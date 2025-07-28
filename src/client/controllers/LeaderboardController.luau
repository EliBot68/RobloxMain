-- LeaderboardController.luau
-- Enhanced client-side leaderboard UI with social integration

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

local RemoteEvents = require(ReplicatedStorage.Shared.modules.RemoteEvents)
local GameConstants = require(ReplicatedStorage.Shared.constants.GameConstants)

local LeaderboardController = {}
local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- UI Variables
local leaderboardUI = nil
local mainFrame = nil
local categoryTabs = nil
local leaderboardDisplay = nil

-- Data
local leaderboardData = {
    global = {},
    friends = {},
    weekly = {},
    party = {}
}
local currentCategory = "global"

-- Colors
local COLORS = {
    Primary = Color3.new(0.2, 0.6, 1),
    Secondary = Color3.new(0.8, 0.4, 1),
    Success = Color3.new(0.2, 0.8, 0.2),
    Warning = Color3.new(1, 0.8, 0.2),
    Error = Color3.new(1, 0.3, 0.3),
    Background = Color3.new(0.05, 0.05, 0.1),
    Surface = Color3.new(0.1, 0.1, 0.15),
    Text = Color3.new(1, 1, 1),
    Gold = Color3.new(1, 0.8, 0),
    Silver = Color3.new(0.8, 0.8, 0.8),
    Bronze = Color3.new(0.8, 0.5, 0.2)
}

function LeaderboardController:Initialize()
    print("🏆 Initializing LeaderboardController...")
    
    self:CreateLeaderboardUI()
    self:SetupEventConnections()
    self:SetupKeybinds()
    
    -- Request initial data
    self:RequestLeaderboardData("global")
    
    print("✅ LeaderboardController initialized!")
end

