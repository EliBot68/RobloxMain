-- HubController.luau
-- Handles client-side hub interactions and UI

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local SoundService = game:GetService("SoundService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local HubController = {}

-- UI elements
local hubGui = nil
local welcomeFrame = nil
local hubNavigationFrame = nil

-- Hub interaction data
local hubLocations = {
    {name = "Pet Shop", icon = "🐾", description = "Adopt and upgrade your pets", position = Vector3.new(-40, 0, 20)},
    {name = "Upgrade Stall", icon = "⚡", description = "Boost your character abilities", position = Vector3.new(40, 0, 20)},
    {name = "Crate Stall", icon = "📦", description = "Open mystery crates for rewards", position = Vector3.new(-40, 0, -10)},
    {name = "Cosmetic Boutique", icon = "👗", description = "Customize your appearance", position = Vector3.new(40, 0, -10)},
    {name = "Quest Board", icon = "📋", description = "Accept daily challenges", position = Vector3.new(0, 0, 40)},
    {name = "Tournament Arena", icon = "🏆", description = "Compete with other players", position = Vector3.new(-20, 0, 50)},
    {name = "Mystery Shop", icon = "🔮", description = "Discover rare items", position = Vector3.new(20, 0, 50)}
}

function HubController:CreateHubGUI()
    -- Create main hub GUI
    hubGui = Instance.new("ScreenGui")
    hubGui.Name = "HubGui"
    hubGui.ResetOnSpawn = false
    hubGui.Parent = playerGui
    
    -- Welcome frame for new players
    welcomeFrame = Instance.new("Frame")
    welcomeFrame.Name = "WelcomeFrame"
    welcomeFrame.Size = UDim2.new(0, 400, 0, 250)
    welcomeFrame.Position = UDim2.new(0.5, -200, 0.5, -125)
    welcomeFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
    welcomeFrame.BorderSizePixel = 0
    welcomeFrame.Visible = false
    welcomeFrame.Parent = hubGui
    
    local welcomeCorner = Instance.new("UICorner")
    welcomeCorner.CornerRadius = UDim.new(0, 15)
    welcomeCorner.Parent = welcomeFrame
    
    local welcomeStroke = Instance.new("UIStroke")
    welcomeStroke.Color = Color3.fromRGB(100, 200, 255)
    welcomeStroke.Thickness = 2
    welcomeStroke.Parent = welcomeFrame
    
    -- Welcome title
    local welcomeTitle = Instance.new("TextLabel")
    welcomeTitle.Size = UDim2.new(1, -20, 0, 50)
    welcomeTitle.Position = UDim2.new(0, 10, 0, 10)
    welcomeTitle.BackgroundTransparency = 1
    welcomeTitle.Text = "🏪 Welcome to Color Rush Market! 🏪"
    welcomeTitle.TextColor3 = Color3.fromRGB(255, 255, 255)
    welcomeTitle.TextScaled = true
    welcomeTitle.Font = Enum.Font.SourceSansBold
    welcomeTitle.Parent = welcomeFrame
    
    -- Welcome description
    local welcomeDesc = Instance.new("TextLabel")
    welcomeDesc.Size = UDim2.new(1, -20, 0, 120)
    welcomeDesc.Position = UDim2.new(0, 10, 0, 70)
    welcomeDesc.BackgroundTransparency = 1
    welcomeDesc.Text = "Explore the market stalls to customize your character, adopt pets, and upgrade your abilities!\n\n🎮 Click the glowing PLAY portal to start your color-matching adventure!\n\n💡 Tip: Use WASD or arrow keys to move around the hub."
    welcomeDesc.TextColor3 = Color3.fromRGB(200, 200, 200)
    welcomeDesc.TextWrapped = true
    welcomeDesc.TextScaled = true
    welcomeDesc.Font = Enum.Font.SourceSans
    welcomeDesc.Parent = welcomeFrame
    
    -- Got it button
    local gotItButton = Instance.new("TextButton")
    gotItButton.Size = UDim2.new(0, 120, 0, 40)
    gotItButton.Position = UDim2.new(0.5, -60, 1, -55)
    gotItButton.BackgroundColor3 = Color3.fromRGB(100, 200, 100)
    gotItButton.Text = "Got it!"
    gotItButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    gotItButton.TextScaled = true
    gotItButton.Font = Enum.Font.SourceSansBold
    gotItButton.Parent = welcomeFrame
    
    local buttonCorner = Instance.new("UICorner")
    buttonCorner.CornerRadius = UDim.new(0, 8)
    buttonCorner.Parent = gotItButton
    
    gotItButton.MouseButton1Click:Connect(function()
        self:HideWelcomeScreen()
    end)
    
    -- Hub navigation frame
    hubNavigationFrame = Instance.new("Frame")
    hubNavigationFrame.Name = "HubNavigation"
    hubNavigationFrame.Size = UDim2.new(0, 300, 0, 400)
    hubNavigationFrame.Position = UDim2.new(1, -320, 0, 20)
    hubNavigationFrame.BackgroundColor3 = Color3.fromRGB(25, 25, 35)
    hubNavigationFrame.BorderSizePixel = 0
    hubNavigationFrame.Visible = false
    hubNavigationFrame.Parent = hubGui
    
    local navCorner = Instance.new("UICorner")
    navCorner.CornerRadius = UDim.new(0, 10)
    navCorner.Parent = hubNavigationFrame
    
    local navStroke = Instance.new("UIStroke")
    navStroke.Color = Color3.fromRGB(80, 150, 255)
    navStroke.Thickness = 1
    navStroke.Parent = hubNavigationFrame
    
    -- Navigation title
    local navTitle = Instance.new("TextLabel")
    navTitle.Size = UDim2.new(1, 0, 0, 40)
    navTitle.Position = UDim2.new(0, 0, 0, 0)
    navTitle.BackgroundTransparency = 1
    navTitle.Text = "🗺️ Hub Map"
    navTitle.TextColor3 = Color3.fromRGB(255, 255, 255)
    navTitle.TextScaled = true
    navTitle.Font = Enum.Font.SourceSansBold
    navTitle.Parent = hubNavigationFrame
    
    -- Scroll frame for locations
    local locationsScroll = Instance.new("ScrollingFrame")
    locationsScroll.Size = UDim2.new(1, -20, 1, -60)
    locationsScroll.Position = UDim2.new(0, 10, 0, 50)
    locationsScroll.BackgroundTransparency = 1
    locationsScroll.ScrollBarThickness = 6
    locationsScroll.Parent = hubNavigationFrame
    
    local locationsLayout = Instance.new("UIListLayout")
    locationsLayout.SortOrder = Enum.SortOrder.LayoutOrder
    locationsLayout.Padding = UDim.new(0, 8)
    locationsLayout.Parent = locationsScroll
    
    -- Create location buttons
    for i, location in pairs(hubLocations) do
        self:CreateLocationButton(location, locationsScroll, i)
    end
    
    -- Update scroll canvas size
    locationsLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        locationsScroll.CanvasSize = UDim2.new(0, 0, 0, locationsLayout.AbsoluteContentSize.Y + 10)
    end)
