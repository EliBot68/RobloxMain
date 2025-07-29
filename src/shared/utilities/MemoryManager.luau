-- MemoryManager.luau
-- Centralized memory management and cleanup utility for all game systems
-- Handles connections, tweens, tasks, and prevents memory leaks

local MemoryManager = {}

-- Memory tracking registries
local activeConnections = {}
local activeTweens = {}
local activeTasks = {}
local activeGameObjects = {}
local playerCleanupCallbacks = {}

-- Configuration
local MEMORY_CONFIG = {
    enableDetailedLogging = true,
    enablePerformanceMonitoring = true,
    autoCleanupInterval = 60, -- seconds
    maxConnectionsPerPlayer = 100,
    maxTweensPerPlayer = 50,
    maxTasksPerPlayer = 20
}

-- ========================================
-- CONNECTION MANAGEMENT
-- ========================================

-- Register a connection for automatic cleanup
function MemoryManager:RegisterConnection(playerId, connectionName, connection)
    playerId = tostring(playerId) -- ASSUMPTION: Player ID used as string key for consistency
    
    if not activeConnections[playerId] then
        activeConnections[playerId] = {}
    end
    
    -- Check connection limit per player to prevent memory issues
    if #activeConnections[playerId] >= MEMORY_CONFIG.maxConnectionsPerPlayer then
        warn("⚠️ Player " .. playerId .. " has reached max connections limit")
        return false
    end
    
    activeConnections[playerId][connectionName] = {
        connection = connection,
        timestamp = tick(),
        type = "RBXScriptConnection"
    }
    
    if MEMORY_CONFIG.enableDetailedLogging then
        print("🔗 Registered connection: " .. connectionName .. " for player " .. playerId)
    end
    
    return true
end

-- Disconnect a specific connection
function MemoryManager:DisconnectConnection(playerId, connectionName)
    playerId = tostring(playerId)
    
    if activeConnections[playerId] and activeConnections[playerId][connectionName] then
        local connectionData = activeConnections[playerId][connectionName]
        
        if connectionData.connection and typeof(connectionData.connection) == "RBXScriptConnection" then
            connectionData.connection:Disconnect()
        end
        
        activeConnections[playerId][connectionName] = nil
        
        if MEMORY_CONFIG.enableDetailedLogging then
            print("🔌 Disconnected connection: " .. connectionName .. " for player " .. playerId)
        end
        
        return true
    end
    
    return false
end

-- Disconnect all connections for a player
function MemoryManager:DisconnectAllPlayerConnections(playerId)
    playerId = tostring(playerId)
    
    if not activeConnections[playerId] then
        return 0
    end
    
    local disconnectedCount = 0
    
    for connectionName, connectionData in pairs(activeConnections[playerId]) do
        if connectionData.connection and typeof(connectionData.connection) == "RBXScriptConnection" then
            connectionData.connection:Disconnect()
            disconnectedCount = disconnectedCount + 1
        end
    end
    
    activeConnections[playerId] = nil
    
    if MEMORY_CONFIG.enableDetailedLogging then
        print("🧹 Disconnected " .. disconnectedCount .. " connections for player " .. playerId)
    end
    
    return disconnectedCount
end

-- ========================================
-- TWEEN MANAGEMENT
-- ========================================

-- Register a tween for automatic cleanup
function MemoryManager:RegisterTween(playerId, tweenName, tween)
    playerId = tostring(playerId)
    
    if not activeTweens[playerId] then
        activeTweens[playerId] = {}
    end
    
    -- Check tween limit per player
    if #activeTweens[playerId] >= MEMORY_CONFIG.maxTweensPerPlayer then
        warn("⚠️ Player " .. playerId .. " has reached max tweens limit")
        return false
    end
    
    activeTweens[playerId][tweenName] = {
        tween = tween,
        timestamp = tick(),
        type = "Tween"
    }
    
    -- ASSUMPTION: Register completion callback to auto-cleanup when tween finishes
    tween.Completed:Connect(function()
        self:CleanupTween(playerId, tweenName)
    end)
    
    if MEMORY_CONFIG.enableDetailedLogging then
        print("✨ Registered tween: " .. tweenName .. " for player " .. playerId)
    end
    
    return true
end

-- Cancel and cleanup a specific tween
function MemoryManager:CleanupTween(playerId, tweenName)
    playerId = tostring(playerId)
    
    if activeTweens[playerId] and activeTweens[playerId][tweenName] then
        local tweenData = activeTweens[playerId][tweenName]
        
        if tweenData.tween then
            tweenData.tween:Cancel() -- ASSUMPTION: Cancel tween to free resources
        end
        
        activeTweens[playerId][tweenName] = nil
        
        if MEMORY_CONFIG.enableDetailedLogging then
            print("🎬 Cleaned up tween: " .. tweenName .. " for player " .. playerId)
        end
        
        return true
    end
    
    return false
