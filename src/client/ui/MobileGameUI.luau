-- MobileGameUI.luau
-- Mobile-optimized game interface with responsive controls and HUD

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")

local SafeRequire = require(ReplicatedStorage.Shared.utils.SafeRequire)
local RemoteEvents = SafeRequire.require(ReplicatedStorage.Shared.modules.RemoteEvents)
local MobileOptimizationService = require(script.Parent.Parent.services.MobileOptimizationService)

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local MobileGameUI = {}

-- Game UI state
local gameUIState = {
    isGameActive = false,
    isVisible = false,
    currentScore = 0,
    currentCoins = 0,
    currentTime = 0,
    gameMode = "Solo", -- Solo, Multiplayer, etc.
    touchControls = {},
    hudElements = {}
}

local gameGui = nil
local layoutProps = nil

-- Create mobile game UI
function MobileGameUI.createGameUI()
    layoutProps = MobileOptimizationService.getLayoutProperties()
    local config = layoutProps.config
    
    -- Main game GUI
    gameGui = Instance.new("ScreenGui")
    gameGui.Name = "MobileGameGUI"
    gameGui.ResetOnSpawn = false
    gameGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    gameGui.Parent = playerGui
    
    -- Create HUD elements
    MobileGameUI.createHUD(gameGui, config)
    
    -- Create touch controls for mobile
    if layoutProps.touchEnabled then
        MobileGameUI.createTouchControls(gameGui, config)
    end
    
    -- Create pause menu button
    MobileGameUI.createPauseButton(gameGui, config)
    
    gameUIState.isVisible = true
    return gameGui
end

