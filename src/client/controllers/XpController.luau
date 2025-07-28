-- XpController.luau
-- Handles client-side XP UI, notifications, and level-up effects

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local StarterGui = game:GetService("StarterGui")
local RunService = game:GetService("RunService")
local SoundService = game:GetService("SoundService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local RemoteEvents = require(ReplicatedStorage.Shared.modules.RemoteEvents)

local XpController = {}

-- UI Elements
local xpFrame = nil
local xpBar = nil
local xpText = nil
local levelText = nil

-- Current XP info
local currentXp = 0
local xpToNextLevel = 0
local currentLevel = 1

function XpController:Init()
    self:CreateXpUI()
    self:SetupRemoteConnections()
    print("✅ XpController initialized")
end

function XpController:CreateXpUI()
    -- Create main XP frame
    xpFrame = Instance.new("Frame")
    xpFrame.Name = "XpFrame"
    xpFrame.Size = UDim2.new(0, 300, 0, 60)
    xpFrame.Position = UDim2.new(0.5, -150, 0, 10)
    xpFrame.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
    xpFrame.BorderSizePixel = 0
    xpFrame.Parent = playerGui
    
    -- Add corner radius
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 8)
    corner.Parent = xpFrame
    
    -- Level text
    levelText = Instance.new("TextLabel")
    levelText.Name = "LevelText"
    levelText.Size = UDim2.new(0, 60, 1, 0)
    levelText.Position = UDim2.new(0, 0, 0, 0)
    levelText.BackgroundTransparency = 1
    levelText.Text = "LV 1"
    levelText.TextColor3 = Color3.fromRGB(255, 255, 255)
    levelText.TextScaled = true
    levelText.Font = Enum.Font.GothamBold
    levelText.Parent = xpFrame
    
    -- XP bar background
    local xpBarBg = Instance.new("Frame")
    xpBarBg.Name = "XpBarBackground"
    xpBarBg.Size = UDim2.new(1, -70, 0, 20)
    xpBarBg.Position = UDim2.new(0, 65, 0.5, -10)
    xpBarBg.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
    xpBarBg.BorderSizePixel = 0
    xpBarBg.Parent = xpFrame
    
    local bgCorner = Instance.new("UICorner")
    bgCorner.CornerRadius = UDim.new(0, 10)
    bgCorner.Parent = xpBarBg
    
    -- XP bar fill
    xpBar = Instance.new("Frame")
    xpBar.Name = "XpBar"
    xpBar.Size = UDim2.new(0, 0, 1, 0)
    xpBar.Position = UDim2.new(0, 0, 0, 0)
    xpBar.BackgroundColor3 = Color3.fromRGB(0, 170, 255)
    xpBar.BorderSizePixel = 0
    xpBar.Parent = xpBarBg
    
    local barCorner = Instance.new("UICorner")
    barCorner.CornerRadius = UDim.new(0, 10)
    barCorner.Parent = xpBar
    
    -- XP text
    xpText = Instance.new("TextLabel")
    xpText.Name = "XpText"
    xpText.Size = UDim2.new(1, 0, 0, 15)
    xpText.Position = UDim2.new(0, 65, 1, -20)
    xpText.BackgroundTransparency = 1
    xpText.Text = "0 / 100 XP"
    xpText.TextColor3 = Color3.fromRGB(200, 200, 200)
    xpText.TextScaled = true
    xpText.Font = Enum.Font.Gotham
    xpText.Parent = xpFrame
end

function XpController:SetupRemoteConnections()
    -- XP gained notification
    RemoteEvents.XpGained.OnClientEvent:Connect(function(xpGained, newXp, xpRequired, level)
        self:ShowXpGainedNotification(xpGained)
        self:UpdateXpDisplay(newXp, xpRequired, level)
    end)
    
    -- Level up notification
    RemoteEvents.LevelUp.OnClientEvent:Connect(function(newLevel, milestone)
        self:ShowLevelUpNotification(newLevel, milestone)
        self:PlayLevelUpEffects(milestone)
    end)
    
    -- Level milestone reward notification
    RemoteEvents.LevelMilestoneReward.OnClientEvent:Connect(function(level, rewardName, rewardType)
        self:ShowMilestoneRewardNotification(level, rewardName, rewardType)
    end)
    
    -- Update level display above head
    RemoteEvents.UpdateLevelDisplay.OnClientEvent:Connect(function(targetPlayer, level)
        self:UpdatePlayerLevelDisplay(targetPlayer, level)
    end)
end

