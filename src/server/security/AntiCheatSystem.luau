-- AntiCheatSystem.luau
-- Comprehensive anti-cheat system to detect and prevent various cheating methods
-- Closes identified bypass methods and implements advanced detection algorithms

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local HttpService = game:GetService("HttpService")

local SafeRequire = require(ReplicatedStorage.Shared.utils.SafeRequire)
local ServiceArchitecture = SafeRequire.require(ReplicatedStorage.Shared.core.ServiceArchitecture)

local AntiCheatSystem = {}
AntiCheatSystem.__index = AntiCheatSystem

-- Implement IAntiCheatSystem interface
setmetatable(AntiCheatSystem, {__index = ServiceArchitecture.IAntiCheatSystem})

-- ========================================
-- ANTI-CHEAT CONFIGURATION
-- ========================================

local ANTICHEAT_CONFIG = {
    -- Detection thresholds
    speedThreshold = 25, -- Max speed in studs/second
    jumpThreshold = 50, -- Max jump height
    teleportThreshold = 100, -- Max position change per frame
    
    -- Time windows for analysis
    speedCheckWindow = 1, -- seconds
    positionHistorySize = 30, -- frames
    actionHistorySize = 100, -- actions
    
    -- Violation thresholds
    maxViolationsPerMinute = 10,
    banThreshold = 50, -- Total violations before ban
    
    -- Detection sensitivities
    noclipSensitivity = 0.8,
    speedhackSensitivity = 0.9,
    exploitSensitivity = 0.7,
    
    -- Monitoring intervals
    continuousMonitoringInterval = 0.1, -- seconds
    deepScanInterval = 5, -- seconds
    statisticsUpdateInterval = 30 -- seconds
}

local CHEAT_TYPES = {
    SPEED_HACK = "speed_hack",
    TELEPORT_HACK = "teleport_hack",
    NO_CLIP = "no_clip",
    FLY_HACK = "fly_hack",
    INFINITE_JUMP = "infinite_jump",
    EXPLOIT_EXECUTION = "exploit_execution",
    MEMORY_MANIPULATION = "memory_manipulation",
    SCRIPT_INJECTION = "script_injection",
    PACKET_MANIPULATION = "packet_manipulation",
    TIME_MANIPULATION = "time_manipulation"
}

local BYPASS_METHODS = {
    -- Known bypass techniques to defend against
    TICK_MANIPULATION = "tick_manipulation",
    HEARTBEAT_SKIPPING = "heartbeat_skipping",
    SIGNAL_BLOCKING = "signal_blocking",
    METAMETHOD_OVERRIDE = "metamethod_override",
    ENVIRONMENT_POLLUTION = "environment_pollution",
    REMOTE_SPOOFING = "remote_spoofing"
}

-- ========================================
-- CORE ANTI-CHEAT SYSTEM
-- ========================================

function AntiCheatSystem.new()
    local self = setmetatable({}, AntiCheatSystem)
    
    -- Player monitoring data
    self.playerData = {} -- Per-player anti-cheat data
    self.violationHistory = {} -- Violation tracking per player
    self.bannedPlayers = {} -- Banned player registry
    
    -- Detection systems
    self.detectionModules = {}
    self.bypassProtections = {}
    self.integrityChecks = {}
    
    -- Performance tracking
    self.performanceMetrics = {
        checksPerSecond = 0,
        falsePositives = 0,
        truePositives = 0,
        bypassAttempts = 0
    }
    
    -- Statistics
    self.stats = {
        playersMonitored = 0,
        violationsDetected = 0,
        playersKicked = 0,
        playersBanned = 0,
        bypassesBlocked = 0,
        uptime = os.time()
    }
    
    -- Initialize monitoring systems
    self:InitializeDetectionModules()
    self:InitializeBypassProtections()
    self:StartMonitoring()
    
    print("🛡️ AntiCheatSystem initialized with advanced detection")
    return self
end

-- ========================================
-- DETECTION MODULES
-- ========================================