-- Create HUD (Heads-Up Display) elements
function MobileGameUI.createHUD(parent, config)
    -- HUD Container (respects safe area)
    local hudFrame = Instance.new("Frame")
    hudFrame.Name = "HudFrame"
    hudFrame.Size = UDim2.new(1, -layoutProps.safeArea.left - layoutProps.safeArea.right, 
                              1, -layoutProps.safeArea.top - layoutProps.safeArea.bottom)
    hudFrame.Position = UDim2.new(0, layoutProps.safeArea.left, 0, layoutProps.safeArea.top)
    hudFrame.BackgroundTransparency = 1
    hudFrame.Parent = parent
    
    -- Top bar for score, coins, time
    local topBar = Instance.new("Frame")
    topBar.Name = "TopBar"
    topBar.Size = UDim2.new(1, 0, 0, layoutProps.deviceType == "Phone" and 60 or 70)
    topBar.Position = UDim2.new(0, 0, 0, 0)
    topBar.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    topBar.BackgroundTransparency = 0.3
    topBar.BorderSizePixel = 0
    topBar.Parent = hudFrame
    
    -- Top bar layout
    local topBarLayout = Instance.new("UIListLayout")
    topBarLayout.FillDirection = Enum.FillDirection.Horizontal
    topBarLayout.HorizontalAlignment = Enum.HorizontalAlignment.Left
    topBarLayout.VerticalAlignment = Enum.VerticalAlignment.Center
    topBarLayout.Padding = UDim.new(0, config.padding.medium)
    topBarLayout.Parent = topBar
    
    local topBarPadding = Instance.new("UIPadding")
    topBarPadding.PaddingLeft = UDim.new(0, config.padding.medium)
    topBarPadding.PaddingRight = UDim.new(0, config.padding.medium)
    topBarPadding.Parent = topBar
    
    -- Score display
    local scoreFrame = Instance.new("Frame")
    scoreFrame.Name = "ScoreFrame"
    scoreFrame.Size = UDim2.new(0, 120, 1, -20)
    scoreFrame.BackgroundColor3 = Color3.fromRGB(52, 152, 219)
    scoreFrame.BorderSizePixel = 0
    scoreFrame.Parent = topBar
    
    local scoreCorner = Instance.new("UICorner")
    scoreCorner.CornerRadius = UDim.new(0, 6)
    scoreCorner.Parent = scoreFrame
    
    local scoreIcon = Instance.new("TextLabel")
    scoreIcon.Size = UDim2.new(0, 30, 1, 0)
    scoreIcon.BackgroundTransparency = 1
    scoreIcon.Text = "🏆"
    scoreIcon.TextSize = config.fontSize.medium
    scoreIcon.TextXAlignment = Enum.TextXAlignment.Center
    scoreIcon.Parent = scoreFrame
    
    local scoreLabel = Instance.new("TextLabel")
    scoreLabel.Name = "ScoreLabel"
    scoreLabel.Size = UDim2.new(1, -35, 1, 0)
    scoreLabel.Position = UDim2.new(0, 30, 0, 0)
    scoreLabel.BackgroundTransparency = 1
    scoreLabel.Text = "0"
    scoreLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    scoreLabel.TextSize = config.fontSize.medium
    scoreLabel.Font = Enum.Font.SourceSansBold
    scoreLabel.TextXAlignment = Enum.TextXAlignment.Center
    scoreLabel.Parent = scoreFrame
    
    -- Coins display
    local coinsFrame = Instance.new("Frame")
    coinsFrame.Name = "CoinsFrame"
    coinsFrame.Size = UDim2.new(0, 120, 1, -20)
    coinsFrame.BackgroundColor3 = Color3.fromRGB(241, 196, 15)
    coinsFrame.BorderSizePixel = 0
    coinsFrame.Parent = topBar
    
    local coinsCorner = Instance.new("UICorner")
    coinsCorner.CornerRadius = UDim.new(0, 6)
    coinsCorner.Parent = coinsFrame
    
    local coinsIcon = Instance.new("TextLabel")
    coinsIcon.Size = UDim2.new(0, 30, 1, 0)
    coinsIcon.BackgroundTransparency = 1
    coinsIcon.Text = "💰"
    coinsIcon.TextSize = config.fontSize.medium
    coinsIcon.TextXAlignment = Enum.TextXAlignment.Center
    coinsIcon.Parent = coinsFrame
    
    local coinsLabel = Instance.new("TextLabel")
    coinsLabel.Name = "CoinsLabel"
    coinsLabel.Size = UDim2.new(1, -35, 1, 0)
    coinsLabel.Position = UDim2.new(0, 30, 0, 0)
    coinsLabel.BackgroundTransparency = 1
    coinsLabel.Text = "0"
    coinsLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    coinsLabel.TextSize = config.fontSize.medium
    coinsLabel.Font = Enum.Font.SourceSansBold
    coinsLabel.TextXAlignment = Enum.TextXAlignment.Center
    coinsLabel.Parent = coinsFrame
    
    -- Timer display
    local timerFrame = Instance.new("Frame")
    timerFrame.Name = "TimerFrame"
    timerFrame.Size = UDim2.new(0, 100, 1, -20)
    timerFrame.BackgroundColor3 = Color3.fromRGB(46, 204, 113)
    timerFrame.BorderSizePixel = 0
    timerFrame.Parent = topBar
    
    local timerCorner = Instance.new("UICorner")
    timerCorner.CornerRadius = UDim.new(0, 6)
    timerCorner.Parent = timerFrame
    
    local timerIcon = Instance.new("TextLabel")
    timerIcon.Size = UDim2.new(0, 25, 1, 0)
    timerIcon.BackgroundTransparency = 1
    timerIcon.Text = "⏱️"
    timerIcon.TextSize = config.fontSize.small
    timerIcon.TextXAlignment = Enum.TextXAlignment.Center
    timerIcon.Parent = timerFrame
    
    local timerLabel = Instance.new("TextLabel")
    timerLabel.Name = "TimerLabel"
    timerLabel.Size = UDim2.new(1, -30, 1, 0)
    timerLabel.Position = UDim2.new(0, 25, 0, 0)
    timerLabel.BackgroundTransparency = 1
    timerLabel.Text = "0:00"
    timerLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    timerLabel.TextSize = config.fontSize.small
    timerLabel.Font = Enum.Font.SourceSansBold
    timerLabel.TextXAlignment = Enum.TextXAlignment.Center
    timerLabel.Parent = timerFrame
    
    -- Bottom notification area
    local notificationArea = Instance.new("Frame")
    notificationArea.Name = "NotificationArea"
    notificationArea.Size = UDim2.new(1, 0, 0, 100)
    notificationArea.Position = UDim2.new(0, 0, 1, -120)
    notificationArea.BackgroundTransparency = 1
    notificationArea.Parent = hudFrame
    
    -- Multiplayer leaderboard (right side on tablets, bottom on phones)
    if gameUIState.gameMode == "Multiplayer" then
        MobileGameUI.createMultiplayerLeaderboard(hudFrame, config)
    end
    
    -- Store HUD references
    gameUIState.hudElements = {
        scoreLabel = scoreLabel,
        coinsLabel = coinsLabel,
        timerLabel = timerLabel,
        notificationArea = notificationArea,
        topBar = topBar
    }
