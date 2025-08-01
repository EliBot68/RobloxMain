-- CriticalErrorHandler.luau
-- Comprehensive error handling system with error boundaries, graceful degradation, 
-- user-friendly error messages, automatic error reporting, and recovery mechanisms
-- Designed to keep the game playable even when individual systems fail

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local HttpService = game:GetService("HttpService")
local LogService = game:GetService("LogService")
local _UserInputService = game:GetService("UserInputService")
local _StarterPlayer = game:GetService("StarterPlayer")

local ModernServiceFramework = require(ReplicatedStorage.Shared.core.ModernServiceFramework)

local CriticalErrorHandler = {}
setmetatable(CriticalErrorHandler, {__index = ModernServiceFramework.ServiceBase})

-- ========================================
-- ERROR CLASSIFICATION SYSTEM
-- ========================================

local ERROR_SEVERITY = {
    TRACE = {level = 0, name = "TRACE", icon = "🔍", color = Color3.fromRGB(128, 128, 128), userVisible = false},
    DEBUG = {level = 1, name = "DEBUG", icon = "🐛", color = Color3.fromRGB(0, 255, 255), userVisible = false},
    INFO = {level = 2, name = "INFO", icon = "ℹ️", color = Color3.fromRGB(255, 255, 255), userVisible = false},
    WARN = {level = 3, name = "WARN", icon = "⚠️", color = Color3.fromRGB(255, 255, 0), userVisible = false},
    ERROR = {level = 4, name = "ERROR", icon = "❌", color = Color3.fromRGB(255, 100, 100), userVisible = true},
    CRITICAL = {level = 5, name = "CRITICAL", icon = "🚨", color = Color3.fromRGB(255, 0, 0), userVisible = true},
    FATAL = {level = 6, name = "FATAL", icon = "💀", color = Color3.fromRGB(128, 0, 128), userVisible = true}
}

local ERROR_CATEGORIES = {
    GAME_LOGIC = "game_logic",
    NETWORK = "network", 
    MEMORY = "memory",
    PERFORMANCE = "performance",
    UI = "ui",
    DATA = "data",
    SECURITY = "security",
    SERVICE = "service",
    SYSTEM = "system",
    USER_INPUT = "user_input",
    PHYSICS = "physics",
    AUDIO = "audio",
    UNKNOWN = "unknown"
}

local RECOVERY_STRATEGIES = {
    NONE = "none",              -- No recovery, let it fail
    RETRY = "retry",            -- Retry with exponential backoff
    FALLBACK = "fallback",      -- Use fallback value/method
    GRACEFUL = "graceful",      -- Graceful degradation 
    RESTART = "restart",        -- Restart component/service
    ISOLATE = "isolate",        -- Isolate failing component
    IGNORE = "ignore",          -- Log and continue
    USER_NOTIFY = "user_notify" -- Notify user and let them decide
}

-- User-friendly error messages
local USER_FRIENDLY_MESSAGES = {
    [ERROR_CATEGORIES.NETWORK] = {
        [ERROR_SEVERITY.ERROR.name] = "Connection issue detected. Trying to reconnect...",
        [ERROR_SEVERITY.CRITICAL.name] = "Lost connection to game servers. Please check your internet connection.",
        [ERROR_SEVERITY.FATAL.name] = "Unable to connect to game servers. Please restart the game."
    },
    [ERROR_CATEGORIES.GAME_LOGIC] = {
        [ERROR_SEVERITY.ERROR.name] = "A gameplay issue occurred. The game will continue normally.",
        [ERROR_SEVERITY.CRITICAL.name] = "A critical gameplay error occurred. Some features may be temporarily unavailable.",
        [ERROR_SEVERITY.FATAL.name] = "A serious error occurred. Please rejoin the game."
    },
    [ERROR_CATEGORIES.MEMORY] = {
        [ERROR_SEVERITY.ERROR.name] = "Optimizing game performance...",
        [ERROR_SEVERITY.CRITICAL.name] = "Low memory detected. Reducing graphics quality to improve performance.",
        [ERROR_SEVERITY.FATAL.name] = "Critical memory issue. Please restart the game to continue playing."
    },
    [ERROR_CATEGORIES.PERFORMANCE] = {
        [ERROR_SEVERITY.ERROR.name] = "Performance optimization in progress...",
        [ERROR_SEVERITY.CRITICAL.name] = "Performance issues detected. Adjusting settings for better gameplay.",
        [ERROR_SEVERITY.FATAL.name] = "Severe performance issues. Please restart the game."
    },
    [ERROR_CATEGORIES.UI] = {
        [ERROR_SEVERITY.ERROR.name] = "Interface issue detected. Refreshing interface...",
        [ERROR_SEVERITY.CRITICAL.name] = "Interface error occurred. Some menus may be temporarily unavailable.",
        [ERROR_SEVERITY.FATAL.name] = "Critical interface error. Please restart the game."
    },
    [ERROR_CATEGORIES.DATA] = {
        [ERROR_SEVERITY.ERROR.name] = "Data sync issue. Your progress is safe and will be restored shortly.",
        [ERROR_SEVERITY.CRITICAL.name] = "Unable to save progress. Playing in offline mode until connection is restored.",
        [ERROR_SEVERITY.FATAL.name] = "Critical data error. Please restart to ensure your progress is saved."
    }
}

-- ========================================
-- SERVICE INITIALIZATION
-- ========================================

function CriticalErrorHandler.new(config)
    local self = ModernServiceFramework.CreateService("CriticalErrorHandler", config or {
        Priority = 1, -- Highest priority - needs to start first
        Dependencies = {},
        OptionalDependencies = {}
    })
    setmetatable(self, {__index = CriticalErrorHandler})
    
    -- Error tracking
    self.errorRegistry = {}
    self.errorStats = {
        totalErrors = 0,
        errorsBySeverity = {},
        errorsByCategory = {},
        errorsBySource = {},
        recentErrors = {},
        criticalErrors = {},
        errorRate = 0,
        lastErrorTime = 0
    }
    
    -- Recovery state tracking
    self.recoveryAttempts = {}
    self.isolatedComponents = {}
    self.gracefullyDegraded = {}
    
    -- Error boundaries
    self.errorBoundaries = {}
    self.globalErrorHandlers = {}
    
    -- User notification system
    self.userNotifications = {}
    self.notificationQueue = {}
    
    -- Performance monitoring
    self.performanceMetrics = {
        frameRate = 60,
        memoryUsage = 0,
        networkLatency = 0,
        errorImpact = 0
    }
    
    -- Configuration
    self.config = {
        maxErrorsPerMinute = 50,
        maxRecoveryAttempts = 3,
        userNotificationDelay = 2.0,
        autoRecoveryEnabled = true,
        performanceMonitoringEnabled = true,
        externalReportingEnabled = false,
        debugMode = false
    }
    
    return self
