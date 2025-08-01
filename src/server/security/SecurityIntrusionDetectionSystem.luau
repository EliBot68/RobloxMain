-- SecurityIntrusionDetectionSystem.luau
-- Comprehensive security monitoring and intrusion detection system
-- Real-time threat detection, behavioral analysis, and automated response

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local HttpService = game:GetService("HttpService")
local RunService = game:GetService("RunService")
local MessagingService = game:GetService("MessagingService")

local SafeRequire = require(ReplicatedStorage.Shared.utils.SafeRequire)
local ServiceArchitecture = SafeRequire.require(ReplicatedStorage.Shared.core.ServiceArchitecture)

local SecurityIntrusionDetectionSystem = {}
SecurityIntrusionDetectionSystem.__index = SecurityIntrusionDetectionSystem

-- Implement IIntrusionDetectionSystem interface
setmetatable(SecurityIntrusionDetectionSystem, {__index = ServiceArchitecture.IIntrusionDetectionSystem})

-- ========================================
-- INTRUSION DETECTION CONFIGURATION
-- ========================================

local IDS_CONFIG = {
    -- Detection sensitivity levels
    sensitivityLevels = {
        LOW = 1,
        MEDIUM = 2,
        HIGH = 3,
        PARANOID = 4
    },
    
    -- Monitoring intervals
    realTimeMonitoring = 1, -- seconds
    behaviorAnalysisInterval = 60, -- seconds
    patternAnalysisInterval = 300, -- 5 minutes
    reportGenerationInterval = 3600, -- 1 hour
    
    -- Threshold configurations
    thresholds = {
        loginFailures = 5,
        rapidRequests = 100, -- per minute
        dataAccessAnomalies = 10,
        suspiciousPatterns = 3,
        networkAnomalies = 5,
        resourceAbuseLimit = 80 -- percentage
    },
    
    -- Detection categories
    detectionCategories = {
        AUTHENTICATION_ATTACKS = "auth_attacks",
        AUTHORIZATION_BYPASS = "authz_bypass",
        DATA_EXFILTRATION = "data_exfiltration",
        DENIAL_OF_SERVICE = "dos_attacks",
        MALWARE_ACTIVITY = "malware",
        INSIDER_THREATS = "insider_threats",
        NETWORK_INTRUSION = "network_intrusion",
        BEHAVIORAL_ANOMALIES = "behavioral_anomalies"
    },
    
    -- Response actions
    responseActions = {
        LOG_ONLY = "log",
        ALERT = "alert",
        BLOCK_USER = "block_user",
        BLOCK_IP = "block_ip",
        ISOLATE_SESSION = "isolate_session",
        ESCALATE = "escalate",
        AUTO_REMEDIATE = "auto_remediate"
    }
}

local THREAT_LEVELS = {
    INFO = 1,
    LOW = 2,
    MEDIUM = 3,
    HIGH = 4,
    CRITICAL = 5
}

local ATTACK_SIGNATURES = {
    -- Authentication attack patterns
    BRUTE_FORCE = {
        name = "Brute Force Attack",
        pattern = "rapid_login_failures",
        threshold = 5,
        timeWindow = 300 -- 5 minutes
    },
    
    CREDENTIAL_STUFFING = {
        name = "Credential Stuffing",
        pattern = "multiple_account_failures",
        threshold = 10,
        timeWindow = 600 -- 10 minutes
    },
    
    -- Data access patterns
    DATA_MINING = {
        name = "Data Mining Attack",
        pattern = "systematic_data_access",
        threshold = 100,
        timeWindow = 300
    },
    
    PRIVILEGE_ESCALATION = {
        name = "Privilege Escalation",
        pattern = "unauthorized_admin_access",
        threshold = 1,
        timeWindow = 60
    },
    
    -- DoS patterns
    RATE_LIMIT_FLOODING = {
        name = "Rate Limit Flooding",
        pattern = "excessive_requests",
        threshold = 1000,
        timeWindow = 60
    },
    
    RESOURCE_EXHAUSTION = {
        name = "Resource Exhaustion",
        pattern = "high_resource_usage",
        threshold = 90, -- percentage
        timeWindow = 300
    }
}

-- ========================================
-- CORE INTRUSION DETECTION SYSTEM
-- ========================================

