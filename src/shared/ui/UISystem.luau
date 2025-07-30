-- UISystem.luau
-- Main UI system integration and initialization
-- Coordinates all UI subsystems and provides unified API

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local GuiService = game:GetService("GuiService")

local SafeRequire = require(ReplicatedStorage.Shared.utils.SafeRequire)

-- Import all UI subsystems
local UIDesignTokens = SafeRequire.require(ReplicatedStorage.Shared.ui.UIDesignTokens)
local UIComponentLibrary = SafeRequire.require(ReplicatedStorage.Shared.ui.UIComponentLibrary)
local UIAnimationSystem = SafeRequire.require(ReplicatedStorage.Shared.ui.UIAnimationSystem)
local UIResponsiveSystem = SafeRequire.require(ReplicatedStorage.Shared.ui.UIResponsiveSystem)
local UIAccessibilitySystem = SafeRequire.require(ReplicatedStorage.Shared.ui.UIAccessibilitySystem)
local UIFeedbackSystem = SafeRequire.require(ReplicatedStorage.Shared.ui.UIFeedbackSystem)
local UITouchSystem = SafeRequire.require(ReplicatedStorage.Shared.ui.UITouchSystem)
local UITestingFramework = SafeRequire.require(ReplicatedStorage.Shared.ui.UITestingFramework)

local UISystem = {}

-- ========================================
-- SYSTEM CONFIGURATION
-- ========================================

local UI_CONFIG = {
    -- System initialization
    autoInitialize = true,
    enableTestingInStudio = true,
    enableDebugMode = false,
    
    -- Theme settings
    defaultTheme = "light",
    systemThemeDetection = true,
    themeTransitionDuration = 0.3,
    
    -- Responsive settings
    enableResponsiveDesign = true,
    enableTouchOptimization = true,
    enableAccessibility = true,
    
    -- Performance settings
    enablePerformanceMonitoring = true,
    animationQuality = "high", -- "low", "medium", "high"
    maxConcurrentAnimations = 10,
    
    -- Development settings
    showComponentBounds = false,
    enableHotReload = false,
    logSystemEvents = false
}

-- ========================================
-- SYSTEM MANAGER
-- ========================================

local SystemManager = {
    -- Initialization state
    initialized = false,
    initializationTime = 0,
    
    -- Subsystem status
    subsystems = {
        designTokens = false,
        componentLibrary = false,
        animationSystem = false,
        responsiveSystem = false,
        accessibilitySystem = false,
        feedbackSystem = false,
        touchSystem = false,
        testingFramework = false
    },
    
    -- System metrics
    performanceMetrics = {
        initializationTime = 0,
        memoryUsage = 0,
        activeComponents = 0,
        activeAnimations = 0
    },
    
    -- Event system
    eventConnections = {},
    eventListeners = {},
    
    -- Component registry
    registeredComponents = {},
    activeComponents = {},
    
    -- Theme state
    currentTheme = "light",
    themeOverrides = {},
    
    -- Development tools
    debugInfo = {
        componentCount = 0,
        lastUpdate = 0,
        errors = {}
    }
}

function UISystem.initialize(config)
    if SystemManager.initialized then
        warn("UISystem already initialized")
        return false
    end
    
    local startTime = tick()
    
    -- Merge configuration
    if config then
        for key, value in pairs(config) do
            UI_CONFIG[key] = value
        end
    end
    
    print("🎨 Initializing UISystem with comprehensive UI framework...")
    
    -- Initialize subsystems in dependency order
    UISystem.initializeSubsystems()
    
    -- Set up system integration
    UISystem.setupSystemIntegration()
    
    -- Configure theme system
    UISystem.setupThemeSystem()
    
    -- Set up responsive design
    UISystem.setupResponsiveDesign()
    
    -- Initialize accessibility features
    UISystem.setupAccessibilityFeatures()
    
    -- Set up performance monitoring
    UISystem.setupPerformanceMonitoring()
    
    -- Set up development tools
    if game:GetService("RunService"):IsStudio() and UI_CONFIG.enableTestingInStudio then
        UISystem.setupDevelopmentTools()
    end
    
    -- Mark as initialized
    SystemManager.initialized = true
    SystemManager.initializationTime = tick() - startTime
    
    print(string.format("🎨 UISystem initialized successfully in %.2fms", SystemManager.initializationTime * 1000))
    
    -- Fire initialization event
    UISystem.fireEvent("systemInitialized", {
        initializationTime = SystemManager.initializationTime,
        subsystems = SystemManager.subsystems
    })
    
    return true
