-- SecuritySessionManager.luau
-- Secure session management and authentication with rate limiting and abuse prevention
-- Implements comprehensive security measures for player sessions

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local HttpService = game:GetService("HttpService")
local DataStoreService = game:GetService("DataStoreService")
local MessagingService = game:GetService("MessagingService")

local SafeRequire = require(ReplicatedStorage.Shared.utils.SafeRequire)
local ServiceArchitecture = SafeRequire.require(ReplicatedStorage.Shared.core.ServiceArchitecture)

local SecuritySessionManager = {}
SecuritySessionManager.__index = SecuritySessionManager

-- Implement ISecuritySessionManager interface
setmetatable(SecuritySessionManager, {__index = ServiceArchitecture.ISecuritySessionManager})

-- ========================================
-- SECURITY CONFIGURATION
-- ========================================

local SECURITY_CONFIG = {
    -- Session settings
    sessionTimeout = 3600, -- 1 hour
    maxSessionsPerUser = 3,
    sessionRefreshInterval = 300, -- 5 minutes
    
    -- Authentication settings
    tokenLength = 32,
    maxLoginAttempts = 5,
    lockoutDuration = 900, -- 15 minutes
    
    -- Rate limiting (requests per minute)
    rateLimits = {
        login = 10,
        dataRequest = 60,
        gameAction = 120,
        purchase = 5,
        chat = 40,
        adminAction = 20
    },
    
    -- Abuse prevention
    suspiciousActivityThreshold = 10,
    autoBlockThreshold = 20,
    maxWarningsBeforeBlock = 5,
    
    -- IP tracking
    maxUsersPerIP = 5,
    ipBanDuration = 3600, -- 1 hour
    
    -- Geographic restrictions (if needed)
    allowedRegions = {}, -- Empty = all regions allowed
    blockedRegions = {},
    
    -- Device fingerprinting
    trackDeviceFingerprints = true,
    maxDevicesPerUser = 3
}

local SESSION_STATES = {
    ACTIVE = "active",
    EXPIRED = "expired", 
    REVOKED = "revoked",
    SUSPENDED = "suspended",
    LOCKED = "locked"
}

local ABUSE_TYPES = {
    RATE_LIMIT_EXCEEDED = "rate_limit_exceeded",
    SUSPICIOUS_LOGIN = "suspicious_login",
    MULTIPLE_SESSIONS = "multiple_sessions",
    IP_HOPPING = "ip_hopping",
    DEVICE_SWITCHING = "device_switching",
    EXPLOIT_ATTEMPT = "exploit_attempt",
    UNAUTHORIZED_ACCESS = "unauthorized_access"
}

-- ========================================
-- CORE SESSION MANAGER
-- ========================================

function SecuritySessionManager.new()
    local self = setmetatable({}, SecuritySessionManager)
    
    -- Data stores
    self.sessionStore = DataStoreService:GetDataStore("SecuritySessions")
    self.authStore = DataStoreService:GetDataStore("Authentication")
    self.abuseStore = DataStoreService:GetDataStore("AbuseTracking")
    self.ipStore = DataStoreService:GetDataStore("IPTracking")
    
    -- Active sessions
    self.activeSessions = {} -- sessionId -> session data
    self.playerSessions = {} -- playerId -> sessionId
    self.ipSessions = {} -- IP -> {sessionIds}
    
    -- Rate limiting
    self.rateLimitCounters = {} -- playerId -> {action -> count}
    self.globalRateLimits = {} -- action -> count
    
    -- Abuse tracking
    self.suspiciousActivity = {} -- playerId -> activities
    self.blockedPlayers = {} -- playerId -> block info
    self.blockedIPs = {} -- IP -> block info
    
    -- Device fingerprinting
    self.deviceFingerprints = {} -- playerId -> {fingerprints}
    
    -- Security events
    self.securityEvents = {} -- Recent security events
    
    -- Statistics
    self.stats = {
        sessionsCreated = 0,
        sessionsExpired = 0,
        authenticationsSuccessful = 0,
        authenticationsFailed = 0,
        rateLimitViolations = 0,
        abuseEventsDetected = 0,
        playersBlocked = 0,
        ipsBlocked = 0
    }
    
    -- Initialize systems
    self:InitializeRateLimiting()
    self:InitializeSessionCleanup()
    self:InitializeAbuseMonitoring()
    
    print("🔐 SecuritySessionManager initialized with comprehensive protection")
    return self
