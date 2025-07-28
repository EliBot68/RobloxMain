-- MobileSettingsController.luau
-- Advanced mobile settings and configuration

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local RemoteEvents = require(ReplicatedStorage.Shared.modules.RemoteEvents)

local MobileSettingsController = {}

-- Settings storage
local mobileSettings = {
    buttonSize = "Large", -- Small, Medium, Large, Extra Large
    buttonOpacity = 0.8,
    hapticFeedback = true,
    touchSensitivity = "Normal", -- Low, Normal, High
    uiPosition = "Corners", -- Corners, Center, Custom
    showTrails = true,
    autoJump = false,
    colorSwitchMode = "Touch", -- Touch, Hold, Double Tap
    hudSize = "Large",
    showFPS = false
}

local settingsGui = nil
local isMobile = false

function MobileSettingsController:DetectMobile()
    local hasTouch = UserInputService.TouchEnabled
    local hasKeyboard = UserInputService.KeyboardEnabled
    local hasMouse = UserInputService.MouseEnabled
    
    isMobile = hasTouch and not (hasKeyboard and hasMouse)
    return isMobile
end

function MobileSettingsController:CreateSettingsGUI()
    settingsGui = Instance.new("ScreenGui")
    settingsGui.Name = "MobileSettingsGUI"
    settingsGui.ResetOnSpawn = false
    settingsGui.IgnoreGuiInset = true
    settingsGui.Enabled = false
    settingsGui.Parent = playerGui
    
    -- Main settings frame
    local settingsFrame = Instance.new("Frame")
    settingsFrame.Name = "SettingsFrame"
    settingsFrame.Size = UDim2.new(0, 400, 0, 600)
    settingsFrame.Position = UDim2.new(0.5, -200, 0.5, -300)
    settingsFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
    settingsFrame.BorderSizePixel = 0
    settingsFrame.Parent = settingsGui
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 15)
    corner.Parent = settingsFrame
    
    -- Title bar
    local titleBar = Instance.new("Frame")
    titleBar.Name = "TitleBar"
    titleBar.Size = UDim2.new(1, 0, 0, 60)
    titleBar.Position = UDim2.new(0, 0, 0, 0)
    titleBar.BackgroundColor3 = Color3.fromRGB(50, 150, 255)
    titleBar.BorderSizePixel = 0
    titleBar.Parent = settingsFrame
    
    local titleCorner = Instance.new("UICorner")
    titleCorner.CornerRadius = UDim.new(0, 15)
    titleCorner.Parent = titleBar
    
    -- Fix title corner to only round top
    local titleBottomCover = Instance.new("Frame")
    titleBottomCover.Size = UDim2.new(1, 0, 0, 15)
    titleBottomCover.Position = UDim2.new(0, 0, 1, -15)
    titleBottomCover.BackgroundColor3 = Color3.fromRGB(50, 150, 255)
    titleBottomCover.BorderSizePixel = 0
    titleBottomCover.Parent = titleBar
    
    local title = Instance.new("TextLabel")
    title.Name = "Title"
    title.Size = UDim2.new(1, -60, 1, 0)
    title.Position = UDim2.new(0, 20, 0, 0)
    title.BackgroundTransparency = 1
    title.Text = "📱 Mobile Settings"
    title.TextColor3 = Color3.new(1, 1, 1)
    title.TextSize = 20
    title.Font = Enum.Font.GothamBold
    title.TextXAlignment = Enum.TextXAlignment.Left
    title.Parent = titleBar
    
    -- Close button
    local closeButton = Instance.new("TextButton")
    closeButton.Name = "CloseButton"
    closeButton.Size = UDim2.new(0, 40, 0, 40)
    closeButton.Position = UDim2.new(1, -50, 0, 10)
    closeButton.BackgroundColor3 = Color3.fromRGB(200, 100, 100)
    closeButton.BorderSizePixel = 0
    closeButton.Text = "✕"
    closeButton.TextColor3 = Color3.new(1, 1, 1)
    closeButton.TextSize = 18
    closeButton.Font = Enum.Font.GothamBold
    closeButton.Parent = titleBar
    
    local closeCorner = Instance.new("UICorner")
    closeCorner.CornerRadius = UDim.new(0, 8)
    closeCorner.Parent = closeButton
    
    -- Settings content
    local contentFrame = Instance.new("ScrollingFrame")
    contentFrame.Name = "ContentFrame"
    contentFrame.Size = UDim2.new(1, -20, 1, -120)
    contentFrame.Position = UDim2.new(0, 10, 0, 70)
    contentFrame.BackgroundTransparency = 1
    contentFrame.BorderSizePixel = 0
    contentFrame.ScrollBarThickness = 6
    contentFrame.Parent = settingsFrame
    
    local contentLayout = Instance.new("UIListLayout")
    contentLayout.SortOrder = Enum.SortOrder.LayoutOrder
    contentLayout.Padding = UDim.new(0, 15)
    contentLayout.Parent = contentFrame
    
    -- Create setting sections
    self:CreateButtonSizeSettings(contentFrame)
    self:CreateControlSettings(contentFrame)
    self:CreateVisualSettings(contentFrame)
    self:CreatePerformanceSettings(contentFrame)
    
    -- Apply and reset buttons
    local buttonFrame = Instance.new("Frame")
    buttonFrame.Name = "ButtonFrame"
    buttonFrame.Size = UDim2.new(1, -20, 0, 50)
    buttonFrame.Position = UDim2.new(0, 10, 1, -60)
    buttonFrame.BackgroundTransparency = 1
    buttonFrame.Parent = settingsFrame
    
    local applyButton = Instance.new("TextButton")
    applyButton.Name = "ApplyButton"
    applyButton.Size = UDim2.new(0.45, 0, 1, 0)
    applyButton.Position = UDim2.new(0, 0, 0, 0)
    applyButton.BackgroundColor3 = Color3.fromRGB(100, 200, 100)
    applyButton.BorderSizePixel = 0
    applyButton.Text = "Apply Settings"
    applyButton.TextColor3 = Color3.new(1, 1, 1)
    applyButton.TextSize = 16
    applyButton.Font = Enum.Font.GothamBold
    applyButton.Parent = buttonFrame
    
    local applyCorner = Instance.new("UICorner")
    applyCorner.CornerRadius = UDim.new(0, 8)
    applyCorner.Parent = applyButton
    
    local resetButton = Instance.new("TextButton")
    resetButton.Name = "ResetButton"
    resetButton.Size = UDim2.new(0.45, 0, 1, 0)
    resetButton.Position = UDim2.new(0.55, 0, 0, 0)
    resetButton.BackgroundColor3 = Color3.fromRGB(200, 150, 100)
    resetButton.BorderSizePixel = 0
    resetButton.Text = "Reset to Default"
    resetButton.TextColor3 = Color3.new(1, 1, 1)
    resetButton.TextSize = 16
    resetButton.Font = Enum.Font.GothamBold
    resetButton.Parent = buttonFrame
    
    local resetCorner = Instance.new("UICorner")
    resetCorner.CornerRadius = UDim.new(0, 8)
    resetCorner.Parent = resetButton
    
    -- Event connections
    closeButton.MouseButton1Click:Connect(function()
        self:CloseSettings()
    end)
    
    applyButton.MouseButton1Click:Connect(function()
        self:ApplySettings()
    end)
    
    resetButton.MouseButton1Click:Connect(function()
        self:ResetToDefaults()
    end)
    
    return settingsFrame
