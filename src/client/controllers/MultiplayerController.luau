-- MultiplayerController.luau
-- Client-side controller for multiplayer queue system and game mode selection

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SoundService = game:GetService("SoundService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local RemoteEvents = require(ReplicatedStorage.Shared.modules.RemoteEvents)

local MultiplayerController = {}

-- UI Elements
local gameSelectionGui = nil
local queueGui = nil
local multiplayerLeaderboardGui = nil
local currentQueueData = {}

-- Queue state
local isInQueue = false
local queuePosition = 0
local totalInQueue = 0

function MultiplayerController:CreateGameSelectionUI()
    -- Create main selection GUI
    gameSelectionGui = Instance.new("ScreenGui")
    gameSelectionGui.Name = "GameModeSelection"
    gameSelectionGui.ResetOnSpawn = false
    gameSelectionGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    gameSelectionGui.Parent = playerGui
    
    -- Main frame
    local mainFrame = Instance.new("Frame")
    mainFrame.Name = "SelectionFrame"
    mainFrame.Size = UDim2.new(0, 400, 0, 300)
    mainFrame.Position = UDim2.new(0.5, -200, 0.5, -150)
    mainFrame.BackgroundColor3 = Color3.new(0.1, 0.1, 0.15)
    mainFrame.BorderSizePixel = 0
    mainFrame.Parent = gameSelectionGui
    
    -- Add corner rounding
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 12)
    corner.Parent = mainFrame
    
    -- Title
    local title = Instance.new("TextLabel")
    title.Name = "Title"
    title.Size = UDim2.new(1, 0, 0, 60)
    title.Position = UDim2.new(0, 0, 0, 0)
    title.BackgroundTransparency = 1
    title.Text = "🎮 SELECT GAME MODE"
    title.TextColor3 = Color3.new(1, 1, 1)
    title.TextScaled = true
    title.Font = Enum.Font.SourceSansBold
    title.Parent = mainFrame
    
    -- Solo Game Button
    local soloButton = Instance.new("TextButton")
    soloButton.Name = "SoloButton"
    soloButton.Size = UDim2.new(0, 160, 0, 80)
    soloButton.Position = UDim2.new(0, 20, 0, 80)
    soloButton.BackgroundColor3 = Color3.fromRGB(75, 150, 255)
    soloButton.BorderSizePixel = 0
    soloButton.Text = "🏃 SOLO RUN\n\nRun by yourself"
    soloButton.TextColor3 = Color3.new(1, 1, 1)
    soloButton.TextScaled = true
    soloButton.Font = Enum.Font.SourceSansBold
    soloButton.Parent = mainFrame
    
    local soloCorner = Instance.new("UICorner")
    soloCorner.CornerRadius = UDim.new(0, 8)
    soloCorner.Parent = soloButton
    
    -- Multiplayer Button
    local multiButton = Instance.new("TextButton")
    multiButton.Name = "MultiplayerButton"
    multiButton.Size = UDim2.new(0, 160, 0, 80)
    multiButton.Position = UDim2.new(0, 220, 0, 80)
    multiButton.BackgroundColor3 = Color3.fromRGB(255, 150, 75)
    multiButton.BorderSizePixel = 0
    multiButton.Text = "👥 GROUP RUN\n\n+25% Bonus XP!"
    multiButton.TextColor3 = Color3.new(1, 1, 1)
    multiButton.TextScaled = true
    multiButton.Font = Enum.Font.SourceSansBold
    multiButton.Parent = mainFrame
    
    local multiCorner = Instance.new("UICorner")
    multiCorner.CornerRadius = UDim.new(0, 8)
    multiCorner.Parent = multiButton
    
    -- Close Button
    local closeButton = Instance.new("TextButton")
    closeButton.Name = "CloseButton"
    closeButton.Size = UDim2.new(0, 360, 0, 40)
    closeButton.Position = UDim2.new(0, 20, 0, 200)
    closeButton.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
    closeButton.BorderSizePixel = 0
    closeButton.Text = "❌ CANCEL"
    closeButton.TextColor3 = Color3.new(1, 1, 1)
    closeButton.TextScaled = true
    closeButton.Font = Enum.Font.SourceSans
    closeButton.Parent = mainFrame
    
    local closeCorner = Instance.new("UICorner")
    closeCorner.CornerRadius = UDim.new(0, 8)
    closeCorner.Parent = closeButton
    
    -- Button animations and connections
    self:SetupButtonAnimations(soloButton)
    self:SetupButtonAnimations(multiButton)
    self:SetupButtonAnimations(closeButton)
    
    -- Connect button events
    soloButton.MouseButton1Click:Connect(function()
        self:StartSoloGame()
    end)
    
    multiButton.MouseButton1Click:Connect(function()
        self:JoinMultiplayerQueue()
    end)
    
    closeButton.MouseButton1Click:Connect(function()
        self:HideGameSelection()
    end)
    
    -- Start hidden
    gameSelectionGui.Enabled = false
