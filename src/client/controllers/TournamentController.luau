-- TournamentController.luau
-- Client-side tournament UI and management

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SoundService = game:GetService("SoundService")

local RemoteEvents = require(ReplicatedStorage.Shared.modules.RemoteEvents)

local TournamentController = {}
local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- Tournament data
local tournamentData = nil
local playerPrizes = {}

-- UI elements
local tournamentGui = nil
local tournamentBoard = nil
local currentCategory = "topScore"

-- Sounds
local sounds = {
    openTournament = nil,
    switchCategory = nil,
    prizeAwarded = nil
}

function TournamentController:Init()
    print("🏆 TournamentController initializing...")
    
    self:CreateTournamentUI()
    self:SetupRemoteEvents()
    self:SetupInputHandling()
    self:LoadSounds()
    
    -- Request initial tournament data
    RemoteEvents.RequestTournamentData:FireServer()
    RemoteEvents.GetTournamentPrizes:FireServer()
    
    print("✅ TournamentController initialized!")
end

function TournamentController:CreateTournamentUI()
    -- Create main tournament GUI
    tournamentGui = Instance.new("ScreenGui")
    tournamentGui.Name = "TournamentGui"
    tournamentGui.ResetOnSpawn = false
    tournamentGui.Enabled = false
    tournamentGui.Parent = playerGui
    
    -- Create tournament board
    self:CreateTournamentBoard()
end

function TournamentController:CreateTournamentBoard()
    tournamentBoard = Instance.new("Frame")
    tournamentBoard.Name = "TournamentBoard"
    tournamentBoard.Size = UDim2.new(0, 800, 0, 600)
    tournamentBoard.Position = UDim2.new(0.5, -400, 0.5, -300)
    tournamentBoard.BackgroundColor3 = Color3.new(0.1, 0.1, 0.2)
    tournamentBoard.BorderSizePixel = 0
    tournamentBoard.Parent = tournamentGui
    
    local boardCorner = Instance.new("UICorner")
    boardCorner.CornerRadius = UDim.new(0, 20)
    boardCorner.Parent = tournamentBoard
    
    local boardStroke = Instance.new("UIStroke")
    boardStroke.Color = Color3.new(1, 0.8, 0)
    boardStroke.Thickness = 3
    boardStroke.Parent = tournamentBoard
    
    -- Tournament header
    local header = Instance.new("Frame")
    header.Name = "Header"
    header.Size = UDim2.new(1, 0, 0, 80)
    header.Position = UDim2.new(0, 0, 0, 0)
    header.BackgroundColor3 = Color3.new(0.15, 0.1, 0.3)
    header.BorderSizePixel = 0
    header.Parent = tournamentBoard
    
    local headerCorner = Instance.new("UICorner")
    headerCorner.CornerRadius = UDim.new(0, 20)
    headerCorner.Parent = header
    
    -- Tournament title
    local title = Instance.new("TextLabel")
    title.Name = "Title"
    title.Size = UDim2.new(0, 400, 1, 0)
    title.Position = UDim2.new(0, 20, 0, 0)
    title.BackgroundTransparency = 1
    title.Text = "🏆 WEEKLY TOURNAMENT"
    title.TextColor3 = Color3.new(1, 0.9, 0.2)
    title.TextScaled = true
    title.Font = Enum.Font.SourceSansBold
    title.TextStrokeTransparency = 0
    title.TextStrokeColor3 = Color3.new(0, 0, 0)
    title.Parent = header
    
    -- Time remaining
    local timeLabel = Instance.new("TextLabel")
    timeLabel.Name = "TimeLabel"
    timeLabel.Size = UDim2.new(0, 300, 1, 0)
    timeLabel.Position = UDim2.new(1, -320, 0, 0)
    timeLabel.BackgroundTransparency = 1
    timeLabel.Text = "⏰ Resets in: 6d 23h 45m"
    timeLabel.TextColor3 = Color3.new(0.8, 0.8, 0.8)
    timeLabel.TextScaled = true
    timeLabel.Font = Enum.Font.SourceSans
    timeLabel.Parent = header
    
    -- Close button
    local closeButton = Instance.new("TextButton")
    closeButton.Name = "CloseButton"
    closeButton.Size = UDim2.new(0, 60, 0, 60)
    closeButton.Position = UDim2.new(1, -70, 0, 10)
    closeButton.BackgroundColor3 = Color3.new(0.8, 0.2, 0.2)
    closeButton.BorderSizePixel = 0
    closeButton.Text = "✕"
    closeButton.TextColor3 = Color3.new(1, 1, 1)
    closeButton.TextScaled = true
    closeButton.Font = Enum.Font.SourceSansBold
    closeButton.Parent = header
    
    local closeCorner = Instance.new("UICorner")
    closeCorner.CornerRadius = UDim.new(0, 10)
    closeCorner.Parent = closeButton
    
    closeButton.MouseButton1Click:Connect(function()
        self:CloseTournament()
    end)
    
    -- Category tabs
    self:CreateCategoryTabs()
    
    -- Leaderboard content
    self:CreateLeaderboardContent()
    
    -- Player stats panel
    self:CreatePlayerStatsPanel()
    
    -- Prizes panel
    self:CreatePrizesPanel()
