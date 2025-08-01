-- EventDrivenSystemManager.luau
-- Converts performance-destroying polling loops to efficient event-driven patterns
-- Provides BindableEvents, signal systems, and adaptive monitoring

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local _RunService = game:GetService("RunService")
local HttpService = game:GetService("HttpService")

local ServiceConnectionHelper = require(ReplicatedStorage.Shared.utils.ServiceConnectionHelper)

local EventDrivenSystemManager = {}

-- Connection helper for this system
local connectionHelper = ServiceConnectionHelper.CreateServiceHelper("EventDrivenSystemManager")

-- ========================================
-- EVENT SYSTEM CONFIGURATION
-- ========================================

local EVENT_CONFIG = {
    -- Adaptive monitoring settings
    adaptiveMonitoring = {
        enabled = true,
        baseInterval = 5.0,      -- Start with 5 second intervals
        minInterval = 0.1,       -- Minimum 100ms for critical systems
        maxInterval = 60.0,      -- Maximum 1 minute for idle systems
        adaptationRate = 0.1,    -- How fast to adapt intervals
        activityThreshold = 0.05 -- Consider active if value changes by 5%
    },
    
    -- Signal system configuration
    signalSystem = {
        poolSize = 100,         -- Pre-allocated signal pool
        maxSignals = 1000,      -- Maximum concurrent signals
        cleanupInterval = 300,  -- Clean unused signals every 5 minutes
        debounceTime = 0.016   -- ~60fps debouncing
    },
    
    -- Performance monitoring
    performance = {
        trackConversions = true,
        trackSignalUsage = true,
        logOptimizations = true,
        measureLatency = true
    }
}

-- ========================================
-- SYSTEM STATE
-- ========================================

local SystemState = {
    -- Event-driven monitors
    adaptiveMonitors = {},      -- {[id] = AdaptiveMonitor}
    signalRegistry = {},        -- {[name] = BindableEvent}
    eventSubscriptions = {},    -- {[eventName] = {[id] = callback}}
    
    -- Performance tracking
    performance = {
        pollingLoopsConverted = 0,
        signalsCreated = 0,
        eventsDispatched = 0,
        averageLatency = 0,
        memoryUsageReduction = 0
    },
    
    -- Converted systems tracking
    convertedSystems = {},      -- Track what we've converted
    activeSignals = {},         -- Currently active signals
    signalPool = {}            -- Pre-allocated signal pool
}

-- ========================================
-- ADAPTIVE MONITORING SYSTEM
-- ========================================

local AdaptiveMonitor = {}
AdaptiveMonitor.__index = AdaptiveMonitor

function AdaptiveMonitor.new(config)
    local self = setmetatable({}, AdaptiveMonitor)
    
    self.id = HttpService:GenerateGUID(false)
    self.name = config.name or "UnnamedMonitor"
    self.getValue = config.getValue -- Function to get current value
    self.onChanged = config.onChanged or function() end
    self.onSignificantChange = config.onSignificantChange or function() end
    
    -- Adaptive settings
    self.currentInterval = config.initialInterval or EVENT_CONFIG.adaptiveMonitoring.baseInterval
    self.minInterval = config.minInterval or EVENT_CONFIG.adaptiveMonitoring.minInterval
    self.maxInterval = config.maxInterval or EVENT_CONFIG.adaptiveMonitoring.maxInterval
    self.activityThreshold = config.activityThreshold or EVENT_CONFIG.adaptiveMonitoring.activityThreshold
    
    -- State tracking
    self.lastValue = nil
    self.lastChangeTime = 0
    self.changeFrequency = 0
    self.isActive = false
    self.connectionId = nil
    
    -- Performance metrics
    self.checksPerformed = 0
    self.changesDetected = 0
    self.adaptations = 0
    
    return self
end

function AdaptiveMonitor:start()
    if self.connectionId then
        self:stop() -- Stop existing monitoring
    end
    
    -- Create adaptive monitoring loop
    self.connectionId = connectionHelper:ConnectRunServiceEvent("Heartbeat", function()
        self:performCheck()
    end, {
        description = "Adaptive monitor: " .. self.name,
        connectionType = "HEARTBEAT"
    })
    
    self.isActive = true
    print("📈 Started adaptive monitor: " .. self.name)
end

function AdaptiveMonitor:stop()
    if self.connectionId then
        connectionHelper:DisconnectConnection(self.connectionId)
        self.connectionId = nil
    end
    
    self.isActive = false
    print("📉 Stopped adaptive monitor: " .. self.name)
end

