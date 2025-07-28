-- ControllerBase.luau
-- Base class/template for all standardized client controllers using Enhanced pattern with SafeRequire
-- Provides consistent controller lifecycle, error handling, and initialization patterns

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SafeRequire = require(ReplicatedStorage.Shared.utils.SafeRequire)

local ControllerBase = {}

-- Controller configuration template
local DEFAULT_CONFIG = {
    enableDetailedLogging = true,
    retryFailedRequires = true,
    maxRetryAttempts = 3,
    validateOnStart = true,
    autoStart = false
}

function ControllerBase.new(controllerName, config)
    local controller = {}
    
    -- Controller metadata
    controller.Name = controllerName
    controller.Config = config or DEFAULT_CONFIG
    controller.IsInitialized = false
    controller.IsStarted = false
    controller.InitializationTime = 0
    controller.Dependencies = {}
    controller.Services = {}
    controller.Connections = {}
    controller.State = "Idle"
    
    -- Enhanced SafeRequire method with controller-specific configuration
    function controller:SafeRequire(modulePath, moduleName, isOptional)
        isOptional = isOptional or false
        
        if SafeRequire and SafeRequire.requireWithRetry then
            local maxAttempts = self.Config.retryFailedRequires and self.Config.maxRetryAttempts or 1
            local result = SafeRequire.requireWithRetry(modulePath, maxAttempts, nil)
            
            if result then
                if self.Config.enableDetailedLogging then
                    print(string.format("✅ %s SafeRequire: %s loaded successfully", self.Name, moduleName))
                end
                return result
            else
                if isOptional then
                    warn(string.format("⚠️ %s SafeRequire: Optional module %s failed to load", self.Name, moduleName))
                    return nil
                else
                    error(string.format("❌ %s SafeRequire: Critical module %s failed to load", self.Name, moduleName))
                end
            end
        else
            -- Fallback to basic pcall
            local success, result = pcall(function()
                return require(modulePath)
            end)
            
            if success then
                return result
            else
                if isOptional then
                    warn(string.format("⚠️ %s: Optional module %s failed: %s", self.Name, moduleName, tostring(result)))
                    return nil
                else
                    error(string.format("❌ %s: Critical module %s failed: %s", self.Name, moduleName, tostring(result)))
                end
            end
        end
    end
    
    -- Standard initialization method
    function controller:Init()
        if self.IsInitialized then
            warn(string.format("⚠️ %s already initialized", self.Name))
            return true
        end
        
        local startTime = tick()
        self.State = "Initializing"
        
        if self.Config.enableDetailedLogging then
            print(string.format("🔧 %s initializing...", self.Name))
        end
        
        -- Load dependencies if specified
        local success = self:LoadDependencies()
        if not success then
            error(string.format("❌ %s failed to load dependencies", self.Name))
            return false
        end
        
        -- Load services if specified
        success = self:LoadServices()
        if not success then
            error(string.format("❌ %s failed to load services", self.Name))
            return false
        end
        
        -- Call controller-specific initialization
        if self.OnInit then
            success = self:OnInit()
            if not success then
                error(string.format("❌ %s OnInit failed", self.Name))
                return false
            end
        end
        
        -- Setup UI if specified
        if self.SetupUI then
            self:SetupUI()
        end
        
        -- Setup connections if specified
        if self.SetupConnections then
            self:SetupConnections()
        end
        
        self.IsInitialized = true
        self.InitializationTime = tick() - startTime
        self.State = "Initialized"
        
        if self.Config.enableDetailedLogging then
            print(string.format("✅ %s initialized successfully (%.2fs)", self.Name, self.InitializationTime))
        end
        
        -- Auto-start if configured
        if self.Config.autoStart then
            spawn(function()
                wait(0.1)
                self:Start()
            end)
        end
        
        return true
    end
    
    -- Standard start method
    function controller:Start()
        if not self.IsInitialized then
            warn(string.format("⚠️ %s cannot start - not initialized", self.Name))
            return false
        end
        
        if self.IsStarted then
            warn(string.format("⚠️ %s already started", self.Name))
            return true
        end
        
        self.State = "Starting"
        
        if self.Config.enableDetailedLogging then
            print(string.format("🚀 %s starting...", self.Name))
        end
        
        -- Call controller-specific start logic
        if self.OnStart then
            local success = self:OnStart()
            if not success then
                error(string.format("❌ %s OnStart failed", self.Name))
                return false
            end
        end
        
        self.IsStarted = true
        self.State = "Running"
        
        if self.Config.enableDetailedLogging then
            print(string.format("✅ %s started successfully", self.Name))
        end
        
        return true
    end
    
    -- Load dependencies using SafeRequire
    function controller:LoadDependencies()
        if not self.Dependencies or #self.Dependencies == 0 then
            return true
        end
        
        for _, dependency in ipairs(self.Dependencies) do
            local modulePath = dependency.path
            local moduleName = dependency.name
            local isOptional = dependency.optional or false
            
            local module = self:SafeRequire(modulePath, moduleName, isOptional)
            if module then
                self[moduleName] = module
            elseif not isOptional then
                return false
            end
        end
        
        return true
    end
    
    -- Load services using ServiceRegistry or direct require
    function controller:LoadServices()
        if not self.Services or not next(self.Services) then
            return true
        end
        
        -- Try to use ServiceRegistry first
        local ServiceRegistry = self:SafeRequire(ReplicatedStorage.Shared.utils.ServiceRegistry, "ServiceRegistry", true)
        
        for serviceName, serviceConfig in pairs(self.Services) do
            local service = nil
            
            if ServiceRegistry then
                service = ServiceRegistry:GetService(serviceName)
            elseif serviceConfig.path then
                service = self:SafeRequire(serviceConfig.path, serviceName, serviceConfig.optional or false)
            end
            
            if service then
                self[serviceName] = service
            elseif not (serviceConfig.optional or false) then
                warn(string.format("❌ %s failed to load required service: %s", self.Name, serviceName))
                return false
            end
        end
        
        return true
    end
    
    -- Cleanup method
    function controller:Cleanup()
        -- Disconnect all connections
        for name, connection in pairs(self.Connections) do
            if connection and connection.Disconnect then
                connection:Disconnect()
            end
        end
        self.Connections = {}
        
        -- Call controller-specific cleanup
        if self.OnCleanup then
            self:OnCleanup()
        end
        
        self.State = "Cleaned"
        
        if self.Config.enableDetailedLogging then
            print(string.format("🧹 %s cleaned up", self.Name))
        end
    end
    
    -- Get controller status
    function controller:GetStatus()
        local function tableLength(t)
            local count = 0
            for _ in pairs(t) do count = count + 1 end
            return count
        end
        
        return {
            name = self.Name,
            state = self.State,
            isInitialized = self.IsInitialized,
            isStarted = self.IsStarted,
            initializationTime = self.InitializationTime,
            dependencyCount = self.Dependencies and #self.Dependencies or 0,
            serviceCount = self.Services and tableLength(self.Services) or 0,
            connectionCount = tableLength(self.Connections)
        }
    end
    
    return controller
end

return ControllerBase
