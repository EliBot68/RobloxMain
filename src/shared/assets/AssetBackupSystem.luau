-- AssetBackupSystem.luau
-- Asset backup and recovery systems with comprehensive data protection
-- Provides automated backups, disaster recovery, and data integrity for asset management

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local HttpService = game:GetService("HttpService")
local DataStoreService = game:GetService("DataStoreService")
local TeleportService = game:GetService("TeleportService")

local SafeRequire = require(ReplicatedStorage.Shared.utils.SafeRequire)

local AssetBackupSystem = {}

-- ========================================
-- BACKUP CONFIGURATION
-- ========================================

local BACKUP_CONFIG = {
    -- Backup strategies
    strategies = {
        full = {
            name = "Full Backup",
            description = "Complete backup of all assets and metadata",
            frequency = 604800,      -- 7 days
            compression = true,
            encryption = true,
            priority = "low"
        },
        
        incremental = {
            name = "Incremental Backup",
            description = "Backup only changed assets since last backup",
            frequency = 86400,       -- 24 hours
            compression = true,
            encryption = true,
            priority = "medium"
        },
        
        differential = {
            name = "Differential Backup",
            description = "Backup changes since last full backup",
            frequency = 259200,      -- 3 days
            compression = true,
            encryption = true,
            priority = "medium"
        },
        
        snapshot = {
            name = "Snapshot Backup",
            description = "Point-in-time snapshot of asset state",
            frequency = 3600,        -- 1 hour
            compression = false,
            encryption = false,
            priority = "high"
        },
        
        continuous = {
            name = "Continuous Backup",
            description = "Real-time backup of asset changes",
            frequency = 60,          -- 1 minute
            compression = false,
            encryption = true,
            priority = "critical"
        }
    },
    
    -- Storage configuration
    storage = {
        locations = {
            local = {
                enabled = true,
                path = "/backups/local",
                capacity = 100 * 1024 * 1024 * 1024, -- 100GB
                retention = 30 * 86400                -- 30 days
            },
            
            cloud = {
                enabled = true,
                provider = "cloud_storage",
                bucket = "asset-backups",
                capacity = 1024 * 1024 * 1024 * 1024, -- 1TB
                retention = 365 * 86400               -- 1 year
            },
            
            archive = {
                enabled = true,
                provider = "archive_storage",
                vault = "asset-archives",
                capacity = math.huge,
                retention = 7 * 365 * 86400           -- 7 years
            },
            
            replicated = {
                enabled = true,
                regions = {"us-east-1", "eu-west-1", "asia-pacific-1"},
                syncInterval = 3600,                  -- 1 hour
                redundancy = 3
            }
        },
        
        compression = {
            algorithm = "lz4",
            level = 6,
            chunkSize = 64 * 1024 -- 64KB
        },
        
        encryption = {
            algorithm = "aes256",
            keyRotation = 30 * 86400, -- 30 days
            keyBackup = true
        }
    },
    
    -- Recovery options
    recovery = {
        enablePointInTimeRecovery = true,
        enableSelectiveRecovery = true,
        enableCrossRegionRecovery = true,
        enableDisasterRecovery = true,
        maxRecoveryTime = 4 * 3600,        -- 4 hours RTO
        maxDataLoss = 15 * 60,             -- 15 minutes RPO
        verificationLevel = "full"
    },
    
    -- Monitoring and alerts
    monitoring = {
        enableHealthChecks = true,
        enableIntegrityChecks = true,
        enablePerformanceMonitoring = true,
        checkInterval = 3600,              -- 1 hour
        alertThresholds = {
            failureRate = 0.05,            -- 5%
            corruptionRate = 0.01,         -- 1%
            performanceDegradation = 0.2   -- 20%
        }
    }
}

-- ========================================
-- BACKUP STATE
-- ========================================

local BackupState = {
    -- Backup management
    backupJobs = {},
    backupHistory = {},
    activeBbackups = {},
    
    -- Storage management
    storageLocations = {},
    storageUsage = {},
    
    -- Recovery management
    recoveryJobs = {},
    recoveryHistory = {},
    
    -- Data integrity
    checksums = {},
    verificationResults = {},
    corruptionReports = {},
    
    -- Monitoring
    healthStatus = {},
    performanceMetrics = {},
    alerts = {},
    
    -- Statistics
    stats = {
        totalBackups = 0,
        successfulBackups = 0,
        failedBackups = 0,
        totalDataBacked = 0,
        totalRecoveries = 0,
        averageBackupTime = 0,
        averageRecoveryTime = 0,
        dataIntegrityRate = 100
    }
}

