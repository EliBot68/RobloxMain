-- AchievementController.luau
-- Complete client-side achievement UI, popups, and daily bonus system

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local SoundService = game:GetService("SoundService")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local SafeRequire = require(ReplicatedStorage.Shared.utils.SafeRequire)
local RemoteEvents = SafeRequire.require(ReplicatedStorage.Shared.modules.RemoteEvents)

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local AchievementController = {}

-- GUI state
local achievementGui = nil
local dailyBonusGui = nil
local achievementPopupGui = nil
local isAchievementMenuOpen = false
local achievementData = {}

-- Sound effects
local achievementSound = nil
local dailyBonusSound = nil
local claimSound = nil

-- Achievement notification queue
local notificationQueue = {}
local isShowingNotification = false

function AchievementController:Init()
    print("🏆 AchievementController initializing...")
    
    self:LoadSounds()
    self:SetupRemoteEvents()
    self:CreateAchievementGUI()
    self:CreateDailyBonusGUI()
    self:CreateAchievementPopupGUI()
    
    -- Request initial data
    if RemoteEvents.RequestAchievementData then
        RemoteEvents.RequestAchievementData:FireServer()
    end
    
    print("✅ AchievementController initialized!")
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
    
    -- Claim sound
    claimSound = Instance.new("Sound")
    claimSound.SoundId = "rbxasset://sounds/button_click.wav"
    claimSound.Volume = 0.5
    claimSound.Pitch = 1.2
    claimSound.Parent = SoundService
end

function AchievementController:SetupRemoteEvents()
    if not RemoteEvents then
        warn("❌ RemoteEvents not available for AchievementController")
        return
    end
    
    -- Achievement data updated
    if RemoteEvents.AchievementDataUpdated then
        RemoteEvents.AchievementDataUpdated.OnClientEvent:Connect(function(data)
            self:UpdateAchievementData(data)
        end)
    end
    
    -- Achievement unlocked
    if RemoteEvents.AchievementUnlocked then
        RemoteEvents.AchievementUnlocked.OnClientEvent:Connect(function(achievement)
            self:ShowAchievementUnlocked(achievement)
        end)
    end
    
    -- Daily bonus popup
    if RemoteEvents.ShowDailyBonusPopup then
        RemoteEvents.ShowDailyBonusPopup.OnClientEvent:Connect(function(bonusData)
            self:ShowDailyBonusPopup(bonusData)
        end)
    end
    
    -- Achievement claim result
    if RemoteEvents.AchievementClaimResult then
        RemoteEvents.AchievementClaimResult.OnClientEvent:Connect(function(result)
            self:HandleClaimResult(result)
        end)
    end
end

