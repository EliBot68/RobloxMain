-- UIDesignTokens.luau
-- Comprehensive design tokens and theming system
-- Provides consistent design language across all UI components

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local GuiService = game:GetService("GuiService")

local UIDesignTokens = {}

-- ========================================
-- DESIGN TOKEN DEFINITIONS
-- ========================================

local DESIGN_TOKENS = {
    -- Color System
    colors = {
        -- Brand Colors
        brand = {
            primary = Color3.fromRGB(0, 122, 255),      -- System Blue
            secondary = Color3.fromRGB(88, 86, 214),    -- System Indigo
            tertiary = Color3.fromRGB(175, 82, 222),    -- System Purple
            quaternary = Color3.fromRGB(255, 45, 85)    -- System Pink
        },
        
        -- Semantic Colors
        semantic = {
            success = Color3.fromRGB(52, 199, 89),      -- System Green
            warning = Color3.fromRGB(255, 149, 0),      -- System Orange
            error = Color3.fromRGB(255, 59, 48),        -- System Red
            info = Color3.fromRGB(0, 122, 255),         -- System Blue
            neutral = Color3.fromRGB(142, 142, 147)     -- System Gray
        },
        
        -- Grayscale Palette
        gray = {
            gray50 = Color3.fromRGB(249, 249, 249),
            gray100 = Color3.fromRGB(244, 244, 244),
            gray200 = Color3.fromRGB(229, 229, 229),
            gray300 = Color3.fromRGB(212, 212, 212),
            gray400 = Color3.fromRGB(163, 163, 163),
            gray500 = Color3.fromRGB(115, 115, 115),
            gray600 = Color3.fromRGB(82, 82, 82),
            gray700 = Color3.fromRGB(64, 64, 64),
            gray800 = Color3.fromRGB(38, 38, 38),
            gray900 = Color3.fromRGB(23, 23, 23)
        },
        
        -- Background System
        background = {
            primary = Color3.fromRGB(255, 255, 255),
            secondary = Color3.fromRGB(249, 249, 249),
            tertiary = Color3.fromRGB(244, 244, 244),
            overlay = Color3.fromRGB(0, 0, 0)
        },
        
        -- Text System
        text = {
            primary = Color3.fromRGB(23, 23, 23),
            secondary = Color3.fromRGB(82, 82, 82),
            tertiary = Color3.fromRGB(115, 115, 115),
            quaternary = Color3.fromRGB(163, 163, 163),
            inverse = Color3.fromRGB(255, 255, 255),
            link = Color3.fromRGB(0, 122, 255),
            accent = Color3.fromRGB(88, 86, 214)
        },
        
        -- Surface Colors
        surface = {
            elevated = Color3.fromRGB(255, 255, 255),
            base = Color3.fromRGB(249, 249, 249),
            sunken = Color3.fromRGB(244, 244, 244),
            overlay = Color3.fromRGB(255, 255, 255)
        },
        
        -- Interactive States
        interactive = {
            enabled = Color3.fromRGB(0, 122, 255),
            hover = Color3.fromRGB(0, 99, 230),
            pressed = Color3.fromRGB(0, 76, 204),
            disabled = Color3.fromRGB(163, 163, 163),
            focus = Color3.fromRGB(0, 122, 255)
        }
    },
    
    -- Typography System
    typography = {
        -- Font Families
        fonts = {
            primary = Enum.Font.Inter,
            secondary = Enum.Font.InterMedium,
            accent = Enum.Font.InterBold,
            monospace = Enum.Font.RobotoMono,
            display = Enum.Font.InterDisplay
        },
        
        -- Font Sizes (Mobile-first responsive)
        sizes = {
            xs = 12,    -- Caption text
            sm = 14,    -- Small text
            base = 16,  -- Body text
            lg = 18,    -- Large body
            xl = 20,    -- Small heading
            xxl = 24,   -- Medium heading
            xxxl = 30,  -- Large heading
            xxxxl = 36, -- Display heading
            xxxxxl = 48 -- Hero heading
        },
        
        -- Line Heights
        lineHeights = {
            tight = 1.2,
            normal = 1.4,
            relaxed = 1.6,
            loose = 1.8
        },
        
        -- Font Weights
        weights = {
            light = Enum.FontWeight.Light,
            regular = Enum.FontWeight.Regular,
            medium = Enum.FontWeight.Medium,
            semibold = Enum.FontWeight.SemiBold,
            bold = Enum.FontWeight.Bold,
            heavy = Enum.FontWeight.Heavy
        }
    },
    
    -- Spacing System (8px base unit)
    spacing = {
        px = 1,     -- 1px
        xs = 4,     -- 4px
        sm = 8,     -- 8px (base unit)
        md = 16,    -- 16px
        lg = 24,    -- 24px
        xl = 32,    -- 32px
        xxl = 48,   -- 48px
        xxxl = 64,  -- 64px
        xxxxl = 96, -- 96px
        xxxxxl = 128 -- 128px
    },
    
    -- Border Radius System
    borderRadius = {
        none = 0,
        xs = 2,
        sm = 4,
        base = 6,
        md = 8,
        lg = 12,
        xl = 16,
        xxl = 24,
        round = 9999,
        circle = 50 -- Percentage-based circular
    },
    
    -- Border Width System
    borderWidth = {
        none = 0,
        thin = 1,
        base = 2,
        thick = 4,
        thicker = 8
    },
    
    -- Shadow System
    shadows = {
        none = {
            offset = Vector2.new(0, 0),
            blur = 0,
            transparency = 1
        },
        xs = {
            offset = Vector2.new(0, 1),
            blur = 2,
            transparency = 0.05
        },
        sm = {
            offset = Vector2.new(0, 1),
            blur = 3,
            transparency = 0.1
        },
        base = {
            offset = Vector2.new(0, 1),
            blur = 6,
            transparency = 0.1
        },
        md = {
            offset = Vector2.new(0, 4),
            blur = 6,
            transparency = 0.07
        },
        lg = {
            offset = Vector2.new(0, 10),
            blur = 15,
            transparency = 0.1
        },
        xl = {
            offset = Vector2.new(0, 20),
            blur = 25,
            transparency = 0.1
        },
        xxl = {
            offset = Vector2.new(0, 25),
            blur = 50,
            transparency = 0.25
        }
    },
    
    -- Z-Index System
    zIndex = {
        hide = -1,
        auto = 0,
        base = 1,
        docked = 10,
        dropdown = 1000,
        sticky = 1100,
        banner = 1200,
        overlay = 1300,
        modal = 1400,
        popover = 1500,
        skipLink = 1600,
        toast = 1700,
        tooltip = 1800
    },
    
    -- Opacity System
    opacity = {
        transparent = 0,
        subtle = 0.05,
        light = 0.1,
        soft = 0.2,
        medium = 0.4,
        strong = 0.6,
        heavy = 0.8,
        opaque = 1
    },
    
    -- Touch Target Sizes (Accessibility)
    touchTargets = {
        minimum = 44,   -- WCAG AA minimum
        comfortable = 48,
        large = 56,
        extraLarge = 64
    },
    
    -- Breakpoints for Responsive Design
    breakpoints = {
        phone = 480,
        tablet = 768,
        desktop = 1024,
        largeDesktop = 1440
    }
}

