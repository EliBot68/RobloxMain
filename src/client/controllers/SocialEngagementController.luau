-- SocialEngagementController.luau
-- Comprehensive social engagement system coordinating all social features

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local SoundService = game:GetService("SoundService")
local RunService = game:GetService("RunService")

local RemoteEvents = require(ReplicatedStorage.Shared.modules.RemoteEvents)
local GameConstants = require(ReplicatedStorage.Shared.constants.GameConstants)

local SocialEngagementController = {}
local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- Controllers
local SocialController = nil
local LeaderboardController = nil
local PartyController = nil
local AchievementController = nil

-- UI Variables
local socialHubUI = nil
local quickAccessFrame = nil
local socialNotifications = {}

-- State
local isInitialized = false
local socialMetrics = {
    friendsCount = 0,
    partyMembers = 0,
    socialScore = 0,
    recentInteractions = {}
}

-- Colors and styling
local COLORS = {
    Primary = Color3.new(0.2, 0.6, 1),
    Secondary = Color3.new(0.8, 0.4, 1),
    Success = Color3.new(0.2, 0.8, 0.2),
    Warning = Color3.new(1, 0.8, 0.2),
    Error = Color3.new(1, 0.3, 0.3),
    Background = Color3.new(0.05, 0.05, 0.1),
    Surface = Color3.new(0.1, 0.1, 0.15),
    Text = Color3.new(1, 1, 1)
}

function SocialEngagementController:Initialize()
    print("🌟 Initializing SocialEngagementController...")
    
    -- Wait for and get other controllers
    self:WaitForControllers()
    
    -- Initialize social features
    self:CreateSocialHub()
    self:CreateQuickAccess()
    self:SetupEventConnections()
    self:SetupKeybinds()
    
    isInitialized = true
    print("✅ SocialEngagementController initialized!")
end

function SocialEngagementController:WaitForControllers()
    -- Get controllers from global registry or create them if needed
    spawn(function()
        wait(2) -- Allow time for other controllers to initialize
        
        -- Try to get controllers from global registry first
        if _G.Controllers then
            SocialController = _G.Controllers.SocialController
            LeaderboardController = _G.Controllers.LeaderboardController
            PartyController = _G.Controllers.PartyController
            AchievementController = _G.Controllers.AchievementController
        end
        
        -- Initialize missing controllers
        if not SocialController then
            local SocialControllerModule = require(script.Parent.SocialController)
            SocialController = SocialControllerModule
            if SocialController.Initialize then
                SocialController:Initialize()
            end
        end
        
        if not LeaderboardController then
            local LeaderboardControllerModule = require(script.Parent.LeaderboardController)
            LeaderboardController = LeaderboardControllerModule
            if LeaderboardController.Initialize then
                LeaderboardController:Initialize()
            end
        end
        
        if not PartyController then
            local PartyControllerModule = require(script.Parent.PartyController)
            PartyController = PartyControllerModule
            if PartyController.Initialize then
                PartyController:Initialize()
            end
        end
        
        print("🔗 Social controllers linked successfully!")
    end)
end

