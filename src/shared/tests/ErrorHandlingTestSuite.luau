-- ErrorHandlingTestSuite.luau
-- Comprehensive test suite for validating the CriticalErrorHandler system
-- Tests error boundaries, recovery mechanisms, graceful degradation, and user notifications

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local _RunService = game:GetService("RunService")

local CriticalErrorHandler = require(ReplicatedStorage.Shared.core.CriticalErrorHandler)
local _ModernServiceFramework = require(ReplicatedStorage.Shared.core.ModernServiceFramework)
-- Note: ObstacleSpawnerServiceWithErrorHandling would be in ServerStorage for server-side testing
-- For this test suite, we'll create mock service behavior

local ErrorHandlingTestSuite = {}

-- ========================================
-- TEST CONFIGURATION
-- ========================================

local TestConfig = {
    verboseOutput = true,
    pauseBetweenTests = 1,
    timeoutSeconds = 30,
    mockPlayerCount = 3,
    enableUserNotifications = true,
    enableRecoveryTesting = true
}

local TestResults = {
    totalTests = 0,
    passedTests = 0,
    failedTests = 0,
    skippedTests = 0,
    errors = {},
    recoveryValidations = {},
    performanceMetrics = {}
}

-- ========================================
-- TEST FRAMEWORK UTILITIES
-- ========================================

function ErrorHandlingTestSuite.LogTest(testName, status, details)
    TestResults.totalTests = TestResults.totalTests + 1
    
    if status == "PASS" then
        TestResults.passedTests = TestResults.passedTests + 1
        if TestConfig.verboseOutput then
            print("✅ [TEST PASS] " .. testName .. (details and (" - " .. details) or ""))
        end
    elseif status == "FAIL" then
        TestResults.failedTests = TestResults.failedTests + 1
        table.insert(TestResults.errors, {test = testName, details = details})
        print("❌ [TEST FAIL] " .. testName .. (details and (" - " .. details) or ""))
    elseif status == "SKIP" then
        TestResults.skippedTests = TestResults.skippedTests + 1
        if TestConfig.verboseOutput then
            print("⏭️ [TEST SKIP] " .. testName .. (details and (" - " .. details) or ""))
        end
    end
end

function ErrorHandlingTestSuite.AssertTrue(condition, testName, details)
    if condition then
        ErrorHandlingTestSuite.LogTest(testName, "PASS", details)
        return true
    else
        ErrorHandlingTestSuite.LogTest(testName, "FAIL", details or "Condition was false")
        return false
    end
end

function ErrorHandlingTestSuite.AssertEqual(expected, actual, testName, details)
    if expected == actual then
        ErrorHandlingTestSuite.LogTest(testName, "PASS", details)
        return true
    else
        local failDetails = string.format("Expected: %s, Got: %s", tostring(expected), tostring(actual))
        if details then
            failDetails = details .. " - " .. failDetails
        end
        ErrorHandlingTestSuite.LogTest(testName, "FAIL", failDetails)
        return false
    end
end

function ErrorHandlingTestSuite.CreateMockPlayer(userId)
    -- Create a mock player object for testing
    local mockPlayer = {}
    mockPlayer.Name = "TestPlayer" .. userId
    mockPlayer.UserId = userId
    mockPlayer.Parent = Players
    
    -- Create mock character
    local character = Instance.new("Model")
    character.Name = mockPlayer.Name
    
    local humanoidRootPart = Instance.new("Part")
    humanoidRootPart.Name = "HumanoidRootPart"
    humanoidRootPart.Position = Vector3.new(0, 10, 0)
    humanoidRootPart.Anchored = true
    humanoidRootPart.Parent = character
    
    character.Parent = workspace
    mockPlayer.Character = character
    
    return mockPlayer
end

-- ========================================
-- ERROR HANDLER CORE TESTS
-- ========================================

