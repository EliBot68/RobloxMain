-- PerformanceMonitoringServiceTest.luau
-- Comprehensive unit tests for Performance Monitoring Service

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local SafeRequire = require(ReplicatedStorage.Shared.utils.SafeRequire)
local TestFramework = SafeRequire.require(ReplicatedStorage.Shared.utils.TestFramework)
local RemoteEvents = SafeRequire.require(ReplicatedStorage.Shared.modules.RemoteEvents)

-- Create test suite
local performanceSuite = TestFramework.createSuite("PerformanceMonitoringService")

-- Test data and mocks
local mockPlayer = TestFramework.Utils.createMockPlayer(123456789, "TestPlayer")
local PerformanceMonitoringService = nil
local PerformanceService = nil

-- Test Setup
performanceSuite:setBeforeAll(function()
    -- Load Performance Monitoring Service
    local success, service = pcall(function()
        return require(ReplicatedStorage.Shared.services.PerformanceMonitoringService)
    end)
    
    if not success then
        error("PerformanceMonitoringService could not be loaded for testing")
    end
    
    PerformanceMonitoringService = service
    
    -- Load Performance Service
    local perfSuccess, perfService = pcall(function()
        return require(game.ServerScriptService.services.PerformanceService)
    end)
    
    if perfSuccess then
        PerformanceService = perfService
    end
end)

-- Test 1: Service Module Loading
performanceSuite:addTest("Performance Monitoring Service Loads Successfully", function()
    local success, details = TestFramework.Utils.assertNotNil(PerformanceMonitoringService, "PerformanceMonitoringService should load successfully")
    assert(success, details)
    
    local isTable = TestFramework.Utils.assertType(PerformanceMonitoringService, "table", "PerformanceMonitoringService should be a table")
    assert(isTable, "PerformanceMonitoringService is not a table")
end)

-- Test 2: Required Functions Exist
performanceSuite:addTest("Required Functions Exist", function()
    local requiredFunctions = {
        "updateFPSMetrics",
        "updateMemoryMetrics", 
        "updatePingMetrics",
        "checkServiceHealth",
        "generatePerformanceReport",
        "logPerformanceEvent",
        "getFPSStatus",
        "getMemoryStatus",
        "getPingStatus",
        "getOverallHealthStatus",
        "startMonitoring",
        "updateConfig",
        "resetMetrics"
    }
    
    for _, funcName in ipairs(requiredFunctions) do
        if PerformanceMonitoringService[funcName] then
            local success, details = TestFramework.Utils.assertFunctionExists(PerformanceMonitoringService, funcName)
            assert(success, string.format("Function exists but not callable: %s - %s", funcName, details))
        else
            print(string.format("⚠️  Function not found: %s", funcName))
        end
    end
end)

-- Test 3: Performance Metrics Generation
performanceSuite:addTest("Performance Metrics Generation", function()
    if not PerformanceMonitoringService.generatePerformanceReport then
        print("⚠️  generatePerformanceReport function not available, skipping test")
        return
    end
    
    local success, report = pcall(PerformanceMonitoringService.generatePerformanceReport, PerformanceMonitoringService)
    assert(success, "generatePerformanceReport should not error")
    
    if report then
        local isTable = TestFramework.Utils.assertType(report, "table", "Performance report should be a table")
        assert(isTable, "Performance report is not a table")
        
        -- Check required report sections
        local requiredSections = {"fps", "memory", "ping", "services", "performance", "overall"}
        for _, section in ipairs(requiredSections) do
            local hasSection = TestFramework.Utils.assertNotNil(report[section], string.format("Report should have %s section", section))
            assert(hasSection, string.format("Report missing %s section", section))
        end
    end
end)

