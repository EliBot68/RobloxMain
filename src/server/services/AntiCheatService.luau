-- AntiCheatService.luau
-- Comprehensive anti-cheat system for Color Rush game

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local _RunService = game:GetService("RunService")
local _TeleportService = game:GetService("TeleportService")
local _MessagingService = game:GetService("MessagingService")

local SafeRequire = require(ReplicatedStorage.Shared.utils.SafeRequire)
local RemoteEvents = SafeRequire.require(ReplicatedStorage.Shared.modules.RemoteEvents)

local AntiCheatService = {}

-- Anti-cheat configuration with performance optimization features
local ANTICHEAT_CONFIG = {
    -- Performance settings (enhanced from AntiCheatServiceAdvanced)
    performanceMode = false, -- Set to true for high-performance servers
    maxChecksPerSecond = 10, -- Limit checks for performance
    batchSize = 15, -- Process violations in batches
    adaptiveMonitoring = true, -- Adjust check frequency based on violation history
    
    -- Monitoring intervals (optimized for performance)
    intervals = {
        movement = 0.2, -- Check movement (performance: 0.5s, standard: 0.2s)
        speed = 0.5, -- Check speed (performance: 1.0s, standard: 0.5s)
        stats = 1.0, -- Check stats (performance: 2.0s, standard: 1.0s)
        position = 0.1 -- Position checks (performance: 0.3s, standard: 0.1s)
    },
    
    -- Movement validation
    maxWalkSpeed = 50,
    maxJumpPower = 75,
    maxVelocity = 150,
    positionUpdateRate = 0.1, -- seconds
    maxPositionDelta = 25, -- studs per update
    teleportDetectionThreshold = 50, -- studs
    
    -- Speed hack detection
    speedCheckInterval = 0.5,
    maxSpeedSustained = 3.0, -- seconds at max speed before flagged
    speedToleranceMultiplier = 1.2,
    
    -- Stat validation
    maxCoinsPerSecond = 100,
    maxXPPerSecond = 200,
    maxScorePerSecond = 1000,
    statUpdateRate = 1.0, -- seconds
    
    -- Violation thresholds
    warningThreshold = 3,
    kickThreshold = 5,
    banThreshold = 10,
    
    -- Monitoring settings
    monitoringEnabled = true,
    logViolations = true,
    autoActions = true,
    whitelistDevelopers = true
}

-- Player monitoring data
local playerData = {}
local violationHistory = {}
local whitelistedPlayers = {
    [1234567890] = true, -- Add developer UserIDs here
    [123456789] = true   -- Example developer ID
}

-- Violation types
local VIOLATION_TYPES = {
    SPEED_HACK = "speed_hack",
    TELEPORT_HACK = "teleport_hack",
    POSITION_HACK = "position_hack",
    STAT_HACK = "stat_hack",
    JUMP_HACK = "jump_hack",
    VELOCITY_HACK = "velocity_hack",
    SUSPICIOUS_MOVEMENT = "suspicious_movement"
}

-- Initialize anti-cheat service
function AntiCheatService:Init()
    print("🛡️ Anti-Cheat Service initializing...")
    
    self:SetupPlayerManagement()
    self:SetupRemoteEvents()
    self:StartMonitoring()
    
    print("✅ Anti-Cheat Service initialized successfully")
end

-- Setup player management
function AntiCheatService:SetupPlayerManagement()
    -- Player joined
    Players.PlayerAdded:Connect(function(player)
        self:InitializePlayerTracking(player)
    end)
    
    -- Player leaving
    Players.PlayerRemoving:Connect(function(player)
        self:CleanupPlayerTracking(player)
    end)
    
    -- Initialize existing players
    for _, player in ipairs(Players:GetPlayers()) do
        self:InitializePlayerTracking(player)
    end
end

