-- PetBehaviorService.luau
-- Business logic for pet behaviors, reactions, and interactions
-- Handles pet AI, animations, and passive ability application

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")

local ServiceArchitecture = require(ReplicatedStorage.Shared.core.ServiceArchitecture)
local PetDatabase = require(ReplicatedStorage.Shared.data.PetDatabase)

local PetBehaviorService = {}
PetBehaviorService.__index = PetBehaviorService

-- Extend the domain service interface
setmetatable(PetBehaviorService, {__index = ServiceArchitecture.IDomainService})

function PetBehaviorService.new()
    local self = setmetatable({}, PetBehaviorService)
    
    self.activePets = {} -- [playerId] = {model, data, behavior}
    self.behaviorConnections = {} -- RunService connections
    self.reactionTweens = {} -- Active reaction animations
    
    return self
end

-- ========================================
-- DOMAIN SERVICE INTERFACE IMPLEMENTATION
-- ========================================

function PetBehaviorService:ValidateInput(input)
    local required = {"petId", "playerId"}
    for _, field in ipairs(required) do
        if not input[field] then
            return false, "Missing required field: " .. field
        end
    end
    
    local petData = PetDatabase:GetPetById(input.petId)
    if not petData then
        return false, "Invalid pet ID: " .. input.petId
    end
    
    return true, "Valid input"
end

function PetBehaviorService:ProcessRequest(request)
    local requestType = request.type
    
    if requestType == "spawn_pet" then
        return self:SpawnPetBehavior(request.playerId, request.petId, request.petModel)
    elseif requestType == "despawn_pet" then
        return self:DespawnPetBehavior(request.playerId)
    elseif requestType == "trigger_reaction" then
        return self:TriggerPetReaction(request.playerId, request.reactionType, request.extraData)
    elseif requestType == "apply_passive" then
        return self:ApplyPetPassive(request.playerId, request.gameData)
    else
        return false, "Unknown request type: " .. requestType
    end
end

function PetBehaviorService:GetBusinessRules()
    return {
        maxFollowDistance = 10,
        minFollowDistance = 2,
        reactionDuration = 2.0,
        passiveCooldown = 1.0,
        behaviorUpdateRate = 0.1
    }
end

-- ========================================
-- PET BEHAVIOR MANAGEMENT
-- ========================================

function PetBehaviorService:SpawnPetBehavior(playerId, petId, petModel)
    -- Clean up existing pet behavior
    self:DespawnPetBehavior(playerId)
    
    local petData = PetDatabase:GetPetById(petId)
    if not petData then
        return false, "Pet data not found"
    end
    
    -- Create behavior data
    local behaviorData = {
        model = petModel,
        data = petData,
        lastPosition = petModel.PrimaryPart.Position,
        targetPosition = petModel.PrimaryPart.Position,
        isFollowing = true,
        lastReaction = 0,
        passiveLastApplied = 0
    }
    
    self.activePets[playerId] = behaviorData
    
    -- Start behavior loop
    self:_startBehaviorLoop(playerId)
    
    print("🐾 Started pet behavior for player " .. playerId .. " with pet " .. petId)
    return true, "Pet behavior started"
end

function PetBehaviorService:DespawnPetBehavior(playerId)
    local behaviorData = self.activePets[playerId]
    if not behaviorData then
        return true, "No active pet behavior"
    end
    
    -- Stop behavior loop
    self:_stopBehaviorLoop(playerId)
    
    -- Clean up reaction tweens
    self:_cleanupReactionTweens(playerId)
    
    -- Remove from active pets
    self.activePets[playerId] = nil
    
    print("🐾 Stopped pet behavior for player " .. playerId)
    return true, "Pet behavior stopped"
end

-- ========================================
-- PET FOLLOWING BEHAVIOR
-- ========================================

function PetBehaviorService:_startBehaviorLoop(playerId)
    local connection = RunService.Heartbeat:Connect(function()
        self:_updatePetBehavior(playerId)
    end)
    
    self.behaviorConnections[playerId] = connection
end

function PetBehaviorService:_stopBehaviorLoop(playerId)
    local connection = self.behaviorConnections[playerId]
    if connection then
        connection:Disconnect()
        self.behaviorConnections[playerId] = nil
    end
