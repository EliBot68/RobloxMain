-- VisualPolishService.luau
-- Manages all visual enhancements including UI, particles, and animations

local Workspace = game:GetService("Workspace")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local VisualPolishService = {}

-- Asset IDs for custom UI elements (using Roblox's free assets)
local UI_ASSETS = {
    buttons = {
        default = "rbxasset://textures/ui/GuiImagePlaceholder.png",
        hover = "rbxasset://textures/ui/GuiImagePlaceholder.png",
        pressed = "rbxasset://textures/ui/GuiImagePlaceholder.png"
    },
    backgrounds = {
        menu = "rbxasset://textures/ui/GuiImagePlaceholder.png",
        game = "rbxasset://textures/ui/GuiImagePlaceholder.png"
    },
    icons = {
        coin = "rbxasset://textures/particles/sparkles_main.dds",
        speed = "rbxasset://textures/ui/GuiImagePlaceholder.png",
        timer = "rbxasset://textures/ui/GuiImagePlaceholder.png",
        difficulty = "rbxasset://textures/ui/GuiImagePlaceholder.png"
    },
    particles = {
        trail = "rbxasset://textures/particles/smoke_main.dds",
        sparkle = "rbxasset://textures/particles/sparkles_main.dds",
        coin_collect = "rbxasset://textures/particles/fire_main.dds",
        jump = "rbxasset://textures/particles/explosion_main.dds"
    }
}

-- Animation configurations
local ANIMATIONS = {
    running = {
        duration = 0.5,
        style = Enum.EasingStyle.Sine,
        direction = Enum.EasingDirection.InOut,
        bounceHeight = 2
    },
    jumping = {
        duration = 0.8,
        style = Enum.EasingStyle.Quad,
        direction = Enum.EasingDirection.Out,
        jumpHeight = 15
    },
    coinCollect = {
        duration = 0.3,
        style = Enum.EasingStyle.Back,
        direction = Enum.EasingDirection.Out,
        scaleMultiplier = 1.5
    }
}

-- Active animations tracker
local activeAnimations = {}
local playerTrails = {}

function VisualPolishService:Initialize()
    print("✨ Initializing Visual Polish Service...")
    
    -- Set up player connections
    Players.PlayerAdded:Connect(function(player)
        player.CharacterAdded:Connect(function(character)
            self:SetupPlayerAnimations(player, character)
            self:SetupPlayerTrails(player, character)
        end)
    end)
    
    -- Handle existing players
    for _, player in pairs(Players:GetPlayers()) do
        if player.Character then
            self:SetupPlayerAnimations(player, player.Character)
            self:SetupPlayerTrails(player, player.Character)
        end
    end
    
    print("✅ Visual Polish Service initialized!")
end

function VisualPolishService:SetupPlayerAnimations(player, character)
    local humanoid = character:WaitForChild("Humanoid")
    local rootPart = character:WaitForChild("HumanoidRootPart")
    
    -- Store original animations
    if not activeAnimations[player] then
        activeAnimations[player] = {
            running = false,
            jumping = false,
            collecting = false,
            originalWalkSpeed = humanoid.WalkSpeed
        }
    end
    
    -- Monitor movement for running animation
    local lastPosition = rootPart.Position
    local runConnection
    
    runConnection = RunService.Heartbeat:Connect(function()
        if not character.Parent then
            runConnection:Disconnect()
            return
        end
        
        local currentPosition = rootPart.Position
        local velocity = (currentPosition - lastPosition).Magnitude
        
        if velocity > 2 and not activeAnimations[player].jumping then
            self:StartRunningAnimation(player, character)
        else
            self:StopRunningAnimation(player, character)
        end
        
        lastPosition = currentPosition
    end)
    
    -- Jump detection
    local jumpConnection
    jumpConnection = humanoid.Jumping:Connect(function()
        self:PlayJumpAnimation(player, character)
    end)
    
    -- Clean up on character removal
    character.AncestryChanged:Connect(function()
        if not character.Parent then
            if runConnection then runConnection:Disconnect() end
            if jumpConnection then jumpConnection:Disconnect() end
            activeAnimations[player] = nil
        end
    end)
end

function VisualPolishService:SetupPlayerTrails(player, character)
    local rootPart = character:WaitForChild("HumanoidRootPart")
    
    -- Create trail attachment
    local trailAttachment0 = Instance.new("Attachment")
    trailAttachment0.Name = "TrailAttachment0"
    trailAttachment0.Position = Vector3.new(-2, 0, 0)
    trailAttachment0.Parent = rootPart
    
    local trailAttachment1 = Instance.new("Attachment")
    trailAttachment1.Name = "TrailAttachment1"
    trailAttachment1.Position = Vector3.new(2, 0, 0)
    trailAttachment1.Parent = rootPart
    
    -- Create main trail
    local trail = Instance.new("Trail")
    trail.Name = "PlayerTrail"
    trail.Attachment0 = trailAttachment0
    trail.Attachment1 = trailAttachment1
    trail.Texture = UI_ASSETS.particles.trail
    trail.Color = ColorSequence.new{
        ColorSequenceKeypoint.new(0, Color3.fromRGB(100, 150, 255)),
        ColorSequenceKeypoint.new(0.5, Color3.fromRGB(255, 255, 100)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 100, 100))
    }
    trail.Transparency = NumberSequence.new{
        NumberSequenceKeypoint.new(0, 0.5),
        NumberSequenceKeypoint.new(1, 1)
    }
    trail.Lifetime = 2
    trail.MinLength = 0
    trail.FaceCamera = true
    trail.Enabled = false
    trail.Parent = rootPart
    
    -- Store trail reference
    playerTrails[player] = trail
    
    -- Clean up on character removal
    character.AncestryChanged:Connect(function()
        if not character.Parent then
            playerTrails[player] = nil
        end
    end)
