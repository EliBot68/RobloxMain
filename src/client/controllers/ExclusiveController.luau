-- ExclusiveController.luau
-- Client-side controller for exclusive cosmetics and FOMO features

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SoundService = game:GetService("SoundService")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local RemoteEvents = require(ReplicatedStorage.Shared.modules.RemoteEvents)

local ExclusiveController = {}

-- UI elements
local exclusiveGui = nil
local countdownLabels = {}
local notificationGui = nil

-- FOMO and urgency effects
local urgencyEffects = {}
local lastNotificationTime = 0

function ExclusiveController:CreateExclusiveShopGUI()
    -- Create main exclusive shop interface
    exclusiveGui = Instance.new("ScreenGui")
    exclusiveGui.Name = "ExclusiveShop"
    exclusiveGui.ResetOnSpawn = false
    exclusiveGui.Parent = playerGui
    
    -- Main frame with dark, premium look
    local mainFrame = Instance.new("Frame")
    mainFrame.Name = "MainFrame"
    mainFrame.Size = UDim2.new(0, 800, 0, 600)
    mainFrame.Position = UDim2.new(0.5, -400, 0.5, -300)
    mainFrame.BackgroundColor3 = Color3.new(0.05, 0.05, 0.1)
    mainFrame.BorderSizePixel = 0
    mainFrame.Visible = false
    mainFrame.Parent = exclusiveGui
    
    -- Add premium gradient
    local gradient = Instance.new("UIGradient")
    gradient.Color = ColorSequence.new{
        ColorSequenceKeypoint.new(0, Color3.new(0.1, 0.05, 0.2)),
        ColorSequenceKeypoint.new(1, Color3.new(0.05, 0.05, 0.15))
    }
    gradient.Rotation = 45
    gradient.Parent = mainFrame
    
    -- Add corner rounding
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 15)
    corner.Parent = mainFrame
    
    -- Title with exclusive styling
    local titleLabel = Instance.new("TextLabel")
    titleLabel.Name = "TitleLabel"
    titleLabel.Size = UDim2.new(1, 0, 0, 80)
    titleLabel.Position = UDim2.new(0, 0, 0, 0)
    titleLabel.BackgroundTransparency = 1
    titleLabel.Text = "✨ EXCLUSIVE COSMETICS - LIMITED TIME! ✨"
    titleLabel.TextColor3 = Color3.new(1, 0.8, 0)
    titleLabel.TextScaled = true
    titleLabel.Font = Enum.Font.SourceSansBold
    titleLabel.TextStrokeTransparency = 0
    titleLabel.TextStrokeColor3 = Color3.new(0, 0, 0)
    titleLabel.Parent = mainFrame
    
    -- Pulsing title effect for urgency
    local titlePulse = TweenService:Create(
        titleLabel,
        TweenInfo.new(2, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true),
        {TextColor3 = Color3.new(1, 1, 0)}
    )
    titlePulse:Play()
    
    -- Close button
    local closeButton = Instance.new("TextButton")
    closeButton.Name = "CloseButton"
    closeButton.Size = UDim2.new(0, 40, 0, 40)
    closeButton.Position = UDim2.new(1, -50, 0, 10)
    closeButton.BackgroundColor3 = Color3.new(0.8, 0.2, 0.2)
    closeButton.Text = "×"
    closeButton.TextColor3 = Color3.new(1, 1, 1)
    closeButton.TextScaled = true
    closeButton.Font = Enum.Font.SourceSansBold
    closeButton.Parent = mainFrame
    
    local closeCorner = Instance.new("UICorner")
    closeCorner.CornerRadius = UDim.new(0, 20)
    closeCorner.Parent = closeButton
    
    closeButton.MouseButton1Click:Connect(function()
        self:CloseExclusiveShop()
    end)
    
    -- Scrolling frame for exclusives
    local scrollFrame = Instance.new("ScrollingFrame")
    scrollFrame.Name = "ScrollFrame"
    scrollFrame.Size = UDim2.new(1, -40, 1, -120)
    scrollFrame.Position = UDim2.new(0, 20, 0, 100)
    scrollFrame.BackgroundTransparency = 1
    scrollFrame.BorderSizePixel = 0
    scrollFrame.ScrollBarThickness = 8
    scrollFrame.ScrollBarImageColor3 = Color3.new(1, 0.8, 0)
    scrollFrame.Parent = mainFrame
    
    -- Grid layout for exclusive items
    local gridLayout = Instance.new("UIGridLayout")
    gridLayout.CellSize = UDim2.new(0, 180, 0, 250)
    gridLayout.CellPadding = UDim2.new(0, 10, 0, 10)
    gridLayout.SortOrder = Enum.SortOrder.Name
    gridLayout.Parent = scrollFrame
    
    return mainFrame, scrollFrame
