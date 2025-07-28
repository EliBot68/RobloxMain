-- MovingObstacle.luau
-- Comprehensive moving obstacle module for Color Rush

local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local MovingObstacle = {}
MovingObstacle.__index = MovingObstacle

-- Movement pattern types
local MOVEMENT_PATTERNS = {
    LINEAR = "Linear",           -- Side-to-side or back-and-forth
    CIRCULAR = "Circular",       -- Circular motion
    PENDULUM = "Pendulum",       -- Pendulum swing
    FIGURE_EIGHT = "FigureEight", -- Figure-8 pattern
    WAYPOINT = "Waypoint",       -- Follow specific waypoints
    RANDOM = "Random"            -- Random movement within bounds
}

-- Default configuration
local DEFAULT_CONFIG = {
    -- Movement settings
    speed = 5,                   -- Units per second
    movementType = MOVEMENT_PATTERNS.LINEAR,
    direction = Vector3.new(1, 0, 0), -- Initial direction
    
    -- Bounds and limits
    movementBounds = {
        min = Vector3.new(-10, 0, 0),
        max = Vector3.new(10, 0, 0)
    },
    
    -- Animation settings
    easingStyle = Enum.EasingStyle.Sine,
    easingDirection = Enum.EasingDirection.InOut,
    reverseOnBounds = true,      -- Reverse direction when hitting bounds
    
    -- Visual settings
    obstacleSize = Vector3.new(4, 8, 2),
    obstacleColor = Color3.fromRGB(255, 100, 100),
    obstacleMaterial = Enum.Material.Neon,
    
    -- Gameplay settings
    damageOnTouch = true,
    requiredColor = nil,         -- Color needed to pass safely (nil = always damages)
    
    -- Effects
    trailEnabled = true,
    rotationEnabled = false,
    pulseEffect = false
}

function MovingObstacle.new(config)
    local self = setmetatable({}, MovingObstacle)
    
    -- Merge config with defaults
    self.config = {}
    for key, value in pairs(DEFAULT_CONFIG) do
        self.config[key] = (config and config[key]) or value
    end
    if config then
        for key, value in pairs(config) do
            if DEFAULT_CONFIG[key] == nil then
                self.config[key] = value
            end
        end
    end
    
    -- State management
    self.isActive = false
    self.currentDirection = self.config.direction
    self.startPosition = Vector3.new(0, 0, 0)
    self.currentPosition = Vector3.new(0, 0, 0)
    self.waypoints = {}
    self.currentWaypointIndex = 1
    
    -- Animation objects
    self.obstaclePart = nil
    self.tweens = {}
    self.connections = {}
    self.effects = {}
    
    return self
end

function MovingObstacle:Create(position, parent)
    -- Set initial position
    self.startPosition = position or Vector3.new(0, 0, 0)
    self.currentPosition = self.startPosition
    
    -- Create obstacle part
    self.obstaclePart = Instance.new("Part")
    self.obstaclePart.Name = "MovingObstacle"
    self.obstaclePart.Size = self.config.obstacleSize
    self.obstaclePart.Position = self.startPosition
    self.obstaclePart.Color = self.config.obstacleColor
    self.obstaclePart.Material = self.config.obstacleMaterial
    self.obstaclePart.Anchored = true
    self.obstaclePart.CanCollide = false -- We'll handle collision detection manually
    self.obstaclePart.Parent = parent or workspace
    
    -- Add obstacle identifier
    self.obstaclePart:SetAttribute("IsMovingObstacle", true)
    self.obstaclePart:SetAttribute("ObstacleType", "Moving")
    self.obstaclePart:SetAttribute("DamageOnTouch", self.config.damageOnTouch)
    if self.config.requiredColor then
        self.obstaclePart:SetAttribute("RequiredColor", self.config.requiredColor)
    end
    
    -- Create visual enhancements
    self:CreateVisualEffects()
    
    -- Setup collision detection
    self:SetupCollisionDetection()
    
    print("📦 Moving obstacle created at position: " .. tostring(self.startPosition))
    return self.obstaclePart
end

