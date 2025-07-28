-- AchievementMenuIntegration.luau
-- Integrates achievement menu with main game UI

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local StarterGui = game:GetService("StarterGui")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local SafeRequire = require(ReplicatedStorage.Shared.utils.SafeRequire)

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local AchievementMenuIntegration = {}

function AchievementMenuIntegration:Init()
    print("🔗 AchievementMenuIntegration initializing...")
    
    -- Wait for main UI to load
    spawn(function()
        wait(3)
        self:IntegrateWithMainMenu()
        self:SetupKeyboardShortcuts()
        self:CreateTopBarButton()
    end)
end

function AchievementMenuIntegration:IntegrateWithMainMenu()
    -- Look for existing main menu or hub UI
    local mainMenuGuis = {
        "MainMenuGUI",
        "HubMenuGUI", 
        "GameMenuGUI",
        "MenuGUI"
    }
    
    local targetGui = nil
    for _, guiName in ipairs(mainMenuGuis) do
        targetGui = playerGui:FindFirstChild(guiName)
        if targetGui then
            print("📋 Found main menu: " .. guiName)
            break
        end
    end
    
    if targetGui then
        self:AddAchievementButtonToMenu(targetGui)
    else
        print("⚠️ No main menu found, creating standalone button")
        self:CreateStandaloneButton()
    end
end

function AchievementMenuIntegration:AddAchievementButtonToMenu(menuGui)
    -- Look for a suitable frame to add the button
    local buttonParent = self:FindButtonContainer(menuGui)
    
    if buttonParent then
        local achievementButton = Instance.new("TextButton")
        achievementButton.Name = "AchievementMenuButton"
        achievementButton.Size = UDim2.new(0, 200, 0, 50)
        achievementButton.BackgroundColor3 = Color3.new(0.2, 0.6, 1)
        achievementButton.BorderSizePixel = 0
        achievementButton.Text = "🏆 ACHIEVEMENTS"
        achievementButton.TextColor3 = Color3.new(1, 1, 1)
        achievementButton.TextSize = 18
        achievementButton.Font = Enum.Font.SourceSansBold
        achievementButton.Parent = buttonParent
        
        local corner = Instance.new("UICorner")
        corner.CornerRadius = UDim.new(0, 8)
        corner.Parent = achievementButton
        
        achievementButton.MouseButton1Click:Connect(function()
            self:OpenAchievementMenu()
        end)
        
        print("✅ Achievement button added to main menu")
    end
end

function AchievementMenuIntegration:FindButtonContainer(gui)
    -- Look for common button container patterns
    local containerNames = {
        "ButtonContainer",
        "MenuButtons",
        "MainButtons",
        "ButtonFrame",
        "Content",
        "MenuFrame"
    }
    
    for _, name in ipairs(containerNames) do
        local container = gui:FindFirstChild(name, true)
        if container and (container:IsA("Frame") or container:IsA("ScrollingFrame")) then
            return container
        end
    end
    
    -- Fallback to the main frame
    return gui:FindFirstChildOfClass("Frame")
end

function AchievementMenuIntegration:CreateStandaloneButton()
    -- Create a standalone achievement button in the corner
    local standaloneGui = Instance.new("ScreenGui")
    standaloneGui.Name = "AchievementButtonGUI"
    standaloneGui.ResetOnSpawn = false
    standaloneGui.Parent = playerGui
    
    local button = Instance.new("TextButton")
    button.Name = "AchievementButton"
    button.Size = UDim2.new(0, 120, 0, 40)
    button.Position = UDim2.new(0, 10, 0, 100)
    button.BackgroundColor3 = Color3.new(0.2, 0.6, 1)
    button.BorderSizePixel = 0
    button.Text = "🏆 Achievements"
    button.TextColor3 = Color3.new(1, 1, 1)
    button.TextSize = 14
    button.Font = Enum.Font.SourceSansBold
    button.Parent = standaloneGui
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 8)
    corner.Parent = button
    
    button.MouseButton1Click:Connect(function()
        self:OpenAchievementMenu()
    end)
    
    print("✅ Standalone achievement button created")