function LeaderboardController:CreateLeaderboardUI()
    if leaderboardUI then leaderboardUI:Destroy() end
    
    -- Main UI
    leaderboardUI = Instance.new("ScreenGui")
    leaderboardUI.Name = "LeaderboardUI"
    leaderboardUI.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    leaderboardUI.Parent = playerGui
    
    -- Main frame with modern design
    mainFrame = Instance.new("Frame")
    mainFrame.Name = "MainFrame"
    mainFrame.Size = UDim2.new(0, 500, 0, 600)
    mainFrame.Position = UDim2.new(0.5, -250, 0.5, -300)
    mainFrame.BackgroundColor3 = COLORS.Background
    mainFrame.BackgroundTransparency = 0.05
    mainFrame.BorderSizePixel = 0
    mainFrame.Visible = false
    mainFrame.Parent = leaderboardUI
    
    -- Rounded corners and glow
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 20)
    corner.Parent = mainFrame
    
    local stroke = Instance.new("UIStroke")
    stroke.Color = COLORS.Primary
    stroke.Thickness = 2
    stroke.Transparency = 0.3
    stroke.Parent = mainFrame
    
    -- Header with title
    local header = Instance.new("Frame")
    header.Name = "Header"
    header.Size = UDim2.new(1, 0, 0, 70)
    header.BackgroundColor3 = COLORS.Surface
    header.BackgroundTransparency = 0.2
    header.BorderSizePixel = 0
    header.Parent = mainFrame
    
    local headerCorner = Instance.new("UICorner")
    headerCorner.CornerRadius = UDim.new(0, 20)
    headerCorner.Parent = header
    
    -- Animated title
    local titleLabel = Instance.new("TextLabel")
    titleLabel.Name = "TitleLabel"
    titleLabel.Size = UDim2.new(1, -120, 1, 0)
    titleLabel.Position = UDim2.new(0, 20, 0, 0)
    titleLabel.BackgroundTransparency = 1
    titleLabel.Text = "🏆 LEADERBOARDS"
    titleLabel.TextColor3 = COLORS.Text
    titleLabel.TextScaled = true
    titleLabel.Font = Enum.Font.SourceSansBold
    titleLabel.TextStrokeTransparency = 0
    titleLabel.TextStrokeColor3 = COLORS.Primary
    titleLabel.Parent = header
    
    -- Animated gradient
    local gradient = Instance.new("UIGradient")
    gradient.Color = ColorSequence.new{
        ColorSequenceKeypoint.new(0, COLORS.Gold),
        ColorSequenceKeypoint.new(0.5, COLORS.Silver),
        ColorSequenceKeypoint.new(1, COLORS.Bronze)
    }
    gradient.Parent = titleLabel
    
    -- Animate gradient
    spawn(function()
        while titleLabel.Parent do
            local tween = TweenService:Create(gradient, TweenInfo.new(3, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {Rotation = 360})
            tween:Play()
            tween.Completed:Wait()
            gradient.Rotation = 0
        end
    end)
    
    -- Close button
    local closeButton = self:CreateStyledButton("✕", COLORS.Error, UDim2.new(0, 40, 0, 40))
    closeButton.Position = UDim2.new(1, -50, 0.5, -20)
    closeButton.Parent = header
    closeButton.MouseButton1Click:Connect(function()
        self:HideLeaderboard()
    end)
    
    -- Refresh button
    local refreshButton = self:CreateStyledButton("🔄", COLORS.Success, UDim2.new(0, 40, 0, 40))
    refreshButton.Position = UDim2.new(1, -95, 0.5, -20)
    refreshButton.Parent = header
    refreshButton.MouseButton1Click:Connect(function()
        self:RequestLeaderboardData(currentCategory)
    end)
    
    self:CreateCategoryTabs()
    self:CreateLeaderboardDisplay()
    
    print("🎨 Enhanced LeaderboardUI created!")
end

function LeaderboardController:CreateCategoryTabs()
    -- Category tabs container
    categoryTabs = Instance.new("Frame")
    categoryTabs.Name = "CategoryTabs"
    categoryTabs.Size = UDim2.new(1, -40, 0, 50)
    categoryTabs.Position = UDim2.new(0, 20, 0, 80)
    categoryTabs.BackgroundTransparency = 1
    categoryTabs.Parent = mainFrame
    
    local tabLayout = Instance.new("UIListLayout")
    tabLayout.FillDirection = Enum.FillDirection.Horizontal
    tabLayout.SortOrder = Enum.SortOrder.LayoutOrder
    tabLayout.Padding = UDim.new(0, 5)
    tabLayout.Parent = categoryTabs
    
    -- Create category tabs
    local tabs = {
        {name = "global", text = "🌍 Global", color = COLORS.Primary},
        {name = "friends", text = "👥 Friends", color = COLORS.Success},
        {name = "weekly", text = "📅 Weekly", color = COLORS.Warning},
        {name = "party", text = "🎉 Party", color = COLORS.Secondary}
    }
    
    for i, tabData in ipairs(tabs) do
        local tab = self:CreateCategoryTab(tabData.text, tabData.name, tabData.color, i)
        tab.Parent = categoryTabs
    end
end

function LeaderboardController:CreateCategoryTab(text, category, color, order)
    local tab = Instance.new("TextButton")
    tab.Name = category .. "Tab"
    tab.Size = UDim2.new(0, 100, 1, 0)
    tab.BackgroundColor3 = color
    tab.BackgroundTransparency = 0.5
    tab.BorderSizePixel = 0
    tab.Text = text
    tab.TextColor3 = COLORS.Text
    tab.TextScaled = true
    tab.Font = Enum.Font.SourceSansBold
    tab.LayoutOrder = order
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 10)
    corner.Parent = tab
    
    local stroke = Instance.new("UIStroke")
    stroke.Color = color
    stroke.Thickness = 2
    stroke.Transparency = 0.3
    stroke.Parent = tab
    
    -- Click handler
    tab.MouseButton1Click:Connect(function()
        self:SwitchCategory(category)
    end)
    
    -- Hover effects
    tab.MouseEnter:Connect(function()
        local tween = TweenService:Create(tab, TweenInfo.new(0.2), {BackgroundTransparency = 0.3})
        tween:Play()
    end)
    
    tab.MouseLeave:Connect(function()
        if currentCategory ~= category then
            local tween = TweenService:Create(tab, TweenInfo.new(0.2), {BackgroundTransparency = 0.5})
            tween:Play()
        end
    end)
    
    return tab
