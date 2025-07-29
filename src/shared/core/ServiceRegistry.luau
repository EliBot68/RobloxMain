-- ServiceRegistry.luau
-- Service discovery and registration system with health monitoring
-- Manages service lifecycle, dependencies, and status reporting

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local HttpService = game:GetService("HttpService")

local ServiceRegistry = {}
ServiceRegistry.__index = ServiceRegistry

-- ========================================
-- REGISTRY SINGLETON
-- ========================================

local registryInstance = nil

function ServiceRegistry.getInstance()
    if not registryInstance then
        registryInstance = ServiceRegistry.new()
    end
    return registryInstance
end

function ServiceRegistry.new()
    local self = setmetatable({}, ServiceRegistry)
    
    self.services = {}
    self.serviceStatus = {}
    self.dependencyGraph = {}
    self.healthMonitors = {}
    self.isMonitoring = false
    self.eventHandlers = {}
    
    -- Service lifecycle events
    self.events = {
        SERVICE_REGISTERED = "ServiceRegistered",
        SERVICE_STARTED = "ServiceStarted",
        SERVICE_STOPPED = "ServiceStopped",
        SERVICE_FAILED = "ServiceFailed",
        HEALTH_CHECK_FAILED = "HealthCheckFailed"
    }
    
    return self
end

-- ========================================
-- SERVICE REGISTRATION
-- ========================================

function ServiceRegistry:RegisterService(name, service, metadata)
    if self.services[name] then
        warn("⚠️ Service already registered: " .. name)
        return false
    end
    
    -- Validate service interface
    if not self:_validateServiceInterface(service) then
        error("❌ Service does not implement required interface: " .. name)
    end
    
    -- Register service
    self.services[name] = service
    self.serviceStatus[name] = {
        name = name,
        service = service,
        status = "REGISTERED",
        isHealthy = true,
        lastHealthCheck = tick(),
        healthFailures = 0,
        startTime = nil,
        metadata = metadata or {},
        version = service:GetVersion(),
        dependencies = service:GetDependencies() or {}
    }
    
    -- Build dependency graph
    self:_buildDependencyGraph(name, service:GetDependencies() or {})
    
    print("📝 Registered service: " .. name .. " (v" .. service:GetVersion() .. ")")
    
    -- Trigger event
    self:_triggerEvent(self.events.SERVICE_REGISTERED, name, service)
    
    return true
end

function ServiceRegistry:UnregisterService(name)
    if not self.services[name] then
        warn("⚠️ Service not found for unregistration: " .. name)
        return false
    end
    
    -- Stop service if running
    if self.serviceStatus[name].status == "RUNNING" then
        self:StopService(name)
    end
    
    -- Remove from registry
    self.services[name] = nil
    self.serviceStatus[name] = nil
    
    -- Clean up dependency graph
    self.dependencyGraph[name] = nil
    for serviceName, deps in pairs(self.dependencyGraph) do
        for i = #deps, 1, -1 do
            if deps[i] == name then
                table.remove(deps, i)
            end
        end
    end
    
    print("🗑️ Unregistered service: " .. name)
    return true
end

-- ========================================
-- SERVICE LIFECYCLE MANAGEMENT
-- ========================================

function ServiceRegistry:StartService(name)
    local serviceInfo = self.serviceStatus[name]
    if not serviceInfo then
        error("❌ Service not found: " .. name)
    end
    
    if serviceInfo.status == "RUNNING" then
        print("ℹ️ Service already running: " .. name)
        return true
    end
    
    -- Start dependencies first
    local success = self:_startDependencies(name)
    if not success then
        error("❌ Failed to start dependencies for service: " .. name)
    end
    
    -- Start the service
    print("🚀 Starting service: " .. name)
    
    local startSuccess, error = pcall(function()
        serviceInfo.service:Start()
    end)
    
    if startSuccess then
        serviceInfo.status = "RUNNING"
        serviceInfo.startTime = tick()
        serviceInfo.isHealthy = true
        serviceInfo.healthFailures = 0
        
        print("✅ Service started: " .. name)
        self:_triggerEvent(self.events.SERVICE_STARTED, name, serviceInfo.service)
        
        -- Start health monitoring if not already monitoring
        if not self.isMonitoring then
            self:StartHealthMonitoring()
        end
        
        return true
    else
        serviceInfo.status = "FAILED"
        serviceInfo.isHealthy = false
        warn("❌ Failed to start service " .. name .. ": " .. tostring(error))
        self:_triggerEvent(self.events.SERVICE_FAILED, name, error)
        return false
    end
end

