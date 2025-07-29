-- CriticalSystemsTestRunner.luau
-- Master test runner for all critical system unit tests

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local SafeRequire = require(ReplicatedStorage.Shared.utils.SafeRequire)
local TestFramework = SafeRequire.require(ReplicatedStorage.Shared.utils.TestFramework)

local CriticalSystemsTestRunner = {}

-- Test suites to run
local testSuites = {
    {
        name = "TutorialService",
        path = "src.server.test.TutorialServiceTest",
        priority = 1
    },
    {
        name = "MainGameService", 
        path = "src.server.test.MainGameServiceTest",
        priority = 1
    },
    {
        name = "AnalyticsService",
        path = "src.server.test.AnalyticsServiceTest", 
        priority = 2
    },
    {
        name = "UpgradeService",
        path = "src.server.test.UpgradeServiceTest",
        priority = 2
    }
}

-- Test results storage
local testResults = {
    totalSuites = 0,
    passedSuites = 0,
    failedSuites = 0,
    totalTests = 0,
    passedTests = 0,
    failedTests = 0,
    skippedTests = 0,
    executionTime = 0,
    suiteResults = {},
    errors = {}
}

-- Utility functions
local function printHeader(text)
    local border = string.rep("=", 60)
    print(border)
    print("  " .. text)
    print(border)
end

local function printSubHeader(text)
    local border = string.rep("-", 40)
    print(border)
    print("  " .. text)
    print(border)
end

local function formatTime(seconds)
    if seconds < 1 then
        return string.format("%.0f ms", seconds * 1000)
    else
        return string.format("%.2f seconds", seconds)
    end
end

local function loadTestSuite(suitePath)
    local success, suite = pcall(function()
        return SafeRequire.require(ReplicatedStorage[suitePath])
    end)
    
    if not success then
        -- Try alternative path structure
        success, suite = pcall(function()
            local pathParts = string.split(suitePath, ".")
            local current = ReplicatedStorage
            for _, part in ipairs(pathParts) do
                current = current[part]
            end
            return require(current)
        end)
    end
    
    return success, suite
end

-- Run individual test suite
function CriticalSystemsTestRunner.runSuite(suiteInfo)
    local suiteStartTime = tick()
    local suiteResult = {
        name = suiteInfo.name,
        tests = 0,
        passed = 0,
        failed = 0,
        skipped = 0,
        errors = {},
        executionTime = 0
    }
    
    printSubHeader("Testing " .. suiteInfo.name)
    
    -- Load test suite
    local success, suite = loadTestSuite(suiteInfo.path)
    if not success then
        local errorMsg = "Failed to load test suite: " .. suiteInfo.name
        print("❌ " .. errorMsg)
        table.insert(suiteResult.errors, errorMsg)
        suiteResult.failed = 1
        testResults.failedSuites = testResults.failedSuites + 1
        table.insert(testResults.errors, errorMsg)
        return suiteResult
    end
    
    if not suite or type(suite) ~= "table" or not suite.run then
        local errorMsg = "Invalid test suite structure: " .. suiteInfo.name
        print("❌ " .. errorMsg)
        table.insert(suiteResult.errors, errorMsg)
        suiteResult.failed = 1
        testResults.failedSuites = testResults.failedSuites + 1
        table.insert(testResults.errors, errorMsg)
        return suiteResult
    end
    
    -- Run the test suite
    local runSuccess, results = pcall(function()
        return suite:run()
    end)
    
    if not runSuccess then
        local errorMsg = "Test suite execution failed: " .. suiteInfo.name .. " - " .. tostring(results)
        print("❌ " .. errorMsg)
        table.insert(suiteResult.errors, errorMsg)
        suiteResult.failed = 1
        testResults.failedSuites = testResults.failedSuites + 1
        table.insert(testResults.errors, errorMsg)
        return suiteResult
    end
    
    -- Process results
    if results then
        suiteResult.tests = results.totalTests or 0
        suiteResult.passed = results.passedTests or 0
        suiteResult.failed = results.failedTests or 0
        suiteResult.skipped = results.skippedTests or 0
        
        if results.failures then
            for _, failure in ipairs(results.failures) do
                table.insert(suiteResult.errors, failure)
            end
        end
        
        -- Update global counters
        testResults.totalTests = testResults.totalTests + suiteResult.tests
        testResults.passedTests = testResults.passedTests + suiteResult.passed
        testResults.failedTests = testResults.failedTests + suiteResult.failed
        testResults.skippedTests = testResults.skippedTests + suiteResult.skipped
        
        -- Print summary for this suite
        if suiteResult.failed > 0 then
            print(string.format("❌ %s: %d/%d tests passed (%d failed, %d skipped)", 
                suiteInfo.name, suiteResult.passed, suiteResult.tests, suiteResult.failed, suiteResult.skipped))
            testResults.failedSuites = testResults.failedSuites + 1
        else
            print(string.format("✅ %s: %d/%d tests passed (%d skipped)", 
                suiteInfo.name, suiteResult.passed, suiteResult.tests, suiteResult.skipped))
            testResults.passedSuites = testResults.passedSuites + 1
        end
    else
        print("⚠️  " .. suiteInfo.name .. ": No results returned")
        testResults.failedSuites = testResults.failedSuites + 1
    end
    
    suiteResult.executionTime = tick() - suiteStartTime
    print(string.format("   Execution time: %s", formatTime(suiteResult.executionTime)))
    
    return suiteResult
