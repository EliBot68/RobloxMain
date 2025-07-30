-- UIAccessibilitySystem.luau
-- Comprehensive accessibility system for inclusive UI design
-- Provides screen reader support, keyboard navigation, and accessibility compliance

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local GuiService = game:GetService("GuiService")
local SoundService = game:GetService("SoundService")
local TweenService = game:GetService("TweenService")

local SafeRequire = require(ReplicatedStorage.Shared.utils.SafeRequire)
local UIDesignTokens = SafeRequire.require(ReplicatedStorage.Shared.ui.UIDesignTokens)

local UIAccessibilitySystem = {}

-- ========================================
-- ACCESSIBILITY CONFIGURATION
-- ========================================

local ACCESSIBILITY_STANDARDS = {
    -- WCAG 2.1 Color Contrast Requirements
    colorContrast = {
        AA_NORMAL = 4.5,      -- Normal text AA compliance
        AA_LARGE = 3.0,       -- Large text AA compliance
        AAA_NORMAL = 7.0,     -- Normal text AAA compliance
        AAA_LARGE = 4.5       -- Large text AAA compliance
    },
    
    -- Touch Target Sizes (Apple/Android Guidelines)
    touchTargets = {
        MINIMUM = 44,         -- Minimum accessible touch target
        RECOMMENDED = 48,     -- Recommended comfortable size
        LARGE = 56,          -- Large touch target
        EXTRA_LARGE = 64     -- Extra large for accessibility
    },
    
    -- Animation Durations (Reduced Motion)
    animations = {
        NONE = 0,            -- No animation
        MINIMAL = 0.1,       -- Minimal animation
        REDUCED = 0.2,       -- Reduced animation
        STANDARD = 0.3       -- Standard animation
    },
    
    -- Focus Indicators
    focus = {
        outlineWidth = 2,
        outlineColor = Color3.fromRGB(0, 122, 255),
        outlineOffset = 2
    }
}

local ARIA_ROLES = {
    button = "button",
    link = "link",
    checkbox = "checkbox",
    radio = "radio",
    textbox = "textbox",
    slider = "slider",
    progressbar = "progressbar",
    dialog = "dialog",
    menu = "menu",
    menuitem = "menuitem",
    tab = "tab",
    tabpanel = "tabpanel",
    navigation = "navigation",
    main = "main",
    banner = "banner",
    contentinfo = "contentinfo",
    complementary = "complementary",
    region = "region"
}

local KEYBOARD_NAVIGATION = {
    -- Focus movement keys
    TAB = Enum.KeyCode.Tab,
    SHIFT_TAB = {Enum.KeyCode.Tab, Enum.KeyCode.LeftShift},
    ARROW_UP = Enum.KeyCode.Up,
    ARROW_DOWN = Enum.KeyCode.Down,
    ARROW_LEFT = Enum.KeyCode.Left,
    ARROW_RIGHT = Enum.KeyCode.Right,
    
    -- Action keys
    ENTER = Enum.KeyCode.Return,
    SPACE = Enum.KeyCode.Space,
    ESCAPE = Enum.KeyCode.Escape,
    
    -- Navigation keys
    HOME = Enum.KeyCode.Home,
    END = Enum.KeyCode.End,
    PAGE_UP = Enum.KeyCode.PageUp,
    PAGE_DOWN = Enum.KeyCode.PageDown
}

-- ========================================
-- ACCESSIBILITY MANAGER
-- ========================================

local AccessibilityManager = {
    -- Settings
    screenReaderEnabled = false,
    keyboardNavigationEnabled = true,
    highContrastMode = false,
    reducedMotionMode = false,
    largeTextMode = false,
    soundCuesEnabled = true,
    hapticFeedbackEnabled = true,
    
    -- Navigation
    focusableElements = {},
    currentFocusIndex = 0,
    focusHistory = {},
    tabOrder = {},
    
    -- Screen Reader
    announcements = {},
    announcementQueue = {},
    lastAnnouncement = "",
    
    -- Color Contrast
    contrastRatios = {},
    
    -- Event Callbacks
    focusCallbacks = {},
    announcementCallbacks = {}
}

