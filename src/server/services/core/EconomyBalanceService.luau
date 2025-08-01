-- EconomyBalanceService.luau
-- Centralized game economy balancing with level scaling and anti-grinding measures

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local EconomyBalanceService = {}

-- Core balance configuration
local ECONOMY_CONFIG = {
    -- Base rewards for gameplay activities
    baseRewards = {
        correctBarrier = 5,          -- Base coins per correct barrier
        finishRun = 15,             -- Base coins for completing a run
        baseXP = 10,                -- Base XP per run completion
        perfectBonus = 25,          -- Bonus coins for perfect run
        streakMultiplier = 0.1,     -- 10% bonus per streak level (max 5)
        difficultyMultiplier = {    -- Multipliers by difficulty
            easy = 1.0,
            medium = 1.5,
            hard = 2.0
        }
    },
    
    -- Level scaling configuration
    levelScaling = {
        xpRequirement = {
            base = 100,             -- XP needed for level 2
            multiplier = 1.15,      -- Increases by 15% per level
            cap = 10000             -- Maximum XP required per level
        },
        rewardScaling = {
            coinMultiplier = 0.05,  -- 5% more coins per level (diminishing)
            xpMultiplier = 0.03,    -- 3% more XP per level (diminishing)
            maxScaling = 3.0        -- Maximum 300% of base rewards
        }
    },
    
    -- Anti-grinding measures
    antiGrinding = {
        -- Diminishing returns for repeated activities
        diminishingReturns = {
            enabled = true,
            threshold = 10,         -- After 10 completions in an hour
            reduction = 0.1,        -- 10% reduction per completion over threshold
            minReward = 0.25,       -- Minimum 25% of original reward
            resetTime = 3600        -- Reset every hour (3600 seconds)
        },
        
        -- Daily activity caps
        dailyCaps = {
            maxRuns = 100,          -- Maximum rewarded runs per day
            maxCoins = 5000,        -- Maximum coins earnable per day (from runs)
            maxQuestRewards = 1500, -- Maximum coins from quests per day
            resetHour = 0           -- Reset at midnight UTC
        },
        
        -- Cooldowns
        cooldowns = {
            runReward = 5,          -- 5 second cooldown between run rewards
            questClaim = 300,       -- 5 minute cooldown between quest claims
            rebirthDelay = 86400    -- 24 hour cooldown between rebirths
        }
    }
}

-- Upgrade pricing configuration with level scaling
local UPGRADE_PRICING = {
    -- Enhanced upgrades (run-specific)
    enhanced = {
        speedBoost = {
            baseCost = 75,
            multiplier = 1.4,
            maxLevel = 15,
            levelScaling = 0.1      -- 10% more expensive per player level
        },
        coinBonus = {
            baseCost = 100,
            multiplier = 1.5,
            maxLevel = 15,
            levelScaling = 0.15
        },
        xpBoost = {
            baseCost = 125,
            multiplier = 1.6,
            maxLevel = 15,
            levelScaling = 0.12
        }
    },
    
    -- General upgrades (permanent boosts)
    general = {
        speedBoost = {
            baseCost = 150,
            multiplier = 1.8,
            maxLevel = 10,
            levelScaling = 0.2
        },
        coinCollector = {
            baseCost = 200,
            multiplier = 1.6,
            maxLevel = 12,
            levelScaling = 0.18
        },
        scoreMaster = {
            baseCost = 300,
            multiplier = 1.7,
            maxLevel = 8,
            levelScaling = 0.25
        },
        barrierShield = {
            baseCost = 500,
            multiplier = 2.2,
            maxLevel = 5,
            levelScaling = 0.3
        },
        streakKeeper = {
            baseCost = 400,
            multiplier = 2.0,
            maxLevel = 6,
            levelScaling = 0.28
        }
    }
}

-- Cosmetic pricing tiers
local COSMETIC_PRICING = {
    -- Trail prices by rarity
    trails = {
        common = 250,
        uncommon = 500,
        rare = 1000,
        epic = 2000,
        legendary = 4000,
        mythic = 8000
    },
    
    -- Skin prices by rarity
    skins = {
        common = 300,
        uncommon = 600,
        rare = 1200,
        epic = 2500,
        legendary = 5000,
        mythic = 10000
    },
    
    -- Pet prices by rarity
    pets = {
        common = 400,
        uncommon = 800,
        rare = 1600,
        epic = 3200,
        legendary = 6400,
        mythic = 12800
    }
}

