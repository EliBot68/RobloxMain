-- RebirthService.luau
-- Handles player rebirth system with balanced progression and anti-grinding measures

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local SafeRequire = require(ReplicatedStorage.Shared.utils.SafeRequire)
local WorldObjectValidator = SafeRequire.require(ReplicatedStorage.Shared.utils.WorldObjectValidator)

local RebirthService = {}

-- Forward declare services
local EconomyBalanceService = nil
local PlayerService = nil

-- Enhanced rebirth configuration with stricter requirements
local REBIRTH_CONFIG = {
    [1] = {
        levelRequired = 25,        -- Increased from 15
        timeRequired = 86400,      -- 24 hours since last rebirth
        coinBonus = 0.15,         -- Reduced bonuses for balance
        xpBonus = 0.10,
        crateOddsBonus = 0.05,
        auraEffect = "Bronze",
        unlocks = {"Bronze Aura", "Faster Coins I", "XP Boost I"},
        specialReward = "Bronze Runner Trail",
        rebirthCoins = 300,       -- Reduced bonus coins
        requirements = {
            totalXP = 2500,        -- Must have earned this much total XP
            totalCoins = 10000,    -- Must have earned this many coins lifetime
            perfectRuns = 5        -- Must have completed 5 perfect runs
        }
    },
    [2] = {
        levelRequired = 50,        -- Increased from 35
        timeRequired = 172800,     -- 48 hours since last rebirth
        coinBonus = 0.30,         -- 30% total (was 50%)
        xpBonus = 0.20,           -- 20% total (was 30%)
        crateOddsBonus = 0.12,    -- 12% total (was 20%)
        auraEffect = "Silver", 
        unlocks = {"Silver Aura", "Faster Coins II", "Lucky Crates I", "XP Boost II"},
        specialReward = "Silver Lightning Trail",
        rebirthCoins = 750,
        ghostSpeedBonus = 0.08,    -- Reduced from 10%
        requirements = {
            totalXP = 7500,
            totalCoins = 35000,
            perfectRuns = 15,
            hardModeCompletes = 10  -- Must complete hard mode 10 times
        }
    },
    [3] = {
        levelRequired = 80,        -- Increased from 60
        timeRequired = 259200,     -- 72 hours since last rebirth
        coinBonus = 0.50,         -- 50% total (was 85%)
        xpBonus = 0.35,           -- 35% total (was 50%)
        crateOddsBonus = 0.20,    -- 20% total (was 35%)
        auraEffect = "Gold",
        unlocks = {"Gold Aura", "Faster Coins III", "Lucky Crates II", "XP Boost III"},
        specialReward = "Golden Phoenix Trail",
        rebirthCoins = 1500,      -- Reduced from 2500
        ghostSpeedBonus = 0.15,
        barrierTimeBonus = 0.10,  -- Reduced from 15%
        requirements = {
            totalXP = 20000,
            totalCoins = 100000,
            perfectRuns = 50,
            hardModeCompletes = 35,
            streakRecord = 25      -- Must achieve 25+ streak
        }
    },
    [4] = {
        levelRequired = 120,       -- Significantly increased from 90
        timeRequired = 432000,     -- 120 hours (5 days) since last rebirth
        coinBonus = 0.75,         -- 75% total (was 125%)
        xpBonus = 0.55,           -- 55% total (was 75%)
        crateOddsBonus = 0.30,    -- 30% total (was 50%)
        auraEffect = "Diamond",
        unlocks = {"Diamond Aura", "Faster Coins IV", "Lucky Crates III", "XP Boost IV", "VIP Features"},
        specialReward = "Diamond Frost Trail",
        rebirthCoins = 5000,
        ghostSpeedBonus = 0.35,
        barrierTimeBonus = 0.25,
        perfectRunBonus = 0.50 -- 50% bonus coins for perfect runs
    },
    [5] = {
        levelRequired = 125,
        coinBonus = 1.75, -- 175% faster coin gain (total)
        xpBonus = 1.0, -- 100% faster XP gain (total)
        crateOddsBonus = 0.75, -- 75% better crate odds (total)
        auraEffect = "Rainbow",
        unlocks = {"Rainbow Aura", "Faster Coins V", "Lucky Crates IV", "XP Boost V", "Perfect Runner"},
        specialReward = "Rainbow Cosmic Trail",
        rebirthCoins = 10000,
        ghostSpeedBonus = 0.50,
        barrierTimeBonus = 0.40,
        perfectRunBonus = 0.75,
        rareDropBonus = 0.25 -- 25% chance for rare item drops
    },
    [6] = {
        levelRequired = 175,
        coinBonus = 2.5, -- 250% faster coin gain (total)
        xpBonus = 1.5, -- 150% faster XP gain (total)
        crateOddsBonus = 1.0, -- 100% better crate odds (total)
        auraEffect = "Cosmic",
        unlocks = {"Cosmic Aura", "Faster Coins VI", "Lucky Crates V", "XP Boost VI", "Legendary Luck"},
        specialReward = "Cosmic Void Trail",
        rebirthCoins = 20000,
        ghostSpeedBonus = 0.75,
        barrierTimeBonus = 0.60,
        perfectRunBonus = 1.0,
        rareDropBonus = 0.50,
        exclusiveUnlock = "Cosmic Pet Egg"
    },
    [7] = {
        levelRequired = 250,
        coinBonus = 3.5, -- 350% faster coin gain (total)
        xpBonus = 2.0, -- 200% faster XP gain (total)
        crateOddsBonus = 1.5, -- 150% better crate odds (total)
        auraEffect = "Transcendent",
        unlocks = {"Transcendent Aura", "Faster Coins VII", "Lucky Crates VI", "XP Boost VII", "Master Runner"},
        specialReward = "Transcendent Wings Trail",
        rebirthCoins = 50000,
        ghostSpeedBonus = 1.0,
        barrierTimeBonus = 0.80,
        perfectRunBonus = 1.5,
        rareDropBonus = 0.75,
        exclusiveUnlock = "Transcendent Crown",
        prestigePoints = 1 -- New currency for prestige shop
    },
    [8] = {
        levelRequired = 350,
        coinBonus = 5.0, -- 500% faster coin gain (total)
        xpBonus = 3.0, -- 300% faster XP gain (total)
        crateOddsBonus = 2.0, -- 200% better crate odds (total)
        auraEffect = "Mythical",
        unlocks = {"Mythical Aura", "Faster Coins VIII", "Lucky Crates VII", "XP Boost VIII", "Barrier Master"},
        specialReward = "Mythical Dragon Trail",
        rebirthCoins = 100000,
        ghostSpeedBonus = 1.5,
        barrierTimeBonus = 1.0,
        perfectRunBonus = 2.0,
        rareDropBonus = 1.0,
        exclusiveUnlock = "Mythical Dragon Pet",
        prestigePoints = 2,
        weeklyBonusChest = true -- Weekly bonus crate
    },
    [9] = {
        levelRequired = 500,
        coinBonus = 7.5, -- 750% faster coin gain (total)
        xpBonus = 4.0, -- 400% faster XP gain (total)
        crateOddsBonus = 3.0, -- 300% better crate odds (total)
        auraEffect = "Celestial",
        unlocks = {"Celestial Aura", "Faster Coins IX", "Lucky Crates VIII", "XP Boost IX", "Time Master"},
        specialReward = "Celestial Galaxy Trail",
        rebirthCoins = 250000,
        ghostSpeedBonus = 2.0,
        barrierTimeBonus = 1.25,
        perfectRunBonus = 3.0,
        rareDropBonus = 1.5,
        exclusiveUnlock = "Celestial Wings",
        prestigePoints = 3,
        weeklyBonusChest = true,
        infiniteEnergy = true -- Never lose energy
    },
    [10] = {
        levelRequired = 750,
        coinBonus = 10.0, -- 1000% faster coin gain (total)
        xpBonus = 5.0, -- 500% faster XP gain (total)
        crateOddsBonus = 5.0, -- 500% better crate odds (total)
        auraEffect = "Infinite",
        unlocks = {"Infinite Aura", "Faster Coins X", "Lucky Crates IX", "XP Boost X", "Infinite Runner"},
        specialReward = "Infinite Reality Trail",
        rebirthCoins = 500000,
        ghostSpeedBonus = 3.0,
        barrierTimeBonus = 1.5,
        perfectRunBonus = 5.0,
        rareDropBonus = 2.0,
        exclusiveUnlock = "Infinite Crown & Throne",
        prestigePoints = 5,
        weeklyBonusChest = true,
        infiniteEnergy = true,
        godMode = true -- Ultimate rebirth achievement
    }
}

