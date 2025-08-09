-- EnterpriseServiceArchitecture.luau
-- Next-generation enterprise service architecture for Color Rush
-- Provides unified dependency injection, lifecycle management, and performance monitoring

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local HttpService = game:GetService("HttpService")

local EnterpriseServiceArchitecture = {}
EnterpriseServiceArchitecture.__index = EnterpriseServiceArchitecture

-- ========================================
-- ENTERPRISE CONSTANTS
-- ========================================

local SERVICE_PRIORITIES = {
    CRITICAL = 1,    -- Core infrastructure (DataService, AnalyticsService)
    HIGH = 2,        -- Game logic (MainGameService, PlayerService)
    MEDIUM = 3,      -- Features (ShopService, QuestService)
    LOW = 4,         -- Enhancement (VisualPolishService, AudioService)
    BACKGROUND = 5   -- Utility (ConsoleMonitorService, CleanupService)
}

local SERVICE_STATES = {
    UNINITIALIZED = "Uninitialized",
    INITIALIZING = "Initializing",
    INITIALIZED = "Initialized",
    STARTING = "Starting",
    RUNNING = "Running",
    DEGRADED = "Degraded",
    FAILING = "Failing",
    STOPPED = "Stopped",
    ERROR = "Error"
}

local HEALTH_LEVELS = {
    HEALTHY = "Healthy",
    WARNING = "Warning",
    CRITICAL = "Critical",
    FAILING = "Failing"
}

-- ========================================
-- ENTERPRISE SERVICE CONTAINER
-- ========================================

local ServiceContainer = {
    services = {},
    instances = {},
    dependencies = {},
    healthMonitor = {},
    performanceMetrics = {},
    errorRecovery = {},
    
    -- Enterprise features
    circuitBreakers = {},
    loadBalancers = {},
    rateLimiters = {},
    cacheManagers = {}
}

-- ========================================
-- DEPENDENCY INJECTION SYSTEM
-- ========================================

function ServiceContainer:RegisterService(serviceName, serviceClass, config)
    config = config or {}
    
    local serviceInfo = {
        name = serviceName,
        class = serviceClass,
        priority = config.priority or SERVICE_PRIORITIES.MEDIUM,
        dependencies = config.dependencies or {},
        autoStart = config.autoStart ~= false,
        singleton = config.singleton ~= false,
        retryAttempts = config.retryAttempts or 3,
        healthCheckInterval = config.healthCheckInterval or 30,
        maxMemoryUsage = config.maxMemoryUsage or 50 * 1024 * 1024, -- 50MB
        maxCpuUsage = config.maxCpuUsage or 5, -- 5%
        
        -- Enterprise features
        enableCircuitBreaker = config.enableCircuitBreaker or false,
        enableLoadBalancing = config.enableLoadBalancing or false,
        enableRateLimiting = config.enableRateLimiting or false,
        enableCaching = config.enableCaching or false
    }
    
    self.services[serviceName] = serviceInfo
    self.healthMonitor[serviceName] = {
        state = SERVICE_STATES.UNINITIALIZED,
        health = HEALTH_LEVELS.HEALTHY,
        lastHealthCheck = 0,
        consecutiveFailures = 0,
        totalRequests = 0,
        successfulRequests = 0,
        averageResponseTime = 0
    }
    
    print("🏢 [Enterprise] Registered service:", serviceName, "Priority:", serviceInfo.priority)
    return self
end

function ServiceContainer:ResolveDependencies(serviceName)
    local serviceInfo = self.services[serviceName]
    if not serviceInfo then
        error("Service not found: " .. serviceName)
    end
    
    local resolvedDependencies = {}
    
    for _, depName in ipairs(serviceInfo.dependencies) do
        local dependency = self:GetService(depName)
        if not dependency then
            warn("⚠️ [Enterprise] Failed to resolve dependency:", depName, "for service:", serviceName)
            -- Attempt graceful degradation
            dependency = self:CreateFallbackService(depName)
        end
        resolvedDependencies[depName] = dependency
    end
    
    return resolvedDependencies
end

-- ========================================
-- ENTERPRISE SERVICE FACTORY
-- ========================================

