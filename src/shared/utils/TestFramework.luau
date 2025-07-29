-- TestFramework.luau
-- Comprehensive unit testing framework for RobloxMain

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local TestFramework = {}

-- Test Suite Registry
local testSuites = {}
local activeTestSuite = nil

-- Test Results Tracking
local TestResults = {
    suites = {},
    totalPassed = 0,
    totalFailed = 0,
    totalSkipped = 0,
    totalTests = 0,
    startTime = 0,
    endTime = 0
}

-- Test Utilities
local TestUtils = {}

/**
 * Assertion utilities for comprehensive testing
 */
function TestUtils.assertEqual(actual, expected, message)
    local success = actual == expected
    local details = message or string.format("Expected %s, got %s", tostring(expected), tostring(actual))
    return success, details
end

function TestUtils.assertNotEqual(actual, expected, message)
    local success = actual ~= expected
    local details = message or string.format("Expected not %s, but got %s", tostring(expected), tostring(actual))
    return success, details
end

function TestUtils.assertTrue(condition, message)
    local success = condition == true
    local details = message or "Expected true, got false"
    return success, details
end

function TestUtils.assertFalse(condition, message)
    local success = condition == false
    local details = message or "Expected false, got true"
    return success, details
end

function TestUtils.assertType(value, expectedType, message)
    local actualType = type(value)
    local success = actualType == expectedType
    local details = message or string.format("Expected type %s, got %s", expectedType, actualType)
    return success, details
end

function TestUtils.assertNotNil(value, message)
    local success = value ~= nil
    local details = message or "Expected non-nil value, got nil"
    return success, details
end

function TestUtils.assertNil(value, message)
    local success = value == nil
    local details = message or "Expected nil value, got " .. tostring(value)
    return success, details
end

function TestUtils.assertTableContains(table, key, message)
    local success = table and table[key] ~= nil
    local details = message or string.format("Table does not contain key: %s", tostring(key))
    return success, details
end

function TestUtils.assertFunctionExists(object, functionName, message)
    local success = object and type(object[functionName]) == "function"
    local details = message or string.format("Function %s does not exist or is not callable", functionName)
    return success, details
end

function TestUtils.assertRemoteEventExists(eventName, message)
    local remoteEventsFolder = ReplicatedStorage:FindFirstChild("RemoteEvents")
    local event = remoteEventsFolder and remoteEventsFolder:FindFirstChild(eventName)
    local success = event ~= nil and event:IsA("RemoteEvent")
    local details = message or string.format("RemoteEvent %s does not exist", eventName)
    return success, details
end

function TestUtils.assertServiceExists(servicePath, message)
    local success, service = pcall(function()
        return require(servicePath)
    end)
    local details = message or string.format("Service at %s could not be loaded", tostring(servicePath))
    return success and service ~= nil, details
end

function TestUtils.assertWorldObjectExists(objectName, parent, message)
    parent = parent or workspace
    local object = parent:FindFirstChild(objectName)
    local success = object ~= nil
    local details = message or string.format("World object %s not found in %s", objectName, parent.Name)
    return success, details
end

-- Mock utilities for testing
function TestUtils.createMockPlayer(userId, name)
    local mockPlayer = {
        UserId = userId or 123456789,
        Name = name or "TestPlayer",
        DisplayName = name or "TestPlayer",
        Parent = Players,
        IsA = function(self, className)
            return className == "Player"
        end,
        WaitForChild = function(self, childName)
            return Instance.new("Folder")
        end,
        FindFirstChild = function(self, childName)
            return Instance.new("Folder")
        end
    }
    return mockPlayer
end

function TestUtils.createMockDataStore()
    local dataStore = {}
    local data = {}
    
    function dataStore:GetAsync(key)
        return data[key]
    end
    
    function dataStore:SetAsync(key, value)
        data[key] = value
        return true
    end
    
    function dataStore:UpdateAsync(key, transformFunction)
        local currentValue = data[key]
        local newValue = transformFunction(currentValue)
        data[key] = newValue
        return newValue
    end
    
    return dataStore
end

function TestUtils.createMockService(serviceName, methods)
    local mockService = {
        Name = serviceName,
        _isMock = true
    }
    
    -- Add provided methods
    for methodName, methodFunc in pairs(methods or {}) do
        mockService[methodName] = methodFunc
    end
    
    return mockService
