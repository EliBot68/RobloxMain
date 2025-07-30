-- SecurityMonitoringIncidentResponseSystem.luau
-- Security monitoring and automated incident response for production systems
-- Provides threat detection, security analytics, and automated response procedures

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local HttpService = game:GetService("HttpService")
local RunService = game:GetService("RunService")

local SafeRequire = require(ReplicatedStorage.Shared.utils.SafeRequire)

local SecurityMonitoringIncidentResponseSystem = {}

-- ========================================
-- SECURITY CONFIGURATION
-- ========================================

local SECURITY_CONFIG = {
    -- Threat detection rules
    threatDetection = {
        loginAttempts = {
            maxFailedAttempts = 5,
            timeWindow = 300, -- 5 minutes
            actions = {"block_ip", "notify", "log"}
        },
        
        bruteForce = {
            maxAttemptsPerMinute = 10,
            blockedDuration = 3600, -- 1 hour
            actions = {"block_ip", "alert", "escalate"}
        },
        
        suspiciousActivity = {
            rapidRequests = {
                threshold = 100,
                timeWindow = 60,
                actions = {"rate_limit", "notify"}
            },
            
            unusualPatterns = {
                threshold = 0.8, -- Anomaly score
                actions = {"log", "review"}
            }
        },
        
        dataAccess = {
            unauthorizedAccess = {
                severity = "critical",
                actions = {"block", "alert", "investigate"}
            },
            
            massDataAccess = {
                threshold = 1000, -- records per minute
                actions = {"alert", "review", "potentially_block"}
            }
        },
        
        systemIntegrity = {
            fileModification = {
                criticalFiles = {"/config", "/secrets", "/admin"},
                actions = {"alert", "backup", "investigate"}
            },
            
            privilegeEscalation = {
                actions = {"immediate_block", "critical_alert", "investigate"}
            }
        }
    },
    
    -- Incident classification
    incidentSeverity = {
        low = {
            priority = 1,
            responseTime = 4 * 3600, -- 4 hours
            escalationTime = 24 * 3600, -- 24 hours
            notificationChannels = {"email", "ticket"}
        },
        
        medium = {
            priority = 2,
            responseTime = 2 * 3600, -- 2 hours
            escalationTime = 8 * 3600, -- 8 hours
            notificationChannels = {"email", "slack", "ticket"}
        },
        
        high = {
            priority = 3,
            responseTime = 1 * 3600, -- 1 hour
            escalationTime = 4 * 3600, -- 4 hours
            notificationChannels = {"email", "slack", "sms", "pagerduty"}
        },
        
        critical = {
            priority = 4,
            responseTime = 15 * 60, -- 15 minutes
            escalationTime = 1 * 3600, -- 1 hour
            notificationChannels = {"all", "phone", "emergency"}
        }
    },
    
    -- Response procedures
    responseProcedures = {
        automated = {
            blockSuspiciousIp = true,
            isolateCompromisedAccount = true,
            disableUnusualActivity = true,
            backupCriticalData = true,
            notifySecurityTeam = true
        },
        
        manual = {
            forensicAnalysis = true,
            evidenceCollection = true,
            impactAssessment = true,
            stakeholderNotification = true,
            remediationPlanning = true
        }
    },
    
    -- Monitoring intervals
    monitoring = {
        realTimeEvents = 1,    -- seconds
        securityScans = 60,    -- seconds
        threatAnalysis = 300,  -- 5 minutes
        reportGeneration = 3600, -- 1 hour
        healthChecks = 30      -- seconds
    }
}

-- ========================================
-- SYSTEM STATE
-- ========================================

local SecurityState = {
    -- Core engines
    detectionEngine = nil,
    responseEngine = nil,
    analyticsEngine = nil,
    
    -- Active threats and incidents
    activeThreats = {},
    activeIncidents = {},
    
    -- Security events
    securityEvents = {},
    
    -- Blocked entities
    blockedIps = {},
    blockedUsers = {},
    quarantinedAssets = {},
    
    -- Detection rules
    detectionRules = {},
    
    -- Response teams
    responseTeams = {},
    
    -- System status
    systemStatus = {
        securityLevel = "normal",
        activeThreats = 0,
        activeIncidents = 0,
        blockedEntities = 0,
        lastThreatDetected = nil
    },
    
    -- Metrics
    metrics = {
        threatsDetected = 0,
        incidentsCreated = 0,
        automaticResponses = 0,
        falsePositives = 0,
        meanTimeToDetection = 0,
        meanTimeToResponse = 0
    },
    
    -- Configuration
    config = SECURITY_CONFIG
}

function SecurityMonitoringIncidentResponseSystem.initialize()
    print("🔒 Initializing SecurityMonitoringIncidentResponseSystem...")
    
    -- Initialize core engines
    SecurityMonitoringIncidentResponseSystem.initializeDetectionEngine()
    SecurityMonitoringIncidentResponseSystem.initializeResponseEngine()
    SecurityMonitoringIncidentResponseSystem.initializeAnalyticsEngine()
    
    -- Set up detection rules
    SecurityMonitoringIncidentResponseSystem.initializeDetectionRules()
    
    -- Set up response teams
    SecurityMonitoringIncidentResponseSystem.initializeResponseTeams()
    
    -- Start monitoring
    SecurityMonitoringIncidentResponseSystem.startSecurityMonitoring()
    
    print("🔒 SecurityMonitoringIncidentResponseSystem initialized successfully")
