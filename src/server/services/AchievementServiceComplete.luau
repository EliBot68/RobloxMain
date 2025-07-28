-- AchievementService.luau
-- Complete achievement tracking, rewards, and daily bonus system

local Players = game:GetService("Players")
local DataStoreService = game:GetService("DataStoreService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local SafeRequire = require(ReplicatedStorage.Shared.utils.SafeRequire)
local ServiceBase = SafeRequire.require(ReplicatedStorage.Shared.utils.ServiceBase)
local WorldObjectValidator = SafeRequire.require(ReplicatedStorage.Shared.utils.WorldObjectValidator)

local AchievementService = ServiceBase.new("AchievementService", {
    enableDetailedLogging = true,
    retryFailedRequires = true,
    maxRetryAttempts = 3,
    validateOnStart = true,
    autoStart = false
})

-- Define dependencies
AchievementService.Dependencies = {
    { path = ReplicatedStorage.Shared.modules.RemoteEvents, name = "RemoteEvents", optional = false },
    { path = script.Parent.DataService, name = "DataService", optional = true },
    { path = script.Parent.PlayerService, name = "PlayerService", optional = true },
    { path = script.Parent.AnalyticsService, name = "AnalyticsService", optional = true }
}

-- DataStore for achievement data
local achievementDataStore = DataStoreService:GetDataStore("PlayerAchievements")
local dailyBonusDataStore = DataStoreService:GetDataStore("DailyBonusProgress")

-- Player achievement progress tracking
local playerAchievements = {}
local playerDailyBonus = {}

-- Comprehensive achievement definitions
local ACHIEVEMENTS = {
    -- Beginner Achievements
    {
        id = "first_run",
        name = "🏁 First Steps",
        description = "Complete your first run",
        icon = "🏁",
        category = "Progress",
        targetValue = 1,
        statKey = "gamesPlayed",
        reward = {
            type = "coins",
            amount = 50,
            name = "50 Coins"
        },
        rarity = "Common"
    },
    {
        id = "run_10_times",
        name = "🏃 Getting Started",
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
        id = "run_50_times",
        name = "🎯 Dedicated Runner",
        description = "Complete 50 runs",
        icon = "🎯",
        category = "Progress",
        targetValue = 50,
        statKey = "gamesPlayed",
        reward = {
            type = "cosmetic",
            item = "runner_badge",
            name = "Runner Badge"
        },
        rarity = "Uncommon"
    },
    {
        id = "run_100_times",
        name = "🏆 Marathon Master",
        description = "Complete 100 runs",
        icon = "🏆",
        category = "Progress",
        targetValue = 100,
        statKey = "gamesPlayed",
        reward = {
            type = "cosmetic",
            item = "golden_runner_trail",
            name = "Golden Runner Trail"
        },
        rarity = "Epic"
    },
    
    -- Economy Achievements
    {
        id = "earn_100_coins",
        name = "💰 Coin Finder",
        description = "Earn 100 coins total",
        icon = "💰",
        category = "Economy",
        targetValue = 100,
        statKey = "totalCoinsEarned",
        reward = {
            type = "coins",
            amount = 25,
            name = "25 Bonus Coins"
        },
        rarity = "Common"
    },
    {
        id = "earn_500_coins",
        name = "💎 Coin Collector",
        description = "Earn 500 coins total",
        icon = "💎",
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
        id = "earn_2000_coins",
        name = "🏦 Coin Tycoon",
        description = "Earn 2,000 coins total",
        icon = "🏦",
        category = "Economy",
        targetValue = 2000,
        statKey = "totalCoinsEarned",
        reward = {
            type = "cosmetic",
            item = "diamond_aura",
            name = "Diamond Aura"
        },
        rarity = "Legendary"
    },
    
    -- Level Achievements
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
        rarity = "Rare"
    },
    {
        id = "reach_level_10",
        name = "🌟 Bright Star",
        description = "Reach level 10",
        icon = "🌟",
        category = "Level",
        targetValue = 10,
        statKey = "level",
        reward = {
            type = "cosmetic",
            item = "glowing_star_aura",
            name = "Glowing Star Aura"
        },
        rarity = "Epic"
    },
    {
        id = "reach_level_25",
        name = "🏅 Champion",
        description = "Reach level 25",
        icon = "🏅",
        category = "Level",
        targetValue = 25,
        statKey = "level",
        reward = {
            type = "cosmetic",
            item = "champion_wings",
            name = "Champion Wings"
        },
        rarity = "Legendary"
    },
    
    -- Performance Achievements
    {
        id = "fast_finish_30s",
        name = "⚡ Speed Demon",
        description = "Finish a run in under 30 seconds",
        icon = "⚡",
        category = "Performance",
        targetValue = 1,
        statKey = "fastFinishes",
        reward = {
            type = "cosmetic",
            item = "lightning_trail",
            name = "Lightning Trail"
        },
        rarity = "Rare"
    },
    {
        id = "perfect_run",
        name = "💯 Perfect Run",
        description = "Complete a run without any wrong color hits",
        icon = "💯",
        category = "Performance",
        targetValue = 1,
        statKey = "perfectRuns",
        reward = {
            type = "cosmetic",
            item = "perfect_halo",
            name = "Perfect Halo"
        },
        rarity = "Epic"
    },
    
    -- Daily/Streak Achievements
    {
        id = "daily_login_7",
        name = "📅 Week Warrior",
        description = "Log in 7 days in a row",
        icon = "📅",
        category = "Daily",
        targetValue = 7,
        statKey = "dailyStreak",
        reward = {
            type = "coins",
            amount = 200,
            name = "200 Bonus Coins"
        },
        rarity = "Uncommon"
    },
    {
        id = "daily_login_30",
        name = "🗓️ Monthly Master",
        description = "Log in 30 days in a row",
        icon = "🗓️",
        category = "Daily",
        targetValue = 30,
        statKey = "dailyStreak",
        reward = {
            type = "cosmetic",
            item = "calendar_crown",
            name = "Calendar Crown"
        },
        rarity = "Legendary"
    },
    
    -- Special Achievements
    {
        id = "social_butterfly",
        name = "👥 Social Butterfly",
        description = "Play with 5 different players",
        icon = "👥",
        category = "Social",
        targetValue = 5,
        statKey = "uniquePlayersPlayed",
        reward = {
            type = "cosmetic",
            item = "friendship_badge",
            name = "Friendship Badge"
        },
        rarity = "Rare"
    },
    {
        id = "upgrade_master",
        name = "⬆️ Upgrade Master",
        description = "Purchase 10 upgrades",
        icon = "⬆️",
        category = "Economy",
        targetValue = 10,
        statKey = "upgradesPurchased",
        reward = {
            type = "cosmetic",
            item = "upgrade_gear",
            name = "Upgrade Gear"
        },
        rarity = "Epic"
    }
}

