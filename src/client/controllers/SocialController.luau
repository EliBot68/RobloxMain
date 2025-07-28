-- SocialController.luau
-- Comprehensive client-side social features including friends, leaderboards, and engagement

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local TextService = game:GetService("TextService")
local SoundService = game:GetService("SoundService")

local RemoteEvents = require(ReplicatedStorage.Shared.modules.RemoteEvents)
local GameConstants = require(ReplicatedStorage.Shared.constants.GameConstants)

local SocialController = {}
local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- UI Variables
local socialUI = nil
local mainFrame = nil
local tabsFrame = nil
local contentFrame = nil

-- Tabs
local friendsTab = nil
local leaderboardTab = nil
local requestsTab = nil
local socialTab = nil

-- Content frames
local friendsContent = nil
local leaderboardContent = nil
local requestsContent = nil
local socialContent = nil

-- Data
local friendsList = {}
local friendRequests = {}
local leaderboardData = {}
local currentTab = "friends"

-- Colors
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

function SocialController:Initialize()
    print("🤝 Initializing SocialController...")
    
    self:CreateSocialUI()
    self:SetupEventConnections()
    self:SetupKeybinds()
    
    -- Request initial data
    RemoteEvents.GetFriendsList:FireServer()
    RemoteEvents.GetFriendRequests:FireServer()
    RemoteEvents.RequestSocialLeaderboard:FireServer("friends")
    
    print("✅ SocialController initialized!")
end

function SocialController:CreateSocialUI()
    if socialUI then socialUI:Destroy() end
    
    -- Main UI
    socialUI = Instance.new("ScreenGui")
    socialUI.Name = "SocialUI"
    socialUI.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    socialUI.Parent = playerGui
    
    -- Modern main frame with glass morphism
    mainFrame = Instance.new("Frame")
    mainFrame.Name = "MainFrame"
    mainFrame.Size = UDim2.new(0, 600, 0, 500)
    mainFrame.Position = UDim2.new(0.5, -300, 0.5, -250)
    mainFrame.BackgroundColor3 = COLORS.Background
    mainFrame.BackgroundTransparency = 0.05
    mainFrame.BorderSizePixel = 0
    mainFrame.Visible = false
    mainFrame.Parent = socialUI
    
    -- Rounded corners
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 20)
    corner.Parent = mainFrame
    
    -- Glowing border
    local stroke = Instance.new("UIStroke")
    stroke.Color = COLORS.Primary
    stroke.Thickness = 2
    stroke.Transparency = 0.3
    stroke.Parent = mainFrame
    
    -- Backdrop blur effect
    local blur = Instance.new("ImageLabel")
    blur.Size = UDim2.new(1, 0, 1, 0)
    blur.BackgroundTransparency = 1
    blur.Image = "rbxasset://textures/ui/GuiImagePlaceholder.png"
    blur.ImageColor3 = Color3.new(1, 1, 1)
    blur.ImageTransparency = 0.9
    blur.Parent = mainFrame
    
    -- Header
    local header = Instance.new("Frame")
    header.Name = "Header"
    header.Size = UDim2.new(1, 0, 0, 60)
    header.BackgroundColor3 = COLORS.Surface
    header.BackgroundTransparency = 0.2
    header.BorderSizePixel = 0
    header.Parent = mainFrame
    
    local headerCorner = Instance.new("UICorner")
    headerCorner.CornerRadius = UDim.new(0, 20)
    headerCorner.Parent = header
    
    -- Title
    local titleLabel = Instance.new("TextLabel")
    titleLabel.Name = "TitleLabel"
    titleLabel.Size = UDim2.new(1, -120, 1, 0)
    titleLabel.Position = UDim2.new(0, 20, 0, 0)
    titleLabel.BackgroundTransparency = 1
    titleLabel.Text = "🌟 SOCIAL HUB"
    titleLabel.TextColor3 = COLORS.Text
    titleLabel.TextScaled = true
    titleLabel.Font = Enum.Font.SourceSansBold
    titleLabel.TextStrokeTransparency = 0
    titleLabel.TextStrokeColor3 = COLORS.Primary
    titleLabel.Parent = header
    
    -- Close button
    local closeButton = self:CreateStyledButton("✕", COLORS.Error, UDim2.new(0, 40, 0, 40))
    closeButton.Position = UDim2.new(1, -50, 0.5, -20)
    closeButton.Parent = header
    closeButton.MouseButton1Click:Connect(function()
        self:HideSocialUI()
    end)
    
    self:CreateTabSystem()
    self:CreateContentFrames()
    
    print("🎨 Social UI created with modern design!")
end

