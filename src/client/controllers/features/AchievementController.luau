-- AchievementController.luau
-- Handles client-side achievement UI, daily bonus popup, and notifications

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local SoundService = game:GetService("SoundService")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local RemoteEvents = require(ReplicatedStorage.Shared.modules.RemoteEvents)

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local AchievementController = {}

-- GUI state
local achievementGui = nil
local dailyBonusGui = nil
local isAchievementOpen = false
local achievementData = {}

-- Sound effects
local achievementSound = nil
local dailyBonusSound = nil
local claimSound = nil

function AchievementController:Init()
    self:LoadSounds()
    self:SetupRemoteEvents()
    self:CreateAchievementGUI()
    
    -- Request initial data
    RemoteEvents.RequestAchievementData:FireServer()
    
    print("🏆 AchievementController initialized")
end

function AchievementController:LoadSounds()
    -- Achievement unlock sound
    achievementSound = Instance.new("Sound")
    achievementSound.SoundId = "rbxasset://sounds/electronicpingshort.wav"
    achievementSound.Volume = 0.7
    achievementSound.Pitch = 1.3
    achievementSound.Parent = SoundService
    
    -- Daily bonus sound
    dailyBonusSound = Instance.new("Sound")
    dailyBonusSound.SoundId = "rbxasset://sounds/impact_water.mp3"
    dailyBonusSound.Volume = 0.6
    dailyBonusSound.Pitch = 1.1
    dailyBonusSound.Parent = SoundService
    
    -- Claim reward sound
    claimSound = Instance.new("Sound")
    claimSound.SoundId = "rbxasset://sounds/impact_water.mp3"
    claimSound.Volume = 0.8
    claimSound.Pitch = 1.4
    claimSound.Parent = SoundService
end

function AchievementController:SetupRemoteEvents()
    -- Achievement events
    RemoteEvents.AchievementDataUpdated.OnClientEvent:Connect(function(data)
        achievementData = data
        self:UpdateAchievementDisplay()
    end)
    
    RemoteEvents.AchievementUnlocked.OnClientEvent:Connect(function(achievement)
        self:ShowAchievementUnlockedPopup(achievement)
    end)
    
    RemoteEvents.AchievementClaimResult.OnClientEvent:Connect(function(result)
        self:HandleClaimResult(result)
    end)
    
    -- Daily bonus events
    RemoteEvents.ShowDailyBonusPopup.OnClientEvent:Connect(function(bonusData)
        self:ShowDailyBonusPopup(bonusData)
    end)
    
    RemoteEvents.DailyBonusResult.OnClientEvent:Connect(function(result)
        self:HandleDailyBonusResult(result)
    end)
end