end

function ExclusiveController:CreateExclusiveItem(exclusive, timeRemaining, parentFrame)
    -- Create individual exclusive item display
    local itemFrame = Instance.new("Frame")
    itemFrame.Name = exclusive.id
    itemFrame.Size = UDim2.new(0, 180, 0, 250)
    itemFrame.BackgroundColor3 = Color3.new(0.1, 0.1, 0.15)
    itemFrame.BorderSizePixel = 2
    itemFrame.BorderColor3 = exclusive.type == "skin" and Color3.new(1, 0.5, 0) or Color3.new(0, 0.8, 1)
    itemFrame.Parent = parentFrame
    
    local itemCorner = Instance.new("UICorner")
    itemCorner.CornerRadius = UDim.new(0, 10)
    itemCorner.Parent = itemFrame
    
    -- Rarity glow effect
    local glowEffect = Instance.new("ImageLabel")
    glowEffect.Size = UDim2.new(1.2, 0, 1.2, 0)
    glowEffect.Position = UDim2.new(-0.1, 0, -0.1, 0)
    glowEffect.BackgroundTransparency = 1
    glowEffect.Image = "rbxasset://textures/ui/GuiImagePlaceholder.png" -- Replace with glow texture
    glowEffect.ImageColor3 = Color3.new(1, 0.8, 0)
    glowEffect.ImageTransparency = 0.7
    glowEffect.Parent = itemFrame
    
    -- Item preview (would show actual cosmetic preview)
    local previewFrame = Instance.new("Frame")
    previewFrame.Size = UDim2.new(1, -10, 0, 100)
    previewFrame.Position = UDim2.new(0, 5, 0, 5)
    previewFrame.BackgroundColor3 = Color3.new(0.2, 0.2, 0.3)
    previewFrame.BorderSizePixel = 0
    previewFrame.Parent = itemFrame
    
    local previewCorner = Instance.new("UICorner")
    previewCorner.CornerRadius = UDim.new(0, 8)
    previewCorner.Parent = previewFrame
    
    -- Preview label (placeholder)
    local previewLabel = Instance.new("TextLabel")
    previewLabel.Size = UDim2.new(1, 0, 1, 0)
    previewLabel.BackgroundTransparency = 1
    previewLabel.Text = exclusive.type == "skin" and "👤" or "✨"
    previewLabel.TextColor3 = Color3.new(1, 1, 1)
    previewLabel.TextScaled = true
    previewLabel.Font = Enum.Font.SourceSans
    previewLabel.Parent = previewFrame
    
    -- Item name
    local nameLabel = Instance.new("TextLabel")
    nameLabel.Size = UDim2.new(1, -10, 0, 30)
    nameLabel.Position = UDim2.new(0, 5, 0, 110)
    nameLabel.BackgroundTransparency = 1
    nameLabel.Text = exclusive.name
    nameLabel.TextColor3 = Color3.new(1, 1, 1)
    nameLabel.TextScaled = true
    nameLabel.Font = Enum.Font.SourceSansBold
    nameLabel.TextStrokeTransparency = 0
    nameLabel.Parent = itemFrame
    
    -- Price
    local priceLabel = Instance.new("TextLabel")
    priceLabel.Size = UDim2.new(1, -10, 0, 25)
    priceLabel.Position = UDim2.new(0, 5, 0, 145)
    priceLabel.BackgroundTransparency = 1
    priceLabel.Text = "💎 " .. exclusive.price .. " ROBUX"
    priceLabel.TextColor3 = Color3.new(0, 1, 0.5)
    priceLabel.TextScaled = true
    priceLabel.Font = Enum.Font.SourceSansBold
    priceLabel.Parent = itemFrame
    
    -- Countdown timer
    local countdownLabel = Instance.new("TextLabel")
    countdownLabel.Name = "CountdownLabel"
    countdownLabel.Size = UDim2.new(1, -10, 0, 20)
    countdownLabel.Position = UDim2.new(0, 5, 0, 175)
    countdownLabel.BackgroundTransparency = 1
    countdownLabel.Text = self:FormatCountdown(timeRemaining)
    countdownLabel.TextColor3 = timeRemaining and timeRemaining.total < 3600 and Color3.new(1, 0.2, 0.2) or Color3.new(1, 1, 1)
    countdownLabel.TextScaled = true
    countdownLabel.Font = Enum.Font.SourceSans
    countdownLabel.TextStrokeTransparency = 0
    countdownLabel.Parent = itemFrame
    
    -- Store countdown label for updates
    countdownLabels[exclusive.id] = countdownLabel
    
    -- Exclusivity text
    local exclusivityLabel = Instance.new("TextLabel")
    exclusivityLabel.Size = UDim2.new(1, -10, 0, 20)
    exclusivityLabel.Position = UDim2.new(0, 5, 0, 200)
    exclusivityLabel.BackgroundTransparency = 1
    exclusivityLabel.Text = exclusive.exclusivityText
    exclusivityLabel.TextColor3 = Color3.new(1, 0.8, 0)
    exclusivityLabel.TextScaled = true
    exclusivityLabel.Font = Enum.Font.SourceSansItalic
    exclusivityLabel.TextStrokeTransparency = 0
    exclusivityLabel.Parent = itemFrame
    
    -- Purchase button
    local purchaseButton = Instance.new("TextButton")
    purchaseButton.Size = UDim2.new(1, -10, 0, 25)
    purchaseButton.Position = UDim2.new(0, 5, 0, 220)
    purchaseButton.BackgroundColor3 = Color3.new(0, 0.8, 0.2)
    purchaseButton.Text = "BUY NOW!"
    purchaseButton.TextColor3 = Color3.new(1, 1, 1)
    purchaseButton.TextScaled = true
    purchaseButton.Font = Enum.Font.SourceSansBold
    purchaseButton.Parent = itemFrame
    
    local buttonCorner = Instance.new("UICorner")
    buttonCorner.CornerRadius = UDim.new(0, 5)
    buttonCorner.Parent = purchaseButton
    
    -- Purchase button effects
    purchaseButton.MouseButton1Click:Connect(function()
        self:PurchaseExclusive(exclusive)
    end)
    
    -- Hover effects
    purchaseButton.MouseEnter:Connect(function()
        local hoverTween = TweenService:Create(
            purchaseButton,
            TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
            {BackgroundColor3 = Color3.new(0, 1, 0.3)}
        )
        hoverTween:Play()
    end)
    
    purchaseButton.MouseLeave:Connect(function()
        local hoverTween = TweenService:Create(
            purchaseButton,
            TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
            {BackgroundColor3 = Color3.new(0, 0.8, 0.2)}
        )
        hoverTween:Play()
    end)
    
    -- Urgency effects for items expiring soon
    if timeRemaining and timeRemaining.total < 3600 then -- Less than 1 hour
        self:AddUrgencyEffects(itemFrame)
    end
    
    return itemFrame
