-- CoinVisualController.luau
-- Manages enhanced coin visuals with sparkle effects and proximity detection

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")

local player = Players.LocalPlayer
local CoinVisualController = {}

-- Visual state
local coinEffects = {}
local proximityDistance = 15 -- Distance to trigger sparkle effects
local updateConnection = nil

function CoinVisualController:Init()
    self:StartProximityCheck()
    print("✨ CoinVisualController initialized")
end

function CoinVisualController:StartProximityCheck()
    -- Clean up existing connection
    if updateConnection then
        updateConnection:Disconnect()
    end
    
    updateConnection = RunService.Heartbeat:Connect(function()
        self:UpdateCoinEffects()
    end)
end

function CoinVisualController:UpdateCoinEffects()
    local character = player.Character
    if not character or not character:FindFirstChild("HumanoidRootPart") then
        return
    end
    
    local playerPosition = character.HumanoidRootPart.Position
    
    -- Find all coin objects in workspace
    local coins = self:FindAllCoins()
    
    for _, coin in pairs(coins) do
        local distance = (coin.Position - playerPosition).Magnitude
        
        if distance <= proximityDistance then
            self:AddSparkleEffect(coin)
        else
            self:RemoveSparkleEffect(coin)
        end
    end
end

function CoinVisualController:FindAllCoins()
    local coins = {}
    
    -- Look for coins in common parent folders
    local possibleParents = {
        Workspace:FindFirstChild("GameObjects"),
        Workspace:FindFirstChild("Coins"),
        Workspace:FindFirstChild("Collectibles"),
        Workspace
    }
    
    for _, parent in pairs(possibleParents) do
        if parent then
            self:SearchForCoins(parent, coins)
        end
    end
    
    return coins
end

function CoinVisualController:SearchForCoins(parent, coinList)
    for _, child in pairs(parent:GetChildren()) do
        -- Check if this looks like a coin
        if self:IsCoinObject(child) then
            table.insert(coinList, child)
        end
        
        -- Recursively search children
        if #child:GetChildren() > 0 then
            self:SearchForCoins(child, coinList)
        end
    end
end

function CoinVisualController:IsCoinObject(obj)
    -- Identify coin objects by common patterns
    local name = obj.Name:lower()
    local isCoin = name:find("coin") or name:find("gold") or name:find("currency")
    
    -- Also check if it's a part with coin-like properties
    if obj:IsA("BasePart") and not isCoin then
        -- Check for typical coin colors (yellow/gold)
        if obj.BrickColor == BrickColor.new("Bright yellow") or 
           obj.BrickColor == BrickColor.new("Gold") or
           obj.Color == Color3.fromRGB(255, 255, 0) then
            isCoin = true
        end
        
        -- Check for circular shape (coin-like)
        if obj.Shape == Enum.PartType.Cylinder or 
           (obj.Size.X == obj.Size.Z and obj.Size.Y < obj.Size.X) then
            isCoin = true
        end
    end
    
    return isCoin and obj:IsA("BasePart")
end

function CoinVisualController:AddSparkleEffect(coin)
    local coinId = tostring(coin)
    
    -- Skip if effect already exists
    if coinEffects[coinId] then
        return
    end
    
    -- Create sparkle effect container
    local effectAttachment = Instance.new("Attachment")
    effectAttachment.Name = "CoinSparkleAttachment"
    effectAttachment.Parent = coin
    
    -- Create particle emitter for sparkles
    local sparkleEmitter = Instance.new("ParticleEmitter")
    sparkleEmitter.Name = "CoinSparkle"
    sparkleEmitter.Parent = effectAttachment
    
    -- Configure sparkle particles
    sparkleEmitter.Texture = "rbxasset://textures/particles/sparkles_main.dds"
    sparkleEmitter.Lifetime = NumberRange.new(0.8, 1.5)
    sparkleEmitter.Rate = 20
    sparkleEmitter.SpreadAngle = Vector2.new(45, 45)
    sparkleEmitter.Speed = NumberRange.new(2, 5)
    sparkleEmitter.Acceleration = Vector3.new(0, -5, 0)
    sparkleEmitter.Drag = 2
    
    -- Color sparkles golden
    local colorSequence = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 255, 100)),
        ColorSequenceKeypoint.new(0.5, Color3.fromRGB(255, 215, 0)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 165, 0))
    })
    sparkleEmitter.Color = colorSequence
    
    -- Size animation
    local sizeSequence = NumberSequence.new({
        NumberSequenceKeypoint.new(0, 0),
        NumberSequenceKeypoint.new(0.2, 1.5),
        NumberSequenceKeypoint.new(0.8, 1),
        NumberSequenceKeypoint.new(1, 0)
    })
    sparkleEmitter.Size = sizeSequence
    
    -- Transparency animation
    local transparencySequence = NumberSequence.new({
        NumberSequenceKeypoint.new(0, 1),
        NumberSequenceKeypoint.new(0.1, 0),
        NumberSequenceKeypoint.new(0.9, 0.3),
        NumberSequenceKeypoint.new(1, 1)
    })
    sparkleEmitter.Transparency = transparencySequence
    
    -- Create glow effect
    local glowEffect = Instance.new("PointLight")
    glowEffect.Name = "CoinGlow"
    glowEffect.Parent = coin
    glowEffect.Color = Color3.fromRGB(255, 215, 0)
    glowEffect.Brightness = 0.5
    glowEffect.Range = 8
    
    -- Pulsing glow animation
    local glowTween = TweenService:Create(
        glowEffect,
        TweenInfo.new(1.5, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true),
        {Brightness = 1.2, Range = 12}
    )
    glowTween:Play()
    
    -- Enhanced coin rotation
    local originalCFrame = coin.CFrame
    local rotationTween = TweenService:Create(
        coin,
        TweenInfo.new(3, Enum.EasingStyle.Linear, Enum.EasingDirection.InOut, -1),
        {CFrame = originalCFrame * CFrame.Angles(0, math.rad(360), 0)}
    )
    rotationTween:Play()
    
    -- Store effect references
    coinEffects[coinId] = {
        attachment = effectAttachment,
        emitter = sparkleEmitter,
        glow = glowEffect,
        glowTween = glowTween,
        rotationTween = rotationTween,
        originalCFrame = originalCFrame
    }
    
    -- Enhanced coin bobbing
    local bobTween = TweenService:Create(
        coin,
        TweenInfo.new(2, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true),
        {Position = coin.Position + Vector3.new(0, 1, 0)}
    )
    bobTween:Play()
    coinEffects[coinId].bobTween = bobTween
