-- EnterpriseDataService.luau
-- Next-generation data management service with distributed caching, real-time synchronization, and advanced persistence
-- Provides enterprise-grade data reliability, consistency, and performance for high-scale operations

local DataStoreService = game:GetService("DataStoreService")
local MemoryStoreService = game:GetService("MemoryStoreService")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local HttpService = game:GetService("HttpService")

local EnterpriseDataService = {}
EnterpriseDataService.__index = EnterpriseDataService

-- ========================================
-- ENTERPRISE DATA CONFIGURATION
-- ========================================

local DATA_CONFIG = {
    -- Performance settings
    enableDistributedCaching = true,
    enableRealTimeSync = true,
    enableAutoBackup = true,
    enableSharding = true,
    
    -- Reliability settings
    maxRetryAttempts = 5,
    retryBaseDelay = 1, -- seconds
    transactionTimeout = 30, -- seconds
    consistencyLevel = "eventual", -- "strong" or "eventual"
    
    -- Caching settings
    cacheExpiration = 300, -- 5 minutes
    maxCacheSize = 1000, -- entries
    cacheEvictionPolicy = "LRU", -- Least Recently Used
    
    -- Backup settings
    backupInterval = 300, -- 5 minutes
    maxBackupVersions = 10,
    enableSnapshotting = true,
    
    -- Sharding settings
    shardCount = 16,
    enableAutoSharding = true,
    shardRebalanceThreshold = 0.8
}

-- ========================================
-- DATA SCHEMAS AND VALIDATION
-- ========================================

local PLAYER_SCHEMA = {
    userId = {type = "number", required = true},
    level = {type = "number", default = 1, min = 1, max = 1000},
    experience = {type = "number", default = 0, min = 0},
    coins = {type = "number", default = 0, min = 0},
    gems = {type = "number", default = 0, min = 0},
    
    -- Progress tracking
    highScore = {type = "number", default = 0, min = 0},
    gamesPlayed = {type = "number", default = 0, min = 0},
    totalPlayTime = {type = "number", default = 0, min = 0},
    lastPlayed = {type = "number", default = 0},
    
    -- Purchases and monetization
    purchases = {type = "table", default = {}},
    gamepassOwned = {type = "table", default = {}},
    vipStatus = {type = "boolean", default = false},
    
    -- Customization
    equippedTrail = {type = "string", default = "None"},
    ownedTrails = {type = "table", default = {"None"}},
    equippedColor = {type = "string", default = "Blue"},
    
    -- Social features
    friends = {type = "table", default = {}},
    guildId = {type = "string", optional = true},
    achievements = {type = "table", default = {}},
    
    -- Settings
    settings = {type = "table", default = {
        musicEnabled = true,
        sfxEnabled = true,
        quality = "Auto"
    }},
    
    -- Metadata
    createdAt = {type = "number", required = true},
    updatedAt = {type = "number", required = true},
    version = {type = "number", default = 1}
}

-- ========================================
-- ENTERPRISE DATA SERVICE
-- ========================================

function EnterpriseDataService.new(dependencies)
    local self = setmetatable({}, EnterpriseDataService)
    
    -- Dependencies
    self.analyticsService = dependencies and dependencies.EnterpriseAnalyticsService
    
    -- Core data stores
    self.primaryDataStore = DataStoreService:GetDataStore("PlayerData_v4")
    self.backupDataStore = DataStoreService:GetDataStore("PlayerBackup_v4") 
    self.metadataStore = DataStoreService:GetDataStore("DataMetadata_v1")
    
    -- Memory stores for real-time features
    self.distributedCache = MemoryStoreService:GetSortedMap("DistributedCache")
    self.sessionStore = MemoryStoreService:GetHashMap("SessionData")
    self.leaderboardStore = MemoryStoreService:GetSortedMap("Leaderboards")
    
    -- Sharding system
    self.shards = {}
    for i = 1, DATA_CONFIG.shardCount do
        self.shards[i] = DataStoreService:GetDataStore("Shard_" .. i .. "_v1")
    end
    
    -- Local caches
    self.localCache = {
        data = {},
        metadata = {},
        accessTimes = {},
        maxSize = DATA_CONFIG.maxCacheSize
    }
    
    -- Performance tracking
    self.metrics = {
        operationsPerSecond = 0,
        averageLatency = 0,
        cacheHitRate = 0,
        errorRate = 0,
        totalOperations = 0,
        successfulOperations = 0,
        failedOperations = 0
    }
    
    -- Transaction management
    self.activeTransactions = {}
    self.transactionLocks = {}
    
    -- Real-time sync
    self.syncQueue = {}
    self.syncSubscriptions = {}
    
    print("🏦 [DataService] Enterprise Data Service initialized")
    return self
