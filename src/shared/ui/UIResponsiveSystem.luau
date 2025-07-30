-- UIResponsiveSystem.luau
-- Comprehensive responsive design system for cross-device UI adaptation
-- Handles viewport changes, device detection, and layout optimization

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local GuiService = game:GetService("GuiService")
local RunService = game:GetService("RunService")

local SafeRequire = require(ReplicatedStorage.Shared.utils.SafeRequire)
local UIDesignTokens = SafeRequire.require(ReplicatedStorage.Shared.ui.UIDesignTokens)

local UIResponsiveSystem = {}

-- ========================================
-- RESPONSIVE CONFIGURATION
-- ========================================

local BREAKPOINTS = {
    xs = 0,     -- Extra small devices (phones in portrait)
    sm = 576,   -- Small devices (phones in landscape)
    md = 768,   -- Medium devices (tablets)
    lg = 992,   -- Large devices (small laptops)
    xl = 1200,  -- Extra large devices (laptops/desktops)
    xxl = 1400  -- Extra extra large devices (large desktops)
}

local DEVICE_TYPES = {
    phone = {
        maxWidth = 767,
        orientation = "portrait",
        touchPrimary = true,
        density = "high"
    },
    phoneLandscape = {
        minWidth = 568,
        maxWidth = 767,
        orientation = "landscape", 
        touchPrimary = true,
        density = "high"
    },
    tablet = {
        minWidth = 768,
        maxWidth = 1023,
        touchPrimary = true,
        density = "medium"
    },
    laptop = {
        minWidth = 1024,
        maxWidth = 1439,
        touchPrimary = false,
        density = "medium"
    },
    desktop = {
        minWidth = 1440,
        touchPrimary = false,
        density = "low"
    },
    tv = {
        minWidth = 1920,
        touchPrimary = false,
        density = "low",
        tenFoot = true
    }
}

local LAYOUT_STRATEGIES = {
    -- Stack layout (mobile-first)
    stack = {
        phone = {direction = "vertical", spacing = "sm", padding = "md"},
        tablet = {direction = "vertical", spacing = "md", padding = "lg"},
        desktop = {direction = "horizontal", spacing = "lg", padding = "xl"}
    },
    
    -- Grid layout
    grid = {
        phone = {columns = 1, gap = "sm", padding = "md"},
        tablet = {columns = 2, gap = "md", padding = "lg"},
        desktop = {columns = 3, gap = "lg", padding = "xl"}
    },
    
    -- Sidebar layout
    sidebar = {
        phone = {sidebar = "hidden", content = "full"},
        tablet = {sidebar = "overlay", content = "full"},
        desktop = {sidebar = "fixed", content = "remaining"}
    },
    
    -- Navigation layout
    navigation = {
        phone = {type = "bottom", collapsible = true},
        tablet = {type = "top", collapsible = false},
        desktop = {type = "top", collapsible = false}
    }
}

-- ========================================
-- RESPONSIVE SYSTEM CORE
-- ========================================

local ResponsiveManager = {
    currentBreakpoint = "md",
    currentDeviceType = "desktop",
    currentViewport = Vector2.new(1920, 1080),
    isLandscape = true,
    isTouchDevice = false,
    isTenFootInterface = false,
    pixelDensity = 1,
    
    -- Callbacks
    breakpointCallbacks = {},
    orientationCallbacks = {},
    deviceTypeCallbacks = {},
    
    -- Layout managers
    responsiveElements = {},
    gridSystems = {},
    
    -- Performance
    updateThrottle = 0.1,
    lastUpdate = 0
}

function UIResponsiveSystem.initialize()
    -- Get initial viewport and device info
    UIResponsiveSystem.updateViewportInfo()
    
    -- Set up viewport change detection
    workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(function()
        UIResponsiveSystem.throttledUpdate()
    end)
    
    -- Set up orientation change detection
    UserInputService:GetPropertyChangedSignal("TouchEnabled"):Connect(function()
        UIResponsiveSystem.updateViewportInfo()
    end)
    
    print("📱 UIResponsiveSystem initialized - Device: " .. ResponsiveManager.currentDeviceType .. 
          ", Breakpoint: " .. ResponsiveManager.currentBreakpoint)