end

-- Create touch controls for mobile devices
function MobileGameUI.createTouchControls(parent, config)
    local controlsFrame = Instance.new("Frame")
    controlsFrame.Name = "TouchControlsFrame"
    controlsFrame.Size = UDim2.new(1, 0, 1, 0)
    controlsFrame.BackgroundTransparency = 1
    controlsFrame.Parent = parent
    
    -- Jump button (right side)
    local jumpButton = Instance.new("TextButton")
    jumpButton.Name = "JumpButton"
    jumpButton.Size = UDim2.new(0, config.minTouchSize * 1.5, 0, config.minTouchSize * 1.5)
    jumpButton.Position = UDim2.new(1, -config.minTouchSize * 1.5 - config.padding.large, 1, -config.minTouchSize * 1.5 - config.padding.large - 60)
    jumpButton.BackgroundColor3 = Color3.fromRGB(52, 152, 219)
    jumpButton.BorderSizePixel = 0
    jumpButton.Text = "🏃"
    jumpButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    jumpButton.TextSize = config.fontSize.title
    jumpButton.Font = Enum.Font.SourceSansBold
    jumpButton.AutoButtonColor = false
    jumpButton.Parent = controlsFrame
    
    local jumpCorner = Instance.new("UICorner")
    jumpCorner.CornerRadius = UDim.new(0.5, 0)
    jumpCorner.Parent = jumpButton
    
    -- Jump button functionality
    local jumpPressed = false
    jumpButton.MouseButton1Down:Connect(function()
        if not jumpPressed then
            jumpPressed = true
            jumpButton.BackgroundColor3 = Color3.fromRGB(41, 128, 185)
            jumpButton.Size = UDim2.new(0, config.minTouchSize * 1.4, 0, config.minTouchSize * 1.4)
            
            -- Send jump input to server
            if RemoteEvents.PlayerJumped then
                RemoteEvents.PlayerJumped:FireServer()
            end
        end
    end)
    
    jumpButton.MouseButton1Up:Connect(function()
        jumpPressed = false
        jumpButton.BackgroundColor3 = Color3.fromRGB(52, 152, 219)
        jumpButton.Size = UDim2.new(0, config.minTouchSize * 1.5, 0, config.minTouchSize * 1.5)
    end)
    
    -- Color change power-up button (left side)
    local colorButton = Instance.new("TextButton")
    colorButton.Name = "ColorButton"
    colorButton.Size = UDim2.new(0, config.minTouchSize * 1.3, 0, config.minTouchSize * 1.3)
    colorButton.Position = UDim2.new(0, config.padding.large, 1, -config.minTouchSize * 1.3 - config.padding.large - 60)
    colorButton.BackgroundColor3 = Color3.fromRGB(155, 89, 182)
    colorButton.BorderSizePixel = 0
    colorButton.Text = "🎨"
    colorButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    colorButton.TextSize = config.fontSize.large
    colorButton.Font = Enum.Font.SourceSansBold
    colorButton.AutoButtonColor = false
    colorButton.Parent = controlsFrame
    
    local colorCorner = Instance.new("UICorner")
    colorCorner.CornerRadius = UDim.new(0.5, 0)
    colorCorner.Parent = colorButton
    
    colorButton.MouseButton1Click:Connect(function()
        colorButton.BackgroundColor3 = Color3.fromRGB(142, 68, 173)
        
        -- Send color change request
        if RemoteEvents.ChangeColor then
            RemoteEvents.ChangeColor:FireServer()
        end
        
        task.wait(0.1)
        colorButton.BackgroundColor3 = Color3.fromRGB(155, 89, 182)
    end)
    
    -- Pause/Settings button (top-right, smaller)
    local settingsButton = Instance.new("TextButton")
    settingsButton.Name = "SettingsButton"
    settingsButton.Size = UDim2.new(0, 40, 0, 40)
    settingsButton.Position = UDim2.new(1, -50, 0, layoutProps.safeArea.top + 10)
    settingsButton.BackgroundColor3 = Color3.fromRGB(149, 165, 166)
    settingsButton.BorderSizePixel = 0
    settingsButton.Text = "⚙️"
    settingsButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    settingsButton.TextSize = config.fontSize.medium
    settingsButton.AutoButtonColor = false
    settingsButton.Parent = controlsFrame
    
    local settingsCorner = Instance.new("UICorner")
    settingsCorner.CornerRadius = UDim.new(0.5, 0)
    settingsCorner.Parent = settingsButton
    
    settingsButton.MouseButton1Click:Connect(function()
        MobileGameUI.showPauseMenu()
    end)
    
    -- Store touch control references
    gameUIState.touchControls = {
        jumpButton = jumpButton,
        colorButton = colorButton,
        settingsButton = settingsButton
    }
    
    -- Add haptic feedback if available
    if layoutProps.touchEnabled then
        MobileGameUI.addHapticFeedback()
    end
