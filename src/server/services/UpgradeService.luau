-- UpgradeService.luau
-- Canonical upgrade service for managing Speed Boost, Coin Bonus, and XP Boost upgrades (Standardized Enhanced Service)
-- Consolidated from UpgradeService.luau and EnhancedUpgradeService.luau

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local DataStoreService = game:GetService("DataStoreService")
local TweenService = game:GetService("TweenService")

local Services = require(game.ReplicatedStorage.Shared.core.Services)
local WorldObjectValidator = require(game.ReplicatedStorage.Shared.utils.WorldObjectValidator)

local UpgradeService = {}

-- Define dependencies
UpgradeService.Dependencies = {
    { path = ReplicatedStorage.Shared.modules.RemoteEvents, name = "RemoteEvents", optional = false },
    { path = script.Parent.DataService, name = "DataService", optional = false },
    { path = script.Parent.PlayerService, name = "PlayerService", optional = true },
}

-- Service state
local connectionIds = {}
local upgradeStalls = {}
local playerUpgradeCache = {}

-- DataStore for upgrade data (fallback if DataService unavailable)
local upgradeDataStore = nil

-- Comprehensive upgrade definitions combining both services
local UPGRADE_DEFINITIONS = {
    speed_boost = {
        id = "speed_boost",
        name = "⚡ Speed Boost",
        description = "Increases movement speed during runs",
        category = "movement",
        maxLevel = 10,
        baseCost = 150,
        costMultiplier = 1.5,
        baseEffect = 0.1, -- 10% speed increase per level
        bonusPerLevel = 0.1,
        effectType = "speed_multiplier",
        icon = "⚡"
    },
    coin_bonus = {
        id = "coin_bonus", 
        name = "💰 Coin Collector",
        description = "Earn more coins from runs and activities",
        category = "economy",
        maxLevel = 10,
        baseCost = 100,
        costMultiplier = 1.6,
        baseEffect = 0.15, -- 15% coin bonus per level
        bonusPerLevel = 0.15,
        effectType = "bonus_coins",
        icon = "💰"
    },
    xp_boost = {
        id = "xp_boost",
        name = "📈 XP Boost", 
        description = "Gain more experience from all activities",
        category = "progression",
        maxLevel = 10,
        baseCost = 200,
        costMultiplier = 1.7,
        baseEffect = 0.2, -- 20% XP bonus per level
        bonusPerLevel = 0.2,
        effectType = "bonus_xp",
        icon = "📈"
    },
    jump_height = {
        id = "jump_height",
        name = "🦘 Jump Power",
        description = "Higher jumps for better navigation",
        category = "movement", 
        maxLevel = 5,
        baseCost = 250,
        costMultiplier = 1.4,
        baseEffect = 0.15, -- 15% jump boost per level
        bonusPerLevel = 0.15,
        effectType = "jump_multiplier",
        icon = "🦘"
    },
    luck_boost = {
        id = "luck_boost",
        name = "🍀 Lucky Streak",
        description = "Increased chance for bonus rewards",
        category = "economy",
        maxLevel = 8,
        baseCost = 300,
        costMultiplier = 1.8,
        baseEffect = 0.05, -- 5% luck boost per level
        bonusPerLevel = 0.05,
        effectType = "luck_multiplier", 
        icon = "🍀"
    }
}

--[[
    Initializes the UpgradeService. Validates world objects, sets up upgrade stalls,
    initializes data storage, and handles existing players.
    
    @return {void}
]]
function UpgradeService:OnInit()
    -- Validate required world objects for upgrade stalls
    local missingObjects = WorldObjectValidator.validateAllRequired()
    if #missingObjects > 0 then
        warn("⚠️ UpgradeService: Missing required world objects:")
        for _, missing in ipairs(missingObjects) do
            warn("  • " .. missing)
        end
    end
    
    -- Ensure Hub folder exists or can be created
    local hubExists, hubObject = WorldObjectValidator.validateObjectWithWait("workspace.Hub", 3)
    if not hubExists then
        warn("⚠️ UpgradeService: Hub folder not found, attempting to create...")
        WorldObjectValidator.createObjectIfMissing("workspace.Hub", "Folder", "workspace")
    else
        print("✅ UpgradeService: Hub folder validated")
    end
    
    -- Initialize DataStore fallback
    upgradeDataStore = DataStoreService:GetDataStore("PlayerUpgrades")
    
    -- Initialize player cache
    playerUpgradeCache = {}
    
    -- Load any existing players
    for _, player in pairs(Players:GetPlayers()) do
        self:HandlePlayerAdded(player)
    end
    
    return true
