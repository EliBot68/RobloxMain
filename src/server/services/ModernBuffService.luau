-- ModernBuffService.luau
-- Handles temporary buffs during gameplay and purchasable power-ups
-- Converted to modern service architecture with dependency injection and error boundaries

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local ModernServiceFramework = require(ReplicatedStorage.Shared.core.ModernServiceFramework)

-- Create modern service with dependencies and error handling
local BuffService = ModernServiceFramework.CreateService("BuffService", {
    Dependencies = {"PlayerService", "MainGameService", "DataService"},
    OptionalDependencies = {"ShopService", "QuestService", "AnalyticsService"},
    Priority = 25, -- High priority (1-100 scale)
    Testable = true,
    ErrorBoundary = function(errorInfo)
        -- Handle buff-related errors gracefully
        if errorInfo.type == "RuntimeError" and string.find(errorInfo.message, "player") then
            warn("🛡️ BuffService: Player-related error handled gracefully:", errorInfo.message)
            return true -- Error handled, continue operation
        end
        return false -- Let framework handle other errors
    end
})

-- ========================================
-- SERVICE STATE AND CONFIGURATION
-- ========================================

-- Active buffs tracking with better organization
local activeBuffs = {}      -- [userId] = {[buffType] = buffData}
local buffConnections = {}  -- [userId] = {[buffType] = connection}
local buffTimers = {}       -- [userId] = {[buffType] = timer}

-- Buff configurations
local BUFF_TYPES = {
    coinMagnet = {
        name = "💰 Coin Magnet",
        description = "Automatically attracts nearby coins",
        duration = 30,
        price = 150,
        effectRadius = 50,
        magnetStrength = 2.0,
        category = "economy"
    },
    doubleJump = {
        name = "🦘 Double Jump",
        description = "Jump twice in mid-air",
        duration = 45,
        price = 200,
        maxJumps = 2,
        jumpPower = 50,
        category = "movement"
    },
    speedBoost = {
        name = "⚡ Speed Boost",
        description = "Move 50% faster",
        duration = 25,
        price = 100,
        speedMultiplier = 1.5,
        category = "movement"
    },
    invincibility = {
        name = "🛡️ Invincibility",
        description = "Immune to damage for a short time",
        duration = 15,
        price = 500,
        immunityTypes = {"fall", "obstacle", "hazard"},
        category = "protection"
    },
    coinDoubler = {
        name = "💎 Coin Doubler",
        description = "Double coin rewards",
        duration = 60,
        price = 300,
        multiplier = 2.0,
        category = "economy"
    }
}

-- Drop chances for random buff rewards
local BUFF_DROP_CHANCES = {
    coinMagnet = 0.15,
    speedBoost = 0.20,
    doubleJump = 0.10,
    coinDoubler = 0.08,
    invincibility = 0.05
}

-- Performance metrics
local buffMetrics = {
    totalBuffsApplied = 0,
    totalBuffsExpired = 0,
    totalErrors = 0,
    averageBuffDuration = 0
}

-- ========================================
-- SERVICE LIFECYCLE METHODS
-- ========================================

function BuffService:Init(config)
    self.Config = config or {}
    
    -- Initialize remote events for client communication
    self:_setupRemoteEvents()
    
    -- Setup player connections
    self:_setupPlayerConnections()
    
    -- Initialize metrics tracking
    self:_initializeMetrics()
    
    print("🔧 BuffService initialized with modern architecture")
end

function BuffService:Start()
    -- Start periodic cleanup of expired buffs
    self:_startPeriodicCleanup()
    
    -- Start metrics collection
    self:_startMetricsCollection()
    
    print("▶️ BuffService started successfully")
end

function BuffService:Stop()
    -- Clean up all active buffs
    for userId, userBuffs in pairs(activeBuffs) do
        for buffType, _ in pairs(userBuffs) do
            self:RemoveBuff(Players:GetPlayerByUserId(tonumber(userId)), buffType)
        end
    end
    
    -- Disconnect all connections
    for userId, userConnections in pairs(buffConnections) do
        for buffType, connection in pairs(userConnections) do
            if connection then
                connection:Disconnect()
            end
        end
    end
    
    print("⏹️ BuffService stopped and cleaned up")
end

-- ========================================
-- PRIVATE INITIALIZATION METHODS
-- ========================================

