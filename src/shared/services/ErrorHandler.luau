-- ErrorHandler.luau
-- Centralized error handling service with proper classification, recovery strategies, and structured logging
-- Provides enterprise-grade error management with graceful failure handling and comprehensive reporting

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local HttpService = game:GetService("HttpService")
local LogService = game:GetService("LogService")
local ConfigurationManager = require(ReplicatedStorage.Shared.core.ConfigurationManager)

local ErrorHandler = {}

-- ========================================
-- ERROR CLASSIFICATION SYSTEM
-- ========================================

-- Error severity levels
local ERROR_LEVELS = {
    DEBUG = {level = 0, name = "DEBUG", icon = "🐛", color = "cyan"},
    INFO = {level = 1, name = "INFO", icon = "ℹ️", color = "white"},
    WARN = {level = 2, name = "WARN", icon = "⚠️", color = "yellow"},
    ERROR = {level = 3, name = "ERROR", icon = "❌", color = "red"},
    FATAL = {level = 4, name = "FATAL", icon = "💀", color = "magenta"}
}

-- Error categories for classification
local ERROR_CATEGORIES = {
    NETWORK = "network",
    MEMORY = "memory", 
    LOGIC = "logic",
    DATA = "data",
    PERFORMANCE = "performance",
    SECURITY = "security",
    UI = "ui",
    SYSTEM = "system",
    UNKNOWN = "unknown"
}

-- Error recovery strategies
local RECOVERY_STRATEGIES = {
    NONE = "none",          -- No recovery, let it fail
    RETRY = "retry",        -- Retry the operation
    FALLBACK = "fallback",  -- Use fallback value/method
    GRACEFUL = "graceful",  -- Graceful degradation
    RESTART = "restart",    -- Restart the service/component
    IGNORE = "ignore"       -- Log and continue
}

-- ========================================
-- ERROR TRACKING AND STORAGE
-- ========================================

local errorRegistry = {}
local errorStats = {
    totalErrors = 0,
    errorsByLevel = {},
    errorsByCategory = {},
    errorsBySource = {},
    recentErrors = {},
    criticalErrors = {}
}

local errorHandlers = {} -- Custom error handlers by category
local recoveryStrategies = {} -- Recovery strategies by error type
local errorCallbacks = {} -- Callbacks for error notifications

-- Configuration
local config = ConfigurationManager.getInstance()

-- ========================================
-- CORE ERROR HANDLING
-- ========================================

-- Main error handling function with classification and recovery
function ErrorHandler:HandleError(errorData)
    --[[
    errorData = {
        level = ERROR_LEVELS.ERROR,
        category = ERROR_CATEGORIES.NETWORK,
        message = "Connection failed",
        source = "NetworkService",
        details = {...},
        stackTrace = debug.traceback(),
        recoveryStrategy = RECOVERY_STRATEGIES.RETRY,
        context = {...}
    }
    --]]
    
    -- Ensure required fields
    errorData.level = errorData.level or ERROR_LEVELS.ERROR
    errorData.category = errorData.category or ERROR_CATEGORIES.UNKNOWN
    errorData.timestamp = tick()
    errorData.id = HttpService:GenerateGUID(false)
    
    -- Get stack trace if not provided
    if not errorData.stackTrace then
        errorData.stackTrace = debug.traceback()
    end
    
    -- Classify error automatically if not specified
    if errorData.category == ERROR_CATEGORIES.UNKNOWN then
        errorData.category = self:ClassifyError(errorData)
    end
    
    -- Register error in tracking system
    self:RegisterError(errorData)
    
    -- Execute logging
    self:LogError(errorData)
    
    -- Attempt recovery if strategy is specified
    local recoveryResult = nil
    if errorData.recoveryStrategy and errorData.recoveryStrategy ~= RECOVERY_STRATEGIES.NONE then
        recoveryResult = self:AttemptRecovery(errorData)
    end
    
    -- Execute custom error handlers
    self:ExecuteErrorHandlers(errorData)
    
    -- Send alerts for critical errors
    if errorData.level.level >= ERROR_LEVELS.ERROR.level then
        self:SendErrorAlert(errorData)
    end
    
    return {
        errorId = errorData.id,
        handled = true,
        recoveryAttempted = recoveryResult ~= nil,
        recoverySuccessful = recoveryResult and recoveryResult.success or false,
        timestamp = errorData.timestamp
    }
