-- GameController.luau
-- Handles client-side game mechanics and UI

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SoundService = game:GetService("SoundService")

local GameConstants = require(ReplicatedStorage.Shared.constants.GameConstants)
local RemoteEvents = require(ReplicatedStorage.Shared.modules.RemoteEvents)
local GuiController = require(script.Parent.GuiController)

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local character = player.CharacterAdded:Wait()

local GameController = {}
local isPlaying = false
local currentColor = "RED"
local gameUI = nil

function GameController:CreateGameUI()
    -- Create main game UI
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "ColorRushUI"
    screenGui.Parent = playerGui
    
    -- Score display (Top Left Corner)
    local scoreFrame = Instance.new("Frame")
    scoreFrame.Name = "ScoreDisplay"
    scoreFrame.Size = UDim2.new(0, 250, 0, 80)
    scoreFrame.Position = UDim2.new(0, 20, 0, 20) -- Top left
    scoreFrame.BackgroundColor3 = Color3.new(0, 0, 0)
    scoreFrame.BackgroundTransparency = 0.3
    scoreFrame.BorderSizePixel = 2
    scoreFrame.BorderColor3 = Color3.new(1, 1, 1)
    scoreFrame.Parent = screenGui
    
    local scoreLabel = Instance.new("TextLabel")
    scoreLabel.Name = "ScoreLabel"
    scoreLabel.Size = UDim2.new(1, 0, 1, 0)
    scoreLabel.BackgroundTransparency = 1
    scoreLabel.Text = "Score: 0"
    scoreLabel.TextColor3 = Color3.new(1, 1, 0) -- Yellow text
    scoreLabel.TextScaled = true
    scoreLabel.Font = Enum.Font.SourceSansBold
    scoreLabel.TextStrokeTransparency = 0
    scoreLabel.TextStrokeColor3 = Color3.new(0, 0, 0)
    scoreLabel.Parent = scoreFrame
    
    -- Coins display (Top Right Corner)
    local coinsFrame = Instance.new("Frame")
    coinsFrame.Name = "CoinsDisplay"
    coinsFrame.Size = UDim2.new(0, 250, 0, 80)
    coinsFrame.Position = UDim2.new(1, -270, 0, 20) -- Top right
    coinsFrame.BackgroundColor3 = Color3.new(0, 0, 0)
    coinsFrame.BackgroundTransparency = 0.3
    coinsFrame.BorderSizePixel = 2
    coinsFrame.BorderColor3 = Color3.new(1, 1, 1)
    coinsFrame.Parent = screenGui
    
    local coinsLabel = Instance.new("TextLabel")
    coinsLabel.Name = "CoinsLabel"
    coinsLabel.Size = UDim2.new(1, 0, 1, 0)
    coinsLabel.BackgroundTransparency = 1
    coinsLabel.Text = "Coins: 0"
    coinsLabel.TextColor3 = Color3.new(1, 0.8, 0) -- Gold text
    coinsLabel.TextScaled = true
    coinsLabel.Font = Enum.Font.SourceSansBold
    coinsLabel.TextStrokeTransparency = 0
    coinsLabel.TextStrokeColor3 = Color3.new(0, 0, 0)
    coinsLabel.Parent = coinsFrame
    
    -- Color indicator (Center Left)
    local colorFrame = Instance.new("Frame")
    colorFrame.Name = "ColorIndicator"
    colorFrame.Size = UDim2.new(0, 200, 0, 100)
    colorFrame.Position = UDim2.new(0, 20, 0, 120) -- Below score
    colorFrame.BackgroundColor3 = GameConstants.GAME_COLORS[currentColor] or Color3.new(1, 0.2, 0.2)
    colorFrame.BorderSizePixel = 3
    colorFrame.BorderColor3 = Color3.new(1, 1, 1)
    colorFrame.Parent = screenGui
    
    local colorLabel = Instance.new("TextLabel")
    colorLabel.Size = UDim2.new(1, 0, 1, 0)
    colorLabel.BackgroundTransparency = 1
    colorLabel.Text = currentColor
    colorLabel.TextColor3 = Color3.new(1, 1, 1)
    colorLabel.TextScaled = true
    colorLabel.Font = Enum.Font.SourceSansBold
    colorLabel.TextStrokeTransparency = 0
    colorLabel.TextStrokeColor3 = Color3.new(0, 0, 0)
    colorLabel.Parent = colorFrame
    
    -- Start button (Center)
    local startButton = Instance.new("TextButton")
    startButton.Name = "StartButton"
    startButton.Size = UDim2.new(0, 200, 0, 60)
    startButton.Position = UDim2.new(0.5, -100, 0.5, -30)
    startButton.BackgroundColor3 = Color3.new(0.2, 0.8, 0.2)
    startButton.BorderSizePixel = 2
    startButton.BorderColor3 = Color3.new(1, 1, 1)
    startButton.Text = "START GAME"
    startButton.TextColor3 = Color3.new(1, 1, 1)
    startButton.TextScaled = true
    startButton.Font = Enum.Font.SourceSansBold
    startButton.Parent = screenGui
    
    startButton.MouseButton1Click:Connect(function()
        self:StartGame()
    end)
    
    -- Mobile Color Buttons (Bottom corners)
    -- Red Button (Bottom Left)
    local redButton = Instance.new("TextButton")
    redButton.Name = "RedButton"
    redButton.Size = UDim2.new(0, 80, 0, 80)
    redButton.Position = UDim2.new(0, 20, 1, -100) -- Bottom left
    redButton.BackgroundColor3 = Color3.new(1, 0.2, 0.2) -- Red
    redButton.BorderSizePixel = 3
    redButton.BorderColor3 = Color3.new(1, 1, 1)
    redButton.Text = "R"
    redButton.TextColor3 = Color3.new(1, 1, 1)
    redButton.TextScaled = true
    redButton.Font = Enum.Font.SourceSansBold
    redButton.TextStrokeTransparency = 0
    redButton.TextStrokeColor3 = Color3.new(0, 0, 0)
    redButton.Visible = false -- Initially hidden
    redButton.Parent = screenGui
    
    redButton.MouseButton1Click:Connect(function()
        self:ChangePlayerColor("RED")
    end)
    
    -- Green Button (Bottom Center)
    local greenButton = Instance.new("TextButton")
    greenButton.Name = "GreenButton"
    greenButton.Size = UDim2.new(0, 80, 0, 80)
    greenButton.Position = UDim2.new(0.5, -40, 1, -100) -- Bottom center
    greenButton.BackgroundColor3 = Color3.new(0.2, 0.8, 0.2) -- Green
    greenButton.BorderSizePixel = 3
    greenButton.BorderColor3 = Color3.new(1, 1, 1)
    greenButton.Text = "G"
    greenButton.TextColor3 = Color3.new(1, 1, 1)
    greenButton.TextScaled = true
    greenButton.Font = Enum.Font.SourceSansBold
    greenButton.TextStrokeTransparency = 0
    greenButton.TextStrokeColor3 = Color3.new(0, 0, 0)
    greenButton.Visible = false -- Initially hidden
    greenButton.Parent = screenGui
    
    greenButton.MouseButton1Click:Connect(function()
        self:ChangePlayerColor("GREEN")
    end)
    
    -- Blue Button (Bottom Right)
    local blueButton = Instance.new("TextButton")
    blueButton.Name = "BlueButton"
    blueButton.Size = UDim2.new(0, 80, 0, 80)
    blueButton.Position = UDim2.new(1, -100, 1, -100) -- Bottom right
    blueButton.BackgroundColor3 = Color3.new(0.2, 0.4, 1) -- Blue
    blueButton.BorderSizePixel = 3
    blueButton.BorderColor3 = Color3.new(1, 1, 1)
    blueButton.Text = "B"
    blueButton.TextColor3 = Color3.new(1, 1, 1)
    blueButton.TextScaled = true
    blueButton.Font = Enum.Font.SourceSansBold
    blueButton.TextStrokeTransparency = 0
    blueButton.TextStrokeColor3 = Color3.new(0, 0, 0)
    blueButton.Visible = false -- Initially hidden
    blueButton.Parent = screenGui
    
    blueButton.MouseButton1Click:Connect(function()
        self:ChangePlayerColor("BLUE")
    end)
    
    return screenGui
