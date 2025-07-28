-- NotificationController.luau
-- Simple notification system for hub interactions and tutorial support

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local SafeRequire = require(ReplicatedStorage.Shared.utils.SafeRequire)
local RemoteEvents = SafeRequire.require(ReplicatedStorage.Shared.modules.RemoteEvents)

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local NotificationController = {}

-- Active notifications tracking
local activeNotifications = {}
local notificationGui = nil

function NotificationController:CreateNotificationContainer()
    if notificationGui then return end
    
    notificationGui = Instance.new("ScreenGui")
    notificationGui.Name = "NotificationGui"
    notificationGui.ResetOnSpawn = false
    notificationGui.Parent = playerGui
end

function NotificationController:ShowNotification(titleOrData, message, duration, notificationType)
    self:CreateNotificationContainer()
    
    -- Support both old and new calling patterns
    local title, msg, dur, nType
    if type(titleOrData) == "table" then
        -- New format: data object
        title = titleOrData.title or "Notification"
        msg = titleOrData.message or ""
        dur = titleOrData.duration or 3
        nType = titleOrData.type or "info"
    else
        -- Old format: individual parameters
        title = titleOrData or "Notification"
        msg = message or ""
        dur = duration or 3
        nType = notificationType or "info"
    end
    
    -- Create notification frame
    local notification = Instance.new("Frame")
    notification.Name = "Notification"
    notification.Size = UDim2.new(0, 350, 0, 100)
    notification.Position = UDim2.new(1, 0, 0, 20 + (#activeNotifications * 110)) -- Start off-screen
    notification.BorderSizePixel = 0
    notification.Parent = notificationGui
    
    -- Set colors based on type
    local colors = {
        info = {Color3.fromRGB(40, 40, 50), Color3.fromRGB(60, 120, 200)},
        success = {Color3.fromRGB(30, 100, 30), Color3.fromRGB(50, 150, 50)},
        warning = {Color3.fromRGB(150, 100, 30), Color3.fromRGB(200, 150, 50)},
        error = {Color3.fromRGB(100, 30, 30), Color3.fromRGB(150, 50, 50)}
    }
    
    local colorSet = colors[nType] or colors.info
    notification.BackgroundColor3 = colorSet[1]
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 12)
    corner.Parent = notification
    
    -- Add gradient
    local gradient = Instance.new("UIGradient")
    gradient.Color = ColorSequence.new{
        ColorSequenceKeypoint.new(0, colorSet[2]),
        ColorSequenceKeypoint.new(1, colorSet[1])
    }
    gradient.Rotation = 45
    gradient.Parent = notification
    
    -- Icon
    local icon = Instance.new("TextLabel")
    icon.Name = "Icon"
    icon.Size = UDim2.new(0, 50, 0, 50)
    icon.Position = UDim2.new(0, 10, 0, 10)
    icon.BackgroundTransparency = 1
    icon.TextSize = 32
    icon.Font = Enum.Font.GothamBold
    icon.TextColor3 = Color3.new(1, 1, 1)
    icon.Parent = notification
    
    if notificationType == "success" then
        icon.Text = "✅"
    elseif notificationType == "warning" then
        icon.Text = "⚠️"
    elseif notificationType == "error" then
        icon.Text = "❌"
    else
        icon.Text = "ℹ️"
    end
    
    -- Title
    local titleLabel = Instance.new("TextLabel")
    titleLabel.Name = "Title"
    titleLabel.Size = UDim2.new(1, -70, 0, 30)
    titleLabel.Position = UDim2.new(0, 60, 0, 10)
    titleLabel.BackgroundTransparency = 1
    titleLabel.Text = title
    titleLabel.TextColor3 = Color3.new(1, 1, 1)
    titleLabel.TextSize = 18
    titleLabel.Font = Enum.Font.GothamBold
    titleLabel.TextXAlignment = Enum.TextXAlignment.Left
    titleLabel.Parent = notification
    
    -- Message
    local messageLabel = Instance.new("TextLabel")
    messageLabel.Name = "Message"
    messageLabel.Size = UDim2.new(1, -70, 0, 50)
    messageLabel.Position = UDim2.new(0, 60, 0, 35)
    messageLabel.BackgroundTransparency = 1
    messageLabel.Text = message
    messageLabel.TextColor3 = Color3.new(0.9, 0.9, 0.9)
    messageLabel.TextSize = 14
    messageLabel.Font = Enum.Font.Gotham
    messageLabel.TextXAlignment = Enum.TextXAlignment.Left
    messageLabel.TextYAlignment = Enum.TextYAlignment.Top
    messageLabel.TextWrapped = true
    messageLabel.Parent = notification
    
    -- Animate in
    local slideInTween = TweenService:Create(notification, TweenInfo.new(0.5, Enum.EasingStyle.Back), {
        Position = UDim2.new(1, -360, 0, 50)
    })
    slideInTween:Play()
    
    -- Auto-remove after duration
    spawn(function()
        wait(duration)
        
        -- Animate out
        local slideOutTween = TweenService:Create(notification, TweenInfo.new(0.3), {
            Position = UDim2.new(1, 0, 0, 50)
        })
        slideOutTween:Play()
        
        slideOutTween.Completed:Connect(function()
            notificationGui:Destroy()
        end)
    end)
end

function NotificationController:ShowWelcomeMessage(data)
    local playerGui = Players.LocalPlayer:WaitForChild("PlayerGui")
    
    -- Create welcome GUI
    local welcomeGui = Instance.new("ScreenGui")
    welcomeGui.Name = "WelcomeGui"
    welcomeGui.ResetOnSpawn = false
    welcomeGui.IgnoreGuiInset = true
    welcomeGui.Parent = playerGui
    
    -- Welcome frame
    local welcomeFrame = Instance.new("Frame")
    welcomeFrame.Size = UDim2.new(0, 600, 0, 300)
    welcomeFrame.Position = UDim2.new(0.5, -300, 0.5, -150)
    welcomeFrame.BackgroundColor3 = Color3.new(0.1, 0.1, 0.2)
    welcomeFrame.BorderSizePixel = 0
    welcomeFrame.Parent = welcomeGui
    
    local welcomeCorner = Instance.new("UICorner")
    welcomeCorner.CornerRadius = UDim.new(0, 20)
    welcomeCorner.Parent = welcomeFrame
    
    -- Gradient
    local welcomeGradient = Instance.new("UIGradient")
    welcomeGradient.Color = ColorSequence.new{
        ColorSequenceKeypoint.new(0, Color3.fromRGB(30, 60, 120)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(10, 20, 40))
    }
    welcomeGradient.Rotation = 45
    welcomeGradient.Parent = welcomeFrame
    
    -- Title
    local welcomeTitle = Instance.new("TextLabel")
    welcomeTitle.Size = UDim2.new(1, -40, 0, 80)
    welcomeTitle.Position = UDim2.new(0, 20, 0, 20)
    welcomeTitle.BackgroundTransparency = 1
    welcomeTitle.Text = data.title or "🎉 Welcome to the Game!"
    welcomeTitle.TextColor3 = Color3.new(1, 1, 1)
    welcomeTitle.TextScaled = true
    welcomeTitle.Font = Enum.Font.GothamBold
    welcomeTitle.Parent = welcomeFrame
    
    -- Message
    local welcomeMessage = Instance.new("TextLabel")
    welcomeMessage.Size = UDim2.new(1, -40, 0, 120)
    welcomeMessage.Position = UDim2.new(0, 20, 0, 100)
    welcomeMessage.BackgroundTransparency = 1
    welcomeMessage.Text = data.message or "Get ready for an amazing adventure! Follow the tutorial to learn the basics."
    welcomeMessage.TextColor3 = Color3.new(0.9, 0.9, 1)
    welcomeMessage.TextSize = 20
    welcomeMessage.Font = Enum.Font.Gotham
    welcomeMessage.TextWrapped = true
    welcomeMessage.Parent = welcomeFrame
    
    -- Continue button
    local continueButton = Instance.new("TextButton")
    continueButton.Size = UDim2.new(0, 200, 0, 50)
    continueButton.Position = UDim2.new(0.5, -100, 0, 230)
    continueButton.BackgroundColor3 = Color3.fromRGB(50, 150, 50)
    continueButton.Text = "Start Tutorial!"
    continueButton.TextColor3 = Color3.new(1, 1, 1)
    continueButton.TextSize = 18
    continueButton.Font = Enum.Font.GothamBold
    continueButton.Parent = welcomeFrame
    
    local buttonCorner = Instance.new("UICorner")
    buttonCorner.CornerRadius = UDim.new(0, 10)
    buttonCorner.Parent = continueButton
    
    -- Animate in
    welcomeFrame.Size = UDim2.new(0, 0, 0, 0)
    local welcomeTween = TweenService:Create(
        welcomeFrame,
        TweenInfo.new(0.8, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
        {Size = UDim2.new(0, 600, 0, 300)}
    )
    welcomeTween:Play()
    
    -- Button functionality
    continueButton.MouseButton1Click:Connect(function()
        -- Animate out
        local fadeOut = TweenService:Create(
            welcomeFrame,
            TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
            {Size = UDim2.new(0, 0, 0, 0)}
        )
        fadeOut:Play()
        fadeOut.Completed:Connect(function()
            welcomeGui:Destroy()
            -- Signal tutorial to start
            RemoteEvents.StartTutorial:FireServer()
        end)
    end)
    
    -- Auto-close fallback
    spawn(function()
        wait(data.duration or 10)
        if welcomeGui and welcomeGui.Parent then
            continueButton.MouseButton1Click:Fire()
        end
    end)
    
    print("👋 Welcome message displayed")
end

function NotificationController:Initialize()
    -- Set up notification system
    print("📢 NotificationController initializing...")
    
    -- Listen for notification requests
    RemoteEvents.ShowNotification.OnClientEvent:Connect(function(data)
        if type(data) == "table" then
            self:ShowNotification(data.title or "Notification", data.message or "", data.duration or 3, data.type or "info")
        else
            -- Legacy support for direct parameters
            self:ShowNotification(data or "Notification", "", 3, "info")
        end
    end)
    
    -- Listen for welcome messages
    RemoteEvents.ShowWelcomeMessage.OnClientEvent:Connect(function(data)
        self:ShowWelcomeMessage(data)
    end)
    
    print("✅ NotificationController initialized!")
end

-- Auto-initialize
NotificationController:Initialize()

return NotificationController
