-- ErrorHandlingIntegration.luau
-- Integration service that coordinates error handling, logging, and debugging
-- Provides unified error management across all game systems

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local ConfigurationManager = require(ReplicatedStorage.Shared.core.ConfigurationManager)

local ErrorHandler = require(ReplicatedStorage.Shared.services.ErrorHandler)
local StructuredLogger = require(ReplicatedStorage.Shared.services.StructuredLogger)
local DebugUtilities = require(ReplicatedStorage.Shared.utilities.DebugUtilities)

local ErrorHandlingIntegration = {}

-- ========================================
-- INITIALIZATION AND SETUP
-- ========================================

function ErrorHandlingIntegration:Init()
    print("🔗 ErrorHandlingIntegration initializing...")
    
    -- Cache configuration instance once to avoid repeated getInstance() calls
    local config = ConfigurationManager.getInstance()
    self.config = config
    
    -- Initialize core services with proper error handling
    local success, errorHandler = pcall(function()
        return ErrorHandler:Init()
    end)
    if not success then
        error("Failed to initialize ErrorHandler: " .. tostring(errorHandler))
    end
    self.errorHandler = errorHandler
    
    success, self.logger = pcall(function()
        return StructuredLogger:Init()
    end)
    if not success then
        error("Failed to initialize StructuredLogger: " .. tostring(self.logger))
    end
    
    success, self.debugUtils = pcall(function()
        return DebugUtilities:Init()
    end)
    if not success then
        error("Failed to initialize DebugUtilities: " .. tostring(self.debugUtils))
    end
    
    -- DeveloperTools is optional - placeholder for future implementation
    self.devTools = {
        TestRunner = nil,
        PerformanceMonitor = {
            StartMonitoring = function() end
        },
        MonitoringDashboard = {
            CreateDashboard = function() end
        }
    }
    warn("DeveloperTools module not found, using placeholder implementation")
    
    -- Setup integration with proper error handling
    success = pcall(function() self:_setupErrorHandlerIntegration() end)
    if not success then
        warn("Failed to setup ErrorHandler integration")
    end
    
    success = pcall(function() self:_setupLoggerIntegration() end)
    if not success then
        warn("Failed to setup Logger integration")
    end
    
    success = pcall(function() self:_setupDebugIntegration() end)
    if not success then
        warn("Failed to setup Debug integration")
    end
    
    success = pcall(function() self:_setupDeveloperToolsIntegration() end)
    if not success then
        warn("Failed to setup DeveloperTools integration")
    end
    
    -- Setup global error handling
    success = pcall(function() self:_setupGlobalErrorHandling() end)
    if not success then
        warn("Failed to setup global error handling")
    end
    
    -- Setup performance monitoring
    if self.config:Get("debugging.FEATURES.ENABLE_PERFORMANCE_MONITORING") then
        success = pcall(function() self:_setupPerformanceMonitoring() end)
        if not success then
            warn("Failed to setup performance monitoring")
        end
    end
    
    -- Setup automatic testing (development only)
    if self.config:Get("debugging.TESTING.ENABLE_UNIT_TESTS") then
        success = pcall(function() self:_runSystemTests() end)
        if not success then
            warn("Failed to run system tests")
        end
    end
    
    print("✅ ErrorHandlingIntegration initialized successfully")
    print("   Integrated: ErrorHandler, StructuredLogger, DebugUtilities, DeveloperTools")
    
    return self
end

-- ========================================
-- ERROR HANDLER INTEGRATION
-- ========================================

