-- CollisionController.luau
-- Advanced collision detection system for Color Rush
-- Handles obstacle collisions, color matching, health tracking, and visual effects

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local _TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")
local _SoundService = game:GetService("SoundService")
local Debris = game:GetService("Debris")

local CollisionController = {}

-- Collision Configuration
local COLLISION_CONFIG = {
    -- Health and lives system
    defaultLives = 3,
    maxLives = 5,
    defaultHealth = 100,
    maxHealth = 100,
    
    -- Damage values
    obstacleDamage = 25,
    colorMismatchDamage = 50,
    perfectColorMatchHealing = 10,
    
    -- Invincibility settings
    invincibilityDuration = 2.0, -- Seconds of invincibility after hit
    invincibilityFlashRate = 0.1, -- Flash rate during invincibility
    
    -- Collision detection
    collisionCooldown = 0.1, -- Minimum time between collisions
    raycastDistance = 5, -- Distance for predictive collision detection
    hitboxExpansion = 1.2, -- Multiplier for collision detection area
    
    -- Color matching system
    colorMatchingEnabled = true,
    strictColorMatching = false, -- If true, must match exactly; if false, neutral obstacles don't hurt
    colorToleranceTime = 0.5, -- Time window for color matching
    
    -- Visual effects
    screenShakeEnabled = true,
    particleEffectsEnabled = true,
    soundEffectsEnabled = true,
    
    -- Performance optimization
    maxCollisionChecksPerFrame = 10,
    collisionUpdateRate = 60, -- Hz
    
    -- Death and respawn
    enablePermaDeath = false,
    respawnDelay = 3.0,
    ghostModeAfterDeath = true,
    ghostModeDuration = 5.0
}

-- Color system matching Color Rush game - MUTED FOR VISIBILITY
local COLORS = {
    Red = {
        color3 = Color3.fromRGB(180, 60, 60),  -- Darker, less bright red
        name = "Red",
        keyCode = Enum.KeyCode.One,
        priority = 1
    },
    Blue = {
        color3 = Color3.fromRGB(60, 120, 200), -- Softer blue
        name = "Blue", 
        keyCode = Enum.KeyCode.Two,
        priority = 2
    },
    Green = {
        color3 = Color3.fromRGB(80, 180, 80),  -- Muted green
        name = "Green",
        keyCode = Enum.KeyCode.Three,
        priority = 3
    },
    Yellow = {
        color3 = Color3.fromRGB(200, 180, 60), -- Darker yellow/gold
        name = "Yellow",
        keyCode = Enum.KeyCode.Four,
        priority = 4
    },
    Neutral = {
        color3 = Color3.fromRGB(140, 140, 140), -- Lighter gray
        name = "Neutral",
        keyCode = nil,
        priority = 0
    }
}

-- Collision types and their properties
local COLLISION_TYPES = {
    OBSTACLE = {
        name = "Obstacle",
        damage = COLLISION_CONFIG.obstacleDamage,
        checkColor = true,
        triggerEffects = true,
        allowMultipleHits = false
    },
    COLLECTIBLE = {
        name = "Collectible",
        damage = 0,
        healing = 5,
        checkColor = false,
        triggerEffects = true,
        allowMultipleHits = false
    },
    HAZARD = {
        name = "Hazard",
        damage = COLLISION_CONFIG.colorMismatchDamage,
        checkColor = false,
        triggerEffects = true,
        allowMultipleHits = true
    },
    CHECKPOINT = {
        name = "Checkpoint",
        damage = 0,
        checkColor = false,
        triggerEffects = false,
        allowMultipleHits = true
    },
    FINISH_LINE = {
        name = "FinishLine",
        damage = 0,
        checkColor = false,
        triggerEffects = true,
        allowMultipleHits = false
    }
}

-- Player collision data storage
local playerCollisionData = {}
local collisionQueue = {}
local performanceMetrics = {
    totalCollisions = 0,
    colorMatches = 0,
    colorMismatches = 0,
    averageProcessingTime = 0,
    lastUpdateTime = 0
}

-- RemoteEvents for client communication
local Events = {}

function CollisionController:Initialize()
    print("💥 Initializing Collision Controller...")
    
    -- Get AnalyticsService reference (commented out due to missing service)
    local success, analyticsService = pcall(function()
        -- return require(script.Parent.Parent.services.AnalyticsService)
        return nil
    end)
    
    if success then
        self.AnalyticsService = analyticsService
        print("📊 CollisionController: AnalyticsService connected")
    else
        warn("⚠️ CollisionController: Could not connect to AnalyticsService")
    end
    
    -- Setup events
    self:SetupRemoteEvents()
    
    -- Setup player connections
    self:SetupPlayerConnections()
    
    -- Initialize collision system
    self:InitializeCollisionSystem()
    
    -- Start collision processing loop
    self:StartCollisionLoop()
    
    print("✅ Collision Controller initialized!")
    return true
end

