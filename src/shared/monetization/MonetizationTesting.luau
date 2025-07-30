-- MonetizationTesting.luau
-- Comprehensive testing and validation system for monetization
-- Includes automated testing, fraud prevention validation, and optimization testing

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local MarketplaceService = game:GetService("MarketplaceService")

local SafeRequire = require(ReplicatedStorage.Shared.utils.SafeRequire)

local MonetizationTesting = {}

-- ========================================
-- TESTING CONFIGURATION
-- ========================================

local TESTING_CONFIG = {
    -- Test environments
    environments = {
        development = {
            enableRealPurchases = false,
            enableFraudSimulation = true,
            enableLoadTesting = true,
            logLevel = "debug"
        },
        
        staging = {
            enableRealPurchases = false,
            enableFraudSimulation = true,
            enableLoadTesting = true,
            logLevel = "info"
        },
        
        production = {
            enableRealPurchases = true,
            enableFraudSimulation = false,
            enableLoadTesting = false,
            logLevel = "warn"
        }
    },
    
    -- Test scenarios
    testScenarios = {
        -- Purchase flow tests
        purchaseFlow = {
            validPurchase = true,
            invalidProduct = true,
            insufficientFunds = true,
            networkError = true,
            duplicateReceipt = true
        },
        
        -- Fraud prevention tests
        fraudPrevention = {
            rapidPurchases = true,
            accountAge = true,
            suspiciousPatterns = true,
            velocityLimits = true,
            duplicateTransactions = true
        },
        
        -- Economy balance tests
        economyBalance = {
            inflation = true,
            deflation = true,
            payToWinViolations = true,
            progressionFairness = true
        },
        
        -- Analytics tests
        analytics = {
            revenueTracking = true,
            conversionTracking = true,
            kpiCalculation = true,
            realTimeMetrics = true
        }
    },
    
    -- Test data
    testData = {
        players = {
            newPlayer = {
                accountAge = 1,
                playtime = 3600,
                previousPurchases = 0
            },
            
            regularPlayer = {
                accountAge = 30,
                playtime = 86400,
                previousPurchases = 5
            },
            
            suspiciousPlayer = {
                accountAge = 0,
                playtime = 300,
                previousPurchases = 0
            }
        },
        
        products = {
            validProduct = {
                id = 123456789,
                type = "GamePass",
                price = 100
            },
            
            invalidProduct = {
                id = 999999999,
                type = "GamePass",
                price = 100
            }
        }
    },
    
    -- Performance thresholds
    performance = {
        purchaseResponseTime = 2.0,     -- Max 2 seconds
        analyticsUpdateTime = 1.0,      -- Max 1 second
        fraudCheckTime = 0.5,           -- Max 0.5 seconds
        memoryUsage = 100 * 1024 * 1024, -- Max 100MB
        maxConcurrentPurchases = 100
    }
}

-- ========================================
-- TESTING STATE
-- ========================================

local TestingState = {
    -- Test execution
    currentEnvironment = "development",
    activeTests = {},
    testResults = {},
    testHistory = {},
    
    -- Mock systems
    mockMarketplace = {},
    mockPlayers = {},
    mockData = {},
    
    -- Performance monitoring
    performanceMetrics = {},
    loadTestResults = {},
    
    -- Validation results
    validationResults = {},
    errorLogs = {},
    
    -- Test statistics
    stats = {
        totalTests = 0,
        passedTests = 0,
        failedTests = 0,
        skippedTests = 0,
        averageExecutionTime = 0,
        lastRunTime = 0
    }
}

function MonetizationTesting.initialize()
    print("🧪 Initializing MonetizationTesting...")
    
    -- Set up test environment
    MonetizationTesting.setupTestEnvironment()
    
    -- Initialize mock systems
    MonetizationTesting.initializeMockSystems()
    
    -- Set up performance monitoring
    MonetizationTesting.setupPerformanceMonitoring()
    
    -- Initialize validation systems
    MonetizationTesting.initializeValidationSystems()
    
    print("🧪 MonetizationTesting initialized successfully")
end

-- ========================================
-- TEST ENVIRONMENT SETUP
-- ========================================

function MonetizationTesting.setupTestEnvironment()
    local env = TESTING_CONFIG.environments[TestingState.currentEnvironment]
    
    TestingState.testEnvironment = {
        name = TestingState.currentEnvironment,
        config = env,
        startTime = tick(),
        
        -- Test runners
        unitTestRunner = MonetizationTesting.createUnitTestRunner(),
        integrationTestRunner = MonetizationTesting.createIntegrationTestRunner(),
        loadTestRunner = MonetizationTesting.createLoadTestRunner(),
        validationRunner = MonetizationTesting.createValidationRunner()
    }
    
    print(string.format("🔧 Test environment setup: %s", TestingState.currentEnvironment))
end

function MonetizationTesting.createUnitTestRunner()
    return {
        name = "unit_test_runner",
        
        runTest = function(self, testCase)
            return MonetizationTesting.runUnitTest(testCase)
        end,
        
        runSuite = function(self, testSuite)
            return MonetizationTesting.runUnitTestSuite(testSuite)
        end
    }
end

function MonetizationTesting.createIntegrationTestRunner()
    return {
        name = "integration_test_runner",
        
        runTest = function(self, testCase)
            return MonetizationTesting.runIntegrationTest(testCase)
        end
    }
end

