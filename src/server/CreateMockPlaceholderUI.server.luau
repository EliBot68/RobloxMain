-- CreateMockPlaceholderUI.server.luau
-- Creates mock placeholder UI elements for testing the migration system
-- This simulates common placeholder scenarios found in development

local StarterGui = game:GetService("StarterGui")
local Players = game:GetService("Players")

local MockPlaceholderCreator = {}

function MockPlaceholderCreator:CreateMockElements()
    print("🎭 Creating mock placeholder UI elements for migration testing...")
    
    -- Create a test ScreenGui in StarterGui
    local mockGui = Instance.new("ScreenGui")
    mockGui.Name = "MockPlaceholderGUI"
    mockGui.ResetOnSpawn = false
    mockGui.Parent = StarterGui
    
    -- Create container frame
    local container = Instance.new("Frame")
    container.Name = "PlaceholderContainer"
    container.Size = UDim2.new(1, 0, 1, 0)
    container.BackgroundTransparency = 1
    container.Parent = mockGui
    
    -- Mock placeholder button with placeholder text
    local placeholderButton = Instance.new("TextButton")
    placeholderButton.Name = "PlaceholderButton"
    placeholderButton.Size = UDim2.new(0, 200, 0, 50)
    placeholderButton.Position = UDim2.new(0, 50, 0, 50)
    placeholderButton.Text = "Placeholder Button"
    placeholderButton.BackgroundColor3 = Color3.fromRGB(100, 100, 100)
    placeholderButton.TextColor3 = Color3.white
    placeholderButton.Font = Enum.Font.Legacy
    placeholderButton.Parent = container
    
    -- Mock image with placeholder image
    local placeholderImage = Instance.new("ImageLabel")
    placeholderImage.Name = "PlaceholderImage"
    placeholderImage.Size = UDim2.new(0, 100, 0, 100)
    placeholderImage.Position = UDim2.new(0, 50, 0, 120)
    placeholderImage.Image = "rbxasset://textures/ui/GuiImagePlaceholder.png"
    placeholderImage.BackgroundColor3 = Color3.fromRGB(200, 200, 200)
    placeholderImage.Parent = container
    
    -- Mock frame with placeholder name
    local placeholderFrame = Instance.new("Frame")
    placeholderFrame.Name = "PlaceholderFrame"
    placeholderFrame.Size = UDim2.new(0, 300, 0, 150)
    placeholderFrame.Position = UDim2.new(0, 50, 0, 240)
    placeholderFrame.BackgroundColor3 = Color3.fromRGB(150, 150, 150)
    placeholderFrame.BorderSizePixel = 2
    placeholderFrame.Parent = container
    
    -- Mock text label with placeholder text
    local placeholderText = Instance.new("TextLabel")
    placeholderText.Name = "PlaceholderText"
    placeholderText.Size = UDim2.new(1, -20, 0, 30)
    placeholderText.Position = UDim2.new(0, 10, 0, 10)
    placeholderText.Text = "This is placeholder text"
    placeholderText.BackgroundTransparency = 1
    placeholderText.TextColor3 = Color3.black
    placeholderText.Font = Enum.Font.Arial
    placeholderText.Parent = placeholderFrame
    
    -- Mock outdated UI elements that need modernizing
    local oldButton = Instance.new("TextButton")
    oldButton.Name = "OldStyleButton"
    oldButton.Size = UDim2.new(0, 150, 0, 40)
    oldButton.Position = UDim2.new(0, 50, 0, 410)
    oldButton.Text = "Old Button"
    oldButton.BackgroundColor3 = Color3.fromRGB(170, 170, 170)
    oldButton.BorderSizePixel = 3
    oldButton.Font = Enum.Font.Legacy
    oldButton.TextSize = 14
    oldButton.Parent = container
    
    -- Mock image button with placeholder
    local placeholderImageButton = Instance.new("ImageButton")
    placeholderImageButton.Name = "PlaceholderImageButton"
    placeholderImageButton.Size = UDim2.new(0, 80, 0, 80)
    placeholderImageButton.Position = UDim2.new(0, 220, 0, 410)
    placeholderImageButton.Image = "GuiImagePlaceholder.png"
    placeholderImageButton.BackgroundColor3 = Color3.fromRGB(180, 180, 180)
    placeholderImageButton.Parent = container
    
    -- Create common game UI elements that might need migration
    self:CreateGameHUDMocks(container)
    self:CreateMenuMocks(container)
    
    print("✅ Mock placeholder UI elements created successfully")
    print("📝 Elements created:")
    print("  - PlaceholderButton (text placeholder)")
    print("  - PlaceholderImage (GuiImagePlaceholder.png)")
    print("  - PlaceholderFrame (placeholder name)")
    print("  - PlaceholderText (placeholder text content)")
    print("  - OldStyleButton (outdated styling)")
    print("  - PlaceholderImageButton (placeholder image)")
    print("  - Game HUD mockups")
    print("  - Menu mockups")
end

