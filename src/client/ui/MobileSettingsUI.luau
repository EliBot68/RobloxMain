-- MobileSettingsUI.luau
-- Mobile-optimized settings interface with responsive design

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local SoundService = game:GetService("SoundService")

local SafeRequire = require(ReplicatedStorage.Shared.utils.SafeRequire)
local RemoteEvents = SafeRequire.require(ReplicatedStorage.Shared.modules.RemoteEvents)
local MobileOptimizationService = require(script.Parent.Parent.services.MobileOptimizationService)

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local MobileSettingsUI = {}

-- Settings state
local settingsState = {
    isVisible = false,
    currentCategory = "General",
    settings = {
        -- Audio settings
        music_enabled = true,
        sfx_enabled = true,
        master_volume = 80,
        
        -- Graphics settings
        effects_enabled = true,
        trails_enabled = true,
        graphics_quality = "Medium",
        
        -- Control settings (mobile)
        haptic_enabled = true,
        button_size = 100,
        auto_jump = false,
        touch_sensitivity = 50,
        
        -- Gameplay settings
        camera_shake = true,
        screen_flash = true,
        auto_run = false,
        
        -- Accessibility settings
        colorblind_mode = false,
        high_contrast = false,
        large_text = false,
        reduce_motion = false
    }
}

local settingsGui = nil
local layoutProps = nil

-- Create mobile settings UI
function MobileSettingsUI.createSettingsUI()
    layoutProps = MobileOptimizationService.getLayoutProperties()
    local config = layoutProps.config
    
    -- Settings modal
    local settingsModal = MobileOptimizationService.createMobileModal({
        title = "⚙️ Settings",
        height = layoutProps.deviceType == "Phone" and 500 or 600,
        backgroundColor = Color3.fromRGB(248, 249, 250),
        closeOnBackgroundTap = true
    })
    
    settingsGui = settingsModal.overlay
    
    -- Create category tabs
    local tabContainer = Instance.new("Frame")
    tabContainer.Name = "TabContainer"
    tabContainer.Size = UDim2.new(1, 0, 0, layoutProps.deviceType == "Phone" and 40 or 50)
    tabContainer.Position = UDim2.new(0, 0, 0, 0)
    tabContainer.BackgroundColor3 = Color3.fromRGB(236, 240, 241)
    tabContainer.BorderSizePixel = 0
    tabContainer.Parent = settingsModal.contentArea
    
    local tabCorner = Instance.new("UICorner")
    tabCorner.CornerRadius = UDim.new(0, 6)
    tabCorner.Parent = tabContainer
    
    local tabLayout = Instance.new("UIListLayout")
    tabLayout.FillDirection = Enum.FillDirection.Horizontal
    tabLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
    tabLayout.VerticalAlignment = Enum.VerticalAlignment.Center
    tabLayout.Padding = UDim.new(0, 2)
    tabLayout.Parent = tabContainer
    
    -- Settings content area
    local contentScroll = MobileOptimizationService.createMobileScrollFrame({
        size = UDim2.new(1, 0, 1, -(layoutProps.deviceType == "Phone" and 50 or 60)),
        position = UDim2.new(0, 0, 0, layoutProps.deviceType == "Phone" and 45 or 55),
        backgroundColor = Color3.fromRGB(255, 255, 255),
        backgroundTransparency = 1,
        useListLayout = true,
        parent = settingsModal.contentArea
    })
    
    -- Create tabs and content
    local categories = {
        {name = "General", icon = "⚙️"},
        {name = "Audio", icon = "🔊"},
        {name = "Graphics", icon = "🎨"},
        {name = "Controls", icon = "📱"},
        {name = "Access", icon = "♿"}
    }
    
    -- Create tab buttons
    local tabButtons = {}
    for i, category in ipairs(categories) do
        local tabButton = MobileOptimizationService.createMobileButton({
            size = UDim2.new(0, layoutProps.deviceType == "Phone" and 65 or 80, 1, -4),
            backgroundColor = i == 1 and Color3.fromRGB(52, 152, 219) or Color3.fromRGB(189, 195, 199),
            text = layoutProps.deviceType == "Phone" and category.icon or (category.icon .. " " .. category.name),
            textSize = layoutProps.deviceType == "Phone" and config.fontSize.medium or config.fontSize.small,
            parent = tabContainer
        })
        
        tabButtons[category.name] = tabButton
        
        tabButton.MouseButton1Click:Connect(function()
            MobileSettingsUI.switchCategory(category.name, tabButtons, contentScroll, config)
        end)
    end
    
    -- Load initial category
    MobileSettingsUI.loadCategory("General", contentScroll, config)
    
    settingsState.isVisible = true
    return settingsModal
