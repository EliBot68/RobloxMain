-- GameStateEventManager.server.luau
-- Manages game state changes and binds them to recording, analytics, and system resets
-- Handles comprehensive game state event routing across all services

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local GameStateEventManager = {}

-- Game state tracking
local CurrentGameStates = {} -- Per player game states
local GlobalGameState = "LOBBY"
local GameSessions = {}

-- Event connections registry
local StateEventConnections = {}

-- Configuration
local STATE_CONFIG = {
    enableDetailedLogging = true,
    enableRecordingIntegration = true,
    enableAnalyticsIntegration = true,
    enableSystemResets = true,
    recordingAutoStart = true,
    analyticsRealTime = true
}

-- Game states
local GAME_STATES = {
    "LOBBY",
    "PREPARING",
    "STARTING", 
    "PLAYING",
    "PAUSED",
    "FINISHING",
    "ENDED",
    "RESETTING"
}

function GameStateEventManager:Initialize()
    print("🎮 Initializing Game State Event Manager...")
    
    -- Wait for core services
    if not self:WaitForCoreServices() then
        warn("❌ Core services not available for game state management")
        return false
    end
    
    -- Setup game state event connections
    self:SetupGameStateConnections()
    self:SetupRecordingStateBindings()
    self:SetupAnalyticsStateBindings()
    self:SetupSystemResetBindings()
    self:SetupPlayerStateTracking()
    
    -- Setup RemoteEvent handlers
    self:SetupRemoteEventHandlers()
    
    print("✅ Game State Event Manager initialized successfully")
    return true
end

function GameStateEventManager:WaitForCoreServices(timeout)
    timeout = timeout or 10
    local startTime = tick()
    
    while tick() - startTime < timeout do
        if _G.GetMainGameController and _G.GetAnalyticsService and _G.GetRecordingSessionManager then
            return true
        end
        wait(0.1)
    end
    
    return false
end

-- ========================================
-- GAME STATE CHANGE HANDLING
-- ========================================

function GameStateEventManager:ChangeGameState(player, newState, gameData)
    local previousState = CurrentGameStates[player.UserId] or "LOBBY"
    
    if STATE_CONFIG.enableDetailedLogging then
        print("🎮 Game state change: " .. player.Name .. " " .. previousState .. " → " .. newState)
    end
    
    -- Validate state transition
    if not self:ValidateStateTransition(previousState, newState) then
        warn("❌ Invalid state transition: " .. previousState .. " → " .. newState)
        return false
    end
    
    -- Update state tracking
    CurrentGameStates[player.UserId] = newState
    
    -- Create game session data
    local sessionData = {
        player = player,
        previousState = previousState,
        newState = newState,
        timestamp = tick(),
        gameData = gameData or {},
        sessionId = self:GetOrCreateSessionId(player)
    }
    
    -- Execute state change actions
    self:ExecuteStateChangeActions(sessionData)
    
    -- Notify all services
    self:NotifyServicesOfStateChange(sessionData)
    
    return true
end

function GameStateEventManager:ValidateStateTransition(fromState, toState)
    -- Define valid transitions
    local validTransitions = {
        LOBBY = {"PREPARING", "RESETTING"},
        PREPARING = {"STARTING", "LOBBY", "RESETTING"},
        STARTING = {"PLAYING", "LOBBY", "RESETTING"},
        PLAYING = {"PAUSED", "FINISHING", "RESETTING"},
        PAUSED = {"PLAYING", "FINISHING", "RESETTING"},
        FINISHING = {"ENDED", "RESETTING"},
        ENDED = {"LOBBY", "RESETTING"},
        RESETTING = {"LOBBY"}
    }
    
    local allowedStates = validTransitions[fromState]
    if not allowedStates then return false end
    
    for _, allowedState in ipairs(allowedStates) do
        if allowedState == toState then
            return true
        end
    end
    
    return false
end

function GameStateEventManager:GetOrCreateSessionId(player)
    if not GameSessions[player.UserId] then
        GameSessions[player.UserId] = {
            sessionId = player.UserId .. "_" .. tick(),
            startTime = tick(),
            states = {}
        }
    end
    
    return GameSessions[player.UserId].sessionId
end

