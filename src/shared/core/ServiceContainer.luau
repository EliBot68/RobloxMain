-- ServiceContainer.luau
-- Enterprise-grade dependency injection container for service management
-- Replaces all _G usage with proper dependency injection patterns

local ServiceContainer = {}
ServiceContainer.__index = ServiceContainer

-- Service registration and resolution
local services = {}
local serviceConfigs = {}
local serviceInstances = {}
local serviceDependencies = {}
local initializationOrder = {}
local serviceInterfaces = {}

-- Service lifecycle states
local ServiceState = {
    UNREGISTERED = "unregistered",
    REGISTERED = "registered", 
    INITIALIZING = "initializing",
    INITIALIZED = "initialized",
    STARTING = "starting",
    STARTED = "started",
    STOPPING = "stopping",
    STOPPED = "stopped",
    ERROR = "error"
}

-- Service configuration schema
local ServiceConfig = {
    name = "",
    interface = nil,
    implementation = nil,
    dependencies = {},
    lifecycle = {
        autoStart = true,
        initTimeout = 30,
        startTimeout = 10,
        stopTimeout = 10
    },
    singleton = true
}

-- Container instance
local containerInstance = nil

-- ========================================
-- CORE CONTAINER METHODS
-- ========================================

function ServiceContainer.new()
    local self = setmetatable({}, ServiceContainer)
    self.services = {}
    self.instances = {}
    self.states = {}
    self.dependencyGraph = {}
    self.initOrder = {}
    self.logger = self:_createLogger()
    return self
end

function ServiceContainer:GetInstance()
    if not containerInstance then
        containerInstance = ServiceContainer.new()
    end
    return containerInstance
end

-- ========================================
-- SERVICE REGISTRATION
-- ========================================

function ServiceContainer:RegisterService(config)
    assert(config.name, "Service name is required")
    assert(config.implementation, "Service implementation is required")
    
    if self.services[config.name] then
        error("Service '" .. config.name .. "' is already registered")
    end
    
    -- Validate service interface if provided
    if config.interface then
        self:_validateServiceInterface(config.implementation, config.interface)
    end
    
    -- Create full service configuration
    local serviceConfig = self:_mergeConfig(ServiceConfig, config)
    
    self.services[config.name] = serviceConfig
    self.states[config.name] = ServiceState.REGISTERED
    self.dependencyGraph[config.name] = config.dependencies or {}
    
    self.logger:Info("Registered service: " .. config.name)
    
    return self
end

function ServiceContainer:RegisterInterface(name, interface)
    assert(name, "Interface name is required")
    assert(interface, "Interface definition is required")
    
    serviceInterfaces[name] = interface
    self.logger:Info("Registered interface: " .. name)
    
    return self
end

-- ========================================
-- SERVICE RESOLUTION
-- ========================================

function ServiceContainer:GetService(serviceName)
    assert(serviceName, "Service name is required")
    
    if not self.services[serviceName] then
        error("Service '" .. serviceName .. "' is not registered")
    end
    
    -- Return singleton instance if it exists
    if self.instances[serviceName] then
        return self.instances[serviceName]
    end
    
    -- Create and initialize service instance
    return self:_createServiceInstance(serviceName)
end

function ServiceContainer:TryGetService(serviceName)
    local success, result = pcall(function()
        return self:GetService(serviceName)
    end)
    
    if success then
        return result
    else
        self.logger:Warn("Failed to resolve service '" .. serviceName .. "': " .. tostring(result))
        return nil
    end
end

function ServiceContainer:HasService(serviceName)
    return self.services[serviceName] ~= nil
end

-- ========================================
-- SERVICE LIFECYCLE MANAGEMENT
-- ========================================

function ServiceContainer:InitializeServices()
    self.logger:Info("Starting service initialization...")
    
    -- Calculate initialization order based on dependencies
    local initOrder = self:_calculateInitializationOrder()
    
    for _, serviceName in ipairs(initOrder) do
        self:_initializeService(serviceName)
    end
    
    self.logger:Info("Service initialization complete")
    return self
end

function ServiceContainer:StartServices()
    self.logger:Info("Starting all services...")
    
    for _, serviceName in ipairs(self.initOrder) do
        if self.services[serviceName].lifecycle.autoStart then
            self:_startService(serviceName)
        end
    end
    
    self.logger:Info("All services started")
    return self
end

function ServiceContainer:StopServices()
    self.logger:Info("Stopping all services...")
    
    -- Stop services in reverse order
    local reverseOrder = {}
    for i = #self.initOrder, 1, -1 do
        table.insert(reverseOrder, self.initOrder[i])
    end
    
    for _, serviceName in ipairs(reverseOrder) do
        self:_stopService(serviceName)
    end
    
    self.logger:Info("All services stopped")
    return self