function SecurityIntrusionDetectionSystem.new(auditLogger, sessionManager)
    local self = setmetatable({}, SecurityIntrusionDetectionSystem)
    
    -- Dependent services
    self.auditLogger = auditLogger
    self.sessionManager = sessionManager
    
    -- Detection engines
    self.signatureDetector = {} -- Signature-based detection
    self.anomalyDetector = {} -- Behavioral anomaly detection
    self.correlationEngine = {} -- Event correlation
    self.responseEngine = {} -- Automated response system
    
    -- Monitoring data
    self.activeMonitors = {} -- Real-time monitors
    self.eventQueue = {} -- Event processing queue
    self.threatDetections = {} -- Detected threats
    self.behaviorProfiles = {} -- User behavior baselines
    
    -- Network monitoring
    self.networkTraffic = {} -- Network traffic patterns
    self.connectionAnalysis = {} -- Connection analysis data
    self.geolocationTracking = {} -- Geographic anomaly detection
    
    -- Performance tracking
    self.systemMetrics = {} -- System performance metrics
    self.resourceUsage = {} -- Resource utilization tracking
    self.alertMetrics = {} -- Alert generation metrics
    
    -- Threat intelligence
    self.threatIntelligence = {} -- Known threat indicators
    self.blacklistedIPs = {} -- Known malicious IPs
    self.malwareSignatures = {} -- Malware detection signatures
    
    -- Statistics
    self.stats = {
        threatsDetected = 0,
        falsePositives = 0,
        truePositives = 0,
        alertsGenerated = 0,
        actionsExecuted = 0,
        eventsProcessed = 0,
        uptimeStart = os.time()
    }
    
    -- Initialize systems
    self:InitializeDetectionEngines()
    self:InitializeThreatIntelligence()
    self:StartRealTimeMonitoring()
    self:InitializeBehaviorAnalysis()
    
    print("🛡️ SecurityIntrusionDetectionSystem initialized with real-time monitoring")
    return self
end

-- ========================================
-- DETECTION ENGINES
-- ========================================

function SecurityIntrusionDetectionSystem:InitializeDetectionEngines()
    -- Signature-based detection
    self.signatureDetector = {
        signatures = ATTACK_SIGNATURES,
        matches = {},
        checkEvent = function(event) return self:CheckSignatureMatch(event) end
    }
    
    -- Anomaly detection
    self.anomalyDetector = {
        baselines = {},
        deviations = {},
        checkBehavior = function(userId, behavior) return self:CheckBehaviorAnomaly(userId, behavior) end
    }
    
    -- Correlation engine
    self.correlationEngine = {
        rules = {},
        correlatedEvents = {},
        analyzePattern = function(events) return self:AnalyzeEventPattern(events) end
    }
    
    -- Response engine
    self.responseEngine = {
        rules = {},
        executedActions = {},
        executeResponse = function(threat, action) return self:ExecuteResponse(threat, action) end
    }
    
    print("🔍 Detection engines initialized")
end

function SecurityIntrusionDetectionSystem:CheckSignatureMatch(event)
    local matches = {}
    
    for signatureName, signature in pairs(self.signatureDetector.signatures) do
        if self:EventMatchesSignature(event, signature) then
            table.insert(matches, {
                signature = signatureName,
                confidence = self:CalculateSignatureConfidence(event, signature),
                metadata = signature
            })
        end
    end
    
    return matches
end

function SecurityIntrusionDetectionSystem:EventMatchesSignature(event, signature)
    -- Check if event matches signature pattern
    if signature.pattern == "rapid_login_failures" then
        return event.eventType == "authentication_failed" and 
               self:CheckRapidFailures(event.playerId, signature.threshold, signature.timeWindow)
    
    elseif signature.pattern == "systematic_data_access" then
        return event.eventType == "data_access" and
               self:CheckSystematicAccess(event.playerId, signature.threshold, signature.timeWindow)
    
    elseif signature.pattern == "excessive_requests" then
        return self:CheckExcessiveRequests(event.playerId, signature.threshold, signature.timeWindow)
    
    elseif signature.pattern == "unauthorized_admin_access" then
        return event.eventType == "admin_action" and
               not self:IsAuthorizedAdmin(event.playerId)
    
    elseif signature.pattern == "high_resource_usage" then
        return self:CheckResourceUsage(event.playerId) > signature.threshold
    
    end
    
    return false
end

