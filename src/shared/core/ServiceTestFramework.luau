-- ServiceTestFramework.luau
-- Comprehensive testing framework for service architecture
-- Handles unit tests, integration tests, mocking, and test reporting

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local HttpService = game:GetService("HttpService")

local ServiceTestFramework = {}

-- ========================================
-- TEST REGISTRY
-- ========================================

local TEST_REGISTRY = {}
local TEST_SUITES = {}
local MOCK_REGISTRY = {}
local TEST_RESULTS = {}
local TEST_HOOKS = {}

-- Test status enum
local TestStatus = {
    PENDING = "PENDING",
    RUNNING = "RUNNING",
    PASSED = "PASSED",
    FAILED = "FAILED",
    SKIPPED = "SKIPPED",
    TIMEOUT = "TIMEOUT"
}

-- ========================================
-- TEST SUITE CREATION
-- ========================================

function ServiceTestFramework:CreateTestSuite(suiteName, options)
    options = options or {}
    
    local suite = {
        name = suiteName,
        description = options.description or "",
        tests = {},
        hooks = {
            beforeAll = {},
            afterAll = {},
            beforeEach = {},
            afterEach = {}
        },
        timeout = options.timeout or 30,
        retries = options.retries or 0,
        parallel = options.parallel or false,
        tags = options.tags or {},
        createdAt = tick()
    }
    
    TEST_SUITES[suiteName] = suite
    print("📋 Created test suite: " .. suiteName)
    
    return suite
end

function ServiceTestFramework:AddTest(suiteName, testName, testFunction, options)
    options = options or {}
    
    local suite = TEST_SUITES[suiteName]
    if not suite then
        error("❌ Test suite not found: " .. suiteName)
    end
    
    local test = {
        name = testName,
        description = options.description or "",
        function = testFunction,
        timeout = options.timeout or suite.timeout,
        retries = options.retries or suite.retries,
        skip = options.skip or false,
        tags = options.tags or {},
        dependencies = options.dependencies or {},
        createdAt = tick()
    }
    
    suite.tests[testName] = test
    
    -- Add to global registry
    local testId = suiteName .. ":" .. testName
    TEST_REGISTRY[testId] = test
    
    print("✅ Added test: " .. testId)
end

-- ========================================
-- TEST HOOKS
-- ========================================

function ServiceTestFramework:AddHook(suiteName, hookType, hookFunction)
    local suite = TEST_SUITES[suiteName]
    if not suite then
        error("❌ Test suite not found: " .. suiteName)
    end
    
    if not suite.hooks[hookType] then
        error("❌ Invalid hook type: " .. hookType)
    end
    
    table.insert(suite.hooks[hookType], hookFunction)
    print("🪝 Added " .. hookType .. " hook to suite: " .. suiteName)
end

-- ========================================
-- ASSERTION FRAMEWORK
-- ========================================

local Assertions = {}

function Assertions.assertEqual(actual, expected, message)
    if actual ~= expected then
        local errorMsg = message or ("Expected " .. tostring(expected) .. " but got " .. tostring(actual))
        error("❌ Assertion failed: " .. errorMsg)
    end
end

function Assertions.assertNotEqual(actual, expected, message)
    if actual == expected then
        local errorMsg = message or ("Expected values to be different but both were " .. tostring(actual))
        error("❌ Assertion failed: " .. errorMsg)
    end
end

function Assertions.assertTrue(value, message)
    if not value then
        local errorMsg = message or ("Expected true but got " .. tostring(value))
        error("❌ Assertion failed: " .. errorMsg)
    end
end

function Assertions.assertFalse(value, message)
    if value then
        local errorMsg = message or ("Expected false but got " .. tostring(value))
        error("❌ Assertion failed: " .. errorMsg)
    end
end

function Assertions.assertNil(value, message)
    if value ~= nil then
        local errorMsg = message or ("Expected nil but got " .. tostring(value))
        error("❌ Assertion failed: " .. errorMsg)
    end
end

function Assertions.assertNotNil(value, message)
    if value == nil then
        local errorMsg = message or "Expected non-nil value but got nil"
        error("❌ Assertion failed: " .. errorMsg)
    end
end

function Assertions.assertType(value, expectedType, message)
    local actualType = type(value)
    if actualType ~= expectedType then
        local errorMsg = message or ("Expected type " .. expectedType .. " but got " .. actualType)
        error("❌ Assertion failed: " .. errorMsg)
    end
end

function Assertions.assertThrows(func, expectedError, message)
    local success, actualError = pcall(func)
    if success then
        local errorMsg = message or "Expected function to throw an error but it succeeded"
        error("❌ Assertion failed: " .. errorMsg)
    end
    
    if expectedError and not string.find(actualError, expectedError) then
        local errorMsg = message or ("Expected error containing '" .. expectedError .. "' but got '" .. actualError .. "'")
        error("❌ Assertion failed: " .. errorMsg)
    end