end

function ServiceContainer:GetServiceState(serviceName)
    return self.states[serviceName] or ServiceState.UNREGISTERED
end

-- ========================================
-- DEPENDENCY INJECTION
-- ========================================

function ServiceContainer:InjectDependencies(serviceInstance, serviceName)
    local config = self.services[serviceName]
    if not config or not config.dependencies then
        return serviceInstance
    end
    
    -- Inject each dependency
    for _, dependencyName in ipairs(config.dependencies) do
        local dependency = self:GetService(dependencyName)
        
        -- Try multiple injection patterns
        if serviceInstance.SetDependency then
            serviceInstance:SetDependency(dependencyName, dependency)
        elseif serviceInstance.dependencies then
            serviceInstance.dependencies[dependencyName] = dependency
        else
            -- Create dependencies table if it doesn't exist
            serviceInstance.dependencies = serviceInstance.dependencies or {}
            serviceInstance.dependencies[dependencyName] = dependency
        end
    end
    
    return serviceInstance
end

-- ========================================
-- SERVICE FACTORY METHODS
-- ========================================

function ServiceContainer:CreateServiceFactory(serviceName)
    return function()
        return self:GetService(serviceName)
    end
end

function ServiceContainer:CreateLazyService(serviceName)
    local lazyService = {}
    local serviceInstance = nil
    
    setmetatable(lazyService, {
        __index = function(_, key)
            if not serviceInstance then
                serviceInstance = self:GetService(serviceName)
            end
            return serviceInstance[key]
        end,
        
        __newindex = function(_, key, value)
            if not serviceInstance then
                serviceInstance = self:GetService(serviceName)
            end
            serviceInstance[key] = value
        end
    })
    
    return lazyService
end

-- ========================================
-- PRIVATE IMPLEMENTATION METHODS
-- ========================================

function ServiceContainer:_createServiceInstance(serviceName)
    local config = self.services[serviceName]
    
    if self.states[serviceName] == ServiceState.INITIALIZING then
        error("Circular dependency detected for service: " .. serviceName)
    end
    
    self.states[serviceName] = ServiceState.INITIALIZING
    self.logger:Debug("Creating instance for service: " .. serviceName)
    
    -- Resolve dependencies first
    local dependencies = {}
    for _, depName in ipairs(config.dependencies or {}) do
        dependencies[depName] = self:GetService(depName)
    end
    
    -- Create service instance
    local instance
    if type(config.implementation) == "function" then
        -- Factory function
        instance = config.implementation(dependencies)
    else
        -- Module or class
        instance = config.implementation
    end
    
    -- Inject dependencies
    self:InjectDependencies(instance, serviceName)
    
    -- Store instance if singleton
    if config.singleton then
        self.instances[serviceName] = instance
    end
    
    self.states[serviceName] = ServiceState.INITIALIZED
    self.logger:Debug("Service instance created: " .. serviceName)
    
    return instance
end

function ServiceContainer:_initializeService(serviceName)
    if self.states[serviceName] == ServiceState.INITIALIZED then
        return
    end
    
    self.logger:Debug("Initializing service: " .. serviceName)
    
    local instance = self:_createServiceInstance(serviceName)
    
    -- Call initialization method if it exists
    if instance and type(instance.Initialize) == "function" then
        local success, err = pcall(function()
            instance:Initialize()
        end)
        
        if not success then
            self.states[serviceName] = ServiceState.ERROR
            error("Failed to initialize service '" .. serviceName .. "': " .. tostring(err))
        end
    end
    
    self.states[serviceName] = ServiceState.INITIALIZED
    self.logger:Info("Service initialized: " .. serviceName)
end

function ServiceContainer:_startService(serviceName)
    if self.states[serviceName] == ServiceState.STARTED then
        return
    end
    
    local instance = self.instances[serviceName]
    if not instance then
        error("Service '" .. serviceName .. "' not initialized")
    end
    
    self.states[serviceName] = ServiceState.STARTING
    self.logger:Debug("Starting service: " .. serviceName)
    
    -- Call start method if it exists
    if type(instance.Start) == "function" then
        local success, err = pcall(function()
            instance:Start()
        end)
        
        if not success then
            self.states[serviceName] = ServiceState.ERROR
            error("Failed to start service '" .. serviceName .. "': " .. tostring(err))
        end
    end
    
    self.states[serviceName] = ServiceState.STARTED
    self.logger:Info("Service started: " .. serviceName)
