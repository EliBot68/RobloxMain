-- DailyRewardController.luau
-- Daily reward system with 7-day cycle and login popups

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local RemoteEvents = require(ReplicatedStorage.Shared.modules.RemoteEvents)

local DailyRewardController = {}

-- UI Elements
local dailyRewardGui = nil
local rewardPopup = nil
local countdownTimer = nil
local isPopupOpen = false

-- Daily rewards configuration (matches server)
local DAILY_REWARDS = {
    [1] = {coins = 100, xp = 50, crateKeys = 0, special = nil},
    [2] = {coins = 150, xp = 75, crateKeys = 0, special = nil},
    [3] = {coins = 200, xp = 100, crateKeys = 1, special = "Crate Key"},
    [4] = {coins = 300, xp = 150, crateKeys = 0, special = nil},
    [5] = {coins = 400, xp = 200, crateKeys = 1, special = "Crate Key"},
    [6] = {coins = 500, xp = 250, crateKeys = 0, special = nil},
    [7] = {coins = 1000, xp = 500, crateKeys = 3, special = "MEGA BONUS"}
}

function DailyRewardController:CreateDailyRewardGUI()
    -- Main GUI container
    dailyRewardGui = Instance.new("ScreenGui")
    dailyRewardGui.Name = "DailyRewardGui"
    dailyRewardGui.ResetOnSpawn = false
    dailyRewardGui.Enabled = false
    dailyRewardGui.Parent = playerGui
    
    -- Overlay background
    local overlay = Instance.new("Frame")
    overlay.Name = "Overlay"
    overlay.Size = UDim2.new(1, 0, 1, 0)
    overlay.Position = UDim2.new(0, 0, 0, 0)
    overlay.BackgroundColor3 = Color3.new(0, 0, 0)
    overlay.BackgroundTransparency = 0.5
    overlay.BorderSizePixel = 0
    overlay.Parent = dailyRewardGui
    
    -- Main popup frame
    rewardPopup = Instance.new("Frame")
    rewardPopup.Name = "RewardPopup"
    rewardPopup.Size = UDim2.new(0, 500, 0, 700)
    rewardPopup.Position = UDim2.new(0.5, -250, 0.5, -350)
    rewardPopup.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
    rewardPopup.BorderSizePixel = 0
    rewardPopup.Parent = overlay
    
    local popupCorner = Instance.new("UICorner")
    popupCorner.CornerRadius = UDim.new(0, 20)
    popupCorner.Parent = rewardPopup
    
    -- Glow effect
    local glow = Instance.new("Frame")
    glow.Name = "Glow"
    glow.Size = UDim2.new(1, 20, 1, 20)
    glow.Position = UDim2.new(0, -10, 0, -10)
    glow.BackgroundColor3 = Color3.fromRGB(255, 215, 0)
    glow.BackgroundTransparency = 0.7
    glow.BorderSizePixel = 0
    glow.ZIndex = rewardPopup.ZIndex - 1
    glow.Parent = rewardPopup
    
    local glowCorner = Instance.new("UICorner")
    glowCorner.CornerRadius = UDim.new(0, 25)
    glowCorner.Parent = glow
    
    -- Animate glow
    local glowTween = TweenService:Create(glow,
        TweenInfo.new(2, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true),
        {BackgroundTransparency = 0.4}
    )
    glowTween:Play()
    
    -- Header
    local header = Instance.new("Frame")
    header.Name = "Header"
    header.Size = UDim2.new(1, 0, 0, 100)
    header.Position = UDim2.new(0, 0, 0, 0)
    header.BackgroundColor3 = Color3.fromRGB(255, 215, 0)
    header.BorderSizePixel = 0
    header.Parent = rewardPopup
    
    local headerCorner = Instance.new("UICorner")
    headerCorner.CornerRadius = UDim.new(0, 20)
    headerCorner.Parent = header
    
    -- Fix header corner to only round top
    local headerBottomCover = Instance.new("Frame")
    headerBottomCover.Size = UDim2.new(1, 0, 0, 20)
    headerBottomCover.Position = UDim2.new(0, 0, 1, -20)
    headerBottomCover.BackgroundColor3 = Color3.fromRGB(255, 215, 0)
    headerBottomCover.BorderSizePixel = 0
    headerBottomCover.Parent = header
    
    -- Title
    local title = Instance.new("TextLabel")
    title.Name = "Title"
    title.Size = UDim2.new(1, -60, 1, 0)
    title.Position = UDim2.new(0, 20, 0, 0)
    title.BackgroundTransparency = 1
    title.Text = "🎁 DAILY REWARDS"
    title.TextColor3 = Color3.new(0, 0, 0)
    title.TextSize = 28
    title.Font = Enum.Font.GothamBold
    title.TextStrokeTransparency = 0
    title.TextStrokeColor3 = Color3.new(1, 1, 1)
    title.Parent = header
    
    -- Close button
    local closeButton = Instance.new("TextButton")
    closeButton.Name = "CloseButton"
    closeButton.Size = UDim2.new(0, 40, 0, 40)
    closeButton.Position = UDim2.new(1, -50, 0, 10)
    closeButton.BackgroundColor3 = Color3.fromRGB(200, 100, 100)
    closeButton.BorderSizePixel = 0
    closeButton.Text = "✕"
    closeButton.TextColor3 = Color3.new(1, 1, 1)
    closeButton.TextSize = 20
    closeButton.Font = Enum.Font.GothamBold
    closeButton.Parent = header
    
    local closeCorner = Instance.new("UICorner")
    closeCorner.CornerRadius = UDim.new(0, 8)
    closeCorner.Parent = closeButton
    
    -- Reward days container
    local rewardContainer = Instance.new("ScrollingFrame")
    rewardContainer.Name = "RewardContainer"
    rewardContainer.Size = UDim2.new(1, -20, 1, -250)
    rewardContainer.Position = UDim2.new(0, 10, 0, 110)
    rewardContainer.BackgroundTransparency = 1
    rewardContainer.BorderSizePixel = 0
    rewardContainer.ScrollBarThickness = 6
    rewardContainer.ScrollBarImageColor3 = Color3.fromRGB(255, 215, 0)
    rewardContainer.Parent = rewardPopup
    
    local containerLayout = Instance.new("UIListLayout")
    containerLayout.SortOrder = Enum.SortOrder.LayoutOrder
    containerLayout.Padding = UDim.new(0, 10)
    containerLayout.Parent = rewardContainer
    
    -- Create 7 reward day cards
    for day = 1, 7 do
        self:CreateRewardDayCard(day, rewardContainer)
    end
    
    -- Update canvas size
    rewardContainer.CanvasSize = UDim2.new(0, 0, 0, containerLayout.AbsoluteContentSize.Y + 20)
    
    -- Countdown timer
    local timerFrame = Instance.new("Frame")
    timerFrame.Name = "TimerFrame"
    timerFrame.Size = UDim2.new(1, -20, 0, 80)
    timerFrame.Position = UDim2.new(0, 10, 1, -90)
    timerFrame.BackgroundColor3 = Color3.fromRGB(50, 50, 60)
    timerFrame.BorderSizePixel = 0
    timerFrame.Parent = rewardPopup
    
    local timerCorner = Instance.new("UICorner")
    timerCorner.CornerRadius = UDim.new(0, 12)
    timerCorner.Parent = timerFrame
    
    local timerIcon = Instance.new("TextLabel")
    timerIcon.Size = UDim2.new(0, 50, 0, 50)
    timerIcon.Position = UDim2.new(0, 15, 0, 15)
    timerIcon.BackgroundTransparency = 1
    timerIcon.Text = "⏰"
    timerIcon.TextSize = 32
    timerIcon.Font = Enum.Font.GothamBold
    timerIcon.Parent = timerFrame
    
    countdownTimer = Instance.new("TextLabel")
    countdownTimer.Name = "CountdownTimer"
    countdownTimer.Size = UDim2.new(1, -80, 1, 0)
    countdownTimer.Position = UDim2.new(0, 70, 0, 0)
    countdownTimer.BackgroundTransparency = 1
    countdownTimer.Text = "Next reward in: --:--:--"
    countdownTimer.TextColor3 = Color3.new(1, 1, 1)
    countdownTimer.TextSize = 18
    countdownTimer.Font = Enum.Font.Gotham
    countdownTimer.TextXAlignment = Enum.TextXAlignment.Left
    countdownTimer.Parent = timerFrame
    
    -- Event connections
    closeButton.MouseButton1Click:Connect(function()
        self:CloseDailyRewards()
    end)
    
    -- Click outside to close
    overlay.MouseButton1Click:Connect(function()
        self:CloseDailyRewards()
    end)
    
    return dailyRewardGui
