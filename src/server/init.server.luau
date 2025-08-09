-- EnterpriseServerInitialization.server.luau
-- Next-generation server initialization with enterprise-level service orchestration
-- Provides comprehensive startup, dependency management, and system integration

print("🏢 Enterprise Color Rush Server starting...")

-- Core Roblox Services
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local RunService = game:GetService("RunService")

-- ========================================
-- ENTERPRISE INITIALIZATION FRAMEWORK
-- ========================================

local EnterpriseInit = {}
local services = {}
local serviceHealth = {}
local initializationMetrics = {
    startTime = tick(),
    servicesLoaded = 0,
    totalServices = 0,
    failedServices = 0,
    initializationTime = 0
}

-- Wait for shared modules to load
local SharedFolder = ReplicatedStorage:WaitForChild("Shared", 10)
if not SharedFolder then
    error("Failed to load shared modules!")
end

-- Load enterprise architecture
local EnterpriseServiceArchitecture = require(SharedFolder.core.EnterpriseServiceArchitecture)
local ServiceContainer = _G.EnterpriseServices

print("✅ Enterprise architecture loaded")

-- ========================================
-- SERVICE REGISTRATION
-- ========================================

-- Register enterprise core services
ServiceContainer:RegisterService("EnterpriseDataService", function(deps)
    return require(SharedFolder.core.EnterpriseDataService).new(deps)
end, {
    priority = 1, -- Critical priority
    dependencies = {},
    autoStart = true,
    enableCircuitBreaker = true,
    enableCaching = true
})

ServiceContainer:RegisterService("EnterpriseAnalyticsService", function(deps)
    return require(ServerScriptService.Server.services.Analytics.EnterpriseAnalyticsService).new(deps)
end, {
    priority = 1, -- Critical priority  
    dependencies = {"EnterpriseDataService"},
    autoStart = true,
    enableCircuitBreaker = true,
    enableRateLimiting = true
})

ServiceContainer:RegisterService("EnterprisePlayerService", function(deps)
    return require(ServerScriptService.Server.services.EnterprisePlayerService).new(deps)
end, {
    priority = 1, -- Critical priority  
    dependencies = {"EnterpriseDataService", "EnterpriseAnalyticsService"},
    autoStart = true,
    enableCircuitBreaker = true
})

ServiceContainer:RegisterService("EnterpriseSecurityService", function(deps)
    return require(ServerScriptService.Server.services.EnterpriseSecurityService).new(deps)
end, {
    priority = 1, -- Critical priority  
    dependencies = {"EnterpriseDataService", "EnterpriseAnalyticsService", "EnterprisePlayerService"},
    autoStart = true,
    enableCircuitBreaker = true
})

ServiceContainer:RegisterService("EnterpriseMonitoringService", function(deps)
    return require(ServerScriptService.Server.services.EnterpriseMonitoringService).new(deps)
end, {
    priority = 2, -- High priority (monitors all other services)
    dependencies = {"EnterpriseDataService", "EnterpriseAnalyticsService", "EnterprisePlayerService", "EnterpriseSecurityService"},
    autoStart = true,
    enableCircuitBreaker = true
})

ServiceContainer:RegisterService("EnterpriseGameController", function(deps)
    return require(ServerScriptService.Server.services.EnterpriseGameController).new(deps)
end, {
    priority = 3, -- Master controller (depends on all other enterprise services)
    dependencies = {"EnterpriseDataService", "EnterpriseAnalyticsService", "EnterprisePlayerService", "EnterpriseSecurityService", "EnterpriseMonitoringService"},
    autoStart = true,
    enableCircuitBreaker = true
})

-- Register legacy services with modern wrappers
ServiceContainer:RegisterService("MainGameService", function(deps)
    local service = require(ServerScriptService.Server.services.MainGameService)
    -- Inject enterprise capabilities
    service.enterpriseData = deps.EnterpriseDataService
    service.enterpriseAnalytics = deps.EnterpriseAnalyticsService
    return service
end, {
    priority = 2, -- High priority
    dependencies = {"EnterpriseDataService", "EnterpriseAnalyticsService"},
    autoStart = true
})

ServiceContainer:RegisterService("PlayerService", function(deps)
    local service = require(ServerScriptService.Server.services.core.PlayerService)
    service.dataService = deps.EnterpriseDataService
    service.analyticsService = deps.EnterpriseAnalyticsService
    return service
end, {
    priority = 2, -- High priority
    dependencies = {"EnterpriseDataService", "EnterpriseAnalyticsService"},
    autoStart = true
})

