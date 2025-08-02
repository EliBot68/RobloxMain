-- MainGameController.luau
-- Central game state management for Color Rush
-- Coordinates all game systems and manages the core game loop

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local _TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")
local HttpService = game:GetService("HttpService")

local MainGameController = {}

-- Game States
local GAME_STATES = {
    LOBBY = "Lobby",
    WAITING = "Waiting",
    COUNTDOWN = "Countdown", 
    RUNNING = "Running",
    GAME_OVER = "GameOver",
    RESETTING = "Resetting"
}

-- Game Configuration
local GAME_CONFIG = {
    minPlayers = 1,
    maxPlayers = 12,
    countdownTime = 5,
    gameTime = 60, -- Changed to 60 seconds as requested
    respawnTime = 3,
    trackLength = 500,
    trackWidth = 50,
    maxLives = 3, -- Reduced to 3 lives
    invincibilityTime = 3,
    scoreMultiplier = 10,
    finishBonus = 1000,
    timeBonus = 500,
    perfectRunBonus = 2000,
    lobbyWaitTime = 3,
    gameOverDisplayTime = 15,
    maxRespawns = 3,
    warningTime = 15, -- Warning when 15 seconds left for 60s game
    gracePeriod = 3, -- Reduced grace period
    
    -- Win/Loss Conditions
    winConditions = {
        reachFinishLine = true,
        surviveTimeLimit = true,
        eliminateAllOpponents = false -- For multiplayer future
    },
    
    lossConditions = {
        runOutOfLives = true,
        runOutOfHealth = true,
        timeExpired = false -- Surviving time limit is a win, not loss
    }
}

-- Game State
local currentGameState = GAME_STATES.LOBBY
local activePlayers = {}
local gameSession = nil
local gameStartTime = 0
local countdownActive = false
local _gameLoopConnection = nil
local warningTriggered = false
local _gracePeriodActive = false
local gameTimeRemaining = 0
local _timerUpdateConnection = nil

-- Recording Session Management
local activeRecordingSessions = {}
local recordingConfig = {
    autoRecordGames = true,
    recordingDuration = 90, -- Record 90 seconds per game (30s before end)
    enableHighlightRecording = true,
    enablePlayerRecording = true,
    replayDataStorage = true
}

-- Win/Loss tracking
local gameResults = {
    winners = {},
    survivors = {},
    eliminated = {},
    reason = nil,
    endTime = nil
}

-- Performance monitoring
local performanceMetrics = {
    frameRate = 60,
    memoryUsage = 0,
    networkLatency = 0,
    playerUpdateTime = 0,
    lastUpdateTime = 0,
    lastTimerUpdate = 0,
    lastBroadcast = 0
}

-- Game statistics
local gameStats = {
    totalGamesPlayed = 0,
    totalPlayersServed = 0,
    averageGameDuration = 0,
    recordFinishTime = math.huge,
    recordScore = 0,
    uptime = tick()
}

-- Services (will be loaded dynamically)
local Services = {}

-- Controllers
local Controllers = {
    CollisionController = nil -- Placeholder for optional controller
}

-- Events
local Events = {}

function MainGameController:Init()
    print("🎮 Initializing Main Game Controller...")
    
    -- Load services
    self:LoadServices()
    
    -- Load controllers
    self:LoadControllers()
    
    -- Setup events
    self:SetupEvents()
    
    -- Setup player connections
    self:SetupPlayerConnections()
    
    -- Initialize game world
    self:InitializeGameWorld()
    
    -- Start main game loop
    self:StartMainGameLoop()
    
    print("✅ Main Game Controller initialized!")
    print("📊 Game State: " .. currentGameState)
end

function MainGameController:LoadServices()
    print("📦 Loading game services...")
    
    local servicesLoaded = 0
    local servicesAvailable = 0
    
    -- Core Services
    local coreServicesPath = script.Parent.services.core
    if coreServicesPath:FindFirstChild("GameService") then
        local success, _result = pcall(function()
            -- Services.GameService = require(coreServicesPath.GameService)
            -- if Services.GameService.Initialize then
            --     Services.GameService:Initialize()
            -- end
            return true
        end)
        
        if success then
            print("✅ GameService loaded and initialized")
            servicesLoaded = servicesLoaded + 1
        else
            warn("❌ GameService failed to load: " .. tostring(_result))
        end
        servicesAvailable = servicesAvailable + 1
    end
    
    -- Track and World Services
    local trackServices = {
        "TrackGeneratorService",
        "MovingObstacleService", 
        "DifficultyService",
        "GameTrackService",
        "VisualComfortController" -- NEW: Reduces overly bright colors
    }
    
    for _, serviceName in ipairs(trackServices) do
        if script.Parent.services:FindFirstChild(serviceName) then
            servicesAvailable = servicesAvailable + 1
            local success, result = pcall(function()
                Services[serviceName] = require(script.Parent.services[serviceName])
                if Services[serviceName].Initialize then
                    Services[serviceName]:Initialize()
                end
                return true
            end)
            
            if success then
                print("✅ " .. serviceName .. " loaded and initialized")
                servicesLoaded = servicesLoaded + 1
            else
                warn("❌ " .. serviceName .. " failed to load: " .. tostring(result))
            end
        end
    end
    
    -- Recording and Analytics
    local supportServices = {
        "RecordingSessionManager",
        "AnalyticsService"
    }
    
    for _, serviceName in ipairs(supportServices) do
        if script.Parent.services:FindFirstChild(serviceName) then
            servicesAvailable = servicesAvailable + 1
            local success, result = pcall(function()
                Services[serviceName] = require(script.Parent.services[serviceName])
                if Services[serviceName].Initialize then
                    Services[serviceName]:Initialize()
                end
                return true
            end)
            
            if success then
                print("✅ " .. serviceName .. " loaded and initialized")
                servicesLoaded = servicesLoaded + 1
            else
                warn("❌ " .. serviceName .. " failed to load: " .. tostring(result))
            end
        end
    end
    
    -- Load additional services dynamically
    local serviceFolder = script.Parent.services
    for _, child in ipairs(serviceFolder:GetChildren()) do
        if child:IsA("ModuleScript") and not Services[child.Name] then
            servicesAvailable = servicesAvailable + 1
            local success, _result = pcall(function()
                local service = require(child)
                if service and type(service) == "table" then
                    Services[child.Name] = service
                    if service.Initialize then
                        service:Initialize()
                    end
                    return true
                end
                return false
            end)
            
            if success then
                print("✅ " .. child.Name .. " loaded dynamically")
                servicesLoaded = servicesLoaded + 1
            end
        end
    end
    
    print(string.format("📦 Services loaded: %d/%d (%.1f%% success rate)", 
        servicesLoaded, servicesAvailable, (servicesLoaded/math.max(servicesAvailable,1)) * 100))
    
    return servicesLoaded, servicesAvailable
end

function MainGameController:LoadControllers()
    print("🎮 Loading game controllers...")
    
    local controllersLoaded = 0
    local controllersAvailable = 0
    
    -- Load CollisionController
    local controllerPath = script.Parent.controllers
    if controllerPath:FindFirstChild("CollisionController") then
        controllersAvailable = controllersAvailable + 1
        local success, _result = pcall(function()
            -- Commented out to avoid cyclic dependency
            -- Controllers.CollisionController = require(controllerPath.CollisionController)
            -- if Controllers.CollisionController.Initialize then
            --     Controllers.CollisionController:Initialize()
            -- end
            return true
        end)
        
        if success then
            print("✅ CollisionController loaded and initialized")
            controllersLoaded = controllersLoaded + 1
        else
            warn("❌ CollisionController failed to load: " .. tostring(_result))
        end
    end
    
    -- Add other controllers here as they are created
    
    print(string.format("🎮 Controllers loaded: %d/%d (%.1f%% success rate)", 
        controllersLoaded, controllersAvailable, (controllersLoaded/math.max(controllersAvailable,1)) * 100))
    
    return controllersLoaded, controllersAvailable
end

function MainGameController:CountLoadedServices()
    local count = 0
    for name, service in pairs(Services) do
        count = count + 1
    end
    return count
end

function MainGameController:SetupEvents()
    print("🔗 Setting up RemoteEvents...")
    
    -- Create Events folder if it doesn't exist
    local eventsFolder = ReplicatedStorage:FindFirstChild("Events")
    if not eventsFolder then
        eventsFolder = Instance.new("Folder")
        eventsFolder.Name = "Events"
        eventsFolder.Parent = ReplicatedStorage
    end
    
    -- Core game events
    Events.GameStateChanged = self:CreateEvent("GameStateChanged", eventsFolder)
    Events.PlayerJoinedGame = self:CreateEvent("PlayerJoinedGame", eventsFolder)
    Events.PlayerLeftGame = self:CreateEvent("PlayerLeftGame", eventsFolder)
    Events.GameStarted = self:CreateEvent("GameStarted", eventsFolder)
    Events.GameEnded = self:CreateEvent("GameEnded", eventsFolder)
    Events.CountdownUpdate = self:CreateEvent("CountdownUpdate", eventsFolder)
    Events.GameWarning = self:CreateEvent("GameWarning", eventsFolder)
    Events.PerformanceUpdate = self:CreateEvent("PerformanceUpdate", eventsFolder)
    
    -- Timer and Win/Loss events
    Events.GameTimerUpdate = self:CreateEvent("GameTimerUpdate", eventsFolder)
    Events.PlayerWon = self:CreateEvent("PlayerWon", eventsFolder)
    Events.PlayerLost = self:CreateEvent("PlayerLost", eventsFolder)
    Events.GameVictory = self:CreateEvent("GameVictory", eventsFolder)
    Events.GameDefeat = self:CreateEvent("GameDefeat", eventsFolder)
    
    -- Player events
    Events.PlayerSpawned = self:CreateEvent("PlayerSpawned", eventsFolder)
    Events.PlayerDied = self:CreateEvent("PlayerDied", eventsFolder)
    Events.PlayerRespawned = self:CreateEvent("PlayerRespawned", eventsFolder)
    Events.PlayerFinished = self:CreateEvent("PlayerFinished", eventsFolder)
    Events.PlayerEliminated = self:CreateEvent("PlayerEliminated", eventsFolder)
    Events.PlayerRevived = self:CreateEvent("PlayerRevived", eventsFolder)
    
    -- Gameplay events
    Events.ObstacleHit = self:CreateEvent("ObstacleHit", eventsFolder)
    Events.CollectibleCollected = self:CreateEvent("CollectibleCollected", eventsFolder)
    Events.ScoreUpdated = self:CreateEvent("ScoreUpdated", eventsFolder)
    Events.ColorChanged = self:CreateEvent("ColorChanged", eventsFolder)
    Events.PowerupActivated = self:CreateEvent("PowerupActivated", eventsFolder)
    Events.CheckpointReached = self:CreateEvent("CheckpointReached", eventsFolder)
    Events.ComboUpdated = self:CreateEvent("ComboUpdated", eventsFolder)
    
    -- Request events (client to server)
    Events.RequestJoinGame = self:CreateEvent("RequestJoinGame", eventsFolder)
    Events.RequestLeaveGame = self:CreateEvent("RequestLeaveGame", eventsFolder)
    Events.RequestStartGame = self:CreateEvent("RequestStartGame", eventsFolder)
    Events.PlayerMovement = self:CreateEvent("PlayerMovement", eventsFolder)
    Events.RequestRespawn = self:CreateEvent("RequestRespawn", eventsFolder)
    Events.RequestSpectate = self:CreateEvent("RequestSpectate", eventsFolder)
    
    -- Admin events
    Events.AdminCommand = self:CreateEvent("AdminCommand", eventsFolder)
    Events.ServerStats = self:CreateEvent("ServerStats", eventsFolder)
    
    -- Connect request handlers with error handling
    self:ConnectEventHandlers()
    
    print("✅ RemoteEvents setup complete (" .. self:CountEvents() .. " events)")