function CollisionController:SetupRemoteEvents()
    -- Get or create Events folder
    local eventsFolder = ReplicatedStorage:FindFirstChild("Events")
    if not eventsFolder then
        eventsFolder = Instance.new("Folder")
        eventsFolder.Name = "Events"
        eventsFolder.Parent = ReplicatedStorage
    end
    
    -- Create collision-related events
    Events.PlayerHitObstacle = self:CreateEvent("PlayerHitObstacle", eventsFolder)
    Events.PlayerColorChanged = self:CreateEvent("PlayerColorChanged", eventsFolder)
    Events.PlayerHealthChanged = self:CreateEvent("PlayerHealthChanged", eventsFolder)
    Events.PlayerLivesChanged = self:CreateEvent("PlayerLivesChanged", eventsFolder)
    Events.PlayerDied = self:CreateEvent("PlayerDied", eventsFolder)
    Events.PlayerRespawned = self:CreateEvent("PlayerRespawned", eventsFolder)
    Events.CollisionEffect = self:CreateEvent("CollisionEffect", eventsFolder)
    Events.ScreenShake = self:CreateEvent("ScreenShake", eventsFolder)
    Events.PlayerInvincible = self:CreateEvent("PlayerInvincible", eventsFolder)
    Events.ColorMatchFeedback = self:CreateEvent("ColorMatchFeedback", eventsFolder)
    Events.CollectibleCollected = self:CreateEvent("CollectibleCollected", eventsFolder)
    Events.CheckpointReached = self:CreateEvent("CheckpointReached", eventsFolder)
    Events.ObstacleHit = self:CreateEvent("ObstacleHit", eventsFolder)
    
    -- Screen Effects Events
    Events.TriggerScreenShake = self:CreateEvent("TriggerScreenShake", eventsFolder)
    Events.TriggerFlashEffect = self:CreateEvent("TriggerFlashEffect", eventsFolder)
    Events.TriggerFOVZoom = self:CreateEvent("TriggerFOVZoom", eventsFolder)
    Events.TriggerJumpEffect = self:CreateEvent("TriggerJumpEffect", eventsFolder)
    Events.TriggerSpeedBoostEffect = self:CreateEvent("TriggerSpeedBoostEffect", eventsFolder)
    Events.TriggerColorMismatchEffect = self:CreateEvent("TriggerColorMismatchEffect", eventsFolder)
    
    -- Setup client request handlers
    Events.RequestColorChange = self:CreateEvent("RequestColorChange", eventsFolder)
    Events.RequestRespawn = self:CreateEvent("RequestRespawn", eventsFolder)
    
    -- Connect event handlers
    Events.RequestColorChange.OnServerEvent:Connect(function(player, newColor)
        self:HandleColorChangeRequest(player, newColor)
    end)
    
    Events.RequestRespawn.OnServerEvent:Connect(function(player)
        self:HandleRespawnRequest(player)
    end)
    
    print("🔗 Collision events setup complete")
end

function CollisionController:CreateEvent(name, parent)
    local event = parent:FindFirstChild(name)
    if not event then
        event = Instance.new("RemoteEvent")
        event.Name = name
        event.Parent = parent
    end
    return event
end

function CollisionController:SetupPlayerConnections()
    -- Handle existing players
    for _, player in pairs(Players:GetPlayers()) do
        self:OnPlayerAdded(player)
    end
    
    -- Handle new players
    Players.PlayerAdded:Connect(function(player)
        self:OnPlayerAdded(player)
    end)
    
    -- Handle players leaving
    Players.PlayerRemoving:Connect(function(player)
        self:OnPlayerRemoving(player)
    end)
    
    print("👥 Player collision connections setup")
end

function CollisionController:OnPlayerAdded(player)
    -- Initialize player collision data
    playerCollisionData[player.UserId] = {
        player = player,
        health = COLLISION_CONFIG.defaultHealth,
        maxHealth = COLLISION_CONFIG.maxHealth,
        lives = COLLISION_CONFIG.defaultLives,
        currentColor = "Red",
        isInvincible = false,
        invincibilityEndTime = 0,
        lastCollisionTime = 0,
        collisionCooldowns = {},
        isDead = false,
        isGhost = false,
        ghostModeEndTime = 0,
        totalCollisions = 0,
        colorMatches = 0,
        colorMismatches = 0,
        statistics = {
            obstaclesHit = 0,
            collectiblesCollected = 0,
            checkpointsReached = 0,
            timesRespawned = 0,
            totalDamageDealt = 0,
            totalHealing = 0,
            perfectColorMatches = 0
        }
    }
    
    -- Setup character connections when character spawns
    player.CharacterAdded:Connect(function(character)
        self:OnCharacterAdded(player, character)
    end)
    
    -- Handle existing character
    if player.Character then
        self:OnCharacterAdded(player, player.Character)
    end
    
    print("➕ Player collision data initialized: " .. player.Name)
end

function CollisionController:OnPlayerRemoving(player)
    -- Cleanup player data
    if playerCollisionData[player.UserId] then
        playerCollisionData[player.UserId] = nil
        print("➖ Player collision data cleaned: " .. player.Name)
    end
end

function CollisionController:OnCharacterAdded(player, character)
    local playerData = playerCollisionData[player.UserId]
    if not playerData then return end
    
    -- Wait for character to fully load
    local humanoid = character:WaitForChild("Humanoid")
    local _humanoidRootPart = character:WaitForChild("HumanoidRootPart")
    
    -- Reset character-specific data
    playerData.isDead = false
    playerData.isGhost = false
    playerData.isInvincible = false
    playerData.invincibilityEndTime = 0
    playerData.lastCollisionTime = 0
    playerData.collisionCooldowns = {}
    
    -- Setup collision detection for character parts
    self:SetupCharacterCollisionDetection(player, character)
    
    -- Setup humanoid health monitoring
    self:SetupHealthMonitoring(player, humanoid)
    
    -- Apply current color to character
    self:ApplyColorToCharacter(player, character, playerData.currentColor)
    
    -- Notify clients of respawn
    Events.PlayerRespawned:FireAllClients(player, {
        health = playerData.health,
        lives = playerData.lives,
        color = playerData.currentColor
    })
    
    print("👨‍🎮 Character collision setup complete: " .. player.Name)
end

function CollisionController:SetupCharacterCollisionDetection(player, character)
    local playerData = playerCollisionData[player.UserId]
    if not playerData then return end
    
    -- Get all character parts for collision detection
    local parts = character:GetChildren()
    
    for _, part in ipairs(parts) do
        if part:IsA("BasePart") and part.Name ~= "HumanoidRootPart" then
            -- Connect touch detection
            part.Touched:Connect(function(hit)
                self:OnPartTouched(player, part, hit)
            end)
        end
    end
    
    -- Special handling for HumanoidRootPart (main collision detection)
    local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
    if humanoidRootPart then
        humanoidRootPart.Touched:Connect(function(hit)
            self:OnMainCollision(player, humanoidRootPart, hit)
        end)
    end