end

function LeaderboardController:CreateLeaderboardDisplay()
    -- Main leaderboard container
    leaderboardDisplay = Instance.new("Frame")
    leaderboardDisplay.Name = "LeaderboardDisplay"
    leaderboardDisplay.Size = UDim2.new(1, -40, 1, -150)
    leaderboardDisplay.Position = UDim2.new(0, 20, 0, 140)
    leaderboardDisplay.BackgroundColor3 = COLORS.Surface
    leaderboardDisplay.BackgroundTransparency = 0.3
    leaderboardDisplay.BorderSizePixel = 0
    leaderboardDisplay.Parent = mainFrame
    
    local displayCorner = Instance.new("UICorner")
    displayCorner.CornerRadius = UDim.new(0, 15)
    displayCorner.Parent = leaderboardDisplay
    
    -- Header with column labels
    local headerFrame = Instance.new("Frame")
    headerFrame.Name = "HeaderFrame"
    headerFrame.Size = UDim2.new(1, -20, 0, 40)
    headerFrame.Position = UDim2.new(0, 10, 0, 10)
    headerFrame.BackgroundColor3 = COLORS.Background
    headerFrame.BackgroundTransparency = 0.2
    headerFrame.BorderSizePixel = 0
    headerFrame.Parent = leaderboardDisplay
    
    local headerCorner = Instance.new("UICorner")
    headerCorner.CornerRadius = UDim.new(0, 10)
    headerCorner.Parent = headerFrame
    
    -- Column headers
    self:CreateColumnHeader("Rank", UDim2.new(0, 60, 1, 0), UDim2.new(0, 10, 0, 0), headerFrame)
    self:CreateColumnHeader("Player", UDim2.new(0, 200, 1, 0), UDim2.new(0, 80, 0, 0), headerFrame)
    self:CreateColumnHeader("Score", UDim2.new(0, 80, 1, 0), UDim2.new(0, 290, 0, 0), headerFrame)
    self:CreateColumnHeader("Coins", UDim2.new(0, 80, 1, 0), UDim2.new(0, 380, 0, 0), headerFrame)
    
    -- Scrollable entries area
    local entriesScrollFrame = Instance.new("ScrollingFrame")
    entriesScrollFrame.Name = "EntriesScrollFrame"
    entriesScrollFrame.Size = UDim2.new(1, -20, 1, -60)
    entriesScrollFrame.Position = UDim2.new(0, 10, 0, 50)
    entriesScrollFrame.BackgroundTransparency = 1
    entriesScrollFrame.BorderSizePixel = 0
    entriesScrollFrame.ScrollBarThickness = 8
    entriesScrollFrame.ScrollBarImageColor3 = COLORS.Primary
    entriesScrollFrame.Parent = leaderboardDisplay
    
    local entriesLayout = Instance.new("UIListLayout")
    entriesLayout.SortOrder = Enum.SortOrder.LayoutOrder
    entriesLayout.Padding = UDim.new(0, 2)
    entriesLayout.Parent = entriesScrollFrame
    
    entriesScrollFrame:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        entriesScrollFrame.CanvasSize = UDim2.new(0, 0, 0, entriesLayout.AbsoluteContentSize.Y + 10)
    end)
end

function LeaderboardController:CreateColumnHeader(text, size, position, parent)
    local header = Instance.new("TextLabel")
    header.Size = size
    header.Position = position
    header.BackgroundTransparency = 1
    header.Text = text
    header.TextColor3 = COLORS.Text
    header.TextScaled = true
    header.Font = Enum.Font.SourceSansBold
    header.TextXAlignment = Enum.TextXAlignment.Center
    header.Parent = parent
    
    return header