function MockPlaceholderCreator:CreateGameHUDMocks(parent)
    -- Mock game HUD with placeholder elements
    local hudFrame = Instance.new("Frame")
    hudFrame.Name = "MockGameHUD"
    hudFrame.Size = UDim2.new(0, 400, 0, 200)
    hudFrame.Position = UDim2.new(0, 400, 0, 50)
    hudFrame.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
    hudFrame.BackgroundTransparency = 0.5
    hudFrame.BorderSizePixel = 1
    hudFrame.Parent = parent
    
    -- Mock score display
    local scoreLabel = Instance.new("TextLabel")
    scoreLabel.Name = "ScoreDisplay"
    scoreLabel.Size = UDim2.new(0, 150, 0, 30)
    scoreLabel.Position = UDim2.new(0, 10, 0, 10)
    scoreLabel.Text = "Score: Placeholder"
    scoreLabel.BackgroundTransparency = 1
    scoreLabel.TextColor3 = Color3.white
    scoreLabel.Font = Enum.Font.Arial
    scoreLabel.TextScaled = true
    scoreLabel.Parent = hudFrame
    
    -- Mock timer with placeholder
    local timerLabel = Instance.new("TextLabel")
    timerLabel.Name = "TimerDisplay"
    timerLabel.Size = UDim2.new(0, 150, 0, 30)
    timerLabel.Position = UDim2.new(0, 10, 0, 50)
    timerLabel.Text = "Time: 00:00"
    timerLabel.BackgroundTransparency = 1
    timerLabel.TextColor3 = Color3.white
    timerLabel.Font = Enum.Font.Legacy
    timerLabel.TextScaled = true
    timerLabel.Parent = hudFrame
    
    -- Mock placeholder icon
    local iconImage = Instance.new("ImageLabel")
    iconImage.Name = "PlaceholderIcon"
    iconImage.Size = UDim2.new(0, 50, 0, 50)
    iconImage.Position = UDim2.new(0, 200, 0, 10)
    iconImage.Image = "placeholder.png"
    iconImage.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    iconImage.Parent = hudFrame
end

function MockPlaceholderCreator:CreateMenuMocks(parent)
    -- Mock menu system with placeholder elements
    local menuFrame = Instance.new("Frame")
    menuFrame.Name = "MockMenuSystem"
    menuFrame.Size = UDim2.new(0, 300, 0, 400)
    menuFrame.Position = UDim2.new(0, 400, 0, 270)
    menuFrame.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
    menuFrame.BorderSizePixel = 2
    menuFrame.Parent = parent
    
    -- Mock menu title with placeholder
    local titleLabel = Instance.new("TextLabel")
    titleLabel.Name = "MenuTitle"
    titleLabel.Size = UDim2.new(1, -20, 0, 50)
    titleLabel.Position = UDim2.new(0, 10, 0, 10)
    titleLabel.Text = "PLACEHOLDER MENU"
    titleLabel.BackgroundTransparency = 1
    titleLabel.TextColor3 = Color3.white
    titleLabel.Font = Enum.Font.Arial
    titleLabel.TextScaled = true
    titleLabel.Parent = menuFrame
    
    -- Mock placeholder buttons
    local buttonNames = {"Placeholder Action", "TODO: Button", "Sample Text", "Button"}
    for i, buttonText in pairs(buttonNames) do
        local mockButton = Instance.new("TextButton")
        mockButton.Name = "MockButton" .. i
        mockButton.Size = UDim2.new(0, 250, 0, 40)
        mockButton.Position = UDim2.new(0, 25, 0, 60 + (i * 50))
        mockButton.Text = buttonText
        mockButton.BackgroundColor3 = Color3.fromRGB(120, 120, 120)
        mockButton.TextColor3 = Color3.white
        mockButton.Font = Enum.Font.Legacy
        mockButton.BorderSizePixel = 2
        mockButton.Parent = menuFrame
    end
end

function MockPlaceholderCreator:CreatePlayerSpecificMocks()
    -- Create placeholder elements that will appear when players join
    Players.PlayerAdded:Connect(function(player)
        player.CharacterAdded:Connect(function()
            wait(2) -- Wait for PlayerGui to load
            
            if player.PlayerGui then
                local playerMockGui = Instance.new("ScreenGui")
                playerMockGui.Name = "PlayerMockPlaceholders"
                playerMockGui.ResetOnSpawn = false
                playerMockGui.Parent = player.PlayerGui
                
                -- Mock placeholder notification
                local notification = Instance.new("TextLabel")
                notification.Name = "PlaceholderNotification"
                notification.Size = UDim2.new(0, 300, 0, 60)
                notification.Position = UDim2.new(0.5, -150, 0, 50)
                notification.Text = "Placeholder: Welcome " .. player.Name
                notification.BackgroundColor3 = Color3.fromRGB(100, 100, 100)
                notification.TextColor3 = Color3.white
                notification.Font = Enum.Font.Arial
                notification.TextScaled = true
                notification.Parent = playerMockGui
                
                -- Mock placeholder button for player
                local playerButton = Instance.new("TextButton")
                playerButton.Name = "PlayerPlaceholderButton"
                playerButton.Size = UDim2.new(0, 200, 0, 50)
                playerButton.Position = UDim2.new(0.5, -100, 0, 130)
                playerButton.Text = "Placeholder Action"
                playerButton.BackgroundColor3 = Color3.fromRGB(150, 150, 150)
                playerButton.TextColor3 = Color3.white
                playerButton.Font = Enum.Font.Legacy
                playerButton.Parent = playerMockGui
                
                print("📱 Created player-specific placeholder UI for: " .. player.Name)
            end
        end)
    end)
end

-- Auto-run mock creation
spawn(function()
    wait(1) -- Brief delay to ensure services are ready
    MockPlaceholderCreator:CreateMockElements()
    MockPlaceholderCreator:CreatePlayerSpecificMocks()
end)

return MockPlaceholderCreator