function GameStateEventManager:ExecuteStateChangeActions(sessionData)
    local player = sessionData.player
    local newState = sessionData.newState
    local previousState = sessionData.previousState
    
    -- Recording state bindings
    if STATE_CONFIG.enableRecordingIntegration then
        self:HandleRecordingStateChange(sessionData)
    end
    
    -- Analytics state bindings
    if STATE_CONFIG.enableAnalyticsIntegration then
        self:HandleAnalyticsStateChange(sessionData)
    end
    
    -- System reset bindings
    if STATE_CONFIG.enableSystemResets then
        self:HandleSystemResetStateChange(sessionData)
    end
    
    -- Custom state actions
    self:ExecuteCustomStateActions(sessionData)
end

-- ========================================
-- RECORDING STATE BINDINGS
-- ========================================

function GameStateEventManager:HandleRecordingStateChange(sessionData)
    local recordingManager = _G.GetRecordingSessionManager()
    if not recordingManager then return end
    
    local player = sessionData.player
    local newState = sessionData.newState
    local previousState = sessionData.previousState
    
    if STATE_CONFIG.enableDetailedLogging then
        print("🎬 Recording state change: " .. player.Name .. " → " .. newState)
    end
    
    -- Start recording on game start
    if newState == "STARTING" or newState == "PLAYING" then
        if STATE_CONFIG.recordingAutoStart then
            if recordingManager.StartRecording then
                local success, error = pcall(function()
                    recordingManager:StartRecording(player, sessionData.gameData)
                end)
                
                if success then
                    print("▶️ Recording started for: " .. player.Name)
                else
                    warn("❌ Failed to start recording: " .. tostring(error))
                end
            end
        end
    end
    
    -- Stop recording on game end
    if newState == "ENDED" or newState == "RESETTING" then
        if recordingManager.StopRecording then
            local success, replayData = pcall(function()
                return recordingManager:StopRecording(player, sessionData.gameData)
            end)
            
            if success and replayData then
                print("⏹️ Recording stopped for: " .. player.Name)
                
                -- Save replay data
                if recordingManager.SaveReplayData then
                    recordingManager:SaveReplayData(player, replayData, sessionData.gameData)
                end
            else
                warn("❌ Failed to stop recording: " .. tostring(replayData))
            end
        end
    end
    
    -- Pause/Resume recording
    if newState == "PAUSED" and recordingManager.PauseRecording then
        recordingManager:PauseRecording(player)
    elseif previousState == "PAUSED" and newState == "PLAYING" and recordingManager.ResumeRecording then
        recordingManager:ResumeRecording(player)
    end
end

function GameStateEventManager:SetupRecordingStateBindings()
    print("🎬 Setting up Recording State Bindings...")
    
    local recordingManager = _G.GetRecordingSessionManager()
    if not recordingManager then
        warn("⚠️ RecordingSessionManager not available")
        return
    end
    
    -- Connect recording events to state changes
    if recordingManager.OnRecordingStarted then
        StateEventConnections.RecordingStarted = recordingManager.OnRecordingStarted:Connect(function(player, recordingData)
            -- Update analytics
            local analyticsService = _G.GetAnalyticsService()
            if analyticsService then
                analyticsService:TrackEvent(player, "recording_started", {
                    sessionId = recordingData.sessionId,
                    timestamp = tick()
                })
            end
        end)
    end
    
    if recordingManager.OnRecordingStopped then
        StateEventConnections.RecordingStopped = recordingManager.OnRecordingStopped:Connect(function(player, replayData)
            -- Update analytics
            local analyticsService = _G.GetAnalyticsService()
            if analyticsService then
                analyticsService:TrackEvent(player, "recording_stopped", {
                    duration = replayData.duration,
                    dataSize = replayData.dataSize or 0,
                    timestamp = tick()
                })
            end
        end)
    end
    
    print("✅ Recording state bindings established")
end

-- ========================================
-- ANALYTICS STATE BINDINGS
-- ========================================