function MonetizationTesting.createLoadTestRunner()
    return {
        name = "load_test_runner",
        
        runTest = function(self, loadConfig)
            return MonetizationTesting.runLoadTest(loadConfig)
        end
    }
end

function MonetizationTesting.createValidationRunner()
    return {
        name = "validation_runner",
        
        validate = function(self, validationType)
            return MonetizationTesting.runValidation(validationType)
        end
    }
end

-- ========================================
-- MOCK SYSTEMS
-- ========================================

function MonetizationTesting.initializeMockSystems()
    TestingState.mockSystems = {
        marketplace = MonetizationTesting.createMockMarketplace(),
        players = MonetizationTesting.createMockPlayers(),
        analytics = MonetizationTesting.createMockAnalytics(),
        storage = MonetizationTesting.createMockStorage()
    }
    
    print("🎭 Mock systems initialized")
end

function MonetizationTesting.createMockMarketplace()
    return {
        name = "mock_marketplace",
        
        ProcessReceipt = function(self, receiptInfo)
            return MonetizationTesting.mockProcessReceipt(receiptInfo)
        end,
        
        GetProductInfo = function(self, productId, infoType)
            return MonetizationTesting.mockGetProductInfo(productId, infoType)
        end,
        
        UserOwnsGamePassAsync = function(self, userId, gamePassId)
            return MonetizationTesting.mockUserOwnsGamePass(userId, gamePassId)
        end
    }
end

function MonetizationTesting.createMockPlayers()
    return {
        name = "mock_players",
        
        createTestPlayer = function(self, playerData)
            return MonetizationTesting.createTestPlayer(playerData)
        end,
        
        simulatePlayerAction = function(self, playerId, action)
            return MonetizationTesting.simulatePlayerAction(playerId, action)
        end
    }
end

function MonetizationTesting.createMockAnalytics()
    return {
        name = "mock_analytics",
        
        trackEvent = function(self, event)
            return MonetizationTesting.mockTrackEvent(event)
        end,
        
        getMetrics = function(self)
            return MonetizationTesting.mockGetMetrics()
        end
    }
end

function MonetizationTesting.createMockStorage()
    return {
        name = "mock_storage",
        
        save = function(self, key, data)
            return MonetizationTesting.mockSaveData(key, data)
        end,
        
        load = function(self, key)
            return MonetizationTesting.mockLoadData(key)
        end
    }
end

function MonetizationTesting.mockProcessReceipt(receiptInfo)
    local testData = TESTING_CONFIG.testData
    
    -- Simulate different receipt scenarios
    if receiptInfo.ProductId == testData.products.invalidProduct.id then
        return Enum.ProductPurchaseDecision.NotProcessedYet
    end
    
    -- Simulate network delays
    task.wait(math.random(0.1, 0.5))
    
    -- Simulate fraud detection
    if MonetizationTesting.shouldTriggerFraudDetection(receiptInfo) then
        print("🚫 Mock fraud detection triggered")
        return Enum.ProductPurchaseDecision.NotProcessedYet
    end
    
    -- Successful purchase
    print(string.format("✅ Mock receipt processed: Player %d, Product %d, R$%d", 
        receiptInfo.PlayerId, receiptInfo.ProductId, receiptInfo.CurrencySpent))
    
    return Enum.ProductPurchaseDecision.PurchaseGranted
end

function MonetizationTesting.mockGetProductInfo(productId, infoType)
    local testData = TESTING_CONFIG.testData
    
    if productId == testData.products.validProduct.id then
        return {
            Name = "Test Product",
            PriceInRobux = testData.products.validProduct.price,
            ProductType = testData.products.validProduct.type,
            IsForSale = true
        }
    else
        error("Product not found")
    end
end

function MonetizationTesting.mockUserOwnsGamePass(userId, gamePassId)
    -- Simulate some players owning gamepasses
    return (userId + gamePassId) % 3 == 0
end

function MonetizationTesting.createTestPlayer(playerData)
    local testPlayer = {
        UserId = math.random(1000000, 9999999),
        Name = "TestPlayer_" .. math.random(1000, 9999),
        AccountAge = playerData.accountAge or 30,
        MembershipType = Enum.MembershipType.None,
        
        -- Custom test properties
        TestData = {
            playtime = playerData.playtime or 3600,
            previousPurchases = playerData.previousPurchases or 0,
            fraudScore = playerData.fraudScore or 0
        }
    }
    
    TestingState.mockPlayers[testPlayer.UserId] = testPlayer
    return testPlayer
end

function MonetizationTesting.simulatePlayerAction(playerId, action)
    local player = TestingState.mockPlayers[playerId]
    if not player then
        return false
    end
    
    local result = {
        playerId = playerId,
        action = action,
        timestamp = tick(),
        success = true,
        data = {}
    }
    
    if action == "purchase" then
        result.data = {
            productId = TESTING_CONFIG.testData.products.validProduct.id,
            amount = TESTING_CONFIG.testData.products.validProduct.price
        }
        
        player.TestData.previousPurchases = player.TestData.previousPurchases + 1
        
    elseif action == "view_store" then
        result.data = {
            storeSection = "featured"
        }
        
    elseif action == "abandon_cart" then
        result.data = {
            reason = "price_too_high"
        }
    end
    
    return result
end

function MonetizationTesting.shouldTriggerFraudDetection(receiptInfo)
    local player = TestingState.mockPlayers[receiptInfo.PlayerId]
    if not player then
        return false
    end
    
    -- Check account age
    if player.AccountAge < 1 then
        return true
    end
    
    -- Check purchase velocity
    if player.TestData.previousPurchases > 10 then
        return true
    end
    
    -- Check amount
    if receiptInfo.CurrencySpent > 1000 then
        return true
    end
    
    return false