end

function ExclusiveController:AddUrgencyEffects(itemFrame)
    -- Add visual urgency effects for items expiring soon
    
    -- Red warning glow
    local warningGlow = Instance.new("ImageLabel")
    warningGlow.Size = UDim2.new(1.3, 0, 1.3, 0)
    warningGlow.Position = UDim2.new(-0.15, 0, -0.15, 0)
    warningGlow.BackgroundTransparency = 1
    warningGlow.Image = "rbxasset://textures/ui/GuiImagePlaceholder.png"
    warningGlow.ImageColor3 = Color3.new(1, 0.2, 0.2)
    warningGlow.ImageTransparency = 0.5
    warningGlow.Parent = itemFrame
    
    -- Pulsing warning effect
    local warningPulse = TweenService:Create(
        warningGlow,
        TweenInfo.new(1, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true),
        {ImageTransparency = 0.2}
    )
    warningPulse:Play()
    
    -- Alert text
    local alertLabel = Instance.new("TextLabel")
    alertLabel.Size = UDim2.new(1, 0, 0, 20)
    alertLabel.Position = UDim2.new(0, 0, 0, -25)
    alertLabel.BackgroundTransparency = 1
    alertLabel.Text = "🚨 EXPIRES SOON! 🚨"
    alertLabel.TextColor3 = Color3.new(1, 0.2, 0.2)
    alertLabel.TextScaled = true
    alertLabel.Font = Enum.Font.SourceSansBold
    alertLabel.TextStrokeTransparency = 0
    alertLabel.Parent = itemFrame
    
    -- Blinking alert
    local alertBlink = TweenService:Create(
        alertLabel,
        TweenInfo.new(0.5, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true),
        {TextTransparency = 1}
    )
    alertBlink:Play()
    
    table.insert(urgencyEffects, {warningPulse, alertBlink})
