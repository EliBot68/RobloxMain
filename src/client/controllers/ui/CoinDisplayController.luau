-- CoinDisplayController.luau
-- Manages the persistent coin display GUI in top right corner

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SoundService = game:GetService("SoundService")

local RemoteEvents = require(ReplicatedStorage.Shared.modules.RemoteEvents)

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local CoinDisplayController = {}

-- GUI state
local coinGui = nil
local currentCoins = 0
local isAnimating = false

-- Sound effects
local coinUpdateSound = nil

function CoinDisplayController:Init()
    self:CreateCoinDisplay()
    self:SetupRemoteEvents()
    self:LoadSounds()
    
    -- Request initial coin count
    RemoteEvents.RequestPlayerCoins:FireServer()
    
    print("💰 CoinDisplayController initialized")
end

function CoinDisplayController:LoadSounds()
    -- Load coin update sound
    coinUpdateSound = Instance.new("Sound")
    coinUpdateSound.SoundId = "rbxasset://sounds/electronicpingshort.wav"
    coinUpdateSound.Volume = 0.4
    coinUpdateSound.Pitch = 1.3
    coinUpdateSound.Parent = SoundService
end

function CoinDisplayController:CreateCoinDisplay()
    -- Remove existing GUI if it exists
    local existingGui = playerGui:FindFirstChild("CoinDisplayGui")
    if existingGui then
        existingGui:Destroy()
    end
    
    -- Create main GUI
    coinGui = Instance.new("ScreenGui")
    coinGui.Name = "CoinDisplayGui"
    coinGui.ResetOnSpawn = false
    coinGui.Parent = playerGui
    
    -- Main coin frame
    local coinFrame = Instance.new("Frame")
    coinFrame.Name = "CoinFrame"
    coinFrame.Size = UDim2.new(0, 180, 0, 50)
    coinFrame.Position = UDim2.new(1, -200, 0, 20) -- Top right corner
    coinFrame.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
    coinFrame.BackgroundTransparency = 0.1
    coinFrame.BorderSizePixel = 0
    coinFrame.Parent = coinGui
    
    -- Add rounded corners
    local frameCorner = Instance.new("UICorner")
    frameCorner.CornerRadius = UDim.new(0, 12)
    frameCorner.Parent = coinFrame
    
    -- Add border effect
    local frameBorder = Instance.new("UIStroke")
    frameBorder.Color = Color3.fromRGB(255, 215, 0) -- Gold border
    frameBorder.Thickness = 2
    frameBorder.Transparency = 0.3
    frameBorder.Parent = coinFrame
    
    -- Coin icon
    local coinIcon = Instance.new("TextLabel")
    coinIcon.Name = "CoinIcon"
    coinIcon.Size = UDim2.new(0, 40, 0, 40)
    coinIcon.Position = UDim2.new(0, 5, 0, 5)
    coinIcon.BackgroundTransparency = 1
    coinIcon.Text = "💰"
    coinIcon.TextColor3 = Color3.fromRGB(255, 215, 0)
    coinIcon.TextScaled = true
    coinIcon.Font = Enum.Font.SourceSansBold
    coinIcon.Parent = coinFrame
    
    -- Coin count label
    local coinLabel = Instance.new("TextLabel")
    coinLabel.Name = "CoinLabel"
    coinLabel.Size = UDim2.new(0, 125, 0, 40)
    coinLabel.Position = UDim2.new(0, 50, 0, 5)
    coinLabel.BackgroundTransparency = 1
    coinLabel.Text = "0"
    coinLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    coinLabel.TextScaled = true
    coinLabel.Font = Enum.Font.GothamBold
    coinLabel.TextXAlignment = Enum.TextXAlignment.Left
    coinLabel.Parent = coinFrame
    
    -- Add subtle glow effect
    local glowFrame = Instance.new("Frame")
    glowFrame.Name = "GlowFrame"
    glowFrame.Size = UDim2.new(1, 4, 1, 4)
    glowFrame.Position = UDim2.new(0, -2, 0, -2)
    glowFrame.BackgroundColor3 = Color3.fromRGB(255, 215, 0)
    glowFrame.BackgroundTransparency = 0.9
    glowFrame.BorderSizePixel = 0
    glowFrame.ZIndex = coinFrame.ZIndex - 1
    glowFrame.Parent = coinFrame
    
    local glowCorner = Instance.new("UICorner")
    glowCorner.CornerRadius = UDim.new(0, 14)
    glowCorner.Parent = glowFrame
    
    print("💰 Coin display GUI created")