end

-- ========================================
-- SERVICE LIFECYCLE
-- ========================================

function CriticalErrorHandler:Initialize()
    if self.IsInitialized then
        return
    end
    
    print("🛡️ Initializing Critical Error Handler...")
    
    -- Initialize error stats tracking
    for _, severity in pairs(ERROR_SEVERITY) do
        self.errorStats.errorsBySeverity[severity.name] = 0
    end
    
    for _, category in pairs(ERROR_CATEGORIES) do
        self.errorStats.errorsByCategory[category] = 0
    end
    
    -- Set up global error handling
    self:SetupGlobalErrorHandling()
    
    -- Set up user notification system
    self:SetupUserNotificationSystem()
    
    -- Set up performance monitoring
    if self.config.performanceMonitoringEnabled then
        self:SetupPerformanceMonitoring()
    end
    
    self.IsInitialized = true
    print("✅ Critical Error Handler initialized")
end

function CriticalErrorHandler:Start()
    if self.IsRunning then
        return
    end
    
    self:Initialize()
    
    -- Start error monitoring loop
    self:AddConnection("errorMonitoring", 
        self:SetupHeartbeat(function()
            self:MonitorErrorRates()
            self:ProcessNotificationQueue()
            self:UpdatePerformanceMetrics()
        end, 0, 1), -- Every second
        "Heartbeat"
    )
    
    -- Start recovery monitoring
    self:AddConnection("recoveryMonitoring",
        self:SetupHeartbeat(function()
            self:MonitorRecoveryAttempts()
            self:CheckIsolatedComponents()
        end, 0, 5), -- Every 5 seconds
        "Heartbeat"
    )
    
    self.IsRunning = true
    print("▶️ Critical Error Handler started")
end

-- ========================================
-- CORE ERROR HANDLING
-- ========================================

function CriticalErrorHandler:HandleError(errorData)
    --[[
    errorData = {
        severity = ERROR_SEVERITY.ERROR,
        category = ERROR_CATEGORIES.GAME_LOGIC,
        message = "Error message",
        source = "ServiceName",
        details = {...},
        stackTrace = debug.traceback(),
        recoveryStrategy = RECOVERY_STRATEGIES.RETRY,
        context = {...},
        userFriendlyMessage = "Custom user message",
        component = "ComponentName",
        retryFunction = function() ... end,
        fallbackFunction = function() ... end,
        fallbackValue = nil,
        gracefulFunction = function() ... end,
        restartFunction = function() ... end
    }
    --]]
    
    -- Ensure required fields
    errorData.severity = errorData.severity or ERROR_SEVERITY.ERROR
    errorData.category = errorData.category or ERROR_CATEGORIES.UNKNOWN
    errorData.source = errorData.source or "Unknown"
    errorData.timestamp = tick()
    errorData.id = HttpService:GenerateGUID(false)
    
    -- Get stack trace if not provided
    if not errorData.stackTrace then
        errorData.stackTrace = debug.traceback()
    end
    
    -- Auto-classify if category is unknown
    if errorData.category == ERROR_CATEGORIES.UNKNOWN then
        errorData.category = self:ClassifyError(errorData)
    end
    
    -- Auto-determine recovery strategy if not specified
    if not errorData.recoveryStrategy then
        errorData.recoveryStrategy = self:DetermineRecoveryStrategy(errorData)
    end
    
    -- Register error in tracking system
    self:RegisterError(errorData)
    
    -- Log error with structured logging
    self:LogStructuredError(errorData)
    
    -- Attempt recovery if strategy is specified
    local recoveryResult = nil
    if errorData.recoveryStrategy and errorData.recoveryStrategy ~= RECOVERY_STRATEGIES.NONE then
        recoveryResult = self:AttemptRecovery(errorData)
    end
    
    -- Execute custom error handlers
    self:ExecuteErrorHandlers(errorData)
    
    -- Handle user notifications
    if errorData.severity.userVisible then
        self:HandleUserNotification(errorData)
    end
    
    -- Send to external reporting if enabled
    if self.config.externalReportingEnabled then
        self:SendExternalReport(errorData)
    end
    
    -- Check for cascading failures
    self:CheckForCascadingFailures(errorData)
    
    return {
        errorId = errorData.id,
        handled = true,
        recoveryAttempted = recoveryResult ~= nil,
        recoverySuccessful = recoveryResult and recoveryResult.success or false,
        userNotified = errorData.severity.userVisible,
        timestamp = errorData.timestamp
    }
end

-- ========================================
-- ERROR CLASSIFICATION
-- ========================================