end

function DailyRewardController:CreateRewardDayCard(day, parent)
    local reward = DAILY_REWARDS[day]
    
    local card = Instance.new("Frame")
    card.Name = "DayCard" .. day
    card.Size = UDim2.new(1, -10, 0, 100)
    card.BackgroundColor3 = Color3.fromRGB(40, 40, 50)
    card.BorderSizePixel = 0
    card.LayoutOrder = day
    card.Parent = parent
    
    local cardCorner = Instance.new("UICorner")
    cardCorner.CornerRadius = UDim.new(0, 10)
    cardCorner.Parent = card
    
    -- Day number badge
    local dayBadge = Instance.new("Frame")
    dayBadge.Name = "DayBadge"
    dayBadge.Size = UDim2.new(0, 60, 0, 60)
    dayBadge.Position = UDim2.new(0, 15, 0, 20)
    dayBadge.BackgroundColor3 = Color3.fromRGB(100, 100, 110)
    dayBadge.BorderSizePixel = 0
    dayBadge.Parent = card
    
    local badgeCorner = Instance.new("UICorner")
    badgeCorner.CornerRadius = UDim.new(0, 30)
    badgeCorner.Parent = dayBadge
    
    local dayNumber = Instance.new("TextLabel")
    dayNumber.Size = UDim2.new(1, 0, 1, 0)
    dayNumber.BackgroundTransparency = 1
    dayNumber.Text = tostring(day)
    dayNumber.TextColor3 = Color3.new(1, 1, 1)
    dayNumber.TextSize = 20
    dayNumber.Font = Enum.Font.GothamBold
    dayNumber.Parent = dayBadge
    
    -- Reward items container
    local rewardItems = Instance.new("Frame")
    rewardItems.Name = "RewardItems"
    rewardItems.Size = UDim2.new(1, -120, 1, -20)
    rewardItems.Position = UDim2.new(0, 90, 0, 10)
    rewardItems.BackgroundTransparency = 1
    rewardItems.Parent = card
    
    local itemsLayout = Instance.new("UIListLayout")
    itemsLayout.SortOrder = Enum.SortOrder.LayoutOrder
    itemsLayout.FillDirection = Enum.FillDirection.Horizontal
    itemsLayout.Padding = UDim.new(0, 15)
    itemsLayout.Parent = rewardItems
    
    -- Coins reward
    if reward.coins > 0 then
        local coinItem = self:CreateRewardItem("💰", tostring(reward.coins), "Coins")
        coinItem.LayoutOrder = 1
        coinItem.Parent = rewardItems
    end
    
    -- XP reward
    if reward.xp > 0 then
        local xpItem = self:CreateRewardItem("⭐", tostring(reward.xp), "XP")
        xpItem.LayoutOrder = 2
        xpItem.Parent = rewardItems
    end
    
    -- Crate keys reward
    if reward.crateKeys > 0 then
        local keyItem = self:CreateRewardItem("🗝️", tostring(reward.crateKeys), "Keys")
        keyItem.LayoutOrder = 3
        keyItem.Parent = rewardItems
    end
    
    -- Special reward
    if reward.special then
        local specialItem = self:CreateRewardItem("🎉", reward.special, "Special")
        specialItem.LayoutOrder = 4
        specialItem.Parent = rewardItems
    end
    
    -- Status indicator (will be updated based on claim status)
    local statusIndicator = Instance.new("Frame")
    statusIndicator.Name = "StatusIndicator"
    statusIndicator.Size = UDim2.new(0, 30, 0, 30)
    statusIndicator.Position = UDim2.new(1, -40, 0, 10)
    statusIndicator.BackgroundColor3 = Color3.fromRGB(100, 100, 100)
    statusIndicator.BorderSizePixel = 0
    statusIndicator.Parent = card
    
    local statusCorner = Instance.new("UICorner")
    statusCorner.CornerRadius = UDim.new(0, 15)
    statusCorner.Parent = statusIndicator
    
    local statusIcon = Instance.new("TextLabel")
    statusIcon.Name = "StatusIcon"
    statusIcon.Size = UDim2.new(1, 0, 1, 0)
    statusIcon.BackgroundTransparency = 1
    statusIcon.Text = "⏳"
    statusIcon.TextSize = 16
    statusIcon.Font = Enum.Font.GothamBold
    statusIcon.Parent = statusIndicator
    
    return card