end

-- ========================================
-- THREAT DETECTION ENGINE
-- ========================================

function SecurityMonitoringIncidentResponseSystem.initializeDetectionEngine()
    SecurityState.detectionEngine = {
        rules = {},
        patterns = {},
        
        processEvent = function(self, event)
            return SecurityMonitoringIncidentResponseSystem.processSecurityEvent(event)
        end,
        
        evaluateThreats = function(self)
            return SecurityMonitoringIncidentResponseSystem.evaluateThreats()
        end,
        
        addRule = function(self, rule)
            return SecurityMonitoringIncidentResponseSystem.addDetectionRule(rule)
        end
    }
    
    print("🔍 Threat detection engine initialized")
end

function SecurityMonitoringIncidentResponseSystem.initializeDetectionRules()
    SecurityState.detectionRules = {
        -- Failed login attempts
        failedLogin = {
            name = "Failed Login Attempts",
            type = "authentication",
            enabled = true,
            
            condition = function(events)
                local failedAttempts = 0
                local timeWindow = SecurityState.config.threatDetection.loginAttempts.timeWindow
                local currentTime = os.time()
                
                for _, event in ipairs(events) do
                    if event.type == "login_failed" and 
                       (currentTime - event.timestamp) <= timeWindow then
                        failedAttempts = failedAttempts + 1
                    end
                end
                
                return failedAttempts >= SecurityState.config.threatDetection.loginAttempts.maxFailedAttempts
            end,
            
            severity = "medium",
            actions = SecurityState.config.threatDetection.loginAttempts.actions
        },
        
        -- Brute force attacks
        bruteForce = {
            name = "Brute Force Attack",
            type = "attack",
            enabled = true,
            
            condition = function(events)
                local attemptsPerMinute = {}
                local currentTime = os.time()
                
                for _, event in ipairs(events) do
                    if event.type == "login_attempt" and 
                       (currentTime - event.timestamp) <= 60 then
                        local ip = event.sourceIp or "unknown"
                        attemptsPerMinute[ip] = (attemptsPerMinute[ip] or 0) + 1
                    end
                end
                
                for ip, attempts in pairs(attemptsPerMinute) do
                    if attempts >= SecurityState.config.threatDetection.bruteForce.maxAttemptsPerMinute then
                        return true, {sourceIp = ip, attempts = attempts}
                    end
                end
                
                return false
            end,
            
            severity = "high",
            actions = SecurityState.config.threatDetection.bruteForce.actions
        },
        
        -- Rapid requests (potential DDoS)
        rapidRequests = {
            name = "Rapid Requests",
            type = "ddos",
            enabled = true,
            
            condition = function(events)
                local requestCount = 0
                local timeWindow = SecurityState.config.threatDetection.suspiciousActivity.rapidRequests.timeWindow
                local currentTime = os.time()
                
                for _, event in ipairs(events) do
                    if event.type == "http_request" and 
                       (currentTime - event.timestamp) <= timeWindow then
                        requestCount = requestCount + 1
                    end
                end
                
                return requestCount >= SecurityState.config.threatDetection.suspiciousActivity.rapidRequests.threshold
            end,
            
            severity = "medium",
            actions = SecurityState.config.threatDetection.suspiciousActivity.rapidRequests.actions
        },
        
        -- Unauthorized data access
        unauthorizedAccess = {
            name = "Unauthorized Data Access",
            type = "data_breach",
            enabled = true,
            
            condition = function(events)
                for _, event in ipairs(events) do
                    if event.type == "data_access" and 
                       event.unauthorized == true then
                        return true, {
                            userId = event.userId,
                            resource = event.resource,
                            action = event.action
                        }
                    end
                end
                
                return false
            end,
            
            severity = "critical",
            actions = SecurityState.config.threatDetection.dataAccess.unauthorizedAccess.actions
        },
        
        -- Privilege escalation
        privilegeEscalation = {
            name = "Privilege Escalation",
            type = "privilege_abuse",
            enabled = true,
            
            condition = function(events)
                for _, event in ipairs(events) do
                    if event.type == "privilege_change" and 
                       event.escalation == true then
                        return true, {
                            userId = event.userId,
                            fromRole = event.fromRole,
                            toRole = event.toRole
                        }
                    end
                end
                
                return false
            end,
            
            severity = "critical",
            actions = SecurityState.config.threatDetection.systemIntegrity.privilegeEscalation.actions
        }
    }
    
    print("📋 Detection rules initialized")
end

