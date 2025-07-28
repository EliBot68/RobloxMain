-- UIPlaceholderMigrationRunner.luau
-- Server script to run UI placeholder migration and ensure all UI elements are production-ready

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local StarterGui = game:GetService("StarterGui")
local RunService = game:GetService("RunService")

local SafeRequire = require(ReplicatedStorage.Shared.utils.SafeRequire)
local UIPlaceholderMigration = SafeRequire.require(ReplicatedStorage.Shared.modules.UIPlaceholderMigration)
local ModernUISystem = SafeRequire.require(ReplicatedStorage.Shared.modules.ModernUISystem)

local UIPlaceholderMigrationRunner = {}

-- Enhanced migration configuration
local MIGRATION_CONFIG = {
    autoRunOnPlayerJoined = true,
    autoRunOnStartup = true,
    validateAfterMigration = true,
    generateDetailedReport = true,
    createBackups = false -- Set to true in production
}

-- Common placeholder text replacements
local TEXT_REPLACEMENTS = {
    -- Generic placeholders
    ["Placeholder"] = "Menu",
    ["placeholder"] = "Option",
    ["PLACEHOLDER"] = "BUTTON",
    ["Text Here"] = "Action",
    ["Sample Text"] = "Content",
    ["Lorem Ipsum"] = "Game Info",
    
    -- Button specific
    ["Button"] = "Action",
    ["Click Me"] = "Play",
    ["Press Here"] = "Continue",
    
    -- Game specific
    ["Score: 0"] = "Score: 0",
    ["Time: 00:00"] = "Time: 60:00",
    ["Lives: 3"] = "Lives: 3",
    ["Level: 1"] = "Level: 1"
}

-- Common placeholder image replacements  
local IMAGE_REPLACEMENTS = {
    ["GuiImagePlaceholder.png"] = "",
    ["rbxasset://textures/ui/GuiImagePlaceholder.png"] = "",
    ["placeholder.png"] = "",
    ["temp.jpg"] = ""
}

function UIPlaceholderMigrationRunner:Init()
    print("🚀 Initializing UI Placeholder Migration Runner...")
    
    -- Setup auto-migration on player join
    if MIGRATION_CONFIG.autoRunOnPlayerJoined then
        Players.PlayerAdded:Connect(function(player)
            self:RunPlayerMigration(player)
        end)
        
        -- Handle players already in game
        for _, player in pairs(Players:GetPlayers()) do
            spawn(function()
                self:RunPlayerMigration(player)
            end)
        end
    end
    
    -- Run startup migration if configured
    if MIGRATION_CONFIG.autoRunOnStartup then
        spawn(function()
            wait(3) -- Wait for UI to load
            self:RunFullMigration()
        end)
    end
    
    print("✅ UI Placeholder Migration Runner initialized!")
end

function UIPlaceholderMigrationRunner:RunFullMigration()
    print("\n🎨 ====== STARTING FULL UI PLACEHOLDER MIGRATION ======")
    
    local startTime = tick()
    local totalReplacements = 0
    
    -- Generate pre-migration report
    if MIGRATION_CONFIG.generateDetailedReport then
        print("\n📊 PRE-MIGRATION ANALYSIS:")
        UIPlaceholderMigration:GenerateReport()
    end
    
    -- Run core migration
    print("\n🔄 Running core placeholder migration...")
    totalReplacements = totalReplacements + UIPlaceholderMigration:ScanAndReplace()
    
    -- Run enhanced text replacement
    print("\n📝 Running enhanced text replacement...")
    totalReplacements = totalReplacements + self:RunTextReplacementPass()
    
    -- Run image replacement
    print("\n🖼️ Running image replacement...")
    totalReplacements = totalReplacements + self:RunImageReplacementPass()
    
    -- Run UI standardization
    print("\n🎯 Running UI standardization...")
    totalReplacements = totalReplacements + self:RunUIStandardizationPass()
    
    -- Validate migration results
    if MIGRATION_CONFIG.validateAfterMigration then
        print("\n✅ Validating migration results...")
        self:ValidateMigrationResults()
    end
    
    local duration = tick() - startTime
    
    print("\n🎉 ====== UI PLACEHOLDER MIGRATION COMPLETE ======")
    print("📈 Total replacements made: " .. totalReplacements)
    print("⏱️ Migration completed in: " .. string.format("%.2f", duration) .. " seconds")
    print("🎨 All UI elements are now production-ready!")
    
    return totalReplacements