function SocialController:CreateTabSystem()
    -- Tabs container
    tabsFrame = Instance.new("Frame")
    tabsFrame.Name = "TabsFrame"
    tabsFrame.Size = UDim2.new(1, -40, 0, 50)
    tabsFrame.Position = UDim2.new(0, 20, 0, 70)
    tabsFrame.BackgroundTransparency = 1
    tabsFrame.Parent = mainFrame
    
    local tabLayout = Instance.new("UIListLayout")
    tabLayout.FillDirection = Enum.FillDirection.Horizontal
    tabLayout.SortOrder = Enum.SortOrder.LayoutOrder
    tabLayout.Padding = UDim.new(0, 10)
    tabLayout.Parent = tabsFrame
    
    -- Friends tab
    friendsTab = self:CreateTab("👥 Friends", 1, function()
        self:ShowTab("friends")
    end)
    
    -- Leaderboards tab
    leaderboardTab = self:CreateTab("🏆 Leaderboards", 2, function()
        self:ShowTab("leaderboard")
    end)
    
    -- Requests tab
    requestsTab = self:CreateTab("📨 Requests", 3, function()
        self:ShowTab("requests")
    end)
    
    -- Social tab
    socialTab = self:CreateTab("⭐ Social", 4, function()
        self:ShowTab("social")
    end)
    
    -- Content area
    contentFrame = Instance.new("Frame")
    contentFrame.Name = "ContentFrame"
    contentFrame.Size = UDim2.new(1, -40, 1, -140)
    contentFrame.Position = UDim2.new(0, 20, 0, 130)
    contentFrame.BackgroundColor3 = COLORS.Surface
    contentFrame.BackgroundTransparency = 0.3
    contentFrame.BorderSizePixel = 0
    contentFrame.Parent = mainFrame
    
    local contentCorner = Instance.new("UICorner")
    contentCorner.CornerRadius = UDim.new(0, 15)
    contentCorner.Parent = contentFrame
end

function SocialController:CreateTab(text, order, callback)
    local tab = Instance.new("TextButton")
    tab.Size = UDim2.new(0, 120, 1, 0)
    tab.BackgroundColor3 = COLORS.Surface
    tab.BackgroundTransparency = 0.5
    tab.BorderSizePixel = 0
    tab.Text = text
    tab.TextColor3 = COLORS.Text
    tab.TextScaled = true
    tab.Font = Enum.Font.SourceSansBold
    tab.LayoutOrder = order
    tab.Parent = tabsFrame
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 10)
    corner.Parent = tab
    
    local stroke = Instance.new("UIStroke")
    stroke.Color = COLORS.Primary
    stroke.Thickness = 1
    stroke.Transparency = 0.5
    stroke.Parent = tab
    
    tab.MouseButton1Click:Connect(callback)
    
    return tab
end

function SocialController:CreateContentFrames()
    -- Friends content
    friendsContent = self:CreateContentFrame("Friends")
    self:CreateFriendsInterface(friendsContent)
    
    -- Leaderboard content
    leaderboardContent = self:CreateContentFrame("Leaderboard")
    self:CreateLeaderboardInterface(leaderboardContent)
    
    -- Requests content
    requestsContent = self:CreateContentFrame("Requests")
    self:CreateRequestsInterface(requestsContent)
    
    -- Social content
    socialContent = self:CreateContentFrame("Social")
    self:CreateSocialInterface(socialContent)
    
    -- Show friends tab by default
    self:ShowTab("friends")
end

function SocialController:CreateContentFrame(name)
    local frame = Instance.new("Frame")
    frame.Name = name .. "Content"
    frame.Size = UDim2.new(1, 0, 1, 0)
    frame.BackgroundTransparency = 1
    frame.Visible = false
    frame.Parent = contentFrame
    
    return frame
end

