-- ModernServiceFramework.luau
-- Unified, modern service architecture with dependency injection, lifecycle management, and testing support
-- Replaces all legacy patterns: Services.Register(), ServiceBase.new(), and _G.GetService()

local _ReplicatedStorage = game:GetService("ReplicatedStorage")
local _RunService = game:GetService("RunService")

local ModernServiceFramework = {}

-- ========================================
-- SERVICE LIFECYCLE STATES
-- ========================================

local ServiceState = {
    UNREGISTERED = "Unregistered",
    REGISTERED = "Registered", 
    INITIALIZING = "Initializing",
    INITIALIZED = "Initialized",
    STARTING = "Starting",
    RUNNING = "Running",
    STOPPING = "Stopping",
    STOPPED = "Stopped",
    ERROR = "Error",
    DESTROYED = "Destroyed"
}

-- ========================================
-- DEPENDENCY INJECTION CONTAINER
-- ========================================

local DependencyContainer = {
    _singletons = {},
    _factories = {},
    _providers = {},
    _resolving = {} -- Circular dependency detection
}

function DependencyContainer:RegisterSingleton(interface, implementation)
    self._singletons[interface] = implementation
    return self
end

function DependencyContainer:RegisterFactory(interface, factory)
    self._factories[interface] = factory
    return self
end

function DependencyContainer:RegisterProvider(interface, provider)
    self._providers[interface] = provider
    return self
end

function DependencyContainer:Resolve(interface)
    -- Check for circular dependencies
    if self._resolving[interface] then
        error(string.format("Circular dependency detected: %s", interface))
    end
    
    self._resolving[interface] = true
    
    local result
    
    -- Try singleton first
    if self._singletons[interface] then
        result = self._singletons[interface]
    -- Try factory
    elseif self._factories[interface] then
        result = self._factories[interface]()
    -- Try provider
    elseif self._providers[interface] then
        result = self._providers[interface]:Provide()
    else
        error(string.format("No registration found for interface: %s", interface))
    end
    
    self._resolving[interface] = nil
    return result
end

-- ========================================
-- MODERN SERVICE BASE CLASS
-- ========================================

local ModernServiceBase = {}
ModernServiceBase.__index = ModernServiceBase

function ModernServiceBase.new(serviceName, config)
    local self = setmetatable({}, ModernServiceBase)
    
    -- Core properties
    self.ServiceName = serviceName
    self.State = ServiceState.REGISTERED
    self.Config = config or {}
    
    -- Lifecycle properties
    self.Priority = self.Config.Priority or 50
    self.Dependencies = self.Config.Dependencies or {}
    self.OptionalDependencies = self.Config.OptionalDependencies or {}
    
    -- Runtime properties
    self.InitializationTime = 0
    self.StartTime = 0
    self.LastError = nil
    self.ErrorCount = 0
    
    -- Connection management
    self.Connections = {}
    self.ConnectionGroups = {}
    
    -- Event system
    self.Events = {
        StateChanged = Instance.new("BindableEvent"),
        Error = Instance.new("BindableEvent"),
        Initialized = Instance.new("BindableEvent"),
        Started = Instance.new("BindableEvent"),
        Stopped = Instance.new("BindableEvent")
    }
    
    -- Metrics and monitoring
    self.Metrics = {
        OperationCount = 0,
        SuccessCount = 0,
        ErrorCount = 0,
        AverageResponseTime = 0,
        LastActivity = 0,
        TotalUptime = 0
    }
    
    -- Dependency injection
    self.InjectedDependencies = {}
    
    -- Testing support
    self.TestMode = self.Config.TestMode or false
    self.MockDependencies = self.Config.MockDependencies or {}
    
    return self
end

-- State management
function ModernServiceBase:SetState(newState)
    local oldState = self.State
    self.State = newState
    
    self.Events.StateChanged:Fire(newState, oldState)
    
    print(string.format("🔄 %s: %s → %s", self.ServiceName, oldState, newState))
end