end

function DailyRewardController:CreateRewardItem(icon, amount, label)
    local item = Instance.new("Frame")
    item.Name = "RewardItem"
    item.Size = UDim2.new(0, 70, 1, 0)
    item.BackgroundTransparency = 1
    
    local itemIcon = Instance.new("TextLabel")
    itemIcon.Size = UDim2.new(1, 0, 0, 30)
    itemIcon.Position = UDim2.new(0, 0, 0, 5)
    itemIcon.BackgroundTransparency = 1
    itemIcon.Text = icon
    itemIcon.TextSize = 20
    itemIcon.Font = Enum.Font.GothamBold
    itemIcon.Parent = item
    
    local itemAmount = Instance.new("TextLabel")
    itemAmount.Size = UDim2.new(1, 0, 0, 25)
    itemAmount.Position = UDim2.new(0, 0, 0, 35)
    itemAmount.BackgroundTransparency = 1
    itemAmount.Text = amount
    itemAmount.TextColor3 = Color3.fromRGB(255, 215, 0)
    itemAmount.TextSize = 16
    itemAmount.Font = Enum.Font.GothamBold
    itemAmount.Parent = item
    
    local itemLabel = Instance.new("TextLabel")
    itemLabel.Size = UDim2.new(1, 0, 0, 20)
    itemLabel.Position = UDim2.new(0, 0, 0, 60)
    itemLabel.BackgroundTransparency = 1
    itemLabel.Text = label
    itemLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
    itemLabel.TextSize = 12
    itemLabel.Font = Enum.Font.Gotham
    itemLabel.Parent = item
    
    return item
