-- MysteryService.luau
-- Handles Mystery Crate system with random cosmetic rewards

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local SoundService = game:GetService("SoundService")

local RemoteEvents = require(ReplicatedStorage.Shared.modules.RemoteEvents)
local PlayerService = require(script.Parent.PlayerService)

-- Forward declare services
local ShopService = nil
local QuestService = nil
local AnalyticsService = nil
local RebirthService = nil

local MysteryService = {}

-- Mystery box configuration - SOFT LAUNCH BALANCED
local MYSTERY_BOX_COST = 50 -- Increased from 25 for better economy balance
local MYSTERY_BOX_COOLDOWN = 3 -- Reduced from 5 seconds for better UX

-- Rarity system with balanced drop rates for soft launch
local RARITIES = {
    {
        name = "Common",
        color = Color3.new(0.8, 0.8, 0.8),
        chance = 70, -- Increased from 60% - more common rewards for beginners
        icon = "🔘",
        glowColor = Color3.new(0.7, 0.7, 0.7)
    },
    {
        name = "Rare",
        color = Color3.new(0.2, 0.8, 0.2),
        chance = 25, -- Decreased from 30% - balanced progression
        icon = "💚",
        glowColor = Color3.new(0.1, 1, 0.1)
    },
    {
        name = "Epic",
        color = Color3.new(0.8, 0.2, 1),
        chance = 5, -- Decreased from 10% - more exclusive feeling
        icon = "💜",
        glowColor = Color3.new(1, 0, 1)
    }
}

-- Mystery reward pools by rarity
local MYSTERY_REWARDS = {
    skins = {
        common = {"pewter_gray", "warm_brown", "soft_pink"},
        rare = {"electric_cyan", "sunset_orange", "emerald_green"},
        epic = {"galaxy_purple", "platinum_silver", "crimson_red"}
    },
    trails = {
        common = {"sparkle_trail", "bubble_trail", "leaf_trail"},
        rare = {"mystic_trail", "thunder_trail", "crystal_trail"},
        epic = {"phoenix_trail", "shadow_trail", "divine_trail"}
    }
}

function MysteryService:GetItemById(itemId)
    -- Get item details from ShopService
    if not ShopService then
        return nil
    end
    
    local allItems = ShopService:GetAllItems()
    for _, item in pairs(allItems) do
        if item.id == itemId then
            return item
        end
    end
    
    return nil
end

-- Player cooldowns
local playerCooldowns = {}