-- Services
local DataService = require(script.Parent.DataService)
local AnalyticsService = require(script.Parent.AnalyticsService)

-- Remote events
local rebirthRemote = Instance.new("RemoteEvent")
rebirthRemote.Name = "RebirthRemote"
rebirthRemote.Parent = ReplicatedStorage

local checkRebirthRemote = Instance.new("RemoteFunction")
checkRebirthRemote.Name = "CheckRebirthRemote"
checkRebirthRemote.Parent = ReplicatedStorage

function RebirthService:CanRebirth(player)
    local playerData = self:GetPlayerData(player)
    if not playerData then 
        return false, "No player data found" 
    end
    
    local currentRebirths = playerData.rebirths or 0
    local nextRebirthLevel = currentRebirths + 1
    
    -- Check if there's a next rebirth available
    if not REBIRTH_CONFIG[nextRebirthLevel] then
        return false, "Maximum rebirths reached"
    end
    
    local config = REBIRTH_CONFIG[nextRebirthLevel]
    
    -- Check level requirement
    if playerData.level < config.levelRequired then
        return false, "Level " .. config.levelRequired .. " required (you are level " .. playerData.level .. ")", config.levelRequired
    end
    
    -- Check time requirement (cooldown)
    local lastRebirthTime = playerData.lastRebirthTime or 0
    local timeSinceLastRebirth = os.time() - lastRebirthTime
    
    if timeSinceLastRebirth < config.timeRequired then
        local hoursRemaining = math.ceil((config.timeRequired - timeSinceLastRebirth) / 3600)
        return false, "Must wait " .. hoursRemaining .. " more hours since last rebirth"
    end
    
    -- Check additional requirements if they exist
    if config.requirements then
        local reqs = config.requirements
        
        -- Check total XP earned
        if reqs.totalXP and (playerData.totalXpEarned or 0) < reqs.totalXP then
            return false, "Need " .. reqs.totalXP .. " total XP earned (you have " .. (playerData.totalXpEarned or 0) .. ")"
        end
        
        -- Check total coins earned
        if reqs.totalCoins and (playerData.totalCoinsEarned or 0) < reqs.totalCoins then
            return false, "Need " .. reqs.totalCoins .. " total coins earned (you have " .. (playerData.totalCoinsEarned or 0) .. ")"
        end
        
        -- Check perfect runs
        if reqs.perfectRuns and (playerData.perfectGames or 0) < reqs.perfectRuns then
            return false, "Need " .. reqs.perfectRuns .. " perfect runs (you have " .. (playerData.perfectGames or 0) .. ")"
        end
        
        -- Check hard mode completions
        if reqs.hardModeCompletes then
            local hardCompletes = playerData.difficultyStats and playerData.difficultyStats.hard and playerData.difficultyStats.hard.completions or 0
            if hardCompletes < reqs.hardModeCompletes then
                return false, "Need " .. reqs.hardModeCompletes .. " hard mode completions (you have " .. hardCompletes .. ")"
            end
        end
        
        -- Check streak record
        if reqs.streakRecord and (playerData.longestStreak or 0) < reqs.streakRecord then
            return false, "Need a " .. reqs.streakRecord .. "+ streak record (your best is " .. (playerData.longestStreak or 0) .. ")"
        end
    end
    
    return true, "Ready for rebirth", config