end

function PetBehaviorService:_updatePetBehavior(playerId)
    local behaviorData = self.activePets[playerId]
    if not behaviorData then
        return
    end
    
    local player = game.Players:GetPlayerByUserId(playerId)
    if not player or not player.Character or not player.Character:FindFirstChild("HumanoidRootPart") then
        return
    end
    
    local playerPosition = player.Character.HumanoidRootPart.Position
    local petModel = behaviorData.model
    local petData = behaviorData.data
    
    if not petModel or not petModel.PrimaryPart then
        return
    end
    
    -- Calculate follow position
    local followDistance = petData.followDistance or 4
    local direction = (playerPosition - petModel.PrimaryPart.Position).Unit
    local targetPosition = playerPosition - (direction * followDistance)
    
    -- Apply height offset to keep pet grounded
    local raycast = workspace:Raycast(targetPosition + Vector3.new(0, 50, 0), Vector3.new(0, -100, 0))
    if raycast then
        targetPosition = raycast.Position + Vector3.new(0, petData.size.Y / 2, 0)
    end
    
    behaviorData.targetPosition = targetPosition
    
    -- Smooth movement using BodyPosition and BodyVelocity
    self:_updatePetMovement(behaviorData, targetPosition, playerPosition)
    
    -- Update pet orientation to face movement direction
    self:_updatePetOrientation(behaviorData, direction)
end

function PetBehaviorService:_updatePetMovement(behaviorData, targetPosition, playerPosition)
    local petModel = behaviorData.model
    local bodyPosition = petModel.PrimaryPart:FindFirstChild("BodyPosition")
    local bodyVelocity = petModel.PrimaryPart:FindFirstChild("BodyVelocity")
    
    if not bodyPosition or not bodyVelocity then
        return
    end
    
    local distance = (targetPosition - petModel.PrimaryPart.Position).Magnitude
    local rules = self:GetBusinessRules()
    
    -- Adjust movement based on distance
    if distance > rules.maxFollowDistance then
        -- Teleport if too far
        petModel:SetPrimaryPartCFrame(CFrame.new(targetPosition))
        bodyVelocity.Velocity = Vector3.new(0, 0, 0)
    elseif distance > rules.minFollowDistance then
        -- Follow smoothly
        bodyPosition.Position = targetPosition
        bodyPosition.MaxForce = Vector3.new(4000, 4000, 4000)
        
        -- Add some randomness to movement
        local randomOffset = Vector3.new(
            (math.random() - 0.5) * 2,
            0,
            (math.random() - 0.5) * 2
        )
        bodyPosition.Position = targetPosition + randomOffset
    else
        -- Stop moving when close enough
        bodyPosition.MaxForce = Vector3.new(0, 4000, 0) -- Only Y-axis to prevent floating
        bodyVelocity.Velocity = bodyVelocity.Velocity * 0.9 -- Damping
    end
end

function PetBehaviorService:_updatePetOrientation(behaviorData, direction)
    local petModel = behaviorData.model
    if not petModel.PrimaryPart then
        return
    end
    
    -- Smoothly rotate pet to face movement direction
    local currentCFrame = petModel.PrimaryPart.CFrame
    local targetLookVector = Vector3.new(direction.X, 0, direction.Z).Unit
    
    if targetLookVector.Magnitude > 0 then
        local targetCFrame = CFrame.lookAt(currentCFrame.Position, currentCFrame.Position + targetLookVector)
        local lerpedCFrame = currentCFrame:Lerp(targetCFrame, 0.1)
        petModel:SetPrimaryPartCFrame(lerpedCFrame)
    end
end

-- ========================================
-- PET REACTIONS
-- ========================================

function PetBehaviorService:TriggerPetReaction(playerId, reactionType, extraData)
    local behaviorData = self.activePets[playerId]
    if not behaviorData then
        return false, "No active pet"
    end
    
    local currentTime = tick()
    local rules = self:GetBusinessRules()
    
    -- Check cooldown
    if currentTime - behaviorData.lastReaction < rules.reactionDuration then
        return false, "Reaction on cooldown"
    end
    
    behaviorData.lastReaction = currentTime
    
    -- Get reaction from pet data
    local petData = behaviorData.data
    local reaction = petData.reactions[reactionType]
    
    if not reaction then
        return false, "Reaction not found: " .. reactionType
    end
    
    -- Execute reaction
    self:_executeReaction(behaviorData, reaction, extraData)
    
    print("🎭 Pet reaction triggered: " .. reaction .. " for player " .. playerId)
    return true, "Reaction triggered"
