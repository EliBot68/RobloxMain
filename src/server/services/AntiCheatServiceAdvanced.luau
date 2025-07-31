-- AntiCheatServiceAdvanced.luau
-- TIER 2: Advanced Anti-Cheat Service with Performance Optimizations
-- High-performance anti-cheat system that replaces tight polling loops with event-driven monitoring
-- Reduces CPU overhead while maintaining security effectiveness
-- 
-- USE WHEN: High-value servers, competitive modes, or performance-critical environments
-- ALTERNATIVE: Use AntiCheatService.luau for basic protection with standard performance

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local HttpService = game:GetService("HttpService")

local ConfigurationManager = require(ReplicatedStorage.Shared.core.ConfigurationManager)
local PerformanceOptimizer = require(ReplicatedStorage.Shared.utilities.PerformanceOptimizer)
local OptimizedMemoryManager = require(ReplicatedStorage.Shared.utilities.OptimizedMemoryManager)

local AntiCheatServiceAdvanced = {}

-- ========================================
-- OPTIMIZED CONFIGURATION
-- ========================================

local config = ConfigurationManager.getInstance()

-- Enhanced anti-cheat configuration with performance optimizations
local ANTICHEAT_CONFIG = {
    -- Performance settings
    maxChecksPerSecond = 5, -- Limit to 5 checks per second instead of constant polling
    batchSize = 10, -- Process violations in batches
    adaptiveMonitoring = true, -- Adjust check frequency based on violation history
    
    -- Monitoring intervals (in seconds)
    intervals = {
        movement = 0.5, -- Check movement every 500ms instead of every frame
        speed = 1.0, -- Check speed every second
        stats = 2.0, -- Check stats every 2 seconds
        position = 0.3 -- Position checks every 300ms
    },
    
    -- Detection thresholds
    thresholds = {
        maxSpeed = 50,
        maxPositionDelta = 25,
        maxStatIncrease = 1000,
        maxJumpHeight = 20,
        suspiciousVelocity = 100
    },
    
    -- Violation limits before action
    limits = {
        warningsBeforeBan = 3,
        violationsBeforeWarning = 5,
        timeWindow = 60 -- seconds
    },
    
    -- Whitelist settings
    whitelistDevelopers = true,
    whitelistedPlayers = {
        [1234567890] = true, -- Developer IDs
        [123456789] = true
    }
}

-- ========================================
-- OPTIMIZED DATA STRUCTURES
-- ========================================

-- Use hash tables for O(1) lookups instead of linear searches
local playerData = {} -- [userId] = playerData
local violationHistory = {} -- [userId] = violations[]
local monitoringSystems = {}
local performanceMetrics = {
    checksPerformed = 0,
    violationsDetected = 0,
    falsePositives = 0,
    avgCheckTime = 0
}

-- ========================================
-- EVENT-DRIVEN MONITORING SYSTEM
-- ========================================

-- Replace while true loops with smart monitoring
function AntiCheatServiceAdvanced:InitializeOptimizedMonitoring()
    local memoryManager = OptimizedMemoryManager
    
    -- Movement monitoring with adaptive intervals
    monitoringSystems.movementMonitor = PerformanceOptimizer:CreateSmartMonitor({
        name = "MovementMonitor",
        checkFunction = function()
            return self:BatchCheckPlayerMovement()
        end,
        onTrigger = function(violations)
            self:ProcessMovementViolations(violations)
        end,
        condition = function(violations)
            return violations and #violations > 0
        end,
        interval = ANTICHEAT_CONFIG.intervals.movement,
        adaptiveInterval = ANTICHEAT_CONFIG.adaptiveMonitoring,
        maxChecksPerSecond = ANTICHEAT_CONFIG.maxChecksPerSecond
    })
    
    -- Speed monitoring with intelligent batching
    monitoringSystems.speedMonitor = PerformanceOptimizer:CreateSmartMonitor({
        name = "SpeedMonitor",
        checkFunction = function()
            return self:BatchCheckPlayerSpeed()
        end,
        onTrigger = function(violations)
            self:ProcessSpeedViolations(violations)
        end,
        condition = function(violations)
            return violations and #violations > 0
        end,
        interval = ANTICHEAT_CONFIG.intervals.speed,
        adaptiveInterval = ANTICHEAT_CONFIG.adaptiveMonitoring,
        maxChecksPerSecond = 2 -- Speed checks are expensive, limit to 2/sec
    })
    
    -- Stats monitoring with longer intervals
    monitoringSystems.statsMonitor = PerformanceOptimizer:CreateSmartMonitor({
        name = "StatsMonitor",
        checkFunction = function()
            return self:BatchCheckPlayerStats()
        end,
        onTrigger = function(violations)
            self:ProcessStatViolations(violations)
        end,
        condition = function(violations)
            return violations and #violations > 0
        end,
        interval = ANTICHEAT_CONFIG.intervals.stats,
        adaptiveInterval = ANTICHEAT_CONFIG.adaptiveMonitoring,
        maxChecksPerSecond = 1 -- Stats checks only once per second max
    })
    
    -- Start all monitoring systems
    for name, monitor in pairs(monitoringSystems) do
        monitor:Start()
        print("ðŸ” Started optimized monitor: " .. name)
    end
