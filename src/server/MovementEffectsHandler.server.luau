-- MovementEffectsHandler.server.luau
-- Server handler for movement-triggered screen effects
-- Processes movement events from PlayerMovementController and triggers appropriate screen effects

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local MovementEffectsHandler = {}

-- Get Events folder
local eventsFolder = ReplicatedStorage:WaitForChild("Events")

-- Movement effect events (server to client)
local Events = {
    TriggerScreenShake = eventsFolder:WaitForChild("TriggerScreenShake"),
    TriggerFlashEffect = eventsFolder:WaitForChild("TriggerFlashEffect"),
    TriggerFOVZoom = eventsFolder:WaitForChild("TriggerFOVZoom"),
    TriggerJumpEffect = eventsFolder:WaitForChild("TriggerJumpEffect"),
    TriggerSpeedBoostEffect = eventsFolder:WaitForChild("TriggerSpeedBoostEffect"),
    TriggerColorMismatchEffect = eventsFolder:WaitForChild("TriggerColorMismatchEffect")
}

-- Create movement request events (client to server) if they don't exist
local function createEvent(name)
    local event = eventsFolder:FindFirstChild(name)
    if not event then
        event = Instance.new("RemoteEvent")
        event.Name = name
        event.Parent = eventsFolder
    end
    return event
end

-- Movement request events (client to server)
local MovementEvents = {
    PlayerMovement = createEvent("PlayerMovement"),
    TriggerJumpEffect = createEvent("TriggerJumpEffect"),
    TriggerSpeedBoostEffect = createEvent("TriggerSpeedBoostEffect"),
    TriggerFOVZoom = createEvent("TriggerFOVZoom")
}

function MovementEffectsHandler:Init()
    print("🎮 Initializing Movement Effects Handler...")
    
    -- Handle movement events from client
    MovementEvents.PlayerMovement.OnServerEvent:Connect(function(player, movementData)
        self:HandleMovementEvent(player, movementData)
    end)
    
    -- Handle jump effect requests
    MovementEvents.TriggerJumpEffect.OnServerEvent:Connect(function(player, jumpType, jumpPower)
        self:HandleJumpEffectRequest(player, jumpType, jumpPower)
    end)
    
    -- Handle speed boost effect requests
    MovementEvents.TriggerSpeedBoostEffect.OnServerEvent:Connect(function(player, duration)
        self:HandleSpeedBoostEffectRequest(player, duration)
    end)
    
    -- Handle FOV zoom requests
    MovementEvents.TriggerFOVZoom.OnServerEvent:Connect(function(player, intensity, duration)
        self:HandleFOVZoomRequest(player, intensity, duration)
    end)
    
    print("✅ Movement Effects Handler initialized!")
end

function MovementEffectsHandler:HandleMovementEvent(player, movementData)
    if not movementData or not movementData.action then return end
    
    local action = movementData.action
    
    if action == "jump" then
        self:HandleJumpEvent(player, movementData)
    elseif action == "dash" then
        self:HandleDashEvent(player, movementData)
    elseif action == "land" then
        self:HandleLandEvent(player, movementData)
    elseif action == "speedBoost" then
        self:HandleSpeedBoostEvent(player, movementData)
    end
end

function MovementEffectsHandler:HandleJumpEvent(player, movementData)
    local jumpType = movementData.jumpType or "ground"
    local jumpPower = movementData.jumpPower or 50
    
    print(string.format("⬆️ %s performed %s jump", player.Name, jumpType))
    
    -- Determine screen shake intensity based on jump type
    local shakeIntensity = 0.2
    local shakeDuration = 0.4
    
    if jumpType == "air" then
        shakeIntensity = 0.3
        shakeDuration = 0.5
    elseif jumpType == "wall" then
        shakeIntensity = 0.4
        shakeDuration = 0.6
    end
    
    -- Trigger screen shake for jump
    Events.TriggerScreenShake:FireClient(player, shakeIntensity, shakeDuration)
    
    -- Trigger jump effect
    Events.TriggerJumpEffect:FireClient(player, jumpType, jumpPower)
end

function MovementEffectsHandler:HandleDashEvent(player, movementData)
    local direction = movementData.direction
    local distance = movementData.distance or 30
    
    print(string.format("💨 %s performed dash", player.Name))
    
    -- Trigger speed boost effect for dash
    Events.TriggerSpeedBoostEffect:FireClient(player, 0.5) -- 0.5 second effect
    
    -- Trigger FOV zoom for speed feeling
    Events.TriggerFOVZoom:FireClient(player, 0.2, 0.4) -- Slight zoom
    
    -- Light screen shake for dash impact
    Events.TriggerScreenShake:FireClient(player, 0.1, 0.3)
end

function MovementEffectsHandler:HandleLandEvent(player, movementData)
    local landingForce = movementData.force or 1
    
    print(string.format("⬇️ %s landed", player.Name))
    
    -- Screen shake based on landing force
    local shakeIntensity = math.min(0.3, landingForce * 0.1)
    Events.TriggerScreenShake:FireClient(player, shakeIntensity, 0.3)
end

function MovementEffectsHandler:HandleSpeedBoostEvent(player, movementData)
    local duration = movementData.duration or 1.0
    local intensity = movementData.intensity or 1.0
    
    print(string.format("🚀 %s speed boost activated", player.Name))
    
    -- Trigger speed boost effects
    Events.TriggerSpeedBoostEffect:FireClient(player, duration)
    Events.TriggerFOVZoom:FireClient(player, intensity * 0.3, duration)
end

-- Direct effect request handlers

function MovementEffectsHandler:HandleJumpEffectRequest(player, jumpType, jumpPower)
    if not player or not player.Parent then return end
    
    -- Trigger jump effect
    Events.TriggerJumpEffect:FireClient(player, jumpType, jumpPower)
    
    -- Additional screen shake
    local shakeIntensity = 0.2
    if jumpType == "air" then
        shakeIntensity = 0.3
    elseif jumpType == "wall" then
        shakeIntensity = 0.4
    end
    
    Events.TriggerScreenShake:FireClient(player, shakeIntensity, 0.5)
end

function MovementEffectsHandler:HandleSpeedBoostEffectRequest(player, duration)
    if not player or not player.Parent then return end
    
    duration = duration or 1.0
    
    print(string.format("🚀 Speed boost effect requested for %s (%.1fs)", player.Name, duration))
    
    -- Trigger speed boost screen effects
    Events.TriggerSpeedBoostEffect:FireClient(player, duration)
    Events.TriggerFOVZoom:FireClient(player, 0.3, duration)
end

function MovementEffectsHandler:HandleFOVZoomRequest(player, intensity, duration)
    if not player or not player.Parent then return end
    
    intensity = intensity or 0.2
    duration = duration or 0.5
    
    print(string.format("🔍 FOV zoom requested for %s (%.1f intensity, %.1fs)", player.Name, intensity, duration))
    
    -- Trigger FOV zoom effect
    Events.TriggerFOVZoom:FireClient(player, intensity, duration)
end

-- Initialize the handler
MovementEffectsHandler:Init()

return MovementEffectsHandler