function SocialController:CreateFriendsInterface(parent)
    -- Header with search
    local headerFrame = Instance.new("Frame")
    headerFrame.Size = UDim2.new(1, -20, 0, 50)
    headerFrame.Position = UDim2.new(0, 10, 0, 10)
    headerFrame.BackgroundTransparency = 1
    headerFrame.Parent = parent
    
    -- Add friend button
    local addFriendButton = self:CreateStyledButton("+ Add Friend", COLORS.Success, UDim2.new(0, 120, 0, 35))
    addFriendButton.Position = UDim2.new(0, 0, 0, 0)
    addFriendButton.Parent = headerFrame
    addFriendButton.MouseButton1Click:Connect(function()
        self:ShowAddFriendDialog()
    end)
    
    -- Search box
    local searchBox = Instance.new("TextBox")
    searchBox.Size = UDim2.new(1, -140, 0, 35)
    searchBox.Position = UDim2.new(0, 130, 0, 0)
    searchBox.BackgroundColor3 = COLORS.Background
    searchBox.BackgroundTransparency = 0.3
    searchBox.BorderSizePixel = 0
    searchBox.PlaceholderText = "🔍 Search friends..."
    searchBox.PlaceholderColor3 = Color3.new(0.7, 0.7, 0.7)
    searchBox.Text = ""
    searchBox.TextColor3 = COLORS.Text
    searchBox.TextScaled = true
    searchBox.Font = Enum.Font.SourceSans
    searchBox.Parent = headerFrame
    
    local searchCorner = Instance.new("UICorner")
    searchCorner.CornerRadius = UDim.new(0, 8)
    searchCorner.Parent = searchBox
    
    -- Friends list
    local friendsScrollFrame = Instance.new("ScrollingFrame")
    friendsScrollFrame.Name = "FriendsScrollFrame"
    friendsScrollFrame.Size = UDim2.new(1, -20, 1, -70)
    friendsScrollFrame.Position = UDim2.new(0, 10, 0, 60)
    friendsScrollFrame.BackgroundTransparency = 1
    friendsScrollFrame.BorderSizePixel = 0
    friendsScrollFrame.ScrollBarThickness = 8
    friendsScrollFrame.ScrollBarImageColor3 = COLORS.Primary
    friendsScrollFrame.Parent = parent
    
    local friendsLayout = Instance.new("UIListLayout")
    friendsLayout.SortOrder = Enum.SortOrder.LayoutOrder
    friendsLayout.Padding = UDim.new(0, 5)
    friendsLayout.Parent = friendsScrollFrame
    
    friendsScrollFrame:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        friendsScrollFrame.CanvasSize = UDim2.new(0, 0, 0, friendsLayout.AbsoluteContentSize.Y + 10)
    end)
end

function SocialController:CreateLeaderboardInterface(parent)
    -- Leaderboard type selector
    local selectorFrame = Instance.new("Frame")
    selectorFrame.Size = UDim2.new(1, -20, 0, 50)
    selectorFrame.Position = UDim2.new(0, 10, 0, 10)
    selectorFrame.BackgroundTransparency = 1
    selectorFrame.Parent = parent
    
    local selectorLayout = Instance.new("UIListLayout")
    selectorLayout.FillDirection = Enum.FillDirection.Horizontal
    selectorLayout.SortOrder = Enum.SortOrder.LayoutOrder
    selectorLayout.Padding = UDim.new(0, 10)
    selectorLayout.Parent = selectorFrame
    
    -- Friends leaderboard button
    local friendsLbButton = self:CreateStyledButton("👥 Friends", COLORS.Primary, UDim2.new(0, 100, 0, 35))
    friendsLbButton.LayoutOrder = 1
    friendsLbButton.Parent = selectorFrame
    friendsLbButton.MouseButton1Click:Connect(function()
        RemoteEvents.RequestSocialLeaderboard:FireServer("friends")
    end)
    
    -- Global leaderboard button
    local globalLbButton = self:CreateStyledButton("🌍 Global", COLORS.Secondary, UDim2.new(0, 100, 0, 35))
    globalLbButton.LayoutOrder = 2
    globalLbButton.Parent = selectorFrame
    globalLbButton.MouseButton1Click:Connect(function()
        RemoteEvents.RequestSocialLeaderboard:FireServer("global")
    end)
    
    -- Party leaderboard button
    local partyLbButton = self:CreateStyledButton("🎉 Party", COLORS.Warning, UDim2.new(0, 100, 0, 35))
    partyLbButton.LayoutOrder = 3
    partyLbButton.Parent = selectorFrame
    partyLbButton.MouseButton1Click:Connect(function()
        RemoteEvents.RequestSocialLeaderboard:FireServer("party")
    end)
    
    -- Leaderboard list
    local leaderboardScrollFrame = Instance.new("ScrollingFrame")
    leaderboardScrollFrame.Name = "LeaderboardScrollFrame"
    leaderboardScrollFrame.Size = UDim2.new(1, -20, 1, -70)
    leaderboardScrollFrame.Position = UDim2.new(0, 10, 0, 60)
    leaderboardScrollFrame.BackgroundTransparency = 1
    leaderboardScrollFrame.BorderSizePixel = 0
    leaderboardScrollFrame.ScrollBarThickness = 8
    leaderboardScrollFrame.ScrollBarImageColor3 = COLORS.Primary
    leaderboardScrollFrame.Parent = parent
    
    local leaderboardLayout = Instance.new("UIListLayout")
    leaderboardLayout.SortOrder = Enum.SortOrder.LayoutOrder
    leaderboardLayout.Padding = UDim.new(0, 5)
    leaderboardLayout.Parent = leaderboardScrollFrame
    
    leaderboardScrollFrame:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        leaderboardScrollFrame.CanvasSize = UDim2.new(0, 0, 0, leaderboardLayout.AbsoluteContentSize.Y + 10)
    end)
end