end

-- ========================================
-- BATCH PROCESSING FUNCTIONS
-- ========================================

-- Batch check player movement for better performance
function AntiCheatServiceAdvanced:BatchCheckPlayerMovement()
    local violations = {}
    local currentTime = tick()
    
    for userId, data in pairs(playerData) do
        if not data.isMonitored then continue end
        
        local player = data.player
        if not player or not player.Parent then
            self:CleanupPlayerData(userId)
            continue
        end
        
        local character = player.Character
        if not character or not character:FindFirstChild("HumanoidRootPart") then
            continue
        end
        
        local violation = self:CheckSinglePlayerMovement(data, character, currentTime)
        if violation then
            table.insert(violations, violation)
        end
    end
    
    performanceMetrics.checksPerformed = performanceMetrics.checksPerformed + 1
    return violations
end

-- Optimized single player movement check
function AntiCheatServiceAdvanced:CheckSinglePlayerMovement(data, character, currentTime)
    local humanoidRootPart = character.HumanoidRootPart
    local currentPosition = humanoidRootPart.Position
    local deltaTime = currentTime - data.lastUpdateTime
    
    if deltaTime <= 0 then return nil end
    
    -- Calculate movement delta
    local positionDelta = (currentPosition - data.lastPosition).Magnitude
    local maxAllowedDelta = ANTICHEAT_CONFIG.thresholds.maxPositionDelta * deltaTime
    
    -- Update data
    data.lastPosition = currentPosition
    data.lastUpdateTime = currentTime
    
    -- Check for violation
    if positionDelta > maxAllowedDelta then
        data.positionViolations = data.positionViolations + 1
        return {
            userId = data.player.UserId,
            type = "POSITION_VIOLATION",
            severity = math.min(positionDelta / maxAllowedDelta, 5.0),
            details = {
                positionDelta = positionDelta,
                maxAllowed = maxAllowedDelta,
                deltaTime = deltaTime
            },
            timestamp = currentTime
        }
    end
    
    return nil
end

-- Batch check player speed
function AntiCheatServiceAdvanced:BatchCheckPlayerSpeed()
    local violations = {}
    local currentTime = tick()
    
    for userId, data in pairs(playerData) do
        if not data.isMonitored then continue end
        
        local player = data.player
        local character = player.Character
        if not character or not character:FindFirstChild("Humanoid") then
            continue
        end
        
        local violation = self:CheckSinglePlayerSpeed(data, character, currentTime)
        if violation then
            table.insert(violations, violation)
        end
    end
    
    return violations
end

-- Optimized single player speed check
function AntiCheatServiceAdvanced:CheckSinglePlayerSpeed(data, character, currentTime)
    local humanoid = character.Humanoid
    local currentSpeed = humanoid.WalkSpeed
    
    -- Check for speed violations
    if currentSpeed > ANTICHEAT_CONFIG.thresholds.maxSpeed then
        data.speedViolations = data.speedViolations + 1
        return {
            userId = data.player.UserId,
            type = "SPEED_VIOLATION",
            severity = currentSpeed / ANTICHEAT_CONFIG.thresholds.maxSpeed,
            details = {
                currentSpeed = currentSpeed,
                maxAllowed = ANTICHEAT_CONFIG.thresholds.maxSpeed
            },
            timestamp = currentTime
        }
    end
    
    return nil
end

-- Batch check player stats
function AntiCheatServiceAdvanced:BatchCheckPlayerStats()
    local violations = {}
    local currentTime = tick()
    
    for userId, data in pairs(playerData) do
        if not data.isMonitored then continue end
        
        local violation = self:CheckSinglePlayerStats(data, currentTime)
        if violation then
            table.insert(violations, violation)
        end
    end
    
    return violations
end

