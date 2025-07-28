-- StreakController.luau
-- Handles client-side daily streak UI, notifications, and effects

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local SoundService = game:GetService("SoundService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local RemoteEvents = require(ReplicatedStorage.Shared.modules.RemoteEvents)

local StreakController = {}

-- UI State
local streakUI = nil
local currentStreakData = nil

function StreakController:Init()
    self:SetupRemoteConnections()
    print("✅ StreakController initialized")
end

function StreakController:SetupRemoteConnections()
    -- Show streak UI
    RemoteEvents.ShowStreakUI.OnClientEvent:Connect(function(streakData)
        self:ShowStreakInterface(streakData)
    end)
    
    -- Show streak reward
    RemoteEvents.ShowStreakReward.OnClientEvent:Connect(function(rewardData)
        self:ShowRewardNotification(rewardData)
    end)
    
    -- Show streak available notification
    RemoteEvents.ShowStreakAvailable.OnClientEvent:Connect(function(availableData)
        self:ShowStreakAvailableNotification(availableData)
    end)
    
    -- Play special sounds
    RemoteEvents.PlaySpecialSound.OnClientEvent:Connect(function(soundType)
        self:PlaySpecialSound(soundType)
    end)
end

function StreakController:ShowStreakInterface(streakData)
    currentStreakData = streakData
    
    -- Remove existing UI if present
    if streakUI then
        streakUI:Destroy()
    end
    
    -- Create streak UI
    streakUI = Instance.new("ScreenGui")
    streakUI.Name = "StreakUI"
    streakUI.Parent = playerGui
    
    -- Main frame
    local mainFrame = Instance.new("Frame")
    mainFrame.Size = UDim2.new(0, 500, 0, 400)
    mainFrame.Position = UDim2.new(0.5, -250, 0.5, -200)
    mainFrame.BackgroundColor3 = Color3.fromRGB(40, 40, 60)
    mainFrame.BorderSizePixel = 0
    mainFrame.Parent = streakUI
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 15)
    corner.Parent = mainFrame
    
    -- Title
    local titleLabel = Instance.new("TextLabel")
    titleLabel.Size = UDim2.new(1, 0, 0, 60)
    titleLabel.Position = UDim2.new(0, 0, 0, 10)
    titleLabel.BackgroundTransparency = 1
    titleLabel.Text = "🔥 DAILY STREAK REWARDS"
    titleLabel.TextColor3 = Color3.fromRGB(255, 215, 0)
    titleLabel.TextScaled = true
    titleLabel.Font = Enum.Font.GothamBold
    titleLabel.Parent = mainFrame
    
    -- Current streak display
    local streakFrame = Instance.new("Frame")
    streakFrame.Size = UDim2.new(1, -20, 0, 80)
    streakFrame.Position = UDim2.new(0, 10, 0, 80)
    streakFrame.BackgroundColor3 = Color3.fromRGB(60, 60, 80)
    streakFrame.BorderSizePixel = 0
    streakFrame.Parent = mainFrame
    
    local streakCorner = Instance.new("UICorner")
    streakCorner.CornerRadius = UDim.new(0, 10)
    streakCorner.Parent = streakFrame
    
    local currentStreakLabel = Instance.new("TextLabel")
    currentStreakLabel.Size = UDim2.new(0.5, 0, 1, 0)
    currentStreakLabel.BackgroundTransparency = 1
    currentStreakLabel.Text = "Current Streak\n" .. streakData.currentStreak .. " Days"
    currentStreakLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    currentStreakLabel.TextScaled = true
    currentStreakLabel.Font = Enum.Font.GothamBold
    currentStreakLabel.Parent = streakFrame
    
    local longestStreakLabel = Instance.new("TextLabel")
    longestStreakLabel.Size = UDim2.new(0.5, 0, 1, 0)
    longestStreakLabel.Position = UDim2.new(0.5, 0, 0, 0)
    longestStreakLabel.BackgroundTransparency = 1
    longestStreakLabel.Text = "Longest Streak\n" .. streakData.longestStreak .. " Days"
    longestStreakLabel.TextColor3 = Color3.fromRGB(200, 200, 255)
    longestStreakLabel.TextScaled = true
    longestStreakLabel.Font = Enum.Font.Gotham
    longestStreakLabel.Parent = streakFrame
    
    -- Today's reward section
    local rewardFrame = Instance.new("Frame")
    rewardFrame.Size = UDim2.new(1, -20, 0, 120)
    rewardFrame.Position = UDim2.new(0, 10, 0, 180)
    rewardFrame.BackgroundColor3 = Color3.fromRGB(80, 120, 80)
    rewardFrame.BorderSizePixel = 0
    rewardFrame.Parent = mainFrame
    
    local rewardCorner = Instance.new("UICorner")
    rewardCorner.CornerRadius = UDim.new(0, 10)
    rewardCorner.Parent = rewardFrame
    
    local rewardTitleLabel = Instance.new("TextLabel")
    rewardTitleLabel.Size = UDim2.new(1, 0, 0, 30)
    rewardTitleLabel.Position = UDim2.new(0, 0, 0, 5)
    rewardTitleLabel.BackgroundTransparency = 1
    rewardTitleLabel.Text = "Today's Reward (Day " .. streakData.currentStreak .. ")"
    rewardTitleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    rewardTitleLabel.TextScaled = true
    rewardTitleLabel.Font = Enum.Font.GothamBold
    rewardTitleLabel.Parent = rewardFrame
    
    local rewardDescLabel = Instance.new("TextLabel")
    rewardDescLabel.Size = UDim2.new(1, 0, 0, 40)
    rewardDescLabel.Position = UDim2.new(0, 0, 0, 35)
    rewardDescLabel.BackgroundTransparency = 1
    rewardDescLabel.Text = streakData.currentReward.coins .. " Coins"
    rewardDescLabel.TextColor3 = Color3.fromRGB(255, 215, 0)
    rewardDescLabel.TextScaled = true
    rewardDescLabel.Font = Enum.Font.Gotham
    rewardDescLabel.Parent = rewardFrame
    
    -- Add special effect text if applicable
    if streakData.currentReward.type ~= "coins" then
        rewardDescLabel.Text = rewardDescLabel.Text .. "\n+ Special Effect!"
    end
    
    -- Claim button
    local claimButton = Instance.new("TextButton")
    claimButton.Size = UDim2.new(0, 200, 0, 40)
    claimButton.Position = UDim2.new(0.5, -100, 0, 75)
    claimButton.BackgroundColor3 = streakData.canClaimToday and Color3.fromRGB(0, 150, 0) or Color3.fromRGB(100, 100, 100)
    claimButton.Text = streakData.canClaimToday and "CLAIM REWARD" or "ALREADY CLAIMED"
    claimButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    claimButton.TextScaled = true
    claimButton.Font = Enum.Font.GothamBold
    claimButton.BorderSizePixel = 0
    claimButton.Active = streakData.canClaimToday
    claimButton.Parent = rewardFrame
    
    local buttonCorner = Instance.new("UICorner")
    buttonCorner.CornerRadius = UDim.new(0, 8)
    buttonCorner.Parent = claimButton
    
    -- Next reward preview
    local nextRewardLabel = Instance.new("TextLabel")
    nextRewardLabel.Size = UDim2.new(1, -20, 0, 40)
    nextRewardLabel.Position = UDim2.new(0, 10, 0, 320)
    nextRewardLabel.BackgroundTransparency = 1
    nextRewardLabel.Text = "Tomorrow (Day " .. (streakData.currentStreak + 1) .. "): " .. streakData.nextReward.coins .. " Coins"
    nextRewardLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
    nextRewardLabel.TextScaled = true
    nextRewardLabel.Font = Enum.Font.Gotham
    nextRewardLabel.Parent = mainFrame
    
    -- Close button
    local closeButton = Instance.new("TextButton")
    closeButton.Size = UDim2.new(0, 30, 0, 30)
    closeButton.Position = UDim2.new(1, -40, 0, 10)
    closeButton.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
    closeButton.Text = "✕"
    closeButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    closeButton.TextScaled = true
    closeButton.Font = Enum.Font.GothamBold
    closeButton.BorderSizePixel = 0
    closeButton.Parent = mainFrame
    
    local closeCorner = Instance.new("UICorner")
    closeCorner.CornerRadius = UDim.new(0, 15)
    closeCorner.Parent = closeButton
    
    -- Button events
    if streakData.canClaimToday then
        claimButton.MouseButton1Click:Connect(function()
            self:ClaimDailyReward()
        end)
        
        -- Add hover effect
        claimButton.MouseEnter:Connect(function()
            TweenService:Create(claimButton, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(0, 180, 0)}):Play()
        end)
        
        claimButton.MouseLeave:Connect(function()
            TweenService:Create(claimButton, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(0, 150, 0)}):Play()
        end)
    end
    
    closeButton.MouseButton1Click:Connect(function()
        self:CloseStreakUI()
    end)
    
    -- Animate UI appearance
    mainFrame.Size = UDim2.new(0, 0, 0, 0)
    local appearTween = TweenService:Create(mainFrame, TweenInfo.new(0.3, Enum.EasingStyle.Back), {
        Size = UDim2.new(0, 500, 0, 400)
    })
    appearTween:Play()