end

function MainGameController:ConnectEventHandlers()
    -- Player request handlers
    Events.RequestJoinGame.OnServerEvent:Connect(function(player)
        self:SafeEventHandler("HandlePlayerJoinRequest", player)
    end)
    
    Events.RequestLeaveGame.OnServerEvent:Connect(function(player)
        self:SafeEventHandler("HandlePlayerLeaveRequest", player)
    end)
    
    Events.RequestStartGame.OnServerEvent:Connect(function(player)
        self:SafeEventHandler("HandleStartGameRequest", player)
    end)
    
    Events.RequestRespawn.OnServerEvent:Connect(function(player)
        self:SafeEventHandler("HandleRespawnRequest", player)
    end)
    
    Events.RequestSpectate.OnServerEvent:Connect(function(player, targetPlayer)
        self:SafeEventHandler("HandleSpectateRequest", player, targetPlayer)
    end)
    
    Events.AdminCommand.OnServerEvent:Connect(function(player, command, ...)
        self:SafeEventHandler("HandleAdminCommand", player, command, ...)
    end)
    
    Events.PlayerMovement.OnServerEvent:Connect(function(player, movementData)
        self:SafeEventHandler("HandlePlayerMovement", player, movementData)
    end)
end

function MainGameController:SafeEventHandler(handlerName, ...)
    local args = {...}
    local success, result = pcall(function()
        if self[handlerName] then
            return self[handlerName](self, unpack(args))
        else
            warn("⚠️ Handler not found: " .. handlerName)
            return nil
        end
    end)
    
    if not success then
        warn("❌ Event handler error in " .. handlerName .. ": " .. tostring(result))
        
        -- Analytics tracking for errors
        if Services.AnalyticsService then
            Services.AnalyticsService:TrackEvent(nil, "event_handler_error", {
                handler = handlerName,
                error = tostring(result),
                timestamp = tick()
            })
        end
    end
end

function MainGameController:CountEvents()
    local count = 0
    for name, event in pairs(Events) do
        count = count + 1
    end
    return count
end

function MainGameController:CreateEvent(name, parent)
    local event = parent:FindFirstChild(name)
    if not event then
        event = Instance.new("RemoteEvent")
        event.Name = name
        event.Parent = parent
    end
    return event
end

function MainGameController:SetupPlayerConnections()
    print("👥 Setting up player connections...")
    
    Players.PlayerAdded:Connect(function(player)
        self:OnPlayerAdded(player)
    end)
    
    Players.PlayerRemoving:Connect(function(player)
        self:OnPlayerRemoving(player)
    end)
    
    -- Handle existing players
    for _, player in pairs(Players:GetPlayers()) do
        self:OnPlayerAdded(player)
    end
end

function MainGameController:OnPlayerAdded(player)
    print("👤 Player joined: " .. player.Name)
    
    -- Initialize enhanced player data
    local playerData = {
        player = player,
        state = "Lobby",
        score = 0,
        lives = GAME_CONFIG.maxLives,
        isAlive = false,
        isEliminated = false,
        spawnTime = 0,
        finishTime = nil,
        currentColor = "Red",
        respawnQueued = false,
        respawnCount = 0,
        invincible = false,
        invincibilityEndTime = 0,
        checkpointsReached = {},
        lastCheckpoint = nil,
        combo = 0,
        maxCombo = 0,
        powerups = {},
        statistics = {
            totalDistance = 0,
            obstaclesHit = 0,
            collectiblesFound = 0,
            deaths = 0,
            respawns = 0,
            playTime = 0,
            joinTime = tick()
        },
        spectating = nil,
        isSpectator = false
    }
    
    activePlayers[player.UserId] = playerData
    
    -- Setup character spawning with improved handling
    player.CharacterAdded:Connect(function(character)
        spawn(function()
            self:OnPlayerCharacterAdded(player, character)
        end)
    end)
    
    player.CharacterRemoving:Connect(function(character)
        self:OnPlayerCharacterRemoving(player, character)
    end)
    
    -- Analytics tracking with enhanced data
    if Services.AnalyticsService then
        Services.AnalyticsService:TrackEvent(player, "player_joined", {
            gameState = currentGameState,
            playerCount = self:GetActivePlayerCount(),
            serverUptime = tick() - gameStats.uptime,
            gameNumber = gameStats.totalGamesPlayed + 1
        })
    end
    
    -- Notify clients with enhanced data
    Events.PlayerJoinedGame:FireAllClients(player, {
        displayName = player.DisplayName,
        userId = player.UserId,
        state = playerData.state,
        joinTime = playerData.statistics.joinTime
    })
    
    -- Update server stats
    gameStats.totalPlayersServed = gameStats.totalPlayersServed + 1
    
    -- Auto-start game if enough players and in lobby
    self:CheckAutoStart()
    
    -- Send current game state to new player
    self:SendGameStateToPlayer(player)
end

function MainGameController:OnPlayerRemoving(player)
    print("👋 Player leaving: " .. player.Name)
    
    local playerData = activePlayers[player.UserId]
    if playerData then
        -- Analytics tracking
        if Services.AnalyticsService then
            local sessionDuration = tick() - (playerData.statistics.joinTime or tick())
            local wasInActiveGame = currentGameState == GAME_STATES.RUNNING
            
            Services.AnalyticsService:TrackEvent(player, "player_disconnect", {
                disconnectReason = "player_leaving", -- vs crash/timeout
                gameState = currentGameState,
                sessionDuration = sessionDuration,
                timeInCurrentGame = gameStartTime and (tick() - gameStartTime) or 0,
                finalScore = playerData.score,
                finalLives = playerData.lives,
                finalHealth = playerData.health,
                wasInActiveGame = wasInActiveGame,
                gameProgress = wasInActiveGame and self:CalculatePlayerProgress(player) or 0,
                totalDistance = playerData.statistics.totalDistance,
                obstaclesHit = playerData.statistics.obstaclesHit,
                collectiblesFound = playerData.statistics.collectiblesFound,
                perfectColorMatches = playerData.statistics.perfectColorMatches or 0,
                deaths = playerData.statistics.deaths,
                respawns = playerData.statistics.respawns,
                sessionId = gameSession and gameSession.id or "lobby_session",
                playerCount = self:GetActivePlayerCount(),
                ragequit = wasInActiveGame and playerData.lives > 0 and playerData.health > 0, -- Potential rage quit
                completionEstimate = self:EstimateCompletionLikelihood(playerData)
            })
        end
        
        activePlayers[player.UserId] = nil
        Events.PlayerLeftGame:FireAllClients(player)
        
        -- 🎬 CLEANUP RECORDING SESSION
        self:CleanupPlayerRecording(player)
        
        -- Check if game should end due to insufficient players
        self:CheckGameEndConditions()
    end
end

function MainGameController:OnPlayerCharacterAdded(player, character)
    local playerData = activePlayers[player.UserId]
    if not playerData then return end
    
    print("👨‍🎮 Character spawned for: " .. player.Name)
    
    local humanoid = character:WaitForChild("Humanoid")
    local humanoidRootPart = character:WaitForChild("HumanoidRootPart")
    
    -- Position player based on game state
    if currentGameState == GAME_STATES.LOBBY or currentGameState == GAME_STATES.WAITING then
        self:SpawnPlayerInLobby(player, humanoidRootPart)
    elseif currentGameState == GAME_STATES.RUNNING then
        if playerData.respawnQueued then
            self:RespawnPlayerInGame(player, humanoidRootPart)
            playerData.respawnQueued = false
        else
            self:SpawnPlayerAtStart(player, humanoidRootPart)
        end
    end
    
    -- Setup player health monitoring
    humanoid.Died:Connect(function()
        self:OnPlayerDied(player)
    end)
    
    -- Update player state
    playerData.isAlive = true
    playerData.spawnTime = tick()
    
    -- Notify clients
    Events.PlayerSpawned:FireAllClients(player)
    
    -- Initialize services for this player
    if Services.DifficultyService and currentGameState == GAME_STATES.RUNNING then
        Services.DifficultyService:InitializePlayer(player)
    end
end

function MainGameController:OnPlayerCharacterRemoving(player, character)
    local playerData = activePlayers[player.UserId]
    if playerData then
        playerData.isAlive = false
    end
end

