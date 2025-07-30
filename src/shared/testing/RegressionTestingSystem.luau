-- RegressionTestingSystem.luau
-- Regression testing for critical game mechanics
-- Provides automated validation and baseline comparison for game features

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")

local SafeRequire = require(ReplicatedStorage.Shared.utils.SafeRequire)

local RegressionTestingSystem = {}

-- ========================================
-- REGRESSION TESTING CONFIGURATION
-- ========================================

local REGRESSION_CONFIG = {
    -- Test execution settings
    execution = {
        enableAutomaticTesting = true,
        enableContinuousValidation = true,
        enableSnapshotComparison = true,
        enablePerformanceRegression = true,
        testTimeout = 30000,
        maxConcurrentTests = 5
    },
    
    -- Baseline management
    baselines = {
        enableBaselineGeneration = true,
        enableBaselineComparison = true,
        enableBaselineUpdates = true,
        snapshotFormat = "json",
        compressionEnabled = true
    },
    
    -- Critical mechanics coverage
    mechanics = {
        player = {
            movement = true,
            actions = true,
            statistics = true,
            progression = true
        },
        game = {
            physics = true,
            scoring = true,
            objectives = true,
            events = true
        },
        ui = {
            interactions = true,
            navigation = true,
            responsiveness = true,
            accessibility = true
        },
        data = {
            persistence = true,
            synchronization = true,
            integrity = true,
            migration = true
        }
    },
    
    -- Performance tracking
    performance = {
        enableMetrics = true,
        enableTrends = true,
        enableAlerts = true,
        thresholdPercentage = 20, -- Alert if 20% regression
        historySize = 100
    },
    
    -- Reporting
    reporting = {
        enableDetailedReports = true,
        enableTrendAnalysis = true,
        enableFailureAnalysis = true,
        generateArtifacts = true
    }
}

-- ========================================
-- REGRESSION TESTING STATE
-- ========================================

local RegressionState = {
    -- Test suites and scenarios
    testSuites = {},
    activeTests = {},
    testHistory = {},
    
    -- Baseline management
    baselines = {},
    snapshots = {},
    
    -- Performance tracking
    performanceHistory = {},
    performanceBaselines = {},
    
    -- Test results
    results = {},
    failures = {},
    regressions = {},
    
    -- Statistics
    stats = {
        testsExecuted = 0,
        regressionsDetected = 0,
        baselinesCreated = 0,
        performanceChecks = 0
    }
}

function RegressionTestingSystem.initialize()
    print("🔄 Initializing RegressionTestingSystem...")
    
    -- Set up test suite management
    RegressionTestingSystem.setupTestSuiteManagement()
    
    -- Initialize baseline management
    RegressionTestingSystem.initializeBaselineManagement()
    
    -- Set up performance regression detection
    RegressionTestingSystem.setupPerformanceRegression()
    
    -- Initialize critical mechanics testing
    RegressionTestingSystem.initializeCriticalMechanicsTesting()
    
    -- Set up automated regression detection
    RegressionTestingSystem.setupAutomatedRegressionDetection()
    
    print("🔄 RegressionTestingSystem initialized successfully")
end

-- ========================================
-- TEST SUITE MANAGEMENT
-- ========================================

function RegressionTestingSystem.setupTestSuiteManagement()
    RegressionState.testSuiteManager = {
        suites = {},
        scenarios = {},
        execution = {}
    }
    
    print("📝 Test suite management initialized")
end

function RegressionTestingSystem.createTestSuite(name, config)
    config = config or {}
    
    local testSuite = {
        name = name,
        description = config.description or "",
        category = config.category or "general",
        priority = config.priority or "medium",
        scenarios = {},
        baselines = {},
        enabled = config.enabled ~= false,
        metadata = {
            createdAt = tick(),
            version = config.version or "1.0.0",
            author = config.author or "System"
        },
        configuration = {
            timeout = config.timeout or REGRESSION_CONFIG.execution.testTimeout,
            retries = config.retries or 3,
            parallel = config.parallel or false,
            isolation = config.isolation or true
        }
    }
    
    RegressionState.testSuites[name] = testSuite
    return testSuite
end

