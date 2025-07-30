-- IntegrationTestingSystem.luau
-- Integration testing for service interactions and data flows
-- Tests complex workflows, service communication, and end-to-end scenarios

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")

local SafeRequire = require(ReplicatedStorage.Shared.utils.SafeRequire)
local UnitTestFramework = SafeRequire(ReplicatedStorage.Shared.testing.UnitTestFramework)

local IntegrationTestingSystem = {}

-- ========================================
-- INTEGRATION TESTING CONFIGURATION
-- ========================================

local INTEGRATION_CONFIG = {
    -- Test environment settings
    environment = {
        enableTestEnvironment = true,
        enableServiceMocking = true,
        enableDataIsolation = true,
        enableNetworkSimulation = true,
        testDataPrefix = "test_",
        cleanupAfterTests = true
    },
    
    -- Service testing
    serviceTests = {
        enableServiceInteractionTests = true,
        enableDataFlowTests = true,
        enableEventTests = true,
        enableRemoteTests = true,
        testTimeout = 60000,              -- 60 seconds
        maxRetries = 3
    },
    
    -- Workflow testing
    workflowTests = {
        enableUserJourneyTests = true,
        enableBusinessLogicTests = true,
        enableStateTransitionTests = true,
        enableConcurrencyTests = true,
        parallelTestLimit = 3
    },
    
    -- Data integrity
    dataIntegrity = {
        enableDataValidation = true,
        enableConsistencyChecks = true,
        enableTransactionTests = true,
        enableCorruptionDetection = true
    },
    
    -- Performance validation
    performanceValidation = {
        enablePerformanceTests = true,
        maxResponseTime = 1000,           -- 1 second
        maxMemoryIncrease = 100,          -- 100MB
        enableLoadTesting = true
    }
}

-- ========================================
-- INTEGRATION TESTING STATE
-- ========================================

local IntegrationState = {
    -- Test environment
    testEnvironment = {},
    serviceMocks = {},
    testData = {},
    
    -- Test scenarios
    testScenarios = {},
    workflowTests = {},
    serviceTests = {},
    
    -- Test execution
    activeTests = {},
    testResults = {},
    testMetrics = {},
    
    -- Service tracking
    serviceInstances = {},
    serviceConnections = {},
    serviceStates = {},
    
    -- Data flow tracking
    dataFlows = {},
    eventSequences = {},
    networkCalls = {},
    
    -- Statistics
    stats = {
        totalIntegrationTests = 0,
        passedIntegrationTests = 0,
        failedIntegrationTests = 0,
        totalScenarios = 0,
        averageExecutionTime = 0,
        dataIntegrityScore = 0
    }
}

function IntegrationTestingSystem.initialize()
    print("🔗 Initializing IntegrationTestingSystem...")
    
    -- Set up test environment
    IntegrationTestingSystem.setupTestEnvironment()
    
    -- Initialize service mocking
    IntegrationTestingSystem.initializeServiceMocking()
    
    -- Set up data flow tracking
    IntegrationTestingSystem.setupDataFlowTracking()
    
    -- Initialize workflow testing
    IntegrationTestingSystem.initializeWorkflowTesting()
    
    -- Set up service interaction testing
    IntegrationTestingSystem.setupServiceInteractionTesting()
    
    print("🔗 IntegrationTestingSystem initialized successfully")
end

-- ========================================
-- TEST ENVIRONMENT SETUP
-- ========================================

function IntegrationTestingSystem.setupTestEnvironment()
    IntegrationState.testEnvironment = {
        isolated = true,
        services = {},
        data = {},
        connections = {},
        cleanup = {}
    }
    
    -- Create isolated test data storage
    IntegrationTestingSystem.createTestDataStorage()
    
    -- Initialize service isolation
    IntegrationTestingSystem.initializeServiceIsolation()
    
    print("🏗️ Test environment configured")
end

function IntegrationTestingSystem.createTestDataStorage()
    IntegrationState.testData = {
        players = {},
        gameState = {},
        userProgress = {},
        transactions = {},
        events = {}
    }
    
    -- Set up data validation
    IntegrationTestingSystem.setupDataValidation()
end

