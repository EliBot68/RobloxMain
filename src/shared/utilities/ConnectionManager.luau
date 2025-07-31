-- ConnectionManager.luau
-- Centralized connection management system to eliminate memory leaks
-- Provides connection pools, automatic cleanup, and lifecycle management

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local ConfigurationManager = require(ReplicatedStorage.Shared.core.ConfigurationManager)

local ConnectionManager = {}

-- ========================================
-- CONFIGURATION AND STATE
-- ========================================

-- Get configuration instance
local config = ConfigurationManager.getInstance()

-- Connection tracking registries
local playerConnections = {} -- Player-specific connections
local serviceConnections = {} -- Service-wide connections
local connectionPools = {} -- Reusable connection pools
local connectionStats = {} -- Performance statistics

-- Connection types for pooling
local CONNECTION_TYPES = {
    PLAYER_ADDED = "PlayerAdded",
    PLAYER_REMOVING = "PlayerRemoving", 
    CHARACTER_ADDED = "CharacterAdded",
    CHARACTER_REMOVING = "CharacterRemoving",
    HEARTBEAT = "Heartbeat",
    TOUCHED = "Touched",
    REMOTE_EVENT = "RemoteEvent",
    REMOTE_FUNCTION = "RemoteFunction",
    MOUSE_CLICK = "MouseClick",
    PROPERTY_CHANGED = "PropertyChanged",
    TWEEN_COMPLETED = "TweenCompleted"
}

-- Connection lifecycle states
local CONNECTION_STATES = {
    ACTIVE = "Active",
    DISCONNECTED = "Disconnected",
    POOLED = "Pooled",
    ERROR = "Error"
}

-- ========================================
-- CONNECTION REGISTRY MANAGEMENT
-- ========================================