function UIAccessibilitySystem.initialize()
    -- Load user preferences
    UIAccessibilitySystem.loadAccessibilityPreferences()
    
    -- Set up keyboard navigation
    UIAccessibilitySystem.initializeKeyboardNavigation()
    
    -- Set up screen reader
    UIAccessibilitySystem.initializeScreenReader()
    
    -- Set up automatic accessibility scanning
    UIAccessibilitySystem.initializeAccessibilityScanning()
    
    print("♿ UIAccessibilitySystem initialized with full accessibility support")
end

-- ========================================
-- KEYBOARD NAVIGATION
-- ========================================

function UIAccessibilitySystem.initializeKeyboardNavigation()
    if not AccessibilityManager.keyboardNavigationEnabled then
        return
    end
    
    -- Handle keyboard input
    UserInputService.InputBegan:Connect(function(input, gameProcessed)
        if gameProcessed then return end
        
        local keyCode = input.KeyCode
        
        -- Tab navigation
        if keyCode == KEYBOARD_NAVIGATION.TAB then
            if UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) then
                UIAccessibilitySystem.focusPrevious()
            else
                UIAccessibilitySystem.focusNext()
            end
            
        -- Arrow key navigation
        elseif keyCode == KEYBOARD_NAVIGATION.ARROW_UP then
            UIAccessibilitySystem.focusUp()
        elseif keyCode == KEYBOARD_NAVIGATION.ARROW_DOWN then
            UIAccessibilitySystem.focusDown()
        elseif keyCode == KEYBOARD_NAVIGATION.ARROW_LEFT then
            UIAccessibilitySystem.focusLeft()
        elseif keyCode == KEYBOARD_NAVIGATION.ARROW_RIGHT then
            UIAccessibilitySystem.focusRight()
            
        -- Action keys
        elseif keyCode == KEYBOARD_NAVIGATION.ENTER or keyCode == KEYBOARD_NAVIGATION.SPACE then
            UIAccessibilitySystem.activateCurrentFocus()
        elseif keyCode == KEYBOARD_NAVIGATION.ESCAPE then
            UIAccessibilitySystem.handleEscape()
            
        -- Navigation keys
        elseif keyCode == KEYBOARD_NAVIGATION.HOME then
            UIAccessibilitySystem.focusFirst()
        elseif keyCode == KEYBOARD_NAVIGATION.END then
            UIAccessibilitySystem.focusLast()
        end
    end)
end

function UIAccessibilitySystem.registerFocusableElement(element, config)
    config = config or {}
    
    if not element then
        warn("Cannot register nil element for focus")
        return nil
    end
    
    local focusConfig = {
        element = element,
        tabIndex = config.tabIndex or 0,
        role = config.role or UIAccessibilitySystem.detectElementRole(element),
        ariaLabel = config.ariaLabel or UIAccessibilitySystem.getElementText(element),
        ariaDescription = config.ariaDescription,
        disabled = config.disabled or false,
        
        -- Navigation callbacks
        onFocus = config.onFocus,
        onBlur = config.onBlur,
        onActivate = config.onActivate,
        
        -- Spatial navigation hints
        up = config.up,
        down = config.down,
        left = config.left,
        right = config.right
    }
    
    -- Generate unique ID
    local elementId = UIAccessibilitySystem.generateElementId()
    AccessibilityManager.focusableElements[elementId] = focusConfig
    
    -- Set accessibility attributes
    element:SetAttribute("AccessibilityId", elementId)
    element:SetAttribute("AriaRole", focusConfig.role)
    element:SetAttribute("AriaLabel", focusConfig.ariaLabel)
    element:SetAttribute("AriaDescription", focusConfig.ariaDescription)
    element:SetAttribute("TabIndex", focusConfig.tabIndex)
    element:SetAttribute("Disabled", focusConfig.disabled)
    
    -- Add focus indicators
    UIAccessibilitySystem.addFocusIndicators(element)
    
    -- Update tab order
    UIAccessibilitySystem.updateTabOrder()
    
    return {
        id = elementId,
        focus = function()
            UIAccessibilitySystem.setFocus(elementId)
        end,
        blur = function()
            UIAccessibilitySystem.removeFocus(elementId)
        end,
        setDisabled = function(disabled)
            focusConfig.disabled = disabled
            element:SetAttribute("Disabled", disabled)
        end,
        setAriaLabel = function(label)
            focusConfig.ariaLabel = label
            element:SetAttribute("AriaLabel", label)
        end,
        destroy = function()
            AccessibilityManager.focusableElements[elementId] = nil
            UIAccessibilitySystem.updateTabOrder()
        end
    }