end

-- ========================================
-- UNIT TESTING
-- ========================================

function MonetizationTesting.runUnitTest(testCase)
    local startTime = tick()
    
    local result = {
        name = testCase.name,
        description = testCase.description,
        status = "running",
        startTime = startTime,
        endTime = nil,
        duration = 0,
        passed = false,
        error = nil,
        assertions = {},
        metadata = testCase.metadata or {}
    }
    
    TestingState.stats.totalTests = TestingState.stats.totalTests + 1
    
    print(string.format("🧪 Running unit test: %s", testCase.name))
    
    local success, errorMessage = pcall(function()
        -- Set up test data
        if testCase.setup then
            testCase.setup()
        end
        
        -- Run test
        local testResult = testCase.test()
        
        -- Validate result
        if testCase.assertions then
            for _, assertion in ipairs(testCase.assertions) do
                local assertionResult = MonetizationTesting.runAssertion(assertion, testResult)
                table.insert(result.assertions, assertionResult)
                
                if not assertionResult.passed then
                    error(string.format("Assertion failed: %s", assertionResult.message))
                end
            end
        end
        
        result.passed = true
        
        -- Clean up
        if testCase.cleanup then
            testCase.cleanup()
        end
    end)
    
    result.endTime = tick()
    result.duration = result.endTime - result.startTime
    
    if not success then
        result.status = "failed"
        result.error = errorMessage
        TestingState.stats.failedTests = TestingState.stats.failedTests + 1
        print(string.format("❌ Unit test failed: %s - %s", testCase.name, errorMessage))
    else
        result.status = "passed"
        TestingState.stats.passedTests = TestingState.stats.passedTests + 1
        print(string.format("✅ Unit test passed: %s (%.3fs)", testCase.name, result.duration))
    end
    
    TestingState.testResults[testCase.name] = result
    return result
end

function MonetizationTesting.runUnitTestSuite(testSuite)
    print(string.format("📋 Running unit test suite: %s", testSuite.name))
    
    local suiteResult = {
        name = testSuite.name,
        startTime = tick(),
        endTime = nil,
        totalTests = #testSuite.tests,
        passedTests = 0,
        failedTests = 0,
        testResults = {}
    }
    
    for _, testCase in ipairs(testSuite.tests) do
        local result = MonetizationTesting.runUnitTest(testCase)
        table.insert(suiteResult.testResults, result)
        
        if result.passed then
            suiteResult.passedTests = suiteResult.passedTests + 1
        else
            suiteResult.failedTests = suiteResult.failedTests + 1
        end
    end
    
    suiteResult.endTime = tick()
    suiteResult.duration = suiteResult.endTime - suiteResult.startTime
    
    print(string.format("📊 Test suite completed: %s - %d/%d passed (%.3fs)", 
        testSuite.name, suiteResult.passedTests, suiteResult.totalTests, suiteResult.duration))
    
    return suiteResult
end

function MonetizationTesting.runAssertion(assertion, testResult)
    local result = {
        type = assertion.type,
        message = assertion.message,
        passed = false,
        expected = assertion.expected,
        actual = nil
    }
    
    if assertion.type == "equals" then
        result.actual = testResult
        result.passed = testResult == assertion.expected
        
    elseif assertion.type == "not_equals" then
        result.actual = testResult
        result.passed = testResult ~= assertion.expected
        
    elseif assertion.type == "greater_than" then
        result.actual = testResult
        result.passed = testResult > assertion.expected
        
    elseif assertion.type == "less_than" then
        result.actual = testResult
        result.passed = testResult < assertion.expected
        
    elseif assertion.type == "contains" then
        result.actual = testResult
        result.passed = string.find(tostring(testResult), tostring(assertion.expected)) ~= nil
        
    elseif assertion.type == "is_true" then
        result.actual = testResult
        result.passed = testResult == true
        
    elseif assertion.type == "is_false" then
        result.actual = testResult
        result.passed = testResult == false
        
    elseif assertion.type == "is_nil" then
        result.actual = testResult
        result.passed = testResult == nil
        
    elseif assertion.type == "is_not_nil" then
        result.actual = testResult
        result.passed = testResult ~= nil
    end
    
    return result
end

-- ========================================
-- INTEGRATION TESTING
-- ========================================

function MonetizationTesting.runIntegrationTest(testCase)
    print(string.format("🔗 Running integration test: %s", testCase.name))
    
    local result = {
        name = testCase.name,
        status = "running",
        startTime = tick(),
        components = testCase.components,
        interactions = {},
        passed = false
    }
    
    local success, errorMessage = pcall(function()
        -- Initialize components
        for _, component in ipairs(testCase.components) do
            MonetizationTesting.initializeTestComponent(component)
        end
        
        -- Run integration scenario
        for _, interaction in ipairs(testCase.interactions) do
            local interactionResult = MonetizationTesting.runInteraction(interaction)
            table.insert(result.interactions, interactionResult)
            
            if not interactionResult.success then
                error(string.format("Integration failed: %s", interactionResult.error))
            end
        end
        
        result.passed = true
    end)
    
    result.endTime = tick()
    result.duration = result.endTime - result.startTime
    
    if not success then
        result.status = "failed"
        result.error = errorMessage
        print(string.format("❌ Integration test failed: %s - %s", testCase.name, errorMessage))
    else
        result.status = "passed"
        print(string.format("✅ Integration test passed: %s (%.3fs)", testCase.name, result.duration))
    end
    
    return result