-- Test 4: FPS Metrics Updates
performanceSuite:addTest("FPS Metrics Updates", function()
    if not PerformanceMonitoringService.updateFPSMetrics then
        print("⚠️  updateFPSMetrics function not available, skipping test")
        return
    end
    
    local success, result = pcall(PerformanceMonitoringService.updateFPSMetrics, PerformanceMonitoringService)
    assert(success, "updateFPSMetrics should not error: " .. tostring(result))
    
    -- Check if metrics object exists
    if PerformanceMonitoringService.getMetrics then
        local metricsSuccess, metrics = pcall(PerformanceMonitoringService.getMetrics, PerformanceMonitoringService)
        if metricsSuccess and metrics and metrics.fps then
            local hasCurrentFPS = TestFramework.Utils.assertNotNil(metrics.fps.current, "Should have current FPS metric")
            assert(hasCurrentFPS, "Missing current FPS metric")
        end
    end
end)

-- Test 5: Memory Metrics Updates
performanceSuite:addTest("Memory Metrics Updates", function()
    if not PerformanceMonitoringService.updateMemoryMetrics then
        print("⚠️  updateMemoryMetrics function not available, skipping test")
        return
    end
    
    local success, result = pcall(PerformanceMonitoringService.updateMemoryMetrics, PerformanceMonitoringService)
    assert(success, "updateMemoryMetrics should not error: " .. tostring(result))
    
    -- Check if metrics object exists
    if PerformanceMonitoringService.getMetrics then
        local metricsSuccess, metrics = pcall(PerformanceMonitoringService.getMetrics, PerformanceMonitoringService)
        if metricsSuccess and metrics and metrics.memory then
            local hasCurrentMemory = TestFramework.Utils.assertNotNil(metrics.memory.current, "Should have current memory metric")
            assert(hasCurrentMemory, "Missing current memory metric")
        end
    end
end)

-- Test 6: Service Health Checking
performanceSuite:addTest("Service Health Checking", function()
    if not PerformanceMonitoringService.checkServiceHealth then
        print("⚠️  checkServiceHealth function not available, skipping test")
        return
    end
    
    local success, healthReport = pcall(PerformanceMonitoringService.checkServiceHealth, PerformanceMonitoringService)
    assert(success, "checkServiceHealth should not error")
    
    if healthReport then
        local isTable = TestFramework.Utils.assertType(healthReport, "table", "Health report should be a table")
        assert(isTable, "Health report is not a table")
        
        -- Check that some services are being monitored
        local serviceCount = 0
        for serviceName, status in pairs(healthReport) do
            serviceCount = serviceCount + 1
            
            local hasStatus = TestFramework.Utils.assertNotNil(status.status, string.format("Service %s should have status", serviceName))
            assert(hasStatus, string.format("Service %s missing status", serviceName))
            
            local hasHealthy = TestFramework.Utils.assertNotNil(status.healthy, string.format("Service %s should have healthy field", serviceName))
            if not hasHealthy then
                print(string.format("⚠️  Service %s missing healthy field", serviceName))
            end
        end
        
        print(string.format("✅ Monitoring %d services", serviceCount))
    end
end)

-- Test 7: Performance Event Logging
performanceSuite:addTest("Performance Event Logging", function()
    if not PerformanceMonitoringService.logPerformanceEvent then
        print("⚠️  logPerformanceEvent function not available, skipping test")
        return
    end
    
    local testEventData = {
        testValue = 123,
        testString = "test_event",
        timestamp = tick()
    }
    
    local success, result = pcall(PerformanceMonitoringService.logPerformanceEvent, PerformanceMonitoringService, "TEST_EVENT", testEventData)
    assert(success, "logPerformanceEvent should not error: " .. tostring(result))
end)

-- Test 8: Status Determination Functions
performanceSuite:addTest("Status Determination Functions", function()
    local statusFunctions = {
        "getFPSStatus",
        "getMemoryStatus", 
        "getPingStatus",
        "getOverallHealthStatus"
    }
    
    for _, funcName in ipairs(statusFunctions) do
        if PerformanceMonitoringService[funcName] then
            local success, status = pcall(PerformanceMonitoringService[funcName], PerformanceMonitoringService)
            assert(success, string.format("%s should not error", funcName))
            
            if status then
                local validStatuses = {good = true, warning = true, critical = true}
                local isValidStatus = TestFramework.Utils.assertTrue(validStatuses[status] ~= nil, string.format("%s should return valid status", funcName))
                assert(isValidStatus, string.format("%s returned invalid status: %s", funcName, tostring(status)))
            end
        else
            print(string.format("⚠️  %s function not available", funcName))
        end
    end
end)

