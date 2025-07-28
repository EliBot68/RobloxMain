-- SystemEventConnections.server.luau
-- Comprehensive event connections and system bindings
-- Handles all inter-service communication and event routing

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local SystemEventConnections = {}

-- Event connection registry
local EventConnections = {}
local ServiceBindings = {}
local PlayerEventHandlers = {}

-- Configuration
local CONNECTION_CONFIG = {
    enableDetailedLogging = true,
    enablePlayerSpawnLogging = true,
    enableServiceBindingLogging = true,
    retryFailedConnections = true,
    connectionTimeout = 10
}

function SystemEventConnections:Initialize()
    print("🔗 Initializing System Event Connections...")
    
    -- Wait for core services to be available
    local coreServices = self:WaitForCoreServices()
    if not coreServices then
        warn("❌ Core services not available - cannot setup connections")
        return false
    end
    
    -- Setup all event connections
    self:SetupPlayerEventConnections()
    self:SetupServiceBindings()
    self:SetupGameStateConnections()
    self:SetupCollisionEventConnections()
    self:SetupTrackGenerationConnections()
    self:SetupAnalyticsConnections()
    self:SetupRecordingConnections()
    
    print("✅ System Event Connections initialized successfully")
    return true
end

function SystemEventConnections:WaitForCoreServices(timeout)
    timeout = timeout or CONNECTION_CONFIG.connectionTimeout
    local startTime = tick()
    
    while tick() - startTime < timeout do
        if _G.CoreServices and _G.GetMainGameController then
            return _G.CoreServices
        end
        wait(0.1)
    end
    
    return nil
end

-- ========================================
-- PLAYER EVENT CONNECTIONS
-- ========================================

function SystemEventConnections:SetupPlayerEventConnections()
    print("👥 Setting up Player Event Connections...")
    
    -- Player Added Event
    EventConnections.PlayerAdded = Players.PlayerAdded:Connect(function(player)
        self:HandlePlayerAdded(player)
    end)
    
    -- Player Removing Event
    EventConnections.PlayerRemoving = Players.PlayerRemoving:Connect(function(player)
        self:HandlePlayerRemoving(player)
    end)
    
    -- Handle existing players
    for _, player in pairs(Players:GetPlayers()) do
        spawn(function()
            self:HandlePlayerAdded(player)
        end)
    end
    
    print("✅ Player event connections established")
end

function SystemEventConnections:HandlePlayerAdded(player)
    if CONNECTION_CONFIG.enablePlayerSpawnLogging then
        print("👋 Processing player join: " .. player.Name)
    end
    
    -- Setup player spawn logic through services
    self:SetupPlayerSpawnLogic(player)
    
    -- Notify all core services
    self:NotifyServicesPlayerAdded(player)
    
    -- Setup player-specific event handlers
    self:SetupPlayerSpecificHandlers(player)
    
    -- Setup character spawn handling
    self:SetupCharacterSpawnHandling(player)
end

function SystemEventConnections:SetupPlayerSpawnLogic(player)
    local mainController = _G.GetMainGameController()
    local gameService = _G.GetGameService()
    
    if CONNECTION_CONFIG.enablePlayerSpawnLogging then
        print("🎮 Setting up spawn logic for: " .. player.Name)
    end
    
    -- Connect to MainGameController spawn logic
    if mainController then
        if mainController.OnPlayerAdded then
            mainController:OnPlayerAdded(player)
        end
        
        if mainController.SetupPlayer then
            mainController:SetupPlayer(player)
        end
        
        if mainController.PreparePlayerForGame then
            mainController:PreparePlayerForGame(player)
        end
    end
    
    -- Connect to GameService spawn logic
    if gameService then
        if gameService.OnPlayerAdded then
            gameService:OnPlayerAdded(player)
        end
        
        if gameService.CreatePlayerSession then
            gameService:CreatePlayerSession(player)
        end
    end
    
    -- Track spawn analytics
    local analyticsService = _G.GetAnalyticsService()
    if analyticsService then
        analyticsService:TrackEvent(player, "player_spawn_setup", {
            timestamp = tick(),
            playerName = player.Name,
            userId = player.UserId
        })
    end