end

-- Convenience methods for different error levels
function ErrorHandler:Debug(message, source, details)
    return self:HandleError({
        level = ERROR_LEVELS.DEBUG,
        message = message,
        source = source or "Unknown",
        details = details
    })
end

function ErrorHandler:Info(message, source, details)
    return self:HandleError({
        level = ERROR_LEVELS.INFO,
        message = message,
        source = source or "Unknown",
        details = details
    })
end

function ErrorHandler:Warn(message, source, details)
    return self:HandleError({
        level = ERROR_LEVELS.WARN,
        message = message,
        source = source or "Unknown",
        details = details,
        recoveryStrategy = RECOVERY_STRATEGIES.GRACEFUL
    })
end

function ErrorHandler:Error(message, source, details, category)
    return self:HandleError({
        level = ERROR_LEVELS.ERROR,
        message = message,
        source = source or "Unknown",
        details = details,
        category = category or ERROR_CATEGORIES.LOGIC,
        recoveryStrategy = RECOVERY_STRATEGIES.RETRY
    })
end

function ErrorHandler:Fatal(message, source, details, category)
    return self:HandleError({
        level = ERROR_LEVELS.FATAL,
        message = message,
        source = source or "Unknown",
        details = details,
        category = category or ERROR_CATEGORIES.SYSTEM,
        recoveryStrategy = RECOVERY_STRATEGIES.RESTART
    })
end

-- ========================================
-- ERROR CLASSIFICATION
-- ========================================

-- Automatically classify errors based on message content and context
function ErrorHandler:ClassifyError(errorData)
    local message = errorData.message:lower()
    local source = (errorData.source or ""):lower()
    
    -- Network-related errors
    if message:find("network") or message:find("connection") or message:find("timeout") or
       message:find("http") or message:find("request") or source:find("network") then
        return ERROR_CATEGORIES.NETWORK
    end
    
    -- Memory-related errors
    if message:find("memory") or message:find("leak") or message:find("out of memory") or
       source:find("memory") then
        return ERROR_CATEGORIES.MEMORY
    end
    
    -- Data-related errors
    if message:find("data") or message:find("datastore") or message:find("save") or
       message:find("load") or source:find("data") then
        return ERROR_CATEGORIES.DATA
    end
    
    -- Performance-related errors
    if message:find("performance") or message:find("slow") or message:find("lag") or
       message:find("fps") or source:find("performance") then
        return ERROR_CATEGORIES.PERFORMANCE
    end
    
    -- Security-related errors
    if message:find("security") or message:find("unauthorized") or message:find("permission") or
       message:find("exploit") or source:find("security") or source:find("anticheat") then
        return ERROR_CATEGORIES.SECURITY
    end
    
    -- UI-related errors
    if message:find("ui") or message:find("gui") or message:find("interface") or
       source:find("ui") or source:find("gui") then
        return ERROR_CATEGORIES.UI
    end
    
    -- System-related errors
    if message:find("system") or message:find("service") or message:find("initialization") or
       source:find("service") or source:find("system") then
        return ERROR_CATEGORIES.SYSTEM
    end
    
    return ERROR_CATEGORIES.LOGIC -- Default to logic error
end

-- ========================================
-- ERROR RECOVERY SYSTEM
-- ========================================

-- Attempt to recover from an error using the specified strategy
function ErrorHandler:AttemptRecovery(errorData)
    local strategy = errorData.recoveryStrategy
    local recoveryResult = {
        strategy = strategy,
        attempts = 0,
        success = false,
        details = {}
    }
    
    if strategy == RECOVERY_STRATEGIES.RETRY then
        recoveryResult = self:RetryOperation(errorData)
    elseif strategy == RECOVERY_STRATEGIES.FALLBACK then
        recoveryResult = self:UseFallback(errorData)
    elseif strategy == RECOVERY_STRATEGIES.GRACEFUL then
        recoveryResult = self:GracefulDegradation(errorData)
    elseif strategy == RECOVERY_STRATEGIES.RESTART then
        recoveryResult = self:RestartComponent(errorData)
    elseif strategy == RECOVERY_STRATEGIES.IGNORE then
        recoveryResult.success = true
        recoveryResult.details.message = "Error ignored per strategy"
    end
    
    -- Log recovery attempt
    self:LogRecoveryAttempt(errorData, recoveryResult)
    
    return recoveryResult