end

-- Switch settings category
function MobileSettingsUI.switchCategory(categoryName, tabButtons, contentArea, config)
    -- Update tab button states
    for name, button in pairs(tabButtons) do
        if name == categoryName then
            button.BackgroundColor3 = Color3.fromRGB(52, 152, 219)
        else
            button.BackgroundColor3 = Color3.fromRGB(189, 195, 199)
        end
    end
    
    -- Clear current content
    for _, child in ipairs(contentArea:GetChildren()) do
        if child:IsA("Frame") then
            child:Destroy()
        end
    end
    
    -- Load new category content
    MobileSettingsUI.loadCategory(categoryName, contentArea, config)
    settingsState.currentCategory = categoryName
end

-- Load category content
function MobileSettingsUI.loadCategory(categoryName, parent, config)
    if categoryName == "General" then
        MobileSettingsUI.createGeneralSettings(parent, config)
    elseif categoryName == "Audio" then
        MobileSettingsUI.createAudioSettings(parent, config)
    elseif categoryName == "Graphics" then
        MobileSettingsUI.createGraphicsSettings(parent, config)
    elseif categoryName == "Controls" then
        MobileSettingsUI.createControlSettings(parent, config)
    elseif categoryName == "Access" then
        MobileSettingsUI.createAccessibilitySettings(parent, config)
    end
end

-- Create general settings
function MobileSettingsUI.createGeneralSettings(parent, config)
    -- Account section
    MobileSettingsUI.createSettingsSection(parent, "👤 Account", {
        {type = "info", label = "Player Name", value = player.Name},
        {type = "info", label = "Player ID", value = tostring(player.UserId)},
        {type = "button", label = "Copy User ID", action = "copy_user_id"}
    }, config)
    
    -- Game preferences
    MobileSettingsUI.createSettingsSection(parent, "🎮 Game Preferences", {
        {type = "toggle", label = "Auto-Save Progress", key = "auto_save", value = true},
        {type = "toggle", label = "Show Tutorials", key = "show_tutorials", value = true},
        {type = "dropdown", label = "Preferred Game Mode", key = "game_mode", options = {"Solo", "Multiplayer", "Co-op"}, value = "Solo"}
    }, config)
    
    -- Data & Privacy
    MobileSettingsUI.createSettingsSection(parent, "🔒 Data & Privacy", {
        {type = "toggle", label = "Share Analytics", key = "analytics_enabled", value = true},
        {type = "toggle", label = "Crash Reporting", key = "crash_reporting", value = true},
        {type = "button", label = "Reset All Data", action = "reset_data", color = Color3.fromRGB(231, 76, 60)}
    }, config)
end