end

function MobileSettingsController:CreateButtonSizeSettings(parent)
    local section = self:CreateSettingSection("Button & UI Settings", parent)
    
    -- Button size setting
    self:CreateDropdownSetting(section, "Button Size", "buttonSize", 
        {"Small", "Medium", "Large", "Extra Large"}, 
        "Controls the size of touch buttons")
    
    -- Button opacity setting
    self:CreateSliderSetting(section, "Button Opacity", "buttonOpacity", 0.3, 1.0, 
        "Transparency of mobile buttons")
    
    -- HUD size setting
    self:CreateDropdownSetting(section, "HUD Size", "hudSize",
        {"Small", "Medium", "Large", "Extra Large"},
        "Size of score, coins, and other HUD elements")
end

function MobileSettingsController:CreateControlSettings(parent)
    local section = self:CreateSettingSection("Touch Controls", parent)
    
    -- Touch sensitivity
    self:CreateDropdownSetting(section, "Touch Sensitivity", "touchSensitivity",
        {"Low", "Normal", "High"},
        "How responsive touch controls are")
    
    -- Color switch mode
    self:CreateDropdownSetting(section, "Color Switch Mode", "colorSwitchMode",
        {"Touch", "Hold", "Double Tap"},
        "How to activate color switching")
    
    -- Auto jump setting
    self:CreateToggleSetting(section, "Auto Jump", "autoJump",
        "Automatically jump when hitting barriers")
    
    -- Haptic feedback
    self:CreateToggleSetting(section, "Haptic Feedback", "hapticFeedback",
        "Visual feedback when pressing buttons")
