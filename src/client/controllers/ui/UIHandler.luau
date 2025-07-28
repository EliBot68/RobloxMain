-- UIHandler.luau
-- Modular UI management system that reflects game state changes
-- Handles Menu, HUD, and Game Over screens with RemoteEvent integration

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local StarterGui = game:GetService("StarterGui")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local UIHandler = {}

-- Game States (matching server)
local GAME_STATES = {
    LOBBY = "Lobby",
    WAITING = "Waiting",
    COUNTDOWN = "Countdown", 
    RUNNING = "Running",
    GAME_OVER = "GameOver",
    RESETTING = "Resetting"
}

-- UI States
local UI_STATES = {
    MENU = "Menu",
    HUD = "HUD", 
    GAME_OVER = "GameOver",
    LOADING = "Loading"
}

-- Current state tracking
local currentGameState = GAME_STATES.LOBBY
local currentUIState = UI_STATES.MENU
local playerData = {
    score = 0,
    lives = 3,
    maxLives = 3,
    timeRemaining = 60
}

-- UI Elements
local UIElements = {}
local RemoteEvents = {}

-- Animation configurations
local ANIMATIONS = {
    fadeIn = TweenInfo.new(0.5, Enum.EasingStyle.Quart, Enum.EasingDirection.Out),
    fadeOut = TweenInfo.new(0.3, Enum.EasingStyle.Quart, Enum.EasingDirection.In),
    slideIn = TweenInfo.new(0.6, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
    bounce = TweenInfo.new(0.4, Enum.EasingStyle.Elastic, Enum.EasingDirection.Out),
    pulse = TweenInfo.new(0.5, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut)
}

-- ========================================
-- INITIALIZATION
-- ========================================

function UIHandler:Init()
    print("🖼️ Initializing UI Handler...")
    
    -- Connect to RemoteEvents
    self:ConnectToRemoteEvents()
    
    -- Create UI elements
    self:CreateMenuUI()
    self:CreateHUDUI()
    self:CreateGameOverUI()
    self:CreateSharedUI()
    
    -- Set initial state
    self:SetUIState(UI_STATES.MENU)
    
    -- Setup input handling
    self:SetupInputHandling()
    
    print("✅ UI Handler initialized!")
end

function UIHandler:ConnectToRemoteEvents()
    print("📡 Connecting to RemoteEvents...")
    
    local eventsFolder = ReplicatedStorage:WaitForChild("Events", 10)
    if not eventsFolder then
        warn("❌ Events folder not found!")
        return
    end
    
    -- Get RemoteEvents
    RemoteEvents.GameStateChanged = eventsFolder:WaitForChild("GameStateChanged", 5)
    RemoteEvents.ScoreUpdated = eventsFolder:WaitForChild("ScoreUpdated", 5)
    RemoteEvents.GameTimerUpdate = eventsFolder:WaitForChild("GameTimerUpdate", 5)
    RemoteEvents.PlayerDied = eventsFolder:WaitForChild("PlayerDied", 5)
    RemoteEvents.GameStarted = eventsFolder:WaitForChild("GameStarted", 5)
    RemoteEvents.GameEnded = eventsFolder:WaitForChild("GameEnded", 5)
    RemoteEvents.CountdownUpdate = eventsFolder:WaitForChild("CountdownUpdate", 5)
    
    -- Request events
    RemoteEvents.RequestJoinGame = eventsFolder:WaitForChild("RequestJoinGame", 5)
    RemoteEvents.RequestLeaveGame = eventsFolder:WaitForChild("RequestLeaveGame", 5)
    
    -- Connect event handlers
    self:ConnectEventHandlers()
    
    print("✅ RemoteEvents connected!")
end

function UIHandler:ConnectEventHandlers()
    if RemoteEvents.GameStateChanged then
        RemoteEvents.GameStateChanged.OnClientEvent:Connect(function(newState, oldState)
            self:OnGameStateChanged(newState, oldState)
        end)
    end
    
    if RemoteEvents.ScoreUpdated then
        RemoteEvents.ScoreUpdated.OnClientEvent:Connect(function(score, difference, reason)
            self:OnScoreUpdated(score, difference, reason)
        end)
    end
    
    if RemoteEvents.GameTimerUpdate then
        RemoteEvents.GameTimerUpdate.OnClientEvent:Connect(function(timeRemaining)
            self:OnTimerUpdated(timeRemaining)
        end)
    end
    
    if RemoteEvents.PlayerDied then
        RemoteEvents.PlayerDied.OnClientEvent:Connect(function(deathData)
            self:OnPlayerDied(deathData)
        end)
    end
    
    if RemoteEvents.GameStarted then
        RemoteEvents.GameStarted.OnClientEvent:Connect(function(gameData)
            self:OnGameStarted(gameData)
        end)
    end
    
    if RemoteEvents.GameEnded then
        RemoteEvents.GameEnded.OnClientEvent:Connect(function(results)
            self:OnGameEnded(results)
        end)
    end
    
    if RemoteEvents.CountdownUpdate then
        RemoteEvents.CountdownUpdate.OnClientEvent:Connect(function(timeLeft)
            self:OnCountdownUpdate(timeLeft)
        end)
    end
end

-- ========================================
-- UI CREATION METHODS
-- ========================================

function UIHandler:CreateMenuUI()
    print("🏠 Creating Menu UI...")
    
    -- Main Menu Screen
    local menuGui = Instance.new("ScreenGui")
    menuGui.Name = "MenuUI"
    menuGui.ResetOnSpawn = false
    menuGui.DisplayOrder = 1
    menuGui.Parent = playerGui
    
    -- Main background
    local backgroundFrame = Instance.new("Frame")
    backgroundFrame.Name = "Background"
    backgroundFrame.Size = UDim2.new(1, 0, 1, 0)
    backgroundFrame.BackgroundColor3 = Color3.fromRGB(20, 25, 35)
    backgroundFrame.BorderSizePixel = 0
    backgroundFrame.Parent = menuGui
    
    -- Gradient background
    local gradient = Instance.new("UIGradient")
    gradient.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Color3.fromRGB(30, 35, 50)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(15, 20, 30))
    })
    gradient.Rotation = 45
    gradient.Parent = backgroundFrame
    
    -- Title
    local titleLabel = Instance.new("TextLabel")
    titleLabel.Name = "TitleLabel"
    titleLabel.Size = UDim2.new(0.8, 0, 0.15, 0)
    titleLabel.Position = UDim2.new(0.1, 0, 0.1, 0)
    titleLabel.BackgroundTransparency = 1
    titleLabel.Text = "COLOR RUSH"
    titleLabel.TextColor3 = Color3.fromRGB(220, 220, 220)
    titleLabel.TextScaled = true
    titleLabel.Font = Enum.Font.GothamBold
    titleLabel.TextStrokeTransparency = 0
    titleLabel.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
    titleLabel.Parent = backgroundFrame
    
    -- Play button
    local playButton = self:CreateStyledButton("PlayButton", "PLAY", UDim2.new(0.3, 0, 0.08, 0), UDim2.new(0.35, 0, 0.4, 0))
    playButton.BackgroundColor3 = Color3.fromRGB(80, 180, 80)
    playButton.Parent = backgroundFrame
    
    -- Settings button
    local settingsButton = self:CreateStyledButton("SettingsButton", "SETTINGS", UDim2.new(0.3, 0, 0.08, 0), UDim2.new(0.35, 0, 0.52, 0))
    settingsButton.BackgroundColor3 = Color3.fromRGB(60, 120, 200)
    settingsButton.Parent = backgroundFrame
    
    -- Leaderboard button
    local leaderboardButton = self:CreateStyledButton("LeaderboardButton", "LEADERBOARD", UDim2.new(0.3, 0, 0.08, 0), UDim2.new(0.35, 0, 0.64, 0))
    leaderboardButton.BackgroundColor3 = Color3.fromRGB(200, 160, 30)
    leaderboardButton.Parent = backgroundFrame
    
    -- Connect button events
    playButton.MouseButton1Click:Connect(function()
        self:OnPlayButtonClicked()
    end)
    
    settingsButton.MouseButton1Click:Connect(function()
        self:OnSettingsButtonClicked()
    end)
    
    leaderboardButton.MouseButton1Click:Connect(function()
        self:OnLeaderboardButtonClicked()
    end)
    
    UIElements.menuGui = menuGui
    UIElements.titleLabel = titleLabel
    UIElements.playButton = playButton
    
    print("✅ Menu UI created!")
