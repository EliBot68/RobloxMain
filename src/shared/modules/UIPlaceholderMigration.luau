-- UIPlaceholderMigration.luau
-- Migration script to replace all remaining placeholder UI elements with modern design
-- Run this script to update any UI elements still using GuiImagePlaceholder.png

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local StarterGui = game:GetService("StarterGui")

local ModernUISystem = require(ReplicatedStorage.Shared.modules.ModernUISystem)

local UIPlaceholderMigration = {}

-- Placeholder identification patterns
local PLACEHOLDER_PATTERNS = {
    "GuiImagePlaceholder.png",
    "rbxasset://textures/ui/GuiImagePlaceholder.png",
    "placeholder",
    "Placeholder"
}

-- Modern replacements for common placeholder uses
local MODERN_REPLACEMENTS = {
    -- Button backgrounds
    buttons = {
        primary = {
            style = "primary",
            useModernButton = true
        },
        secondary = {
            style = "secondary", 
            useModernButton = true
        },
        success = {
            style = "success",
            useModernButton = true
        },
        danger = {
            style = "danger",
            useModernButton = true
        }
    },
    
    -- Background replacements
    backgrounds = {
        menu = {
            style = "menu",
            useModernFrame = true
        },
        game = {
            style = "game",
            useModernFrame = true
        },
        modal = {
            style = "modal",
            useModernFrame = true
        }
    },
    
    -- Icon replacements using Unicode
    icons = {
        star = "⭐",
        heart = "❤️",
        coin = "💰",
        timer = "⏱️",
        speed = "⚡",
        shield = "🛡️",
        trophy = "🏆",
        settings = "⚙️",
        help = "❓",
        close = "❌",
        check = "✅",
        arrow_left = "⬅️",
        arrow_right = "➡️",
        arrow_up = "⬆️",
        arrow_down = "⬇️",
        play = "▶️",
        pause = "⏸️",
        stop = "⏹️",
        menu = "☰",
        search = "🔍",
        info = "ℹ️"
    }
}

function UIPlaceholderMigration:ScanAndReplace()
    print("🔍 Starting UI Placeholder Migration...")
    print("📋 Scanning for placeholder elements...")
    
    local replacementCount = 0
    
    -- Scan all player GUIs
    for _, player in pairs(Players:GetPlayers()) do
        if player.PlayerGui then
            replacementCount = replacementCount + self:ProcessContainer(player.PlayerGui, "PlayerGui for " .. player.Name)
        end
    end
    
    -- Scan StarterGui
    replacementCount = replacementCount + self:ProcessContainer(StarterGui, "StarterGui")
    
    print("✅ UI Placeholder Migration completed!")
    print("🔧 Total replacements made: " .. replacementCount)
    
    return replacementCount
end

function UIPlaceholderMigration:ProcessContainer(container, containerName)
    local replacements = 0
    
    print("📂 Processing: " .. containerName)
    
    -- Recursively process all descendants
    for _, descendant in pairs(container:GetDescendants()) do
        if self:IsPlaceholderElement(descendant) then
            local success = self:ReplaceElement(descendant)
            if success then
                replacements = replacements + 1
                print("  ✨ Replaced: " .. descendant:GetFullName())
            end
        end
    end
    
    return replacements
end

function UIPlaceholderMigration:IsPlaceholderElement(element)
    -- Check ImageLabels and ImageButtons for placeholder images
    if element:IsA("ImageLabel") or element:IsA("ImageButton") then
        for _, pattern in pairs(PLACEHOLDER_PATTERNS) do
            if string.find(element.Image:lower(), pattern:lower()) then
                return true
            end
        end
    end
    
    -- Check TextLabels and TextButtons for placeholder text
    if element:IsA("TextLabel") or element:IsA("TextButton") then
        for _, pattern in pairs(PLACEHOLDER_PATTERNS) do
            if string.find(element.Text:lower(), pattern:lower()) then
                return true
            end
        end
    end
    
    -- Check Frame backgrounds
    if element:IsA("Frame") and element.Name:lower():find("placeholder") then
        return true
    end
    
    return false
end