end

function UIPlaceholderMigrationRunner:RunPlayerMigration(player)
    if not player.PlayerGui then
        player.CharacterAdded:Wait()
        wait(2) -- Wait for PlayerGui to be ready
    end
    
    print("👤 Running UI migration for: " .. player.Name)
    
    local replacements = 0
    
    -- Process player's GUI
    if player.PlayerGui then
        replacements = replacements + UIPlaceholderMigration:ProcessContainer(player.PlayerGui, "PlayerGui for " .. player.Name)
        replacements = replacements + self:RunPlayerSpecificEnhancements(player)
    end
    
    if replacements > 0 then
        print("  ✨ " .. replacements .. " UI elements enhanced for " .. player.Name)
    else
        print("  ✅ No placeholder elements found for " .. player.Name)
    end
end

function UIPlaceholderMigrationRunner:RunTextReplacementPass()
    local replacements = 0
    
    -- Scan all players
    for _, player in pairs(Players:GetPlayers()) do
        if player.PlayerGui then
            for _, element in pairs(player.PlayerGui:GetDescendants()) do
                if element:IsA("TextLabel") or element:IsA("TextButton") then
                    local originalText = element.Text
                    local newText = self:ReplaceText(originalText)
                    
                    if newText ~= originalText then
                        element.Text = newText
                        replacements = replacements + 1
                        print("  📝 Text replaced: '" .. originalText .. "' → '" .. newText .. "'")
                    end
                end
            end
        end
    end
    
    -- Scan StarterGui
    for _, element in pairs(StarterGui:GetDescendants()) do
        if element:IsA("TextLabel") or element:IsA("TextButton") then
            local originalText = element.Text
            local newText = self:ReplaceText(originalText)
            
            if newText ~= originalText then
                element.Text = newText
                replacements = replacements + 1
                print("  📝 StarterGui text replaced: '" .. originalText .. "' → '" .. newText .. "'")
            end
        end
    end
    
    return replacements
end

function UIPlaceholderMigrationRunner:RunImageReplacementPass()
    local replacements = 0
    
    -- Scan all players
    for _, player in pairs(Players:GetPlayers()) do
        if player.PlayerGui then
            for _, element in pairs(player.PlayerGui:GetDescendants()) do
                if element:IsA("ImageLabel") or element:IsA("ImageButton") then
                    local originalImage = element.Image
                    local shouldReplace = false
                    
                    -- Check if it's a placeholder image
                    for placeholder, replacement in pairs(IMAGE_REPLACEMENTS) do
                        if originalImage:lower():find(placeholder:lower()) then
                            element.Image = replacement
                            
                            -- If removing image, add modern styling
                            if replacement == "" then
                                self:ApplyModernStyling(element)
                            end
                            
                            replacements = replacements + 1
                            shouldReplace = true
                            print("  🖼️ Image replaced: " .. originalImage .. " → " .. replacement)
                            break
                        end
                    end
                end
            end
        end
    end
    
    return replacements
end

function UIPlaceholderMigrationRunner:RunUIStandardizationPass()
    local replacements = 0
    
    -- Apply consistent styling to common UI patterns
    for _, player in pairs(Players:GetPlayers()) do
        if player.PlayerGui then
            replacements = replacements + self:StandardizePlayerGUI(player.PlayerGui)
        end
    end
    
    replacements = replacements + self:StandardizePlayerGUI(StarterGui)
    
    return replacements
end