function SocialController:CreateRequestsInterface(parent)
    -- Header
    local headerLabel = Instance.new("TextLabel")
    headerLabel.Size = UDim2.new(1, -20, 0, 40)
    headerLabel.Position = UDim2.new(0, 10, 0, 10)
    headerLabel.BackgroundTransparency = 1
    headerLabel.Text = "📨 Friend Requests"
    headerLabel.TextColor3 = COLORS.Text
    headerLabel.TextScaled = true
    headerLabel.Font = Enum.Font.SourceSansBold
    headerLabel.Parent = parent
    
    -- Requests list
    local requestsScrollFrame = Instance.new("ScrollingFrame")
    requestsScrollFrame.Name = "RequestsScrollFrame"
    requestsScrollFrame.Size = UDim2.new(1, -20, 1, -60)
    requestsScrollFrame.Position = UDim2.new(0, 10, 0, 50)
    requestsScrollFrame.BackgroundTransparency = 1
    requestsScrollFrame.BorderSizePixel = 0
    requestsScrollFrame.ScrollBarThickness = 8
    requestsScrollFrame.ScrollBarImageColor3 = COLORS.Primary
    requestsScrollFrame.Parent = parent
    
    local requestsLayout = Instance.new("UIListLayout")
    requestsLayout.SortOrder = Enum.SortOrder.LayoutOrder
    requestsLayout.Padding = UDim.new(0, 5)
    requestsLayout.Parent = requestsScrollFrame
    
    requestsScrollFrame:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        requestsScrollFrame.CanvasSize = UDim2.new(0, 0, 0, requestsLayout.AbsoluteContentSize.Y + 10)
    end)
end

function SocialController:CreateSocialInterface(parent)
    -- Social stats display
    local statsFrame = Instance.new("Frame")
    statsFrame.Size = UDim2.new(1, -20, 0, 100)
    statsFrame.Position = UDim2.new(0, 10, 0, 10)
    statsFrame.BackgroundColor3 = COLORS.Background
    statsFrame.BackgroundTransparency = 0.3
    statsFrame.BorderSizePixel = 0
    statsFrame.Parent = parent
    
    local statsCorner = Instance.new("UICorner")
    statsCorner.CornerRadius = UDim.new(0, 10)
    statsCorner.Parent = statsFrame
    
    local statsLayout = Instance.new("UIGridLayout")
    statsLayout.CellSize = UDim2.new(0, 120, 0, 40)
    statsLayout.CellPadding = UDim2.new(0, 10, 0, 10)
    statsLayout.Parent = statsFrame
    
    -- Create stat labels
    self:CreateStatLabel("👍 Likes: 0", statsFrame)
    self:CreateStatLabel("🎯 Challenges: 0", statsFrame)
    self:CreateStatLabel("🏆 Shared: 0", statsFrame)
    self:CreateStatLabel("👑 Wins: 0", statsFrame)
    
    -- Social actions
    local actionsFrame = Instance.new("Frame")
    actionsFrame.Size = UDim2.new(1, -20, 1, -120)
    actionsFrame.Position = UDim2.new(0, 10, 0, 110)
    actionsFrame.BackgroundTransparency = 1
    actionsFrame.Parent = parent
    
    local actionsLayout = Instance.new("UIListLayout")
    actionsLayout.SortOrder = Enum.SortOrder.LayoutOrder
    actionsLayout.Padding = UDim.new(0, 10)
    actionsLayout.Parent = actionsFrame
    
    -- Quick actions
    local quickShare = self:CreateStyledButton("🏆 Share Latest Achievement", COLORS.Success, UDim2.new(1, 0, 0, 40))
    quickShare.LayoutOrder = 1
    quickShare.Parent = actionsFrame
    
    local quickChallenge = self:CreateStyledButton("⚔️ Challenge Random Friend", COLORS.Warning, UDim2.new(1, 0, 0, 40))
    quickChallenge.LayoutOrder = 2
    quickChallenge.Parent = actionsFrame
    
    local viewActivity = self:CreateStyledButton("📊 View Friend Activity", COLORS.Primary, UDim2.new(1, 0, 0, 40))
    viewActivity.LayoutOrder = 3
    viewActivity.Parent = actionsFrame
end

function SocialController:CreateStatLabel(text, parent)
    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(0, 120, 0, 40)
    label.BackgroundTransparency = 1
    label.Text = text
    label.TextColor3 = COLORS.Text
    label.TextScaled = true
    label.Font = Enum.Font.SourceSansBold
    label.Parent = parent
    
    return label
end

function SocialController:CreateStyledButton(text, color, size)
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
    
    local stroke = Instance.new("UIStroke")
    stroke.Color = color
    stroke.Thickness = 2
    stroke.Transparency = 0.3
    stroke.Parent = button
    
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