end

function TournamentController:CreateCategoryTabs()
    local tabFrame = Instance.new("Frame")
    tabFrame.Name = "CategoryTabs"
    tabFrame.Size = UDim2.new(1, -40, 0, 50)
    tabFrame.Position = UDim2.new(0, 20, 0, 90)
    tabFrame.BackgroundTransparency = 1
    tabFrame.Parent = tournamentBoard
    
    local categories = {
        {id = "topScore", name = "🎯 Top Score", color = Color3.new(1, 0.6, 0.2)},
        {id = "mostRuns", name = "🏃 Most Runs", color = Color3.new(0.2, 0.8, 0.4)},
        {id = "longestStreak", name = "⚡ Perfect Streak", color = Color3.new(0.6, 0.2, 1)}
    }
    
    for i, category in ipairs(categories) do
        local tab = Instance.new("TextButton")
        tab.Name = category.id .. "Tab"
        tab.Size = UDim2.new(0, 240, 1, 0)
        tab.Position = UDim2.new(0, (i-1) * 250, 0, 0)
        tab.BackgroundColor3 = category.id == currentCategory and category.color or Color3.new(0.3, 0.3, 0.4)
        tab.BorderSizePixel = 0
        tab.Text = category.name
        tab.TextColor3 = Color3.new(1, 1, 1)
        tab.TextScaled = true
        tab.Font = Enum.Font.SourceSansBold
        tab.Parent = tabFrame
        
        local tabCorner = Instance.new("UICorner")
        tabCorner.CornerRadius = UDim.new(0, 10)
        tabCorner.Parent = tab
        
        tab.MouseButton1Click:Connect(function()
            self:SwitchCategory(category.id)
        end)
        
        -- Store reference
        tab.categoryData = category
    end
end

