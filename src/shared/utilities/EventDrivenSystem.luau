-- EventDrivenSystem.luau
-- Core event-driven architecture to replace performance-destroying polling loops
-- Provides BindableEvents, signal systems, and adaptive monitoring

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local ConfigurationManager = require(ReplicatedStorage.Shared.core.ConfigurationManager)

local EventDrivenSystem = {}

-- ========================================
-- CONFIGURATION AND STATE
-- ========================================

-- Get configuration instance
local config = ConfigurationManager.getInstance()

-- Event system state
local eventSignals = {}
local adaptiveMonitors = {}
local periodicTasks = {}
local eventStatistics = {}

-- Event types for different systems
local EVENT_TYPES = {
    PLAYER_STAT_CHANGED = "PlayerStatChanged",
    WORLD_OBJECT_READY = "WorldObjectReady",
    SYSTEM_HEALTH_UPDATE = "SystemHealthUpdate",
    PERFORMANCE_THRESHOLD = "PerformanceThreshold",
    CLEANUP_REQUIRED = "CleanupRequired",
    PARTY_INVITE_EXPIRED = "PartyInviteExpired",
    GAME_STATE_CHANGED = "GameStateChanged",
    MOBILE_OPTIMIZATION = "MobileOptimization"
}

-- Adaptive monitoring intervals
local MONITORING_INTERVALS = {
    HIGH_FREQUENCY = 0.1,    -- 100ms - only for critical systems
    MEDIUM_FREQUENCY = 1.0,   -- 1 second - for normal updates
    LOW_FREQUENCY = 5.0,     -- 5 seconds - for background tasks
    ULTRA_LOW_FREQUENCY = 30.0 -- 30 seconds - for maintenance
}

-- ========================================
-- CORE EVENT SIGNAL SYSTEM
-- ========================================

-- Create a new event signal
function EventDrivenSystem:CreateEventSignal(eventType)
    if eventSignals[eventType] then
        return eventSignals[eventType]
    end
    
    local signal = {
        event = Instance.new("BindableEvent"),
        connections = {},
        lastFired = 0,
        fireCount = 0,
        subscriptionCount = 0
    }
    
    eventSignals[eventType] = signal
    
    -- Initialize statistics
    eventStatistics[eventType] = {
        totalFires = 0,
        totalSubscriptions = 0,
        averageInterval = 0,
        lastFireTime = 0
    }
    
    if config:Get("performance.EVENT_DRIVEN.ENABLE_DETAILED_LOGGING") then
        print(string.format("📡 Created event signal: %s", eventType))
    end
    
    return signal
end

-- Subscribe to an event with automatic cleanup
function EventDrivenSystem:Subscribe(eventType, callback, owner)
    local signal = self:CreateEventSignal(eventType)
    local connection = signal.event.Event:Connect(callback)
    
    -- Track connection for cleanup
    local connectionData = {
        connection = connection,
        owner = owner or "Unknown",
        subscribedAt = tick()
    }
    
    table.insert(signal.connections, connectionData)
    signal.subscriptionCount = signal.subscriptionCount + 1
    
    -- Update statistics
    eventStatistics[eventType].totalSubscriptions = eventStatistics[eventType].totalSubscriptions + 1
    
    if config:Get("performance.EVENT_DRIVEN.ENABLE_DETAILED_LOGGING") then
        print(string.format("📨 Subscribed to %s by %s", eventType, owner))
    end
    
    return connection
end

-- Fire an event with rate limiting
function EventDrivenSystem:FireEvent(eventType, ...)
    local signal = eventSignals[eventType]
    if not signal then
        warn("Attempted to fire non-existent event: " .. eventType)
        return false
    end
    
    local currentTime = tick()
    local minInterval = config:Get("performance.EVENT_DRIVEN.MIN_FIRE_INTERVAL") or 0.01 -- 10ms minimum
    
    -- Rate limiting to prevent spam
    if currentTime - signal.lastFired < minInterval then
        return false
    end
    
    signal.lastFired = currentTime
    signal.fireCount = signal.fireCount + 1
    
    -- Update statistics
    local stats = eventStatistics[eventType]
    stats.totalFires = stats.totalFires + 1
    
    if stats.lastFireTime > 0 then
        local interval = currentTime - stats.lastFireTime
        stats.averageInterval = (stats.averageInterval + interval) / 2
    end
    stats.lastFireTime = currentTime
    
    -- Fire the event
    signal.event:Fire(...)
    
    return true
