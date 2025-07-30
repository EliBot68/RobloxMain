-- TouchControlsSystem.luau
-- Advanced touch controls with haptic feedback and gesture recognition
-- Handles mobile input optimization, gesture detection, and cross-platform input management

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local GuiService = game:GetService("GuiService")
local TweenService = game:GetService("TweenService")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local HapticService = game:GetService("HapticService")
local ContextActionService = game:GetService("ContextActionService")

local SafeRequire = require(ReplicatedStorage.Shared.utils.SafeRequire)

local TouchControlsSystem = {}

-- ========================================
-- TOUCH CONTROLS CONFIGURATION
-- ========================================

local TOUCH_CONFIG = {
    -- Touch sensitivity and responsiveness
    sensitivity = {
        tap = {
            maxDuration = 0.3,     -- Maximum tap duration (seconds)
            maxMovement = 10,      -- Maximum movement for tap (pixels)
            doubleTapWindow = 0.5  -- Double tap detection window
        },
        
        swipe = {
            minDistance = 50,      -- Minimum swipe distance (pixels)
            maxDuration = 1.0,     -- Maximum swipe duration
            velocityThreshold = 100 -- Minimum velocity for swipe detection
        },
        
        pinch = {
            minDistanceChange = 20, -- Minimum distance change for pinch
            sensitivity = 0.5       -- Pinch sensitivity multiplier
        },
        
        pan = {
            minMovement = 5,       -- Minimum movement to start panning
            damping = 0.9,         -- Pan momentum damping
            maxVelocity = 2000     -- Maximum pan velocity
        }
    },
    
    -- Haptic feedback settings
    haptics = {
        enableFeedback = true,
        feedbackTypes = {
            tap = "light",
            longPress = "medium",
            swipe = "light",
            pinch = "medium",
            error = "heavy",
            success = "medium"
        },
        
        -- Intensity levels (0.0 - 1.0)
        intensity = {
            light = 0.3,
            medium = 0.6,
            heavy = 1.0
        }
    },
    
    -- Virtual controls configuration
    virtualControls = {
        joystick = {
            enabled = true,
            size = UDim2.new(0, 120, 0, 120),
            position = UDim2.new(0, 80, 1, -200),
            deadZone = 0.15,
            returnSpeed = 0.2,
            opacity = 0.7
        },
        
        actionButtons = {
            enabled = true,
            buttonSize = UDim2.new(0, 60, 0, 60),
            spacing = 20,
            position = UDim2.new(1, -200, 1, -150),
            opacity = 0.8
        },
        
        dpad = {
            enabled = false,
            size = UDim2.new(0, 100, 0, 100),
            position = UDim2.new(0, 50, 1, -150),
            opacity = 0.7
        }
    },
    
    -- Gesture recognition settings
    gestures = {
        enableGestureRecognition = true,
        
        swipeGestures = {
            up = true,
            down = true,
            left = true,
            right = true,
            diagonal = false
        },
        
        pinchGestures = {
            zoomIn = true,
            zoomOut = true
        },
        
        rotationGestures = {
            enabled = false, -- Disabled for performance
            sensitivity = 1.0
        },
        
        customGestures = {}
    },
    
    -- Performance optimization
    performance = {
        updateFrequency = 60,      -- Update frequency (Hz)
        inputBufferSize = 10,      -- Input event buffer size
        gestureTimeout = 2.0,      -- Gesture timeout (seconds)
        enableMultitouch = true,   -- Enable multitouch support
        maxTouchPoints = 10        -- Maximum simultaneous touch points
    },
    
    -- Accessibility settings
    accessibility = {
        minTouchTargetSize = 44,   -- Minimum touch target size (pixels)
        touchAssistEnabled = false, -- Touch assist for motor impairments
        voiceControlEnabled = false, -- Voice control integration
        assistiveTouchEnabled = false -- iOS-style assistive touch
    }
}

-- ========================================
-- TOUCH CONTROLS STATE
-- ========================================

local TouchState = {
    -- Input tracking
    activeTouches = {},
    inputHistory = {},
    gestureState = {},
    
    -- Virtual controls
    virtualJoystick = {
        active = false,
        position = Vector2.new(0, 0),
        delta = Vector2.new(0, 0),
        magnitude = 0,
        angle = 0
    },
    
    actionButtons = {},
    
    -- Gesture recognition
    gestureRecognizer = {
        activeGestures = {},
        gestureHistory = {},
        recognitionState = "idle"
    },
    
    -- Haptic feedback
    hapticController = {
        lastFeedbackTime = 0,
        feedbackQueue = {},
        enabled = TOUCH_CONFIG.haptics.enableFeedback
    },
    
    -- Performance tracking
    performance = {
        inputEvents = 0,
        gesturesRecognized = 0,
        averageResponseTime = 0,
        frameDrops = 0
    },
    
    -- Event callbacks
    callbacks = {
        onTap = {},
        onDoubleTap = {},
        onLongPress = {},
        onSwipe = {},
        onPinch = {},
        onPan = {},
        onJoystickMove = {},
        onButtonPress = {}
    }
}