end

-- Retry operation with exponential backoff
function ErrorHandler:RetryOperation(errorData)
    local maxRetries = config:Get("errorHandling.RECOVERY.MAX_RETRIES") or 3
    local baseDelay = config:Get("errorHandling.RECOVERY.BASE_RETRY_DELAY") or 1.0
    
    local recoveryResult = {
        strategy = RECOVERY_STRATEGIES.RETRY,
        attempts = 0,
        success = false,
        details = {}
    }
    
    for attempt = 1, maxRetries do
        recoveryResult.attempts = attempt
        
        -- Wait with exponential backoff
        if attempt > 1 then
            local delay = baseDelay * (2 ^ (attempt - 2))
            task.wait(delay)
        end
        
        -- Attempt to retry the operation if retry function is provided
        if errorData.retryFunction then
            local success, result = pcall(errorData.retryFunction)
            if success then
                recoveryResult.success = true
                recoveryResult.details.result = result
                recoveryResult.details.successfulAttempt = attempt
                break
            else
                recoveryResult.details["attempt_" .. attempt] = result
            end
        else
            -- No retry function provided, mark as failed
            recoveryResult.details.error = "No retry function provided"
            break
        end
    end
    
    return recoveryResult
end

-- Use fallback value or method
function ErrorHandler:UseFallback(errorData)
    local recoveryResult = {
        strategy = RECOVERY_STRATEGIES.FALLBACK,
        attempts = 1,
        success = false,
        details = {}
    }
    
    if errorData.fallbackFunction then
        local success, result = pcall(errorData.fallbackFunction)
        if success then
            recoveryResult.success = true
            recoveryResult.details.fallbackResult = result
        else
            recoveryResult.details.fallbackError = result
        end
    elseif errorData.fallbackValue ~= nil then
        recoveryResult.success = true
        recoveryResult.details.fallbackValue = errorData.fallbackValue
    else
        recoveryResult.details.error = "No fallback function or value provided"
    end
    
    return recoveryResult
end

-- Implement graceful degradation
function ErrorHandler:GracefulDegradation(errorData)
    local recoveryResult = {
        strategy = RECOVERY_STRATEGIES.GRACEFUL,
        attempts = 1,
        success = true, -- Graceful degradation is always "successful"
        details = {
            message = "System continuing with reduced functionality"
        }
    }
    
    -- Execute graceful degradation function if provided
    if errorData.gracefulFunction then
        local success, result = pcall(errorData.gracefulFunction)
        if success then
            recoveryResult.details.gracefulResult = result
        else
            recoveryResult.details.gracefulError = result
            recoveryResult.success = false
        end
    end
    
    return recoveryResult
end

-- Restart component or service
function ErrorHandler:RestartComponent(errorData)
    local recoveryResult = {
        strategy = RECOVERY_STRATEGIES.RESTART,
        attempts = 1,
        success = false,
        details = {}
    }
    
    if errorData.restartFunction then
        local success, result = pcall(errorData.restartFunction)
        if success then
            recoveryResult.success = true
            recoveryResult.details.restartResult = result
        else
            recoveryResult.details.restartError = result
        end
    else
        recoveryResult.details.error = "No restart function provided"
    end
    
    return recoveryResult
end

-- ========================================
-- ERROR BOUNDARIES
-- ========================================