function IntegrationTestingSystem.setupDataValidation()
    IntegrationState.dataValidation = {
        schemas = {},
        validators = {},
        constraints = {}
    }
    
    -- Define common data schemas
    IntegrationState.dataValidation.schemas.player = {
        userId = "number",
        username = "string",
        level = "number",
        experience = "number",
        currency = "number"
    }
    
    IntegrationState.dataValidation.schemas.gameState = {
        sessionId = "string",
        startTime = "number",
        isActive = "boolean",
        playerCount = "number"
    }
end

function IntegrationTestingSystem.initializeServiceIsolation()
    -- Track original service methods for restoration
    IntegrationState.originalMethods = {}
    
    -- Set up service isolation boundaries
    IntegrationState.serviceBoundaries = {
        dataService = {},
        gameService = {},
        playerService = {},
        eventService = {}
    }
end

-- ========================================
-- SERVICE MOCKING SYSTEM
-- ========================================

function IntegrationTestingSystem.initializeServiceMocking()
    IntegrationState.serviceMocks = {}
    
    -- Create service mock factory
    IntegrationTestingSystem.createServiceMockFactory()
    
    print("🎭 Service mocking system initialized")
end

function IntegrationTestingSystem.createServiceMockFactory()
    IntegrationState.mockFactory = {
        mocks = {},
        stubs = {},
        spies = {}
    }
end

function IntegrationTestingSystem.mockService(serviceName, mockImplementation)
    local originalService = IntegrationState.serviceInstances[serviceName]
    
    -- Store original for restoration
    IntegrationState.originalMethods[serviceName] = originalService
    
    -- Create mock service
    local mockService = {}
    for methodName, implementation in pairs(mockImplementation) do
        if type(implementation) == "function" then
            mockService[methodName] = IntegrationTestingSystem.createServiceSpy(
                serviceName, methodName, implementation
            )
        else
            mockService[methodName] = implementation
        end
    end
    
    IntegrationState.serviceMocks[serviceName] = mockService
    IntegrationState.serviceInstances[serviceName] = mockService
    
    return mockService
end

function IntegrationTestingSystem.createServiceSpy(serviceName, methodName, implementation)
    local spy = {
        serviceName = serviceName,
        methodName = methodName,
        calls = {},
        implementation = implementation
    }
    
    return function(...)
        local args = {...}
        local call = {
            args = args,
            timestamp = tick(),
            returnValue = nil,
            error = nil
        }
        
        local success, result = pcall(implementation, ...)
        if success then
            call.returnValue = result
        else
            call.error = result
        end
        
        table.insert(spy.calls, call)
        
        -- Track service interaction
        IntegrationTestingSystem.trackServiceInteraction(serviceName, methodName, call)
        
        if success then
            return result
        else
            error(result)
        end
    end
end

function IntegrationTestingSystem.trackServiceInteraction(serviceName, methodName, call)
    local interaction = {
        service = serviceName,
        method = methodName,
        timestamp = call.timestamp,
        args = call.args,
        result = call.returnValue,
        error = call.error,
        duration = 0 -- Would be calculated in real implementation
    }
    
    if not IntegrationState.serviceConnections[serviceName] then
        IntegrationState.serviceConnections[serviceName] = {}
    end
    
    table.insert(IntegrationState.serviceConnections[serviceName], interaction)
end

function IntegrationTestingSystem.restoreServices()
    for serviceName, originalService in pairs(IntegrationState.originalMethods) do
        IntegrationState.serviceInstances[serviceName] = originalService
    end
    
    IntegrationState.serviceMocks = {}
    print("🔄 Services restored to original state")
end

-- ========================================
-- DATA FLOW TRACKING
-- ========================================

function IntegrationTestingSystem.setupDataFlowTracking()
    IntegrationState.dataFlows = {}
    IntegrationState.eventSequences = {}
    
    -- Set up data flow monitoring
    IntegrationTestingSystem.initializeDataFlowMonitoring()
    
    print("📊 Data flow tracking configured")
end

function IntegrationTestingSystem.initializeDataFlowMonitoring()
    IntegrationState.dataFlowMonitor = {
        active = true,
        flows = {},
        sequences = {},
        validators = {}
    }
end

function IntegrationTestingSystem.trackDataFlow(flowName, source, destination, data)
    local flow = {
        name = flowName,
        source = source,
        destination = destination,
        data = data,
        timestamp = tick(),
        size = IntegrationTestingSystem.calculateDataSize(data),
        validated = false
    }
    
    table.insert(IntegrationState.dataFlows, flow)
    
    -- Validate data flow
    IntegrationTestingSystem.validateDataFlow(flow)
    
    return flow
