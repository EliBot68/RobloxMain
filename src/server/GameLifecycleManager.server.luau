-- GameLifecycleManager.server.luau
-- Handles the complete game lifecycle from server start to game end
-- Manages service initialization, game loop control, and system resets

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local GameLifecycleManager = {}

-- Lifecycle state tracking
local LifecycleState = "STARTING"
local GameLoopActive = false
local AdminCommands = {}
local SystemStatus = {}

-- Configuration
local LIFECYCLE_CONFIG = {
    enableDetailedLogging = true,
    autoStartGameLoop = true,
    autoStartDelay = 15, -- seconds after server start
    enableAdminCommands = true,
    gameLoopInterval = 1, -- seconds between game loop iterations
    enableSystemHealthMonitoring = true,
    healthCheckInterval = 30, -- seconds
    enableAutoRestart = true,
    maxPlayers = 50,
    adminUserIds = {} -- Add admin user IDs here
}

-- Lifecycle states
local LIFECYCLE_STATES = {
    "STARTING",     -- Server starting up, initializing services
    "READY",        -- Services initialized, ready for games
    "GAME_ACTIVE",  -- Game loop is running
    "RESETTING",    -- Resetting all systems
    "SHUTDOWN"      -- Server shutting down
}

function GameLifecycleManager:Initialize()
    print("🚀 Initializing Game Lifecycle Manager...")
    
    -- Set initial state
    LifecycleState = "STARTING"
    
    -- Wait for core services to initialize
    self:WaitForCoreServicesInitialization()
    
    -- Setup admin commands
    if LIFECYCLE_CONFIG.enableAdminCommands then
        self:SetupAdminCommands()
    end
    
    -- Setup system health monitoring
    if LIFECYCLE_CONFIG.enableSystemHealthMonitoring then
        self:StartSystemHealthMonitoring()
    end
    
    -- Setup game loop management
    self:SetupGameLoopManagement()
    
    -- Mark as ready
    self:TransitionToReady()
    
    -- Auto-start game loop if configured
    if LIFECYCLE_CONFIG.autoStartGameLoop then
        spawn(function()
            wait(LIFECYCLE_CONFIG.autoStartDelay)
            self:StartGameLoop("auto-start")
        end)
    end
    
    print("✅ Game Lifecycle Manager initialized successfully")
    return true
end

-- ========================================
-- SERVICE INITIALIZATION MANAGEMENT
-- ========================================

function GameLifecycleManager:WaitForCoreServicesInitialization()
    print("⏳ Waiting for core services initialization...")
    
    local timeout = 60 -- 60 second timeout
    local startTime = tick()
    
    while tick() - startTime < timeout do
        if self:CheckCoreServicesReady() then
            print("✅ All core services initialized successfully")
            SystemStatus.coreServicesReady = true
            return true
        end
        
        wait(1)
        
        if LIFECYCLE_CONFIG.enableDetailedLogging then
            print("⏳ Still waiting for core services... (" .. math.floor(tick() - startTime) .. "s)")
        end
    end
    
    warn("❌ Timeout waiting for core services initialization")
    SystemStatus.coreServicesReady = false
    return false
end

function GameLifecycleManager:CheckCoreServicesReady()
    local requiredServices = {
        "GameService",
        "AnalyticsService",
        "TrackGeneratorService", 
        "DifficultyService",
        "MainGameController",
        "CollisionController",
        "RecordingSessionManager",
        "MovingObstacleService",
        "SystemEventConnections",
        "GameStateEventManager"
    }
    
    for _, serviceName in ipairs(requiredServices) do
        local getter = _G["Get" .. serviceName]
        if not getter or not getter() then
            if LIFECYCLE_CONFIG.enableDetailedLogging then
                print("⏳ Waiting for: " .. serviceName)
            end
            return false
        end
    end
    
    return true
end

function GameLifecycleManager:InitializeSystemStatus()
    SystemStatus = {
        lifecycleState = LifecycleState,
        coreServicesReady = false,
        gameLoopActive = false,
        playerCount = 0,
        systemHealth = "unknown",
        lastHealthCheck = 0,
        uptime = tick(),
        gamesPlayed = 0,
        totalResets = 0
    }
