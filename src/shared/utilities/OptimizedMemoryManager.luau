-- OptimizedMemoryManager.luau
-- High-performance memory management system with object pooling, leak detection, and adaptive cleanup
-- Replaces tight polling loops with event-driven patterns and intelligent resource management

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local HttpService = game:GetService("HttpService")
local ConfigurationManager = require(ReplicatedStorage.Shared.core.ConfigurationManager)

local OptimizedMemoryManager = {}

-- ========================================
-- MEMORY TRACKING AND OPTIMIZATION
-- ========================================

-- Efficient collections using hash tables instead of arrays
local activeConnections = {} -- [playerId][connectionId] = connectionData
local activeTweens = {} -- [playerId][tweenId] = tweenData
local activeTasks = {} -- [playerId][taskId] = taskData
local activeGameObjects = {} -- [playerId][objectId] = objectData
local playerCleanupCallbacks = {} -- [playerId][callbackId] = function

-- Object pools for frequently created/destroyed objects
local objectPools = {
    uiElements = {},
    particles = {},
    sounds = {},
    parts = {},
    connections = {}
}

-- Memory pressure monitoring
local memoryStats = {
    lastGCTime = 0,
    gcCount = 0,
    memoryPressure = "LOW", -- LOW, MEDIUM, HIGH, CRITICAL
    adaptiveCleanupActive = false,
    performanceMetrics = {
        avgCleanupTime = 0,
        maxCleanupTime = 0,
        cleanupOperations = 0
    }
}

-- Event-driven cleanup system
local cleanupEvents = {
    onPlayerLeaving = Instance.new("BindableEvent"),
    onMemoryPressure = Instance.new("BindableEvent"),
    onResourceLimitReached = Instance.new("BindableEvent"),
    onPerformanceDegradation = Instance.new("BindableEvent")
}

-- Configuration access
local config = ConfigurationManager.getInstance()

-- ========================================
-- OBJECT POOLING SYSTEM
-- ========================================

-- Create object pool for reusable objects
function OptimizedMemoryManager:CreateObjectPool(poolName, createFunction, resetFunction, initialSize)
    initialSize = initialSize or config:Get("memory.OBJECT_POOLS.DEFAULT_INITIAL_SIZE")
    
    objectPools[poolName] = {
        available = {},
        inUse = {},
        createFunction = createFunction,
        resetFunction = resetFunction,
        stats = {
            created = 0,
            reused = 0,
            maxConcurrent = 0
        }
    }
    
    -- Pre-populate pool
    for i = 1, initialSize do
        local object = createFunction()
        table.insert(objectPools[poolName].available, object)
        objectPools[poolName].stats.created = objectPools[poolName].stats.created + 1
    end
    
    if config:Get("memory.TRACKING.ENABLE_DETAILED_LOGGING") then
        print("🏊 Created object pool '" .. poolName .. "' with " .. initialSize .. " objects")
    end
    
    return objectPools[poolName]
end

-- Get object from pool (create if needed)
function OptimizedMemoryManager:GetPooledObject(poolName)
    local pool = objectPools[poolName]
    if not pool then
        warn("❌ Object pool '" .. poolName .. "' does not exist")
        return nil
    end
    
    local object
    
    if #pool.available > 0 then
        -- Reuse existing object
        object = table.remove(pool.available)
        pool.stats.reused = pool.stats.reused + 1
    else
        -- Create new object
        object = pool.createFunction()
        pool.stats.created = pool.stats.created + 1
    end
    
    local objectId = HttpService:GenerateGUID(false)
    pool.inUse[objectId] = object
    
    -- Update max concurrent usage
    local currentInUse = 0
    for _ in pairs(pool.inUse) do
        currentInUse = currentInUse + 1
    end
    
    if currentInUse > pool.stats.maxConcurrent then
        pool.stats.maxConcurrent = currentInUse
    end
    
    return object, objectId
end

-- Return object to pool
function OptimizedMemoryManager:ReturnPooledObject(poolName, objectId)
    local pool = objectPools[poolName]
    if not pool then
        warn("❌ Object pool '" .. poolName .. "' does not exist")
        return false
    end
    
    local object = pool.inUse[objectId]
    if not object then
        warn("❌ Object with ID '" .. objectId .. "' not found in pool '" .. poolName .. "'")
        return false
    end
    
    -- Reset object to clean state
    if pool.resetFunction then
        pool.resetFunction(object)
    end
    
    -- Return to available pool
    table.insert(pool.available, object)
    pool.inUse[objectId] = nil
    
    return true