-- ========================================
-- DARK MODE VARIANTS
-- ========================================

local DARK_MODE_TOKENS = {
    colors = {
        background = {
            primary = Color3.fromRGB(23, 23, 23),
            secondary = Color3.fromRGB(38, 38, 38),
            tertiary = Color3.fromRGB(64, 64, 64),
            overlay = Color3.fromRGB(0, 0, 0)
        },
        
        text = {
            primary = Color3.fromRGB(255, 255, 255),
            secondary = Color3.fromRGB(229, 229, 229),
            tertiary = Color3.fromRGB(212, 212, 212),
            quaternary = Color3.fromRGB(163, 163, 163),
            inverse = Color3.fromRGB(23, 23, 23),
            link = Color3.fromRGB(0, 122, 255),
            accent = Color3.fromRGB(88, 86, 214)
        },
        
        surface = {
            elevated = Color3.fromRGB(38, 38, 38),
            base = Color3.fromRGB(23, 23, 23),
            sunken = Color3.fromRGB(18, 18, 18),
            overlay = Color3.fromRGB(64, 64, 64)
        }
    }
}

-- ========================================
-- ACCESSIBILITY THEMES
-- ========================================

local ACCESSIBILITY_THEMES = {
    highContrast = {
        colors = {
            background = {
                primary = Color3.fromRGB(0, 0, 0),
                secondary = Color3.fromRGB(255, 255, 255)
            },
            text = {
                primary = Color3.fromRGB(255, 255, 255),
                secondary = Color3.fromRGB(0, 0, 0)
            },
            brand = {
                primary = Color3.fromRGB(255, 255, 0),
                secondary = Color3.fromRGB(0, 255, 255)
            }
        }
    },
    
    colorBlind = {
        colors = {
            brand = {
                primary = Color3.fromRGB(0, 104, 183),    -- Blue (safe)
                secondary = Color3.fromRGB(213, 94, 0),   -- Orange (safe)
                tertiary = Color3.fromRGB(0, 158, 115),   -- Green (safe)
                quaternary = Color3.fromRGB(204, 121, 167) -- Pink (safe)
            },
            semantic = {
                success = Color3.fromRGB(0, 158, 115),
                warning = Color3.fromRGB(213, 94, 0),
                error = Color3.fromRGB(230, 159, 0),
                info = Color3.fromRGB(0, 104, 183)
            }
        }
    },
    
    reducedMotion = {
        animations = {
            duration = 0, -- Disable animations
            easing = Enum.EasingStyle.Linear
        }
    }
}