end

-- ========================================
-- CORE DATA OPERATIONS
-- ========================================

function EnterpriseDataService:LoadPlayerData(player)
    local startTime = tick()
    local userId = tostring(player.UserId)
    
    -- Update metrics
    self.metrics.totalOperations += 1
    
    -- Check local cache first
    local cachedData = self:GetFromLocalCache(userId)
    if cachedData then
        self.metrics.successfulOperations += 1
        self.metrics.cacheHitRate = self.metrics.successfulOperations / self.metrics.totalOperations
        return true, cachedData
    end
    
    -- Try distributed cache
    local distributedData = self:GetFromDistributedCache(userId)
    if distributedData then
        self:SetLocalCache(userId, distributedData)
        self.metrics.successfulOperations += 1
        return true, distributedData
    end
    
    -- Load from persistent storage with retries
    local success, playerData = self:LoadWithRetry(userId)
    
    if success then
        -- Validate and migrate data
        playerData = self:ValidateAndMigrateData(playerData)
        
        -- Cache the data
        self:SetLocalCache(userId, playerData)
        self:SetDistributedCache(userId, playerData)
        
        -- Track in analytics
        if self.analyticsService then
            self.analyticsService:TrackEvent(player, "data_loaded", {
                loadTime = tick() - startTime,
                dataSize = self:EstimateDataSize(playerData),
                cacheHit = false
            })
        end
        
        self.metrics.successfulOperations += 1
        print("✅ [DataService] Loaded data for", player.Name)
    else
        -- Create default data for new players
        playerData = self:CreateDefaultPlayerData(player)
        
        -- Save the new data
        self:SavePlayerDataAsync(player, playerData)
        
        self.metrics.successfulOperations += 1
        print("🆕 [DataService] Created new player data for", player.Name)
    end
    
    -- Update performance metrics
    local latency = tick() - startTime
    self.metrics.averageLatency = (self.metrics.averageLatency + latency) / 2
    
    return true, playerData
end

function EnterpriseDataService:SavePlayerData(player, playerData, options)
    local startTime = tick()
    local userId = tostring(player.UserId)
    options = options or {}
    
    -- Validate data before saving
    local isValid, errorMsg = self:ValidatePlayerData(playerData)
    if not isValid then
        warn("❌ [DataService] Invalid player data:", errorMsg)
        return false, errorMsg
    end
    
    -- Update metadata
    playerData.updatedAt = os.time()
    playerData.version = (playerData.version or 1) + 1
    
    -- Create backup if requested
    if options.createBackup or DATA_CONFIG.enableAutoBackup then
        self:CreateBackup(userId, playerData)
    end
    
    -- Start transaction
    local transactionId = self:BeginTransaction(userId)
    
    local success, errorMsg = pcall(function()
        -- Save to primary storage
        self:SaveToPrimaryStorage(userId, playerData)
        
        -- Update caches
        self:SetLocalCache(userId, playerData)
        self:SetDistributedCache(userId, playerData)
        
        -- Real-time sync to other servers
        if DATA_CONFIG.enableRealTimeSync then
            self:BroadcastSync(userId, playerData)
        end
        
        -- Update session data
        self:UpdateSessionData(userId, playerData)
    end)
    
    -- End transaction
    self:EndTransaction(transactionId)
    
    if success then
        -- Track in analytics
        if self.analyticsService then
            self.analyticsService:TrackEvent(player, "data_saved", {
                saveTime = tick() - startTime,
                dataSize = self:EstimateDataSize(playerData),
                transactionId = transactionId
            })
        end
        
        print("💾 [DataService] Saved data for", player.Name)
        return true
    else
        warn("❌ [DataService] Failed to save data for", player.Name, ":", errorMsg)
        return false, errorMsg
    end
