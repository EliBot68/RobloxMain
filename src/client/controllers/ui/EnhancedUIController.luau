-- EnhancedUIController.luau
-- Client-side enhanced UI with modern design system (UPDATED - NO MORE PLACEHOLDERS!)

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

local ModernUISystem = require(ReplicatedStorage.Shared.modules.ModernUISystem)

local player = Players.LocalPlayer

local EnhancedUIController = {}

-- Modern UI Configuration (REPLACED PLACEHOLDERS)
local UI_CONFIG = {
    -- Using ModernUISystem button styles instead of placeholder images
    buttons = {
        primary = {
            style = "primary",
            hoverScale = 1.05,
            pressScale = 0.95
        },
        secondary = {
            style = "secondary", 
            hoverScale = 1.03,
            pressScale = 0.98
        },
        danger = {
            style = "danger",
            hoverScale = 1.05,
            pressScale = 0.95
        },
        success = {
            style = "success",
            hoverScale = 1.05,
            pressScale = 0.95
        }
    },
    
    -- Modern background styles using design tokens
    backgrounds = {
        menu = {
            style = "menu",
            transparency = 0.15
        },
        game = {
            style = "game",
            transparency = 0.3
        },
        popup = {
            style = "modal",
            transparency = 0.1
        }
    },
    
    -- Modern icon system using Unicode icons
    icons = {
        coin = "💰",
        timer = "⏱️", 
        speed = "⚡",
        xp = "⭐",
        difficulty = "🎯",
        settings = "⚙️"
    }
}

-- Animation presets
local ANIMATIONS = {
    slideIn = {
        duration = 0.5,
        style = Enum.EasingStyle.Back,
        direction = Enum.EasingDirection.Out
    },
    fadeIn = {
        duration = 0.3,
        style = Enum.EasingStyle.Quad,
        direction = Enum.EasingDirection.Out
    },
    bounce = {
        duration = 0.2,
        style = Enum.EasingStyle.Elastic,
        direction = Enum.EasingDirection.Out
    },
    pulse = {
        duration = 1,
        style = Enum.EasingStyle.Sine,
        direction = Enum.EasingDirection.InOut
    }
}

function EnhancedUIController:Init()
    print("🎨 Initializing Enhanced UI Controller...")
    
    -- Set up UI management
    self:SetupPlayerGui()
    self:CreateMainMenuEnhancements()
    
    print("✅ Enhanced UI Controller initialized!")
end

function EnhancedUIController:SetupPlayerGui()
    local playerGui = player:WaitForChild("PlayerGui")
    
    -- Create enhanced UI container
    local enhancedUI = Instance.new("ScreenGui")
    enhancedUI.Name = "EnhancedUI"
    enhancedUI.ResetOnSpawn = false
    enhancedUI.DisplayOrder = 10
    enhancedUI.Parent = playerGui
    
    -- Store reference
    self.enhancedUI = enhancedUI
end

function EnhancedUIController:CreateMainMenuEnhancements()
    if not self.enhancedUI then return end
    
    -- MODERNIZED: Create background using ModernUISystem
    local backgroundFrame = ModernUISystem.createModernFrame({
        name = "BackgroundOverlay",
        style = UI_CONFIG.backgrounds.menu.style,
        size = UDim2.new(1, 0, 1, 0),
        position = UDim2.new(0, 0, 0, 0)
    })
    backgroundFrame.ZIndex = -1
    backgroundFrame.BackgroundTransparency = UI_CONFIG.backgrounds.menu.transparency
    backgroundFrame.Parent = self.enhancedUI
    
    -- Modern animated background particles using Unicode icons
    self:CreateModernBackgroundParticles(backgroundFrame)
end

function EnhancedUIController:CreateModernBackgroundParticles(parent)
    -- MODERNIZED: Create floating particles using modern icon system
    local particleIcons = {"⭐", "💎", "🔥", "⚡", "✨", "🌟", "💫", "⭕"}
    
    for i = 1, 8 do
        local particle = Instance.new("TextLabel")
        particle.Name = "ModernParticle" .. i
        particle.Size = UDim2.new(0, math.random(20, 40), 0, math.random(20, 40))
        particle.Position = UDim2.new(
            math.random(0, 100) / 100,
            0,
            math.random(0, 100) / 100,
            0
        )
        particle.BackgroundTransparency = 1
        particle.Text = particleIcons[i] or "⭐"
        particle.TextScaled = true
        particle.Font = ModernUISystem.getDesignTokens().fonts.icon
        particle.TextColor3 = ModernUISystem.getDesignTokens().colors.white
        particle.TextTransparency = math.random(30, 70) / 100
        particle.Parent = parent
        
        -- Modern floating animation using ModernUISystem
        spawn(function()
            while particle.Parent do
                -- Random movement animation
                ModernUISystem.animateElement(particle, "float", {
                    duration = math.random(4, 8),
                    endPosition = particle.Position + UDim2.new(
                        math.random(-30, 30) / 100,
                        0,
                        math.random(-30, 30) / 100,
                        0
                    ),
                    rotation = math.random(-180, 180)
                })
                
                wait(math.random(4, 8))
            end
        end)
        
        -- Pulse animation for visual appeal
        ModernUISystem.animateElement(particle, "pulse", {
            duration = math.random(2, 4),
            repeatCount = -1,
            reverses = true
        })
    end