end

function CollisionController:SetupHealthMonitoring(player, humanoid)
    local playerData = playerCollisionData[player.UserId]
    if not playerData then return end
    
    -- Set humanoid health to match our system
    humanoid.MaxHealth = playerData.maxHealth
    humanoid.Health = playerData.health
    
    -- Monitor humanoid health changes
    humanoid.HealthChanged:Connect(function(health)
        self:OnHumanoidHealthChanged(player, health)
    end)
    
    -- Monitor humanoid death
    humanoid.Died:Connect(function()
        self:OnHumanoidDied(player)
    end)
end

function CollisionController:InitializeCollisionSystem()
    -- Initialize collision processing system
    collisionQueue = {}
    
    -- Event-driven performance monitoring
    local performanceUpdateEvent = Instance.new("BindableEvent")
    
    local function schedulePerformanceUpdate()
        -- Adaptive interval based on collision activity
        local queueSize = #collisionQueue
        local interval = queueSize > 50 and 3 or (queueSize > 10 and 4 or 6)
        wait(interval)
        performanceUpdateEvent:Fire()
    end
    
    performanceUpdateEvent.Event:Connect(function()
        self:UpdatePerformanceMetrics()
        spawn(schedulePerformanceUpdate)
    end)
    
    -- Start the performance monitoring cycle
    spawn(schedulePerformanceUpdate)
    
    print("⚙️ Collision system initialized")
end

function CollisionController:StartCollisionLoop()
    -- Main collision processing loop
    RunService.Heartbeat:Connect(function(deltaTime)
        self:ProcessCollisionQueue(deltaTime)
        self:UpdatePlayerStates(deltaTime)
    end)
    
    print("🔄 Collision processing loop started")
end

-- Main collision detection handlers
function CollisionController:OnMainCollision(player, playerPart, hit)
    local playerData = playerCollisionData[player.UserId]
    if not playerData or playerData.isDead or playerData.isGhost then return end
    
    -- Check collision cooldown
    local currentTime = tick()
    if currentTime - playerData.lastCollisionTime < COLLISION_CONFIG.collisionCooldown then
        return
    end
    
    -- Determine collision type and object
    local collisionInfo = self:AnalyzeCollision(hit)
    if not collisionInfo then return end
    
    -- Add to collision queue for processing
    table.insert(collisionQueue, {
        player = player,
        playerPart = playerPart,
        hitPart = hit,
        collisionInfo = collisionInfo,
        timestamp = currentTime
    })
    
    playerData.lastCollisionTime = currentTime
end

function CollisionController:OnPartTouched(player, playerPart, hit)
    -- Handle collisions on other body parts (less critical)
    if playerPart.Name == "Head" or playerPart.Name == "Torso" or playerPart.Name == "UpperTorso" then
        self:OnMainCollision(player, playerPart, hit)
    end
end

function CollisionController:AnalyzeCollision(hit)
    local parent = hit.Parent
    local hitInfo = {}
    
    -- Check if it's a track obstacle
    if hit:GetAttribute("GeneratedTrack") then
        if hit:GetAttribute("Boundary") then
            hitInfo.type = COLLISION_TYPES.HAZARD
            hitInfo.subType = "boundary"
            hitInfo.color = "Neutral"
        elseif hit:GetAttribute("StartLine") then
            hitInfo.type = COLLISION_TYPES.CHECKPOINT
            hitInfo.subType = "start"
            hitInfo.color = "Neutral"
        elseif hit:GetAttribute("FinishLine") then
            hitInfo.type = COLLISION_TYPES.FINISH_LINE
            hitInfo.subType = "finish"
            hitInfo.color = "Neutral"
        elseif hit:GetAttribute("Checkpoint") then
            hitInfo.type = COLLISION_TYPES.CHECKPOINT
            hitInfo.subType = "checkpoint"
            hitInfo.checkpointNumber = hit:GetAttribute("Checkpoint")
            hitInfo.color = "Neutral"
        elseif hit.Name:find("Obstacle") then
            hitInfo.type = COLLISION_TYPES.OBSTACLE
            hitInfo.subType = "static"
            hitInfo.color = self:DetermineObjectColor(hit)
        elseif hit.Name:find("Collectible") then
            hitInfo.type = COLLISION_TYPES.COLLECTIBLE
            hitInfo.subType = "collectible"
            hitInfo.color = self:DetermineObjectColor(hit)
        else
            hitInfo.type = COLLISION_TYPES.OBSTACLE
            hitInfo.subType = "platform"
            hitInfo.color = "Neutral"
        end
    -- Check if it's a moving obstacle
    elseif parent and parent:GetAttribute("MovingObstacle") then
        hitInfo.type = COLLISION_TYPES.OBSTACLE
        hitInfo.subType = "moving"
        hitInfo.color = self:DetermineObjectColor(hit)
    -- Check if it's a custom obstacle
    elseif hit.Name:find("Obstacle") or hit.Name:find("Barrier") or hit.Name:find("Wall") then
        hitInfo.type = COLLISION_TYPES.OBSTACLE
        hitInfo.subType = "custom"
        hitInfo.color = self:DetermineObjectColor(hit)
    else
        -- Not a recognized collision object
        return nil
    end
    
    hitInfo.object = hit
    hitInfo.objectName = hit.Name
    hitInfo.position = hit.Position
    
    return hitInfo
end

function CollisionController:DetermineObjectColor(object)
    -- Check for explicit color attribute
    local colorAttribute = object:GetAttribute("Color")
    if colorAttribute then
        return colorAttribute
    end
    
    -- Determine color from object's Color3 value
    local objectColor = object.Color
    local closestColor = "Neutral"
    local closestDistance = math.huge
    
    for colorName, colorData in pairs(COLORS) do
        local distance = (objectColor - colorData.color3).Magnitude
        if distance < closestDistance then
            closestDistance = distance
            closestColor = colorName
        end
    end
    
    -- If the color is very close to one of our game colors, use it
    if closestDistance < 0.3 then
        return closestColor
    else
        return "Neutral"
    end
