-- XpDisplayController.luau
-- Manages XP bar display and level up animations

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SoundService = game:GetService("SoundService")

local RemoteEvents = require(ReplicatedStorage.Shared.modules.RemoteEvents)

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local XpDisplayController = {}

-- GUI state
local xpGui = nil
local currentXp = 0
local currentLevel = 1
local xpToNextLevel = 100
local isAnimating = false

-- Sound effects
local levelUpSound = nil
local xpGainSound = nil

function XpDisplayController:Init()
    self:CreateXpDisplay()
    self:SetupRemoteEvents()
    self:LoadSounds()
    
    -- Request initial XP data
    RemoteEvents.RequestPlayerXp:FireServer()
    
    print("📊 XpDisplayController initialized")
end

function XpDisplayController:LoadSounds()
    -- Level up sound
    levelUpSound = Instance.new("Sound")
    levelUpSound.SoundId = "rbxasset://sounds/electronicpingshort.wav"
    levelUpSound.Volume = 0.8
    levelUpSound.Pitch = 1.5
    levelUpSound.Parent = SoundService
    
    -- XP gain sound
    xpGainSound = Instance.new("Sound")
    xpGainSound.SoundId = "rbxasset://sounds/impact_water.mp3"
    xpGainSound.Volume = 0.3
    xpGainSound.Pitch = 2.0
    xpGainSound.Parent = SoundService
end

function XpDisplayController:CreateXpDisplay()
    -- Remove existing GUI if it exists
    local existingGui = playerGui:FindFirstChild("XpDisplayGui")
    if existingGui then
        existingGui:Destroy()
    end
    
    -- Create main GUI
    xpGui = Instance.new("ScreenGui")
    xpGui.Name = "XpDisplayGui"
    xpGui.ResetOnSpawn = false
    xpGui.Parent = playerGui
    
    -- Main XP frame (positioned under player name)
    local xpFrame = Instance.new("Frame")
    xpFrame.Name = "XpFrame"
    xpFrame.Size = UDim2.new(0, 300, 0, 40)
    xpFrame.Position = UDim2.new(0.5, -150, 0, 60) -- Under default name display
    xpFrame.BackgroundTransparency = 1
    xpFrame.Parent = xpGui
    
    -- Level display
    local levelFrame = Instance.new("Frame")
    levelFrame.Name = "LevelFrame"
    levelFrame.Size = UDim2.new(0, 60, 0, 30)
    levelFrame.Position = UDim2.new(0, 0, 0, 5)
    levelFrame.BackgroundColor3 = Color3.fromRGB(70, 70, 70)
    levelFrame.BorderSizePixel = 0
    levelFrame.Parent = xpFrame
    
    local levelCorner = Instance.new("UICorner")
    levelCorner.CornerRadius = UDim.new(0, 8)
    levelCorner.Parent = levelFrame
    
    local levelBorder = Instance.new("UIStroke")
    levelBorder.Color = Color3.fromRGB(255, 215, 0)
    levelBorder.Thickness = 2
    levelBorder.Parent = levelFrame
    
    local levelLabel = Instance.new("TextLabel")
    levelLabel.Name = "LevelLabel"
    levelLabel.Size = UDim2.new(1, 0, 1, 0)
    levelLabel.BackgroundTransparency = 1
    levelLabel.Text = "1"
    levelLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    levelLabel.TextScaled = true
    levelLabel.Font = Enum.Font.GothamBold
    levelLabel.Parent = levelFrame
    
    -- XP bar background
    local xpBarBg = Instance.new("Frame")
    xpBarBg.Name = "XpBarBackground"
    xpBarBg.Size = UDim2.new(0, 220, 0, 20)
    xpBarBg.Position = UDim2.new(0, 70, 0, 10)
    xpBarBg.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
    xpBarBg.BorderSizePixel = 0
    xpBarBg.Parent = xpFrame
    
    local barBgCorner = Instance.new("UICorner")
    barBgCorner.CornerRadius = UDim.new(0, 10)
    barBgCorner.Parent = xpBarBg
    
    local barBgBorder = Instance.new("UIStroke")
    barBgBorder.Color = Color3.fromRGB(100, 100, 100)
    barBgBorder.Thickness = 1
    barBgBorder.Parent = xpBarBg
    
    -- XP bar fill
    local xpBarFill = Instance.new("Frame")
    xpBarFill.Name = "XpBarFill"
    xpBarFill.Size = UDim2.new(0, 0, 1, 0)
    xpBarFill.Position = UDim2.new(0, 0, 0, 0)
    xpBarFill.BackgroundColor3 = Color3.fromRGB(0, 255, 100)
    xpBarFill.BorderSizePixel = 0
    xpBarFill.Parent = xpBarBg
    
    local barFillCorner = Instance.new("UICorner")
    barFillCorner.CornerRadius = UDim.new(0, 10)
    barFillCorner.Parent = xpBarFill
    
    -- XP text overlay
    local xpTextLabel = Instance.new("TextLabel")
    xpTextLabel.Name = "XpTextLabel"
    xpTextLabel.Size = UDim2.new(1, 0, 1, 0)
    xpTextLabel.BackgroundTransparency = 1
    xpTextLabel.Text = "0 / 100 XP"
    xpTextLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    xpTextLabel.TextScaled = true
    xpTextLabel.Font = Enum.Font.Gotham
    xpTextLabel.TextStrokeTransparency = 0.5
    xpTextLabel.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
    xpTextLabel.Parent = xpBarBg
    
    -- Glow effect
    local glowFrame = Instance.new("Frame")
    glowFrame.Name = "GlowFrame"
    glowFrame.Size = UDim2.new(1, 4, 1, 4)
    glowFrame.Position = UDim2.new(0, -2, 0, -2)
    glowFrame.BackgroundColor3 = Color3.fromRGB(0, 255, 100)
    glowFrame.BackgroundTransparency = 0.8
    glowFrame.BorderSizePixel = 0
    glowFrame.ZIndex = xpBarBg.ZIndex - 1
    glowFrame.Parent = xpBarBg
    
    local glowCorner = Instance.new("UICorner")
    glowCorner.CornerRadius = UDim.new(0, 12)
    glowCorner.Parent = glowFrame
    
    print("📊 XP display GUI created")
