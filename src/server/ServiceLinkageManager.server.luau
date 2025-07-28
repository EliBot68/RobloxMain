-- ServiceLinkageManager.server.luau
-- Manages bi-directional service connections and communication
-- Handles MainGameController linkage to TrackGeneratorService and CollisionController

local ServiceLinkageManager = {}

-- Connection registry
local ServiceConnections = {}
local LinkageStatus = {}

-- Configuration
local LINKAGE_CONFIG = {
    enableDetailedLogging = true,
    enableBidirectionalComm = true,
    retryFailedLinks = true,
    linkTimeout = 10,
    healthCheckInterval = 30
}

function ServiceLinkageManager:Initialize()
    print("🔗 Initializing Service Linkage Manager...")
    
    -- Wait for core services
    local coreServices = self:WaitForCoreServices()
    if not coreServices then
        warn("❌ Core services not available for linkage")
        return false
    end
    
    -- Setup all service linkages
    self:LinkMainControllerToTrackGenerator()
    self:LinkMainControllerToCollisionController()
    self:LinkCollisionControllerToTrackGenerator()
    self:LinkAllServicesToAnalytics()
    self:LinkServicesToGameService()
    
    -- Start health monitoring
    self:StartHealthMonitoring()
    
    print("✅ Service Linkage Manager initialized successfully")
    return true
end

function ServiceLinkageManager:WaitForCoreServices(timeout)
    timeout = timeout or LINKAGE_CONFIG.linkTimeout
    local startTime = tick()
    
    while tick() - startTime < timeout do
        if _G.CoreServices and _G.GetMainGameController and _G.GetTrackGeneratorService and _G.GetCollisionController then
            return true
        end
        wait(0.1)
    end
    
    return false
end

-- ========================================
-- MAIN CONTROLLER TO TRACK GENERATOR LINKAGE
-- ========================================

function ServiceLinkageManager:LinkMainControllerToTrackGenerator()
    print("🛤️ Linking MainGameController ↔ TrackGeneratorService...")
    
    local mainController = _G.GetMainGameController()
    local trackGenerator = _G.GetTrackGeneratorService()
    
    if not mainController or not trackGenerator then
        warn("❌ Cannot link MainController to TrackGenerator - services missing")
        LinkageStatus.MainControllerToTrackGenerator = false
        return false
    end
    
    -- Set service references
    self:SetServiceReferences(mainController, trackGenerator, "TrackGenerator")
    
    -- Setup bi-directional communication
    self:SetupTrackGenerationCommunication(mainController, trackGenerator)
    
    -- Setup event bindings
    self:SetupTrackGenerationEvents(mainController, trackGenerator)
    
    LinkageStatus.MainControllerToTrackGenerator = true
    print("✅ MainController ↔ TrackGenerator linkage complete")
    return true
end

function ServiceLinkageManager:SetupTrackGenerationCommunication(mainController, trackGenerator)
    -- MainController → TrackGenerator methods
    if not mainController.RequestTrackGeneration then
        mainController.RequestTrackGeneration = function(self, trackConfig)
            if LINKAGE_CONFIG.enableDetailedLogging then
                print("🛤️ MainController requesting track generation:", trackConfig.difficulty or "default")
            end
            
            return trackGenerator:GenerateTrack(trackConfig)
        end
    end
    
    if not mainController.GetCurrentTrack then
        mainController.GetCurrentTrack = function(self)
            return trackGenerator:GetCurrentTrack()
        end
    end
    
    if not mainController.ValidateTrack then
        mainController.ValidateTrack = function(self, trackData)
            return trackGenerator:ValidateTrack(trackData)
        end
    end
    
    -- TrackGenerator → MainController methods
    if not trackGenerator.NotifyTrackReady then
        trackGenerator.NotifyTrackReady = function(self, trackData)
            if LINKAGE_CONFIG.enableDetailedLogging then
                print("✅ TrackGenerator notifying MainController: track ready")
            end
            
            if mainController.OnTrackReady then
                mainController:OnTrackReady(trackData)
            end
        end
    end
    
    if not trackGenerator.NotifyTrackGenerationFailed then
        trackGenerator.NotifyTrackGenerationFailed = function(self, error)
            if mainController.OnTrackGenerationFailed then
                mainController:OnTrackGenerationFailed(error)
            end
        end
    end
    
    if LINKAGE_CONFIG.enableDetailedLogging then
        print("📞 Track generation communication methods established")
    end