end

function CollisionController:ProcessCollisionQueue(deltaTime)
    local startTime = tick()
    local processedCount = 0
    local maxProcessing = COLLISION_CONFIG.maxCollisionChecksPerFrame
    
    while #collisionQueue > 0 and processedCount < maxProcessing do
        local collision = table.remove(collisionQueue, 1)
        self:ProcessCollision(collision)
        processedCount = processedCount + 1
    end
    
    -- Update performance metrics
    local processingTime = tick() - startTime
    performanceMetrics.averageProcessingTime = 
        (performanceMetrics.averageProcessingTime * 0.9) + (processingTime * 0.1)
    performanceMetrics.lastUpdateTime = tick()
end

function CollisionController:ProcessCollision(collision)
    local player = collision.player
    local collisionInfo = collision.collisionInfo
    local playerData = playerCollisionData[player.UserId]
    
    if not playerData or playerData.isDead then return end
    
    -- Check invincibility
    if playerData.isInvincible and collisionInfo.type == COLLISION_TYPES.OBSTACLE then
        return
    end
    
    -- Check collision-specific cooldown
    local objectId = collisionInfo.objectName
    if playerData.collisionCooldowns[objectId] and 
       tick() - playerData.collisionCooldowns[objectId] < 1.0 then
        return
    end
    
    -- Process based on collision type
    if collisionInfo.type == COLLISION_TYPES.OBSTACLE then
        self:ProcessObstacleCollision(player, collisionInfo)
    elseif collisionInfo.type == COLLISION_TYPES.COLLECTIBLE then
        self:ProcessCollectibleCollision(player, collisionInfo)
    elseif collisionInfo.type == COLLISION_TYPES.HAZARD then
        self:ProcessHazardCollision(player, collisionInfo)
    elseif collisionInfo.type == COLLISION_TYPES.CHECKPOINT then
        self:ProcessCheckpointCollision(player, collisionInfo)
    elseif collisionInfo.type == COLLISION_TYPES.FINISH_LINE then
        self:ProcessFinishLineCollision(player, collisionInfo)
    end
    
    -- Set collision cooldown for this object
    playerData.collisionCooldowns[objectId] = tick()
    playerData.totalCollisions = playerData.totalCollisions + 1
    performanceMetrics.totalCollisions = performanceMetrics.totalCollisions + 1
end

function CollisionController:ProcessObstacleCollision(player, collisionInfo)
    local playerData = playerCollisionData[player.UserId]
    if not playerData then return end
    
    local damage = 0
    local colorMatch = false
    local perfectMatch = false
    
    -- Check color matching if enabled
    if COLLISION_CONFIG.colorMatchingEnabled and collisionInfo.color ~= "Neutral" then
        if collisionInfo.color == playerData.currentColor then
            colorMatch = true
            perfectMatch = true
            damage = 0 -- No damage for perfect color match
            
            -- Perfect color match screen effects
            Events.TriggerFlashEffect:FireClient(player, Color3.fromRGB(100, 255, 100), 0.2, 0.3) -- Green flash
            Events.TriggerScreenShake:FireClient(player, 0.1, 0.2) -- Light shake for satisfaction
            
            -- Potential healing for perfect matches
            if COLLISION_CONFIG.perfectColorMatchHealing > 0 then
                self:HealPlayer(player, COLLISION_CONFIG.perfectColorMatchHealing)
            end
            
            playerData.colorMatches = playerData.colorMatches + 1
            playerData.statistics.perfectColorMatches = playerData.statistics.perfectColorMatches + 1
            performanceMetrics.colorMatches = performanceMetrics.colorMatches + 1
        else
            colorMatch = false
            damage = COLLISION_CONFIG.colorMismatchDamage
            
            -- Color mismatch screen effects
            Events.TriggerColorMismatchEffect:FireClient(player, {
                playerColor = playerData.currentColor,
                obstacleColor = collisionInfo.color,
                intensity = 0.6
            })
            
            playerData.colorMismatches = playerData.colorMismatches + 1
            performanceMetrics.colorMismatches = performanceMetrics.colorMismatches + 1
        end
    else
        -- Standard obstacle damage (neutral or color matching disabled)
        damage = collisionInfo.type.damage
    end
    
    -- Apply damage if any
    if damage > 0 then
        self:DamagePlayer(player, damage, "obstacle", collisionInfo)
        playerData.statistics.obstaclesHit = playerData.statistics.obstaclesHit + 1
        playerData.statistics.totalDamageDealt = playerData.statistics.totalDamageDealt + damage
    end
    
    -- Analytics tracking for obstacle hits
    if self.AnalyticsService then
        self.AnalyticsService:TrackEvent(player, "obstacle_hit", {
            obstacleType = collisionInfo.objectName or "unknown",
            obstacleColor = collisionInfo.color,
            playerColor = playerData.currentColor,
            damage = damage,
            colorMatch = colorMatch,
            perfectMatch = perfectMatch,
            position = {
                x = math.floor(collisionInfo.position.X),
                y = math.floor(collisionInfo.position.Y),
                z = math.floor(collisionInfo.position.Z)
            },
            playerHealth = playerData.health,
            playerLives = playerData.lives,
            playerScore = playerData.score,
            gameTime = (playerData.gameStartTime and (tick() - playerData.gameStartTime)) or 0,
            sessionId = (playerData.gameSession and playerData.gameSession.id) or "no_session",
            totalObstaclesHit = playerData.statistics.obstaclesHit,
            perfectColorMatches = playerData.statistics.perfectColorMatches,
            hitSequence = playerData.statistics.obstaclesHit, -- For pattern analysis
            isInvincible = playerData.isInvincible
        })
    end
    
    -- Trigger visual and audio effects
    self:TriggerCollisionEffects(player, collisionInfo, colorMatch, perfectMatch)
    
    -- Fire events to clients
    Events.PlayerHitObstacle:FireAllClients(player, {
        obstacle = collisionInfo.objectName,
        damage = damage,
        colorMatch = colorMatch,
        perfectMatch = perfectMatch,
        playerColor = playerData.currentColor,
        obstacleColor = collisionInfo.color,
        position = collisionInfo.position
    })
    
    Events.ObstacleHit:FireAllClients(player, collisionInfo.objectName, collisionInfo.subType)
    
    print(string.format("💥 %s hit %s obstacle (%s) - Damage: %d, Color Match: %s", 
        player.Name, collisionInfo.color, collisionInfo.objectName, damage, tostring(colorMatch)))
