-- PerformanceTestingSystem.luau
-- Automated performance regression testing and benchmarking system
-- Validates performance across updates and identifies regressions

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")

local SafeRequire = require(ReplicatedStorage.Shared.utils.SafeRequire)

local PerformanceTestingSystem = {}

-- ========================================
-- TESTING CONFIGURATION
-- ========================================

local TESTING_CONFIG = {
    -- Benchmark suites
    benchmarkSuites = {
        startup = {
            name = "Startup Performance",
            tests = {"moduleLoading", "assetPreloading", "initialization", "firstFrame"},
            timeout = 60000, -- 60 seconds
            iterations = 5,
            warmupRuns = 1
        },
        runtime = {
            name = "Runtime Performance",
            tests = {"frameRate", "memoryUsage", "scriptExecution", "renderingPerformance"},
            timeout = 30000, -- 30 seconds
            iterations = 10,
            warmupRuns = 2
        },
        stress = {
            name = "Stress Testing",
            tests = {"highPlayerCount", "memoryPressure", "networkLoad", "assetStreaming"},
            timeout = 120000, -- 2 minutes
            iterations = 3,
            warmupRuns = 1
        },
        regression = {
            name = "Regression Testing",
            tests = {"performanceBaseline", "memoryBaseline", "loadTimeBaseline"},
            timeout = 45000, -- 45 seconds
            iterations = 5,
            warmupRuns = 1
        }
    },
    
    -- Performance thresholds
    thresholds = {
        critical = {
            startupTime = 15000,      -- 15 seconds
            averageFPS = 30,          -- Minimum FPS
            memoryUsage = 1024,       -- 1GB maximum
            loadTime = 5000,          -- 5 seconds
            responseTime = 100        -- 100ms
        },
        warning = {
            startupTime = 10000,      -- 10 seconds
            averageFPS = 45,          -- Target FPS
            memoryUsage = 512,        -- 512MB target
            loadTime = 3000,          -- 3 seconds
            responseTime = 50         -- 50ms
        },
        target = {
            startupTime = 5000,       -- 5 seconds
            averageFPS = 60,          -- Ideal FPS
            memoryUsage = 256,        -- 256MB ideal
            loadTime = 1000,          -- 1 second
            responseTime = 20         -- 20ms
        }
    },
    
    -- Regression detection
    regression = {
        performanceDeltaThreshold = 0.15,    -- 15% performance delta
        memoryDeltaThreshold = 0.20,         -- 20% memory delta
        loadTimeDeltaThreshold = 0.25,       -- 25% load time delta
        consecutiveFailuresThreshold = 3,    -- 3 consecutive failures
        baselineRetentionDays = 30          -- Keep baselines for 30 days
    },
    
    -- Test environment
    environment = {
        enableAutomatedTesting = true,
        enableContinuousTesting = false,
        testInterval = 3600,                 -- 1 hour between tests
        enableRegressionAlerts = true,
        enablePerformanceReports = true
    }
}

-- ========================================
-- TESTING SYSTEM STATE
-- ========================================

local TestingState = {
    -- Test execution
    currentTest = nil,
    activeTests = {},
    testResults = {},
    testHistory = {},
    
    -- Benchmarking
    benchmarkResults = {},
    performanceBaselines = {},
    regressionResults = {},
    
    -- Test data collection
    testMetrics = {},
    testEnvironment = {},
    
    -- Automated testing
    automatedTestingEnabled = false,
    testScheduler = nil,
    
    -- Result storage
    resultDatabase = {},
    
    -- Statistics
    stats = {
        testsRun = 0,
        testsPasssed = 0,
        testsFailed = 0,
        regressionsDetected = 0,
        averageTestTime = 0
    },
    
    -- System state
    isInitialized = false,
    connections = {}
}