function RegressionTestingSystem.addTestScenario(suiteName, scenarioName, testFunction, config)
    local testSuite = RegressionState.testSuites[suiteName]
    if not testSuite then
        error(string.format("Test suite '%s' not found", suiteName))
    end
    
    config = config or {}
    
    local scenario = {
        name = scenarioName,
        description = config.description or "",
        testFunction = testFunction,
        enabled = config.enabled ~= false,
        critical = config.critical or false,
        baseline = config.baseline,
        validation = config.validation,
        setup = config.setup,
        teardown = config.teardown,
        metadata = {
            createdAt = tick(),
            tags = config.tags or {},
            dependencies = config.dependencies or {}
        }
    }
    
    testSuite.scenarios[scenarioName] = scenario
    return scenario
end

function RegressionTestingSystem.executeTestSuite(suiteName, options)
    local testSuite = RegressionState.testSuites[suiteName]
    if not testSuite then
        error(string.format("Test suite '%s' not found", suiteName))
    end
    
    options = options or {}
    
    local execution = {
        suiteId = suiteName,
        startTime = tick(),
        endTime = nil,
        status = "running",
        results = {},
        regressions = {},
        performance = {},
        artifacts = {}
    }
    
    print(string.format("🔄 Executing test suite: %s", suiteName))
    
    -- Execute scenarios
    for scenarioName, scenario in pairs(testSuite.scenarios) do
        if scenario.enabled then
            local result = RegressionTestingSystem.executeTestScenario(testSuite, scenario, options)
            execution.results[scenarioName] = result
            
            -- Check for regressions
            if result.regression then
                execution.regressions[scenarioName] = result.regression
                RegressionState.stats.regressionsDetected = RegressionState.stats.regressionsDetected + 1
            end
            
            RegressionState.stats.testsExecuted = RegressionState.stats.testsExecuted + 1
        end
    end
    
    execution.endTime = tick()
    execution.duration = execution.endTime - execution.startTime
    execution.status = "completed"
    
    -- Store execution results
    if not RegressionState.testHistory[suiteName] then
        RegressionState.testHistory[suiteName] = {}
    end
    table.insert(RegressionState.testHistory[suiteName], execution)
    
    print(string.format("✅ Test suite '%s' completed in %.2fs", suiteName, execution.duration))
    
    return execution
end

function RegressionTestingSystem.executeTestScenario(testSuite, scenario, options)
    local result = {
        name = scenario.name,
        startTime = tick(),
        endTime = nil,
        status = "running",
        success = false,
        output = nil,
        error = nil,
        baseline = nil,
        snapshot = nil,
        regression = nil,
        performance = {}
    }
    
    print(string.format("  📋 Executing scenario: %s", scenario.name))
    
    -- Setup phase
    if scenario.setup then
        local setupSuccess, setupError = pcall(scenario.setup)
        if not setupSuccess then
            result.status = "setup_failed"
            result.error = setupError
            result.endTime = tick()
            return result
        end
    end
    
    -- Execute test function
    local testSuccess, testOutput = pcall(scenario.testFunction)
    result.success = testSuccess
    result.output = testOutput
    
    if not testSuccess then
        result.status = "failed"
        result.error = testOutput
    else
        result.status = "passed"
        
        -- Create snapshot for baseline comparison
        if scenario.baseline then
            result.snapshot = RegressionTestingSystem.createSnapshot(testOutput, scenario.baseline)
            
            -- Compare with baseline
            local regression = RegressionTestingSystem.compareWithBaseline(
                testSuite.name, 
                scenario.name, 
                result.snapshot
            )
            result.regression = regression
        end
        
        -- Performance validation
        if scenario.validation and scenario.validation.performance then
            result.performance = RegressionTestingSystem.validatePerformance(
                testSuite.name,
                scenario.name,
                testOutput
            )
        end
    end
    
    -- Teardown phase
    if scenario.teardown then
        pcall(scenario.teardown)
    end
    
    result.endTime = tick()
    result.duration = result.endTime - result.startTime
    
    return result
end

-- ========================================
-- BASELINE MANAGEMENT
-- ========================================

function RegressionTestingSystem.initializeBaselineManagement()
    RegressionState.baselineManager = {
        baselines = {},
        snapshots = {},
        storage = {}
    }
    
    print("📊 Baseline management initialized")
end