function GameStateEventManager:HandleAnalyticsStateChange(sessionData)
    local analyticsService = _G.GetAnalyticsService()
    if not analyticsService then return end
    
    local player = sessionData.player
    local newState = sessionData.newState
    local previousState = sessionData.previousState
    
    if STATE_CONFIG.enableDetailedLogging then
        print("📊 Analytics state change: " .. player.Name .. " → " .. newState)
    end
    
    -- Track state transition
    analyticsService:TrackEvent(player, "game_state_change", {
        previousState = previousState,
        newState = newState,
        timestamp = sessionData.timestamp,
        sessionId = sessionData.sessionId,
        duration = self:GetStateDuration(player, previousState),
        gameData = sessionData.gameData
    })
    
    -- Track specific state events
    if newState == "STARTING" then
        analyticsService:TrackEvent(player, "game_started", {
            sessionId = sessionData.sessionId,
            gameMode = sessionData.gameData.gameMode or "default",
            difficulty = sessionData.gameData.difficulty or 1
        })
    elseif newState == "ENDED" then
        local sessionInfo = GameSessions[player.UserId]
        analyticsService:TrackEvent(player, "game_ended", {
            sessionId = sessionData.sessionId,
            totalDuration = sessionInfo and (tick() - sessionInfo.startTime) or 0,
            finalScore = sessionData.gameData.finalScore or 0,
            completionRate = sessionData.gameData.completionRate or 0
        })
    elseif newState == "PAUSED" then
        analyticsService:TrackEvent(player, "game_paused", {
            sessionId = sessionData.sessionId,
            pauseReason = sessionData.gameData.pauseReason or "manual"
        })
    end
    
    -- Real-time analytics updates
    if STATE_CONFIG.analyticsRealTime and newState == "PLAYING" then
        self:StartRealTimeAnalytics(player, sessionData)
    elseif previousState == "PLAYING" and newState ~= "PAUSED" then
        self:StopRealTimeAnalytics(player)
    end
end

function GameStateEventManager:StartRealTimeAnalytics(player, sessionData)
    local analyticsService = _G.GetAnalyticsService()
    if not analyticsService then return end
    
    -- Start periodic analytics updates
    local connectionName = "RealTimeAnalytics_" .. player.UserId
    if StateEventConnections[connectionName] then
        StateEventConnections[connectionName]:Disconnect()
    end
    
    StateEventConnections[connectionName] = spawn(function()
        while CurrentGameStates[player.UserId] == "PLAYING" do
            wait(5) -- Update every 5 seconds
            
            if CurrentGameStates[player.UserId] == "PLAYING" then
                local mainController = _G.GetMainGameController()
                local gameData = {}
                
                if mainController and mainController.GetPlayerGameData then
                    gameData = mainController:GetPlayerGameData(player) or {}
                end
                
                analyticsService:TrackEvent(player, "gameplay_progress", {
                    sessionId = sessionData.sessionId,
                    timestamp = tick(),
                    currentScore = gameData.currentScore or 0,
                    currentDistance = gameData.currentDistance or 0,
                    currentSpeed = gameData.currentSpeed or 0
                })
            end
        end
    end)
end

function GameStateEventManager:StopRealTimeAnalytics(player)
    local connectionName = "RealTimeAnalytics_" .. player.UserId
    if StateEventConnections[connectionName] then
        StateEventConnections[connectionName]:Disconnect()
        StateEventConnections[connectionName] = nil
    end
end

function GameStateEventManager:SetupAnalyticsStateBindings()
    print("📊 Setting up Analytics State Bindings...")
    
    local analyticsService = _G.GetAnalyticsService()
    if not analyticsService then
        warn("⚠️ AnalyticsService not available")
        return
    end
    
    -- No specific event connections needed - handled through state changes
    print("✅ Analytics state bindings established")
end

-- ========================================
-- SYSTEM RESET BINDINGS
-- ========================================

function GameStateEventManager:HandleSystemResetStateChange(sessionData)
    local player = sessionData.player
    local newState = sessionData.newState
    
    if STATE_CONFIG.enableDetailedLogging then
        print("🔄 System reset state change: " .. player.Name .. " → " .. newState)
    end
    
    -- Reset systems when transitioning to RESETTING state
    if newState == "RESETTING" then
        self:ResetAllSystems(player, sessionData)
    end
    
    -- Initialize systems when transitioning from LOBBY to PREPARING
    if newState == "PREPARING" then
        self:InitializeSystemsForGame(player, sessionData)
    end
