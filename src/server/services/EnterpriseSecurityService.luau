-- EnterpriseSecurityService.luau
-- Advanced security monitoring, anti-cheat, and threat detection system
-- Provides real-time security analysis, player behavior monitoring, and automated threat response

local Players = game:GetService("Players")
local HttpService = game:GetService("HttpService")
local RunService = game:GetService("RunService")
local TeleportService = game:GetService("TeleportService")
local DataStoreService = game:GetService("DataStoreService")

local EnterpriseSecurityService = {}
EnterpriseSecurityService.__index = EnterpriseSecurityService

-- ========================================
-- SECURITY CONFIGURATION
-- ========================================

local SECURITY_CONFIG = {
    -- Anti-cheat settings
    enableAntiCheat = true,
    enableBehaviorAnalysis = true,
    enableRealTimeScanning = true,
    
    -- Threat detection thresholds
    suspiciousActivityThreshold = 5, -- Actions per second
    velocityThreshold = 100, -- Studs per second
    teleportThreshold = 50, -- Studs instantaneous movement
    
    -- Monitoring intervals
    securityScanInterval = 5, -- seconds
    behaviorAnalysisInterval = 10, -- seconds
    threatAssessmentInterval = 30, -- seconds
    
    -- Response actions
    enableAutoKick = true,
    enableAutoTempBan = true,
    kickThreshold = 3, -- Violations before kick
    tempBanThreshold = 5, -- Violations before temp ban
    
    -- Whitelist (trusted players)
    trustedPlayers = {},
    
    -- Rate limiting
    maxActionsPerSecond = 10,
    maxRequestsPerMinute = 60
}

-- Security violation types
local VIOLATION_TYPES = {
    SPEED_HACK = "Speed Hack",
    TELEPORT_HACK = "Teleport Hack",
    FLY_HACK = "Fly Hack",
    NOCLIP_HACK = "NoClip Hack",
    SPAM_DETECTION = "Spam Detection",
    SUSPICIOUS_BEHAVIOR = "Suspicious Behavior",
    EXPLOIT_ATTEMPT = "Exploit Attempt",
    RATE_LIMIT_EXCEEDED = "Rate Limit Exceeded"
}

-- ========================================
-- ENTERPRISE SECURITY SERVICE
-- ========================================

function EnterpriseSecurityService.new(dependencies)
    local self = setmetatable({}, EnterpriseSecurityService)
    
    -- Dependencies
    self.dataService = dependencies and dependencies.EnterpriseDataService
    self.analyticsService = dependencies and dependencies.EnterpriseAnalyticsService
    self.monitoringService = dependencies and dependencies.EnterpriseMonitoringService
    
    -- Security data
    self.playerProfiles = {}
    self.securityViolations = {}
    self.threatLevel = "Low"
    self.activeScanners = {}
    
    -- Real-time monitoring data
    self.playerPositions = {}
    self.playerVelocities = {}
    self.playerActions = {}
    self.rateLimiters = {}
    
    -- Security metrics
    self.securityMetrics = {
        totalViolations = 0,
        threatsBlocked = 0,
        playersKicked = 0,
        playersBanned = 0,
        exploitAttempts = 0
    }
    
    print("🛡️ [Security] Enterprise Security Service initialized")
    return self
end

-- ========================================
-- PLAYER SECURITY PROFILING
-- ========================================

function EnterpriseSecurityService:CreatePlayerProfile(player)
    local profile = {
        userId = player.UserId,
        username = player.Name,
        joinTime = tick(),
        lastSeen = tick(),
        
        -- Security metrics
        violationCount = 0,
        trustScore = 100, -- 0-100 scale
        riskLevel = "Low", -- Low, Medium, High, Critical
        
        -- Behavior tracking
        averageActivity = 0,
        movementPattern = {},
        actionHistory = {},
        chatHistory = {},
        
        -- Anti-cheat data
        suspiciousActivities = {},
        lastPositions = {},
        velocityHistory = {},
        
        -- Session data
        sessionDuration = 0,
        actionsPerSecond = 0,
        flaggedBehaviors = {}
    }
    
    self.playerProfiles[tostring(player.UserId)] = profile
    self.playerPositions[tostring(player.UserId)] = {}
    self.playerVelocities[tostring(player.UserId)] = {}
    self.playerActions[tostring(player.UserId)] = {}
    self.rateLimiters[tostring(player.UserId)] = {
        actions = {},
        requests = {}
    }
    
    print("🛡️ [Security] Player profile created for:", player.Name)
    return profile