end

function IntegrationTestingSystem.calculateDataSize(data)
    if type(data) == "table" then
        return #HttpService:JSONEncode(data)
    else
        return #tostring(data)
    end
end

function IntegrationTestingSystem.validateDataFlow(flow)
    -- Validate data structure
    local isValid = IntegrationTestingSystem.validateDataStructure(flow.data)
    
    -- Check data consistency
    local isConsistent = IntegrationTestingSystem.checkDataConsistency(flow)
    
    flow.validated = isValid and isConsistent
    
    if not flow.validated then
        warn(string.format("Data flow validation failed: %s -> %s", flow.source, flow.destination))
    end
end

function IntegrationTestingSystem.validateDataStructure(data)
    -- Basic data structure validation
    if type(data) == "table" then
        for key, value in pairs(data) do
            if type(key) ~= "string" and type(key) ~= "number" then
                return false
            end
        end
    end
    return true
end

function IntegrationTestingSystem.checkDataConsistency(flow)
    -- Check if data follows expected patterns
    return true -- Simplified for example
end

-- ========================================
-- WORKFLOW TESTING
-- ========================================

function IntegrationTestingSystem.initializeWorkflowTesting()
    IntegrationState.workflowTests = {}
    
    -- Set up workflow test framework
    IntegrationTestingSystem.setupWorkflowFramework()
    
    print("🔄 Workflow testing initialized")
end

function IntegrationTestingSystem.setupWorkflowFramework()
    IntegrationState.workflowFramework = {
        scenarios = {},
        steps = {},
        conditions = {},
        validations = {}
    }
end

function IntegrationTestingSystem.defineWorkflow(workflowName, steps)
    local workflow = {
        name = workflowName,
        steps = steps,
        currentStep = 1,
        state = {},
        results = {},
        startTime = nil,
        endTime = nil
    }
    
    IntegrationState.workflowTests[workflowName] = workflow
    IntegrationState.stats.totalScenarios = IntegrationState.stats.totalScenarios + 1
    
    return workflow
end

function IntegrationTestingSystem.executeWorkflow(workflowName)
    local workflow = IntegrationState.workflowTests[workflowName]
    if not workflow then
        error(string.format("Workflow '%s' not found", workflowName))
    end
    
    workflow.startTime = tick()
    workflow.currentStep = 1
    workflow.state = {}
    workflow.results = {}
    
    print(string.format("🔄 Executing workflow: %s", workflowName))
    
    local success = true
    local error = nil
    
    for i, step in ipairs(workflow.steps) do
        workflow.currentStep = i
        
        local stepSuccess, stepError = IntegrationTestingSystem.executeWorkflowStep(workflow, step)
        
        table.insert(workflow.results, {
            step = i,
            name = step.name,
            success = stepSuccess,
            error = stepError,
            timestamp = tick()
        })
        
        if not stepSuccess then
            success = false
            error = stepError
            break
        end
    end
    
    workflow.endTime = tick()
    workflow.duration = workflow.endTime - workflow.startTime
    workflow.success = success
    workflow.error = error
    
    -- Update statistics
    if success then
        IntegrationState.stats.passedIntegrationTests = IntegrationState.stats.passedIntegrationTests + 1
    else
        IntegrationState.stats.failedIntegrationTests = IntegrationState.stats.failedIntegrationTests + 1
    end
    
    IntegrationState.stats.totalIntegrationTests = IntegrationState.stats.totalIntegrationTests + 1
    
    print(string.format("🔄 Workflow %s: %s (%.2fs)", 
        workflowName, success and "PASSED" or "FAILED", workflow.duration))
    
    return workflow
end

function IntegrationTestingSystem.executeWorkflowStep(workflow, step)
    local success, error = pcall(function()
        if step.setup then
            step.setup(workflow.state)
        end
        
        if step.action then
            local result = step.action(workflow.state)
            if step.resultKey then
                workflow.state[step.resultKey] = result
            end
        end
        
        if step.validation then
            local isValid = step.validation(workflow.state)
            if not isValid then
                error(string.format("Validation failed for step: %s", step.name))
            end
        end
        
        if step.cleanup then
            step.cleanup(workflow.state)
        end
    end)
    
    return success, error