end

function VisualPolishService:StartRunningAnimation(player, character)
    if activeAnimations[player].running then return end
    activeAnimations[player].running = true
    
    local rootPart = character:FindFirstChild("HumanoidRootPart")
    if not rootPart then return end
    
    -- Enable trail during running
    if playerTrails[player] then
        playerTrails[player].Enabled = true
    end
    
    -- Subtle bouncing animation
    local originalPosition = rootPart.Position
    local bounceConnection
    local bounceTime = 0
    
    bounceConnection = RunService.Heartbeat:Connect(function(deltaTime)
        if not activeAnimations[player].running or not rootPart.Parent then
            bounceConnection:Disconnect()
            return
        end
        
        bounceTime = bounceTime + deltaTime * 8 -- Bounce frequency
        local bounceOffset = math.sin(bounceTime) * ANIMATIONS.running.bounceHeight
        
        -- Apply subtle bounce
        local currentCFrame = rootPart.CFrame
        rootPart.CFrame = CFrame.new(
            currentCFrame.Position.X,
            currentCFrame.Position.Y + bounceOffset * 0.1,
            currentCFrame.Position.Z
        ) * (currentCFrame - currentCFrame.Position)
    end)
end

function VisualPolishService:StopRunningAnimation(player, character)
    if not activeAnimations[player].running then return end
    activeAnimations[player].running = false
    
    -- Disable trail
    if playerTrails[player] then
        playerTrails[player].Enabled = false
    end
end

function VisualPolishService:PlayJumpAnimation(player, character)
    if activeAnimations[player].jumping then return end
    activeAnimations[player].jumping = true
    
    local rootPart = character:FindFirstChild("HumanoidRootPart")
    if not rootPart then return end
    
    -- Create jump particle effect
    self:CreateJumpParticles(rootPart)
    
    -- Enhanced trail during jump
    if playerTrails[player] then
        playerTrails[player].Enabled = true
        local originalColor = playerTrails[player].Color
        playerTrails[player].Color = ColorSequence.new(Color3.fromRGB(255, 255, 255))
        
        -- Reset trail color after jump
        task.wait(ANIMATIONS.jumping.duration)
        if playerTrails[player] then
            playerTrails[player].Color = originalColor
        end
    end
    
    -- Reset jumping state
    task.wait(ANIMATIONS.jumping.duration)
    activeAnimations[player].jumping = false
