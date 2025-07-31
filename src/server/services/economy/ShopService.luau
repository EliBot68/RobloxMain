-- ShopService.luau
-- Handles the Skins & Trails shop functionality

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local GameConstants = require(ReplicatedStorage.Shared.constants.GameConstants)
local RemoteEvents = require(ReplicatedStorage.Shared.modules.RemoteEvents)
local PlayerService = require(script.Parent.Parent.core.PlayerService)

-- Forward declare QuestService to avoid circular dependency
local QuestService = nil

local ShopService = {}

-- Shop items configuration - SOFT LAUNCH BALANCED PRICES
local SKIN_ITEMS = {
    {
        id = "classic_red",
        name = "Classic Red",
        price = 100, -- Increased from 50
        color = Color3.new(1, 0.2, 0.2),
        category = "skin"
    },
    {
        id = "ocean_blue",
        name = "Ocean Blue",
        price = 150, -- Increased from 75
        color = Color3.new(0.2, 0.4, 1),
        category = "skin"
    },
    {
        id = "forest_green",
        name = "Forest Green",
        price = 150, -- Increased from 75
        color = Color3.new(0.2, 0.8, 0.2),
        category = "skin"
    },
    {
        id = "golden_yellow",
        name = "Golden Yellow",
        price = 250, -- Increased from 100
        color = Color3.new(1, 0.9, 0.1),
        category = "skin"
    },
    {
        id = "royal_purple",
        name = "Royal Purple",
        price = 350, -- Increased from 125
        color = Color3.new(0.8, 0.2, 0.8),
        category = "skin"
    },
    {
        id = "midnight_black",
        name = "Midnight Black",
        price = 500, -- Increased from 150
        color = Color3.new(0.1, 0.1, 0.1),
        category = "skin"
    },
    -- Mystery-exclusive skins (not purchasable directly)
    {
        id = "pewter_gray",
        name = "Pewter Gray",
        price = 999999, -- Not directly purchasable
        color = Color3.new(0.6, 0.6, 0.6),
        category = "skin",
        mysteryOnly = true
    },
    {
        id = "warm_brown",
        name = "Warm Brown",
        price = 999999,
        color = Color3.new(0.6, 0.4, 0.2),
        category = "skin",
        mysteryOnly = true
    },
    {
        id = "soft_pink",
        name = "Soft Pink",
        price = 999999,
        color = Color3.new(1, 0.7, 0.8),
        category = "skin",
        mysteryOnly = true
    },
    {
        id = "electric_cyan",
        name = "Electric Cyan",
        price = 999999,
        color = Color3.new(0, 1, 1),
        category = "skin",
        mysteryOnly = true
    },
    {
        id = "sunset_orange",
        name = "Sunset Orange",
        price = 999999,
        color = Color3.new(1, 0.5, 0),
        category = "skin",
        mysteryOnly = true
    },
    {
        id = "emerald_green",
        name = "Emerald Green",
        price = 999999,
        color = Color3.new(0, 0.8, 0.2),
        category = "skin",
        mysteryOnly = true
    },
    {
        id = "galaxy_purple",
        name = "Galaxy Purple",
        price = 999999,
        color = Color3.new(0.5, 0, 1),
        category = "skin",
        mysteryOnly = true
    },
    {
        id = "platinum_silver",
        name = "Platinum Silver",
        price = 999999,
        color = Color3.new(0.9, 0.9, 1),
        category = "skin",
        mysteryOnly = true
    },
    {
        id = "crimson_red",
        name = "Crimson Red",
        price = 999999,
        color = Color3.new(0.8, 0, 0),
        category = "skin",
        mysteryOnly = true
    },
    -- Level milestone reward skins (not purchasable)
    {
        id = "veteran_bronze",
        name = "Veteran Bronze",
        price = 999999,
        color = Color3.new(0.8, 0.5, 0.2),
        category = "skin",
        levelReward = 5
    },
    {
        id = "seasoned_silver",
        name = "Seasoned Silver",
        price = 999999,
        color = Color3.new(0.8, 0.8, 0.9),
        category = "skin",
        levelReward = 15
    },
    {
        id = "expert_gold",
        name = "Expert Gold",
        price = 999999,
        color = Color3.new(1, 0.8, 0.1),
        category = "skin",
        levelReward = 35
    },
    {
        id = "master_platinum",
        name = "Master Platinum",
        price = 999999,
        color = Color3.new(0.9, 0.95, 1),
        category = "skin",
        levelReward = 75
    },
    {
        id = "grandmaster_rainbow",
        name = "Grandmaster Rainbow",
        price = 999999,
        color = Color3.new(1, 0.5, 1),
        category = "skin",
        levelReward = 100
    }
}