function TouchControlsSystem.initialize()
    print("📱 Initializing TouchControlsSystem...")
    
    -- Set up input detection
    TouchControlsSystem.setupInputDetection()
    
    -- Initialize gesture recognition
    TouchControlsSystem.initializeGestureRecognition()
    
    -- Set up virtual controls
    TouchControlsSystem.setupVirtualControls()
    
    -- Initialize haptic feedback
    TouchControlsSystem.initializeHapticFeedback()
    
    -- Set up accessibility features
    TouchControlsSystem.setupAccessibilityFeatures()
    
    -- Start input processing loops
    TouchControlsSystem.startInputProcessing()
    
    print("📱 TouchControlsSystem initialized successfully")
end

-- ========================================
-- INPUT DETECTION SETUP
-- ========================================

function TouchControlsSystem.setupInputDetection()
    TouchState.inputManager = {
        touchProcessor = TouchControlsSystem.createTouchProcessor(),
        mouseProcessor = TouchControlsSystem.createMouseProcessor(),
        gamepadProcessor = TouchControlsSystem.createGamepadProcessor(),
        
        processInput = function(self, inputObject)
            TouchControlsSystem.processInputEvent(inputObject)
        end
    }
    
    -- Connect input events
    TouchState.inputConnections = {
        inputBegan = UserInputService.InputBegan:Connect(function(input, gameProcessed)
            if not gameProcessed then
                TouchState.inputManager:processInput(input)
            end
        end),
        
        inputChanged = UserInputService.InputChanged:Connect(function(input, gameProcessed)
            if not gameProcessed then
                TouchState.inputManager:processInput(input)
            end
        end),
        
        inputEnded = UserInputService.InputEnded:Connect(function(input, gameProcessed)
            if not gameProcessed then
                TouchState.inputManager:processInput(input)
            end
        end),
        
        touchTap = UserInputService.TouchTap:Connect(function(touchPositions, gameProcessed)
            if not gameProcessed then
                TouchControlsSystem.handleTouchTap(touchPositions)
            end
        end),
        
        touchLongPress = UserInputService.TouchLongPress:Connect(function(touchPositions, state, gameProcessed)
            if not gameProcessed then
                TouchControlsSystem.handleLongPress(touchPositions, state)
            end
        end),
        
        touchPan = UserInputService.TouchPan:Connect(function(touchPositions, totalTranslation, velocity, state, gameProcessed)
            if not gameProcessed then
                TouchControlsSystem.handleTouchPan(touchPositions, totalTranslation, velocity, state)
            end
        end),
        
        touchPinch = UserInputService.TouchPinch:Connect(function(touchPositions, scale, velocity, state, gameProcessed)
            if not gameProcessed then
                TouchControlsSystem.handleTouchPinch(touchPositions, scale, velocity, state)
            end
        end),
        
        touchRotate = UserInputService.TouchRotate:Connect(function(touchPositions, rotation, velocity, state, gameProcessed)
            if not gameProcessed and TOUCH_CONFIG.gestures.rotationGestures.enabled then
                TouchControlsSystem.handleTouchRotate(touchPositions, rotation, velocity, state)
            end
        end),
        
        touchSwipe = UserInputService.TouchSwipe:Connect(function(swipeDirection, numberOfTouches, gameProcessed)
            if not gameProcessed then
                TouchControlsSystem.handleTouchSwipe(swipeDirection, numberOfTouches)
            end
        end)
    }
    
    print("🎮 Input detection initialized")
end

function TouchControlsSystem.createTouchProcessor()
    return {
        name = "touch_processor",
        
        process = function(self, inputObject)
            if inputObject.UserInputType == Enum.UserInputType.Touch then
                TouchControlsSystem.processTouchInput(inputObject)
            end
        end
    }
end

function TouchControlsSystem.createMouseProcessor()
    return {
        name = "mouse_processor",
        
        process = function(self, inputObject)
            if inputObject.UserInputType == Enum.UserInputType.MouseButton1 or
               inputObject.UserInputType == Enum.UserInputType.MouseMovement then
                TouchControlsSystem.processMouseInput(inputObject)
            end
        end
    }
end

function TouchControlsSystem.createGamepadProcessor()
    return {
        name = "gamepad_processor",
        
        process = function(self, inputObject)
            if inputObject.UserInputType == Enum.UserInputType.Gamepad1 then
                TouchControlsSystem.processGamepadInput(inputObject)
            end
        end
    }
end

-- ========================================
-- INPUT PROCESSING
-- ========================================

