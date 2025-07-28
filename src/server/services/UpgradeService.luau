-- UpgradeService.luau
-- Handles player upgrades using coins for gameplay buffs

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local DataStoreService = game:GetService("DataStoreService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local RemoteEvents = require(ReplicatedStorage.Shared.modules.RemoteEvents)
local PlayerService = require(script.Parent.PlayerService)

-- Forward declare QuestService to avoid circular dependency
local QuestService = nil

local UpgradeService = {}

-- DataStore for upgrade data
local upgradeDataStore = DataStoreService:GetDataStore("PlayerUpgrades")

-- Upgrade configuration with balanced progression and caps
local UPGRADES = {
    -- Speed Upgrades
    {
        id = "speed_boost",
        name = "⚡ Speed Boost",
        description = "Increases movement speed",
        category = "movement",
        maxLevel = 5,
        baseCost = 200,
        costMultiplier = 1.5,
        baseEffect = 0.1, -- 10% per level
        effectType = "speed_multiplier",
        icon = "⚡"
    },
    
    -- Coin Bonuses
    {
        id = "coin_bonus",
        name = "💰 Coin Collector",
        description = "Extra coins per correct barrier",
        category = "economy",
        maxLevel = 10,
        baseCost = 150,
        costMultiplier = 1.3,
        baseEffect = 1, -- +1 coin per level
        effectType = "bonus_coins",
        icon = "💰"
    },
    
    -- Score Multipliers
    {
        id = "score_multiplier",
        name = "🏆 Score Master",
        description = "Increases score gain from barriers",
        category = "scoring",
        maxLevel = 7,
        baseCost = 300,
        costMultiplier = 1.4,
        baseEffect = 0.15, -- 15% per level
        effectType = "score_multiplier",
        icon = "🏆"
    },
    
    -- Defensive Upgrades
    {
        id = "barrier_forgiveness",
        name = "🛡️ Barrier Shield",
        description = "Reduces score penalty from wrong barriers",
        category = "defense",
        maxLevel = 3,
        baseCost = 500,
        costMultiplier = 2.0,
        baseEffect = 0.25, -- 25% penalty reduction per level
        effectType = "penalty_reduction",
        icon = "🛡️"
    },
    
    -- Streak Bonuses
    {
        id = "streak_keeper",
        name = "🔥 Streak Keeper",
        description = "Maintains streaks longer after mistakes",
        category = "streak",
        maxLevel = 3,
        baseCost = 400,
        costMultiplier = 1.8,
        baseEffect = 1, -- +1 mistake forgiveness per level
        effectType = "streak_forgiveness",
        icon = "🔥"
    },
    
    -- Mystery Box Upgrades
    {
        id = "lucky_finder",
        name = "🍀 Lucky Finder",
        description = "Better rewards from Mystery Boxes",
        category = "luck",
        maxLevel = 5,
        baseCost = 350,
        costMultiplier = 1.6,
        baseEffect = 0.1, -- 10% better odds per level
        effectType = "mystery_luck",
        icon = "🍀"
    },
    
    -- Time Bonuses
    {
        id = "time_master",
        name = "⏱️ Time Master",
        description = "Slower barrier color changes",
        category = "timing",
        maxLevel = 4,
        baseCost = 600,
        costMultiplier = 1.7,
        baseEffect = 0.1, -- 10% slower changes per level
        effectType = "time_slowdown",
        icon = "⏱️"
    },
    
    -- Ghost Racing Upgrades
    {
        id = "ghost_hunter",
        name = "👻 Ghost Hunter",
        description = "Bonus coins for beating ghosts",
        category = "ghost",
        maxLevel = 3,
        baseCost = 450,
        costMultiplier = 1.9,
        baseEffect = 50, -- +50 coins per ghost victory per level
        effectType = "ghost_victory_bonus",
        icon = "👻"
    }
}

-- Player upgrade tracking
local playerUpgrades = {}

function UpgradeService:GetUpgradeCost(upgrade, currentLevel)
    if currentLevel >= upgrade.maxLevel then
        return nil -- Max level reached
    end
    
    return math.floor(upgrade.baseCost * (upgrade.costMultiplier ^ currentLevel))
end

function UpgradeService:GetUpgradeEffect(upgrade, level)
    return upgrade.baseEffect * level
end

function UpgradeService:LoadPlayerUpgrades(player)
    local userId = tostring(player.UserId)
    
    -- Try to load from DataStore
    local success, data = pcall(function()
        return upgradeDataStore:GetAsync(userId) or {}
    end)
    
    if not success then
        warn("Failed to load upgrade data for " .. player.Name)
        data = {}
    end
    
    -- Initialize default upgrade levels
    local upgrades = {}
    for _, upgrade in pairs(UPGRADES) do
        upgrades[upgrade.id] = data[upgrade.id] or 0
    end
    
    playerUpgrades[userId] = upgrades
    
    print("⚡ Loaded upgrades for " .. player.Name .. ": " .. self:GetUpgradeCount(player) .. " total levels")
    return upgrades
end

function UpgradeService:SavePlayerUpgrades(player)
    local userId = tostring(player.UserId)
    local upgrades = playerUpgrades[userId]
    
    if not upgrades then return false end
    
    local success = pcall(function()
        upgradeDataStore:SetAsync(userId, upgrades)
    end)
    
    if not success then
        warn("Failed to save upgrade data for " .. player.Name)
        return false
    end
    
    return true
end

function UpgradeService:GetPlayerUpgrades(player)
    local userId = tostring(player.UserId)
    return playerUpgrades[userId] or {}
end

function UpgradeService:GetUpgradeCount(player)
    local upgrades = self:GetPlayerUpgrades(player)
    local totalLevels = 0
    
    for _, level in pairs(upgrades) do
        totalLevels = totalLevels + level
    end
    
    return totalLevels
end

function UpgradeService:PurchaseUpgrade(player, upgradeId)
    local userId = tostring(player.UserId)
    local upgrades = playerUpgrades[userId]
    
    if not upgrades then
        warn("No upgrade data found for " .. player.Name)
        return false, "Upgrade data not loaded"
    end
    
    -- Find the upgrade
    local upgrade = nil
    for _, up in pairs(UPGRADES) do
        if up.id == upgradeId then
            upgrade = up
            break
        end
    end
    
    if not upgrade then
        return false, "Upgrade not found"
    end
    
    local currentLevel = upgrades[upgradeId] or 0
    
    -- Check if already at max level
    if currentLevel >= upgrade.maxLevel then
        return false, "Already at maximum level"
    end
    
    -- Calculate cost
    local cost = self:GetUpgradeCost(upgrade, currentLevel)
    
    -- Check if player has enough coins
    local playerData = PlayerService:GetPlayerData(player)
    if not playerData or playerData.coins < cost then
        return false, "Not enough coins"
    end
    
    -- Deduct coins
    playerData.coins = playerData.coins - cost
    PlayerService:UpdatePlayerData(player, playerData)
    
    -- Upgrade the level
    upgrades[upgradeId] = currentLevel + 1
    
    -- Save upgrades
    local saveSuccess = self:SavePlayerUpgrades(player)
    if not saveSuccess then
        -- Refund coins if save failed
        playerData.coins = playerData.coins + cost
        PlayerService:UpdatePlayerData(player, playerData)
        upgrades[upgradeId] = currentLevel -- Revert upgrade
        return false, "Failed to save upgrade data"
    end
    
    -- Update quest progress
    if QuestService then
        QuestService:UpdateQuestProgress(player, "upgrade_purchase", 1, {
            upgradeId = upgradeId,
            level = upgrades[upgradeId],
            cost = cost
        })
        
        -- Check if this upgrade reached max level
        if upgrades[upgradeId] >= upgrade.maxLevel then
            QuestService:UpdateQuestProgress(player, "max_upgrade_reached", 1, {
                upgradeId = upgradeId,
                maxLevelReached = true
            })
        end
    end
    
    -- Log to analytics
    if PlayerService and PlayerService.AnalyticsService then
        PlayerService.AnalyticsService:LogEvent(player, "upgrade_purchased", {
            upgradeId = upgradeId,
            level = upgrades[upgradeId],
            cost = cost,
            totalUpgrades = self:GetUpgradeCount(player)
        })
    end
    
    print("⚡ " .. player.Name .. " purchased " .. upgrade.name .. " level " .. upgrades[upgradeId] .. " for " .. cost .. " coins")
    
    return true, "Upgrade purchased successfully"
end

function UpgradeService:GetUpgradeList()
    local upgradeList = {}
    
    for _, upgrade in pairs(UPGRADES) do
        table.insert(upgradeList, {
            id = upgrade.id,
            name = upgrade.name,
            description = upgrade.description,
            category = upgrade.category,
            maxLevel = upgrade.maxLevel,
            baseCost = upgrade.baseCost,
            costMultiplier = upgrade.costMultiplier,
            baseEffect = upgrade.baseEffect,
            effectType = upgrade.effectType,
            icon = upgrade.icon
        })
    end
    
    return upgradeList
end

function UpgradeService:GetPlayerUpgradeEffects(player)
    local upgrades = self:GetPlayerUpgrades(player)
    local effects = {}
    
    for _, upgrade in pairs(UPGRADES) do
        local level = upgrades[upgrade.id] or 0
        if level > 0 then
            effects[upgrade.effectType] = (effects[upgrade.effectType] or 0) + self:GetUpgradeEffect(upgrade, level)
        end
    end
    
    return effects
end

function UpgradeService:ApplyUpgradeEffects(player, baseValue, effectType)
    local effects = self:GetPlayerUpgradeEffects(player)
    local modifier = effects[effectType] or 0
    
    if effectType == "speed_multiplier" or effectType == "score_multiplier" then
        return baseValue * (1 + modifier)
    elseif effectType == "bonus_coins" then
        return baseValue + modifier
    elseif effectType == "penalty_reduction" then
        return baseValue * (1 - math.min(modifier, 0.75)) -- Cap at 75% reduction
    elseif effectType == "time_slowdown" then
        return baseValue * (1 + modifier)
    elseif effectType == "ghost_victory_bonus" then
        return baseValue + modifier
    end
    
    return baseValue
end

function UpgradeService:SetupUpgradeStall()
    local success, error = pcall(function()
        local marketPlaza = Workspace:FindFirstChild("MarketPlaza")
        if not marketPlaza then
            warn("⚠️ MarketPlaza not found in Workspace!")
            return
        end
        
        local upgradeStall = marketPlaza:FindFirstChild("UpgradeStall")
        if not upgradeStall then
            warn("⚠️ Upgrade stall not found in MarketPlaza!")
            return
        end
        
        local stallPanel = upgradeStall:FindFirstChild("StallPanel")
        if not stallPanel then 
            warn("⚠️ StallPanel not found in UpgradeStall!")
            return 
        end
    
    -- Add floating title
    local billboardGui = Instance.new("BillboardGui")
    billboardGui.Size = UDim2.new(0, 400, 0, 80)
    billboardGui.StudsOffset = Vector3.new(0, 4, 0)
    billboardGui.Parent = stallPanel
    
    local titleLabel = Instance.new("TextLabel")
    titleLabel.Size = UDim2.new(1, 0, 1, 0)
    titleLabel.BackgroundTransparency = 1
    titleLabel.Text = "⚡ UPGRADES"
    titleLabel.TextColor3 = Color3.new(1, 0.8, 0.2)
    titleLabel.TextScaled = true
    titleLabel.Font = Enum.Font.SourceSansBold
    titleLabel.TextStrokeTransparency = 0
    titleLabel.TextStrokeColor3 = Color3.new(0, 0, 0)
    titleLabel.Parent = billboardGui
    
    -- Add floating animation
    local floatTween = TweenService:Create(
        billboardGui,
        TweenInfo.new(3, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true),
        {StudsOffset = Vector3.new(0, 5, 0)}
    )
    floatTween:Play()
    
    -- Add glow effect
    local pointLight = Instance.new("PointLight")
    pointLight.Color = Color3.new(1, 0.8, 0.2)
    pointLight.Brightness = 2
    pointLight.Range = 10
    pointLight.Parent = stallPanel
end

function UpgradeService:Initialize()
    print("⚡ UpgradeService initializing...")
    
    -- Wait for workspace to be ready
    wait(1)
    
    -- Setup upgrade stall display
    self:SetupUpgradeStall()
    
    -- Find and setup click detector with error handling
    local success, error = pcall(function()
        local marketPlaza = Workspace:FindFirstChild("MarketPlaza")
        if not marketPlaza then
            warn("⚠️ MarketPlaza not found for click detector setup!")
            return
        end
        
        local upgradeStall = marketPlaza:FindFirstChild("UpgradeStall")
        if upgradeStall then
            local clickDetector = upgradeStall:FindFirstChild("ClickDetector")
            if clickDetector then
                clickDetector.MouseClick:Connect(function(player)
                    local upgrades = self:GetPlayerUpgrades(player)
                    local upgradeList = self:GetUpgradeList()
                RemoteEvents.ShowUpgradeShop:FireClient(player, upgradeList, upgrades)
            end)
            print("⚡ Upgrade stall click detector connected")
        else
            warn("⚠️ ClickDetector not found in upgrade stall!")
        end
    else
        warn("⚠️ Upgrade stall not found in MarketPlaza!")
    end
    
    print("✅ UpgradeService initialized successfully!")
end

-- Handle player joining
local function onPlayerAdded(player)
    spawn(function()
        wait(2) -- Wait for player to fully load
        UpgradeService:LoadPlayerUpgrades(player)
    end)
end

-- Connect events
Players.PlayerAdded:Connect(onPlayerAdded)

-- Remote event handlers
RemoteEvents.PurchaseUpgrade.OnServerEvent:Connect(function(player, upgradeId)
    local success, message = UpgradeService:PurchaseUpgrade(player, upgradeId)
    RemoteEvents.UpgradePurchaseResult:FireClient(player, success, message, upgradeId)
    
    if success then
        -- Send updated upgrade data
        local upgrades = UpgradeService:GetPlayerUpgrades(player)
        local upgradeList = UpgradeService:GetUpgradeList()
        RemoteEvents.UpdateUpgradeData:FireClient(player, upgradeList, upgrades)
    end
end)

function UpgradeService:SetQuestService(questService)
    QuestService = questService
end

-- Auto-initialize when required
UpgradeService:Initialize()

return UpgradeService