end

function MultiplayerController:CreateQueueUI()
    -- Create queue GUI
    queueGui = Instance.new("ScreenGui")
    queueGui.Name = "MultiplayerQueue"
    queueGui.ResetOnSpawn = false
    queueGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    queueGui.Parent = playerGui
    
    -- Main queue frame
    local queueFrame = Instance.new("Frame")
    queueFrame.Name = "QueueFrame"
    queueFrame.Size = UDim2.new(0, 350, 0, 250)
    queueFrame.Position = UDim2.new(0.5, -175, 0.5, -125)
    queueFrame.BackgroundColor3 = Color3.new(0.1, 0.1, 0.15)
    queueFrame.BorderSizePixel = 0
    queueFrame.Parent = queueGui
    
    local queueCorner = Instance.new("UICorner")
    queueCorner.CornerRadius = UDim.new(0, 12)
    queueCorner.Parent = queueFrame
    
    -- Queue title
    local queueTitle = Instance.new("TextLabel")
    queueTitle.Name = "QueueTitle"
    queueTitle.Size = UDim2.new(1, 0, 0, 50)
    queueTitle.BackgroundTransparency = 1
    queueTitle.Text = "🎮 MULTIPLAYER QUEUE"
    queueTitle.TextColor3 = Color3.new(1, 1, 1)
    queueTitle.TextScaled = true
    queueTitle.Font = Enum.Font.SourceSansBold
    queueTitle.Parent = queueFrame
    
    -- Queue status
    local queueStatus = Instance.new("TextLabel")
    queueStatus.Name = "QueueStatus"
    queueStatus.Size = UDim2.new(1, -20, 0, 40)
    queueStatus.Position = UDim2.new(0, 10, 0, 60)
    queueStatus.BackgroundTransparency = 1
    queueStatus.Text = "Waiting for players..."
    queueStatus.TextColor3 = Color3.fromRGB(255, 200, 100)
    queueStatus.TextScaled = true
    queueStatus.Font = Enum.Font.SourceSans
    queueStatus.Parent = queueFrame
    
    -- Player list
    local playerList = Instance.new("ScrollingFrame")
    playerList.Name = "PlayerList"
    playerList.Size = UDim2.new(1, -20, 0, 100)
    playerList.Position = UDim2.new(0, 10, 0, 110)
    playerList.BackgroundColor3 = Color3.new(0.05, 0.05, 0.1)
    playerList.BorderSizePixel = 0
    playerList.ScrollBarThickness = 8
    playerList.Parent = queueFrame
    
    local listCorner = Instance.new("UICorner")
    listCorner.CornerRadius = UDim.new(0, 6)
    listCorner.Parent = playerList
    
    local listLayout = Instance.new("UIListLayout")
    listLayout.SortOrder = Enum.SortOrder.LayoutOrder
    listLayout.Padding = UDim.new(0, 2)
    listLayout.Parent = playerList
    
    -- Leave queue button
    local leaveButton = Instance.new("TextButton")
    leaveButton.Name = "LeaveButton"
    leaveButton.Size = UDim2.new(1, -20, 0, 30)
    leaveButton.Position = UDim2.new(0, 10, 1, -40)
    leaveButton.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
    leaveButton.BorderSizePixel = 0
    leaveButton.Text = "❌ LEAVE QUEUE"
    leaveButton.TextColor3 = Color3.new(1, 1, 1)
    leaveButton.TextScaled = true
    leaveButton.Font = Enum.Font.SourceSans
    leaveButton.Parent = queueFrame
    
    local leaveCorner = Instance.new("UICorner")
    leaveCorner.CornerRadius = UDim.new(0, 6)
    leaveCorner.Parent = leaveButton
    
    self:SetupButtonAnimations(leaveButton)
    
    leaveButton.MouseButton1Click:Connect(function()
        self:LeaveQueue()
    end)
    
    -- Start hidden
    queueGui.Enabled = false