function MovingObstacle:CreateVisualEffects()
    if not self.obstaclePart then return end
    
    -- Add glowing effect
    local pointLight = Instance.new("PointLight")
    pointLight.Color = self.config.obstacleColor
    pointLight.Brightness = 1
    pointLight.Range = 10
    pointLight.Parent = self.obstaclePart
    
    -- Add trail effect if enabled
    if self.config.trailEnabled then
        local attachment0 = Instance.new("Attachment")
        attachment0.Name = "TrailAttachment0"
        attachment0.Position = Vector3.new(-self.config.obstacleSize.X/2, 0, 0)
        attachment0.Parent = self.obstaclePart
        
        local attachment1 = Instance.new("Attachment")
        attachment1.Name = "TrailAttachment1"
        attachment1.Position = Vector3.new(self.config.obstacleSize.X/2, 0, 0)
        attachment1.Parent = self.obstaclePart
        
        local trail = Instance.new("Trail")
        trail.Color = ColorSequence.new(self.config.obstacleColor)
        trail.Transparency = NumberSequence.new{
            NumberSequenceKeypoint.new(0, 0.5),
            NumberSequenceKeypoint.new(1, 1)
        }
        trail.Lifetime = 1
        trail.MinLength = 0
        trail.Attachment0 = attachment0
        trail.Attachment1 = attachment1
        trail.Parent = self.obstaclePart
        
        self.effects.trail = trail
    end
    
    -- Add pulse effect if enabled
    if self.config.pulseEffect then
        local originalSize = self.config.obstacleSize
        local pulseTween = TweenService:Create(
            self.obstaclePart,
            TweenInfo.new(1, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true),
            {Size = originalSize * 1.2}
        )
        pulseTween:Play()
        self.effects.pulse = pulseTween
    end
    
    -- Add rotation effect if enabled
    if self.config.rotationEnabled then
        local rotationTween = TweenService:Create(
            self.obstaclePart,
            TweenInfo.new(2, Enum.EasingStyle.Linear, Enum.EasingDirection.InOut, -1),
            {CFrame = self.obstaclePart.CFrame * CFrame.Angles(0, math.pi * 2, 0)}
        )
        rotationTween:Play()
        self.effects.rotation = rotationTween
    end
end

function MovingObstacle:SetupCollisionDetection()
    if not self.obstaclePart then return end
    
    -- Use Touched event for basic collision detection
    self.connections.touched = self.obstaclePart.Touched:Connect(function(hit)
        self:OnTouch(hit)
    end)
end

function MovingObstacle:OnTouch(hit)
    local character = hit.Parent
    local humanoid = character:FindFirstChildOfClass("Humanoid")
    if not humanoid then return end
    
    local player = game.Players:GetPlayerFromCharacter(character)
    if not player then return end
    
    -- Check if obstacle requires specific color
    if self.config.requiredColor then
        -- TODO: Integrate with player color system
        -- For now, assume player has correct color 50% of the time
        if math.random() > 0.5 then
            print("✅ " .. player.Name .. " passed through colored obstacle safely")
            return
        end
    end
    
    if self.config.damageOnTouch then
        print("💥 " .. player.Name .. " hit moving obstacle!")
        
        -- Fire remote event for damage/scoring
        if ReplicatedStorage:FindFirstChild("RemoteEvents") then
            local remoteEvents = ReplicatedStorage.RemoteEvents
            if remoteEvents:FindFirstChild("ObstacleHit") then
                remoteEvents.ObstacleHit:FireAllClients(player, "MovingObstacle")
            end
        end
        
        -- Visual impact effect
        self:CreateImpactEffect()
    end
end

function MovingObstacle:CreateImpactEffect()
    if not self.obstaclePart then return end
    
    -- Flash effect
    local originalColor = self.obstaclePart.Color
    self.obstaclePart.Color = Color3.fromRGB(255, 255, 255)
    
    spawn(function()
        wait(0.1)
        if self.obstaclePart then
            self.obstaclePart.Color = originalColor
        end
    end)
    
    -- Particle burst effect
    local attachment = Instance.new("Attachment")
    attachment.Name = "ImpactEffect"
    attachment.Parent = self.obstaclePart
    
    local particles = Instance.new("ParticleEmitter")
    particles.Texture = "rbxasset://textures/particles/sparkles_main.dds"
    particles.Color = ColorSequence.new(Color3.fromRGB(255, 200, 100))
    particles.Size = NumberSequence.new{
        NumberSequenceKeypoint.new(0, 1),
        NumberSequenceKeypoint.new(1, 0)
    }
    particles.Lifetime = NumberRange.new(0.5, 1)
    particles.Rate = 100
    particles.SpreadAngle = Vector2.new(360, 360)
    particles.Speed = NumberRange.new(10, 20)
    particles.Parent = attachment
    
    particles:Emit(30)
    
    -- Clean up effect
    spawn(function()
        wait(2)
        if attachment and attachment.Parent then
            attachment:Destroy()
        end
    end)
end