function AdaptiveMonitor:performCheck()
    local currentTime = tick()
    
    -- Check if it's time for a sample
    if currentTime - (self.lastCheckTime or 0) < self.currentInterval then
        return
    end
    
    self.lastCheckTime = currentTime
    self.checksPerformed = self.checksPerformed + 1
    
    -- Get current value
    local success, currentValue = pcall(self.getValue)
    if not success then
        warn("AdaptiveMonitor error in getValue: " .. tostring(currentValue))
        return
    end
    
    -- Check for changes
    if self.lastValue ~= nil then
        local hasChanged = self:hasSignificantChange(self.lastValue, currentValue)
        
        if hasChanged then
            self.changesDetected = self.changesDetected + 1
            self.lastChangeTime = currentTime
            
            -- Notify of change
            self.onChanged(currentValue, self.lastValue)
            
            -- Check for significant change
            if self:isSignificantChange(self.lastValue, currentValue) then
                self.onSignificantChange(currentValue, self.lastValue)
            end
        end
    end
    
    self.lastValue = currentValue
    
    -- Adapt monitoring frequency
    self:adaptInterval(currentTime)
end

function AdaptiveMonitor:hasSignificantChange(oldValue, newValue)
    if type(oldValue) ~= type(newValue) then
        return true
    end
    
    if type(oldValue) == "number" then
        local change = math.abs(newValue - oldValue)
        local threshold = math.abs(oldValue) * self.activityThreshold
        return change > threshold
    elseif type(oldValue) == "table" then
        return not self:deepEqual(oldValue, newValue)
    else
        return oldValue ~= newValue
    end
end

function AdaptiveMonitor:isSignificantChange(oldValue, newValue)
    -- More stringent check for significant changes
    local threshold = self.activityThreshold * 2
    
    if type(oldValue) == "number" then
        local change = math.abs(newValue - oldValue)
        local significantThreshold = math.abs(oldValue) * threshold
        return change > significantThreshold
    else
        return self:hasSignificantChange(oldValue, newValue)
    end
end

function AdaptiveMonitor:adaptInterval(currentTime)
    local timeSinceLastChange = currentTime - self.lastChangeTime
    local adaptationRate = EVENT_CONFIG.adaptiveMonitoring.adaptationRate
    
    -- Adapt based on activity
    if timeSinceLastChange < 5 then
        -- Recent activity - increase frequency
        self.currentInterval = math.max(
            self.minInterval,
            self.currentInterval * (1 - adaptationRate)
        )
    else
        -- No recent activity - decrease frequency
        self.currentInterval = math.min(
            self.maxInterval,
            self.currentInterval * (1 + adaptationRate)
        )
    end
    
    self.adaptations = self.adaptations + 1
end

function AdaptiveMonitor:deepEqual(t1, t2)
    if t1 == t2 then return true end
    if type(t1) ~= "table" or type(t2) ~= "table" then return false end
    
    for k, v in pairs(t1) do
        if not self:deepEqual(v, t2[k]) then return false end
    end
    
    for k, v in pairs(t2) do
        if not self:deepEqual(v, t1[k]) then return false end
    end
    
    return true
end

function AdaptiveMonitor:getMetrics()
    return {
        name = self.name,
        currentInterval = self.currentInterval,
        checksPerformed = self.checksPerformed,
        changesDetected = self.changesDetected,
        adaptations = self.adaptations,
        efficiency = self.checksPerformed > 0 and (self.changesDetected / self.checksPerformed) or 0,
        isActive = self.isActive
    }
end

-- ========================================
-- SIGNAL SYSTEM
-- ========================================

function EventDrivenSystemManager:createSignal(signalName, config)
    config = config or {}
    
    if SystemState.signalRegistry[signalName] then
        warn("Signal already exists: " .. signalName)
        return SystemState.signalRegistry[signalName]
    end
    
    -- Get signal from pool or create new
    local signal = self:getPooledSignal() or Instance.new("BindableEvent")
    signal.Name = signalName
    
    -- Configure signal
    local signalConfig = {
        signal = signal,
        debounceTime = config.debounceTime or EVENT_CONFIG.signalSystem.debounceTime,
        lastFired = 0,
        fireCount = 0,
        subscribers = {},
        created = tick()
    }
    
    SystemState.signalRegistry[signalName] = signalConfig
    SystemState.performance.signalsCreated = SystemState.performance.signalsCreated + 1
    
    print("📡 Created signal: " .. signalName)
    return signal
end

function EventDrivenSystemManager:getSignal(signalName)
    local signalConfig = SystemState.signalRegistry[signalName]
    return signalConfig and signalConfig.signal or nil