end

-- Wait utilities for async testing
function TestUtils.waitForCondition(condition, timeout, interval)
    timeout = timeout or 5
    interval = interval or 0.1
    local startTime = tick()
    
    while tick() - startTime < timeout do
        if condition() then
            return true
        end
        wait(interval)
    end
    
    return false
end

function TestUtils.waitForEvent(event, timeout)
    timeout = timeout or 5
    local fired = false
    local connection
    
    connection = event:Connect(function()
        fired = true
        connection:Disconnect()
    end)
    
    local success = TestUtils.waitForCondition(function()
        return fired
    end, timeout)
    
    if not success then
        connection:Disconnect()
    end
    
    return success
end

-- Test Suite Class
local TestSuite = {}
TestSuite.__index = TestSuite

/**
 * Create a new test suite
 * @param {string} name - Name of the test suite
 * @return {TestSuite} Test suite instance
 */
function TestSuite.new(name)
    local suite = {
        name = name,
        tests = {},
        beforeEach = nil,
        afterEach = nil,
        beforeAll = nil,
        afterAll = nil,
        results = {
            passed = 0,
            failed = 0,
            skipped = 0,
            total = 0,
            details = {}
        }
    }
    setmetatable(suite, TestSuite)
    return suite
end

/**
 * Add a test to the suite
 * @param {string} testName - Name of the test
 * @param {function} testFunction - Test function to run
 */
function TestSuite:addTest(testName, testFunction)
    table.insert(self.tests, {
        name = testName,
        func = testFunction,
        skip = false
    })
end

/**
 * Skip a test
 * @param {string} testName - Name of the test to skip
 * @param {function} testFunction - Test function (will not be run)
 */
function TestSuite:skipTest(testName, testFunction)
    table.insert(self.tests, {
        name = testName,
        func = testFunction,
        skip = true
    })
end

/**
 * Set up function to run before each test
 * @param {function} setupFunction - Function to run before each test
 */
function TestSuite:setBeforeEach(setupFunction)
    self.beforeEach = setupFunction
end

/**
 * Set up function to run after each test
 * @param {function} teardownFunction - Function to run after each test
 */
function TestSuite:setAfterEach(teardownFunction)
    self.afterEach = teardownFunction
end

/**
 * Set up function to run before all tests
 * @param {function} setupFunction - Function to run before all tests
 */
function TestSuite:setBeforeAll(setupFunction)
    self.beforeAll = setupFunction
end

/**
 * Set up function to run after all tests
 * @param {function} teardownFunction - Function to run after all tests
 */
function TestSuite:setAfterAll(teardownFunction)
    self.afterAll = teardownFunction
end

/**
 * Run all tests in the suite
 * @return {table} Test results
 */
function TestSuite:run()
    print(string.format("🧪 Running Test Suite: %s", self.name))
    print(string.rep("=", 50))
    
    -- Run beforeAll if exists
    if self.beforeAll then
        local success, error = pcall(self.beforeAll)
        if not success then
            print(string.format("❌ BeforeAll failed: %s", error))
            return self.results
        end
    end
    
    for _, test in ipairs(self.tests) do
        self.results.total = self.results.total + 1
        
        if test.skip then
            self.results.skipped = self.results.skipped + 1
            print(string.format("⏭️  %s - SKIPPED", test.name))
            table.insert(self.results.details, {
                name = test.name,
                status = "skipped",
                details = "Test skipped"
            })
        else
            -- Run beforeEach if exists
            if self.beforeEach then
                pcall(self.beforeEach)
            end
            
            -- Run the test
            local success, result = pcall(test.func)
            
            if success then
                self.results.passed = self.results.passed + 1
                print(string.format("✅ %s - PASSED", test.name))
                table.insert(self.results.details, {
                    name = test.name,
                    status = "passed",
                    details = result or "Test passed"
                })
            else
                self.results.failed = self.results.failed + 1
                print(string.format("❌ %s - FAILED: %s", test.name, result))
                table.insert(self.results.details, {
                    name = test.name,
                    status = "failed",
                    details = result or "Unknown error"
                })
            end
            
            -- Run afterEach if exists
            if self.afterEach then
                pcall(self.afterEach)
            end
        end
    end
    
    -- Run afterAll if exists
    if self.afterAll then
        pcall(self.afterAll)
    end
    
    -- Print suite summary
    print(string.rep("=", 50))
    print(string.format("📊 %s Results:", self.name))
    print(string.format("   Total: %d | Passed: %d | Failed: %d | Skipped: %d", 
        self.results.total, self.results.passed, self.results.failed, self.results.skipped))
    
    return self.results