function AssetBackupSystem.initialize()
    print("💾 Initializing AssetBackupSystem...")
    
    -- Set up backup engine
    AssetBackupSystem.setupBackupEngine()
    
    -- Initialize storage management
    AssetBackupSystem.initializeStorageManagement()
    
    -- Set up recovery system
    AssetBackupSystem.setupRecoverySystem()
    
    -- Initialize data integrity monitoring
    AssetBackupSystem.initializeDataIntegrity()
    
    -- Start backup scheduling
    AssetBackupSystem.startBackupScheduling()
    
    print("💾 AssetBackupSystem initialized successfully")
end

-- ========================================
-- BACKUP ENGINE
-- ========================================

function AssetBackupSystem.setupBackupEngine()
    BackupState.backupEngine = {
        scheduler = AssetBackupSystem.createBackupScheduler(),
        executor = AssetBackupSystem.createBackupExecutor(),
        compressor = AssetBackupSystem.createCompressionEngine(),
        encryptor = AssetBackupSystem.createEncryptionEngine()
    }
    
    print("🔧 Backup engine initialized")
end

function AssetBackupSystem.createBackupScheduler()
    return {
        name = "scheduler",
        jobs = {},
        queue = {},
        
        schedule = function(self, job)
            return AssetBackupSystem.scheduleBackupJob(job)
        end,
        
        execute = function(self)
            AssetBackupSystem.executeScheduledBackups(self)
        end
    }
end

function AssetBackupSystem.createBackupExecutor()
    return {
        name = "executor",
        activeJobs = {},
        
        execute = function(self, job)
            return AssetBackupSystem.executeBackupJob(job)
        end,
        
        monitor = function(self)
            AssetBackupSystem.monitorActiveBackups(self)
        end
    }
end

function AssetBackupSystem.createCompressionEngine()
    return {
        name = "compressor",
        algorithm = BACKUP_CONFIG.storage.compression.algorithm,
        level = BACKUP_CONFIG.storage.compression.level,
        
        compress = function(self, data)
            return AssetBackupSystem.compressData(data)
        end,
        
        decompress = function(self, compressedData)
            return AssetBackupSystem.decompressData(compressedData)
        end
    }
end

function AssetBackupSystem.createEncryptionEngine()
    return {
        name = "encryptor",
        algorithm = BACKUP_CONFIG.storage.encryption.algorithm,
        keys = {},
        
        encrypt = function(self, data)
            return AssetBackupSystem.encryptData(data)
        end,
        
        decrypt = function(self, encryptedData)
            return AssetBackupSystem.decryptData(encryptedData)
        end
    }
end