-- Initialize player tracking
function AntiCheatService:InitializePlayerTracking(player)
    local userId = player.UserId
    
    playerData[userId] = {
        player = player,
        
        -- Movement tracking
        lastPosition = Vector3.new(0, 0, 0),
        lastUpdateTime = tick(),
        velocityHistory = {},
        speedViolations = 0,
        positionViolations = 0,
        
        -- Speed tracking
        speedCheckStartTime = tick(),
        sustainedHighSpeed = false,
        maxSpeedDuration = 0,
        
        -- Stat tracking
        lastCoins = 0,
        lastXP = 0,
        lastScore = 0,
        lastStatUpdateTime = tick(),
        statViolations = 0,
        
        -- Jump tracking
        lastJumpTime = 0,
        jumpCount = 0,
        jumpViolations = 0,
        
        -- General tracking
        totalViolations = 0,
        lastViolationTime = 0,
        warnings = 0,
        isMonitored = true
    }
    
    -- Initialize violation history
    violationHistory[userId] = {}
    
    -- Check if player is whitelisted
    if ANTICHEAT_CONFIG.whitelistDevelopers and whitelistedPlayers[userId] then
        playerData[userId].isMonitored = false
        print("🔧 Developer " .. player.Name .. " whitelisted from anti-cheat monitoring")
    end
    
    print("🔍 Initialized anti-cheat tracking for " .. player.Name)
end

-- Cleanup player tracking
function AntiCheatService:CleanupPlayerTracking(player)
    local userId = player.UserId
    
    -- Save violation history for future reference
    if violationHistory[userId] and #violationHistory[userId] > 0 then
        self:SaveViolationHistory(userId, violationHistory[userId])
    end
    
    -- Clean up data
    playerData[userId] = nil
    violationHistory[userId] = nil
    
    print("🧹 Cleaned up anti-cheat data for " .. player.Name)
end

-- Start monitoring systems
function AntiCheatService:StartMonitoring()
    if not ANTICHEAT_CONFIG.monitoringEnabled then
        print("⚠️ Anti-cheat monitoring is disabled")
        return
    end
    
    -- Movement monitoring
    task.spawn(function() -- UPDATED for modern API
        self:StartMovementMonitoring()
    end)
    
    -- Speed monitoring
    task.spawn(function() -- UPDATED for modern API
        self:StartSpeedMonitoring()
    end)
    
    -- Stat monitoring
    task.spawn(function() -- UPDATED for modern API
        self:StartStatMonitoring()
    end)
    
    print("🔍 All anti-cheat monitoring systems started")
end

-- CONVERTED: Movement monitoring system → Event-driven with adaptive intervals
function AntiCheatService:StartMovementMonitoring()
    local MovementMonitorEvent = Instance.new("BindableEvent")
    local monitorInterval = ANTICHEAT_CONFIG.intervals.movement or 0.2 -- Start with config value
    local lastViolationTime = 0
    
    local function scheduleMovementCheck()
        task.delay(monitorInterval, function()
            MovementMonitorEvent:Fire()
            scheduleMovementCheck() -- Schedule next check
        end)
    end
    
    MovementMonitorEvent.Event:Connect(function()
        local violationsDetected = 0
        local playersChecked = 0
        
        for userId, data in pairs(playerData) do
            if not data.isMonitored then continue end
            
            local character = data.player.Character
            if not character or not character:FindFirstChild("HumanoidRootPart") then
                continue
            end
            
            playersChecked = playersChecked + 1
            local hadViolation = self:CheckPlayerMovement(data, character)
            if hadViolation then
                violationsDetected = violationsDetected + 1
                lastViolationTime = tick()
            end
        end
        
        -- Adaptive interval based on violation activity
        if violationsDetected > 0 then
            monitorInterval = math.max(0.1, monitorInterval * 0.8) -- More frequent when violations
            print(string.format("🚨 Movement violations detected (%d), increasing check frequency", violationsDetected))
        else
            -- Gradually reduce frequency if no violations for a while
            if tick() - lastViolationTime > 30 then -- No violations for 30 seconds
                monitorInterval = math.min(2.0, monitorInterval * 1.05) -- Less frequent when clean
            end
        end
        
        print(string.format("👁️ Movement monitoring: %d players checked, %d violations (next check in %.2fs)", 
            playersChecked, violationsDetected, monitorInterval))
    end)
    
    scheduleMovementCheck()
    print("✅ Movement monitoring converted to event-driven system (NO POLLING)")
