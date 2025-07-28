-- DataService.luau
-- Handles player data storage and retrieval

local DataStoreService = game:GetService("DataStoreService")
local Players = game:GetService("Players")

local DataService = {}
local playerDataStore = DataStoreService:GetDataStore("PlayerData")

-- Forward declare PlayerService to avoid circular dependency
local PlayerService = nil

-- Default player data structure
local DEFAULT_DATA = {
    coins = 0,
    level = 1,
    experience = 0,
    xpToNextLevel = 100, -- Dynamic XP requirement for next level
    totalXpEarned = 0, -- Track lifetime XP for analytics
    highScore = 0,
    totalBarriersPassed = 0,
    gamesPlayed = 0,
    totalCoinsEarned = 0, -- Track total coins earned for leaderboard
    upgrades = {
        speed = 0,
        coinMagnet = 0,
        doubleCoins = 0
    },
    -- Enhanced Upgrade System
    enhancedUpgrades = {
        speedBoost = 0, -- 0-10 levels
        coinBonus = 0,  -- 0-10 levels
        xpBoost = 0     -- 0-10 levels
    },
    currentColor = "RED",
    settings = {
        music = true,
        sfx = true,
        particles = true,
        colorblindMode = false,
        controllerEnabled = true
    },
    -- Purchased items data
    ownedSkins = {},
    ownedTrails = {"common_sparkle"}, -- Give everyone the basic trail
    ownedUpgrades = {},
    equippedSkin = nil,
    equippedTrail = nil,
    -- Trail & Crate System
    crateHistory = {}, -- Track crate purchases and results
    trailsUnlocked = {"common_sparkle"}, -- Legacy compatibility
    -- Daily quest progress
    questProgress = {},
    dailyQuests = {},
    lastQuestReset = 0, -- Track when quests were last reset
    -- Additional tracking
    totalPurchases = 0,
    totalRobuxSpent = 0, -- Track Robux spent on developer products
    totalDevProductPurchases = 0, -- Track number of dev product purchases
    joinDate = 0, -- Will be set on first join
    -- Trophy-related stats
    perfectGames = 0, -- Games completed without wrong barriers
    ghostVictories = 0, -- Ghost races won
    maxCombo = 0, -- Highest combo achieved
    eventsParticipated = 0, -- Number of world events participated in
    eventsWon = 0, -- Number of world events won
    scoresShared = 0, -- Number of times score was shared
    puzzlesCompleted = 0, -- Weekly puzzles completed
    currentStreak = 0, -- Current login streak
    longestStreak = 0, -- Longest login streak achieved
    lastLoginDate = 0, -- Last login timestamp for streak tracking
    -- Pet System
    ownedPets = {}, -- Array of owned pet IDs
    activePet = nil, -- Currently equipped pet ID
    petStats = {}, -- Pet-specific statistics
    -- Buff System
    buffInventory = {}, -- Purchased buffs available for use
    totalBuffsUsed = 0, -- Lifetime buff usage tracking
    buffUsageStats = {}, -- Per-buff usage statistics
    -- VIP Gamepass benefits
    vipCoinMultiplier = 1, -- Applied from VIP Double Coins gamepass
    ownedGamepasses = {}, -- Track owned gamepasses for benefits
    -- Tournament System
    tournamentPrizes = {}, -- Exclusive tournament cosmetics earned
    -- Rebirth System (future expansion)
    rebirths = 0, -- Number of rebirths completed
    rebirthBonuses = {}, -- Rebirth-specific bonuses and multipliers
    -- Tutorial System
    tutorialCompleted = false, -- Track if new player tutorial was completed
    
    -- Goal System
    completedGoals = {}, -- Track which goals have been completed
    claimedGoalRewards = {}, -- Track which goal rewards have been claimed
    
    -- Achievement System
    completedAchievements = {}, -- Track which achievements have been completed
    claimedAchievementRewards = {}, -- Track which achievement rewards have been claimed
    ownedCosmetics = {}, -- Track cosmetic rewards from achievements
}