-- Create error boundary around critical operations
function ErrorHandler:CreateErrorBoundary(boundaryName, operation, errorConfig)
    --[[
    errorConfig = {
        category = ERROR_CATEGORIES.SYSTEM,
        recoveryStrategy = RECOVERY_STRATEGIES.FALLBACK,
        fallbackValue = nil,
        retryFunction = function() ... end,
        onError = function(errorData) ... end
    }
    --]]
    
    errorConfig = errorConfig or {}
    
    return function(...)
        local args = {...}
        local success, result = pcall(function()
            return operation(unpack(args))
        end)
        
        if success then
            return result
        else
            -- Error occurred, handle it
            local errorData = {
                level = ERROR_LEVELS.ERROR,
                category = errorConfig.category or ERROR_CATEGORIES.LOGIC,
                message = "Error in boundary '" .. boundaryName .. "': " .. tostring(result),
                source = boundaryName,
                details = {
                    originalError = result,
                    arguments = args
                },
                recoveryStrategy = errorConfig.recoveryStrategy,
                fallbackValue = errorConfig.fallbackValue,
                retryFunction = errorConfig.retryFunction and function()
                    return operation(unpack(args))
                end,
                gracefulFunction = errorConfig.gracefulFunction,
                restartFunction = errorConfig.restartFunction
            }
            
            local handleResult = self:HandleError(errorData)
            
            -- Execute custom error callback
            if errorConfig.onError then
                pcall(errorConfig.onError, errorData, handleResult)
            end
            
            -- Return fallback value or nil
            return errorConfig.fallbackValue
        end
    end
end

-- Wrap service methods with error boundaries
function ErrorHandler:WrapServiceWithErrorBoundaries(service, serviceName)
    local wrappedService = {}
    
    for methodName, method in pairs(service) do
        if type(method) == "function" then
            wrappedService[methodName] = self:CreateErrorBoundary(
                serviceName .. "." .. methodName,
                method,
                {
                    category = ERROR_CATEGORIES.SYSTEM,
                    recoveryStrategy = RECOVERY_STRATEGIES.GRACEFUL,
                    onError = function(errorData)
                        self:Warn("Service method error in " .. serviceName .. "." .. methodName, 
                                serviceName, errorData.details)
                    end
                }
            )
        else
            wrappedService[methodName] = method
        end
    end
    
    return wrappedService
end

-- ========================================
-- STANDARDIZED PCALL REPLACEMENT
-- ========================================

-- Safe call with automatic error handling
function ErrorHandler:SafeCall(operation, errorConfig, ...)
    errorConfig = errorConfig or {}
    local args = {...}
    
    local success, result = pcall(function()
        return operation(unpack(args))
    end)
    
    if success then
        return {
            success = true,
            result = result,
            error = nil
        }
    else
        -- Handle the error
        local errorData = {
            level = errorConfig.level or ERROR_LEVELS.ERROR,
            category = errorConfig.category or ERROR_CATEGORIES.LOGIC,
            message = errorConfig.message or ("Safe call failed: " .. tostring(result)),
            source = errorConfig.source or "SafeCall",
            details = {
                originalError = result,
                arguments = args
            },
            recoveryStrategy = errorConfig.recoveryStrategy,
            fallbackValue = errorConfig.fallbackValue,
            retryFunction = errorConfig.retryFunction and function()
                return operation(unpack(args))
            end
        }
        
        local handleResult = self:HandleError(errorData)
        
        return {
            success = false,
            result = errorConfig.fallbackValue,
            error = errorData,
            handleResult = handleResult
        }
    end
end

-- Async safe call with Promise-like interface
function ErrorHandler:SafeCallAsync(operation, errorConfig, ...)
    local args = {...}
    
    return task.spawn(function()
        return self:SafeCall(operation, errorConfig, unpack(args))
    end)
end

-- ========================================
-- ERROR REGISTRATION AND TRACKING
-- ========================================

-- Register error in tracking system
function ErrorHandler:RegisterError(errorData)
    -- Add to registry
    errorRegistry[errorData.id] = errorData
    
    -- Update statistics
    errorStats.totalErrors = errorStats.totalErrors + 1
    
    -- Track by level
    local levelName = errorData.level.name
    errorStats.errorsByLevel[levelName] = (errorStats.errorsByLevel[levelName] or 0) + 1
    
    -- Track by category
    errorStats.errorsByCategory[errorData.category] = (errorStats.errorsByCategory[errorData.category] or 0) + 1
    
    -- Track by source
    errorStats.errorsBySource[errorData.source] = (errorStats.errorsBySource[errorData.source] or 0) + 1
    
    -- Add to recent errors (keep last 100)
    table.insert(errorStats.recentErrors, errorData)
    if #errorStats.recentErrors > 100 then
        table.remove(errorStats.recentErrors, 1)
    end
    
    -- Track critical errors separately
    if errorData.level.level >= ERROR_LEVELS.ERROR.level then
        table.insert(errorStats.criticalErrors, errorData)
        if #errorStats.criticalErrors > 50 then
            table.remove(errorStats.criticalErrors, 1)
        end
    end