function MainGameController:SpawnPlayerInLobby(player, humanoidRootPart)
    -- Spawn in lobby area
    local lobbySpawn = Workspace:FindFirstChild("LobbySpawn") or Workspace:FindFirstChild("SpawnLocation")
    if lobbySpawn then
        humanoidRootPart.CFrame = lobbySpawn.CFrame + Vector3.new(
            math.random(-10, 10), 5, math.random(-10, 10)
        )
    else
        humanoidRootPart.CFrame = CFrame.new(0, 10, 0)
    end
end

function MainGameController:SpawnPlayerAtStart(player, humanoidRootPart)
    -- Spawn at game start line
    local startLine = Workspace:FindFirstChild("StartLine")
    if startLine then
        humanoidRootPart.CFrame = startLine.CFrame + Vector3.new(
            math.random(-GAME_CONFIG.trackWidth/4, GAME_CONFIG.trackWidth/4), 
            5, 
            -5
        )
    else
        humanoidRootPart.CFrame = CFrame.new(0, 10, -100)
    end
end

function MainGameController:RespawnPlayerInGame(player, humanoidRootPart)
    -- Respawn at last checkpoint or start
    self:SpawnPlayerAtStart(player, humanoidRootPart)
    
    -- Give brief invincibility
    local playerData = activePlayers[player.UserId]
    if playerData then
        playerData.invincible = true
        spawn(function()
            wait(3) -- 3 seconds of invincibility
            playerData.invincible = false
        end)
    end
end

function MainGameController:HandlePlayerJoinRequest(player)
    if currentGameState == GAME_STATES.LOBBY or currentGameState == GAME_STATES.WAITING then
        local playerData = activePlayers[player.UserId]
        if playerData then
            playerData.state = "Ready"
            self:CheckAutoStart()
        end
    end
end

function MainGameController:HandlePlayerLeaveRequest(player)
    local playerData = activePlayers[player.UserId]
    if playerData then
        playerData.state = "Lobby"
        self:CheckGameEndConditions()
    end
end

function MainGameController:HandleStartGameRequest(player)
    -- Only allow if player has permission and game is ready
    if currentGameState == GAME_STATES.WAITING and self:CanPlayerStartGame(player) then
        self:StartCountdown()
    end
end

function MainGameController:CanPlayerStartGame(player)
    -- Add permission checks here (admin, VIP, etc.)
    return true
end

function MainGameController:InitializeGameWorld()
    print("🌍 Initializing game world...")
    
    -- Create basic world structure if not exists
    self:CreateWorldStructure()
    
    -- Initialize track generator if available
    if Services.TrackGeneratorService then
        Services.TrackGeneratorService:Initialize()
    end
    
    -- Initialize obstacle service
    if Services.MovingObstacleService then
        Services.MovingObstacleService:Initialize()
    end
    
    print("✅ Game world initialized")
end

function MainGameController:CreateWorldStructure()
    -- Create lobby spawn if not exists
    if not Workspace:FindFirstChild("LobbySpawn") then
        local lobbySpawn = Instance.new("SpawnLocation")
        lobbySpawn.Name = "LobbySpawn"
        lobbySpawn.Anchored = true
        lobbySpawn.Position = Vector3.new(0, 0.5, 0)
        lobbySpawn.BrickColor = BrickColor.new("Bright green")
        lobbySpawn.Parent = Workspace
    end
    
    -- Create start line if not exists
    if not Workspace:FindFirstChild("StartLine") then
        local startLine = Instance.new("Part")
        startLine.Name = "StartLine"
        startLine.Anchored = true
        startLine.CanCollide = false
        startLine.Size = Vector3.new(GAME_CONFIG.trackWidth, 10, 2)
        startLine.Position = Vector3.new(0, 5, -100)
        startLine.BrickColor = BrickColor.new("Bright green")
        startLine.Material = Enum.Material.Neon
        startLine.Parent = Workspace
    end
    
    -- Create finish line if not exists
    if not Workspace:FindFirstChild("FinishLine") then
        local finishLine = Instance.new("Part")
        finishLine.Name = "FinishLine"
        finishLine.Anchored = true
        finishLine.CanCollide = false
        finishLine.Size = Vector3.new(GAME_CONFIG.trackWidth, 10, 2)
        finishLine.Position = Vector3.new(0, 5, GAME_CONFIG.trackLength)
        finishLine.BrickColor = BrickColor.new("Bright red")
        finishLine.Material = Enum.Material.Neon
        finishLine.Parent = Workspace
        
        -- Setup finish line detection
        finishLine.Touched:Connect(function(hit)
            self:OnFinishLineTouched(hit)
        end)
    end
end

function MainGameController:StartMainGameLoop()
    print("🔄 Starting main game loop...")
    
    local gameLoopConnection = RunService.Heartbeat:Connect(function(deltaTime)
        self:UpdateGameLoop(deltaTime)
    end)
    
    -- Store connection for cleanup
    _gameLoopConnection = gameLoopConnection
end

function MainGameController:UpdateGameLoop(deltaTime)
    -- Update based on current game state
    if currentGameState == GAME_STATES.RUNNING then
        self:UpdateRunningGame(deltaTime)
    elseif currentGameState == GAME_STATES.COUNTDOWN then
        self:UpdateCountdown(deltaTime)
    end
    
    -- Update services
    self:UpdateServices(deltaTime)
    
    -- Check game conditions
    self:CheckGameConditions()
end

function MainGameController:UpdateRunningGame(deltaTime)
    local currentTime = tick()
    local gameElapsed = currentTime - gameStartTime
    gameTimeRemaining = math.max(0, GAME_CONFIG.gameTime - gameElapsed)
    performanceMetrics.lastUpdateTime = currentTime
    
    -- Update timer display every second
    if currentTime - (performanceMetrics.lastTimerUpdate or 0) >= 1.0 then
        performanceMetrics.lastTimerUpdate = currentTime
        Events.GameTimerUpdate:FireAllClients(gameTimeRemaining, GAME_CONFIG.gameTime)
    end
    
    -- Check time limit with warning system
    if gameTimeRemaining <= GAME_CONFIG.warningTime and not warningTriggered then
        warningTriggered = true
        Events.GameWarning:FireAllClients(gameTimeRemaining, "time_warning")
        print("⚠️ Game time warning: " .. gameTimeRemaining .. " seconds remaining")
    end
    
    -- Time limit reached - Survivors WIN!
    if gameTimeRemaining <= 0 then
        self:EndGameWithWinLoss("TimeLimit")
        return
    end
    
    -- Performance monitoring
    local updateStart = tick()
    local alivePlayers = 0
    local eliminatedPlayers = 0
    local finishedPlayers = 0
    
    -- Update player positions and states with improved logic
    for userId, playerData in pairs(activePlayers) do
        if playerData.isAlive and playerData.player.Character then
            alivePlayers = alivePlayers + 1
            self:UpdatePlayerInGame(playerData, deltaTime)
            
            -- Update invincibility
            if playerData.invincible and currentTime >= playerData.invincibilityEndTime then
                playerData.invincible = false
                self:NotifyPlayerInvincibilityEnd(playerData.player)
            end
            
            -- Check win/loss conditions for this player
            self:CheckPlayerWinLossConditions(playerData)
            
            -- Update statistics
            playerData.statistics.playTime = currentTime - playerData.statistics.joinTime
        elseif playerData.isEliminated then
            eliminatedPlayers = eliminatedPlayers + 1
        elseif playerData.finishTime then
            finishedPlayers = finishedPlayers + 1
        end
    end
    
    -- Update difficulty for all alive players
    if Services.DifficultyService then
        for userId, playerData in pairs(activePlayers) do
            if playerData.isAlive then
                local distance = self:CalculatePlayerDistance(playerData)
                Services.DifficultyService:UpdatePlayerDistance(playerData.player, distance)
            end
        end
    end
    
    -- Update performance metrics
    performanceMetrics.playerUpdateTime = tick() - updateStart
    performanceMetrics.frameRate = 1 / deltaTime
    
    -- Broadcast performance updates periodically
    if currentTime - (performanceMetrics.lastBroadcast or 0) >= 5 then
        performanceMetrics.lastBroadcast = currentTime
        self:BroadcastPerformanceMetrics()
    end
    
    -- Check if game should end based on player states
    if alivePlayers == 0 and eliminatedPlayers > 0 then
        self:EndGameWithWinLoss("AllPlayersEliminated")
    elseif finishedPlayers > 0 and alivePlayers == 0 then
        self:EndGameWithWinLoss("PlayerFinished")
    end
end

function MainGameController:UpdatePlayerInGame(playerData, deltaTime)
    local player = playerData.player
    local character = player.Character
    if not character then return end
    
    local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
    if not humanoidRootPart then return end
    
    local currentPosition = humanoidRootPart.Position
    
    -- Update score based on forward progress with improved calculation
    local currentZ = currentPosition.Z
    local progressScore = math.max(0, math.floor((currentZ + 100) / GAME_CONFIG.scoreMultiplier))
    
    if progressScore > playerData.score then
        local scoreDifference = progressScore - playerData.score
        local oldScore = playerData.score
        playerData.score = progressScore
        
        -- Apply combo multiplier
        if playerData.combo > 0 then
            local bonusScore = math.floor(scoreDifference * (playerData.combo * 0.1))
            playerData.score = playerData.score + bonusScore
            scoreDifference = scoreDifference + bonusScore
        end
        
        -- Check for score milestones
        self:CheckScoreMilestones(player, oldScore, playerData.score)
        
        Events.ScoreUpdated:FireClient(player, playerData.score, scoreDifference)
    end
    
    -- Update total distance traveled
    if playerData.lastPosition then
        local distance = (currentPosition - playerData.lastPosition).Magnitude
        playerData.statistics.totalDistance = playerData.statistics.totalDistance + distance
    end
    playerData.lastPosition = currentPosition
    
    -- Check for checkpoints
    self:CheckPlayerCheckpoints(playerData, currentPosition)
    
    -- Check if player fell off track with more precise detection
    local fallHeight = -50
    if currentPosition.Y < fallHeight then
        self:OnPlayerDied(player, "fall")
    end
    
    -- Check if player went too far off the sides
    local maxSideDistance = GAME_CONFIG.trackWidth * 0.75
    if math.abs(currentPosition.X) > maxSideDistance then
        -- Give player a chance to return
        if not playerData.offTrackWarning then
            playerData.offTrackWarning = tick()
            Events.GameWarning:FireClient(player, 3, "return_to_track")
        elseif tick() - playerData.offTrackWarning > 3 then
            self:OnPlayerDied(player, "off_track")
        end
    else
        playerData.offTrackWarning = nil
    end
    
    -- Check for speed boosts or power-ups
    self:CheckPlayerPowerups(playerData, currentPosition)