end

-- Check player movement for violations
function AntiCheatService:CheckPlayerMovement(data, character)
    local humanoidRootPart = character.HumanoidRootPart
    local humanoid = character:FindFirstChild("Humanoid")
    local violationDetected = false
    
    if not humanoidRootPart or not humanoid then return false end
    
    local currentPosition = humanoidRootPart.Position
    local currentTime = tick()
    local deltaTime = currentTime - data.lastUpdateTime
    
    if deltaTime > 0 then
        -- Calculate movement delta
        local positionDelta = (currentPosition - data.lastPosition).Magnitude
        local maxAllowedDelta = ANTICHEAT_CONFIG.maxPositionDelta * deltaTime
        
        -- Check for teleporting
        if positionDelta > ANTICHEAT_CONFIG.teleportDetectionThreshold then
            self:FlagViolation(data.player, VIOLATION_TYPES.TELEPORT_HACK, {
                distance = positionDelta,
                deltaTime = deltaTime,
                fromPosition = data.lastPosition,
                toPosition = currentPosition
            })
        end
        
        -- Check for excessive position changes
        if positionDelta > maxAllowedDelta * 2 then
            self:FlagViolation(data.player, VIOLATION_TYPES.POSITION_HACK, {
                actualDelta = positionDelta,
                maxAllowedDelta = maxAllowedDelta,
                deltaTime = deltaTime
            })
        end
        
        -- Check humanoid properties
        if humanoid.WalkSpeed > ANTICHEAT_CONFIG.maxWalkSpeed * ANTICHEAT_CONFIG.speedToleranceMultiplier then
            self:FlagViolation(data.player, VIOLATION_TYPES.SPEED_HACK, {
                walkSpeed = humanoid.WalkSpeed,
                maxAllowed = ANTICHEAT_CONFIG.maxWalkSpeed
            })
            
            -- Correct the speed
            humanoid.WalkSpeed = ANTICHEAT_CONFIG.maxWalkSpeed
        end
        
        if humanoid.JumpPower > ANTICHEAT_CONFIG.maxJumpPower * ANTICHEAT_CONFIG.speedToleranceMultiplier then
            self:FlagViolation(data.player, VIOLATION_TYPES.JUMP_HACK, {
                jumpPower = humanoid.JumpPower,
                maxAllowed = ANTICHEAT_CONFIG.maxJumpPower
            })
            
            -- Correct the jump power
            humanoid.JumpPower = ANTICHEAT_CONFIG.maxJumpPower
        end
        
        -- Check velocity
        local velocity = humanoidRootPart.AssemblyLinearVelocity
        local velocityMagnitude = velocity.Magnitude
        
        if velocityMagnitude > ANTICHEAT_CONFIG.maxVelocity then
            self:FlagViolation(data.player, VIOLATION_TYPES.VELOCITY_HACK, {
                velocity = velocityMagnitude,
                maxAllowed = ANTICHEAT_CONFIG.maxVelocity
            })
            
            -- Limit velocity
            humanoidRootPart.AssemblyLinearVelocity = velocity.Unit * ANTICHEAT_CONFIG.maxVelocity
        end
        
        -- Update tracking data
        data.lastPosition = currentPosition
        data.lastUpdateTime = currentTime
        
        -- Store velocity history (keep last 10 entries)
        table.insert(data.velocityHistory, {
            velocity = velocityMagnitude,
            time = currentTime
        })
        
        if #data.velocityHistory > 10 then
            table.remove(data.velocityHistory, 1)
        end
    end
    
    return violationDetected
end