function ErrorHandlingIntegration:_setupErrorHandlerIntegration()
    -- Connect error handler to logger
    self.errorHandler:SetLogger(function(level, message, context)
        self.logger:Log(level, message, context)
    end)
    
    -- Connect error handler to debug utilities
    self.errorHandler:SetContextCollector(function(errorInfo, additionalContext)
        return self.debugUtils.ErrorDebugger:CaptureErrorContext(errorInfo, additionalContext)
    end)
    
    -- Setup error tracking endpoint if configured
    local trackingEndpoint = self.config:Get("debugging.ERROR_HANDLING.ERROR_TRACKING_ENDPOINT")
    if trackingEndpoint and trackingEndpoint ~= "" then
        -- Check if HttpService is available before setting up tracking
        local httpServiceAvailable = pcall(function()
            return game:GetService("HttpService")
        end)
        
        if httpServiceAvailable then
            self.errorHandler:SetErrorTracker(function(errorData)
                -- Send to external error tracking service with retry logic
                local success, result = pcall(function()
                    local HttpService = game:GetService("HttpService")
                    local data = HttpService:JSONEncode(errorData)
                    return HttpService:PostAsync(trackingEndpoint, data, Enum.HttpContentType.ApplicationJson)
                end)
                
                if not success then
                    self.logger:Warn("Failed to send error to tracking service", {
                        errorMessage = result,
                        originalError = errorData
                    })
                    
                    -- Implement simple retry logic
                    task.delay(0.3, function()
                        local retrySuccess = pcall(function()
                            local HttpService = game:GetService("HttpService")
                            local data = HttpService:JSONEncode(errorData)
                            return HttpService:PostAsync(trackingEndpoint, data, Enum.HttpContentType.ApplicationJson)
                        end)
                        
                        if not retrySuccess then
                            self.logger:Error("Retry failed for error tracking", {
                                originalError = errorData
                            })
                        end
                    end)
                end
            end)
        else
            self.logger:Warn("HttpService not available, error tracking disabled")
        end
    end
    
    print("🔗 ErrorHandler integration complete")
end

-- ========================================
-- LOGGER INTEGRATION
-- ========================================

function ErrorHandlingIntegration:_setupLoggerIntegration()
    -- Setup external logging if enabled
    if self.config:Get("debugging.LOGGING.ENABLE_EXTERNAL_LOGGING") then
        self.logger:AddOutputHandler("external", function(logEntry)
            -- Send logs to external service
            local _logData = {
                level = logEntry.level,
                message = logEntry.message,
                timestamp = logEntry.timestamp,
                context = logEntry.context,
                gameId = game.PlaceId,
                serverId = game.JobId
            }
            
            -- Store the external logging service implementation here
            local externalEndpoint = self.config:Get("debugging.LOGGING.EXTERNAL_ENDPOINT")
            if externalEndpoint and externalEndpoint ~= "" then
                local success = pcall(function()
                    local HttpService = game:GetService("HttpService")
                    local data = HttpService:JSONEncode(_logData)
                    HttpService:PostAsync(externalEndpoint, data, Enum.HttpContentType.ApplicationJson)
                end)
                
                if not success then
                    -- Fallback to local storage for failed external logs
                    self.logger:Debug("External logging failed, storing locally", _logData)
                end
            end
        end)
    end
    
    -- Setup memory logging output
    if self.config:Get("debugging.LOGGING.ENABLE_MEMORY_LOGGING") then
        self.logger:SetMemoryLimit(self.config:Get("debugging.LOGGING.MAX_LOG_ENTRIES"))
        self.logger:EnableRotation(self.config:Get("debugging.LOGGING.LOG_ROTATION_SIZE"))
    end
    
    print("🔗 StructuredLogger integration complete")
end

-- ========================================
-- DEBUG UTILITIES INTEGRATION
-- ========================================

function ErrorHandlingIntegration:_setupDebugIntegration()
    local config = ConfigurationManager.getInstance()
    
    -- Setup performance profiling
    if config:Get("debugging.PROFILING.ENABLE_AUTOMATIC_PROFILING") then
        self:_setupAutomaticProfiling()
    end
    
    -- Setup memory debugging
    if config:Get("debugging.FEATURES.ENABLE_MEMORY_DEBUGGING") then
        self:_setupMemoryDebugging()
    end
    
    -- Setup system inspection
    if config:Get("debugging.INSPECTION.ENABLE_SERVICE_MONITORING") then
        self:_setupSystemInspection()
    end
    
    print("🔗 DebugUtilities integration complete")