function AchievementController:CreateAchievementGUI()
    -- Main achievement menu GUI
    achievementGui = Instance.new("ScreenGui")
    achievementGui.Name = "AchievementGUI"
    achievementGui.ResetOnSpawn = false
    achievementGui.Parent = playerGui
    
    -- Main frame
    local mainFrame = Instance.new("Frame")
    mainFrame.Name = "MainFrame"
    mainFrame.Size = UDim2.new(0.8, 0, 0.8, 0)
    mainFrame.Position = UDim2.new(0.1, 0, 0.1, 0)
    mainFrame.BackgroundColor3 = Color3.new(0.1, 0.1, 0.15)
    mainFrame.BorderSizePixel = 0
    mainFrame.Visible = false
    mainFrame.Parent = achievementGui
    
    local mainCorner = Instance.new("UICorner")
    mainCorner.CornerRadius = UDim.new(0, 15)
    mainCorner.Parent = mainFrame
    
    -- Header
    local header = Instance.new("Frame")
    header.Name = "Header"
    header.Size = UDim2.new(1, 0, 0, 60)
    header.Position = UDim2.new(0, 0, 0, 0)
    header.BackgroundColor3 = Color3.new(0.15, 0.15, 0.2)
    header.BorderSizePixel = 0
    header.Parent = mainFrame
    
    local headerCorner = Instance.new("UICorner")
    headerCorner.CornerRadius = UDim.new(0, 15)
    headerCorner.Parent = header
    
    local headerTitle = Instance.new("TextLabel")
    headerTitle.Name = "Title"
    headerTitle.Size = UDim2.new(1, -120, 1, 0)
    headerTitle.Position = UDim2.new(0, 20, 0, 0)
    headerTitle.BackgroundTransparency = 1
    headerTitle.Text = "🏆 ACHIEVEMENTS"
    headerTitle.TextColor3 = Color3.new(1, 1, 1)
    headerTitle.TextSize = 28
    headerTitle.Font = Enum.Font.SourceSansBold
    headerTitle.TextXAlignment = Enum.TextXAlignment.Left
    headerTitle.Parent = header
    
    -- Close button
    local closeButton = Instance.new("TextButton")
    closeButton.Name = "CloseButton"
    closeButton.Size = UDim2.new(0, 40, 0, 40)
    closeButton.Position = UDim2.new(1, -50, 0, 10)
    closeButton.BackgroundColor3 = Color3.new(0.8, 0.2, 0.2)
    closeButton.BorderSizePixel = 0
    closeButton.Text = "✕"
    closeButton.TextColor3 = Color3.new(1, 1, 1)
    closeButton.TextSize = 20
    closeButton.Font = Enum.Font.SourceSansBold
    closeButton.Parent = header
    
    local closeCorner = Instance.new("UICorner")
    closeCorner.CornerRadius = UDim.new(0, 8)
    closeCorner.Parent = closeButton
    
    closeButton.MouseButton1Click:Connect(function()
        self:CloseAchievementMenu()
    end)
    
    -- Content area
    local contentFrame = Instance.new("Frame")
    contentFrame.Name = "Content"
    contentFrame.Size = UDim2.new(1, -20, 1, -80)
    contentFrame.Position = UDim2.new(0, 10, 0, 70)
    contentFrame.BackgroundTransparency = 1
    contentFrame.Parent = mainFrame
    
    -- Scroll frame for achievements
    local scrollFrame = Instance.new("ScrollingFrame")
    scrollFrame.Name = "AchievementScroll"
    scrollFrame.Size = UDim2.new(1, 0, 1, 0)
    scrollFrame.Position = UDim2.new(0, 0, 0, 0)
    scrollFrame.BackgroundTransparency = 1
    scrollFrame.BorderSizePixel = 0
    scrollFrame.ScrollBarThickness = 8
    scrollFrame.ScrollBarImageColor3 = Color3.new(0.3, 0.3, 0.3)
    scrollFrame.Parent = contentFrame
    
    local scrollLayout = Instance.new("UIListLayout")
    scrollLayout.SortOrder = Enum.SortOrder.LayoutOrder
    scrollLayout.Padding = UDim.new(0, 10)
    scrollLayout.Parent = scrollFrame
    
    -- Store references
    achievementGui.MainFrame = mainFrame
    achievementGui.ScrollFrame = scrollFrame
end