function BuffService:_setupRemoteEvents()
    -- Create remote events folder if it doesn't exist
    local remoteEvents = ReplicatedStorage:FindFirstChild("RemoteEvents")
    if not remoteEvents then
        remoteEvents = Instance.new("Folder")
        remoteEvents.Name = "RemoteEvents"
        remoteEvents.Parent = ReplicatedStorage
    end
    
    -- Create buff-related remote events
    local events = {
        "PurchaseBuff",
        "BuffActivated", 
        "BuffExpired",
        "BuffTimeUpdate",
        "BuffShopUpdate"
    }
    
    for _, eventName in ipairs(events) do
        if not remoteEvents:FindFirstChild(eventName) then
            local remoteEvent = Instance.new("RemoteEvent")
            remoteEvent.Name = eventName
            remoteEvent.Parent = remoteEvents
        end
    end
    
    -- Setup remote event handlers
    remoteEvents.PurchaseBuff.OnServerEvent:Connect(function(player, buffType)
        self:PurchaseBuff(player, buffType)
    end)
end

function BuffService:_setupPlayerConnections()
    -- Handle player joining
    Players.PlayerAdded:Connect(function(player)
        self:_initializePlayerBuffs(player)
    end)
    
    -- Handle player leaving
    Players.PlayerRemoving:Connect(function(player)
        self:_cleanupPlayerBuffs(player)
    end)
    
    -- Initialize existing players
    for _, player in pairs(Players:GetPlayers()) do
        self:_initializePlayerBuffs(player)
    end
end

function BuffService:_initializeMetrics()
    buffMetrics = {
        totalBuffsApplied = 0,
        totalBuffsExpired = 0,
        totalErrors = 0,
        averageBuffDuration = 0,
        startTime = tick()
    }
end

function BuffService:_initializePlayerBuffs(player)
    local userId = tostring(player.UserId)
    activeBuffs[userId] = {}
    buffConnections[userId] = {}
    buffTimers[userId] = {}
end

function BuffService:_cleanupPlayerBuffs(player)
    local userId = tostring(player.UserId)
    
    -- Remove all active buffs
    if activeBuffs[userId] then
        for buffType, _ in pairs(activeBuffs[userId]) do
            self:RemoveBuff(player, buffType)
        end
    end
    
    -- Clean up tracking
    activeBuffs[userId] = nil
    buffConnections[userId] = nil
    buffTimers[userId] = nil
end

-- ========================================
-- CORE BUFF MANAGEMENT METHODS
-- ========================================

function BuffService:ApplyBuff(player, buffType, duration, source)
    if not player or not player.Parent then
        return false, "Invalid player"
    end
    
    local buffConfig = BUFF_TYPES[buffType]
    if not buffConfig then
        return false, "Invalid buff type: " .. tostring(buffType)
    end
    
    local success, result = pcall(function()
        return self:_applyBuffSafely(player, buffType, duration or buffConfig.duration, source)
    end)
    
    if not success then
        buffMetrics.totalErrors = buffMetrics.totalErrors + 1
        return false, "Failed to apply buff: " .. tostring(result)
    end
    
    return result
end

function BuffService:_applyBuffSafely(player, buffType, duration, source)
    local userId = tostring(player.UserId)
    local buffConfig = BUFF_TYPES[buffType]
    
    -- Remove existing buff of same type
    if activeBuffs[userId] and activeBuffs[userId][buffType] then
        self:RemoveBuff(player, buffType)
    end
    
    -- Create buff data
    local buffData = {
        type = buffType,
        startTime = tick(),
        endTime = tick() + duration,
        duration = duration,
        source = source or "unknown",
        config = buffConfig
    }
    
    -- Store buff data
    if not activeBuffs[userId] then
        activeBuffs[userId] = {}
    end
    activeBuffs[userId][buffType] = buffData
    
    -- Apply buff effects based on type
    local success = self:_applyBuffEffects(player, buffType, buffData)
    if not success then
        activeBuffs[userId][buffType] = nil
        return false, "Failed to apply buff effects"
    end
    
    -- Start buff timer with modern non-blocking approach
    self:_startBuffTimer(player, buffType, buffData)
    
    -- Notify client
    local remoteEvents = ReplicatedStorage:FindFirstChild("RemoteEvents")
    if remoteEvents and remoteEvents:FindFirstChild("BuffActivated") then
        remoteEvents.BuffActivated:FireClient(player, {
            type = buffType,
            duration = duration,
            config = buffConfig
        })
    end
    
    -- Update metrics
    buffMetrics.totalBuffsApplied = buffMetrics.totalBuffsApplied + 1
    
    print(string.format("✨ Applied %s buff to %s for %ds", buffConfig.name, player.Name, duration))
    
    -- Analytics tracking (if available)
    if self.AnalyticsService then
        self.AnalyticsService:TrackEvent("BuffApplied", {
            playerId = player.UserId,
            buffType = buffType,
            duration = duration,
            source = source
        })
    end
    
    return true