local TRAIL_ITEMS = {
    {
        id = "fire_trail",
        name = "Fire Trail",
        price = 300, -- Increased from 200 for better progression
        color = Color3.new(1, 0.4, 0.1),
        category = "trail",
        effect = "fire"
    },
    {
        id = "ice_trail",
        name = "Ice Trail",
        price = 400, -- Increased from 250 for balanced economy
        color = Color3.new(0.7, 0.9, 1),
        category = "trail",
        effect = "ice"
    },
    {
        id = "lightning_trail",
        name = "Lightning Trail",
        price = 600, -- Increased from 300 for premium feel
        color = Color3.new(1, 1, 0.2),
        category = "trail",
        effect = "lightning"
    },
    {
        id = "rainbow_trail",
        name = "Rainbow Trail",
        price = 1000, -- Increased from 500 for ultimate luxury
        color = Color3.new(1, 0.5, 1),
        category = "trail",
        effect = "rainbow"
    },
    -- Mystery-exclusive trails (not purchasable directly)
    {
        id = "sparkle_trail",
        name = "Sparkle Trail",
        price = 999999, -- Not directly purchasable
        color = Color3.new(1, 1, 0.8),
        category = "trail",
        effect = "sparkle",
        mysteryOnly = true
    },
    {
        id = "bubble_trail",
        name = "Bubble Trail",
        price = 999999,
        color = Color3.new(0.7, 0.9, 1),
        category = "trail",
        effect = "bubble",
        mysteryOnly = true
    },
    {
        id = "leaf_trail",
        name = "Leaf Trail",
        price = 999999,
        color = Color3.new(0.4, 0.8, 0.2),
        category = "trail",
        effect = "leaf",
        mysteryOnly = true
    },
    {
        id = "mystic_trail",
        name = "Mystic Trail",
        price = 999999,
        color = Color3.new(0.8, 0.4, 1),
        category = "trail",
        effect = "mystic",
        mysteryOnly = true
    },
    {
        id = "thunder_trail",
        name = "Thunder Trail",
        price = 999999,
        color = Color3.new(1, 1, 0.3),
        category = "trail",
        effect = "thunder",
        mysteryOnly = true
    },
    {
        id = "crystal_trail",
        name = "Crystal Trail",
        price = 999999,
        color = Color3.new(0.8, 1, 1),
        category = "trail",
        effect = "crystal",
        mysteryOnly = true
    },
    {
        id = "phoenix_trail",
        name = "Phoenix Trail",
        price = 999999,
        color = Color3.new(1, 0.3, 0),
        category = "trail",
        effect = "phoenix",
        mysteryOnly = true
    },
    {
        id = "shadow_trail",
        name = "Shadow Trail",
        price = 999999,
        color = Color3.new(0.2, 0.2, 0.2),
        category = "trail",
        effect = "shadow",
        mysteryOnly = true
    },
    {
        id = "divine_trail",
        name = "Divine Trail",
        price = 999999,
        color = Color3.new(1, 1, 0.5),
        category = "trail",
        effect = "divine",
        mysteryOnly = true
    },
    -- Level milestone reward trails (not purchasable)
    {
        id = "experience_trail",
        name = "Experience Trail",
        price = 999999,
        color = Color3.new(0.2, 0.8, 1),
        category = "trail",
        effect = "experience",
        levelReward = 10
    },
    {
        id = "mastery_trail",
        name = "Mastery Trail",
        price = 999999,
        color = Color3.new(1, 0.8, 0.2),
        category = "trail",
        effect = "mastery",
        levelReward = 25
    },
    {
        id = "legend_trail",
        name = "Legendary Trail",
        price = 999999,
        color = Color3.new(1, 0.2, 0.8),
        category = "trail",
        effect = "legendary",
        levelReward = 50
    },
    {
        id = "grandmaster_trail",
        name = "Grandmaster Trail",
        price = 999999,
        color = Color3.new(1, 1, 0.5),
        category = "trail",
        effect = "grandmaster",
        levelReward = 100
    }
}

