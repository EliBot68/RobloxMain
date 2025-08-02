-- ModernUISystem.luau
-- Complete modern UI system replacing all placeholder elements
-- Mobile-friendly, scalable, and following Roblox best practices

local _ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local GuiService = game:GetService("GuiService")

local ModernUISystem = {}

-- Modern UI Configuration
local UI_DESIGN = {
    -- Color Palette
    colors = {
        -- Primary Brand Colors
        primary = Color3.fromRGB(79, 172, 254), -- Vibrant Blue
        primaryDark = Color3.fromRGB(41, 128, 185), -- Darker Blue
        primaryLight = Color3.fromRGB(174, 214, 241), -- Light Blue
        
        -- Secondary Colors
        secondary = Color3.fromRGB(155, 89, 182), -- Purple
        accent = Color3.fromRGB(52, 152, 219), -- Bright Blue
        success = Color3.fromRGB(46, 204, 113), -- Green
        warning = Color3.fromRGB(241, 196, 15), -- Yellow
        danger = Color3.fromRGB(231, 76, 60), -- Red
        
        -- Neutral Colors
        dark = Color3.fromRGB(44, 62, 80), -- Dark Blue-Gray
        medium = Color3.fromRGB(127, 140, 141), -- Medium Gray
        light = Color3.fromRGB(236, 240, 241), -- Light Gray
        white = Color3.fromRGB(255, 255, 255),
        black = Color3.fromRGB(0, 0, 0),
        
        -- Background Colors
        backgroundDark = Color3.fromRGB(30, 39, 46),
        backgroundMedium = Color3.fromRGB(45, 52, 54),
        backgroundLight = Color3.fromRGB(99, 110, 114),
        
        -- Game-specific Colors
        coinGold = Color3.fromRGB(255, 215, 0),
        xpBlue = Color3.fromRGB(52, 152, 219),
        speedRed = Color3.fromRGB(231, 76, 60),
        difficultyPurple = Color3.fromRGB(155, 89, 182)
    },
    
    -- Typography
    fonts = {
        heading = Enum.Font.GothamBold,
        subheading = Enum.Font.GothamMedium,
        body = Enum.Font.Gotham,
        button = Enum.Font.GothamBold,
        caption = Enum.Font.GothamMedium
    },
    
    -- Spacing & Sizing
    spacing = {
        xs = 4,
        sm = 8,
        md = 16,
        lg = 24,
        xl = 32,
        xxl = 48
    },
    
    -- Border Radius
    radius = {
        sm = 4,
        md = 8,
        lg = 12,
        xl = 16,
        round = 50 -- For circular elements
    },
    
    -- Shadows and Borders
    borders = {
        thin = 1,
        medium = 2,
        thick = 3
    },
    
    -- Z-Index Layers
    zIndex = {
        background = 1,
        content = 2,
        overlay = 3,
        modal = 4,
        tooltip = 5,
        notification = 6
    }
}