end

function ServiceLinkageManager:SetupTrackGenerationEvents(mainController, trackGenerator)
    -- Track generation request event
    if mainController.OnGameStartRequested and trackGenerator.GenerateTrack then
        ServiceConnections.TrackGenerationRequest = mainController.OnGameStartRequested:Connect(function(player, gameConfig)
            if LINKAGE_CONFIG.enableDetailedLogging then
                print("🎮 Game start requested - generating track for:", player.Name)
            end
            
            local trackConfig = {
                difficulty = gameConfig.difficulty or 1,
                length = gameConfig.trackLength or 100,
                playerCount = gameConfig.playerCount or 1,
                theme = gameConfig.theme or "default"
            }
            
            trackGenerator:GenerateTrack(trackConfig)
        end)
    end
    
    -- Track completion event
    if trackGenerator.OnTrackGenerated and mainController.HandleTrackGenerated then
        ServiceConnections.TrackGenerated = trackGenerator.OnTrackGenerated:Connect(function(trackData)
            if LINKAGE_CONFIG.enableDetailedLogging then
                print("🛤️ Track generated - notifying MainController")
            end
            
            mainController:HandleTrackGenerated(trackData)
        end)
    end
    
    if LINKAGE_CONFIG.enableDetailedLogging then
        print("🔔 Track generation events connected")
    end
end

-- ========================================
-- MAIN CONTROLLER TO COLLISION CONTROLLER LINKAGE
-- ========================================

function ServiceLinkageManager:LinkMainControllerToCollisionController()
    print("💥 Linking MainGameController ↔ CollisionController...")
    
    local mainController = _G.GetMainGameController()
    local collisionController = _G.GetCollisionController()
    
    if not mainController or not collisionController then
        warn("❌ Cannot link MainController to CollisionController - services missing")
        LinkageStatus.MainControllerToCollisionController = false
        return false
    end
    
    -- Set service references
    self:SetServiceReferences(mainController, collisionController, "CollisionController")
    self:SetServiceReferences(collisionController, mainController, "MainController")
    
    -- Setup bi-directional communication
    self:SetupCollisionCommunication(mainController, collisionController)
    
    -- Setup collision event bindings
    self:SetupCollisionEvents(mainController, collisionController)
    
    LinkageStatus.MainControllerToCollisionController = true
    print("✅ MainController ↔ CollisionController linkage complete")
    return true
end

function ServiceLinkageManager:SetupCollisionCommunication(mainController, collisionController)
    -- MainController → CollisionController methods
    if not mainController.EnableCollisionDetection then
        mainController.EnableCollisionDetection = function(self, player)
            if LINKAGE_CONFIG.enableDetailedLogging then
                print("🛡️ MainController enabling collision for:", player.Name)
            end
            
            return collisionController:EnablePlayerCollision(player)
        end
    end
    
    if not mainController.DisableCollisionDetection then
        mainController.DisableCollisionDetection = function(self, player)
            return collisionController:DisablePlayerCollision(player)
        end
    end
    
    if not mainController.SetCollisionMode then
        mainController.SetCollisionMode = function(self, mode)
            if collisionController.SetCollisionMode then
                collisionController:SetCollisionMode(mode)
            end
        end
    end
    
    -- CollisionController → MainController methods
    if not collisionController.NotifyPlayerCollision then
        collisionController.NotifyPlayerCollision = function(self, player, collisionData)
            if LINKAGE_CONFIG.enableDetailedLogging then
                print("💥 CollisionController notifying MainController: player collision")
            end
            
            if mainController.HandlePlayerCollision then
                mainController:HandlePlayerCollision(player, collisionData)
            end
        end
    end
    
    if not collisionController.NotifyPlayerDeath then
        collisionController.NotifyPlayerDeath = function(self, player, deathData)
            if LINKAGE_CONFIG.enableDetailedLogging then
                print("💀 CollisionController notifying MainController: player death")
            end
            
            if mainController.HandlePlayerDeath then
                mainController:HandlePlayerDeath(player, deathData)
            end
        end
    end
    
    if not collisionController.NotifyGameStateChange then
        collisionController.NotifyGameStateChange = function(self, newState, data)
            if mainController.HandleGameStateChange then
                mainController:HandleGameStateChange(nil, newState, data)
            end
        end
    end
    
    if LINKAGE_CONFIG.enableDetailedLogging then
        print("📞 Collision communication methods established")
    end
