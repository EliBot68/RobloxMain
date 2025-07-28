-- NotificationController.luau
-- Simple notification system for hub interactions

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local RemoteEvents = require(ReplicatedStorage.Shared.modules.RemoteEvents)

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local NotificationController = {}

function NotificationController:ShowNotification(title, message, duration, notificationType)
    -- Show a beautiful notification
    duration = duration or 3
    notificationType = notificationType or "info"
    
    -- Create notification GUI
    local notificationGui = Instance.new("ScreenGui")
    notificationGui.Name = "NotificationGui"
    notificationGui.ResetOnSpawn = false
    notificationGui.Parent = playerGui
    
    -- Notification container
    local notification = Instance.new("Frame")
    notification.Name = "Notification"
    notification.Size = UDim2.new(0, 350, 0, 100)
    notification.Position = UDim2.new(1, 0, 0, 50) -- Start off-screen
    notification.BackgroundColor3 = Color3.fromRGB(40, 40, 50)
    notification.BorderSizePixel = 0
    notification.Parent = notificationGui
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 12)
    corner.Parent = notification
    
    -- Add gradient based on type
    local gradient = Instance.new("UIGradient")
    if notificationType == "success" then
        gradient.Color = ColorSequence.new{
            ColorSequenceKeypoint.new(0, Color3.fromRGB(50, 150, 50)),
            ColorSequenceKeypoint.new(1, Color3.fromRGB(30, 100, 30))
        }
    elseif notificationType == "warning" then
        gradient.Color = ColorSequence.new{
            ColorSequenceKeypoint.new(0, Color3.fromRGB(200, 150, 50)),
            ColorSequenceKeypoint.new(1, Color3.fromRGB(150, 100, 30))
        }
    elseif notificationType == "error" then
        gradient.Color = ColorSequence.new{
            ColorSequenceKeypoint.new(0, Color3.fromRGB(200, 50, 50)),
            ColorSequenceKeypoint.new(1, Color3.fromRGB(150, 30, 30))
        }
    else -- info
        gradient.Color = ColorSequence.new{
            ColorSequenceKeypoint.new(0, Color3.fromRGB(50, 100, 200)),
            ColorSequenceKeypoint.new(1, Color3.fromRGB(30, 70, 150))
        }
    end
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

function NotificationController:Initialize()
    -- Set up notification system
    print("📢 NotificationController initializing...")
    
    -- Listen for notification requests
    RemoteEvents.ShowNotification.OnClientEvent:Connect(function(data)
        self:ShowNotification(data.title, data.message, data.duration, data.type)
    end)
    
    print("✅ NotificationController initialized!")
end

-- Auto-initialize
NotificationController:Initialize()

return NotificationController