function ErrorHandlingTestSuite.TestErrorHandlerInitialization()
    print("\n🔧 Testing CriticalErrorHandler Initialization...")
    
    local startTime = tick()
    
    -- Test initialization
    local success = pcall(function()
        local handler = CriticalErrorHandler.new()
        ErrorHandlingTestSuite.AssertTrue(handler ~= nil, "ErrorHandler.new() creates instance")
        ErrorHandlingTestSuite.AssertTrue(handler.IsInitialized ~= nil, "Handler has IsInitialized property")
        ErrorHandlingTestSuite.AssertTrue(type(handler.HandleError) == "function", "Handler has HandleError method")
        ErrorHandlingTestSuite.AssertTrue(type(handler.CreateErrorBoundary) == "function", "Handler has CreateErrorBoundary method")
    end)
    
    ErrorHandlingTestSuite.AssertTrue(success, "ErrorHandler initializes without errors")
    
    local initTime = tick() - startTime
    TestResults.performanceMetrics.initializationTime = initTime
    
    if initTime > 1 then
        ErrorHandlingTestSuite.LogTest("ErrorHandler initialization performance", "FAIL", "Took " .. initTime .. " seconds (should be < 1s)")
    else
        ErrorHandlingTestSuite.LogTest("ErrorHandler initialization performance", "PASS", "Took " .. initTime .. " seconds")
    end
end

function ErrorHandlingTestSuite.TestErrorSeverityLevels()
    print("\n🚨 Testing Error Severity Levels...")
    
    local handler = CriticalErrorHandler.new()
    
    -- Test all severity levels exist
    local severityLevels = {
        "TRACE", "DEBUG", "INFO", "WARN", "ERROR", "CRITICAL", "FATAL"
    }
    
    for _, level in pairs(severityLevels) do
        ErrorHandlingTestSuite.AssertTrue(
            handler.ERROR_SEVERITY[level] ~= nil,
            "Severity level " .. level .. " exists",
            "Value: " .. tostring(handler.ERROR_SEVERITY[level])
        )
    end
    
    -- Test severity ordering
    ErrorHandlingTestSuite.AssertTrue(
        handler.ERROR_SEVERITY.TRACE < handler.ERROR_SEVERITY.DEBUG,
        "TRACE < DEBUG severity ordering"
    )
    
    ErrorHandlingTestSuite.AssertTrue(
        handler.ERROR_SEVERITY.WARN < handler.ERROR_SEVERITY.ERROR,
        "WARN < ERROR severity ordering"
    )
    
    ErrorHandlingTestSuite.AssertTrue(
        handler.ERROR_SEVERITY.ERROR < handler.ERROR_SEVERITY.CRITICAL,
        "ERROR < CRITICAL severity ordering"
    )
    
    ErrorHandlingTestSuite.AssertTrue(
        handler.ERROR_SEVERITY.CRITICAL < handler.ERROR_SEVERITY.FATAL,
        "CRITICAL < FATAL severity ordering"
    )
end

function ErrorHandlingTestSuite.TestErrorCategories()
    print("\n📂 Testing Error Categories...")
    
    local handler = CriticalErrorHandler.new()
    
    -- Test all categories exist
    local categories = {
        "SYSTEM", "SERVICE", "GAME_LOGIC", "PHYSICS", "UI", 
        "NETWORK", "DATA", "MEMORY", "PERFORMANCE", "SECURITY",
        "USER_INPUT", "GRAPHICS", "AUDIO"
    }
    
    for _, category in pairs(categories) do
        ErrorHandlingTestSuite.AssertTrue(
            handler.ERROR_CATEGORIES[category] ~= nil,
            "Error category " .. category .. " exists"
        )
    end
end