end

function ExclusiveController:FormatCountdown(timeData)
    if not timeData then
        return "EXPIRED"
    end
    
    if timeData.days > 0 then
        return string.format("%dd %dh %dm", timeData.days, timeData.hours, timeData.minutes)
    elseif timeData.hours > 0 then
        return string.format("%dh %dm %ds", timeData.hours, timeData.minutes, timeData.seconds)
    else
        return string.format("%dm %ds", timeData.minutes, timeData.seconds)
    end
end

function ExclusiveController:UpdateCountdowns(exclusivesData)
    -- Update all countdown displays
    for exclusiveId, countdownLabel in pairs(countdownLabels) do
        local exclusive = nil
        for _, ex in pairs(exclusivesData) do
            if ex.id == exclusiveId then
                exclusive = ex
                break
            end
        end
        
        if exclusive and countdownLabel then
            local timeRemaining = self:CalculateTimeRemaining(exclusive.endDate)
            local countdownText = self:FormatCountdown(timeRemaining)
            
            countdownLabel.Text = countdownText
            countdownLabel.TextColor3 = timeRemaining and timeRemaining.total < 3600 and Color3.new(1, 0.2, 0.2) or Color3.new(1, 1, 1)
        end
    end
end

function ExclusiveController:CalculateTimeRemaining(endDate)
    local currentTime = os.time()
    local timeLeft = endDate - currentTime
    
    if timeLeft <= 0 then
        return nil
    end
    
    local days = math.floor(timeLeft / 86400)
    local hours = math.floor((timeLeft % 86400) / 3600)
    local minutes = math.floor((timeLeft % 3600) / 60)
    local seconds = timeLeft % 60
    
    return {
        total = timeLeft,
        days = days,
        hours = hours,
        minutes = minutes,
        seconds = seconds
    }
end