function RegressionTestingSystem.createSnapshot(data, config)
    config = config or {}
    
    local snapshot = {
        data = data,
        timestamp = tick(),
        checksum = RegressionTestingSystem.calculateChecksum(data),
        metadata = {
            type = config.type or "full",
            filters = config.filters or {},
            precision = config.precision or "default"
        }
    }
    
    if config.filters and #config.filters > 0 then
        snapshot.data = RegressionTestingSystem.applyFilters(data, config.filters)
    end
    
    return snapshot
end

function RegressionTestingSystem.saveBaseline(suiteName, scenarioName, snapshot)
    local baselineKey = string.format("%s.%s", suiteName, scenarioName)
    
    RegressionState.baselines[baselineKey] = {
        snapshot = snapshot,
        createdAt = tick(),
        version = "1.0.0"
    }
    
    RegressionState.stats.baselinesCreated = RegressionState.stats.baselinesCreated + 1
    
    print(string.format("💾 Baseline saved for %s", baselineKey))
end

function RegressionTestingSystem.getBaseline(suiteName, scenarioName)
    local baselineKey = string.format("%s.%s", suiteName, scenarioName)
    return RegressionState.baselines[baselineKey]
end

function RegressionTestingSystem.compareWithBaseline(suiteName, scenarioName, currentSnapshot)
    local baseline = RegressionTestingSystem.getBaseline(suiteName, scenarioName)
    if not baseline then
        -- No baseline exists, save current as baseline
        RegressionTestingSystem.saveBaseline(suiteName, scenarioName, currentSnapshot)
        return nil
    end
    
    local comparison = {
        hasRegression = false,
        differences = {},
        similarity = 0,
        analysis = {}
    }
    
    -- Compare checksums first
    if baseline.snapshot.checksum ~= currentSnapshot.checksum then
        comparison.hasRegression = true
        
        -- Detailed comparison
        comparison.differences = RegressionTestingSystem.calculateDifferences(
            baseline.snapshot.data,
            currentSnapshot.data
        )
        
        comparison.similarity = RegressionTestingSystem.calculateSimilarity(
            baseline.snapshot.data,
            currentSnapshot.data
        )
        
        comparison.analysis = RegressionTestingSystem.analyzeRegression(comparison.differences)
    else
        comparison.similarity = 1.0
    end
    
    return comparison.hasRegression and comparison or nil
end

function RegressionTestingSystem.calculateChecksum(data)
    local serialized = HttpService:JSONEncode(data)
    local checksum = 0
    
    for i = 1, #serialized do
        checksum = checksum + string.byte(serialized, i)
    end
    
    return checksum
end

function RegressionTestingSystem.calculateDifferences(baseline, current)
    local differences = {}
    
    if type(baseline) ~= type(current) then
        differences.typeChange = {
            from = type(baseline),
            to = type(current)
        }
        return differences
    end
    
    if type(baseline) == "table" then
        -- Compare table properties
        for key, value in pairs(baseline) do
            if current[key] == nil then
                differences[key] = {type = "removed", value = value}
            elseif not RegressionTestingSystem.deepEqual(value, current[key]) then
                differences[key] = {
                    type = "changed",
                    from = value,
                    to = current[key]
                }
            end
        end
        
        for key, value in pairs(current) do
            if baseline[key] == nil then
                differences[key] = {type = "added", value = value}
            end
        end
    else
        if baseline ~= current then
            differences.value = {
                type = "changed",
                from = baseline,
                to = current
            }
        end
    end
    
    return differences
end

function RegressionTestingSystem.calculateSimilarity(baseline, current)
    if type(baseline) ~= type(current) then
        return 0
    end
    
    if type(baseline) ~= "table" then
        return baseline == current and 1 or 0
    end
    
    local totalKeys = 0
    local matchingKeys = 0
    
    -- Count all unique keys
    local allKeys = {}
    for key in pairs(baseline) do
        allKeys[key] = true
    end
    for key in pairs(current) do
        allKeys[key] = true
    end
    
    for key in pairs(allKeys) do
        totalKeys = totalKeys + 1
        if RegressionTestingSystem.deepEqual(baseline[key], current[key]) then
            matchingKeys = matchingKeys + 1
        end
    end
    
    return totalKeys > 0 and (matchingKeys / totalKeys) or 1
end