end

-- Create pause button
function MobileGameUI.createPauseButton(parent, config)
    local pauseButton = Instance.new("TextButton")
    pauseButton.Name = "PauseButton"
    pauseButton.Size = UDim2.new(0, 50, 0, 50)
    pauseButton.Position = UDim2.new(1, -60, 0, layoutProps.safeArea.top + 10)
    pauseButton.BackgroundColor3 = Color3.fromRGB(52, 73, 94)
    pauseButton.BackgroundTransparency = 0.2
    pauseButton.BorderSizePixel = 0
    pauseButton.Text = "⏸️"
    pauseButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    pauseButton.TextSize = config.fontSize.large
    pauseButton.Font = Enum.Font.SourceSansBold
    pauseButton.ZIndex = 200
    pauseButton.Parent = parent
    
    local pauseCorner = Instance.new("UICorner")
    pauseCorner.CornerRadius = UDim.new(0, 8)
    pauseCorner.Parent = pauseButton
    
    pauseButton.MouseButton1Click:Connect(function()
        MobileGameUI.showPauseMenu()
    end)
end

-- Create multiplayer leaderboard
function MobileGameUI.createMultiplayerLeaderboard(parent, config)
    local leaderboardFrame = Instance.new("Frame")
    leaderboardFrame.Name = "MultiplayerLeaderboard"
    
    if layoutProps.deviceType == "Phone" then
        -- Bottom position for phones
        leaderboardFrame.Size = UDim2.new(1, -40, 0, 120)
        leaderboardFrame.Position = UDim2.new(0, 20, 1, -140)
    else
        -- Right side for tablets
        leaderboardFrame.Size = UDim2.new(0, 200, 0.6, 0)
        leaderboardFrame.Position = UDim2.new(1, -220, 0.2, 0)
    end
    
    leaderboardFrame.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    leaderboardFrame.BackgroundTransparency = 0.4
    leaderboardFrame.BorderSizePixel = 0
    leaderboardFrame.Parent = parent
    
    local leaderboardCorner = Instance.new("UICorner")
    leaderboardCorner.CornerRadius = UDim.new(0, 8)
    leaderboardCorner.Parent = leaderboardFrame
    
    -- Leaderboard title
    local titleLabel = Instance.new("TextLabel")
    titleLabel.Size = UDim2.new(1, 0, 0, 30)
    titleLabel.BackgroundTransparency = 1
    titleLabel.Text = "🏁 Leaderboard"
    titleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    titleLabel.TextSize = config.fontSize.medium
    titleLabel.Font = Enum.Font.SourceSansBold
    titleLabel.TextXAlignment = Enum.TextXAlignment.Center
    titleLabel.Parent = leaderboardFrame
    
    -- Leaderboard content scroll
    local leaderboardScroll = MobileOptimizationService.createMobileScrollFrame({
        size = UDim2.new(1, -10, 1, -35),
        position = UDim2.new(0, 5, 0, 30),
        backgroundColor = Color3.fromRGB(255, 255, 255),
        backgroundTransparency = 1,
        useListLayout = true,
        parent = leaderboardFrame
    })
    
    gameUIState.hudElements.multiplayerLeaderboard = leaderboardScroll