end

function GameStateEventManager:ResetAllSystems(player, sessionData)
    print("🔄 Resetting all systems for: " .. player.Name)
    
    -- Reset MainGameController
    local mainController = _G.GetMainGameController()
    if mainController then
        if mainController.ResetPlayerGame then
            mainController:ResetPlayerGame(player)
        end
        if mainController.ClearPlayerData then
            mainController:ClearPlayerData(player)
        end
    end
    
    -- Reset CollisionController
    local collisionController = _G.GetCollisionController()
    if collisionController then
        if collisionController.ResetPlayerCollisions then
            collisionController:ResetPlayerCollisions(player)
        end
        if collisionController.DisablePlayerCollision then
            collisionController:DisablePlayerCollision(player)
        end
    end
    
    -- Reset TrackGeneratorService
    local trackGenerator = _G.GetTrackGeneratorService()
    if trackGenerator then
        if trackGenerator.ClearPlayerTrack then
            trackGenerator:ClearPlayerTrack(player)
        end
    end
    
    -- Reset DifficultyService
    local difficultyService = _G.GetDifficultyService()
    if difficultyService then
        if difficultyService.ResetPlayerDifficulty then
            difficultyService:ResetPlayerDifficulty(player)
        end
    end
    
    -- Clear player session data
    if GameSessions[player.UserId] then
        GameSessions[player.UserId] = nil
    end
    
    -- Stop any ongoing real-time analytics
    self:StopRealTimeAnalytics(player)
    
    -- Track reset analytics
    local analyticsService = _G.GetAnalyticsService()
    if analyticsService then
        analyticsService:TrackEvent(player, "systems_reset", {
            timestamp = tick(),
            resetReason = sessionData.gameData.resetReason or "manual"
        })
    end
end

function GameStateEventManager:InitializeSystemsForGame(player, sessionData)
    print("🎯 Initializing systems for game: " .. player.Name)
    
    -- Initialize MainGameController for new game
    local mainController = _G.GetMainGameController()
    if mainController then
        if mainController.PreparePlayerForGame then
            mainController:PreparePlayerForGame(player, sessionData.gameData)
        end
    end
    
    -- Enable collision detection
    local collisionController = _G.GetCollisionController()
    if collisionController then
        if collisionController.EnablePlayerCollision then
            collisionController:EnablePlayerCollision(player)
        end
    end
    
    -- Prepare track generation
    local trackGenerator = _G.GetTrackGeneratorService()
    if trackGenerator then
        if trackGenerator.PreparePlayerTrack then
            trackGenerator:PreparePlayerTrack(player, sessionData.gameData)
        end
    end
    
    -- Set initial difficulty
    local difficultyService = _G.GetDifficultyService()
    if difficultyService then
        if difficultyService.InitializePlayerDifficulty then
            difficultyService:InitializePlayerDifficulty(player, sessionData.gameData.difficulty or 1)
        end
    end
end

function GameStateEventManager:SetupSystemResetBindings()
    print("🔄 Setting up System Reset Bindings...")
    
    -- System reset bindings are handled through state change actions
    print("✅ System reset bindings established")
end

-- ========================================
-- PLAYER STATE TRACKING
-- ========================================

function GameStateEventManager:SetupPlayerStateTracking()
    print("👥 Setting up Player State Tracking...")
    
    -- Player added - initialize to LOBBY state
    StateEventConnections.PlayerAdded = Players.PlayerAdded:Connect(function(player)
        CurrentGameStates[player.UserId] = "LOBBY"
        GameSessions[player.UserId] = {
            sessionId = player.UserId .. "_" .. tick(),
            startTime = tick(),
            states = {}
        }
        
        if STATE_CONFIG.enableDetailedLogging then
            print("👋 Player " .. player.Name .. " initialized to LOBBY state")
        end
    end)
    
    -- Player removing - cleanup state data
    StateEventConnections.PlayerRemoving = Players.PlayerRemoving:Connect(function(player)
        CurrentGameStates[player.UserId] = nil
        GameSessions[player.UserId] = nil
        
        -- Stop any ongoing connections
        self:StopRealTimeAnalytics(player)
        
        if STATE_CONFIG.enableDetailedLogging then
            print("👋 Player " .. player.Name .. " state data cleaned up")
        end
    end)
    
    print("✅ Player state tracking established")