end

function MobileSettingsController:CreateVisualSettings(parent)
    local section = self:CreateSettingSection("Visual Settings", parent)
    
    -- Trail visibility
    self:CreateToggleSetting(section, "Show Trails", "showTrails",
        "Display player trail effects")
    
    -- UI position
    self:CreateDropdownSetting(section, "UI Position", "uiPosition",
        {"Corners", "Center", "Custom"},
        "Where to position mobile UI elements")
end

function MobileSettingsController:CreatePerformanceSettings(parent)
    local section = self:CreateSettingSection("Performance", parent)
    
    -- FPS display
    self:CreateToggleSetting(section, "Show FPS", "showFPS",
        "Display frame rate counter")
end

function MobileSettingsController:CreateSettingSection(title, parent)
    local section = Instance.new("Frame")
    section.Name = title:gsub(" ", "") .. "Section"
    section.Size = UDim2.new(1, 0, 0, 200) -- Will be adjusted by UIListLayout
    section.BackgroundColor3 = Color3.fromRGB(40, 40, 50)
    section.BorderSizePixel = 0
    section.LayoutOrder = parent:FindFirstChild("UIListLayout").AbsoluteContentSize.Y
    section.Parent = parent
    
    local sectionCorner = Instance.new("UICorner")
    sectionCorner.CornerRadius = UDim.new(0, 8)
    sectionCorner.Parent = section
    
    local sectionTitle = Instance.new("TextLabel")
    sectionTitle.Name = "SectionTitle"
    sectionTitle.Size = UDim2.new(1, -20, 0, 30)
    sectionTitle.Position = UDim2.new(0, 10, 0, 10)
    sectionTitle.BackgroundTransparency = 1
    sectionTitle.Text = title
    sectionTitle.TextColor3 = Color3.fromRGB(100, 150, 255)
    sectionTitle.TextSize = 16
    sectionTitle.Font = Enum.Font.GothamBold
    sectionTitle.TextXAlignment = Enum.TextXAlignment.Left
    sectionTitle.Parent = section
    
    local sectionLayout = Instance.new("UIListLayout")
    sectionLayout.SortOrder = Enum.SortOrder.LayoutOrder
    sectionLayout.Padding = UDim.new(0, 8)
    sectionLayout.Parent = section
    
    -- Spacer for title
    local spacer = Instance.new("Frame")
    spacer.Size = UDim2.new(1, 0, 0, 40)
    spacer.BackgroundTransparency = 1
    spacer.LayoutOrder = 0
    spacer.Parent = section
    
    return section
end

function MobileSettingsController:CreateToggleSetting(parent, name, settingKey, description)
    local setting = Instance.new("Frame")
    setting.Name = name:gsub(" ", "") .. "Setting"
    setting.Size = UDim2.new(1, -20, 0, 50)
    setting.BackgroundTransparency = 1
    setting.LayoutOrder = #parent:GetChildren()
    setting.Parent = parent
    
    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(0.7, 0, 0.6, 0)
    label.Position = UDim2.new(0, 10, 0, 0)
    label.BackgroundTransparency = 1
    label.Text = name
    label.TextColor3 = Color3.new(1, 1, 1)
    label.TextSize = 14
    label.Font = Enum.Font.Gotham
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Parent = setting
    
    local desc = Instance.new("TextLabel")
    desc.Size = UDim2.new(0.7, 0, 0.4, 0)
    desc.Position = UDim2.new(0, 10, 0.6, 0)
    desc.BackgroundTransparency = 1
    desc.Text = description
    desc.TextColor3 = Color3.fromRGB(180, 180, 180)
    desc.TextSize = 11
    desc.Font = Enum.Font.Gotham
    desc.TextXAlignment = Enum.TextXAlignment.Left
    desc.Parent = setting
    
    local toggle = Instance.new("TextButton")
    toggle.Name = "Toggle"
    toggle.Size = UDim2.new(0, 60, 0, 30)
    toggle.Position = UDim2.new(1, -70, 0, 10)
    toggle.BackgroundColor3 = mobileSettings[settingKey] and Color3.fromRGB(100, 200, 100) or Color3.fromRGB(100, 100, 100)
    toggle.BorderSizePixel = 0
    toggle.Text = mobileSettings[settingKey] and "ON" or "OFF"
    toggle.TextColor3 = Color3.new(1, 1, 1)
    toggle.TextSize = 12
    toggle.Font = Enum.Font.GothamBold
    toggle.Parent = setting
    
    local toggleCorner = Instance.new("UICorner")
    toggleCorner.CornerRadius = UDim.new(0, 15)
    toggleCorner.Parent = toggle
    
    toggle.MouseButton1Click:Connect(function()
        mobileSettings[settingKey] = not mobileSettings[settingKey]
        toggle.BackgroundColor3 = mobileSettings[settingKey] and Color3.fromRGB(100, 200, 100) or Color3.fromRGB(100, 100, 100)
        toggle.Text = mobileSettings[settingKey] and "ON" or "OFF"
    end)
    
    -- Auto-resize parent
    parent.Size = UDim2.new(1, 0, 0, parent.UIListLayout.AbsoluteContentSize.Y + 20)
