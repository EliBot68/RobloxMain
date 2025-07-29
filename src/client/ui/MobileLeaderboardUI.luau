-- MobileLeaderboardUI.luau
-- Mobile-optimized leaderboard and achievement interface

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

local SafeRequire = require(ReplicatedStorage.Shared.utils.SafeRequire)
local RemoteEvents = SafeRequire.require(ReplicatedStorage.Shared.modules.RemoteEvents)
local MobileOptimizationService = require(script.Parent.Parent.services.MobileOptimizationService)

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local MobileLeaderboardUI = {}

-- Leaderboard state
local leaderboardState = {
    isVisible = false,
    currentTab = "Global",
    leaderboardData = {
        Global = {},
        Weekly = {},
        Daily = {},
        Friends = {}
    },
    achievementData = {},
    playerStats = {
        rank = 0,
        score = 0,
        weeklyRank = 0,
        weeklyScore = 0,
        totalGames = 0,
        winRate = 0
    }
}

local leaderboardGui = nil
local layoutProps = nil

-- Create mobile leaderboard UI
function MobileLeaderboardUI.createLeaderboardUI()
    layoutProps = MobileOptimizationService.getLayoutProperties()
    local config = layoutProps.config
    
    -- Leaderboard modal
    local leaderboardModal = MobileOptimizationService.createMobileModal({
        title = "🏆 Leaderboards & Achievements",
        height = layoutProps.deviceType == "Phone" and 550 or 650,
        backgroundColor = Color3.fromRGB(248, 249, 250),
        closeOnBackgroundTap = true
    })
    
    leaderboardGui = leaderboardModal.overlay
    
    -- Create tab system
    local tabContainer = Instance.new("Frame")
    tabContainer.Name = "TabContainer"
    tabContainer.Size = UDim2.new(1, 0, 0, layoutProps.deviceType == "Phone" and 45 or 55)
    tabContainer.Position = UDim2.new(0, 0, 0, 0)
    tabContainer.BackgroundColor3 = Color3.fromRGB(236, 240, 241)
    tabContainer.BorderSizePixel = 0
    tabContainer.Parent = leaderboardModal.contentArea
    
    local tabCorner = Instance.new("UICorner")
    tabCorner.CornerRadius = UDim.new(0, 6)
    tabCorner.Parent = tabContainer
    
    local tabLayout = Instance.new("UIListLayout")
    tabLayout.FillDirection = Enum.FillDirection.Horizontal
    tabLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
    tabLayout.VerticalAlignment = Enum.VerticalAlignment.Center
    tabLayout.Padding = UDim.new(0, 2)
    tabLayout.Parent = tabContainer
    
    -- Content area
    local contentFrame = Instance.new("Frame")
    contentFrame.Size = UDim2.new(1, 0, 1, -(layoutProps.deviceType == "Phone" and 50 or 60))
    contentFrame.Position = UDim2.new(0, 0, 0, layoutProps.deviceType == "Phone" and 50 or 60)
    contentFrame.BackgroundTransparency = 1
    contentFrame.Parent = leaderboardModal.contentArea
    
    -- Create tabs
    local tabs = {
        {name = "Global", icon = "🌍"},
        {name = "Weekly", icon = "📅"},
        {name = "Friends", icon = "👥"},
        {name = "Achievements", icon = "🏅"}
    }
    
    local tabButtons = {}
    for i, tab in ipairs(tabs) do
        local tabButton = MobileOptimizationService.createMobileButton({
            size = UDim2.new(0, layoutProps.deviceType == "Phone" and 75 : 90, 1, -4),
            backgroundColor = i == 1 and Color3.fromRGB(52, 152, 219) or Color3.fromRGB(189, 195, 199),
            text = layoutProps.deviceType == "Phone" and tab.icon or (tab.icon .. "\n" .. tab.name),
            textSize = layoutProps.deviceType == "Phone" and config.fontSize.medium or config.fontSize.small,
            parent = tabContainer
        })
        
        tabButtons[tab.name] = tabButton
        
        tabButton.MouseButton1Click:Connect(function()
            MobileLeaderboardUI.switchTab(tab.name, tabButtons, contentFrame, config)
        end)
    end
    
    -- Load initial tab
    MobileLeaderboardUI.loadTab("Global", contentFrame, config)
    
    leaderboardState.isVisible = true
    return leaderboardModal
