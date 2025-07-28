-- MobileUIController.luau
-- Manages comprehensive mobile UI with game controls, responsive menus, and accessibility

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local GuiService = game:GetService("GuiService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local RemoteEvents = require(ReplicatedStorage.Shared.modules.RemoteEvents)

local MobileUIController = {}

-- UI Elements
local mobileGameGui = nil
local mobileHubGui = nil
local isMobile = false
local isInGame = false
local trailFXEnabled = true

-- Mobile detection
function MobileUIController:DetectMobile()
    local hasTouch = UserInputService.TouchEnabled
    local hasKeyboard = UserInputService.KeyboardEnabled
    local hasMouse = UserInputService.MouseEnabled
    
    -- Consider it mobile if touch is enabled and no physical keyboard/mouse
    isMobile = hasTouch and not (hasKeyboard and hasMouse)
    
    -- Also check for small screen size (common on mobile)
    local viewportSize = workspace.CurrentCamera.ViewportSize
    local isSmallScreen = viewportSize.X < 1000 or viewportSize.Y < 600
    
    isMobile = isMobile or (hasTouch and isSmallScreen)
    
    print("📱 Mobile detected: " .. tostring(isMobile))
    return isMobile
end

function MobileUIController:CreateMobileGameControls()
    -- Create mobile game controls GUI (for in-game actions)
    mobileGameGui = Instance.new("ScreenGui")
    mobileGameGui.Name = "MobileGameGui"
    mobileGameGui.ResetOnSpawn = false
    mobileGameGui.IgnoreGuiInset = true
    mobileGameGui.Enabled = false -- Start hidden
    mobileGameGui.Parent = playerGui
    
    -- Game controls container
    local gameContainer = Instance.new("Frame")
    gameContainer.Name = "GameContainer"
    gameContainer.Size = UDim2.new(1, 0, 1, 0)
    gameContainer.BackgroundTransparency = 1
    gameContainer.Parent = mobileGameGui
    
    -- Create game control buttons
    self:CreateJumpButton(gameContainer)
    self:CreateColorSwitchGameButton(gameContainer)
    self:CreatePauseButton(gameContainer)
    self:CreateSettingsButton(gameContainer)
    
    print("📱 Mobile game controls created")
end

function MobileUIController:CreateJumpButton(parent)
    -- Large jump button (bottom right)
    local jumpButton = Instance.new("TextButton")
    jumpButton.Name = "JumpButton"
    jumpButton.Size = UDim2.new(0, 120, 0, 120)
    jumpButton.Position = UDim2.new(1, -140, 1, -140)
    jumpButton.BackgroundColor3 = Color3.fromRGB(255, 100, 100)
    jumpButton.BorderSizePixel = 0
    jumpButton.Text = "⬆️"
    jumpButton.TextColor3 = Color3.new(1, 1, 1)
    jumpButton.TextSize = 48
    jumpButton.Font = Enum.Font.GothamBold
    jumpButton.AutoButtonColor = false
    jumpButton.Parent = parent
    
    -- Add corner radius
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 25)
    corner.Parent = jumpButton
    
    -- Add drop shadow
    local shadow = Instance.new("Frame")
    shadow.Name = "Shadow"
    shadow.Size = UDim2.new(1, 8, 1, 8)
    shadow.Position = UDim2.new(0, 4, 0, 4)
    shadow.BackgroundColor3 = Color3.new(0, 0, 0)
    shadow.BackgroundTransparency = 0.6
    shadow.BorderSizePixel = 0
    shadow.ZIndex = jumpButton.ZIndex - 1
    shadow.Parent = jumpButton
    
    local shadowCorner = Instance.new("UICorner")
    shadowCorner.CornerRadius = UDim.new(0, 25)
    shadowCorner.Parent = shadow
    
    -- Add glow effect
    local glow = Instance.new("Frame")
    glow.Name = "Glow"
    glow.Size = UDim2.new(1, 20, 1, 20)
    glow.Position = UDim2.new(0, -10, 0, -10)
    glow.BackgroundColor3 = Color3.fromRGB(255, 150, 150)
    glow.BackgroundTransparency = 0.8
    glow.BorderSizePixel = 0
    glow.ZIndex = jumpButton.ZIndex - 2
    glow.Parent = jumpButton
    
    local glowCorner = Instance.new("UICorner")
    glowCorner.CornerRadius = UDim.new(0, 35)
    glowCorner.Parent = glow
    
    -- Jump functionality
    local isJumping = false
    
    jumpButton.MouseButton1Down:Connect(function()
        if isJumping then return end
        isJumping = true
        
        -- Make player jump
        local character = player.Character
        if character and character:FindFirstChild("Humanoid") then
            character.Humanoid.Jump = true
        end
        
        -- Visual feedback
        self:AnimateButtonPress(jumpButton)
        
        -- Prevent spam jumping
        wait(0.5)
        isJumping = false
    end)
    
    -- Add label
    local label = Instance.new("TextLabel")
    label.Name = "Label"
    label.Size = UDim2.new(1, 0, 0, 30)
    label.Position = UDim2.new(0, 0, 1, 10)
    label.BackgroundTransparency = 1
    label.Text = "JUMP"
    label.TextColor3 = Color3.new(1, 1, 1)
    label.TextSize = 16
    label.Font = Enum.Font.GothamBold
    label.TextStrokeTransparency = 0
    label.TextStrokeColor3 = Color3.new(0, 0, 0)
    label.Parent = jumpButton