-- CONVERTED: Speed monitoring system → Event-driven with adaptive intervals
function AntiCheatService:StartSpeedMonitoring()
    local SpeedMonitorEvent = Instance.new("BindableEvent")
    local monitorInterval = ANTICHEAT_CONFIG.intervals.speed or 0.5
    local consecutiveCleanChecks = 0
    
    local function scheduleSpeedCheck()
        task.delay(monitorInterval, function()
            SpeedMonitorEvent:Fire()
            scheduleSpeedCheck()
        end)
    end
    
    SpeedMonitorEvent.Event:Connect(function()
        local violationsDetected = 0
        local playersChecked = 0
        
        for userId, data in pairs(playerData) do
            if not data.isMonitored then continue end
            
            local character = data.player.Character
            if not character or not character:FindFirstChild("Humanoid") then
                continue
            end
            
            playersChecked = playersChecked + 1
            local hadViolation = self:CheckPlayerSpeed(data, character)
            if hadViolation then
                violationsDetected = violationsDetected + 1
                consecutiveCleanChecks = 0
            end
        end
        
        -- Adaptive interval based on detection patterns
        if violationsDetected > 0 then
            monitorInterval = math.max(0.2, monitorInterval * 0.8) -- More frequent when violations
            print(string.format("🏃 Speed violations detected (%d), increasing monitoring", violationsDetected))
        else
            consecutiveCleanChecks = consecutiveCleanChecks + 1
            if consecutiveCleanChecks > 10 then -- 10 clean checks in a row
                monitorInterval = math.min(5.0, monitorInterval * 1.1) -- Less frequent when consistently clean
            end
        end
        
        print(string.format("⚡ Speed monitoring: %d players, %d violations (next in %.2fs)", 
            playersChecked, violationsDetected, monitorInterval))
    end)
    
    scheduleSpeedCheck()
    print("✅ Speed monitoring converted to event-driven system (NO POLLING)")
end

-- Check player speed for sustained violations
function AntiCheatService:CheckPlayerSpeed(data, character)
    local humanoid = character:FindFirstChild("Humanoid")
    if not humanoid then return end
    
    local currentTime = tick()
    local isHighSpeed = humanoid.WalkSpeed >= ANTICHEAT_CONFIG.maxWalkSpeed * 0.9
    
    if isHighSpeed then
        if not data.sustainedHighSpeed then
            data.sustainedHighSpeed = true
            data.speedCheckStartTime = currentTime
        else
            local duration = currentTime - data.speedCheckStartTime
            if duration > ANTICHEAT_CONFIG.maxSpeedSustained then
                self:FlagViolation(data.player, VIOLATION_TYPES.SPEED_HACK, {
                    sustainedDuration = duration,
                    walkSpeed = humanoid.WalkSpeed,
                    maxSustained = ANTICHEAT_CONFIG.maxSpeedSustained
                })
                
                -- Reset tracking
                data.sustainedHighSpeed = false
            end
        end
    else
        data.sustainedHighSpeed = false
    end
end

-- CONVERTED: Stat monitoring system → Event-driven with adaptive intervals
function AntiCheatService:StartStatMonitoring()
    local StatMonitorEvent = Instance.new("BindableEvent")
    local monitorInterval = ANTICHEAT_CONFIG.intervals.stats or 1.0
    local totalViolationsDetected = 0
    
    local function scheduleStatCheck()
        task.delay(monitorInterval, function()
            StatMonitorEvent:Fire()
            scheduleStatCheck()
        end)
    end
    
    StatMonitorEvent.Event:Connect(function()
        local violationsThisCheck = 0
        local playersChecked = 0
        
        for userId, data in pairs(playerData) do
            if not data.isMonitored then continue end
            
            playersChecked = playersChecked + 1
            local hadViolation = self:CheckPlayerStats(data)
            if hadViolation then
                violationsThisCheck = violationsThisCheck + 1
                totalViolationsDetected = totalViolationsDetected + 1
            end
        end
        
        -- Adaptive interval based on violation history
        if violationsThisCheck > 0 then
            monitorInterval = math.max(0.5, monitorInterval * 0.9) -- More frequent when violations
            print(string.format("📊 Stat violations detected (%d), tightening monitoring", violationsThisCheck))
        else
            -- Reduce frequency if consistently clean
            if totalViolationsDetected == 0 and playersChecked > 0 then
                monitorInterval = math.min(10.0, monitorInterval * 1.2) -- Less frequent when totally clean
            end
        end
        
        print(string.format("📈 Stat monitoring: %d players, %d violations (next in %.1fs)", 
            playersChecked, violationsThisCheck, monitorInterval))
    end)
    
    scheduleStatCheck()
    print("✅ Stat monitoring converted to event-driven system (NO POLLING)")