function ErrorHandlingTestSuite.TestRecoveryStrategies()
    print("\n🔄 Testing Recovery Strategies...")
    
    local handler = CriticalErrorHandler.new()
    
    -- Test all recovery strategies exist
    local strategies = {
        "IGNORE", "RETRY", "GRACEFUL", "FALLBACK", 
        "RESTART", "DEGRADE", "USER_NOTIFY", "EMERGENCY"
    }
    
    for _, strategy in pairs(strategies) do
        ErrorHandlingTestSuite.AssertTrue(
            handler.RECOVERY_STRATEGIES[strategy] ~= nil,
            "Recovery strategy " .. strategy .. " exists"
        )
    end
end

-- ========================================
-- ERROR BOUNDARY TESTS
-- ========================================

function ErrorHandlingTestSuite.TestBasicErrorBoundary()
    print("\n🛡️ Testing Basic Error Boundaries...")
    
    local handler = CriticalErrorHandler.new()
    local errorCaught = false
    local boundaryExecuted = false
    
    -- Test successful execution
    local successBoundary = handler:CreateErrorBoundary(
        "TestSuccessfulBoundary",
        function()
            boundaryExecuted = true
            return "success"
        end,
        {
            category = handler.ERROR_CATEGORIES.SYSTEM,
            severity = handler.ERROR_SEVERITY.ERROR,
            recoveryStrategy = handler.RECOVERY_STRATEGIES.IGNORE
        }
    )
    
    local result = successBoundary()
    ErrorHandlingTestSuite.AssertTrue(boundaryExecuted, "Successful boundary function executed")
    ErrorHandlingTestSuite.AssertEqual("success", result, "Successful boundary returns correct value")
    
    -- Test error handling
    local errorBoundary = handler:CreateErrorBoundary(
        "TestErrorBoundary",
        function()
            error("Test error")
        end,
        {
            category = handler.ERROR_CATEGORIES.SYSTEM,
            severity = handler.ERROR_SEVERITY.ERROR,
            recoveryStrategy = handler.RECOVERY_STRATEGIES.IGNORE,
            onError = function(errorData)
                errorCaught = true
            end
        }
    )
    
    errorBoundary()
    ErrorHandlingTestSuite.AssertTrue(errorCaught, "Error boundary catches errors and calls onError")
end

function ErrorHandlingTestSuite.TestRetryRecoveryStrategy()
    print("\n🔁 Testing Retry Recovery Strategy...")
    
    local handler = CriticalErrorHandler.new()
    local attemptCount = 0
    local maxAttempts = 3
    
    local retryBoundary = handler:CreateErrorBoundary(
        "TestRetryBoundary",
        function()
            attemptCount = attemptCount + 1
            if attemptCount < maxAttempts then
                error("Retry test error")
            end
            return "success_after_retry"
        end,
        {
            category = handler.ERROR_CATEGORIES.SYSTEM,
            severity = handler.ERROR_SEVERITY.ERROR,
            recoveryStrategy = handler.RECOVERY_STRATEGIES.RETRY,
            maxRetryAttempts = maxAttempts,
            retryFunction = function()
                -- Retry logic would go here
            end
        }
    )
    
    local result = retryBoundary()
    
    ErrorHandlingTestSuite.AssertEqual(maxAttempts, attemptCount, "Retry strategy attempts correct number of times")
    ErrorHandlingTestSuite.AssertEqual("success_after_retry", result, "Retry strategy succeeds after retries")
end

function ErrorHandlingTestSuite.TestGracefulRecoveryStrategy()
    print("\n🎯 Testing Graceful Recovery Strategy...")
    
    local handler = CriticalErrorHandler.new()
    local gracefulCalled = false
    
    local gracefulBoundary = handler:CreateErrorBoundary(
        "TestGracefulBoundary",
        function()
            error("Graceful test error")
        end,
        {
            category = handler.ERROR_CATEGORIES.SYSTEM,
            severity = handler.ERROR_SEVERITY.ERROR,
            recoveryStrategy = handler.RECOVERY_STRATEGIES.GRACEFUL,
            gracefulFunction = function()
                gracefulCalled = true
                return "graceful_recovery_value"
            end
        }
    )
    
    local result = gracefulBoundary()
    
    ErrorHandlingTestSuite.AssertTrue(gracefulCalled, "Graceful recovery function is called on error")
    ErrorHandlingTestSuite.AssertEqual("graceful_recovery_value", result, "Graceful recovery returns fallback value")