end

function CoinVisualController:RemoveSparkleEffect(coin)
    local coinId = tostring(coin)
    local effect = coinEffects[coinId]
    
    if not effect then
        return
    end
    
    -- Clean up effect components
    if effect.attachment and effect.attachment.Parent then
        effect.attachment:Destroy()
    end
    
    if effect.glow and effect.glow.Parent then
        effect.glow:Destroy()
    end
    
    if effect.glowTween then
        effect.glowTween:Cancel()
    end
    
    if effect.rotationTween then
        effect.rotationTween:Cancel()
    end
    
    if effect.bobTween then
        effect.bobTween:Cancel()
    end
    
    -- Restore original rotation
    if effect.originalCFrame and coin.Parent then
        coin.CFrame = effect.originalCFrame
    end
    
    -- Remove from tracking
    coinEffects[coinId] = nil
end

function CoinVisualController:EnhanceCoinAppearance(coin)
    -- Add permanent visual improvements to a coin
    if not coin or not coin:IsA("BasePart") then
        return
    end
    
    -- Enhanced material
    coin.Material = Enum.Material.Neon
    coin.TopSurface = Enum.SurfaceType.Smooth
    coin.BottomSurface = Enum.SurfaceType.Smooth
    
    -- Add surface gui for coin symbol
    local existingGui = coin:FindFirstChild("CoinGui")
    if not existingGui then
        local surfaceGui = Instance.new("SurfaceGui")
        surfaceGui.Name = "CoinGui"
        surfaceGui.Face = Enum.NormalId.Front
        surfaceGui.Parent = coin
        
        local coinSymbol = Instance.new("TextLabel")
        coinSymbol.Size = UDim2.new(1, 0, 1, 0)
        coinSymbol.BackgroundTransparency = 1
        coinSymbol.Text = "$"
        coinSymbol.TextColor3 = Color3.fromRGB(0, 0, 0)
        coinSymbol.TextScaled = true
        coinSymbol.Font = Enum.Font.GothamBold
        coinSymbol.Parent = surfaceGui
    end
    
    -- Add outline effect
    local outline = Instance.new("SelectionBox")
    outline.Name = "CoinOutline"
    outline.Adornee = coin
    outline.Color3 = Color3.fromRGB(255, 215, 0)
    outline.LineThickness = 0.2
    outline.Transparency = 0.5
    outline.Parent = coin
end

function CoinVisualController:CreateCoinCollectionEffect(position)
    -- Create dramatic collection effect at position
    local effectPart = Instance.new("Part")
    effectPart.Name = "CoinCollectionEffect"
    effectPart.Size = Vector3.new(0.1, 0.1, 0.1)
    effectPart.Position = position
    effectPart.Anchored = true
    effectPart.CanCollide = false
    effectPart.Transparency = 1
    effectPart.Parent = Workspace
    
    local attachment = Instance.new("Attachment")
    attachment.Parent = effectPart
    
    -- Burst effect
    local burstEmitter = Instance.new("ParticleEmitter")
    burstEmitter.Parent = attachment
    burstEmitter.Texture = "rbxasset://textures/particles/sparkles_main.dds"
    burstEmitter.Lifetime = NumberRange.new(1, 2)
    burstEmitter.Rate = 100
    burstEmitter.SpreadAngle = Vector2.new(180, 180)
    burstEmitter.Speed = NumberRange.new(10, 20)
    burstEmitter.Acceleration = Vector3.new(0, -20, 0)
    
    burstEmitter.Color = ColorSequence.new(Color3.fromRGB(255, 215, 0))
    burstEmitter.Size = NumberSequence.new({
        NumberSequenceKeypoint.new(0, 2),
        NumberSequenceKeypoint.new(0.5, 1),
        NumberSequenceKeypoint.new(1, 0)
    })
    
    -- Emit burst then clean up
    burstEmitter:Emit(50)
    
    spawn(function()
        wait(3)
        effectPart:Destroy()
    end)
end

function CoinVisualController:Cleanup()
    -- Clean up all active effects
    for coinId, effect in pairs(coinEffects) do
        if effect.attachment and effect.attachment.Parent then
            effect.attachment:Destroy()
        end
        if effect.glow and effect.glow.Parent then
            effect.glow:Destroy()
        end
        if effect.glowTween then
            effect.glowTween:Cancel()
        end
        if effect.rotationTween then
            effect.rotationTween:Cancel()
        end
        if effect.bobTween then
            effect.bobTween:Cancel()
        end
    end
    
    coinEffects = {}
    
    if updateConnection then
        updateConnection:Disconnect()
        updateConnection = nil
    end
end

return CoinVisualController