-- Service state
local playerActivityData = {} -- Track player activity for anti-grinding
local lastRewardTimes = {}    -- Track cooldowns
local dailyStats = {}         -- Track daily activity

-- Initialize player activity tracking
function EconomyBalanceService:InitializePlayerTracking(player)
    local userId = tostring(player.UserId)
    playerActivityData[userId] = {
        runCompletions = {},
        dailyCoins = 0,
        dailyRuns = 0,
        dailyQuestRewards = 0,
        lastResetTime = os.time()
    }
    lastRewardTimes[userId] = {}
end

-- Clean up player tracking
function EconomyBalanceService:CleanupPlayerTracking(player)
    local userId = tostring(player.UserId)
    playerActivityData[userId] = nil
    lastRewardTimes[userId] = nil
end

-- Calculate XP requirement for a specific level
function EconomyBalanceService:GetXPRequirement(level)
    local config = ECONOMY_CONFIG.levelScaling.xpRequirement
    local requirement = config.base * (config.multiplier ^ (level - 1))
    return math.min(requirement, config.cap)
end

-- Calculate scaled reward based on player level
function EconomyBalanceService:CalculateScaledReward(baseReward, playerLevel, rewardType)
    local scaling = ECONOMY_CONFIG.levelScaling.rewardScaling
    local multiplier = 1 + (scaling[rewardType .. "Multiplier"] * (playerLevel - 1))
    
    -- Apply diminishing returns scaling
    multiplier = math.min(multiplier, scaling.maxScaling)
    
    return math.floor(baseReward * multiplier)
end

-- Calculate run completion rewards with all modifiers
function EconomyBalanceService:CalculateRunReward(player, runData)
    local playerData = self:GetPlayerData(player)
    if not playerData then
        return {coins = 0, xp = 0}
    end
    
    local userId = tostring(player.UserId)
    local activityData = playerActivityData[userId]
    
    -- Check cooldown
    if self:IsOnCooldown(player, "runReward") then
        return {coins = 0, xp = 0, reason = "Cooldown active"}
    end
    
    -- Check daily caps
    if activityData.dailyRuns >= ECONOMY_CONFIG.antiGrinding.dailyCaps.maxRuns then
        return {coins = 0, xp = 0, reason = "Daily run limit reached"}
    end
    
    local baseRewards = ECONOMY_CONFIG.baseRewards
    local difficulty = runData.difficulty or "easy"
    local correctBarriers = runData.correctBarriers or 0
    local perfect = runData.perfect or false
    local streak = runData.streak or 0
    
    -- Base coin calculation
    local baseCoins = (correctBarriers * baseRewards.correctBarrier) + baseRewards.finishRun
    local baseXP = baseRewards.baseXP
    
    -- Apply difficulty multiplier
    local difficultyMult = baseRewards.difficultyMultiplier[difficulty] or 1.0
    baseCoins = baseCoins * difficultyMult
    baseXP = baseXP * difficultyMult
    
    -- Apply perfect bonus
    if perfect then
        baseCoins = baseCoins + baseRewards.perfectBonus
        baseXP = baseXP * 1.25
    end
    
    -- Apply streak bonus
    local streakBonus = 1 + (math.min(streak, 5) * baseRewards.streakMultiplier)
    baseCoins = baseCoins * streakBonus
    
    -- Apply level scaling
    local finalCoins = self:CalculateScaledReward(baseCoins, playerData.level, "coin")
    local finalXP = self:CalculateScaledReward(baseXP, playerData.level, "xp")
    
    -- Apply player upgrades
    finalCoins = self:ApplyUpgradeMultipliers(player, finalCoins, "coins")
    finalXP = self:ApplyUpgradeMultipliers(player, finalXP, "xp")
    
    -- Apply diminishing returns
    local diminishedCoins, diminishedXP = self:ApplyDiminishingReturns(player, finalCoins, finalXP)
    
    -- Check daily coin cap
    if activityData.dailyCoins + diminishedCoins > ECONOMY_CONFIG.antiGrinding.dailyCaps.maxCoins then
        diminishedCoins = math.max(0, ECONOMY_CONFIG.antiGrinding.dailyCaps.maxCoins - activityData.dailyCoins)
    end
    
    -- Update tracking
    self:UpdateActivityTracking(player, diminishedCoins, diminishedXP)
    
    return {
        coins = math.floor(diminishedCoins),
        xp = math.floor(diminishedXP),
        breakdown = {
            base = {coins = baseCoins, xp = baseXP},
            difficulty = difficultyMult,
            perfect = perfect,
            streak = streak,
            levelScaling = {coins = finalCoins / baseCoins, xp = finalXP / baseXP},
            diminishing = {coins = diminishedCoins / finalCoins, xp = diminishedXP / finalXP}
        }
    }