end

-- ========================================
-- SERVICE INTERACTION TESTING
-- ========================================

function IntegrationTestingSystem.setupServiceInteractionTesting()
    IntegrationState.serviceTests = {}
    
    -- Initialize service test framework
    IntegrationTestingSystem.initializeServiceTestFramework()
    
    print("⚙️ Service interaction testing configured")
end

function IntegrationTestingSystem.initializeServiceTestFramework()
    IntegrationState.serviceTestFramework = {
        scenarios = {},
        interactions = {},
        validations = {}
    }
end

function IntegrationTestingSystem.testServiceInteraction(serviceName, methodName, args, expectedResult)
    local test = {
        service = serviceName,
        method = methodName,
        args = args,
        expectedResult = expectedResult,
        startTime = tick()
    }
    
    local service = IntegrationState.serviceInstances[serviceName]
    if not service then
        error(string.format("Service '%s' not found", serviceName))
    end
    
    local success, result = pcall(service[methodName], unpack(args))
    
    test.endTime = tick()
    test.duration = test.endTime - test.startTime
    test.success = success
    test.result = result
    test.error = not success and result or nil
    
    -- Validate result
    if success and expectedResult then
        test.resultValid = IntegrationTestingSystem.validateResult(result, expectedResult)
    else
        test.resultValid = success
    end
    
    table.insert(IntegrationState.serviceTests, test)
    
    return test
end

function IntegrationTestingSystem.validateResult(actual, expected)
    if type(expected) == "function" then
        return expected(actual)
    elseif type(expected) == "table" and type(actual) == "table" then
        return IntegrationTestingSystem.deepCompare(actual, expected)
    else
        return actual == expected
    end
end

function IntegrationTestingSystem.deepCompare(actual, expected)
    if type(actual) ~= type(expected) then
        return false
    end
    
    if type(actual) == "table" then
        for key, value in pairs(expected) do
            if not IntegrationTestingSystem.deepCompare(actual[key], value) then
                return false
            end
        end
        return true
    else
        return actual == expected
    end
end

-- ========================================
-- END-TO-END SCENARIO TESTING
-- ========================================

function IntegrationTestingSystem.createEndToEndScenario(scenarioName, description)
    local scenario = {
        name = scenarioName,
        description = description,
        steps = {},
        preconditions = {},
        postconditions = {},
        cleanup = {}
    }
    
    IntegrationState.testScenarios[scenarioName] = scenario
    
    return {
        given = function(condition)
            table.insert(scenario.preconditions, condition)
            return scenario
        end,
        
        when = function(action)
            table.insert(scenario.steps, {type = "action", func = action})
            return scenario
        end,
        
        then = function(validation)
            table.insert(scenario.steps, {type = "validation", func = validation})
            return scenario
        end,
        
        cleanup = function(cleanupFunc)
            table.insert(scenario.cleanup, cleanupFunc)
            return scenario
        end
    }
end

function IntegrationTestingSystem.executeScenario(scenarioName)
    local scenario = IntegrationState.testScenarios[scenarioName]
    if not scenario then
        error(string.format("Scenario '%s' not found", scenarioName))
    end
    
    print(string.format("🎭 Executing scenario: %s", scenarioName))
    
    local results = {
        scenario = scenarioName,
        success = true,
        steps = {},
        startTime = tick()
    }
    
    -- Check preconditions
    for _, condition in ipairs(scenario.preconditions) do
        local conditionMet, error = pcall(condition)
        if not conditionMet then
            results.success = false
            results.error = string.format("Precondition failed: %s", error)
            return results
        end
    end
    
    -- Execute steps
    for i, step in ipairs(scenario.steps) do
        local stepResult = {
            step = i,
            type = step.type,
            success = false,
            startTime = tick()
        }
        
        local success, error = pcall(step.func)
        stepResult.success = success
        stepResult.error = error
        stepResult.endTime = tick()
        stepResult.duration = stepResult.endTime - stepResult.startTime
        
        table.insert(results.steps, stepResult)
        
        if not success then
            results.success = false
            results.error = error
            break
        end
    end
    
    -- Run cleanup
    for _, cleanupFunc in ipairs(scenario.cleanup) do
        pcall(cleanupFunc)
    end
    
    results.endTime = tick()
    results.duration = results.endTime - results.startTime
    
    table.insert(IntegrationState.testResults, results)
    
    print(string.format("🎭 Scenario %s: %s (%.2fs)", 
        scenarioName, results.success and "PASSED" or "FAILED", results.duration))
    
    return results
