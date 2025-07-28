-- UnifiedDataService.luau
-- Enhanced unified data management system with backup saves, validation, and retry logic

local DataStoreService = game:GetService("DataStoreService")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local UnifiedDataService = {}

-- Primary and backup DataStores
local primaryDataStore = DataStoreService:GetDataStore("UnifiedPlayerData_v2")
local backupDataStore = DataStoreService:GetDataStore("UnifiedPlayerDataBackup_v2")

-- Leaderboard DataStores (OrderedDataStore for rankings)
local highScoreStore = DataStoreService:GetOrderedDataStore("GlobalHighScores_v2")
local totalCoinsStore = DataStoreService:GetOrderedDataStore("GlobalTotalCoins_v2")

-- Service state
local playerDataCache = {} -- In-memory cache for active players
local saveQueue = {} -- Queue for pending saves
local backupTimer = 0 -- Timer for backup saves
local isShuttingDown = false

-- Configuration
local BACKUP_INTERVAL = 300 -- 5 minutes in seconds
local MAX_SAVE_RETRIES = 5
local RETRY_DELAY_BASE = 2 -- Base delay for exponential backoff

-- Unified data schema - consolidates all previous separate schemas
local DEFAULT_DATA = {
    -- Core player stats
    coins = 0,
    level = 1,
    experience = 0,
    xpToNextLevel = 100,
    totalXpEarned = 0,
    highScore = 0,
    totalBarriersPassed = 0,
    gamesPlayed = 0,
    totalCoinsEarned = 0,
    currentColor = "RED",
    
    -- Settings
    settings = {
        music = true,
        sfx = true,
        particles = true,
        colorblindMode = false,
        controllerEnabled = true
    },
    
    -- Upgrade systems (consolidated from UpgradeService and EnhancedUpgradeService)
    upgrades = {
        speed = 0,
        coinMagnet = 0,
        doubleCoins = 0
    },
    enhancedUpgrades = {
        speedBoost = 0, -- 0-10 levels
        coinBonus = 0,  -- 0-10 levels  
        xpBoost = 0     -- 0-10 levels
    },
    
    -- Cosmetics and items
    ownedSkins = {},
    ownedTrails = {"common_sparkle"},
    ownedUpgrades = {},
    equippedSkin = nil,
    equippedTrail = nil,
    ownedCosmetics = {},
    
    -- Quest system (consolidated from QuestService)
    questProgress = {},
    dailyQuests = {},
    lastQuestReset = 0,
    
    -- Puzzle system (consolidated from PuzzleService)
    puzzleProgress = {},
    puzzlesCompleted = 0,
    weeklyPuzzleData = {},
    
    -- Tournament system (consolidated from TournamentService)
    tournamentStats = {},
    tournamentPrizes = {},
    weeklyTournamentData = {},
    
    -- Weekly leaderboard (consolidated from WeeklyLeaderboardService)
    weeklyStats = {},
    weeklyRewards = {},
    
    -- Exclusive cosmetics (consolidated from ExclusiveService)
    exclusiveCosmetics = {},
    exclusiveSchedule = {},
    
    -- Pet system
    ownedPets = {},
    activePet = nil,
    petStats = {},
    
    -- Buff system
    buffInventory = {},
    totalBuffsUsed = 0,
    buffUsageStats = {},
    
    -- VIP and monetization
    vipCoinMultiplier = 1,
    ownedGamepasses = {},
    totalPurchases = 0,
    totalRobuxSpent = 0,
    totalDevProductPurchases = 0,
    
    -- Achievement and goal systems
    completedGoals = {},
    claimedGoalRewards = {},
    completedAchievements = {},
    claimedAchievementRewards = {},
    
    -- Trophy and streak systems
    perfectGames = 0,
    ghostVictories = 0,
    maxCombo = 0,
    eventsParticipated = 0,
    eventsWon = 0,
    scoresShared = 0,
    currentStreak = 0,
    longestStreak = 0,
    lastLoginDate = 0,
    
    -- Rebirth system
    rebirths = 0,
    rebirthBonuses = {},
    
    -- Tutorial and onboarding
    tutorialCompleted = false,
    
    -- Metadata
    joinDate = 0,
    dataVersion = 2,
    lastSaveTime = 0,
    totalPlayTime = 0
}