end

function UIHandler:CreateHUDUI()
    print("🎮 Creating HUD UI...")
    
    -- HUD Screen
    local hudGui = Instance.new("ScreenGui")
    hudGui.Name = "HUDUI"
    hudGui.ResetOnSpawn = false
    hudGui.DisplayOrder = 2
    hudGui.Parent = playerGui
    
    -- Score display
    local scoreFrame = Instance.new("Frame")
    scoreFrame.Name = "ScoreFrame"
    scoreFrame.Size = UDim2.new(0.15, 0, 0.08, 0)
    scoreFrame.Position = UDim2.new(0.02, 0, 0.02, 0)
    scoreFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
    scoreFrame.BorderSizePixel = 0
    scoreFrame.Parent = hudGui
    
    local scoreCorner = Instance.new("UICorner")
    scoreCorner.CornerRadius = UDim.new(0, 8)
    scoreCorner.Parent = scoreFrame
    
    local scoreLabel = Instance.new("TextLabel")
    scoreLabel.Name = "ScoreLabel"
    scoreLabel.Size = UDim2.new(1, 0, 1, 0)
    scoreLabel.BackgroundTransparency = 1
    scoreLabel.Text = "Score: 0"
    scoreLabel.TextColor3 = Color3.fromRGB(220, 220, 220)
    scoreLabel.TextScaled = true
    scoreLabel.Font = Enum.Font.GothamBold
    scoreLabel.Parent = scoreFrame
    
    -- Timer display
    local timerFrame = Instance.new("Frame")
    timerFrame.Name = "TimerFrame"
    timerFrame.Size = UDim2.new(0.12, 0, 0.08, 0)
    timerFrame.Position = UDim2.new(0.44, 0, 0.02, 0)
    timerFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
    timerFrame.BorderSizePixel = 0
    timerFrame.Parent = hudGui
    
    local timerCorner = Instance.new("UICorner")
    timerCorner.CornerRadius = UDim.new(0, 8)
    timerCorner.Parent = timerFrame
    
    local timerLabel = Instance.new("TextLabel")
    timerLabel.Name = "TimerLabel"
    timerLabel.Size = UDim2.new(1, 0, 1, 0)
    timerLabel.BackgroundTransparency = 1
    timerLabel.Text = "1:00"
    timerLabel.TextColor3 = Color3.fromRGB(220, 220, 220)
    timerLabel.TextScaled = true
    timerLabel.Font = Enum.Font.GothamBold
    timerLabel.Parent = timerFrame
    
    -- Lives display
    local livesFrame = Instance.new("Frame")
    livesFrame.Name = "LivesFrame"
    livesFrame.Size = UDim2.new(0.15, 0, 0.08, 0)
    livesFrame.Position = UDim2.new(0.83, 0, 0.02, 0)
    livesFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
    livesFrame.BorderSizePixel = 0
    livesFrame.Parent = hudGui
    
    local livesCorner = Instance.new("UICorner")
    livesCorner.CornerRadius = UDim.new(0, 8)
    livesCorner.Parent = livesFrame
    
    local livesLabel = Instance.new("TextLabel")
    livesLabel.Name = "LivesLabel"
    livesLabel.Size = UDim2.new(1, 0, 1, 0)
    livesLabel.BackgroundTransparency = 1
    livesLabel.Text = "Lives: 3"
    livesLabel.TextColor3 = Color3.fromRGB(80, 220, 80)
    livesLabel.TextScaled = true
    livesLabel.Font = Enum.Font.GothamBold
    livesLabel.Parent = livesFrame
    
    -- Countdown overlay (for game start)
    local countdownFrame = Instance.new("Frame")
    countdownFrame.Name = "CountdownFrame"
    countdownFrame.Size = UDim2.new(1, 0, 1, 0)
    countdownFrame.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    countdownFrame.BackgroundTransparency = 0.5
    countdownFrame.BorderSizePixel = 0
    countdownFrame.Visible = false
    countdownFrame.Parent = hudGui
    
    local countdownLabel = Instance.new("TextLabel")
    countdownLabel.Name = "CountdownLabel"
    countdownLabel.Size = UDim2.new(0.4, 0, 0.3, 0)
    countdownLabel.Position = UDim2.new(0.3, 0, 0.35, 0)
    countdownLabel.BackgroundTransparency = 1
    countdownLabel.Text = "3"
    countdownLabel.TextColor3 = Color3.fromRGB(220, 220, 220)
    countdownLabel.TextScaled = true
    countdownLabel.Font = Enum.Font.GothamBold
    countdownLabel.TextStrokeTransparency = 0
    countdownLabel.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
    countdownLabel.Parent = countdownFrame
    
    UIElements.hudGui = hudGui
    UIElements.scoreLabel = scoreLabel
    UIElements.timerLabel = timerLabel
    UIElements.livesLabel = livesLabel
    UIElements.countdownFrame = countdownFrame
    UIElements.countdownLabel = countdownLabel
    
    print("✅ HUD UI created!")