end

-- Switch leaderboard tab
function MobileLeaderboardUI.switchTab(tabName, tabButtons, contentArea, config)
    -- Update tab button states
    for name, button in pairs(tabButtons) do
        if name == tabName then
            button.BackgroundColor3 = Color3.fromRGB(52, 152, 219)
        else
            button.BackgroundColor3 = Color3.fromRGB(189, 195, 199)
        end
    end
    
    -- Clear current content
    for _, child in ipairs(contentArea:GetChildren()) do
        child:Destroy()
    end
    
    -- Load new tab content
    MobileLeaderboardUI.loadTab(tabName, contentArea, config)
    leaderboardState.currentTab = tabName
end

-- Load tab content
function MobileLeaderboardUI.loadTab(tabName, parent, config)
    if tabName == "Achievements" then
        MobileLeaderboardUI.createAchievementsTab(parent, config)
    else
        MobileLeaderboardUI.createLeaderboardTab(tabName, parent, config)
    end
end

-- Create leaderboard tab content
function MobileLeaderboardUI.createLeaderboardTab(tabType, parent, config)
    -- Player stats header
    local statsHeader = Instance.new("Frame")
    statsHeader.Size = UDim2.new(1, 0, 0, layoutProps.deviceType == "Phone" and 80 or 100)
    statsHeader.BackgroundColor3 = Color3.fromRGB(52, 152, 219)
    statsHeader.BorderSizePixel = 0
    statsHeader.Parent = parent
    
    local statsCorner = Instance.new("UICorner")
    statsCorner.CornerRadius = UDim.new(0, 8)
    statsCorner.Parent = statsHeader
    
    -- Player rank and score
    local playerInfoLayout = Instance.new("UIListLayout")
    playerInfoLayout.FillDirection = Enum.FillDirection.Horizontal
    playerInfoLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
    playerInfoLayout.VerticalAlignment = Enum.VerticalAlignment.Center
    playerInfoLayout.Padding = UDim.new(0, config.padding.large)
    playerInfoLayout.Parent = statsHeader
    
    -- Player avatar (smaller on mobile)
    local avatarSize = layoutProps.deviceType == "Phone" and 50 or 60
    local avatarFrame = Instance.new("Frame")
    avatarFrame.Size = UDim2.new(0, avatarSize, 0, avatarSize)
    avatarFrame.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    avatarFrame.BorderSizePixel = 0
    avatarFrame.Parent = statsHeader
    
    local avatarCorner = Instance.new("UICorner")
    avatarCorner.CornerRadius = UDim.new(0.5, 0)
    avatarCorner.Parent = avatarFrame
    
    -- Player avatar image (would normally load from Roblox)
    local avatarLabel = Instance.new("TextLabel")
    avatarLabel.Size = UDim2.new(1, 0, 1, 0)
    avatarLabel.BackgroundTransparency = 1
    avatarLabel.Text = "👤"
    avatarLabel.TextSize = config.fontSize.title
    avatarLabel.Parent = avatarFrame
    
    -- Player name and stats
    local playerStatsFrame = Instance.new("Frame")
    playerStatsFrame.Size = UDim2.new(0, 200, 1, -10)
    playerStatsFrame.BackgroundTransparency = 1
    playerStatsFrame.Parent = statsHeader
    
    local playerNameLabel = Instance.new("TextLabel")
    playerNameLabel.Size = UDim2.new(1, 0, 0.4, 0)
    playerNameLabel.BackgroundTransparency = 1
    playerNameLabel.Text = player.Name
    playerNameLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    playerNameLabel.TextSize = config.fontSize.large
    playerNameLabel.Font = Enum.Font.SourceSansBold
    playerNameLabel.TextXAlignment = Enum.TextXAlignment.Left
    playerNameLabel.Parent = playerStatsFrame
    
    local playerRankLabel = Instance.new("TextLabel")
    playerRankLabel.Size = UDim2.new(1, 0, 0.3, 0)
    playerRankLabel.Position = UDim2.new(0, 0, 0.4, 0)
    playerRankLabel.BackgroundTransparency = 1
    playerRankLabel.Text = "Rank: #" .. (leaderboardState.playerStats.rank > 0 and tostring(leaderboardState.playerStats.rank) or "Unranked")
    playerRankLabel.TextColor3 = Color3.fromRGB(236, 240, 241)
    playerRankLabel.TextSize = config.fontSize.medium
    playerRankLabel.Font = Enum.Font.SourceSans
    playerRankLabel.TextXAlignment = Enum.TextXAlignment.Left
    playerRankLabel.Parent = playerStatsFrame
    
    local playerScoreLabel = Instance.new("TextLabel")
    playerScoreLabel.Size = UDim2.new(1, 0, 0.3, 0)
    playerScoreLabel.Position = UDim2.new(0, 0, 0.7, 0)
    playerScoreLabel.BackgroundTransparency = 1
    playerScoreLabel.Text = "Score: " .. tostring(leaderboardState.playerStats.score)
    playerScoreLabel.TextColor3 = Color3.fromRGB(236, 240, 241)
    playerScoreLabel.TextSize = config.fontSize.medium
    playerScoreLabel.Font = Enum.Font.SourceSans
    playerScoreLabel.TextXAlignment = Enum.TextXAlignment.Left
    playerScoreLabel.Parent = playerStatsFrame
    
    -- Leaderboard list
    local leaderboardScroll = MobileOptimizationService.createMobileScrollFrame({
        size = UDim2.new(1, 0, 1, -(layoutProps.deviceType == "Phone" and 90 or 110)),
        position = UDim2.new(0, 0, 0, layoutProps.deviceType == "Phone" and 85 or 105),
        backgroundColor = Color3.fromRGB(255, 255, 255),
        backgroundTransparency = 1,
        useListLayout = true,
        parent = parent
    })
    
    -- Create leaderboard entries
    local leaderboardData = leaderboardState.leaderboardData[tabType] or {}
    if #leaderboardData == 0 then
        -- Show loading or empty state
        MobileLeaderboardUI.createEmptyState(leaderboardScroll, tabType, config)
    else
        for i, entry in ipairs(leaderboardData) do
            MobileLeaderboardUI.createLeaderboardEntry(leaderboardScroll, i, entry, config)
        end
    end
    
    -- Refresh button
    local refreshButton = MobileOptimizationService.createMobileButton({
        size = UDim2.new(0, layoutProps.deviceType == "Phone" and 120 or 140, 0, 35),
        position = UDim2.new(1, -(layoutProps.deviceType == "Phone" and 130 or 150), 1, -45),
        backgroundColor = Color3.fromRGB(46, 204, 113),
        text = "🔄 Refresh",
        textSize = config.fontSize.small,
        parent = parent
    })
    
    refreshButton.MouseButton1Click:Connect(function()
        MobileLeaderboardUI.refreshLeaderboard(tabType)
    end)