end

function ServiceLinkageManager:SetupCollisionEvents(mainController, collisionController)
    -- Player collision events
    if collisionController.OnPlayerCollision and mainController.HandlePlayerCollision then
        ServiceConnections.PlayerCollision = collisionController.OnPlayerCollision:Connect(function(player, collisionData)
            if LINKAGE_CONFIG.enableDetailedLogging then
                print("💥 Player collision detected:", player.Name)
            end
            
            mainController:HandlePlayerCollision(player, collisionData)
        end)
    end
    
    -- Player death events
    if collisionController.OnPlayerDeath and mainController.HandlePlayerDeath then
        ServiceConnections.PlayerDeath = collisionController.OnPlayerDeath:Connect(function(player, deathData)
            if LINKAGE_CONFIG.enableDetailedLogging then
                print("💀 Player death detected:", player.Name)
            end
            
            mainController:HandlePlayerDeath(player, deathData)
        end)
    end
    
    -- Obstacle collision events
    if collisionController.OnObstacleCollision and mainController.HandleObstacleCollision then
        ServiceConnections.ObstacleCollision = collisionController.OnObstacleCollision:Connect(function(player, obstacleData)
            mainController:HandleObstacleCollision(player, obstacleData)
        end)
    end
    
    -- Game state change requests from collision system
    if mainController.OnGameStateChangeRequested and collisionController.RequestGameStateChange then
        ServiceConnections.GameStateChangeRequest = mainController.OnGameStateChangeRequested:Connect(function(newState, data)
            collisionController:RequestGameStateChange(newState, data)
        end)
    end
    
    if LINKAGE_CONFIG.enableDetailedLogging then
        print("🔔 Collision events connected")
    end
end

-- ========================================
-- ADDITIONAL SERVICE LINKAGES
-- ========================================

function ServiceLinkageManager:LinkCollisionControllerToTrackGenerator()
    local collisionController = _G.GetCollisionController()
    local trackGenerator = _G.GetTrackGeneratorService()
    
    if not collisionController or not trackGenerator then
        warn("⚠️ Cannot link CollisionController to TrackGenerator - services missing")
        return false
    end
    
    if LINKAGE_CONFIG.enableDetailedLogging then
        print("🔗 Linking CollisionController ↔ TrackGenerator")
    end
    
    -- Set references
    self:SetServiceReferences(collisionController, trackGenerator, "TrackGenerator")
    
    -- Setup track-based collision configuration
    if not collisionController.ConfigureForTrack then
        collisionController.ConfigureForTrack = function(self, trackData)
            if trackData.obstacles then
                self:SetObstacles(trackData.obstacles)
            end
            if trackData.collisionSettings then
                self:ApplyCollisionSettings(trackData.collisionSettings)
            end
        end
    end
    
    LinkageStatus.CollisionControllerToTrackGenerator = true
    print("✅ CollisionController ↔ TrackGenerator linkage complete")
    return true
end

function ServiceLinkageManager:LinkAllServicesToAnalytics()
    local analyticsService = _G.GetAnalyticsService()
    if not analyticsService then
        warn("⚠️ AnalyticsService not available for linkage")
        return false
    end
    
    if LINKAGE_CONFIG.enableDetailedLogging then
        print("📊 Linking all services to AnalyticsService")
    end
    
    local services = {
        _G.GetMainGameController(),
        _G.GetCollisionController(),
        _G.GetTrackGeneratorService(),
        _G.GetDifficultyService(),
        _G.GetRecordingSessionManager()
    }
    
    for _, service in ipairs(services) do
        if service then
            self:SetServiceReferences(service, analyticsService, "AnalyticsService")
        end
    end
    
    LinkageStatus.AllServicesToAnalytics = true
    print("✅ All services linked to Analytics")
    return true
end

