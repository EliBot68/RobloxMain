-- RecordingSessionManager.server.luau
-- Manages coordinated recording sessions for promotional footage
-- Handles multiplayer coordination, optimal timing, and scene setup

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")

local RecordingSessionManager = {}

-- Recording State
local activeRecordingSessions = {}
local recordingMoments = {}
local coordinatedPlayers = {}

-- Optimal Recording Moments Configuration
local RECORDING_MOMENTS = {
    PerfectStreak = {
        name = "Perfect Streak",
        description = "Flawless high-speed obstacle navigation",
        duration = 35,
        requirements = {
            minSpeed = 50,
            consecutiveDodges = 8,
            healthThreshold = 0.8,
            scoreMultiplier = 3
        },
        cameraPreset = "ActionFollow",
        triggers = {"SpeedBoost", "HighScore", "PerfectRun"}
    },
    
    LastSecondSave = {
        name = "Last Second Save",
        description = "Dramatic near-death recovery",
        duration = 25,
        requirements = {
            lowHealth = 0.2,
            dangerousObstacle = true,
            perfectTiming = true,
            recoveryOpportunity = true
        },
        cameraPreset = "DramaticClose",
        triggers = {"LowHealth", "DangerousObstacle", "PerfectDodge"}
    },
    
    MultiplayerMayhem = {
        name = "Multiplayer Mayhem",
        description = "Competitive multiplayer racing action",
        duration = 40,
        requirements = {
            minPlayers = 3,
            closeCompetition = true,
            leaderChanges = 2,
            socialInteraction = true
        },
        cameraPreset = "MultiplayerWide",
        triggers = {"LeaderChange", "CloseRace", "SocialMoment"}
    }
}

-- Events Setup
local function setupEvents()
    local eventsFolder = ReplicatedStorage:FindFirstChild("Events")
    if not eventsFolder then
        eventsFolder = Instance.new("Folder")
        eventsFolder.Name = "Events"
        eventsFolder.Parent = ReplicatedStorage
    end
    
    -- Recording control events
    local startRecordingEvent = Instance.new("RemoteEvent")
    startRecordingEvent.Name = "StartRecording"
    startRecordingEvent.Parent = eventsFolder
    
    local stopRecordingEvent = Instance.new("RemoteEvent")
    stopRecordingEvent.Name = "StopRecording"
    stopRecordingEvent.Parent = eventsFolder
    
    local recordingMomentEvent = Instance.new("RemoteEvent")
    recordingMomentEvent.Name = "RecordingMoment"
    recordingMomentEvent.Parent = eventsFolder
    
    return {
        startRecording = startRecordingEvent,
        stopRecording = stopRecordingEvent,
        recordingMoment = recordingMomentEvent
    }
end

local events = setupEvents()

function RecordingSessionManager:Init()
    print("🎬 Initializing Recording Session Manager...")
    
    -- Set up event connections
    self:ConnectEvents()
    
    -- Start monitoring for optimal moments
    self:StartMomentDetection()
    
    -- Set up player coordination
    self:SetupPlayerCoordination()
    
    print("✅ Recording Session Manager initialized!")
end

function RecordingSessionManager:ConnectEvents()
    -- Handle recording start requests
    events.startRecording.OnServerEvent:Connect(function(player, sessionType, duration)
        self:StartRecordingSession(player, sessionType, duration)
    end)
    
    -- Handle recording stop requests
    events.stopRecording.OnServerEvent:Connect(function(player)
        self:StopRecordingSession(player)
    end)
    
    -- Player connections
    Players.PlayerAdded:Connect(function(player)
        self:SetupPlayerForRecording(player)
    end)
    
    Players.PlayerRemoving:Connect(function(player)
        self:CleanupPlayerRecording(player)
    end)
end

