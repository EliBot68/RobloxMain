-- ServiceArchitecture.luau
-- Core service architecture framework for clean, modular service design
-- Implements interfaces, contracts, and composition patterns

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local HttpService = game:GetService("HttpService")

local ServiceArchitecture = {}

-- ========================================
-- SERVICE INTERFACE CONTRACTS
-- ========================================

-- Base service interface that all services must implement
local IService = {}

function IService:GetServiceName()
    error("GetServiceName must be implemented by service")
end

function IService:GetVersion()
    error("GetVersion must be implemented by service")
end

function IService:GetHealthStatus()
    error("GetHealthStatus must be implemented by service")
end

function IService:Initialize()
    error("Initialize must be implemented by service")
end

function IService:Start()
    error("Start must be implemented by service")
end

function IService:Stop()
    error("Stop must be implemented by service")
end

function IService:GetDependencies()
    return {} -- Override to specify dependencies
end

ServiceArchitecture.IService = IService

-- ========================================
-- DATA LAYER INTERFACES
-- ========================================

-- Repository pattern interface for data access
local IRepository = {}

function IRepository:Create(data)
    error("Create must be implemented by repository")
end

function IRepository:GetById(id)
    error("GetById must be implemented by repository")
end

function IRepository:Update(id, data)
    error("Update must be implemented by repository")
end

function IRepository:Delete(id)
    error("Delete must be implemented by repository")
end

function IRepository:GetAll(filters)
    error("GetAll must be implemented by repository")
end

function IRepository:Count(filters)
    error("Count must be implemented by repository")
end

ServiceArchitecture.IRepository = IRepository

-- ========================================
-- BUSINESS LOGIC LAYER INTERFACES
-- ========================================

-- Domain service interface for business logic
local IDomainService = {}

function IDomainService:ValidateInput(input)
    error("ValidateInput must be implemented by domain service")
end

function IDomainService:ProcessRequest(request)
    error("ProcessRequest must be implemented by domain service")
end

function IDomainService:GetBusinessRules()
    error("GetBusinessRules must be implemented by domain service")
end

ServiceArchitecture.IDomainService = IDomainService

-- ========================================
-- PRESENTATION LAYER INTERFACES
-- ========================================

-- Controller interface for handling requests
local IController = {}

function IController:HandleRequest(request, context)
    error("HandleRequest must be implemented by controller")
end

function IController:ValidateRequest(request)
    error("ValidateRequest must be implemented by controller")
end

function IController:FormatResponse(data)
    error("FormatResponse must be implemented by controller")
end

ServiceArchitecture.IController = IController

-- ========================================
-- SERVICE COMPOSITION PATTERNS
-- ========================================

-- Service aggregator for combining multiple services
local ServiceAggregator = {}
ServiceAggregator.__index = ServiceAggregator

function ServiceAggregator.new(name, services)
    local self = setmetatable({}, ServiceAggregator)
    self.name = name
    self.services = services or {}
    self.dependencies = {}
    self.isInitialized = false
    self.isStarted = false
    return self
end

function ServiceAggregator:AddService(name, service)
    self.services[name] = service
    
    -- Collect dependencies
    if service.GetDependencies then
        local deps = service:GetDependencies()
        for _, dep in ipairs(deps) do
            self.dependencies[dep] = true
        end
    end
end

function ServiceAggregator:GetService(name)
    return self.services[name]
end

function ServiceAggregator:Initialize()
    if self.isInitialized then return end
    
    print("🏗️ Initializing service aggregator: " .. self.name)
    
    -- Initialize services in dependency order
    local initialized = {}
    local function initializeService(name, service)
        if initialized[name] then return end
        
        -- Initialize dependencies first
        if service.GetDependencies then
            for _, depName in ipairs(service:GetDependencies()) do
                local depService = self.services[depName]
                if depService then
                    initializeService(depName, depService)
                end
            end
        end
        
        if service.Initialize then
            service:Initialize()
        end
        initialized[name] = true
        print("  ✅ Initialized service: " .. name)
    end
    
    for name, service in pairs(self.services) do
        initializeService(name, service)
    end
    
    self.isInitialized = true
    print("✅ Service aggregator initialized: " .. self.name)
end