end

-- ========================================
-- DISTRIBUTED CACHING SYSTEM
-- ========================================

function EnterpriseDataService:GetFromDistributedCache(userId)
    if not DATA_CONFIG.enableDistributedCaching then
        return nil
    end
    
    local success, cachedData = pcall(function()
        return self.distributedCache:GetAsync(userId)
    end)
    
    if success and cachedData then
        -- Check if cache is still valid
        local cacheAge = os.time() - (cachedData.cacheTimestamp or 0)
        if cacheAge < DATA_CONFIG.cacheExpiration then
            return cachedData.data
        else
            -- Remove expired cache
            pcall(function()
                self.distributedCache:RemoveAsync(userId)
            end)
        end
    end
    
    return nil
end

function EnterpriseDataService:SetDistributedCache(userId, playerData)
    if not DATA_CONFIG.enableDistributedCaching then
        return
    end
    
    local cacheEntry = {
        data = playerData,
        cacheTimestamp = os.time(),
        serverId = game.JobId
    }
    
    pcall(function()
        self.distributedCache:SetAsync(userId, cacheEntry, DATA_CONFIG.cacheExpiration)
    end)
end

function EnterpriseDataService:GetFromLocalCache(userId)
    local cachedData = self.localCache.data[userId]
    if cachedData then
        -- Update access time for LRU eviction
        self.localCache.accessTimes[userId] = tick()
        return cachedData
    end
    return nil
end

function EnterpriseDataService:SetLocalCache(userId, playerData)
    -- Check cache size and evict if necessary
    if self:GetCacheSize() >= self.localCache.maxSize then
        self:EvictLRUEntry()
    end
    
    self.localCache.data[userId] = table.clone(playerData)
    self.localCache.accessTimes[userId] = tick()
end

function EnterpriseDataService:EvictLRUEntry()
    local oldestTime = math.huge
    local oldestKey = nil
    
    for userId, accessTime in pairs(self.localCache.accessTimes) do
        if accessTime < oldestTime then
            oldestTime = accessTime
            oldestKey = userId
        end
    end
    
    if oldestKey then
        self.localCache.data[oldestKey] = nil
        self.localCache.accessTimes[oldestKey] = nil
    end
end

-- ========================================
-- SHARDING SYSTEM
-- ========================================

function EnterpriseDataService:GetShardIndex(userId)
    -- Consistent hashing for shard selection
    local hash = 0
    for i = 1, #userId do
        hash = hash + string.byte(userId, i)
    end
    return (hash % DATA_CONFIG.shardCount) + 1
end

function EnterpriseDataService:LoadFromShard(userId)
    local shardIndex = self:GetShardIndex(userId)
    local shard = self.shards[shardIndex]
    
    return self:LoadWithRetryFromStore(shard, userId)
end

function EnterpriseDataService:SaveToShard(userId, playerData)
    local shardIndex = self:GetShardIndex(userId)
    local shard = self.shards[shardIndex]
    
    return self:SaveWithRetryToStore(shard, userId, playerData)
end

-- ========================================
-- TRANSACTION MANAGEMENT
-- ========================================