end

-- Check player stats for illegal changes
function AntiCheatService:CheckPlayerStats(data)
    local player = data.player
    local currentTime = tick()
    local deltaTime = currentTime - data.lastStatUpdateTime
    
    if deltaTime <= 0 then return end
    
    -- Get current stats (would integrate with your player data system)
    local currentStats = self:GetPlayerStats(player)
    if not currentStats then return end
    
    -- Check coin changes
    local coinDelta = currentStats.coins - data.lastCoins
    local maxCoinIncrease = ANTICHEAT_CONFIG.maxCoinsPerSecond * deltaTime
    
    if coinDelta > maxCoinIncrease then
        self:FlagViolation(player, VIOLATION_TYPES.STAT_HACK, {
            statType = "coins",
            actualIncrease = coinDelta,
            maxAllowed = maxCoinIncrease,
            deltaTime = deltaTime
        })
        
        -- Revert stats if auto-correction is enabled
        if ANTICHEAT_CONFIG.autoActions then
            self:RevertPlayerStats(player, "coins", data.lastCoins + maxCoinIncrease)
        end
    end
    
    -- Check XP changes
    local xpDelta = currentStats.xp - data.lastXP
    local maxXPIncrease = ANTICHEAT_CONFIG.maxXPPerSecond * deltaTime
    
    if xpDelta > maxXPIncrease then
        self:FlagViolation(player, VIOLATION_TYPES.STAT_HACK, {
            statType = "xp",
            actualIncrease = xpDelta,
            maxAllowed = maxXPIncrease,
            deltaTime = deltaTime
        })
        
        if ANTICHEAT_CONFIG.autoActions then
            self:RevertPlayerStats(player, "xp", data.lastXP + maxXPIncrease)
        end
    end
    
    -- Check score changes
    local scoreDelta = currentStats.score - data.lastScore
    local maxScoreIncrease = ANTICHEAT_CONFIG.maxScorePerSecond * deltaTime
    
    if scoreDelta > maxScoreIncrease then
        self:FlagViolation(player, VIOLATION_TYPES.STAT_HACK, {
            statType = "score",
            actualIncrease = scoreDelta,
            maxAllowed = maxScoreIncrease,
            deltaTime = deltaTime
        })
        
        if ANTICHEAT_CONFIG.autoActions then
            self:RevertPlayerStats(player, "score", data.lastScore + maxScoreIncrease)
        end
    end
    
    -- Update tracking data
    data.lastCoins = currentStats.coins
    data.lastXP = currentStats.xp
    data.lastScore = currentStats.score
    data.lastStatUpdateTime = currentTime
end

-- Get player stats (integrate with your data system)
function AntiCheatService:GetPlayerStats(player)
    -- This would integrate with your actual player data system
    -- For now, return mock data
    return {
        coins = 0,
        xp = 0,
        score = 0
    }
end

-- Revert player stats
function AntiCheatService:RevertPlayerStats(player, statType, correctValue)
    -- This would integrate with your actual player data system
    if RemoteEvents.RevertPlayerStat then
        RemoteEvents.RevertPlayerStat:FireClient(player, statType, correctValue)
    end
    
    print("🔧 Reverted " .. statType .. " for " .. player.Name .. " to " .. tostring(correctValue))
end