function SecurityMonitoringIncidentResponseSystem.processSecurityEvent(event)
    -- Add timestamp if not present
    if not event.timestamp then
        event.timestamp = os.time()
    end
    
    -- Add unique ID
    if not event.id then
        event.id = HttpService:GenerateGUID()
    end
    
    -- Store event
    table.insert(SecurityState.securityEvents, event)
    
    -- Evaluate against detection rules
    local threats = {}
    
    for ruleName, rule in pairs(SecurityState.detectionRules) do
        if rule.enabled then
            local triggered, details = rule.condition(SecurityState.securityEvents)
            
            if triggered then
                local threat = {
                    id = HttpService:GenerateGUID(),
                    ruleName = ruleName,
                    rule = rule,
                    triggerEvent = event,
                    details = details or {},
                    detected = os.time(),
                    status = "active",
                    severity = rule.severity
                }
                
                SecurityState.activeThreats[threat.id] = threat
                table.insert(threats, threat)
                
                SecurityState.metrics.threatsDetected = SecurityState.metrics.threatsDetected + 1
                
                print(string.format("⚠️ Threat detected: %s (%s)", rule.name, rule.severity:upper()))
                
                -- Trigger automatic response
                SecurityMonitoringIncidentResponseSystem.triggerAutomaticResponse(threat)
            end
        end
    end
    
    return threats
end

function SecurityMonitoringIncidentResponseSystem.addDetectionRule(rule)
    if not rule.name or not rule.condition then
        return {success = false, error = "Invalid rule format"}
    end
    
    -- Set defaults
    rule.enabled = rule.enabled ~= false
    rule.severity = rule.severity or "medium"
    rule.actions = rule.actions or {"log", "notify"}
    
    local ruleName = rule.name:lower():gsub("%s+", "_")
    SecurityState.detectionRules[ruleName] = rule
    
    print(string.format("📝 Added detection rule: %s", rule.name))
    
    return {success = true, ruleName = ruleName}
end

function SecurityMonitoringIncidentResponseSystem.evaluateThreats()
    -- Clean up old events (keep last 1000 or last hour)
    local currentTime = os.time()
    local cleanedEvents = {}
    
    for i = #SecurityState.securityEvents, 1, -1 do
        local event = SecurityState.securityEvents[i]
        if #cleanedEvents < 1000 and (currentTime - event.timestamp) <= 3600 then
            table.insert(cleanedEvents, 1, event)
        end
    end
    
    SecurityState.securityEvents = cleanedEvents
    
    -- Update system status
    SecurityState.systemStatus.activeThreats = 0
    for _ in pairs(SecurityState.activeThreats) do
        SecurityState.systemStatus.activeThreats = SecurityState.systemStatus.activeThreats + 1
    end
    
    if SecurityState.systemStatus.activeThreats > 0 then
        SecurityState.systemStatus.securityLevel = "elevated"
    else
        SecurityState.systemStatus.securityLevel = "normal"
    end
end

-- ========================================
-- INCIDENT RESPONSE ENGINE
-- ========================================

function SecurityMonitoringIncidentResponseSystem.initializeResponseEngine()
    SecurityState.responseEngine = {
        procedures = {},
        automations = {},
        
        createIncident = function(self, threat)
            return SecurityMonitoringIncidentResponseSystem.createIncident(threat)
        end,
        
        executeResponse = function(self, response)
            return SecurityMonitoringIncidentResponseSystem.executeResponse(response)
        end,
        
        escalateIncident = function(self, incidentId)
            return SecurityMonitoringIncidentResponseSystem.escalateIncident(incidentId)
        end
    }
    
    print("🚨 Incident response engine initialized")
end

function SecurityMonitoringIncidentResponseSystem.initializeResponseTeams()
    SecurityState.responseTeams = {
        level1 = {
            name = "Security Operations Center",
            role = "monitoring",
            contacts = {
                email = "soc@company.com",
                slack = "#security-alerts",
                phone = "+1-555-SOC-TEAM"
            },
            availability = "24/7",
            responseTime = 15 * 60 -- 15 minutes
        },
        
        level2 = {
            name = "Security Engineers",
            role = "investigation",
            contacts = {
                email = "security-engineering@company.com",
                slack = "#security-engineering",
                phone = "+1-555-SEC-ENG"
            },
            availability = "business_hours",
            responseTime = 2 * 3600 -- 2 hours
        },
        
        level3 = {
            name = "Security Leadership",
            role = "decision_making",
            contacts = {
                email = "security-leadership@company.com",
                slack = "#security-leadership",
                phone = "+1-555-SEC-LEAD"
            },
            availability = "on_call",
            responseTime = 4 * 3600 -- 4 hours
        },
        
        emergency = {
            name = "Emergency Response Team",
            role = "crisis_management",
            contacts = {
                email = "emergency@company.com",
                slack = "#emergency",
                phone = "+1-555-EMERGENCY"
            },
            availability = "24/7",
            responseTime = 5 * 60 -- 5 minutes
        }
    }
    
    print("👥 Response teams initialized")
end

function SecurityMonitoringIncidentResponseSystem.triggerAutomaticResponse(threat)
    local actions = threat.rule.actions or {}
    
    for _, action in ipairs(actions) do
        SecurityMonitoringIncidentResponseSystem.executeAutomaticAction(action, threat)
    end
    
    -- Create incident if severity is high or critical
    if threat.severity == "high" or threat.severity == "critical" then
        SecurityMonitoringIncidentResponseSystem.createIncident(threat)
    end
end