end

function UIHandler:CreateGameOverUI()
    print("🏁 Creating Game Over UI...")
    
    -- Game Over Screen
    local gameOverGui = Instance.new("ScreenGui")
    gameOverGui.Name = "GameOverUI"
    gameOverGui.ResetOnSpawn = false
    gameOverGui.DisplayOrder = 3
    gameOverGui.Parent = playerGui
    
    -- Background overlay
    local overlay = Instance.new("Frame")
    overlay.Name = "Overlay"
    overlay.Size = UDim2.new(1, 0, 1, 0)
    overlay.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    overlay.BackgroundTransparency = 0.3
    overlay.BorderSizePixel = 0
    overlay.Parent = gameOverGui
    
    -- Main results frame
    local resultsFrame = Instance.new("Frame")
    resultsFrame.Name = "ResultsFrame"
    resultsFrame.Size = UDim2.new(0.4, 0, 0.6, 0)
    resultsFrame.Position = UDim2.new(0.3, 0, 0.2, 0)
    resultsFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
    resultsFrame.BorderSizePixel = 0
    resultsFrame.Parent = overlay
    
    local resultsCorner = Instance.new("UICorner")
    resultsCorner.CornerRadius = UDim.new(0, 12)
    resultsCorner.Parent = resultsFrame
    
    local resultsStroke = Instance.new("UIStroke")
    resultsStroke.Color = Color3.fromRGB(100, 100, 100)
    resultsStroke.Thickness = 2
    resultsStroke.Parent = resultsFrame
    
    -- Result title
    local resultLabel = Instance.new("TextLabel")
    resultLabel.Name = "ResultLabel"
    resultLabel.Size = UDim2.new(0.8, 0, 0.15, 0)
    resultLabel.Position = UDim2.new(0.1, 0, 0.05, 0)
    resultLabel.BackgroundTransparency = 1
    resultLabel.Text = "GAME OVER"
    resultLabel.TextColor3 = Color3.fromRGB(220, 80, 80)
    resultLabel.TextScaled = true
    resultLabel.Font = Enum.Font.GothamBold
    resultLabel.Parent = resultsFrame
    
    -- Final score
    local finalScoreLabel = Instance.new("TextLabel")
    finalScoreLabel.Name = "FinalScoreLabel"
    finalScoreLabel.Size = UDim2.new(0.8, 0, 0.12, 0)
    finalScoreLabel.Position = UDim2.new(0.1, 0, 0.25, 0)
    finalScoreLabel.BackgroundTransparency = 1
    finalScoreLabel.Text = "Final Score: 0"
    finalScoreLabel.TextColor3 = Color3.fromRGB(220, 220, 220)
    finalScoreLabel.TextScaled = true
    finalScoreLabel.Font = Enum.Font.Gotham
    finalScoreLabel.Parent = resultsFrame
    
    -- Play Again button
    local playAgainButton = self:CreateStyledButton("PlayAgainButton", "PLAY AGAIN", UDim2.new(0.7, 0, 0.1, 0), UDim2.new(0.15, 0, 0.6, 0))
    playAgainButton.BackgroundColor3 = Color3.fromRGB(80, 180, 80)
    playAgainButton.Parent = resultsFrame
    
    -- Main Menu button
    local mainMenuButton = self:CreateStyledButton("MainMenuButton", "MAIN MENU", UDim2.new(0.7, 0, 0.1, 0), UDim2.new(0.15, 0, 0.75, 0))
    mainMenuButton.BackgroundColor3 = Color3.fromRGB(140, 140, 140)
    mainMenuButton.Parent = resultsFrame
    
    -- Connect button events
    playAgainButton.MouseButton1Click:Connect(function()
        self:OnPlayAgainButtonClicked()
    end)
    
    mainMenuButton.MouseButton1Click:Connect(function()
        self:OnMainMenuButtonClicked()
    end)
    
    UIElements.gameOverGui = gameOverGui
    UIElements.resultLabel = resultLabel
    UIElements.finalScoreLabel = finalScoreLabel
    UIElements.playAgainButton = playAgainButton
    UIElements.mainMenuButton = mainMenuButton
    
    print("✅ Game Over UI created!")