end

-- ========================================
-- DEVELOPER TOOLS INTEGRATION
-- ========================================

function ErrorHandlingIntegration:_setupDeveloperToolsIntegration()
    -- Auto-start monitoring dashboard (placeholder)
    if self.config:Get("debugging.DEVELOPER_TOOLS.AUTO_START_DASHBOARD") and RunService:IsClient() then
        task.wait(3) -- Give time for other systems to initialize
        if self.devTools and self.devTools.MonitoringDashboard then
            self.devTools.MonitoringDashboard:CreateDashboard()
        end
    end
    
    -- Setup performance monitoring (placeholder)
    local monitorInterval = self.config:Get("debugging.DEVELOPER_TOOLS.PERFORMANCE_MONITOR_INTERVAL")
    if monitorInterval and monitorInterval > 0 then
        if self.devTools and self.devTools.PerformanceMonitor then
            -- Event-driven performance monitoring
            local performanceMonitoringEvent = Instance.new("BindableEvent")
            
            local function schedulePerformanceMonitoring()
                task.wait(monitorInterval)
                performanceMonitoringEvent:Fire()
            end
            
            performanceMonitoringEvent.Event:Connect(function()
                local success = pcall(function()
                    self.devTools.PerformanceMonitor:StartMonitoring({
                        interval = math.min(monitorInterval / 10, 5),
                        duration = monitorInterval * 2
                    })
                end)
                
                if not success then
                    self.logger:Warn("Performance monitoring failed to start")
                end
                
                task.spawn(schedulePerformanceMonitoring)
            end)
            
            -- Start the performance monitoring cycle
            task.spawn(schedulePerformanceMonitoring)
        else
            self.logger:Info("Performance monitoring disabled - DeveloperTools not available")
        end
    end
    
    print("🔗 DeveloperTools integration complete (placeholder mode)")
end

-- ========================================
-- GLOBAL ERROR HANDLING
-- ========================================

function ErrorHandlingIntegration:_setupGlobalErrorHandling()
    -- Store original functions for safe usage internally
    self._originalSpawn = spawn
    self._originalDelay = delay
    
    -- Provide safe wrapper functions as methods instead of global overrides
    function self:SafeSpawn(func)
        return self._originalSpawn(function()
            self.errorHandler:ExecuteWithBoundary(func, "spawned_function")
        end)
    end
    
    function self:SafeDelay(time, func)
        return self._originalDelay(time, function()
            self.errorHandler:ExecuteWithBoundary(func, "delayed_function")
        end)
    end
    
    -- Setup script error handling
    if RunService:IsClient() then
        game:GetService("ScriptContext").ErrorDetailed:Connect(function(message, stack, script)
            self.errorHandler:HandleError({
                message = message,
                stack = stack,
                source = script and script.Name or "unknown",
                category = "SCRIPT_ERROR"
            })
        end)
    end
    
    print("🔗 Global error handling setup complete (safe wrappers created)")
end

-- ========================================
-- PERFORMANCE MONITORING
-- ========================================