end

-- Get pool statistics
function OptimizedMemoryManager:GetPoolStats(poolName)
    local pool = objectPools[poolName]
    if not pool then
        return nil
    end
    
    local availableCount = #pool.available
    local inUseCount = 0
    for _ in pairs(pool.inUse) do
        inUseCount = inUseCount + 1
    end
    
    return {
        available = availableCount,
        inUse = inUseCount,
        total = availableCount + inUseCount,
        created = pool.stats.created,
        reused = pool.stats.reused,
        maxConcurrent = pool.stats.maxConcurrent,
        reuseRatio = pool.stats.reused / math.max(pool.stats.created, 1)
    }
end

-- ========================================
-- EFFICIENT CONNECTION MANAGEMENT
-- ========================================

-- Register connection with optimized storage and automatic cleanup
function OptimizedMemoryManager:RegisterConnection(playerId, connectionName, connection, autoCleanup)
    playerId = tostring(playerId)
    autoCleanup = autoCleanup ~= false -- Default true
    
    if not activeConnections[playerId] then
        activeConnections[playerId] = {}
    end
    
    -- Check limits
    local currentCount = 0
    for _ in pairs(activeConnections[playerId]) do
        currentCount = currentCount + 1
    end
    
    local maxConnections = config:Get("memory.LIMITS.MAX_CONNECTIONS_PER_PLAYER")
    if currentCount >= maxConnections then
        warn("⚠️ Player " .. playerId .. " exceeded connection limit (" .. maxConnections .. ")")
        return false
    end
    
    local connectionId = HttpService:GenerateGUID(false)
    activeConnections[playerId][connectionId] = {
        connection = connection,
        name = connectionName,
        timestamp = tick(),
        autoCleanup = autoCleanup,
        type = "RBXScriptConnection"
    }
    
    -- Auto-cleanup on completion if it's a one-time connection
    if autoCleanup and connection.Completed then
        connection.Completed:Connect(function()
            self:DisconnectConnection(playerId, connectionId)
        end)
    end
    
    if config:Get("memory.TRACKING.ENABLE_DETAILED_LOGGING") then
        print("🔗 Registered connection: " .. connectionName .. " (" .. connectionId .. ") for player " .. playerId)
    end
    
    return connectionId
end

-- Batch disconnect connections for efficiency
function OptimizedMemoryManager:BatchDisconnectConnections(playerId, connectionIds)
    playerId = tostring(playerId)
    local disconnectedCount = 0
    
    if not activeConnections[playerId] then
        return 0
    end
    
    for _, connectionId in ipairs(connectionIds) do
        if self:DisconnectConnection(playerId, connectionId) then
            disconnectedCount = disconnectedCount + 1
        end
    end
    
    return disconnectedCount
end

-- Disconnect connection by ID
function OptimizedMemoryManager:DisconnectConnection(playerId, connectionId)
    playerId = tostring(playerId)
    
    if not activeConnections[playerId] or not activeConnections[playerId][connectionId] then
        return false
    end
    
    local connectionData = activeConnections[playerId][connectionId]
    
    if connectionData.connection and typeof(connectionData.connection) == "RBXScriptConnection" then
        connectionData.connection:Disconnect()
    end
    
    activeConnections[playerId][connectionId] = nil
    
    if config:Get("memory.TRACKING.ENABLE_DETAILED_LOGGING") then
        print("🔌 Disconnected connection: " .. connectionData.name .. " (" .. connectionId .. ") for player " .. playerId)
    end
    
    return true
end

-- ========================================
-- MEMORY PRESSURE MONITORING
-- ========================================

-- Monitor memory pressure and adapt cleanup strategies
function OptimizedMemoryManager:MonitorMemoryPressure()
    local previousMemory = 0
    local memoryCheckInterval = config:Get("memory.MONITORING.PRESSURE_CHECK_INTERVAL")
    
    task.spawn(function()
        while true do
            task.wait(memoryCheckInterval)
            
            -- Force garbage collection to get accurate reading
            collectgarbage("collect")
            local currentMemory = collectgarbage("count")
            
            -- Calculate memory growth rate
            local memoryGrowth = currentMemory - previousMemory
            local growthRate = memoryGrowth / memoryCheckInterval
            
            -- Determine memory pressure level
            local pressureLevel = self:CalculateMemoryPressure(currentMemory, growthRate)
            
            if pressureLevel ~= memoryStats.memoryPressure then
                memoryStats.memoryPressure = pressureLevel
                self:HandleMemoryPressureChange(pressureLevel)
                cleanupEvents.onMemoryPressure:Fire(pressureLevel, currentMemory, growthRate)
            end
            
            previousMemory = currentMemory
            
            if config:Get("memory.TRACKING.ENABLE_PERFORMANCE_MONITORING") then
                print("📊 Memory: " .. math.floor(currentMemory) .. "KB, Growth: " .. 
                      string.format("%.2f", growthRate) .. "KB/s, Pressure: " .. pressureLevel)
            end
        end
    end)