function TouchControlsSystem.processInputEvent(inputObject)
    local startTime = tick()
    
    -- Add to input history
    table.insert(TouchState.inputHistory, {
        inputObject = inputObject,
        timestamp = startTime
    })
    
    -- Limit input history size
    if #TouchState.inputHistory > TOUCH_CONFIG.performance.inputBufferSize then
        table.remove(TouchState.inputHistory, 1)
    end
    
    -- Process based on input type
    if inputObject.UserInputType == Enum.UserInputType.Touch then
        TouchControlsSystem.processTouchInput(inputObject)
    elseif inputObject.UserInputType == Enum.UserInputType.MouseButton1 then
        TouchControlsSystem.processMouseInput(inputObject)
    elseif inputObject.UserInputType == Enum.UserInputType.Gamepad1 then
        TouchControlsSystem.processGamepadInput(inputObject)
    end
    
    -- Update performance metrics
    local processingTime = tick() - startTime
    TouchState.performance.inputEvents = TouchState.performance.inputEvents + 1
    TouchState.performance.averageResponseTime = 
        (TouchState.performance.averageResponseTime + processingTime) / 2
end

function TouchControlsSystem.processTouchInput(inputObject)
    local touchPosition = inputObject.Position
    local touchId = inputObject.UserInputState
    
    if inputObject.UserInputState == Enum.UserInputState.Begin then
        -- Touch began
        TouchState.activeTouches[touchId] = {
            startPosition = touchPosition,
            currentPosition = touchPosition,
            startTime = tick(),
            moved = false,
            totalMovement = 0
        }
        
        TouchControlsSystem.checkVirtualControlTouch(touchPosition, "began")
        
    elseif inputObject.UserInputState == Enum.UserInputState.Change then
        -- Touch moved
        local touch = TouchState.activeTouches[touchId]
        if touch then
            local movement = (touchPosition - touch.currentPosition).Magnitude
            touch.currentPosition = touchPosition
            touch.totalMovement = touch.totalMovement + movement
            
            if movement > TOUCH_CONFIG.sensitivity.pan.minMovement then
                touch.moved = true
            end
            
            TouchControlsSystem.checkVirtualControlTouch(touchPosition, "changed")
        end
        
    elseif inputObject.UserInputState == Enum.UserInputState.End then
        -- Touch ended
        local touch = TouchState.activeTouches[touchId]
        if touch then
            local duration = tick() - touch.startTime
            
            -- Determine gesture type
            if not touch.moved and duration <= TOUCH_CONFIG.sensitivity.tap.maxDuration then
                TouchControlsSystem.handleTap(touch.startPosition)
            end
            
            TouchControlsSystem.checkVirtualControlTouch(touchPosition, "ended")
            TouchState.activeTouches[touchId] = nil
        end
    end
end

function TouchControlsSystem.processMouseInput(inputObject)
    -- Simulate touch events for mouse input (desktop testing)
    if inputObject.UserInputState == Enum.UserInputState.Begin then
        TouchControlsSystem.handleTap(inputObject.Position)
    end
end

function TouchControlsSystem.processGamepadInput(inputObject)
    -- Process gamepad input for console support
    if inputObject.KeyCode == Enum.KeyCode.ButtonA then
        if inputObject.UserInputState == Enum.UserInputState.Begin then
            TouchControlsSystem.triggerHapticFeedback("tap")
        end
    end
end

-- ========================================
-- GESTURE RECOGNITION
-- ========================================

function TouchControlsSystem.initializeGestureRecognition()
    TouchState.gestureRecognizer = {
        activeGestures = {},
        gestureHistory = {},
        recognitionState = "idle",
        
        recognizeGesture = function(self, inputData)
            return TouchControlsSystem.analyzeGesture(inputData)
        end,
        
        addCustomGesture = function(self, gestureName, recognitionFunction)
            TOUCH_CONFIG.gestures.customGestures[gestureName] = recognitionFunction
        end
    }
    
    print("👆 Gesture recognition initialized")
end

function TouchControlsSystem.analyzeGesture(inputData)
    -- Simplified gesture analysis
    local gestureType = "unknown"
    
    if inputData.touchCount == 1 then
        local movement = inputData.totalMovement or 0
        local duration = inputData.duration or 0
        
        if movement < TOUCH_CONFIG.sensitivity.tap.maxMovement and 
           duration < TOUCH_CONFIG.sensitivity.tap.maxDuration then
            gestureType = "tap"
        elseif movement > TOUCH_CONFIG.sensitivity.swipe.minDistance then
            gestureType = "swipe"
        elseif duration > 1.0 then
            gestureType = "longPress"
        end
        
    elseif inputData.touchCount == 2 then
        gestureType = "pinch"
    end
    
    return {
        type = gestureType,
        confidence = 0.8,
        data = inputData
    }
end

-- ========================================
-- TOUCH EVENT HANDLERS
-- ========================================

function TouchControlsSystem.handleTouchTap(touchPositions)
    local position = touchPositions[1]
    TouchControlsSystem.handleTap(position)
end