function SocialEngagementController:CreateSocialHub()
    if socialHubUI then socialHubUI:Destroy() end
    
    -- Main social hub UI
    socialHubUI = Instance.new("ScreenGui")
    socialHubUI.Name = "SocialHubUI"
    socialHubUI.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    socialHubUI.Parent = playerGui
    
    -- Create main hub frame (hidden by default)
    local hubFrame = Instance.new("Frame")
    hubFrame.Name = "HubFrame"
    hubFrame.Size = UDim2.new(0, 800, 0, 600)
    hubFrame.Position = UDim2.new(0.5, -400, 0.5, -300)
    hubFrame.BackgroundColor3 = COLORS.Background
    hubFrame.BackgroundTransparency = 0.05
    hubFrame.BorderSizePixel = 0
    hubFrame.Visible = false
    hubFrame.Parent = socialHubUI
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 20)
    corner.Parent = hubFrame
    
    local stroke = Instance.new("UIStroke")
    stroke.Color = COLORS.Primary
    stroke.Thickness = 3
    stroke.Transparency = 0.2
    stroke.Parent = hubFrame
    
    -- Header with navigation
    local headerFrame = Instance.new("Frame")
    headerFrame.Size = UDim2.new(1, 0, 0, 80)
    headerFrame.BackgroundColor3 = COLORS.Surface
    headerFrame.BackgroundTransparency = 0.2
    headerFrame.BorderSizePixel = 0
    headerFrame.Parent = hubFrame
    
    local headerCorner = Instance.new("UICorner")
    headerCorner.CornerRadius = UDim.new(0, 20)
    headerCorner.Parent = headerFrame
    
    -- Title
    local titleLabel = Instance.new("TextLabel")
    titleLabel.Size = UDim2.new(0.6, 0, 1, 0)
    titleLabel.Position = UDim2.new(0, 20, 0, 0)
    titleLabel.BackgroundTransparency = 1
    titleLabel.Text = "🌟 SOCIAL HUB"
    titleLabel.TextColor3 = COLORS.Text
    titleLabel.TextScaled = true
    titleLabel.Font = Enum.Font.SourceSansBold
    titleLabel.TextStrokeTransparency = 0
    titleLabel.TextStrokeColor3 = COLORS.Primary
    titleLabel.Parent = headerFrame
    
    -- Navigation buttons
    local navFrame = Instance.new("Frame")
    navFrame.Size = UDim2.new(0.4, -40, 0, 60)
    navFrame.Position = UDim2.new(0.6, 0, 0, 10)
    navFrame.BackgroundTransparency = 1
    navFrame.Parent = headerFrame
    
    local navLayout = Instance.new("UIListLayout")
    navLayout.FillDirection = Enum.FillDirection.Horizontal
    navLayout.SortOrder = Enum.SortOrder.LayoutOrder
    navLayout.Padding = UDim.new(0, 5)
    navLayout.Parent = navFrame
    
    -- Navigation buttons
    self:CreateNavButton("👥 Friends", COLORS.Success, 1, function()
        if SocialController then SocialController:ShowSocialUI() end
        self:HideSocialHub()
    end, navFrame)
    
    self:CreateNavButton("🏆 Boards", COLORS.Warning, 2, function()
        if LeaderboardController then LeaderboardController:ShowLeaderboard() end
        self:HideSocialHub()
    end, navFrame)
    
    self:CreateNavButton("🎉 Party", COLORS.Secondary, 3, function()
        if PartyController then PartyController:ShowPartyUI() end
        self:HideSocialHub()
    end, navFrame)
    
    -- Close button
    local closeButton = self:CreateStyledButton("✕", COLORS.Error, UDim2.new(0, 40, 0, 40))
    closeButton.Position = UDim2.new(1, -50, 0, 20)
    closeButton.Parent = headerFrame
    closeButton.MouseButton1Click:Connect(function()
        self:HideSocialHub()
    end)
    
    -- Content area with social overview
    self:CreateSocialOverview(hubFrame)
    
    print("🎨 Social Hub UI created!")
end

function SocialEngagementController:CreateNavButton(text, color, order, callback, parent)
    local button = Instance.new("TextButton")
    button.Size = UDim2.new(0, 80, 1, 0)
    button.BackgroundColor3 = color
    button.BackgroundTransparency = 0.2
    button.BorderSizePixel = 0
    button.Text = text
    button.TextColor3 = COLORS.Text
    button.TextScaled = true
    button.Font = Enum.Font.SourceSansBold
    button.LayoutOrder = order
    button.Parent = parent
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 8)
    corner.Parent = button
    
    button.MouseButton1Click:Connect(callback)
    
    -- Hover effects
    button.MouseEnter:Connect(function()
        local tween = TweenService:Create(button, TweenInfo.new(0.2), {BackgroundTransparency = 0.1})
        tween:Play()
    end)
    
    button.MouseLeave:Connect(function()
        local tween = TweenService:Create(button, TweenInfo.new(0.2), {BackgroundTransparency = 0.2})
        tween:Play()
    end)
    
    return button
end

