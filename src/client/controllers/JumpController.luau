-- JumpController.luau
-- Comprehensive jump mechanics controller for Color Rush

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local SoundService = game:GetService("SoundService")

local player = Players.LocalPlayer
local RemoteEvents = require(ReplicatedStorage.Shared.modules.RemoteEvents)

local JumpController = {}

-- Jump state management
local jumpState = {
    canJump = true,
    isJumping = false,
    isInAir = false,
    jumpCooldown = 0.5, -- Prevent spam jumping
    lastJumpTime = 0
}

-- Input connections
local inputConnections = {}

function JumpController:Init()
    print("🦘 JumpController initializing...")
    
    -- Setup input handling
    self:SetupInputHandling()
    
    -- Setup state monitoring
    self:SetupStateMonitoring()
    
    -- Listen for server updates
    self:SetupRemoteEvents()
    
    print("✅ JumpController initialized!")
end

function JumpController:SetupInputHandling()
    -- Keyboard space bar input
    inputConnections.keyboardInput = UserInputService.InputBegan:Connect(function(input, gameProcessed)
        if gameProcessed then return end
        
        if input.KeyCode == Enum.KeyCode.Space then
            self:AttemptJump()
        end
    end)
    
    -- Mobile jump button handling (if mobile detected)
    if UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled then
        self:SetupMobileJumpButton()
    end
    
    print("🎮 Jump input handling setup complete")
end

function JumpController:SetupStateMonitoring()
    -- Monitor player character for air state
    local function monitorCharacter(character)
        if not character then return end
        
        local humanoid = character:WaitForChild("Humanoid")
        local humanoidRootPart = character:WaitForChild("HumanoidRootPart")
        
        -- Monitor jump state changes
        humanoid.StateChanged:Connect(function(oldState, newState)
            if newState == Enum.HumanoidStateType.Jumping then
                jumpState.isJumping = true
                jumpState.isInAir = true
                jumpState.canJump = false
                
                -- Notify server of jump
                RemoteEvents.PlayerJumped:FireServer()
                
                -- Play jump effects
                self:PlayJumpEffects(character)
                
            elseif newState == Enum.HumanoidStateType.Landed then
                jumpState.isJumping = false
                jumpState.isInAir = false
                
                -- Start cooldown before allowing next jump
                spawn(function()
                    wait(jumpState.jumpCooldown)
                    jumpState.canJump = true
                end)
                
                -- Play landing effects
                self:PlayLandingEffects(character)
                
            elseif newState == Enum.HumanoidStateType.Freefall then
                jumpState.isInAir = true
                jumpState.canJump = false
            end
        end)
        
        -- Monitor for ground contact using raycast
        local groundCheckConnection
        groundCheckConnection = RunService.Heartbeat:Connect(function()
            if not character.Parent then
                groundCheckConnection:Disconnect()
                return
            end
            
            self:CheckGroundContact(humanoidRootPart)
        end)
    end
    
    -- Monitor for character spawning
    if player.Character then
        monitorCharacter(player.Character)
    end
    
    player.CharacterAdded:Connect(monitorCharacter)
    
    print("👁️ Jump state monitoring setup complete")
end

function JumpController:CheckGroundContact(humanoidRootPart)
    -- Raycast downward to check if player is on ground
    local rayOrigin = humanoidRootPart.Position
    local rayDirection = Vector3.new(0, -5, 0) -- Cast 5 studs down
    
    local raycastParams = RaycastParams.new()
    raycastParams.FilterType = Enum.RaycastFilterType.Blacklist
    raycastParams.FilterDescendantsInstances = {player.Character}
    
    local raycastResult = workspace:Raycast(rayOrigin, rayDirection, raycastParams)
    
    if raycastResult then
        -- Player is on ground
        if jumpState.isInAir and not jumpState.isJumping then
            jumpState.isInAir = false
            jumpState.canJump = true
        end
    else
        -- Player is in air
        if not jumpState.isInAir then
            jumpState.isInAir = true
            jumpState.canJump = false
        end
    end
end

