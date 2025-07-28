-- EnhancedMobileUIController.luau
-- Comprehensive mobile UI optimization with larger buttons and corner positioning

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local GuiService = game:GetService("GuiService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local RemoteEvents = require(ReplicatedStorage.Shared.modules.RemoteEvents)

local EnhancedMobileUIController = {}

-- UI Elements
local mobileGameGui = nil
local mobileHubGui = nil
local isMobile = false
local isInGame = false
local touchControlsEnabled = true

-- Mobile detection with enhanced logic
function EnhancedMobileUIController:DetectMobile()
    local hasTouch = UserInputService.TouchEnabled
    local hasKeyboard = UserInputService.KeyboardEnabled
    local hasMouse = UserInputService.MouseEnabled
    
    -- Enhanced detection for mobile devices
    isMobile = hasTouch and not (hasKeyboard and hasMouse)
    
    -- Check screen dimensions (mobile typically < 1200px width)
    local viewportSize = workspace.CurrentCamera.ViewportSize
    local isSmallScreen = viewportSize.X < 1200 or viewportSize.Y < 800
    
    -- Override detection for touch devices with small screens
    if hasTouch and isSmallScreen then
        isMobile = true
    end
    
    -- Force mobile mode if aspect ratio suggests phone (taller than wide)
    local aspectRatio = viewportSize.Y / viewportSize.X
    if hasTouch and aspectRatio > 1.5 then
        isMobile = true
    end
    
    print("📱 Enhanced mobile detection: " .. tostring(isMobile) .. " | Screen: " .. viewportSize.X .. "x" .. viewportSize.Y)
    return isMobile
end

function EnhancedMobileUIController:CreateLargeGameControls()
    -- Create enlarged mobile game controls for phone screens
    mobileGameGui = Instance.new("ScreenGui")
    mobileGameGui.Name = "EnhancedMobileGameGui"
    mobileGameGui.ResetOnSpawn = false
    mobileGameGui.IgnoreGuiInset = true
    mobileGameGui.Enabled = false
    mobileGameGui.Parent = playerGui
    
    -- Main container
    local container = Instance.new("Frame")
    container.Name = "Container"
    container.Size = UDim2.new(1, 0, 1, 0)
    container.BackgroundTransparency = 1
    container.Parent = mobileGameGui
    
    -- Create enlarged control buttons positioned in corners
    self:CreateLargeJumpButton(container)
    self:CreateLargeColorSwitchButton(container)
    self:CreateLargePauseButton(container)
    self:CreateMobileGameHUD(container)
    
    print("📱 Large mobile game controls created")
end

function EnhancedMobileUIController:CreateLargeJumpButton(parent)
    -- Extra large jump button (bottom right corner)
    local jumpButton = Instance.new("TextButton")
    jumpButton.Name = "LargeJumpButton"
    jumpButton.Size = UDim2.new(0, 160, 0, 160) -- Much larger
    jumpButton.Position = UDim2.new(1, -180, 1, -180) -- Corner positioning
    jumpButton.BackgroundColor3 = Color3.fromRGB(255, 100, 100)
    jumpButton.BorderSizePixel = 0
    jumpButton.Text = ""
    jumpButton.AutoButtonColor = false
    jumpButton.Parent = parent
    
    -- Extra rounded corners for modern look
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 35)
    corner.Parent = jumpButton
    
    -- Large jump icon
    local jumpIcon = Instance.new("TextLabel")
    jumpIcon.Name = "JumpIcon"
    jumpIcon.Size = UDim2.new(1, 0, 0.6, 0)
    jumpIcon.Position = UDim2.new(0, 0, 0, 0)
    jumpIcon.BackgroundTransparency = 1
    jumpIcon.Text = "⬆️"
    jumpIcon.TextColor3 = Color3.new(1, 1, 1)
    jumpIcon.TextSize = 64 -- Extra large icon
    jumpIcon.Font = Enum.Font.GothamBold
    jumpIcon.TextStrokeTransparency = 0
    jumpIcon.TextStrokeColor3 = Color3.new(0, 0, 0)
    jumpIcon.Parent = jumpButton
    
    -- Jump label
    local jumpLabel = Instance.new("TextLabel")
    jumpLabel.Name = "JumpLabel"
    jumpLabel.Size = UDim2.new(1, 0, 0.4, 0)
    jumpLabel.Position = UDim2.new(0, 0, 0.6, 0)
    jumpLabel.BackgroundTransparency = 1
    jumpLabel.Text = "JUMP"
    jumpLabel.TextColor3 = Color3.new(1, 1, 1)
    jumpLabel.TextSize = 20
    jumpLabel.Font = Enum.Font.GothamBold
    jumpLabel.TextStrokeTransparency = 0
    jumpLabel.TextStrokeColor3 = Color3.new(0, 0, 0)
    jumpLabel.Parent = jumpButton
    
    -- Enhanced shadow effect
    local shadow = Instance.new("Frame")
    shadow.Name = "Shadow"
    shadow.Size = UDim2.new(1, 12, 1, 12)
    shadow.Position = UDim2.new(0, 6, 0, 6)
    shadow.BackgroundColor3 = Color3.new(0, 0, 0)
    shadow.BackgroundTransparency = 0.7
    shadow.BorderSizePixel = 0
    shadow.ZIndex = jumpButton.ZIndex - 1
    shadow.Parent = jumpButton
    
    local shadowCorner = Instance.new("UICorner")
    shadowCorner.CornerRadius = UDim.new(0, 35)
    shadowCorner.Parent = shadow
    
    -- Glow effect for visibility
    local glow = Instance.new("Frame")
    glow.Name = "Glow"
    glow.Size = UDim2.new(1, 30, 1, 30)
    glow.Position = UDim2.new(0, -15, 0, -15)
    glow.BackgroundColor3 = Color3.fromRGB(255, 150, 150)
    glow.BackgroundTransparency = 0.85
    glow.BorderSizePixel = 0
    glow.ZIndex = jumpButton.ZIndex - 2
    glow.Parent = jumpButton
    
    local glowCorner = Instance.new("UICorner")
    glowCorner.CornerRadius = UDim.new(0, 50)
    glowCorner.Parent = glow
    
    -- Touch-optimized jump functionality
    local isJumping = false
    local touchConnection = nil
    
    -- Handle both mouse and touch input
    jumpButton.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or 
           input.UserInputType == Enum.UserInputType.Touch then
            
            if isJumping then return end
            isJumping = true
            
            -- Make player jump
            local character = player.Character
            if character and character:FindFirstChild("Humanoid") then
                character.Humanoid.Jump = true
            end
            
            -- Enhanced visual feedback
            self:AnimateButtonPress(jumpButton, 1.1, 0.95)
            
            -- Haptic feedback simulation
            self:TriggerHapticFeedback(jumpButton)
            
            -- Prevent spam jumping
            spawn(function()
                wait(0.3)
                isJumping = false
            end)
        end
    end)
    
    print("📱 Large jump button created")
