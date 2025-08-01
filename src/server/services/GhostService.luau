-- GhostService.luau
-- Handles recording and playback of ghost runner paths for competitive racing

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local DataStoreService = game:GetService("DataStoreService")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local RemoteEvents = require(ReplicatedStorage.Shared.modules.RemoteEvents)
local GameConstants = require(ReplicatedStorage.Shared.constants.GameConstants)

-- Forward declare services to avoid circular dependencies
local PlayerService = nil
local AnalyticsService = nil

local GhostService = {}

-- DataStore for ghost run data
local ghostRunStore = DataStoreService:GetDataStore("GhostRuns")

-- Active ghost recordings
local activeRecordings = {} -- [playerId] = {positions, timestamps, score, etc.}
local activeGhosts = {} -- [ghostId] = ghost runner model

-- Ghost run configuration
local GHOST_CONFIG = {
    maxStoredGhosts = 10, -- Maximum ghosts per track
    recordingInterval = 0.1, -- Record position every 0.1 seconds
    minRunDuration = 5, -- Minimum run duration to save as ghost
    maxGhostDisplays = 3, -- Maximum concurrent ghost displays
    ghostTransparency = 0.6,
    ghostSpeed = 1.0 -- Playback speed multiplier
}

-- Ghost data structure
--[[
GhostRun = {
    id = "unique_ghost_id",
    playerName = "PlayerName",
    playerId = 12345,
    trackType = "main" or "event",
    score = 15,
    duration = 45.2,
    timestamp = os.time(),
    path = {
        {position = Vector3, timestamp = 0.1, color = "RED"},
        {position = Vector3, timestamp = 0.2, color = "BLUE"},
        -- ... more path points
    },
    barriers = {
        {position = Vector3, color = "RED", timestamp = 1.5, hit = true},
        -- ... barrier interactions
    }
}
]]

function GhostService:StartRecording(player, trackType)
    local userId = player.UserId
    
    -- Initialize recording data
    activeRecordings[userId] = {
        playerId = userId,
        playerName = player.Name,
        trackType = trackType or "main",
        startTime = tick(),
        path = {},
        barriers = {},
        score = 0,
        isRecording = true
    }
    
    -- Start recording position updates
    local character = player.Character
    if not character or not character:FindFirstChild("HumanoidRootPart") then
        warn("❌ Cannot start ghost recording - character not found")
        return false
    end
    
    local humanoidRootPart = character.HumanoidRootPart
    local recording = activeRecordings[userId]
    
    -- Record initial position
    table.insert(recording.path, {
        position = humanoidRootPart.Position,
        timestamp = 0,
        color = self:GetPlayerColor(player)
    })
    
    print("👻 Started ghost recording for " .. player.Name .. " on " .. trackType .. " track")
    return true
end

function GhostService:RecordPosition(player)
    local userId = player.UserId
    local recording = activeRecordings[userId]
    
    if not recording or not recording.isRecording then
        return
    end
    
    local character = player.Character
    if not character or not character:FindFirstChild("HumanoidRootPart") then
        return
    end
    
    local humanoidRootPart = character.HumanoidRootPart
    local currentTime = tick() - recording.startTime
    
    -- Record position with timestamp
    table.insert(recording.path, {
        position = humanoidRootPart.Position,
        timestamp = currentTime,
        color = self:GetPlayerColor(player)
    })
    
    -- Limit path points to prevent excessive data
    if #recording.path > 2000 then -- ~200 seconds at 0.1s intervals
        table.remove(recording.path, 1) -- Remove oldest point
    end
end

function GhostService:RecordBarrierInteraction(player, barrierPosition, barrierColor, hit, score)
    local userId = player.UserId
    local recording = activeRecordings[userId]
    
    if not recording or not recording.isRecording then
        return
    end
    
    local currentTime = tick() - recording.startTime
    
    -- Record barrier interaction
    table.insert(recording.barriers, {
        position = barrierPosition,
        color = barrierColor,
        timestamp = currentTime,
        hit = hit,
        score = score or 0
    })
    
    -- Update current score
    if hit then
        recording.score = score or recording.score
    end
