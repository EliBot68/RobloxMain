-- UITouchSystem.luau
-- Touch target optimization and mobile interaction system
-- Provides enhanced touch interactions, gesture support, and accessibility compliance

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local GuiService = game:GetService("GuiService")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")

local SafeRequire = require(ReplicatedStorage.Shared.utils.SafeRequire)
local UIDesignTokens = SafeRequire.require(ReplicatedStorage.Shared.ui.UIDesignTokens)
local UIFeedbackSystem = SafeRequire.require(ReplicatedStorage.Shared.ui.UIFeedbackSystem)

local UITouchSystem = {}

-- ========================================
-- TOUCH CONFIGURATION
-- ========================================

local TOUCH_STANDARDS = {
    -- Apple Human Interface Guidelines / Material Design
    touchTargets = {
        MINIMUM = 44,        -- Minimum accessible size (Apple HIG)
        RECOMMENDED = 48,    -- Material Design minimum
        COMFORTABLE = 56,    -- Comfortable interaction size
        LARGE = 64,         -- Large touch targets
        EXTRA_LARGE = 72    -- Extra large for accessibility
    },
    
    -- Touch feedback timing
    feedback = {
        PRESS_DURATION = 50,     -- Visual press feedback duration
        HOLD_THRESHOLD = 500,    -- Long press threshold
        TAP_THRESHOLD = 200,     -- Maximum tap duration
        DOUBLE_TAP_WINDOW = 300, -- Double tap detection window
        SWIPE_THRESHOLD = 50,    -- Minimum swipe distance
        HAPTIC_INTENSITY = 0.6   -- Haptic feedback intensity
    },
    
    -- Touch spacing and padding
    spacing = {
        MINIMUM_BETWEEN_TARGETS = 8,  -- Minimum space between touch targets
        EDGE_PADDING = 16,           -- Padding from screen edges
        SAFE_AREA_PADDING = 20       -- Additional padding for safe areas
    },
    
    -- Gesture recognition
    gestures = {
        SWIPE_VELOCITY_THRESHOLD = 100,    -- Minimum swipe velocity
        PINCH_THRESHOLD = 20,              -- Minimum pinch distance change
        ROTATION_THRESHOLD = 15            -- Minimum rotation angle (degrees)
    }
}

local TOUCH_EVENTS = {
    TAP = "tap",
    DOUBLE_TAP = "doubleTap",
    LONG_PRESS = "longPress",
    SWIPE_UP = "swipeUp",
    SWIPE_DOWN = "swipeDown",
    SWIPE_LEFT = "swipeLeft",
    SWIPE_RIGHT = "swipeRight",
    PINCH_IN = "pinchIn",
    PINCH_OUT = "pinchOut",
    ROTATE = "rotate",
    HOVER_START = "hoverStart",
    HOVER_END = "hoverEnd"
}

-- ========================================
-- TOUCH MANAGER
-- ========================================

local TouchManager = {
    -- Device capabilities
    touchEnabled = false,
    mouseEnabled = false,
    gamepadEnabled = false,
    
    -- Touch tracking
    activeTouches = {},
    touchTargets = {},
    gestureRecognizers = {},
    
    -- State management
    lastTapTime = 0,
    lastTapPosition = Vector2.new(0, 0),
    longPressTimers = {},
    
    -- Settings
    hapticEnabled = true,
    visualFeedbackEnabled = true,
    soundFeedbackEnabled = true,
    
    -- Platform specific
    platformScale = 1,
    safeAreaInsets = {top = 0, bottom = 0, left = 0, right = 0}
}

function UITouchSystem.initialize()
    -- Detect device capabilities
    UITouchSystem.detectDeviceCapabilities()
    
    -- Set up touch input handling
    UITouchSystem.setupTouchHandling()
    
    -- Initialize gesture recognition
    UITouchSystem.initializeGestureRecognition()
    
    -- Set up safe area detection
    UITouchSystem.setupSafeAreaDetection()
    
    -- Load user preferences
    UITouchSystem.loadTouchPreferences()
    
    print("👆 UITouchSystem initialized with enhanced touch interactions")
end