end

function EnhancedMobileUIController:CreateLargeColorSwitchButton(parent)
    -- Extra large color switch button (bottom left corner)
    local colorButton = Instance.new("TextButton")
    colorButton.Name = "LargeColorSwitchButton"
    colorButton.Size = UDim2.new(0, 160, 0, 160) -- Extra large
    colorButton.Position = UDim2.new(0, 20, 1, -180) -- Bottom left corner
    colorButton.BackgroundColor3 = Color3.fromRGB(100, 150, 255)
    colorButton.BorderSizePixel = 0
    colorButton.Text = ""
    colorButton.AutoButtonColor = false
    colorButton.Parent = parent
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 35)
    corner.Parent = colorButton
    
    -- Color switch icon
    local colorIcon = Instance.new("TextLabel")
    colorIcon.Name = "ColorIcon"
    colorIcon.Size = UDim2.new(1, 0, 0.6, 0)
    colorIcon.Position = UDim2.new(0, 0, 0, 0)
    colorIcon.BackgroundTransparency = 1
    colorIcon.Text = "🎨"
    colorIcon.TextColor3 = Color3.new(1, 1, 1)
    colorIcon.TextSize = 64
    colorIcon.Font = Enum.Font.GothamBold
    colorIcon.TextStrokeTransparency = 0
    colorIcon.TextStrokeColor3 = Color3.new(0, 0, 0)
    colorIcon.Parent = colorButton
    
    -- Color label
    local colorLabel = Instance.new("TextLabel")
    colorLabel.Name = "ColorLabel"
    colorLabel.Size = UDim2.new(1, 0, 0.4, 0)
    colorLabel.Position = UDim2.new(0, 0, 0.6, 0)
    colorLabel.BackgroundTransparency = 1
    colorLabel.Text = "COLOR"
    colorLabel.TextColor3 = Color3.new(1, 1, 1)
    colorLabel.TextSize = 18
    colorLabel.Font = Enum.Font.GothamBold
    colorLabel.TextStrokeTransparency = 0
    colorLabel.TextStrokeColor3 = Color3.new(0, 0, 0)
    colorLabel.Parent = colorButton
    
    -- Shadow and glow effects
    local shadow = Instance.new("Frame")
    shadow.Name = "Shadow"
    shadow.Size = UDim2.new(1, 12, 1, 12)
    shadow.Position = UDim2.new(0, 6, 0, 6)
    shadow.BackgroundColor3 = Color3.new(0, 0, 0)
    shadow.BackgroundTransparency = 0.7
    shadow.BorderSizePixel = 0
    shadow.ZIndex = colorButton.ZIndex - 1
    shadow.Parent = colorButton
    
    local shadowCorner = Instance.new("UICorner")
    shadowCorner.CornerRadius = UDim.new(0, 35)
    shadowCorner.Parent = shadow
    
    -- Touch functionality for color switching
    colorButton.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or 
           input.UserInputType == Enum.UserInputType.Touch then
            
            -- Send color switch request
            RemoteEvents.PlayerColorChanged:FireServer()
            
            -- Visual feedback
            self:AnimateButtonPress(colorButton, 1.1, 0.95)
            self:TriggerHapticFeedback(colorButton)
            
            -- Color change animation
            local colorTween = TweenService:Create(colorIcon, TweenInfo.new(0.3, Enum.EasingStyle.Bounce), {
                Rotation = colorIcon.Rotation + 360
            })
            colorTween:Play()
        end
    end)
    
    print("📱 Large color switch button created")
