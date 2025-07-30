-- Enhanced DataService.luau
-- Updated to integrate with new data persistence and state management systems
-- Provides comprehensive data layer with transaction support, caching, and integrity

local DataStoreService = game:GetService("DataStoreService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local SafeRequire = require(ReplicatedStorage.Shared.utils.SafeRequire)
local RemoteEvents = SafeRequire.require(ReplicatedStorage.Shared.RemoteEvents)
local ServiceArchitecture = SafeRequire.require(ReplicatedStorage.Shared.core.ServiceArchitecture)

-- Import new data management systems
local DataAccessLayer = SafeRequire.require(ReplicatedStorage.Shared.core.DataAccessLayer)
local DataValidator = SafeRequire.require(ReplicatedStorage.Shared.core.DataValidator)
local BackupManager = SafeRequire.require(ReplicatedStorage.Shared.core.BackupManager)
local DataMigrationTool = SafeRequire.require(ReplicatedStorage.Shared.core.DataMigrationTool)
local CacheManager = SafeRequire.require(ReplicatedStorage.Shared.core.CacheManager)
local AuditLogger = SafeRequire.require(ReplicatedStorage.Shared.core.AuditLogger)
local ConsistencyChecker = SafeRequire.require(ReplicatedStorage.Shared.core.ConsistencyChecker)

local DataService = {}
DataService.__index = DataService

-- Implement IDataService interface
setmetatable(DataService, {__index = ServiceArchitecture.IDataService})

-- ========================================
-- SERVICE CONFIGURATION
-- ========================================

local SERVICE_CONFIG = {
    enableTransactions = true,
    enableCaching = true,
    enableBackups = true,
    enableAuditing = true,
    enableConsistencyChecks = true,
    enableMigration = true,
    
    -- Performance settings
    batchOperations = true,
    maxConcurrentOperations = 10,
    operationTimeout = 30,
    
    -- Safety settings
    validateAllWrites = true,
    backupBeforeUpdates = true,
    checkConsistencyOnRead = false
}

-- ========================================
-- DEFAULT DATA STRUCTURE
-- ========================================

local DEFAULT_DATA = {
    -- Core player progression
    coins = 0,
    level = 1,
    experience = 0,
    highScore = 0,
    
    -- Upgrade system
    upgrades = {
        speed = 0,
        jump = 0,
        coins = 0,
        luck = 0,
        magnet = 0
    },
    
    -- Cosmetic system
    cosmetics = {
        equipped = {
            hat = nil,
            shirt = nil,
            pants = nil,
            accessory = nil
        },
        owned = {}
    },
    
    -- Settings
    settings = {
        music = true,
        sfx = true,
        graphics = "Medium",
        controls = "Default",
        autoRun = false,
        showHints = true
    },
    
    -- Achievement system
    achievements = {},
    
    -- Quest system
    quests = {
        active = {},
        completed = {},
        daily = {
            lastReset = 0,
            streak = 0,
            completed = {}
        }
    },
    
    -- Pet system
    pets = {
        active = nil,
        owned = {}
    },
    
    -- Buff system
    buffs = {},
    
    -- Metadata
    lastPlayed = 0,
    joinDate = 0,
    playTime = 0,
    
    -- Statistics
    statistics = {
        gamesPlayed = 0,
        totalScore = 0,
        coinsEarned = 0,
        timePlayed = 0,
        achievements = 0
    },
    
    -- Version info
    schemaVersion = "2.1.0",
    lastMigration = 0
}

-- ========================================
-- CORE DATA SERVICE
-- ========================================

function DataService.new()
    local self = setmetatable({}, DataService)
    
    -- Initialize data management systems
    self.dataLayer = DataAccessLayer.new()
    self.validator = DataValidator.new()
    self.backupManager = BackupManager.new()
    self.migrationTool = DataMigrationTool.new()
    self.cacheManager = CacheManager.new()
    self.auditLogger = AuditLogger.new()
    self.consistencyChecker = ConsistencyChecker.new()
    
    -- Service state
    self.playerDataCache = {}
    self.activeOperations = {}
    self.pendingOperations = {}
    
    -- Statistics
    self.stats = {
        reads = 0,
        writes = 0,
        cacheHits = 0,
        cacheMisses = 0,
        validationFailures = 0,
        migrationCount = 0,
        backupCount = 0,
        errors = 0
    }
    
    -- Connect to player events
    self:ConnectPlayerEvents()
    
    -- Set up remote events
    self:SetupRemoteEvents()
    
    print("🗄️ Enhanced DataService initialized with comprehensive data management")
    return self
end

-- ========================================
-- PLAYER LIFECYCLE MANAGEMENT
-- ========================================

function DataService:ConnectPlayerEvents()
    Players.PlayerAdded:Connect(function(player)
        self:HandlePlayerAdded(player)
    end)
    
    Players.PlayerRemoving:Connect(function(player)
        self:HandlePlayerRemoving(player)
    end)
    
    -- Handle server shutdown
    game:BindToClose(function()
        self:HandleServerShutdown()
    end)
end

function DataService:HandlePlayerAdded(player)
    local playerId = tostring(player.UserId)
    
    self.auditLogger:LogUserAction(player.UserId, "player_joined", {
        displayName = player.DisplayName,
        accountAge = player.AccountAge
    })
    
    task.spawn(function()
        local success, playerData = self:LoadPlayerData(playerId)
        
        if success and playerData then
            -- Cache the loaded data
            self.playerDataCache[playerId] = playerData
            
            -- Notify PlayerService
            RemoteEvents.DataLoaded:FireClient(player, playerData.data)
            
            print("✅ Loaded data for player " .. player.DisplayName .. " (" .. playerId .. ")")
        else
            warn("❌ Failed to load data for player " .. player.DisplayName)
            
            -- Load default data as fallback
            local defaultData = self:CreateDefaultData(playerId)
            self.playerDataCache[playerId] = defaultData
            RemoteEvents.DataLoaded:FireClient(player, defaultData.data)
        end
    end)
end

function DataService:HandlePlayerRemoving(player)
    local playerId = tostring(player.UserId)
    
    self.auditLogger:LogUserAction(player.UserId, "player_leaving", {
        displayName = player.DisplayName,
        sessionDuration = tick() - (player.leaderstats and player.leaderstats.SessionStart.Value or tick())
    })
    
    -- Save player data immediately
    task.spawn(function()
        local success = self:SavePlayerData(playerId)
        if success then
            print("✅ Saved data for departing player " .. player.DisplayName)
        else
            warn("❌ Failed to save data for departing player " .. player.DisplayName)
        end
        
        -- Clean up cache
        self.playerDataCache[playerId] = nil
    end)
end

function DataService:HandleServerShutdown()
    print("🔄 Server shutdown - saving all player data...")
    
    local savePromises = {}
    
    for playerId, _ in pairs(self.playerDataCache) do
        table.insert(savePromises, task.spawn(function()
            return self:SavePlayerData(playerId)
        end))
    end
    
    -- Wait for all saves to complete (with timeout)
    local timeout = tick() + 25 -- 25 second timeout
    local completed = 0
    
    while completed < #savePromises and tick() < timeout do
        completed = 0
        for _, promise in ipairs(savePromises) do
            if coroutine.status(promise) == "dead" then
                completed = completed + 1
            end
        end
        task.wait(0.1)
    end
    
    -- Flush any remaining audit logs
    self.auditLogger:FlushBuffer()
    
    print("✅ Server shutdown data save completed (" .. completed .. "/" .. #savePromises .. ")")
end

-- ========================================
-- DATA OPERATIONS
-- ========================================

function DataService:LoadPlayerData(playerId)
    local operationId = self:StartOperation("load", playerId)
    
    local success, result = pcall(function()
        -- Try cache first
        if SERVICE_CONFIG.enableCaching then
            local cachedData = self.cacheManager:Get("player_" .. playerId)
            if cachedData then
                self.stats.cacheHits = self.stats.cacheHits + 1
                self.auditLogger:LogDataChange(playerId, "READ", "cached_data", nil, cachedData)
                return cachedData
            end
            self.stats.cacheMisses = self.stats.cacheMisses + 1
        end
        
        -- Load from data layer
        local rawData = self.dataLayer:Read(playerId)
        
        if not rawData then
            -- No data found, create default
            local defaultData = self:CreateDefaultData(playerId)
            local createdData = self.dataLayer:Create({
                playerId = playerId,
                data = defaultData.data
            })
            
            self.auditLogger:LogDataChange(playerId, "CREATE", "new_player", nil, defaultData.data)
            return createdData
        end
        
        -- Check if migration is needed
        if SERVICE_CONFIG.enableMigration then
            if not self.migrationTool:IsVersionUpToDate(rawData) then
                print("🔄 Migrating data for player " .. playerId)
                
                local migratedData = self.migrationTool:MigratePlayerData(
                    playerId, 
                    rawData, 
                    self.migrationTool:GetLatestVersion()
                )
                
                if migratedData then
                    rawData = migratedData
                    self.stats.migrationCount = self.stats.migrationCount + 1
                end
            end
        end
        
        -- Validate data integrity
        if SERVICE_CONFIG.enableConsistencyChecks and SERVICE_CONFIG.checkConsistencyOnRead then
            local checkResult = self.consistencyChecker:CheckPlayerData(playerId, rawData.data)
            if #checkResult.issues > 0 then
                warn("⚠️ Data consistency issues found for player " .. playerId)
                -- The consistency checker would have attempted repairs
            end
        end
        
        -- Cache the data
        if SERVICE_CONFIG.enableCaching then
            self.cacheManager:Set("player_" .. playerId, rawData, 300, "L2", {"player_data"})
        end
        
        self.stats.reads = self.stats.reads + 1
        self.auditLogger:LogDataChange(playerId, "READ", "player_data", nil, rawData.data)
        
        return rawData
    end)
    
    self:EndOperation(operationId)
    
    if success then
        return true, result
    else
        self.stats.errors = self.stats.errors + 1
        self.auditLogger:LogError(result, {operation = "load", playerId = playerId})
        return false, nil
    end
end

function DataService:SavePlayerData(playerId, specificData)
    local operationId = self:StartOperation("save", playerId)
    
    local success, result = pcall(function()
        local dataToSave = specificData or self.playerDataCache[playerId]
        
        if not dataToSave then
            error("No data to save for player " .. playerId)
        end
        
        -- Update metadata
        dataToSave.data.lastPlayed = os.time()
        
        -- Validate before saving
        if SERVICE_CONFIG.validateAllWrites then
            local validationResult = self.validator:Validate(dataToSave.data)
            if not validationResult.isValid then
                self.stats.validationFailures = self.stats.validationFailures + 1
                error("Data validation failed: " .. table.concat(validationResult.errors, ", "))
            end
        end
        
        -- Create backup if enabled
        if SERVICE_CONFIG.enableBackups and SERVICE_CONFIG.backupBeforeUpdates then
            self.backupManager:CreatePreUpdateBackup(playerId, dataToSave, {
                operation = "save",
                timestamp = os.time()
            })
            self.stats.backupCount = self.stats.backupCount + 1
        end
        
        -- Save using data layer
        local savedData = self.dataLayer:Update(playerId, dataToSave.data, dataToSave.version)
        
        -- Update cache
        if SERVICE_CONFIG.enableCaching then
            self.cacheManager:Set("player_" .. playerId, savedData, 300, "L2", {"player_data"})
        end
        
        -- Update local cache
        self.playerDataCache[playerId] = savedData
        
        self.stats.writes = self.stats.writes + 1
        self.auditLogger:LogDataChange(playerId, "UPDATE", "player_data", dataToSave.data, savedData.data)
        
        return savedData
    end)
    
    self:EndOperation(operationId)
    
    if success then
        return true, result
    else
        self.stats.errors = self.stats.errors + 1
        self.auditLogger:LogError(result, {operation = "save", playerId = playerId})
        return false, nil
    end
end

function DataService:UpdatePlayerData(playerId, updates, context)
    local operationId = self:StartOperation("update", playerId)
    
    local success, result = pcall(function()
        local currentData = self.playerDataCache[playerId]
        if not currentData then
            error("Player data not loaded: " .. playerId)
        end
        
        -- Validate the update
        local validationResult = self.validator:ValidateUpdate(currentData.data, updates)
        if not validationResult.isValid then
            self.stats.validationFailures = self.stats.validationFailures + 1
            error("Update validation failed: " .. table.concat(validationResult.errors, ", "))
        end
        
        -- Apply updates to current data
        for key, value in pairs(updates) do
            currentData.data[key] = value
        end
        
        -- Save the updated data
        local saved, savedData = self:SavePlayerData(playerId, currentData)
        if not saved then
            error("Failed to save updated data")
        end
        
        self.auditLogger:LogDataChange(playerId, "UPDATE", "batch_update", nil, updates, context)
        
        return savedData
    end)
    
    self:EndOperation(operationId)
    
    if success then
        return true, result
    else
        self.stats.errors = self.stats.errors + 1
        self.auditLogger:LogError(result, {operation = "update", playerId = playerId, updates = updates})
        return false, nil
    end
end

function DataService:GetPlayerData(playerId, useCache)
    useCache = useCache ~= false -- Default to true
    
    if useCache and self.playerDataCache[playerId] then
        return self.playerDataCache[playerId]
    end
    
    local success, data = self:LoadPlayerData(playerId)
    return success and data or nil
end

function DataService:DeletePlayerData(playerId, reason)
    local operationId = self:StartOperation("delete", playerId)
    
    local success, result = pcall(function()
        -- Create final backup
        local currentData = self.playerDataCache[playerId]
        if currentData and SERVICE_CONFIG.enableBackups then
            self.backupManager:CreateBackup(playerId, currentData, "pre_deletion", {
                reason = reason or "Player data deletion",
                deletedBy = "DataService"
            })
        end
        
        -- Delete from data layer
        local deleted = self.dataLayer:Delete(playerId)
        
        -- Clear from cache
        if SERVICE_CONFIG.enableCaching then
            self.cacheManager:Delete("player_" .. playerId)
        end
        
        -- Clear local cache
        self.playerDataCache[playerId] = nil
        
        self.auditLogger:LogDataChange(playerId, "DELETE", "player_data", currentData and currentData.data, nil, {
            reason = reason
        })
        
        return deleted
    end)
    
    self:EndOperation(operationId)
    
    return success and result
end

-- ========================================
-- REMOTE EVENT HANDLERS
-- ========================================

function DataService:SetupRemoteEvents()
    -- Handle client data requests
    RemoteEvents.GetPlayerData.OnServerInvoke = function(player)
        local playerId = tostring(player.UserId)
        local playerData = self:GetPlayerData(playerId)
        
        if playerData then
            return {
                success = true,
                data = playerData.data,
                version = playerData.version
            }
        else
            return {
                success = false,
                error = "Failed to load player data"
            }
        end
    end
    
    -- Handle client data updates
    RemoteEvents.UpdatePlayerData.OnServerInvoke = function(player, updateData)
        local playerId = tostring(player.UserId)
        
        if not updateData or not updateData.updates then
            return {
                success = false,
                error = "Invalid update data"
            }
        end
        
        local success, result = self:UpdatePlayerData(
            playerId, 
            updateData.updates, 
            {
                clientVersion = updateData.clientVersion,
                expectedServerVersion = updateData.expectedServerVersion,
                source = "client_update"
            }
        )
        
        if success then
            return {
                success = true,
                newData = result.data,
                newVersion = result.version
            }
        else
            -- Check for version conflicts
            local currentData = self:GetPlayerData(playerId)
            if currentData and updateData.expectedServerVersion ~= currentData.version then
                return {
                    success = false,
                    conflict = true,
                    serverData = currentData,
                    clientUpdates = updateData.updates
                }
            else
                return {
                    success = false,
                    error = "Update failed"
                }
            end
        end
    end
end

-- ========================================
-- UTILITY FUNCTIONS
-- ========================================

function DataService:CreateDefaultData(playerId)
    local defaultData = {}
    
    -- Deep copy default structure
    for key, value in pairs(DEFAULT_DATA) do
        defaultData[key] = type(value) == "table" and self:DeepCopy(value) or value
    end
    
    -- Set initial timestamps
    defaultData.joinDate = os.time()
    defaultData.lastPlayed = os.time()
    
    return {
        data = defaultData,
        version = 1,
        createdAt = os.time(),
        lastModified = os.time(),
        checksum = "initial"
    }
end

function DataService:DeepCopy(original)
    if type(original) ~= "table" then
        return original
    end
    
    local copy = {}
    for key, value in pairs(original) do
        copy[key] = self:DeepCopy(value)
    end
    
    return copy
end

function DataService:StartOperation(operationType, playerId)
    local operationId = operationType .. "_" .. playerId .. "_" .. os.time() .. "_" .. math.random(1000, 9999)
    
    self.activeOperations[operationId] = {
        type = operationType,
        playerId = playerId,
        startTime = tick(),
        status = "running"
    }
    
    return operationId
end

function DataService:EndOperation(operationId)
    local operation = self.activeOperations[operationId]
    if operation then
        operation.endTime = tick()
        operation.duration = operation.endTime - operation.startTime
        operation.status = "completed"
        
        -- Move to completed operations (keep recent history)
        self.activeOperations[operationId] = nil
    end
end

-- ========================================
-- MANAGEMENT FUNCTIONS
-- ========================================

function DataService:RunConsistencyCheck(playerId)
    local playerData = self:GetPlayerData(playerId)
    if not playerData then
        return {
            success = false,
            error = "Player data not found"
        }
    end
    
    local checkResult = self.consistencyChecker:CheckPlayerData(playerId, playerData.data)
    
    return {
        success = true,
        checkId = checkResult.checkId,
        issues = checkResult.issues,
        repairs = checkResult.repairs,
        duration = checkResult.duration
    }
end

function DataService:CreateManualBackup(playerId, reason)
    local playerData = self:GetPlayerData(playerId)
    if not playerData then
        return nil
    end
    
    return self.backupManager:CreateBackup(playerId, playerData, "manual", {
        reason = reason,
        createdBy = "DataService"
    })
end

function DataService:RestoreFromBackup(playerId, backupId)
    return self.backupManager:RestoreFromBackup(playerId, backupId)
end

function DataService:InvalidateCache(playerId)
    if SERVICE_CONFIG.enableCaching then
        self.cacheManager:Delete("player_" .. playerId)
        return true
    end
    return false
end

function DataService:FlushAuditLogs()
    return self.auditLogger:FlushBuffer()
end

-- ========================================
-- STATISTICS AND MONITORING
-- ========================================

function DataService:GetStatistics()
    local activeOps = 0
    for _ in pairs(self.activeOperations) do
        activeOps = activeOps + 1
    end
    
    return {
        service = self.stats,
        dataLayer = self.dataLayer:GetStatistics(),
        cache = self.cacheManager:GetStatistics(),
        backup = self.backupManager:GetStatistics(),
        audit = self.auditLogger:GetStatistics(),
        consistency = self.consistencyChecker:GetStatistics(),
        migration = self.migrationTool:GetStatistics(),
        
        runtime = {
            activeOperations = activeOps,
            cachedPlayers = self:CountCachedPlayers(),
            uptime = tick() - (self.startTime or tick())
        }
    }
end

function DataService:CountCachedPlayers()
    local count = 0
    for _ in pairs(self.playerDataCache) do
        count = count + 1
    end
    return count
end

function DataService:GetHealthStatus()
    local stats = self:GetStatistics()
    local health = {
        status = "healthy",
        issues = {},
        score = 100
    }
    
    -- Check error rates
    local totalOps = stats.service.reads + stats.service.writes
    local errorRate = totalOps > 0 and (stats.service.errors / totalOps) or 0
    
    if errorRate > 0.05 then -- 5% error rate
        table.insert(health.issues, "High error rate: " .. math.floor(errorRate * 100) .. "%")
        health.score = health.score - 20
    end
    
    -- Check validation failures
    if stats.service.validationFailures > stats.service.writes * 0.1 then
        table.insert(health.issues, "High validation failure rate")
        health.score = health.score - 15
    end
    
    -- Check cache performance
    local cacheHitRate = (stats.service.cacheHits + stats.service.cacheMisses) > 0 and 
                        (stats.service.cacheHits / (stats.service.cacheHits + stats.service.cacheMisses)) or 0
    
    if cacheHitRate < 0.5 then -- Less than 50% cache hit rate
        table.insert(health.issues, "Low cache hit rate: " .. math.floor(cacheHitRate * 100) .. "%")
        health.score = health.score - 10
    end
    
    -- Determine overall status
    if health.score >= 80 then
        health.status = "healthy"
    elseif health.score >= 60 then
        health.status = "degraded"
    else
        health.status = "unhealthy"
    end
    
    return health
end

return DataService