end

function EventDrivenSystemManager:fireSignal(signalName, ...)
    local args = {...}
    local signalConfig = SystemState.signalRegistry[signalName]
    if not signalConfig then
        warn("Signal not found: " .. signalName)
        return false
    end
    
    local currentTime = tick()
    
    -- Apply debouncing
    if currentTime - signalConfig.lastFired < signalConfig.debounceTime then
        return false -- Debounced
    end
    
    signalConfig.lastFired = currentTime
    signalConfig.fireCount = signalConfig.fireCount + 1
    SystemState.performance.eventsDispatched = SystemState.performance.eventsDispatched + 1
    
    -- Fire the signal
    local success = pcall(function()
        signalConfig.signal:Fire(table.unpack(args))
    end)
    
    if not success then
        warn("Failed to fire signal: " .. signalName)
        return false
    end
    
    return true
end

function EventDrivenSystemManager:connectToSignal(signalName, callback, config)
    config = config or {}
    
    local signalConfig = SystemState.signalRegistry[signalName]
    if not signalConfig then
        warn("Signal not found: " .. signalName)
        return nil
    end
    
    -- Create managed connection
    local connectionId = connectionHelper:TrackConnection(
        signalConfig.signal.Event:Connect(callback),
        {
            description = "Signal connection: " .. signalName,
            connectionType = "SIGNAL"
        }
    )
    
    -- Track subscription
    if not SystemState.eventSubscriptions[signalName] then
        SystemState.eventSubscriptions[signalName] = {}
    end
    SystemState.eventSubscriptions[signalName][connectionId] = callback
    
    signalConfig.subscribers[connectionId] = {
        callback = callback,
        connected = tick(),
        callCount = 0
    }
    
    return connectionId
end

function EventDrivenSystemManager:getPooledSignal()
    if #SystemState.signalPool > 0 then
        return table.remove(SystemState.signalPool)
    end
    return nil
end

function EventDrivenSystemManager:returnSignalToPool(signal)
    if #SystemState.signalPool < EVENT_CONFIG.signalSystem.poolSize then
        -- Reset signal state
        signal.Name = "PooledSignal"
        table.insert(SystemState.signalPool, signal)
        return true
    end
    
    -- Pool is full, destroy signal
    signal:Destroy()
    return false
end

-- ========================================
-- POLLING LOOP CONVERTERS
-- ========================================

function EventDrivenSystemManager:convertPollingToEvents(pollingConfig)
    local conversionId = HttpService:GenerateGUID(false)
    
    local conversion = {
        id = conversionId,
        name = pollingConfig.name or "UnnamedConversion",
        originalInterval = pollingConfig.interval or 1.0,
        checkFunction = pollingConfig.checkFunction,
        onChanged = pollingConfig.onChanged,
        onStarted = pollingConfig.onStarted,
        onStopped = pollingConfig.onStopped,
        created = tick()
    }
    
    -- Create adaptive monitor for this conversion
    local monitor = AdaptiveMonitor.new({
        name = conversion.name,
        getValue = conversion.checkFunction,
        onChanged = conversion.onChanged,
        initialInterval = conversion.originalInterval,
        minInterval = pollingConfig.minInterval or 0.1,
        maxInterval = pollingConfig.maxInterval or 30.0
    })
    
    SystemState.adaptiveMonitors[conversionId] = monitor
    SystemState.convertedSystems[conversionId] = conversion
    SystemState.performance.pollingLoopsConverted = SystemState.performance.pollingLoopsConverted + 1
    
    -- Start monitoring
    monitor:start()
    
    if conversion.onStarted then
        conversion.onStarted()
    end
    
    print("🔄 Converted polling loop to adaptive monitoring: " .. conversion.name)
    return conversionId
end

function EventDrivenSystemManager:stopConversion(conversionId)
    local monitor = SystemState.adaptiveMonitors[conversionId]
    local conversion = SystemState.convertedSystems[conversionId]
    
    if monitor then
        monitor:stop()
        SystemState.adaptiveMonitors[conversionId] = nil
    end
    
    if conversion and conversion.onStopped then
        conversion.onStopped()
    end
    
    SystemState.convertedSystems[conversionId] = nil
    print("⏹️ Stopped conversion: " .. (conversion and conversion.name or conversionId))
end

-- ========================================
-- SPECIALIZED CONVERTERS
-- ========================================