end

function EnhancedMobileUIController:CreateLargePauseButton(parent)
    -- Large pause button (top right corner)
    local pauseButton = Instance.new("TextButton")
    pauseButton.Name = "LargePauseButton"
    pauseButton.Size = UDim2.new(0, 100, 0, 100) -- Large but not overwhelming
    pauseButton.Position = UDim2.new(1, -120, 0, 20) -- Top right corner
    pauseButton.BackgroundColor3 = Color3.fromRGB(80, 80, 80)
    pauseButton.BorderSizePixel = 0
    pauseButton.Text = ""
    pauseButton.AutoButtonColor = false
    pauseButton.Parent = parent
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 20)
    corner.Parent = pauseButton
    
    -- Pause icon
    local pauseIcon = Instance.new("TextLabel")
    pauseIcon.Name = "PauseIcon"
    pauseIcon.Size = UDim2.new(1, 0, 1, 0)
    pauseIcon.Position = UDim2.new(0, 0, 0, 0)
    pauseIcon.BackgroundTransparency = 1
    pauseIcon.Text = "⏸️"
    pauseIcon.TextColor3 = Color3.new(1, 1, 1)
    pauseIcon.TextSize = 40
    pauseIcon.Font = Enum.Font.GothamBold
    pauseIcon.Parent = pauseButton
    
    -- Touch functionality
    pauseButton.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or 
           input.UserInputType == Enum.UserInputType.Touch then
            
            RemoteEvents.PauseGame:FireServer()
            self:AnimateButtonPress(pauseButton, 1.05, 0.95)
        end
    end)
    
    print("📱 Large pause button created")
end