end

function CollisionController:ProcessCollectibleCollision(player, collisionInfo)
    local playerData = playerCollisionData[player.UserId]
    if not playerData then return end
    
    -- Heal player if collectible provides healing
    if collisionInfo.type.healing > 0 then
        self:HealPlayer(player, collisionInfo.type.healing)
        playerData.statistics.totalHealing = playerData.statistics.totalHealing + collisionInfo.type.healing
    end
    
    playerData.statistics.collectiblesCollected = playerData.statistics.collectiblesCollected + 1
    
    -- Analytics tracking for collectible collection
    if self.AnalyticsService then
        self.AnalyticsService:TrackEvent(player, "collectible_collected", {
            collectibleType = collisionInfo.objectName or "unknown",
            collectibleValue = collisionInfo.type.healing or 0,
            position = {
                x = math.floor(collisionInfo.position.X),
                y = math.floor(collisionInfo.position.Y),
                z = math.floor(collisionInfo.position.Z)
            },
            playerHealth = playerData.health,
            playerLives = playerData.lives,
            playerScore = playerData.score,
            totalCollected = playerData.statistics.collectiblesCollected,
            gameTime = (playerData.gameStartTime and (tick() - playerData.gameStartTime)) or 0,
            sessionId = (playerData.gameSession and playerData.gameSession.id) or "no_session",
            collectionRate = playerData.statistics.collectiblesCollected / math.max(1, playerData.statistics.obstaclesHit + playerData.statistics.collectiblesCollected)
        })
    end
    
    -- Remove collectible from world
    if collisionInfo.object and collisionInfo.object.Parent then
        -- Create disappear effect
        self:CreateCollectibleEffect(collisionInfo.object, player)
        
        -- Remove the collectible
        collisionInfo.object:Destroy()
    end
    
    -- Fire collectible collected event
    Events.CollectibleCollected:FireAllClients(player, {
        collectible = collisionInfo.objectName,
        healing = collisionInfo.type.healing,
        position = collisionInfo.position
    })
    
    print(string.format("💎 %s collected %s - Healing: %d", 
        player.Name, collisionInfo.objectName, collisionInfo.type.healing))
end

function CollisionController:ProcessHazardCollision(player, collisionInfo)
    local playerData = playerCollisionData[player.UserId]
    if not playerData then return end
    
    -- Hazards always deal damage regardless of color
    local damage = collisionInfo.type.damage
    self:DamagePlayer(player, damage, "hazard", collisionInfo)
    
    -- Trigger intense effects for hazards
    self:TriggerHazardEffects(player, collisionInfo)
    
    Events.PlayerHitObstacle:FireAllClients(player, {
        obstacle = collisionInfo.objectName,
        damage = damage,
        hazard = true,
        position = collisionInfo.position
    })
    
    print(string.format("⚠️ %s hit hazard %s - Damage: %d", 
        player.Name, collisionInfo.objectName, damage))
end

function CollisionController:ProcessCheckpointCollision(player, collisionInfo)
    local playerData = playerCollisionData[player.UserId]
    if not playerData then return end
    
    playerData.statistics.checkpointsReached = playerData.statistics.checkpointsReached + 1
    
    -- Fire checkpoint event
    Events.CheckpointReached:FireAllClients(player, 
        collisionInfo.checkpointNumber or 0, 
        collisionInfo.position
    )
    
    print(string.format("🎯 %s reached checkpoint %s", 
        player.Name, tostring(collisionInfo.checkpointNumber or "unknown")))
end

function CollisionController:ProcessFinishLineCollision(player, collisionInfo)
    local playerData = playerCollisionData[player.UserId]
    if not playerData then return end
    
    -- Calculate finish time and bonus
    local finishTime = tick()
    
    -- Fire finish line event (MainGameController will handle the rest)
    local remoteEvents = ReplicatedStorage:FindFirstChild("Events")
    if remoteEvents and remoteEvents:FindFirstChild("PlayerFinished") then
        remoteEvents.PlayerFinished:FireAllClients(player, finishTime)
    end
    
    print(string.format("🏆 %s crossed finish line!", player.Name))
end

