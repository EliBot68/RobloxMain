-- BaseService.luau
-- Base class for all services implementing dependency injection patterns
-- Provides common functionality and enforces service contracts

local ServiceInterface = require(script.Parent.ServiceInterface)

local BaseService = {}
BaseService.__index = BaseService

-- ========================================
-- BASE SERVICE IMPLEMENTATION
-- ========================================

function BaseService.new(name, dependencies)
    local self = setmetatable({}, BaseService)
    
    self.name = name or "UnnamedService"
    self.dependencies = {}
    self.requiredDependencies = dependencies or {}
    self.isInitialized = false
    self.isStarted = false
    self.status = "created"
    self.logger = self:_createLogger()
    
    return self
end

-- ========================================
-- CORE SERVICE METHODS (IService interface)
-- ========================================

function BaseService:Initialize()
    if self.isInitialized then
        self.logger:Warn("Service '" .. self.name .. "' is already initialized")
        return
    end
    
    self.logger:Info("Initializing service: " .. self.name)
    
    -- Validate required dependencies
    self:_validateDependencies()
    
    -- Call service-specific initialization
    if self.OnInitialize then
        local success, err = pcall(function()
            self:OnInitialize()
        end)
        
        if not success then
            self.status = "error"
            error("Failed to initialize service '" .. self.name .. "': " .. tostring(err))
        end
    end
    
    self.isInitialized = true
    self.status = "initialized"
    self.logger:Info("Service initialized: " .. self.name)
end

function BaseService:Start()
    if not self.isInitialized then
        error("Cannot start service '" .. self.name .. "' before initialization")
    end
    
    if self.isStarted then
        self.logger:Warn("Service '" .. self.name .. "' is already started")
        return
    end
    
    self.logger:Info("Starting service: " .. self.name)
    
    -- Call service-specific start logic
    if self.OnStart then
        local success, err = pcall(function()
            self:OnStart()
        end)
        
        if not success then
            self.status = "error"
            error("Failed to start service '" .. self.name .. "': " .. tostring(err))
        end
    end
    
    self.isStarted = true
    self.status = "started"
    self.logger:Info("Service started: " .. self.name)
end

function BaseService:Stop()
    if not self.isStarted then
        self.logger:Warn("Service '" .. self.name .. "' is not started")
        return
    end
    
    self.logger:Info("Stopping service: " .. self.name)
    
    -- Call service-specific stop logic
    if self.OnStop then
        local success, err = pcall(function()
            self:OnStop()
        end)
        
        if not success then
            self.logger:Error("Error stopping service '" .. self.name .. "': " .. tostring(err))
        end
    end
    
    self.isStarted = false
    self.status = "stopped"
    self.logger:Info("Service stopped: " .. self.name)
end

function BaseService:GetName()
    return self.name
end

function BaseService:GetStatus()
    return {
        name = self.name,
        status = self.status,
        isInitialized = self.isInitialized,
        isStarted = self.isStarted,
        dependencies = self:_getDependencyStatus()
    }
end

-- ========================================
-- DEPENDENCY MANAGEMENT
-- ========================================

function BaseService:SetDependency(dependencyName, dependency)
    if not dependency then
        error("Cannot set nil dependency '" .. dependencyName .. "' for service '" .. self.name .. "'")
    end
    
    self.dependencies[dependencyName] = dependency
    self.logger:Debug("Set dependency '" .. dependencyName .. "' for service '" .. self.name .. "'")
end

function BaseService:GetDependency(dependencyName)
    local dependency = self.dependencies[dependencyName]
    
    if not dependency then
        error("Dependency '" .. dependencyName .. "' not found for service '" .. self.name .. "'")
    end
    
    return dependency
end

function BaseService:TryGetDependency(dependencyName)
    return self.dependencies[dependencyName]
end

function BaseService:HasDependency(dependencyName)
    return self.dependencies[dependencyName] ~= nil
end

function BaseService:RequireDependency(dependencyName)
    table.insert(self.requiredDependencies, dependencyName)
end

-- ========================================
-- UTILITY METHODS
-- ========================================

function BaseService:Log(level, message)
    local timestamp = os.date("%H:%M:%S")
    local logMessage = string.format("[%s][%s][%s] %s", timestamp, level, self.name, message)
    
    if level == "ERROR" then
        error(logMessage)
    elseif level == "WARN" then
        warn(logMessage)
    else
        print(logMessage)
    end
end

function BaseService:LogDebug(message)
    self:Log("DEBUG", message)
end

function BaseService:LogInfo(message)
    self:Log("INFO", message)
end

function BaseService:LogWarn(message)
    self:Log("WARN", message)
end

function BaseService:LogError(message)
    self:Log("ERROR", message)
end

-- ========================================
-- HEALTH AND DIAGNOSTICS
-- ========================================