function JumpController:AttemptJump()
    -- Check if jump is allowed
    if not jumpState.canJump then
        return false
    end
    
    if jumpState.isJumping or jumpState.isInAir then
        return false
    end
    
    -- Check cooldown
    local currentTime = tick()
    if currentTime - jumpState.lastJumpTime < jumpState.jumpCooldown then
        return false
    end
    
    -- Get player character
    local character = player.Character
    if not character then return false end
    
    local humanoid = character:FindFirstChild("Humanoid")
    if not humanoid then return false end
    
    -- Execute jump
    humanoid.Jump = true
    jumpState.lastJumpTime = currentTime
    
    print("🦘 Player jumped!")
    return true
end

function JumpController:SetupMobileJumpButton()
    -- Create mobile jump button
    local playerGui = player:WaitForChild("PlayerGui")
    
    local jumpGui = Instance.new("ScreenGui")
    jumpGui.Name = "JumpControlGui"
    jumpGui.ResetOnSpawn = false
    jumpGui.Parent = playerGui
    
    local jumpButton = Instance.new("TextButton")
    jumpButton.Name = "JumpButton"
    jumpButton.Size = UDim2.new(0, 100, 0, 100)
    jumpButton.Position = UDim2.new(1, -120, 1, -120)
    jumpButton.BackgroundColor3 = Color3.fromRGB(100, 200, 100)
    jumpButton.BorderSizePixel = 0
    jumpButton.Text = "⬆️"
    jumpButton.TextSize = 48
    jumpButton.TextColor3 = Color3.new(1, 1, 1)
    jumpButton.Font = Enum.Font.SourceSansBold
    jumpButton.Parent = jumpGui
    
    -- Add corner radius
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 20)
    corner.Parent = jumpButton
    
    -- Button functionality
    jumpButton.MouseButton1Click:Connect(function()
        self:AttemptJump()
    end)
    
    -- Visual feedback
    jumpButton.MouseButton1Down:Connect(function()
        local pressTween = TweenService:Create(
            jumpButton,
            TweenInfo.new(0.1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
            {Size = UDim2.new(0, 90, 0, 90)}
        )
        pressTween:Play()
    end)
    
    jumpButton.MouseButton1Up:Connect(function()
        local releaseTween = TweenService:Create(
            jumpButton,
            TweenInfo.new(0.1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
            {Size = UDim2.new(0, 100, 0, 100)}
        )
        releaseTween:Play()
    end)
    
    print("📱 Mobile jump button created")
end

function JumpController:PlayJumpEffects(character)
    local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
    if not humanoidRootPart then return end
    
    -- Create jump particle effect
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
    
    -- Emit particles
    particles:Emit(20)
    
    -- Clean up after effect
    spawn(function()
        wait(2)
        if attachment and attachment.Parent then
            attachment:Destroy()
        end
    end)
    
    -- Play jump sound
    self:PlayJumpSound()
end

function JumpController:PlayLandingEffects(character)
    local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
    if not humanoidRootPart then return end
    
    -- Create landing dust effect
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
    
    -- Emit particles
    dustParticles:Emit(15)
    
    -- Clean up after effect
    spawn(function()
        wait(2)
        if attachment and attachment.Parent then
            attachment:Destroy()
        end
    end)
    
    -- Play landing sound
    self:PlayLandingSound()
end

function JumpController:PlayJumpSound()
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

function JumpController:PlayLandingSound()
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

function JumpController:SetupRemoteEvents()
    -- Listen for server-side jump validation responses
    RemoteEvents.JumpValidated.OnClientEvent:Connect(function(isValid)
        if not isValid then
            -- Server rejected jump, reset state
            jumpState.isJumping = false
            jumpState.canJump = true
            print("⚠️ Jump rejected by server")
        end
    end)
    
    -- Listen for jump state updates from server
    RemoteEvents.UpdateJumpState.OnClientEvent:Connect(function(newState)
        jumpState.canJump = newState.canJump
        jumpState.isJumping = newState.isJumping
        jumpState.isInAir = newState.isInAir
    end)
end

function JumpController:GetJumpState()
    return {
        canJump = jumpState.canJump,
        isJumping = jumpState.isJumping,
        isInAir = jumpState.isInAir,
        lastJumpTime = jumpState.lastJumpTime
    }
end

function JumpController:Cleanup()
    -- Disconnect all connections
    for _, connection in pairs(inputConnections) do
        if connection then
            connection:Disconnect()
        end
    end
    
    print("🧹 JumpController cleaned up")
end

return JumpController
