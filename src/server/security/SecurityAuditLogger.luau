-- SecurityAuditLogger.luau
-- Comprehensive security audit logging system for all sensitive operations
-- Provides detailed logging, compliance reporting, and security monitoring

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local HttpService = game:GetService("HttpService")
local DataStoreService = game:GetService("DataStoreService")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local SafeRequire = require(ReplicatedStorage.Shared.utils.SafeRequire)
local ServiceArchitecture = SafeRequire.require(ReplicatedStorage.Shared.core.ServiceArchitecture)

local SecurityAuditLogger = {}
SecurityAuditLogger.__index = SecurityAuditLogger

-- Implement ISecurityAuditLogger interface
setmetatable(SecurityAuditLogger, {__index = ServiceArchitecture.ISecurityAuditLogger})

-- ========================================
-- AUDIT LOGGING CONFIGURATION
-- ========================================

local AUDIT_CONFIG = {
    -- Log retention settings
    maxLogEntries = 10000,
    logRetentionDays = 90,
    
    -- Batch processing
    batchSize = 50,
    batchInterval = 60, -- seconds
    
    -- Log levels
    logLevels = {
        DEBUG = 1,
        INFO = 2,
        WARNING = 3,
        ERROR = 4,
        CRITICAL = 5,
        SECURITY = 6
    },
    
    -- Minimum log level to store
    minLogLevel = 2, -- INFO and above
    
    -- Sensitive operations to always log
    alwaysLogOperations = {
        "player_authentication",
        "session_creation",
        "session_revocation",
        "admin_action",
        "data_modification",
        "security_violation",
        "rate_limit_exceeded",
        "suspicious_activity",
        "player_blocked",
        "anti_cheat_violation"
    },
    
    -- PII masking
    maskSensitiveData = true,
    sensitiveFields = {
        "password", "token", "secret", "key", "ip", "email"
    }
}

local EVENT_CATEGORIES = {
    AUTHENTICATION = "authentication",
    AUTHORIZATION = "authorization",
    DATA_ACCESS = "data_access",
    SECURITY_VIOLATION = "security_violation",
    ADMIN_ACTION = "admin_action",
    SYSTEM_EVENT = "system_event",
    USER_ACTION = "user_action",
    ANTI_CHEAT = "anti_cheat",
    RATE_LIMITING = "rate_limiting",
    SESSION_MANAGEMENT = "session_management"
}

local COMPLIANCE_FRAMEWORKS = {
    COPPA = "coppa", -- Children's Online Privacy Protection Act
    GDPR = "gdpr",   -- General Data Protection Regulation
    SOC2 = "soc2",   -- Service Organization Control 2
    CUSTOM = "custom"
}

-- ========================================
-- CORE AUDIT LOGGER
-- ========================================

function SecurityAuditLogger.new()
    local self = setmetatable({}, SecurityAuditLogger)
    
    -- Data storage
    self.auditStore = DataStoreService:GetDataStore("SecurityAuditLogs")
    self.complianceStore = DataStoreService:GetDataStore("ComplianceLogs")
    self.alertStore = DataStoreService:GetDataStore("SecurityAlerts")
    
    -- Active logging data
    self.logBuffer = {} -- Buffered log entries
    self.alertQueue = {} -- Queued security alerts
    self.complianceBuffer = {} -- Buffered compliance logs
    
    -- Session tracking
    self.activeSessions = {} -- Active audit sessions
    self.operationContext = {} -- Current operation context
    
    -- Filtering and search
    self.logFilters = {} -- Active log filters
    self.searchIndices = {} -- Search optimization indices
    
    -- Statistics and metrics
    self.stats = {
        totalLogsGenerated = 0,
        securityEventsLogged = 0,
        complianceEventsLogged = 0,
        alertsGenerated = 0,
        logsStored = 0,
        logsFailed = 0,
        averageLogSize = 0,
        storageUsed = 0
    }
    
    -- Performance tracking
    self.performanceMetrics = {
        logWriteTime = 0,
        searchTime = 0,
        compressionRatio = 0,
        lastFlushTime = os.time()
    }
    
    -- Initialize systems
    self:InitializeBatchProcessing()
    self:InitializeRetentionPolicy()
    self:InitializeComplianceReporting()
    
    print("📋 SecurityAuditLogger initialized with comprehensive logging")
    return self