function DataService:GetPlayerData(player)
    -- Send data loading started notification to client
    local RemoteEvents = require(game.ReplicatedStorage.Shared.modules.RemoteEvents)
    RemoteEvents.DataLoadStarted:FireClient(player)
    
    local maxRetries = 3
    local retryDelay = 2
    local playerData = nil
    local loadSuccess = false
    
    for attempt = 1, maxRetries do
        local success, data = pcall(function()
            return playerDataStore:GetAsync(player.UserId)
        end)
        
        if success then
            if data then
                -- Merge loaded data with default data to ensure all fields exist
                playerData = {}
                for key, value in pairs(DEFAULT_DATA) do
                    if data[key] ~= nil then
                        playerData[key] = data[key]
                    else
                        playerData[key] = value
                    end
                end
                
                -- Ensure nested tables are properly merged
                if type(DEFAULT_DATA.upgrades) == "table" then
                    playerData.upgrades = playerData.upgrades or {}
                    for upgradeKey, upgradeValue in pairs(DEFAULT_DATA.upgrades) do
                        if playerData.upgrades[upgradeKey] == nil then
                            playerData.upgrades[upgradeKey] = upgradeValue
                        end
                    end
                end
                
                -- Enhanced upgrades system
                if type(DEFAULT_DATA.enhancedUpgrades) == "table" then
                    playerData.enhancedUpgrades = playerData.enhancedUpgrades or {}
                    for upgradeKey, upgradeValue in pairs(DEFAULT_DATA.enhancedUpgrades) do
                        if playerData.enhancedUpgrades[upgradeKey] == nil then
                            playerData.enhancedUpgrades[upgradeKey] = upgradeValue
                        end
                    end
                end
                
                if type(DEFAULT_DATA.settings) == "table" then
                    playerData.settings = playerData.settings or {}
                    for settingKey, settingValue in pairs(DEFAULT_DATA.settings) do
                        if playerData.settings[settingKey] == nil then
                            playerData.settings[settingKey] = settingValue
                        end
                    end
                end
                
                -- Initialize shop data if missing
                playerData.ownedSkins = playerData.ownedSkins or {}
                playerData.ownedTrails = playerData.ownedTrails or {"common_sparkle"}
                playerData.ownedUpgrades = playerData.ownedUpgrades or {}
                playerData.questProgress = playerData.questProgress or {}
                playerData.dailyQuests = playerData.dailyQuests or {}
                playerData.ownedGamepasses = playerData.ownedGamepasses or {}
                playerData.tournamentPrizes = playerData.tournamentPrizes or {}
                playerData.buffInventory = playerData.buffInventory or {}
                playerData.buffUsageStats = playerData.buffUsageStats or {}
                playerData.ownedPets = playerData.ownedPets or {}
                playerData.petStats = playerData.petStats or {}
                playerData.rebirthBonuses = playerData.rebirthBonuses or {}
                playerData.crateHistory = playerData.crateHistory or {}
                playerData.trailsUnlocked = playerData.trailsUnlocked or {"common_sparkle"}
                
                -- Ensure basic trail is always owned
                if not table.find(playerData.ownedTrails, "common_sparkle") then
                    table.insert(playerData.ownedTrails, "common_sparkle")
                end
                
                -- Update login streak
                self:UpdateLoginStreak(playerData)
                
                print("✅ Loaded data for " .. player.Name .. " (attempt " .. attempt .. ") - Coins: " .. playerData.coins .. ", Level: " .. playerData.level .. ", XP: " .. playerData.experience)
                loadSuccess = true
                break
            else
                -- New player - use default data
                playerData = self:CreateNewPlayerData()
                warn("📝 Created new player data for " .. player.Name)
                loadSuccess = true
                break
            end
        else
            warn("❌ Failed to load data for " .. player.Name .. " (attempt " .. attempt .. "/" .. maxRetries .. "): " .. tostring(data))
            if attempt < maxRetries then
                wait(retryDelay)
                retryDelay = retryDelay * 2 -- Exponential backoff
            end
        end
    end
    
    -- If all retries failed, use default data and warn
    if not loadSuccess or not playerData then
        warn("🚨 All data loading attempts failed for " .. player.Name .. ", using default data")
        playerData = self:CreateNewPlayerData()
        loadSuccess = false
    end
    
    -- Send data loading completed notification to client
    RemoteEvents.DataLoadCompleted:FireClient(player, loadSuccess, playerData)
    
    return playerData
