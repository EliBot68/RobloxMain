-- UnitTestFramework.luau
-- Comprehensive unit testing framework with test coverage reporting
-- Provides structured testing capabilities with assertions, mocking, and detailed reporting

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local HttpService = game:GetService("HttpService")

local SafeRequire = require(ReplicatedStorage.Shared.utils.SafeRequire)

local UnitTestFramework = {}

-- ========================================
-- TESTING FRAMEWORK CONFIGURATION
-- ========================================

local TEST_CONFIG = {
    -- Test execution settings
    execution = {
        enableParallelExecution = true,
        maxConcurrentTests = 5,
        testTimeout = 30000,             -- 30 seconds
        enableTestIsolation = true,
        enableAsyncTesting = true,
        retryFailedTests = 1
    },
    
    -- Coverage reporting
    coverage = {
        enableCoverageTracking = true,
        enableBranchCoverage = true,
        enableFunctionCoverage = true,
        enableLineCoverage = true,
        coverageThreshold = 80,          -- 80% minimum coverage
        excludePatterns = {"test_", "mock_", "debug_"}
    },
    
    -- Assertion configuration
    assertions = {
        enableStrictMode = true,
        enableCustomMatchers = true,
        enableAsyncAssertions = true,
        floatTolerance = 0.0001
    },
    
    -- Reporting settings
    reporting = {
        enableDetailedReports = true,
        enableConsoleOutput = true,
        enableFileOutput = true,
        enableMetrics = true,
        reportFormat = "detailed"        -- "simple", "detailed", "json"
    }
}

-- ========================================
-- TESTING FRAMEWORK STATE
-- ========================================

local TestState = {
    -- Test registry
    testSuites = {},
    testCases = {},
    testHooks = {
        beforeAll = {},
        afterAll = {},
        beforeEach = {},
        afterEach = {}
    },
    
    -- Test execution
    currentSuite = nil,
    currentTest = nil,
    testResults = {},
    executionStats = {},
    
    -- Coverage tracking
    coverageData = {},
    sourceFiles = {},
    instrumentedCode = {},
    
    -- Mocking system
    mocks = {},
    spies = {},
    stubs = {},
    
    -- Async testing
    pendingTests = {},
    asyncCallbacks = {},
    
    -- Framework state
    isRunning = false,
    testQueue = {},
    
    -- Statistics
    stats = {
        totalTests = 0,
        passedTests = 0,
        failedTests = 0,
        skippedTests = 0,
        totalSuites = 0,
        executionTime = 0,
        coveragePercentage = 0
    }
}

function UnitTestFramework.initialize()
    print("🧪 Initializing UnitTestFramework...")
    
    -- Initialize test registry
    UnitTestFramework.initializeTestRegistry()
    
    -- Set up coverage tracking
    UnitTestFramework.setupCoverageTracking()
    
    -- Initialize assertion library
    UnitTestFramework.initializeAssertions()
    
    -- Set up mocking system
    UnitTestFramework.initializeMockingSystem()
    
    -- Initialize async testing support
    UnitTestFramework.initializeAsyncTesting()
    
    print("🧪 UnitTestFramework initialized successfully")
end

-- ========================================
-- TEST REGISTRY AND ORGANIZATION
-- ========================================

function UnitTestFramework.initializeTestRegistry()
    TestState.testSuites = {}
    TestState.testCases = {}
    
    print("📋 Test registry initialized")
end