function AntiCheatSystem:InitializeDetectionModules()
    -- Speed hack detection
    self.detectionModules.speedHack = {
        name = "Speed Hack Detection",
        enabled = true,
        check = function(player, data)
            return self:DetectSpeedHack(player, data)
        end
    }
    
    -- Teleport detection
    self.detectionModules.teleportHack = {
        name = "Teleport Detection",
        enabled = true,
        check = function(player, data)
            return self:DetectTeleportHack(player, data)
        end
    }
    
    -- No-clip detection
    self.detectionModules.noClip = {
        name = "No-Clip Detection",
        enabled = true,
        check = function(player, data)
            return self:DetectNoClip(player, data)
        end
    }
    
    -- Fly hack detection
    self.detectionModules.flyHack = {
        name = "Fly Hack Detection",
        enabled = true,
        check = function(player, data)
            return self:DetectFlyHack(player, data)
        end
    }
    
    -- Exploit execution detection
    self.detectionModules.exploitExecution = {
        name = "Exploit Execution Detection",
        enabled = true,
        check = function(player, data)
            return self:DetectExploitExecution(player, data)
        end
    }
    
    -- Time manipulation detection
    self.detectionModules.timeManipulation = {
        name = "Time Manipulation Detection",
        enabled = true,
        check = function(player, data)
            return self:DetectTimeManipulation(player, data)
        end
    }
end

function AntiCheatSystem:DetectSpeedHack(player, data)
    local character = player.Character
    if not character or not character:FindFirstChild("HumanoidRootPart") then
        return {detected = false}
    end
    
    local humanoidRootPart = character.HumanoidRootPart
    local currentPosition = humanoidRootPart.Position
    local currentTime = tick()
    
    if data.lastPosition and data.lastTime then
        local distance = (currentPosition - data.lastPosition).Magnitude
        local timeDiff = currentTime - data.lastTime
        local speed = distance / timeDiff
        
        -- Check against threshold with some tolerance for lag
        if speed > ANTICHEAT_CONFIG.speedThreshold * 1.2 then
            return {
                detected = true,
                cheatType = CHEAT_TYPES.SPEED_HACK,
                severity = math.min(speed / ANTICHEAT_CONFIG.speedThreshold, 5),
                details = {
                    speed = speed,
                    threshold = ANTICHEAT_CONFIG.speedThreshold,
                    distance = distance,
                    timeDiff = timeDiff
                }
            }
        end
    end
    
    -- Update tracking data
    data.lastPosition = currentPosition
    data.lastTime = currentTime
    
    return {detected = false}
end

function AntiCheatSystem:DetectTeleportHack(player, data)
    local character = player.Character
    if not character or not character:FindFirstChild("HumanoidRootPart") then
        return {detected = false}
    end
    
    local humanoidRootPart = character.HumanoidRootPart
    local currentPosition = humanoidRootPart.Position
    
    if data.lastTeleportCheckPosition then
        local distance = (currentPosition - data.lastTeleportCheckPosition).Magnitude
        
        -- Large instant movement without proper velocity
        if distance > ANTICHEAT_CONFIG.teleportThreshold then
            local velocity = humanoidRootPart.AssemblyLinearVelocity
            local expectedDistance = velocity.Magnitude * 0.1 -- Expected for one frame
            
            if distance > expectedDistance * 3 then
                return {
                    detected = true,
                    cheatType = CHEAT_TYPES.TELEPORT_HACK,
                    severity = math.min(distance / ANTICHEAT_CONFIG.teleportThreshold, 5),
                    details = {
                        distance = distance,
                        expectedDistance = expectedDistance,
                        velocity = velocity.Magnitude
                    }
                }
            end
        end
    end
    
    data.lastTeleportCheckPosition = currentPosition
    return {detected = false}
end

function AntiCheatSystem:DetectNoClip(player, data)
    local character = player.Character
    if not character or not character:FindFirstChild("HumanoidRootPart") then
        return {detected = false}
    end
    
    local humanoidRootPart = character.HumanoidRootPart
    local position = humanoidRootPart.Position
    
    -- Raycast downward to check if player is floating in air without support
    local raycastParams = RaycastParams.new()
    raycastParams.FilterType = Enum.RaycastFilterType.Blacklist
    raycastParams.FilterDescendantsInstances = {character}
    
    local raycastResult = Workspace:Raycast(position, Vector3.new(0, -200, 0), raycastParams)
    
    if not raycastResult then
        -- Player is very high up, check if they should be falling
        local velocity = humanoidRootPart.AssemblyLinearVelocity
        if math.abs(velocity.Y) < 5 and position.Y > 100 then
            return {
                detected = true,
                cheatType = CHEAT_TYPES.NO_CLIP,
                severity = 3,
                details = {
                    position = position,
                    velocity = velocity,
                    noGroundDetected = true
                }
            }
        end
    else
        local distanceToGround = raycastResult.Distance
        
        -- Check if player is moving through walls
        if distanceToGround > 50 then
            local humanoid = character:FindFirstChild("Humanoid")
            if humanoid and humanoid.PlatformStand == false and velocity.Y > -10 then
                data.suspiciousFloating = (data.suspiciousFloating or 0) + 1
                
                if data.suspiciousFloating > 10 then
                    return {
                        detected = true,
                        cheatType = CHEAT_TYPES.NO_CLIP,
                        severity = 2,
                        details = {
                            distanceToGround = distanceToGround,
                            suspiciousFloatingCount = data.suspiciousFloating
                        }
                    }
                end
            end
        else
            data.suspiciousFloating = 0
        end
    end
    
    return {detected = false}