end

function GhostService:StopRecording(player, finalScore)
    local userId = player.UserId
    local recording = activeRecordings[userId]
    
    if not recording or not recording.isRecording then
        return nil
    end
    
    recording.isRecording = false
    recording.score = finalScore or recording.score
    recording.duration = tick() - recording.startTime
    
    -- Only save if run meets minimum requirements
    if recording.duration >= GHOST_CONFIG.minRunDuration and #recording.path > 10 then
        local ghostRun = self:CreateGhostRun(recording)
        self:SaveGhostRun(ghostRun)
        
        print("👻 Saved ghost run for " .. player.Name .. " - Score: " .. recording.score .. ", Duration: " .. string.format("%.1f", recording.duration) .. "s")
        
        -- Clear recording
        activeRecordings[userId] = nil
        
        return ghostRun
    else
        print("❌ Ghost run too short to save for " .. player.Name)
        activeRecordings[userId] = nil
        return nil
    end
end

function GhostService:CreateGhostRun(recording)
    local ghostId = "ghost_" .. recording.playerId .. "_" .. os.time()
    
    return {
        id = ghostId,
        playerName = recording.playerName,
        playerId = recording.playerId,
        trackType = recording.trackType,
        score = recording.score,
        duration = recording.duration,
        timestamp = os.time(),
        path = recording.path,
        barriers = recording.barriers
    }
end

function GhostService:SaveGhostRun(ghostRun)
    local trackKey = "ghosts_" .. ghostRun.trackType
    
    local success, currentGhosts = pcall(function()
        return ghostRunStore:GetAsync(trackKey) or {}
    end)
    
    if not success then
        warn("❌ Failed to load existing ghosts for saving")
        return false
    end
    
    -- Add new ghost
    table.insert(currentGhosts, ghostRun)
    
    -- Sort by score (highest first)
    table.sort(currentGhosts, function(a, b)
        return a.score > b.score
    end)
    
    -- Keep only top ghosts
    if #currentGhosts > GHOST_CONFIG.maxStoredGhosts then
        for i = GHOST_CONFIG.maxStoredGhosts + 1, #currentGhosts do
            currentGhosts[i] = nil
        end
    end
    
    -- Save back to DataStore
    local saveSuccess = pcall(function()
        ghostRunStore:SetAsync(trackKey, currentGhosts)
    end)
    
    if saveSuccess then
        print("💾 Ghost run saved successfully")
        
        -- Log analytics
        if AnalyticsService then
            AnalyticsService:LogEvent(Players:GetPlayerByUserId(ghostRun.playerId), "ghost_run_saved", {
                ghostId = ghostRun.id,
                score = ghostRun.score,
                duration = ghostRun.duration,
                trackType = ghostRun.trackType,
                pathPoints = #ghostRun.path
            })
        end
        
        return true
    else
        warn("❌ Failed to save ghost run")
        return false
    end
end