-- ========================================
-- THEME MANAGEMENT
-- ========================================

local currentTheme = "light"
local currentAccessibilityMode = "default"
local themeChangeCallbacks = {}

-- Core theme getter
function UIDesignTokens.getTokens(tokenPath)
    local tokens = DESIGN_TOKENS
    
    -- Apply dark mode overrides
    if currentTheme == "dark" then
        tokens = UIDesignTokens.mergeTokens(tokens, DARK_MODE_TOKENS)
    end
    
    -- Apply accessibility overrides
    if currentAccessibilityMode ~= "default" then
        local accessibilityTokens = ACCESSIBILITY_THEMES[currentAccessibilityMode]
        if accessibilityTokens then
            tokens = UIDesignTokens.mergeTokens(tokens, accessibilityTokens)
        end
    end
    
    -- Navigate to specific token if path provided
    if tokenPath then
        local keys = string.split(tokenPath, ".")
        local result = tokens
        
        for _, key in ipairs(keys) do
            if result[key] then
                result = result[key]
            else
                warn("Token path not found: " .. tokenPath)
                return nil
            end
        end
        
        return result
    end
    
    return tokens
end

-- Specific token getters
function UIDesignTokens.getColors()
    return UIDesignTokens.getTokens("colors")
end

function UIDesignTokens.getTypography()
    return UIDesignTokens.getTokens("typography")
end

function UIDesignTokens.getSpacing()
    return UIDesignTokens.getTokens("spacing")
end

function UIDesignTokens.getBorderRadius()
    return UIDesignTokens.getTokens("borderRadius")
end

function UIDesignTokens.getShadows()
    return UIDesignTokens.getTokens("shadows")
end

function UIDesignTokens.getZIndex()
    return UIDesignTokens.getTokens("zIndex")
end

-- Responsive design helpers
function UIDesignTokens.getResponsiveSize(baseSizeKey, deviceType)
    local sizes = UIDesignTokens.getTokens("typography.sizes")
    local baseSize = sizes[baseSizeKey] or sizes.base
    
    -- Scale based on device type
    local scaleFactor = 1
    
    if deviceType == "phone" then
        scaleFactor = 0.9
    elseif deviceType == "tablet" then
        scaleFactor = 1.0
    elseif deviceType == "desktop" then
        scaleFactor = 1.1
    end
    
    return math.floor(baseSize * scaleFactor)
end

function UIDesignTokens.getResponsiveSpacing(spacingKey, deviceType)
    local spacing = UIDesignTokens.getTokens("spacing")
    local baseSpacing = spacing[spacingKey] or spacing.md
    
    -- Scale based on device type
    local scaleFactor = 1
    
    if deviceType == "phone" then
        scaleFactor = 0.8
    elseif deviceType == "tablet" then
        scaleFactor = 1.0
    elseif deviceType == "desktop" then
        scaleFactor = 1.2
    end
    
    return math.floor(baseSpacing * scaleFactor)
end

-- Touch target helpers
function UIDesignTokens.getTouchTargetSize(sizeVariant, isTouch)
    local touchTargets = UIDesignTokens.getTokens("touchTargets")
    
    if not isTouch then
        -- Non-touch devices can use smaller targets
        return math.max(touchTargets[sizeVariant] - 8, 24)
    end
    
    return touchTargets[sizeVariant] or touchTargets.comfortable
end

-- ========================================
-- THEME SWITCHING
-- ========================================

function UIDesignTokens.setTheme(theme)
    if theme ~= "light" and theme ~= "dark" then
        warn("Invalid theme: " .. tostring(theme))
        return false
    end
    
    local previousTheme = currentTheme
    currentTheme = theme
    
    -- Store preference
    pcall(function()
        local Players = game:GetService("Players")
        local player = Players.LocalPlayer
        if player then
            player:SetAttribute("UITheme", theme)
        end
    end)
    
    -- Notify callbacks
    UIDesignTokens.notifyThemeChange(theme, previousTheme)
    
    print("🎨 Theme changed to: " .. theme)
    return true