function XpController:UpdateXpDisplay(xp, xpRequired, level)
    currentXp = xp
    xpToNextLevel = xpRequired
    currentLevel = level
    
    -- Update level text
    levelText.Text = "LV " .. level
    
    -- Update XP text
    xpText.Text = xp .. " / " .. xpRequired .. " XP"
    
    -- Update XP bar
    local xpPercentage = xp / xpRequired
    TweenService:Create(xpBar, TweenInfo.new(0.5, Enum.EasingStyle.Quad), {
        Size = UDim2.new(xpPercentage, 0, 1, 0)
    }):Play()
    
    -- Color code level text based on level range
    if level >= 100 then
        levelText.TextColor3 = Color3.fromRGB(255, 215, 0) -- Gold
    elseif level >= 75 then
        levelText.TextColor3 = Color3.fromRGB(255, 165, 0) -- Orange
    elseif level >= 50 then
        levelText.TextColor3 = Color3.fromRGB(128, 0, 128) -- Purple
    elseif level >= 25 then
        levelText.TextColor3 = Color3.fromRGB(0, 100, 255) -- Blue
    elseif level >= 10 then
        levelText.TextColor3 = Color3.fromRGB(0, 255, 0) -- Green
    else
        levelText.TextColor3 = Color3.fromRGB(255, 255, 255) -- White
    end
end

function XpController:ShowXpGainedNotification(xpGained)
    -- Create floating XP text
    local notification = Instance.new("TextLabel")
    notification.Size = UDim2.new(0, 100, 0, 30)
    notification.Position = UDim2.new(0.5, -50, 0.8, 0)
    notification.BackgroundTransparency = 1
    notification.Text = "+" .. xpGained .. " XP"
    notification.TextColor3 = Color3.fromRGB(0, 255, 150)
    notification.TextScaled = true
    notification.Font = Enum.Font.GothamBold
    notification.TextStrokeTransparency = 0
    notification.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
    notification.Parent = playerGui
    
    -- Animate notification
    local tween = TweenService:Create(notification, TweenInfo.new(2, Enum.EasingStyle.Quad), {
        Position = UDim2.new(0.5, -50, 0.6, 0),
        TextTransparency = 1,
        TextStrokeTransparency = 1
    })
    
    tween:Play()
    tween.Completed:Connect(function()
        notification:Destroy()
    end)
end

function XpController:ShowLevelUpNotification(newLevel, milestone)
    -- Create level up notification
    local levelUpFrame = Instance.new("Frame")
    levelUpFrame.Size = UDim2.new(0, 400, 0, 100)
    levelUpFrame.Position = UDim2.new(0.5, -200, 0.3, 0)
    levelUpFrame.BackgroundColor3 = Color3.fromRGB(255, 215, 0)
    levelUpFrame.BorderSizePixel = 0
    levelUpFrame.Parent = playerGui
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 15)
    corner.Parent = levelUpFrame
    
    local levelUpText = Instance.new("TextLabel")
    levelUpText.Size = UDim2.new(1, 0, 0.6, 0)
    levelUpText.Position = UDim2.new(0, 0, 0, 0)
    levelUpText.BackgroundTransparency = 1
    levelUpText.Text = "LEVEL UP!"
    levelUpText.TextColor3 = Color3.fromRGB(0, 0, 0)
    levelUpText.TextScaled = true
    levelUpText.Font = Enum.Font.GothamBold
    levelUpText.Parent = levelUpFrame
    
    local newLevelText = Instance.new("TextLabel")
    newLevelText.Size = UDim2.new(1, 0, 0.4, 0)
    newLevelText.Position = UDim2.new(0, 0, 0.6, 0)
    newLevelText.BackgroundTransparency = 1
    newLevelText.Text = "Level " .. newLevel
    newLevelText.TextColor3 = Color3.fromRGB(50, 50, 50)
    newLevelText.TextScaled = true
    newLevelText.Font = Enum.Font.Gotham
    newLevelText.Parent = levelUpFrame
    
    -- Animate level up notification
    levelUpFrame.Size = UDim2.new(0, 0, 0, 0)
    local appearTween = TweenService:Create(levelUpFrame, TweenInfo.new(0.3, Enum.EasingStyle.Back), {
        Size = UDim2.new(0, 400, 0, 100)
    })
    
    appearTween:Play()
    
    -- Hold for 2 seconds then fade out
    wait(2)
    local fadeTween = TweenService:Create(levelUpFrame, TweenInfo.new(0.5, Enum.EasingStyle.Quad), {
        Position = UDim2.new(0.5, -200, 0.1, 0),
        BackgroundTransparency = 1
    })
    
    TweenService:Create(levelUpText, TweenInfo.new(0.5, Enum.EasingStyle.Quad), {
        TextTransparency = 1
    }):Play()
    
    TweenService:Create(newLevelText, TweenInfo.new(0.5, Enum.EasingStyle.Quad), {
        TextTransparency = 1
    }):Play()
    
    fadeTween:Play()
    fadeTween.Completed:Connect(function()
        levelUpFrame:Destroy()
    end)
end