function UITouchSystem.detectDeviceCapabilities()
    TouchManager.touchEnabled = UserInputService.TouchEnabled
    TouchManager.mouseEnabled = UserInputService.MouseEnabled
    TouchManager.gamepadEnabled = UserInputService.GamepadEnabled
    
    -- Determine platform scaling
    if TouchManager.touchEnabled then
        -- Mobile device
        local screenSize = workspace.CurrentCamera.ViewportSize
        local diagonal = math.sqrt(screenSize.X^2 + screenSize.Y^2)
        
        -- Adjust scaling based on screen diagonal
        if diagonal < 1000 then
            TouchManager.platformScale = 1.2  -- Small phones
        elseif diagonal > 1500 then
            TouchManager.platformScale = 0.9  -- Large tablets
        else
            TouchManager.platformScale = 1.0  -- Standard
        end
    else
        TouchManager.platformScale = 1.0
    end
    
    print(string.format("📱 Device: Touch=%s, Mouse=%s, Gamepad=%s, Scale=%.1f", 
        tostring(TouchManager.touchEnabled),
        tostring(TouchManager.mouseEnabled), 
        tostring(TouchManager.gamepadEnabled),
        TouchManager.platformScale
    ))
end

-- ========================================
-- TOUCH TARGET REGISTRATION
-- ========================================

function UITouchSystem.registerTouchTarget(element, config)
    config = config or {}
    
    if not element then
        warn("Cannot register nil element as touch target")
        return nil
    end
    
    local targetConfig = {
        element = element,
        id = config.id or UITouchSystem.generateId(),
        
        -- Size requirements
        minimumSize = config.minimumSize or TOUCH_STANDARDS.touchTargets.MINIMUM,
        preferredSize = config.preferredSize or TOUCH_STANDARDS.touchTargets.RECOMMENDED,
        
        -- Touch events
        onTap = config.onTap,
        onDoubleTap = config.onDoubleTap,
        onLongPress = config.onLongPress,
        onSwipe = config.onSwipe,
        onHover = config.onHover,
        
        -- Feedback options
        hapticFeedback = config.hapticFeedback ~= false,
        visualFeedback = config.visualFeedback ~= false,
        soundFeedback = config.soundFeedback ~= false,
        
        -- Touch behavior
        allowMultipleTouch = config.allowMultipleTouch or false,
        preventScrolling = config.preventScrolling or false,
        
        -- Accessibility
        accessibilityHint = config.accessibilityHint,
        
        -- State
        disabled = config.disabled or false,
        lastTouchTime = 0,
        isPressed = false,
        touchStartPosition = Vector2.new(0, 0)
    }
    
    -- Validate and optimize touch target size
    UITouchSystem.optimizeTouchTargetSize(element, targetConfig)
    
    -- Add touch event handling
    UITouchSystem.setupElementTouchHandling(element, targetConfig)
    
    -- Store target
    TouchManager.touchTargets[targetConfig.id] = targetConfig
    
    return {
        id = targetConfig.id,
        setEnabled = function(enabled)
            targetConfig.disabled = not enabled
        end,
        updateConfig = function(newConfig)
            for key, value in pairs(newConfig) do
                targetConfig[key] = value
            end
        end,
        destroy = function()
            UITouchSystem.unregisterTouchTarget(targetConfig.id)
        end
    }
end

function UITouchSystem.optimizeTouchTargetSize(element, config)
    local currentSize = element.AbsoluteSize
    local tokens = UIDesignTokens.getTokens()
    
    -- Calculate required size with platform scaling
    local requiredSize = config.minimumSize * TouchManager.platformScale
    
    -- Check if current size meets requirements
    local needsResize = currentSize.X < requiredSize or currentSize.Y < requiredSize
    
    if needsResize then
        -- Calculate optimal size
        local optimalWidth = math.max(currentSize.X, requiredSize)
        local optimalHeight = math.max(currentSize.Y, requiredSize)
        
        -- Apply size constraints
        if element.Size.X.Scale == 0 then
            element.Size = UDim2.new(0, optimalWidth, element.Size.Y.Scale, optimalHeight)
        end
        
        -- Add invisible touch area if needed
        UITouchSystem.addInvisibleTouchArea(element, optimalWidth, optimalHeight)
        
        -- Log optimization
        print(string.format("🎯 Optimized touch target: %dx%d -> %dx%d", 
            currentSize.X, currentSize.Y, optimalWidth, optimalHeight))
    end
    
    -- Add visual indicators for development (can be disabled in production)
    if game:GetService("RunService"):IsStudio() then
        UITouchSystem.addTouchTargetIndicators(element, config)
    end