end

-- ========================================
-- SESSION MANAGEMENT
-- ========================================

function SecuritySessionManager:CreateSession(player, authData)
    local playerId = tostring(player.UserId)
    local playerIP = self:GetPlayerIP(player)
    
    -- Pre-authentication checks
    local preAuthCheck = self:PerformPreAuthenticationChecks(player, playerIP)
    if not preAuthCheck.allowed then
        return {
            success = false,
            error = preAuthCheck.reason,
            blocked = true
        }
    end
    
    -- Check for existing sessions
    local existingSessions = self:GetPlayerSessions(playerId)
    if #existingSessions >= SECURITY_CONFIG.maxSessionsPerUser then
        -- Revoke oldest session
        self:RevokeSession(existingSessions[1])
    end
    
    -- Create new session
    local sessionId = self:GenerateSessionToken()
    local deviceFingerprint = self:GenerateDeviceFingerprint(player)
    
    local session = {
        sessionId = sessionId,
        playerId = playerId,
        playerName = player.Name,
        createdAt = os.time(),
        lastActivity = os.time(),
        expiresAt = os.time() + SECURITY_CONFIG.sessionTimeout,
        state = SESSION_STATES.ACTIVE,
        
        -- Security metadata
        playerIP = playerIP,
        deviceFingerprint = deviceFingerprint,
        userAgent = self:GetUserAgent(player),
        location = self:GetPlayerLocation(player),
        
        -- Tracking data
        activityCount = 0,
        lastRateLimitReset = os.time(),
        securityFlags = {},
        
        -- Authentication data
        authMethod = authData.method or "roblox_native",
        authTimestamp = os.time(),
        multiFactorVerified = authData.mfaVerified or false
    }
    
    -- Store session
    self.activeSessions[sessionId] = session
    self.playerSessions[playerId] = sessionId
    
    -- Track IP sessions
    if not self.ipSessions[playerIP] then
        self.ipSessions[playerIP] = {}
    end
    table.insert(self.ipSessions[playerIP], sessionId)
    
    -- Store device fingerprint
    if not self.deviceFingerprints[playerId] then
        self.deviceFingerprints[playerId] = {}
    end
    table.insert(self.deviceFingerprints[playerId], deviceFingerprint)
    
    -- Update statistics
    self.stats.sessionsCreated = self.stats.sessionsCreated + 1
    self.stats.authenticationsSuccessful = self.stats.authenticationsSuccessful + 1
    
    -- Log security event
    self:LogSecurityEvent("session_created", {
        playerId = playerId,
        sessionId = sessionId,
        playerIP = playerIP,
        deviceFingerprint = deviceFingerprint
    })
    
    print("🔑 Session created for " .. player.Name .. " (" .. sessionId .. ")")
    
    return {
        success = true,
        sessionId = sessionId,
        expiresAt = session.expiresAt,
        securityLevel = self:CalculateSecurityLevel(session)
    }
end

function SecuritySessionManager:ValidateSession(sessionId)
    local session = self.activeSessions[sessionId]
    
    if not session then
        return {valid = false, reason = "Session not found"}
    end
    
    -- Check expiration
    if os.time() > session.expiresAt then
        self:ExpireSession(sessionId)
        return {valid = false, reason = "Session expired"}
    end
    
    -- Check session state
    if session.state ~= SESSION_STATES.ACTIVE then
        return {valid = false, reason = "Session not active: " .. session.state}
    end
    
    -- Update last activity
    session.lastActivity = os.time()
    session.activityCount = session.activityCount + 1
    
    return {
        valid = true,
        session = session,
        securityLevel = self:CalculateSecurityLevel(session)
    }