function MysteryService:GetRarityByChance(player)
    local randomValue = math.random(1, 100)
    
    -- Apply rebirth crate odds bonus
    local rebirthBonus = 0
    if RebirthService and player then
        rebirthBonus = RebirthService:GetCrateOddsBonus(player) * 100 -- Convert to percentage
        if rebirthBonus > 0 then
            print("🌟 Rebirth crate bonus: +" .. rebirthBonus .. "% better odds for " .. player.Name)
        end
    end
    
    local cumulativeChance = 0
    
    for i, rarity in pairs(RARITIES) do
        local adjustedChance = rarity.chance
        
        -- Apply rebirth bonus to rare+ items (reduce common chance, increase others)
        if rebirthBonus > 0 then
            if rarity.name == "Common" then
                adjustedChance = math.max(adjustedChance - rebirthBonus, 10) -- Don't go below 10%
            else
                adjustedChance = adjustedChance + (rebirthBonus / (#RARITIES - 1)) -- Distribute bonus to non-common
            end
        end
        
        cumulativeChance = cumulativeChance + adjustedChance
        if randomValue <= cumulativeChance then
            if rebirthBonus > 0 and rarity.name ~= "Common" then
                print("🎉 Rebirth bonus helped get " .. rarity.name .. " item for " .. player.Name .. "!")
            end
            return rarity
        end
    end
    
    -- Fallback to common if something goes wrong
    return RARITIES[1]
end

function MysteryService:GetRandomReward(rarity)
    local rarityName = rarity.name:lower()
    local rewardType = math.random(1, 2) == 1 and "skins" or "trails"
    
    local rewardPool = MYSTERY_REWARDS[rewardType][rarityName]
    if not rewardPool or #rewardPool == 0 then
        -- Fallback to common skins
        rewardPool = MYSTERY_REWARDS.skins.common
        rewardType = "skins"
    end
    
    local randomItemId = rewardPool[math.random(1, #rewardPool)]
    local itemData = self:GetItemById(randomItemId)
    
    if not itemData then
        -- Fallback if item not found
        warn("Mystery item not found: " .. randomItemId)
        itemData = {
            id = "pewter_gray",
            name = "Pewter Gray",
            color = Color3.new(0.6, 0.6, 0.6),
            category = "skin"
        }
    end
    
    return {
        id = itemData.id,
        name = itemData.name,
        color = itemData.color,
        effect = itemData.effect,
        rarity = rarity,
        type = itemData.category
    }
end

function MysteryService:PurchaseMysteryBox(player)
    local userId = tostring(player.UserId)
    local currentTime = tick()
    
    -- Check cooldown
    if playerCooldowns[userId] and currentTime - playerCooldowns[userId] < MYSTERY_BOX_COOLDOWN then
        local remainingTime = MYSTERY_BOX_COOLDOWN - (currentTime - playerCooldowns[userId])
        RemoteEvents.MysteryBoxResult:FireClient(player, {
            success = false,
            error = "Please wait " .. math.ceil(remainingTime) .. " seconds before opening another mystery box!"
        })
        return false
    end
    
    -- Check player data and coins
    local playerData = PlayerService:GetPlayerData(player)
    if not playerData then
        RemoteEvents.MysteryBoxResult:FireClient(player, {
            success = false,
            error = "Player data not found!"
        })
        return false
    end
    
    if playerData.coins < MYSTERY_BOX_COST then
        RemoteEvents.MysteryBoxResult:FireClient(player, {
            success = false,
            error = "Not enough coins! You need " .. MYSTERY_BOX_COST .. " coins."
        })
        return false
    end
    
    -- Deduct coins
    playerData.coins = playerData.coins - MYSTERY_BOX_COST
    
    -- Generate random reward with rebirth bonuses
    local rarity = self:GetRarityByChance(player)
    local reward = self:GetRandomReward(rarity)
    
    -- Initialize cosmetic arrays if needed
    if not playerData.ownedSkins then playerData.ownedSkins = {} end
    if not playerData.ownedTrails then playerData.ownedTrails = {} end
    
    -- Check if player already owns this item
    local alreadyOwned = false
    if reward.type == "skin" and playerData.ownedSkins[reward.id] then
        alreadyOwned = true
    elseif reward.type == "trail" and playerData.ownedTrails[reward.id] then
        alreadyOwned = true
    end
    
    -- Add reward to player data
    if reward.type == "skin" then
        playerData.ownedSkins[reward.id] = true
        if not playerData.equippedSkin then
            playerData.equippedSkin = reward.id
        end
    elseif reward.type == "trail" then
        playerData.ownedTrails[reward.id] = true
        if not playerData.equippedTrail then
            playerData.equippedTrail = reward.id
        end
    end
    
    -- Track statistics
    if not playerData.mysteryBoxStats then
        playerData.mysteryBoxStats = {
            totalOpened = 0,
            commonReceived = 0,
            rareReceived = 0,
            epicReceived = 0,
            coinsSpent = 0
        }
    end
    
    playerData.mysteryBoxStats.totalOpened = playerData.mysteryBoxStats.totalOpened + 1
    playerData.mysteryBoxStats.coinsSpent = playerData.mysteryBoxStats.coinsSpent + MYSTERY_BOX_COST
    
    local rarityLower = rarity.name:lower()
    if rarityLower == "common" then
        playerData.mysteryBoxStats.commonReceived = playerData.mysteryBoxStats.commonReceived + 1
    elseif rarityLower == "rare" then
        playerData.mysteryBoxStats.rareReceived = playerData.mysteryBoxStats.rareReceived + 1
    elseif rarityLower == "epic" then
        playerData.mysteryBoxStats.epicReceived = playerData.mysteryBoxStats.epicReceived + 1
    end
    
    -- Update player data
    PlayerService:UpdatePlayerData(player, playerData)
    
    -- Set cooldown
    playerCooldowns[userId] = currentTime
    
    -- Track quest progress for cosmetic purchase
    if QuestService then
        QuestService:UpdateQuestProgress(player, "cosmetic_purchase", 1)
        QuestService:UpdateQuestProgress(player, "mystery_box_opened", 1)
        
        -- Track rare/epic finds for quest
        if rarity.name == "Rare" or rarity.name == "Epic" then
            QuestService:UpdateQuestProgress(player, "rare_mystery_find", 1, {rarity = rarity.name})
        end
    end
    
    -- Log analytics
    if AnalyticsService then
        AnalyticsService:LogEvent(player, "mystery_box_opened", {
            cost = MYSTERY_BOX_COST,
            rewardId = reward.id,
            rewardName = reward.name,
            rewardType = reward.type,
            rarity = rarity.name,
            alreadyOwned = alreadyOwned,
            totalOpened = playerData.mysteryBoxStats.totalOpened,
            remainingCoins = playerData.coins
        })
    end
    
    -- Apply cosmetics if this is a new item
    if ShopService and not alreadyOwned then
        ShopService:ApplyPlayerCosmetics(player)
    end
    
    -- Send result to client
    RemoteEvents.MysteryBoxResult:FireClient(player, {
        success = true,
        reward = reward,
        alreadyOwned = alreadyOwned,
        newCoinTotal = playerData.coins,
        stats = playerData.mysteryBoxStats
    })
    
    -- Broadcast special rewards to all players
    if rarity.name == "Epic" then
        local message = "🎉 " .. player.Name .. " found an EPIC " .. reward.name .. " from a Mystery Box!"
        for _, otherPlayer in pairs(Players:GetPlayers()) do
            RemoteEvents.MysteryBoxResult:FireClient(otherPlayer, {
                specialAnnouncement = true,
                message = message,
                rarity = rarity
            })
        end
    end
    
    print("🎲 " .. player.Name .. " opened mystery box - Got " .. rarity.name .. " " .. reward.name .. " (" .. reward.type .. ")")
    return true
end

function MysteryService:OpenMysteryShop(player)
    local playerData = PlayerService:GetPlayerData(player)
    if not playerData then return end
    
    -- Track quest progress for shop visits
    if QuestService then
        QuestService:UpdateQuestProgress(player, "shop_visits", 1)
    end
    
    -- Send mystery shop data to client
    RemoteEvents.OpenMysteryShop:FireClient(player, {
        playerCoins = playerData.coins,
        boxCost = MYSTERY_BOX_COST,
        rarities = RARITIES,
        stats = playerData.mysteryBoxStats or {
            totalOpened = 0,
            commonReceived = 0,
            rareReceived = 0,
            epicReceived = 0,
            coinsSpent = 0
        },
        cooldownRemaining = self:GetPlayerCooldown(player)
    })
    
    print("🎲 " .. player.Name .. " opened the Mystery Box shop")
end

function MysteryService:GetPlayerCooldown(player)
    local userId = tostring(player.UserId)
    if not playerCooldowns[userId] then
        return 0
    end
    
    local currentTime = tick()
    local remainingTime = MYSTERY_BOX_COOLDOWN - (currentTime - playerCooldowns[userId])
    return math.max(0, remainingTime)
end

function MysteryService:SetupMysteryStall()
    local mysteryStall = Workspace.MarketPlaza.MarketStalls:FindFirstChild("MysteryStall")
    if not mysteryStall then
        warn("Mystery Crate stall not found! Please add it to the MarketPlaza.MarketStalls in your workspace.")
        return
    end
    
    local clickDetector = mysteryStall:FindFirstChild("ClickDetector")
    local shopSign = mysteryStall:FindFirstChild("ShopSign")
    
    if clickDetector then
        clickDetector.MouseClick:Connect(function(player)
            self:OpenMysteryShop(player)
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
        titleLabel.Text = "MYSTERY CRATES"
        titleLabel.TextColor3 = Color3.new(0.8, 0.2, 1)
        titleLabel.TextScaled = true
        titleLabel.Font = Enum.Font.SourceSansBold
        titleLabel.TextStrokeTransparency = 0
        titleLabel.TextStrokeColor3 = Color3.new(0, 0, 0)
        titleLabel.Parent = surfaceGui
        
        local subtitleLabel = Instance.new("TextLabel")
        subtitleLabel.Size = UDim2.new(1, 0, 0.4, 0)
        subtitleLabel.Position = UDim2.new(0, 0, 0.6, 0)
        subtitleLabel.BackgroundTransparency = 1
        subtitleLabel.Text = "🎲 25 Coins Each! 🎲"
        subtitleLabel.TextColor3 = Color3.new(1, 1, 0.2)
        subtitleLabel.TextScaled = true
        subtitleLabel.Font = Enum.Font.SourceSansBold
        subtitleLabel.TextStrokeTransparency = 0
        subtitleLabel.TextStrokeColor3 = Color3.new(0, 0, 0)
        subtitleLabel.Parent = surfaceGui
    end
    
    -- Add glowing effects to the stall
    self:AddGlowingEffects(mysteryStall)
    
    print("🎲 Mystery Crate stall setup complete!")
end

function MysteryService:AddGlowingEffects(stall)
    -- Add magical particle effects
    local stallRoof = stall:FindFirstChild("StallRoof")
    if stallRoof then
        local attachment = Instance.new("Attachment")
        attachment.Position = Vector3.new(0, 1, 0)
        attachment.Parent = stallRoof
        
        -- Sparkle particles
        local sparkles = Instance.new("ParticleEmitter")
        sparkles.Texture = "rbxasset://textures/particles/sparkles_main.dds"
        sparkles.Lifetime = NumberRange.new(1.0, 3.0)
        sparkles.Rate = 50
        sparkles.SpreadAngle = Vector2.new(45, 45)
        sparkles.Speed = NumberRange.new(5)
        sparkles.Color = ColorSequence.new({
            ColorSequenceKeypoint.new(0, Color3.new(1, 0, 1)),
            ColorSequenceKeypoint.new(0.5, Color3.new(0, 1, 1)),
            ColorSequenceKeypoint.new(1, Color3.new(1, 1, 0))
        })
        sparkles.Parent = attachment
        
        -- Magic swirl particles
        local swirls = Instance.new("ParticleEmitter")
        swirls.Texture = "rbxasset://textures/particles/smoke_main.dds"
        swirls.Lifetime = NumberRange.new(2.0, 4.0)
        swirls.Rate = 25
        swirls.SpreadAngle = Vector2.new(20, 20)
        swirls.Speed = NumberRange.new(2)
        swirls.Color = ColorSequence.new(Color3.new(0.8, 0.2, 1))
        swirls.Transparency = NumberSequence.new({
            NumberSequenceKeypoint.new(0, 0.8),
            NumberSequenceKeypoint.new(0.5, 0.5),
            NumberSequenceKeypoint.new(1, 1)
        })
        swirls.Parent = attachment
    end
    
    -- Add glowing border to counter
    local stallCounter = stall:FindFirstChild("StallCounter")
    if stallCounter then
        local selectionBox = Instance.new("SelectionBox")
        selectionBox.Adornee = stallCounter
        selectionBox.Color3 = Color3.new(1, 0, 1)
        selectionBox.LineThickness = 0.2
        selectionBox.Transparency = 0.3
        selectionBox.Parent = stallCounter
        
        -- Animate the glow
        local glowTween = TweenService:Create(
            selectionBox,
            TweenInfo.new(2, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true),
            {Transparency = 0.8}
        )
        glowTween:Play()
    end
end

function MysteryService:Init()
    print("🎲 MysteryService initializing...")
    
    -- Wait for workspace to be ready
    wait(1)
    
    -- Setup mystery stall
    self:SetupMysteryStall()
    
    -- Handle remote events
    RemoteEvents.PurchaseMysteryBox.OnServerEvent:Connect(function(player)
        self:PurchaseMysteryBox(player)
    end)
    
    -- Handle player leaving to clean up cooldowns
    Players.PlayerRemoving:Connect(function(player)
        local userId = tostring(player.UserId)
        playerCooldowns[userId] = nil
    end)
    
    print("✅ MysteryService initialized successfully!")
end

function MysteryService:SetShopService(service)
    ShopService = service
end

function MysteryService:SetQuestService(service)
    QuestService = service
end

function MysteryService:SetAnalyticsService(service)
    AnalyticsService = service
end

function MysteryService:SetRebirthService(service)
    RebirthService = service
end

-- Auto-initialize when required
MysteryService:Init()

return MysteryService
