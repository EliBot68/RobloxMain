-- TrailController.luau
-- Manages cosmetic trail effects during runs and equipping

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local RemoteEvents = require(ReplicatedStorage.Shared.modules.RemoteEvents)

local player = Players.LocalPlayer
local TrailController = {}

-- Trail state
local currentTrail = nil
local trailEffect = nil
local isInRun = false
local updateConnection = nil

-- Trail definitions
local TRAIL_DEFINITIONS = {
    common_sparkle = {
        name = "Sparkle Trail",
        rarity = "Common",
        color = Color3.fromRGB(255, 255, 255),
        texture = "rbxasset://textures/particles/sparkles_main.dds",
        lifetime = NumberRange.new(0.5, 1.0),
        rate = 20,
        speed = NumberRange.new(5, 10),
        size = NumberSequence.new({
            NumberSequenceKeypoint.new(0, 1),
            NumberSequenceKeypoint.new(0.5, 1.5),
            NumberSequenceKeypoint.new(1, 0)
        })
    },
    rare_flame = {
        name = "Flame Trail",
        rarity = "Rare",
        color = ColorSequence.new({
            ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 100, 0)),
            ColorSequenceKeypoint.new(0.5, Color3.fromRGB(255, 200, 0)),
            ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 0, 0))
        }),
        texture = "rbxasset://textures/particles/fire_main.dds",
        lifetime = NumberRange.new(0.8, 1.5),
        rate = 30,
        speed = NumberRange.new(3, 8),
        size = NumberSequence.new({
            NumberSequenceKeypoint.new(0, 0),
            NumberSequenceKeypoint.new(0.3, 2),
            NumberSequenceKeypoint.new(1, 0)
        })
    },
    epic_rainbow = {
        name = "Rainbow Trail",
        rarity = "Epic",
        color = ColorSequence.new({
            ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 0, 0)),
            ColorSequenceKeypoint.new(0.2, Color3.fromRGB(255, 165, 0)),
            ColorSequenceKeypoint.new(0.4, Color3.fromRGB(255, 255, 0)),
            ColorSequenceKeypoint.new(0.6, Color3.fromRGB(0, 255, 0)),
            ColorSequenceKeypoint.new(0.8, Color3.fromRGB(0, 0, 255)),
            ColorSequenceKeypoint.new(1, Color3.fromRGB(128, 0, 128))
        }),
        texture = "rbxasset://textures/particles/sparkles_main.dds",
        lifetime = NumberRange.new(1.0, 2.0),
        rate = 40,
        speed = NumberRange.new(8, 15),
        size = NumberSequence.new({
            NumberSequenceKeypoint.new(0, 0),
            NumberSequenceKeypoint.new(0.2, 3),
            NumberSequenceKeypoint.new(0.8, 2),
            NumberSequenceKeypoint.new(1, 0)
        })
    }
}

function TrailController:Init()
    self:SetupRemoteEvents()
    print("✨ TrailController initialized")
end

function TrailController:SetupRemoteEvents()
    -- Handle trail equipment updates
    RemoteEvents.TrailEquipped.OnClientEvent:Connect(function(trailId)
        self:SetEquippedTrail(trailId)
    end)
    
    -- Handle run start/end events
    RemoteEvents.GameStarted.OnClientEvent:Connect(function()
        self:StartTrailEffects()
    end)
    
    RemoteEvents.GameEnded.OnClientEvent:Connect(function()
        self:StopTrailEffects()
    end)
    
    -- Handle trail data requests
    RemoteEvents.RequestTrailData.OnClientEvent:Connect(function(equippedTrail)
        currentTrail = equippedTrail
    end)
end

function TrailController:SetEquippedTrail(trailId)
    currentTrail = trailId
    
    -- Update trail effects if currently in a run
    if isInRun then
        self:StopTrailEffects()
        if trailId then
            self:StartTrailEffects()
        end
    end
end