end

function XpDisplayController:SetupRemoteEvents()
    -- Handle XP updates
    RemoteEvents.XpUpdated.OnClientEvent:Connect(function(newXp, newLevel, xpRequired)
        self:UpdateXpDisplay(newXp, newLevel, xpRequired)
    end)
    
    -- Handle level up events
    RemoteEvents.LevelUp.OnClientEvent:Connect(function(newLevel, xpGained)
        self:PlayLevelUpAnimation(newLevel, xpGained)
    end)
    
    -- Handle XP gain notifications
    RemoteEvents.XpGained.OnClientEvent:Connect(function(amount, reason)
        self:ShowXpGain(amount, reason)
    end)
end

function XpDisplayController:UpdateXpDisplay(newXp, newLevel, xpRequired)
    if not xpGui or not xpGui.Parent then
        return
    end
    
    currentXp = newXp
    currentLevel = newLevel
    xpToNextLevel = xpRequired
    
    local xpFrame = xpGui.XpFrame
    local levelLabel = xpFrame.LevelFrame.LevelLabel
    local xpBarFill = xpFrame.XpBarBackground.XpBarFill
    local xpTextLabel = xpFrame.XpBarBackground.XpTextLabel
    
    -- Update level display
    levelLabel.Text = tostring(currentLevel)
    
    -- Calculate XP progress for current level
    local xpForCurrentLevel = self:GetXpForLevel(currentLevel)
    local xpForNextLevel = self:GetXpForLevel(currentLevel + 1)
    local currentLevelXp = newXp - xpForCurrentLevel
    local xpNeededForLevel = xpForNextLevel - xpForCurrentLevel
    
    -- Update XP bar
    local fillPercentage = math.min(currentLevelXp / xpNeededForLevel, 1)
    
    local fillTween = TweenService:Create(
        xpBarFill,
        TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
        {Size = UDim2.new(fillPercentage, 0, 1, 0)}
    )
    fillTween:Play()
    
    -- Update text
    xpTextLabel.Text = currentLevelXp .. " / " .. xpNeededForLevel .. " XP"
    
    -- Play XP gain sound
    if xpGainSound then
        xpGainSound:Play()
    end