function ExclusiveController:ShowExclusivePurchase(exclusive, timeRemaining)
    -- Show detailed purchase confirmation with FOMO elements
    local confirmGui = Instance.new("ScreenGui")
    confirmGui.Name = "ExclusiveConfirm"
    confirmGui.Parent = playerGui
    
    -- Dark overlay
    local overlay = Instance.new("Frame")
    overlay.Size = UDim2.new(1, 0, 1, 0)
    overlay.BackgroundColor3 = Color3.new(0, 0, 0)
    overlay.BackgroundTransparency = 0.5
    overlay.BorderSizePixel = 0
    overlay.Parent = confirmGui
    
    -- Confirmation frame
    local confirmFrame = Instance.new("Frame")
    confirmFrame.Size = UDim2.new(0, 400, 0, 300)
    confirmFrame.Position = UDim2.new(0.5, -200, 0.5, -150)
    confirmFrame.BackgroundColor3 = Color3.new(0.1, 0.1, 0.15)
    confirmFrame.BorderSizePixel = 0
    confirmFrame.Parent = confirmGui
    
    local confirmCorner = Instance.new("UICorner")
    confirmCorner.CornerRadius = UDim.new(0, 15)
    confirmCorner.Parent = confirmFrame
    
    -- Title
    local titleLabel = Instance.new("TextLabel")
    titleLabel.Size = UDim2.new(1, -20, 0, 40)
    titleLabel.Position = UDim2.new(0, 10, 0, 10)
    titleLabel.BackgroundTransparency = 1
    titleLabel.Text = "🌟 EXCLUSIVE PURCHASE 🌟"
    titleLabel.TextColor3 = Color3.new(1, 0.8, 0)
    titleLabel.TextScaled = true
    titleLabel.Font = Enum.Font.SourceSansBold
    titleLabel.Parent = confirmFrame
    
    -- Item details
    local itemLabel = Instance.new("TextLabel")
    itemLabel.Size = UDim2.new(1, -20, 0, 30)
    itemLabel.Position = UDim2.new(0, 10, 0, 60)
    itemLabel.BackgroundTransparency = 1
    itemLabel.Text = exclusive.name
    itemLabel.TextColor3 = Color3.new(1, 1, 1)
    itemLabel.TextScaled = true
    itemLabel.Font = Enum.Font.SourceSansBold
    itemLabel.Parent = confirmFrame
    
    -- Price
    local priceLabel = Instance.new("TextLabel")
    priceLabel.Size = UDim2.new(1, -20, 0, 25)
    priceLabel.Position = UDim2.new(0, 10, 0, 100)
    priceLabel.BackgroundTransparency = 1
    priceLabel.Text = "💎 " .. exclusive.price .. " ROBUX"
    priceLabel.TextColor3 = Color3.new(0, 1, 0.5)
    priceLabel.TextScaled = true
    priceLabel.Font = Enum.Font.SourceSansBold
    priceLabel.Parent = confirmFrame
    
    -- Countdown warning
    local warningLabel = Instance.new("TextLabel")
    warningLabel.Size = UDim2.new(1, -20, 0, 25)
    warningLabel.Position = UDim2.new(0, 10, 0, 135)
    warningLabel.BackgroundTransparency = 1
    warningLabel.Text = "⏰ " .. self:FormatCountdown(timeRemaining) .. " REMAINING!"
    warningLabel.TextColor3 = Color3.new(1, 0.3, 0.3)
    warningLabel.TextScaled = true
    warningLabel.Font = Enum.Font.SourceSansItalic
    warningLabel.Parent = confirmFrame
    
    -- FOMO text
    local fomoLabel = Instance.new("TextLabel")
    fomoLabel.Size = UDim2.new(1, -20, 0, 20)
    fomoLabel.Position = UDim2.new(0, 10, 0, 170)
    fomoLabel.BackgroundTransparency = 1
    fomoLabel.Text = "Once it's gone, it's GONE FOREVER!"
    fomoLabel.TextColor3 = Color3.new(1, 0.8, 0)
    fomoLabel.TextScaled = true
    fomoLabel.Font = Enum.Font.SourceSansItalic
    fomoLabel.Parent = confirmFrame
    
    -- Purchase button
    local purchaseButton = Instance.new("TextButton")
    purchaseButton.Size = UDim2.new(0, 150, 0, 40)
    purchaseButton.Position = UDim2.new(0, 20, 1, -60)
    purchaseButton.BackgroundColor3 = Color3.new(0, 0.8, 0.2)
    purchaseButton.Text = "BUY NOW!"
    purchaseButton.TextColor3 = Color3.new(1, 1, 1)
    purchaseButton.TextScaled = true
    purchaseButton.Font = Enum.Font.SourceSansBold
    purchaseButton.Parent = confirmFrame
    
    -- Cancel button
    local cancelButton = Instance.new("TextButton")
    cancelButton.Size = UDim2.new(0, 150, 0, 40)
    cancelButton.Position = UDim2.new(1, -170, 1, -60)
    cancelButton.BackgroundColor3 = Color3.new(0.8, 0.2, 0.2)
    cancelButton.Text = "Cancel"
    cancelButton.TextColor3 = Color3.new(1, 1, 1)
    cancelButton.TextScaled = true
    cancelButton.Font = Enum.Font.SourceSans
    cancelButton.Parent = confirmFrame
    
    -- Button corners
    local purchaseCorner = Instance.new("UICorner")
    purchaseCorner.CornerRadius = UDim.new(0, 8)
    purchaseCorner.Parent = purchaseButton
    
    local cancelCorner = Instance.new("UICorner")
    cancelCorner.CornerRadius = UDim.new(0, 8)
    cancelCorner.Parent = cancelButton
    
    -- Button events
    purchaseButton.MouseButton1Click:Connect(function()
        RemoteEvents.PurchaseExclusive:FireServer(exclusive.id)
        confirmGui:Destroy()
    end)
    
    cancelButton.MouseButton1Click:Connect(function()
        confirmGui:Destroy()
    end)
    
    -- Auto-close on overlay click
    overlay.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            confirmGui:Destroy()
        end
    end)
end

function ExclusiveController:PurchaseExclusive(exclusive)
    -- Initiate purchase process
    RemoteEvents.PurchaseExclusive:FireServer(exclusive.id)
end

