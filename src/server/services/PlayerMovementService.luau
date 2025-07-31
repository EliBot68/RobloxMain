-- PlayerMovementService.luau
-- Server-side player movement management service
-- Integrates with DifficultyService for dynamic speed adjustments

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local SafeRequire = require(ReplicatedStorage.Shared.utils.SafeRequire)
local ServiceBase = SafeRequire.require(ReplicatedStorage.Shared.utils.ServiceBase)

local PlayerMovementService = {}
setmetatable(PlayerMovementService, {__index = ServiceBase})

-- Service initialization
function PlayerMovementService.new()
    local self = ServiceBase.new("PlayerMovementService", {
        Priority = 4,
        Dependencies = {}
    })
    setmetatable(self, {__index = PlayerMovementService})
    
    -- Movement configuration
    self.movementConfig = {
        baseWalkSpeed = 16,             -- Default walkspeed
        baseJumpPower = 50,            -- Default jump power
        maxWalkSpeed = 50,             -- Maximum allowed walkspeed
        maxJumpPower = 100,            -- Maximum allowed jump power
        speedBoostMultiplier = 1.5,    -- Speed boost multiplier
        slowEffectMultiplier = 0.5     -- Slow effect multiplier
    }
    
    -- Player movement data
    self.playerMovementData = {}
    self.activeEffects = {}
    
    return self
end

-- Initialize the service
function PlayerMovementService:Initialize()
    if self.IsInitialized then
        return
    end
    
    print("🏃 Initializing PlayerMovementService...")
    
    -- Set up player connections
    Players.PlayerAdded:Connect(function(player)
        self:InitializePlayerMovement(player)
    end)
    
    Players.PlayerRemoving:Connect(function(player)
        self:CleanupPlayerMovement(player)
    end)
    
    -- Initialize for existing players
    for _, player in ipairs(Players:GetPlayers()) do
        self:InitializePlayerMovement(player)
    end
    
    self.IsInitialized = true
    print("✅ PlayerMovementService initialized")
end

-- Start the service
function PlayerMovementService:Start()
    if self.IsRunning then
        return
    end
    
    self:Initialize()
    self.IsRunning = true
    print("▶️ PlayerMovementService started")
end

-- Stop the service
function PlayerMovementService:Stop()
    if not self.IsRunning then
        return
    end
    
    -- Reset all player speeds to default
    for _, player in ipairs(Players:GetPlayers()) do
        self:ResetPlayerSpeed(player)
    end
    
    self.IsRunning = false
    print("⏹️ PlayerMovementService stopped")
end

-- Initialize movement data for a player
function PlayerMovementService:InitializePlayerMovement(player)
    local userId = tostring(player.UserId)
    
    -- Set default movement data
    self.playerMovementData[userId] = {
        baseWalkSpeed = self.movementConfig.baseWalkSpeed,
        baseJumpPower = self.movementConfig.baseJumpPower,
        currentWalkSpeed = self.movementConfig.baseWalkSpeed,
        currentJumpPower = self.movementConfig.baseJumpPower,
        speedMultiplier = 1.0,
        jumpMultiplier = 1.0
    }
    
    -- Initialize active effects tracking
    self.activeEffects[userId] = {}
    
    -- Apply default speeds to character if it exists
    player.CharacterAdded:Connect(function(character)
        self:ApplyMovementSettings(player, character)
    end)
    
    -- Apply to current character if it exists
    if player.Character then
        self:ApplyMovementSettings(player, player.Character)
    end
    
    print("🏃 Initialized movement for " .. player.Name)
end

-- Cleanup movement data for a player
function PlayerMovementService:CleanupPlayerMovement(player)
    local userId = tostring(player.UserId)
    
    self.playerMovementData[userId] = nil
    self.activeEffects[userId] = nil
    
    print("🧹 Cleaned up movement for " .. player.Name)
end

-- Apply movement settings to a character
function PlayerMovementService:ApplyMovementSettings(player, character)
    local humanoid = character:FindFirstChildOfClass("Humanoid")
    if not humanoid then
        return
    end
    
    local userId = tostring(player.UserId)
    local movementData = self.playerMovementData[userId]
    
    if movementData then
        humanoid.WalkSpeed = movementData.currentWalkSpeed
        humanoid.JumpPower = movementData.currentJumpPower
    end
end

-- Update player speed (called by DifficultyService)
function PlayerMovementService:UpdateSpeed(player, newSpeed)
    local userId = tostring(player.UserId)
    local movementData = self.playerMovementData[userId]
    
    if not movementData then
        return
    end
    
    -- Clamp speed to valid range
    local clampedSpeed = math.clamp(newSpeed, 1, self.movementConfig.maxWalkSpeed)
    movementData.currentWalkSpeed = clampedSpeed
    
    -- Apply to character if it exists
    if player.Character then
        local humanoid = player.Character:FindFirstChildOfClass("Humanoid")
        if humanoid then
            humanoid.WalkSpeed = clampedSpeed
        end
    end
    
    print(string.format("🏃 Updated speed for %s: %.1f", player.Name, clampedSpeed))
end