end

function HubController:CreateLocationButton(location, parent, layoutOrder)
    local locationButton = Instance.new("TextButton")
    locationButton.Size = UDim2.new(1, -10, 0, 60)
    locationButton.BackgroundColor3 = Color3.fromRGB(40, 40, 50)
    locationButton.BorderSizePixel = 0
    locationButton.Text = ""
    locationButton.LayoutOrder = layoutOrder
    locationButton.Parent = parent
    
    local buttonCorner = Instance.new("UICorner")
    buttonCorner.CornerRadius = UDim.new(0, 8)
    buttonCorner.Parent = locationButton
    
    -- Location icon and name
    local iconLabel = Instance.new("TextLabel")
    iconLabel.Size = UDim2.new(0, 40, 0, 40)
    iconLabel.Position = UDim2.new(0, 10, 0, 10)
    iconLabel.BackgroundTransparency = 1
    iconLabel.Text = location.icon
    iconLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    iconLabel.TextScaled = true
    iconLabel.Font = Enum.Font.SourceSansBold
    iconLabel.Parent = locationButton
    
    local nameLabel = Instance.new("TextLabel")
    nameLabel.Size = UDim2.new(1, -60, 0, 25)
    nameLabel.Position = UDim2.new(0, 55, 0, 5)
    nameLabel.BackgroundTransparency = 1
    nameLabel.Text = location.name
    nameLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    nameLabel.TextScaled = true
    nameLabel.Font = Enum.Font.SourceSansBold
    nameLabel.TextXAlignment = Enum.TextXAlignment.Left
    nameLabel.Parent = locationButton
    
    local descLabel = Instance.new("TextLabel")
    descLabel.Size = UDim2.new(1, -60, 0, 25)
    descLabel.Position = UDim2.new(0, 55, 0, 30)
    descLabel.BackgroundTransparency = 1
    descLabel.Text = location.description
    descLabel.TextColor3 = Color3.fromRGB(180, 180, 180)
    descLabel.TextScaled = true
    descLabel.Font = Enum.Font.SourceSans
    descLabel.TextXAlignment = Enum.TextXAlignment.Left
    descLabel.Parent = locationButton
    
    -- Hover effects
    locationButton.MouseEnter:Connect(function()
        local hoverTween = TweenService:Create(locationButton, TweenInfo.new(0.2), {
            BackgroundColor3 = Color3.fromRGB(60, 60, 70)
        })
        hoverTween:Play()
    end)
    
    locationButton.MouseLeave:Connect(function()
        local leaveTween = TweenService:Create(locationButton, TweenInfo.new(0.2), {
            BackgroundColor3 = Color3.fromRGB(40, 40, 50)
        })
        leaveTween:Play()
    end)
    
    -- Click to navigate
    locationButton.MouseButton1Click:Connect(function()
        self:NavigateToLocation(location)
    end)