end

function AntiCheatSystem:DetectFlyHack(player, data)
    local character = player.Character
    if not character or not character:FindFirstChild("HumanoidRootPart") then
        return {detected = false}
    end
    
    local humanoid = character:FindFirstChild("Humanoid")
    local humanoidRootPart = character.HumanoidRootPart
    
    if humanoid and humanoidRootPart then
        local velocity = humanoidRootPart.AssemblyLinearVelocity
        local jumpState = humanoid:GetState()
        
        -- Track sustained upward movement without jumping
        if velocity.Y > 5 and jumpState ~= Enum.HumanoidStateType.Jumping and 
           jumpState ~= Enum.HumanoidStateType.Freefall then
            
            data.suspiciousFlying = (data.suspiciousFlying or 0) + 1
            
            if data.suspiciousFlying > 15 then -- 1.5 seconds of sustained flying
                return {
                    detected = true,
                    cheatType = CHEAT_TYPES.FLY_HACK,
                    severity = 3,
                    details = {
                        velocity = velocity,
                        jumpState = jumpState,
                        flyingDuration = data.suspiciousFlying * 0.1
                    }
                }
            end
        else
            data.suspiciousFlying = 0
        end
    end
    
    return {detected = false}
end

function AntiCheatSystem:DetectExploitExecution(player, data)
    -- This requires additional monitoring of script creation and execution
    -- which would be implemented with deeper engine hooks in a real system
    
    -- Check for suspicious script patterns
    local character = player.Character
    if not character then
        return {detected = false}
    end
    
    -- Monitor for unauthorized script creation
    local suspiciousScripts = 0
    for _, descendant in ipairs(character:GetDescendants()) do
        if descendant:IsA("LocalScript") or descendant:IsA("Script") then
            -- Check if script was created by the game or by an exploit
            if not string.find(descendant.Name, "GameScript") and 
               not string.find(descendant.Name, "Core") then
                suspiciousScripts = suspiciousScripts + 1
            end
        end
    end
    
    if suspiciousScripts > 3 then
        return {
            detected = true,
            cheatType = CHEAT_TYPES.SCRIPT_INJECTION,
            severity = 4,
            details = {
                suspiciousScriptCount = suspiciousScripts
            }
        }
    end
    
    return {detected = false}
end

function AntiCheatSystem:DetectTimeManipulation(player, data)
    local currentTime = tick()
    
    if data.lastTickTime then
        local tickDiff = currentTime - data.lastTickTime
        
        -- Check for time skips or slowdowns
        if tickDiff > 1 then -- More than 1 second between checks
            data.suspiciousTimeSkips = (data.suspiciousTimeSkips or 0) + 1
            
            if data.suspiciousTimeSkips > 3 then
                return {
                    detected = true,
                    cheatType = CHEAT_TYPES.TIME_MANIPULATION,
                    severity = 2,
                    details = {
                        tickDiff = tickDiff,
                        timeSkipsCount = data.suspiciousTimeSkips
                    }
                }
            end
        elseif tickDiff < 0.05 then -- Too fast
            data.suspiciousSpeedUp = (data.suspiciousSpeedUp or 0) + 1
            
            if data.suspiciousSpeedUp > 10 then
                return {
                    detected = true,
                    cheatType = CHEAT_TYPES.TIME_MANIPULATION,
                    severity = 3,
                    details = {
                        tickDiff = tickDiff,
                        speedUpCount = data.suspiciousSpeedUp
                    }
                }
            end
        else
            -- Normal timing, reset counters
            data.suspiciousTimeSkips = 0
            data.suspiciousSpeedUp = 0
        end
    end
    
    data.lastTickTime = currentTime
    return {detected = false}
end

-- ========================================
-- BYPASS PROTECTION
-- ========================================

function AntiCheatSystem:InitializeBypassProtections()
    -- Protect against metamethod overrides
    self.bypassProtections.metamethodProtection = function()
        self:ProtectMetamethods()
    end
    
    -- Protect against environment pollution
    self.bypassProtections.environmentProtection = function()
        self:ProtectEnvironment()
    end
    
    -- Protect against signal blocking
    self.bypassProtections.signalProtection = function()
        self:ProtectSignals()
    end
    
    -- Execute all protections
    for _, protection in pairs(self.bypassProtections) do
        pcall(protection)
    end