-- Monetization Items (Gamepasses and Developer Products)
local MONETIZATION_ITEMS = {
    -- Gamepasses
    {
        id = "gamepass_double_coins",
        name = "💰 Double Coins",
        price = 99, -- Robux
        description = "Permanently doubles all coin rewards from runs!",
        category = "gamepass",
        icon = "💰",
        gamepassId = 123456789, -- Replace with actual gamepass ID
        permanentBoost = true,
        multiplier = 2.0
    },
    {
        id = "gamepass_vip_trail",
        name = "✨ VIP Trail",
        price = 149, -- Robux
        description = "Unlock exclusive VIP rainbow trail with sparkle effects!",
        category = "gamepass",
        icon = "✨",
        gamepassId = 987654321, -- Replace with actual gamepass ID
        cosmetic = true,
        trailEffect = "VIPRainbow"
    },
    -- Developer Products
    {
        id = "product_coins_100",
        name = "💰 100 Coins Pack",
        price = 25, -- Robux
        description = "Instantly get 100 coins to spend in the shop!",
        category = "product",
        icon = "💰",
        productId = 111222333, -- Replace with actual product ID
        consumable = true,
        coinAmount = 100
    },
    {
        id = "product_crate_key",
        name = "🗝️ Unlock Crate Key",
        price = 50, -- Robux
        description = "Get a special key to unlock mystery crates for free!",
        category = "product",
        icon = "🗝️",
        productId = 444555666, -- Replace with actual product ID
        consumable = true,
        keyAmount = 1
    }
}

local UPGRADE_ITEMS = {
    {
        id = "speed_boost_1",
        name = "Speed Boost Level 1",
        price = 100,
        category = "upgrade",
        upgradeType = "speed",
        level = 1,
        description = "Increase movement speed by 15%"
    },
    {
        id = "speed_boost_2",
        name = "Speed Boost Level 2",
        price = 200,
        category = "upgrade",
        upgradeType = "speed",
        level = 2,
        description = "Increase movement speed by 30%",
        requires = "speed_boost_1"
    },
    {
        id = "speed_boost_3",
        name = "Speed Boost Level 3",
        price = 400,
        category = "upgrade",
        upgradeType = "speed",
        level = 3,
        description = "Increase movement speed by 50%",
        requires = "speed_boost_2"
    },
    {
        id = "coin_magnet_1",
        name = "Coin Magnet Level 1",
        price = 200,
        category = "upgrade",
        upgradeType = "coinMagnet",
        level = 1,
        description = "Attract coins from 3 studs away"
    },
    {
        id = "coin_magnet_2",
        name = "Coin Magnet Level 2",
        price = 400,
        category = "upgrade",
        upgradeType = "coinMagnet",
        level = 2,
        description = "Attract coins from 5 studs away",
        requires = "coin_magnet_1"
    },
    {
        id = "double_coins_1",
        name = "Double Coins",
        price = 500,
        category = "upgrade",
        upgradeType = "doubleCoins",
        level = 1,
        description = "Earn 2x coins from all sources"
    }
}

