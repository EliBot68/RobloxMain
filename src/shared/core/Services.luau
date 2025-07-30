-- Services.luau
-- Centralized Service Management Module
-- Replaces _G namespace pollution with proper service registry pattern

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Services = {}

-- Private service storage
local _services = {}
local _initialized = false

-- Service loading functions
local serviceLoaders = {
    -- Core Game Services
    MainGameController = function()
        return require(ReplicatedStorage.Server.MainGameController)
    end,
    
    -- Game Systems
    TrackGeneratorService = function()
        return require(ReplicatedStorage.Server.services.TrackGeneratorService)
    end,
    
    MovingObstacleService = function()
        return require(ReplicatedStorage.Server.services.MovingObstacleService)
    end,
    
    CollisionController = function()
        return require(ReplicatedStorage.Server.controllers.CollisionController)
    end,
    
    DifficultyService = function()
        return require(ReplicatedStorage.Server.services.DifficultyService)
    end,
    
    -- Player Services
    PlayerService = function()
        return require(ReplicatedStorage.Server.services.PlayerService)
    end,
    
    DataService = function()
        return require(ReplicatedStorage.Server.services.DataService)
    end,
    
    -- Performance Services
    PerformanceService = function()
        return require(ReplicatedStorage.Server.services.PerformanceService)
    end,
    
    -- Recording Service
    RecordingSessionManager = function()
        return require(ReplicatedStorage.Server.services.RecordingSessionManager)
    end,
    
    -- Analytics (if keeping minimal analytics)
    AnalyticsService = function()
        return require(ReplicatedStorage.Server.services.AnalyticsService)
    end,
}

-- Initialize the service registry
function Services.Initialize()
    if _initialized then
        return true
    end
    
    print("🚀 Initializing centralized Services module...")
    
    -- Pre-load critical services
    local criticalServices = {
        "DataService",
        "PlayerService", 
        "PerformanceService"
    }
    
    for _, serviceName in ipairs(criticalServices) do
        Services.Get(serviceName)
    end
    
    _initialized = true
    print("✅ Services module initialized successfully")
    return true
end

-- Get a service instance (lazy loading)
function Services.Get(serviceName)
    -- Return cached service if available
    if _services[serviceName] then
        return _services[serviceName]
    end
    
    -- Load service if loader exists
    local loader = serviceLoaders[serviceName]
    if not loader then
        warn("❌ No loader found for service: " .. serviceName)
        return nil
    end
    
    -- Attempt to load the service
    local success, result = pcall(loader)
    if success and result then
        _services[serviceName] = result
        print("✅ Loaded service: " .. serviceName)
        return result
    else
        warn("❌ Failed to load service: " .. serviceName .. " - " .. tostring(result))
        return nil
    end
end

-- Register a service instance manually
function Services.Register(serviceName, serviceInstance)
    if not serviceName or not serviceInstance then
        warn("❌ Invalid service registration: " .. tostring(serviceName))
        return false
    end
    
    _services[serviceName] = serviceInstance
    print("📝 Registered service: " .. serviceName)
    return true
end

-- Check if a service is available
function Services.IsAvailable(serviceName)
    return _services[serviceName] ~= nil or serviceLoaders[serviceName] ~= nil
end

-- Get all loaded services
function Services.GetLoadedServices()
    local loaded = {}
    for name, _ in pairs(_services) do
        table.insert(loaded, name)
    end
    return loaded
end

-- Health check for services
function Services.HealthCheck()
    local report = {
        totalServices = 0,
        loadedServices = 0,
        failedServices = {},
        healthyServices = {}
    }
    
    for serviceName, _ in pairs(serviceLoaders) do
        report.totalServices = report.totalServices + 1
        
        local service = Services.Get(serviceName)
        if service then
            report.loadedServices = report.loadedServices + 1
            table.insert(report.healthyServices, serviceName)
        else
            table.insert(report.failedServices, serviceName)
        end
    end
    
    return report
end

-- Cleanup function
function Services.Cleanup()
    for serviceName, service in pairs(_services) do
        if service and type(service.Cleanup) == "function" then
            pcall(service.Cleanup)
        end
    end
    
    _services = {}
    _initialized = false
    print("🧹 Services cleanup completed")
end

-- Initialize automatically when required
Services.Initialize()

return Services