end

function ErrorHandlingTestSuite.TestFallbackRecoveryStrategy()
    print("\n🔽 Testing Fallback Recovery Strategy...")
    
    local handler = CriticalErrorHandler.new()
    local fallbackCalled = false
    
    local fallbackBoundary = handler:CreateErrorBoundary(
        "TestFallbackBoundary",
        function()
            error("Fallback test error")
        end,
        {
            category = handler.ERROR_CATEGORIES.SYSTEM,
            severity = handler.ERROR_SEVERITY.ERROR,
            recoveryStrategy = handler.RECOVERY_STRATEGIES.FALLBACK,
            fallbackFunction = function()
                fallbackCalled = true
                return "fallback_value"
            end,
            fallbackValue = "default_fallback"
        }
    )
    
    local result = fallbackBoundary()
    
    ErrorHandlingTestSuite.AssertTrue(fallbackCalled, "Fallback function is called on error")
    ErrorHandlingTestSuite.AssertEqual("fallback_value", result, "Fallback recovery returns fallback function value")
end

-- ========================================
-- SERVICE INTEGRATION TESTS
-- ========================================

function ErrorHandlingTestSuite.TestServiceWithErrorHandling()
    print("\n🏗️ Testing Service Integration with Error Handling...")
    
    local service = {
        Priority = 1,
        Dependencies = {"CriticalErrorHandler"}
    })
    
    ErrorHandlingTestSuite.AssertTrue(service ~= nil, "Service with error handling creates successfully")
    ErrorHandlingTestSuite.AssertTrue(service.errorHandler ~= nil, "Service has error handler dependency")
    
    -- Test service initialization with error handling
    local initSuccess = pcall(function()
        service:Initialize()
    end)
    
    ErrorHandlingTestSuite.AssertTrue(initSuccess, "Service initialization with error handling succeeds")
    ErrorHandlingTestSuite.AssertTrue(service.IsInitialized, "Service is marked as initialized")
    
    -- Test service starting with error handling
    local startSuccess = pcall(function()
        service:Start()
    end)
    
    ErrorHandlingTestSuite.AssertTrue(startSuccess, "Service start with error handling succeeds")
    ErrorHandlingTestSuite.AssertTrue(service.IsRunning, "Service is marked as running")
end

function ErrorHandlingTestSuite.TestPlayerManagementWithErrors()
    print("\n👥 Testing Player Management Error Handling...")
    
    local service = {IsRunning = true}
    service:Initialize()
    
    -- Test valid player initialization
    local mockPlayer = ErrorHandlingTestSuite.CreateMockPlayer(12345)
    
    local initSuccess = pcall(function()
        service:InitializePlayerSpawning(mockPlayer)
    end)
    
    ErrorHandlingTestSuite.AssertTrue(initSuccess, "Player initialization succeeds with valid player")
    
    local userId = tostring(mockPlayer.UserId)
    ErrorHandlingTestSuite.AssertTrue(
        service.playerSpawnRates[userId] ~= nil,
        "Player spawn data is created"
    )
    
    ErrorHandlingTestSuite.AssertTrue(
        service.activeObstacles[userId] ~= nil,
        "Player obstacle tracking is created"
    )
    
    -- Test invalid player handling
    local invalidInitSuccess = pcall(function()
        service:InitializePlayerSpawning(nil)
    end)
    
    ErrorHandlingTestSuite.AssertTrue(invalidInitSuccess, "Invalid player initialization is handled gracefully")
    
    -- Test player cleanup
    local cleanupSuccess = pcall(function()
        service:CleanupPlayerSpawning(mockPlayer)
    end)
    
    ErrorHandlingTestSuite.AssertTrue(cleanupSuccess, "Player cleanup succeeds")
    ErrorHandlingTestSuite.AssertTrue(
        service.playerSpawnRates[userId] == nil,
        "Player spawn data is cleaned up"
    )
    
    -- Cleanup mock player
    if mockPlayer.Character then
        mockPlayer.Character:Destroy()
    end