end

function BuffService:RemoveBuff(player, buffType)
    if not player then
        return false
    end
    
    local userId = tostring(player.UserId)
    
    if not activeBuffs[userId] or not activeBuffs[userId][buffType] then
        return false -- Buff not active
    end
    
    local buffData = activeBuffs[userId][buffType]
    
    -- Remove buff effects
    self:_removeBuffEffects(player, buffType, buffData)
    
    -- Clean up timers
    if buffTimers[userId] and buffTimers[userId][buffType] then
        buffTimers[userId][buffType] = nil
    end
    
    -- Clean up connections
    if buffConnections[userId] and buffConnections[userId][buffType] then
        buffConnections[userId][buffType]:Disconnect()
        buffConnections[userId][buffType] = nil
    end
    
    -- Remove from active buffs
    activeBuffs[userId][buffType] = nil
    
    -- Notify client
    local remoteEvents = ReplicatedStorage:FindFirstChild("RemoteEvents")
    if remoteEvents and remoteEvents:FindFirstChild("BuffExpired") then
        remoteEvents.BuffExpired:FireClient(player, {
            type = buffType
        })
    end
    
    -- Update metrics
    buffMetrics.totalBuffsExpired = buffMetrics.totalBuffsExpired + 1
    
    print(string.format("🕐 Removed %s buff from %s", buffType, player.Name))
    
    return true
end

function BuffService:PurchaseBuff(player, buffType)
    local buffConfig = BUFF_TYPES[buffType]
    if not buffConfig then
        return false, "Invalid buff type"
    end
    
    -- Check if player has enough currency (requires ShopService)
    if self.ShopService then
        local canAfford, _newBalance = self.ShopService:CanAffordItem(player, buffConfig.price)
        if not canAfford then
            return false, "Insufficient funds"
        end
        
        -- Process purchase
        local purchaseSuccess = self.ShopService:ProcessPurchase(player, {
            itemType = "buff",
            itemId = buffType,
            price = buffConfig.price
        })
        
        if not purchaseSuccess then
            return false, "Purchase failed"
        end
    end
    
    -- Apply the buff
    local success, error = self:ApplyBuff(player, buffType, buffConfig.duration, "purchase")
    
    if success then
        print(string.format("💰 %s purchased %s buff for %d coins", player.Name, buffConfig.name, buffConfig.price))
        
        -- Update quest progress (if available)
        if self.QuestService then
            self.QuestService:UpdateProgress(player, "purchaseBuffs", 1)
        end
        
        return true
    else
        -- Refund on failure (if ShopService available)
        if self.ShopService then
            self.ShopService:RefundPurchase(player, buffConfig.price)
        end
        return false, error
    end
end

-- ========================================
-- BUFF EFFECT IMPLEMENTATIONS
-- ========================================