end

-- ========================================
-- LIFECYCLE STATE MANAGEMENT
-- ========================================

function GameLifecycleManager:TransitionToReady()
    if LifecycleState ~= "STARTING" then
        warn("❌ Invalid state transition to READY from: " .. LifecycleState)
        return false
    end
    
    LifecycleState = "READY"
    SystemStatus.lifecycleState = "READY"
    
    print("🎯 System ready for game operations")
    
    -- Initialize all systems for ready state
    self:InitializeSystemsForReady()
    
    -- Notify analytics
    local analyticsService = _G.GetAnalyticsService()
    if analyticsService then
        analyticsService:TrackEvent(nil, "system_ready", {
            timestamp = tick(),
            uptime = tick() - SystemStatus.uptime
        })
    end
    
    return true
end

function GameLifecycleManager:TransitionToGameActive()
    if LifecycleState ~= "READY" and LifecycleState ~= "RESETTING" then
        warn("❌ Invalid state transition to GAME_ACTIVE from: " .. LifecycleState)
        return false
    end
    
    LifecycleState = "GAME_ACTIVE"
    SystemStatus.lifecycleState = "GAME_ACTIVE"
    SystemStatus.gameLoopActive = true
    
    print("🎮 Game loop activated")
    
    -- Notify all services of game activation
    self:NotifyServicesGameActive()
    
    return true
end

function GameLifecycleManager:TransitionToResetting()
    local previousState = LifecycleState
    LifecycleState = "RESETTING"
    SystemStatus.lifecycleState = "RESETTING"
    SystemStatus.gameLoopActive = false
    
    print("🔄 Transitioning to reset state from: " .. previousState)
    
    -- Stop game loop
    self:StopGameLoop("system-reset")
    
    -- Reset all systems
    self:ResetAllSystems()
    
    -- Increment reset counter
    SystemStatus.totalResets = SystemStatus.totalResets + 1
    
    return true
end

function GameLifecycleManager:InitializeSystemsForReady()
    print("🎯 Initializing systems for READY state...")
    
    -- Initialize core game systems
    local mainController = _G.GetMainGameController()
    if mainController then
        if mainController.InitializeForGameLoop then
            mainController:InitializeForGameLoop()
        end
    end
    
    -- Initialize track generator
    local trackGenerator = _G.GetTrackGeneratorService()
    if trackGenerator then
        if trackGenerator.PrepareForGameLoop then
            trackGenerator:PrepareForGameLoop()
        end
    end
    
    -- Initialize collision system
    local collisionController = _G.GetCollisionController()
    if collisionController then
        if collisionController.InitializeForGameLoop then
            collisionController:InitializeForGameLoop()
        end
    end
    
    -- Initialize difficulty system
    local difficultyService = _G.GetDifficultyService()
    if difficultyService then
        if difficultyService.InitializeForGameLoop then
            difficultyService:InitializeForGameLoop()
        end
    end
    
    print("✅ Systems initialized for READY state")
end

-- ========================================
-- GAME LOOP MANAGEMENT
-- ========================================

function GameLifecycleManager:SetupGameLoopManagement()
    print("🔄 Setting up game loop management...")
    
    -- Initialize game loop status
    GameLoopActive = false
    
    -- Setup game loop monitoring
    self:SetupGameLoopMonitoring()
    
    print("✅ Game loop management ready")
end

function GameLifecycleManager:StartGameLoop(trigger)
    trigger = trigger or "manual"
    
    if LifecycleState ~= "READY" then
        warn("❌ Cannot start game loop - system not ready (current state: " .. LifecycleState .. ")")
        return false
    end
    
    if GameLoopActive then
        warn("⚠️ Game loop already active")
        return false
    end
    
    print("▶️ Starting game loop (trigger: " .. trigger .. ")")
    
    -- Transition to game active state
    self:TransitionToGameActive()
    
    -- Start the main game loop
    self:RunMainGameLoop()
    
    -- Track analytics
    local analyticsService = _G.GetAnalyticsService()
    if analyticsService then
        analyticsService:TrackEvent(nil, "game_loop_started", {
            trigger = trigger,
            timestamp = tick(),
            playerCount = #Players:GetPlayers()
        })
    end
    
    return true