end

-- Calculate memory pressure level
function OptimizedMemoryManager:CalculateMemoryPressure(currentMemory, growthRate)
    local lowThreshold = config:Get("memory.PRESSURE_THRESHOLDS.LOW_MEMORY_KB")
    local mediumThreshold = config:Get("memory.PRESSURE_THRESHOLDS.MEDIUM_MEMORY_KB")
    local highThreshold = config:Get("memory.PRESSURE_THRESHOLDS.HIGH_MEMORY_KB")
    local criticalThreshold = config:Get("memory.PRESSURE_THRESHOLDS.CRITICAL_MEMORY_KB")
    
    local highGrowthRate = config:Get("memory.PRESSURE_THRESHOLDS.HIGH_GROWTH_RATE_KB_PER_SEC")
    
    if currentMemory > criticalThreshold or growthRate > highGrowthRate * 2 then
        return "CRITICAL"
    elseif currentMemory > highThreshold or growthRate > highGrowthRate then
        return "HIGH"
    elseif currentMemory > mediumThreshold or growthRate > highGrowthRate * 0.5 then
        return "MEDIUM"
    elseif currentMemory > lowThreshold then
        return "LOW"
    else
        return "MINIMAL"
    end
end

-- Handle memory pressure changes with adaptive strategies
function OptimizedMemoryManager:HandleMemoryPressureChange(pressureLevel)
    print("🔥 Memory pressure changed to: " .. pressureLevel)
    
    if pressureLevel == "CRITICAL" then
        -- Immediate aggressive cleanup
        self:EmergencyCleanup()
        memoryStats.adaptiveCleanupActive = true
        
    elseif pressureLevel == "HIGH" then
        -- Aggressive cleanup with object pool trimming
        self:AggressiveCleanup()
        self:TrimObjectPools(0.5) -- Remove 50% of available objects
        memoryStats.adaptiveCleanupActive = true
        
    elseif pressureLevel == "MEDIUM" then
        -- Moderate cleanup
        self:ModerateCleanup()
        self:TrimObjectPools(0.25) -- Remove 25% of available objects
        memoryStats.adaptiveCleanupActive = true
        
    elseif pressureLevel == "LOW" then
        -- Light cleanup
        self:LightCleanup()
        memoryStats.adaptiveCleanupActive = false
        
    else -- MINIMAL
        -- No special cleanup needed
        memoryStats.adaptiveCleanupActive = false
    end
end

-- ========================================
-- ADAPTIVE CLEANUP STRATEGIES
-- ========================================

-- Emergency cleanup for critical memory pressure
function OptimizedMemoryManager:EmergencyCleanup()
    local startTime = tick()
    print("🚨 EMERGENCY MEMORY CLEANUP INITIATED")
    
    -- Immediately clean up all inactive resources
    self:CleanupStaleConnections(0) -- Clean all stale connections immediately
    self:CleanupStaleTweens(0)
    self:CleanupStaleTasks(0)
    
    -- Clear object pools completely
    for poolName, pool in pairs(objectPools) do
        pool.available = {}
        if config:Get("memory.TRACKING.ENABLE_DETAILED_LOGGING") then
            print("🧹 Emptied object pool: " .. poolName)
        end
    end
    
    -- Force multiple garbage collection cycles
    for i = 1, 5 do
        collectgarbage("collect")
        task.wait(0.1)
    end
    
    local cleanupTime = tick() - startTime
    memoryStats.performanceMetrics.avgCleanupTime = cleanupTime
    if cleanupTime > memoryStats.performanceMetrics.maxCleanupTime then
        memoryStats.performanceMetrics.maxCleanupTime = cleanupTime
    end
    
    print("✅ Emergency cleanup completed in " .. string.format("%.2f", cleanupTime) .. "s")
end