function RegressionTestingSystem.analyzeRegression(differences)
    local analysis = {
        severity = "low",
        categories = {},
        recommendations = {}
    }
    
    local changeCount = 0
    for key, diff in pairs(differences) do
        changeCount = changeCount + 1
        
        if diff.type == "removed" then
            analysis.categories.removals = (analysis.categories.removals or 0) + 1
        elseif diff.type == "added" then
            analysis.categories.additions = (analysis.categories.additions or 0) + 1
        elseif diff.type == "changed" then
            analysis.categories.modifications = (analysis.categories.modifications or 0) + 1
        end
    end
    
    -- Determine severity
    if changeCount > 10 then
        analysis.severity = "critical"
    elseif changeCount > 5 then
        analysis.severity = "high"
    elseif changeCount > 2 then
        analysis.severity = "medium"
    end
    
    -- Generate recommendations
    if analysis.categories.removals and analysis.categories.removals > 0 then
        table.insert(analysis.recommendations, "Review removed functionality for potential breaking changes")
    end
    
    if analysis.categories.additions and analysis.categories.additions > 3 then
        table.insert(analysis.recommendations, "Verify new functionality doesn't impact existing features")
    end
    
    return analysis
end

-- ========================================
-- PERFORMANCE REGRESSION DETECTION
-- ========================================

function RegressionTestingSystem.setupPerformanceRegression()
    RegressionState.performanceRegression = {
        metrics = {},
        baselines = {},
        history = {},
        alerts = {}
    }
    
    print("📈 Performance regression detection initialized")
end

