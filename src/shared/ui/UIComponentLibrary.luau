-- UIComponentLibrary.luau
-- Comprehensive UI component library with accessibility and responsive design
-- Provides reusable, consistent components across the application

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local GuiService = game:GetService("GuiService")
local SoundService = game:GetService("SoundService")

local SafeRequire = require(ReplicatedStorage.Shared.utils.SafeRequire)
local UIDesignTokens = SafeRequire.require(ReplicatedStorage.Shared.ui.UIDesignTokens)

local UIComponentLibrary = {}

-- ========================================
-- COMPONENT CONFIGURATION
-- ========================================

local COMPONENT_DEFAULTS = {
    -- Animation Configuration
    animations = {
        duration = 0.2,
        easing = Enum.EasingStyle.Quad,
        direction = Enum.EasingDirection.Out
    },
    
    -- Accessibility Configuration
    accessibility = {
        enableSounds = true,
        enableHaptics = true,
        enableKeyboardNavigation = true,
        enableScreenReader = true,
        minimumContrastRatio = 4.5
    },
    
    -- Responsive Configuration
    responsive = {
        autoScale = true,
        touchOptimization = true,
        adaptiveSpacing = true
    }
}

-- ========================================
-- BUTTON COMPONENT
-- ========================================

function UIComponentLibrary.createButton(config)
    config = config or {}
    
    -- Get design tokens
    local tokens = UIDesignTokens.getTokens()
    local deviceType = UIDesignTokens.getDeviceType()
    local isTouch = UserInputService.TouchEnabled
    
    -- Default configuration
    local buttonConfig = {
        variant = config.variant or "primary",
        size = config.size or "medium",
        text = config.text or "Button",
        icon = config.icon,
        disabled = config.disabled or false,
        loading = config.loading or false,
        fullWidth = config.fullWidth or false,
        onClick = config.onClick,
        
        -- Accessibility
        ariaLabel = config.ariaLabel or config.text,
        ariaDescription = config.ariaDescription,
        role = "button"
    }
    
    -- Size variants
    local sizeConfig = {
        small = {
            height = UIDesignTokens.getTouchTargetSize("minimum", isTouch),
            fontSize = UIDesignTokens.getResponsiveSize("sm", deviceType),
            padding = UIDesignTokens.getResponsiveSpacing("sm", deviceType)
        },
        medium = {
            height = UIDesignTokens.getTouchTargetSize("comfortable", isTouch),
            fontSize = UIDesignTokens.getResponsiveSize("base", deviceType),
            padding = UIDesignTokens.getResponsiveSpacing("md", deviceType)
        },
        large = {
            height = UIDesignTokens.getTouchTargetSize("large", isTouch),
            fontSize = UIDesignTokens.getResponsiveSize("lg", deviceType),
            padding = UIDesignTokens.getResponsiveSpacing("lg", deviceType)
        }
    }
    
    local currentSize = sizeConfig[buttonConfig.size]
    
    -- Variant styles
    local variantStyles = {
        primary = {
            backgroundColor = tokens.colors.brand.primary,
            textColor = tokens.colors.text.inverse,
            borderColor = tokens.colors.brand.primary,
            hoverColor = tokens.colors.interactive.hover,
            pressedColor = tokens.colors.interactive.pressed
        },
        secondary = {
            backgroundColor = tokens.colors.surface.elevated,
            textColor = tokens.colors.text.primary,
            borderColor = tokens.colors.brand.primary,
            hoverColor = tokens.colors.gray.gray100,
            pressedColor = tokens.colors.gray.gray200
        },
        tertiary = {
            backgroundColor = Color3.new(0, 0, 0),
            backgroundTransparency = 1,
            textColor = tokens.colors.brand.primary,
            borderColor = Color3.new(0, 0, 0),
            borderTransparency = 1,
            hoverColor = tokens.colors.gray.gray100,
            pressedColor = tokens.colors.gray.gray200
        },
        danger = {
            backgroundColor = tokens.colors.semantic.error,
            textColor = tokens.colors.text.inverse,
            borderColor = tokens.colors.semantic.error,
            hoverColor = Color3.fromRGB(230, 45, 35),
            pressedColor = Color3.fromRGB(200, 35, 25)
        }
    }
    
    local currentStyle = variantStyles[buttonConfig.variant] or variantStyles.primary
    
    -- Create button element
    local button = Instance.new("TextButton")
    button.Name = config.name or ("Button_" .. buttonConfig.variant)
    button.Size = UDim2.new(
        buttonConfig.fullWidth and 1 or 0,
        buttonConfig.fullWidth and 0 or math.max(120, #buttonConfig.text * 8 + currentSize.padding * 2),
        0,
        currentSize.height
    )
    button.Position = config.position or UDim2.new(0, 0, 0, 0)
    button.AnchorPoint = config.anchorPoint or Vector2.new(0, 0)
    
    -- Apply base styling
    button.BackgroundColor3 = currentStyle.backgroundColor
    button.BackgroundTransparency = currentStyle.backgroundTransparency or 0
    button.BorderSizePixel = 0
    button.Text = buttonConfig.text
    button.TextColor3 = currentStyle.textColor
    button.TextSize = currentSize.fontSize
    button.Font = tokens.typography.fonts.primary
    button.TextScaled = false
    button.TextWrapped = true
    button.AutoButtonColor = false
    
    -- Disabled state
    if buttonConfig.disabled then
        button.BackgroundColor3 = tokens.colors.interactive.disabled
        button.TextColor3 = tokens.colors.text.quaternary
    end
    
    -- Add corner radius
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, tokens.borderRadius.md)
    corner.Parent = button
    
    -- Add border (stroke)
    local stroke = Instance.new("UIStroke")
    stroke.Color = currentStyle.borderColor
    stroke.Thickness = tokens.borderWidth.base
    stroke.Transparency = currentStyle.borderTransparency or 0
    stroke.Parent = button
    
    -- Add padding
    local padding = Instance.new("UIPadding")
    padding.PaddingLeft = UDim.new(0, currentSize.padding)
    padding.PaddingRight = UDim.new(0, currentSize.padding)
    padding.PaddingTop = UDim.new(0, tokens.spacing.xs)
    padding.PaddingBottom = UDim.new(0, tokens.spacing.xs)
    padding.Parent = button
    
    -- Add icon if specified
    if buttonConfig.icon then
        local iconFrame = Instance.new("Frame")
        iconFrame.Name = "IconFrame"
        iconFrame.Size = UDim2.new(0, currentSize.fontSize, 0, currentSize.fontSize)
        iconFrame.Position = UDim2.new(0, 0, 0.5, -(currentSize.fontSize / 2))
        iconFrame.BackgroundTransparency = 1
        iconFrame.Parent = button
        
        local iconLabel = Instance.new("TextLabel")
        iconLabel.Size = UDim2.new(1, 0, 1, 0)
        iconLabel.BackgroundTransparency = 1
        iconLabel.Text = buttonConfig.icon
        iconLabel.TextColor3 = currentStyle.textColor
        iconLabel.TextSize = currentSize.fontSize
        iconLabel.Font = tokens.typography.fonts.primary
        iconLabel.TextScaled = true
        iconLabel.Parent = iconFrame
        
        -- Adjust text position for icon
        button.TextXAlignment = Enum.TextXAlignment.Left
        padding.PaddingLeft = UDim.new(0, currentSize.padding + currentSize.fontSize + tokens.spacing.xs)
    end
    
    -- Add loading spinner if specified
    if buttonConfig.loading then
        local spinner = UIComponentLibrary.createLoadingSpinner({
            size = UDim2.new(0, currentSize.fontSize, 0, currentSize.fontSize),
            position = UDim2.new(1, -(currentSize.padding + currentSize.fontSize), 0.5, -(currentSize.fontSize / 2)),
            parent = button
        })
        
        button.Text = buttonConfig.text .. "..."
    end
    
    -- ========================================
    -- BUTTON INTERACTIONS
    -- ========================================
    
    -- Hover effects
    local function onHover()
        if buttonConfig.disabled or buttonConfig.loading then return end
        
        local hoverTween = TweenService:Create(
            button,
            TweenInfo.new(COMPONENT_DEFAULTS.animations.duration, COMPONENT_DEFAULTS.animations.easing),
            {
                BackgroundColor3 = currentStyle.hoverColor,
                Size = UDim2.new(button.Size.X.Scale, button.Size.X.Offset, button.Size.Y.Scale, button.Size.Y.Offset + 2)
            }
        )
        hoverTween:Play()
        
        -- Play hover sound
        if COMPONENT_DEFAULTS.accessibility.enableSounds then
            UIComponentLibrary.playUISound("hover")
        end
    end
    
    local function onLeave()
        if buttonConfig.disabled or buttonConfig.loading then return end
        
        local leaveTween = TweenService:Create(
            button,
            TweenInfo.new(COMPONENT_DEFAULTS.animations.duration, COMPONENT_DEFAULTS.animations.easing),
            {
                BackgroundColor3 = currentStyle.backgroundColor,
                Size = UDim2.new(button.Size.X.Scale, button.Size.X.Offset, button.Size.Y.Scale, button.Size.Y.Offset - 2)
            }
        )
        leaveTween:Play()
    end
    
    local function onPress()
        if buttonConfig.disabled or buttonConfig.loading then return end
        
        local pressTween = TweenService:Create(
            button,
            TweenInfo.new(0.1, Enum.EasingStyle.Quad),
            {
                BackgroundColor3 = currentStyle.pressedColor,
                Size = UDim2.new(button.Size.X.Scale, button.Size.X.Offset - 2, button.Size.Y.Scale, button.Size.Y.Offset - 2)
            }
        )
        pressTween:Play()
        
        -- Play click sound
        if COMPONENT_DEFAULTS.accessibility.enableSounds then
            UIComponentLibrary.playUISound("click")
        end
        
        -- Haptic feedback
        if COMPONENT_DEFAULTS.accessibility.enableHaptics and UserInputService.TouchEnabled then
            UserInputService:GetPlatformService():PerformHapticFeedback(Enum.HapticFeedbackType.ImpactLight)
        end
    end
    
    local function onRelease()
        if buttonConfig.disabled or buttonConfig.loading then return end
        
        wait(0.1)
        onLeave()
        
        -- Execute callback
        if buttonConfig.onClick then
            pcall(buttonConfig.onClick)
        end
    end
    
    -- Connect events
    button.MouseEnter:Connect(onHover)
    button.MouseLeave:Connect(onLeave)
    button.MouseButton1Down:Connect(onPress)
    button.MouseButton1Up:Connect(onRelease)
    
    -- Accessibility attributes
    button:SetAttribute("AriaLabel", buttonConfig.ariaLabel)
    button:SetAttribute("AriaDescription", buttonConfig.ariaDescription)
    button:SetAttribute("Role", buttonConfig.role)
    button:SetAttribute("Disabled", buttonConfig.disabled)
    
    -- Public methods
    local buttonMethods = {
        setDisabled = function(disabled)
            buttonConfig.disabled = disabled
            button:SetAttribute("Disabled", disabled)
            
            if disabled then
                button.BackgroundColor3 = tokens.colors.interactive.disabled
                button.TextColor3 = tokens.colors.text.quaternary
            else
                button.BackgroundColor3 = currentStyle.backgroundColor
                button.TextColor3 = currentStyle.textColor
            end
        end,
        
        setLoading = function(loading)
            buttonConfig.loading = loading
            -- Implementation would add/remove spinner
        end,
        
        setText = function(text)
            buttonConfig.text = text
            button.Text = text
        end,
        
        getElement = function()
            return button
        end
    }
    
    return buttonMethods