end

function UITouchSystem.addInvisibleTouchArea(element, requiredWidth, requiredHeight)
    -- Create invisible overlay to expand touch area
    local touchArea = Instance.new("Frame")
    touchArea.Name = "TouchArea"
    touchArea.Size = UDim2.new(0, requiredWidth, 0, requiredHeight)
    touchArea.Position = UDim2.new(0.5, -requiredWidth/2, 0.5, -requiredHeight/2)
    touchArea.AnchorPoint = Vector2.new(0.5, 0.5)
    touchArea.BackgroundTransparency = 1
    touchArea.ZIndex = element.ZIndex + 1
    touchArea.Parent = element
    
    -- Forward touch events to original element
    touchArea.InputBegan:Connect(function(input)
        element:GetPropertyChangedSignal("InputBegan"):Fire(input)
    end)
    
    touchArea.InputEnded:Connect(function(input)
        element:GetPropertyChangedSignal("InputEnded"):Fire(input)
    end)
    
    return touchArea
end

function UITouchSystem.addTouchTargetIndicators(element, config)
    -- Visual indicator for development
    local indicator = Instance.new("Frame")
    indicator.Name = "TouchTargetIndicator"
    indicator.Size = UDim2.new(1, 0, 1, 0)
    indicator.Position = UDim2.new(0, 0, 0, 0)
    indicator.BackgroundColor3 = Color3.fromRGB(0, 255, 0)
    indicator.BackgroundTransparency = 0.8
    indicator.BorderSizePixel = 1
    indicator.BorderColor3 = Color3.fromRGB(0, 200, 0)
    indicator.ZIndex = element.ZIndex - 1
    indicator.Parent = element
    
    -- Size label
    local sizeLabel = Instance.new("TextLabel")
    sizeLabel.Size = UDim2.new(1, 0, 1, 0)
    sizeLabel.BackgroundTransparency = 1
    sizeLabel.Text = string.format("%dx%d", element.AbsoluteSize.X, element.AbsoluteSize.Y)
    sizeLabel.TextColor3 = Color3.fromRGB(0, 150, 0)
    sizeLabel.TextSize = 10
    sizeLabel.Font = Enum.Font.SourceSans
    sizeLabel.TextStrokeTransparency = 0
    sizeLabel.TextStrokeColor3 = Color3.new(1, 1, 1)
    sizeLabel.Parent = indicator
end

-- ========================================
-- TOUCH EVENT HANDLING
-- ========================================

function UITouchSystem.setupTouchHandling()
    -- Touch input events
    UserInputService.TouchStarted:Connect(function(touch, gameProcessed)
        if gameProcessed then return end
        UITouchSystem.handleTouchStart(touch)
    end)
    
    UserInputService.TouchMoved:Connect(function(touch, gameProcessed)
        if gameProcessed then return end
        UITouchSystem.handleTouchMove(touch)
    end)
    
    UserInputService.TouchEnded:Connect(function(touch, gameProcessed)
        if gameProcessed then return end
        UITouchSystem.handleTouchEnd(touch)
    end)
    
    -- Mouse events for desktop testing
    if TouchManager.mouseEnabled then
        UserInputService.InputBegan:Connect(function(input, gameProcessed)
            if gameProcessed then return end
            
            if input.UserInputType == Enum.UserInputType.MouseButton1 then
                UITouchSystem.handleMouseStart(input)
            end
        end)
        
        UserInputService.InputEnded:Connect(function(input, gameProcessed)
            if gameProcessed then return end
            
            if input.UserInputType == Enum.UserInputType.MouseButton1 then
                UITouchSystem.handleMouseEnd(input)
            end
        end)
    end
end