end

function MobileSettingsController:OpenSettings()
    if not isMobile then
        print("📱 Mobile settings only available on mobile devices")
        return
    end
    
    if not settingsGui then
        self:CreateSettingsGUI()
    end
    
    settingsGui.Enabled = true
end

function MobileSettingsController:CloseSettings()
    if settingsGui then
        settingsGui.Enabled = false
    end
end

function MobileSettingsController:ApplySettings()
    print("📱 Applying mobile settings...")
    
    -- Apply settings to enhanced mobile UI
    RemoteEvents.UpdateMobileSettings:FireServer(mobileSettings)
    
    -- Update local UI if needed
    self:UpdateLocalUI()
    
    self:CloseSettings()
end

function MobileSettingsController:UpdateLocalUI()
    local enhancedGui = playerGui:FindFirstChild("EnhancedMobileGameGui")
    if not enhancedGui then return end
    
    local container = enhancedGui:FindFirstChild("Container")
    if not container then return end
    
    -- Update button sizes based on setting
    local sizeMultiplier = 1
    if mobileSettings.buttonSize == "Small" then
        sizeMultiplier = 0.7
    elseif mobileSettings.buttonSize == "Medium" then
        sizeMultiplier = 0.85
    elseif mobileSettings.buttonSize == "Large" then
        sizeMultiplier = 1.0
    elseif mobileSettings.buttonSize == "Extra Large" then
        sizeMultiplier = 1.2
    end
    
    -- Update jump button
    local jumpButton = container:FindFirstChild("LargeJumpButton")
    if jumpButton then
        local baseSize = 160
        local newSize = baseSize * sizeMultiplier
        jumpButton.Size = UDim2.new(0, newSize, 0, newSize)
        jumpButton.BackgroundTransparency = 1 - mobileSettings.buttonOpacity
    end
    
    -- Update color button
    local colorButton = container:FindFirstChild("LargeColorSwitchButton")
    if colorButton then
        local baseSize = 160
        local newSize = baseSize * sizeMultiplier
        colorButton.Size = UDim2.new(0, newSize, 0, newSize)
        colorButton.BackgroundTransparency = 1 - mobileSettings.buttonOpacity
    end
    
    print("📱 Mobile UI updated with new settings")
end

function MobileSettingsController:ResetToDefaults()
    mobileSettings = {
        buttonSize = "Large",
        buttonOpacity = 0.8,
        hapticFeedback = true,
        touchSensitivity = "Normal",
        uiPosition = "Corners",
        showTrails = true,
        autoJump = false,
        colorSwitchMode = "Touch",
        hudSize = "Large",
        showFPS = false
    }
    
    -- Recreate GUI with default values
    if settingsGui then
        settingsGui:Destroy()
        self:CreateSettingsGUI()
        settingsGui.Enabled = true
    end
    
    print("📱 Mobile settings reset to defaults")
end

function MobileSettingsController:Initialize()
    if not self:DetectMobile() then
        return
    end
    
    print("📱 MobileSettingsController initialized")
    
    -- Listen for settings open request
    RemoteEvents.OpenMobileSettings.OnClientEvent:Connect(function()
        self:OpenSettings()
    end)
end

-- Auto-initialize
MobileSettingsController:Initialize()

return MobileSettingsController