end

function MobileUIController:CreateColorSwitchGameButton(parent)
    -- Color switch button for in-game (bottom left)
    local colorButton = Instance.new("TextButton")
    colorButton.Name = "ColorSwitchGameButton"
    colorButton.Size = UDim2.new(0, 120, 0, 120)
    colorButton.Position = UDim2.new(0, 20, 1, -140)
    colorButton.BackgroundColor3 = Color3.fromRGB(100, 255, 100)
    colorButton.BorderSizePixel = 0
    colorButton.Text = "🎨"
    colorButton.TextColor3 = Color3.new(1, 1, 1)
    colorButton.TextSize = 48
    colorButton.Font = Enum.Font.GothamBold
    colorButton.AutoButtonColor = false
    colorButton.Parent = parent
    
    -- Add corner radius
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 25)
    corner.Parent = colorButton
    
    -- Add drop shadow
    local shadow = Instance.new("Frame")
    shadow.Name = "Shadow"
    shadow.Size = UDim2.new(1, 8, 1, 8)
    shadow.Position = UDim2.new(0, 4, 0, 4)
    shadow.BackgroundColor3 = Color3.new(0, 0, 0)
    shadow.BackgroundTransparency = 0.6
    shadow.BorderSizePixel = 0
    shadow.ZIndex = colorButton.ZIndex - 1
    shadow.Parent = colorButton
    
    local shadowCorner = Instance.new("UICorner")
    shadowCorner.CornerRadius = UDim.new(0, 25)
    shadowCorner.Parent = shadow
    
    -- Color switching functionality
    local colors = {
        {name = "RED", color = Color3.fromRGB(255, 100, 100), emoji = "🔴"},
        {name = "GREEN", color = Color3.fromRGB(100, 255, 100), emoji = "🟢"},
        {name = "BLUE", color = Color3.fromRGB(100, 100, 255), emoji = "🔵"},
        {name = "YELLOW", color = Color3.fromRGB(255, 255, 100), emoji = "🟡"},
        {name = "PURPLE", color = Color3.fromRGB(200, 100, 255), emoji = "🟣"},
        {name = "ORANGE", color = Color3.fromRGB(255, 150, 50), emoji = "🟠"}
    }
    
    local currentColorIndex = 2 -- Start with green
    
    colorButton.MouseButton1Click:Connect(function()
        -- Cycle to next color
        currentColorIndex = currentColorIndex % #colors + 1
        local colorData = colors[currentColorIndex]
        
        -- Animate color change
        local tween = TweenService:Create(colorButton, TweenInfo.new(0.2, Enum.EasingStyle.Back), {
            BackgroundColor3 = colorData.color
        })
        tween:Play()
        
        -- Update button appearance
        colorButton.Text = colorData.emoji
        
        -- Send color change to server
        RemoteEvents.PlayerColorChanged:FireServer(colorData.name)
        
        -- Visual feedback
        self:AnimateButtonPress(colorButton)
        
        print("📱 Game color switched to: " .. colorData.name)
    end)
    
    -- Add label
    local label = Instance.new("TextLabel")
    label.Name = "Label"
    label.Size = UDim2.new(1, 0, 0, 30)
    label.Position = UDim2.new(0, 0, 1, 10)
    label.BackgroundTransparency = 1
    label.Text = "COLOR"
    label.TextColor3 = Color3.new(1, 1, 1)
    label.TextSize = 16
    label.Font = Enum.Font.GothamBold
    label.TextStrokeTransparency = 0
    label.TextStrokeColor3 = Color3.new(0, 0, 0)
    label.Parent = colorButton
end

function MobileUIController:CreatePauseButton(parent)
    -- Pause button (top left)
    local pauseButton = Instance.new("TextButton")
    pauseButton.Name = "PauseButton"
    pauseButton.Size = UDim2.new(0, 80, 0, 80)
    pauseButton.Position = UDim2.new(0, 20, 0, 50)
    pauseButton.BackgroundColor3 = Color3.fromRGB(255, 200, 50)
    pauseButton.BorderSizePixel = 0
    pauseButton.Text = "⏸️"
    pauseButton.TextColor3 = Color3.new(1, 1, 1)
    pauseButton.TextSize = 32
    pauseButton.Font = Enum.Font.GothamBold
    pauseButton.AutoButtonColor = false
    pauseButton.Parent = parent
    
    -- Add corner radius
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 15)
    corner.Parent = pauseButton
    
    -- Pause functionality
    pauseButton.MouseButton1Click:Connect(function()
        -- Send pause request to server
        RemoteEvents.PauseGame:FireServer()
        
        -- Visual feedback
        self:AnimateButtonPress(pauseButton)
        
        print("📱 Game paused from mobile")
    end)
end