function XpController:ShowMilestoneRewardNotification(level, rewardName, rewardType)
    -- Create milestone reward notification
    local rewardFrame = Instance.new("Frame")
    rewardFrame.Size = UDim2.new(0, 350, 0, 80)
    rewardFrame.Position = UDim2.new(0.5, -175, 0.7, 0)
    rewardFrame.BackgroundColor3 = Color3.fromRGB(138, 43, 226)
    rewardFrame.BorderSizePixel = 0
    rewardFrame.Parent = playerGui
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 12)
    corner.Parent = rewardFrame
    
    local rewardText = Instance.new("TextLabel")
    rewardText.Size = UDim2.new(1, 0, 0.5, 0)
    rewardText.Position = UDim2.new(0, 0, 0, 0)
    rewardText.BackgroundTransparency = 1
    rewardText.Text = "Milestone Reward!"
    rewardText.TextColor3 = Color3.fromRGB(255, 255, 255)
    rewardText.TextScaled = true
    rewardText.Font = Enum.Font.GothamBold
    rewardText.Parent = rewardFrame
    
    local itemText = Instance.new("TextLabel")
    itemText.Size = UDim2.new(1, 0, 0.5, 0)
    itemText.Position = UDim2.new(0, 0, 0.5, 0)
    itemText.BackgroundTransparency = 1
    itemText.Text = "Unlocked: " .. rewardName
    itemText.TextColor3 = Color3.fromRGB(220, 220, 220)
    itemText.TextScaled = true
    itemText.Font = Enum.Font.Gotham
    itemText.Parent = rewardFrame
    
    -- Animate and auto-remove
    rewardFrame.Position = UDim2.new(0.5, -175, 1, 0)
    local slideTween = TweenService:Create(rewardFrame, TweenInfo.new(0.4, Enum.EasingStyle.Back), {
        Position = UDim2.new(0.5, -175, 0.7, 0)
    })
    
    slideTween:Play()
    
    -- Auto-remove after 3 seconds
    wait(3)
    local fadeOut = TweenService:Create(rewardFrame, TweenInfo.new(0.3, Enum.EasingStyle.Quad), {
        Position = UDim2.new(0.5, -175, 1, 0)
    })
    
    fadeOut:Play()
    fadeOut.Completed:Connect(function()
        rewardFrame:Destroy()
    end)
end

function XpController:PlayLevelUpEffects(milestone)
    -- Play level up sound
    local levelUpSound = Instance.new("Sound")
    levelUpSound.SoundId = "rbxasset://sounds/electronicpingshort.wav"
    levelUpSound.Volume = 0.5
    levelUpSound.Parent = workspace
    levelUpSound:Play()
    
    levelUpSound.Ended:Connect(function()
        levelUpSound:Destroy()
    end)
    
    -- Extra effects for milestone levels
    if milestone then
        wait(0.5)
        local milestoneSound = Instance.new("Sound")
        milestoneSound.SoundId = "rbxasset://sounds/bell.wav"
        milestoneSound.Volume = 0.7
        milestoneSound.Parent = workspace
        milestoneSound:Play()
        
        milestoneSound.Ended:Connect(function()
            milestoneSound:Destroy()
        end)
    end
end

function XpController:UpdatePlayerLevelDisplay(targetPlayer, level)
    if not targetPlayer or not targetPlayer.Character then
        return
    end
    
    local character = targetPlayer.Character
    local humanoid = character:FindFirstChild("Humanoid")
    local head = character:FindFirstChild("Head")
    
    if not humanoid or not head then
        return
    end
    
    -- Remove existing level display
    local existingDisplay = head:FindFirstChild("LevelDisplay")
    if existingDisplay then
        existingDisplay:Destroy()
    end
    
    -- Create new level display
    local billboard = Instance.new("BillboardGui")
    billboard.Name = "LevelDisplay"
    billboard.Size = UDim2.new(0, 100, 0, 30)
    billboard.StudsOffset = Vector3.new(0, 3, 0)
    billboard.Parent = head
    
    local levelLabel = Instance.new("TextLabel")
    levelLabel.Size = UDim2.new(1, 0, 1, 0)
    levelLabel.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    levelLabel.BackgroundTransparency = 0.3
    levelLabel.Text = "LV " .. level
    levelLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    levelLabel.TextScaled = true
    levelLabel.Font = Enum.Font.GothamBold
    levelLabel.TextStrokeTransparency = 0
    levelLabel.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
    levelLabel.Parent = billboard
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 8)
    corner.Parent = levelLabel
    
    -- Color code based on level
    if level >= 100 then
        levelLabel.TextColor3 = Color3.fromRGB(255, 215, 0) -- Gold
        levelLabel.BackgroundColor3 = Color3.fromRGB(40, 30, 0)
    elseif level >= 75 then
        levelLabel.TextColor3 = Color3.fromRGB(255, 165, 0) -- Orange
        levelLabel.BackgroundColor3 = Color3.fromRGB(40, 25, 0)
    elseif level >= 50 then
        levelLabel.TextColor3 = Color3.fromRGB(200, 100, 255) -- Purple
        levelLabel.BackgroundColor3 = Color3.fromRGB(30, 0, 40)
    elseif level >= 25 then
        levelLabel.TextColor3 = Color3.fromRGB(100, 150, 255) -- Blue
        levelLabel.BackgroundColor3 = Color3.fromRGB(0, 10, 40)
    elseif level >= 10 then
        levelLabel.TextColor3 = Color3.fromRGB(100, 255, 100) -- Green
        levelLabel.BackgroundColor3 = Color3.fromRGB(0, 40, 0)
    else
        levelLabel.TextColor3 = Color3.fromRGB(255, 255, 255) -- White
        levelLabel.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
    end
end

return XpController
