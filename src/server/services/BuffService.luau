-- BuffService.luau
-- Handles temporary buffs during gameplay and purchasable power-ups

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local SafeRequire = require(ReplicatedStorage.Shared.utils.SafeRequire)
local PlayerService = SafeRequire.require(script.Parent.core.PlayerService)
local MainGameService = SafeRequire.require(script.Parent.MainGameService)
local ShopService = SafeRequire.require(script.Parent.economy.ShopService)
local QuestService = SafeRequire.require(script.Parent.QuestService)
local RemoteEvents = SafeRequire.require(ReplicatedStorage.Shared.modules.RemoteEvents)

-- Use MainGameService as GameService for compatibility
local GameService = MainGameService

local BuffService = {}

-- Active buffs tracking
local activeBuffs = {} -- [userId] = {[buffType] = {data}}
local buffConnections = {} -- [userId] = {[buffType] = connection}

-- Buff configurations
local BUFF_TYPES = {
    coinMagnet = {
        name = "💰 Coin Magnet",
        description = "Automatically attracts nearby coins",
        duration = 30, -- seconds
        range = 20, -- studs
        effect = "magnetic_collection",
        visualEffect = "golden_aura",
        purchasePrice = 50, -- coins
        shopCategory = "powerups"
    },
    comboStreak = {
        name = "🔥 Combo Streak",
        description = "Double score multiplier while maintaining streak",
        duration = 45, -- seconds
        multiplier = 2.0,
        effect = "score_multiplier",
        visualEffect = "fire_aura",
        purchasePrice = 75, -- coins
        shopCategory = "powerups"
    },
    speedBoost = {
        name = "⚡ Speed Boost",
        description = "25% faster movement speed",
        duration = 25, -- seconds
        speedMultiplier = 1.25,
        effect = "movement_speed",
        visualEffect = "lightning_trail",
        purchasePrice = 40, -- coins
        shopCategory = "powerups"
    },
    shieldProtection = {
        name = "🛡️ Shield Protection",
        description = "Survive one barrier collision",
        duration = 60, -- seconds or until used
        effect = "collision_immunity",
        visualEffect = "shield_bubble",
        purchasePrice = 100, -- coins
        shopCategory = "powerups"
    },
    timeFreeze = {
        name = "❄️ Time Freeze",
        description = "Slow down barriers for easier navigation",
        duration = 15, -- seconds
        slowdownFactor = 0.6,
        effect = "world_slowdown",
        visualEffect = "ice_crystals",
        purchasePrice = 80, -- coins
        shopCategory = "powerups"
    },
    doubleCoins = {
        name = "💎 Double Coins",
        description = "Earn 2x coins from all sources",
        duration = 40, -- seconds
        multiplier = 2.0,
        effect = "coin_multiplier",
        visualEffect = "gem_sparkles",
        purchasePrice = 60, -- coins
        shopCategory = "powerups"
    }
}

-- Buff drop chances during gameplay
local BUFF_DROP_CHANCES = {
    onPerfectStreak = { -- After 5+ perfect barriers in a row
        coinMagnet = 0.15,
        comboStreak = 0.20,
        speedBoost = 0.10
    },
    onHighScore = { -- When beating personal best
        shieldProtection = 0.25,
        doubleCoins = 0.20,
        timeFreeze = 0.15
    },
    onLongRun = { -- After 2+ minutes of gameplay
        coinMagnet = 0.12,
        comboStreak = 0.18,
        speedBoost = 0.08
    },
    random = { -- Random chance every 30 seconds
        coinMagnet = 0.05,
        speedBoost = 0.03,
        doubleCoins = 0.04
    }
}

function BuffService:Init()
    print("💫 BuffService initializing...")
    
    -- Setup remote event handlers
    self:SetupRemoteEvents()
    
    -- Setup buff drop monitoring
    self:SetupBuffDropSystem()
    
    -- Register purchasable buffs in shop
    self:RegisterShopBuffs()
    
    print("✅ BuffService initialized with power-up system!")
end

function BuffService:SetupRemoteEvents()
    -- Handle buff purchases
    RemoteEvents.PurchaseBuff.OnServerEvent:Connect(function(player, buffType)
        self:PurchaseBuff(player, buffType)
    end)
    
    -- Handle buff activation requests
    RemoteEvents.ActivateBuff.OnServerEvent:Connect(function(player, buffType)
        self:ActivateBuff(player, buffType)
    end)
    
    -- Handle mid-game buff pickups
    RemoteEvents.CollectBuffPickup.OnServerEvent:Connect(function(player, buffId)
        self:CollectBuffPickup(player, buffId)
    end)