function MobileUIController:CreateSettingsButton(parent)
    -- Settings/FX toggle button (top right)
    local settingsContainer = Instance.new("Frame")
    settingsContainer.Name = "SettingsContainer"
    settingsContainer.Size = UDim2.new(0, 200, 0, 80)
    settingsContainer.Position = UDim2.new(1, -220, 0, 50)
    settingsContainer.BackgroundTransparency = 1
    settingsContainer.Parent = parent
    
    -- Trail FX toggle button
    local fxButton = Instance.new("TextButton")
    fxButton.Name = "TrailFXButton"
    fxButton.Size = UDim2.new(0, 80, 0, 80)
    fxButton.Position = UDim2.new(0, 0, 0, 0)
    fxButton.BackgroundColor3 = trailFXEnabled and Color3.fromRGB(100, 255, 100) or Color3.fromRGB(255, 100, 100)
    fxButton.BorderSizePixel = 0
    fxButton.Text = trailFXEnabled and "✨" or "🚫"
    fxButton.TextColor3 = Color3.new(1, 1, 1)
    fxButton.TextSize = 28
    fxButton.Font = Enum.Font.GothamBold
    fxButton.AutoButtonColor = false
    fxButton.Parent = settingsContainer
    
    local fxCorner = Instance.new("UICorner")
    fxCorner.CornerRadius = UDim.new(0, 15)
    fxCorner.Parent = fxButton
    
    -- FX toggle functionality
    fxButton.MouseButton1Click:Connect(function()
        trailFXEnabled = not trailFXEnabled
        
        -- Update button appearance
        local newColor = trailFXEnabled and Color3.fromRGB(100, 255, 100) or Color3.fromRGB(255, 100, 100)
        local newText = trailFXEnabled and "✨" or "🚫"
        
        TweenService:Create(fxButton, TweenInfo.new(0.2), {
            BackgroundColor3 = newColor
        }):Play()
        
        fxButton.Text = newText
        
        -- Send FX toggle to server/client systems
        RemoteEvents.ToggleTrailFX:FireServer(trailFXEnabled)
        
        -- Visual feedback
        self:AnimateButtonPress(fxButton)
        
        print("📱 Trail FX toggled: " .. tostring(trailFXEnabled))
    end)
    
    -- FX label
    local fxLabel = Instance.new("TextLabel")
    fxLabel.Name = "FXLabel"
    fxLabel.Size = UDim2.new(1, 0, 0, 25)
    fxLabel.Position = UDim2.new(0, 0, 1, 5)
    fxLabel.BackgroundTransparency = 1
    fxLabel.Text = "Trail FX"
    fxLabel.TextColor3 = Color3.new(1, 1, 1)
    fxLabel.TextSize = 12
    fxLabel.Font = Enum.Font.Gotham
    fxLabel.TextStrokeTransparency = 0
    fxLabel.TextStrokeColor3 = Color3.new(0, 0, 0)
    fxLabel.Parent = fxButton
    
    -- Settings button
    local settingsButton = Instance.new("TextButton")
    settingsButton.Name = "SettingsButton"
    settingsButton.Size = UDim2.new(0, 80, 0, 80)
    settingsButton.Position = UDim2.new(0, 100, 0, 0)
    settingsButton.BackgroundColor3 = Color3.fromRGB(150, 150, 150)
    settingsButton.BorderSizePixel = 0
    settingsButton.Text = "⚙️"
    settingsButton.TextColor3 = Color3.new(1, 1, 1)
    settingsButton.TextSize = 28
    settingsButton.Font = Enum.Font.GothamBold
    settingsButton.AutoButtonColor = false
    settingsButton.Parent = settingsContainer
    
    local settingsCorner = Instance.new("UICorner")
    settingsCorner.CornerRadius = UDim.new(0, 15)
    settingsCorner.Parent = settingsButton
    
    -- Settings functionality
    settingsButton.MouseButton1Click:Connect(function()
        -- Open mobile-friendly settings
        RemoteEvents.OpenMobileSettings:FireServer()
        
        -- Visual feedback
        self:AnimateButtonPress(settingsButton)
        
        print("📱 Mobile settings opened")
    end)
end