end

function VisualPolishService:PlayCoinCollectAnimation(player, character, coinPosition)
    if not character then return end
    
    local rootPart = character:FindFirstChild("HumanoidRootPart")
    if not rootPart then return end
    
    -- Create coin collection particles
    self:CreateCoinCollectParticles(coinPosition)
    
    -- Player scale animation
    local originalSize = rootPart.Size
    local scaleTween = TweenService:Create(
        rootPart,
        TweenInfo.new(
            ANIMATIONS.coinCollect.duration,
            ANIMATIONS.coinCollect.style,
            ANIMATIONS.coinCollect.direction
        ),
        {Size = originalSize * ANIMATIONS.coinCollect.scaleMultiplier}
    )
    
    scaleTween:Play()
    scaleTween.Completed:Connect(function()
        local returnTween = TweenService:Create(
            rootPart,
            TweenInfo.new(ANIMATIONS.coinCollect.duration),
            {Size = originalSize}
        )
        returnTween:Play()
    end)
    
    -- Enhanced trail burst
    if playerTrails[player] then
        local originalLifetime = playerTrails[player].Lifetime
        playerTrails[player].Lifetime = 5
        playerTrails[player].Enabled = true
        
        task.wait(1)
        if playerTrails[player] then
            playerTrails[player].Lifetime = originalLifetime
        end
    end
end

function VisualPolishService:CreateJumpParticles(rootPart)
    local attachment = Instance.new("Attachment")
    attachment.Parent = rootPart
    attachment.Position = Vector3.new(0, -2, 0)
    
    local particles = Instance.new("ParticleEmitter")
    particles.Name = "JumpParticles"
    particles.Texture = UI_ASSETS.particles.jump
    particles.Color = ColorSequence.new(Color3.fromRGB(255, 255, 255))
    particles.Size = NumberSequence.new{
        NumberSequenceKeypoint.new(0, 1),
        NumberSequenceKeypoint.new(1, 0)
    }
    particles.Transparency = NumberSequence.new{
        NumberSequenceKeypoint.new(0, 0.3),
        NumberSequenceKeypoint.new(1, 1)
    }
    particles.Lifetime = NumberRange.new(0.5, 1.5)
    particles.Rate = 50
    particles.SpreadAngle = Vector2.new(45, 45)
    particles.Speed = NumberRange.new(5, 15)
    particles.VelocityInheritance = 0.5
    particles.Parent = attachment
    
    -- Event-driven particle control
    particles.Enabled = true
    
    local particleEvent = Instance.new("BindableEvent")
    local function disableParticles()
        particles.Enabled = false
    end
    
    particleEvent.Event:Connect(disableParticles)
    task.wait(0.25) -- Optimized timing for better visual effect
    particleEvent:Fire()
    
    -- Clean up
    game:GetService("Debris"):AddItem(attachment, 3)
end