end

function HubController:ShowWelcomeScreen()
    if not welcomeFrame then return end
    
    welcomeFrame.Visible = true
    welcomeFrame.Size = UDim2.new(0, 0, 0, 0)
    welcomeFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
    
    local showTween = TweenService:Create(welcomeFrame, TweenInfo.new(0.5, Enum.EasingStyle.Back), {
        Size = UDim2.new(0, 400, 0, 250),
        Position = UDim2.new(0.5, -200, 0.5, -125)
    })
    showTween:Play()
end

function HubController:HideWelcomeScreen()
    if not welcomeFrame then return end
    
    local hideTween = TweenService:Create(welcomeFrame, TweenInfo.new(0.3, Enum.EasingStyle.Quad), {
        Size = UDim2.new(0, 0, 0, 0),
        Position = UDim2.new(0.5, 0, 0.5, 0)
    })
    hideTween:Play()
    
    hideTween.Completed:Connect(function()
        welcomeFrame.Visible = false
        self:ShowHubNavigation()
    end)
end

function HubController:ShowHubNavigation()
    if not hubNavigationFrame then return end
    
    hubNavigationFrame.Visible = true
    hubNavigationFrame.Position = UDim2.new(1, 0, 0, 20)
    
    local showTween = TweenService:Create(hubNavigationFrame, TweenInfo.new(0.4, Enum.EasingStyle.Quad), {
        Position = UDim2.new(1, -320, 0, 20)
    })
    showTween:Play()
end