end

-- Show pause menu
function MobileGameUI.showPauseMenu()
    local pauseModal = MobileOptimizationService.createMobileModal({
        title = "⏸️ Game Paused",
        height = 300,
        backgroundColor = Color3.fromRGB(248, 249, 250),
        closeOnBackgroundTap = false
    })
    
    local config = layoutProps.config
    
    -- Pause game
    if RemoteEvents.PauseGame then
        RemoteEvents.PauseGame:FireServer(true)
    end
    
    -- Menu buttons
    local buttonsData = {
        {text = "▶️ Resume", color = Color3.fromRGB(46, 204, 113), action = "resume"},
        {text = "🏠 Return to Hub", color = Color3.fromRGB(52, 152, 219), action = "hub"},
        {text = "🔄 Restart", color = Color3.fromRGB(241, 196, 15), action = "restart"},
        {text = "⚙️ Settings", color = Color3.fromRGB(149, 165, 166), action = "settings"}
    }
    
    local buttonContainer = Instance.new("Frame")
    buttonContainer.Size = UDim2.new(1, 0, 1, -20)
    buttonContainer.Position = UDim2.new(0, 0, 0, 10)
    buttonContainer.BackgroundTransparency = 1
    buttonContainer.Parent = pauseModal.contentArea
    
    local buttonLayout = Instance.new("UIListLayout")
    buttonLayout.FillDirection = Enum.FillDirection.Vertical
    buttonLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
    buttonLayout.VerticalAlignment = Enum.VerticalAlignment.Center
    buttonLayout.Padding = UDim.new(0, config.padding.medium)
    buttonLayout.Parent = buttonContainer
    
    for _, buttonData in ipairs(buttonsData) do
        local button = MobileOptimizationService.createMobileButton({
            size = UDim2.new(0.8, 0, 0, config.buttonHeight),
            backgroundColor = buttonData.color,
            text = buttonData.text,
            parent = buttonContainer
        })
        
        button.MouseButton1Click:Connect(function()
            MobileGameUI.handlePauseMenuAction(buttonData.action, pauseModal)
        end)
    end
end

-- Handle pause menu actions
function MobileGameUI.handlePauseMenuAction(action, pauseModal)
    if action == "resume" then
        -- Resume game
        if RemoteEvents.PauseGame then
            RemoteEvents.PauseGame:FireServer(false)
        end
        MobileOptimizationService.closeMobileModal(pauseModal.overlay)
        
    elseif action == "hub" then
        -- Return to hub
        if RemoteEvents.ReturnToHub then
            RemoteEvents.ReturnToHub:FireServer()
        end
        MobileOptimizationService.closeMobileModal(pauseModal.overlay)
        
    elseif action == "restart" then
        -- Restart game
        if RemoteEvents.FinishGame then
            RemoteEvents.FinishGame:FireServer()
        end
        MobileOptimizationService.closeMobileModal(pauseModal.overlay)
        
    elseif action == "settings" then
        -- Show settings menu
        MobileOptimizationService.closeMobileModal(pauseModal.overlay)
        MobileGameUI.showSettingsMenu()
    end
