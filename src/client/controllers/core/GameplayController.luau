-- EnhancedGameplayController.luau
-- Client-side gameplay controller with multi-difficulty support and visual polish

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local SoundService = game:GetService("SoundService")

local player = Players.LocalPlayer
local RemoteEvents = require(ReplicatedStorage.Shared.modules.RemoteEvents)

-- Import UI controller for enhanced visuals
local EnhancedUIController = require(script.Parent.Parent.ui.EnhancedUIController)

local EnhancedGameplayController = {}

-- Game state
local isInGame = false
local currentDifficulty = nil
local gameConfig = nil
local gameUI = nil
local currentColor = "Red"
local connections = {}
local visualEffects = {}

-- Difficulty UI colors
local DIFFICULTY_COLORS = {
    Easy = Color3.fromRGB(85, 255, 85),
    Medium = Color3.fromRGB(255, 255, 85), 
    Hard = Color3.fromRGB(255, 85, 85)
}

-- Color mappings
local COLORS = {
    Red = {color = Color3.fromRGB(255, 100, 100), key = "Q"},
    Green = {color = Color3.fromRGB(100, 255, 100), key = "W"},
    Blue = {color = Color3.fromRGB(100, 150, 255), key = "E"},
    Yellow = {color = Color3.fromRGB(255, 255, 100), key = "R"}
}

function EnhancedGameplayController:Init()
    print("🎮 Initializing Enhanced Gameplay Controller...")
    
    self:SetupRemoteEvents()
    self:SetupInputHandling()
    
    print("✅ Enhanced Gameplay Controller initialized!")
end

function EnhancedGameplayController:SetupRemoteEvents()
    -- Game started with difficulty info
    RemoteEvents.GameStarted.OnClientEvent:Connect(function(difficulty, config)
        self:StartGame(difficulty, config)
    end)
    
    -- Game timer updates
    RemoteEvents.GameTimer.OnClientEvent:Connect(function(timeRemaining)
        self:UpdateTimer(timeRemaining)
    end)
    
    -- Color change confirmation
    RemoteEvents.ColorChanged.OnClientEvent:Connect(function(newColor)
        self:UpdateCurrentColor(newColor)
    end)
    
    -- Game results
    RemoteEvents.GameResults.OnClientEvent:Connect(function(results)
        self:ShowResults(results)
    end)
    
    -- Game ended
    RemoteEvents.GameEnded.OnClientEvent:Connect(function()
        self:EndGame()
    end)
end

function EnhancedGameplayController:SetupInputHandling()
    -- Color switching inputs
    UserInputService.InputBegan:Connect(function(input, gameProcessed)
        if gameProcessed or not isInGame then return end
        
        local keyPressed = input.KeyCode.Name
        local targetColor = nil
        
        -- Map keys to colors
        for colorName, colorData in pairs(COLORS) do
            if keyPressed == colorData.key then
                targetColor = colorName
                break
            end
        end
        
        if targetColor and targetColor ~= currentColor then
            -- Send color change to server
            RemoteEvents.ColorChanged:FireServer(targetColor)
            
            -- Play color change sound
            self:PlayColorChangeSound()
        end
    end)
end

function EnhancedGameplayController:StartGame(difficulty, config)
    print("🎮 Starting " .. difficulty .. " game on client...")
    
    isInGame = true
    currentDifficulty = difficulty
    gameConfig = config
    currentColor = "Red"
    
    -- Create game UI
    self:CreateGameUI()
    
    -- Start collision detection
    self:StartCollisionDetection()
    
    -- Play start sound
    self:PlayGameStartSound()
end