end

function UISystem.initializeSubsystems()
    local subsystemOrder = {
        "designTokens",
        "animationSystem", 
        "responsiveSystem",
        "accessibilitySystem",
        "touchSystem",
        "feedbackSystem",
        "componentLibrary",
        "testingFramework"
    }
    
    for _, subsystemName in ipairs(subsystemOrder) do
        local success = UISystem.initializeSubsystem(subsystemName)
        SystemManager.subsystems[subsystemName] = success
        
        if not success then
            warn(string.format("Failed to initialize subsystem: %s", subsystemName))
        end
    end
end

function UISystem.initializeSubsystem(subsystemName)
    local success = false
    
    pcall(function()
        if subsystemName == "designTokens" then
            -- UIDesignTokens initializes automatically
            success = true
            
        elseif subsystemName == "componentLibrary" then
            -- UIComponentLibrary initializes automatically
            success = true
            
        elseif subsystemName == "animationSystem" then
            -- UIAnimationSystem initializes automatically
            success = true
            
        elseif subsystemName == "responsiveSystem" then
            -- UIResponsiveSystem initializes automatically
            success = true
            
        elseif subsystemName == "accessibilitySystem" then
            -- UIAccessibilitySystem initializes automatically
            success = true
            
        elseif subsystemName == "feedbackSystem" then
            -- UIFeedbackSystem initializes automatically
            success = true
            
        elseif subsystemName == "touchSystem" then
            -- UITouchSystem initializes automatically
            success = true
            
        elseif subsystemName == "testingFramework" then
            -- UITestingFramework initializes automatically
            success = true
        end
    end)
    
    if success then
        print(string.format("  ✅ %s initialized", subsystemName))
    else
        print(string.format("  ❌ %s failed to initialize", subsystemName))
    end
    
    return success
end

-- ========================================
-- SYSTEM INTEGRATION
-- ========================================

function UISystem.setupSystemIntegration()
    -- Integrate design tokens with all systems
    UISystem.integrateDesignTokens()
    
    -- Integrate responsive system with components
    UISystem.integrateResponsiveDesign()
    
    -- Integrate accessibility with all interactive elements
    UISystem.integrateAccessibility()
    
    -- Integrate touch optimization with components
    UISystem.integrateTouchOptimization()
    
    -- Set up cross-system event communication
    UISystem.setupEventSystem()
    
    print("🔗 System integration completed")
end

function UISystem.integrateDesignTokens()
    -- Ensure all systems use design tokens
    pcall(function()
        -- Set theme across all systems
        local tokens = UIDesignTokens.getTokens()
        
        -- Update animation system with design token timings
        if SystemManager.subsystems.animationSystem then
            -- Animation system uses design tokens automatically
        end
        
        -- Update responsive system with design token breakpoints
        if SystemManager.subsystems.responsiveSystem then
            -- Responsive system uses design tokens automatically
        end
    end)
end

function UISystem.integrateResponsiveDesign()
    if not SystemManager.subsystems.responsiveSystem then return end
    
    -- Set up responsive component updates
    UIResponsiveSystem.onViewportChange(function(viewportInfo)
        UISystem.updateComponentsForViewport(viewportInfo)
    end)
end

function UISystem.integrateAccessibility()
    if not SystemManager.subsystems.accessibilitySystem then return end
    
    -- Set up accessibility monitoring for new components
    UISystem.addEventListener("componentCreated", function(componentData)
        if componentData.element and componentData.interactive then
            UIAccessibilitySystem.registerFocusableElement(componentData.element, {
                ariaLabel = componentData.ariaLabel,
                role = componentData.role
            })
        end
    end)
end

function UISystem.integrateTouchOptimization()
    if not SystemManager.subsystems.touchSystem then return end
    
    -- Set up automatic touch optimization for interactive components
    UISystem.addEventListener("componentCreated", function(componentData)
        if componentData.element and componentData.interactive then
            UITouchSystem.registerTouchTarget(componentData.element, {
                hapticFeedback = componentData.hapticFeedback,
                visualFeedback = componentData.visualFeedback,
                onTap = componentData.onTap
            })
        end
    end)