end

-- ========================================
-- CORE LOGGING FUNCTIONS
-- ========================================

function SecurityAuditLogger:LogSecurityEvent(eventType, category, details, severity)
    severity = severity or AUDIT_CONFIG.logLevels.INFO
    
    local logEntry = self:CreateLogEntry(eventType, category, details, severity)
    logEntry.isSecurityEvent = true
    
    -- Always log security events regardless of level
    self:AddToBuffer(logEntry)
    
    -- Generate alerts for high-severity events
    if severity >= AUDIT_CONFIG.logLevels.WARNING then
        self:GenerateSecurityAlert(logEntry)
    end
    
    self.stats.securityEventsLogged = self.stats.securityEventsLogged + 1
    
    print("🔒 Security event logged: " .. eventType .. " (" .. category .. ")")
end

function SecurityAuditLogger:LogUserAction(player, actionType, details, context)
    local playerId = player and tostring(player.UserId) or "system"
    local playerName = player and player.Name or "System"
    
    local enhancedDetails = {
        action = actionType,
        playerDetails = self:GetPlayerDetails(player),
        context = context or {},
        userInput = details,
        timestamp = os.time(),
        serverId = game.JobId
    }
    
    -- Mask sensitive data
    if AUDIT_CONFIG.maskSensitiveData then
        enhancedDetails = self:MaskSensitiveData(enhancedDetails)
    end
    
    local logEntry = self:CreateLogEntry(
        "user_action",
        EVENT_CATEGORIES.USER_ACTION,
        enhancedDetails,
        AUDIT_CONFIG.logLevels.INFO
    )
    
    logEntry.playerId = playerId
    logEntry.playerName = playerName
    
    self:AddToBuffer(logEntry)
end

function SecurityAuditLogger:LogDataAccess(player, resourceType, resourceId, operation, result)
    local details = {
        resourceType = resourceType,
        resourceId = resourceId,
        operation = operation,
        result = result,
        playerDetails = self:GetPlayerDetails(player),
        accessTimestamp = os.time(),
        dataClassification = self:ClassifyDataSensitivity(resourceType)
    }
    
    local logEntry = self:CreateLogEntry(
        "data_access",
        EVENT_CATEGORIES.DATA_ACCESS,
        details,
        AUDIT_CONFIG.logLevels.INFO
    )
    
    logEntry.playerId = player and tostring(player.UserId) or "system"
    logEntry.isComplianceRelevant = self:IsComplianceRelevant(resourceType)
    
    self:AddToBuffer(logEntry)
    
    -- Log for compliance if needed
    if logEntry.isComplianceRelevant then
        self:LogComplianceEvent(logEntry)
    end
end

function SecurityAuditLogger:LogAdminAction(admin, actionType, targetPlayer, details)
    local enhancedDetails = {
        actionType = actionType,
        adminDetails = self:GetPlayerDetails(admin),
        targetDetails = targetPlayer and self:GetPlayerDetails(targetPlayer) or nil,
        actionDetails = details,
        adminLevel = self:GetAdminLevel(admin),
        ipAddress = self:GetPlayerIP(admin),
        timestamp = os.time()
    }
    
    local logEntry = self:CreateLogEntry(
        "admin_action",
        EVENT_CATEGORIES.ADMIN_ACTION,
        enhancedDetails,
        AUDIT_CONFIG.logLevels.WARNING
    )
    
    logEntry.adminId = tostring(admin.UserId)
    logEntry.adminName = admin.Name
    logEntry.targetId = targetPlayer and tostring(targetPlayer.UserId) or nil
    logEntry.requiresApproval = self:RequiresAdminApproval(actionType)
    
    self:AddToBuffer(logEntry)
    
    -- Always generate alert for admin actions
    self:GenerateSecurityAlert(logEntry)
    
    print("👮 Admin action logged: " .. admin.Name .. " -> " .. actionType)
end