function EnhancedGameplayController:CreateGameUI()
    local playerGui = player:WaitForChild("PlayerGui")
    
    -- Remove existing game UI
    if gameUI then
        gameUI:Destroy()
    end
    
    -- Create main game UI with enhanced visuals
    gameUI = Instance.new("ScreenGui")
    gameUI.Name = "EnhancedGameplayUI"
    gameUI.ResetOnSpawn = false
    gameUI.Parent = playerGui
    
    -- Main frame with animated background
    local mainFrame = EnhancedUIController:CreateAnimatedFrame({
        name = "GameMainFrame",
        parent = gameUI,
        size = UDim2.new(1, 0, 1, 0),
        position = UDim2.new(0, 0, 0, 0),
        style = "game",
        animate = true,
        animationType = "fadeIn"
    })
    
    -- Difficulty indicator with custom styling
    local difficultyFrame = EnhancedUIController:CreateAnimatedFrame({
        name = "DifficultyFrame",
        parent = mainFrame,
        size = UDim2.new(0, 350, 0, 80),
        position = UDim2.new(0.5, -175, 0, 10),
        style = "popup",
        glow = true,
        glowColor = DIFFICULTY_COLORS[currentDifficulty],
        animate = true,
        animationType = "slideIn"
    })
    
    local difficultyLabel = Instance.new("TextLabel")
    difficultyLabel.Name = "DifficultyLabel"
    difficultyLabel.Size = UDim2.new(1, -20, 1, -20)
    difficultyLabel.Position = UDim2.new(0, 10, 0, 10)
    difficultyLabel.BackgroundTransparency = 1
    difficultyLabel.Text = "🏃 " .. currentDifficulty:upper() .. " MODE 🏃"
    difficultyLabel.TextColor3 = DIFFICULTY_COLORS[currentDifficulty]
    difficultyLabel.TextScaled = true
    difficultyLabel.Font = Enum.Font.SourceSansBold
    difficultyLabel.TextStrokeTransparency = 0
    difficultyLabel.TextStrokeColor3 = Color3.new(0, 0, 0)
    difficultyLabel.Parent = difficultyFrame
    
    -- Animated timer display with icon
    local timerFrame = EnhancedUIController:CreateAnimatedFrame({
        name = "TimerFrame",
        parent = mainFrame,
        size = UDim2.new(0, 250, 0, 100),
        position = UDim2.new(0.5, -125, 0, 100),
        style = "popup",
        glow = true,
        glowColor = Color3.new(1, 1, 1),
        animate = true,
        animationType = "bounce"
    })
    
    local timerIcon = Instance.new("ImageLabel")
    timerIcon.Name = "TimerIcon"
    timerIcon.Size = UDim2.new(0, 40, 0, 40)
    timerIcon.Position = UDim2.new(0, 10, 0.5, -20)
    timerIcon.BackgroundTransparency = 1
    timerIcon.Image = EnhancedUIController:GetUIConfig().icons.timer
    timerIcon.ImageColor3 = Color3.new(1, 1, 1)
    timerIcon.Parent = timerFrame
    
    local timerLabel = Instance.new("TextLabel")
    timerLabel.Name = "TimerLabel"
    timerLabel.Size = UDim2.new(1, -60, 1, 0)
    timerLabel.Position = UDim2.new(0, 60, 0, 0)
    timerLabel.BackgroundTransparency = 1
    timerLabel.Text = "TIME: " .. gameConfig.gameDuration
    timerLabel.TextColor3 = Color3.new(1, 1, 1)
    timerLabel.TextScaled = true
    timerLabel.Font = Enum.Font.SourceSansBold
    timerLabel.TextStrokeTransparency = 0
    timerLabel.TextStrokeColor3 = Color3.new(0, 0, 0)
    timerLabel.Parent = timerFrame
    
    -- Enhanced score display with progress bar
    local scoreFrame = EnhancedUIController:CreateAnimatedFrame({
        name = "ScoreFrame",
        parent = mainFrame,
        size = UDim2.new(0, 200, 0, 80),
        position = UDim2.new(0, 20, 0, 120),
        style = "popup",
        animate = true
    })
    
    local scoreLabel = Instance.new("TextLabel")
    scoreLabel.Name = "ScoreLabel"
    scoreLabel.Size = UDim2.new(1, 0, 0.6, 0)
    scoreLabel.BackgroundTransparency = 1
    scoreLabel.Text = "SCORE: 0"
    scoreLabel.TextColor3 = Color3.new(1, 1, 1)
    scoreLabel.TextScaled = true
    scoreLabel.Font = Enum.Font.SourceSansBold
    scoreLabel.Parent = scoreFrame
    
    -- Score progress bar
    local scoreProgress = EnhancedUIController:CreateProgressBar({
        name = "ScoreProgress",
        parent = scoreFrame,
        size = UDim2.new(1, -20, 0, 15),
        position = UDim2.new(0, 10, 0.7, 0),
        color = Color3.fromRGB(100, 255, 100)
    })
    
    -- Enhanced coins display with animated icon
    local coinsFrame = EnhancedUIController:CreateAnimatedFrame({
        name = "CoinsFrame", 
        parent = mainFrame,
        size = UDim2.new(0, 200, 0, 60),
        position = UDim2.new(0, 20, 0, 210),
        style = "popup",
        animate = true
    })
    
    local coinIcon = Instance.new("ImageLabel")
    coinIcon.Name = "CoinIcon"
    coinIcon.Size = UDim2.new(0, 30, 0, 30)
    coinIcon.Position = UDim2.new(0, 10, 0.5, -15)
    coinIcon.BackgroundTransparency = 1
    coinIcon.Image = EnhancedUIController:GetUIConfig().icons.coin
    coinIcon.ImageColor3 = COLORS.Yellow.color
    coinIcon.Parent = coinsFrame
    
    -- Spinning coin animation
    local coinSpin = TweenService:Create(
        coinIcon,
        TweenInfo.new(2, Enum.EasingStyle.Linear, Enum.EasingDirection.InOut, -1),
        {Rotation = 360}
    )
    coinSpin:Play()
    
    local coinsLabel = Instance.new("TextLabel")
    coinsLabel.Name = "CoinsLabel"
    coinsLabel.Size = UDim2.new(1, -50, 1, 0)
    coinsLabel.Position = UDim2.new(0, 50, 0, 0)
    coinsLabel.BackgroundTransparency = 1
    coinsLabel.Text = "COINS: 0"
    coinsLabel.TextColor3 = COLORS.Yellow.color
    coinsLabel.TextScaled = true
    coinsLabel.Font = Enum.Font.SourceSansBold
    coinsLabel.Parent = coinsFrame
    
    -- Enhanced current color display with animations
    local colorFrame = EnhancedUIController:CreateAnimatedFrame({
        name = "ColorFrame",
        parent = mainFrame,
        size = UDim2.new(0, 140, 0, 140),
        position = UDim2.new(1, -160, 0, 120),
        style = "popup",
        glow = true,
        glowColor = COLORS[currentColor].color,
        animate = true,
        animationType = "bounce"
    })
    
    -- Color display background
    local colorDisplay = Instance.new("Frame")
    colorDisplay.Name = "ColorDisplay"
    colorDisplay.Size = UDim2.new(1, -20, 1, -20)
    colorDisplay.Position = UDim2.new(0, 10, 0, 10)
    colorDisplay.BackgroundColor3 = COLORS[currentColor].color
    colorDisplay.BorderSizePixel = 3
    colorDisplay.BorderColor3 = Color3.new(1, 1, 1)
    colorDisplay.Parent = colorFrame
    
    local colorCorner = Instance.new("UICorner")
    colorCorner.CornerRadius = UDim.new(0, 20)
    colorCorner.Parent = colorDisplay
    
    local colorLabel = Instance.new("TextLabel")
    colorLabel.Name = "ColorLabel"
    colorLabel.Size = UDim2.new(1, 0, 1, 0)
    colorLabel.BackgroundTransparency = 1
    colorLabel.Text = currentColor:upper()
    colorLabel.TextColor3 = Color3.new(1, 1, 1)
    colorLabel.TextScaled = true
    colorLabel.Font = Enum.Font.SourceSansBold
    colorLabel.TextStrokeTransparency = 0
    colorLabel.TextStrokeColor3 = Color3.new(0, 0, 0)
    colorLabel.Parent = colorDisplay
    
    -- Enhanced controls help with visual key indicators
    local controlsFrame = EnhancedUIController:CreateAnimatedFrame({
        name = "ControlsFrame",
        parent = mainFrame,
        size = UDim2.new(0, 320, 0, 120),
        position = UDim2.new(1, -340, 1, -140),
        style = "popup",
        animate = true,
        animationType = "slideIn"
    })
    
    -- Create visual key buttons
    local keyPositions = {
        Q = UDim2.new(0, 10, 0, 10),
        W = UDim2.new(0, 80, 0, 10),
        E = UDim2.new(0, 150, 0, 10),
        R = UDim2.new(0, 220, 0, 10)
    }
    
    local keyColors = {Q = "Red", W = "Green", E = "Blue", R = "Yellow"}
    
    for key, pos in pairs(keyPositions) do
        local keyButton = EnhancedUIController:CreateCustomButton({
            name = "Key" .. key,
            parent = controlsFrame,
            size = UDim2.new(0, 60, 0, 40),
            position = pos,
            text = key,
            style = "secondary",
            font = Enum.Font.SourceSansBold
        })
        
        -- Color the button based on the color it represents
        local bgFrame = keyButton:FindFirstChild("ButtonBackground")
        if bgFrame then
            bgFrame.ImageColor3 = COLORS[keyColors[key]].color
        end
        
        -- Add color name label
        local colorNameLabel = Instance.new("TextLabel")
        colorNameLabel.Size = UDim2.new(1, 0, 0, 20)
        colorNameLabel.Position = UDim2.new(0, 0, 1, 5)
        colorNameLabel.BackgroundTransparency = 1
        colorNameLabel.Text = keyColors[key]
        colorNameLabel.TextColor3 = COLORS[keyColors[key]].color
        colorNameLabel.TextScaled = true
        colorNameLabel.Font = Enum.Font.SourceSans
        colorNameLabel.Parent = keyButton
    end
    
    -- Speed multiplier indicator with animated icon
    local speedFrame = EnhancedUIController:CreateAnimatedFrame({
        name = "SpeedFrame",
        parent = mainFrame,
        size = UDim2.new(0, 220, 0, 50),
        position = UDim2.new(0, 20, 0, 280),
        style = "popup",
        animate = true
    })
    
    local speedIcon = Instance.new("ImageLabel")
    speedIcon.Name = "SpeedIcon"
    speedIcon.Size = UDim2.new(0, 30, 0, 30)
    speedIcon.Position = UDim2.new(0, 10, 0.5, -15)
    speedIcon.BackgroundTransparency = 1
    speedIcon.Image = EnhancedUIController:GetUIConfig().icons.speed
    speedIcon.ImageColor3 = DIFFICULTY_COLORS[currentDifficulty]
    speedIcon.Parent = speedFrame
    
    -- Speed icon pulse animation
    local speedPulse = TweenService:Create(
        speedIcon,
        TweenInfo.new(1, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true),
        {Size = UDim2.new(0, 35, 0, 35)}
    )
    speedPulse:Play()
    
    local speedLabel = Instance.new("TextLabel")
    speedLabel.Name = "SpeedLabel"
    speedLabel.Size = UDim2.new(1, -50, 1, 0)
    speedLabel.Position = UDim2.new(0, 50, 0, 0)
    speedLabel.BackgroundTransparency = 1
    speedLabel.Text = "SPEED: " .. gameConfig.speedMultiplier .. "x"
    speedLabel.TextColor3 = DIFFICULTY_COLORS[currentDifficulty]
    speedLabel.TextScaled = true
    speedLabel.Font = Enum.Font.SourceSansBold
    speedLabel.Parent = speedFrame
    
    print("✅ Enhanced game UI created for " .. currentDifficulty .. " mode")