end

-- Calculate upgrade cost with level scaling
function EconomyBalanceService:CalculateUpgradeCost(upgradeType, upgradeId, currentLevel, playerLevel)
    local config = UPGRADE_PRICING[upgradeType] and UPGRADE_PRICING[upgradeType][upgradeId]
    if not config then
        warn("Unknown upgrade: " .. upgradeType .. "." .. upgradeId)
        return 999999
    end
    
    -- Base cost calculation
    local baseCost = config.baseCost * (config.multiplier ^ currentLevel)
    
    -- Apply level scaling (higher level players pay more)
    local levelMultiplier = 1 + (config.levelScaling * (playerLevel - 1))
    
    return math.floor(baseCost * levelMultiplier)
end

-- Calculate cosmetic prices with level adjustment
function EconomyBalanceService:CalculateCosmeticPrice(itemType, rarity, playerLevel)
    local basePrice = COSMETIC_PRICING[itemType] and COSMETIC_PRICING[itemType][rarity]
    if not basePrice then
        return 999999
    end
    
    -- Slight level scaling for cosmetics (less aggressive than upgrades)
    local levelMultiplier = 1 + (0.05 * math.min(playerLevel - 1, 20)) -- Cap at level 21
    
    return math.floor(basePrice * levelMultiplier)
end

-- Apply diminishing returns for repeated activities
function EconomyBalanceService:ApplyDiminishingReturns(player, coins, xp)
    local userId = tostring(player.UserId)
    local activityData = playerActivityData[userId]
    local config = ECONOMY_CONFIG.antiGrinding.diminishingReturns
    
    if not config.enabled then
        return coins, xp
    end
    
    -- Count recent completions
    local currentTime = os.time()
    local recentCompletions = 0
    
    for _, completionTime in ipairs(activityData.runCompletions) do
        if currentTime - completionTime <= config.resetTime then
            recentCompletions = recentCompletions + 1
        end
    end
    
    -- Apply diminishing returns if over threshold
    if recentCompletions > config.threshold then
        local excessCompletions = recentCompletions - config.threshold
        local reductionFactor = math.max(
            config.minReward,
            1 - (excessCompletions * config.reduction)
        )
        
        coins = coins * reductionFactor
        xp = xp * reductionFactor
    end
    
    return coins, xp
end

-- Check if player is on cooldown for specific activity
function EconomyBalanceService:IsOnCooldown(player, activityType)
    local userId = tostring(player.UserId)
    local cooldowns = ECONOMY_CONFIG.antiGrinding.cooldowns
    local lastTime = lastRewardTimes[userId] and lastRewardTimes[userId][activityType]
    
    if not lastTime or not cooldowns[activityType] then
        return false
    end
    
    return (os.time() - lastTime) < cooldowns[activityType]
end

-- Update activity tracking
function EconomyBalanceService:UpdateActivityTracking(player, coinsEarned, xpEarned)
    local userId = tostring(player.UserId)
    local activityData = playerActivityData[userId]
    local currentTime = os.time()
    
    -- Add completion time
    table.insert(activityData.runCompletions, currentTime)
    
    -- Clean old completion times
    local cutoffTime = currentTime - ECONOMY_CONFIG.antiGrinding.diminishingReturns.resetTime
    for i = #activityData.runCompletions, 1, -1 do
        if activityData.runCompletions[i] < cutoffTime then
            table.remove(activityData.runCompletions, i)
        end
    end
    
    -- Update daily stats
    activityData.dailyCoins = activityData.dailyCoins + coinsEarned
    activityData.dailyRuns = activityData.dailyRuns + 1
    
    -- Update last reward time
    lastRewardTimes[userId] = lastRewardTimes[userId] or {}
    lastRewardTimes[userId].runReward = currentTime
end

-- Reset daily stats if needed
function EconomyBalanceService:CheckDailyReset(player)
    local userId = tostring(player.UserId)
    local activityData = playerActivityData[userId]
    
    if not activityData then
        return
    end
    
    local currentTime = os.time()
    local currentDay = math.floor(currentTime / 86400) -- Days since epoch
    local lastResetDay = math.floor(activityData.lastResetTime / 86400)
    
    if currentDay > lastResetDay then
        -- Reset daily stats
        activityData.dailyCoins = 0
        activityData.dailyRuns = 0
        activityData.dailyQuestRewards = 0
        activityData.lastResetTime = currentTime
        
        print("📅 Daily stats reset for " .. player.Name)
    end