function AchievementController:CreateAchievementGUI()
    -- Remove existing GUI
    local existingGui = playerGui:FindFirstChild("AchievementGui")
    if existingGui then
        existingGui:Destroy()
    end
    
    -- Create main GUI
    achievementGui = Instance.new("ScreenGui")
    achievementGui.Name = "AchievementGui"
    achievementGui.ResetOnSpawn = false
    achievementGui.Parent = playerGui
    
    -- Achievement button (top-right corner)
    local achievementButton = Instance.new("TextButton")
    achievementButton.Name = "AchievementButton"
    achievementButton.Size = UDim2.new(0, 60, 0, 60)
    achievementButton.Position = UDim2.new(1, -70, 0, 10)
    achievementButton.BackgroundColor3 = Color3.fromRGB(255, 215, 0)
    achievementButton.BorderSizePixel = 0
    achievementButton.Text = "🏆"
    achievementButton.TextScaled = true
    achievementButton.Font = Enum.Font.GothamBold
    achievementButton.Parent = achievementGui
    
    local buttonCorner = Instance.new("UICorner")
    buttonCorner.CornerRadius = UDim.new(0, 12)
    buttonCorner.Parent = achievementButton
    
    local buttonStroke = Instance.new("UIStroke")
    buttonStroke.Color = Color3.fromRGB(200, 170, 0)
    buttonStroke.Thickness = 2
    buttonStroke.Parent = achievementButton
    
    -- Notification badge (for unclaimed achievements)
    local notificationBadge = Instance.new("Frame")
    notificationBadge.Name = "NotificationBadge"
    notificationBadge.Size = UDim2.new(0, 20, 0, 20)
    notificationBadge.Position = UDim2.new(1, -5, 0, -5)
    notificationBadge.BackgroundColor3 = Color3.fromRGB(255, 50, 50)
    notificationBadge.BorderSizePixel = 0
    notificationBadge.Visible = false
    notificationBadge.ZIndex = 5
    notificationBadge.Parent = achievementButton
    
    local badgeCorner = Instance.new("UICorner")
    badgeCorner.CornerRadius = UDim.new(0.5, 0)
    badgeCorner.Parent = notificationBadge
    
    local badgeText = Instance.new("TextLabel")
    badgeText.Size = UDim2.new(1, 0, 1, 0)
    badgeText.BackgroundTransparency = 1
    badgeText.Text = "!"
    badgeText.TextColor3 = Color3.fromRGB(255, 255, 255)
    badgeText.TextScaled = true
    badgeText.Font = Enum.Font.GothamBold
    badgeText.Parent = notificationBadge
    
    -- Button click handler
    achievementButton.MouseButton1Click:Connect(function()
        if isAchievementOpen then
            self:HideAchievementPanel()
        else
            self:ShowAchievementPanel()
        end
    end)
    
    -- Hover effects
    achievementButton.MouseEnter:Connect(function()
        local hoverTween = TweenService:Create(
            achievementButton,
            TweenInfo.new(0.2, Enum.EasingStyle.Quad),
            {Size = UDim2.new(0, 65, 0, 65)}
        )
        hoverTween:Play()
    end)
    
    achievementButton.MouseLeave:Connect(function()
        local normalTween = TweenService:Create(
            achievementButton,
            TweenInfo.new(0.2, Enum.EasingStyle.Quad),
            {Size = UDim2.new(0, 60, 0, 60)}
        )
        normalTween:Play()
    end)
end

function AchievementController:ShowAchievementPanel()
    if isAchievementOpen then return end
    
    isAchievementOpen = true
    
    -- Create achievement panel
    local achievementPanel = Instance.new("Frame")
    achievementPanel.Name = "AchievementPanel"
    achievementPanel.Size = UDim2.new(0, 450, 0, 500)
    achievementPanel.Position = UDim2.new(1, -460, 0, 80)
    achievementPanel.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
    achievementPanel.BorderSizePixel = 0
    achievementPanel.Parent = achievementGui
    
    local panelCorner = Instance.new("UICorner")
    panelCorner.CornerRadius = UDim.new(0, 12)
    panelCorner.Parent = achievementPanel
    
    local panelStroke = Instance.new("UIStroke")
    panelStroke.Color = Color3.fromRGB(255, 215, 0)
    panelStroke.Thickness = 2
    panelStroke.Parent = achievementPanel
    
    -- Title
    local titleLabel = Instance.new("TextLabel")
    titleLabel.Name = "Title"
    titleLabel.Size = UDim2.new(1, -20, 0, 40)
    titleLabel.Position = UDim2.new(0, 10, 0, 10)
    titleLabel.BackgroundTransparency = 1
    titleLabel.Text = "🏆 ACHIEVEMENTS"
    titleLabel.TextColor3 = Color3.fromRGB(255, 215, 0)
    titleLabel.TextScaled = true
    titleLabel.Font = Enum.Font.GothamBold
    titleLabel.Parent = achievementPanel
    
    -- Close button
    local closeButton = Instance.new("TextButton")
    closeButton.Name = "CloseButton"
    closeButton.Size = UDim2.new(0, 30, 0, 30)
    closeButton.Position = UDim2.new(1, -40, 0, 10)
    closeButton.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
    closeButton.BorderSizePixel = 0
    closeButton.Text = "✕"
    closeButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    closeButton.TextScaled = true
    closeButton.Font = Enum.Font.GothamBold
    closeButton.Parent = achievementPanel
    
    local closeCorner = Instance.new("UICorner")
    closeCorner.CornerRadius = UDim.new(0, 8)
    closeCorner.Parent = closeButton
    
    closeButton.MouseButton1Click:Connect(function()
        self:HideAchievementPanel()
    end)
    
    -- Scroll frame for achievements
    local scrollFrame = Instance.new("ScrollingFrame")
    scrollFrame.Name = "ScrollFrame"
    scrollFrame.Size = UDim2.new(1, -20, 1, -70)
    scrollFrame.Position = UDim2.new(0, 10, 0, 60)
    scrollFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
    scrollFrame.BorderSizePixel = 0
    scrollFrame.ScrollBarThickness = 8
    scrollFrame.ScrollBarImageColor3 = Color3.fromRGB(255, 215, 0)
    scrollFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
    scrollFrame.Parent = achievementPanel
    
    local scrollCorner = Instance.new("UICorner")
    scrollCorner.CornerRadius = UDim.new(0, 8)
    scrollCorner.Parent = scrollFrame
    
    -- Layout for achievements
    local listLayout = Instance.new("UIListLayout")
    listLayout.SortOrder = Enum.SortOrder.LayoutOrder
    listLayout.Padding = UDim.new(0, 8)
    listLayout.Parent = scrollFrame
    
    -- Update canvas size when content changes
    listLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        scrollFrame.CanvasSize = UDim2.new(0, 0, 0, listLayout.AbsoluteContentSize.Y + 16)
    end)
    
    -- Populate with achievements
    self:PopulateAchievements(scrollFrame)
    
    -- Animate in
    achievementPanel.Position = UDim2.new(1, 0, 0, 80)
    local animateIn = TweenService:Create(
        achievementPanel,
        TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
        {Position = UDim2.new(1, -460, 0, 80)}
    )
    animateIn:Play()
