-- MainGameService.luau
-- Enhanced master orchestration service with proper module requiring, state management, and event integration
-- Implements Init(), Start(), SafeRequire, WorldObjectValidator, and comprehensive event handling
-- This is the production-ready master service that ties everything together

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

-- Wait for shared modules
local SharedFolder = ReplicatedStorage:WaitForChild("Shared", 10)
if not SharedFolder then
    error("MainGameService: Failed to find Shared folder!")
end

-- Import utilities with proper error handling
local SafeRequire = nil
local WorldObjectValidator = nil
local DeveloperConfig = nil

-- Try to load SafeRequire
local success, result = pcall(function()
    local utilsFolder = SharedFolder:WaitForChild("utils", 5)
    return require(utilsFolder.SafeRequire)
end)

if success then
    SafeRequire = result
else
    warn("MainGameService: Failed to load SafeRequire, using fallback")
    SafeRequire = {
        require = function(moduleScript, defaultValue)
            local s, r = pcall(require, moduleScript)
            return s and r or defaultValue
        end
    }
end

-- Try to load WorldObjectValidator
local success2, result2 = pcall(function()
    local utilsFolder = SharedFolder:WaitForChild("utils", 5)
    return require(utilsFolder.WorldObjectValidator)
end)

if success2 then
    WorldObjectValidator = result2
else
    warn("MainGameService: Failed to load WorldObjectValidator")
end

-- Try to load DeveloperConfig
local success3, result3 = pcall(function()
    local modulesFolder = SharedFolder:WaitForChild("modules", 5)
    return require(modulesFolder.DeveloperConfig)
end)

if success3 then
    DeveloperConfig = result3
else
    warn("MainGameService: Failed to load DeveloperConfig")
end

local MainGameService = {}

-- Service state management
MainGameService.State = "Lobby" -- "Lobby", "Preparing", "Running", "GameOver", "Resetting"
MainGameService.Services = {}
MainGameService.Controllers = {}
MainGameService.EventConnections = {}
MainGameService.ActiveGames = {}

-- Initialization flags
local isInitialized = false
local isStarted = false
local initializationTime = 0

-- Configuration
local SERVICE_CONFIG = {
    enableDetailedLogging = true,
    maxInitializationTime = 60,
    healthCheckInterval = 30,
    autoStartAfterInit = true,
    retryFailedRequires = true,
    maxRetryAttempts = 3,
    validateWorldObjects = true,
    enableDeveloperMode = false -- Will be set based on DeveloperConfig
}

-- ========================================
-- SAFE MODULE REQUIRING
-- ========================================

function MainGameService:SafeRequire(modulePath, moduleName, isOptional)
    isOptional = isOptional or false
    
    -- Use the utility SafeRequire if available, fallback to internal implementation
    if SafeRequire and SafeRequire.requireWithRetry then
        local maxAttempts = SERVICE_CONFIG.retryFailedRequires and SERVICE_CONFIG.maxRetryAttempts or 1
        local result = SafeRequire.requireWithRetry(modulePath, maxAttempts, nil)
        
        if result then
            if SERVICE_CONFIG.enableDetailedLogging then
                print("✅ SafeRequire: " .. moduleName .. " loaded successfully")
            end
            return result
        else
            if isOptional then
                warn("⚠️ SafeRequire: Optional module " .. moduleName .. " failed to load")
                return nil
            else
                error("❌ SafeRequire: Critical module " .. moduleName .. " failed to load")
            end
        end
    else
        -- Fallback to internal implementation
        local maxAttempts = SERVICE_CONFIG.retryFailedRequires and SERVICE_CONFIG.maxRetryAttempts or 1
        
        for attempt = 1, maxAttempts do
            local success, result = pcall(function()
                return require(modulePath)
            end)
            
            if success then
                if SERVICE_CONFIG.enableDetailedLogging then
                    print("✅ SafeRequire: " .. moduleName .. " loaded successfully" .. (attempt > 1 and " (attempt " .. attempt .. ")" or ""))
                end
                return result
            else
                if attempt < maxAttempts then
                    warn("⚠️ SafeRequire: " .. moduleName .. " failed (attempt " .. attempt .. "), retrying...")
                    -- Event-driven retry delay (NO POLLING)
                    task.delay(0.3, function()
                        -- Retry logic continues in next iteration
                    end)
                else
                    if isOptional then
                        warn("⚠️ SafeRequire: Optional module " .. moduleName .. " failed to load: " .. tostring(result))
                        return nil
                    else
                        error("❌ SafeRequire: Critical module " .. moduleName .. " failed to load: " .. tostring(result))
                    end
                end
            end
        end
    end
    
    return nil