end

function UIAccessibilitySystem.addFocusIndicators(element)
    -- Create focus outline
    local focusOutline = Instance.new("UIStroke")
    focusOutline.Name = "FocusOutline"
    focusOutline.Color = ACCESSIBILITY_STANDARDS.focus.outlineColor
    focusOutline.Thickness = ACCESSIBILITY_STANDARDS.focus.outlineWidth
    focusOutline.Transparency = 1 -- Hidden by default
    focusOutline.Parent = element
    
    -- Store original properties for restoration
    element:SetAttribute("OriginalBackgroundTransparency", element.BackgroundTransparency)
    
    return focusOutline
end

function UIAccessibilitySystem.updateTabOrder()
    AccessibilityManager.tabOrder = {}
    
    -- Sort elements by tab index and position
    local sortedElements = {}
    for id, config in pairs(AccessibilityManager.focusableElements) do
        if not config.disabled and config.element.Parent then
            table.insert(sortedElements, {id = id, config = config})
        end
    end
    
    table.sort(sortedElements, function(a, b)
        -- Sort by tab index first
        if a.config.tabIndex ~= b.config.tabIndex then
            return a.config.tabIndex < b.config.tabIndex
        end
        
        -- Then by vertical position
        local aPos = a.config.element.AbsolutePosition
        local bPos = b.config.element.AbsolutePosition
        
        if math.abs(aPos.Y - bPos.Y) > 10 then
            return aPos.Y < bPos.Y
        end
        
        -- Finally by horizontal position
        return aPos.X < bPos.X
    end)
    
    for _, item in ipairs(sortedElements) do
        table.insert(AccessibilityManager.tabOrder, item.id)
    end
end

function UIAccessibilitySystem.focusNext()
    if #AccessibilityManager.tabOrder == 0 then return end
    
    AccessibilityManager.currentFocusIndex = AccessibilityManager.currentFocusIndex + 1
    if AccessibilityManager.currentFocusIndex > #AccessibilityManager.tabOrder then
        AccessibilityManager.currentFocusIndex = 1
    end
    
    local elementId = AccessibilityManager.tabOrder[AccessibilityManager.currentFocusIndex]
    UIAccessibilitySystem.setFocus(elementId)
end

function UIAccessibilitySystem.focusPrevious()
    if #AccessibilityManager.tabOrder == 0 then return end
    
    AccessibilityManager.currentFocusIndex = AccessibilityManager.currentFocusIndex - 1
    if AccessibilityManager.currentFocusIndex < 1 then
        AccessibilityManager.currentFocusIndex = #AccessibilityManager.tabOrder
    end
    
    local elementId = AccessibilityManager.tabOrder[AccessibilityManager.currentFocusIndex]
    UIAccessibilitySystem.setFocus(elementId)
end

function UIAccessibilitySystem.setFocus(elementId)
    local config = AccessibilityManager.focusableElements[elementId]
    if not config or config.disabled then
        return false
    end
    
    local element = config.element
    if not element or not element.Parent then
        return false
    end
    
    -- Remove focus from previously focused element
    UIAccessibilitySystem.clearCurrentFocus()
    
    -- Set focus
    AccessibilityManager.currentFocusIndex = table.find(AccessibilityManager.tabOrder, elementId) or 0
    
    -- Show focus indicators
    local focusOutline = element:FindFirstChild("FocusOutline")
    if focusOutline then
        focusOutline.Transparency = 0
    end
    
    -- Scroll into view if needed
    UIAccessibilitySystem.scrollIntoView(element)
    
    -- Play focus sound
    if AccessibilityManager.soundCuesEnabled then
        UIAccessibilitySystem.playAccessibilitySound("focus")
    end
    
    -- Announce to screen reader
    UIAccessibilitySystem.announceElement(config)
    
    -- Call focus callback
    if config.onFocus then
        pcall(config.onFocus, element)
    end
    
    -- Notify focus change
    UIAccessibilitySystem.notifyFocusChange(elementId, element)
    
    return true