end

-- ========================================
-- EXAMPLE TEST SCENARIOS
-- ========================================

function IntegrationTestingSystem.defineStandardScenarios()
    -- Player login and data loading scenario
    IntegrationTestingSystem.createEndToEndScenario("PlayerLoginFlow", "Test complete player login and data loading")
        .given(function()
            assert(game.Players.LocalPlayer, "Player must be present")
        end)
        .when(function()
            -- Simulate player data loading
            IntegrationTestingSystem.trackDataFlow("playerData", "DataService", "PlayerService", {
                userId = 12345,
                username = "TestPlayer",
                level = 1,
                experience = 0
            })
        end)
        .then(function()
            -- Validate player data was loaded correctly
            assert(IntegrationState.testData.players[12345], "Player data should be loaded")
        end)
        .cleanup(function()
            IntegrationState.testData.players = {}
        end)
    
    -- Game session workflow
    IntegrationTestingSystem.defineWorkflow("GameSessionFlow", {
        {
            name = "Initialize Game",
            action = function(state)
                state.sessionId = HttpService:GenerateGUID(false)
                state.startTime = tick()
                return state.sessionId
            end,
            validation = function(state)
                return state.sessionId ~= nil
            end,
            resultKey = "sessionId"
        },
        {
            name = "Load Player Data",
            action = function(state)
                state.playerData = {
                    userId = 12345,
                    level = 5,
                    currency = 1000
                }
                return state.playerData
            end,
            validation = function(state)
                return state.playerData.userId == 12345
            end
        },
        {
            name = "Start Game Session",
            action = function(state)
                state.gameActive = true
                state.sessionStartTime = tick()
            end,
            validation = function(state)
                return state.gameActive == true
            end
        }
    })
end

-- ========================================
-- PERFORMANCE VALIDATION
-- ========================================

function IntegrationTestingSystem.validatePerformance(testName, testFunction, performanceRequirements)
    local requirements = performanceRequirements or {
        maxExecutionTime = INTEGRATION_CONFIG.performanceValidation.maxResponseTime,
        maxMemoryIncrease = INTEGRATION_CONFIG.performanceValidation.maxMemoryIncrease
    }
    
    local initialMemory = collectgarbage("count")
    local startTime = tick()
    
    local success, result = pcall(testFunction)
    
    local endTime = tick()
    local finalMemory = collectgarbage("count")
    
    local performance = {
        executionTime = (endTime - startTime) * 1000, -- Convert to milliseconds
        memoryIncrease = finalMemory - initialMemory,
        success = success,
        result = result
    }
    
    -- Check performance requirements
    performance.meetsRequirements = 
        performance.executionTime <= requirements.maxExecutionTime and
        performance.memoryIncrease <= requirements.maxMemoryIncrease
    
    if not performance.meetsRequirements then
        warn(string.format("Performance test '%s' failed requirements", testName))
        warn(string.format("  Execution time: %.1fms (max: %.1fms)", 
            performance.executionTime, requirements.maxExecutionTime))
        warn(string.format("  Memory increase: %.1fMB (max: %.1fMB)", 
            performance.memoryIncrease, requirements.maxMemoryIncrease))
    end
    
    return performance
end

-- ========================================
-- CONCURRENCY TESTING
-- ========================================