function MobileUIController:CreateColorSwitchButton(parent)
    -- Color switch button (cycles through colors)
    local colorButton = Instance.new("TextButton")
    colorButton.Name = "ColorSwitchButton"
    colorButton.Size = UDim2.new(0, 100, 0, 100)
    colorButton.Position = UDim2.new(0, 10, 0, 50)
    colorButton.BackgroundColor3 = Color3.new(1, 0.3, 0.3) -- Start with red
    colorButton.BorderSizePixel = 0
    colorButton.Text = "🎨"
    colorButton.TextColor3 = Color3.new(1, 1, 1)
    colorButton.TextSize = 36
    colorButton.Font = Enum.Font.SourceSansBold
    colorButton.Parent = parent
    
    -- Add corner radius for modern look
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 20)
    corner.Parent = colorButton
    
    -- Add drop shadow effect
    local shadow = Instance.new("Frame")
    shadow.Name = "Shadow"
    shadow.Size = UDim2.new(1, 6, 1, 6)
    shadow.Position = UDim2.new(0, 3, 0, 3)
    shadow.BackgroundColor3 = Color3.new(0, 0, 0)
    shadow.BackgroundTransparency = 0.7
    shadow.BorderSizePixel = 0
    shadow.ZIndex = colorButton.ZIndex - 1
    shadow.Parent = colorButton
    
    local shadowCorner = Instance.new("UICorner")
    shadowCorner.CornerRadius = UDim.new(0, 20)
    shadowCorner.Parent = shadow
    
    -- Button functionality
    local colors = {
        {name = "RED", color = Color3.new(1, 0.3, 0.3), emoji = "🔴"},
        {name = "GREEN", color = Color3.new(0.3, 1, 0.3), emoji = "🟢"},
        {name = "BLUE", color = Color3.new(0.3, 0.3, 1), emoji = "🔵"},
        {name = "YELLOW", color = Color3.new(1, 1, 0.3), emoji = "🟡"},
        {name = "PURPLE", color = Color3.new(0.8, 0.3, 1), emoji = "🟣"},
        {name = "ORANGE", color = Color3.new(1, 0.6, 0.2), emoji = "🟠"}
    }
    
    local currentColorIndex = 1
    
    colorButton.MouseButton1Click:Connect(function()
        -- Cycle to next color
        currentColorIndex = currentColorIndex % #colors + 1
        local colorData = colors[currentColorIndex]
        
        -- Animate color change
        local tween = TweenService:Create(colorButton, TweenInfo.new(0.2, Enum.EasingStyle.Quad), {
            BackgroundColor3 = colorData.color
        })
        tween:Play()
        
        -- Update button text
        colorButton.Text = colorData.emoji
        
        -- Send color change to server
        RemoteEvents.PlayerColorChanged:FireServer(colorData.name)
        
        -- Animate button press
        self:AnimateButtonPress(colorButton)
        
        print("📱 Mobile color switched to: " .. colorData.name)
    end)
    
    -- Add label below button
    local label = Instance.new("TextLabel")
    label.Name = "Label"
    label.Size = UDim2.new(1, 0, 0, 25)
    label.Position = UDim2.new(0, 0, 1, 5)
    label.BackgroundTransparency = 1
    label.Text = "Color"
    label.TextColor3 = Color3.new(1, 1, 1)
    label.TextSize = 14
    label.Font = Enum.Font.SourceSansBold
    label.TextStrokeTransparency = 0.5
    label.TextStrokeColor3 = Color3.new(0, 0, 0)
    label.Parent = colorButton
end

function MobileUIController:CreatePlayPortalButton(parent)
    -- Play portal button (starts game)
    local playButton = Instance.new("TextButton")
    playButton.Name = "PlayPortalButton"
    playButton.Size = UDim2.new(0, 100, 0, 100)
    playButton.Position = UDim2.new(0, 10, 0, 170)
    playButton.BackgroundColor3 = Color3.new(0.2, 0.8, 0.3)
    playButton.BorderSizePixel = 0
    playButton.Text = "▶️"
    playButton.TextColor3 = Color3.new(1, 1, 1)
    playButton.TextSize = 42
    playButton.Font = Enum.Font.SourceSansBold
    playButton.Parent = parent
    
    -- Add corner radius
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 20)
    corner.Parent = playButton
    
    -- Add drop shadow
    local shadow = Instance.new("Frame")
    shadow.Name = "Shadow"
    shadow.Size = UDim2.new(1, 6, 1, 6)
    shadow.Position = UDim2.new(0, 3, 0, 3)
    shadow.BackgroundColor3 = Color3.new(0, 0, 0)
    shadow.BackgroundTransparency = 0.7
    shadow.BorderSizePixel = 0
    shadow.ZIndex = playButton.ZIndex - 1
    shadow.Parent = playButton
    
    local shadowCorner = Instance.new("UICorner")
    shadowCorner.CornerRadius = UDim.new(0, 20)
    shadowCorner.Parent = shadow
    
    -- Button functionality
    playButton.MouseButton1Click:Connect(function()
        -- Trigger game start (teleport to game area)
        RemoteEvents.JoinSoloGame:FireServer()
        
        -- Animate button press
        self:AnimateButtonPress(playButton)
        
        print("📱 Mobile play button pressed")
    end)
    
    -- Add label
    local label = Instance.new("TextLabel")
    label.Name = "Label"
    label.Size = UDim2.new(1, 0, 0, 25)
    label.Position = UDim2.new(0, 0, 1, 5)
    label.BackgroundTransparency = 1
    label.Text = "Play"
    label.TextColor3 = Color3.new(1, 1, 1)
    label.TextSize = 14
    label.Font = Enum.Font.SourceSansBold
    label.TextStrokeTransparency = 0.5
    label.TextStrokeColor3 = Color3.new(0, 0, 0)
    label.Parent = playButton
end