end

-- ========================================
-- INITIALIZATION PHASE (Init Method)
-- ========================================

function MainGameService:Init()
    if isInitialized then
        warn("⚠️ MainGameService already initialized!")
        return true
    end
    
    local startTime = tick()
    print("🚀 MainGameService:Init() - Starting initialization...")
    
    -- Check developer mode
    if DeveloperConfig then
        SERVICE_CONFIG.enableDeveloperMode = true
        print("🛠️ Developer mode enabled")
    end
    
    -- Validate world objects first if enabled
    if SERVICE_CONFIG.validateWorldObjects and WorldObjectValidator then
        print("🔍 Validating world objects...")
        local isValid = WorldObjectValidator.performFullValidation()
        if not isValid then
            warn("⚠️ World object validation failed - some objects may be missing")
            -- Continue initialization but log the issue
        else
            print("✅ World object validation passed")
        end
    end
    
    -- Set initial state
    self.State = "Lobby"
    
    -- Load core services and controllers using SafeRequire
    local success = self:LoadCoreModules()
    if not success then
        warn("❌ Failed to load core modules")
        return false
    end
    
    -- Initialize core services
    success = self:InitializeCoreServices()
    if not success then
        warn("❌ Failed to initialize core services")
        return false
    end
    
    -- Setup event connections
    self:SetupEventConnections()
    
    -- Setup global accessors
    self:SetupGlobalAccessors()
    
    -- Mark as initialized
    isInitialized = true
    initializationTime = tick() - startTime
    
    print("✅ MainGameService:Init() complete (" .. string.format("%.2f", initializationTime) .. "s)")
    
    -- Auto-start if configured
    if SERVICE_CONFIG.autoStartAfterInit then
        task.spawn(function() -- UPDATED for modern API
            task.wait(1) -- UPDATED for modern API - Brief delay
            self:Start()
        end)
    end
    
    return true
end

function MainGameService:LoadCoreModules()
    print("📦 Loading core modules with SafeRequire...")
    
    -- Core Services (Critical)
    self.Services.GameService = self:SafeRequire(
        script.Parent.core.GameService, 
        "GameService", 
        false
    )
    
    self.Services.AnalyticsService = self:SafeRequire(
        script.Parent.AnalyticsService, 
        "AnalyticsService", 
        false
    )
    
    self.Services.TrackGeneratorService = self:SafeRequire(
        script.Parent.TrackGeneratorService, 
        "TrackGeneratorService", 
        false
    )
    
    self.Services.DifficultyService = self:SafeRequire(
        script.Parent.DifficultyService, 
        "DifficultyService", 
        false
    )
    
    -- Controllers (Critical)
    self.Controllers.MainGameController = self:SafeRequire(
        script.Parent.Parent.controllers.MainGameController, 
        "MainGameController", 
        false
    )
    
    self.Controllers.CollisionController = self:SafeRequire(
        script.Parent.Parent.controllers.CollisionController, 
        "CollisionController", 
        false
    )
    
    -- Optional Services
    self.Services.RecordingSessionManager = self:SafeRequire(
        script.Parent.RecordingSessionManager, 
        "RecordingSessionManager", 
        true
    )
    
    self.Services.MovingObstacleService = self:SafeRequire(
        script.Parent.MovingObstacleService, 
        "MovingObstacleService", 
        true
    )
    
    -- Utility Services
    self.Services.ProfessionalLighting = self:SafeRequire(
        script.Parent.ProfessionalLighting, 
        "ProfessionalLighting", 
        true
    )
    
    print("✅ Core modules loaded successfully")
    return true
end

