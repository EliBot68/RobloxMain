-- MiniGameController.luau
-- Client-side mini-game UI and controls

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SoundService = game:GetService("SoundService")

local RemoteEvents = require(ReplicatedStorage.Shared.modules.RemoteEvents)

local MiniGameController = {}
local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- UI elements
local miniGameGui = nil
local countdownFrame = nil
local resultsFrame = nil
local messageFrame = nil

-- Sound effects
local sounds = {
    countdown = nil,
    success = nil,
    complete = nil,
    click = nil
}

function MiniGameController:Init()
    print("🎮 MiniGameController initializing...")
    
    self:CreateMiniGameUI()
    self:SetupRemoteEvents()
    self:LoadSounds()
    
    print("✅ MiniGameController initialized!")
end

function MiniGameController:CreateMiniGameUI()
    -- Create main UI
    miniGameGui = Instance.new("ScreenGui")
    miniGameGui.Name = "MiniGameGui"
    miniGameGui.ResetOnSpawn = false
    miniGameGui.Parent = playerGui
    
    -- Create countdown frame
    self:CreateCountdownFrame()
    
    -- Create results frame
    self:CreateResultsFrame()
    
    -- Create message frame
    self:CreateMessageFrame()
end

function MiniGameController:CreateCountdownFrame()
    countdownFrame = Instance.new("Frame")
    countdownFrame.Name = "CountdownFrame"
    countdownFrame.Size = UDim2.new(0, 400, 0, 300)
    countdownFrame.Position = UDim2.new(0.5, -200, 0.5, -150)
    countdownFrame.BackgroundColor3 = Color3.new(0.1, 0.1, 0.2)
    countdownFrame.BackgroundTransparency = 0.1
    countdownFrame.BorderSizePixel = 0
    countdownFrame.Visible = false
    countdownFrame.Parent = miniGameGui
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 20)
    corner.Parent = countdownFrame
    
    local stroke = Instance.new("UIStroke")
    stroke.Color = Color3.new(0.3, 0.6, 1)
    stroke.Thickness = 3
    stroke.Parent = countdownFrame
    
    -- Game title
    local titleLabel = Instance.new("TextLabel")
    titleLabel.Name = "TitleLabel"
    titleLabel.Size = UDim2.new(1, -40, 0, 80)
    titleLabel.Position = UDim2.new(0, 20, 0, 20)
    titleLabel.BackgroundTransparency = 1
    titleLabel.Text = "🎮 Mini Game Starting!"
    titleLabel.TextColor3 = Color3.new(1, 1, 1)
    titleLabel.TextScaled = true
    titleLabel.Font = Enum.Font.SourceSansBold
    titleLabel.TextStrokeTransparency = 0
    titleLabel.TextStrokeColor3 = Color3.new(0, 0, 0)
    titleLabel.Parent = countdownFrame
    
    -- Countdown number
    local countdownLabel = Instance.new("TextLabel")
    countdownLabel.Name = "CountdownLabel"
    countdownLabel.Size = UDim2.new(1, -40, 0, 120)
    countdownLabel.Position = UDim2.new(0, 20, 0, 100)
    countdownLabel.BackgroundTransparency = 1
    countdownLabel.Text = "3"
    countdownLabel.TextColor3 = Color3.new(1, 0.3, 0.3)
    countdownLabel.TextScaled = true
    countdownLabel.Font = Enum.Font.SourceSansBold
    countdownLabel.TextStrokeTransparency = 0
    countdownLabel.TextStrokeColor3 = Color3.new(0, 0, 0)
    countdownLabel.Parent = countdownFrame
    
    -- Progress bar
    local progressBarBG = Instance.new("Frame")
    progressBarBG.Name = "ProgressBarBG"
    progressBarBG.Size = UDim2.new(1, -40, 0, 20)
    progressBarBG.Position = UDim2.new(0, 20, 0, 240)
    progressBarBG.BackgroundColor3 = Color3.new(0.2, 0.2, 0.3)
    progressBarBG.BorderSizePixel = 0
    progressBarBG.Parent = countdownFrame
    
    local progressBarCorner = Instance.new("UICorner")
    progressBarCorner.CornerRadius = UDim.new(0, 10)
    progressBarCorner.Parent = progressBarBG
    
    local progressBar = Instance.new("Frame")
    progressBar.Name = "ProgressBar"
    progressBar.Size = UDim2.new(1, 0, 1, 0)
    progressBar.Position = UDim2.new(0, 0, 0, 0)
    progressBar.BackgroundColor3 = Color3.new(0.3, 0.8, 1)
    progressBar.BorderSizePixel = 0
    progressBar.Parent = progressBarBG
    
    local progressCorner = Instance.new("UICorner")
    progressCorner.CornerRadius = UDim.new(0, 10)
    progressCorner.Parent = progressBar