end

function ErrorHandlingTestSuite.TestObstacleSpawningWithErrors()
    print("\n🧱 Testing Obstacle Spawning Error Handling...")
    
    local service = {IsRunning = true}
    service:Initialize()
    service:Start()
    
    local mockPlayer = ErrorHandlingTestSuite.CreateMockPlayer(67890)
    service:InitializePlayerSpawning(mockPlayer)
    
    local currentTime = tick()
    local playerData = service.playerSpawnRates[tostring(mockPlayer.UserId)]
    
    -- Test normal spawning
    local spawnSuccess = pcall(function()
        service:ProcessPlayerSpawning(mockPlayer, currentTime)
    end)
    
    ErrorHandlingTestSuite.AssertTrue(spawnSuccess, "Player spawning processing succeeds")
    
    -- Test spawning with invalid player data
    local invalidSpawnSuccess = pcall(function()
        service:ProcessPlayerSpawning(nil, currentTime)
    end)
    
    ErrorHandlingTestSuite.AssertTrue(invalidSpawnSuccess, "Invalid player spawning is handled gracefully")
    
    -- Test obstacle creation
    local createSuccess = pcall(function()
        local obstacle = service:CreateObstacle("simple_block", Vector3.new(0, 10, 50))
        ErrorHandlingTestSuite.AssertTrue(obstacle ~= nil, "Obstacle creation returns valid object")
        if obstacle then
            obstacle:Destroy()
        end
    end)
    
    ErrorHandlingTestSuite.AssertTrue(createSuccess, "Obstacle creation succeeds")
    
    -- Test invalid obstacle creation
    local invalidCreateSuccess = pcall(function()
        local obstacle = service:CreateObstacle("invalid_type", Vector3.new(0, 0, 0))
        -- Should still create something due to error handling
    end)
    
    ErrorHandlingTestSuite.AssertTrue(invalidCreateSuccess, "Invalid obstacle creation is handled gracefully")
    
    -- Cleanup
    service:CleanupPlayerSpawning(mockPlayer)
    if mockPlayer.Character then
        mockPlayer.Character:Destroy()
    end
end

-- ========================================
-- DEGRADED MODE TESTS
-- ========================================

function ErrorHandlingTestSuite.TestDegradedMode()
    print("\n⚠️ Testing Degraded Mode...")
    
    local service = {IsRunning = true}
    service:Initialize()
    
    -- Test entering degraded mode
    local degradedSuccess = pcall(function()
        service:EnterDegradedMode("Test degraded mode")
    end)
    
    ErrorHandlingTestSuite.AssertTrue(degradedSuccess, "Entering degraded mode succeeds")
    ErrorHandlingTestSuite.AssertTrue(service.spawnConfig.degradedMode, "Service is in degraded mode")
    
    -- Test degraded spawning parameters
    ErrorHandlingTestSuite.AssertTrue(
        service.spawnConfig.baseSpawnRate < 2.0,
        "Spawn rate is reduced in degraded mode"
    )
    
    ErrorHandlingTestSuite.AssertTrue(
        service.spawnConfig.maxObstaclesPerPlayer < 20,
        "Max obstacles per player is reduced in degraded mode"
    )
end