-- Enhanced daily bonus definitions
local DAILY_BONUSES = {
    [1] = {coins = 25, xp = 10, type = "standard", message = "Welcome back! Daily login bonus!", effect = "coins"},
    [2] = {coins = 30, xp = 12, type = "standard", message = "Day 2! Keep it up!", effect = "coins"},
    [3] = {coins = 35, xp = 15, type = "standard", message = "Three days strong!", effect = "coins"},
    [4] = {coins = 40, xp = 18, type = "standard", message = "Halfway to a week!", effect = "coins"},
    [5] = {coins = 45, xp = 20, type = "standard", message = "Five days! Amazing!", effect = "coins"},
    [6] = {coins = 50, xp = 25, type = "standard", message = "Almost a full week!", effect = "coins"},
    [7] = {coins = 100, xp = 50, type = "weekly", message = "WEEKLY BONUS! 🎉", effect = "golden_explosion"},
    [14] = {coins = 200, xp = 100, type = "biweekly", message = "TWO WEEKS! Incredible! 🌟", effect = "rainbow_burst"},
    [30] = {coins = 500, xp = 250, type = "monthly", message = "MONTHLY DEDICATION! 👑", effect = "royal_celebration"}
}

-- Service-specific initialization
function AchievementService:OnInit()
    print("🏆 AchievementService initializing...")
    
    -- Validate required dependencies
    local missingObjects = WorldObjectValidator.validateAllRequired()
    if #missingObjects > 0 then
        warn("⚠️ AchievementService: Missing required world objects:")
        for _, missing in ipairs(missingObjects) do
            warn("  • " .. missing)
        end
    end
    
    -- Initialize tracking tables
    playerAchievements = {}
    playerDailyBonus = {}
    
    return true
end