end

function UIHandler:CreateSharedUI()
    print("🔗 Creating Shared UI...")
    
    -- Notification system
    local notificationGui = Instance.new("ScreenGui")
    notificationGui.Name = "NotificationUI"
    notificationGui.ResetOnSpawn = false
    notificationGui.DisplayOrder = 10
    notificationGui.Parent = playerGui
    
    local notificationFrame = Instance.new("Frame")
    notificationFrame.Name = "NotificationFrame"
    notificationFrame.Size = UDim2.new(0.4, 0, 0.08, 0)
    notificationFrame.Position = UDim2.new(0.3, 0, -0.1, 0)
    notificationFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
    notificationFrame.BorderSizePixel = 0
    notificationFrame.Visible = false
    notificationFrame.Parent = notificationGui
    
    local notificationCorner = Instance.new("UICorner")
    notificationCorner.CornerRadius = UDim.new(0, 8)
    notificationCorner.Parent = notificationFrame
    
    local notificationLabel = Instance.new("TextLabel")
    notificationLabel.Name = "NotificationLabel"
    notificationLabel.Size = UDim2.new(1, 0, 1, 0)
    notificationLabel.BackgroundTransparency = 1
    notificationLabel.Text = "Notification"
    notificationLabel.TextColor3 = Color3.fromRGB(220, 220, 220)
    notificationLabel.TextScaled = true
    notificationLabel.Font = Enum.Font.Gotham
    notificationLabel.Parent = notificationFrame
    
    UIElements.notificationFrame = notificationFrame
    UIElements.notificationLabel = notificationLabel
    
    print("✅ Shared UI created!")
