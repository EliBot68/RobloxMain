-- init.server.lua
-- Enterprise server initialization following Rojo conventions
-- This is the main server entry point that Rojo will recognize

print("🏢 [Server] Loading Enterprise Color Rush Server...")

-- Essential Roblox Services
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local HttpService = game:GetService("HttpService")

-- Wait for shared modules to be available
local SharedFolder = ReplicatedStorage:WaitForChild("Shared", 10)
if not SharedFolder then
    error("🚨 [Server] Failed to load shared modules from ReplicatedStorage!")
end

print("✅ [Server] Shared modules loaded from ReplicatedStorage")

-- Load Enterprise Service Architecture
local EnterpriseServiceArchitecture = require(SharedFolder.core.EnterpriseServiceArchitecture)
local ServiceContainer = EnterpriseServiceArchitecture.ServiceContainer

-- Initialize enterprise service container
local container = ServiceContainer.new()
print("📦 [Server] Enterprise service container initialized")

-- ========================================
-- ENTERPRISE SERVICE REGISTRATION
-- ========================================

print("🔧 [Server] Registering enterprise services...")

-- Core Data Service (Priority 1 - Foundation)
container:RegisterService("EnterpriseDataService", function(deps)
    return require(SharedFolder.core.EnterpriseDataService).new(deps)
end, {
    priority = 1,
    dependencies = {},
    autoStart = true,
    enableCircuitBreaker = true,
    enableCaching = true
})

-- Analytics Service (Priority 1 - Critical for tracking)
container:RegisterService("EnterpriseAnalyticsService", function(deps)
    return require(script.Parent.services.Analytics.EnterpriseAnalyticsService).new(deps)
end, {
    priority = 1,
    dependencies = {"EnterpriseDataService"},
    autoStart = true,
    enableCircuitBreaker = true,
    enableRateLimiting = true
})

-- Player Service (Priority 1 - Critical for player management)
container:RegisterService("EnterprisePlayerService", function(deps)
    return require(script.Parent.services.EnterprisePlayerService).new(deps)
end, {
    priority = 1,
    dependencies = {"EnterpriseDataService", "EnterpriseAnalyticsService"},
    autoStart = true,
    enableCircuitBreaker = true
})

-- Security Service (Priority 1 - Critical for anti-cheat)
container:RegisterService("EnterpriseSecurityService", function(deps)
    return require(script.Parent.services.EnterpriseSecurityService).new(deps)
end, {
    priority = 1,
    dependencies = {"EnterpriseDataService", "EnterpriseAnalyticsService", "EnterprisePlayerService"},
    autoStart = true,
    enableCircuitBreaker = true
})

-- Monitoring Service (Priority 2 - Monitors all other services)
container:RegisterService("EnterpriseMonitoringService", function(deps)
    return require(script.Parent.services.EnterpriseMonitoringService).new(deps)
end, {
    priority = 2,
    dependencies = {"EnterpriseDataService", "EnterpriseAnalyticsService", "EnterprisePlayerService", "EnterpriseSecurityService"},
    autoStart = true,
    enableCircuitBreaker = true
})

-- Game Controller (Priority 3 - Master orchestrator)
container:RegisterService("EnterpriseGameController", function(deps)
    return require(script.Parent.services.EnterpriseGameController).new(deps)
end, {
    priority = 3,
    dependencies = {"EnterpriseDataService", "EnterpriseAnalyticsService", "EnterprisePlayerService", "EnterpriseSecurityService", "EnterpriseMonitoringService"},
    autoStart = true,
    enableCircuitBreaker = true
})

-- Main Game Service (Priority 4 - Game logic)
container:RegisterService("MainGameService", function(deps)
    local service = require(script.Parent.services.MainGameService)
    -- Inject enterprise dependencies
    service.enterpriseData = deps.EnterpriseDataService
    service.enterpriseAnalytics = deps.EnterpriseAnalyticsService
    service.enterprisePlayer = deps.EnterprisePlayerService
    return service
end, {
    priority = 4,
    dependencies = {"EnterpriseDataService", "EnterpriseAnalyticsService", "EnterprisePlayerService"},
    autoStart = true
})

-- Track Generator Service (Priority 5 - Game content)
container:RegisterService("TrackGeneratorService", function(deps)
    return require(script.Parent.services.TrackGeneratorService)
end, {
    priority = 5,
    dependencies = {"MainGameService"},
    autoStart = true
})