end

function LeaderboardController:SwitchCategory(category)
    currentCategory = category
    
    -- Update tab visuals
    for _, tab in pairs(categoryTabs:GetChildren()) do
        if tab:IsA("TextButton") then
            if tab.Name == category .. "Tab" then
                tab.BackgroundTransparency = 0.1
            else
                tab.BackgroundTransparency = 0.5
            end
        end
    end
    
    -- Request data for new category
    self:RequestLeaderboardData(category)
    
    -- Update display
    self:UpdateLeaderboardDisplay(category)
end

function LeaderboardController:RequestLeaderboardData(category)
    if category == "global" then
        RemoteEvents.RequestSocialLeaderboard:FireServer("global")
    elseif category == "friends" then
        RemoteEvents.RequestSocialLeaderboard:FireServer("friends")
    elseif category == "weekly" then
        RemoteEvents.RequestWeeklyLeaderboard:FireServer()
    elseif category == "party" then
        RemoteEvents.RequestSocialLeaderboard:FireServer("party")
    end
end

function LeaderboardController:UpdateLeaderboardDisplay(category)
    local scrollFrame = leaderboardDisplay:FindFirstChild("EntriesScrollFrame")
    if not scrollFrame then return end
    
    -- Clear existing entries
    for _, child in pairs(scrollFrame:GetChildren()) do
        if child:IsA("Frame") then
            child:Destroy()
        end
    end
    
    local data = leaderboardData[category] or {}
    
    -- Create entries
    for i, entryData in ipairs(data) do
        self:CreateLeaderboardEntry(entryData, scrollFrame, i)
    end
    
    -- Show empty state if no data
    if #data == 0 then
        self:CreateEmptyState(scrollFrame, category)
    end
end