end

function BuffService:RegisterShopBuffs()
    if not ShopService then return end
    
    -- Register each buff as a purchasable item
    for buffType, buffConfig in pairs(BUFF_TYPES) do
        ShopService:RegisterItem({
            id = "buff_" .. buffType,
            name = buffConfig.name,
            description = buffConfig.description,
            price = buffConfig.purchasePrice,
            category = buffConfig.shopCategory,
            type = "buff",
            buffType = buffType,
            icon = self:GetBuffIcon(buffType)
        })
    end
end

function BuffService:GetBuffIcon(buffType)
    local icons = {
        coinMagnet = "💰",
        comboStreak = "🔥",
        speedBoost = "⚡",
        shieldProtection = "🛡️",
        timeFreeze = "❄️",
        doubleCoins = "💎"
    }
    return icons[buffType] or "✨"
end

function BuffService:PurchaseBuff(player, buffType)
    local buffConfig = BUFF_TYPES[buffType]
    if not buffConfig then return end
    
    local playerData = PlayerService:GetPlayerData(player)
    if not playerData then return end
    
    -- Check if player can afford the buff
    if playerData.coins < buffConfig.purchasePrice then
        RemoteEvents.ShowNotification:FireClient(player, {
            type = "error",
            title = "Insufficient Coins",
            message = "Need " .. buffConfig.purchasePrice .. " coins to purchase " .. buffConfig.name
        })
        return
    end
    
    -- Deduct coins
    playerData.coins = playerData.coins - buffConfig.purchasePrice
    PlayerService:UpdatePlayerData(player, playerData)
    
    -- Add buff to player's inventory (for use in next game)
    if not playerData.buffInventory then
        playerData.buffInventory = {}
    end
    
    playerData.buffInventory[buffType] = (playerData.buffInventory[buffType] or 0) + 1
    
    -- Track unique buffs purchased for quests
    local uniqueBuffTypes = 0
    for buffId, count in pairs(playerData.buffInventory) do
        if count > 0 then
            uniqueBuffTypes = uniqueBuffTypes + 1
        end
    end
    
    PlayerService:UpdatePlayerData(player, playerData)
    
    -- Update quest progress
    if QuestService then
        QuestService:UpdateQuestProgress(player, "buff_purchased", 1, {buffType = buffType})
        QuestService:UpdateQuestProgress(player, "unique_buffs_purchased", 1, {uniqueBuffTypes = uniqueBuffTypes})
    end
    
    -- Notify player
    RemoteEvents.ShowNotification:FireClient(player, {
        type = "success",
        title = "Buff Purchased!",
        message = buffConfig.name .. " added to inventory"
    })
    
    -- Update shop UI
    RemoteEvents.BuffPurchased:FireClient(player, buffType)
    
    print("💫 " .. player.Name .. " purchased " .. buffConfig.name)
end

function BuffService:ActivateBuff(player, buffType, duration)
    local buffConfig = BUFF_TYPES[buffType]
    if not buffConfig then return end
    
    local userId = tostring(player.UserId)
    
    -- Initialize player buffs if needed
    if not activeBuffs[userId] then
        activeBuffs[userId] = {}
        buffConnections[userId] = {}
    end
    
    -- Check if buff is already active
    if activeBuffs[userId][buffType] then
        -- Extend duration instead of stacking
        local currentBuff = activeBuffs[userId][buffType]
        currentBuff.endTime = tick() + (duration or buffConfig.duration)
        currentBuff.duration = duration or buffConfig.duration
        
        RemoteEvents.BuffUpdated:FireClient(player, {
            buffType = buffType,
            timeRemaining = currentBuff.endTime - tick(),
            isExtended = true
        })
        return
    end
    
    -- Create new buff
    local buffData = {
        buffType = buffType,
        startTime = tick(),
        endTime = tick() + (duration or buffConfig.duration),
        duration = duration or buffConfig.duration,
        config = buffConfig,
        player = player
    }
    
    activeBuffs[userId][buffType] = buffData
    
    -- Apply buff effects
    self:ApplyBuffEffects(player, buffType, buffData)
    
    -- Track buff usage for quests
    if QuestService then
        QuestService:UpdateQuestProgress(player, "buffs_used", 1, {buffType = buffType})
        
        -- Track specific buff usage
        if buffType == "timeFreeze" then
            QuestService:UpdateQuestProgress(player, "timefreeze_used", 1)
        end
    end
    
    -- Start buff timer
    self:StartBuffTimer(player, buffType, buffData)
    
    -- Notify client
    RemoteEvents.BuffActivated:FireClient(player, {
        buffType = buffType,
        duration = buffData.duration,
        config = buffConfig
    })
    
    -- Create visual effects
    self:CreateBuffVisualEffects(player, buffType)
    
    print("💫 Activated " .. buffConfig.name .. " for " .. player.Name)