end

function UIResponsiveSystem.throttledUpdate()
    local now = tick()
    if now - ResponsiveManager.lastUpdate < ResponsiveManager.updateThrottle then
        return
    end
    
    ResponsiveManager.lastUpdate = now
    UIResponsiveSystem.updateViewportInfo()
end

function UIResponsiveSystem.updateViewportInfo()
    local camera = workspace.CurrentCamera
    local viewport = camera.ViewportSize
    
    local previousBreakpoint = ResponsiveManager.currentBreakpoint
    local previousDeviceType = ResponsiveManager.currentDeviceType
    local previousOrientation = ResponsiveManager.isLandscape
    
    -- Update viewport info
    ResponsiveManager.currentViewport = viewport
    ResponsiveManager.isLandscape = viewport.X > viewport.Y
    ResponsiveManager.isTouchDevice = UserInputService.TouchEnabled and not UserInputService.MouseEnabled
    ResponsiveManager.isTenFootInterface = GuiService:IsTenFootInterface()
    
    -- Determine breakpoint
    ResponsiveManager.currentBreakpoint = UIResponsiveSystem.getBreakpoint(viewport.X)
    
    -- Determine device type
    ResponsiveManager.currentDeviceType = UIResponsiveSystem.getDeviceType()
    
    -- Estimate pixel density
    ResponsiveManager.pixelDensity = UIResponsiveSystem.estimatePixelDensity()
    
    -- Trigger callbacks if changed
    if previousBreakpoint ~= ResponsiveManager.currentBreakpoint then
        UIResponsiveSystem.notifyBreakpointChange(ResponsiveManager.currentBreakpoint, previousBreakpoint)
    end
    
    if previousDeviceType ~= ResponsiveManager.currentDeviceType then
        UIResponsiveSystem.notifyDeviceTypeChange(ResponsiveManager.currentDeviceType, previousDeviceType)
    end
    
    if previousOrientation ~= ResponsiveManager.isLandscape then
        UIResponsiveSystem.notifyOrientationChange(ResponsiveManager.isLandscape)
    end
    
    -- Update responsive elements
    UIResponsiveSystem.updateResponsiveElements()
end

-- ========================================
-- BREAKPOINT AND DEVICE DETECTION
-- ========================================

function UIResponsiveSystem.getBreakpoint(width)
    if width >= BREAKPOINTS.xxl then
        return "xxl"
    elseif width >= BREAKPOINTS.xl then
        return "xl"
    elseif width >= BREAKPOINTS.lg then
        return "lg"
    elseif width >= BREAKPOINTS.md then
        return "md"
    elseif width >= BREAKPOINTS.sm then
        return "sm"
    else
        return "xs"
    end
end

function UIResponsiveSystem.getDeviceType()
    local viewport = ResponsiveManager.currentViewport
    local width = viewport.X
    local height = viewport.Y
    local isLandscape = ResponsiveManager.isLandscape
    local isTouchDevice = ResponsiveManager.isTouchDevice
    local isTenFootInterface = ResponsiveManager.isTenFootInterface
    
    -- Console/TV detection
    if isTenFootInterface or width >= 1920 then
        return "tv"
    end
    
    -- Touch device detection
    if isTouchDevice then
        if width <= 767 then
            return isLandscape and "phoneLandscape" or "phone"
        elseif width <= 1023 then
            return "tablet"
        end
    end
    
    -- Desktop/laptop detection
    if width >= 1440 then
        return "desktop"
    elseif width >= 1024 then
        return "laptop"
    elseif width >= 768 then
        return "tablet"
    else
        return "phone"
    end
end