end

-- Enhanced rebirth validation with comprehensive checks
function RebirthService:ValidateRebirthAttempt(player)
    -- Check if player is currently in a game
    if self:IsPlayerInGame(player) then
        return false, "Cannot rebirth while in a game"
    end
    
    -- Check for abuse patterns
    local playerData = self:GetPlayerData(player)
    if playerData and playerData.rebirthAttempts then
        local recentAttempts = 0
        local cutoffTime = os.time() - 3600 -- Last hour
        
        for _, attemptTime in ipairs(playerData.rebirthAttempts) do
            if attemptTime > cutoffTime then
                recentAttempts = recentAttempts + 1
            end
        end
        
        if recentAttempts > 5 then
            return false, "Too many rebirth attempts. Please wait before trying again."
        end
    end
    
    return self:CanRebirth(player)
end

-- Helper function to check if player is in game
function RebirthService:IsPlayerInGame(player)
    -- This would check with your game track service
    local GameTrackService = require(script.Parent.GameTrackService)
    return GameTrackService:IsPlayerInGame(player)
end

-- Get player data with fallback
function RebirthService:GetPlayerData(player)
    if PlayerService then
        return PlayerService:GetPlayerData(player)
    end
    
    -- Fallback to DataService
    local DataService = require(script.Parent.core.DataService)
    return DataService:GetPlayerData(player)