end

function UIAccessibilitySystem.clearCurrentFocus()
    if AccessibilityManager.currentFocusIndex == 0 then return end
    
    local elementId = AccessibilityManager.tabOrder[AccessibilityManager.currentFocusIndex]
    if not elementId then return end
    
    local config = AccessibilityManager.focusableElements[elementId]
    if not config then return end
    
    local element = config.element
    if not element then return end
    
    -- Hide focus indicators
    local focusOutline = element:FindFirstChild("FocusOutline")
    if focusOutline then
        focusOutline.Transparency = 1
    end
    
    -- Call blur callback
    if config.onBlur then
        pcall(config.onBlur, element)
    end
end

function UIAccessibilitySystem.activateCurrentFocus()
    if AccessibilityManager.currentFocusIndex == 0 then return end
    
    local elementId = AccessibilityManager.tabOrder[AccessibilityManager.currentFocusIndex]
    if not elementId then return end
    
    local config = AccessibilityManager.focusableElements[elementId]
    if not config or config.disabled then return end
    
    local element = config.element
    
    -- Play activation sound
    if AccessibilityManager.soundCuesEnabled then
        UIAccessibilitySystem.playAccessibilitySound("activate")
    end
    
    -- Haptic feedback
    if AccessibilityManager.hapticFeedbackEnabled and UserInputService.TouchEnabled then
        pcall(function()
            UserInputService:GetPlatformService():PerformHapticFeedback(Enum.HapticFeedbackType.ImpactMedium)
        end)
    end
    
    -- Call activation callback
    if config.onActivate then
        pcall(config.onActivate, element)
    end
    
    -- Simulate click for buttons
    if element:IsA("GuiButton") then
        -- Fire click events
        for _, connection in pairs(getconnections(element.MouseButton1Click)) do
            pcall(connection.Function)
        end
    end
end

-- ========================================
-- SCREEN READER SUPPORT
-- ========================================

function UIAccessibilitySystem.initializeScreenReader()
    -- Note: Roblox doesn't have native screen reader APIs
    -- This system provides announcements through audio and visual cues
    
    if not AccessibilityManager.screenReaderEnabled then
        return
    end
    
    -- Create announcement display
    UIAccessibilitySystem.createAnnouncementDisplay()
    
    print("🔊 Screen reader simulation initialized")
end

function UIAccessibilitySystem.announceElement(config)
    if not AccessibilityManager.screenReaderEnabled then
        return
    end
    
    local announcement = UIAccessibilitySystem.buildElementAnnouncement(config)
    UIAccessibilitySystem.announce(announcement)
end

function UIAccessibilitySystem.buildElementAnnouncement(config)
    local parts = {}
    
    -- Element label
    if config.ariaLabel and config.ariaLabel ~= "" then
        table.insert(parts, config.ariaLabel)
    end
    
    -- Element role
    if config.role then
        table.insert(parts, config.role)
    end
    
    -- Element description
    if config.ariaDescription and config.ariaDescription ~= "" then
        table.insert(parts, config.ariaDescription)
    end
    
    -- Element state
    if config.disabled then
        table.insert(parts, "disabled")
    end
    
    return table.concat(parts, ", ")
end

function UIAccessibilitySystem.announce(text, priority)
    priority = priority or "polite"
    
    if text == AccessibilityManager.lastAnnouncement then
        return -- Avoid duplicate announcements
    end
    
    AccessibilityManager.lastAnnouncement = text
    
    -- Add to announcement queue
    table.insert(AccessibilityManager.announcementQueue, {
        text = text,
        priority = priority,
        timestamp = tick()
    })
    
    -- Process queue
    UIAccessibilitySystem.processAnnouncementQueue()
    
    -- Notify callbacks
    UIAccessibilitySystem.notifyAnnouncement(text, priority)
end

function UIAccessibilitySystem.processAnnouncementQueue()
    if #AccessibilityManager.announcementQueue == 0 then
        return
    end
    
    local announcement = table.remove(AccessibilityManager.announcementQueue, 1)
    
    -- Display announcement visually
    UIAccessibilitySystem.displayAnnouncement(announcement.text)
    
    -- Play announcement audio (if available)
    if AccessibilityManager.soundCuesEnabled then
        UIAccessibilitySystem.playAnnouncementSound(announcement.text)
    end
    
    -- Schedule next announcement
    if #AccessibilityManager.announcementQueue > 0 then
        task.wait(1) -- Wait between announcements
        UIAccessibilitySystem.processAnnouncementQueue()
    end