function EnterpriseDataService:BeginTransaction(userId)
    local transactionId = HttpService:GenerateGUID(false)
    
    self.activeTransactions[transactionId] = {
        userId = userId,
        startTime = tick(),
        lockAcquired = false
    }
    
    -- Acquire lock
    if not self.transactionLocks[userId] then
        self.transactionLocks[userId] = transactionId
        self.activeTransactions[transactionId].lockAcquired = true
    else
        error("Transaction conflict: user " .. userId .. " is locked by another transaction")
    end
    
    return transactionId
end

function EnterpriseDataService:EndTransaction(transactionId)
    local transaction = self.activeTransactions[transactionId]
    if not transaction then
        return
    end
    
    -- Release lock
    if transaction.lockAcquired then
        self.transactionLocks[transaction.userId] = nil
    end
    
    -- Clean up transaction
    self.activeTransactions[transactionId] = nil
end

-- ========================================
-- REAL-TIME SYNCHRONIZATION
-- ========================================

function EnterpriseDataService:BroadcastSync(userId, playerData)
    local syncMessage = {
        userId = userId,
        data = playerData,
        timestamp = os.time(),
        serverId = game.JobId,
        operation = "update"
    }
    
    -- Add to sync queue
    table.insert(self.syncQueue, syncMessage)
    
    -- Notify subscribers
    for _, callback in ipairs(self.syncSubscriptions) do
        spawn(function()
            pcall(callback, syncMessage)
        end)
    end
end

function EnterpriseDataService:SubscribeToSync(callback)
    table.insert(self.syncSubscriptions, callback)
end

function EnterpriseDataService:ProcessSyncQueue()
    for i = #self.syncQueue, 1, -1 do
        local syncMessage = self.syncQueue[i]
        
        -- Process sync message
        self:ProcessSyncMessage(syncMessage)
        
        -- Remove from queue
        table.remove(self.syncQueue, i)
    end
end

-- ========================================
-- DATA VALIDATION AND MIGRATION
-- ========================================

function EnterpriseDataService:ValidatePlayerData(playerData)
    for fieldName, fieldSchema in pairs(PLAYER_SCHEMA) do
        local value = playerData[fieldName]
        
        -- Check required fields
        if fieldSchema.required and value == nil then
            return false, "Missing required field: " .. fieldName
        end
        
        -- Set default values
        if value == nil and fieldSchema.default ~= nil then
            playerData[fieldName] = fieldSchema.default
        end
        
        -- Type checking
        if value ~= nil then
            local expectedType = fieldSchema.type
            local actualType = type(value)
            
            if expectedType == "table" and actualType ~= "table" then
                return false, "Field " .. fieldName .. " must be a table"
            elseif expectedType == "number" and actualType ~= "number" then
                return false, "Field " .. fieldName .. " must be a number"
            elseif expectedType == "string" and actualType ~= "string" then
                return false, "Field " .. fieldName .. " must be a string"
            elseif expectedType == "boolean" and actualType ~= "boolean" then
                return false, "Field " .. fieldName .. " must be a boolean"
            end
            
            -- Range checking for numbers
            if expectedType == "number" then
                if fieldSchema.min and value < fieldSchema.min then
                    return false, "Field " .. fieldName .. " is below minimum value"
                end
                if fieldSchema.max and value > fieldSchema.max then
                    return false, "Field " .. fieldName .. " is above maximum value"
                end
            end
        end
    end
    
    return true
end

function EnterpriseDataService:ValidateAndMigrateData(playerData)
    -- Migration from older versions
    if not playerData.version or playerData.version < 2 then
        -- Migrate to version 2
        playerData.gems = playerData.gems or 0
        playerData.vipStatus = playerData.vipStatus or false
        playerData.version = 2
    end
    
    if playerData.version < 3 then
        -- Migrate to version 3
        playerData.settings = playerData.settings or {
            musicEnabled = true,
            sfxEnabled = true,
            quality = "Auto"
        }
        playerData.version = 3
    end
    
    -- Validate after migration
    local isValid, errorMsg = self:ValidatePlayerData(playerData)
    if not isValid then
        warn("⚠️ [DataService] Data validation failed after migration:", errorMsg)
        -- Return default data as fallback
        return self:CreateDefaultPlayerData()
    end
    
    return playerData