function UIResponsiveSystem.estimatePixelDensity()
    local viewport = ResponsiveManager.currentViewport
    local deviceType = ResponsiveManager.currentDeviceType
    
    -- Rough estimation based on device type and viewport
    if deviceType == "phone" or deviceType == "phoneLandscape" then
        return 2.0 -- High density
    elseif deviceType == "tablet" then
        return 1.5 -- Medium-high density
    elseif deviceType == "tv" then
        return 0.8 -- Low density, large screen
    else
        return 1.0 -- Standard density
    end
end

-- ========================================
-- RESPONSIVE UTILITIES
-- ========================================

function UIResponsiveSystem.getResponsiveValue(breakpointValues, defaultValue)
    local currentBreakpoint = ResponsiveManager.currentBreakpoint
    
    -- Try exact match first
    if breakpointValues[currentBreakpoint] then
        return breakpointValues[currentBreakpoint]
    end
    
    -- Fall back to smaller breakpoints
    local breakpointOrder = {"xxl", "xl", "lg", "md", "sm", "xs"}
    local currentIndex = table.find(breakpointOrder, currentBreakpoint)
    
    if currentIndex then
        for i = currentIndex + 1, #breakpointOrder do
            local fallbackBreakpoint = breakpointOrder[i]
            if breakpointValues[fallbackBreakpoint] then
                return breakpointValues[fallbackBreakpoint]
            end
        end
    end
    
    return defaultValue
end

function UIResponsiveSystem.getDeviceValue(deviceValues, defaultValue)
    local currentDevice = ResponsiveManager.currentDeviceType
    
    if deviceValues[currentDevice] then
        return deviceValues[currentDevice]
    end
    
    return defaultValue
end

function UIResponsiveSystem.isBreakpointOrLarger(breakpoint)
    local breakpointOrder = {"xs", "sm", "md", "lg", "xl", "xxl"}
    local currentIndex = table.find(breakpointOrder, ResponsiveManager.currentBreakpoint)
    local targetIndex = table.find(breakpointOrder, breakpoint)
    
    return currentIndex and targetIndex and currentIndex >= targetIndex
end

function UIResponsiveSystem.isBreakpointOrSmaller(breakpoint)
    local breakpointOrder = {"xs", "sm", "md", "lg", "xl", "xxl"}
    local currentIndex = table.find(breakpointOrder, ResponsiveManager.currentBreakpoint)
    local targetIndex = table.find(breakpointOrder, breakpoint)
    
    return currentIndex and targetIndex and currentIndex <= targetIndex
end

-- ========================================
-- RESPONSIVE ELEMENT MANAGEMENT
-- ========================================

function UIResponsiveSystem.createResponsiveElement(config)
    local element = config.element
    if not element then
        warn("No element provided for responsive configuration")
        return nil
    end
    
    local responsiveConfig = {
        element = element,
        
        -- Size configurations per breakpoint
        sizes = config.sizes or {},
        
        -- Position configurations per breakpoint  
        positions = config.positions or {},
        
        -- Visibility configurations per breakpoint
        visibility = config.visibility or {},
        
        -- Text size configurations per breakpoint
        textSizes = config.textSizes or {},
        
        -- Padding configurations per breakpoint
        padding = config.padding or {},
        
        -- Custom property configurations
        customProperties = config.customProperties or {},
        
        -- Callbacks
        onBreakpointChange = config.onBreakpointChange,
        onDeviceTypeChange = config.onDeviceTypeChange,
        onOrientationChange = config.onOrientationChange
    }
    
    -- Register element
    local elementId = UIResponsiveSystem.generateElementId()
    ResponsiveManager.responsiveElements[elementId] = responsiveConfig
    
    -- Apply initial configuration
    UIResponsiveSystem.updateElementForCurrentBreakpoint(responsiveConfig)
    
    return {
        id = elementId,
        update = function()
            UIResponsiveSystem.updateElementForCurrentBreakpoint(responsiveConfig)
        end,
        destroy = function()
            ResponsiveManager.responsiveElements[elementId] = nil
        end,
        setSize = function(breakpointSizes)
            responsiveConfig.sizes = breakpointSizes
            UIResponsiveSystem.updateElementForCurrentBreakpoint(responsiveConfig)
        end,
        setVisibility = function(breakpointVisibility)
            responsiveConfig.visibility = breakpointVisibility
            UIResponsiveSystem.updateElementForCurrentBreakpoint(responsiveConfig)
        end
    }