end

function StreakController:ClaimDailyReward()
    RemoteEvents.ClaimDailyStreak:FireServer()
    
    -- Disable button temporarily
    if streakUI then
        local claimButton = streakUI:FindFirstChild("Frame"):FindFirstChild("Frame"):FindFirstChild("TextButton")
        if claimButton then
            claimButton.Active = false
            claimButton.BackgroundColor3 = Color3.fromRGB(100, 100, 100)
            claimButton.Text = "CLAIMING..."
        end
    end
end

function StreakController:ShowRewardNotification(rewardData)
    -- Create reward notification
    local rewardNotif = Instance.new("ScreenGui")
    rewardNotif.Name = "StreakRewardNotification"
    rewardNotif.Parent = playerGui
    
    local notifFrame = Instance.new("Frame")
    notifFrame.Size = UDim2.new(0, 400, 0, 150)
    notifFrame.Position = UDim2.new(0.5, -200, 0.3, 0)
    notifFrame.BackgroundColor3 = Color3.fromRGB(255, 215, 0)
    notifFrame.BorderSizePixel = 0
    notifFrame.Parent = rewardNotif
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 20)
    corner.Parent = notifFrame
    
    local streakLabel = Instance.new("TextLabel")
    streakLabel.Size = UDim2.new(1, 0, 0.3, 0)
    streakLabel.BackgroundTransparency = 1
    streakLabel.Text = "DAY " .. rewardData.day .. " STREAK!"
    streakLabel.TextColor3 = Color3.fromRGB(0, 0, 0)
    streakLabel.TextScaled = true
    streakLabel.Font = Enum.Font.GothamBold
    streakLabel.Parent = notifFrame
    
    local rewardLabel = Instance.new("TextLabel")
    rewardLabel.Size = UDim2.new(1, 0, 0.3, 0)
    rewardLabel.Position = UDim2.new(0, 0, 0.3, 0)
    rewardLabel.BackgroundTransparency = 1
    rewardLabel.Text = "+" .. rewardData.coins .. " COINS EARNED!"
    rewardLabel.TextColor3 = Color3.fromRGB(50, 50, 50)
    rewardLabel.TextScaled = true
    rewardLabel.Font = Enum.Font.GothamBold
    rewardLabel.Parent = notifFrame
    
    local messageLabel = Instance.new("TextLabel")
    messageLabel.Size = UDim2.new(1, 0, 0.4, 0)
    messageLabel.Position = UDim2.new(0, 0, 0.6, 0)
    messageLabel.BackgroundTransparency = 1
    messageLabel.Text = rewardData.message
    messageLabel.TextColor3 = Color3.fromRGB(80, 80, 80)
    messageLabel.TextScaled = true
    messageLabel.Font = Enum.Font.Gotham
    messageLabel.Parent = notifFrame
    
    -- Animate notification
    notifFrame.Size = UDim2.new(0, 0, 0, 0)
    local appearTween = TweenService:Create(notifFrame, TweenInfo.new(0.5, Enum.EasingStyle.Back), {
        Size = UDim2.new(0, 400, 0, 150)
    })
    
    appearTween:Play()
    
    -- Play reward sound
    local rewardSound = Instance.new("Sound")
    rewardSound.SoundId = "rbxasset://sounds/electronicpingshort.wav"
    rewardSound.Volume = 0.6
    rewardSound.Parent = workspace
    rewardSound:Play()
    
    rewardSound.Ended:Connect(function()
        rewardSound:Destroy()
    end)
    
    -- Auto-remove after delay
    wait(4)
    local fadeOut = TweenService:Create(notifFrame, TweenInfo.new(0.5, Enum.EasingStyle.Quad), {
        Position = UDim2.new(0.5, -200, 0.1, 0),
        BackgroundTransparency = 1
    })
    
    TweenService:Create(streakLabel, TweenInfo.new(0.5, Enum.EasingStyle.Quad), {TextTransparency = 1}):Play()
    TweenService:Create(rewardLabel, TweenInfo.new(0.5, Enum.EasingStyle.Quad), {TextTransparency = 1}):Play()
    TweenService:Create(messageLabel, TweenInfo.new(0.5, Enum.EasingStyle.Quad), {TextTransparency = 1}):Play()
    
    fadeOut:Play()
    fadeOut.Completed:Connect(function()
        rewardNotif:Destroy()
    end)
    
    -- Update UI if open
    if streakUI then
        self:CloseStreakUI()
    end