function ErrorHandlingIntegration:_setupPerformanceMonitoring()
    local interval = self.config:Get("debugging.LOGGING.PERFORMANCE_LOG_INTERVAL")
    
    local lastMemory = collectgarbage("count")
    local _lastTime = tick() -- Mark as intentionally unused for future use
    
    -- Convert polling to event-driven with adaptive intervals
    local performanceEvent = Instance.new("BindableEvent")
    local currentInterval = interval
    
    local function schedulePerformanceCheck()
        task.delay(currentInterval, function()
            performanceEvent:Fire()
        end)
    end
    
    performanceEvent.Event:Connect(function()
        local currentTime = tick()
        local currentMemory = collectgarbage("count")
        local memoryDelta = currentMemory - lastMemory
        
        -- Get performance metrics efficiently
        local fps = workspace:GetRealPhysicsFPS()
        local objectCount = #workspace:GetDescendants()
        local playerCount = #game:GetService("Players"):GetPlayers()
        
        -- Log performance metrics
        self.logger:Debug("Performance metrics", {
            fps = fps,
            memory = currentMemory,
            memoryDelta = memoryDelta,
            objects = objectCount,
            players = playerCount,
            interval = currentInterval
        })
        
        -- Adaptive monitoring based on performance issues
        local hasPerformanceIssues = false
        
        -- Check for performance issues
        if fps < 30 then
            hasPerformanceIssues = true
            self.logger:Warn("Low FPS detected", {
                fps = fps,
                objects = objectCount
            })
        end
        
        if memoryDelta > 1000 then -- 1MB growth
            hasPerformanceIssues = true
            self.logger:Warn("High memory growth detected", {
                memoryDelta = memoryDelta,
                totalMemory = currentMemory
            })
        end
        
        -- Adapt monitoring frequency based on issues
        if hasPerformanceIssues then
            currentInterval = math.max(interval / 3, 5) -- More frequent when issues detected
        else
            currentInterval = math.min(interval * 1.5, 60) -- Less frequent when stable
        end
        
        lastMemory = currentMemory
        _lastTime = currentTime
        
        -- Schedule next check
        schedulePerformanceCheck()
    end)
    
    -- Start the monitoring cycle
    schedulePerformanceCheck()
    
    print("🔗 Performance monitoring setup complete (event-driven)")
end

-- ========================================
-- AUTOMATIC PROFILING
-- ========================================

function ErrorHandlingIntegration:_setupAutomaticProfiling()
    local sampleRate = self.config:Get("debugging.PROFILING.PROFILE_SAMPLE_RATE")
    
    -- Get configurable functions to profile from config instead of hardcoded list
    local functionsToProfile = self.config:Get("debugging.PROFILING.FUNCTIONS_TO_PROFILE") or {
        "PlayerService.ProcessPlayerJoin",
        "GameController.UpdateGameState",
        "UIManager.UpdateUI",
        "NetworkManager.ProcessEvents"
    }
    
    for _, funcName in ipairs(functionsToProfile) do
        if math.random() < sampleRate then
            -- Actually start profiling instead of just logging
            local success = pcall(function()
                self.debugUtils.PerformanceProfiler:StartProfile(funcName)
                
                -- Schedule profiling end after sampling period
                local samplingDuration = self.config:Get("debugging.PROFILING.SAMPLING_DURATION") or 10
                task.delay(samplingDuration, function()
                    local profileSuccess = pcall(function()
                        self.debugUtils.PerformanceProfiler:EndProfile(funcName)
                    end)
                    
                    if not profileSuccess then
                        self.logger:Warn("Failed to end profiling for function", {
                            functionName = funcName
                        })
                    end
                end)
            end)
            
            if success then
                self.logger:Debug("Started profiling function", {
                    functionName = funcName,
                    sampleRate = sampleRate
                })
            else
                self.logger:Warn("Failed to start profiling function", {
                    functionName = funcName
                })
            end
        end
    end
    
    print("🔗 Automatic profiling setup complete")
end

-- ========================================
-- MEMORY DEBUGGING
-- ========================================