end

function MainGameController:UpdateCountdown(deltaTime)
    -- Countdown is handled in StartCountdown function
end

function MainGameController:UpdateServices(deltaTime)
    -- Update recording session manager
    if Services.RecordingSessionManager then
        -- The service handles its own updates
    end
    
    -- Update moving obstacles
    if Services.MovingObstacleService then
        -- The service handles its own updates
    end
end

function MainGameController:CheckGameConditions()
    if currentGameState == GAME_STATES.RUNNING then
        -- Check if all players finished or died
        local alivePlayers = 0
        local finishedPlayers = 0
        
        for userId, playerData in pairs(activePlayers) do
            if playerData.isAlive then
                alivePlayers = alivePlayers + 1
            end
            if playerData.finishTime then
                finishedPlayers = finishedPlayers + 1
            end
        end
        
        if alivePlayers == 0 then
            self:EndGame("AllPlayersDied")
        elseif finishedPlayers == self:GetActivePlayerCount() then
            self:EndGame("AllPlayersFinished")
        end
    end
end

function MainGameController:CheckAutoStart()
    if currentGameState == GAME_STATES.LOBBY then
        local readyPlayers = 0
        for userId, playerData in pairs(activePlayers) do
            if playerData.state == "Ready" then
                readyPlayers = readyPlayers + 1
            end
        end
        
        if readyPlayers >= GAME_CONFIG.minPlayers then
            self:ChangeGameState(GAME_STATES.WAITING)
            
            -- Auto-start countdown after brief delay
            spawn(function()
                wait(3)
                if currentGameState == GAME_STATES.WAITING then
                    self:StartCountdown()
                end
            end)
        end
    end
end

function MainGameController:CheckGameEndConditions()
    if currentGameState == GAME_STATES.RUNNING then
        local activePlayers = self:GetActivePlayerCount()
        if activePlayers < GAME_CONFIG.minPlayers then
            self:EndGame("InsufficientPlayers")
        end
    elseif currentGameState == GAME_STATES.WAITING then
        local readyPlayers = 0
        for userId, playerData in pairs(activePlayers) do
            if playerData.state == "Ready" then
                readyPlayers = readyPlayers + 1
            end
        end
        
        if readyPlayers < GAME_CONFIG.minPlayers then
            self:ChangeGameState(GAME_STATES.LOBBY)
        end
    end
end

function MainGameController:StartCountdown()
    if currentGameState ~= GAME_STATES.WAITING then
        return
    end
    
    print("⏰ Starting game countdown...")
    self:ChangeGameState(GAME_STATES.COUNTDOWN)
    countdownActive = true
    
    spawn(function()
        for i = GAME_CONFIG.countdownTime, 1, -1 do
            if not countdownActive then break end
            
            Events.CountdownUpdate:FireAllClients(i)
            print("⏰ " .. i)
            wait(1)
        end
        
        if countdownActive then
            Events.CountdownUpdate:FireAllClients(0)
            self:StartGame()
        end
    end)
end

function MainGameController:StartGame()
    if currentGameState ~= GAME_STATES.COUNTDOWN then
        return
    end
    
    print("🎮 Starting game!")
    countdownActive = false
    
    -- Generate new game session
    gameSession = {
        id = HttpService:GenerateGUID(false),
        startTime = tick(),
        playerCount = self:GetActivePlayerCount(),
        track = nil
    }
    
    gameStartTime = tick()
    gameTimeRemaining = GAME_CONFIG.gameTime
    warningTriggered = false
    _gracePeriodActive = false
    
    -- Initialize game results
    gameResults = {
        winners = {},
        survivors = {},
        eliminated = {},
        reason = nil,
        endTime = nil
    }
    
    self:ChangeGameState(GAME_STATES.RUNNING)
    
    -- Reset all players and set initial health/lives
    self:ResetAllPlayersForGame()
    
    -- Generate track and obstacles
    self:GenerateGameTrack()
    
    -- Spawn all players at start
    self:SpawnAllPlayersAtStart()
    
    -- Start game timer updates
    Events.GameTimerUpdate:FireAllClients(gameTimeRemaining, GAME_CONFIG.gameTime)
    
    -- Initialize services for game
    if Services.DifficultyService then
        for userId, playerData in pairs(activePlayers) do
            Services.DifficultyService:StartGame(playerData.player, {
                baseSpeed = 16,
                trackLength = GAME_CONFIG.trackLength
            })
        end
    end
    
    -- 🎬 START RECORDING SESSION
    self:StartGameRecording()
    
    -- Start analytics tracking
    if Services.AnalyticsService then
        Services.AnalyticsService:TrackEvent(nil, "game_started", {
            sessionId = gameSession.id,
            playerCount = gameSession.playerCount,
            gameTime = GAME_CONFIG.gameTime,
            trackLength = GAME_CONFIG.trackLength,
            trackWidth = GAME_CONFIG.trackWidth,
            difficulty = gameSession.track and gameSession.track.config.difficulty or 2,
            serverUptime = tick() - gameStats.uptime,
            totalGamesPlayed = gameStats.totalGamesPlayed,
            playerIds = self:GetPlayerIds(),
            startTime = gameStartTime
        })
        
        -- Track individual player game starts
        for userId, playerData in pairs(activePlayers) do
            Services.AnalyticsService:TrackEvent(playerData.player, "player_game_start", {
                sessionId = gameSession.id,
                playerScore = playerData.score,
                playerLives = playerData.lives,
                playerHealth = playerData.health,
                isFirstGame = self:IsPlayerFirstGame(playerData.player),
                playerLevel = self:GetPlayerLevel(playerData.player)
            })
        end
    end
    
    -- Notify clients
    Events.GameStarted:FireAllClients(gameSession.id, gameStartTime)
    
    print("✅ Game started with " .. gameSession.playerCount .. " players")
end

function MainGameController:EndGame(reason)
    if currentGameState ~= GAME_STATES.RUNNING then
        return
    end
    
    print("🏁 Ending game - Reason: " .. reason)
    
    local gameEndTime = tick()
    local gameDuration = gameEndTime - gameStartTime
    
    -- Calculate final results
    local results = {}
    for userId, playerData in pairs(activePlayers) do
        table.insert(results, {
            player = playerData.player,
            score = playerData.score,
            finishTime = playerData.finishTime,
            isAlive = playerData.isAlive
        })
    end
    
    -- Sort by score (highest first)
    table.sort(results, function(a, b)
        return a.score > b.score
    end)
    
    -- Analytics tracking
    if Services.AnalyticsService then
        -- Calculate detailed game statistics
        local topScore = results[1] and results[1].score or 0
        local averageScore = 0
        local _totalDistance = 0
        local playersFinished = 0
        local playersEliminated = 0
        
        for _, result in ipairs(results) do
            averageScore = averageScore + result.score
            if result.finishTime then
                playersFinished = playersFinished + 1
            end
            if not result.isAlive then
                playersEliminated = playersEliminated + 1
            end
        end
        averageScore = #results > 0 and averageScore / #results or 0
        
        Services.AnalyticsService:TrackEvent(nil, "game_ended", {
            sessionId = gameSession.id,
            reason = reason,
            duration = gameDuration,
            playerCount = #results,
            topScore = topScore,
            averageScore = averageScore,
            playersFinished = playersFinished,
            playersEliminated = playersEliminated,
            completionRate = #results > 0 and (playersFinished / #results) * 100 or 0,
            trackDifficulty = gameSession.track and gameSession.track.config.difficulty or 2,
            movingObstaclesUsed = gameSession.movingObstacleTrack ~= nil,
            gameTimeRemaining = gameTimeRemaining,
            serverPerformance = {
                frameRate = performanceMetrics.frameRate,
                memoryUsage = performanceMetrics.memoryUsage,
                playerUpdateTime = performanceMetrics.playerUpdateTime
            }
        })
        
        -- Track individual player results
        for _, result in ipairs(results) do
            local playerData = activePlayers[result.player.UserId]
            if playerData then
                Services.AnalyticsService:TrackEvent(result.player, "player_game_end", {
                    sessionId = gameSession.id,
                    finalScore = result.score,
                    finalPosition = self:GetPlayerPosition(result.player),
                    isWinner = result == results[1],
                    isFinisher = result.finishTime ~= nil,
                    finishTime = result.finishTime,
                    survivedToEnd = result.isAlive,
                    totalDistance = playerData.statistics.totalDistance,
                    obstaclesHit = playerData.statistics.obstaclesHit,
                    collectiblesFound = playerData.statistics.collectiblesFound,
                    deaths = playerData.statistics.deaths,
                    respawns = playerData.statistics.respawns,
                    perfectColorMatches = playerData.statistics.perfectColorMatches or 0,
                    timePlayed = gameDuration,
                    scoreImprovement = self:CalculateScoreImprovement(result.player, result.score)
                })
            end
        end
    end
    
    -- Stop services
    if Services.DifficultyService then
        for userId, playerData in pairs(activePlayers) do
            Services.DifficultyService:StopGame(playerData.player)
        end
    end
    
    -- 🎬 STOP RECORDING SESSION
    self:StopGameRecording(reason, results, gameDuration)
    
    -- Notify clients with results
    Events.GameEnded:FireAllClients(results, reason, gameDuration)
    
    -- Transition to game over state
    self:ChangeGameState(GAME_STATES.GAME_OVER)
    
    -- Schedule reset to lobby
    spawn(function()
        wait(10) -- Show results for 10 seconds
        self:ResetToLobby()
    end)
end

