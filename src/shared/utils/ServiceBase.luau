-- ServiceBase.luau
-- Base class/template for all standardized services using Enhanced pattern with SafeRequire
-- Provides consistent service lifecycle, error handling, and initialization patterns

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SafeRequire = require(ReplicatedStorage.Shared.utils.SafeRequire)

local ServiceBase = {}

-- Service configuration template
local DEFAULT_CONFIG = {
    enableDetailedLogging = true,
    retryFailedRequires = true,
    maxRetryAttempts = 3,
    validateOnStart = true,
    autoStart = false
}

function ServiceBase.new(serviceName, config)
    local service = {}
    
    -- Service metadata
    service.Name = serviceName
    service.Config = config or DEFAULT_CONFIG
    service.IsInitialized = false
    service.IsStarted = false
    service.InitializationTime = 0
    service.Dependencies = {}
    service.RemoteEvents = {}
    service.Connections = {}
    service.State = "Idle"
    
    -- Enhanced SafeRequire method with service-specific configuration
    function service:SafeRequire(modulePath, moduleName, isOptional)
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
    function service:Init()
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
        
        -- Call service-specific initialization
        if self.OnInit then
            success = self:OnInit()
            if not success then
                error(string.format("❌ %s OnInit failed", self.Name))
                return false
            end
        end
        
        -- Setup remote events if specified
        if self.SetupRemoteEvents then
            self:SetupRemoteEvents()
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
    function service:Start()
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
        
        -- Call service-specific start logic
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
    function service:LoadDependencies()
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
    
    -- Cleanup method
    function service:Cleanup()
        -- Disconnect all connections
        for name, connection in pairs(self.Connections) do
            if connection and connection.Disconnect then
                connection:Disconnect()
            end
        end
        self.Connections = {}
        
        -- Call service-specific cleanup
        if self.OnCleanup then
            self:OnCleanup()
        end
        
        self.State = "Cleaned"
        
        if self.Config.enableDetailedLogging then
            print(string.format("🧹 %s cleaned up", self.Name))
        end
    end
    
    -- Get service status
    function service:GetStatus()
        return {
            name = self.Name,
            state = self.State,
            isInitialized = self.IsInitialized,
            isStarted = self.IsStarted,
            initializationTime = self.InitializationTime,
            dependencyCount = self.Dependencies and #self.Dependencies or 0,
            connectionCount = 0
        }
    end
    
    return service
end

return ServiceBase