end

-- ========================================
-- INPUT COMPONENT
-- ========================================

function UIComponentLibrary.createInput(config)
    config = config or {}
    
    local tokens = UIDesignTokens.getTokens()
    local deviceType = UIDesignTokens.getDeviceType()
    local isTouch = UserInputService.TouchEnabled
    
    -- Input configuration
    local inputConfig = {
        type = config.type or "text", -- text, password, number, email
        placeholder = config.placeholder or "Enter text...",
        value = config.value or "",
        disabled = config.disabled or false,
        required = config.required or false,
        maxLength = config.maxLength,
        multiline = config.multiline or false,
        
        -- Validation
        validator = config.validator,
        errorMessage = config.errorMessage,
        
        -- Events
        onFocus = config.onFocus,
        onBlur = config.onBlur,
        onChange = config.onChange,
        onSubmit = config.onSubmit,
        
        -- Accessibility
        ariaLabel = config.ariaLabel or config.placeholder,
        ariaDescription = config.ariaDescription
    }
    
    -- Create container
    local container = Instance.new("Frame")
    container.Name = config.name or "InputContainer"
    container.Size = config.size or UDim2.new(1, 0, 0, UIDesignTokens.getTouchTargetSize("comfortable", isTouch))
    container.Position = config.position or UDim2.new(0, 0, 0, 0)
    container.BackgroundTransparency = 1
    
    -- Create input field
    local inputField = inputConfig.multiline and Instance.new("TextBox") or Instance.new("TextBox")
    inputField.Name = "InputField"
    inputField.Size = UDim2.new(1, 0, 1, 0)
    inputField.BackgroundColor3 = tokens.colors.surface.elevated
    inputField.BorderSizePixel = 0
    inputField.Text = inputConfig.value
    inputField.PlaceholderText = inputConfig.placeholder
    inputField.TextColor3 = tokens.colors.text.primary
    inputField.PlaceholderColor3 = tokens.colors.text.tertiary
    inputField.TextSize = UIDesignTokens.getResponsiveSize("base", deviceType)
    inputField.Font = tokens.typography.fonts.primary
    inputField.TextXAlignment = Enum.TextXAlignment.Left
    inputField.TextYAlignment = inputConfig.multiline and Enum.TextYAlignment.Top or Enum.TextYAlignment.Center
    inputField.ClearTextOnFocus = false
    inputField.TextScaled = false
    inputField.Parent = container
    
    -- Multiline specific settings
    if inputConfig.multiline then
        inputField.TextWrapped = true
        inputField.Size = UDim2.new(1, 0, 1, 0)
    end
    
    -- Password masking
    if inputConfig.type == "password" then
        inputField.TextTransparency = 0
        -- Note: Roblox doesn't have native password masking, would need custom implementation
    end
    
    -- Max length
    if inputConfig.maxLength then
        inputField:GetPropertyChangedSignal("Text"):Connect(function()
            if #inputField.Text > inputConfig.maxLength then
                inputField.Text = string.sub(inputField.Text, 1, inputConfig.maxLength)
            end
        end)
    end
    
    -- Add corner radius
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, tokens.borderRadius.base)
    corner.Parent = inputField
    
    -- Add border
    local stroke = Instance.new("UIStroke")
    stroke.Color = tokens.colors.gray.gray300
    stroke.Thickness = tokens.borderWidth.base
    stroke.Parent = inputField
    
    -- Add padding
    local padding = Instance.new("UIPadding")
    local paddingValue = UIDesignTokens.getResponsiveSpacing("md", deviceType)
    padding.PaddingLeft = UDim.new(0, paddingValue)
    padding.PaddingRight = UDim.new(0, paddingValue)
    padding.PaddingTop = UDim.new(0, tokens.spacing.sm)
    padding.PaddingBottom = UDim.new(0, tokens.spacing.sm)
    padding.Parent = inputField
    
    -- Focus and blur effects
    local function onFocus()
        stroke.Color = tokens.colors.brand.primary
        stroke.Thickness = tokens.borderWidth.thick
        
        if inputConfig.onFocus then
            pcall(inputConfig.onFocus)
        end
    end
    
    local function onBlur()
        stroke.Color = tokens.colors.gray.gray300
        stroke.Thickness = tokens.borderWidth.base
        
        -- Validation on blur
        if inputConfig.validator then
            local isValid, errorMsg = inputConfig.validator(inputField.Text)
            if not isValid then
                UIComponentLibrary.showInputError(container, errorMsg or inputConfig.errorMessage)
            else
                UIComponentLibrary.hideInputError(container)
            end
        end
        
        if inputConfig.onBlur then
            pcall(inputConfig.onBlur)
        end
    end
    
    -- Connect events
    inputField.Focused:Connect(onFocus)
    inputField.FocusLost:Connect(onBlur)
    
    if inputConfig.onChange then
        inputField:GetPropertyChangedSignal("Text"):Connect(function()
            pcall(inputConfig.onChange, inputField.Text)
        end)
    end
    
    -- Accessibility attributes
    inputField:SetAttribute("AriaLabel", inputConfig.ariaLabel)
    inputField:SetAttribute("AriaDescription", inputConfig.ariaDescription)
    inputField:SetAttribute("Required", inputConfig.required)
    
    -- Public methods
    local inputMethods = {
        getValue = function()
            return inputField.Text
        end,
        
        setValue = function(value)
            inputField.Text = tostring(value)
        end,
        
        setDisabled = function(disabled)
            inputField.TextEditable = not disabled
            inputField.BackgroundColor3 = disabled and tokens.colors.gray.gray100 or tokens.colors.surface.elevated
        end,
        
        focus = function()
            inputField:CaptureFocus()
        end,
        
        blur = function()
            inputField:ReleaseFocus()
        end,
        
        validate = function()
            if inputConfig.validator then
                return inputConfig.validator(inputField.Text)
            end
            return true
        end,
        
        getElement = function()
            return container
        end
    }
    
    return inputMethods