function RecordingSessionManager:SetupPlayerForRecording(player)
    print("🎮 Setting up recording for player: " .. player.Name)
    
    player.CharacterAdded:Connect(function(character)
        spawn(function()
            wait(2) -- Wait for character to load
            self:SetupCharacterRecording(player, character)
        end)
    end)
    
    if player.Character then
        self:SetupCharacterRecording(player, player.Character)
    end
end

function RecordingSessionManager:SetupCharacterRecording(player, character)
    local humanoid = character:WaitForChild("Humanoid")
    local humanoidRootPart = character:WaitForChild("HumanoidRootPart")
    
    -- Track player performance for moment detection
    local playerData = {
        consecutiveDodges = 0,
        lastDodgeTime = 0,
        totalScore = 0,
        currentSpeed = 0,
        lastHealth = humanoid.Health,
        dangerousMoments = 0
    }
    
    coordinatedPlayers[player] = playerData
    
    -- Monitor health changes
    humanoid.HealthChanged:Connect(function(health)
        playerData.lastHealth = health
        
        -- Detect low health moments
        if health / humanoid.MaxHealth <= 0.2 then
            self:CheckForRecordingMoment(player, "LowHealth")
        end
        
        -- Detect dramatic recoveries
        if health > playerData.lastHealth and playerData.lastHealth / humanoid.MaxHealth <= 0.3 then
            self:CheckForRecordingMoment(player, "DramaticRecovery")
        end
    end)
    
    -- Monitor speed and movement
    local speedConnection
    speedConnection = RunService.Heartbeat:Connect(function()
        if not humanoidRootPart.Parent then
            speedConnection:Disconnect()
            return
        end
        
        local velocity = humanoidRootPart.Velocity
        playerData.currentSpeed = velocity.Magnitude
        
        -- Detect high-speed moments
        if playerData.currentSpeed >= 50 then
            self:CheckForRecordingMoment(player, "HighSpeed")
        end
    end)
    
    print("📊 Character recording setup complete for " .. player.Name)
end

function RecordingSessionManager:StartMomentDetection()
    -- Event-driven optimal recording moment detection
    local momentDetectionEvent = Instance.new("BindableEvent")
    
    local function scheduleMomentDetection()
        wait(1) -- Check every second
        
        self:DetectPerfectStreakMoments()
        self:DetectMultiplayerMoments()
        self:DetectDramaticMoments()
        
        momentDetectionEvent:Fire()
    end
    
    momentDetectionEvent.Event:Connect(function()
        spawn(scheduleMomentDetection)
    end)
    
    -- Start the moment detection cycle
    spawn(scheduleMomentDetection)
end

function RecordingSessionManager:DetectPerfectStreakMoments()
    for player, data in pairs(coordinatedPlayers) do
        if not player.Character then continue end
        
        local requirements = RECORDING_MOMENTS.PerfectStreak.requirements
        
        -- Check if player meets perfect streak criteria
        if data.currentSpeed >= requirements.minSpeed and
           data.consecutiveDodges >= requirements.consecutiveDodges and
           data.lastHealth / player.Character.Humanoid.MaxHealth >= requirements.healthThreshold then
            
            self:TriggerRecordingMoment(player, "PerfectStreak")
        end
    end
end

function RecordingSessionManager:DetectMultiplayerMoments()
    local activePlayers = {}
    
    -- Collect active players
    for player, data in pairs(coordinatedPlayers) do
        if player.Character and data.currentSpeed > 10 then
            table.insert(activePlayers, {player = player, data = data})
        end
    end
    
    -- Check for multiplayer moments
    if #activePlayers >= 3 then
        -- Sort by score or position
        table.sort(activePlayers, function(a, b)
            return a.data.totalScore > b.data.totalScore
        end)
        
        -- Check for close competition
        local topScore = activePlayers[1].data.totalScore
        local secondScore = activePlayers[2] and activePlayers[2].data.totalScore or 0
        
        if topScore > 0 and math.abs(topScore - secondScore) / topScore <= 0.2 then
            -- Close competition detected
            for _, playerInfo in ipairs(activePlayers) do
                self:TriggerRecordingMoment(playerInfo.player, "MultiplayerMayhem")
            end
        end
    end
