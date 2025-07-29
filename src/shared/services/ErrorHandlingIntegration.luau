-- ErrorHandlingIntegration.luau
-- Integration service that coordinates error handling, logging, and debugging
-- Provides unified error management across all game systems

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local ConfigurationManager = require(ReplicatedStorage.Shared.core.ConfigurationManager)

local ErrorHandler = require(ReplicatedStorage.Shared.services.ErrorHandler)
local StructuredLogger = require(ReplicatedStorage.Shared.services.StructuredLogger)
local DebugUtilities = require(ReplicatedStorage.Shared.utilities.DebugUtilities)
local DeveloperTools = require(ReplicatedStorage.Shared.utilities.DeveloperTools)

local ErrorHandlingIntegration = {}

-- ========================================
-- INITIALIZATION AND SETUP
-- ========================================

function ErrorHandlingIntegration:Init()
    print("🔗 ErrorHandlingIntegration initializing...")
    
    local config = ConfigurationManager.getInstance()
    
    -- Initialize core services
    self.errorHandler = ErrorHandler:Init()
    self.logger = StructuredLogger:Init()
    self.debugUtils = DebugUtilities:Init()
    self.devTools = DeveloperTools:Init()
    
    -- Setup integration
    self:_setupErrorHandlerIntegration()
    self:_setupLoggerIntegration()
    self:_setupDebugIntegration()
    self:_setupDeveloperToolsIntegration()
    
    -- Setup global error handling
    self:_setupGlobalErrorHandling()
    
    -- Setup performance monitoring
    if config:Get("debugging.FEATURES.ENABLE_PERFORMANCE_MONITORING") then
        self:_setupPerformanceMonitoring()
    end
    
    -- Setup automatic testing (development only)
    if config:Get("debugging.TESTING.ENABLE_UNIT_TESTS") then
        self:_runSystemTests()
    end
    
    print("✅ ErrorHandlingIntegration initialized successfully")
    print("   Integrated: ErrorHandler, StructuredLogger, DebugUtilities, DeveloperTools")
    
    return self
end

-- ========================================
-- ERROR HANDLER INTEGRATION
-- ========================================

function ErrorHandlingIntegration:_setupErrorHandlerIntegration()
    local config = ConfigurationManager.getInstance()
    
    -- Connect error handler to logger
    self.errorHandler:SetLogger(function(level, message, context)
        self.logger:Log(level, message, context)
    end)
    
    -- Connect error handler to debug utilities
    self.errorHandler:SetContextCollector(function(error, additionalContext)
        return self.debugUtils.ErrorDebugger:CaptureErrorContext(error, additionalContext)
    end)
    
    -- Setup error tracking endpoint if configured
    local trackingEndpoint = config:Get("debugging.ERROR_HANDLING.ERROR_TRACKING_ENDPOINT")
    if trackingEndpoint and trackingEndpoint ~= "" then
        self.errorHandler:SetErrorTracker(function(errorData)
            -- Send to external error tracking service
            local success, result = pcall(function()
                local HttpService = game:GetService("HttpService")
                local data = HttpService:JSONEncode(errorData)
                return HttpService:PostAsync(trackingEndpoint, data, Enum.HttpContentType.ApplicationJson)
            end)
            
            if not success then
                self.logger:Warn("Failed to send error to tracking service", {
                    error = result,
                    originalError = errorData
                })
            end
        end)
    end
    
    print("🔗 ErrorHandler integration complete")
end

-- ========================================
-- LOGGER INTEGRATION
-- ========================================