function EnhancedMobileUIController:CreateMobileGameHUD(parent)
    -- Enhanced mobile HUD positioned at top for easy viewing
    local hudContainer = Instance.new("Frame")
    hudContainer.Name = "MobileHUD"
    hudContainer.Size = UDim2.new(1, -40, 0, 80) -- Full width with margins
    hudContainer.Position = UDim2.new(0, 20, 0, 20) -- Top of screen
    hudContainer.BackgroundTransparency = 1
    hudContainer.Parent = parent
    
    -- Score display (top left)
    local scoreFrame = Instance.new("Frame")
    scoreFrame.Name = "ScoreFrame"
    scoreFrame.Size = UDim2.new(0, 200, 1, 0)
    scoreFrame.Position = UDim2.new(0, 0, 0, 0)
    scoreFrame.BackgroundColor3 = Color3.fromRGB(40, 40, 50)
    scoreFrame.BackgroundTransparency = 0.3
    scoreFrame.BorderSizePixel = 0
    scoreFrame.Parent = hudContainer
    
    local scoreCorner = Instance.new("UICorner")
    scoreCorner.CornerRadius = UDim.new(0, 15)
    scoreCorner.Parent = scoreFrame
    
    local scoreLabel = Instance.new("TextLabel")
    scoreLabel.Name = "ScoreLabel"
    scoreLabel.Size = UDim2.new(1, -20, 1, 0)
    scoreLabel.Position = UDim2.new(0, 10, 0, 0)
    scoreLabel.BackgroundTransparency = 1
    scoreLabel.Text = "SCORE: 0"
    scoreLabel.TextColor3 = Color3.new(1, 1, 1)
    scoreLabel.TextSize = 24 -- Larger text for mobile
    scoreLabel.Font = Enum.Font.GothamBold
    scoreLabel.TextXAlignment = Enum.TextXAlignment.Left
    scoreLabel.TextStrokeTransparency = 0
    scoreLabel.TextStrokeColor3 = Color3.new(0, 0, 0)
    scoreLabel.Parent = scoreFrame
    
    -- Coins display (top center)
    local coinsFrame = Instance.new("Frame")
    coinsFrame.Name = "CoinsFrame"
    coinsFrame.Size = UDim2.new(0, 180, 1, 0)
    coinsFrame.Position = UDim2.new(0.5, -90, 0, 0)
    coinsFrame.BackgroundColor3 = Color3.fromRGB(255, 215, 0)
    coinsFrame.BackgroundTransparency = 0.2
    coinsFrame.BorderSizePixel = 0
    coinsFrame.Parent = hudContainer
    
    local coinsCorner = Instance.new("UICorner")
    coinsCorner.CornerRadius = UDim.new(0, 15)
    coinsCorner.Parent = coinsFrame
    
    local coinsLabel = Instance.new("TextLabel")
    coinsLabel.Name = "CoinsLabel"
    coinsLabel.Size = UDim2.new(1, -20, 1, 0)
    coinsLabel.Position = UDim2.new(0, 10, 0, 0)
    coinsLabel.BackgroundTransparency = 1
    coinsLabel.Text = "💰 0"
    coinsLabel.TextColor3 = Color3.new(0, 0, 0)
    coinsLabel.TextSize = 24
    coinsLabel.Font = Enum.Font.GothamBold
    coinsLabel.TextStrokeTransparency = 0
    coinsLabel.TextStrokeColor3 = Color3.new(1, 1, 1)
    coinsLabel.Parent = coinsFrame
    
    print("📱 Mobile game HUD created")
end