function BuffService:_applyBuffEffects(player, buffType, buffData)
    local character = player.Character
    if not character then
        return false
    end
    
    local humanoid = character:FindFirstChild("Humanoid")
    if not humanoid then
        return false
    end
    
    local userId = tostring(player.UserId)
    
    -- Apply effects based on buff type
    if buffType == "speedBoost" then
        -- Store original speed and apply boost
        buffData.originalWalkSpeed = humanoid.WalkSpeed
        humanoid.WalkSpeed = humanoid.WalkSpeed * BUFF_TYPES.speedBoost.speedMultiplier
        
    elseif buffType == "doubleJump" then
        -- Enable double jump functionality
        buffData.originalJumpPower = humanoid.JumpPower
        buffData.currentJumps = 0
        
        -- Create double jump connection
        local connection = humanoid.StateChanged:Connect(function(old, new)
            if new == Enum.HumanoidStateType.Landed then
                buffData.currentJumps = 0
            elseif new == Enum.HumanoidStateType.Jumping and buffData.currentJumps < BUFF_TYPES.doubleJump.maxJumps - 1 then
                task.delay(0.1, function()
                    if humanoid.Parent and humanoid:GetState() == Enum.HumanoidStateType.Freefall then
                        buffData.currentJumps = buffData.currentJumps + 1
                        humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
                    end
                end)
            end
        end)
        
        buffConnections[userId][buffType] = connection
        
    elseif buffType == "coinMagnet" then
        -- Create coin magnet effect
        local magnetConnection = RunService.Heartbeat:Connect(function()
            self:_updateCoinMagnet(player, buffData)
        end)
        
        buffConnections[userId][buffType] = magnetConnection
        
    elseif buffType == "invincibility" then
        -- Apply invincibility
        buffData.originalMaxHealth = humanoid.MaxHealth
        buffData.originalHealth = humanoid.Health
        humanoid.MaxHealth = math.huge
        humanoid.Health = math.huge
        
        -- Visual effect (optional)
        self:_createInvincibilityEffect(character)
        
    elseif buffType == "coinDoubler" then
        -- Flag for double coin rewards (handled by reward system)
        buffData.isActive = true
    end
    
    return true
end

function BuffService:_removeBuffEffects(player, buffType, buffData)
    local character = player.Character
    if not character then
        return
    end
    
    local humanoid = character:FindFirstChild("Humanoid")
    if not humanoid then
        return
    end
    
    -- Remove effects based on buff type
    if buffType == "speedBoost" and buffData.originalWalkSpeed then
        humanoid.WalkSpeed = buffData.originalWalkSpeed
        
    elseif buffType == "doubleJump" and buffData.originalJumpPower then
        humanoid.JumpPower = buffData.originalJumpPower
        
    elseif buffType == "invincibility" then
        if buffData.originalMaxHealth then
            humanoid.MaxHealth = buffData.originalMaxHealth
            humanoid.Health = math.min(humanoid.Health, buffData.originalMaxHealth)
        end
        
        -- Remove visual effect
        self:_removeInvincibilityEffect(character)
    end
end

-- ========================================
-- UTILITY AND HELPER METHODS
-- ========================================

function BuffService:_startBuffTimer(player, buffType, buffData)
    local _userId = tostring(player.UserId)
    
    -- Modern event-driven timer (NO POLLING)
    local function updateTimer()
        local timeRemaining = buffData.endTime - tick()
        
        if timeRemaining <= 0 then
            -- Buff expired
            self:RemoveBuff(player, buffType)
            return
        end
        
        -- Update client with remaining time
        local remoteEvents = ReplicatedStorage:FindFirstChild("RemoteEvents")
        if remoteEvents and remoteEvents:FindFirstChild("BuffTimeUpdate") then
            remoteEvents.BuffTimeUpdate:FireClient(player, {
                buffType = buffType,
                timeRemaining = timeRemaining
            })
        end
        
        -- Schedule next update
        task.delay(1, updateTimer)
    end
    
    updateTimer() -- Start the timer
end

function BuffService:_updateCoinMagnet(player, buffData)
    local character = player.Character
    if not character then return end
    
    local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
    if not humanoidRootPart then return end
    
    local magnetRadius = BUFF_TYPES.coinMagnet.effectRadius
    local magnetStrength = BUFF_TYPES.coinMagnet.magnetStrength
    
    -- Find nearby coins (assuming they have a specific tag or are in a folder)
    for _, coin in pairs(workspace:GetChildren()) do
        if coin.Name == "Coin" and coin:FindFirstChild("Position") then
            local distance = (coin.Position.Position - humanoidRootPart.Position).Magnitude
            
            if distance <= magnetRadius then
                -- Attract coin to player
                local direction = (humanoidRootPart.Position - coin.Position.Position).Unit
                local attractForce = direction * magnetStrength * (magnetRadius / distance)
                
                -- Apply force or teleport based on implementation
                coin.Position.Position = coin.Position.Position + attractForce
            end
        end
    end
end