function ServiceLinkageManager:LinkServicesToGameService()
    local gameService = _G.GetGameService()
    if not gameService then
        warn("⚠️ GameService not available for linkage")
        return false
    end
    
    if LINKAGE_CONFIG.enableDetailedLogging then
        print("🎮 Linking all services to GameService")
    end
    
    local services = {
        _G.GetMainGameController(),
        _G.GetCollisionController(),
        _G.GetTrackGeneratorService(),
        _G.GetDifficultyService()
    }
    
    for _, service in ipairs(services) do
        if service then
            self:SetServiceReferences(service, gameService, "GameService")
        end
    end
    
    LinkageStatus.AllServicesToGameService = true
    print("✅ All services linked to GameService")
    return true
end

-- ========================================
-- UTILITY METHODS
-- ========================================

function ServiceLinkageManager:SetServiceReferences(sourceService, targetService, targetName)
    if not sourceService or not targetService then return end
    
    -- Set direct reference
    sourceService[targetName] = targetService
    
    -- Set getter method
    local getterName = "Get" .. targetName
    if not sourceService[getterName] then
        sourceService[getterName] = function()
            return targetService
        end
    end
    
    -- Set setter method for dynamic updates
    local setterName = "Set" .. targetName
    if not sourceService[setterName] then
        sourceService[setterName] = function(self, newService)
            self[targetName] = newService
        end
    end
    
    if LINKAGE_CONFIG.enableDetailedLogging then
        print("🔗 Reference set: " .. (sourceService.Name or "Service") .. " → " .. targetName)
    end
end

-- ========================================
-- HEALTH MONITORING
-- ========================================

function ServiceLinkageManager:StartHealthMonitoring()
    if LINKAGE_CONFIG.healthCheckInterval <= 0 then return end
    
    spawn(function()
        while true do
            wait(LINKAGE_CONFIG.healthCheckInterval)
            self:PerformHealthCheck()
        end
    end)
end

function ServiceLinkageManager:PerformHealthCheck()
    local healthStatus = {
        timestamp = tick(),
        linkages = {},
        issues = {}
    }
    
    -- Check each linkage status
    for linkageName, status in pairs(LinkageStatus) do
        healthStatus.linkages[linkageName] = status
        
        if not status then
            table.insert(healthStatus.issues, "Failed linkage: " .. linkageName)
        end
    end
    
    -- Check service availability
    local coreServices = {
        "MainGameController",
        "TrackGeneratorService", 
        "CollisionController",
        "GameService",
        "AnalyticsService"
    }
    
    for _, serviceName in ipairs(coreServices) do
        local service = _G["Get" .. serviceName] and _G["Get" .. serviceName]()
        if not service then
            table.insert(healthStatus.issues, "Missing service: " .. serviceName)
        end
    end
    
    -- Log health status
    if #healthStatus.issues > 0 then
        warn("⚠️ Service linkage health issues detected:")
        for _, issue in ipairs(healthStatus.issues) do
            warn("  - " .. issue)
        end
    else
        if LINKAGE_CONFIG.enableDetailedLogging then
            print("✅ Service linkage health check passed")
        end
    end
    
    return healthStatus
end

-- ========================================
-- MANAGEMENT METHODS
-- ========================================

function ServiceLinkageManager:GetLinkageStatus()
    return LinkageStatus
end

function ServiceLinkageManager:DisconnectAll()
    print("🔌 Disconnecting all service linkages...")
    
    for name, connection in pairs(ServiceConnections) do
        if connection and connection.Disconnect then
            connection:Disconnect()
        end
    end
    
    ServiceConnections = {}
    LinkageStatus = {}
    
    print("✅ All service linkages disconnected")
end

function ServiceLinkageManager:ReinitializeLinkage(linkageName)
    if linkageName == "MainControllerToTrackGenerator" then
        return self:LinkMainControllerToTrackGenerator()
    elseif linkageName == "MainControllerToCollisionController" then
        return self:LinkMainControllerToCollisionController()
    elseif linkageName == "CollisionControllerToTrackGenerator" then
        return self:LinkCollisionControllerToTrackGenerator()
    else
        warn("❌ Unknown linkage name: " .. linkageName)
        return false
    end
end

-- Auto-initialize when core services are ready
spawn(function()
    wait(5) -- Wait for core services and other connections
    ServiceLinkageManager:Initialize()
end)

return ServiceLinkageManager