end

function DailyRewardController:UpdateRewardStatus(rewardData)
    if not rewardPopup then return end
    
    local rewardContainer = rewardPopup.RewardContainer
    
    for day = 1, 7 do
        local dayCard = rewardContainer:FindFirstChild("DayCard" .. day)
        if dayCard then
            local statusIndicator = dayCard.StatusIndicator
            local statusIcon = statusIndicator.StatusIcon
            local dayBadge = dayCard.DayBadge
            
            if day < rewardData.currentDay then
                -- Already claimed
                statusIndicator.BackgroundColor3 = Color3.fromRGB(100, 200, 100)
                statusIcon.Text = "✓"
                statusIcon.TextColor3 = Color3.new(1, 1, 1)
                dayBadge.BackgroundColor3 = Color3.fromRGB(100, 200, 100)
                
            elseif day == rewardData.currentDay then
                if rewardData.canClaim then
                    -- Available to claim
                    statusIndicator.BackgroundColor3 = Color3.fromRGB(255, 215, 0)
                    statusIcon.Text = "🎁"
                    statusIcon.TextColor3 = Color3.new(0, 0, 0)
                    dayBadge.BackgroundColor3 = Color3.fromRGB(255, 215, 0)
                    
                    -- Add glow effect
                    if not dayCard:FindFirstChild("Glow") then
                        local glow = Instance.new("Frame")
                        glow.Name = "Glow"
                        glow.Size = UDim2.new(1, 6, 1, 6)
                        glow.Position = UDim2.new(0, -3, 0, -3)
                        glow.BackgroundColor3 = Color3.fromRGB(255, 215, 0)
                        glow.BackgroundTransparency = 0.7
                        glow.BorderSizePixel = 0
                        glow.ZIndex = dayCard.ZIndex - 1
                        glow.Parent = dayCard
                        
                        local glowCorner = Instance.new("UICorner")
                        glowCorner.CornerRadius = UDim.new(0, 13)
                        glowCorner.Parent = glow
                        
                        -- Animate glow
                        local glowTween = TweenService:Create(glow,
                            TweenInfo.new(1, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true),
                            {BackgroundTransparency = 0.4}
                        )
                        glowTween:Play()
                    end
                else
                    -- Already claimed today
                    statusIndicator.BackgroundColor3 = Color3.fromRGB(100, 200, 100)
                    statusIcon.Text = "✓"
                    statusIcon.TextColor3 = Color3.new(1, 1, 1)
                    dayBadge.BackgroundColor3 = Color3.fromRGB(100, 200, 100)
                end
                
            else
                -- Future day
                statusIndicator.BackgroundColor3 = Color3.fromRGB(100, 100, 100)
                statusIcon.Text = "🔒"
                statusIcon.TextColor3 = Color3.fromRGB(150, 150, 150)
                dayBadge.BackgroundColor3 = Color3.fromRGB(100, 100, 110)
            end
        end
    end