end

function SecuritySessionManager:RefreshSession(sessionId)
    local session = self.activeSessions[sessionId]
    
    if not session or session.state ~= SESSION_STATES.ACTIVE then
        return {success = false, reason = "Invalid session for refresh"}
    end
    
    -- Extend expiration
    session.expiresAt = os.time() + SECURITY_CONFIG.sessionTimeout
    session.lastActivity = os.time()
    
    self:LogSecurityEvent("session_refreshed", {
        sessionId = sessionId,
        playerId = session.playerId,
        newExpiresAt = session.expiresAt
    })
    
    return {
        success = true,
        expiresAt = session.expiresAt
    }
end

function SecuritySessionManager:RevokeSession(sessionId, reason)
    local session = self.activeSessions[sessionId]
    
    if session then
        session.state = SESSION_STATES.REVOKED
        session.revokedAt = os.time()
        session.revokeReason = reason or "manual_revocation"
        
        -- Clean up tracking
        self.playerSessions[session.playerId] = nil
        
        if self.ipSessions[session.playerIP] then
            for i, id in ipairs(self.ipSessions[session.playerIP]) do
                if id == sessionId then
                    table.remove(self.ipSessions[session.playerIP], i)
                    break
                end
            end
        end
        
        self:LogSecurityEvent("session_revoked", {
            sessionId = sessionId,
            playerId = session.playerId,
            reason = reason
        })
        
        print("🚫 Session revoked: " .. sessionId .. " - " .. (reason or "Unknown"))
        return {success = true}
    end
    
    return {success = false, reason = "Session not found"}
end

function SecuritySessionManager:ExpireSession(sessionId)
    local session = self.activeSessions[sessionId]
    
    if session then
        session.state = SESSION_STATES.EXPIRED
        session.expiredAt = os.time()
        
        self.stats.sessionsExpired = self.stats.sessionsExpired + 1
        
        -- Clean up tracking
        self.playerSessions[session.playerId] = nil
        
        self:LogSecurityEvent("session_expired", {
            sessionId = sessionId,
            playerId = session.playerId
        })
    end
end

-- ========================================
-- RATE LIMITING
-- ========================================

function SecuritySessionManager:InitializeRateLimiting()
    -- Event-driven rate limit reset system
    local rateLimitResetEvent = Instance.new("BindableEvent")
    
    local function scheduleRateLimitReset()
        wait(60) -- Reset every minute
        rateLimitResetEvent:Fire()
    end
    
    rateLimitResetEvent.Event:Connect(function()
        self:ResetRateLimits()
        spawn(scheduleRateLimitReset)
    end)
    
    -- Start the rate limit reset cycle
    spawn(scheduleRateLimitReset)
end

function SecuritySessionManager:CheckRateLimit(player, action)
    local playerId = tostring(player.UserId)
    local minute = math.floor(os.time() / 60)
    local key = playerId .. "_" .. action .. "_" .. minute
    
    -- Get current count
    local currentCount = self.rateLimitCounters[key] or 0
    local limit = SECURITY_CONFIG.rateLimits[action] or 60
    
    if currentCount >= limit then
        self:HandleRateLimitViolation(player, action, currentCount, limit)
        return false
    end
    
    -- Increment counter
    self.rateLimitCounters[key] = currentCount + 1
    
    -- Global rate limiting
    local globalKey = action .. "_" .. minute
    local globalCount = self.globalRateLimits[globalKey] or 0
    local globalLimit = (SECURITY_CONFIG.rateLimits[action] or 60) * 100 -- 100x player limit
    
    if globalCount >= globalLimit then
        self:HandleGlobalRateLimit(action, globalCount, globalLimit)
        return false
    end
    
    self.globalRateLimits[globalKey] = globalCount + 1
    return true