end

-- Cancel all tweens for a player
function MemoryManager:CleanupAllPlayerTweens(playerId)
    playerId = tostring(playerId)
    
    if not activeTweens[playerId] then
        return 0
    end
    
    local cleanedCount = 0
    
    for tweenName, tweenData in pairs(activeTweens[playerId]) do
        if tweenData.tween then
            tweenData.tween:Cancel()
            cleanedCount = cleanedCount + 1
        end
    end
    
    activeTweens[playerId] = nil
    
    if MEMORY_CONFIG.enableDetailedLogging then
        print("🧹 Cleaned up " .. cleanedCount .. " tweens for player " .. playerId)
    end
    
    return cleanedCount
end

-- ========================================
-- TASK MANAGEMENT  
-- ========================================

-- Register a task for automatic cleanup
function MemoryManager:RegisterTask(playerId, taskName, taskThread)
    playerId = tostring(playerId)
    
    if not activeTasks[playerId] then
        activeTasks[playerId] = {}
    end
    
    -- Check task limit per player
    if #activeTasks[playerId] >= MEMORY_CONFIG.maxTasksPerPlayer then
        warn("⚠️ Player " .. playerId .. " has reached max tasks limit")
        return false
    end
    
    activeTasks[playerId][taskName] = {
        task = taskThread,
        timestamp = tick(),
        type = "Task"
    }
    
    if MEMORY_CONFIG.enableDetailedLogging then
        print("⚙️ Registered task: " .. taskName .. " for player " .. playerId)
    end
    
    return true
end

-- Cancel a specific task
function MemoryManager:CancelTask(playerId, taskName)
    playerId = tostring(playerId)
    
    if activeTasks[playerId] and activeTasks[playerId][taskName] then
        local taskData = activeTasks[playerId][taskName]
        
        if taskData.task then
            task.cancel(taskData.task) -- ASSUMPTION: Use task.cancel for modern API
        end
        
        activeTasks[playerId][taskName] = nil
        
        if MEMORY_CONFIG.enableDetailedLogging then
            print("⚙️ Cancelled task: " .. taskName .. " for player " .. playerId)
        end
        
        return true
    end
    
    return false
end

-- Cancel all tasks for a player
function MemoryManager:CancelAllPlayerTasks(playerId)
    playerId = tostring(playerId)
    
    if not activeTasks[playerId] then
        return 0
    end
    
    local cancelledCount = 0
    
    for taskName, taskData in pairs(activeTasks[playerId]) do
        if taskData.task then
            task.cancel(taskData.task)
            cancelledCount = cancelledCount + 1
        end
    end
    
    activeTasks[playerId] = nil
    
    if MEMORY_CONFIG.enableDetailedLogging then
        print("🧹 Cancelled " .. cancelledCount .. " tasks for player " .. playerId)
    end
    
    return cancelledCount
end

-- ========================================
-- GAME OBJECT MANAGEMENT
-- ========================================

-- Register a game object for cleanup (parts, guis, etc.)
function MemoryManager:RegisterGameObject(playerId, objectName, gameObject)
    playerId = tostring(playerId)
    
    if not activeGameObjects[playerId] then
        activeGameObjects[playerId] = {}
    end
    
    activeGameObjects[playerId][objectName] = {
        object = gameObject,
        timestamp = tick(),
        type = typeof(gameObject)
    }
    
    if MEMORY_CONFIG.enableDetailedLogging then
        print("🎮 Registered game object: " .. objectName .. " (" .. typeof(gameObject) .. ") for player " .. playerId)
    end
    
    return true
end

-- Destroy a specific game object
function MemoryManager:DestroyGameObject(playerId, objectName)
    playerId = tostring(playerId)
    
    if activeGameObjects[playerId] and activeGameObjects[playerId][objectName] then
        local objectData = activeGameObjects[playerId][objectName]
        
        if objectData.object and objectData.object.Parent then
            objectData.object:Destroy() -- ASSUMPTION: All registered objects have Destroy method
        end
        
        activeGameObjects[playerId][objectName] = nil
        
        if MEMORY_CONFIG.enableDetailedLogging then
            print("🗑️ Destroyed game object: " .. objectName .. " for player " .. playerId)
        end
        
        return true
    end
    
    return false
end

