-- FountainService.luau
-- Handles the magical fountain daily bonus system

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local DataStoreService = game:GetService("DataStoreService")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local SafeRequire = require(ReplicatedStorage.Shared.utils.SafeRequire)
local WorldObjectValidator = SafeRequire.require(ReplicatedStorage.Shared.utils.WorldObjectValidator)
local PlayerService = SafeRequire.require(script.Parent.core.PlayerService)
local RemoteEvents = SafeRequire.require(ReplicatedStorage.Shared.modules.RemoteEvents)

-- Forward declare QuestService to avoid circular dependency
local QuestService = nil

local FountainService = {}

-- DataStore for tracking daily claims
local dailyBonusStore = DataStoreService:GetDataStore("DailyFountainBonus")

-- Reward configurations
local DAILY_REWARDS = {
    {
        type = "coins",
        amount = 100,
        name = "💰 Coin Shower",
        description = "100 shiny coins rain from the fountain!",
        weight = 40,
        rarity = "common"
    },
    {
        type = "coins",
        amount = 250,
        name = "💎 Treasure Burst",
        description = "A treasure chest materializes with 250 coins!",
        weight = 25,
        rarity = "uncommon"
    },
    {
        type = "coins",
        amount = 500,
        name = "🏆 Royal Blessing",
        description = "The fountain grants you 500 royal coins!",
        weight = 10,
        rarity = "rare"
    },
    {
        type = "multiplier",
        amount = 2,
        duration = 300, -- 5 minutes
        name = "⚡ Speed Boost",
        description = "Double speed for 5 minutes!",
        weight = 15,
        rarity = "uncommon"
    },
    {
        type = "multiplier",
        amount = 3,
        duration = 180, -- 3 minutes
        name = "🌟 Lucky Stars",
        description = "Triple coin collection for 3 minutes!",
        weight = 8,
        rarity = "rare"
    },
    {
        type = "special",
        name = "🎨 Rainbow Trail",
        description = "Temporary rainbow trail for 10 minutes!",
        duration = 600,
        weight = 5,
        rarity = "epic"
    },
    {
        type = "mega",
        amount = 1000,
        name = "💫 Fountain Jackpot",
        description = "1000 MEGA COINS + Rainbow effects!",
        weight = 2,
        rarity = "legendary"
    }
}

-- Player cooldown tracking
local playerCooldowns = {}

function FountainService:GetDaysSinceEpoch()
    return math.floor(os.time() / 86400) -- 86400 seconds in a day
end

function FountainService:CanPlayerClaim(player)
    local userId = tostring(player.UserId)
    local currentDay = self:GetDaysSinceEpoch()
    
    -- Check local cooldown first
    if playerCooldowns[userId] and playerCooldowns[userId] >= currentDay then
        return false, playerCooldowns[userId]
    end
    
    -- Check DataStore
    local success, lastClaimDay = pcall(function()
        return dailyBonusStore:GetAsync(userId) or 0
    end)
    
    if success then
        playerCooldowns[userId] = lastClaimDay
        return lastClaimDay < currentDay, lastClaimDay
    else
        warn("Failed to check daily bonus for " .. player.Name)
        return false, 0
    end
end

function FountainService:MarkPlayerClaimed(player)
    local userId = tostring(player.UserId)
    local currentDay = self:GetDaysSinceEpoch()
    
    -- Update local cache
    playerCooldowns[userId] = currentDay
    
    -- Update DataStore
    local success = pcall(function()
        dailyBonusStore:SetAsync(userId, currentDay)
    end)
    
    if not success then
        warn("Failed to save daily bonus claim for " .. player.Name)
    end
end

function FountainService:GetRandomReward()
    local totalWeight = 0
    for _, reward in pairs(DAILY_REWARDS) do
        totalWeight = totalWeight + reward.weight
    end
    
    local random = math.random() * totalWeight
    local currentWeight = 0
    
    for _, reward in pairs(DAILY_REWARDS) do
        currentWeight = currentWeight + reward.weight
        if random <= currentWeight then
            return reward
        end
    end
    
    -- Fallback to first reward
    return DAILY_REWARDS[1]
end

function FountainService:GetRarityColor(rarity)
    local colors = {
        common = Color3.new(0.8, 0.8, 0.8),
        uncommon = Color3.new(0.2, 1, 0.2),
        rare = Color3.new(0.2, 0.4, 1),
        epic = Color3.new(0.8, 0.2, 1),
        legendary = Color3.new(1, 0.8, 0.2)
    }
    return colors[rarity] or colors.common
end

