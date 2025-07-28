-- MainGameController.client.luau
-- Central client-side game state management for Color Rush
-- Handles UI transitions, RemoteEvent listening, and client-side game coordination

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local SoundService = game:GetService("SoundService")
local UserInputService = game:GetService("UserInputService")
local StarterGui = game:GetService("StarterGui")
local GuiService = game:GetService("GuiService")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local MainGameController = {}

-- Game States (must match server)
local GAME_STATES = {
    LOBBY = "Lobby",
    WAITING = "Waiting", 
    COUNTDOWN = "Countdown",
    RUNNING = "Running",
    GAME_OVER = "GameOver",
    RESETTING = "Resetting"
}

-- UI State Management
local UI_STATES = {
    MAIN_MENU = "MainMenu",
    WAITING_ROOM = "WaitingRoom",
    COUNTDOWN = "Countdown",
    GAMEPLAY_HUD = "GameplayHUD",
    GAME_OVER = "GameOver",
    SPECTATING = "Spectating"
}

-- Current State
local currentGameState = GAME_STATES.LOBBY
local currentUIState = UI_STATES.MAIN_MENU
local isInGame = false
local playerScore = 0
local playerLives = 3
local gameTimeRemaining = 60

-- RemoteEvents
local Events = {}

-- UI References (will be connected to StarterGui elements)
local UIElements = {
    -- Main Menu (StarterGui/MainMenu)
    mainMenuGui = nil,
    playButton = nil,
    settingsButton = nil,
    shopButton = nil,
    leaderboardButton = nil,
    titleLabel = nil,
    
    -- Waiting Room (StarterGui/WaitingRoom)
    waitingRoomGui = nil,
    playerListFrame = nil,
    playersCountLabel = nil,
    waitingStatusLabel = nil,
    leaveButton = nil,
    
    -- Countdown (StarterGui/Countdown)
    countdownGui = nil,
    countdownNumberLabel = nil,
    countdownTextLabel = nil,
    
    -- Gameplay HUD (StarterGui/GameplayHUD)
    gameplayHudGui = nil,
    scoreLabel = nil,
    livesLabel = nil,
    timerLabel = nil,
    colorIndicator = nil,
    minimap = nil,
    pauseButton = nil,
    comboLabel = nil,
    
    -- Game Over (StarterGui/GameOver)
    gameOverGui = nil,
    resultLabel = nil,
    finalScoreLabel = nil,
    playAgainButton = nil,
    mainMenuButton = nil,
    statsFrame = nil,
    
    -- Shared Elements
    loadingSpinner = nil,
    notificationFrame = nil,
    chatFrame = nil
}

-- Audio References
local AudioElements = {
    backgroundMusic = nil,
    gameplayMusic = nil,
    countdownSound = nil,
    victorySound = nil,
    defeatSound = nil,
    uiClickSound = nil,
    scoreSound = nil,
    liveLostSound = nil
}

-- Screen Effects Controller Reference
local ScreenEffectsController = nil

-- Performance monitoring
local lastFrameTime = tick()
local frameCount = 0
local averageFPS = 60

function MainGameController:Init()
    print("🎮 Initializing Client Main Game Controller...")
    
    -- Wait for essential services
    self:WaitForEssentialServices()
    
    -- Connect to RemoteEvents
    self:ConnectToRemoteEvents()
    
    -- Initialize UI system
    self:InitializeUI()
    
    -- Initialize audio system
    self:InitializeAudio()
    
    -- Connect to other controllers
    self:ConnectToControllers()
    
    -- Setup input handling
    self:SetupInputHandling()
    
    -- Start performance monitoring
    self:StartPerformanceMonitoring()
    
    -- Set initial UI state
    self:TransitionToUI(UI_STATES.MAIN_MENU)
    
    print("✅ Client Main Game Controller initialized!")
    print("📊 Current State: " .. currentGameState .. " | UI: " .. currentUIState)
end

function MainGameController:WaitForEssentialServices()
    print("⏳ Waiting for essential services...")
    
    -- Wait for ReplicatedStorage to be ready
    if not ReplicatedStorage:FindFirstChild("Events") then
        ReplicatedStorage.ChildAdded:Wait()
    end
    
    -- Wait for player character if needed
    if not player.Character then
        player.CharacterAdded:Wait()
    end
    
    print("✅ Essential services ready")
end