function ServiceAggregator:Start()
    if not self.isInitialized then
        self:Initialize()
    end
    
    if self.isStarted then return end
    
    print("🚀 Starting service aggregator: " .. self.name)
    
    for name, service in pairs(self.services) do
        if service.Start then
            service:Start()
            print("  ▶️ Started service: " .. name)
        end
    end
    
    self.isStarted = true
    print("✅ Service aggregator started: " .. self.name)
end

function ServiceAggregator:Stop()
    if not self.isStarted then return end
    
    print("🛑 Stopping service aggregator: " .. self.name)
    
    for name, service in pairs(self.services) do
        if service.Stop then
            service:Stop()
            print("  ⏹️ Stopped service: " .. name)
        end
    end
    
    self.isStarted = false
    print("✅ Service aggregator stopped: " .. self.name)
end

function ServiceAggregator:GetHealthStatus()
    local status = {
        name = self.name,
        isHealthy = true,
        services = {},
        timestamp = tick()
    }
    
    for name, service in pairs(self.services) do
        local serviceStatus = {
            name = name,
            isHealthy = true,
            status = "Unknown",
            version = "Unknown"
        }
        
        if service.GetHealthStatus then
            local success, result = pcall(service.GetHealthStatus, service)
            if success then
                serviceStatus.isHealthy = result.isHealthy
                serviceStatus.status = result.status
            else
                serviceStatus.isHealthy = false
                serviceStatus.status = "Error: " .. tostring(result)
            end
        end
        
        if service.GetVersion then
            local success, version = pcall(service.GetVersion, service)
            if success then
                serviceStatus.version = version
            end
        end
        
        status.services[name] = serviceStatus
        
        if not serviceStatus.isHealthy then
            status.isHealthy = false
        end
    end
    
    return status
end

ServiceArchitecture.ServiceAggregator = ServiceAggregator

-- ========================================
-- BASE SERVICE IMPLEMENTATION
-- ========================================

-- Base service class implementing common functionality
local BaseService = {}
BaseService.__index = BaseService

function BaseService.new(name, version)
    local self = setmetatable({}, BaseService)
    self.serviceName = name
    self.version = version or "1.0.0"
    self.isInitialized = false
    self.isStarted = false
    self.healthStatus = {
        isHealthy = true,
        status = "Created",
        lastCheck = tick(),
        metrics = {}
    }
    self.dependencies = {}
    self.events = {}
    return self
end

function BaseService:GetServiceName()
    return self.serviceName
end

function BaseService:GetVersion()
    return self.version
end

function BaseService:GetDependencies()
    return self.dependencies
end

function BaseService:SetDependencies(deps)
    self.dependencies = deps
end

function BaseService:GetHealthStatus()
    self.healthStatus.lastCheck = tick()
    return self.healthStatus
end

function BaseService:UpdateHealthStatus(isHealthy, status, metrics)
    self.healthStatus.isHealthy = isHealthy
    self.healthStatus.status = status
    self.healthStatus.lastCheck = tick()
    self.healthStatus.metrics = metrics or {}
end

function BaseService:Initialize()
    if self.isInitialized then return end
    
    print("🔧 Initializing service: " .. self.serviceName)
    
    -- Call child implementation
    if self._initialize then
        self:_initialize()
    end
    
    self.isInitialized = true
    self:UpdateHealthStatus(true, "Initialized")
    
    print("✅ Service initialized: " .. self.serviceName)
end

function BaseService:Start()
    if not self.isInitialized then
        self:Initialize()
    end
    
    if self.isStarted then return end
    
    print("🚀 Starting service: " .. self.serviceName)
    
    -- Call child implementation
    if self._start then
        self:_start()
    end
    
    self.isStarted = true
    self:UpdateHealthStatus(true, "Running")
    
    print("✅ Service started: " .. self.serviceName)
end

function BaseService:Stop()
    if not self.isStarted then return end
    
    print("🛑 Stopping service: " .. self.serviceName)
    
    -- Call child implementation
    if self._stop then
        self:_stop()
    end
    
    self.isStarted = false
    self:UpdateHealthStatus(true, "Stopped")
    
    print("✅ Service stopped: " .. self.serviceName)
end

function BaseService:AddEvent(eventName, handler)
    if not self.events[eventName] then
        self.events[eventName] = {}
    end
    table.insert(self.events[eventName], handler)
end