-- Modern Button Styles
local BUTTON_STYLES = {
    primary = {
        name = "PrimaryActionButton",
        description = "Main call-to-action buttons (Play, Continue, etc.)",
        backgroundColor = UI_DESIGN.colors.primary,
        textColor = UI_DESIGN.colors.white,
        borderColor = UI_DESIGN.colors.primaryDark,
        hoverColor = UI_DESIGN.colors.primaryDark,
        pressedColor = UI_DESIGN.colors.primaryLight,
        shadowColor = Color3.fromRGB(0, 0, 0),
        shadowTransparency = 0.8,
        cornerRadius = UI_DESIGN.radius.md,
        textFont = UI_DESIGN.fonts.button
    },
    
    secondary = {
        name = "SecondaryActionButton",
        description = "Secondary actions (Settings, Shop, etc.)",
        backgroundColor = UI_DESIGN.colors.medium,
        textColor = UI_DESIGN.colors.white,
        borderColor = UI_DESIGN.colors.dark,
        hoverColor = UI_DESIGN.colors.dark,
        pressedColor = UI_DESIGN.colors.light,
        shadowColor = Color3.fromRGB(0, 0, 0),
        shadowTransparency = 0.8,
        cornerRadius = UI_DESIGN.radius.md,
        textFont = UI_DESIGN.fonts.button
    },
    
    success = {
        name = "SuccessActionButton",
        description = "Positive actions (Claim, Upgrade, etc.)",
        backgroundColor = UI_DESIGN.colors.success,
        textColor = UI_DESIGN.colors.white,
        borderColor = Color3.fromRGB(39, 174, 96),
        hoverColor = Color3.fromRGB(39, 174, 96),
        pressedColor = Color3.fromRGB(22, 160, 133),
        shadowColor = Color3.fromRGB(0, 0, 0),
        shadowTransparency = 0.8,
        cornerRadius = UI_DESIGN.radius.md,
        textFont = UI_DESIGN.fonts.button
    },
    
    danger = {
        name = "DangerActionButton", 
        description = "Destructive actions (Delete, Reset, etc.)",
        backgroundColor = UI_DESIGN.colors.danger,
        textColor = UI_DESIGN.colors.white,
        borderColor = Color3.fromRGB(192, 57, 43),
        hoverColor = Color3.fromRGB(192, 57, 43),
        pressedColor = Color3.fromRGB(231, 76, 60),
        shadowColor = Color3.fromRGB(0, 0, 0),
        shadowTransparency = 0.8,
        cornerRadius = UI_DESIGN.radius.md,
        textFont = UI_DESIGN.fonts.button
    },
    
    minimal = {
        name = "MinimalActionButton",
        description = "Subtle actions (Close, Cancel, etc.)",
        backgroundColor = Color3.fromRGB(255, 255, 255),
        backgroundTransparency = 0.9,
        textColor = UI_DESIGN.colors.medium,
        borderColor = UI_DESIGN.colors.light,
        hoverColor = UI_DESIGN.colors.light,
        pressedColor = UI_DESIGN.colors.medium,
        shadowColor = Color3.fromRGB(0, 0, 0),
        shadowTransparency = 0.95,
        cornerRadius = UI_DESIGN.radius.sm,
        textFont = UI_DESIGN.fonts.body
    }
}

-- Modern Icon Assets (Using Unicode and custom assets)
local ICON_ASSETS = {
    -- Game Actions
    play = "⏵️", -- Play button
    pause = "⏸️", -- Pause button
    stop = "⏹️", -- Stop button
    restart = "🔄", -- Restart/refresh
    
    -- Navigation
    home = "🏠", -- Home/Hub
    back = "⬅️", -- Back navigation
    forward = "➡️", -- Forward navigation
    up = "⬆️", -- Up arrow
    down = "⬇️", -- Down arrow
    
    -- Game Elements
    coin = "🪙", -- Coins/currency
    gem = "💎", -- Premium currency
    star = "⭐", -- Stars/rating
    trophy = "🏆", -- Achievements
    crown = "👑", -- VIP/premium
    
    -- Status & Stats
    speed = "⚡", -- Speed indicator
    timer = "⏱️", -- Timer/clock
    heart = "❤️", -- Health/lives
    shield = "🛡️", -- Protection
    fire = "🔥", -- Streak/hot
    
    -- Settings & Controls
    settings = "⚙️", -- Settings gear
    sound = "🔊", -- Audio on
    soundOff = "🔇", -- Audio off
    info = "ℹ️", -- Information
    help = "❓", -- Help/question
    
    -- Social
    friend = "👥", -- Friends
    chat = "💬", -- Chat/communication
    share = "📤", -- Share
    leaderboard = "📊", -- Leaderboard
    
    -- Shop & Items
    shop = "🛒", -- Shopping cart
    gift = "🎁", -- Gifts/rewards
    chest = "📦", -- Treasure chest
    key = "🗝️", -- Keys/unlock
    
    -- Difficulty & Progress
    beginner = "🟢", -- Easy/beginner
    intermediate = "🟡", -- Medium/intermediate  
    advanced = "🟠", -- Hard/advanced
    expert = "🔴", -- Expert/insane
    master = "🟣", -- Master level
    
    -- Feedback
    checkmark = "✅", -- Success/complete
    cross = "❌", -- Error/failure
    warning = "⚠️", -- Warning
    lock = "🔒", -- Locked content
    unlock = "🔓" -- Unlocked content
}