end

-- Run all critical system tests
function CriticalSystemsTestRunner.runAllTests()
    local overallStartTime = tick()
    
    printHeader("CRITICAL SYSTEMS UNIT TEST SUITE")
    print("Testing: TutorialService, MainGameService, AnalyticsService, UpgradeService")
    print("")
    
    -- Initialize counters
    testResults.totalSuites = #testSuites
    testResults.passedSuites = 0
    testResults.failedSuites = 0
    testResults.totalTests = 0
    testResults.passedTests = 0
    testResults.failedTests = 0
    testResults.skippedTests = 0
    testResults.suiteResults = {}
    testResults.errors = {}
    
    -- Sort test suites by priority
    table.sort(testSuites, function(a, b)
        return a.priority < b.priority
    end)
    
    -- Run each test suite
    for i, suiteInfo in ipairs(testSuites) do
        print(string.format("\n[%d/%d] Running %s tests...", i, #testSuites, suiteInfo.name))
        
        local suiteResult = CriticalSystemsTestRunner.runSuite(suiteInfo)
        table.insert(testResults.suiteResults, suiteResult)
        
        -- Brief pause between suites to prevent overwhelming output
        wait(0.1)
    end
    
    testResults.executionTime = tick() - overallStartTime
    
    -- Generate final report
    CriticalSystemsTestRunner.generateReport()
    
    return testResults
end

-- Generate comprehensive test report
function CriticalSystemsTestRunner.generateReport()
    printHeader("CRITICAL SYSTEMS TEST REPORT")
    
    -- Overall summary
    print(string.format("Total Test Suites: %d", testResults.totalSuites))
    print(string.format("✅ Passed Suites: %d", testResults.passedSuites))
    print(string.format("❌ Failed Suites: %d", testResults.failedSuites))
    print("")
    print(string.format("Total Tests: %d", testResults.totalTests))
    print(string.format("✅ Passed Tests: %d", testResults.passedTests))
    print(string.format("❌ Failed Tests: %d", testResults.failedTests))
    print(string.format("⚠️  Skipped Tests: %d", testResults.skippedTests))
    print("")
    print(string.format("Total Execution Time: %s", formatTime(testResults.executionTime)))
    
    -- Success rate calculation
    local successRate = 0
    if testResults.totalTests > 0 then
        successRate = (testResults.passedTests / testResults.totalTests) * 100
    end
    print(string.format("Success Rate: %.1f%%", successRate))
    
    -- Detailed suite breakdown
    if #testResults.suiteResults > 0 then
        printSubHeader("DETAILED SUITE RESULTS")
        
        for _, suite in ipairs(testResults.suiteResults) do
            local status = suite.failed > 0 and "❌" or "✅"
            print(string.format("%s %s:", status, suite.name))
            print(string.format("   Tests: %d passed, %d failed, %d skipped", 
                suite.passed, suite.failed, suite.skipped))
            print(string.format("   Execution Time: %s", formatTime(suite.executionTime)))
            
            if #suite.errors > 0 then
                print("   Errors:")
                for _, error in ipairs(suite.errors) do
                    print("     - " .. error)
                end
            end
            print("")
        end
    end
    
    -- Error summary
    if #testResults.errors > 0 then
        printSubHeader("ERROR SUMMARY")
        for i, error in ipairs(testResults.errors) do
            print(string.format("%d. %s", i, error))
        end
        print("")
    end
    
    -- Final verdict
    if testResults.failedSuites == 0 and testResults.failedTests == 0 then
        printHeader("🎉 ALL CRITICAL SYSTEMS TESTS PASSED! 🎉")
        print("Your critical systems are ready for production!")
    elseif testResults.failedSuites > 0 then
        printHeader("⚠️  CRITICAL SYSTEM FAILURES DETECTED")
        print("Some critical systems have failing tests. Review and fix before deployment.")
    else
        printHeader("✅ CRITICAL SYSTEMS OPERATIONAL")
        print(string.format("Minor issues detected (%d failed tests), but all suites completed.", testResults.failedTests))
    end
end

-- Quick health check function
function CriticalSystemsTestRunner.healthCheck()
    printHeader("CRITICAL SYSTEMS HEALTH CHECK")
    
    local healthStatus = {
        TutorialService = "Unknown",
        MainGameService = "Unknown", 
        AnalyticsService = "Unknown",
        UpgradeService = "Unknown"
    }
    
    -- Quick load test for each service
    for _, suiteInfo in ipairs(testSuites) do
        local success, suite = loadTestSuite(suiteInfo.path)
        if success and suite then
            healthStatus[suiteInfo.name] = "✅ Healthy"
        else
            healthStatus[suiteInfo.name] = "❌ Error"
        end
    end
    
    -- Print health status
    for serviceName, status in pairs(healthStatus) do
        print(string.format("%s: %s", serviceName, status))
    end
    
    return healthStatus
end

-- Export the test runner
return CriticalSystemsTestRunner