function BaseService:PerformHealthCheck()
    local health = {
        service = self.name,
        status = self.status,
        isHealthy = true,
        issues = {},
        metrics = {}
    }
    
    -- Check basic service state
    if not self.isInitialized then
        health.isHealthy = false
        table.insert(health.issues, "Service not initialized")
    end
    
    -- Check dependencies
    for _, depName in ipairs(self.requiredDependencies) do
        if not self.dependencies[depName] then
            health.isHealthy = false
            table.insert(health.issues, "Missing required dependency: " .. depName)
        end
    end
    
    -- Call service-specific health check
    if self.OnHealthCheck then
        local success, serviceHealth = pcall(function()
            return self:OnHealthCheck()
        end)
        
        if success and serviceHealth then
            if serviceHealth.isHealthy ~= nil then
                health.isHealthy = health.isHealthy and serviceHealth.isHealthy
            end
            
            if serviceHealth.issues then
                for _, issue in ipairs(serviceHealth.issues) do
                    table.insert(health.issues, issue)
                end
            end
            
            if serviceHealth.metrics then
                health.metrics = serviceHealth.metrics
            end
        else
            health.isHealthy = false
            table.insert(health.issues, "Health check failed: " .. tostring(serviceHealth))
        end
    end
    
    return health
end

function BaseService:GetMetrics()
    local metrics = {
        service = self.name,
        status = self.status,
        uptime = self.isStarted and (tick() - (self.startTime or 0)) or 0,
        memoryUsage = self:_calculateMemoryUsage()
    }
    
    -- Add service-specific metrics
    if self.OnGetMetrics then
        local success, serviceMetrics = pcall(function()
            return self:OnGetMetrics()
        end)
        
        if success and serviceMetrics then
            for key, value in pairs(serviceMetrics) do
                metrics[key] = value
            end
        end
    end
    
    return metrics
end

-- ========================================
-- PRIVATE HELPER METHODS
-- ========================================

function BaseService:_validateDependencies()
    for _, dependencyName in ipairs(self.requiredDependencies) do
        if not self.dependencies[dependencyName] then
            error("Required dependency '" .. dependencyName .. "' not provided for service '" .. self.name .. "'")
        end
    end
end

function BaseService:_getDependencyStatus()
    local status = {}
    
    for depName, dependency in pairs(self.dependencies) do
        if dependency and type(dependency.GetStatus) == "function" then
            status[depName] = dependency:GetStatus()
        else
            status[depName] = "available"
        end
    end
    
    return status
end

function BaseService:_calculateMemoryUsage()
    -- Basic memory usage calculation
    -- This would be enhanced with actual memory profiling in production
    return {
        objects = self:_countTrackedObjects(),
        connections = self:_countConnections(),
        approximateSize = "unknown" -- Would implement actual memory measurement
    }
end

function BaseService:_countTrackedObjects()
    local count = 0
    
    -- Count properties that are likely to be tracked objects
    for key, value in pairs(self) do
        if type(value) == "table" or type(value) == "userdata" then
            count = count + 1
        end
    end
    
    return count
end

function BaseService:_countConnections()
    local count = 0
    
    -- This would be enhanced to actually count RBXScriptConnections
    -- For now, just return a placeholder
    return count
end

function BaseService:_createLogger()
    local logger = {}
    
    function logger:Debug(message)
        print("[DEBUG][" .. self.name .. "] " .. message)
    end
    
    function logger:Info(message)
        print("[INFO][" .. self.name .. "] " .. message)
    end
    
    function logger:Warn(message)
        warn("[WARN][" .. self.name .. "] " .. message)
    end
    
    function logger:Error(message)
        error("[ERROR][" .. self.name .. "] " .. message)
    end
    
    return logger
end

-- ========================================
-- VIRTUAL METHODS (Override in subclasses)
-- ========================================

-- Override this method in service implementations
function BaseService:OnInitialize()
    -- Service-specific initialization logic
end

-- Override this method in service implementations
function BaseService:OnStart()
    -- Service-specific start logic
end

-- Override this method in service implementations  
function BaseService:OnStop()
    -- Service-specific stop logic
end

-- Override this method for custom health checks
function BaseService:OnHealthCheck()
    return {
        isHealthy = true,
        issues = {},
        metrics = {}
    }
end

-- Override this method for custom metrics
function BaseService:OnGetMetrics()
    return {}
end

-- ========================================
-- INTERFACE VALIDATION
-- ========================================

function BaseService:ValidateInterface(interface)
    local isValid, errors = ServiceInterface.ValidateImplementation(self, interface)
    
    if not isValid then
        error("Service '" .. self.name .. "' does not implement required interface:\n" .. table.concat(errors, "\n"))
    end
    
    return true
end

return BaseService