end

function MiniGameController:CreateResultsFrame()
    resultsFrame = Instance.new("Frame")
    resultsFrame.Name = "ResultsFrame"
    resultsFrame.Size = UDim2.new(0, 500, 0, 400)
    resultsFrame.Position = UDim2.new(0.5, -250, 0.5, -200)
    resultsFrame.BackgroundColor3 = Color3.new(0.1, 0.1, 0.2)
    resultsFrame.BackgroundTransparency = 0.1
    resultsFrame.BorderSizePixel = 0
    resultsFrame.Visible = false
    resultsFrame.Parent = miniGameGui
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 25)
    corner.Parent = resultsFrame
    
    local stroke = Instance.new("UIStroke")
    stroke.Color = Color3.new(0.8, 0.6, 0.2)
    stroke.Thickness = 4
    stroke.Parent = resultsFrame
    
    -- Results title
    local titleLabel = Instance.new("TextLabel")
    titleLabel.Name = "TitleLabel"
    titleLabel.Size = UDim2.new(1, -40, 0, 80)
    titleLabel.Position = UDim2.new(0, 20, 0, 20)
    titleLabel.BackgroundTransparency = 1
    titleLabel.Text = "🏆 Game Complete!"
    titleLabel.TextColor3 = Color3.new(1, 1, 0.3)
    titleLabel.TextScaled = true
    titleLabel.Font = Enum.Font.SourceSansBold
    titleLabel.TextStrokeTransparency = 0
    titleLabel.TextStrokeColor3 = Color3.new(0, 0, 0)
    titleLabel.Parent = resultsFrame
    
    -- Score display
    local scoreLabel = Instance.new("TextLabel")
    scoreLabel.Name = "ScoreLabel"
    scoreLabel.Size = UDim2.new(1, -40, 0, 60)
    scoreLabel.Position = UDim2.new(0, 20, 0, 110)
    scoreLabel.BackgroundTransparency = 1
    scoreLabel.Text = "Score: 0"
    scoreLabel.TextColor3 = Color3.new(1, 1, 1)
    scoreLabel.TextScaled = true
    scoreLabel.Font = Enum.Font.SourceSans
    scoreLabel.TextStrokeTransparency = 0
    scoreLabel.TextStrokeColor3 = Color3.new(0, 0, 0)
    scoreLabel.Parent = resultsFrame
    
    -- Message display
    local messageLabel = Instance.new("TextLabel")
    messageLabel.Name = "MessageLabel"
    messageLabel.Size = UDim2.new(1, -40, 0, 80)
    messageLabel.Position = UDim2.new(0, 20, 0, 180)
    messageLabel.BackgroundTransparency = 1
    messageLabel.Text = "Great job!"
    messageLabel.TextColor3 = Color3.new(0.8, 0.8, 0.8)
    messageLabel.TextScaled = true
    messageLabel.Font = Enum.Font.SourceSans
    messageLabel.TextWrapped = true
    messageLabel.Parent = resultsFrame
    
    -- Rewards display
    local rewardsLabel = Instance.new("TextLabel")
    rewardsLabel.Name = "RewardsLabel"
    rewardsLabel.Size = UDim2.new(1, -40, 0, 60)
    rewardsLabel.Position = UDim2.new(0, 20, 0, 270)
    rewardsLabel.BackgroundTransparency = 1
    rewardsLabel.Text = "💰 +0 coins | ⭐ +0 XP"
    rewardsLabel.TextColor3 = Color3.new(0.3, 1, 0.3)
    rewardsLabel.TextScaled = true
    rewardsLabel.Font = Enum.Font.SourceSansBold
    rewardsLabel.TextStrokeTransparency = 0
    rewardsLabel.TextStrokeColor3 = Color3.new(0, 0, 0)
    rewardsLabel.Parent = resultsFrame
    
    -- Close button
    local closeButton = Instance.new("TextButton")
    closeButton.Name = "CloseButton"
    closeButton.Size = UDim2.new(0, 200, 0, 50)
    closeButton.Position = UDim2.new(0.5, -100, 0, 340)
    closeButton.BackgroundColor3 = Color3.new(0.3, 0.6, 1)
    closeButton.BorderSizePixel = 0
    closeButton.Text = "✨ Awesome!"
    closeButton.TextColor3 = Color3.new(1, 1, 1)
    closeButton.TextScaled = true
    closeButton.Font = Enum.Font.SourceSansBold
    closeButton.Parent = resultsFrame
    
    local buttonCorner = Instance.new("UICorner")
    buttonCorner.CornerRadius = UDim.new(0, 15)
    buttonCorner.Parent = closeButton
    
    closeButton.MouseButton1Click:Connect(function()
        self:CloseResults()
    end)