-- Aggressive cleanup for high memory pressure
function OptimizedMemoryManager:AggressiveCleanup()
    local startTime = tick()
    
    local staleConnectionThreshold = config:Get("memory.CLEANUP_THRESHOLDS.AGGRESSIVE_CONNECTION_AGE_SECONDS")
    local staleTweenThreshold = config:Get("memory.CLEANUP_THRESHOLDS.AGGRESSIVE_TWEEN_AGE_SECONDS")
    local staleTaskThreshold = config:Get("memory.CLEANUP_THRESHOLDS.AGGRESSIVE_TASK_AGE_SECONDS")
    
    self:CleanupStaleConnections(staleConnectionThreshold)
    self:CleanupStaleTweens(staleTweenThreshold)
    self:CleanupStaleTasks(staleTaskThreshold)
    
    -- Force garbage collection
    collectgarbage("collect")
    
    local cleanupTime = tick() - startTime
    print("🧹 Aggressive cleanup completed in " .. string.format("%.2f", cleanupTime) .. "s")
end

-- Moderate cleanup for medium memory pressure
function OptimizedMemoryManager:ModerateCleanup()
    local staleConnectionThreshold = config:Get("memory.CLEANUP_THRESHOLDS.MODERATE_CONNECTION_AGE_SECONDS")
    local staleTweenThreshold = config:Get("memory.CLEANUP_THRESHOLDS.MODERATE_TWEEN_AGE_SECONDS")
    local staleTaskThreshold = config:Get("memory.CLEANUP_THRESHOLDS.MODERATE_TASK_AGE_SECONDS")
    
    self:CleanupStaleConnections(staleConnectionThreshold)
    self:CleanupStaleTweens(staleTweenThreshold)
    self:CleanupStaleTasks(staleTaskThreshold)
end

-- Light cleanup for low memory pressure
function OptimizedMemoryManager:LightCleanup()
    local staleConnectionThreshold = config:Get("memory.CLEANUP_THRESHOLDS.LIGHT_CONNECTION_AGE_SECONDS")
    local staleTweenThreshold = config:Get("memory.CLEANUP_THRESHOLDS.LIGHT_TWEEN_AGE_SECONDS")
    local staleTaskThreshold = config:Get("memory.CLEANUP_THRESHOLDS.LIGHT_TASK_AGE_SECONDS")
    
    self:CleanupStaleConnections(staleConnectionThreshold)
    self:CleanupStaleTweens(staleTweenThreshold)
    self:CleanupStaleTasks(staleTaskThreshold)
end

-- ========================================
-- STALE RESOURCE CLEANUP
-- ========================================

-- Clean up stale connections based on age threshold
function OptimizedMemoryManager:CleanupStaleConnections(ageThreshold)
    local currentTime = tick()
    local cleanedCount = 0
    
    for playerId, connections in pairs(activeConnections) do
        local toRemove = {}
        
        for connectionId, connectionData in pairs(connections) do
            local age = currentTime - connectionData.timestamp
            if age > ageThreshold then
                table.insert(toRemove, connectionId)
            end
        end
        
        for _, connectionId in ipairs(toRemove) do
            if self:DisconnectConnection(playerId, connectionId) then
                cleanedCount = cleanedCount + 1
            end
        end
    end
    
    if cleanedCount > 0 and config:Get("memory.TRACKING.ENABLE_DETAILED_LOGGING") then
        print("🧹 Cleaned up " .. cleanedCount .. " stale connections (age > " .. ageThreshold .. "s)")
    end
    
    return cleanedCount
end

-- Clean up stale tweens
function OptimizedMemoryManager:CleanupStaleTweens(ageThreshold)
    local currentTime = tick()
    local cleanedCount = 0
    
    for playerId, tweens in pairs(activeTweens) do
        local toRemove = {}
        
        for tweenId, tweenData in pairs(tweens) do
            local age = currentTime - tweenData.timestamp
            if age > ageThreshold then
                table.insert(toRemove, tweenId)
            end
        end
        
        for _, tweenId in ipairs(toRemove) do
            if self:CleanupTween(playerId, tweenId) then
                cleanedCount = cleanedCount + 1
            end
        end
    end
    
    if cleanedCount > 0 and config:Get("memory.TRACKING.ENABLE_DETAILED_LOGGING") then
        print("🧹 Cleaned up " .. cleanedCount .. " stale tweens (age > " .. ageThreshold .. "s)")
    end
    
    return cleanedCount
end