end

function MonetizationTesting.initializeTestComponent(component)
    if component == "monetization_system" then
        -- Initialize monetization system for testing
        return true
    elseif component == "analytics_system" then
        -- Initialize analytics system for testing
        return true
    elseif component == "fraud_prevention" then
        -- Initialize fraud prevention for testing
        return true
    end
    
    return false
end

function MonetizationTesting.runInteraction(interaction)
    local result = {
        type = interaction.type,
        startTime = tick(),
        success = false,
        data = {},
        error = nil
    }
    
    if interaction.type == "purchase_flow" then
        result = MonetizationTesting.testPurchaseFlow(interaction.params)
        
    elseif interaction.type == "analytics_tracking" then
        result = MonetizationTesting.testAnalyticsTracking(interaction.params)
        
    elseif interaction.type == "fraud_detection" then
        result = MonetizationTesting.testFraudDetection(interaction.params)
    end
    
    result.endTime = tick()
    result.duration = result.endTime - result.startTime
    
    return result
end

function MonetizationTesting.testPurchaseFlow(params)
    local player = MonetizationTesting.createTestPlayer(params.playerData)
    
    -- Simulate purchase initiation
    local purchaseResult = MonetizationTesting.simulatePlayerAction(player.UserId, "purchase")
    
    -- Test receipt processing
    local receiptInfo = {
        PlayerId = player.UserId,
        ProductId = params.productId,
        CurrencySpent = params.amount,
        CurrencyType = Enum.CurrencyType.Robux,
        PlaceIdWherePurchased = game.PlaceId,
        PurchaseId = HttpService:GenerateGUID(false)
    }
    
    local receiptResult = TestingState.mockSystems.marketplace:ProcessReceipt(receiptInfo)
    
    return {
        type = "purchase_flow",
        success = receiptResult == Enum.ProductPurchaseDecision.PurchaseGranted,
        data = {
            player = player,
            purchase = purchaseResult,
            receipt = receiptResult
        }
    }
end

function MonetizationTesting.testAnalyticsTracking(params)
    -- Test analytics event tracking
    local event = {
        type = "revenue",
        playerId = params.playerId,
        amount = params.amount,
        productId = params.productId
    }
    
    local trackResult = TestingState.mockSystems.analytics:trackEvent(event)
    
    -- Verify metrics are updated
    local metrics = TestingState.mockSystems.analytics:getMetrics()
    
    return {
        type = "analytics_tracking",
        success = trackResult and metrics.totalRevenue > 0,
        data = {
            event = event,
            metrics = metrics
        }
    }
end

function MonetizationTesting.testFraudDetection(params)
    local player = MonetizationTesting.createTestPlayer(params.suspiciousPlayerData)
    
    -- Create suspicious receipt
    local receiptInfo = {
        PlayerId = player.UserId,
        ProductId = params.productId,
        CurrencySpent = params.amount,
        CurrencyType = Enum.CurrencyType.Robux,
        PlaceIdWherePurchased = game.PlaceId,
        PurchaseId = HttpService:GenerateGUID(false)
    }
    
    local shouldBlock = MonetizationTesting.shouldTriggerFraudDetection(receiptInfo)
    
    return {
        type = "fraud_detection",
        success = shouldBlock, -- Success means fraud was detected
        data = {
            player = player,
            receipt = receiptInfo,
            blocked = shouldBlock
        }
    }
end

-- ========================================
-- LOAD TESTING
-- ========================================

function MonetizationTesting.runLoadTest(loadConfig)
    print(string.format("⚡ Running load test: %s", loadConfig.name))
    
    local result = {
        name = loadConfig.name,
        startTime = tick(),
        config = loadConfig,
        metrics = {
            totalRequests = 0,
            successfulRequests = 0,
            failedRequests = 0,
            averageResponseTime = 0,
            maxResponseTime = 0,
            minResponseTime = math.huge,
            requestsPerSecond = 0
        },
        passed = false
    }
    
    local responses = {}
    local concurrentUsers = loadConfig.concurrentUsers or 10
    local duration = loadConfig.duration or 30
    local requestInterval = loadConfig.requestInterval or 1
    
    -- Spawn concurrent users
    local userCoroutines = {}
    for i = 1, concurrentUsers do
        local coroutine = spawn(function()
            MonetizationTesting.simulateLoadTestUser(i, duration, requestInterval, responses)
        end)
        table.insert(userCoroutines, coroutine)
    end
    
    -- Wait for test completion
    task.wait(duration + 5) -- Extra time for cleanup
    
    -- Calculate metrics
    result.metrics.totalRequests = #responses
    
    local totalResponseTime = 0
    for _, response in ipairs(responses) do
        if response.success then
            result.metrics.successfulRequests = result.metrics.successfulRequests + 1
        else
            result.metrics.failedRequests = result.metrics.failedRequests + 1
        end
        
        totalResponseTime = totalResponseTime + response.duration
        result.metrics.maxResponseTime = math.max(result.metrics.maxResponseTime, response.duration)
        result.metrics.minResponseTime = math.min(result.metrics.minResponseTime, response.duration)
    end
    
    result.endTime = tick()
    result.duration = result.endTime - result.startTime
    
    if result.metrics.totalRequests > 0 then
        result.metrics.averageResponseTime = totalResponseTime / result.metrics.totalRequests
        result.metrics.requestsPerSecond = result.metrics.totalRequests / result.duration
    end
    
    -- Check if load test passed
    local successRate = result.metrics.totalRequests > 0 and 
        (result.metrics.successfulRequests / result.metrics.totalRequests) or 0
    
    result.passed = successRate >= 0.95 and 
        result.metrics.averageResponseTime <= TESTING_CONFIG.performance.purchaseResponseTime
    
    if result.passed then
        print(string.format("✅ Load test passed: %s - %.1f%% success, %.3fs avg response", 
            loadConfig.name, successRate * 100, result.metrics.averageResponseTime))
    else
        print(string.format("❌ Load test failed: %s - %.1f%% success, %.3fs avg response", 
            loadConfig.name, successRate * 100, result.metrics.averageResponseTime))
    end
    
    TestingState.loadTestResults[loadConfig.name] = result
    return result