end

-- ========================================
-- ADAPTIVE MONITORING SYSTEM
-- ========================================

-- Create an adaptive monitor that adjusts frequency based on activity
function EventDrivenSystem:CreateAdaptiveMonitor(monitorName, checkFunction, config)
    config = config or {}
    
    local monitor = {
        name = monitorName,
        checkFunction = checkFunction,
        currentInterval = config.baseInterval or MONITORING_INTERVALS.MEDIUM_FREQUENCY,
        baseInterval = config.baseInterval or MONITORING_INTERVALS.MEDIUM_FREQUENCY,
        minInterval = config.minInterval or MONITORING_INTERVALS.HIGH_FREQUENCY,
        maxInterval = config.maxInterval or MONITORING_INTERVALS.ULTRA_LOW_FREQUENCY,
        
        -- Adaptive behavior
        activityLevel = 0,
        lastChangeTime = 0,
        changeCount = 0,
        isActive = false,
        
        -- Connection tracking
        connection = nil,
        owner = config.owner or "AdaptiveMonitor"
    }
    
    adaptiveMonitors[monitorName] = monitor
    
    if config:Get("performance.EVENT_DRIVEN.ENABLE_DETAILED_LOGGING") then
        print(string.format("🔄 Created adaptive monitor: %s (interval: %.2fs)", monitorName, monitor.currentInterval))
    end
    
    return monitor
end

-- Start an adaptive monitor
function EventDrivenSystem:StartAdaptiveMonitor(monitorName)
    local monitor = adaptiveMonitors[monitorName]
    if not monitor or monitor.isActive then
        return false
    end
    
    monitor.isActive = true
    
    local function monitorLoop()
        if not monitor.isActive then
            return
        end
        
        local changed = false
        
        -- Execute the check function
        local success, result = pcall(monitor.checkFunction)
        if success and result then
            changed = true
            monitor.changeCount = monitor.changeCount + 1
            monitor.lastChangeTime = tick()
        end
        
        -- Adjust interval based on activity
        self:AdjustMonitorInterval(monitor, changed)
        
        -- Schedule next check
        task.wait(monitor.currentInterval)
        task.spawn(monitorLoop)
    end
    
    task.spawn(monitorLoop)
    
    if config:Get("performance.EVENT_DRIVEN.ENABLE_DETAILED_LOGGING") then
        print(string.format("▶️ Started adaptive monitor: %s", monitorName))
    end
    
    return true
end

-- Adjust monitor interval based on activity
function EventDrivenSystem:AdjustMonitorInterval(monitor, activityDetected)
    local currentTime = tick()
    local timeSinceLastChange = currentTime - monitor.lastChangeTime
    
    if activityDetected then
        -- Increase frequency when activity is detected
        monitor.activityLevel = math.min(monitor.activityLevel + 1, 10)
        monitor.currentInterval = math.max(
            monitor.baseInterval / (1 + monitor.activityLevel * 0.2),
            monitor.minInterval
        )
    else
        -- Decrease frequency when no activity
        if timeSinceLastChange > monitor.baseInterval * 5 then
            monitor.activityLevel = math.max(monitor.activityLevel - 0.1, 0)
            monitor.currentInterval = math.min(
                monitor.baseInterval + (monitor.activityLevel * 0.5),
                monitor.maxInterval
            )
        end
    end
end

-- Stop an adaptive monitor
function EventDrivenSystem:StopAdaptiveMonitor(monitorName)
    local monitor = adaptiveMonitors[monitorName]
    if not monitor then
        return false
    end
    
    monitor.isActive = false
    
    if config:Get("performance.EVENT_DRIVEN.ENABLE_DETAILED_LOGGING") then
        print(string.format("⏹️ Stopped adaptive monitor: %s", monitorName))
    end
    
    return true
end

-- ========================================
-- WORLD OBJECT EVENT SYSTEM
-- ========================================