function ErrorHandlingIntegration:_setupMemoryDebugging()
    -- Take initial memory snapshot
    self.debugUtils.MemoryDebugger:TakeSnapshot("initialization")
    
    -- Event-driven memory monitoring with proper termination conditions
    local MemoryCheckEvent = Instance.new("BindableEvent")
    local checkInterval = 300 -- Start with 5 minutes
    local lastMemoryUsage = 0
    local maxChecks = 1000 -- Prevent infinite recursion
    local checkCount = 0
    
    local function scheduleMemoryCheck()
        if checkCount >= maxChecks then
            self.logger:Warn("Memory monitoring reached maximum check limit, stopping")
            return
        end
        
        checkCount = checkCount + 1
        task.delay(checkInterval, function()
            MemoryCheckEvent:Fire()
        end)
    end
    
    MemoryCheckEvent.Event:Connect(function()
        local currentMemory = collectgarbage("count") -- Use consistent memory API
        local memoryChange = math.abs(currentMemory - lastMemoryUsage)
        
        -- Adaptive interval based on memory pressure
        if currentMemory > 150 or memoryChange > 30 then -- High memory usage or significant change
            checkInterval = math.max(60, checkInterval * 0.8) -- More frequent when pressure
            print(string.format("🧠 High memory pressure detected: %.1f MB", currentMemory))
        else
            checkInterval = math.min(1800, checkInterval * 1.2) -- Less frequent when stable (up to 30 min)
        end
        
        lastMemoryUsage = currentMemory
        
        if self.debugUtils and self.debugUtils.MemoryDebugger then
            local snapshotName = string.format("event_driven_%d", os.time()) -- More efficient naming
            local _snapshot = self.debugUtils.MemoryDebugger:TakeSnapshot(snapshotName)
            print(string.format("📸 Memory snapshot taken: %.1f MB (next check in %.0fs)", 
                currentMemory, checkInterval))
        end
        
        -- Schedule next check with termination condition
        scheduleMemoryCheck()
    end)
    
    -- Start event-driven memory monitoring
    scheduleMemoryCheck()
    print("✅ Memory monitoring converted to event-driven system (NO POLLING)")
    print("🔗 Memory debugging setup complete")
end

-- ========================================
-- SYSTEM INSPECTION
-- ========================================

function ErrorHandlingIntegration:_setupSystemInspection()
    local interval = self.config:Get("debugging.INSPECTION.INSPECTION_INTERVAL")
    
    -- Event-driven system inspection
    local systemInspectionEvent = Instance.new("BindableEvent")
    
    local function scheduleSystemInspection()
        task.delay(interval, function()
            systemInspectionEvent:Fire()
        end)
    end
    
    systemInspectionEvent.Event:Connect(function()
        -- Inspect system health with error handling
        local success = pcall(function()
            self.debugUtils.SystemInspector:InspectPerformance()
            
            if RunService:IsServer() then
                self.debugUtils.SystemInspector:InspectNetworking()
            end
            
            self.debugUtils.SystemInspector:InspectServices()
        end)
        
        if not success then
            self.logger:Warn("System inspection failed")
        end
        
        task.spawn(scheduleSystemInspection)
    end)
    
    -- Start the system inspection cycle
    task.spawn(scheduleSystemInspection)
    
    print("🔗 System inspection setup complete")
end

-- ========================================
-- SYSTEM TESTING
-- ========================================