function GhostService:LoadGhosts(trackType, count)
    local trackKey = "ghosts_" .. (trackType or "main")
    count = count or GHOST_CONFIG.maxGhostDisplays
    
    local success, ghosts = pcall(function()
        return ghostRunStore:GetAsync(trackKey) or {}
    end)
    
    if not success then
        warn("❌ Failed to load ghosts")
        return {}
    end
    
    -- Return top ghosts up to requested count
    local topGhosts = {}
    for i = 1, math.min(count, #ghosts) do
        table.insert(topGhosts, ghosts[i])
    end
    
    return topGhosts
end

function GhostService:SpawnGhost(ghostRun, player)
    local ghostId = ghostRun.id .. "_display"
    
    -- Remove existing ghost if any
    self:DespawnGhost(ghostId)
    
    -- Create ghost model
    local ghostModel = self:CreateGhostModel(ghostRun)
    if not ghostModel then
        warn("❌ Failed to create ghost model")
        return nil
    end
    
    ghostModel.Name = ghostId
    ghostModel.Parent = Workspace
    
    -- Store ghost reference
    activeGhosts[ghostId] = {
        model = ghostModel,
        ghostRun = ghostRun,
        playbackIndex = 1,
        startTime = tick(),
        isPlaying = true
    }
    
    -- Start playback
    self:StartGhostPlayback(ghostId)
    
    print("👻 Spawned ghost of " .. ghostRun.playerName .. " (Score: " .. ghostRun.score .. ")")
    return ghostId
end

function GhostService:CreateGhostModel(ghostRun)
    -- Create a simplified ghost model
    local ghostModel = Instance.new("Model")
    ghostModel.Name = "GhostRunner_" .. ghostRun.playerName
    
    -- Create main part
    local ghostPart = Instance.new("Part")
    ghostPart.Name = "GhostBody"
    ghostPart.Size = Vector3.new(2, 5, 1)
    ghostPart.Anchored = true
    ghostPart.CanCollide = false
    ghostPart.Transparency = GHOST_CONFIG.ghostTransparency
    ghostPart.BrickColor = BrickColor.new("Bright blue")
    ghostPart.Material = Enum.Material.ForceField
    ghostPart.Parent = ghostModel
    
    -- Add glow effect
    local pointLight = Instance.new("PointLight")
    pointLight.Color = Color3.new(0.5, 0.5, 1)
    pointLight.Brightness = 1
    pointLight.Range = 10
    pointLight.Parent = ghostPart
    
    -- Add name tag
    local nameGui = Instance.new("BillboardGui")
    nameGui.Size = UDim2.new(0, 200, 0, 50)
    nameGui.StudsOffset = Vector3.new(0, 3, 0)
    nameGui.Parent = ghostPart
    
    local nameLabel = Instance.new("TextLabel")
    nameLabel.Size = UDim2.new(1, 0, 1, 0)
    nameLabel.BackgroundTransparency = 1
    nameLabel.Text = "👻 " .. ghostRun.playerName .. " (" .. ghostRun.score .. ")"
    nameLabel.TextColor3 = Color3.new(0.8, 0.8, 1)
    nameLabel.TextScaled = true
    nameLabel.Font = Enum.Font.SourceSansBold
    nameLabel.TextStrokeTransparency = 0
    nameLabel.TextStrokeColor3 = Color3.new(0, 0, 0)
    nameLabel.Parent = nameGui
    
    -- Add particle trail
    local attachment = Instance.new("Attachment")
    attachment.Parent = ghostPart
    
    local trail = Instance.new("Trail")
    trail.Color = ColorSequence.new(Color3.new(0.5, 0.5, 1))
    trail.Transparency = NumberSequence.new(0.3, 1)
    trail.Lifetime = 2
    trail.MinLength = 0
    trail.Attachment0 = attachment
    trail.Attachment1 = attachment
    trail.Parent = ghostPart
    
    return ghostModel
end

function GhostService:StartGhostPlayback(ghostId)
    local ghost = activeGhosts[ghostId]
    if not ghost or not ghost.isPlaying then
        return
    end
    
    local ghostRun = ghost.ghostRun
    local model = ghost.model
    local ghostPart = model:FindFirstChild("GhostBody")
    
    if not ghostPart then
        return
    end
    
    -- Start playback loop
    spawn(function()
        while ghost.isPlaying and model.Parent do
            local currentTime = (tick() - ghost.startTime) * GHOST_CONFIG.ghostSpeed
            
            -- Find appropriate path point for current time
            local targetPoint = self:GetPathPointAtTime(ghostRun.path, currentTime)
            
            if targetPoint then
                -- Update ghost position
                ghostPart.Position = targetPoint.position
                
                -- Update ghost color based on player's color at that time
                local color = self:GetColorFromName(targetPoint.color)
                if color then
                    ghostPart.BrickColor = BrickColor.new(color)
                end
                
                ghost.playbackIndex = ghost.playbackIndex + 1
            else
                -- Playback finished
                self:DespawnGhost(ghostId)
                break
            end
            
            wait(GHOST_CONFIG.recordingInterval)
        end
    end)
end

function GhostService:GetPathPointAtTime(path, targetTime)
    -- Find the path point closest to the target time
    for i, point in ipairs(path) do
        if point.timestamp >= targetTime then
            return point
        end
    end
    
    -- Return last point if we've exceeded the path duration
    return path[#path]
end

function GhostService:GetColorFromName(colorName)
    local colorMap = {
        RED = Color3.new(1, 0.2, 0.2),
        GREEN = Color3.new(0.2, 1, 0.2),
        BLUE = Color3.new(0.2, 0.2, 1),
        YELLOW = Color3.new(1, 1, 0.2),
        PURPLE = Color3.new(1, 0.2, 1),
        ORANGE = Color3.new(1, 0.6, 0.2)
    }
    
    return colorMap[colorName]
end

function GhostService:GetPlayerColor(player)
    -- Get current player color from PlayerService
    if PlayerService then
        local playerData = PlayerService:GetPlayerData(player)
        if playerData and playerData.currentColor then
            return playerData.currentColor
        end
    end
    
    return "RED" -- Default color
end

function GhostService:DespawnGhost(ghostId)
    local ghost = activeGhosts[ghostId]
    if not ghost then
        return
    end
    
    ghost.isPlaying = false
    
    if ghost.model and ghost.model.Parent then
        ghost.model:Destroy()
    end
    
    activeGhosts[ghostId] = nil
    print("👻 Despawned ghost: " .. ghostId)
end

function GhostService:DespawnAllGhosts()
    for ghostId, _ in pairs(activeGhosts) do
        self:DespawnGhost(ghostId)
    end
end

function GhostService:GetPlayerGhostStats(player)
    local userId = player.UserId
    local stats = {
        totalGhosts = 0,
        bestScore = 0,
        averageScore = 0,
        bestDuration = math.huge
    }
    
    -- Check both main and event tracks
    for _, trackType in pairs({"main", "event"}) do
        local ghosts = self:LoadGhosts(trackType, 50) -- Load more for stats
        
        for _, ghost in pairs(ghosts) do
            if ghost.playerId == userId then
                stats.totalGhosts = stats.totalGhosts + 1
                stats.bestScore = math.max(stats.bestScore, ghost.score)
                stats.averageScore = stats.averageScore + ghost.score
                stats.bestDuration = math.min(stats.bestDuration, ghost.duration)
            end
        end
    end
    
    if stats.totalGhosts > 0 then
        stats.averageScore = stats.averageScore / stats.totalGhosts
    end
    
    if stats.bestDuration == math.huge then
        stats.bestDuration = 0
    end
    
    return stats
end

function GhostService:GetLeaderboardGhosts(trackType, count)
    local ghosts = self:LoadGhosts(trackType, count or 10)
    local leaderboard = {}
    
    for i, ghost in ipairs(ghosts) do
        table.insert(leaderboard, {
            rank = i,
            playerName = ghost.playerName,
            score = ghost.score,
            duration = ghost.duration,
            timestamp = ghost.timestamp,
            ghostId = ghost.id
        })
    end
    
    return leaderboard
end

function GhostService:PassBarrier(player, wasHit)
    local userId = player.UserId
    if not activeRecordings[userId] then
        return
    end
    
    local recording = activeRecordings[userId]
    
    -- Record barrier interaction
    table.insert(recording.barrierInteractions, {
        time = tick() - recording.startTime,
        wasHit = wasHit,
        position = {
            x = player.Character.HumanoidRootPart.Position.X,
            y = player.Character.HumanoidRootPart.Position.Y,
            z = player.Character.HumanoidRootPart.Position.Z
        }
    })
    
    -- Update score
    if wasHit then
        recording.score = recording.score - GHOST_CONFIG.hitPenalty
    else
        recording.score = recording.score + GHOST_CONFIG.passBonus
    end
    
    -- Update race comparison if racing
    self:UpdateRaceComparison(player)
    
    print("🎯 " .. player.Name .. " barrier interaction: " .. (wasHit and "HIT" or "PASS") .. " (Score: " .. recording.score .. ")")
end

function GhostService:GetActiveRecording(player)
    return activeRecordings[player.UserId]
end

function GhostService:SetPlayerService(service)
    PlayerService = service
end

function GhostService:SetAnalyticsService(service)
    AnalyticsService = service
end

function GhostService:Initialize()
    print("👻 GhostService initializing...")
    
    -- Clean up any existing ghosts
    self:DespawnAllGhosts()
    
    -- Set up remote event handlers
    RemoteEvents.RequestGhostLeaderboard.OnServerEvent:Connect(function(player, trackType, count)
        local ghosts = self:GetLeaderboardGhosts(trackType, count)
        RemoteEvents.ShowGhostLeaderboard:FireClient(player, ghosts)
    end)
    
    RemoteEvents.RaceAgainstGhost.OnServerEvent:Connect(function(player, ghostId)
        self:StartRaceAgainstGhost(player, ghostId)
    end)
    
    -- Event-driven position recording with smart management
    local recordingEvent = Instance.new("BindableEvent")
    
    local function scheduleNextRecording()
        local activeCount = 0
        for _ in pairs(activeRecordings) do
            activeCount = activeCount + 1
        end
        
        -- Adaptive interval based on active recordings
        local interval = GHOST_CONFIG.recordingInterval
        if activeCount > 5 then
            interval = interval * 1.5 -- Reduce frequency for many players
        elseif activeCount == 0 then
            interval = 5 -- Much longer wait when no one is recording
        end
        
        task.spawn(function()
            task.wait(interval)
            recordingEvent:Fire()
        end)
    end
    
    recordingEvent.Event:Connect(function()
        local recordedAny = false
        for playerId, _ in pairs(activeRecordings) do
            local player = Players:GetPlayerByUserId(playerId)
            if player then
                self:RecordPosition(player)
                recordedAny = true
            end
        end
        
        -- Only continue if there are active recordings
        if recordedAny or next(activeRecordings) then
            scheduleNextRecording()
        end
    end)
    
    -- Start recording cycle
    scheduleNextRecording()
    
    print("✅ GhostService initialized successfully!")
end

function GhostService:StartRaceAgainstGhost(player, ghostId)
    -- Load the ghost and spawn it for the player
    local trackType = "main" -- Default, could be determined from ghostId
    local ghosts = self:LoadGhosts(trackType, 50) -- Load many to find specific ghost
    
    local targetGhost = nil
    for _, ghost in pairs(ghosts) do
        if ghost.id == ghostId then
            targetGhost = ghost
            break
        end
    end
    
    if targetGhost then
        local spawnedGhostId = self:SpawnGhost(targetGhost, player)
        if spawnedGhostId then
            print("🏁 " .. player.Name .. " is racing against " .. targetGhost.playerName .. "'s ghost")
            
            -- Track race start for comparison
            self:StartRaceComparison(player, targetGhost)
        end
    else
        warn("❌ Ghost not found: " .. ghostId)
    end
end

function GhostService:StartRaceComparison(player, ghostRun)
    -- Store race comparison data
    local userId = player.UserId
    if not activeRecordings[userId] then
        return -- Player not in a run
    end
    
    activeRecordings[userId].racingAgainst = {
        ghostName = ghostRun.playerName,
        ghostScore = ghostRun.score,
        ghostDuration = ghostRun.duration,
        startTime = tick()
    }
    
    print("🏁 Started race comparison for " .. player.Name .. " vs " .. ghostRun.playerName)
end

function GhostService:UpdateRaceComparison(player)
    local userId = player.UserId
    local recording = activeRecordings[userId]
    
    if not recording or not recording.racingAgainst then
        return
    end
    
    local raceData = recording.racingAgainst
    local currentTime = tick() - raceData.startTime
    
    -- Send comparison update to client
    RemoteEvents.UpdateRaceComparison:FireClient(
        player,
        raceData.ghostName,
        recording.score,
        raceData.ghostScore,
        currentTime,
        raceData.ghostDuration
    )
end

return GhostService