function ServiceRegistry:StopService(name)
    local serviceInfo = self.serviceStatus[name]
    if not serviceInfo then
        error("❌ Service not found: " .. name)
    end
    
    if serviceInfo.status ~= "RUNNING" then
        print("ℹ️ Service not running: " .. name)
        return true
    end
    
    print("🛑 Stopping service: " .. name)
    
    local stopSuccess, error = pcall(function()
        serviceInfo.service:Stop()
    end)
    
    if stopSuccess then
        serviceInfo.status = "STOPPED"
        serviceInfo.isHealthy = true
        print("✅ Service stopped: " .. name)
        self:_triggerEvent(self.events.SERVICE_STOPPED, name, serviceInfo.service)
        return true
    else
        serviceInfo.status = "FAILED"
        serviceInfo.isHealthy = false
        warn("❌ Failed to stop service " .. name .. ": " .. tostring(error))
        self:_triggerEvent(self.events.SERVICE_FAILED, name, error)
        return false
    end
end

function ServiceRegistry:StartAllServices()
    print("🚀 Starting all registered services...")
    
    -- Get startup order based on dependencies
    local startupOrder = self:_getStartupOrder()
    local failures = {}
    
    for _, serviceName in ipairs(startupOrder) do
        local success = self:StartService(serviceName)
        if not success then
            table.insert(failures, serviceName)
        end
    end
    
    if #failures > 0 then
        warn("❌ Some services failed to start: " .. table.concat(failures, ", "))
        return false
    end
    
    print("✅ All services started successfully")
    return true
end

function ServiceRegistry:StopAllServices()
    print("🛑 Stopping all services...")
    
    -- Stop in reverse dependency order
    local startupOrder = self:_getStartupOrder()
    local failures = {}
    
    for i = #startupOrder, 1, -1 do
        local serviceName = startupOrder[i]
        local success = self:StopService(serviceName)
        if not success then
            table.insert(failures, serviceName)
        end
    end
    
    if #failures > 0 then
        warn("❌ Some services failed to stop: " .. table.concat(failures, ", "))
        return false
    end
    
    print("✅ All services stopped successfully")
    return true
end

-- ========================================
-- SERVICE DISCOVERY
-- ========================================

function ServiceRegistry:GetService(name)
    return self.services[name]
end

function ServiceRegistry:GetServiceStatus(name)
    return self.serviceStatus[name]
end

function ServiceRegistry:GetAllServices()
    local services = {}
    for name, service in pairs(self.services) do
        services[name] = service
    end
    return services
end

function ServiceRegistry:GetServicesByStatus(status)
    local services = {}
    for name, serviceInfo in pairs(self.serviceStatus) do
        if serviceInfo.status == status then
            services[name] = serviceInfo.service
        end
    end
    return services
end

function ServiceRegistry:GetRunningServices()
    return self:GetServicesByStatus("RUNNING")
end

function ServiceRegistry:GetHealthyServices()
    local services = {}
    for name, serviceInfo in pairs(self.serviceStatus) do
        if serviceInfo.isHealthy then
            services[name] = serviceInfo.service
        end
    end
    return services
end

function ServiceRegistry:GetUnhealthyServices()
    local services = {}
    for name, serviceInfo in pairs(self.serviceStatus) do
        if not serviceInfo.isHealthy then
            services[name] = serviceInfo.service
        end
    end
    return services
end

-- ========================================
-- HEALTH MONITORING
-- ========================================

function ServiceRegistry:StartHealthMonitoring(interval)
    if self.isMonitoring then
        print("ℹ️ Health monitoring already running")
        return
    end
    
    interval = interval or 30 -- Default 30 seconds
    self.isMonitoring = true
    
    print("💓 Starting health monitoring (interval: " .. interval .. "s)")
    
    spawn(function()
        while self.isMonitoring do
            self:_performHealthChecks()
            wait(interval)
        end
    end)
end

function ServiceRegistry:StopHealthMonitoring()
    self.isMonitoring = false
    print("💔 Health monitoring stopped")
end

function ServiceRegistry:_performHealthChecks()
    for name, serviceInfo in pairs(self.serviceStatus) do
        if serviceInfo.status == "RUNNING" then
            local success, healthStatus = pcall(function()
                return serviceInfo.service:GetHealthStatus()
            end)
            
            serviceInfo.lastHealthCheck = tick()
            
            if success and healthStatus.isHealthy then
                if not serviceInfo.isHealthy then
                    print("💚 Service health recovered: " .. name)
                    serviceInfo.isHealthy = true
                    serviceInfo.healthFailures = 0
                end
            else
                serviceInfo.healthFailures = serviceInfo.healthFailures + 1
                
                if serviceInfo.isHealthy then
                    warn("💔 Service health check failed: " .. name .. " (failure #" .. serviceInfo.healthFailures .. ")")
                    self:_triggerEvent(self.events.HEALTH_CHECK_FAILED, name, healthStatus)
                end
                
                -- Mark as unhealthy after 3 consecutive failures
                if serviceInfo.healthFailures >= 3 then
                    serviceInfo.isHealthy = false
                    warn("❌ Service marked as unhealthy: " .. name)
                end
            end
        end
    end
end

-- ========================================
-- DEPENDENCY MANAGEMENT
-- ========================================

function ServiceRegistry:_buildDependencyGraph(serviceName, dependencies)
    self.dependencyGraph[serviceName] = dependencies
end