end

function BuffService:ApplyBuffEffects(player, buffType, buffData)
    local character = player.Character
    if not character then return end
    
    local humanoid = character:FindFirstChildOfClass("Humanoid")
    local userId = tostring(player.UserId)
    
    if buffType == "coinMagnet" then
        self:StartCoinMagnetEffect(player, buffData)
    elseif buffType == "comboStreak" then
        self:StartComboStreakEffect(player, buffData)
    elseif buffType == "speedBoost" and humanoid then
        humanoid.WalkSpeed = humanoid.WalkSpeed * buffData.config.speedMultiplier
    elseif buffType == "shieldProtection" then
        self:StartShieldProtectionEffect(player, buffData)
    elseif buffType == "timeFreeze" then
        self:StartTimeFreezeEffect(player, buffData)
    elseif buffType == "doubleCoins" then
        self:StartDoubleCoinEffect(player, buffData)
    end
end

function BuffService:StartCoinMagnetEffect(player, buffData)
    local userId = tostring(player.UserId)
    local character = player.Character
    if not character then return end
    
    local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
    if not humanoidRootPart then return end
    
    -- Create coin magnet connection
    local connection = RunService.Heartbeat:Connect(function()
        if not activeBuffs[userId] or not activeBuffs[userId].coinMagnet then
            connection:Disconnect()
            return
        end
        
        -- Find nearby coins
        local coins = Workspace:GetDescendants()
        for _, obj in pairs(coins) do
            if obj.Name == "Coin" and obj:IsA("BasePart") then
                local distance = (obj.Position - humanoidRootPart.Position).Magnitude
                
                if distance <= buffData.config.range then
                    -- Attract coin towards player
                    local direction = (humanoidRootPart.Position - obj.Position).Unit
                    local attractSpeed = math.max(5, 20 - distance) -- Faster when closer
                    
                    local bodyVelocity = obj:FindFirstChild("BodyVelocity")
                    if not bodyVelocity then
                        bodyVelocity = Instance.new("BodyVelocity")
                        bodyVelocity.MaxForce = Vector3.new(4000, 4000, 4000)
                        bodyVelocity.Parent = obj
                    end
                    
                    bodyVelocity.Velocity = direction * attractSpeed
                    
                    -- Event-driven body velocity cleanup (NO POLLING)
                    task.delay(0.8, function() -- Slightly longer for better effect
                        if bodyVelocity and bodyVelocity.Parent then
                            bodyVelocity:Destroy()
                        end
                    end)
                end
            end
        end
    end)
    
    buffConnections[userId].coinMagnet = connection
end

function BuffService:StartComboStreakEffect(player, buffData)
    local userId = tostring(player.UserId)
    
    -- Track combo streak for score multiplier
    local comboCount = 0
    local lastSuccessTime = tick()
    
    -- Connect to game events for streak tracking
    local connection = RemoteEvents.BarrierPassed.OnServerEvent:Connect(function(eventPlayer, success)
        if eventPlayer ~= player then return end
        if not activeBuffs[userId] or not activeBuffs[userId].comboStreak then
            connection:Disconnect()
            return
        end
        
        if success then
            comboCount = comboCount + 1
            lastSuccessTime = tick()
            
            -- Apply score multiplier
            if GameService then
                GameService:ApplyScoreMultiplier(player, buffData.config.multiplier)
            end
            
            -- Show streak effect
            RemoteEvents.ShowStreakEffect:FireClient(player, {
                comboCount = comboCount,
                multiplier = buffData.config.multiplier
            })
            
            -- Track combo with buff for quests
            if QuestService and comboCount >= 10 then
                QuestService:UpdateQuestProgress(player, "combo_with_buff", comboCount, {
                    comboCount = comboCount,
                    hasComboStreakBuff = true
                })
            end
        else
            -- Reset combo on failure
            comboCount = 0
            if GameService then
                GameService:RemoveScoreMultiplier(player)
            end
        end
    end)
    
    buffConnections[userId].comboStreak = connection