end

function UIDesignTokens.setAccessibilityMode(mode)
    local validModes = {"default", "highContrast", "colorBlind", "reducedMotion"}
    
    if not table.find(validModes, mode) then
        warn("Invalid accessibility mode: " .. tostring(mode))
        return false
    end
    
    local previousMode = currentAccessibilityMode
    currentAccessibilityMode = mode
    
    -- Store preference
    pcall(function()
        local Players = game:GetService("Players")
        local player = Players.LocalPlayer
        if player then
            player:SetAttribute("UIAccessibilityMode", mode)
        end
    end)
    
    -- Notify callbacks
    UIDesignTokens.notifyThemeChange(currentTheme, currentTheme)
    
    print("♿ Accessibility mode changed to: " .. mode)
    return true
end

function UIDesignTokens.getTheme()
    return currentTheme
end

function UIDesignTokens.getAccessibilityMode()
    return currentAccessibilityMode
end

-- Auto-detect system preferences
function UIDesignTokens.detectSystemPreferences()
    -- Try to detect dark mode preference (limited in Roblox)
    local success, result = pcall(function()
        local Players = game:GetService("Players")
        local player = Players.LocalPlayer
        
        if player then
            local savedTheme = player:GetAttribute("UITheme")
            local savedAccessibility = player:GetAttribute("UIAccessibilityMode")
            
            if savedTheme then
                UIDesignTokens.setTheme(savedTheme)
            end
            
            if savedAccessibility then
                UIDesignTokens.setAccessibilityMode(savedAccessibility)
            end
        end
    end)
    
    if not success then
        print("⚠️ Could not load saved theme preferences")
    end
end

-- ========================================
-- UTILITY FUNCTIONS
-- ========================================

function UIDesignTokens.mergeTokens(baseTokens, overrideTokens)
    local merged = {}
    
    -- Deep copy base tokens
    for key, value in pairs(baseTokens) do
        if type(value) == "table" then
            merged[key] = UIDesignTokens.mergeTokens(value, {})
        else
            merged[key] = value
        end
    end
    
    -- Apply overrides
    for key, value in pairs(overrideTokens) do
        if type(value) == "table" and merged[key] and type(merged[key]) == "table" then
            merged[key] = UIDesignTokens.mergeTokens(merged[key], value)
        else
            merged[key] = value
        end
    end
    
    return merged
end

function UIDesignTokens.onThemeChange(callback)
    table.insert(themeChangeCallbacks, callback)
    
    return function()
        local index = table.find(themeChangeCallbacks, callback)
        if index then
            table.remove(themeChangeCallbacks, index)
        end
    end
end

function UIDesignTokens.notifyThemeChange(newTheme, previousTheme)
    for _, callback in ipairs(themeChangeCallbacks) do
        pcall(callback, newTheme, previousTheme)
    end
end

-- Color manipulation utilities
function UIDesignTokens.adjustColorOpacity(color, opacity)
    return Color3.new(color.R, color.G, color.B), 1 - opacity
end

function UIDesignTokens.blendColors(color1, color2, factor)
    return Color3.new(
        color1.R + (color2.R - color1.R) * factor,
        color1.G + (color2.G - color1.G) * factor,
        color1.B + (color2.B - color1.B) * factor
    )
end

function UIDesignTokens.getContrastingTextColor(backgroundColor)
    local luminance = 0.299 * backgroundColor.R + 0.587 * backgroundColor.G + 0.114 * backgroundColor.B
    
    if luminance > 0.5 then
        return UIDesignTokens.getTokens("colors.text.primary")
    else
        return UIDesignTokens.getTokens("colors.text.inverse")
    end
end

-- Device detection
function UIDesignTokens.getDeviceType()
    local viewport = workspace.CurrentCamera.ViewportSize
    local breakpoints = UIDesignTokens.getTokens("breakpoints")
    
    if GuiService:IsTenFootInterface() then
        return "console"
    elseif UserInputService.TouchEnabled and not UserInputService.MouseEnabled then
        if viewport.X < breakpoints.tablet then
            return "phone"
        else
            return "tablet"
        end
    else
        if viewport.X < breakpoints.desktop then
            return "tablet"
        elseif viewport.X < breakpoints.largeDesktop then
            return "desktop"
        else
            return "largeDesktop"
        end
    end
end

-- Initialize system
UIDesignTokens.detectSystemPreferences()

print("🎨 UIDesignTokens initialized with comprehensive theming system")

return UIDesignTokens