function EnhancedMobileUIController:CreateMobileHubInterface()
    -- Enhanced hub interface for mobile with larger, corner-positioned elements
    mobileHubGui = Instance.new("ScreenGui")
    mobileHubGui.Name = "EnhancedMobileHubGui"
    mobileHubGui.ResetOnSpawn = false
    mobileHubGui.IgnoreGuiInset = true
    mobileHubGui.Enabled = false
    mobileHubGui.Parent = playerGui
    
    local hubContainer = Instance.new("Frame")
    hubContainer.Name = "HubContainer"
    hubContainer.Size = UDim2.new(1, 0, 1, 0)
    hubContainer.BackgroundTransparency = 1
    hubContainer.Parent = mobileHubGui
    
    -- Create mobile-optimized hub buttons
    self:CreateMobileShopButton(hubContainer)
    self:CreateMobileUpgradeButton(hubContainer)
    self:CreateMobileCrateButton(hubContainer)
    self:CreateMobileSettingsButton(hubContainer)
    self:CreateMobilePremiumButton(hubContainer)
    
    print("📱 Mobile hub interface created")
end

function EnhancedMobileUIController:CreateMobileShopButton(parent)
    -- Large shop button (bottom left of hub)
    local shopButton = Instance.new("TextButton")
    shopButton.Name = "MobileShopButton"
    shopButton.Size = UDim2.new(0, 140, 0, 140)
    shopButton.Position = UDim2.new(0, 20, 1, -160)
    shopButton.BackgroundColor3 = Color3.fromRGB(100, 200, 100)
    shopButton.BorderSizePixel = 0
    shopButton.Text = ""
    shopButton.AutoButtonColor = false
    shopButton.Parent = parent
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 25)
    corner.Parent = shopButton
    
    -- Shop icon and label
    local shopIcon = Instance.new("TextLabel")
    shopIcon.Size = UDim2.new(1, 0, 0.6, 0)
    shopIcon.Position = UDim2.new(0, 0, 0, 0)
    shopIcon.BackgroundTransparency = 1
    shopIcon.Text = "🛍️"
    shopIcon.TextSize = 60
    shopIcon.Font = Enum.Font.GothamBold
    shopIcon.Parent = shopButton
    
    local shopLabel = Instance.new("TextLabel")
    shopLabel.Size = UDim2.new(1, 0, 0.4, 0)
    shopLabel.Position = UDim2.new(0, 0, 0.6, 0)
    shopLabel.BackgroundTransparency = 1
    shopLabel.Text = "SHOP"
    shopLabel.TextColor3 = Color3.new(1, 1, 1)
    shopLabel.TextSize = 20
    shopLabel.Font = Enum.Font.GothamBold
    shopLabel.TextStrokeTransparency = 0
    shopLabel.TextStrokeColor3 = Color3.new(0, 0, 0)
    shopLabel.Parent = shopButton
    
    shopButton.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or 
           input.UserInputType == Enum.UserInputType.Touch then
            RemoteEvents.OpenShop:FireServer()
            self:AnimateButtonPress(shopButton, 1.1, 0.9)
        end
    end)
end

function EnhancedMobileUIController:CreateMobileUpgradeButton(parent)
    -- Large upgrade button 
    local upgradeButton = Instance.new("TextButton")
    upgradeButton.Name = "MobileUpgradeButton"
    upgradeButton.Size = UDim2.new(0, 140, 0, 140)
    upgradeButton.Position = UDim2.new(0, 180, 1, -160)
    upgradeButton.BackgroundColor3 = Color3.fromRGB(200, 100, 200)
    upgradeButton.BorderSizePixel = 0
    upgradeButton.Text = ""
    upgradeButton.AutoButtonColor = false
    upgradeButton.Parent = parent
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 25)
    corner.Parent = upgradeButton
    
    local upgradeIcon = Instance.new("TextLabel")
    upgradeIcon.Size = UDim2.new(1, 0, 0.6, 0)
    upgradeIcon.BackgroundTransparency = 1
    upgradeIcon.Text = "⚡"
    upgradeIcon.TextSize = 60
    upgradeIcon.Font = Enum.Font.GothamBold
    upgradeIcon.Parent = upgradeButton
    
    local upgradeLabel = Instance.new("TextLabel")
    upgradeLabel.Size = UDim2.new(1, 0, 0.4, 0)
    upgradeLabel.Position = UDim2.new(0, 0, 0.6, 0)
    upgradeLabel.BackgroundTransparency = 1
    upgradeLabel.Text = "UPGRADES"
    upgradeLabel.TextColor3 = Color3.new(1, 1, 1)
    upgradeLabel.TextSize = 16
    upgradeLabel.Font = Enum.Font.GothamBold
    upgradeLabel.TextStrokeTransparency = 0
    upgradeLabel.TextStrokeColor3 = Color3.new(0, 0, 0)
    upgradeLabel.Parent = upgradeButton
    
    upgradeButton.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or 
           input.UserInputType == Enum.UserInputType.Touch then
            RemoteEvents.OpenUpgradeShop:FireServer()
            self:AnimateButtonPress(upgradeButton, 1.1, 0.9)
        end
    end)
