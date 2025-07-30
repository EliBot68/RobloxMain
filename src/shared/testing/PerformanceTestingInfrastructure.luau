-- PerformanceTestingInfrastructure.luau
-- Performance testing and load testing infrastructure for comprehensive performance validation
-- Tests system performance under various load conditions and stress scenarios

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")

local SafeRequire = require(ReplicatedStorage.Shared.utils.SafeRequire)

local PerformanceTestingInfrastructure = {}

-- ========================================
-- PERFORMANCE TESTING CONFIGURATION
-- ========================================

local PERF_TEST_CONFIG = {
    -- Load testing settings
    loadTesting = {
        enableLoadTesting = true,
        enableStressTesting = true,
        enableSpikeTests = true,
        enableVolumeTests = true,
        maxConcurrentUsers = 100,
        testDuration = 300,              -- 5 minutes
        rampUpTime = 60,                 -- 1 minute
        rampDownTime = 60                -- 1 minute
    },
    
    -- Performance benchmarks
    benchmarks = {
        enableBenchmarking = true,
        enableComparison = true,
        enableRegression = true,
        baselineThreshold = 0.1,         -- 10% performance degradation threshold
        sampleSize = 100,
        warmupIterations = 10
    },
    
    -- Resource monitoring
    monitoring = {
        enableCPUMonitoring = true,
        enableMemoryMonitoring = true,
        enableNetworkMonitoring = true,
        enableGPUMonitoring = true,
        monitoringInterval = 1000,       -- 1 second
        alertThresholds = {
            cpu = 80,                    -- 80% CPU usage
            memory = 1024,               -- 1GB memory usage
            fps = 30,                    -- Minimum 30 FPS
            latency = 200                -- 200ms max latency
        }
    },
    
    -- Test scenarios
    scenarios = {
        enableScenarioTesting = true,
        enableUserSimulation = true,
        enableDataIntensiveTests = true,
        enableConcurrencyTests = true,
        maxTestDuration = 600            -- 10 minutes
    },
    
    -- Reporting and analysis
    reporting = {
        enableDetailedReporting = true,
        enableGraphs = true,
        enableComparison = true,
        retentionPeriod = 2592000        -- 30 days
    }
}

-- ========================================
-- PERFORMANCE TESTING STATE
-- ========================================

local PerfTestState = {
    -- Test execution
    activeTests = {},
    testResults = {},
    testQueue = {},
    
    -- Load testing
    loadTests = {},
    userSimulations = {},
    loadMetrics = {},
    
    -- Performance benchmarks
    benchmarks = {},
    baselines = {},
    regressionData = {},
    
    -- Resource monitoring
    cpuMetrics = {},
    memoryMetrics = {},
    networkMetrics = {},
    fpsMetrics = {},
    
    -- Test scenarios
    scenarios = {},
    scenarioResults = {},
    
    -- Statistics
    stats = {
        totalTests = 0,
        passedTests = 0,
        failedTests = 0,
        averageExecutionTime = 0,
        totalLoadTests = 0,
        maxConcurrentUsers = 0,
        performanceScore = 0
    }
}

function PerformanceTestingInfrastructure.initialize()
    print("⚡ Initializing PerformanceTestingInfrastructure...")
    
    -- Set up resource monitoring
    PerformanceTestingInfrastructure.setupResourceMonitoring()
    
    -- Initialize load testing framework
    PerformanceTestingInfrastructure.initializeLoadTestingFramework()
    
    -- Set up benchmarking system
    PerformanceTestingInfrastructure.setupBenchmarkingSystem()
    
    -- Initialize scenario testing
    PerformanceTestingInfrastructure.initializeScenarioTesting()
    
    -- Set up stress testing
    PerformanceTestingInfrastructure.setupStressTesting()
    
    print("⚡ PerformanceTestingInfrastructure initialized successfully")
end

-- ========================================
-- RESOURCE MONITORING
-- ========================================

function PerformanceTestingInfrastructure.setupResourceMonitoring()
    PerfTestState.resourceMonitor = {
        active = false,
        startTime = 0,
        metrics = {},
        alerts = {}
    }
    
    -- Start monitoring systems
    PerformanceTestingInfrastructure.startCPUMonitoring()
    PerformanceTestingInfrastructure.startMemoryMonitoring()
    PerformanceTestingInfrastructure.startFPSMonitoring()
    PerformanceTestingInfrastructure.startNetworkMonitoring()
    
    print("📊 Resource monitoring initialized")