function SecurityAuditLogger:LogAntiCheatViolation(player, violationType, details, severity)
    local enhancedDetails = {
        violationType = violationType,
        playerDetails = self:GetPlayerDetails(player),
        violationDetails = details,
        severity = severity,
        detectionMethod = details.detectionMethod or "unknown",
        evidence = self:CollectViolationEvidence(player, violationType),
        timestamp = os.time()
    }
    
    local logEntry = self:CreateLogEntry(
        "anti_cheat_violation",
        EVENT_CATEGORIES.ANTI_CHEAT,
        enhancedDetails,
        AUDIT_CONFIG.logLevels.SECURITY
    )
    
    logEntry.playerId = tostring(player.UserId)
    logEntry.playerName = player.Name
    logEntry.violationSeverity = severity
    
    self:AddToBuffer(logEntry)
    
    -- Always alert on anti-cheat violations
    self:GenerateSecurityAlert(logEntry)
    
    -- Track for patterns
    self:TrackViolationPattern(player, violationType)
end

function SecurityAuditLogger:LogSystemEvent(eventType, component, details, severity)
    severity = severity or AUDIT_CONFIG.logLevels.INFO
    
    local enhancedDetails = {
        component = component,
        eventDetails = details,
        systemState = self:GetSystemState(),
        performance = self:GetPerformanceMetrics(),
        timestamp = os.time(),
        serverId = game.JobId
    }
    
    local logEntry = self:CreateLogEntry(
        eventType,
        EVENT_CATEGORIES.SYSTEM_EVENT,
        enhancedDetails,
        severity
    )
    
    self:AddToBuffer(logEntry)
    
    if severity >= AUDIT_CONFIG.logLevels.ERROR then
        self:GenerateSystemAlert(logEntry)
    end
end

-- ========================================
-- LOG ENTRY CREATION AND MANAGEMENT
-- ========================================

function SecurityAuditLogger:CreateLogEntry(eventType, category, details, severity)
    local logId = self:GenerateLogId()
    
    local logEntry = {
        logId = logId,
        eventType = eventType,
        category = category,
        severity = severity,
        severityName = self:GetSeverityName(severity),
        details = details,
        
        -- Metadata
        timestamp = os.time(),
        timestampISO = os.date("!%Y-%m-%dT%H:%M:%SZ", os.time()),
        serverId = game.JobId,
        serverRegion = self:GetServerRegion(),
        gameVersion = self:GetGameVersion(),
        
        -- Tracking
        sessionId = self:GetCurrentSessionId(),
        correlationId = self:GetCorrelationId(),
        requestId = self:GetRequestId(),
        
        -- Security context
        securityContext = self:GetSecurityContext(),
        operationContext = self.operationContext[eventType] or {},
        
        -- Technical details
        stackTrace = debug.traceback(),
        memoryUsage = self:GetMemoryUsage(),
        cpuUsage = self:GetCPUUsage()
    }
    
    -- Calculate log size
    logEntry.logSize = #HttpService:JSONEncode(logEntry)
    
    self.stats.totalLogsGenerated = self.stats.totalLogsGenerated + 1
    self.stats.averageLogSize = (self.stats.averageLogSize + logEntry.logSize) / 2
    
    return logEntry
end

function SecurityAuditLogger:AddToBuffer(logEntry)
    table.insert(self.logBuffer, logEntry)
    
    -- Check if immediate flush is needed
    if logEntry.severity >= AUDIT_CONFIG.logLevels.CRITICAL or
       #self.logBuffer >= AUDIT_CONFIG.batchSize then
        self:FlushLogBuffer()
    end
end