end

-- Main TestFramework Functions

/**
 * Create and register a new test suite
 * @param {string} name - Name of the test suite
 * @return {TestSuite} Test suite instance
 */
function TestFramework.createSuite(name)
    local suite = TestSuite.new(name)
    table.insert(testSuites, suite)
    activeTestSuite = suite
    return suite
end

/**
 * Get the currently active test suite
 * @return {TestSuite} Current test suite
 */
function TestFramework.getCurrentSuite()
    return activeTestSuite
end

/**
 * Run a specific test suite by name
 * @param {string} suiteName - Name of the suite to run
 * @return {table} Test results
 */
function TestFramework.runSuite(suiteName)
    for _, suite in ipairs(testSuites) do
        if suite.name == suiteName then
            local results = suite:run()
            TestResults.suites[suiteName] = results
            return results
        end
    end
    
    error("Test suite '" .. suiteName .. "' not found")
end

/**
 * Run all registered test suites
 * @return {table} Combined test results
 */
function TestFramework.runAllSuites()
    print("🚀 Starting Comprehensive Unit Tests")
    print(string.rep("=", 60))
    
    TestResults.startTime = tick()
    TestResults.totalPassed = 0
    TestResults.totalFailed = 0
    TestResults.totalSkipped = 0
    TestResults.totalTests = 0
    
    for _, suite in ipairs(testSuites) do
        local results = suite:run()
        TestResults.suites[suite.name] = results
        TestResults.totalPassed = TestResults.totalPassed + results.passed
        TestResults.totalFailed = TestResults.totalFailed + results.failed
        TestResults.totalSkipped = TestResults.totalSkipped + results.skipped
        TestResults.totalTests = TestResults.totalTests + results.total
        print() -- Add spacing between suites
    end
    
    TestResults.endTime = tick()
    
    -- Print comprehensive summary
    print(string.rep("=", 60))
    print("🎯 COMPREHENSIVE TEST RESULTS")
    print(string.rep("=", 60))
    print(string.format("Total Test Suites: %d", #testSuites))
    print(string.format("Total Tests: %d", TestResults.totalTests))
    print(string.format("Passed: %d (%.1f%%)", TestResults.totalPassed, 
        TestResults.totalTests > 0 and (TestResults.totalPassed/TestResults.totalTests)*100 or 0))
    print(string.format("Failed: %d (%.1f%%)", TestResults.totalFailed,
        TestResults.totalTests > 0 and (TestResults.totalFailed/TestResults.totalTests)*100 or 0))
    print(string.format("Skipped: %d (%.1f%%)", TestResults.totalSkipped,
        TestResults.totalTests > 0 and (TestResults.totalSkipped/TestResults.totalTests)*100 or 0))
    print(string.format("Execution Time: %.2f seconds", TestResults.endTime - TestResults.startTime))
    
    -- Print failed tests summary
    if TestResults.totalFailed > 0 then
        print("\n❌ FAILED TESTS SUMMARY:")
        for suiteName, suiteResults in pairs(TestResults.suites) do
            for _, test in ipairs(suiteResults.details) do
                if test.status == "failed" then
                    print(string.format("   • %s -> %s: %s", suiteName, test.name, test.details))
                end
            end
        end
    end
    
    -- Overall status
    if TestResults.totalFailed == 0 then
        print("\n🎉 ALL TESTS PASSED! System ready for production.")
    elseif TestResults.totalFailed <= 3 then
        print("\n⚠️  Minor issues found. Review failed tests.")
    else
        print("\n🚨 Multiple issues found. Address critical failures before proceeding.")
    end
    
    print(string.rep("=", 60))
    
    return TestResults
end

-- Export utilities
TestFramework.Utils = TestUtils
TestFramework.TestSuite = TestSuite

return TestFramework