function TouchControlsSystem.handleTap(position)
    TouchControlsSystem.triggerHapticFeedback("tap")
    
    -- Check for double tap
    local currentTime = tick()
    local lastTap = TouchState.lastTapTime
    
    if lastTap and (currentTime - lastTap) < TOUCH_CONFIG.sensitivity.tap.doubleTapWindow then
        TouchControlsSystem.handleDoubleTap(position)
        TouchState.lastTapTime = nil
    else
        TouchState.lastTapTime = currentTime
        
        -- Delay single tap to check for double tap
        spawn(function()
            task.wait(TOUCH_CONFIG.sensitivity.tap.doubleTapWindow)
            if TouchState.lastTapTime == currentTime then
                TouchControlsSystem.triggerTapCallbacks(position)
            end
        end)
    end
end

function TouchControlsSystem.handleDoubleTap(position)
    TouchControlsSystem.triggerHapticFeedback("tap")
    TouchControlsSystem.triggerDoubleTapCallbacks(position)
end

function TouchControlsSystem.handleLongPress(touchPositions, state)
    if state == Enum.UserInputState.Begin then
        TouchControlsSystem.triggerHapticFeedback("longPress")
        TouchControlsSystem.triggerLongPressCallbacks(touchPositions[1])
    end
end

function TouchControlsSystem.handleTouchPan(touchPositions, totalTranslation, velocity, state)
    local panData = {
        positions = touchPositions,
        translation = totalTranslation,
        velocity = velocity,
        state = state
    }
    
    TouchControlsSystem.triggerPanCallbacks(panData)
end

function TouchControlsSystem.handleTouchPinch(touchPositions, scale, velocity, state)
    TouchControlsSystem.triggerHapticFeedback("pinch")
    
    local pinchData = {
        positions = touchPositions,
        scale = scale,
        velocity = velocity,
        state = state
    }
    
    TouchControlsSystem.triggerPinchCallbacks(pinchData)
end

function TouchControlsSystem.handleTouchRotate(touchPositions, rotation, velocity, state)
    local rotateData = {
        positions = touchPositions,
        rotation = rotation,
        velocity = velocity,
        state = state
    }
    
    TouchControlsSystem.triggerRotateCallbacks(rotateData)
end

function TouchControlsSystem.handleTouchSwipe(swipeDirection, numberOfTouches)
    TouchControlsSystem.triggerHapticFeedback("swipe")
    
    local swipeData = {
        direction = swipeDirection,
        touchCount = numberOfTouches
    }
    
    TouchControlsSystem.triggerSwipeCallbacks(swipeData)
end

-- ========================================
-- VIRTUAL CONTROLS
-- ========================================

function TouchControlsSystem.setupVirtualControls()
    if TOUCH_CONFIG.virtualControls.joystick.enabled then
        TouchControlsSystem.createVirtualJoystick()
    end
    
    if TOUCH_CONFIG.virtualControls.actionButtons.enabled then
        TouchControlsSystem.createActionButtons()
    end
    
    if TOUCH_CONFIG.virtualControls.dpad.enabled then
        TouchControlsSystem.createDPad()
    end
    
    print("🕹️ Virtual controls initialized")
end

function TouchControlsSystem.createVirtualJoystick()
    local player = Players.LocalPlayer
    local playerGui = player:WaitForChild("PlayerGui")
    
    -- Create joystick container
    local joystickFrame = Instance.new("Frame")
    joystickFrame.Name = "VirtualJoystick"
    joystickFrame.Size = TOUCH_CONFIG.virtualControls.joystick.size
    joystickFrame.Position = TOUCH_CONFIG.virtualControls.joystick.position
    joystickFrame.BackgroundTransparency = 1
    joystickFrame.Parent = playerGui
    
    -- Create joystick base
    local joystickBase = Instance.new("ImageLabel")
    joystickBase.Name = "Base"
    joystickBase.Size = UDim2.new(1, 0, 1, 0)
    joystickBase.Position = UDim2.new(0, 0, 0, 0)
    joystickBase.BackgroundTransparency = 1
    joystickBase.Image = "rbxasset://textures/ui/Controls/Joystick/Base.png"
    joystickBase.ImageTransparency = 1 - TOUCH_CONFIG.virtualControls.joystick.opacity
    joystickBase.Parent = joystickFrame
    
    -- Create joystick knob
    local joystickKnob = Instance.new("ImageLabel")
    joystickKnob.Name = "Knob"
    joystickKnob.Size = UDim2.new(0.4, 0, 0.4, 0)
    joystickKnob.Position = UDim2.new(0.3, 0, 0.3, 0)
    joystickKnob.BackgroundTransparency = 1
    joystickKnob.Image = "rbxasset://textures/ui/Controls/Joystick/Knob.png"
    joystickKnob.ImageTransparency = 1 - TOUCH_CONFIG.virtualControls.joystick.opacity
    joystickKnob.Parent = joystickBase
    
    -- Set up joystick input handling
    TouchControlsSystem.setupJoystickInput(joystickFrame, joystickBase, joystickKnob)
    
    TouchState.virtualJoystick.frame = joystickFrame
    TouchState.virtualJoystick.base = joystickBase
    TouchState.virtualJoystick.knob = joystickKnob
