-- MobileOptimizationService.luau
-- Comprehensive mobile UI optimization with device detection and adaptive layouts

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local GuiService = game:GetService("GuiService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local SafeRequire = require(ReplicatedStorage.Shared.utils.SafeRequire)
local RemoteEvents = SafeRequire.require(ReplicatedStorage.Shared.modules.RemoteEvents)

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local MobileOptimizationService = {}

-- Device detection and configuration
local deviceInfo = {
    platform = "Unknown",
    screenSize = Vector2.new(0, 0),
    aspectRatio = 1,
    isPhone = false,
    isTablet = false,
    isDesktop = false,
    safeArea = {
        top = 0,
        bottom = 0,
        left = 0,
        right = 0
    },
    touchEnabled = false,
    accelerometerEnabled = false,
    gyroscopeEnabled = false
}

-- Mobile optimization configurations
local MOBILE_CONFIG = {
    -- Phone configurations
    PHONE = {
        minTouchSize = 44, -- Minimum 44x44 pixel touch targets
        maxMenuWidth = 0.9, -- 90% of screen width
        fontSize = {
            small = 14,
            medium = 16,
            large = 20,
            title = 24
        },
        padding = {
            small = 8,
            medium = 12,
            large = 16
        },
        buttonHeight = 50,
        scrollBarWidth = 8,
        safeAreaPadding = 20
    },
    
    -- Tablet configurations
    TABLET = {
        minTouchSize = 36,
        maxMenuWidth = 0.7,
        fontSize = {
            small = 16,
            medium = 18,
            large = 22,
            title = 28
        },
        padding = {
            small = 12,
            medium = 16,
            large = 20
        },
        buttonHeight = 54,
        scrollBarWidth = 12,
        safeAreaPadding = 24
    },
    
    -- Desktop configurations (fallback)
    DESKTOP = {
        minTouchSize = 20,
        maxMenuWidth = 0.5,
        fontSize = {
            small = 12,
            medium = 14,
            large = 16,
            title = 20
        },
        padding = {
            small = 6,
            medium = 10,
            large = 14
        },
        buttonHeight = 36,
        scrollBarWidth = 16,
        safeAreaPadding = 10
    }
}

-- Device detection function
function MobileOptimizationService.detectDevice()
    -- Get screen size
    local camera = workspace.CurrentCamera
    local screenSize = camera.ViewportSize
    deviceInfo.screenSize = screenSize
    deviceInfo.aspectRatio = screenSize.X / screenSize.Y
    
    -- Check input capabilities
    deviceInfo.touchEnabled = UserInputService.TouchEnabled
    deviceInfo.accelerometerEnabled = UserInputService.AccelerometerEnabled
    deviceInfo.gyroscopeEnabled = UserInputService.GyroscopeEnabled
    
    -- Determine device type based on screen size and input
    local screenArea = screenSize.X * screenSize.Y
    
    if UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled then
        -- Mobile device
        if screenSize.X < 768 or screenSize.Y < 768 then
            deviceInfo.platform = "Phone"
            deviceInfo.isPhone = true
        else
            deviceInfo.platform = "Tablet"
            deviceInfo.isTablet = true
        end
    else
        -- Desktop/laptop
        deviceInfo.platform = "Desktop"
        deviceInfo.isDesktop = true
    end
    
    -- Get safe area information (for devices with notches, etc.)
    local safeArea = GuiService:GetSafeZone()
    deviceInfo.safeArea = {
        top = safeArea.Top,
        bottom = safeArea.Bottom,
        left = safeArea.Left,
        right = safeArea.Right
    }
    
    print(string.format("[Mobile] Detected device: %s (%dx%d)", 
        deviceInfo.platform, screenSize.X, screenSize.Y))
    
    return deviceInfo
end

-- Get current configuration based on device
function MobileOptimizationService.getCurrentConfig()
    if deviceInfo.isPhone then
        return MOBILE_CONFIG.PHONE
    elseif deviceInfo.isTablet then
        return MOBILE_CONFIG.TABLET
    else
        return MOBILE_CONFIG.DESKTOP
    end
end

-- Optimize UI element for mobile
function MobileOptimizationService.optimizeUIElement(element, options)
    if not element or not element:IsA("GuiBase2d") then
        return false
    end
    
    local config = MobileOptimizationService.getCurrentConfig()
    options = options or {}
    
    -- Apply size optimizations
    if options.minTouchSize ~= false and (deviceInfo.isPhone or deviceInfo.isTablet) then
        if element:IsA("GuiButton") or element:IsA("TextButton") or element:IsA("ImageButton") then
            local currentSize = element.AbsoluteSize
            local minSize = options.minTouchSize or config.minTouchSize
            
            if currentSize.X < minSize or currentSize.Y < minSize then
                element.Size = UDim2.new(
                    element.Size.X.Scale,
                    math.max(element.Size.X.Offset, minSize),
                    element.Size.Y.Scale,
                    math.max(element.Size.Y.Offset, minSize)
                )
            end
        end
    end
    
    -- Apply font size optimizations
    if element:IsA("TextLabel") or element:IsA("TextButton") or element:IsA("TextBox") then
        local fontSizeType = options.fontSize or "medium"
        local newFontSize = config.fontSize[fontSizeType] or config.fontSize.medium
        
        if element.TextScaled then
            -- Keep TextScaled but adjust constraints
            if not element:FindFirstChild("UITextSizeConstraint") then
                local constraint = Instance.new("UITextSizeConstraint")
                constraint.MinTextSize = math.max(8, newFontSize - 4)
                constraint.MaxTextSize = newFontSize + 6
                constraint.Parent = element
            end
        else
            element.TextSize = newFontSize
        end
    end
    
    -- Apply padding optimizations
    if options.padding and element:IsA("Frame") then
        local paddingType = options.padding or "medium"
        local paddingValue = config.padding[paddingType] or config.padding.medium
        
        local padding = element:FindFirstChild("UIPadding")
        if not padding then
            padding = Instance.new("UIPadding")
            padding.Parent = element
        end
        
        padding.PaddingTop = UDim.new(0, paddingValue)
        padding.PaddingBottom = UDim.new(0, paddingValue)
        padding.PaddingLeft = UDim.new(0, paddingValue)
        padding.PaddingRight = UDim.new(0, paddingValue)
    end
    
    -- Apply safe area constraints
    if options.respectSafeArea and element.Parent == playerGui then
        local safeAreaFrame = Instance.new("Frame")
        safeAreaFrame.Name = "SafeAreaFrame"
        safeAreaFrame.Size = UDim2.new(1, -deviceInfo.safeArea.left - deviceInfo.safeArea.right, 
                                      1, -deviceInfo.safeArea.top - deviceInfo.safeArea.bottom)
        safeAreaFrame.Position = UDim2.new(0, deviceInfo.safeArea.left, 0, deviceInfo.safeArea.top)
        safeAreaFrame.BackgroundTransparency = 1
        safeAreaFrame.Parent = element.Parent
        
        element.Parent = safeAreaFrame
    end
    
    return true
end

-- Create mobile-optimized button
function MobileOptimizationService.createMobileButton(properties)
    local config = MobileOptimizationService.getCurrentConfig()
    
    local button = Instance.new("TextButton")
    button.Size = properties.size or UDim2.new(0, 200, 0, config.buttonHeight)
    button.Position = properties.position or UDim2.new(0, 0, 0, 0)
    button.BackgroundColor3 = properties.backgroundColor or Color3.fromRGB(52, 152, 219)
    button.BorderSizePixel = 0
    button.Text = properties.text or "Button"
    button.TextColor3 = properties.textColor or Color3.fromRGB(255, 255, 255)
    button.TextSize = config.fontSize.medium
    button.Font = properties.font or Enum.Font.SourceSansBold
    button.AutoButtonColor = true
    
    -- Add corner rounding
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 8)
    corner.Parent = button
    
    -- Add padding
    local padding = Instance.new("UIPadding")
    padding.PaddingTop = UDim.new(0, config.padding.small)
    padding.PaddingBottom = UDim.new(0, config.padding.small)
    padding.PaddingLeft = UDim.new(0, config.padding.medium)
    padding.PaddingRight = UDim.new(0, config.padding.medium)
    padding.Parent = button
    
    -- Add touch feedback for mobile
    if deviceInfo.touchEnabled then
        local function addTouchFeedback()
            local originalColor = button.BackgroundColor3
            local darkerColor = Color3.fromRGB(
                math.max(0, originalColor.R * 255 - 30),
                math.max(0, originalColor.G * 255 - 30),
                math.max(0, originalColor.B * 255 - 30)
            )
            
            button.MouseButton1Down:Connect(function()
                button.BackgroundColor3 = darkerColor
            end)
            
            button.MouseButton1Up:Connect(function()
                button.BackgroundColor3 = originalColor
            end)
            
            button.MouseLeave:Connect(function()
                button.BackgroundColor3 = originalColor
            end)
        end
        addTouchFeedback()
    end
    
    if properties.parent then
        button.Parent = properties.parent
    end
    
    return button