-- Create audio settings
function MobileSettingsUI.createAudioSettings(parent, config)
    -- Volume controls
    MobileSettingsUI.createSettingsSection(parent, "🔊 Volume", {
        {type = "slider", label = "Master Volume", key = "master_volume", min = 0, max = 100, value = settingsState.settings.master_volume},
        {type = "slider", label = "Music Volume", key = "music_volume", min = 0, max = 100, value = 80},
        {type = "slider", label = "SFX Volume", key = "sfx_volume", min = 0, max = 100, value = 90}
    }, config)
    
    -- Audio preferences
    MobileSettingsUI.createSettingsSection(parent, "🎵 Audio Preferences", {
        {type = "toggle", label = "Background Music", key = "music_enabled", value = settingsState.settings.music_enabled},
        {type = "toggle", label = "Sound Effects", key = "sfx_enabled", value = settingsState.settings.sfx_enabled},
        {type = "toggle", label = "UI Sounds", key = "ui_sounds", value = true},
        {type = "toggle", label = "Spatial Audio", key = "spatial_audio", value = false}
    }, config)
    
    -- Audio quality
    MobileSettingsUI.createSettingsSection(parent, "🎧 Audio Quality", {
        {type = "dropdown", label = "Audio Quality", key = "audio_quality", options = {"Low", "Medium", "High"}, value = "Medium"},
        {type = "toggle", label = "Audio Compression", key = "audio_compression", value = true}
    }, config)
end

-- Create graphics settings
function MobileSettingsUI.createGraphicsSettings(parent, config)
    -- Visual effects
    MobileSettingsUI.createSettingsSection(parent, "✨ Visual Effects", {
        {type = "toggle", label = "Particle Effects", key = "effects_enabled", value = settingsState.settings.effects_enabled},
        {type = "toggle", label = "Player Trails", key = "trails_enabled", value = settingsState.settings.trails_enabled},
        {type = "toggle", label = "Screen Effects", key = "screen_effects", value = true},
        {type = "toggle", label = "Bloom Effect", key = "bloom_effect", value = true}
    }, config)
    
    -- Performance
    MobileSettingsUI.createSettingsSection(parent, "⚡ Performance", {
        {type = "dropdown", label = "Graphics Quality", key = "graphics_quality", options = {"Low", "Medium", "High", "Ultra"}, value = settingsState.settings.graphics_quality},
        {type = "slider", label = "Frame Rate Limit", key = "fps_limit", min = 30, max = 120, value = 60},
        {type = "toggle", label = "V-Sync", key = "vsync", value = false}
    }, config)
    
    -- Visual preferences
    MobileSettingsUI.createSettingsSection(parent, "👁️ Visual Preferences", {
        {type = "toggle", label = "Camera Shake", key = "camera_shake", value = settingsState.settings.camera_shake},
        {type = "toggle", label = "Screen Flash", key = "screen_flash", value = settingsState.settings.screen_flash},
        {type = "slider", label = "Brightness", key = "brightness", min = 50, max = 150, value = 100}
    }, config)
end

-- Create control settings
function MobileSettingsUI.createControlSettings(parent, config)
    if not layoutProps.touchEnabled then
        -- Show message for non-touch devices
        local messageFrame = Instance.new("Frame")
        messageFrame.Size = UDim2.new(1, 0, 0, 100)
        messageFrame.BackgroundColor3 = Color3.fromRGB(241, 196, 15)
        messageFrame.BorderSizePixel = 0
        messageFrame.Parent = parent
        
        local messageLabel = Instance.new("TextLabel")
        messageLabel.Size = UDim2.new(1, -20, 1, 0)
        messageLabel.Position = UDim2.new(0, 10, 0, 0)
        messageLabel.BackgroundTransparency = 1
        messageLabel.Text = "📱 Touch controls are only available on mobile devices"
        messageLabel.TextColor3 = Color3.fromRGB(0, 0, 0)
        messageLabel.TextSize = config.fontSize.medium
        messageLabel.Font = Enum.Font.SourceSans
        messageLabel.TextWrapped = true
        messageLabel.Parent = messageFrame
        
        return
    end
    
    -- Touch controls
    MobileSettingsUI.createSettingsSection(parent, "📱 Touch Controls", {
        {type = "slider", label = "Button Size", key = "button_size", min = 80, max = 140, value = settingsState.settings.button_size},
        {type = "slider", label = "Touch Sensitivity", key = "touch_sensitivity", min = 20, max = 100, value = settingsState.settings.touch_sensitivity},
        {type = "toggle", label = "Haptic Feedback", key = "haptic_enabled", value = settingsState.settings.haptic_enabled},
        {type = "toggle", label = "Button Opacity", key = "button_opacity", value = true}
    }, config)
    
    -- Gameplay assists
    MobileSettingsUI.createSettingsSection(parent, "🎮 Gameplay Assists", {
        {type = "toggle", label = "Auto-Jump", key = "auto_jump", value = settingsState.settings.auto_jump},
        {type = "toggle", label = "Auto-Run", key = "auto_run", value = settingsState.settings.auto_run},
        {type = "toggle", label = "Gesture Controls", key = "gesture_controls", value = false}
    }, config)
    
    -- Control layout
    MobileSettingsUI.createSettingsSection(parent, "🎯 Control Layout", {
        {type = "button", label = "Reset to Default", action = "reset_controls"},
        {type = "button", label = "Calibrate Touch", action = "calibrate_touch"},
        {type = "dropdown", label = "Control Scheme", key = "control_scheme", options = {"Default", "Compact", "Extended"}, value = "Default"}
    }, config)