-- Replace polling-based object validation with event-driven approach
function EventDrivenSystem:WaitForWorldObject(objectPath, timeout, callback)
    timeout = timeout or 10
    
    local startTime = tick()
    local objectFound = false
    
    -- Check if object already exists
    local function checkObject()
        local success, object = pcall(function()
            local parts = objectPath:split(".")
            local current = game
            
            for _, part in ipairs(parts) do
                current = current:FindFirstChild(part)
                if not current then
                    return nil
                end
            end
            
            return current
        end)
        
        return success and object ~= nil, object
    end
    
    local exists, object = checkObject()
    if exists then
        if callback then
            callback(true, object)
        end
        self:FireEvent(EVENT_TYPES.WORLD_OBJECT_READY, objectPath, object)
        return true, object
    end
    
    -- Set up adaptive monitoring for the object
    local monitorName = "WorldObject_" .. objectPath:gsub("%.", "_")
    
    self:CreateAdaptiveMonitor(monitorName, function()
        if tick() - startTime >= timeout then
            if callback then
                callback(false, nil)
            end
            self:StopAdaptiveMonitor(monitorName)
            return false
        end
        
        local exists, object = checkObject()
        if exists then
            objectFound = true
            if callback then
                callback(true, object)
            end
            self:FireEvent(EVENT_TYPES.WORLD_OBJECT_READY, objectPath, object)
            self:StopAdaptiveMonitor(monitorName)
            return true
        end
        
        return false
    end, {
        baseInterval = 0.5,
        minInterval = 0.1,
        maxInterval = 2.0,
        owner = "WorldObjectWaiter"
    })
    
    self:StartAdaptiveMonitor(monitorName)
    
    return objectFound, object
end

-- ========================================
-- PLAYER STAT MONITORING SYSTEM
-- ========================================

-- Replace continuous stat checking with event-driven updates
function EventDrivenSystem:MonitorPlayerStat(player, statName, threshold, callback)
    local playerId = tostring(player.UserId)
    local monitorName = string.format("PlayerStat_%s_%s", playerId, statName)
    
    local lastValue = nil
    
    self:CreateAdaptiveMonitor(monitorName, function()
        local leaderstats = player:FindFirstChild("leaderstats")
        if not leaderstats then
            return false
        end
        
        local stat = leaderstats:FindFirstChild(statName)
        if not stat then
            return false
        end
        
        local currentValue = stat.Value
        local changed = lastValue ~= nil and lastValue ~= currentValue
        
        if changed then
            lastValue = currentValue
            
            if callback then
                callback(player, statName, currentValue, lastValue)
            end
            
            self:FireEvent(EVENT_TYPES.PLAYER_STAT_CHANGED, player, statName, currentValue, lastValue)
            
            -- Check threshold
            if threshold and currentValue >= threshold then
                self:FireEvent(EVENT_TYPES.PERFORMANCE_THRESHOLD, player, statName, currentValue, threshold)
            end
        end
        
        lastValue = currentValue
        return changed
    end, {
        baseInterval = 2.0,
        minInterval = 0.5,
        maxInterval = 10.0,
        owner = "PlayerStatMonitor"
    })
    
    self:StartAdaptiveMonitor(monitorName)
    
    -- Cleanup when player leaves
    self:Subscribe("PlayerRemoving", function(leavingPlayer)
        if leavingPlayer == player then
            self:StopAdaptiveMonitor(monitorName)
        end
    end, "PlayerStatCleanup")
end

-- ========================================
-- PERIODIC TASK SYSTEM (REPLACES POLLING LOOPS)
-- ========================================

-- Create a managed periodic task with automatic optimization
function EventDrivenSystem:CreatePeriodicTask(taskName, taskFunction, interval, options)
    options = options or {}
    
    local task = {
        name = taskName,
        taskFunction = taskFunction,
        interval = interval,
        isActive = false,
        
        -- Performance tracking
        executionCount = 0,
        totalExecutionTime = 0,
        averageExecutionTime = 0,
        lastExecutionTime = 0,
        
        -- Adaptive behavior
        adaptiveInterval = options.adaptive and interval or nil,
        minInterval = options.minInterval or interval * 0.1,
        maxInterval = options.maxInterval or interval * 10,
        
        -- Resource management
        owner = options.owner or "PeriodicTask",
        priority = options.priority or 1,
        maxExecutionTime = options.maxExecutionTime or 1.0 -- 1 second max
    }
    
    periodicTasks[taskName] = task
    
    if config:Get("performance.EVENT_DRIVEN.ENABLE_DETAILED_LOGGING") then
        print(string.format("⏰ Created periodic task: %s (interval: %.2fs)", taskName, interval))
    end
    
    return task
end