end

function SystemEventConnections:SetupCharacterSpawnHandling(player)
    -- Handle character spawning
    player.CharacterAdded:Connect(function(character)
        self:HandleCharacterSpawned(player, character)
    end)
    
    -- Handle existing character
    if player.Character then
        spawn(function()
            self:HandleCharacterSpawned(player, player.Character)
        end)
    end
end

function SystemEventConnections:HandleCharacterSpawned(player, character)
    if CONNECTION_CONFIG.enablePlayerSpawnLogging then
        print("👨‍🎮 Character spawned for: " .. player.Name)
    end
    
    -- Wait for character to fully load
    local humanoid = character:WaitForChild("Humanoid", 5)
    local humanoidRootPart = character:WaitForChild("HumanoidRootPart", 5)
    
    if not humanoid or not humanoidRootPart then
        warn("❌ Character components missing for: " .. player.Name)
        return
    end
    
    -- Notify services about character spawn
    local mainController = _G.GetMainGameController()
    if mainController and mainController.OnPlayerCharacterAdded then
        mainController:OnPlayerCharacterAdded(player, character)
    end
    
    local collisionController = _G.GetCollisionController()
    if collisionController and collisionController.SetupPlayerForCollision then
        collisionController:SetupPlayerForCollision(player, character)
    end
    
    local recordingManager = _G.GetRecordingSessionManager()
    if recordingManager and recordingManager.SetupPlayerForRecording then
        recordingManager:SetupPlayerForRecording(player)
    end
    
    -- Track character spawn analytics
    local analyticsService = _G.GetAnalyticsService()
    if analyticsService then
        analyticsService:TrackEvent(player, "character_spawned", {
            timestamp = tick(),
            characterName = character.Name,
            spawnPosition = humanoidRootPart.Position
        })
    end
end

function SystemEventConnections:NotifyServicesPlayerAdded(player)
    local services = {
        {"GameService", "OnPlayerAdded"},
        {"MainGameController", "OnPlayerAdded"},
        {"AnalyticsService", "TrackPlayerJoin"},
        {"CollisionController", "OnPlayerAdded"},
        {"DifficultyService", "OnPlayerAdded"},
        {"RecordingSessionManager", "SetupPlayerForRecording"}
    }
    
    for _, serviceInfo in ipairs(services) do
        local serviceName, methodName = serviceInfo[1], serviceInfo[2]
        local service = _G.GetCoreService(serviceName)
        
        if service and service[methodName] then
            local success, error = pcall(function()
                service[methodName](service, player)
            end)
            
            if not success then
                warn("❌ Failed to notify " .. serviceName .. " of player join: " .. tostring(error))
            end
        end
    end
end

function SystemEventConnections:HandlePlayerRemoving(player)
    if CONNECTION_CONFIG.enablePlayerSpawnLogging then
        print("👋 Processing player leave: " .. player.Name)
    end
    
    -- Notify all services
    self:NotifyServicesPlayerRemoving(player)
    
    -- Cleanup player-specific handlers
    self:CleanupPlayerHandlers(player)
end

function SystemEventConnections:NotifyServicesPlayerRemoving(player)
    local services = {
        {"GameService", "OnPlayerRemoving"},
        {"MainGameController", "OnPlayerRemoving"},
        {"AnalyticsService", "TrackPlayerLeave"},
        {"CollisionController", "OnPlayerRemoving"},
        {"DifficultyService", "OnPlayerRemoving"},
        {"RecordingSessionManager", "CleanupPlayerRecording"}
    }
    
    for _, serviceInfo in ipairs(services) do
        local serviceName, methodName = serviceInfo[1], serviceInfo[2]
        local service = _G.GetCoreService(serviceName)
        
        if service and service[methodName] then
            local success, error = pcall(function()
                service[methodName](service, player)
            end)
            
            if not success then
                warn("❌ Failed to notify " .. serviceName .. " of player leave: " .. tostring(error))
            end
        end
    end
