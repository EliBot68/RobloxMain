-- ArchwayService.luau
-- Enhanced archway service with comprehensive memory management
-- Handles the game entrance archway and game start sequence

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local SafeRequire = require(ReplicatedStorage.Shared.utils.SafeRequire)
local WorldObjectValidator = SafeRequire.require(ReplicatedStorage.Shared.utils.WorldObjectValidator)
local RemoteEvents = SafeRequire.require(ReplicatedStorage.Shared.modules.RemoteEvents)
local GameService = SafeRequire.require(script.Parent.GameService)
local MemoryManager = require(ReplicatedStorage.Shared.utilities.MemoryManager)

local ArchwayService = {}

-- Track active game starts to prevent spam
local activeGameStarts = {}

-- Multiplayer queue system
local multiplayerQueue = {}
local currentMultiplayerSession = nil
local MAX_QUEUE_SIZE = 6 -- Up to 6 players can play together
local QUEUE_TIMEOUT = 30 -- Auto-start after 30 seconds if queue isn't full

-- Memory management tracking
local activeTweens = {} -- Track all active tweens for cleanup
local activeConnections = {} -- Track all active connections for cleanup
local playerQueueData = {} -- Track player-specific queue data

-- Available game start positions (corresponding to tracks)
local GAME_START_POSITIONS = {
    Vector3.new(100, 6, -10),   -- Track 1 start
    Vector3.new(-100, 6, -10),  -- Track 2 start
    Vector3.new(0, 6, 140)      -- Track 3 start
}