end

function AchievementController:HideAchievementPanel()
    if not isAchievementOpen then return end
    
    isAchievementOpen = false
    local achievementPanel = achievementGui:FindFirstChild("AchievementPanel")
    
    if achievementPanel then
        local animateOut = TweenService:Create(
            achievementPanel,
            TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.In),
            {Position = UDim2.new(1, 0, 0, 80)}
        )
        
        animateOut:Play()
        animateOut.Completed:Connect(function()
            achievementPanel:Destroy()
        end)
    end
end

function AchievementController:PopulateAchievements(scrollFrame)
    -- Clear existing achievements
    for _, child in pairs(scrollFrame:GetChildren()) do
        if child:IsA("Frame") and child.Name:find("Achievement") then
            child:Destroy()
        end
    end
    
    -- Create achievement frames
    for i, achievement in pairs(achievementData) do
        local achievementFrame = self:CreateAchievementFrame(achievement, i)
        achievementFrame.Parent = scrollFrame
    end
end

function AchievementController:CreateAchievementFrame(achievement, index)
    local achievementFrame = Instance.new("Frame")
    achievementFrame.Name = "Achievement" .. index
    achievementFrame.Size = UDim2.new(1, -16, 0, 100)
    achievementFrame.BackgroundColor3 = achievement.completed and Color3.fromRGB(0, 100, 0) or Color3.fromRGB(50, 50, 50)
    achievementFrame.BorderSizePixel = 0
    achievementFrame.LayoutOrder = index
    
    local frameCorner = Instance.new("UICorner")
    frameCorner.CornerRadius = UDim.new(0, 8)
    frameCorner.Parent = achievementFrame
    
    local frameStroke = Instance.new("UIStroke")
    frameStroke.Color = achievement.completed and Color3.fromRGB(0, 200, 0) or Color3.fromRGB(100, 100, 100)
    frameStroke.Thickness = 2
    frameStroke.Parent = achievementFrame
    
    -- Icon
    local iconLabel = Instance.new("TextLabel")
    iconLabel.Size = UDim2.new(0, 60, 0, 60)
    iconLabel.Position = UDim2.new(0, 10, 0, 20)
    iconLabel.BackgroundTransparency = 1
    iconLabel.Text = achievement.icon
    iconLabel.TextScaled = true
    iconLabel.Font = Enum.Font.SourceSansBold
    iconLabel.Parent = achievementFrame
    
    -- Name
    local nameLabel = Instance.new("TextLabel")
    nameLabel.Size = UDim2.new(1, -80, 0, 25)
    nameLabel.Position = UDim2.new(0, 80, 0, 10)
    nameLabel.BackgroundTransparency = 1
    nameLabel.Text = achievement.name
    nameLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    nameLabel.TextScaled = true
    nameLabel.Font = Enum.Font.GothamBold
    nameLabel.TextXAlignment = Enum.TextXAlignment.Left
    nameLabel.Parent = achievementFrame
    
    -- Description
    local descLabel = Instance.new("TextLabel")
    descLabel.Size = UDim2.new(1, -80, 0, 20)
    descLabel.Position = UDim2.new(0, 80, 0, 35)
    descLabel.BackgroundTransparency = 1
    descLabel.Text = achievement.description
    descLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
    descLabel.TextScaled = true
    descLabel.Font = Enum.Font.Gotham
    descLabel.TextXAlignment = Enum.TextXAlignment.Left
    descLabel.Parent = achievementFrame
    
    -- Progress bar
    local progressBg = Instance.new("Frame")
    progressBg.Size = UDim2.new(0, 200, 0, 8)
    progressBg.Position = UDim2.new(0, 80, 0, 60)
    progressBg.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
    progressBg.BorderSizePixel = 0
    progressBg.Parent = achievementFrame
    
    local progressCorner = Instance.new("UICorner")
    progressCorner.CornerRadius = UDim.new(0, 4)
    progressCorner.Parent = progressBg
    
    local progressBar = Instance.new("Frame")
    progressBar.Size = UDim2.new(achievement.progressPercent / 100, 0, 1, 0)
    progressBar.BackgroundColor3 = achievement.completed and Color3.fromRGB(0, 255, 0) or Color3.fromRGB(255, 215, 0)
    progressBar.BorderSizePixel = 0
    progressBar.Parent = progressBg
    
    local barCorner = Instance.new("UICorner")
    barCorner.CornerRadius = UDim.new(0, 4)
    barCorner.Parent = progressBar
    
    -- Progress text
    local progressText = Instance.new("TextLabel")
    progressText.Size = UDim2.new(0, 100, 0, 15)
    progressText.Position = UDim2.new(0, 80, 0, 75)
    progressText.BackgroundTransparency = 1
    progressText.Text = achievement.progress .. "/" .. achievement.targetValue
    progressText.TextColor3 = Color3.fromRGB(150, 150, 150)
    progressText.TextScaled = true
    progressText.Font = Enum.Font.Gotham
    progressText.TextXAlignment = Enum.TextXAlignment.Left
    progressText.Parent = achievementFrame
    
    -- Reward button
    if achievement.completed and not achievement.claimed then
        local claimButton = Instance.new("TextButton")
        claimButton.Size = UDim2.new(0, 80, 0, 30)
        claimButton.Position = UDim2.new(1, -90, 0, 35)
        claimButton.BackgroundColor3 = Color3.fromRGB(0, 200, 0)
        claimButton.BorderSizePixel = 0
        claimButton.Text = "🎁 CLAIM"
        claimButton.TextColor3 = Color3.fromRGB(255, 255, 255)
        claimButton.TextScaled = true
        claimButton.Font = Enum.Font.GothamBold
        claimButton.Parent = achievementFrame
        
        local claimCorner = Instance.new("UICorner")
        claimCorner.CornerRadius = UDim.new(0, 6)
        claimCorner.Parent = claimButton
        
        claimButton.MouseButton1Click:Connect(function()
            RemoteEvents.ClaimAchievementReward:FireServer(achievement.id)
        end)
    elseif achievement.claimed then
        local claimedLabel = Instance.new("TextLabel")
        claimedLabel.Size = UDim2.new(0, 80, 0, 30)
        claimedLabel.Position = UDim2.new(1, -90, 0, 35)
        claimedLabel.BackgroundTransparency = 1
        claimedLabel.Text = "✅ CLAIMED"
        claimedLabel.TextColor3 = Color3.fromRGB(0, 200, 0)
        claimedLabel.TextScaled = true
        claimedLabel.Font = Enum.Font.GothamBold
        claimedLabel.Parent = achievementFrame
    end
    
    return achievementFrame