-- Start a periodic task
function EventDrivenSystem:StartPeriodicTask(taskName)
    local task = periodicTasks[taskName]
    if not task or task.isActive then
        return false
    end
    
    task.isActive = true
    
    local function taskLoop()
        if not task.isActive then
            return
        end
        
        local startTime = tick()
        
        -- Execute task with performance monitoring
        local success, result = pcall(task.taskFunction)
        
        local executionTime = tick() - startTime
        task.executionCount = task.executionCount + 1
        task.totalExecutionTime = task.totalExecutionTime + executionTime
        task.averageExecutionTime = task.totalExecutionTime / task.executionCount
        task.lastExecutionTime = executionTime
        
        -- Warn about long execution times
        if executionTime > task.maxExecutionTime then
            warn(string.format("Periodic task %s took %.3fs (exceeds %.3fs limit)", 
                taskName, executionTime, task.maxExecutionTime))
        end
        
        if not success then
            warn(string.format("Periodic task %s failed: %s", taskName, tostring(result)))
        end
        
        -- Adaptive interval adjustment
        if task.adaptiveInterval then
            self:AdjustTaskInterval(task, success, executionTime)
        end
        
        -- Schedule next execution
        local currentInterval = task.adaptiveInterval or task.interval
        task.wait(currentInterval)
        task.spawn(taskLoop)
    end
    
    task.spawn(taskLoop)
    return true
end

-- Adjust task interval based on performance
function EventDrivenSystem:AdjustTaskInterval(task, success, executionTime)
    if not success or executionTime > task.maxExecutionTime then
        -- Slow down if task is failing or taking too long
        task.adaptiveInterval = math.min(task.adaptiveInterval * 1.5, task.maxInterval)
    elseif executionTime < task.maxExecutionTime * 0.1 then
        -- Speed up if task is very fast
        task.adaptiveInterval = math.max(task.adaptiveInterval * 0.8, task.minInterval)
    end
end

-- Stop a periodic task
function EventDrivenSystem:StopPeriodicTask(taskName)
    local task = periodicTasks[taskName]
    if not task then
        return false
    end
    
    task.isActive = false
    return true
end

-- ========================================
-- SYSTEM STATISTICS AND MONITORING
-- ========================================

-- Get comprehensive performance statistics
function EventDrivenSystem:GetSystemStats()
    local stats = {
        eventSignals = {},
        adaptiveMonitors = {},
        periodicTasks = {},
        totalEventFires = 0,
        totalSubscriptions = 0,
        systemHealth = "Good"
    }
    
    -- Event signal statistics
    for eventType, signal in pairs(eventSignals) do
        stats.eventSignals[eventType] = {
            subscriptions = signal.subscriptionCount,
            fireCount = signal.fireCount,
            lastFired = signal.lastFired,
            averageInterval = eventStatistics[eventType].averageInterval
        }
        stats.totalEventFires = stats.totalEventFires + signal.fireCount
        stats.totalSubscriptions = stats.totalSubscriptions + signal.subscriptionCount
    end
    
    -- Adaptive monitor statistics
    for name, monitor in pairs(adaptiveMonitors) do
        stats.adaptiveMonitors[name] = {
            isActive = monitor.isActive,
            currentInterval = monitor.currentInterval,
            activityLevel = monitor.activityLevel,
            changeCount = monitor.changeCount
        }
    end
    
    -- Periodic task statistics
    for name, task in pairs(periodicTasks) do
        stats.periodicTasks[name] = {
            isActive = task.isActive,
            executionCount = task.executionCount,
            averageExecutionTime = task.averageExecutionTime,
            lastExecutionTime = task.lastExecutionTime
        }
    end
    
    -- Determine system health
    local totalActiveMonitors = 0
    local totalActiveTasks = 0
    
    for _, monitor in pairs(adaptiveMonitors) do
        if monitor.isActive then
            totalActiveMonitors = totalActiveMonitors + 1
        end
    end
    
    for _, task in pairs(periodicTasks) do
        if task.isActive then
            totalActiveTasks = totalActiveTasks + 1
        end
    end
    
    if totalActiveMonitors > 50 or totalActiveTasks > 20 then
        stats.systemHealth = "Warning - High Resource Usage"
    elseif totalActiveMonitors > 100 or totalActiveTasks > 50 then
        stats.systemHealth = "Critical - Excessive Resource Usage"
    end
    
    return stats
end