end

-- Show settings menu
function MobileGameUI.showSettingsMenu()
    local settingsModal = MobileOptimizationService.createMobileModal({
        title = "⚙️ Settings",
        height = 400,
        backgroundColor = Color3.fromRGB(248, 249, 250),
        closeOnBackgroundTap = true
    })
    
    local config = layoutProps.config
    
    -- Settings content
    local settingsScroll = MobileOptimizationService.createMobileScrollFrame({
        size = UDim2.new(1, 0, 1, 0),
        backgroundColor = Color3.fromRGB(255, 255, 255),
        backgroundTransparency = 1,
        useListLayout = true,
        parent = settingsModal.contentArea
    })
    
    -- Audio settings
    MobileGameUI.createSettingsSection(settingsScroll, "🔊 Audio", {
        {type = "toggle", label = "Music", key = "music_enabled"},
        {type = "toggle", label = "Sound Effects", key = "sfx_enabled"},
        {type = "slider", label = "Volume", key = "master_volume", min = 0, max = 100}
    }, config)
    
    -- Graphics settings
    MobileGameUI.createSettingsSection(settingsScroll, "🎨 Graphics", {
        {type = "toggle", label = "Visual Effects", key = "effects_enabled"},
        {type = "toggle", label = "Trails", key = "trails_enabled"},
        {type = "dropdown", label = "Quality", key = "graphics_quality", options = {"Low", "Medium", "High"}}
    }, config)
    
    -- Controls settings
    if layoutProps.touchEnabled then
        MobileGameUI.createSettingsSection(settingsScroll, "📱 Controls", {
            {type = "toggle", label = "Haptic Feedback", key = "haptic_enabled"},
            {type = "slider", label = "Button Size", key = "button_size", min = 80, max = 120},
            {type = "toggle", label = "Auto-Jump", key = "auto_jump"}
        }, config)
    end
end

-- Create settings section
function MobileGameUI.createSettingsSection(parent, title, settings, config)
    -- Section header
    local headerFrame = Instance.new("Frame")
    headerFrame.Size = UDim2.new(1, 0, 0, 40)
    headerFrame.BackgroundColor3 = Color3.fromRGB(230, 230, 230)
    headerFrame.BorderSizePixel = 0
    headerFrame.Parent = parent
    
    local headerCorner = Instance.new("UICorner")
    headerCorner.CornerRadius = UDim.new(0, 6)
    headerCorner.Parent = headerFrame
    
    local headerLabel = Instance.new("TextLabel")
    headerLabel.Size = UDim2.new(1, -20, 1, 0)
    headerLabel.Position = UDim2.new(0, 10, 0, 0)
    headerLabel.BackgroundTransparency = 1
    headerLabel.Text = title
    headerLabel.TextColor3 = Color3.fromRGB(44, 62, 80)
    headerLabel.TextSize = config.fontSize.medium
    headerLabel.Font = Enum.Font.SourceSansBold
    headerLabel.TextXAlignment = Enum.TextXAlignment.Left
    headerLabel.Parent = headerFrame
    
    -- Settings items
    for _, setting in ipairs(settings) do
        local settingFrame = Instance.new("Frame")
        settingFrame.Size = UDim2.new(1, 0, 0, 50)
        settingFrame.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
        settingFrame.BorderSizePixel = 0
        settingFrame.Parent = parent
        
        local settingLabel = Instance.new("TextLabel")
        settingLabel.Size = UDim2.new(0.6, 0, 1, 0)
        settingLabel.Position = UDim2.new(0, 20, 0, 0)
        settingLabel.BackgroundTransparency = 1
        settingLabel.Text = setting.label
        settingLabel.TextColor3 = Color3.fromRGB(44, 62, 80)
        settingLabel.TextSize = config.fontSize.medium
        settingLabel.Font = Enum.Font.SourceSans
        settingLabel.TextXAlignment = Enum.TextXAlignment.Left
        settingLabel.Parent = settingFrame
        
        -- Create appropriate control based on type
        if setting.type == "toggle" then
            local toggleButton = MobileOptimizationService.createMobileButton({
                size = UDim2.new(0, 60, 0, 30),
                position = UDim2.new(1, -80, 0.5, -15),
                backgroundColor = Color3.fromRGB(46, 204, 113), -- Assume enabled for demo
                text = "ON",
                parent = settingFrame
            })
            
            toggleButton.MouseButton1Click:Connect(function()
                -- Toggle logic would go here
                if toggleButton.Text == "ON" then
                    toggleButton.Text = "OFF"
                    toggleButton.BackgroundColor3 = Color3.fromRGB(231, 76, 60)
                else
                    toggleButton.Text = "ON"
                    toggleButton.BackgroundColor3 = Color3.fromRGB(46, 204, 113)
                end
            end)
        end
    end