-- Data validation schemas
local function ValidatePlayerData(data)
    if type(data) ~= "table" then
        return false, "Data is not a table"
    end
    
    -- Check required fields
    local requiredFields = {"coins", "level", "experience", "upgrades", "settings"}
    for _, field in ipairs(requiredFields) do
        if data[field] == nil then
            return false, "Missing required field: " .. field
        end
    end
    
    -- Validate data types
    if type(data.coins) ~= "number" or data.coins < 0 then
        return false, "Invalid coins value"
    end
    
    if type(data.level) ~= "number" or data.level < 1 then
        return false, "Invalid level value"
    end
    
    if type(data.experience) ~= "number" or data.experience < 0 then
        return false, "Invalid experience value"
    end
    
    if type(data.upgrades) ~= "table" then
        return false, "Invalid upgrades data"
    end
    
    if type(data.settings) ~= "table" then
        return false, "Invalid settings data"
    end
    
    return true, "Valid"
end

-- Merge loaded data with default schema to ensure compatibility
local function MergeWithDefaults(loadedData, defaults)
    local mergedData = {}
    
    for key, defaultValue in pairs(defaults) do
        if loadedData[key] ~= nil then
            if type(defaultValue) == "table" and type(loadedData[key]) == "table" then
                -- Recursively merge nested tables
                mergedData[key] = MergeWithDefaults(loadedData[key], defaultValue)
            else
                mergedData[key] = loadedData[key]
            end
        else
            -- Use default value for missing fields
            if type(defaultValue) == "table" then
                mergedData[key] = MergeWithDefaults({}, defaultValue)
            else
                mergedData[key] = defaultValue
            end
        end
    end
    
    return mergedData
end

-- Load player data with validation and retry logic
function UnifiedDataService:LoadPlayerData(player)
    local userId = tostring(player.UserId)
    local maxRetries = MAX_SAVE_RETRIES
    local retryDelay = RETRY_DELAY_BASE
    
    print("🔄 Loading data for " .. player.Name .. " (ID: " .. userId .. ")")
    
    for attempt = 1, maxRetries do
        local success, result = pcall(function()
            -- Try primary DataStore first
            local primaryData = primaryDataStore:GetAsync(userId)
            if primaryData then
                return primaryData, "primary"
            end
            
            -- Fall back to backup DataStore
            local backupData = backupDataStore:GetAsync(userId)
            if backupData then
                warn("⚠️ Loaded backup data for " .. player.Name)
                return backupData, "backup"
            end
            
            return nil, "new"
        end)
        
        if success then
            local loadedData, source = result, "primary"
            if type(result) == "table" then
                loadedData, source = result[1], result[2] or "primary"
            end
            
            if loadedData then
                -- Validate loaded data
                local isValid, validationMessage = ValidatePlayerData(loadedData)
                
                if isValid then
                    -- Merge with defaults and update cache
                    local playerData = MergeWithDefaults(loadedData, DEFAULT_DATA)
                    playerData.lastSaveTime = os.time()
                    playerDataCache[userId] = playerData
                    
                    print("✅ Successfully loaded " .. source .. " data for " .. player.Name .. 
                          " (Coins: " .. playerData.coins .. ", Level: " .. playerData.level .. ")")
                    return playerData
                else
                    warn("❌ Data validation failed for " .. player.Name .. ": " .. validationMessage)
                    if attempt < maxRetries then
                        warn("🔄 Retrying data load (attempt " .. (attempt + 1) .. "/" .. maxRetries .. ")")
                        wait(retryDelay)
                        retryDelay = retryDelay * 1.5 -- Exponential backoff
                        continue
                    end
                end
            else
                -- New player
                local newPlayerData = MergeWithDefaults({}, DEFAULT_DATA)
                newPlayerData.joinDate = os.time()
                newPlayerData.lastSaveTime = os.time()
                playerDataCache[userId] = newPlayerData
                
                print("📝 Created new player data for " .. player.Name)
                return newPlayerData
            end
        else
            warn("❌ Failed to load data for " .. player.Name .. " (attempt " .. attempt .. "/" .. maxRetries .. "): " .. tostring(result))
            if attempt < maxRetries then
                wait(retryDelay)
                retryDelay = retryDelay * 1.5
            end
        end
    end
    
    -- If all retries failed, create emergency default data
    warn("⚠️ All data load attempts failed for " .. player.Name .. ", using emergency defaults")
    local emergencyData = MergeWithDefaults({}, DEFAULT_DATA)
    emergencyData.joinDate = os.time()
    emergencyData.lastSaveTime = os.time()
    playerDataCache[userId] = emergencyData
    
    return emergencyData