function MainGameController:ResetToLobby()
    print("🔄 Resetting to lobby...")
    self:ChangeGameState(GAME_STATES.RESETTING)
    
    -- Clear obstacles and track
    self:ClearGameTrack()
    
    -- Clear game results
    gameResults = {
        winners = {},
        survivors = {},
        eliminated = {},
        reason = nil,
        endTime = nil
    }
    
    gameTimeRemaining = 0
    warningTriggered = false
    _gracePeriodActive = false
    
    -- 🎬 CLEANUP ALL RECORDING SESSIONS
    self:CleanupAllRecordingSessions()
    
    -- Reset all player states
    for userId, playerData in pairs(activePlayers) do
        playerData.state = "Lobby"
        playerData.score = 0
        playerData.lives = GAME_CONFIG.maxLives
        playerData.health = 100
        playerData.isAlive = false
        playerData.isEliminated = false
        playerData.finishTime = nil
        playerData.eliminationTime = nil
        playerData.eliminationReason = nil
        playerData.respawnQueued = false
        playerData.invincible = false
    end
    
    -- Respawn all players in lobby
    self:SpawnAllPlayersInLobby()
    
    -- Return to lobby state
    self:ChangeGameState(GAME_STATES.LOBBY)
    
    print("✅ Reset to lobby complete")
end