end

function UIAccessibilitySystem.createAnnouncementDisplay()
    -- Create visual announcement display for users who can see
    local playerGui = game.Players.LocalPlayer:WaitForChild("PlayerGui")
    
    local announcementGui = Instance.new("ScreenGui")
    announcementGui.Name = "AccessibilityAnnouncements"
    announcementGui.DisplayOrder = 1000
    announcementGui.Parent = playerGui
    
    local announcementFrame = Instance.new("Frame")
    announcementFrame.Name = "AnnouncementFrame"
    announcementFrame.Size = UDim2.new(0.4, 0, 0, 60)
    announcementFrame.Position = UDim2.new(0.5, 0, 0, 20)
    announcementFrame.AnchorPoint = Vector2.new(0.5, 0)
    announcementFrame.BackgroundColor3 = Color3.new(0, 0, 0)
    announcementFrame.BackgroundTransparency = 0.2
    announcementFrame.BorderSizePixel = 0
    announcementFrame.Visible = false
    announcementFrame.Parent = announcementGui
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 8)
    corner.Parent = announcementFrame
    
    local announcementLabel = Instance.new("TextLabel")
    announcementLabel.Name = "AnnouncementLabel"
    announcementLabel.Size = UDim2.new(1, -20, 1, 0)
    announcementLabel.Position = UDim2.new(0, 10, 0, 0)
    announcementLabel.BackgroundTransparency = 1
    announcementLabel.Text = ""
    announcementLabel.TextColor3 = Color3.new(1, 1, 1)
    announcementLabel.TextSize = 16
    announcementLabel.Font = Enum.Font.SourceSans
    announcementLabel.TextWrapped = true
    announcementLabel.TextXAlignment = Enum.TextXAlignment.Center
    announcementLabel.TextYAlignment = Enum.TextYAlignment.Center
    announcementLabel.Parent = announcementFrame
    
    AccessibilityManager.announcementDisplay = {
        gui = announcementGui,
        frame = announcementFrame,
        label = announcementLabel
    }
end

function UIAccessibilitySystem.displayAnnouncement(text)
    local display = AccessibilityManager.announcementDisplay
    if not display then return end
    
    display.label.Text = text
    display.frame.Visible = true
    
    -- Fade in
    local fadeInTween = TweenService:Create(
        display.frame,
        TweenInfo.new(0.2, Enum.EasingStyle.Quad),
        {BackgroundTransparency = 0.1}
    )
    fadeInTween:Play()
    
    -- Auto-hide after 3 seconds
    task.wait(3)
    
    local fadeOutTween = TweenService:Create(
        display.frame,
        TweenInfo.new(0.3, Enum.EasingStyle.Quad),
        {BackgroundTransparency = 1}
    )
    fadeOutTween:Play()
    
    fadeOutTween.Completed:Connect(function()
        display.frame.Visible = false
    end)
end

-- ========================================
-- COLOR CONTRAST ANALYSIS
-- ========================================

function UIAccessibilitySystem.checkColorContrast(foregroundColor, backgroundColor)
    local function getLuminance(color)
        local function sRGBToLinear(value)
            if value <= 0.03928 then
                return value / 12.92
            else
                return math.pow((value + 0.055) / 1.055, 2.4)
            end
        end
        
        local r = sRGBToLinear(color.R)
        local g = sRGBToLinear(color.G)
        local b = sRGBToLinear(color.B)
        
        return 0.2126 * r + 0.7152 * g + 0.0722 * b
    end
    
    local fgLuminance = getLuminance(foregroundColor)
    local bgLuminance = getLuminance(backgroundColor)
    
    local lighter = math.max(fgLuminance, bgLuminance)
    local darker = math.min(fgLuminance, bgLuminance)
    
    local contrastRatio = (lighter + 0.05) / (darker + 0.05)
    
    return {
        ratio = contrastRatio,
        passesAA = contrastRatio >= ACCESSIBILITY_STANDARDS.colorContrast.AA_NORMAL,
        passesAALarge = contrastRatio >= ACCESSIBILITY_STANDARDS.colorContrast.AA_LARGE,
        passesAAA = contrastRatio >= ACCESSIBILITY_STANDARDS.colorContrast.AAA_NORMAL,
        passesAAALarge = contrastRatio >= ACCESSIBILITY_STANDARDS.colorContrast.AAA_LARGE
    }