function ShopService:GetShopItems()
    local allItems = {}
    
    -- Add skins (excluding mystery-only items and level rewards)
    for _, item in pairs(SKIN_ITEMS) do
        if not item.mysteryOnly and not item.levelReward then
            table.insert(allItems, item)
        end
    end
    
    -- Add trails (excluding mystery-only items and level rewards)
    for _, item in pairs(TRAIL_ITEMS) do
        if not item.mysteryOnly and not item.levelReward then
            table.insert(allItems, item)
        end
    end
    
    -- Add upgrades
    for _, item in pairs(UPGRADE_ITEMS) do
        table.insert(allItems, item)
    end
    
    -- Add monetization items (gamepasses and products)
    for _, item in pairs(MONETIZATION_ITEMS) do
        table.insert(allItems, item)
    end
    
    return allItems
end

function ShopService:GetAllItems()
    -- Returns all items including mystery-only items
    local allItems = {}
    
    -- Add all skins
    for _, item in pairs(SKIN_ITEMS) do
        table.insert(allItems, item)
    end
    
    -- Add all trails
    for _, item in pairs(TRAIL_ITEMS) do
        table.insert(allItems, item)
    end
    
    -- Add upgrades
    for _, item in pairs(UPGRADE_ITEMS) do
        table.insert(allItems, item)
    end
    
    return allItems
end

function ShopService:GetItemData(itemId)
    -- Find item data by ID
    local allItems = self:GetAllItems()
    
    for _, item in pairs(allItems) do
        if item.id == itemId then
            return item
        end
    end
    
    return nil
end

function ShopService:PurchaseItem(player, itemId)
    local playerData = PlayerService:GetPlayerData(player)
    if not playerData then
        return false, "Player data not found"
    end
    
    -- Find the item
    local item = nil
    local allItems = self:GetShopItems()
    
    for _, shopItem in pairs(allItems) do
        if shopItem.id == itemId then
            item = shopItem
            break
        end
    end
    
    if not item then
        return false, "Item not found"
    end
    
    -- Handle monetization items (gamepasses and dev products)
    if item.category == "gamepass" or item.category == "product" then
        return self:HandleMonetizationPurchase(player, itemId)
    end
    
    -- Check if player already owns it
    if item.category == "skin" then
        if playerData.ownedSkins and playerData.ownedSkins[itemId] then
            return false, "Already owned"
        end
    elseif item.category == "trail" then
        if playerData.ownedTrails and playerData.ownedTrails[itemId] then
            return false, "Already owned"
        end
    elseif item.category == "upgrade" then
        -- Check if upgrade is already owned
        if playerData.ownedUpgrades and playerData.ownedUpgrades[itemId] then
            return false, "Already owned"
        end
        
        -- Check prerequisites for upgrades
        if item.requires then
            if not playerData.ownedUpgrades or not playerData.ownedUpgrades[item.requires] then
                return false, "Requires previous upgrade level"
            end
        end
    end
    
    -- Check if player has enough coins
    if playerData.coins < item.price then
        return false, "Not enough coins"
    end
    
    -- Initialize owned items if needed
    if not playerData.ownedSkins then
        playerData.ownedSkins = {}
    end
    if not playerData.ownedTrails then
        playerData.ownedTrails = {}
    end
    if not playerData.ownedUpgrades then
        playerData.ownedUpgrades = {}
    end
    
    -- Deduct coins and add item
    playerData.coins = playerData.coins - item.price
    
    if item.category == "skin" then
        playerData.ownedSkins[itemId] = true
        if not playerData.equippedSkin then
            playerData.equippedSkin = itemId
        end
    elseif item.category == "trail" then
        playerData.ownedTrails[itemId] = true
        if not playerData.equippedTrail then
            playerData.equippedTrail = itemId
        end
    elseif item.category == "upgrade" then
        playerData.ownedUpgrades[itemId] = true
        
        -- Apply upgrade immediately
        self:ApplyUpgrade(player, item)
        
        -- Update the upgrade level in player data
        if not playerData.upgrades then
            playerData.upgrades = {}
        end
        playerData.upgrades[item.upgradeType] = item.level
    end
    
    -- Update player data and save immediately (purchases are critical)
    PlayerService:UpdatePlayerData(player, playerData)
    
    -- Track quest progress
    if QuestService then
        if item.category == "upgrade" then
            QuestService:UpdateQuestProgress(player, "upgrade_purchase", 1)
        else
            QuestService:UpdateQuestProgress(player, "cosmetic_purchase", 1)
        end
    end
    
    -- Apply cosmetics if it's a cosmetic item
    if item.category == "skin" or item.category == "trail" then
        self:ApplyPlayerCosmetics(player)
    end
    
    print("💰 " .. player.Name .. " purchased " .. item.name .. " for " .. item.price .. " coins")
    return true, "Purchase successful"