end

-- ========================================
-- STRUCTURED LOGGING
-- ========================================

-- Log error with structured format
function ErrorHandler:LogError(errorData)
    local logLevel = config:Get("errorHandling.LOGGING.LEVEL") or ERROR_LEVELS.INFO.level
    
    -- Only log if error level meets minimum logging level
    if errorData.level.level < logLevel then
        return
    end
    
    local logMessage = self:FormatLogMessage(errorData)
    
    -- Use appropriate Roblox logging method
    if errorData.level.level >= ERROR_LEVELS.FATAL.level then
        error(logMessage, 0) -- This will be caught by our error boundary
    elseif errorData.level.level >= ERROR_LEVELS.ERROR.level then
        warn(logMessage)
    else
        print(logMessage)
    end
    
    -- Log to custom log storage if enabled
    if config:Get("errorHandling.LOGGING.ENABLE_CUSTOM_STORAGE") then
        self:WriteToCustomLog(errorData, logMessage)
    end
    
    -- Send to external logging service if configured
    if config:Get("errorHandling.LOGGING.ENABLE_EXTERNAL_LOGGING") then
        self:SendToExternalLogger(errorData)
    end
end

-- Format log message with structured information
function ErrorHandler:FormatLogMessage(errorData)
    local timestamp = os.date("%Y-%m-%d %H:%M:%S", errorData.timestamp)
    local level = errorData.level
    
    local message = string.format("[%s] %s %s [%s] [%s] %s",
        timestamp,
        level.icon,
        level.name,
        errorData.category:upper(),
        errorData.source,
        errorData.message
    )
    
    -- Add details if present
    if errorData.details then
        message = message .. "\n  Details: " .. HttpService:JSONEncode(errorData.details)
    end
    
    -- Add stack trace for errors and above
    if errorData.level.level >= ERROR_LEVELS.ERROR.level and errorData.stackTrace then
        message = message .. "\n  Stack Trace:\n" .. errorData.stackTrace
    end
    
    return message
end

-- Write to custom log storage
function ErrorHandler:WriteToCustomLog(errorData, logMessage)
    -- This would write to a custom log file or storage system
    -- For now, we'll store in memory (in production, use DataStore or external service)
    
    if not self.customLogs then
        self.customLogs = {}
    end
    
    table.insert(self.customLogs, {
        timestamp = errorData.timestamp,
        level = errorData.level.name,
        category = errorData.category,
        source = errorData.source,
        message = errorData.message,
        details = errorData.details,
        formattedMessage = logMessage
    })
    
    -- Keep only recent logs
    if #self.customLogs > 1000 then
        table.remove(self.customLogs, 1)
    end
end

-- Send to external logging service
function ErrorHandler:SendToExternalLogger(errorData)
    -- This would send to external services like LogDNA, Splunk, etc.
    -- For now, we'll simulate with HTTP request
    
    local payload = {
        timestamp = errorData.timestamp,
        level = errorData.level.name,
        category = errorData.category,
        source = errorData.source,
        message = errorData.message,
        details = errorData.details,
        gameId = game.PlaceId,
        serverId = game.JobId
    }
    
    -- In production, you would send this to your logging service
    if config:Get("errorHandling.LOGGING.DEBUG_EXTERNAL") then
        print("📡 Would send to external logger:", HttpService:JSONEncode(payload))
    end
end

-- ========================================
-- LOGGING RECOVERY ATTEMPTS
-- ========================================