function MainGameController:ConnectToRemoteEvents()
    print("🔗 Connecting to RemoteEvents...")
    
    local eventsFolder = ReplicatedStorage:WaitForChild("Events", 10)
    if not eventsFolder then
        warn("❌ Events folder not found in ReplicatedStorage!")
        return
    end
    
    -- Core game events
    Events.GameStateChanged = eventsFolder:WaitForChild("GameStateChanged", 5)
    Events.GameStarted = eventsFolder:WaitForChild("GameStarted", 5)
    Events.GameEnded = eventsFolder:WaitForChild("GameEnded", 5)
    Events.CountdownUpdate = eventsFolder:WaitForChild("CountdownUpdate", 5)
    Events.GameWarning = eventsFolder:WaitForChild("GameWarning", 5)
    Events.GameTimerUpdate = eventsFolder:WaitForChild("GameTimerUpdate", 5)
    
    -- Player events
    Events.PlayerJoinedGame = eventsFolder:WaitForChild("PlayerJoinedGame", 5)
    Events.PlayerLeftGame = eventsFolder:WaitForChild("PlayerLeftGame", 5)
    Events.PlayerWon = eventsFolder:WaitForChild("PlayerWon", 5)
    Events.PlayerLost = eventsFolder:WaitForChild("PlayerLost", 5)
    Events.PlayerSpawned = eventsFolder:WaitForChild("PlayerSpawned", 5)
    Events.PlayerDied = eventsFolder:WaitForChild("PlayerDied", 5)
    Events.PlayerFinished = eventsFolder:WaitForChild("PlayerFinished", 5)
    
    -- Gameplay events
    Events.ScoreUpdated = eventsFolder:WaitForChild("ScoreUpdated", 5)
    Events.ObstacleHit = eventsFolder:WaitForChild("ObstacleHit", 5)
    Events.CollectibleCollected = eventsFolder:WaitForChild("CollectibleCollected", 5)
    Events.ColorChanged = eventsFolder:WaitForChild("ColorChanged", 5)
    Events.PowerupActivated = eventsFolder:WaitForChild("PowerupActivated", 5)
    Events.ComboUpdated = eventsFolder:WaitForChild("ComboUpdated", 5)
    
    -- Request events (client to server)
    Events.RequestJoinGame = eventsFolder:WaitForChild("RequestJoinGame", 5)
    Events.RequestLeaveGame = eventsFolder:WaitForChild("RequestLeaveGame", 5)
    Events.RequestStartGame = eventsFolder:WaitForChild("RequestStartGame", 5)
    Events.RequestRespawn = eventsFolder:WaitForChild("RequestRespawn", 5)
    
    -- Connect event handlers
    self:ConnectEventHandlers()
    
    print("✅ RemoteEvents connected successfully!")
end

function MainGameController:ConnectEventHandlers()
    print("📡 Connecting event handlers...")
    
    -- Core game state events
    if Events.GameStateChanged then
        Events.GameStateChanged.OnClientEvent:Connect(function(newState, oldState)
            self:OnGameStateChanged(newState, oldState)
        end)
    end
    
    if Events.GameStarted then
        Events.GameStarted.OnClientEvent:Connect(function(gameData)
            self:OnGameStarted(gameData)
        end)
    end
    
    if Events.GameEnded then
        Events.GameEnded.OnClientEvent:Connect(function(results)
            self:OnGameEnded(results)
        end)
    end
    
    if Events.CountdownUpdate then
        Events.CountdownUpdate.OnClientEvent:Connect(function(timeLeft)
            self:OnCountdownUpdate(timeLeft)
        end)
    end
    
    if Events.GameTimerUpdate then
        Events.GameTimerUpdate.OnClientEvent:Connect(function(timeRemaining)
            self:OnGameTimerUpdate(timeRemaining)
        end)
    end
    
    if Events.GameWarning then
        Events.GameWarning.OnClientEvent:Connect(function(warningType, data)
            self:OnGameWarning(warningType, data)
        end)
    end
    
    -- Player events
    if Events.PlayerJoinedGame then
        Events.PlayerJoinedGame.OnClientEvent:Connect(function(playerData)
            self:OnPlayerJoinedGame(playerData)
        end)
    end
    
    if Events.PlayerLeftGame then
        Events.PlayerLeftGame.OnClientEvent:Connect(function(playerData)
            self:OnPlayerLeftGame(playerData)
        end)
    end
    
    if Events.PlayerWon then
        Events.PlayerWon.OnClientEvent:Connect(function(winData)
            self:OnPlayerWon(winData)
        end)
    end
    
    if Events.PlayerLost then
        Events.PlayerLost.OnClientEvent:Connect(function(lossData)
            self:OnPlayerLost(lossData)
        end)
    end
    
    if Events.PlayerDied then
        Events.PlayerDied.OnClientEvent:Connect(function(deathData)
            self:OnPlayerDied(deathData)
        end)
    end
    
    -- Gameplay events
    if Events.ScoreUpdated then
        Events.ScoreUpdated.OnClientEvent:Connect(function(newScore, scoreDifference, reason)
            self:OnScoreUpdated(newScore, scoreDifference, reason)
        end)
    end
    
    if Events.ObstacleHit then
        Events.ObstacleHit.OnClientEvent:Connect(function(hitData)
            self:OnObstacleHit(hitData)
        end)
    end
    
    if Events.CollectibleCollected then
        Events.CollectibleCollected.OnClientEvent:Connect(function(collectData)
            self:OnCollectibleCollected(collectData)
        end)
    end
    
    if Events.ColorChanged then
        Events.ColorChanged.OnClientEvent:Connect(function(newColor)
            self:OnColorChanged(newColor)
        end)
    end
    
    if Events.ComboUpdated then
        Events.ComboUpdated.OnClientEvent:Connect(function(comboCount, multiplier)
            self:OnComboUpdated(comboCount, multiplier)
        end)
    end
    
    print("✅ Event handlers connected!")
end

function MainGameController:InitializeUI()
    print("🖼️ Initializing UI system...")
    
    -- Connect to UI elements in StarterGui
    self:ConnectToUIElements()
    
    -- Setup UI event handlers
    self:SetupUIEventHandlers()
    
    -- Initialize UI animations
    self:InitializeUIAnimations()
    
    print("✅ UI system initialized!")
end