end

function ShopService:HandleMonetizationPurchase(player, itemId)
    -- Handle gamepass and developer product purchases
    local item = nil
    
    -- Find the monetization item
    for _, monetizationItem in pairs(MONETIZATION_ITEMS) do
        if monetizationItem.id == itemId then
            item = monetizationItem
            break
        end
    end
    
    if not item then
        return false, "Item not found"
    end
    
    -- Create purchase confirmation data
    local purchaseData = {
        type = item.category, -- "gamepass" or "product"
        key = item.category == "gamepass" and 
            (item.id == "gamepass_double_coins" and "doubleCoins" or "vipTrail") or
            (item.id == "product_coins_100" and "coins100Pack" or "crateKey"),
        name = item.name,
        description = item.description,
        price = item.price,
        icon = item.icon,
        itemId = itemId
    }
    
    -- Send confirmation request to client
    RemoteEvents.ShowPurchaseConfirmation:FireClient(player, purchaseData)
    
    return true, "Purchase confirmation shown"
end

function ShopService:ApplyUpgrade(player, upgradeItem)
    local character = player.Character
    if not character then
        return
    end
    
    local humanoid = character:FindFirstChild("Humanoid")
    if not humanoid then
        return
    end
    
    if upgradeItem.upgradeType == "speed" then
        -- Apply speed boost
        local baseSpeed = 16 -- Default Roblox walkspeed
        local speedMultiplier = 1 + (upgradeItem.level * 0.15) -- 15% per level
        local newSpeed = baseSpeed * speedMultiplier
        
        humanoid.WalkSpeed = newSpeed
        print("⚡ Applied Speed Boost Level " .. upgradeItem.level .. " to " .. player.Name .. " (Speed: " .. newSpeed .. ")")
        
    elseif upgradeItem.upgradeType == "coinMagnet" then
        -- Apply coin magnet effect - this would need to be handled in GameService
        local magnetRange = 3 + (upgradeItem.level * 2) -- 3 studs base + 2 per level
        
        -- Store magnet range in player data for GameService to use
        local playerData = PlayerService:GetPlayerData(player)
        if playerData then
            playerData.magnetRange = magnetRange
            PlayerService:UpdatePlayerData(player, playerData)
        end
        
        print("🧲 Applied Coin Magnet Level " .. upgradeItem.level .. " to " .. player.Name .. " (Range: " .. magnetRange .. " studs)")
        
    elseif upgradeItem.upgradeType == "doubleCoins" then
        -- Apply double coins effect - this affects coin collection in GameService
        local coinMultiplier = 1 + upgradeItem.level -- Level 1 = 2x coins
        
        -- Store coin multiplier in player data for GameService to use
        local playerData = PlayerService:GetPlayerData(player)
        if playerData then
            playerData.coinMultiplier = coinMultiplier
            PlayerService:UpdatePlayerData(player, playerData)
        end
        
        print("💰 Applied Double Coins Level " .. upgradeItem.level .. " to " .. player.Name .. " (Multiplier: " .. coinMultiplier .. "x)")
    end
end