-- Health and damage system
function CollisionController:DamagePlayer(player, damage, source, collisionInfo)
    local playerData = playerCollisionData[player.UserId]
    if not playerData or playerData.isDead or playerData.isInvincible then return end
    
    -- Apply damage
    playerData.health = math.max(0, playerData.health - damage)
    
    -- Update humanoid health
    if player.Character and player.Character:FindFirstChild("Humanoid") then
        player.Character.Humanoid.Health = playerData.health
    end
    
    -- Trigger screen effects based on damage type
    if source == "obstacle" then
        -- Collision screen shake based on damage intensity
        local shakeIntensity = math.min(0.8, damage / 50) -- Scale with damage
        Events.TriggerScreenShake:FireClient(player, shakeIntensity, 0.5)
        
        -- Flash effect for obstacle hit
        local flashColor = Color3.fromRGB(255, 100, 100) -- Red flash
        Events.TriggerFlashEffect:FireClient(player, flashColor, 0.3, 0.2)
        
    elseif source == "hazard" then
        -- More intense effects for hazards
        Events.TriggerScreenShake:FireClient(player, 0.6, 0.8)
        local flashColor = Color3.fromRGB(255, 50, 50) -- Bright red flash
        Events.TriggerFlashEffect:FireClient(player, flashColor, 0.5, 0.3)
    end
    
    -- Fire health changed event
    Events.PlayerHealthChanged:FireAllClients(player, {
        health = playerData.health,
        maxHealth = playerData.maxHealth,
        damage = damage,
        source = source
    })
    
    -- Check if player died
    if playerData.health <= 0 then
        self:HandlePlayerDeath(player, source, collisionInfo)
    else
        -- Apply invincibility frames
        self:MakePlayerInvincible(player, COLLISION_CONFIG.invincibilityDuration)
    end
    
    print(string.format("❤️ %s took %d damage from %s - Health: %d/%d", 
        player.Name, damage, source, playerData.health, playerData.maxHealth))
end

function CollisionController:HealPlayer(player, healing)
    local playerData = playerCollisionData[player.UserId]
    if not playerData or playerData.isDead then return end
    
    -- Apply healing
    local oldHealth = playerData.health
    playerData.health = math.min(playerData.maxHealth, playerData.health + healing)
    
    local actualHealing = playerData.health - oldHealth
    
    if actualHealing > 0 then
        -- Update humanoid health
        if player.Character and player.Character:FindFirstChild("Humanoid") then
            player.Character.Humanoid.Health = playerData.health
        end
        
        -- Fire health changed event
        Events.PlayerHealthChanged:FireAllClients(player, {
            health = playerData.health,
            maxHealth = playerData.maxHealth,
            healing = actualHealing,
            source = "collectible"
        })
        
        print(string.format("💚 %s healed %d - Health: %d/%d", 
            player.Name, actualHealing, playerData.health, playerData.maxHealth))
    end
end

function CollisionController:HandlePlayerDeath(player, source, collisionInfo)
    local playerData = playerCollisionData[player.UserId]
    if not playerData or playerData.isDead then return end
    
    -- Mark player as dead
    playerData.isDead = true
    playerData.lives = math.max(0, playerData.lives - 1)
    playerData.statistics.timesRespawned = playerData.statistics.timesRespawned + 1
    
    -- Fire death events
    Events.PlayerDied:FireAllClients(player, {
        lives = playerData.lives,
        source = source,
        position = collisionInfo and collisionInfo.position or Vector3.new(0,0,0),
        canRespawn = playerData.lives > 0
    })
    
    -- Fire MainGameController death event
    local remoteEvents = ReplicatedStorage:FindFirstChild("Events")
    if remoteEvents and remoteEvents:FindFirstChild("PlayerDied") then
        remoteEvents.PlayerDied:FireAllClients(player, {
            reason = source,
            livesRemaining = playerData.lives
        })
    end
    
    Events.PlayerLivesChanged:FireAllClients(player, playerData.lives)
    
    -- NEW: Notify MainGameController for win/loss checking
    self:NotifyMainGameController(player, "player_died", {
        lives = playerData.lives,
        health = playerData.health,
        source = source
    })
    
    -- Handle respawn or game over
    if playerData.lives > 0 then
        self:QueuePlayerRespawn(player)
    else
        self:HandlePlayerGameOver(player)
    end
    
    print(string.format("💀 %s died from %s - Lives remaining: %d", 
        player.Name, source, playerData.lives))
end

function CollisionController:QueuePlayerRespawn(player)
    local playerData = playerCollisionData[player.UserId]
    if not playerData then return end
    
    -- Enable ghost mode if configured
    if COLLISION_CONFIG.ghostModeAfterDeath then
        playerData.isGhost = true
        playerData.ghostModeEndTime = tick() + COLLISION_CONFIG.ghostModeDuration
        
        Events.PlayerInvincible:FireAllClients(player, {
            invincible = true,
            duration = COLLISION_CONFIG.ghostModeDuration,
            type = "ghost"
        })
    end
    
    -- Schedule respawn
    spawn(function()
        wait(COLLISION_CONFIG.respawnDelay)
        
        if playerData.isDead and player.Parent then
            self:RespawnPlayer(player)
        end
    end)
end

function CollisionController:RespawnPlayer(player)
    local playerData = playerCollisionData[player.UserId]
    if not playerData then return end
    
    -- Reset player state
    playerData.isDead = false
    playerData.health = playerData.maxHealth
    playerData.isInvincible = false
    playerData.isGhost = false
    playerData.invincibilityEndTime = 0
    playerData.ghostModeEndTime = 0
    
    -- Respawn character
    player:LoadCharacter()
    
    print(string.format("🔄 %s respawned - Lives: %d", player.Name, playerData.lives))
end

function CollisionController:HandlePlayerGameOver(player)
    local playerData = playerCollisionData[player.UserId]
    if not playerData then return end
    
    -- Player is eliminated from the current game
    Events.PlayerDied:FireAllClients(player, {
        lives = 0,
        gameOver = true,
        canRespawn = false
    })
    
    print(string.format("☠️ %s eliminated - Game Over", player.Name))
end

-- Invincibility system
function CollisionController:MakePlayerInvincible(player, duration)
    local playerData = playerCollisionData[player.UserId]
    if not playerData then return end
    
    playerData.isInvincible = true
    playerData.invincibilityEndTime = tick() + duration
    
    -- Fire invincibility event to client for visual effects
    Events.PlayerInvincible:FireAllClients(player, {
        invincible = true,
        duration = duration,
        type = "damage"
    })
    
    -- Auto-disable invincibility after duration
    spawn(function()
        wait(duration)
        if playerData.isInvincible and tick() >= playerData.invincibilityEndTime then
            playerData.isInvincible = false
            
            Events.PlayerInvincible:FireAllClients(player, {
                invincible = false,
                type = "damage"
            })
        end
    end)
    
    print(string.format("✨ %s is invincible for %.1f seconds", player.Name, duration))