end

function SecuritySessionManager:HandleRateLimitViolation(player, action, count, limit)
    local playerId = tostring(player.UserId)
    
    self.stats.rateLimitViolations = self.stats.rateLimitViolations + 1
    
    -- Log abuse
    self:LogAbuseEvent(player, ABUSE_TYPES.RATE_LIMIT_EXCEEDED, {
        action = action,
        count = count,
        limit = limit,
        severity = math.min(count / limit, 5)
    })
    
    -- Escalate if severe
    if count > limit * 2 then
        self:FlagSuspiciousActivity(player, "severe_rate_limit_violation", {
            action = action,
            count = count,
            limit = limit
        })
    end
    
    print("⚠️ Rate limit violation: " .. player.Name .. " - " .. action .. " (" .. count .. "/" .. limit .. ")")
end

function SecuritySessionManager:ResetRateLimits()
    local currentMinute = math.floor(os.time() / 60)
    
    -- Clean up old rate limit entries
    for key in pairs(self.rateLimitCounters) do
        local minute = tonumber(string.match(key, "_(%d+)$"))
        if minute and minute < currentMinute then
            self.rateLimitCounters[key] = nil
        end
    end
    
    for key in pairs(self.globalRateLimits) do
        local minute = tonumber(string.match(key, "_(%d+)$"))
        if minute and minute < currentMinute then
            self.globalRateLimits[key] = nil
        end
    end
end

-- ========================================
-- ABUSE PREVENTION
-- ========================================

function SecuritySessionManager:InitializeAbuseMonitoring()
    -- Event-driven abuse monitoring system
    local abuseMonitoringEvent = Instance.new("BindableEvent")
    
    local function scheduleAbuseMonitoring()
        -- Adaptive interval based on recent suspicious activity
        local recentActivityCount = #self.securityEvents
        local interval = recentActivityCount > 20 and 180 or 300 -- More frequent checks with higher activity
        wait(interval)
        abuseMonitoringEvent:Fire()
    end
    
    abuseMonitoringEvent.Event:Connect(function()
        self:AnalyzeSuspiciousActivity()
        spawn(scheduleAbuseMonitoring)
    end)
    
    -- Start the abuse monitoring cycle
    spawn(scheduleAbuseMonitoring)
end

function SecuritySessionManager:PerformPreAuthenticationChecks(player, playerIP)
    local playerId = tostring(player.UserId)
    
    -- Check if player is blocked
    if self.blockedPlayers[playerId] then
        local blockInfo = self.blockedPlayers[playerId]
        if os.time() < blockInfo.expiresAt then
            return {
                allowed = false,
                reason = "Player is blocked: " .. blockInfo.reason
            }
        else
            -- Block expired, remove it
            self.blockedPlayers[playerId] = nil
        end
    end
    
    -- Check if IP is blocked
    if self.blockedIPs[playerIP] then
        local blockInfo = self.blockedIPs[playerIP]
        if os.time() < blockInfo.expiresAt then
            return {
                allowed = false,
                reason = "IP is blocked: " .. blockInfo.reason
            }
        else
            -- Block expired, remove it
            self.blockedIPs[playerIP] = nil
        end
    end
    
    -- Check IP session limits
    local ipSessions = self.ipSessions[playerIP] or {}
    if #ipSessions >= SECURITY_CONFIG.maxUsersPerIP then
        self:LogAbuseEvent(player, ABUSE_TYPES.MULTIPLE_SESSIONS, {
            playerIP = playerIP,
            sessionCount = #ipSessions,
            limit = SECURITY_CONFIG.maxUsersPerIP
        })
        
        return {
            allowed = false,
            reason = "Too many users from this IP address"
        }
    end
    
    -- Check device fingerprints
    if SECURITY_CONFIG.trackDeviceFingerprints then
        local playerFingerprints = self.deviceFingerprints[playerId] or {}
        if #playerFingerprints >= SECURITY_CONFIG.maxDevicesPerUser then
            self:FlagSuspiciousActivity(player, "multiple_devices", {
                deviceCount = #playerFingerprints,
                limit = SECURITY_CONFIG.maxDevicesPerUser
            })
        end
    end
    
    return {allowed = true}