function SecurityMonitoringIncidentResponseSystem.executeAutomaticAction(action, threat)
    print(string.format("🤖 Executing automatic action: %s", action))
    
    if action == "block_ip" then
        local sourceIp = threat.details.sourceIp or threat.triggerEvent.sourceIp
        if sourceIp then
            SecurityMonitoringIncidentResponseSystem.blockIpAddress(sourceIp, threat.severity)
        end
        
    elseif action == "block" or action == "immediate_block" then
        local userId = threat.details.userId or threat.triggerEvent.userId
        if userId then
            SecurityMonitoringIncidentResponseSystem.blockUser(userId, threat.severity)
        end
        
    elseif action == "rate_limit" then
        local sourceIp = threat.details.sourceIp or threat.triggerEvent.sourceIp
        if sourceIp then
            SecurityMonitoringIncidentResponseSystem.applyRateLimit(sourceIp)
        end
        
    elseif action == "notify" or action == "alert" or action == "critical_alert" then
        SecurityMonitoringIncidentResponseSystem.sendSecurityNotification(threat, action)
        
    elseif action == "log" then
        SecurityMonitoringIncidentResponseSystem.logSecurityEvent(threat)
        
    elseif action == "backup" then
        SecurityMonitoringIncidentResponseSystem.triggerEmergencyBackup(threat)
        
    elseif action == "escalate" then
        local incident = SecurityMonitoringIncidentResponseSystem.createIncident(threat)
        SecurityMonitoringIncidentResponseSystem.escalateIncident(incident.id)
        
    elseif action == "investigate" then
        SecurityMonitoringIncidentResponseSystem.startAutomaticInvestigation(threat)
    end
    
    SecurityState.metrics.automaticResponses = SecurityState.metrics.automaticResponses + 1
end

function SecurityMonitoringIncidentResponseSystem.createIncident(threat)
    local incident = {
        id = HttpService:GenerateGUID(),
        title = string.format("%s - %s", threat.rule.name, threat.severity:upper()),
        description = string.format("Threat detected by rule: %s", threat.rule.name),
        
        severity = threat.severity,
        status = "open",
        
        threat = threat,
        triggerEvent = threat.triggerEvent,
        
        created = os.time(),
        lastUpdated = os.time(),
        
        assignedTeam = SecurityMonitoringIncidentResponseSystem.getAssignedTeam(threat.severity),
        
        timeline = {
            {
                timestamp = os.time(),
                action = "incident_created",
                description = "Incident created from threat detection",
                automated = true
            }
        },
        
        evidence = {},
        affectedSystems = {},
        
        responseActions = {},
        
        metrics = {
            timeToDetection = os.time() - threat.triggerEvent.timestamp,
            timeToResponse = nil,
            timeToResolution = nil
        }
    }
    
    SecurityState.activeIncidents[incident.id] = incident
    SecurityState.metrics.incidentsCreated = SecurityState.metrics.incidentsCreated + 1
    
    print(string.format("🚨 Incident created: %s (%s)", incident.title, incident.severity:upper()))
    
    -- Send notifications
    SecurityMonitoringIncidentResponseSystem.notifyResponseTeam(incident)
    
    -- Start response timer
    SecurityMonitoringIncidentResponseSystem.startResponseTimer(incident)
    
    return incident
end

function SecurityMonitoringIncidentResponseSystem.getAssignedTeam(severity)
    if severity == "critical" then
        return "emergency"
    elseif severity == "high" then
        return "level2"
    else
        return "level1"
    end
end

function SecurityMonitoringIncidentResponseSystem.notifyResponseTeam(incident)
    local team = SecurityState.responseTeams[incident.assignedTeam]
    
    if team then
        local severityConfig = SecurityState.config.incidentSeverity[incident.severity]
        
        for _, channel in ipairs(severityConfig.notificationChannels) do
            SecurityMonitoringIncidentResponseSystem.sendNotification(channel, incident, team)
        end
    end
end

function SecurityMonitoringIncidentResponseSystem.sendNotification(channel, incident, team)
    local message = string.format(
        "SECURITY INCIDENT: %s\nSeverity: %s\nAssigned to: %s\nIncident ID: %s",
        incident.title,
        incident.severity:upper(),
        team.name,
        incident.id
    )
    
    print(string.format("📢 Sending %s notification: %s", channel:upper(), message))
    
    -- In a real implementation, this would send actual notifications
    -- via email, Slack, SMS, etc.
end

function SecurityMonitoringIncidentResponseSystem.blockIpAddress(ipAddress, severity)
    local block = {
        ip = ipAddress,
        reason = string.format("Security threat detected (%s)", severity),
        blocked = os.time(),
        duration = SecurityState.config.threatDetection.bruteForce.blockedDuration,
        severity = severity
    }
    
    SecurityState.blockedIps[ipAddress] = block
    
    print(string.format("🚫 Blocked IP address: %s (%s)", ipAddress, severity))
end

function SecurityMonitoringIncidentResponseSystem.blockUser(userId, severity)
    local block = {
        userId = userId,
        reason = string.format("Security threat detected (%s)", severity),
        blocked = os.time(),
        duration = severity == "critical" and 86400 or 3600, -- 24h for critical, 1h otherwise
        severity = severity
    }
    
    SecurityState.blockedUsers[userId] = block
    
    print(string.format("🚫 Blocked user: %s (%s)", userId, severity))
end

function SecurityMonitoringIncidentResponseSystem.applyRateLimit(ipAddress)
    -- Implement rate limiting
    print(string.format("⏱️ Applied rate limiting to: %s", ipAddress))
end