function TrailController:StartTrailEffects()
    if not currentTrail or not TRAIL_DEFINITIONS[currentTrail] then
        return
    end
    
    isInRun = true
    
    local character = player.Character
    if not character then
        return
    end
    
    local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
    if not humanoidRootPart then
        return
    end
    
    -- Create trail attachment
    local trailAttachment = Instance.new("Attachment")
    trailAttachment.Name = "TrailAttachment"
    trailAttachment.Position = Vector3.new(0, -2.5, 0) -- Below character
    trailAttachment.Parent = humanoidRootPart
    
    -- Create particle emitter
    local trailData = TRAIL_DEFINITIONS[currentTrail]
    local particleEmitter = Instance.new("ParticleEmitter")
    particleEmitter.Name = "TrailEffect"
    particleEmitter.Parent = trailAttachment
    
    -- Configure particle properties
    particleEmitter.Texture = trailData.texture
    particleEmitter.Lifetime = trailData.lifetime
    particleEmitter.Rate = trailData.rate
    particleEmitter.Speed = trailData.speed
    particleEmitter.Size = trailData.size
    particleEmitter.SpreadAngle = Vector2.new(30, 30)
    particleEmitter.Acceleration = Vector3.new(0, -10, 0)
    particleEmitter.Drag = 1
    
    -- Set color (either single color or sequence)
    if typeof(trailData.color) == "Color3" then
        particleEmitter.Color = ColorSequence.new(trailData.color)
    else
        particleEmitter.Color = trailData.color
    end
    
    -- Transparency animation
    particleEmitter.Transparency = NumberSequence.new({
        NumberSequenceKeypoint.new(0, 0),
        NumberSequenceKeypoint.new(0.8, 0.3),
        NumberSequenceKeypoint.new(1, 1)
    })
    
    -- Store reference
    trailEffect = {
        attachment = trailAttachment,
        emitter = particleEmitter
    }
    
    -- Start velocity-based emission adjustment
    self:StartVelocityTracking()
    
    print("✨ Started trail effect: " .. trailData.name)
end

function TrailController:StartVelocityTracking()
    if updateConnection then
        updateConnection:Disconnect()
    end
    
    updateConnection = RunService.Heartbeat:Connect(function()
        if not trailEffect or not trailEffect.emitter then
            return
        end
        
        local character = player.Character
        if not character then
            return
        end
        
        local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
        if not humanoidRootPart then
            return
        end
        
        -- Adjust emission rate based on movement speed
        local velocity = humanoidRootPart.Velocity
        local speed = velocity.Magnitude
        
        local baseRate = TRAIL_DEFINITIONS[currentTrail].rate
        local adjustedRate = math.max(baseRate * (speed / 16), baseRate * 0.3) -- Scale with speed
        
        trailEffect.emitter.Rate = adjustedRate
        
        -- Add burst effect when moving fast
        if speed > 30 then
            trailEffect.emitter.Speed = NumberRange.new(
                TRAIL_DEFINITIONS[currentTrail].speed.Min * 1.5,
                TRAIL_DEFINITIONS[currentTrail].speed.Max * 1.5
            )
        else
            trailEffect.emitter.Speed = TRAIL_DEFINITIONS[currentTrail].speed
        end
    end)
end

function TrailController:StopTrailEffects()
    isInRun = false
    
    if updateConnection then
        updateConnection:Disconnect()
        updateConnection = nil
    end
    
    if trailEffect then
        -- Fade out the trail
        if trailEffect.emitter then
            trailEffect.emitter.Rate = 0
            
            -- Remove after particles fade
            spawn(function()
                wait(3)
                if trailEffect.attachment and trailEffect.attachment.Parent then
                    trailEffect.attachment:Destroy()
                end
            end)
        end
        
        trailEffect = nil
    end
    
    print("✨ Stopped trail effects")
end

function TrailController:GetTrailDefinitions()
    return TRAIL_DEFINITIONS
end

function TrailController:GetEquippedTrail()
    return currentTrail
end

function TrailController:PreviewTrail(trailId, duration)
    -- Temporarily show trail for preview
    if not TRAIL_DEFINITIONS[trailId] then
        return
    end
    
    local oldTrail = currentTrail
    currentTrail = trailId
    
    self:StartTrailEffects()
    
    -- Restore after duration
    spawn(function()
        wait(duration or 3)
        self:StopTrailEffects()
        currentTrail = oldTrail
    end)
end

function TrailController:SetEquippedTrail(trailId)
    currentEquippedTrail = trailId
    
    -- If currently running and equipped trail changed, restart effects
    if isRunning then
        self:StopTrailEffects()
        if trailId then
            self:StartTrailEffects()
        end
    end
end

function TrailController:Cleanup()
    self:StopTrailEffects()
    currentTrail = nil
end

return TrailController