function UITouchSystem.setupElementTouchHandling(element, config)
    -- Store element reference
    element:SetAttribute("TouchTargetId", config.id)
    
    -- Handle input events
    element.InputBegan:Connect(function(input)
        if config.disabled then return end
        
        if input.UserInputType == Enum.UserInputType.Touch or 
           input.UserInputType == Enum.UserInputType.MouseButton1 then
            UITouchSystem.handleElementTouchStart(element, config, input)
        end
    end)
    
    element.InputEnded:Connect(function(input)
        if config.disabled then return end
        
        if input.UserInputType == Enum.UserInputType.Touch or 
           input.UserInputType == Enum.UserInputType.MouseButton1 then
            UITouchSystem.handleElementTouchEnd(element, config, input)
        end
    end)
    
    -- Mouse hover for desktop
    if TouchManager.mouseEnabled then
        element.MouseEnter:Connect(function()
            if config.disabled then return end
            UITouchSystem.handleElementHoverStart(element, config)
        end)
        
        element.MouseLeave:Connect(function()
            if config.disabled then return end
            UITouchSystem.handleElementHoverEnd(element, config)
        end)
    end
end

function UITouchSystem.handleElementTouchStart(element, config, input)
    config.isPressed = true
    config.touchStartPosition = input.Position
    config.lastTouchTime = tick()
    
    -- Visual feedback
    if config.visualFeedback and TouchManager.visualFeedbackEnabled then
        UITouchSystem.showTouchFeedback(element, "press")
    end
    
    -- Haptic feedback
    if config.hapticFeedback and TouchManager.hapticEnabled then
        UITouchSystem.playHapticFeedback("light")
    end
    
    -- Start long press timer
    if config.onLongPress then
        config.longPressTimer = task.delay(TOUCH_STANDARDS.feedback.HOLD_THRESHOLD / 1000, function()
            if config.isPressed then
                UITouchSystem.handleElementLongPress(element, config)
            end
        end)
    end
end

function UITouchSystem.handleElementTouchEnd(element, config, input)
    if not config.isPressed then return end
    
    config.isPressed = false
    local touchDuration = (tick() - config.lastTouchTime) * 1000
    local touchDistance = (input.Position - config.touchStartPosition).Magnitude
    
    -- Cancel long press timer
    if config.longPressTimer then
        task.cancel(config.longPressTimer)
        config.longPressTimer = nil
    end
    
    -- Visual feedback
    if config.visualFeedback and TouchManager.visualFeedbackEnabled then
        UITouchSystem.showTouchFeedback(element, "release")
    end
    
    -- Determine touch event type
    if touchDuration < TOUCH_STANDARDS.feedback.TAP_THRESHOLD and 
       touchDistance < TOUCH_STANDARDS.feedback.SWIPE_THRESHOLD then
        
        -- Check for double tap
        local currentTime = tick()
        if currentTime - TouchManager.lastTapTime < TOUCH_STANDARDS.feedback.DOUBLE_TAP_WINDOW / 1000 and
           (input.Position - TouchManager.lastTapPosition).Magnitude < 50 then
            
            UITouchSystem.handleElementDoubleTap(element, config)
        else
            UITouchSystem.handleElementTap(element, config)
        end
        
        TouchManager.lastTapTime = currentTime
        TouchManager.lastTapPosition = input.Position
        
    elseif touchDistance >= TOUCH_STANDARDS.feedback.SWIPE_THRESHOLD then
        -- Handle swipe
        UITouchSystem.handleElementSwipe(element, config, input.Position - config.touchStartPosition)
    end
end

function UITouchSystem.handleElementTap(element, config)
    -- Sound feedback
    if config.soundFeedback and TouchManager.soundFeedbackEnabled then
        UIFeedbackSystem.playFeedbackSound("tap")
    end
    
    -- Call tap callback
    if config.onTap then
        pcall(config.onTap, element)
    end
    
    -- Trigger button click for GUI buttons
    if element:IsA("GuiButton") then
        pcall(function()
            element.MouseButton1Click:Fire()
        end)
    end
end