end

function AchievementController:ShowDailyBonusPopup(bonusData)
    if dailyBonusGui then
        dailyBonusGui:Destroy()
    end
    
    -- Play bonus sound
    if dailyBonusSound then
        dailyBonusSound:Play()
    end
    
    -- Create daily bonus GUI
    dailyBonusGui = Instance.new("ScreenGui")
    dailyBonusGui.Name = "DailyBonusGui"
    dailyBonusGui.Parent = playerGui
    
    -- Background overlay
    local overlay = Instance.new("Frame")
    overlay.Size = UDim2.new(1, 0, 1, 0)
    overlay.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    overlay.BackgroundTransparency = 0.5
    overlay.BorderSizePixel = 0
    overlay.Parent = dailyBonusGui
    
    -- Bonus frame
    local bonusFrame = Instance.new("Frame")
    bonusFrame.Size = UDim2.new(0, 400, 0, 350)
    bonusFrame.Position = UDim2.new(0.5, -200, 0.5, -175)
    bonusFrame.BackgroundColor3 = Color3.fromRGB(255, 215, 0)
    bonusFrame.BorderSizePixel = 0
    bonusFrame.Parent = overlay
    
    local frameCorner = Instance.new("UICorner")
    frameCorner.CornerRadius = UDim.new(0, 15)
    frameCorner.Parent = bonusFrame
    
    -- Inner frame
    local innerFrame = Instance.new("Frame")
    innerFrame.Size = UDim2.new(1, -10, 1, -10)
    innerFrame.Position = UDim2.new(0, 5, 0, 5)
    innerFrame.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
    innerFrame.BorderSizePixel = 0
    innerFrame.Parent = bonusFrame
    
    local innerCorner = Instance.new("UICorner")
    innerCorner.CornerRadius = UDim.new(0, 12)
    innerCorner.Parent = innerFrame
    
    -- Title
    local titleLabel = Instance.new("TextLabel")
    titleLabel.Size = UDim2.new(1, -20, 0, 60)
    titleLabel.Position = UDim2.new(0, 10, 0, 10)
    titleLabel.BackgroundTransparency = 1
    titleLabel.Text = "🎁 DAILY BONUS!"
    titleLabel.TextColor3 = Color3.fromRGB(255, 215, 0)
    titleLabel.TextScaled = true
    titleLabel.Font = Enum.Font.GothamBold
    titleLabel.Parent = innerFrame
    
    -- Day info
    local dayLabel = Instance.new("TextLabel")
    dayLabel.Size = UDim2.new(1, -20, 0, 40)
    dayLabel.Position = UDim2.new(0, 10, 0, 80)
    dayLabel.BackgroundTransparency = 1
    dayLabel.Text = "Day " .. bonusData.streak .. " Login Streak!"
    dayLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    dayLabel.TextScaled = true
    dayLabel.Font = Enum.Font.Gotham
    dayLabel.Parent = innerFrame
    
    -- Coin reward
    local coinIcon = Instance.new("TextLabel")
    coinIcon.Size = UDim2.new(0, 80, 0, 80)
    coinIcon.Position = UDim2.new(0.5, -40, 0, 130)
    coinIcon.BackgroundTransparency = 1
    coinIcon.Text = "💰"
    coinIcon.TextScaled = true
    coinIcon.Font = Enum.Font.SourceSansBold
    coinIcon.Parent = innerFrame
    
    local rewardLabel = Instance.new("TextLabel")
    rewardLabel.Size = UDim2.new(1, -20, 0, 40)
    rewardLabel.Position = UDim2.new(0, 10, 0, 220)
    rewardLabel.BackgroundTransparency = 1
    rewardLabel.Text = "+" .. bonusData.bonus.coins .. " Coins!"
    rewardLabel.TextColor3 = Color3.fromRGB(255, 215, 0)
    rewardLabel.TextScaled = true
    rewardLabel.Font = Enum.Font.GothamBold
    rewardLabel.Parent = innerFrame
    
    -- Claim button
    local claimButton = Instance.new("TextButton")
    claimButton.Size = UDim2.new(0, 150, 0, 50)
    claimButton.Position = UDim2.new(0.5, -75, 0, 280)
    claimButton.BackgroundColor3 = Color3.fromRGB(0, 200, 0)
    claimButton.BorderSizePixel = 0
    claimButton.Text = "CLAIM BONUS!"
    claimButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    claimButton.TextScaled = true
    claimButton.Font = Enum.Font.GothamBold
    claimButton.Parent = innerFrame
    
    local claimCorner = Instance.new("UICorner")
    claimCorner.CornerRadius = UDim.new(0, 10)
    claimCorner.Parent = claimButton
    
    claimButton.MouseButton1Click:Connect(function()
        RemoteEvents.ClaimDailyBonus:FireServer()
    end)
    
    -- Animate in
    bonusFrame.Size = UDim2.new(0, 0, 0, 0)
    local animateIn = TweenService:Create(
        bonusFrame,
        TweenInfo.new(0.5, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
        {Size = UDim2.new(0, 400, 0, 350)}
    )
    animateIn:Play()
end

function AchievementController:ShowAchievementUnlockedPopup(achievement)
    if achievementSound then
        achievementSound:Play()
    end
    
    -- Create achievement popup
    local popupGui = Instance.new("ScreenGui")
    popupGui.Name = "AchievementPopup"
    popupGui.Parent = playerGui
    
    local popupFrame = Instance.new("Frame")
    popupFrame.Size = UDim2.new(0, 350, 0, 120)
    popupFrame.Position = UDim2.new(0.5, -175, 0, -150)
    popupFrame.BackgroundColor3 = Color3.fromRGB(255, 215, 0)
    popupFrame.BorderSizePixel = 0
    popupFrame.Parent = popupGui
    
    local frameCorner = Instance.new("UICorner")
    frameCorner.CornerRadius = UDim.new(0, 12)
    frameCorner.Parent = popupFrame
    
    -- Inner frame
    local innerFrame = Instance.new("Frame")
    innerFrame.Size = UDim2.new(1, -6, 1, -6)
    innerFrame.Position = UDim2.new(0, 3, 0, 3)
    innerFrame.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
    innerFrame.BorderSizePixel = 0
    innerFrame.Parent = popupFrame
    
    local innerCorner = Instance.new("UICorner")
    innerCorner.CornerRadius = UDim.new(0, 10)
    innerCorner.Parent = innerFrame
    
    -- Achievement icon
    local iconLabel = Instance.new("TextLabel")
    iconLabel.Size = UDim2.new(0, 60, 0, 60)
    iconLabel.Position = UDim2.new(0, 15, 0, 30)
    iconLabel.BackgroundTransparency = 1
    iconLabel.Text = achievement.icon
    iconLabel.TextScaled = true
    iconLabel.Font = Enum.Font.SourceSansBold
    iconLabel.Parent = innerFrame
    
    -- Achievement text
    local titleLabel = Instance.new("TextLabel")
    titleLabel.Size = UDim2.new(1, -90, 0, 30)
    titleLabel.Position = UDim2.new(0, 85, 0, 15)
    titleLabel.BackgroundTransparency = 1
    titleLabel.Text = "🏆 ACHIEVEMENT UNLOCKED!"
    titleLabel.TextColor3 = Color3.fromRGB(255, 215, 0)
    titleLabel.TextScaled = true
    titleLabel.Font = Enum.Font.GothamBold
    titleLabel.TextXAlignment = Enum.TextXAlignment.Left
    titleLabel.Parent = innerFrame
    
    local nameLabel = Instance.new("TextLabel")
    nameLabel.Size = UDim2.new(1, -90, 0, 25)
    nameLabel.Position = UDim2.new(0, 85, 0, 45)
    nameLabel.BackgroundTransparency = 1
    nameLabel.Text = achievement.name
    nameLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    nameLabel.TextScaled = true
    nameLabel.Font = Enum.Font.Gotham
    nameLabel.TextXAlignment = Enum.TextXAlignment.Left
    nameLabel.Parent = innerFrame
    
    local rewardLabel = Instance.new("TextLabel")
    rewardLabel.Size = UDim2.new(1, -90, 0, 20)
    rewardLabel.Position = UDim2.new(0, 85, 0, 75)
    rewardLabel.BackgroundTransparency = 1
    rewardLabel.Text = "Reward: " .. achievement.reward.name
    rewardLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
    rewardLabel.TextScaled = true
    rewardLabel.Font = Enum.Font.Gotham
    rewardLabel.TextXAlignment = Enum.TextXAlignment.Left
    rewardLabel.Parent = innerFrame
    
    -- Animate in
    local animateIn = TweenService:Create(
        popupFrame,
        TweenInfo.new(0.5, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
        {Position = UDim2.new(0.5, -175, 0, 20)}
    )
    animateIn:Play()
    
    -- Auto-hide after 4 seconds
    spawn(function()
        wait(4)
        local animateOut = TweenService:Create(
            popupFrame,
            TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
            {Position = UDim2.new(0.5, -175, 0, -150)}
        )
        animateOut:Play()
        
        animateOut.Completed:Connect(function()
            popupGui:Destroy()
        end)
    end)
end

function AchievementController:HandleClaimResult(result)
    if result.success then
        if claimSound then
            claimSound:Play()
        end
        
        -- Update achievement display
        RemoteEvents.RequestAchievementData:FireServer()
        
        -- Show success notification
        self:ShowNotification("🎁 Achievement reward claimed!", Color3.fromRGB(0, 200, 0))
    else
        self:ShowNotification("❌ " .. result.message, Color3.fromRGB(200, 0, 0))
    end
end

function AchievementController:HandleDailyBonusResult(result)
    if result.success then
        if claimSound then
            claimSound:Play()
        end
        
        -- Close daily bonus popup
        if dailyBonusGui then
            dailyBonusGui:Destroy()
            dailyBonusGui = nil
        end
        
        -- Show success notification
        self:ShowNotification("🎁 Daily bonus claimed! +" .. result.coinsEarned .. " coins", Color3.fromRGB(0, 200, 0))
    else
        self:ShowNotification("❌ " .. result.message, Color3.fromRGB(200, 0, 0))
    end
end

function AchievementController:ShowNotification(message, color)
    local notificationGui = Instance.new("ScreenGui")
    notificationGui.Name = "NotificationGui"
    notificationGui.Parent = playerGui
    
    local notificationFrame = Instance.new("Frame")
    notificationFrame.Size = UDim2.new(0, 300, 0, 60)
    notificationFrame.Position = UDim2.new(0.5, -150, 0, -70)
    notificationFrame.BackgroundColor3 = color
    notificationFrame.BorderSizePixel = 0
    notificationFrame.Parent = notificationGui
    
    local frameCorner = Instance.new("UICorner")
    frameCorner.CornerRadius = UDim.new(0, 10)
    frameCorner.Parent = notificationFrame
    
    local messageLabel = Instance.new("TextLabel")
    messageLabel.Size = UDim2.new(1, -20, 1, 0)
    messageLabel.Position = UDim2.new(0, 10, 0, 0)
    messageLabel.BackgroundTransparency = 1
    messageLabel.Text = message
    messageLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    messageLabel.TextScaled = true
    messageLabel.Font = Enum.Font.GothamBold
    messageLabel.Parent = notificationFrame
    
    -- Animate in
    local animateIn = TweenService:Create(
        notificationFrame,
        TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
        {Position = UDim2.new(0.5, -150, 0, 20)}
    )
    animateIn:Play()
    
    -- Auto-hide
    spawn(function()
        wait(3)
        local animateOut = TweenService:Create(
            notificationFrame,
            TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
            {Position = UDim2.new(0.5, -150, 0, -70)}
        )
        animateOut:Play()
        
        animateOut.Completed:Connect(function()
            notificationGui:Destroy()
        end)
    end)
end

function AchievementController:UpdateAchievementDisplay()
    -- Update notification badge
    local button = achievementGui:FindFirstChild("AchievementButton")
    if button then
        local badge = button:FindFirstChild("NotificationBadge")
        local hasUnclaimedAchievements = false
        
        for _, achievement in pairs(achievementData) do
            if achievement.completed and not achievement.claimed then
                hasUnclaimedAchievements = true
                break
            end
        end
        
        if badge then
            badge.Visible = hasUnclaimedAchievements
        end
    end
    
    -- Update panel if open
    if isAchievementOpen then
        local panel = achievementGui:FindFirstChild("AchievementPanel")
        if panel then
            local scrollFrame = panel:FindFirstChild("ScrollFrame")
            if scrollFrame then
                self:PopulateAchievements(scrollFrame)
            end
        end
    end
end

function AchievementController:Cleanup()
    if achievementGui then
        achievementGui:Destroy()
        achievementGui = nil
    end
    
    if dailyBonusGui then
        dailyBonusGui:Destroy()
        dailyBonusGui = nil
    end
    
    isAchievementOpen = false
    achievementData = {}
end

return AchievementController