function AchievementController:CreateDailyBonusGUI()
    -- Daily bonus popup GUI
    dailyBonusGui = Instance.new("ScreenGui")
    dailyBonusGui.Name = "DailyBonusGUI"
    dailyBonusGui.ResetOnSpawn = false
    dailyBonusGui.Parent = playerGui
    
    -- Background overlay
    local overlay = Instance.new("Frame")
    overlay.Name = "Overlay"
    overlay.Size = UDim2.new(1, 0, 1, 0)
    overlay.Position = UDim2.new(0, 0, 0, 0)
    overlay.BackgroundColor3 = Color3.new(0, 0, 0)
    overlay.BackgroundTransparency = 0.5
    overlay.BorderSizePixel = 0
    overlay.Visible = false
    overlay.Parent = dailyBonusGui
    
    -- Popup frame
    local popupFrame = Instance.new("Frame")
    popupFrame.Name = "PopupFrame"
    popupFrame.Size = UDim2.new(0, 400, 0, 300)
    popupFrame.Position = UDim2.new(0.5, -200, 0.5, -150)
    popupFrame.BackgroundColor3 = Color3.new(0.1, 0.1, 0.2)
    popupFrame.BorderSizePixel = 0
    popupFrame.Parent = overlay
    
    local popupCorner = Instance.new("UICorner")
    popupCorner.CornerRadius = UDim.new(0, 20)
    popupCorner.Parent = popupFrame
    
    -- Title
    local title = Instance.new("TextLabel")
    title.Name = "Title"
    title.Size = UDim2.new(1, -20, 0, 50)
    title.Position = UDim2.new(0, 10, 0, 10)
    title.BackgroundTransparency = 1
    title.Text = "🎁 DAILY BONUS"
    title.TextColor3 = Color3.new(1, 1, 1)
    title.TextSize = 24
    title.Font = Enum.Font.SourceSansBold
    title.TextXAlignment = Enum.TextXAlignment.Center
    title.Parent = popupFrame
    
    -- Bonus day
    local dayLabel = Instance.new("TextLabel")
    dayLabel.Name = "DayLabel"
    dayLabel.Size = UDim2.new(1, -20, 0, 40)
    dayLabel.Position = UDim2.new(0, 10, 0, 60)
    dayLabel.BackgroundTransparency = 1
    dayLabel.Text = "Day 1"
    dayLabel.TextColor3 = Color3.new(1, 1, 0.5)
    dayLabel.TextSize = 20
    dayLabel.Font = Enum.Font.SourceSansBold
    dayLabel.TextXAlignment = Enum.TextXAlignment.Center
    dayLabel.Parent = popupFrame
    
    -- Rewards
    local rewardLabel = Instance.new("TextLabel")
    rewardLabel.Name = "RewardLabel"
    rewardLabel.Size = UDim2.new(1, -20, 0, 60)
    rewardLabel.Position = UDim2.new(0, 10, 0, 100)
    rewardLabel.BackgroundTransparency = 1
    rewardLabel.Text = "💰 25 Coins\n⭐ 10 XP"
    rewardLabel.TextColor3 = Color3.new(0.8, 1, 0.8)
    rewardLabel.TextSize = 18
    rewardLabel.Font = Enum.Font.SourceSans
    rewardLabel.TextXAlignment = Enum.TextXAlignment.Center
    rewardLabel.Parent = popupFrame
    
    -- Message
    local messageLabel = Instance.new("TextLabel")
    messageLabel.Name = "MessageLabel"
    messageLabel.Size = UDim2.new(1, -20, 0, 40)
    messageLabel.Position = UDim2.new(0, 10, 0, 160)
    messageLabel.BackgroundTransparency = 1
    messageLabel.Text = "Welcome back!"
    messageLabel.TextColor3 = Color3.new(0.9, 0.9, 0.9)
    messageLabel.TextSize = 16
    messageLabel.Font = Enum.Font.SourceSans
    messageLabel.TextXAlignment = Enum.TextXAlignment.Center
    messageLabel.TextWrapped = true
    messageLabel.Parent = popupFrame
    
    -- Claim button
    local claimButton = Instance.new("TextButton")
    claimButton.Name = "ClaimButton"
    claimButton.Size = UDim2.new(0, 120, 0, 40)
    claimButton.Position = UDim2.new(0.5, -60, 0, 220)
    claimButton.BackgroundColor3 = Color3.new(0.2, 0.8, 0.2)
    claimButton.BorderSizePixel = 0
    claimButton.Text = "CLAIM"
    claimButton.TextColor3 = Color3.new(1, 1, 1)
    claimButton.TextSize = 18
    claimButton.Font = Enum.Font.SourceSansBold
    claimButton.Parent = popupFrame
    
    local claimCorner = Instance.new("UICorner")
    claimCorner.CornerRadius = UDim.new(0, 10)
    claimCorner.Parent = claimButton
    
    claimButton.MouseButton1Click:Connect(function()
        self:HideDailyBonusPopup()
    end)
    
    -- Store references
    dailyBonusGui.Overlay = overlay
    dailyBonusGui.PopupFrame = popupFrame
end