function MobileUIController:CreateCloseMenusButton(parent)
    -- Close menus button (closes all open UIs)
    local closeButton = Instance.new("TextButton")
    closeButton.Name = "CloseMenusButton"
    closeButton.Size = UDim2.new(0, 100, 0, 100)
    closeButton.Position = UDim2.new(0, 10, 0, 290)
    closeButton.BackgroundColor3 = Color3.new(0.8, 0.3, 0.3)
    closeButton.BorderSizePixel = 0
    closeButton.Text = "✕"
    closeButton.TextColor3 = Color3.new(1, 1, 1)
    closeButton.TextSize = 36
    closeButton.Font = Enum.Font.SourceSansBold
    closeButton.Parent = parent
    
    -- Add corner radius
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 20)
    corner.Parent = closeButton
    
    -- Add drop shadow
    local shadow = Instance.new("Frame")
    shadow.Name = "Shadow"
    shadow.Size = UDim2.new(1, 6, 1, 6)
    shadow.Position = UDim2.new(0, 3, 0, 3)
    shadow.BackgroundColor3 = Color3.new(0, 0, 0)
    shadow.BackgroundTransparency = 0.7
    shadow.BorderSizePixel = 0
    shadow.ZIndex = closeButton.ZIndex - 1
    shadow.Parent = closeButton
    
    local shadowCorner = Instance.new("UICorner")
    shadowCorner.CornerRadius = UDim.new(0, 20)
    shadowCorner.Parent = shadow
    
    -- Button functionality
    closeButton.MouseButton1Click:Connect(function()
        -- Close all open menus/UIs
        self:CloseAllMenus()
        
        -- Animate button press
        self:AnimateButtonPress(closeButton)
        
        print("📱 Mobile close menus button pressed")
    end)
    
    -- Add label
    local label = Instance.new("TextLabel")
    label.Name = "Label"
    label.Size = UDim2.new(1, 0, 0, 25)
    label.Position = UDim2.new(0, 0, 1, 5)
    label.BackgroundTransparency = 1
    label.Text = "Close"
    label.TextColor3 = Color3.new(1, 1, 1)
    label.TextSize = 14
    label.Font = Enum.Font.SourceSansBold
    label.TextStrokeTransparency = 0.5
    label.TextStrokeColor3 = Color3.new(0, 0, 0)
    label.Parent = closeButton
end

function MobileUIController:AnimateButtonPress(button)
    -- Scale down then back up for press feedback
    local originalSize = button.Size
    
    local shrinkTween = TweenService:Create(button, TweenInfo.new(0.1, Enum.EasingStyle.Quad), {
        Size = UDim2.new(originalSize.X.Scale * 0.9, originalSize.X.Offset * 0.9, 
                        originalSize.Y.Scale * 0.9, originalSize.Y.Offset * 0.9)
    })
    
    shrinkTween:Play()
    shrinkTween.Completed:Connect(function()
        local expandTween = TweenService:Create(button, TweenInfo.new(0.1, Enum.EasingStyle.Quad), {
            Size = originalSize
        })
        expandTween:Play()
    end)
end

function MobileUIController:CloseAllMenus()
    -- Close common UI elements that might be open
    local uisToClose = {
        "ShopGui",
        "QuestGui", 
        "SettingsGui",
        "TutorialGui",
        "PetGui",
        "PartyGui",
        "TournamentGui"
    }
    
    for _, uiName in pairs(uisToClose) do
        local ui = playerGui:FindFirstChild(uiName)
        if ui and ui.Visible then
            ui.Visible = false
            print("📱 Closed mobile UI: " .. uiName)
        end
    end
    
    -- Also send close events to controllers
    RemoteEvents.CloseAllMenus:FireServer()
end

function MobileUIController:ShowMobileUI(show)
    -- Show/hide mobile UI based on context
    if mobileHubGui then
        mobileHubGui.Enabled = show and not isInGame and isMobile
    end
    
    if mobileGameGui then
        mobileGameGui.Enabled = show and isInGame and isMobile
    end
    
    print("📱 Mobile UI visibility updated - Hub: " .. tostring(show and not isInGame) .. ", Game: " .. tostring(show and isInGame))
end

function MobileUIController:SwitchToGameMode()
    -- Switch from hub to game controls
    isInGame = true
    
    if isMobile then
        -- Hide hub UI, show game controls
        if mobileHubGui then
            mobileHubGui.Enabled = false
        end
        
        if mobileGameGui then
            mobileGameGui.Enabled = true
        end
        
        print("📱 Switched to game mode - showing game controls")
    end
end

function MobileUIController:SwitchToHubMode()
    -- Switch from game to hub controls
    isInGame = false
    
    if isMobile then
        -- Hide game controls, show hub UI
        if mobileGameGui then
            mobileGameGui.Enabled = false
        end
        
        if mobileHubGui then
            mobileHubGui.Enabled = true
        end
        
        print("📱 Switched to hub mode - showing hub controls")
    end
end

function MobileUIController:TestTouchElements()
    -- Test all mobile touch elements for proper sizing
    if not isMobile then return end
    
    print("📱 Testing mobile touch elements...")
    
    local function testElement(element, minSize)
        if element and element:IsA("GuiObject") then
            local actualSize = element.AbsoluteSize
            local isGoodSize = actualSize.X >= minSize and actualSize.Y >= minSize
            
            print(string.format("📱 Element %s: %dx%d %s", 
                element.Name, 
                actualSize.X, 
                actualSize.Y, 
                isGoodSize and "✅ Good" or "❌ Too small"
            ))
            
            if not isGoodSize then
                print("📱 Warning: Element may be too small for touch input!")
            end
        end
    end
    
    -- Test hub elements
    if mobileHubGui then
        local container = mobileHubGui:FindFirstChild("ButtonContainer")
        if container then
            for _, child in pairs(container:GetChildren()) do
                if child:IsA("TextButton") then
                    testElement(child, 44) -- 44px minimum for touch
                end
            end
        end
    end
    
    -- Test game elements
    if mobileGameGui then
        local gameContainer = mobileGameGui:FindFirstChild("GameContainer")
        if gameContainer then
            testElement(gameContainer:FindFirstChild("JumpButton"), 44)
            testElement(gameContainer:FindFirstChild("ColorSwitchGameButton"), 44)
            testElement(gameContainer:FindFirstChild("PauseButton"), 44)
        end
    end
    
    print("📱 Touch element testing complete")