function FountainService:ApplyReward(player, reward)
    local playerData = PlayerService:GetPlayerData(player)
    if not playerData then return end
    
    if reward.type == "coins" then
        playerData.coins = playerData.coins + reward.amount
        playerData.totalCoinsEarned = (playerData.totalCoinsEarned or 0) + reward.amount
        
    elseif reward.type == "multiplier" then
        -- Apply temporary multiplier (handled by client)
        RemoteEvents.ApplyTempMultiplier:FireClient(player, reward.amount, reward.duration)
        
    elseif reward.type == "special" then
        -- Apply special effects (handled by client)
        RemoteEvents.ApplySpecialEffect:FireClient(player, "rainbow_trail", reward.duration)
        
    elseif reward.type == "mega" then
        playerData.coins = playerData.coins + reward.amount
        playerData.totalCoinsEarned = (playerData.totalCoinsEarned or 0) + reward.amount
        -- Add special mega effects
        RemoteEvents.ApplySpecialEffect:FireClient(player, "mega_jackpot", 30)
    end
    
    -- Update player data
    PlayerService:UpdatePlayerData(player, playerData)
end

function FountainService:CreateParticleEffect(position, reward)
    local part = Instance.new("Part")
    part.Size = Vector3.new(0.1, 0.1, 0.1)
    part.Position = position
    part.Anchored = true
    part.CanCollide = false
    part.Transparency = 1
    part.Parent = Workspace
    
    -- Create different effects based on reward rarity
    local attachment = Instance.new("Attachment")
    attachment.Parent = part
    
    local particleEmitter = Instance.new("ParticleEmitter")
    particleEmitter.Parent = attachment
    particleEmitter.Enabled = true
    particleEmitter.Lifetime = NumberRange.new(2, 4)
    particleEmitter.Rate = 100
    particleEmitter.SpreadAngle = Vector2.new(360, 360)
    particleEmitter.Speed = NumberRange.new(5, 15)
    particleEmitter.Color = ColorSequence.new(self:GetRarityColor(reward.rarity))
    
    if reward.rarity == "legendary" then
        particleEmitter.Rate = 200
        particleEmitter.Speed = NumberRange.new(10, 25)
        particleEmitter.Texture = "rbxasset://textures/particles/sparkles_main.dds"
    elseif reward.rarity == "epic" then
        particleEmitter.Rate = 150
        particleEmitter.Texture = "rbxasset://textures/particles/fire_main.dds"
    end
    
    -- Clean up after 5 seconds
    game:GetService("Debris"):AddItem(part, 5)
    
    -- Disable emitter after 2 seconds
    wait(2)
    particleEmitter.Enabled = false
end

function FountainService:PlayFountainAnimation()
    local fountain = Workspace.MarketPlaza.CentralFountain
    if not fountain then return end
    
    local magicalOrb = fountain:FindFirstChild("MagicalOrb")
    if not magicalOrb then return end
    
    -- Pulse animation
    local originalSize = magicalOrb.Size
    local originalColor = magicalOrb.Color
    
    local growTween = TweenService:Create(
        magicalOrb,
        TweenInfo.new(1, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut),
        {
            Size = originalSize * 1.5,
            Color = Color3.new(1, 1, 1)
        }
    )
    
    local shrinkTween = TweenService:Create(
        magicalOrb,
        TweenInfo.new(1, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut),
        {
            Size = originalSize,
            Color = originalColor
        }
    )
    
    growTween:Play()
    growTween.Completed:Connect(function()
        shrinkTween:Play()
    end)
end

function FountainService:ClaimDailyBonus(player)
    local canClaim, lastClaimDay = self:CanPlayerClaim(player)
    
    if not canClaim then
        -- Show cooldown timer
        local timeUntilNextClaim = (lastClaimDay + 1) * 86400 - os.time()
        local hoursLeft = math.ceil(timeUntilNextClaim / 3600)
        
        RemoteEvents.ShowFountainCooldown:FireClient(player, hoursLeft)
        print("⏰ " .. player.Name .. " tried to claim fountain bonus, " .. hoursLeft .. " hours left")
        return
    end
    
    -- Get random reward
    local reward = self:GetRandomReward()
    
    -- Mark as claimed
    self:MarkPlayerClaimed(player)
    
    -- Apply reward
    self:ApplyReward(player, reward)
    
    -- Track quest progress
    if QuestService then
        QuestService:UpdateQuestProgress(player, "fountain_claimed", 1)
    end
    
    -- Create visual effects
    spawn(function()
        self:CreateParticleEffect(Vector3.new(0, 8, 0), reward)
    end)
    
    -- Play fountain animation
    self:PlayFountainAnimation()
    
    -- Notify client
    RemoteEvents.FountainRewardClaimed:FireClient(player, reward)
    
    print("🎁 " .. player.Name .. " claimed fountain bonus: " .. reward.name)
end

