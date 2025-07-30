-- AdaptiveUISystem.luau
-- Comprehensive adaptive UI scaling and layout system for all screen sizes and orientations
-- Handles responsive design, dynamic layouts, and cross-platform compatibility

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local GuiService = game:GetService("GuiService")
local TweenService = game:GetService("TweenService")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local SafeRequire = require(ReplicatedStorage.Shared.utils.SafeRequire)

local AdaptiveUISystem = {}

-- ========================================
-- ADAPTIVE UI CONFIGURATION
-- ========================================

local UI_CONFIG = {
    -- Screen size breakpoints
    breakpoints = {
        mobile = {
            portrait = {width = 0, height = 0, maxWidth = 768, maxHeight = 1024},
            landscape = {width = 0, height = 0, maxWidth = 1024, maxHeight = 768}
        },
        tablet = {
            portrait = {width = 768, height = 1024, maxWidth = 1024, maxHeight = 1366},
            landscape = {width = 1024, height = 768, maxWidth = 1366, maxHeight = 1024}
        },
        desktop = {
            standard = {width = 1024, height = 768, maxWidth = 1920, maxHeight = 1080},
            wide = {width = 1920, height = 1080, maxWidth = 3840, maxHeight = 2160}
        },
        console = {
            tv = {width = 1920, height = 1080, maxWidth = 3840, maxHeight = 2160}
        }
    },
    
    -- Scaling factors for different device types
    scaling = {
        mobile = {
            baseScale = 1.0,
            textScale = 1.1,
            buttonScale = 1.2,
            iconScale = 1.15,
            spacingScale = 0.9
        },
        tablet = {
            baseScale = 1.1,
            textScale = 1.0,
            buttonScale = 1.1,
            iconScale = 1.0,
            spacingScale = 1.0
        },
        desktop = {
            baseScale = 1.0,
            textScale = 1.0,
            buttonScale = 1.0,
            iconScale = 1.0,
            spacingScale = 1.0
        },
        console = {
            baseScale = 1.2,
            textScale = 1.1,
            buttonScale = 1.3,
            iconScale = 1.2,
            spacingScale = 1.1
        }
    },
    
    -- Layout configurations
    layouts = {
        mobile = {
            portrait = {
                columns = 1,
                maxItemsPerRow = 2,
                navigationPosition = "bottom",
                menuStyle = "drawer",
                buttonSize = "large",
                spacing = "compact"
            },
            landscape = {
                columns = 2,
                maxItemsPerRow = 4,
                navigationPosition = "top",
                menuStyle = "horizontal",
                buttonSize = "medium",
                spacing = "normal"
            }
        },
        tablet = {
            portrait = {
                columns = 2,
                maxItemsPerRow = 3,
                navigationPosition = "top",
                menuStyle = "tabs",
                buttonSize = "medium",
                spacing = "normal"
            },
            landscape = {
                columns = 3,
                maxItemsPerRow = 5,
                navigationPosition = "top",
                menuStyle = "horizontal",
                buttonSize = "medium",
                spacing = "normal"
            }
        },
        desktop = {
            standard = {
                columns = 3,
                maxItemsPerRow = 6,
                navigationPosition = "top",
                menuStyle = "horizontal",
                buttonSize = "medium",
                spacing = "normal"
            },
            wide = {
                columns = 4,
                maxItemsPerRow = 8,
                navigationPosition = "top",
                menuStyle = "horizontal",
                buttonSize = "medium",
                spacing = "wide"
            }
        }
    },
    
    -- Animation settings
    animations = {
        transitionDuration = 0.3,
        easingStyle = Enum.EasingStyle.Quart,
        easingDirection = Enum.EasingDirection.Out,
        enableTransitions = true,
        enableParallax = false, -- Disabled on mobile for performance
        enableBlur = false      -- Disabled on mobile for performance
    },
    
    -- Accessibility settings
    accessibility = {
        minTouchTargetSize = 44, -- 44x44 pixels minimum
        maxTextContrast = true,
        enableHighContrast = false,
        fontSize = {
            small = 12,
            normal = 14,
            large = 18,
            extraLarge = 24
        },
        enableVoiceOver = false,
        enableReducedMotion = false
    },
    
    -- Safe area handling
    safeArea = {
        enableNotchSupport = true,
        enableHomeIndicatorPadding = true,
        minimumPadding = {
            top = 20,
            bottom = 20,
            left = 16,
            right = 16
        }
    }
}

-- ========================================
-- ADAPTIVE UI STATE
-- ========================================