end

function SecuritySessionManager:LogAbuseEvent(player, abuseType, details)
    local playerId = tostring(player.UserId)
    
    local abuseEvent = {
        timestamp = os.time(),
        playerId = playerId,
        playerName = player.Name,
        abuseType = abuseType,
        details = details,
        severity = details.severity or 1,
        playerIP = self:GetPlayerIP(player)
    }
    
    -- Add to suspicious activity tracking
    if not self.suspiciousActivity[playerId] then
        self.suspiciousActivity[playerId] = {}
    end
    table.insert(self.suspiciousActivity[playerId], abuseEvent)
    
    self.stats.abuseEventsDetected = self.stats.abuseEventsDetected + 1
    
    self:LogSecurityEvent("abuse_detected", abuseEvent)
end

function SecuritySessionManager:FlagSuspiciousActivity(player, activityType, details)
    local playerId = tostring(player.UserId)
    
    local activity = {
        timestamp = os.time(),
        activityType = activityType,
        details = details,
        escalated = false
    }
    
    if not self.suspiciousActivity[playerId] then
        self.suspiciousActivity[playerId] = {}
    end
    table.insert(self.suspiciousActivity[playerId], activity)
    
    -- Check if escalation is needed
    local recentActivities = self:GetRecentSuspiciousActivity(playerId, 300) -- 5 minutes
    if #recentActivities >= SECURITY_CONFIG.suspiciousActivityThreshold then
        self:EscalateSuspiciousActivity(player, recentActivities)
    end
    
    print("🚨 Suspicious activity flagged: " .. player.Name .. " - " .. activityType)
end

function SecuritySessionManager:EscalateSuspiciousActivity(player, activities)
    local playerId = tostring(player.UserId)
    
    -- Calculate risk score
    local riskScore = 0
    for _, activity in ipairs(activities) do
        riskScore = riskScore + (activity.details.severity or 1)
    end
    
    if riskScore >= SECURITY_CONFIG.autoBlockThreshold then
        self:BlockPlayer(player, "Automated block due to suspicious activity", 3600) -- 1 hour block
    else
        self:WarnPlayer(player, "Suspicious activity detected")
    end
end

function SecuritySessionManager:AnalyzeSuspiciousActivity()
    for playerId, activities in pairs(self.suspiciousActivity) do
        local recentActivities = {}
        local cutoffTime = os.time() - 3600 -- Last hour
        
        for _, activity in ipairs(activities) do
            if activity.timestamp > cutoffTime then
                table.insert(recentActivities, activity)
            end
        end
        
        -- Update with only recent activities
        self.suspiciousActivity[playerId] = recentActivities
        
        -- Analyze patterns
        if #recentActivities > 0 then
            self:AnalyzeActivityPatterns(playerId, recentActivities)
        end
    end
end

function SecuritySessionManager:AnalyzeActivityPatterns(playerId, activities)
    -- Pattern analysis for different types of abuse
    local activityTypes = {}
    for _, activity in ipairs(activities) do
        activityTypes[activity.activityType] = (activityTypes[activity.activityType] or 0) + 1
    end
    
    -- Check for repeated patterns
    for activityType, count in pairs(activityTypes) do
        if count >= 5 then
            local player = Players:GetPlayerByUserId(tonumber(playerId))
            if player then
                self:FlagSuspiciousActivity(player, "repeated_pattern", {
                    pattern = activityType,
                    count = count,
                    severity = math.min(count / 5, 3)
                })
            end
        end
    end
end

-- ========================================
-- PLAYER BLOCKING AND WARNINGS
-- ========================================