end

function EnhancedMobileUIController:CreateMobileCrateButton(parent)
    -- Large crate button
    local crateButton = Instance.new("TextButton")
    crateButton.Name = "MobileCrateButton"
    crateButton.Size = UDim2.new(0, 140, 0, 140)
    crateButton.Position = UDim2.new(1, -160, 1, -160)
    crateButton.BackgroundColor3 = Color3.fromRGB(200, 150, 50)
    crateButton.BorderSizePixel = 0
    crateButton.Text = ""
    crateButton.AutoButtonColor = false
    crateButton.Parent = parent
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 25)
    corner.Parent = crateButton
    
    local crateIcon = Instance.new("TextLabel")
    crateIcon.Size = UDim2.new(1, 0, 0.6, 0)
    crateIcon.BackgroundTransparency = 1
    crateIcon.Text = "📦"
    crateIcon.TextSize = 60
    crateIcon.Font = Enum.Font.GothamBold
    crateIcon.Parent = crateButton
    
    local crateLabel = Instance.new("TextLabel")
    crateLabel.Size = UDim2.new(1, 0, 0.4, 0)
    crateLabel.Position = UDim2.new(0, 0, 0.6, 0)
    crateLabel.BackgroundTransparency = 1
    crateLabel.Text = "CRATES"
    crateLabel.TextColor3 = Color3.new(1, 1, 1)
    crateLabel.TextSize = 18
    crateLabel.Font = Enum.Font.GothamBold
    crateLabel.TextStrokeTransparency = 0
    crateLabel.TextStrokeColor3 = Color3.new(0, 0, 0)
    crateLabel.Parent = crateButton
    
    crateButton.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or 
           input.UserInputType == Enum.UserInputType.Touch then
            RemoteEvents.OpenCrateMachine:FireServer()
            self:AnimateButtonPress(crateButton, 1.1, 0.9)
        end
    end)
end

function EnhancedMobileUIController:CreateMobileSettingsButton(parent)
    -- Settings button (top left)
    local settingsButton = Instance.new("TextButton")
    settingsButton.Name = "MobileSettingsButton"
    settingsButton.Size = UDim2.new(0, 80, 0, 80)
    settingsButton.Position = UDim2.new(0, 20, 0, 20)
    settingsButton.BackgroundColor3 = Color3.fromRGB(80, 80, 80)
    settingsButton.BorderSizePixel = 0
    settingsButton.Text = "⚙️"
    settingsButton.TextColor3 = Color3.new(1, 1, 1)
    settingsButton.TextSize = 35
    settingsButton.Font = Enum.Font.GothamBold
    settingsButton.AutoButtonColor = false
    settingsButton.Parent = parent
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 15)
    corner.Parent = settingsButton
    
    settingsButton.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or 
           input.UserInputType == Enum.UserInputType.Touch then
            RemoteEvents.OpenMobileSettings:FireServer()
            self:AnimateButtonPress(settingsButton, 1.05, 0.95)
        end
    end)
end

