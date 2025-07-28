-- LevelingService.luau
-- Handles player XP, leveling, and level milestone rewards

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local SafeRequire = require(ReplicatedStorage.Shared.utils.SafeRequire)
local RemoteEvents = SafeRequire.require(ReplicatedStorage.Shared.modules.RemoteEvents)

-- Forward declare services
local PlayerService = nil
local ShopService = nil
local AnalyticsService = nil

local LevelingService = {}

-- XP Configuration
local XP_CONFIG = {
    baseXpPerScore = 10, -- Base XP per score point
    bonusXpPerBarrier = 2, -- Bonus XP per barrier passed
    perfectGameBonus = 50, -- Bonus XP for perfect games (no wrong barriers)
    highScoreBonus = 100, -- Bonus XP for new personal high score
    
    -- Level progression formula: XP needed = baseXp * (level ^ scalingFactor)
    baseXpForNextLevel = 100,
    scalingFactor = 1.15, -- How much XP requirement increases per level
    maxLevel = 100 -- Maximum level (can be increased)
}

-- Level milestone rewards - cosmetics unlocked at specific levels
local LEVEL_REWARDS = {
    [5] = {
        type = "skin",
        id = "veteran_bronze",
        name = "Veteran Bronze",
        color = Color3.new(0.8, 0.5, 0.2),
        description = "Unlocked at Level 5!"
    },
    [10] = {
        type = "trail",
        id = "experience_trail",
        name = "Experience Trail",
        color = Color3.new(0.2, 0.8, 1),
        effect = "experience",
        description = "Unlocked at Level 10!"
    },
    [15] = {
        type = "skin",
        id = "seasoned_silver",
        name = "Seasoned Silver",
        color = Color3.new(0.8, 0.8, 0.9),
        description = "Unlocked at Level 15!"
    },
    [25] = {
        type = "trail",
        id = "mastery_trail",
        name = "Mastery Trail",
        color = Color3.new(1, 0.8, 0.2),
        effect = "mastery",
        description = "Unlocked at Level 25!"
    },
    [35] = {
        type = "skin",
        id = "expert_gold",
        name = "Expert Gold",
        color = Color3.new(1, 0.8, 0.1),
        description = "Unlocked at Level 35!"
    },
    [50] = {
        type = "trail",
        id = "legend_trail",
        name = "Legendary Trail",
        color = Color3.new(1, 0.2, 0.8),
        effect = "legendary",
        description = "Unlocked at Level 50!"
    },
    [75] = {
        type = "skin",
        id = "master_platinum",
        name = "Master Platinum",
        color = Color3.new(0.9, 0.95, 1),
        description = "Unlocked at Level 75!"
    },
    [100] = {
        type = "both",
        skin = {
            id = "grandmaster_rainbow",
            name = "Grandmaster Rainbow",
            color = Color3.new(1, 0.5, 1),
            description = "The ultimate achievement!"
        },
        trail = {
            id = "grandmaster_trail",
            name = "Grandmaster Trail",
            color = Color3.new(1, 1, 0.5),
            effect = "grandmaster",
            description = "The ultimate achievement!"
        }
    }
}

function LevelingService:CalculateXpRequirement(level)
    -- Calculate XP needed to reach the next level
    if level >= XP_CONFIG.maxLevel then
        return 0 -- Max level reached
    end
    
    return math.floor(XP_CONFIG.baseXpForNextLevel * (level ^ XP_CONFIG.scalingFactor))
end

function LevelingService:CalculateXpGain(score, barriersPassed, isPerfectGame, isNewHighScore)
    local xpGain = 0
    
    -- Base XP from score
    xpGain = xpGain + (score * XP_CONFIG.baseXpPerScore)
    
    -- Bonus XP from barriers passed
    xpGain = xpGain + (barriersPassed * XP_CONFIG.bonusXpPerBarrier)
    
    -- Perfect game bonus
    if isPerfectGame then
        xpGain = xpGain + XP_CONFIG.perfectGameBonus
    end
    
    -- New high score bonus
    if isNewHighScore then
        xpGain = xpGain + XP_CONFIG.highScoreBonus
    end
    
    return math.max(1, math.floor(xpGain)) -- Minimum 1 XP per game