function MovingObstacle:StartMovement()
    if self.isActive then return end
    self.isActive = true
    
    if not self.obstaclePart then
        warn("❌ Cannot start movement - obstacle part not created")
        return
    end
    
    print("🏃 Starting movement for obstacle: " .. self.config.movementType)
    
    -- Choose movement pattern
    if self.config.movementType == MOVEMENT_PATTERNS.LINEAR then
        self:StartLinearMovement()
    elseif self.config.movementType == MOVEMENT_PATTERNS.CIRCULAR then
        self:StartCircularMovement()
    elseif self.config.movementType == MOVEMENT_PATTERNS.PENDULUM then
        self:StartPendulumMovement()
    elseif self.config.movementType == MOVEMENT_PATTERNS.FIGURE_EIGHT then
        self:StartFigureEightMovement()
    elseif self.config.movementType == MOVEMENT_PATTERNS.WAYPOINT then
        self:StartWaypointMovement()
    elseif self.config.movementType == MOVEMENT_PATTERNS.RANDOM then
        self:StartRandomMovement()
    end
end

function MovingObstacle:StartLinearMovement()
    local function moveToPosition(targetPosition, duration)
        local tween = TweenService:Create(
            self.obstaclePart,
            TweenInfo.new(
                duration,
                self.config.easingStyle,
                self.config.easingDirection
            ),
            {Position = targetPosition}
        )
        return tween
    end
    
    local function calculateMovement()
        local distance = (self.config.movementBounds.max - self.config.movementBounds.min).Magnitude
        local duration = distance / self.config.speed
        
        local targetPos = self.currentDirection.X > 0 and self.config.movementBounds.max or self.config.movementBounds.min
        targetPos = self.startPosition + targetPos
        
        local tween = moveToPosition(targetPos, duration)
        tween:Play()
        
        tween.Completed:Connect(function()
            if self.isActive and self.config.reverseOnBounds then
                self.currentDirection = -self.currentDirection
                spawn(function()
                    wait(0.1) -- Small pause at bounds
                    if self.isActive then
                        calculateMovement()
                    end
                end)
            end
        end)
        
        table.insert(self.tweens, tween)
    end
    
    calculateMovement()
end

function MovingObstacle:StartCircularMovement()
    local radius = (self.config.movementBounds.max - self.config.movementBounds.min).Magnitude / 2
    local center = self.startPosition + (self.config.movementBounds.max + self.config.movementBounds.min) / 2
    
    local angle = 0
    local connection = RunService.Heartbeat:Connect(function(deltaTime)
        if not self.isActive or not self.obstaclePart then
            return
        end
        
        angle = angle + (self.config.speed * deltaTime)
        local x = center.X + radius * math.cos(angle)
        local z = center.Z + radius * math.sin(angle)
        
        self.obstaclePart.Position = Vector3.new(x, self.startPosition.Y, z)
        self.currentPosition = self.obstaclePart.Position
    end)
    
    self.connections.movement = connection
end

function MovingObstacle:StartPendulumMovement()
    local angle = 0
    local maxAngle = math.pi / 3 -- 60 degrees
    local length = (self.config.movementBounds.max - self.config.movementBounds.min).Magnitude
    
    local connection = RunService.Heartbeat:Connect(function(deltaTime)
        if not self.isActive or not self.obstaclePart then
            return
        end
        
        angle = angle + (self.config.speed * deltaTime)
        local swingAngle = maxAngle * math.sin(angle)
        
        local x = self.startPosition.X + length * math.sin(swingAngle)
        local y = self.startPosition.Y - length * math.cos(swingAngle)
        
        self.obstaclePart.Position = Vector3.new(x, y, self.startPosition.Z)
        self.currentPosition = self.obstaclePart.Position
    end)
    
    self.connections.movement = connection
end

function MovingObstacle:StartFigureEightMovement()
    local time = 0
    local scale = (self.config.movementBounds.max - self.config.movementBounds.min).Magnitude / 4
    
    local connection = RunService.Heartbeat:Connect(function(deltaTime)
        if not self.isActive or not self.obstaclePart then
            return
        end
        
        time = time + (self.config.speed * deltaTime * 0.5)
        
        local x = self.startPosition.X + scale * math.sin(time)
        local z = self.startPosition.Z + scale * math.sin(time * 2)
        
        self.obstaclePart.Position = Vector3.new(x, self.startPosition.Y, z)
        self.currentPosition = self.obstaclePart.Position
    end)
    
    self.connections.movement = connection
end

function MovingObstacle:StartWaypointMovement()
    if #self.waypoints == 0 then
        warn("❌ No waypoints set for waypoint movement")
        return
    end
    
    local function moveToNextWaypoint()
        if not self.isActive then return end
        
        local targetWaypoint = self.waypoints[self.currentWaypointIndex]
        local distance = (targetWaypoint - self.obstaclePart.Position).Magnitude
        local duration = distance / self.config.speed
        
        local tween = TweenService:Create(
            self.obstaclePart,
            TweenInfo.new(duration, self.config.easingStyle, self.config.easingDirection),
            {Position = targetWaypoint}
        )
        
        tween:Play()
        
        tween.Completed:Connect(function()
            if self.isActive then
                self.currentWaypointIndex = self.currentWaypointIndex + 1
                if self.currentWaypointIndex > #self.waypoints then
                    self.currentWaypointIndex = 1
                end
                spawn(function()
                    wait(0.5) -- Pause at waypoint
                    moveToNextWaypoint()
                end)
            end
        end)
        
        table.insert(self.tweens, tween)
    end
    
    moveToNextWaypoint()
