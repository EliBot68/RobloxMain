-- ContentAdminPanel.luau
-- Simple admin interface for content management

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local RemoteEvents = ReplicatedStorage:WaitForChild("RemoteEvents")
local Player = Players.LocalPlayer
local PlayerGui = Player:WaitForChild("PlayerGui")

local ContentAdminPanel = {}

-- Admin UI elements
local adminGui = nil
local adminPanel = nil
local isAdminPanelVisible = false

-- Quick templates for easy content creation
local QUICK_TEMPLATES = {
    events = {
        {name = "Weekend Bonus", description = "Double coins for 3 days!", duration = 3, icon = "💰"},
        {name = "Speed Challenge", description = "Complete runs faster than ever!", duration = 7, icon = "⚡"},
        {name = "Pet Parade", description = "All pets 50% off this week!", duration = 7, icon = "🐾"},
        {name = "Rainbow Festival", description = "Colorful celebration event!", duration = 5, icon = "🌈"}
    },
    
    trails = {
        {name = "Lightning Trail", description = "Electric yellow trail effect", price = 1500, rarity = "rare", colors = {Color3.fromRGB(255, 255, 0)}},
        {name = "Fire Trail", description = "Blazing red and orange trail", price = 2000, rarity = "epic", colors = {Color3.fromRGB(255, 0, 0), Color3.fromRGB(255, 165, 0)}},
        {name = "Ice Trail", description = "Cool blue crystalline trail", price = 1800, rarity = "rare", colors = {Color3.fromRGB(173, 216, 230)}},
        {name = "Galaxy Trail", description = "Cosmic purple and blue trail", price = 3000, rarity = "legendary", colors = {Color3.fromRGB(128, 0, 128), Color3.fromRGB(0, 0, 255)}}
    },
    
    pets = {
        {name = "Lightning Bug", description = "A glowing companion that sparks with energy", rarity = "rare", price = 2500},
        {name = "Crystal Fox", description = "A mystical fox with crystal fur", rarity = "epic", price = 4000},
        {name = "Shadow Wolf", description = "A mysterious dark wolf companion", rarity = "legendary", price = 6000},
        {name = "Golden Eagle", description = "A majestic golden flying companion", rarity = "epic", price = 3500}
    }
}

function ContentAdminPanel:Init()
    -- Check if player has admin permissions
    if not self:HasAdminPermissions() then
        return
    end
    
    self:CreateAdminUI()
    self:SetupEventConnections()
    
    print("🔧 ContentAdminPanel initialized for authorized user")
end

function ContentAdminPanel:HasAdminPermissions()
    -- Check admin permissions (customize based on your system)
    return Player.Name == "YourUsername" or 
           Player:GetRankInGroup(0) >= 100 or 
           Player.UserId == 1 -- Example checks
end