function FountainService:SetupFountainDisplay()
    local fountain = Workspace.MarketPlaza.CentralFountain
    if not fountain then
        warn("Fountain not found!")
        return
    end
    
    local fountainCenter = fountain:FindFirstChild("FountainCenter")
    if not fountainCenter then return end
    
    -- Add floating text display
    local billboardGui = Instance.new("BillboardGui")
    billboardGui.Size = UDim2.new(0, 300, 0, 100)
    billboardGui.StudsOffset = Vector3.new(0, 3, 0)
    billboardGui.Parent = fountainCenter
    
    local titleLabel = Instance.new("TextLabel")
    titleLabel.Size = UDim2.new(1, 0, 0.6, 0)
    titleLabel.BackgroundTransparency = 1
    titleLabel.Text = "🌟 MAGICAL FOUNTAIN 🌟"
    titleLabel.TextColor3 = Color3.new(1, 1, 0.6)
    titleLabel.TextScaled = true
    titleLabel.Font = Enum.Font.SourceSansBold
    titleLabel.TextStrokeTransparency = 0
    titleLabel.TextStrokeColor3 = Color3.new(0, 0, 0)
    titleLabel.Parent = billboardGui
    
    local subtitleLabel = Instance.new("TextLabel")
    subtitleLabel.Size = UDim2.new(1, 0, 0.4, 0)
    subtitleLabel.Position = UDim2.new(0, 0, 0.6, 0)
    subtitleLabel.BackgroundTransparency = 1
    subtitleLabel.Text = "Click for Daily Blessing!"
    subtitleLabel.TextColor3 = Color3.new(0.8, 0.8, 1)
    subtitleLabel.TextScaled = true
    subtitleLabel.Font = Enum.Font.SourceSans
    subtitleLabel.TextStrokeTransparency = 0
    subtitleLabel.TextStrokeColor3 = Color3.new(0, 0, 0)
    subtitleLabel.Parent = billboardGui
    
    -- Add floating animation
    local floatTween = TweenService:Create(
        billboardGui,
        TweenInfo.new(3, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true),
        {StudsOffset = Vector3.new(0, 5, 0)}
    )
    floatTween:Play()
end

function FountainService:Initialize()
    print("🌊 FountainService initializing...")
    
    -- Validate fountain-related world objects
    print("🔍 Validating fountain world objects...")
    local missingObjects = WorldObjectValidator.validateAllRequired()
    if #missingObjects > 0 then
        warn("⚠️ FountainService: Missing required world objects:")
        for _, missing in ipairs(missingObjects) do
            warn("  • " .. missing)
        end
    end
    
    -- Validate fountain object specifically
    local fountainExists = WorldObjectValidator.validateObjectWithWait("workspace.Hub.Fountain", 5)
    if not fountainExists then
        -- Try alternative path
        fountainExists = WorldObjectValidator.validateObjectWithWait("workspace.MarketPlaza.CentralFountain", 5)
        if not fountainExists then
            warn("⚠️ FountainService: Fountain object not found in expected locations")
            return false
        end
    end
    print("✅ FountainService: Fountain object validated")
    
    -- Wait for workspace to be ready
    wait(1)
    
    -- Setup fountain display
    self:SetupFountainDisplay()
    
    -- Find and setup click detector
    local fountain = Workspace.MarketPlaza.CentralFountain
    if fountain then
        local clickDetector = fountain:FindFirstChild("ClickDetector")
        if clickDetector then
            clickDetector.MouseClick:Connect(function(player)
                self:ClaimDailyBonus(player)
            end)
            print("🎯 Fountain click detector connected")
        else
            warn("⚠️ ClickDetector not found in fountain!")
        end
        
        -- Add special glow effect to magical orb
        local magicalOrb = fountain:FindFirstChild("MagicalOrb")
        if magicalOrb then
            local pointLight = Instance.new("PointLight")
            pointLight.Color = Color3.new(1, 0.8, 0.2)
            pointLight.Brightness = 2
            pointLight.Range = 20
            pointLight.Parent = magicalOrb
            
            -- Breathing light effect
            local lightTween = TweenService:Create(
                pointLight,
                TweenInfo.new(2, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true),
                {Brightness = 4}
            )
            lightTween:Play()
        end
    else
        warn("⚠️ Fountain not found in MarketPlaza!")
    end
    
    print("✨ FountainService initialized successfully!")
end

function FountainService:SetQuestService(service)
    QuestService = service
end

-- Handle player joining
local function onPlayerAdded(player)
    -- Pre-check cooldown for UI updates
    spawn(function()
        wait(2) -- Wait for player to fully load
        local canClaim, lastClaimDay = FountainService:CanPlayerClaim(player)
        if not canClaim then
            local timeUntilNextClaim = (lastClaimDay + 1) * 86400 - os.time()
            local hoursLeft = math.ceil(timeUntilNextClaim / 3600)
            RemoteEvents.ShowFountainCooldown:FireClient(player, hoursLeft)
        end
    end)
end

-- Connect events
Players.PlayerAdded:Connect(onPlayerAdded)

-- Auto-initialize when required
FountainService:Initialize()

return FountainService