end

function GameController:UpdateColorIndicator(color)
    currentColor = color
    
    if gameUI then
        local colorFrame = gameUI:FindFirstChild("ColorIndicator")
        if colorFrame then
            colorFrame.BackgroundColor3 = GameConstants.GAME_COLORS[color]
            colorFrame.TextLabel.Text = color
            
            -- Pulse animation
            local tween = TweenService:Create(
                colorFrame,
                TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
                {Size = UDim2.new(0, 220, 0, 110)}
            )
            tween:Play()
            
            tween.Completed:Connect(function()
                local returnTween = TweenService:Create(
                    colorFrame,
                    TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
                    {Size = UDim2.new(0, 200, 0, 100)}
                )
                returnTween:Play()
            end)
        end
    end
end

function GameController:ChangePlayerColor(colorName)
    -- Only allow color changes during gameplay
    if not isPlaying then
        return
    end
    
    -- Update local color state
    currentColor = colorName
    
    -- Update the color indicator immediately for responsive feedback
    self:UpdateColorIndicator(colorName)
    
    -- Send color change to server
    RemoteEvents.PlayerColorChanged:FireServer(colorName)
    
    -- Add visual feedback for button press
    if gameUI then
        local buttonName = colorName:sub(1,1) .. "Button" -- "RED" -> "RButton"
        local button = gameUI:FindFirstChild(buttonName)
        if button then
            -- Button press animation
            local originalSize = button.Size
            local pressTween = TweenService:Create(
                button,
                TweenInfo.new(0.1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
                {Size = originalSize * 0.9}
            )
            pressTween:Play()
            
            pressTween.Completed:Connect(function()
                local releaseTween = TweenService:Create(
                    button,
                    TweenInfo.new(0.1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
                    {Size = originalSize}
                )
                releaseTween:Play()
            end)
        end
    end
    
    print("📱 Mobile color change: " .. colorName)
end

function GameController:UpdateScore(score)
    if gameUI then
        local scoreFrame = gameUI:FindFirstChild("ScoreDisplay")
        if scoreFrame and scoreFrame:FindFirstChild("ScoreLabel") then
            scoreFrame.ScoreLabel.Text = "Score: " .. score
            
            -- Score animation
            local originalSize = scoreFrame.Size
            local scaleTween = TweenService:Create(
                scoreFrame,
                TweenInfo.new(0.2, Enum.EasingStyle.Bounce, Enum.EasingDirection.Out),
                {Size = originalSize * 1.1}
            )
            scaleTween:Play()
            
            scaleTween.Completed:Connect(function()
                local returnTween = TweenService:Create(
                    scoreFrame,
                    TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
                    {Size = originalSize}
                )
                returnTween:Play()
            end)
        end
    end
end

function GameController:UpdateCoins(coins)
    if gameUI then
        local coinsFrame = gameUI:FindFirstChild("CoinsDisplay")
        if coinsFrame and coinsFrame:FindFirstChild("CoinsLabel") then
            coinsFrame.CoinsLabel.Text = "Coins: " .. coins
            
            -- Coins animation with sparkle effect
            local originalSize = coinsFrame.Size
            local originalColor = coinsFrame.CoinsLabel.TextColor3
            
            -- Scale animation
            local scaleTween = TweenService:Create(
                coinsFrame,
                TweenInfo.new(0.3, Enum.EasingStyle.Bounce, Enum.EasingDirection.Out),
                {Size = originalSize * 1.15}
            )
            scaleTween:Play()
            
            -- Color flash animation
            local colorTween = TweenService:Create(
                coinsFrame.CoinsLabel,
                TweenInfo.new(0.1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
                {TextColor3 = Color3.new(1, 1, 1)} -- Flash white
            )
            colorTween:Play()
            
            colorTween.Completed:Connect(function()
                local returnColorTween = TweenService:Create(
                    coinsFrame.CoinsLabel,
                    TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
                    {TextColor3 = originalColor} -- Return to gold
                )
                returnColorTween:Play()
            end)
            
            scaleTween.Completed:Connect(function()
                local returnTween = TweenService:Create(
                    coinsFrame,
                    TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
                    {Size = originalSize}
                )
                returnTween:Play()
            end)
        end
    end
end

function GameController:ShowSummaryScreen(results)
    -- Create summary screen overlay
    local summaryScreen = Instance.new("Frame")
    summaryScreen.Name = "SummaryScreen"
    summaryScreen.Size = UDim2.new(1, 0, 1, 0)
    summaryScreen.Position = UDim2.new(0, 0, 0, 0)
    summaryScreen.BackgroundColor3 = Color3.new(0, 0, 0)
    summaryScreen.BackgroundTransparency = 0.3
    summaryScreen.BorderSizePixel = 0
    summaryScreen.Parent = gameUI
    
    -- Main summary panel
    local summaryPanel = Instance.new("Frame")
    summaryPanel.Name = "SummaryPanel"
    summaryPanel.Size = UDim2.new(0, 400, 0, 350)
    summaryPanel.Position = UDim2.new(0.5, -200, 0.5, -175)
    summaryPanel.BackgroundColor3 = Color3.new(0.1, 0.1, 0.15)
    summaryPanel.BorderSizePixel = 0
    summaryPanel.Parent = summaryScreen
    
    -- Panel styling
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 12)
    corner.Parent = summaryPanel
    
    local stroke = Instance.new("UIStroke")
    stroke.Color = Color3.new(0.3, 0.3, 0.4)
    stroke.Thickness = 2
    stroke.Parent = summaryPanel
    
    -- Title
    local titleLabel = Instance.new("TextLabel")
    titleLabel.Name = "TitleLabel"
    titleLabel.Size = UDim2.new(1, 0, 0, 60)
    titleLabel.Position = UDim2.new(0, 0, 0, 10)
    titleLabel.BackgroundTransparency = 1
    titleLabel.Text = "🏁 Run Complete!"
    titleLabel.TextColor3 = Color3.new(1, 1, 1)
    titleLabel.TextScaled = true
    titleLabel.Font = Enum.Font.GothamBold
    titleLabel.Parent = summaryPanel
    
    -- Final Score
    local scoreLabel = Instance.new("TextLabel")
    scoreLabel.Name = "ScoreLabel"
    scoreLabel.Size = UDim2.new(1, -40, 0, 50)
    scoreLabel.Position = UDim2.new(0, 20, 0, 80)
    scoreLabel.BackgroundTransparency = 1
    scoreLabel.Text = "Final Score: " .. results.score
    scoreLabel.TextColor3 = Color3.fromRGB(255, 215, 0) -- Gold
    scoreLabel.TextScaled = true
    scoreLabel.Font = Enum.Font.Gotham
    scoreLabel.Parent = summaryPanel
    
    -- Coins Earned
    local coinsLabel = Instance.new("TextLabel")
    coinsLabel.Name = "CoinsLabel"
    coinsLabel.Size = UDim2.new(1, -40, 0, 50)
    coinsLabel.Position = UDim2.new(0, 20, 0, 140)
    coinsLabel.BackgroundTransparency = 1
    coinsLabel.Text = "💰 Coins Earned: " .. results.coinReward
    coinsLabel.TextColor3 = Color3.fromRGB(255, 215, 0) -- Gold
    coinsLabel.TextScaled = true
    coinsLabel.Font = Enum.Font.Gotham
    coinsLabel.Parent = summaryPanel
    
    -- Barriers Passed
    local barriersLabel = Instance.new("TextLabel")
    barriersLabel.Name = "BarriersLabel"
    barriersLabel.Size = UDim2.new(1, -40, 0, 40)
    barriersLabel.Position = UDim2.new(0, 20, 0, 200)
    barriersLabel.BackgroundTransparency = 1
    barriersLabel.Text = "🚧 Barriers Passed: " .. results.barriersPassed
    barriersLabel.TextColor3 = Color3.new(0.8, 0.8, 0.8)
    barriersLabel.TextScaled = true
    barriersLabel.Font = Enum.Font.Gotham
    barriersLabel.Parent = summaryPanel
    
    -- Collect Rewards Button
    local collectButton = Instance.new("TextButton")
    collectButton.Name = "CollectButton"
    collectButton.Size = UDim2.new(0, 300, 0, 50)
    collectButton.Position = UDim2.new(0.5, -150, 0, 280)
    collectButton.BackgroundColor3 = Color3.fromRGB(46, 204, 113) -- Green
    collectButton.Text = "🎁 Collect Rewards"
    collectButton.TextColor3 = Color3.new(1, 1, 1)
    collectButton.TextScaled = true
    collectButton.Font = Enum.Font.GothamBold
    collectButton.BorderSizePixel = 0
    collectButton.Parent = summaryPanel
    
    -- Button styling
    local buttonCorner = Instance.new("UICorner")
    buttonCorner.CornerRadius = UDim.new(0, 8)
    buttonCorner.Parent = collectButton
    
    local buttonStroke = Instance.new("UIStroke")
    buttonStroke.Color = Color3.fromRGB(39, 174, 96)
    buttonStroke.Thickness = 2
    buttonStroke.Parent = collectButton
    
    -- Button animation and functionality
    collectButton.MouseButton1Click:Connect(function()
        -- Button press animation
        local pressTween = TweenService:Create(
            collectButton,
            TweenInfo.new(0.1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
            {Size = UDim2.new(0, 290, 0, 45)}
        )
        pressTween:Play()
        
        pressTween.Completed:Connect(function()
            local releaseTween = TweenService:Create(
                collectButton,
                TweenInfo.new(0.1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
                {Size = UDim2.new(0, 300, 0, 50)}
            )
            releaseTween:Play()
            
            -- Close summary screen and return to hub
            self:CloseSummaryScreen()
            RemoteEvents.ReturnToHub:FireServer()
        end)
    end)
    
    -- Hover effects
    collectButton.MouseEnter:Connect(function()
        local hoverTween = TweenService:Create(
            collectButton,
            TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
            {BackgroundColor3 = Color3.fromRGB(52, 217, 122)}
        )
        hoverTween:Play()
    end)
    
    collectButton.MouseLeave:Connect(function()
        local leaveTween = TweenService:Create(
            collectButton,
            TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
            {BackgroundColor3 = Color3.fromRGB(46, 204, 113)}
        )
        leaveTween:Play()
    end)
    
    -- Animate the summary screen in
    summaryPanel.Position = UDim2.new(0.5, -200, 1.5, 0)
    summaryScreen.BackgroundTransparency = 1
    
    local fadeInTween = TweenService:Create(
        summaryScreen,
        TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
        {BackgroundTransparency = 0.3}
    )
    fadeInTween:Play()
    
    local slideInTween = TweenService:Create(
        summaryPanel,
        TweenInfo.new(0.5, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
        {Position = UDim2.new(0.5, -200, 0.5, -175)}
    )
    slideInTween:Play()
end

function GameController:CloseSummaryScreen()
    if gameUI then
        local summaryScreen = gameUI:FindFirstChild("SummaryScreen")
        if summaryScreen then
            local summaryPanel = summaryScreen:FindFirstChild("SummaryPanel")
            
            -- Animate out
            local fadeOutTween = TweenService:Create(
                summaryScreen,
                TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
                {BackgroundTransparency = 1}
            )
            fadeOutTween:Play()
            
            if summaryPanel then
                local slideOutTween = TweenService:Create(
                    summaryPanel,
                    TweenInfo.new(0.4, Enum.EasingStyle.Back, Enum.EasingDirection.In),
                    {Position = UDim2.new(0.5, -200, -0.5, 0)}
                )
                slideOutTween:Play()
                
                slideOutTween.Completed:Connect(function()
                    summaryScreen:Destroy()
                    self:ShowStartButton(true) -- Show start button when back in hub
                end)
            else
                fadeOutTween.Completed:Connect(function()
                    summaryScreen:Destroy()
                    self:ShowStartButton(true) -- Show start button when back in hub
                end)
            end
        end
    end
end

function GameController:ShowStartButton(show)
    if gameUI then
        local startButton = gameUI:FindFirstChild("StartButton")
        if startButton then
            startButton.Visible = show
        end
    end
end

function GameController:ShowMobileButtons(show)
    if gameUI then
        local redButton = gameUI:FindFirstChild("RedButton")
        local greenButton = gameUI:FindFirstChild("GreenButton")
        local blueButton = gameUI:FindFirstChild("BlueButton")
        
        if redButton then redButton.Visible = show end
        if greenButton then greenButton.Visible = show end
        if blueButton then blueButton.Visible = show end
    end
end

function GameController:StartGame()
    if isPlaying then return end
    
    isPlaying = true
    self:ShowStartButton(false)
    self:ShowMobileButtons(true) -- Show mobile buttons during gameplay
    
    RemoteEvents.StartGame:FireServer()
end

function GameController:EndGame()
    if not isPlaying then return end
    
    isPlaying = false
    self:ShowStartButton(true)
    self:ShowMobileButtons(false) -- Hide mobile buttons when not playing
    
    RemoteEvents.EndGame:FireServer("manual")
end

function GameController:PlaySuccessEffect()
    -- Screen flash effect
    local flash = Instance.new("Frame")
    flash.Size = UDim2.new(1, 0, 1, 0)
    flash.BackgroundColor3 = Color3.new(0, 1, 0)
    flash.BackgroundTransparency = 0.7
    flash.BorderSizePixel = 0
    flash.Parent = gameUI
    
    local tween = TweenService:Create(
        flash,
        TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
        {BackgroundTransparency = 1}
    )
    tween:Play()
    
    tween.Completed:Connect(function()
        flash:Destroy()
    end)
end

function GameController:PlayFailEffect()
    -- Screen shake and red flash
    local flash = Instance.new("Frame")
    flash.Size = UDim2.new(1, 0, 1, 0)
    flash.BackgroundColor3 = Color3.new(1, 0, 0)
    flash.BackgroundTransparency = 0.5
    flash.BorderSizePixel = 0
    flash.Parent = gameUI
    
    local tween = TweenService:Create(
        flash,
        TweenInfo.new(0.8, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
        {BackgroundTransparency = 1}
    )
    tween:Play()
    
    tween.Completed:Connect(function()
        flash:Destroy()
    end)
end

function GameController:Init()
    -- Create game UI
    gameUI = self:CreateGameUI()
    
    -- Listen to leaderstats changes
    local player = game.Players.LocalPlayer
    
    local function onLeaderstatsAdded(leaderstats)
        -- Listen for coins changes
        local coins = leaderstats:WaitForChild("Coins", 5)
        if coins then
            -- Update initial value
            self:UpdateCoins(coins.Value)
            -- Listen for changes
            coins.Changed:Connect(function()
                self:UpdateCoins(coins.Value)
            end)
        end
    end
    
    -- Check if leaderstats already exists
    if player:FindFirstChild("leaderstats") then
        onLeaderstatsAdded(player.leaderstats)
    else
        -- Wait for leaderstats to be added
        player.ChildAdded:Connect(function(child)
            if child.Name == "leaderstats" then
                onLeaderstatsAdded(child)
            end
        end)
    end
    
    -- Handle input
    UserInputService.InputBegan:Connect(function(input, gameProcessed)
        if gameProcessed then return end
        
        if input.KeyCode == Enum.KeyCode.Space then
            if isPlaying then
                self:EndGame()
            else
                self:StartGame()
            end
        end
    end)
    
    -- Handle remote events
    RemoteEvents.GameStarted.OnClientEvent:Connect(function(color)
        isPlaying = true
        self:UpdateColorIndicator(color)
        self:ShowStartButton(false)
        self:ShowMobileButtons(true) -- Show mobile buttons during gameplay
        -- Initialize score display
        self:UpdateScore(0)
        print("🎮 Game started! Your color: " .. color)
    end)
    
    RemoteEvents.GameEnded.OnClientEvent:Connect(function(results)
        isPlaying = false
        self:ShowStartButton(false) -- Hide start button while summary is shown
        self:ShowMobileButtons(false) -- Hide mobile buttons when game ends
        self:ShowSummaryScreen(results)
        print("🏁 Game ended! Score: " .. results.score .. ", Coins: " .. results.coinReward)
    end)
    
    RemoteEvents.ColorChanged.OnClientEvent:Connect(function(newColor)
        self:UpdateColorIndicator(newColor)
        print("🎨 Color changed to: " .. newColor)
    end)
    
    RemoteEvents.BarrierPassed.OnClientEvent:Connect(function(success, score)
        self:UpdateScore(score)
        if success then
            self:PlaySuccessEffect()
        else
            self:PlayFailEffect()
        end
    end)
    
    RemoteEvents.CoinCollected.OnClientEvent:Connect(function(totalCoins)
        self:UpdateCoins(totalCoins)
        print("💰 Coin collected! Total: " .. totalCoins)
    end)
    
    RemoteEvents.NewHighScore.OnClientEvent:Connect(function(score)
        print("🏆 NEW HIGH SCORE: " .. score)
    end)
    
    -- Handle failure effects
    RemoteEvents.ShowFailureEffect.OnClientEvent:Connect(function(failureData)
        self:ShowFailureEffect(failureData)
    end)
    
    print("✅ GameController initialized")
end

function GameController:ShowFailureEffect(failureData)
    print("💥 Showing failure effect:", failureData.barrierColor, "vs", failureData.playerColor)
    
    -- Play fail sound
    if failureData.playFailSound then
        self:PlayFailSound()
    end
    
    -- Show red flash overlay
    if failureData.showRedFlash then
        self:ShowRedFlashOverlay()
    end
    
    -- Show failure message
    self:ShowFailureMessage(failureData.barrierColor, failureData.playerColor)
end

function GameController:PlayFailSound()
    local failSound = Instance.new("Sound")
    failSound.SoundId = "rbxassetid://131961136" -- Error/fail sound
    failSound.Volume = 0.8
    failSound.Pitch = 0.5 -- Lower pitch for failure
    failSound.Parent = SoundService
    failSound:Play()
    
    failSound.Ended:Connect(function()
        failSound:Destroy()
    end)
end

function GameController:ShowRedFlashOverlay()
    -- Create red flash overlay
    local flashGui = Instance.new("ScreenGui")
    flashGui.Name = "RedFlashOverlay"
    flashGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    flashGui.Parent = playerGui
    
    local flashFrame = Instance.new("Frame")
    flashFrame.Size = UDim2.new(1, 0, 1, 0)
    flashFrame.Position = UDim2.new(0, 0, 0, 0)
    flashFrame.BackgroundColor3 = Color3.new(1, 0, 0) -- Bright red
    flashFrame.BorderSizePixel = 0
    flashFrame.ZIndex = 20 -- Above everything else
    flashFrame.BackgroundTransparency = 1 -- Start invisible
    flashFrame.Parent = flashGui
    
    -- Flash animation: fade in quickly, then fade out
    local flashIn = TweenService:Create(
        flashFrame,
        TweenInfo.new(0.1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
        {BackgroundTransparency = 0.3}
    )
    
    flashIn:Play()
    
    flashIn.Completed:Connect(function()
        local flashOut = TweenService:Create(
            flashFrame,
            TweenInfo.new(0.8, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut),
            {BackgroundTransparency = 1}
        )
        
        flashOut:Play()
        
        flashOut.Completed:Connect(function()
            flashGui:Destroy()
        end)
    end)
end

function GameController:ShowFailureMessage(barrierColor, playerColor)
    -- Create failure message GUI
    local messageGui = Instance.new("ScreenGui")
    messageGui.Name = "FailureMessage"
    messageGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    messageGui.Parent = playerGui
    
    local messageFrame = Instance.new("Frame")
    messageFrame.Size = UDim2.new(0.6, 0, 0.3, 0)
    messageFrame.Position = UDim2.new(0.2, 0, 0.35, 0)
    messageFrame.BackgroundColor3 = Color3.new(0, 0, 0)
    messageFrame.BackgroundTransparency = 0.2
    messageFrame.BorderSizePixel = 3
    messageFrame.BorderColor3 = Color3.new(1, 0, 0)
    messageFrame.ZIndex = 15
    messageFrame.Parent = messageGui
    
    -- Failure title
    local titleLabel = Instance.new("TextLabel")
    titleLabel.Size = UDim2.new(1, 0, 0.4, 0)
    titleLabel.Position = UDim2.new(0, 0, 0, 0)
    titleLabel.BackgroundTransparency = 1
    titleLabel.Text = "❌ WRONG COLOR!"
    titleLabel.TextColor3 = Color3.new(1, 0.2, 0.2)
    titleLabel.TextScaled = true
    titleLabel.Font = Enum.Font.SourceSansBold
    titleLabel.TextStrokeTransparency = 0
    titleLabel.TextStrokeColor3 = Color3.new(0, 0, 0)
    titleLabel.Parent = messageFrame
    
    -- Details label
    local detailsLabel = Instance.new("TextLabel")
    detailsLabel.Size = UDim2.new(1, 0, 0.6, 0)
    detailsLabel.Position = UDim2.new(0, 0, 0.4, 0)
    detailsLabel.BackgroundTransparency = 1
    detailsLabel.Text = "Needed: " .. barrierColor .. "\nYou had: " .. playerColor
    detailsLabel.TextColor3 = Color3.new(1, 1, 1)
    detailsLabel.TextScaled = true
    detailsLabel.Font = Enum.Font.SourceSans
    detailsLabel.TextStrokeTransparency = 0
    detailsLabel.TextStrokeColor3 = Color3.new(0, 0, 0)
    detailsLabel.Parent = messageFrame
    
    -- Shake animation for the message
    local originalPosition = messageFrame.Position
    local shakeTween = TweenService:Create(
        messageFrame,
        TweenInfo.new(0.1, Enum.EasingStyle.Bounce, Enum.EasingDirection.InOut, 6, true),
        {Position = originalPosition + UDim2.new(0, 10, 0, 0)}
    )
    shakeTween:Play()
    
    -- Auto-remove after 3 seconds
    game:GetService("Debris"):AddItem(messageGui, 3)
end

return GameController