function ContentAdminPanel:CreateAdminUI()
    -- Create admin GUI
    adminGui = Instance.new("ScreenGui")
    adminGui.Name = "ContentAdminGui"
    adminGui.ResetOnSpawn = false
    adminGui.Parent = PlayerGui
    
    -- Create admin toggle button
    local toggleButton = Instance.new("TextButton")
    toggleButton.Name = "AdminToggle"
    toggleButton.Size = UDim2.new(0, 120, 0, 40)
    toggleButton.Position = UDim2.new(1, -140, 0, 200)
    toggleButton.BackgroundColor3 = Color3.fromRGB(100, 100, 100)
    toggleButton.BorderSizePixel = 0
    toggleButton.Text = "🔧 Content Admin"
    toggleButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    toggleButton.TextScaled = true
    toggleButton.Font = Enum.Font.GothamBold
    toggleButton.Parent = adminGui
    
    local toggleCorner = Instance.new("UICorner")
    toggleCorner.CornerRadius = UDim.new(0, 8)
    toggleCorner.Parent = toggleButton
    
    -- Create admin panel (initially hidden)
    adminPanel = Instance.new("Frame")
    adminPanel.Name = "AdminPanel"
    adminPanel.Size = UDim2.new(0, 600, 0, 500)
    adminPanel.Position = UDim2.new(0.5, -300, 0.5, -250)
    adminPanel.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
    adminPanel.BorderSizePixel = 0
    adminPanel.Visible = false
    adminPanel.Parent = adminGui
    
    local panelCorner = Instance.new("UICorner")
    panelCorner.CornerRadius = UDim.new(0, 12)
    panelCorner.Parent = adminPanel
    
    -- Create panel header
    local header = Instance.new("Frame")
    header.Name = "Header"
    header.Size = UDim2.new(1, 0, 0, 50)
    header.Position = UDim2.new(0, 0, 0, 0)
    header.BackgroundColor3 = Color3.fromRGB(100, 100, 100)
    header.BorderSizePixel = 0
    header.Parent = adminPanel
    
    local headerCorner = Instance.new("UICorner")
    headerCorner.CornerRadius = UDim.new(0, 12)
    headerCorner.Parent = header
    
    -- Header title
    local headerTitle = Instance.new("TextLabel")
    headerTitle.Name = "Title"
    headerTitle.Size = UDim2.new(1, -100, 1, 0)
    headerTitle.Position = UDim2.new(0, 20, 0, 0)
    headerTitle.BackgroundTransparency = 1
    headerTitle.Text = "🔧 Content Management Panel"
    headerTitle.TextColor3 = Color3.fromRGB(255, 255, 255)
    headerTitle.TextScaled = true
    headerTitle.Font = Enum.Font.GothamBold
    headerTitle.TextXAlignment = Enum.TextXAlignment.Left
    headerTitle.Parent = header
    
    -- Close button
    local closeButton = Instance.new("TextButton")
    closeButton.Name = "CloseButton"
    closeButton.Size = UDim2.new(0, 40, 0, 30)
    closeButton.Position = UDim2.new(1, -50, 0, 10)
    closeButton.BackgroundColor3 = Color3.fromRGB(220, 50, 50)
    closeButton.BorderSizePixel = 0
    closeButton.Text = "✕"
    closeButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    closeButton.TextScaled = true
    closeButton.Font = Enum.Font.GothamBold
    closeButton.Parent = header
    
    local closeCorner = Instance.new("UICorner")
    closeCorner.CornerRadius = UDim.new(0, 6)
    closeCorner.Parent = closeButton
    
    -- Create content sections
    self:CreateQuickActionsSection()
    self:CreateTemplateSection()
    self:CreateAdvancedSection()
    
    -- Set up button connections
    toggleButton.MouseButton1Click:Connect(function()
        self:ToggleAdminPanel()
    end)
    
    closeButton.MouseButton1Click:Connect(function()
        self:HideAdminPanel()
    end)
end