function ErrorHandlingTestSuite.TestEmergencyMode()
    print("\n🚨 Testing Emergency Mode...")
    
    local service = {IsRunning = true}
    service:Initialize()
    
    -- Test entering emergency mode
    local emergencySuccess = pcall(function()
        service:EnterEmergencyMode("Test emergency mode")
    end)
    
    ErrorHandlingTestSuite.AssertTrue(emergencySuccess, "Entering emergency mode succeeds")
    ErrorHandlingTestSuite.AssertTrue(service.spawnConfig.emergencyMode, "Service is in emergency mode")
    
    -- Test that spawning is disabled
    local mockPlayer = ErrorHandlingTestSuite.CreateMockPlayer(11111)
    service:InitializePlayerSpawning(mockPlayer)
    
    local spawnAttemptSuccess = pcall(function()
        service:UpdateSpawning()
    end)
    
    ErrorHandlingTestSuite.AssertTrue(spawnAttemptSuccess, "Spawning update in emergency mode is handled gracefully")
    
    -- Cleanup
    service:CleanupPlayerSpawning(mockPlayer)
    if mockPlayer.Character then
        mockPlayer.Character:Destroy()
    end
end

-- ========================================
-- PERFORMANCE AND MEMORY TESTS
-- ========================================

function ErrorHandlingTestSuite.TestMemoryManagement()
    print("\n💾 Testing Memory Management...")
    
    local service = {IsRunning = true}
    service:Initialize()
    service:Start()
    
    local mockPlayer = ErrorHandlingTestSuite.CreateMockPlayer(99999)
    service:InitializePlayerSpawning(mockPlayer)
    
    -- Test obstacle limit enforcement
    local userId = tostring(mockPlayer.UserId)
    
    -- Manually add obstacles to exceed limit
    for i = 1, 25 do -- Exceed maxObstaclesPerPlayer (20)
        local obstacle = Instance.new("Part")
        obstacle.Name = "TestObstacle" .. i
        obstacle.Position = Vector3.new(i, 10, 50)
        obstacle.Parent = workspace
        table.insert(service.activeObstacles[userId], obstacle)
    end
    
    local beforeCount = #service.activeObstacles[userId]
    ErrorHandlingTestSuite.AssertTrue(beforeCount > 20, "Can create obstacles above limit for testing")
    
    -- Test cleanup
    local cleanupSuccess = pcall(function()
        service:ForceCleanupOldestObstacles(mockPlayer, 10)
    end)
    
    ErrorHandlingTestSuite.AssertTrue(cleanupSuccess, "Force cleanup succeeds")
    
    local afterCount = #service.activeObstacles[userId]
    ErrorHandlingTestSuite.AssertTrue(afterCount < beforeCount, "Cleanup reduces obstacle count")
    
    -- Test emergency cleanup
    local emergencyCleanupSuccess = pcall(function()
        service:PerformEmergencyCleanup()
    end)
    
    ErrorHandlingTestSuite.AssertTrue(emergencyCleanupSuccess, "Emergency cleanup succeeds")
    
    -- Cleanup remaining obstacles and player
    service:ForceCleanupPlayerObstacles(mockPlayer)
    if mockPlayer.Character then
        mockPlayer.Character:Destroy()
    end
end

function ErrorHandlingTestSuite.TestPerformanceMonitoring()
    print("\n📊 Testing Performance Monitoring...")
    
    local handler = CriticalErrorHandler.new()
    
    -- Test performance tracking
    local perfStartTime = tick()
    
    local perfBoundary = handler:CreateErrorBoundary(
        "PerformanceTest",
        function()
            -- Simulate some work
            for i = 1, 1000 do
                local _ = math.sqrt(i)
            end
            return "performance_test_complete"
        end,
        {
            category = handler.ERROR_CATEGORIES.PERFORMANCE,
            severity = handler.ERROR_SEVERITY.INFO,
            recoveryStrategy = handler.RECOVERY_STRATEGIES.IGNORE
        }
    )
    
    local result = perfBoundary()
    local perfTime = tick() - perfStartTime
    
    ErrorHandlingTestSuite.AssertEqual("performance_test_complete", result, "Performance test completes successfully")
    ErrorHandlingTestSuite.AssertTrue(perfTime < 1, "Performance test completes in reasonable time")
    
    TestResults.performanceMetrics.boundaryExecutionTime = perfTime
