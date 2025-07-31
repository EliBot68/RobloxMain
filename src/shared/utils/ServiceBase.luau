-- ServiceBase.luau
-- Base class for all client and server services

local ServiceBase = {}
ServiceBase.__index = ServiceBase

-- Service states
local SERVICE_STATES = {
    UNINITIALIZED = "Uninitialized",
    INITIALIZING = "Initializing",
    INITIALIZED = "Initialized", 
    STARTING = "Starting",
    RUNNING = "Running",
    STOPPING = "Stopping",
    STOPPED = "Stopped",
    ERROR = "Error"
}

-- Create a new service instance
function ServiceBase.new(name, config)
    local self = setmetatable({}, ServiceBase)
    
    self.Name = name or "UnnamedService"
    self.State = SERVICE_STATES.UNINITIALIZED
    self.Config = config or {}
    self.IsInitialized = false
    self.IsRunning = false
    self.Priority = self.Config.Priority or 0
    self.Dependencies = self.Config.Dependencies or {}
    self.InitializationTime = 0
    self.LastError = nil
    
    -- Event connections storage
    self.Connections = {}
    
    -- Service metrics
    self.Metrics = {
        StartTime = 0,
        OperationCount = 0,
        ErrorCount = 0,
        LastActivity = 0
    }
    
    -- Bindable events for lifecycle
    self.StateChanged = Instance.new("BindableEvent")
    
    return self
end

-- Initialize the service
function ServiceBase:Initialize()
    if self.State ~= SERVICE_STATES.UNINITIALIZED then
        warn(string.format("[%s] Cannot initialize - current state: %s", self.Name, self.State))
        return false
    end
    
    self:SetState(SERVICE_STATES.INITIALIZING)
    
    local startTime = tick()
    local success, error = pcall(function()
        -- Check dependencies
        if not self:CheckDependencies() then
            error("Dependencies not met")
        end
        
        -- Call custom initialization
        if self.OnInitialize then
            self:OnInitialize()
        end
    end)
    
    self.InitializationTime = tick() - startTime
    
    if success then
        self.IsInitialized = true
        self:SetState(SERVICE_STATES.INITIALIZED)
        self:LogInfo("Initialized successfully in %.2fs", self.InitializationTime)
        return true
    else
        self.LastError = error
        self:SetState(SERVICE_STATES.ERROR)
        self:LogError("Initialization failed: %s", tostring(error))
        return false
    end
end

-- Start the service
function ServiceBase:Start()
    if self.State ~= SERVICE_STATES.INITIALIZED then
        warn(string.format("[%s] Cannot start - current state: %s", self.Name, self.State))
        return false
    end
    
    self:SetState(SERVICE_STATES.STARTING)
    
    local success, error = pcall(function()
        if self.OnStart then
            self:OnStart()
        end
    end)
    
    if success then
        self.IsRunning = true
        self.Metrics.StartTime = tick()
        self:SetState(SERVICE_STATES.RUNNING)
        self:LogInfo("Started successfully")
        return true
    else
        self.LastError = error
        self:SetState(SERVICE_STATES.ERROR)
        self:LogError("Start failed: %s", tostring(error))
        return false
    end
end

-- Stop the service
function ServiceBase:Stop()
    if self.State == SERVICE_STATES.STOPPED then
        return true
    end
    
    self:SetState(SERVICE_STATES.STOPPING)
    
    local success, error = pcall(function()
        -- Disconnect all connections
        for _, connection in pairs(self.Connections) do
            if connection and connection.Disconnect then
                connection:Disconnect()
            end
        end
        self.Connections = {}
        
        if self.OnStop then
            self:OnStop()
        end
    end)
    
    if success then
        self.IsRunning = false
        self:SetState(SERVICE_STATES.STOPPED)
        self:LogInfo("Stopped successfully")
        return true
    else
        self.LastError = error
        self:SetState(SERVICE_STATES.ERROR)
        self:LogError("Stop failed: %s", tostring(error))
        return false
    end
end

-- Set service state and fire event
function ServiceBase:SetState(newState)
    local oldState = self.State
    self.State = newState
    
    if self.StateChanged then
        self.StateChanged:Fire(newState, oldState)
    end
end

-- Add a connection to be managed by the service
function ServiceBase:AddConnection(name, connection)
    self.Connections[name] = connection
end

-- Remove a specific connection
function ServiceBase:RemoveConnection(name)
    local connection = self.Connections[name]
    if connection and connection.Disconnect then
        connection:Disconnect()
    end
    self.Connections[name] = nil
end

-- Check if all dependencies are met
function ServiceBase:CheckDependencies()
    -- Override in child classes for specific dependency checks
    return true
end

-- Logging methods
function ServiceBase:LogInfo(message, ...)
    local formattedMessage = string.format(message, ...)
    print(string.format("[%s] %s", self.Name, formattedMessage))
end

function ServiceBase:LogWarn(message, ...)
    local formattedMessage = string.format(message, ...)
    warn(string.format("[%s] %s", self.Name, formattedMessage))
end

function ServiceBase:LogError(message, ...)
    local formattedMessage = string.format(message, ...)
    warn(string.format("[%s] ERROR: %s", self.Name, formattedMessage))
    self.Metrics.ErrorCount = self.Metrics.ErrorCount + 1
end

-- Update metrics
function ServiceBase:RecordOperation()
    self.Metrics.OperationCount = self.Metrics.OperationCount + 1
    self.Metrics.LastActivity = tick()
end

-- Get service status info
function ServiceBase:GetStatus()
    return {
        Name = self.Name,
        State = self.State,
        IsInitialized = self.IsInitialized,
        IsRunning = self.IsRunning,
        Priority = self.Priority,
        InitializationTime = self.InitializationTime,
        LastError = self.LastError,
        ConnectionCount = #self.Connections,
        Metrics = {
            Uptime = self.IsRunning and (tick() - self.Metrics.StartTime) or 0,
            OperationCount = self.Metrics.OperationCount,
            ErrorCount = self.Metrics.ErrorCount,
            LastActivity = self.Metrics.LastActivity
        }
    }
end

-- Get health status
function ServiceBase:GetHealth()
    local health = {
        Status = self.State,
        Healthy = self.State == SERVICE_STATES.RUNNING,
        Issues = {}
    }
    
    -- Check for common issues
    if self.Metrics.ErrorCount > 0 then
        table.insert(health.Issues, string.format("Error count: %d", self.Metrics.ErrorCount))
    end
    
    if self.IsRunning and (tick() - self.Metrics.LastActivity) > 300 then
        table.insert(health.Issues, "No activity for 5+ minutes")
    end
    
    if #self.Connections == 0 and self.IsRunning then
        table.insert(health.Issues, "No active connections")
    end
    
    health.Healthy = health.Healthy and #health.Issues == 0
    
    return health
end

-- Restart the service
function ServiceBase:Restart()
    self:LogInfo("Restarting service...")
    
    local wasRunning = self.IsRunning
    
    if self.IsRunning then
        self:Stop()
    end
    
    if wasRunning then
        wait(0.1) -- Brief pause
        return self:Start()
    end
    
    return true
end

-- Cleanup service
function ServiceBase:Destroy()
    self:Stop()
    
    if self.StateChanged then
        self.StateChanged:Destroy()
        self.StateChanged = nil
    end
    
    setmetatable(self, nil)
end

-- Export states for use by other modules
ServiceBase.States = SERVICE_STATES

return ServiceBase
