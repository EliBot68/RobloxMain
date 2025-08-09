-- ServiceRegistry.luau  
-- Centralized service management and dependency injection system
-- Provides service discovery, lifecycle management, and dependency resolution

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local _SafeRequire = require(game.ReplicatedStorage.Shared.utils.SafeRequire)

local ServiceRegistry = {}
ServiceRegistry.__index = ServiceRegistry

-- Singleton instance
local instance = nil

-- Service states for tracking
local SERVICE_STATES = {
    UNREGISTERED = "Unregistered",
    REGISTERED = "Registered", 
    INITIALIZING = "Initializing",
    INITIALIZED = "Initialized",
    STARTING = "Starting",
    RUNNING = "Running",
    STOPPING = "Stopping",
    STOPPED = "Stopped",
    ERROR = "Error"
}

-- Create new registry instance
function ServiceRegistry.new()
    local self = setmetatable({}, ServiceRegistry)
    
    self.services = {}
    self.serviceInstances = {}
    self.dependencyGraph = {}
    self.initializationOrder = {}
    self.isInitialized = false
    
    -- Metrics
    self.metrics = {
        totalServices = 0,
        runningServices = 0,
        failedServices = 0,
        totalRequests = 0,
        averageResponseTime = 0
    }
    
    -- Events for monitoring
    self.ServiceRegistered = Instance.new("BindableEvent")
    self.ServiceStarted = Instance.new("BindableEvent")
    self.ServiceStopped = Instance.new("BindableEvent")
    self.ServiceError = Instance.new("BindableEvent")
    
    return self
end

-- Get singleton instance
function ServiceRegistry.getInstance()
    if not instance then
        instance = ServiceRegistry.new()
    end
    return instance
end

-- Register a service class
function ServiceRegistry:RegisterService(name, serviceClass, config)
    if self.services[name] then
        warn("Service '" .. name .. "' is already registered")
        return false
    end
    
    config = config or {}
    
    self.services[name] = {
        name = name,
        class = serviceClass,
        config = config,
        state = SERVICE_STATES.REGISTERED,
        dependencies = config.Dependencies or {},
        priority = config.Priority or 0,
        instance = nil,
        errorCount = 0,
        lastError = nil
    }
    
    self.metrics.totalServices = self.metrics.totalServices + 1
    self.ServiceRegistered:Fire(name)
    
    return true
end

-- Get a service instance (lazy initialization)
function ServiceRegistry:GetService(name)
    self.metrics.totalRequests = self.metrics.totalRequests + 1
    local startTime = tick()
    
    local serviceInfo = self.services[name]
    if not serviceInfo then
        warn("Service '" .. name .. "' is not registered")
        return nil
    end
    
    -- Return existing instance if available
    if serviceInfo.instance then
        self:_updateResponseTime(startTime)
        return serviceInfo.instance
    end
    
    -- Initialize service if needed
    local success, result = pcall(function()
        return self:_initializeService(name)
    end)
    
    if not success then
        serviceInfo.state = SERVICE_STATES.ERROR
        serviceInfo.errorCount = serviceInfo.errorCount + 1
        serviceInfo.lastError = result
        self.metrics.failedServices = self.metrics.failedServices + 1
        self.ServiceError:Fire(name, result)
        warn("Failed to initialize service '" .. name .. "': " .. tostring(result))
        return nil
    end
    
    self:_updateResponseTime(startTime)
    return result
end

-- Internal method to initialize a service
function ServiceRegistry:_initializeService(name)
    local serviceInfo = self.services[name]
    if not serviceInfo then
        error("Service not found: " .. name)
    end
    
    -- Check if already initialized
    if serviceInfo.instance then
        return serviceInfo.instance
    end
    
    serviceInfo.state = SERVICE_STATES.INITIALIZING
    
    -- Initialize dependencies first
    for _, depName in ipairs(serviceInfo.dependencies) do
        local dependency = self:GetService(depName)
        if not dependency then
            error("Failed to resolve dependency '" .. depName .. "' for service '" .. name .. "'")
        end
    end
    
    -- Create service instance
    local serviceClass = serviceInfo.class
    local instance
    
    if type(serviceClass) == "function" then
        instance = serviceClass.new(serviceInfo.config)
    elseif type(serviceClass) == "table" and serviceClass.new then
        instance = serviceClass.new(serviceInfo.config)
    else
        error("Invalid service class for '" .. name .. "'")
    end
    
    -- Initialize the service
    if instance.Initialize then
        instance:Initialize()
    end
    
    serviceInfo.instance = instance
    serviceInfo.state = SERVICE_STATES.INITIALIZED
    
    return instance