end

function GameLifecycleManager:StopGameLoop(reason)
    reason = reason or "manual"
    
    if not GameLoopActive then
        warn("⚠️ Game loop not active")
        return false
    end
    
    print("⏹️ Stopping game loop (reason: " .. reason .. ")")
    
    GameLoopActive = false
    
    -- Stop all active games
    self:StopAllActiveGames()
    
    -- Transition back to ready state
    if LifecycleState == "GAME_ACTIVE" then
        LifecycleState = "READY"
        SystemStatus.lifecycleState = "READY"
        SystemStatus.gameLoopActive = false
    end
    
    -- Track analytics
    local analyticsService = _G.GetAnalyticsService()
    if analyticsService then
        analyticsService:TrackEvent(nil, "game_loop_stopped", {
            reason = reason,
            timestamp = tick(),
            gamesPlayed = SystemStatus.gamesPlayed
        })
    end
    
    return true
end

function GameLifecycleManager:RunMainGameLoop()
    GameLoopActive = true
    
    spawn(function()
        print("🔄 Main game loop started")
        
        while GameLoopActive and LifecycleState == "GAME_ACTIVE" do
            -- Update player count
            SystemStatus.playerCount = #Players:GetPlayers()
            
            -- Run game loop iteration
            self:RunGameLoopIteration()
            
            -- Wait for next iteration
            wait(LIFECYCLE_CONFIG.gameLoopInterval)
        end
        
        print("🔄 Main game loop ended")
    end)
end

function GameLifecycleManager:RunGameLoopIteration()
    -- Check for players needing games
    local playersNeedingGames = self:GetPlayersNeedingGames()
    
    if #playersNeedingGames > 0 then
        self:StartGamesForPlayers(playersNeedingGames)
    end
    
    -- Update game states
    self:UpdateActiveGames()
    
    -- Clean up finished games
    self:CleanupFinishedGames()
    
    -- Update system metrics
    self:UpdateSystemMetrics()
end

function GameLifecycleManager:GetPlayersNeedingGames()
    local gameStateManager = _G.GetGameStateEventManager()
    if not gameStateManager then return {} end
    
    local playersNeeding = {}
    
    for _, player in pairs(Players:GetPlayers()) do
        local playerState = gameStateManager:GetPlayerState(player)
        
        -- Players in LOBBY state need games
        if playerState == "LOBBY" then
            table.insert(playersNeeding, player)
        end
    end
    
    return playersNeeding
end

function GameLifecycleManager:StartGamesForPlayers(players)
    local gameStateManager = _G.GetGameStateEventManager()
    if not gameStateManager then return end
    
    for _, player in ipairs(players) do
        if LIFECYCLE_CONFIG.enableDetailedLogging then
            print("🎮 Starting game for: " .. player.Name)
        end
        
        -- Transition player to preparing state
        gameStateManager:ChangeGameState(player, "PREPARING", {
            autoStarted = true,
            timestamp = tick()
        })
        
        -- Increment games played counter
        SystemStatus.gamesPlayed = SystemStatus.gamesPlayed + 1
    end
end

function GameLifecycleManager:UpdateActiveGames()
    -- Update logic for active games
    local mainController = _G.GetMainGameController()
    if mainController and mainController.UpdateActiveGames then
        mainController:UpdateActiveGames()
    end
end

function GameLifecycleManager:CleanupFinishedGames()
    -- Cleanup logic for finished games
    local mainController = _G.GetMainGameController()
    if mainController and mainController.CleanupFinishedGames then
        mainController:CleanupFinishedGames()
    end
end

function GameLifecycleManager:UpdateSystemMetrics()
    SystemStatus.playerCount = #Players:GetPlayers()
    SystemStatus.uptime = tick() - SystemStatus.uptime
end