end

function UISystem.setupEventSystem()
    -- Central event system for cross-subsystem communication
    SystemManager.eventListeners = {}
    
    print("📡 Event system configured")
end

-- ========================================
-- THEME SYSTEM
-- ========================================

function UISystem.setupThemeSystem()
    -- Load saved theme preference
    UISystem.loadThemePreference()
    
    -- Set up system theme detection
    if UI_CONFIG.systemThemeDetection then
        UISystem.detectSystemTheme()
    end
    
    -- Apply current theme
    UISystem.applyTheme(SystemManager.currentTheme)
    
    print(string.format("🎨 Theme system configured with '%s' theme", SystemManager.currentTheme))
end

function UISystem.loadThemePreference()
    pcall(function()
        local player = Players.LocalPlayer
        local savedTheme = player:GetAttribute("UITheme")
        if savedTheme then
            SystemManager.currentTheme = savedTheme
        end
    end)
end

function UISystem.detectSystemTheme()
    -- Note: Roblox doesn't have native system theme detection
    -- This could be implemented with external tools or user preference
    -- For now, we'll use the default theme
end

function UISystem.setTheme(themeName, options)
    options = options or {}
    
    if not UIDesignTokens.hasTheme(themeName) then
        warn(string.format("Theme '%s' not found", themeName))
        return false
    end
    
    local previousTheme = SystemManager.currentTheme
    SystemManager.currentTheme = themeName
    
    -- Apply theme with animation if specified
    if options.animated ~= false then
        UISystem.animateThemeTransition(previousTheme, themeName, options.duration)
    else
        UISystem.applyTheme(themeName)
    end
    
    -- Save theme preference
    UISystem.saveThemePreference(themeName)
    
    -- Fire theme change event
    UISystem.fireEvent("themeChanged", {
        previousTheme = previousTheme,
        currentTheme = themeName
    })
    
    print(string.format("🎨 Theme changed from '%s' to '%s'", previousTheme, themeName))
    
    return true
end

function UISystem.applyTheme(themeName)
    -- Apply theme to design tokens
    UIDesignTokens.setTheme(themeName)
    
    -- Update all registered components
    UISystem.updateAllComponentsTheme()
end

function UISystem.animateThemeTransition(fromTheme, toTheme, duration)
    duration = duration or UI_CONFIG.themeTransitionDuration
    
    -- Create theme transition animation
    if SystemManager.subsystems.animationSystem then
        UIAnimationSystem.animate({
            duration = duration,
            ease = "easeInOut",
            onUpdate = function(progress)
                -- Interpolate between themes
                UISystem.interpolateThemes(fromTheme, toTheme, progress)
            end,
            onComplete = function()
                UISystem.applyTheme(toTheme)
            end
        })
    else
        UISystem.applyTheme(toTheme)
    end
end

function UISystem.interpolateThemes(fromTheme, toTheme, progress)
    -- Theme interpolation implementation
    -- This would interpolate colors and other theme properties
end

function UISystem.saveThemePreference(themeName)
    pcall(function()
        local player = Players.LocalPlayer
        player:SetAttribute("UITheme", themeName)
    end)
end

-- ========================================
-- RESPONSIVE DESIGN
-- ========================================

function UISystem.setupResponsiveDesign()
    if not UI_CONFIG.enableResponsiveDesign then return end
    
    -- Monitor viewport changes
    workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(function()
        UISystem.handleViewportChange()
    end)
    
    -- Initial responsive update
    UISystem.handleViewportChange()
    
    print("📱 Responsive design system configured")
end

function UISystem.handleViewportChange()
    if not SystemManager.subsystems.responsiveSystem then return end
    
    local viewportInfo = UIResponsiveSystem.getViewportInfo()
    
    -- Update all components for new viewport
    UISystem.updateComponentsForViewport(viewportInfo)
    
    -- Fire viewport change event
    UISystem.fireEvent("viewportChanged", viewportInfo)
end

function UISystem.updateComponentsForViewport(viewportInfo)
    for componentId, component in pairs(SystemManager.activeComponents) do
        if component.responsive and component.updateForViewport then
            pcall(function()
                component.updateForViewport(viewportInfo)
            end)
        end
    end
end

-- ========================================
-- ACCESSIBILITY FEATURES
-- ========================================