end

function MiniGameController:CreateMessageFrame()
    messageFrame = Instance.new("Frame")
    messageFrame.Name = "MessageFrame"
    messageFrame.Size = UDim2.new(0, 400, 0, 100)
    messageFrame.Position = UDim2.new(0.5, -200, 0, 100)
    messageFrame.BackgroundColor3 = Color3.new(0.1, 0.1, 0.2)
    messageFrame.BackgroundTransparency = 0.2
    messageFrame.BorderSizePixel = 0
    messageFrame.Visible = false
    messageFrame.Parent = miniGameGui
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 15)
    corner.Parent = messageFrame
    
    local messageLabel = Instance.new("TextLabel")
    messageLabel.Name = "MessageLabel"
    messageLabel.Size = UDim2.new(1, -20, 1, -20)
    messageLabel.Position = UDim2.new(0, 10, 0, 10)
    messageLabel.BackgroundTransparency = 1
    messageLabel.Text = "Message"
    messageLabel.TextColor3 = Color3.new(1, 1, 1)
    messageLabel.TextScaled = true
    messageLabel.Font = Enum.Font.SourceSansBold
    messageLabel.TextStrokeTransparency = 0
    messageLabel.TextStrokeColor3 = Color3.new(0, 0, 0)
    messageLabel.TextWrapped = true
    messageLabel.Parent = messageFrame
end

function MiniGameController:ShowCountdown(gameData)
    if not countdownFrame then return end
    
    -- Set game title
    local titleLabel = countdownFrame.TitleLabel
    if gameData.gameType == "jumpTarget" then
        titleLabel.Text = "🎯 Jump to the Target!"
    elseif gameData.gameType == "coinClicker" then
        titleLabel.Text = "💰 Coin Clicker Rush!"
    end
    
    -- Show countdown
    countdownFrame.Visible = true
    
    -- Countdown animation
    local countdownLabel = countdownFrame.CountdownLabel
    local progressBar = countdownFrame.ProgressBarBG.ProgressBar
    
    for i = 3, 1, -1 do
        countdownLabel.Text = tostring(i)
        countdownLabel.TextColor3 = Color3.new(1, 0.3, 0.3)
        
        -- Scale animation
        local scaleTween = TweenService:Create(
            countdownLabel,
            TweenInfo.new(0.5, Enum.EasingStyle.Bounce, Enum.EasingDirection.Out),
            {TextSize = 120}
        )
        scaleTween:Play()
        
        -- Play sound
        if sounds.countdown then
            sounds.countdown:Play()
        end
        
        wait(1)
        
        scaleTween = TweenService:Create(
            countdownLabel,
            TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
            {TextSize = 80}
        )
        scaleTween:Play()
    end
    
    -- "GO!" message
    countdownLabel.Text = "GO!"
    countdownLabel.TextColor3 = Color3.new(0.3, 1, 0.3)
    
    local goTween = TweenService:Create(
        countdownLabel,
        TweenInfo.new(0.5, Enum.EasingStyle.Bounce, Enum.EasingDirection.Out),
        {TextSize = 140}
    )
    goTween:Play()
    
    -- Play start sound
    if sounds.success then
        sounds.success:Play()
    end
    
    wait(1)
    
    -- Hide countdown and start progress timer
    countdownFrame.Visible = false
    self:StartGameTimer(gameData.duration)
end

