-- ControllerBase.luau
-- Base class for all client-side controllers

local SafeRequire = require(script.Parent.SafeRequire)

local ControllerBase = {}
ControllerBase.__index = ControllerBase

-- Controller states
local CONTROLLER_STATES = {
    UNINITIALIZED = "Uninitialized",
    INITIALIZING = "Initializing", 
    INITIALIZED = "Initialized",
    STARTING = "Starting",
    RUNNING = "Running",
    STOPPING = "Stopping",
    STOPPED = "Stopped",
    ERROR = "Error"
}

-- Create a new controller instance
function ControllerBase.new(name, dependencies)
    local self = setmetatable({}, ControllerBase)
    
    self.Name = name or "UnnamedController"
    self.State = CONTROLLER_STATES.UNINITIALIZED
    self.Dependencies = dependencies or {}
    self.IsInitialized = false
    self.IsRunning = false
    self.Priority = 0 -- Higher numbers initialize first
    self.InitializationTime = 0
    self.LastError = nil
    
    -- Event connections storage
    self.Connections = {}
    
    -- Bindable events for lifecycle
    self.StateChanged = Instance.new("BindableEvent")
    
    return self
end

-- Initialize the controller
function ControllerBase:Initialize()
    if self.State ~= CONTROLLER_STATES.UNINITIALIZED then
        warn(string.format("[%s] Cannot initialize - current state: %s", self.Name, self.State))
        return false
    end
    
    self:SetState(CONTROLLER_STATES.INITIALIZING)
    
    local startTime = tick()
    local success, error = pcall(function()
        if self.OnInitialize then
            self:OnInitialize()
        end
    end)
    
    self.InitializationTime = tick() - startTime
    
    if success then
        self.IsInitialized = true
        self:SetState(CONTROLLER_STATES.INITIALIZED)
        return true
    else
        self.LastError = error
        self:SetState(CONTROLLER_STATES.ERROR)
        warn(string.format("[%s] Initialization failed: %s", self.Name, tostring(error)))
        return false
    end
end

-- Start the controller
function ControllerBase:Start()
    if self.State ~= CONTROLLER_STATES.INITIALIZED then
        warn(string.format("[%s] Cannot start - current state: %s", self.Name, self.State))
        return false
    end
    
    self:SetState(CONTROLLER_STATES.STARTING)
    
    local success, error = pcall(function()
        if self.OnStart then
            self:OnStart()
        end
    end)
    
    if success then
        self.IsRunning = true
        self:SetState(CONTROLLER_STATES.RUNNING)
        return true
    else
        self.LastError = error
        self:SetState(CONTROLLER_STATES.ERROR)
        warn(string.format("[%s] Start failed: %s", self.Name, tostring(error)))
        return false
    end
end

-- Stop the controller
function ControllerBase:Stop()
    if self.State == CONTROLLER_STATES.STOPPED then
        return true
    end
    
    self:SetState(CONTROLLER_STATES.STOPPING)
    
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
        self:SetState(CONTROLLER_STATES.STOPPED)
        return true
    else
        self.LastError = error
        self:SetState(CONTROLLER_STATES.ERROR)
        warn(string.format("[%s] Stop failed: %s", self.Name, tostring(error)))
        return false
    end
end

-- Set controller state and fire event
function ControllerBase:SetState(newState)
    local oldState = self.State
    self.State = newState
    
    if self.StateChanged then
        self.StateChanged:Fire(newState, oldState)
    end
end

-- Add a connection to be managed by the controller
function ControllerBase:AddConnection(name, connection)
    self.Connections[name] = connection
end

-- Remove a specific connection
function ControllerBase:RemoveConnection(name)
    local connection = self.Connections[name]
    if connection and connection.Disconnect then
        connection:Disconnect()
    end
    self.Connections[name] = nil
end

-- Check if all dependencies are met
function ControllerBase:CheckDependencies()
    -- Override in child classes for specific dependency checks
    return true
end

-- Get controller status info
function ControllerBase:GetStatus()
    return {
        Name = self.Name,
        State = self.State,
        IsInitialized = self.IsInitialized,
        IsRunning = self.IsRunning,
        Priority = self.Priority,
        InitializationTime = self.InitializationTime,
        LastError = self.LastError,
        ConnectionCount = #self.Connections
    }
end

-- Cleanup controller
function ControllerBase:Destroy()
    self:Stop()
    
    if self.StateChanged then
        self.StateChanged:Destroy()
        self.StateChanged = nil
    end
    
    setmetatable(self, nil)
end

-- Export states for use by other modules
ControllerBase.States = CONTROLLER_STATES

return ControllerBase
