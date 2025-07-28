-- DataMigrationService.luau
-- Service to migrate data from old separate DataStores to the new unified system

local DataStoreService = game:GetService("DataStoreService")
local Players = game:GetService("Players")

local DataMigrationService = {}

-- References to old DataStores
local oldDataStores = {
    playerUpgrades = DataStoreService:GetDataStore("PlayerUpgrades"),
    dailyQuestProgress = DataStoreService:GetDataStore("DailyQuestProgress"),
    weeklyPuzzleProgress = DataStoreService:GetDataStore("WeeklyPuzzleProgress"),
    exclusiveCosmetics = DataStoreService:GetDataStore("ExclusiveCosmetics"),
    exclusiveSchedule = DataStoreService:GetDataStore("ExclusiveSchedule"),
    tournamentData = DataStoreService:GetDataStore("TournamentData_v1"),
    weeklyLeaderboard = DataStoreService:GetDataStore("WeeklyLeaderboard_v1"),
    weeklyRewards = DataStoreService:GetDataStore("WeeklyRewards_v1")
}

-- Migration tracking
local migrationStore = DataStoreService:GetDataStore("DataMigrationTracker")

function DataMigrationService:HasMigrated(userId)
    local success, migrated = pcall(function()
        return migrationStore:GetAsync(tostring(userId))
    end)
    
    return success and migrated == true
end

function DataMigrationService:MarkAsMigrated(userId)
    local success, error = pcall(function()
        migrationStore:SetAsync(tostring(userId), true)
    end)
    
    if not success then
        warn("❌ Failed to mark migration for user " .. userId .. ": " .. tostring(error))
    end
    
    return success
end

function DataMigrationService:MigratePlayerData(player, unifiedDataService)
    local userId = tostring(player.UserId)
    
    -- Check if already migrated
    if self:HasMigrated(userId) then
        print("✅ Data already migrated for " .. player.Name)
        return true
    end
    
    print("🔄 Starting data migration for " .. player.Name)
    
    -- Get current unified data
    local currentData = unifiedDataService:GetPlayerData(player)
    if not currentData then
        warn("❌ No unified data found for " .. player.Name)
        return false
    end
    
    local migrationSuccessful = true
    local migratedSections = {}
    
    -- Migrate upgrade data
    local upgradeSuccess, upgradeData = pcall(function()
        return oldDataStores.playerUpgrades:GetAsync(userId)
    end)
    
    if upgradeSuccess and upgradeData then
        -- Merge upgrade data
        if upgradeData.speed then
            currentData.upgrades.speed = math.max(currentData.upgrades.speed or 0, upgradeData.speed)
        end
        if upgradeData.coinMagnet then
            currentData.upgrades.coinMagnet = math.max(currentData.upgrades.coinMagnet or 0, upgradeData.coinMagnet)
        end
        if upgradeData.doubleCoins then
            currentData.upgrades.doubleCoins = math.max(currentData.upgrades.doubleCoins or 0, upgradeData.doubleCoins)
        end
        
        table.insert(migratedSections, "upgrades")
        print("📦 Migrated upgrade data for " .. player.Name)
    end
    
    -- Migrate quest data
    local questSuccess, questData = pcall(function()
        return oldDataStores.dailyQuestProgress:GetAsync(userId)
    end)
    
    if questSuccess and questData then
        -- Merge quest progress
        if questData.questProgress then
            for questId, progress in pairs(questData.questProgress) do
                currentData.questProgress[questId] = progress
            end
        end
        if questData.dailyQuests then
            currentData.dailyQuests = questData.dailyQuests
        end
        if questData.lastQuestReset then
            currentData.lastQuestReset = math.max(currentData.lastQuestReset or 0, questData.lastQuestReset)
        end
        
        table.insert(migratedSections, "quests")
        print("📦 Migrated quest data for " .. player.Name)
    end
    
    -- Migrate puzzle data
    local puzzleSuccess, puzzleData = pcall(function()
        return oldDataStores.weeklyPuzzleProgress:GetAsync(userId)
    end)
    
    if puzzleSuccess and puzzleData then
        -- Merge puzzle progress
        currentData.weeklyPuzzleData = puzzleData
        if puzzleData.completed then
            currentData.puzzlesCompleted = math.max(currentData.puzzlesCompleted or 0, puzzleData.completed)
        end
        
        table.insert(migratedSections, "puzzles")
        print("📦 Migrated puzzle data for " .. player.Name)
    end
    
    -- Migrate exclusive cosmetics
    local exclusiveSuccess, exclusiveData = pcall(function()
        return oldDataStores.exclusiveCosmetics:GetAsync(userId)
    end)
    
    if exclusiveSuccess and exclusiveData then
        currentData.exclusiveCosmetics = exclusiveData
        table.insert(migratedSections, "exclusives")
        print("📦 Migrated exclusive cosmetics for " .. player.Name)
    end
    
    -- Migrate tournament data
    local tournamentSuccess, tournamentData = pcall(function()
        return oldDataStores.tournamentData:GetAsync(userId)
    end)
    
    if tournamentSuccess and tournamentData then
        currentData.weeklyTournamentData = tournamentData
        table.insert(migratedSections, "tournament")
        print("📦 Migrated tournament data for " .. player.Name)
    end
    
    -- Migrate weekly leaderboard data
    local weeklySuccess, weeklyData = pcall(function()
        return oldDataStores.weeklyLeaderboard:GetAsync(userId)
    end)
    
    if weeklySuccess and weeklyData then
        currentData.weeklyStats = weeklyData
        table.insert(migratedSections, "weekly")
        print("📦 Migrated weekly data for " .. player.Name)
    end
    
    -- Save the migrated data
    local saveSuccess = unifiedDataService:SavePlayerData(player, currentData)
    if saveSuccess then
        self:MarkAsMigrated(userId)
        print("✅ Migration completed for " .. player.Name .. " (sections: " .. table.concat(migratedSections, ", ") .. ")")
        return true
    else
        warn("❌ Failed to save migrated data for " .. player.Name)
        return false
    end