end

-- ========================================
-- CARD COMPONENT
-- ========================================

function UIComponentLibrary.createCard(config)
    config = config or {}
    
    local tokens = UIDesignTokens.getTokens()
    local deviceType = UIDesignTokens.getDeviceType()
    
    -- Card configuration
    local cardConfig = {
        variant = config.variant or "elevated", -- elevated, outlined, filled
        padding = config.padding or "md",
        shadow = config.shadow or "base",
        interactive = config.interactive or false,
        onClick = config.onClick
    }
    
    -- Create card
    local card = Instance.new("Frame")
    card.Name = config.name or "Card"
    card.Size = config.size or UDim2.new(0, 300, 0, 200)
    card.Position = config.position or UDim2.new(0, 0, 0, 0)
    card.BorderSizePixel = 0
    
    -- Variant styling
    if cardConfig.variant == "elevated" then
        card.BackgroundColor3 = tokens.colors.surface.elevated
        card.BackgroundTransparency = 0
    elseif cardConfig.variant == "outlined" then
        card.BackgroundColor3 = tokens.colors.surface.base
        card.BackgroundTransparency = 0
        
        local stroke = Instance.new("UIStroke")
        stroke.Color = tokens.colors.gray.gray300
        stroke.Thickness = tokens.borderWidth.base
        stroke.Parent = card
    elseif cardConfig.variant == "filled" then
        card.BackgroundColor3 = tokens.colors.gray.gray50
        card.BackgroundTransparency = 0
    end
    
    -- Add corner radius
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, tokens.borderRadius.lg)
    corner.Parent = card
    
    -- Add padding
    local padding = Instance.new("UIPadding")
    local paddingValue = UIDesignTokens.getResponsiveSpacing(cardConfig.padding, deviceType)
    padding.PaddingLeft = UDim.new(0, paddingValue)
    padding.PaddingRight = UDim.new(0, paddingValue)
    padding.PaddingTop = UDim.new(0, paddingValue)
    padding.PaddingBottom = UDim.new(0, paddingValue)
    padding.Parent = card
    
    -- Add shadow effect (simulated with Frame)
    if cardConfig.shadow ~= "none" then
        local shadowData = tokens.shadows[cardConfig.shadow]
        if shadowData then
            local shadow = Instance.new("Frame")
            shadow.Name = "Shadow"
            shadow.Size = UDim2.new(1, shadowData.blur, 1, shadowData.blur)
            shadow.Position = UDim2.new(0, shadowData.offset.X, 0, shadowData.offset.Y)
            shadow.BackgroundColor3 = Color3.new(0, 0, 0)
            shadow.BackgroundTransparency = shadowData.transparency
            shadow.BorderSizePixel = 0
            shadow.ZIndex = card.ZIndex - 1
            shadow.Parent = card.Parent
            
            local shadowCorner = Instance.new("UICorner")
            shadowCorner.CornerRadius = corner.CornerRadius
            shadowCorner.Parent = shadow
            
            -- Move shadow behind card when card is added to parent
            card:GetPropertyChangedSignal("Parent"):Connect(function()
                if card.Parent then
                    shadow.Parent = card.Parent
                end
            end)
        end
    end
    
    -- Interactive behavior
    if cardConfig.interactive then
        local button = Instance.new("TextButton")
        button.Size = UDim2.new(1, 0, 1, 0)
        button.BackgroundTransparency = 1
        button.Text = ""
        button.Parent = card
        
        -- Hover effects
        button.MouseEnter:Connect(function()
            local hoverTween = TweenService:Create(
                card,
                TweenInfo.new(0.2, Enum.EasingStyle.Quad),
                {Size = UDim2.new(card.Size.X.Scale, card.Size.X.Offset + 4, card.Size.Y.Scale, card.Size.Y.Offset + 4)}
            )
            hoverTween:Play()
        end)
        
        button.MouseLeave:Connect(function()
            local leaveTween = TweenService:Create(
                card,
                TweenInfo.new(0.2, Enum.EasingStyle.Quad),
                {Size = UDim2.new(card.Size.X.Scale, card.Size.X.Offset - 4, card.Size.Y.Scale, card.Size.Y.Offset - 4)}
            )
            leaveTween:Play()
        end)
        
        button.MouseButton1Click:Connect(function()
            if cardConfig.onClick then
                pcall(cardConfig.onClick)
            end
        end)
    end
    
    return {
        getElement = function()
            return card
        end,
        
        setContent = function(content)
            -- Clear existing content
            for _, child in ipairs(card:GetChildren()) do
                if not child:IsA("UICorner") and not child:IsA("UIPadding") and not child:IsA("UIStroke") then
                    child:Destroy()
                end
            end
            
            -- Add new content
            if content then
                content.Parent = card
            end
        end
    }