end

function EnhancedUIController:CreateCustomButton(config)
    -- MODERNIZED: Use ModernUISystem instead of custom placeholder-based buttons
    local buttonStyle = UI_CONFIG.buttons[config.style] or UI_CONFIG.buttons.primary
    
    -- Create modern button using the new system
    local modernButton = ModernUISystem.createModernButton({
        name = config.name or "CustomButton",
        text = config.text or "Button",
        style = buttonStyle.style,
        size = config.size or UDim2.new(0, 200, 0, 60),
        position = config.position or UDim2.new(0, 0, 0, 0)
    })
    modernButton.Parent = config.parent
    
    -- Add icon if specified using modern icon system
    if config.icon then
        local iconButton = ModernUISystem.createIconButton({
            name = (config.name or "CustomButton") .. "Icon",
            icon = config.icon,
            style = buttonStyle.style,
            size = UDim2.new(0, 30, 0, 30),
            position = UDim2.new(0, 10, 0.5, -15)
        })
        iconButton.Parent = modernButton
        
        -- Adjust text position for icon
        local textLabel = modernButton:FindFirstChild("TextLabel")
        if textLabel then
            textLabel.Position = UDim2.new(0, 50, 0, 0)
            textLabel.Size = UDim2.new(1, -60, 1, 0)
        end
    end
    
    -- Apply enhanced hover and click effects
    local button = modernButton:FindFirstChild("TextButton") or modernButton
    if button and button:IsA("GuiButton") then
        button.MouseEnter:Connect(function()
            ModernUISystem.animateElement(modernButton, "scaleUp", {
                duration = 0.2,
                scale = buttonStyle.hoverScale
            })
        end)
        
        button.MouseLeave:Connect(function()
            ModernUISystem.animateElement(modernButton, "scaleDown", {
                duration = 0.2,
                scale = 1.0
            })
        end)
        
        button.MouseButton1Down:Connect(function()
            ModernUISystem.animateElement(modernButton, "scaleDown", {
                duration = 0.1,
                scale = buttonStyle.pressScale
            })
        end)
        
        button.MouseButton1Up:Connect(function()
            ModernUISystem.animateElement(modernButton, "scaleUp", {
                duration = 0.1,
                scale = 1.0
            })
        end)
    
    -- Connect callback
    if config.callback then
        buttonBG.MouseButton1Click:Connect(config.callback)
    end
    
    return buttonFrame
end

function EnhancedUIController:CreateAnimatedFrame(config)
    local backgroundStyle = UI_CONFIG.backgrounds[config.style] or UI_CONFIG.backgrounds.popup
    
    local frame = Instance.new("ImageLabel")
    frame.Name = config.name or "AnimatedFrame"
    frame.Size = config.size or UDim2.new(0, 400, 0, 300)
    frame.Position = config.position or UDim2.new(0.5, -200, 0.5, -150)
    frame.BackgroundTransparency = 1
    frame.Image = backgroundStyle.image
    frame.ImageColor3 = backgroundStyle.color
    frame.ImageTransparency = backgroundStyle.transparency
    frame.ScaleType = Enum.ScaleType.Slice
    frame.SliceCenter = Rect.new(50, 50, 200, 200)
    frame.Parent = config.parent
    
    -- Border glow
    if config.glow then
        local glowFrame = Instance.new("ImageLabel")
        glowFrame.Name = "GlowEffect"
        glowFrame.Size = UDim2.new(1, 40, 1, 40)
        glowFrame.Position = UDim2.new(0, -20, 0, -20)
        glowFrame.BackgroundTransparency = 1
        glowFrame.Image = backgroundStyle.image
        glowFrame.ImageColor3 = config.glowColor or Color3.new(1, 1, 1)
        glowFrame.ImageTransparency = 0.8
        glowFrame.ScaleType = Enum.ScaleType.Slice
        glowFrame.SliceCenter = Rect.new(50, 50, 200, 200)
        glowFrame.ZIndex = frame.ZIndex - 1
        glowFrame.Parent = frame.Parent
        
        -- Pulsing glow animation
        local glowTween = TweenService:Create(
            glowFrame,
            TweenInfo.new(
                ANIMATIONS.pulse.duration,
                ANIMATIONS.pulse.style,
                ANIMATIONS.pulse.direction,
                -1,
                true
            ),
            {ImageTransparency = 0.95}
        )
        glowTween:Play()
    end
    
    -- Entry animation
    if config.animate then
        local animationType = config.animationType or "slideIn"
        local anim = ANIMATIONS[animationType]
        
        if animationType == "slideIn" then
            frame.Position = frame.Position + UDim2.new(0, 0, 1, 0)
            local slideTween = TweenService:Create(
                frame,
                TweenInfo.new(anim.duration, anim.style, anim.direction),
                {Position = config.position or UDim2.new(0.5, -200, 0.5, -150)}
            )
            slideTween:Play()
        elseif animationType == "fadeIn" then
            frame.ImageTransparency = 1
            local fadeTween = TweenService:Create(
                frame,
                TweenInfo.new(anim.duration, anim.style, anim.direction),
                {ImageTransparency = backgroundStyle.transparency}
            )
            fadeTween:Play()
        end
    end
    
    return frame