end

-- Start all services
function ServiceRegistry:StartAllServices()
    local startOrder = self:_calculateStartOrder()
    
    for _, serviceName in ipairs(startOrder) do
        local success, err = pcall(function()
            self:StartService(serviceName)
        end)
        
        if not success then
            warn("Failed to start service '" .. serviceName .. "': " .. tostring(err))
        end
    end
end

-- Start a specific service
function ServiceRegistry:StartService(name)
    local serviceInfo = self.services[name]
    if not serviceInfo then
        error("Service not found: " .. name)
    end
    
    -- Get or create instance
    local instance = self:GetService(name)
    if not instance then
        error("Failed to get service instance: " .. name)
    end
    
    serviceInfo.state = SERVICE_STATES.STARTING
    
    -- Start the service if it has a Start method
    if instance.Start then
        instance:Start()
    end
    
    serviceInfo.state = SERVICE_STATES.RUNNING
    self.metrics.runningServices = self.metrics.runningServices + 1
    self.ServiceStarted:Fire(name)
end

-- Stop a specific service
function ServiceRegistry:StopService(name)
    local serviceInfo = self.services[name]
    if not serviceInfo or not serviceInfo.instance then
        return
    end
    
    serviceInfo.state = SERVICE_STATES.STOPPING
    
    -- Stop the service if it has a Stop method
    if serviceInfo.instance.Stop then
        serviceInfo.instance:Stop()
    end
    
    serviceInfo.state = SERVICE_STATES.STOPPED
    self.metrics.runningServices = math.max(0, self.metrics.runningServices - 1)
    self.ServiceStopped:Fire(name)
end

-- Get service status
function ServiceRegistry:GetServiceStatus(name)
    local serviceInfo = self.services[name]
    if not serviceInfo then
        return nil
    end
    
    return {
        name = name,
        state = serviceInfo.state,
        hasInstance = serviceInfo.instance ~= nil,
        errorCount = serviceInfo.errorCount,
        lastError = serviceInfo.lastError,
        dependencies = serviceInfo.dependencies
    }
end

-- Get all service statuses
function ServiceRegistry:GetAllServiceStatuses()
    local statuses = {}
    for name, _ in pairs(self.services) do
        statuses[name] = self:GetServiceStatus(name)
    end
    return statuses
end

-- Get registry metrics
function ServiceRegistry:GetMetrics()
    return {
        totalServices = self.metrics.totalServices,
        runningServices = self.metrics.runningServices,
        failedServices = self.metrics.failedServices,
        totalRequests = self.metrics.totalRequests,
        averageResponseTime = self.metrics.averageResponseTime
    }
end

-- Calculate service start order based on dependencies
function ServiceRegistry:_calculateStartOrder()
    local visited = {}
    local visiting = {}
    local order = {}
    
    local function visit(name)
        if visiting[name] then
            error("Circular dependency detected involving service: " .. name)
        end
        
        if visited[name] then
            return
        end
        
        visiting[name] = true
        
        local serviceInfo = self.services[name]
        if serviceInfo then
            for _, depName in ipairs(serviceInfo.dependencies) do
                if self.services[depName] then
                    visit(depName)
                end
            end
        end
        
        visiting[name] = nil
        visited[name] = true
        table.insert(order, name)
    end
    
    -- Visit all services
    for name, _ in pairs(self.services) do
        visit(name)
    end
    
    return order
end

-- Update response time metrics
function ServiceRegistry:_updateResponseTime(startTime)
    local responseTime = tick() - startTime
    local totalTime = self.metrics.averageResponseTime * (self.metrics.totalRequests - 1)
    self.metrics.averageResponseTime = (totalTime + responseTime) / self.metrics.totalRequests
end

-- Cleanup method
function ServiceRegistry:Cleanup()
    -- Stop all services
    for name, serviceInfo in pairs(self.services) do
        if serviceInfo.state == SERVICE_STATES.RUNNING then
            self:StopService(name)
        end
    end
    
    -- Clear everything
    self.services = {}
    self.serviceInstances = {}
    self.dependencyGraph = {}
    
    -- Clean up events
    if self.ServiceRegistered then
        self.ServiceRegistered:Destroy()
    end
    if self.ServiceStarted then
        self.ServiceStarted:Destroy()
    end
    if self.ServiceStopped then
        self.ServiceStopped:Destroy()
    end
    if self.ServiceError then
        self.ServiceError:Destroy()
    end
end

return ServiceRegistry