end

function DataService:CreateNewPlayerData()
    local playerData = {}
    for key, value in pairs(DEFAULT_DATA) do
        if type(value) == "table" then
            playerData[key] = {}
            for subKey, subValue in pairs(value) do
                playerData[key][subKey] = subValue
            end
        else
            playerData[key] = value
        end
    end
    
    -- Set join date for new players
    playerData.joinDate = tick()
    return playerData
end

function DataService:SavePlayerData(player, data, reason)
    -- Validate data before saving
    if not data then
        warn("❌ Cannot save nil data for " .. player.Name)
        return false
    end
    
    -- Send save started notification to client
    reason = reason or "Game progress"
    local RemoteEvents = require(game.ReplicatedStorage.Shared.modules.RemoteEvents)
    RemoteEvents.SaveStarted:FireClient(player, reason)
    
    -- Add timestamp to track last save
    data.lastSave = tick()
    
    local maxRetries = 3
    local retryDelay = 1
    local success = false
    
    for attempt = 1, maxRetries do
        local saveSuccess, errorMessage = pcall(function()
            playerDataStore:SetAsync(player.UserId, data)
        end)
        
        if saveSuccess then
            print("💾 Saved data for " .. player.Name .. " (attempt " .. attempt .. ") - Coins: " .. (data.coins or 0) .. ", Level: " .. (data.level or 1) .. ", XP: " .. (data.experience or 0))
            success = true
            break
        else
            warn("❌ Failed to save data for " .. player.Name .. " (attempt " .. attempt .. "/" .. maxRetries .. "): " .. tostring(errorMessage))
            if attempt < maxRetries then
                wait(retryDelay)
                retryDelay = retryDelay * 2 -- Exponential backoff
            end
        end
    end
    
    if success then
        -- Send save completed notification to client
        RemoteEvents.SaveCompleted:FireClient(player, true, reason)
    else
        warn("🚨 All save attempts failed for " .. player.Name .. ", data may be lost!")
        -- Send save failed notification to client
        RemoteEvents.SaveCompleted:FireClient(player, false, reason)
    end
    
    return success
end

-- Immediate save function for critical changes
function DataService:ImmediateSave(player, data, reason)
    reason = reason or "Critical change"
    print("🚨 Immediate save triggered for " .. player.Name .. " - Reason: " .. reason)
    return self:SavePlayerData(player, data, reason)
end

-- Function to save all players immediately (for shutdown)
function DataService:SaveAllPlayers()
    if not PlayerService then
        warn("❌ PlayerService not available for emergency save")
        return
    end
    
    local savedCount = 0
    local failedCount = 0
    
    for _, player in pairs(game.Players:GetPlayers()) do
        local playerData = PlayerService:GetPlayerData(player)
        if playerData then
            local success = self:SavePlayerData(player, playerData, "Game shutdown")
            if success then
                savedCount = savedCount + 1
            else
                failedCount = failedCount + 1
            end
        end
    end
    
    print("💾 Emergency save complete - Saved: " .. savedCount .. ", Failed: " .. failedCount)
    return savedCount, failedCount
end