function ArchwayService:SetupArchwayDisplay()
    local archway = Workspace.MarketPlaza.GameArchway
    if not archway then
        warn("Game archway not found!")
        return
    end
    
    local centerGem = archway:FindFirstChild("CenterGem")
    local portal = archway:FindFirstChild("MagicPortal")
    local glowOrb1 = archway:FindFirstChild("GlowOrb1")
    local glowOrb2 = archway:FindFirstChild("GlowOrb2")
    
    -- Add floating "PLAY" text
    local archTop = archway:FindFirstChild("ArchTop")
    if archTop then
        local billboardGui = Instance.new("BillboardGui")
        billboardGui.Size = UDim2.new(0, 400, 0, 100)
        billboardGui.StudsOffset = Vector3.new(0, 2, 0)
        billboardGui.Parent = archTop
        
        local playLabel = Instance.new("TextLabel")
        playLabel.Size = UDim2.new(1, 0, 1, 0)
        playLabel.BackgroundTransparency = 1
        playLabel.Text = "🎮 PLAY"
        playLabel.TextColor3 = Color3.new(1, 1, 0.6)
        playLabel.TextScaled = true
        playLabel.Font = Enum.Font.SourceSansBold
        playLabel.TextStrokeTransparency = 0
        playLabel.TextStrokeColor3 = Color3.new(0, 0, 0)
        playLabel.Parent = billboardGui
        
        -- Pulsing animation with memory management
        local pulseTween = TweenService:Create(
            playLabel,
            TweenInfo.new(1, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true),
            {
                TextTransparency = 0.3,
                TextSize = 24
            }
        )
        pulseTween:Play()
        
        -- Register tween for cleanup - ASSUMPTION: Using "system" as playerId for global tweens
        MemoryManager:RegisterTween("system", "archway_pulse_" .. tick(), pulseTween)
        table.insert(activeTweens, pulseTween)
        
        -- Floating animation with memory management
        local floatTween = TweenService:Create(
            billboardGui,
            TweenInfo.new(4, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true),
            {StudsOffset = Vector3.new(0, 4, 0)}
        )
        floatTween:Play()
        
        -- Register tween for cleanup
        MemoryManager:RegisterTween("system", "archway_float_" .. tick(), floatTween)
        table.insert(activeTweens, floatTween)
    end
    
    -- Add subtitle text
    if portal then
        local subtitleGui = Instance.new("BillboardGui")
        subtitleGui.Size = UDim2.new(0, 300, 0, 50)
        subtitleGui.StudsOffset = Vector3.new(0, -3, 0)
        subtitleGui.Parent = portal
        
        local subtitleLabel = Instance.new("TextLabel")
        subtitleLabel.Size = UDim2.new(1, 0, 1, 0)
        subtitleLabel.BackgroundTransparency = 1
        subtitleLabel.Text = "Walk through to start!"
        subtitleLabel.TextColor3 = Color3.new(0.8, 0.9, 1)
        subtitleLabel.TextScaled = true
        subtitleLabel.Font = Enum.Font.SourceSansItalic
        subtitleLabel.TextStrokeTransparency = 0
        subtitleLabel.TextStrokeColor3 = Color3.new(0, 0, 0)
        subtitleLabel.Parent = subtitleGui
        
        -- Gentle pulsing
        local subtitlePulse = TweenService:Create(
            subtitleLabel,
            TweenInfo.new(2, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true),
            {TextTransparency = 0.4}
        )
        subtitlePulse:Play()
    end
    
    -- Center gem rotation and pulsing
    if centerGem then
        local rotateTween = TweenService:Create(
            centerGem,
            TweenInfo.new(3, Enum.EasingStyle.Linear, Enum.EasingDirection.InOut, -1),
            {CFrame = centerGem.CFrame * CFrame.Angles(0, math.pi * 2, 0)}
        )
        rotateTween:Play()
        
        local gemPulse = TweenService:Create(
            centerGem,
            TweenInfo.new(1.5, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true),
            {Size = centerGem.Size * 1.2}
        )
        gemPulse:Play()
    end
    
    -- Orb pulsing (alternating)
    if glowOrb1 then
        local orb1Pulse = TweenService:Create(
            glowOrb1,
            TweenInfo.new(2, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true),
            {Transparency = 0.5}
        )
        orb1Pulse:Play()
    end
    
    if glowOrb2 then
        -- Offset the second orb animation
        spawn(function()
            wait(1)
            local orb2Pulse = TweenService:Create(
                glowOrb2,
                TweenInfo.new(2, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true),
                {Transparency = 0.5}
            )
            orb2Pulse:Play()
        end)
    end
    
    -- Portal shimmer effect
    if portal then
        local shimmerTween = TweenService:Create(
            portal,
            TweenInfo.new(3, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true),
            {Transparency = 0.3}
        )
        shimmerTween:Play()
    end
end