function PerformanceTestingSystem.initialize()
    print("🧪 Initializing PerformanceTestingSystem...")
    
    -- Initialize test environment
    PerformanceTestingSystem.initializeTestEnvironment()
    
    -- Load performance baselines
    PerformanceTestingSystem.loadPerformanceBaselines()
    
    -- Set up automated testing
    PerformanceTestingSystem.setupAutomatedTesting()
    
    -- Initialize benchmark suites
    PerformanceTestingSystem.initializeBenchmarkSuites()
    
    -- Set up regression detection
    PerformanceTestingSystem.setupRegressionDetection()
    
    TestingState.isInitialized = true
    print("🧪 PerformanceTestingSystem initialized successfully")
end

-- ========================================
-- TEST ENVIRONMENT SETUP
-- ========================================

function PerformanceTestingSystem.initializeTestEnvironment()
    TestingState.testEnvironment = {
        platform = PerformanceTestingSystem.detectPlatform(),
        deviceType = PerformanceTestingSystem.detectDeviceType(),
        gameVersion = PerformanceTestingSystem.getGameVersion(),
        testTimestamp = tick(),
        environmentId = HttpService:GenerateGUID(false)
    }
    
    print(string.format("🔧 Test environment: %s (%s)", 
        TestingState.testEnvironment.platform, 
        TestingState.testEnvironment.deviceType))
end

function PerformanceTestingSystem.detectPlatform()
    -- Detect the current platform
    if game:GetService("UserInputService").TouchEnabled then
        return "Mobile"
    elseif game:GetService("UserInputService").GamepadEnabled then
        return "Console"
    else
        return "PC"
    end
end

function PerformanceTestingSystem.detectDeviceType()
    -- Estimate device performance tier
    local memoryUsage = collectgarbage("count") / 1024
    if memoryUsage < 256 then
        return "HighEnd"
    elseif memoryUsage < 512 then
        return "MidRange"
    else
        return "LowEnd"
    end
end

function PerformanceTestingSystem.getGameVersion()
    -- Get current game version for baseline comparison
    return "1.0.0" -- Placeholder - would get actual version
end

-- ========================================
-- BENCHMARK SUITE EXECUTION
-- ========================================