end

function Assertions.assertNoThrow(func, message)
    local success, error = pcall(func)
    if not success then
        local errorMsg = message or ("Expected function not to throw but got error: " .. error)
        error("❌ Assertion failed: " .. errorMsg)
    end
end

function Assertions.assertTableEqual(actual, expected, message)
    local function tablesEqual(t1, t2)
        if type(t1) ~= "table" or type(t2) ~= "table" then
            return t1 == t2
        end
        
        for k, v in pairs(t1) do
            if not tablesEqual(v, t2[k]) then
                return false
            end
        end
        
        for k, v in pairs(t2) do
            if not tablesEqual(v, t1[k]) then
                return false
            end
        end
        
        return true
    end
    
    if not tablesEqual(actual, expected) then
        local errorMsg = message or "Tables are not equal"
        error("❌ Assertion failed: " .. errorMsg)
    end
end

ServiceTestFramework.Assert = Assertions

-- ========================================
-- MOCK SYSTEM
-- ========================================

function ServiceTestFramework:CreateMock(originalObject, mockName)
    mockName = mockName or "MockObject"
    
    local mock = {
        _mockName = mockName,
        _originalObject = originalObject,
        _mockData = {},
        _callHistory = {},
        _returnValues = {},
        _throwErrors = {},
        _callCounts = {}
    }
    
    -- Create mock methods for all original methods
    if originalObject then
        for key, value in pairs(originalObject) do
            if type(value) == "function" then
                mock[key] = function(self, ...)
                    local args = {...}
                    local callInfo = {
                        method = key,
                        args = args,
                        timestamp = tick()
                    }
                    
                    table.insert(mock._callHistory, callInfo)
                    mock._callCounts[key] = (mock._callCounts[key] or 0) + 1
                    
                    -- Check if should throw error
                    if mock._throwErrors[key] then
                        error(mock._throwErrors[key])
                    end
                    
                    -- Return mocked value if set
                    if mock._returnValues[key] ~= nil then
                        return mock._returnValues[key]
                    end
                    
                    -- Call original if no mock set
                    if originalObject and originalObject[key] then
                        return originalObject[key](originalObject, ...)
                    end
                end
            else
                mock[key] = value
            end
        end
    end
    
    -- Mock control methods
    function mock:SetReturnValue(method, value)
        self._returnValues[method] = value
    end
    
    function mock:SetThrowError(method, error)
        self._throwErrors[method] = error
    end
    
    function mock:GetCallCount(method)
        return self._callCounts[method] or 0
    end
    
    function mock:GetCallHistory(method)
        if method then
            local methodCalls = {}
            for _, call in ipairs(self._callHistory) do
                if call.method == method then
                    table.insert(methodCalls, call)
                end
            end
            return methodCalls
        else
            return self._callHistory
        end
    end
    
    function mock:WasCalledWith(method, ...)
        local expectedArgs = {...}
        local calls = self:GetCallHistory(method)
        
        for _, call in ipairs(calls) do
            local argsMatch = true
            for i, expectedArg in ipairs(expectedArgs) do
                if call.args[i] ~= expectedArg then
                    argsMatch = false
                    break
                end
            end
            if argsMatch then
                return true
            end
        end
        
        return false
    end
    
    function mock:Reset()
        self._callHistory = {}
        self._returnValues = {}
        self._throwErrors = {}
        self._callCounts = {}
    end
    
    MOCK_REGISTRY[mockName] = mock
    return mock
end

function ServiceTestFramework:CreateSpy(originalFunction, spyName)
    spyName = spyName or "SpyFunction"
    
    local spy = {
        _spyName = spyName,
        _originalFunction = originalFunction,
        _callHistory = {},
        _callCount = 0
    }
    
    local spyFunction = function(...)
        local args = {...}
        local callInfo = {
            args = args,
            timestamp = tick()
        }
        
        table.insert(spy._callHistory, callInfo)
        spy._callCount = spy._callCount + 1
        
        if originalFunction then
            return originalFunction(...)
        end
    end
    
    -- Add spy methods
    spyFunction.GetCallCount = function()
        return spy._callCount
    end
    
    spyFunction.GetCallHistory = function()
        return spy._callHistory
    end
    
    spyFunction.WasCalledWith = function(...)
        local expectedArgs = {...}
        for _, call in ipairs(spy._callHistory) do
            local argsMatch = true
            for i, expectedArg in ipairs(expectedArgs) do
                if call.args[i] ~= expectedArg then
                    argsMatch = false
                    break
                end
            end
            if argsMatch then
                return true
            end
        end
        return false
    end
    
    spyFunction.Reset = function()
        spy._callHistory = {}
        spy._callCount = 0
    end
    
    return spyFunction