end

-- Save player data with retry logic
function UnifiedDataService:SavePlayerData(player, data)
    local userId = tostring(player.UserId)
    data = data or playerDataCache[userId]
    
    if not data then
        warn("❌ No data to save for " .. player.Name)
        return false
    end
    
    -- Validate data before saving
    local isValid, validationMessage = ValidatePlayerData(data)
    if not isValid then
        warn("❌ Cannot save invalid data for " .. player.Name .. ": " .. validationMessage)
        return false
    end
    
    data.lastSaveTime = os.time()
    local maxRetries = MAX_SAVE_RETRIES
    local retryDelay = RETRY_DELAY_BASE
    
    for attempt = 1, maxRetries do
        local success, error = pcall(function()
            primaryDataStore:SetAsync(userId, data)
        end)
        
        if success then
            playerDataCache[userId] = data
            print("💾 Successfully saved data for " .. player.Name .. " (attempt " .. attempt .. ")")
            return true
        else
            warn("❌ Failed to save data for " .. player.Name .. " (attempt " .. attempt .. "/" .. maxRetries .. "): " .. tostring(error))
            if attempt < maxRetries then
                wait(retryDelay)
                retryDelay = retryDelay * 1.5
            end
        end
    end
    
    warn("⚠️ All save attempts failed for " .. player.Name .. ", data may be lost!")
    return false
end

-- Backup save to secondary DataStore
function UnifiedDataService:BackupPlayerData(player, data)
    local userId = tostring(player.UserId)
    data = data or playerDataCache[userId]
    
    if not data then
        return false
    end
    
    local success, error = pcall(function()
        backupDataStore:SetAsync(userId, data)
    end)
    
    if success then
        print("💾 Backup saved for " .. player.Name)
        return true
    else
        warn("❌ Backup save failed for " .. player.Name .. ": " .. tostring(error))
        return false
    end
end

-- Get cached player data
function UnifiedDataService:GetPlayerData(player)
    local userId = tostring(player.UserId)
    return playerDataCache[userId]
end

-- Update cached player data
function UnifiedDataService:UpdatePlayerData(player, updates)
    local userId = tostring(player.UserId)
    local data = playerDataCache[userId]
    
    if not data then
        warn("❌ No cached data found for " .. player.Name)
        return false
    end
    
    -- Apply updates
    for key, value in pairs(updates) do
        data[key] = value
    end
    
    return true
end

-- Queue player for save
function UnifiedDataService:QueueSave(player)
    local userId = tostring(player.UserId)
    if not saveQueue[userId] then
        saveQueue[userId] = {
            player = player,
            timestamp = os.time()
        }
    end
end

-- Process save queue
function UnifiedDataService:ProcessSaveQueue()
    for userId, queueData in pairs(saveQueue) do
        if queueData.player and queueData.player.Parent then
            self:SavePlayerData(queueData.player)
        end
        saveQueue[userId] = nil
    end
end

-- Handle player leaving
function UnifiedDataService:HandlePlayerLeaving(player)
    local userId = tostring(player.UserId)
    
    -- Save immediately on leave
    if playerDataCache[userId] then
        self:SavePlayerData(player)
        self:BackupPlayerData(player)
    end
    
    -- Clean up cache
    playerDataCache[userId] = nil
    saveQueue[userId] = nil
    
    print("👋 Cleaned up data for " .. player.Name)