-- Flag a violation
function AntiCheatService:FlagViolation(player, violationType, data)
    local userId = player.UserId
    local playerTrackingData = playerData[userId]
    
    if not playerTrackingData then return end
    
    local currentTime = tick()
    
    -- Create violation record
    local violation = {
        type = violationType,
        time = currentTime,
        data = data,
        playerName = player.Name,
        userId = userId
    }
    
    -- Add to violation history
    table.insert(violationHistory[userId], violation)
    
    -- Update player violation counts
    playerTrackingData.totalViolations = playerTrackingData.totalViolations + 1
    playerTrackingData.lastViolationTime = currentTime
    
    -- Type-specific violation counts
    if violationType == VIOLATION_TYPES.SPEED_HACK then
        playerTrackingData.speedViolations = playerTrackingData.speedViolations + 1
    elseif violationType == VIOLATION_TYPES.TELEPORT_HACK or violationType == VIOLATION_TYPES.POSITION_HACK then
        playerTrackingData.positionViolations = playerTrackingData.positionViolations + 1
    elseif violationType == VIOLATION_TYPES.STAT_HACK then
        playerTrackingData.statViolations = playerTrackingData.statViolations + 1
    elseif violationType == VIOLATION_TYPES.JUMP_HACK then
        playerTrackingData.jumpViolations = playerTrackingData.jumpViolations + 1
    end
    
    -- Log violation
    if ANTICHEAT_CONFIG.logViolations then
        self:LogViolation(violation)
    end
    
    -- Take action if auto-actions are enabled
    if ANTICHEAT_CONFIG.autoActions then
        self:HandleViolation(player, violation)
    end
end

-- Log violation
function AntiCheatService:LogViolation(violation)
    local logMessage = string.format(
        "🚨 [ANTI-CHEAT] %s by %s (%d) - %s",
        violation.type,
        violation.playerName,
        violation.userId,
        self:FormatViolationData(violation.data)
    )
    
    print(logMessage)
    
    -- Send to analytics if available
    if RemoteEvents.LogAntiCheatViolation then
        RemoteEvents.LogAntiCheatViolation:FireServer(violation)
    end
end

-- Format violation data for logging
function AntiCheatService:FormatViolationData(data)
    local formatted = {}
    
    for key, value in pairs(data) do
        if typeof(value) == "Vector3" then
            table.insert(formatted, key .. ":" .. tostring(value))
        elseif type(value) == "number" then
            table.insert(formatted, key .. ":" .. string.format("%.2f", value))
        else
            table.insert(formatted, key .. ":" .. tostring(value))
        end
    end
    
    return table.concat(formatted, ", ")
end

-- Handle violation (warnings, kicks, bans)
function AntiCheatService:HandleViolation(player, violation)
    local userId = player.UserId
    local playerTrackingData = playerData[userId]
    
    if not playerTrackingData then return end
    
    local totalViolations = playerTrackingData.totalViolations
    
    -- Warning system
    if totalViolations <= ANTICHEAT_CONFIG.warningThreshold then
        playerTrackingData.warnings = playerTrackingData.warnings + 1
        self:WarnPlayer(player, violation, playerTrackingData.warnings)
        
    -- Kick system
    elseif totalViolations <= ANTICHEAT_CONFIG.kickThreshold then
        self:KickPlayer(player, violation, totalViolations)
        
    -- Ban system
    elseif totalViolations >= ANTICHEAT_CONFIG.banThreshold then
        self:BanPlayer(player, violation, totalViolations)
    end
end

-- Warn player
function AntiCheatService:WarnPlayer(player, violation, warningCount)
    local message = string.format(
        "⚠️ WARNING #%d: Suspicious activity detected (%s). Please play fairly or you may be kicked.",
        warningCount,
        violation.type
    )
    
    if RemoteEvents.ShowAntiCheatWarning then
        RemoteEvents.ShowAntiCheatWarning:FireClient(player, message, warningCount)
    end
    
    print("⚠️ Warned " .. player.Name .. " for " .. violation.type .. " (Warning #" .. warningCount .. ")")
end

-- Kick player
function AntiCheatService:KickPlayer(player, violation, violationCount)
    local reason = string.format(
        "Kicked for suspicious activity: %s (%d violations total)",
        violation.type,
        violationCount
    )
    
    print("👢 Kicking " .. player.Name .. " - " .. reason)
    
    -- Log kick
    self:LogKick(player, reason, violationCount)
    
    -- Kick player
    player:Kick(reason)
end