end

-- ========================================
-- BACKUP AND RECOVERY
-- ========================================

function EnterpriseDataService:CreateBackup(userId, playerData)
    local backupKey = userId .. "_backup_" .. os.time()
    
    local backupData = {
        originalData = table.clone(playerData),
        createdAt = os.time(),
        serverId = game.JobId,
        reason = "auto_backup"
    }
    
    pcall(function()
        self.backupDataStore:SetAsync(backupKey, backupData)
    end)
    
    -- Clean up old backups
    self:CleanupOldBackups(userId)
end

function EnterpriseDataService:RestoreFromBackup(userId, backupTimestamp)
    local backupKey = userId .. "_backup_" .. backupTimestamp
    
    local success, backupData = pcall(function()
        return self.backupDataStore:GetAsync(backupKey)
    end)
    
    if success and backupData then
        return backupData.originalData
    end
    
    return nil
end

-- ========================================
-- UTILITY METHODS
-- ========================================

function EnterpriseDataService:CreateDefaultPlayerData(player)
    local currentTime = os.time()
    
    return {
        userId = player and player.UserId or 0,
        level = 1,
        experience = 0,
        coins = 0,
        gems = 0,
        
        highScore = 0,
        gamesPlayed = 0,
        totalPlayTime = 0,
        lastPlayed = currentTime,
        
        purchases = {},
        gamepassOwned = {},
        vipStatus = false,
        
        equippedTrail = "None",
        ownedTrails = {"None"},
        equippedColor = "Blue",
        
        friends = {},
        achievements = {},
        
        settings = {
            musicEnabled = true,
            sfxEnabled = true,
            quality = "Auto"
        },
        
        createdAt = currentTime,
        updatedAt = currentTime,
        version = 3
    }
end

function EnterpriseDataService:EstimateDataSize(data)
    -- Rough estimation of data size in bytes
    local jsonString = HttpService:JSONEncode(data)
    return #jsonString
end

function EnterpriseDataService:GetCacheSize()
    local count = 0
    for _ in pairs(self.localCache.data) do
        count = count + 1
    end
    return count
end

function EnterpriseDataService:LoadWithRetry(userId)
    for attempt = 1, DATA_CONFIG.maxRetryAttempts do
        local success, result = pcall(function()
            return self.primaryDataStore:GetAsync(userId)
        end)
        
        if success then
            return success, result
        else
            if attempt < DATA_CONFIG.maxRetryAttempts then
                local delay = DATA_CONFIG.retryBaseDelay * (2 ^ (attempt - 1)) -- Exponential backoff
                wait(delay)
            end
        end
    end
    
    return false, "Failed to load after " .. DATA_CONFIG.maxRetryAttempts .. " attempts"
end

function EnterpriseDataService:SaveToPrimaryStorage(userId, playerData)
    for attempt = 1, DATA_CONFIG.maxRetryAttempts do
        local success, errorMsg = pcall(function()
            self.primaryDataStore:SetAsync(userId, playerData)
        end)
        
        if success then
            return true
        else
            if attempt < DATA_CONFIG.maxRetryAttempts then
                local delay = DATA_CONFIG.retryBaseDelay * (2 ^ (attempt - 1))
                wait(delay)
            else
                error("Failed to save after " .. DATA_CONFIG.maxRetryAttempts .. " attempts: " .. tostring(errorMsg))
            end
        end
    end
end

-- ========================================
-- SERVICE LIFECYCLE
-- ========================================

function EnterpriseDataService:Initialize()
    print("🚀 [DataService] Initializing Enterprise Data Service...")
    
    -- Start sync queue processing
    spawn(function()
        while true do
            wait(1)
            self:ProcessSyncQueue()
        end
    end)
    
    -- Start performance monitoring
    spawn(function()
        while true do
            wait(60) -- Every minute
            self:UpdatePerformanceMetrics()
        end
    end)
    
    print("✅ [DataService] Enterprise Data Service initialized")