end

-- Create mobile-optimized scrolling frame
function MobileOptimizationService.createMobileScrollFrame(properties)
    local config = MobileOptimizationService.getCurrentConfig()
    
    local scrollFrame = Instance.new("ScrollingFrame")
    scrollFrame.Size = properties.size or UDim2.new(1, 0, 1, 0)
    scrollFrame.Position = properties.position or UDim2.new(0, 0, 0, 0)
    scrollFrame.BackgroundColor3 = properties.backgroundColor or Color3.fromRGB(255, 255, 255)
    scrollFrame.BackgroundTransparency = properties.backgroundTransparency or 0
    scrollFrame.BorderSizePixel = 0
    scrollFrame.ScrollBarThickness = config.scrollBarWidth
    scrollFrame.ScrollBarImageColor3 = Color3.fromRGB(149, 165, 166)
    scrollFrame.ScrollBarImageTransparency = 0.5
    scrollFrame.CanvasSize = properties.canvasSize or UDim2.new(0, 0, 2, 0)
    scrollFrame.ScrollingDirection = properties.scrollingDirection or Enum.ScrollingDirection.Y
    
    -- Mobile-specific touch scrolling optimization
    if deviceInfo.touchEnabled then
        scrollFrame.ElasticBehavior = Enum.ElasticBehavior.WhenScrollable
        scrollFrame.ScrollingEnabled = true
        scrollFrame.TouchInputEnabled = true
    end
    
    -- Add list layout if specified
    if properties.useListLayout then
        local listLayout = Instance.new("UIListLayout")
        listLayout.FillDirection = properties.fillDirection or Enum.FillDirection.Vertical
        listLayout.HorizontalAlignment = properties.horizontalAlignment or Enum.HorizontalAlignment.Center
        listLayout.VerticalAlignment = properties.verticalAlignment or Enum.VerticalAlignment.Top
        listLayout.Padding = UDim.new(0, config.padding.small)
        listLayout.Parent = scrollFrame
        
        -- Auto-resize canvas
        listLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
            scrollFrame.CanvasSize = UDim2.new(0, 0, 0, listLayout.AbsoluteContentSize.Y + config.padding.medium)
        end)
    end
    
    if properties.parent then
        scrollFrame.Parent = properties.parent
    end
    
    return scrollFrame