end

-- ========================================
-- MODAL COMPONENT
-- ========================================

function UIComponentLibrary.createModal(config)
    config = config or {}
    
    local tokens = UIDesignTokens.getTokens()
    
    -- Modal configuration
    local modalConfig = {
        size = config.size or "medium", -- small, medium, large, fullscreen
        title = config.title or "Modal",
        content = config.content,
        showCloseButton = config.showCloseButton ~= false,
        closeOnBackdrop = config.closeOnBackdrop ~= false,
        onClose = config.onClose,
        onOpen = config.onOpen
    }
    
    -- Size variants
    local sizeVariants = {
        small = UDim2.new(0, 400, 0, 300),
        medium = UDim2.new(0, 600, 0, 400),
        large = UDim2.new(0, 800, 0, 600),
        fullscreen = UDim2.new(0.95, 0, 0.95, 0)
    }
    
    -- Create modal container
    local modalGui = Instance.new("ScreenGui")
    modalGui.Name = config.name or "Modal"
    modalGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    modalGui.DisplayOrder = tokens.zIndex.modal
    
    -- Backdrop
    local backdrop = Instance.new("Frame")
    backdrop.Name = "Backdrop"
    backdrop.Size = UDim2.new(1, 0, 1, 0)
    backdrop.BackgroundColor3 = tokens.colors.background.overlay
    backdrop.BackgroundTransparency = 0.5
    backdrop.BorderSizePixel = 0
    backdrop.Parent = modalGui
    
    -- Modal content
    local modal = Instance.new("Frame")
    modal.Name = "Modal"
    modal.Size = sizeVariants[modalConfig.size]
    modal.Position = UDim2.new(0.5, 0, 0.5, 0)
    modal.AnchorPoint = Vector2.new(0.5, 0.5)
    modal.BackgroundColor3 = tokens.colors.surface.elevated
    modal.BorderSizePixel = 0
    modal.Parent = modalGui
    
    -- Add corner radius
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, tokens.borderRadius.xl)
    corner.Parent = modal
    
    -- Add shadow
    local shadow = Instance.new("Frame")
    shadow.Name = "Shadow"
    shadow.Size = UDim2.new(1, 20, 1, 20)
    shadow.Position = UDim2.new(0, 10, 0, 10)
    shadow.AnchorPoint = Vector2.new(0.5, 0.5)
    shadow.BackgroundColor3 = Color3.new(0, 0, 0)
    shadow.BackgroundTransparency = 0.7
    shadow.BorderSizePixel = 0
    shadow.ZIndex = modal.ZIndex - 1
    shadow.Parent = modalGui
    
    local shadowCorner = Instance.new("UICorner")
    shadowCorner.CornerRadius = corner.CornerRadius
    shadowCorner.Parent = shadow
    
    -- Header
    local header = Instance.new("Frame")
    header.Name = "Header"
    header.Size = UDim2.new(1, 0, 0, 60)
    header.BackgroundTransparency = 1
    header.Parent = modal
    
    local title = Instance.new("TextLabel")
    title.Name = "Title"
    title.Size = UDim2.new(1, modalConfig.showCloseButton and -60 or -20, 1, 0)
    title.Position = UDim2.new(0, 20, 0, 0)
    title.BackgroundTransparency = 1
    title.Text = modalConfig.title
    title.TextColor3 = tokens.colors.text.primary
    title.TextSize = 24
    title.Font = tokens.typography.fonts.accent
    title.TextXAlignment = Enum.TextXAlignment.Left
    title.TextYAlignment = Enum.TextYAlignment.Center
    title.Parent = header
    
    -- Close button
    if modalConfig.showCloseButton then
        local closeButton = UIComponentLibrary.createButton({
            variant = "tertiary",
            size = "small",
            text = "×",
            position = UDim2.new(1, -50, 0.5, -20),
            onClick = function()
                UIComponentLibrary.closeModal(modalGui, modalConfig.onClose)
            end
        })
        closeButton.getElement().Parent = header
    end
    
    -- Content area
    local content = Instance.new("ScrollingFrame")
    content.Name = "Content"
    content.Size = UDim2.new(1, 0, 1, -60)
    content.Position = UDim2.new(0, 0, 0, 60)
    content.BackgroundTransparency = 1
    content.BorderSizePixel = 0
    content.ScrollBarThickness = 8
    content.ScrollBarImageColor3 = tokens.colors.gray.gray400
    content.Parent = modal
    
    -- Add content padding
    local contentPadding = Instance.new("UIPadding")
    contentPadding.PaddingLeft = UDim.new(0, 20)
    contentPadding.PaddingRight = UDim.new(0, 20)
    contentPadding.PaddingTop = UDim.new(0, 0)
    contentPadding.PaddingBottom = UDim.new(0, 20)
    contentPadding.Parent = content
    
    -- Backdrop click to close
    if modalConfig.closeOnBackdrop then
        local backdropButton = Instance.new("TextButton")
        backdropButton.Size = UDim2.new(1, 0, 1, 0)
        backdropButton.BackgroundTransparency = 1
        backdropButton.Text = ""
        backdropButton.Parent = backdrop
        
        backdropButton.MouseButton1Click:Connect(function()
            UIComponentLibrary.closeModal(modalGui, modalConfig.onClose)
        end)
    end
    
    -- Animation
    modal.Size = UDim2.new(0, 0, 0, 0)
    backdrop.BackgroundTransparency = 1
    
    local openTween = TweenService:Create(
        modal,
        TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
        {Size = sizeVariants[modalConfig.size]}
    )
    
    local backdropTween = TweenService:Create(
        backdrop,
        TweenInfo.new(0.2, Enum.EasingStyle.Quad),
        {BackgroundTransparency = 0.5}
    )
    
    openTween:Play()
    backdropTween:Play()
    
    if modalConfig.onOpen then
        pcall(modalConfig.onOpen)
    end
    
    return {
        getElement = function()
            return modalGui
        end,
        
        getContentFrame = function()
            return content
        end,
        
        setContent = function(newContent)
            -- Clear existing content
            for _, child in ipairs(content:GetChildren()) do
                if not child:IsA("UIPadding") then
                    child:Destroy()
                end
            end
            
            -- Add new content
            if newContent then
                newContent.Parent = content
            end
        end,
        
        close = function()
            UIComponentLibrary.closeModal(modalGui, modalConfig.onClose)
        end
    }