end

function UIHandler:CreateStyledButton(name, text, size, position)
    local button = Instance.new("TextButton")
    button.Name = name
    button.Size = size
    button.Position = position
    button.BackgroundColor3 = Color3.fromRGB(60, 120, 200)
    button.BorderSizePixel = 0
    button.Text = text
    button.TextColor3 = Color3.fromRGB(255, 255, 255)
    button.TextScaled = true
    button.Font = Enum.Font.GothamBold
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 8)
    corner.Parent = button
    
    local stroke = Instance.new("UIStroke")
    stroke.Color = Color3.fromRGB(100, 100, 100)
    stroke.Thickness = 1
    stroke.Parent = button
    
    -- Hover effects
    button.MouseEnter:Connect(function()
        local hoverTween = TweenService:Create(button, ANIMATIONS.bounce, {Size = UDim2.new(size.X.Scale * 1.05, 0, size.Y.Scale * 1.05, 0)})
        hoverTween:Play()
    end)
    
    button.MouseLeave:Connect(function()
        local leaveTween = TweenService:Create(button, ANIMATIONS.bounce, {Size = size})
        leaveTween:Play()
    end)
    
    return button
end

-- ========================================
-- UI STATE MANAGEMENT
-- ========================================

function UIHandler:SetUIState(newState)
    print("🔄 Setting UI state: " .. newState)
    
    currentUIState = newState
    
    -- Hide all UI first
    self:HideAllUI()
    
    -- Show appropriate UI
    if newState == UI_STATES.MENU then
        self:ShowMenuUI()
    elseif newState == UI_STATES.HUD then
        self:ShowHUDUI()
    elseif newState == UI_STATES.GAME_OVER then
        self:ShowGameOverUI()
    end