function ArchwayService:AddPlayerToQueue(player)
    -- Check if player is already in queue
    for _, queuedPlayer in pairs(multiplayerQueue) do
        if queuedPlayer == player then
            return false -- Already in queue
        end
    end
    
    -- Check if queue is full
    if #multiplayerQueue >= MAX_QUEUE_SIZE then
        RemoteEvents.QueueFull:FireClient(player)
        return false
    end
    
    -- Add player to queue
    table.insert(multiplayerQueue, player)
    
    -- Notify player they joined the queue
    RemoteEvents.JoinedQueue:FireClient(player, #multiplayerQueue, MAX_QUEUE_SIZE)
    
    -- Notify all players in queue of updated count
    self:NotifyQueueUpdate()
    
    print("🎮 " .. player.Name .. " joined multiplayer queue (" .. #multiplayerQueue .. "/" .. MAX_QUEUE_SIZE .. ")")
    
    -- Start queue timer if this is the first player
    if #multiplayerQueue == 1 then
        self:StartQueueTimer()
    end
    
    -- Auto-start if queue is full
    if #multiplayerQueue >= MAX_QUEUE_SIZE then
        self:StartMultiplayerGame()
    end
    
    return true
end

function ArchwayService:RemovePlayerFromQueue(player)
    for i, queuedPlayer in pairs(multiplayerQueue) do
        if queuedPlayer == player then
            table.remove(multiplayerQueue, i)
            
            -- Notify player they left the queue
            RemoteEvents.LeftQueue:FireClient(player)
            
            -- Notify remaining players
            self:NotifyQueueUpdate()
            
            print("👋 " .. player.Name .. " left multiplayer queue (" .. #multiplayerQueue .. "/" .. MAX_QUEUE_SIZE .. ")")
            return true
        end
    end
    return false
end

function ArchwayService:NotifyQueueUpdate()
    for _, player in pairs(multiplayerQueue) do
        if player and player.Parent then
            RemoteEvents.QueueUpdate:FireClient(player, #multiplayerQueue, MAX_QUEUE_SIZE, self:GetQueuePlayerNames())
        end
    end
end

function ArchwayService:GetQueuePlayerNames()
    local names = {}
    for _, player in pairs(multiplayerQueue) do
        if player and player.Parent then
            table.insert(names, player.Name)
        end
    end
    return names
end

function ArchwayService:StartQueueTimer()
    spawn(function()
        wait(QUEUE_TIMEOUT)
        
        -- Check if we still have players and no active session
        if #multiplayerQueue > 1 and not currentMultiplayerSession then
            print("⏰ Queue timer expired, starting game with " .. #multiplayerQueue .. " players")
            self:StartMultiplayerGame()
        end
    end)
end

function ArchwayService:StartMultiplayerGame()
    if #multiplayerQueue < 1 then
        return false
    end
    
    -- Create multiplayer session
    currentMultiplayerSession = {
        players = {},
        startTime = tick(),
        sessionId = tostring(tick())
    }
    
    -- Move players from queue to session
    for _, player in pairs(multiplayerQueue) do
        if player and player.Parent then
            table.insert(currentMultiplayerSession.players, player)
        end
    end
    
    -- Clear the queue
    multiplayerQueue = {}
    
    print("🎮 Starting multiplayer game with " .. #currentMultiplayerSession.players .. " players")
    
    -- Start the synchronized game sequence
    self:StartSynchronizedGameSequence(currentMultiplayerSession.players)
    
    return true
end

function ArchwayService:StartSynchronizedGameSequence(players)
    -- Disable movement for all players and start fade
    for _, player in pairs(players) do
        if player and player.Character then
            local humanoid = player.Character:FindFirstChildOfClass("Humanoid")
            if humanoid then
                humanoid.PlatformStand = true
            end
            
            -- Trigger client fade to black
            RemoteEvents.GameFadeToBlack:FireClient(player)
        end
    end
    
    -- Wait for fade
    wait(1.5)
    
    -- Assign players to different tracks
    local trackAssignments = self:AssignPlayersToTracks(players)
    
    -- Teleport all players simultaneously
    for i, player in pairs(players) do
        if player and player.Character then
            local humanoidRootPart = player.Character:FindFirstChild("HumanoidRootPart")
            local humanoid = player.Character:FindFirstChildOfClass("Humanoid")
            
            if humanoidRootPart and humanoid then
                local trackPosition = trackAssignments[i]
                humanoidRootPart.CFrame = CFrame.new(trackPosition)
                
                -- Re-enable movement
                humanoid.PlatformStand = false
                
                print("🚀 " .. player.Name .. " transported to track " .. i)
            end
        end
    end
    
    -- Start synchronized countdown
    self:StartSynchronizedCountdown(players)
end

function ArchwayService:AssignPlayersToTracks(players)
    local assignments = {}
    local trackPositions = {
        Vector3.new(100, 6, -10),   -- Track 1
        Vector3.new(-100, 6, -10),  -- Track 2  
        Vector3.new(0, 6, 140),     -- Track 3
        Vector3.new(200, 6, -10),   -- Track 4 (new)
        Vector3.new(-200, 6, -10),  -- Track 5 (new)
        Vector3.new(100, 6, 240)    -- Track 6 (new)
    }
    
    for i, player in pairs(players) do
        -- Use modulo to cycle through available tracks
        local trackIndex = ((i - 1) % #trackPositions) + 1
        assignments[i] = trackPositions[trackIndex]
    end
    
    return assignments
end

function ArchwayService:StartSynchronizedCountdown(players)
    -- Fade from black for all players
    for _, player in pairs(players) do
        if player and player.Parent then
            RemoteEvents.GameFadeFromBlack:FireClient(player)
        end
    end
    
    -- Wait for fade in to complete
    wait(1)
    
    -- Start synchronized countdown for all players
    for _, player in pairs(players) do
        if player and player.Parent then
            RemoteEvents.GameCountdownStart:FireClient(player)
            RemoteEvents.MultiplayerGameInfo:FireClient(player, {
                sessionId = currentMultiplayerSession.sessionId,
                playerCount = #players,
                playerNames = self:GetSessionPlayerNames(players)
            })
        end
    end
    
    -- Server-side countdown
    for i = 3, 1, -1 do
        -- Notify all players of countdown
        for _, player in pairs(players) do
            if player and player.Parent then
                RemoteEvents.SynchronizedCountdown:FireClient(player, i)
            end
        end
        print("⏰ Multiplayer countdown: " .. i)
        wait(1)
    end
    
    -- Start the actual game for all players simultaneously
    local startedGames = 0
    for _, player in pairs(players) do
        if player and player.Parent then
            local success = GameService:StartMultiplayerGame(player, currentMultiplayerSession.sessionId, players)
            if success then
                startedGames = startedGames + 1
            end
        end
    end
    
    print("🎮 Started multiplayer game for " .. startedGames .. "/" .. #players .. " players")
    
    -- Schedule session cleanup
    self:ScheduleSessionCleanup()
end

function ArchwayService:GetSessionPlayerNames(players)
    local names = {}
    for _, player in pairs(players) do
        if player and player.Parent then
            table.insert(names, player.Name)
        end
    end
    return names
end

function ArchwayService:ScheduleSessionCleanup()
    -- Clean up session after 5 minutes with modern API
    task.spawn(function() -- UPDATED for modern API
        task.wait(300) -- UPDATED for modern API - 5 minutes
        
        if currentMultiplayerSession then
            print("🧹 Cleaning up multiplayer session: " .. currentMultiplayerSession.sessionId)
            self:CleanupMultiplayerSession(currentMultiplayerSession.sessionId)
        end
    end)
end

-- Enhanced multiplayer session cleanup
function ArchwayService:CleanupMultiplayerSession(sessionId)
    if not currentMultiplayerSession or currentMultiplayerSession.sessionId ~= sessionId then
        return false
    end
    
    print("🧹 Comprehensive multiplayer session cleanup: " .. sessionId)
    
    -- Clean up all players in the session
    for _, player in pairs(currentMultiplayerSession.players or {}) do
        if player and player.Parent then
            self:CleanupPlayerFromMultiplayer(player)
        end
    end
    
    -- Clear session data
    currentMultiplayerSession = nil
    
    print("✅ Multiplayer session cleanup complete")
    return true
end

-- Clean up inactive multiplayer sessions
function ArchwayService:CleanupInactiveMultiplayerSessions()
    local cleaned = 0
    local currentTime = tick()
    
    -- Clean up current session if it's been inactive too long (15 minutes)
    if currentMultiplayerSession and 
       (currentTime - currentMultiplayerSession.startTime) > 900 then
        print("🧹 Cleaning up inactive multiplayer session")
        self:CleanupMultiplayerSession(currentMultiplayerSession.sessionId)
        cleaned = 1
    end
    
    -- Clean up queue data for disconnected players
    local disconnectedPlayers = {}
    for _, player in pairs(multiplayerQueue) do
        if not player or not player.Parent then
            table.insert(disconnectedPlayers, player)
        end
    end
    
    for _, player in pairs(disconnectedPlayers) do
        self:RemovePlayerFromQueue(player)
        cleaned = cleaned + 1
    end
    
    return cleaned
end

-- Clean up player from multiplayer systems
function ArchwayService:CleanupPlayerFromMultiplayer(player)
    if not player then return false end
    
    local playerId = tostring(player.UserId)
    print("🧹 Cleaning up multiplayer data for player: " .. player.Name)
    
    -- Remove from queue if present
    self:RemovePlayerFromQueue(player)
    
    -- Clean up player-specific queue data
    if playerQueueData[playerId] then
        playerQueueData[playerId] = nil
    end
    
    -- Use MemoryManager to clean up player resources
    MemoryManager:CleanupPlayer(playerId)
    
    return true
end

function ArchwayService:ShowQueueInterface(player)
    -- Check if player wants to join solo or multiplayer
    RemoteEvents.ShowGameModeSelection:FireClient(player)
end

function ArchwayService:StartGameSequence(player, character)
    local userId = tostring(player.UserId)
    
    -- Prevent game start spam
    if activeGameStarts[userId] and tick() - activeGameStarts[userId] < 5 then
        return
    end
    
    activeGameStarts[userId] = tick()
    
    local humanoid = character:FindFirstChildOfClass("Humanoid")
    local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
    
    if not humanoid or not humanoidRootPart then return end
    
    print("🎮 " .. player.Name .. " is starting a new game...")
    
    -- Disable player movement
    humanoid.PlatformStand = true
    
    -- Trigger client fade to black
    RemoteEvents.GameFadeToBlack:FireClient(player)
    
    -- Wait for fade
    wait(1.5)
    
    -- Choose random track start position
    local startPosition = GAME_START_POSITIONS[math.random(1, #GAME_START_POSITIONS)]
    
    -- Teleport player to track start
    humanoidRootPart.CFrame = CFrame.new(startPosition)
    
    -- Re-enable movement
    humanoid.PlatformStand = false
    
    -- Start countdown sequence
    self:StartCountdown(player)
    
    print("🚀 " .. player.Name .. " transported to game track!")
end

function ArchwayService:StartCountdown(player)
    -- Fade from black
    RemoteEvents.GameFadeFromBlack:FireClient(player)
    
    -- Wait for fade in to complete
    wait(1)
    
    -- Start countdown on client
    RemoteEvents.GameCountdownStart:FireClient(player)
    
    -- Server-side countdown
    for i = 3, 1, -1 do
        print("⏰ Countdown for " .. player.Name .. ": " .. i)
        wait(1)
    end
    
    -- Start the actual game
    local success = GameService:StartGame(player)
    if success then
        print("🎮 Game started for " .. player.Name)
    else
        print("❌ Failed to start game for " .. player.Name)
    end
    
    -- Clear countdown state
    local userId = tostring(player.UserId)
    activeGameStarts[userId] = nil
end

function ArchwayService:SetupTriggerDetection()
    local archway = Workspace.MarketPlaza.GameArchway
    if not archway then return end
    
    local triggerZone = archway:FindFirstChild("TriggerZone")
    if not triggerZone then
        warn("Trigger zone not found in archway!")
        return
    end
    
    -- Setup touch detection
    local connection
    connection = triggerZone.Touched:Connect(function(hit)
        local character = hit.Parent
        local humanoid = character:FindFirstChildOfClass("Humanoid")
        local player = Players:GetPlayerFromCharacter(character)
        
        if player and humanoid then
            -- Check if player is coming from the market plaza side
            local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
            if humanoidRootPart and humanoidRootPart.Position.Z > -23 then
                -- Show game mode selection instead of immediately starting
                self:ShowQueueInterface(player)
            end
        end
    end)
    
    print("🎮 Archway trigger detection setup complete")
end

function ArchwayService:Initialize()
    print("🏛️ ArchwayService initializing...")
    
    -- Validate archway-related world objects
    print("🔍 Validating archway world objects...")
    local missingObjects = WorldObjectValidator.validateAllRequired()
    if #missingObjects > 0 then
        warn("⚠️ ArchwayService: Missing required world objects:")
        for _, missing in ipairs(missingObjects) do
            warn("  • " .. missing)
        end
    end
    
    -- Validate game archway specifically
    local archwayExists = WorldObjectValidator.validateObjectWithWait("workspace.MarketPlaza.GameArchway", 5)
    if not archwayExists then
        warn("⚠️ ArchwayService: GameArchway not found - game start may not work")
    else
        print("✅ ArchwayService: GameArchway validated")
    end
    
    -- Validate start and finish lines
    local startLineExists = WorldObjectValidator.validateObjectWithWait("workspace.GameTrack.StartLine", 3)
    local finishLineExists = WorldObjectValidator.validateObjectWithWait("workspace.GameTrack.FinishLine", 3)
    if not startLineExists or not finishLineExists then
        warn("⚠️ ArchwayService: Start/Finish lines missing - game boundaries may not work")
    else
        print("✅ ArchwayService: Game boundaries validated")
    end
    
    -- Wait for workspace to be ready
    wait(1)
    
    -- Setup archway display and animations
    self:SetupArchwayDisplay()
    
    -- Setup trigger detection
    self:SetupTriggerDetection()
    
    -- Setup remote event handlers for queue system with memory management
    local soloGameConnection = RemoteEvents.JoinSoloGame.OnServerEvent:Connect(function(player)
        -- Start solo game immediately
        if player.Character then
            self:StartGameSequence(player, player.Character)
        end
    end)
    MemoryManager:RegisterConnection("system", "solo_game_connection", soloGameConnection)
    table.insert(activeConnections, soloGameConnection)
    
    local joinQueueConnection = RemoteEvents.JoinMultiplayerQueue.OnServerEvent:Connect(function(player)
        self:AddPlayerToQueue(player)
    end)
    MemoryManager:RegisterConnection("system", "join_queue_connection", joinQueueConnection)
    table.insert(activeConnections, joinQueueConnection)
    
    local leaveQueueConnection = RemoteEvents.LeaveMultiplayerQueue.OnServerEvent:Connect(function(player)
        self:RemovePlayerFromQueue(player)
    end)
    MemoryManager:RegisterConnection("system", "leave_queue_connection", leaveQueueConnection)
    table.insert(activeConnections, leaveQueueConnection)
    
    -- Handle player leaving to clean up queue and player data
    local playerRemovingConnection = Players.PlayerRemoving:Connect(function(player)
        self:CleanupPlayerFromMultiplayer(player)
    end)
    MemoryManager:RegisterConnection("system", "player_removing_connection", playerRemovingConnection)
    table.insert(activeConnections, playerRemovingConnection)
    
    print("✅ ArchwayService initialized successfully with memory management!")
end

-- Comprehensive service cleanup
function ArchwayService:Cleanup()
    print("🧹 ArchwayService comprehensive cleanup starting...")
    
    -- Cleanup all active tweens
    for _, tween in pairs(activeTweens) do
        if tween then
            tween:Cancel()
        end
    end
    activeTweens = {}
    
    -- Cleanup all active connections
    for _, connection in pairs(activeConnections) do
        if connection and typeof(connection) == "RBXScriptConnection" then
            connection:Disconnect()
        end
    end
    activeConnections = {}
    
    -- Cleanup multiplayer sessions
    if currentMultiplayerSession then
        self:CleanupMultiplayerSession(currentMultiplayerSession.sessionId)
    end
    
    -- Clear queue
    multiplayerQueue = {}
    playerQueueData = {}
    activeGameStarts = {}
    
    -- Use MemoryManager for system cleanup
    MemoryManager:CleanupPlayer("system")
    
    print("✅ ArchwayService cleanup complete")
end

-- Auto-initialize when required
ArchwayService:Initialize()

return ArchwayService