end

function RebirthService:PerformRebirth(player)
    local canRebirth, message, config = self:CanRebirth(player)
    if not canRebirth then
        return false, message
    end
    
    local playerData = DataService:GetPlayerData(player)
    if not playerData then return false, "No player data found" end
    
    -- Store pre-rebirth stats for analytics
    local preRebirthStats = {
        level = playerData.level,
        totalCoinsEarned = playerData.totalCoinsEarned,
        gamesPlayed = playerData.gamesPlayed,
        highScore = playerData.highScore
    }
    
    -- Reset progress but keep certain things
    local preservedData = {
        -- Keep permanent progress
        rebirths = (playerData.rebirths or 0) + 1,
        rebirthBonuses = playerData.rebirthBonuses or {},
        
        -- Keep cosmetics and pets
        ownedSkins = playerData.ownedSkins,
        ownedTrails = playerData.ownedTrails,
        ownedPets = playerData.ownedPets,
        activePet = playerData.activePet,
        petStats = playerData.petStats,
        
        -- Keep achievements and goals
        completedGoals = playerData.completedGoals,
        claimedGoalRewards = playerData.claimedGoalRewards,
        
        -- Keep monetization
        ownedGamepasses = playerData.ownedGamepasses,
        totalPurchases = playerData.totalPurchases,
        totalRobuxSpent = playerData.totalRobuxSpent,
        
        -- Keep social features
        scoresShared = playerData.scoresShared,
        
        -- Keep settings and tutorial
        settings = playerData.settings,
        tutorialCompleted = playerData.tutorialCompleted,
        joinDate = playerData.joinDate
    }
    
    -- Add new rebirth bonuses
    local newRebirthLevel = preservedData.rebirths
    local rebirthConfig = REBIRTH_CONFIG[newRebirthLevel]
    
    -- Update all bonus multipliers
    preservedData.rebirthBonuses.coinMultiplier = 1 + rebirthConfig.coinBonus
    preservedData.rebirthBonuses.xpBonus = rebirthConfig.xpBonus or 0
    preservedData.rebirthBonuses.crateOddsBonus = rebirthConfig.crateOddsBonus
    preservedData.rebirthBonuses.ghostSpeedBonus = rebirthConfig.ghostSpeedBonus or 0
    preservedData.rebirthBonuses.barrierTimeBonus = rebirthConfig.barrierTimeBonus or 0
    preservedData.rebirthBonuses.perfectRunBonus = rebirthConfig.perfectRunBonus or 0
    preservedData.rebirthBonuses.rareDropBonus = rebirthConfig.rareDropBonus or 0
    preservedData.rebirthBonuses.auraEffect = rebirthConfig.auraEffect
    preservedData.rebirthBonuses.unlocks = rebirthConfig.unlocks
    
    -- Add special features for higher rebirths
    if rebirthConfig.weeklyBonusChest then
        preservedData.rebirthBonuses.weeklyBonusChest = true
    end
    if rebirthConfig.infiniteEnergy then
        preservedData.rebirthBonuses.infiniteEnergy = true
    end
    if rebirthConfig.godMode then
        preservedData.rebirthBonuses.godMode = true
    end
    
    -- Add prestige points
    if rebirthConfig.prestigePoints then
        preservedData.prestigePoints = (preservedData.prestigePoints or 0) + rebirthConfig.prestigePoints
    end
    
    -- Add rebirth coins
    preservedData.rebirthCoinBalance = (preservedData.rebirthCoinBalance or 0) + rebirthConfig.rebirthCoins
    
    -- Add rebirth aura to owned cosmetics
    local rebirthAura = rebirthConfig.auraEffect .. " Aura"
    if not preservedData.ownedTrails then
        preservedData.ownedTrails = {}
    end
    if not table.find(preservedData.ownedTrails, rebirthAura) then
        table.insert(preservedData.ownedTrails, rebirthAura)
    end
    
    -- Reset to default data and merge preserved data
    local newData = {}
    for key, value in pairs(require(script.Parent.DataService).DEFAULT_DATA) do
        newData[key] = value
    end
    
    -- Apply preserved data
    for key, value in pairs(preservedData) do
        newData[key] = value
    end
    
    -- Set special rebirth starting bonuses
    newData.coins = 1000 * newRebirthLevel -- Start with more coins based on rebirth level
    newData.experience = 0
    newData.level = 1
    newData.highScore = 0 -- Reset high score for new challenge
    newData.totalBarriersPassed = 0
    newData.gamesPlayed = 0
    
    -- Save the new data
    local saveSuccess = DataService:SavePlayerData(player, newData)
    if not saveSuccess then
        return false, "Failed to save rebirth data"
    end
    
    -- Track rebirth analytics
    AnalyticsService:TrackEvent(player, "rebirth_completed", {
        rebirthLevel = newRebirthLevel,
        preRebirthLevel = preRebirthStats.level,
        preRebirthCoins = preRebirthStats.totalCoinsEarned,
        auraUnlocked = rebirthAura,
        coinMultiplier = preservedData.rebirthBonuses.coinMultiplier
    })
    
    -- Notify AuraService to refresh player's aura
    local AuraService = require(script.Parent.AuraService)
    spawn(function()
        wait(2) -- Wait for client to receive rebirth notification
        AuraService:RefreshPlayerAura(player)
    end)
    
    return true, "Rebirth successful!", {
        rebirthLevel = newRebirthLevel,
        auraUnlocked = rebirthAura,
        coinBonus = rebirthConfig.coinBonus,
        crateOddsBonus = rebirthConfig.crateOddsBonus,
        unlocks = rebirthConfig.unlocks
    }