end

function UIHandler:HideAllUI()
    if UIElements.menuGui then UIElements.menuGui.Visible = false end
    if UIElements.hudGui then UIElements.hudGui.Visible = false end
    if UIElements.gameOverGui then UIElements.gameOverGui.Visible = false end
    if UIElements.countdownFrame then UIElements.countdownFrame.Visible = false end
end

function UIHandler:ShowMenuUI()
    if UIElements.menuGui then
        UIElements.menuGui.Visible = true
        
        -- Animate title entrance
        if UIElements.titleLabel then
            UIElements.titleLabel.Position = UDim2.new(0.1, 0, -0.2, 0)
            local slideIn = TweenService:Create(UIElements.titleLabel, ANIMATIONS.slideIn, {Position = UDim2.new(0.1, 0, 0.1, 0)})
            slideIn:Play()
        end
    end
end

function UIHandler:ShowHUDUI()
    if UIElements.hudGui then
        UIElements.hudGui.Visible = true
        
        -- Update HUD with current data
        self:UpdateScoreDisplay()
        self:UpdateTimerDisplay()
        self:UpdateLivesDisplay()
    end
end

function UIHandler:ShowGameOverUI()
    if UIElements.gameOverGui then
        UIElements.gameOverGui.Visible = true
        
        -- Update final score
        if UIElements.finalScoreLabel then
            UIElements.finalScoreLabel.Text = "Final Score: " .. playerData.score
        end
        
        -- Animate entrance
        if UIElements.gameOverGui:FindFirstChild("Overlay") then
            local resultsFrame = UIElements.gameOverGui.Overlay:FindFirstChild("ResultsFrame")
            if resultsFrame then
                resultsFrame.Position = UDim2.new(0.3, 0, -0.6, 0)
                local slideIn = TweenService:Create(resultsFrame, ANIMATIONS.slideIn, {Position = UDim2.new(0.3, 0, 0.2, 0)})
                slideIn:Play()
            end
        end
    end
end

-- ========================================
-- EVENT HANDLERS
-- ========================================

function UIHandler:OnGameStateChanged(newState, oldState)
    print("🎮 Game state changed: " .. oldState .. " → " .. newState)
    
    currentGameState = newState
    
    -- Update UI based on game state
    if newState == GAME_STATES.LOBBY then
        self:SetUIState(UI_STATES.MENU)
    elseif newState == GAME_STATES.WAITING then
        self:SetUIState(UI_STATES.MENU)
        self:ShowNotification("Waiting for players...", 3)
    elseif newState == GAME_STATES.COUNTDOWN then
        self:SetUIState(UI_STATES.HUD)
        if UIElements.countdownFrame then
            UIElements.countdownFrame.Visible = true
        end
    elseif newState == GAME_STATES.RUNNING then
        self:SetUIState(UI_STATES.HUD)
        if UIElements.countdownFrame then
            UIElements.countdownFrame.Visible = false
        end
    elseif newState == GAME_STATES.GAME_OVER then
        self:SetUIState(UI_STATES.GAME_OVER)
    end