-- Log recovery attempt results
function ErrorHandler:LogRecoveryAttempt(errorData, recoveryResult)
    local message = string.format("Recovery attempt for error %s using strategy %s: %s",
        errorData.id,
        recoveryResult.strategy,
        recoveryResult.success and "SUCCESS" or "FAILED"
    )
    
    self:Info(message, "ErrorHandler", {
        originalErrorId = errorData.id,
        recoveryStrategy = recoveryResult.strategy,
        attempts = recoveryResult.attempts,
        success = recoveryResult.success,
        details = recoveryResult.details
    })
end

-- ========================================
-- ERROR HANDLERS AND CALLBACKS
-- ========================================

-- Register custom error handler for specific category
function ErrorHandler:RegisterErrorHandler(category, handler)
    if not errorHandlers[category] then
        errorHandlers[category] = {}
    end
    
    table.insert(errorHandlers[category], handler)
    
    self:Debug("Registered error handler for category: " .. category, "ErrorHandler")
end

-- Execute custom error handlers
function ErrorHandler:ExecuteErrorHandlers(errorData)
    local handlers = errorHandlers[errorData.category] or {}
    
    for _, handler in ipairs(handlers) do
        local success, result = pcall(handler, errorData)
        if not success then
            self:Warn("Error handler failed: " .. tostring(result), "ErrorHandler", {
                category = errorData.category,
                originalError = errorData.id
            })
        end
    end
end

-- ========================================
-- ERROR ALERTING
-- ========================================

-- Send error alert for critical errors
function ErrorHandler:SendErrorAlert(errorData)
    if not config:Get("errorHandling.ALERTING.ENABLED") then
        return
    end
    
    local alertThreshold = config:Get("errorHandling.ALERTING.MINIMUM_LEVEL") or ERROR_LEVELS.ERROR.level
    
    if errorData.level.level >= alertThreshold then
        self:ProcessErrorAlert(errorData)
    end
end

-- Process error alert (send to monitoring systems, Discord, etc.)
function ErrorHandler:ProcessErrorAlert(errorData)
    local alertMessage = string.format("🚨 CRITICAL ERROR ALERT 🚨\n" ..
        "Level: %s\n" ..
        "Category: %s\n" ..
        "Source: %s\n" ..
        "Message: %s\n" ..
        "Time: %s\n" ..
        "Game: %s (Place ID: %d)\n" ..
        "Server: %s",
        errorData.level.name,
        errorData.category:upper(),
        errorData.source,
        errorData.message,
        os.date("%Y-%m-%d %H:%M:%S", errorData.timestamp),
        game.Name,
        game.PlaceId,
        game.JobId
    )
    
    -- In production, send to monitoring systems
    if config:Get("errorHandling.ALERTING.DEBUG") then
        print(alertMessage)
    end
    
    -- Execute alert callbacks
    for _, callback in ipairs(errorCallbacks) do
        pcall(callback, errorData, alertMessage)
    end
end

-- Register alert callback
function ErrorHandler:RegisterAlertCallback(callback)
    table.insert(errorCallbacks, callback)
end

-- ========================================
-- ERROR STATISTICS AND REPORTING
-- ========================================

-- Get error statistics
function ErrorHandler:GetErrorStats()
    return {
        total = errorStats.totalErrors,
        byLevel = errorStats.errorsByLevel,
        byCategory = errorStats.errorsByCategory,
        bySource = errorStats.errorsBySource,
        recentCount = #errorStats.recentErrors,
        criticalCount = #errorStats.criticalErrors,
        uptime = tick() - (self.startTime or tick())
    }
end