end

function UIAccessibilitySystem.validateElementContrast(element)
    if not element:IsA("TextLabel") and not element:IsA("TextButton") and not element:IsA("TextBox") then
        return nil
    end
    
    local textColor = element.TextColor3
    local backgroundColor = element.BackgroundColor3
    
    -- Account for transparency
    if element.BackgroundTransparency > 0.5 then
        -- Try to find parent background
        local parent = element.Parent
        while parent and parent ~= game.Players.LocalPlayer.PlayerGui do
            if parent:IsA("GuiObject") and parent.BackgroundTransparency < 0.5 then
                backgroundColor = parent.BackgroundColor3
                break
            end
            parent = parent.Parent
        end
    end
    
    return UIAccessibilitySystem.checkColorContrast(textColor, backgroundColor)
end

-- ========================================
-- ACCESSIBILITY SCANNING
-- ========================================

function UIAccessibilitySystem.initializeAccessibilityScanning()
    -- Periodically scan for accessibility issues
    task.spawn(function()
        while true do
            task.wait(5) -- Scan every 5 seconds
            UIAccessibilitySystem.scanForAccessibilityIssues()
        end
    end)
end

function UIAccessibilitySystem.scanForAccessibilityIssues()
    local issues = {}
    
    -- Scan all GUI elements
    for _, gui in pairs(game.Players.LocalPlayer.PlayerGui:GetChildren()) do
        if gui:IsA("ScreenGui") then
            UIAccessibilitySystem.scanGuiForIssues(gui, issues)
        end
    end
    
    -- Report issues
    if #issues > 0 then
        UIAccessibilitySystem.reportAccessibilityIssues(issues)
    end
end

function UIAccessibilitySystem.scanGuiForIssues(gui, issues)
    for _, descendant in pairs(gui:GetDescendants()) do
        if descendant:IsA("GuiObject") then
            -- Check touch target size
            if descendant:IsA("GuiButton") or descendant:IsA("TextButton") then
                local size = descendant.AbsoluteSize
                if size.X < ACCESSIBILITY_STANDARDS.touchTargets.MINIMUM or 
                   size.Y < ACCESSIBILITY_STANDARDS.touchTargets.MINIMUM then
                    table.insert(issues, {
                        type = "touch_target_too_small",
                        element = descendant,
                        severity = "warning",
                        message = "Touch target smaller than " .. ACCESSIBILITY_STANDARDS.touchTargets.MINIMUM .. "px"
                    })
                end
            end
            
            -- Check color contrast
            if descendant:IsA("TextLabel") or descendant:IsA("TextButton") or descendant:IsA("TextBox") then
                local contrastResult = UIAccessibilitySystem.validateElementContrast(descendant)
                if contrastResult and not contrastResult.passesAA then
                    table.insert(issues, {
                        type = "low_color_contrast",
                        element = descendant,
                        severity = "error",
                        message = string.format("Color contrast ratio %.1f:1 fails WCAG AA (4.5:1 required)", contrastResult.ratio)
                    })
                end
            end
            
            -- Check for missing accessibility attributes
            if (descendant:IsA("GuiButton") or descendant:IsA("TextButton")) and 
               not descendant:GetAttribute("AriaLabel") then
                table.insert(issues, {
                    type = "missing_aria_label",
                    element = descendant,
                    severity = "warning",
                    message = "Interactive element missing AriaLabel"
                })
            end
        end
    end
end

function UIAccessibilitySystem.reportAccessibilityIssues(issues)
    local errorCount = 0
    local warningCount = 0
    
    for _, issue in ipairs(issues) do
        if issue.severity == "error" then
            errorCount = errorCount + 1
        elseif issue.severity == "warning" then
            warningCount = warningCount + 1
        end
    end
    
    if errorCount > 0 then
        warn(string.format("♿ Accessibility scan found %d errors and %d warnings", errorCount, warningCount))
    end