-- Optimized single player stats check
function AntiCheatServiceAdvanced:CheckSinglePlayerStats(data, currentTime)
    -- Get current stats from player data store or leaderstats
    local player = data.player
    local leaderstats = player:FindFirstChild("leaderstats")
    if not leaderstats then return nil end
    
    local currentCoins = leaderstats:FindFirstChild("Coins")
    local currentXP = leaderstats:FindFirstChild("XP")
    
    if currentCoins and currentXP then
        local coinIncrease = currentCoins.Value - data.lastCoins
        local xpIncrease = currentXP.Value - data.lastXP
        local timeDelta = currentTime - data.lastStatUpdateTime
        
        -- Update tracked values
        data.lastCoins = currentCoins.Value
        data.lastXP = currentXP.Value
        data.lastStatUpdateTime = currentTime
        
        -- Check for suspicious stat increases
        local maxIncrease = ANTICHEAT_CONFIG.thresholds.maxStatIncrease * timeDelta
        
        if coinIncrease > maxIncrease or xpIncrease > maxIncrease then
            data.statViolations = data.statViolations + 1
            return {
                userId = player.UserId,
                type = "STAT_VIOLATION",
                severity = math.max(coinIncrease / maxIncrease, xpIncrease / maxIncrease),
                details = {
                    coinIncrease = coinIncrease,
                    xpIncrease = xpIncrease,
                    maxAllowed = maxIncrease,
                    timeDelta = timeDelta
                },
                timestamp = currentTime
            }
        end
    end
    
    return nil
end

-- ========================================
-- VIOLATION PROCESSING
-- ========================================