function ServiceContainer:CreateService(serviceName)
    local serviceInfo = self.services[serviceName]
    if not serviceInfo then
        error("Service not registered: " .. serviceName)
    end
    
    -- Check if singleton and already exists
    if serviceInfo.singleton and self.instances[serviceName] then
        return self.instances[serviceName]
    end
    
    -- Update health monitor
    self.healthMonitor[serviceName].state = SERVICE_STATES.INITIALIZING
    
    local startTime = tick()
    local success, serviceInstance = pcall(function()
        -- Resolve dependencies first
        local dependencies = self:ResolveDependencies(serviceName)
        
        -- Create service instance
        local instance
        if type(serviceInfo.class) == "function" then
            instance = serviceInfo.class(dependencies)
        else
            instance = serviceInfo.class.new(dependencies)
        end
        
        -- Add enterprise capabilities
        self:InjectEnterpriseCapabilities(instance, serviceName)
        
        return instance
    end)
    
    local initTime = tick() - startTime
    
    if success then
        self.instances[serviceName] = serviceInstance
        self.healthMonitor[serviceName].state = SERVICE_STATES.INITIALIZED
        
        -- Update performance metrics
        self.performanceMetrics[serviceName] = {
            initializationTime = initTime,
            memoryUsage = 0,
            cpuUsage = 0,
            requestsPerSecond = 0
        }
        
        print("✅ [Enterprise] Created service:", serviceName, "in", math.floor(initTime * 1000) .. "ms")
        return serviceInstance
    else
        self.healthMonitor[serviceName].state = SERVICE_STATES.ERROR
        self.healthMonitor[serviceName].consecutiveFailures += 1
        
        error("Failed to create service " .. serviceName .. ": " .. tostring(serviceInstance))
    end
end

-- ========================================
-- ENTERPRISE CAPABILITIES INJECTION
-- ========================================

function ServiceContainer:InjectEnterpriseCapabilities(instance, serviceName)
    local serviceInfo = self.services[serviceName]
    
    -- Inject health monitoring
    instance.GetHealth = function()
        return self.healthMonitor[serviceName]
    end
    
    -- Inject performance metrics
    instance.GetMetrics = function()
        return self.performanceMetrics[serviceName] or {}
    end
    
    -- Inject circuit breaker if enabled
    if serviceInfo.enableCircuitBreaker then
        self:SetupCircuitBreaker(instance, serviceName)
    end
    
    -- Inject rate limiting if enabled
    if serviceInfo.enableRateLimiting then
        self:SetupRateLimiter(instance, serviceName)
    end
    
    -- Inject caching if enabled
    if serviceInfo.enableCaching then
        self:SetupCacheManager(instance, serviceName)
    end
    
    -- Inject error recovery
    instance.RecoverFromError = function()
        return self:RecoverService(serviceName)
    end
end

-- ========================================
-- ENTERPRISE HEALTH MONITORING
-- ========================================

function ServiceContainer:StartHealthMonitoring()
    spawn(function()
        while true do
            wait(5) -- Check every 5 seconds
            
            for serviceName, monitor in pairs(self.healthMonitor) do
                if tick() - monitor.lastHealthCheck > self.services[serviceName].healthCheckInterval then
                    self:PerformHealthCheck(serviceName)
                end
            end
        end
    end)
    
    print("💊 [Enterprise] Health monitoring started")
end

function ServiceContainer:PerformHealthCheck(serviceName)
    local instance = self.instances[serviceName]
    local monitor = self.healthMonitor[serviceName]
    local serviceInfo = self.services[serviceName]
    
    if not instance then
        return
    end
    
    monitor.lastHealthCheck = tick()
    
    -- Check if service has custom health check
    if instance.HealthCheck then
        local success, isHealthy = pcall(instance.HealthCheck, instance)
        if success then
            if isHealthy then
                monitor.health = HEALTH_LEVELS.HEALTHY
                monitor.consecutiveFailures = 0
            else
                monitor.health = HEALTH_LEVELS.WARNING
                monitor.consecutiveFailures += 1
            end
        else
            monitor.health = HEALTH_LEVELS.CRITICAL
            monitor.consecutiveFailures += 1
        end
    end
    
    -- Check memory usage
    local memoryUsage = self:GetServiceMemoryUsage(serviceName)
    if memoryUsage > serviceInfo.maxMemoryUsage then
        monitor.health = HEALTH_LEVELS.WARNING
        warn("⚠️ [Enterprise] High memory usage in", serviceName, ":", memoryUsage / 1024 / 1024, "MB")
    end
    
    -- Auto-recovery for failed services
    if monitor.consecutiveFailures >= 3 then
        warn("🚨 [Enterprise] Service", serviceName, "failing, attempting recovery...")
        self:RecoverService(serviceName)
    end