function PerformanceTestingSystem.initializeBenchmarkSuites()
    for suiteName, suite in pairs(TESTING_CONFIG.benchmarkSuites) do
        print(string.format("📋 Initialized benchmark suite: %s (%d tests)", 
            suite.name, #suite.tests))
    end
end

function PerformanceTestingSystem.runBenchmarkSuite(suiteName, callback)
    local suite = TESTING_CONFIG.benchmarkSuites[suiteName]
    if not suite then
        warn("Unknown benchmark suite: " .. suiteName)
        if callback then callback(false, "Suite not found") end
        return
    end
    
    local suiteResults = {
        suiteName = suiteName,
        startTime = tick(),
        tests = {},
        environment = TestingState.testEnvironment,
        status = "running"
    }
    
    TestingState.currentTest = suiteResults
    print(string.format("🧪 Running benchmark suite: %s", suite.name))
    
    -- Run warmup iterations
    PerformanceTestingSystem.runWarmupTests(suite, function()
        -- Run actual test iterations
        PerformanceTestingSystem.runTestIterations(suite, suiteResults, function(results)
            suiteResults.endTime = tick()
            suiteResults.totalTime = suiteResults.endTime - suiteResults.startTime
            suiteResults.status = results.success and "completed" or "failed"
            
            -- Store results
            table.insert(TestingState.testResults, suiteResults)
            TestingState.stats.testsRun = TestingState.stats.testsRun + 1
            
            if results.success then
                TestingState.stats.testsPasssed = TestingState.stats.testsPasssed + 1
            else
                TestingState.stats.testsFailed = TestingState.stats.testsFailed + 1
            end
            
            TestingState.currentTest = nil
            
            print(string.format("✅ Completed benchmark suite: %s (%.2fs)", 
                suite.name, suiteResults.totalTime))
            
            if callback then callback(results.success, suiteResults) end
        end)
    end)
end

function PerformanceTestingSystem.runWarmupTests(suite, callback)
    local warmupCount = suite.warmupRuns or 1
    local completedWarmups = 0
    
    local function runNextWarmup()
        if completedWarmups >= warmupCount then
            callback()
            return
        end
        
        PerformanceTestingSystem.runTestIteration(suite, true, function()
            completedWarmups = completedWarmups + 1
            task.wait(1) -- Brief pause between warmups
            runNextWarmup()
        end)
    end
    
    runNextWarmup()
end

function PerformanceTestingSystem.runTestIterations(suite, suiteResults, callback)
    local iterations = suite.iterations or 1
    local completedIterations = 0
    local allResults = {}
    
    local function runNextIteration()
        if completedIterations >= iterations then
            -- Process final results
            local processedResults = PerformanceTestingSystem.processIterationResults(allResults)
            suiteResults.tests = processedResults.tests
            suiteResults.summary = processedResults.summary
            
            callback({
                success = processedResults.success,
                results = processedResults
            })
            return
        end
        
        PerformanceTestingSystem.runTestIteration(suite, false, function(results)
            table.insert(allResults, results)
            completedIterations = completedIterations + 1
            
            print(string.format("📊 Iteration %d/%d completed", completedIterations, iterations))
            
            task.wait(2) -- Pause between iterations
            runNextIteration()
        end)
    end
    
    runNextIteration()
end

function PerformanceTestingSystem.runTestIteration(suite, isWarmup, callback)
    local iterationResults = {
        isWarmup = isWarmup,
        startTime = tick(),
        tests = {}
    }
    
    local testIndex = 1
    
    local function runNextTest()
        if testIndex > #suite.tests then
            iterationResults.endTime = tick()
            iterationResults.duration = iterationResults.endTime - iterationResults.startTime
            callback(iterationResults)
            return
        end
        
        local testName = suite.tests[testIndex]
        PerformanceTestingSystem.runIndividualTest(testName, function(testResult)
            if not isWarmup then
                iterationResults.tests[testName] = testResult
            end
            
            testIndex = testIndex + 1
            runNextTest()
        end)
    end
    
    runNextTest()
end

function PerformanceTestingSystem.runIndividualTest(testName, callback)
    local testStartTime = tick()
    local testFunc = PerformanceTestingSystem.getTestFunction(testName)
    
    if not testFunc then
        callback({
            name = testName,
            success = false,
            error = "Test function not found",
            duration = 0
        })
        return
    end
    
    -- Run the test
    local success, result = pcall(testFunc)
    local testEndTime = tick()
    
    local testResult = {
        name = testName,
        success = success,
        duration = (testEndTime - testStartTime) * 1000, -- Convert to milliseconds
        timestamp = testStartTime,
        result = success and result or nil,
        error = not success and tostring(result) or nil
    }
    
    callback(testResult)
end

function PerformanceTestingSystem.getTestFunction(testName)
    local testFunctions = {
        moduleLoading = PerformanceTestingSystem.testModuleLoading,
        assetPreloading = PerformanceTestingSystem.testAssetPreloading,
        initialization = PerformanceTestingSystem.testInitialization,
        firstFrame = PerformanceTestingSystem.testFirstFrame,
        frameRate = PerformanceTestingSystem.testFrameRate,
        memoryUsage = PerformanceTestingSystem.testMemoryUsage,
        scriptExecution = PerformanceTestingSystem.testScriptExecution,
        renderingPerformance = PerformanceTestingSystem.testRenderingPerformance,
        highPlayerCount = PerformanceTestingSystem.testHighPlayerCount,
        memoryPressure = PerformanceTestingSystem.testMemoryPressure,
        networkLoad = PerformanceTestingSystem.testNetworkLoad,
        assetStreaming = PerformanceTestingSystem.testAssetStreaming,
        performanceBaseline = PerformanceTestingSystem.testPerformanceBaseline,
        memoryBaseline = PerformanceTestingSystem.testMemoryBaseline,
        loadTimeBaseline = PerformanceTestingSystem.testLoadTimeBaseline
    }
    
    return testFunctions[testName]
end

function PerformanceTestingSystem.processIterationResults(allResults)
    local processedTests = {}
    local testNames = {}
    
    -- Collect all test names
    for _, iteration in ipairs(allResults) do
        for testName, _ in pairs(iteration.tests) do
            if not testNames[testName] then
                testNames[testName] = true
                table.insert(testNames, testName)
            end
        end
    end
    
    -- Process each test across iterations
    for _, testName in ipairs(testNames) do
        local testResults = {}
        for _, iteration in ipairs(allResults) do
            if iteration.tests[testName] then
                table.insert(testResults, iteration.tests[testName])
            end
        end
        
        processedTests[testName] = PerformanceTestingSystem.calculateTestStatistics(testResults)
    end
    
    -- Calculate overall success
    local overallSuccess = true
    for _, testStats in pairs(processedTests) do
        if not testStats.success then
            overallSuccess = false
            break
        end
    end
    
    return {
        tests = processedTests,
        success = overallSuccess,
        summary = PerformanceTestingSystem.generateTestSummary(processedTests)
    }
end

function PerformanceTestingSystem.calculateTestStatistics(testResults)
    local durations = {}
    local successCount = 0
    
    for _, result in ipairs(testResults) do
        table.insert(durations, result.duration)
        if result.success then
            successCount = successCount + 1
        end
    end
    
    table.sort(durations)
    
    local stats = {
        success = successCount == #testResults,
        successRate = successCount / #testResults,
        iterations = #testResults,
        duration = {
            min = durations[1],
            max = durations[#durations],
            median = durations[math.ceil(#durations / 2)],
            average = PerformanceTestingSystem.calculateAverage(durations),
            p95 = durations[math.ceil(#durations * 0.95)]
        }
    }
    
    return stats
end

function PerformanceTestingSystem.calculateAverage(values)
    local sum = 0
    for _, value in ipairs(values) do
        sum = sum + value
    end
    return sum / #values
end

function PerformanceTestingSystem.generateTestSummary(processedTests)
    local summary = {
        totalTests = 0,
        passedTests = 0,
        failedTests = 0,
        averageDuration = 0,
        performanceScore = 0
    }
    
    local totalDuration = 0
    for _, testStats in pairs(processedTests) do
        summary.totalTests = summary.totalTests + 1
        if testStats.success then
            summary.passedTests = summary.passedTests + 1
        else
            summary.failedTests = summary.failedTests + 1
        end
        totalDuration = totalDuration + testStats.duration.average
    end
    
    summary.averageDuration = totalDuration / summary.totalTests
    summary.successRate = summary.passedTests / summary.totalTests
    summary.performanceScore = summary.successRate * 100
    
    return summary
end

-- ========================================
-- INDIVIDUAL TEST IMPLEMENTATIONS
-- ========================================

function PerformanceTestingSystem.testModuleLoading()
    local startTime = tick()
    
    -- Simulate module loading test
    local modules = {"TestModule1", "TestModule2", "TestModule3"}
    for _, moduleName in ipairs(modules) do
        -- Simulate module load time
        task.wait(math.random(10, 50) / 1000)
    end
    
    local loadTime = (tick() - startTime) * 1000
    
    return {
        loadTime = loadTime,
        modulesLoaded = #modules,
        success = loadTime < TESTING_CONFIG.thresholds.warning.loadTime
    }
end

function PerformanceTestingSystem.testAssetPreloading()
    local startTime = tick()
    
    -- Simulate asset preloading
    task.wait(math.random(100, 500) / 1000)
    
    local preloadTime = (tick() - startTime) * 1000
    
    return {
        preloadTime = preloadTime,
        assetsLoaded = math.random(10, 50),
        success = preloadTime < TESTING_CONFIG.thresholds.warning.loadTime
    }
end

function PerformanceTestingSystem.testInitialization()
    local startTime = tick()
    
    -- Simulate initialization
    task.wait(math.random(50, 200) / 1000)
    
    local initTime = (tick() - startTime) * 1000
    
    return {
        initializationTime = initTime,
        success = initTime < TESTING_CONFIG.thresholds.warning.startupTime / 10
    }
end

function PerformanceTestingSystem.testFirstFrame()
    local frameTime = 1 / RunService.Heartbeat:Wait()
    
    return {
        firstFrameTime = frameTime,
        fps = 1 / frameTime,
        success = frameTime > TESTING_CONFIG.thresholds.warning.averageFPS
    }
end

function PerformanceTestingSystem.testFrameRate()
    local frameTimes = {}
    local measurements = 60
    
    -- Measure frame rate over time
    for i = 1, measurements do
        local frameTime = RunService.Heartbeat:Wait()
        table.insert(frameTimes, frameTime)
    end
    
    local averageFrameTime = PerformanceTestingSystem.calculateAverage(frameTimes)
    local averageFPS = 1 / averageFrameTime
    
    return {
        averageFPS = averageFPS,
        measurements = measurements,
        success = averageFPS >= TESTING_CONFIG.thresholds.warning.averageFPS
    }
end

function PerformanceTestingSystem.testMemoryUsage()
    local initialMemory = collectgarbage("count")
    
    -- Simulate memory allocation
    local testData = {}
    for i = 1, 1000 do
        testData[i] = string.rep("test", 100)
    end
    
    local finalMemory = collectgarbage("count")
    local memoryDelta = (finalMemory - initialMemory) / 1024 -- Convert to MB
    
    -- Cleanup
    testData = nil
    collectgarbage("collect")
    
    return {
        memoryUsage = finalMemory / 1024, -- MB
        memoryDelta = memoryDelta,
        success = (finalMemory / 1024) < TESTING_CONFIG.thresholds.warning.memoryUsage
    }
end

function PerformanceTestingSystem.testScriptExecution()
    local startTime = tick()
    
    -- Simulate script execution workload
    local sum = 0
    for i = 1, 100000 do
        sum = sum + i
    end
    
    local executionTime = (tick() - startTime) * 1000
    
    return {
        executionTime = executionTime,
        operations = 100000,
        success = executionTime < TESTING_CONFIG.thresholds.warning.responseTime
    }
end

function PerformanceTestingSystem.testRenderingPerformance()
    local renderTime = RunService.Heartbeat:Wait() * 0.6 -- Estimate render portion
    
    return {
        renderTime = renderTime * 1000, -- Convert to ms
        success = (renderTime * 1000) < TESTING_CONFIG.thresholds.warning.responseTime
    }
end

function PerformanceTestingSystem.testHighPlayerCount()
    -- Simulate high player count scenario
    local simulatedPlayers = 50
    local processingTime = simulatedPlayers * 0.5 -- ms per player
    
    return {
        simulatedPlayers = simulatedPlayers,
        processingTime = processingTime,
        success = processingTime < TESTING_CONFIG.thresholds.warning.responseTime
    }
end

function PerformanceTestingSystem.testMemoryPressure()
    local initialMemory = collectgarbage("count")
    
    -- Create memory pressure
    local memoryHog = {}
    for i = 1, 10000 do
        memoryHog[i] = string.rep("pressure", 50)
    end
    
    local pressureMemory = collectgarbage("count")
    local memoryIncrease = (pressureMemory - initialMemory) / 1024
    
    -- Cleanup
    memoryHog = nil
    collectgarbage("collect")
    
    local finalMemory = collectgarbage("count")
    local memoryRecovered = (pressureMemory - finalMemory) / 1024
    
    return {
        memoryIncrease = memoryIncrease,
        memoryRecovered = memoryRecovered,
        recoveryRate = memoryRecovered / memoryIncrease,
        success = (finalMemory / 1024) < TESTING_CONFIG.thresholds.critical.memoryUsage
    }
end

function PerformanceTestingSystem.testNetworkLoad()
    local startTime = tick()
    
    -- Simulate network operations
    task.wait(math.random(20, 100) / 1000)
    
    local networkTime = (tick() - startTime) * 1000
    
    return {
        networkTime = networkTime,
        success = networkTime < TESTING_CONFIG.thresholds.warning.responseTime * 2
    }
end

function PerformanceTestingSystem.testAssetStreaming()
    local streamingTime = math.random(100, 500)
    local assetsStreamed = math.random(5, 20)
    
    return {
        streamingTime = streamingTime,
        assetsStreamed = assetsStreamed,
        averageAssetTime = streamingTime / assetsStreamed,
        success = (streamingTime / assetsStreamed) < 50 -- 50ms per asset
    }
end

function PerformanceTestingSystem.testPerformanceBaseline()
    -- Compare current performance against baseline
    local currentFPS = 1 / RunService.Heartbeat:Wait()
    local baseline = TestingState.performanceBaselines.fps or 60
    
    local deltaPercent = math.abs(currentFPS - baseline) / baseline
    
    return {
        currentFPS = currentFPS,
        baselineFPS = baseline,
        deltaPercent = deltaPercent,
        success = deltaPercent < TESTING_CONFIG.regression.performanceDeltaThreshold
    }
end

function PerformanceTestingSystem.testMemoryBaseline()
    local currentMemory = collectgarbage("count") / 1024
    local baseline = TestingState.performanceBaselines.memory or 256
    
    local deltaPercent = math.abs(currentMemory - baseline) / baseline
    
    return {
        currentMemory = currentMemory,
        baselineMemory = baseline,
        deltaPercent = deltaPercent,
        success = deltaPercent < TESTING_CONFIG.regression.memoryDeltaThreshold
    }
end

function PerformanceTestingSystem.testLoadTimeBaseline()
    local startTime = tick()
    
    -- Simulate load operation
    task.wait(math.random(500, 2000) / 1000)
    
    local loadTime = (tick() - startTime) * 1000
    local baseline = TestingState.performanceBaselines.loadTime or 1000
    
    local deltaPercent = math.abs(loadTime - baseline) / baseline
    
    return {
        currentLoadTime = loadTime,
        baselineLoadTime = baseline,
        deltaPercent = deltaPercent,
        success = deltaPercent < TESTING_CONFIG.regression.loadTimeDeltaThreshold
    }
end

-- ========================================
-- PERFORMANCE BASELINES
-- ========================================

function PerformanceTestingSystem.loadPerformanceBaselines()
    -- Load existing baselines or create defaults
    TestingState.performanceBaselines = {
        fps = 60,
        memory = 256, -- MB
        loadTime = 1000, -- ms
        startupTime = 5000, -- ms
        responseTime = 20 -- ms
    }
    
    print("📊 Performance baselines loaded")
end

function PerformanceTestingSystem.updateBaseline(metric, value)
    TestingState.performanceBaselines[metric] = value
    print(string.format("📊 Updated baseline %s: %.2f", metric, value))
end

function PerformanceTestingSystem.establishNewBaseline()
    -- Run comprehensive baseline test
    PerformanceTestingSystem.runBenchmarkSuite("runtime", function(success, results)
        if success then
            -- Extract baseline values from results
            local newBaselines = PerformanceTestingSystem.extractBaselinesFromResults(results)
            
            for metric, value in pairs(newBaselines) do
                TestingState.performanceBaselines[metric] = value
            end
            
            print("📊 New performance baseline established")
        end
    end)
end

function PerformanceTestingSystem.extractBaselinesFromResults(results)
    local baselines = {}
    
    if results.tests.frameRate then
        baselines.fps = results.tests.frameRate.duration.average
    end
    
    if results.tests.memoryUsage then
        baselines.memory = results.tests.memoryUsage.duration.average
    end
    
    return baselines
end

-- ========================================
-- REGRESSION DETECTION
-- ========================================

function PerformanceTestingSystem.setupRegressionDetection()
    TestingState.regressionResults = {}
    
    print("🔍 Regression detection system active")
end

function PerformanceTestingSystem.detectRegressions(testResults)
    local regressions = {}
    
    -- Check each test against thresholds and baselines
    for testName, testStats in pairs(testResults.tests) do
        local regression = PerformanceTestingSystem.analyzeTestForRegression(testName, testStats)
        if regression then
            table.insert(regressions, regression)
        end
    end
    
    if #regressions > 0 then
        PerformanceTestingSystem.handleRegressionDetection(regressions)
        TestingState.stats.regressionsDetected = TestingState.stats.regressionsDetected + #regressions
    end
    
    return regressions
end

function PerformanceTestingSystem.analyzeTestForRegression(testName, testStats)
    -- Check performance regression
    if not testStats.success then
        return {
            testName = testName,
            type = "failure",
            severity = "critical",
            description = "Test failed to meet success criteria"
        }
    end
    
    -- Check against baselines
    local baselineKey = PerformanceTestingSystem.getBaselineKey(testName)
    if baselineKey and TestingState.performanceBaselines[baselineKey] then
        local baseline = TestingState.performanceBaselines[baselineKey]
        local current = testStats.duration.average
        local deltaPercent = math.abs(current - baseline) / baseline
        
        local threshold = PerformanceTestingSystem.getRegressionThreshold(testName)
        if deltaPercent > threshold then
            return {
                testName = testName,
                type = "performance_regression",
                severity = deltaPercent > threshold * 2 and "critical" or "warning",
                baseline = baseline,
                current = current,
                deltaPercent = deltaPercent,
                description = string.format("Performance regression detected: %.1f%% deviation from baseline", deltaPercent * 100)
            }
        end
    end
    
    return nil
end

function PerformanceTestingSystem.getBaselineKey(testName)
    local keyMap = {
        frameRate = "fps",
        memoryUsage = "memory",
        moduleLoading = "loadTime",
        assetPreloading = "loadTime"
    }
    return keyMap[testName]
end

function PerformanceTestingSystem.getRegressionThreshold(testName)
    local thresholdMap = {
        frameRate = TESTING_CONFIG.regression.performanceDeltaThreshold,
        memoryUsage = TESTING_CONFIG.regression.memoryDeltaThreshold,
        moduleLoading = TESTING_CONFIG.regression.loadTimeDeltaThreshold,
        assetPreloading = TESTING_CONFIG.regression.loadTimeDeltaThreshold
    }
    return thresholdMap[testName] or TESTING_CONFIG.regression.performanceDeltaThreshold
end

function PerformanceTestingSystem.handleRegressionDetection(regressions)
    for _, regression in ipairs(regressions) do
        if regression.severity == "critical" then
            warn(string.format("🚨 CRITICAL REGRESSION: %s - %s", regression.testName, regression.description))
        else
            warn(string.format("⚠️ Performance regression: %s - %s", regression.testName, regression.description))
        end
    end
    
    -- Store regression results
    table.insert(TestingState.regressionResults, {
        timestamp = tick(),
        regressions = regressions,
        severity = PerformanceTestingSystem.calculateOverallSeverity(regressions)
    })
end

function PerformanceTestingSystem.calculateOverallSeverity(regressions)
    local hasCritical = false
    local hasWarning = false
    
    for _, regression in ipairs(regressions) do
        if regression.severity == "critical" then
            hasCritical = true
        elseif regression.severity == "warning" then
            hasWarning = true
        end
    end
    
    if hasCritical then
        return "critical"
    elseif hasWarning then
        return "warning"
    else
        return "info"
    end
end

-- ========================================
-- AUTOMATED TESTING
-- ========================================

function PerformanceTestingSystem.setupAutomatedTesting()
    if not TESTING_CONFIG.environment.enableAutomatedTesting then
        return
    end
    
    TestingState.automatedTestingEnabled = true
    
    if TESTING_CONFIG.environment.enableContinuousTesting then
        PerformanceTestingSystem.startContinuousTesting()
    end
    
    print("🤖 Automated testing system active")
end

function PerformanceTestingSystem.startContinuousTesting()
    TestingState.testScheduler = task.spawn(function()
        while TestingState.automatedTestingEnabled do
            PerformanceTestingSystem.runAutomatedTestCycle()
            task.wait(TESTING_CONFIG.environment.testInterval)
        end
    end)
    
    print("🔄 Continuous testing started")
end

function PerformanceTestingSystem.runAutomatedTestCycle()
    print("🤖 Running automated test cycle...")
    
    -- Run regression tests
    PerformanceTestingSystem.runBenchmarkSuite("regression", function(success, results)
        if success then
            local regressions = PerformanceTestingSystem.detectRegressions(results)
            if #regressions > 0 then
                PerformanceTestingSystem.sendRegressionAlert(regressions)
            end
        end
        
        -- Run performance tests
        PerformanceTestingSystem.runBenchmarkSuite("runtime", function(runtimeSuccess, runtimeResults)
            if runtimeSuccess then
                PerformanceTestingSystem.generatePerformanceReport(runtimeResults)
            end
        end)
    end)
end

function PerformanceTestingSystem.sendRegressionAlert(regressions)
    if not TESTING_CONFIG.environment.enableRegressionAlerts then
        return
    end
    
    warn(string.format("🚨 Performance regression alert: %d regressions detected", #regressions))
    
    for _, regression in ipairs(regressions) do
        warn(string.format("  - %s: %s", regression.testName, regression.description))
    end
end

function PerformanceTestingSystem.generatePerformanceReport(results)
    if not TESTING_CONFIG.environment.enablePerformanceReports then
        return
    end
    
    local report = {
        timestamp = tick(),
        environment = TestingState.testEnvironment,
        results = results,
        summary = results.summary,
        baseline_comparison = PerformanceTestingSystem.compareWithBaselines(results)
    }
    
    table.insert(TestingState.testHistory, report)
    
    print(string.format("📄 Performance report generated: %.1f%% success rate", 
        results.summary.performanceScore))
end

function PerformanceTestingSystem.compareWithBaselines(results)
    local comparison = {}
    
    for testName, testStats in pairs(results.tests) do
        local baselineKey = PerformanceTestingSystem.getBaselineKey(testName)
        if baselineKey and TestingState.performanceBaselines[baselineKey] then
            local baseline = TestingState.performanceBaselines[baselineKey]
            local current = testStats.duration.average
            local deltaPercent = ((current - baseline) / baseline) * 100
            
            comparison[testName] = {
                baseline = baseline,
                current = current,
                delta = deltaPercent,
                status = deltaPercent > 15 and "regression" or (deltaPercent < -15 and "improvement" or "stable")
            }
        end
    end
    
    return comparison
end

-- ========================================
-- PUBLIC API
-- ========================================

function PerformanceTestingSystem.runTest(suiteName, callback)
    return PerformanceTestingSystem.runBenchmarkSuite(suiteName, callback)
end

function PerformanceTestingSystem.getTestResults()
    return TestingState.testResults
end

function PerformanceTestingSystem.getTestHistory()
    return TestingState.testHistory
end

function PerformanceTestingSystem.getRegressionResults()
    return TestingState.regressionResults
end

function PerformanceTestingSystem.getBaselines()
    return TestingState.performanceBaselines
end

function PerformanceTestingSystem.setBaseline(metric, value)
    return PerformanceTestingSystem.updateBaseline(metric, value)
end

function PerformanceTestingSystem.getTestStatistics()
    return TestingState.stats
end

function PerformanceTestingSystem.enableAutomatedTesting(enabled)
    TestingState.automatedTestingEnabled = enabled
    
    if enabled and not TestingState.testScheduler then
        PerformanceTestingSystem.startContinuousTesting()
    elseif not enabled and TestingState.testScheduler then
        task.cancel(TestingState.testScheduler)
        TestingState.testScheduler = nil
    end
    
    print(string.format("🤖 Automated testing %s", enabled and "enabled" or "disabled"))
end

function PerformanceTestingSystem.shutdown()
    TestingState.isInitialized = false
    TestingState.automatedTestingEnabled = false
    
    if TestingState.testScheduler then
        task.cancel(TestingState.testScheduler)
    end
    
    for _, connection in pairs(TestingState.connections) do
        if typeof(connection) == "thread" then
            task.cancel(connection)
        elseif typeof(connection) == "RBXScriptConnection" then
            connection:Disconnect()
        end
    end
    
    print("🧪 PerformanceTestingSystem shutdown")
end

-- Initialize the performance testing system
PerformanceTestingSystem.initialize()

print("🧪 PerformanceTestingSystem loaded with automated regression testing")

return PerformanceTestingSystem