function SocialController:ShowTab(tabName)
    currentTab = tabName
    
    -- Hide all content frames
    friendsContent.Visible = false
    leaderboardContent.Visible = false
    requestsContent.Visible = false
    socialContent.Visible = false
    
    -- Reset tab colors
    friendsTab.BackgroundTransparency = 0.5
    leaderboardTab.BackgroundTransparency = 0.5
    requestsTab.BackgroundTransparency = 0.5
    socialTab.BackgroundTransparency = 0.5
    
    -- Show selected content and highlight tab
    if tabName == "friends" then
        friendsContent.Visible = true
        friendsTab.BackgroundTransparency = 0.1
        self:UpdateFriendsList()
    elseif tabName == "leaderboard" then
        leaderboardContent.Visible = true
        leaderboardTab.BackgroundTransparency = 0.1
    elseif tabName == "requests" then
        requestsContent.Visible = true
        requestsTab.BackgroundTransparency = 0.1
        self:UpdateRequestsList()
    elseif tabName == "social" then
        socialContent.Visible = true
        socialTab.BackgroundTransparency = 0.1
    end
end

function SocialController:ShowSocialUI()
    if not mainFrame then
        self:CreateSocialUI()
    end
    
    mainFrame.Visible = true
    
    -- Entrance animation
    mainFrame.Size = UDim2.new(0, 0, 0, 0)
    mainFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
    
    local tween = TweenService:Create(
        mainFrame,
        TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
        {
            Size = UDim2.new(0, 600, 0, 500),
            Position = UDim2.new(0.5, -300, 0.5, -250)
        }
    )
    tween:Play()
    
    -- Request fresh data
    RemoteEvents.GetFriendsList:FireServer()
    RemoteEvents.GetFriendRequests:FireServer()
end

function SocialController:HideSocialUI()
    if not mainFrame then return end
    
    local tween = TweenService:Create(
        mainFrame,
        TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
        {
            Size = UDim2.new(0, 0, 0, 0),
            Position = UDim2.new(0.5, 0, 0.5, 0)
        }
    )
    tween:Play()
    
    tween.Completed:Connect(function()
        mainFrame.Visible = false
    end)
end

function SocialController:ShowAddFriendDialog()
    -- Create simple input dialog
    local dialog = Instance.new("Frame")
    dialog.Size = UDim2.new(0, 300, 0, 150)
    dialog.Position = UDim2.new(0.5, -150, 0.5, -75)
    dialog.BackgroundColor3 = COLORS.Background
    dialog.BorderSizePixel = 0
    dialog.Parent = socialUI
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 15)
    corner.Parent = dialog
    
    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(1, -20, 0, 40)
    title.Position = UDim2.new(0, 10, 0, 10)
    title.BackgroundTransparency = 1
    title.Text = "Add Friend"
    title.TextColor3 = COLORS.Text
    title.TextScaled = true
    title.Font = Enum.Font.SourceSansBold
    title.Parent = dialog
    
    local usernameBox = Instance.new("TextBox")
    usernameBox.Size = UDim2.new(1, -40, 0, 35)
    usernameBox.Position = UDim2.new(0, 20, 0, 50)
    usernameBox.BackgroundColor3 = COLORS.Surface
    usernameBox.BorderSizePixel = 0
    usernameBox.PlaceholderText = "Enter username..."
    usernameBox.Text = ""
    usernameBox.TextColor3 = COLORS.Text
    usernameBox.TextScaled = true
    usernameBox.Font = Enum.Font.SourceSans
    usernameBox.Parent = dialog
    
    local inputCorner = Instance.new("UICorner")
    inputCorner.CornerRadius = UDim.new(0, 8)
    inputCorner.Parent = usernameBox
    
    local sendButton = self:CreateStyledButton("Send Request", COLORS.Success, UDim2.new(0, 100, 0, 30))
    sendButton.Position = UDim2.new(0, 50, 0, 100)
    sendButton.Parent = dialog
    
    local cancelButton = self:CreateStyledButton("Cancel", COLORS.Error, UDim2.new(0, 100, 0, 30))
    cancelButton.Position = UDim2.new(0, 160, 0, 100)
    cancelButton.Parent = dialog
    
    sendButton.MouseButton1Click:Connect(function()
        local username = usernameBox.Text
        if username ~= "" then
            -- Convert username to userId (simplified)
            local success, userId = pcall(function()
                return Players:GetUserIdFromNameAsync(username)
            end)
            
            if success then
                RemoteEvents.SendFriendRequest:FireServer(userId)
                dialog:Destroy()
            else
                -- Show error
                usernameBox.PlaceholderText = "User not found!"
                usernameBox.Text = ""
            end
        end
    end)
    
    cancelButton.MouseButton1Click:Connect(function()
        dialog:Destroy()
    end)
end

function SocialController:UpdateFriendsList()
    local scrollFrame = friendsContent:FindFirstChild("FriendsScrollFrame")
    if not scrollFrame then return end
    
    -- Clear existing friends
    for _, child in pairs(scrollFrame:GetChildren()) do
        if child:IsA("Frame") then
            child:Destroy()
        end
    end
    
    -- Create friend entries
    for i, friend in ipairs(friendsList) do
        self:CreateFriendEntry(friend, scrollFrame, i)
    end