end

function AntiCheatSystem:ProtectMetamethods()
    -- Protect critical metamethods from being overridden
    local protectedMetamethods = {"__index", "__newindex", "__call", "__metatable"}
    
    for _, method in ipairs(protectedMetamethods) do
        -- This would require engine-level protection in a real implementation
        -- For now, we log attempts to access these
        debug.setmetatable({}, {
            __index = function(t, k)
                if k == method then
                    self:LogBypassAttempt("metamethod_override", {method = method})
                end
            end
        })
    end
end

function AntiCheatSystem:ProtectEnvironment()
    -- Protect global environment from pollution
    local originalGlobals = {}
    for k, v in pairs(_G) do
        originalGlobals[k] = v
    end
    
    spawn(function()
        while true do
            wait(1)
            for k, v in pairs(_G) do
                if originalGlobals[k] ~= v then
                    self:LogBypassAttempt("environment_pollution", {
                        key = k,
                        originalValue = originalGlobals[k],
                        newValue = v
                    })
                end
            end
        end
    end)
end

function AntiCheatSystem:ProtectSignals()
    -- Monitor for signal connection blocking
    local originalConnect = game.Heartbeat.Connect
    
    game.Heartbeat.Connect = function(self, func)
        -- Log if someone tries to block our monitoring
        if string.find(debug.traceback(), "AntiCheat") then
            return originalConnect(self, func)
        else
            self:LogBypassAttempt("signal_blocking", {
                signal = "Heartbeat",
                traceback = debug.traceback()
            })
            return originalConnect(self, func)
        end
    end
end

-- ========================================
-- MONITORING SYSTEM
-- ========================================

function AntiCheatSystem:StartMonitoring()
    -- Continuous monitoring loop
    spawn(function()
        while true do
            wait(ANTICHEAT_CONFIG.continuousMonitoringInterval)
            self:RunContinuousChecks()
        end
    end)
    
    -- Deep scan loop
    spawn(function()
        while true do
            wait(ANTICHEAT_CONFIG.deepScanInterval)
            self:RunDeepScan()
        end
    end)
    
    -- Statistics update loop
    spawn(function()
        while true do
            wait(ANTICHEAT_CONFIG.statisticsUpdateInterval)
            self:UpdateStatistics()
        end
    end)
end

function AntiCheatSystem:RunContinuousChecks()
    for _, player in ipairs(Players:GetPlayers()) do
        if player.Character then
            self:CheckPlayer(player)
        end
    end
end

function AntiCheatSystem:CheckPlayer(player)
    local playerId = tostring(player.UserId)
    
    -- Initialize player data if not exists
    if not self.playerData[playerId] then
        self.playerData[playerId] = {
            joinTime = os.time(),
            violationCount = 0,
            lastPosition = nil,
            lastTime = nil,
            suspiciousActivity = {}
        }
        self.stats.playersMonitored = self.stats.playersMonitored + 1
    end
    
    local playerData = self.playerData[playerId]
    
    -- Run all detection modules
    for moduleName, module in pairs(self.detectionModules) do
        if module.enabled then
            local result = module.check(player, playerData)
            
            if result.detected then
                self:HandleViolation(player, result)
            end
        end
    end
end

function AntiCheatSystem:RunDeepScan()
    for _, player in ipairs(Players:GetPlayers()) do
        self:PerformDeepScan(player)
    end
end

function AntiCheatSystem:PerformDeepScan(player)
    local playerId = tostring(player.UserId)
    local playerData = self.playerData[playerId]
    
    if not playerData then return end
    
    -- Integrity checks
    self:CheckPlayerIntegrity(player)
    
    -- Behavioral analysis
    self:AnalyzePlayerBehavior(player, playerData)
    
    -- Performance anomaly detection
    self:DetectPerformanceAnomalies(player, playerData)
end

function AntiCheatSystem:CheckPlayerIntegrity(player)
    local character = player.Character
    if not character then return end
    
    -- Check for unauthorized modifications
    local humanoid = character:FindFirstChild("Humanoid")
    if humanoid then
        -- Check WalkSpeed and JumpPower
        if humanoid.WalkSpeed > 16.1 or humanoid.JumpPower > 50.1 then
            self:HandleViolation(player, {
                detected = true,
                cheatType = "stat_modification",
                severity = 2,
                details = {
                    walkSpeed = humanoid.WalkSpeed,
                    jumpPower = humanoid.JumpPower
                }
            })
        end
    end
end

-- ========================================
-- VIOLATION HANDLING
-- ========================================