function ExclusiveController:ShowExclusiveNotification(message, messageType)
    -- Show floating notification with FOMO styling
    if tick() - lastNotificationTime < 2 then return end -- Rate limit notifications
    lastNotificationTime = tick()
    
    if not notificationGui then
        notificationGui = Instance.new("ScreenGui")
        notificationGui.Name = "ExclusiveNotifications"
        notificationGui.Parent = playerGui
    end
    
    local notification = Instance.new("Frame")
    notification.Size = UDim2.new(0, 400, 0, 80)
    notification.Position = UDim2.new(1, 410, 0, 100 + (#notificationGui:GetChildren() * 90))
    notification.BackgroundColor3 = messageType == "success" and Color3.new(0, 0.8, 0.2) or Color3.new(0.8, 0.2, 0.2)
    notification.BorderSizePixel = 0
    notification.Parent = notificationGui
    
    local notifCorner = Instance.new("UICorner")
    notifCorner.CornerRadius = UDim.new(0, 10)
    notifCorner.Parent = notification
    
    local messageLabel = Instance.new("TextLabel")
    messageLabel.Size = UDim2.new(1, -20, 1, -20)
    messageLabel.Position = UDim2.new(0, 10, 0, 10)
    messageLabel.BackgroundTransparency = 1
    messageLabel.Text = message
    messageLabel.TextColor3 = Color3.new(1, 1, 1)
    messageLabel.TextScaled = true
    messageLabel.Font = Enum.Font.SourceSansBold
    messageLabel.TextWrapped = true
    messageLabel.Parent = notification
    
    -- Slide in animation
    local slideIn = TweenService:Create(
        notification,
        TweenInfo.new(0.5, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
        {Position = UDim2.new(1, -410, 0, 100 + (#notificationGui:GetChildren() * 90))}
    )
    slideIn:Play()
    
    -- Auto-remove after 5 seconds
    spawn(function()
        wait(5)
        local slideOut = TweenService:Create(
            notification,
            TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
            {Position = UDim2.new(1, 410, 0, notification.Position.Y.Offset)}
        )
        slideOut:Play()
        slideOut.Completed:Connect(function()
            notification:Destroy()
        end)
    end)
end

function ExclusiveController:OpenExclusiveShop()
    if not exclusiveGui then
        self:CreateExclusiveShopGUI()
    end
    
    local mainFrame = exclusiveGui.MainFrame
    mainFrame.Visible = true
    
    -- Slide in animation
    mainFrame.Position = UDim2.new(0.5, -400, 1, 0)
    local slideIn = TweenService:Create(
        mainFrame,
        TweenInfo.new(0.5, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
        {Position = UDim2.new(0.5, -400, 0.5, -300)}
    )
    slideIn:Play()
    
    -- Request exclusive data from server
    RemoteEvents.GetExclusiveData:FireServer()
end

function ExclusiveController:CloseExclusiveShop()
    if not exclusiveGui then return end
    
    local mainFrame = exclusiveGui.MainFrame
    local slideOut = TweenService:Create(
        mainFrame,
        TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
        {Position = UDim2.new(0.5, -400, 1, 0)}
    )
    slideOut:Play()
    slideOut.Completed:Connect(function()
        mainFrame.Visible = false
    end)
end

function ExclusiveController:StartCountdownUpdates()
    -- Update countdowns every second
    RunService.Heartbeat:Connect(function()
        if exclusiveGui and exclusiveGui.MainFrame.Visible then
            -- Update countdown displays in shop
            -- This would be connected to server data updates
        end
    end)
end

function ExclusiveController:Initialize()
    print("🌟 ExclusiveController initializing...")
    
    -- Create notification GUI
    self:StartCountdownUpdates()
    
    print("✅ ExclusiveController initialized!")
end

-- Remote event connections
RemoteEvents.ShowExclusivePurchase.OnClientEvent:Connect(function(exclusive, timeRemaining)
    ExclusiveController:ShowExclusivePurchase(exclusive, timeRemaining)
end)

RemoteEvents.ExclusivePurchased.OnClientEvent:Connect(function(exclusive)
    ExclusiveController:ShowExclusiveNotification("🌟 Successfully purchased " .. exclusive.name .. "! 🌟", "success")
end)

RemoteEvents.ExclusiveExpired.OnClientEvent:Connect(function(exclusive)
    ExclusiveController:ShowExclusiveNotification("⏰ " .. exclusive.name .. " has expired! You missed out!", "warning")
end)

RemoteEvents.ExclusivePurchaseResult.OnClientEvent:Connect(function(success, message)
    if success then
        ExclusiveController:ShowExclusiveNotification("🎉 " .. message, "success")
    else
        ExclusiveController:ShowExclusiveNotification("❌ " .. message, "error")
    end
end)

-- Auto-initialize
ExclusiveController:Initialize()

return ExclusiveController