function SocialEngagementController:CreateSocialOverview(parent)
    local contentFrame = Instance.new("Frame")
    contentFrame.Size = UDim2.new(1, -40, 1, -100)
    contentFrame.Position = UDim2.new(0, 20, 0, 90)
    contentFrame.BackgroundTransparency = 1
    contentFrame.Parent = parent
    
    -- Social metrics display
    local metricsFrame = Instance.new("Frame")
    metricsFrame.Size = UDim2.new(1, 0, 0, 120)
    metricsFrame.BackgroundColor3 = COLORS.Surface
    metricsFrame.BackgroundTransparency = 0.3
    metricsFrame.BorderSizePixel = 0
    metricsFrame.Parent = contentFrame
    
    local metricsCorner = Instance.new("UICorner")
    metricsCorner.CornerRadius = UDim.new(0, 15)
    metricsCorner.Parent = metricsFrame
    
    local metricsLayout = Instance.new("UIGridLayout")
    metricsLayout.CellSize = UDim2.new(0, 180, 0, 80)
    metricsLayout.CellPadding = UDim2.new(0, 10, 0, 10)
    metricsLayout.Parent = metricsFrame
    
    -- Create metric cards
    self:CreateMetricCard("👥 Friends", "0", "Active connections", COLORS.Success, metricsFrame)
    self:CreateMetricCard("🎉 Party", "0/6", "Current party size", COLORS.Secondary, metricsFrame)
    self:CreateMetricCard("🏆 Rank", "#--", "Global position", COLORS.Warning, metricsFrame)
    self:CreateMetricCard("⭐ Score", "0", "Social engagement", COLORS.Primary, metricsFrame)
    
    -- Quick actions
    local actionsFrame = Instance.new("Frame")
    actionsFrame.Size = UDim2.new(1, 0, 1, -140)
    actionsFrame.Position = UDim2.new(0, 0, 0, 130)
    actionsFrame.BackgroundTransparency = 1
    actionsFrame.Parent = contentFrame
    
    local actionsScrollFrame = Instance.new("ScrollingFrame")
    actionsScrollFrame.Size = UDim2.new(1, 0, 1, 0)
    actionsScrollFrame.BackgroundTransparency = 1
    actionsScrollFrame.BorderSizePixel = 0
    actionsScrollFrame.ScrollBarThickness = 8
    actionsScrollFrame.ScrollBarImageColor3 = COLORS.Primary
    actionsScrollFrame.Parent = actionsFrame
    
    local actionsLayout = Instance.new("UIListLayout")
    actionsLayout.SortOrder = Enum.SortOrder.LayoutOrder
    actionsLayout.Padding = UDim.new(0, 10)
    actionsLayout.Parent = actionsScrollFrame
    
    -- Action buttons
    self:CreateActionButton("🤝 Find & Add Friends", "Discover new players to connect with", 1, function()
        if SocialController then 
            SocialController:ShowSocialUI()
            self:HideSocialHub()
        end
    end, actionsScrollFrame)
    
    self:CreateActionButton("🏆 View Leaderboards", "Check rankings and compete with friends", 2, function()
        if LeaderboardController then 
            LeaderboardController:ShowLeaderboard()
            self:HideSocialHub()
        end
    end, actionsScrollFrame)
    
    self:CreateActionButton("🎉 Create Party", "Start a party and invite friends", 3, function()
        if PartyController then 
            PartyController:ShowPartyUI()
            self:HideSocialHub()
        end
    end, actionsScrollFrame)
    
    self:CreateActionButton("📊 View Achievements", "Track your progress and share successes", 4, function()
        if AchievementController and AchievementController.ShowAchievementMenu then
            AchievementController:ShowAchievementMenu()
            self:HideSocialHub()
        end
    end, actionsScrollFrame)
    
    actionsScrollFrame:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        actionsScrollFrame.CanvasSize = UDim2.new(0, 0, 0, actionsLayout.AbsoluteContentSize.Y + 20)
    end)
end

function SocialEngagementController:CreateMetricCard(title, value, description, color, parent)
    local card = Instance.new("Frame")
    card.BackgroundColor3 = color
    card.BackgroundTransparency = 0.7
    card.BorderSizePixel = 0
    card.Parent = parent
    
    local cardCorner = Instance.new("UICorner")
    cardCorner.CornerRadius = UDim.new(0, 10)
    cardCorner.Parent = card
    
    local titleLabel = Instance.new("TextLabel")
    titleLabel.Size = UDim2.new(1, -10, 0, 25)
    titleLabel.Position = UDim2.new(0, 5, 0, 5)
    titleLabel.BackgroundTransparency = 1
    titleLabel.Text = title
    titleLabel.TextColor3 = COLORS.Text
    titleLabel.TextScaled = true
    titleLabel.Font = Enum.Font.SourceSansBold
    titleLabel.Parent = card
    
    local valueLabel = Instance.new("TextLabel")
    valueLabel.Size = UDim2.new(1, -10, 0, 30)
    valueLabel.Position = UDim2.new(0, 5, 0, 25)
    valueLabel.BackgroundTransparency = 1
    valueLabel.Text = value
    valueLabel.TextColor3 = COLORS.Text
    valueLabel.TextScaled = true
    valueLabel.Font = Enum.Font.SourceSansBold
    valueLabel.Parent = card
    
    local descLabel = Instance.new("TextLabel")
    descLabel.Size = UDim2.new(1, -10, 0, 20)
    descLabel.Position = UDim2.new(0, 5, 0, 55)
    descLabel.BackgroundTransparency = 1
    descLabel.Text = description
    descLabel.TextColor3 = Color3.new(0.8, 0.8, 0.8)
    descLabel.TextScaled = true
    descLabel.Font = Enum.Font.SourceSans
    descLabel.Parent = card
    
    return card