end

function RebirthService:GetRebirthInfo(player)
    local playerData = DataService:GetPlayerData(player)
    if not playerData then return nil end
    
    local currentRebirths = playerData.rebirths or 0
    local nextRebirthLevel = currentRebirths + 1
    
    local info = {
        currentRebirths = currentRebirths,
        nextRebirthLevel = nextRebirthLevel,
        currentBonuses = playerData.rebirthBonuses or {},
        canRebirth = false,
        nextRequirement = nil,
        nextRewards = nil
    }
    
    if REBIRTH_CONFIG[nextRebirthLevel] then
        local config = REBIRTH_CONFIG[nextRebirthLevel]
        info.canRebirth = playerData.level >= config.levelRequired
        info.nextRequirement = config.levelRequired
        info.nextRewards = {
            coinBonus = config.coinBonus,
            crateOddsBonus = config.crateOddsBonus,
            auraEffect = config.auraEffect,
            unlocks = config.unlocks
        }
    end
    
    return info
end

function RebirthService:GetCoinMultiplier(player)
    local playerData = DataService:GetPlayerData(player)
    if not playerData or not playerData.rebirthBonuses then
        return 1
    end
    
    local baseMultiplier = playerData.rebirthBonuses.coinMultiplier or 1
    local vipMultiplier = playerData.vipCoinMultiplier or 1
    
    return baseMultiplier * vipMultiplier