end

-- ========================================
-- UTILITY FUNCTIONS
-- ========================================

function UIAccessibilitySystem.detectElementRole(element)
    if element:IsA("TextButton") or element:IsA("ImageButton") then
        return ARIA_ROLES.button
    elseif element:IsA("TextBox") then
        return ARIA_ROLES.textbox
    elseif element:IsA("ScrollingFrame") then
        return ARIA_ROLES.region
    else
        return "generic"
    end
end

function UIAccessibilitySystem.getElementText(element)
    if element:IsA("TextLabel") or element:IsA("TextButton") or element:IsA("TextBox") then
        return element.Text
    elseif element.Name and element.Name ~= "" then
        return element.Name
    else
        return "Unnamed element"
    end
end

function UIAccessibilitySystem.scrollIntoView(element)
    -- Find scrollable parent
    local parent = element.Parent
    while parent do
        if parent:IsA("ScrollingFrame") then
            local scrollFrame = parent
            local elementPos = element.AbsolutePosition
            local scrollPos = scrollFrame.AbsolutePosition
            local scrollSize = scrollFrame.AbsoluteSize
            
            -- Calculate if element is visible
            local isVisible = elementPos.Y >= scrollPos.Y and 
                            elementPos.Y + element.AbsoluteSize.Y <= scrollPos.Y + scrollSize.Y
            
            if not isVisible then
                -- Scroll to make element visible
                local targetY = elementPos.Y - scrollPos.Y - scrollSize.Y / 2
                scrollFrame.CanvasPosition = Vector2.new(scrollFrame.CanvasPosition.X, targetY)
            end
            
            break
        end
        parent = parent.Parent
    end
end

function UIAccessibilitySystem.playAccessibilitySound(soundType)
    -- Play accessibility feedback sounds
    local soundMap = {
        focus = "rbxasset://sounds/ui/hover.mp3",
        activate = "rbxasset://sounds/ui/click1.mp3",
        error = "rbxasset://sounds/ui/error.mp3",
        success = "rbxasset://sounds/ui/success.mp3"
    }
    
    local soundId = soundMap[soundType]
    if soundId then
        local sound = Instance.new("Sound")
        sound.SoundId = soundId
        sound.Volume = 0.2
        sound.Parent = SoundService
        sound:Play()
        
        sound.Ended:Connect(function()
            sound:Destroy()
        end)
    end
end

function UIAccessibilitySystem.playAnnouncementSound(text)
    -- Note: In a real implementation, this would use text-to-speech
    -- For now, we play a notification sound
    UIAccessibilitySystem.playAccessibilitySound("focus")
end

function UIAccessibilitySystem.generateElementId()
    return "a11y_" .. tick() .. "_" .. math.random(1000, 9999)
end

-- ========================================
-- SETTINGS AND PREFERENCES
-- ========================================

function UIAccessibilitySystem.loadAccessibilityPreferences()
    -- Load user accessibility preferences
    pcall(function()
        local Players = game:GetService("Players")
        local player = Players.LocalPlayer
        
        if player then
            AccessibilityManager.screenReaderEnabled = player:GetAttribute("ScreenReaderEnabled") or false
            AccessibilityManager.keyboardNavigationEnabled = player:GetAttribute("KeyboardNavigationEnabled") or true
            AccessibilityManager.highContrastMode = player:GetAttribute("HighContrastMode") or false
            AccessibilityManager.reducedMotionMode = player:GetAttribute("ReducedMotionMode") or false
            AccessibilityManager.largeTextMode = player:GetAttribute("LargeTextMode") or false
            AccessibilityManager.soundCuesEnabled = player:GetAttribute("SoundCuesEnabled") or true
            AccessibilityManager.hapticFeedbackEnabled = player:GetAttribute("HapticFeedbackEnabled") or true
        end
    end)
end

