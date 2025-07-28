-- ServiceMigrationUtility.luau
-- Utility to help migrate services to the standardized Enhanced pattern

local ServiceMigrationUtility = {}

-- Template for converting Knit services to Enhanced pattern
function ServiceMigrationUtility.convertKnitService(serviceName, originalService)
    local template = string.format([[
-- %s.luau
-- %s (Standardized Enhanced Service)

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local ServiceBase = require(ReplicatedStorage.Shared.utils.ServiceBase)

local %s = ServiceBase.new("%s", {
    enableDetailedLogging = true,
    retryFailedRequires = true,
    maxRetryAttempts = 3,
    validateOnStart = true,
    autoStart = false
})

-- Service-specific initialization
function %s:OnInit()
    -- TODO: Convert KnitInit logic here
    return true
end

-- Service-specific start logic
function %s:OnStart()
    -- TODO: Convert KnitStart logic here
    return true
end

-- TODO: Convert service methods from original Knit service

return %s]], 
        serviceName, 
        serviceName,
        serviceName, 
        serviceName,
        serviceName,
        serviceName,
        serviceName
    )
    
    return template
end

-- Template for standardizing existing Enhanced services
function ServiceMigrationUtility.standardizeEnhancedService(serviceName)
    local template = string.format([[
-- %s.luau
-- %s (Standardized Enhanced Service)

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local ServiceBase = require(ReplicatedStorage.Shared.utils.ServiceBase)

local %s = ServiceBase.new("%s", {
    enableDetailedLogging = true,
    retryFailedRequires = true,
    maxRetryAttempts = 3,
    validateOnStart = true,
    autoStart = false
})

-- Define dependencies (if any)
%s.Dependencies = {
    -- { path = script.Parent.SomeService, name = "SomeService", optional = false },
}

-- Service-specific initialization
function %s:OnInit()
    -- Initialize service-specific components here
    return true
end

-- Service-specific start logic
function %s:OnStart()
    -- Start service-specific operations here
    return true
end

-- Setup remote events (if needed)
function %s:SetupRemoteEvents()
    -- Setup RemoteEvents and RemoteFunctions here
end

-- Setup connections (if needed)
function %s:SetupConnections()
    -- Setup event connections here
end

-- Service-specific cleanup
function %s:OnCleanup()
    -- Cleanup service-specific resources here
end

-- TODO: Add service-specific methods here

return %s]], 
        serviceName, 
        serviceName,
        serviceName, 
        serviceName,
        serviceName,
        serviceName,
        serviceName,
        serviceName,
        serviceName,
        serviceName,
        serviceName
    )
    
    return template
end