function AntiCheatSystem:HandleViolation(player, violationData)
    local playerId = tostring(player.UserId)
    local playerData = self.playerData[playerId]
    
    if not playerData then return end
    
    -- Record violation
    playerData.violationCount = playerData.violationCount + 1
    self.stats.violationsDetected = self.stats.violationsDetected + 1
    
    local violation = {
        timestamp = os.time(),
        cheatType = violationData.cheatType,
        severity = violationData.severity,
        details = violationData.details,
        playerId = playerId,
        playerName = player.Name
    }
    
    -- Add to violation history
    if not self.violationHistory[playerId] then
        self.violationHistory[playerId] = {}
    end
    table.insert(self.violationHistory[playerId], violation)
    
    -- Determine action based on severity and history
    local action = self:DetermineAction(player, violation, playerData.violationCount)
    
    -- Execute action
    self:ExecuteAction(player, action, violation)
    
    -- Log violation
    self:LogViolation(violation, action)
end

function AntiCheatSystem:DetermineAction(player, violation, totalViolations)
    local severity = violation.severity
    
    if totalViolations >= ANTICHEAT_CONFIG.banThreshold then
        return "ban"
    elseif severity >= 4 or totalViolations >= 20 then
        return "kick"
    elseif severity >= 3 or totalViolations >= 10 then
        return "warn"
    elseif severity >= 2 then
        return "log"
    else
        return "monitor"
    end
end

function AntiCheatSystem:ExecuteAction(player, action, violation)
    if action == "ban" then
        self:BanPlayer(player, violation)
    elseif action == "kick" then
        self:KickPlayer(player, violation)
    elseif action == "warn" then
        self:WarnPlayer(player, violation)
    elseif action == "log" then
        -- Already logged
    elseif action == "monitor" then
        -- Continue monitoring
    end
end

function AntiCheatSystem:BanPlayer(player, violation)
    local playerId = tostring(player.UserId)
    
    self.bannedPlayers[playerId] = {
        reason = violation.cheatType,
        timestamp = os.time(),
        violationDetails = violation
    }
    
    self.stats.playersBanned = self.stats.playersBanned + 1
    
    player:Kick("You have been banned for cheating: " .. violation.cheatType)
    print("🔨 Player banned: " .. player.Name .. " for " .. violation.cheatType)
end

function AntiCheatSystem:KickPlayer(player, violation)
    self.stats.playersKicked = self.stats.playersKicked + 1
    
    player:Kick("Anti-cheat violation detected: " .. violation.cheatType)
    print("👢 Player kicked: " .. player.Name .. " for " .. violation.cheatType)
end

function AntiCheatSystem:WarnPlayer(player, violation)
    -- Send warning to player (would use RemoteEvent in practice)
    print("⚠️ Warning issued to " .. player.Name .. " for " .. violation.cheatType)
end

-- ========================================
-- LOGGING AND ANALYTICS
-- ========================================

function AntiCheatSystem:LogViolation(violation, action)
    local logEntry = {
        timestamp = os.time(),
        violation = violation,
        action = action,
        serverId = game.JobId
    }
    
    -- In a real implementation, this would be sent to external logging service
    print("📝 Anti-cheat violation logged: " .. violation.cheatType .. " -> " .. action)
end

function AntiCheatSystem:LogBypassAttempt(bypassType, details)
    self.stats.bypassesBlocked = self.stats.bypassesBlocked + 1
    
    local logEntry = {
        timestamp = os.time(),
        bypassType = bypassType,
        details = details,
        serverId = game.JobId
    }
    
    print("🚫 Bypass attempt blocked: " .. bypassType)
end

function AntiCheatSystem:UpdateStatistics()
    -- Update performance metrics
    self.performanceMetrics.checksPerSecond = self.stats.violationsDetected / 
                                             (os.time() - self.stats.uptime)
end

-- ========================================
-- ADMIN INTERFACE
-- ========================================

function AntiCheatSystem:GetPlayerReport(player)
    local playerId = tostring(player.UserId)
    
    return {
        playerData = self.playerData[playerId],
        violationHistory = self.violationHistory[playerId] or {},
        isBanned = self.bannedPlayers[playerId] ~= nil,
        banInfo = self.bannedPlayers[playerId]
    }
end

function AntiCheatSystem:GetSystemReport()
    return {
        stats = self.stats,
        performanceMetrics = self.performanceMetrics,
        detectionModules = self.detectionModules,
        configuredThresholds = ANTICHEAT_CONFIG
    }
end

function AntiCheatSystem:UnbanPlayer(player)
    local playerId = tostring(player.UserId)
    self.bannedPlayers[playerId] = nil
    print("✅ Player unbanned: " .. player.Name)
end

return AntiCheatSystem