function UnitTestFramework.describe(suiteName, testFunction)
    local suite = {
        name = suiteName,
        tests = {},
        hooks = {
            beforeAll = {},
            afterAll = {},
            beforeEach = {},
            afterEach = {}
        },
        stats = {
            total = 0,
            passed = 0,
            failed = 0,
            skipped = 0
        }
    }
    
    TestState.testSuites[suiteName] = suite
    TestState.currentSuite = suite
    TestState.stats.totalSuites = TestState.stats.totalSuites + 1
    
    -- Execute the test function to register tests
    if testFunction then
        local success, error = pcall(testFunction)
        if not success then
            warn(string.format("Error in test suite '%s': %s", suiteName, error))
        end
    end
    
    TestState.currentSuite = nil
    
    print(string.format("📋 Test suite registered: %s (%d tests)", suiteName, #suite.tests))
    return suite
end

function UnitTestFramework.it(testName, testFunction, options)
    if not TestState.currentSuite then
        error("Test case must be defined within a test suite (describe block)")
    end
    
    options = options or {}
    
    local testCase = {
        name = testName,
        func = testFunction,
        suite = TestState.currentSuite.name,
        skip = options.skip or false,
        only = options.only or false,
        timeout = options.timeout or TEST_CONFIG.execution.testTimeout,
        async = options.async or false,
        retries = options.retries or TEST_CONFIG.execution.retryFailedTests
    }
    
    table.insert(TestState.currentSuite.tests, testCase)
    TestState.testCases[testName] = testCase
    TestState.stats.totalTests = TestState.stats.totalTests + 1
    
    return testCase
end

function UnitTestFramework.beforeAll(hookFunction)
    if TestState.currentSuite then
        table.insert(TestState.currentSuite.hooks.beforeAll, hookFunction)
    else
        table.insert(TestState.testHooks.beforeAll, hookFunction)
    end
end

function UnitTestFramework.afterAll(hookFunction)
    if TestState.currentSuite then
        table.insert(TestState.currentSuite.hooks.afterAll, hookFunction)
    else
        table.insert(TestState.testHooks.afterAll, hookFunction)
    end
end

function UnitTestFramework.beforeEach(hookFunction)
    if TestState.currentSuite then
        table.insert(TestState.currentSuite.hooks.beforeEach, hookFunction)
    else
        table.insert(TestState.testHooks.beforeEach, hookFunction)
    end
end

function UnitTestFramework.afterEach(hookFunction)
    if TestState.currentSuite then
        table.insert(TestState.currentSuite.hooks.afterEach, hookFunction)
    else
        table.insert(TestState.testHooks.afterEach, hookFunction)
    end
end

-- ========================================
-- ASSERTION LIBRARY
-- ========================================

function UnitTestFramework.initializeAssertions()
    UnitTestFramework.expect = UnitTestFramework.createExpectFunction()
    
    print("✓ Assertion library initialized")
end

function UnitTestFramework.createExpectFunction()
    local function expect(actual)
        local expectation = {
            actual = actual,
            not = false
        }
        
        -- Create "not" modifier
        local notExpectation = setmetatable({}, {
            __index = function(_, key)
                if expectation[key] then
                    return function(...)
                        expectation.not = true
                        return expectation[key](...)
                    end
                end
            end
        })
        
        expectation.not = notExpectation
        
        -- Assertion methods
        function expectation.toBe(expected)
            local result = expectation.actual == expected
            if expectation.not then result = not result end
            
            if not result then
                UnitTestFramework.throwAssertionError(
                    expectation.not and "Expected values not to be equal" or "Expected values to be equal",
                    expected,
                    expectation.actual
                )
            end
        end
        
        function expectation.toEqual(expected)
            local result = UnitTestFramework.deepEqual(expectation.actual, expected)
            if expectation.not then result = not result end
            
            if not result then
                UnitTestFramework.throwAssertionError(
                    expectation.not and "Expected values not to be deeply equal" or "Expected values to be deeply equal",
                    expected,
                    expectation.actual
                )
            end
        end
        
        function expectation.toBeCloseTo(expected, precision)
            precision = precision or TEST_CONFIG.assertions.floatTolerance
            local result = math.abs(expectation.actual - expected) <= precision
            if expectation.not then result = not result end
            
            if not result then
                UnitTestFramework.throwAssertionError(
                    expectation.not and "Expected values not to be close" or "Expected values to be close",
                    expected,
                    expectation.actual
                )
            end
        end
        
        function expectation.toBeTruthy()
            local result = expectation.actual and true or false
            if expectation.not then result = not result end
            
            if not result then
                UnitTestFramework.throwAssertionError(
                    expectation.not and "Expected value not to be truthy" or "Expected value to be truthy",
                    "truthy value",
                    expectation.actual
                )
            end
        end
        
        function expectation.toBeFalsy()
            local result = not expectation.actual
            if expectation.not then result = not result end
            
            if not result then
                UnitTestFramework.throwAssertionError(
                    expectation.not and "Expected value not to be falsy" or "Expected value to be falsy",
                    "falsy value",
                    expectation.actual
                )
            end
        end
        
        function expectation.toContain(expected)
            local result = false
            if type(expectation.actual) == "table" then
                for _, value in pairs(expectation.actual) do
                    if value == expected then
                        result = true
                        break
                    end
                end
            elseif type(expectation.actual) == "string" then
                result = string.find(expectation.actual, expected) ~= nil
            end
            
            if expectation.not then result = not result end
            
            if not result then
                UnitTestFramework.throwAssertionError(
                    expectation.not and "Expected value not to contain" or "Expected value to contain",
                    expected,
                    expectation.actual
                )
            end
        end
        
        function expectation.toThrow(expectedError)
            local success, error = pcall(expectation.actual)
            local result = not success
            
            if expectedError and not success then
                result = string.find(tostring(error), expectedError) ~= nil
            end
            
            if expectation.not then result = not result end
            
            if not result then
                UnitTestFramework.throwAssertionError(
                    expectation.not and "Expected function not to throw" or "Expected function to throw",
                    expectedError or "any error",
                    success and "no error" or error
                )
            end
        end
        
        function expectation.toHaveBeenCalled()
            if type(expectation.actual) ~= "table" or not expectation.actual._isSpy then
                error("toHaveBeenCalled can only be used with spies")
            end
            
            local result = #expectation.actual.calls > 0
            if expectation.not then result = not result end
            
            if not result then
                UnitTestFramework.throwAssertionError(
                    expectation.not and "Expected spy not to have been called" or "Expected spy to have been called",
                    "function call",
                    string.format("%d calls", #expectation.actual.calls)
                )
            end
        end
        
        function expectation.toHaveBeenCalledWith(...)
            if type(expectation.actual) ~= "table" or not expectation.actual._isSpy then
                error("toHaveBeenCalledWith can only be used with spies")
            end
            
            local expectedArgs = {...}
            local result = false
            
            for _, call in ipairs(expectation.actual.calls) do
                if UnitTestFramework.deepEqual(call.args, expectedArgs) then
                    result = true
                    break
                end
            end
            
            if expectation.not then result = not result end
            
            if not result then
                UnitTestFramework.throwAssertionError(
                    expectation.not and "Expected spy not to have been called with" or "Expected spy to have been called with",
                    expectedArgs,
                    expectation.actual.calls
                )
            end
        end
        
        return expectation
    end
    
    return expect
end

function UnitTestFramework.throwAssertionError(message, expected, actual)
    local errorMessage = string.format("Assertion failed: %s\nExpected: %s\nActual: %s", 
        message, 
        UnitTestFramework.stringify(expected), 
        UnitTestFramework.stringify(actual))
    
    error(errorMessage)
end

function UnitTestFramework.deepEqual(a, b)
    if type(a) ~= type(b) then
        return false
    end
    
    if type(a) == "table" then
        -- Check all keys in a exist in b with equal values
        for key, value in pairs(a) do
            if not UnitTestFramework.deepEqual(value, b[key]) then
                return false
            end
        end
        
        -- Check all keys in b exist in a
        for key, _ in pairs(b) do
            if a[key] == nil then
                return false
            end
        end
        
        return true
    else
        return a == b
    end
end

function UnitTestFramework.stringify(value)
    if type(value) == "table" then
        return HttpService:JSONEncode(value)
    else
        return tostring(value)
    end
end

-- ========================================
-- MOCKING SYSTEM
-- ========================================

function UnitTestFramework.initializeMockingSystem()
    TestState.mocks = {}
    TestState.spies = {}
    TestState.stubs = {}
    
    print("🎭 Mocking system initialized")
end

function UnitTestFramework.createMock(originalFunction)
    local mock = {
        _isMock = true,
        _original = originalFunction,
        calls = {},
        returnValue = nil,
        implementation = nil
    }
    
    local mockFunction = function(...)
        local args = {...}
        table.insert(mock.calls, {
            args = args,
            timestamp = tick()
        })
        
        if mock.implementation then
            return mock.implementation(...)
        elseif mock.returnValue ~= nil then
            return mock.returnValue
        end
    end
    
    -- Add mock methods
    mock.mockReturnValue = function(value)
        mock.returnValue = value
        return mock
    end
    
    mock.mockImplementation = function(impl)
        mock.implementation = impl
        return mock
    end
    
    mock.mockClear = function()
        mock.calls = {}
        return mock
    end
    
    mock.mockRestore = function()
        return mock._original
    end
    
    setmetatable(mock, {
        __call = mockFunction
    })
    
    table.insert(TestState.mocks, mock)
    return mock
end

function UnitTestFramework.createSpy(originalFunction)
    local spy = {
        _isSpy = true,
        _original = originalFunction,
        calls = {}
    }
    
    local spyFunction = function(...)
        local args = {...}
        table.insert(spy.calls, {
            args = args,
            timestamp = tick()
        })
        
        if originalFunction then
            return originalFunction(...)
        end
    end
    
    setmetatable(spy, {
        __call = spyFunction
    })
    
    table.insert(TestState.spies, spy)
    return spy
end

function UnitTestFramework.createStub(originalFunction, stubImplementation)
    local stub = {
        _isStub = true,
        _original = originalFunction,
        _implementation = stubImplementation,
        calls = {}
    }
    
    local stubFunction = function(...)
        local args = {...}
        table.insert(stub.calls, {
            args = args,
            timestamp = tick()
        })
        
        if stub._implementation then
            return stub._implementation(...)
        end
    end
    
    setmetatable(stub, {
        __call = stubFunction
    })
    
    table.insert(TestState.stubs, stub)
    return stub
end

function UnitTestFramework.clearAllMocks()
    for _, mock in ipairs(TestState.mocks) do
        mock.calls = {}
    end
    
    for _, spy in ipairs(TestState.spies) do
        spy.calls = {}
    end
    
    for _, stub in ipairs(TestState.stubs) do
        stub.calls = {}
    end
end

-- ========================================
-- COVERAGE TRACKING
-- ========================================

function UnitTestFramework.setupCoverageTracking()
    if not TEST_CONFIG.coverage.enableCoverageTracking then
        return
    end
    
    TestState.coverageData = {
        lines = {},
        functions = {},
        branches = {},
        statements = {}
    }
    
    print("📊 Coverage tracking initialized")
end

function UnitTestFramework.instrumentFile(filePath, sourceCode)
    if not TEST_CONFIG.coverage.enableCoverageTracking then
        return sourceCode
    end
    
    -- Basic instrumentation (in production, this would be more sophisticated)
    local instrumentedCode = sourceCode
    local lineNumber = 1
    
    -- Track line coverage
    for line in sourceCode:gmatch("[^\r\n]+") do
        if not UnitTestFramework.shouldExcludeFromCoverage(line) then
            TestState.coverageData.lines[lineNumber] = {
                file = filePath,
                line = lineNumber,
                content = line,
                hits = 0
            }
        end
        lineNumber = lineNumber + 1
    end
    
    TestState.sourceFiles[filePath] = {
        source = sourceCode,
        instrumented = instrumentedCode,
        totalLines = lineNumber - 1
    }
    
    return instrumentedCode
end

function UnitTestFramework.shouldExcludeFromCoverage(line)
    for _, pattern in ipairs(TEST_CONFIG.coverage.excludePatterns) do
        if string.find(line, pattern) then
            return true
        end
    end
    return false
end

function UnitTestFramework.recordLineCoverage(filePath, lineNumber)
    if TestState.coverageData.lines[lineNumber] then
        TestState.coverageData.lines[lineNumber].hits = 
            TestState.coverageData.lines[lineNumber].hits + 1
    end
end

function UnitTestFramework.calculateCoverage()
    local totalLines = 0
    local coveredLines = 0
    
    for _, lineData in pairs(TestState.coverageData.lines) do
        totalLines = totalLines + 1
        if lineData.hits > 0 then
            coveredLines = coveredLines + 1
        end
    end
    
    local coveragePercentage = totalLines > 0 and (coveredLines / totalLines) * 100 or 0
    TestState.stats.coveragePercentage = coveragePercentage
    
    return {
        totalLines = totalLines,
        coveredLines = coveredLines,
        coveragePercentage = coveragePercentage,
        uncoveredLines = UnitTestFramework.getUncoveredLines()
    }
end

function UnitTestFramework.getUncoveredLines()
    local uncovered = {}
    
    for lineNumber, lineData in pairs(TestState.coverageData.lines) do
        if lineData.hits == 0 then
            table.insert(uncovered, {
                file = lineData.file,
                line = lineNumber,
                content = lineData.content
            })
        end
    end
    
    return uncovered
end

-- ========================================
-- ASYNC TESTING SUPPORT
-- ========================================

function UnitTestFramework.initializeAsyncTesting()
    TestState.pendingTests = {}
    TestState.asyncCallbacks = {}
    
    print("⏱️ Async testing support initialized")
end

function UnitTestFramework.done()
    return function()
        if TestState.currentTest then
            TestState.currentTest.asyncComplete = true
        end
    end
end

function UnitTestFramework.waitFor(condition, timeout)
    timeout = timeout or 5000 -- 5 seconds default
    local startTime = tick()
    
    return function(callback)
        local function checkCondition()
            if condition() then
                callback(true)
            elseif (tick() - startTime) * 1000 >= timeout then
                callback(false, "Timeout waiting for condition")
            else
                task.wait(0.1)
                checkCondition()
            end
        end
        
        checkCondition()
    end
end

-- ========================================
-- TEST EXECUTION ENGINE
-- ========================================

function UnitTestFramework.runTests(suiteFilter)
    print("🧪 Starting test execution...")
    
    TestState.isRunning = true
    local startTime = tick()
    
    -- Reset statistics
    UnitTestFramework.resetTestStats()
    
    -- Run global before hooks
    UnitTestFramework.runHooks(TestState.testHooks.beforeAll)
    
    -- Execute test suites
    for suiteName, suite in pairs(TestState.testSuites) do
        if not suiteFilter or suiteName == suiteFilter then
            UnitTestFramework.runTestSuite(suite)
        end
    end
    
    -- Run global after hooks
    UnitTestFramework.runHooks(TestState.testHooks.afterAll)
    
    -- Calculate final statistics
    TestState.stats.executionTime = tick() - startTime
    local coverage = UnitTestFramework.calculateCoverage()
    
    -- Generate test report
    local report = UnitTestFramework.generateTestReport(coverage)
    
    TestState.isRunning = false
    
    print(string.format("🧪 Test execution completed in %.2fs", TestState.stats.executionTime))
    print(string.format("📊 Results: %d/%d passed, %.1f%% coverage", 
        TestState.stats.passedTests, TestState.stats.totalTests, coverage.coveragePercentage))
    
    return report
end

function UnitTestFramework.runTestSuite(suite)
    print(string.format("📋 Running test suite: %s", suite.name))
    
    -- Run suite before hooks
    UnitTestFramework.runHooks(suite.hooks.beforeAll)
    
    -- Execute individual tests
    for _, testCase in ipairs(suite.tests) do
        if not testCase.skip then
            UnitTestFramework.runTestCase(testCase, suite)
        else
            TestState.stats.skippedTests = TestState.stats.skippedTests + 1
            suite.stats.skipped = suite.stats.skipped + 1
        end
    end
    
    -- Run suite after hooks
    UnitTestFramework.runHooks(suite.hooks.afterAll)
    
    print(string.format("📋 Suite completed: %s (%d/%d passed)", 
        suite.name, suite.stats.passed, suite.stats.total))
end

function UnitTestFramework.runTestCase(testCase, suite)
    TestState.currentTest = testCase
    testCase.startTime = tick()
    
    -- Run before each hooks
    UnitTestFramework.runHooks(TestState.testHooks.beforeEach)
    UnitTestFramework.runHooks(suite.hooks.beforeEach)
    
    local success, error = UnitTestFramework.executeTest(testCase)
    
    -- Run after each hooks
    UnitTestFramework.runHooks(suite.hooks.afterEach)
    UnitTestFramework.runHooks(TestState.testHooks.afterEach)
    
    -- Record test result
    testCase.endTime = tick()
    testCase.duration = testCase.endTime - testCase.startTime
    testCase.success = success
    testCase.error = error
    
    if success then
        TestState.stats.passedTests = TestState.stats.passedTests + 1
        suite.stats.passed = suite.stats.passed + 1
        print(string.format("  ✓ %s (%.2fms)", testCase.name, testCase.duration * 1000))
    else
        TestState.stats.failedTests = TestState.stats.failedTests + 1
        suite.stats.failed = suite.stats.failed + 1
        print(string.format("  ✗ %s (%.2fms): %s", testCase.name, testCase.duration * 1000, error))
    end
    
    suite.stats.total = suite.stats.total + 1
    
    -- Store result
    table.insert(TestState.testResults, {
        suite = suite.name,
        test = testCase.name,
        success = success,
        error = error,
        duration = testCase.duration
    })
    
    TestState.currentTest = nil
end

function UnitTestFramework.executeTest(testCase)
    local success, error
    
    if testCase.async then
        success, error = UnitTestFramework.executeAsyncTest(testCase)
    else
        success, error = pcall(testCase.func)
    end
    
    return success, error
end

function UnitTestFramework.executeAsyncTest(testCase)
    testCase.asyncComplete = false
    local success, error = pcall(testCase.func, UnitTestFramework.done())
    
    if not success then
        return false, error
    end
    
    -- Wait for async completion
    local timeout = testCase.timeout
    local startTime = tick()
    
    while not testCase.asyncComplete do
        if (tick() - startTime) * 1000 >= timeout then
            return false, "Async test timeout"
        end
        task.wait(0.1)
    end
    
    return true, nil
end

function UnitTestFramework.runHooks(hooks)
    for _, hook in ipairs(hooks) do
        local success, error = pcall(hook)
        if not success then
            warn(string.format("Hook failed: %s", error))
        end
    end
end

function UnitTestFramework.resetTestStats()
    TestState.stats = {
        totalTests = TestState.stats.totalTests,
        passedTests = 0,
        failedTests = 0,
        skippedTests = 0,
        totalSuites = TestState.stats.totalSuites,
        executionTime = 0,
        coveragePercentage = 0
    }
    
    -- Reset suite stats
    for _, suite in pairs(TestState.testSuites) do
        suite.stats = {
            total = 0,
            passed = 0,
            failed = 0,
            skipped = 0
        }
    end
end

-- ========================================
-- REPORTING SYSTEM
-- ========================================

function UnitTestFramework.generateTestReport(coverage)
    local report = {
        timestamp = tick(),
        execution = {
            duration = TestState.stats.executionTime,
            suites = TestState.stats.totalSuites,
            tests = TestState.stats.totalTests,
            passed = TestState.stats.passedTests,
            failed = TestState.stats.failedTests,
            skipped = TestState.stats.skippedTests,
            successRate = (TestState.stats.passedTests / math.max(TestState.stats.totalTests, 1)) * 100
        },
        coverage = coverage,
        results = TestState.testResults,
        suites = {},
        failures = {}
    }
    
    -- Add suite details
    for suiteName, suite in pairs(TestState.testSuites) do
        report.suites[suiteName] = {
            name = suiteName,
            stats = suite.stats,
            tests = suite.tests
        }
    end
    
    -- Add failure details
    for _, result in ipairs(TestState.testResults) do
        if not result.success then
            table.insert(report.failures, result)
        end
    end
    
    -- Check coverage threshold
    report.coverageThresholdMet = coverage.coveragePercentage >= TEST_CONFIG.coverage.coverageThreshold
    
    return report
end

function UnitTestFramework.printDetailedReport(report)
    print("\n" .. string.rep("=", 60))
    print("🧪 UNIT TEST REPORT")
    print(string.rep("=", 60))
    
    -- Execution summary
    print(string.format("📊 Execution Summary:"))
    print(string.format("  Duration: %.2fs", report.execution.duration))
    print(string.format("  Suites: %d", report.execution.suites))
    print(string.format("  Tests: %d total, %d passed, %d failed, %d skipped", 
        report.execution.tests, report.execution.passed, 
        report.execution.failed, report.execution.skipped))
    print(string.format("  Success Rate: %.1f%%", report.execution.successRate))
    
    -- Coverage summary
    print(string.format("\n📈 Coverage Summary:"))
    print(string.format("  Lines: %d/%d (%.1f%%)", 
        report.coverage.coveredLines, report.coverage.totalLines, 
        report.coverage.coveragePercentage))
    print(string.format("  Threshold: %.1f%% (%s)", 
        TEST_CONFIG.coverage.coverageThreshold,
        report.coverageThresholdMet and "✓ PASSED" or "✗ FAILED"))
    
    -- Failure details
    if #report.failures > 0 then
        print(string.format("\n❌ Failures (%d):", #report.failures))
        for _, failure in ipairs(report.failures) do
            print(string.format("  %s > %s:", failure.suite, failure.test))
            print(string.format("    %s", failure.error))
        end
    end
    
    print(string.rep("=", 60))
end

-- ========================================
-- PUBLIC API
-- ========================================

-- Export core testing functions
UnitTestFramework.describe = UnitTestFramework.describe
UnitTestFramework.it = UnitTestFramework.it
UnitTestFramework.beforeAll = UnitTestFramework.beforeAll
UnitTestFramework.afterAll = UnitTestFramework.afterAll
UnitTestFramework.beforeEach = UnitTestFramework.beforeEach
UnitTestFramework.afterEach = UnitTestFramework.afterEach

-- Export assertion functions
function UnitTestFramework.getExpect()
    return UnitTestFramework.expect
end

-- Export mocking functions
UnitTestFramework.createMock = UnitTestFramework.createMock
UnitTestFramework.createSpy = UnitTestFramework.createSpy
UnitTestFramework.createStub = UnitTestFramework.createStub
UnitTestFramework.clearAllMocks = UnitTestFramework.clearAllMocks

-- Export test execution
UnitTestFramework.runTests = UnitTestFramework.runTests

-- Export utilities
function UnitTestFramework.getTestStats()
    return TestState.stats
end

function UnitTestFramework.getCoverageData()
    return TestState.coverageData
end

function UnitTestFramework.getTestResults()
    return TestState.testResults
end

function UnitTestFramework.printReport(report)
    if TEST_CONFIG.reporting.reportFormat == "detailed" then
        UnitTestFramework.printDetailedReport(report)
    else
        print(string.format("Tests: %d/%d passed, %.1f%% coverage", 
            report.execution.passed, report.execution.tests, 
            report.coverage.coveragePercentage))
    end
end

-- Initialize the unit testing framework
UnitTestFramework.initialize()

print("🧪 UnitTestFramework loaded with comprehensive testing capabilities")

return UnitTestFramework