end

function LevelingService:AwardXp(player, xpAmount, source)
    local playerData = PlayerService:GetPlayerData(player)
    if not playerData then
        return false
    end
    
    -- Initialize XP fields if they don't exist (for existing players)
    if not playerData.experience then playerData.experience = 0 end
    if not playerData.totalXpEarned then playerData.totalXpEarned = 0 end
    if not playerData.xpToNextLevel then 
        playerData.xpToNextLevel = self:CalculateXpRequirement(playerData.level or 1)
    end
    
    local oldLevel = playerData.level or 1
    local oldXp = playerData.experience
    
    -- Add XP
    playerData.experience = playerData.experience + xpAmount
    playerData.totalXpEarned = playerData.totalXpEarned + xpAmount
    
    -- Check for level ups
    local leveledUp = false
    local levelsGained = 0
    
    while playerData.experience >= playerData.xpToNextLevel and playerData.level < XP_CONFIG.maxLevel do
        playerData.experience = playerData.experience - playerData.xpToNextLevel
        playerData.level = playerData.level + 1
        levelsGained = levelsGained + 1
        leveledUp = true
        
        -- Calculate new XP requirement
        playerData.xpToNextLevel = self:CalculateXpRequirement(playerData.level)
        
        -- Check for level milestone rewards
        self:CheckLevelMilestone(player, playerData.level)
    end
    
    -- Update player data
    PlayerService:UpdatePlayerData(player, playerData)
    
    -- Update leaderstats if they exist
    local leaderstats = player:FindFirstChild("leaderstats")
    if leaderstats then
        local levelStat = leaderstats:FindFirstChild("Level")
        if levelStat then
            levelStat.Value = playerData.level
        end
    end
    
    -- Send XP update to client
    RemoteEvents.XpGained:FireClient(player, {
        xpGained = xpAmount,
        currentXp = playerData.experience,
        xpToNextLevel = playerData.xpToNextLevel,
        currentLevel = playerData.level,
        leveledUp = leveledUp,
        levelsGained = levelsGained,
        source = source or "Unknown"
    })
    
    -- Update XP display
    RemoteEvents.XpUpdated:FireClient(player, playerData.experience, playerData.level, self:GetXpRequiredForLevel(playerData.level + 1))
    
    -- Send level up notification if applicable
    if leveledUp then
        RemoteEvents.LevelUp:FireClient(player, playerData.level, xpAmount)
    end
    
    -- Log analytics
    if AnalyticsService then
        AnalyticsService:LogEvent(player, "xp_gained", {
            xpAmount = xpAmount,
            source = source,
            currentLevel = playerData.level,
            totalXp = playerData.totalXpEarned,
            leveledUp = leveledUp,
            levelsGained = levelsGained
        })
    end
    
    -- Show level up effects
    if leveledUp then
        self:ShowLevelUpEffects(player, oldLevel, playerData.level)
    end
    
    print("⭐ " .. player.Name .. " gained " .. xpAmount .. " XP from " .. (source or "Unknown") .. " (Level " .. playerData.level .. ")")
    return true
end