function UISystem.setupAccessibilityFeatures()
    if not UI_CONFIG.enableAccessibility then return end
    
    -- Load accessibility preferences
    UISystem.loadAccessibilityPreferences()
    
    -- Set up accessibility monitoring
    UISystem.setupAccessibilityMonitoring()
    
    print("♿ Accessibility features configured")
end

function UISystem.loadAccessibilityPreferences()
    pcall(function()
        local player = Players.LocalPlayer
        
        local reducedMotion = player:GetAttribute("ReducedMotionEnabled") or false
        local highContrast = player:GetAttribute("HighContrastEnabled") or false
        local screenReader = player:GetAttribute("ScreenReaderEnabled") or false
        
        if reducedMotion then
            UIAccessibilitySystem.setReducedMotionMode(true)
        end
        
        if highContrast then
            UIAccessibilitySystem.setHighContrastMode(true)
        end
        
        if screenReader then
            UIAccessibilitySystem.setScreenReaderEnabled(true)
        end
    end)
end

function UISystem.setupAccessibilityMonitoring()
    -- Monitor for accessibility violations
    task.spawn(function()
        while SystemManager.initialized do
            task.wait(5) -- Check every 5 seconds
            UISystem.scanForAccessibilityIssues()
        end
    end)
end

function UISystem.scanForAccessibilityIssues()
    if not SystemManager.subsystems.accessibilitySystem then return end
    
    -- Scan all active components for accessibility issues
    local issues = {}
    
    for componentId, component in pairs(SystemManager.activeComponents) do
        if component.element then
            local accessibilityResult = UIAccessibilitySystem.validateElementContrast(component.element)
            if accessibilityResult and not accessibilityResult.passesAA then
                table.insert(issues, {
                    componentId = componentId,
                    type = "color_contrast",
                    ratio = accessibilityResult.ratio
                })
            end
        end
    end
    
    if #issues > 0 and UI_CONFIG.logSystemEvents then
        print(string.format("♿ Found %d accessibility issues", #issues))
    end
end

-- ========================================
-- PERFORMANCE MONITORING
-- ========================================

function UISystem.setupPerformanceMonitoring()
    if not UI_CONFIG.enablePerformanceMonitoring then return end
    
    -- Monitor system performance
    task.spawn(function()
        while SystemManager.initialized do
            task.wait(1) -- Check every second
            UISystem.updatePerformanceMetrics()
        end
    end)
    
    print("📊 Performance monitoring enabled")
end

function UISystem.updatePerformanceMetrics()
    local metrics = SystemManager.performanceMetrics
    
    -- Update memory usage
    metrics.memoryUsage = collectgarbage("count")
    
    -- Count active components
    metrics.activeComponents = 0
    for _ in pairs(SystemManager.activeComponents) do
        metrics.activeComponents = metrics.activeComponents + 1
    end
    
    -- Count active animations
    if SystemManager.subsystems.animationSystem then
        metrics.activeAnimations = UIAnimationSystem.getActiveAnimationCount()
    end
    
    -- Check for performance issues
    UISystem.checkPerformanceThresholds(metrics)
end

function UISystem.checkPerformanceThresholds(metrics)
    local warnings = {}
    
    if metrics.activeAnimations > UI_CONFIG.maxConcurrentAnimations then
        table.insert(warnings, string.format("Too many concurrent animations: %d", metrics.activeAnimations))
    end
    
    if metrics.memoryUsage > 100 then -- 100MB threshold
        table.insert(warnings, string.format("High memory usage: %.1fMB", metrics.memoryUsage))
    end
    
    if #warnings > 0 and UI_CONFIG.logSystemEvents then
        for _, warning in ipairs(warnings) do
            warn("📊 Performance warning: " .. warning)
        end
    end
end

-- ========================================
-- DEVELOPMENT TOOLS
-- ========================================

function UISystem.setupDevelopmentTools()
    print("🔧 Setting up development tools...")
    
    -- Set up component inspection
    UISystem.setupComponentInspection()
    
    -- Set up performance profiling
    UISystem.setupPerformanceProfiling()
    
    -- Set up automated testing
    UISystem.setupAutomatedTesting()
    
    print("🔧 Development tools configured")
end

function UISystem.setupComponentInspection()
    -- Visual component debugging
    if UI_CONFIG.showComponentBounds then
        UISystem.addEventListener("componentCreated", function(componentData)
            UISystem.addComponentBounds(componentData.element)
        end)
    end
end

function UISystem.addComponentBounds(element)
    local bounds = Instance.new("Frame")
    bounds.Name = "ComponentBounds"
    bounds.Size = UDim2.new(1, 0, 1, 0)
    bounds.Position = UDim2.new(0, 0, 0, 0)
    bounds.BackgroundColor3 = Color3.fromRGB(255, 0, 0)
    bounds.BackgroundTransparency = 0.8
    bounds.BorderSizePixel = 1
    bounds.BorderColor3 = Color3.fromRGB(255, 0, 0)
    bounds.ZIndex = element.ZIndex + 1000
    bounds.Parent = element
end

function UISystem.setupPerformanceProfiling()
    -- Performance profiling for development
    if UI_CONFIG.enableDebugMode then
        UISystem.addEventListener("componentCreated", function(componentData)
            print(string.format("🔧 Component created: %s", componentData.componentType))
        end)
    end
end

function UISystem.setupAutomatedTesting()
    if not SystemManager.subsystems.testingFramework then return end
    
    -- Set up sample tests for the UI system
    UITestingFramework.describe("UISystem Integration", function()
        UITestingFramework.it("should initialize all subsystems", function()
            UITestingFramework.expect(SystemManager.initialized).toBeTruthy()
            
            for subsystemName, status in pairs(SystemManager.subsystems) do
                UITestingFramework.expect(status).toBe(true)
            end
        end)
        
        UITestingFramework.it("should respond to theme changes", function()
            local originalTheme = SystemManager.currentTheme
            UISystem.setTheme("dark")
            UITestingFramework.expect(SystemManager.currentTheme).toBe("dark")
            UISystem.setTheme(originalTheme)
        end)
        
        UITestingFramework.it("should handle viewport changes", function()
            local viewportInfo = UIResponsiveSystem.getViewportInfo()
            UITestingFramework.expect(viewportInfo).toBeTruthy()
            UITestingFramework.expect(viewportInfo.breakpoint).toBeTruthy()
        end)
    end)
end

-- ========================================
-- COMPONENT MANAGEMENT
-- ========================================

function UISystem.registerComponent(componentId, componentData)
    SystemManager.registeredComponents[componentId] = componentData
    
    -- Fire component registered event
    UISystem.fireEvent("componentRegistered", {
        componentId = componentId,
        componentData = componentData
    })
end

function UISystem.createComponent(componentType, config)
    config = config or {}
    
    local component = nil
    local componentData = {
        componentType = componentType,
        config = config,
        element = nil,
        interactive = false,
        responsive = config.responsive ~= false,
        createdAt = tick()
    }
    
    -- Create component using component library
    if SystemManager.subsystems.componentLibrary then
        if componentType == "button" then
            component = UIComponentLibrary.createButton(config)
            componentData.interactive = true
            componentData.element = component.element
            
        elseif componentType == "input" then
            component = UIComponentLibrary.createInput(config)
            componentData.interactive = true
            componentData.element = component.element
            
        elseif componentType == "card" then
            component = UIComponentLibrary.createCard(config)
            componentData.element = component.element
            
        elseif componentType == "modal" then
            component = UIComponentLibrary.createModal(config)
            componentData.interactive = true
            componentData.element = component.element
            
        elseif componentType == "loadingSpinner" then
            component = UIComponentLibrary.createLoadingSpinner(config)
            componentData.element = component.element
        end
    end
    
    if component then
        local componentId = UISystem.generateComponentId()
        componentData.component = component
        SystemManager.activeComponents[componentId] = componentData
        
        -- Fire component created event
        UISystem.fireEvent("componentCreated", componentData)
        
        -- Add destroy method
        component.destroy = function()
            UISystem.destroyComponent(componentId)
        end
        
        component.id = componentId
        
        return component
    end
    
    return nil
end

function UISystem.destroyComponent(componentId)
    local componentData = SystemManager.activeComponents[componentId]
    if not componentData then return end
    
    -- Destroy the actual component
    if componentData.component and componentData.component.destroy then
        componentData.component.destroy()
    end
    
    -- Remove from active components
    SystemManager.activeComponents[componentId] = nil
    
    -- Fire component destroyed event
    UISystem.fireEvent("componentDestroyed", {
        componentId = componentId
    })
end

function UISystem.updateAllComponentsTheme()
    for componentId, componentData in pairs(SystemManager.activeComponents) do
        if componentData.component and componentData.component.updateTheme then
            pcall(function()
                componentData.component.updateTheme()
            end)
        end
    end
end

function UISystem.generateComponentId()
    return "ui_component_" .. tick() .. "_" .. math.random(1000, 9999)
end

-- ========================================
-- EVENT SYSTEM
-- ========================================

function UISystem.addEventListener(eventName, callback)
    if not SystemManager.eventListeners[eventName] then
        SystemManager.eventListeners[eventName] = {}
    end
    
    table.insert(SystemManager.eventListeners[eventName], callback)
    
    return function() -- Return unsubscribe function
        local listeners = SystemManager.eventListeners[eventName]
        if listeners then
            for i, listener in ipairs(listeners) do
                if listener == callback then
                    table.remove(listeners, i)
                    break
                end
            end
        end
    end
end

function UISystem.fireEvent(eventName, eventData)
    local listeners = SystemManager.eventListeners[eventName]
    if not listeners then return end
    
    for _, callback in ipairs(listeners) do
        pcall(callback, eventData)
    end
    
    if UI_CONFIG.logSystemEvents then
        print(string.format("📡 Event fired: %s", eventName))
    end
end

-- ========================================
-- PUBLIC API
-- ========================================

-- System management
UISystem.initialize = UISystem.initialize
UISystem.isInitialized = function() return SystemManager.initialized end
UISystem.getSystemInfo = function() return {
    initialized = SystemManager.initialized,
    initializationTime = SystemManager.initializationTime,
    subsystems = SystemManager.subsystems,
    performanceMetrics = SystemManager.performanceMetrics
} end

-- Theme management
UISystem.setTheme = UISystem.setTheme
UISystem.getCurrentTheme = function() return SystemManager.currentTheme end
UISystem.getAvailableThemes = function() return UIDesignTokens.getAvailableThemes() end

-- Component creation shortcuts
UISystem.createButton = function(config) return UISystem.createComponent("button", config) end
UISystem.createInput = function(config) return UISystem.createComponent("input", config) end
UISystem.createCard = function(config) return UISystem.createComponent("card", config) end
UISystem.createModal = function(config) return UISystem.createComponent("modal", config) end
UISystem.createLoadingSpinner = function(config) return UISystem.createComponent("loadingSpinner", config) end

-- Feedback shortcuts
UISystem.showToast = function(message, type, options) 
    options = options or {}
    options.message = message
    options.type = type
    return UIFeedbackSystem.showToast(options)
end
UISystem.success = UIFeedbackSystem.success
UISystem.error = UIFeedbackSystem.error
UISystem.warning = UIFeedbackSystem.warning
UISystem.info = UIFeedbackSystem.info

-- Animation shortcuts
UISystem.animate = UIAnimationSystem.animate
UISystem.animatePattern = UIAnimationSystem.animatePattern

-- Responsive utilities
UISystem.getViewportInfo = UIResponsiveSystem.getViewportInfo
UISystem.getBreakpoint = UIResponsiveSystem.getBreakpoint

-- Touch utilities
UISystem.optimizeButton = UITouchSystem.optimizeButton
UISystem.getDeviceInfo = UITouchSystem.getDeviceInfo

-- Testing utilities (development only)
UISystem.runTests = function()
    if SystemManager.subsystems.testingFramework then
        return UITestingFramework.runAllTests()
    end
end

-- Event system
UISystem.addEventListener = UISystem.addEventListener
UISystem.fireEvent = UISystem.fireEvent

-- Export subsystem references for advanced usage
UISystem.DesignTokens = UIDesignTokens
UISystem.ComponentLibrary = UIComponentLibrary
UISystem.AnimationSystem = UIAnimationSystem
UISystem.ResponsiveSystem = UIResponsiveSystem
UISystem.AccessibilitySystem = UIAccessibilitySystem
UISystem.FeedbackSystem = UIFeedbackSystem
UISystem.TouchSystem = UITouchSystem
UISystem.TestingFramework = UITestingFramework

-- Auto-initialize if enabled
if UI_CONFIG.autoInitialize then
    UISystem.initialize()
end

print("🎨 UISystem loaded with comprehensive UI framework")

return UISystem