function HubController:NavigateToLocation(location)
    if not player.Character or not player.Character:FindFirstChild("HumanoidRootPart") then
        return
    end
    
    local targetPosition = Vector3.new(0, 10, 0) + location.position + Vector3.new(0, 0, 10) -- Offset to stand in front
    
    -- Move player to location
    player.Character.HumanoidRootPart.CFrame = CFrame.new(targetPosition)
    
    -- Show location notification
    self:ShowLocationNotification(location.name, location.description)
    
    -- Play navigation sound
    local navSound = Instance.new("Sound")
    navSound.SoundId = "rbxasset://sounds/electronicpingshort.wav"
    navSound.Volume = 0.3
    navSound.Parent = SoundService
    navSound:Play()
    
    navSound.Ended:Connect(function()
        navSound:Destroy()
    end)
end

function HubController:ShowLocationNotification(locationName, description)
    -- Create temporary notification
    local notification = Instance.new("Frame")
    notification.Size = UDim2.new(0, 300, 0, 80)
    notification.Position = UDim2.new(0.5, -150, 0, -90)
    notification.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
    notification.BorderSizePixel = 0
    notification.Parent = hubGui
    
    local notifCorner = Instance.new("UICorner")
    notifCorner.CornerRadius = UDim.new(0, 10)
    notifCorner.Parent = notification
    
    local notifStroke = Instance.new("UIStroke")
    notifStroke.Color = Color3.fromRGB(100, 200, 255)
    notifStroke.Thickness = 2
    notifStroke.Parent = notification
    
    local titleLabel = Instance.new("TextLabel")
    titleLabel.Size = UDim2.new(1, -20, 0, 30)
    titleLabel.Position = UDim2.new(0, 10, 0, 5)
    titleLabel.BackgroundTransparency = 1
    titleLabel.Text = "📍 " .. locationName
    titleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    titleLabel.TextScaled = true
    titleLabel.Font = Enum.Font.SourceSansBold
    titleLabel.Parent = notification
    
    local descLabel = Instance.new("TextLabel")
    descLabel.Size = UDim2.new(1, -20, 0, 35)
    descLabel.Position = UDim2.new(0, 10, 0, 40)
    descLabel.BackgroundTransparency = 1
    descLabel.Text = description
    descLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
    descLabel.TextScaled = true
    descLabel.Font = Enum.Font.SourceSans
    descLabel.Parent = notification
    
    -- Animate notification
    local showTween = TweenService:Create(notification, TweenInfo.new(0.3, Enum.EasingStyle.Back), {
        Position = UDim2.new(0.5, -150, 0, 20)
    })
    showTween:Play()
    
    -- Auto-hide after 3 seconds
    wait(3)
    
    local hideTween = TweenService:Create(notification, TweenInfo.new(0.3, Enum.EasingStyle.Quad), {
        Position = UDim2.new(0.5, -150, 0, -90),
        BackgroundTransparency = 1
    })
    hideTween:Play()
    
    hideTween.Completed:Connect(function()
        notification:Destroy()
    end)
end

function HubController:HandleInput()
    -- Toggle hub navigation with M key
    UserInputService.InputBegan:Connect(function(input, gameProcessed)
        if gameProcessed then return end
        
        if input.KeyCode == Enum.KeyCode.M then
            if hubNavigationFrame and hubNavigationFrame.Visible then
                -- Hide navigation
                local hideTween = TweenService:Create(hubNavigationFrame, TweenInfo.new(0.3, Enum.EasingStyle.Quad), {
                    Position = UDim2.new(1, 0, 0, 20)
                })
                hideTween:Play()
                
                hideTween.Completed:Connect(function()
                    hubNavigationFrame.Visible = false
                end)
            else
                -- Show navigation
                self:ShowHubNavigation()
            end
        end
    end)
end

function HubController:CheckFirstTime()
    -- Check if player is new (this could be integrated with data service)
    local DataService = require(ReplicatedStorage.Shared.modules.DataService)
    
    spawn(function()
        wait(2) -- Wait for character to spawn and stabilize
        
        -- For now, show welcome screen for all players (can be modified based on actual data)
        -- In production, check if player has tutorialCompleted flag
        self:ShowWelcomeScreen()
    end)