end

function RebirthService:GetCrateOddsBonus(player)
    local playerData = DataService:GetPlayerData(player)
    if not playerData or not playerData.rebirthBonuses then
        return 0
    end
    
    return playerData.rebirthBonuses.crateOddsBonus or 0
end

function RebirthService:GetPlayerAura(player)
    local playerData = DataService:GetPlayerData(player)
    if not playerData or not playerData.rebirthBonuses then
        return nil
    end
    
    return playerData.rebirthBonuses.auraEffect
end

-- Enhanced rebirth bonus functions
function RebirthService:GetXPMultiplier(player)
    local playerData = DataService:GetPlayerData(player)
    if not playerData or not playerData.rebirthBonuses then
        return 1
    end
    
    return 1 + (playerData.rebirthBonuses.xpBonus or 0)
end

function RebirthService:GetGhostSpeedBonus(player)
    local playerData = DataService:GetPlayerData(player)
    if not playerData or not playerData.rebirthBonuses then
        return 0
    end
    
    return playerData.rebirthBonuses.ghostSpeedBonus or 0
end

function RebirthService:GetBarrierTimeBonus(player)
    local playerData = DataService:GetPlayerData(player)
    if not playerData or not playerData.rebirthBonuses then
        return 0
    end
    
    return playerData.rebirthBonuses.barrierTimeBonus or 0
end

function RebirthService:GetPerfectRunBonus(player)
    local playerData = DataService:GetPlayerData(player)
    if not playerData or not playerData.rebirthBonuses then
        return 0
    end
    
    return playerData.rebirthBonuses.perfectRunBonus or 0
end

function RebirthService:GetRareDropBonus(player)
    local playerData = DataService:GetPlayerData(player)
    if not playerData or not playerData.rebirthBonuses then
        return 0
    end
    
    return playerData.rebirthBonuses.rareDropBonus or 0
end

function RebirthService:GetPrestigePoints(player)
    local playerData = DataService:GetPlayerData(player)
    if not playerData then
        return 0
    end
    
    return playerData.prestigePoints or 0
end

function RebirthService:HasInfiniteEnergy(player)
    local playerData = DataService:GetPlayerData(player)
    if not playerData or not playerData.rebirthBonuses then
        return false
    end
    
    return playerData.rebirthBonuses.infiniteEnergy == true
end

function RebirthService:HasGodMode(player)
    local playerData = DataService:GetPlayerData(player)
    if not playerData or not playerData.rebirthBonuses then
        return false
    end
    
    return playerData.rebirthBonuses.godMode == true
end

function RebirthService:HasWeeklyBonusChest(player)
    local playerData = DataService:GetPlayerData(player)
    if not playerData or not playerData.rebirthBonuses then
        return false
    end
    
    return playerData.rebirthBonuses.weeklyBonusChest == true
end