end

-- Create mobile-optimized popup/modal
function MobileOptimizationService.createMobileModal(properties)
    local config = MobileOptimizationService.getCurrentConfig()
    
    -- Background overlay
    local overlay = Instance.new("Frame")
    overlay.Name = "ModalOverlay"
    overlay.Size = UDim2.new(1, 0, 1, 0)
    overlay.Position = UDim2.new(0, 0, 0, 0)
    overlay.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    overlay.BackgroundTransparency = 0.5
    overlay.ZIndex = 100
    overlay.Parent = playerGui
    
    -- Modal frame
    local modal = Instance.new("Frame")
    modal.Name = "Modal"
    modal.Size = UDim2.new(config.maxMenuWidth, 0, 0, properties.height or 400)
    modal.Position = UDim2.new((1 - config.maxMenuWidth) / 2, 0, 0.5, -(properties.height or 400) / 2)
    modal.BackgroundColor3 = properties.backgroundColor or Color3.fromRGB(255, 255, 255)
    modal.BorderSizePixel = 0
    modal.ZIndex = 101
    modal.Parent = overlay
    
    -- Corner rounding
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 12)
    corner.Parent = modal
    
    -- Safe area adjustment for mobile
    if deviceInfo.isPhone or deviceInfo.isTablet then
        modal.Size = UDim2.new(config.maxMenuWidth, -config.safeAreaPadding * 2, 0, properties.height or 400)
        modal.Position = UDim2.new((1 - config.maxMenuWidth) / 2, config.safeAreaPadding, 0.5, -(properties.height or 400) / 2)
    end
    
    -- Title bar
    if properties.title then
        local titleBar = Instance.new("Frame")
        titleBar.Name = "TitleBar"
        titleBar.Size = UDim2.new(1, 0, 0, 50)
        titleBar.Position = UDim2.new(0, 0, 0, 0)
        titleBar.BackgroundColor3 = properties.titleBackgroundColor or Color3.fromRGB(52, 73, 94)
        titleBar.BorderSizePixel = 0
        titleBar.Parent = modal
        
        local titleCorner = Instance.new("UICorner")
        titleCorner.CornerRadius = UDim.new(0, 12)
        titleCorner.Parent = titleBar
        
        local titleLabel = Instance.new("TextLabel")
        titleLabel.Size = UDim2.new(1, -60, 1, 0)
        titleLabel.Position = UDim2.new(0, 20, 0, 0)
        titleLabel.BackgroundTransparency = 1
        titleLabel.Text = properties.title
        titleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
        titleLabel.TextSize = config.fontSize.title
        titleLabel.Font = Enum.Font.SourceSansBold
        titleLabel.TextXAlignment = Enum.TextXAlignment.Left
        titleLabel.Parent = titleBar
        
        -- Close button
        local closeButton = MobileOptimizationService.createMobileButton({
            size = UDim2.new(0, 40, 0, 40),
            position = UDim2.new(1, -50, 0, 5),
            backgroundColor = Color3.fromRGB(231, 76, 60),
            text = "✕",
            textColor = Color3.fromRGB(255, 255, 255),
            parent = titleBar
        })
        
        closeButton.MouseButton1Click:Connect(function()
            MobileOptimizationService.closeMobileModal(overlay)
        end)
    end
    
    -- Content area
    local contentArea = Instance.new("Frame")
    contentArea.Name = "ContentArea"
    contentArea.Size = UDim2.new(1, 0, 1, properties.title and -50 or 0)
    contentArea.Position = UDim2.new(0, 0, 0, properties.title and 50 or 0)
    contentArea.BackgroundTransparency = 1
    contentArea.Parent = modal
    
    -- Add padding to content area
    local padding = Instance.new("UIPadding")
    padding.PaddingTop = UDim.new(0, config.padding.large)
    padding.PaddingBottom = UDim.new(0, config.padding.large)
    padding.PaddingLeft = UDim.new(0, config.padding.large)
    padding.PaddingRight = UDim.new(0, config.padding.large)
    padding.Parent = contentArea
    
    -- Animation
    modal.Size = UDim2.new(0, 0, 0, 0)
    modal.Position = UDim2.new(0.5, 0, 0.5, 0)
    
    local showTween = TweenService:Create(modal,
        TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
        {
            Size = UDim2.new(config.maxMenuWidth, deviceInfo.isPhone and -config.safeAreaPadding * 2 or 0, 0, properties.height or 400),
            Position = UDim2.new((1 - config.maxMenuWidth) / 2, deviceInfo.isPhone and config.safeAreaPadding or 0, 0.5, -(properties.height or 400) / 2)
        }
    )
    showTween:Play()
    
    -- Close on background tap (mobile-friendly)
    if properties.closeOnBackgroundTap ~= false then
        overlay.MouseButton1Click:Connect(function()
            MobileOptimizationService.closeMobileModal(overlay)
        end)
        
        modal.MouseButton1Click:Connect(function()
            -- Prevent event bubbling
        end)
    end
    
    return {
        overlay = overlay,
        modal = modal,
        contentArea = contentArea
    }