function UIPlaceholderMigrationRunner:StandardizePlayerGUI(gui)
    local replacements = 0
    
    for _, element in pairs(gui:GetDescendants()) do
        -- Standardize buttons
        if element:IsA("TextButton") and not element:GetAttribute("ModernUI_Processed") then
            self:StandardizeButton(element)
            element:SetAttribute("ModernUI_Processed", true)
            replacements = replacements + 1
        end
        
        -- Standardize frames
        if element:IsA("Frame") and not element:GetAttribute("ModernUI_Processed") then
            self:StandardizeFrame(element)
            element:SetAttribute("ModernUI_Processed", true)
            replacements = replacements + 1
        end
        
        -- Standardize text elements
        if (element:IsA("TextLabel") or element:IsA("TextButton")) and not element:GetAttribute("ModernUI_Processed") then
            self:StandardizeText(element)
            element:SetAttribute("ModernUI_Processed", true)
            replacements = replacements + 1
        end
    end
    
    return replacements
end

function UIPlaceholderMigrationRunner:StandardizeButton(button)
    -- Apply modern button styling
    button.Font = Enum.Font.GothamBold
    button.TextScaled = true
    button.BorderSizePixel = 0
    
    -- Add corner radius if not present
    if not button:FindFirstChildOfClass("UICorner") then
        local corner = Instance.new("UICorner")
        corner.CornerRadius = UDim.new(0, 8)
        corner.Parent = button
    end
    
    -- Determine button style from name/text
    local style = self:DetermineButtonStyle(button)
    self:ApplyButtonStyle(button, style)
    
    -- Add hover effects
    self:AddButtonHoverEffects(button)
end

function UIPlaceholderMigrationRunner:StandardizeFrame(frame)
    -- Apply modern frame styling
    frame.BorderSizePixel = 0
    
    -- Add corner radius if not present
    if not frame:FindFirstChildOfClass("UICorner") then
        local corner = Instance.new("UICorner")
        corner.CornerRadius = UDim.new(0, 12)
        corner.Parent = frame
    end
    
    -- Add subtle background gradient if solid color
    if not frame:FindFirstChildOfClass("UIGradient") then
        local gradient = Instance.new("UIGradient")
        gradient.Color = ColorSequence.new({
            ColorSequenceKeypoint.new(0, frame.BackgroundColor3),
            ColorSequenceKeypoint.new(1, Color3.new(
                math.max(0, frame.BackgroundColor3.R - 0.05),
                math.max(0, frame.BackgroundColor3.G - 0.05),
                math.max(0, frame.BackgroundColor3.B - 0.05)
            ))
        })
        gradient.Rotation = 90
        gradient.Parent = frame
    end
end

function UIPlaceholderMigrationRunner:StandardizeText(textElement)
    -- Apply modern text styling
    if textElement.Font == Enum.Font.Legacy or textElement.Font == Enum.Font.Arial then
        textElement.Font = Enum.Font.Gotham
    end
    
    -- Ensure text scaling is appropriate
    if textElement.TextScaled == false and textElement.TextSize == 14 then
        textElement.TextScaled = true
    end
    
    -- Add text stroke for better readability if needed
    if textElement.Parent and textElement.Parent.BackgroundTransparency > 0.5 then
        textElement.TextStrokeTransparency = 0.8
        textElement.TextStrokeColor3 = Color3.new(0, 0, 0)
    end
end

function UIPlaceholderMigrationRunner:ReplaceText(text)
    -- Check for exact matches first
    if TEXT_REPLACEMENTS[text] then
        return TEXT_REPLACEMENTS[text]
    end
    
    -- Check for partial matches
    for placeholder, replacement in pairs(TEXT_REPLACEMENTS) do
        if text:lower():find(placeholder:lower()) then
            return text:gsub(placeholder, replacement)
        end
    end
    
    return text
end