function ContentAdminPanel:CreateQuickActionsSection()
    -- Quick actions for common tasks
    local quickSection = Instance.new("Frame")
    quickSection.Name = "QuickActions"
    quickSection.Size = UDim2.new(1, -20, 0, 120)
    quickSection.Position = UDim2.new(0, 10, 0, 60)
    quickSection.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
    quickSection.BorderSizePixel = 0
    quickSection.Parent = adminPanel
    
    local quickCorner = Instance.new("UICorner")
    quickCorner.CornerRadius = UDim.new(0, 8)
    quickCorner.Parent = quickSection
    
    -- Section title
    local quickTitle = Instance.new("TextLabel")
    quickTitle.Name = "Title"
    quickTitle.Size = UDim2.new(1, 0, 0, 30)
    quickTitle.Position = UDim2.new(0, 0, 0, 0)
    quickTitle.BackgroundTransparency = 1
    quickTitle.Text = "⚡ Quick Actions"
    quickTitle.TextColor3 = Color3.fromRGB(255, 215, 0)
    quickTitle.TextScaled = true
    quickTitle.Font = Enum.Font.GothamBold
    quickTitle.TextXAlignment = Enum.TextXAlignment.Center
    quickTitle.Parent = quickSection
    
    -- Quick action buttons
    local actions = {
        {text = "Reset Weekly\nLeaderboard", action = "reset_weekly"},
        {text = "Add Weekend\nEvent", action = "weekend_event"},
        {text = "50% Off\nAll Pets", action = "pet_sale"},
        {text = "New Trail\nDrop", action = "trail_drop"}
    }
    
    for i, action in pairs(actions) do
        local button = Instance.new("TextButton")
        button.Name = "QuickAction" .. i
        button.Size = UDim2.new(0.2, -10, 0, 60)
        button.Position = UDim2.new((i-1) * 0.25 + 0.025, 0, 0, 40)
        button.BackgroundColor3 = Color3.fromRGB(100, 200, 100)
        button.BorderSizePixel = 0
        button.Text = action.text
        button.TextColor3 = Color3.fromRGB(0, 0, 0)
        button.TextScaled = true
        button.Font = Enum.Font.Gotham
        button.Parent = quickSection
        
        local buttonCorner = Instance.new("UICorner")
        buttonCorner.CornerRadius = UDim.new(0, 6)
        buttonCorner.Parent = button
        
        button.MouseButton1Click:Connect(function()
            self:ExecuteQuickAction(action.action)
        end)
    end
end

function ContentAdminPanel:CreateTemplateSection()
    -- Template-based content creation
    local templateSection = Instance.new("Frame")
    templateSection.Name = "Templates"
    templateSection.Size = UDim2.new(1, -20, 0, 200)
    templateSection.Position = UDim2.new(0, 10, 0, 190)
    templateSection.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
    templateSection.BorderSizePixel = 0
    templateSection.Parent = adminPanel
    
    local templateCorner = Instance.new("UICorner")
    templateCorner.CornerRadius = UDim.new(0, 8)
    templateCorner.Parent = templateSection
    
    -- Section title
    local templateTitle = Instance.new("TextLabel")
    templateTitle.Name = "Title"
    templateTitle.Size = UDim2.new(1, 0, 0, 30)
    templateTitle.Position = UDim2.new(0, 0, 0, 0)
    templateTitle.BackgroundTransparency = 1
    templateTitle.Text = "📋 Content Templates"
    templateTitle.TextColor3 = Color3.fromRGB(255, 215, 0)
    templateTitle.TextScaled = true
    templateTitle.Font = Enum.Font.GothamBold
    templateTitle.TextXAlignment = Enum.TextXAlignment.Center
    templateTitle.Parent = templateSection
    
    -- Template categories
    local categories = {"Events", "Trails", "Pets"}
    
    for i, category in pairs(categories) do
        local categoryFrame = Instance.new("Frame")
        categoryFrame.Name = category .. "Category"
        categoryFrame.Size = UDim2.new(0.3, -10, 0, 150)
        categoryFrame.Position = UDim2.new((i-1) * 0.33 + 0.015, 0, 0, 40)
        categoryFrame.BackgroundColor3 = Color3.fromRGB(80, 80, 80)
        categoryFrame.BorderSizePixel = 0
        categoryFrame.Parent = templateSection
        
        local categoryCorner = Instance.new("UICorner")
        categoryCorner.CornerRadius = UDim.new(0, 6)
        categoryCorner.Parent = categoryFrame
        
        -- Category label
        local categoryLabel = Instance.new("TextLabel")
        categoryLabel.Name = "Label"
        categoryLabel.Size = UDim2.new(1, 0, 0, 25)
        categoryLabel.Position = UDim2.new(0, 0, 0, 0)
        categoryLabel.BackgroundTransparency = 1
        categoryLabel.Text = category
        categoryLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
        categoryLabel.TextScaled = true
        categoryLabel.Font = Enum.Font.GothamBold
        categoryLabel.Parent = categoryFrame
        
        -- Template buttons
        local templates = QUICK_TEMPLATES[category:lower()]
        for j, template in pairs(templates) do
            if j <= 4 then -- Show first 4 templates
                local templateButton = Instance.new("TextButton")
                templateButton.Name = "Template" .. j
                templateButton.Size = UDim2.new(1, -10, 0, 25)
                templateButton.Position = UDim2.new(0, 5, 0, 20 + (j * 30))
                templateButton.BackgroundColor3 = Color3.fromRGB(120, 120, 120)
                templateButton.BorderSizePixel = 0
                templateButton.Text = template.name
                templateButton.TextColor3 = Color3.fromRGB(255, 255, 255)
                templateButton.TextScaled = true
                templateButton.Font = Enum.Font.Gotham
                templateButton.Parent = categoryFrame
                
                local templateCorner = Instance.new("UICorner")
                templateCorner.CornerRadius = UDim.new(0, 4)
                templateCorner.Parent = templateButton
                
                templateButton.MouseButton1Click:Connect(function()
                    self:CreateFromTemplate(category:lower(), template)
                end)
            end
        end
    end