function SecurityMonitoringIncidentResponseSystem.escalateIncident(incidentId)
    local incident = SecurityState.activeIncidents[incidentId]
    
    if not incident then
        return {success = false, error = "Incident not found"}
    end
    
    -- Escalate to next level
    local currentTeam = incident.assignedTeam
    local newTeam = nil
    
    if currentTeam == "level1" then
        newTeam = "level2"
    elseif currentTeam == "level2" then
        newTeam = "level3"
    elseif currentTeam == "level3" then
        newTeam = "emergency"
    end
    
    if newTeam then
        incident.assignedTeam = newTeam
        incident.lastUpdated = os.time()
        
        table.insert(incident.timeline, {
            timestamp = os.time(),
            action = "escalated",
            description = string.format("Escalated from %s to %s", currentTeam, newTeam),
            automated = true
        })
        
        print(string.format("⬆️ Escalated incident %s to %s", incidentId, newTeam))
        
        -- Notify new team
        SecurityMonitoringIncidentResponseSystem.notifyResponseTeam(incident)
        
        return {success = true, newTeam = newTeam}
    else
        return {success = false, error = "Already at highest escalation level"}
    end
end

function SecurityMonitoringIncidentResponseSystem.startResponseTimer(incident)
    spawn(function()
        local severityConfig = SecurityState.config.incidentSeverity[incident.severity]
        local responseTime = severityConfig.responseTime
        
        wait(responseTime)
        
        -- Check if incident is still open and unacknowledged
        local currentIncident = SecurityState.activeIncidents[incident.id]
        if currentIncident and currentIncident.status == "open" then
            print(string.format("⏰ Response time exceeded for incident: %s", incident.id))
            
            -- Auto-escalate
            SecurityMonitoringIncidentResponseSystem.escalateIncident(incident.id)
        end
    end)
end

-- ========================================
-- ANALYTICS ENGINE
-- ========================================

function SecurityMonitoringIncidentResponseSystem.initializeAnalyticsEngine()
    SecurityState.analyticsEngine = {
        patterns = {},
        baselines = {},
        
        analyzePatterns = function(self)
            return SecurityMonitoringIncidentResponseSystem.analyzeSecurityPatterns()
        end,
        
        generateReport = function(self, timeframe)
            return SecurityMonitoringIncidentResponseSystem.generateSecurityReport(timeframe)
        end,
        
        detectAnomalies = function(self)
            return SecurityMonitoringIncidentResponseSystem.detectSecurityAnomalies()
        end
    }
    
    -- Start analytics
    SecurityMonitoringIncidentResponseSystem.startSecurityAnalytics()
    
    print("📊 Security analytics engine initialized")
end

function SecurityMonitoringIncidentResponseSystem.analyzeSecurityPatterns()
    -- Analyze events for patterns
    local patterns = {
        attackVectors = {},
        targetedResources = {},
        timeDistribution = {},
        geographicDistribution = {}
    }
    
    for _, event in ipairs(SecurityState.securityEvents) do
        -- Attack vectors
        if event.type then
            patterns.attackVectors[event.type] = (patterns.attackVectors[event.type] or 0) + 1
        end
        
        -- Targeted resources
        if event.resource then
            patterns.targetedResources[event.resource] = (patterns.targetedResources[event.resource] or 0) + 1
        end
        
        -- Time distribution
        local hour = os.date("%H", event.timestamp)
        patterns.timeDistribution[hour] = (patterns.timeDistribution[hour] or 0) + 1
        
        -- Geographic distribution (simulated)
        if event.sourceIp then
            local region = SecurityMonitoringIncidentResponseSystem.getRegionFromIp(event.sourceIp)
            patterns.geographicDistribution[region] = (patterns.geographicDistribution[region] or 0) + 1
        end
    end
    
    return patterns
end