end

function SocialEngagementController:CreateActionButton(title, description, order, callback, parent)
    local button = Instance.new("TextButton")
    button.Size = UDim2.new(1, -10, 0, 60)
    button.BackgroundColor3 = COLORS.Surface
    button.BackgroundTransparency = 0.3
    button.BorderSizePixel = 0
    button.Text = ""
    button.LayoutOrder = order
    button.Parent = parent
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 10)
    corner.Parent = button
    
    local titleLabel = Instance.new("TextLabel")
    titleLabel.Size = UDim2.new(1, -20, 0, 30)
    titleLabel.Position = UDim2.new(0, 10, 0, 5)
    titleLabel.BackgroundTransparency = 1
    titleLabel.Text = title
    titleLabel.TextColor3 = COLORS.Text
    titleLabel.TextScaled = true
    titleLabel.Font = Enum.Font.SourceSansBold
    titleLabel.TextXAlignment = Enum.TextXAlignment.Left
    titleLabel.Parent = button
    
    local descLabel = Instance.new("TextLabel")
    descLabel.Size = UDim2.new(1, -20, 0, 25)
    descLabel.Position = UDim2.new(0, 10, 0, 30)
    descLabel.BackgroundTransparency = 1
    descLabel.Text = description
    descLabel.TextColor3 = Color3.new(0.8, 0.8, 0.8)
    descLabel.TextScaled = true
    descLabel.Font = Enum.Font.SourceSans
    descLabel.TextXAlignment = Enum.TextXAlignment.Left
    descLabel.Parent = button
    
    button.MouseButton1Click:Connect(callback)
    
    -- Hover effects
    button.MouseEnter:Connect(function()
        local tween = TweenService:Create(button, TweenInfo.new(0.2), {BackgroundTransparency = 0.1})
        tween:Play()
    end)
    
    button.MouseLeave:Connect(function()
        local tween = TweenService:Create(button, TweenInfo.new(0.2), {BackgroundTransparency = 0.3})
        tween:Play()
    end)
    
    return button
end

function SocialEngagementController:CreateQuickAccess()
    -- Quick access toolbar
    quickAccessFrame = Instance.new("Frame")
    quickAccessFrame.Name = "QuickAccessFrame"
    quickAccessFrame.Size = UDim2.new(0, 300, 0, 50)
    quickAccessFrame.Position = UDim2.new(1, -320, 0, 100)
    quickAccessFrame.BackgroundColor3 = COLORS.Background
    quickAccessFrame.BackgroundTransparency = 0.2
    quickAccessFrame.BorderSizePixel = 0
    quickAccessFrame.Parent = socialHubUI
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 25)
    corner.Parent = quickAccessFrame
    
    local stroke = Instance.new("UIStroke")
    stroke.Color = COLORS.Primary
    stroke.Thickness = 2
    stroke.Transparency = 0.5
    stroke.Parent = quickAccessFrame
    
    local layout = Instance.new("UIListLayout")
    layout.FillDirection = Enum.FillDirection.Horizontal
    layout.SortOrder = Enum.SortOrder.LayoutOrder
    layout.Padding = UDim.new(0, 5)
    layout.Parent = quickAccessFrame
    
    -- Quick access buttons
    self:CreateQuickButton("🌟", "Social Hub", 1, function()
        self:ShowSocialHub()
    end)
    
    self:CreateQuickButton("👥", "Friends", 2, function()
        if SocialController then SocialController:ToggleSocialUI() end
    end)
    
    self:CreateQuickButton("🏆", "Leaderboard", 3, function()
        if LeaderboardController then LeaderboardController:ToggleLeaderboard() end
    end)
    
    self:CreateQuickButton("🎉", "Party", 4, function()
        if PartyController then PartyController:TogglePartyUI() end
    end)
    
    -- Entrance animation
    quickAccessFrame.Position = UDim2.new(1, 0, 0, 100)
    local tween = TweenService:Create(
        quickAccessFrame,
        TweenInfo.new(0.5, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
        {Position = UDim2.new(1, -320, 0, 100)}
    )
    tween:Play()
    
    print("🚀 Quick access toolbar created!")
end

function SocialEngagementController:CreateQuickButton(icon, tooltip, order, callback)
    local button = Instance.new("TextButton")
    button.Size = UDim2.new(0, 40, 0, 40)
    button.BackgroundColor3 = COLORS.Primary
    button.BackgroundTransparency = 0.2
    button.BorderSizePixel = 0
    button.Text = icon
    button.TextColor3 = COLORS.Text
    button.TextScaled = true
    button.Font = Enum.Font.SourceSansBold
    button.LayoutOrder = order
    button.Parent = quickAccessFrame
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0.5, 0)
    corner.Parent = button
    
    button.MouseButton1Click:Connect(callback)
    
    -- Hover effects
    button.MouseEnter:Connect(function()
        local tween = TweenService:Create(button, TweenInfo.new(0.2), {
            BackgroundTransparency = 0.1,
            Size = UDim2.new(0, 45, 0, 45)
        })
        tween:Play()
    end)
    
    button.MouseLeave:Connect(function()
        local tween = TweenService:Create(button, TweenInfo.new(0.2), {
            BackgroundTransparency = 0.2,
            Size = UDim2.new(0, 40, 0, 40)
        })
        tween:Play()
    end)
    
    return button