function TournamentController:CreateLeaderboardContent()
    local contentFrame = Instance.new("Frame")
    contentFrame.Name = "LeaderboardContent"
    contentFrame.Size = UDim2.new(0.6, -30, 1, -200)
    contentFrame.Position = UDim2.new(0, 20, 0, 150)
    contentFrame.BackgroundColor3 = Color3.new(0.05, 0.05, 0.1)
    contentFrame.BorderSizePixel = 0
    contentFrame.Parent = tournamentBoard
    
    local contentCorner = Instance.new("UICorner")
    contentCorner.CornerRadius = UDim.new(0, 15)
    contentCorner.Parent = contentFrame
    
    -- Leaderboard header
    local leaderboardHeader = Instance.new("Frame")
    leaderboardHeader.Name = "LeaderboardHeader"
    leaderboardHeader.Size = UDim2.new(1, 0, 0, 40)
    leaderboardHeader.Position = UDim2.new(0, 0, 0, 0)
    leaderboardHeader.BackgroundColor3 = Color3.new(0.1, 0.1, 0.2)
    leaderboardHeader.BorderSizePixel = 0
    leaderboardHeader.Parent = contentFrame
    
    local headerCorner = Instance.new("UICorner")
    headerCorner.CornerRadius = UDim.new(0, 15)
    headerCorner.Parent = leaderboardHeader
    
    -- Header labels
    local rankLabel = Instance.new("TextLabel")
    rankLabel.Size = UDim2.new(0, 60, 1, 0)
    rankLabel.Position = UDim2.new(0, 10, 0, 0)
    rankLabel.BackgroundTransparency = 1
    rankLabel.Text = "Rank"
    rankLabel.TextColor3 = Color3.new(0.8, 0.8, 0.8)
    rankLabel.TextScaled = true
    rankLabel.Font = Enum.Font.SourceSansBold
    rankLabel.Parent = leaderboardHeader
    
    local playerLabel = Instance.new("TextLabel")
    playerLabel.Size = UDim2.new(0, 200, 1, 0)
    playerLabel.Position = UDim2.new(0, 80, 0, 0)
    playerLabel.BackgroundTransparency = 1
    playerLabel.Text = "Player"
    playerLabel.TextColor3 = Color3.new(0.8, 0.8, 0.8)
    playerLabel.TextScaled = true
    playerLabel.Font = Enum.Font.SourceSansBold
    playerLabel.Parent = leaderboardHeader
    
    local scoreLabel = Instance.new("TextLabel")
    scoreLabel.Size = UDim2.new(0, 100, 1, 0)
    scoreLabel.Position = UDim2.new(1, -110, 0, 0)
    scoreLabel.BackgroundTransparency = 1
    scoreLabel.Text = "Score"
    scoreLabel.TextColor3 = Color3.new(0.8, 0.8, 0.8)
    scoreLabel.TextScaled = true
    scoreLabel.Font = Enum.Font.SourceSansBold
    scoreLabel.Parent = leaderboardHeader
    
    -- Leaderboard scroll frame
    local scrollFrame = Instance.new("ScrollingFrame")
    scrollFrame.Name = "LeaderboardScroll"
    scrollFrame.Size = UDim2.new(1, -20, 1, -50)
    scrollFrame.Position = UDim2.new(0, 10, 0, 40)
    scrollFrame.BackgroundTransparency = 1
    scrollFrame.BorderSizePixel = 0
    scrollFrame.ScrollBarThickness = 8
    scrollFrame.Parent = contentFrame
    
    local listLayout = Instance.new("UIListLayout")
    listLayout.SortOrder = Enum.SortOrder.LayoutOrder
    listLayout.Padding = UDim.new(0, 2)
    listLayout.Parent = scrollFrame
    
    -- Store reference
    self.leaderboardScroll = scrollFrame
end

function TournamentController:CreatePlayerStatsPanel()
    local statsFrame = Instance.new("Frame")
    statsFrame.Name = "PlayerStats"
    statsFrame.Size = UDim2.new(0.4, -30, 0, 200)
    statsFrame.Position = UDim2.new(0.6, 10, 0, 150)
    statsFrame.BackgroundColor3 = Color3.new(0.05, 0.05, 0.1)
    statsFrame.BorderSizePixel = 0
    statsFrame.Parent = tournamentBoard
    
    local statsCorner = Instance.new("UICorner")
    statsCorner.CornerRadius = UDim.new(0, 15)
    statsCorner.Parent = statsFrame
    
    -- Stats header
    local statsHeader = Instance.new("TextLabel")
    statsHeader.Name = "StatsHeader"
    statsHeader.Size = UDim2.new(1, -20, 0, 30)
    statsHeader.Position = UDim2.new(0, 10, 0, 10)
    statsHeader.BackgroundTransparency = 1
    statsHeader.Text = "📊 Your Week Stats"
    statsHeader.TextColor3 = Color3.new(0.8, 1, 0.8)
    statsHeader.TextScaled = true
    statsHeader.Font = Enum.Font.SourceSansBold
    statsHeader.Parent = statsFrame
    
    -- Stats content
    local statsContent = Instance.new("TextLabel")
    statsContent.Name = "StatsContent"
    statsContent.Size = UDim2.new(1, -20, 1, -50)
    statsContent.Position = UDim2.new(0, 10, 0, 40)
    statsContent.BackgroundTransparency = 1
    statsContent.Text = "Top Score: 0\nTotal Runs: 0\nBest Streak: 0\nRanking: Unranked"
    statsContent.TextColor3 = Color3.new(0.9, 0.9, 0.9)
    statsContent.TextScaled = true
    statsContent.Font = Enum.Font.SourceSans
    statsContent.TextYAlignment = Enum.TextYAlignment.Top
    statsContent.Parent = statsFrame
    
    -- Store reference
    self.statsContent = statsContent