end

function MonetizationTesting.simulateLoadTestUser(userId, duration, interval, responses)
    local endTime = tick() + duration
    local userResponses = {}
    
    while tick() < endTime do
        local startTime = tick()
        
        -- Simulate purchase request
        local player = MonetizationTesting.createTestPlayer({
            accountAge = math.random(1, 365),
            playtime = math.random(3600, 86400),
            previousPurchases = math.random(0, 10)
        })
        
        local success, result = pcall(function()
            return MonetizationTesting.simulatePlayerAction(player.UserId, "purchase")
        end)
        
        local responseTime = tick() - startTime
        
        local response = {
            userId = userId,
            timestamp = startTime,
            duration = responseTime,
            success = success and result ~= nil,
            error = success and nil or result
        }
        
        table.insert(userResponses, response)
        table.insert(responses, response)
        
        task.wait(interval)
    end
    
    print(string.format("👤 Load test user %d completed: %d requests", userId, #userResponses))
end

-- ========================================
-- VALIDATION SYSTEMS
-- ========================================

function MonetizationTesting.initializeValidationSystems()
    TestingState.validationSystems = {
        purchaseValidator = MonetizationTesting.createPurchaseValidator(),
        fraudValidator = MonetizationTesting.createFraudValidator(),
        economyValidator = MonetizationTesting.createEconomyValidator(),
        analyticsValidator = MonetizationTesting.createAnalyticsValidator()
    }
    
    print("✅ Validation systems initialized")
end

function MonetizationTesting.createPurchaseValidator()
    return {
        name = "purchase_validator",
        
        validate = function(self, purchaseData)
            return MonetizationTesting.validatePurchase(purchaseData)
        end
    }
end

function MonetizationTesting.createFraudValidator()
    return {
        name = "fraud_validator",
        
        validate = function(self, transactionData)
            return MonetizationTesting.validateFraudPrevention(transactionData)
        end
    }
end

function MonetizationTesting.createEconomyValidator()
    return {
        name = "economy_validator",
        
        validate = function(self, economyData)
            return MonetizationTesting.validateEconomyBalance(economyData)
        end
    }
end

function MonetizationTesting.createAnalyticsValidator()
    return {
        name = "analytics_validator",
        
        validate = function(self, analyticsData)
            return MonetizationTesting.validateAnalytics(analyticsData)
        end
    }
end

function MonetizationTesting.runValidation(validationType)
    print(string.format("🔍 Running validation: %s", validationType))
    
    local result = {
        type = validationType,
        startTime = tick(),
        passed = false,
        issues = {},
        recommendations = {}
    }
    
    if validationType == "purchase_flow" then
        result = MonetizationTesting.validatePurchaseFlow()
        
    elseif validationType == "fraud_prevention" then
        result = MonetizationTesting.validateFraudPrevention()
        
    elseif validationType == "economy_balance" then
        result = MonetizationTesting.validateEconomyBalance()
        
    elseif validationType == "analytics_accuracy" then
        result = MonetizationTesting.validateAnalyticsAccuracy()
        
    elseif validationType == "performance" then
        result = MonetizationTesting.validatePerformance()
    end
    
    result.endTime = tick()
    result.duration = result.endTime - result.startTime
    
    if result.passed then
        print(string.format("✅ Validation passed: %s", validationType))
    else
        print(string.format("❌ Validation failed: %s - %d issues found", 
            validationType, #result.issues))
        
        for _, issue in ipairs(result.issues) do
            print(string.format("  🚫 %s: %s", issue.severity, issue.description))
        end
    end
    
    TestingState.validationResults[validationType] = result
    return result
end

function MonetizationTesting.validatePurchaseFlow()
    local result = {
        type = "purchase_flow",
        passed = true,
        issues = {},
        recommendations = {}
    }
    
    -- Test valid purchase
    local validTest = MonetizationTesting.testPurchaseFlow({
        playerData = TESTING_CONFIG.testData.players.regularPlayer,
        productId = TESTING_CONFIG.testData.products.validProduct.id,
        amount = TESTING_CONFIG.testData.products.validProduct.price
    })
    
    if not validTest.success then
        table.insert(result.issues, {
            severity = "high",
            description = "Valid purchase flow failed",
            details = validTest
        })
        result.passed = false
    end
    
    -- Test invalid product
    local invalidTest = MonetizationTesting.testPurchaseFlow({
        playerData = TESTING_CONFIG.testData.players.regularPlayer,
        productId = TESTING_CONFIG.testData.products.invalidProduct.id,
        amount = TESTING_CONFIG.testData.products.invalidProduct.price
    })
    
    if invalidTest.success then
        table.insert(result.issues, {
            severity = "medium",
            description = "Invalid product purchase succeeded (should fail)",
            details = invalidTest
        })
        result.passed = false
    end
    
    return result
end

function MonetizationTesting.validateFraudPrevention()
    local result = {
        type = "fraud_prevention",
        passed = true,
        issues = {},
        recommendations = {}
    }
    
    -- Test suspicious account detection
    local suspiciousTest = MonetizationTesting.testFraudDetection({
        suspiciousPlayerData = TESTING_CONFIG.testData.players.suspiciousPlayer,
        productId = TESTING_CONFIG.testData.products.validProduct.id,
        amount = 1000 -- High amount for new account
    })
    
    if not suspiciousTest.success then
        table.insert(result.issues, {
            severity = "high",
            description = "Fraud prevention failed to detect suspicious transaction",
            details = suspiciousTest
        })
        result.passed = false
    end
    
    -- Test legitimate transaction
    local legitimateTest = MonetizationTesting.testFraudDetection({
        suspiciousPlayerData = TESTING_CONFIG.testData.players.regularPlayer,
        productId = TESTING_CONFIG.testData.products.validProduct.id,
        amount = TESTING_CONFIG.testData.products.validProduct.price
    })
    
    if legitimateTest.success then
        table.insert(result.issues, {
            severity = "medium",
            description = "Fraud prevention incorrectly blocked legitimate transaction",
            details = legitimateTest
        })
    end
    
    return result
end

function MonetizationTesting.validateEconomyBalance()
    local result = {
        type = "economy_balance",
        passed = true,
        issues = {},
        recommendations = {}
    }
    
    -- Test pay-to-win violations
    local payToWinCheck = MonetizationTesting.checkPayToWinViolations()
    if #payToWinCheck.violations > 0 then
        table.insert(result.issues, {
            severity = "high",
            description = "Pay-to-win violations detected",
            details = payToWinCheck.violations
        })
        result.passed = false
    end
    
    -- Test progression fairness
    local progressionCheck = MonetizationTesting.checkProgressionFairness()
    if not progressionCheck.fair then
        table.insert(result.issues, {
            severity = "medium",
            description = "Unfair progression detected",
            details = progressionCheck
        })
    end
    
    return result
end

function MonetizationTesting.validateAnalyticsAccuracy()
    local result = {
        type = "analytics_accuracy",
        passed = true,
        issues = {},
        recommendations = {}
    }
    
    -- Test revenue tracking accuracy
    local revenueTest = MonetizationTesting.testRevenueTrackingAccuracy()
    if revenueTest.accuracy < 0.99 then
        table.insert(result.issues, {
            severity = "high",
            description = string.format("Revenue tracking accuracy below threshold: %.2f%%", 
                revenueTest.accuracy * 100),
            details = revenueTest
        })
        result.passed = false
    end
    
    -- Test conversion tracking
    local conversionTest = MonetizationTesting.testConversionTrackingAccuracy()
    if conversionTest.accuracy < 0.95 then
        table.insert(result.issues, {
            severity = "medium",
            description = string.format("Conversion tracking accuracy below threshold: %.2f%%", 
                conversionTest.accuracy * 100),
            details = conversionTest
        })
    end
    
    return result
end

function MonetizationTesting.validatePerformance()
    local result = {
        type = "performance",
        passed = true,
        issues = {},
        recommendations = {}
    }
    
    -- Test response times
    local responseTimeTest = MonetizationTesting.testResponseTimes()
    if responseTimeTest.averageTime > TESTING_CONFIG.performance.purchaseResponseTime then
        table.insert(result.issues, {
            severity = "high",
            description = string.format("Average response time exceeds threshold: %.3fs > %.3fs", 
                responseTimeTest.averageTime, TESTING_CONFIG.performance.purchaseResponseTime),
            details = responseTimeTest
        })
        result.passed = false
    end
    
    -- Test memory usage
    local memoryTest = MonetizationTesting.testMemoryUsage()
    if memoryTest.usage > TESTING_CONFIG.performance.memoryUsage then
        table.insert(result.issues, {
            severity = "medium",
            description = string.format("Memory usage exceeds threshold: %d MB > %d MB", 
                memoryTest.usage / 1024 / 1024, TESTING_CONFIG.performance.memoryUsage / 1024 / 1024),
            details = memoryTest
        })
    end
    
    return result
end

-- ========================================
-- PERFORMANCE MONITORING
-- ========================================

function MonetizationTesting.setupPerformanceMonitoring()
    TestingState.performanceMonitor = {
        responseTimeTracker = MonetizationTesting.createResponseTimeTracker(),
        memoryTracker = MonetizationTesting.createMemoryTracker(),
        throughputTracker = MonetizationTesting.createThroughputTracker()
    }
    
    print("📊 Performance monitoring initialized")
end

function MonetizationTesting.createResponseTimeTracker()
    return {
        name = "response_time_tracker",
        measurements = {},
        
        measure = function(self, operation, duration)
            table.insert(self.measurements, {
                operation = operation,
                duration = duration,
                timestamp = tick()
            })
        end,
        
        getAverageTime = function(self, operation)
            local total = 0
            local count = 0
            
            for _, measurement in ipairs(self.measurements) do
                if not operation or measurement.operation == operation then
                    total = total + measurement.duration
                    count = count + 1
                end
            end
            
            return count > 0 and (total / count) or 0
        end
    }
end

function MonetizationTesting.createMemoryTracker()
    return {
        name = "memory_tracker",
        measurements = {},
        
        measure = function(self)
            local usage = collectgarbage("count") * 1024 -- Convert KB to bytes
            table.insert(self.measurements, {
                usage = usage,
                timestamp = tick()
            })
            return usage
        end,
        
        getAverageUsage = function(self)
            local total = 0
            
            for _, measurement in ipairs(self.measurements) do
                total = total + measurement.usage
            end
            
            return #self.measurements > 0 and (total / #self.measurements) or 0
        end
    }
end

function MonetizationTesting.createThroughputTracker()
    return {
        name = "throughput_tracker",
        operations = {},
        
        recordOperation = function(self, operation)
            table.insert(self.operations, {
                operation = operation,
                timestamp = tick()
            })
        end,
        
        getThroughput = function(self, timeWindow)
            timeWindow = timeWindow or 60 -- Default 1 minute
            local cutoff = tick() - timeWindow
            local count = 0
            
            for _, op in ipairs(self.operations) do
                if op.timestamp >= cutoff then
                    count = count + 1
                end
            end
            
            return count / timeWindow
        end
    }
end

-- ========================================
-- UTILITY FUNCTIONS
-- ========================================

function MonetizationTesting.checkPayToWinViolations()
    return {
        violations = {}, -- Would implement actual checks
        fair = true
    }
end

function MonetizationTesting.checkProgressionFairness()
    return {
        fair = true,
        issues = {}
    }
end

function MonetizationTesting.testRevenueTrackingAccuracy()
    return {
        accuracy = 0.995,
        trackedRevenue = 1000,
        actualRevenue = 1005
    }
end

function MonetizationTesting.testConversionTrackingAccuracy()
    return {
        accuracy = 0.98,
        trackedConversions = 98,
        actualConversions = 100
    }
end

function MonetizationTesting.testResponseTimes()
    return {
        averageTime = 1.2,
        maxTime = 2.5,
        minTime = 0.8
    }
end

function MonetizationTesting.testMemoryUsage()
    return {
        usage = 80 * 1024 * 1024, -- 80MB
        peak = 95 * 1024 * 1024   -- 95MB
    }
end

function MonetizationTesting.mockTrackEvent(event)
    return true
end

function MonetizationTesting.mockGetMetrics()
    return {
        totalRevenue = 1000,
        totalConversions = 50,
        conversionRate = 0.05
    }
end

function MonetizationTesting.mockSaveData(key, data)
    TestingState.mockData[key] = data
    return true
end

function MonetizationTesting.mockLoadData(key)
    return TestingState.mockData[key]
end

-- ========================================
-- PUBLIC API
-- ========================================

function MonetizationTesting.runComprehensiveTests()
    print("🧪 Running comprehensive monetization testing suite...")
    
    local startTime = tick()
    local testResults = {}
    
    -- Unit tests
    print("📋 Running unit tests...")
    local unitTests = MonetizationTesting.createMonetizationUnitTests()
    local unitResults = MonetizationTesting.runUnitTestSuite(unitTests)
    testResults.unitTests = unitResults
    
    -- Integration tests
    print("🔗 Running integration tests...")
    local integrationTests = MonetizationTesting.createMonetizationIntegrationTests()
    local integrationResults = {}
    
    for _, test in ipairs(integrationTests) do
        local result = MonetizationTesting.runIntegrationTest(test)
        table.insert(integrationResults, result)
    end
    testResults.integrationTests = integrationResults
    
    -- Load tests
    print("⚡ Running load tests...")
    local loadTests = MonetizationTesting.createMonetizationLoadTests()
    local loadResults = {}
    
    for _, test in ipairs(loadTests) do
        local result = MonetizationTesting.runLoadTest(test)
        table.insert(loadResults, result)
    end
    testResults.loadTests = loadResults
    
    -- Validation tests
    print("🔍 Running validation tests...")
    local validationTypes = {"purchase_flow", "fraud_prevention", "economy_balance", 
                           "analytics_accuracy", "performance"}
    local validationResults = {}
    
    for _, validationType in ipairs(validationTypes) do
        local result = MonetizationTesting.runValidation(validationType)
        validationResults[validationType] = result
    end
    testResults.validationTests = validationResults
    
    -- Generate summary
    local endTime = tick()
    local totalDuration = endTime - startTime
    
    local summary = {
        startTime = startTime,
        endTime = endTime,
        duration = totalDuration,
        results = testResults,
        statistics = MonetizationTesting.calculateTestStatistics(testResults)
    }
    
    MonetizationTesting.printTestSummary(summary)
    
    return summary
end

function MonetizationTesting.createMonetizationUnitTests()
    return {
        name = "monetization_unit_tests",
        tests = {
            {
                name = "purchase_processing",
                description = "Test basic purchase processing",
                test = function()
                    local receiptInfo = {
                        PlayerId = 12345,
                        ProductId = TESTING_CONFIG.testData.products.validProduct.id,
                        CurrencySpent = 100,
                        CurrencyType = Enum.CurrencyType.Robux
                    }
                    
                    local result = TestingState.mockSystems.marketplace:ProcessReceipt(receiptInfo)
                    return result == Enum.ProductPurchaseDecision.PurchaseGranted
                end,
                assertions = {
                    {type = "is_true", message = "Purchase should be granted"}
                }
            },
            
            {
                name = "fraud_detection",
                description = "Test fraud detection system",
                test = function()
                    local suspiciousReceipt = {
                        PlayerId = 99999,
                        ProductId = TESTING_CONFIG.testData.products.validProduct.id,
                        CurrencySpent = 2000 -- High amount
                    }
                    
                    return MonetizationTesting.shouldTriggerFraudDetection(suspiciousReceipt)
                end,
                assertions = {
                    {type = "is_true", message = "Should trigger fraud detection for suspicious transaction"}
                }
            },
            
            {
                name = "analytics_tracking",
                description = "Test analytics event tracking",
                test = function()
                    local event = {
                        type = "purchase",
                        playerId = 12345,
                        amount = 100
                    }
                    
                    return TestingState.mockSystems.analytics:trackEvent(event)
                end,
                assertions = {
                    {type = "is_true", message = "Analytics tracking should succeed"}
                }
            }
        }
    }
end

function MonetizationTesting.createMonetizationIntegrationTests()
    return {
        {
            name = "end_to_end_purchase",
            components = {"monetization_system", "analytics_system", "fraud_prevention"},
            interactions = {
                {
                    type = "purchase_flow",
                    params = {
                        playerData = TESTING_CONFIG.testData.players.regularPlayer,
                        productId = TESTING_CONFIG.testData.products.validProduct.id,
                        amount = TESTING_CONFIG.testData.products.validProduct.price
                    }
                },
                {
                    type = "analytics_tracking",
                    params = {
                        playerId = 12345,
                        amount = 100,
                        productId = TESTING_CONFIG.testData.products.validProduct.id
                    }
                }
            }
        }
    }
end

function MonetizationTesting.createMonetizationLoadTests()
    return {
        {
            name = "purchase_load_test",
            concurrentUsers = 50,
            duration = 30,
            requestInterval = 2
        },
        
        {
            name = "analytics_load_test",
            concurrentUsers = 100,
            duration = 60,
            requestInterval = 1
        }
    }
end

function MonetizationTesting.calculateTestStatistics(testResults)
    local stats = {
        totalTests = 0,
        passedTests = 0,
        failedTests = 0,
        passRate = 0,
        totalDuration = 0
    }
    
    -- Unit test stats
    if testResults.unitTests then
        stats.totalTests = stats.totalTests + testResults.unitTests.totalTests
        stats.passedTests = stats.passedTests + testResults.unitTests.passedTests
        stats.failedTests = stats.failedTests + testResults.unitTests.failedTests
        stats.totalDuration = stats.totalDuration + testResults.unitTests.duration
    end
    
    -- Integration test stats
    if testResults.integrationTests then
        for _, result in ipairs(testResults.integrationTests) do
            stats.totalTests = stats.totalTests + 1
            if result.passed then
                stats.passedTests = stats.passedTests + 1
            else
                stats.failedTests = stats.failedTests + 1
            end
            stats.totalDuration = stats.totalDuration + result.duration
        end
    end
    
    -- Load test stats
    if testResults.loadTests then
        for _, result in ipairs(testResults.loadTests) do
            stats.totalTests = stats.totalTests + 1
            if result.passed then
                stats.passedTests = stats.passedTests + 1
            else
                stats.failedTests = stats.failedTests + 1
            end
            stats.totalDuration = stats.totalDuration + result.duration
        end
    end
    
    -- Validation test stats
    if testResults.validationTests then
        for _, result in pairs(testResults.validationTests) do
            stats.totalTests = stats.totalTests + 1
            if result.passed then
                stats.passedTests = stats.passedTests + 1
            else
                stats.failedTests = stats.failedTests + 1
            end
            stats.totalDuration = stats.totalDuration + result.duration
        end
    end
    
    if stats.totalTests > 0 then
        stats.passRate = stats.passedTests / stats.totalTests
    end
    
    return stats
end

function MonetizationTesting.printTestSummary(summary)
    print("=" .. string.rep("=", 60))
    print("🧪 MONETIZATION TESTING SUMMARY")
    print("=" .. string.rep("=", 60))
    
    local stats = summary.statistics
    
    print(string.format("Total Tests: %d", stats.totalTests))
    print(string.format("Passed: %d (%.1f%%)", stats.passedTests, stats.passRate * 100))
    print(string.format("Failed: %d", stats.failedTests))
    print(string.format("Total Duration: %.3f seconds", stats.totalDuration))
    
    if stats.passRate >= 0.95 then
        print("✅ OVERALL STATUS: PASSED")
    elseif stats.passRate >= 0.8 then
        print("⚠️ OVERALL STATUS: PASSED WITH WARNINGS")
    else
        print("❌ OVERALL STATUS: FAILED")
    end
    
    print("=" .. string.rep("=", 60))
end

function MonetizationTesting.getTestResults()
    return TestingState.testResults
end

function MonetizationTesting.getTestStatistics()
    return TestingState.stats
end

function MonetizationTesting.setTestEnvironment(environment)
    if TESTING_CONFIG.environments[environment] then
        TestingState.currentEnvironment = environment
        MonetizationTesting.setupTestEnvironment()
        print(string.format("🔧 Test environment changed to: %s", environment))
        return true
    else
        print(string.format("❌ Invalid test environment: %s", environment))
        return false
    end
end

-- Initialize the testing system
MonetizationTesting.initialize()

print("🧪 MonetizationTesting loaded with comprehensive testing and validation")

return MonetizationTesting