end

-- Color system
function CollisionController:HandleColorChangeRequest(player, newColor)
    local playerData = playerCollisionData[player.UserId]
    if not playerData or playerData.isDead then return end
    
    -- Validate color
    if not COLORS[newColor] then
        warn("Invalid color requested: " .. tostring(newColor))
        return
    end
    
    -- Update player color
    local oldColor = playerData.currentColor
    playerData.currentColor = newColor
    
    -- Apply color to character
    if player.Character then
        self:ApplyColorToCharacter(player, player.Character, newColor)
    end
    
    -- Fire color change event
    Events.PlayerColorChanged:FireAllClients(player, {
        oldColor = oldColor,
        newColor = newColor,
        timestamp = tick()
    })
    
    print(string.format("🎨 %s changed color: %s → %s", player.Name, oldColor, newColor))
end

function CollisionController:ApplyColorToCharacter(player, character, colorName)
    local colorData = COLORS[colorName]
    if not colorData then return end
    
    -- Apply color to character parts
    for _, part in ipairs(character:GetChildren()) do
        if part:IsA("BasePart") and part.Name ~= "HumanoidRootPart" then
            part.Color = colorData.color3
            
            -- Add glow effect for non-neutral colors
            if colorName ~= "Neutral" then
                local pointLight = part:FindFirstChild("ColorLight")
                if not pointLight then
                    pointLight = Instance.new("PointLight")
                    pointLight.Name = "ColorLight"
                    pointLight.Parent = part
                end
                
                pointLight.Color = colorData.color3
                pointLight.Brightness = 0.3  -- Reduced for professional look
                pointLight.Range = 8  -- Reduced range for better performance
            else
                -- Remove glow for neutral
                local pointLight = part:FindFirstChild("ColorLight")
                if pointLight then
                    pointLight:Destroy()
                end
            end
        end
    end
end

-- Visual effects system
function CollisionController:TriggerCollisionEffects(player, collisionInfo, colorMatch, perfectMatch)
    if not COLLISION_CONFIG.screenShakeEnabled then return end
    
    local intensity = 10
    local duration = 0.3
    
    if perfectMatch then
        intensity = 5 -- Gentle shake for perfect match
        duration = 0.2
        
        -- Positive feedback effect
        Events.ColorMatchFeedback:FireClient(player, {
            match = true,
            perfect = true,
            color = collisionInfo.color
        })
    elseif colorMatch then
        intensity = 7 -- Medium shake for good match
        duration = 0.25
        
        Events.ColorMatchFeedback:FireClient(player, {
            match = true,
            perfect = false,
            color = collisionInfo.color
        })
    else
        intensity = 15 -- Strong shake for mismatch/damage
        duration = 0.4
        
        Events.ColorMatchFeedback:FireClient(player, {
            match = false,
            perfect = false,
            color = collisionInfo.color
        })
    end
    
    -- Fire screen shake event
    Events.ScreenShake:FireClient(player, {
        intensity = intensity,
        duration = duration,
        type = "collision"
    })
    
    -- Fire collision effect event
    Events.CollisionEffect:FireAllClients(player, {
        position = collisionInfo.position,
        type = collisionInfo.subType,
        colorMatch = colorMatch,
        perfectMatch = perfectMatch
    })
end

function CollisionController:TriggerHazardEffects(player, collisionInfo)
    -- Intense effects for hazards
    Events.ScreenShake:FireClient(player, {
        intensity = 20,
        duration = 0.5,
        type = "hazard"
    })
    
    Events.CollisionEffect:FireAllClients(player, {
        position = collisionInfo.position,
        type = "hazard",
        intensity = "high"
    })
end

function CollisionController:CreateCollectibleEffect(collectible, player)
    if not COLLISION_CONFIG.particleEffectsEnabled then return end
    
    -- Create sparkle effect
    local effect = Instance.new("Explosion")
    effect.Position = collectible.Position
    effect.BlastRadius = 0
    effect.BlastPressure = 0
    effect.Visible = false
    effect.Parent = Workspace
    
    -- Create custom particle effect
    local attachment = Instance.new("Attachment")
    attachment.Position = collectible.Position
    attachment.Parent = Workspace.Terrain
    
    local particles = Instance.new("ParticleEmitter")
    particles.Color = ColorSequence.new(collectible.Color)
    particles.Lifetime = NumberRange.new(0.5, 1.0)
    particles.Rate = 100
    particles.SpreadAngle = Vector2.new(45, 45)
    particles.Speed = NumberRange.new(5, 10)
    particles.Parent = attachment
    
    particles:Emit(20)
    
    -- Cleanup
    Debris:AddItem(attachment, 2)
end

-- State update system
function CollisionController:UpdatePlayerStates(deltaTime)
    local currentTime = tick()
    
    for userId, playerData in pairs(playerCollisionData) do
        -- Update invincibility
        if playerData.isInvincible and currentTime >= playerData.invincibilityEndTime then
            playerData.isInvincible = false
            
            Events.PlayerInvincible:FireAllClients(playerData.player, {
                invincible = false,
                type = "damage"
            })
        end
        
        -- Update ghost mode
        if playerData.isGhost and currentTime >= playerData.ghostModeEndTime then
            playerData.isGhost = false
            
            Events.PlayerInvincible:FireAllClients(playerData.player, {
                invincible = false,
                type = "ghost"
            })
        end
        
        -- Clear old collision cooldowns
        for objectId, cooldownTime in pairs(playerData.collisionCooldowns) do
            if currentTime - cooldownTime > 5.0 then -- 5 second cleanup
                playerData.collisionCooldowns[objectId] = nil
            end
        end
    end
end