end

-- Create leaderboard entry
function MobileLeaderboardUI.createLeaderboardEntry(parent, rank, entry, config)
    local entryFrame = Instance.new("Frame")
    entryFrame.Size = UDim2.new(1, -10, 0, layoutProps.deviceType == "Phone" and 60 or 70)
    entryFrame.BackgroundColor3 = rank <= 3 and Color3.fromRGB(255, 235, 59) or Color3.fromRGB(255, 255, 255)
    entryFrame.BackgroundTransparency = rank <= 3 and 0.8 or 0
    entryFrame.BorderSizePixel = rank <= 3 and 2 or 1
    entryFrame.BorderColor3 = rank == 1 and Color3.fromRGB(255, 193, 7) or 
                             rank == 2 and Color3.fromRGB(158, 158, 158) or
                             rank == 3 and Color3.fromRGB(205, 127, 50) or Color3.fromRGB(189, 195, 199)
    entryFrame.Parent = parent
    
    local entryCorner = Instance.new("UICorner")
    entryCorner.CornerRadius = UDim.new(0, 6)
    entryCorner.Parent = entryFrame
    
    -- Rank badge
    local rankSize = layoutProps.deviceType == "Phone" and 35 or 40
    local rankBadge = Instance.new("Frame")
    rankBadge.Size = UDim2.new(0, rankSize, 0, rankSize)
    rankBadge.Position = UDim2.new(0, 10, 0.5, -rankSize/2)
    rankBadge.BackgroundColor3 = rank == 1 and Color3.fromRGB(255, 193, 7) or 
                                rank == 2 and Color3.fromRGB(158, 158, 158) or
                                rank == 3 and Color3.fromRGB(205, 127, 50) or Color3.fromRGB(52, 152, 219)
    rankBadge.BorderSizePixel = 0
    rankBadge.Parent = entryFrame
    
    local rankCorner = Instance.new("UICorner")
    rankCorner.CornerRadius = UDim.new(0.5, 0)
    rankCorner.Parent = rankBadge
    
    local rankLabel = Instance.new("TextLabel")
    rankLabel.Size = UDim2.new(1, 0, 1, 0)
    rankLabel.BackgroundTransparency = 1
    rankLabel.Text = rank <= 3 and (rank == 1 and "🥇" or rank == 2 and "🥈" or "🥉") or tostring(rank)
    rankLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    rankLabel.TextSize = rank <= 3 and config.fontSize.medium or config.fontSize.small
    rankLabel.Font = Enum.Font.SourceSansBold
    rankLabel.Parent = rankBadge
    
    -- Player info
    local playerName = Instance.new("TextLabel")
    playerName.Size = UDim2.new(0.5, -30, 0.6, 0)
    playerName.Position = UDim2.new(0, rankSize + 20, 0, 5)
    playerName.BackgroundTransparency = 1
    playerName.Text = entry.playerName or "Unknown Player"
    playerName.TextColor3 = Color3.fromRGB(44, 62, 80)
    playerName.TextSize = config.fontSize.medium
    playerName.Font = Enum.Font.SourceSansBold
    playerName.TextXAlignment = Enum.TextXAlignment.Left
    playerName.TextTruncate = Enum.TextTruncate.AtEnd
    playerName.Parent = entryFrame
    
    -- Score
    local scoreLabel = Instance.new("TextLabel")
    scoreLabel.Size = UDim2.new(0.3, 0, 0.6, 0)
    scoreLabel.Position = UDim2.new(0.7, 0, 0, 5)
    scoreLabel.BackgroundTransparency = 1
    scoreLabel.Text = tostring(entry.score or 0)
    scoreLabel.TextColor3 = Color3.fromRGB(52, 152, 219)
    scoreLabel.TextSize = config.fontSize.medium
    scoreLabel.Font = Enum.Font.SourceSansBold
    scoreLabel.TextXAlignment = Enum.TextXAlignment.Right
    scoreLabel.Parent = entryFrame
    
    -- Additional info (games played, win rate, etc.)
    local infoLabel = Instance.new("TextLabel")
    infoLabel.Size = UDim2.new(1, -rankSize - 30, 0.4, 0)
    infoLabel.Position = UDim2.new(0, rankSize + 20, 0.6, 0)
    infoLabel.BackgroundTransparency = 1
    infoLabel.Text = string.format("Games: %d | Win Rate: %.1f%%", entry.gamesPlayed or 0, entry.winRate or 0)
    infoLabel.TextColor3 = Color3.fromRGB(127, 140, 141)
    infoLabel.TextSize = config.fontSize.small
    infoLabel.Font = Enum.Font.SourceSans
    infoLabel.TextXAlignment = Enum.TextXAlignment.Left
    infoLabel.Parent = entryFrame
    
    -- Highlight player's entry
    if entry.playerId == player.UserId then
        entryFrame.BackgroundColor3 = Color3.fromRGB(46, 204, 113)
        entryFrame.BackgroundTransparency = 0.8
        entryFrame.BorderColor3 = Color3.fromRGB(46, 204, 113)
        
        playerName.TextColor3 = Color3.fromRGB(27, 94, 32)
        scoreLabel.TextColor3 = Color3.fromRGB(27, 94, 32)
    end