function GameLifecycleManager:SetupGameLoopMonitoring()
    -- Monitor game loop health
    spawn(function()
        while true do
            wait(30) -- Check every 30 seconds
            
            if GameLoopActive then
                -- Verify game loop is still healthy
                if not self:CheckGameLoopHealth() then
                    warn("⚠️ Game loop health check failed - attempting restart")
                    self:RestartGameLoop("health-check-failure")
                end
            end
        end
    end)
end

function GameLifecycleManager:CheckGameLoopHealth()
    -- Basic health checks
    if LifecycleState ~= "GAME_ACTIVE" and GameLoopActive then
        return false
    end
    
    -- Check if core services are still available
    if not self:CheckCoreServicesReady() then
        return false
    end
    
    return true
end

function GameLifecycleManager:RestartGameLoop(reason)
    print("🔄 Restarting game loop (reason: " .. reason .. ")")
    
    self:StopGameLoop(reason)
    
    wait(2) -- Brief pause
    
    if LifecycleState == "READY" then
        self:StartGameLoop("auto-restart")
    end
end

-- ========================================
-- SYSTEM RESET MANAGEMENT
-- ========================================

function GameLifecycleManager:ResetAllSystems()
    print("🔄 Resetting all systems...")
    
    -- Stop game loop first
    if GameLoopActive then
        self:StopGameLoop("system-reset")
    end
    
    -- Reset all players
    self:ResetAllPlayers()
    
    -- Reset all core services
    self:ResetCoreServices()
    
    -- Reset system state
    self:ResetSystemState()
    
    -- Transition back to ready
    spawn(function()
        wait(2) -- Brief pause for cleanup
        
        if LifecycleState == "RESETTING" then
            LifecycleState = "READY"
            SystemStatus.lifecycleState = "READY"
            print("✅ System reset complete - ready for new games")
            
            -- Auto-restart game loop if configured
            if LIFECYCLE_CONFIG.autoStartGameLoop then
                wait(1)
                self:StartGameLoop("post-reset")
            end
        end
    end)
end

function GameLifecycleManager:ResetAllPlayers()
    print("👥 Resetting all players...")
    
    local gameStateManager = _G.GetGameStateEventManager()
    
    for _, player in pairs(Players:GetPlayers()) do
        if LIFECYCLE_CONFIG.enableDetailedLogging then
            print("🔄 Resetting player: " .. player.Name)
        end
        
        -- Reset player to lobby state
        if gameStateManager then
            gameStateManager:ChangeGameState(player, "RESETTING", {
                resetType = "system-wide",
                timestamp = tick()
            })
            
            -- Then to lobby
            spawn(function()
                wait(0.5)
                gameStateManager:ChangeGameState(player, "LOBBY", {
                    resetComplete = true,
                    timestamp = tick()
                })
            end)
        end
    end
end

function GameLifecycleManager:ResetCoreServices()
    print("🔧 Resetting core services...")
    
    local services = {
        _G.GetMainGameController(),
        _G.GetCollisionController(),
        _G.GetTrackGeneratorService(),
        _G.GetDifficultyService(),
        _G.GetRecordingSessionManager(),
        _G.GetMovingObstacleService()
    }
    
    for _, service in ipairs(services) do
        if service then
            -- Reset service if it has a reset method
            if service.ResetService then
                pcall(function()
                    service:ResetService()
                end)
            elseif service.Reset then
                pcall(function()
                    service:Reset()
                end)
            elseif service.Initialize then
                -- Reinitialize service
                pcall(function()
                    service:Initialize()
                end)
            end
        end
    end
end

function GameLifecycleManager:ResetSystemState()
    print("📊 Resetting system state...")
    
    -- Reset system status (preserve some metrics)
    local previousGamesPlayed = SystemStatus.gamesPlayed
    local previousTotalResets = SystemStatus.totalResets
    local previousUptime = SystemStatus.uptime
    
    self:InitializeSystemStatus()
    
    -- Restore preserved metrics
    SystemStatus.gamesPlayed = previousGamesPlayed
    SystemStatus.totalResets = previousTotalResets
    SystemStatus.uptime = previousUptime
    SystemStatus.lifecycleState = "RESETTING"
end

