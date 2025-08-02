-- StructuredLogger.luau
-- Enterprise-grade structured logging system with multiple outputs, log levels, and formatting
-- Provides comprehensive logging capabilities for debugging, monitoring, and troubleshooting

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local ConfigurationManager = require(ReplicatedStorage.Shared.core.ConfigurationManager)

local StructuredLogger = {}

-- Helper function to repeat strings (Luau doesn't have string.rep)
local function repeatString(str, count)
    local result = ""
    for _ = 1, count do
        result = result .. str
    end
    return result
end

-- ========================================
-- LOG LEVEL DEFINITIONS
-- ========================================

local LOG_LEVELS = {
    TRACE = {level = 0, name = "TRACE", icon = "🔍", color = "cyan", robloxMethod = "print"},
    DEBUG = {level = 1, name = "DEBUG", icon = "🐛", color = "blue", robloxMethod = "print"},
    INFO = {level = 2, name = "INFO", icon = "ℹ️", color = "green", robloxMethod = "print"},
    WARN = {level = 3, name = "WARN", icon = "⚠️", color = "yellow", robloxMethod = "warn"},
    ERROR = {level = 4, name = "ERROR", icon = "❌", color = "red", robloxMethod = "warn"},
    FATAL = {level = 5, name = "FATAL", icon = "💀", color = "magenta", robloxMethod = "error"}
}

-- ========================================
-- LOG OUTPUT DESTINATIONS
-- ========================================

local LOG_OUTPUTS = {
    CONSOLE = "console",         -- Roblox output console
    MEMORY = "memory",          -- In-memory storage
    DATASTORE = "datastore",    -- DataStore persistence
    EXTERNAL = "external",      -- External logging service
    FILE = "file"              -- File system (Studio only)
}

-- ========================================
-- LOGGER STATE AND CONFIGURATION
-- ========================================

local logBuffer = {} -- In-memory log storage
local logStats = {
    totalLogs = 0,
    logsByLevel = {},
    logsBySource = {},
    sessionStart = tick()
}

local logOutputs = {} -- Active output handlers
local logFilters = {} -- Log filtering functions
local logFormatters = {} -- Custom log formatters
local logContextProviders = {} -- Context enrichment functions

-- Configuration access
local config = ConfigurationManager.getInstance()

-- ========================================
-- CORE LOGGING FUNCTIONS
-- ========================================

-- Main logging function with full structured data
function StructuredLogger:Log(logData)
    --[[
    logData = {
        level = LOG_LEVELS.INFO,
        message = "Operation completed",
        source = "ServiceName",
        category = "business",
        details = {...},
        context = {...},
        timestamp = tick(),
        tags = {...},
        userId = 12345,
        correlationId = "uuid"
    }
    --]]
    
    -- Validate and normalize log data
    logData = self:NormalizeLogData(logData)
    
    -- Check if log should be filtered out
    if not self:ShouldLog(logData) then
        return false
    end
    
    -- Enrich log with context
    logData = self:EnrichLogWithContext(logData)
    
    -- Update statistics
    self:UpdateLogStats(logData)
    
    -- Send to all configured outputs
    self:SendToOutputs(logData)
    
    return true
end

-- Convenience methods for different log levels
function StructuredLogger:Trace(message, source, details, context)
    return self:Log({
        level = LOG_LEVELS.TRACE,
        message = message,
        source = source,
        details = details,
        context = context
    })
end

function StructuredLogger:Debug(message, source, details, context)
    return self:Log({
        level = LOG_LEVELS.DEBUG,
        message = message,
        source = source,
        details = details,
        context = context
    })
end

function StructuredLogger:Info(message, source, details, context)
    return self:Log({
        level = LOG_LEVELS.INFO,
        message = message,
        source = source,
        details = details,
        context = context
    })
end

function StructuredLogger:Warn(message, source, details, context)
    return self:Log({
        level = LOG_LEVELS.WARN,
        message = message,
        source = source,
        details = details,
        context = context
    })
end

function StructuredLogger:Error(message, source, details, context)
    return self:Log({
        level = LOG_LEVELS.ERROR,
        message = message,
        source = source,
        details = details,
        context = context
    })
end

function StructuredLogger:Fatal(message, source, details, context)
    return self:Log({
        level = LOG_LEVELS.FATAL,
        message = message,
        source = source,
        details = details,
        context = context
    })
end

-- ========================================
-- LOG DATA PROCESSING
-- ========================================

-- Normalize and validate log data
function StructuredLogger:NormalizeLogData(logData)
    local normalized = {
        level = logData.level or LOG_LEVELS.INFO,
        message = tostring(logData.message or ""),
        source = logData.source or "Unknown",
        category = logData.category or "general",
        details = logData.details or {},
        context = logData.context or {},
        timestamp = logData.timestamp or tick(),
        tags = logData.tags or {},
        userId = logData.userId,
        correlationId = logData.correlationId or HttpService:GenerateGUID(false),
        sessionId = self:GetSessionId()
    }
    
    -- Add automatic tags
    table.insert(normalized.tags, "environment:" .. config:GetEnvironment())
    if RunService:IsServer() then
        table.insert(normalized.tags, "side:server")
    else
        table.insert(normalized.tags, "side:client")
    end
    
    return normalized
end

-- Check if log should be processed based on filters
function StructuredLogger:ShouldLog(logData)
    -- Check minimum log level
    local minLevel = config:Get("logging.LEVEL.MINIMUM") or LOG_LEVELS.INFO.level
    if logData.level.level < minLevel then
        return false
    end
    
    -- Apply custom filters
    for _, filter in ipairs(logFilters) do
        local success, shouldLog = pcall(filter, logData)
        if success and not shouldLog then
            return false
        end
    end
    
    return true
end

-- Enrich log with additional context
function StructuredLogger:EnrichLogWithContext(logData)
    -- Add system context
    logData.context.gameId = game.PlaceId
    logData.context.serverId = game.JobId
    logData.context.version = game.PlaceVersion
    
    if RunService:IsServer() then
        logData.context.playerCount = #Players:GetPlayers()
        logData.context.maxPlayers = Players.MaxPlayers
    end
    
    -- Add performance context
    logData.context.memory = collectgarbage("count")
    logData.context.fps = workspace:GetRealPhysicsFPS()
    
    -- Execute custom context providers
    for _, provider in ipairs(logContextProviders) do
        local success, additionalContext = pcall(provider, logData)
        if success and additionalContext then
            for key, value in pairs(additionalContext) do
                logData.context[key] = value
            end
        end
    end
    
    return logData
end

-- Update logging statistics
function StructuredLogger:UpdateLogStats(logData)
    logStats.totalLogs = logStats.totalLogs + 1
    
    -- Count by level
    local levelName = logData.level.name
    logStats.logsByLevel[levelName] = (logStats.logsByLevel[levelName] or 0) + 1
    
    -- Count by source
    logStats.logsBySource[logData.source] = (logStats.logsBySource[logData.source] or 0) + 1
end

-- ========================================
-- LOG OUTPUT HANDLERS
-- ========================================

-- Send log to all configured outputs
function StructuredLogger:SendToOutputs(logData)
    for outputType, outputHandler in pairs(logOutputs) do
        local success, result = pcall(outputHandler, logData)
        if not success then
            -- Fallback to console if output handler fails
            print("⚠️ Log output '" .. outputType .. "' failed:", result)
        end
    end
end

-- Console output handler
function StructuredLogger:CreateConsoleOutput()
    return function(logData)
        local formattedMessage = self:FormatLogMessage(logData, "console")
        
        -- Use appropriate Roblox logging method
        if logData.level.robloxMethod == "error" and logData.level.level < LOG_LEVELS.FATAL.level then
            warn(formattedMessage) -- Use warn instead of error for ERROR level
        elseif logData.level.robloxMethod == "warn" then
            warn(formattedMessage)
        else
            print(formattedMessage)
        end
    end
end

-- Memory buffer output handler
function StructuredLogger:CreateMemoryOutput()
    return function(logData)
        table.insert(logBuffer, logData)
        
        -- Keep buffer size under control
        local maxBufferSize = config:Get("logging.MEMORY.MAX_BUFFER_SIZE") or 1000
        if #logBuffer > maxBufferSize then
            table.remove(logBuffer, 1)
        end
    end
end

-- External service output handler
function StructuredLogger:CreateExternalOutput()
    return function(logData)
        if not config:Get("logging.EXTERNAL.ENABLED") then
            return
        end
        
        local payload = {
            timestamp = os.date("!%Y-%m-%dT%H:%M:%SZ", logData.timestamp),
            level = logData.level.name,
            message = logData.message,
            source = logData.source,
            category = logData.category,
            details = logData.details,
            context = logData.context,
            tags = logData.tags,
            userId = logData.userId,
            correlationId = logData.correlationId,
            sessionId = logData.sessionId
        }
        
        -- In production, send to external logging service
        if config:Get("logging.EXTERNAL.DEBUG") then
            print("📡 External log:", HttpService:JSONEncode(payload))
        end
    end
end

-- ========================================
-- LOG FORMATTING
-- ========================================

-- Format log message for different outputs
function StructuredLogger:FormatLogMessage(logData, outputType)
    local formatter = logFormatters[outputType] or self:GetDefaultFormatter(outputType)
    return formatter(logData)
end

-- Get default formatter for output type
function StructuredLogger:GetDefaultFormatter(outputType)
    if outputType == "console" then
        return function(logData)
            local timestamp = os.date("%H:%M:%S", logData.timestamp)
            local level = logData.level
            
            local message = string.format("[%s] %s %s [%s] %s",
                timestamp,
                level.icon,
                level.name,
                logData.source,
                logData.message
            )
            
            -- Add details for higher log levels
            if logData.level.level >= LOG_LEVELS.WARN.level and next(logData.details) then
                message = message .. "\n  📋 Details: " .. self:SerializeData(logData.details)
            end
            
            -- Add context for errors
            if logData.level.level >= LOG_LEVELS.ERROR.level and next(logData.context) then
                message = message .. "\n  🔍 Context: " .. self:SerializeData(logData.context)
            end
            
            return message
        end
    elseif outputType == "json" then
        return function(logData)
            return HttpService:JSONEncode(logData)
        end
    else
        return function(logData)
            return logData.message
        end
    end
end

-- Serialize data for display
function StructuredLogger:SerializeData(data)
    local success, result = pcall(function()
        return HttpService:JSONEncode(data)
    end)
    
    if success then
        return result
    else
        return tostring(data)
    end
end

-- ========================================
-- LOG FILTERING AND CUSTOM HANDLERS
-- ========================================

-- Add custom log filter
function StructuredLogger:AddFilter(filterFunction)
    table.insert(logFilters, filterFunction)
end

-- Add custom context provider
function StructuredLogger:AddContextProvider(providerFunction)
    table.insert(logContextProviders, providerFunction)
end

-- Add custom formatter
function StructuredLogger:AddFormatter(outputType, formatterFunction)
    logFormatters[outputType] = formatterFunction
end

-- Create source-specific logger
function StructuredLogger:CreateLogger(sourceName, defaultCategory)
    return {
        Trace = function(message, details, context)
            return self:Trace(message, sourceName, details, context)
        end,
        Debug = function(message, details, context)
            return self:Debug(message, sourceName, details, context)
        end,
        Info = function(message, details, context)
            return self:Info(message, sourceName, details, context)
        end,
        Warn = function(message, details, context)
            return self:Warn(message, sourceName, details, context)
        end,
        Error = function(message, details, context)
            return self:Error(message, sourceName, details, context)
        end,
        Fatal = function(message, details, context)
            return self:Fatal(message, sourceName, details, context)
        end,
        
        -- Context-aware logging
        LogWithCategory = function(level, message, category, details, context)
            return self:Log({
                level = level,
                message = message,
                source = sourceName,
                category = category or defaultCategory,
                details = details,
                context = context
            })
        end
    }
end

-- ========================================
-- LOG QUERYING AND ANALYSIS
-- ========================================

-- Query logs with filters
function StructuredLogger:QueryLogs(queryOptions)
    --[[
    queryOptions = {
        level = LOG_LEVELS.ERROR,
        source = "ServiceName",
        category = "business",
        since = timestamp,
        until = timestamp,
        limit = 100,
        tags = {...}
    }
    --]]
    
    local results = {}
    
    for _, logData in ipairs(logBuffer) do
        if self:MatchesQuery(logData, queryOptions) then
            table.insert(results, logData)
            
            if queryOptions.limit and #results >= queryOptions.limit then
                break
            end
        end
    end
    
    return results
end

-- Check if log matches query criteria
function StructuredLogger:MatchesQuery(logData, queryOptions)
    -- Level filter
    if queryOptions.level and logData.level.level < queryOptions.level.level then
        return false
    end
    
    -- Source filter
    if queryOptions.source and logData.source ~= queryOptions.source then
        return false
    end
    
    -- Category filter
    if queryOptions.category and logData.category ~= queryOptions.category then
        return false
    end
    
    -- Time range filters
    if queryOptions.since and logData.timestamp < queryOptions.since then
        return false
    end
    
    if queryOptions["until"] and logData.timestamp > queryOptions["until"] then
        return false
    end
    
    -- Tags filter
    if queryOptions.tags then
        for _, requiredTag in ipairs(queryOptions.tags) do
            local hasTag = false
            for _, logTag in ipairs(logData.tags) do
                if logTag == requiredTag then
                    hasTag = true
                    break
                end
            end
            if not hasTag then
                return false
            end
        end
    end
    
    return true
end

-- Get log statistics
function StructuredLogger:GetLogStats()
    return {
        total = logStats.totalLogs,
        byLevel = logStats.logsByLevel,
        bySource = logStats.logsBySource,
        bufferSize = #logBuffer,
        sessionUptime = tick() - logStats.sessionStart
    }
end

-- ========================================
-- LOG EXPORT AND PERSISTENCE
-- ========================================

-- Export logs in various formats
function StructuredLogger:ExportLogs(format, queryOptions)
    local logs = self:QueryLogs(queryOptions or {})
    
    if format == "json" then
        return HttpService:JSONEncode(logs)
    elseif format == "csv" then
        return self:ExportToCsv(logs)
    elseif format == "text" then
        return self:ExportToText(logs)
    else
        error("Unsupported export format: " .. tostring(format))
    end
end

-- Export logs to CSV format
function StructuredLogger:ExportToCsv(logs)
    local csv = "timestamp,level,source,category,message,details\n"
    
    for _, logData in ipairs(logs) do
        local row = string.format('"%s","%s","%s","%s","%s","%s"\n',
            os.date("%Y-%m-%d %H:%M:%S", logData.timestamp),
            logData.level.name,
            logData.source,
            logData.category,
            logData.message:gsub('"', '""'), -- Escape quotes
            self:SerializeData(logData.details):gsub('"', '""')
        )
        csv = csv .. row
    end
    
    return csv
end

-- Export logs to text format
function StructuredLogger:ExportToText(logs)
    local text = ""
    
    for _, logData in ipairs(logs) do
        text = text .. self:FormatLogMessage(logData, "console") .. "\n"
    end
    
    return text
end

-- ========================================
-- SESSION MANAGEMENT
-- ========================================

-- Get current session ID
function StructuredLogger:GetSessionId()
    if not self.sessionId then
        self.sessionId = HttpService:GenerateGUID(false)
    end
    return self.sessionId
end

-- Start new logging session
function StructuredLogger:StartNewSession()
    self.sessionId = HttpService:GenerateGUID(false)
    logStats.sessionStart = tick()
    
    self:Info("New logging session started", "StructuredLogger", {
        sessionId = self.sessionId,
        environment = config:GetEnvironment()
    })
end

-- ========================================
-- PERFORMANCE MONITORING
-- ========================================

-- Monitor logging performance
function StructuredLogger:MonitorPerformance()
    local RunService = game:GetService("RunService")
    local lastMonitorTime = 0
    local monitorInterval = config:Get("logging.PERFORMANCE.MONITOR_INTERVAL") or 300 -- 5 minutes
    
    self.performanceConnection = RunService.Heartbeat:Connect(function()
        local currentTime = tick()
        if currentTime - lastMonitorTime >= monitorInterval then
            lastMonitorTime = currentTime
            
            local stats = self:GetLogStats()
            local logsPerSecond = stats.total / stats.sessionUptime
            
            self:Debug("Logging performance metrics", "StructuredLogger", {
                totalLogs = stats.total,
                logsPerSecond = logsPerSecond,
                bufferSize = stats.bufferSize,
                sessionUptime = stats.sessionUptime
            })
            
            -- Alert if logging rate is too high
            local maxLogsPerSecond = config:Get("logging.PERFORMANCE.MAX_LOGS_PER_SECOND") or 10
            if logsPerSecond > maxLogsPerSecond then
                self:Warn("High logging rate detected", "StructuredLogger", {
                    currentRate = logsPerSecond,
                    maxRate = maxLogsPerSecond
                })
            end
        end
    end)
end

-- ========================================
-- DEBUGGING UTILITIES
-- ========================================

-- Print current log buffer contents
function StructuredLogger:DumpLogBuffer(level)
    level = level or LOG_LEVELS.DEBUG
    
    print("\n" .. repeatString("=", 60))
    print("📊 LOG BUFFER DUMP")
    print(repeatString("=", 60))
    
    local count = 0
    for _, logData in ipairs(logBuffer) do
        if logData.level.level >= level.level then
            print(self:FormatLogMessage(logData, "console"))
            count = count + 1
        end
    end
    
    print(repeatString("=", 60))
    print("Total logs shown: " .. count .. " (level >= " .. level.name .. ")")
    print(repeatString("=", 60) .. "\n")
end

-- Get recent logs for debugging
function StructuredLogger:GetRecentLogs(count, level)
    count = count or 50
    level = level or LOG_LEVELS.DEBUG
    
    local recent = {}
    local logCount = 0
    
    for i = #logBuffer, 1, -1 do
        local logData = logBuffer[i]
        if logData.level.level >= level.level then
            table.insert(recent, 1, logData) -- Insert at beginning
            logCount = logCount + 1
            
            if logCount >= count then
                break
            end
        end
    end
    
    return recent
end

-- ========================================
-- INITIALIZATION
-- ========================================

function StructuredLogger:Init()
    print("📝 StructuredLogger initializing...")
    
    -- Initialize log level counters
    for _, level in pairs(LOG_LEVELS) do
        logStats.logsByLevel[level.name] = 0
    end
    
    -- Setup default outputs
    local enabledOutputs = config:Get("logging.OUTPUTS.ENABLED") or {LOG_OUTPUTS.CONSOLE, LOG_OUTPUTS.MEMORY}
    
    for _, outputType in ipairs(enabledOutputs) do
        if outputType == LOG_OUTPUTS.CONSOLE then
            logOutputs[LOG_OUTPUTS.CONSOLE] = self:CreateConsoleOutput()
        elseif outputType == LOG_OUTPUTS.MEMORY then
            logOutputs[LOG_OUTPUTS.MEMORY] = self:CreateMemoryOutput()
        elseif outputType == LOG_OUTPUTS.EXTERNAL then
            logOutputs[LOG_OUTPUTS.EXTERNAL] = self:CreateExternalOutput()
        end
    end
    
    -- Start new session
    self:StartNewSession()
    
    -- Start performance monitoring
    if config:Get("logging.PERFORMANCE.ENABLE_MONITORING") then
        self:MonitorPerformance()
    end
    
    -- Add default context providers
    self:AddContextProvider(function(logData)
        return {
            runtime = "Roblox",
            luauVersion = _VERSION or "Unknown"
        }
    end)
    
    print("✅ StructuredLogger initialized successfully")
    return true
end

return StructuredLogger