end

-- Create accessibility settings
function MobileSettingsUI.createAccessibilitySettings(parent, config)
    -- Visual accessibility
    MobileSettingsUI.createSettingsSection(parent, "👁️ Visual Accessibility", {
        {type = "toggle", label = "Colorblind Support", key = "colorblind_mode", value = settingsState.settings.colorblind_mode},
        {type = "toggle", label = "High Contrast", key = "high_contrast", value = settingsState.settings.high_contrast},
        {type = "toggle", label = "Large Text", key = "large_text", value = settingsState.settings.large_text},
        {type = "slider", label = "UI Scale", key = "ui_scale", min = 80, max = 120, value = 100}
    }, config)
    
    -- Motion accessibility
    MobileSettingsUI.createSettingsSection(parent, "🏃 Motion & Effects", {
        {type = "toggle", label = "Reduce Motion", key = "reduce_motion", value = settingsState.settings.reduce_motion},
        {type = "toggle", label = "Disable Screen Shake", key = "disable_shake", value = false},
        {type = "toggle", label = "Disable Flashing", key = "disable_flash", value = false}
    }, config)
    
    -- Input accessibility
    MobileSettingsUI.createSettingsSection(parent, "⌨️ Input Accessibility", {
        {type = "toggle", label = "Hold to Jump", key = "hold_jump", value = false},
        {type = "slider", label = "Input Delay", key = "input_delay", min = 0, max = 500, value = 0},
        {type = "toggle", label = "Simplified Controls", key = "simple_controls", value = false}
    }, config)
end