function LeaderboardController:CreateLeaderboardEntry(entryData, parent, index)
    local entry = Instance.new("Frame")
    entry.Name = "Entry" .. index
    entry.Size = UDim2.new(1, -10, 0, 50)
    entry.BackgroundColor3 = self:GetEntryColor(index, entryData.isPlayer)
    entry.BackgroundTransparency = entryData.isPlayer and 0.1 or 0.3
    entry.BorderSizePixel = 0
    entry.LayoutOrder = index
    entry.Parent = parent
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 8)
    corner.Parent = entry
    
    -- Special effects for top 3
    if index <= 3 then
        local stroke = Instance.new("UIStroke")
        stroke.Color = self:GetRankColor(index)
        stroke.Thickness = 2
        stroke.Transparency = 0.3
        stroke.Parent = entry
        
        -- Glow effect for #1
        if index == 1 then
            local glow = Instance.new("ImageLabel")
            glow.Size = UDim2.new(1, 20, 1, 20)
            glow.Position = UDim2.new(0, -10, 0, -10)
            glow.BackgroundTransparency = 1
            glow.Image = "rbxasset://textures/ui/GuiImagePlaceholder.png"
            glow.ImageColor3 = COLORS.Gold
            glow.ImageTransparency = 0.7
            glow.ZIndex = -1
            glow.Parent = entry
        end
    end
    
    -- Rank with medal for top 3
    local rankLabel = Instance.new("TextLabel")
    rankLabel.Size = UDim2.new(0, 60, 1, 0)
    rankLabel.Position = UDim2.new(0, 5, 0, 0)
    rankLabel.BackgroundTransparency = 1
    rankLabel.Text = self:GetRankDisplay(index)
    rankLabel.TextColor3 = COLORS.Text
    rankLabel.TextScaled = true
    rankLabel.Font = Enum.Font.SourceSansBold
    rankLabel.Parent = entry
    
    -- Player name with status indicator
    local nameFrame = Instance.new("Frame")
    nameFrame.Size = UDim2.new(0, 200, 1, 0)
    nameFrame.Position = UDim2.new(0, 75, 0, 0)
    nameFrame.BackgroundTransparency = 1
    nameFrame.Parent = entry
    
    local nameLabel = Instance.new("TextLabel")
    nameLabel.Size = UDim2.new(1, -20, 1, 0)
    nameLabel.Position = UDim2.new(0, 0, 0, 0)
    nameLabel.BackgroundTransparency = 1
    nameLabel.Text = entryData.playerName or "Unknown"
    nameLabel.TextColor3 = COLORS.Text
    nameLabel.TextScaled = true
    nameLabel.Font = entryData.isPlayer and Enum.Font.SourceSansBold or Enum.Font.SourceSans
    nameLabel.TextXAlignment = Enum.TextXAlignment.Left
    nameLabel.Parent = nameFrame
    
    -- Online indicator (for friends)
    if entryData.isOnline ~= nil then
        local onlineIndicator = Instance.new("Frame")
        onlineIndicator.Size = UDim2.new(0, 10, 0, 10)
        onlineIndicator.Position = UDim2.new(1, -15, 0.5, -5)
        onlineIndicator.BackgroundColor3 = entryData.isOnline and COLORS.Success or Color3.new(0.5, 0.5, 0.5)
        onlineIndicator.BorderSizePixel = 0
        onlineIndicator.Parent = nameFrame
        
        local indicatorCorner = Instance.new("UICorner")
        indicatorCorner.CornerRadius = UDim.new(0.5, 0)
        indicatorCorner.Parent = onlineIndicator
    end
    
    -- Score
    local scoreLabel = Instance.new("TextLabel")
    scoreLabel.Size = UDim2.new(0, 80, 1, 0)
    scoreLabel.Position = UDim2.new(0, 285, 0, 0)
    scoreLabel.BackgroundTransparency = 1
    scoreLabel.Text = self:FormatNumber(entryData.score or 0)
    scoreLabel.TextColor3 = COLORS.Text
    scoreLabel.TextScaled = true
    scoreLabel.Font = Enum.Font.SourceSans
    scoreLabel.Parent = entry
    
    -- Coins
    local coinsLabel = Instance.new("TextLabel")
    coinsLabel.Size = UDim2.new(0, 80, 1, 0)
    coinsLabel.Position = UDim2.new(0, 375, 0, 0)
    coinsLabel.BackgroundTransparency = 1
    coinsLabel.Text = self:FormatNumber(entryData.coins or 0)
    coinsLabel.TextColor3 = COLORS.Warning
    coinsLabel.TextScaled = true
    coinsLabel.Font = Enum.Font.SourceSans
    coinsLabel.Parent = entry
    
    -- Entry animation
    entry.Position = UDim2.new(1, 0, 0, 0)
    entry.BackgroundTransparency = 1
    
    local delay = (index - 1) * 0.05
    spawn(function()
        wait(delay)
        local tween = TweenService:Create(
            entry,
            TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
            {
                Position = UDim2.new(0, 0, 0, 0),
                BackgroundTransparency = entryData.isPlayer and 0.1 or 0.3
            }
        )
        tween:Play()
    end)
end

function LeaderboardController:CreateEmptyState(parent, category)
    local emptyFrame = Instance.new("Frame")
    emptyFrame.Size = UDim2.new(1, 0, 1, 0)
    emptyFrame.BackgroundTransparency = 1
    emptyFrame.Parent = parent
    
    local emptyLabel = Instance.new("TextLabel")
    emptyLabel.Size = UDim2.new(1, -40, 0, 100)
    emptyLabel.Position = UDim2.new(0, 20, 0.5, -50)
    emptyLabel.BackgroundTransparency = 1
    emptyLabel.Text = self:GetEmptyStateText(category)
    emptyLabel.TextColor3 = Color3.new(0.6, 0.6, 0.6)
    emptyLabel.TextScaled = true
    emptyLabel.Font = Enum.Font.SourceSans
    emptyLabel.TextWrapped = true
    emptyLabel.Parent = emptyFrame
end