-- Process movement violations efficiently
function AntiCheatServiceAdvanced:ProcessMovementViolations(violations)
    for _, violation in ipairs(violations) do
        self:RecordViolation(violation)
        performanceMetrics.violationsDetected = performanceMetrics.violationsDetected + 1
    end
    
    if #violations > 0 then
        print("ðŸš¨ Processed " .. #violations .. " movement violations")
    end
end

-- Process speed violations
function AntiCheatServiceAdvanced:ProcessSpeedViolations(violations)
    for _, violation in ipairs(violations) do
        self:RecordViolation(violation)
        
        -- Take immediate action for severe speed violations
        if violation.severity > 3.0 then
            self:TakeImmediateAction(violation.userId, violation)
        end
    end
end

-- Process stat violations
function AntiCheatServiceAdvanced:ProcessStatViolations(violations)
    for _, violation in ipairs(violations) do
        self:RecordViolation(violation)
        
        -- Stat violations are serious, escalate quickly
        if violation.severity > 2.0 then
            self:EscalateViolation(violation.userId, violation)
        end
    end
end

-- Record violation in optimized data structure
function AntiCheatServiceAdvanced:RecordViolation(violation)
    local userId = violation.userId
    
    if not violationHistory[userId] then
        violationHistory[userId] = {}
    end
    
    table.insert(violationHistory[userId], violation)
    
    -- Keep only recent violations (sliding window)
    local cutoffTime = tick() - ANTICHEAT_CONFIG.limits.timeWindow
    local filteredHistory = {}
    
    for _, v in ipairs(violationHistory[userId]) do
        if v.timestamp > cutoffTime then
            table.insert(filteredHistory, v)
        end
    end
    
    violationHistory[userId] = filteredHistory
    
    -- Check if action is needed
    if #violationHistory[userId] >= ANTICHEAT_CONFIG.limits.violationsBeforeWarning then
        self:IssueWarning(userId)
    end
end

-- ========================================
-- PLAYER MANAGEMENT (OPTIMIZED)
-- ========================================

-- Initialize player tracking with optimized data structure
function AntiCheatServiceAdvanced:InitializePlayerTracking(player)
    local userId = player.UserId
    
    -- Check whitelist first
    local isWhitelisted = ANTICHEAT_CONFIG.whitelistDevelopers and 
                         ANTICHEAT_CONFIG.whitelistedPlayers[userId]
    
    playerData[userId] = {
        player = player,
        
        -- Movement tracking
        lastPosition = Vector3.new(0, 0, 0),
        lastUpdateTime = tick(),
        positionViolations = 0,
        
        -- Speed tracking  
        speedViolations = 0,
        lastSpeedCheck = tick(),
        
        -- Stat tracking
        lastCoins = 0,
        lastXP = 0,
        lastStatUpdateTime = tick(),
        statViolations = 0,
        
        -- General tracking
        totalViolations = 0,
        warnings = 0,
        isMonitored = not isWhitelisted,
        adaptiveMultiplier = 1.0 -- For adaptive monitoring
    }
    
    -- Initialize violation history
    violationHistory[userId] = {}
    
    if isWhitelisted then
        print("ðŸ”§ Developer " .. player.Name .. " whitelisted from anti-cheat")
    else
        print("ðŸ” Initialized optimized anti-cheat for " .. player.Name)
    end
end

-- Cleanup player data efficiently
function AntiCheatServiceAdvanced:CleanupPlayerData(userId)
    if playerData[userId] then
        local player = playerData[userId].player
        print("ðŸ§¹ Cleaning up anti-cheat data for " .. (player and player.Name or "Unknown Player"))
    end
    
    playerData[userId] = nil
    violationHistory[userId] = nil
end

-- ========================================
-- ACTION SYSTEM
-- ========================================

-- Issue warning to player
function AntiCheatServiceAdvanced:IssueWarning(userId)
    local data = playerData[userId]
    if not data then return end
    
    data.warnings = data.warnings + 1
    
    local player = data.player
    print("âš ï¸ Warning issued to " .. player.Name .. " (Warning #" .. data.warnings .. ")")
    
    -- Ban if too many warnings
    if data.warnings >= ANTICHEAT_CONFIG.limits.warningsBeforeBan then
        self:BanPlayer(userId, "Multiple anti-cheat violations")
    end
end

-- Take immediate action for severe violations
function AntiCheatServiceAdvanced:TakeImmediateAction(userId, violation)
    local data = playerData[userId]
    if not data then return end
    
    local player = data.player
    print("ðŸš¨ IMMEDIATE ACTION: " .. violation.type .. " by " .. player.Name .. 
          " (severity: " .. string.format("%.2f", violation.severity) .. ")")
    
    if violation.severity > 4.0 then
        self:BanPlayer(userId, "Severe anti-cheat violation: " .. violation.type)
    else
        self:KickPlayer(userId, "Anti-cheat violation detected")
    end
end

-- Escalate violation
function AntiCheatServiceAdvanced:EscalateViolation(userId, violation)
    local data = playerData[userId]
    if not data then return end
    
    -- Increase adaptive monitoring frequency for this player
    data.adaptiveMultiplier = math.max(0.1, data.adaptiveMultiplier * 0.5)
    
    print("ðŸ“ˆ Escalated monitoring for player " .. data.player.Name .. 
          " due to " .. violation.type)
end

-- Kick player
function AntiCheatServiceAdvanced:KickPlayer(userId, reason)
    local data = playerData[userId]
    if data and data.player then
        data.player:Kick("Anti-Cheat: " .. reason)
        print("ðŸ‘¢ Kicked player " .. data.player.Name .. ": " .. reason)
    end
end

-- Ban player (placeholder - implement with your ban system)
function AntiCheatServiceAdvanced:BanPlayer(userId, reason)
    local data = playerData[userId]
    if data and data.player then
        -- Implement actual ban logic here
        data.player:Kick("BANNED: " .. reason)
        print("ðŸ”¨ Banned player " .. data.player.Name .. ": " .. reason)
    end
end

-- ========================================
-- PERFORMANCE MONITORING
-- ========================================

-- Get anti-cheat performance statistics
function AntiCheatServiceAdvanced:GetPerformanceStats()
    local activePlayers = 0
    local monitoredPlayers = 0
    
    for userId, data in pairs(playerData) do
        activePlayers = activePlayers + 1
        if data.isMonitored then
            monitoredPlayers = monitoredPlayers + 1
        end
    end
    
    local monitorStats = {}
    for name, monitor in pairs(monitoringSystems) do
        monitorStats[name] = monitor:GetStats()
    end
    
    return {
        players = {
            active = activePlayers,
            monitored = monitoredPlayers,
            whitelisted = activePlayers - monitoredPlayers
        },
        performance = performanceMetrics,
        monitors = monitorStats,
        memory = {
            playerData = activePlayers,
            violationHistory = 0 -- Count violations
        }
    }
end

-- Print performance report
function AntiCheatServiceAdvanced:PrintPerformanceReport()
    local stats = self:GetPerformanceStats()
    
    print("ðŸ›¡ï¸ Anti-Cheat Performance Report:")
    print("   Players: " .. stats.players.active .. " active, " .. 
          stats.players.monitored .. " monitored")
    print("   Checks performed: " .. stats.performance.checksPerformed)
    print("   Violations detected: " .. stats.performance.violationsDetected)
    
    for name, monitorStats in pairs(stats.monitors) do
        print("   " .. name .. ": " .. monitorStats.checks .. " checks, " .. 
              monitorStats.triggers .. " triggers (" .. 
              string.format("%.1f%%", monitorStats.triggerRate * 100) .. ")")
    end
end

-- ========================================
-- INITIALIZATION
-- ========================================

function AntiCheatServiceAdvanced:Init()
    print("ðŸ›¡ï¸ AntiCheatServiceAdvanced initializing...")
    
    -- Setup player management
    Players.PlayerAdded:Connect(function(player)
        self:InitializePlayerTracking(player)
    end)
    
    Players.PlayerRemoving:Connect(function(player)
        self:CleanupPlayerData(player.UserId)
    end)
    
    -- Initialize existing players
    for _, player in ipairs(Players:GetPlayers()) do
        self:InitializePlayerTracking(player)
    end
    
    -- Initialize optimized monitoring systems
    self:InitializeOptimizedMonitoring()
    
    -- Start performance reporting
    task.spawn(function()
        while true do
            task.wait(60) -- Report every minute
            self:PrintPerformanceReport()
        end
    end)
    
    print("âœ… AntiCheatServiceAdvanced initialized with smart monitoring")
    return true
end

return AntiCheatServiceAdvanced