end

function PetBehaviorService:_executeReaction(behaviorData, reaction, extraData)
    local petModel = behaviorData.model
    local petData = behaviorData.data
    
    -- Clean up previous reaction tweens
    self:_cleanupReactionTweens(behaviorData.playerId)
    
    if reaction == "hop_excited" then
        self:_hopReaction(petModel)
    elseif reaction == "lightning_dance" then
        self:_lightningDanceReaction(petModel, petData)
    elseif reaction == "golden_shimmer" then
        self:_goldenShimmerReaction(petModel, petData)
    elseif reaction == "shell_glow" then
        self:_shellGlowReaction(petModel, petData)
    elseif reaction == "flame_swirl" then
        self:_flameSwirlReaction(petModel, petData)
    elseif reaction == "crystal_chime" then
        self:_crystalChimeReaction(petModel, petData)
    elseif reaction == "shadow_dash" then
        self:_shadowDashReaction(petModel, petData)
    elseif reaction == "rainbow_trail" then
        self:_rainbowTrailReaction(petModel, petData)
    elseif reaction == "golden_flames" then
        self:_goldenFlamesReaction(petModel, petData)
    elseif reaction == "cosmic_trail" then
        self:_cosmicTrailReaction(petModel, petData)
    else
        -- Default reaction
        self:_defaultReaction(petModel, petData)
    end
end

-- ========================================
-- REACTION IMPLEMENTATIONS
-- ========================================

function PetBehaviorService:_hopReaction(petModel)
    local hopTween = TweenService:Create(
        petModel.PrimaryPart,
        TweenInfo.new(0.3, Enum.EasingStyle.Bounce, Enum.EasingDirection.Out, 2, true),
        {Position = petModel.PrimaryPart.Position + Vector3.new(0, 2, 0)}
    )
    hopTween:Play()
    table.insert(self.reactionTweens, hopTween)
end

function PetBehaviorService:_lightningDanceReaction(petModel, petData)
    -- Create lightning effect
    self:_createLightningEffect(petModel, petData.color)
    
    -- Spin animation
    local spinTween = TweenService:Create(
        petModel.PrimaryPart,
        TweenInfo.new(1.0, Enum.EasingStyle.Linear),
        {CFrame = petModel.PrimaryPart.CFrame * CFrame.Angles(0, math.rad(720), 0)}
    )
    spinTween:Play()
    table.insert(self.reactionTweens, spinTween)
end

function PetBehaviorService:_goldenShimmerReaction(petModel, petData)
    -- Shimmer effect
    for _, part in ipairs(petModel:GetDescendants()) do
        if part:IsA("BasePart") then
            local shimmerTween = TweenService:Create(
                part,
                TweenInfo.new(0.5, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, 4, true),
                {Color = Color3.new(1, 1, 0)}
            )
            shimmerTween:Play()
            table.insert(self.reactionTweens, shimmerTween)
        end
    end
end