function AchievementController:CreateAchievementPopupGUI()
    -- Achievement unlock popup GUI
    achievementPopupGui = Instance.new("ScreenGui")
    achievementPopupGui.Name = "AchievementPopupGUI"
    achievementPopupGui.ResetOnSpawn = false
    achievementPopupGui.Parent = playerGui
    
    -- Notification frame (positioned at top-right)
    local notificationFrame = Instance.new("Frame")
    notificationFrame.Name = "NotificationFrame"
    notificationFrame.Size = UDim2.new(0, 350, 0, 100)
    notificationFrame.Position = UDim2.new(1, 370, 0, 20) -- Start off-screen
    notificationFrame.BackgroundColor3 = Color3.new(0.1, 0.1, 0.2)
    notificationFrame.BorderSizePixel = 0
    notificationFrame.Parent = achievementPopupGui
    
    local notifCorner = Instance.new("UICorner")
    notifCorner.CornerRadius = UDim.new(0, 12)
    notifCorner.Parent = notificationFrame
    
    -- Glow effect
    local glow = Instance.new("ImageLabel")
    glow.Name = "Glow"
    glow.Size = UDim2.new(1, 20, 1, 20)
    glow.Position = UDim2.new(0, -10, 0, -10)
    glow.BackgroundTransparency = 1
    glow.Image = "rbxasset://textures/ui/Glow.png"
    glow.ImageColor3 = Color3.new(1, 1, 0)
    glow.ImageTransparency = 0.5
    glow.ScaleType = Enum.ScaleType.Slice
    glow.SliceCenter = Rect.new(12, 12, 12, 12)
    glow.Parent = notificationFrame
    
    -- Icon
    local icon = Instance.new("TextLabel")
    icon.Name = "Icon"
    icon.Size = UDim2.new(0, 60, 0, 60)
    icon.Position = UDim2.new(0, 10, 0, 20)
    icon.BackgroundTransparency = 1
    icon.Text = "🏆"
    icon.TextColor3 = Color3.new(1, 1, 1)
    icon.TextSize = 40
    icon.Font = Enum.Font.SourceSansBold
    icon.TextXAlignment = Enum.TextXAlignment.Center
    icon.Parent = notificationFrame
    
    -- Title
    local title = Instance.new("TextLabel")
    title.Name = "Title"
    title.Size = UDim2.new(1, -80, 0, 30)
    title.Position = UDim2.new(0, 70, 0, 15)
    title.BackgroundTransparency = 1
    title.Text = "ACHIEVEMENT UNLOCKED!"
    title.TextColor3 = Color3.new(1, 1, 0)
    title.TextSize = 14
    title.Font = Enum.Font.SourceSansBold
    title.TextXAlignment = Enum.TextXAlignment.Left
    title.Parent = notificationFrame
    
    -- Achievement name
    local achievementName = Instance.new("TextLabel")
    achievementName.Name = "AchievementName"
    achievementName.Size = UDim2.new(1, -80, 0, 25)
    achievementName.Position = UDim2.new(0, 70, 0, 40)
    achievementName.BackgroundTransparency = 1
    achievementName.Text = "Achievement Name"
    achievementName.TextColor3 = Color3.new(1, 1, 1)
    achievementName.TextSize = 16
    achievementName.Font = Enum.Font.SourceSans
    achievementName.TextXAlignment = Enum.TextXAlignment.Left
    achievementName.TextWrapped = true
    achievementName.Parent = notificationFrame
    
    -- Description
    local description = Instance.new("TextLabel")
    description.Name = "Description"
    description.Size = UDim2.new(1, -80, 0, 20)
    description.Position = UDim2.new(0, 70, 0, 65)
    description.BackgroundTransparency = 1
    description.Text = "Achievement description"
    description.TextColor3 = Color3.new(0.8, 0.8, 0.8)
    description.TextSize = 12
    description.Font = Enum.Font.SourceSans
    description.TextXAlignment = Enum.TextXAlignment.Left
    description.TextWrapped = true
    description.Parent = notificationFrame
    
    -- Store reference
    achievementPopupGui.NotificationFrame = notificationFrame