function ServiceRegistry:_startDependencies(serviceName)
    local dependencies = self.dependencyGraph[serviceName] or {}
    
    for _, depName in ipairs(dependencies) do
        if not self.services[depName] then
            warn("❌ Dependency not found: " .. depName .. " (required by " .. serviceName .. ")")
            return false
        end
        
        local depStatus = self.serviceStatus[depName]
        if depStatus.status ~= "RUNNING" then
            local success = self:StartService(depName)
            if not success then
                warn("❌ Failed to start dependency: " .. depName .. " (required by " .. serviceName .. ")")
                return false
            end
        end
    end
    
    return true
end

function ServiceRegistry:_getStartupOrder()
    local order = {}
    local visited = {}
    local visiting = {}
    
    local function visit(serviceName)
        if visiting[serviceName] then
            error("❌ Circular dependency detected involving: " .. serviceName)
        end
        
        if visited[serviceName] then
            return
        end
        
        visiting[serviceName] = true
        
        local dependencies = self.dependencyGraph[serviceName] or {}
        for _, depName in ipairs(dependencies) do
            if self.services[depName] then
                visit(depName)
            end
        end
        
        visiting[serviceName] = false
        visited[serviceName] = true
        table.insert(order, serviceName)
    end
    
    for serviceName, _ in pairs(self.services) do
        if not visited[serviceName] then
            visit(serviceName)
        end
    end
    
    return order
end

-- ========================================
-- EVENT SYSTEM
-- ========================================

function ServiceRegistry:AddEventHandler(eventName, handler)
    if not self.eventHandlers[eventName] then
        self.eventHandlers[eventName] = {}
    end
    table.insert(self.eventHandlers[eventName], handler)
end

function ServiceRegistry:_triggerEvent(eventName, ...)
    local handlers = self.eventHandlers[eventName]
    if handlers then
        for _, handler in ipairs(handlers) do
            local success, error = pcall(handler, ...)
            if not success then
                warn("❌ Event handler error for " .. eventName .. ": " .. tostring(error))
            end
        end
    end
end

-- ========================================
-- REPORTING AND DIAGNOSTICS
-- ========================================

function ServiceRegistry:GetHealthReport()
    local report = {
        timestamp = tick(),
        totalServices = 0,
        runningServices = 0,
        healthyServices = 0,
        failedServices = 0,
        services = {}
    }
    
    for name, serviceInfo in pairs(self.serviceStatus) do
        report.totalServices = report.totalServices + 1
        
        if serviceInfo.status == "RUNNING" then
            report.runningServices = report.runningServices + 1
        end
        
        if serviceInfo.isHealthy then
            report.healthyServices = report.healthyServices + 1
        end
        
        if serviceInfo.status == "FAILED" then
            report.failedServices = report.failedServices + 1
        end
        
        report.services[name] = {
            name = name,
            status = serviceInfo.status,
            isHealthy = serviceInfo.isHealthy,
            version = serviceInfo.version,
            healthFailures = serviceInfo.healthFailures,
            lastHealthCheck = serviceInfo.lastHealthCheck,
            uptime = serviceInfo.startTime and (tick() - serviceInfo.startTime) or 0,
            dependencies = serviceInfo.dependencies
        }
    end
    
    return report
end

function ServiceRegistry:PrintHealthReport()
    local report = self:GetHealthReport()
    
    print("\n" .. "=".rep(60))
    print("💊 SERVICE REGISTRY HEALTH REPORT")
    print("=".rep(60))
    print("Total Services: " .. report.totalServices)
    print("Running: " .. report.runningServices .. "/" .. report.totalServices)
    print("Healthy: " .. report.healthyServices .. "/" .. report.totalServices)
    print("Failed: " .. report.failedServices .. "/" .. report.totalServices)
    print()
    
    for name, serviceInfo in pairs(report.services) do
        local statusIcon = serviceInfo.isHealthy and "💚" or "💔"
        local uptime = serviceInfo.uptime > 0 and string.format("%.1fs", serviceInfo.uptime) or "N/A"
        
        print(string.format("%s %-20s %s (v%s) - Uptime: %s", 
              statusIcon, name, serviceInfo.status, serviceInfo.version, uptime))
        
        if serviceInfo.healthFailures > 0 then
            print("  ⚠️ Health failures: " .. serviceInfo.healthFailures)
        end
        
        if #serviceInfo.dependencies > 0 then
            print("  📦 Dependencies: " .. table.concat(serviceInfo.dependencies, ", "))
        end
    end
    
    print("=".rep(60) .. "\n")
end

-- ========================================
-- PRIVATE UTILITY METHODS
-- ========================================

function ServiceRegistry:_validateServiceInterface(service)
    local requiredMethods = {"GetServiceName", "GetVersion", "GetHealthStatus", "Initialize", "Start", "Stop"}
    
    for _, methodName in ipairs(requiredMethods) do
        if type(service[methodName]) ~= "function" then
            warn("❌ Service missing required method: " .. methodName)
            return false
        end
    end
    
    return true
end

return ServiceRegistry