function GameLifecycleManager:StopAllActiveGames()
    print("🛑 Stopping all active games...")
    
    local gameStateManager = _G.GetGameStateEventManager()
    if not gameStateManager then return end
    
    for _, player in pairs(Players:GetPlayers()) do
        local playerState = gameStateManager:GetPlayerState(player)
        
        -- Stop any active games
        if playerState == "PLAYING" or playerState == "PREPARING" or playerState == "STARTING" then
            gameStateManager:ChangeGameState(player, "ENDED", {
                reason = "system-shutdown",
                forced = true,
                timestamp = tick()
            })
        end
    end
end

-- ========================================
-- ADMIN COMMANDS
-- ========================================

function GameLifecycleManager:SetupAdminCommands()
    print("👑 Setting up admin commands...")
    
    -- Setup chat commands for admins
    Players.PlayerAdded:Connect(function(player)
        if self:IsAdmin(player) then
            print("👑 Admin connected: " .. player.Name)
            
            player.Chatted:Connect(function(message)
                self:HandleAdminCommand(player, message)
            end)
        end
    end)
    
    -- Setup existing players
    for _, player in pairs(Players:GetPlayers()) do
        if self:IsAdmin(player) then
            player.Chatted:Connect(function(message)
                self:HandleAdminCommand(player, message)
            end)
        end
    end
    
    print("✅ Admin commands ready")
end

function GameLifecycleManager:IsAdmin(player)
    -- Check if player is admin by UserId
    for _, adminId in ipairs(LIFECYCLE_CONFIG.adminUserIds) do
        if player.UserId == adminId then
            return true
        end
    end
    
    -- Check if player has admin privileges (game creator, etc.)
    if player.UserId == game.CreatorId then
        return true
    end
    
    return false
end

function GameLifecycleManager:HandleAdminCommand(player, message)
    local command = message:lower()
    
    if command:sub(1, 1) ~= "/" then return end -- Must start with /
    
    local cmd = command:sub(2) -- Remove /
    
    if LIFECYCLE_CONFIG.enableDetailedLogging then
        print("👑 Admin command from " .. player.Name .. ": " .. cmd)
    end
    
    -- Start game loop
    if cmd == "startgame" or cmd == "start" then
        if self:StartGameLoop("admin-command") then
            self:SendAdminMessage(player, "✅ Game loop started")
        else
            self:SendAdminMessage(player, "❌ Failed to start game loop")
        end
        
    -- Stop game loop
    elseif cmd == "stopgame" or cmd == "stop" then
        if self:StopGameLoop("admin-command") then
            self:SendAdminMessage(player, "✅ Game loop stopped")
        else
            self:SendAdminMessage(player, "❌ Failed to stop game loop")
        end
        
    -- Reset all systems
    elseif cmd == "reset" or cmd == "resetall" then
        self:TransitionToResetting()
        self:SendAdminMessage(player, "🔄 Resetting all systems...")
        
    -- Get system status
    elseif cmd == "status" then
        local status = self:GetSystemStatusReport()
        self:SendAdminMessage(player, status)
        
    -- Restart game loop
    elseif cmd == "restart" then
        self:RestartGameLoop("admin-command")
        self:SendAdminMessage(player, "🔄 Restarting game loop...")
        
    -- Force player reset
    elseif cmd:sub(1, 5) == "reset" then
        local targetName = cmd:sub(7) -- "reset PlayerName"
        local targetPlayer = Players:FindFirstChild(targetName)
        if targetPlayer then
            self:ResetPlayer(targetPlayer)
            self:SendAdminMessage(player, "🔄 Reset player: " .. targetName)
        else
            self:SendAdminMessage(player, "❌ Player not found: " .. targetName)
        end
        
    -- Help command
    elseif cmd == "help" then
        local helpText = "🔧 Admin Commands:\n/start - Start game loop\n/stop - Stop game loop\n/reset - Reset all systems\n/restart - Restart game loop\n/status - System status\n/reset PlayerName - Reset specific player"
        self:SendAdminMessage(player, helpText)
        
    else
        self:SendAdminMessage(player, "❓ Unknown command. Use /help for commands")
    end
end