-- Destroy all game objects for a player
function MemoryManager:DestroyAllPlayerGameObjects(playerId)
    playerId = tostring(playerId)
    
    if not activeGameObjects[playerId] then
        return 0
    end
    
    local destroyedCount = 0
    
    for objectName, objectData in pairs(activeGameObjects[playerId]) do
        if objectData.object and objectData.object.Parent then
            objectData.object:Destroy()
            destroyedCount = destroyedCount + 1
        end
    end
    
    activeGameObjects[playerId] = nil
    
    if MEMORY_CONFIG.enableDetailedLogging then
        print("🧹 Destroyed " .. destroyedCount .. " game objects for player " .. playerId)
    end
    
    return destroyedCount
end

-- ========================================
-- CUSTOM CLEANUP CALLBACKS
-- ========================================

-- Register a custom cleanup function for a player
function MemoryManager:RegisterCleanupCallback(playerId, callbackName, cleanupFunction)
    playerId = tostring(playerId)
    
    if not playerCleanupCallbacks[playerId] then
        playerCleanupCallbacks[playerId] = {}
    end
    
    playerCleanupCallbacks[playerId][callbackName] = cleanupFunction
    
    if MEMORY_CONFIG.enableDetailedLogging then
        print("📋 Registered cleanup callback: " .. callbackName .. " for player " .. playerId)
    end
    
    return true
end

-- Execute custom cleanup callbacks for a player
function MemoryManager:ExecutePlayerCleanupCallbacks(playerId)
    playerId = tostring(playerId)
    
    if not playerCleanupCallbacks[playerId] then
        return 0
    end
    
    local executedCount = 0
    
    for callbackName, cleanupFunction in pairs(playerCleanupCallbacks[playerId]) do
        local success, error = pcall(cleanupFunction)
        
        if success then
            executedCount = executedCount + 1
            if MEMORY_CONFIG.enableDetailedLogging then
                print("✅ Executed cleanup callback: " .. callbackName .. " for player " .. playerId)
            end
        else
            warn("❌ Failed to execute cleanup callback " .. callbackName .. " for player " .. playerId .. ": " .. tostring(error))
        end
    end
    
    playerCleanupCallbacks[playerId] = nil
    return executedCount
end

-- ========================================
-- COMPREHENSIVE PLAYER CLEANUP
-- ========================================

-- Complete cleanup for a player (all resources)
function MemoryManager:CleanupPlayer(playerId)
    playerId = tostring(playerId)
    
    local stats = {
        connections = 0,
        tweens = 0,
        tasks = 0,
        gameObjects = 0,
        callbacks = 0
    }
    
    print("🧹 Starting comprehensive cleanup for player " .. playerId)
    
    -- Clean up connections
    stats.connections = self:DisconnectAllPlayerConnections(playerId)
    
    -- Clean up tweens
    stats.tweens = self:CleanupAllPlayerTweens(playerId)
    
    -- Clean up tasks
    stats.tasks = self:CancelAllPlayerTasks(playerId)
    
    -- Clean up game objects
    stats.gameObjects = self:DestroyAllPlayerGameObjects(playerId)
    
    -- Execute custom cleanup callbacks
    stats.callbacks = self:ExecutePlayerCleanupCallbacks(playerId)
    
    print("✅ Cleanup complete for player " .. playerId .. ":")
    print("   Connections: " .. stats.connections)
    print("   Tweens: " .. stats.tweens)
    print("   Tasks: " .. stats.tasks)
    print("   Game Objects: " .. stats.gameObjects)
    print("   Callbacks: " .. stats.callbacks)
    
    return stats
end

-- ========================================
-- SYSTEM-WIDE CLEANUP
-- ========================================

-- Clean up all players (full system cleanup)
function MemoryManager:CleanupAllPlayers()
    local totalStats = {
        players = 0,
        connections = 0,
        tweens = 0,
        tasks = 0,
        gameObjects = 0,
        callbacks = 0
    }
    
    print("🧹 Starting system-wide memory cleanup...")
    
    -- Cleanup all player connections
    for playerId, _ in pairs(activeConnections) do
        local stats = self:CleanupPlayer(playerId)
        totalStats.players = totalStats.players + 1
        totalStats.connections = totalStats.connections + stats.connections
        totalStats.tweens = totalStats.tweens + stats.tweens
        totalStats.tasks = totalStats.tasks + stats.tasks
        totalStats.gameObjects = totalStats.gameObjects + stats.gameObjects
        totalStats.callbacks = totalStats.callbacks + stats.callbacks
    end
    
    -- Force garbage collection
    for i = 1, 3 do
        collectgarbage("collect")
        task.wait(0.1) -- UPDATED for modern API
    end
    
    print("✅ System-wide cleanup complete:")
    print("   Players cleaned: " .. totalStats.players)
    print("   Total connections: " .. totalStats.connections)
    print("   Total tweens: " .. totalStats.tweens)
    print("   Total tasks: " .. totalStats.tasks)
    print("   Total game objects: " .. totalStats.gameObjects)
    print("   Total callbacks: " .. totalStats.callbacks)
    
    return totalStats