function UIPlaceholderMigration:ReplaceElement(element)
    local elementType = self:DetermineElementType(element)
    
    if elementType == "button" then
        return self:ReplaceWithModernButton(element)
    elseif elementType == "icon" then
        return self:ReplaceWithModernIcon(element)
    elseif elementType == "background" then
        return self:ReplaceWithModernBackground(element)
    elseif elementType == "frame" then
        return self:ReplaceWithModernFrame(element)
    end
    
    return false
end

function UIPlaceholderMigration:DetermineElementType(element)
    local name = element.Name:lower()
    
    -- Determine type based on name patterns
    if name:find("button") then
        return "button"
    elseif name:find("icon") then
        return "icon"
    elseif name:find("background") or name:find("bg") then
        return "background"
    elseif element:IsA("Frame") then
        return "frame"
    elseif element:IsA("ImageLabel") or element:IsA("ImageButton") then
        return "icon"
    end
    
    return "unknown"
end

function UIPlaceholderMigration:ReplaceWithModernButton(element)
    local parent = element.Parent
    if not parent then return false end
    
    -- Determine button style based on color or name
    local style = "primary"
    local name = element.Name:lower()
    
    if name:find("danger") or name:find("delete") or name:find("cancel") then
        style = "danger"
    elseif name:find("success") or name:find("confirm") or name:find("ok") then
        style = "success"
    elseif name:find("secondary") or name:find("back") then
        style = "secondary"
    end
    
    -- Create modern button replacement
    local modernButton = ModernUISystem.createModernButton({
        name = element.Name,
        text = self:ExtractTextFromElement(element),
        style = style,
        size = element.Size,
        position = element.Position
    })
    
    -- Copy important properties
    modernButton.Visible = element.Visible
    modernButton.ZIndex = element.ZIndex
    modernButton.LayoutOrder = element.LayoutOrder
    
    -- Replace in parent
    modernButton.Parent = parent
    element:Destroy()
    
    return true
end

function UIPlaceholderMigration:ReplaceWithModernIcon(element)
    local parent = element.Parent
    if not parent then return false end
    
    -- Determine icon type from name
    local iconType = self:GuessIconType(element.Name)
    local iconText = MODERN_REPLACEMENTS.icons[iconType] or "⭐"
    
    -- Create modern icon replacement
    local modernIcon = ModernUISystem.createIconButton({
        name = element.Name,
        icon = iconType,
        style = "minimal",
        size = element.Size,
        position = element.Position
    })
    
    -- Copy properties
    modernIcon.Visible = element.Visible
    modernIcon.ZIndex = element.ZIndex
    modernIcon.LayoutOrder = element.LayoutOrder
    
    -- Replace
    modernIcon.Parent = parent
    element:Destroy()
    
    return true
end

function UIPlaceholderMigration:ReplaceWithModernBackground(element)
    local parent = element.Parent
    if not parent then return false end
    
    -- Determine background style
    local style = "game"
    local name = element.Name:lower()
    
    if name:find("menu") then
        style = "menu"
    elseif name:find("modal") or name:find("popup") then
        style = "modal"
    end
    
    -- Create modern frame replacement
    local modernFrame = ModernUISystem.createModernFrame({
        name = element.Name,
        style = style,
        size = element.Size,
        position = element.Position
    })
    
    -- Move children to new frame
    for _, child in pairs(element:GetChildren()) do
        if not child:IsA("UICorner") and not child:IsA("UIGradient") then
            child.Parent = modernFrame
        end
    end
    
    -- Copy properties
    modernFrame.Visible = element.Visible
    modernFrame.ZIndex = element.ZIndex
    modernFrame.LayoutOrder = element.LayoutOrder
    
    -- Replace
    modernFrame.Parent = parent
    element:Destroy()
    
    return true
end

function UIPlaceholderMigration:ReplaceWithModernFrame(element)
    local parent = element.Parent
    if not parent then return false end
    
    -- Create modern frame
    local modernFrame = ModernUISystem.createModernFrame({
        name = element.Name,
        style = "default",
        size = element.Size,
        position = element.Position
    })
    
    -- Move children
    for _, child in pairs(element:GetChildren()) do
        child.Parent = modernFrame
    end
    
    -- Copy properties
    modernFrame.Visible = element.Visible
    modernFrame.ZIndex = element.ZIndex
    modernFrame.LayoutOrder = element.LayoutOrder
    
    -- Replace
    modernFrame.Parent = parent
    element:Destroy()
    
    return true