end

-- ========================================
-- SERVICE BINDINGS
-- ========================================

function SystemEventConnections:SetupServiceBindings()
    print("🔗 Setting up Service Bindings...")
    
    -- Link MainGameController to TrackGeneratorService
    self:LinkMainControllerToTrackGenerator()
    
    -- Link MainGameController to CollisionController
    self:LinkMainControllerToCollisionController()
    
    -- Link CollisionController to AnalyticsService
    self:LinkCollisionControllerToAnalytics()
    
    -- Link GameService to all dependent services
    self:LinkGameServiceToOthers()
    
    print("✅ Service bindings established")
end

function SystemEventConnections:LinkMainControllerToTrackGenerator()
    local mainController = _G.GetMainGameController()
    local trackGenerator = _G.GetTrackGeneratorService()
    
    if not mainController or not trackGenerator then
        warn("⚠️ Cannot link MainController to TrackGenerator - services missing")
        return
    end
    
    if CONNECTION_CONFIG.enableServiceBindingLogging then
        print("🔗 Linking MainGameController → TrackGeneratorService")
    end
    
    -- Set TrackGenerator reference in MainController
    if mainController.SetTrackGeneratorService then
        mainController:SetTrackGeneratorService(trackGenerator)
    end
    
    -- Set MainController reference in TrackGenerator
    if trackGenerator.SetMainController then
        trackGenerator:SetMainController(mainController)
    end
    
    -- Connect track generation events
    if mainController.OnTrackGenerationRequested and trackGenerator.OnTrackGenerated then
        ServiceBindings.TrackGeneration = mainController.OnTrackGenerationRequested:Connect(function(trackConfig)
            trackGenerator:GenerateTrack(trackConfig)
        end)
    end
    
    print("✅ MainController ↔ TrackGenerator binding complete")
end

function SystemEventConnections:LinkMainControllerToCollisionController()
    local mainController = _G.GetMainGameController()
    local collisionController = _G.GetCollisionController()
    
    if not mainController or not collisionController then
        warn("⚠️ Cannot link MainController to CollisionController - services missing")
        return
    end
    
    if CONNECTION_CONFIG.enableServiceBindingLogging then
        print("🔗 Linking MainGameController → CollisionController")
    end
    
    -- Set MainController reference in CollisionController
    if collisionController.SetMainController then
        collisionController:SetMainController(mainController)
    end
    
    -- Set CollisionController reference in MainController
    if mainController.SetCollisionController then
        mainController:SetCollisionController(collisionController)
    end
    
    -- Connect collision events to game state changes
    if collisionController.OnPlayerCollision and mainController.HandlePlayerCollision then
        ServiceBindings.PlayerCollision = collisionController.OnPlayerCollision:Connect(function(player, collisionData)
            mainController:HandlePlayerCollision(player, collisionData)
        end)
    end
    
    if collisionController.OnPlayerDeath and mainController.HandlePlayerDeath then
        ServiceBindings.PlayerDeath = collisionController.OnPlayerDeath:Connect(function(player, deathData)
            mainController:HandlePlayerDeath(player, deathData)
        end)
    end
    
    print("✅ MainController ↔ CollisionController binding complete")
end

function SystemEventConnections:LinkCollisionControllerToAnalytics()
    local collisionController = _G.GetCollisionController()
    local analyticsService = _G.GetAnalyticsService()
    
    if not collisionController or not analyticsService then
        warn("⚠️ Cannot link CollisionController to Analytics - services missing")
        return
    end
    
    if CONNECTION_CONFIG.enableServiceBindingLogging then
        print("🔗 Linking CollisionController → AnalyticsService")
    end
    
    -- Set analytics reference in collision controller
    if collisionController.SetAnalyticsService then
        collisionController:SetAnalyticsService(analyticsService)
    end
    
    print("✅ CollisionController → Analytics binding complete")
end