function DataService:Init()
    -- Set up player disconnection handling
    Players.PlayerRemoving:Connect(function(player)
        if PlayerService then
            local playerData = PlayerService:GetPlayerData(player)
            if playerData then
                self:ImmediateSave(player, playerData, "Player leaving")
            end
        end
        
        -- Clean up tracking data
        local userId = tostring(player.UserId)
        lastSavedData[userId] = nil
    end)
    
    -- Set up game shutdown handling
    game:BindToClose(function()
        print("🚨 Game shutting down, saving all player data...")
        self:SaveAllPlayers()
        wait(5) -- Give time for saves to complete
    end)
    
    -- Set up periodic auto-save (every 2 minutes) to prevent data loss
    spawn(function()
        while wait(120) do -- 2 minutes for more frequent saves
            if PlayerService then
                local savedCount = 0
                for _, player in pairs(game.Players:GetPlayers()) do
                    local playerData = PlayerService:GetPlayerData(player)
                    if playerData then
                        local success = self:SavePlayerData(player, playerData, "Auto-save")
                        if success then
                            savedCount = savedCount + 1
                        end
                    end
                end
                if savedCount > 0 then
                    print("🔄 Auto-saved data for " .. savedCount .. " players")
                end
            end
        end
    end)
    
    -- Enhanced backup save mechanism - more frequent for critical changes
    spawn(function()
        while wait(15) do -- Check every 15 seconds for critical data changes
            if PlayerService then
                for _, player in pairs(game.Players:GetPlayers()) do
                    local playerData = PlayerService:GetPlayerData(player)
                    if playerData and self:HasCriticalChanges(player, playerData) then
                        self:ImmediateSave(player, playerData, "Critical change detected")
                    end
                end
            end
        end
    end)
    
    print("✅ DataService initialized with enhanced auto-save, backup mechanisms, and disconnect handling enabled")
end

-- Track last saved data to detect critical changes
local lastSavedData = {}

function DataService:HasCriticalChanges(player, currentData)
    local userId = tostring(player.UserId)
    local lastData = lastSavedData[userId]
    
    if not lastData then
        lastSavedData[userId] = self:CreateDataSnapshot(currentData)
        return false
    end
    
    -- Check for critical changes that must be saved immediately
    local criticalChanges = false
    
    -- High-value progression changes
    if (currentData.level or 1) > (lastData.level or 1) then
        criticalChanges = true
        print("🔥 Critical change: Level increased for " .. player.Name)
    end
    if (currentData.experience or 0) ~= (lastData.experience or 0) then
        criticalChanges = true
        print("🔥 Critical change: XP changed for " .. player.Name)
    end
    if (currentData.coins or 0) ~= (lastData.coins or 0) then
        criticalChanges = true
        print("🔥 Critical change: Coins changed for " .. player.Name)
    end
    if (currentData.highScore or 0) > (lastData.highScore or 0) then
        criticalChanges = true
        print("🔥 Critical change: New high score for " .. player.Name)
    end
    
    -- Enhanced upgrade system changes
    if currentData.enhancedUpgrades then
        local lastUpgrades = lastData.enhancedUpgrades or {}
        for upgradeType, level in pairs(currentData.enhancedUpgrades) do
            if level > (lastUpgrades[upgradeType] or 0) then
                criticalChanges = true
                print("🔥 Critical change: Enhanced upgrade purchased for " .. player.Name .. " (" .. upgradeType .. ")")
            end
        end
    end
    
    -- Trail system changes
    if #(currentData.ownedTrails or {}) > #(lastData.ownedTrails or {}) then
        criticalChanges = true
        print("🔥 Critical change: New trail unlocked for " .. player.Name)
    end
    if (currentData.equippedTrail or "") ~= (lastData.equippedTrail or "") then
        criticalChanges = true
        print("🔥 Critical change: Trail equipped/unequipped for " .. player.Name)
    end
    
    -- Cosmetic/progression unlocks
    if #(currentData.ownedSkins or {}) > #(lastData.ownedSkins or {}) then
        criticalChanges = true
        print("🔥 Critical change: New cosmetic unlocked for " .. player.Name)
    end
    if #(currentData.ownedPets or {}) > #(lastData.ownedPets or {}) then
        criticalChanges = true
        print("🔥 Critical change: New pet unlocked for " .. player.Name)
    end
    if #(currentData.tournamentPrizes or {}) > #(lastData.tournamentPrizes or {}) then
        criticalChanges = true
        print("🔥 Critical change: Tournament prize earned for " .. player.Name)
    end
    
    -- Purchase tracking
    if (currentData.totalPurchases or 0) > (lastData.totalPurchases or 0) then
        criticalChanges = true
        print("🔥 Critical change: Purchase made for " .. player.Name)
    end
    
    -- Crate system
    if #(currentData.crateHistory or {}) > #(lastData.crateHistory or {}) then
        criticalChanges = true
        print("🔥 Critical change: Crate opened for " .. player.Name)
    end
    
    if criticalChanges then
        lastSavedData[userId] = self:CreateDataSnapshot(currentData)
    end
    
    return criticalChanges
