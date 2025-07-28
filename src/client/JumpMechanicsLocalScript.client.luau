-- JumpMechanicsLocalScript.client.luau
-- Complete jump mechanics implementation for Color Rush with mobile support

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local SoundService = game:GetService("SoundService")
local ContextActionService = game:GetService("ContextActionService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- Safe require for RemoteEvents using SafeRequire utility
local SafeRequire = require(ReplicatedStorage.Shared.utils.SafeRequire)
local RemoteEvents = SafeRequire.require(ReplicatedStorage.Shared.modules.RemoteEvents)

if not RemoteEvents then
    warn("❌ Failed to load RemoteEvents")
    return
end

-- Jump state management
local JumpMechanics = {
    -- Player state
    canJump = true,
    isJumping = false,
    isInAir = false,
    lastJumpTime = 0,
    jumpCooldown = 0.5,
    
    -- Mobile detection
    isMobile = false,
    
    -- UI elements
    mobileJumpButton = nil,
    
    -- Connections
    connections = {},
    
    -- Effects
    jumpEffectsEnabled = true,
    soundEffectsEnabled = true
}

-- Initialize the jump mechanics system
function JumpMechanics:Init()
    print("🦘 Jump Mechanics initializing...")
    
    -- Detect mobile platform
    self:DetectMobile()
    
    -- Setup input handling
    self:SetupInputHandling()
    
    -- Setup character monitoring
    self:SetupCharacterMonitoring()
    
    -- Setup remote events
    self:SetupRemoteEvents()
    
    -- Create mobile UI if needed
    if self.isMobile then
        self:CreateMobileJumpButton()
    end
    
    print("✅ Jump Mechanics initialized!")
end

function JumpMechanics:DetectMobile()
    -- Enhanced mobile detection
    local hasTouch = UserInputService.TouchEnabled
    local hasKeyboard = UserInputService.KeyboardEnabled
    local hasMouse = UserInputService.MouseEnabled
    
    -- Consider mobile if touch enabled and no physical keyboard/mouse
    self.isMobile = hasTouch and not (hasKeyboard and hasMouse)
    
    print(string.format("📱 Platform detected: %s", self.isMobile and "Mobile" or "Desktop"))
end

function JumpMechanics:SetupInputHandling()
    -- Desktop: Space bar input
    self.connections.keyboardInput = UserInputService.InputBegan:Connect(function(input, gameProcessed)
        if gameProcessed then return end
        
        if input.KeyCode == Enum.KeyCode.Space then
            self:AttemptJump()
        end
    end)
    
    -- Mobile: Context action for touch button
    if self.isMobile then
        ContextActionService:BindAction(
            "JumpAction",
            function(actionName, inputState, inputObject)
                if inputState == Enum.UserInputState.Begin then
                    self:AttemptJump()
                end
            end,
            true, -- Create touch button
            Enum.KeyCode.Space -- Also bind to space for testing
        )
        
        -- Customize the touch button
        spawn(function()
            wait(0.1) -- Wait for button creation
            self:CustomizeTouchButton()
        end)
    end
    
    print("🎮 Input handling setup complete")
end

function JumpMechanics:CustomizeTouchButton()
    local contextActionGui = playerGui:FindFirstChild("ContextActionGui")
    if not contextActionGui then return end
    
    local jumpActionFrame = contextActionGui:FindFirstChild("JumpActionFrame")
    if not jumpActionFrame then return end
    
    local jumpButton = jumpActionFrame:FindFirstChild("JumpActionButton")
    if not jumpButton then return end
    
    -- Enhance the button appearance
    jumpButton.Size = UDim2.new(0, 80, 0, 80)
    jumpButton.Position = UDim2.new(1, -100, 1, -100)
    jumpButton.BackgroundColor3 = Color3.fromRGB(100, 200, 100)
    jumpButton.Text = "⬆️"
    jumpButton.TextSize = 32
    jumpButton.TextColor3 = Color3.new(1, 1, 1)
    jumpButton.Font = Enum.Font.SourceSansBold
    
    -- Add corner radius
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 15)
    corner.Parent = jumpButton
    
    print("📱 Touch button customized")
end