-- Dependency injection
function ModernServiceBase:InjectDependencies()
    self:SetState(ServiceState.INITIALIZING)
    
    for _, dependency in ipairs(self.Dependencies) do
        if self.TestMode and self.MockDependencies[dependency] then
            self.InjectedDependencies[dependency] = self.MockDependencies[dependency]
        else
            local success, result = pcall(function()
                return DependencyContainer:Resolve(dependency)
            end)
            
            if success then
                self.InjectedDependencies[dependency] = result
            else
                self:HandleError(string.format("Failed to resolve dependency: %s - %s", dependency, result))
                return false
            end
        end
    end
    
    -- Inject optional dependencies
    for _, dependency in ipairs(self.OptionalDependencies) do
        local success, result = pcall(function()
            return DependencyContainer:Resolve(dependency)
        end)
        
        if success then
            self.InjectedDependencies[dependency] = result
        else
            print(string.format("⚠️ Optional dependency not available: %s", dependency))
        end
    end
    
    return true
end

-- Get injected dependency
function ModernServiceBase:GetDependency(dependencyName)
    return self.InjectedDependencies[dependencyName]
end

-- Connection management
function ModernServiceBase:CreateConnectionGroup(groupName)
    self.ConnectionGroups[groupName] = {}
    return self.ConnectionGroups[groupName]
end

function ModernServiceBase:AddConnection(connectionName, connection, groupName)
    self.Connections[connectionName] = connection
    
    if groupName and self.ConnectionGroups[groupName] then
        table.insert(self.ConnectionGroups[groupName], connection)
    end
    
    return connection
end

function ModernServiceBase:DisconnectGroup(groupName)
    local group = self.ConnectionGroups[groupName]
    if not group then return 0 end
    
    local count = 0
    for _, connection in ipairs(group) do
        if connection and connection.Connected then
            connection:Disconnect()
            count = count + 1
        end
    end
    
    self.ConnectionGroups[groupName] = {}
    return count
end

-- Error handling with boundaries
function ModernServiceBase:HandleError(errorMessage, critical)
    self.ErrorCount = self.ErrorCount + 1
    self.LastError = {
        message = errorMessage,
        timestamp = os.time(),
        critical = critical or false
    }
    
    self.Events.Error:Fire(errorMessage, critical)
    
    if critical then
        self:SetState(ServiceState.ERROR)
        warn(string.format("🚨 CRITICAL ERROR in %s: %s", self.ServiceName, errorMessage))
    else
        warn(string.format("⚠️ Error in %s: %s", self.ServiceName, errorMessage))
    end
end

-- Performance tracking
function ModernServiceBase:TrackOperation(operationName, operationFunction)
    local startTime = tick()
    self.Metrics.OperationCount = self.Metrics.OperationCount + 1
    self.Metrics.LastActivity = os.time()
    
    local success, result = pcall(operationFunction)
    
    local duration = tick() - startTime
    self.Metrics.AverageResponseTime = (self.Metrics.AverageResponseTime + duration) / 2
    
    if success then
        self.Metrics.SuccessCount = self.Metrics.SuccessCount + 1
        return true, result
    else
        self:HandleError(string.format("Operation '%s' failed: %s", operationName, result))
        return false, result
    end
end

-- Lifecycle methods (to be overridden)
function ModernServiceBase:Initialize()
    -- Override in derived services
end

function ModernServiceBase:Start()
    -- Override in derived services
end

function ModernServiceBase:Stop()
    -- Override in derived services
end

function ModernServiceBase:Cleanup()
    -- Disconnect all connections
    for _, connection in pairs(self.Connections) do
        if connection and connection.Connected then
            connection:Disconnect()
        end
    end
    
    for _, group in pairs(self.ConnectionGroups) do
        for _, connection in ipairs(group) do
            if connection and connection.Connected then
                connection:Disconnect()
            end
        end
    end
    
    -- Clean up events
    for _, event in pairs(self.Events) do
        event:Destroy()
    end
    
    self:SetState(ServiceState.DESTROYED)
end

-- ========================================
-- SERVICE REGISTRY AND MANAGER
-- ========================================

local ServiceRegistry = {
    _services = {},
    _initializationOrder = {},
    _running = {},
    _errorBoundaries = {}
}