end

function SocialController:CreateFriendEntry(friendData, parent, index)
    local entry = Instance.new("Frame")
    entry.Size = UDim2.new(1, -10, 0, 60)
    entry.BackgroundColor3 = COLORS.Surface
    entry.BackgroundTransparency = 0.3
    entry.BorderSizePixel = 0
    entry.LayoutOrder = index
    entry.Parent = parent
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 10)
    corner.Parent = entry
    
    -- Online indicator
    local onlineIndicator = Instance.new("Frame")
    onlineIndicator.Size = UDim2.new(0, 12, 0, 12)
    onlineIndicator.Position = UDim2.new(0, 10, 0.5, -6)
    onlineIndicator.BackgroundColor3 = friendData.isOnline and COLORS.Success or Color3.new(0.5, 0.5, 0.5)
    onlineIndicator.BorderSizePixel = 0
    onlineIndicator.Parent = entry
    
    local indicatorCorner = Instance.new("UICorner")
    indicatorCorner.CornerRadius = UDim.new(0.5, 0)
    indicatorCorner.Parent = onlineIndicator
    
    -- Friend name
    local nameLabel = Instance.new("TextLabel")
    nameLabel.Size = UDim2.new(1, -150, 1, 0)
    nameLabel.Position = UDim2.new(0, 30, 0, 0)
    nameLabel.BackgroundTransparency = 1
    nameLabel.Text = friendData.playerName
    nameLabel.TextColor3 = COLORS.Text
    nameLabel.TextScaled = true
    nameLabel.Font = Enum.Font.SourceSansBold
    nameLabel.TextXAlignment = Enum.TextXAlignment.Left
    nameLabel.Parent = entry
    
    -- Action buttons
    local inviteButton = self:CreateStyledButton("🎉", COLORS.Primary, UDim2.new(0, 30, 0, 30))
    inviteButton.Position = UDim2.new(1, -70, 0.5, -15)
    inviteButton.Parent = entry
    
    local removeButton = self:CreateStyledButton("❌", COLORS.Error, UDim2.new(0, 30, 0, 30))
    removeButton.Position = UDim2.new(1, -35, 0.5, -15)
    removeButton.Parent = entry
    
    removeButton.MouseButton1Click:Connect(function()
        RemoteEvents.RemoveFriend:FireServer(friendData.userId)
    end)
end

function SocialController:UpdateRequestsList()
    local scrollFrame = requestsContent:FindFirstChild("RequestsScrollFrame")
    if not scrollFrame then return end
    
    -- Clear existing requests
    for _, child in pairs(scrollFrame:GetChildren()) do
        if child:IsA("Frame") then
            child:Destroy()
        end
    end
    
    -- Create request entries
    for i, request in ipairs(friendRequests) do
        self:CreateRequestEntry(request, scrollFrame, i)
    end
end

function SocialController:CreateRequestEntry(requestData, parent, index)
    local entry = Instance.new("Frame")
    entry.Size = UDim2.new(1, -10, 0, 80)
    entry.BackgroundColor3 = COLORS.Surface
    entry.BackgroundTransparency = 0.3
    entry.BorderSizePixel = 0
    entry.LayoutOrder = index
    entry.Parent = parent
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 10)
    corner.Parent = entry
    
    -- Request info
    local nameLabel = Instance.new("TextLabel")
    nameLabel.Size = UDim2.new(1, -140, 0, 30)
    nameLabel.Position = UDim2.new(0, 10, 0, 10)
    nameLabel.BackgroundTransparency = 1
    nameLabel.Text = requestData.playerName .. " wants to be friends"
    nameLabel.TextColor3 = COLORS.Text
    nameLabel.TextScaled = true
    nameLabel.Font = Enum.Font.SourceSansBold
    nameLabel.TextXAlignment = Enum.TextXAlignment.Left
    nameLabel.Parent = entry
    
    -- Time ago
    local timeLabel = Instance.new("TextLabel")
    timeLabel.Size = UDim2.new(1, -140, 0, 20)
    timeLabel.Position = UDim2.new(0, 10, 0, 40)
    timeLabel.BackgroundTransparency = 1
    timeLabel.Text = self:GetTimeAgo(requestData.timestamp)
    timeLabel.TextColor3 = Color3.new(0.7, 0.7, 0.7)
    timeLabel.TextScaled = true
    timeLabel.Font = Enum.Font.SourceSans
    timeLabel.TextXAlignment = Enum.TextXAlignment.Left
    timeLabel.Parent = entry
    
    -- Action buttons
    local acceptButton = self:CreateStyledButton("✓", COLORS.Success, UDim2.new(0, 40, 0, 30))
    acceptButton.Position = UDim2.new(1, -90, 0.5, -15)
    acceptButton.Parent = entry
    
    local declineButton = self:CreateStyledButton("✕", COLORS.Error, UDim2.new(0, 40, 0, 30))
    declineButton.Position = UDim2.new(1, -45, 0.5, -15)
    declineButton.Parent = entry
    
    acceptButton.MouseButton1Click:Connect(function()
        RemoteEvents.AcceptFriendRequest:FireServer(requestData.userId)
    end)
    
    declineButton.MouseButton1Click:Connect(function()
        RemoteEvents.DeclineFriendRequest:FireServer(requestData.userId)
    end)