function MainGameController:ConnectToUIElements()
    print("🔗 Connecting to UI elements...")
    
    -- Wait for and connect to UI elements
    spawn(function()
        -- Main Menu UI
        local mainMenuGui = playerGui:WaitForChild("MainMenu", 5)
        if mainMenuGui then
            UIElements.mainMenuGui = mainMenuGui
            UIElements.playButton = mainMenuGui:FindFirstChild("PlayButton", true)
            UIElements.settingsButton = mainMenuGui:FindFirstChild("SettingsButton", true)
            UIElements.shopButton = mainMenuGui:FindFirstChild("ShopButton", true)
            UIElements.leaderboardButton = mainMenuGui:FindFirstChild("LeaderboardButton", true)
            UIElements.titleLabel = mainMenuGui:FindFirstChild("TitleLabel", true)
            print("✅ Main Menu UI connected")
        else
            warn("⚠️ MainMenu GUI not found in StarterGui")
        end
        
        -- Waiting Room UI
        local waitingRoomGui = playerGui:WaitForChild("WaitingRoom", 5)
        if waitingRoomGui then
            UIElements.waitingRoomGui = waitingRoomGui
            UIElements.playerListFrame = waitingRoomGui:FindFirstChild("PlayerListFrame", true)
            UIElements.playersCountLabel = waitingRoomGui:FindFirstChild("PlayersCountLabel", true)
            UIElements.waitingStatusLabel = waitingRoomGui:FindFirstChild("WaitingStatusLabel", true)
            UIElements.leaveButton = waitingRoomGui:FindFirstChild("LeaveButton", true)
            print("✅ Waiting Room UI connected")
        else
            warn("⚠️ WaitingRoom GUI not found in StarterGui")
        end
        
        -- Countdown UI
        local countdownGui = playerGui:WaitForChild("Countdown", 5)
        if countdownGui then
            UIElements.countdownGui = countdownGui
            UIElements.countdownNumberLabel = countdownGui:FindFirstChild("CountdownNumber", true)
            UIElements.countdownTextLabel = countdownGui:FindFirstChild("CountdownText", true)
            print("✅ Countdown UI connected")
        else
            warn("⚠️ Countdown GUI not found in StarterGui")
        end
        
        -- Gameplay HUD UI
        local gameplayHudGui = playerGui:WaitForChild("GameplayHUD", 5)
        if gameplayHudGui then
            UIElements.gameplayHudGui = gameplayHudGui
            UIElements.scoreLabel = gameplayHudGui:FindFirstChild("ScoreLabel", true)
            UIElements.livesLabel = gameplayHudGui:FindFirstChild("LivesLabel", true)
            UIElements.timerLabel = gameplayHudGui:FindFirstChild("TimerLabel", true)
            UIElements.colorIndicator = gameplayHudGui:FindFirstChild("ColorIndicator", true)
            UIElements.minimap = gameplayHudGui:FindFirstChild("Minimap", true)
            UIElements.pauseButton = gameplayHudGui:FindFirstChild("PauseButton", true)
            UIElements.comboLabel = gameplayHudGui:FindFirstChild("ComboLabel", true)
            print("✅ Gameplay HUD UI connected")
        else
            warn("⚠️ GameplayHUD GUI not found in StarterGui")
        end
        
        -- Game Over UI
        local gameOverGui = playerGui:WaitForChild("GameOver", 5)
        if gameOverGui then
            UIElements.gameOverGui = gameOverGui
            UIElements.resultLabel = gameOverGui:FindFirstChild("ResultLabel", true)
            UIElements.finalScoreLabel = gameOverGui:FindFirstChild("FinalScoreLabel", true)
            UIElements.playAgainButton = gameOverGui:FindFirstChild("PlayAgainButton", true)
            UIElements.mainMenuButton = gameOverGui:FindFirstChild("MainMenuButton", true)
            UIElements.statsFrame = gameOverGui:FindFirstChild("StatsFrame", true)
            print("✅ Game Over UI connected")
        else
            warn("⚠️ GameOver GUI not found in StarterGui")
        end
    end)
end

function MainGameController:SetupUIEventHandlers()
    print("🎯 Setting up UI event handlers...")
    
    -- Main Menu buttons
    if UIElements.playButton then
        UIElements.playButton.MouseButton1Click:Connect(function()
            self:OnPlayButtonClicked()
        end)
    end
    
    if UIElements.settingsButton then
        UIElements.settingsButton.MouseButton1Click:Connect(function()
            self:OnSettingsButtonClicked()
        end)
    end
    
    if UIElements.shopButton then
        UIElements.shopButton.MouseButton1Click:Connect(function()
            self:OnShopButtonClicked()
        end)
    end
    
    if UIElements.leaderboardButton then
        UIElements.leaderboardButton.MouseButton1Click:Connect(function()
            self:OnLeaderboardButtonClicked()
        end)
    end
    
    -- Waiting Room buttons
    if UIElements.leaveButton then
        UIElements.leaveButton.MouseButton1Click:Connect(function()
            self:OnLeaveButtonClicked()
        end)
    end
    
    -- Game Over buttons
    if UIElements.playAgainButton then
        UIElements.playAgainButton.MouseButton1Click:Connect(function()
            self:OnPlayAgainButtonClicked()
        end)
    end
    
    if UIElements.mainMenuButton then
        UIElements.mainMenuButton.MouseButton1Click:Connect(function()
            self:OnMainMenuButtonClicked()
        end)
    end
    
    -- Gameplay buttons
    if UIElements.pauseButton then
        UIElements.pauseButton.MouseButton1Click:Connect(function()
            self:OnPauseButtonClicked()
        end)
    end
    
    print("✅ UI event handlers setup complete!")
end

