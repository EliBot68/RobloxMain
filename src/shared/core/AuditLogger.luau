-- AuditLogger.luau
-- Comprehensive audit trail system for data changes and system events
-- Provides detailed logging, querying, and compliance features

local DataStoreService = game:GetService("DataStoreService")
local HttpService = game:GetService("HttpService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local SafeRequire = require(ReplicatedStorage.Shared.utils.SafeRequire)
local ServiceArchitecture = SafeRequire.require(ReplicatedStorage.Shared.core.ServiceArchitecture)

local AuditLogger = {}
AuditLogger.__index = AuditLogger

-- Implement IAuditLogger interface
setmetatable(AuditLogger, {__index = ServiceArchitecture.IAuditLogger})

-- ========================================
-- AUDIT CONFIGURATION
-- ========================================

local AUDIT_CONFIG = {
    enableLogging = true,
    logLevel = "INFO", -- DEBUG, INFO, WARN, ERROR, CRITICAL
    retentionPeriod = 2592000, -- 30 days in seconds
    batchSize = 50,
    flushInterval = 30, -- seconds
    maxLogSize = 10000, -- characters per log entry
    enableCompression = true,
    enableEncryption = false
}

local LOG_LEVELS = {
    DEBUG = 1,
    INFO = 2,
    WARN = 3,
    ERROR = 4,
    CRITICAL = 5
}

local AUDIT_STORES = {
    MAIN_LOG = "AuditLogV3",
    DATA_CHANGES = "DataChangeLogV3",
    SECURITY_LOG = "SecurityLogV3",
    PERFORMANCE_LOG = "PerformanceLogV3",
    ERROR_LOG = "ErrorLogV3"
}

local EVENT_TYPES = {
    -- Data events
    DATA_READ = "data_read",
    DATA_WRITE = "data_write",
    DATA_DELETE = "data_delete",
    DATA_MIGRATION = "data_migration",
    DATA_BACKUP = "data_backup",
    DATA_RESTORE = "data_restore",
    
    -- Security events
    AUTH_LOGIN = "auth_login",
    AUTH_LOGOUT = "auth_logout",
    AUTH_FAILURE = "auth_failure",
    PERMISSION_DENIED = "permission_denied",
    SUSPICIOUS_ACTIVITY = "suspicious_activity",
    
    -- System events
    SERVICE_START = "service_start",
    SERVICE_STOP = "service_stop",
    CONFIG_CHANGE = "config_change",
    ERROR_OCCURRED = "error_occurred",
    PERFORMANCE_ISSUE = "performance_issue",
    
    -- User events
    USER_ACTION = "user_action",
    TRANSACTION = "transaction",
    PURCHASE = "purchase",
    ACHIEVEMENT = "achievement"
}

-- ========================================
-- CORE AUDIT LOGGER
-- ========================================

function AuditLogger.new()
    local self = setmetatable({}, AuditLogger)
    
    -- Initialize DataStores
    self.mainLogStore = DataStoreService:GetDataStore(AUDIT_STORES.MAIN_LOG)
    self.dataChangeStore = DataStoreService:GetDataStore(AUDIT_STORES.DATA_CHANGES)
    self.securityStore = DataStoreService:GetDataStore(AUDIT_STORES.SECURITY_LOG)
    self.performanceStore = DataStoreService:GetDataStore(AUDIT_STORES.PERFORMANCE_LOG)
    self.errorStore = DataStoreService:GetDataStore(AUDIT_STORES.ERROR_LOG)
    
    -- Log buffer for batching
    self.logBuffer = {}
    self.bufferSize = 0
    
    -- Session tracking
    self.sessionId = self:GenerateSessionId()
    self.startTime = os.time()
    
    -- Statistics
    self.stats = {
        logsGenerated = 0,
        logsFlushed = 0,
        logsDropped = 0,
        bufferOverflows = 0,
        errors = 0,
        avgLogSize = 0,
        flushes = 0
    }
    
    -- Start background flushing
    self:StartAutoFlush()
    
    -- Log system startup
    self:LogEvent(EVENT_TYPES.SERVICE_START, "AuditLogger", {
        sessionId = self.sessionId,
        config = AUDIT_CONFIG
    })
    
    print("📋 AuditLogger initialized with comprehensive audit trails")
    return self
end

-- ========================================
-- CORE LOGGING FUNCTIONS
-- ========================================

function AuditLogger:LogEvent(eventType, actor, details, severity)
    if not AUDIT_CONFIG.enableLogging then
        return false
    end
    
    severity = severity or "INFO"
    
    -- Check log level
    if not self:ShouldLog(severity) then
        return false
    end
    
    local logEntry = self:CreateLogEntry(eventType, actor, details, severity)
    
    -- Add to buffer
    self:AddToBuffer(logEntry)
    
    self.stats.logsGenerated = self.stats.logsGenerated + 1
    
    return true
end

function AuditLogger:LogDataChange(playerId, operation, field, oldValue, newValue, context)
    local details = {
        playerId = playerId,
        operation = operation, -- CREATE, READ, UPDATE, DELETE
        field = field,
        oldValue = self:SanitizeValue(oldValue),
        newValue = self:SanitizeValue(newValue),
        context = context or {},
        dataVersion = context and context.version or nil,
        transactionId = context and context.transactionId or nil
    }
    
    return self:LogEvent(EVENT_TYPES.DATA_WRITE, "DataService", details, "INFO")
end

function AuditLogger:LogSecurityEvent(eventType, userId, details, severity)
    severity = severity or "WARN"
    
    local securityDetails = {
        userId = userId,
        userAgent = details.userAgent,
        ipAddress = details.ipAddress or "unknown",
        location = details.location,
        details = details,
        risk = self:CalculateRiskLevel(eventType, details),
        sessionId = self.sessionId
    }
    
    return self:LogEvent(eventType, "SecurityService", securityDetails, severity)
end

function AuditLogger:LogPerformanceEvent(operation, duration, details)
    local perfDetails = {
        operation = operation,
        duration = duration,
        details = details or {},
        threshold = details and details.threshold or nil,
        severity = self:DeterminePerfSeverity(duration, operation)
    }
    
    return self:LogEvent(EVENT_TYPES.PERFORMANCE_ISSUE, "PerformanceMonitor", perfDetails, "INFO")
end

function AuditLogger:LogError(error, context, stackTrace)
    local errorDetails = {
        error = tostring(error),
        context = context or {},
        stackTrace = stackTrace,
        errorId = self:GenerateErrorId(),
        serverId = game.JobId
    }
    
    return self:LogEvent(EVENT_TYPES.ERROR_OCCURRED, "ErrorHandler", errorDetails, "ERROR")
end

function AuditLogger:LogUserAction(userId, action, details)
    local userDetails = {
        userId = userId,
        action = action,
        details = details or {},
        timestamp = os.time(),
        sessionDuration = os.time() - self.startTime
    }
    
    return self:LogEvent(EVENT_TYPES.USER_ACTION, "UserService", userDetails, "INFO")
end

-- ========================================
-- LOG ENTRY CREATION
-- ========================================

function AuditLogger:CreateLogEntry(eventType, actor, details, severity)
    local entry = {
        id = self:GenerateLogId(),
        timestamp = os.time(),
        timestampMs = tick() * 1000,
        sessionId = self.sessionId,
        serverId = game.JobId,
        eventType = eventType,
        actor = actor,
        severity = severity,
        details = details or {},
        
        -- Environment info
        environment = {
            placeId = game.PlaceId,
            gameId = game.GameId,
            serverType = game.PrivateServerId and "Private" or "Public",
            playerCount = #game.Players:GetPlayers()
        },
        
        -- Metadata
        metadata = {
            loggerVersion = "3.0.0",
            schemaVersion = "1.0.0",
            checksum = nil -- Will be calculated
        }
    }
    
    -- Calculate checksum
    entry.metadata.checksum = self:CalculateChecksum(entry)
    
    -- Compress if needed
    if AUDIT_CONFIG.enableCompression and self:ShouldCompress(entry) then
        entry = self:CompressLogEntry(entry)
    end
    
    return entry
end

function AuditLogger:ShouldLog(severity)
    local configLevel = LOG_LEVELS[AUDIT_CONFIG.logLevel] or LOG_LEVELS.INFO
    local eventLevel = LOG_LEVELS[severity] or LOG_LEVELS.INFO
    
    return eventLevel >= configLevel
end

function AuditLogger:ShouldCompress(entry)
    local entrySize = self:CalculateLogSize(entry)
    return entrySize > 1000 -- Compress entries larger than 1KB
end

-- ========================================
-- BUFFER MANAGEMENT
-- ========================================

function AuditLogger:AddToBuffer(logEntry)
    -- Check buffer size limit
    if self.bufferSize >= AUDIT_CONFIG.batchSize then
        self:FlushBuffer()
    end
    
    table.insert(self.logBuffer, logEntry)
    self.bufferSize = self.bufferSize + 1
    
    -- Update average log size
    local logSize = self:CalculateLogSize(logEntry)
    self.stats.avgLogSize = (self.stats.avgLogSize * (self.stats.logsGenerated - 1) + logSize) / self.stats.logsGenerated
end

function AuditLogger:FlushBuffer()
    if #self.logBuffer == 0 then
        return true
    end
    
    local success = self:WriteBatchToStore(self.logBuffer)
    
    if success then
        self.stats.logsFlushed = self.stats.logsFlushed + #self.logBuffer
        self.stats.flushes = self.stats.flushes + 1
        
        print("📤 Flushed " .. #self.logBuffer .. " audit logs to storage")
    else
        self.stats.logsDropped = self.stats.logsDropped + #self.logBuffer
        warn("⚠️ Failed to flush " .. #self.logBuffer .. " audit logs")
    end
    
    -- Clear buffer
    self.logBuffer = {}
    self.bufferSize = 0
    
    return success
end

function AuditLogger:StartAutoFlush()
    task.spawn(function()
        while true do
            task.wait(AUDIT_CONFIG.flushInterval)
            if #self.logBuffer > 0 then
                self:FlushBuffer()
            end
        end
    end)
    
    print("⏰ Auto-flush started (interval: " .. AUDIT_CONFIG.flushInterval .. "s)")
end

-- ========================================
-- STORAGE OPERATIONS
-- ========================================

function AuditLogger:WriteBatchToStore(logBatch)
    local batchId = self:GenerateBatchId()
    local batchData = {
        batchId = batchId,
        timestamp = os.time(),
        count = #logBatch,
        logs = logBatch,
        checksum = self:CalculateBatchChecksum(logBatch)
    }
    
    -- Write to appropriate stores based on event types
    local success = true
    
    -- Main log store
    local mainSuccess = pcall(function()
        self.mainLogStore:SetAsync(batchId, batchData)
    end)
    
    if not mainSuccess then
        success = false
    end
    
    -- Category-specific stores
    self:WriteToSpecializedStores(logBatch, batchId)
    
    return success
end

function AuditLogger:WriteToSpecializedStores(logBatch, batchId)
    local categorizedLogs = {
        dataChanges = {},
        security = {},
        performance = {},
        errors = {}
    }
    
    -- Categorize logs
    for _, log in ipairs(logBatch) do
        if log.eventType == EVENT_TYPES.DATA_WRITE or 
           log.eventType == EVENT_TYPES.DATA_READ or
           log.eventType == EVENT_TYPES.DATA_DELETE then
            table.insert(categorizedLogs.dataChanges, log)
            
        elseif string.find(log.eventType, "auth_") or 
               log.eventType == EVENT_TYPES.PERMISSION_DENIED or
               log.eventType == EVENT_TYPES.SUSPICIOUS_ACTIVITY then
            table.insert(categorizedLogs.security, log)
            
        elseif log.eventType == EVENT_TYPES.PERFORMANCE_ISSUE then
            table.insert(categorizedLogs.performance, log)
            
        elseif log.eventType == EVENT_TYPES.ERROR_OCCURRED then
            table.insert(categorizedLogs.errors, log)
        end
    end
    
    -- Write to specialized stores
    if #categorizedLogs.dataChanges > 0 then
        pcall(function()
            self.dataChangeStore:SetAsync(batchId .. "_data", categorizedLogs.dataChanges)
        end)
    end
    
    if #categorizedLogs.security > 0 then
        pcall(function()
            self.securityStore:SetAsync(batchId .. "_security", categorizedLogs.security)
        end)
    end
    
    if #categorizedLogs.performance > 0 then
        pcall(function()
            self.performanceStore:SetAsync(batchId .. "_perf", categorizedLogs.performance)
        end)
    end
    
    if #categorizedLogs.errors > 0 then
        pcall(function()
            self.errorStore:SetAsync(batchId .. "_errors", categorizedLogs.errors)
        end)
    end
end

-- ========================================
-- LOG QUERYING
-- ========================================

function AuditLogger:QueryLogs(criteria)
    local results = {}
    
    -- This is a simplified query implementation
    -- In practice, you'd want more sophisticated indexing and querying
    
    local logStore = self:GetStoreForCriteria(criteria)
    
    -- For now, return empty results as DataStore doesn't support complex queries
    warn("⚠️ Log querying requires external indexing system - returning empty results")
    
    return {
        logs = results,
        total = #results,
        criteria = criteria,
        executedAt = os.time()
    }
end

function AuditLogger:GetLogsByTimeRange(startTime, endTime, eventType)
    -- Placeholder for time-range queries
    return self:QueryLogs({
        startTime = startTime,
        endTime = endTime,
        eventType = eventType
    })
end

function AuditLogger:GetLogsByUser(userId, limit)
    return self:QueryLogs({
        userId = userId,
        limit = limit or 100
    })
end

function AuditLogger:GetLogsByEventType(eventType, limit)
    return self:QueryLogs({
        eventType = eventType,
        limit = limit or 100
    })
end

function AuditLogger:GetSecurityLogs(severity, limit)
    return self:QueryLogs({
        category = "security",
        severity = severity,
        limit = limit or 50
    })
end

-- ========================================
-- COMPLIANCE AND REPORTING
-- ========================================

function AuditLogger:GenerateComplianceReport(startTime, endTime, reportType)
    local report = {
        reportId = self:GenerateReportId(),
        reportType = reportType or "full",
        period = {
            startTime = startTime,
            endTime = endTime,
            duration = endTime - startTime
        },
        generatedAt = os.time(),
        generatedBy = "AuditLogger",
        
        summary = {
            totalEvents = 0,
            eventsByType = {},
            eventsBySeverity = {},
            dataChanges = 0,
            securityEvents = 0,
            errors = 0
        },
        
        details = {},
        metadata = {
            version = "1.0.0",
            format = "structured"
        }
    }
    
    -- Note: In a real implementation, this would query actual logs
    -- For now, it's a template structure
    
    print("📊 Generated compliance report: " .. report.reportId)
    return report
end

function AuditLogger:ExportLogs(criteria, format)
    format = format or "json"
    
    local logs = self:QueryLogs(criteria)
    local exportData = {
        exportId = self:GenerateExportId(),
        criteria = criteria,
        format = format,
        exportedAt = os.time(),
        count = #logs.logs,
        data = logs.logs
    }
    
    -- In practice, this would save to external storage or return downloadable data
    print("📋 Exported " .. #logs.logs .. " logs in " .. format .. " format")
    
    return exportData
end

-- ========================================
-- UTILITY FUNCTIONS
-- ========================================

function AuditLogger:GenerateLogId()
    return "log_" .. os.time() .. "_" .. math.random(100000, 999999)
end

function AuditLogger:GenerateBatchId()
    return "batch_" .. os.time() .. "_" .. math.random(1000, 9999)
end

function AuditLogger:GenerateSessionId()
    return "session_" .. game.JobId .. "_" .. os.time()
end

function AuditLogger:GenerateErrorId()
    return "error_" .. os.time() .. "_" .. math.random(10000, 99999)
end

function AuditLogger:GenerateReportId()
    return "report_" .. os.time() .. "_" .. math.random(1000, 9999)
end

function AuditLogger:GenerateExportId()
    return "export_" .. os.time() .. "_" .. math.random(1000, 9999)
end

function AuditLogger:CalculateChecksum(data)
    -- Simple checksum calculation
    local jsonString = HttpService:JSONEncode(data)
    local checksum = 0
    
    for i = 1, string.len(jsonString) do
        checksum = checksum + string.byte(jsonString, i)
    end
    
    return tostring(checksum)
end

function AuditLogger:CalculateBatchChecksum(logBatch)
    local combined = ""
    for _, log in ipairs(logBatch) do
        combined = combined .. (log.metadata.checksum or "")
    end
    return self:CalculateChecksum({data = combined})
end

function AuditLogger:CalculateLogSize(logEntry)
    local jsonString = HttpService:JSONEncode(logEntry)
    return string.len(jsonString)
end

function AuditLogger:SanitizeValue(value)
    -- Remove sensitive information
    if type(value) == "string" and string.len(value) > 1000 then
        return string.sub(value, 1, 1000) .. "... (truncated)"
    end
    
    -- Remove sensitive keys
    if type(value) == "table" then
        local sanitized = {}
        for k, v in pairs(value) do
            if not self:IsSensitiveKey(k) then
                sanitized[k] = self:SanitizeValue(v)
            else
                sanitized[k] = "[REDACTED]"
            end
        end
        return sanitized
    end
    
    return value
end

function AuditLogger:IsSensitiveKey(key)
    local sensitiveKeys = {"password", "token", "secret", "key", "hash"}
    local keyLower = string.lower(tostring(key))
    
    for _, sensitive in ipairs(sensitiveKeys) do
        if string.find(keyLower, sensitive) then
            return true
        end
    end
    
    return false
end

function AuditLogger:CompressLogEntry(entry)
    -- Simple compression simulation
    return {
        compressed = true,
        originalSize = self:CalculateLogSize(entry),
        data = entry -- In practice, this would be compressed
    }
end

function AuditLogger:CalculateRiskLevel(eventType, details)
    local riskScore = 0
    
    if eventType == EVENT_TYPES.AUTH_FAILURE then
        riskScore = riskScore + 2
    elseif eventType == EVENT_TYPES.PERMISSION_DENIED then
        riskScore = riskScore + 3
    elseif eventType == EVENT_TYPES.SUSPICIOUS_ACTIVITY then
        riskScore = riskScore + 5
    end
    
    -- Additional risk factors
    if details.multipleFailures then
        riskScore = riskScore + 2
    end
    
    if details.unusualLocation then
        riskScore = riskScore + 1
    end
    
    if riskScore >= 5 then
        return "HIGH"
    elseif riskScore >= 3 then
        return "MEDIUM"
    else
        return "LOW"
    end
end

function AuditLogger:DeterminePerfSeverity(duration, operation)
    local thresholds = {
        data_read = 100,   -- 100ms
        data_write = 500,  -- 500ms
        cache_read = 10,   -- 10ms
        cache_write = 50   -- 50ms
    }
    
    local threshold = thresholds[operation] or 200
    
    if duration > threshold * 5 then
        return "CRITICAL"
    elseif duration > threshold * 2 then
        return "WARN"
    else
        return "INFO"
    end
end

function AuditLogger:GetStoreForCriteria(criteria)
    if criteria.category == "security" then
        return self.securityStore
    elseif criteria.category == "performance" then
        return self.performanceStore
    elseif criteria.category == "errors" then
        return self.errorStore
    elseif criteria.category == "data" then
        return self.dataChangeStore
    else
        return self.mainLogStore
    end
end

-- ========================================
-- STATISTICS AND MONITORING
-- ========================================

function AuditLogger:GetStatistics()
    return {
        stats = self.stats,
        config = AUDIT_CONFIG,
        sessionId = self.sessionId,
        uptime = os.time() - self.startTime,
        bufferSize = self.bufferSize,
        bufferUsage = self.bufferSize / AUDIT_CONFIG.batchSize,
        
        rates = {
            logsPerSecond = self.stats.logsGenerated / (os.time() - self.startTime),
            flushesPerHour = self.stats.flushes / ((os.time() - self.startTime) / 3600),
            errorRate = self.stats.errors / math.max(self.stats.logsGenerated, 1)
        }
    }
end

function AuditLogger:GetHealthStatus()
    local stats = self:GetStatistics()
    local health = {
        status = "healthy",
        issues = {},
        score = 100
    }
    
    -- Check buffer usage
    if stats.bufferUsage > 0.8 then
        table.insert(health.issues, "High buffer usage")
        health.score = health.score - 10
    end
    
    -- Check error rate
    if stats.rates.errorRate > 0.05 then -- 5% error rate
        table.insert(health.issues, "High error rate")
        health.score = health.score - 20
    end
    
    -- Check if logs are being flushed
    if stats.stats.flushes == 0 and stats.uptime > 60 then
        table.insert(health.issues, "No log flushes detected")
        health.score = health.score - 30
    end
    
    -- Determine overall status
    if health.score >= 80 then
        health.status = "healthy"
    elseif health.score >= 60 then
        health.status = "degraded"
    else
        health.status = "unhealthy"
    end
    
    return health
end

-- ========================================
-- CLEANUP AND MAINTENANCE
-- ========================================

function AuditLogger:Cleanup()
    -- Flush any remaining logs
    if #self.logBuffer > 0 then
        self:FlushBuffer()
    end
    
    -- Log shutdown
    self:LogEvent(EVENT_TYPES.SERVICE_STOP, "AuditLogger", {
        sessionId = self.sessionId,
        uptime = os.time() - self.startTime,
        stats = self.stats
    })
    
    print("📋 AuditLogger cleanup completed")
end

return AuditLogger