function MainGameService:InitializeCoreServices()
    print("🔧 Initializing core services...")
    
    -- Initialize services in dependency order
    local initOrder = {
        {"AnalyticsService", "Initialize"},
        {"GameService", "Initialize"},
        {"TrackGeneratorService", "Initialize"},
        {"DifficultyService", "KnitStart"},
        {"MainGameController", "Initialize"},
        {"CollisionController", "Initialize"},
        {"RecordingSessionManager", "Init"},
        {"MovingObstacleService", "Initialize"},
        {"ProfessionalLighting", "Initialize"}
    }
    
    for _, serviceInfo in ipairs(initOrder) do
        local serviceName, initMethod = serviceInfo[1], serviceInfo[2]
        local serviceCategory = self.Services[serviceName] and "Services" or "Controllers"
        local service = self[serviceCategory][serviceName]
        
        if service then
            if service[initMethod] then
                local success, error = pcall(function()
                    service[initMethod](service)
                end)
                
                if success then
                    if SERVICE_CONFIG.enableDetailedLogging then
                        print("✅ " .. serviceName .. " initialized")
                    end
                else
                    warn("❌ Failed to initialize " .. serviceName .. ": " .. tostring(error))
                end
            else
                if SERVICE_CONFIG.enableDetailedLogging then
                    print("📋 " .. serviceName .. " loaded (no " .. initMethod .. " method)")
                end
            end
        else
            warn("⚠️ " .. serviceName .. " not found for initialization")
        end
    end
    
    print("✅ Core services initialization complete")
    return true
end

-- ========================================
-- START PHASE (Start Method)  
-- ========================================

function MainGameService:Start()
    if not isInitialized then
        warn("❌ Cannot start MainGameService - not initialized. Call Init() first.")
        return false
    end
    
    if isStarted then
        warn("⚠️ MainGameService already started!")
        return true
    end
    
    print("▶️ MainGameService:Start() - Starting game operations...")
    
    -- Start all services that have Start methods
    self:StartAllServices()
    
    -- Begin health monitoring
    self:StartHealthMonitoring()
    
    -- Initialize game state
    self:InitializeGameState()
    
    -- Mark as started
    isStarted = true
    
    print("✅ MainGameService:Start() complete - Ready for players!")
    
    -- Track analytics
    if self.Services.AnalyticsService then
        self.Services.AnalyticsService:TrackEvent(nil, "main_game_service_started", {
            initializationTime = initializationTime,
            timestamp = tick()
        })
    end
    
    return true
end

function MainGameService:StartAllServices()
    print("🚀 Starting all services...")
    
    -- Services that have Start methods
    local startableServices = {
        "GameService",
        "AnalyticsService", 
        "TrackGeneratorService",
        "MainGameController",
        "CollisionController",
        "RecordingSessionManager"
    }
    
    for _, serviceName in ipairs(startableServices) do
        local service = self.Services[serviceName] or self.Controllers[serviceName]
        
        if service and service.Start then
            local success, error = pcall(function()
                service:Start()
            end)
            
            if success then
                if SERVICE_CONFIG.enableDetailedLogging then
                    print("▶️ " .. serviceName .. " started")
                end
            else
                warn("❌ Failed to start " .. serviceName .. ": " .. tostring(error))
            end
        end
    end
    
    print("✅ All services started")
end

function MainGameService:InitializeGameState()
    print("🎮 Initializing game state...")
    
    -- Set initial game state
    self.State = "Lobby"
    
    -- Initialize active games tracking
    self.ActiveGames = {}
    
    -- Setup game state tracking
    self:SetupGameStateTracking()
    
    print("✅ Game state initialized - State: " .. self.State)
end

-- ========================================
-- GAME STATE MANAGEMENT
-- ========================================

function MainGameService:SetGameState(newState, data)
    local previousState = self.State
    self.State = newState
    
    if SERVICE_CONFIG.enableDetailedLogging then
        print("🎮 Game state change: " .. previousState .. " → " .. newState)
    end
    
    -- Handle state transitions
    self:HandleStateTransition(previousState, newState, data)
    
    -- Track analytics
    if self.Services.AnalyticsService then
        self.Services.AnalyticsService:TrackEvent(nil, "game_state_changed", {
            previousState = previousState,
            newState = newState,
            timestamp = tick(),
            data = data or {}
        })
    end
end