end

function DataMigrationService:CleanupOldDataStores(player)
    local userId = tostring(player.UserId)
    
    -- Only cleanup if migration was successful
    if not self:HasMigrated(userId) then
        warn("⚠️ Skipping cleanup for " .. player.Name .. " - migration not completed")
        return false
    end
    
    print("🧹 Cleaning up old DataStore entries for " .. player.Name)
    
    local cleanupTasks = {
        function() oldDataStores.playerUpgrades:RemoveAsync(userId) end,
        function() oldDataStores.dailyQuestProgress:RemoveAsync(userId) end,
        function() oldDataStores.weeklyPuzzleProgress:RemoveAsync(userId) end,
        function() oldDataStores.exclusiveCosmetics:RemoveAsync(userId) end,
        function() oldDataStores.tournamentData:RemoveAsync(userId) end,
        function() oldDataStores.weeklyLeaderboard:RemoveAsync(userId) end,
        function() oldDataStores.weeklyRewards:RemoveAsync(userId) end
    }
    
    local cleanupCount = 0
    for i, cleanupTask in ipairs(cleanupTasks) do
        local success, error = pcall(cleanupTask)
        if success then
            cleanupCount = cleanupCount + 1
        else
            warn("❌ Cleanup task " .. i .. " failed for " .. player.Name .. ": " .. tostring(error))
        end
    end
    
    print("🧹 Cleaned up " .. cleanupCount .. "/" .. #cleanupTasks .. " old DataStore entries for " .. player.Name)
    return cleanupCount == #cleanupTasks
end

function DataMigrationService:Init()
    print("🔄 Data Migration Service initialized")
end

return DataMigrationService