end

function ServiceContainer:_stopService(serviceName)
    if self.states[serviceName] ~= ServiceState.STARTED then
        return
    end
    
    local instance = self.instances[serviceName]
    if not instance then
        return
    end
    
    self.states[serviceName] = ServiceState.STOPPING
    self.logger:Debug("Stopping service: " .. serviceName)
    
    -- Call stop method if it exists
    if type(instance.Stop) == "function" then
        local success, err = pcall(function()
            instance:Stop()
        end)
        
        if not success then
            self.logger:Error("Failed to stop service '" .. serviceName .. "': " .. tostring(err))
        end
    end
    
    self.states[serviceName] = ServiceState.STOPPED
    self.logger:Info("Service stopped: " .. serviceName)
end

function ServiceContainer:_calculateInitializationOrder()
    local visited = {}
    local visiting = {}
    local order = {}
    
    local function visit(serviceName)
        if visiting[serviceName] then
            error("Circular dependency detected involving service: " .. serviceName)
        end
        
        if visited[serviceName] then
            return
        end
        
        visiting[serviceName] = true
        
        -- Visit dependencies first
        local dependencies = self.dependencyGraph[serviceName] or {}
        for _, depName in ipairs(dependencies) do
            if self.services[depName] then
                visit(depName)
            else
                error("Unknown dependency '" .. depName .. "' for service '" .. serviceName .. "'")
            end
        end
        
        visiting[serviceName] = false
        visited[serviceName] = true
        table.insert(order, serviceName)
    end
    
    -- Visit all services
    for serviceName, _ in pairs(self.services) do
        visit(serviceName)
    end
    
    self.initOrder = order
    return order
end

function ServiceContainer:_validateServiceInterface(implementation, interface)
    for methodName, methodSignature in pairs(interface) do
        if not implementation[methodName] then
            error("Service implementation missing required method: " .. methodName)
        end
        
        if type(implementation[methodName]) ~= "function" then
            error("Service method '" .. methodName .. "' must be a function")
        end
    end
end

function ServiceContainer:_mergeConfig(default, override)
    local result = {}
    
    -- Copy default values
    for key, value in pairs(default) do
        if type(value) == "table" then
            result[key] = self:_mergeConfig(value, {})
        else
            result[key] = value
        end
    end
    
    -- Override with provided values
    for key, value in pairs(override) do
        if type(value) == "table" and type(result[key]) == "table" then
            result[key] = self:_mergeConfig(result[key], value)
        else
            result[key] = value
        end
    end
    
    return result
end

function ServiceContainer:_createLogger()
    local logger = {}
    
    function logger:Debug(message)
        print("[DEBUG][ServiceContainer] " .. message)
    end
    
    function logger:Info(message)
        print("[INFO][ServiceContainer] " .. message)
    end
    
    function logger:Warn(message)
        warn("[WARN][ServiceContainer] " .. message)
    end
    
    function logger:Error(message)
        error("[ERROR][ServiceContainer] " .. message)
    end
    
    return logger
end

-- ========================================
-- DIAGNOSTICS AND DEBUGGING
-- ========================================

function ServiceContainer:GetDiagnostics()
    local diagnostics = {
        registeredServices = {},
        serviceStates = {},
        dependencyGraph = self.dependencyGraph,
        initializationOrder = self.initOrder
    }
    
    for serviceName, config in pairs(self.services) do
        diagnostics.registeredServices[serviceName] = {
            dependencies = config.dependencies,
            autoStart = config.lifecycle.autoStart,
            singleton = config.singleton
        }
        diagnostics.serviceStates[serviceName] = self.states[serviceName]
    end
    
    return diagnostics
end

function ServiceContainer:PrintDiagnostics()
    local diagnostics = self:GetDiagnostics()
    
    print("=== SERVICE CONTAINER DIAGNOSTICS ===")
    print("Registered Services:", #self.services)
    
    print("\nService States:")
    for serviceName, state in pairs(diagnostics.serviceStates) do
        print("  " .. serviceName .. ": " .. state)
    end
    
    print("\nInitialization Order:")
    for i, serviceName in ipairs(diagnostics.initializationOrder) do
        print("  " .. i .. ". " .. serviceName)
    end
    
    print("\nDependency Graph:")
    for serviceName, deps in pairs(diagnostics.dependencyGraph) do
        if #deps > 0 then
            print("  " .. serviceName .. " -> " .. table.concat(deps, ", "))
        end
    end
    
    print("=====================================")
end

-- Export singleton instance
return ServiceContainer