-- Register a service class
function ServiceRegistry:RegisterService(serviceName, serviceClass, config)
    if self._services[serviceName] then
        warn(string.format("Service '%s' already registered, overwriting", serviceName))
    end
    
    local serviceConfig = config or {}
    serviceConfig.ServiceName = serviceName
    
    self._services[serviceName] = {
        class = serviceClass,
        config = serviceConfig,
        instance = nil,
        registered = os.time()
    }
    
    print(string.format("📝 Registered service: %s", serviceName))
    return self
end

-- Get or create service instance
function ServiceRegistry:GetService(serviceName)
    local serviceData = self._services[serviceName]
    if not serviceData then
        error(string.format("Service '%s' not registered", serviceName))
    end
    
    -- Return existing instance if available
    if serviceData.instance then
        return serviceData.instance
    end
    
    -- Create new instance
    local instance
    if type(serviceData.class) == "function" then
        instance = serviceData.class(serviceData.config)
    else
        instance = serviceData.class.new(serviceName, serviceData.config)
    end
    
    serviceData.instance = instance
    return instance
end

-- Initialize all services in dependency order
function ServiceRegistry:InitializeAll()
    print("🚀 Initializing all services in dependency order...")
    
    local initialized = {}
    local initialOrder = {}
    
    -- Topological sort for dependency resolution
    local function initializeService(serviceName)
        if initialized[serviceName] then
            return true
        end
        
        local serviceData = self._services[serviceName]
        if not serviceData then
            return false
        end
        
        local instance = self:GetService(serviceName)
        
        -- Initialize dependencies first
        if instance.Dependencies then
            for _, dependency in ipairs(instance.Dependencies) do
                if not initializeService(dependency) then
                    error(string.format("Failed to initialize dependency '%s' for service '%s'", dependency, serviceName))
                end
            end
        end
        
        -- Inject dependencies and initialize
        local dependencySuccess = instance:InjectDependencies()
        if not dependencySuccess then
            error(string.format("Failed to inject dependencies for service '%s'", serviceName))
        end
        
        -- Call initialize method
        local startTime = tick()
        local initSuccess, result = pcall(function()
            if instance.Initialize then
                instance:Initialize()
            end
        end)
        
        if initSuccess then
            initialized[serviceName] = true
            instance.InitializationTime = tick() - startTime
            instance:SetState(ServiceState.INITIALIZED)
            instance.Events.Initialized:Fire()
            table.insert(initialOrder, serviceName)
            print(string.format("✅ Initialized service: %s (%.3fs)", serviceName, instance.InitializationTime))
        else
            instance:HandleError(string.format("Initialization failed: %s", result), true)
            return false
        end
        
        return true
    end
    
    -- Initialize all registered services
    for serviceName, _ in pairs(self._services) do
        initializeService(serviceName)
    end
    
    self._initializationOrder = initialOrder
    print(string.format("🎉 Initialized %d services successfully", #initialOrder))
    
    return initialOrder
end

-- Start all services
function ServiceRegistry:StartAll()
    print("▶️ Starting all services...")
    
    for _, serviceName in ipairs(self._initializationOrder) do
        local instance = self:GetService(serviceName)
        
        if instance.State == ServiceState.INITIALIZED then
            local startTime = tick()
            local success, result = pcall(function()
                if instance.Start then
                    instance:Start()
                end
            end)
            
            if success then
                instance.StartTime = tick() - startTime
                instance:SetState(ServiceState.RUNNING)
                instance.Events.Started:Fire()
                self._running[serviceName] = instance
                print(string.format("▶️ Started service: %s", serviceName))
            else
                instance:HandleError(string.format("Start failed: %s", result), true)
            end
        end
    end
    
    print(string.format("🎊 Started %d services", #self._running))
end

-- Stop all services
function ServiceRegistry:StopAll()
    print("⏹️ Stopping all services...")
    
    local stopOrder = {}
    for i = #self._initializationOrder, 1, -1 do
        table.insert(stopOrder, self._initializationOrder[i])
    end
    
    for _, serviceName in ipairs(stopOrder) do
        local instance = self._running[serviceName]
        if instance then
            local success, result = pcall(function()
                instance:SetState(ServiceState.STOPPING)
                if instance.Stop then
                    instance:Stop()
                end
                instance:Cleanup()
            end)
            
            if success then
                instance:SetState(ServiceState.STOPPED)
                instance.Events.Stopped:Fire()
                self._running[serviceName] = nil
                print(string.format("⏹️ Stopped service: %s", serviceName))
            else
                instance:HandleError(string.format("Stop failed: %s", result), true)
            end
        end
    end
    
    print("🛑 All services stopped")
end

-- Health monitoring
function ServiceRegistry:GetHealthReport()
    local report = {
        timestamp = os.time(),
        totalServices = 0,
        runningServices = 0,
        errorServices = 0,
        services = {}
    }
    
    for serviceName, serviceData in pairs(self._services) do
        report.totalServices = report.totalServices + 1
        
        local instance = serviceData.instance
        if instance then
            local serviceReport = {
                name = serviceName,
                state = instance.State,
                uptime = instance.StartTime > 0 and (tick() - instance.StartTime) or 0,
                errorCount = instance.ErrorCount,
                lastError = instance.LastError,
                metrics = instance.Metrics
            }
            
            if instance.State == ServiceState.RUNNING then
                report.runningServices = report.runningServices + 1
            elseif instance.State == ServiceState.ERROR then
                report.errorServices = report.errorServices + 1
            end
            
            report.services[serviceName] = serviceReport
        end
    end
    
    return report
end

-- ========================================
-- TESTING FRAMEWORK INTEGRATION
-- ========================================

local TestingFramework = {}

function TestingFramework:CreateMockService(serviceName, mockImplementation)
    return setmetatable(mockImplementation or {}, {
        __index = function(_, key)
            return function() end -- Default no-op for undefined methods
        end
    })
end

function TestingFramework:CreateTestContainer()
    local testContainer = {
        _singletons = {},
        _mocks = {}
    }
    
    function testContainer:RegisterMock(interface, mock)
        self._mocks[interface] = mock
        return self
    end
    
    function testContainer:Resolve(interface)
        return self._mocks[interface] or error("Mock not found: " .. interface)
    end
    
    return testContainer
end

function TestingFramework:CreateTestService(serviceClass, testConfig)
    local config = testConfig or {}
    config.TestMode = true
    
    return serviceClass.new("TestService", config)
end

-- ========================================
-- MODERN SERVICE FRAMEWORK API
-- ========================================

-- Main API
function ModernServiceFramework.CreateService(serviceName, config)
    return ModernServiceBase.new(serviceName, config)
end

function ModernServiceFramework.RegisterService(serviceName, serviceClass, config)
    return ServiceRegistry:RegisterService(serviceName, serviceClass, config)
end

function ModernServiceFramework.GetService(serviceName)
    return ServiceRegistry:GetService(serviceName)
end

function ModernServiceFramework.InitializeAllServices()
    return ServiceRegistry:InitializeAll()
end

function ModernServiceFramework.StartAllServices()
    return ServiceRegistry:StartAll()
end

function ModernServiceFramework.StopAllServices()
    return ServiceRegistry:StopAll()
end

function ModernServiceFramework.GetHealthReport()
    return ServiceRegistry:GetHealthReport()
end

-- Dependency injection API
function ModernServiceFramework.RegisterSingleton(interface, implementation)
    return DependencyContainer:RegisterSingleton(interface, implementation)
end

function ModernServiceFramework.RegisterFactory(interface, factory)
    return DependencyContainer:RegisterFactory(interface, factory)
end

function ModernServiceFramework.Resolve(interface)
    return DependencyContainer:Resolve(interface)
end

-- Testing API
function ModernServiceFramework.CreateTestService(serviceClass, testConfig)
    return TestingFramework:CreateTestService(serviceClass, testConfig)
end

function ModernServiceFramework.CreateMockService(serviceName, mockImplementation)
    return TestingFramework:CreateMockService(serviceName, mockImplementation)
end

function ModernServiceFramework.CreateTestContainer()
    return TestingFramework:CreateTestContainer()
end

-- Export classes for inheritance
ModernServiceFramework.ServiceBase = ModernServiceBase
ModernServiceFramework.ServiceState = ServiceState
ModernServiceFramework.ServiceRegistry = ServiceRegistry
ModernServiceFramework.DependencyContainer = DependencyContainer
ModernServiceFramework.TestingFramework = TestingFramework

return ModernServiceFramework