end

-- ========================================
-- LOADING SPINNER COMPONENT
-- ========================================

function UIComponentLibrary.createLoadingSpinner(config)
    config = config or {}
    
    local tokens = UIDesignTokens.getTokens()
    
    -- Create spinner container
    local spinner = Instance.new("Frame")
    spinner.Name = config.name or "LoadingSpinner"
    spinner.Size = config.size or UDim2.new(0, 40, 0, 40)
    spinner.Position = config.position or UDim2.new(0.5, -20, 0.5, -20)
    spinner.AnchorPoint = config.anchorPoint or Vector2.new(0, 0)
    spinner.BackgroundTransparency = 1
    
    if config.parent then
        spinner.Parent = config.parent
    end
    
    -- Create spinning circle
    local circle = Instance.new("ImageLabel")
    circle.Name = "Circle"
    circle.Size = UDim2.new(1, 0, 1, 0)
    circle.BackgroundTransparency = 1
    circle.Image = "rbxasset://textures/ui/GuiImagePlaceholder.png" -- Replace with actual spinner image
    circle.ImageColor3 = config.color or tokens.colors.brand.primary
    circle.Parent = spinner
    
    -- Animate rotation
    local rotationTween = TweenService:Create(
        circle,
        TweenInfo.new(1, Enum.EasingStyle.Linear, Enum.EasingDirection.In, -1),
        {Rotation = 360}
    )
    rotationTween:Play()
    
    return {
        getElement = function()
            return spinner
        end,
        
        destroy = function()
            rotationTween:Cancel()
            spinner:Destroy()
        end
    }