end

function BuffService:StartShieldProtectionEffect(player, buffData)
    local userId = tostring(player.UserId)
    
    -- One-time collision protection
    local connection = RemoteEvents.BarrierCollision.OnServerEvent:Connect(function(eventPlayer)
        if eventPlayer ~= player then return end
        if not activeBuffs[userId] or not activeBuffs[userId].shieldProtection then
            connection:Disconnect()
            return
        end
        
        -- Prevent game over and remove shield
        RemoteEvents.ShieldActivated:FireClient(player)
        self:RemoveBuff(player, "shieldProtection")
        
        -- Update quest progress for shield usage
        if QuestService then
            QuestService:UpdateQuestProgress(player, "shield_used", 1, {shieldActivated = true})
        end
        
        -- Show dramatic shield break effect
        self:CreateShieldBreakEffect(player)
    end)
    
    buffConnections[userId].shieldProtection = connection
end

function BuffService:StartTimeFreezeEffect(player, buffData)
    -- Slow down all barriers in the game
    if GameService then
        GameService:SetGameSpeed(buffData.config.slowdownFactor)
    end
    
    -- Create time freeze visual effects
    self:CreateTimeFreezeEffect(player)
end

function BuffService:StartDoubleCoinEffect(player, buffData)
    local userId = tostring(player.UserId)
    
    -- Apply coin multiplier
    if GameService then
        GameService:SetCoinMultiplier(player, buffData.config.multiplier)
    end
end

function BuffService:StartBuffTimer(player, buffType, buffData)
    local userId = tostring(player.UserId)
    
    -- Event-driven timer (NO POLLING)
    local function updateTimer()
        local timeRemaining = buffData.endTime - tick()
        
        if timeRemaining <= 0 then
            -- Buff expired
            self:RemoveBuff(player, buffType)
            return
        end
        
        -- Update client with remaining time
        RemoteEvents.BuffTimeUpdate:FireClient(player, {
            buffType = buffType,
            timeRemaining = timeRemaining
        })
        
        -- Schedule next update
        task.delay(1, updateTimer)
    end
    
    updateTimer() -- Start the timer
end

function BuffService:RemoveBuff(player, buffType)
    local userId = tostring(player.UserId)
    
    if not activeBuffs[userId] or not activeBuffs[userId][buffType] then return end
    
    local buffData = activeBuffs[userId][buffType]
    local character = player.Character
    
    -- Remove buff effects
    if buffType == "speedBoost" and character then
        local humanoid = character:FindFirstChildOfClass("Humanoid")
        if humanoid then
            humanoid.WalkSpeed = humanoid.WalkSpeed / buffData.config.speedMultiplier
        end
    elseif buffType == "timeFreeze" then
        if GameService then
            GameService:SetGameSpeed(1.0) -- Reset to normal speed
        end
    elseif buffType == "doubleCoins" then
        if GameService then
            GameService:SetCoinMultiplier(player, 1.0) -- Reset to normal
        end
    elseif buffType == "comboStreak" then
        if GameService then
            GameService:RemoveScoreMultiplier(player)
        end
    end
    
    -- Disconnect buff connection
    if buffConnections[userId] and buffConnections[userId][buffType] then
        buffConnections[userId][buffType]:Disconnect()
        buffConnections[userId][buffType] = nil
    end
    
    -- Remove from active buffs
    activeBuffs[userId][buffType] = nil
    
    -- Notify client
    RemoteEvents.BuffExpired:FireClient(player, {
        buffType = buffType,
        config = buffData.config
    })
    
    -- Remove visual effects
    self:RemoveBuffVisualEffects(player, buffType)
    
    print("💫 " .. buffData.config.name .. " expired for " .. player.Name)
end