end

function RecordingSessionManager:DetectDramaticMoments()
    for player, data in pairs(coordinatedPlayers) do
        if not player.Character then continue end
        
        local healthPercent = data.lastHealth / player.Character.Humanoid.MaxHealth
        
        -- Detect near-death situations
        if healthPercent <= 0.2 and data.currentSpeed > 20 then
            data.dangerousMoments = data.dangerousMoments + 1
            
            if data.dangerousMoments >= 2 then
                self:TriggerRecordingMoment(player, "LastSecondSave")
                data.dangerousMoments = 0 -- Reset counter
            end
        end
    end
end

function RecordingSessionManager:CheckForRecordingMoment(player, triggerType)
    local playerData = coordinatedPlayers[player]
    if not playerData then return end
    
    -- Update trigger history
    if not playerData.triggers then
        playerData.triggers = {}
    end
    
    table.insert(playerData.triggers, {
        type = triggerType,
        time = tick()
    })
    
    -- Clean old triggers (older than 30 seconds)
    local currentTime = tick()
    for i = #playerData.triggers, 1, -1 do
        if currentTime - playerData.triggers[i].time > 30 then
            table.remove(playerData.triggers, i)
        end
    end
end

function RecordingSessionManager:TriggerRecordingMoment(player, momentType)
    local moment = RECORDING_MOMENTS[momentType]
    if not moment then return end
    
    -- Check if this moment was recently triggered
    local sessionKey = player.Name .. "_" .. momentType
    local lastTriggerTime = recordingMoments[sessionKey] or 0
    
    if tick() - lastTriggerTime < 60 then
        return -- Cooldown to prevent spam
    end
    
    recordingMoments[sessionKey] = tick()
    
    print("🎬 Optimal recording moment detected: " .. moment.name .. " for " .. player.Name)
    
    -- Notify all players about the recording opportunity
    events.recordingMoment:FireAllClients(momentType, moment, player.Name)
    
    -- Auto-coordinate the recording if multiple players are involved
    if momentType == "MultiplayerMayhem" then
        self:CoordinateMultiplayerRecording(moment)
    end
end

function RecordingSessionManager:CoordinateMultiplayerRecording(moment)
    print("🎥 Coordinating multiplayer recording session...")
    
    -- Prepare all players for recording
    for player, _ in pairs(coordinatedPlayers) do
        if player.Character then
            -- Optimize player appearance for recording
            self:OptimizePlayerForRecording(player)
        end
    end
    
    -- Synchronize timing
    spawn(function()
        wait(2) -- Give players time to prepare
        
        -- Start coordinated recording
        events.startRecording:FireAllClients("MultiplayerMayhem", moment.duration)
        
        print("🎬 Coordinated multiplayer recording started!")
        
        -- Auto-stop after duration
        wait(moment.duration)
        events.stopRecording:FireAllClients()
        
        print("✅ Coordinated multiplayer recording completed!")
    end)
end

function RecordingSessionManager:OptimizePlayerForRecording(player)
    local character = player.Character
    if not character then return end
    
    -- Ensure character is in good recording condition
    local humanoid = character:FindFirstChild("Humanoid")
    if humanoid then
        -- Reset any negative effects
        humanoid.PlatformStand = false
        humanoid.Sit = false
        
        -- Ensure good health for recording
        if humanoid.Health < humanoid.MaxHealth * 0.5 then
            humanoid.Health = humanoid.MaxHealth * 0.8
        end
    end
    
    -- Clean up any unwanted accessories or effects
    self:CleanCharacterForRecording(character)
end

function RecordingSessionManager:CleanCharacterForRecording(character)
    -- Remove any debug or inappropriate accessories
    local humanoid = character:FindFirstChild("Humanoid")
    if not humanoid then return end
    
    -- Remove temporary effects that might look bad in recording
    for _, part in ipairs(character:GetChildren()) do
        if part:IsA("Part") or part:IsA("Accessory") then
            -- Check for debug or inappropriate items
            if string.find(part.Name:lower(), "debug") or 
               string.find(part.Name:lower(), "test") or
               string.find(part.Name:lower(), "temp") then
                part:Destroy()
            end
        end
    end