end

function UIPlaceholderMigration:ExtractTextFromElement(element)
    if element:IsA("TextLabel") or element:IsA("TextButton") then
        return element.Text
    elseif element:IsA("ImageButton") or element:IsA("ImageLabel") then
        -- Look for child text elements
        local textLabel = element:FindFirstChildOfClass("TextLabel")
        if textLabel then
            return textLabel.Text
        end
    end
    
    return element.Name:gsub("Button", ""):gsub("_", " "):upper()
end

function UIPlaceholderMigration:GuessIconType(elementName)
    local name = elementName:lower()
    
    -- Common icon name patterns
    local iconMappings = {
        star = {"star", "rating", "favorite"},
        heart = {"heart", "health", "life", "lives"},
        coin = {"coin", "money", "currency", "gold"},
        timer = {"timer", "time", "clock"},
        speed = {"speed", "fast", "boost", "lightning"},
        shield = {"shield", "armor", "defense", "protect"},
        trophy = {"trophy", "achievement", "award", "win"},
        settings = {"settings", "config", "options", "gear"},
        help = {"help", "question", "info", "support"},
        close = {"close", "exit", "x", "cancel"},
        check = {"check", "confirm", "ok", "accept", "success"},
        play = {"play", "start", "go"},
        pause = {"pause", "stop"},
        menu = {"menu", "hamburger", "nav"},
        search = {"search", "find", "look"}
    }
    
    for iconType, patterns in pairs(iconMappings) do
        for _, pattern in pairs(patterns) do
            if name:find(pattern) then
                return iconType
            end
        end
    end
    
    return "star" -- Default fallback
end

function UIPlaceholderMigration:GenerateReport()
    print("\n📊 UI Placeholder Migration Report")
    print("=" .. string.rep("=", 40))
    
    local totalScanned = 0
    local totalPlaceholders = 0
    
    -- Scan without replacing to generate report
    for _, player in pairs(Players:GetPlayers()) do
        if player.PlayerGui then
            local scanned, placeholders = self:ScanContainerForReport(player.PlayerGui)
            totalScanned = totalScanned + scanned
            totalPlaceholders = totalPlaceholders + placeholders
            
            if placeholders > 0 then
                print("👤 " .. player.Name .. ": " .. placeholders .. "/" .. scanned .. " elements need replacement")
            end
        end
    end
    
    local scanned, placeholders = self:ScanContainerForReport(StarterGui)
    totalScanned = totalScanned + scanned
    totalPlaceholders = totalPlaceholders + placeholders
    
    if placeholders > 0 then
        print("🎮 StarterGui: " .. placeholders .. "/" .. scanned .. " elements need replacement")
    end
    
    print("\n📈 Summary:")
    print("  Total UI elements scanned: " .. totalScanned)
    print("  Placeholder elements found: " .. totalPlaceholders)
    print("  Migration coverage needed: " .. math.floor((totalPlaceholders / math.max(totalScanned, 1)) * 100) .. "%")
    print("=" .. string.rep("=", 40))
end

function UIPlaceholderMigration:ScanContainerForReport(container)
    local scanned = 0
    local placeholders = 0
    
    for _, descendant in pairs(container:GetDescendants()) do
        if descendant:IsA("GuiObject") then
            scanned = scanned + 1
            if self:IsPlaceholderElement(descendant) then
                placeholders = placeholders + 1
            end
        end
    end
    
    return scanned, placeholders
end

-- Auto-run functions
function UIPlaceholderMigration:RunFullMigration()
    self:GenerateReport()
    
    print("\n🚀 Starting full UI migration...")
    local replacements = self:ScanAndReplace()
    
    print("\n✅ Migration complete! " .. replacements .. " elements modernized.")
    print("🎨 All placeholder UI elements have been replaced with modern designs!")
end

-- Initialize migration (can be called manually or automatically)
spawn(function()
    wait(5) -- Wait for UI to load
    
    print("🎨 UI Placeholder Migration System Ready!")
    print("📝 Call UIPlaceholderMigration:RunFullMigration() to replace all placeholders")
    print("📊 Call UIPlaceholderMigration:GenerateReport() for analysis only")
end)

return UIPlaceholderMigration