function BuffService:CreateBuffVisualEffects(player, buffType)
    local character = player.Character
    if not character then return end
    
    local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
    if not humanoidRootPart then return end
    
    -- Create buff aura based on type
    local aura = Instance.new("Part")
    aura.Name = "BuffAura_" .. buffType
    aura.Size = Vector3.new(8, 8, 8)
    aura.Position = humanoidRootPart.Position
    aura.Shape = Enum.PartType.Ball
    aura.Material = Enum.Material.Neon
    aura.CanCollide = false
    aura.Anchored = true
    aura.Transparency = 0.7
    aura.Parent = character
    
    -- Set color based on buff type
    local colors = {
        coinMagnet = Color3.new(1, 0.8, 0), -- Gold
        comboStreak = Color3.new(1, 0.3, 0), -- Orange/Fire
        speedBoost = Color3.new(0.3, 0.8, 1), -- Electric Blue
        shieldProtection = Color3.new(0.3, 0.8, 0.3), -- Green
        timeFreeze = Color3.new(0.7, 0.9, 1), -- Ice Blue
        doubleCoins = Color3.new(0.8, 0.3, 1) -- Purple
    }
    
    aura.Color = colors[buffType] or Color3.new(1, 1, 1)
    
    -- Animate aura
    local pulseConnection = RunService.Heartbeat:Connect(function()
        if not aura.Parent then
            pulseConnection:Disconnect()
            return
        end
        
        local time = tick()
        local pulse = 0.5 + 0.3 * math.sin(time * 3)
        aura.Transparency = 0.4 + pulse * 0.3
        aura.Size = Vector3.new(6 + pulse * 2, 6 + pulse * 2, 6 + pulse * 2)
        
        -- Follow player
        if humanoidRootPart.Parent then
            aura.Position = humanoidRootPart.Position
        end
    end)
    
    -- Store connection for cleanup
    aura:SetAttribute("PulseConnection", pulseConnection)
end

function BuffService:RemoveBuffVisualEffects(player, buffType)
    local character = player.Character
    if not character then return end
    
    local aura = character:FindFirstChild("BuffAura_" .. buffType)
    if aura then
        local connection = aura:GetAttribute("PulseConnection")
        if connection then
            connection:Disconnect()
        end
        aura:Destroy()
    end
end

function BuffService:CreateShieldBreakEffect(player)
    -- Create dramatic shield break effect
    RemoteEvents.CreateEffect:FireClient(player, {
        effectType = "shieldBreak",
        position = player.Character.HumanoidRootPart.Position,
        duration = 2
    })
end

function BuffService:CreateTimeFreezeEffect(player)
    -- Create time freeze visual effect
    RemoteEvents.CreateEffect:FireClient(player, {
        effectType = "timeFreeze",
        duration = 15
    })
end

function BuffService:SetupBuffDropSystem()
    -- Monitor game events for buff drops
    if GameService then
        -- Connect to game events that can trigger buff drops
        GameService.OnPerfectStreak:Connect(function(player, streakCount)
            if streakCount >= 5 then
                self:CheckBuffDrop(player, "onPerfectStreak")
            end
        end)
        
        GameService.OnHighScore:Connect(function(player, newScore)
            self:CheckBuffDrop(player, "onHighScore")
        end)
        
        GameService.OnLongRun:Connect(function(player, runTime)
            if runTime >= 120 then -- 2 minutes
                self:CheckBuffDrop(player, "onLongRun")
            end
        end)
    end
    
    -- CONVERTED: Random buff drops → Event-driven with adaptive intervals
    local BuffDropEvent = Instance.new("BindableEvent")
    local dropInterval = 30 -- Start with 30 seconds
    
    local function scheduleBuffDrop()
        task.delay(dropInterval, function()
            BuffDropEvent:Fire()
            scheduleBuffDrop()
        end)
    end
    
    BuffDropEvent.Event:Connect(function()
        local activePlayers = 0
        local buffDrops = 0
        
        for _, player in pairs(Players:GetPlayers()) do
            if GameService and GameService:IsPlayerInGame(player) then
                activePlayers = activePlayers + 1
                local dropped = self:CheckBuffDrop(player, "random")
                if dropped then
                    buffDrops = buffDrops + 1
                end
            end
        end
        
        -- Adaptive interval based on player activity and buff success
        if activePlayers == 0 then
            dropInterval = 120 -- No active players, much less frequent
        elseif activePlayers > 5 then
            dropInterval = math.max(15, dropInterval * 0.9) -- More players, slightly more frequent
        else
            dropInterval = math.min(60, dropInterval * 1.1) -- Fewer players, less frequent
        end
        
        -- Adjust based on buff drop success rate
        if buffDrops > activePlayers * 0.3 then -- High success rate
            dropInterval = math.min(45, dropInterval * 1.2) -- Slow down when dropping too many
        elseif buffDrops == 0 and activePlayers > 0 then -- No drops with active players
            dropInterval = math.max(20, dropInterval * 0.95) -- Speed up slightly
        end
        
        print(string.format("🎁 Random buff check: %d drops for %d players (next in %.0fs)", 
            buffDrops, activePlayers, dropInterval))
    end)
    
    scheduleBuffDrop()
    print("✅ Random buff drops converted to event-driven system (NO POLLING)")