function LevelingService:CheckLevelMilestone(player, newLevel)
    local reward = LEVEL_REWARDS[newLevel]
    if not reward then
        return
    end
    
    local playerData = PlayerService:GetPlayerData(player)
    if not playerData then
        return
    end
    
    -- Initialize cosmetic arrays if needed
    if not playerData.ownedSkins then playerData.ownedSkins = {} end
    if not playerData.ownedTrails then playerData.ownedTrails = {} end
    
    -- Award milestone reward
    if reward.type == "skin" then
        playerData.ownedSkins[reward.id] = true
        RemoteEvents.LevelMilestoneReward:FireClient(player, {
            level = newLevel,
            rewardType = "skin",
            reward = reward
        })
    elseif reward.type == "trail" then
        playerData.ownedTrails[reward.id] = true
        RemoteEvents.LevelMilestoneReward:FireClient(player, {
            level = newLevel,
            rewardType = "trail",
            reward = reward
        })
    elseif reward.type == "both" then
        playerData.ownedSkins[reward.skin.id] = true
        playerData.ownedTrails[reward.trail.id] = true
        RemoteEvents.LevelMilestoneReward:FireClient(player, {
            level = newLevel,
            rewardType = "both",
            skin = reward.skin,
            trail = reward.trail
        })
    end
    
    -- Update player data
    PlayerService:UpdatePlayerData(player, playerData)
    
    -- Apply cosmetics if this is their first cosmetic
    if ShopService then
        ShopService:ApplyPlayerCosmetics(player)
    end
    
    -- Log milestone achievement
    if AnalyticsService then
        AnalyticsService:LogEvent(player, "level_milestone_reached", {
            level = newLevel,
            rewardType = reward.type,
            rewardId = reward.id or "multiple"
        })
    end
    
    print("🏆 " .. player.Name .. " reached level " .. newLevel .. " milestone and unlocked: " .. (reward.name or "multiple items"))
end

function LevelingService:ShowLevelUpEffects(player, oldLevel, newLevel)
    local character = player.Character
    if not character then
        return
    end
    
    -- Update level display above head
    self:UpdateLevelDisplay(player)
    
    -- Show level up particle effects
    local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
    if humanoidRootPart then
        -- Create level up particles
        local attachment = Instance.new("Attachment")
        attachment.Parent = humanoidRootPart
        
        local levelUpParticles = Instance.new("ParticleEmitter")
        levelUpParticles.Texture = "rbxasset://textures/particles/sparkles_main.dds"
        levelUpParticles.Lifetime = NumberRange.new(2.0, 4.0)
        levelUpParticles.Rate = 100
        levelUpParticles.SpreadAngle = Vector2.new(45, 45)
        levelUpParticles.Speed = NumberRange.new(10)
        levelUpParticles.Color = ColorSequence.new({
            ColorSequenceKeypoint.new(0, Color3.new(1, 1, 0)),
            ColorSequenceKeypoint.new(0.5, Color3.new(0, 1, 1)),
            ColorSequenceKeypoint.new(1, Color3.new(1, 0, 1))
        })
        levelUpParticles.Parent = attachment
        
        -- Burst effect
        levelUpParticles:Emit(50)
        
        -- Clean up after 5 seconds
        game:GetService("Debris"):AddItem(attachment, 5)
    end
    
    print("✨ " .. player.Name .. " leveled up from " .. oldLevel .. " to " .. newLevel .. "!")
end

function LevelingService:UpdateLevelDisplay(player)
    local character = player.Character
    if not character then
        return
    end
    
    local head = character:FindFirstChild("Head")
    if not head then
        return
    end
    
    -- Remove existing level display
    local existingGui = head:FindFirstChild("LevelDisplay")
    if existingGui then
        existingGui:Destroy()
    end
    
    local playerData = PlayerService:GetPlayerData(player)
    if not playerData then
        return
    end
    
    -- Create new level display
    local billboardGui = Instance.new("BillboardGui")
    billboardGui.Name = "LevelDisplay"
    billboardGui.Size = UDim2.new(0, 100, 0, 30)
    billboardGui.StudsOffset = Vector3.new(0, 3, 0)
    billboardGui.Parent = head
    
    -- Background frame
    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(1, 0, 1, 0)
    frame.BackgroundColor3 = Color3.new(0, 0, 0)
    frame.BackgroundTransparency = 0.3
    frame.BorderSizePixel = 0
    frame.Parent = billboardGui
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 8)
    corner.Parent = frame
    
    -- Level text
    local levelLabel = Instance.new("TextLabel")
    levelLabel.Size = UDim2.new(1, 0, 1, 0)
    levelLabel.BackgroundTransparency = 1
    levelLabel.Text = "LVL " .. playerData.level
    levelLabel.TextColor3 = self:GetLevelColor(playerData.level)
    levelLabel.TextScaled = true
    levelLabel.Font = Enum.Font.SourceSansBold
    levelLabel.TextStrokeTransparency = 0
    levelLabel.TextStrokeColor3 = Color3.new(0, 0, 0)
    levelLabel.Parent = frame
    
    -- Add glow effect for high levels
    if playerData.level >= 50 then
        local selectionBox = Instance.new("SelectionBox")
        selectionBox.Adornee = frame
        selectionBox.Color3 = self:GetLevelColor(playerData.level)
        selectionBox.LineThickness = 0.1
        selectionBox.Transparency = 0.5
        selectionBox.Parent = frame
        
        -- Animate the glow
        local glowTween = TweenService:Create(
            selectionBox,
            TweenInfo.new(2, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true),
            {Transparency = 0.8}
        )
        glowTween:Play()
    end
