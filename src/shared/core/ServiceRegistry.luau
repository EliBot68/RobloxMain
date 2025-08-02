-- ServiceRegistry.luau  
-- Centralized service management and dependency injection system
-- Provides service discovery, lifecycle management, and dependency resolution

local _ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Remove unused import to reduce memory usage and confusion
-- local _SafeRequire = require(ReplicatedStorage.Shared.utils.SafeRequire)

local ServiceRegistry = {}
ServiceRegistry.__index = ServiceRegistry

-- Store singleton instances per context to enable testing
local _instances = {}

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

-- Get singleton instance with context support for testing
function ServiceRegistry.getInstance(context)
    context = context or "default"
    if not _instances[context] then
        _instances[context] = ServiceRegistry.new()
    end
    return _instances[context]
end

-- Clear instance for testing
function ServiceRegistry.clearInstance(context)
    context = context or "default"
    if _instances[context] then
        _instances[context]:Cleanup()
        _instances[context] = nil
    end
end

-- Register a service class
function ServiceRegistry:RegisterService(name, serviceClass, config)
    if self.services[name] then
        warn("Service '" .. name .. "' is already registered")
        return false -- Return early to prevent confusion
    end
    
    -- Validate config parameter for required fields and correct types
    config = config or {}
    if type(config) ~= "table" then
        error("Config parameter must be a table")
    end
    
    self.services[name] = {
        name = name,
        class = serviceClass,
        config = config,
        state = SERVICE_STATES.REGISTERED,
        dependencies = config.Dependencies or {},
        priority = config.Priority or 0,
        serviceInstance = nil, -- Renamed to avoid variable shadowing
        errorCount = 0,
        lastError = nil
    }
    
    -- Thread-safe metrics update with validation
    local function updateMetrics()
        self.metrics.totalServices = (self.metrics.totalServices or 0) + 1
    end
    
    local success, err = pcall(updateMetrics)
    if not success then
        warn("Failed to update metrics: " .. tostring(err))
    end
    
    self.ServiceRegistered:Fire(name)
    
    return true
end

-- Get a service instance (lazy initialization)
function ServiceRegistry:GetService(name)
    -- Thread-safe metrics update with overflow protection
    local function updateMetricsCount()
        self.metrics.totalRequests = (self.metrics.totalRequests or 0) + 1
        -- Prevent overflow with very large numbers
        if self.metrics.totalRequests > 1000000 then
            self.metrics.totalRequests = 1000000
        end
    end
    
    local success, err = pcall(updateMetricsCount)
    if not success then
        warn("Failed to update request metrics: " .. tostring(err))
    end
    
    local startTime = tick()
    
    local serviceInfo = self.services[name]
    if not serviceInfo then
        warn("Service '" .. name .. "' is not registered")
        return nil
    end
    
    -- Return existing instance if available
    if serviceInfo.serviceInstance then
        self:_updateResponseTime(startTime)
        return serviceInfo.serviceInstance
    end
    
    -- Initialize service if needed with proper error handling and cleanup
    local initSuccess, result = pcall(function()
        return self:_initializeService(name)
    end)
    
    if not initSuccess then
        -- Ensure atomicity - update error state together
        serviceInfo.state = SERVICE_STATES.ERROR
        serviceInfo.errorCount = serviceInfo.errorCount + 1
        serviceInfo.lastError = result
        
        -- Thread-safe metrics update
        local metricsSuccess = pcall(function()
            self.metrics.failedServices = (self.metrics.failedServices or 0) + 1
        end)
        if not metricsSuccess then
            warn("Failed to update failure metrics")
        end
        
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
    if serviceInfo.serviceInstance then
        return serviceInfo.serviceInstance
    end
    
    serviceInfo.state = SERVICE_STATES.INITIALIZING
    
    -- Validate and initialize dependencies first
    for _, depName in ipairs(serviceInfo.dependencies) do
        -- Validate that all dependencies actually exist
        if not self.services[depName] then
            error("Dependency '" .. depName .. "' for service '" .. name .. "' is not registered")
        end
        
        local dependency = self:GetService(depName)
        if not dependency then
            error("Failed to resolve dependency '" .. depName .. "' for service '" .. name .. "'")
        end
    end
    
    -- Validate service class interface before creating instance
    local serviceClass = serviceInfo.class
    local serviceInstance
    
    if type(serviceClass) == "function" then
        serviceInstance = serviceClass.new(serviceInfo.config)
    elseif type(serviceClass) == "table" and type(serviceClass.new) == "function" then
        serviceInstance = serviceClass.new(serviceInfo.config)
    else
        error("Invalid service class for '" .. name .. "' - must be function or table with new method")
    end
    
    -- Validate initialization method exists and succeeded
    if serviceInstance.Initialize then
        if type(serviceInstance.Initialize) ~= "function" then
            error("Initialize method for service '" .. name .. "' is not a function")
        end
        
        local initSuccess, initResult = pcall(function()
            return serviceInstance:Initialize()
        end)
        
        if not initSuccess then
            error("Initialization failed for service '" .. name .. "': " .. tostring(initResult))
        end
    end
    
    serviceInfo.serviceInstance = serviceInstance
    serviceInfo.state = SERVICE_STATES.INITIALIZED
    
    return serviceInstance