function MainGameService:HandleStateTransition(from, to, data)
    -- Handle specific state transitions
    if to == "Running" and from == "Preparing" then
        self:OnGameStarted(data)
    elseif to == "GameOver" and from == "Running" then
        self:OnGameEnded(data)
    elseif to == "Lobby" and from == "GameOver" then
        self:OnGameReset(data)
    end
end

function MainGameService:OnGameStarted(data)
    print("🎮 Game started!")
    
    -- Start recording if available
    if self.Services.RecordingSessionManager then
        self.Services.RecordingSessionManager:StartRecording(data.player, data)
    end
    
    -- Initialize difficulty
    if self.Services.DifficultyService then
        self.Services.DifficultyService:InitializeForGame(data.player)
    end
    
    -- Generate track
    if self.Services.TrackGeneratorService then
        self.Services.TrackGeneratorService:GenerateTrack(data.trackConfig or {})
    end
end

function MainGameService:OnGameEnded(data)
    print("🏁 Game ended!")
    
    -- Stop recording
    if self.Services.RecordingSessionManager then
        self.Services.RecordingSessionManager:StopRecording(data.player)
    end
    
    -- Log game end analytics
    if self.Services.AnalyticsService then
        self.Services.AnalyticsService:LogGameEnd(data)
    end
    
    -- Clear track
    if self.Services.TrackGeneratorService then
        self.Services.TrackGeneratorService:ClearTrack()
    end
    
    -- Reset collision system
    if self.Controllers.CollisionController then
        self.Controllers.CollisionController:ResetForPlayer(data.player)
    end
end

function MainGameService:OnGameReset(data)
    print("🔄 Game reset!")
    
    -- Reset all services
    self:ResetAllServices()
    
    -- Clear active games
    self.ActiveGames = {}
end

-- ========================================
-- CALLABLE GAME FUNCTIONS
-- ========================================

function MainGameService:StartGame(player, gameConfig)
    if self.State ~= "Lobby" and self.State ~= "GameOver" then
        warn("❌ Cannot start game - invalid state: " .. self.State)
        return false
    end
    
    print("🎮 Starting game for: " .. (player and player.Name or "System"))
    
    -- Create game session
    local gameId = self:CreateGameSession(player, gameConfig)
    
    -- Set state to preparing
    self:SetGameState("Preparing", {
        player = player,
        gameId = gameId,
        gameConfig = gameConfig or {}
    })
    
    -- Prepare player for game
    if self.Controllers.MainGameController then
        self.Controllers.MainGameController:PreparePlayerForGame(player, gameConfig)
    end
    
    -- Start the actual game
    task.spawn(function() -- UPDATED for modern API
        task.wait(1) -- UPDATED for modern API - Brief preparation time
        
        self:SetGameState("Running", {
            player = player,
            gameId = gameId,
            trackConfig = gameConfig and gameConfig.trackConfig or {},
            startTime = tick()
        })
    end)
    
    return gameId
end

function MainGameService:EndGame(player, results)
    if self.State ~= "Running" then
        warn("❌ Cannot end game - invalid state: " .. self.State)
        return false
    end
    
    print("🏁 Ending game for: " .. (player and player.Name or "System"))
    
    -- Get game session
    local gameSession = self:GetGameSession(player)
    if gameSession then
        gameSession.endTime = tick()
        gameSession.results = results or {}
        gameSession.duration = gameSession.endTime - gameSession.startTime
    end
    
    -- Set state to game over
    self:SetGameState("GameOver", {
        player = player,
        results = results or {},
        gameSession = gameSession
    })
    
    -- Auto-return to lobby after delay
    task.spawn(function() -- UPDATED for modern API
        task.wait(3) -- UPDATED for modern API - Show results for 3 seconds
        
        self:SetGameState("Lobby", {
            player = player,
            previousResults = results
        })
    end)
    
    return true
end

function MainGameService:CreateGameSession(player, gameConfig)
    local gameId = (player and player.UserId or 0) .. "_" .. tick()
    
    self.ActiveGames[gameId] = {
        gameId = gameId,
        player = player,
        startTime = tick(),
        endTime = nil,
        gameConfig = gameConfig or {},
        results = nil,
        duration = 0
    }
    
    return gameId