function SystemEventConnections:LinkGameServiceToOthers()
    local gameService = _G.GetGameService()
    
    if not gameService then
        warn("⚠️ GameService not available for linking")
        return
    end
    
    if CONNECTION_CONFIG.enableServiceBindingLogging then
        print("🔗 Linking GameService to dependent services")
    end
    
    -- Link to MainController
    local mainController = _G.GetMainGameController()
    if mainController and mainController.SetGameService then
        mainController:SetGameService(gameService)
    end
    
    -- Link to CollisionController
    local collisionController = _G.GetCollisionController()
    if collisionController and collisionController.SetGameService then
        collisionController:SetGameService(gameService)
    end
    
    -- Link to DifficultyService
    local difficultyService = _G.GetDifficultyService()
    if difficultyService and difficultyService.SetGameService then
        difficultyService:SetGameService(gameService)
    end
    
    print("✅ GameService bindings complete")
end

-- ========================================
-- GAME STATE CONNECTIONS
-- ========================================

function SystemEventConnections:SetupGameStateConnections()
    print("🎮 Setting up Game State Connections...")
    
    local mainController = _G.GetMainGameController()
    if not mainController then
        warn("⚠️ MainGameController not available for game state connections")
        return
    end
    
    -- Connect to RemoteEvents for game state changes
    if _G.GetRemoteEvent then
        local gameStateEvent = _G.GetRemoteEvent("GameStateChange")
        if gameStateEvent then
            ServiceBindings.GameStateChange = gameStateEvent.OnServerEvent:Connect(function(player, newState, gameData)
                self:HandleGameStateChange(player, newState, gameData)
            end)
        end
        
        local scoreUpdateEvent = _G.GetRemoteEvent("ScoreUpdate")
        if scoreUpdateEvent then
            ServiceBindings.ScoreUpdate = scoreUpdateEvent.OnServerEvent:Connect(function(player, scoreData)
                self:HandleScoreUpdate(player, scoreData)
            end)
        end
    end
    
    print("✅ Game state connections established")
end

function SystemEventConnections:HandleGameStateChange(player, newState, gameData)
    if CONNECTION_CONFIG.enableDetailedLogging then
        print("🎮 Game state change: " .. player.Name .. " → " .. tostring(newState))
    end
    
    -- Notify all relevant services
    local services = {
        _G.GetMainGameController(),
        _G.GetGameService(),
        _G.GetAnalyticsService(),
        _G.GetDifficultyService(),
        _G.GetRecordingSessionManager()
    }
    
    for _, service in ipairs(services) do
        if service and service.HandleGameStateChange then
            pcall(function()
                service:HandleGameStateChange(player, newState, gameData)
            end)
        end
    end
end

function SystemEventConnections:HandleScoreUpdate(player, scoreData)
    if CONNECTION_CONFIG.enableDetailedLogging then
        print("📊 Score update: " .. player.Name .. " → " .. tostring(scoreData.score or 0))
    end
    
    -- Notify analytics
    local analyticsService = _G.GetAnalyticsService()
    if analyticsService then
        analyticsService:TrackEvent(player, "score_updated", scoreData)
    end
    
    -- Notify main controller
    local mainController = _G.GetMainGameController()
    if mainController and mainController.HandleScoreUpdate then
        mainController:HandleScoreUpdate(player, scoreData)
    end
end

-- ========================================
-- SPECIALIZED CONNECTIONS
-- ========================================

function SystemEventConnections:SetupCollisionEventConnections()
    print("💥 Setting up Collision Event Connections...")
    
    local collisionController = _G.GetCollisionController()
    if not collisionController then
        warn("⚠️ CollisionController not available")
        return
    end
    
    -- Connect obstacle hit events
    if _G.GetRemoteEvent then
        local obstacleHitEvent = _G.GetRemoteEvent("ObstacleHit")
        if obstacleHitEvent then
            ServiceBindings.ObstacleHit = obstacleHitEvent.OnServerEvent:Connect(function(player, obstacleData)
                if collisionController.HandleObstacleHit then
                    collisionController:HandleObstacleHit(player, obstacleData)
                end
            end)
        end
    end
    
    print("✅ Collision event connections established")