end

--[[
    Starts the UpgradeService by setting up physical upgrade stalls in the game world.
    
    @return {boolean} - True if service started successfully
]]
function UpgradeService:OnStart()
    -- Setup upgrade stalls in the world
    self:SetupUpgradeStalls()
    
    print("✅ UpgradeService started with", #UPGRADE_DEFINITIONS, "upgrade types")
    return true
end

--[[
    Sets up remote event connections for client-server communication.
    Handles upgrade purchases, data requests, and shop interactions.
    
    @return {void}
]]
function UpgradeService:SetupRemoteEvents()
    if self.RemoteEvents then
        -- Purchase upgrade
        local purchaseEvent = self.RemoteEvents:GetRemoteFunction("PurchaseUpgrade")
        if purchaseEvent then
            purchaseEvent.OnServerInvoke = function(player, upgradeId)
                return self:PurchaseUpgrade(player, upgradeId)
            end
        end
        
        -- Get upgrade data
        local upgradeDataEvent = self.RemoteEvents:GetRemoteFunction("GetUpgradeData")
        if upgradeDataEvent then
            upgradeDataEvent.OnServerInvoke = function(player)
                return self:GetPlayerUpgradeData(player)
            end
        end
        
        -- Open upgrade shop
        local openShopEvent = self.RemoteEvents:GetRemoteEvent("OpenUpgradeShop")
        if openShopEvent then
            openShopEvent.OnServerEvent:Connect(function(player)
                self:OpenUpgradeShop(player)
            end)
        end
    end
end

-- Setup connections
function UpgradeService:SetupConnections()
    -- Player management
    self.Connections.PlayerAdded = Players.PlayerAdded:Connect(function(player)
        self:HandlePlayerAdded(player)
    end)
    
    self.Connections.PlayerRemoving = Players.PlayerRemoving:Connect(function(player)
        self:HandlePlayerRemoving(player)
    end)
end

-- Setup upgrade stalls in the world
function UpgradeService:SetupUpgradeStalls()
    -- Wait for workspace to be ready
    game.Loaded:Wait()
    task.wait(1) -- UPDATED for modern API - Brief delay for character to fully load
    
    -- Validate and wait for Hub folder
    local hubObject = WorldObjectValidator.waitForObject("workspace.Hub", 10)
    if not hubObject then
        -- Try alternative locations
        hubObject = WorldObjectValidator.waitForObject("workspace.World", 5)
        if not hubObject then
            warn("⚠️ UpgradeService: No suitable parent found for upgrade stalls")
            return
        end
    end
    
    -- Create upgrade stalls
    self:CreateUpgradeStall(hubObject)
    print("✅ UpgradeService: Upgrade stalls setup completed")
end

-- Create upgrade stall in world
function UpgradeService:CreateUpgradeStall(parent)
    local existingStall = parent:FindFirstChild("UpgradeStall")
    if existingStall then
        return existingStall
    end
    
    -- Create upgrade stall model
    local stall = Instance.new("Model")
    stall.Name = "UpgradeStall"
    stall.Parent = parent
    
    -- Create base part
    local base = Instance.new("Part")
    base.Name = "Base"
    base.Size = Vector3.new(6, 1, 6)
    base.Position = Vector3.new(-25, 5, 15) -- Commerce district
    base.Anchored = true
    base.Material = Enum.Material.Neon
    base.BrickColor = BrickColor.new("Bright yellow")
    base.Parent = stall
    
    -- Create sign
    local sign = Instance.new("Part")
    sign.Name = "Sign"
    sign.Size = Vector3.new(4, 3, 0.2)
    sign.Position = base.Position + Vector3.new(0, 3, 0)
    sign.Anchored = true
    sign.Material = Enum.Material.SmoothPlastic
    sign.BrickColor = BrickColor.new("Dark stone grey")
    sign.Parent = stall
    
    -- Add sign text
    local signGui = Instance.new("SurfaceGui")
    signGui.Face = Enum.NormalId.Front
    signGui.Parent = sign
    
    local signLabel = Instance.new("TextLabel")
    signLabel.Size = UDim2.new(1, 0, 1, 0)
    signLabel.BackgroundTransparency = 1
    signLabel.Text = "⬆️ UPGRADES ⬆️\nClick to improve your abilities!"
    signLabel.TextColor3 = Color3.new(1, 1, 1)
    signLabel.TextScaled = true
    signLabel.Font = Enum.Font.SourceSansBold
    signLabel.Parent = signGui
    
    -- Create interaction detection
    local detector = Instance.new("Part")
    detector.Name = "ClickDetector"
    detector.Size = Vector3.new(8, 6, 8)
    detector.Position = base.Position + Vector3.new(0, 2, 0)
    detector.Anchored = true
    detector.Transparency = 1
    detector.CanCollide = false
    detector.Parent = stall
    
    local clickDetector = Instance.new("ClickDetector")
    clickDetector.MaxActivationDistance = 20
    clickDetector.Parent = detector
    
    clickDetector.MouseClick:Connect(function(player)
        self:OpenUpgradeShop(player)
    end)
    
    upgradeStalls[stall] = true
    print("✅ UpgradeService: Created upgrade stall")
    
    return stall
end

-- Handle player joining
function UpgradeService:HandlePlayerAdded(player)
    -- Initialize player upgrade data
    task.spawn(function() -- UPDATED for modern API
        self:LoadPlayerUpgrades(player)
        self:ApplyAllUpgrades(player)
    end)
end

-- Handle player leaving  
function UpgradeService:HandlePlayerRemoving(player)
    -- Save player upgrade data
    self:SavePlayerUpgrades(player)
    
    -- Clean up cache
    playerUpgradeCache[player.UserId] = nil
end

-- Load player upgrades from DataService or DataStore
function UpgradeService:LoadPlayerUpgrades(player)
    local upgrades = {}
    
    -- Try DataService first
    if self.DataService then
        local playerData = self.DataService:GetPlayerData(player)
        if playerData and playerData.upgrades then
            upgrades = playerData.upgrades
        end
    else
        -- Fallback to DataStore
        local success, data = pcall(function()
            return upgradeDataStore:GetAsync("Player_" .. player.UserId)
        end)
        
        if success and data then
            upgrades = data
        end
    end
    
    -- Ensure all upgrade types exist with default values
    for upgradeId, _ in pairs(UPGRADE_DEFINITIONS) do
        if not upgrades[upgradeId] then
            upgrades[upgradeId] = {
                level = 0,
                totalSpent = 0,
                purchaseCount = 0
            }
        end
    end
    
    playerUpgradeCache[player.UserId] = upgrades
    return upgrades
end

-- Save player upgrades to DataService or DataStore
function UpgradeService:SavePlayerUpgrades(player)
    local upgrades = playerUpgradeCache[player.UserId]
    if not upgrades then return end
    
    -- Try DataService first
    if self.DataService then
        self.DataService:SetPlayerData(player, "upgrades", upgrades)
    else
        -- Fallback to DataStore
        task.spawn(function() -- UPDATED for modern API
            local success, error = pcall(function()
                upgradeDataStore:SetAsync("Player_" .. player.UserId, upgrades)
            end)
            
            if not success then
                warn("❌ UpgradeService: Failed to save upgrades for " .. player.Name .. ": " .. tostring(error))
            end
        end)
    end
end

-- Get player upgrade data
function UpgradeService:GetPlayerUpgradeData(player)
    local upgrades = playerUpgradeCache[player.UserId] or self:LoadPlayerUpgrades(player)
    
    local data = {
        upgrades = upgrades,
        definitions = UPGRADE_DEFINITIONS,
        playerCoins = self:GetPlayerCoins(player)
    }
    
    return data
end

-- Get player coins (with fallback)
function UpgradeService:GetPlayerCoins(player)
    if self.DataService then
        local playerData = self.DataService:GetPlayerData(player)
        return playerData and playerData.coins or 0
    elseif self.PlayerService then
        return self.PlayerService:GetCoins(player) or 0
    else
        -- Fallback to leaderstats
        local leaderstats = player:FindFirstChild("leaderstats")
        local coins = leaderstats and leaderstats:FindFirstChild("Coins")
        return coins and coins.Value or 0
    end
end

-- Deduct player coins
function UpgradeService:DeductPlayerCoins(player, amount)
    if self.DataService then
        local playerData = self.DataService:GetPlayerData(player)
        if playerData and playerData.coins >= amount then
            self.DataService:SetPlayerData(player, "coins", playerData.coins - amount)
            return true
        end
    elseif self.PlayerService then
        return self.PlayerService:SpendCoins(player, amount)
    else
        -- Fallback to leaderstats
        local leaderstats = player:FindFirstChild("leaderstats")
        local coins = leaderstats and leaderstats:FindFirstChild("Coins")
        if coins and coins.Value >= amount then
            coins.Value = coins.Value - amount
            return true
        end
    end
    return false
end

-- Calculate upgrade cost
function UpgradeService:CalculateUpgradeCost(upgradeId, currentLevel, playerLevel)
    local upgrade = UPGRADE_DEFINITIONS[upgradeId]
    if not upgrade then return 0 end
    
    local cost = upgrade.baseCost * (upgrade.costMultiplier ^ currentLevel)
    
    -- Optional: Player level discount
    if playerLevel and playerLevel > 10 then
        local discount = math.min(0.2, (playerLevel - 10) * 0.01) -- Max 20% discount
        cost = cost * (1 - discount)
    end
    
    return math.floor(cost)
end

--[[
    Processes a player's upgrade purchase. Validates the upgrade, checks player's
    coins, deducts the cost, and updates the player's upgrade level.
    
    @param player {Player} - The player making the purchase
    @param upgradeId {string} - The ID of the upgrade to purchase
    @return {table} - Result table with success boolean and error message if failed
]]
function UpgradeService:PurchaseUpgrade(player, upgradeId)
    local upgrade = UPGRADE_DEFINITIONS[upgradeId]
    if not upgrade then
        return {success = false, error = "Invalid upgrade"}
    end
    
    local playerUpgrades = playerUpgradeCache[player.UserId] or self:LoadPlayerUpgrades(player)
    local currentLevel = playerUpgrades[upgradeId].level
    
    -- Check if max level reached
    if currentLevel >= upgrade.maxLevel then
        return {success = false, error = "Max level reached"}
    end
    
    -- Calculate cost
    local cost = self:CalculateUpgradeCost(upgradeId, currentLevel)
    local playerCoins = self:GetPlayerCoins(player)
    
    -- Check if player has enough coins
    if playerCoins < cost then
        return {success = false, error = "Not enough coins", cost = cost, has = playerCoins}
    end
    
    -- Deduct coins
    local deductSuccess = self:DeductPlayerCoins(player, cost)
    if not deductSuccess then
        return {success = false, error = "Failed to deduct coins"}
    end
    
    -- Apply upgrade
    playerUpgrades[upgradeId].level = currentLevel + 1
    playerUpgrades[upgradeId].totalSpent = (playerUpgrades[upgradeId].totalSpent or 0) + cost
    playerUpgrades[upgradeId].purchaseCount = (playerUpgrades[upgradeId].purchaseCount or 0) + 1
    
    -- Save immediately
    self:SavePlayerUpgrades(player)
    
    -- Apply effects
    self:ApplyUpgradeEffect(player, upgradeId, playerUpgrades[upgradeId].level)
    
    -- Notify quest system
    local ServiceRegistry = self:SafeRequire(ReplicatedStorage.Shared.utils.ServiceRegistry, "ServiceRegistry", true)
    if ServiceRegistry then
        local QuestService = ServiceRegistry:GetService("QuestService")
        if QuestService and QuestService.UpdateProgress then
            QuestService:UpdateProgress(player, "upgrades_purchased", 1)
        end
    end
    
    print("✅ " .. player.Name .. " purchased " .. upgrade.name .. " level " .. playerUpgrades[upgradeId].level)
    
    return {
        success = true,
        newLevel = playerUpgrades[upgradeId].level,
        newCoins = self:GetPlayerCoins(player),
        upgrade = upgrade
    }
end

-- Apply upgrade effect to player
function UpgradeService:ApplyUpgradeEffect(player, upgradeId, level)
    local upgrade = UPGRADE_DEFINITIONS[upgradeId]
    if not upgrade or level <= 0 then return end
    
    local character = player.Character
    if not character then return end
    
    local humanoid = character:FindFirstChild("Humanoid")
    if not humanoid then return end
    
    -- Apply effects based on upgrade type
    if upgradeId == "speed_boost" then
        local multiplier = 1 + (upgrade.baseEffect * level)
        humanoid.WalkSpeed = 16 * multiplier -- Base Roblox speed is 16
        
    elseif upgradeId == "jump_height" then
        local multiplier = 1 + (upgrade.baseEffect * level)
        humanoid.JumpPower = 50 * multiplier -- Base Roblox jump is 50
        
    end
    
    -- Other effects (coin_bonus, xp_boost, luck_boost) are applied during gameplay
end

-- Apply all upgrades to player
function UpgradeService:ApplyAllUpgrades(player)
    local playerUpgrades = playerUpgradeCache[player.UserId]
    if not playerUpgrades then return end
    
    -- Wait for character
    if not player.Character then
        player.CharacterAdded:Wait()
    end
    
    task.wait(1) -- UPDATED for modern API - Brief delay for character to fully load
    
    -- Apply each upgrade
    for upgradeId, upgradeData in pairs(playerUpgrades) do
        if upgradeData.level > 0 then
            self:ApplyUpgradeEffect(player, upgradeId, upgradeData.level)
        end
    end
end

-- Get upgrade multiplier for calculations
function UpgradeService:GetUpgradeMultiplier(player, upgradeId)
    local playerUpgrades = playerUpgradeCache[player.UserId]
    if not playerUpgrades then return 1 end
    
    local upgradeData = playerUpgrades[upgradeId]
    if not upgradeData or upgradeData.level <= 0 then return 1 end
    
    local upgrade = UPGRADE_DEFINITIONS[upgradeId]
    if not upgrade then return 1 end
    
    return 1 + (upgrade.baseEffect * upgradeData.level)
end

-- Convenience methods for common multipliers
function UpgradeService:GetCoinMultiplier(player)
    return self:GetUpgradeMultiplier(player, "coin_bonus")
end

function UpgradeService:GetXpMultiplier(player)
    return self:GetUpgradeMultiplier(player, "xp_boost")
end

function UpgradeService:GetSpeedMultiplier(player)
    return self:GetUpgradeMultiplier(player, "speed_boost")
end

function UpgradeService:GetLuckMultiplier(player)
    return self:GetUpgradeMultiplier(player, "luck_boost")
end

-- Open upgrade shop for player
function UpgradeService:OpenUpgradeShop(player)
    if self.RemoteEvents then
        local openShopEvent = self.RemoteEvents:GetRemoteEvent("OpenUpgradeShop")
        if openShopEvent then
            local upgradeData = self:GetPlayerUpgradeData(player)
            openShopEvent:FireClient(player, upgradeData)
        end
    end
end

-- Get upgrade statistics
function UpgradeService:GetUpgradeStatistics()
    local stats = {
        totalPlayers = 0,
        totalUpgrades = 0,
        upgradeBreakdown = {}
    }
    
    for upgradeId, _ in pairs(UPGRADE_DEFINITIONS) do
        stats.upgradeBreakdown[upgradeId] = {
            totalLevels = 0,
            uniqueOwners = 0,
            totalSpent = 0
        }
    end
    
    for playerId, upgrades in pairs(playerUpgradeCache) do
        stats.totalPlayers = stats.totalPlayers + 1
        
        for upgradeId, upgradeData in pairs(upgrades) do
            if upgradeData.level > 0 then
                stats.totalUpgrades = stats.totalUpgrades + upgradeData.level
                stats.upgradeBreakdown[upgradeId].totalLevels = stats.upgradeBreakdown[upgradeId].totalLevels + upgradeData.level
                stats.upgradeBreakdown[upgradeId].uniqueOwners = stats.upgradeBreakdown[upgradeId].uniqueOwners + 1
                stats.upgradeBreakdown[upgradeId].totalSpent = stats.upgradeBreakdown[upgradeId].totalSpent + (upgradeData.totalSpent or 0)
            end
        end
    end
    
    return stats
end

-- Get all upgrade definitions
function UpgradeService:GetUpgradeDefinitions()
    return UPGRADE_DEFINITIONS
end

-- Service-specific cleanup
function UpgradeService:OnCleanup()
    -- Save all player data
    for playerId, _ in pairs(playerUpgradeCache) do
        local player = Players:GetPlayerByUserId(playerId)
        if player then
            self:SavePlayerUpgrades(player)
        end
    end
    
    -- Clean up upgrade stalls
    for stall, _ in pairs(upgradeStalls) do
        if stall and stall.Parent then
            stall:Destroy()
        end
    end
    upgradeStalls = {}
    
    -- Clear cache
    playerUpgradeCache = {}
end

-- Register service with centralized Services module
Services.Register("UpgradeService", UpgradeService)

return UpgradeService
