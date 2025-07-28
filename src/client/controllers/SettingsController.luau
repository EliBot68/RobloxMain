-- SettingsController.luau
-- Handles player accessibility settings and preferences UI

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local RemoteEvents = require(ReplicatedStorage.Shared.modules.RemoteEvents)
local GameConstants = require(ReplicatedStorage.Shared.constants.GameConstants)

local player = Players.LocalPlayer
local SettingsController = {}

-- Settings state
local currentSettings = {
    music = true,
    sfx = true,
    colorblindMode = false,
    controllerEnabled = true
}

-- UI References
local settingsGui = nil
local settingsFrame = nil
local isSettingsOpen = false

function SettingsController:CreateSettingsUI()
    -- Create main settings GUI
    settingsGui = Instance.new("ScreenGui")
    settingsGui.Name = "SettingsGUI"
    settingsGui.ResetOnSpawn = false
    settingsGui.Parent = player:WaitForChild("PlayerGui")
    
    -- Background frame
    local background = Instance.new("Frame")
    background.Name = "Background"
    background.Size = UDim2.new(1, 0, 1, 0)
    background.Position = UDim2.new(0, 0, 0, 0)
    background.BackgroundColor3 = Color3.new(0, 0, 0)
    background.BackgroundTransparency = 0.5
    background.Visible = false
    background.Parent = settingsGui
    
    -- Settings frame
    settingsFrame = Instance.new("Frame")
    settingsFrame.Name = "SettingsFrame"
    settingsFrame.Size = UDim2.new(0, 400, 0, 500)
    settingsFrame.Position = UDim2.new(0.5, -200, 0.5, -250)
    settingsFrame.BackgroundColor3 = Color3.new(0.1, 0.1, 0.1)
    settingsFrame.BorderSizePixel = 0
    settingsFrame.Parent = background
    
    -- Add corner radius
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 10)
    corner.Parent = settingsFrame
    
    -- Title
    local title = Instance.new("TextLabel")
    title.Name = "Title"
    title.Size = UDim2.new(1, 0, 0, 50)
    title.Position = UDim2.new(0, 0, 0, 0)
    title.BackgroundTransparency = 1
    title.Text = "⚙️ SETTINGS"
    title.TextColor3 = Color3.new(1, 1, 1)
    title.TextScaled = true
    title.Font = Enum.Font.SourceSansBold
    title.Parent = settingsFrame
    
    -- Close button
    local closeButton = Instance.new("TextButton")
    closeButton.Name = "CloseButton"
    closeButton.Size = UDim2.new(0, 30, 0, 30)
    closeButton.Position = UDim2.new(1, -40, 0, 10)
    closeButton.BackgroundColor3 = Color3.new(0.8, 0.2, 0.2)
    closeButton.Text = "✕"
    closeButton.TextColor3 = Color3.new(1, 1, 1)
    closeButton.TextScaled = true
    closeButton.Font = Enum.Font.SourceSansBold
    closeButton.Parent = settingsFrame
    
    local closeCorner = Instance.new("UICorner")
    closeCorner.CornerRadius = UDim.new(0, 5)
    closeCorner.Parent = closeButton
    
    closeButton.MouseButton1Click:Connect(function()
        self:HideSettings()
    end)
    
    -- Settings options
    self:CreateSettingToggle("Music", "🎵", 60, "music")
    self:CreateSettingToggle("Sound Effects", "🔊", 110, "sfx")
    self:CreateSettingToggle("Colorblind Mode", "🔤", 160, "colorblindMode")
    self:CreateSettingToggle("Controller Support", "🎮", 210, "controllerEnabled")
    
    -- Info text for colorblind mode
    local infoText = Instance.new("TextLabel")
    infoText.Name = "InfoText"
    infoText.Size = UDim2.new(1, -20, 0, 80)
    infoText.Position = UDim2.new(0, 10, 0, 270)
    infoText.BackgroundTransparency = 1
    infoText.Text = "Colorblind Mode adds symbols to colors:\n🔺 Red   ⬟ Green   ⬢ Blue"
    infoText.TextColor3 = Color3.new(0.8, 0.8, 0.8)
    infoText.TextSize = 14
    infoText.Font = Enum.Font.SourceSans
    infoText.TextWrapped = true
    infoText.Parent = settingsFrame
    
    -- Controller info text
    local controllerInfo = Instance.new("TextLabel")
    controllerInfo.Name = "ControllerInfo"
    controllerInfo.Size = UDim2.new(1, -20, 0, 80)
    controllerInfo.Position = UDim2.new(0, 10, 0, 360)
    controllerInfo.BackgroundTransparency = 1
    controllerInfo.Text = "Xbox Controller:\nD-Pad Up = Red\nD-Pad Left = Green\nD-Pad Right = Blue"
    controllerInfo.TextColor3 = Color3.new(0.8, 0.8, 0.8)
    controllerInfo.TextSize = 14
    controllerInfo.Font = Enum.Font.SourceSans
    controllerInfo.TextWrapped = true
    controllerInfo.Parent = settingsFrame
    
    return settingsGui
end