end

function SocialController:GetTimeAgo(timestamp)
    local currentTime = os.time()
    local timeDiff = currentTime - timestamp
    
    if timeDiff < 60 then
        return "Just now"
    elseif timeDiff < 3600 then
        local minutes = math.floor(timeDiff / 60)
        return minutes .. " minute" .. (minutes == 1 and "" or "s") .. " ago"
    elseif timeDiff < 86400 then
        local hours = math.floor(timeDiff / 3600)
        return hours .. " hour" .. (hours == 1 and "" or "s") .. " ago"
    else
        local days = math.floor(timeDiff / 86400)
        return days .. " day" .. (days == 1 and "" or "s") .. " ago"
    end
end

function SocialController:SetupEventConnections()
    -- Friend system events
    RemoteEvents.FriendsListUpdated.OnClientEvent:Connect(function(newFriendsList)
        friendsList = newFriendsList
        if currentTab == "friends" then
            self:UpdateFriendsList()
        end
    end)
    
    RemoteEvents.GetFriendRequests.OnClientEvent:Connect(function(requests)
        friendRequests = requests
        if currentTab == "requests" then
            self:UpdateRequestsList()
        end
        
        -- Update requests tab badge
        if #requests > 0 then
            requestsTab.Text = "📨 Requests (" .. #requests .. ")"
        else
            requestsTab.Text = "📨 Requests"
        end
    end)
    
    -- Leaderboard events
    RemoteEvents.FriendsLeaderboardUpdated.OnClientEvent:Connect(function(leaderboard)
        self:UpdateLeaderboard(leaderboard, "friends")
    end)
    
    RemoteEvents.GlobalLeaderboardUpdated.OnClientEvent:Connect(function(leaderboard)
        self:UpdateLeaderboard(leaderboard, "global")
    end)
    
    RemoteEvents.PartyLeaderboardUpdated.OnClientEvent:Connect(function(leaderboard)
        self:UpdateLeaderboard(leaderboard, "party")
    end)
    
    -- Social engagement events
    RemoteEvents.FriendRequestReceived.OnClientEvent:Connect(function(senderId, senderName)
        self:ShowNotification("📨 Friend Request", senderName .. " sent you a friend request!", COLORS.Primary)
        RemoteEvents.GetFriendRequests:FireServer()
    end)
    
    RemoteEvents.FriendAdded.OnClientEvent:Connect(function(friendId, friendName)
        self:ShowNotification("🤝 New Friend", "You are now friends with " .. friendName .. "!", COLORS.Success)
        RemoteEvents.GetFriendsList:FireServer()
    end)
    
    RemoteEvents.ScoreLikeReceived.OnClientEvent:Connect(function(likerId, likerName)
        self:ShowNotification("👍 Score Liked", likerName .. " liked your score!", COLORS.Warning)
    end)
    
    RemoteEvents.ChallengeReceived.OnClientEvent:Connect(function(challenge)
        self:ShowNotification("⚔️ Challenge", challenge.challengerName .. " challenged you to " .. challenge.challengeType .. "!", COLORS.Secondary)
    end)
end

function SocialController:UpdateLeaderboard(leaderboard, type)
    local scrollFrame = leaderboardContent:FindFirstChild("LeaderboardScrollFrame")
    if not scrollFrame then return end
    
    -- Clear existing entries
    for _, child in pairs(scrollFrame:GetChildren()) do
        if child:IsA("Frame") then
            child:Destroy()
        end
    end
    
    -- Create leaderboard entries
    for i, entry in ipairs(leaderboard) do
        self:CreateLeaderboardEntry(entry, scrollFrame, i)
    end
end