end

function PerformanceTestingInfrastructure.startCPUMonitoring()
    task.spawn(function()
        while true do
            if PerfTestState.resourceMonitor.active then
                local cpuUsage = PerformanceTestingInfrastructure.measureCPUUsage()
                
                table.insert(PerfTestState.cpuMetrics, {
                    timestamp = tick(),
                    usage = cpuUsage,
                    threshold = PERF_TEST_CONFIG.monitoring.alertThresholds.cpu
                })
                
                -- Check threshold
                if cpuUsage > PERF_TEST_CONFIG.monitoring.alertThresholds.cpu then
                    PerformanceTestingInfrastructure.triggerAlert("CPU", cpuUsage, "High CPU usage detected")
                end
                
                -- Limit data retention
                if #PerfTestState.cpuMetrics > 3600 then
                    table.remove(PerfTestState.cpuMetrics, 1)
                end
            end
            
            task.wait(PERF_TEST_CONFIG.monitoring.monitoringInterval / 1000)
        end
    end)
end

function PerformanceTestingInfrastructure.measureCPUUsage()
    -- Simulate CPU usage measurement (in real implementation would use actual system metrics)
    local startTime = tick()
    local iterations = 100000
    
    for i = 1, iterations do
        math.sin(i)
    end
    
    local executionTime = tick() - startTime
    return math.min(100, executionTime * 1000) -- Convert to percentage
end

function PerformanceTestingInfrastructure.startMemoryMonitoring()
    task.spawn(function()
        while true do
            if PerfTestState.resourceMonitor.active then
                local memoryUsage = collectgarbage("count") / 1024 -- Convert to MB
                
                table.insert(PerfTestState.memoryMetrics, {
                    timestamp = tick(),
                    usage = memoryUsage,
                    threshold = PERF_TEST_CONFIG.monitoring.alertThresholds.memory
                })
                
                -- Check threshold
                if memoryUsage > PERF_TEST_CONFIG.monitoring.alertThresholds.memory then
                    PerformanceTestingInfrastructure.triggerAlert("Memory", memoryUsage, "High memory usage detected")
                end
                
                -- Limit data retention
                if #PerfTestState.memoryMetrics > 3600 then
                    table.remove(PerfTestState.memoryMetrics, 1)
                end
            end
            
            task.wait(PERF_TEST_CONFIG.monitoring.monitoringInterval / 1000)
        end
    end)
end

function PerformanceTestingInfrastructure.startFPSMonitoring()
    local frameCount = 0
    local lastSecond = math.floor(tick())
    
    RunService.Heartbeat:Connect(function()
        if PerfTestState.resourceMonitor.active then
            frameCount = frameCount + 1
            local currentSecond = math.floor(tick())
            
            if currentSecond > lastSecond then
                local fps = frameCount
                frameCount = 0
                lastSecond = currentSecond
                
                table.insert(PerfTestState.fpsMetrics, {
                    timestamp = tick(),
                    fps = fps,
                    threshold = PERF_TEST_CONFIG.monitoring.alertThresholds.fps
                })
                
                -- Check threshold
                if fps < PERF_TEST_CONFIG.monitoring.alertThresholds.fps then
                    PerformanceTestingInfrastructure.triggerAlert("FPS", fps, "Low FPS detected")
                end
                
                -- Limit data retention
                if #PerfTestState.fpsMetrics > 3600 then
                    table.remove(PerfTestState.fpsMetrics, 1)
                end
            end
        end
    end)
end

function PerformanceTestingInfrastructure.startNetworkMonitoring()
    task.spawn(function()
        while true do
            if PerfTestState.resourceMonitor.active then
                local latency = PerformanceTestingInfrastructure.measureNetworkLatency()
                
                table.insert(PerfTestState.networkMetrics, {
                    timestamp = tick(),
                    latency = latency,
                    threshold = PERF_TEST_CONFIG.monitoring.alertThresholds.latency
                })
                
                -- Check threshold
                if latency > PERF_TEST_CONFIG.monitoring.alertThresholds.latency then
                    PerformanceTestingInfrastructure.triggerAlert("Network", latency, "High latency detected")
                end
                
                -- Limit data retention
                if #PerfTestState.networkMetrics > 600 then
                    table.remove(PerfTestState.networkMetrics, 1)
                end
            end
            
            task.wait(10) -- Check every 10 seconds
        end
    end)