end

function UIResponsiveSystem.updateElementForCurrentBreakpoint(config)
    local element = config.element
    if not element or not element.Parent then
        return
    end
    
    local currentBreakpoint = ResponsiveManager.currentBreakpoint
    local currentDevice = ResponsiveManager.currentDeviceType
    
    -- Update size
    if config.sizes then
        local newSize = UIResponsiveSystem.getResponsiveValue(config.sizes)
        if newSize then
            element.Size = newSize
        end
    end
    
    -- Update position
    if config.positions then
        local newPosition = UIResponsiveSystem.getResponsiveValue(config.positions)
        if newPosition then
            element.Position = newPosition
        end
    end
    
    -- Update visibility
    if config.visibility then
        local isVisible = UIResponsiveSystem.getResponsiveValue(config.visibility, true)
        element.Visible = isVisible
    end
    
    -- Update text size
    if config.textSizes and element:IsA("TextLabel") or element:IsA("TextButton") or element:IsA("TextBox") then
        local newTextSize = UIResponsiveSystem.getResponsiveValue(config.textSizes)
        if newTextSize then
            element.TextSize = newTextSize
        end
    end
    
    -- Update padding
    if config.padding then
        local paddingConfig = UIResponsiveSystem.getResponsiveValue(config.padding)
        if paddingConfig then
            local uiPadding = element:FindFirstChildOfClass("UIPadding")
            if not uiPadding then
                uiPadding = Instance.new("UIPadding")
                uiPadding.Parent = element
            end
            
            if type(paddingConfig) == "table" then
                uiPadding.PaddingTop = UDim.new(0, paddingConfig.top or paddingConfig.all or 0)
                uiPadding.PaddingBottom = UDim.new(0, paddingConfig.bottom or paddingConfig.all or 0)
                uiPadding.PaddingLeft = UDim.new(0, paddingConfig.left or paddingConfig.all or 0)
                uiPadding.PaddingRight = UDim.new(0, paddingConfig.right or paddingConfig.all or 0)
            else
                local value = paddingConfig
                uiPadding.PaddingTop = UDim.new(0, value)
                uiPadding.PaddingBottom = UDim.new(0, value)
                uiPadding.PaddingLeft = UDim.new(0, value)
                uiPadding.PaddingRight = UDim.new(0, value)
            end
        end
    end
    
    -- Update custom properties
    if config.customProperties then
        local customConfig = UIResponsiveSystem.getResponsiveValue(config.customProperties)
        if customConfig then
            for property, value in pairs(customConfig) do
                if element[property] ~= nil then
                    element[property] = value
                end
            end
        end
    end
    
    -- Call callbacks
    if config.onBreakpointChange then
        pcall(config.onBreakpointChange, currentBreakpoint, currentDevice)
    end
end

function UIResponsiveSystem.updateResponsiveElements()
    for _, config in pairs(ResponsiveManager.responsiveElements) do
        UIResponsiveSystem.updateElementForCurrentBreakpoint(config)
    end
end

-- ========================================
-- GRID SYSTEM
-- ========================================

