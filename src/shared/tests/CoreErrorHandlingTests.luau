-- CoreErrorHandlingTests.luau
-- Focused test suite for core CriticalErrorHandler functionality
-- Tests error boundaries, recovery mechanisms, and basic functionality

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CriticalErrorHandler = require(ReplicatedStorage.Shared.core.CriticalErrorHandler)

local CoreErrorHandlingTests = {}

-- ========================================
-- TEST FRAMEWORK
-- ========================================

local TestResults = {
    totalTests = 0,
    passedTests = 0,
    failedTests = 0,
    errors = {}
}

function CoreErrorHandlingTests.LogTest(testName, status, details)
    TestResults.totalTests = TestResults.totalTests + 1
    
    if status == "PASS" then
        TestResults.passedTests = TestResults.passedTests + 1
        print("✅ [PASS] " .. testName .. (details and (" - " .. details) or ""))
    elseif status == "FAIL" then
        TestResults.failedTests = TestResults.failedTests + 1
        table.insert(TestResults.errors, {test = testName, details = details})
        print("❌ [FAIL] " .. testName .. (details and (" - " .. details) or ""))
    end
end

function CoreErrorHandlingTests.AssertTrue(condition, testName, details)
    if condition then
        CoreErrorHandlingTests.LogTest(testName, "PASS", details)
        return true
    else
        CoreErrorHandlingTests.LogTest(testName, "FAIL", details or "Condition was false")
        return false
    end
end

function CoreErrorHandlingTests.AssertEqual(expected, actual, testName, details)
    if expected == actual then
        CoreErrorHandlingTests.LogTest(testName, "PASS", details)
        return true
    else
        local failDetails = string.format("Expected: %s, Got: %s", tostring(expected), tostring(actual))
        if details then
            failDetails = details .. " - " .. failDetails
        end
        CoreErrorHandlingTests.LogTest(testName, "FAIL", failDetails)
        return false
    end
end

-- ========================================
-- CORE FUNCTIONALITY TESTS
-- ========================================

function CoreErrorHandlingTests.TestInitialization()
    print("\n🔧 Testing CriticalErrorHandler Initialization...")
    
    local success = pcall(function()
        local handler = CriticalErrorHandler.new()
        CoreErrorHandlingTests.AssertTrue(handler ~= nil, "ErrorHandler.new() creates instance")
        CoreErrorHandlingTests.AssertTrue(type(handler.HandleError) == "function", "Handler has HandleError method")
        CoreErrorHandlingTests.AssertTrue(type(handler.CreateErrorBoundary) == "function", "Handler has CreateErrorBoundary method")
    end)
    
    CoreErrorHandlingTests.AssertTrue(success, "ErrorHandler initializes without errors")
end

function CoreErrorHandlingTests.TestErrorSeverityLevels()
    print("\n🚨 Testing Error Severity Levels...")
    
    local handler = CriticalErrorHandler.new()
    
    local severityLevels = {
        "TRACE", "DEBUG", "INFO", "WARN", "ERROR", "CRITICAL", "FATAL"
    }
    
    for _, level in pairs(severityLevels) do
        CoreErrorHandlingTests.AssertTrue(
            handler.ERROR_SEVERITY[level] ~= nil,
            "Severity level " .. level .. " exists"
        )
    end
    
    -- Test severity ordering
    CoreErrorHandlingTests.AssertTrue(
        handler.ERROR_SEVERITY.TRACE < handler.ERROR_SEVERITY.DEBUG,
        "TRACE < DEBUG severity ordering"
    )
    
    CoreErrorHandlingTests.AssertTrue(
        handler.ERROR_SEVERITY.ERROR < handler.ERROR_SEVERITY.CRITICAL,
        "ERROR < CRITICAL severity ordering"
    )
    
    CoreErrorHandlingTests.AssertTrue(
        handler.ERROR_SEVERITY.CRITICAL < handler.ERROR_SEVERITY.FATAL,
        "CRITICAL < FATAL severity ordering"
    )
end

function CoreErrorHandlingTests.TestErrorCategories()
    print("\n📂 Testing Error Categories...")
    
    local handler = CriticalErrorHandler.new()
    
    local categories = {
        "SYSTEM", "SERVICE", "GAME_LOGIC", "PHYSICS", "UI", 
        "NETWORK", "DATA", "MEMORY", "PERFORMANCE", "SECURITY",
        "USER_INPUT", "GRAPHICS", "AUDIO"
    }
    
    for _, category in pairs(categories) do
        CoreErrorHandlingTests.AssertTrue(
            handler.ERROR_CATEGORIES[category] ~= nil,
            "Error category " .. category .. " exists"
        )
    end