end

function EnterpriseSecurityService:UpdatePlayerProfile(player)
    local profile = self.playerProfiles[tostring(player.UserId)]
    if not profile then
        return
    end
    
    local currentTime = tick()
    profile.lastSeen = currentTime
    profile.sessionDuration = currentTime - profile.joinTime
    
    -- Update behavior metrics
    self:AnalyzePlayerBehavior(player, profile)
    self:UpdateTrustScore(player, profile)
    self:AssessRiskLevel(player, profile)
end

function EnterpriseSecurityService:AnalyzePlayerBehavior(player, profile)
    if not player.Character then return end
    
    local humanoid = player.Character:FindFirstChild("Humanoid")
    local rootPart = player.Character:FindFirstChild("HumanoidRootPart")
    
    if not humanoid or not rootPart then return end
    
    local currentTime = tick()
    local userId = tostring(player.UserId)
    
    -- Track position and movement
    local currentPosition = rootPart.Position
    local lastPositions = self.playerPositions[userId]
    
    table.insert(lastPositions, {
        position = currentPosition,
        timestamp = currentTime
    })
    
    -- Keep only recent positions (last 30 seconds)
    while #lastPositions > 0 and currentTime - lastPositions[1].timestamp > 30 do
        table.remove(lastPositions, 1)
    end
    
    -- Calculate velocity if we have previous position
    if #lastPositions >= 2 then
        local prev = lastPositions[#lastPositions - 1]
        local timeDiff = currentTime - prev.timestamp
        local distance = (currentPosition - prev.position).Magnitude
        local velocity = distance / timeDiff
        
        table.insert(self.playerVelocities[userId], {
            velocity = velocity,
            timestamp = currentTime
        })
        
        -- Check for speed violations
        if velocity > SECURITY_CONFIG.velocityThreshold and not self:IsPlayerTrusted(player) then
            self:RecordViolation(player, VIOLATION_TYPES.SPEED_HACK, {
                velocity = velocity,
                threshold = SECURITY_CONFIG.velocityThreshold,
                position = currentPosition
            })
        end
        
        -- Check for teleport violations
        if distance > SECURITY_CONFIG.teleportThreshold and timeDiff < 0.1 then
            self:RecordViolation(player, VIOLATION_TYPES.TELEPORT_HACK, {
                distance = distance,
                timeDiff = timeDiff,
                position = currentPosition
            })
        end
    end
    
    -- Check for fly hack (sustained high Y velocity)
    if rootPart.AssemblyLinearVelocity.Y > 20 and humanoid:GetState() ~= Enum.HumanoidStateType.Jumping then
        local flyTime = 0
        for i = #self.playerVelocities[userId], math.max(1, #self.playerVelocities[userId] - 10), -1 do
            local entry = self.playerVelocities[userId][i]
            if entry and entry.velocity and currentTime - entry.timestamp < 2 then
                flyTime = flyTime + 0.1
            end
        end
        
        if flyTime > 1.5 then -- Flying for more than 1.5 seconds
            self:RecordViolation(player, VIOLATION_TYPES.FLY_HACK, {
                flyTime = flyTime,
                yVelocity = rootPart.AssemblyLinearVelocity.Y
            })
        end
    end
end

function EnterpriseSecurityService:UpdateTrustScore(player, profile)
    local baseScore = 100
    local violationPenalty = profile.violationCount * 5
    local timeBonusMultiplier = math.min(profile.sessionDuration / 3600, 2) -- Max 2x bonus for 1+ hour sessions
    
    profile.trustScore = math.max(0, baseScore - violationPenalty + (timeBonusMultiplier * 5))
end

function EnterpriseSecurityService:AssessRiskLevel(player, profile)
    if profile.trustScore >= 80 then
        profile.riskLevel = "Low"
    elseif profile.trustScore >= 60 then
        profile.riskLevel = "Medium"
    elseif profile.trustScore >= 40 then
        profile.riskLevel = "High"
    else
        profile.riskLevel = "Critical"
    end
end

-- ========================================
-- VIOLATION DETECTION AND HANDLING
-- ========================================

function EnterpriseSecurityService:RecordViolation(player, violationType, details)
    local violation = {
        userId = player.UserId,
        username = player.Name,
        violationType = violationType,
        timestamp = os.time(),
        details = details,
        serverSession = game.JobId
    }
    
    table.insert(self.securityViolations, violation)
    
    -- Update player profile
    local profile = self.playerProfiles[tostring(player.UserId)]
    if profile then
        profile.violationCount = profile.violationCount + 1
        table.insert(profile.suspiciousActivities, violation)
    end
    
    -- Update metrics
    self.securityMetrics.totalViolations = self.securityMetrics.totalViolations + 1
    self.securityMetrics.exploitAttempts = self.securityMetrics.exploitAttempts + 1
    
    -- Log to analytics
    if self.analyticsService then
        self.analyticsService:TrackEvent(player, "security_violation", {
            violationType = violationType,
            details = details,
            playerProfile = profile
        })
    end
    
    -- Determine response action
    self:DetermineSecurityResponse(player, violation)
    
    print(string.format("🚨 [Security] Violation recorded: %s by %s - %s", 
        violationType, player.Name, HttpService:JSONEncode(details)))
end

function EnterpriseSecurityService:DetermineSecurityResponse(player, violation)
    if self:IsPlayerTrusted(player) then
        print("🛡️ [Security] Trusted player violation ignored:", player.Name)
        return
    end
    
    local profile = self.playerProfiles[tostring(player.UserId)]
    if not profile then return end
    
    -- Progressive response based on violation count and risk level
    if profile.violationCount >= SECURITY_CONFIG.tempBanThreshold and profile.riskLevel == "Critical" then
        self:TempBanPlayer(player, violation)
    elseif profile.violationCount >= SECURITY_CONFIG.kickThreshold and profile.riskLevel ~= "Low" then
        self:KickPlayer(player, violation)
    else
        self:WarnPlayer(player, violation)
    end
end

function EnterpriseSecurityService:WarnPlayer(player, violation)
    -- Send warning message
    local message = string.format("⚠️ Security Warning: %s detected. Please play fairly!", violation.violationType)
    
    local success = pcall(function()
        player:Kick(message)
    end)
    
    if not success then
        print("🛡️ [Security] Failed to warn player:", player.Name)
    end
    
    print("⚠️ [Security] Player warned:", player.Name, violation.violationType)
end

function EnterpriseSecurityService:KickPlayer(player, violation)
    if not SECURITY_CONFIG.enableAutoKick then return end
    
    local message = string.format("🚫 You have been kicked for: %s. Repeated violations may result in a ban.", 
        violation.violationType)
    
    self.securityMetrics.playersKicked = self.securityMetrics.playersKicked + 1
    
    local success = pcall(function()
        player:Kick(message)
    end)
    
    if success then
        print("🚫 [Security] Player kicked:", player.Name, violation.violationType)
    else
        print("🛡️ [Security] Failed to kick player:", player.Name)
    end
end

function EnterpriseSecurityService:TempBanPlayer(player, violation)
    if not SECURITY_CONFIG.enableAutoTempBan then return end
    
    -- Store temp ban in data service
    if self.dataService then
        local banData = {
            userId = player.UserId,
            reason = violation.violationType,
            timestamp = os.time(),
            duration = 3600, -- 1 hour
            details = violation.details
        }
        
        spawn(function()
            self.dataService:SetAsync("TempBan_" .. player.UserId, banData)
        end)
    end
    
    self.securityMetrics.playersBanned = self.securityMetrics.playersBanned + 1
    
    local message = "🔒 You have been temporarily banned for security violations. Ban duration: 1 hour."
    
    local success = pcall(function()
        player:Kick(message)
    end)
    
    if success then
        print("🔒 [Security] Player temporarily banned:", player.Name, violation.violationType)
    else
        print("🛡️ [Security] Failed to temp ban player:", player.Name)
    end
end

-- ========================================
-- RATE LIMITING SYSTEM
-- ========================================

function EnterpriseSecurityService:CheckRateLimit(player, actionType)
    local userId = tostring(player.UserId)
    local limiter = self.rateLimiters[userId]
    if not limiter then return true end
    
    local currentTime = tick()
    
    -- Initialize action tracking
    if not limiter.actions[actionType] then
        limiter.actions[actionType] = {}
    end
    
    local actionHistory = limiter.actions[actionType]
    
    -- Clean old entries (older than 1 second)
    for i = #actionHistory, 1, -1 do
        if currentTime - actionHistory[i] > 1 then
            table.remove(actionHistory, i)
        end
    end
    
    -- Check if under limit
    if #actionHistory >= SECURITY_CONFIG.maxActionsPerSecond then
        self:RecordViolation(player, VIOLATION_TYPES.RATE_LIMIT_EXCEEDED, {
            actionType = actionType,
            actionsInSecond = #actionHistory,
            limit = SECURITY_CONFIG.maxActionsPerSecond
        })
        return false
    end
    
    -- Record this action
    table.insert(actionHistory, currentTime)
    return true
end

-- ========================================
-- THREAT ASSESSMENT
-- ========================================

function EnterpriseSecurityService:AssessGlobalThreatLevel()
    local totalPlayers = #Players:GetPlayers()
    if totalPlayers == 0 then
        self.threatLevel = "Low"
        return
    end
    
    local highRiskPlayers = 0
    local totalViolations = 0
    
    for _, profile in pairs(self.playerProfiles) do
        if profile.riskLevel == "High" or profile.riskLevel == "Critical" then
            highRiskPlayers = highRiskPlayers + 1
        end
        totalViolations = totalViolations + profile.violationCount
    end
    
    local highRiskPercent = highRiskPlayers / totalPlayers
    local avgViolationsPerPlayer = totalViolations / totalPlayers
    
    if highRiskPercent > 0.3 or avgViolationsPerPlayer > 5 then
        self.threatLevel = "Critical"
    elseif highRiskPercent > 0.15 or avgViolationsPerPlayer > 2 then
        self.threatLevel = "High"
    elseif highRiskPercent > 0.05 or avgViolationsPerPlayer > 1 then
        self.threatLevel = "Medium"
    else
        self.threatLevel = "Low"
    end
end

-- ========================================
-- SECURITY UTILITIES
-- ========================================

function EnterpriseSecurityService:IsPlayerTrusted(player)
    return table.find(SECURITY_CONFIG.trustedPlayers, player.UserId) ~= nil
end

function EnterpriseSecurityService:AddTrustedPlayer(userId)
    if not table.find(SECURITY_CONFIG.trustedPlayers, userId) then
        table.insert(SECURITY_CONFIG.trustedPlayers, userId)
        print("🛡️ [Security] Player added to trusted list:", userId)
    end
end

function EnterpriseSecurityService:RemoveTrustedPlayer(userId)
    local index = table.find(SECURITY_CONFIG.trustedPlayers, userId)
    if index then
        table.remove(SECURITY_CONFIG.trustedPlayers, index)
        print("🛡️ [Security] Player removed from trusted list:", userId)
    end
end

function EnterpriseSecurityService:GetPlayerSecurityReport(player)
    local profile = self.playerProfiles[tostring(player.UserId)]
    if not profile then return nil end
    
    return {
        username = profile.username,
        trustScore = profile.trustScore,
        riskLevel = profile.riskLevel,
        violationCount = profile.violationCount,
        sessionDuration = profile.sessionDuration,
        lastViolations = (function()
            local start = math.max(1, #profile.suspiciousActivities - 5)
            local result = {}
            for i = start, #profile.suspiciousActivities do
                table.insert(result, profile.suspiciousActivities[i])
            end
            return result
        end)()
    }
end

-- ========================================
-- SERVICE LIFECYCLE
-- ========================================

function EnterpriseSecurityService:Initialize()
    print("🚀 [Security] Initializing Enterprise Security Service...")
    
    -- Start real-time scanning
    if SECURITY_CONFIG.enableRealTimeScanning then
        self.activeScanners.realTime = RunService.Heartbeat:Connect(function()
            for _, player in pairs(Players:GetPlayers()) do
                if player.Character then
                    self:UpdatePlayerProfile(player)
                end
            end
        end)
    end
    
    -- Start periodic security scans
    spawn(function()
        while true do
            self:PerformSecurityScan()
            wait(SECURITY_CONFIG.securityScanInterval)
        end
    end)
    
    -- Start threat assessment
    spawn(function()
        while true do
            self:AssessGlobalThreatLevel()
            wait(SECURITY_CONFIG.threatAssessmentInterval)
        end
    end)
    
    print("✅ [Security] Enterprise Security Service initialized")
end

function EnterpriseSecurityService:Start()
    print("🎯 [Security] Starting Enterprise Security Service...")
    
    -- Connect to player events
    Players.PlayerAdded:Connect(function(player)
        self:CreatePlayerProfile(player)
        
        -- Check for existing temp ban
        if self.dataService then
            spawn(function()
                local banData = self.dataService:GetAsync("TempBan_" .. player.UserId)
                if banData then
                    local banTime = banData.timestamp + banData.duration
                    if os.time() < banTime then
                        local remainingTime = banTime - os.time()
                        player:Kick(string.format("🔒 You are temporarily banned. Time remaining: %d minutes", 
                            math.ceil(remainingTime / 60)))
                        return
                    else
                        -- Ban expired, remove it
                        self.dataService:RemoveAsync("TempBan_" .. player.UserId)
                    end
                end
            end)
        end
    end)
    
    Players.PlayerRemoving:Connect(function(player)
        local userId = tostring(player.UserId)
        self.playerProfiles[userId] = nil
        self.playerPositions[userId] = nil
        self.playerVelocities[userId] = nil
        self.playerActions[userId] = nil
        self.rateLimiters[userId] = nil
    end)
    
    print("✅ [Security] Enterprise Security Service started")
end

function EnterpriseSecurityService:Stop()
    print("🛑 [Security] Stopping Enterprise Security Service...")
    
    -- Disconnect all scanners
    for scannerName, connection in pairs(self.activeScanners) do
        if connection then
            connection:Disconnect()
            print("🛡️ [Security] Stopped scanner:", scannerName)
        end
    end
    
    print("✅ [Security] Enterprise Security Service stopped")
end

function EnterpriseSecurityService:HealthCheck()
    local healthyProfiles = 0
    for _, profile in pairs(self.playerProfiles) do
        if profile.riskLevel ~= "Critical" then
            healthyProfiles = healthyProfiles + 1
        end
    end
    
    return {
        isHealthy = self.threatLevel ~= "Critical",
        metrics = {
            threatLevel = self.threatLevel,
            totalViolations = self.securityMetrics.totalViolations,
            playersKicked = self.securityMetrics.playersKicked,
            playersBanned = self.securityMetrics.playersBanned,
            totalPlayers = #Players:GetPlayers(),
            healthyProfiles = healthyProfiles
        }
    }
end

function EnterpriseSecurityService:PerformSecurityScan()
    -- Scan for potential security issues
    for _, player in pairs(Players:GetPlayers()) do
        local profile = self.playerProfiles[tostring(player.UserId)]
        if profile and profile.riskLevel == "Critical" then
            print("🚨 [Security] Critical risk player detected:", player.Name)
        end
    end
end

-- ========================================
-- PUBLIC API
-- ========================================

function EnterpriseSecurityService:GetSecurityMetrics()
    return table.clone(self.securityMetrics)
end

function EnterpriseSecurityService:GetThreatLevel()
    return self.threatLevel
end

function EnterpriseSecurityService:GetPlayerProfile(player)
    return self.playerProfiles[tostring(player.UserId)]
end

function EnterpriseSecurityService:GetViolationHistory()
    return table.clone(self.securityViolations)
end

function EnterpriseSecurityService:GetSystemHealth()
    return self:HealthCheck()
end

return EnterpriseSecurityService