end

function EnhancedUIController:CreateProgressBar(config)
    local container = Instance.new("Frame")
    container.Name = config.name or "ProgressBar"
    container.Size = config.size or UDim2.new(0, 300, 0, 20)
    container.Position = config.position or UDim2.new(0, 0, 0, 0)
    container.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
    container.BorderSizePixel = 2
    container.BorderColor3 = Color3.new(1, 1, 1)
    container.Parent = config.parent
    
    local progressFill = Instance.new("Frame")
    progressFill.Name = "ProgressFill"
    progressFill.Size = UDim2.new(0, 0, 1, 0)
    progressFill.BackgroundColor3 = config.color or Color3.fromRGB(100, 255, 100)
    progressFill.BorderSizePixel = 0
    progressFill.Parent = container
    
    -- Gradient effect
    local gradient = Instance.new("UIGradient")
    gradient.Color = ColorSequence.new{
        ColorSequenceKeypoint.new(0, Color3.new(1, 1, 1)),
        ColorSequenceKeypoint.new(1, config.color or Color3.fromRGB(100, 255, 100))
    }
    gradient.Rotation = 90
    gradient.Parent = progressFill
    
    -- Progress text
    local progressText = Instance.new("TextLabel")
    progressText.Name = "ProgressText"
    progressText.Size = UDim2.new(1, 0, 1, 0)
    progressText.BackgroundTransparency = 1
    progressText.Text = "0%"
    progressText.TextColor3 = Color3.new(1, 1, 1)
    progressText.TextScaled = true
    progressText.Font = Enum.Font.SourceSansBold
    progressText.TextStrokeTransparency = 0
    progressText.TextStrokeColor3 = Color3.new(0, 0, 0)
    progressText.Parent = container
    
    -- Update function
    container.UpdateProgress = function(percentage)
        percentage = math.clamp(percentage, 0, 100)
        
        local targetSize = UDim2.new(percentage / 100, 0, 1, 0)
        local progressTween = TweenService:Create(
            progressFill,
            TweenInfo.new(0.3, Enum.EasingStyle.Quad),
            {Size = targetSize}
        )
        progressTween:Play()
        
        progressText.Text = math.floor(percentage) .. "%"
    end
    
    return container
end