function SecuritySessionManager:BlockPlayer(player, reason, duration)
    local playerId = tostring(player.UserId)
    duration = duration or 3600 -- Default 1 hour
    
    local blockInfo = {
        reason = reason,
        timestamp = os.time(),
        expiresAt = os.time() + duration,
        duration = duration,
        blockedBy = "SecuritySystem"
    }
    
    self.blockedPlayers[playerId] = blockInfo
    self.stats.playersBlocked = self.stats.playersBlocked + 1
    
    -- Revoke current session
    local sessionId = self.playerSessions[playerId]
    if sessionId then
        self:RevokeSession(sessionId, "player_blocked")
    end
    
    self:LogSecurityEvent("player_blocked", {
        playerId = playerId,
        reason = reason,
        duration = duration,
        expiresAt = blockInfo.expiresAt
    })
    
    print("🚫 Player blocked: " .. player.Name .. " for " .. duration .. "s - " .. reason)
    
    -- Kick player
    player:Kick("You have been temporarily blocked: " .. reason)
end

function SecuritySessionManager:BlockIP(playerIP, reason, duration)
    duration = duration or SECURITY_CONFIG.ipBanDuration
    
    local blockInfo = {
        reason = reason,
        timestamp = os.time(),
        expiresAt = os.time() + duration,
        duration = duration,
        blockedBy = "SecuritySystem"
    }
    
    self.blockedIPs[playerIP] = blockInfo
    self.stats.ipsBlocked = self.stats.ipsBlocked + 1
    
    -- Kick all players from this IP
    local sessions = self.ipSessions[playerIP] or {}
    for _, sessionId in ipairs(sessions) do
        local session = self.activeSessions[sessionId]
        if session then
            local player = Players:GetPlayerByUserId(tonumber(session.playerId))
            if player then
                player:Kick("IP address blocked: " .. reason)
            end
            self:RevokeSession(sessionId, "ip_blocked")
        end
    end
    
    self:LogSecurityEvent("ip_blocked", {
        playerIP = playerIP,
        reason = reason,
        duration = duration,
        expiresAt = blockInfo.expiresAt
    })
    
    print("🚫 IP blocked: " .. playerIP .. " for " .. duration .. "s - " .. reason)
end

function SecuritySessionManager:WarnPlayer(player, message)
    -- In a real implementation, this would send a warning to the player
    print("⚠️ Warning sent to " .. player.Name .. ": " .. message)
end

-- ========================================
-- UTILITY FUNCTIONS
-- ========================================

function SecuritySessionManager:GenerateSessionToken()
    return HttpService:GenerateGUID(false):gsub("-", ""):sub(1, SECURITY_CONFIG.tokenLength)
end

function SecuritySessionManager:GenerateDeviceFingerprint(player)
    -- Generate a fingerprint based on available device information
    local fingerprint = {
        userId = player.UserId,
        timestamp = os.time(),
        -- In a real implementation, would include more device-specific data
        randomComponent = HttpService:GenerateGUID(false):sub(1, 8)
    }
    
    return HttpService:JSONEncode(fingerprint)
end

function SecuritySessionManager:GetPlayerIP(player)
    -- In a real implementation, this would get actual IP
    return "192.168.1." .. (player.UserId % 255)
end

function SecuritySessionManager:GetUserAgent(player)
    -- In a real implementation, this would get actual user agent
    return "RobloxPlayer/Unknown"
end

function SecuritySessionManager:GetPlayerLocation(player)
    -- In a real implementation, this would use IP geolocation
    return {country = "Unknown", region = "Unknown"}
end

function SecuritySessionManager:CalculateSecurityLevel(session)
    local level = 1 -- Base level
    
    if session.multiFactorVerified then level = level + 1 end
    if session.activityCount > 100 then level = level + 1 end
    if os.time() - session.createdAt > 1800 then level = level + 1 end -- 30 minutes
    
    return math.min(level, 5)