end

function CoreErrorHandlingTests.TestRecoveryStrategies()
    print("\n🔄 Testing Recovery Strategies...")
    
    local handler = CriticalErrorHandler.new()
    
    local strategies = {
        "IGNORE", "RETRY", "GRACEFUL", "FALLBACK", 
        "RESTART", "DEGRADE", "USER_NOTIFY", "EMERGENCY"
    }
    
    for _, strategy in pairs(strategies) do
        CoreErrorHandlingTests.AssertTrue(
            handler.RECOVERY_STRATEGIES[strategy] ~= nil,
            "Recovery strategy " .. strategy .. " exists"
        )
    end
end

-- ========================================
-- ERROR BOUNDARY TESTS
-- ========================================

function CoreErrorHandlingTests.TestBasicErrorBoundary()
    print("\n🛡️ Testing Basic Error Boundaries...")
    
    local handler = CriticalErrorHandler.new()
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
    CoreErrorHandlingTests.AssertTrue(boundaryExecuted, "Successful boundary function executed")
    CoreErrorHandlingTests.AssertEqual("success", result, "Successful boundary returns correct value")
end

function CoreErrorHandlingTests.TestErrorBoundaryWithError()
    print("\n💥 Testing Error Boundary Error Handling...")
    
    local handler = CriticalErrorHandler.new()
    local errorCaught = false
    
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
    CoreErrorHandlingTests.AssertTrue(errorCaught, "Error boundary catches errors and calls onError")
end

function CoreErrorHandlingTests.TestGracefulRecovery()
    print("\n🎯 Testing Graceful Recovery...")
    
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
    
    CoreErrorHandlingTests.AssertTrue(gracefulCalled, "Graceful recovery function is called on error")
    CoreErrorHandlingTests.AssertEqual("graceful_recovery_value", result, "Graceful recovery returns fallback value")
end

function CoreErrorHandlingTests.TestFallbackRecovery()
    print("\n🔽 Testing Fallback Recovery...")
    
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
    
    CoreErrorHandlingTests.AssertTrue(fallbackCalled, "Fallback function is called on error")
    CoreErrorHandlingTests.AssertEqual("fallback_value", result, "Fallback recovery returns fallback function value")
end

-- ========================================
-- ERROR LOGGING TESTS
-- ========================================

function CoreErrorHandlingTests.TestErrorLogging()
    print("\n📝 Testing Error Logging...")
    
    local handler = CriticalErrorHandler.new()
    
    -- Test different logging levels
    local logTests = {
        {method = "Trace", level = "TRACE"},
        {method = "Debug", level = "DEBUG"}, 
        {method = "Info", level = "INFO"},
        {method = "Warn", level = "WARN"},
        {method = "Error", level = "ERROR"},
        {method = "Critical", level = "CRITICAL"},
        {method = "Fatal", level = "FATAL"}
    }
    
    for _, logTest in pairs(logTests) do
        local success = pcall(function()
            handler[logTest.method](handler, "Test " .. logTest.level .. " message", "TestModule")
        end)
        
        CoreErrorHandlingTests.AssertTrue(
            success, 
            logTest.method .. " logging works without errors"
        )
    end
end

-- ========================================
-- USER NOTIFICATION TESTS
-- ========================================

function CoreErrorHandlingTests.TestUserNotifications()
    print("\n📢 Testing User Notifications...")
    
    local handler = CriticalErrorHandler.new()
    
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
    
    CoreErrorHandlingTests.AssertTrue(notificationSuccess, "User notification boundary executes without crashing")
end

-- ========================================
-- PERFORMANCE TESTS
-- ========================================

function CoreErrorHandlingTests.TestPerformance()
    print("\n📊 Testing Performance...")
    
    local handler = CriticalErrorHandler.new()
    
    -- Test multiple rapid boundary executions
    local startTime = tick()
    
    for i = 1, 100 do
        local perfBoundary = handler:CreateErrorBoundary(
            "PerformanceTest" .. i,
            function()
                return "success" .. i
            end,
            {
                category = handler.ERROR_CATEGORIES.PERFORMANCE,
                severity = handler.ERROR_SEVERITY.INFO,
                recoveryStrategy = handler.RECOVERY_STRATEGIES.IGNORE
            }
        )
        
        perfBoundary()
    end
    
    local totalTime = tick() - startTime
    
    CoreErrorHandlingTests.AssertTrue(totalTime < 1, "100 boundary executions complete in under 1 second")
    print(string.format("  ⏱️ Performance: 100 boundaries executed in %.3f seconds", totalTime))
end