end

function EnhancedGameplayController:StartCollisionDetection()
    if not player.Character then return end
    
    local humanoidRootPart = player.Character:FindFirstChild("HumanoidRootPart")
    if not humanoidRootPart then return end
    
    -- Continuous collision detection
    connections.collisionDetection = RunService.Heartbeat:Connect(function()
        if not isInGame or not humanoidRootPart then return end
        
        local character = player.Character
        if not character then return end
        
        -- Check for nearby objects
        local region = Region3.new(
            humanoidRootPart.Position - Vector3.new(5, 5, 5),
            humanoidRootPart.Position + Vector3.new(5, 5, 5)
        )
        
        local parts = game.Workspace:ReadVoxels(region, 4)
        
        for _, part in pairs(game.Workspace:GetPartBoundsInRegion(region, math.huge, math.huge)) do
            if part:GetAttribute("IsCoin") then
                self:HandleCoinCollection(part)
            elseif part:GetAttribute("IsObstacle") then
                self:HandleObstacleCollision(part)
            elseif part:GetAttribute("RequiredColor") then
                self:HandleColorGate(part)
            elseif part:GetAttribute("IsFinishLine") then
                self:HandleFinishLine()
            end
        end
    end)
end

function EnhancedGameplayController:HandleCoinCollection(coinPart)
    if coinPart:GetAttribute("Collected") then return end
    
    coinPart:SetAttribute("Collected", true)
    
    -- Enhanced visual effect with particles
    self:CreateCoinCollectionEffect(coinPart.Position)
    
    -- Scale and fade animation
    local originalSize = coinPart.Size
    local collectTween = TweenService:Create(
        coinPart,
        TweenInfo.new(0.4, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
        {
            Size = originalSize * 2,
            Transparency = 1,
            Position = coinPart.Position + Vector3.new(0, 5, 0)
        }
    )
    collectTween:Play()
    
    -- Update UI with animation
    if gameUI then
        local coinsLabel = gameUI:FindFirstChild("GameMainFrame", true) and 
                          gameUI.GameMainFrame:FindFirstChild("CoinsFrame", true) and
                          gameUI.GameMainFrame.CoinsFrame:FindFirstChild("CoinsLabel")
        
        if coinsLabel then
            local currentCoins = tonumber(coinsLabel.Text:match("%d+")) or 0
            coinsLabel.Text = "COINS: " .. (currentCoins + 1)
            
            -- Bounce animation for coin counter
            local originalSize = coinsLabel.Parent.Size
            local bounceUp = TweenService:Create(
                coinsLabel.Parent,
                TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
                {Size = originalSize * 1.2}
            )
            bounceUp:Play()
            
            bounceUp.Completed:Connect(function()
                local bounceDown = TweenService:Create(
                    coinsLabel.Parent,
                    TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
                    {Size = originalSize}
                )
                bounceDown:Play()
            end)
            
            -- Flash effect
            local originalColor = coinsLabel.TextColor3
            coinsLabel.TextColor3 = Color3.new(1, 1, 1)
            
            spawn(function()
                wait(0.1)
                coinsLabel.TextColor3 = originalColor
            end)
        end
    end
    
    -- Notify server
    RemoteEvents.CoinCollected:FireServer(coinPart:GetAttribute("CoinValue") or 10)
    
    -- Enhanced sound with pitch variation
    self:PlayCoinSound()
    
    -- Clean up coin
    game:GetService("Debris"):AddItem(coinPart, 1)
end

function EnhancedGameplayController:HandleObstacleCollision(obstacle)
    if obstacle:GetAttribute("Hit") then return end
    
    obstacle:SetAttribute("Hit", true)
    
    -- Visual feedback
    local originalColor = obstacle.Color
    obstacle.Color = Color3.new(1, 0, 0)
    
    spawn(function()
        wait(0.1)
        obstacle.Color = originalColor
    end)
    
    -- Screen shake effect
    self:ScreenShake()
    
    -- Notify server
    RemoteEvents.ObstacleHit:FireServer()
    
    -- Play impact sound
    self:PlayImpactSound()
    
    print("💥 Hit obstacle!")
end

function EnhancedGameplayController:HandleColorGate(gate)
    if gate:GetAttribute("Passed") then return end
    
    local requiredColor = gate:GetAttribute("RequiredColor")
    local success = requiredColor == currentColor
    
    gate:SetAttribute("Passed", true)
    
    -- Visual feedback
    if success then
        gate.Color = Color3.new(0, 1, 0) -- Green flash
        self:PlaySuccessSound()
    else
        gate.Color = Color3.new(1, 0, 0) -- Red flash
        self:PlayFailSound()
    end
    
    -- Reset color after flash
    spawn(function()
        wait(0.2)
        gate.Color = COLORS[requiredColor].color
    end)
    
    -- Notify server
    RemoteEvents.ColorGateCheck:FireServer(requiredColor, currentColor)
    
    print(success and "✅ Gate passed!" or "❌ Wrong color!")
end

function EnhancedGameplayController:HandleFinishLine()
    if not isInGame then return end
    
    print("🏁 Finished the track!")
    -- Game will end via server timer or distance completion
end

function EnhancedGameplayController:UpdateTimer(timeRemaining)
    if not gameUI then return end
    
    local timerLabel = gameUI.MainFrame.TimerFrame.TimerLabel
    timerLabel.Text = "TIME: " .. math.ceil(timeRemaining)
    
    -- Color change based on time remaining
    if timeRemaining <= 10 then
        timerLabel.TextColor3 = Color3.new(1, 0, 0) -- Red
    elseif timeRemaining <= 30 then
        timerLabel.TextColor3 = Color3.new(1, 1, 0) -- Yellow
    else
        timerLabel.TextColor3 = Color3.new(1, 1, 1) -- White
    end
end

function EnhancedGameplayController:UpdateCurrentColor(newColor)
    currentColor = newColor
    
    if not gameUI then return end
    
    local colorFrame = gameUI.MainFrame.ColorFrame
    local colorLabel = colorFrame.ColorLabel
    
    -- Update color display
    colorFrame.BackgroundColor3 = COLORS[newColor].color
    colorLabel.Text = newColor:upper()
    
    -- Flash effect
    local originalSize = colorFrame.Size
    local tween = TweenService:Create(
        colorFrame,
        TweenInfo.new(0.2, Enum.EasingStyle.Elastic, Enum.EasingDirection.Out),
        {Size = originalSize + UDim2.new(0, 20, 0, 20)}
    )
    tween:Play()
    
    spawn(function()
        wait(0.2)
        local returnTween = TweenService:Create(
            colorFrame,
            TweenInfo.new(0.2, Enum.EasingStyle.Elastic, Enum.EasingDirection.Out),
            {Size = originalSize}
        )
        returnTween:Play()
    end)
    
    print("🎨 Color changed to " .. newColor)
end

function EnhancedGameplayController:ShowResults(results)
    print("🏁 Game completed! Results:", results)
    
    -- Clean up game UI
    if gameUI then
        gameUI:Destroy()
        gameUI = nil
    end
    
    -- Create results UI
    local playerGui = player:WaitForChild("PlayerGui")
    local resultsGui = Instance.new("ScreenGui")
    resultsGui.Name = "GameResults"
    resultsGui.ResetOnSpawn = false
    resultsGui.Parent = playerGui
    
    -- Background
    local background = Instance.new("Frame")
    background.Size = UDim2.new(1, 0, 1, 0)
    background.BackgroundColor3 = Color3.new(0, 0, 0)
    background.BackgroundTransparency = 0.5
    background.BorderSizePixel = 0
    background.Parent = resultsGui
    
    -- Results frame
    local resultsFrame = Instance.new("Frame")
    resultsFrame.Size = UDim2.new(0, 500, 0, 400)
    resultsFrame.Position = UDim2.new(0.5, -250, 0.5, -200)
    resultsFrame.BackgroundColor3 = DIFFICULTY_COLORS[results.difficulty]
    resultsFrame.BorderSizePixel = 0
    resultsFrame.Parent = background
    
    -- Title
    local titleLabel = Instance.new("TextLabel")
    titleLabel.Size = UDim2.new(1, 0, 0, 60)
    titleLabel.Position = UDim2.new(0, 0, 0, 10)
    titleLabel.BackgroundTransparency = 1
    titleLabel.Text = "🏁 " .. results.difficulty:upper() .. " COMPLETE! 🏁"
    titleLabel.TextColor3 = Color3.new(0, 0, 0)
    titleLabel.TextScaled = true
    titleLabel.Font = Enum.Font.SourceSansBold
    titleLabel.Parent = resultsFrame
    
    -- Results text
    local resultsText = string.format(
        "FINAL SCORE: %d\n\n" ..
        "COINS COLLECTED: %d\n" ..
        "GATES PASSED: %d\n" ..
        "OBSTACLES HIT: %d\n\n" ..
        "REWARDS:\n" ..
        "💰 %d Coins\n" ..
        "⭐ %d XP",
        results.score,
        results.coinsCollected,
        results.gatesPassed or 0,
        results.obstaclesHit or 0,
        results.coinReward,
        results.xpReward
    )
    
    local resultsLabel = Instance.new("TextLabel")
    resultsLabel.Size = UDim2.new(1, -40, 1, -140)
    resultsLabel.Position = UDim2.new(0, 20, 0, 80)
    resultsLabel.BackgroundTransparency = 1
    resultsLabel.Text = resultsText
    resultsLabel.TextColor3 = Color3.new(0, 0, 0)
    resultsLabel.TextScaled = true
    resultsLabel.Font = Enum.Font.SourceSans
    resultsLabel.Parent = resultsFrame
    
    -- Return button
    local returnButton = Instance.new("TextButton")
    returnButton.Size = UDim2.new(0, 200, 0, 50)
    returnButton.Position = UDim2.new(0.5, -100, 1, -70)
    returnButton.BackgroundColor3 = Color3.new(0, 0, 0)
    returnButton.BorderSizePixel = 0
    returnButton.Text = "RETURN TO HUB"
    returnButton.TextColor3 = Color3.new(1, 1, 1)
    returnButton.TextScaled = true
    returnButton.Font = Enum.Font.SourceSansBold
    returnButton.Parent = resultsFrame
    
    returnButton.MouseButton1Click:Connect(function()
        resultsGui:Destroy()
        self:EndGame()
    end)
    
    -- Auto-close after 10 seconds
    spawn(function()
        wait(10)
        if resultsGui and resultsGui.Parent then
            resultsGui:Destroy()
            self:EndGame()
        end
    end)
    
    -- Play completion sound
    self:PlayCompletionSound()
end

function EnhancedGameplayController:EndGame()
    print("🎮 Game ended on client")
    
    isInGame = false
    currentDifficulty = nil
    gameConfig = nil
    currentColor = "Red"
    
    -- Clean up UI
    if gameUI then
        gameUI:Destroy()
        gameUI = nil
    end
    
    -- Disconnect all connections
    for _, connection in pairs(connections) do
        if connection then
            connection:Disconnect()
        end
    end
    connections = {}
end

-- Sound effects
function EnhancedGameplayController:PlayGameStartSound()
    -- Create and play start sound
    local sound = Instance.new("Sound")
    sound.SoundId = "rbxasset://sounds/electronicpingshort.wav"
    sound.Volume = 0.5
    sound.Parent = SoundService
    sound:Play()
    sound.Ended:Connect(function() sound:Destroy() end)
end

function EnhancedGameplayController:PlayColorChangeSound()
    local sound = Instance.new("Sound")
    sound.SoundId = "rbxasset://sounds/button.wav"
    sound.Volume = 0.3
    sound.Pitch = 1.5
    sound.Parent = SoundService
    sound:Play()
    sound.Ended:Connect(function() sound:Destroy() end)
end

function EnhancedGameplayController:PlayCoinSound()
    local sound = Instance.new("Sound")
    sound.SoundId = "rbxasset://sounds/action_get_up.mp3"
    sound.Volume = 0.4
    sound.Pitch = 2
    sound.Parent = SoundService
    sound:Play()
    sound.Ended:Connect(function() sound:Destroy() end)
end

function EnhancedGameplayController:PlayImpactSound()
    local sound = Instance.new("Sound")
    sound.SoundId = "rbxasset://sounds/impact_water.mp3"
    sound.Volume = 0.6
    sound.Parent = SoundService
    sound:Play()
    sound.Ended:Connect(function() sound:Destroy() end)
end

function EnhancedGameplayController:PlaySuccessSound()
    local sound = Instance.new("Sound")
    sound.SoundId = "rbxasset://sounds/action_jump.mp3"
    sound.Volume = 0.4
    sound.Pitch = 1.5
    sound.Parent = SoundService
    sound:Play()
    sound.Ended:Connect(function() sound:Destroy() end)
end

function EnhancedGameplayController:PlayFailSound()
    local sound = Instance.new("Sound")
    sound.SoundId = "rbxasset://sounds/action_falling.mp3"
    sound.Volume = 0.4
    sound.Parent = SoundService
    sound:Play()
    sound.Ended:Connect(function() sound:Destroy() end)
end

function EnhancedGameplayController:PlayCompletionSound()
    local sound = Instance.new("Sound")
    sound.SoundId = "rbxasset://sounds/action_get_up.mp3"
    sound.Volume = 0.7
    sound.Pitch = 0.8
    sound.Parent = SoundService
    sound:Play()
    sound.Ended:Connect(function() sound:Destroy() end)
end

function EnhancedGameplayController:ScreenShake()
    -- Enhanced screen shake effect with camera manipulation
    local camera = workspace.CurrentCamera
    if not camera then return end
    
    local originalCFrame = camera.CFrame
    
    -- More dramatic shake for visual polish
    spawn(function()
        for i = 1, 15 do
            local intensity = (16 - i) * 0.8
            local randomOffset = Vector3.new(
                math.random(-intensity, intensity),
                math.random(-intensity, intensity),
                math.random(-intensity, intensity)
            )
            camera.CFrame = originalCFrame + randomOffset
            wait(0.02)
        end
        camera.CFrame = originalCFrame
    end)
end

function EnhancedGameplayController:CreateCoinCollectionEffect(position)
    -- Create particle burst effect at coin collection point
    local effectPart = Instance.new("Part")
    effectPart.Name = "CoinCollectionEffect"
    effectPart.Size = Vector3.new(1, 1, 1)
    effectPart.Position = position
    effectPart.Anchored = true
    effectPart.CanCollide = false
    effectPart.Transparency = 1
    effectPart.Parent = workspace
    
    local attachment = Instance.new("Attachment")
    attachment.Parent = effectPart
    
    -- Golden sparkle particles
    local sparkles = Instance.new("ParticleEmitter")
    sparkles.Name = "CoinSparkles"
    sparkles.Texture = "rbxasset://textures/particles/sparkles_main.dds"
    sparkles.Color = ColorSequence.new{
        ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 255, 100)),
        ColorSequenceKeypoint.new(0.5, Color3.fromRGB(255, 215, 0)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 165, 0))
    }
    sparkles.Size = NumberSequence.new{
        NumberSequenceKeypoint.new(0, 0.3),
        NumberSequenceKeypoint.new(0.5, 1.2),
        NumberSequenceKeypoint.new(1, 0)
    }
    sparkles.Transparency = NumberSequence.new{
        NumberSequenceKeypoint.new(0, 0),
        NumberSequenceKeypoint.new(1, 1)
    }
    sparkles.Lifetime = NumberRange.new(0.8, 1.5)
    sparkles.Rate = 200
    sparkles.SpreadAngle = Vector2.new(360, 360)
    sparkles.Speed = NumberRange.new(5, 15)
    sparkles.Acceleration = Vector3.new(0, -20, 0)
    sparkles.Parent = attachment
    
    -- Fire burst for extra effect
    local fireBurst = Instance.new("ParticleEmitter")
    fireBurst.Name = "CoinBurst"
    fireBurst.Texture = "rbxasset://textures/particles/fire_main.dds"
    fireBurst.Color = ColorSequence.new(Color3.fromRGB(255, 255, 100))
    fireBurst.Size = NumberSequence.new{
        NumberSequenceKeypoint.new(0, 0.5),
        NumberSequenceKeypoint.new(0.3, 1.5),
        NumberSequenceKeypoint.new(1, 0)
    }
    fireBurst.Transparency = NumberSequence.new{
        NumberSequenceKeypoint.new(0, 0.3),
        NumberSequenceKeypoint.new(1, 1)
    }
    fireBurst.Lifetime = NumberRange.new(0.3, 0.8)
    fireBurst.Rate = 100
    fireBurst.SpreadAngle = Vector2.new(45, 45)
    fireBurst.Speed = NumberRange.new(8, 20)
    fireBurst.Parent = attachment
    
    -- Emit burst
    sparkles:Emit(30)
    fireBurst:Emit(15)
    
    -- Clean up
    game:GetService("Debris"):AddItem(effectPart, 3)