end

function UIHandler:OnScoreUpdated(score, difference, reason)
    playerData.score = score
    self:UpdateScoreDisplay()
    
    -- Show score popup if there was an increase
    if difference and difference > 0 then
        self:ShowScorePopup("+" .. difference, reason)
    end
end

function UIHandler:OnTimerUpdated(timeRemaining)
    playerData.timeRemaining = timeRemaining
    self:UpdateTimerDisplay()
end

function UIHandler:OnPlayerDied(deathData)
    if deathData.player == player then
        playerData.lives = deathData.livesRemaining or 0
        self:UpdateLivesDisplay()
        
        if playerData.lives > 0 then
            self:ShowNotification("Life lost! " .. playerData.lives .. " remaining", 3)
        end
    end
end

function UIHandler:OnGameStarted(gameData)
    playerData.lives = gameData.maxLives or 3
    playerData.maxLives = gameData.maxLives or 3
    playerData.score = 0
    playerData.timeRemaining = gameData.gameTime or 60
    
    self:UpdateAllDisplays()
end

function UIHandler:OnGameEnded(results)
    -- Determine win/loss for result display
    local playerWon = false
    if results.winners then
        for _, winner in pairs(results.winners) do
            if winner.player == player then
                playerWon = true
                break
            end
        end
    end
    
    -- Update result text
    if UIElements.resultLabel then
        if playerWon then
            UIElements.resultLabel.Text = "VICTORY!"
            UIElements.resultLabel.TextColor3 = Color3.fromRGB(80, 220, 80)
        else
            UIElements.resultLabel.Text = "GAME OVER"
            UIElements.resultLabel.TextColor3 = Color3.fromRGB(220, 80, 80)
        end
    end
end

function UIHandler:OnCountdownUpdate(timeLeft)
    if UIElements.countdownLabel then
        if timeLeft > 0 then
            UIElements.countdownLabel.Text = tostring(timeLeft)
        else
            UIElements.countdownLabel.Text = "GO!"
        end
        
        -- Animate countdown
        local scaleUp = TweenService:Create(UIElements.countdownLabel, ANIMATIONS.bounce, {Size = UDim2.new(0.5, 0, 0.4, 0)})
        local scaleDown = TweenService:Create(UIElements.countdownLabel, TweenInfo.new(0.3), {Size = UDim2.new(0.4, 0, 0.3, 0)})
        
        scaleUp:Play()
        scaleUp.Completed:Connect(function()
            scaleDown:Play()
        end)
    end
end

-- ========================================
-- UI UPDATE METHODS
-- ========================================

function UIHandler:UpdateScoreDisplay()
    if UIElements.scoreLabel then
        UIElements.scoreLabel.Text = "Score: " .. playerData.score
    end
end

function UIHandler:UpdateTimerDisplay()
    if UIElements.timerLabel then
        local minutes = math.floor(playerData.timeRemaining / 60)
        local seconds = playerData.timeRemaining % 60
        UIElements.timerLabel.Text = string.format("%d:%02d", minutes, seconds)
        
        -- Warning color for low time
        if playerData.timeRemaining <= 10 then
            UIElements.timerLabel.TextColor3 = Color3.fromRGB(220, 80, 80)
        else
            UIElements.timerLabel.TextColor3 = Color3.fromRGB(220, 220, 220)
        end
    end
end

function UIHandler:UpdateLivesDisplay()
    if UIElements.livesLabel then
        UIElements.livesLabel.Text = "Lives: " .. playerData.lives
        
        -- Color based on lives remaining
        if playerData.lives <= 1 then
            UIElements.livesLabel.TextColor3 = Color3.fromRGB(220, 80, 80) -- Red
        elseif playerData.lives <= 2 then
            UIElements.livesLabel.TextColor3 = Color3.fromRGB(220, 180, 60) -- Yellow
        else
            UIElements.livesLabel.TextColor3 = Color3.fromRGB(80, 220, 80) -- Green
        end
    end