end

-- Start all services with proper cleanup on partial failure
function ServiceRegistry:StartAllServices()
    local startOrder = self:_calculateStartOrder()
    local startedServices = {}
    
    for _, serviceName in ipairs(startOrder) do
        local success, err = pcall(function()
            self:StartService(serviceName)
        end)
        
        if success then
            table.insert(startedServices, serviceName)
        else
            -- Clean up partial initialization states
            warn("Failed to start service '" .. serviceName .. "': " .. tostring(err))
            
            -- Stop already started services in reverse order
            for i = #startedServices, 1, -1 do
                local stopSuccess = pcall(function()
                    self:StopService(startedServices[i])
                end)
                if not stopSuccess then
                    warn("Failed to stop service during cleanup: " .. startedServices[i])
                end
            end
            
            error("Service startup failed at '" .. serviceName .. "', system rolled back")
        end
    end
end

-- Start a specific service
function ServiceRegistry:StartService(name)
    local serviceInfo = self.services[name]
    if not serviceInfo then
        error("Service not found: " .. name)
    end
    
    -- Validate service is in a valid state to be started
    if serviceInfo.state == SERVICE_STATES.RUNNING then
        warn("Service '" .. name .. "' is already running")
        return
    end
    
    if serviceInfo.state == SERVICE_STATES.ERROR then
        error("Cannot start service '" .. name .. "' in error state")
    end
    
    -- Get or create instance
    local serviceInstance = self:GetService(name)
    if not serviceInstance then
        error("Failed to get service instance: " .. name)
    end
    
    serviceInfo.state = SERVICE_STATES.STARTING
    
    -- Validate and start the service if it has a Start method
    if serviceInstance.Start then
        if type(serviceInstance.Start) ~= "function" then
            error("Start method for service '" .. name .. "' is not a function")
        end
        
        local startSuccess, startError = pcall(function()
            serviceInstance:Start()
        end)
        
        if not startSuccess then
            serviceInfo.state = SERVICE_STATES.ERROR
            error("Failed to start service '" .. name .. "': " .. tostring(startError))
        end
    end
    
    serviceInfo.state = SERVICE_STATES.RUNNING
    
    -- Thread-safe metrics update
    local metricsSuccess = pcall(function()
        self.metrics.runningServices = (self.metrics.runningServices or 0) + 1
    end)
    if not metricsSuccess then
        warn("Failed to update running service metrics")
    end
    
    self.ServiceStarted:Fire(name)
end