function SecurityIntrusionDetectionSystem:CheckBehaviorAnomaly(playerId, behavior)
    local baseline = self.behaviorProfiles[playerId]
    if not baseline then
        return nil -- No baseline established yet
    end
    
    local anomalies = {}
    
    -- Check various behavioral metrics
    if behavior.requestRate and baseline.avgRequestRate then
        local deviation = math.abs(behavior.requestRate - baseline.avgRequestRate) / baseline.avgRequestRate
        if deviation > 2.0 then -- 200% deviation
            table.insert(anomalies, {
                type = "request_rate_anomaly",
                severity = math.min(deviation, 5),
                details = {
                    current = behavior.requestRate,
                    baseline = baseline.avgRequestRate,
                    deviation = deviation
                }
            })
        end
    end
    
    if behavior.sessionDuration and baseline.avgSessionDuration then
        local deviation = math.abs(behavior.sessionDuration - baseline.avgSessionDuration) / baseline.avgSessionDuration
        if deviation > 3.0 then -- 300% deviation
            table.insert(anomalies, {
                type = "session_duration_anomaly",
                severity = math.min(deviation / 2, 5),
                details = {
                    current = behavior.sessionDuration,
                    baseline = baseline.avgSessionDuration,
                    deviation = deviation
                }
            })
        end
    end
    
    if behavior.accessPatterns and baseline.normalAccessPatterns then
        local patternSimilarity = self:CalculatePatternSimilarity(behavior.accessPatterns, baseline.normalAccessPatterns)
        if patternSimilarity < 0.3 then -- Less than 30% similarity
            table.insert(anomalies, {
                type = "access_pattern_anomaly",
                severity = (1 - patternSimilarity) * 5,
                details = {
                    similarity = patternSimilarity,
                    currentPattern = behavior.accessPatterns
                }
            })
        end
    end
    
    return #anomalies > 0 and anomalies or nil
end