function MiniGameController:StartGameTimer(duration)
    if not countdownFrame then return end
    
    local progressBar = countdownFrame.ProgressBarBG.ProgressBar
    local startTime = tick()
    
    -- Show progress bar
    countdownFrame.ProgressBarBG.Visible = true
    countdownFrame.TitleLabel.Visible = false
    countdownFrame.CountdownLabel.Visible = false
    countdownFrame.Visible = true
    
    spawn(function()
        while tick() - startTime < duration do
            local elapsed = tick() - startTime
            local progress = elapsed / duration
            
            -- Update progress bar
            progressBar.Size = UDim2.new(1 - progress, 0, 1, 0)
            
            -- Change color as time runs out
            if progress < 0.3 then
                progressBar.BackgroundColor3 = Color3.new(0.3, 0.8, 1) -- Blue
            elseif progress < 0.7 then
                progressBar.BackgroundColor3 = Color3.new(1, 0.8, 0.3) -- Yellow
            else
                progressBar.BackgroundColor3 = Color3.new(1, 0.3, 0.3) -- Red
            end
            
            wait(0.1)
        end
        
        -- Hide timer
        countdownFrame.Visible = false
        countdownFrame.TitleLabel.Visible = true
        countdownFrame.CountdownLabel.Visible = true
        countdownFrame.ProgressBarBG.Visible = false
    end)
end

function MiniGameController:ShowMessage(message, messageType)
    if not messageFrame then return end
    
    local messageLabel = messageFrame.MessageLabel
    messageLabel.Text = message
    
    -- Set color based on type
    if messageType == "success" then
        messageFrame.BackgroundColor3 = Color3.new(0.2, 0.6, 0.2)
        messageLabel.TextColor3 = Color3.new(1, 1, 1)
    elseif messageType == "warning" then
        messageFrame.BackgroundColor3 = Color3.new(0.8, 0.6, 0.2)
        messageLabel.TextColor3 = Color3.new(1, 1, 1)
    else
        messageFrame.BackgroundColor3 = Color3.new(0.1, 0.1, 0.2)
        messageLabel.TextColor3 = Color3.new(1, 1, 1)
    end
    
    -- Show message
    messageFrame.Visible = true
    messageFrame.Position = UDim2.new(0.5, -200, 0, 50)
    
    -- Slide in animation
    local slideIn = TweenService:Create(
        messageFrame,
        TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
        {Position = UDim2.new(0.5, -200, 0, 100)}
    )
    slideIn:Play()
    
    -- Play appropriate sound
    if messageType == "success" and sounds.success then
        sounds.success:Play()
    elseif sounds.click then
        sounds.click:Play()
    end
    
    -- Auto-hide after 2 seconds
    spawn(function()
        wait(2)
        if messageFrame.Visible then
            local slideOut = TweenService:Create(
                messageFrame,
                TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
                {Position = UDim2.new(0.5, -200, 0, 50)}
            )
            slideOut:Play()
            
            wait(0.3)
            messageFrame.Visible = false
        end
    end)
end

function MiniGameController:ShowResults(resultsData)
    if not resultsFrame then return end
    
    -- Set title based on game type
    local titleLabel = resultsFrame.TitleLabel
    if resultsData.gameType == "jumpTarget" then
        titleLabel.Text = "🎯 Target Practice Complete!"
    elseif resultsData.gameType == "coinClicker" then
        titleLabel.Text = "💰 Coin Clicking Finished!"
    end
    
    -- Set score
    local scoreLabel = resultsFrame.ScoreLabel
    if resultsData.gameType == "jumpTarget" then
        scoreLabel.Text = "Targets Hit: " .. (resultsData.score or 0)
    elseif resultsData.gameType == "coinClicker" then
        scoreLabel.Text = "Coins Clicked: " .. (resultsData.coinsClicked or 0) .. "\nTotal Score: " .. (resultsData.score or 0)
    end
    
    -- Set message
    local messageLabel = resultsFrame.MessageLabel
    messageLabel.Text = resultsData.message or "Great job!"
    
    -- Set rewards
    local rewardsLabel = resultsFrame.RewardsLabel
    local rewards = resultsData.rewards or {coins = 0, xp = 0}
    rewardsLabel.Text = "💰 +" .. rewards.coins .. " coins | ⭐ +" .. rewards.xp .. " XP"
    
    -- Show results
    resultsFrame.Visible = true
    resultsFrame.Size = UDim2.new(0, 0, 0, 0)
    resultsFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
    
    -- Scale in animation
    local scaleIn = TweenService:Create(
        resultsFrame,
        TweenInfo.new(0.5, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
        {
            Size = UDim2.new(0, 500, 0, 400),
            Position = UDim2.new(0.5, -250, 0.5, -200)
        }
    )
    scaleIn:Play()
    
    -- Play completion sound
    if sounds.complete then
        sounds.complete:Play()
    end
    
    -- Add confetti effect for good scores
    if resultsData.score and resultsData.score > 2 then
        self:CreateConfettiEffect()
    end
end

function MiniGameController:CloseResults()
    if not resultsFrame then return end
    
    -- Scale out animation
    local scaleOut = TweenService:Create(
        resultsFrame,
        TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.In),
        {
            Size = UDim2.new(0, 0, 0, 0),
            Position = UDim2.new(0.5, 0, 0.5, 0)
        }
    )
    scaleOut:Play()
    
    scaleOut.Completed:Connect(function()
        resultsFrame.Visible = false
    end)