end

function DataService:CreateDataSnapshot(data)
    return {
        level = data.level or 1,
        experience = data.experience or 0,
        coins = data.coins or 0,
        highScore = data.highScore or 0,
        ownedSkins = data.ownedSkins and #data.ownedSkins or 0,
        ownedTrails = data.ownedTrails and #data.ownedTrails or 0,
        ownedPets = data.ownedPets and #data.ownedPets or 0,
        tournamentPrizes = data.tournamentPrizes and #data.tournamentPrizes or 0,
        totalPurchases = data.totalPurchases or 0,
        crateHistory = data.crateHistory and #data.crateHistory or 0,
        equippedTrail = data.equippedTrail or "",
        enhancedUpgrades = {
            speedBoost = data.enhancedUpgrades and data.enhancedUpgrades.speedBoost or 0,
            coinBonus = data.enhancedUpgrades and data.enhancedUpgrades.coinBonus or 0,
            xpBoost = data.enhancedUpgrades and data.enhancedUpgrades.xpBoost or 0
        }
    }
end

-- Function to get default data structure (useful for other services)
function DataService:GetDefaultData()
    local data = {}
    for key, value in pairs(DEFAULT_DATA) do
        if type(value) == "table" then
            data[key] = {}
            for subKey, subValue in pairs(value) do
                data[key][subKey] = subValue
            end
        else
            data[key] = value
        end
    end
    return data
end

-- Enhanced function for other services to trigger immediate saves for critical changes
function DataService:TriggerImmediateSaveForCriticalChange(player, changeType, changeDetails)
    if not PlayerService then
        warn("❌ PlayerService not available for immediate save")
        return false
    end
    
    local playerData = PlayerService:GetPlayerData(player)
    if playerData then
        local reason = string.format("%s: %s", changeType, changeDetails or "No details")
        return self:ImmediateSave(player, playerData, reason)
    end
    
    return false
end

-- Function for services to check if they should trigger immediate saves
function DataService:ShouldTriggerImmediateSave(changeType)
    local immediateChanges = {
        "LEVEL_UP", "XP_GAIN", "COIN_CHANGE", "HIGH_SCORE", 
        "COSMETIC_UNLOCK", "TRAIL_UNLOCK", "TRAIL_EQUIP",
        "UPGRADE_PURCHASE", "CRATE_OPEN", "PURCHASE"
    }
    
    return table.find(immediateChanges, changeType) ~= nil
end

function DataService:SetPlayerService(service)
    PlayerService = service
end

function DataService:UpdateLoginStreak(playerData)
    local currentTime = os.time()
    local currentDay = math.floor(currentTime / 86400) -- Days since epoch
    local lastLoginDay = math.floor((playerData.lastLoginDate or 0) / 86400)
    
    if lastLoginDay == 0 then
        -- First login
        playerData.currentStreak = 1
        playerData.longestStreak = math.max(playerData.longestStreak or 0, 1)
    elseif currentDay == lastLoginDay then
        -- Same day, no change to streak
        return
    elseif currentDay == lastLoginDay + 1 then
        -- Consecutive day
        playerData.currentStreak = (playerData.currentStreak or 0) + 1
        playerData.longestStreak = math.max(playerData.longestStreak or 0, playerData.currentStreak)
    else
        -- Streak broken
        playerData.currentStreak = 1
    end
    
    playerData.lastLoginDate = currentTime
    print("📅 Login streak for player: " .. (playerData.currentStreak or 0) .. " days")
end

return DataService