-- Modern Background Patterns
local BACKGROUND_STYLES = {
    mainMenu = {
        name = "MainMenuBackground",
        description = "Main menu gradient background",
        gradientColors = {
            UI_DESIGN.colors.primary,
            UI_DESIGN.colors.secondary,
            UI_DESIGN.colors.primaryDark
        },
        gradientRotation = 45,
        backgroundColor = UI_DESIGN.colors.primary,
        backgroundTransparency = 0
    },
    
    gameHUD = {
        name = "GameHUDBackground",
        description = "Semi-transparent HUD background",
        backgroundColor = UI_DESIGN.colors.backgroundDark,
        backgroundTransparency = 0.3,
        blurEnabled = true
    },
    
    -- Additional styles needed for migration
    menu = {
        name = "MenuBackground",
        description = "General menu background",
        backgroundColor = UI_DESIGN.colors.backgroundMedium,
        backgroundTransparency = 0.15,
        gradientColors = {
            UI_DESIGN.colors.backgroundMedium,
            UI_DESIGN.colors.backgroundDark
        },
        gradientRotation = 90
    },
    
    game = {
        name = "GameBackground", 
        description = "In-game UI background",
        backgroundColor = UI_DESIGN.colors.backgroundDark,
        backgroundTransparency = 0.3,
        borderColor = UI_DESIGN.colors.primary,
        shadowEnabled = false
    },
    
    default = {
        name = "DefaultBackground",
        description = "Default frame background",
        backgroundColor = UI_DESIGN.colors.white,
        backgroundTransparency = 0.1,
        borderColor = UI_DESIGN.colors.light,
        shadowEnabled = false
    },
    
    card = {
        name = "CardBackground",
        description = "Card/panel background",
        backgroundColor = UI_DESIGN.colors.white,
        backgroundTransparency = 0.05,
        borderColor = UI_DESIGN.colors.light,
        shadowEnabled = true
    },
    
    modal = {
        name = "ModalBackground",
        description = "Modal dialog background",
        backgroundColor = UI_DESIGN.colors.backgroundMedium,
        backgroundTransparency = 0.1,
        overlayColor = UI_DESIGN.colors.black,
        overlayTransparency = 0.5
    }
}

-- Animation Presets
local ANIMATION_PRESETS = {
    slideInFromRight = {
        duration = 0.4,
        easingStyle = Enum.EasingStyle.Quart,
        easingDirection = Enum.EasingDirection.Out,
        startOffset = UDim2.new(1, 0, 0, 0),
        endOffset = UDim2.new(0, 0, 0, 0)
    },
    
    slideInFromBottom = {
        duration = 0.4,
        easingStyle = Enum.EasingStyle.Quart,
        easingDirection = Enum.EasingDirection.Out,
        startOffset = UDim2.new(0, 0, 1, 0),
        endOffset = UDim2.new(0, 0, 0, 0)
    },
    
    fadeIn = {
        duration = 0.3,
        easingStyle = Enum.EasingStyle.Quad,
        easingDirection = Enum.EasingDirection.Out,
        startTransparency = 1,
        endTransparency = 0
    },
    
    scaleIn = {
        duration = 0.3,
        easingStyle = Enum.EasingStyle.Back,
        easingDirection = Enum.EasingDirection.Out,
        startScale = UDim2.new(0.8, 0, 0.8, 0),
        endScale = UDim2.new(1, 0, 1, 0)
    },
    
    bounce = {
        duration = 0.2,
        easingStyle = Enum.EasingStyle.Elastic,
        easingDirection = Enum.EasingDirection.Out,
        scaleMultiplier = 1.1
    },
    
    pulse = {
        duration = 1.5,
        easingStyle = Enum.EasingStyle.Sine,
        easingDirection = Enum.EasingDirection.InOut,
        repeatCount = -1,
        reverses = true,
        scaleMultiplier = 1.05
    }
}

-- Mobile Optimization Settings
local _MOBILE_CONFIG = {
    -- Touch-friendly minimum sizes
    minButtonSize = {
        width = 48,
        height = 48
    },
    
    -- Touch target padding
    touchPadding = 8,
    
    -- Mobile-specific layouts
    layouts = {
        portrait = {
            hudPosition = UDim2.new(0, 10, 0, 10),
            buttonSpacing = 16,
            textScale = 1.2
        },
        landscape = {
            hudPosition = UDim2.new(0, 10, 0, 10),
            buttonSpacing = 12,
            textScale = 1.0
        }
    }
}