-- Service-specific start logic
function AchievementService:OnStart()
    print("🏆 AchievementService starting...")
    
    -- Load any existing players
    for _, player in pairs(Players:GetPlayers()) do
        self:OnPlayerAdded(player)
    end
    
    print("✅ AchievementService started with", #ACHIEVEMENTS, "achievements")
    return true
end

-- Setup remote events
function AchievementService:SetupRemoteEvents()
    if not self.RemoteEvents then
        warn("❌ AchievementService: RemoteEvents not available")
        return
    end

    -- Request achievement data
    self.RemoteEvents.RequestAchievementData.OnServerEvent:Connect(function(player)
        self:SendAchievementData(player)
    end)
    
    -- Claim achievement reward
    self.RemoteEvents.ClaimAchievementReward.OnServerEvent:Connect(function(player, achievementId)
        self:ClaimAchievementReward(player, achievementId)
    end)
    
    -- Request daily bonus
    self.RemoteEvents.RequestDailyBonus.OnServerEvent:Connect(function(player)
        self:ProcessDailyBonus(player)
    end)
    
    print("✅ AchievementService: Remote events connected")
end

-- Setup connections
function AchievementService:SetupConnections()
    -- Player management
    self.Connections.PlayerAdded = Players.PlayerAdded:Connect(function(player)
        self:OnPlayerAdded(player)
    end)
    
    self.Connections.PlayerRemoving = Players.PlayerRemoving:Connect(function(player)
        self:SavePlayerData(player)
    end)
end

function AchievementService:OnPlayerAdded(player)
    print("🏆 Loading achievement data for " .. player.Name)
    
    -- Load achievement data
    spawn(function()
        self:LoadPlayerAchievements(player)
        self:LoadPlayerDailyBonus(player)
        
        -- Send initial data to client
        self:SendAchievementData(player)
        
        -- Check for daily bonus after a brief delay
        wait(3)
        self:ProcessDailyBonus(player)
    end)
end

function AchievementService:LoadPlayerAchievements(player)
    local userId = tostring(player.UserId)
    local data = {}
    
    -- Try to load from DataStore
    local success, result = pcall(function()
        return achievementDataStore:GetAsync(userId)
    end)
    
    if success and result then
        data = result
    else
        -- Initialize new player data
        data = {
            achievements = {},
            statistics = {
                gamesPlayed = 0,
                totalCoinsEarned = 0,
                level = 1,
                fastFinishes = 0,
                perfectRuns = 0,
                dailyStreak = 0,
                uniquePlayersPlayed = 0,
                upgradesPurchased = 0
            }
        }
    end
    
    -- Ensure all achievements exist in player data
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
    print("✅ Loaded achievements for " .. player.Name)
end

function AchievementService:LoadPlayerDailyBonus(player)
    local userId = tostring(player.UserId)
    local data = {}
    
    local success, result = pcall(function()
        return dailyBonusDataStore:GetAsync(userId)
    end)
    
    if success and result then
        data = result
    else
        -- Initialize new daily bonus data
        data = {
            lastClaimDate = 0,
            currentStreak = 0,
            totalDaysClaimed = 0,
            lastStreakReset = 0
        }
    end
    
    playerDailyBonus[userId] = data
    print("✅ Loaded daily bonus data for " .. player.Name)
end

function AchievementService:SendAchievementData(player)
    local userId = tostring(player.UserId)
    local achievements = playerAchievements[userId]
    
    if not achievements then
        warn("❌ No achievement data for " .. player.Name)
        return
    end
    
    local data = {
        achievements = achievements.achievements,
        statistics = achievements.statistics,
        definitions = ACHIEVEMENTS,
        dailyBonus = playerDailyBonus[userId]
    }
    
    if self.RemoteEvents then
        self.RemoteEvents.AchievementDataUpdated:FireClient(player, data)
    end
end

function AchievementService:ProcessDailyBonus(player)
    local userId = tostring(player.UserId)
    local bonusData = playerDailyBonus[userId]
    
    if not bonusData then
        warn("❌ No daily bonus data for " .. player.Name)
        return
    end
    
    local currentTime = os.time()
    local currentDate = os.date("*t", currentTime).yday -- Day of year
    local lastDate = os.date("*t", bonusData.lastClaimDate).yday
    
    -- Check if player can claim daily bonus
    if bonusData.lastClaimDate == 0 or currentDate ~= lastDate then
        -- Player can claim bonus
        local daysSinceLastClaim = currentDate - lastDate
        
        if daysSinceLastClaim == 1 or bonusData.lastClaimDate == 0 then
            -- Consecutive day or first time
            bonusData.currentStreak = bonusData.currentStreak + 1
        elseif daysSinceLastClaim > 1 then
            -- Streak broken
            bonusData.currentStreak = 1
            bonusData.lastStreakReset = currentTime
        end
        
        -- Determine bonus based on streak
        local bonusDay = math.min(bonusData.currentStreak, 30) -- Cap at 30 days
        local bonus = DAILY_BONUSES[bonusDay] or DAILY_BONUSES[7] -- Default to weekly bonus
        
        -- Special bonuses for milestones
        if bonusDay == 14 then
            bonus = DAILY_BONUSES[14]
        elseif bonusDay == 30 then
            bonus = DAILY_BONUSES[30]
        elseif bonusDay > 7 then
            bonus = DAILY_BONUSES[7] -- Weekly bonus for 8+ days
        end
        
        -- Award the bonus
        self:AwardDailyBonus(player, bonus, bonusDay)
        
        -- Update data
        bonusData.lastClaimDate = currentTime
        bonusData.totalDaysClaimed = bonusData.totalDaysClaimed + 1
        
        -- Update daily streak achievement progress
        self:UpdatePlayerProgress(player, "dailyStreak", bonusData.currentStreak)
        
        -- Save data
        self:SavePlayerDailyBonus(player)
        
        print("✅ " .. player.Name .. " claimed daily bonus (Day " .. bonusDay .. ")")
    else
        print("⚠️ " .. player.Name .. " already claimed today's bonus")
    end
end

function AchievementService:AwardDailyBonus(player, bonus, day)
    -- Award coins
    if self.PlayerService and self.PlayerService.AddCoins then
        self.PlayerService:AddCoins(player, bonus.coins)
    elseif self.DataService then
        local playerData = self.DataService:GetPlayerData(player)
        if playerData then
            self.DataService:SetPlayerData(player, "coins", (playerData.coins or 0) + bonus.coins)
        end
    end
    
    -- Award XP if available
    if bonus.xp and self.PlayerService and self.PlayerService.AddXP then
        self.PlayerService:AddXP(player, bonus.xp)
    end
    
    -- Show popup to player
    if self.RemoteEvents then
        self.RemoteEvents.ShowDailyBonusPopup:FireClient(player, {
            day = day,
            coins = bonus.coins,
            xp = bonus.xp or 0,
            message = bonus.message,
            effect = bonus.effect
        })
    end
    
    -- Analytics tracking
    if self.AnalyticsService and self.AnalyticsService.LogEvent then
        self.AnalyticsService:LogEvent(player, "daily_bonus_claimed", {
            day = day,
            coins = bonus.coins,
            streak = playerDailyBonus[tostring(player.UserId)].currentStreak
        })
    end
end

function AchievementService:ClaimAchievementReward(player, achievementId)
    local userId = tostring(player.UserId)
    local achievements = playerAchievements[userId]
    
    if not achievements then
        warn("❌ No achievement data for " .. player.Name)
        return
    end
    
    local achievementProgress = achievements.achievements[achievementId]
    if not achievementProgress then
        warn("❌ Achievement " .. achievementId .. " not found for " .. player.Name)
        return
    end
    
    -- Check if achievement is completed but not claimed
    if not achievementProgress.completed then
        warn("⚠️ Achievement " .. achievementId .. " not completed for " .. player.Name)
        return
    end
    
    if achievementProgress.claimed then
        warn("⚠️ Achievement " .. achievementId .. " already claimed for " .. player.Name)
        return
    end
    
    -- Find achievement definition
    local achievementDef = nil
    for _, achievement in pairs(ACHIEVEMENTS) do
        if achievement.id == achievementId then
            achievementDef = achievement
            break
        end
    end
    
    if not achievementDef then
        warn("❌ Achievement definition not found: " .. achievementId)
        return
    end
    
    -- Award the reward
    local success = self:AwardReward(player, achievementDef.reward)
    
    if success then
        -- Mark as claimed
        achievementProgress.claimed = true
        achievementProgress.claimedDate = os.time()
        
        -- Save data
        self:SavePlayerAchievements(player)
        
        -- Notify client
        if self.RemoteEvents then
            self.RemoteEvents.AchievementClaimResult:FireClient(player, {
                success = true,
                achievementId = achievementId,
                reward = achievementDef.reward
            })
        end
        
        -- Analytics
        if self.AnalyticsService and self.AnalyticsService.LogEvent then
            self.AnalyticsService:LogEvent(player, "achievement_reward_claimed", {
                achievementId = achievementId,
                rewardType = achievementDef.reward.type,
                rewardAmount = achievementDef.reward.amount or 1
            })
        end
        
        print("✅ " .. player.Name .. " claimed reward for " .. achievementDef.name)
    else
        warn("❌ Failed to award reward for " .. achievementId .. " to " .. player.Name)
    end
end

function AchievementService:AwardReward(player, reward)
    if reward.type == "coins" then
        if self.PlayerService and self.PlayerService.AddCoins then
            return self.PlayerService:AddCoins(player, reward.amount)
        elseif self.DataService then
            local playerData = self.DataService:GetPlayerData(player)
            if playerData then
                self.DataService:SetPlayerData(player, "coins", (playerData.coins or 0) + reward.amount)
                return true
            end
        end
    elseif reward.type == "xp" then
        if self.PlayerService and self.PlayerService.AddXP then
            return self.PlayerService:AddXP(player, reward.amount)
        end
    elseif reward.type == "cosmetic" then
        -- Award cosmetic item (placeholder - would integrate with cosmetic system)
        if self.PlayerService and self.PlayerService.AwardCosmetic then
            return self.PlayerService:AwardCosmetic(player, reward.item)
        end
        -- For now, just acknowledge the cosmetic award
        print("🎨 " .. player.Name .. " earned cosmetic: " .. reward.name)
        return true
    end
    
    return false
end

function AchievementService:ShowAchievementUnlocked(player, achievement)
    if self.RemoteEvents then
        self.RemoteEvents.AchievementUnlocked:FireClient(player, achievement)
    end
    
    -- Analytics
    if self.AnalyticsService and self.AnalyticsService.LogEvent then
        self.AnalyticsService:LogEvent(player, "achievement_unlocked", {
            achievementId = achievement.id,
            category = achievement.category,
            rarity = achievement.rarity
        })
    end
    
    print("🏆 " .. player.Name .. " unlocked achievement: " .. achievement.name)
end

function AchievementService:UpdatePlayerProgress(player, statKey, newValue)
    -- Called by other services when player stats change
    local userId = tostring(player.UserId)
    local achievements = playerAchievements[userId]
    
    if not achievements then return end
    
    -- Update the statistic
    achievements.statistics[statKey] = newValue
    
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

function AchievementService:SavePlayerData(player)
    self:SavePlayerAchievements(player)
    self:SavePlayerDailyBonus(player)
end

function AchievementService:SavePlayerAchievements(player)
    local userId = tostring(player.UserId)
    local data = playerAchievements[userId]
    
    if not data then return end
    
    spawn(function()
        local success, error = pcall(function()
            achievementDataStore:SetAsync(userId, data)
        end)
        
        if not success then
            warn("❌ Failed to save achievement data for " .. player.Name .. ": " .. tostring(error))
        end
    end)
end

function AchievementService:SavePlayerDailyBonus(player)
    local userId = tostring(player.UserId)
    local data = playerDailyBonus[userId]
    
    if not data then return end
    
    spawn(function()
        local success, error = pcall(function()
            dailyBonusDataStore:SetAsync(userId, data)
        end)
        
        if not success then
            warn("❌ Failed to save daily bonus data for " .. player.Name .. ": " .. tostring(error))
        end
    end)
end

-- Get achievement definitions for UI
function AchievementService:GetAchievementDefinitions()
    return ACHIEVEMENTS
end

-- Get daily bonus definitions for UI
function AchievementService:GetDailyBonusDefinitions()
    return DAILY_BONUSES
end

-- Service-specific cleanup
function AchievementService:OnCleanup()
    -- Save all player data
    for playerId, _ in pairs(playerAchievements) do
        local player = Players:GetPlayerByUserId(playerId)
        if player then
            self:SavePlayerData(player)
        end
    end
    
    -- Clear cache
    playerAchievements = {}
    playerDailyBonus = {}
end

return AchievementService