-- Clean up stale tasks
function OptimizedMemoryManager:CleanupStaleTasks(ageThreshold)
    local currentTime = tick()
    local cleanedCount = 0
    
    for playerId, tasks in pairs(activeTasks) do
        local toRemove = {}
        
        for taskId, taskData in pairs(tasks) do
            local age = currentTime - taskData.timestamp
            if age > ageThreshold then
                table.insert(toRemove, taskId)
            end
        end
        
        for _, taskId in ipairs(toRemove) do
            if self:CancelTask(playerId, taskId) then
                cleanedCount = cleanedCount + 1
            end
        end
    end
    
    if cleanedCount > 0 and config:Get("memory.TRACKING.ENABLE_DETAILED_LOGGING") then
        print("🧹 Cleaned up " .. cleanedCount .. " stale tasks (age > " .. ageThreshold .. "s)")
    end
    
    return cleanedCount
end

-- ========================================
-- OBJECT POOL OPTIMIZATION
-- ========================================

-- Trim object pools to reduce memory usage
function OptimizedMemoryManager:TrimObjectPools(trimRatio)
    trimRatio = trimRatio or 0.5 -- Default 50%
    
    for poolName, pool in pairs(objectPools) do
        local availableCount = #pool.available
        local trimCount = math.floor(availableCount * trimRatio)
        
        if trimCount > 0 then
            -- Remove excess objects from available pool
            for i = 1, trimCount do
                table.remove(pool.available)
            end
            
            if config:Get("memory.TRACKING.ENABLE_DETAILED_LOGGING") then
                print("✂️ Trimmed " .. trimCount .. " objects from pool '" .. poolName .. "' (" .. 
                      (availableCount - trimCount) .. "/" .. availableCount .. " remaining)")
            end
        end
    end
end

-- ========================================
-- EVENT-DRIVEN CLEANUP UTILITIES
-- ========================================

-- Replace tight polling with event-driven pattern
function OptimizedMemoryManager:CreateEventDrivenMonitor(eventName, monitorFunction, interval)
    interval = interval or config:Get("memory.MONITORING.DEFAULT_EVENT_INTERVAL")
    
    local lastUpdate = 0
    local connection
    
    -- Use RunService.Heartbeat for frame-based monitoring
    connection = RunService.Heartbeat:Connect(function()
        local currentTime = tick()
        if currentTime - lastUpdate >= interval then
            lastUpdate = currentTime
            
            local success, result = pcall(monitorFunction)
            if not success then
                warn("❌ Event-driven monitor '" .. eventName .. "' failed: " .. tostring(result))
            end
        end
    end)
    
    -- Register connection for cleanup
    self:RegisterConnection("SYSTEM", eventName .. "_monitor", connection, false)
    
    return connection
end

-- Batch cleanup utility for improved performance
function OptimizedMemoryManager:CreateBatchCleanup(batchSize, processingFunction)
    batchSize = batchSize or config:Get("memory.BATCH_PROCESSING.DEFAULT_BATCH_SIZE")
    local batch = {}
    
    return function(item)
        table.insert(batch, item)
        
        if #batch >= batchSize then
            -- Process batch
            local success, result = pcall(processingFunction, batch)
            if not success then
                warn("❌ Batch cleanup failed: " .. tostring(result))
            end
            
            -- Clear batch
            batch = {}
        end
    end, function()
        -- Process remaining items in batch
        if #batch > 0 then
            local success, result = pcall(processingFunction, batch)
            if not success then
                warn("❌ Final batch cleanup failed: " .. tostring(result))
            end
        end
    end
end

-- ========================================
-- TWEEN MANAGEMENT (inherited from original)
-- ========================================

function OptimizedMemoryManager:RegisterTween(playerId, tweenName, tween)
    playerId = tostring(playerId)
    
    if not activeTweens[playerId] then
        activeTweens[playerId] = {}
    end
    
    local tweenId = HttpService:GenerateGUID(false)
    activeTweens[playerId][tweenId] = {
        tween = tween,
        name = tweenName,
        timestamp = tick(),
        type = "Tween"
    }
    
    -- Auto-cleanup on completion
    tween.Completed:Connect(function()
        self:CleanupTween(playerId, tweenId)
    end)
    
    return tweenId
end

function OptimizedMemoryManager:CleanupTween(playerId, tweenId)
    playerId = tostring(playerId)
    
    if activeTweens[playerId] and activeTweens[playerId][tweenId] then
        local tweenData = activeTweens[playerId][tweenId]
        
        if tweenData.tween then
            tweenData.tween:Cancel()
        end
        
        activeTweens[playerId][tweenId] = nil
        return true
    end
    
    return false