-- ========================================
-- STRESS TESTS
-- ========================================

function CoreErrorHandlingTests.TestStressConditions()
    print("\n💪 Testing Stress Conditions...")
    
    local handler = CriticalErrorHandler.new()
    local errorCount = 0
    local successCount = 0
    
    -- Test rapid error generation with mixed success/failure
    for i = 1, 50 do
        local stressBoundary = handler:CreateErrorBoundary(
            "StressTest" .. i,
            function()
                if math.random() > 0.6 then -- 40% success rate
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
        
        local result = stressBoundary()
        if result == "success" then
            successCount = successCount + 1
        end
    end
    
    CoreErrorHandlingTests.AssertTrue(errorCount > 0, "Stress test generates expected errors")
    CoreErrorHandlingTests.AssertTrue(successCount > 0, "Stress test has some successes")
    CoreErrorHandlingTests.AssertEqual(50, errorCount + successCount, "All stress test attempts are accounted for")
    
    print(string.format("  🔢 Stress results: %d errors, %d successes out of 50 attempts", errorCount, successCount))
end

-- ========================================
-- MAIN TEST EXECUTION
-- ========================================

function CoreErrorHandlingTests.RunAllTests()
    print("🧪 Starting Core Error Handling Test Suite...")
    print("=" .. string.rep("=", 60))
    
    local overallStartTime = tick()
    
    -- Event-driven test sequencing (NO POLLING)
    local function runTestSequence()
        local tests = {
            CoreErrorHandlingTests.TestInitialization,
            CoreErrorHandlingTests.TestErrorSeverityLevels,
            CoreErrorHandlingTests.TestErrorCategories,
            CoreErrorHandlingTests.TestRecoveryStrategies,
            CoreErrorHandlingTests.TestBasicErrorBoundary,
            CoreErrorHandlingTests.TestErrorBoundaryWithError,
            CoreErrorHandlingTests.TestGracefulRecovery,
            CoreErrorHandlingTests.TestFallbackRecovery,
            CoreErrorHandlingTests.TestErrorLogging,
            CoreErrorHandlingTests.TestUserNotifications,
            CoreErrorHandlingTests.TestPerformance,
            CoreErrorHandlingTests.TestStressConditions
        }
        
        local currentTest = 1
        local function runNextTest()
            if currentTest <= #tests then
                tests[currentTest]()
                currentTest = currentTest + 1
                -- Small delay between tests for readability
                task.delay(0.05, runNextTest)
            else
                -- All tests complete
                local overallTime = tick() - overallStartTime
                CoreErrorHandlingTests.PrintResults(overallTime)
            end
        end
        
        runNextTest()
    end
    
    runTestSequence()
    
    return TestResults
end

function CoreErrorHandlingTests.PrintResults(totalTime)
    print("\n" .. "=" .. string.rep("=", 60))
    print("🎯 CORE ERROR HANDLING TEST RESULTS")
    print("=" .. string.rep("=", 60))
    
    print(string.format("📊 Total Tests: %d", TestResults.totalTests))
    print(string.format("✅ Passed: %d", TestResults.passedTests))
    print(string.format("❌ Failed: %d", TestResults.failedTests))
    
    local successRate = TestResults.totalTests > 0 and (TestResults.passedTests / TestResults.totalTests * 100) or 0
    print(string.format("📈 Success Rate: %.1f%%", successRate))
    
    if totalTime then
        print(string.format("⏱️ Total Test Time: %.2f seconds", totalTime))
    end
    
    if #TestResults.errors > 0 then
        print("\n❌ FAILED TESTS:")
        for i, errorInfo in ipairs(TestResults.errors) do
            print(string.format("  %d. %s: %s", i, errorInfo.test, errorInfo.details))
        end
    end
    
    if successRate >= 95 then
        print("\n🎉 EXCELLENT! Core error handling system is working perfectly.")
    elseif successRate >= 85 then
        print("\n👍 GOOD! Core error handling system is working well with minor issues.")
    elseif successRate >= 70 then
        print("\n⚠️ WARNING! Core error handling system has some issues that need attention.")
    else
        print("\n🚨 CRITICAL! Core error handling system has major problems that need immediate attention.")
    end
    
    print("=" .. string.rep("=", 60))
    
    return TestResults
end

-- Auto-run tests in Studio for development
if game:GetService("RunService"):IsStudio() and not _G.CoreErrorHandlingTestsRun then
    _G.CoreErrorHandlingTestsRun = true
    
    task.spawn(function()
        task.wait(1) -- Give services time to initialize
        CoreErrorHandlingTests.RunAllTests()
    end)
end

return CoreErrorHandlingTests