local UIState = {
    -- Current device information
    currentDevice = {
        type = "desktop",
        orientation = "landscape",
        screenSize = Vector2.new(1024, 768),
        safeArea = {
            top = 0,
            bottom = 0,
            left = 0,
            right = 0
        },
        aspectRatio = 4/3,
        dpi = 96
    },
    
    -- Current layout configuration
    currentLayout = {},
    currentScaling = {},
    
    -- UI element registry
    adaptiveElements = {},
    layoutContainers = {},
    responsiveImages = {},
    dynamicText = {},
    
    -- Animation state
    activeTransitions = {},
    animationQueue = {},
    
    -- Accessibility state
    accessibilitySettings = {
        highContrast = false,
        largeText = false,
        reducedMotion = false,
        voiceOverEnabled = false
    },
    
    -- Performance tracking
    performanceMetrics = {
        layoutCalculations = 0,
        transitionCount = 0,
        averageLayoutTime = 0,
        frameDrops = 0
    }
}

function AdaptiveUISystem.initialize()
    print("📱 Initializing AdaptiveUISystem...")
    
    -- Detect initial device configuration
    AdaptiveUISystem.detectDevice()
    
    -- Set up layout system
    AdaptiveUISystem.setupLayoutSystem()
    
    -- Initialize responsive components
    AdaptiveUISystem.initializeResponsiveComponents()
    
    -- Set up orientation monitoring
    AdaptiveUISystem.setupOrientationMonitoring()
    
    -- Initialize accessibility features
    AdaptiveUISystem.initializeAccessibility()
    
    -- Set up performance monitoring
    AdaptiveUISystem.setupPerformanceMonitoring()
    
    -- Apply initial layout
    AdaptiveUISystem.applyAdaptiveLayout()
    
    print("📱 AdaptiveUISystem initialized successfully")
end

-- ========================================
-- DEVICE DETECTION AND CONFIGURATION
-- ========================================

function AdaptiveUISystem.detectDevice()
    local camera = workspace.CurrentCamera
    local viewportSize = camera and camera.ViewportSize or Vector2.new(1024, 768)
    
    UIState.currentDevice.screenSize = viewportSize
    UIState.currentDevice.aspectRatio = viewportSize.X / viewportSize.Y
    
    -- Determine device type
    if UserInputService.TouchEnabled then
        if viewportSize.X < 768 or viewportSize.Y < 768 then
            UIState.currentDevice.type = "mobile"
        else
            UIState.currentDevice.type = "tablet"
        end
    elseif UserInputService.GamepadEnabled then
        UIState.currentDevice.type = "console"
    else
        UIState.currentDevice.type = "desktop"
    end
    
    -- Determine orientation
    if viewportSize.X > viewportSize.Y then
        UIState.currentDevice.orientation = "landscape"
    else
        UIState.currentDevice.orientation = "portrait"
    end
    
    -- Calculate safe area (simplified)
    UIState.currentDevice.safeArea = AdaptiveUISystem.calculateSafeArea()
    
    -- Get DPI information
    UIState.currentDevice.dpi = AdaptiveUISystem.estimateDPI()
    
    print(string.format("📱 Device detected: %s %s (%dx%d)", 
        UIState.currentDevice.type, 
        UIState.currentDevice.orientation,
        viewportSize.X, 
        viewportSize.Y))
end

function AdaptiveUISystem.calculateSafeArea()
    local safeArea = {
        top = UI_CONFIG.safeArea.minimumPadding.top,
        bottom = UI_CONFIG.safeArea.minimumPadding.bottom,
        left = UI_CONFIG.safeArea.minimumPadding.left,
        right = UI_CONFIG.safeArea.minimumPadding.right
    }
    
    -- Add device-specific safe area adjustments
    if UIState.currentDevice.type == "mobile" then
        -- Account for notches and home indicators
        if UI_CONFIG.safeArea.enableNotchSupport then
            safeArea.top = safeArea.top + 24 -- Status bar + notch
        end
        
        if UI_CONFIG.safeArea.enableHomeIndicatorPadding then
            safeArea.bottom = safeArea.bottom + 34 -- Home indicator
        end
    end
    
    return safeArea
end

function AdaptiveUISystem.estimateDPI()
    local screenSize = UIState.currentDevice.screenSize
    local deviceType = UIState.currentDevice.type
    
    -- Estimate DPI based on device type and screen size
    if deviceType == "mobile" then
        return screenSize.X > 400 and 300 or 150 -- Retina vs standard
    elseif deviceType == "tablet" then
        return 200
    elseif deviceType == "console" then
        return 96 -- TV DPI
    else
        return 96 -- Standard desktop DPI
    end