function AssetBackupSystem.createBackup(assetIds, strategy, options)
    options = options or {}
    
    local backup = {
        id = HttpService:GenerateGUID(false),
        strategy = strategy,
        assetIds = assetIds,
        timestamp = tick(),
        status = "pending",
        options = options,
        metadata = {
            totalAssets = #assetIds,
            estimatedSize = AssetBackupSystem.estimateBackupSize(assetIds),
            priority = BACKUP_CONFIG.strategies[strategy].priority,
            compression = BACKUP_CONFIG.strategies[strategy].compression,
            encryption = BACKUP_CONFIG.strategies[strategy].encryption
        },
        progress = {
            current = 0,
            total = #assetIds,
            percentage = 0,
            startTime = nil,
            endTime = nil
        },
        storage = {
            locations = {},
            checksums = {},
            integrity = "pending"
        }
    }
    
    -- Schedule the backup
    BackupState.backupEngine.scheduler:schedule(backup)
    
    print(string.format("💾 Created backup job: %s (%s strategy, %d assets)", 
        backup.id, strategy, #assetIds))
    
    return backup.id
end

function AssetBackupSystem.scheduleBackupJob(job)
    job.status = "scheduled"
    job.scheduledTime = tick()
    
    -- Add to scheduler queue
    table.insert(BackupState.backupEngine.scheduler.queue, job)
    
    -- Sort by priority
    table.sort(BackupState.backupEngine.scheduler.queue, function(a, b)
        local priorityOrder = {critical = 1, high = 2, medium = 3, low = 4}
        return priorityOrder[a.metadata.priority] < priorityOrder[b.metadata.priority]
    end)
    
    BackupState.backupJobs[job.id] = job
    
    return true
end

function AssetBackupSystem.executeBackupJob(job)
    job.status = "running"
    job.progress.startTime = tick()
    
    print(string.format("▶️ Executing backup job: %s (%s)", job.id, job.strategy))
    
    BackupState.activeBbackups[job.id] = job
    
    spawn(function()
        local success = true
        local backupData = {}
        
        -- Process each asset
        for i, assetId in ipairs(job.assetIds) do
            local assetData = AssetBackupSystem.getAssetData(assetId)
            
            if assetData then
                -- Apply compression if enabled
                if job.metadata.compression then
                    assetData = BackupState.backupEngine.compressor:compress(assetData)
                end
                
                -- Apply encryption if enabled
                if job.metadata.encryption then
                    assetData = BackupState.backupEngine.encryptor:encrypt(assetData)
                end
                
                backupData[assetId] = assetData
                
                -- Update progress
                job.progress.current = i
                job.progress.percentage = (i / job.progress.total) * 100
            else
                success = false
                print(string.format("❌ Failed to backup asset: %s", assetId))
            end
            
            -- Yield periodically
            if i % 10 == 0 then
                task.wait(0.1)
            end
        end
        
        -- Store backup data
        if success then
            local stored = AssetBackupSystem.storeBackupData(job, backupData)
            if stored then
                job.status = "completed"
                BackupState.stats.successfulBackups = BackupState.stats.successfulBackups + 1
            else
                job.status = "failed"
                success = false
            end
        else
            job.status = "failed"
        end
        
        if not success then
            BackupState.stats.failedBackups = BackupState.stats.failedBackups + 1
        end
        
        job.progress.endTime = tick()
        job.progress.duration = job.progress.endTime - job.progress.startTime
        
        -- Remove from active backups
        BackupState.activeBbackups[job.id] = nil
        
        -- Add to history
        BackupState.backupHistory[job.id] = job
        
        -- Update statistics
        BackupState.stats.totalBackups = BackupState.stats.totalBackups + 1
        AssetBackupSystem.updateBackupStatistics()
        
        print(string.format("✅ Backup job %s: %s (%.2fs)", 
            job.status, job.id, job.progress.duration))
    end)
    
    return job
end

function AssetBackupSystem.getAssetData(assetId)
    -- Simulate asset data retrieval
    return {
        id = assetId,
        type = "asset_data",
        content = string.format("Asset data for %s", assetId),
        metadata = {
            size = math.random(1024, 1024 * 1024),
            checksum = HttpService:GenerateGUID(false),
            timestamp = tick()
        }
    }
end

function AssetBackupSystem.storeBackupData(job, backupData)
    local success = true
    
    -- Store in each configured location
    for locationName, location in pairs(BACKUP_CONFIG.storage.locations) do
        if location.enabled then
            local stored = AssetBackupSystem.storeInLocation(job, backupData, locationName, location)
            
            if stored then
                job.storage.locations[locationName] = {
                    status = "stored",
                    timestamp = tick(),
                    path = stored.path,
                    size = stored.size,
                    checksum = stored.checksum
                }
            else
                job.storage.locations[locationName] = {
                    status = "failed",
                    timestamp = tick(),
                    error = "Storage failed"
                }
                success = false
            end
        end
    end
    
    return success
end

function AssetBackupSystem.storeInLocation(job, backupData, locationName, location)
    -- Simulate storage to location
    local totalSize = 0
    for _, assetData in pairs(backupData) do
        totalSize = totalSize + (assetData.metadata and assetData.metadata.size or 1024)
    end
    
    local storage = {
        path = string.format("%s/%s/%s", location.path or "/backup", job.strategy, job.id),
        size = totalSize,
        checksum = HttpService:GenerateGUID(false),
        timestamp = tick()
    }
    
    -- Update storage usage
    if not BackupState.storageUsage[locationName] then
        BackupState.storageUsage[locationName] = {
            used = 0,
            capacity = location.capacity,
            items = 0
        }
    end
    
    BackupState.storageUsage[locationName].used = BackupState.storageUsage[locationName].used + totalSize
    BackupState.storageUsage[locationName].items = BackupState.storageUsage[locationName].items + 1
    
    print(string.format("📦 Stored backup in %s: %s (%.1fMB)", 
        locationName, storage.path, totalSize / (1024 * 1024)))
    
    return storage
end

-- ========================================
-- STORAGE MANAGEMENT
-- ========================================

function AssetBackupSystem.initializeStorageManagement()
    BackupState.storageManager = {
        locations = {},
        replication = {},
        cleanup = {},
        monitoring = {}
    }
    
    -- Initialize storage locations
    AssetBackupSystem.initializeStorageLocations()
    
    -- Set up storage monitoring
    AssetBackupSystem.setupStorageMonitoring()
    
    print("🗄️ Storage management initialized")
end

function AssetBackupSystem.initializeStorageLocations()
    for locationName, location in pairs(BACKUP_CONFIG.storage.locations) do
        if location.enabled then
            BackupState.storageLocations[locationName] = {
                name = locationName,
                config = location,
                status = "available",
                health = "healthy",
                lastCheck = tick()
            }
            
            BackupState.storageUsage[locationName] = {
                used = 0,
                capacity = location.capacity,
                items = 0,
                usagePercentage = 0
            }
        end
    end
end

function AssetBackupSystem.setupStorageMonitoring()
    spawn(function()
        while true do
            AssetBackupSystem.checkStorageHealth()
            AssetBackupSystem.manageStorageRetention()
            AssetBackupSystem.replicateBackups()
            
            task.wait(3600) -- Check every hour
        end
    end)
end

function AssetBackupSystem.checkStorageHealth()
    for locationName, location in pairs(BackupState.storageLocations) do
        local health = AssetBackupSystem.assessStorageHealth(locationName)
        location.health = health.status
        location.lastCheck = tick()
        
        if health.status ~= "healthy" then
            AssetBackupSystem.handleStorageIssue(locationName, health)
        end
    end
end

function AssetBackupSystem.assessStorageHealth(locationName)
    local usage = BackupState.storageUsage[locationName]
    usage.usagePercentage = (usage.used / usage.capacity) * 100
    
    local health = {
        status = "healthy",
        issues = {}
    }
    
    -- Check capacity
    if usage.usagePercentage > 95 then
        health.status = "critical"
        table.insert(health.issues, "Storage almost full")
    elseif usage.usagePercentage > 85 then
        health.status = "warning"
        table.insert(health.issues, "Storage usage high")
    end
    
    return health
end

function AssetBackupSystem.manageStorageRetention()
    local currentTime = tick()
    
    for locationName, location in pairs(BackupState.storageLocations) do
        local retention = location.config.retention
        local cutoffTime = currentTime - retention
        
        -- Find expired backups
        local expiredBackups = {}
        for backupId, backup in pairs(BackupState.backupHistory) do
            if backup.timestamp < cutoffTime and backup.storage.locations[locationName] then
                table.insert(expiredBackups, backupId)
            end
        end
        
        -- Clean up expired backups
        for _, backupId in ipairs(expiredBackups) do
            AssetBackupSystem.deleteBackup(backupId, locationName)
        end
        
        if #expiredBackups > 0 then
            print(string.format("🗑️ Cleaned up %d expired backups from %s", 
                #expiredBackups, locationName))
        end
    end
end

function AssetBackupSystem.deleteBackup(backupId, locationName)
    local backup = BackupState.backupHistory[backupId]
    if not backup or not backup.storage.locations[locationName] then
        return false
    end
    
    local storageInfo = backup.storage.locations[locationName]
    
    -- Update storage usage
    local usage = BackupState.storageUsage[locationName]
    usage.used = usage.used - storageInfo.size
    usage.items = usage.items - 1
    
    -- Remove storage reference
    backup.storage.locations[locationName] = nil
    
    print(string.format("🗑️ Deleted backup %s from %s", backupId, locationName))
    
    return true
end

-- ========================================
-- RECOVERY SYSTEM
-- ========================================

function AssetBackupSystem.setupRecoverySystem()
    BackupState.recoverySystem = {
        engine = AssetBackupSystem.createRecoveryEngine(),
        validator = AssetBackupSystem.createRecoveryValidator(),
        monitor = AssetBackupSystem.createRecoveryMonitor()
    }
    
    print("🔄 Recovery system initialized")
end

function AssetBackupSystem.createRecoveryEngine()
    return {
        name = "recovery_engine",
        activeRecoveries = {},
        
        recover = function(self, recoveryRequest)
            return AssetBackupSystem.executeRecovery(recoveryRequest)
        end
    }
end

function AssetBackupSystem.createRecoveryValidator()
    return {
        name = "recovery_validator",
        
        validate = function(self, recoveryRequest)
            return AssetBackupSystem.validateRecoveryRequest(recoveryRequest)
        end
    }
end

function AssetBackupSystem.createRecoveryMonitor()
    return {
        name = "recovery_monitor",
        
        monitor = function(self)
            AssetBackupSystem.monitorRecoveryOperations()
        end
    }
end

function AssetBackupSystem.recoverAssets(assetIds, options)
    options = options or {}
    
    local recovery = {
        id = HttpService:GenerateGUID(false),
        assetIds = assetIds,
        options = options,
        timestamp = tick(),
        status = "pending",
        targetTime = options.targetTime or tick(),
        targetLocation = options.targetLocation or "local",
        validation = options.validation or "full",
        progress = {
            current = 0,
            total = #assetIds,
            percentage = 0,
            startTime = nil,
            endTime = nil
        },
        results = {}
    }
    
    -- Validate recovery request
    local validation = BackupState.recoverySystem.validator:validate(recovery)
    if not validation.valid then
        recovery.status = "failed"
        recovery.error = validation.error
        return recovery
    end
    
    -- Execute recovery
    BackupState.recoverySystem.engine:recover(recovery)
    
    print(string.format("🔄 Started recovery: %s (%d assets)", recovery.id, #assetIds))
    
    return recovery
end

function AssetBackupSystem.validateRecoveryRequest(recovery)
    local validation = {valid = true, error = nil}
    
    -- Check if assets exist in backups
    local availableAssets = AssetBackupSystem.findAvailableAssets(recovery.assetIds, recovery.targetTime)
    
    if #availableAssets == 0 then
        validation.valid = false
        validation.error = "No backup found for requested assets and time"
        return validation
    end
    
    -- Check target location availability
    local targetLocation = BackupState.storageLocations[recovery.targetLocation]
    if not targetLocation or targetLocation.status ~= "available" then
        validation.valid = false
        validation.error = "Target location not available"
        return validation
    end
    
    return validation
end

function AssetBackupSystem.executeRecovery(recovery)
    recovery.status = "running"
    recovery.progress.startTime = tick()
    
    BackupState.recoveryJobs[recovery.id] = recovery
    
    spawn(function()
        local success = true
        local recoveredAssets = {}
        
        -- Find appropriate backups
        local backups = AssetBackupSystem.findRecoveryBackups(recovery.assetIds, recovery.targetTime)
        
        -- Recover each asset
        for i, assetId in ipairs(recovery.assetIds) do
            local backup = AssetBackupSystem.findAssetBackup(assetId, backups)
            
            if backup then
                local assetData = AssetBackupSystem.recoverAssetFromBackup(assetId, backup)
                
                if assetData then
                    recoveredAssets[assetId] = assetData
                    recovery.results[assetId] = {
                        status = "recovered",
                        backupId = backup.id,
                        timestamp = backup.timestamp
                    }
                else
                    recovery.results[assetId] = {
                        status = "failed",
                        error = "Recovery failed"
                    }
                    success = false
                end
            else
                recovery.results[assetId] = {
                    status = "not_found",
                    error = "No backup available"
                }
                success = false
            end
            
            -- Update progress
            recovery.progress.current = i
            recovery.progress.percentage = (i / recovery.progress.total) * 100
            
            task.wait(0.1)
        end
        
        -- Validate recovered data if requested
        if recovery.validation ~= "none" then
            success = AssetBackupSystem.validateRecoveredData(recoveredAssets, recovery.validation) and success
        end
        
        recovery.status = success and "completed" or "failed"
        recovery.progress.endTime = tick()
        recovery.progress.duration = recovery.progress.endTime - recovery.progress.startTime
        
        -- Clean up
        BackupState.recoveryJobs[recovery.id] = nil
        BackupState.recoveryHistory[recovery.id] = recovery
        
        -- Update statistics
        BackupState.stats.totalRecoveries = BackupState.stats.totalRecoveries + 1
        AssetBackupSystem.updateRecoveryStatistics()
        
        print(string.format("✅ Recovery %s: %s (%.2fs)", 
            recovery.status, recovery.id, recovery.progress.duration))
    end)
    
    return recovery
end

function AssetBackupSystem.findRecoveryBackups(assetIds, targetTime)
    local candidates = {}
    
    -- Find backups that contain the requested assets and are before target time
    for backupId, backup in pairs(BackupState.backupHistory) do
        if backup.timestamp <= targetTime and backup.status == "completed" then
            local hasAssets = false
            for _, assetId in ipairs(assetIds) do
                for _, backupAssetId in ipairs(backup.assetIds) do
                    if assetId == backupAssetId then
                        hasAssets = true
                        break
                    end
                end
                if hasAssets then break end
            end
            
            if hasAssets then
                table.insert(candidates, backup)
            end
        end
    end
    
    -- Sort by timestamp (newest first)
    table.sort(candidates, function(a, b) return a.timestamp > b.timestamp end)
    
    return candidates
end

function AssetBackupSystem.findAssetBackup(assetId, backups)
    for _, backup in ipairs(backups) do
        for _, backupAssetId in ipairs(backup.assetIds) do
            if assetId == backupAssetId then
                return backup
            end
        end
    end
    return nil
end

function AssetBackupSystem.recoverAssetFromBackup(assetId, backup)
    -- Simulate asset recovery from backup
    local assetData = {
        id = assetId,
        type = "recovered_asset",
        content = string.format("Recovered data for %s from backup %s", assetId, backup.id),
        metadata = {
            originalBackup = backup.id,
            recoveryTime = tick(),
            integrity = "verified"
        }
    }
    
    return assetData
end

function AssetBackupSystem.validateRecoveredData(recoveredAssets, validationLevel)
    if validationLevel == "none" then
        return true
    end
    
    local validationPassed = true
    
    for assetId, assetData in pairs(recoveredAssets) do
        local validation = AssetBackupSystem.validateAssetData(assetData, validationLevel)
        if not validation.valid then
            validationPassed = false
            print(string.format("❌ Validation failed for asset %s: %s", assetId, validation.error))
        end
    end
    
    return validationPassed
end

function AssetBackupSystem.validateAssetData(assetData, validationLevel)
    local validation = {valid = true, error = nil}
    
    if validationLevel == "basic" then
        -- Basic validation - check if data exists
        if not assetData or not assetData.content then
            validation.valid = false
            validation.error = "Asset data is missing or corrupted"
        end
    elseif validationLevel == "full" then
        -- Full validation - check integrity, checksums, etc.
        if not assetData or not assetData.content then
            validation.valid = false
            validation.error = "Asset data is missing or corrupted"
        elseif not assetData.metadata or not assetData.metadata.integrity then
            validation.valid = false
            validation.error = "Asset integrity information missing"
        end
    end
    
    return validation
end

-- ========================================
-- DATA INTEGRITY
-- ========================================

function AssetBackupSystem.initializeDataIntegrity()
    BackupState.integrityMonitor = {
        checksums = {},
        verifications = {},
        corruptions = {},
        repairs = {}
    }
    
    -- Start integrity monitoring
    AssetBackupSystem.startIntegrityMonitoring()
    
    print("🔐 Data integrity monitoring initialized")
end

function AssetBackupSystem.startIntegrityMonitoring()
    spawn(function()
        while true do
            if BACKUP_CONFIG.monitoring.enableIntegrityChecks then
                AssetBackupSystem.performIntegrityChecks()
            end
            
            task.wait(BACKUP_CONFIG.monitoring.checkInterval)
        end
    end)
end

function AssetBackupSystem.performIntegrityChecks()
    local corruptedBackups = {}
    
    for backupId, backup in pairs(BackupState.backupHistory) do
        if backup.status == "completed" then
            local integrity = AssetBackupSystem.verifyBackupIntegrity(backup)
            
            if not integrity.valid then
                table.insert(corruptedBackups, {
                    backupId = backupId,
                    corruption = integrity.corruption
                })
            end
        end
    end
    
    -- Handle corrupted backups
    for _, corruption in ipairs(corruptedBackups) do
        AssetBackupSystem.handleCorruption(corruption)
    end
    
    -- Update integrity statistics
    local totalBackups = 0
    local corruptedCount = #corruptedBackups
    
    for _ in pairs(BackupState.backupHistory) do
        totalBackups = totalBackups + 1
    end
    
    BackupState.stats.dataIntegrityRate = totalBackups > 0 and 
        ((totalBackups - corruptedCount) / totalBackups) * 100 or 100
end

function AssetBackupSystem.verifyBackupIntegrity(backup)
    -- Simulate integrity verification
    local corruption = math.random() < 0.01 -- 1% chance of corruption
    
    return {
        valid = not corruption,
        corruption = corruption and {
            type = "checksum_mismatch",
            severity = "medium",
            location = "storage"
        } or nil
    }
end

function AssetBackupSystem.handleCorruption(corruption)
    print(string.format("🚨 Corruption detected in backup %s", corruption.backupId))
    
    -- Record corruption
    table.insert(BackupState.integrityMonitor.corruptions, {
        backupId = corruption.backupId,
        corruption = corruption.corruption,
        timestamp = tick(),
        handled = false
    })
    
    -- Attempt repair from other locations
    local repaired = AssetBackupSystem.attemptRepair(corruption.backupId)
    
    if repaired then
        print(string.format("✅ Successfully repaired backup %s", corruption.backupId))
    else
        print(string.format("❌ Failed to repair backup %s", corruption.backupId))
    end
end

function AssetBackupSystem.attemptRepair(backupId)
    -- Simulate repair attempt from redundant copies
    return math.random() > 0.3 -- 70% success rate
end

-- ========================================
-- SCHEDULING AND AUTOMATION
-- ========================================

function AssetBackupSystem.startBackupScheduling()
    spawn(function()
        while true do
            AssetBackupSystem.executeScheduledBackups()
            AssetBackupSystem.performMaintenanceTasks()
            
            task.wait(60) -- Check every minute
        end
    end)
    
    print("⏰ Backup scheduling started")
end

function AssetBackupSystem.executeScheduledBackups()
    local scheduler = BackupState.backupEngine.scheduler
    local currentTime = tick()
    
    -- Check for jobs ready to execute
    local readyJobs = {}
    for i, job in ipairs(scheduler.queue) do
        if job.status == "scheduled" and AssetBackupSystem.isJobReady(job, currentTime) then
            table.insert(readyJobs, i)
        end
    end
    
    -- Execute ready jobs
    for i = #readyJobs, 1, -1 do -- Reverse order to maintain indices
        local jobIndex = readyJobs[i]
        local job = table.remove(scheduler.queue, jobIndex)
        BackupState.backupEngine.executor:execute(job)
    end
end

function AssetBackupSystem.isJobReady(job, currentTime)
    -- Simple scheduling logic - execute immediately for demo
    return true
end

function AssetBackupSystem.performMaintenanceTasks()
    -- Clean up old job records
    AssetBackupSystem.cleanupOldRecords()
    
    -- Update performance metrics
    AssetBackupSystem.updatePerformanceMetrics()
    
    -- Check alerts
    AssetBackupSystem.checkAlerts()
end

function AssetBackupSystem.cleanupOldRecords()
    local cutoffTime = tick() - (30 * 86400) -- 30 days
    
    -- Clean backup history
    for backupId, backup in pairs(BackupState.backupHistory) do
        if backup.timestamp < cutoffTime then
            BackupState.backupHistory[backupId] = nil
        end
    end
    
    -- Clean recovery history
    for recoveryId, recovery in pairs(BackupState.recoveryHistory) do
        if recovery.timestamp < cutoffTime then
            BackupState.recoveryHistory[recoveryId] = nil
        end
    end
end

function AssetBackupSystem.updatePerformanceMetrics()
    -- Update average backup time
    local totalTime = 0
    local completedBackups = 0
    
    for _, backup in pairs(BackupState.backupHistory) do
        if backup.status == "completed" and backup.progress.duration then
            totalTime = totalTime + backup.progress.duration
            completedBackups = completedBackups + 1
        end
    end
    
    BackupState.stats.averageBackupTime = completedBackups > 0 and (totalTime / completedBackups) or 0
    
    -- Update average recovery time
    totalTime = 0
    local completedRecoveries = 0
    
    for _, recovery in pairs(BackupState.recoveryHistory) do
        if recovery.status == "completed" and recovery.progress.duration then
            totalTime = totalTime + recovery.progress.duration
            completedRecoveries = completedRecoveries + 1
        end
    end
    
    BackupState.stats.averageRecoveryTime = completedRecoveries > 0 and (totalTime / completedRecoveries) or 0
end

function AssetBackupSystem.checkAlerts()
    local thresholds = BACKUP_CONFIG.monitoring.alertThresholds
    
    -- Check failure rate
    local totalJobs = BackupState.stats.successfulBackups + BackupState.stats.failedBackups
    if totalJobs > 0 then
        local failureRate = BackupState.stats.failedBackups / totalJobs
        if failureRate > thresholds.failureRate then
            AssetBackupSystem.createAlert("high_failure_rate", {
                rate = failureRate,
                threshold = thresholds.failureRate
            })
        end
    end
    
    -- Check data integrity
    if BackupState.stats.dataIntegrityRate < (100 - thresholds.corruptionRate * 100) then
        AssetBackupSystem.createAlert("data_integrity_concern", {
            rate = BackupState.stats.dataIntegrityRate,
            threshold = 100 - thresholds.corruptionRate * 100
        })
    end
end

function AssetBackupSystem.createAlert(type, data)
    local alert = {
        id = HttpService:GenerateGUID(false),
        type = type,
        data = data,
        timestamp = tick(),
        severity = "warning"
    }
    
    table.insert(BackupState.alerts, alert)
    
    print(string.format("🚨 Alert: %s", type))
end

-- ========================================
-- UTILITY FUNCTIONS
-- ========================================

function AssetBackupSystem.estimateBackupSize(assetIds)
    return #assetIds * 1024 * 1024 -- Rough estimate: 1MB per asset
end

function AssetBackupSystem.findAvailableAssets(assetIds, targetTime)
    local available = {}
    
    for _, assetId in ipairs(assetIds) do
        for _, backup in pairs(BackupState.backupHistory) do
            if backup.timestamp <= targetTime then
                for _, backupAssetId in ipairs(backup.assetIds) do
                    if assetId == backupAssetId then
                        table.insert(available, assetId)
                        break
                    end
                end
            end
        end
    end
    
    return available
end

function AssetBackupSystem.compressData(data)
    -- Simulate compression
    return {
        compressed = true,
        algorithm = BACKUP_CONFIG.storage.compression.algorithm,
        data = data,
        originalSize = 1024,
        compressedSize = 512
    }
end

function AssetBackupSystem.decompressData(compressedData)
    -- Simulate decompression
    return compressedData.data
end

function AssetBackupSystem.encryptData(data)
    -- Simulate encryption
    return {
        encrypted = true,
        algorithm = BACKUP_CONFIG.storage.encryption.algorithm,
        data = data,
        keyId = HttpService:GenerateGUID(false)
    }
end

function AssetBackupSystem.decryptData(encryptedData)
    -- Simulate decryption
    return encryptedData.data
end

function AssetBackupSystem.updateBackupStatistics()
    -- Update total data backed up
    local totalData = 0
    for _, backup in pairs(BackupState.backupHistory) do
        if backup.status == "completed" then
            totalData = totalData + (backup.metadata.estimatedSize or 0)
        end
    end
    BackupState.stats.totalDataBacked = totalData
end

function AssetBackupSystem.updateRecoveryStatistics()
    -- Statistics are updated when recoveries complete
end

-- ========================================
-- PUBLIC API
-- ========================================

function AssetBackupSystem.runBackupDemo()
    print("💾 Running asset backup demonstration...")
    
    -- Create sample backups
    local sampleAssets = {
        {"ui_background", "character_model", "ambient_music"},
        {"particle_effect", "sound_effect"},
        {"texture_pack", "animation_set", "script_module"}
    }
    
    local strategies = {"full", "incremental", "snapshot"}
    
    print("  💾 Creating backup jobs...")
    
    local backupJobs = {}
    for i, assets in ipairs(sampleAssets) do
        local strategy = strategies[i]
        local backupId = AssetBackupSystem.createBackup(assets, strategy)
        table.insert(backupJobs, backupId)
        print(string.format("    Created %s backup: %s (%d assets)", strategy, backupId, #assets))
    end
    
    -- Wait for backups to complete
    task.wait(3)
    
    -- Test recovery
    print("  🔄 Testing asset recovery...")
    
    local recoveryAssets = {"ui_background", "character_model"}
    local recovery = AssetBackupSystem.recoverAssets(recoveryAssets, {
        targetTime = tick(),
        validation = "full"
    })
    
    task.wait(2)
    
    -- Show storage usage
    print("  🗄️ Storage Usage:")
    for locationName, usage in pairs(BackupState.storageUsage) do
        print(string.format("    %s: %.1fMB / %.1fGB (%.1f%%)", 
            locationName,
            usage.used / (1024 * 1024),
            usage.capacity / (1024 * 1024 * 1024),
            usage.usagePercentage))
    end
    
    -- Perform integrity check
    print("  🔐 Performing integrity check...")
    AssetBackupSystem.performIntegrityChecks()
    
    -- Show backup statistics
    local stats = AssetBackupSystem.getBackupStats()
    print("  📊 Backup Statistics:")
    print(string.format("    Total backups: %d", stats.totalBackups))
    print(string.format("    Successful backups: %d", stats.successfulBackups))
    print(string.format("    Failed backups: %d", stats.failedBackups))
    print(string.format("    Total data backed up: %.1fMB", stats.totalDataBacked / (1024 * 1024)))
    print(string.format("    Total recoveries: %d", stats.totalRecoveries))
    print(string.format("    Average backup time: %.2fs", stats.averageBackupTime))
    print(string.format("    Average recovery time: %.2fs", stats.averageRecoveryTime))
    print(string.format("    Data integrity rate: %.1f%%", stats.dataIntegrityRate))
    
    -- Show alerts if any
    if #BackupState.alerts > 0 then
        print("  🚨 Active Alerts:")
        for _, alert in ipairs(BackupState.alerts) do
            print(string.format("    %s: %s", alert.type, alert.severity))
        end
    end
    
    print("💾 Asset backup demonstration completed")
end

function AssetBackupSystem.getBackupStats()
    return BackupState.stats
end

function AssetBackupSystem.getBackupJobs()
    return BackupState.backupJobs
end

function AssetBackupSystem.getBackupHistory()
    return BackupState.backupHistory
end

function AssetBackupSystem.getRecoveryHistory()
    return BackupState.recoveryHistory
end

function AssetBackupSystem.getStorageUsage()
    return BackupState.storageUsage
end

function AssetBackupSystem.getAlerts()
    return BackupState.alerts
end

-- Export API
AssetBackupSystem.createBackup = AssetBackupSystem.createBackup
AssetBackupSystem.recoverAssets = AssetBackupSystem.recoverAssets
AssetBackupSystem.performIntegrityChecks = AssetBackupSystem.performIntegrityChecks

-- Initialize the asset backup system
AssetBackupSystem.initialize()

print("💾 AssetBackupSystem loaded with comprehensive backup and recovery capabilities")

return AssetBackupSystem