end

function UIHandler:UpdateAllDisplays()
    self:UpdateScoreDisplay()
    self:UpdateTimerDisplay()
    self:UpdateLivesDisplay()
end

-- ========================================
-- BUTTON HANDLERS
-- ========================================

function UIHandler:OnPlayButtonClicked()
    print("🎮 Play button clicked")
    if RemoteEvents.RequestJoinGame then
        RemoteEvents.RequestJoinGame:FireServer()
    end
    self:ShowNotification("Joining game...", 2)
end

function UIHandler:OnSettingsButtonClicked()
    print("⚙️ Settings button clicked")
    self:ShowNotification("Settings - Coming soon!", 2)
end

function UIHandler:OnLeaderboardButtonClicked()
    print("🏆 Leaderboard button clicked")
    self:ShowNotification("Leaderboard - Coming soon!", 2)
end

function UIHandler:OnPlayAgainButtonClicked()
    print("🔄 Play again button clicked")
    if RemoteEvents.RequestJoinGame then
        RemoteEvents.RequestJoinGame:FireServer()
    end
end

function UIHandler:OnMainMenuButtonClicked()
    print("🏠 Main menu button clicked")
    self:SetUIState(UI_STATES.MENU)
end

-- ========================================
-- UTILITY METHODS
-- ========================================

function UIHandler:ShowNotification(message, duration)
    if UIElements.notificationFrame and UIElements.notificationLabel then
        UIElements.notificationLabel.Text = message
        UIElements.notificationFrame.Visible = true
        
        -- Animate in
        local slideIn = TweenService:Create(UIElements.notificationFrame, ANIMATIONS.slideIn, {Position = UDim2.new(0.3, 0, 0.05, 0)})
        slideIn:Play()
        
        -- Auto-hide
        spawn(function()
            wait(duration or 3)
            local slideOut = TweenService:Create(UIElements.notificationFrame, ANIMATIONS.fadeOut, {Position = UDim2.new(0.3, 0, -0.1, 0)})
            slideOut:Play()
            slideOut.Completed:Connect(function()
                UIElements.notificationFrame.Visible = false
            end)
        end)
    end
end

function UIHandler:ShowScorePopup(scoreText, reason)
    local popup = Instance.new("TextLabel")
    popup.Size = UDim2.new(0.1, 0, 0.05, 0)
    popup.Position = UDim2.new(0.45, 0, 0.5, 0)
    popup.BackgroundTransparency = 1
    popup.Text = scoreText
    popup.TextColor3 = Color3.fromRGB(80, 220, 80)
    popup.TextScaled = true
    popup.Font = Enum.Font.GothamBold
    popup.TextStrokeTransparency = 0
    popup.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
    popup.Parent = playerGui
    
    -- Animate popup
    local moveUp = TweenService:Create(popup, TweenInfo.new(2), {Position = UDim2.new(0.45, 0, 0.3, 0), TextTransparency = 1})
    moveUp:Play()
    moveUp.Completed:Connect(function()
        popup:Destroy()
    end)
end

function UIHandler:SetupInputHandling()
    UserInputService.InputBegan:Connect(function(input, gameProcessed)
        if gameProcessed then return end
        
        if input.KeyCode == Enum.KeyCode.Escape then
            if currentUIState == UI_STATES.HUD then
                self:ShowNotification("Game paused", 2)
            end
        end
    end)
end

-- ========================================
-- PUBLIC API
-- ========================================

function UIHandler:GetCurrentUIState()
    return currentUIState
end

function UIHandler:GetPlayerData()
    return playerData
end

function UIHandler:ManualUpdateScore(score)
    playerData.score = score
    self:UpdateScoreDisplay()
end

function UIHandler:ManualUpdateLives(lives)
    playerData.lives = lives
    self:UpdateLivesDisplay()
end

function UIHandler:ManualUpdateTimer(time)
    playerData.timeRemaining = time
    self:UpdateTimerDisplay()
end

-- Initialize the UIHandler
UIHandler:Init()

return UIHandler