function UIResponsiveSystem.createResponsiveGrid(config)
    local container = config.container
    if not container then
        warn("No container provided for responsive grid")
        return nil
    end
    
    local gridConfig = {
        container = container,
        
        -- Columns per breakpoint
        columns = config.columns or {
            xs = 1, sm = 1, md = 2, lg = 3, xl = 4, xxl = 4
        },
        
        -- Gap between items per breakpoint
        gap = config.gap or {
            xs = 8, sm = 12, md = 16, lg = 20, xl = 24, xxl = 24
        },
        
        -- Padding around grid per breakpoint
        padding = config.padding or {
            xs = 16, sm = 20, md = 24, lg = 32, xl = 40, xxl = 40
        },
        
        -- Item aspect ratio (optional)
        aspectRatio = config.aspectRatio,
        
        -- Auto-sizing
        autoSize = config.autoSize ~= false
    }
    
    -- Create or get UI grid layout
    local gridLayout = container:FindFirstChildOfClass("UIGridLayout")
    if not gridLayout then
        gridLayout = Instance.new("UIGridLayout")
        gridLayout.Parent = container
    end
    
    -- Create or get UI padding
    local uiPadding = container:FindFirstChildOfClass("UIPadding")
    if not uiPadding then
        uiPadding = Instance.new("UIPadding")
        uiPadding.Parent = container
    end
    
    -- Function to update grid layout
    local function updateGrid()
        local currentBreakpoint = ResponsiveManager.currentBreakpoint
        local viewport = ResponsiveManager.currentViewport
        
        -- Get responsive values
        local columns = UIResponsiveSystem.getResponsiveValue(gridConfig.columns, 1)
        local gap = UIResponsiveSystem.getResponsiveValue(gridConfig.gap, 16)
        local padding = UIResponsiveSystem.getResponsiveValue(gridConfig.padding, 16)
        
        -- Update padding
        uiPadding.PaddingLeft = UDim.new(0, padding)
        uiPadding.PaddingRight = UDim.new(0, padding)
        uiPadding.PaddingTop = UDim.new(0, padding)
        uiPadding.PaddingBottom = UDim.new(0, padding)
        
        -- Calculate cell size
        local availableWidth = viewport.X - (padding * 2)
        local cellWidth = (availableWidth - (gap * (columns - 1))) / columns
        
        local cellHeight = cellWidth
        if gridConfig.aspectRatio then
            cellHeight = cellWidth / gridConfig.aspectRatio
        end
        
        -- Update grid layout
        gridLayout.CellSize = UDim2.new(0, cellWidth, 0, cellHeight)
        gridLayout.CellPadding = UDim2.new(0, gap, 0, gap)
        gridLayout.SortOrder = Enum.SortOrder.LayoutOrder
        gridLayout.FillDirection = Enum.FillDirection.Horizontal
        gridLayout.HorizontalAlignment = Enum.HorizontalAlignment.Left
        gridLayout.VerticalAlignment = Enum.VerticalAlignment.Top
        
        -- Auto-size container if enabled
        if gridConfig.autoSize then
            local contentSize = gridLayout.AbsoluteContentSize
            container.Size = UDim2.new(container.Size.X.Scale, container.Size.X.Offset, 0, contentSize.Y + padding * 2)
        end
    end
    
    -- Register grid for updates
    local gridId = UIResponsiveSystem.generateElementId()
    ResponsiveManager.gridSystems[gridId] = {
        config = gridConfig,
        update = updateGrid
    }
    
    -- Initial update
    updateGrid()
    
    -- Listen for content changes
    gridLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        if gridConfig.autoSize then
            local contentSize = gridLayout.AbsoluteContentSize
            local padding = UIResponsiveSystem.getResponsiveValue(gridConfig.padding, 16)
            container.Size = UDim2.new(container.Size.X.Scale, container.Size.X.Offset, 0, contentSize.Y + padding * 2)
        end
    end)
    
    return {
        id = gridId,
        update = updateGrid,
        destroy = function()
            ResponsiveManager.gridSystems[gridId] = nil
        end,
        setColumns = function(columnConfig)
            gridConfig.columns = columnConfig
            updateGrid()
        end,
        setGap = function(gapConfig)
            gridConfig.gap = gapConfig
            updateGrid()
        end
    }
end

-- ========================================
-- LAYOUT HELPERS
-- ========================================