end

function AchievementController:UpdateAchievementData(data)
    achievementData = data
    self:RefreshAchievementDisplay()
end

function AchievementController:RefreshAchievementDisplay()
    if not achievementGui or not achievementGui.ScrollFrame then return end
    
    local scrollFrame = achievementGui.ScrollFrame
    
    -- Clear existing children
    for _, child in pairs(scrollFrame:GetChildren()) do
        if child:IsA("Frame") then
            child:Destroy()
        end
    end
    
    if not achievementData.definitions then return end
    
    -- Create achievement entries
    for _, achievement in pairs(achievementData.definitions) do
        self:CreateAchievementEntry(scrollFrame, achievement)
    end
    
    -- Update scroll size
    local layout = scrollFrame:FindFirstChild("UIListLayout")
    if layout then
        scrollFrame.CanvasSize = UDim2.new(0, 0, 0, layout.AbsoluteContentSize.Y + 10)
    end
end

function AchievementController:CreateAchievementEntry(parent, achievement)
    local progress = achievementData.achievements and achievementData.achievements[achievement.id]
    if not progress then return end
    
    -- Main entry frame
    local entryFrame = Instance.new("Frame")
    entryFrame.Name = achievement.id
    entryFrame.Size = UDim2.new(1, -10, 0, 80)
    entryFrame.BackgroundColor3 = progress.completed and Color3.new(0.15, 0.25, 0.15) or Color3.new(0.15, 0.15, 0.2)
    entryFrame.BorderSizePixel = 0
    entryFrame.Parent = parent
    
    local entryCorner = Instance.new("UICorner")
    entryCorner.CornerRadius = UDim.new(0, 8)
    entryCorner.Parent = entryFrame
    
    -- Icon
    local icon = Instance.new("TextLabel")
    icon.Name = "Icon"
    icon.Size = UDim2.new(0, 60, 0, 60)
    icon.Position = UDim2.new(0, 10, 0, 10)
    icon.BackgroundTransparency = 1
    icon.Text = achievement.icon
    icon.TextColor3 = progress.completed and Color3.new(1, 1, 0) or Color3.new(0.7, 0.7, 0.7)
    icon.TextSize = 32
    icon.Font = Enum.Font.SourceSansBold
    icon.TextXAlignment = Enum.TextXAlignment.Center
    icon.Parent = entryFrame
    
    -- Name
    local nameLabel = Instance.new("TextLabel")
    nameLabel.Name = "Name"
    nameLabel.Size = UDim2.new(1, -200, 0, 25)
    nameLabel.Position = UDim2.new(0, 80, 0, 10)
    nameLabel.BackgroundTransparency = 1
    nameLabel.Text = achievement.name
    nameLabel.TextColor3 = progress.completed and Color3.new(1, 1, 1) or Color3.new(0.8, 0.8, 0.8)
    nameLabel.TextSize = 16
    nameLabel.Font = Enum.Font.SourceSansBold
    nameLabel.TextXAlignment = Enum.TextXAlignment.Left
    nameLabel.Parent = entryFrame
    
    -- Description
    local descLabel = Instance.new("TextLabel")
    descLabel.Name = "Description"
    descLabel.Size = UDim2.new(1, -200, 0, 20)
    descLabel.Position = UDim2.new(0, 80, 0, 35)
    descLabel.BackgroundTransparency = 1
    descLabel.Text = achievement.description
    descLabel.TextColor3 = Color3.new(0.7, 0.7, 0.7)
    descLabel.TextSize = 12
    descLabel.Font = Enum.Font.SourceSans
    descLabel.TextXAlignment = Enum.TextXAlignment.Left
    descLabel.TextWrapped = true
    descLabel.Parent = entryFrame
    
    -- Progress bar
    local progressBG = Instance.new("Frame")
    progressBG.Name = "ProgressBG"
    progressBG.Size = UDim2.new(1, -200, 0, 8)
    progressBG.Position = UDim2.new(0, 80, 0, 60)
    progressBG.BackgroundColor3 = Color3.new(0.1, 0.1, 0.1)
    progressBG.BorderSizePixel = 0
    progressBG.Parent = entryFrame
    
    local progressCorner = Instance.new("UICorner")
    progressCorner.CornerRadius = UDim.new(0, 4)
    progressCorner.Parent = progressBG
    
    local progressBar = Instance.new("Frame")
    progressBar.Name = "ProgressBar"
    local progressPercent = math.min(progress.progress / achievement.targetValue, 1)
    progressBar.Size = UDim2.new(progressPercent, 0, 1, 0)
    progressBar.Position = UDim2.new(0, 0, 0, 0)
    progressBar.BackgroundColor3 = progress.completed and Color3.new(0.2, 0.8, 0.2) or Color3.new(0.3, 0.6, 1)
    progressBar.BorderSizePixel = 0
    progressBar.Parent = progressBG
    
    local barCorner = Instance.new("UICorner")
    barCorner.CornerRadius = UDim.new(0, 4)
    barCorner.Parent = progressBar
    
    -- Progress text
    local progressText = Instance.new("TextLabel")
    progressText.Name = "ProgressText"
    progressText.Size = UDim2.new(1, -200, 0, 15)
    progressText.Position = UDim2.new(0, 80, 0, 68)
    progressText.BackgroundTransparency = 1
    progressText.Text = progress.progress .. " / " .. achievement.targetValue
    progressText.TextColor3 = Color3.new(0.7, 0.7, 0.7)
    progressText.TextSize = 10
    progressText.Font = Enum.Font.SourceSans
    progressText.TextXAlignment = Enum.TextXAlignment.Left
    progressText.Parent = entryFrame
    
    -- Claim button (if completed but not claimed)
    if progress.completed and not progress.claimed then
        local claimButton = Instance.new("TextButton")
        claimButton.Name = "ClaimButton"
        claimButton.Size = UDim2.new(0, 100, 0, 30)
        claimButton.Position = UDim2.new(1, -110, 0, 25)
        claimButton.BackgroundColor3 = Color3.new(0.2, 0.8, 0.2)
        claimButton.BorderSizePixel = 0
        claimButton.Text = "CLAIM"
        claimButton.TextColor3 = Color3.new(1, 1, 1)
        claimButton.TextSize = 14
        claimButton.Font = Enum.Font.SourceSansBold
        claimButton.Parent = entryFrame
        
        local claimCorner = Instance.new("UICorner")
        claimCorner.CornerRadius = UDim.new(0, 6)
        claimCorner.Parent = claimButton
        
        claimButton.MouseButton1Click:Connect(function()
            self:ClaimAchievement(achievement.id)
        end)
    elseif progress.claimed then
        -- Claimed indicator
        local claimedLabel = Instance.new("TextLabel")
        claimedLabel.Name = "ClaimedLabel"
        claimedLabel.Size = UDim2.new(0, 100, 0, 30)
        claimedLabel.Position = UDim2.new(1, -110, 0, 25)
        claimedLabel.BackgroundTransparency = 1
        claimedLabel.Text = "✓ CLAIMED"
        claimedLabel.TextColor3 = Color3.new(0.5, 1, 0.5)
        claimedLabel.TextSize = 12
        claimedLabel.Font = Enum.Font.SourceSansBold
        claimedLabel.Parent = entryFrame
    end