function CriticalErrorHandler:ClassifyError(errorData)
    local message = (errorData.message or ""):lower()
    local source = (errorData.source or ""):lower()
    
    -- Network-related errors
    if message:find("network") or message:find("connection") or message:find("timeout") or 
       message:find("http") or message:find("request") or source:find("network") or
       source:find("remote") then
        return ERROR_CATEGORIES.NETWORK
    end
    
    -- Memory-related errors
    if message:find("memory") or message:find("leak") or message:find("out of memory") or
       source:find("memory") then
        return ERROR_CATEGORIES.MEMORY
    end
    
    -- Performance-related errors
    if message:find("performance") or message:find("slow") or message:find("lag") or
       message:find("fps") or message:find("freeze") or source:find("performance") then
        return ERROR_CATEGORIES.PERFORMANCE
    end
    
    -- UI-related errors
    if message:find("ui") or message:find("gui") or message:find("interface") or
       message:find("button") or message:find("menu") or source:find("ui") or 
       source:find("gui") then
        return ERROR_CATEGORIES.UI
    end
    
    -- Data-related errors
    if message:find("data") or message:find("datastore") or message:find("save") or
       message:find("load") or message:find("profile") or source:find("data") then
        return ERROR_CATEGORIES.DATA
    end
    
    -- Service-related errors
    if message:find("service") or message:find("initialization") or 
       source:find("service") then
        return ERROR_CATEGORIES.SERVICE
    end
    
    -- Physics-related errors
    if message:find("physics") or message:find("collision") or message:find("raycast") or
       source:find("physics") then
        return ERROR_CATEGORIES.PHYSICS
    end
    
    -- Audio-related errors
    if message:find("audio") or message:find("sound") or message:find("music") or
       source:find("audio") or source:find("sound") then
        return ERROR_CATEGORIES.AUDIO
    end
    
    -- User input-related errors
    if message:find("input") or message:find("touch") or message:find("keyboard") or
       message:find("mouse") or source:find("input") then
        return ERROR_CATEGORIES.USER_INPUT
    end
    
    -- Security-related errors
    if message:find("security") or message:find("unauthorized") or message:find("permission") or
       message:find("exploit") or source:find("security") or source:find("anticheat") then
        return ERROR_CATEGORIES.SECURITY
    end
    
    return ERROR_CATEGORIES.GAME_LOGIC -- Default to game logic error
end

function CriticalErrorHandler:DetermineRecoveryStrategy(errorData)
    local category = errorData.category
    local severity = errorData.severity
    
    -- Fatal errors should restart components
    if severity.level >= ERROR_SEVERITY.FATAL.level then
        return RECOVERY_STRATEGIES.RESTART
    end
    
    -- Critical errors need graceful degradation or user notification
    if severity.level >= ERROR_SEVERITY.CRITICAL.level then
        if category == ERROR_CATEGORIES.NETWORK or category == ERROR_CATEGORIES.DATA then
            return RECOVERY_STRATEGIES.USER_NOTIFY
        else
            return RECOVERY_STRATEGIES.GRACEFUL
        end
    end
    
    -- Regular errors can be retried or use fallbacks
    if category == ERROR_CATEGORIES.NETWORK then
        return RECOVERY_STRATEGIES.RETRY
    elseif category == ERROR_CATEGORIES.UI or category == ERROR_CATEGORIES.GAME_LOGIC then
        return RECOVERY_STRATEGIES.FALLBACK
    elseif category == ERROR_CATEGORIES.PERFORMANCE or category == ERROR_CATEGORIES.MEMORY then
        return RECOVERY_STRATEGIES.GRACEFUL
    else
        return RECOVERY_STRATEGIES.RETRY
    end
end

-- ========================================
-- ERROR RECOVERY SYSTEM
-- ========================================