end

function PerformanceTestingInfrastructure.measureNetworkLatency()
    -- Simulate network latency measurement
    return math.random(20, 150)
end

function PerformanceTestingInfrastructure.triggerAlert(metricType, value, message)
    local alert = {
        type = metricType,
        value = value,
        message = message,
        timestamp = tick(),
        severity = PerformanceTestingInfrastructure.calculateAlertSeverity(metricType, value)
    }
    
    table.insert(PerfTestState.resourceMonitor.alerts, alert)
    
    warn(string.format("⚠️ Performance Alert [%s]: %s (%.2f)", metricType, message, value))
end

function PerformanceTestingInfrastructure.calculateAlertSeverity(metricType, value)
    local thresholds = PERF_TEST_CONFIG.monitoring.alertThresholds
    local threshold = thresholds[string.lower(metricType)]
    
    if not threshold then return "low" end
    
    local ratio = value / threshold
    
    if ratio >= 2.0 then
        return "critical"
    elseif ratio >= 1.5 then
        return "high"
    elseif ratio >= 1.2 then
        return "medium"
    else
        return "low"
    end
end

function PerformanceTestingInfrastructure.startResourceMonitoring()
    PerfTestState.resourceMonitor.active = true
    PerfTestState.resourceMonitor.startTime = tick()
    
    print("📊 Resource monitoring started")
end

function PerformanceTestingInfrastructure.stopResourceMonitoring()
    PerfTestState.resourceMonitor.active = false
    
    print("📊 Resource monitoring stopped")
end

-- ========================================
-- LOAD TESTING FRAMEWORK
-- ========================================

function PerformanceTestingInfrastructure.initializeLoadTestingFramework()
    PerfTestState.loadTests = {}
    PerfTestState.userSimulations = {}
    PerfTestState.loadMetrics = {}
    
    print("🔄 Load testing framework initialized")
end

function PerformanceTestingInfrastructure.createLoadTest(testName, configuration)
    local loadTest = {
        name = testName,
        configuration = configuration,
        virtualUsers = {},
        metrics = {},
        results = {},
        startTime = nil,
        endTime = nil,
        status = "pending"
    }
    
    PerfTestState.loadTests[testName] = loadTest
    
    return loadTest
end

function PerformanceTestingInfrastructure.executeLoadTest(testName)
    local loadTest = PerfTestState.loadTests[testName]
    if not loadTest then
        error(string.format("Load test '%s' not found", testName))
    end
    
    loadTest.startTime = tick()
    loadTest.status = "running"
    
    print(string.format("🔄 Starting load test: %s", testName))
    
    -- Start resource monitoring
    PerformanceTestingInfrastructure.startResourceMonitoring()
    
    -- Execute load test phases
    local success = PerformanceTestingInfrastructure.executeLoadTestPhases(loadTest)
    
    loadTest.endTime = tick()
    loadTest.duration = loadTest.endTime - loadTest.startTime
    loadTest.status = success and "completed" or "failed"
    
    -- Stop resource monitoring
    PerformanceTestingInfrastructure.stopResourceMonitoring()
    
    -- Calculate results
    loadTest.results = PerformanceTestingInfrastructure.calculateLoadTestResults(loadTest)
    
    PerfTestState.stats.totalLoadTests = PerfTestState.stats.totalLoadTests + 1
    
    print(string.format("🔄 Load test %s: %s (%.2fs)", 
        testName, loadTest.status, loadTest.duration))
    
    return loadTest
end

function PerformanceTestingInfrastructure.executeLoadTestPhases(loadTest)
    local config = loadTest.configuration
    
    -- Phase 1: Ramp-up
    local success = PerformanceTestingInfrastructure.executeRampUpPhase(loadTest, config.rampUpTime or PERF_TEST_CONFIG.loadTesting.rampUpTime)
    if not success then return false end
    
    -- Phase 2: Sustained load
    success = PerformanceTestingInfrastructure.executeSustainedLoadPhase(loadTest, config.testDuration or PERF_TEST_CONFIG.loadTesting.testDuration)
    if not success then return false end
    
    -- Phase 3: Ramp-down
    success = PerformanceTestingInfrastructure.executeRampDownPhase(loadTest, config.rampDownTime or PERF_TEST_CONFIG.loadTesting.rampDownTime)
    
    return success
end

