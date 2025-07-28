-- ArchwayController.luau
-- Handles client-side archway fade effects and countdown display

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SoundService = game:GetService("SoundService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local RemoteEvents = require(ReplicatedStorage.Shared.modules.RemoteEvents)

local ArchwayController = {}

-- UI Elements
local fadeFrame = nil
local countdownGui = nil

function ArchwayController:CreateFadeFrame()
    if fadeFrame then return end
    
    -- Create screen fade overlay
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "FadeGui"
    screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    screenGui.Parent = playerGui
    
    fadeFrame = Instance.new("Frame")
    fadeFrame.Name = "FadeFrame"
    fadeFrame.Size = UDim2.new(1, 0, 1, 0)
    fadeFrame.Position = UDim2.new(0, 0, 0, 0)
    fadeFrame.BackgroundColor3 = Color3.new(0, 0, 0)
    fadeFrame.BorderSizePixel = 0
    fadeFrame.ZIndex = 10
    fadeFrame.BackgroundTransparency = 1  -- Start transparent
    fadeFrame.Parent = screenGui
    
    print("📺 Fade frame created")
end

function ArchwayController:CreateCountdownGui()
    if countdownGui then return end
    
    -- Create full-screen countdown display
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "CountdownGui"
    screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    screenGui.Parent = playerGui
    
    countdownGui = Instance.new("Frame")
    countdownGui.Name = "CountdownFrame"
    countdownGui.Size = UDim2.new(1, 0, 1, 0)  -- Full screen
    countdownGui.Position = UDim2.new(0, 0, 0, 0)
    countdownGui.BackgroundTransparency = 1
    countdownGui.ZIndex = 15
    countdownGui.Visible = false
    countdownGui.Parent = screenGui
    
    -- Massive countdown number - takes up most of the screen
    local countdownLabel = Instance.new("TextLabel")
    countdownLabel.Name = "CountdownLabel"
    countdownLabel.Size = UDim2.new(0.8, 0, 0.6, 0)  -- 80% width, 60% height
    countdownLabel.Position = UDim2.new(0.1, 0, 0.2, 0)  -- Centered
    countdownLabel.BackgroundTransparency = 1
    countdownLabel.Text = "3"
    countdownLabel.TextColor3 = Color3.new(1, 1, 0)  -- Bright yellow
    countdownLabel.TextScaled = true
    countdownLabel.Font = Enum.Font.SourceSansBold
    countdownLabel.TextStrokeTransparency = 0
    countdownLabel.TextStrokeColor3 = Color3.new(0, 0, 0)
    countdownLabel.TextStrokeThickness = 8  -- Thick outline
    countdownLabel.Parent = countdownGui
    
    -- Ready message below the number
    local readyLabel = Instance.new("TextLabel")
    readyLabel.Name = "ReadyLabel"
    readyLabel.Size = UDim2.new(0.6, 0, 0.1, 0)
    readyLabel.Position = UDim2.new(0.2, 0, 0.85, 0)  -- Bottom of screen
    readyLabel.BackgroundTransparency = 1
    readyLabel.Text = "Get Ready!"
    readyLabel.TextColor3 = Color3.new(1, 1, 1)
    readyLabel.TextScaled = true
    readyLabel.Font = Enum.Font.SourceSans
    readyLabel.TextStrokeTransparency = 0
    readyLabel.TextStrokeColor3 = Color3.new(0, 0, 0)
    readyLabel.TextStrokeThickness = 4
    readyLabel.Parent = countdownGui
    
    print("⏰ Big countdown GUI created")
end

function ArchwayController:FadeToBlack()
    self:CreateFadeFrame()
    
    if not fadeFrame then return end
    
    print("🌑 Fading to black...")
    
    -- Fade to black
    local fadeIn = TweenService:Create(
        fadeFrame,
        TweenInfo.new(1.5, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut),
        {BackgroundTransparency = 0}
    )
    
    fadeIn:Play()
    
    -- Play transition sound
    local transitionSound = Instance.new("Sound")
    transitionSound.SoundId = "rbxassetid://131961136"  -- Swoosh sound
    transitionSound.Volume = 0.5
    transitionSound.Parent = SoundService
    transitionSound:Play()
    
    transitionSound.Ended:Connect(function()
        transitionSound:Destroy()
    end)
end

function ArchwayController:FadeFromBlack()
    if not fadeFrame then return end
    
    print("🌞 Fading from black...")
    
    -- Fade from black
    local fadeOut = TweenService:Create(
        fadeFrame,
        TweenInfo.new(1, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut),
        {BackgroundTransparency = 1}
    )
    
    fadeOut:Play()
    
    -- Clean up after fade
    fadeOut.Completed:Connect(function()
        if fadeFrame and fadeFrame.Parent then
            fadeFrame.Parent:Destroy()
            fadeFrame = nil
        end
    end)
end

function ArchwayController:StartCountdown()
    self:CreateCountdownGui()
    
    if not countdownGui then return end
    
    print("⏰ Starting big countdown...")
    
    local countdownLabel = countdownGui:FindFirstChild("CountdownLabel")
    local readyLabel = countdownGui:FindFirstChild("ReadyLabel")
    
    if not countdownLabel or not readyLabel then return end
    
    -- Show countdown full screen
    countdownGui.Visible = true
    
    -- Countdown from 3 to 1 with dramatic effects
    for i = 3, 1, -1 do
        countdownLabel.Text = tostring(i) .. "…"
        
        -- Start with huge size and scale down dramatically
        countdownLabel.Size = UDim2.new(1.0, 0, 0.8, 0)
        countdownLabel.TextTransparency = 0
        countdownLabel.TextStrokeTransparency = 0
        
        -- Dramatic scale and fade in animation
        local scaleDown = TweenService:Create(
            countdownLabel,
            TweenInfo.new(0.9, Enum.EasingStyle.Bounce, Enum.EasingDirection.Out),
            {Size = UDim2.new(0.8, 0, 0.6, 0)}
        )
        scaleDown:Play()
        
        -- Color progression: Red -> Orange -> Yellow
        local colors = {
            Color3.new(1, 0.2, 0.2),  -- Red for 3
            Color3.new(1, 0.6, 0.2),  -- Orange for 2  
            Color3.new(1, 1, 0.2)     -- Yellow for 1
        }
        countdownLabel.TextColor3 = colors[4-i]
        
        -- Pulsing glow effect
        local pulseIn = TweenService:Create(
            countdownLabel,
            TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
            {TextStrokeThickness = 12}
        )
        pulseIn:Play()
        
        pulseIn.Completed:Connect(function()
            local pulseOut = TweenService:Create(
                countdownLabel,
                TweenInfo.new(0.6, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut),
                {TextStrokeThickness = 8}
            )
            pulseOut:Play()
        end)
        
        -- Play countdown beep sound with increasing pitch
        local GameAudioController = require(script.Parent.GameAudioController)
        GameAudioController:PlayCountdownSound(4-i) -- Convert 3,2,1 to 1,2,3
        
        wait(1)  -- One second intervals as requested
    end
    
    -- Show "GO!" with maximum impact
    countdownLabel.Text = "GO!"
    countdownLabel.TextColor3 = Color3.new(0, 1, 0.2)  -- Bright green
    readyLabel.Text = "Color Rush Begins!"
    readyLabel.TextColor3 = Color3.new(0, 1, 0.2)
    
    -- Massive explosion animation for GO
    countdownLabel.Size = UDim2.new(1.2, 0, 0.9, 0)
    local goExplosion = TweenService:Create(
        countdownLabel,
        TweenInfo.new(0.4, Enum.EasingStyle.Bounce, Enum.EasingDirection.Out),
        {Size = UDim2.new(0.8, 0, 0.6, 0)}
    )
    goExplosion:Play()
    
    -- Dramatic glow for GO
    local goGlow = TweenService:Create(
        countdownLabel,
        TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
        {TextStrokeThickness = 15}
    )
    goGlow:Play()
    
    -- Play final "GO" sound
    local GameAudioController = require(script.Parent.GameAudioController)
    GameAudioController:PlayGameStartSound()
    
    -- Start background music for the run
    GameAudioController:StartBackgroundMusic("normal")
    
    -- Hold GO for a moment then fade out
    wait(0.8)
    
    -- Fade out the entire countdown
    local fadeOut = TweenService:Create(
        countdownGui,
        TweenInfo.new(0.6, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut),
        {BackgroundTransparency = 1}
    )
    
    for _, child in pairs(countdownGui:GetChildren()) do
        if child:IsA("TextLabel") then
            TweenService:Create(
                child,
                TweenInfo.new(0.6, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut),
                {TextTransparency = 1, TextStrokeTransparency = 1}
            ):Play()
        end
    end
    
    fadeOut:Play()
    
    fadeOut.Completed:Connect(function()
        if countdownGui and countdownGui.Parent then
            countdownGui.Parent:Destroy()
            countdownGui = nil
        end
    end)
end

function ArchwayController:Initialize()
    print("🏛️ ArchwayController initializing...")
    
    -- Connect to remote events
    RemoteEvents.GameFadeToBlack.OnClientEvent:Connect(function()
        self:FadeToBlack()
    end)
    
    RemoteEvents.GameFadeFromBlack.OnClientEvent:Connect(function()
        self:FadeFromBlack()
    end)
    
    RemoteEvents.GameCountdownStart.OnClientEvent:Connect(function()
        self:StartCountdown()
    end)
    
    print("✅ ArchwayController initialized successfully!")
end

-- Auto-initialize when required
ArchwayController:Initialize()

return ArchwayController