end

function TournamentController:CreatePrizesPanel()
    local prizesFrame = Instance.new("Frame")
    prizesFrame.Name = "PrizesPanel"
    prizesFrame.Size = UDim2.new(0.4, -30, 0, 240)
    prizesFrame.Position = UDim2.new(0.6, 10, 0, 360)
    prizesFrame.BackgroundColor3 = Color3.new(0.05, 0.05, 0.1)
    prizesFrame.BorderSizePixel = 0
    prizesFrame.Parent = tournamentBoard
    
    local prizesCorner = Instance.new("UICorner")
    prizesCorner.CornerRadius = UDim.new(0, 15)
    prizesCorner.Parent = prizesFrame
    
    -- Prizes header
    local prizesHeader = Instance.new("TextLabel")
    prizesHeader.Name = "PrizesHeader"
    prizesHeader.Size = UDim2.new(1, -20, 0, 30)
    prizesHeader.Position = UDim2.new(0, 10, 0, 10)
    prizesHeader.BackgroundTransparency = 1
    prizesHeader.Text = "🏆 Weekly Prizes"
    prizesHeader.TextColor3 = Color3.new(1, 0.9, 0.2)
    prizesHeader.TextScaled = true
    prizesHeader.Font = Enum.Font.SourceSansBold
    prizesHeader.Parent = prizesFrame
    
    -- Prizes scroll frame
    local prizesScroll = Instance.new("ScrollingFrame")
    prizesScroll.Name = "PrizesScroll"
    prizesScroll.Size = UDim2.new(1, -20, 1, -50)
    prizesScroll.Position = UDim2.new(0, 10, 0, 40)
    prizesScroll.BackgroundTransparency = 1
    prizesScroll.BorderSizePixel = 0
    prizesScroll.ScrollBarThickness = 6
    prizesScroll.Parent = prizesFrame
    
    local prizesLayout = Instance.new("UIListLayout")
    prizesLayout.SortOrder = Enum.SortOrder.LayoutOrder
    prizesLayout.Padding = UDim.new(0, 5)
    prizesLayout.Parent = prizesScroll
    
    -- Store reference
    self.prizesScroll = prizesScroll
end

function TournamentController:SwitchCategory(categoryId)
    currentCategory = categoryId
    
    -- Update tab appearances
    local tabFrame = tournamentBoard:FindFirstChild("CategoryTabs")
    if tabFrame then
        for _, tab in pairs(tabFrame:GetChildren()) do
            if tab:IsA("TextButton") and tab.categoryData then
                if tab.categoryData.id == categoryId then
                    tab.BackgroundColor3 = tab.categoryData.color
                else
                    tab.BackgroundColor3 = Color3.new(0.3, 0.3, 0.4)
                end
            end
        end
    end
    
    -- Update leaderboard display
    self:UpdateLeaderboardDisplay()
    
    -- Update prizes display
    self:UpdatePrizesDisplay()
    
    -- Play sound
    if sounds.switchCategory then
        sounds.switchCategory:Play()
    end
end