end

function XpDisplayController:GetXpForLevel(level)
    -- XP required to reach a specific level (cumulative)
    if level <= 1 then
        return 0
    end
    
    local totalXp = 0
    for i = 1, level - 1 do
        totalXp = totalXp + (i * 100) -- Each level requires level * 100 XP
    end
    return totalXp
end

function XpDisplayController:PlayLevelUpAnimation(newLevel, xpGained)
    if isAnimating then return end
    isAnimating = true
    
    -- Play level up sound
    if levelUpSound then
        levelUpSound:Play()
    end
    
    -- Create level up notification
    self:CreateLevelUpNotification(newLevel, xpGained)
    
    -- Create particle burst effect
    self:CreateLevelUpParticles()
    
    -- Animate XP bar glow
    self:AnimateXpBarGlow()
    
    -- Reset animation state
    spawn(function()
        wait(3)
        isAnimating = false
    end)
end

function XpDisplayController:CreateLevelUpNotification(newLevel, xpGained)
    -- Create level up notification
    local notification = Instance.new("Frame")
    notification.Name = "LevelUpNotification"
    notification.Size = UDim2.new(0, 400, 0, 100)
    notification.Position = UDim2.new(0.5, -200, 0.3, -50)
    notification.BackgroundColor3 = Color3.fromRGB(255, 215, 0)
    notification.BorderSizePixel = 0
    notification.Parent = xpGui
    
    local notifCorner = Instance.new("UICorner")
    notifCorner.CornerRadius = UDim.new(0, 15)
    notifCorner.Parent = notification
    
    local notifBorder = Instance.new("UIStroke")
    notifBorder.Color = Color3.fromRGB(255, 255, 255)
    notifBorder.Thickness = 3
    notifBorder.Parent = notification
    
    -- Level up text
    local levelUpText = Instance.new("TextLabel")
    levelUpText.Size = UDim2.new(1, 0, 0.6, 0)
    levelUpText.Position = UDim2.new(0, 0, 0, 0)
    levelUpText.BackgroundTransparency = 1
    levelUpText.Text = "🎉 LEVEL UP! 🎉"
    levelUpText.TextColor3 = Color3.fromRGB(0, 0, 0)
    levelUpText.TextScaled = true
    levelUpText.Font = Enum.Font.GothamBold
    levelUpText.Parent = notification
    
    -- New level text
    local newLevelText = Instance.new("TextLabel")
    newLevelText.Size = UDim2.new(1, 0, 0.4, 0)
    newLevelText.Position = UDim2.new(0, 0, 0.6, 0)
    newLevelText.BackgroundTransparency = 1
    newLevelText.Text = "Level " .. newLevel .. " Reached!"
    newLevelText.TextColor3 = Color3.fromRGB(50, 50, 50)
    newLevelText.TextScaled = true
    newLevelText.Font = Enum.Font.Gotham
    newLevelText.Parent = notification
    
    -- Animate notification
    notification.Position = UDim2.new(0.5, -200, -0.2, -50)
    local slideIn = TweenService:Create(
        notification,
        TweenInfo.new(0.8, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
        {Position = UDim2.new(0.5, -200, 0.3, -50)}
    )
    slideIn:Play()
    
    -- Auto-remove after showing
    spawn(function()
        wait(3)
        local slideOut = TweenService:Create(
            notification,
            TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
            {
                Position = UDim2.new(0.5, -200, -0.2, -50),
                BackgroundTransparency = 1
            }
        )
        slideOut:Play()
        slideOut.Completed:Connect(function()
            notification:Destroy()
        end)
    end)
end

function XpDisplayController:CreateLevelUpParticles()
    -- Create particle burst at XP bar location
    local xpFrame = xpGui.XpFrame
    local centerPosition = xpFrame.AbsolutePosition + (xpFrame.AbsoluteSize / 2)
    
    -- Create temporary attachment for particles
    local tempPart = Instance.new("Part")
    tempPart.Name = "LevelUpParticleAnchor"
    tempPart.Size = Vector3.new(0.1, 0.1, 0.1)
    tempPart.Position = Vector3.new(0, 50, 0) -- Above ground
    tempPart.Anchored = true
    tempPart.CanCollide = false
    tempPart.Transparency = 1
    tempPart.Parent = workspace
    
    local attachment = Instance.new("Attachment")
    attachment.Parent = tempPart
    
    -- Create particle emitter
    local particles = Instance.new("ParticleEmitter")
    particles.Parent = attachment
    particles.Texture = "rbxasset://textures/particles/sparkles_main.dds"
    particles.Lifetime = NumberRange.new(1, 2)
    particles.Rate = 200
    particles.SpreadAngle = Vector2.new(180, 180)
    particles.Speed = NumberRange.new(20, 40)
    particles.Acceleration = Vector3.new(0, -50, 0)
    
    -- Gold and white particles
    local colorSequence = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 255, 100)),
        ColorSequenceKeypoint.new(0.5, Color3.fromRGB(255, 215, 0)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 255, 255))
    })
    particles.Color = colorSequence
    
    particles.Size = NumberSequence.new({
        NumberSequenceKeypoint.new(0, 0),
        NumberSequenceKeypoint.new(0.2, 3),
        NumberSequenceKeypoint.new(1, 0)
    })
    
    particles.Transparency = NumberSequence.new({
        NumberSequenceKeypoint.new(0, 1),
        NumberSequenceKeypoint.new(0.1, 0),
        NumberSequenceKeypoint.new(1, 1)
    })
    
    -- Emit burst then clean up
    particles:Emit(100)
    
    spawn(function()
        wait(3)
        tempPart:Destroy()
    end)