function CollisionController:UpdatePerformanceMetrics()
    performanceMetrics.memoryUsed = gcinfo()
    
    -- Log performance statistics
    if performanceMetrics.totalCollisions > 0 then
        local matchRate = (performanceMetrics.colorMatches / performanceMetrics.totalCollisions) * 100
        print(string.format("📊 Collision Stats: %d total, %.1f%% color match, %.3fs avg processing", 
            performanceMetrics.totalCollisions, matchRate, performanceMetrics.averageProcessingTime))
    end
end

-- Event handlers
function CollisionController:HandleRespawnRequest(player)
    local playerData = playerCollisionData[player.UserId]
    if not playerData then return end
    
    if playerData.isDead and playerData.lives > 0 then
        self:RespawnPlayer(player)
    end
end

function CollisionController:OnHumanoidHealthChanged(player, health)
    local playerData = playerCollisionData[player.UserId]
    if not playerData then return end
    
    -- Sync our health system with humanoid health
    playerData.health = health
    
    Events.PlayerHealthChanged:FireAllClients(player, {
        health = playerData.health,
        maxHealth = playerData.maxHealth,
        source = "external"
    })
end

function CollisionController:OnHumanoidDied(player)
    local playerData = playerCollisionData[player.UserId]
    if not playerData or playerData.isDead then return end
    
    -- Handle death through our system
    self:HandlePlayerDeath(player, "external", nil)
end

-- Public API methods
function CollisionController:GetPlayerData(player)
    return playerCollisionData[player.UserId]
end

function CollisionController:GetPlayerHealth(player)
    local playerData = playerCollisionData[player.UserId]
    return playerData and playerData.health or 0
end

function CollisionController:GetPlayerLives(player)
    local playerData = playerCollisionData[player.UserId]
    return playerData and playerData.lives or 0
end

function CollisionController:GetPlayerColor(player)
    local playerData = playerCollisionData[player.UserId]
    return playerData and playerData.currentColor or "Red"
end

function CollisionController:SetPlayerColor(player, color)
    self:HandleColorChangeRequest(player, color)
end

-- NEW: Notify MainGameController about critical player state changes
function CollisionController:NotifyMainGameController(player, eventType, data)
    -- Look for MainGameController in the server
    local success, result = pcall(function()
        -- Try to find MainGameController through require path
        local mainGameController = require(script.Parent.Parent.MainGameController)
        
        if mainGameController then
            -- Safely check and call optional methods using dynamic access
            if rawget(mainGameController, "OnPlayerStateChanged") then
                (rawget(mainGameController, "OnPlayerStateChanged"))(mainGameController, player, eventType, data)
            elseif rawget(mainGameController, "activePlayers") then
                -- Update MainGameController player data directly
                local playerData = rawget(mainGameController, "activePlayers")[player.UserId]
                if playerData then
                    if data.lives ~= nil then
                        playerData.lives = data.lives
                    end
                    if data.health ~= nil then
                        playerData.health = data.health
                    end
                    
                    -- Trigger elimination check if needed
                    if (data.lives and data.lives <= 0) or (data.health and data.health <= 0) then
                        if mainGameController.EliminatePlayer then
                            local reason = "no_lives"
                            if data.health and data.health <= 0 then
                                reason = "no_health"
                            end
                            mainGameController:EliminatePlayer(player, reason)
                        end
                    end
                end
            end
        end
    end)
    
    if not success then
        warn("⚠️ Failed to notify MainGameController: " .. tostring(result))
    end
end

-- Enhanced damage handling with MainGameController integration
function CollisionController:ApplyDamageToPlayer(player, damage, source)
    local playerData = playerCollisionData[player.UserId]
    if not playerData or playerData.invincible or playerData.isDead then return false end
    
    local oldHealth = playerData.health
    playerData.health = math.max(0, playerData.health - damage)
    
    -- Fire health changed event
    Events.PlayerHealthChanged:FireClient(player, playerData.health, damage, source)
    
    -- Notify MainGameController of health change
    self:NotifyMainGameController(player, "health_changed", {
        health = playerData.health,
        oldHealth = oldHealth,
        damage = damage,
        source = source
    })
    
    -- Check if player died from health loss
    if playerData.health <= 0 and oldHealth > 0 then
        self:HandlePlayerDeath(player, source or "damage", nil)
        return true
    end
    
    return false
end

function CollisionController:SetPlayerHealth(player, health)
    local playerData = playerCollisionData[player.UserId]
    if not playerData then return end
    
    playerData.health = math.max(0, math.min(playerData.maxHealth, health))
    
    if player.Character and player.Character:FindFirstChild("Humanoid") then
        player.Character.Humanoid.Health = playerData.health
    end
    
    Events.PlayerHealthChanged:FireAllClients(player, {
        health = playerData.health,
        maxHealth = playerData.maxHealth,
        source = "external"
    })
end

function CollisionController:SetPlayerLives(player, lives)
    local playerData = playerCollisionData[player.UserId]
    if not playerData then return end
    
    playerData.lives = math.max(0, lives)
    Events.PlayerLivesChanged:FireAllClients(player, playerData.lives)
end

function CollisionController:IsPlayerInvincible(player)
    local playerData = playerCollisionData[player.UserId]
    return playerData and (playerData.isInvincible or playerData.isGhost) or false
end

function CollisionController:GetPerformanceMetrics()
    return performanceMetrics
end

function CollisionController:GetCollisionConfig()
    return COLLISION_CONFIG
end

-- Configuration methods
function CollisionController:SetCollisionConfig(newConfig)
    for key, value in pairs(newConfig) do
        if COLLISION_CONFIG[key] ~= nil then
            COLLISION_CONFIG[key] = value
        end
    end
end

function CollisionController:EnableColorMatching(enabled)
    COLLISION_CONFIG.colorMatchingEnabled = enabled
end

function CollisionController:SetInvincibilityDuration(duration)
    COLLISION_CONFIG.invincibilityDuration = duration
end

return CollisionController