-- Convert player stat monitoring
function EventDrivenSystemManager:createPlayerStatMonitor(player, statName, onChanged)
    local signalName = "PlayerStat_" .. player.Name .. "_" .. statName
    self:createSignal(signalName)
    
    return self:convertPollingToEvents({
        name = "PlayerStat_" .. statName,
        interval = 1.0,
        checkFunction = function()
            if not player.Parent then return nil end
            local leaderstats = player:FindFirstChild("leaderstats")
            if not leaderstats then return nil end
            local stat = leaderstats:FindFirstChild(statName)
            return stat and stat.Value or nil
        end,
        onChanged = function(newValue, oldValue)
            self:fireSignal(signalName, player, newValue, oldValue)
            if onChanged then onChanged(newValue, oldValue) end
        end,
        minInterval = 0.5,
        maxInterval = 10.0
    })
end

-- Convert world state monitoring
function EventDrivenSystemManager:createWorldStateMonitor(statePath, onChanged)
    local signalName = "WorldState_" .. statePath:gsub("%.", "_")
    self:createSignal(signalName)
    
    return self:convertPollingToEvents({
        name = "WorldState_" .. statePath,
        interval = 2.0,
        checkFunction = function()
            local current = workspace
            for part in statePath:gmatch("[^%.]+") do
                current = current:FindFirstChild(part)
                if not current then return nil end
            end
            return current
        end,
        onChanged = function(newValue, oldValue)
            self:fireSignal(signalName, newValue, oldValue)
            if onChanged then onChanged(newValue, oldValue) end
        end,
        minInterval = 1.0,
        maxInterval = 30.0
    })
end

-- Convert performance monitoring
function EventDrivenSystemManager:createPerformanceMonitor(metricName, getMetricFunction, onThresholdExceeded)
    local signalName = "Performance_" .. metricName
    self:createSignal(signalName)
    
    return self:convertPollingToEvents({
        name = "Performance_" .. metricName,
        interval = 5.0,
        checkFunction = getMetricFunction,
        onChanged = function(newValue, oldValue)
            self:fireSignal(signalName, newValue, oldValue)
            
            -- Check thresholds
            if onThresholdExceeded and type(newValue) == "number" then
                onThresholdExceeded(newValue, oldValue)
            end
        end,
        minInterval = 1.0,
        maxInterval = 60.0
    })
end

-- ========================================
-- BATCH OPERATION CONVERTERS
-- ========================================

function EventDrivenSystemManager:convertBatchOperations(batchConfig)
    local signalName = "BatchOperation_" .. (batchConfig.name or "Unnamed")
    self:createSignal(signalName)
    
    local batchState = {
        items = {},
        lastProcessed = 0,
        processingInterval = batchConfig.interval or 1.0,
        maxBatchSize = batchConfig.maxBatchSize or 50
    }
    
    -- Convert batch processing to event-driven
    return self:convertPollingToEvents({
        name = "BatchProcessor_" .. (batchConfig.name or "Unnamed"),
        interval = batchState.processingInterval,
        checkFunction = function()
            return #batchState.items
        end,
        onChanged = function(newCount, oldCount)
            if newCount > 0 and (newCount >= batchState.maxBatchSize or 
                                 tick() - batchState.lastProcessed > batchState.processingInterval) then
                
                -- Process batch
                local itemsToProcess = {}
                for i = 1, math.min(newCount, batchState.maxBatchSize) do
                    table.insert(itemsToProcess, table.remove(batchState.items, 1))
                end
                
                self:fireSignal(signalName, itemsToProcess)
                batchState.lastProcessed = tick()
                
                if batchConfig.onBatchProcessed then
                    batchConfig.onBatchProcessed(itemsToProcess)
                end
            end
        end,
        minInterval = 0.1,
        maxInterval = batchState.processingInterval * 2
    })
end

-- ========================================
-- SYSTEM MANAGEMENT
-- ========================================

function EventDrivenSystemManager:initialize()
    print("🚀 Initializing EventDrivenSystemManager...")
    
    -- Pre-allocate signal pool
    for i = 1, EVENT_CONFIG.signalSystem.poolSize do
        table.insert(SystemState.signalPool, Instance.new("BindableEvent"))
    end
    
    -- Set up cleanup routine
    connectionHelper:ConnectRunServiceEvent("Heartbeat", function()
        self:performMaintenance()
    end, {
        description = "EventDrivenSystemManager maintenance"
    })
    
    -- Set up automatic cleanup
    connectionHelper:AddToShutdownSequence()
    
    print("✅ EventDrivenSystemManager initialized")
end