end

-- ========================================
-- PERFORMANCE MONITORING
-- ========================================

-- Get memory usage statistics
function MemoryManager:GetMemoryStats()
    local stats = {
        totalPlayers = 0,
        totalConnections = 0,
        totalTweens = 0,
        totalTasks = 0,
        totalGameObjects = 0,
        totalCallbacks = 0,
        playerDetails = {}
    }
    
    -- Count connections
    for playerId, connections in pairs(activeConnections) do
        local connectionCount = 0
        for _ in pairs(connections) do
            connectionCount = connectionCount + 1
        end
        stats.totalConnections = stats.totalConnections + connectionCount
        stats.playerDetails[playerId] = stats.playerDetails[playerId] or {}
        stats.playerDetails[playerId].connections = connectionCount
    end
    
    -- Count tweens
    for playerId, tweens in pairs(activeTweens) do
        local tweenCount = 0
        for _ in pairs(tweens) do
            tweenCount = tweenCount + 1
        end
        stats.totalTweens = stats.totalTweens + tweenCount
        stats.playerDetails[playerId] = stats.playerDetails[playerId] or {}
        stats.playerDetails[playerId].tweens = tweenCount
    end
    
    -- Count tasks
    for playerId, tasks in pairs(activeTasks) do
        local taskCount = 0
        for _ in pairs(tasks) do
            taskCount = taskCount + 1
        end
        stats.totalTasks = stats.totalTasks + taskCount
        stats.playerDetails[playerId] = stats.playerDetails[playerId] or {}
        stats.playerDetails[playerId].tasks = taskCount
    end
    
    -- Count game objects
    for playerId, objects in pairs(activeGameObjects) do
        local objectCount = 0
        for _ in pairs(objects) do
            objectCount = objectCount + 1
        end
        stats.totalGameObjects = stats.totalGameObjects + objectCount
        stats.playerDetails[playerId] = stats.playerDetails[playerId] or {}
        stats.playerDetails[playerId].gameObjects = objectCount
    end
    
    -- Count callbacks
    for playerId, callbacks in pairs(playerCleanupCallbacks) do
        local callbackCount = 0
        for _ in pairs(callbacks) do
            callbackCount = callbackCount + 1
        end
        stats.totalCallbacks = stats.totalCallbacks + callbackCount
        stats.playerDetails[playerId] = stats.playerDetails[playerId] or {}
        stats.playerDetails[playerId].callbacks = callbackCount
    end
    
    stats.totalPlayers = 0
    for _ in pairs(stats.playerDetails) do
        stats.totalPlayers = stats.totalPlayers + 1
    end
    
    return stats
end

-- Print memory usage report
function MemoryManager:PrintMemoryReport()
    local stats = self:GetMemoryStats()
    
    print("📊 Memory Manager Status Report:")
    print("   Active Players: " .. stats.totalPlayers)
    print("   Total Connections: " .. stats.totalConnections)
    print("   Total Tweens: " .. stats.totalTweens)
    print("   Total Tasks: " .. stats.totalTasks)
    print("   Total Game Objects: " .. stats.totalGameObjects)
    print("   Total Callbacks: " .. stats.totalCallbacks)
    
    if MEMORY_CONFIG.enableDetailedLogging then
        print("\n   Per-Player Details:")
        for playerId, details in pairs(stats.playerDetails) do
            print("     Player " .. playerId .. ":")
            print("       Connections: " .. (details.connections or 0))
            print("       Tweens: " .. (details.tweens or 0))
            print("       Tasks: " .. (details.tasks or 0))
            print("       Game Objects: " .. (details.gameObjects or 0))
            print("       Callbacks: " .. (details.callbacks or 0))
        end
    end
end

-- ========================================
-- INITIALIZATION AND MONITORING
-- ========================================

-- Start automatic cleanup monitoring
function MemoryManager:StartPeriodicCleanup()
    task.spawn(function() -- UPDATED for modern API
        while true do
            task.wait(MEMORY_CONFIG.autoCleanupInterval) -- UPDATED for modern API
            
            if MEMORY_CONFIG.enablePerformanceMonitoring then
                self:PrintMemoryReport()
            end
            
            -- Force garbage collection periodically
            collectgarbage("collect")
        end
    end)
    
    print("⏰ Started periodic memory cleanup (every " .. MEMORY_CONFIG.autoCleanupInterval .. " seconds)")
end

-- Initialize memory manager
function MemoryManager:Init()
    print("🧠 MemoryManager initialized")
    
    if MEMORY_CONFIG.enablePerformanceMonitoring then
        self:StartPeriodicCleanup()
    end
    
    return true
end

return MemoryManager