function ErrorHandlingIntegration:_setupLoggerIntegration()
    local config = ConfigurationManager.getInstance()
    
    -- Setup external logging if enabled
    if config:Get("debugging.LOGGING.ENABLE_EXTERNAL_LOGGING") then
        self.logger:AddOutputHandler("external", function(logEntry)
            -- Example: Send logs to external service
            -- This would typically use HttpService to send to a logging service
            local logData = {
                level = logEntry.level,
                message = logEntry.message,
                timestamp = logEntry.timestamp,
                context = logEntry.context,
                gameId = game.PlaceId,
                serverId = game.JobId
            }
            
            -- In a real implementation, you'd send this to your logging service
            -- For now, we'll just store it for potential future use
        end)
    end
    
    -- Setup memory logging output
    if config:Get("debugging.LOGGING.ENABLE_MEMORY_LOGGING") then
        self.logger:SetMemoryLimit(config:Get("debugging.LOGGING.MAX_LOG_ENTRIES"))
        self.logger:EnableRotation(config:Get("debugging.LOGGING.LOG_ROTATION_SIZE"))
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
    local config = ConfigurationManager.getInstance()
    
    -- Auto-start monitoring dashboard
    if config:Get("debugging.DEVELOPER_TOOLS.AUTO_START_DASHBOARD") and RunService:IsClient() then
        wait(3) -- Give time for other systems to initialize
        self.devTools.MonitoringDashboard:CreateDashboard()
    end
    
    -- Setup performance monitoring
    local monitorInterval = config:Get("debugging.DEVELOPER_TOOLS.PERFORMANCE_MONITOR_INTERVAL")
    if monitorInterval and monitorInterval > 0 then
        spawn(function()
            while true do
                wait(monitorInterval)
                self.devTools.PerformanceMonitor:StartMonitoring({
                    interval = math.min(monitorInterval / 10, 5),
                    duration = monitorInterval * 2
                })
            end
        end)
    end
    
    print("🔗 DeveloperTools integration complete")
end

-- ========================================
-- GLOBAL ERROR HANDLING
-- ========================================

