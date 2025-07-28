-- AuraService.luau
-- Handles cosmetic aura effects for rebirthed players

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local AuraService = {}

-- Aura configurations
local AURA_CONFIGS = {
    Bronze = {
        color = Color3.fromRGB(205, 127, 50),
        particleCount = 10,
        size = 0.5,
        speed = 2,
        transparency = 0.7
    },
    Silver = {
        color = Color3.fromRGB(192, 192, 192),
        particleCount = 15,
        size = 0.7,
        speed = 3,
        transparency = 0.6
    },
    Gold = {
        color = Color3.fromRGB(255, 215, 0),
        particleCount = 20,
        size = 0.9,
        speed = 4,
        transparency = 0.5
    },
    Diamond = {
        color = Color3.fromRGB(185, 242, 255),
        particleCount = 25,
        size = 1.1,
        speed = 5,
        transparency = 0.4
    },
    Rainbow = {
        color = Color3.fromRGB(255, 255, 255),
        particleCount = 30,
        size = 1.3,
        speed = 6,
        transparency = 0.3,
        isRainbow = true
    }
}

-- Active auras per player
local activeAuras = {}

-- Remote for aura updates
local auraRemote = Instance.new("RemoteEvent")
auraRemote.Name = "AuraRemote"
auraRemote.Parent = ReplicatedStorage

function AuraService:CreateAura(player, auraType)
    if not player.Character or not player.Character:FindFirstChild("HumanoidRootPart") then
        return nil
    end
    
    local config = AURA_CONFIGS[auraType]
    if not config then
        warn("Unknown aura type: " .. tostring(auraType))
        return nil
    end
    
    local rootPart = player.Character.HumanoidRootPart
    
    -- Create aura attachment
    local auraAttachment = Instance.new("Attachment")
    auraAttachment.Name = "AuraAttachment"
    auraAttachment.Parent = rootPart
    
    -- Create particle emitter
    local auraParticles = Instance.new("ParticleEmitter")
    auraParticles.Name = "AuraParticles"
    auraParticles.Parent = auraAttachment
    
    -- Configure particles
    auraParticles.Color = ColorSequence.new(config.color)
    auraParticles.Size = NumberSequence.new{
        NumberSequenceKeypoint.new(0, 0),
        NumberSequenceKeypoint.new(0.5, config.size),
        NumberSequenceKeypoint.new(1, 0)
    }
    auraParticles.Transparency = NumberSequence.new{
        NumberSequenceKeypoint.new(0, 1),
        NumberSequenceKeypoint.new(0.3, config.transparency),
        NumberSequenceKeypoint.new(1, 1)
    }
    auraParticles.Lifetime = NumberRange.new(2, 4)
    auraParticles.Rate = config.particleCount
    auraParticles.VelocityInheritance = 0
    auraParticles.EmissionDirection = Enum.NormalId.Top
    auraParticles.Speed = NumberRange.new(config.speed, config.speed + 2)
    auraParticles.SpreadAngle = Vector2.new(45, 45)
    
    -- Special effects for rainbow aura
    if config.isRainbow then
        -- Create rainbow color cycling
        spawn(function()
            local hue = 0
            while auraParticles.Parent do
                hue = (hue + 1) % 360
                local rainbowColor = Color3.fromHSV(hue / 360, 1, 1)
                auraParticles.Color = ColorSequence.new(rainbowColor)
                wait(0.1)
            end
        end)
    end
    
    -- Create floating ring effect
    local ring = Instance.new("Part")
    ring.Name = "AuraRing"
    ring.Shape = Enum.PartType.Cylinder
    ring.Material = Enum.Material.Neon
    ring.CanCollide = false
    ring.Anchored = true
    ring.Size = Vector3.new(0.2, 6, 6)
    ring.Color = config.color
    ring.Transparency = config.transparency + 0.2
    ring.Parent = rootPart
    
    -- Position ring at player's feet
    ring.CFrame = rootPart.CFrame * CFrame.new(0, -3, 0) * CFrame.fromEulerAnglesXYZ(0, 0, math.rad(90))
    
    -- Animate ring rotation
    local ringTween = TweenService:Create(ring, TweenInfo.new(2, Enum.EasingStyle.Linear, Enum.EasingDirection.InOut, -1), {
        CFrame = ring.CFrame * CFrame.fromEulerAnglesXYZ(math.rad(360), 0, 0)
    })
    ringTween:Play()
    
    local auraData = {
        particles = auraParticles,
        ring = ring,
        attachment = auraAttachment,
        tween = ringTween,
        type = auraType
    }
    
    return auraData
end

function AuraService:ApplyPlayerAura(player)
    -- Get player's rebirth data
    local RebirthService = require(script.Parent.RebirthService)
    local auraEffect = RebirthService:GetPlayerAura(player)
    
    if not auraEffect then
        return -- No aura to apply
    end
    
    -- Remove existing aura
    self:RemovePlayerAura(player)
    
    -- Create new aura
    local auraData = self:CreateAura(player, auraEffect)
    if auraData then
        activeAuras[player.UserId] = auraData
        print("✨ Applied " .. auraEffect .. " aura to " .. player.Name)
    end
end

function AuraService:RemovePlayerAura(player)
    local auraData = activeAuras[player.UserId]
    if not auraData then
        return
    end
    
    -- Clean up aura effects
    if auraData.particles then
        auraData.particles:Destroy()
    end
    if auraData.ring then
        auraData.ring:Destroy()
    end
    if auraData.attachment then
        auraData.attachment:Destroy()
    end
    if auraData.tween then
        auraData.tween:Cancel()
    end
    
    activeAuras[player.UserId] = nil
end

function AuraService:OnPlayerAdded(player)
    player.CharacterAdded:Connect(function(character)
        -- Wait for character to fully load
        wait(2)
        self:ApplyPlayerAura(player)
    end)
    
    player.CharacterRemoving:Connect(function()
        self:RemovePlayerAura(player)
    end)
end

function AuraService:OnPlayerRemoving(player)
    self:RemovePlayerAura(player)
end

function AuraService:RefreshPlayerAura(player)
    -- Called when player completes a rebirth
    if player.Character then
        wait(1) -- Wait for data to update
        self:ApplyPlayerAura(player)
    end
end

function AuraService:Init()
    -- Connect to player events
    Players.PlayerAdded:Connect(function(player)
        self:OnPlayerAdded(player)
    end)
    
    Players.PlayerRemoving:Connect(function(player)
        self:OnPlayerRemoving(player)
    end)
    
    -- Handle existing players
    for _, player in pairs(Players:GetPlayers()) do
        self:OnPlayerAdded(player)
    end
    
    -- Listen for rebirth events to refresh auras
    auraRemote.OnServerEvent:Connect(function(player, action)
        if action == "refresh" then
            self:RefreshPlayerAura(player)
        end
    end)
    
    print("AuraService initialized")
end

return AuraService