-- Additional Game Services (Priority 6 - Extended features)
local additionalServices = {
    {name = "DifficultyService", deps = {"MainGameService", "EnterpriseAnalyticsService"}},
    {name = "MonetizationService", deps = {"EnterpriseDataService", "EnterpriseAnalyticsService"}},
    {name = "AchievementService", deps = {"EnterpriseDataService", "EnterpriseAnalyticsService"}},
    {name = "LeaderboardService", deps = {"EnterpriseDataService", "EnterpriseAnalyticsService"}},
    {name = "AntiCheatService", deps = {"EnterpriseSecurityService"}},
    {name = "PerformanceService", deps = {"EnterpriseMonitoringService"}},
}

for _, serviceConfig in pairs(additionalServices) do
    local serviceModule = script.Parent.services:FindFirstChild(serviceConfig.name)
    if serviceModule then
        container:RegisterService(serviceConfig.name, function(deps)
            local service = require(serviceModule)
            -- Inject enterprise dependencies if the service supports it
            if service.SetDependencies then
                service:SetDependencies(deps)
            end
            return service
        end, {
            priority = 6,
            dependencies = serviceConfig.deps,
            autoStart = true
        })
    else
        warn("⚠️ [Server] Service not found:", serviceConfig.name)
    end
end

-- ========================================
-- SERVICE STARTUP
-- ========================================

print("🚀 [Server] Starting all enterprise services...")
container:StartAllServices()

-- Verify all services started successfully
local healthCheck = container:HealthCheck()
if healthCheck.allHealthy then
    print("✅ [Server] All enterprise services started successfully!")
else
    warn("⚠️ [Server] Some services failed to start:", healthCheck.unhealthyServices)
end

-- ========================================
-- GLOBAL ERROR HANDLING
-- ========================================

local function handleGlobalError(message, trace)
    local analyticsService = container:GetService("EnterpriseAnalyticsService")
    if analyticsService then
        analyticsService:TrackEvent(nil, "server_error", {
            message = message,
            trace = trace,
            timestamp = os.time(),
            gameId = game.GameId,
            placeId = game.PlaceId
        })
    end
    
    warn("🚨 [Server] Unhandled error:", message)
    warn("📍 [Server] Stack trace:", trace)
end

-- Set up global error handler
pcall(function()
    game:GetService("ScriptContext").Error:Connect(handleGlobalError)
end)

-- ========================================
-- PERFORMANCE MONITORING
-- ========================================

spawn(function()
    while true do
        wait(30) -- Check every 30 seconds
        
        local memoryUsage = gcinfo() * 1024
        local playerCount = #Players:GetPlayers()
        
        -- Monitor service health
        local healthCheck = container:HealthCheck()
        if not healthCheck.allHealthy then
            warn("⚠️ [Server] Service health issues detected:", healthCheck.unhealthyServices)
        end
        
        -- Memory cleanup if needed
        if memoryUsage > 500 * 1024 * 1024 then -- 500MB threshold
            print("🧹 [Server] High memory usage detected, running garbage collection...")
            collectgarbage("collect")
        end
        
        -- Track performance metrics
        local analyticsService = container:GetService("EnterpriseAnalyticsService")
        if analyticsService then
            analyticsService:TrackEvent(nil, "server_performance", {
                memoryUsage = memoryUsage,
                playerCount = playerCount,
                servicesHealthy = healthCheck.allHealthy
            })
        end
    end
end)

-- ========================================
-- GRACEFUL SHUTDOWN
-- ========================================

game:BindToClose(function()
    print("🛑 [Server] Server shutting down...")
    
    -- Save all player data
    local playerService = container:GetService("EnterprisePlayerService")
    if playerService then
        for _, player in pairs(Players:GetPlayers()) do
            spawn(function()
                playerService:SavePlayerDataAsync(player)
            end)
        end
        wait(3) -- Give time for saves to complete
    end
    
    -- Stop all services gracefully
    container:StopAllServices()
    
    print("✅ [Server] Enterprise server shutdown complete")
end)

-- ========================================
-- GLOBAL EXPORTS
-- ========================================

-- Export container for global access
_G.EnterpriseContainer = container
_G.EnterpriseServices = {
    GetService = function(serviceName)
        return container:GetService(serviceName)
    end,
    GetAllServices = function()
        return container:GetAllServices()
    end,
    GetHealthStatus = function()
        return container:HealthCheck()
    end
}

print("🌟 [Server] Enterprise Color Rush Server fully operational!")
print("   📊 Services registered:", container:GetServiceCount())
print("   🏢 Enterprise architecture: ACTIVE")
print("   🔗 Global exports: _G.EnterpriseContainer, _G.EnterpriseServices")

-- Send server startup analytics
local analyticsService = container:GetService("EnterpriseAnalyticsService")
if analyticsService then
    analyticsService:TrackEvent(nil, "server_startup", {
        servicesCount = container:GetServiceCount(),
        gameId = game.GameId,
        placeId = game.PlaceId,
        timestamp = os.time()
    })
end