end

-- ========================================
-- TASK MANAGEMENT (inherited from original)
-- ========================================

function OptimizedMemoryManager:RegisterTask(playerId, taskName, taskThread)
    playerId = tostring(playerId)
    
    if not activeTasks[playerId] then
        activeTasks[playerId] = {}
    end
    
    local taskId = HttpService:GenerateGUID(false)
    activeTasks[playerId][taskId] = {
        task = taskThread,
        name = taskName,
        timestamp = tick(),
        type = "Task"
    }
    
    return taskId
end

function OptimizedMemoryManager:CancelTask(playerId, taskId)
    playerId = tostring(playerId)
    
    if activeTasks[playerId] and activeTasks[playerId][taskId] then
        local taskData = activeTasks[playerId][taskId]
        
        if taskData.task then
            task.cancel(taskData.task)
        end
        
        activeTasks[playerId][taskId] = nil
        return true
    end
    
    return false
end

-- ========================================
-- COMPREHENSIVE CLEANUP (enhanced)
-- ========================================

function OptimizedMemoryManager:CleanupPlayer(playerId)
    playerId = tostring(playerId)
    
    local stats = {
        connections = 0,
        tweens = 0,
        tasks = 0,
        gameObjects = 0,
        callbacks = 0
    }
    
    -- Clean up all player resources
    if activeConnections[playerId] then
        for connectionId in pairs(activeConnections[playerId]) do
            if self:DisconnectConnection(playerId, connectionId) then
                stats.connections = stats.connections + 1
            end
        end
    end
    
    if activeTweens[playerId] then
        for tweenId in pairs(activeTweens[playerId]) do
            if self:CleanupTween(playerId, tweenId) then
                stats.tweens = stats.tweens + 1
            end
        end
    end
    
    if activeTasks[playerId] then
        for taskId in pairs(activeTasks[playerId]) do
            if self:CancelTask(playerId, taskId) then
                stats.tasks = stats.tasks + 1
            end
        end
    end
    
    -- Fire cleanup event
    cleanupEvents.onPlayerLeaving:Fire(playerId, stats)
    
    return stats
end

-- ========================================
-- ENHANCED MONITORING AND REPORTING
-- ========================================

function OptimizedMemoryManager:GetAdvancedMemoryStats()
    local stats = {
        memory = {
            current = collectgarbage("count"),
            pressure = memoryStats.memoryPressure,
            adaptiveCleanupActive = memoryStats.adaptiveCleanupActive
        },
        performance = memoryStats.performanceMetrics,
        resources = {
            connections = 0,
            tweens = 0,
            tasks = 0,
            gameObjects = 0
        },
        objectPools = {}
    }
    
    -- Count active resources
    for playerId, connections in pairs(activeConnections) do
        for _ in pairs(connections) do
            stats.resources.connections = stats.resources.connections + 1
        end
    end
    
    for playerId, tweens in pairs(activeTweens) do
        for _ in pairs(tweens) do
            stats.resources.tweens = stats.resources.tweens + 1
        end
    end
    
    for playerId, tasks in pairs(activeTasks) do
        for _ in pairs(tasks) do
            stats.resources.tasks = stats.resources.tasks + 1
        end
    end
    
    -- Get object pool stats
    for poolName in pairs(objectPools) do
        stats.objectPools[poolName] = self:GetPoolStats(poolName)
    end
    
    return stats
end

-- ========================================
-- INITIALIZATION
-- ========================================

function OptimizedMemoryManager:Init()
    print("🧠 OptimizedMemoryManager initializing with advanced features...")
    
    -- Start memory pressure monitoring
    self:MonitorMemoryPressure()
    
    -- Create default object pools
    self:CreateObjectPool("uiElements", 
        function() return Instance.new("Frame") end,
        function(frame) 
            frame.Parent = nil
            frame.Size = UDim2.new(0, 100, 0, 100)
            frame.Position = UDim2.new(0, 0, 0, 0)
        end
    )
    
    self:CreateObjectPool("particles",
        function() return Instance.new("ParticleEmitter") end,
        function(emitter)
            emitter.Parent = nil
            emitter.Enabled = false
        end
    )
    
    -- Setup player cleanup events
    Players.PlayerRemoving:Connect(function(player)
        self:CleanupPlayer(tostring(player.UserId))
    end)
    
    print("✅ OptimizedMemoryManager initialized successfully")
    return true
end

return OptimizedMemoryManager