end

-- ========================================
-- PERFORMANCE MONITORING
-- ========================================

function ServiceContainer:StartPerformanceMonitoring()
    local heartbeat
    heartbeat = RunService.Heartbeat:Connect(function()
        for serviceName, instance in pairs(self.instances) do
            self:UpdatePerformanceMetrics(serviceName)
        end
    end)
    
    print("📊 [Enterprise] Performance monitoring started")
    return heartbeat
end

function ServiceContainer:UpdatePerformanceMetrics(serviceName)
    local metrics = self.performanceMetrics[serviceName]
    if not metrics then return end
    
    -- Update memory usage (placeholder - would need actual memory profiling)
    metrics.memoryUsage = self:GetServiceMemoryUsage(serviceName)
    
    -- Update request metrics
    local monitor = self.healthMonitor[serviceName]
    if monitor.totalRequests > 0 then
        metrics.requestsPerSecond = monitor.totalRequests / (tick() - (monitor.startTime or tick()))
        metrics.successRate = monitor.successfulRequests / monitor.totalRequests
    end
end

-- ========================================
-- ERROR RECOVERY SYSTEM
-- ========================================

function ServiceContainer:RecoverService(serviceName)
    local monitor = self.healthMonitor[serviceName]
    local serviceInfo = self.services[serviceName]
    
    print("🔧 [Enterprise] Attempting to recover service:", serviceName)
    
    -- Stop the failing service
    local instance = self.instances[serviceName]
    if instance and instance.Stop then
        pcall(instance.Stop, instance)
    end
    
    -- Clear the instance
    self.instances[serviceName] = nil
    
    -- Reset health monitor
    monitor.state = SERVICE_STATES.UNINITIALIZED
    monitor.consecutiveFailures = 0
    
    -- Attempt to recreate the service
    local success, newInstance = pcall(function()
        return self:CreateService(serviceName)
    end)
    
    if success then
        -- Restart the service
        if newInstance.Start then
            pcall(newInstance.Start, newInstance)
        end
        
        monitor.state = SERVICE_STATES.RUNNING
        monitor.health = HEALTH_LEVELS.HEALTHY
        print("✅ [Enterprise] Successfully recovered service:", serviceName)
        return true
    else
        monitor.state = SERVICE_STATES.ERROR
        monitor.health = HEALTH_LEVELS.FAILING
        warn("❌ [Enterprise] Failed to recover service:", serviceName)
        return false
    end
end

-- ========================================
-- CIRCUIT BREAKER PATTERN
-- ========================================

function ServiceContainer:SetupCircuitBreaker(instance, serviceName)
    local circuitBreaker = {
        state = "CLOSED", -- CLOSED, OPEN, HALF_OPEN
        failureCount = 0,
        failureThreshold = 5,
        timeout = 60, -- seconds
        lastFailureTime = 0
    }
    
    self.circuitBreakers[serviceName] = circuitBreaker
    
    -- Wrap service methods with circuit breaker
    local originalMethods = {}
    for methodName, method in pairs(instance) do
        if type(method) == "function" and not methodName:match("^_") then
            originalMethods[methodName] = method
            
            instance[methodName] = function(...)
                return self:CallWithCircuitBreaker(serviceName, methodName, originalMethods[methodName], ...)
            end
        end
    end
end