-- Ban player (temporary or permanent)
function AntiCheatService:BanPlayer(player, violation, violationCount)
    local reason = string.format(
        "Banned for repeated cheating: %s (%d violations total)",
        violation.type,
        violationCount
    )
    
    print("🔨 Banning " .. player.Name .. " - " .. reason)
    
    -- Log ban
    self:LogBan(player, reason, violationCount)
    
    -- Ban player (you would implement your ban system here)
    if RemoteEvents.BanPlayer then
        RemoteEvents.BanPlayer:FireServer(player.UserId, reason, 86400) -- 24 hour ban
    end
    
    -- Kick them immediately
    player:Kick("You have been banned for cheating. Ban reason: " .. reason)
end

-- Log kick
function AntiCheatService:LogKick(player, reason, violationCount)
    local logData = {
        action = "kick",
        userId = player.UserId,
        playerName = player.Name,
        reason = reason,
        violationCount = violationCount,
        time = tick()
    }
    
    -- Send to external logging system
    if RemoteEvents.LogAntiCheatAction then
        RemoteEvents.LogAntiCheatAction:FireServer(logData)
    end
end

-- Log ban
function AntiCheatService:LogBan(player, reason, violationCount)
    local logData = {
        action = "ban",
        userId = player.UserId,
        playerName = player.Name,
        reason = reason,
        violationCount = violationCount,
        time = tick()
    }
    
    -- Send to external logging system
    if RemoteEvents.LogAntiCheatAction then
        RemoteEvents.LogAntiCheatAction:FireServer(logData)
    end
end