-- Register a connection for automatic lifecycle management
function ConnectionManager:RegisterConnection(owner, connectionName, connection, connectionType)
    connectionType = connectionType or "Generic"
    
    -- Validate inputs
    if not connection or typeof(connection) ~= "RBXScriptConnection" then
        warn(string.format("❌ Invalid connection provided: %s for %s", tostring(connection), tostring(owner)))
        return false
    end
    
    -- Determine storage location
    local registry
    if tostring(owner):find("Player") or Players:GetPlayerByUserId(tonumber(owner)) then
        -- Player-specific connection
        local playerId = tostring(owner)
        if not playerConnections[playerId] then
            playerConnections[playerId] = {}
        end
        registry = playerConnections[playerId]
    else
        -- Service-level connection
        local serviceName = tostring(owner)
        if not serviceConnections[serviceName] then
            serviceConnections[serviceName] = {}
        end
        registry = serviceConnections[serviceName]
    end
    
    -- Check connection limits
    local maxConnections = config:Get("memory.LIMITS.MAX_CONNECTIONS_PER_PLAYER")
    if #registry >= maxConnections then
        warn(string.format("⚠️ Connection limit exceeded for %s (%d/%d)", tostring(owner), #registry, maxConnections))
        return false
    end
    
    -- Store connection data
    local connectionData = {
        name = connectionName,
        connection = connection,
        type = connectionType,
        owner = owner,
        timestamp = tick(),
        state = CONNECTION_STATES.ACTIVE,
        metadata = {}
    }
    
    registry[connectionName] = connectionData
    
    -- Update statistics
    self:UpdateConnectionStats(connectionType, "registered")
    
    if config:Get("memory.TRACKING.ENABLE_DETAILED_LOGGING") then
        print(string.format("🔗 Registered %s connection: %s for %s", connectionType, connectionName, tostring(owner)))
    end
    
    return true
end

-- Unregister and disconnect a specific connection
function ConnectionManager:UnregisterConnection(owner, connectionName)
    local registry = self:GetConnectionRegistry(owner)
    if not registry or not registry[connectionName] then
        return false
    end
    
    local connectionData = registry[connectionName]
    
    -- Disconnect the connection
    if connectionData.connection and connectionData.state == CONNECTION_STATES.ACTIVE then
        connectionData.connection:Disconnect()
        connectionData.state = CONNECTION_STATES.DISCONNECTED
        
        -- Update statistics
        self:UpdateConnectionStats(connectionData.type, "disconnected")
    end
    
    -- Remove from registry
    registry[connectionName] = nil
    
    if config:Get("memory.TRACKING.ENABLE_DETAILED_LOGGING") then
        print(string.format("🔌 Unregistered connection: %s for %s", connectionName, tostring(owner)))
    end
    
    return true
end

-- Get the appropriate connection registry for an owner
function ConnectionManager:GetConnectionRegistry(owner)
    if tostring(owner):find("Player") or Players:GetPlayerByUserId(tonumber(owner)) then
        return playerConnections[tostring(owner)]
    else
        return serviceConnections[tostring(owner)]
    end
end

-- ========================================
-- CONNECTION POOLS
-- ========================================

-- Initialize connection pools for frequently used patterns
function ConnectionManager:InitializeConnectionPools()
    print("🏊 Initializing connection pools...")
    
    for connectionType, typeName in pairs(CONNECTION_TYPES) do
        connectionPools[typeName] = {
            available = {},
            active = {},
            totalCreated = 0,
            totalReused = 0,
            maxSize = config:Get("memory.OBJECT_POOLS.MAX_POOL_SIZE") or 25
        }
    end
    
    print("✅ Connection pools initialized for " .. #CONNECTION_TYPES .. " types")
end

-- Get a pooled connection or create a new one
function ConnectionManager:GetPooledConnection(connectionType, signal, callback)
    if not connectionPools[connectionType] then
        self:InitializeConnectionPools()
    end
    
    local pool = connectionPools[connectionType]
    local connection
    
    -- Try to reuse from pool
    if #pool.available > 0 then
        connection = table.remove(pool.available, 1)
        pool.totalReused = pool.totalReused + 1
        
        if config:Get("memory.TRACKING.ENABLE_DETAILED_LOGGING") then
            print(string.format("♻️ Reused pooled %s connection", connectionType))
        end
    else
        -- Create new connection
        connection = signal:Connect(callback)
        pool.totalCreated = pool.totalCreated + 1
        
        if config:Get("memory.TRACKING.ENABLE_DETAILED_LOGGING") then
            print(string.format("🆕 Created new %s connection", connectionType))
        end
    end
    
    -- Add to active connections
    table.insert(pool.active, connection)
    
    return connection
end

-- Return a connection to the pool
function ConnectionManager:ReturnConnectionToPool(connectionType, connection)
    if not connectionPools[connectionType] then
        return false
    end
    
    local pool = connectionPools[connectionType]
    
    -- Remove from active
    for i, activeConnection in ipairs(pool.active) do
        if activeConnection == connection then
            table.remove(pool.active, i)
            break
        end
    end
    
    -- Add to available pool if under max size
    if #pool.available < pool.maxSize then
        connection:Disconnect()
        table.insert(pool.available, connection)
        return true
    else
        -- Pool is full, just disconnect
        connection:Disconnect()
        return false
    end
end

-- ========================================
-- UTILITY FUNCTIONS FOR COMMON PATTERNS
-- ========================================

-- Helper for player event connections
function ConnectionManager:ConnectPlayerEvent(eventName, callback, owner)
    owner = owner or "PlayerEventHandler"
    
    local connection = Players[eventName]:Connect(callback)
    local connectionName = eventName .. "_" .. tick()
    
    self:RegisterConnection(owner, connectionName, connection, eventName)
    return connection, connectionName
end

-- Helper for character event connections
function ConnectionManager:ConnectCharacterEvent(player, eventName, callback, owner)
    owner = owner or tostring(player.UserId)
    
    local connection = player[eventName]:Connect(callback)
    local connectionName = eventName .. "_" .. player.Name .. "_" .. tick()
    
    self:RegisterConnection(owner, connectionName, connection, eventName)
    return connection, connectionName
end

-- Helper for RemoteEvent connections
function ConnectionManager:ConnectRemoteEvent(remoteEvent, callback, owner)
    owner = owner or "RemoteEventHandler"
    
    local connection = remoteEvent.OnServerEvent:Connect(callback)
    local connectionName = remoteEvent.Name .. "_ServerEvent_" .. tick()
    
    self:RegisterConnection(owner, connectionName, connection, CONNECTION_TYPES.REMOTE_EVENT)
    return connection, connectionName
end

-- Helper for touch event connections
function ConnectionManager:ConnectTouchEvent(part, callback, owner)
    owner = owner or "TouchEventHandler"
    
    local connection = part.Touched:Connect(callback)
    local connectionName = part.Name .. "_Touched_" .. tick()
    
    self:RegisterConnection(owner, connectionName, connection, CONNECTION_TYPES.TOUCHED)
    return connection, connectionName
end

-- Helper for tween completion connections
function ConnectionManager:ConnectTweenCompleted(tween, callback, owner)
    owner = owner or "TweenHandler"
    
    local connection = tween.Completed:Connect(callback)
    local connectionName = "TweenCompleted_" .. tick()
    
    self:RegisterConnection(owner, connectionName, connection, CONNECTION_TYPES.TWEEN_COMPLETED)
    return connection, connectionName
end

-- Helper for heartbeat connections with rate limiting
function ConnectionManager:ConnectHeartbeat(callback, interval, owner)
    interval = interval or 0 -- No rate limiting by default
    owner = owner or "HeartbeatHandler"
    
    local lastCall = 0
    local wrappedCallback = function()
        local now = tick()
        if now - lastCall >= interval then
            lastCall = now
            callback()
        end
    end
    
    local connection = RunService.Heartbeat:Connect(wrappedCallback)
    local connectionName = "Heartbeat_" .. tick()
    
    self:RegisterConnection(owner, connectionName, connection, CONNECTION_TYPES.HEARTBEAT)
    return connection, connectionName
end

-- ========================================
-- BULK CLEANUP OPERATIONS
-- ========================================

-- Disconnect all connections for a specific owner
function ConnectionManager:DisconnectAllForOwner(owner)
    local registry = self:GetConnectionRegistry(owner)
    if not registry then
        return 0
    end
    
    local disconnectedCount = 0
    
    for connectionName, connectionData in pairs(registry) do
        if connectionData.connection and connectionData.state == CONNECTION_STATES.ACTIVE then
            connectionData.connection:Disconnect()
            connectionData.state = CONNECTION_STATES.DISCONNECTED
            
            -- Update statistics
            self:UpdateConnectionStats(connectionData.type, "disconnected")
            disconnectedCount = disconnectedCount + 1
        end
    end
    
    -- Clear the registry
    if tostring(owner):find("Player") or Players:GetPlayerByUserId(tonumber(owner)) then
        playerConnections[tostring(owner)] = nil
    else
        serviceConnections[tostring(owner)] = nil
    end
    
    if config:Get("memory.TRACKING.ENABLE_DETAILED_LOGGING") then
        print(string.format("🧹 Disconnected %d connections for %s", disconnectedCount, tostring(owner)))
    end
    
    return disconnectedCount
end

-- Emergency cleanup - disconnect all connections
function ConnectionManager:EmergencyCleanup()
    print("🚨 Emergency connection cleanup initiated...")
    
    local totalDisconnected = 0
    
    -- Cleanup player connections
    for playerId, connections in pairs(playerConnections) do
        totalDisconnected = totalDisconnected + self:DisconnectAllForOwner(playerId)
    end
    
    -- Cleanup service connections
    for serviceName, connections in pairs(serviceConnections) do
        totalDisconnected = totalDisconnected + self:DisconnectAllForOwner(serviceName)
    end
    
    -- Clear connection pools
    for poolType, pool in pairs(connectionPools) do
        for _, connection in ipairs(pool.active) do
            if connection and typeof(connection) == "RBXScriptConnection" then
                connection:Disconnect()
                totalDisconnected = totalDisconnected + 1
            end
        end
        for _, connection in ipairs(pool.available) do
            if connection and typeof(connection) == "RBXScriptConnection" then
                connection:Disconnect()
                totalDisconnected = totalDisconnected + 1
            end
        end
        pool.active = {}
        pool.available = {}
    end
    
    print(string.format("✅ Emergency cleanup complete - %d connections disconnected", totalDisconnected))
    return totalDisconnected
end

-- Cleanup stale connections (older than threshold)
function ConnectionManager:CleanupStaleConnections()
    local currentTime = tick()
    local staleThreshold = config:Get("memory.CLEANUP_THRESHOLDS.LIGHT_CONNECTION_AGE_SECONDS") or 300 -- 5 minutes
    local cleanedCount = 0
    
    -- Check player connections
    for playerId, connections in pairs(playerConnections) do
        for connectionName, connectionData in pairs(connections) do
            if currentTime - connectionData.timestamp > staleThreshold then
                if connectionData.connection and connectionData.state == CONNECTION_STATES.ACTIVE then
                    connectionData.connection:Disconnect()
                    connectionData.state = CONNECTION_STATES.DISCONNECTED
                    cleanedCount = cleanedCount + 1
                end
                connections[connectionName] = nil
            end
        end
    end
    
    -- Check service connections
    for serviceName, connections in pairs(serviceConnections) do
        for connectionName, connectionData in pairs(connections) do
            if currentTime - connectionData.timestamp > staleThreshold then
                if connectionData.connection and connectionData.state == CONNECTION_STATES.ACTIVE then
                    connectionData.connection:Disconnect()
                    connectionData.state = CONNECTION_STATES.DISCONNECTED
                    cleanedCount = cleanedCount + 1
                end
                connections[connectionName] = nil
            end
        end
    end
    
    if cleanedCount > 0 and config:Get("memory.TRACKING.ENABLE_DETAILED_LOGGING") then
        print(string.format("🧽 Cleaned up %d stale connections", cleanedCount))
    end
    
    return cleanedCount
end

-- ========================================
-- STATISTICS AND MONITORING
-- ========================================

-- Update connection statistics
function ConnectionManager:UpdateConnectionStats(connectionType, action)
    if not connectionStats[connectionType] then
        connectionStats[connectionType] = {
            registered = 0,
            disconnected = 0,
            errors = 0
        }
    end
    
    connectionStats[connectionType][action] = (connectionStats[connectionType][action] or 0) + 1
end

-- Get comprehensive connection statistics
function ConnectionManager:GetConnectionStats()
    local stats = {
        totalPlayerConnections = 0,
        totalServiceConnections = 0,
        totalPooledConnections = 0,
        activePlayerCount = 0,
        activeServiceCount = 0,
        connectionTypes = {},
        poolStats = {}
    }
    
    -- Count player connections
    for playerId, connections in pairs(playerConnections) do
        local activeCount = 0
        for _, connectionData in pairs(connections) do
            if connectionData.state == CONNECTION_STATES.ACTIVE then
                activeCount = activeCount + 1
            end
        end
        stats.totalPlayerConnections = stats.totalPlayerConnections + activeCount
        if activeCount > 0 then
            stats.activePlayerCount = stats.activePlayerCount + 1
        end
    end
    
    -- Count service connections
    for serviceName, connections in pairs(serviceConnections) do
        local activeCount = 0
        for _, connectionData in pairs(connections) do
            if connectionData.state == CONNECTION_STATES.ACTIVE then
                activeCount = activeCount + 1
            end
        end
        stats.totalServiceConnections = stats.totalServiceConnections + activeCount
        if activeCount > 0 then
            stats.activeServiceCount = stats.activeServiceCount + 1
        end
    end
    
    -- Count pooled connections
    for poolType, pool in pairs(connectionPools) do
        stats.totalPooledConnections = stats.totalPooledConnections + #pool.active + #pool.available
        stats.poolStats[poolType] = {
            active = #pool.active,
            available = #pool.available,
            totalCreated = pool.totalCreated,
            totalReused = pool.totalReused,
            reuseRatio = pool.totalCreated > 0 and (pool.totalReused / pool.totalCreated) or 0
        }
    end
    
    -- Copy connection type stats
    stats.connectionTypes = connectionStats
    
    return stats
end

-- Print detailed connection report
function ConnectionManager:PrintConnectionReport()
    local stats = self:GetConnectionStats()
    
    print("📊 CONNECTION MANAGER REPORT")
    print("================================")
    print(string.format("Total Active Connections: %d", stats.totalPlayerConnections + stats.totalServiceConnections))
    print(string.format("  Player Connections: %d (across %d players)", stats.totalPlayerConnections, stats.activePlayerCount))
    print(string.format("  Service Connections: %d (across %d services)", stats.totalServiceConnections, stats.activeServiceCount))
    print(string.format("  Pooled Connections: %d", stats.totalPooledConnections))
    
    print("\n🏊 CONNECTION POOL PERFORMANCE:")
    for poolType, poolStats in pairs(stats.poolStats) do
        print(string.format("  %s: %d active, %d available, %.1f%% reuse rate", 
            poolType, poolStats.active, poolStats.available, poolStats.reuseRatio * 100))
    end
    
    print("\n📈 CONNECTION TYPE STATISTICS:")
    for connectionType, typeStats in pairs(stats.connectionTypes) do
        print(string.format("  %s: %d registered, %d disconnected", 
            connectionType, typeStats.registered, typeStats.disconnected))
    end
end

-- ========================================
-- AUTOMATIC LIFECYCLE MANAGEMENT
-- ========================================

-- Initialize automatic cleanup for player disconnections
function ConnectionManager:InitializePlayerCleanup()
    -- Handle player leaving
    self:ConnectPlayerEvent("PlayerRemoving", function(player)
        self:DisconnectAllForOwner(tostring(player.UserId))
    end, "ConnectionManager")
    
    print("🎯 Automatic player cleanup initialized")
end

-- Start periodic stale connection cleanup
function ConnectionManager:StartPeriodicCleanup()
    local cleanupInterval = config:Get("memory.TRACKING.AUTO_CLEANUP_INTERVAL") or 60
    
    self:ConnectHeartbeat(function()
        self:CleanupStaleConnections()
    end, cleanupInterval, "ConnectionManager")
    
    print(string.format("⏰ Periodic cleanup started (every %d seconds)", cleanupInterval))
end

-- ========================================
-- INITIALIZATION
-- ========================================

-- Initialize the connection manager
function ConnectionManager:Initialize()
    print("🔌 Initializing ConnectionManager...")
    
    -- Initialize connection pools
    self:InitializeConnectionPools()
    
    -- Set up automatic cleanup
    self:InitializePlayerCleanup()
    
    -- Start periodic maintenance
    if config:Get("memory.TRACKING.ENABLE_PERFORMANCE_MONITORING") then
        self:StartPeriodicCleanup()
    end
    
    print("✅ ConnectionManager initialized successfully")
    return true
end

-- Cleanup the connection manager itself
function ConnectionManager:Cleanup()
    print("🧹 ConnectionManager shutdown cleanup...")
    
    -- Emergency cleanup all connections
    local totalCleaned = self:EmergencyCleanup()
    
    -- Clear all registries
    playerConnections = {}
    serviceConnections = {}
    connectionPools = {}
    connectionStats = {}
    
    print(string.format("✅ ConnectionManager cleanup complete - %d connections cleaned", totalCleaned))
end

return ConnectionManager
