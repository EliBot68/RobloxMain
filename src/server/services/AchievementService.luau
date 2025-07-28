-- AchievementService.luau
-- Handles achievement tracking, rewards, and daily bonus system

local Players = game:GetService("Players")
local DataStoreService = game:GetService("DataStoreService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local RemoteEvents = require(ReplicatedStorage.Shared.modules.RemoteEvents)

-- Forward declare services
local PlayerService = nil
local AnalyticsService = nil

local AchievementService = {}

-- DataStore for achievement progress
local achievementDataStore = DataStoreService:GetDataStore("PlayerAchievements")
local dailyBonusDataStore = DataStoreService:GetDataStore("DailyBonusProgress")

-- Achievement definitions
local ACHIEVEMENTS = {
    {
        id = "run_10_times",
        name = "🏃 First Steps",
        description = "Complete 10 runs",
        icon = "🏃",
        category = "Progress",
        targetValue = 10,
        statKey = "gamesPlayed",
        reward = {
            type = "coins",
            amount = 100,
            name = "100 Coins"
        },
        rarity = "Common"
    },
    {
        id = "earn_500_coins",
        name = "💰 Coin Collector",
        description = "Earn 500 coins total",
        icon = "💰",
        category = "Economy",
        targetValue = 500,
        statKey = "totalCoinsEarned",
        reward = {
            type = "cosmetic",
            item = "golden_sparkle_trail",
            name = "Golden Sparkle Trail"
        },
        rarity = "Rare"
    },
    {
        id = "reach_level_5",
        name = "⭐ Rising Star",
        description = "Reach level 5",
        icon = "⭐",
        category = "Level",
        targetValue = 5,
        statKey = "level",
        reward = {
            type = "cosmetic",
            item = "star_crown",
            name = "Star Crown"
        },
        rarity = "Epic"
    }
}

-- Daily bonus definitions
local DAILY_BONUSES = {
    [1] = {coins = 25, type = "standard", message = "Daily login bonus!"},
    [2] = {coins = 30, type = "standard", message = "Welcome back! Day 2!"},
    [3] = {coins = 35, type = "standard", message = "Three days strong!"},
    [4] = {coins = 40, type = "standard", message = "Halfway to a week!"},
    [5] = {coins = 45, type = "standard", message = "Almost a week!"},
    [6] = {coins = 50, type = "standard", message = "Six days! Amazing!"},
    [7] = {coins = 75, type = "weekly", message = "WEEKLY BONUS! 🎉", effect = "golden_coins"}
}

-- Player achievement progress tracking
local playerAchievements = {}
local playerDailyBonus = {}

function AchievementService:Init()
    -- Connect to remote events
    self:SetupRemoteEvents()
    
    -- Connect to player events
    Players.PlayerAdded:Connect(function(player)
        self:OnPlayerAdded(player)
    end)
    
    Players.PlayerRemoving:Connect(function(player)
        self:SavePlayerData(player)
    end)
    
    print("🏆 AchievementService initialized")
end

function AchievementService:SetupRemoteEvents()
    -- Achievement events
    RemoteEvents.RequestAchievementData.OnServerEvent:Connect(function(player)
        self:SendAchievementData(player)
    end)
    
    RemoteEvents.ClaimAchievementReward.OnServerEvent:Connect(function(player, achievementId)
        self:ClaimAchievementReward(player, achievementId)
    end)
    
    -- Daily bonus events
    RemoteEvents.RequestDailyBonus.OnServerEvent:Connect(function(player)
        self:ShowDailyBonus(player)
    end)
    
    RemoteEvents.ClaimDailyBonus.OnServerEvent:Connect(function(player)
        self:ClaimDailyBonus(player)
    end)
end

function AchievementService:OnPlayerAdded(player)
    spawn(function()
        wait(2) -- Wait for player to fully load
        
        -- Load achievement data
        self:LoadPlayerAchievements(player)
        
        -- Check for daily bonus
        self:CheckDailyBonus(player)
        
        -- Check all achievements
        self:CheckAllAchievements(player)
    end)
end

function AchievementService:LoadPlayerAchievements(player)
    local userId = tostring(player.UserId)
    
    -- Load achievement progress
    local success, data = pcall(function()
        return achievementDataStore:GetAsync(userId) or {}
    end)
    
    if not success then
        warn("Failed to load achievement data for " .. player.Name)
        data = {}
    end
    
    -- Initialize default achievement data
    if not data.achievements then
        data.achievements = {}
        for _, achievement in pairs(ACHIEVEMENTS) do
            data.achievements[achievement.id] = {
                progress = 0,
                completed = false,
                claimed = false,
                completedDate = nil,
                claimedDate = nil
            }
        end
    end
    
    -- Ensure all achievements exist (for new achievements added later)
    for _, achievement in pairs(ACHIEVEMENTS) do
        if not data.achievements[achievement.id] then
            data.achievements[achievement.id] = {
                progress = 0,
                completed = false,
                claimed = false,
                completedDate = nil,
                claimedDate = nil
            }
        end
    end
    
    playerAchievements[userId] = data
end

function AchievementService:CheckDailyBonus(player)
    local userId = tostring(player.UserId)
    local currentTime = os.time()
    local currentDay = math.floor(currentTime / 86400) -- Days since epoch
    
    -- Load daily bonus data
    local success, data = pcall(function()
        return dailyBonusDataStore:GetAsync(userId) or {}
    end)
    
    if not success then
        warn("Failed to load daily bonus data for " .. player.Name)
        data = {}
    end
    
    -- Initialize if needed
    if not data.lastClaimDay then
        data = {
            lastClaimDay = 0,
            currentStreak = 0,
            longestStreak = 0,
            totalBonusesClaimed = 0,
            claimedToday = false
        }
    end
    
    -- Check if we should show daily bonus
    local shouldShowBonus = false
    
    if data.lastClaimDay == 0 then
        -- First time player
        data.currentStreak = 1
        data.longestStreak = 1
        shouldShowBonus = true
    elseif data.lastClaimDay == currentDay then
        -- Already claimed today
        data.claimedToday = true
    elseif data.lastClaimDay == currentDay - 1 then
        -- Claimed yesterday, continue streak
        data.currentStreak = data.currentStreak + 1
        data.longestStreak = math.max(data.longestStreak, data.currentStreak)
        shouldShowBonus = true
    else
        -- Streak broken or new day
        data.currentStreak = 1
        shouldShowBonus = true
    end
    
    data.claimedToday = false
    playerDailyBonus[userId] = data
    
    if shouldShowBonus then
        -- Show daily bonus popup after a delay
        spawn(function()
            wait(3)
            self:ShowDailyBonusPopup(player)
        end)
    end
end

function AchievementService:ShowDailyBonusPopup(player)
    local userId = tostring(player.UserId)
    local data = playerDailyBonus[userId]
    
    if not data or data.claimedToday then
        return
    end
    
    local dayInCycle = ((data.currentStreak - 1) % 7) + 1
    local bonus = DAILY_BONUSES[dayInCycle] or DAILY_BONUSES[7]
    
    RemoteEvents.ShowDailyBonusPopup:FireClient(player, {
        day = data.currentStreak,
        dayInCycle = dayInCycle,
        bonus = bonus,
        streak = data.currentStreak,
        longestStreak = data.longestStreak
    })
end

function AchievementService:ClaimDailyBonus(player)
    local userId = tostring(player.UserId)
    local data = playerDailyBonus[userId]
    
    if not data or data.claimedToday then
        RemoteEvents.DailyBonusResult:FireClient(player, {
            success = false,
            message = "Daily bonus already claimed today!"
        })
        return
    end
    
    local currentDay = math.floor(os.time() / 86400)
    local dayInCycle = ((data.currentStreak - 1) % 7) + 1
    local bonus = DAILY_BONUSES[dayInCycle] or DAILY_BONUSES[7]
    
    -- Apply bonus
    if PlayerService then
        local playerData = PlayerService:GetPlayerData(player)
        if playerData then
            playerData.coins = playerData.coins + bonus.coins
            playerData.totalCoinsEarned = (playerData.totalCoinsEarned or 0) + bonus.coins
            PlayerService:UpdatePlayerData(player, playerData)
        end
    end
    
    -- Update daily bonus data
    data.lastClaimDay = currentDay
    data.claimedToday = true
    data.totalBonusesClaimed = data.totalBonusesClaimed + 1
    
    -- Save data
    self:SaveDailyBonusData(player, data)
    
    -- Send success response
    RemoteEvents.DailyBonusResult:FireClient(player, {
        success = true,
        bonus = bonus,
        streak = data.currentStreak,
        coinsEarned = bonus.coins
    })
    
    -- Analytics
    if AnalyticsService then
        AnalyticsService:LogEvent(player, "daily_bonus_claimed", {
            day = data.currentStreak,
            coinsEarned = bonus.coins,
            type = bonus.type
        })
    end
    
    print("🎁 " .. player.Name .. " claimed daily bonus: " .. bonus.coins .. " coins (Day " .. data.currentStreak .. ")")
end

function AchievementService:CheckAllAchievements(player)
    if not PlayerService then return end
    
    local userId = tostring(player.UserId)
    local playerData = PlayerService:GetPlayerData(player)
    local achievements = playerAchievements[userId]
    
    if not playerData or not achievements then return end
    
    local hasNewAchievements = false
    
    for _, achievement in pairs(ACHIEVEMENTS) do
        local achievementProgress = achievements.achievements[achievement.id]
        
        if achievementProgress and not achievementProgress.completed then
            -- Get current stat value
            local currentValue = self:GetStatValue(playerData, achievement.statKey)
            
            -- Update progress
            achievementProgress.progress = currentValue
            
            -- Check if completed
            if currentValue >= achievement.targetValue then
                achievementProgress.completed = true
                achievementProgress.completedDate = os.time()
                hasNewAchievements = true
                
                -- Show achievement notification
                self:ShowAchievementUnlocked(player, achievement)
                
                print("🏆 " .. player.Name .. " unlocked achievement: " .. achievement.name)
            end
        end
    end
    
    if hasNewAchievements then
        self:SavePlayerAchievements(player)
        self:SendAchievementData(player)
    end
end

function AchievementService:GetStatValue(playerData, statKey)
    if statKey == "gamesPlayed" then
        return playerData.gamesPlayed or 0
    elseif statKey == "totalCoinsEarned" then
        return playerData.totalCoinsEarned or 0
    elseif statKey == "level" then
        return playerData.level or 1
    elseif statKey == "highScore" then
        return playerData.highScore or 0
    end
    return 0
end

function AchievementService:ShowAchievementUnlocked(player, achievement)
    RemoteEvents.AchievementUnlocked:FireClient(player, {
        id = achievement.id,
        name = achievement.name,
        description = achievement.description,
        icon = achievement.icon,
        reward = achievement.reward,
        rarity = achievement.rarity
    })
end

function AchievementService:ClaimAchievementReward(player, achievementId)
    local userId = tostring(player.UserId)
    local achievements = playerAchievements[userId]
    
    if not achievements or not achievements.achievements[achievementId] then
        return
    end
    
    local achievementProgress = achievements.achievements[achievementId]
    
    if not achievementProgress.completed then
        RemoteEvents.AchievementClaimResult:FireClient(player, {
            success = false,
            message = "Achievement not completed yet!"
        })
        return
    end
    
    if achievementProgress.claimed then
        RemoteEvents.AchievementClaimResult:FireClient(player, {
            success = false,
            message = "Reward already claimed!"
        })
        return
    end
    
    -- Find achievement definition
    local achievement = nil
    for _, ach in pairs(ACHIEVEMENTS) do
        if ach.id == achievementId then
            achievement = ach
            break
        end
    end
    
    if not achievement then return end
    
    -- Apply reward
    local success = self:ApplyAchievementReward(player, achievement)
    
    if success then
        achievementProgress.claimed = true
        achievementProgress.claimedDate = os.time()
        
        self:SavePlayerAchievements(player)
        
        RemoteEvents.AchievementClaimResult:FireClient(player, {
            success = true,
            achievement = achievement,
            reward = achievement.reward
        })
        
        print("🎁 " .. player.Name .. " claimed achievement reward: " .. achievement.name)
    else
        RemoteEvents.AchievementClaimResult:FireClient(player, {
            success = false,
            message = "Failed to apply reward"
        })
    end
end

function AchievementService:ApplyAchievementReward(player, achievement)
    if not PlayerService then return false end
    
    local playerData = PlayerService:GetPlayerData(player)
    if not playerData then return false end
    
    local reward = achievement.reward
    
    if reward.type == "coins" then
        playerData.coins = playerData.coins + reward.amount
        playerData.totalCoinsEarned = (playerData.totalCoinsEarned or 0) + reward.amount
    elseif reward.type == "cosmetic" then
        -- Add cosmetic to player's collection
        if reward.item:find("trail") then
            if not playerData.ownedTrails then playerData.ownedTrails = {} end
            if not table.find(playerData.ownedTrails, reward.item) then
                table.insert(playerData.ownedTrails, reward.item)
            end
        else
            -- Handle other cosmetics (hats, etc.)
            if not playerData.ownedCosmetics then playerData.ownedCosmetics = {} end
            playerData.ownedCosmetics[reward.item] = true
        end
    end
    
    PlayerService:UpdatePlayerData(player, playerData)
    return true
end

function AchievementService:SendAchievementData(player)
    local userId = tostring(player.UserId)
    local achievements = playerAchievements[userId]
    
    if not achievements then return end
    
    local achievementData = {}
    
    for _, achievement in pairs(ACHIEVEMENTS) do
        local progress = achievements.achievements[achievement.id]
        
        table.insert(achievementData, {
            id = achievement.id,
            name = achievement.name,
            description = achievement.description,
            icon = achievement.icon,
            category = achievement.category,
            targetValue = achievement.targetValue,
            progress = progress.progress,
            completed = progress.completed,
            claimed = progress.claimed,
            reward = achievement.reward,
            rarity = achievement.rarity,
            progressPercent = math.min(100, (progress.progress / achievement.targetValue) * 100)
        })
    end
    
    RemoteEvents.AchievementDataUpdated:FireClient(player, achievementData)
end

function AchievementService:SavePlayerAchievements(player)
    local userId = tostring(player.UserId)
    local data = playerAchievements[userId]
    
    if not data then return end
    
    pcall(function()
        achievementDataStore:SetAsync(userId, data)
    end)
end

function AchievementService:SaveDailyBonusData(player, data)
    local userId = tostring(player.UserId)
    
    pcall(function()
        dailyBonusDataStore:SetAsync(userId, data)
    end)
end

function AchievementService:UpdatePlayerProgress(player, statKey, newValue)
    -- Called by other services when player stats change
    local userId = tostring(player.UserId)
    local achievements = playerAchievements[userId]
    
    if not achievements then return end
    
    local hasUpdates = false
    
    for _, achievement in pairs(ACHIEVEMENTS) do
        if achievement.statKey == statKey then
            local progress = achievements.achievements[achievement.id]
            if progress and not progress.completed then
                progress.progress = newValue
                
                if newValue >= achievement.targetValue then
                    progress.completed = true
                    progress.completedDate = os.time()
                    hasUpdates = true
                    
                    self:ShowAchievementUnlocked(player, achievement)
                end
            end
        end
    end
    
    if hasUpdates then
        self:SavePlayerAchievements(player)
        self:SendAchievementData(player)
    end
end

-- Service dependency setters
function AchievementService:SetPlayerService(service)
    PlayerService = service
end

function AchievementService:SetAnalyticsService(service)
    AnalyticsService = service
end

return AchievementService