end

-- ========================================
-- UTILITY FUNCTIONS
-- ========================================

function UIComponentLibrary.showInputError(inputContainer, message)
    -- Remove existing error
    local existingError = inputContainer:FindFirstChild("ErrorMessage")
    if existingError then
        existingError:Destroy()
    end
    
    -- Create error message
    local errorLabel = Instance.new("TextLabel")
    errorLabel.Name = "ErrorMessage"
    errorLabel.Size = UDim2.new(1, 0, 0, 20)
    errorLabel.Position = UDim2.new(0, 0, 1, 5)
    errorLabel.BackgroundTransparency = 1
    errorLabel.Text = message or "Invalid input"
    errorLabel.TextColor3 = UIDesignTokens.getTokens("colors.semantic.error")
    errorLabel.TextSize = 12
    errorLabel.Font = UIDesignTokens.getTokens("typography.fonts.primary")
    errorLabel.TextXAlignment = Enum.TextXAlignment.Left
    errorLabel.Parent = inputContainer
    
    -- Update input field border
    local inputField = inputContainer:FindFirstChild("InputField")
    if inputField then
        local stroke = inputField:FindFirstChildOfClass("UIStroke")
        if stroke then
            stroke.Color = UIDesignTokens.getTokens("colors.semantic.error")
        end
    end