end

-- ========================================
-- USER NOTIFICATION TESTS
-- ========================================

function ErrorHandlingTestSuite.TestUserNotifications()
    print("\n📢 Testing User Notifications...")
    
    if not TestConfig.enableUserNotifications then
        ErrorHandlingTestSuite.LogTest("User notification tests", "SKIP", "Disabled in test config")
        return
    end
    
    local handler = CriticalErrorHandler.new()
    
    -- Test user-friendly error messages
    local notificationBoundary = handler:CreateErrorBoundary(
        "UserNotificationTest",
        function()
            error("Technical error message")
        end,
        {
            category = handler.ERROR_CATEGORIES.UI,
            severity = handler.ERROR_SEVERITY.ERROR,
            recoveryStrategy = handler.RECOVERY_STRATEGIES.USER_NOTIFY,
            userFriendlyMessage = "Something went wrong, but we're fixing it!"
        }
    )
    
    local notificationSuccess = pcall(function()
        notificationBoundary()
    end)
    
    ErrorHandlingTestSuite.AssertTrue(notificationSuccess, "User notification boundary executes without crashing")
end

-- ========================================
-- STRESS TESTS
-- ========================================

function ErrorHandlingTestSuite.TestStressConditions()
    print("\n💪 Testing Stress Conditions...")
    
    local handler = CriticalErrorHandler.new()
    local service = {IsRunning = true}
    service:Initialize()
    
    -- Test rapid error generation
    local errorCount = 0
    for i = 1, 100 do
        local stressBoundary = handler:CreateErrorBoundary(
            "StressTest" .. i,
            function()
                if math.random() > 0.7 then -- 30% success rate
                    error("Stress test error " .. i)
                end
                return "success"
            end,
            {
                category = handler.ERROR_CATEGORIES.SYSTEM,
                severity = handler.ERROR_SEVERITY.WARN,
                recoveryStrategy = handler.RECOVERY_STRATEGIES.IGNORE,
                onError = function()
                    errorCount = errorCount + 1
                end
            }
        )
        
        stressBoundary()
    end
    
    ErrorHandlingTestSuite.AssertTrue(errorCount > 0, "Stress test generates expected errors")
    ErrorHandlingTestSuite.AssertTrue(errorCount < 100, "Stress test has some successes")
    
    print(string.format("  🔢 Stress test results: %d errors out of 100 attempts", errorCount))
end

-- ========================================
-- MAIN TEST EXECUTION
-- ========================================