end

function MultiplayerController:CreateMultiplayerLeaderboard()
    -- Create multiplayer leaderboard GUI
    multiplayerLeaderboardGui = Instance.new("ScreenGui")
    multiplayerLeaderboardGui.Name = "MultiplayerLeaderboard"
    multiplayerLeaderboardGui.ResetOnSpawn = false
    multiplayerLeaderboardGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    multiplayerLeaderboardGui.Parent = playerGui
    
    -- Leaderboard frame
    local leaderboardFrame = Instance.new("Frame")
    leaderboardFrame.Name = "LeaderboardFrame"
    leaderboardFrame.Size = UDim2.new(0, 280, 0, 350)
    leaderboardFrame.Position = UDim2.new(1, -300, 0, 20)
    leaderboardFrame.BackgroundColor3 = Color3.new(0.1, 0.1, 0.15)
    leaderboardFrame.BorderSizePixel = 0
    leaderboardFrame.Parent = multiplayerLeaderboardGui
    
    local leaderboardCorner = Instance.new("UICorner")
    leaderboardCorner.CornerRadius = UDim.new(0, 8)
    leaderboardCorner.Parent = leaderboardFrame
    
    -- Title
    local leaderboardTitle = Instance.new("TextLabel")
    leaderboardTitle.Name = "Title"
    leaderboardTitle.Size = UDim2.new(1, 0, 0, 40)
    leaderboardTitle.BackgroundTransparency = 1
    leaderboardTitle.Text = "🏆 LIVE RANKINGS"
    leaderboardTitle.TextColor3 = Color3.new(1, 1, 1)
    leaderboardTitle.TextScaled = true
    leaderboardTitle.Font = Enum.Font.SourceSansBold
    leaderboardTitle.Parent = leaderboardFrame
    
    -- Player rankings container
    local rankingsContainer = Instance.new("ScrollingFrame")
    rankingsContainer.Name = "RankingsContainer"
    rankingsContainer.Size = UDim2.new(1, -10, 1, -50)
    rankingsContainer.Position = UDim2.new(0, 5, 0, 45)
    rankingsContainer.BackgroundTransparency = 1
    rankingsContainer.BorderSizePixel = 0
    rankingsContainer.ScrollBarThickness = 6
    rankingsContainer.Parent = leaderboardFrame
    
    local rankingsLayout = Instance.new("UIListLayout")
    rankingsLayout.SortOrder = Enum.SortOrder.LayoutOrder
    rankingsLayout.Padding = UDim.new(0, 2)
    rankingsLayout.Parent = rankingsContainer
    
    -- Start hidden
    multiplayerLeaderboardGui.Enabled = false
end