function EnhancedMobileUIController:CreateMobilePremiumButton(parent)
    -- Premium shop button (top right)
    local premiumButton = Instance.new("TextButton")
    premiumButton.Name = "MobilePremiumButton"
    premiumButton.Size = UDim2.new(0, 120, 0, 80)
    premiumButton.Position = UDim2.new(1, -140, 0, 20)
    premiumButton.BackgroundColor3 = Color3.fromRGB(255, 215, 0)
    premiumButton.BorderSizePixel = 0
    premiumButton.Text = "💎 VIP"
    premiumButton.TextColor3 = Color3.new(0, 0, 0)
    premiumButton.TextSize = 20
    premiumButton.Font = Enum.Font.GothamBold
    premiumButton.AutoButtonColor = false
    premiumButton.Parent = parent
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 15)
    corner.Parent = premiumButton
    
    -- Glow effect
    local glow = Instance.new("Frame")
    glow.Size = UDim2.new(1, 6, 1, 6)
    glow.Position = UDim2.new(0, -3, 0, -3)
    glow.BackgroundColor3 = Color3.fromRGB(255, 215, 0)
    glow.BackgroundTransparency = 0.7
    glow.BorderSizePixel = 0
    glow.ZIndex = premiumButton.ZIndex - 1
    glow.Parent = premiumButton
    
    local glowCorner = Instance.new("UICorner")
    glowCorner.CornerRadius = UDim.new(0, 18)
    glowCorner.Parent = glow
    
    premiumButton.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or 
           input.UserInputType == Enum.UserInputType.Touch then
            RemoteEvents.OpenMonetizationShop:FireServer()
            self:AnimateButtonPress(premiumButton, 1.05, 0.95)
        end
    end)
end

function EnhancedMobileUIController:AnimateButtonPress(button, scaleUp, scaleDown)
    -- Enhanced button press animation
    scaleUp = scaleUp or 1.1
    scaleDown = scaleDown or 0.9
    
    local originalSize = button.Size
    
    -- Scale up
    local scaleUpTween = TweenService:Create(button, TweenInfo.new(0.1, Enum.EasingStyle.Quad), {
        Size = UDim2.new(originalSize.X.Scale * scaleUp, originalSize.X.Offset * scaleUp, 
                        originalSize.Y.Scale * scaleUp, originalSize.Y.Offset * scaleUp)
    })
    
    scaleUpTween:Play()
    scaleUpTween.Completed:Connect(function()
        -- Scale down
        local scaleDownTween = TweenService:Create(button, TweenInfo.new(0.1, Enum.EasingStyle.Quad), {
            Size = UDim2.new(originalSize.X.Scale * scaleDown, originalSize.X.Offset * scaleDown,
                            originalSize.Y.Scale * scaleDown, originalSize.Y.Offset * scaleDown)
        })
        
        scaleDownTween:Play()
        scaleDownTween.Completed:Connect(function()
            -- Return to original size
            local returnTween = TweenService:Create(button, TweenInfo.new(0.1, Enum.EasingStyle.Quad), {
                Size = originalSize
            })
            returnTween:Play()
        end)
    end)
end

function EnhancedMobileUIController:TriggerHapticFeedback(button)
    -- Simulate haptic feedback with visual effects
    local originalColor = button.BackgroundColor3
    
    -- Brief color flash
    local flashTween = TweenService:Create(button, TweenInfo.new(0.1), {
        BackgroundColor3 = Color3.new(1, 1, 1)
    })
    
    flashTween:Play()
    flashTween.Completed:Connect(function()
        local returnTween = TweenService:Create(button, TweenInfo.new(0.1), {
            BackgroundColor3 = originalColor
        })
        returnTween:Play()
    end)
end

function EnhancedMobileUIController:OptimizeExistingMenus()
    -- Optimize existing menus for mobile touch interface
    spawn(function()
        wait(2) -- Wait for other controllers to initialize
        
        -- Find and optimize shop menus
        self:OptimizeShopMenuForMobile()
        self:OptimizeUpgradeMenuForMobile()
        self:OptimizeCrateMenuForMobile()
    end)
end

