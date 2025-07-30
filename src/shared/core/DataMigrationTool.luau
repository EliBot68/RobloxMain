-- DataMigrationTool.luau
-- Schema migration and data transformation utilities
-- Handles version upgrades and data structure changes

local DataStoreService = game:GetService("DataStoreService")
local HttpService = game:GetService("HttpService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local SafeRequire = require(ReplicatedStorage.Shared.utils.SafeRequire)
local ServiceArchitecture = SafeRequire.require(ReplicatedStorage.Shared.core.ServiceArchitecture)

local DataMigrationTool = {}
DataMigrationTool.__index = DataMigrationTool

-- Implement IMigrationTool interface
setmetatable(DataMigrationTool, {__index = ServiceArchitecture.IMigrationTool})

-- ========================================
-- MIGRATION CONFIGURATION
-- ========================================

local MIGRATION_CONFIG = {
    batchSize = 10,
    maxRetries = 3,
    retryDelay = 1,
    backupBeforeMigration = true,
    validateAfterMigration = true,
    dryRunMode = false
}

local SCHEMA_VERSIONS = {
    "1.0.0", -- Initial version
    "1.1.0", -- Added achievements system
    "1.2.0", -- Added quest system
    "1.3.0", -- Added pet system
    "2.0.0", -- Major restructure
    "2.1.0"  -- Current version
}

local CURRENT_SCHEMA_VERSION = "2.1.0"

-- ========================================
-- CORE MIGRATION TOOL
-- ========================================

function DataMigrationTool.new()
    local self = setmetatable({}, DataMigrationTool)
    
    -- Migration state
    self.migrations = {}
    self.migrationHistory = {}
    self.currentMigrations = {}
    
    -- Statistics
    self.stats = {
        migrationsRun = 0,
        recordsMigrated = 0,
        migrationFailures = 0,
        rollbacks = 0,
        validationFailures = 0
    }
    
    -- Initialize migration definitions
    self:RegisterMigrations()
    
    print("🔄 DataMigrationTool initialized with schema versioning")
    return self
end

-- ========================================
-- MIGRATION REGISTRATION
-- ========================================

function DataMigrationTool:RegisterMigrations()
    -- Migration from 1.0.0 to 1.1.0: Add achievements
    self:RegisterMigration("1.0.0", "1.1.0", function(data)
        if not data.achievements then
            data.achievements = {}
        end
        return data
    end, "Add achievements system")
    
    -- Migration from 1.1.0 to 1.2.0: Add quest system
    self:RegisterMigration("1.1.0", "1.2.0", function(data)
        if not data.quests then
            data.quests = {
                active = {},
                completed = {},
                daily = {
                    lastReset = 0,
                    streak = 0,
                    completed = {}
                }
            }
        end
        return data
    end, "Add quest system")
    
    -- Migration from 1.2.0 to 1.3.0: Add pet system
    self:RegisterMigration("1.2.0", "1.3.0", function(data)
        if not data.pets then
            data.pets = {
                active = nil,
                owned = {}
            }
        end
        return data
    end, "Add pet system")
    
    -- Migration from 1.3.0 to 2.0.0: Major restructure
    self:RegisterMigration("1.3.0", "2.0.0", function(data)
        -- Restructure cosmetics
        if data.cosmetics and not data.cosmetics.equipped then
            local oldCosmetics = data.cosmetics
            data.cosmetics = {
                equipped = {},
                owned = {}
            }
            
            -- Migrate owned items
            for _, item in ipairs(oldCosmetics) do
                table.insert(data.cosmetics.owned, item)
            end
        end
        
        -- Add statistics
        if not data.statistics then
            data.statistics = {
                gamesPlayed = 0,
                totalScore = data.highScore or 0,
                coinsEarned = data.coins or 0,
                timePlayed = 0,
                achievements = 0
            }
        end
        
        -- Add joinDate if missing
        if not data.joinDate then
            data.joinDate = os.time()
        end
        
        return data
    end, "Major data structure overhaul")
    
    -- Migration from 2.0.0 to 2.1.0: Add buff system
    self:RegisterMigration("2.0.0", "2.1.0", function(data)
        if not data.buffs then
            data.buffs = {}
        end
        
        -- Add playTime tracking
        if not data.playTime then
            data.playTime = 0
        end
        
        -- Enhance settings
        if data.settings then
            if data.settings.controls == nil then
                data.settings.controls = "Default"
            end
            if data.settings.autoRun == nil then
                data.settings.autoRun = false
            end
            if data.settings.showHints == nil then
                data.settings.showHints = true
            end
        end
        
        return data
    end, "Add buff system and enhanced settings")
    
    print("📋 Registered " .. self:CountMigrations() .. " data migrations")
end

function DataMigrationTool:RegisterMigration(fromVersion, toVersion, migrationFunction, description)
    local migrationId = fromVersion .. "_to_" .. toVersion
    
    self.migrations[migrationId] = {
        fromVersion = fromVersion,
        toVersion = toVersion,
        migrationFunction = migrationFunction,
        description = description or "No description",
        registeredAt = os.time()
    }
    
    print("📝 Registered migration: " .. fromVersion .. " → " .. toVersion .. " (" .. (description or "No description") .. ")")
end

-- ========================================
-- MIGRATION EXECUTION
-- ========================================

function DataMigrationTool:MigratePlayerData(playerId, currentData, targetVersion)
    targetVersion = targetVersion or CURRENT_SCHEMA_VERSION
    
    local migrationId = self:GenerateMigrationId(playerId)
    
    self.currentMigrations[migrationId] = {
        playerId = playerId,
        startVersion = self:GetDataVersion(currentData),
        targetVersion = targetVersion,
        startTime = os.time(),
        status = "running"
    }
    
    print("🔄 Starting migration for player " .. playerId .. " (target: " .. targetVersion .. ")")
    
    local success, result = pcall(function()
        return self:ExecuteMigrationChain(currentData, targetVersion, migrationId)
    end)
    
    self.currentMigrations[migrationId] = nil
    
    if success then
        self.stats.migrationsRun = self.stats.migrationsRun + 1
        self.stats.recordsMigrated = self.stats.recordsMigrated + 1
        
        self:LogMigration(playerId, "migration_success", {
            migrationId = migrationId,
            fromVersion = self:GetDataVersion(currentData),
            toVersion = targetVersion,
            duration = os.time() - self.currentMigrations[migrationId].startTime
        })
        
        print("✅ Migration completed for player " .. playerId)
        return result
    else
        self.stats.migrationFailures = self.stats.migrationFailures + 1
        
        self:LogMigration(playerId, "migration_failure", {
            migrationId = migrationId,
            error = tostring(result),
            fromVersion = self:GetDataVersion(currentData),
            targetVersion = targetVersion
        })
        
        warn("❌ Migration failed for player " .. playerId .. ": " .. tostring(result))
        return nil
    end
end

function DataMigrationTool:ExecuteMigrationChain(data, targetVersion, migrationId)
    local currentVersion = self:GetDataVersion(data)
    local migratedData = self:DeepCopy(data)
    
    -- Find migration path
    local migrationPath = self:FindMigrationPath(currentVersion, targetVersion)
    
    if not migrationPath then
        error("❌ No migration path found from " .. currentVersion .. " to " .. targetVersion)
    end
    
    print("📍 Migration path: " .. table.concat(migrationPath, " → "))
    
    -- Execute each migration in the chain
    for i = 1, #migrationPath - 1 do
        local fromVersion = migrationPath[i]
        local toVersion = migrationPath[i + 1]
        local migrationKey = fromVersion .. "_to_" .. toVersion
        
        local migration = self.migrations[migrationKey]
        if not migration then
            error("❌ Missing migration: " .. migrationKey)
        end
        
        print("🔧 Applying migration: " .. fromVersion .. " → " .. toVersion)
        
        -- Create backup before migration if enabled
        if MIGRATION_CONFIG.backupBeforeMigration then
            self:CreateMigrationBackup(migrationId, migratedData, fromVersion)
        end
        
        -- Apply the migration
        local success, newData = pcall(migration.migrationFunction, migratedData)
        
        if not success then
            error("❌ Migration function failed (" .. migrationKey .. "): " .. tostring(newData))
        end
        
        migratedData = newData
        
        -- Update version in the data
        self:SetDataVersion(migratedData, toVersion)
        
        -- Validate migrated data if enabled
        if MIGRATION_CONFIG.validateAfterMigration then
            local validationResult = self:ValidateMigratedData(migratedData, toVersion)
            if not validationResult.isValid then
                self.stats.validationFailures = self.stats.validationFailures + 1
                error("❌ Validation failed after migration to " .. toVersion .. ": " .. 
                      table.concat(validationResult.errors, ", "))
            end
        end
        
        print("✅ Migration step completed: " .. fromVersion .. " → " .. toVersion)
    end
    
    -- Final version check
    local finalVersion = self:GetDataVersion(migratedData)
    if finalVersion ~= targetVersion then
        warn("⚠️ Final version mismatch: expected " .. targetVersion .. ", got " .. finalVersion)
    end
    
    return migratedData
end

-- ========================================
-- MIGRATION PATH FINDING
-- ========================================

function DataMigrationTool:FindMigrationPath(fromVersion, toVersion)
    if fromVersion == toVersion then
        return {fromVersion}
    end
    
    -- Simple linear path through SCHEMA_VERSIONS
    local fromIndex = self:FindVersionIndex(fromVersion)
    local toIndex = self:FindVersionIndex(toVersion)
    
    if not fromIndex or not toIndex then
        warn("❌ Unknown version in migration path")
        return nil
    end
    
    if fromIndex > toIndex then
        warn("❌ Downgrade migrations not supported")
        return nil
    end
    
    local path = {}
    for i = fromIndex, toIndex do
        table.insert(path, SCHEMA_VERSIONS[i])
    end
    
    return path
end

function DataMigrationTool:FindVersionIndex(version)
    for i, v in ipairs(SCHEMA_VERSIONS) do
        if v == version then
            return i
        end
    end
    return nil
end

-- ========================================
-- BATCH MIGRATION
-- ========================================

function DataMigrationTool:MigrateBatch(playerIds, targetVersion)
    targetVersion = targetVersion or CURRENT_SCHEMA_VERSION
    
    local batchId = self:GenerateBatchId()
    local results = {
        batchId = batchId,
        totalPlayers = #playerIds,
        successful = 0,
        failed = 0,
        errors = {},
        startTime = os.time()
    }
    
    print("🔄 Starting batch migration for " .. #playerIds .. " players")
    
    -- Process in smaller batches
    local batchSize = MIGRATION_CONFIG.batchSize
    
    for i = 1, #playerIds, batchSize do
        local endIndex = math.min(i + batchSize - 1, #playerIds)
        local batch = {}
        
        for j = i, endIndex do
            table.insert(batch, playerIds[j])
        end
        
        print("📦 Processing batch " .. math.ceil(i / batchSize) .. "/" .. 
              math.ceil(#playerIds / batchSize) .. " (" .. #batch .. " players)")
        
        self:ProcessMigrationBatch(batch, targetVersion, results)
        
        -- Small delay between batches to avoid rate limits
        task.wait(0.1)
    end
    
    results.endTime = os.time()
    results.duration = results.endTime - results.startTime
    
    print("✅ Batch migration completed: " .. results.successful .. "/" .. results.totalPlayers .. 
          " successful (" .. results.duration .. "s)")
    
    return results
end

function DataMigrationTool:ProcessMigrationBatch(playerIds, targetVersion, results)
    for _, playerId in ipairs(playerIds) do
        local success, result = pcall(function()
            -- Load player data
            local dataStore = DataStoreService:GetDataStore("PlayerDataV3")
            local currentData = dataStore:GetAsync(tostring(playerId))
            
            if not currentData then
                error("No data found for player " .. playerId)
            end
            
            -- Check if migration is needed
            local currentVersion = self:GetDataVersion(currentData)
            if currentVersion == targetVersion then
                return "No migration needed"
            end
            
            -- Perform migration
            local migratedData = self:MigratePlayerData(playerId, currentData, targetVersion)
            
            if not migratedData then
                error("Migration returned nil data")
            end
            
            -- Save migrated data (in dry run mode, skip saving)
            if not MIGRATION_CONFIG.dryRunMode then
                dataStore:SetAsync(tostring(playerId), migratedData)
            end
            
            return "Migrated from " .. currentVersion .. " to " .. targetVersion
        end)
        
        if success then
            results.successful = results.successful + 1
            print("✅ Migrated player " .. playerId .. ": " .. result)
        else
            results.failed = results.failed + 1
            table.insert(results.errors, {
                playerId = playerId,
                error = tostring(result)
            })
            warn("❌ Failed to migrate player " .. playerId .. ": " .. tostring(result))
        end
    end
end

-- ========================================
-- ROLLBACK FUNCTIONALITY
-- ========================================

function DataMigrationTool:RollbackMigration(playerId, migrationId)
    local backupData = self:GetMigrationBackup(migrationId)
    
    if not backupData then
        warn("❌ No backup found for migration " .. migrationId)
        return false
    end
    
    local success = pcall(function()
        local dataStore = DataStoreService:GetDataStore("PlayerDataV3")
        dataStore:SetAsync(tostring(playerId), backupData.originalData)
    end)
    
    if success then
        self.stats.rollbacks = self.stats.rollbacks + 1
        
        self:LogMigration(playerId, "rollback_success", {
            migrationId = migrationId,
            rolledBackTo = self:GetDataVersion(backupData.originalData)
        })
        
        print("🔄 Rollback completed for player " .. playerId .. " (migration: " .. migrationId .. ")")
        return true
    else
        self:LogMigration(playerId, "rollback_failure", {
            migrationId = migrationId,
            error = "Failed to write rollback data"
        })
        
        warn("❌ Rollback failed for player " .. playerId)
        return false
    end
end

-- ========================================
-- BACKUP MANAGEMENT
-- ========================================

function DataMigrationTool:CreateMigrationBackup(migrationId, data, version)
    local backupData = {
        migrationId = migrationId,
        originalData = self:DeepCopy(data),
        originalVersion = version,
        timestamp = os.time(),
        serverId = game.JobId
    }
    
    local backupStore = DataStoreService:GetDataStore("MigrationBackupsV3")
    local success = pcall(function()
        backupStore:SetAsync(migrationId .. "_backup", backupData)
    end)
    
    if success then
        print("💾 Migration backup created: " .. migrationId)
        return true
    else
        warn("⚠️ Failed to create migration backup: " .. migrationId)
        return false
    end
end

function DataMigrationTool:GetMigrationBackup(migrationId)
    local backupStore = DataStoreService:GetDataStore("MigrationBackupsV3")
    
    local success, backupData = pcall(function()
        return backupStore:GetAsync(migrationId .. "_backup")
    end)
    
    return success and backupData or nil
end

-- ========================================
-- VERSION MANAGEMENT
-- ========================================

function DataMigrationTool:GetDataVersion(data)
    if type(data) == "table" then
        return data.schemaVersion or data.version or "1.0.0"
    end
    return "1.0.0"
end

function DataMigrationTool:SetDataVersion(data, version)
    if type(data) == "table" then
        data.schemaVersion = version
        data.lastMigration = os.time()
    end
end

function DataMigrationTool:IsVersionUpToDate(data)
    local currentVersion = self:GetDataVersion(data)
    return currentVersion == CURRENT_SCHEMA_VERSION
end

function DataMigrationTool:GetLatestVersion()
    return CURRENT_SCHEMA_VERSION
end

-- ========================================
-- VALIDATION
-- ========================================

function DataMigrationTool:ValidateMigratedData(data, expectedVersion)
    local result = {
        isValid = true,
        errors = {},
        warnings = {}
    }
    
    -- Check version
    local actualVersion = self:GetDataVersion(data)
    if actualVersion ~= expectedVersion then
        table.insert(result.errors, "Version mismatch: expected " .. expectedVersion .. ", got " .. actualVersion)
        result.isValid = false
    end
    
    -- Basic structure validation
    if type(data) ~= "table" then
        table.insert(result.errors, "Data must be a table")
        result.isValid = false
        return result
    end
    
    -- Required fields based on version
    local requiredFields = self:GetRequiredFieldsForVersion(expectedVersion)
    for _, field in ipairs(requiredFields) do
        if data[field] == nil then
            table.insert(result.errors, "Missing required field for version " .. expectedVersion .. ": " .. field)
            result.isValid = false
        end
    end
    
    return result
end

function DataMigrationTool:GetRequiredFieldsForVersion(version)
    local baseFields = {"coins", "level", "experience", "highScore", "lastPlayed"}
    
    if self:CompareVersions(version, "1.1.0") >= 0 then
        table.insert(baseFields, "achievements")
    end
    
    if self:CompareVersions(version, "1.2.0") >= 0 then
        table.insert(baseFields, "quests")
    end
    
    if self:CompareVersions(version, "1.3.0") >= 0 then
        table.insert(baseFields, "pets")
    end
    
    if self:CompareVersions(version, "2.0.0") >= 0 then
        table.insert(baseFields, "statistics")
        table.insert(baseFields, "joinDate")
    end
    
    if self:CompareVersions(version, "2.1.0") >= 0 then
        table.insert(baseFields, "buffs")
        table.insert(baseFields, "playTime")
    end
    
    return baseFields
end

function DataMigrationTool:CompareVersions(version1, version2)
    local function parseVersion(v)
        local parts = {}
        for part in string.gmatch(v, "%d+") do
            table.insert(parts, tonumber(part))
        end
        return parts
    end
    
    local v1 = parseVersion(version1)
    local v2 = parseVersion(version2)
    
    for i = 1, math.max(#v1, #v2) do
        local p1 = v1[i] or 0
        local p2 = v2[i] or 0
        
        if p1 > p2 then
            return 1
        elseif p1 < p2 then
            return -1
        end
    end
    
    return 0
end

-- ========================================
-- UTILITY FUNCTIONS
-- ========================================

function DataMigrationTool:DeepCopy(original)
    if type(original) ~= "table" then
        return original
    end
    
    local copy = {}
    for key, value in pairs(original) do
        copy[key] = self:DeepCopy(value)
    end
    
    return copy
end

function DataMigrationTool:GenerateMigrationId(playerId)
    return "migration_" .. playerId .. "_" .. os.time() .. "_" .. math.random(1000, 9999)
end

function DataMigrationTool:GenerateBatchId()
    return "batch_" .. os.time() .. "_" .. math.random(1000, 9999)
end

function DataMigrationTool:LogMigration(playerId, eventType, eventData)
    local logEntry = {
        playerId = playerId,
        eventType = eventType,
        eventData = eventData,
        timestamp = os.time(),
        serverId = game.JobId
    }
    
    local logStore = DataStoreService:GetDataStore("MigrationLogV3")
    local logKey = "migration_log_" .. playerId .. "_" .. os.time() .. "_" .. math.random(1000, 9999)
    
    pcall(function()
        logStore:SetAsync(logKey, logEntry)
    end)
end

function DataMigrationTool:CountMigrations()
    local count = 0
    for _ in pairs(self.migrations) do
        count = count + 1
    end
    return count
end

function DataMigrationTool:GetStatistics()
    return {
        stats = self.stats,
        availableMigrations = self:CountMigrations(),
        currentVersion = CURRENT_SCHEMA_VERSION,
        supportedVersions = SCHEMA_VERSIONS,
        activeMigrations = self:CountActiveMigrations(),
        config = MIGRATION_CONFIG
    }
end

function DataMigrationTool:CountActiveMigrations()
    local count = 0
    for _ in pairs(self.currentMigrations) do
        count = count + 1
    end
    return count
end

return DataMigrationTool