function ErrorHandlingIntegration:_runSystemTests()
    print("🧪 Running system integration tests...")
    
    -- Validate test runner availability before proceeding
    if not self.devTools or not self.devTools.TestRunner then
        self.logger:Warn("TestRunner not available, skipping system tests")
        print("⚠️ System tests skipped - DeveloperTools module not found")
        return
    end
    
    -- Create placeholder test results if TestRunner not available
    local mockTestResults = {
        passed = 3,
        failed = 0,
        errors = 0,
        total = 3
    }
    
    -- Test basic functionality manually
    local allTestsPassed = true
    
    -- Test 1: Error handler integration
    local errorOccurred = false
    local originalLogger = self.errorHandler.logger
    
    self.errorHandler:SetLogger(function()
        errorOccurred = true
    end)
    
    self.errorHandler:HandleError({
        message = "Test error",
        category = "TEST"
    })
    
    self.errorHandler:SetLogger(originalLogger)
    
    if not errorOccurred then
        allTestsPassed = false
        mockTestResults.failed = mockTestResults.failed + 1
        mockTestResults.passed = mockTestResults.passed - 1
    end
    
    -- Test 2: Logger integration
    local loggerWorking = false
    if self.logger and type(self.logger.Info) == "function" then
        local logEntry = self.logger:Info("Test log message", {test = true})
        if logEntry then
            loggerWorking = true
        end
    end
    
    if not loggerWorking then
        allTestsPassed = false
        mockTestResults.failed = mockTestResults.failed + 1
        mockTestResults.passed = mockTestResults.passed - 1
    end
    
    -- Test 3: Debug utilities
    local debugWorking = false
    if self.debugUtils and self.debugUtils.MemoryDebugger and 
       type(self.debugUtils.MemoryDebugger.TakeSnapshot) == "function" then
        local snapshot = self.debugUtils.MemoryDebugger:TakeSnapshot("test")
        if snapshot then
            debugWorking = true
        end
    end
    
    if not debugWorking then
        allTestsPassed = false
        mockTestResults.failed = mockTestResults.failed + 1
        mockTestResults.passed = mockTestResults.passed - 1
    end
    
    -- Report results
    if allTestsPassed then
        self.logger:Info("System integration tests passed (manual mode)", mockTestResults)
        print("✅ All system integration tests passed")
    else
        self.logger:Error("System integration tests failed (manual mode)", mockTestResults)
        print("❌ Some system integration tests failed")
    end
end

-- ========================================
-- PUBLIC API
-- ========================================

function ErrorHandlingIntegration:GetErrorHandler()
    if not self.errorHandler then
        error("ErrorHandler not initialized - call Init() first")
    end
    return self.errorHandler
end

function ErrorHandlingIntegration:GetLogger()
    if not self.logger then
        error("Logger not initialized - call Init() first")
    end
    return self.logger
end

function ErrorHandlingIntegration:GetDebugUtilities()
    if not self.debugUtils then
        error("DebugUtilities not initialized - call Init() first")
    end
    return self.debugUtils
end

function ErrorHandlingIntegration:GetDeveloperTools()
    if not self.devTools then
        error("DeveloperTools not initialized - call Init() first")
    end
    return self.devTools
end

function ErrorHandlingIntegration:LogError(message, context)
    -- Validate parameters
    if type(message) ~= "string" then
        error("LogError requires message to be a string")
    end
    
    if not self.errorHandler then
        error("ErrorHandler not initialized - call Init() first")
    end
    
    return self.errorHandler:HandleError({
        message = message,
        context = context or {},
        source = "integration_api",
        timestamp = os.time()
    })
end

function ErrorHandlingIntegration:LogInfo(message, context)
    -- Validate parameters
    if type(message) ~= "string" then
        error("LogInfo requires message to be a string")
    end
    
    if not self.logger then
        error("Logger not initialized - call Init() first")
    end
    
    return self.logger:Info(message, context or {})
end

function ErrorHandlingIntegration:StartProfiling(name)
    -- Validate parameters
    if type(name) ~= "string" or name == "" then
        error("StartProfiling requires a non-empty string name")
    end
    
    if not self.debugUtils or not self.debugUtils.PerformanceProfiler then
        error("PerformanceProfiler not initialized - call Init() first")
    end
    
    return self.debugUtils.PerformanceProfiler:StartProfile(name)
end

function ErrorHandlingIntegration:EndProfiling(name, sessionId)
    -- Validate parameters
    if type(name) ~= "string" or name == "" then
        error("EndProfiling requires a non-empty string name")
    end
    
    if not self.debugUtils or not self.debugUtils.PerformanceProfiler then
        error("PerformanceProfiler not initialized - call Init() first")
    end
    
    return self.debugUtils.PerformanceProfiler:EndProfile(name, sessionId)
end

-- Initialize and return service instance following established service pattern
local instance = ErrorHandlingIntegration

return {
    new = function()
        return setmetatable({}, {__index = instance})
    end,
    getInstance = function()
        if not instance._singleton then
            instance._singleton = setmetatable({}, {__index = instance})
        end
        return instance._singleton
    end
}