end

-- ========================================
-- TEST EXECUTION
-- ========================================

function ServiceTestFramework:RunTest(suiteName, testName)
    local suite = TEST_SUITES[suiteName]
    if not suite then
        error("❌ Test suite not found: " .. suiteName)
    end
    
    local test = suite.tests[testName]
    if not test then
        error("❌ Test not found: " .. testName)
    end
    
    local testId = suiteName .. ":" .. testName
    local result = {
        testId = testId,
        suiteName = suiteName,
        testName = testName,
        status = TestStatus.PENDING,
        startTime = nil,
        endTime = nil,
        duration = 0,
        error = nil,
        retryCount = 0,
        output = {}
    }
    
    TEST_RESULTS[testId] = result
    
    -- Check if test should be skipped
    if test.skip then
        result.status = TestStatus.SKIPPED
        result.startTime = tick()
        result.endTime = tick()
        print("⏭️ Skipped test: " .. testId)
        return result
    end
    
    -- Check dependencies
    for _, dependency in ipairs(test.dependencies) do
        local depResult = TEST_RESULTS[dependency]
        if not depResult or depResult.status ~= TestStatus.PASSED then
            result.status = TestStatus.SKIPPED
            result.error = "Dependency not satisfied: " .. dependency
            print("⏭️ Skipped test due to dependency: " .. testId)
            return result
        end
    end
    
    -- Run test with retries
    local maxRetries = test.retries
    local attempt = 0
    
    while attempt <= maxRetries do
        attempt = attempt + 1
        result.retryCount = attempt - 1
        result.status = TestStatus.RUNNING
        result.startTime = tick()
        
        print("🧪 Running test: " .. testId .. (attempt > 1 and (" (retry " .. (attempt - 1) .. ")") or ""))
        
        -- Run beforeEach hooks
        for _, hook in ipairs(suite.hooks.beforeEach) do
            pcall(hook)
        end
        
        -- Execute test with timeout
        local success, error = self:ExecuteWithTimeout(test.function, test.timeout)
        
        result.endTime = tick()
        result.duration = result.endTime - result.startTime
        
        if success then
            result.status = TestStatus.PASSED
            result.error = nil
            print("✅ Test passed: " .. testId)
            
            -- Run afterEach hooks
            for _, hook in ipairs(suite.hooks.afterEach) do
                pcall(hook)
            end
            
            break
        else
            result.status = TestStatus.FAILED
            result.error = error
            
            if attempt <= maxRetries then
                print("🔄 Test failed, retrying: " .. testId)
                wait(0.1) -- Brief delay before retry
            else
                print("❌ Test failed: " .. testId .. " - " .. tostring(error))
            end
            
            -- Run afterEach hooks
            for _, hook in ipairs(suite.hooks.afterEach) do
                pcall(hook)
            end
        end
    end
    
    return result
end

function ServiceTestFramework:RunTestSuite(suiteName)
    local suite = TEST_SUITES[suiteName]
    if not suite then
        error("❌ Test suite not found: " .. suiteName)
    end
    
    print("🧪 Running test suite: " .. suiteName)
    
    -- Run beforeAll hooks
    for _, hook in ipairs(suite.hooks.beforeAll) do
        pcall(hook)
    end
    
    local suiteResults = {
        suiteName = suiteName,
        startTime = tick(),
        endTime = nil,
        duration = 0,
        totalTests = 0,
        passedTests = 0,
        failedTests = 0,
        skippedTests = 0,
        testResults = {}
    }
    
    -- Count tests
    for _ in pairs(suite.tests) do
        suiteResults.totalTests = suiteResults.totalTests + 1
    end
    
    -- Run tests
    if suite.parallel then
        -- Run tests in parallel (simplified for this example)
        for testName, _ in pairs(suite.tests) do
            local result = self:RunTest(suiteName, testName)
            table.insert(suiteResults.testResults, result)
            
            if result.status == TestStatus.PASSED then
                suiteResults.passedTests = suiteResults.passedTests + 1
            elseif result.status == TestStatus.FAILED then
                suiteResults.failedTests = suiteResults.failedTests + 1
            elseif result.status == TestStatus.SKIPPED then
                suiteResults.skippedTests = suiteResults.skippedTests + 1
            end
        end
    else
        -- Run tests sequentially
        for testName, _ in pairs(suite.tests) do
            local result = self:RunTest(suiteName, testName)
            table.insert(suiteResults.testResults, result)
            
            if result.status == TestStatus.PASSED then
                suiteResults.passedTests = suiteResults.passedTests + 1
            elseif result.status == TestStatus.FAILED then
                suiteResults.failedTests = suiteResults.failedTests + 1
            elseif result.status == TestStatus.SKIPPED then
                suiteResults.skippedTests = suiteResults.skippedTests + 1
            end
        end
    end
    
    suiteResults.endTime = tick()
    suiteResults.duration = suiteResults.endTime - suiteResults.startTime
    
    -- Run afterAll hooks
    for _, hook in ipairs(suite.hooks.afterAll) do
        pcall(hook)
    end
    
    self:PrintSuiteResults(suiteResults)
    return suiteResults