end

function StreakController:ShowStreakAvailableNotification(availableData)
    -- Create small notification that streak is available
    local availNotif = Instance.new("ScreenGui")
    availNotif.Name = "StreakAvailableNotification"
    availNotif.Parent = playerGui
    
    local availFrame = Instance.new("Frame")
    availFrame.Size = UDim2.new(0, 300, 0, 80)
    availFrame.Position = UDim2.new(1, -320, 0, 20)
    availFrame.BackgroundColor3 = Color3.fromRGB(255, 165, 0)
    availFrame.BorderSizePixel = 0
    availFrame.Parent = availNotif
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 12)
    corner.Parent = availFrame
    
    local availLabel = Instance.new("TextLabel")
    availLabel.Size = UDim2.new(1, 0, 0.6, 0)
    availLabel.BackgroundTransparency = 1
    availLabel.Text = "🔥 Daily Streak Available!"
    availLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    availLabel.TextScaled = true
    availLabel.Font = Enum.Font.GothamBold
    availLabel.Parent = availFrame
    
    local clickLabel = Instance.new("TextLabel")
    clickLabel.Size = UDim2.new(1, 0, 0.4, 0)
    clickLabel.Position = UDim2.new(0, 0, 0.6, 0)
    clickLabel.BackgroundTransparency = 1
    clickLabel.Text = "Visit the Daily Streak stall!"
    clickLabel.TextColor3 = Color3.fromRGB(220, 220, 220)
    clickLabel.TextScaled = true
    clickLabel.Font = Enum.Font.Gotham
    clickLabel.Parent = availFrame
    
    -- Slide in animation
    availFrame.Position = UDim2.new(1, 0, 0, 20)
    local slideIn = TweenService:Create(availFrame, TweenInfo.new(0.5, Enum.EasingStyle.Back), {
        Position = UDim2.new(1, -320, 0, 20)
    })
    slideIn:Play()
    
    -- Auto-remove after delay
    wait(5)
    local slideOut = TweenService:Create(availFrame, TweenInfo.new(0.3, Enum.EasingStyle.Quad), {
        Position = UDim2.new(1, 0, 0, 20)
    })
    slideOut:Play()
    slideOut.Completed:Connect(function()
        availNotif:Destroy()
    end)
end

function StreakController:PlaySpecialSound(soundType)
    local soundId = "rbxasset://sounds/electronicpingshort.wav" -- Default
    
    if soundType == "mega_reward" then
        soundId = "rbxasset://sounds/bell.wav"
    elseif soundType == "ultimate_reward" then
        soundId = "rbxasset://sounds/bell.wav" -- Use different sound in production
    end
    
    local specialSound = Instance.new("Sound")
    specialSound.SoundId = soundId
    specialSound.Volume = 0.8
    specialSound.Parent = workspace
    specialSound:Play()
    
    specialSound.Ended:Connect(function()
        specialSound:Destroy()
    end)
end

function StreakController:CloseStreakUI()
    if streakUI then
        local mainFrame = streakUI:FindFirstChild("Frame")
        if mainFrame then
            local closeTween = TweenService:Create(mainFrame, TweenInfo.new(0.2, Enum.EasingStyle.Quad), {
                Size = UDim2.new(0, 0, 0, 0)
            })
            closeTween:Play()
            closeTween.Completed:Connect(function()
                streakUI:Destroy()
                streakUI = nil
            end)
        else
            streakUI:Destroy()
            streakUI = nil
        end
    end
end

return StreakController