function ShopService:ReapplyAllUpgrades(player)
    -- Reapply all owned upgrades when player respawns
    local playerData = PlayerService:GetPlayerData(player)
    if not playerData or not playerData.ownedUpgrades then
        return
    end
    
    local allItems = self:GetShopItems()
    
    for itemId, owned in pairs(playerData.ownedUpgrades) do
        if owned then
            -- Find the upgrade item
            for _, item in pairs(allItems) do
                if item.id == itemId and item.category == "upgrade" then
                    self:ApplyUpgrade(player, item)
                    break
                end
            end
        end
    end
    
    print("🔄 Reapplied all upgrades for " .. player.Name)
end

function ShopService:EquipItem(player, itemId, category)
    local playerData = PlayerService:GetPlayerData(player)
    if not playerData then
        return false, "Player data not found"
    end
    
    -- Check ownership
    if category == "skin" then
        if not playerData.ownedSkins or not playerData.ownedSkins[itemId] then
            return false, "Item not owned"
        end
        playerData.equippedSkin = itemId
    elseif category == "trail" then
        if not playerData.ownedTrails or not playerData.ownedTrails[itemId] then
            return false, "Item not owned"
        end
        playerData.equippedTrail = itemId
    end
    
    -- Update player data
    PlayerService:UpdatePlayerData(player, playerData)
    
    -- Apply cosmetics
    self:ApplyPlayerCosmetics(player)
    
    print("✨ " .. player.Name .. " equipped " .. itemId)
    return true, "Item equipped"
end

function ShopService:ApplyPlayerCosmetics(player)
    local playerData = PlayerService:GetPlayerData(player)
    if not playerData then return end
    
    local character = player.Character
    if not character then return end
    
    -- Apply skin color
    if playerData.equippedSkin then
        local skinItem = nil
        for _, item in pairs(SKIN_ITEMS) do
            if item.id == playerData.equippedSkin then
                skinItem = item
                break
            end
        end
        
        if skinItem then
            for _, part in pairs(character:GetChildren()) do
                if part:IsA("BasePart") and part.Name ~= "HumanoidRootPart" then
                    part.Color = skinItem.color
                end
            end
        end
    end
    
    -- Apply trail effect
    if playerData.equippedTrail then
        self:CreateTrailEffect(character, playerData.equippedTrail)
    end
end

function ShopService:CreateTrailEffect(character, trailId)
    local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
    if not humanoidRootPart then return end
    
    -- Remove existing trail
    local existingTrail = character:FindFirstChild("CustomTrail")
    if existingTrail then
        existingTrail:Destroy()
    end
    
    -- Find trail item
    local trailItem = nil
    for _, item in pairs(TRAIL_ITEMS) do
        if item.id == trailId then
            trailItem = item
            break
        end
    end
    
    if not trailItem then return end
    
    -- Create trail effect
    local trail = Instance.new("Trail")
    trail.Name = "CustomTrail"
    trail.Lifetime = 2
    trail.MinLength = 0
    trail.FaceCamera = true
    trail.Color = ColorSequence.new(trailItem.color)
    trail.Transparency = NumberSequence.new({
        NumberSequenceKeypoint.new(0, 0.5),
        NumberSequenceKeypoint.new(1, 1)
    })
    
    -- Create attachments
    local attachment0 = Instance.new("Attachment")
    attachment0.Position = Vector3.new(-0.5, 0, 0)
    attachment0.Parent = humanoidRootPart
    
    local attachment1 = Instance.new("Attachment")
    attachment1.Position = Vector3.new(0.5, 0, 0)
    attachment1.Parent = humanoidRootPart
    
    trail.Attachment0 = attachment0
    trail.Attachment1 = attachment1
    trail.Parent = character
end