end

function ServiceTestFramework:RunAllTests()
    print("🧪 Running all test suites...")
    
    local allResults = {
        startTime = tick(),
        endTime = nil,
        duration = 0,
        totalSuites = 0,
        totalTests = 0,
        passedTests = 0,
        failedTests = 0,
        skippedTests = 0,
        suiteResults = {}
    }
    
    for suiteName, _ in pairs(TEST_SUITES) do
        allResults.totalSuites = allResults.totalSuites + 1
        local suiteResult = self:RunTestSuite(suiteName)
        table.insert(allResults.suiteResults, suiteResult)
        
        allResults.totalTests = allResults.totalTests + suiteResult.totalTests
        allResults.passedTests = allResults.passedTests + suiteResult.passedTests
        allResults.failedTests = allResults.failedTests + suiteResult.failedTests
        allResults.skippedTests = allResults.skippedTests + suiteResult.skippedTests
    end
    
    allResults.endTime = tick()
    allResults.duration = allResults.endTime - allResults.startTime
    
    self:PrintOverallResults(allResults)
    return allResults
end

-- ========================================
-- UTILITY FUNCTIONS
-- ========================================

function ServiceTestFramework:ExecuteWithTimeout(func, timeout)
    local completed = false
    local success, result
    
    spawn(function()
        success, result = pcall(func)
        completed = true
    end)
    
    local startTime = tick()
    while not completed and (tick() - startTime) < timeout do
        wait(0.1)
    end
    
    if not completed then
        return false, "Test timed out after " .. timeout .. " seconds"
    end
    
    return success, result
end

function ServiceTestFramework:PrintSuiteResults(suiteResults)
    print("\n" .. "=".rep(50))
    print("📊 TEST SUITE RESULTS: " .. suiteResults.suiteName)
    print("=".rep(50))
    print("Total Tests: " .. suiteResults.totalTests)
    print("✅ Passed: " .. suiteResults.passedTests)
    print("❌ Failed: " .. suiteResults.failedTests)
    print("⏭️ Skipped: " .. suiteResults.skippedTests)
    print("⏱️ Duration: " .. string.format("%.2f", suiteResults.duration) .. "s")
    
    if suiteResults.failedTests > 0 then
        print("\n❌ Failed Tests:")
        for _, result in ipairs(suiteResults.testResults) do
            if result.status == TestStatus.FAILED then
                print("  - " .. result.testName .. ": " .. (result.error or "Unknown error"))
            end
        end
    end
    
    print("=".rep(50) .. "\n")
end

function ServiceTestFramework:PrintOverallResults(allResults)
    print("\n" .. "=".rep(60))
    print("📊 OVERALL TEST RESULTS")
    print("=".rep(60))
    print("Total Suites: " .. allResults.totalSuites)
    print("Total Tests: " .. allResults.totalTests)
    print("✅ Passed: " .. allResults.passedTests)
    print("❌ Failed: " .. allResults.failedTests)
    print("⏭️ Skipped: " .. allResults.skippedTests)
    print("⏱️ Total Duration: " .. string.format("%.2f", allResults.duration) .. "s")
    
    local successRate = allResults.totalTests > 0 and (allResults.passedTests / allResults.totalTests * 100) or 0
    print("📈 Success Rate: " .. string.format("%.1f", successRate) .. "%")
    
    if allResults.failedTests > 0 then
        print("\n❌ Failed Test Summary:")
        for _, suiteResult in ipairs(allResults.suiteResults) do
            for _, testResult in ipairs(suiteResult.testResults) do
                if testResult.status == TestStatus.FAILED then
                    print("  - " .. testResult.testId .. ": " .. (testResult.error or "Unknown error"))
                end
            end
        end
    end
    
    print("=".rep(60) .. "\n")
end

function ServiceTestFramework:GetTestResults(testId)
    if testId then
        return TEST_RESULTS[testId]
    else
        return TEST_RESULTS
    end
end

function ServiceTestFramework:ClearResults()
    TEST_RESULTS = {}
    print("🧹 Cleared all test results")
end

function ServiceTestFramework:ExportResults(format)
    format = format or "json"
    
    local exportData = {
        testResults = TEST_RESULTS,
        testSuites = TEST_SUITES,
        exportedAt = tick(),
        format = format
    }
    
    if format == "json" then
        return HttpService:JSONEncode(exportData)
    else
        return exportData
    end
end

return ServiceTestFramework