function RebirthService:GetRebirthMilestones(player)
    local playerData = DataService:GetPlayerData(player)
    local rebirths = playerData and playerData.rebirths or 0
    
    local milestones = {
        {name = "First Rebirth", threshold = 1, achieved = rebirths >= 1, reward = "Bronze Status"},
        {name = "Veteran Rebirther", threshold = 3, achieved = rebirths >= 3, reward = "Gold Status"},
        {name = "Master Rebirther", threshold = 5, achieved = rebirths >= 5, reward = "Diamond Status"},
        {name = "Legendary Rebirther", threshold = 7, achieved = rebirths >= 7, reward = "Legendary Status"},
        {name = "Transcendent Being", threshold = 10, achieved = rebirths >= 10, reward = "Infinite Status"}
    }
    
    return milestones
end

function RebirthService:GetRebirthLeaderboard()
    -- This would typically query a leaderboard datastore
    -- For now, return a mock leaderboard structure
    return {
        {player = "TopRebirther", rebirths = 10, aura = "Infinite"},
        {player = "LegendaryRunner", rebirths = 8, aura = "Mythical"},
        {player = "MasterPlayer", rebirths = 6, aura = "Cosmic"},
        {player = "ProRunner", rebirths = 4, aura = "Diamond"},
        {player = "VeteranPlayer", rebirths = 3, aura = "Gold"}
    }
end

function RebirthService:CalculateNextRebirthRecommendation(player)
    local playerData = DataService:GetPlayerData(player)
    if not playerData then return nil end
    
    local currentRebirths = playerData.rebirths or 0
    local nextRebirthLevel = currentRebirths + 1
    local nextConfig = REBIRTH_CONFIG[nextRebirthLevel]
    
    if not nextConfig then
        return {
            isMaxRebirth = true,
            message = "🎉 You've achieved the maximum rebirth level! You are truly Infinite!"
        }
    end
    
    local levelGap = nextConfig.levelRequired - playerData.level
    local timeEstimate = math.max(1, math.ceil(levelGap / 3)) -- Rough estimate: 3 levels per hour
    
    return {
        isMaxRebirth = false,
        levelGap = levelGap,
        timeEstimate = timeEstimate,
        recommendation = levelGap <= 5 and "Ready to rebirth soon!" or 
                        levelGap <= 15 and "Getting close to next rebirth!" or 
                        "Focus on leveling up first.",
        nextRewards = {
            coinBonus = nextConfig.coinBonus,
            specialReward = nextConfig.specialReward,
            rebirthCoins = nextConfig.rebirthCoins
        }
    }
end

-- Remote event handlers
rebirthRemote.OnServerEvent:Connect(function(player)
    local success, message, rebirthData = RebirthService:PerformRebirth(player)
    
    if success then
        -- Notify client of successful rebirth
        rebirthRemote:FireClient(player, "success", message, rebirthData)
    else
        -- Notify client of failed rebirth
        rebirthRemote:FireClient(player, "failed", message)
    end
end)

checkRebirthRemote.OnServerInvoke = function(player)
    return RebirthService:GetRebirthInfo(player)
end

function RebirthService:Init()
    print("🔄 RebirthService initializing...")
    
    -- Validate rebirth-related world objects
    print("🔍 Validating rebirth world objects...")
    local missingObjects = WorldObjectValidator.validateAllRequired()
    if #missingObjects > 0 then
        warn("⚠️ RebirthService: Missing required world objects:")
        for _, missing in ipairs(missingObjects) do
            warn("  • " .. missing)
        end
    end
    
    -- Validate rebirth statue
    local rebirthStatueExists = WorldObjectValidator.validateObjectWithWait("workspace.Hub.RebirthStatue", 5)
    if not rebirthStatueExists then
        warn("⚠️ RebirthService: RebirthStatue not found - rebirth interface may not work")
    else
        print("✅ RebirthService: RebirthStatue validated")
    end
    
    print("✅ RebirthService initialized")
end

return RebirthService
