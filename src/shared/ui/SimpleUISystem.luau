-- SimpleUISystem.luau
-- Simplified UI system focused on color-matching game needs
-- Replaces the complex enterprise UI system with game-focused functionality

local Services = require(script.Parent.Parent.core.Services)

local SimpleUISystem = {}

-- UI Configuration for color-matching game
local UI_CONFIG = {
    colors = {
        primary = Color3.fromRGB(52, 152, 219),
        secondary = Color3.fromRGB(46, 204, 113),
        warning = Color3.fromRGB(231, 76, 60),
        background = Color3.fromRGB(44, 62, 80),
        text = Color3.fromRGB(255, 255, 255)
    },
    
    fontSize = {
        small = 14,
        medium = 18,
        large = 24,
        huge = 32
    },
    
    buttonHeight = 50,
    cornerRadius = 8,
    padding = 10
}

-- Create a simple styled button
function SimpleUISystem.createButton(config)
    local button = Instance.new("TextButton")
    button.Name = config.name or "Button"
    button.Size = config.size or UDim2.new(0, 200, 0, UI_CONFIG.buttonHeight)
    button.Position = config.position or UDim2.new(0, 0, 0, 0)
    button.BackgroundColor3 = config.color or UI_CONFIG.colors.primary
    button.BorderSizePixel = 0
    button.Text = config.text or "Button"
    button.TextColor3 = UI_CONFIG.colors.text
    button.TextSize = config.textSize or UI_CONFIG.fontSize.medium
    button.Font = Enum.Font.SourceSansBold
    button.AutoButtonColor = false
    
    -- Add rounded corners
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, UI_CONFIG.cornerRadius)
    corner.Parent = button
    
    -- Add hover effect
    button.MouseEnter:Connect(function()
        button.BackgroundColor3 = button.BackgroundColor3:lerp(Color3.new(1, 1, 1), 0.1)
    end)
    
    button.MouseLeave:Connect(function()
        button.BackgroundColor3 = config.color or UI_CONFIG.colors.primary
    end)
    
    if config.parent then
        button.Parent = config.parent
    end
    
    return button
end

-- Create a simple text label
function SimpleUISystem.createLabel(config)
    local label = Instance.new("TextLabel")
    label.Name = config.name or "Label"
    label.Size = config.size or UDim2.new(0, 200, 0, 40)
    label.Position = config.position or UDim2.new(0, 0, 0, 0)
    label.BackgroundTransparency = config.backgroundTransparency or 1
    label.BackgroundColor3 = config.backgroundColor or UI_CONFIG.colors.background
    label.Text = config.text or "Label"
    label.TextColor3 = config.textColor or UI_CONFIG.colors.text
    label.TextSize = config.textSize or UI_CONFIG.fontSize.medium
    label.Font = config.font or Enum.Font.SourceSans
    label.TextXAlignment = config.textXAlignment or Enum.TextXAlignment.Center
    label.TextYAlignment = config.textYAlignment or Enum.TextYAlignment.Center
    
    if config.parent then
        label.Parent = config.parent
    end
    
    return label
end

-- Create a simple frame
function SimpleUISystem.createFrame(config)
    local frame = Instance.new("Frame")
    frame.Name = config.name or "Frame"
    frame.Size = config.size or UDim2.new(1, 0, 1, 0)
    frame.Position = config.position or UDim2.new(0, 0, 0, 0)
    frame.BackgroundColor3 = config.backgroundColor or UI_CONFIG.colors.background
    frame.BackgroundTransparency = config.backgroundTransparency or 0
    frame.BorderSizePixel = 0
    
    -- Add rounded corners if specified
    if config.cornerRadius then
        local corner = Instance.new("UICorner")
        corner.CornerRadius = UDim.new(0, config.cornerRadius)
        corner.Parent = frame
    end
    
    if config.parent then
        frame.Parent = config.parent
    end
    
    return frame
end

-- Create HUD display for score/timer
function SimpleUISystem.createHUDDisplay(config)
    local frame = SimpleUISystem.createFrame({
        name = config.name or "HUDDisplay",
        size = config.size or UDim2.new(0, 150, 0, 40),
        position = config.position,
        backgroundColor = UI_CONFIG.colors.background,
        backgroundTransparency = 0.3,
        cornerRadius = UI_CONFIG.cornerRadius,
        parent = config.parent
    })
    
    local label = SimpleUISystem.createLabel({
        name = "DisplayLabel",
        size = UDim2.new(1, -UI_CONFIG.padding*2, 1, 0),
        position = UDim2.new(0, UI_CONFIG.padding, 0, 0),
        text = config.text or "0",
        textSize = config.textSize or UI_CONFIG.fontSize.large,
        font = Enum.Font.SourceSansBold,
        parent = frame
    })
    
    return frame, label
end

-- Simple notification system
function SimpleUISystem.showNotification(text, duration, color)
    local playerGui = game.Players.LocalPlayer:WaitForChild("PlayerGui")
    
    local notification = SimpleUISystem.createFrame({
        name = "Notification",
        size = UDim2.new(0, 300, 0, 60),
        position = UDim2.new(0.5, -150, 0, 50),
        backgroundColor = color or UI_CONFIG.colors.primary,
        cornerRadius = UI_CONFIG.cornerRadius,
        parent = playerGui
    })
    
    local label = SimpleUISystem.createLabel({
        name = "NotificationText",
        size = UDim2.new(1, -UI_CONFIG.padding*2, 1, 0),
        position = UDim2.new(0, UI_CONFIG.padding, 0, 0),
        text = text,
        textSize = UI_CONFIG.fontSize.medium,
        font = Enum.Font.SourceSansBold,
        parent = notification
    })
    
    -- Animate entrance
    notification.Position = UDim2.new(0.5, -150, 0, -70)
    local tween = game:GetService("TweenService"):Create(
        notification, 
        TweenInfo.new(0.3, Enum.EasingStyle.Back), 
        {Position = UDim2.new(0.5, -150, 0, 50)}
    )
    tween:Play()
    
    -- Auto-remove after duration
    game:GetService("Debris"):AddItem(notification, duration or 3)
end

-- Get UI configuration
function SimpleUISystem.getConfig()
    return UI_CONFIG
end

-- Register service with centralized Services module
Services.Register("SimpleUISystem", SimpleUISystem)

return SimpleUISystem