function JumpMechanics:CreateMobileJumpButton()
    -- Create dedicated mobile jump button
    local jumpGui = Instance.new("ScreenGui")
    jumpGui.Name = "JumpMechanicsGui"
    jumpGui.ResetOnSpawn = false
    jumpGui.Parent = playerGui
    
    self.mobileJumpButton = Instance.new("TextButton")
    self.mobileJumpButton.Name = "MobileJumpButton"
    self.mobileJumpButton.Size = UDim2.new(0, 100, 0, 100)
    self.mobileJumpButton.Position = UDim2.new(1, -120, 1, -120)
    self.mobileJumpButton.BackgroundColor3 = Color3.fromRGB(85, 170, 255)
    self.mobileJumpButton.BorderSizePixel = 0
    self.mobileJumpButton.Text = ""
    self.mobileJumpButton.AutoButtonColor = false
    self.mobileJumpButton.Parent = jumpGui
    
    -- Add modern styling
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 25)
    corner.Parent = self.mobileJumpButton
    
    -- Add shadow
    local shadow = Instance.new("Frame")
    shadow.Name = "Shadow"
    shadow.Size = UDim2.new(1, 6, 1, 6)
    shadow.Position = UDim2.new(0, 3, 0, 3)
    shadow.BackgroundColor3 = Color3.new(0, 0, 0)
    shadow.BackgroundTransparency = 0.7
    shadow.BorderSizePixel = 0
    shadow.ZIndex = self.mobileJumpButton.ZIndex - 1
    shadow.Parent = self.mobileJumpButton
    
    local shadowCorner = Instance.new("UICorner")
    shadowCorner.CornerRadius = UDim.new(0, 25)
    shadowCorner.Parent = shadow
    
    -- Add icon
    local icon = Instance.new("TextLabel")
    icon.Name = "Icon"
    icon.Size = UDim2.new(0.6, 0, 0.6, 0)
    icon.Position = UDim2.new(0.2, 0, 0.1, 0)
    icon.BackgroundTransparency = 1
    icon.Text = "⬆️"
    icon.TextColor3 = Color3.new(1, 1, 1)
    icon.TextScaled = true
    icon.Font = Enum.Font.SourceSansBold
    icon.TextStrokeTransparency = 0
    icon.TextStrokeColor3 = Color3.new(0, 0, 0)
    icon.Parent = self.mobileJumpButton
    
    -- Add label
    local label = Instance.new("TextLabel")
    label.Name = "Label"
    label.Size = UDim2.new(1, 0, 0.3, 0)
    label.Position = UDim2.new(0, 0, 0.7, 0)
    label.BackgroundTransparency = 1
    label.Text = "JUMP"
    label.TextColor3 = Color3.new(1, 1, 1)
    label.TextScaled = true
    label.Font = Enum.Font.SourceSansBold
    label.TextStrokeTransparency = 0
    label.TextStrokeColor3 = Color3.new(0, 0, 0)
    label.Parent = self.mobileJumpButton
    
    -- Button functionality
    self.mobileJumpButton.MouseButton1Click:Connect(function()
        self:AttemptJump()
    end)
    
    -- Visual feedback
    self:SetupButtonFeedback(self.mobileJumpButton)
    
    print("📱 Mobile jump button created")
end

function JumpMechanics:SetupButtonFeedback(button)
    button.MouseButton1Down:Connect(function()
        self:AnimateButtonPress(button)
    end)
    
    button.MouseButton1Up:Connect(function()
        self:AnimateButtonRelease(button)
    end)
end