function BuffService:_createInvincibilityEffect(character)
    local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
    if not humanoidRootPart then return end
    
    -- Create glowing effect
    local aura = Instance.new("SelectionBox")
    aura.Adornee = humanoidRootPart
    aura.Color3 = Color3.fromRGB(255, 215, 0) -- Gold color
    aura.LineThickness = 0.2
    aura.Transparency = 0.5
    aura.Parent = humanoidRootPart
    
    -- Pulsing animation
    local tween = TweenService:Create(aura, 
        TweenInfo.new(0.5, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true),
        {Transparency = 0.8}
    )
    tween:Play()
    
    -- Store references for cleanup
    humanoidRootPart:SetAttribute("InvincibilityAura", aura)
    humanoidRootPart:SetAttribute("InvincibilityTween", tween)
end

function BuffService:_removeInvincibilityEffect(character)
    local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
    if not humanoidRootPart then return end
    
    local aura = humanoidRootPart:GetAttribute("InvincibilityAura")
    local tween = humanoidRootPart:GetAttribute("InvincibilityTween")
    
    if tween then
        tween:Cancel()
    end
    
    if aura then
        aura:Destroy()
    end
    
    humanoidRootPart:SetAttribute("InvincibilityAura", nil)
    humanoidRootPart:SetAttribute("InvincibilityTween", nil)
end

function BuffService:_startPeriodicCleanup()
    -- Clean up expired buffs every 30 seconds
    local function performCleanup()
        local currentTime = tick()
        local expiredCount = 0
        
        for userId, userBuffs in pairs(activeBuffs) do
            for buffType, buffData in pairs(userBuffs) do
                if buffData.endTime <= currentTime then
                    local player = Players:GetPlayerByUserId(tonumber(userId))
                    if player then
                        self:RemoveBuff(player, buffType)
                        expiredCount = expiredCount + 1
                    end
                end
            end
        end
        
        if expiredCount > 0 then
            print(string.format("🧹 Cleaned up %d expired buffs", expiredCount))
        end
        
        -- Schedule next cleanup
        task.delay(30, performCleanup)
    end
    
    task.delay(30, performCleanup)
end

function BuffService:_startMetricsCollection()
    -- Collect and report metrics every 5 minutes
    local function collectMetrics()
        local activeBuffCount = 0
        for userId, userBuffs in pairs(activeBuffs) do
            for buffType, _ in pairs(userBuffs) do
                activeBuffCount = activeBuffCount + 1
            end
        end
        
        local uptime = tick() - buffMetrics.startTime
        
        print(string.format("📊 BuffService Metrics - Active: %d, Applied: %d, Expired: %d, Errors: %d, Uptime: %.1fs",
            activeBuffCount, buffMetrics.totalBuffsApplied, buffMetrics.totalBuffsExpired, 
            buffMetrics.totalErrors, uptime))
        
        -- Schedule next collection
        task.delay(300, collectMetrics)
    end
    
    task.delay(300, collectMetrics)
end

-- ========================================
-- PUBLIC API METHODS
-- ========================================

function BuffService:GetPlayerBuffs(player)
    local userId = tostring(player.UserId)
    return activeBuffs[userId] or {}
end

function BuffService:IsBuffActive(player, buffType)
    local userId = tostring(player.UserId)
    return activeBuffs[userId] and activeBuffs[userId][buffType] ~= nil
end

function BuffService:GetBuffTimeRemaining(player, buffType)
    local userId = tostring(player.UserId)
    local buffData = activeBuffs[userId] and activeBuffs[userId][buffType]
    
    if buffData then
        return math.max(0, buffData.endTime - tick())
    end
    
    return 0
end

function BuffService:GetBuffTypes()
    return BUFF_TYPES
end

function BuffService:GetServiceMetrics()
    return buffMetrics
end

-- Grant random buff (for rewards)
function BuffService:GrantRandomBuff(player, source)
    local totalChance = 0
    for _, chance in pairs(BUFF_DROP_CHANCES) do
        totalChance = totalChance + chance
    end
    
    local roll = math.random() * totalChance
    local currentChance = 0
    
    for buffType, chance in pairs(BUFF_DROP_CHANCES) do
        currentChance = currentChance + chance
        if roll <= currentChance then
            local duration = BUFF_TYPES[buffType].duration
            return self:ApplyBuff(player, buffType, duration, source or "random_reward")
        end
    end
    
    return false, "No buff selected"
end

return BuffService