end

function MovingObstacle:StartRandomMovement()
    local function moveToRandomPosition()
        if not self.isActive then return end
        
        -- Generate random position within bounds
        local randomX = math.random() * (self.config.movementBounds.max.X - self.config.movementBounds.min.X) + self.config.movementBounds.min.X
        local randomZ = math.random() * (self.config.movementBounds.max.Z - self.config.movementBounds.min.Z) + self.config.movementBounds.min.Z
        local targetPosition = Vector3.new(
            self.startPosition.X + randomX,
            self.startPosition.Y,
            self.startPosition.Z + randomZ
        )
        
        local distance = (targetPosition - self.obstaclePart.Position).Magnitude
        local duration = distance / self.config.speed
        
        local tween = TweenService:Create(
            self.obstaclePart,
            TweenInfo.new(duration, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut),
            {Position = targetPosition}
        )
        
        tween:Play()
        
        tween.Completed:Connect(function()
            if self.isActive then
                spawn(function()
                    wait(math.random(1, 3)) -- Random pause
                    moveToRandomPosition()
                end)
            end
        end)
        
        table.insert(self.tweens, tween)
    end
    
    moveToRandomPosition()
end

function MovingObstacle:StopMovement()
    self.isActive = false
    
    -- Stop all tweens
    for _, tween in pairs(self.tweens) do
        if tween then
            tween:Cancel()
        end
    end
    self.tweens = {}
    
    -- Disconnect all connections
    for _, connection in pairs(self.connections) do
        if connection then
            connection:Disconnect()
        end
    end
    self.connections = {}
    
    print("⏹️ Stopped movement for obstacle")
end

function MovingObstacle:SetWaypoints(waypoints)
    self.waypoints = waypoints or {}
    self.currentWaypointIndex = 1
    print("📍 Set " .. #self.waypoints .. " waypoints for obstacle")
end

function MovingObstacle:SetSpeed(newSpeed)
    self.config.speed = newSpeed
    print("🏃 Updated obstacle speed to: " .. newSpeed)
end

function MovingObstacle:SetMovementBounds(minBounds, maxBounds)
    self.config.movementBounds.min = minBounds
    self.config.movementBounds.max = maxBounds
    print("📏 Updated movement bounds")
end

function MovingObstacle:GetCurrentPosition()
    return self.currentPosition
end

function MovingObstacle:IsActive()
    return self.isActive
end

function MovingObstacle:Destroy()
    self:StopMovement()
    
    -- Stop all effects
    for _, effect in pairs(self.effects) do
        if effect and effect.Cancel then
            effect:Cancel()
        end
    end
    
    -- Destroy obstacle part
    if self.obstaclePart then
        self.obstaclePart:Destroy()
        self.obstaclePart = nil
    end
    
    print("🗑️ Moving obstacle destroyed")
end

-- Static methods for easy obstacle creation
function MovingObstacle.CreateLinear(position, direction, distance, speed, parent)
    local bounds = {
        min = Vector3.new(0, 0, 0),
        max = direction.Unit * distance
    }
    
    local config = {
        movementType = MOVEMENT_PATTERNS.LINEAR,
        direction = direction,
        movementBounds = bounds,
        speed = speed or 5
    }
    
    local obstacle = MovingObstacle.new(config)
    obstacle:Create(position, parent)
    obstacle:StartMovement()
    
    return obstacle
end

function MovingObstacle.CreateCircular(position, radius, speed, parent)
    local bounds = {
        min = Vector3.new(-radius, 0, -radius),
        max = Vector3.new(radius, 0, radius)
    }
    
    local config = {
        movementType = MOVEMENT_PATTERNS.CIRCULAR,
        movementBounds = bounds,
        speed = speed or 3
    }
    
    local obstacle = MovingObstacle.new(config)
    obstacle:Create(position, parent)
    obstacle:StartMovement()
    
    return obstacle
end

function MovingObstacle.CreatePendulum(position, length, speed, parent)
    local bounds = {
        min = Vector3.new(-length, -length, 0),
        max = Vector3.new(length, 0, 0)
    }
    
    local config = {
        movementType = MOVEMENT_PATTERNS.PENDULUM,
        movementBounds = bounds,
        speed = speed or 2
    }
    
    local obstacle = MovingObstacle.new(config)
    obstacle:Create(position, parent)
    obstacle:StartMovement()
    
    return obstacle
end

return MovingObstacle