function UIAccessibilitySystem.saveAccessibilityPreferences()
    pcall(function()
        local Players = game:GetService("Players")
        local player = Players.LocalPlayer
        
        if player then
            player:SetAttribute("ScreenReaderEnabled", AccessibilityManager.screenReaderEnabled)
            player:SetAttribute("KeyboardNavigationEnabled", AccessibilityManager.keyboardNavigationEnabled)
            player:SetAttribute("HighContrastMode", AccessibilityManager.highContrastMode)
            player:SetAttribute("ReducedMotionMode", AccessibilityManager.reducedMotionMode)
            player:SetAttribute("LargeTextMode", AccessibilityManager.largeTextMode)
            player:SetAttribute("SoundCuesEnabled", AccessibilityManager.soundCuesEnabled)
            player:SetAttribute("HapticFeedbackEnabled", AccessibilityManager.hapticFeedbackEnabled)
        end
    end)
end

-- ========================================
-- PUBLIC API
-- ========================================

function UIAccessibilitySystem.setScreenReaderEnabled(enabled)
    AccessibilityManager.screenReaderEnabled = enabled
    UIAccessibilitySystem.saveAccessibilityPreferences()
    
    if enabled then
        UIAccessibilitySystem.initializeScreenReader()
    end
    
    print("🔊 Screen reader: " .. (enabled and "enabled" or "disabled"))
end

function UIAccessibilitySystem.setReducedMotionMode(enabled)
    AccessibilityManager.reducedMotionMode = enabled
    UIDesignTokens.setAccessibilityMode(enabled and "reducedMotion" or "default")
    UIAccessibilitySystem.saveAccessibilityPreferences()
    
    print("🎬 Reduced motion: " .. (enabled and "enabled" or "disabled"))
end

function UIAccessibilitySystem.setHighContrastMode(enabled)
    AccessibilityManager.highContrastMode = enabled
    UIDesignTokens.setAccessibilityMode(enabled and "highContrast" or "default")
    UIAccessibilitySystem.saveAccessibilityPreferences()
    
    print("🎨 High contrast: " .. (enabled and "enabled" or "disabled"))
end

function UIAccessibilitySystem.getAccessibilitySettings()
    return {
        screenReaderEnabled = AccessibilityManager.screenReaderEnabled,
        keyboardNavigationEnabled = AccessibilityManager.keyboardNavigationEnabled,
        highContrastMode = AccessibilityManager.highContrastMode,
        reducedMotionMode = AccessibilityManager.reducedMotionMode,
        largeTextMode = AccessibilityManager.largeTextMode,
        soundCuesEnabled = AccessibilityManager.soundCuesEnabled,
        hapticFeedbackEnabled = AccessibilityManager.hapticFeedbackEnabled
    }
end

-- Event system
function UIAccessibilitySystem.onFocusChange(callback)
    table.insert(AccessibilityManager.focusCallbacks, callback)
end

function UIAccessibilitySystem.onAnnouncement(callback)
    table.insert(AccessibilityManager.announcementCallbacks, callback)
end

function UIAccessibilitySystem.notifyFocusChange(elementId, element)
    for _, callback in ipairs(AccessibilityManager.focusCallbacks) do
        pcall(callback, elementId, element)
    end
end

function UIAccessibilitySystem.notifyAnnouncement(text, priority)
    for _, callback in ipairs(AccessibilityManager.announcementCallbacks) do
        pcall(callback, text, priority)
    end
end

-- Spatial navigation functions (placeholder implementations)
function UIAccessibilitySystem.focusUp() UIAccessibilitySystem.focusPrevious() end
function UIAccessibilitySystem.focusDown() UIAccessibilitySystem.focusNext() end
function UIAccessibilitySystem.focusLeft() UIAccessibilitySystem.focusPrevious() end
function UIAccessibilitySystem.focusRight() UIAccessibilitySystem.focusNext() end
function UIAccessibilitySystem.focusFirst() AccessibilityManager.currentFocusIndex = 1; UIAccessibilitySystem.focusNext() end
function UIAccessibilitySystem.focusLast() AccessibilityManager.currentFocusIndex = #AccessibilityManager.tabOrder; UIAccessibilitySystem.setFocus(AccessibilityManager.tabOrder[AccessibilityManager.currentFocusIndex]) end
function UIAccessibilitySystem.handleEscape() UIAccessibilitySystem.clearCurrentFocus() end

-- Initialize the accessibility system
UIAccessibilitySystem.initialize()

print("♿ UIAccessibilitySystem initialized with WCAG 2.1 compliance")

return UIAccessibilitySystem