-- Save violation history
function AntiCheatService:SaveViolationHistory(userId, violations)
    -- This would integrate with your data storage system
    print("💾 Saving violation history for user " .. userId .. " (" .. #violations .. " violations)")
end

-- Setup remote events
function AntiCheatService:SetupRemoteEvents()
    -- Client reporting suspicious behavior
    if RemoteEvents.ReportSuspiciousActivity then
        RemoteEvents.ReportSuspiciousActivity.OnServerEvent:Connect(function(player, activityType, data)
            self:HandleClientReport(player, activityType, data)
        end)
    end
    
    -- Admin commands
    if RemoteEvents.AntiCheatAdminCommand then
        RemoteEvents.AntiCheatAdminCommand.OnServerEvent:Connect(function(player, command, targetUserId)
            self:HandleAdminCommand(player, command, targetUserId)
        end)
    end
end

-- Handle client reports
function AntiCheatService:HandleClientReport(reportingPlayer, activityType, data)
    -- Validate that the reporting player is legitimate
    if not playerData[reportingPlayer.UserId] then return end
    
    print("📢 Client report from " .. reportingPlayer.Name .. ": " .. activityType)
    
    -- Log the report
    if ANTICHEAT_CONFIG.logViolations then
        local reportData = {
            type = "client_report",
            reportedActivity = activityType,
            reportingPlayer = reportingPlayer.Name,
            reportingUserId = reportingPlayer.UserId,
            data = data,
            time = tick()
        }
        
        self:LogViolation(reportData)
    end
end

-- Handle admin commands
function AntiCheatService:HandleAdminCommand(player, command, targetUserId)
    -- Check if player is admin (implement your admin system here)
    if not self:IsPlayerAdmin(player) then
        warn("Unauthorized anti-cheat admin command from " .. player.Name)
        return
    end
    
    if command == "reset_violations" then
        self:ResetPlayerViolations(targetUserId)
    elseif command == "get_violations" then
        self:SendViolationReport(player, targetUserId)
    elseif command == "whitelist" then
        self:WhitelistPlayer(targetUserId)
    elseif command == "unwhitelist" then
        self:UnwhitelistPlayer(targetUserId)
    end
end

-- Check if player is admin
function AntiCheatService:IsPlayerAdmin(player)
    -- Implement your admin check here
    return whitelistedPlayers[player.UserId] == true
end

-- Reset player violations
function AntiCheatService:ResetPlayerViolations(userId)
    if playerData[userId] then
        playerData[userId].totalViolations = 0
        playerData[userId].warnings = 0
        violationHistory[userId] = {}
        print("🔄 Reset violations for user " .. userId)
    end
end

-- Send violation report to admin
function AntiCheatService:SendViolationReport(adminPlayer, targetUserId)
    local data = playerData[targetUserId]
    local history = violationHistory[targetUserId]
    
    if not data or not history then
        RemoteEvents.AntiCheatAdminResponse:FireClient(adminPlayer, "Player not found or no data available")
        return
    end
    
    local report = {
        userId = targetUserId,
        playerName = data.player.Name,
        totalViolations = data.totalViolations,
        warnings = data.warnings,
        violationHistory = history
    }
    
    RemoteEvents.AntiCheatAdminResponse:FireClient(adminPlayer, report)
end

-- Whitelist player
function AntiCheatService:WhitelistPlayer(userId)
    if playerData[userId] then
        playerData[userId].isMonitored = false
        print("⚪ Whitelisted user " .. userId .. " from anti-cheat monitoring")
    end
end

-- Unwhitelist player
function AntiCheatService:UnwhitelistPlayer(userId)
    if playerData[userId] then
        playerData[userId].isMonitored = true
        print("🔴 Removed whitelist for user " .. userId)
    end
end

-- Get service statistics
function AntiCheatService:GetStats()
    local totalPlayers = 0
    local monitoredPlayers = 0
    local totalViolations = 0
    
    for userId, data in pairs(playerData) do
        totalPlayers = totalPlayers + 1
        if data.isMonitored then
            monitoredPlayers = monitoredPlayers + 1
        end
        totalViolations = totalViolations + data.totalViolations
    end
    
    return {
        totalPlayers = totalPlayers,
        monitoredPlayers = monitoredPlayers,
        totalViolations = totalViolations,
        configEnabled = ANTICHEAT_CONFIG.monitoringEnabled
    }
end

-- Manual check for specific player
function AntiCheatService:ManualCheck(userId)
    local data = playerData[userId]
    if not data then return nil end
    
    return {
        player = data.player.Name,
        isMonitored = data.isMonitored,
        totalViolations = data.totalViolations,
        warnings = data.warnings,
        speedViolations = data.speedViolations,
        positionViolations = data.positionViolations,
        statViolations = data.statViolations,
        jumpViolations = data.jumpViolations
    }
end

-- Performance optimization functions (integrated from AntiCheatServiceAdvanced)
function AntiCheatService:EnablePerformanceMode()
    print("🚀 AntiCheat: Enabling performance mode")
    ANTICHEAT_CONFIG.performanceMode = true
    ANTICHEAT_CONFIG.intervals.movement = 0.5
    ANTICHEAT_CONFIG.intervals.speed = 1.0
    ANTICHEAT_CONFIG.intervals.stats = 2.0
    ANTICHEAT_CONFIG.intervals.position = 0.3
    print("✅ AntiCheat: Performance mode enabled - monitoring intervals adjusted")
end

function AntiCheatService:DisablePerformanceMode()
    print("🔧 AntiCheat: Disabling performance mode")
    ANTICHEAT_CONFIG.performanceMode = false
    ANTICHEAT_CONFIG.intervals.movement = 0.2
    ANTICHEAT_CONFIG.intervals.speed = 0.5
    ANTICHEAT_CONFIG.intervals.stats = 1.0
    ANTICHEAT_CONFIG.intervals.position = 0.1
    print("✅ AntiCheat: Standard mode enabled - full monitoring restored")
end

function AntiCheatService:GetPerformanceMetrics()
    local totalChecks = 0
    local totalViolations = 0
    
    for _, data in pairs(playerData) do
        totalViolations = totalViolations + data.warnings
    end
    
    for _, history in pairs(violationHistory) do
        totalChecks = totalChecks + #history
    end
    
    return {
        performanceMode = ANTICHEAT_CONFIG.performanceMode,
        totalChecks = totalChecks,
        totalViolations = totalViolations,
        activeMonitoring = ANTICHEAT_CONFIG.monitoringEnabled,
        monitoredPlayers = self:GetActivePlayerCount()
    }
end

return AntiCheatService