function IntegrationTestingSystem.testConcurrency(testName, testFunctions, maxConcurrent)
    maxConcurrent = maxConcurrent or INTEGRATION_CONFIG.workflowTests.parallelTestLimit
    
    local results = {
        testName = testName,
        totalTests = #testFunctions,
        completed = 0,
        successful = 0,
        failed = 0,
        results = {},
        startTime = tick()
    }
    
    local activeTests = {}
    local testIndex = 1
    
    -- Start initial batch of tests
    while #activeTests < maxConcurrent and testIndex <= #testFunctions do
        local testThread = task.spawn(function()
            local testFunc = testFunctions[testIndex]
            local success, result = pcall(testFunc)
            
            table.insert(results.results, {
                index = testIndex,
                success = success,
                result = result,
                timestamp = tick()
            })
            
            results.completed = results.completed + 1
            if success then
                results.successful = results.successful + 1
            else
                results.failed = results.failed + 1
            end
        end)
        
        table.insert(activeTests, testThread)
        testIndex = testIndex + 1
    end
    
    -- Wait for all tests to complete
    while results.completed < results.totalTests do
        task.wait(0.1)
        
        -- Clean up completed threads and start new ones
        for i = #activeTests, 1, -1 do
            if coroutine.status(activeTests[i]) == "dead" then
                table.remove(activeTests, i)
                
                -- Start next test if available
                if testIndex <= #testFunctions then
                    local testThread = task.spawn(function()
                        local testFunc = testFunctions[testIndex]
                        local success, result = pcall(testFunc)
                        
                        table.insert(results.results, {
                            index = testIndex,
                            success = success,
                            result = result,
                            timestamp = tick()
                        })
                        
                        results.completed = results.completed + 1
                        if success then
                            results.successful = results.successful + 1
                        else
                            results.failed = results.failed + 1
                        end
                    end)
                    
                    table.insert(activeTests, testThread)
                    testIndex = testIndex + 1
                end
            end
        end
    end
    
    results.endTime = tick()
    results.duration = results.endTime - results.startTime
    
    print(string.format("🔄 Concurrency test '%s': %d/%d passed (%.2fs)", 
        testName, results.successful, results.totalTests, results.duration))
    
    return results
end

-- ========================================
-- PUBLIC API
-- ========================================

function IntegrationTestingSystem.runAllIntegrationTests()
    print("🔗 Running all integration tests...")
    
    local startTime = tick()
    
    -- Define standard scenarios
    IntegrationTestingSystem.defineStandardScenarios()
    
    -- Execute scenarios
    for scenarioName, _ in pairs(IntegrationState.testScenarios) do
        IntegrationTestingSystem.executeScenario(scenarioName)
    end
    
    -- Execute workflows
    for workflowName, _ in pairs(IntegrationState.workflowTests) do
        IntegrationTestingSystem.executeWorkflow(workflowName)
    end
    
    local endTime = tick()
    IntegrationState.stats.averageExecutionTime = endTime - startTime
    
    -- Generate report
    local report = IntegrationTestingSystem.generateIntegrationReport()
    
    print(string.format("🔗 Integration tests completed in %.2fs", endTime - startTime))
    print(string.format("📊 Results: %d/%d passed", 
        IntegrationState.stats.passedIntegrationTests, 
        IntegrationState.stats.totalIntegrationTests))
    
    return report
end

function IntegrationTestingSystem.generateIntegrationReport()
    return {
        timestamp = tick(),
        stats = IntegrationState.stats,
        scenarios = IntegrationState.testScenarios,
        workflows = IntegrationState.workflowTests,
        serviceTests = IntegrationState.serviceTests,
        dataFlows = IntegrationState.dataFlows,
        results = IntegrationState.testResults
    }
end

function IntegrationTestingSystem.cleanup()
    -- Restore original services
    IntegrationTestingSystem.restoreServices()
    
    -- Clear test data
    IntegrationState.testData = {}
    
    -- Disconnect test connections
    for _, connection in pairs(IntegrationState.testEnvironment.connections) do
        if connection.Disconnect then
            connection:Disconnect()
        end
    end
    
    print("🧹 Integration test environment cleaned up")
end

-- Export API
IntegrationTestingSystem.mockService = IntegrationTestingSystem.mockService
IntegrationTestingSystem.defineWorkflow = IntegrationTestingSystem.defineWorkflow
IntegrationTestingSystem.executeWorkflow = IntegrationTestingSystem.executeWorkflow
IntegrationTestingSystem.createEndToEndScenario = IntegrationTestingSystem.createEndToEndScenario
IntegrationTestingSystem.executeScenario = IntegrationTestingSystem.executeScenario
IntegrationTestingSystem.testServiceInteraction = IntegrationTestingSystem.testServiceInteraction
IntegrationTestingSystem.validatePerformance = IntegrationTestingSystem.validatePerformance
IntegrationTestingSystem.testConcurrency = IntegrationTestingSystem.testConcurrency

-- Initialize the integration testing system
IntegrationTestingSystem.initialize()

print("🔗 IntegrationTestingSystem loaded with comprehensive integration testing capabilities")

return IntegrationTestingSystem