end

function XpDisplayController:AnimateXpBarGlow()
    local xpFrame = xpGui.XpFrame
    local glowFrame = xpFrame.XpBarBackground.GlowFrame
    
    -- Pulse glow effect
    local glowPulse = TweenService:Create(
        glowFrame,
        TweenInfo.new(0.3, Enum.EasingStyle.Sine, Enum.EasingDirection.Out, 3, true),
        {BackgroundTransparency = 0.3}
    )
    glowPulse:Play()
end

function XpDisplayController:ShowXpGain(amount, reason)
    -- Show floating XP gain text
    local xpFrame = xpGui.XpFrame
    
    local xpGainLabel = Instance.new("TextLabel")
    xpGainLabel.Name = "XpGainFloat"
    xpGainLabel.Size = UDim2.new(0, 100, 0, 30)
    xpGainLabel.Position = UDim2.new(1, 10, 0, 5)
    xpGainLabel.BackgroundTransparency = 1
    xpGainLabel.Text = "+" .. amount .. " XP"
    xpGainLabel.TextColor3 = Color3.fromRGB(0, 255, 100)
    xpGainLabel.TextScaled = true
    xpGainLabel.Font = Enum.Font.GothamBold
    xpGainLabel.TextStrokeTransparency = 0
    xpGainLabel.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
    xpGainLabel.Parent = xpFrame
    
    -- Float upward animation
    local floatTween = TweenService:Create(
        xpGainLabel,
        TweenInfo.new(1.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
        {
            Position = UDim2.new(1, 10, 0, -30),
            TextTransparency = 1,
            TextStrokeTransparency = 1
        }
    )
    floatTween:Play()
    
    floatTween.Completed:Connect(function()
        xpGainLabel:Destroy()
    end)
end

function XpDisplayController:Hide()
    if xpGui then
        xpGui.Enabled = false
    end
end

function XpDisplayController:Show()
    if xpGui then
        xpGui.Enabled = true
    end
end

function XpDisplayController:Cleanup()
    if xpGui then
        xpGui:Destroy()
        xpGui = nil
    end
    currentXp = 0
    currentLevel = 1
    isAnimating = false
end

return XpDisplayController