function VisualPolishService:CreateCoinCollectParticles(position)
    local part = Instance.new("Part")
    part.Name = "CoinCollectEffect"
    part.Size = Vector3.new(1, 1, 1)
    part.Position = position
    part.Anchored = true
    part.CanCollide = false
    part.Transparency = 1
    part.Parent = Workspace
    
    local attachment = Instance.new("Attachment")
    attachment.Parent = part
    
    local particles = Instance.new("ParticleEmitter")
    particles.Name = "CoinCollectParticles"
    particles.Texture = UI_ASSETS.particles.coin_collect
    particles.Color = ColorSequence.new(Color3.fromRGB(255, 255, 100))
    particles.Size = NumberSequence.new{
        NumberSequenceKeypoint.new(0, 0.5),
        NumberSequenceKeypoint.new(0.5, 1.5),
        NumberSequenceKeypoint.new(1, 0)
    }
    particles.Transparency = NumberSequence.new{
        NumberSequenceKeypoint.new(0, 0),
        NumberSequenceKeypoint.new(1, 1)
    }
    particles.Lifetime = NumberRange.new(1, 2)
    particles.Rate = 100
    particles.SpreadAngle = Vector2.new(360, 360)
    particles.Speed = NumberRange.new(2, 10)
    particles.Parent = attachment
    
    -- Burst effect
    particles:Emit(20)
    
    -- Clean up
    game:GetService("Debris"):AddItem(part, 3)
end

function VisualPolishService:CreateCustomButton(parent, config)
    local button = Instance.new("ImageButton")
    button.Name = config.name or "CustomButton"
    button.Size = config.size or UDim2.new(0, 200, 0, 60)
    button.Position = config.position or UDim2.new(0, 0, 0, 0)
    button.BackgroundTransparency = 1
    button.Image = config.image or UI_ASSETS.buttons.default
    button.ScaleType = Enum.ScaleType.Slice
    button.SliceCenter = Rect.new(20, 20, 80, 80)
    button.Parent = parent
    
    -- Add text label
    local textLabel = Instance.new("TextLabel")
    textLabel.Name = "ButtonText"
    textLabel.Size = UDim2.new(1, 0, 1, 0)
    textLabel.BackgroundTransparency = 1
    textLabel.Text = config.text or "Button"
    textLabel.TextColor3 = config.textColor or Color3.new(1, 1, 1)
    textLabel.TextScaled = true
    textLabel.Font = config.font or Enum.Font.SourceSansBold
    textLabel.TextStrokeTransparency = 0
    textLabel.TextStrokeColor3 = Color3.new(0, 0, 0)
    textLabel.Parent = button
    
    -- Add hover effects
    button.MouseEnter:Connect(function()
        local hoverTween = TweenService:Create(
            button,
            TweenInfo.new(0.2, Enum.EasingStyle.Quad),
            {Size = button.Size + UDim2.new(0, 10, 0, 5)}
        )
        hoverTween:Play()
    end)
    
    button.MouseLeave:Connect(function()
        local leaveTween = TweenService:Create(
            button,
            TweenInfo.new(0.2, Enum.EasingStyle.Quad),
            {Size = config.size or UDim2.new(0, 200, 0, 60)}
        )
        leaveTween:Play()
    end)
    
    -- Add click animation
    button.MouseButton1Down:Connect(function()
        local pressTween = TweenService:Create(
            button,
            TweenInfo.new(0.1, Enum.EasingStyle.Quad),
            {Size = button.Size - UDim2.new(0, 5, 0, 2)}
        )
        pressTween:Play()
    end)
    
    button.MouseButton1Up:Connect(function()
        local releaseTween = TweenService:Create(
            button,
            TweenInfo.new(0.1, Enum.EasingStyle.Quad),
            {Size = config.size or UDim2.new(0, 200, 0, 60)}
        )
        releaseTween:Play()
    end)
    
    return button
end