end

-- Close mobile modal with animation
function MobileOptimizationService.closeMobileModal(overlay)
    local modal = overlay:FindFirstChild("Modal")
    if modal then
        local closeTween = TweenService:Create(modal,
            TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
            {
                Size = UDim2.new(0, 0, 0, 0),
                Position = UDim2.new(0.5, 0, 0.5, 0)
            }
        )
        
        closeTween:Play()
        closeTween.Completed:Connect(function()
            overlay:Destroy()
        end)
    else
        overlay:Destroy()
    end
end

-- Auto-optimize existing UI elements
function MobileOptimizationService.optimizeExistingUI()
    local function optimizeGuiDescendants(gui)
        for _, child in pairs(gui:GetDescendants()) do
            if child:IsA("GuiButton") or child:IsA("TextButton") or child:IsA("ImageButton") then
                MobileOptimizationService.optimizeUIElement(child, {fontSize = "medium"})
            elseif child:IsA("TextLabel") then
                MobileOptimizationService.optimizeUIElement(child, {fontSize = "medium"})
            elseif child:IsA("Frame") and child.Name:match("Menu") or child.Name:match("Panel") then
                MobileOptimizationService.optimizeUIElement(child, {padding = "medium"})
            end
        end
    end
    
    -- Optimize all existing GUIs
    for _, gui in pairs(playerGui:GetChildren()) do
        if gui:IsA("ScreenGui") then
            optimizeGuiDescendants(gui)
        end
    end
    
    -- Watch for new GUIs
    playerGui.ChildAdded:Connect(function(child)
        if child:IsA("ScreenGui") then
            task.wait(0.1) -- Allow GUI to fully load
            optimizeGuiDescendants(child)
        end
    end)