function TournamentController:UpdateLeaderboardDisplay()
    if not tournamentData or not self.leaderboardScroll then return end
    
    -- Clear existing entries
    for _, child in pairs(self.leaderboardScroll:GetChildren()) do
        if child:IsA("Frame") then
            child:Destroy()
        end
    end
    
    local leaderboard = tournamentData.leaderboards[currentCategory] or {}
    
    for i, entry in ipairs(leaderboard) do
        local entryFrame = Instance.new("Frame")
        entryFrame.Name = "Entry" .. i
        entryFrame.Size = UDim2.new(1, -10, 0, 35)
        entryFrame.BackgroundColor3 = i <= 3 and Color3.new(0.2, 0.2, 0.3) or Color3.new(0.1, 0.1, 0.15)
        entryFrame.BorderSizePixel = 0
        entryFrame.LayoutOrder = i
        entryFrame.Parent = self.leaderboardScroll
        
        local entryCorner = Instance.new("UICorner")
        entryCorner.CornerRadius = UDim.new(0, 8)
        entryCorner.Parent = entryFrame
        
        -- Rank with medal for top 3
        local rankText = tostring(i)
        if i == 1 then rankText = "🥇"
        elseif i == 2 then rankText = "🥈"
        elseif i == 3 then rankText = "🥉"
        end
        
        local rankLabel = Instance.new("TextLabel")
        rankLabel.Size = UDim2.new(0, 50, 1, 0)
        rankLabel.Position = UDim2.new(0, 5, 0, 0)
        rankLabel.BackgroundTransparency = 1
        rankLabel.Text = rankText
        rankLabel.TextColor3 = Color3.new(1, 1, 1)
        rankLabel.TextScaled = true
        rankLabel.Font = Enum.Font.SourceSansBold
        rankLabel.Parent = entryFrame
        
        -- Player name
        local nameLabel = Instance.new("TextLabel")
        nameLabel.Size = UDim2.new(0, 180, 1, 0)
        nameLabel.Position = UDim2.new(0, 60, 0, 0)
        nameLabel.BackgroundTransparency = 1
        nameLabel.Text = entry.displayName
        nameLabel.TextColor3 = entry.isPlayer and Color3.new(0.2, 1, 0.2) or Color3.new(0.9, 0.9, 0.9)
        nameLabel.TextScaled = true
        nameLabel.Font = entry.isPlayer and Enum.Font.SourceSansBold or Enum.Font.SourceSans
        nameLabel.TextXAlignment = Enum.TextXAlignment.Left
        nameLabel.Parent = entryFrame
        
        -- Score/value
        local valueLabel = Instance.new("TextLabel")
        valueLabel.Size = UDim2.new(0, 80, 1, 0)
        valueLabel.Position = UDim2.new(1, -85, 0, 0)
        valueLabel.BackgroundTransparency = 1
        valueLabel.Text = self:FormatValue(currentCategory, entry.value)
        valueLabel.TextColor3 = Color3.new(1, 1, 1)
        valueLabel.TextScaled = true
        valueLabel.Font = Enum.Font.SourceSans
        valueLabel.Parent = entryFrame
    end
    
    -- Update canvas size
    self.leaderboardScroll.CanvasSize = UDim2.new(0, 0, 0, #leaderboard * 37)
end

function TournamentController:UpdatePrizesDisplay()
    if not tournamentData or not self.prizesScroll then return end
    
    -- Clear existing entries
    for _, child in pairs(self.prizesScroll:GetChildren()) do
        if child:IsA("Frame") then
            child:Destroy()
        end
    end
    
    local prizes = tournamentData.prizes[currentCategory] or {}
    
    for rank, prize in ipairs(prizes) do
        local prizeFrame = Instance.new("Frame")
        prizeFrame.Name = "Prize" .. rank
        prizeFrame.Size = UDim2.new(1, -10, 0, 35)
        prizeFrame.BackgroundColor3 = Color3.new(0.1, 0.1, 0.15)
        prizeFrame.BorderSizePixel = 0
        prizeFrame.LayoutOrder = rank
        prizeFrame.Parent = self.prizesScroll
        
        local prizeCorner = Instance.new("UICorner")
        prizeCorner.CornerRadius = UDim.new(0, 8)
        prizeCorner.Parent = prizeFrame
        
        -- Rank indicator
        local rankLabel = Instance.new("TextLabel")
        rankLabel.Size = UDim2.new(0, 30, 1, 0)
        rankLabel.Position = UDim2.new(0, 5, 0, 0)
        rankLabel.BackgroundTransparency = 1
        rankLabel.Text = "#" .. rank
        rankLabel.TextColor3 = Color3.new(1, 0.8, 0.2)
        rankLabel.TextScaled = true
        rankLabel.Font = Enum.Font.SourceSansBold
        rankLabel.Parent = prizeFrame
        
        -- Prize name
        local nameLabel = Instance.new("TextLabel")
        nameLabel.Size = UDim2.new(1, -40, 1, 0)
        nameLabel.Position = UDim2.new(0, 35, 0, 0)
        nameLabel.BackgroundTransparency = 1
        nameLabel.Text = prize.name
        nameLabel.TextColor3 = prize.color or Color3.new(0.9, 0.9, 0.9)
        nameLabel.TextScaled = true
        nameLabel.Font = Enum.Font.SourceSans
        nameLabel.TextXAlignment = Enum.TextXAlignment.Left
        nameLabel.Parent = prizeFrame
    end
    
    -- Update canvas size
    self.prizesScroll.CanvasSize = UDim2.new(0, 0, 0, #prizes * 40)
end

function TournamentController:UpdatePlayerStats()
    if not tournamentData or not self.statsContent then return end
    
    local playerStats = tournamentData.playerStats or {}
    local rankings = tournamentData.rankings or {}
    
    local topScore = playerStats.topScore or 0
    local totalRuns = playerStats.totalRuns or 0
    local longestStreak = playerStats.longestStreak or 0
    
    -- Get ranking for current category
    local ranking = rankings[currentCategory]
    local rankText = "Unranked"
    if ranking and ranking.rank then
        rankText = "#" .. ranking.rank .. " of " .. ranking.total
    end
    
    self.statsContent.Text = string.format(
        "Top Score: %d\nTotal Runs: %d\nBest Streak: %d\nRanking: %s",
        topScore, totalRuns, longestStreak, rankText
    )
end

function TournamentController:UpdateTimeRemaining()
    if not tournamentData then return end
    
    local timeLabel = tournamentBoard:FindFirstChild("Header"):FindFirstChild("TimeLabel")
    if not timeLabel then return end
    
    local timeRemaining = tournamentData.timeUntilReset or 0
    local days = math.floor(timeRemaining / 86400)
    local hours = math.floor((timeRemaining % 86400) / 3600)
    local minutes = math.floor((timeRemaining % 3600) / 60)
    
    timeLabel.Text = string.format("⏰ Resets in: %dd %dh %dm", days, hours, minutes)
end

function TournamentController:FormatValue(category, value)
    if category == "topScore" then
        return tostring(value)
    elseif category == "mostRuns" then
        return tostring(value) .. " runs"
    elseif category == "longestStreak" then
        return tostring(value) .. " perfect"
    end
    return tostring(value)
end

function TournamentController:OpenTournament()
    if tournamentGui then
        tournamentGui.Enabled = true
        
        -- Animate board entrance
        tournamentBoard.Position = UDim2.new(0.5, -400, 1.5, 0)
        local showTween = TweenService:Create(
            tournamentBoard,
            TweenInfo.new(0.5, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
            {Position = UDim2.new(0.5, -400, 0.5, -300)}
        )
        showTween:Play()
        
        -- Request latest data
        RemoteEvents.RequestTournamentData:FireServer()
        
        -- Play sound
        if sounds.openTournament then
            sounds.openTournament:Play()
        end
    end
end

function TournamentController:CloseTournament()
    if tournamentGui then
        -- Animate board exit
        local hideTween = TweenService:Create(
            tournamentBoard,
            TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
            {Position = UDim2.new(0.5, -400, 1.5, 0)}
        )
        hideTween:Play()
        
        hideTween.Completed:Connect(function()
            tournamentGui.Enabled = false
        end)
    end
end

function TournamentController:ShowPrizeAwarded(prizeData)
    -- Create prize notification
    local notification = Instance.new("Frame")
    notification.Name = "PrizeNotification"
    notification.Size = UDim2.new(0, 400, 0, 120)
    notification.Position = UDim2.new(0.5, -200, 0, -150)
    notification.BackgroundColor3 = Color3.new(1, 0.8, 0.2)
    notification.BorderSizePixel = 0
    notification.Parent = playerGui
    
    local notifCorner = Instance.new("UICorner")
    notifCorner.CornerRadius = UDim.new(0, 15)
    notifCorner.Parent = notification
    
    local notifStroke = Instance.new("UIStroke")
    notifStroke.Color = Color3.new(1, 1, 1)
    notifStroke.Thickness = 3
    notifStroke.Parent = notification
    
    -- Prize icon and text
    local prizeText = Instance.new("TextLabel")
    prizeText.Size = UDim2.new(1, -20, 1, 0)
    prizeText.Position = UDim2.new(0, 10, 0, 0)
    prizeText.BackgroundTransparency = 1
    prizeText.Text = "🏆 TOURNAMENT PRIZE EARNED!\n" .. prizeData.prize.name .. "\nRank #" .. prizeData.rank .. " in " .. prizeData.category
    prizeText.TextColor3 = Color3.new(0, 0, 0)
    prizeText.TextScaled = true
    prizeText.Font = Enum.Font.SourceSansBold
    prizeText.Parent = notification
    
    -- Animate notification
    local showTween = TweenService:Create(
        notification,
        TweenInfo.new(0.5, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
        {Position = UDim2.new(0.5, -200, 0, 50)}
    )
    showTween:Play()
    
    -- Play prize sound
    if sounds.prizeAwarded then
        sounds.prizeAwarded:Play()
    end
    
    -- Auto-hide after 5 seconds
    spawn(function()
        wait(5)
        local hideTween = TweenService:Create(
            notification,
            TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
            {Position = UDim2.new(0.5, -200, 0, -150)}
        )
        hideTween:Play()
        hideTween.Completed:Connect(function()
            notification:Destroy()
        end)
    end)
end

function TournamentController:SetupInputHandling()
    -- Tournament hotkey (T key)
    UserInputService.InputBegan:Connect(function(input, gameProcessed)
        if gameProcessed then return end
        
        if input.KeyCode == Enum.KeyCode.T then
            if tournamentGui.Enabled then
                self:CloseTournament()
            else
                self:OpenTournament()
            end
        end
    end)
end

function TournamentController:SetupRemoteEvents()
    -- Tournament data updates
    RemoteEvents.TournamentDataUpdated.OnClientEvent:Connect(function(data)
        tournamentData = data
        self:UpdateLeaderboardDisplay()
        self:UpdatePlayerStats()
        self:UpdateTimeRemaining()
        self:UpdatePrizesDisplay()
    end)
    
    -- Leaderboard updates
    RemoteEvents.TournamentLeaderboardUpdated.OnClientEvent:Connect(function(data)
        if tournamentData then
            tournamentData.leaderboards[data.category] = data.leaderboard
            tournamentData.rankings[data.category] = data.playerRanking
            
            if currentCategory == data.category then
                self:UpdateLeaderboardDisplay()
                self:UpdatePlayerStats()
            end
        end
    end)
    
    -- Prize awarded
    RemoteEvents.TournamentPrizeAwarded.OnClientEvent:Connect(function(prizeData)
        self:ShowPrizeAwarded(prizeData)
    end)
    
    -- Week reset
    RemoteEvents.TournamentWeekReset.OnClientEvent:Connect(function(data)
        -- Show week reset notification
        print("🏆 Tournament week reset! New week: " .. data.newWeek)
    end)
    
    -- Player prizes updated
    RemoteEvents.TournamentPrizesUpdated.OnClientEvent:Connect(function(prizes)
        playerPrizes = prizes
    end)
end

function TournamentController:LoadSounds()
    sounds.openTournament = Instance.new("Sound")
    sounds.openTournament.SoundId = "rbxasset://sounds/electronicpingshort.wav"
    sounds.openTournament.Volume = 0.6
    sounds.openTournament.Parent = SoundService
    
    sounds.switchCategory = Instance.new("Sound")
    sounds.switchCategory.SoundId = "rbxasset://sounds/button.wav"
    sounds.switchCategory.Volume = 0.4
    sounds.switchCategory.Parent = SoundService
    
    sounds.prizeAwarded = Instance.new("Sound")
    sounds.prizeAwarded.SoundId = "rbxasset://sounds/action_get_up.mp3"
    sounds.prizeAwarded.Volume = 0.8
    sounds.prizeAwarded.Parent = SoundService
end

return TournamentController