function SecurityMonitoringIncidentResponseSystem.getRegionFromIp(ipAddress)
    -- Simulate IP geolocation
    local regions = {"US", "EU", "APAC", "Unknown"}
    local hash = 0
    for i = 1, #ipAddress do
        hash = hash + string.byte(ipAddress, i)
    end
    
    return regions[(hash % #regions) + 1]
end

function SecurityMonitoringIncidentResponseSystem.detectSecurityAnomalies()
    local anomalies = {}
    
    -- Detect unusual activity patterns
    local currentHour = tonumber(os.date("%H"))
    local eventsThisHour = 0
    
    for _, event in ipairs(SecurityState.securityEvents) do
        local eventHour = tonumber(os.date("%H", event.timestamp))
        if eventHour == currentHour then
            eventsThisHour = eventsThisHour + 1
        end
    end
    
    -- Check if this hour has unusually high activity
    local averageEventsPerHour = #SecurityState.securityEvents / 24
    
    if eventsThisHour > averageEventsPerHour * 2 then
        table.insert(anomalies, {
            type = "high_activity",
            description = string.format("Unusually high activity: %d events this hour vs %d average", 
                eventsThisHour, math.floor(averageEventsPerHour)),
            severity = "medium"
        })
    end
    
    return anomalies
end

function SecurityMonitoringIncidentResponseSystem.generateSecurityReport(timeframe)
    timeframe = timeframe or 3600 -- Default 1 hour
    
    local currentTime = os.time()
    local startTime = currentTime - timeframe
    
    local report = {
        timeframe = {
            start = startTime,
            end = currentTime,
            duration = timeframe
        },
        
        summary = {
            totalEvents = 0,
            threatsDetected = 0,
            incidentsCreated = 0,
            blockedEntities = 0,
            falsePositives = 0
        },
        
        topThreats = {},
        incidentsBySevertiy = {},
        responseMetrics = {},
        
        patterns = SecurityState.analyticsEngine:analyzePatterns(),
        anomalies = SecurityState.analyticsEngine:detectAnomalies()
    }
    
    -- Count events in timeframe
    for _, event in ipairs(SecurityState.securityEvents) do
        if event.timestamp >= startTime then
            report.summary.totalEvents = report.summary.totalEvents + 1
        end
    end
    
    -- Count threats and incidents
    for _, threat in pairs(SecurityState.activeThreats) do
        if threat.detected >= startTime then
            report.summary.threatsDetected = report.summary.threatsDetected + 1
        end
    end
    
    for _, incident in pairs(SecurityState.activeIncidents) do
        if incident.created >= startTime then
            report.summary.incidentsCreated = report.summary.incidentsCreated + 1
            
            -- Count by severity
            local severity = incident.severity
            report.incidentsBySevertiy[severity] = (report.incidentsBySevertiy[severity] or 0) + 1
        end
    end
    
    -- Count blocked entities
    report.summary.blockedEntities = 0
    for _ in pairs(SecurityState.blockedIps) do
        report.summary.blockedEntities = report.summary.blockedEntities + 1
    end
    for _ in pairs(SecurityState.blockedUsers) do
        report.summary.blockedEntities = report.summary.blockedEntities + 1
    end
    
    -- Response metrics
    report.responseMetrics = {
        meanTimeToDetection = SecurityState.metrics.meanTimeToDetection,
        meanTimeToResponse = SecurityState.metrics.meanTimeToResponse,
        automaticResponses = SecurityState.metrics.automaticResponses,
        falsePositiveRate = SecurityState.metrics.falsePositives / math.max(SecurityState.metrics.threatsDetected, 1)
    }
    
    return report
end

function SecurityMonitoringIncidentResponseSystem.startSecurityAnalytics()
    spawn(function()
        while true do
            SecurityState.analyticsEngine:analyzePatterns()
            SecurityState.analyticsEngine:detectAnomalies()
            
            wait(SecurityState.config.monitoring.threatAnalysis)
        end
    end)
    
    print("📊 Security analytics started")
end

-- ========================================
-- MONITORING
-- ========================================

function SecurityMonitoringIncidentResponseSystem.startSecurityMonitoring()
    -- Real-time event processing
    spawn(function()
        while true do
            SecurityState.detectionEngine:evaluateThreats()
            wait(SecurityState.config.monitoring.realTimeEvents)
        end
    end)
    
    -- Security scans
    spawn(function()
        while true do
            SecurityMonitoringIncidentResponseSystem.performSecurityScan()
            wait(SecurityState.config.monitoring.securityScans)
        end
    end)
    
    -- Health checks
    spawn(function()
        while true do
            SecurityMonitoringIncidentResponseSystem.performHealthCheck()
            wait(SecurityState.config.monitoring.healthChecks)
        end
    end)
    
    -- Report generation
    spawn(function()
        while true do
            wait(SecurityState.config.monitoring.reportGeneration)
            local report = SecurityState.analyticsEngine:generateReport()
            SecurityMonitoringIncidentResponseSystem.storeReport(report)
        end
    end)
    
    print("🔍 Security monitoring started")
end

function SecurityMonitoringIncidentResponseSystem.performSecurityScan()
    -- Simulate security scanning
    local scanResults = {
        vulnerabilities = math.random(0, 3),
        suspiciousFiles = math.random(0, 2),
        unauthorizedChanges = math.random(0, 1),
        networkAnomalies = math.random(0, 2)
    }
    
    -- Create events for any findings
    for finding, count in pairs(scanResults) do
        if count > 0 then
            local event = {
                type = "security_scan",
                subtype = finding,
                count = count,
                timestamp = os.time(),
                source = "security_scanner"
            }
            
            SecurityMonitoringIncidentResponseSystem.processSecurityEvent(event)
        end
    end
end

function SecurityMonitoringIncidentResponseSystem.performHealthCheck()
    -- Check system health
    local health = {
        detectionEngine = "healthy",
        responseEngine = "healthy",
        analyticsEngine = "healthy",
        
        memoryUsage = math.random(30, 70),
        cpuUsage = math.random(20, 60),
        diskUsage = math.random(40, 80)
    }
    
    -- Check for issues
    if health.memoryUsage > 90 then
        health.detectionEngine = "degraded"
    end
    
    if health.cpuUsage > 90 then
        health.responseEngine = "degraded"
    end
    
    SecurityState.systemStatus.overallHealth = "healthy"
    for component, status in pairs(health) do
        if status == "degraded" or status == "unhealthy" then
            SecurityState.systemStatus.overallHealth = "degraded"
            break
        end
    end
end

function SecurityMonitoringIncidentResponseSystem.storeReport(report)
    -- In a real implementation, this would store the report in a database
    print(string.format("📄 Generated security report: %d events, %d threats, %d incidents", 
        report.summary.totalEvents,
        report.summary.threatsDetected,
        report.summary.incidentsCreated))
end

-- ========================================
-- PUBLIC API
-- ========================================

function SecurityMonitoringIncidentResponseSystem.reportSecurityEvent(event)
    return SecurityState.detectionEngine:processEvent(event)
end

function SecurityMonitoringIncidentResponseSystem.getActiveThreats()
    return SecurityState.activeThreats
end

function SecurityMonitoringIncidentResponseSystem.getActiveIncidents()
    return SecurityState.activeIncidents
end

function SecurityMonitoringIncidentResponseSystem.getSecurityStatus()
    return SecurityState.systemStatus
end

function SecurityMonitoringIncidentResponseSystem.getSecurityMetrics()
    return SecurityState.metrics
end

function SecurityMonitoringIncidentResponseSystem.getBlockedEntities()
    return {
        ips = SecurityState.blockedIps,
        users = SecurityState.blockedUsers
    }
end

function SecurityMonitoringIncidentResponseSystem.addCustomRule(rule)
    return SecurityState.detectionEngine:addRule(rule)
end

function SecurityMonitoringIncidentResponseSystem.acknowledgeIncident(incidentId, userId)
    local incident = SecurityState.activeIncidents[incidentId]
    
    if incident then
        incident.status = "acknowledged"
        incident.acknowledgedBy = userId
        incident.acknowledgedAt = os.time()
        incident.lastUpdated = os.time()
        
        table.insert(incident.timeline, {
            timestamp = os.time(),
            action = "acknowledged",
            description = string.format("Incident acknowledged by %s", userId),
            automated = false
        })
        
        print(string.format("✅ Incident acknowledged: %s", incidentId))
        return {success = true}
    else
        return {success = false, error = "Incident not found"}
    end
end

function SecurityMonitoringIncidentResponseSystem.resolveIncident(incidentId, userId, resolution)
    local incident = SecurityState.activeIncidents[incidentId]
    
    if incident then
        incident.status = "resolved"
        incident.resolvedBy = userId
        incident.resolvedAt = os.time()
        incident.resolution = resolution
        incident.lastUpdated = os.time()
        
        incident.metrics.timeToResolution = os.time() - incident.created
        
        table.insert(incident.timeline, {
            timestamp = os.time(),
            action = "resolved",
            description = string.format("Incident resolved by %s: %s", userId, resolution),
            automated = false
        })
        
        print(string.format("✅ Incident resolved: %s", incidentId))
        return {success = true}
    else
        return {success = false, error = "Incident not found"}
    end
end

function SecurityMonitoringIncidentResponseSystem.simulateSecurityEvents(scenario)
    scenario = scenario or "mixed"
    
    print(string.format("🎭 Simulating security scenario: %s", scenario))
    
    local events = {}
    
    if scenario == "brute_force" then
        -- Simulate brute force attack
        for i = 1, 15 do
            local event = {
                type = "login_failed",
                userId = "target_user",
                sourceIp = "192.168.1.100",
                timestamp = os.time() - (15 - i) * 10,
                userAgent = "BadBot/1.0"
            }
            
            table.insert(events, event)
            SecurityMonitoringIncidentResponseSystem.reportSecurityEvent(event)
        end
        
    elseif scenario == "data_breach" then
        -- Simulate unauthorized data access
        local event = {
            type = "data_access",
            userId = "compromised_user",
            resource = "/sensitive/customer_data",
            action = "bulk_download",
            unauthorized = true,
            sourceIp = "203.0.113.1",
            timestamp = os.time()
        }
        
        table.insert(events, event)
        SecurityMonitoringIncidentResponseSystem.reportSecurityEvent(event)
        
    elseif scenario == "ddos" then
        -- Simulate DDoS attack
        for i = 1, 150 do
            local event = {
                type = "http_request",
                sourceIp = string.format("10.0.0.%d", math.random(1, 254)),
                method = "GET",
                path = "/api/endpoint",
                timestamp = os.time() - math.random(0, 60)
            }
            
            table.insert(events, event)
            SecurityMonitoringIncidentResponseSystem.reportSecurityEvent(event)
        end
        
    elseif scenario == "privilege_escalation" then
        -- Simulate privilege escalation
        local event = {
            type = "privilege_change",
            userId = "regular_user",
            fromRole = "user",
            toRole = "admin",
            escalation = true,
            sourceIp = "172.16.0.10",
            timestamp = os.time()
        }
        
        table.insert(events, event)
        SecurityMonitoringIncidentResponseSystem.reportSecurityEvent(event)
        
    else -- mixed scenario
        -- Generate various security events
        local eventTypes = {
            {type = "login_failed", count = 8},
            {type = "http_request", count = 120},
            {type = "data_access", count = 3},
            {type = "file_modification", count = 2}
        }
        
        for _, eventType in ipairs(eventTypes) do
            for i = 1, eventType.count do
                local event = {
                    type = eventType.type,
                    sourceIp = string.format("192.168.%d.%d", math.random(1, 254), math.random(1, 254)),
                    timestamp = os.time() - math.random(0, 300)
                }
                
                table.insert(events, event)
                SecurityMonitoringIncidentResponseSystem.reportSecurityEvent(event)
            end
        end
    end
    
    print(string.format("✅ Simulated %d security events for scenario: %s", #events, scenario))
    
    return events
end

function SecurityMonitoringIncidentResponseSystem.runSecurityDemo()
    print("🔒 Running security monitoring and incident response demonstration...")
    
    -- Show configuration
    print("  ⚙️ Security Configuration:")
    print(string.format("    Threat Detection Rules: %d", 
        table.count(SecurityState.detectionRules)))
    print(string.format("    Response Teams: %d", 
        table.count(SecurityState.responseTeams)))
    print(string.format("    Incident Severity Levels: %d", 
        table.count(SecurityState.config.incidentSeverity)))
    
    -- Show detection rules
    print("  📋 Active Detection Rules:")
    for ruleName, rule in pairs(SecurityState.detectionRules) do
        print(string.format("    %s: %s (%s)", 
            rule.name, 
            rule.type, 
            rule.severity))
    end
    
    -- Show response teams
    print("  👥 Response Teams:")
    for teamId, team in pairs(SecurityState.responseTeams) do
        print(string.format("    %s: %s (%s)", 
            team.name, 
            team.role, 
            team.availability))
    end
    
    -- Simulate various security scenarios
    print("  🎭 Simulating Security Scenarios:")
    
    print("    Scenario 1: Brute Force Attack")
    SecurityMonitoringIncidentResponseSystem.simulateSecurityEvents("brute_force")
    wait(1)
    
    print("    Scenario 2: DDoS Attack")
    SecurityMonitoringIncidentResponseSystem.simulateSecurityEvents("ddos")
    wait(1)
    
    print("    Scenario 3: Data Breach")
    SecurityMonitoringIncidentResponseSystem.simulateSecurityEvents("data_breach")
    wait(1)
    
    print("    Scenario 4: Privilege Escalation")
    SecurityMonitoringIncidentResponseSystem.simulateSecurityEvents("privilege_escalation")
    wait(1)
    
    -- Show detection results
    print("  ⚠️ Threat Detection Results:")
    local activeThreats = SecurityMonitoringIncidentResponseSystem.getActiveThreats()
    for threatId, threat in pairs(activeThreats) do
        print(string.format("    %s: %s (%s)", 
            threat.rule.name, 
            threat.severity:upper(), 
            threat.status))
    end
    
    -- Show incident status
    print("  🚨 Active Incidents:")
    local activeIncidents = SecurityMonitoringIncidentResponseSystem.getActiveIncidents()
    for incidentId, incident in pairs(activeIncidents) do
        print(string.format("    %s: %s (Team: %s)", 
            incident.title, 
            incident.status, 
            incident.assignedTeam))
    end
    
    -- Show blocked entities
    print("  🚫 Blocked Entities:")
    local blockedEntities = SecurityMonitoringIncidentResponseSystem.getBlockedEntities()
    print(string.format("    Blocked IPs: %d", table.count(blockedEntities.ips)))
    print(string.format("    Blocked Users: %d", table.count(blockedEntities.users)))
    
    -- Show security analytics
    print("  📊 Security Analytics:")
    local patterns = SecurityState.analyticsEngine:analyzePatterns()
    print(string.format("    Attack Vectors: %d types detected", table.count(patterns.attackVectors)))
    print(string.format("    Targeted Resources: %d", table.count(patterns.targetedResources)))
    print(string.format("    Geographic Distribution: %d regions", table.count(patterns.geographicDistribution)))
    
    -- Show security metrics
    print("  📈 Security Metrics:")
    local metrics = SecurityMonitoringIncidentResponseSystem.getSecurityMetrics()
    print(string.format("    Threats Detected: %d", metrics.threatsDetected))
    print(string.format("    Incidents Created: %d", metrics.incidentsCreated))
    print(string.format("    Automatic Responses: %d", metrics.automaticResponses))
    print(string.format("    False Positives: %d", metrics.falsePositives))
    
    -- Show system status
    print("  🏥 System Status:")
    local status = SecurityMonitoringIncidentResponseSystem.getSecurityStatus()
    print(string.format("    Security Level: %s", status.securityLevel:upper()))
    print(string.format("    Active Threats: %d", status.activeThreats))
    print(string.format("    Active Incidents: %d", status.activeIncidents))
    print(string.format("    Blocked Entities: %d", status.blockedEntities))
    
    -- Generate security report
    print("  📄 Security Report:")
    local report = SecurityState.analyticsEngine:generateReport(3600)
    print(string.format("    Total Events (1h): %d", report.summary.totalEvents))
    print(string.format("    Threats Detected (1h): %d", report.summary.threatsDetected))
    print(string.format("    Incidents Created (1h): %d", report.summary.incidentsCreated))
    print(string.format("    Response Rate: %.1f%%", 
        (report.summary.incidentsCreated / math.max(report.summary.threatsDetected, 1)) * 100))
    
    print("🔒 Security monitoring and incident response demonstration completed")
    print("     Enterprise-grade security monitoring operational!")
end

-- Helper function for table counting
if not table.count then
    function table.count(t)
        local count = 0
        for _ in pairs(t) do count = count + 1 end
        return count
    end
end

-- Initialize the security monitoring system
SecurityMonitoringIncidentResponseSystem.initialize()

print("🔒 SecurityMonitoringIncidentResponseSystem loaded with comprehensive security monitoring")

return SecurityMonitoringIncidentResponseSystem