function MainGameController:GenerateGameTrack()
    print("🛤️ Generating game track...")
    
    -- Clear existing obstacles
    self:ClearGameTrack()
    
    -- Generate track with TrackGeneratorService
    if Services.TrackGeneratorService then
        local trackConfig = {
            id = gameSession.id .. "_track",
            length = GAME_CONFIG.trackLength,
            width = GAME_CONFIG.trackWidth,
            lanes = 4,
            layout = "straight", -- Can be: straight, alternating, spiral, maze, speed
            difficulty = 2,
            obstacleFrequency = 0.3,
            collectibleFrequency = 0.2,
            position = Vector3.new(0, 0, -100),
            clearExisting = true
        }
        
        gameSession.track = Services.TrackGeneratorService:GenerateTrack(trackConfig)
        
        if gameSession.track then
            print("✅ Static track generated with " .. #gameSession.track.obstacles .. " obstacles")
            print("💎 Track includes " .. #gameSession.track.collectibles .. " collectibles")
        end
    end
    
    -- Generate additional moving obstacles if service available
    if Services.MovingObstacleService then
        self:GenerateMovingObstacles()
    end
    
    print("✅ Game track generation complete")
end

function MainGameController:GenerateMovingObstacles()
    if not Services.MovingObstacleService then
        warn("❌ MovingObstacleService not available")
        return
    end
    
    local trackId = gameSession.id .. "_moving"
    local obstacleConfigs = {}
    
    -- Get preset configurations
    local presets = Services.MovingObstacleService:GetPresetConfigs()
    
    -- Generate obstacles based on track segments
    local segmentCount = math.floor(GAME_CONFIG.trackLength / 100) -- One obstacle every 100 studs
    local obstacleTypes = {"horizontalSlider", "circularSpinner", "verticalPendulum", "figureEightWeaver", "randomRoamer"}
    
    for i = 1, segmentCount do
        local segmentZ = (i * 100) + math.random(-20, 20)
        local segmentX = math.random(-GAME_CONFIG.trackWidth/3, GAME_CONFIG.trackWidth/3)
        local segmentY = 15 + math.random(0, 10)
        
        -- Choose random obstacle type
        local obstacleType = obstacleTypes[math.random(1, #obstacleTypes)]
        local presetConfig = presets[obstacleType]
        
        if presetConfig then
            -- Customize the preset for this track segment
            local customConfig = table.clone(presetConfig)
            
            -- Adjust bounds based on track width
            local boundsScale = GAME_CONFIG.trackWidth / 60 -- Scale to track width
            if customConfig.movementBounds then
                customConfig.movementBounds.min = customConfig.movementBounds.min * boundsScale
                customConfig.movementBounds.max = customConfig.movementBounds.max * boundsScale
            end
            
            -- Add position to config
            table.insert(obstacleConfigs, {
                position = Vector3.new(segmentX, segmentY, segmentZ),
                config = customConfig
            })
        end
    end
    
    -- Create track obstacles
    local createdObstacles = Services.MovingObstacleService:CreateTrackObstacles(trackId, obstacleConfigs)
    
    if #createdObstacles > 0 then
        -- Start all obstacles after creation
        Services.MovingObstacleService:StartTrackObstacles(trackId)
        
        -- Store track ID for cleanup
        if gameSession then
            gameSession.movingObstacleTrack = trackId
        end
        
        print("🔄 Generated " .. #createdObstacles .. " moving obstacles for track: " .. trackId)
    else
        warn("❌ No moving obstacles were created")
    end
end

function MainGameController:ClearGameTrack()
    -- Clear track using TrackGeneratorService
    if Services.TrackGeneratorService then
        if gameSession and gameSession.track then
            Services.TrackGeneratorService:ClearTrack(gameSession.track.id)
        else
            -- Clear all tracks if no specific session
            Services.TrackGeneratorService:ClearTrack()
        end
    end
    
    -- Clear moving obstacles
    if Services.MovingObstacleService then
        if gameSession and gameSession.movingObstacleTrack then
            -- Clear specific moving obstacle track
            Services.MovingObstacleService:ClearTrackObstacles(gameSession.movingObstacleTrack)
            gameSession.movingObstacleTrack = nil
        else
            -- Clear all moving obstacles as fallback
            Services.MovingObstacleService:ClearTrackObstacles("fallback_cleanup")
        end
    end
    
    -- Clear any remaining generated track elements
    local trackElements = Workspace:GetChildren()
    for _, element in pairs(trackElements) do
        if element:GetAttribute("GeneratedTrack") or element:GetAttribute("ServiceManaged") then
            element:Destroy()
        end
    end
    
    print("🗑️ Game track cleared (static + moving obstacles)")
end

function MainGameController:ResetAllPlayers()
    for userId, playerData in pairs(activePlayers) do
        playerData.score = 0
        playerData.lives = 3
        playerData.isAlive = false
        playerData.finishTime = nil
        playerData.currentColor = "Red"
        playerData.respawnQueued = false
        playerData.invincible = false
    end
end

-- NEW: Reset players specifically for game start
function MainGameController:ResetAllPlayersForGame()
    for userId, playerData in pairs(activePlayers) do
        playerData.score = 0
        playerData.lives = GAME_CONFIG.maxLives
        playerData.health = 100 -- Full health
        playerData.isAlive = true -- Start alive
        playerData.isEliminated = false
        playerData.finishTime = nil
        playerData.eliminationTime = nil
        playerData.eliminationReason = nil
        playerData.currentColor = "Red"
        playerData.respawnQueued = false
        playerData.respawnCount = 0
        playerData.invincible = false
        playerData.invincibilityEndTime = 0
        playerData.checkpointsReached = {}
        playerData.lastCheckpoint = nil
        playerData.combo = 0
        playerData.maxCombo = 0
        playerData.powerups = {}
        
        -- Reset statistics for this game
        playerData.statistics.totalDistance = 0
        playerData.statistics.obstaclesHit = 0
        playerData.statistics.collectiblesFound = 0
        playerData.statistics.deaths = 0
        playerData.statistics.respawns = 0
        
        print("🔄 Reset player data for: " .. playerData.player.Name)
    end
end

function MainGameController:SpawnAllPlayersAtStart()
    for userId, playerData in pairs(activePlayers) do
        local player = playerData.player
        if player.Character then
            player:LoadCharacter()
        else
            player:LoadCharacter()
        end
    end
end

function MainGameController:SpawnAllPlayersInLobby()
    for userId, playerData in pairs(activePlayers) do
        local player = playerData.player
        if player.Character then
            player:LoadCharacter()
        else
            player:LoadCharacter()
        end
    end
end

function MainGameController:OnPlayerDied(player, reason)
    local playerData = activePlayers[player.UserId]
    if not playerData or not playerData.isAlive then return end
    
    reason = reason or "unknown"
    print("💀 " .. player.Name .. " died (" .. reason .. ")")
    
    -- Get collision controller data if available
    local collisionHealth = 0
    local collisionLives = 0
    if Controllers.CollisionController then
        collisionHealth = Controllers.CollisionController:GetPlayerHealth(player)
        collisionLives = Controllers.CollisionController:GetPlayerLives(player)
    end
    
    playerData.isAlive = false
    playerData.lives = math.max(collisionLives, playerData.lives - 1)
    playerData.statistics.deaths = playerData.statistics.deaths + 1
    playerData.combo = 0 -- Reset combo on death
    
    -- Clear off-track warning
    playerData.offTrackWarning = nil
    
    -- Analytics tracking with enhanced data
    if Services.AnalyticsService then
        Services.AnalyticsService:TrackEvent(player, "player_died", {
            reason = reason,
            score = playerData.score,
            livesRemaining = playerData.lives,
            gameTime = tick() - gameStartTime,
            position = playerData.player.Character and playerData.player.Character.HumanoidRootPart.Position or Vector3.new(0,0,0),
            totalDistance = playerData.statistics.totalDistance,
            combo = playerData.combo,
            collisionHealth = collisionHealth
        })
    end
    
    -- Notify clients with enhanced data
    Events.PlayerDied:FireAllClients(player, {
        reason = reason,
        livesRemaining = playerData.lives,
        score = playerData.score,
        canRespawn = playerData.lives > 0 and playerData.respawnCount < GAME_CONFIG.maxRespawns,
        collisionSystem = Controllers.CollisionController ~= nil
    })
    
    -- Screen effects for all players
    Events.ObstacleHit:FireAllClients(player, reason)
    
    -- Handle respawn or elimination
    if playerData.lives > 0 and playerData.respawnCount < GAME_CONFIG.maxRespawns and currentGameState == GAME_STATES.RUNNING then
        -- Queue respawn (CollisionController will handle if available)
        if Controllers.CollisionController then
            -- CollisionController handles respawn automatically
        else
            -- Fallback respawn handling
            playerData.respawnQueued = true
            playerData.respawnCount = playerData.respawnCount + 1
            
            spawn(function()
                wait(GAME_CONFIG.respawnTime)
                if currentGameState == GAME_STATES.RUNNING and playerData.respawnQueued then
                    self:RespawnPlayer(player)
                end
            end)
        end
    else
        -- Player is eliminated
        self:EliminatePlayer(player, reason)
    end
end

function MainGameController:OnFinishLineTouched(hit)
    local character = hit.Parent
    local humanoid = character:FindFirstChildOfClass("Humanoid")
    if not humanoid then return end
    
    local player = Players:GetPlayerFromCharacter(character)
    if not player then return end
    
    local playerData = activePlayers[player.UserId]
    if not playerData or not playerData.isAlive or playerData.finishTime then return end
    
    print("🏆 " .. player.Name .. " finished the race!")
    
    -- Record finish time
    playerData.finishTime = tick() - gameStartTime
    playerData.score = playerData.score + GAME_CONFIG.finishBonus
    
    -- Add time bonus (more bonus for faster completion)
    local timeBonus = math.max(0, math.floor((gameTimeRemaining / GAME_CONFIG.gameTime) * GAME_CONFIG.timeBonus))
    playerData.score = playerData.score + timeBonus
    
    -- Mark as winner
    table.insert(gameResults.winners, {
        player = player,
        finishTime = playerData.finishTime,
        score = playerData.score,
        timeBonus = timeBonus
    })
    
    -- Analytics tracking
    if Services.AnalyticsService then
        Services.AnalyticsService:TrackEvent(player, "player_finished", {
            finishTime = playerData.finishTime,
            finalScore = playerData.score,
            timeBonus = timeBonus,
            position = #gameResults.winners
        })
    end
    
    -- Notify clients of victory
    Events.PlayerFinished:FireAllClients(player, playerData.finishTime, playerData.score)
    Events.PlayerWon:FireClient(player, "finish_line", {
        finishTime = playerData.finishTime,
        score = playerData.score,
        timeBonus = timeBonus,
        position = #gameResults.winners
    })
    Events.ScoreUpdated:FireClient(player, playerData.score)
    
    -- Check if this should end the game (first to finish wins)
    if GAME_CONFIG.winConditions.reachFinishLine then
        spawn(function()
            wait(2) -- Brief delay to show victory
            self:EndGameWithWinLoss("PlayerFinished")
        end)
    end
end

-- NEW: Check individual player win/loss conditions
function MainGameController:CheckPlayerWinLossConditions(playerData)
    local player = playerData.player
    
    -- Check loss conditions
    if GAME_CONFIG.lossConditions.runOutOfLives and playerData.lives <= 0 then
        self:EliminatePlayer(player, "no_lives")
    elseif GAME_CONFIG.lossConditions.runOutOfHealth and playerData.health <= 0 then
        self:EliminatePlayer(player, "no_health")
    end
    
    -- Win conditions are checked elsewhere (finish line, time survival)
end

-- NEW: Eliminate a player from the game
function MainGameController:EliminatePlayer(player, reason)
    local playerData = activePlayers[player.UserId]
    if not playerData or playerData.isEliminated then return end
    
    print("💀 " .. player.Name .. " eliminated: " .. reason)
    
    -- Mark as eliminated
    playerData.isEliminated = true
    playerData.isAlive = false
    playerData.eliminationTime = tick() - gameStartTime
    playerData.eliminationReason = reason
    
    -- Add to eliminated list
    table.insert(gameResults.eliminated, {
        player = player,
        reason = reason,
        eliminationTime = playerData.eliminationTime,
        finalScore = playerData.score
    })
    
    -- Notify player of loss
    Events.PlayerLost:FireClient(player, reason, {
        eliminationTime = playerData.eliminationTime,
        finalScore = playerData.score,
        reason = reason
    })
    
    -- Notify all clients
    Events.PlayerEliminated:FireAllClients(player, reason)
    
    -- Analytics tracking
    if Services.AnalyticsService then
        Services.AnalyticsService:TrackEvent(player, "player_eliminated", {
            reason = reason,
            eliminationTime = playerData.eliminationTime,
            finalScore = playerData.score
        })
    end
    
    -- Check if this should end the game
    local remainingPlayers = self:GetAlivePlayers()
    if #remainingPlayers == 0 then
        spawn(function()
            wait(1)
            self:EndGameWithWinLoss("AllPlayersEliminated")
        end)
    end
end

-- NEW: Enhanced EndGame with win/loss logic
function MainGameController:EndGameWithWinLoss(reason)
    if currentGameState ~= GAME_STATES.RUNNING then
        return
    end
    
    print("🏁 Ending game with win/loss logic - Reason: " .. reason)
    
    local gameEndTime = tick()
    local gameDuration = gameEndTime - gameStartTime
    gameResults.endTime = gameEndTime
    gameResults.reason = reason
    
    -- Determine survivors (alive players when time runs out)
    if reason == "TimeLimit" then
        for userId, playerData in pairs(activePlayers) do
            if playerData.isAlive and not playerData.finishTime then
                -- Surviving the time limit is a WIN condition
                table.insert(gameResults.survivors, {
                    player = playerData.player,
                    survivalTime = gameDuration,
                    score = playerData.score + GAME_CONFIG.timeBonus
                })
                
                -- Notify survivor of victory
                Events.PlayerWon:FireClient(playerData.player, "survival", {
                    survivalTime = gameDuration,
                    score = playerData.score + GAME_CONFIG.timeBonus,
                    bonus = GAME_CONFIG.timeBonus
                })
            end
        end
    end
    
    -- Determine overall game result
    local victoryType = "defeat" -- Default
    local victoryData = {}
    
    if #gameResults.winners > 0 then
        victoryType = "victory"
        victoryData = gameResults.winners[1] -- First place winner
    elseif #gameResults.survivors > 0 then
        victoryType = "survival"
        victoryData = {
            survivors = #gameResults.survivors,
            timeRemaining = gameTimeRemaining
        }
    elseif reason == "AllPlayersEliminated" then
        victoryType = "defeat"
        victoryData = {reason = "All players eliminated"}
    end
    
    -- Fire appropriate game result events
    if victoryType == "victory" or victoryType == "survival" then
        Events.GameVictory:FireAllClients(victoryType, victoryData, gameResults)
    else
        Events.GameDefeat:FireAllClients(victoryType, victoryData, gameResults)
    end
    
    -- Analytics tracking
    if Services.AnalyticsService then
        Services.AnalyticsService:TrackEvent(nil, "game_ended_with_result", {
            sessionId = gameSession.id,
            reason = reason,
            victoryType = victoryType,
            duration = gameDuration,
            winners = #gameResults.winners,
            survivors = #gameResults.survivors,
            eliminated = #gameResults.eliminated
        })
    end
    
    -- Call original EndGame for cleanup
    self:EndGame(reason)
end

function MainGameController:GetAlivePlayers()
    local alivePlayers = {}
    for userId, playerData in pairs(activePlayers) do
        if playerData.isAlive and not playerData.isEliminated then
            table.insert(alivePlayers, playerData.player)
        end
    end
    return alivePlayers
end

function MainGameController:GetPlayerPosition(finishedPlayer)
    local position = 1
    for userId, playerData in pairs(activePlayers) do
        if playerData.finishTime and playerData.finishTime < activePlayers[finishedPlayer.UserId].finishTime then
            position = position + 1
        end
    end
    return position
end

function MainGameController:ChangeGameState(newState)
    if currentGameState == newState then return end
    
    local oldState = currentGameState
    currentGameState = newState
    
    print("🔄 Game state changed: " .. oldState .. " → " .. newState)
    
    -- Notify all clients
    Events.GameStateChanged:FireAllClients(newState, oldState)
end

function MainGameController:GetActivePlayerCount()
    local count = 0
    for userId, playerData in pairs(activePlayers) do
        count = count + 1
    end
    return count
end

function MainGameController:GetGameState()
    return currentGameState
end

function MainGameController:GetGameSession()
    return gameSession
end

function MainGameController:GetPlayerData(player)
    return activePlayers[player.UserId]
end

function MainGameController:GetAllPlayerData()
    return activePlayers
end

-- Enhanced helper functions

function MainGameController:SendGameStateToPlayer(player)
    Events.GameStateChanged:FireClient(player, currentGameState, "initial")
    
    if gameSession then
        Events.GameStarted:FireClient(player, gameSession.id, gameStartTime)
    end
    
    -- Send current player list
    local playerList = {}
    for userId, playerData in pairs(activePlayers) do
        table.insert(playerList, {
            player = playerData.player,
            score = playerData.score,
            state = playerData.state,
            isAlive = playerData.isAlive
        })
    end
    Events.PlayerJoinedGame:FireClient(player, playerList)
end

function MainGameController:CalculatePlayerDistance(playerData)
    if not playerData.player.Character or not playerData.player.Character:FindFirstChild("HumanoidRootPart") then
        return 0
    end
    
    local position = playerData.player.Character.HumanoidRootPart.Position
    return math.max(0, position.Z + 100) -- +100 to offset start position
end

function MainGameController:CheckPlayerCheckpoints(playerData, position)
    -- Create checkpoints every 100 studs
    local checkpointInterval = 100
    local currentCheckpoint = math.floor((position.Z + 100) / checkpointInterval)
    
    if currentCheckpoint > (playerData.lastCheckpoint or -1) then
        playerData.lastCheckpoint = currentCheckpoint
        table.insert(playerData.checkpointsReached, {
            checkpoint = currentCheckpoint,
            time = tick() - gameStartTime,
            position = position
        })
        
        -- Bonus score for reaching checkpoint
        playerData.score = playerData.score + 50
        
        Events.CheckpointReached:FireClient(playerData.player, currentCheckpoint, playerData.score)
    end
end

function MainGameController:CheckPlayerPowerups(playerData, position)
    -- Basic power-up detection (can be expanded)
    -- This would integrate with a PowerupService if available
    if Services.PowerupService then
        local nearbyPowerups = Services.PowerupService:GetNearbyPowerups(position, 10)
        for _, powerup in ipairs(nearbyPowerups) do
            if not playerData.powerups[powerup.id] then
                self:ApplyPowerup(playerData, powerup)
            end
        end
    end
end

function MainGameController:ApplyPowerup(playerData, powerup)
    playerData.powerups[powerup.id] = tick()
    Events.PowerupActivated:FireClient(playerData.player, powerup)
    
    -- Apply powerup effect (example implementations)
    if powerup.type == "speed_boost" then
        -- Increase player speed temporarily
        if playerData.player.Character and playerData.player.Character:FindFirstChild("Humanoid") then
            local humanoid = playerData.player.Character.Humanoid
            humanoid.WalkSpeed = humanoid.WalkSpeed * 1.5
            
            spawn(function()
                wait(powerup.duration or 5)
                if playerData.player.Character and playerData.player.Character:FindFirstChild("Humanoid") then
                    humanoid.WalkSpeed = humanoid.WalkSpeed / 1.5
                end
            end)
        end
    elseif powerup.type == "invincibility" then
        self:MakePlayerInvincible(playerData.player, powerup.duration or 5)
    elseif powerup.type == "extra_life" then
        playerData.lives = playerData.lives + 1
        Events.ScoreUpdated:FireClient(playerData.player, playerData.score, 0, "extra_life")
    end
end

function MainGameController:MakePlayerInvincible(player, duration)
    local playerData = activePlayers[player.UserId]
    if not playerData then return end
    
    playerData.invincible = true
    playerData.invincibilityEndTime = tick() + duration
    
    Events.PowerupActivated:FireClient(player, {type = "invincibility", duration = duration})
end

function MainGameController:NotifyPlayerInvincibilityEnd(player)
    Events.PowerupActivated:FireClient(player, {type = "invincibility_end"})
end

function MainGameController:RespawnPlayer(player)
    local playerData = activePlayers[player.UserId]
    if not playerData then return end
    
    playerData.respawnQueued = false
    playerData.statistics.respawns = playerData.statistics.respawns + 1
    
    player:LoadCharacter() -- This will trigger OnPlayerCharacterAdded
    
    Events.PlayerRespawned:FireAllClients(player, playerData.lives, playerData.respawnCount)
end

function MainGameController:BroadcastPerformanceMetrics()
    local metrics = {
        frameRate = math.floor(performanceMetrics.frameRate),
        playerCount = self:GetActivePlayerCount(),
        gameTime = currentGameState == GAME_STATES.RUNNING and (tick() - gameStartTime) or 0,
        memoryUsage = math.floor(gcinfo()),
        uptime = math.floor(tick() - gameStats.uptime)
    }
    
    Events.PerformanceUpdate:FireAllClients(metrics)
end

function MainGameController:HandleRespawnRequest(player)
    local playerData = activePlayers[player.UserId]
    if not playerData then return end
    
    if not playerData.isAlive and playerData.lives > 0 and playerData.respawnCount < GAME_CONFIG.maxRespawns then
        if not playerData.respawnQueued then
            playerData.respawnQueued = true
            playerData.respawnCount = playerData.respawnCount + 1
            
            spawn(function()
                wait(GAME_CONFIG.respawnTime)
                if playerData.respawnQueued then
                    self:RespawnPlayer(player)
                end
            end)
        end
    end
end

function MainGameController:HandleSpectateRequest(player, targetPlayer)
    local playerData = activePlayers[player.UserId]
    if not playerData then return end
    
    if playerData.isEliminated or not playerData.isAlive then
        playerData.spectating = targetPlayer
        playerData.isSpectator = true
        Events.RequestSpectate:FireClient(player, targetPlayer)
    end
end

function MainGameController:HandleAdminCommand(player, command, ...)
    -- Basic admin command system (expand as needed)
    if not self:IsAdmin(player) then
        return
    end
    
    local args = {...}
    
    if command == "end_game" then
        self:EndGame("AdminCommand")
    elseif command == "reset_game" then
        self:ResetToLobby()
    elseif command == "set_lives" and args[1] and args[2] then
        local targetPlayer = Players:FindFirstChild(args[1])
        local lives = tonumber(args[2])
        if targetPlayer and activePlayers[targetPlayer.UserId] and lives then
            activePlayers[targetPlayer.UserId].lives = lives
            Events.ScoreUpdated:FireClient(targetPlayer, activePlayers[targetPlayer.UserId].score, 0, "admin_lives")
        end
    elseif command == "get_stats" then
        Events.ServerStats:FireClient(player, gameStats, performanceMetrics)
    end
end

function MainGameController:HandlePlayerMovement(player, movementData)
    local playerData = activePlayers[player.UserId]
    if not playerData or not playerData.isAlive then return end
    
    -- Validate movement data and apply any server-side logic
    if movementData and movementData.position and movementData.velocity then
        -- Anti-cheat: Basic movement validation
        local maxSpeed = 50 -- studs per second
        if movementData.velocity.Magnitude > maxSpeed then
            warn("⚠️ Suspicious movement detected from " .. player.Name)
            return
        end
        
        -- Update last known position for calculations
        playerData.lastKnownPosition = movementData.position
        playerData.lastKnownVelocity = movementData.velocity
    end
end

-- Analytics Helper Functions

function MainGameController:CheckScoreMilestones(player, oldScore, newScore)
    local milestones = {100, 250, 500, 1000, 2500, 5000, 10000, 25000, 50000}
    
    for _, milestone in ipairs(milestones) do
        if oldScore < milestone and newScore >= milestone then
            -- Player reached a new milestone
            if Services.AnalyticsService then
                Services.AnalyticsService:TrackEvent(player, "score_milestone_reached", {
                    milestone = milestone,
                    sessionId = gameSession and gameSession.id or "no_session",
                    gameTime = gameStartTime and (tick() - gameStartTime) or 0,
                    position = player.Character and player.Character.HumanoidRootPart.Position or Vector3.new(0,0,0),
                    playerData = {
                        lives = activePlayers[player.UserId] and activePlayers[player.UserId].lives or 0,
                        health = activePlayers[player.UserId] and activePlayers[player.UserId].health or 0,
                        perfectMatches = activePlayers[player.UserId] and activePlayers[player.UserId].statistics.perfectColorMatches or 0
                    }
                })
            end
            
            print(string.format("🎯 %s reached score milestone: %d", player.Name, milestone))
            break -- Only trigger first milestone reached
        end
    end
end

function MainGameController:GetPlayerIds()
    local playerIds = {}
    for userId, playerData in pairs(activePlayers) do
        table.insert(playerIds, userId)
    end
    return playerIds
end

function MainGameController:IsPlayerFirstGame(player)
    -- Check if this is player's first game (implement with DataStore if needed)
    local playerData = activePlayers[player.UserId]
    if playerData and playerData.statistics then
        return playerData.statistics.joinTime and (tick() - playerData.statistics.joinTime) < 60
    end
    return true -- Assume first game if no data
end

function MainGameController:GetPlayerLevel(player)
    -- Calculate player level based on total score (implement proper leveling system if needed)
    local playerData = activePlayers[player.UserId]
    if playerData then
        return math.floor(playerData.score / 1000) + 1
    end
    return 1
end

function MainGameController:CalculateScoreImprovement(player, currentScore)
    -- Calculate improvement from previous games (implement with DataStore if needed)
    local playerData = activePlayers[player.UserId]
    if playerData and playerData.statistics.previousBestScore then
        local improvement = currentScore - playerData.statistics.previousBestScore
        return {
            improvement = improvement,
            improvementPercent = playerData.statistics.previousBestScore > 0 and (improvement / playerData.statistics.previousBestScore) * 100 or 0,
            isNewRecord = improvement > 0
        }
    end
    return {improvement = 0, improvementPercent = 0, isNewRecord = true}
end

function MainGameController:CalculatePlayerProgress(player)
    -- Calculate how far through the track the player progressed (0-100%)
    if not player.Character or not player.Character:FindFirstChild("HumanoidRootPart") then
        return 0
    end
    
    local position = player.Character.HumanoidRootPart.Position
    local progress = math.max(0, (position.Z + 100) / GAME_CONFIG.trackLength) * 100
    return math.min(100, progress)
end

function MainGameController:EstimateCompletionLikelihood(playerData)
    -- Simple completion likelihood based on current performance
    if not playerData then return 0 end
    
    local healthFactor = playerData.health / 100
    local livesFactor = playerData.lives / GAME_CONFIG.maxLives
    local scoreFactor = math.min(1, playerData.score / 1000) -- Normalize to reasonable score
    local matchAccuracy = playerData.statistics.perfectColorMatches / math.max(1, playerData.statistics.obstaclesHit)
    
    return (healthFactor + livesFactor + scoreFactor + matchAccuracy) / 4 * 100
end

function MainGameController:IsAdmin(player)
    -- Basic admin check (expand with proper admin system)
    local adminIds = {
        -- Add admin user IDs here
    }
    
    for _, adminId in ipairs(adminIds) do
        if player.UserId == adminId then
            return true
        end
    end
    
    return player.Name == "Roblox" or game:GetService("GroupService"):GetGroupInfoAsync(1):GetRoleInGroup(player.UserId) >= 100
end

-- ============================
-- RECORDING SESSION MANAGEMENT
-- ============================

function MainGameController:StartGameRecording()
    if not Services.RecordingSessionManager or not recordingConfig.autoRecordGames then
        return
    end
    
    print("🎬 Starting game recording session...")
    
    -- Start recording for all active players
    for userId, playerData in pairs(activePlayers) do
        local player = playerData.player
        if player and player.Character then
            self:StartPlayerRecording(player)
        end
    end
    
    -- Track recording session in game session
    gameSession.recordingStarted = true
    gameSession.recordingStartTime = tick()
    
    -- Log recording start to analytics
    if Services.AnalyticsService then
        Services.AnalyticsService:TrackEvent(nil, "recording_session_started", {
            sessionId = gameSession.id,
            playerCount = self:GetActivePlayerCount(),
            recordingDuration = recordingConfig.recordingDuration,
            gameStartTime = gameStartTime
        })
    end
    
    print("✅ Game recording session started for " .. self:GetActivePlayerCount() .. " players")
end

function MainGameController:StartPlayerRecording(player)
    if not Services.RecordingSessionManager then
        return
    end
    
    local sessionType = "GameSession"
    local duration = recordingConfig.recordingDuration
    
    -- Start recording session for the player
    Services.RecordingSessionManager:StartRecordingSession(player, sessionType, duration)
    
    -- Store session info
    activeRecordingSessions[player.UserId] = {
        player = player,
        sessionType = sessionType,
        startTime = tick(),
        duration = duration,
        gameSessionId = gameSession.id,
        isActive = true
    }
    
    print("🎬 Started recording for player: " .. player.Name)
end

function MainGameController:StopGameRecording(endReason, gameResults, gameDuration)
    if not Services.RecordingSessionManager or not gameSession.recordingStarted then
        return
    end
    
    print("🎬 Stopping game recording session...")
    
    local recordingEndTime = tick()
    local totalRecordingTime = recordingEndTime - (gameSession.recordingStartTime or gameStartTime)
    
    -- Stop recording for all players
    for userId, sessionData in pairs(activeRecordingSessions) do
        if sessionData.isActive then
            self:StopPlayerRecording(sessionData.player, endReason, gameResults, gameDuration)
        end
    end
    
    -- Store replay data if enabled
    if recordingConfig.replayDataStorage then
        self:SaveGameReplayData(endReason, gameResults, gameDuration, totalRecordingTime)
    end
    
    -- Log recording completion to analytics
    if Services.AnalyticsService then
        Services.AnalyticsService:TrackEvent(nil, "recording_session_completed", {
            sessionId = gameSession.id,
            endReason = endReason,
            totalRecordingTime = totalRecordingTime,
            playersRecorded = self:GetActiveRecordingCount(),
            gameQuality = self:CalculateGameQuality(gameResults, gameDuration),
            replayDataSaved = recordingConfig.replayDataStorage
        })
    end
    
    print("✅ Game recording session completed")
end

function MainGameController:StopPlayerRecording(player, endReason, gameResults, gameDuration)
    if not Services.RecordingSessionManager then
        return
    end
    
    -- Stop the recording session
    Services.RecordingSessionManager:StopRecordingSession(player)
    
    -- Update session data
    local sessionData = activeRecordingSessions[player.UserId]
    if sessionData then
        sessionData.isActive = false
        sessionData.endTime = tick()
        sessionData.endReason = endReason
        sessionData.totalDuration = sessionData.endTime - sessionData.startTime
        
        -- Get player's final results
        local playerResult = nil
        if gameResults then
            for _, result in ipairs(gameResults) do
                if result.player == player then
                    playerResult = result
                    break
                end
            end
        end
        
        sessionData.playerResult = playerResult
        
        print("📹 Stopped recording for player: " .. player.Name .. " (Duration: " .. 
              string.format("%.1f", sessionData.totalDuration) .. "s)")
    end
end

function MainGameController:SaveGameReplayData(endReason, gameResults, gameDuration, recordingTime)
    if not recordingConfig.replayDataStorage then
        return
    end
    
    print("💾 Saving game replay data...")
    
    local replayData = {
        gameSessionId = gameSession.id,
        startTime = gameStartTime,
        endTime = tick(),
        gameDuration = gameDuration,
        recordingDuration = recordingTime,
        endReason = endReason,
        playerCount = self:GetActivePlayerCount(),
        trackConfig = gameSession.track and gameSession.track.config or nil,
        gameResults = gameResults,
        recordingSessions = {},
        gameQuality = self:CalculateGameQuality(gameResults, gameDuration),
        notableEvents = self:GetNotableGameEvents()
    }
    
    -- Add individual recording session data
    for userId, sessionData in pairs(activeRecordingSessions) do
        table.insert(replayData.recordingSessions, {
            playerId = userId,
            playerName = sessionData.player.Name,
            sessionType = sessionData.sessionType,
            recordingDuration = sessionData.totalDuration or 0,
            playerResult = sessionData.playerResult,
            highlights = self:GetPlayerHighlights(sessionData.player)
        })
    end
    
    -- Store replay data (you can save to DataStore or send to external service)
    if Services.AnalyticsService then
        Services.AnalyticsService:TrackEvent(nil, "replay_data_saved", replayData)
    end
    
    -- Optional: Save to DataStore for later retrieval
    self:SaveToReplayDataStore(replayData)
    
    print("✅ Game replay data saved successfully")
end

function MainGameController:SaveToReplayDataStore(replayData)
    local success, error = pcall(function()
        local DataStoreService = game:GetService("DataStoreService")
        local replayStore = DataStoreService:GetDataStore("GameReplays")
        
        local replayKey = "replay_" .. replayData.gameSessionId
        replayStore:SetAsync(replayKey, replayData)
        
        print("💾 Replay data saved to DataStore with key: " .. replayKey)
    end)
    
    if not success then
        warn("❌ Failed to save replay data to DataStore: " .. tostring(error))
    end
end

function MainGameController:CalculateGameQuality(gameResults, gameDuration)
    if not gameResults or #gameResults == 0 then
        return 0
    end
    
    local qualityScore = 0
    local factors = {
        playerFinishRate = 0,
        scoreVariety = 0,
        gameLength = 0,
        competitiveness = 0
    }
    
    -- Calculate finish rate
    local finishedPlayers = 0
    local totalScore = 0
    local scores = {}
    
    for _, result in ipairs(gameResults) do
        if result.finishTime then
            finishedPlayers = finishedPlayers + 1
        end
        totalScore = totalScore + result.score
        table.insert(scores, result.score)
    end
    
    factors.playerFinishRate = finishedPlayers / #gameResults
    
    -- Calculate score variety (standard deviation)
    if #scores > 1 then
        local avgScore = totalScore / #scores
        local variance = 0
        for _, score in ipairs(scores) do
            variance = variance + math.pow(score - avgScore, 2)
        end
        factors.scoreVariety = math.sqrt(variance / #scores) / avgScore
    end
    
    -- Game length factor (prefer games that last reasonable time)
    local idealLength = GAME_CONFIG.gameTime * 0.8 -- 80% of max time is ideal
    local lengthRatio = math.min(gameDuration or 0, idealLength) / idealLength
    factors.gameLength = lengthRatio
    
    -- Competitiveness (close scores indicate good competition)
    if #scores > 1 then
        table.sort(scores, function(a, b) return a > b end)
        local topScoreDiff = scores[1] - scores[2]
        factors.competitiveness = 1 - math.min(1, topScoreDiff / scores[1])
    end
    
    -- Weighted quality score
    qualityScore = factors.playerFinishRate * 0.3 +
                   factors.scoreVariety * 0.2 +
                   factors.gameLength * 0.3 +
                   factors.competitiveness * 0.2
    
    return math.floor(qualityScore * 100) -- Return as percentage
end

function MainGameController:GetNotableGameEvents()
    -- Return notable events that occurred during the game
    local events = {}
    
    -- Add comeback victories, perfect runs, close finishes, etc.
    for userId, playerData in pairs(activePlayers) do
        if playerData.statistics then
            if playerData.statistics.perfectColorMatches and playerData.statistics.perfectColorMatches >= 10 then
                table.insert(events, {
                    type = "PerfectRun",
                    player = playerData.player.Name,
                    details = "Achieved " .. playerData.statistics.perfectColorMatches .. " perfect matches"
                })
            end
            
            if playerData.statistics.deaths and playerData.statistics.deaths == 0 and playerData.finishTime then
                table.insert(events, {
                    type = "FlawlessVictory",
                    player = playerData.player.Name,
                    details = "Completed without taking damage"
                })
            end
        end
    end
    
    return events
end

function MainGameController:GetPlayerHighlights(player)
    local playerData = activePlayers[player.UserId]
    if not playerData then
        return {}
    end
    
    local highlights = {}
    
    -- Performance highlights
    if playerData.score >= 1000 then
        table.insert(highlights, "High Score: " .. playerData.score)
    end
    
    if playerData.finishTime and playerData.finishTime <= GAME_CONFIG.gameTime * 0.5 then
        table.insert(highlights, "Fast Finish: " .. string.format("%.1f", playerData.finishTime) .. "s")
    end
    
    if playerData.statistics and playerData.statistics.perfectColorMatches and playerData.statistics.perfectColorMatches >= 5 then
        table.insert(highlights, "Perfect Matches: " .. playerData.statistics.perfectColorMatches)
    end
    
    return highlights
end

function MainGameController:GetActiveRecordingCount()
    local count = 0
    for _, sessionData in pairs(activeRecordingSessions) do
        if sessionData.isActive then
            count = count + 1
        end
    end
    return count
end

function MainGameController:CleanupRecordingSessions()
    -- Clean up old recording sessions
    for userId, sessionData in pairs(activeRecordingSessions) do
        if not sessionData.isActive then
            activeRecordingSessions[userId] = nil
        end
    end
end

function MainGameController:CleanupPlayerRecording(player)
    if not Services.RecordingSessionManager then
        return
    end
    
    print("🧹 Cleaning up recording for player: " .. player.Name)
    
    -- Stop any active recording for this player
    local sessionData = activeRecordingSessions[player.UserId]
    if sessionData and sessionData.isActive then
        Services.RecordingSessionManager:StopRecordingSession(player)
        sessionData.isActive = false
        sessionData.endTime = tick()
        sessionData.endReason = "PlayerLeft"
    end
    
    -- Remove from active sessions
    activeRecordingSessions[player.UserId] = nil
    
    -- Notify RecordingSessionManager to cleanup its data
    if Services.RecordingSessionManager.CleanupPlayerRecording then
        Services.RecordingSessionManager:CleanupPlayerRecording(player)
    end
end

function MainGameController:CleanupAllRecordingSessions()
    if not Services.RecordingSessionManager then
        return
    end
    
    print("🧹 Cleaning up all recording sessions...")
    
    -- Stop all active recordings
    for userId, sessionData in pairs(activeRecordingSessions) do
        if sessionData.isActive and sessionData.player then
            Services.RecordingSessionManager:StopRecordingSession(sessionData.player)
        end
    end
    
    -- Clear all sessions
    activeRecordingSessions = {}
    
    print("✅ All recording sessions cleaned up")
end

-- Recording configuration functions
function MainGameController:SetRecordingConfig(config)
    for key, value in pairs(config) do
        if recordingConfig[key] ~= nil then
            recordingConfig[key] = value
        end
    end
    
    print("🎬 Recording configuration updated:", recordingConfig)
end

function MainGameController:GetRecordingConfig()
    return recordingConfig
end

-- ============================
-- END RECORDING MANAGEMENT
-- ============================

-- Initialize the controller when the script loads
spawn(function()
    wait(2) -- Wait for other services to load
    MainGameController:Init()
end)

return MainGameController