end

-- Initialize the service
function UnifiedDataService:Init()
    print("💾 Initializing Unified Data Service...")
    
    -- Set up player connections
    Players.PlayerAdded:Connect(function(player)
        self:LoadPlayerData(player)
    end)
    
    Players.PlayerRemoving:Connect(function(player)
        self:HandlePlayerLeaving(player)
    end)
    
    -- Handle game shutdown
    game:BindToClose(function()
        isShuttingDown = true
        print("⚠️ Game shutting down, saving all player data...")
        
        for userId, data in pairs(playerDataCache) do
            local player = Players:GetPlayerByUserId(tonumber(userId))
            if player then
                self:SavePlayerData(player)
                self:BackupPlayerData(player)
            end
        end
        
        wait(3) -- Give time for saves to complete
    end)
    
    -- Set up backup timer using Heartbeat
    RunService.Heartbeat:Connect(function(deltaTime)
        if isShuttingDown then
            return
        end
        
        backupTimer = backupTimer + deltaTime
        
        -- Backup saves every 5 minutes
        if backupTimer >= BACKUP_INTERVAL then
            backupTimer = 0
            
            print("💾 Performing backup saves for all players...")
            for userId, data in pairs(playerDataCache) do
                local player = Players:GetPlayerByUserId(tonumber(userId))
                if player and player.Parent then
                    spawn(function()
                        self:BackupPlayerData(player)
                    end)
                end
            end
        end
        
        -- Process save queue every 30 seconds
        if backupTimer % 30 < deltaTime then
            self:ProcessSaveQueue()
        end
    end)
    
    print("✅ Unified Data Service initialized with automatic backups!")
end

-- Utility function to migrate data from old services
function UnifiedDataService:MigrateOldData(player)
    local userId = tostring(player.UserId)
    local currentData = playerDataCache[userId]
    
    if not currentData then
        warn("❌ No current data to migrate for " .. player.Name)
        return false
    end
    
    print("🔄 Checking for legacy data to migrate for " .. player.Name)
    
    -- Attempt to load from old DataStores and merge
    local oldStores = {
        {store = "PlayerUpgrades", field = "legacyUpgrades"},
        {store = "DailyQuestProgress", field = "legacyQuests"},
        {store = "WeeklyPuzzleProgress", field = "legacyPuzzles"},
        {store = "ExclusiveCosmetics", field = "legacyExclusives"},
        {store = "TournamentData_v1", field = "legacyTournament"},
        {store = "WeeklyLeaderboard_v1", field = "legacyWeekly"}
    }
    
    local migrationPerformed = false
    
    for _, storeInfo in ipairs(oldStores) do
        local success, oldData = pcall(function()
            local oldStore = DataStoreService:GetDataStore(storeInfo.store)
            return oldStore:GetAsync(userId)
        end)
        
        if success and oldData then
            currentData[storeInfo.field] = oldData
            migrationPerformed = true
            print("📦 Migrated " .. storeInfo.store .. " data for " .. player.Name)
        end
    end
    
    if migrationPerformed then
        -- Save the migrated data
        self:SavePlayerData(player, currentData)
        print("✅ Migration completed for " .. player.Name)
    end
    
    return migrationPerformed
end

-- System-wide data storage (for schedules, global settings, etc.)
local systemDataCache = {}
local systemDataStore = DataStoreService:GetDataStore("SystemData_v2")

function UnifiedDataService:GetSystemData(key)
    -- Check cache first
    if systemDataCache[key] then
        return systemDataCache[key]
    end
    
    -- Load from DataStore
    local success, data = pcall(function()
        return systemDataStore:GetAsync(key)
    end)
    
    if success and data then
        systemDataCache[key] = data
        return data
    end
    
    return nil
end

function UnifiedDataService:SaveSystemData(key, data)
    local success, error = pcall(function()
        systemDataStore:SetAsync(key, data)
    end)
    
    if success then
        systemDataCache[key] = data
        return true
    else
        warn("❌ Failed to save system data for key " .. key .. ": " .. tostring(error))
        return false
    end
end

return UnifiedDataService