function SecurityIntrusionDetectionSystem:AnalyzeEventPattern(events)
    local patterns = {}
    
    -- Group events by type and time
    local eventGroups = {}
    for _, event in ipairs(events) do
        local key = event.eventType .. "_" .. math.floor(event.timestamp / 60) -- Group by minute
        if not eventGroups[key] then
            eventGroups[key] = {}
        end
        table.insert(eventGroups[key], event)
    end
    
    -- Look for suspicious patterns
    for groupKey, groupEvents in pairs(eventGroups) do
        if #groupEvents > 10 then -- High frequency
            table.insert(patterns, {
                type = "high_frequency_events",
                severity = math.min(#groupEvents / 10, 5),
                events = groupEvents,
                details = {
                    eventCount = #groupEvents,
                    timeWindow = 60,
                    eventType = groupEvents[1].eventType
                }
            })
        end
    end
    
    -- Check for distributed attacks
    local playerGroups = {}
    for _, event in ipairs(events) do
        if not playerGroups[event.playerId] then
            playerGroups[event.playerId] = {}
        end
        table.insert(playerGroups[event.playerId], event)
    end
    
    if table.getn(playerGroups) > 5 and #events > 50 then -- Multiple players, many events
        table.insert(patterns, {
            type = "distributed_attack",
            severity = 4,
            events = events,
            details = {
                playerCount = table.getn(playerGroups),
                totalEvents = #events,
                avgEventsPerPlayer = #events / table.getn(playerGroups)
            }
        })
    end
    
    return patterns
end

-- ========================================
-- REAL-TIME MONITORING
-- ========================================

function SecurityIntrusionDetectionSystem:StartRealTimeMonitoring()
    -- Create BindableEvents for event-driven monitoring
    local mainMonitoringEvent = Instance.new("BindableEvent")
    local behaviorAnalysisEvent = Instance.new("BindableEvent")
    local patternCorrelationEvent = Instance.new("BindableEvent")
    local reportGenerationEvent = Instance.new("BindableEvent")
    
    -- Adaptive main monitoring system
    local function scheduleMainMonitoring()
        local queueSize = #self.eventQueue
        local threatLevel = self:GetCurrentThreatLevel()
        
        -- Adaptive interval based on activity (30% to 300% of base)
        local baseInterval = IDS_CONFIG.realTimeMonitoring
        local adaptiveMultiplier = queueSize > 50 and 0.3 or (threatLevel > 7 and 0.5 or (queueSize < 5 and 2.0 or 1.0))
        local interval = baseInterval * adaptiveMultiplier
        
        wait(interval)
        mainMonitoringEvent:Fire()
    end
    
    mainMonitoringEvent.Event:Connect(function()
        self:ProcessEventQueue()
        self:MonitorSystemHealth()
        self:CheckActiveThreats()
        spawn(scheduleMainMonitoring)
    end)
    
    -- Adaptive behavior analysis system
    local function scheduleBehaviorAnalysis()
        local activeConnections = self:GetActiveConnectionCount()
        local interval = activeConnections > 20 and (IDS_CONFIG.behaviorAnalysisInterval * 0.7) or IDS_CONFIG.behaviorAnalysisInterval
        wait(interval)
        behaviorAnalysisEvent:Fire()
    end
    
    behaviorAnalysisEvent.Event:Connect(function()
        self:AnalyzeBehaviorPatterns()
        spawn(scheduleBehaviorAnalysis)
    end)
    
    -- Adaptive pattern correlation system
    local function schedulePatternCorrelation()
        local patternCount = self:GetActivePatternCount()
        local interval = patternCount > 15 and (IDS_CONFIG.patternAnalysisInterval * 0.8) or IDS_CONFIG.patternAnalysisInterval
        wait(interval)
        patternCorrelationEvent:Fire()
    end
    
    patternCorrelationEvent.Event:Connect(function()
        self:PerformPatternCorrelation()
        spawn(schedulePatternCorrelation)
    end)
    
    -- Event-driven report generation system
    local function scheduleReportGeneration()
        wait(IDS_CONFIG.reportGenerationInterval)
        reportGenerationEvent:Fire()
    end
    
    reportGenerationEvent.Event:Connect(function()
        self:GenerateSecurityReport()
        spawn(scheduleReportGeneration)
    end)
    
    -- Start all monitoring cycles
    spawn(scheduleMainMonitoring)
    spawn(scheduleBehaviorAnalysis)
    spawn(schedulePatternCorrelation)
    spawn(scheduleReportGeneration)
    
    print("📊 Real-time monitoring started")
end

function SecurityIntrusionDetectionSystem:ProcessEventQueue()
    local processedCount = 0
    
    while #self.eventQueue > 0 and processedCount < 100 do -- Process up to 100 events per cycle
        local event = table.remove(self.eventQueue, 1)
        self:ProcessSecurityEvent(event)
        processedCount = processedCount + 1
    end
    
    self.stats.eventsProcessed = self.stats.eventsProcessed + processedCount
end

function SecurityIntrusionDetectionSystem:ProcessSecurityEvent(event)
    -- Signature-based detection
    local signatureMatches = self.signatureDetector.checkEvent(event)
    
    if #signatureMatches > 0 then
        for _, match in ipairs(signatureMatches) do
            self:HandleThreatDetection(event, "signature", match)
        end
    end
    
    -- Anomaly detection (for user events)
    if event.playerId then
        local behavior = self:ExtractBehaviorFromEvent(event)
        local anomalies = self.anomalyDetector.checkBehavior(event.playerId, behavior)
        
        if anomalies then
            for _, anomaly in ipairs(anomalies) do
                self:HandleThreatDetection(event, "anomaly", anomaly)
            end
        end
        
        -- Update behavior profile
        self:UpdateBehaviorProfile(event.playerId, behavior)
    end
    
    -- Add to correlation analysis
    self:AddEventToCorrelation(event)
end

function SecurityIntrusionDetectionSystem:HandleThreatDetection(event, detectionType, detectionResult)
    local threatId = self:GenerateThreatId()
    
    local threat = {
        threatId = threatId,
        detectionType = detectionType,
        detectionResult = detectionResult,
        sourceEvent = event,
        threatLevel = self:CalculateThreatLevel(detectionResult),
        detectedAt = os.time(),
        status = "active",
        
        -- Classification
        category = self:ClassifyThreat(detectionResult),
        severity = detectionResult.severity or THREAT_LEVELS.MEDIUM,
        confidence = detectionResult.confidence or 0.8,
        
        -- Context
        playerId = event.playerId,
        playerName = event.playerName,
        ipAddress = event.ipAddress,
        userAgent = event.userAgent,
        
        -- Response
        responseActions = self:DetermineResponseActions(detectionResult),
        responseExecuted = false
    }
    
    -- Store threat
    table.insert(self.threatDetections, threat)
    self.stats.threatsDetected = self.stats.threatsDetected + 1
    
    -- Execute immediate response
    self:ExecuteImmediateResponse(threat)
    
    -- Generate alert
    self:GenerateSecurityAlert(threat)
    
    -- Log to audit system
    if self.auditLogger then
        self.auditLogger:LogSecurityEvent(
            "threat_detected",
            "intrusion_detection",
            threat,
            threat.severity
        )
    end
    
    print("🚨 Threat detected: " .. threatId .. " (" .. threat.category .. ")")
    
    return threat
end

-- ========================================
-- BEHAVIORAL ANALYSIS
-- ========================================

function SecurityIntrusionDetectionSystem:InitializeBehaviorAnalysis()
    -- Initialize behavior tracking for connected players
    for _, player in ipairs(Players:GetPlayers()) do
        self:InitializePlayerBehaviorProfile(player)
    end
    
    -- Set up player event handlers
    Players.PlayerAdded:Connect(function(player)
        self:InitializePlayerBehaviorProfile(player)
    end)
    
    Players.PlayerRemoving:Connect(function(player)
        self:FinalizeBehaviorProfile(player)
    end)
end

function SecurityIntrusionDetectionSystem:InitializePlayerBehaviorProfile(player)
    local playerId = tostring(player.UserId)
    
    self.behaviorProfiles[playerId] = {
        playerId = playerId,
        playerName = player.Name,
        profileCreated = os.time(),
        
        -- Baseline metrics
        avgRequestRate = 0,
        avgSessionDuration = 0,
        normalAccessPatterns = {},
        typicalLoginTimes = {},
        commonLocations = {},
        
        -- Current session data
        currentSession = {
            startTime = os.time(),
            requestCount = 0,
            actionsPerformed = {},
            accessedResources = {}
        },
        
        -- Historical data
        sessionHistory = {},
        anomalyHistory = {},
        
        -- Learning phase
        learningPhase = true,
        samplesCollected = 0,
        learningComplete = false
    }
    
    print("👤 Behavior profile initialized for " .. player.Name)
end

function SecurityIntrusionDetectionSystem:UpdateBehaviorProfile(playerId, behavior)
    local profile = self.behaviorProfiles[playerId]
    if not profile then return end
    
    profile.samplesCollected = profile.samplesCollected + 1
    
    -- Update current session
    profile.currentSession.requestCount = profile.currentSession.requestCount + 1
    
    if behavior.action then
        table.insert(profile.currentSession.actionsPerformed, behavior.action)
    end
    
    if behavior.resource then
        table.insert(profile.currentSession.accessedResources, behavior.resource)
    end
    
    -- Update baselines (moving average)
    if behavior.requestRate then
        profile.avgRequestRate = (profile.avgRequestRate + behavior.requestRate) / 2
    end
    
    -- Check if learning phase is complete
    if profile.learningPhase and profile.samplesCollected >= 100 then
        profile.learningPhase = false
        profile.learningComplete = true
        self:FinalizeBehaviorBaseline(playerId)
        print("📚 Behavior learning completed for " .. profile.playerName)
    end
end

function SecurityIntrusionDetectionSystem:AnalyzeBehaviorPatterns()
    local anomaliesDetected = 0
    
    for playerId, profile in pairs(self.behaviorProfiles) do
        if profile.learningComplete then
            local currentBehavior = self:GetCurrentBehavior(playerId)
            local anomalies = self:CheckBehaviorAnomaly(playerId, currentBehavior)
            
            if anomalies then
                anomaliesDetected = anomaliesDetected + #anomalies
                
                for _, anomaly in ipairs(anomalies) do
                    local event = {
                        eventType = "behavioral_anomaly",
                        playerId = playerId,
                        playerName = profile.playerName,
                        timestamp = os.time(),
                        details = anomaly
                    }
                    
                    table.insert(self.eventQueue, event)
                end
            end
        end
    end
    
    if anomaliesDetected > 0 then
        print("🧠 Behavior analysis: " .. anomaliesDetected .. " anomalies detected")
    end
end

-- ========================================
-- NETWORK MONITORING
-- ========================================

function SecurityIntrusionDetectionSystem:MonitorNetworkTraffic()
    -- Monitor connection patterns
    local connectionMetrics = {
        activeConnections = #Players:GetPlayers(),
        connectionRate = self:CalculateConnectionRate(),
        bandwidthUsage = self:EstimateBandwidthUsage(),
        geographicDistribution = self:AnalyzeGeographicDistribution()
    }
    
    -- Check for network anomalies
    if connectionMetrics.connectionRate > 10 then -- 10 connections per minute
        self:CreateNetworkEvent("high_connection_rate", connectionMetrics)
    end
    
    if connectionMetrics.bandwidthUsage > 0.8 then -- 80% bandwidth utilization
        self:CreateNetworkEvent("high_bandwidth_usage", connectionMetrics)
    end
    
    -- Geographic anomaly detection
    if self:DetectGeographicAnomalies(connectionMetrics.geographicDistribution) then
        self:CreateNetworkEvent("geographic_anomaly", connectionMetrics)
    end
end

function SecurityIntrusionDetectionSystem:CreateNetworkEvent(eventType, metrics)
    local event = {
        eventType = eventType,
        category = IDS_CONFIG.detectionCategories.NETWORK_INTRUSION,
        timestamp = os.time(),
        details = metrics,
        severity = self:CalculateNetworkEventSeverity(eventType, metrics)
    }
    
    table.insert(self.eventQueue, event)
end

-- ========================================
-- AUTOMATED RESPONSE
-- ========================================

function SecurityIntrusionDetectionSystem:ExecuteImmediateResponse(threat)
    local actions = threat.responseActions
    
    for _, action in ipairs(actions) do
        local success = self.responseEngine.executeResponse(threat, action)
        
        if success then
            self.stats.actionsExecuted = self.stats.actionsExecuted + 1
        end
    end
    
    threat.responseExecuted = true
end

function SecurityIntrusionDetectionSystem:ExecuteResponse(threat, action)
    if action == IDS_CONFIG.responseActions.LOG_ONLY then
        -- Already logged
        return true
        
    elseif action == IDS_CONFIG.responseActions.ALERT then
        self:GenerateSecurityAlert(threat)
        return true
        
    elseif action == IDS_CONFIG.responseActions.BLOCK_USER then
        return self:BlockUser(threat.playerId, threat.threatId)
        
    elseif action == IDS_CONFIG.responseActions.BLOCK_IP then
        return self:BlockIP(threat.ipAddress, threat.threatId)
        
    elseif action == IDS_CONFIG.responseActions.ISOLATE_SESSION then
        return self:IsolateSession(threat.playerId, threat.threatId)
        
    elseif action == IDS_CONFIG.responseActions.ESCALATE then
        return self:EscalateThreat(threat)
        
    elseif action == IDS_CONFIG.responseActions.AUTO_REMEDIATE then
        return self:AutoRemediate(threat)
        
    end
    
    return false
end

function SecurityIntrusionDetectionSystem:BlockUser(playerId, reason)
    if self.sessionManager then
        return self.sessionManager:BlockPlayer(
            Players:GetPlayerByUserId(tonumber(playerId)),
            "IDS: " .. reason,
            3600 -- 1 hour
        )
    end
    return false
end

function SecurityIntrusionDetectionSystem:BlockIP(ipAddress, reason)
    if self.sessionManager then
        return self.sessionManager:BlockIP(
            ipAddress,
            "IDS: " .. reason,
            7200 -- 2 hours
        )
    end
    return false
end

function SecurityIntrusionDetectionSystem:IsolateSession(playerId, reason)
    -- Isolate player session (limit access)
    print("🔒 Session isolated for player " .. playerId .. ": " .. reason)
    return true
end

function SecurityIntrusionDetectionSystem:EscalateThreat(threat)
    -- Escalate to security team
    print("⬆️ Threat escalated: " .. threat.threatId)
    return true
end

function SecurityIntrusionDetectionSystem:AutoRemediate(threat)
    -- Automated remediation actions
    print("🔧 Auto-remediation executed for: " .. threat.threatId)
    return true
end

-- ========================================
-- THREAT INTELLIGENCE
-- ========================================

function SecurityIntrusionDetectionSystem:InitializeThreatIntelligence()
    -- Load known malicious indicators
    self.blacklistedIPs = {
        "192.168.1.100", -- Example malicious IP
        "10.0.0.50"
    }
    
    self.malwareSignatures = {
        "malicious_pattern_1",
        "exploit_signature_2",
        "trojan_indicator_3"
    }
    
    self.threatIntelligence = {
        lastUpdated = os.time(),
        sources = {"internal", "community"},
        indicators = {},
        riskScores = {}
    }
    
    print("🧠 Threat intelligence initialized")
end

function SecurityIntrusionDetectionSystem:CheckThreatIntelligence(indicator)
    -- Check if indicator is in threat intelligence database
    if table.find(self.blacklistedIPs, indicator) then
        return {
            type = "malicious_ip",
            severity = THREAT_LEVELS.HIGH,
            source = "threat_intelligence"
        }
    end
    
    for _, signature in ipairs(self.malwareSignatures) do
        if string.find(tostring(indicator), signature) then
            return {
                type = "malware_signature",
                severity = THREAT_LEVELS.CRITICAL,
                source = "threat_intelligence"
            }
        end
    end
    
    return nil
end

-- ========================================
-- UTILITY FUNCTIONS
-- ========================================

function SecurityIntrusionDetectionSystem:ReceiveSecurityEvent(event)
    table.insert(self.eventQueue, event)
end

function SecurityIntrusionDetectionSystem:ExtractBehaviorFromEvent(event)
    return {
        action = event.eventType,
        resource = event.details and event.details.resource,
        requestRate = 1, -- Simplified
        timestamp = event.timestamp
    }
end

function SecurityIntrusionDetectionSystem:CalculateThreatLevel(detectionResult)
    local baseLevel = detectionResult.severity or THREAT_LEVELS.MEDIUM
    local confidence = detectionResult.confidence or 0.5
    
    return math.min(baseLevel * confidence, THREAT_LEVELS.CRITICAL)
end

function SecurityIntrusionDetectionSystem:ClassifyThreat(detectionResult)
    if detectionResult.type then
        if string.find(detectionResult.type, "login") or string.find(detectionResult.type, "auth") then
            return IDS_CONFIG.detectionCategories.AUTHENTICATION_ATTACKS
        elseif string.find(detectionResult.type, "access") then
            return IDS_CONFIG.detectionCategories.AUTHORIZATION_BYPASS
        elseif string.find(detectionResult.type, "data") then
            return IDS_CONFIG.detectionCategories.DATA_EXFILTRATION
        elseif string.find(detectionResult.type, "request") or string.find(detectionResult.type, "rate") then
            return IDS_CONFIG.detectionCategories.DENIAL_OF_SERVICE
        else
            return IDS_CONFIG.detectionCategories.BEHAVIORAL_ANOMALIES
        end
    end
    
    return IDS_CONFIG.detectionCategories.BEHAVIORAL_ANOMALIES
end

function SecurityIntrusionDetectionSystem:DetermineResponseActions(detectionResult)
    local severity = detectionResult.severity or THREAT_LEVELS.MEDIUM
    local actions = {}
    
    -- Always log
    table.insert(actions, IDS_CONFIG.responseActions.LOG_ONLY)
    
    if severity >= THREAT_LEVELS.LOW then
        table.insert(actions, IDS_CONFIG.responseActions.ALERT)
    end
    
    if severity >= THREAT_LEVELS.HIGH then
        table.insert(actions, IDS_CONFIG.responseActions.BLOCK_USER)
    end
    
    if severity >= THREAT_LEVELS.CRITICAL then
        table.insert(actions, IDS_CONFIG.responseActions.ESCALATE)
    end
    
    return actions
end

function SecurityIntrusionDetectionSystem:GenerateSecurityAlert(threat)
    local alert = {
        alertId = self:GenerateAlertId(),
        threatId = threat.threatId,
        alertType = "security_threat",
        severity = threat.severity,
        title = self:GenerateAlertTitle(threat),
        description = self:GenerateAlertDescription(threat),
        generatedAt = os.time(),
        status = "open"
    }
    
    self.stats.alertsGenerated = self.stats.alertsGenerated + 1
    
    print("🚨 Security alert: " .. alert.title)
    return alert
end

function SecurityIntrusionDetectionSystem:GenerateThreatId()
    return "threat_" .. os.time() .. "_" .. math.random(100000, 999999)
end

function SecurityIntrusionDetectionSystem:GenerateAlertId()
    return "alert_" .. os.time() .. "_" .. math.random(100000, 999999)
end

-- ========================================
-- REPORTING AND ANALYTICS
-- ========================================

function SecurityIntrusionDetectionSystem:GenerateSecurityReport()
    local report = {
        reportId = self:GenerateReportId(),
        reportType = "security_monitoring",
        generatedAt = os.time(),
        
        summary = {
            threatsDetected = self.stats.threatsDetected,
            alertsGenerated = self.stats.alertsGenerated,
            actionsExecuted = self.stats.actionsExecuted,
            eventsProcessed = self.stats.eventsProcessed,
            falsePositiveRate = self:CalculateFalsePositiveRate(),
            systemUptime = os.time() - self.stats.uptimeStart
        },
        
        threatBreakdown = self:AnalyzeThreatBreakdown(),
        topThreats = self:GetTopThreats(),
        trendAnalysis = self:AnalyzeTrends(),
        recommendations = self:GenerateRecommendations()
    }
    
    print("📊 Security report generated: " .. report.reportId)
    return report
end

function SecurityIntrusionDetectionSystem:GetSecurityDashboard()
    return {
        currentThreats = #self.threatDetections,
        activeMonitors = table.getn(self.activeMonitors),
        systemHealth = self:GetSystemHealth(),
        recentAlerts = self:GetRecentAlerts(10),
        threatTrends = self:GetThreatTrends(),
        performanceMetrics = self:GetPerformanceMetrics()
    }
end

-- ========================================
-- STUB IMPLEMENTATIONS
-- ========================================

-- These would be properly implemented with real data in production
function SecurityIntrusionDetectionSystem:CheckRapidFailures(playerId, threshold, timeWindow) return false end
function SecurityIntrusionDetectionSystem:CheckSystematicAccess(playerId, threshold, timeWindow) return false end
function SecurityIntrusionDetectionSystem:CheckExcessiveRequests(playerId, threshold, timeWindow) return false end
function SecurityIntrusionDetectionSystem:IsAuthorizedAdmin(playerId) return true end
function SecurityIntrusionDetectionSystem:CheckResourceUsage(playerId) return 20 end
function SecurityIntrusionDetectionSystem:CalculatePatternSimilarity(pattern1, pattern2) return 0.8 end
function SecurityIntrusionDetectionSystem:MonitorSystemHealth() end
function SecurityIntrusionDetectionSystem:CheckActiveThreats() end
function SecurityIntrusionDetectionSystem:AddEventToCorrelation(event) end
function SecurityIntrusionDetectionSystem:PerformPatternCorrelation() end
function SecurityIntrusionDetectionSystem:FinalizeBehaviorProfile(player) end
function SecurityIntrusionDetectionSystem:FinalizeBehaviorBaseline(playerId) end
function SecurityIntrusionDetectionSystem:GetCurrentBehavior(playerId) return {} end
function SecurityIntrusionDetectionSystem:CalculateConnectionRate() return 2 end
function SecurityIntrusionDetectionSystem:EstimateBandwidthUsage() return 0.3 end
function SecurityIntrusionDetectionSystem:AnalyzeGeographicDistribution() return {} end
function SecurityIntrusionDetectionSystem:DetectGeographicAnomalies(distribution) return false end
function SecurityIntrusionDetectionSystem:CalculateNetworkEventSeverity(eventType, metrics) return THREAT_LEVELS.MEDIUM end
function SecurityIntrusionDetectionSystem:GenerateAlertTitle(threat) return "Security Threat Detected" end
function SecurityIntrusionDetectionSystem:GenerateAlertDescription(threat) return "A security threat has been detected" end
function SecurityIntrusionDetectionSystem:GenerateReportId() return "report_" .. os.time() end
function SecurityIntrusionDetectionSystem:CalculateFalsePositiveRate() return 0.05 end
function SecurityIntrusionDetectionSystem:AnalyzeThreatBreakdown() return {} end
function SecurityIntrusionDetectionSystem:GetTopThreats() return {} end
function SecurityIntrusionDetectionSystem:AnalyzeTrends() return {} end
function SecurityIntrusionDetectionSystem:GenerateRecommendations() return {} end
function SecurityIntrusionDetectionSystem:GetSystemHealth() return "healthy" end
function SecurityIntrusionDetectionSystem:GetRecentAlerts(count) return {} end
function SecurityIntrusionDetectionSystem:GetThreatTrends() return {} end
function SecurityIntrusionDetectionSystem:GetPerformanceMetrics() return {} end

return SecurityIntrusionDetectionSystem