end

function MainGameService:GetGameSession(player)
    for gameId, session in pairs(self.ActiveGames) do
        if session.player == player then
            return session
        end
    end
    return nil
end

-- ========================================
-- EVENT INTEGRATION SETUP
-- ========================================

function MainGameService:SetupEventConnections()
    print("🔗 Setting up event connections...")
    
    -- Player management events
    self.EventConnections.PlayerAdded = Players.PlayerAdded:Connect(function(player)
        self:HandlePlayerJoin(player)
    end)
    
    self.EventConnections.PlayerRemoving = Players.PlayerRemoving:Connect(function(player)
        self:HandlePlayerLeave(player)
    end)
    
    -- Handle existing players
    for _, player in pairs(Players:GetPlayers()) do
        task.spawn(function() -- UPDATED for modern API
            self:HandlePlayerJoin(player)
        end)
    end
    
    -- Game controller events
    if self.Controllers.MainGameController then
        -- Game ended event
        if self.Controllers.MainGameController.GameEnded then
            self.EventConnections.GameEnded = self.Controllers.MainGameController.GameEnded:Connect(function(player, results)
                self:HandleGameEndedEvent(player, results)
            end)
        end
        
        -- Game started event
        if self.Controllers.MainGameController.GameStarted then
            self.EventConnections.GameStarted = self.Controllers.MainGameController.GameStarted:Connect(function(player, gameData)
                self:HandleGameStartedEvent(player, gameData)
            end)
        end
    end
    
    -- Collision events
    if self.Controllers.CollisionController then
        if self.Controllers.CollisionController.PlayerCollision then
            self.EventConnections.PlayerCollision = self.Controllers.CollisionController.PlayerCollision:Connect(function(player, collisionData)
                self:HandlePlayerCollision(player, collisionData)
            end)
        end
    end
    
    print("✅ Event connections established")
end

function MainGameService:HandlePlayerJoin(player)
    print("👋 Player joined: " .. player.Name)
    
    -- Handle with MainGameController
    if self.Controllers.MainGameController then
        if self.Controllers.MainGameController.HandlePlayerJoin then
            self.Controllers.MainGameController:HandlePlayerJoin(player)
        end
    end
    
    -- Setup player in services
    if self.Services.GameService then
        if self.Services.GameService.OnPlayerAdded then
            self.Services.GameService:OnPlayerAdded(player)
        end
    end
    
    if self.Services.AnalyticsService then
        self.Services.AnalyticsService:TrackPlayerJoin(player)
    end
    
    if self.Controllers.CollisionController then
        if self.Controllers.CollisionController.SetupPlayer then
            self.Controllers.CollisionController:SetupPlayer(player)
        end
    end
end

function MainGameService:HandlePlayerLeave(player)
    print("👋 Player leaving: " .. player.Name)
    
    -- Clean up any active games for this player
    for gameId, session in pairs(self.ActiveGames) do
        if session.player == player then
            self:EndGame(player, {reason = "player_left"})
            break
        end
    end
    
    -- Handle with services
    if self.Services.AnalyticsService then
        self.Services.AnalyticsService:TrackPlayerLeave(player)
    end
    
    if self.Controllers.MainGameController then
        if self.Controllers.MainGameController.HandlePlayerLeave then
            self.Controllers.MainGameController:HandlePlayerLeave(player)
        end
    end
end

function MainGameService:HandleGameEndedEvent(player, results)
    print("🎮 Game ended event for: " .. (player and player.Name or "Unknown"))
    
    -- Log game end analytics
    if self.Services.AnalyticsService then
        self.Services.AnalyticsService:LogGameEnd(results)
    end
    
    -- Stop recording
    if self.Services.RecordingSessionManager then
        self.Services.RecordingSessionManager:StopRecording(player)
    end
    
    -- Clear track
    if self.Services.TrackGeneratorService then
        self.Services.TrackGeneratorService:ClearTrack()
    end
    
    -- Update internal state
    if self.State == "Running" then
        self:EndGame(player, results)
    end
end

function MainGameService:HandleGameStartedEvent(player, gameData)
    print("🎮 Game started event for: " .. (player and player.Name or "Unknown"))
    
    -- Update internal state if needed
    if self.State == "Lobby" or self.State == "GameOver" then
        self:StartGame(player, gameData)
    end