-- Generate a service registry for centralized management
function ServiceMigrationUtility.generateServiceRegistry()
    local template = [[
-- ServiceRegistry.luau
-- Centralized registry for all standardized services

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SafeRequire = require(ReplicatedStorage.Shared.utils.SafeRequire)

local ServiceRegistry = {}

-- Service definitions with metadata
ServiceRegistry.Services = {
    -- Core Services (Critical)
    GameService = {
        path = script.Parent.Parent.server.services.core.GameService,
        category = "core",
        critical = true,
        autoStart = true
    },
    AnalyticsService = {
        path = script.Parent.Parent.server.services.AnalyticsService,
        category = "core", 
        critical = true,
        autoStart = true
    },
    TrackGeneratorService = {
        path = script.Parent.Parent.server.services.TrackGeneratorService,
        category = "core",
        critical = true,
        autoStart = true
    },
    DifficultyService = {
        path = script.Parent.Parent.server.services.DifficultyService,
        category = "core",
        critical = true,
        autoStart = true
    },
    
    -- Data Services
    DataService = {
        path = script.Parent.Parent.server.services.DataService,
        category = "data",
        critical = true,
        autoStart = true
    },
    PlayerService = {
        path = script.Parent.Parent.server.services.PlayerService,
        category = "data",
        critical = true,
        autoStart = true
    },
    
    -- Feature Services
    UpgradeService = {
        path = script.Parent.Parent.server.services.UpgradeService,
        category = "features",
        critical = false,
        autoStart = true
    },
    MonetizationService = {
        path = script.Parent.Parent.server.services.MonetizationService,
        category = "features",
        critical = false,
        autoStart = true
    },
    
    -- Enhancement Services
    RecordingSessionManager = {
        path = script.Parent.Parent.server.services.RecordingSessionManager,
        category = "enhancement",
        critical = false,
        autoStart = false
    },
    MovingObstacleService = {
        path = script.Parent.Parent.server.services.MovingObstacleService,
        category = "enhancement",
        critical = false,
        autoStart = true
    }
}

-- Loaded services cache
ServiceRegistry.LoadedServices = {}

-- Load a service by name using SafeRequire
function ServiceRegistry:LoadService(serviceName)
    if self.LoadedServices[serviceName] then
        return self.LoadedServices[serviceName]
    end
    
    local serviceConfig = self.Services[serviceName]
    if not serviceConfig then
        warn(string.format("❌ ServiceRegistry: Unknown service '%s'", serviceName))
        return nil
    end
    
    local service = SafeRequire.requireWithRetry(
        serviceConfig.path,
        serviceConfig.critical and 3 or 1
    )
    
    if service then
        self.LoadedServices[serviceName] = service
        print(string.format("✅ ServiceRegistry: Loaded %s", serviceName))
        return service
    else
        if serviceConfig.critical then
            error(string.format("❌ ServiceRegistry: Critical service '%s' failed to load", serviceName))
        else
            warn(string.format("⚠️ ServiceRegistry: Optional service '%s' failed to load", serviceName))
        end
        return nil
    end
end

-- Initialize all services in dependency order
function ServiceRegistry:InitializeAll()
    print("🔧 ServiceRegistry: Initializing all services...")
    
    local categories = {"core", "data", "features", "enhancement"}
    local initializedCount = 0
    local failedServices = {}
    
    for _, category in ipairs(categories) do
        print(string.format("📦 Initializing %s services...", category))
        
        for serviceName, config in pairs(self.Services) do
            if config.category == category then
                local service = self:LoadService(serviceName)
                
                if service and service.Init then
                    local success = pcall(function()
                        service:Init()
                    end)
                    
                    if success then
                        initializedCount = initializedCount + 1
                        print(string.format("  ✅ %s initialized", serviceName))
                    else
                        table.insert(failedServices, serviceName)
                        if config.critical then
                            error(string.format("❌ Critical service %s failed to initialize", serviceName))
                        else
                            warn(string.format("⚠️ Optional service %s failed to initialize", serviceName))
                        end
                    end
                end
            end
        end
    end
    
    print(string.format("✅ ServiceRegistry: Initialized %d services", initializedCount))
    if #failedServices > 0 then
        warn(string.format("⚠️ ServiceRegistry: %d services failed: %s", #failedServices, table.concat(failedServices, ", ")))
    end
    
    return initializedCount, failedServices
end

-- Start all auto-start services
function ServiceRegistry:StartAll()
    print("🚀 ServiceRegistry: Starting auto-start services...")
    
    local startedCount = 0
    
    for serviceName, config in pairs(self.Services) do
        if config.autoStart then
            local service = self.LoadedServices[serviceName]
            
            if service and service.Start then
                local success = pcall(function()
                    service:Start()
                end)
                
                if success then
                    startedCount = startedCount + 1
                    print(string.format("  ✅ %s started", serviceName))
                else
                    warn(string.format("⚠️ %s failed to start", serviceName))
                end
            end
        end
    end
    
    print(string.format("✅ ServiceRegistry: Started %d services", startedCount))
    return startedCount
end

-- Get service by name
function ServiceRegistry:GetService(serviceName)
    return self.LoadedServices[serviceName] or self:LoadService(serviceName)
end

-- Get service status for all services
function ServiceRegistry:GetStatus()
    local status = {
        total = 0,
        loaded = 0,
        initialized = 0,
        started = 0,
        failed = 0,
        services = {}
    }
    
    for serviceName, config in pairs(self.Services) do
        status.total = status.total + 1
        local service = self.LoadedServices[serviceName]
        
        local serviceStatus = {
            name = serviceName,
            category = config.category,
            critical = config.critical,
            loaded = service ~= nil,
            initialized = service and service.IsInitialized or false,
            started = service and service.IsStarted or false
        }
        
        if serviceStatus.loaded then status.loaded = status.loaded + 1 end
        if serviceStatus.initialized then status.initialized = status.initialized + 1 end
        if serviceStatus.started then status.started = status.started + 1 end
        
        status.services[serviceName] = serviceStatus
    end
    
    return status
end

return ServiceRegistry]]
    
    return template
end

return ServiceMigrationUtility