function UIResponsiveSystem.createStackLayout(config)
    local container = config.container
    if not container then
        warn("No container provided for stack layout")
        return nil
    end
    
    -- Get layout strategy
    local strategy = LAYOUT_STRATEGIES.stack
    local currentDevice = ResponsiveManager.currentDeviceType
    local deviceStrategy = strategy[currentDevice] or strategy.desktop
    
    -- Create list layout
    local listLayout = container:FindFirstChildOfClass("UIListLayout")
    if not listLayout then
        listLayout = Instance.new("UIListLayout")
        listLayout.Parent = container
    end
    
    -- Configure layout
    listLayout.FillDirection = deviceStrategy.direction == "vertical" and Enum.FillDirection.Vertical or Enum.FillDirection.Horizontal
    listLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
    listLayout.VerticalAlignment = Enum.VerticalAlignment.Top
    listLayout.SortOrder = Enum.SortOrder.LayoutOrder
    
    -- Set spacing
    local tokens = UIDesignTokens.getTokens()
    local spacing = tokens.spacing[deviceStrategy.spacing] or tokens.spacing.md
    listLayout.Padding = UDim.new(0, spacing)
    
    -- Set container padding
    local uiPadding = container:FindFirstChildOfClass("UIPadding")
    if not uiPadding then
        uiPadding = Instance.new("UIPadding")
        uiPadding.Parent = container
    end
    
    local containerPadding = tokens.spacing[deviceStrategy.padding] or tokens.spacing.lg
    uiPadding.PaddingLeft = UDim.new(0, containerPadding)
    uiPadding.PaddingRight = UDim.new(0, containerPadding)
    uiPadding.PaddingTop = UDim.new(0, containerPadding)
    uiPadding.PaddingBottom = UDim.new(0, containerPadding)
    
    return listLayout
end

function UIResponsiveSystem.createSidebarLayout(config)
    local container = config.container
    if not container then
        warn("No container provided for sidebar layout")
        return nil
    end
    
    local strategy = LAYOUT_STRATEGIES.sidebar
    local currentDevice = ResponsiveManager.currentDeviceType
    local deviceStrategy = strategy[currentDevice] or strategy.desktop
    
    -- Create sidebar and content frames
    local sidebar = container:FindFirstChild("Sidebar") or Instance.new("Frame")
    sidebar.Name = "Sidebar"
    sidebar.Parent = container
    
    local content = container:FindFirstChild("Content") or Instance.new("Frame")
    content.Name = "Content"
    content.Parent = container
    
    -- Configure based on device strategy
    if deviceStrategy.sidebar == "hidden" then
        sidebar.Visible = false
        content.Size = UDim2.new(1, 0, 1, 0)
        content.Position = UDim2.new(0, 0, 0, 0)
        
    elseif deviceStrategy.sidebar == "overlay" then
        sidebar.Size = UDim2.new(0, 280, 1, 0)
        sidebar.Position = UDim2.new(0, -280, 0, 0) -- Hidden by default
        content.Size = UDim2.new(1, 0, 1, 0)
        content.Position = UDim2.new(0, 0, 0, 0)
        
    elseif deviceStrategy.sidebar == "fixed" then
        sidebar.Size = UDim2.new(0, 280, 1, 0)
        sidebar.Position = UDim2.new(0, 0, 0, 0)
        content.Size = UDim2.new(1, -280, 1, 0)
        content.Position = UDim2.new(0, 280, 0, 0)
    end
    
    return {
        sidebar = sidebar,
        content = content,
        toggleSidebar = function()
            if deviceStrategy.sidebar == "overlay" then
                local isVisible = sidebar.Position.X.Offset >= 0
                sidebar.Position = UDim2.new(0, isVisible and -280 or 0, 0, 0)
            end
        end
    }
end

-- ========================================
-- EVENT SYSTEM
-- ========================================

function UIResponsiveSystem.onBreakpointChange(callback)
    table.insert(ResponsiveManager.breakpointCallbacks, callback)
    
    return function()
        local index = table.find(ResponsiveManager.breakpointCallbacks, callback)
        if index then
            table.remove(ResponsiveManager.breakpointCallbacks, index)
        end
    end