end

function CoinDisplayController:SetupRemoteEvents()
    -- Handle coin updates
    RemoteEvents.CoinBalanceUpdated.OnClientEvent:Connect(function(newCoinCount)
        self:UpdateCoinDisplay(newCoinCount)
    end)
    
    -- Handle coin collection during runs
    RemoteEvents.CoinCollected.OnClientEvent:Connect(function(newTotal)
        self:UpdateCoinDisplay(newTotal, true) -- Animate collection
    end)
    
    -- Handle instant coin updates (after purchases, rewards, etc.)
    RemoteEvents.InstantCoinUpdate.OnClientEvent:Connect(function(newCoinCount)
        self:UpdateCoinDisplay(newCoinCount, false)
    end)
end

function CoinDisplayController:UpdateCoinDisplay(newCoins, animate)
    if not coinGui or not coinGui.Parent then
        return
    end
    
    local coinFrame = coinGui.CoinFrame
    local coinLabel = coinFrame.CoinLabel
    local coinIcon = coinFrame.CoinIcon
    
    local oldCoins = currentCoins
    currentCoins = newCoins
    
    -- Update text with number formatting
    coinLabel.Text = self:FormatNumber(currentCoins)
    
    if animate and not isAnimating and newCoins > oldCoins then
        self:PlayCoinAnimation(coinFrame, coinIcon, coinLabel)
    end
end

function CoinDisplayController:FormatNumber(number)
    -- Format large numbers with K, M abbreviations
    if number >= 1000000 then
        return string.format("%.1fM", number / 1000000)
    elseif number >= 1000 then
        return string.format("%.1fK", number / 1000)
    else
        return tostring(number)
    end
end

function CoinDisplayController:PlayCoinAnimation(coinFrame, coinIcon, coinLabel)
    if isAnimating then return end
    isAnimating = true
    
    -- Play sound effect
    if coinUpdateSound then
        coinUpdateSound:Play()
    end
    
    -- Bounce animation
    local originalSize = coinFrame.Size
    local bounceSize = UDim2.new(originalSize.X.Scale, originalSize.X.Offset + 20, 
                                originalSize.Y.Scale, originalSize.Y.Offset + 10)
    
    local bounceIn = TweenService:Create(
        coinFrame,
        TweenInfo.new(0.2, Enum.EasingStyle.Bounce, Enum.EasingDirection.Out),
        {Size = bounceSize}
    )
    
    local bounceOut = TweenService:Create(
        coinFrame,
        TweenInfo.new(0.3, Enum.EasingStyle.Bounce, Enum.EasingDirection.Out),
        {Size = originalSize}
    )
    
    -- Coin icon spin
    local iconSpin = TweenService:Create(
        coinIcon,
        TweenInfo.new(0.5, Enum.EasingStyle.Linear),
        {Rotation = 360}
    )
    
    -- Text flash
    local originalColor = coinLabel.TextColor3
    local flashColor = Color3.fromRGB(255, 255, 100) -- Bright yellow flash
    
    local textFlash = TweenService:Create(
        coinLabel,
        TweenInfo.new(0.1, Enum.EasingStyle.Quad),
        {TextColor3 = flashColor}
    )
    
    local textRestore = TweenService:Create(
        coinLabel,
        TweenInfo.new(0.4, Enum.EasingStyle.Quad),
        {TextColor3 = originalColor}
    )
    
    -- Glow pulse
    local glowFrame = coinFrame.GlowFrame
    local glowPulse = TweenService:Create(
        glowFrame,
        TweenInfo.new(0.4, Enum.EasingStyle.Sine, Enum.EasingDirection.Out),
        {BackgroundTransparency = 0.7}
    )
    
    local glowRestore = TweenService:Create(
        glowFrame,
        TweenInfo.new(0.6, Enum.EasingStyle.Sine, Enum.EasingDirection.Out),
        {BackgroundTransparency = 0.9}
    )
    
    -- Play animations
    bounceIn:Play()
    iconSpin:Play()
    textFlash:Play()
    glowPulse:Play()
    
    bounceIn.Completed:Connect(function()
        bounceOut:Play()
    end)
    
    textFlash.Completed:Connect(function()
        textRestore:Play()
    end)
    
    glowPulse.Completed:Connect(function()
        glowRestore:Play()
    end)
    
    -- Reset icon rotation and animation state
    iconSpin.Completed:Connect(function()
        coinIcon.Rotation = 0
        isAnimating = false
    end)