end

function MobileUIController:TestHitboxes()
    -- Test function to verify tap areas are working correctly
    if not mobileHubGui then return end
    
    print("📱 Testing mobile UI hitboxes...")
    
    local buttons = mobileHubGui.ButtonContainer:GetChildren()
    for _, button in pairs(buttons) do
        if button:IsA("TextButton") then
            -- Add temporary visual feedback for testing
            local testFrame = Instance.new("Frame")
            testFrame.Name = "HitboxTest"
            testFrame.Size = button.Size
            testFrame.Position = button.Position
            testFrame.BackgroundColor3 = Color3.new(1, 1, 0)
            testFrame.BackgroundTransparency = 0.8
            testFrame.BorderSizePixel = 2
            testFrame.BorderColor3 = Color3.new(1, 0, 0)
            testFrame.ZIndex = 999
            testFrame.Parent = button.Parent
            
            -- Remove test frame after 3 seconds
            game:GetService("Debris"):AddItem(testFrame, 3)
            
            print("📱 " .. button.Name .. " hitbox: " .. tostring(button.AbsoluteSize))
        end
    end
end

function MobileUIController:OptimizeForSmallScreens()
    if not mobileHubGui then return end
    
    local viewportSize = workspace.CurrentCamera.ViewportSize
    local isVerySmallScreen = viewportSize.X < 600 or viewportSize.Y < 400
    
    if isVerySmallScreen then
        print("📱 Optimizing for very small screen: " .. tostring(viewportSize))
        
        -- Make buttons slightly smaller on very small screens
        local container = mobileHubGui.ButtonContainer
        local buttons = container:GetChildren()
        
        for _, button in pairs(buttons) do
            if button:IsA("TextButton") then
                button.Size = UDim2.new(0, 80, 0, 80) -- Smaller but still tap-friendly
                button.TextSize = button.TextSize * 0.8
            end
        end
        
        -- Adjust button spacing
        if container:FindFirstChild("ColorSwitchButton") then
            container.ColorSwitchButton.Position = UDim2.new(0, 10, 0, 40)
        end
        if container:FindFirstChild("PlayPortalButton") then
            container.PlayPortalButton.Position = UDim2.new(0, 10, 0, 135)
        end
        if container:FindFirstChild("CloseMenusButton") then
            container.CloseMenusButton.Position = UDim2.new(0, 10, 0, 230)
        end
    end
end

function MobileUIController:OptimizeTopBarForMobile()
    -- Find existing top bar elements and optimize for mobile
    local existingTopBar = playerGui:FindFirstChild("TopBar") or playerGui:FindFirstChild("CoinsGui") or playerGui:FindFirstChild("MainGui")
    
    if existingTopBar then
        print("📱 Found existing top bar, optimizing for mobile...")
        
        -- Create mobile-optimized top bar
        local mobileTopBar = Instance.new("Frame")
        mobileTopBar.Name = "MobileTopBar"
        mobileTopBar.Size = UDim2.new(1, 0, 0, 90)
        mobileTopBar.Position = UDim2.new(0, 0, 0, 0)
        mobileTopBar.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
        mobileTopBar.BackgroundTransparency = 0.1
        mobileTopBar.BorderSizePixel = 0
        mobileTopBar.ZIndex = 10
        mobileTopBar.Parent = existingTopBar
        
        -- Add gradient
        local gradient = Instance.new("UIGradient")
        gradient.Color = ColorSequence.new{
            ColorSequenceKeypoint.new(0, Color3.fromRGB(40, 40, 50)),
            ColorSequenceKeypoint.new(1, Color3.fromRGB(20, 20, 30))
        }
        gradient.Rotation = 90
        gradient.Parent = mobileTopBar
        
        -- Create mobile coins display
        self:CreateMobileCoinsDisplay(mobileTopBar)
        
        -- Create mobile XP display
        self:CreateMobileXPDisplay(mobileTopBar)
        
        -- Create mobile level display
        self:CreateMobileLevelDisplay(mobileTopBar)
        
        -- Hide or minimize original top bar elements
        for _, child in pairs(existingTopBar:GetChildren()) do
            if child ~= mobileTopBar and child:IsA("GuiObject") then
                if child.Name:find("Coin") or child.Name:find("XP") or child.Name:find("Level") then
                    child.Visible = false
                end
            end
        end
    end
end