end

function DailyRewardController:UpdateCountdown(timeUntilNext)
    if not countdownTimer then return end
    
    if timeUntilNext and timeUntilNext > 0 then
        local hours = math.floor(timeUntilNext / 3600)
        local minutes = math.floor((timeUntilNext % 3600) / 60)
        local seconds = timeUntilNext % 60
        
        countdownTimer.Text = string.format("Next reward in: %02d:%02d:%02d", hours, minutes, seconds)
    else
        countdownTimer.Text = "Reward available now!"
        countdownTimer.TextColor3 = Color3.fromRGB(100, 255, 100)
    end
end

function DailyRewardController:ShowDailyRewards(rewardData)
    if isPopupOpen then return end
    
    if not dailyRewardGui then
        self:CreateDailyRewardGUI()
    end
    
    isPopupOpen = true
    dailyRewardGui.Enabled = true
    
    -- Update reward status
    self:UpdateRewardStatus(rewardData)
    
    -- Update countdown
    self:UpdateCountdown(rewardData.timeUntilNext)
    
    -- Entry animation
    rewardPopup.Position = UDim2.new(0.5, -250, -1, 0)
    rewardPopup.Size = UDim2.new(0, 100, 0, 100)
    
    local entryTween = TweenService:Create(rewardPopup,
        TweenInfo.new(0.6, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
        {
            Position = UDim2.new(0.5, -250, 0.5, -350),
            Size = UDim2.new(0, 500, 0, 700)
        }
    )
    entryTween:Play()
    
    -- Start countdown update loop
    spawn(function()
        while isPopupOpen and dailyRewardGui.Enabled do
            if rewardData.timeUntilNext and rewardData.timeUntilNext > 0 then
                rewardData.timeUntilNext = rewardData.timeUntilNext - 1
                self:UpdateCountdown(rewardData.timeUntilNext)
            end
            wait(1)
        end
    end)
    
    print("🎁 Daily rewards popup shown")
end

function DailyRewardController:CloseDailyRewards()
    if not isPopupOpen or not dailyRewardGui then return end
    
    isPopupOpen = false
    
    -- Exit animation
    local exitTween = TweenService:Create(rewardPopup,
        TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.In),
        {
            Position = UDim2.new(0.5, -250, 1.2, 0),
            Size = UDim2.new(0, 100, 0, 100)
        }
    )
    exitTween:Play()
    
    exitTween.Completed:Connect(function()
        dailyRewardGui.Enabled = false
    end)
end

function DailyRewardController:ShowClaimButton(day)
    if not rewardPopup then return end
    
    local rewardContainer = rewardPopup.RewardContainer
    local dayCard = rewardContainer:FindFirstChild("DayCard" .. day)
    
    if dayCard and not dayCard:FindFirstChild("ClaimButton") then
        local claimButton = Instance.new("TextButton")
        claimButton.Name = "ClaimButton"
        claimButton.Size = UDim2.new(0, 80, 0, 30)
        claimButton.Position = UDim2.new(1, -90, 1, -40)
        claimButton.BackgroundColor3 = Color3.fromRGB(100, 200, 100)
        claimButton.BorderSizePixel = 0
        claimButton.Text = "CLAIM"
        claimButton.TextColor3 = Color3.new(1, 1, 1)
        claimButton.TextSize = 14
        claimButton.Font = Enum.Font.GothamBold
        claimButton.Parent = dayCard
        
        local claimCorner = Instance.new("UICorner")
        claimCorner.CornerRadius = UDim.new(0, 6)
        claimCorner.Parent = claimButton
        
        -- Pulse animation
        local pulse = TweenService:Create(claimButton,
            TweenInfo.new(0.8, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true),
            {BackgroundColor3 = Color3.fromRGB(120, 255, 120)}
        )
        pulse:Play()
        
        claimButton.MouseButton1Click:Connect(function()
            self:ClaimDailyReward(day)
        end)
    end
end

function DailyRewardController:ClaimDailyReward(day)
    print("🎁 Claiming daily reward for day", day)
    RemoteEvents.ClaimDailyReward:FireServer(day)
end