function MainGameController:InitializeUIAnimations()
    print("✨ Initializing UI animations...")
    
    -- Create reusable animation tweens
    self.animations = {
        fadeIn = TweenService:Create(
            nil, -- Target will be set dynamically
            TweenInfo.new(0.5, Enum.EasingStyle.Quart, Enum.EasingDirection.Out),
            {Transparency = 0}
        ),
        fadeOut = TweenService:Create(
            nil, -- Target will be set dynamically
            TweenInfo.new(0.3, Enum.EasingStyle.Quart, Enum.EasingDirection.In),
            {Transparency = 1}
        ),
        slideIn = TweenService:Create(
            nil, -- Target will be set dynamically
            TweenInfo.new(0.4, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
            {Position = UDim2.new(0.5, 0, 0.5, 0)}
        ),
        scaleUp = TweenService:Create(
            nil, -- Target will be set dynamically
            TweenInfo.new(0.2, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
            {Size = UDim2.new(1.1, 0, 1.1, 0)}
        ),
        scaleDown = TweenService:Create(
            nil, -- Target will be set dynamically
            TweenInfo.new(0.1, Enum.EasingStyle.Quart, Enum.EasingDirection.Out),
            {Size = UDim2.new(1, 0, 1, 0)}
        )
    }
    
    print("✅ UI animations initialized!")
end

function MainGameController:InitializeAudio()
    print("🔊 Initializing audio system...")
    
    -- Initialize audio elements
    AudioElements.backgroundMusic = self:CreateAudioElement("BackgroundMusic", "rbxasset://sounds/music/background.mp3")
    AudioElements.gameplayMusic = self:CreateAudioElement("GameplayMusic", "rbxasset://sounds/music/gameplay.mp3")
    AudioElements.countdownSound = self:CreateAudioElement("CountdownSound", "rbxasset://sounds/ui/countdown.mp3")
    AudioElements.victorySound = self:CreateAudioElement("VictorySound", "rbxasset://sounds/ui/victory.mp3")
    AudioElements.defeatSound = self:CreateAudioElement("DefeatSound", "rbxasset://sounds/ui/defeat.mp3")
    AudioElements.uiClickSound = self:CreateAudioElement("UIClickSound", "rbxasset://sounds/ui/click.mp3")
    AudioElements.scoreSound = self:CreateAudioElement("ScoreSound", "rbxasset://sounds/gameplay/score.mp3")
    AudioElements.liveLostSound = self:CreateAudioElement("LiveLostSound", "rbxasset://sounds/gameplay/life_lost.mp3")
    
    -- Start background music
    self:PlayAudio("BackgroundMusic", true, 0.5)
    
    print("✅ Audio system initialized!")
end

function MainGameController:CreateAudioElement(name, soundId)
    local sound = Instance.new("Sound")
    sound.Name = name
    sound.SoundId = soundId
    sound.Volume = 0.5
    sound.Parent = SoundService
    return sound
end

function MainGameController:ConnectToControllers()
    print("🔗 Connecting to other controllers...")
    
    -- Connect to ScreenEffectsController
    local success, controller = pcall(function()
        return require(script.Parent.ScreenEffectsController)
    end)
    
    if success then
        ScreenEffectsController = controller
        print("✅ ScreenEffectsController connected")
    else
        warn("⚠️ Could not connect to ScreenEffectsController")
    end
    
    -- Connect to UIHandler
    local uiSuccess, uiHandler = pcall(function()
        return require(script.Parent.ui.UIHandler)
    end)
    
    if uiSuccess then
        self.UIHandler = uiHandler
        print("✅ UIHandler connected")
    else
        warn("⚠️ Could not connect to UIHandler")
    end
    
    print("✅ Controller connections complete!")
end

function MainGameController:SetupInputHandling()
    print("⌨️ Setting up input handling...")
    
    -- Handle ESC key for pausing/menu
    UserInputService.InputBegan:Connect(function(input, gameProcessed)
        if gameProcessed then return end
        
        if input.KeyCode == Enum.KeyCode.Escape then
            if currentGameState == GAME_STATES.RUNNING then
                self:OnPauseButtonClicked()
            elseif currentUIState ~= UI_STATES.MAIN_MENU then
                self:TransitionToUI(UI_STATES.MAIN_MENU)
            end
        end
    end)
    
    print("✅ Input handling setup complete!")
end

function MainGameController:StartPerformanceMonitoring()
    print("📊 Starting performance monitoring...")
    
    RunService.Heartbeat:Connect(function()
        local currentTime = tick()
        local deltaTime = currentTime - lastFrameTime
        lastFrameTime = currentTime
        
        frameCount = frameCount + 1
        if frameCount >= 60 then
            averageFPS = math.floor(60 / deltaTime)
            frameCount = 0
        end
    end)
    
    print("✅ Performance monitoring started!")
end

-- ========================================
-- GAME STATE EVENT HANDLERS
-- ========================================

function MainGameController:OnGameStateChanged(newState, oldState)
    print("🔄 Game state changed: " .. oldState .. " → " .. newState)
    
    currentGameState = newState
    
    -- Transition UI based on game state
    if newState == GAME_STATES.LOBBY then
        self:TransitionToUI(UI_STATES.MAIN_MENU)
        self:PlayAudio("BackgroundMusic", true, 0.5)
        
    elseif newState == GAME_STATES.WAITING then
        self:TransitionToUI(UI_STATES.WAITING_ROOM)
        
    elseif newState == GAME_STATES.COUNTDOWN then
        self:TransitionToUI(UI_STATES.COUNTDOWN)
        self:StopAudio("BackgroundMusic")
        
    elseif newState == GAME_STATES.RUNNING then
        self:TransitionToUI(UI_STATES.GAMEPLAY_HUD)
        self:PlayAudio("GameplayMusic", true, 0.7)
        isInGame = true
        
    elseif newState == GAME_STATES.GAME_OVER then
        self:TransitionToUI(UI_STATES.GAME_OVER)
        self:StopAudio("GameplayMusic")
        isInGame = false
        
    elseif newState == GAME_STATES.RESETTING then
        -- Show loading or keep current UI
        self:ShowNotification("Game resetting...", 2)
    end
    
    -- Trigger screen effects for state changes
    if ScreenEffectsController then
        ScreenEffectsController:OnGameStateChanged(newState, oldState)
    end
end

function MainGameController:OnGameStarted(gameData)
    print("🚀 Game started with data:", gameData)
    
    -- Reset player stats
    playerScore = 0
    playerLives = gameData.maxLives or 3
    gameTimeRemaining = gameData.gameTime or 60
    
    -- Update UI
    self:UpdateScore(0)
    self:UpdateLives(playerLives)
    self:UpdateTimer(gameTimeRemaining)
    
    -- Play start sound
    self:PlayAudio("CountdownSound", false, 0.8)
    
    -- Show start notification
    self:ShowNotification("Game Started! Good luck!", 3)
end

function MainGameController:OnGameEnded(results)
    print("🏁 Game ended with results:", results)
    
    -- Stop gameplay music
    self:StopAudio("GameplayMusic")
    
    -- Determine if player won or lost
    local playerWon = false
    if results.winners then
        for _, winner in pairs(results.winners) do
            if winner.player == player then
                playerWon = true
                break
            end
        end
    end
    
    -- Play appropriate sound and show results
    if playerWon then
        self:PlayAudio("VictorySound", false, 1.0)
        self:ShowGameOverResults("VICTORY!", results)
        if ScreenEffectsController then
            ScreenEffectsController:TriggerVictoryEffect()
        end
    else
        self:PlayAudio("DefeatSound", false, 1.0)
        self:ShowGameOverResults("GAME OVER", results)
        if ScreenEffectsController then
            ScreenEffectsController:TriggerDefeatEffect()
        end
    end
end

function MainGameController:OnCountdownUpdate(timeLeft)
    print("⏰ Countdown update: " .. timeLeft)
    
    -- Update countdown UI
    if UIElements.countdownNumberLabel then
        UIElements.countdownNumberLabel.Text = tostring(timeLeft)
        
        -- Animate countdown number
        local scaleUpTween = TweenService:Create(
            UIElements.countdownNumberLabel,
            TweenInfo.new(0.2, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
            {Size = UDim2.new(1.2, 0, 1.2, 0)}
        )
        
        local scaleDownTween = TweenService:Create(
            UIElements.countdownNumberLabel,
            TweenInfo.new(0.3, Enum.EasingStyle.Quart, Enum.EasingDirection.Out),
            {Size = UDim2.new(1, 0, 1, 0)}
        )
        
        scaleUpTween:Play()
        scaleUpTween.Completed:Connect(function()
            scaleDownTween:Play()
        end)
    end
    
    -- Play countdown sound
    if timeLeft > 0 then
        self:PlayAudio("CountdownSound", false, 0.8)
    end
    
    -- Special handling for final countdown
    if timeLeft == 1 then
        if UIElements.countdownTextLabel then
            UIElements.countdownTextLabel.Text = "GO!"
        end
    elseif timeLeft <= 3 then
        if UIElements.countdownTextLabel then
            UIElements.countdownTextLabel.Text = "Get Ready!"
        end
    end
end

function MainGameController:OnGameTimerUpdate(timeRemaining)
    gameTimeRemaining = timeRemaining
    self:UpdateTimer(timeRemaining)
    
    -- Warning effects for low time
    if timeRemaining <= 10 and timeRemaining > 0 then
        if UIElements.timerLabel then
            UIElements.timerLabel.TextColor3 = Color3.fromRGB(220, 80, 80) -- Red warning
        end
        
        if timeRemaining <= 5 then
            -- Pulse effect for critical time
            local pulseAnimation = TweenService:Create(
                UIElements.timerLabel,
                TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut, -1, true),
                {TextTransparency = 0.3}
            )
            pulseAnimation:Play()
        end
    else
        if UIElements.timerLabel then
            UIElements.timerLabel.TextColor3 = Color3.fromRGB(220, 220, 220) -- Normal white
        end
    end
end

function MainGameController:OnGameWarning(warningType, data)
    print("⚠️ Game warning: " .. warningType, data)
    
    if warningType == "time_warning" then
        self:ShowNotification("⏰ " .. data.timeLeft .. " seconds remaining!", 3)
    elseif warningType == "low_lives" then
        self:ShowNotification("💗 Low lives remaining!", 2)
    elseif warningType == "final_warning" then
        self:ShowNotification("🚨 FINAL WARNING!", 3)
    end
end

-- ========================================
-- PLAYER EVENT HANDLERS
-- ========================================

function MainGameController:OnPlayerJoinedGame(playerData)
    print("👥 Player joined: " .. (playerData.name or "Unknown"))
    
    -- Update waiting room player list
    self:UpdateWaitingRoomPlayerList()
    
    -- Show notification
    self:ShowNotification(playerData.name .. " joined the game", 2)
end

function MainGameController:OnPlayerLeftGame(playerData)
    print("👋 Player left: " .. (playerData.name or "Unknown"))
    
    -- Update waiting room player list
    self:UpdateWaitingRoomPlayerList()
    
    -- Show notification
    self:ShowNotification(playerData.name .. " left the game", 2)
end

function MainGameController:OnPlayerWon(winData)
    print("🏆 Player won:", winData)
    
    if winData.player == player then
        -- Local player won
        self:ShowNotification("🏆 VICTORY! You won!", 5)
        if ScreenEffectsController then
            ScreenEffectsController:TriggerVictoryEffect()
        end
    else
        -- Another player won
        self:ShowNotification("🏆 " .. winData.playerName .. " won!", 3)
    end
end

function MainGameController:OnPlayerLost(lossData)
    print("💀 Player lost:", lossData)
    
    if lossData.player == player then
        -- Local player lost
        self:ShowNotification("💀 You were eliminated!", 4)
        if ScreenEffectsController then
            ScreenEffectsController:TriggerDeathEffect()
        end
    else
        -- Another player lost
        self:ShowNotification("💀 " .. lossData.playerName .. " was eliminated", 2)
    end
end

function MainGameController:OnPlayerDied(deathData)
    print("☠️ Player died:", deathData)
    
    if deathData.player == player then
        -- Local player died
        playerLives = deathData.livesRemaining or 0
        self:UpdateLives(playerLives)
        
        self:PlayAudio("LiveLostSound", false, 0.8)
        
        if playerLives > 0 then
            self:ShowNotification("💗 Life lost! " .. playerLives .. " remaining", 3)
        else
            self:ShowNotification("💀 No lives remaining!", 4)
        end
        
        -- Trigger death screen effect
        if ScreenEffectsController then
            ScreenEffectsController:TriggerDeathEffect()
        end
    end
end

-- ========================================
-- GAMEPLAY EVENT HANDLERS
-- ========================================

function MainGameController:OnScoreUpdated(newScore, scoreDifference, reason)
    print("📊 Score updated: " .. newScore .. " (+" .. (scoreDifference or 0) .. ")")
    
    playerScore = newScore
    self:UpdateScore(newScore)
    
    -- Show score increase effect
    if scoreDifference and scoreDifference > 0 then
        self:ShowScorePopup("+" .. scoreDifference, reason)
        self:PlayAudio("ScoreSound", false, 0.6)
    end
end

function MainGameController:OnObstacleHit(hitData)
    print("💥 Obstacle hit:", hitData)
    
    -- Trigger screen shake effect
    if ScreenEffectsController then
        ScreenEffectsController:TriggerImpactEffect()
    end
    
    -- Show hit notification
    if hitData.damage and hitData.damage > 0 then
        self:ShowNotification("💥 Hit! -" .. hitData.damage .. " health", 2)
    end
end

function MainGameController:OnCollectibleCollected(collectData)
    print("⭐ Collectible collected:", collectData)
    
    -- Show collection effect
    if collectData.value and collectData.value > 0 then
        self:ShowScorePopup("+" .. collectData.value, "collectible")
    end
    
    -- Trigger collection effect
    if ScreenEffectsController then
        ScreenEffectsController:TriggerCollectionEffect()
    end
end

function MainGameController:OnColorChanged(newColor)
    print("🎨 Color changed to:", newColor)
    
    -- Update color indicator
    if UIElements.colorIndicator then
        UIElements.colorIndicator.BackgroundColor3 = newColor
        
        -- Pulse animation for color change
        local pulseTween = TweenService:Create(
            UIElements.colorIndicator,
            TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut, 1, true),
            {Size = UDim2.new(1.2, 0, 1.2, 0)}
        )
        pulseTween:Play()
    end
end

function MainGameController:OnComboUpdated(comboCount, multiplier)
    print("🔥 Combo updated: " .. comboCount .. "x (multiplier: " .. multiplier .. ")")
    
    -- Update combo display
    if UIElements.comboLabel then
        if comboCount > 1 then
            UIElements.comboLabel.Text = "COMBO x" .. comboCount
            UIElements.comboLabel.Visible = true
            
            -- Animate combo text
            local bounceAnimation = TweenService:Create(
                UIElements.comboLabel,
                TweenInfo.new(0.2, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
                {Size = UDim2.new(1.1, 0, 1.1, 0)}
            )
            bounceAnimation:Play()
            
            bounceAnimation.Completed:Connect(function()
                local returnAnimation = TweenService:Create(
                    UIElements.comboLabel,
                    TweenInfo.new(0.1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
                    {Size = UDim2.new(1, 0, 1, 0)}
                )
                returnAnimation:Play()
            end)
        else
            UIElements.comboLabel.Visible = false
        end
    end
end

-- ========================================
-- UI TRANSITION METHODS
-- ========================================

function MainGameController:TransitionToUI(newUIState)
    print("🖼️ Transitioning to UI state: " .. newUIState)
    
    local oldUIState = currentUIState
    currentUIState = newUIState
    
    -- Hide all UI first
    self:HideAllUI()
    
    -- Show relevant UI
    if newUIState == UI_STATES.MAIN_MENU then
        self:ShowMainMenu()
    elseif newUIState == UI_STATES.WAITING_ROOM then
        self:ShowWaitingRoom()
    elseif newUIState == UI_STATES.COUNTDOWN then
        self:ShowCountdown()
    elseif newUIState == UI_STATES.GAMEPLAY_HUD then
        self:ShowGameplayHUD()
    elseif newUIState == UI_STATES.GAME_OVER then
        self:ShowGameOver()
    elseif newUIState == UI_STATES.SPECTATING then
        self:ShowSpectatingUI()
    end
    
    -- Play UI transition sound
    self:PlayAudio("UIClickSound", false, 0.4)
end

function MainGameController:HideAllUI()
    local uiElements = {
        UIElements.mainMenuGui,
        UIElements.waitingRoomGui,
        UIElements.countdownGui,
        UIElements.gameplayHudGui,
        UIElements.gameOverGui
    }
    
    for _, element in pairs(uiElements) do
        if element then
            element.Visible = false
        end
    end
end

function MainGameController:ShowMainMenu()
    if UIElements.mainMenuGui then
        UIElements.mainMenuGui.Visible = true
        
        -- Animate main menu entrance
        if UIElements.titleLabel then
            local slideInTween = TweenService:Create(
                UIElements.titleLabel,
                TweenInfo.new(0.8, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
                {Position = UDim2.new(0.5, 0, 0.2, 0)}
            )
            slideInTween:Play()
        end
    end
end

function MainGameController:ShowWaitingRoom()
    if UIElements.waitingRoomGui then
        UIElements.waitingRoomGui.Visible = true
        self:UpdateWaitingRoomPlayerList()
    end
end

function MainGameController:ShowCountdown()
    if UIElements.countdownGui then
        UIElements.countdownGui.Visible = true
        
        -- Reset countdown text
        if UIElements.countdownTextLabel then
            UIElements.countdownTextLabel.Text = "Get Ready!"
        end
    end
end

function MainGameController:ShowGameplayHUD()
    if UIElements.gameplayHudGui then
        UIElements.gameplayHudGui.Visible = true
        
        -- Update all HUD elements
        self:UpdateScore(playerScore)
        self:UpdateLives(playerLives)
        self:UpdateTimer(gameTimeRemaining)
    end
end

function MainGameController:ShowGameOver()
    if UIElements.gameOverGui then
        UIElements.gameOverGui.Visible = true
        
        -- Update final score
        if UIElements.finalScoreLabel then
            UIElements.finalScoreLabel.Text = "Final Score: " .. playerScore
        end
    end
end

function MainGameController:ShowSpectatingUI()
    -- Show minimal spectating UI
    if UIElements.gameplayHudGui then
        UIElements.gameplayHudGui.Visible = true
        
        -- Hide personal stats, show spectator text
        if UIElements.scoreLabel then
            UIElements.scoreLabel.Text = "SPECTATING"
        end
    end
end

-- ========================================
-- UI UPDATE METHODS
-- ========================================

function MainGameController:UpdateScore(score)
    if UIElements.scoreLabel then
        UIElements.scoreLabel.Text = "Score: " .. score
    end
end

function MainGameController:UpdateLives(lives)
    if UIElements.livesLabel then
        UIElements.livesLabel.Text = "Lives: " .. lives
        
        -- Change color based on lives remaining
        if lives <= 1 then
            UIElements.livesLabel.TextColor3 = Color3.fromRGB(220, 80, 80) -- Red
        elseif lives <= 2 then
            UIElements.livesLabel.TextColor3 = Color3.fromRGB(220, 180, 60) -- Yellow
        else
            UIElements.livesLabel.TextColor3 = Color3.fromRGB(80, 220, 80) -- Green
        end
    end
end

function MainGameController:UpdateTimer(timeRemaining)
    if UIElements.timerLabel then
        local minutes = math.floor(timeRemaining / 60)
        local seconds = timeRemaining % 60
        UIElements.timerLabel.Text = string.format("%d:%02d", minutes, seconds)
    end
end

function MainGameController:UpdateWaitingRoomPlayerList()
    -- This would be implemented to show current players in waiting room
    if UIElements.playersCountLabel then
        UIElements.playersCountLabel.Text = "Players: " .. #Players:GetPlayers() .. "/12"
    end
end

function MainGameController:ShowGameOverResults(resultText, results)
    if UIElements.resultLabel then
        UIElements.resultLabel.Text = resultText
    end
    
    if UIElements.finalScoreLabel then
        UIElements.finalScoreLabel.Text = "Final Score: " .. playerScore
    end
    
    -- Show additional stats if available
    if UIElements.statsFrame and results then
        -- Populate stats frame with game results
        -- This could include time survived, obstacles hit, collectibles collected, etc.
    end
end

-- ========================================
-- UI BUTTON HANDLERS
-- ========================================

function MainGameController:OnPlayButtonClicked()
    print("🎮 Play button clicked")
    self:PlayAudio("UIClickSound", false, 0.6)
    
    -- Request to join game
    if Events.RequestJoinGame then
        Events.RequestJoinGame:FireServer()
    end
end

function MainGameController:OnSettingsButtonClicked()
    print("⚙️ Settings button clicked")
    self:PlayAudio("UIClickSound", false, 0.6)
    
    -- Open settings menu (would be implemented)
    self:ShowNotification("Settings menu - Coming soon!", 2)
end

function MainGameController:OnShopButtonClicked()
    print("🛒 Shop button clicked")
    self:PlayAudio("UIClickSound", false, 0.6)
    
    -- Open shop (would be implemented)
    self:ShowNotification("Shop - Coming soon!", 2)
end

function MainGameController:OnLeaderboardButtonClicked()
    print("🏆 Leaderboard button clicked")
    self:PlayAudio("UIClickSound", false, 0.6)
    
    -- Open leaderboard (would be implemented)
    self:ShowNotification("Leaderboard - Coming soon!", 2)
end

function MainGameController:OnLeaveButtonClicked()
    print("🚪 Leave button clicked")
    self:PlayAudio("UIClickSound", false, 0.6)
    
    -- Request to leave game
    if Events.RequestLeaveGame then
        Events.RequestLeaveGame:FireServer()
    end
end

function MainGameController:OnPlayAgainButtonClicked()
    print("🔄 Play again button clicked")
    self:PlayAudio("UIClickSound", false, 0.6)
    
    -- Request to join new game
    if Events.RequestJoinGame then
        Events.RequestJoinGame:FireServer()
    end
end

function MainGameController:OnMainMenuButtonClicked()
    print("🏠 Main menu button clicked")
    self:PlayAudio("UIClickSound", false, 0.6)
    
    -- Return to main menu
    self:TransitionToUI(UI_STATES.MAIN_MENU)
end

function MainGameController:OnPauseButtonClicked()
    print("⏸️ Pause button clicked")
    self:PlayAudio("UIClickSound", false, 0.6)
    
    -- Show pause menu (would be implemented)
    self:ShowNotification("Game paused", 2)
end

-- ========================================
-- UTILITY METHODS
-- ========================================

function MainGameController:ShowNotification(message, duration)
    print("📢 Notification: " .. message)
    
    -- Create or update notification UI
    if not UIElements.notificationFrame then
        self:CreateNotificationFrame()
    end
    
    if UIElements.notificationFrame then
        local notificationLabel = UIElements.notificationFrame:FindFirstChild("NotificationLabel")
        if notificationLabel then
            notificationLabel.Text = message
            UIElements.notificationFrame.Visible = true
            
            -- Animate notification
            local slideInTween = TweenService:Create(
                UIElements.notificationFrame,
                TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
                {Position = UDim2.new(0.5, 0, 0.1, 0)}
            )
            slideInTween:Play()
            
            -- Auto-hide after duration
            spawn(function()
                wait(duration or 3)
                local slideOutTween = TweenService:Create(
                    UIElements.notificationFrame,
                    TweenInfo.new(0.3, Enum.EasingStyle.Quart, Enum.EasingDirection.In),
                    {Position = UDim2.new(0.5, 0, -0.1, 0)}
                )
                slideOutTween:Play()
                slideOutTween.Completed:Connect(function()
                    UIElements.notificationFrame.Visible = false
                end)
            end)
        end
    end
end

function MainGameController:CreateNotificationFrame()
    local notificationFrame = Instance.new("Frame")
    notificationFrame.Name = "NotificationFrame"
    notificationFrame.Size = UDim2.new(0.4, 0, 0.08, 0)
    notificationFrame.Position = UDim2.new(0.5, 0, -0.1, 0)
    notificationFrame.AnchorPoint = Vector2.new(0.5, 0.5)
    notificationFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
    notificationFrame.BorderSizePixel = 0
    notificationFrame.Visible = false
    notificationFrame.Parent = playerGui
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 8)
    corner.Parent = notificationFrame
    
    local stroke = Instance.new("UIStroke")
    stroke.Color = Color3.fromRGB(100, 100, 100)
    stroke.Thickness = 1
    stroke.Parent = notificationFrame
    
    local notificationLabel = Instance.new("TextLabel")
    notificationLabel.Name = "NotificationLabel"
    notificationLabel.Size = UDim2.new(1, 0, 1, 0)
    notificationLabel.Position = UDim2.new(0, 0, 0, 0)
    notificationLabel.BackgroundTransparency = 1
    notificationLabel.Text = "Notification"
    notificationLabel.TextColor3 = Color3.fromRGB(220, 220, 220)
    notificationLabel.TextScaled = true
    notificationLabel.Font = Enum.Font.GothamBold
    notificationLabel.Parent = notificationFrame
    
    UIElements.notificationFrame = notificationFrame
end

function MainGameController:ShowScorePopup(scoreText, reason)
    -- Create floating score popup
    local popup = Instance.new("TextLabel")
    popup.Size = UDim2.new(0.1, 0, 0.05, 0)
    popup.Position = UDim2.new(0.5, 0, 0.5, 0)
    popup.AnchorPoint = Vector2.new(0.5, 0.5)
    popup.BackgroundTransparency = 1
    popup.Text = scoreText
    popup.TextColor3 = Color3.fromRGB(80, 220, 80)
    popup.TextScaled = true
    popup.Font = Enum.Font.GothamBold
    popup.TextStrokeTransparency = 0
    popup.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
    popup.Parent = playerGui
    
    -- Animate popup
    local moveTween = TweenService:Create(
        popup,
        TweenInfo.new(1.5, Enum.EasingStyle.Quart, Enum.EasingDirection.Out),
        {Position = UDim2.new(0.5, 0, 0.3, 0), TextTransparency = 1}
    )
    moveTween:Play()
    
    moveTween.Completed:Connect(function()
        popup:Destroy()
    end)
end

function MainGameController:PlayAudio(audioName, loop, volume)
    local audio = AudioElements[audioName]
    if audio then
        audio.Looped = loop or false
        audio.Volume = volume or 0.5
        audio:Play()
    end
end

function MainGameController:StopAudio(audioName)
    local audio = AudioElements[audioName]
    if audio then
        audio:Stop()
    end
end

-- ========================================
-- PUBLIC API
-- ========================================

function MainGameController:GetCurrentGameState()
    return currentGameState
end

function MainGameController:GetCurrentUIState()
    return currentUIState
end

function MainGameController:IsInGame()
    return isInGame
end

function MainGameController:GetPlayerScore()
    return playerScore
end

function MainGameController:GetPlayerLives()
    return playerLives
end

-- Initialize the controller
MainGameController:Init()

return MainGameController