function LeaderboardController:GetEmptyStateText(category)
    if category == "friends" then
        return "📝 No friends on leaderboard yet!\nAdd some friends to see their scores here."
    elseif category == "party" then
        return "🎉 No party leaderboard available!\nJoin or create a party to see party rankings."
    elseif category == "weekly" then
        return "📅 Weekly leaderboard is being calculated...\nCheck back soon!"
    else
        return "🌍 Global leaderboard is loading...\nPlease wait a moment."
    end
end

function LeaderboardController:GetEntryColor(rank, isPlayer)
    if isPlayer then
        return COLORS.Primary
    elseif rank == 1 then
        return COLORS.Gold
    elseif rank == 2 then
        return COLORS.Silver
    elseif rank == 3 then
        return COLORS.Bronze
    else
        return COLORS.Surface
    end
end

function LeaderboardController:GetRankColor(rank)
    if rank == 1 then
        return COLORS.Gold
    elseif rank == 2 then
        return COLORS.Silver
    elseif rank == 3 then
        return COLORS.Bronze
    else
        return COLORS.Text
    end
end

function LeaderboardController:GetRankDisplay(rank)
    if rank == 1 then
        return "🥇"
    elseif rank == 2 then
        return "🥈"
    elseif rank == 3 then
        return "🥉"
    else
        return "#" .. rank
    end
end

function LeaderboardController:FormatNumber(number)
    if number >= 1000000 then
        return string.format("%.1fM", number / 1000000)
    elseif number >= 1000 then
        return string.format("%.1fK", number / 1000)
    else
        return tostring(number)
    end
end

function LeaderboardController:CreateStyledButton(text, color, size)
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

function LeaderboardController:SetupEventConnections()
    -- Social leaderboard events
    RemoteEvents.GlobalLeaderboardUpdated.OnClientEvent:Connect(function(data)
        leaderboardData.global = data
        if currentCategory == "global" then
            self:UpdateLeaderboardDisplay("global")
        end
    end)
    
    RemoteEvents.FriendsLeaderboardUpdated.OnClientEvent:Connect(function(data)
        leaderboardData.friends = data
        if currentCategory == "friends" then
            self:UpdateLeaderboardDisplay("friends")
        end
    end)
    
    RemoteEvents.PartyLeaderboardUpdated.OnClientEvent:Connect(function(data)
        leaderboardData.party = data
        if currentCategory == "party" then
            self:UpdateLeaderboardDisplay("party")
        end
    end)
    
    -- Weekly leaderboard events
    RemoteEvents.UpdateWeeklyLeaderboard.OnClientEvent:Connect(function(data)
        leaderboardData.weekly = data
        if currentCategory == "weekly" then
            self:UpdateLeaderboardDisplay("weekly")
        end
    end)
end

function LeaderboardController:SetupKeybinds()
    UserInputService.InputBegan:Connect(function(input, gameProcessed)
        if gameProcessed then return end
        
        if input.KeyCode == Enum.KeyCode.L then -- L for Leaderboard
            self:ToggleLeaderboard()
        end
    end)
end

function LeaderboardController:ShowLeaderboard()
    if not mainFrame then
        self:CreateLeaderboardUI()
    end
    
    mainFrame.Visible = true
    
    -- Entrance animation
    mainFrame.Size = UDim2.new(0, 0, 0, 0)
    mainFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
    
    local tween = TweenService:Create(
        mainFrame,
        TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
        {
            Size = UDim2.new(0, 500, 0, 600),
            Position = UDim2.new(0.5, -250, 0.5, -300)
        }
    )
    tween:Play()
    
    -- Request fresh data
    self:RequestLeaderboardData(currentCategory)
end

function LeaderboardController:HideLeaderboard()
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

function LeaderboardController:ToggleLeaderboard()
    if mainFrame and mainFrame.Visible then
        self:HideLeaderboard()
    else
        self:ShowLeaderboard()
    end
end

-- Public interface
function LeaderboardController:ShowCategory(category)
    self:ShowLeaderboard()
    self:SwitchCategory(category)
end

return LeaderboardController