function CriticalErrorHandler:AttemptRecovery(errorData)
    local strategy = errorData.recoveryStrategy
    local componentId = errorData.component or errorData.source
    
    -- Check if we've exceeded max recovery attempts for this component
    local attempts = self.recoveryAttempts[componentId] or 0
    if attempts >= self.config.maxRecoveryAttempts then
        self:IsolateComponent(componentId, errorData)
        return {
            strategy = RECOVERY_STRATEGIES.ISOLATE,
            success = false,
            attempts = attempts,
            details = {message = "Max recovery attempts exceeded, component isolated"}
        }
    end
    
    -- Track recovery attempt
    self.recoveryAttempts[componentId] = attempts + 1
    
    local recoveryResult = {
        strategy = strategy,
        attempts = self.recoveryAttempts[componentId],
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
    elseif strategy == RECOVERY_STRATEGIES.ISOLATE then
        recoveryResult = self:IsolateComponent(componentId, errorData)
    elseif strategy == RECOVERY_STRATEGIES.USER_NOTIFY then
        recoveryResult = self:NotifyUserForDecision(errorData)
    elseif strategy == RECOVERY_STRATEGIES.IGNORE then
        recoveryResult.success = true
        recoveryResult.details.message = "Error ignored per strategy"
    end
    
    -- Reset recovery attempts on successful recovery
    if recoveryResult.success then
        self.recoveryAttempts[componentId] = 0
        
        -- Remove from isolation if it was isolated
        if self.isolatedComponents[componentId] then
            self:ReintegrateComponent(componentId)
        end
    end
    
    -- Log recovery attempt
    self:LogRecoveryAttempt(errorData, recoveryResult)
    
    return recoveryResult
end

function CriticalErrorHandler:RetryOperation(errorData)
    local maxRetries = 3
    local baseDelay = 1.0
    
    local recoveryResult = {
        strategy = RECOVERY_STRATEGIES.RETRY,
        attempts = 0,
        success = false,
        details = {}
    }
    
    if errorData.retryFunction then
        for attempt = 1, maxRetries do
            recoveryResult.attempts = attempt
            
            -- Wait with exponential backoff
            if attempt > 1 then
                local delay = baseDelay * (2 ^ (attempt - 2))
                task.wait(delay)
            end
            
            local success, result = pcall(errorData.retryFunction)
            if success then
                recoveryResult.success = true
                recoveryResult.details.result = result
                recoveryResult.details.successfulAttempt = attempt
                break
            else
                recoveryResult.details["attempt_" .. attempt] = result
            end
        end
    else
        recoveryResult.details.error = "No retry function provided"
    end
    
    return recoveryResult
end

function CriticalErrorHandler:UseFallback(errorData)
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

function CriticalErrorHandler:GracefulDegradation(errorData)
    local recoveryResult = {
        strategy = RECOVERY_STRATEGIES.GRACEFUL,
        attempts = 1,
        success = true, -- Graceful degradation is always "successful"
        details = {
            message = "System continuing with reduced functionality"
        }
    }
    
    local componentId = errorData.component or errorData.source
    self.gracefullyDegraded[componentId] = {
        timestamp = tick(),
        reason = errorData.message,
        category = errorData.category
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

function CriticalErrorHandler:RestartComponent(errorData)
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
            
            -- Clear any isolation or degradation status
            local componentId = errorData.component or errorData.source
            self.isolatedComponents[componentId] = nil
            self.gracefullyDegraded[componentId] = nil
        else
            recoveryResult.details.restartError = result
        end
    else
        recoveryResult.details.error = "No restart function provided"
    end
    
    return recoveryResult
end

function CriticalErrorHandler:IsolateComponent(componentId, errorData)
    local recoveryResult = {
        strategy = RECOVERY_STRATEGIES.ISOLATE,
        attempts = 1,
        success = true, -- Isolation is always successful
        details = {
            message = "Component isolated to prevent cascade failures",
            component = componentId
        }
    }
    
    self.isolatedComponents[componentId] = {
        timestamp = tick(),
        reason = errorData.message,
        category = errorData.category,
        errorData = errorData
    }
    
    -- Notify other systems about the isolation
    self:NotifyComponentIsolation(componentId, errorData)
    
    return recoveryResult
end

function CriticalErrorHandler:NotifyUserForDecision(errorData)
    local recoveryResult = {
        strategy = RECOVERY_STRATEGIES.USER_NOTIFY,
        attempts = 1,
        success = true,
        details = {
            message = "User notified about error"
        }
    }
    
    -- Queue user notification
    local notification = {
        type = "error_decision",
        severity = errorData.severity,
        category = errorData.category,
        message = self:GetUserFriendlyMessage(errorData),
        options = {"Retry", "Continue", "Restart"},
        callback = function(choice)
            if choice == "Retry" and errorData.retryFunction then
                self:RetryOperation(errorData)
            elseif choice == "Restart" and errorData.restartFunction then
                self:RestartComponent(errorData)
            -- "Continue" just proceeds with degraded functionality
            end
        end
    }
    
    self:QueueUserNotification(notification)
    
    return recoveryResult
end

-- ========================================
-- ERROR BOUNDARIES
-- ========================================

function CriticalErrorHandler:CreateErrorBoundary(boundaryName, operation, errorConfig)
    --[[
    errorConfig = {
        category = ERROR_CATEGORIES.GAME_LOGIC,
        severity = ERROR_SEVERITY.ERROR,
        recoveryStrategy = RECOVERY_STRATEGIES.FALLBACK,
        fallbackValue = nil,
        retryFunction = function() ... end,
        gracefulFunction = function() ... end,
        onError = function(errorData) ... end,
        component = "ComponentName"
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
            -- Error occurred, handle it with error boundary
            local errorData = {
                severity = errorConfig.severity or ERROR_SEVERITY.ERROR,
                category = errorConfig.category or ERROR_CATEGORIES.GAME_LOGIC,
                message = "Error in boundary '" .. boundaryName .. "': " .. tostring(result),
                source = boundaryName,
                component = errorConfig.component or boundaryName,
                details = {
                    originalError = result,
                    arguments = args,
                    boundaryName = boundaryName
                },
                stackTrace = debug.traceback(),
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

function CriticalErrorHandler:WrapServiceWithErrorBoundaries(service, serviceName)
    local wrappedService = {}
    
    for methodName, method in pairs(service) do
        if type(method) == "function" and methodName ~= "new" then
            wrappedService[methodName] = self:CreateErrorBoundary(
                serviceName .. "." .. methodName,
                method,
                {
                    category = ERROR_CATEGORIES.SERVICE,
                    severity = ERROR_SEVERITY.ERROR,
                    recoveryStrategy = RECOVERY_STRATEGIES.GRACEFUL,
                    component = serviceName,
                    onError = function(errorData)
                        self:LogStructuredError({
                            severity = ERROR_SEVERITY.WARN,
                            category = ERROR_CATEGORIES.SERVICE,
                            message = "Service method error in " .. serviceName .. "." .. methodName,
                            source = serviceName,
                            details = errorData.details
                        })
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
-- GLOBAL ERROR HANDLING SETUP
-- ========================================

function CriticalErrorHandler:SetupGlobalErrorHandling()
    -- Wrap common global functions with error boundaries
    local originalSpawn = spawn;
    spawn = function(func)
        return originalSpawn(function()
            self:CreateErrorBoundary("spawned_function", func, {
                category = ERROR_CATEGORIES.SYSTEM,
                severity = ERROR_SEVERITY.ERROR,
                recoveryStrategy = RECOVERY_STRATEGIES.IGNORE
            })()
        end)
    end
    
    local originalTask = task.spawn
    task.spawn = function(func, ...)
        local args = {...}
        return originalTask(function()
            self:CreateErrorBoundary("task_function", func, {
                category = ERROR_CATEGORIES.SYSTEM,
                severity = ERROR_SEVERITY.ERROR,
                recoveryStrategy = RECOVERY_STRATEGIES.IGNORE
            })(unpack(args))
        end)
    end
    
    -- Handle script errors if on client
    if RunService:IsClient() then
        game:GetService("ScriptContext").ErrorDetailed:Connect(function(message, stack, script)
            self:HandleError({
                severity = ERROR_SEVERITY.ERROR,
                category = ERROR_CATEGORIES.SYSTEM,
                message = message,
                source = script and script.Name or "unknown_script",
                stackTrace = stack,
                details = {
                    scriptName = script and script.Name or "unknown",
                    scriptParent = script and script.Parent and script.Parent.Name or "unknown"
                },
                recoveryStrategy = RECOVERY_STRATEGIES.GRACEFUL
            })
        end)
    end
    
    -- Handle LogService errors
    LogService.MessageOut:Connect(function(message, messageType)
        if messageType == Enum.MessageType.MessageError then
            self:HandleError({
                severity = ERROR_SEVERITY.ERROR,
                category = ERROR_CATEGORIES.SYSTEM,
                message = "LogService Error: " .. message,
                source = "LogService",
                details = {
                    messageType = messageType.Name,
                    originalMessage = message
                },
                recoveryStrategy = RECOVERY_STRATEGIES.IGNORE
            })
        end
    end)
    
    print("🔗 Global error handling setup complete")
end

-- ========================================
-- USER NOTIFICATION SYSTEM
-- ========================================

function CriticalErrorHandler:SetupUserNotificationSystem()
    -- Only set up on client
    if not RunService:IsClient() then
        return
    end
    
    -- Create user notification GUI
    local player = Players.LocalPlayer
    local playerGui = player:WaitForChild("PlayerGui")
    
    -- Create notification container
    local notificationGui = Instance.new("ScreenGui")
    notificationGui.Name = "ErrorNotificationSystem"
    notificationGui.ResetOnSpawn = false
    notificationGui.Parent = playerGui
    
    -- Create notification frame
    local notificationFrame = Instance.new("Frame")
    notificationFrame.Name = "NotificationFrame"
    notificationFrame.Size = UDim2.new(0, 400, 0, 120)
    notificationFrame.Position = UDim2.new(1, -420, 0, 20)
    notificationFrame.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
    notificationFrame.BorderSizePixel = 0
    notificationFrame.Visible = false
    notificationFrame.Parent = notificationGui
    
    -- Add corner radius
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 8)
    corner.Parent = notificationFrame
    
    -- Add notification text
    local notificationText = Instance.new("TextLabel")
    notificationText.Name = "NotificationText"
    notificationText.Size = UDim2.new(1, -20, 0.7, 0)
    notificationText.Position = UDim2.new(0, 10, 0, 10)
    notificationText.BackgroundTransparency = 1
    notificationText.Text = ""
    notificationText.TextColor3 = Color3.fromRGB(255, 255, 255)
    notificationText.TextScaled = true
    notificationText.TextWrapped = true
    notificationText.Font = Enum.Font.Gotham
    notificationText.Parent = notificationFrame
    
    -- Add close button
    local closeButton = Instance.new("TextButton")
    closeButton.Name = "CloseButton"
    closeButton.Size = UDim2.new(0, 60, 0, 25)
    closeButton.Position = UDim2.new(1, -70, 1, -35)
    closeButton.BackgroundColor3 = Color3.fromRGB(70, 70, 70)
    closeButton.BorderSizePixel = 0
    closeButton.Text = "OK"
    closeButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    closeButton.Font = Enum.Font.Gotham
    closeButton.TextScaled = true
    closeButton.Parent = notificationFrame
    
    local closeCorner = Instance.new("UICorner")
    closeCorner.CornerRadius = UDim.new(0, 4)
    closeCorner.Parent = closeButton
    
    closeButton.MouseButton1Click:Connect(function()
        self:HideNotification()
    end)
    
    self.notificationGui = notificationGui
    self.notificationFrame = notificationFrame
    self.notificationText = notificationText
    self.closeButton = closeButton
    
    print("🔗 User notification system setup complete")
end

function CriticalErrorHandler:GetUserFriendlyMessage(errorData)
    local category = errorData.category
    local severity = errorData.severity.name
    
    -- Check for custom user-friendly message
    if errorData.userFriendlyMessage then
        return errorData.userFriendlyMessage
    end
    
    -- Use predefined user-friendly messages
    if USER_FRIENDLY_MESSAGES[category] and USER_FRIENDLY_MESSAGES[category][severity] then
        return USER_FRIENDLY_MESSAGES[category][severity]
    end
    
    -- Generic fallback messages
    if severity == ERROR_SEVERITY.ERROR.name then
        return "A minor issue occurred. The game will continue normally."
    elseif severity == ERROR_SEVERITY.CRITICAL.name then
        return "An issue occurred that may affect gameplay. We're working to resolve it."
    elseif severity == ERROR_SEVERITY.FATAL.name then
        return "A serious error occurred. Please restart the game if issues persist."
    else
        return "An unexpected issue occurred."
    end
end

function CriticalErrorHandler:HandleUserNotification(errorData)
    if not RunService:IsClient() then
        return
    end
    
    local notification = {
        type = "error_notification",
        severity = errorData.severity,
        category = errorData.category,
        message = self:GetUserFriendlyMessage(errorData),
        timestamp = tick(),
        autoHide = true,
        duration = 5.0
    }
    
    self:QueueUserNotification(notification)
end

function CriticalErrorHandler:QueueUserNotification(notification)
    table.insert(self.notificationQueue, notification)
end

function CriticalErrorHandler:ProcessNotificationQueue()
    if not RunService:IsClient() or #self.notificationQueue == 0 then
        return
    end
    
    -- Only show one notification at a time
    if self.currentNotification then
        return
    end
    
    local notification = table.remove(self.notificationQueue, 1)
    self:ShowNotification(notification)
end

function CriticalErrorHandler:ShowNotification(notification)
    if not self.notificationFrame then
        return
    end
    
    self.currentNotification = notification
    
    -- Set notification text and color based on severity
    self.notificationText.Text = notification.message
    
    local severityColor = notification.severity.color
    self.notificationFrame.BackgroundColor3 = Color3.new(
        severityColor.R * 0.3,
        severityColor.G * 0.3, 
        severityColor.B * 0.3
    )
    
    -- Show notification with animation
    self.notificationFrame.Visible = true
    self.notificationFrame:TweenPosition(
        UDim2.new(1, -420, 0, 20),
        "Out",
        "Quad",
        0.3,
        true
    )
    
    -- Auto-hide if specified
    if notification.autoHide then
        task.wait(notification.duration or 5.0)
        self:HideNotification()
    end
end

function CriticalErrorHandler:HideNotification()
    if not self.notificationFrame or not self.currentNotification then
        return
    end
    
    -- Hide notification with animation
    self.notificationFrame:TweenPosition(
        UDim2.new(1, 20, 0, 20),
        "In",
        "Quad",
        0.3,
        true,
        function()
            self.notificationFrame.Visible = false
            self.currentNotification = nil
        end
    )
end

-- ========================================
-- PERFORMANCE MONITORING
-- ========================================

function CriticalErrorHandler:SetupPerformanceMonitoring()
    -- Monitor frame rate
    self:AddConnection("frameRateMonitoring",
        RunService.Heartbeat:Connect(function()
            self.performanceMetrics.frameRate = workspace:GetRealPhysicsFPS()
            
            -- Check for critical performance issues
            if self.performanceMetrics.frameRate < 20 then
                self:HandleError({
                    severity = ERROR_SEVERITY.CRITICAL,
                    category = ERROR_CATEGORIES.PERFORMANCE,
                    message = "Critical frame rate drop detected: " .. self.performanceMetrics.frameRate .. " FPS",
                    source = "PerformanceMonitor",
                    recoveryStrategy = RECOVERY_STRATEGIES.GRACEFUL,
                    gracefulFunction = function()
                        -- Reduce graphics quality or effects
                        self:ReduceGraphicsQuality()
                    end
                })
            end
        end),
        "Connection"
    )
    
    -- Event-driven memory monitoring (NO POLLING)
    task.spawn(function()
        local memoryMonitorEvent = Instance.new("BindableEvent")
        local checkInterval = 5 -- Start with 5 second intervals
        local maxInterval = 60 -- Maximum interval of 1 minute
        
        local function performMemoryCheck()
            if not self.IsRunning then return end
            
            local memoryUsage = collectgarbage("count")
            self.performanceMetrics.memoryUsage = memoryUsage
            
            -- Check for memory issues
            if memoryUsage > 500000 then -- 500MB threshold
                checkInterval = 2 -- More frequent checks when memory is high
                self:HandleError({
                    severity = ERROR_SEVERITY.CRITICAL,
                    category = ERROR_CATEGORIES.MEMORY,
                    message = "High memory usage detected: " .. math.floor(memoryUsage/1024) .. " MB",
                    source = "MemoryMonitor",
                    recoveryStrategy = RECOVERY_STRATEGIES.GRACEFUL,
                    gracefulFunction = function()
                        -- Memory cleanup - Luau's garbage collection
                        local _beforeMem = collectgarbage("count")
                        -- Clear caches if available
                        self:ClearCaches()
                        -- Check memory again
                        local afterMem = collectgarbage("count")
                        print("🧹 Memory cleanup completed. Usage: " .. math.floor(afterMem) .. " KB")
                    end
                })
            else
                -- Gradually increase interval when memory is normal
                checkInterval = math.min(checkInterval * 1.2, maxInterval)
            end
        end
    end)
end

function CriticalErrorHandler:ReduceGraphicsQuality()
    -- This would typically adjust render settings
    -- For now, we'll just log the action
    print("🔧 Reducing graphics quality to improve performance")
    
    -- In a real implementation, you might:
    -- - Reduce particle effects
    -- - Lower shadow quality
    -- - Reduce texture resolution
    -- - Disable non-essential visual effects
end

function CriticalErrorHandler:ClearCaches()
    -- Clear any cached data to free memory
    print("🧹 Clearing caches to free memory")
    
    -- In a real implementation, you might:
    -- - Clear texture caches
    -- - Remove old audio files
    -- - Clean up unused objects
end

-- ========================================
-- CASCADING FAILURE DETECTION
-- ========================================

function CriticalErrorHandler:CheckForCascadingFailures(errorData)
    local currentTime = tick()
    local recentErrorWindow = 30 -- 30 seconds
    
    -- Count recent errors
    local recentErrorCount = 0
    for _, recentError in ipairs(self.errorStats.recentErrors) do
        if currentTime - recentError.timestamp <= recentErrorWindow then
            recentErrorCount = recentErrorCount + 1
        end
    end
    
    -- Check for error cascade
    if recentErrorCount >= 10 then -- 10 errors in 30 seconds
        self:HandleCascadingFailure()
    end
    
    -- Check for component failure cascade
    local componentId = errorData.component or errorData.source
    local componentErrors = 0
    for _, recentError in ipairs(self.errorStats.recentErrors) do
        if (recentError.component == componentId or recentError.source == componentId) and
           currentTime - recentError.timestamp <= recentErrorWindow then
            componentErrors = componentErrors + 1
        end
    end
    
    if componentErrors >= 5 then -- 5 errors from same component in 30 seconds
        self:IsolateComponent(componentId, errorData)
    end
end

function CriticalErrorHandler:HandleCascadingFailure()
    self:HandleError({
        severity = ERROR_SEVERITY.FATAL,
        category = ERROR_CATEGORIES.SYSTEM,
        message = "Cascading failure detected - multiple system errors",
        source = "CascadeDetector",
        recoveryStrategy = RECOVERY_STRATEGIES.USER_NOTIFY,
        userFriendlyMessage = "Multiple system errors detected. The game may need to be restarted for optimal performance."
    })
end

-- ========================================
-- COMPONENT MANAGEMENT
-- ========================================

function CriticalErrorHandler:NotifyComponentIsolation(componentId, errorData)
    -- Notify other systems that a component has been isolated
    print("🔒 Component isolated: " .. componentId .. " due to: " .. errorData.message)
    
    -- Here you would typically notify other services about the isolation
    -- so they can adapt their behavior accordingly
end

function CriticalErrorHandler:ReintegrateComponent(componentId)
    self.isolatedComponents[componentId] = nil
    print("🔓 Component reintegrated: " .. componentId)
end

function CriticalErrorHandler:CheckIsolatedComponents()
    local currentTime = tick()
    local reintegrationTimeout = 300 -- 5 minutes
    
    for componentId, isolationData in pairs(self.isolatedComponents) do
        if currentTime - isolationData.timestamp > reintegrationTimeout then
            -- Attempt to reintegrate the component
            print("⏰ Attempting to reintegrate isolated component: " .. componentId)
            self:ReintegrateComponent(componentId)
        end
    end
end

function CriticalErrorHandler:MonitorRecoveryAttempts()
    local currentTime = tick()
    local resetTimeout = 300 -- 5 minutes
    
    for componentId, attempts in pairs(self.recoveryAttempts) do
        -- Reset recovery attempts after timeout (component might be working again)
        local lastErrorTime = 0
        for _, recentError in ipairs(self.errorStats.recentErrors) do
            if (recentError.component == componentId or recentError.source == componentId) then
                lastErrorTime = math.max(lastErrorTime, recentError.timestamp)
            end
        end
        
        if currentTime - lastErrorTime > resetTimeout then
            self.recoveryAttempts[componentId] = 0
        end
    end
end

-- ========================================
-- ERROR TRACKING AND STATISTICS
-- ========================================

function CriticalErrorHandler:RegisterError(errorData)
    -- Add to registry
    self.errorRegistry[errorData.id] = errorData
    
    -- Update statistics
    self.errorStats.totalErrors = self.errorStats.totalErrors + 1
    self.errorStats.errorsBySeverity[errorData.severity.name] = 
        (self.errorStats.errorsBySeverity[errorData.severity.name] or 0) + 1
    self.errorStats.errorsByCategory[errorData.category] = 
        (self.errorStats.errorsByCategory[errorData.category] or 0) + 1
    self.errorStats.errorsBySource[errorData.source] = 
        (self.errorStats.errorsBySource[errorData.source] or 0) + 1
    
    -- Add to recent errors (keep last 100)
    table.insert(self.errorStats.recentErrors, errorData)
    if #self.errorStats.recentErrors > 100 then
        table.remove(self.errorStats.recentErrors, 1)
    end
    
    -- Track critical errors separately
    if errorData.severity.level >= ERROR_SEVERITY.CRITICAL.level then
        table.insert(self.errorStats.criticalErrors, errorData)
        if #self.errorStats.criticalErrors > 50 then
            table.remove(self.errorStats.criticalErrors, 1)
        end
    end
end

function CriticalErrorHandler:MonitorErrorRates()
    local currentTime = tick()
    local timeWindow = 60 -- 1 minute
    
    -- Calculate error rate
    local recentErrorCount = 0
    for _, recentError in ipairs(self.errorStats.recentErrors) do
        if currentTime - recentError.timestamp <= timeWindow then
            recentErrorCount = recentErrorCount + 1
        end
    end
    
    self.errorStats.errorRate = recentErrorCount
    self.errorStats.lastErrorTime = currentTime
    
    -- Check for error rate spike
    if recentErrorCount > self.config.maxErrorsPerMinute then
        self:HandleError({
            severity = ERROR_SEVERITY.CRITICAL,
            category = ERROR_CATEGORIES.SYSTEM,
            message = "Error rate spike detected: " .. recentErrorCount .. " errors in last minute",
            source = "ErrorRateMonitor",
            recoveryStrategy = RECOVERY_STRATEGIES.GRACEFUL
        })
    end
end

-- ========================================
-- STRUCTURED LOGGING
-- ========================================

function CriticalErrorHandler:LogStructuredError(errorData)
    local logLevel = errorData.severity.level
    local icon = errorData.severity.icon
    local _color = errorData.severity.color
    
    -- Create structured log message
    local logMessage = string.format(
        "%s [%s] [%s] %s: %s",
        icon,
        errorData.severity.name,
        errorData.category:upper(),
        errorData.source,
        errorData.message
    )
    
    -- Use appropriate Roblox logging method
    if logLevel >= ERROR_SEVERITY.FATAL.level then
        error(logMessage, 0) -- This will be caught by our error boundary
    elseif logLevel >= ERROR_SEVERITY.CRITICAL.level then
        warn(logMessage)
    elseif logLevel >= ERROR_SEVERITY.WARN.level then
        warn(logMessage)
    else
        print(logMessage)
    end
    
    -- Add to custom log storage
    local logEntry = {
        id = errorData.id,
        timestamp = errorData.timestamp,
        severity = errorData.severity,
        category = errorData.category,
        source = errorData.source,
        message = errorData.message,
        details = errorData.details,
        stackTrace = errorData.stackTrace
    }
    
    -- Store in custom logs (for later retrieval)
    if not self.customLogs then
        self.customLogs = {}
    end
    
    table.insert(self.customLogs, logEntry)
    
    -- Keep only last 1000 logs to prevent memory issues
    if #self.customLogs > 1000 then
        table.remove(self.customLogs, 1)
    end
end

function CriticalErrorHandler:LogRecoveryAttempt(errorData, recoveryResult)
    local message = string.format("Recovery attempt for error %s using strategy %s: %s",
        errorData.id,
        recoveryResult.strategy,
        recoveryResult.success and "SUCCESS" or "FAILED"
    )
    
    self:LogStructuredError({
        severity = ERROR_SEVERITY.INFO,
        category = ERROR_CATEGORIES.SYSTEM,
        message = message,
        source = "RecoverySystem",
        details = {
            originalErrorId = errorData.id,
            recoveryStrategy = recoveryResult.strategy,
            attempts = recoveryResult.attempts,
            success = recoveryResult.success,
            details = recoveryResult.details
        }
    })
end

-- ========================================
-- EXTERNAL REPORTING
-- ========================================

function CriticalErrorHandler:SendExternalReport(errorData)
    -- This would send error reports to external services
    -- For now, we'll simulate the reporting
    
    local reportData = {
        errorId = errorData.id,
        timestamp = errorData.timestamp,
        severity = errorData.severity.name,
        category = errorData.category,
        source = errorData.source,
        message = errorData.message,
        gameId = game.PlaceId,
        serverId = game.JobId,
        playerCount = #Players:GetPlayers(),
        details = errorData.details
    }
    
    if self.config.debugMode then
        print("📡 Would send external report:", HttpService:JSONEncode(reportData))
    end
    
    -- In production, you would send this to your error tracking service
    -- using HttpService:PostAsync or similar
end

-- ========================================
-- ERROR HANDLERS REGISTRATION
-- ========================================

function CriticalErrorHandler:RegisterErrorHandler(category, handler)
    if not self.globalErrorHandlers[category] then
        self.globalErrorHandlers[category] = {}
    end
    
    table.insert(self.globalErrorHandlers[category], handler)
end

function CriticalErrorHandler:ExecuteErrorHandlers(errorData)
    local handlers = self.globalErrorHandlers[errorData.category] or {}
    
    for _, handler in ipairs(handlers) do
        local success, result = pcall(handler, errorData)
        if not success then
            -- Error in error handler - log it but don't recurse
            print("⚠️ Error handler failed:", result)
        end
    end
end

-- ========================================
-- PUBLIC API METHODS
-- ========================================

-- Convenience methods for different error severities
function CriticalErrorHandler:Trace(message, source, details)
    return self:HandleError({
        severity = ERROR_SEVERITY.TRACE,
        message = message,
        source = source or "Unknown",
        details = details
    })
end

function CriticalErrorHandler:Debug(message, source, details)
    return self:HandleError({
        severity = ERROR_SEVERITY.DEBUG,
        message = message,
        source = source or "Unknown",
        details = details
    })
end

function CriticalErrorHandler:Info(message, source, details)
    return self:HandleError({
        severity = ERROR_SEVERITY.INFO,
        message = message,
        source = source or "Unknown",
        details = details
    })
end

function CriticalErrorHandler:Warn(message, source, details)
    return self:HandleError({
        severity = ERROR_SEVERITY.WARN,
        message = message,
        source = source or "Unknown",
        details = details,
        recoveryStrategy = RECOVERY_STRATEGIES.GRACEFUL
    })
end

function CriticalErrorHandler:Error(message, source, details, category)
    return self:HandleError({
        severity = ERROR_SEVERITY.ERROR,
        message = message,
        source = source or "Unknown",
        details = details,
        category = category or ERROR_CATEGORIES.GAME_LOGIC,
        recoveryStrategy = RECOVERY_STRATEGIES.RETRY
    })
end

function CriticalErrorHandler:Critical(message, source, details, category)
    return self:HandleError({
        severity = ERROR_SEVERITY.CRITICAL,
        message = message,
        source = source or "Unknown",
        details = details,
        category = category or ERROR_CATEGORIES.SYSTEM,
        recoveryStrategy = RECOVERY_STRATEGIES.GRACEFUL
    })
end

function CriticalErrorHandler:Fatal(message, source, details, category)
    return self:HandleError({
        severity = ERROR_SEVERITY.FATAL,
        message = message,
        source = source or "Unknown",
        details = details,
        category = category or ERROR_CATEGORIES.SYSTEM,
        recoveryStrategy = RECOVERY_STRATEGIES.RESTART
    })
end

-- Get error statistics
function CriticalErrorHandler:GetErrorStats()
    return {
        totalErrors = self.errorStats.totalErrors,
        errorRate = self.errorStats.errorRate,
        errorsBySeverity = self.errorStats.errorsBySeverity,
        errorsByCategory = self.errorStats.errorsByCategory,
        errorsBySource = self.errorStats.errorsBySource,
        recentErrorCount = #self.errorStats.recentErrors,
        criticalErrorCount = #self.errorStats.criticalErrors,
        isolatedComponents = self.isolatedComponents,
        gracefullyDegraded = self.gracefullyDegraded,
        uptime = tick() - (self.startTime or tick())
    }
end

-- Get system health report
function CriticalErrorHandler:GetSystemHealthReport()
    local stats = self:GetErrorStats()
    
    local healthScore = 100
    
    -- Reduce health based on error rate
    if stats.errorRate > 20 then
        healthScore = healthScore - 30
    elseif stats.errorRate > 10 then
        healthScore = healthScore - 15
    elseif stats.errorRate > 5 then
        healthScore = healthScore - 5
    end
    
    -- Reduce health based on isolated components
    local isolatedCount = 0
    for _ in pairs(stats.isolatedComponents) do
        isolatedCount = isolatedCount + 1
    end
    healthScore = healthScore - (isolatedCount * 10)
    
    -- Reduce health based on degraded components
    local degradedCount = 0
    for _ in pairs(stats.gracefullyDegraded) do
        degradedCount = degradedCount + 1
    end
    healthScore = healthScore - (degradedCount * 5)
    
    healthScore = math.max(0, healthScore)
    
    return {
        healthScore = healthScore,
        status = healthScore >= 80 and "HEALTHY" or healthScore >= 60 and "DEGRADED" or "CRITICAL",
        errorRate = stats.errorRate,
        isolatedComponents = isolatedCount,
        degradedComponents = degradedCount,
        uptime = stats.uptime,
        recommendations = self:GetHealthRecommendations(healthScore, stats)
    }
end

function CriticalErrorHandler:GetHealthRecommendations(healthScore, stats)
    local recommendations = {}
    
    if stats.errorRate > 10 then
        table.insert(recommendations, "High error rate detected - investigate recent changes")
    end
    
    for componentId in pairs(stats.isolatedComponents) do
        table.insert(recommendations, "Component '" .. componentId .. "' is isolated - manual intervention may be required")
    end
    
    for componentId in pairs(stats.gracefullyDegraded) do
        table.insert(recommendations, "Component '" .. componentId .. "' is running in degraded mode")
    end
    
    if healthScore < 60 then
        table.insert(recommendations, "System health is critical - consider restarting affected services")
    end
    
    return recommendations
end

-- Print comprehensive error report
function CriticalErrorHandler:PrintErrorReport()
    local stats = self:GetErrorStats()
    local health = self:GetSystemHealthReport()
    
    local separator = string.rep("=", 80)
    
    print("\n" .. separator)
    print("🛡️ CRITICAL ERROR HANDLER REPORT")
    print(separator)
    
    print("📊 SYSTEM HEALTH:")
    print("   Health Score: " .. health.healthScore .. "/100 (" .. health.status .. ")")
    print("   Uptime: " .. string.format("%.2f", health.uptime) .. "s")
    print("   Error Rate: " .. health.errorRate .. " errors/minute")
    
    print("\n📈 ERROR STATISTICS:")
    print("   Total Errors: " .. stats.totalErrors)
    print("   Recent Errors: " .. stats.recentErrorCount)
    print("   Critical Errors: " .. stats.criticalErrorCount)
    
    print("\n🏷️ BY SEVERITY:")
    for severity, count in pairs(stats.errorsBySeverity) do
        if count > 0 then
            print("   " .. severity .. ": " .. count)
        end
    end
    
    print("\n📂 BY CATEGORY:")
    for category, count in pairs(stats.errorsByCategory) do
        if count > 0 then
            print("   " .. category:upper() .. ": " .. count)
        end
    end
    
    print("\n🔧 BY SOURCE:")
    for source, count in pairs(stats.errorsBySource) do
        if count > 0 then
            print("   " .. source .. ": " .. count)
        end
    end
    
    if next(stats.isolatedComponents) then
        print("\n🔒 ISOLATED COMPONENTS:")
        for componentId, isolationData in pairs(stats.isolatedComponents) do
            print("   " .. componentId .. " (isolated " .. math.floor(tick() - isolationData.timestamp) .. "s ago)")
        end
    end
    
    if next(stats.gracefullyDegraded) then
        print("\n⚠️ DEGRADED COMPONENTS:")
        for componentId, degradationData in pairs(stats.gracefullyDegraded) do
            print("   " .. componentId .. " (degraded " .. math.floor(tick() - degradationData.timestamp) .. "s ago)")
        end
    end
    
    if #health.recommendations > 0 then
        print("\n💡 RECOMMENDATIONS:")
        for _, recommendation in ipairs(health.recommendations) do
            print("   • " .. recommendation)
        end
    end
    
    print(separator .. "\n")
end

return CriticalErrorHandler