-- Get recent errors
function ErrorHandler:GetRecentErrors(count)
    count = count or 10
    local recent = {}
    
    for i = math.max(1, #errorStats.recentErrors - count + 1), #errorStats.recentErrors do
        table.insert(recent, errorStats.recentErrors[i])
    end
    
    return recent
end

-- Print error report
function ErrorHandler:PrintErrorReport()
    local stats = self:GetErrorStats()
    
    print("\n" .. "=".rep(60))
    print("📊 ERROR HANDLER REPORT")
    print("⏰ Generated: " .. os.date("%Y-%m-%d %H:%M:%S"))
    print("=".rep(60))
    
    print("📈 STATISTICS:")
    print("   Total Errors: " .. stats.total)
    print("   Critical Errors: " .. stats.criticalCount)
    print("   System Uptime: " .. string.format("%.2f", stats.uptime) .. "s")
    
    print("\n🏷️ BY LEVEL:")
    for level, count in pairs(stats.byLevel) do
        print("   " .. level .. ": " .. count)
    end
    
    print("\n📂 BY CATEGORY:")
    for category, count in pairs(stats.byCategory) do
        print("   " .. category:upper() .. ": " .. count)
    end
    
    print("\n🔧 BY SOURCE:")
    for source, count in pairs(stats.bySource) do
        print("   " .. source .. ": " .. count)
    end
    
    print("=".rep(60) .. "\n")
end

-- ========================================
-- INITIALIZATION
-- ========================================

function ErrorHandler:Init()
    self.startTime = tick()
    
    print("🛡️ ErrorHandler initializing...")
    
    -- Initialize error level counts
    for _, level in pairs(ERROR_LEVELS) do
        errorStats.errorsByLevel[level.name] = 0
    end
    
    -- Initialize category counts
    for _, category in pairs(ERROR_CATEGORIES) do
        errorStats.errorsByCategory[category] = 0
    end
    
    -- Set up global error handling
    self:SetupGlobalErrorHandling()
    
    -- Start error monitoring
    if config:Get("errorHandling.MONITORING.ENABLED") then
        self:StartErrorMonitoring()
    end
    
    print("✅ ErrorHandler initialized successfully")
    return true
end

-- Setup global error handling for uncaught errors
function ErrorHandler:SetupGlobalErrorHandling()
    -- Handle LogService errors
    LogService.MessageOut:Connect(function(message, messageType)
        if messageType == Enum.MessageType.MessageError then
            self:HandleError({
                level = ERROR_LEVELS.ERROR,
                category = ERROR_CATEGORIES.SYSTEM,
                message = "LogService Error: " .. message,
                source = "LogService",
                details = {
                    messageType = messageType.Name,
                    originalMessage = message
                }
            })
        end
    end)
end

-- Start error monitoring loop
function ErrorHandler:StartErrorMonitoring()
    task.spawn(function()
        while true do
            task.wait(config:Get("errorHandling.MONITORING.INTERVAL") or 60)
            
            -- Check for error rate spikes
            self:CheckErrorRateSpikes()
            
            -- Clean up old errors
            self:CleanupOldErrors()
            
            -- Generate periodic reports
            if config:Get("errorHandling.MONITORING.ENABLE_PERIODIC_REPORTS") then
                self:PrintErrorReport()
            end
        end
    end)
end

-- Check for error rate spikes
function ErrorHandler:CheckErrorRateSpikes()
    local recentTime = tick() - 300 -- Last 5 minutes
    local recentErrorCount = 0
    
    for _, errorData in ipairs(errorStats.recentErrors) do
        if errorData.timestamp > recentTime then
            recentErrorCount = recentErrorCount + 1
        end
    end
    
    local errorRate = recentErrorCount / 300 -- Errors per second
    local threshold = config:Get("errorHandling.MONITORING.ERROR_RATE_THRESHOLD") or 0.1
    
    if errorRate > threshold then
        self:Fatal("Error rate spike detected", "ErrorHandler", {
            errorRate = errorRate,
            threshold = threshold,
            recentErrorCount = recentErrorCount
        })
    end
end

-- Clean up old errors from memory
function ErrorHandler:CleanupOldErrors()
    local cutoffTime = tick() - (config:Get("errorHandling.STORAGE.MAX_AGE_SECONDS") or 3600)
    
    -- Clean up error registry
    for errorId, errorData in pairs(errorRegistry) do
        if errorData.timestamp < cutoffTime then
            errorRegistry[errorId] = nil
        end
    end
    
    -- Clean up custom logs
    if self.customLogs then
        local filteredLogs = {}
        for _, log in ipairs(self.customLogs) do
            if log.timestamp >= cutoffTime then
                table.insert(filteredLogs, log)
            end
        end
        self.customLogs = filteredLogs
    end
end

return ErrorHandler