function ErrorHandlingIntegration:_setupGlobalErrorHandling()
    -- Wrap common functions with error boundaries
    local originalSpawn = spawn
    spawn = function(func)
        return originalSpawn(function()
            self.errorHandler:ExecuteWithBoundary(func, "spawned_function")
        end)
    end
    
    local originalDelay = delay
    delay = function(time, func)
        return originalDelay(time, function()
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
    
    print("🔗 Global error handling setup complete")
end

-- ========================================
-- PERFORMANCE MONITORING
-- ========================================

function ErrorHandlingIntegration:_setupPerformanceMonitoring()
    local config = ConfigurationManager.getInstance()
    local interval = config:Get("debugging.LOGGING.PERFORMANCE_LOG_INTERVAL")
    
    local lastMemory = collectgarbage("count")
    local lastTime = tick()
    
    local connection = RunService.Heartbeat:Connect(function()
        local currentTime = tick()
        if currentTime - lastTime >= interval then
            local currentMemory = collectgarbage("count")
            local memoryDelta = currentMemory - lastMemory
            
            -- Log performance metrics
            self.logger:Debug("Performance metrics", {
                fps = workspace:GetRealPhysicsFPS(),
                memory = currentMemory,
                memoryDelta = memoryDelta,
                objects = #workspace:GetDescendants(),
                players = #game:GetService("Players"):GetPlayers()
            })
            
            -- Check for performance issues
            if workspace:GetRealPhysicsFPS() < 30 then
                self.logger:Warn("Low FPS detected", {
                    fps = workspace:GetRealPhysicsFPS(),
                    objects = #workspace:GetDescendants()
                })
            end
            
            if memoryDelta > 1000 then -- 1MB growth
                self.logger:Warn("High memory growth detected", {
                    memoryDelta = memoryDelta,
                    totalMemory = currentMemory
                })
            end
            
            lastMemory = currentMemory
            lastTime = currentTime
        end
    end)
    
    -- Cleanup on game close
    game:BindToClose(function()
        connection:Disconnect()
    end)
    
    print("🔗 Performance monitoring setup complete")
end

-- ========================================
-- AUTOMATIC PROFILING
-- ========================================

function ErrorHandlingIntegration:_setupAutomaticProfiling()
    local config = ConfigurationManager.getInstance()
    local sampleRate = config:Get("debugging.PROFILING.PROFILE_SAMPLE_RATE")
    
    -- Profile key functions automatically
    local functionsToProfile = {
        "PlayerService.ProcessPlayerJoin",
        "GameController.UpdateGameState",
        "UIManager.UpdateUI",
        "NetworkManager.ProcessEvents"
    }
    
    for _, funcName in ipairs(functionsToProfile) do
        if math.random() < sampleRate then
            -- This would typically wrap the actual function
            -- For now, we'll just log that we would profile it
            self.logger:Debug("Would start profiling function", {
                functionName = funcName,
                sampleRate = sampleRate
            })
        end
    end
    
    print("🔗 Automatic profiling setup complete")
end

-- ========================================
-- MEMORY DEBUGGING
-- ========================================

function ErrorHandlingIntegration:_setupMemoryDebugging()
    local config = ConfigurationManager.getInstance()
    
    -- Take initial memory snapshot
    self.debugUtils.MemoryDebugger:TakeSnapshot("initialization")
    
    -- Schedule periodic memory checks
    spawn(function()
        while true do
            wait(60) -- Check every minute
            
            local snapshot = self.debugUtils.MemoryDebugger:TakeSnapshot("periodic_" .. tick())
            
            -- Check for potential leaks
            local leaks = self.debugUtils.MemoryDebugger:DetectMemoryLeaks()
            if #leaks > 0 then
                self.logger:Warn("Potential memory leaks detected", {
                    leakCount = #leaks,
                    leaks = leaks
                })
            end
        end
    end)
    
    print("🔗 Memory debugging setup complete")
end

-- ========================================
-- SYSTEM INSPECTION
-- ========================================

function ErrorHandlingIntegration:_setupSystemInspection()
    local config = ConfigurationManager.getInstance()
    local interval = config:Get("debugging.INSPECTION.INSPECTION_INTERVAL")
    
    spawn(function()
        while true do
            wait(interval)
            
            -- Inspect system health
            self.debugUtils.SystemInspector:InspectPerformance()
            
            if RunService:IsServer() then
                self.debugUtils.SystemInspector:InspectNetworking()
            end
            
            self.debugUtils.SystemInspector:InspectServices()
        end
    end)
    
    print("🔗 System inspection setup complete")
end

-- ========================================
-- SYSTEM TESTING
-- ========================================

function ErrorHandlingIntegration:_runSystemTests()
    print("🧪 Running system integration tests...")
    
    local testSuite = self.devTools.TestRunner:CreateTestSuite("ErrorHandlingIntegration")
    
    -- Test error handler integration
    testSuite:AddTest("ErrorHandler responds to errors", function()
        local errorOccurred = false
        
        self.errorHandler:SetLogger(function()
            errorOccurred = true
        end)
        
        self.errorHandler:HandleError({
            message = "Test error",
            category = "TEST"
        })
        
        self.devTools.TestRunner.Assertions.assertTrue(errorOccurred, "Error should trigger logger")
    end)
    
    -- Test logger integration
    testSuite:AddTest("Logger accepts log entries", function()
        local logEntry = self.logger:Info("Test log message", {test = true})
        self.devTools.TestRunner.Assertions.assertNotNil(logEntry, "Logger should return log entry")
    end)
    
    -- Test debug utilities
    testSuite:AddTest("DebugUtilities memory snapshot", function()
        local snapshot = self.debugUtils.MemoryDebugger:TakeSnapshot("test")
        self.devTools.TestRunner.Assertions.assertNotNil(snapshot, "Should create memory snapshot")
        self.devTools.TestRunner.Assertions.assertType(snapshot.memory, "number", "Memory should be number")
    end)
    
    -- Run tests
    local results = testSuite:Run()
    
    if results.failed > 0 or results.errors > 0 then
        self.logger:Error("System integration tests failed", results)
    else
        self.logger:Info("System integration tests passed", results)
    end
end

-- ========================================
-- PUBLIC API
-- ========================================

function ErrorHandlingIntegration:GetErrorHandler()
    return self.errorHandler
end

function ErrorHandlingIntegration:GetLogger()
    return self.logger
end

function ErrorHandlingIntegration:GetDebugUtilities()
    return self.debugUtils
end

function ErrorHandlingIntegration:GetDeveloperTools()
    return self.devTools
end

function ErrorHandlingIntegration:LogError(message, context)
    return self.errorHandler:HandleError({
        message = message,
        context = context,
        source = "integration_api"
    })
end

function ErrorHandlingIntegration:LogInfo(message, context)
    return self.logger:Info(message, context)
end

function ErrorHandlingIntegration:StartProfiling(name)
    return self.debugUtils.PerformanceProfiler:StartProfile(name)
end

function ErrorHandlingIntegration:EndProfiling(name, sessionId)
    return self.debugUtils.PerformanceProfiler:EndProfile(name, sessionId)
end

return ErrorHandlingIntegration