-- Create settings section
function MobileSettingsUI.createSettingsSection(parent, title, settings, config)
    -- Section container
    local sectionFrame = Instance.new("Frame")
    sectionFrame.Size = UDim2.new(1, 0, 0, 50 + (#settings * 60)) -- Dynamic height
    sectionFrame.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    sectionFrame.BorderSizePixel = 0
    sectionFrame.Parent = parent
    
    local sectionCorner = Instance.new("UICorner")
    sectionCorner.CornerRadius = UDim.new(0, 8)
    sectionCorner.Parent = sectionFrame
    
    -- Section header
    local headerFrame = Instance.new("Frame")
    headerFrame.Size = UDim2.new(1, 0, 0, 40)
    headerFrame.BackgroundColor3 = Color3.fromRGB(236, 240, 241)
    headerFrame.BorderSizePixel = 0
    headerFrame.Parent = sectionFrame
    
    local headerCorner = Instance.new("UICorner")
    headerCorner.CornerRadius = UDim.new(0, 8)
    headerCorner.Parent = headerFrame
    
    local headerLabel = Instance.new("TextLabel")
    headerLabel.Size = UDim2.new(1, -20, 1, 0)
    headerLabel.Position = UDim2.new(0, 10, 0, 0)
    headerLabel.BackgroundTransparency = 1
    headerLabel.Text = title
    headerLabel.TextColor3 = Color3.fromRGB(44, 62, 80)
    headerLabel.TextSize = config.fontSize.medium
    headerLabel.Font = Enum.Font.SourceSansBold
    headerLabel.TextXAlignment = Enum.TextXAlignment.Left
    headerLabel.Parent = headerFrame
    
    -- Settings content
    local contentFrame = Instance.new("Frame")
    contentFrame.Size = UDim2.new(1, 0, 1, -40)
    contentFrame.Position = UDim2.new(0, 0, 0, 40)
    contentFrame.BackgroundTransparency = 1
    contentFrame.Parent = sectionFrame
    
    local contentLayout = Instance.new("UIListLayout")
    contentLayout.FillDirection = Enum.FillDirection.Vertical
    contentLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
    contentLayout.VerticalAlignment = Enum.VerticalAlignment.Top
    contentLayout.Padding = UDim.new(0, 2)
    contentLayout.Parent = contentFrame
    
    -- Create setting items
    for _, setting in ipairs(settings) do
        MobileSettingsUI.createSettingItem(contentFrame, setting, config)
    end
end

-- Create individual setting item
function MobileSettingsUI.createSettingItem(parent, setting, config)
    local itemFrame = Instance.new("Frame")
    itemFrame.Size = UDim2.new(1, -10, 0, 50)
    itemFrame.BackgroundColor3 = Color3.fromRGB(248, 249, 250)
    itemFrame.BorderSizePixel = 0
    itemFrame.Parent = parent
    
    local itemCorner = Instance.new("UICorner")
    itemCorner.CornerRadius = UDim.new(0, 4)
    itemCorner.Parent = itemFrame
    
    -- Setting label
    local labelWidth = layoutProps.deviceType == "Phone" and 0.5 or 0.6
    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(labelWidth, 0, 1, 0)
    label.Position = UDim2.new(0, 15, 0, 0)
    label.BackgroundTransparency = 1
    label.Text = setting.label
    label.TextColor3 = Color3.fromRGB(44, 62, 80)
    label.TextSize = config.fontSize.medium
    label.Font = Enum.Font.SourceSans
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.TextWrapped = true
    label.Parent = itemFrame
    
    -- Create control based on type
    local controlWidth = layoutProps.deviceType == "Phone" and 0.45 or 0.35
    
    if setting.type == "toggle" then
        local toggleButton = MobileOptimizationService.createMobileButton({
            size = UDim2.new(0, 60, 0, 30),
            position = UDim2.new(1, -75, 0.5, -15),
            backgroundColor = (setting.value and Color3.fromRGB(46, 204, 113)) or Color3.fromRGB(231, 76, 60),
            text = setting.value and "ON" or "OFF",
            textSize = config.fontSize.small,
            parent = itemFrame
        })
        
        toggleButton.MouseButton1Click:Connect(function()
            local newValue = not settingsState.settings[setting.key]
            MobileSettingsUI.updateSetting(setting.key, newValue)
            
            toggleButton.Text = newValue and "ON" or "OFF"
            toggleButton.BackgroundColor3 = newValue and Color3.fromRGB(46, 204, 113) or Color3.fromRGB(231, 76, 60)
        end)
        
    elseif setting.type == "slider" then
        local sliderFrame = Instance.new("Frame")
        sliderFrame.Size = UDim2.new(controlWidth, 0, 0, 30)
        sliderFrame.Position = UDim2.new(1 - controlWidth, -10, 0.5, -15)
        sliderFrame.BackgroundColor3 = Color3.fromRGB(189, 195, 199)
        sliderFrame.BorderSizePixel = 0
        sliderFrame.Parent = itemFrame
        
        local sliderCorner = Instance.new("UICorner")
        sliderCorner.CornerRadius = UDim.new(0, 15)
        sliderCorner.Parent = sliderFrame
        
        local sliderFill = Instance.new("Frame")
        local currentValue = setting.value or settingsState.settings[setting.key] or setting.min
        local fillPercent = (currentValue - setting.min) / (setting.max - setting.min)
        sliderFill.Size = UDim2.new(fillPercent, 0, 1, 0)
        sliderFill.BackgroundColor3 = Color3.fromRGB(52, 152, 219)
        sliderFill.BorderSizePixel = 0
        sliderFill.Parent = sliderFrame
        
        local fillCorner = Instance.new("UICorner")
        fillCorner.CornerRadius = UDim.new(0, 15)
        fillCorner.Parent = sliderFill
        
        local valueLabel = Instance.new("TextLabel")
        valueLabel.Size = UDim2.new(1, 0, 1, 0)
        valueLabel.BackgroundTransparency = 1
        valueLabel.Text = tostring(math.floor(currentValue))
        valueLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
        valueLabel.TextSize = config.fontSize.small
        valueLabel.Font = Enum.Font.SourceSansBold
        valueLabel.TextXAlignment = Enum.TextXAlignment.Center
        valueLabel.Parent = sliderFrame
        
        -- Slider interaction
        sliderFrame.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                local connection
                connection = UserInputService.InputChanged:Connect(function(input2)
                    if input2.UserInputType == Enum.UserInputType.MouseMovement or input2.UserInputType == Enum.UserInputType.Touch then
                        local relativeX = (input2.Position.X - sliderFrame.AbsolutePosition.X) / sliderFrame.AbsoluteSize.X
                        relativeX = math.clamp(relativeX, 0, 1)
                        
                        local newValue = setting.min + (relativeX * (setting.max - setting.min))
                        newValue = math.floor(newValue)
                        
                        sliderFill.Size = UDim2.new(relativeX, 0, 1, 0)
                        valueLabel.Text = tostring(newValue)
                        
                        MobileSettingsUI.updateSetting(setting.key, newValue)
                    end
                end)
                
                local releaseConnection
                releaseConnection = UserInputService.InputEnded:Connect(function(input2)
                    if input2.UserInputType == Enum.UserInputType.MouseButton1 or input2.UserInputType == Enum.UserInputType.Touch then
                        connection:Disconnect()
                        releaseConnection:Disconnect()
                    end
                end)
            end
        end)
        
    elseif setting.type == "dropdown" then
        local dropdownButton = MobileOptimizationService.createMobileButton({
            size = UDim2.new(controlWidth, 0, 0, 35),
            position = UDim2.new(1 - controlWidth, -10, 0.5, -17.5),
            backgroundColor = Color3.fromRGB(52, 152, 219),
            text = setting.value or setting.options[1] or "Select",
            textSize = config.fontSize.small,
            parent = itemFrame
        })
        
        dropdownButton.MouseButton1Click:Connect(function()
            MobileSettingsUI.showDropdownMenu(dropdownButton, setting.options, function(selectedValue)
                dropdownButton.Text = selectedValue
                MobileSettingsUI.updateSetting(setting.key, selectedValue)
            end)
        end)
        
    elseif setting.type == "button" then
        local actionButton = MobileOptimizationService.createMobileButton({
            size = UDim2.new(controlWidth, 0, 0, 35),
            position = UDim2.new(1 - controlWidth, -10, 0.5, -17.5),
            backgroundColor = setting.color or Color3.fromRGB(52, 152, 219),
            text = setting.label,
            textSize = config.fontSize.small,
            parent = itemFrame
        })
        
        actionButton.MouseButton1Click:Connect(function()
            MobileSettingsUI.handleAction(setting.action)
        end)
        
    elseif setting.type == "info" then
        local infoLabel = Instance.new("TextLabel")
        infoLabel.Size = UDim2.new(controlWidth, 0, 1, 0)
        infoLabel.Position = UDim2.new(1 - controlWidth, -10, 0, 0)
        infoLabel.BackgroundTransparency = 1
        infoLabel.Text = setting.value or "N/A"
        infoLabel.TextColor3 = Color3.fromRGB(127, 140, 141)
        infoLabel.TextSize = config.fontSize.medium
        infoLabel.Font = Enum.Font.SourceSans
        infoLabel.TextXAlignment = Enum.TextXAlignment.Right
        infoLabel.TextWrapped = true
        infoLabel.Parent = itemFrame
    end
end

-- Show dropdown menu
function MobileSettingsUI.showDropdownMenu(button, options, onSelect)
    -- Create dropdown overlay
    local overlay = Instance.new("Frame")
    overlay.Size = UDim2.new(1, 0, 1, 0)
    overlay.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    overlay.BackgroundTransparency = 0.5
    overlay.BorderSizePixel = 0
    overlay.ZIndex = 1000
    overlay.Parent = playerGui
    
    -- Dropdown container
    local dropdownContainer = Instance.new("Frame")
    dropdownContainer.Size = UDim2.new(0, 200, 0, #options * 40 + 10)
    dropdownContainer.Position = UDim2.new(0.5, -100, 0.5, -((#options * 40 + 10) / 2))
    dropdownContainer.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    dropdownContainer.BorderSizePixel = 0
    dropdownContainer.Parent = overlay
    
    local containerCorner = Instance.new("UICorner")
    containerCorner.CornerRadius = UDim.new(0, 8)
    containerCorner.Parent = dropdownContainer
    
    local dropdownLayout = Instance.new("UIListLayout")
    dropdownLayout.FillDirection = Enum.FillDirection.Vertical
    dropdownLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
    dropdownLayout.VerticalAlignment = Enum.VerticalAlignment.Top
    dropdownLayout.Padding = UDim.new(0, 2)
    dropdownLayout.Parent = dropdownContainer
    
    local dropdownPadding = Instance.new("UIPadding")
    dropdownPadding.PaddingTop = UDim.new(0, 5)
    dropdownPadding.PaddingBottom = UDim.new(0, 5)
    dropdownPadding.Parent = dropdownContainer
    
    -- Create option buttons
    for _, option in ipairs(options) do
        local optionButton = MobileOptimizationService.createMobileButton({
            size = UDim2.new(1, -10, 0, 35),
            backgroundColor = Color3.fromRGB(236, 240, 241),
            text = option,
            textSize = layoutProps.config.fontSize.medium,
            parent = dropdownContainer
        })
        
        optionButton.MouseButton1Click:Connect(function()
            onSelect(option)
            overlay:Destroy()
        end)
    end
    
    -- Close on background tap
    overlay.MouseButton1Click:Connect(function()
        overlay:Destroy()
    end)
end

-- Handle action buttons
function MobileSettingsUI.handleAction(action)
    if action == "copy_user_id" then
        -- Copy user ID to clipboard (if supported)
        print("[Settings] User ID copied: " .. tostring(player.UserId))
        
    elseif action == "reset_data" then
        -- Show confirmation dialog
        MobileSettingsUI.showConfirmDialog(
            "Reset All Data",
            "Are you sure you want to reset all game data? This action cannot be undone.",
            function()
                if RemoteEvents.ResetPlayerData then
                    RemoteEvents.ResetPlayerData:FireServer()
                end
            end
        )
        
    elseif action == "reset_controls" then
        -- Reset control settings to default
        settingsState.settings.button_size = 100
        settingsState.settings.touch_sensitivity = 50
        settingsState.settings.haptic_enabled = true
        MobileSettingsUI.applySettings()
        
    elseif action == "calibrate_touch" then
        -- Show touch calibration
        print("[Settings] Touch calibration started")
    end
end

-- Show confirmation dialog
function MobileSettingsUI.showConfirmDialog(title, message, onConfirm)
    local confirmModal = MobileOptimizationService.createMobileModal({
        title = title,
        height = 200,
        backgroundColor = Color3.fromRGB(248, 249, 250),
        closeOnBackgroundTap = false
    })
    
    -- Message
    local messageLabel = Instance.new("TextLabel")
    messageLabel.Size = UDim2.new(1, -20, 0.6, 0)
    messageLabel.Position = UDim2.new(0, 10, 0, 10)
    messageLabel.BackgroundTransparency = 1
    messageLabel.Text = message
    messageLabel.TextColor3 = Color3.fromRGB(44, 62, 80)
    messageLabel.TextSize = layoutProps.config.fontSize.medium
    messageLabel.Font = Enum.Font.SourceSans
    messageLabel.TextWrapped = true
    messageLabel.Parent = confirmModal.contentArea
    
    -- Buttons
    local buttonContainer = Instance.new("Frame")
    buttonContainer.Size = UDim2.new(1, -20, 0.4, -10)
    buttonContainer.Position = UDim2.new(0, 10, 0.6, 0)
    buttonContainer.BackgroundTransparency = 1
    buttonContainer.Parent = confirmModal.contentArea
    
    local buttonLayout = Instance.new("UIListLayout")
    buttonLayout.FillDirection = Enum.FillDirection.Horizontal
    buttonLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
    buttonLayout.VerticalAlignment = Enum.VerticalAlignment.Center
    buttonLayout.Padding = UDim.new(0, 10)
    buttonLayout.Parent = buttonContainer
    
    -- Cancel button
    local cancelButton = MobileOptimizationService.createMobileButton({
        size = UDim2.new(0, 100, 0, 40),
        backgroundColor = Color3.fromRGB(149, 165, 166),
        text = "Cancel",
        parent = buttonContainer
    })
    
    cancelButton.MouseButton1Click:Connect(function()
        MobileOptimizationService.closeMobileModal(confirmModal.overlay)
    end)
    
    -- Confirm button
    local confirmButton = MobileOptimizationService.createMobileButton({
        size = UDim2.new(0, 100, 0, 40),
        backgroundColor = Color3.fromRGB(231, 76, 60),
        text = "Confirm",
        parent = buttonContainer
    })
    
    confirmButton.MouseButton1Click:Connect(function()
        onConfirm()
        MobileOptimizationService.closeMobileModal(confirmModal.overlay)
    end)
end

-- Update setting value
function MobileSettingsUI.updateSetting(key, value)
    settingsState.settings[key] = value
    MobileSettingsUI.applySettings()
    
    -- Send to server if needed
    if RemoteEvents.UpdatePlayerSettings then
        RemoteEvents.UpdatePlayerSettings:FireServer(key, value)
    end
end

-- Apply settings
function MobileSettingsUI.applySettings()
    local settings = settingsState.settings
    
    -- Audio settings
    if settings.master_volume then
        SoundService.MasterVolume = settings.master_volume / 100
    end
    
    -- Mobile-specific settings
    if layoutProps.touchEnabled then
        -- Apply button size changes
        if settings.button_size then
            -- This would update the MobileGameUI button sizes
            print("[Settings] Button size updated to: " .. settings.button_size)
        end
        
        -- Apply haptic feedback setting
        if settings.haptic_enabled ~= nil then
            print("[Settings] Haptic feedback: " .. tostring(settings.haptic_enabled))
        end
    end
    
    print("[Settings] Settings applied successfully")
end

-- Show settings UI
function MobileSettingsUI.show()
    if not settingsState.isVisible then
        MobileSettingsUI.createSettingsUI()
    end
end

-- Hide settings UI
function MobileSettingsUI.hide()
    if settingsGui then
        MobileOptimizationService.closeMobileModal(settingsGui)
        settingsState.isVisible = false
    end
end

-- Load settings from server
function MobileSettingsUI.loadSettings(serverSettings)
    if serverSettings then
        for key, value in pairs(serverSettings) do
            settingsState.settings[key] = value
        end
        MobileSettingsUI.applySettings()
    end
end

-- Get current settings
function MobileSettingsUI.getSettings()
    return settingsState.settings
end

-- Remote event connections
if RemoteEvents.PlayerSettingsLoaded then
    RemoteEvents.PlayerSettingsLoaded.OnClientEvent:Connect(function(settings)
        MobileSettingsUI.loadSettings(settings)
    end)
end

return MobileSettingsUI
