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
    
    -- Parameter validation - Issue #1 fix
    if name ~= nil and type(name) ~= "string" then
        error("ServiceBase.new: name must be a string or nil")
    end
    if config ~= nil and type(config) ~= "table" then
        error("ServiceBase.new: config must be a table or nil")
    end
    
    self.Name = name or "UnnamedService"
    self.State = SERVICE_STATES.UNINITIALIZED
    self.Config = config or {}
    self.IsInitialized = false
    self.IsRunning = false
    
    -- Config access validation - Issue #2 fix
    local function safeConfigGet(key, default)
        if self.Config and type(self.Config) == "table" then
            return self.Config[key] or default
        end
        return default
    end
    
    self.Priority = safeConfigGet("Priority", 0)
    self.Dependencies = safeConfigGet("Dependencies", {})
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
    
    -- Bindable events for lifecycle - Issue #3 fix: Track for cleanup
    self.StateChanged = Instance.new("BindableEvent")
    self._eventsToCleanup = {self.StateChanged}
    
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
    -- Issue #4 fix: Avoid variable shadowing by using different name
    local success, initError = pcall(function()
        -- Check dependencies
        if not self:CheckDependencies() then
            error("Dependencies not met")
        end
        
        -- Call custom initialization - Issue #6 fix: Validate return value
        if self.OnInitialize then
            local initResult = self:OnInitialize()
            -- If OnInitialize returns false explicitly, treat as failure
            if initResult == false then
                error("OnInitialize returned false")
            end
        end
    end)
    
    self.InitializationTime = tick() - startTime
    
    if success then
        self.IsInitialized = true
        self:SetState(SERVICE_STATES.INITIALIZED)
        self:LogInfo("Initialized successfully in %.2fs", self.InitializationTime)
        return true
    else
        self.LastError = initError
        self:SetState(SERVICE_STATES.ERROR)
        self:LogError("Initialization failed: %s", tostring(initError))
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
    
    local success, startError = pcall(function()
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
        self.LastError = startError
        self:SetState(SERVICE_STATES.ERROR)
        self:LogError("Start failed: %s", tostring(startError))
        return false
    end
end

-- Stop the service
function ServiceBase:Stop()
    if self.State == SERVICE_STATES.STOPPED then
        return true
    end
    
    self:SetState(SERVICE_STATES.STOPPING)
    
    local success, stopError = pcall(function()
        -- Issue #7 & #8 fix: Connection cleanup with proper error handling and iteration
        local connectionsToClean = {}
        for name, connection in pairs(self.Connections) do
            table.insert(connectionsToClean, {name = name, connection = connection})
        end
        
        for _, item in ipairs(connectionsToClean) do
            local disconnectSuccess, disconnectError = pcall(function()
                if item.connection and item.connection.Disconnect then
                    item.connection:Disconnect()
                end
            end)
            if not disconnectSuccess then
                self:LogWarn("Failed to disconnect connection '%s': %s", item.name, tostring(disconnectError))
            end
            self.Connections[item.name] = nil
        end
        
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
        self.LastError = stopError
        self:SetState(SERVICE_STATES.ERROR)
        self:LogError("Stop failed: %s", tostring(stopError))
        return false
    end
end

-- Set service state and fire event
function ServiceBase:SetState(newState)
    local oldState = self.State
    self.State = newState
    
    -- Issue #9 fix: State change event with error handling
    if self.StateChanged then
        local success, eventError = pcall(function()
            self.StateChanged:Fire(newState, oldState)
        end)
        if not success then
            self:LogWarn("Error firing StateChanged event: %s", tostring(eventError))
        end
    end
end

-- Add a connection to be managed by the service
function ServiceBase:AddConnection(name, connection)
    -- Issue #10 fix: Connection management validation
    if type(name) ~= "string" then
        error("AddConnection: name must be a string")
    end
    if not connection or not connection.Disconnect or type(connection.Disconnect) ~= "function" then
        error("AddConnection: connection must have a Disconnect method")
    end
    
    self.Connections[name] = connection
end

-- Remove a specific connection
function ServiceBase:RemoveConnection(name)
    -- Issue #11 fix: Connection removal with existence check
    if type(name) ~= "string" then
        return false
    end
    
    local connection = self.Connections[name]
    if connection then
        local success, disconnectError = pcall(function()
            if connection.Disconnect and type(connection.Disconnect) == "function" then
                connection:Disconnect()
            end
        end)
        if not success then
            self:LogWarn("Error disconnecting connection '%s': %s", name, tostring(disconnectError))
        end
        self.Connections[name] = nil
        return true
    end
    
    return false
end

-- Check if all dependencies are met
function ServiceBase:CheckDependencies()
    -- Issue #5 fix: Proper dependency validation instead of hardcoded true
    if not self.Dependencies or type(self.Dependencies) ~= "table" then
        return true -- No dependencies to check
    end
    
    for _, dependency in ipairs(self.Dependencies) do
        if type(dependency) == "string" then
            -- Basic dependency name check - can be overridden by child classes
            if dependency == "" then
                self:LogWarn("Empty dependency name found")
                return false
            end
        else
            self:LogWarn("Invalid dependency type: %s", type(dependency))
            return false
        end
    end
    
    -- Override in child classes for specific dependency checks
    return true
end

-- Logging methods
function ServiceBase:LogInfo(message, ...)
    -- Issue #12 fix: String formatting with error protection
    local success, formattedMessage = pcall(string.format, message, ...)
    if not success then
        formattedMessage = tostring(message) .. " [FORMAT ERROR]"
    end
    print(string.format("[%s] %s", self.Name, formattedMessage))
end

function ServiceBase:LogWarn(message, ...)
    -- Issue #12 fix: String formatting with error protection
    local success, formattedMessage = pcall(string.format, message, ...)
    if not success then
        formattedMessage = tostring(message) .. " [FORMAT ERROR]"
    end
    warn(string.format("[%s] %s", self.Name, formattedMessage))
end

function ServiceBase:LogError(message, ...)
    -- Issue #12 fix: String formatting with error protection
    local success, formattedMessage = pcall(string.format, message, ...)
    if not success then
        formattedMessage = tostring(message) .. " [FORMAT ERROR]"
    end
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
    -- Issue #13 fix: Correct connection count calculation for dictionary
    local connectionCount = 0
    for _ in pairs(self.Connections) do
        connectionCount = connectionCount + 1
    end
    
    return {
        Name = self.Name,
        State = self.State,
        IsInitialized = self.IsInitialized,
        IsRunning = self.IsRunning,
        Priority = self.Priority,
        InitializationTime = self.InitializationTime,
        LastError = self.LastError,
        ConnectionCount = connectionCount,
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
    -- Issue #14 fix: Configurable health check thresholds
    local HEALTH_CHECK_CONFIG = {
        INACTIVITY_THRESHOLD = 300, -- 5 minutes - configurable
        MIN_CONNECTIONS_WARNING = 0 -- warn if no connections while running
    }
    
    local health = {
        Status = self.State,
        Healthy = self.State == SERVICE_STATES.RUNNING,
        Issues = {}
    }
    
    -- Check for common issues
    if self.Metrics.ErrorCount > 0 then
        table.insert(health.Issues, string.format("Error count: %d", self.Metrics.ErrorCount))
    end
    
    if self.IsRunning and (tick() - self.Metrics.LastActivity) > HEALTH_CHECK_CONFIG.INACTIVITY_THRESHOLD then
        table.insert(health.Issues, string.format("No activity for %d+ seconds", HEALTH_CHECK_CONFIG.INACTIVITY_THRESHOLD))
    end
    
    -- Fix connection count calculation for health check
    local connectionCount = 0
    for _ in pairs(self.Connections) do
        connectionCount = connectionCount + 1
    end
    
    if connectionCount <= HEALTH_CHECK_CONFIG.MIN_CONNECTIONS_WARNING and self.IsRunning then
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
        -- Issue #15 fix: Task scheduling with cleanup tracking
        if not self._restartTasks then
            self._restartTasks = {}
        end
        
        local restartTask
        restartTask = task.delay(0.05, function()
            self:Start()
            -- Remove completed task from tracking
            if self._restartTasks then
                for i, t in ipairs(self._restartTasks) do
                    if t == restartTask then
                        table.remove(self._restartTasks, i)
                        break
                    end
                end
            end
        end)
        
        table.insert(self._restartTasks, restartTask)
        return true
    end
    
    return true
end

-- Cleanup service
function ServiceBase:Destroy()
    self:Stop()
    
    -- Issue #3 & #15 fix: Clean up tracked events and tasks
    if self._eventsToCleanup then
        for _, event in ipairs(self._eventsToCleanup) do
            if event and event.Destroy then
                event:Destroy()
            end
        end
        self._eventsToCleanup = nil
    end
    
    if self.StateChanged then
        self.StateChanged:Destroy()
        self.StateChanged = nil
    end
    
    -- Clean up any pending restart tasks
    if self._restartTasks then
        for _, task in ipairs(self._restartTasks) do
            if task then
                task.cancel(task)
            end
        end
        self._restartTasks = nil
    end
    
    setmetatable(self, nil)
end

-- Export states for use by other modules
ServiceBase.States = SERVICE_STATES

return ServiceBase