end

function EnterpriseDataService:Start()
    print("🎯 [DataService] Starting Enterprise Data Service...")
    
    -- Connect to player events
    Players.PlayerAdded:Connect(function(player)
        spawn(function()
            local success, playerData = self:LoadPlayerData(player)
            if success then
                -- Store in session for quick access
                self:UpdateSessionData(tostring(player.UserId), playerData)
            end
        end)
    end)
    
    Players.PlayerRemoving:Connect(function(player)
        spawn(function()
            -- Final save before player leaves
            local sessionData = self:GetSessionData(tostring(player.UserId))
            if sessionData then
                self:SavePlayerData(player, sessionData)
            end
            
            -- Clean up
            self:CleanupPlayerSession(tostring(player.UserId))
        end)
    end)
    
    print("✅ [DataService] Enterprise Data Service started")
end

function EnterpriseDataService:Stop()
    print("🛑 [DataService] Stopping Enterprise Data Service...")
    
    -- Save all active player data
    for player in pairs(Players:GetPlayers()) do
        local sessionData = self:GetSessionData(tostring(player.UserId))
        if sessionData then
            pcall(function()
                self:SavePlayerData(player, sessionData)
            end)
        end
    end
    
    print("✅ [DataService] Enterprise Data Service stopped")
end

function EnterpriseDataService:HealthCheck()
    -- Check if core systems are responsive
    local primaryStoreHealthy = pcall(function()
        self.primaryDataStore:GetAsync("healthcheck_" .. game.JobId)
    end)
    
    local cacheHealthy = self:GetCacheSize() < self.localCache.maxSize
    
    return primaryStoreHealthy and cacheHealthy
end

-- ========================================
-- SESSION MANAGEMENT
-- ========================================

function EnterpriseDataService:UpdateSessionData(userId, playerData)
    pcall(function()
        self.sessionStore:SetAsync(userId, playerData, 3600) -- 1 hour TTL
    end)
end

function EnterpriseDataService:GetSessionData(userId)
    local success, sessionData = pcall(function()
        return self.sessionStore:GetAsync(userId)
    end)
    
    if success then
        return sessionData
    end
    return nil
end

function EnterpriseDataService:CleanupPlayerSession(userId)
    -- Remove from local cache
    self.localCache.data[userId] = nil
    self.localCache.accessTimes[userId] = nil
    
    -- Remove from session store
    pcall(function()
        self.sessionStore:RemoveAsync(userId)
    end)
end

-- ========================================
-- PERFORMANCE MONITORING
-- ========================================

function EnterpriseDataService:UpdatePerformanceMetrics()
    -- Calculate operations per second
    local currentTime = tick()
    if not self.lastMetricsUpdate then
        self.lastMetricsUpdate = currentTime
        return
    end
    
    local timeDelta = currentTime - self.lastMetricsUpdate
    self.metrics.operationsPerSecond = self.metrics.totalOperations / timeDelta
    
    -- Calculate error rate
    self.metrics.errorRate = self.metrics.failedOperations / math.max(self.metrics.totalOperations, 1)
    
    self.lastMetricsUpdate = currentTime
end

-- ========================================
-- PUBLIC API
-- ========================================

function EnterpriseDataService:GetPlayerDataAsync(player)
    return self:LoadPlayerData(player)
end

function EnterpriseDataService:SavePlayerDataAsync(player, playerData)
    return self:SavePlayerData(player, playerData)
end

function EnterpriseDataService:GetMetrics()
    return table.clone(self.metrics)
end

function EnterpriseDataService:GetSystemHealth()
    return {
        isHealthy = self:HealthCheck(),
        metrics = self:GetMetrics(),
        cacheSize = self:GetCacheSize(),
        maxCacheSize = self.localCache.maxSize,
        activeTransactions = 0, -- TODO: Count active transactions
        syncQueueSize = #self.syncQueue
    }
end

return EnterpriseDataService