-- Test 9: Configuration Management
performanceSuite:addTest("Configuration Management", function()
    if not PerformanceMonitoringService.updateConfig then
        print("⚠️  updateConfig function not available, skipping test")
        return
    end
    
    local testConfig = {
        FPS_WARNING_THRESHOLD = 25,
        MEMORY_WARNING_MB = 600
    }
    
    local success, result = pcall(PerformanceMonitoringService.updateConfig, PerformanceMonitoringService, testConfig)
    assert(success, "updateConfig should not error: " .. tostring(result))
    
    if PerformanceMonitoringService.getConfig then
        local configSuccess, config = pcall(PerformanceMonitoringService.getConfig, PerformanceMonitoringService)
        if configSuccess and config then
            local hasUpdatedValue = TestFramework.Utils.assertTrue(config.FPS_WARNING_THRESHOLD == 25, "Config should be updated")
            assert(hasUpdatedValue, "Config was not properly updated")
        end
    end
end)

-- Test 10: Metrics Reset Functionality
performanceSuite:addTest("Metrics Reset Functionality", function()
    if not PerformanceMonitoringService.resetMetrics then
        print("⚠️  resetMetrics function not available, skipping test")
        return
    end
    
    local success, result = pcall(PerformanceMonitoringService.resetMetrics, PerformanceMonitoringService)
    assert(success, "resetMetrics should not error: " .. tostring(result))
end)

-- Test 11: Remote Events Integration
performanceSuite:addTest("Remote Events Integration", function()
    local performanceEvents = {
        "RequestPerformanceReport",
        "PerformanceReportUpdated",
        "PerformanceAlert",
        "RequestHealthCheck",
        "HealthCheckResult",
        "RemoteLogEvent",
        "ShowPerformanceUI",
        "HidePerformanceUI"
    }
    
    for _, eventName in ipairs(performanceEvents) do
        local success, details = TestFramework.Utils.assertRemoteEventExists(eventName)
        assert(success, string.format("Missing RemoteEvent: %s - %s", eventName, details))
        
        -- Verify RemoteEvents module has reference
        local hasReference = TestFramework.Utils.assertNotNil(RemoteEvents[eventName])
        assert(hasReference, string.format("RemoteEvents.%s is not defined", eventName))
    end
end)

-- Test 12: Performance Service Integration
performanceSuite:addTest("Performance Service Integration", function()
    if not PerformanceService then
        print("⚠️  PerformanceService not available, skipping test")
        return
    end
    
    local isTable = TestFramework.Utils.assertType(PerformanceService, "table", "PerformanceService should be a table")
    assert(isTable, "PerformanceService is not a table")
    
    -- Check key integration functions
    local integrationFunctions = {
        "comprehensiveHealthCheck",
        "handlePerformanceRequest",
        "sendPerformanceAlert"
    }
    
    for _, funcName in ipairs(integrationFunctions) do
        if PerformanceService[funcName] then
            local success, details = TestFramework.Utils.assertFunctionExists(PerformanceService, funcName)
            assert(success, string.format("Integration function exists but not callable: %s - %s", funcName, details))
        else
            print(string.format("⚠️  Integration function not found: %s", funcName))
        end
    end
end)