function PetBehaviorService:_createLightningEffect(petModel, color)
    -- Simple lightning effect using parts and tweens
    for i = 1, 5 do
        local bolt = Instance.new("Part")
        bolt.Name = "LightningBolt"
        bolt.Material = Enum.Material.Neon
        bolt.BrickColor = BrickColor.new(color)
        bolt.Size = Vector3.new(0.1, math.random(1, 3), 0.1)
        bolt.Anchored = true
        bolt.CanCollide = false
        
        local angle = math.rad(i * 72) -- 360 / 5
        local distance = 3
        bolt.Position = petModel.PrimaryPart.Position + Vector3.new(
            math.cos(angle) * distance,
            math.random(-1, 2),
            math.sin(angle) * distance
        )
        
        bolt.Parent = petModel
        
        -- Fade out and remove
        local fadeTween = TweenService:Create(
            bolt,
            TweenInfo.new(1.0, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
            {Transparency = 1, Size = Vector3.new(0.01, bolt.Size.Y * 2, 0.01)}
        )
        fadeTween:Play()
        
        fadeTween.Completed:Connect(function()
            bolt:Destroy()
        end)
    end
end

function PetBehaviorService:_defaultReaction(petModel, petData)
    -- Simple scale pulse
    local scaleTween = TweenService:Create(
        petModel.PrimaryPart,
        TweenInfo.new(0.5, Enum.EasingStyle.Elastic, Enum.EasingDirection.Out, 2, true),
        {Size = petModel.PrimaryPart.Size * 1.2}
    )
    scaleTween:Play()
    table.insert(self.reactionTweens, scaleTween)
end

function PetBehaviorService:_cleanupReactionTweens(playerId)
    for i = #self.reactionTweens, 1, -1 do
        local tween = self.reactionTweens[i]
        if tween then
            tween:Cancel()
            table.remove(self.reactionTweens, i)
        end
    end
end

-- ========================================
-- PASSIVE ABILITIES
-- ========================================

function PetBehaviorService:ApplyPetPassive(playerId, gameData)
    local behaviorData = self.activePets[playerId]
    if not behaviorData then
        return false, "No active pet"
    end
    
    local currentTime = tick()
    local rules = self:GetBusinessRules()
    
    -- Check cooldown
    if currentTime - behaviorData.passiveLastApplied < rules.passiveCooldown then
        return false, "Passive on cooldown"
    end
    
    behaviorData.passiveLastApplied = currentTime
    
    local petData = behaviorData.data
    local passive = petData.passive
    
    if passive.type == "multi_passive" then
        local results = {}
        for _, effect in ipairs(passive.effects) do
            local result = self:_applySinglePassive(effect, gameData)
            table.insert(results, result)
        end
        return true, results
    else
        local result = self:_applySinglePassive(passive, gameData)
        return true, result
    end
end

function PetBehaviorService:_applySinglePassive(passive, gameData)
    local passiveType = passive.type
    local value = passive.value
    
    if passiveType == "speed_bonus" then
        return {
            type = "speed_multiplier",
            value = 1 + value,
            description = "Speed increased by " .. (value * 100) .. "%"
        }
    elseif passiveType == "coin_bonus" then
        return {
            type = "bonus_coins",
            value = value,
            description = "+" .. value .. " bonus coins"
        }
    elseif passiveType == "xp_bonus" then
        return {
            type = "xp_multiplier",
            value = 1 + value,
            description = "XP increased by " .. (value * 100) .. "%"
        }
    elseif passiveType == "shield_chance" then
        local shouldShield = math.random() < value
        return {
            type = "shield_protection",
            value = shouldShield,
            description = shouldShield and "Shield activated!" or "Shield on standby"
        }
    elseif passiveType == "streak_bonus" then
        return {
            type = "streak_multiplier",
            value = 1 + value,
            description = "Streak bonus increased by " .. (value * 100) .. "%"
        }
    else
        return {
            type = "unknown",
            value = 0,
            description = "Unknown passive type: " .. passiveType
        }
    end
end

-- ========================================
-- PET STATUS AND INFORMATION
-- ========================================

function PetBehaviorService:GetActivePetStatus(playerId)
    local behaviorData = self.activePets[playerId]
    if not behaviorData then
        return nil
    end
    
    return {
        petId = behaviorData.data.id,
        petName = behaviorData.data.name,
        isFollowing = behaviorData.isFollowing,
        lastReaction = behaviorData.lastReaction,
        passiveLastApplied = behaviorData.passiveLastApplied,
        position = behaviorData.model.PrimaryPart.Position,
        targetPosition = behaviorData.targetPosition
    }
end

function PetBehaviorService:GetAllActivePets()
    local activePets = {}
    for playerId, behaviorData in pairs(self.activePets) do
        activePets[playerId] = self:GetActivePetStatus(playerId)
    end
    return activePets
end

function PetBehaviorService:GetActivePetCount()
    local count = 0
    for _ in pairs(self.activePets) do
        count = count + 1
    end
    return count
end

return PetBehaviorService