end

function MiniGameController:CreateConfettiEffect()
    -- Create temporary confetti frame
    local confettiFrame = Instance.new("Frame")
    confettiFrame.Size = UDim2.new(1, 0, 1, 0)
    confettiFrame.Position = UDim2.new(0, 0, 0, 0)
    confettiFrame.BackgroundTransparency = 1
    confettiFrame.Parent = miniGameGui
    
    -- Create multiple confetti pieces
    for i = 1, 20 do
        local confetti = Instance.new("Frame")
        confetti.Size = UDim2.new(0, 10, 0, 10)
        confetti.Position = UDim2.new(math.random(0, 100) / 100, 0, 0, -20)
        confetti.BackgroundColor3 = Color3.new(math.random(), math.random(), math.random())
        confetti.BorderSizePixel = 0
        confetti.Parent = confettiFrame
        
        local corner = Instance.new("UICorner")
        corner.CornerRadius = UDim.new(0.5, 0)
        corner.Parent = confetti
        
        -- Animate confetti falling
        local fallTween = TweenService:Create(
            confetti,
            TweenInfo.new(3 + math.random() * 2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
            {
                Position = UDim2.new(
                    confetti.Position.X.Scale + (math.random() - 0.5) * 0.3,
                    0,
                    1.2,
                    0
                ),
                Rotation = math.random() * 360
            }
        )
        fallTween:Play()
    end
    
    -- Clean up after 5 seconds
    spawn(function()
        wait(5)
        confettiFrame:Destroy()
    end)
end

function MiniGameController:LoadSounds()
    -- Create sound effects (you can replace these with actual sound IDs)
    sounds.countdown = Instance.new("Sound")
    sounds.countdown.SoundId = "rbxasset://sounds/electronicpingshort.wav"
    sounds.countdown.Volume = 0.5
    sounds.countdown.Parent = SoundService
    
    sounds.success = Instance.new("Sound")
    sounds.success.SoundId = "rbxasset://sounds/action_get_up.mp3"
    sounds.success.Volume = 0.7
    sounds.success.Parent = SoundService
    
    sounds.complete = Instance.new("Sound")
    sounds.complete.SoundId = "rbxasset://sounds/action_footsteps_plastic.mp3"
    sounds.complete.Volume = 0.8
    sounds.complete.Parent = SoundService
    
    sounds.click = Instance.new("Sound")
    sounds.click.SoundId = "rbxasset://sounds/button.wav"
    sounds.click.Volume = 0.3
    sounds.click.Parent = SoundService
end

function MiniGameController:SetupRemoteEvents()
    -- Handle countdown start
    RemoteEvents.StartMiniGameCountdown.OnClientEvent:Connect(function(gameData)
        spawn(function()
            self:ShowCountdown(gameData)
        end)
    end)
    
    -- Handle messages
    RemoteEvents.ShowMiniGameMessage.OnClientEvent:Connect(function(message, messageType)
        self:ShowMessage(message, messageType)
    end)
    
    -- Handle results
    RemoteEvents.ShowMiniGameResults.OnClientEvent:Connect(function(resultsData)
        self:ShowResults(resultsData)
    end)
end

-- Handle UI cleanup on respawn
player.CharacterAdded:Connect(function()
    wait(1) -- Wait for character to load
    if miniGameGui and miniGameGui.Parent then
        -- Reset UI state
        if countdownFrame then countdownFrame.Visible = false end
        if resultsFrame then resultsFrame.Visible = false end
        if messageFrame then messageFrame.Visible = false end
    end
end)

return MiniGameController