function BaseService:TriggerEvent(eventName, ...)
    local handlers = self.events[eventName]
    if handlers then
        for _, handler in ipairs(handlers) do
            local success, result = pcall(handler, ...)
            if not success then
                warn("❌ Event handler error in " .. self.serviceName .. "." .. eventName .. ": " .. tostring(result))
            end
        end
    end
end

ServiceArchitecture.BaseService = BaseService

-- ========================================
-- SERVICE FACTORY
-- ========================================

-- Factory for creating services with proper setup
local ServiceFactory = {}

function ServiceFactory.CreateService(serviceType, config)
    local service = BaseService.new(config.name, config.version)
    
    -- Apply configuration
    if config.dependencies then
        service:SetDependencies(config.dependencies)
    end
    
    -- Add custom methods
    if config.methods then
        for methodName, method in pairs(config.methods) do
            service[methodName] = method
        end
    end
    
    -- Add initialization logic
    if config.initialize then
        service._initialize = config.initialize
    end
    
    -- Add start logic
    if config.start then
        service._start = config.start
    end
    
    -- Add stop logic
    if config.stop then
        service._stop = config.stop
    end
    
    return service
end

ServiceArchitecture.ServiceFactory = ServiceFactory

-- ========================================
-- DECORATOR PATTERNS
-- ========================================

-- Service decorator for adding cross-cutting concerns
local ServiceDecorator = {}

function ServiceDecorator.WithLogging(service, logger)
    local originalMethods = {}
    
    -- Wrap public methods with logging
    for methodName, method in pairs(service) do
        if type(method) == "function" and not methodName:find("^_") and methodName ~= "GetServiceName" and methodName ~= "GetVersion" then
            originalMethods[methodName] = method
            service[methodName] = function(self, ...)
                local startTime = tick()
                logger:Debug("Method called", {
                    service = service:GetServiceName(),
                    method = methodName,
                    args = {...}
                })
                
                local success, result = pcall(originalMethods[methodName], self, ...)
                local duration = tick() - startTime
                
                if success then
                    logger:Debug("Method completed", {
                        service = service:GetServiceName(),
                        method = methodName,
                        duration = duration,
                        result = result
                    })
                    return result
                else
                    logger:Error("Method failed", {
                        service = service:GetServiceName(),
                        method = methodName,
                        duration = duration,
                        error = result
                    })
                    error(result)
                end
            end
        end
    end
    
    return service
end

function ServiceDecorator.WithRetry(service, maxRetries, delay)
    maxRetries = maxRetries or 3
    delay = delay or 1
    
    local originalMethods = {}
    
    for methodName, method in pairs(service) do
        if type(method) == "function" and not methodName:find("^_") and methodName ~= "GetServiceName" and methodName ~= "GetVersion" then
            originalMethods[methodName] = method
            service[methodName] = function(self, ...)
                local attempts = 0
                while attempts < maxRetries do
                    attempts = attempts + 1
                    local success, result = pcall(originalMethods[methodName], self, ...)
                    
                    if success then
                        return result
                    elseif attempts < maxRetries then
                        warn("⚠️ Retrying " .. service:GetServiceName() .. "." .. methodName .. " (attempt " .. attempts .. "/" .. maxRetries .. ")")
                        wait(delay)
                    else
                        error("❌ " .. service:GetServiceName() .. "." .. methodName .. " failed after " .. maxRetries .. " attempts: " .. tostring(result))
                    end
                end
            end
        end
    end
    
    return service
end

function ServiceDecorator.WithCaching(service, cacheTimeout)
    cacheTimeout = cacheTimeout or 60
    local cache = {}
    local cacheTimestamps = {}
    
    local originalMethods = {}
    
    for methodName, method in pairs(service) do
        if type(method) == "function" and methodName:find("^Get") then
            originalMethods[methodName] = method
            service[methodName] = function(self, ...)
                local args = {...}
                local cacheKey = methodName .. "_" .. HttpService:JSONEncode(args)
                local now = tick()
                
                -- Check cache
                if cache[cacheKey] and cacheTimestamps[cacheKey] and 
                   (now - cacheTimestamps[cacheKey]) < cacheTimeout then
                    return cache[cacheKey]
                end
                
                -- Execute method and cache result
                local result = originalMethods[methodName](self, unpack(args))
                cache[cacheKey] = result
                cacheTimestamps[cacheKey] = now
                
                return result
            end
        end
    end
    
    return service
end

ServiceArchitecture.ServiceDecorator = ServiceDecorator

return ServiceArchitecture