function RegressionTestingSystem.recordPerformanceMetric(testKey, metricName, value)
    if not RegressionState.performanceHistory[testKey] then
        RegressionState.performanceHistory[testKey] = {}
    end
    
    if not RegressionState.performanceHistory[testKey][metricName] then
        RegressionState.performanceHistory[testKey][metricName] = {}
    end
    
    local metric = {
        value = value,
        timestamp = tick(),
        trend = nil
    }
    
    local history = RegressionState.performanceHistory[testKey][metricName]
    table.insert(history, metric)
    
    -- Maintain history size limit
    if #history > REGRESSION_CONFIG.performance.historySize then
        table.remove(history, 1)
    end
    
    -- Calculate trend
    if #history >= 2 then
        local previous = history[#history - 1]
        metric.trend = (value - previous.value) / previous.value * 100
    end
    
    RegressionState.stats.performanceChecks = RegressionState.stats.performanceChecks + 1
    
    return metric
end

function RegressionTestingSystem.validatePerformance(suiteName, scenarioName, testOutput)
    local testKey = string.format("%s.%s", suiteName, scenarioName)
    local performance = {
        metrics = {},
        regressions = {},
        trends = {}
    }
    
    if testOutput and testOutput.performance then
        for metricName, value in pairs(testOutput.performance) do
            local metric = RegressionTestingSystem.recordPerformanceMetric(testKey, metricName, value)
            performance.metrics[metricName] = metric
            
            -- Check for regression
            local regression = RegressionTestingSystem.checkPerformanceRegression(testKey, metricName, value)
            if regression then
                performance.regressions[metricName] = regression
            end
        end
    end
    
    return performance
end

function RegressionTestingSystem.checkPerformanceRegression(testKey, metricName, currentValue)
    local history = RegressionState.performanceHistory[testKey] and 
                   RegressionState.performanceHistory[testKey][metricName]
    
    if not history or #history < 5 then
        return nil -- Not enough data for regression analysis
    end
    
    -- Calculate baseline (average of last 5 values excluding current)
    local baseline = 0
    local count = 0
    for i = math.max(1, #history - 5), #history - 1 do
        baseline = baseline + history[i].value
        count = count + 1
    end
    baseline = baseline / count
    
    -- Check for regression
    local regressionPercentage = (currentValue - baseline) / baseline * 100
    
    if math.abs(regressionPercentage) > REGRESSION_CONFIG.performance.thresholdPercentage then
        return {
            type = regressionPercentage > 0 and "degradation" or "improvement",
            percentage = regressionPercentage,
            baseline = baseline,
            current = currentValue,
            severity = math.abs(regressionPercentage) > 50 and "critical" or "warning"
        }
    end
    
    return nil
end

-- ========================================
-- CRITICAL MECHANICS TESTING
-- ========================================

function RegressionTestingSystem.initializeCriticalMechanicsTesting()
    -- Set up predefined test suites for critical game mechanics
    RegressionTestingSystem.setupPlayerMechanicsTests()
    RegressionTestingSystem.setupGameMechanicsTests()
    RegressionTestingSystem.setupUIMechanicsTests()
    RegressionTestingSystem.setupDataMechanicsTests()
    
    print("🎮 Critical mechanics testing initialized")
end

function RegressionTestingSystem.setupPlayerMechanicsTests()
    local playerSuite = RegressionTestingSystem.createTestSuite("PlayerMechanics", {
        description = "Core player functionality and behavior",
        category = "critical",
        priority = "high"
    })
    
    -- Player movement regression test
    RegressionTestingSystem.addTestScenario("PlayerMechanics", "MovementSystem", function()
        -- Simulate player movement
        local movementData = {
            walkSpeed = 16,
            jumpPower = 50,
            acceleration = 1.2,
            friction = 0.8,
            airControl = 0.9
        }
        
        -- Performance tracking
        local startTime = tick()
        -- Simulate movement calculations
        for i = 1, 1000 do
            local velocity = movementData.walkSpeed * movementData.acceleration
        end
        local endTime = tick()
        
        return {
            mechanics = movementData,
            performance = {
                calculationTime = (endTime - startTime) * 1000,
                memoryUsage = collectgarbage("count")
            }
        }
    end, {
        baseline = {type = "full"},
        validation = {performance = true},
        critical = true
    })
    
    -- Player actions regression test
    RegressionTestingSystem.addTestScenario("PlayerMechanics", "ActionSystem", function()
        local actionData = {
            actions = {"jump", "run", "slide", "interact"},
            cooldowns = {jump = 0.5, run = 0, slide = 2.0, interact = 0.1},
            combinations = {
                {"run", "jump"},
                {"run", "slide"},
                {"jump", "interact"}
            }
        }
        
        return {
            mechanics = actionData,
            performance = {
                memoryUsage = collectgarbage("count")
            }
        }
    end, {
        baseline = {type = "full"},
        critical = true
    })
end

function RegressionTestingSystem.setupGameMechanicsTests()
    local gameSuite = RegressionTestingSystem.createTestSuite("GameMechanics", {
        description = "Core game systems and logic",
        category = "critical",
        priority = "high"
    })
    
    -- Scoring system regression test
    RegressionTestingSystem.addTestScenario("GameMechanics", "ScoringSystem", function()
        local scoreData = {
            basePoints = 10,
            multipliers = {distance = 1.5, time = 2.0, combo = 3.0},
            bonuses = {perfect = 100, streak = 50},
            calculations = {}
        }
        
        -- Simulate scoring calculations
        for i = 1, 10 do
            local score = scoreData.basePoints * scoreData.multipliers.distance
            table.insert(scoreData.calculations, score)
        end
        
        return {
            mechanics = scoreData,
            performance = {
                memoryUsage = collectgarbage("count")
            }
        }
    end, {
        baseline = {type = "full"},
        validation = {performance = true},
        critical = true
    })
    
    -- Physics system regression test
    RegressionTestingSystem.addTestScenario("GameMechanics", "PhysicsSystem", function()
        local physicsData = {
            gravity = Vector3.new(0, -196.2, 0),
            friction = 0.5,
            restitution = 0.3,
            airDensity = 1.225,
            collisionDetection = "continuous"
        }
        
        return {
            mechanics = physicsData,
            performance = {
                memoryUsage = collectgarbage("count")
            }
        }
    end, {
        baseline = {type = "full"},
        critical = true
    })
end

function RegressionTestingSystem.setupUIMechanicsTests()
    local uiSuite = RegressionTestingSystem.createTestSuite("UIMechanics", {
        description = "User interface systems and interactions",
        category = "critical",
        priority = "medium"
    })
    
    -- UI responsiveness test
    RegressionTestingSystem.addTestScenario("UIMechanics", "ResponsivenessTest", function()
        local startTime = tick()
        
        -- Simulate UI operations
        local uiData = {
            elements = 50,
            interactions = 100,
            animations = 25,
            renderTime = 0
        }
        
        -- Simulate rendering
        for i = 1, uiData.elements do
            -- Simulate element processing
            task.wait()
        end
        
        local endTime = tick()
        uiData.renderTime = (endTime - startTime) * 1000
        
        return {
            mechanics = uiData,
            performance = {
                renderTime = uiData.renderTime,
                memoryUsage = collectgarbage("count")
            }
        }
    end, {
        baseline = {type = "full"},
        validation = {performance = true},
        critical = true
    })
end

function RegressionTestingSystem.setupDataMechanicsTests()
    local dataSuite = RegressionTestingSystem.createTestSuite("DataMechanics", {
        description = "Data persistence and synchronization",
        category = "critical",
        priority = "high"
    })
    
    -- Data integrity test
    RegressionTestingSystem.addTestScenario("DataMechanics", "DataIntegrityTest", function()
        local dataStructure = {
            player = {
                userId = 12345,
                stats = {level = 5, exp = 1250, currency = 500},
                settings = {music = true, effects = true},
                inventory = {"item1", "item2", "item3"}
            },
            validation = {
                checksums = {},
                timestamps = {},
                versions = {}
            }
        }
        
        -- Calculate checksums for validation
        dataStructure.validation.checksums.player = RegressionTestingSystem.calculateChecksum(dataStructure.player)
        dataStructure.validation.timestamps.created = tick()
        dataStructure.validation.versions.format = "1.0.0"
        
        return {
            mechanics = dataStructure,
            performance = {
                memoryUsage = collectgarbage("count")
            }
        }
    end, {
        baseline = {type = "full"},
        critical = true
    })
end

-- ========================================
-- AUTOMATED REGRESSION DETECTION
-- ========================================

function RegressionTestingSystem.setupAutomatedRegressionDetection()
    RegressionState.automatedDetection = {
        enabled = true,
        schedule = {},
        triggers = {},
        notifications = {}
    }
    
    if REGRESSION_CONFIG.execution.enableContinuousValidation then
        RegressionTestingSystem.startContinuousValidation()
    end
    
    print("🤖 Automated regression detection initialized")
end

function RegressionTestingSystem.startContinuousValidation()
    spawn(function()
        while RegressionState.automatedDetection.enabled do
            -- Run critical test suites periodically
            for suiteName, testSuite in pairs(RegressionState.testSuites) do
                if testSuite.category == "critical" then
                    local result = RegressionTestingSystem.executeTestSuite(suiteName)
                    
                    if next(result.regressions) then
                        RegressionTestingSystem.handleRegressionAlert(suiteName, result.regressions)
                    end
                end
            end
            
            task.wait(300) -- Run every 5 minutes
        end
    end)
end

function RegressionTestingSystem.handleRegressionAlert(suiteName, regressions)
    local alert = {
        timestamp = tick(),
        suite = suiteName,
        regressions = regressions,
        severity = "medium"
    }
    
    -- Determine alert severity
    for scenarioName, regression in pairs(regressions) do
        if regression.analysis and regression.analysis.severity == "critical" then
            alert.severity = "critical"
            break
        elseif regression.analysis and regression.analysis.severity == "high" then
            alert.severity = "high"
        end
    end
    
    table.insert(RegressionState.automatedDetection.notifications, alert)
    
    print(string.format("🚨 Regression alert for suite '%s' (Severity: %s)", suiteName, alert.severity))
    for scenarioName, regression in pairs(regressions) do
        print(string.format("  - %s: %d differences detected", scenarioName, 
            regression.differences and #regression.differences or 0))
    end
end

-- ========================================
-- UTILITY FUNCTIONS
-- ========================================

function RegressionTestingSystem.deepEqual(a, b)
    if type(a) ~= type(b) then
        return false
    end
    
    if type(a) == "table" then
        for key, value in pairs(a) do
            if not RegressionTestingSystem.deepEqual(value, b[key]) then
                return false
            end
        end
        
        for key, value in pairs(b) do
            if a[key] == nil then
                return false
            end
        end
        
        return true
    else
        return a == b
    end
end

function RegressionTestingSystem.applyFilters(data, filters)
    local filtered = data
    
    for _, filter in ipairs(filters) do
        if filter.type == "exclude" then
            -- Remove specified keys
            for _, key in ipairs(filter.keys) do
                filtered[key] = nil
            end
        elseif filter.type == "include" then
            -- Keep only specified keys
            local newFiltered = {}
            for _, key in ipairs(filter.keys) do
                newFiltered[key] = filtered[key]
            end
            filtered = newFiltered
        end
    end
    
    return filtered
end

-- ========================================
-- PUBLIC API
-- ========================================

function RegressionTestingSystem.runRegressionTestingDemo()
    print("🔄 Running regression testing demonstration...")
    
    -- Execute critical mechanics tests
    print("  🎮 Testing critical game mechanics...")
    
    local playerResults = RegressionTestingSystem.executeTestSuite("PlayerMechanics")
    print(string.format("    Player mechanics: %d scenarios, %d regressions", 
        #playerResults.results, #playerResults.regressions))
    
    local gameResults = RegressionTestingSystem.executeTestSuite("GameMechanics")
    print(string.format("    Game mechanics: %d scenarios, %d regressions", 
        #gameResults.results, #gameResults.regressions))
    
    local uiResults = RegressionTestingSystem.executeTestSuite("UIMechanics")
    print(string.format("    UI mechanics: %d scenarios, %d regressions", 
        #uiResults.results, #uiResults.regressions))
    
    local dataResults = RegressionTestingSystem.executeTestSuite("DataMechanics")
    print(string.format("    Data mechanics: %d scenarios, %d regressions", 
        #dataResults.results, #dataResults.regressions))
    
    -- Demonstrate baseline comparison
    print("  📊 Testing baseline comparison...")
    local testSnapshot = RegressionTestingSystem.createSnapshot({
        version = "2.0.0",
        features = {"feature1", "feature2", "newFeature"},
        performance = {loadTime = 1.5, memoryUsage = 100}
    })
    
    -- Save as baseline
    RegressionTestingSystem.saveBaseline("Demo", "FeatureTest", testSnapshot)
    
    -- Test with modification
    local modifiedSnapshot = RegressionTestingSystem.createSnapshot({
        version = "2.1.0",
        features = {"feature1", "feature2", "newFeature", "anotherFeature"},
        performance = {loadTime = 1.8, memoryUsage = 120}
    })
    
    local regression = RegressionTestingSystem.compareWithBaseline("Demo", "FeatureTest", modifiedSnapshot)
    if regression then
        print(string.format("    Regression detected: %.1f%% similarity", regression.similarity * 100))
    else
        print("    No regression detected")
    end
    
    print("🔄 Regression testing demonstration completed")
end

function RegressionTestingSystem.generateRegressionReport()
    local report = {
        timestamp = tick(),
        summary = {
            totalTests = RegressionState.stats.testsExecuted,
            totalRegressions = RegressionState.stats.regressionsDetected,
            totalBaselines = RegressionState.stats.baselinesCreated,
            performanceChecks = RegressionState.stats.performanceChecks
        },
        suites = {},
        regressions = {},
        performance = {}
    }
    
    -- Collect suite information
    for suiteName, suite in pairs(RegressionState.testSuites) do
        report.suites[suiteName] = {
            enabled = suite.enabled,
            scenarioCount = 0,
            category = suite.category,
            priority = suite.priority
        }
        
        for scenarioName, scenario in pairs(suite.scenarios) do
            report.suites[suiteName].scenarioCount = report.suites[suiteName].scenarioCount + 1
        end
    end
    
    -- Collect regression information
    for testKey, regressions in pairs(RegressionState.regressions) do
        report.regressions[testKey] = regressions
    end
    
    return report
end

function RegressionTestingSystem.getRegressionStats()
    return RegressionState.stats
end

function RegressionTestingSystem.getAllTestSuites()
    return RegressionState.testSuites
end

function RegressionTestingSystem.getTestHistory(suiteName)
    return RegressionState.testHistory[suiteName] or {}
end

-- Export API
RegressionTestingSystem.createTestSuite = RegressionTestingSystem.createTestSuite
RegressionTestingSystem.addTestScenario = RegressionTestingSystem.addTestScenario
RegressionTestingSystem.executeTestSuite = RegressionTestingSystem.executeTestSuite
RegressionTestingSystem.createSnapshot = RegressionTestingSystem.createSnapshot
RegressionTestingSystem.saveBaseline = RegressionTestingSystem.saveBaseline
RegressionTestingSystem.compareWithBaseline = RegressionTestingSystem.compareWithBaseline
RegressionTestingSystem.recordPerformanceMetric = RegressionTestingSystem.recordPerformanceMetric
RegressionTestingSystem.generateRegressionReport = RegressionTestingSystem.generateRegressionReport

-- Initialize the regression testing system
RegressionTestingSystem.initialize()

print("🔄 RegressionTestingSystem loaded with comprehensive regression validation")

return RegressionTestingSystem