-- Component Creation Functions
function ModernUISystem.createModernButton(config)
    local style = BUTTON_STYLES[config.style] or BUTTON_STYLES.primary
    
    local button = Instance.new("TextButton")
    button.Name = config.name or style.name
    button.Size = config.size or UDim2.new(0, 200, 0, 50)
    button.Position = config.position or UDim2.new(0, 0, 0, 0)
    button.BackgroundColor3 = style.backgroundColor
    button.BackgroundTransparency = style.backgroundTransparency or 0
    button.BorderSizePixel = 0
    button.Text = config.text or "Button"
    button.TextColor3 = style.textColor
    button.TextScaled = true
    button.Font = style.textFont
    button.AutoButtonColor = false
    
    -- Add corner radius
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, style.cornerRadius)
    corner.Parent = button
    
    -- Add border/stroke
    local stroke = Instance.new("UIStroke")
    stroke.Color = style.borderColor
    stroke.Thickness = UI_DESIGN.borders.thin
    stroke.Parent = button
    
    -- Add shadow effect
    local shadow = Instance.new("Frame")
    shadow.Name = "Shadow"
    shadow.Size = UDim2.new(1, 4, 1, 4)
    shadow.Position = UDim2.new(0, 2, 0, 2)
    shadow.BackgroundColor3 = style.shadowColor
    shadow.BackgroundTransparency = style.shadowTransparency
    shadow.BorderSizePixel = 0
    shadow.ZIndex = button.ZIndex - 1
    shadow.Parent = button.Parent
    
    local shadowCorner = Instance.new("UICorner")
    shadowCorner.CornerRadius = UDim.new(0, style.cornerRadius)
    shadowCorner.Parent = shadow
    
    -- Add text padding
    local padding = Instance.new("UIPadding")
    padding.PaddingLeft = UDim.new(0, UI_DESIGN.spacing.md)
    padding.PaddingRight = UDim.new(0, UI_DESIGN.spacing.md)
    padding.PaddingTop = UDim.new(0, UI_DESIGN.spacing.sm)
    padding.PaddingBottom = UDim.new(0, UI_DESIGN.spacing.sm)
    padding.Parent = button
    
    -- Add hover and press animations
    button.MouseEnter:Connect(function()
        local hoverTween = TweenService:Create(
            button,
            TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
            {BackgroundColor3 = style.hoverColor}
        )
        hoverTween:Play()
    end)
    
    button.MouseLeave:Connect(function()
        local leaveTween = TweenService:Create(
            button,
            TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
            {BackgroundColor3 = style.backgroundColor}
        )
        leaveTween:Play()
    end)
    
    button.MouseButton1Down:Connect(function()
        local pressTween = TweenService:Create(
            button,
            TweenInfo.new(0.1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
            {
                BackgroundColor3 = style.pressedColor,
                Size = button.Size - UDim2.new(0, 4, 0, 4)
            }
        )
        pressTween:Play()
    end)
    
    button.MouseButton1Up:Connect(function()
        local releaseTween = TweenService:Create(
            button,
            TweenInfo.new(0.1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
            {
                BackgroundColor3 = style.backgroundColor,
                Size = config.size or UDim2.new(0, 200, 0, 50)
            }
        )
        releaseTween:Play()
    end)
    
    return button
end

function ModernUISystem.createIconButton(config)
    local button = ModernUISystem.createModernButton(config)
    button.Text = ""
    
    -- Add icon
    local iconLabel = Instance.new("TextLabel")
    iconLabel.Name = "Icon"
    iconLabel.Size = UDim2.new(0.6, 0, 0.6, 0)
    iconLabel.Position = UDim2.new(0.2, 0, 0.2, 0)
    iconLabel.BackgroundTransparency = 1
    iconLabel.Text = ICON_ASSETS[config.icon] or config.customIcon or "❓"
    iconLabel.TextColor3 = button.TextColor3
    iconLabel.TextScaled = true
    iconLabel.Font = Enum.Font.SourceSansBold
    iconLabel.Parent = button
    
    return button
end

function ModernUISystem.createModernFrame(config)
    local style = BACKGROUND_STYLES[config.style] or BACKGROUND_STYLES.card
    
    local frame = Instance.new("Frame")
    frame.Name = config.name or style.name
    frame.Size = config.size or UDim2.new(0, 300, 0, 200)
    frame.Position = config.position or UDim2.new(0, 0, 0, 0)
    frame.BackgroundColor3 = style.backgroundColor
    frame.BackgroundTransparency = style.backgroundTransparency or 0
    frame.BorderSizePixel = 0
    
    -- Add corner radius
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, UI_DESIGN.radius.lg)
    corner.Parent = frame
    
    -- Add border if specified
    if style.borderColor then
        local stroke = Instance.new("UIStroke")
        stroke.Color = style.borderColor
        stroke.Thickness = UI_DESIGN.borders.thin
        stroke.Parent = frame
    end
    
    -- Add gradient background if specified
    if style.gradientColors then
        local gradient = Instance.new("UIGradient")
        gradient.Color = ColorSequence.new(style.gradientColors)
        gradient.Rotation = style.gradientRotation or 0
        gradient.Parent = frame
    end
    
    -- Add shadow if enabled
    if style.shadowEnabled then
        local shadow = Instance.new("Frame")
        shadow.Name = "Shadow"
        shadow.Size = UDim2.new(1, 8, 1, 8)
        shadow.Position = UDim2.new(0, 4, 0, 4)
        shadow.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
        shadow.BackgroundTransparency = 0.8
        shadow.BorderSizePixel = 0
        shadow.ZIndex = frame.ZIndex - 1
        shadow.Parent = frame.Parent
        
        local shadowCorner = Instance.new("UICorner")
        shadowCorner.CornerRadius = UDim.new(0, UI_DESIGN.radius.lg)
        shadowCorner.Parent = shadow
    end
    
    return frame
end

function ModernUISystem.createInfoCard(config)
    local card = ModernUISystem.createModernFrame({
        name = config.name or "InfoCard",
        style = "card",
        size = config.size or UDim2.new(0, 250, 0, 150),
        position = config.position
    })
    
    -- Add icon
    local iconFrame = Instance.new("Frame")
    iconFrame.Name = "IconFrame"
    iconFrame.Size = UDim2.new(0, 50, 0, 50)
    iconFrame.Position = UDim2.new(0, UI_DESIGN.spacing.md, 0, UI_DESIGN.spacing.md)
    iconFrame.BackgroundColor3 = config.iconColor or UI_DESIGN.colors.primary
    iconFrame.BorderSizePixel = 0
    iconFrame.Parent = card
    
    local iconCorner = Instance.new("UICorner")
    iconCorner.CornerRadius = UDim.new(0, UI_DESIGN.radius.round)
    iconCorner.Parent = iconFrame
    
    local iconLabel = Instance.new("TextLabel")
    iconLabel.Size = UDim2.new(0.6, 0, 0.6, 0)
    iconLabel.Position = UDim2.new(0.2, 0, 0.2, 0)
    iconLabel.BackgroundTransparency = 1
    iconLabel.Text = ICON_ASSETS[config.icon] or "📊"
    iconLabel.TextColor3 = UI_DESIGN.colors.white
    iconLabel.TextScaled = true
    iconLabel.Font = Enum.Font.SourceSansBold
    iconLabel.Parent = iconFrame
    
    -- Add title
    local titleLabel = Instance.new("TextLabel")
    titleLabel.Name = "TitleLabel"
    titleLabel.Size = UDim2.new(1, -90, 0, 30)
    titleLabel.Position = UDim2.new(0, 70, 0, UI_DESIGN.spacing.md)
    titleLabel.BackgroundTransparency = 1
    titleLabel.Text = config.title or "Title"
    titleLabel.TextColor3 = UI_DESIGN.colors.dark
    titleLabel.TextXAlignment = Enum.TextXAlignment.Left
    titleLabel.TextScaled = true
    titleLabel.Font = UI_DESIGN.fonts.subheading
    titleLabel.Parent = card
    
    -- Add value
    local valueLabel = Instance.new("TextLabel")
    valueLabel.Name = "ValueLabel"
    valueLabel.Size = UDim2.new(1, -90, 0, 40)
    valueLabel.Position = UDim2.new(0, 70, 0, 50)
    valueLabel.BackgroundTransparency = 1
    valueLabel.Text = config.value or "0"
    valueLabel.TextColor3 = config.valueColor or UI_DESIGN.colors.primary
    valueLabel.TextXAlignment = Enum.TextXAlignment.Left
    valueLabel.TextScaled = true
    valueLabel.Font = UI_DESIGN.fonts.heading
    valueLabel.Parent = card
    
    -- Add description
    local descLabel = Instance.new("TextLabel")
    descLabel.Name = "DescriptionLabel"
    descLabel.Size = UDim2.new(1, -90, 0, 25)
    descLabel.Position = UDim2.new(0, 70, 1, -35)
    descLabel.BackgroundTransparency = 1
    descLabel.Text = config.description or "Description"
    descLabel.TextColor3 = UI_DESIGN.colors.medium
    descLabel.TextXAlignment = Enum.TextXAlignment.Left
    descLabel.TextScaled = true
    descLabel.Font = UI_DESIGN.fonts.caption
    descLabel.Parent = card
    
    return card
end

function ModernUISystem.applyMobileOptimization(gui)
    -- Add UIScale for mobile adaptation
    local uiScale = Instance.new("UIScale")
    uiScale.Scale = 1.0 -- Will be adjusted based on screen size
    uiScale.Parent = gui
    
    -- Adjust scale based on screen size
    local function updateScale()
        local viewport = workspace.CurrentCamera.ViewportSize
        local baseResolution = Vector2.new(1920, 1080)
        local scale = math.min(viewport.X / baseResolution.X, viewport.Y / baseResolution.Y)
        
        -- Ensure minimum scale for readability
        scale = math.max(scale, 0.5)
        
        -- Apply mobile-specific scaling
        if GuiService:IsTenFootInterface() then
            scale = scale * 1.5 -- Console scaling
        elseif UserInputService.TouchEnabled and not UserInputService.MouseEnabled then
            scale = scale * 1.2 -- Mobile scaling
        end
        
        uiScale.Scale = scale
    end
    
    updateScale()
    workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(updateScale)
    
    return uiScale
end

function ModernUISystem.animateElement(element, animationType, config)
    local preset = ANIMATION_PRESETS[animationType]
    if not preset then return end
    
    local tweenInfo = TweenInfo.new(
        config.duration or preset.duration,
        config.easingStyle or preset.easingStyle,
        config.easingDirection or preset.easingDirection,
        config.repeatCount or preset.repeatCount or 0,
        config.reverses or preset.reverses or false
    )
    
    local properties = {}
    
    if animationType == "fadeIn" then
        element.BackgroundTransparency = preset.startTransparency
        properties.BackgroundTransparency = preset.endTransparency
    elseif animationType == "scaleIn" then
        element.Size = preset.startScale
        properties.Size = preset.endScale
    elseif animationType == "slideInFromRight" then
        element.Position = element.Position + preset.startOffset
        properties.Position = element.Position - preset.startOffset
    elseif animationType == "slideInFromBottom" then
        element.Position = element.Position + preset.startOffset
        properties.Position = element.Position - preset.startOffset
    elseif animationType == "bounce" then
        properties.Size = element.Size * preset.scaleMultiplier
    elseif animationType == "pulse" then
        properties.BackgroundTransparency = 0.5
    end
    
    local tween = TweenService:Create(element, tweenInfo, properties)
    tween:Play()
    
    return tween
end

-- Utility functions
function ModernUISystem.getDesignTokens()
    return UI_DESIGN
end

function ModernUISystem.getIconAsset(iconName)
    return ICON_ASSETS[iconName] or "❓"
end

function ModernUISystem.getButtonStyle(styleName)
    return BUTTON_STYLES[styleName] or BUTTON_STYLES.primary
end

function ModernUISystem.getBackgroundStyle(styleName)
    return BACKGROUND_STYLES[styleName] or BACKGROUND_STYLES.card
end

-- Additional required functions for UIPlaceholderMigration
function ModernUISystem.replaceUIElement(oldElement, newConfig)
    -- Replace an existing UI element with a modern equivalent
    local parent = oldElement.Parent
    if not parent then return nil end
    
    local elementType = oldElement.ClassName
    local newElement = nil
    
    if elementType == "TextButton" or elementType == "ImageButton" then
        newElement = ModernUISystem.createModernButton({
            name = oldElement.Name,
            text = oldElement.Text or "Button",
            style = newConfig.style or "primary",
            size = oldElement.Size,
            position = oldElement.Position
        })
    elseif elementType == "Frame" then
        newElement = ModernUISystem.createModernFrame({
            name = oldElement.Name,
            style = newConfig.style or "default",
            size = oldElement.Size,
            position = oldElement.Position
        })
    elseif elementType == "ImageLabel" then
        newElement = ModernUISystem.createIconButton({
            name = oldElement.Name,
            icon = newConfig.icon or "star",
            style = "minimal",
            size = oldElement.Size,
            position = oldElement.Position
        })
    else
        -- Default frame replacement for unknown types
        newElement = ModernUISystem.createModernFrame({
            name = oldElement.Name,
            style = "default",
            size = oldElement.Size,
            position = oldElement.Position
        })
    end
    
    if newElement then
        -- Copy common properties
        newElement.Visible = oldElement.Visible
        newElement.ZIndex = oldElement.ZIndex
        if oldElement:GetAttribute("LayoutOrder") then
            newElement.LayoutOrder = oldElement.LayoutOrder
        end
        
        -- Move children to new element
        for _, child in pairs(oldElement:GetChildren()) do
            if not child:IsA("UICorner") and not child:IsA("UIGradient") and not child:IsA("UIStroke") then
                child.Parent = newElement
            end
        end
        
        -- Replace in parent
        newElement.Parent = parent
        oldElement:Destroy()
    end
    
    return newElement
end

function ModernUISystem.enhanceExistingElement(element, config)
    -- Enhance an existing element with modern styling without replacing it
    config = config or {}
    
    if element:IsA("TextButton") then
        -- Apply modern button styling
        element.Font = Enum.Font.GothamBold
        element.BorderSizePixel = 0
        
        -- Add corner radius if not present
        if not element:FindFirstChildOfClass("UICorner") then
            local corner = Instance.new("UICorner")
            corner.CornerRadius = UDim.new(0, UI_DESIGN.radius.md)
            corner.Parent = element
        end
        
        -- Apply color scheme
        local style = BUTTON_STYLES[config.style or "primary"]
        element.BackgroundColor3 = style.backgroundColor
        element.TextColor3 = style.textColor
        
    elseif element:IsA("Frame") then
        -- Apply modern frame styling
        element.BorderSizePixel = 0
        
        -- Add corner radius if not present
        if not element:FindFirstChildOfClass("UICorner") then
            local corner = Instance.new("UICorner")
            corner.CornerRadius = UDim.new(0, UI_DESIGN.radius.lg)
            corner.Parent = element
        end
        
    elseif element:IsA("TextLabel") then
        -- Apply modern text styling
        if element.Font == Enum.Font.Legacy or element.Font == Enum.Font.Arial then
            element.Font = UI_DESIGN.fonts.body
        end
        
        -- Improve text readability
        if config.addStroke then
            element.TextStrokeTransparency = 0.8
            element.TextStrokeColor3 = Color3.new(0, 0, 0)
        end
    end
    
    -- Mark as processed
    element:SetAttribute("ModernUI_Enhanced", true)
    
    return element
end

function ModernUISystem.createProductionReadyElement(elementType, config)
    -- Create production-ready elements with no placeholder content
    config = config or {}
    
    if elementType == "button" then
        return ModernUISystem.createModernButton({
            name = config.name or "ProductionButton",
            text = config.text or "Action",
            style = config.style or "primary",
            size = config.size or UDim2.new(0, 200, 0, 50),
            position = config.position or UDim2.new(0, 0, 0, 0)
        })
        
    elseif elementType == "frame" then
        return ModernUISystem.createModernFrame({
            name = config.name or "ProductionFrame",
            style = config.style or "default",
            size = config.size or UDim2.new(0, 300, 0, 200),
            position = config.position or UDim2.new(0, 0, 0, 0)
        })
        
    elseif elementType == "icon" then
        return ModernUISystem.createIconButton({
            name = config.name or "ProductionIcon",
            icon = config.icon or "star",
            style = "minimal",
            size = config.size or UDim2.new(0, 50, 0, 50),
            position = config.position or UDim2.new(0, 0, 0, 0)
        })
        
    else
        warn("Unknown element type for production creation: " .. tostring(elementType))
        return nil
    end
end

return ModernUISystem