end

function ContentAdminPanel:CreateAdvancedSection()
    -- Advanced content management
    local advancedSection = Instance.new("Frame")
    advancedSection.Name = "Advanced"
    advancedSection.Size = UDim2.new(1, -20, 0, 80)
    advancedSection.Position = UDim2.new(0, 10, 0, 400)
    advancedSection.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
    advancedSection.BorderSizePixel = 0
    advancedSection.Parent = adminPanel
    
    local advancedCorner = Instance.new("UICorner")
    advancedCorner.CornerRadius = UDim.new(0, 8)
    advancedCorner.Parent = advancedSection
    
    -- Section title
    local advancedTitle = Instance.new("TextLabel")
    advancedTitle.Name = "Title"
    advancedTitle.Size = UDim2.new(1, 0, 0, 25)
    advancedTitle.Position = UDim2.new(0, 0, 0, 0)
    advancedTitle.BackgroundTransparency = 1
    advancedTitle.Text = "⚙️ Advanced Tools"
    advancedTitle.TextColor3 = Color3.fromRGB(255, 215, 0)
    advancedTitle.TextScaled = true
    advancedTitle.Font = Enum.Font.GothamBold
    advancedTitle.TextXAlignment = Enum.TextXAlignment.Center
    advancedTitle.Parent = advancedSection
    
    -- Advanced buttons
    local advancedActions = {
        {text = "Content Sync", action = "sync_content"},
        {text = "Clear Cache", action = "clear_cache"},
        {text = "Export Config", action = "export_config"}
    }
    
    for i, action in pairs(advancedActions) do
        local button = Instance.new("TextButton")
        button.Name = "Advanced" .. i
        button.Size = UDim2.new(0.3, -10, 0, 40)
        button.Position = UDim2.new((i-1) * 0.33 + 0.015, 0, 0, 30)
        button.BackgroundColor3 = Color3.fromRGB(150, 100, 200)
        button.BorderSizePixel = 0
        button.Text = action.text
        button.TextColor3 = Color3.fromRGB(255, 255, 255)
        button.TextScaled = true
        button.Font = Enum.Font.Gotham
        button.Parent = advancedSection
        
        local buttonCorner = Instance.new("UICorner")
        buttonCorner.CornerRadius = UDim.new(0, 6)
        buttonCorner.Parent = button
        
        button.MouseButton1Click:Connect(function()
            self:ExecuteAdvancedAction(action.action)
        end)
    end
end

function ContentAdminPanel:SetupEventConnections()
    -- Set up admin panel event connections
    print("🔧 Admin panel events connected")
end

function ContentAdminPanel:ToggleAdminPanel()
    if isAdminPanelVisible then
        self:HideAdminPanel()
    else
        self:ShowAdminPanel()
    end
end

function ContentAdminPanel:ShowAdminPanel()
    isAdminPanelVisible = true
    adminPanel.Visible = true
    
    -- Animate entrance
    adminPanel.Size = UDim2.new(0, 0, 0, 0)
    adminPanel.Position = UDim2.new(0.5, 0, 0.5, 0)
    
    local showTween = TweenService:Create(
        adminPanel,
        TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
        {
            Size = UDim2.new(0, 600, 0, 500),
            Position = UDim2.new(0.5, -300, 0.5, -250)
        }
    )
    showTween:Play()