end

function SystemEventConnections:SetupTrackGenerationConnections()
    print("🛤️ Setting up Track Generation Connections...")
    
    local trackGenerator = _G.GetTrackGeneratorService()
    if not trackGenerator then
        warn("⚠️ TrackGeneratorService not available")
        return
    end
    
    -- Connect track generation to main controller
    local mainController = _G.GetMainGameController()
    if mainController then
        -- Connect track generation completion
        if trackGenerator.OnTrackGenerated and mainController.HandleTrackGenerated then
            ServiceBindings.TrackGenerated = trackGenerator.OnTrackGenerated:Connect(function(trackData)
                mainController:HandleTrackGenerated(trackData)
            end)
        end
    end
    
    print("✅ Track generation connections established")
end

function SystemEventConnections:SetupAnalyticsConnections()
    print("📊 Setting up Analytics Connections...")
    
    local analyticsService = _G.GetAnalyticsService()
    if not analyticsService then
        warn("⚠️ AnalyticsService not available")
        return
    end
    
    -- Connect analytics to all major events
    -- This is handled through direct service calls rather than events
    
    print("✅ Analytics connections established")
end

function SystemEventConnections:SetupRecordingConnections()
    print("🎬 Setting up Recording Connections...")
    
    local recordingManager = _G.GetRecordingSessionManager()
    if not recordingManager then
        warn("⚠️ RecordingSessionManager not available")
        return
    end
    
    -- Recording connections are handled through MainGameController integration
    
    print("✅ Recording connections established")
end

-- ========================================
-- CLEANUP AND MANAGEMENT
-- ========================================

function SystemEventConnections:SetupPlayerSpecificHandlers(player)
    if not PlayerEventHandlers[player.UserId] then
        PlayerEventHandlers[player.UserId] = {}
    end
    
    -- Add any player-specific event handlers here
end

function SystemEventConnections:CleanupPlayerHandlers(player)
    local handlers = PlayerEventHandlers[player.UserId]
    if handlers then
        for _, connection in pairs(handlers) do
            if connection and connection.Disconnect then
                connection:Disconnect()
            end
        end
        PlayerEventHandlers[player.UserId] = nil
    end
end

function SystemEventConnections:DisconnectAll()
    print("🔌 Disconnecting all system event connections...")
    
    -- Disconnect main event connections
    for name, connection in pairs(EventConnections) do
        if connection and connection.Disconnect then
            connection:Disconnect()
        end
    end
    
    -- Disconnect service bindings
    for name, connection in pairs(ServiceBindings) do
        if connection and connection.Disconnect then
            connection:Disconnect()
        end
    end
    
    -- Cleanup player handlers
    for userId, handlers in pairs(PlayerEventHandlers) do
        for _, connection in pairs(handlers) do
            if connection and connection.Disconnect then
                connection:Disconnect()
            end
        end
    end
    
    -- Clear all registries
    EventConnections = {}
    ServiceBindings = {}
    PlayerEventHandlers = {}
    
    print("✅ All connections disconnected")
end

function SystemEventConnections:GetConnectionStatus()
    local status = {
        eventConnections = {},
        serviceBindings = {},
        playerHandlers = {}
    }
    
    for name, connection in pairs(EventConnections) do
        status.eventConnections[name] = connection ~= nil
    end
    
    for name, connection in pairs(ServiceBindings) do
        status.serviceBindings[name] = connection ~= nil
    end
    
    for userId, handlers in pairs(PlayerEventHandlers) do
        status.playerHandlers[userId] = #handlers
    end
    
    return status
end

-- Auto-initialize when script loads
spawn(function()
    wait(3) -- Wait for core services to load
    SystemEventConnections:Initialize()
end)

-- Global accessor
_G.GetSystemEventConnections = function()
    return SystemEventConnections
end

return SystemEventConnections