function EnhancedUIController:CreateNotification(config)
    local notification = Instance.new("Frame")
    notification.Name = "Notification"
    notification.Size = UDim2.new(0, 300, 0, 80)
    notification.Position = UDim2.new(1, -320, 0, 20)
    notification.BackgroundColor3 = config.color or Color3.fromRGB(50, 50, 50)
    notification.BackgroundTransparency = 0.1
    notification.BorderSizePixel = 0
    notification.Parent = self.enhancedUI
    
    -- Rounded corners
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 10)
    corner.Parent = notification
    
    -- Icon
    if config.icon then
        local iconLabel = Instance.new("ImageLabel")
        iconLabel.Name = "NotificationIcon"
        iconLabel.Size = UDim2.new(0, 40, 0, 40)
        iconLabel.Position = UDim2.new(0, 10, 0.5, -20)
        iconLabel.BackgroundTransparency = 1
        iconLabel.Image = config.icon
        iconLabel.ImageColor3 = config.iconColor or Color3.new(1, 1, 1)
        iconLabel.Parent = notification
    end
    
    -- Text
    local notificationText = Instance.new("TextLabel")
    notificationText.Name = "NotificationText"
    notificationText.Size = UDim2.new(1, config.icon and -60 or -20, 1, 0)
    notificationText.Position = UDim2.new(0, config.icon and 60 or 10, 0, 0)
    notificationText.BackgroundTransparency = 1
    notificationText.Text = config.text or "Notification"
    notificationText.TextColor3 = Color3.new(1, 1, 1)
    notificationText.TextScaled = true
    notificationText.Font = Enum.Font.SourceSans
    notificationText.TextWrapped = true
    notificationText.Parent = notification
    
    -- Slide in animation
    notification.Position = UDim2.new(1, 0, 0, 20)
    local slideInTween = TweenService:Create(
        notification,
        TweenInfo.new(0.5, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
        {Position = UDim2.new(1, -320, 0, 20)}
    )
    slideInTween:Play()
    
    -- Auto-dismiss
    local duration = config.duration or 3
    task.wait(duration)
    
    local slideOutTween = TweenService:Create(
        notification,
        TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
        {Position = UDim2.new(1, 0, 0, 20)}
    )
    slideOutTween:Play()
    
    slideOutTween.Completed:Connect(function()
        notification:Destroy()
    end)
    
    return notification
end

function EnhancedUIController:ShowLoadingScreen(text)
    local loadingScreen = Instance.new("Frame")
    loadingScreen.Name = "LoadingScreen"
    loadingScreen.Size = UDim2.new(1, 0, 1, 0)
    loadingScreen.BackgroundColor3 = Color3.new(0, 0, 0)
    loadingScreen.BackgroundTransparency = 0.5
    loadingScreen.BorderSizePixel = 0
    loadingScreen.Parent = self.enhancedUI
    
    local spinner = Instance.new("ImageLabel")
    spinner.Name = "LoadingSpinner"
    spinner.Size = UDim2.new(0, 100, 0, 100)
    spinner.Position = UDim2.new(0.5, -50, 0.5, -80)
    spinner.BackgroundTransparency = 1
    spinner.Image = UI_CONFIG.icons.speed
    spinner.ImageColor3 = Color3.fromRGB(100, 150, 255)
    spinner.Parent = loadingScreen
    
    local loadingText = Instance.new("TextLabel")
    loadingText.Name = "LoadingText"
    loadingText.Size = UDim2.new(0, 400, 0, 50)
    loadingText.Position = UDim2.new(0.5, -200, 0.5, 40)
    loadingText.BackgroundTransparency = 1
    loadingText.Text = text or "Loading..."
    loadingText.TextColor3 = Color3.new(1, 1, 1)
    loadingText.TextScaled = true
    loadingText.Font = Enum.Font.SourceSansBold
    loadingText.Parent = loadingScreen
    
    -- Spinning animation
    local spinTween = TweenService:Create(
        spinner,
        TweenInfo.new(1, Enum.EasingStyle.Linear, Enum.EasingDirection.InOut, -1),
        {Rotation = 360}
    )
    spinTween:Play()
    
    -- Pulsing text
    local pulseTween = TweenService:Create(
        loadingText,
        TweenInfo.new(1, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true),
        {TextTransparency = 0.5}
    )
    pulseTween:Play()
    
    return loadingScreen
end

function EnhancedUIController:HideLoadingScreen(loadingScreen)
    if loadingScreen then
        local fadeTween = TweenService:Create(
            loadingScreen,
            TweenInfo.new(0.5, Enum.EasingStyle.Quad),
            {BackgroundTransparency = 1}
        )
        fadeTween:Play()
        
        fadeTween.Completed:Connect(function()
            loadingScreen:Destroy()
        end)
    end
end

-- Utility functions
function EnhancedUIController:GetUIConfig()
    return UI_CONFIG
end

function EnhancedUIController:PlayUISound(soundType)
    local soundIds = {
        click = "rbxasset://sounds/button.wav",
        hover = "rbxasset://sounds/action_get_up.mp3",
        success = "rbxasset://sounds/electronicpingshort.wav",
        error = "rbxasset://sounds/action_falling.mp3"
    }
    
    local soundId = soundIds[soundType]
    if soundId then
        local sound = Instance.new("Sound")
        sound.SoundId = soundId
        sound.Volume = 0.3
        sound.Parent = game:GetService("SoundService")
        sound:Play()
        sound.Ended:Connect(function() sound:Destroy() end)
    end
end

return EnhancedUIController