end

function UIComponentLibrary.hideInputError(inputContainer)
    local errorMessage = inputContainer:FindFirstChild("ErrorMessage")
    if errorMessage then
        errorMessage:Destroy()
    end
    
    -- Reset input field border
    local inputField = inputContainer:FindFirstChild("InputField")
    if inputField then
        local stroke = inputField:FindFirstChildOfClass("UIStroke")
        if stroke then
            stroke.Color = UIDesignTokens.getTokens("colors.gray.gray300")
        end
    end
end

function UIComponentLibrary.closeModal(modalGui, onClose)
    local modal = modalGui:FindFirstChild("Modal")
    local backdrop = modalGui:FindFirstChild("Backdrop")
    
    if modal and backdrop then
        local closeTween = TweenService:Create(
            modal,
            TweenInfo.new(0.2, Enum.EasingStyle.Back, Enum.EasingDirection.In),
            {Size = UDim2.new(0, 0, 0, 0)}
        )
        
        local backdropTween = TweenService:Create(
            backdrop,
            TweenInfo.new(0.2, Enum.EasingStyle.Quad),
            {BackgroundTransparency = 1}
        )
        
        closeTween:Play()
        backdropTween:Play()
        
        closeTween.Completed:Connect(function()
            modalGui:Destroy()
            if onClose then
                pcall(onClose)
            end
        end)
    end
end

function UIComponentLibrary.playUISound(soundType)
    -- Create or get UI sound effects
    local soundMap = {
        click = "rbxasset://sounds/ui/click1.mp3",
        hover = "rbxasset://sounds/ui/hover.mp3",
        success = "rbxasset://sounds/ui/success.mp3",
        error = "rbxasset://sounds/ui/error.mp3"
    }
    
    local soundId = soundMap[soundType]
    if soundId then
        local sound = Instance.new("Sound")
        sound.SoundId = soundId
        sound.Volume = 0.3
        sound.Parent = SoundService
        sound:Play()
        
        sound.Ended:Connect(function()
            sound:Destroy()
        end)
    end
end

print("🧩 UIComponentLibrary initialized with comprehensive component system")

return UIComponentLibrary