function SocialController:CreateLeaderboardEntry(entryData, parent, index)
    local entry = Instance.new("Frame")
    entry.Size = UDim2.new(1, -10, 0, 50)
    entry.BackgroundColor3 = entryData.isPlayer and COLORS.Primary or COLORS.Surface
    entry.BackgroundTransparency = entryData.isPlayer and 0.2 or 0.3
    entry.BorderSizePixel = 0
    entry.LayoutOrder = index
    entry.Parent = parent
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 8)
    corner.Parent = entry
    
    -- Rank
    local rankLabel = Instance.new("TextLabel")
    rankLabel.Size = UDim2.new(0, 40, 1, 0)
    rankLabel.Position = UDim2.new(0, 5, 0, 0)
    rankLabel.BackgroundTransparency = 1
    rankLabel.Text = "#" .. (entryData.rank or index)
    rankLabel.TextColor3 = COLORS.Text
    rankLabel.TextScaled = true
    rankLabel.Font = Enum.Font.SourceSansBold
    rankLabel.Parent = entry
    
    -- Player name
    local nameLabel = Instance.new("TextLabel")
    nameLabel.Size = UDim2.new(0.4, 0, 1, 0)
    nameLabel.Position = UDim2.new(0, 50, 0, 0)
    nameLabel.BackgroundTransparency = 1
    nameLabel.Text = entryData.playerName
    nameLabel.TextColor3 = COLORS.Text
    nameLabel.TextScaled = true
    nameLabel.Font = Enum.Font.SourceSansBold
    nameLabel.TextXAlignment = Enum.TextXAlignment.Left
    nameLabel.Parent = entry
    
    -- Score
    local scoreLabel = Instance.new("TextLabel")
    scoreLabel.Size = UDim2.new(0.25, 0, 1, 0)
    scoreLabel.Position = UDim2.new(0.45, 0, 0, 0)
    scoreLabel.BackgroundTransparency = 1
    scoreLabel.Text = "🏆 " .. (entryData.score or 0)
    scoreLabel.TextColor3 = COLORS.Text
    scoreLabel.TextScaled = true
    scoreLabel.Font = Enum.Font.SourceSans
    scoreLabel.Parent = entry
    
    -- Coins
    local coinsLabel = Instance.new("TextLabel")
    coinsLabel.Size = UDim2.new(0.25, 0, 1, 0)
    coinsLabel.Position = UDim2.new(0.7, 0, 0, 0)
    coinsLabel.BackgroundTransparency = 1
    coinsLabel.Text = "💰 " .. (entryData.coins or 0)
    coinsLabel.TextColor3 = COLORS.Text
    coinsLabel.TextScaled = true
    coinsLabel.Font = Enum.Font.SourceSans
    coinsLabel.Parent = entry
    
    -- Online indicator for friends
    if entryData.isOnline ~= nil then
        local onlineIndicator = Instance.new("Frame")
        onlineIndicator.Size = UDim2.new(0, 8, 0, 8)
        onlineIndicator.Position = UDim2.new(1, -15, 0.5, -4)
        onlineIndicator.BackgroundColor3 = entryData.isOnline and COLORS.Success or Color3.new(0.5, 0.5, 0.5)
        onlineIndicator.BorderSizePixel = 0
        onlineIndicator.Parent = entry
        
        local indicatorCorner = Instance.new("UICorner")
        indicatorCorner.CornerRadius = UDim.new(0.5, 0)
        indicatorCorner.Parent = onlineIndicator
    end
end

function SocialController:ShowNotification(title, message, color)
    local notification = Instance.new("Frame")
    notification.Size = UDim2.new(0, 300, 0, 80)
    notification.Position = UDim2.new(1, -320, 0, 20)
    notification.BackgroundColor3 = color
    notification.BackgroundTransparency = 0.1
    notification.BorderSizePixel = 0
    notification.Parent = playerGui
    
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
    messageLabel.Size = UDim2.new(1, -10, 0, 45)
    messageLabel.Position = UDim2.new(0, 5, 0, 30)
    messageLabel.BackgroundTransparency = 1
    messageLabel.Text = message
    messageLabel.TextColor3 = COLORS.Text
    messageLabel.TextScaled = true
    messageLabel.Font = Enum.Font.SourceSans
    messageLabel.TextWrapped = true
    messageLabel.Parent = notification
    
    -- Entrance animation
    notification.Position = UDim2.new(1, 0, 0, 20)
    local entranceTween = TweenService:Create(
        notification,
        TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
        {Position = UDim2.new(1, -320, 0, 20)}
    )
    entranceTween:Play()
    
    -- Auto dismiss after 5 seconds
    spawn(function()
        wait(5)
        local exitTween = TweenService:Create(
            notification,
            TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
            {Position = UDim2.new(1, 0, 0, 20), BackgroundTransparency = 1}
        )
        exitTween:Play()
        exitTween.Completed:Connect(function()
            notification:Destroy()
        end)
    end)
end

function SocialController:SetupKeybinds()
    UserInputService.InputBegan:Connect(function(input, gameProcessed)
        if gameProcessed then return end
        
        if input.KeyCode == Enum.KeyCode.F then -- F for Friends
            if mainFrame and mainFrame.Visible then
                self:HideSocialUI()
            else
                self:ShowSocialUI()
            end
        end
    end)
end

-- Public interface
function SocialController:ToggleSocialUI()
    if mainFrame and mainFrame.Visible then
        self:HideSocialUI()
    else
        self:ShowSocialUI()
    end
end

return SocialController