function EnhancedMobileUIController:OptimizeShopMenuForMobile()
    -- Monitor for shop GUI creation and optimize
    local function optimizeShopGUI(gui)
        if not gui:FindFirstChild("ShopFrame") then return end
        
        local shopFrame = gui.ShopFrame
        
        -- Enlarge shop items for touch
        for _, item in pairs(shopFrame:GetDescendants()) do
            if item:IsA("TextButton") and item.Name:find("Item") then
                -- Increase button size
                item.Size = UDim2.new(item.Size.X.Scale, item.Size.X.Offset + 20, 
                                     item.Size.Y.Scale, item.Size.Y.Offset + 20)
                
                -- Increase text size
                if item:FindFirstChild("TextLabel") then
                    item.TextLabel.TextSize = math.max(item.TextLabel.TextSize * 1.3, 18)
                end
            end
        end
        
        print("📱 Shop menu optimized for mobile")
    end
    
    -- Monitor for shop GUI
    playerGui.ChildAdded:Connect(function(child)
        if child.Name == "ShopUI" then
            optimizeShopGUI(child)
        end
    end)
end

function EnhancedMobileUIController:OptimizeUpgradeMenuForMobile()
    -- Similar optimization for upgrade menu
    local function optimizeUpgradeGUI(gui)
        -- Enlarge upgrade buttons and text
        for _, item in pairs(gui:GetDescendants()) do
            if item:IsA("TextButton") and (item.Name:find("Upgrade") or item.Name:find("Button")) then
                item.Size = UDim2.new(item.Size.X.Scale, item.Size.X.Offset + 15,
                                     item.Size.Y.Scale, item.Size.Y.Offset + 15)
                
                if item.TextSize then
                    item.TextSize = math.max(item.TextSize * 1.2, 16)
                end
            end
        end
        
        print("📱 Upgrade menu optimized for mobile")
    end
    
    playerGui.ChildAdded:Connect(function(child)
        if child.Name:find("Upgrade") then
            optimizeUpgradeGUI(child)
        end
    end)
end

function EnhancedMobileUIController:OptimizeCrateMenuForMobile()
    -- Optimize crate interface for mobile
    local function optimizeCrateGUI(gui)
        for _, item in pairs(gui:GetDescendants()) do
            if item:IsA("TextButton") then
                -- Enlarge crate interaction buttons
                item.Size = UDim2.new(item.Size.X.Scale, item.Size.X.Offset + 25,
                                     item.Size.Y.Scale, item.Size.Y.Offset + 25)
                
                if item.TextSize then
                    item.TextSize = math.max(item.TextSize * 1.3, 20)
                end
            end
        end
        
        print("📱 Crate menu optimized for mobile")
    end
    
    playerGui.ChildAdded:Connect(function(child)
        if child.Name:find("Crate") then
            optimizeCrateGUI(child)
        end
    end)
end

function EnhancedMobileUIController:SwitchToGameMode()
    if not isMobile then return end
    
    isInGame = true
    
    if mobileHubGui then
        mobileHubGui.Enabled = false
    end
    
    if mobileGameGui then
        mobileGameGui.Enabled = true
    end
    
    print("📱 Switched to mobile game mode")
end

function EnhancedMobileUIController:SwitchToHubMode()
    if not isMobile then return end
    
    isInGame = false
    
    if mobileGameGui then
        mobileGameGui.Enabled = false
    end
    
    if mobileHubGui then
        mobileHubGui.Enabled = true
    end
    
    print("📱 Switched to mobile hub mode")
end

function EnhancedMobileUIController:Initialize()
    print("📱 EnhancedMobileUIController initializing...")
    
    -- Detect mobile device
    if not self:DetectMobile() then
        print("📱 Not a mobile device, skipping mobile UI")
        return
    end
    
    -- Create mobile interfaces
    self:CreateLargeGameControls()
    self:CreateMobileHubInterface()
    
    -- Optimize existing menus
    self:OptimizeExistingMenus()
    
    -- Listen for mode switches
    RemoteEvents.SwitchToGameMode.OnClientEvent:Connect(function()
        self:SwitchToGameMode()
    end)
    
    RemoteEvents.SwitchToHubMode.OnClientEvent:Connect(function()
        self:SwitchToHubMode()
    end)
    
    -- Start in hub mode
    self:SwitchToHubMode()
    
    print("✅ EnhancedMobileUIController initialized for mobile device!")
end

-- Auto-initialize
EnhancedMobileUIController:Initialize()

return EnhancedMobileUIController