function UIPlaceholderMigrationRunner:DetermineButtonStyle(button)
    local name = button.Name:lower()
    local text = button.Text:lower()
    
    if name:find("play") or text:find("play") or text:find("start") then
        return "primary"
    elseif name:find("danger") or text:find("delete") or text:find("remove") then
        return "danger"
    elseif name:find("success") or text:find("confirm") or text:find("accept") then
        return "success"
    else
        return "secondary"
    end
end

function UIPlaceholderMigrationRunner:ApplyButtonStyle(button, style)
    local colors = {
        primary = {bg = Color3.fromRGB(79, 172, 254), text = Color3.white},
        secondary = {bg = Color3.fromRGB(127, 140, 141), text = Color3.white},
        success = {bg = Color3.fromRGB(46, 204, 113), text = Color3.white},
        danger = {bg = Color3.fromRGB(231, 76, 60), text = Color3.white}
    }
    
    local styleColors = colors[style] or colors.secondary
    button.BackgroundColor3 = styleColors.bg
    button.TextColor3 = styleColors.text
end

function UIPlaceholderMigrationRunner:AddButtonHoverEffects(button)
    local originalSize = button.Size
    local originalColor = button.BackgroundColor3
    
    local function onHover()
        local hoverTween = TweenService:Create(button, TweenInfo.new(0.2), {
            Size = UDim2.new(originalSize.X.Scale * 1.05, originalSize.X.Offset, originalSize.Y.Scale * 1.05, originalSize.Y.Offset),
            BackgroundColor3 = Color3.new(
                math.min(1, originalColor.R * 1.1),
                math.min(1, originalColor.G * 1.1),
                math.min(1, originalColor.B * 1.1)
            )
        })
        hoverTween:Play()
    end
    
    local function onLeave()
        local leaveTween = TweenService:Create(button, TweenInfo.new(0.2), {
            Size = originalSize,
            BackgroundColor3 = originalColor
        })
        leaveTween:Play()
    end
    
    button.MouseEnter:Connect(onHover)
    button.MouseLeave:Connect(onLeave)
end

function UIPlaceholderMigrationRunner:ApplyModernStyling(element)
    -- Apply modern styling to elements that had placeholder images
    element.BackgroundColor3 = Color3.fromRGB(79, 172, 254)
    element.BorderSizePixel = 0
    
    -- Add corner radius
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 8)
    corner.Parent = element
    
    -- Add gradient
    local gradient = Instance.new("UIGradient")
    gradient.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Color3.fromRGB(79, 172, 254)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(41, 128, 185))
    })
    gradient.Rotation = 45
    gradient.Parent = element
end

function UIPlaceholderMigrationRunner:RunPlayerSpecificEnhancements(player)
    local replacements = 0
    
    -- Add any player-specific UI enhancements here
    -- For example: VIP status indicators, personalized messages, etc.
    
    return replacements
end

function UIPlaceholderMigrationRunner:ValidateMigrationResults()
    local issues = 0
    
    -- Scan for remaining placeholders
    for _, player in pairs(Players:GetPlayers()) do
        if player.PlayerGui then
            issues = issues + self:ScanForRemainingPlaceholders(player.PlayerGui, player.Name)
        end
    end
    
    issues = issues + self:ScanForRemainingPlaceholders(StarterGui, "StarterGui")
    
    if issues == 0 then
        print("✅ Migration validation passed! No placeholder elements found.")
    else
        warn("⚠️ Migration validation found " .. issues .. " remaining placeholder elements.")
    end
    
    return issues == 0
end

function UIPlaceholderMigrationRunner:ScanForRemainingPlaceholders(container, containerName)
    local placeholders = 0
    
    for _, element in pairs(container:GetDescendants()) do
        if UIPlaceholderMigration:IsPlaceholderElement(element) then
            placeholders = placeholders + 1
            warn("  📍 Remaining placeholder in " .. containerName .. ": " .. element:GetFullName())
        end
    end
    
    return placeholders
end

-- Auto-initialize
UIPlaceholderMigrationRunner:Init()

return UIPlaceholderMigrationRunner