end

function MainGameService:HandlePlayerCollision(player, collisionData)
    -- Handle collision events
    if self.Services.AnalyticsService then
        self.Services.AnalyticsService:TrackEvent(player, "player_collision", collisionData)
    end
    
    -- Check if collision should end game
    if collisionData.fatal then
        self:EndGame(player, {
            reason = "collision",
            collisionData = collisionData
        })
    end
end

-- ========================================
-- SYSTEM INTEGRITY VALIDATION
-- ========================================

function MainGameService:ValidateSystemIntegrity()
    print("🔍 Performing comprehensive system integrity check...")
    
    local results = {
        worldObjects = {valid = true, issues = {}},
        services = {valid = true, issues = {}},
        configuration = {valid = true, issues = {}},
        overall = true
    }
    
    -- World Object Validation
    if WorldObjectValidator then
        local requiredMissing = WorldObjectValidator.validateAllRequired()
        local optionalMissing = WorldObjectValidator.validateAllOptional()
        
        if #requiredMissing > 0 then
            results.worldObjects.valid = false
            results.overall = false
            results.worldObjects.issues = requiredMissing
            warn("❌ Critical world objects missing: " .. #requiredMissing)
        end
        
        if #optionalMissing > 0 and SERVICE_CONFIG.enableDetailedLogging then
            print("⚠️ Optional world objects missing: " .. #optionalMissing)
        end
    end
    
    -- Service Health Validation
    local criticalServices = {"GameService", "AnalyticsService", "TrackGeneratorService", "MainGameController"}
    for _, serviceName in ipairs(criticalServices) do
        if not self.Services[serviceName] and not self.Controllers[serviceName] then
            results.services.valid = false
            results.overall = false
            table.insert(results.services.issues, "Missing critical service: " .. serviceName)
        end
    end
    
    -- Configuration Validation
    if DeveloperConfig then
        local configValid, configIssues = pcall(function()
            return DeveloperConfig:ValidateConfig()
        end)
        
        if not configValid or not configIssues then
            results.configuration.valid = false
            results.overall = false
            table.insert(results.configuration.issues, "Developer configuration validation failed")
        end
    end
    
    -- Report results
    if results.overall then
        print("✅ System integrity check passed")
    else
        warn("❌ System integrity check failed")
        
        if not results.worldObjects.valid then
            for _, issue in ipairs(results.worldObjects.issues) do
                warn("  World Objects: " .. issue)
            end
        end
        
        if not results.services.valid then
            for _, issue in ipairs(results.services.issues) do
                warn("  Services: " .. issue)
            end
        end
        
        if not results.configuration.valid then
            for _, issue in ipairs(results.configuration.issues) do
                warn("  Configuration: " .. issue)
            end
        end
    end
    
    return results
end

function MainGameService:ValidateAndRepairSystem()
    print("🔧 Starting system validation and repair...")
    
    local integrity = self:ValidateSystemIntegrity()
    
    if not integrity.overall then
        print("🛠️ Attempting automatic repairs...")
        
        -- Attempt to create missing world objects
        if not integrity.worldObjects.valid and WorldObjectValidator then
            for _, missingPath in ipairs(integrity.worldObjects.issues) do
                local success = pcall(function()
                    WorldObjectValidator.createObjectIfMissing(missingPath, "Folder")
                end)
                
                if success then
                    print("🔧 Created missing object: " .. missingPath)
                else
                    warn("❌ Failed to create: " .. missingPath)
                end
            end
        end
        
        -- Attempt to reload missing services
        if not integrity.services.valid then
            for _, issue in ipairs(integrity.services.issues) do
                local serviceName = issue:match("Missing critical service: (.+)")
                if serviceName then
                    print("🔄 Attempting to reload: " .. serviceName)
                    self:LoadService(serviceName)
                end
            end
        end
        
        print("✅ System repair attempt completed")
        
        -- Re-validate after repairs
        task.spawn(function() -- UPDATED for modern API
            task.wait(2) -- UPDATED for modern API
            self:ValidateSystemIntegrity()
        end)
    end
    
    return integrity
end

-- ========================================
-- SYSTEM MANAGEMENT
-- ========================================

function MainGameService:ResetAllServices()
    print("🔄 Resetting all services...")
    
    -- Reset services that have Reset methods
    local resetableServices = {
        "MainGameController",
        "CollisionController", 
        "TrackGeneratorService",
        "DifficultyService",
        "RecordingSessionManager"
    }
    
    for _, serviceName in ipairs(resetableServices) do
        local service = self.Services[serviceName] or self.Controllers[serviceName]
        
        if service then
            if service.Reset then
                pcall(function()
                    service:Reset()
                end)
            elseif service.ResetService then
                pcall(function()
                    service:ResetService()
                end)
            end
        end
    end
    
    print("✅ All services reset")
end

function MainGameService:StartHealthMonitoring()
    if SERVICE_CONFIG.healthCheckInterval <= 0 then return end
    
    -- CONVERTED: Polling loop → Event-driven health monitoring
    local HealthMonitorEvent = Instance.new("BindableEvent")
    local monitorInterval = math.max(30, SERVICE_CONFIG.healthCheckInterval) -- Start with at least 30s
    
    local function scheduleHealthCheck()
        if not isStarted then return end
        
        task.delay(monitorInterval, function()
            if isStarted then
                HealthMonitorEvent:Fire()
                scheduleHealthCheck() -- Schedule next check
            end
        end)
    end
    
    HealthMonitorEvent.Event:Connect(function()
        local beforeCheck = tick()
        self:PerformHealthCheck()
        local checkTime = tick() - beforeCheck
        
        -- Adaptive interval based on system health and check time
        if checkTime > 1.0 then -- Slow health checks indicate issues
            monitorInterval = math.max(15, monitorInterval * 0.8) -- More frequent when slow
            print(string.format("⚠️ Slow health check detected, increasing monitoring frequency"))
        else
            monitorInterval = math.min(300, monitorInterval * 1.1) -- Less frequent when fast (up to 5 min)
        end
        
        print(string.format("🏥 MainGameService health check completed (%.2fs, next in %.0fs)", 
            checkTime, monitorInterval))
    end)
    
    -- Start event-driven monitoring
    scheduleHealthCheck()
    print("✅ MainGameService health monitoring converted to event-driven system (NO POLLING)")
end

function MainGameService:PerformHealthCheck()
    local healthData = {
        timestamp = tick(),
        state = self.State,
        activeGames = {},
        serviceHealth = {},
        systemIntegrity = {}
    }
    
    -- Check active games
    for gameId, session in pairs(self.ActiveGames) do
        table.insert(healthData.activeGames, {
            gameId = gameId,
            duration = session.startTime and (tick() - session.startTime) or 0,
            playerName = session.player and session.player.Name or "Unknown"
        })
    end
    
    -- Check service health
    for serviceName, service in pairs(self.Services) do
        healthData.serviceHealth[serviceName] = service ~= nil
    end
    
    for controllerName, controller in pairs(self.Controllers) do
        healthData.serviceHealth[controllerName] = controller ~= nil
    end
    
    -- Validate system integrity if enabled
    if SERVICE_CONFIG.validateWorldObjects and WorldObjectValidator then
        local isValid, issues = pcall(function()
            return WorldObjectValidator.validateAllRequired()
        end)
        
        if isValid and #issues == 0 then
            healthData.systemIntegrity.worldObjects = "Valid"
        else
            healthData.systemIntegrity.worldObjects = "Issues: " .. #issues
            if SERVICE_CONFIG.enableDetailedLogging then
                warn("⚠️ World object validation issues detected during health check")
            end
        end
    end
    
    -- Track health analytics
    if self.Services.AnalyticsService then
        self.Services.AnalyticsService:TrackEvent(nil, "system_health_check", healthData)
    end
    
    if SERVICE_CONFIG.enableDetailedLogging then
        print("💓 Health check complete - State: " .. self.State .. ", Active games: " .. #healthData.activeGames)
        
        if SERVICE_CONFIG.enableDeveloperMode then
            print("🔍 System integrity: " .. (healthData.systemIntegrity.worldObjects or "Not checked"))
        end
    end
end

function MainGameService:SetupGameStateTracking()
    -- Track game state changes for analytics - FULLY EVENT-DRIVEN (NO POLLING)
    local previousState = self.State
    
    -- Create state change signal that only fires when state actually changes
    local stateChangeSignal = Instance.new("BindableEvent")
    
    -- Override SetGameState to trigger analytics immediately on state changes
    local originalSetGameState = self.SetGameState
    self.SetGameState = function(self, newState, data)
        local oldState = self.State
        originalSetGameState(self, newState, data)
        
        -- Fire state change event only when state actually changes
        if oldState ~= newState then
            stateChangeSignal:Fire(oldState, newState)
        end
    end
    
    -- Event-driven analytics tracking (only when states change)
    stateChangeSignal.Event:Connect(function(fromState, toState)
        if self.Services.AnalyticsService then
            self.Services.AnalyticsService:TrackEvent(nil, "internal_state_change", {
                from = fromState,
                to = toState,
                timestamp = tick()
            })
        end
        previousState = toState
    end)
    
    print("✅ Game state tracking converted to 100% event-driven (NO POLLING LOOPS)")
end

-- ========================================
-- GLOBAL ACCESSORS
-- ========================================

function MainGameService:SetupGlobalAccessors()
    -- Main service accessor
    _G.GetMainGameService = function()
        return MainGameService
    end
    
    -- Individual service accessors
    _G.GetGameService = function()
        return MainGameService.Services.GameService
    end
    
    _G.GetAnalyticsService = function()
        return MainGameService.Services.AnalyticsService
    end
    
    _G.GetTrackGeneratorService = function()
        return MainGameService.Services.TrackGeneratorService
    end
    
    _G.GetDifficultyService = function()
        return MainGameService.Services.DifficultyService
    end
    
    _G.GetMainGameController = function()
        return MainGameService.Controllers.MainGameController
    end
    
    _G.GetCollisionController = function()
        return MainGameService.Controllers.CollisionController
    end
    
    _G.GetRecordingSessionManager = function()
        return MainGameService.Services.RecordingSessionManager
    end
    
    -- Direct game control functions
    _G.StartGame = function(player, config)
        return MainGameService:StartGame(player, config)
    end
    
    _G.EndGame = function(player, results)
        return MainGameService:EndGame(player, results)
    end
    
    _G.GetGameState = function()
        return MainGameService.State
    end
end

-- ========================================
-- UTILITY METHODS
-- ========================================

function MainGameService:GetCurrentState()
    return self.State
end

function MainGameService:GetActiveGames()
    return self.ActiveGames
end

function MainGameService:GetServices()
    return self.Services
end

function MainGameService:GetControllers()
    return self.Controllers
end

function MainGameService:IsInitialized()
    return isInitialized
end

function MainGameService:IsStarted()
    return isStarted
end

function MainGameService:Shutdown()
    print("🔌 Shutting down MainGameService...")
    
    -- Disconnect all events
    for connectionName, connection in pairs(self.EventConnections) do
        if connection and connection.Disconnect then
            connection:Disconnect()
        end
    end
    
    -- Reset flags
    isStarted = false
    isInitialized = false
    
    print("✅ MainGameService shutdown complete")
end

-- ========================================
-- AUTO-INITIALIZATION AND GLOBAL REGISTRATION
-- ========================================

-- Auto-initialize when required
if RunService:IsServer() then
    task.spawn(function() -- UPDATED for modern API
        task.wait(2) -- UPDATED for modern API - Brief delay to ensure other systems are ready
        
        print("🚀 Auto-initializing Enhanced MainGameService...")
        
        if MainGameService:Init() then
            print("🎮 Enhanced MainGameService initialized successfully")
            
            -- Register with global service system if available
            if _G.RegisterCoreService then
                _G.RegisterCoreService("MainGameService", MainGameService)
                print("📍 MainGameService registered globally")
            end
            
            -- Perform initial system validation
            if SERVICE_CONFIG.validateWorldObjects then
                task.spawn(function() -- UPDATED for modern API
                    task.wait(1) -- UPDATED for modern API
                    MainGameService:ValidateAndRepairSystem()
                end)
            end
            
        else
            warn("❌ Enhanced MainGameService initialization failed")
        end
    end)
end

return MainGameService