-- Stop a specific service
function ServiceRegistry:StopService(name)
    local serviceInfo = self.services[name]
    if not serviceInfo or not serviceInfo.serviceInstance then
        return
    end
    
    serviceInfo.state = SERVICE_STATES.STOPPING
    
    -- Validate and stop the service if it has a Stop method
    if serviceInfo.serviceInstance.Stop then
        if type(serviceInfo.serviceInstance.Stop) ~= "function" then
            warn("Stop method for service '" .. name .. "' is not a function")
        else
            local stopSuccess, stopError = pcall(function()
                serviceInfo.serviceInstance:Stop()
            end)
            
            if not stopSuccess then
                warn("Failed to stop service '" .. name .. "': " .. tostring(stopError))
            end
        end
    end
    
    serviceInfo.state = SERVICE_STATES.STOPPED
    
    -- Thread-safe metrics update
    local metricsSuccess = pcall(function()
        self.metrics.runningServices = math.max(0, (self.metrics.runningServices or 0) - 1)
    end)
    if not metricsSuccess then
        warn("Failed to update running service metrics")
    end
    
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
        hasInstance = serviceInfo.serviceInstance ~= nil,
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

-- Calculate service start order based on dependencies (optimized topological sort)
function ServiceRegistry:_calculateStartOrder()
    local visited = {}
    local visiting = {}
    local order = {}
    
    -- Pre-validate all dependencies exist before building dependency graph
    for name, serviceInfo in pairs(self.services) do
        for _, depName in ipairs(serviceInfo.dependencies) do
            if not self.services[depName] then
                error("Service '" .. name .. "' depends on unregistered service '" .. depName .. "'")
            end
        end
    end
    
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
            -- Visit dependencies efficiently
            for _, depName in ipairs(serviceInfo.dependencies) do
                visit(depName)
            end
        end
        
        visiting[name] = nil
        visited[name] = true
        table.insert(order, name)
    end
    
    -- Visit all services (O(n) complexity)
    for name, _ in pairs(self.services) do
        if not visited[name] then
            visit(name)
        end
    end
    
    return order
end

-- Update response time metrics with overflow protection
function ServiceRegistry:_updateResponseTime(startTime)
    local responseTime = tick() - startTime
    
    -- Protect against overflow with very large numbers
    if responseTime > 3600 then -- Cap at 1 hour
        responseTime = 3600
    end
    
    local totalRequests = self.metrics.totalRequests or 1
    if totalRequests <= 1 then
        self.metrics.averageResponseTime = responseTime
    else
        local currentAverage = self.metrics.averageResponseTime or 0
        local totalTime = currentAverage * (totalRequests - 1)
        
        -- Prevent overflow in calculation
        if totalTime > 1000000 then
            -- Reset metrics if they get too large
            self.metrics.averageResponseTime = responseTime
            self.metrics.totalRequests = 1
        else
            self.metrics.averageResponseTime = (totalTime + responseTime) / totalRequests
        end
    end
end

-- Cleanup method with proper metrics reset and event cleanup
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
    
    -- Reset metrics
    self.metrics = {
        totalServices = 0,
        runningServices = 0,
        failedServices = 0,
        totalRequests = 0,
        averageResponseTime = 0
    }
    
    -- Clean up events with error handling
    local function safeDestroy(event, eventName)
        local success = pcall(function()
            if event then
                event:Destroy()
            end
        end)
        if not success then
            warn("Failed to destroy " .. eventName .. " event")
        end
    end
    
    safeDestroy(self.ServiceRegistered, "ServiceRegistered")
    safeDestroy(self.ServiceStarted, "ServiceStarted")
    safeDestroy(self.ServiceStopped, "ServiceStopped")
    safeDestroy(self.ServiceError, "ServiceError")
    
    -- Clear from singleton instances
    for context, instance in pairs(_instances) do
        if instance == self then
            _instances[context] = nil
        end
    end
end

return ServiceRegistry