-- Update player jump power
function PlayerMovementService:UpdateJumpPower(player, newJumpPower)
    local userId = tostring(player.UserId)
    local movementData = self.playerMovementData[userId]
    
    if not movementData then
        return
    end
    
    -- Clamp jump power to valid range
    local clampedJumpPower = math.clamp(newJumpPower, 10, self.movementConfig.maxJumpPower)
    movementData.currentJumpPower = clampedJumpPower
    
    -- Apply to character if it exists
    if player.Character then
        local humanoid = player.Character:FindFirstChildOfClass("Humanoid")
        if humanoid then
            humanoid.JumpPower = clampedJumpPower
        end
    end
    
    print(string.format("🦘 Updated jump power for %s: %.1f", player.Name, clampedJumpPower))
end

-- Apply temporary speed boost
function PlayerMovementService:ApplySpeedBoost(player, duration, multiplier)
    local userId = tostring(player.UserId)
    local movementData = self.playerMovementData[userId]
    
    if not movementData then
        return
    end
    
    multiplier = multiplier or self.movementConfig.speedBoostMultiplier
    duration = duration or 5
    
    -- Calculate boosted speed
    local boostedSpeed = movementData.baseWalkSpeed * multiplier
    boostedSpeed = math.clamp(boostedSpeed, 1, self.movementConfig.maxWalkSpeed)
    
    -- Apply boost
    self:UpdateSpeed(player, boostedSpeed)
    
    -- Store effect for tracking
    local effectId = "speed_boost_" .. tick()
    self.activeEffects[userId][effectId] = {
        type = "speed_boost",
        startTime = tick(),
        duration = duration,
        originalSpeed = movementData.currentWalkSpeed
    }
    
    -- Set timer to remove boost
    task.wait(duration)
    
    -- Remove effect and reset speed
    self.activeEffects[userId][effectId] = nil
    self:UpdateSpeed(player, movementData.baseWalkSpeed)
    
    print(string.format("⚡ Speed boost expired for %s", player.Name))
end

-- Apply temporary slow effect
function PlayerMovementService:ApplySlowEffect(player, duration, multiplier)
    local userId = tostring(player.UserId)
    local movementData = self.playerMovementData[userId]
    
    if not movementData then
        return
    end
    
    multiplier = multiplier or self.movementConfig.slowEffectMultiplier
    duration = duration or 3
    
    -- Calculate slowed speed
    local slowedSpeed = movementData.baseWalkSpeed * multiplier
    slowedSpeed = math.max(slowedSpeed, 1) -- Don't go below 1
    
    -- Apply slow effect
    self:UpdateSpeed(player, slowedSpeed)
    
    -- Store effect for tracking
    local effectId = "slow_effect_" .. tick()
    self.activeEffects[userId][effectId] = {
        type = "slow_effect",
        startTime = tick(),
        duration = duration,
        originalSpeed = movementData.currentWalkSpeed
    }
    
    -- Set timer to remove effect
    task.wait(duration)
    
    -- Remove effect and reset speed
    self.activeEffects[userId][effectId] = nil
    self:UpdateSpeed(player, movementData.baseWalkSpeed)
    
    print(string.format("🐌 Slow effect expired for %s", player.Name))
end

-- Reset player speed to base values
function PlayerMovementService:ResetPlayerSpeed(player)
    local userId = tostring(player.UserId)
    local movementData = self.playerMovementData[userId]
    
    if not movementData then
        return
    end
    
    -- Reset to base values
    movementData.currentWalkSpeed = movementData.baseWalkSpeed
    movementData.currentJumpPower = movementData.baseJumpPower
    
    -- Apply to character
    if player.Character then
        local humanoid = player.Character:FindFirstChildOfClass("Humanoid")
        if humanoid then
            humanoid.WalkSpeed = movementData.baseWalkSpeed
            humanoid.JumpPower = movementData.baseJumpPower
        end
    end
    
    -- Clear active effects
    self.activeEffects[userId] = {}
    
    print(string.format("🔄 Reset movement for %s", player.Name))
end

-- Get player movement statistics
function PlayerMovementService:GetPlayerStats(player)
    local userId = tostring(player.UserId)
    local movementData = self.playerMovementData[userId]
    local effects = self.activeEffects[userId]
    
    if not movementData then
        return nil
    end
    
    return {
        baseWalkSpeed = movementData.baseWalkSpeed,
        currentWalkSpeed = movementData.currentWalkSpeed,
        baseJumpPower = movementData.baseJumpPower,
        currentJumpPower = movementData.currentJumpPower,
        activeEffects = effects and #effects or 0
    }
end

-- Get service statistics
function PlayerMovementService:GetServiceStats()
    local totalPlayers = 0
    local totalEffects = 0
    
    for _, effects in pairs(self.activeEffects) do
        totalPlayers = totalPlayers + 1
        for _ in pairs(effects) do
            totalEffects = totalEffects + 1
        end
    end
    
    return {
        totalPlayers = totalPlayers,
        totalActiveEffects = totalEffects,
        averageEffectsPerPlayer = totalPlayers > 0 and (totalEffects / totalPlayers) or 0,
        isRunning = self.IsRunning
    }
end

return PlayerMovementService