function PerformanceTestingInfrastructure.executeRampUpPhase(loadTest, duration)
    local config = loadTest.configuration
    local maxUsers = config.maxUsers or PERF_TEST_CONFIG.loadTesting.maxConcurrentUsers
    local startTime = tick()
    
    print(string.format("  📈 Ramp-up phase: 0 -> %d users over %.1fs", maxUsers, duration))
    
    while tick() - startTime < duration do
        local elapsed = tick() - startTime
        local progress = elapsed / duration
        local currentUsers = math.floor(maxUsers * progress)
        
        -- Add users if needed
        while #loadTest.virtualUsers < currentUsers do
            local user = PerformanceTestingInfrastructure.createVirtualUser(#loadTest.virtualUsers + 1, config.userBehavior)
            table.insert(loadTest.virtualUsers, user)
            PerformanceTestingInfrastructure.startVirtualUser(user)
        end
        
        -- Record metrics
        PerformanceTestingInfrastructure.recordLoadMetrics(loadTest, "rampup")
        
        task.wait(1)
    end
    
    return true
end

function PerformanceTestingInfrastructure.executeSustainedLoadPhase(loadTest, duration)
    local startTime = tick()
    
    print(string.format("  🔄 Sustained load phase: %d users for %.1fs", #loadTest.virtualUsers, duration))
    
    while tick() - startTime < duration do
        -- Monitor system performance
        PerformanceTestingInfrastructure.recordLoadMetrics(loadTest, "sustained")
        
        -- Check for failure conditions
        if PerformanceTestingInfrastructure.checkFailureConditions(loadTest) then
            warn("Load test failed due to system performance degradation")
            return false
        end
        
        task.wait(1)
    end
    
    return true
end

function PerformanceTestingInfrastructure.executeRampDownPhase(loadTest, duration)
    local startTime = tick()
    local initialUsers = #loadTest.virtualUsers
    
    print(string.format("  📉 Ramp-down phase: %d -> 0 users over %.1fs", initialUsers, duration))
    
    while tick() - startTime < duration do
        local elapsed = tick() - startTime
        local progress = elapsed / duration
        local remainingUsers = math.floor(initialUsers * (1 - progress))
        
        -- Remove users if needed
        while #loadTest.virtualUsers > remainingUsers do
            local user = table.remove(loadTest.virtualUsers)
            PerformanceTestingInfrastructure.stopVirtualUser(user)
        end
        
        -- Record metrics
        PerformanceTestingInfrastructure.recordLoadMetrics(loadTest, "rampdown")
        
        task.wait(1)
    end
    
    -- Stop all remaining users
    for _, user in ipairs(loadTest.virtualUsers) do
        PerformanceTestingInfrastructure.stopVirtualUser(user)
    end
    loadTest.virtualUsers = {}
    
    return true
end

function PerformanceTestingInfrastructure.createVirtualUser(userId, behavior)
    local user = {
        id = userId,
        behavior = behavior or {},
        active = false,
        startTime = tick(),
        actions = {},
        metrics = {
            actionsPerformed = 0,
            errors = 0,
            averageResponseTime = 0
        }
    }
    
    return user
end

function PerformanceTestingInfrastructure.startVirtualUser(user)
    user.active = true
    user.startTime = tick()
    
    -- Start user behavior simulation
    task.spawn(function()
        while user.active do
            PerformanceTestingInfrastructure.executeUserAction(user)
            task.wait(math.random(1, 5)) -- Random action interval
        end
    end)
end

function PerformanceTestingInfrastructure.stopVirtualUser(user)
    user.active = false
    user.endTime = tick()
    user.totalTime = user.endTime - user.startTime
end

function PerformanceTestingInfrastructure.executeUserAction(user)
    local actions = user.behavior.actions or {"click", "scroll", "type", "wait"}
    local action = actions[math.random(#actions)]
    
    local actionStart = tick()
    local success, error = pcall(function()
        if action == "click" then
            -- Simulate click action
            task.wait(0.01)
        elseif action == "scroll" then
            -- Simulate scroll action
            task.wait(0.02)
        elseif action == "type" then
            -- Simulate typing
            task.wait(0.05)
        elseif action == "wait" then
            task.wait(0.1)
        end
    end)
    
    local actionEnd = tick()
    local responseTime = actionEnd - actionStart
    
    table.insert(user.actions, {
        action = action,
        timestamp = actionStart,
        responseTime = responseTime,
        success = success,
        error = error
    })
    
    user.metrics.actionsPerformed = user.metrics.actionsPerformed + 1
    if not success then
        user.metrics.errors = user.metrics.errors + 1
    end
    
    -- Update average response time
    local totalResponseTime = 0
    for _, actionData in ipairs(user.actions) do
        totalResponseTime = totalResponseTime + actionData.responseTime
    end
    user.metrics.averageResponseTime = totalResponseTime / #user.actions
end

function PerformanceTestingInfrastructure.recordLoadMetrics(loadTest, phase)
    local metrics = {
        timestamp = tick(),
        phase = phase,
        activeUsers = #loadTest.virtualUsers,
        cpu = PerfTestState.cpuMetrics[#PerfTestState.cpuMetrics] and PerfTestState.cpuMetrics[#PerfTestState.cpuMetrics].usage or 0,
        memory = PerfTestState.memoryMetrics[#PerfTestState.memoryMetrics] and PerfTestState.memoryMetrics[#PerfTestState.memoryMetrics].usage or 0,
        fps = PerfTestState.fpsMetrics[#PerfTestState.fpsMetrics] and PerfTestState.fpsMetrics[#PerfTestState.fpsMetrics].fps or 0,
        latency = PerfTestState.networkMetrics[#PerfTestState.networkMetrics] and PerfTestState.networkMetrics[#PerfTestState.networkMetrics].latency or 0
    }
    
    table.insert(loadTest.metrics, metrics)
end

function PerformanceTestingInfrastructure.checkFailureConditions(loadTest)
    local latestMetrics = loadTest.metrics[#loadTest.metrics]
    if not latestMetrics then return false end
    
    local thresholds = PERF_TEST_CONFIG.monitoring.alertThresholds
    
    if latestMetrics.cpu > thresholds.cpu * 1.5 then return true end
    if latestMetrics.memory > thresholds.memory * 1.5 then return true end
    if latestMetrics.fps < thresholds.fps * 0.5 then return true end
    if latestMetrics.latency > thresholds.latency * 2 then return true end
    
    return false
end

function PerformanceTestingInfrastructure.calculateLoadTestResults(loadTest)
    local results = {
        duration = loadTest.duration,
        maxConcurrentUsers = 0,
        totalActions = 0,
        totalErrors = 0,
        averageResponseTime = 0,
        throughput = 0,
        errorRate = 0,
        performance = {
            maxCPU = 0,
            maxMemory = 0,
            minFPS = 999,
            maxLatency = 0
        }
    }
    
    -- Calculate user metrics
    for _, user in ipairs(loadTest.virtualUsers) do
        results.totalActions = results.totalActions + user.metrics.actionsPerformed
        results.totalErrors = results.totalErrors + user.metrics.errors
        results.averageResponseTime = results.averageResponseTime + user.metrics.averageResponseTime
    end
    
    if #loadTest.virtualUsers > 0 then
        results.averageResponseTime = results.averageResponseTime / #loadTest.virtualUsers
    end
    
    results.errorRate = results.totalActions > 0 and (results.totalErrors / results.totalActions) * 100 or 0
    results.throughput = loadTest.duration > 0 and (results.totalActions / loadTest.duration) or 0
    
    -- Calculate performance metrics
    for _, metric in ipairs(loadTest.metrics) do
        results.maxConcurrentUsers = math.max(results.maxConcurrentUsers, metric.activeUsers)
        results.performance.maxCPU = math.max(results.performance.maxCPU, metric.cpu)
        results.performance.maxMemory = math.max(results.performance.maxMemory, metric.memory)
        results.performance.minFPS = math.min(results.performance.minFPS, metric.fps)
        results.performance.maxLatency = math.max(results.performance.maxLatency, metric.latency)
    end
    
    return results
end

-- ========================================
-- BENCHMARKING SYSTEM
-- ========================================

function PerformanceTestingInfrastructure.setupBenchmarkingSystem()
    PerfTestState.benchmarks = {}
    PerfTestState.baselines = {}
    PerfTestState.regressionData = {}
    
    print("📏 Benchmarking system initialized")
end

function PerformanceTestingInfrastructure.createBenchmark(benchmarkName, benchmarkFunction, options)
    options = options or {}
    
    local benchmark = {
        name = benchmarkName,
        func = benchmarkFunction,
        options = options,
        results = {},
        baseline = nil,
        regressions = {}
    }
    
    PerfTestState.benchmarks[benchmarkName] = benchmark
    
    return benchmark
end

function PerformanceTestingInfrastructure.runBenchmark(benchmarkName, iterations)
    local benchmark = PerfTestState.benchmarks[benchmarkName]
    if not benchmark then
        error(string.format("Benchmark '%s' not found", benchmarkName))
    end
    
    iterations = iterations or PERF_TEST_CONFIG.benchmarks.sampleSize
    local warmupIterations = PERF_TEST_CONFIG.benchmarks.warmupIterations
    
    print(string.format("📏 Running benchmark: %s (%d iterations)", benchmarkName, iterations))
    
    local results = {
        name = benchmarkName,
        iterations = iterations,
        executions = {},
        statistics = {},
        timestamp = tick()
    }
    
    -- Warmup iterations
    for i = 1, warmupIterations do
        pcall(benchmark.func)
    end
    
    -- Actual benchmark iterations
    for i = 1, iterations do
        local startTime = tick()
        local startMemory = collectgarbage("count")
        
        local success, result = pcall(benchmark.func)
        
        local endTime = tick()
        local endMemory = collectgarbage("count")
        
        local execution = {
            iteration = i,
            executionTime = (endTime - startTime) * 1000, -- Convert to milliseconds
            memoryDelta = (endMemory - startMemory) / 1024, -- Convert to MB
            success = success,
            result = result,
            timestamp = endTime
        }
        
        table.insert(results.executions, execution)
    end
    
    -- Calculate statistics
    results.statistics = PerformanceTestingInfrastructure.calculateBenchmarkStatistics(results.executions)
    
    -- Store results
    table.insert(benchmark.results, results)
    
    -- Check for regression
    if benchmark.baseline then
        local regression = PerformanceTestingInfrastructure.detectRegression(benchmark.baseline, results)
        if regression then
            table.insert(benchmark.regressions, regression)
        end
    end
    
    print(string.format("📏 Benchmark completed: avg %.2fms, std %.2fms", 
        results.statistics.averageTime, results.statistics.standardDeviation))
    
    return results
end

function PerformanceTestingInfrastructure.calculateBenchmarkStatistics(executions)
    local times = {}
    local memories = {}
    local successCount = 0
    
    for _, execution in ipairs(executions) do
        table.insert(times, execution.executionTime)
        table.insert(memories, execution.memoryDelta)
        if execution.success then
            successCount = successCount + 1
        end
    end
    
    local statistics = {
        successRate = (successCount / #executions) * 100,
        averageTime = PerformanceTestingInfrastructure.calculateMean(times),
        minTime = math.min(unpack(times)),
        maxTime = math.max(unpack(times)),
        medianTime = PerformanceTestingInfrastructure.calculateMedian(times),
        standardDeviation = PerformanceTestingInfrastructure.calculateStandardDeviation(times),
        averageMemory = PerformanceTestingInfrastructure.calculateMean(memories),
        percentiles = {
            p95 = PerformanceTestingInfrastructure.calculatePercentile(times, 95),
            p99 = PerformanceTestingInfrastructure.calculatePercentile(times, 99)
        }
    }
    
    return statistics
end

function PerformanceTestingInfrastructure.calculateMean(values)
    local sum = 0
    for _, value in ipairs(values) do
        sum = sum + value
    end
    return sum / #values
end

function PerformanceTestingInfrastructure.calculateMedian(values)
    local sorted = {}
    for _, value in ipairs(values) do
        table.insert(sorted, value)
    end
    table.sort(sorted)
    
    local n = #sorted
    if n % 2 == 0 then
        return (sorted[n/2] + sorted[n/2 + 1]) / 2
    else
        return sorted[math.ceil(n/2)]
    end
end

function PerformanceTestingInfrastructure.calculateStandardDeviation(values)
    local mean = PerformanceTestingInfrastructure.calculateMean(values)
    local squaredDifferences = {}
    
    for _, value in ipairs(values) do
        table.insert(squaredDifferences, (value - mean)^2)
    end
    
    local variance = PerformanceTestingInfrastructure.calculateMean(squaredDifferences)
    return math.sqrt(variance)
end

function PerformanceTestingInfrastructure.calculatePercentile(values, percentile)
    local sorted = {}
    for _, value in ipairs(values) do
        table.insert(sorted, value)
    end
    table.sort(sorted)
    
    local index = math.ceil((percentile / 100) * #sorted)
    return sorted[index]
end

function PerformanceTestingInfrastructure.setBaseline(benchmarkName, results)
    local benchmark = PerfTestState.benchmarks[benchmarkName]
    if not benchmark then
        error(string.format("Benchmark '%s' not found", benchmarkName))
    end
    
    benchmark.baseline = results or benchmark.results[#benchmark.results]
    PerfTestState.baselines[benchmarkName] = benchmark.baseline
    
    print(string.format("📏 Baseline set for benchmark: %s (%.2fms)", benchmarkName, benchmark.baseline.statistics.averageTime))
end

function PerformanceTestingInfrastructure.detectRegression(baseline, current)
    local baselineTime = baseline.statistics.averageTime
    local currentTime = current.statistics.averageTime
    
    local performanceChange = (currentTime - baselineTime) / baselineTime
    local threshold = PERF_TEST_CONFIG.benchmarks.baselineThreshold
    
    if performanceChange > threshold then
        return {
            type = "performance_regression",
            baseline = baseline,
            current = current,
            change = performanceChange * 100, -- Convert to percentage
            threshold = threshold * 100,
            timestamp = tick()
        }
    end
    
    return nil
end

-- ========================================
-- STRESS TESTING
-- ========================================

function PerformanceTestingInfrastructure.setupStressTesting()
    PerfTestState.stressTests = {}
    
    print("💪 Stress testing initialized")
end

function PerformanceTestingInfrastructure.createStressTest(testName, stressFunction, limits)
    local stressTest = {
        name = testName,
        func = stressFunction,
        limits = limits or {
            maxIterations = 1000,
            maxDuration = 300, -- 5 minutes
            memoryLimit = 2048, -- 2GB
            cpuLimit = 90 -- 90%
        },
        results = {},
        breakingPoint = nil
    }
    
    PerfTestState.stressTests[testName] = stressTest
    
    return stressTest
end

function PerformanceTestingInfrastructure.executeStressTest(testName)
    local stressTest = PerfTestState.stressTests[testName]
    if not stressTest then
        error(string.format("Stress test '%s' not found", testName))
    end
    
    print(string.format("💪 Starting stress test: %s", testName))
    
    PerformanceTestingInfrastructure.startResourceMonitoring()
    
    local startTime = tick()
    local iteration = 0
    local success = true
    local breakingPoint = nil
    
    while success and iteration < stressTest.limits.maxIterations do
        iteration = iteration + 1
        
        -- Execute stress function
        local iterationStart = tick()
        success = pcall(stressTest.func, iteration)
        local iterationEnd = tick()
        
        -- Record metrics
        local metrics = {
            iteration = iteration,
            timestamp = iterationEnd,
            duration = iterationEnd - iterationStart,
            success = success,
            memory = collectgarbage("count") / 1024,
            totalTime = iterationEnd - startTime
        }
        
        table.insert(stressTest.results, metrics)
        
        -- Check limits
        if metrics.totalTime > stressTest.limits.maxDuration then
            breakingPoint = {type = "duration", limit = stressTest.limits.maxDuration, iteration = iteration}
            break
        end
        
        if metrics.memory > stressTest.limits.memoryLimit then
            breakingPoint = {type = "memory", limit = stressTest.limits.memoryLimit, iteration = iteration}
            break
        end
        
        -- Check if function failed
        if not success then
            breakingPoint = {type = "function_failure", iteration = iteration}
            break
        end
        
        task.wait(0.01) -- Small delay to prevent infinite tight loops
    end
    
    PerformanceTestingInfrastructure.stopResourceMonitoring()
    
    stressTest.breakingPoint = breakingPoint
    stressTest.completedIterations = iteration
    stressTest.totalDuration = tick() - startTime
    
    print(string.format("💪 Stress test %s completed: %d iterations, %.2fs", 
        testName, iteration, stressTest.totalDuration))
    
    if breakingPoint then
        print(string.format("  Breaking point: %s at iteration %d", breakingPoint.type, breakingPoint.iteration))
    end
    
    return stressTest
end

-- ========================================
-- PUBLIC API
-- ========================================

function PerformanceTestingInfrastructure.runAllPerformanceTests()
    print("⚡ Running all performance tests...")
    
    local startTime = tick()
    
    -- Run load tests
    local loadTestResults = PerformanceTestingInfrastructure.runLoadTests()
    
    -- Run benchmarks
    local benchmarkResults = PerformanceTestingInfrastructure.runBenchmarks()
    
    -- Run stress tests
    local stressTestResults = PerformanceTestingInfrastructure.runStressTests()
    
    local endTime = tick()
    
    -- Generate comprehensive report
    local report = PerformanceTestingInfrastructure.generatePerformanceReport(loadTestResults, benchmarkResults, stressTestResults)
    
    print(string.format("⚡ Performance tests completed in %.2fs", endTime - startTime))
    
    return report
end

function PerformanceTestingInfrastructure.runLoadTests()
    print("🔄 Running load tests...")
    
    -- Create and run basic load test
    PerformanceTestingInfrastructure.createLoadTest("BasicLoad", {
        maxUsers = 50,
        testDuration = 60,
        userBehavior = {
            actions = {"click", "scroll", "type"}
        }
    })
    
    local results = {}
    for testName, _ in pairs(PerfTestState.loadTests) do
        table.insert(results, PerformanceTestingInfrastructure.executeLoadTest(testName))
    end
    
    return results
end

function PerformanceTestingInfrastructure.runBenchmarks()
    print("📏 Running benchmarks...")
    
    -- Create basic benchmarks
    PerformanceTestingInfrastructure.createBenchmark("BasicComputation", function()
        local sum = 0
        for i = 1, 10000 do
            sum = sum + math.sin(i)
        end
        return sum
    end)
    
    PerformanceTestingInfrastructure.createBenchmark("MemoryAllocation", function()
        local array = {}
        for i = 1, 1000 do
            array[i] = {value = i, timestamp = tick()}
        end
        return #array
    end)
    
    local results = {}
    for benchmarkName, _ in pairs(PerfTestState.benchmarks) do
        table.insert(results, PerformanceTestingInfrastructure.runBenchmark(benchmarkName, 50))
    end
    
    return results
end

function PerformanceTestingInfrastructure.runStressTests()
    print("💪 Running stress tests...")
    
    -- Create basic stress test
    PerformanceTestingInfrastructure.createStressTest("MemoryStress", function(iteration)
        -- Simulate memory intensive operation
        local data = {}
        for i = 1, iteration * 100 do
            data[i] = string.rep("test", 100)
        end
        return true
    end)
    
    local results = {}
    for testName, _ in pairs(PerfTestState.stressTests) do
        table.insert(results, PerformanceTestingInfrastructure.executeStressTest(testName))
    end
    
    return results
end

function PerformanceTestingInfrastructure.generatePerformanceReport(loadTestResults, benchmarkResults, stressTestResults)
    return {
        timestamp = tick(),
        loadTests = loadTestResults,
        benchmarks = benchmarkResults,
        stressTests = stressTestResults,
        resourceMetrics = {
            cpu = PerfTestState.cpuMetrics,
            memory = PerfTestState.memoryMetrics,
            fps = PerfTestState.fpsMetrics,
            network = PerfTestState.networkMetrics
        },
        alerts = PerfTestState.resourceMonitor.alerts,
        statistics = PerfTestState.stats
    }
end

function PerformanceTestingInfrastructure.getPerformanceStats()
    return PerfTestState.stats
end

function PerformanceTestingInfrastructure.getResourceMetrics()
    return {
        cpu = PerfTestState.cpuMetrics,
        memory = PerfTestState.memoryMetrics,
        fps = PerfTestState.fpsMetrics,
        network = PerfTestState.networkMetrics
    }
end

-- Export API
PerformanceTestingInfrastructure.createLoadTest = PerformanceTestingInfrastructure.createLoadTest
PerformanceTestingInfrastructure.executeLoadTest = PerformanceTestingInfrastructure.executeLoadTest
PerformanceTestingInfrastructure.createBenchmark = PerformanceTestingInfrastructure.createBenchmark
PerformanceTestingInfrastructure.runBenchmark = PerformanceTestingInfrastructure.runBenchmark
PerformanceTestingInfrastructure.setBaseline = PerformanceTestingInfrastructure.setBaseline
PerformanceTestingInfrastructure.createStressTest = PerformanceTestingInfrastructure.createStressTest
PerformanceTestingInfrastructure.executeStressTest = PerformanceTestingInfrastructure.executeStressTest

-- Initialize the performance testing infrastructure
PerformanceTestingInfrastructure.initialize()

print("⚡ PerformanceTestingInfrastructure loaded with comprehensive performance testing capabilities")

return PerformanceTestingInfrastructure