end

function SecuritySessionManager:GetPlayerSessions(playerId)
    local sessions = {}
    for sessionId, session in pairs(self.activeSessions) do
        if session.playerId == playerId and session.state == SESSION_STATES.ACTIVE then
            table.insert(sessions, sessionId)
        end
    end
    return sessions
end

function SecuritySessionManager:GetRecentSuspiciousActivity(playerId, timeWindow)
    local activities = self.suspiciousActivity[playerId] or {}
    local recent = {}
    local cutoffTime = os.time() - timeWindow
    
    for _, activity in ipairs(activities) do
        if activity.timestamp > cutoffTime then
            table.insert(recent, activity)
        end
    end
    
    return recent
end

function SecuritySessionManager:LogSecurityEvent(eventType, eventData)
    local event = {
        timestamp = os.time(),
        eventType = eventType,
        eventData = eventData,
        serverId = game.JobId
    }
    
    table.insert(self.securityEvents, event)
    
    -- Keep only recent events (last 1000)
    if #self.securityEvents > 1000 then
        table.remove(self.securityEvents, 1)
    end
end

-- ========================================
-- CLEANUP AND MAINTENANCE
-- ========================================

function SecuritySessionManager:InitializeSessionCleanup()
    -- Event-driven session cleanup system
    local sessionCleanupEvent = Instance.new("BindableEvent")
    
    local function scheduleSessionCleanup()
        -- Adaptive interval based on active session count
        local sessionCount = 0
        for _ in pairs(self.activeSessions) do sessionCount = sessionCount + 1 end
        
        local interval = sessionCount > 50 and (SECURITY_CONFIG.sessionRefreshInterval * 0.5) or SECURITY_CONFIG.sessionRefreshInterval
        wait(interval)
        sessionCleanupEvent:Fire()
    end
    
    sessionCleanupEvent.Event:Connect(function()
        self:CleanupExpiredSessions()
        spawn(scheduleSessionCleanup)
    end)
    
    -- Start the session cleanup cycle
    spawn(scheduleSessionCleanup)
end

function SecuritySessionManager:CleanupExpiredSessions()
    local currentTime = os.time()
    local expiredSessions = {}
    
    for sessionId, session in pairs(self.activeSessions) do
        if currentTime > session.expiresAt and session.state == SESSION_STATES.ACTIVE then
            table.insert(expiredSessions, sessionId)
        end
    end
    
    for _, sessionId in ipairs(expiredSessions) do
        self:ExpireSession(sessionId)
    end
    
    if #expiredSessions > 0 then
        print("🧹 Cleaned up " .. #expiredSessions .. " expired sessions")
    end
end

-- ========================================
-- ADMIN AND REPORTING
-- ========================================

function SecuritySessionManager:GetSecurityReport()
    return {
        stats = self.stats,
        activeSessions = 0,
        blockedPlayers = 0,
        blockedIPs = 0,
        recentSecurityEvents = #self.securityEvents
    }
    
    -- Count active items
    for _ in pairs(self.activeSessions) do
        _.activeSessions = _.activeSessions + 1
    end
    
    for _ in pairs(self.blockedPlayers) do
        _.blockedPlayers = _.blockedPlayers + 1
    end
    
    for _ in pairs(self.blockedIPs) do
        _.blockedIPs = _.blockedIPs + 1
    end
end

function SecuritySessionManager:GetPlayerSecurityInfo(player)
    local playerId = tostring(player.UserId)
    local sessionId = self.playerSessions[playerId]
    
    return {
        currentSession = sessionId and self.activeSessions[sessionId],
        suspiciousActivities = self.suspiciousActivity[playerId] or {},
        isBlocked = self.blockedPlayers[playerId] ~= nil,
        blockInfo = self.blockedPlayers[playerId],
        deviceFingerprints = self.deviceFingerprints[playerId] or {}
    }
end

return SecuritySessionManager