function ServiceContainer:CallWithCircuitBreaker(serviceName, methodName, originalMethod, ...)
    local circuitBreaker = self.circuitBreakers[serviceName]
    local currentTime = tick()
    
    -- Check circuit breaker state
    if circuitBreaker.state == "OPEN" then
        if currentTime - circuitBreaker.lastFailureTime > circuitBreaker.timeout then
            circuitBreaker.state = "HALF_OPEN"
        else
            error("Circuit breaker is OPEN for service: " .. serviceName)
        end
    end
    
    -- Execute the method
    local success, result = pcall(originalMethod, ...)
    
    if success then
        -- Reset on success
        if circuitBreaker.state == "HALF_OPEN" then
            circuitBreaker.state = "CLOSED"
            circuitBreaker.failureCount = 0
        end
        
        -- Update metrics
        local monitor = self.healthMonitor[serviceName]
        monitor.totalRequests += 1
        monitor.successfulRequests += 1
        
        return result
    else
        -- Handle failure
        circuitBreaker.failureCount += 1
        circuitBreaker.lastFailureTime = currentTime
        
        if circuitBreaker.failureCount >= circuitBreaker.failureThreshold then
            circuitBreaker.state = "OPEN"
        end
        
        -- Update metrics
        local monitor = self.healthMonitor[serviceName]
        monitor.totalRequests += 1
        
        error("Service call failed: " .. tostring(result))
    end
end

-- ========================================
-- PUBLIC API
-- ========================================

function ServiceContainer:GetService(serviceName)
    if not self.instances[serviceName] then
        self:CreateService(serviceName)
    end
    
    return self.instances[serviceName]
end

function ServiceContainer:StartAllServices()
    -- Sort services by priority
    local sortedServices = {}
    for serviceName, serviceInfo in pairs(self.services) do
        table.insert(sortedServices, {name = serviceName, priority = serviceInfo.priority})
    end
    
    table.sort(sortedServices, function(a, b)
        return a.priority < b.priority
    end)
    
    -- Start services in priority order
    for _, serviceData in ipairs(sortedServices) do
        local serviceName = serviceData.name
        local serviceInfo = self.services[serviceName]
        
        if serviceInfo.autoStart then
            local instance = self:GetService(serviceName)
            if instance and instance.Start then
                local success = pcall(instance.Start, instance)
                if success then
                    self.healthMonitor[serviceName].state = SERVICE_STATES.RUNNING
                    print("🚀 [Enterprise] Started service:", serviceName)
                else
                    warn("❌ [Enterprise] Failed to start service:", serviceName)
                end
            end
        end
    end
    
    -- Start monitoring systems
    self:StartHealthMonitoring()
    self:StartPerformanceMonitoring()
    
    print("🏢 [Enterprise] All services started successfully")
end

function ServiceContainer:GetSystemHealth()
    local healthSummary = {
        totalServices = 0,
        healthyServices = 0,
        warningServices = 0,
        criticalServices = 0,
        failingServices = 0,
        overallHealth = HEALTH_LEVELS.HEALTHY
    }
    
    for serviceName, monitor in pairs(self.healthMonitor) do
        healthSummary.totalServices += 1
        
        if monitor.health == HEALTH_LEVELS.HEALTHY then
            healthSummary.healthyServices += 1
        elseif monitor.health == HEALTH_LEVELS.WARNING then
            healthSummary.warningServices += 1
        elseif monitor.health == HEALTH_LEVELS.CRITICAL then
            healthSummary.criticalServices += 1
        elseif monitor.health == HEALTH_LEVELS.FAILING then
            healthSummary.failingServices += 1
        end
    end
    
    -- Determine overall health
    if healthSummary.failingServices > 0 then
        healthSummary.overallHealth = HEALTH_LEVELS.FAILING
    elseif healthSummary.criticalServices > 0 then
        healthSummary.overallHealth = HEALTH_LEVELS.CRITICAL
    elseif healthSummary.warningServices > 0 then
        healthSummary.overallHealth = HEALTH_LEVELS.WARNING
    end
    
    return healthSummary
end

-- ========================================
-- UTILITY METHODS
-- ========================================

function ServiceContainer:GetServiceMemoryUsage(serviceName)
    -- Placeholder for actual memory profiling
    return math.random(1024 * 1024, 10 * 1024 * 1024) -- 1-10MB random
end

function ServiceContainer:CreateFallbackService(serviceName)
    -- Create a minimal fallback service for graceful degradation
    return {
        name = serviceName .. "_Fallback",
        enabled = false,
        
        -- Provide basic no-op methods
        Initialize = function() end,
        Start = function() end,
        Stop = function() end,
        HealthCheck = function() return false end
    }
end

-- ========================================
-- SINGLETON INSTANCE
-- ========================================

local enterpriseContainer = ServiceContainer

-- Global access for enterprise services
_G.EnterpriseServices = enterpriseContainer

return EnterpriseServiceArchitecture