end

function AchievementController:ShowAchievementUnlocked(achievement)
    -- Add to notification queue
    table.insert(notificationQueue, achievement)
    
    -- Process queue if not already showing
    if not isShowingNotification then
        self:ProcessNotificationQueue()
    end
end

function AchievementController:ProcessNotificationQueue()
    if #notificationQueue == 0 then
        isShowingNotification = false
        return
    end
    
    isShowingNotification = true
    local achievement = table.remove(notificationQueue, 1)
    
    -- Play sound
    if achievementSound then
        achievementSound:Play()
    end
    
    -- Update notification content
    local frame = achievementPopupGui.NotificationFrame
    frame.Icon.Text = achievement.icon
    frame.AchievementName.Text = achievement.name
    frame.Description.Text = achievement.description
    
    -- Slide in animation
    local slideIn = TweenService:Create(
        frame,
        TweenInfo.new(0.5, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
        {Position = UDim2.new(1, -360, 0, 20)}
    )
    slideIn:Play()
    
    -- Wait and slide out
    wait(3)
    local slideOut = TweenService:Create(
        frame,
        TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
        {Position = UDim2.new(1, 370, 0, 20)}
    )
    slideOut:Play()
    
    slideOut.Completed:Connect(function()
        -- Process next notification
        spawn(function()
            wait(0.5)
            self:ProcessNotificationQueue()
        end)
    end)
end

function AchievementController:ShowDailyBonusPopup(bonusData)
    if not dailyBonusGui.Overlay then return end
    
    -- Play sound
    if dailyBonusSound then
        dailyBonusSound:Play()
    end
    
    -- Update popup content
    local popup = dailyBonusGui.PopupFrame
    popup.DayLabel.Text = "Day " .. bonusData.day
    popup.RewardLabel.Text = "💰 " .. bonusData.coins .. " Coins"
    if bonusData.xp and bonusData.xp > 0 then
        popup.RewardLabel.Text = popup.RewardLabel.Text .. "\n⭐ " .. bonusData.xp .. " XP"
    end
    popup.MessageLabel.Text = bonusData.message
    
    -- Show popup
    dailyBonusGui.Overlay.Visible = true
    
    -- Scale in animation
    popup.Size = UDim2.new(0, 0, 0, 0)
    local scaleIn = TweenService:Create(
        popup,
        TweenInfo.new(0.5, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
        {Size = UDim2.new(0, 400, 0, 300)}
    )
    scaleIn:Play()
end

function AchievementController:HideDailyBonusPopup()
    if not dailyBonusGui.Overlay then return end
    
    -- Play claim sound
    if claimSound then
        claimSound:Play()
    end
    
    local popup = dailyBonusGui.PopupFrame
    local scaleOut = TweenService:Create(
        popup,
        TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
        {Size = UDim2.new(0, 0, 0, 0)}
    )
    scaleOut:Play()
    
    scaleOut.Completed:Connect(function()
        dailyBonusGui.Overlay.Visible = false
    end)
end

function AchievementController:ClaimAchievement(achievementId)
    if RemoteEvents.ClaimAchievementReward then
        RemoteEvents.ClaimAchievementReward:FireServer(achievementId)
    end
    
    -- Play claim sound
    if claimSound then
        claimSound:Play()
    end
end

function AchievementController:HandleClaimResult(result)
    if result.success then
        -- Refresh display to show claimed status
        self:RefreshAchievementDisplay()
        
        -- Show brief success message
        print("✅ Claimed reward for achievement: " .. result.achievementId)
    else
        warn("❌ Failed to claim achievement reward")
    end
end

function AchievementController:OpenAchievementMenu()
    if not achievementGui.MainFrame then return end
    
    isAchievementMenuOpen = true
    achievementGui.MainFrame.Visible = true
    
    -- Request fresh data
    if RemoteEvents.RequestAchievementData then
        RemoteEvents.RequestAchievementData:FireServer()
    end
    
    -- Scale in animation
    achievementGui.MainFrame.Size = UDim2.new(0, 0, 0, 0)
    local scaleIn = TweenService:Create(
        achievementGui.MainFrame,
        TweenInfo.new(0.4, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
        {Size = UDim2.new(0.8, 0, 0.8, 0)}
    )
    scaleIn:Play()
end

function AchievementController:CloseAchievementMenu()
    if not achievementGui.MainFrame then return end
    
    isAchievementMenuOpen = false
    
    local scaleOut = TweenService:Create(
        achievementGui.MainFrame,
        TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
        {Size = UDim2.new(0, 0, 0, 0)}
    )
    scaleOut:Play()
    
    scaleOut.Completed:Connect(function()
        achievementGui.MainFrame.Visible = false
    end)
end

-- Initialize the controller
AchievementController:Init()

return AchievementController