end

function LevelingService:GetLevelColor(level)
    -- Return color based on level range
    if level >= 100 then
        return Color3.new(1, 0.5, 1) -- Rainbow/Grandmaster
    elseif level >= 75 then
        return Color3.new(0.9, 0.95, 1) -- Platinum
    elseif level >= 50 then
        return Color3.new(1, 0.2, 0.8) -- Legendary Pink
    elseif level >= 35 then
        return Color3.new(1, 0.8, 0.1) -- Gold
    elseif level >= 25 then
        return Color3.new(1, 0.8, 0.2) -- Orange
    elseif level >= 15 then
        return Color3.new(0.8, 0.8, 0.9) -- Silver
    elseif level >= 10 then
        return Color3.new(0.2, 0.8, 1) -- Blue
    elseif level >= 5 then
        return Color3.new(0.8, 0.5, 0.2) -- Bronze
    else
        return Color3.new(1, 1, 1) -- White (novice)
    end
end

function LevelingService:GetPlayerLevel(player)
    local playerData = PlayerService:GetPlayerData(player)
    return playerData and playerData.level or 1
end

function LevelingService:GetPlayerXp(player)
    local playerData = PlayerService:GetPlayerData(player)
    if not playerData then
        return 0, 100
    end
    
    return playerData.experience or 0, playerData.xpToNextLevel or 100
end

function LevelingService:GetLevelRewards()
    return LEVEL_REWARDS
end

function LevelingService:OnPlayerAdded(player)
    -- Set up level display when player spawns
    player.CharacterAdded:Connect(function(character)
        wait(1) -- Wait for character to fully load
        self:UpdateLevelDisplay(player)
    end)
end

function LevelingService:Init()
    print("⭐ LevelingService initializing...")
    
    -- Handle XP display requests
    RemoteEvents.RequestPlayerXp.OnServerEvent:Connect(function(player)
        self:SendPlayerXp(player)
    end)
    
    -- Handle player joining
    Players.PlayerAdded:Connect(function(player)
        self:OnPlayerAdded(player)
    end)
    
    -- For players already in game
    for _, player in pairs(Players:GetPlayers()) do
        self:OnPlayerAdded(player)
    end
    
    print("✅ LevelingService initialized successfully!")
end

function LevelingService:SendPlayerXp(player)
    local playerData = PlayerService:GetPlayerData(player)
    if playerData then
        local currentXp = playerData.experience or 0
        local currentLevel = playerData.level or 1
        local xpRequired = self:GetXpRequiredForLevel(currentLevel + 1)
        
        RemoteEvents.XpUpdated:FireClient(player, currentXp, currentLevel, xpRequired)
    end
end

function LevelingService:SetPlayerService(service)
    PlayerService = service
end

function LevelingService:SetShopService(service)
    ShopService = service
end

function LevelingService:SetAnalyticsService(service)
    AnalyticsService = service
end

-- Auto-initialize when required
LevelingService:Init()

return LevelingService