function ErrorHandlingTestSuite.RunAllTests()
    print("🧪 Starting Comprehensive Error Handling Test Suite...")
    print("=" .. string.rep("=", 60))
    
    local overallStartTime = tick()
    
    -- Core functionality tests
    ErrorHandlingTestSuite.TestErrorHandlerInitialization()
    task.wait(TestConfig.pauseBetweenTests)
    
    ErrorHandlingTestSuite.TestErrorSeverityLevels()
    task.wait(TestConfig.pauseBetweenTests)
    
    ErrorHandlingTestSuite.TestErrorCategories()
    task.wait(TestConfig.pauseBetweenTests)
    
    ErrorHandlingTestSuite.TestRecoveryStrategies()
    task.wait(TestConfig.pauseBetweenTests)
    
    -- Error boundary tests
    ErrorHandlingTestSuite.TestBasicErrorBoundary()
    task.wait(TestConfig.pauseBetweenTests)
    
    ErrorHandlingTestSuite.TestRetryRecoveryStrategy()
    task.wait(TestConfig.pauseBetweenTests)
    
    ErrorHandlingTestSuite.TestGracefulRecoveryStrategy()
    task.wait(TestConfig.pauseBetweenTests)
    
    ErrorHandlingTestSuite.TestFallbackRecoveryStrategy()
    task.wait(TestConfig.pauseBetweenTests)
    
    -- Service integration tests
    ErrorHandlingTestSuite.TestServiceWithErrorHandling()
    task.wait(TestConfig.pauseBetweenTests)
    
    ErrorHandlingTestSuite.TestPlayerManagementWithErrors()
    task.wait(TestConfig.pauseBetweenTests)
    
    ErrorHandlingTestSuite.TestObstacleSpawningWithErrors()
    task.wait(TestConfig.pauseBetweenTests)
    
    -- Degradation tests
    ErrorHandlingTestSuite.TestDegradedMode()
    task.wait(TestConfig.pauseBetweenTests)
    
    ErrorHandlingTestSuite.TestEmergencyMode()
    task.wait(TestConfig.pauseBetweenTests)
    
    -- Performance tests
    ErrorHandlingTestSuite.TestMemoryManagement()
    task.wait(TestConfig.pauseBetweenTests)
    
    ErrorHandlingTestSuite.TestPerformanceMonitoring()
    task.wait(TestConfig.pauseBetweenTests)
    
    -- User experience tests
    ErrorHandlingTestSuite.TestUserNotifications()
    task.wait(TestConfig.pauseBetweenTests)
    
    -- Stress tests
    ErrorHandlingTestSuite.TestStressConditions()
    
    local overallTime = tick() - overallStartTime
    TestResults.performanceMetrics.totalTestTime = overallTime
    
    -- Print results
    ErrorHandlingTestSuite.PrintResults()
end

function ErrorHandlingTestSuite.PrintResults()
    print("\n" .. "=" .. string.rep("=", 60))
    print("🎯 ERROR HANDLING TEST SUITE RESULTS")
    print("=" .. string.rep("=", 60))
    
    print(string.format("📊 Total Tests: %d", TestResults.totalTests))
    print(string.format("✅ Passed: %d", TestResults.passedTests))
    print(string.format("❌ Failed: %d", TestResults.failedTests))
    print(string.format("⏭️ Skipped: %d", TestResults.skippedTests))
    
    local successRate = TestResults.totalTests > 0 and (TestResults.passedTests / TestResults.totalTests * 100) or 0
    print(string.format("📈 Success Rate: %.1f%%", successRate))
    
    if TestResults.performanceMetrics.totalTestTime then
        print(string.format("⏱️ Total Test Time: %.2f seconds", TestResults.performanceMetrics.totalTestTime))
    end
    
    if #TestResults.errors > 0 then
        print("\n❌ FAILED TESTS:")
        for i, error in ipairs(TestResults.errors) do
            print(string.format("  %d. %s: %s", i, error.test, error.details))
        end
    end
    
    if successRate >= 90 then
        print("\n🎉 EXCELLENT! Error handling system is working correctly.")
    elseif successRate >= 75 then
        print("\n👍 GOOD! Error handling system is mostly working, minor issues detected.")
    elseif successRate >= 50 then
        print("\n⚠️ WARNING! Error handling system has significant issues that need attention.")
    else
        print("\n🚨 CRITICAL! Error handling system is not working properly and needs immediate attention.")
    end
    
    print("=" .. string.rep("=", 60))
    
    return TestResults
end

-- Auto-run tests when required (for quick testing)
if not _G.ErrorHandlingTestSuite then
    _G.ErrorHandlingTestSuite = ErrorHandlingTestSuite
    
    -- Only auto-run in Studio for development
    if game:GetService("RunService"):IsStudio() then
        task.spawn(function()
            task.wait(1) -- Give services time to initialize
            ErrorHandlingTestSuite.RunAllTests()
        end)
    end
end

return ErrorHandlingTestSuite