function MobileUIController:CreateMobileCoinsDisplay(parent)
    -- Mobile-optimized coins display
    local coinsContainer = Instance.new("Frame")
    coinsContainer.Name = "MobileCoinsContainer"
    coinsContainer.Size = UDim2.new(0, 140, 0, 60)
    coinsContainer.Position = UDim2.new(0, 10, 0, 15)
    coinsContainer.BackgroundColor3 = Color3.fromRGB(255, 215, 50)
    coinsContainer.BorderSizePixel = 0
    coinsContainer.Parent = parent
    
    local coinsCorner = Instance.new("UICorner")
    coinsCorner.CornerRadius = UDim.new(0, 12)
    coinsCorner.Parent = coinsContainer
    
    -- Coins icon
    local coinsIcon = Instance.new("TextLabel")
    coinsIcon.Name = "CoinsIcon"
    coinsIcon.Size = UDim2.new(0, 40, 1, 0)
    coinsIcon.Position = UDim2.new(0, 5, 0, 0)
    coinsIcon.BackgroundTransparency = 1
    coinsIcon.Text = "🪙"
    coinsIcon.TextSize = 28
    coinsIcon.Font = Enum.Font.GothamBold
    coinsIcon.Parent = coinsContainer
    
    -- Coins amount
    local coinsLabel = Instance.new("TextLabel")
    coinsLabel.Name = "CoinsLabel"
    coinsLabel.Size = UDim2.new(1, -50, 1, 0)
    coinsLabel.Position = UDim2.new(0, 45, 0, 0)
    coinsLabel.BackgroundTransparency = 1
    coinsLabel.Text = "0"
    coinsLabel.TextColor3 = Color3.new(0, 0, 0)
    coinsLabel.TextSize = 24
    coinsLabel.Font = Enum.Font.GothamBold
    coinsLabel.TextXAlignment = Enum.TextXAlignment.Left
    coinsLabel.TextYAlignment = Enum.TextYAlignment.Center
    coinsLabel.Parent = coinsContainer
    
    -- Auto-update coins display
    spawn(function()
        while coinsContainer.Parent do
            -- Get coins from player data or leaderstats
            local coins = 0
            if player.leaderstats and player.leaderstats:FindFirstChild("Coins") then
                coins = player.leaderstats.Coins.Value
            end
            
            -- Format large numbers
            local formattedCoins = self:FormatNumber(coins)
            coinsLabel.Text = formattedCoins
            
            wait(0.5)
        end
    end)
    
    return coinsContainer
end

function MobileUIController:CreateMobileXPDisplay(parent)
    -- Mobile-optimized XP bar
    local xpContainer = Instance.new("Frame")
    xpContainer.Name = "MobileXPContainer"
    xpContainer.Size = UDim2.new(0, 200, 0, 35)
    xpContainer.Position = UDim2.new(0, 160, 0, 15)
    xpContainer.BackgroundColor3 = Color3.fromRGB(60, 60, 70)
    xpContainer.BorderSizePixel = 0
    xpContainer.Parent = parent
    
    local xpCorner = Instance.new("UICorner")
    xpCorner.CornerRadius = UDim.new(0, 8)
    xpCorner.Parent = xpContainer
    
    -- XP fill bar
    local xpBar = Instance.new("Frame")
    xpBar.Name = "XPBar"
    xpBar.Size = UDim2.new(0, 0, 1, 0)
    xpBar.Position = UDim2.new(0, 0, 0, 0)
    xpBar.BackgroundColor3 = Color3.fromRGB(100, 255, 100)
    xpBar.BorderSizePixel = 0
    xpBar.Parent = xpContainer
    
    local xpBarCorner = Instance.new("UICorner")
    xpBarCorner.CornerRadius = UDim.new(0, 8)
    xpBarCorner.Parent = xpBar
    
    -- XP gradient
    local xpGradient = Instance.new("UIGradient")
    xpGradient.Color = ColorSequence.new{
        ColorSequenceKeypoint.new(0, Color3.fromRGB(150, 255, 150)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(50, 200, 50))
    }
    xpGradient.Parent = xpBar
    
    -- XP text
    local xpLabel = Instance.new("TextLabel")
    xpLabel.Name = "XPLabel"
    xpLabel.Size = UDim2.new(1, 0, 1, 0)
    xpLabel.Position = UDim2.new(0, 0, 0, 0)
    xpLabel.BackgroundTransparency = 1
    xpLabel.Text = "XP: 0/100"
    xpLabel.TextColor3 = Color3.new(1, 1, 1)
    xpLabel.TextSize = 16
    xpLabel.Font = Enum.Font.GothamBold
    xpLabel.TextStrokeTransparency = 0
    xpLabel.TextStrokeColor3 = Color3.new(0, 0, 0)
    xpLabel.Parent = xpContainer
    
    -- Auto-update XP display
    spawn(function()
        while xpContainer.Parent do
            -- Get XP from player data
            local currentXP = 0
            local maxXP = 100
            
            if player.leaderstats then
                if player.leaderstats:FindFirstChild("XP") then
                    currentXP = player.leaderstats.XP.Value
                end
                if player.leaderstats:FindFirstChild("Level") then
                    local level = player.leaderstats.Level.Value
                    maxXP = level * 100 -- Example XP scaling
                end
            end
            
            -- Update bar fill
            local fillPercentage = math.min(currentXP / maxXP, 1)
            TweenService:Create(xpBar, TweenInfo.new(0.3), {
                Size = UDim2.new(fillPercentage, 0, 1, 0)
            }):Play()
            
            -- Update text
            xpLabel.Text = string.format("XP: %s/%s", self:FormatNumber(currentXP), self:FormatNumber(maxXP))
            
            wait(0.5)
        end
    end)
    
    return xpContainer
end