function UITouchSystem.handleElementDoubleTap(element, config)
    -- Haptic feedback
    if config.hapticFeedback and TouchManager.hapticEnabled then
        UITouchSystem.playHapticFeedback("medium")
    end
    
    -- Call double tap callback
    if config.onDoubleTap then
        pcall(config.onDoubleTap, element)
    end
end

function UITouchSystem.handleElementLongPress(element, config)
    -- Stronger haptic feedback
    if config.hapticFeedback and TouchManager.hapticEnabled then
        UITouchSystem.playHapticFeedback("heavy")
    end
    
    -- Visual feedback
    if config.visualFeedback and TouchManager.visualFeedbackEnabled then
        UITouchSystem.showTouchFeedback(element, "longPress")
    end
    
    -- Call long press callback
    if config.onLongPress then
        pcall(config.onLongPress, element)
    end
end

function UITouchSystem.handleElementSwipe(element, config, direction)
    local swipeVector = direction.Unit
    local swipeAngle = math.deg(math.atan2(swipeVector.Y, swipeVector.X))
    
    -- Determine swipe direction
    local swipeType
    if math.abs(swipeAngle) < 45 then
        swipeType = TOUCH_EVENTS.SWIPE_RIGHT
    elseif math.abs(swipeAngle) > 135 then
        swipeType = TOUCH_EVENTS.SWIPE_LEFT
    elseif swipeAngle > 45 and swipeAngle < 135 then
        swipeType = TOUCH_EVENTS.SWIPE_DOWN
    else
        swipeType = TOUCH_EVENTS.SWIPE_UP
    end
    
    -- Call swipe callback
    if config.onSwipe then
        pcall(config.onSwipe, element, swipeType, direction)
    end
end

function UITouchSystem.handleElementHoverStart(element, config)
    if config.onHover then
        pcall(config.onHover, element, TOUCH_EVENTS.HOVER_START)
    end
end

function UITouchSystem.handleElementHoverEnd(element, config)
    if config.onHover then
        pcall(config.onHover, element, TOUCH_EVENTS.HOVER_END)
    end
end

-- ========================================
-- VISUAL FEEDBACK
-- ========================================