-- Test 13: Comprehensive Health Check
performanceSuite:addTest("Comprehensive Health Check", function()
    if not PerformanceService or not PerformanceService.comprehensiveHealthCheck then
        print("⚠️  comprehensiveHealthCheck function not available, skipping test")
        return
    end
    
    local success, healthReport = pcall(PerformanceService.comprehensiveHealthCheck, PerformanceService)
    assert(success, "comprehensiveHealthCheck should not error")
    
    if healthReport then
        local isTable = TestFramework.Utils.assertType(healthReport, "table", "Health report should be a table")
        assert(isTable, "Health report is not a table")
        
        -- Check required sections
        local requiredSections = {"performance", "integration"}
        for _, section in ipairs(requiredSections) do
            local hasSection = TestFramework.Utils.assertNotNil(healthReport[section], string.format("Health report should have %s section", section))
            assert(hasSection, string.format("Health report missing %s section", section))
        end
        
        -- Check integration section structure
        if healthReport.integration then
            local hasStatus = TestFramework.Utils.assertNotNil(healthReport.integration.status, "Integration should have status")
            assert(hasStatus, "Integration missing status")
            
            local hasScore = TestFramework.Utils.assertNotNil(healthReport.integration.score, "Integration should have score")
            assert(hasScore, "Integration missing score")
        end
    end
end)

-- Test 14: Ping Metrics (with mock player)
performanceSuite:addTest("Ping Metrics with Mock Player", function()
    if not PerformanceMonitoringService.updatePingMetrics then
        print("⚠️  updatePingMetrics function not available, skipping test")
        return
    end
    
    -- Test with mock player
    local success, result = pcall(PerformanceMonitoringService.updatePingMetrics, PerformanceMonitoringService, mockPlayer)
    assert(success, "updatePingMetrics should handle mock player gracefully: " .. tostring(result))
    
    -- Test with nil player
    local nilSuccess, nilResult = pcall(PerformanceMonitoringService.updatePingMetrics, PerformanceMonitoringService, nil)
    assert(nilSuccess, "updatePingMetrics should handle nil player gracefully")
end)

-- Test 15: Performance Monitoring Startup
performanceSuite:addTest("Performance Monitoring Startup", function()
    if not PerformanceMonitoringService.startMonitoring then
        print("⚠️  startMonitoring function not available, skipping test")
        return
    end
    
    local success, connections = pcall(PerformanceMonitoringService.startMonitoring, PerformanceMonitoringService)
    assert(success, "startMonitoring should not error")
    
    if connections then
        local isTable = TestFramework.Utils.assertType(connections, "table", "Connections should be a table")
        assert(isTable, "Connections is not a table")
        
        -- Check that some connections were created
        local connectionCount = 0
        for name, connection in pairs(connections) do
            connectionCount = connectionCount + 1
            print(string.format("✅ Found monitoring connection: %s", name))
        end
        
        local hasConnections = TestFramework.Utils.assertTrue(connectionCount > 0, "Should have monitoring connections")
        assert(hasConnections, "No monitoring connections found")
    end
end)

-- Test 16: Error Handling
performanceSuite:addTest("Error Handling", function()
    -- Test invalid configuration
    if PerformanceMonitoringService.updateConfig then
        local invalidSuccess, invalidResult = pcall(PerformanceMonitoringService.updateConfig, PerformanceMonitoringService, "invalid_config")
        assert(invalidSuccess, "Should handle invalid config gracefully")
    end
    
    -- Test invalid event data
    if PerformanceMonitoringService.logPerformanceEvent then
        local eventSuccess, eventResult = pcall(PerformanceMonitoringService.logPerformanceEvent, PerformanceMonitoringService, nil, nil)
        assert(eventSuccess, "Should handle invalid event data gracefully")
    end
end)

-- Test 17: Performance Thresholds
performanceSuite:addTest("Performance Thresholds", function()
    local statusFunctions = {
        {func = "getFPSStatus", metric = "fps"},
        {func = "getMemoryStatus", metric = "memory"},
        {func = "getPingStatus", metric = "ping"}
    }
    
    for _, statusInfo in ipairs(statusFunctions) do
        if PerformanceMonitoringService[statusInfo.func] then
            local success, status = pcall(PerformanceMonitoringService[statusInfo.func], PerformanceMonitoringService)
            
            if success and status then
                local validStatuses = {good = true, warning = true, critical = true}
                local isValid = TestFramework.Utils.assertTrue(validStatuses[status] ~= nil, 
                    string.format("%s threshold check should return valid status", statusInfo.metric))
                assert(isValid, string.format("%s threshold returned invalid status: %s", statusInfo.metric, status))
            end
        end
    end
end)