end

-- ========================================
-- LAYOUT SYSTEM
-- ========================================

function AdaptiveUISystem.setupLayoutSystem()
    UIState.layoutSystem = {
        gridCalculator = AdaptiveUISystem.createGridCalculator(),
        flexboxCalculator = AdaptiveUISystem.createFlexboxCalculator(),
        constraintSolver = AdaptiveUISystem.createConstraintSolver(),
        
        calculateLayout = function(self, container, elements)
            return AdaptiveUISystem.calculateContainerLayout(container, elements)
        end,
        
        applyLayout = function(self, container, layout)
            AdaptiveUISystem.applyContainerLayout(container, layout)
        end
    }
    
    print("📐 Layout system initialized")
end

function AdaptiveUISystem.createGridCalculator()
    return {
        name = "grid_calculator",
        
        calculate = function(self, container, items, columns)
            local layout = {
                type = "grid",
                columns = columns,
                rows = math.ceil(#items / columns),
                items = {}
            }
            
            local containerSize = container.AbsoluteSize
            local itemWidth = containerSize.X / columns
            local itemHeight = containerSize.Y / layout.rows
            
            for i, item in ipairs(items) do
                local row = math.ceil(i / columns) - 1
                local col = (i - 1) % columns
                
                layout.items[i] = {
                    element = item,
                    position = UDim2.new(0, col * itemWidth, 0, row * itemHeight),
                    size = UDim2.new(0, itemWidth, 0, itemHeight)
                }
            end
            
            return layout
        end
    }
end

function AdaptiveUISystem.createFlexboxCalculator()
    return {
        name = "flexbox_calculator",
        
        calculate = function(self, container, items, direction)
            direction = direction or "row"
            
            local layout = {
                type = "flexbox",
                direction = direction,
                items = {}
            }
            
            local containerSize = container.AbsoluteSize
            local totalItems = #items
            
            if direction == "row" then
                local itemWidth = containerSize.X / totalItems
                
                for i, item in ipairs(items) do
                    layout.items[i] = {
                        element = item,
                        position = UDim2.new(0, (i - 1) * itemWidth, 0, 0),
                        size = UDim2.new(0, itemWidth, 1, 0)
                    }
                end
            else -- column
                local itemHeight = containerSize.Y / totalItems
                
                for i, item in ipairs(items) do
                    layout.items[i] = {
                        element = item,
                        position = UDim2.new(0, 0, 0, (i - 1) * itemHeight),
                        size = UDim2.new(1, 0, 0, itemHeight)
                    }
                end
            end
            
            return layout
        end
    }
end

function AdaptiveUISystem.createConstraintSolver()
    return {
        name = "constraint_solver",
        
        solve = function(self, constraints)
            -- Simplified constraint solving
            local solution = {}
            
            for i, constraint in ipairs(constraints) do
                solution[i] = AdaptiveUISystem.resolveConstraint(constraint)
            end
            
            return solution
        end
    }
end

function AdaptiveUISystem.calculateContainerLayout(container, elements)
    local deviceType = UIState.currentDevice.type
    local orientation = UIState.currentDevice.orientation
    
    -- Get layout configuration for current device
    local layoutConfig = UI_CONFIG.layouts[deviceType]
    if layoutConfig and layoutConfig[orientation] then
        layoutConfig = layoutConfig[orientation]
    elseif layoutConfig and layoutConfig.standard then
        layoutConfig = layoutConfig.standard
    else
        layoutConfig = UI_CONFIG.layouts.desktop.standard
    end
    
    UIState.currentLayout = layoutConfig
    
    -- Calculate layout based on configuration
    local layout
    if layoutConfig.columns and layoutConfig.columns > 1 then
        layout = UIState.layoutSystem.gridCalculator:calculate(container, elements, layoutConfig.columns)
    else
        layout = UIState.layoutSystem.flexboxCalculator:calculate(container, elements, "column")
    end
    
    -- Apply scaling
    layout = AdaptiveUISystem.applyScalingToLayout(layout)
    
    -- Apply safe area constraints
    layout = AdaptiveUISystem.applySafeAreaToLayout(layout)
    
    UIState.performanceMetrics.layoutCalculations = UIState.performanceMetrics.layoutCalculations + 1
    
    return layout
end

function AdaptiveUISystem.applyContainerLayout(container, layout)
    local startTime = tick()
    
    -- Apply layout to each item
    for i, itemLayout in ipairs(layout.items) do
        local element = itemLayout.element
        
        if element and element.Parent then
            -- Create transition if animations are enabled
            if UI_CONFIG.animations.enableTransitions then
                AdaptiveUISystem.animateToLayout(element, itemLayout.position, itemLayout.size)
            else
                element.Position = itemLayout.position
                element.Size = itemLayout.size
            end
        end
    end
    
    -- Update performance metrics
    local layoutTime = tick() - startTime
    UIState.performanceMetrics.averageLayoutTime = 
        (UIState.performanceMetrics.averageLayoutTime + layoutTime) / 2
end

function AdaptiveUISystem.applyScalingToLayout(layout)
    local deviceType = UIState.currentDevice.type
    local scaling = UI_CONFIG.scaling[deviceType] or UI_CONFIG.scaling.desktop
    
    UIState.currentScaling = scaling
    
    -- Apply scaling to layout items
    for i, itemLayout in ipairs(layout.items) do
        local originalSize = itemLayout.size
        
        -- Scale size based on device scaling factors
        itemLayout.size = UDim2.new(
            originalSize.X.Scale * scaling.baseScale,
            originalSize.X.Offset * scaling.baseScale,
            originalSize.Y.Scale * scaling.baseScale,
            originalSize.Y.Offset * scaling.baseScale
        )
    end
    
    return layout
end

function AdaptiveUISystem.applySafeAreaToLayout(layout)
    local safeArea = UIState.currentDevice.safeArea
    
    -- Adjust layout items to respect safe area
    for i, itemLayout in ipairs(layout.items) do
        local originalPosition = itemLayout.position
        
        -- Add safe area padding
        itemLayout.position = UDim2.new(
            originalPosition.X.Scale,
            originalPosition.X.Offset + safeArea.left,
            originalPosition.Y.Scale,
            originalPosition.Y.Offset + safeArea.top
        )
        
        -- Reduce size to account for safe area
        local originalSize = itemLayout.size
        itemLayout.size = UDim2.new(
            originalSize.X.Scale,
            originalSize.X.Offset - (safeArea.left + safeArea.right),
            originalSize.Y.Scale,
            originalSize.Y.Offset - (safeArea.top + safeArea.bottom)
        )
    end
    
    return layout
end

-- ========================================
-- RESPONSIVE COMPONENTS
-- ========================================

function AdaptiveUISystem.initializeResponsiveComponents()
    UIState.componentManagers = {
        textManager = AdaptiveUISystem.createResponsiveTextManager(),
        imageManager = AdaptiveUISystem.createResponsiveImageManager(),
        buttonManager = AdaptiveUISystem.createResponsiveButtonManager(),
        navigationManager = AdaptiveUISystem.createNavigationManager()
    }
    
    print("🔧 Responsive components initialized")
end

function AdaptiveUISystem.createResponsiveTextManager()
    return {
        name = "responsive_text_manager",
        elements = {},
        
        registerText = function(self, textElement, baseSize)
            self.elements[textElement] = {
                baseSize = baseSize or textElement.TextSize,
                element = textElement
            }
        end,
        
        updateTextSizes = function(self)
            local scaling = UIState.currentScaling
            local accessibilityScale = UIState.accessibilitySettings.largeText and 1.25 or 1.0
            
            for element, data in pairs(self.elements) do
                if element.Parent then
                    local newSize = data.baseSize * scaling.textScale * accessibilityScale
                    
                    if UI_CONFIG.animations.enableTransitions then
                        AdaptiveUISystem.animateProperty(element, "TextSize", newSize)
                    else
                        element.TextSize = newSize
                    end
                end
            end
        end
    }
end

function AdaptiveUISystem.createResponsiveImageManager()
    return {
        name = "responsive_image_manager",
        elements = {},
        
        registerImage = function(self, imageElement, imageSources)
            self.elements[imageElement] = {
                sources = imageSources, -- {low = "id", medium = "id", high = "id"}
                element = imageElement
            }
        end,
        
        updateImageQuality = function(self)
            local deviceType = UIState.currentDevice.type
            local qualityLevel = "medium"
            
            if deviceType == "mobile" then
                qualityLevel = "low"
            elseif deviceType == "desktop" or deviceType == "console" then
                qualityLevel = "high"
            end
            
            for element, data in pairs(self.elements) do
                if element.Parent and data.sources[qualityLevel] then
                    element.Image = data.sources[qualityLevel]
                end
            end
        end
    }
end

function AdaptiveUISystem.createResponsiveButtonManager()
    return {
        name = "responsive_button_manager",
        elements = {},
        
        registerButton = function(self, buttonElement, baseSize)
            self.elements[buttonElement] = {
                baseSize = baseSize or buttonElement.Size,
                element = buttonElement
            }
        end,
        
        updateButtonSizes = function(self)
            local scaling = UIState.currentScaling
            local deviceType = UIState.currentDevice.type
            
            -- Ensure minimum touch target size on mobile
            local minSize = deviceType == "mobile" and UI_CONFIG.accessibility.minTouchTargetSize or 0
            
            for element, data in pairs(self.elements) do
                if element.Parent then
                    local newSize = UDim2.new(
                        data.baseSize.X.Scale * scaling.buttonScale,
                        math.max(minSize, data.baseSize.X.Offset * scaling.buttonScale),
                        data.baseSize.Y.Scale * scaling.buttonScale,
                        math.max(minSize, data.baseSize.Y.Offset * scaling.buttonScale)
                    )
                    
                    if UI_CONFIG.animations.enableTransitions then
                        AdaptiveUISystem.animateToSize(element, newSize)
                    else
                        element.Size = newSize
                    end
                end
            end
        end
    }
end

function AdaptiveUISystem.createNavigationManager()
    return {
        name = "navigation_manager",
        navigationElements = {},
        
        registerNavigation = function(self, navElement)
            table.insert(self.navigationElements, navElement)
        end,
        
        updateNavigationLayout = function(self)
            local layoutConfig = UIState.currentLayout
            
            for _, navElement in ipairs(self.navigationElements) do
                if navElement.Parent then
                    AdaptiveUISystem.configureNavigationElement(navElement, layoutConfig)
                end
            end
        end
    }
end

function AdaptiveUISystem.configureNavigationElement(navElement, layoutConfig)
    if layoutConfig.navigationPosition == "bottom" then
        navElement.Position = UDim2.new(0, 0, 1, -60)
        navElement.Size = UDim2.new(1, 0, 0, 60)
    elseif layoutConfig.navigationPosition == "top" then
        navElement.Position = UDim2.new(0, 0, 0, 0)
        navElement.Size = UDim2.new(1, 0, 0, 50)
    end
    
    -- Configure navigation style
    if layoutConfig.menuStyle == "drawer" then
        AdaptiveUISystem.configureDrawerMenu(navElement)
    elseif layoutConfig.menuStyle == "tabs" then
        AdaptiveUISystem.configureTabMenu(navElement)
    else
        AdaptiveUISystem.configureHorizontalMenu(navElement)
    end
end

function AdaptiveUISystem.configureDrawerMenu(navElement)
    -- Configure for drawer-style navigation (mobile)
    navElement.BackgroundTransparency = 0
    navElement.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
end

function AdaptiveUISystem.configureTabMenu(navElement)
    -- Configure for tab-style navigation (tablet)
    navElement.BackgroundTransparency = 0.1
    navElement.BackgroundColor3 = Color3.fromRGB(240, 240, 240)
end

function AdaptiveUISystem.configureHorizontalMenu(navElement)
    -- Configure for horizontal navigation (desktop/landscape)
    navElement.BackgroundTransparency = 0.2
    navElement.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
end

-- ========================================
-- ORIENTATION MONITORING
-- ========================================

function AdaptiveUISystem.setupOrientationMonitoring()
    local camera = workspace.CurrentCamera
    
    if camera then
        UIState.orientationConnection = camera:GetPropertyChangedSignal("ViewportSize"):Connect(function()
            AdaptiveUISystem.handleOrientationChange()
        end)
    end
    
    print("🔄 Orientation monitoring initialized")
end

function AdaptiveUISystem.handleOrientationChange()
    local camera = workspace.CurrentCamera
    if not camera then return end
    
    local newViewportSize = camera.ViewportSize
    local oldOrientation = UIState.currentDevice.orientation
    
    -- Update device information
    UIState.currentDevice.screenSize = newViewportSize
    UIState.currentDevice.aspectRatio = newViewportSize.X / newViewportSize.Y
    
    -- Determine new orientation
    local newOrientation
    if newViewportSize.X > newViewportSize.Y then
        newOrientation = "landscape"
    else
        newOrientation = "portrait"
    end
    
    UIState.currentDevice.orientation = newOrientation
    
    -- If orientation changed, recalculate layout
    if newOrientation ~= oldOrientation then
        print(string.format("📱 Orientation changed: %s -> %s", oldOrientation, newOrientation))
        
        -- Recalculate safe area
        UIState.currentDevice.safeArea = AdaptiveUISystem.calculateSafeArea()
        
        -- Apply new adaptive layout
        AdaptiveUISystem.applyAdaptiveLayout()
        
        -- Trigger orientation change event
        AdaptiveUISystem.triggerOrientationChangeEvent(oldOrientation, newOrientation)
    end
end

function AdaptiveUISystem.triggerOrientationChangeEvent(oldOrientation, newOrientation)
    -- Notify all registered orientation listeners
    for _, listener in ipairs(UIState.orientationListeners or {}) do
        if listener and typeof(listener) == "function" then
            pcall(listener, oldOrientation, newOrientation)
        end
    end
end

-- ========================================
-- ACCESSIBILITY FEATURES
-- ========================================

function AdaptiveUISystem.initializeAccessibility()
    UIState.accessibilityManager = {
        highContrastMode = false,
        largeTextMode = false,
        reducedMotionMode = false,
        voiceOverMode = false,
        
        enableHighContrast = function(self)
            self.highContrastMode = true
            UIState.accessibilitySettings.highContrast = true
            AdaptiveUISystem.applyHighContrastTheme()
            print("♿ High contrast mode enabled")
        end,
        
        disableHighContrast = function(self)
            self.highContrastMode = false
            UIState.accessibilitySettings.highContrast = false
            AdaptiveUISystem.removeHighContrastTheme()
            print("♿ High contrast mode disabled")
        end,
        
        enableLargeText = function(self)
            self.largeTextMode = true
            UIState.accessibilitySettings.largeText = true
            UIState.componentManagers.textManager:updateTextSizes()
            print("♿ Large text mode enabled")
        end,
        
        disableLargeText = function(self)
            self.largeTextMode = false
            UIState.accessibilitySettings.largeText = false
            UIState.componentManagers.textManager:updateTextSizes()
            print("♿ Large text mode disabled")
        end,
        
        enableReducedMotion = function(self)
            self.reducedMotionMode = true
            UIState.accessibilitySettings.reducedMotion = true
            UI_CONFIG.animations.enableTransitions = false
            print("♿ Reduced motion mode enabled")
        end,
        
        disableReducedMotion = function(self)
            self.reducedMotionMode = false
            UIState.accessibilitySettings.reducedMotion = false
            UI_CONFIG.animations.enableTransitions = true
            print("♿ Reduced motion mode disabled")
        end
    }
    
    print("♿ Accessibility features initialized")
end

function AdaptiveUISystem.applyHighContrastTheme()
    -- Apply high contrast colors to registered elements
    for element, _ in pairs(UIState.adaptiveElements) do
        if element:IsA("GuiObject") then
            if element:IsA("TextLabel") or element:IsA("TextButton") then
                element.TextColor3 = Color3.new(1, 1, 1) -- White text
                element.BackgroundColor3 = Color3.new(0, 0, 0) -- Black background
            end
        end
    end
end

function AdaptiveUISystem.removeHighContrastTheme()
    -- Restore original colors (would store original colors in a registry)
    for element, _ in pairs(UIState.adaptiveElements) do
        if element:IsA("GuiObject") then
            -- Restore to default theme colors
            AdaptiveUISystem.applyDefaultTheme(element)
        end
    end
end

function AdaptiveUISystem.applyDefaultTheme(element)
    -- Apply default theme colors
    if element:IsA("TextLabel") or element:IsA("TextButton") then
        element.TextColor3 = Color3.fromRGB(50, 50, 50)
        element.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    end
end

-- ========================================
-- ANIMATION SYSTEM
-- ========================================

function AdaptiveUISystem.animateToLayout(element, targetPosition, targetSize)
    local tweenInfo = TweenInfo.new(
        UI_CONFIG.animations.transitionDuration,
        UI_CONFIG.animations.easingStyle,
        UI_CONFIG.animations.easingDirection
    )
    
    -- Create position tween
    local positionTween = TweenService:Create(element, tweenInfo, {Position = targetPosition})
    
    -- Create size tween
    local sizeTween = TweenService:Create(element, tweenInfo, {Size = targetSize})
    
    -- Play tweens
    positionTween:Play()
    sizeTween:Play()
    
    -- Track active transitions
    UIState.performanceMetrics.transitionCount = UIState.performanceMetrics.transitionCount + 1
end

function AdaptiveUISystem.animateToSize(element, targetSize)
    local tweenInfo = TweenInfo.new(
        UI_CONFIG.animations.transitionDuration,
        UI_CONFIG.animations.easingStyle,
        UI_CONFIG.animations.easingDirection
    )
    
    local sizeTween = TweenService:Create(element, tweenInfo, {Size = targetSize})
    sizeTween:Play()
end

function AdaptiveUISystem.animateProperty(element, property, targetValue)
    local tweenInfo = TweenInfo.new(
        UI_CONFIG.animations.transitionDuration,
        UI_CONFIG.animations.easingStyle,
        UI_CONFIG.animations.easingDirection
    )
    
    local properties = {}
    properties[property] = targetValue
    
    local tween = TweenService:Create(element, tweenInfo, properties)
    tween:Play()
end

-- ========================================
-- PERFORMANCE MONITORING
-- ========================================

function AdaptiveUISystem.setupPerformanceMonitoring()
    UIState.performanceMonitor = {
        frameTracker = {
            lastFrameTime = tick(),
            frameCount = 0,
            
            update = function(self)
                local currentTime = tick()
                local deltaTime = currentTime - self.lastFrameTime
                
                if deltaTime > 1/50 then -- 50 FPS threshold
                    UIState.performanceMetrics.frameDrops = UIState.performanceMetrics.frameDrops + 1
                end
                
                self.lastFrameTime = currentTime
                self.frameCount = self.frameCount + 1
            end
        }
    }
    
    -- Start performance monitoring loop
    spawn(function()
        while true do
            UIState.performanceMonitor.frameTracker:update()
            task.wait()
        end
    end)
    
    print("📊 Performance monitoring initialized")
end

-- ========================================
-- UTILITY FUNCTIONS
-- ========================================

function AdaptiveUISystem.resolveConstraint(constraint)
    -- Simplified constraint resolution
    return {
        satisfied = true,
        value = constraint.value or 0
    }
end

function AdaptiveUISystem.applyAdaptiveLayout()
    -- Apply layout to all registered containers
    for container, elements in pairs(UIState.layoutContainers) do
        if container.Parent then
            local layout = AdaptiveUISystem.calculateContainerLayout(container, elements)
            AdaptiveUISystem.applyContainerLayout(container, layout)
        end
    end
    
    -- Update all responsive components
    if UIState.componentManagers then
        UIState.componentManagers.textManager:updateTextSizes()
        UIState.componentManagers.imageManager:updateImageQuality()
        UIState.componentManagers.buttonManager:updateButtonSizes()
        UIState.componentManagers.navigationManager:updateNavigationLayout()
    end
end

-- ========================================
-- PUBLIC API
-- ========================================

function AdaptiveUISystem.registerAdaptiveElement(element, config)
    config = config or {}
    
    UIState.adaptiveElements[element] = {
        config = config,
        originalProperties = {
            size = element.Size,
            position = element.Position,
            textSize = element:IsA("TextLabel") and element.TextSize or nil
        }
    }
    
    -- Register with appropriate component manager
    if element:IsA("TextLabel") or element:IsA("TextButton") then
        UIState.componentManagers.textManager:registerText(element)
    elseif element:IsA("ImageLabel") or element:IsA("ImageButton") then
        UIState.componentManagers.imageManager:registerImage(element, config.imageSources)
    elseif element:IsA("GuiButton") then
        UIState.componentManagers.buttonManager:registerButton(element)
    end
end

function AdaptiveUISystem.registerLayoutContainer(container, elements)
    UIState.layoutContainers[container] = elements
    
    -- Apply initial layout
    local layout = AdaptiveUISystem.calculateContainerLayout(container, elements)
    AdaptiveUISystem.applyContainerLayout(container, layout)
end

function AdaptiveUISystem.registerOrientationListener(callback)
    if not UIState.orientationListeners then
        UIState.orientationListeners = {}
    end
    
    table.insert(UIState.orientationListeners, callback)
end

function AdaptiveUISystem.enableHighContrast()
    UIState.accessibilityManager:enableHighContrast()
end

function AdaptiveUISystem.disableHighContrast()
    UIState.accessibilityManager:disableHighContrast()
end

function AdaptiveUISystem.enableLargeText()
    UIState.accessibilityManager:enableLargeText()
end

function AdaptiveUISystem.disableLargeText()
    UIState.accessibilityManager:disableLargeText()
end

function AdaptiveUISystem.enableReducedMotion()
    UIState.accessibilityManager:enableReducedMotion()
end

function AdaptiveUISystem.disableReducedMotion()
    UIState.accessibilityManager:disableReducedMotion()
end

function AdaptiveUISystem.refreshLayout()
    AdaptiveUISystem.detectDevice()
    AdaptiveUISystem.applyAdaptiveLayout()
    print("🔄 Layout refreshed")
end

function AdaptiveUISystem.runUIDemo()
    print("📱 Running adaptive UI demonstration...")
    
    -- Show current device information
    print("  📱 Device Information:")
    local device = UIState.currentDevice
    print(string.format("    Type: %s", device.type))
    print(string.format("    Orientation: %s", device.orientation))
    print(string.format("    Screen Size: %dx%d", device.screenSize.X, device.screenSize.Y))
    print(string.format("    Aspect Ratio: %.2f", device.aspectRatio))
    print(string.format("    DPI: %d", device.dpi))
    
    -- Show safe area information
    print("  📐 Safe Area:")
    local safeArea = device.safeArea
    print(string.format("    Top: %d, Bottom: %d", safeArea.top, safeArea.bottom))
    print(string.format("    Left: %d, Right: %d", safeArea.left, safeArea.right))
    
    -- Show current layout configuration
    print("  🎮 Current Layout:")
    local layout = UIState.currentLayout
    if layout then
        print(string.format("    Columns: %d", layout.columns or 1))
        print(string.format("    Max Items Per Row: %d", layout.maxItemsPerRow or 1))
        print(string.format("    Navigation Position: %s", layout.navigationPosition or "top"))
        print(string.format("    Menu Style: %s", layout.menuStyle or "horizontal"))
        print(string.format("    Button Size: %s", layout.buttonSize or "medium"))
    end
    
    -- Show scaling information
    print("  📏 Scaling Factors:")
    local scaling = UIState.currentScaling
    if scaling then
        print(string.format("    Base Scale: %.2f", scaling.baseScale))
        print(string.format("    Text Scale: %.2f", scaling.textScale))
        print(string.format("    Button Scale: %.2f", scaling.buttonScale))
        print(string.format("    Icon Scale: %.2f", scaling.iconScale))
    end
    
    -- Show accessibility settings
    print("  ♿ Accessibility:")
    local accessibility = UIState.accessibilitySettings
    print(string.format("    High Contrast: %s", accessibility.highContrast and "✅" or "❌"))
    print(string.format("    Large Text: %s", accessibility.largeText and "✅" or "❌"))
    print(string.format("    Reduced Motion: %s", accessibility.reducedMotion and "✅" or "❌"))
    
    -- Show performance metrics
    print("  📊 Performance Metrics:")
    local performance = UIState.performanceMetrics
    print(string.format("    Layout Calculations: %d", performance.layoutCalculations))
    print(string.format("    Transitions: %d", performance.transitionCount))
    print(string.format("    Average Layout Time: %.3fs", performance.averageLayoutTime))
    print(string.format("    Frame Drops: %d", performance.frameDrops))
    
    -- Demonstrate orientation change simulation
    print("  🔄 Demonstrating orientation change...")
    
    local originalOrientation = UIState.currentDevice.orientation
    
    -- Simulate orientation change
    if originalOrientation == "portrait" then
        UIState.currentDevice.orientation = "landscape"
        UIState.currentDevice.screenSize = Vector2.new(UIState.currentDevice.screenSize.Y, UIState.currentDevice.screenSize.X)
    else
        UIState.currentDevice.orientation = "portrait"
        UIState.currentDevice.screenSize = Vector2.new(UIState.currentDevice.screenSize.Y, UIState.currentDevice.screenSize.X)
    end
    
    print(string.format("    Orientation changed: %s -> %s", originalOrientation, UIState.currentDevice.orientation))
    
    -- Apply new layout
    AdaptiveUISystem.applyAdaptiveLayout()
    
    task.wait(1)
    
    -- Restore original orientation
    UIState.currentDevice.orientation = originalOrientation
    UIState.currentDevice.screenSize = Vector2.new(UIState.currentDevice.screenSize.Y, UIState.currentDevice.screenSize.X)
    AdaptiveUISystem.applyAdaptiveLayout()
    
    print(string.format("    Orientation restored: %s", originalOrientation))
    
    -- Demonstrate accessibility features
    print("  ♿ Demonstrating accessibility features...")
    
    AdaptiveUISystem.enableHighContrast()
    task.wait(0.5)
    AdaptiveUISystem.disableHighContrast()
    
    AdaptiveUISystem.enableLargeText()
    task.wait(0.5)
    AdaptiveUISystem.disableLargeText()
    
    print("📱 Adaptive UI demonstration completed")
end

function AdaptiveUISystem.getDeviceInfo()
    return UIState.currentDevice
end

function AdaptiveUISystem.getCurrentLayout()
    return UIState.currentLayout
end

function AdaptiveUISystem.getPerformanceMetrics()
    return UIState.performanceMetrics
end

function AdaptiveUISystem.getAccessibilitySettings()
    return UIState.accessibilitySettings
end

-- Initialize the adaptive UI system
AdaptiveUISystem.initialize()

print("📱 AdaptiveUISystem loaded with comprehensive responsive design")

return AdaptiveUISystem