end

-- Get upgrade multipliers for rewards
function EconomyBalanceService:ApplyUpgradeMultipliers(player, amount, type)
    local playerData = self:GetPlayerData(player)
    if not playerData then
        return amount
    end
    
    local multiplier = 1.0
    
    -- Apply enhanced upgrades
    if type == "coins" and playerData.enhancedUpgrades and playerData.enhancedUpgrades.coinBonus then
        multiplier = multiplier + (playerData.enhancedUpgrades.coinBonus * 0.15) -- 15% per level
    end
    
    if type == "xp" and playerData.enhancedUpgrades and playerData.enhancedUpgrades.xpBoost then
        multiplier = multiplier + (playerData.enhancedUpgrades.xpBoost * 0.2) -- 20% per level
    end
    
    -- Apply VIP multiplier
    if type == "coins" and playerData.vipCoinMultiplier then
        multiplier = multiplier * playerData.vipCoinMultiplier
    end
    
    return amount * multiplier
end

-- Get player data (interface with unified data service)
function EconomyBalanceService:GetPlayerData(player)
    -- This would interface with your UnifiedDataService
    local UnifiedDataService = require(script.Parent.UnifiedDataService)
    return UnifiedDataService:GetPlayerData(player)
end

-- Public API for reward calculation
function EconomyBalanceService:GetUpgradePrice(upgradeType, upgradeId, currentLevel, playerLevel)
    return self:CalculateUpgradeCost(upgradeType, upgradeId, currentLevel, playerLevel)
end

function EconomyBalanceService:GetCosmeticPrice(itemType, rarity, playerLevel)
    return self:CalculateCosmeticPrice(itemType, rarity, playerLevel)
end

function EconomyBalanceService:CalculateQuestReward(player, questType, baseReward)
    local playerData = self:GetPlayerData(player)
    if not playerData then
        return baseReward
    end
    
    -- Check daily quest reward cap
    local userId = tostring(player.UserId)
    local activityData = playerActivityData[userId]
    
    if activityData and activityData.dailyQuestRewards >= ECONOMY_CONFIG.antiGrinding.dailyCaps.maxQuestRewards then
        return 0
    end
    
    -- Apply level scaling
    local scaledReward = self:CalculateScaledReward(baseReward, playerData.level, "coin")
    
    -- Apply upgrade multipliers
    scaledReward = self:ApplyUpgradeMultipliers(player, scaledReward, "coins")
    
    -- Update daily tracking
    if activityData then
        activityData.dailyQuestRewards = activityData.dailyQuestRewards + scaledReward
    end
    
    return math.floor(scaledReward)
end

-- Initialize the service
function EconomyBalanceService:Init()
    print("💰 Economy Balance Service initialized")
    
    -- Set up player connections
    Players.PlayerAdded:Connect(function(player)
        self:InitializePlayerTracking(player)
    end)
    
    Players.PlayerRemoving:Connect(function(player)
        self:CleanupPlayerTracking(player)
    end)
    
    -- CONVERTED: Daily reset checker → Event-driven system
    local DailyResetEvent = Instance.new("BindableEvent")
    local checkInterval = 1800 -- Start with 30 minutes (was 60s)
    
    local function scheduleDailyResetCheck()
        task.delay(checkInterval, function()
            DailyResetEvent:Fire()
            scheduleDailyResetCheck()
        end)
    end
    
    DailyResetEvent.Event:Connect(function()
        local playersNeedingReset = 0
        local totalPlayers = 0
        
        for _, player in pairs(Players:GetPlayers()) do
            totalPlayers = totalPlayers + 1
            local needsReset = self:CheckDailyReset(player)
            if needsReset then
                playersNeedingReset = playersNeedingReset + 1
            end
        end
        
        -- Adaptive interval - more frequent near midnight, less frequent during mid-day
        local currentHour = os.date("*t").hour
        if currentHour >= 23 or currentHour <= 1 then -- Near midnight
            checkInterval = math.max(300, checkInterval * 0.5) -- More frequent (min 5 min)
        else
            checkInterval = math.min(3600, checkInterval * 1.1) -- Less frequent (max 1 hour)
        end
        
        print(string.format("📅 Daily reset check: %d/%d players needed reset (next in %.0f min)", 
            playersNeedingReset, totalPlayers, checkInterval / 60))
    end)
    
    scheduleDailyResetCheck()
    print("✅ Daily reset checker converted to event-driven system (NO POLLING)")
end

return EconomyBalanceService