function UITouchSystem.showTouchFeedback(element, feedbackType)
    if feedbackType == "press" then
        -- Scale down slightly
        local scaleTween = TweenService:Create(
            element,
            TweenInfo.new(TOUCH_STANDARDS.feedback.PRESS_DURATION / 1000, Enum.EasingStyle.Quad),
            {Size = element.Size * 0.95}
        )
        scaleTween:Play()
        
        -- Darken background
        if element.BackgroundTransparency < 1 then
            local originalColor = element.BackgroundColor3
            element:SetAttribute("OriginalBackgroundColor", originalColor)
            
            local darkerColor = Color3.new(
                originalColor.R * 0.8,
                originalColor.G * 0.8,
                originalColor.B * 0.8
            )
            
            local colorTween = TweenService:Create(
                element,
                TweenInfo.new(TOUCH_STANDARDS.feedback.PRESS_DURATION / 1000),
                {BackgroundColor3 = darkerColor}
            )
            colorTween:Play()
        end
        
    elseif feedbackType == "release" then
        -- Restore original size
        local originalSize = element:GetAttribute("OriginalSize") or element.Size / 0.95
        local scaleTween = TweenService:Create(
            element,
            TweenInfo.new(TOUCH_STANDARDS.feedback.PRESS_DURATION / 1000, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
            {Size = originalSize}
        )
        scaleTween:Play()
        
        -- Restore original color
        local originalColor = element:GetAttribute("OriginalBackgroundColor")
        if originalColor then
            local colorTween = TweenService:Create(
                element,
                TweenInfo.new(TOUCH_STANDARDS.feedback.PRESS_DURATION / 1000),
                {BackgroundColor3 = originalColor}
            )
            colorTween:Play()
        end
        
    elseif feedbackType == "longPress" then
        -- Ripple effect
        UITouchSystem.createRippleEffect(element)
    end
end

function UITouchSystem.createRippleEffect(element)
    local ripple = Instance.new("Frame")
    ripple.Name = "RippleEffect"
    ripple.Size = UDim2.new(0, 0, 0, 0)
    ripple.Position = UDim2.new(0.5, 0, 0.5, 0)
    ripple.AnchorPoint = Vector2.new(0.5, 0.5)
    ripple.BackgroundColor3 = Color3.new(1, 1, 1)
    ripple.BackgroundTransparency = 0.7
    ripple.BorderSizePixel = 0
    ripple.ZIndex = element.ZIndex + 1
    ripple.Parent = element
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0.5, 0)
    corner.Parent = ripple
    
    -- Animate ripple
    local maxSize = math.max(element.AbsoluteSize.X, element.AbsoluteSize.Y) * 2
    
    local expandTween = TweenService:Create(
        ripple,
        TweenInfo.new(0.6, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
        {
            Size = UDim2.new(0, maxSize, 0, maxSize),
            BackgroundTransparency = 1
        }
    )
    
    expandTween:Play()
    expandTween.Completed:Connect(function()
        ripple:Destroy()
    end)
end

-- ========================================
-- HAPTIC FEEDBACK
-- ========================================

function UITouchSystem.playHapticFeedback(intensity)
    if not TouchManager.hapticEnabled or not TouchManager.touchEnabled then
        return
    end
    
    pcall(function()
        local hapticType
        if intensity == "light" then
            hapticType = Enum.HapticFeedbackType.ImpactLight
        elseif intensity == "medium" then
            hapticType = Enum.HapticFeedbackType.ImpactMedium
        elseif intensity == "heavy" then
            hapticType = Enum.HapticFeedbackType.ImpactHeavy
        else
            hapticType = Enum.HapticFeedbackType.ImpactMedium
        end
        
        UserInputService:GetPlatformService():PerformHapticFeedback(hapticType)
    end)
end

-- ========================================
-- GESTURE RECOGNITION
-- ========================================

function UITouchSystem.initializeGestureRecognition()
    -- Multi-touch gesture recognition would be implemented here
    -- For now, basic single-touch gestures are handled in element touch handling
    print("🤲 Gesture recognition initialized")
end

-- ========================================
-- SAFE AREA DETECTION
-- ========================================

function UITouchSystem.setupSafeAreaDetection()
    -- Detect safe area insets for notched devices
    pcall(function()
        local guiInsets = GuiService:GetGuiInset()
        TouchManager.safeAreaInsets = {
            top = guiInsets.Y,
            bottom = 0,  -- Bottom insets would need platform-specific detection
            left = 0,
            right = 0
        }
    end)
    
    -- Monitor viewport changes
    workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(function()
        UITouchSystem.updateSafeAreas()
    end)
end

function UITouchSystem.updateSafeAreas()
    -- Update safe area calculations when viewport changes
    pcall(function()
        local guiInsets = GuiService:GetGuiInset()
        TouchManager.safeAreaInsets.top = guiInsets.Y
        
        -- Notify registered touch targets about safe area changes
        for _, target in pairs(TouchManager.touchTargets) do
            UITouchSystem.updateTouchTargetForSafeArea(target)
        end
    end)
end

function UITouchSystem.updateTouchTargetForSafeArea(targetConfig)
    local element = targetConfig.element
    if not element or not element.Parent then return end
    
    -- Adjust positioning for safe areas if element is near screen edges
    local absolutePos = element.AbsolutePosition
    local viewportSize = workspace.CurrentCamera.ViewportSize
    
    local adjustments = {}
    
    -- Check if near top edge
    if absolutePos.Y < TOUCH_STANDARDS.spacing.SAFE_AREA_PADDING + TouchManager.safeAreaInsets.top then
        adjustments.top = true
    end
    
    -- Check if near bottom edge
    if absolutePos.Y + element.AbsoluteSize.Y > viewportSize.Y - TOUCH_STANDARDS.spacing.SAFE_AREA_PADDING then
        adjustments.bottom = true
    end
    
    -- Apply adjustments if needed
    if next(adjustments) then
        UITouchSystem.applySafeAreaAdjustments(element, adjustments)
    end
end

function UITouchSystem.applySafeAreaAdjustments(element, adjustments)
    -- Apply safe area padding adjustments
    if adjustments.top then
        local currentY = element.Position.Y
        element.Position = UDim2.new(
            currentY.Scale,
            currentY.Offset,
            currentY.Scale,
            math.max(currentY.Offset, TouchManager.safeAreaInsets.top + TOUCH_STANDARDS.spacing.SAFE_AREA_PADDING)
        )
    end
end

-- ========================================
-- ACCESSIBILITY INTEGRATION
-- ========================================

function UITouchSystem.enhanceElementAccessibility(element, config)
    -- Add accessibility attributes
    element:SetAttribute("TouchTargetOptimized", true)
    element:SetAttribute("MinimumTouchSize", config.minimumSize)
    
    if config.accessibilityHint then
        element:SetAttribute("AccessibilityHint", config.accessibilityHint)
    end
    
    -- Integrate with accessibility system if available
    pcall(function()
        local UIAccessibilitySystem = require(ReplicatedStorage.Shared.ui.UIAccessibilitySystem)
        UIAccessibilitySystem.registerFocusableElement(element, {
            ariaLabel = config.accessibilityHint,
            role = "button"
        })
    end)
end

-- ========================================
-- UTILITY FUNCTIONS
-- ========================================

function UITouchSystem.loadTouchPreferences()
    -- Load user touch preferences
    pcall(function()
        local player = game.Players.LocalPlayer
        TouchManager.hapticEnabled = player:GetAttribute("HapticFeedbackEnabled") ~= false
        TouchManager.visualFeedbackEnabled = player:GetAttribute("VisualFeedbackEnabled") ~= false
        TouchManager.soundFeedbackEnabled = player:GetAttribute("SoundFeedbackEnabled") ~= false
    end)
end

function UITouchSystem.saveTouchPreferences()
    pcall(function()
        local player = game.Players.LocalPlayer
        player:SetAttribute("HapticFeedbackEnabled", TouchManager.hapticEnabled)
        player:SetAttribute("VisualFeedbackEnabled", TouchManager.visualFeedbackEnabled)
        player:SetAttribute("SoundFeedbackEnabled", TouchManager.soundFeedbackEnabled)
    end)
end

function UITouchSystem.generateId()
    return "touch_" .. tick() .. "_" .. math.random(1000, 9999)
end

function UITouchSystem.unregisterTouchTarget(targetId)
    TouchManager.touchTargets[targetId] = nil
end

-- Global touch handlers (to be implemented)
function UITouchSystem.handleTouchStart(touch) end
function UITouchSystem.handleTouchMove(touch) end
function UITouchSystem.handleTouchEnd(touch) end
function UITouchSystem.handleMouseStart(input) end
function UITouchSystem.handleMouseEnd(input) end

-- ========================================
-- PUBLIC API
-- ========================================

function UITouchSystem.optimizeButton(button, config)
    config = config or {}
    config.onTap = config.onTap or function()
        if button:IsA("GuiButton") then
            button.MouseButton1Click:Fire()
        end
    end
    
    return UITouchSystem.registerTouchTarget(button, config)
end

function UITouchSystem.getDeviceInfo()
    return {
        touchEnabled = TouchManager.touchEnabled,
        mouseEnabled = TouchManager.mouseEnabled,
        gamepadEnabled = TouchManager.gamepadEnabled,
        platformScale = TouchManager.platformScale,
        safeAreaInsets = TouchManager.safeAreaInsets
    }
end

function UITouchSystem.setHapticEnabled(enabled)
    TouchManager.hapticEnabled = enabled
    UITouchSystem.saveTouchPreferences()
end

function UITouchSystem.setVisualFeedbackEnabled(enabled)
    TouchManager.visualFeedbackEnabled = enabled
    UITouchSystem.saveTouchPreferences()
end

function UITouchSystem.setSoundFeedbackEnabled(enabled)
    TouchManager.soundFeedbackEnabled = enabled
    UITouchSystem.saveTouchPreferences()
end

-- Export touch events and standards
UITouchSystem.TOUCH_EVENTS = TOUCH_EVENTS
UITouchSystem.TOUCH_STANDARDS = TOUCH_STANDARDS

-- Initialize the touch system
UITouchSystem.initialize()

print("👆 UITouchSystem initialized with optimized touch interactions")

return UITouchSystem