function VisualPolishService:CreateCustomFrame(parent, config)
    local frame = Instance.new("ImageLabel")
    frame.Name = config.name or "CustomFrame"
    frame.Size = config.size or UDim2.new(0, 400, 0, 300)
    frame.Position = config.position or UDim2.new(0.5, -200, 0.5, -150)
    frame.BackgroundTransparency = 1
    frame.Image = config.image or UI_ASSETS.backgrounds.menu
    frame.ScaleType = Enum.ScaleType.Slice
    frame.SliceCenter = Rect.new(50, 50, 200, 200)
    frame.ImageColor3 = config.color or Color3.new(1, 1, 1)
    frame.ImageTransparency = config.transparency or 0
    frame.Parent = parent
    
    -- Add border glow effect
    if config.glow then
        local glowFrame = Instance.new("ImageLabel")
        glowFrame.Name = "GlowEffect"
        glowFrame.Size = UDim2.new(1, 20, 1, 20)
        glowFrame.Position = UDim2.new(0, -10, 0, -10)
        glowFrame.BackgroundTransparency = 1
        glowFrame.Image = config.image or UI_ASSETS.backgrounds.menu
        glowFrame.ScaleType = Enum.ScaleType.Slice
        glowFrame.SliceCenter = Rect.new(50, 50, 200, 200)
        glowFrame.ImageColor3 = config.glowColor or Color3.new(1, 1, 1)
        glowFrame.ImageTransparency = 0.8
        glowFrame.ZIndex = frame.ZIndex - 1
        glowFrame.Parent = frame.Parent
        
        -- Animate glow
        local glowTween = TweenService:Create(
            glowFrame,
            TweenInfo.new(2, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true),
            {ImageTransparency = 0.9}
        )
        glowTween:Play()
    end
    
    return frame
end

function VisualPolishService:EnableTrail(player, colorName)
    if not playerTrails[player] then return end
    
    local trail = playerTrails[player]
    local colors = {
        Red = Color3.fromRGB(255, 100, 100),
        Green = Color3.fromRGB(100, 255, 100),
        Blue = Color3.fromRGB(100, 150, 255),
        Yellow = Color3.fromRGB(255, 255, 100)
    }
    
    local color = colors[colorName] or Color3.new(1, 1, 1)
    trail.Color = ColorSequence.new(color)
    trail.Enabled = true
end

function VisualPolishService:DisableTrail(player)
    if not playerTrails[player] then return end
    playerTrails[player].Enabled = false
end

function VisualPolishService:UpdateTrailColor(player, colorName)
    if not playerTrails[player] then return end
    
    local colors = {
        Red = Color3.fromRGB(255, 100, 100),
        Green = Color3.fromRGB(100, 255, 100),
        Blue = Color3.fromRGB(100, 150, 255),
        Yellow = Color3.fromRGB(255, 255, 100)
    }
    
    local color = colors[colorName] or Color3.new(1, 1, 1)
    playerTrails[player].Color = ColorSequence.new(color)
end

-- Utility functions for external services
function VisualPolishService:TriggerCoinCollectionEffect(player, coinPosition)
    if player.Character then
        self:PlayCoinCollectAnimation(player, player.Character, coinPosition)
    end
end

function VisualPolishService:TriggerJumpEffect(player)
    if player.Character then
        self:PlayJumpAnimation(player, player.Character)
    end
end

function VisualPolishService:GetUIAssets()
    return UI_ASSETS
end

function VisualPolishService:CreateLoadingAnimation(parent)
    local loadingFrame = Instance.new("Frame")
    loadingFrame.Name = "LoadingFrame"
    loadingFrame.Size = UDim2.new(0, 100, 0, 100)
    loadingFrame.Position = UDim2.new(0.5, -50, 0.5, -50)
    loadingFrame.BackgroundTransparency = 1
    loadingFrame.Parent = parent
    
    local spinner = Instance.new("ImageLabel")
    spinner.Name = "Spinner"
    spinner.Size = UDim2.new(1, 0, 1, 0)
    spinner.BackgroundTransparency = 1
    spinner.Image = UI_ASSETS.icons.speed
    spinner.Parent = loadingFrame
    
    -- Spin animation
    local spinTween = TweenService:Create(
        spinner,
        TweenInfo.new(1, Enum.EasingStyle.Linear, Enum.EasingDirection.InOut, -1),
        {Rotation = 360}
    )
    spinTween:Play()
    
    return loadingFrame, spinTween
end

return VisualPolishService