ServiceContainer:RegisterService("TrackGeneratorService", function(deps)
    return require(ServerScriptService.Server.services.TrackGeneratorService)
end, {
    priority = 3, -- Medium priority
    dependencies = {"MainGameService"},
    autoStart = true
})

-- Register additional services
local serviceConfigs = {
    {name = "DifficultyService", priority = 3, deps = {"MainGameService", "EnterpriseAnalyticsService"}},
    {name = "MonetizationService", priority = 3, deps = {"EnterpriseDataService", "EnterpriseAnalyticsService"}},
    {name = "AchievementService", priority = 4, deps = {"PlayerService", "EnterpriseAnalyticsService"}},
    {name = "LeaderboardService", priority = 4, deps = {"PlayerService", "EnterpriseDataService"}},
    {name = "QuestService", priority = 4, deps = {"PlayerService", "EnterpriseDataService"}},
    {name = "ShopService", priority = 4, deps = {"MonetizationService", "EnterpriseDataService"}},
    {name = "PerformanceService", priority = 5, deps = {}},
    {name = "ConsoleMonitorService", priority = 5, deps = {}}
}

for _, config in ipairs(serviceConfigs) do
    local serviceName = config.name
    local servicePath = ServerScriptService.Server.services:FindFirstChild(serviceName)
    
    if servicePath then
        ServiceContainer:RegisterService(serviceName, function(deps)
            local service = require(servicePath)
            -- Inject enterprise dependencies
            if deps.EnterpriseDataService then
                service.enterpriseData = deps.EnterpriseDataService
            end
            if deps.EnterpriseAnalyticsService then
                service.enterpriseAnalytics = deps.EnterpriseAnalyticsService
            end
            return service
        end, {
            priority = config.priority,
            dependencies = config.deps,
            autoStart = true
        })
        
        initializationMetrics.totalServices = initializationMetrics.totalServices + 1
    end
end

print("📝 Registered", initializationMetrics.totalServices + 4, "enterprise services") -- +4 for core services

-- ========================================
-- ENTERPRISE STARTUP SEQUENCE
-- ========================================

local function StartEnterpriseServices()
    print("🚀 Starting enterprise service initialization...")
    
    local success, errorMsg = pcall(function()
        ServiceContainer:StartAllServices()
    end)
    
    if success then
        print("✅ All enterprise services started successfully")
        
        -- Update global service access
        _G.Services = {}
        _G.Services.Data = ServiceContainer:GetService("EnterpriseDataService")
        _G.Services.Analytics = ServiceContainer:GetService("EnterpriseAnalyticsService")
        _G.Services.MainGame = ServiceContainer:GetService("MainGameService")
        _G.Services.Player = ServiceContainer:GetService("PlayerService")
        
        -- Store all services for easy access
        for serviceName, _ in pairs(serviceConfigs) do
            local service = ServiceContainer:GetService(serviceName)
            if service then
                _G.Services[serviceName:gsub("Service", "")] = service
            end
        end
        
        return true
    else
        error("Failed to start enterprise services: " .. tostring(errorMsg))
    end
end

-- ========================================
-- PLAYER LIFECYCLE MANAGEMENT
-- ========================================

local function SetupEnterprisePlayerHandling()
    -- Enhanced player join handling
    Players.PlayerAdded:Connect(function(player)
        print("👋 Enterprise player join:", player.Name)
        
        spawn(function()
            -- Load player data through enterprise data service
            local dataService = _G.Services.Data
            local analyticsService = _G.Services.Analytics
            
            local success, playerData = dataService:LoadPlayerData(player)
            if success then
                print("📊 Loaded player data for:", player.Name)
                
                -- Track player join in analytics
                analyticsService:TrackEvent(player, "player_join", {
                    platform = analyticsService:GetPlatform(player),
                    deviceType = analyticsService:GetDeviceType(player),
                    isReturningPlayer = playerData.gamesPlayed > 0
                })
                
                -- Notify other services
                for serviceName, service in pairs(_G.Services) do
                    if service and service.OnPlayerJoined then
                        pcall(function()
                            service:OnPlayerJoined(player, playerData)
                        end)
                    end
                end
            else
                warn("❌ Failed to load player data for:", player.Name)
            end
        end)
    end)
    
    -- Enhanced player leave handling
    Players.PlayerRemoving:Connect(function(player)
        print("👋 Enterprise player leave:", player.Name)
        
        spawn(function()
            local dataService = _G.Services.Data
            local analyticsService = _G.Services.Analytics
            
            -- Get final player data
            local sessionData = dataService:GetSessionData(tostring(player.UserId))
            if sessionData then
                -- Save final state
                dataService:SavePlayerData(player, sessionData)
                
                -- Track player leave with session metrics
                analyticsService:TrackEvent(player, "player_leave", {
                    sessionDuration = analyticsService:GetSessionDuration(player),
                    gamesPlayed = sessionData.gamesPlayed or 0,
                    coinsEarned = sessionData.coins or 0
                })
            end
            
            -- Notify other services
            for serviceName, service in pairs(_G.Services) do
                if service and service.OnPlayerLeaving then
                    pcall(function()
                        service:OnPlayerLeaving(player)
                    end)
                end
            end
        end)
    end)