function MobileUIController:CreateMobileLevelDisplay(parent)
    -- Mobile-optimized level display
    local levelContainer = Instance.new("Frame")
    levelContainer.Name = "MobileLevelContainer"
    levelContainer.Size = UDim2.new(0, 80, 0, 60)
    levelContainer.Position = UDim2.new(0, 370, 0, 15)
    levelContainer.BackgroundColor3 = Color3.fromRGB(150, 100, 255)
    levelContainer.BorderSizePixel = 0
    levelContainer.Parent = parent
    
    local levelCorner = Instance.new("UICorner")
    levelCorner.CornerRadius = UDim.new(0, 12)
    levelCorner.Parent = levelContainer
    
    -- Level text
    local levelLabel = Instance.new("TextLabel")
    levelLabel.Name = "LevelLabel"
    levelLabel.Size = UDim2.new(1, 0, 0.6, 0)
    levelLabel.Position = UDim2.new(0, 0, 0, 0)
    levelLabel.BackgroundTransparency = 1
    levelLabel.Text = "1"
    levelLabel.TextColor3 = Color3.new(1, 1, 1)
    levelLabel.TextSize = 20
    levelLabel.Font = Enum.Font.GothamBold
    levelLabel.Parent = levelContainer
    
    -- Level subtitle
    local levelSubtitle = Instance.new("TextLabel")
    levelSubtitle.Name = "LevelSubtitle"
    levelSubtitle.Size = UDim2.new(1, 0, 0.4, 0)
    levelSubtitle.Position = UDim2.new(0, 0, 0.6, 0)
    levelSubtitle.BackgroundTransparency = 1
    levelSubtitle.Text = "LVL"
    levelSubtitle.TextColor3 = Color3.new(1, 1, 1)
    levelSubtitle.TextSize = 12
    levelSubtitle.Font = Enum.Font.Gotham
    levelSubtitle.Parent = levelContainer
    
    -- Auto-update level display
    spawn(function()
        while levelContainer.Parent do
            -- Get level from player data
            local level = 1
            if player.leaderstats and player.leaderstats:FindFirstChild("Level") then
                level = player.leaderstats.Level.Value
            end
            
            levelLabel.Text = tostring(level)
            
            wait(1)
        end
    end)
    
    return levelContainer
end

function MobileUIController:FormatNumber(number)
    -- Format large numbers for mobile display
    if number >= 1000000000 then
        return string.format("%.1fB", number / 1000000000)
    elseif number >= 1000000 then
        return string.format("%.1fM", number / 1000000)
    elseif number >= 1000 then
        return string.format("%.1fK", number / 1000)
    else
        return tostring(number)
    end
end

function MobileUIController:CreateMobileHubUI()
    -- Create main mobile GUI container
    mobileHubGui = Instance.new("ScreenGui")
    mobileHubGui.Name = "MobileHubGui"
    mobileHubGui.ResetOnSpawn = false
    mobileHubGui.IgnoreGuiInset = true
    mobileHubGui.Parent = playerGui
    
    -- Main button container (right side of screen)
    local buttonContainer = Instance.new("Frame")
    buttonContainer.Name = "ButtonContainer"
    buttonContainer.Size = UDim2.new(0, 120, 1, 0)
    buttonContainer.Position = UDim2.new(1, -130, 0, 0)
    buttonContainer.BackgroundTransparency = 1
    buttonContainer.Parent = mobileHubGui
    
    -- Create large tap-friendly buttons
    self:CreateColorSwitchButton(buttonContainer)
    self:CreatePlayPortalButton(buttonContainer)
    self:CreateCloseMenusButton(buttonContainer)
    
    -- Optimize top bar for mobile
    self:OptimizeTopBarForMobile()
    
    print("📱 Mobile hub UI created with responsive elements")
end

function MobileUIController:Initialize()
    print("📱 MobileUIController initializing...")
    
    -- Detect if this is a mobile device
    self:DetectMobile()
    
    if isMobile then
        -- Create mobile-specific UI
        self:CreateMobileHubUI()
        self:CreateMobileGameControls()
        
        -- Optimize for screen size
        self:OptimizeForSmallScreens()
        
        -- Show mobile UI
        self:ShowMobileUI(true)
        
        -- Set up event connections for game mode switching
        self:SetupEventConnections()
        
        -- Test hitboxes in development
        wait(1) -- Give UI time to load
        -- Uncomment for testing: self:TestHitboxes()
        
        print("✅ Mobile UI initialized successfully!")
    else
        print("📱 Desktop detected - mobile UI disabled")
    end
    
    -- Handle screen size changes
    workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(function()
        if isMobile then
            self:OptimizeForSmallScreens()
        end
    end)
end

function MobileUIController:SetupEventConnections()
    -- Set up remote event connections for mobile UI
    print("📱 Setting up mobile event connections...")
    
    -- Listen for game mode changes
    RemoteEvents.GameStarted.OnClientEvent:Connect(function()
        self:SwitchToGameMode()
    end)
    
    RemoteEvents.GameEnded.OnClientEvent:Connect(function()
        self:SwitchToHubMode()
    end)
    
    RemoteEvents.ReturnToHub.OnClientEvent:Connect(function()
        self:SwitchToHubMode()
    end)
    
    -- Listen for manual mode switches
    RemoteEvents.SwitchToGameMode.OnClientEvent:Connect(function()
        self:SwitchToGameMode()
    end)
    
    RemoteEvents.SwitchToHubMode.OnClientEvent:Connect(function()
        self:SwitchToHubMode()
    end)
    
    print("📱 Mobile event connections established")
end

-- Auto-initialize
MobileUIController:Initialize()

return MobileUIController