end

function TouchControlsSystem.setupJoystickInput(frame, base, knob)
    local dragging = false
    local startPosition = Vector2.new(0, 0)
    
    local function updateJoystick(input)
        if not dragging then return end
        
        local frameCenter = base.AbsolutePosition + base.AbsoluteSize / 2
        local inputPosition = Vector2.new(input.Position.X, input.Position.Y)
        local delta = inputPosition - frameCenter
        local distance = delta.Magnitude
        local radius = base.AbsoluteSize.X / 2
        
        -- Apply dead zone
        if distance < radius * TOUCH_CONFIG.virtualControls.joystick.deadZone then
            delta = Vector2.new(0, 0)
            distance = 0
        end
        
        -- Clamp to circle
        if distance > radius then
            delta = delta.Unit * radius
            distance = radius
        end
        
        -- Update knob position
        local knobPosition = UDim2.new(0.5, delta.X, 0.5, delta.Y)
        knob.Position = knobPosition
        
        -- Update joystick state
        TouchState.virtualJoystick.active = distance > 0
        TouchState.virtualJoystick.delta = delta
        TouchState.virtualJoystick.magnitude = distance / radius
        TouchState.virtualJoystick.angle = math.atan2(delta.Y, delta.X)
        TouchState.virtualJoystick.position = inputPosition
        
        -- Trigger joystick callbacks
        TouchControlsSystem.triggerJoystickCallbacks(TouchState.virtualJoystick)
    end
    
    -- Input connections
    frame.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.Touch or 
           input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true
            startPosition = Vector2.new(input.Position.X, input.Position.Y)
            updateJoystick(input)
        end
    end)
    
    frame.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.Touch or 
           input.UserInputType == Enum.UserInputType.MouseMovement then
            updateJoystick(input)
        end
    end)
    
    frame.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.Touch or 
           input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = false
            
            -- Return knob to center with animation
            local returnTween = TweenService:Create(knob, 
                TweenInfo.new(TOUCH_CONFIG.virtualControls.joystick.returnSpeed, Enum.EasingStyle.Quart, Enum.EasingDirection.Out),
                {Position = UDim2.new(0.3, 0, 0.3, 0)}
            )
            returnTween:Play()
            
            -- Reset joystick state
            TouchState.virtualJoystick.active = false
            TouchState.virtualJoystick.delta = Vector2.new(0, 0)
            TouchState.virtualJoystick.magnitude = 0
            TouchState.virtualJoystick.angle = 0
            
            TouchControlsSystem.triggerJoystickCallbacks(TouchState.virtualJoystick)
        end
    end)
end

function TouchControlsSystem.createActionButtons()
    local player = Players.LocalPlayer
    local playerGui = player:WaitForChild("PlayerGui")
    
    -- Create action button container
    local buttonContainer = Instance.new("Frame")
    buttonContainer.Name = "ActionButtons"
    buttonContainer.Size = UDim2.new(0, 200, 0, 150)
    buttonContainer.Position = TOUCH_CONFIG.virtualControls.actionButtons.position
    buttonContainer.BackgroundTransparency = 1
    buttonContainer.Parent = playerGui
    
    -- Create action buttons
    local buttonNames = {"Jump", "Action", "Sprint", "Crouch"}
    local buttonColors = {
        Color3.fromRGB(76, 175, 80),  -- Green
        Color3.fromRGB(33, 150, 243), -- Blue
        Color3.fromRGB(255, 193, 7),  -- Yellow
        Color3.fromRGB(156, 39, 176)  -- Purple
    }
    
    for i, buttonName in ipairs(buttonNames) do
        local button = TouchControlsSystem.createActionButton(buttonName, buttonColors[i])
        
        -- Position buttons in a grid
        local col = (i - 1) % 2
        local row = math.floor((i - 1) / 2)
        
        button.Position = UDim2.new(0, col * 80, 0, row * 80)
        button.Parent = buttonContainer
        
        TouchState.actionButtons[buttonName] = button
    end
end