end

-- Create achievements tab
function MobileLeaderboardUI.createAchievementsTab(parent, config)
    -- Achievement categories
    local categories = {"Recent", "Progress", "Completed", "Locked"}
    
    -- Category selector
    local categoryFrame = Instance.new("Frame")
    categoryFrame.Size = UDim2.new(1, 0, 0, 40)
    categoryFrame.BackgroundColor3 = Color3.fromRGB(236, 240, 241)
    categoryFrame.BorderSizePixel = 0
    categoryFrame.Parent = parent
    
    local categoryCorner = Instance.new("UICorner")
    categoryCorner.CornerRadius = UDim.new(0, 6)
    categoryCorner.Parent = categoryFrame
    
    local categoryLayout = Instance.new("UIListLayout")
    categoryLayout.FillDirection = Enum.FillDirection.Horizontal
    categoryLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
    categoryLayout.VerticalAlignment = Enum.VerticalAlignment.Center
    categoryLayout.Padding = UDim.new(0, 2)
    categoryLayout.Parent = categoryFrame
    
    -- Achievement scroll area
    local achievementScroll = MobileOptimizationService.createMobileScrollFrame({
        size = UDim2.new(1, 0, 1, -50),
        position = UDim2.new(0, 0, 0, 45),
        backgroundColor = Color3.fromRGB(255, 255, 255),
        backgroundTransparency = 1,
        useListLayout = false,
        parent = parent
    })
    
    -- Create category buttons
    local categoryButtons = {}
    for i, category in ipairs(categories) do
        local categoryButton = MobileOptimizationService.createMobileButton({
            size = UDim2.new(0, layoutProps.deviceType == "Phone" and 70 or 85, 1, -4),
            backgroundColor = i == 1 and Color3.fromRGB(155, 89, 182) or Color3.fromRGB(189, 195, 199),
            text = category,
            textSize = config.fontSize.small,
            parent = categoryFrame
        })
        
        categoryButtons[category] = categoryButton
        
        categoryButton.MouseButton1Click:Connect(function()
            MobileLeaderboardUI.switchAchievementCategory(category, categoryButtons, achievementScroll, config)
        end)
    end
    
    -- Load initial achievements
    MobileLeaderboardUI.loadAchievements("Recent", achievementScroll, config)