function EventDrivenSystemManager:performMaintenance()
    local currentTime = tick()
    
    -- Only run maintenance every 5 minutes
    if not self.lastMaintenance then
        self.lastMaintenance = 0
    end
    
    if currentTime - self.lastMaintenance < 300 then
        return
    end
    
    self.lastMaintenance = currentTime
    
    -- Clean up unused signals
    for signalName, signalConfig in pairs(SystemState.signalRegistry) do
        if currentTime - signalConfig.lastFired > EVENT_CONFIG.signalSystem.cleanupInterval then
            if #signalConfig.subscribers == 0 then
                self:returnSignalToPool(signalConfig.signal)
                SystemState.signalRegistry[signalName] = nil
                print("🗑️ Cleaned up unused signal: " .. signalName)
            end
        end
    end
end

function EventDrivenSystemManager:getSystemMetrics()
    local metrics = {
        performance = SystemState.performance,
        activeMonitors = {},
        signalMetrics = {},
        systemHealth = {
            monitorCount = 0,
            signalCount = 0,
            totalEfficiency = 0
        }
    }
    
    -- Collect monitor metrics
    for id, monitor in pairs(SystemState.adaptiveMonitors) do
        local monitorMetrics = monitor:getMetrics()
        metrics.activeMonitors[id] = monitorMetrics
        metrics.systemHealth.monitorCount = metrics.systemHealth.monitorCount + 1
        metrics.systemHealth.totalEfficiency = metrics.systemHealth.totalEfficiency + monitorMetrics.efficiency
    end
    
    -- Collect signal metrics
    for signalName, signalConfig in pairs(SystemState.signalRegistry) do
        metrics.signalMetrics[signalName] = {
            fireCount = signalConfig.fireCount,
            subscriberCount = 0,
            lastFired = signalConfig.lastFired,
            created = signalConfig.created
        }
        
        for _ in pairs(signalConfig.subscribers) do
            metrics.signalMetrics[signalName].subscriberCount = metrics.signalMetrics[signalName].subscriberCount + 1
        end
        
        metrics.systemHealth.signalCount = metrics.systemHealth.signalCount + 1
    end
    
    -- Calculate average efficiency
    if metrics.systemHealth.monitorCount > 0 then
        metrics.systemHealth.totalEfficiency = metrics.systemHealth.totalEfficiency / metrics.systemHealth.monitorCount
    end
    
    return metrics
end

function EventDrivenSystemManager:printDiagnostics()
    local metrics = self:getSystemMetrics()
    
    print("📊 Event-Driven System Diagnostics:")
    print("===================================")
    
    print("🔧 Performance Metrics:")
    print("  • Polling loops converted: " .. metrics.performance.pollingLoopsConverted)
    print("  • Signals created: " .. metrics.performance.signalsCreated)
    print("  • Events dispatched: " .. metrics.performance.eventsDispatched)
    
    print("📈 Active Monitors:")
    for id, monitorMetrics in pairs(metrics.activeMonitors) do
        print(string.format("  • %s: %.1f%% efficient, %.2fs interval", 
            monitorMetrics.name, 
            monitorMetrics.efficiency * 100,
            monitorMetrics.currentInterval))
    end
    
    print("📡 Signal Usage:")
    for signalName, signalMetrics in pairs(metrics.signalMetrics) do
        print(string.format("  • %s: %d fires, %d subscribers", 
            signalName, 
            signalMetrics.fireCount, 
            signalMetrics.subscriberCount))
    end
    
    print("🏥 System Health:")
    print(string.format("  • Monitors: %d active", metrics.systemHealth.monitorCount))
    print(string.format("  • Signals: %d active", metrics.systemHealth.signalCount))
    print(string.format("  • Average efficiency: %.1f%%", metrics.systemHealth.totalEfficiency * 100))
end

-- ========================================
-- CLEANUP
-- ========================================

function EventDrivenSystemManager:cleanup()
    print("🧹 Cleaning up EventDrivenSystemManager...")
    
    -- Stop all monitors
    for conversionId in pairs(SystemState.adaptiveMonitors) do
        self:stopConversion(conversionId)
    end
    
    -- Clean up all signals
    for signalName, signalConfig in pairs(SystemState.signalRegistry) do
        signalConfig.signal:Destroy()
    end
    
    -- Clean up signal pool
    for _, signal in ipairs(SystemState.signalPool) do
        signal:Destroy()
    end
    
    -- Clean up connections
    connectionHelper:CleanupAll()
    
    print("✅ EventDrivenSystemManager cleanup completed")
end

-- Initialize the system
EventDrivenSystemManager:initialize()

return EventDrivenSystemManager