end

function HubController:Init()
    -- Create hub GUI
    self:CreateHubGUI()
    
    -- Set up input handling
    self:HandleInput()
    
    -- Create premium shop button
    self:CreatePremiumShopButton()
    
    -- Check if player needs welcome screen
    if player.Character then
        self:CheckFirstTime()
    else
        player.CharacterAdded:Connect(function()
            self:CheckFirstTime()
        end)
    end
    
    print("HubController initialized")
end

function HubController:CreatePremiumShopButton()
    -- Create premium shop button in the hub
    local screenGui = playerGui:FindFirstChild("HubNavigationUI") or Instance.new("ScreenGui")
    screenGui.Name = "HubNavigationUI"
    screenGui.ResetOnSpawn = false
    screenGui.Parent = playerGui
    
    -- Premium shop button
    local premiumButton = Instance.new("TextButton")
    premiumButton.Name = "PremiumShopButton"
    premiumButton.Size = UDim2.new(0, 180, 0, 60)
    premiumButton.Position = UDim2.new(0, 20, 0, 200)
    premiumButton.BackgroundColor3 = Color3.fromRGB(255, 215, 0)
    premiumButton.BorderSizePixel = 0
    premiumButton.Text = "💎 PREMIUM SHOP"
    premiumButton.TextColor3 = Color3.fromRGB(0, 0, 0)
    premiumButton.TextSize = 16
    premiumButton.Font = Enum.Font.GothamBold
    premiumButton.Parent = screenGui
    
    local premiumCorner = Instance.new("UICorner")
    premiumCorner.CornerRadius = UDim.new(0, 10)
    premiumCorner.Parent = premiumButton
    
    -- Gradient effect
    local premiumGradient = Instance.new("UIGradient")
    premiumGradient.Color = ColorSequence.new{
        ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 235, 59)),
        ColorSequenceKeypoint.new(0.5, Color3.fromRGB(255, 215, 0)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 193, 7))
    }
    premiumGradient.Rotation = 45
    premiumGradient.Parent = premiumButton
    
    -- Glowing effect
    local glowFrame = Instance.new("Frame")
    glowFrame.Name = "GlowFrame"
    glowFrame.Size = UDim2.new(1, 6, 1, 6)
    glowFrame.Position = UDim2.new(0, -3, 0, -3)
    glowFrame.BackgroundColor3 = Color3.fromRGB(255, 215, 0)
    glowFrame.BorderSizePixel = 0
    glowFrame.ZIndex = premiumButton.ZIndex - 1
    glowFrame.BackgroundTransparency = 0.7
    glowFrame.Parent = premiumButton
    
    local glowCorner = Instance.new("UICorner")
    glowCorner.CornerRadius = UDim.new(0, 13)
    glowCorner.Parent = glowFrame
    
    -- Animate glow effect
    local glowTween = TweenService:Create(glowFrame, TweenInfo.new(1.5, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true), {
        BackgroundTransparency = 0.9
    })
    glowTween:Play()
    
    -- Button hover effects
    premiumButton.MouseEnter:Connect(function()
        local hoverTween = TweenService:Create(premiumButton, TweenInfo.new(0.2), {
            Size = UDim2.new(0, 185, 0, 62),
            Position = UDim2.new(0, 17.5, 0, 199)
        })
        hoverTween:Play()
    end)
    
    premiumButton.MouseLeave:Connect(function()
        local leaveTween = TweenService:Create(premiumButton, TweenInfo.new(0.2), {
            Size = UDim2.new(0, 180, 0, 60),
            Position = UDim2.new(0, 20, 0, 200)
        })
        leaveTween:Play()
    end)
    
    -- Button click handler
    premiumButton.MouseButton1Click:Connect(function()
        RemoteEvents.OpenMonetizationShop:FireServer()
    end)
    
    print("💎 Created premium shop button")
end

return HubController