end

function AchievementMenuIntegration:CreateTopBarButton()
    -- Try to create a top bar button (may not work in all contexts)
    local success = pcall(function()
        local topBarButton = Instance.new("ScreenGui")
        topBarButton.Name = "AchievementTopBarGUI"
        topBarButton.ResetOnSpawn = false
        topBarButton.Parent = playerGui
        
        local button = Instance.new("TextButton")
        button.Name = "TopBarButton"
        button.Size = UDim2.new(0, 60, 0, 30)
        button.Position = UDim2.new(1, -70, 0, 5)
        button.BackgroundColor3 = Color3.new(0.1, 0.1, 0.2)
        button.BackgroundTransparency = 0.3
        button.BorderSizePixel = 0
        button.Text = "🏆"
        button.TextColor3 = Color3.new(1, 1, 1)
        button.TextSize = 20
        button.Font = Enum.Font.SourceSansBold
        button.Parent = topBarButton
        
        local corner = Instance.new("UICorner")
        corner.CornerRadius = UDim.new(0, 6)
        corner.Parent = button
        
        button.MouseButton1Click:Connect(function()
            self:OpenAchievementMenu()
        end)
        
        print("✅ Top bar achievement button created")
    end)
    
    if not success then
        print("⚠️ Could not create top bar button")
    end
end

function AchievementMenuIntegration:SetupKeyboardShortcuts()
    -- Setup keyboard shortcut to open achievements (H key)
    UserInputService.InputBegan:Connect(function(input, gameProcessed)
        if gameProcessed then return end
        
        if input.KeyCode == Enum.KeyCode.H then
            self:ToggleAchievementMenu()
        elseif input.KeyCode == Enum.KeyCode.J then
            -- Alternative shortcut
            self:OpenAchievementMenu()
        end
    end)
    
    print("✅ Achievement menu keyboard shortcuts setup (H key)")
end

function AchievementMenuIntegration:OpenAchievementMenu()
    -- Try to access the AchievementController
    local success = pcall(function()
        local AchievementController = require(ReplicatedStorage.Shared.controllers.AchievementControllerComplete)
        if AchievementController and AchievementController.OpenAchievementMenu then
            AchievementController:OpenAchievementMenu()
        end
    end)
    
    if not success then
        -- Try alternative path
        success = pcall(function()
            local AchievementController = require(script.Parent.Parent.controllers.AchievementControllerComplete)
            if AchievementController and AchievementController.OpenAchievementMenu then
                AchievementController:OpenAchievementMenu()
            end
        end)
    end
    
    if not success then
        -- Fallback notification
        StarterGui:SetCore("SendNotification", {
            Title = "🏆 Achievements",
            Text = "Opening achievement menu...",
            Duration = 2
        })
        print("📋 Achievement menu requested (controller may not be loaded yet)")
    end
end

function AchievementMenuIntegration:ToggleAchievementMenu()
    -- For now, just open the menu (could add toggle logic later)
    self:OpenAchievementMenu()
end

function AchievementMenuIntegration:CreateAchievementNotificationArea()
    -- Create a dedicated area for achievement notifications
    local notifGui = Instance.new("ScreenGui")
    notifGui.Name = "AchievementNotificationGUI"
    notifGui.ResetOnSpawn = false
    notifGui.Parent = playerGui
    
    -- Notification area frame
    local notifArea = Instance.new("Frame")
    notifArea.Name = "NotificationArea"
    notifArea.Size = UDim2.new(0, 350, 1, 0)
    notifArea.Position = UDim2.new(1, -360, 0, 0)
    notifArea.BackgroundTransparency = 1
    notifArea.Parent = notifGui
    
    local layout = Instance.new("UIListLayout")
    layout.SortOrder = Enum.SortOrder.LayoutOrder
    layout.Padding = UDim.new(0, 10)
    layout.Parent = notifArea
    
    print("✅ Achievement notification area created")
end

-- Initialize the integration
AchievementMenuIntegration:Init()

return AchievementMenuIntegration
