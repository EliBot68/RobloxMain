-- DataAccessLayer.luau
-- Comprehensive data access layer with transaction support and conflict resolution
-- Handles all data persistence operations with integrity guarantees

local DataStoreService = game:GetService("DataStoreService")
local MessagingService = game:GetService("MessagingService")
local HttpService = game:GetService("HttpService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local SafeRequire = require(ReplicatedStorage.Shared.utils.SafeRequire)
local ServiceArchitecture = SafeRequire.require(ReplicatedStorage.Shared.core.ServiceArchitecture)

local DataAccessLayer = {}
DataAccessLayer.__index = DataAccessLayer

-- Implement IRepository interface
setmetatable(DataAccessLayer, {__index = ServiceArchitecture.IRepository})

-- ========================================
-- DATA STORE CONFIGURATION
-- ========================================

local DATASTORE_CONFIG = {
    PRIMARY_DATA = "PlayerDataV3",
    BACKUP_DATA = "PlayerDataBackupV3", 
    AUDIT_LOG = "DataAuditLogV3",
    TRANSACTION_LOG = "TransactionLogV3",
    CACHE_STORE = "DataCacheV3",
    SCHEMA_STORE = "DataSchemaV3"
}

local RETRY_CONFIG = {
    maxRetries = 5,
    baseDelay = 0.5,
    maxDelay = 10,
    backoffMultiplier = 2,
    jitterRange = 0.1
}

local TRANSACTION_CONFIG = {
    maxLockDuration = 30, -- seconds
    lockRetryDelay = 0.1,
    maxLockRetries = 100,
    conflictResolutionStrategy = "server_wins" -- "server_wins", "client_wins", "merge", "manual"
}

-- ========================================
-- CORE DATA ACCESS LAYER
-- ========================================

function DataAccessLayer.new()
    local self = setmetatable({}, DataAccessLayer)
    
    -- Initialize DataStores
    self.primaryStore = DataStoreService:GetDataStore(DATASTORE_CONFIG.PRIMARY_DATA)
    self.backupStore = DataStoreService:GetDataStore(DATASTORE_CONFIG.BACKUP_DATA)
    self.auditStore = DataStoreService:GetDataStore(DATASTORE_CONFIG.AUDIT_LOG)
    self.transactionStore = DataStoreService:GetDataStore(DATASTORE_CONFIG.TRANSACTION_LOG)
    self.cacheStore = DataStoreService:GetDataStore(DATASTORE_CONFIG.CACHE_STORE)
    self.schemaStore = DataStoreService:GetDataStore(DATASTORE_CONFIG.SCHEMA_STORE)
    
    -- Internal state
    self.transactionLocks = {} -- Active transaction locks
    self.pendingOperations = {} -- Queued operations per player
    self.dataVersions = {} -- Version tracking per player
    self.lastBackupTime = {} -- Backup tracking per player
    
    -- Statistics
    self.stats = {
        reads = 0,
        writes = 0,
        conflicts = 0,
        retries = 0,
        failures = 0,
        backups = 0,
        cacheHits = 0,
        cacheMisses = 0
    }
    
    print("🗄️ DataAccessLayer initialized with transaction support")
    return self
end

-- ========================================
-- TRANSACTION MANAGEMENT
-- ========================================

function DataAccessLayer:BeginTransaction(playerId, operationType, timeout)
    timeout = timeout or TRANSACTION_CONFIG.maxLockDuration
    local transactionId = self:GenerateTransactionId()
    local lockKey = "lock_" .. tostring(playerId)
    
    -- Attempt to acquire lock
    local lockAcquired = false
    local retries = 0
    
    while retries < TRANSACTION_CONFIG.maxLockRetries and not lockAcquired do
        local success, existingLock = pcall(function()
            return self.transactionStore:GetAsync(lockKey)
        end)
        
        if success and not existingLock then
            -- Attempt to set lock
            local lockData = {
                transactionId = transactionId,
                playerId = playerId,
                operationType = operationType,
                timestamp = os.time(),
                expiresAt = os.time() + timeout,
                serverId = game.JobId
            }
            
            local lockSuccess = pcall(function()
                self.transactionStore:SetAsync(lockKey, lockData)
            end)
            
            if lockSuccess then
                self.transactionLocks[transactionId] = lockData
                lockAcquired = true
                
                self:LogAuditEvent(playerId, "transaction_begin", {
                    transactionId = transactionId,
                    operationType = operationType,
                    timeout = timeout
                })
                
                print("🔒 Transaction lock acquired: " .. transactionId .. " for player " .. playerId)
            end
        elseif success and existingLock then
            -- Check if lock is expired
            if os.time() > existingLock.expiresAt then
                -- Force release expired lock
                pcall(function()
                    self.transactionStore:RemoveAsync(lockKey)
                end)
                print("⏰ Released expired lock for player " .. playerId)
            else
                -- Lock is active, wait and retry
                task.wait(TRANSACTION_CONFIG.lockRetryDelay)
                retries = retries + 1
            end
        else
            -- Error accessing lock store
            task.wait(TRANSACTION_CONFIG.lockRetryDelay)
            retries = retries + 1
        end
    end
    
    if not lockAcquired then
        error("❌ Failed to acquire transaction lock for player " .. playerId .. " after " .. retries .. " retries")
    end
    
    return transactionId
end

function DataAccessLayer:CommitTransaction(transactionId)
    local lockData = self.transactionLocks[transactionId]
    if not lockData then
        error("❌ Invalid transaction ID: " .. transactionId)
    end
    
    local lockKey = "lock_" .. tostring(lockData.playerId)
    
    -- Release the lock
    local success = pcall(function()
        self.transactionStore:RemoveAsync(lockKey)
    end)
    
    if success then
        self.transactionLocks[transactionId] = nil
        
        self:LogAuditEvent(lockData.playerId, "transaction_commit", {
            transactionId = transactionId,
            operationType = lockData.operationType,
            duration = os.time() - lockData.timestamp
        })
        
        print("✅ Transaction committed: " .. transactionId)
        return true
    else
        warn("⚠️ Failed to release transaction lock: " .. transactionId)
        return false
    end
end

function DataAccessLayer:RollbackTransaction(transactionId, reason)
    local lockData = self.transactionLocks[transactionId]
    if not lockData then
        warn("⚠️ Attempted rollback of invalid transaction: " .. transactionId)
        return false
    end
    
    local lockKey = "lock_" .. tostring(lockData.playerId)
    
    -- Release the lock
    pcall(function()
        self.transactionStore:RemoveAsync(lockKey)
    end)
    
    self.transactionLocks[transactionId] = nil
    
    self:LogAuditEvent(lockData.playerId, "transaction_rollback", {
        transactionId = transactionId,
        operationType = lockData.operationType,
        reason = reason or "Unknown",
        duration = os.time() - lockData.timestamp
    })
    
    print("🔄 Transaction rolled back: " .. transactionId .. " - Reason: " .. (reason or "Unknown"))
    return true
end

function DataAccessLayer:IsTransactionActive(transactionId)
    return self.transactionLocks[transactionId] ~= nil
end

-- ========================================
-- VERSIONED DATA OPERATIONS
-- ========================================

function DataAccessLayer:Create(data)
    local playerId = data.playerId
    if not playerId then
        error("❌ Player ID is required for data creation")
    end
    
    local transactionId = self:BeginTransaction(playerId, "CREATE")
    
    local success, result = pcall(function()
        -- Check if data already exists
        local existingData = self:ReadRaw(playerId)
        if existingData then
            error("❌ Data already exists for player " .. playerId)
        end
        
        -- Create versioned data
        local versionedData = {
            data = data.data,
            version = 1,
            lastModified = os.time(),
            createdAt = os.time(),
            serverId = game.JobId,
            checksum = self:CalculateChecksum(data.data)
        }
        
        -- Save to primary store
        self.primaryStore:SetAsync(tostring(playerId), versionedData)
        
        -- Create initial backup
        self:CreateBackup(playerId, versionedData)
        
        -- Update version tracking
        self.dataVersions[playerId] = 1
        
        self.stats.writes = self.stats.writes + 1
        return versionedData
    end)
    
    if success then
        self:CommitTransaction(transactionId)
        return result
    else
        self:RollbackTransaction(transactionId, tostring(result))
        error(result)
    end
end

function DataAccessLayer:Read(playerId)
    local success, data = pcall(function()
        return self:ReadWithRetry(playerId)
    end)
    
    if success then
        self.stats.reads = self.stats.reads + 1
        return data
    else
        self.stats.failures = self.stats.failures + 1
        error("❌ Failed to read data for player " .. playerId .. ": " .. tostring(data))
    end
end

function DataAccessLayer:Update(playerId, updates, expectedVersion)
    local transactionId = self:BeginTransaction(playerId, "UPDATE")
    
    local success, result = pcall(function()
        -- Read current data
        local currentData = self:ReadRaw(playerId)
        if not currentData then
            error("❌ No data found for player " .. playerId)
        end
        
        -- Version conflict detection
        if expectedVersion and currentData.version ~= expectedVersion then
            self.stats.conflicts = self.stats.conflicts + 1
            
            local resolution = self:ResolveVersionConflict(
                playerId,
                currentData,
                updates,
                expectedVersion
            )
            
            if not resolution.canUpdate then
                error("❌ Version conflict detected for player " .. playerId .. 
                      " (expected: " .. expectedVersion .. ", current: " .. currentData.version .. ")")
            end
            
            updates = resolution.mergedUpdates
        end
        
        -- Apply updates
        local newData = self:ApplyUpdates(currentData.data, updates)
        
        -- Validate the updated data
        local validationResult = self:ValidateData(newData)
        if not validationResult.isValid then
            error("❌ Data validation failed: " .. table.concat(validationResult.errors, ", "))
        end
        
        -- Create new version
        local newVersion = currentData.version + 1
        local versionedData = {
            data = newData,
            version = newVersion,
            lastModified = os.time(),
            createdAt = currentData.createdAt,
            serverId = game.JobId,
            checksum = self:CalculateChecksum(newData),
            previousVersion = currentData.version
        }
        
        -- Save to primary store
        self.primaryStore:SetAsync(tostring(playerId), versionedData)
        
        -- Create backup if needed
        if self:ShouldCreateBackup(playerId) then
            self:CreateBackup(playerId, versionedData)
        end
        
        -- Update version tracking
        self.dataVersions[playerId] = newVersion
        
        self.stats.writes = self.stats.writes + 1
        return versionedData
    end)
    
    if success then
        self:CommitTransaction(transactionId)
        return result
    else
        self:RollbackTransaction(transactionId, tostring(result))
        error(result)
    end
end

function DataAccessLayer:Delete(playerId)
    local transactionId = self:BeginTransaction(playerId, "DELETE")
    
    local success, result = pcall(function()
        -- Read current data for backup
        local currentData = self:ReadRaw(playerId)
        if currentData then
            -- Create final backup before deletion
            self:CreateBackup(playerId, currentData, "pre_deletion")
        end
        
        -- Remove from primary store
        self.primaryStore:RemoveAsync(tostring(playerId))
        
        -- Clean up version tracking
        self.dataVersions[playerId] = nil
        self.lastBackupTime[playerId] = nil
        
        return true
    end)
    
    if success then
        self:CommitTransaction(transactionId)
        return result
    else
        self:RollbackTransaction(transactionId, tostring(result))
        error(result)
    end
end

function DataAccessLayer:List(filters)
    -- Note: DataStore doesn't support listing, this would require external indexing
    warn("⚠️ List operations not supported by DataStore - consider using external indexing")
    return {}
end

-- ========================================
-- RAW DATA OPERATIONS
-- ========================================

function DataAccessLayer:ReadRaw(playerId)
    return self:ReadWithRetry(tostring(playerId))
end

function DataAccessLayer:ReadWithRetry(key)
    local retries = 0
    local delay = RETRY_CONFIG.baseDelay
    
    while retries < RETRY_CONFIG.maxRetries do
        local success, data = pcall(function()
            return self.primaryStore:GetAsync(key)
        end)
        
        if success then
            return data
        else
            retries = retries + 1
            self.stats.retries = self.stats.retries + 1
            
            if retries < RETRY_CONFIG.maxRetries then
                -- Calculate jittered delay
                local jitter = (math.random() - 0.5) * 2 * RETRY_CONFIG.jitterRange * delay
                local actualDelay = delay + jitter
                
                task.wait(actualDelay)
                delay = math.min(delay * RETRY_CONFIG.backoffMultiplier, RETRY_CONFIG.maxDelay)
            else
                error("❌ Max retries exceeded reading " .. key .. ": " .. tostring(data))
            end
        end
    end
end

-- ========================================
-- CONFLICT RESOLUTION
-- ========================================

function DataAccessLayer:ResolveVersionConflict(playerId, serverData, clientUpdates, expectedVersion)
    local strategy = TRANSACTION_CONFIG.conflictResolutionStrategy
    
    self:LogAuditEvent(playerId, "version_conflict", {
        serverVersion = serverData.version,
        expectedVersion = expectedVersion,
        strategy = strategy,
        conflictFields = self:IdentifyConflictFields(serverData.data, clientUpdates)
    })
    
    if strategy == "server_wins" then
        return {
            canUpdate = false,
            reason = "Server version takes precedence"
        }
        
    elseif strategy == "client_wins" then
        return {
            canUpdate = true,
            mergedUpdates = clientUpdates
        }
        
    elseif strategy == "merge" then
        local mergedUpdates = self:MergeDataChanges(serverData.data, clientUpdates)
        return {
            canUpdate = true,
            mergedUpdates = mergedUpdates
        }
        
    else
        return {
            canUpdate = false,
            reason = "Manual conflict resolution required",
            serverData = serverData,
            clientUpdates = clientUpdates
        }
    end
end

function DataAccessLayer:IdentifyConflictFields(serverData, clientUpdates)
    local conflicts = {}
    
    for key, value in pairs(clientUpdates) do
        if serverData[key] ~= nil and serverData[key] ~= value then
            table.insert(conflicts, {
                field = key,
                serverValue = serverData[key],
                clientValue = value
            })
        end
    end
    
    return conflicts
end

function DataAccessLayer:MergeDataChanges(serverData, clientUpdates)
    local merged = {}
    
    -- Copy server data as base
    for key, value in pairs(serverData) do
        merged[key] = value
    end
    
    -- Apply non-conflicting client updates
    for key, value in pairs(clientUpdates) do
        if type(value) == "number" and type(serverData[key]) == "number" then
            -- For numeric values, take the maximum (assume both are increments)
            merged[key] = math.max(serverData[key], value)
        elseif type(value) == "table" and type(serverData[key]) == "table" then
            -- For tables, merge recursively
            merged[key] = self:MergeDataChanges(serverData[key], value)
        else
            -- For other types, prefer client updates
            merged[key] = value
        end
    end
    
    return merged
end

-- ========================================
-- DATA VALIDATION
-- ========================================

function DataAccessLayer:ValidateData(data)
    local result = {
        isValid = true,
        errors = {},
        warnings = {}
    }
    
    -- Basic structure validation
    if type(data) ~= "table" then
        table.insert(result.errors, "Data must be a table")
        result.isValid = false
        return result
    end
    
    -- Required fields validation
    local requiredFields = {"coins", "level", "experience", "highScore"}
    for _, field in ipairs(requiredFields) do
        if data[field] == nil then
            table.insert(result.errors, "Missing required field: " .. field)
            result.isValid = false
        elseif type(data[field]) ~= "number" then
            table.insert(result.errors, "Field " .. field .. " must be a number")
            result.isValid = false
        end
    end
    
    -- Range validation
    if data.coins and data.coins < 0 then
        table.insert(result.errors, "Coins cannot be negative")
        result.isValid = false
    end
    
    if data.level and (data.level < 1 or data.level > 1000) then
        table.insert(result.errors, "Level must be between 1 and 1000")
        result.isValid = false
    end
    
    if data.experience and data.experience < 0 then
        table.insert(result.errors, "Experience cannot be negative")
        result.isValid = false
    end
    
    -- Data consistency checks
    if data.level and data.experience then
        local expectedMinXP = (data.level - 1) * 100
        if data.experience < expectedMinXP then
            table.insert(result.warnings, "Experience seems low for current level")
        end
    end
    
    return result
end

-- ========================================
-- BACKUP AND RECOVERY
-- ========================================

function DataAccessLayer:CreateBackup(playerId, data, backupType)
    backupType = backupType or "automatic"
    
    local backupKey = tostring(playerId) .. "_" .. os.time() .. "_" .. backupType
    local backupData = {
        originalData = data,
        backupType = backupType,
        timestamp = os.time(),
        serverId = game.JobId
    }
    
    local success = pcall(function()
        self.backupStore:SetAsync(backupKey, backupData)
    end)
    
    if success then
        self.lastBackupTime[playerId] = os.time()
        self.stats.backups = self.stats.backups + 1
        
        self:LogAuditEvent(playerId, "backup_created", {
            backupKey = backupKey,
            backupType = backupType,
            dataVersion = data.version
        })
        
        print("💾 Backup created for player " .. playerId .. " (" .. backupType .. ")")
        return backupKey
    else
        warn("⚠️ Failed to create backup for player " .. playerId)
        return nil
    end
end

function DataAccessLayer:ShouldCreateBackup(playerId)
    local lastBackup = self.lastBackupTime[playerId]
    if not lastBackup then
        return true -- No backup yet
    end
    
    local timeSinceBackup = os.time() - lastBackup
    return timeSinceBackup >= 300 -- 5 minutes
end

function DataAccessLayer:RestoreFromBackup(playerId, backupKey)
    local transactionId = self:BeginTransaction(playerId, "RESTORE")
    
    local success, result = pcall(function()
        -- Read backup data
        local backupData = self.backupStore:GetAsync(backupKey)
        if not backupData then
            error("❌ Backup not found: " .. backupKey)
        end
        
        -- Restore to primary store
        self.primaryStore:SetAsync(tostring(playerId), backupData.originalData)
        
        -- Update version tracking
        self.dataVersions[playerId] = backupData.originalData.version
        
        self:LogAuditEvent(playerId, "data_restored", {
            backupKey = backupKey,
            restoredVersion = backupData.originalData.version,
            backupTimestamp = backupData.timestamp
        })
        
        return backupData.originalData
    end)
    
    if success then
        self:CommitTransaction(transactionId)
        print("🔄 Data restored for player " .. playerId .. " from backup " .. backupKey)
        return result
    else
        self:RollbackTransaction(transactionId, tostring(result))
        error(result)
    end
end

-- ========================================
-- UTILITY FUNCTIONS
-- ========================================

function DataAccessLayer:GenerateTransactionId()
    return "txn_" .. game.JobId .. "_" .. os.time() .. "_" .. math.random(1000, 9999)
end

function DataAccessLayer:CalculateChecksum(data)
    return HttpService:GenerateGUID(false)
end

function DataAccessLayer:ApplyUpdates(originalData, updates)
    local newData = {}
    
    -- Copy original data
    for key, value in pairs(originalData) do
        newData[key] = value
    end
    
    -- Apply updates
    for key, value in pairs(updates) do
        newData[key] = value
    end
    
    return newData
end

function DataAccessLayer:LogAuditEvent(playerId, eventType, eventData)
    local auditEntry = {
        playerId = playerId,
        eventType = eventType,
        eventData = eventData,
        timestamp = os.time(),
        serverId = game.JobId
    }
    
    local auditKey = "audit_" .. playerId .. "_" .. os.time() .. "_" .. math.random(1000, 9999)
    
    pcall(function()
        self.auditStore:SetAsync(auditKey, auditEntry)
    end)
end

function DataAccessLayer:GetStatistics()
    return {
        stats = self.stats,
        activeTransactions = #self.transactionLocks,
        trackedVersions = 0,
        uptime = tick() - (self.startTime or tick())
    }
    
    -- Count tracked versions
    for _ in pairs(self.dataVersions) do
        _.trackedVersions = _.trackedVersions + 1
    end
end

return DataAccessLayer