end

-- ========================================
-- SYSTEM HEALTH MONITORING
-- ========================================

local function StartSystemHealthMonitoring()
    spawn(function()
        while true do
            wait(30) -- Check every 30 seconds
            
            local systemHealth = ServiceContainer:GetSystemHealth()
            local dataHealth = _G.Services.Data:GetSystemHealth()
            local analyticsHealth = _G.Services.Analytics:GetSystemHealth()
            
            -- Log system status
            if systemHealth.overallHealth == "Healthy" then
                print("💚 System Health: All services operational")
            else
                warn("⚠️ System Health Warning:", systemHealth.overallHealth)
                warn("   - Healthy:", systemHealth.healthyServices)
                warn("   - Warning:", systemHealth.warningServices)  
                warn("   - Critical:", systemHealth.criticalServices)
                warn("   - Failing:", systemHealth.failingServices)
            end
            
            -- Track health metrics in analytics
            _G.Services.Analytics:TrackEvent(nil, "system_health", {
                overallHealth = systemHealth.overallHealth,
                healthyServices = systemHealth.healthyServices,
                totalServices = systemHealth.totalServices,
                dataServiceHealth = dataHealth.isHealthy,
                analyticsServiceHealth = analyticsHealth.isHealthy
            })
        end
    end)
end

-- ========================================
-- PERFORMANCE OPTIMIZATION
-- ========================================

local function StartPerformanceOptimization()
    -- Memory cleanup
    spawn(function()
        while true do
            wait(300) -- Every 5 minutes
            
            -- Force garbage collection
            gcinfo()
            
            -- Clean up expired caches
            if _G.Services.Data.CleanupExpiredCache then
                _G.Services.Data:CleanupExpiredCache()
            end
            
            print("🧹 Performed routine cleanup")
        end
    end)
    
    -- Performance monitoring
    local lastFrameTime = tick()
    RunService.Heartbeat:Connect(function()
        local currentTime = tick()
        local deltaTime = currentTime - lastFrameTime
        lastFrameTime = currentTime
        
        -- Track performance metrics
        if deltaTime > 0.1 then -- Frame took longer than 100ms
            _G.Services.Analytics:TrackEvent(nil, "performance_warning", {
                frameTime = deltaTime,
                serverType = "game_server"
            })
        end
    end)
end

-- ========================================
-- ENTERPRISE INITIALIZATION SEQUENCE
-- ========================================

print("� Starting enterprise initialization sequence...")

-- Step 1: Start enterprise services
local success = StartEnterpriseServices()

if success then
    -- Step 2: Setup player handling
    SetupEnterprisePlayerHandling()
    print("✅ Enterprise player handling initialized")
    
    -- Step 3: Start system monitoring
    StartSystemHealthMonitoring()
    print("✅ System health monitoring started")
    
    -- Step 4: Start performance optimization
    StartPerformanceOptimization()
    print("✅ Performance optimization started")
    
    -- Calculate initialization metrics
    initializationMetrics.initializationTime = tick() - initializationMetrics.startTime
    initializationMetrics.servicesLoaded = initializationMetrics.totalServices - initializationMetrics.failedServices
    
    print("🎊 Enterprise Color Rush Server fully operational!")
    print("   📊 Services loaded:", initializationMetrics.servicesLoaded .. "/" .. initializationMetrics.totalServices)
    print("   ⏱️ Initialization time:", math.floor(initializationMetrics.initializationTime * 1000) .. "ms")
    print("   🏢 Enterprise architecture: ACTIVE")
    
    -- Track server startup in analytics
    _G.Services.Analytics:TrackEvent(nil, "server_startup", {
        initializationTime = initializationMetrics.initializationTime,
        servicesLoaded = initializationMetrics.servicesLoaded,
        totalServices = initializationMetrics.totalServices,
        failedServices = initializationMetrics.failedServices
    })
else
    error("❌ Enterprise initialization failed!")
end