function ShopService:SetupShopStall()
    local skinsStall = Workspace.MarketPlaza.MarketStalls:FindFirstChild("SkinsTrailsStall")
    if not skinsStall then
        warn("Skins & Trails stall not found!")
        return
    end
    
    local clickDetector = skinsStall:FindFirstChild("ClickDetector")
    local shopSign = skinsStall:FindFirstChild("ShopSign")
    
    if clickDetector then
        clickDetector.MouseClick:Connect(function(player)
            self:OpenShop(player)
        end)
    end
    
    -- Add shop sign text
    if shopSign then
        local surfaceGui = Instance.new("SurfaceGui")
        surfaceGui.Face = Enum.NormalId.Front
        surfaceGui.Parent = shopSign
        
        local titleLabel = Instance.new("TextLabel")
        titleLabel.Size = UDim2.new(1, 0, 0.6, 0)
        titleLabel.Position = UDim2.new(0, 0, 0, 0)
        titleLabel.BackgroundTransparency = 1
        titleLabel.Text = "SKINS & TRAILS"
        titleLabel.TextColor3 = Color3.new(0.2, 0.2, 0.8)
        titleLabel.TextScaled = true
        titleLabel.Font = Enum.Font.SourceSansBold
        titleLabel.Parent = surfaceGui
        
        local subtitleLabel = Instance.new("TextLabel")
        subtitleLabel.Size = UDim2.new(1, 0, 0.4, 0)
        subtitleLabel.Position = UDim2.new(0, 0, 0.6, 0)
        subtitleLabel.BackgroundTransparency = 1
        subtitleLabel.Text = "Click to Shop!"
        subtitleLabel.TextColor3 = Color3.new(0.5, 0.5, 0.5)
        subtitleLabel.TextScaled = true
        subtitleLabel.Font = Enum.Font.SourceSans
        subtitleLabel.Parent = surfaceGui
    end
end

function ShopService:OpenShop(player)
    local playerData = PlayerService:GetPlayerData(player)
    if not playerData then return end
    
    -- Track quest progress for shop visits
    if QuestService then
        QuestService:UpdateQuestProgress(player, "shop_visits", 1)
    end
    
    -- Send shop data to client
    RemoteEvents.OpenShop:FireClient(player, {
        items = self:GetShopItems(),
        playerCoins = playerData.coins,
        ownedSkins = playerData.ownedSkins or {},
        ownedTrails = playerData.ownedTrails or {},
        equippedSkin = playerData.equippedSkin,
        equippedTrail = playerData.equippedTrail
    })
    
    print("🛒 " .. player.Name .. " opened the Skins & Trails shop")
end

function ShopService:Init()
    -- Set up the shop stall
    game.Loaded:Wait()
    self:SetupShopStall()
    
    -- Handle remote events
    RemoteEvents.PurchaseShopItem.OnServerEvent:Connect(function(player, itemId)
        local success, message = self:PurchaseItem(player, itemId)
        RemoteEvents.ShopPurchaseResult:FireClient(player, success, message, itemId)
    end)
    
    -- Handle purchase confirmation requests
    RemoteEvents.ShowPurchaseConfirmation.OnServerEvent:Connect(function(player, purchaseData)
        if purchaseData.itemType == "shop_item" then
            local itemData = self:GetItemData(purchaseData.itemId)
            if itemData then
                -- Update purchase data with server-side item information
                purchaseData.name = itemData.name
                purchaseData.description = itemData.description or "Customize your appearance!"
                purchaseData.price = itemData.price
                purchaseData.icon = itemData.icon or (itemData.category == "skin" and "🎨" or "✨")
                
                RemoteEvents.ShowPurchaseConfirmation:FireClient(player, purchaseData)
            end
        end
    end)
    
    RemoteEvents.EquipShopItem.OnServerEvent:Connect(function(player, itemId, category)
        local success, message = self:EquipItem(player, itemId, category)
        RemoteEvents.ShopEquipResult:FireClient(player, success, message, itemId, category)
    end)
    
    RemoteEvents.RequestShopData.OnServerEvent:Connect(function(player)
        self:OpenShop(player)
    end)
    
    -- Apply cosmetics when players spawn
    Players.PlayerAdded:Connect(function(player)
        player.CharacterAdded:Connect(function(character)
            wait(1) -- Wait for character to fully load
            self:ApplyPlayerCosmetics(player)
        end)
    end)
    
    print("✅ ShopService initialized")
end

function ShopService:SetQuestService(service)
    QuestService = service
end

return ShopService