function GameLifecycleManager:SendAdminMessage(player, message)
    -- Send message to admin (you can customize this)
    print("👑 → " .. player.Name .. ": " .. message)
    
    -- You could also create a GUI message or use RemoteEvents here
end

function GameLifecycleManager:ResetPlayer(player)
    local gameStateManager = _G.GetGameStateEventManager()
    if gameStateManager then
        gameStateManager:ChangeGameState(player, "RESETTING", {
            resetType = "admin-command",
            timestamp = tick()
        })
        
        spawn(function()
            wait(0.5)
            gameStateManager:ChangeGameState(player, "LOBBY", {
                resetComplete = true,
                timestamp = tick()
            })
        end)
    end
end

-- ========================================
-- SYSTEM HEALTH MONITORING
-- ========================================

function GameLifecycleManager:StartSystemHealthMonitoring()
    print("🔍 Starting system health monitoring...")
    
    spawn(function()
        while true do
            wait(LIFECYCLE_CONFIG.healthCheckInterval)
            self:PerformSystemHealthCheck()
        end
    end)
end

function GameLifecycleManager:PerformSystemHealthCheck()
    local healthData = {
        timestamp = tick(),
        coreServicesHealth = self:CheckCoreServicesReady(),
        gameLoopHealth = GameLoopActive and self:CheckGameLoopHealth() or true,
        playerCount = #Players:GetPlayers(),
        memoryUsage = gcinfo(),
        uptime = tick() - SystemStatus.uptime
    }
    
    -- Update system status
    SystemStatus.systemHealth = healthData.coreServicesHealth and healthData.gameLoopHealth and "healthy" or "unhealthy"
    SystemStatus.lastHealthCheck = tick()
    
    -- Log health status
    if LIFECYCLE_CONFIG.enableDetailedLogging then
        local status = SystemStatus.systemHealth == "healthy" and "✅" or "❌"
        print(status .. " System health check: " .. SystemStatus.systemHealth)
    end
    
    -- Track analytics
    local analyticsService = _G.GetAnalyticsService()
    if analyticsService then
        analyticsService:TrackEvent(nil, "system_health_check", healthData)
    end
    
    -- Auto-restart if unhealthy and auto-restart is enabled
    if SystemStatus.systemHealth == "unhealthy" and LIFECYCLE_CONFIG.enableAutoRestart then
        warn("⚠️ System unhealthy - attempting auto-restart")
        self:TransitionToResetting()
    end
end

-- ========================================
-- STATUS AND REPORTING
-- ========================================

function GameLifecycleManager:GetSystemStatusReport()
    local report = {
        "🎮 Game Lifecycle Status:",
        "State: " .. LifecycleState,
        "Game Loop: " .. (GameLoopActive and "Active" or "Inactive"),
        "Players: " .. SystemStatus.playerCount,
        "Games Played: " .. SystemStatus.gamesPlayed,
        "Total Resets: " .. SystemStatus.totalResets,
        "Health: " .. SystemStatus.systemHealth,
        "Uptime: " .. math.floor(tick() - SystemStatus.uptime) .. "s"
    }
    
    return table.concat(report, "\n")
end

function GameLifecycleManager:GetLifecycleState()
    return LifecycleState
end

function GameLifecycleManager:IsGameLoopActive()
    return GameLoopActive
end

function GameLifecycleManager:GetSystemStatus()
    return SystemStatus
end

-- ========================================
-- INITIALIZATION
-- ========================================

-- Initialize system status
GameLifecycleManager:InitializeSystemStatus()

-- Global accessors
_G.GetGameLifecycleManager = function()
    return GameLifecycleManager
end

_G.StartGameLoop = function()
    return GameLifecycleManager:StartGameLoop("global-command")
end

_G.StopGameLoop = function()
    return GameLifecycleManager:StopGameLoop("global-command")
end

_G.ResetAllSystems = function()
    return GameLifecycleManager:TransitionToResetting()
end

-- Auto-initialize after all other systems
spawn(function()
    wait(8) -- Wait for all core services to load
    GameLifecycleManager:Initialize()
end)

return GameLifecycleManager
