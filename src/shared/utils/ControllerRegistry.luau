-- ControllerRegistry.luau  
-- Registry and manager for all client-side controllers

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local SafeRequire = require(script.Parent.SafeRequire)
local ControllerBase = require(script.Parent.ControllerBase)

local ControllerRegistry = {}

-- Registry state
local controllers = {}
local initializationOrder = {}
local isInitialized = false
local isRunning = false

-- Events
local InitializationCompleted = Instance.new("BindableEvent")
local StartupCompleted = Instance.new("BindableEvent")

-- Registry configuration
local MAX_INITIALIZATION_TIME = 30 -- seconds
local MAX_STARTUP_TIME = 15 -- seconds

-- Register a controller
function ControllerRegistry:RegisterController(name, controllerModule, priority)
    if controllers[name] then
        warn(string.format("[ControllerRegistry] Controller '%s' already registered", name))
        return false
    end
    
    priority = priority or 0
    
    local controllerData = {
        Name = name,
        Module = controllerModule,
        Instance = nil,
        Priority = priority,
        Dependencies = {},
        IsInitialized = false,
        IsRunning = false
    }
    
    controllers[name] = controllerData
    
    -- Insert in priority order
    local inserted = false
    for i, existing in ipairs(initializationOrder) do
        if priority > existing.Priority then
            table.insert(initializationOrder, i, controllerData)
            inserted = true
            break
        end
    end
    
    if not inserted then
        table.insert(initializationOrder, controllerData)
    end
    
    print(string.format("[ControllerRegistry] Registered controller '%s' with priority %d", name, priority))
    return true
end

-- Get a registered controller
function ControllerRegistry:GetController(name)
    local controllerData = controllers[name]
    if controllerData and controllerData.Instance then
        return controllerData.Instance
    end
    return nil
end

-- Check if a controller is registered
function ControllerRegistry:HasController(name)
    return controllers[name] ~= nil
end

-- Initialize all controllers
function ControllerRegistry:InitializeAll()
    if isInitialized then
        warn("[ControllerRegistry] Controllers already initialized")
        return true
    end
    
    print(string.format("[ControllerRegistry] Initializing %d controllers...", #initializationOrder))
    
    local startTime = tick()
    local successCount = 0
    local failureCount = 0
    
    for i, controllerData in ipairs(initializationOrder) do
        local success = self:InitializeController(controllerData)
        if success then
            successCount = successCount + 1
        else
            failureCount = failureCount + 1
        end
        
        -- Check timeout
        if (tick() - startTime) > MAX_INITIALIZATION_TIME then
            warn("[ControllerRegistry] Initialization timeout reached")
            break
        end
    end
    
    local totalTime = tick() - startTime
    isInitialized = failureCount == 0
    
    print(string.format("[ControllerRegistry] Initialization completed in %.2fs - Success: %d, Failed: %d", 
        totalTime, successCount, failureCount))
    
    InitializationCompleted:Fire(isInitialized, successCount, failureCount)
    return isInitialized
end

-- Initialize a single controller
function ControllerRegistry:InitializeController(controllerData)
    local success, result = pcall(function()
        print(string.format("[ControllerRegistry] Initializing %s...", controllerData.Name))
        
        -- Load the controller module
        local controllerModule = SafeRequire.require(controllerData.Module)
        if not controllerModule then
            error("Failed to load controller module")
        end
        
        -- Create controller instance
        local instance
        if controllerModule.new then
            -- Controller uses class pattern
            instance = controllerModule.new()
        elseif getmetatable(controllerModule) == ControllerBase then
            -- Controller inherits from ControllerBase
            instance = controllerModule
        else
            -- Controller is a simple module
            instance = controllerModule
        end
        
        controllerData.Instance = instance
        
        -- Initialize if it has the method
        if instance and instance.Initialize then
            return instance:Initialize()
        elseif instance and instance.Init then
            return instance:Init()
        end
        
        return true
    end)
    
    if success and result then
        controllerData.IsInitialized = true
        print(string.format("[ControllerRegistry] ✓ %s initialized successfully", controllerData.Name))
        return true
    else
        controllerData.IsInitialized = false
        warn(string.format("[ControllerRegistry] ✗ %s initialization failed: %s", 
            controllerData.Name, tostring(result)))
        return false
    end
end

-- Start all controllers
function ControllerRegistry:StartAll()
    if not isInitialized then
        warn("[ControllerRegistry] Cannot start - controllers not initialized")
        return false
    end
    
    if isRunning then
        warn("[ControllerRegistry] Controllers already running")
        return true
    end
    
    print("[ControllerRegistry] Starting all controllers...")
    
    local startTime = tick()
    local successCount = 0
    local failureCount = 0
    
    for _, controllerData in ipairs(initializationOrder) do
        if controllerData.IsInitialized then
            local success = self:StartController(controllerData)
            if success then
                successCount = successCount + 1
            else
                failureCount = failureCount + 1
            end
        end
        
        -- Check timeout
        if (tick() - startTime) > MAX_STARTUP_TIME then
            warn("[ControllerRegistry] Startup timeout reached")
            break
        end
    end
    
    local totalTime = tick() - startTime
    isRunning = failureCount == 0
    
    print(string.format("[ControllerRegistry] Startup completed in %.2fs - Success: %d, Failed: %d", 
        totalTime, successCount, failureCount))
    
    StartupCompleted:Fire(isRunning, successCount, failureCount)
    return isRunning
end

-- Start a single controller
function ControllerRegistry:StartController(controllerData)
    local success, result = pcall(function()
        local instance = controllerData.Instance
        if instance and instance.Start then
            return instance:Start()
        elseif instance and instance.Run then
            return instance:Run()
        end
        return true
    end)
    
    if success and result then
        controllerData.IsRunning = true
        return true
    else
        warn(string.format("[ControllerRegistry] Failed to start %s: %s", 
            controllerData.Name, tostring(result)))
        return false
    end
end

-- Stop all controllers
function ControllerRegistry:StopAll()
    print("[ControllerRegistry] Stopping all controllers...")
    
    -- Stop in reverse order
    for i = #initializationOrder, 1, -1 do
        local controllerData = initializationOrder[i]
        if controllerData.IsRunning and controllerData.Instance then
            pcall(function()
                if controllerData.Instance.Stop then
                    controllerData.Instance:Stop()
                end
            end)
            controllerData.IsRunning = false
        end
    end
    
    isRunning = false
end

-- Get registry status
function ControllerRegistry:GetStatus()
    local status = {
        IsInitialized = isInitialized,
        IsRunning = isRunning,
        TotalControllers = #initializationOrder,
        InitializedCount = 0,
        RunningCount = 0,
        Controllers = {}
    }
    
    for _, controllerData in pairs(controllers) do
        if controllerData.IsInitialized then
            status.InitializedCount = status.InitializedCount + 1
        end
        if controllerData.IsRunning then
            status.RunningCount = status.RunningCount + 1
        end
        
        status.Controllers[controllerData.Name] = {
            Priority = controllerData.Priority,
            IsInitialized = controllerData.IsInitialized,
            IsRunning = controllerData.IsRunning
        }
    end
    
    return status
end

-- Events for external listeners
ControllerRegistry.InitializationCompleted = InitializationCompleted
ControllerRegistry.StartupCompleted = StartupCompleted

return ControllerRegistry