end

function CoinDisplayController:ShowCoinReward(amount, reason)
    -- Show temporary reward notification
    local rewardGui = Instance.new("Frame")
    rewardGui.Name = "CoinRewardNotification"
    rewardGui.Size = UDim2.new(0, 200, 0, 60)
    rewardGui.Position = UDim2.new(1, -220, 0, 80) -- Below main coin display
    rewardGui.BackgroundColor3 = Color3.fromRGB(0, 150, 0)
    rewardGui.BackgroundTransparency = 0.1
    rewardGui.BorderSizePixel = 0
    rewardGui.Parent = coinGui
    
    local rewardCorner = Instance.new("UICorner")
    rewardCorner.CornerRadius = UDim.new(0, 10)
    rewardCorner.Parent = rewardGui
    
    local rewardLabel = Instance.new("TextLabel")
    rewardLabel.Size = UDim2.new(1, 0, 0.6, 0)
    rewardLabel.Position = UDim2.new(0, 0, 0, 0)
    rewardLabel.BackgroundTransparency = 1
    rewardLabel.Text = "+" .. amount .. " Coins!"
    rewardLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    rewardLabel.TextScaled = true
    rewardLabel.Font = Enum.Font.GothamBold
    rewardLabel.Parent = rewardGui
    
    local reasonLabel = Instance.new("TextLabel")
    reasonLabel.Size = UDim2.new(1, 0, 0.4, 0)
    reasonLabel.Position = UDim2.new(0, 0, 0.6, 0)
    reasonLabel.BackgroundTransparency = 1
    reasonLabel.Text = reason or "Reward"
    reasonLabel.TextColor3 = Color3.fromRGB(200, 255, 200)
    reasonLabel.TextScaled = true
    reasonLabel.Font = Enum.Font.Gotham
    reasonLabel.Parent = rewardGui
    
    -- Slide in animation
    rewardGui.Position = UDim2.new(1, 0, 0, 80)
    local slideIn = TweenService:Create(
        rewardGui,
        TweenInfo.new(0.5, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
        {Position = UDim2.new(1, -220, 0, 80)}
    )
    slideIn:Play()
    
    -- Auto-remove after 3 seconds
    spawn(function()
        wait(3)
        local slideOut = TweenService:Create(
            rewardGui,
            TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
            {Position = UDim2.new(1, 0, 0, 80)}
        )
        slideOut:Play()
        slideOut.Completed:Connect(function()
            rewardGui:Destroy()
        end)
    end)
end

function CoinDisplayController:GetCurrentCoins()
    return currentCoins
end

function CoinDisplayController:Hide()
    if coinGui then
        coinGui.Enabled = false
    end
end

function CoinDisplayController:Show()
    if coinGui then
        coinGui.Enabled = true
    end
end

function CoinDisplayController:Cleanup()
    if coinGui then
        coinGui:Destroy()
        coinGui = nil
    end
    currentCoins = 0
    isAnimating = false
end

return CoinDisplayController