end

function SocialEngagementController:CreateStyledButton(text, color, size)
    local button = Instance.new("TextButton")
    button.Size = size or UDim2.new(0, 100, 0, 35)
    button.BackgroundColor3 = color
    button.BackgroundTransparency = 0.2
    button.BorderSizePixel = 0
    button.Text = text
    button.TextColor3 = COLORS.Text
    button.TextScaled = true
    button.Font = Enum.Font.SourceSansBold
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 8)
    corner.Parent = button
    
    -- Hover effects
    button.MouseEnter:Connect(function()
        local tween = TweenService:Create(button, TweenInfo.new(0.2), {BackgroundTransparency = 0.1})
        tween:Play()
    end)
    
    button.MouseLeave:Connect(function()
        local tween = TweenService:Create(button, TweenInfo.new(0.2), {BackgroundTransparency = 0.2})
        tween:Play()
    end)
    
    return button
end

function SocialEngagementController:SetupEventConnections()
    -- Social engagement tracking
    RemoteEvents.FriendAdded.OnClientEvent:Connect(function(friendId, friendName)
        socialMetrics.friendsCount = socialMetrics.friendsCount + 1
        self:UpdateSocialMetrics()
        self:ShowEngagementNotification("🤝 New Friend", "Connected with " .. friendName, COLORS.Success)
    end)
    
    RemoteEvents.FriendRemoved.OnClientEvent:Connect(function()
        socialMetrics.friendsCount = math.max(0, socialMetrics.friendsCount - 1)
        self:UpdateSocialMetrics()
    end)
    
    RemoteEvents.PartyMemberJoined.OnClientEvent:Connect(function()
        socialMetrics.partyMembers = socialMetrics.partyMembers + 1
        self:UpdateSocialMetrics()
    end)
    
    RemoteEvents.PartyMemberLeft.OnClientEvent:Connect(function()
        socialMetrics.partyMembers = math.max(0, socialMetrics.partyMembers - 1)
        self:UpdateSocialMetrics()
    end)
    
    -- Achievement sharing
    RemoteEvents.AchievementShared.OnClientEvent:Connect(function(sharerId, sharerName, achievementId)
        self:ShowEngagementNotification("🏆 Achievement Shared", sharerName .. " unlocked: " .. achievementId, COLORS.Warning)
    end)
    
    -- Challenge notifications
    RemoteEvents.ChallengeReceived.OnClientEvent:Connect(function(challenge)
        self:ShowEngagementNotification("⚔️ Challenge!", challenge.challengerName .. " challenged you!", COLORS.Secondary)
    end)
end

function SocialEngagementController:UpdateSocialMetrics()
    -- Update metric displays if social hub is open
    local hubFrame = socialHubUI and socialHubUI:FindFirstChild("HubFrame")
    if not hubFrame or not hubFrame.Visible then return end
    
    -- This would update the metric cards with current values
    -- Implementation would depend on how the metric cards are structured
end