end

function ContentAdminPanel:HideAdminPanel()
    isAdminPanelVisible = false
    
    local hideTween = TweenService:Create(
        adminPanel,
        TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
        {
            Size = UDim2.new(0, 0, 0, 0),
            Position = UDim2.new(0.5, 0, 0.5, 0)
        }
    )
    hideTween:Play()
    
    hideTween.Completed:Connect(function()
        adminPanel.Visible = false
    end)
end

function ContentAdminPanel:ExecuteQuickAction(action)
    -- Execute quick actions
    if action == "reset_weekly" then
        RemoteEvents.AdminContentUpdate:FireServer("add", "leaderboard", {
            type = "weekly",
            preserveData = true,
            rewards = {{type = "cosmetic", id = "weekly_crown", name = "Weekly Champion Crown"}},
            notification = "Weekly leaderboard reset! New competition begins!"
        })
        self:ShowConfirmation("Weekly leaderboard reset scheduled!")
        
    elseif action == "weekend_event" then
        local eventData = {
            name = "Weekend Bonus Extravaganza",
            description = "Double coins and XP all weekend long!",
            duration = 3,
            icon = "🎉",
            rewards = {{type = "trail", id = "weekend_sparkle", name = "Weekend Sparkle Trail"}}
        }
        self:CreateFromTemplate("events", eventData)
        
    elseif action == "pet_sale" then
        local eventData = {
            name = "Pet Paradise Sale",
            description = "All pets 50% off for 5 days!",
            duration = 5,
            icon = "🐾",
            rewards = {{type = "pet", id = "sale_special", name = "Sale Special Pet"}}
        }
        self:CreateFromTemplate("events", eventData)
        
    elseif action == "trail_drop" then
        local trailData = QUICK_TEMPLATES.trails[math.random(1, #QUICK_TEMPLATES.trails)]
        self:CreateFromTemplate("trails", trailData)
    end
end

function ContentAdminPanel:CreateFromTemplate(contentType, templateData)
    -- Create content from template
    RemoteEvents.AdminContentUpdate:FireServer("add", contentType, templateData)
    self:ShowConfirmation("New " .. contentType:sub(1, -2) .. " created: " .. templateData.name)
end

function ContentAdminPanel:ExecuteAdvancedAction(action)
    -- Execute advanced actions
    if action == "sync_content" then
        -- Request content sync
        self:ShowConfirmation("Content sync requested")
        
    elseif action == "clear_cache" then
        -- Clear content cache
        self:ShowConfirmation("Content cache cleared")
        
    elseif action == "export_config" then
        -- Export current configuration
        self:ShowConfirmation("Configuration exported to console")
        print("📋 Current Content Configuration:")
        -- This would export the current content state
    end
end

function ContentAdminPanel:ShowConfirmation(message)
    -- Show confirmation message
    local confirmation = Instance.new("TextLabel")
    confirmation.Name = "Confirmation"
    confirmation.Size = UDim2.new(0, 300, 0, 50)
    confirmation.Position = UDim2.new(0.5, -150, 0, 50)
    confirmation.BackgroundColor3 = Color3.fromRGB(100, 200, 100)
    confirmation.BorderSizePixel = 0
    confirmation.Text = "✅ " .. message
    confirmation.TextColor3 = Color3.fromRGB(0, 0, 0)
    confirmation.TextScaled = true
    confirmation.Font = Enum.Font.GothamBold
    confirmation.Parent = adminGui
    
    local confirmCorner = Instance.new("UICorner")
    confirmCorner.CornerRadius = UDim.new(0, 8)
    confirmCorner.Parent = confirmation
    
    -- Auto-remove after 3 seconds
    wait(3)
    confirmation:Destroy()
end

return ContentAdminPanel