function DailyRewardController:ShowRewardClaimedEffect(rewardInfo)
    if not rewardPopup then return end
    
    -- Create reward claimed popup
    local claimedPopup = Instance.new("Frame")
    claimedPopup.Size = UDim2.new(0, 300, 0, 200)
    claimedPopup.Position = UDim2.new(0.5, -150, 0.5, -100)
    claimedPopup.BackgroundColor3 = Color3.fromRGB(40, 40, 50)
    claimedPopup.BorderSizePixel = 0
    claimedPopup.Parent = rewardPopup
    
    local claimedCorner = Instance.new("UICorner")
    claimedCorner.CornerRadius = UDim.new(0, 15)
    claimedCorner.Parent = claimedPopup
    
    -- Success icon
    local successIcon = Instance.new("TextLabel")
    successIcon.Size = UDim2.new(1, 0, 0, 60)
    successIcon.Position = UDim2.new(0, 0, 0, 20)
    successIcon.BackgroundTransparency = 1
    successIcon.Text = "🎉"
    successIcon.TextSize = 48
    successIcon.Font = Enum.Font.GothamBold
    successIcon.Parent = claimedPopup
    
    -- Success text
    local successText = Instance.new("TextLabel")
    successText.Size = UDim2.new(1, -20, 0, 40)
    successText.Position = UDim2.new(0, 10, 0, 90)
    successText.BackgroundTransparency = 1
    successText.Text = "REWARD CLAIMED!"
    successText.TextColor3 = Color3.fromRGB(100, 255, 100)
    successText.TextSize = 20
    successText.Font = Enum.Font.GothamBold
    successText.Parent = claimedPopup
    
    -- Reward details
    local rewardDetails = Instance.new("TextLabel")
    rewardDetails.Size = UDim2.new(1, -20, 0, 50)
    rewardDetails.Position = UDim2.new(0, 10, 0, 130)
    rewardDetails.BackgroundTransparency = 1
    rewardDetails.Text = string.format("+%d Coins, +%d XP", rewardInfo.coins or 0, rewardInfo.xp or 0)
    rewardDetails.TextColor3 = Color3.new(1, 1, 1)
    rewardDetails.TextSize = 16
    rewardDetails.Font = Enum.Font.Gotham
    rewardDetails.TextWrapped = true
    rewardDetails.Parent = claimedPopup
    
    -- Entry animation
    claimedPopup.Size = UDim2.new(0, 50, 0, 50)
    local entryTween = TweenService:Create(claimedPopup,
        TweenInfo.new(0.5, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
        {Size = UDim2.new(0, 300, 0, 200)}
    )
    entryTween:Play()
    
    -- Auto-remove after 3 seconds
    spawn(function()
        wait(3)
        local exitTween = TweenService:Create(claimedPopup,
            TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.In),
            {
                Size = UDim2.new(0, 50, 0, 50),
                BackgroundTransparency = 1
            }
        )
        exitTween:Play()
        exitTween.Completed:Connect(function()
            claimedPopup:Destroy()
        end)
    end)
end

function DailyRewardController:Initialize()
    print("🎁 DailyRewardController initializing...")
    
    -- Connect remote events
    RemoteEvents.ShowDailyRewardPopup.OnClientEvent:Connect(function(rewardData)
        self:ShowDailyRewards(rewardData)
        
        -- Show claim button if reward is available
        if rewardData.canClaim then
            self:ShowClaimButton(rewardData.currentDay)
        end
    end)
    
    RemoteEvents.DailyRewardClaimResult.OnClientEvent:Connect(function(success, rewardInfo, errorMessage)
        if success then
            self:ShowRewardClaimedEffect(rewardInfo)
            
            -- Refresh the popup after claiming
            spawn(function()
                wait(1)
                RemoteEvents.RequestDailyRewardData:FireServer()
            end)
        else
            print("❌ Failed to claim daily reward:", errorMessage)
        end
    end)
    
    RemoteEvents.UpdateDailyRewardData.OnClientEvent:Connect(function(rewardData)
        if isPopupOpen then
            self:UpdateRewardStatus(rewardData)
            self:UpdateCountdown(rewardData.timeUntilNext)
            
            if rewardData.canClaim then
                self:ShowClaimButton(rewardData.currentDay)
            end
        end
    end)
    
    -- Auto-request daily reward data on login
    spawn(function()
        wait(2) -- Wait for other systems to initialize
        RemoteEvents.RequestDailyRewardData:FireServer()
    end)
    
    print("✅ DailyRewardController initialized!")
end

-- Auto-initialize
DailyRewardController:Initialize()

return DailyRewardController