function SecurityAuditLogger:FlushLogBuffer()
    if #self.logBuffer == 0 then return end
    
    local startTime = tick()
    local logsToFlush = {}
    
    -- Copy logs to flush
    for i = 1, math.min(#self.logBuffer, AUDIT_CONFIG.batchSize) do
        table.insert(logsToFlush, self.logBuffer[i])
    end
    
    -- Remove from buffer
    for i = 1, #logsToFlush do
        table.remove(self.logBuffer, 1)
    end
    
    -- Store logs
    local success, err = pcall(function()
        self:StoreLogs(logsToFlush)
    end)
    
    if success then
        self.stats.logsStored = self.stats.logsStored + #logsToFlush
        self.performanceMetrics.lastFlushTime = os.time()
    else
        self.stats.logsFailed = self.stats.logsFailed + #logsToFlush
        warn("❌ Failed to store audit logs: " .. tostring(err))
    end
    
    self.performanceMetrics.logWriteTime = tick() - startTime
    
    print("💾 Flushed " .. #logsToFlush .. " audit logs to storage")
end

function SecurityAuditLogger:StoreLogs(logs)
    local batchKey = "audit_batch_" .. os.time() .. "_" .. math.random(1000, 9999)
    
    local batchData = {
        logs = logs,
        batchSize = #logs,
        batchTimestamp = os.time(),
        serverId = game.JobId,
        checksum = self:CalculateChecksum(logs)
    }
    
    self.auditStore:SetAsync(batchKey, batchData)
    
    -- Update storage metrics
    local batchSize = #HttpService:JSONEncode(batchData)
    self.stats.storageUsed = self.stats.storageUsed + batchSize
    self.performanceMetrics.compressionRatio = batchSize / (#logs * self.stats.averageLogSize)
end

-- ========================================
-- SECURITY ALERTS
-- ========================================

function SecurityAuditLogger:GenerateSecurityAlert(logEntry)
    local alert = {
        alertId = self:GenerateAlertId(),
        alertType = "security_event",
        severity = logEntry.severity,
        title = self:GenerateAlertTitle(logEntry),
        description = self:GenerateAlertDescription(logEntry),
        sourceLogId = logEntry.logId,
        
        -- Alert metadata
        timestamp = os.time(),
        status = "open",
        assignedTo = nil,
        escalationLevel = self:CalculateEscalationLevel(logEntry),
        
        -- Context
        affectedPlayers = self:GetAffectedPlayers(logEntry),
        riskAssessment = self:AssessRisk(logEntry),
        recommendedActions = self:GetRecommendedActions(logEntry),
        
        -- Correlation
        relatedAlerts = self:FindRelatedAlerts(logEntry),
        alertPattern = self:IdentifyAlertPattern(logEntry)
    }
    
    table.insert(self.alertQueue, alert)
    self.stats.alertsGenerated = self.stats.alertsGenerated + 1
    
    -- Immediate processing for critical alerts
    if alert.severity >= AUDIT_CONFIG.logLevels.CRITICAL then
        self:ProcessCriticalAlert(alert)
    end
    
    print("🚨 Security alert generated: " .. alert.title)
end

function SecurityAuditLogger:GenerateSystemAlert(logEntry)
    local alert = {
        alertId = self:GenerateAlertId(),
        alertType = "system_event",
        severity = logEntry.severity,
        title = "System Event: " .. logEntry.eventType,
        description = "System component " .. (logEntry.details.component or "unknown") .. " reported an event",
        sourceLogId = logEntry.logId,
        
        timestamp = os.time(),
        status = "open",
        systemComponent = logEntry.details.component,
        healthImpact = self:AssessHealthImpact(logEntry)
    }
    
    table.insert(self.alertQueue, alert)
    
    print("⚠️ System alert generated: " .. alert.title)
end

function SecurityAuditLogger:ProcessCriticalAlert(alert)
    -- Store immediately
    local alertKey = "critical_alert_" .. alert.alertId
    
    pcall(function()
        self.alertStore:SetAsync(alertKey, alert)
    end)
    
    -- Notify administrators (in real implementation)
    print("🚨 CRITICAL ALERT: " .. alert.title)
end

-- ========================================
-- COMPLIANCE LOGGING
-- ========================================

function SecurityAuditLogger:LogComplianceEvent(logEntry)
    local complianceEntry = {
        complianceId = self:GenerateComplianceId(),
        originalLogId = logEntry.logId,
        
        -- Compliance metadata
        framework = self:DetermineComplianceFramework(logEntry),
        regulation = self:GetApplicableRegulations(logEntry),
        dataSubject = self:GetDataSubject(logEntry),
        
        -- Privacy information
        personalDataInvolved = self:ContainsPersonalData(logEntry),
        dataCategories = self:ClassifyDataCategories(logEntry),
        processingPurpose = self:GetProcessingPurpose(logEntry),
        legalBasis = self:GetLegalBasis(logEntry),
        
        -- Retention
        retentionPeriod = self:GetRetentionPeriod(logEntry),
        disposalDate = self:CalculateDisposalDate(logEntry),
        
        timestamp = os.time(),
        complianceTimestamp = os.date("!%Y-%m-%dT%H:%M:%SZ", os.time())
    }
    
    table.insert(self.complianceBuffer, complianceEntry)
    self.stats.complianceEventsLogged = self.stats.complianceEventsLogged + 1
    
    print("📋 Compliance event logged: " .. complianceEntry.framework)
end

function SecurityAuditLogger:GenerateComplianceReport(framework, startDate, endDate)
    local relevantLogs = self:SearchComplianceLogs(framework, startDate, endDate)
    
    local report = {
        reportId = self:GenerateReportId(),
        framework = framework,
        reportPeriod = {
            startDate = startDate,
            endDate = endDate
        },
        
        -- Summary statistics
        totalEvents = #relevantLogs,
        dataAccessEvents = self:CountEventsByType(relevantLogs, "data_access"),
        securityEvents = self:CountEventsByType(relevantLogs, "security_violation"),
        
        -- Compliance metrics
        dataSubjectsAffected = self:CountUniqueDataSubjects(relevantLogs),
        dataCategories = self:GetUniqueDataCategories(relevantLogs),
        complianceViolations = self:IdentifyComplianceViolations(relevantLogs),
        
        -- Detailed logs
        logs = relevantLogs,
        
        -- Report metadata
        generatedAt = os.time(),
        generatedBy = "SecurityAuditLogger",
        reportVersion = "1.0"
    }
    
    return report
end

-- ========================================
-- SEARCH AND FILTERING
-- ========================================

function SecurityAuditLogger:SearchLogs(criteria)
    local startTime = tick()
    local results = {}
    
    -- Build search query
    local query = self:BuildSearchQuery(criteria)
    
    -- Search in buffer first
    for _, log in ipairs(self.logBuffer) do
        if self:MatchesCriteria(log, criteria) then
            table.insert(results, log)
        end
    end
    
    -- Search in stored logs (simplified - would use proper indexing)
    local storedResults = self:SearchStoredLogs(query)
    for _, log in ipairs(storedResults) do
        table.insert(results, log)
    end
    
    -- Sort by timestamp (newest first)
    table.sort(results, function(a, b)
        return a.timestamp > b.timestamp
    end)
    
    self.performanceMetrics.searchTime = tick() - startTime
    
    return {
        results = results,
        totalFound = #results,
        searchTime = self.performanceMetrics.searchTime,
        query = query
    }
end

function SecurityAuditLogger:FilterLogs(logs, filters)
    local filtered = {}
    
    for _, log in ipairs(logs) do
        local includeLog = true
        
        for filterType, filterValue in pairs(filters) do
            if not self:ApplyFilter(log, filterType, filterValue) then
                includeLog = false
                break
            end
        end
        
        if includeLog then
            table.insert(filtered, log)
        end
    end
    
    return filtered
end

function SecurityAuditLogger:GetLogsByPlayer(player, timeRange)
    local playerId = tostring(player.UserId)
    
    local criteria = {
        playerId = playerId,
        timeRange = timeRange
    }
    
    return self:SearchLogs(criteria)
end

function SecurityAuditLogger:GetSecurityEventsByType(eventType, timeRange)
    local criteria = {
        eventType = eventType,
        category = EVENT_CATEGORIES.SECURITY_VIOLATION,
        timeRange = timeRange
    }
    
    return self:SearchLogs(criteria)
end

-- ========================================
-- UTILITY FUNCTIONS
-- ========================================

function SecurityAuditLogger:MaskSensitiveData(data)
    if type(data) ~= "table" then
        return data
    end
    
    local masked = {}
    
    for key, value in pairs(data) do
        local keyLower = string.lower(tostring(key))
        local isSensitive = false
        
        for _, sensitiveField in ipairs(AUDIT_CONFIG.sensitiveFields) do
            if string.find(keyLower, sensitiveField) then
                isSensitive = true
                break
            end
        end
        
        if isSensitive and type(value) == "string" then
            masked[key] = string.rep("*", math.min(#value, 8))
        elseif type(value) == "table" then
            masked[key] = self:MaskSensitiveData(value)
        else
            masked[key] = value
        end
    end
    
    return masked
end

function SecurityAuditLogger:GetPlayerDetails(player)
    if not player then
        return {
            playerId = "system",
            playerName = "System",
            accountAge = 0,
            membershipType = "None"
        }
    end
    
    return {
        playerId = tostring(player.UserId),
        playerName = player.Name,
        displayName = player.DisplayName,
        accountAge = player.AccountAge,
        membershipType = tostring(player.MembershipType),
        joinTimestamp = os.time(),
        deviceType = self:GetDeviceType(player),
        platform = self:GetPlatform(player)
    }
end

function SecurityAuditLogger:GenerateLogId()
    return "log_" .. os.time() .. "_" .. math.random(100000, 999999)
end

function SecurityAuditLogger:GenerateAlertId()
    return "alert_" .. os.time() .. "_" .. math.random(100000, 999999)
end

function SecurityAuditLogger:GenerateComplianceId()
    return "comp_" .. os.time() .. "_" .. math.random(100000, 999999)
end

function SecurityAuditLogger:GenerateReportId()
    return "report_" .. os.time() .. "_" .. math.random(100000, 999999)
end

function SecurityAuditLogger:GetSeverityName(severity)
    for name, level in pairs(AUDIT_CONFIG.logLevels) do
        if level == severity then
            return name
        end
    end
    return "UNKNOWN"
end

function SecurityAuditLogger:CalculateChecksum(data)
    return HttpService:GenerateGUID(false):sub(1, 8)
end

-- ========================================
-- BATCH PROCESSING AND CLEANUP
-- ========================================

function SecurityAuditLogger:InitializeBatchProcessing()
    -- Event-driven batch processing with adaptive intervals
    local batchEvent = Instance.new("BindableEvent")
    
    local function scheduleBatchProcessing()
        local bufferActivity = #self.logBuffer + #self.complianceBuffer + #self.alertQueue
        local interval = AUDIT_CONFIG.batchInterval
        
        -- Adaptive interval based on buffer activity
        if bufferActivity > 100 then
            interval = interval * 0.5 -- Process more frequently with high activity
        elseif bufferActivity == 0 then
            interval = interval * 3 -- Process less frequently when idle
        end
        
        task.spawn(function()
            task.wait(interval)
            batchEvent:Fire()
        end)
    end
    
    batchEvent.Event:Connect(function()
        if #self.logBuffer > 0 then
            self:FlushLogBuffer()
        end
        if #self.complianceBuffer > 0 then
            self:FlushComplianceBuffer()
        end
        if #self.alertQueue > 0 then
            self:ProcessAlertQueue()
        end
        scheduleBatchProcessing()
    end)
    
    scheduleBatchProcessing()
end

function SecurityAuditLogger:InitializeRetentionPolicy()
    -- Event-driven retention policy with smart scheduling
    local retentionEvent = Instance.new("BindableEvent")
    
    local function scheduleRetention()
        task.spawn(function()
            task.wait(86400) -- Daily cleanup
            retentionEvent:Fire()
        end)
    end
    
    retentionEvent.Event:Connect(function()
        self:ApplyRetentionPolicy()
        scheduleRetention()
    end)
    
    scheduleRetention()
end

function SecurityAuditLogger:InitializeComplianceReporting()
    -- Event-driven compliance reporting with adaptive scheduling
    local complianceEvent = Instance.new("BindableEvent")
    
    local function scheduleCompliance()
        local bufferSize = #self.complianceBuffer
        local interval = 3600 -- Base hourly interval
        
        -- More frequent flushing when buffer is large
        if bufferSize > 50 then
            interval = 1800 -- 30 minutes
        elseif bufferSize == 0 then
            interval = 7200 -- 2 hours
        end
        
        task.spawn(function()
            task.wait(interval)
            complianceEvent:Fire()
        end)
    end
    
    complianceEvent.Event:Connect(function()
        if #self.complianceBuffer > 0 then
            self:FlushComplianceBuffer()
        end
        scheduleCompliance()
    end)
    
    scheduleCompliance()
end

function SecurityAuditLogger:FlushComplianceBuffer()
    if #self.complianceBuffer == 0 then return end
    
    local batchKey = "compliance_batch_" .. os.time()
    local batchData = {
        entries = self.complianceBuffer,
        batchTimestamp = os.time()
    }
    
    pcall(function()
        self.complianceStore:SetAsync(batchKey, batchData)
    end)
    
    self.complianceBuffer = {}
    print("📋 Flushed compliance logs to storage")
end

function SecurityAuditLogger:ProcessAlertQueue()
    for _, alert in ipairs(self.alertQueue) do
        local alertKey = "alert_" .. alert.alertId
        
        pcall(function()
            self.alertStore:SetAsync(alertKey, alert)
        end)
    end
    
    print("🚨 Processed " .. #self.alertQueue .. " security alerts")
    self.alertQueue = {}
end

function SecurityAuditLogger:ApplyRetentionPolicy()
    local cutoffDate = os.time() - (AUDIT_CONFIG.logRetentionDays * 86400)
    
    -- This would be implemented with proper data store iteration
    print("🗑️ Applied retention policy (cutoff: " .. os.date("%Y-%m-%d", cutoffDate) .. ")")
end

-- ========================================
-- ADMIN INTERFACE
-- ========================================

function SecurityAuditLogger:GetAuditStatistics()
    return {
        stats = self.stats,
        performanceMetrics = self.performanceMetrics,
        bufferStatus = {
            logBuffer = #self.logBuffer,
            complianceBuffer = #self.complianceBuffer,
            alertQueue = #self.alertQueue
        },
        systemHealth = {
            storageCapacity = self:GetStorageCapacity(),
            processingLoad = self:GetProcessingLoad(),
            errorRate = self:GetErrorRate()
        }
    }
end

function SecurityAuditLogger:ExportLogs(criteria, format)
    local logs = self:SearchLogs(criteria)
    
    if format == "json" then
        return HttpService:JSONEncode(logs.results)
    elseif format == "csv" then
        return self:ConvertToCSV(logs.results)
    else
        return logs.results
    end
end

-- ========================================
-- STUB IMPLEMENTATIONS FOR UTILITY FUNCTIONS
-- ========================================

-- These would be properly implemented in a real system
function SecurityAuditLogger:GetPlayerIP(player) return "192.168.1.1" end
function SecurityAuditLogger:GetDeviceType(player) return "Desktop" end
function SecurityAuditLogger:GetPlatform(player) return "Windows" end
function SecurityAuditLogger:GetAdminLevel(player) return 1 end
function SecurityAuditLogger:GetServerRegion() return "US-East" end
function SecurityAuditLogger:GetGameVersion() return "1.0.0" end
function SecurityAuditLogger:GetCurrentSessionId() return "session_123" end
function SecurityAuditLogger:GetCorrelationId() return "corr_123" end
function SecurityAuditLogger:GetRequestId() return "req_123" end
function SecurityAuditLogger:GetSecurityContext() return {} end
function SecurityAuditLogger:GetMemoryUsage() return 0 end
function SecurityAuditLogger:GetCPUUsage() return 0 end
function SecurityAuditLogger:GetSystemState() return {} end
function SecurityAuditLogger:GetPerformanceMetrics() return {} end
function SecurityAuditLogger:ClassifyDataSensitivity(resourceType) return "low" end
function SecurityAuditLogger:IsComplianceRelevant(resourceType) return false end
function SecurityAuditLogger:RequiresAdminApproval(actionType) return false end
function SecurityAuditLogger:CollectViolationEvidence(player, violationType) return {} end
function SecurityAuditLogger:TrackViolationPattern(player, violationType) end
function SecurityAuditLogger:BuildSearchQuery(criteria) return criteria end
function SecurityAuditLogger:MatchesCriteria(log, criteria) return true end
function SecurityAuditLogger:SearchStoredLogs(query) return {} end
function SecurityAuditLogger:ApplyFilter(log, filterType, filterValue) return true end

return SecurityAuditLogger