-- Print detailed system report
function EventDrivenSystem:PrintSystemReport()
    local stats = self:GetSystemStats()
    
    print("📊 EVENT-DRIVEN SYSTEM REPORT")
    print("==============================")
    print(string.format("System Health: %s", stats.systemHealth))
    print(string.format("Total Event Fires: %d", stats.totalEventFires))
    print(string.format("Total Subscriptions: %d", stats.totalSubscriptions))
    
    print("\n📡 EVENT SIGNALS:")
    for eventType, signalStats in pairs(stats.eventSignals) do
        print(string.format("  %s: %d subs, %d fires, %.2fs avg interval", 
            eventType, signalStats.subscriptions, signalStats.fireCount, signalStats.averageInterval))
    end
    
    print("\n🔄 ADAPTIVE MONITORS:")
    for name, monitorStats in pairs(stats.adaptiveMonitors) do
        local status = monitorStats.isActive and "ACTIVE" or "INACTIVE"
        print(string.format("  %s: %s, %.2fs interval, %d activity, %d changes", 
            name, status, monitorStats.currentInterval, monitorStats.activityLevel, monitorStats.changeCount))
    end
    
    print("\n⏰ PERIODIC TASKS:")
    for name, taskStats in pairs(stats.periodicTasks) do
        local status = taskStats.isActive and "ACTIVE" or "INACTIVE"
        print(string.format("  %s: %s, %d executions, %.3fs avg time", 
            name, status, taskStats.executionCount, taskStats.averageExecutionTime))
    end
end

-- ========================================
-- CLEANUP AND SHUTDOWN
-- ========================================

-- Cleanup all event-driven systems
function EventDrivenSystem:Cleanup()
    print("🧹 Cleaning up EventDrivenSystem...")
    
    local cleanupStats = {
        eventSignals = 0,
        adaptiveMonitors = 0,
        periodicTasks = 0,
        connections = 0
    }
    
    -- Stop all adaptive monitors
    for name, monitor in pairs(adaptiveMonitors) do
        if monitor.isActive then
            self:StopAdaptiveMonitor(name)
            cleanupStats.adaptiveMonitors = cleanupStats.adaptiveMonitors + 1
        end
    end
    
    -- Stop all periodic tasks
    for name, task in pairs(periodicTasks) do
        if task.isActive then
            self:StopPeriodicTask(name)
            cleanupStats.periodicTasks = cleanupStats.periodicTasks + 1
        end
    end
    
    -- Cleanup event signals and connections
    for eventType, signal in pairs(eventSignals) do
        for _, connectionData in ipairs(signal.connections) do
            if connectionData.connection then
                connectionData.connection:Disconnect()
                cleanupStats.connections = cleanupStats.connections + 1
            end
        end
        
        signal.event:Destroy()
        cleanupStats.eventSignals = cleanupStats.eventSignals + 1
    end
    
    -- Clear all registries
    eventSignals = {}
    adaptiveMonitors = {}
    periodicTasks = {}
    eventStatistics = {}
    
    print(string.format("✅ EventDrivenSystem cleanup complete:"))
    print(string.format("   Event Signals: %d", cleanupStats.eventSignals))
    print(string.format("   Adaptive Monitors: %d", cleanupStats.adaptiveMonitors))
    print(string.format("   Periodic Tasks: %d", cleanupStats.periodicTasks))
    print(string.format("   Connections: %d", cleanupStats.connections))
    
    return cleanupStats
end

-- Initialize the event-driven system
function EventDrivenSystem:Initialize()
    print("🚀 Initializing EventDrivenSystem...")
    
    -- Create default event signals
    for _, eventType in pairs(EVENT_TYPES) do
        self:CreateEventSignal(eventType)
    end
    
    -- Set up system health monitoring
    self:CreatePeriodicTask("SystemHealthMonitor", function()
        local stats = self:GetSystemStats()
        self:FireEvent(EVENT_TYPES.SYSTEM_HEALTH_UPDATE, stats)
        
        if stats.systemHealth ~= "Good" then
            warn("EventDrivenSystem health warning: " .. stats.systemHealth)
        end
    end, 60, { -- Check every minute
        adaptive = true,
        owner = "EventDrivenSystem"
    })
    
    self:StartPeriodicTask("SystemHealthMonitor")
    
    print("✅ EventDrivenSystem initialized successfully")
    return true
end

return EventDrivenSystem