function MultiplayerController:SetupButtonAnimations(button)
    -- Hover effects
    button.MouseEnter:Connect(function()
        local hoverTween = TweenService:Create(
            button,
            TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
            {Size = UDim2.new(button.Size.X.Scale, button.Size.X.Offset + 4, button.Size.Y.Scale, button.Size.Y.Offset + 4)}
        )
        hoverTween:Play()
    end)
    
    button.MouseLeave:Connect(function()
        local unhoverTween = TweenService:Create(
            button,
            TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
            {Size = UDim2.new(button.Size.X.Scale, button.Size.X.Offset - 4, button.Size.Y.Scale, button.Size.Y.Offset - 4)}
        )
        unhoverTween:Play()
    end)
    
    -- Click effect
    button.MouseButton1Down:Connect(function()
        local clickTween = TweenService:Create(
            button,
            TweenInfo.new(0.1, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
            {Size = UDim2.new(button.Size.X.Scale, button.Size.X.Offset - 2, button.Size.Y.Scale, button.Size.Y.Offset - 2)}
        )
        clickTween:Play()
    end)
    
    button.MouseButton1Up:Connect(function()
        local releaseTween = TweenService:Create(
            button,
            TweenInfo.new(0.1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
            {Size = UDim2.new(button.Size.X.Scale, button.Size.X.Offset + 2, button.Size.Y.Scale, button.Size.Y.Offset + 2)}
        )
        releaseTween:Play()
    end)
end

function MultiplayerController:ShowGameSelection()
    if gameSelectionGui then
        gameSelectionGui.Enabled = true
        
        -- Fade in animation
        local frame = gameSelectionGui.SelectionFrame
        frame.BackgroundTransparency = 1
        frame.Size = UDim2.new(0, 300, 0, 200)
        
        local fadeIn = TweenService:Create(
            frame,
            TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
            {
                BackgroundTransparency = 0,
                Size = UDim2.new(0, 400, 0, 300)
            }
        )
        fadeIn:Play()
        
        -- Fade in all children
        for _, child in pairs(frame:GetChildren()) do
            if child:IsA("GuiObject") then
                child.BackgroundTransparency = 1
                child.TextTransparency = 1
                
                local childTween = TweenService:Create(
                    child,
                    TweenInfo.new(0.4, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
                    {
                        BackgroundTransparency = child:GetAttribute("OriginalBackgroundTransparency") or 0,
                        TextTransparency = 0
                    }
                )
                childTween:Play()
            end
        end
    end
end

function MultiplayerController:HideGameSelection()
    if gameSelectionGui then
        local frame = gameSelectionGui.SelectionFrame
        
        local fadeOut = TweenService:Create(
            frame,
            TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
            {
                BackgroundTransparency = 1,
                Size = UDim2.new(0, 300, 0, 200)
            }
        )
        
        fadeOut:Play()
        fadeOut.Completed:Connect(function()
            gameSelectionGui.Enabled = false
        end)
    end
end

function MultiplayerController:StartSoloGame()
    self:HideGameSelection()
    RemoteEvents.JoinSoloGame:FireServer()
    print("🏃 Starting solo game...")
end

function MultiplayerController:JoinMultiplayerQueue()
    self:HideGameSelection()
    RemoteEvents.JoinMultiplayerQueue:FireServer()
    print("👥 Joining multiplayer queue...")
end

function MultiplayerController:LeaveQueue()
    RemoteEvents.LeaveMultiplayerQueue:FireServer()
    isInQueue = false
    
    if queueGui then
        queueGui.Enabled = false
    end
    
    print("👋 Left multiplayer queue")
end

function MultiplayerController:UpdateQueueDisplay(queueCount, maxSize, playerNames)
    if not queueGui then return end
    
    local queueFrame = queueGui.QueueFrame
    local queueStatus = queueFrame.QueueStatus
    local playerList = queueFrame.PlayerList
    
    -- Update status text
    queueStatus.Text = string.format("👥 %d/%d players ready", queueCount, maxSize)
    
    -- Clear existing player entries
    for _, child in pairs(playerList:GetChildren()) do
        if child:IsA("TextLabel") then
            child:Destroy()
        end
    end
    
    -- Add player entries
    for i, playerName in pairs(playerNames) do
        local playerEntry = Instance.new("TextLabel")
        playerEntry.Name = "Player" .. i
        playerEntry.Size = UDim2.new(1, -10, 0, 25)
        playerEntry.BackgroundTransparency = 1
        playerEntry.Text = string.format("%d. %s", i, playerName)
        playerEntry.TextColor3 = Color3.new(1, 1, 1)
        playerEntry.TextScaled = true
        playerEntry.Font = Enum.Font.SourceSans
        playerEntry.TextXAlignment = Enum.TextXAlignment.Left
        playerEntry.Parent = playerList
    end
    
    -- Update canvas size
    playerList.CanvasSize = UDim2.new(0, 0, 0, #playerNames * 27)
end

function MultiplayerController:ShowMultiplayerLeaderboard()
    if multiplayerLeaderboardGui then
        multiplayerLeaderboardGui.Enabled = true
    end
end

function MultiplayerController:HideMultiplayerLeaderboard()
    if multiplayerLeaderboardGui then
        multiplayerLeaderboardGui.Enabled = false
    end
end

function MultiplayerController:ShowFinalResults(finalResults)
    -- Create final results GUI
    local finalResultsGui = Instance.new("ScreenGui")
    finalResultsGui.Name = "FinalResults"
    finalResultsGui.ResetOnSpawn = false
    finalResultsGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    finalResultsGui.Parent = playerGui
    
    -- Main results frame
    local resultsFrame = Instance.new("Frame")
    resultsFrame.Name = "ResultsFrame"
    resultsFrame.Size = UDim2.new(0, 500, 0, 400)
    resultsFrame.Position = UDim2.new(0.5, -250, 0.5, -200)
    resultsFrame.BackgroundColor3 = Color3.new(0.1, 0.1, 0.15)
    resultsFrame.BorderSizePixel = 0
    resultsFrame.Parent = finalResultsGui
    
    local resultsCorner = Instance.new("UICorner")
    resultsCorner.CornerRadius = UDim.new(0, 12)
    resultsCorner.Parent = resultsFrame
    
    -- Title
    local title = Instance.new("TextLabel")
    title.Name = "Title"
    title.Size = UDim2.new(1, 0, 0, 60)
    title.BackgroundTransparency = 1
    title.Text = "🏆 FINAL RESULTS"
    title.TextColor3 = Color3.fromRGB(255, 215, 0)
    title.TextScaled = true
    title.Font = Enum.Font.SourceSansBold
    title.Parent = resultsFrame
    
    -- Results container
    local resultsContainer = Instance.new("ScrollingFrame")
    resultsContainer.Name = "ResultsContainer"
    resultsContainer.Size = UDim2.new(1, -20, 1, -120)
    resultsContainer.Position = UDim2.new(0, 10, 0, 70)
    resultsContainer.BackgroundColor3 = Color3.new(0.05, 0.05, 0.1)
    resultsContainer.BorderSizePixel = 0
    resultsContainer.ScrollBarThickness = 8
    resultsContainer.Parent = resultsFrame
    
    local containerCorner = Instance.new("UICorner")
    containerCorner.CornerRadius = UDim.new(0, 6)
    containerCorner.Parent = resultsContainer
    
    local resultsLayout = Instance.new("UIListLayout")
    resultsLayout.SortOrder = Enum.SortOrder.LayoutOrder
    resultsLayout.Padding = UDim.new(0, 3)
    resultsLayout.Parent = resultsContainer
    
    -- Create result entries
    for i, result in pairs(finalResults) do
        local entryFrame = Instance.new("Frame")
        entryFrame.Name = "Result" .. i
        entryFrame.Size = UDim2.new(1, -10, 0, 50)
        entryFrame.LayoutOrder = i
        entryFrame.BorderSizePixel = 0
        entryFrame.Parent = resultsContainer
        
        -- Color based on placement
        if i == 1 then
            entryFrame.BackgroundColor3 = Color3.fromRGB(255, 215, 0) -- Gold
        elseif i == 2 then
            entryFrame.BackgroundColor3 = Color3.fromRGB(192, 192, 192) -- Silver
        elseif i == 3 then
            entryFrame.BackgroundColor3 = Color3.fromRGB(205, 127, 50) -- Bronze
        else
            entryFrame.BackgroundColor3 = Color3.fromRGB(60, 60, 80) -- Regular
        end
        
        local entryCorner = Instance.new("UICorner")
        entryCorner.CornerRadius = UDim.new(0, 4)
        entryCorner.Parent = entryFrame
        
        -- Placement
        local placement = Instance.new("TextLabel")
        placement.Size = UDim2.new(0, 50, 1, 0)
        placement.BackgroundTransparency = 1
        placement.Text = i == 1 and "🥇" or i == 2 and "🥈" or i == 3 and "🥉" or tostring(i)
        placement.TextColor3 = Color3.new(1, 1, 1)
        placement.TextScaled = true
        placement.Font = Enum.Font.SourceSansBold
        placement.Parent = entryFrame
        
        -- Player name
        local playerName = Instance.new("TextLabel")
        playerName.Size = UDim2.new(0, 180, 1, 0)
        playerName.Position = UDim2.new(0, 55, 0, 0)
        playerName.BackgroundTransparency = 1
        playerName.Text = result.name
        playerName.TextColor3 = Color3.new(1, 1, 1)
        playerName.TextScaled = true
        playerName.Font = Enum.Font.SourceSans
        playerName.TextXAlignment = Enum.TextXAlignment.Left
        playerName.Parent = entryFrame
        
        -- Score
        local scoreLabel = Instance.new("TextLabel")
        scoreLabel.Size = UDim2.new(0, 80, 1, 0)
        scoreLabel.Position = UDim2.new(0, 240, 0, 0)
        scoreLabel.BackgroundTransparency = 1
        scoreLabel.Text = "Score: " .. tostring(result.score)
        scoreLabel.TextColor3 = Color3.new(1, 1, 1)
        scoreLabel.TextScaled = true
        scoreLabel.Font = Enum.Font.SourceSans
        scoreLabel.Parent = entryFrame
        
        -- Barriers passed
        local barriersLabel = Instance.new("TextLabel")
        barriersLabel.Size = UDim2.new(0, 80, 1, 0)
        barriersLabel.Position = UDim2.new(0, 325, 0, 0)
        barriersLabel.BackgroundTransparency = 1
        barriersLabel.Text = "Barriers: " .. tostring(result.barriersPassed)
        barriersLabel.TextColor3 = Color3.new(1, 1, 1)
        barriersLabel.TextScaled = true
        barriersLabel.Font = Enum.Font.SourceSans
        barriersLabel.Parent = entryFrame
        
        -- Coins collected
        local coinsLabel = Instance.new("TextLabel")
        coinsLabel.Size = UDim2.new(0, 80, 1, 0)
        coinsLabel.Position = UDim2.new(0, 410, 0, 0)
        coinsLabel.BackgroundTransparency = 1
        coinsLabel.Text = "Coins: " .. tostring(result.coinsCollected)
        coinsLabel.TextColor3 = Color3.new(1, 1, 1)
        coinsLabel.TextScaled = true
        coinsLabel.Font = Enum.Font.SourceSans
        coinsLabel.Parent = entryFrame
    end
    
    -- Close button
    local closeButton = Instance.new("TextButton")
    closeButton.Name = "CloseButton"
    closeButton.Size = UDim2.new(1, -20, 0, 40)
    closeButton.Position = UDim2.new(0, 10, 1, -50)
    closeButton.BackgroundColor3 = Color3.fromRGB(75, 150, 255)
    closeButton.BorderSizePixel = 0
    closeButton.Text = "✅ CONTINUE"
    closeButton.TextColor3 = Color3.new(1, 1, 1)
    closeButton.TextScaled = true
    closeButton.Font = Enum.Font.SourceSansBold
    closeButton.Parent = resultsFrame
    
    local closeCorner = Instance.new("UICorner")
    closeCorner.CornerRadius = UDim.new(0, 6)
    closeCorner.Parent = closeButton
    
    self:SetupButtonAnimations(closeButton)
    
    closeButton.MouseButton1Click:Connect(function()
        self:HideFinalResults()
    end)
    
    -- Update canvas size
    resultsContainer.CanvasSize = UDim2.new(0, 0, 0, #finalResults * 53)
    
    -- Store reference for cleanup
    self.finalResultsGui = finalResultsGui
    
    -- Entrance animation
    resultsFrame.Size = UDim2.new(0, 300, 0, 200)
    resultsFrame.BackgroundTransparency = 1
    
    local entranceTween = TweenService:Create(
        resultsFrame,
        TweenInfo.new(0.5, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
        {
            Size = UDim2.new(0, 500, 0, 400),
            BackgroundTransparency = 0
        }
    )
    entranceTween:Play()
    
    print("🏆 Final multiplayer results displayed!")
end

function MultiplayerController:HideFinalResults()
    if self.finalResultsGui then
        local exitTween = TweenService:Create(
            self.finalResultsGui.ResultsFrame,
            TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
            {
                Size = UDim2.new(0, 300, 0, 200),
                BackgroundTransparency = 1
            }
        )
        
        exitTween:Play()
        exitTween.Completed:Connect(function()
            self.finalResultsGui:Destroy()
            self.finalResultsGui = nil
        end)
    end
end

function MultiplayerController:UpdateMultiplayerLeaderboard(leaderboardData)
    if not multiplayerLeaderboardGui then return end
    
    local container = multiplayerLeaderboardGui.LeaderboardFrame.RankingsContainer
    
    -- Clear existing entries
    for _, child in pairs(container:GetChildren()) do
        if child:IsA("Frame") then
            child:Destroy()
        end
    end
    
    -- Sort players by score (highest first)
    table.sort(leaderboardData, function(a, b)
        return (a.score or 0) > (b.score or 0)
    end)
    
    -- Create leaderboard entries
    for i, playerData in pairs(leaderboardData) do
        local entryFrame = Instance.new("Frame")
        entryFrame.Name = "Player" .. i
        entryFrame.Size = UDim2.new(1, -10, 0, 35)
        entryFrame.BackgroundColor3 = i <= 3 and Color3.fromRGB(255, 200, 50) or Color3.fromRGB(60, 60, 80)
        entryFrame.BorderSizePixel = 0
        entryFrame.Parent = container
        
        local entryCorner = Instance.new("UICorner")
        entryCorner.CornerRadius = UDim.new(0, 4)
        entryCorner.Parent = entryFrame
        
        -- Rank
        local rankLabel = Instance.new("TextLabel")
        rankLabel.Size = UDim2.new(0, 30, 1, 0)
        rankLabel.BackgroundTransparency = 1
        rankLabel.Text = tostring(i)
        rankLabel.TextColor3 = Color3.new(1, 1, 1)
        rankLabel.TextScaled = true
        rankLabel.Font = Enum.Font.SourceSansBold
        rankLabel.Parent = entryFrame
        
        -- Player name
        local nameLabel = Instance.new("TextLabel")
        nameLabel.Size = UDim2.new(0, 120, 1, 0)
        nameLabel.Position = UDim2.new(0, 35, 0, 0)
        nameLabel.BackgroundTransparency = 1
        nameLabel.Text = playerData.playerName or "Unknown"
        nameLabel.TextColor3 = Color3.new(1, 1, 1)
        nameLabel.TextScaled = true
        nameLabel.Font = Enum.Font.SourceSans
        nameLabel.TextXAlignment = Enum.TextXAlignment.Left
        nameLabel.Parent = entryFrame
        
        -- Score
        local scoreLabel = Instance.new("TextLabel")
        scoreLabel.Size = UDim2.new(0, 80, 1, 0)
        scoreLabel.Position = UDim2.new(1, -80, 0, 0)
        scoreLabel.BackgroundTransparency = 1
        scoreLabel.Text = tostring(playerData.score or 0)
        scoreLabel.TextColor3 = Color3.new(1, 1, 1)
        scoreLabel.TextScaled = true
        scoreLabel.Font = Enum.Font.SourceSansBold
        scoreLabel.TextXAlignment = Enum.TextXAlignment.Right
        scoreLabel.Parent = entryFrame
    end
    
    -- Update canvas size
    container.CanvasSize = UDim2.new(0, 0, 0, #leaderboardData * 37)
end

function MultiplayerController:SetupRemoteEvents()
    -- Game mode selection
    RemoteEvents.ShowGameModeSelection.OnClientEvent:Connect(function()
        self:ShowGameSelection()
    end)
    
    -- Queue events
    RemoteEvents.JoinedQueue.OnClientEvent:Connect(function(position, maxSize)
        isInQueue = true
        queuePosition = position
        totalInQueue = maxSize
        
        if queueGui then
            queueGui.Enabled = true
        end
        
        print("✅ Joined queue at position " .. position)
    end)
    
    RemoteEvents.LeftQueue.OnClientEvent:Connect(function()
        isInQueue = false
        
        if queueGui then
            queueGui.Enabled = false
        end
        
        print("👋 Left the queue")
    end)
    
    RemoteEvents.QueueUpdate.OnClientEvent:Connect(function(queueCount, maxSize, playerNames)
        self:UpdateQueueDisplay(queueCount, maxSize, playerNames)
    end)
    
    RemoteEvents.QueueFull.OnClientEvent:Connect(function()
        print("⚠️ Queue is full! Try again later.")
    end)
    
    -- Multiplayer game events
    RemoteEvents.MultiplayerGameStarted.OnClientEvent:Connect(function(startColor, gameInfo)
        if queueGui then
            queueGui.Enabled = false
        end
        
        self:ShowMultiplayerLeaderboard()
        print("🎮 Multiplayer game started! Session: " .. (gameInfo.sessionId or "Unknown"))
    end)
    
    RemoteEvents.MultiplayerLeaderboardUpdate.OnClientEvent:Connect(function(leaderboardData)
        self:UpdateMultiplayerLeaderboard(leaderboardData)
    end)
    
    RemoteEvents.MultiplayerGameCompleted.OnClientEvent:Connect(function(finalResults)
        self:ShowFinalResults(finalResults)
        
        spawn(function()
            wait(5) -- Show final results for 5 seconds
            self:HideMultiplayerLeaderboard()
            self:HideFinalResults()
        end)
    end)
    
    -- Synchronized countdown
    RemoteEvents.SynchronizedCountdown.OnClientEvent:Connect(function(count)
        -- You can add countdown UI here if needed
        print("⏰ Multiplayer countdown: " .. count)
    end)
end

function MultiplayerController:Initialize()
    print("👥 MultiplayerController initializing...")
    
    -- Create UI elements
    self:CreateGameSelectionUI()
    self:CreateQueueUI()
    self:CreateMultiplayerLeaderboard()
    
    -- Setup remote events
    self:SetupRemoteEvents()
    
    -- Handle player leaving to clean up UI
    game:BindToClose(function()
        if isInQueue then
            RemoteEvents.LeaveMultiplayerQueue:FireServer()
        end
    end)
    
    print("✅ MultiplayerController initialized!")
end

-- Auto-initialize
MultiplayerController:Initialize()

return MultiplayerController