function SettingsController:CreateSettingToggle(name, icon, yPos, settingKey)
    -- Setting container
    local settingFrame = Instance.new("Frame")
    settingFrame.Name = settingKey .. "Setting"
    settingFrame.Size = UDim2.new(1, -20, 0, 40)
    settingFrame.Position = UDim2.new(0, 10, 0, yPos)
    settingFrame.BackgroundTransparency = 1
    settingFrame.Parent = settingsFrame
    
    -- Icon and label
    local label = Instance.new("TextLabel")
    label.Name = "Label"
    label.Size = UDim2.new(0, 250, 1, 0)
    label.Position = UDim2.new(0, 0, 0, 0)
    label.BackgroundTransparency = 1
    label.Text = icon .. " " .. name
    label.TextColor3 = Color3.new(1, 1, 1)
    label.TextSize = 18
    label.Font = Enum.Font.SourceSans
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Parent = settingFrame
    
    -- Toggle button
    local toggleButton = Instance.new("TextButton")
    toggleButton.Name = "ToggleButton"
    toggleButton.Size = UDim2.new(0, 80, 0, 30)
    toggleButton.Position = UDim2.new(1, -90, 0, 5)
    toggleButton.BackgroundColor3 = currentSettings[settingKey] and Color3.new(0.2, 0.8, 0.2) or Color3.new(0.6, 0.2, 0.2)
    toggleButton.Text = currentSettings[settingKey] and "ON" or "OFF"
    toggleButton.TextColor3 = Color3.new(1, 1, 1)
    toggleButton.TextScaled = true
    toggleButton.Font = Enum.Font.SourceSansBold
    toggleButton.Parent = settingFrame
    
    local toggleCorner = Instance.new("UICorner")
    toggleCorner.CornerRadius = UDim.new(0, 5)
    toggleCorner.Parent = toggleButton
    
    -- Toggle functionality
    toggleButton.MouseButton1Click:Connect(function()
        currentSettings[settingKey] = not currentSettings[settingKey]
        
        -- Update button appearance
        toggleButton.BackgroundColor3 = currentSettings[settingKey] and Color3.new(0.2, 0.8, 0.2) or Color3.new(0.6, 0.2, 0.2)
        toggleButton.Text = currentSettings[settingKey] and "ON" or "OFF"
        
        -- Apply setting immediately
        self:ApplySetting(settingKey, currentSettings[settingKey])
        
        print("🔧 Setting " .. settingKey .. " = " .. tostring(currentSettings[settingKey]))
    end)
end

function SettingsController:ApplySetting(settingKey, value)
    if settingKey == "colorblindMode" then
        -- Update colorblind mode immediately
        RemoteEvents.ToggleColorblindMode:FireServer(value)
        
        -- Notify InputController about the change
        local InputController = require(script.Parent.InputController)
        InputController:UpdatePlayerSettings(currentSettings)
        
    elseif settingKey == "controllerEnabled" then
        -- Update controller support
        RemoteEvents.ToggleControllerSupport:FireServer(value)
        
        -- Notify InputController about the change
        local InputController = require(script.Parent.InputController)
        InputController:UpdatePlayerSettings(currentSettings)
        
    elseif settingKey == "music" or settingKey == "sfx" then
        -- Update audio settings
        RemoteEvents.UpdatePlayerSettings:FireServer(settingKey, value)
    end
end

function SettingsController:ShowSettings()
    if not settingsGui then
        self:CreateSettingsUI()
    end
    
    local background = settingsGui.Background
    background.Visible = true
    isSettingsOpen = true
    
    -- Animate in
    settingsFrame.Position = UDim2.new(0.5, -200, 1, 0)
    settingsFrame:TweenPosition(
        UDim2.new(0.5, -200, 0.5, -250),
        Enum.EasingDirection.Out,
        Enum.EasingStyle.Back,
        0.3,
        true
    )
    
    print("⚙️ Settings menu opened")
end

function SettingsController:HideSettings()
    if not settingsGui then return end
    
    local background = settingsGui.Background
    
    -- Animate out
    settingsFrame:TweenPosition(
        UDim2.new(0.5, -200, 1, 0),
        Enum.EasingDirection.In,
        Enum.EasingStyle.Back,
        0.3,
        true,
        function()
            background.Visible = false
            isSettingsOpen = false
        end
    )
    
    print("⚙️ Settings menu closed")
end

function SettingsController:UpdateSettings(newSettings)
    for key, value in pairs(newSettings) do
        if currentSettings[key] ~= nil then
            currentSettings[key] = value
        end
    end
    
    -- Update UI if it exists
    if settingsFrame then
        for key, value in pairs(currentSettings) do
            local settingFrame = settingsFrame:FindFirstChild(key .. "Setting")
            if settingFrame then
                local toggleButton = settingFrame:FindFirstChild("ToggleButton")
                if toggleButton then
                    toggleButton.BackgroundColor3 = value and Color3.new(0.2, 0.8, 0.2) or Color3.new(0.6, 0.2, 0.2)
                    toggleButton.Text = value and "ON" or "OFF"
                end
            end
        end
    end
end

function SettingsController:IsSettingsOpen()
    return isSettingsOpen
end

function SettingsController:Init()
    print("⚙️ SettingsController initializing...")
    
    -- Listen for settings key (ESC or backslash)
    UserInputService.InputBegan:Connect(function(input, gameProcessed)
        if gameProcessed then return end
        
        if input.KeyCode == Enum.KeyCode.Backslash or input.KeyCode == Enum.KeyCode.Escape then
            if isSettingsOpen then
                self:HideSettings()
            else
                self:ShowSettings()
            end
        end
    end)
    
    -- Listen for settings updates from server
    RemoteEvents.PlayerDataUpdated.OnClientEvent:Connect(function(data)
        if data and data.settings then
            self:UpdateSettings(data.settings)
        end
    end)
    
    print("✅ SettingsController initialized (Press \\ or ESC to open settings)")
end

return SettingsController