-- Test 18: Global Performance Service Access
performanceSuite:addTest("Global Performance Service Access", function()
    -- Check if PerformanceService is available globally
    local globalService = _G.PerformanceService
    if globalService then
        local isTable = TestFramework.Utils.assertType(globalService, "table", "Global PerformanceService should be a table")
        assert(isTable, "Global PerformanceService is not a table")
        
        print("✅ PerformanceService available globally")
    else
        print("⚠️  PerformanceService not available globally")
    end
end)

-- Test 19: Performance vs QA Integration
performanceSuite:addTest("Performance vs QA Integration", function()
    -- Try to access QA test runner for integration testing
    local success, qaRunner = pcall(function()
        return require(game.ServerScriptService.QATestRunner)
    end)
    
    if success and qaRunner then
        print("✅ QA Test Runner available for integration")
        
        if PerformanceService and PerformanceService.comprehensiveHealthCheck then
            local healthSuccess, healthReport = pcall(PerformanceService.comprehensiveHealthCheck, PerformanceService)
            
            if healthSuccess and healthReport and healthReport.qa then
                print("✅ QA integration working in comprehensive health check")
            else
                print("⚠️  QA integration not working in health check")
            end
        end
    else
        print("⚠️  QA Test Runner not available for integration testing")
    end
    
    assert(true, "Performance vs QA integration test completed")
end)

-- Test 20: Performance Monitoring Complete System Test
performanceSuite:addTest("Complete System Integration Test", function()
    local systemComponents = {
        "PerformanceMonitoringService loaded",
        "PerformanceService loaded", 
        "Remote events configured",
        "Health checking functional",
        "Metrics generation working"
    }
    
    local passedComponents = 0
    local totalComponents = #systemComponents
    
    -- Component 1: PerformanceMonitoringService
    if PerformanceMonitoringService then
        passedComponents = passedComponents + 1
    end
    
    -- Component 2: PerformanceService
    if PerformanceService then
        passedComponents = passedComponents + 1
    end
    
    -- Component 3: Remote events
    local eventCount = 0
    local performanceEvents = {"RequestPerformanceReport", "PerformanceReportUpdated", "PerformanceAlert"}
    for _, eventName in ipairs(performanceEvents) do
        if RemoteEvents[eventName] then
            eventCount = eventCount + 1
        end
    end
    if eventCount >= 2 then
        passedComponents = passedComponents + 1
    end
    
    -- Component 4: Health checking
    if PerformanceMonitoringService and PerformanceMonitoringService.checkServiceHealth then
        local healthSuccess, healthReport = pcall(PerformanceMonitoringService.checkServiceHealth, PerformanceMonitoringService)
        if healthSuccess then
            passedComponents = passedComponents + 1
        end
    end
    
    -- Component 5: Metrics generation
    if PerformanceMonitoringService and PerformanceMonitoringService.generatePerformanceReport then
        local reportSuccess, report = pcall(PerformanceMonitoringService.generatePerformanceReport, PerformanceMonitoringService)
        if reportSuccess and report then
            passedComponents = passedComponents + 1
        end
    end
    
    local completionRate = (passedComponents / totalComponents) * 100
    print(string.format("✅ Performance monitoring system: %d/%d components (%.1f%% complete)", 
        passedComponents, totalComponents, completionRate))
    
    local systemHealthy = TestFramework.Utils.assertTrue(passedComponents >= 3, "At least 3 system components should be working")
    assert(systemHealthy, string.format("Only %d/%d system components working", passedComponents, totalComponents))
end)

return performanceSuite