end

-- Get device-specific layout properties
function MobileOptimizationService.getLayoutProperties()
    local config = MobileOptimizationService.getCurrentConfig()
    
    return {
        deviceType = deviceInfo.platform,
        config = config,
        screenSize = deviceInfo.screenSize,
        safeArea = deviceInfo.safeArea,
        touchEnabled = deviceInfo.touchEnabled,
        
        -- Helper functions
        getResponsiveSize = function(baseSize, mobileMultiplier)
            mobileMultiplier = mobileMultiplier or 1.2
            if deviceInfo.isPhone or deviceInfo.isTablet then
                return UDim2.new(
                    baseSize.X.Scale * mobileMultiplier,
                    baseSize.X.Offset * mobileMultiplier,
                    baseSize.Y.Scale * mobileMultiplier, 
                    baseSize.Y.Offset * mobileMultiplier
                )
            end
            return baseSize
        end,
        
        getResponsivePosition = function(basePosition, safeAreaAdjustment)
            if (deviceInfo.isPhone or deviceInfo.isTablet) and safeAreaAdjustment then
                return UDim2.new(
                    basePosition.X.Scale,
                    basePosition.X.Offset + deviceInfo.safeArea.left,
                    basePosition.Y.Scale,
                    basePosition.Y.Offset + deviceInfo.safeArea.top
                )
            end
            return basePosition
        end
    }
end

-- Initialize mobile optimization
function MobileOptimizationService.initialize()
    -- Detect device
    MobileOptimizationService.detectDevice()
    
    -- Optimize existing UI
    MobileOptimizationService.optimizeExistingUI()
    
    -- Listen for screen size changes (rotation)
    workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(function()
        MobileOptimizationService.detectDevice()
        MobileOptimizationService.optimizeExistingUI()
        
        -- Notify other systems of orientation change
        if RemoteEvents.DeviceOrientationChanged then
            RemoteEvents.DeviceOrientationChanged:FireServer(deviceInfo)
        end
    end)
    
    print("[Mobile] Mobile optimization initialized for", deviceInfo.platform)
end

-- Auto-initialize
MobileOptimizationService.initialize()

-- Export service
return MobileOptimizationService