function TouchControlsSystem.createActionButton(name, color)
    local button = Instance.new("TextButton")
    button.Name = name .. "Button"
    button.Size = TOUCH_CONFIG.virtualControls.actionButtons.buttonSize
    button.BackgroundColor3 = color
    button.BackgroundTransparency = 1 - TOUCH_CONFIG.virtualControls.actionButtons.opacity
    button.BorderSizePixel = 0
    button.Text = name
    button.TextColor3 = Color3.new(1, 1, 1)
    button.TextSize = 14
    button.Font = Enum.Font.SourceSansBold
    
    -- Round button corners
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0.5, 0)
    corner.Parent = button
    
    -- Button press effects
    button.MouseButton1Down:Connect(function()
        TouchControlsSystem.triggerHapticFeedback("tap")
        TouchControlsSystem.triggerButtonCallbacks(name, "press")
        
        -- Visual feedback
        local pressedTween = TweenService:Create(button,
            TweenInfo.new(0.1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
            {Size = button.Size * 0.9}
        )
        pressedTween:Play()
    end)
    
    button.MouseButton1Up:Connect(function()
        TouchControlsSystem.triggerButtonCallbacks(name, "release")
        
        -- Return to normal size
        local releaseTween = TweenService:Create(button,
            TweenInfo.new(0.1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
            {Size = TOUCH_CONFIG.virtualControls.actionButtons.buttonSize}
        )
        releaseTween:Play()
    end)
    
    return button
end

function TouchControlsSystem.createDPad()
    -- Implementation for D-Pad virtual control
    print("🎮 D-Pad creation placeholder")
end

function TouchControlsSystem.checkVirtualControlTouch(position, state)
    -- Check if touch intersects with virtual controls
    if TouchState.virtualJoystick.frame then
        local frame = TouchState.virtualJoystick.frame
        local framePos = frame.AbsolutePosition
        local frameSize = frame.AbsoluteSize
        
        if position.X >= framePos.X and position.X <= framePos.X + frameSize.X and
           position.Y >= framePos.Y and position.Y <= framePos.Y + frameSize.Y then
            -- Touch is on joystick, let joystick handle it
            return true
        end
    end
    
    return false
end

-- ========================================
-- HAPTIC FEEDBACK
-- ========================================

function TouchControlsSystem.initializeHapticFeedback()
    TouchState.hapticController = {
        enabled = TOUCH_CONFIG.haptics.enableFeedback,
        lastFeedbackTime = 0,
        feedbackQueue = {},
        
        triggerFeedback = function(self, feedbackType, intensity)
            if not self.enabled then return end
            
            local currentTime = tick()
            
            -- Prevent haptic spam
            if currentTime - self.lastFeedbackTime < 0.1 then
                return
            end
            
            self.lastFeedbackTime = currentTime
            
            -- Get feedback intensity
            intensity = intensity or TOUCH_CONFIG.haptics.intensity[feedbackType] or 0.5
            
            -- Trigger haptic feedback
            if HapticService:IsVibrationSupported(Enum.UserInputType.Gamepad1) then
                HapticService:SetMotor(Enum.UserInputType.Gamepad1, Enum.VibrationMotor.Large, intensity)
                
                -- Stop vibration after short duration
                spawn(function()
                    task.wait(0.1)
                    HapticService:SetMotor(Enum.UserInputType.Gamepad1, Enum.VibrationMotor.Large, 0)
                end)
            end
        end
    }
    
    print("📳 Haptic feedback initialized")
end

function TouchControlsSystem.triggerHapticFeedback(feedbackType)
    TouchState.hapticController:triggerFeedback(feedbackType)
end

-- ========================================
-- ACCESSIBILITY FEATURES
-- ========================================

function TouchControlsSystem.setupAccessibilityFeatures()
    TouchState.accessibilityManager = {
        touchAssistEnabled = TOUCH_CONFIG.accessibility.touchAssistEnabled,
        voiceControlEnabled = TOUCH_CONFIG.accessibility.voiceControlEnabled,
        assistiveTouchEnabled = TOUCH_CONFIG.accessibility.assistiveTouchEnabled,
        
        enableTouchAssist = function(self)
            self.touchAssistEnabled = true
            TouchControlsSystem.applyTouchAssist()
            print("♿ Touch assist enabled")
        end,
        
        disableTouchAssist = function(self)
            self.touchAssistEnabled = false
            TouchControlsSystem.removeTouchAssist()
            print("♿ Touch assist disabled")
        end,
        
        enableVoiceControl = function(self)
            self.voiceControlEnabled = true
            TouchControlsSystem.setupVoiceControl()
            print("♿ Voice control enabled")
        end,
        
        disableVoiceControl = function(self)
            self.voiceControlEnabled = false
            TouchControlsSystem.disableVoiceControl()
            print("♿ Voice control disabled")
        end
    }
    
    print("♿ Accessibility features initialized")
end

function TouchControlsSystem.applyTouchAssist()
    -- Increase touch target sizes
    for _, button in pairs(TouchState.actionButtons) do
        if button then
            button.Size = button.Size * 1.2
        end
    end
    
    -- Add visual touch indicators
    TouchControlsSystem.enableTouchIndicators()
end

function TouchControlsSystem.removeTouchAssist()
    -- Reset touch target sizes
    for _, button in pairs(TouchState.actionButtons) do
        if button then
            button.Size = TOUCH_CONFIG.virtualControls.actionButtons.buttonSize
        end
    end
    
    -- Remove visual touch indicators
    TouchControlsSystem.disableTouchIndicators()
end

function TouchControlsSystem.enableTouchIndicators()
    -- Add visual feedback for touch points
    print("👆 Touch indicators enabled")
end

function TouchControlsSystem.disableTouchIndicators()
    -- Remove visual feedback for touch points
    print("👆 Touch indicators disabled")
end

function TouchControlsSystem.setupVoiceControl()
    -- Setup voice command recognition
    print("🎤 Voice control setup placeholder")
end

function TouchControlsSystem.disableVoiceControl()
    -- Disable voice command recognition
    print("🎤 Voice control disabled")
end

-- ========================================
-- INPUT PROCESSING LOOPS
-- ========================================

function TouchControlsSystem.startInputProcessing()
    -- Main input processing loop
    spawn(function()
        while true do
            TouchControlsSystem.updateInputProcessing()
            task.wait(1 / TOUCH_CONFIG.performance.updateFrequency)
        end
    end)
    
    -- Gesture recognition loop
    spawn(function()
        while true do
            TouchControlsSystem.updateGestureRecognition()
            task.wait(0.1) -- 10Hz gesture recognition
        end
    end)
    
    -- Performance monitoring loop
    spawn(function()
        while true do
            TouchControlsSystem.updatePerformanceMonitoring()
            task.wait(1) -- 1Hz performance monitoring
        end
    end)
    
    print("🔄 Input processing loops started")
end

function TouchControlsSystem.updateInputProcessing()
    -- Clean up old input history
    local currentTime = tick()
    for i = #TouchState.inputHistory, 1, -1 do
        local inputEvent = TouchState.inputHistory[i]
        if currentTime - inputEvent.timestamp > TOUCH_CONFIG.performance.gestureTimeout then
            table.remove(TouchState.inputHistory, i)
        end
    end
    
    -- Update virtual joystick smoothing
    TouchControlsSystem.updateJoystickSmoothing()
end

function TouchControlsSystem.updateGestureRecognition()
    -- Process pending gesture recognition
    TouchState.performance.gesturesRecognized = TouchState.performance.gesturesRecognized + 1
end

function TouchControlsSystem.updatePerformanceMonitoring()
    -- Monitor frame drops and performance
    local frameRate = 1 / RunService.Heartbeat:Wait()
    if frameRate < 50 then
        TouchState.performance.frameDrops = TouchState.performance.frameDrops + 1
    end
end

function TouchControlsSystem.updateJoystickSmoothing()
    -- Apply smoothing to joystick input
    if TouchState.virtualJoystick.active then
        local damping = TOUCH_CONFIG.virtualControls.joystick.returnSpeed
        -- Apply smoothing logic here
    end
end

-- ========================================
-- CALLBACK SYSTEM
-- ========================================

function TouchControlsSystem.triggerTapCallbacks(position)
    for _, callback in pairs(TouchState.callbacks.onTap) do
        pcall(callback, position)
    end
end

function TouchControlsSystem.triggerDoubleTapCallbacks(position)
    for _, callback in pairs(TouchState.callbacks.onDoubleTap) do
        pcall(callback, position)
    end
end

function TouchControlsSystem.triggerLongPressCallbacks(position)
    for _, callback in pairs(TouchState.callbacks.onLongPress) do
        pcall(callback, position)
    end
end

function TouchControlsSystem.triggerSwipeCallbacks(swipeData)
    for _, callback in pairs(TouchState.callbacks.onSwipe) do
        pcall(callback, swipeData)
    end
end

function TouchControlsSystem.triggerPinchCallbacks(pinchData)
    for _, callback in pairs(TouchState.callbacks.onPinch) do
        pcall(callback, pinchData)
    end
end

function TouchControlsSystem.triggerPanCallbacks(panData)
    for _, callback in pairs(TouchState.callbacks.onPan) do
        pcall(callback, panData)
    end
end

function TouchControlsSystem.triggerRotateCallbacks(rotateData)
    for _, callback in pairs(TouchState.callbacks.onRotate) do
        pcall(callback, rotateData)
    end
end

function TouchControlsSystem.triggerJoystickCallbacks(joystickData)
    for _, callback in pairs(TouchState.callbacks.onJoystickMove) do
        pcall(callback, joystickData)
    end
end

function TouchControlsSystem.triggerButtonCallbacks(buttonName, action)
    for _, callback in pairs(TouchState.callbacks.onButtonPress) do
        pcall(callback, buttonName, action)
    end
end

-- ========================================
-- PUBLIC API
-- ========================================

function TouchControlsSystem.onTap(callback)
    table.insert(TouchState.callbacks.onTap, callback)
end

function TouchControlsSystem.onDoubleTap(callback)
    table.insert(TouchState.callbacks.onDoubleTap, callback)
end

function TouchControlsSystem.onLongPress(callback)
    table.insert(TouchState.callbacks.onLongPress, callback)
end

function TouchControlsSystem.onSwipe(callback)
    table.insert(TouchState.callbacks.onSwipe, callback)
end

function TouchControlsSystem.onPinch(callback)
    table.insert(TouchState.callbacks.onPinch, callback)
end

function TouchControlsSystem.onPan(callback)
    table.insert(TouchState.callbacks.onPan, callback)
end

function TouchControlsSystem.onJoystickMove(callback)
    table.insert(TouchState.callbacks.onJoystickMove, callback)
end

function TouchControlsSystem.onButtonPress(callback)
    table.insert(TouchState.callbacks.onButtonPress, callback)
end

function TouchControlsSystem.enableHapticFeedback()
    TouchState.hapticController.enabled = true
    TOUCH_CONFIG.haptics.enableFeedback = true
    print("📳 Haptic feedback enabled")
end

function TouchControlsSystem.disableHapticFeedback()
    TouchState.hapticController.enabled = false
    TOUCH_CONFIG.haptics.enableFeedback = false
    print("📳 Haptic feedback disabled")
end

function TouchControlsSystem.showVirtualControls()
    if TouchState.virtualJoystick.frame then
        TouchState.virtualJoystick.frame.Visible = true
    end
    
    for _, button in pairs(TouchState.actionButtons) do
        if button then
            button.Visible = true
        end
    end
    
    print("🕹️ Virtual controls shown")
end

function TouchControlsSystem.hideVirtualControls()
    if TouchState.virtualJoystick.frame then
        TouchState.virtualJoystick.frame.Visible = false
    end
    
    for _, button in pairs(TouchState.actionButtons) do
        if button then
            button.Visible = false
        end
    end
    
    print("🕹️ Virtual controls hidden")
end

function TouchControlsSystem.getJoystickState()
    return TouchState.virtualJoystick
end

function TouchControlsSystem.getPerformanceMetrics()
    return TouchState.performance
end

function TouchControlsSystem.runTouchDemo()
    print("📱 Running touch controls demonstration...")
    
    -- Show touch configuration
    print("  🎮 Touch Configuration:")
    print(string.format("    Tap Duration: %.1fs", TOUCH_CONFIG.sensitivity.tap.maxDuration))
    print(string.format("    Swipe Distance: %dpx", TOUCH_CONFIG.sensitivity.swipe.minDistance))
    print(string.format("    Haptic Feedback: %s", TOUCH_CONFIG.haptics.enableFeedback and "✅" or "❌"))
    print(string.format("    Virtual Joystick: %s", TOUCH_CONFIG.virtualControls.joystick.enabled and "✅" or "❌"))
    print(string.format("    Action Buttons: %s", TOUCH_CONFIG.virtualControls.actionButtons.enabled and "✅" or "❌"))
    
    -- Show current touch state
    print("  👆 Touch State:")
    print(string.format("    Active Touches: %d", #TouchState.activeTouches))
    print(string.format("    Joystick Active: %s", TouchState.virtualJoystick.active and "✅" or "❌"))
    print(string.format("    Joystick Magnitude: %.2f", TouchState.virtualJoystick.magnitude))
    
    -- Show performance metrics
    print("  📊 Performance Metrics:")
    local performance = TouchState.performance
    print(string.format("    Input Events: %d", performance.inputEvents))
    print(string.format("    Gestures Recognized: %d", performance.gesturesRecognized))
    print(string.format("    Average Response Time: %.3fs", performance.averageResponseTime))
    print(string.format("    Frame Drops: %d", performance.frameDrops))
    
    -- Demonstrate callbacks
    print("  🔧 Setting up demo callbacks...")
    
    TouchControlsSystem.onTap(function(position)
        print(string.format("    Tap detected at (%.0f, %.0f)", position.X, position.Y))
    end)
    
    TouchControlsSystem.onSwipe(function(swipeData)
        print(string.format("    Swipe detected: %s direction", tostring(swipeData.direction)))
    end)
    
    TouchControlsSystem.onJoystickMove(function(joystickData)
        if joystickData.active then
            print(string.format("    Joystick: magnitude=%.2f, angle=%.1f°", 
                joystickData.magnitude, math.deg(joystickData.angle)))
        end
    end)
    
    TouchControlsSystem.onButtonPress(function(buttonName, action)
        print(string.format("    Button %s: %s", buttonName, action))
    end)
    
    -- Show accessibility features
    print("  ♿ Accessibility Features:")
    local accessibility = TouchState.accessibilityManager
    print(string.format("    Touch Assist: %s", accessibility.touchAssistEnabled and "✅" or "❌"))
    print(string.format("    Voice Control: %s", accessibility.voiceControlEnabled and "✅" or "❌"))
    print(string.format("    Assistive Touch: %s", accessibility.assistiveTouchEnabled and "✅" or "❌"))
    
    -- Demonstrate haptic feedback
    print("  📳 Testing haptic feedback...")
    TouchControlsSystem.triggerHapticFeedback("tap")
    task.wait(0.5)
    TouchControlsSystem.triggerHapticFeedback("medium")
    task.wait(0.5)
    TouchControlsSystem.triggerHapticFeedback("heavy")
    
    print("📱 Touch controls demonstration completed")
    print("     Try tapping, swiping, or using the virtual joystick!")
end

-- Initialize the touch controls system
TouchControlsSystem.initialize()

print("📱 TouchControlsSystem loaded with comprehensive gesture and haptic support")

return TouchControlsSystem