end

-- Add haptic feedback
function MobileGameUI.addHapticFeedback()
    -- Note: Roblox doesn't have direct haptic feedback API
    -- This would integrate with platform-specific haptic systems
    print("[Mobile] Haptic feedback enabled for touch controls")
end

-- Update HUD elements
function MobileGameUI.updateScore(score)
    gameUIState.currentScore = score
    if gameUIState.hudElements.scoreLabel then
        gameUIState.hudElements.scoreLabel.Text = tostring(score)
    end
end

function MobileGameUI.updateCoins(coins)
    gameUIState.currentCoins = coins
    if gameUIState.hudElements.coinsLabel then
        gameUIState.hudElements.coinsLabel.Text = tostring(coins)
    end
end

function MobileGameUI.updateTimer(time)
    gameUIState.currentTime = time
    if gameUIState.hudElements.timerLabel then
        local minutes = math.floor(time / 60)
        local seconds = time % 60
        gameUIState.hudElements.timerLabel.Text = string.format("%d:%02d", minutes, seconds)
    end
end

-- Show game UI
function MobileGameUI.show(gameMode)
    gameUIState.gameMode = gameMode or "Solo"
    if not gameGui then
        MobileGameUI.createGameUI()
    end
    gameGui.Enabled = true
    gameUIState.isGameActive = true
end

-- Hide game UI
function MobileGameUI.hide()
    if gameGui then
        gameGui.Enabled = false
    end
    gameUIState.isGameActive = false
end

-- Clean up game UI
function MobileGameUI.cleanup()
    if gameGui then
        gameGui:Destroy()
        gameGui = nil
    end
    gameUIState.isVisible = false
    gameUIState.isGameActive = false
end

-- Remote event connections
if RemoteEvents.GameStarted then
    RemoteEvents.GameStarted.OnClientEvent:Connect(function(gameMode)
        MobileGameUI.show(gameMode)
    end)
end

if RemoteEvents.GameEnded then
    RemoteEvents.GameEnded.OnClientEvent:Connect(function()
        MobileGameUI.hide()
    end)
end

if RemoteEvents.NewHighScore then
    RemoteEvents.NewHighScore.OnClientEvent:Connect(function(score)
        MobileGameUI.updateScore(score)
    end)
end

if RemoteEvents.CoinCollected then
    RemoteEvents.CoinCollected.OnClientEvent:Connect(function(totalCoins)
        MobileGameUI.updateCoins(totalCoins)
    end)
end

if RemoteEvents.GameTimer then
    RemoteEvents.GameTimer.OnClientEvent:Connect(function(timeRemaining)
        MobileGameUI.updateTimer(timeRemaining)
    end)
end

return MobileGameUI