end

-- Switch achievement category
function MobileLeaderboardUI.switchAchievementCategory(categoryName, categoryButtons, achievementArea, config)
    -- Update button states
    for name, button in pairs(categoryButtons) do
        if name == categoryName then
            button.BackgroundColor3 = Color3.fromRGB(155, 89, 182)
        else
            button.BackgroundColor3 = Color3.fromRGB(189, 195, 199)
        end
    end
    
    -- Clear current achievements
    for _, child in ipairs(achievementArea:GetChildren()) do
        if child:IsA("Frame") and child.Name ~= "UIListLayout" and child.Name ~= "UIPadding" then
            child:Destroy()
        end
    end
    
    -- Load new category
    MobileLeaderboardUI.loadAchievements(categoryName, achievementArea, config)
end

-- Load achievements
function MobileLeaderboardUI.loadAchievements(category, parent, config)
    -- Sample achievement data
    local achievements = {
        Recent = {
            {name = "First Steps", description = "Complete your first run", icon = "👟", completed = true, progress = 100},
            {name = "Coin Collector", description = "Collect 100 coins", icon = "💰", completed = true, progress = 100},
            {name = "Speed Demon", description = "Reach maximum speed", icon = "💨", completed = false, progress = 75}
        },
        Progress = {
            {name = "Marathon Runner", description = "Run 1000 meters total", icon = "🏃", completed = false, progress = 65},
            {name = "Obstacle Master", description = "Jump over 500 obstacles", icon = "🤸", completed = false, progress = 40},
            {name = "Color Champion", description = "Change colors 100 times", icon = "🎨", completed = false, progress = 85}
        },
        Completed = {
            {name = "First Steps", description = "Complete your first run", icon = "👟", completed = true, progress = 100},
            {name = "Coin Collector", description = "Collect 100 coins", icon = "💰", completed = true, progress = 100}
        },
        Locked = {
            {name = "Ultimate Runner", description = "???", icon = "🔒", completed = false, progress = 0},
            {name = "Secret Achievement", description = "???", icon = "🔒", completed = false, progress = 0}
        }
    }
    
    local categoryAchievements = achievements[category] or {}
    
    -- Create grid layout for achievements
    local gridContainer = Instance.new("Frame")
    gridContainer.Size = UDim2.new(1, -10, 0, 0) -- Height will be calculated
    gridContainer.Position = UDim2.new(0, 5, 0, 5)
    gridContainer.BackgroundTransparency = 1
    gridContainer.Parent = parent
    
    local achievementsPerRow = layoutProps.deviceType == "Phone" and 1 or 2
    local achievementHeight = layoutProps.deviceType == "Phone" and 100 : 120
    local rows = math.ceil(#categoryAchievements / achievementsPerRow)
    
    gridContainer.Size = UDim2.new(1, -10, 0, rows * (achievementHeight + 5) + 5)
    
    -- Create achievement cards
    for i, achievement in ipairs(categoryAchievements) do
        local row = math.floor((i - 1) / achievementsPerRow)
        local col = (i - 1) % achievementsPerRow
        
        local achievementCard = Instance.new("Frame")
        achievementCard.Size = UDim2.new(1/achievementsPerRow, -5, 0, achievementHeight)
        achievementCard.Position = UDim2.new(col/achievementsPerRow, col == 0 and 0 or 5, 0, row * (achievementHeight + 5))
        achievementCard.BackgroundColor3 = achievement.completed and Color3.fromRGB(46, 204, 113) or Color3.fromRGB(255, 255, 255)
        achievementCard.BackgroundTransparency = achievement.completed and 0.9 or 0
        achievementCard.BorderSizePixel = 1
        achievementCard.BorderColor3 = achievement.completed and Color3.fromRGB(46, 204, 113) or Color3.fromRGB(189, 195, 199)
        achievementCard.Parent = gridContainer
        
        local cardCorner = Instance.new("UICorner")
        cardCorner.CornerRadius = UDim.new(0, 8)
        cardCorner.Parent = achievementCard
        
        -- Achievement icon
        local iconLabel = Instance.new("TextLabel")
        iconLabel.Size = UDim2.new(0, 40, 0, 40)
        iconLabel.Position = UDim2.new(0, 10, 0, 10)
        iconLabel.BackgroundTransparency = 1
        iconLabel.Text = achievement.icon
        iconLabel.TextSize = config.fontSize.title
        iconLabel.Parent = achievementCard
        
        -- Achievement name
        local nameLabel = Instance.new("TextLabel")
        nameLabel.Size = UDim2.new(1, -60, 0, 25)
        nameLabel.Position = UDim2.new(0, 55, 0, 10)
        nameLabel.BackgroundTransparency = 1
        nameLabel.Text = achievement.name
        nameLabel.TextColor3 = Color3.fromRGB(44, 62, 80)
        nameLabel.TextSize = config.fontSize.medium
        nameLabel.Font = Enum.Font.SourceSansBold
        nameLabel.TextXAlignment = Enum.TextXAlignment.Left
        nameLabel.TextTruncate = Enum.TextTruncate.AtEnd
        nameLabel.Parent = achievementCard
        
        -- Achievement description
        local descLabel = Instance.new("TextLabel")
        descLabel.Size = UDim2.new(1, -60, 0, 30)
        descLabel.Position = UDim2.new(0, 55, 0, 35)
        descLabel.BackgroundTransparency = 1
        descLabel.Text = achievement.description
        descLabel.TextColor3 = Color3.fromRGB(127, 140, 141)
        descLabel.TextSize = config.fontSize.small
        descLabel.Font = Enum.Font.SourceSans
        descLabel.TextXAlignment = Enum.TextXAlignment.Left
        descLabel.TextWrapped = true
        descLabel.Parent = achievementCard
        
        -- Progress bar (if not completed and not locked)
        if not achievement.completed and achievement.progress > 0 then
            local progressBG = Instance.new("Frame")
            progressBG.Size = UDim2.new(1, -20, 0, 8)
            progressBG.Position = UDim2.new(0, 10, 1, -18)
            progressBG.BackgroundColor3 = Color3.fromRGB(189, 195, 199)
            progressBG.BorderSizePixel = 0
            progressBG.Parent = achievementCard
            
            local progressCorner = Instance.new("UICorner")
            progressCorner.CornerRadius = UDim.new(0, 4)
            progressCorner.Parent = progressBG
            
            local progressFill = Instance.new("Frame")
            progressFill.Size = UDim2.new(achievement.progress / 100, 0, 1, 0)
            progressFill.BackgroundColor3 = Color3.fromRGB(52, 152, 219)
            progressFill.BorderSizePixel = 0
            progressFill.Parent = progressBG
            
            local fillCorner = Instance.new("UICorner")
            fillCorner.CornerRadius = UDim.new(0, 4)
            fillCorner.Parent = progressFill
            
            -- Progress text
            local progressText = Instance.new("TextLabel")
            progressText.Size = UDim2.new(1, 0, 1, 0)
            progressText.BackgroundTransparency = 1
            progressText.Text = achievement.progress .. "%"
            progressText.TextColor3 = Color3.fromRGB(255, 255, 255)
            progressText.TextSize = config.fontSize.tiny
            progressText.Font = Enum.Font.SourceSansBold
            progressText.Parent = progressBG
        end
        
        -- Completed checkmark
        if achievement.completed then
            local checkmark = Instance.new("TextLabel")
            checkmark.Size = UDim2.new(0, 25, 0, 25)
            checkmark.Position = UDim2.new(1, -30, 0, 5)
            checkmark.BackgroundColor3 = Color3.fromRGB(46, 204, 113)
            checkmark.BorderSizePixel = 0
            checkmark.Text = "✓"
            checkmark.TextColor3 = Color3.fromRGB(255, 255, 255)
            checkmark.TextSize = config.fontSize.medium
            checkmark.Font = Enum.Font.SourceSansBold
            checkmark.Parent = achievementCard
            
            local checkCorner = Instance.new("UICorner")
            checkCorner.CornerRadius = UDim.new(0.5, 0)
            checkCorner.Parent = checkmark
        end
    end
    
    -- Update scroll frame content size
    parent.CanvasSize = UDim2.new(0, 0, 0, gridContainer.Size.Y.Offset + 20)
end

-- Create empty state
function MobileLeaderboardUI.createEmptyState(parent, tabType, config)
    local emptyFrame = Instance.new("Frame")
    emptyFrame.Size = UDim2.new(1, 0, 0, 150)
    emptyFrame.BackgroundTransparency = 1
    emptyFrame.Parent = parent
    
    local emptyIcon = Instance.new("TextLabel")
    emptyIcon.Size = UDim2.new(0, 60, 0, 60)
    emptyIcon.Position = UDim2.new(0.5, -30, 0, 20)
    emptyIcon.BackgroundTransparency = 1
    emptyIcon.Text = "📊"
    emptyIcon.TextSize = config.fontSize.title * 1.5
    emptyIcon.Parent = emptyFrame
    
    local emptyText = Instance.new("TextLabel")
    emptyText.Size = UDim2.new(1, -40, 0, 40)
    emptyText.Position = UDim2.new(0, 20, 0, 90)
    emptyText.BackgroundTransparency = 1
    emptyText.Text = "No " .. tabType:lower() .. " leaderboard data available.\nPlay some games to see rankings!"
    emptyText.TextColor3 = Color3.fromRGB(127, 140, 141)
    emptyText.TextSize = config.fontSize.medium
    emptyText.Font = Enum.Font.SourceSans
    emptyText.TextWrapped = true
    emptyText.Parent = emptyFrame
end

-- Refresh leaderboard data
function MobileLeaderboardUI.refreshLeaderboard(tabType)
    print("[Leaderboard] Refreshing " .. tabType .. " leaderboard...")
    
    -- Send request to server
    if RemoteEvents.RequestLeaderboard then
        RemoteEvents.RequestLeaderboard:FireServer(tabType)
    end
end

-- Update leaderboard data
function MobileLeaderboardUI.updateLeaderboardData(tabType, data)
    leaderboardState.leaderboardData[tabType] = data
    
    -- If currently viewing this tab, refresh the display
    if leaderboardState.currentTab == tabType and leaderboardState.isVisible then
        -- Would refresh the current tab display
        print("[Leaderboard] Updated " .. tabType .. " data with " .. #data .. " entries")
    end
end

-- Update player stats
function MobileLeaderboardUI.updatePlayerStats(stats)
    for key, value in pairs(stats) do
        leaderboardState.playerStats[key] = value
    end
end

-- Update achievement data
function MobileLeaderboardUI.updateAchievementData(achievements)
    leaderboardState.achievementData = achievements
end

-- Show leaderboard UI
function MobileLeaderboardUI.show()
    if not leaderboardState.isVisible then
        MobileLeaderboardUI.createLeaderboardUI()
    end
end

-- Hide leaderboard UI
function MobileLeaderboardUI.hide()
    if leaderboardGui then
        MobileOptimizationService.closeMobileModal(leaderboardGui)
        leaderboardState.isVisible = false
    end
end

-- Remote event connections
if RemoteEvents.LeaderboardDataUpdated then
    RemoteEvents.LeaderboardDataUpdated.OnClientEvent:Connect(function(tabType, data)
        MobileLeaderboardUI.updateLeaderboardData(tabType, data)
    end)
end

if RemoteEvents.PlayerStatsUpdated then
    RemoteEvents.PlayerStatsUpdated.OnClientEvent:Connect(function(stats)
        MobileLeaderboardUI.updatePlayerStats(stats)
    end)
end

if RemoteEvents.AchievementUnlocked then
    RemoteEvents.AchievementUnlocked.OnClientEvent:Connect(function(achievementData)
        -- Show achievement notification
        print("[Achievement] Unlocked: " .. achievementData.name)
    end)
end

if RemoteEvents.AchievementProgress then
    RemoteEvents.AchievementProgress.OnClientEvent:Connect(function(achievementId, progress)
        -- Update achievement progress
        print("[Achievement] Progress updated: " .. achievementId .. " - " .. progress .. "%")
    end)
end

return MobileLeaderboardUI