end

function UIResponsiveSystem.onDeviceTypeChange(callback)
    table.insert(ResponsiveManager.deviceTypeCallbacks, callback)
    
    return function()
        local index = table.find(ResponsiveManager.deviceTypeCallbacks, callback)
        if index then
            table.remove(ResponsiveManager.deviceTypeCallbacks, index)
        end
    end
end

function UIResponsiveSystem.onOrientationChange(callback)
    table.insert(ResponsiveManager.orientationCallbacks, callback)
    
    return function()
        local index = table.find(ResponsiveManager.orientationCallbacks, callback)
        if index then
            table.remove(ResponsiveManager.orientationCallbacks, index)
        end
    end
end

function UIResponsiveSystem.notifyBreakpointChange(newBreakpoint, previousBreakpoint)
    for _, callback in ipairs(ResponsiveManager.breakpointCallbacks) do
        pcall(callback, newBreakpoint, previousBreakpoint)
    end
    
    print("📱 Breakpoint changed: " .. previousBreakpoint .. " → " .. newBreakpoint)
end

function UIResponsiveSystem.notifyDeviceTypeChange(newDeviceType, previousDeviceType)
    for _, callback in ipairs(ResponsiveManager.deviceTypeCallbacks) do
        pcall(callback, newDeviceType, previousDeviceType)
    end
    
    print("📱 Device type changed: " .. previousDeviceType .. " → " .. newDeviceType)
end

function UIResponsiveSystem.notifyOrientationChange(isLandscape)
    for _, callback in ipairs(ResponsiveManager.orientationCallbacks) do
        pcall(callback, isLandscape and "landscape" or "portrait")
    end
    
    print("📱 Orientation changed: " .. (isLandscape and "landscape" or "portrait"))
end

-- ========================================
-- UTILITY FUNCTIONS
-- ========================================

function UIResponsiveSystem.generateElementId()
    return "responsive_" .. tick() .. "_" .. math.random(1000, 9999)
end

function UIResponsiveSystem.getCurrentBreakpoint()
    return ResponsiveManager.currentBreakpoint
end

function UIResponsiveSystem.getCurrentDeviceType()
    return ResponsiveManager.currentDeviceType
end

function UIResponsiveSystem.getCurrentViewport()
    return ResponsiveManager.currentViewport
end

function UIResponsiveSystem.getDeviceInfo()
    return {
        breakpoint = ResponsiveManager.currentBreakpoint,
        deviceType = ResponsiveManager.currentDeviceType,
        viewport = ResponsiveManager.currentViewport,
        isLandscape = ResponsiveManager.isLandscape,
        isTouchDevice = ResponsiveManager.isTouchDevice,
        isTenFootInterface = ResponsiveManager.isTenFootInterface,
        pixelDensity = ResponsiveManager.pixelDensity
    }
end

function UIResponsiveSystem.isMobile()
    local deviceType = ResponsiveManager.currentDeviceType
    return deviceType == "phone" or deviceType == "phoneLandscape"
end

function UIResponsiveSystem.isTablet()
    return ResponsiveManager.currentDeviceType == "tablet"
end

function UIResponsiveSystem.isDesktop()
    local deviceType = ResponsiveManager.currentDeviceType
    return deviceType == "laptop" or deviceType == "desktop" or deviceType == "tv"
end

function UIResponsiveSystem.isTouchPrimary()
    return ResponsiveManager.isTouchDevice
end

function UIResponsiveSystem.getBreakpoints()
    return BREAKPOINTS
end

function UIResponsiveSystem.getDeviceTypes()
    return DEVICE_TYPES
end

function UIResponsiveSystem.getLayoutStrategies()
    return LAYOUT_STRATEGIES
end

-- Initialize the responsive system
UIResponsiveSystem.initialize()

print("📱 UIResponsiveSystem initialized for cross-device compatibility")

return UIResponsiveSystem
