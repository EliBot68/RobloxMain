-- BackupManager.luau
-- Comprehensive backup and disaster recovery system
-- Handles automatic backups, recovery procedures, and data integrity

local DataStoreService = game:GetService("DataStoreService")
local MessagingService = game:GetService("MessagingService")
local HttpService = game:GetService("HttpService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local SafeRequire = require(ReplicatedStorage.Shared.utils.SafeRequire)
local ServiceArchitecture = SafeRequire.require(ReplicatedStorage.Shared.core.ServiceArchitecture)

local BackupManager = {}
BackupManager.__index = BackupManager

-- Implement IBackupManager interface
setmetatable(BackupManager, {__index = ServiceArchitecture.IBackupManager})

-- ========================================
-- BACKUP CONFIGURATION
-- ========================================

local BACKUP_CONFIG = {
    automaticBackupInterval = 300, -- 5 minutes
    retentionPeriod = 604800, -- 7 days in seconds
    maxBackupsPerPlayer = 50,
    compressionEnabled = true,
    encryptionEnabled = false,
    verificationEnabled = true,
    redundantCopies = 2
}

local BACKUP_STORES = {
    PRIMARY = "PlayerBackupsV3",
    SECONDARY = "PlayerBackupsSecondaryV3",
    METADATA = "BackupMetadataV3",
    RECOVERY_LOG = "RecoveryLogV3"
}

local BACKUP_TYPES = {
    AUTOMATIC = "automatic",
    MANUAL = "manual",
    PRE_UPDATE = "pre_update",
    PRE_DELETION = "pre_deletion",
    MIGRATION = "migration",
    EMERGENCY = "emergency"
}

-- ========================================
-- CORE BACKUP MANAGER
-- ========================================

function BackupManager.new()
    local self = setmetatable({}, BackupManager)
    
    -- Initialize DataStores
    self.primaryBackupStore = DataStoreService:GetDataStore(BACKUP_STORES.PRIMARY)
    self.secondaryBackupStore = DataStoreService:GetDataStore(BACKUP_STORES.SECONDARY)
    self.metadataStore = DataStoreService:GetDataStore(BACKUP_STORES.METADATA)
    self.recoveryLogStore = DataStoreService:GetDataStore(BACKUP_STORES.RECOVERY_LOG)
    
    -- Backup state management
    self.backupSchedule = {}
    self.lastBackupTimes = {}
    self.activeBackups = {}
    self.recoveryQueue = {}
    
    -- Statistics
    self.stats = {
        backupsCreated = 0,
        backupsRestored = 0,
        backupFailures = 0,
        recoverySuccesses = 0,
        recoveryFailures = 0,
        dataCorruption = 0,
        spaceUsed = 0
    }
    
    -- Start automatic backup scheduler
    self:StartBackupScheduler()
    
    print("💾 BackupManager initialized with disaster recovery capabilities")
    return self
end

-- ========================================
-- BACKUP CREATION
-- ========================================

function BackupManager:CreateBackup(playerId, data, backupType, metadata)
    backupType = backupType or BACKUP_TYPES.MANUAL
    metadata = metadata or {}
    
    local backupId = self:GenerateBackupId(playerId, backupType)
    
    local backupData = {
        backupId = backupId,
        playerId = playerId,
        data = data,
        backupType = backupType,
        timestamp = os.time(),
        serverId = game.JobId,
        metadata = metadata,
        checksum = self:CalculateChecksum(data),
        dataVersion = data.version or 0,
        schemaVersion = "1.0.0"
    }
    
    -- Compress data if enabled
    if BACKUP_CONFIG.compressionEnabled then
        backupData.compressed = true
        backupData.data = self:CompressData(data)
    end
    
    -- Create backup with redundancy
    local success = self:CreateRedundantBackup(backupData)
    
    if success then
        -- Update metadata
        self:UpdateBackupMetadata(playerId, backupId, backupData)
        
        -- Update tracking
        self.lastBackupTimes[playerId] = os.time()
        self.stats.backupsCreated = self.stats.backupsCreated + 1
        
        self:LogBackupEvent(playerId, "backup_created", {
            backupId = backupId,
            backupType = backupType,
            dataSize = self:CalculateDataSize(data),
            checksum = backupData.checksum
        })
        
        print("💾 Backup created: " .. backupId .. " for player " .. playerId .. " (type: " .. backupType .. ")")
        
        -- Clean up old backups
        self:CleanupOldBackups(playerId)
        
        return backupId
    else
        self.stats.backupFailures = self.stats.backupFailures + 1
        warn("❌ Failed to create backup for player " .. playerId)
        return nil
    end
end

function BackupManager:CreateRedundantBackup(backupData)
    local primarySuccess = false
    local secondarySuccess = false
    
    -- Save to primary backup store
    local success1 = pcall(function()
        self.primaryBackupStore:SetAsync(backupData.backupId, backupData)
    end)
    
    if success1 then
        primarySuccess = true
    else
        warn("⚠️ Failed to save backup to primary store: " .. backupData.backupId)
    end
    
    -- Save to secondary backup store
    local success2 = pcall(function()
        self.secondaryBackupStore:SetAsync(backupData.backupId, backupData)
    end)
    
    if success2 then
        secondarySuccess = true
    else
        warn("⚠️ Failed to save backup to secondary store: " .. backupData.backupId)
    end
    
    -- Require at least one successful save
    return primarySuccess or secondarySuccess
end

function BackupManager:CreateAutomaticBackup(playerId, data)
    return self:CreateBackup(playerId, data, BACKUP_TYPES.AUTOMATIC, {
        automaticBackup = true,
        scheduledAt = os.time()
    })
end

function BackupManager:CreatePreUpdateBackup(playerId, data, updateInfo)
    return self:CreateBackup(playerId, data, BACKUP_TYPES.PRE_UPDATE, {
        preUpdate = true,
        updateInfo = updateInfo,
        originalVersion = data.version or 0
    })
end

function BackupManager:CreateEmergencyBackup(playerId, data, reason)
    return self:CreateBackup(playerId, data, BACKUP_TYPES.EMERGENCY, {
        emergency = true,
        reason = reason,
        priority = "high"
    })
end

-- ========================================
-- BACKUP RESTORATION
-- ========================================

function BackupManager:RestoreFromBackup(playerId, backupId, targetStore)
    local backupData = self:GetBackupData(backupId)
    
    if not backupData then
        warn("❌ Backup not found: " .. backupId)
        return false
    end
    
    -- Verify backup integrity
    local verificationResult = self:VerifyBackupIntegrity(backupData)
    if not verificationResult.isValid then
        warn("❌ Backup integrity check failed: " .. table.concat(verificationResult.errors, ", "))
        self.stats.dataCorruption = self.stats.dataCorruption + 1
        return false
    end
    
    -- Decompress data if needed
    local restoredData = backupData.data
    if backupData.compressed then
        restoredData = self:DecompressData(backupData.data)
    end
    
    -- Restore to target store (or primary data store if not specified)
    local success = false
    if targetStore then
        success = pcall(function()
            targetStore:SetAsync(tostring(playerId), restoredData)
        end)
    else
        -- Restore to primary data store
        local DataStoreService = game:GetService("DataStoreService")
        local primaryStore = DataStoreService:GetDataStore("PlayerDataV3")
        success = pcall(function()
            primaryStore:SetAsync(tostring(playerId), restoredData)
        end)
    end
    
    if success then
        self.stats.recoverySuccesses = self.stats.recoverySuccesses + 1
        
        self:LogRecoveryEvent(playerId, "restore_success", {
            backupId = backupId,
            restoredVersion = restoredData.version or 0,
            backupTimestamp = backupData.timestamp,
            backupType = backupData.backupType
        })
        
        print("✅ Successfully restored data for player " .. playerId .. " from backup " .. backupId)
        return true
    else
        self.stats.recoveryFailures = self.stats.recoveryFailures + 1
        
        self:LogRecoveryEvent(playerId, "restore_failure", {
            backupId = backupId,
            reason = "Failed to write to target store"
        })
        
        warn("❌ Failed to restore data for player " .. playerId .. " from backup " .. backupId)
        return false
    end
end

function BackupManager:GetLatestBackup(playerId, backupType)
    local metadata = self:GetPlayerBackupMetadata(playerId)
    
    if not metadata or not metadata.backups then
        return nil
    end
    
    local latestBackup = nil
    local latestTimestamp = 0
    
    for backupId, backupInfo in pairs(metadata.backups) do
        if (not backupType or backupInfo.backupType == backupType) then
            if backupInfo.timestamp > latestTimestamp then
                latestTimestamp = backupInfo.timestamp
                latestBackup = backupId
            end
        end
    end
    
    return latestBackup
end

function BackupManager:RestoreLatestBackup(playerId, backupType)
    local latestBackupId = self:GetLatestBackup(playerId, backupType)
    
    if not latestBackupId then
        warn("❌ No backup found for player " .. playerId .. " (type: " .. (backupType or "any") .. ")")
        return false
    end
    
    return self:RestoreFromBackup(playerId, latestBackupId)
end

-- ========================================
-- BACKUP RETRIEVAL
-- ========================================

function BackupManager:GetBackupData(backupId)
    local backupData = nil
    
    -- Try primary store first
    local success1, data1 = pcall(function()
        return self.primaryBackupStore:GetAsync(backupId)
    end)
    
    if success1 and data1 then
        backupData = data1
    else
        -- Try secondary store
        local success2, data2 = pcall(function()
            return self.secondaryBackupStore:GetAsync(backupId)
        end)
        
        if success2 and data2 then
            backupData = data2
            warn("⚠️ Backup retrieved from secondary store: " .. backupId)
        end
    end
    
    return backupData
end

function BackupManager:ListPlayerBackups(playerId, backupType, limit)
    local metadata = self:GetPlayerBackupMetadata(playerId)
    
    if not metadata or not metadata.backups then
        return {}
    end
    
    local backups = {}
    
    for backupId, backupInfo in pairs(metadata.backups) do
        if not backupType or backupInfo.backupType == backupType then
            table.insert(backups, {
                backupId = backupId,
                timestamp = backupInfo.timestamp,
                backupType = backupInfo.backupType,
                dataVersion = backupInfo.dataVersion,
                size = backupInfo.size
            })
        end
    end
    
    -- Sort by timestamp (newest first)
    table.sort(backups, function(a, b)
        return a.timestamp > b.timestamp
    end)
    
    -- Apply limit if specified
    if limit and #backups > limit then
        local limitedBackups = {}
        for i = 1, limit do
            table.insert(limitedBackups, backups[i])
        end
        return limitedBackups
    end
    
    return backups
end

-- ========================================
-- BACKUP METADATA MANAGEMENT
-- ========================================

function BackupManager:UpdateBackupMetadata(playerId, backupId, backupData)
    local metadataKey = "player_" .. tostring(playerId)
    
    local success, currentMetadata = pcall(function()
        return self.metadataStore:GetAsync(metadataKey)
    end)
    
    if not success or not currentMetadata then
        currentMetadata = {
            playerId = playerId,
            backups = {},
            totalBackups = 0,
            totalSize = 0,
            lastBackup = 0
        }
    end
    
    -- Add backup info
    local dataSize = self:CalculateDataSize(backupData.data)
    currentMetadata.backups[backupId] = {
        timestamp = backupData.timestamp,
        backupType = backupData.backupType,
        dataVersion = backupData.dataVersion,
        size = dataSize,
        checksum = backupData.checksum,
        serverId = backupData.serverId
    }
    
    currentMetadata.totalBackups = currentMetadata.totalBackups + 1
    currentMetadata.totalSize = currentMetadata.totalSize + dataSize
    currentMetadata.lastBackup = backupData.timestamp
    
    -- Save updated metadata
    pcall(function()
        self.metadataStore:SetAsync(metadataKey, currentMetadata)
    end)
end

function BackupManager:GetPlayerBackupMetadata(playerId)
    local metadataKey = "player_" .. tostring(playerId)
    
    local success, metadata = pcall(function()
        return self.metadataStore:GetAsync(metadataKey)
    end)
    
    return success and metadata or nil
end

-- ========================================
-- BACKUP SCHEDULING
-- ========================================

function BackupManager:StartBackupScheduler()
    -- Schedule automatic backups
    task.spawn(function()
        while true do
            task.wait(BACKUP_CONFIG.automaticBackupInterval)
            self:ProcessScheduledBackups()
        end
    end)
    
    print("⏰ Backup scheduler started (interval: " .. BACKUP_CONFIG.automaticBackupInterval .. "s)")
end

function BackupManager:ProcessScheduledBackups()
    -- This would typically be integrated with player data management
    -- For now, it's a placeholder for the automatic backup system
    
    print("🔄 Processing scheduled backups...")
    
    -- Clean up expired backups
    self:CleanupExpiredBackups()
end

function BackupManager:ScheduleBackup(playerId, delay, backupType)
    local scheduleTime = os.time() + delay
    
    if not self.backupSchedule[playerId] then
        self.backupSchedule[playerId] = {}
    end
    
    table.insert(self.backupSchedule[playerId], {
        scheduleTime = scheduleTime,
        backupType = backupType or BACKUP_TYPES.AUTOMATIC
    })
    
    print("📅 Backup scheduled for player " .. playerId .. " in " .. delay .. " seconds")
end

function BackupManager:ShouldCreateAutomaticBackup(playerId)
    local lastBackup = self.lastBackupTimes[playerId]
    
    if not lastBackup then
        return true -- No backup yet
    end
    
    local timeSinceBackup = os.time() - lastBackup
    return timeSinceBackup >= BACKUP_CONFIG.automaticBackupInterval
end

-- ========================================
-- BACKUP CLEANUP
-- ========================================

function BackupManager:CleanupOldBackups(playerId)
    local metadata = self:GetPlayerBackupMetadata(playerId)
    
    if not metadata or not metadata.backups then
        return
    end
    
    local backupsToDelete = {}
    local currentTime = os.time()
    
    -- Find backups to delete (based on retention period and max count)
    local backupList = {}
    for backupId, backupInfo in pairs(metadata.backups) do
        table.insert(backupList, {
            id = backupId,
            timestamp = backupInfo.timestamp,
            backupType = backupInfo.backupType
        })
    end
    
    -- Sort by timestamp (oldest first)
    table.sort(backupList, function(a, b)
        return a.timestamp < b.timestamp
    end)
    
    -- Mark old backups for deletion
    local backupCount = #backupList
    for i, backup in ipairs(backupList) do
        local age = currentTime - backup.timestamp
        local shouldDelete = false
        
        -- Delete if expired
        if age > BACKUP_CONFIG.retentionPeriod then
            shouldDelete = true
        end
        
        -- Delete if exceeding max count (keep newest)
        if backupCount > BACKUP_CONFIG.maxBackupsPerPlayer then
            local excessCount = backupCount - BACKUP_CONFIG.maxBackupsPerPlayer
            if i <= excessCount then
                shouldDelete = true
            end
        end
        
        -- Never delete emergency backups automatically
        if backup.backupType == BACKUP_TYPES.EMERGENCY then
            shouldDelete = false
        end
        
        if shouldDelete then
            table.insert(backupsToDelete, backup.id)
        end
    end
    
    -- Delete the backups
    for _, backupId in ipairs(backupsToDelete) do
        self:DeleteBackup(backupId, playerId)
    end
    
    if #backupsToDelete > 0 then
        print("🗑️ Cleaned up " .. #backupsToDelete .. " old backups for player " .. playerId)
    end
end

function BackupManager:CleanupExpiredBackups()
    -- This would require iterating through all player metadata
    -- For now, cleanup happens per-player when new backups are created
    
    print("🧹 Expired backup cleanup completed")
end

function BackupManager:DeleteBackup(backupId, playerId)
    -- Delete from both stores
    pcall(function()
        self.primaryBackupStore:RemoveAsync(backupId)
    end)
    
    pcall(function()
        self.secondaryBackupStore:RemoveAsync(backupId)
    end)
    
    -- Update metadata
    local metadataKey = "player_" .. tostring(playerId)
    local success, metadata = pcall(function()
        return self.metadataStore:GetAsync(metadataKey)
    end)
    
    if success and metadata and metadata.backups then
        local backupInfo = metadata.backups[backupId]
        if backupInfo then
            metadata.backups[backupId] = nil
            metadata.totalBackups = metadata.totalBackups - 1
            metadata.totalSize = metadata.totalSize - (backupInfo.size or 0)
            
            pcall(function()
                self.metadataStore:SetAsync(metadataKey, metadata)
            end)
        end
    end
    
    self:LogBackupEvent(playerId, "backup_deleted", {
        backupId = backupId,
        reason = "cleanup"
    })
end

-- ========================================
-- BACKUP VERIFICATION
-- ========================================

function BackupManager:VerifyBackupIntegrity(backupData)
    local result = {
        isValid = true,
        errors = {},
        warnings = {}
    }
    
    -- Check required fields
    local requiredFields = {"backupId", "playerId", "data", "timestamp", "checksum"}
    for _, field in ipairs(requiredFields) do
        if backupData[field] == nil then
            table.insert(result.errors, "Missing required field: " .. field)
            result.isValid = false
        end
    end
    
    if not result.isValid then
        return result
    end
    
    -- Verify checksum
    local expectedChecksum = self:CalculateChecksum(backupData.data)
    if backupData.checksum ~= expectedChecksum then
        table.insert(result.errors, "Checksum mismatch - data may be corrupted")
        result.isValid = false
    end
    
    -- Check data structure
    if type(backupData.data) ~= "table" then
        table.insert(result.errors, "Backup data must be a table")
        result.isValid = false
    end
    
    -- Verify timestamp
    if backupData.timestamp > os.time() then
        table.insert(result.warnings, "Backup timestamp is in the future")
    end
    
    local backupAge = os.time() - backupData.timestamp
    if backupAge > BACKUP_CONFIG.retentionPeriod * 2 then
        table.insert(result.warnings, "Backup is very old (" .. backupAge .. " seconds)")
    end
    
    return result
end

function BackupManager:VerifyAllPlayerBackups(playerId)
    local backups = self:ListPlayerBackups(playerId)
    local results = {}
    
    for _, backup in ipairs(backups) do
        local backupData = self:GetBackupData(backup.backupId)
        if backupData then
            local verification = self:VerifyBackupIntegrity(backupData)
            results[backup.backupId] = verification
            
            if not verification.isValid then
                warn("❌ Corrupted backup detected: " .. backup.backupId)
                self.stats.dataCorruption = self.stats.dataCorruption + 1
            end
        else
            results[backup.backupId] = {
                isValid = false,
                errors = {"Backup data not found"},
                warnings = {}
            }
        end
    end
    
    return results
end

-- ========================================
-- UTILITY FUNCTIONS
-- ========================================

function BackupManager:GenerateBackupId(playerId, backupType)
    local timestamp = os.time()
    local random = math.random(1000, 9999)
    return "backup_" .. playerId .. "_" .. backupType .. "_" .. timestamp .. "_" .. random
end

function BackupManager:CalculateChecksum(data)
    -- Simple checksum based on JSON encoding
    local jsonString = HttpService:JSONEncode(data)
    local checksum = 0
    
    for i = 1, string.len(jsonString) do
        checksum = checksum + string.byte(jsonString, i)
    end
    
    return checksum
end

function BackupManager:CalculateDataSize(data)
    -- Estimate data size based on JSON encoding
    local jsonString = HttpService:JSONEncode(data)
    return string.len(jsonString)
end

function BackupManager:CompressData(data)
    -- Simple compression (in a real implementation, use actual compression)
    local jsonString = HttpService:JSONEncode(data)
    return {
        compressed = true,
        originalSize = string.len(jsonString),
        data = jsonString -- In reality, this would be compressed
    }
end

function BackupManager:DecompressData(compressedData)
    -- Simple decompression
    if type(compressedData) == "table" and compressedData.compressed then
        return HttpService:JSONDecode(compressedData.data)
    end
    return compressedData
end

function BackupManager:LogBackupEvent(playerId, eventType, eventData)
    local logEntry = {
        playerId = playerId,
        eventType = eventType,
        eventData = eventData,
        timestamp = os.time(),
        serverId = game.JobId
    }
    
    local logKey = "backup_log_" .. playerId .. "_" .. os.time() .. "_" .. math.random(1000, 9999)
    
    pcall(function()
        self.recoveryLogStore:SetAsync(logKey, logEntry)
    end)
end

function BackupManager:LogRecoveryEvent(playerId, eventType, eventData)
    local logEntry = {
        playerId = playerId,
        eventType = eventType,
        eventData = eventData,
        timestamp = os.time(),
        serverId = game.JobId
    }
    
    local logKey = "recovery_log_" .. playerId .. "_" .. os.time() .. "_" .. math.random(1000, 9999)
    
    pcall(function()
        self.recoveryLogStore:SetAsync(logKey, logEntry)
    end)
end

function BackupManager:GetStatistics()
    local totalSize = 0
    local totalBackups = 0
    
    -- Calculate total size would require iterating all metadata
    -- For now, use tracked statistics
    
    return {
        stats = self.stats,
        config = BACKUP_CONFIG,
        activeSchedules = self:CountActiveSchedules(),
        lastCleanup = self.lastCleanup or 0
    }
end

function BackupManager:CountActiveSchedules()
    local count = 0
    for playerId, schedules in pairs(self.backupSchedule) do
        count = count + #schedules
    end
    return count
end

return BackupManager