end

function EnhancedGameplayController:CreateTrailEffect(player)
    -- Create enhanced trail effect for running
    if not player.Character or not player.Character:FindFirstChild("HumanoidRootPart") then return end
    
    local rootPart = player.Character.HumanoidRootPart
    
    -- Create trail attachments
    local attachment0 = Instance.new("Attachment")
    attachment0.Name = "TrailAttachment0"
    attachment0.Position = Vector3.new(-1.5, -1, 0)
    attachment0.Parent = rootPart
    
    local attachment1 = Instance.new("Attachment")
    attachment1.Name = "TrailAttachment1"
    attachment1.Position = Vector3.new(1.5, -1, 0)
    attachment1.Parent = rootPart
    
    -- Create colorful trail
    local trail = Instance.new("Trail")
    trail.Name = "RunningTrail"
    trail.Attachment0 = attachment0
    trail.Attachment1 = attachment1
    trail.Texture = "rbxasset://textures/particles/smoke_main.dds"
    trail.Color = ColorSequence.new{
        ColorSequenceKeypoint.new(0, COLORS[currentColor].color),
        ColorSequenceKeypoint.new(1, COLORS[currentColor].color:lerp(Color3.new(1, 1, 1), 0.5))
    }
    trail.Transparency = NumberSequence.new{
        NumberSequenceKeypoint.new(0, 0.3),
        ColorSequenceKeypoint.new(0.5, 0.7),
        NumberSequenceKeypoint.new(1, 1)
    }
    trail.Lifetime = 1.5
    trail.MinLength = 0
    trail.FaceCamera = true
    trail.Parent = rootPart
    
    -- Store trail for color updates
    visualEffects.playerTrail = trail
    
    return trail