function SocialEngagementController:ShowEngagementNotification(title, message, color)
    local notification = Instance.new("Frame")
    notification.Size = UDim2.new(0, 300, 0, 70)
    notification.Position = UDim2.new(1, -320, 0, 20 + (#socialNotifications * 80))
    notification.BackgroundColor3 = color
    notification.BackgroundTransparency = 0.1
    notification.BorderSizePixel = 0
    notification.Parent = socialHubUI
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 10)
    corner.Parent = notification
    
    local titleLabel = Instance.new("TextLabel")
    titleLabel.Size = UDim2.new(1, -10, 0, 25)
    titleLabel.Position = UDim2.new(0, 5, 0, 5)
    titleLabel.BackgroundTransparency = 1
    titleLabel.Text = title
    titleLabel.TextColor3 = COLORS.Text
    titleLabel.TextScaled = true
    titleLabel.Font = Enum.Font.SourceSansBold
    titleLabel.Parent = notification
    
    local messageLabel = Instance.new("TextLabel")
    messageLabel.Size = UDim2.new(1, -10, 0, 35)
    messageLabel.Position = UDim2.new(0, 5, 0, 30)
    messageLabel.BackgroundTransparency = 1
    messageLabel.Text = message
    messageLabel.TextColor3 = COLORS.Text
    messageLabel.TextScaled = true
    messageLabel.Font = Enum.Font.SourceSans
    messageLabel.TextWrapped = true
    messageLabel.Parent = notification
    
    table.insert(socialNotifications, notification)
    
    -- Entrance animation
    notification.Position = UDim2.new(1, 0, 0, 20 + ((#socialNotifications - 1) * 80))
    local entranceTween = TweenService:Create(
        notification,
        TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
        {Position = UDim2.new(1, -320, 0, 20 + ((#socialNotifications - 1) * 80))}
    )
    entranceTween:Play()
    
    -- Auto-dismiss after 5 seconds
    spawn(function()
        wait(5)
        self:DismissNotification(notification)
    end)
end

function SocialEngagementController:DismissNotification(notification)
    local index = nil
    for i, notif in ipairs(socialNotifications) do
        if notif == notification then
            index = i
            break
        end
    end
    
    if index then
        table.remove(socialNotifications, index)
        
        local exitTween = TweenService:Create(
            notification,
            TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
            {Position = UDim2.new(1, 0, 0, notification.Position.Y.Offset), BackgroundTransparency = 1}
        )
        exitTween:Play()
        exitTween.Completed:Connect(function()
            notification:Destroy()
        end)
        
        -- Reposition remaining notifications
        for i, notif in ipairs(socialNotifications) do
            local newPosition = UDim2.new(1, -320, 0, 20 + ((i - 1) * 80))
            local repositionTween = TweenService:Create(
                notif,
                TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
                {Position = newPosition}
            )
            repositionTween:Play()
        end
    end
end

function SocialEngagementController:SetupKeybinds()
    UserInputService.InputBegan:Connect(function(input, gameProcessed)
        if gameProcessed then return end
        
        if input.KeyCode == Enum.KeyCode.Tab then -- Tab for Social Hub
            self:ToggleSocialHub()
        end
    end)
end

function SocialEngagementController:ShowSocialHub()
    local hubFrame = socialHubUI and socialHubUI:FindFirstChild("HubFrame")
    if not hubFrame then return end
    
    hubFrame.Visible = true
    
    -- Entrance animation
    hubFrame.Size = UDim2.new(0, 0, 0, 0)
    hubFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
    
    local tween = TweenService:Create(
        hubFrame,
        TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
        {
            Size = UDim2.new(0, 800, 0, 600),
            Position = UDim2.new(0.5, -400, 0.5, -300)
        }
    )
    tween:Play()
end

function SocialEngagementController:HideSocialHub()
    local hubFrame = socialHubUI and socialHubUI:FindFirstChild("HubFrame")
    if not hubFrame then return end
    
    local tween = TweenService:Create(
        hubFrame,
        TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
        {
            Size = UDim2.new(0, 0, 0, 0),
            Position = UDim2.new(0.5, 0, 0.5, 0)
        }
    )
    tween:Play()
    
    tween.Completed:Connect(function()
        hubFrame.Visible = false
    end)
end

function SocialEngagementController:ToggleSocialHub()
    local hubFrame = socialHubUI and socialHubUI:FindFirstChild("HubFrame")
    if not hubFrame then return end
    
    if hubFrame.Visible then
        self:HideSocialHub()
    else
        self:ShowSocialHub()
    end
end

-- Public interface
function SocialEngagementController:GetSocialMetrics()
    return socialMetrics
end

function SocialEngagementController:IsInitialized()
    return isInitialized
end

return SocialEngagementController