end

function RecordingSessionManager:StartRecordingSession(player, sessionType, duration)
    local sessionId = player.Name .. "_" .. tick()
    
    activeRecordingSessions[sessionId] = {
        player = player,
        type = sessionType,
        startTime = tick(),
        duration = duration or 30,
        isActive = true
    }
    
    print("🎬 Recording session started: " .. sessionId)
    
    -- Optimize game state for recording
    self:OptimizeGameForRecording(player)
    
    -- Auto-stop after duration
    spawn(function()
        wait(duration or 30)
        self:StopRecordingSession(player)
    end)
end

function RecordingSessionManager:StopRecordingSession(player)
    for sessionId, session in pairs(activeRecordingSessions) do
        if session.player == player and session.isActive then
            session.isActive = false
            session.endTime = tick()
            
            print("✅ Recording session completed: " .. sessionId)
            
            -- Clean up optimizations
            self:RestoreGameAfterRecording(player)
            
            break
        end
    end
end

function RecordingSessionManager:OptimizeGameForRecording(player)
    -- Reduce server lag during recording
    -- Disable non-essential systems temporarily
    -- Ensure smooth gameplay experience
    
    print("⚡ Optimizing game state for recording...")
end

function RecordingSessionManager:RestoreGameAfterRecording(player)
    -- Restore normal game state
    print("🔄 Restoring normal game state after recording...")
end

function RecordingSessionManager:CleanupPlayerRecording(player)
    coordinatedPlayers[player] = nil
    
    -- Remove any active recording sessions
    for sessionId, session in pairs(activeRecordingSessions) do
        if session.player == player then
            activeRecordingSessions[sessionId] = nil
        end
    end
    
    print("🧹 Cleaned up recording data for " .. player.Name)
end

-- PUBLIC API METHODS
function RecordingSessionManager:ForceRecordingMoment(momentType, targetPlayer)
    local player = targetPlayer or Players:GetPlayers()[1]
    if player then
        self:TriggerRecordingMoment(player, momentType)
    end
end

function RecordingSessionManager:GetActiveRecordingSessions()
    return activeRecordingSessions
end

function RecordingSessionManager:GetPlayerRecordingData(player)
    return coordinatedPlayers[player]
end

-- ADMIN COMMANDS FOR TESTING
local function setupAdminCommands()
    Players.PlayerAdded:Connect(function(player)
        player.Chatted:Connect(function(message)
            local args = string.split(message, " ")
            local command = args[1]:lower()
            
            -- Only allow developers/admins to use these commands
            if player.Name == "YourUsername" or player:GetRankInGroup(0) >= 100 then
                if command == ":perfectstreak" then
                    RecordingSessionManager:ForceRecordingMoment("PerfectStreak", player)
                elseif command == ":lastsecond" then
                    RecordingSessionManager:ForceRecordingMoment("LastSecondSave", player)
                elseif command == ":multiplayer" then
                    RecordingSessionManager:ForceRecordingMoment("MultiplayerMayhem", player)
                elseif command == ":recordinginfo" then
                    local data = RecordingSessionManager:GetPlayerRecordingData(player)
                    if data then
                        print("📊 Recording data for " .. player.Name .. ":")
                        print("  Speed: " .. data.currentSpeed)
                        print("  Dodges: " .. data.consecutiveDodges)
                        print("  Score: " .. data.totalScore)
                        print("  Health: " .. data.lastHealth)
                    end
                end
            end
        end)
    end)
end

-- Initialize the manager
spawn(function()
    wait(5) -- Wait for game to fully load
    RecordingSessionManager:Init()
    setupAdminCommands()
end)

return RecordingSessionManager