end

-- ========================================
-- REMOTE EVENT HANDLERS
-- ========================================

function GameStateEventManager:SetupRemoteEventHandlers()
    print("📡 Setting up Remote Event Handlers...")
    
    -- Game state change remote events
    if _G.GetRemoteEvent then
        local gameStateEvent = _G.GetRemoteEvent("GameStateChange")
        if gameStateEvent then
            StateEventConnections.GameStateRemote = gameStateEvent.OnServerEvent:Connect(function(player, newState, gameData)
                self:ChangeGameState(player, newState, gameData)
            end)
        end
        
        -- Start game event
        local startGameEvent = _G.GetRemoteEvent("StartGame")
        if startGameEvent then
            StateEventConnections.StartGameRemote = startGameEvent.OnServerEvent:Connect(function(player, gameConfig)
                self:ChangeGameState(player, "STARTING", gameConfig)
            end)
        end
        
        -- End game event
        local endGameEvent = _G.GetRemoteEvent("EndGame")
        if endGameEvent then
            StateEventConnections.EndGameRemote = endGameEvent.OnServerEvent:Connect(function(player, gameResults)
                self:ChangeGameState(player, "ENDED", gameResults)
            end)
        end
        
        -- Reset game event
        local resetGameEvent = _G.GetRemoteEvent("ResetGame")
        if resetGameEvent then
            StateEventConnections.ResetGameRemote = resetGameEvent.OnServerEvent:Connect(function(player, resetData)
                self:ChangeGameState(player, "RESETTING", resetData)
            end)
        end
    end
    
    print("✅ Remote event handlers established")
end

-- ========================================
-- UTILITY METHODS
-- ========================================

function GameStateEventManager:GetStateDuration(player, state)
    local session = GameSessions[player.UserId]
    if not session or not session.states or not session.states[state] then
        return 0
    end
    
    return tick() - session.states[state].startTime
end

function GameStateEventManager:ExecuteCustomStateActions(sessionData)
    -- Add any custom state-specific actions here
    local player = sessionData.player
    local newState = sessionData.newState
    
    -- Custom actions can be added here for specific game requirements
end

function GameStateEventManager:NotifyServicesOfStateChange(sessionData)
    local services = {
        _G.GetMainGameController(),
        _G.GetGameService(),
        _G.GetCollisionController(),
        _G.GetTrackGeneratorService(),
        _G.GetDifficultyService()
    }
    
    for _, service in ipairs(services) do
        if service and service.HandleGameStateChange then
            pcall(function()
                service:HandleGameStateChange(sessionData.player, sessionData.newState, sessionData.gameData)
            end)
        end
    end
end

-- ========================================
-- MANAGEMENT METHODS
-- ========================================

function GameStateEventManager:GetPlayerState(player)
    return CurrentGameStates[player.UserId] or "LOBBY"
end

function GameStateEventManager:GetAllPlayerStates()
    return CurrentGameStates
end

function GameStateEventManager:GetGlobalGameState()
    return GlobalGameState
end

function GameStateEventManager:SetGlobalGameState(newState)
    GlobalGameState = newState
    
    -- Notify all players of global state change
    for userId, _ in pairs(CurrentGameStates) do
        local player = Players:GetPlayerByUserId(userId)
        if player then
            -- Send to client
            local gameStateEvent = _G.GetRemoteEvent and _G.GetRemoteEvent("GlobalGameStateChange")
            if gameStateEvent then
                gameStateEvent:FireClient(player, newState)
            end
        end
    end
end

function GameStateEventManager:DisconnectAll()
    print("🔌 Disconnecting all game state event connections...")
    
    for name, connection in pairs(StateEventConnections) do
        if connection and connection.Disconnect then
            connection:Disconnect()
        end
    end
    
    StateEventConnections = {}
    CurrentGameStates = {}
    GameSessions = {}
    
    print("✅ All game state connections disconnected")
end

-- Auto-initialize after all core services are loaded
spawn(function()
    wait(6) -- Wait for core services and other event managers
    GameStateEventManager:Initialize()
end)

return GameStateEventManager