end

function BuffService:CheckBuffDrop(player, triggerType)
    local dropChances = BUFF_DROP_CHANCES[triggerType]
    if not dropChances then return end
    
    -- Roll for each possible buff
    for buffType, chance in pairs(dropChances) do
        if math.random() <= chance then
            self:DropBuff(player, buffType)
            break -- Only one buff per trigger
        end
    end
end

function BuffService:DropBuff(player, buffType)
    local character = player.Character
    if not character then return end
    
    local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
    if not humanoidRootPart then return end
    
    -- Create buff pickup in the world
    local pickup = Instance.new("Part")
    pickup.Name = "BuffPickup_" .. buffType
    pickup.Size = Vector3.new(3, 3, 3)
    pickup.Shape = Enum.PartType.Ball
    pickup.Material = Enum.Material.Neon
    pickup.CanCollide = false
    pickup.Anchored = true
    pickup.Position = humanoidRootPart.Position + Vector3.new(0, 5, 0)
    pickup.Parent = Workspace
    
    -- Set visual style based on buff
    local colors = {
        coinMagnet = Color3.new(1, 0.8, 0),
        comboStreak = Color3.new(1, 0.3, 0),
        speedBoost = Color3.new(0.3, 0.8, 1),
        shieldProtection = Color3.new(0.3, 0.8, 0.3),
        timeFreeze = Color3.new(0.7, 0.9, 1),
        doubleCoins = Color3.new(0.8, 0.3, 1)
    }
    pickup.Color = colors[buffType] or Color3.new(1, 1, 1)
    
    -- Add pickup detection
    local clickDetector = Instance.new("ClickDetector")
    clickDetector.MaxActivationDistance = 15
    clickDetector.Parent = pickup
    
    -- Add floating animation
    local floatTween = TweenService:Create(
        pickup,
        TweenInfo.new(2, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true),
        {Position = pickup.Position + Vector3.new(0, 2, 0)}
    )
    floatTween:Play()
    
    -- Handle pickup collection
    clickDetector.MouseClick:Connect(function(clickPlayer)
        if clickPlayer == player then
            self:CollectBuffPickup(player, buffType)
            pickup:Destroy()
        end
    end)
    
    -- Auto-remove after 15 seconds
    game:GetService("Debris"):AddItem(pickup, 15)
    
    -- Notify player
    RemoteEvents.ShowNotification:FireClient(player, {
        type = "info",
        title = "Buff Available!",
        message = BUFF_TYPES[buffType].name .. " - Click to collect!"
    })
end

function BuffService:CollectBuffPickup(player, buffType)
    -- Activate the buff immediately
    self:ActivateBuff(player, buffType)
    
    -- Show collection effect
    RemoteEvents.ShowNotification:FireClient(player, {
        type = "success",
        title = "Buff Collected!",
        message = BUFF_TYPES[buffType].name .. " activated!"
    })
    
    print("💫 " .. player.Name .. " collected " .. BUFF_TYPES[buffType].name .. " pickup")
end

function BuffService:GetActiveBuffs(player)
    local userId = tostring(player.UserId)
    return activeBuffs[userId] or {}
end

function BuffService:HasActiveBuff(player, buffType)
    local userId = tostring(player.UserId)
    return activeBuffs[userId] and activeBuffs[userId][buffType] ~= nil
end

-- Handle player leaving cleanup
Players.PlayerRemoving:Connect(function(player)
    local userId = tostring(player.UserId)
    
    -- Clean up active buffs
    if activeBuffs[userId] then
        for buffType, _ in pairs(activeBuffs[userId]) do
            BuffService:RemoveBuff(player, buffType)
        end
        activeBuffs[userId] = nil
    end
    
    -- Clean up connections
    if buffConnections[userId] then
        for _, connection in pairs(buffConnections[userId]) do
            if connection then
                connection:Disconnect()
            end
        end
        buffConnections[userId] = nil
    end
end)

return BuffService