end

function EnhancedGameplayController:UpdateTrailColor(newColor)
    if visualEffects.playerTrail then
        local trail = visualEffects.playerTrail
        trail.Color = ColorSequence.new{
            ColorSequenceKeypoint.new(0, COLORS[newColor].color),
            ColorSequenceKeypoint.new(1, COLORS[newColor].color:lerp(Color3.new(1, 1, 1), 0.5))
        }
    end
end

function EnhancedGameplayController:CreateJumpEffect(player)
    if not player.Character or not player.Character:FindFirstChild("HumanoidRootPart") then return end
    
    local rootPart = player.Character.HumanoidRootPart
    
    -- Create jump particle effect
    local effectPart = Instance.new("Part")
    effectPart.Name = "JumpEffect"
    effectPart.Size = Vector3.new(1, 1, 1)
    effectPart.Position = rootPart.Position + Vector3.new(0, -3, 0)
    effectPart.Anchored = true
    effectPart.CanCollide = false
    effectPart.Transparency = 1
    effectPart.Parent = workspace
    
    local attachment = Instance.new("Attachment")
    attachment.Parent = effectPart
    
    -- Dust cloud particles
    local dustCloud = Instance.new("ParticleEmitter")
    dustCloud.Name = "JumpDust"
    dustCloud.Texture = "rbxasset://textures/particles/smoke_main.dds"
    dustCloud.Color = ColorSequence.new(Color3.fromRGB(200, 200, 200))
    dustCloud.Size = NumberSequence.new{
        NumberSequenceKeypoint.new(0, 1),
        NumberSequenceKeypoint.new(1, 3)
    }
    dustCloud.Transparency = NumberSequence.new{
        NumberSequenceKeypoint.new(0, 0.5),
        NumberSequenceKeypoint.new(1, 1)
    }
    dustCloud.Lifetime = NumberRange.new(1, 2)
    dustCloud.Rate = 50
    dustCloud.SpreadAngle = Vector2.new(80, 80)
    dustCloud.Speed = NumberRange.new(2, 8)
    dustCloud.Acceleration = Vector3.new(0, 5, 0)
    dustCloud.Parent = attachment
    
    -- Energy burst
    local energyBurst = Instance.new("ParticleEmitter")
    energyBurst.Name = "JumpEnergy"
    energyBurst.Texture = "rbxasset://textures/particles/sparkles_main.dds"
    energyBurst.Color = ColorSequence.new(COLORS[currentColor].color)
    energyBurst.Size = NumberSequence.new{
        NumberSequenceKeypoint.new(0, 0.5),
        NumberSequenceKeypoint.new(1, 0)
    }
    energyBurst.Transparency = NumberSequence.new{
        NumberSequenceKeypoint.new(0, 0),
        NumberSequenceKeypoint.new(1, 1)
    }
    energyBurst.Lifetime = NumberRange.new(0.5, 1)
    energyBurst.Rate = 100
    energyBurst.SpreadAngle = Vector2.new(360, 360)
    energyBurst.Speed = NumberRange.new(10, 25)
    energyBurst.Parent = attachment
    
    -- Emit effects
    dustCloud:Emit(20)
    energyBurst:Emit(15)
    
    -- Clean up
    game:GetService("Debris"):AddItem(effectPart, 3)
end

return EnhancedGameplayController