function JumpMechanics:AnimateButtonPress(button)
    local pressTween = TweenService:Create(
        button,
        TweenInfo.new(0.1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
        {Size = UDim2.new(0, 90, 0, 90)}
    )
    pressTween:Play()
end

function JumpMechanics:AnimateButtonRelease(button)
    local releaseTween = TweenService:Create(
        button,
        TweenInfo.new(0.1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
        {Size = UDim2.new(0, 100, 0, 100)}
    )
    releaseTween:Play()
end

function JumpMechanics:SetupCharacterMonitoring()
    local function monitorCharacter(character)
        if not character then return end
        
        local humanoid = character:WaitForChild("Humanoid")
        local humanoidRootPart = character:WaitForChild("HumanoidRootPart")
        
        -- Monitor humanoid state changes
        self.connections.stateChanged = humanoid.StateChanged:Connect(function(oldState, newState)
            if newState == Enum.HumanoidStateType.Jumping then
                self.isJumping = true
                self.isInAir = true
                self.canJump = false
                
                if self.jumpEffectsEnabled then
                    self:PlayJumpEffects(character)
                end
                
            elseif newState == Enum.HumanoidStateType.Landed then
                self.isJumping = false
                self.isInAir = false
                
                if self.jumpEffectsEnabled then
                    self:PlayLandingEffects(character)
                end
                
                -- Start cooldown
                spawn(function()
                    wait(self.jumpCooldown)
                    self.canJump = true
                end)
                
            elseif newState == Enum.HumanoidStateType.Freefall then
                self.isInAir = true
                self.canJump = false
            end
        end)
        
        -- Ground detection using raycast
        self.connections.groundCheck = RunService.Heartbeat:Connect(function()
            if not character.Parent then return end
            self:CheckGroundContact(humanoidRootPart)
        end)
    end
    
    -- Monitor current and future characters
    if player.Character then
        monitorCharacter(player.Character)
    end
    
    self.connections.characterAdded = player.CharacterAdded:Connect(monitorCharacter)
    
    print("👁️ Character monitoring setup complete")
end

function JumpMechanics:CheckGroundContact(humanoidRootPart)
    local rayOrigin = humanoidRootPart.Position
    local rayDirection = Vector3.new(0, -5, 0)
    
    local raycastParams = RaycastParams.new()
    raycastParams.FilterType = Enum.RaycastFilterType.Blacklist
    raycastParams.FilterDescendantsInstances = {player.Character}
    
    local raycastResult = workspace:Raycast(rayOrigin, rayDirection, raycastParams)
    
    if raycastResult and self.isInAir and not self.isJumping then
        self.isInAir = false
        self.canJump = true
    elseif not raycastResult and not self.isInAir then
        self.isInAir = true
        self.canJump = false
    end
end

function JumpMechanics:AttemptJump()
    -- Validate jump attempt
    if not self.canJump or self.isJumping or self.isInAir then
        return false
    end
    
    local currentTime = tick()
    if currentTime - self.lastJumpTime < self.jumpCooldown then
        return false
    end
    
    local character = player.Character
    if not character then return false end
    
    local humanoid = character:FindFirstChild("Humanoid")
    if not humanoid then return false end
    
    -- Execute jump
    humanoid.Jump = true
    self.lastJumpTime = currentTime
    
    -- Notify server
    if RemoteEvents.PlayerJumped then
        RemoteEvents.PlayerJumped:FireServer()
    end
    
    -- Visual feedback for mobile button
    if self.mobileJumpButton then
        self:FlashJumpButton()
    end
    
    print("🦘 Player jumped!")
    return true
end

function JumpMechanics:FlashJumpButton()
    if not self.mobileJumpButton then return end
    
    local originalColor = self.mobileJumpButton.BackgroundColor3
    self.mobileJumpButton.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    
    spawn(function()
        wait(0.1)
        self.mobileJumpButton.BackgroundColor3 = originalColor
    end)
end

function JumpMechanics:PlayJumpEffects(character)
    if not self.jumpEffectsEnabled then return end
    
    local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
    if not humanoidRootPart then return end
    
    -- Create particle effect
    local attachment = Instance.new("Attachment")
    attachment.Name = "JumpEffect"
    attachment.Parent = humanoidRootPart
    
    local particles = Instance.new("ParticleEmitter")
    particles.Name = "JumpParticles"
    particles.Texture = "rbxasset://textures/particles/sparkles_main.dds"
    particles.Color = ColorSequence.new(Color3.fromRGB(100, 200, 255))
    particles.Size = NumberSequence.new{
        NumberSequenceKeypoint.new(0, 0.5),
        NumberSequenceKeypoint.new(1, 0)
    }
    particles.Lifetime = NumberRange.new(0.3, 0.8)
    particles.Rate = 50
    particles.SpreadAngle = Vector2.new(45, 45)
    particles.Speed = NumberRange.new(5, 15)
    particles.Parent = attachment
    
    particles:Emit(20)
    
    -- Cleanup
    spawn(function()
        wait(2)
        if attachment and attachment.Parent then
            attachment:Destroy()
        end
    end)
    
    -- Play sound
    if self.soundEffectsEnabled then
        self:PlayJumpSound()
    end
end

function JumpMechanics:PlayLandingEffects(character)
    if not self.jumpEffectsEnabled then return end
    
    local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
    if not humanoidRootPart then return end
    
    -- Create dust effect
    local attachment = Instance.new("Attachment")
    attachment.Name = "LandingEffect"
    attachment.Position = Vector3.new(0, -2, 0)
    attachment.Parent = humanoidRootPart
    
    local dustParticles = Instance.new("ParticleEmitter")
    dustParticles.Name = "LandingDust"
    dustParticles.Texture = "rbxasset://textures/particles/smoke_main.dds"
    dustParticles.Color = ColorSequence.new(Color3.fromRGB(200, 180, 150))
    dustParticles.Size = NumberSequence.new{
        NumberSequenceKeypoint.new(0, 1),
        NumberSequenceKeypoint.new(1, 2)
    }
    dustParticles.Transparency = NumberSequence.new{
        NumberSequenceKeypoint.new(0, 0.3),
        NumberSequenceKeypoint.new(1, 1)
    }
    dustParticles.Lifetime = NumberRange.new(0.5, 1.2)
    dustParticles.Rate = 30
    dustParticles.SpreadAngle = Vector2.new(60, 60)
    dustParticles.Speed = NumberRange.new(3, 8)
    dustParticles.Parent = attachment
    
    dustParticles:Emit(15)
    
    -- Cleanup
    spawn(function()
        wait(2)
        if attachment and attachment.Parent then
            attachment:Destroy()
        end
    end)
    
    -- Play sound
    if self.soundEffectsEnabled then
        self:PlayLandingSound()
    end
end

function JumpMechanics:PlayJumpSound()
    local jumpSound = Instance.new("Sound")
    jumpSound.SoundId = "rbxasset://sounds/impact_water.mp3"
    jumpSound.Volume = 0.3
    jumpSound.Pitch = 1.5
    jumpSound.Parent = SoundService
    jumpSound:Play()
    
    jumpSound.Ended:Connect(function()
        jumpSound:Destroy()
    end)
end

function JumpMechanics:PlayLandingSound()
    local landingSound = Instance.new("Sound")
    landingSound.SoundId = "rbxasset://sounds/impact_dirt.mp3"
    landingSound.Volume = 0.4
    landingSound.Pitch = 1.2
    landingSound.Parent = SoundService
    landingSound:Play()
    
    landingSound.Ended:Connect(function()
        landingSound:Destroy()
    end)
end

function JumpMechanics:SetupRemoteEvents()
    if not RemoteEvents then return end
    
    -- Listen for server validation
    if RemoteEvents.JumpValidated then
        RemoteEvents.JumpValidated.OnClientEvent:Connect(function(isValid, reason)
            if not isValid then
                self.isJumping = false
                self.canJump = true
                print("⚠️ Jump rejected: " .. (reason or "Unknown"))
            end
        end)
    end
    
    -- Listen for state updates
    if RemoteEvents.UpdateJumpState then
        RemoteEvents.UpdateJumpState.OnClientEvent:Connect(function(newState)
            self.canJump = newState.canJump
            self.isJumping = newState.isJumping
            self.isInAir = newState.isInAir
        end)
    end
    
    print("📡 Remote events setup complete")
end

function JumpMechanics:GetState()
    return {
        canJump = self.canJump,
        isJumping = self.isJumping,
        isInAir = self.isInAir,
        lastJumpTime = self.lastJumpTime,
        isMobile = self.isMobile
    }
end

function JumpMechanics:SetEffectsEnabled(enabled)
    self.jumpEffectsEnabled = enabled
    self.soundEffectsEnabled = enabled
end

function JumpMechanics:Cleanup()
    for _, connection in pairs(self.connections) do
        if connection then
            connection:Disconnect()
        end
    end
    
    if self.mobileJumpButton then
        self.mobileJumpButton.Parent:Destroy()
    end
    
    ContextActionService:UnbindAction("JumpAction")
    
    print("🧹 Jump Mechanics cleaned up")
end

-- Initialize when script runs
JumpMechanics:Init()

-- Expose for debugging
_G.JumpMechanics = JumpMechanics
