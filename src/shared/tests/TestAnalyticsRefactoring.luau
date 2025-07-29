-- TestAnalyticsRefactoring.luau
-- Comprehensive test suite for the refactored Analytics system
-- Tests all components and their integration

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local SafeRequire = require(ReplicatedStorage.Shared.utils.SafeRequire)
local ServiceTestFramework = SafeRequire.require(ReplicatedStorage.Shared.core.ServiceTestFramework)

-- Import analytics components for testing
local AnalyticsRepository = require(ReplicatedStorage.Server.services.Analytics.AnalyticsRepository)
local AnalyticsEventCollector = require(ReplicatedStorage.Server.services.Analytics.AnalyticsEventCollector)
local AnalyticsSessionService = require(ReplicatedStorage.Server.services.Analytics.AnalyticsSessionService)
local AnalyticsReportingService = require(ReplicatedStorage.Server.services.Analytics.AnalyticsReportingService)
local AnalyticsServiceOrchestrator = require(ReplicatedStorage.Server.services.Analytics.AnalyticsServiceOrchestrator)

-- ========================================
-- ANALYTICS REPOSITORY TESTS
-- ========================================

local analyticsRepositoryTests = ServiceTestFramework:CreateTestSuite("AnalyticsRepository", {
    description = "Tests for analytics data persistence and storage",
    timeout = 10
})

ServiceTestFramework:AddTest("AnalyticsRepository", "should_create_analytics_event", function()
    local repository = AnalyticsRepository.new()
    
    local eventData = {
        playerId = 12345,
        playerName = "TestPlayer",
        sessionId = "test_session",
        eventType = "test_event",
        eventData = {value = 100}
    }
    
    local event = repository:Create(eventData)
    
    ServiceTestFramework.Assert.assertNotNil(event, "Event should be created")
    ServiceTestFramework.Assert.assertEqual(event.playerId, 12345, "Player ID should match")
    ServiceTestFramework.Assert.assertEqual(event.eventType, "test_event", "Event type should match")
    ServiceTestFramework.Assert.assertType(event.id, "string", "Event should have ID")
end)

ServiceTestFramework:AddTest("AnalyticsRepository", "should_manage_player_sessions", function()
    local repository = AnalyticsRepository.new()
    
    local sessionData = {
        sessionId = "test_session_123",
        playerName = "TestPlayer",
        platform = "PC"
    }
    
    local session = repository:CreatePlayerSession(12345, sessionData)
    
    ServiceTestFramework.Assert.assertNotNil(session, "Session should be created")
    ServiceTestFramework.Assert.assertEqual(session.sessionId, "test_session_123", "Session ID should match")
    ServiceTestFramework.Assert.assertTrue(session.isActive, "Session should be active")
    
    local retrievedSession = repository:GetPlayerSession(12345)
    ServiceTestFramework.Assert.assertEqual(retrievedSession.sessionId, session.sessionId, "Retrieved session should match")
end)

ServiceTestFramework:AddTest("AnalyticsRepository", "should_handle_buffer_operations", function()
    local repository = AnalyticsRepository.new()
    
    local initialSize = repository:GetBufferSize()
    
    -- Add events to buffer
    for i = 1, 5 do
        repository:Create({
            playerId = i,
            playerName = "TestPlayer" .. i,
            sessionId = "session_" .. i,
            eventType = "test_event",
            eventData = {iteration = i}
        })
    end
    
    local newSize = repository:GetBufferSize()
    ServiceTestFramework.Assert.assertEqual(newSize, initialSize + 5, "Buffer size should increase by 5")
    
    local events = repository:GetBufferEvents(3)
    ServiceTestFramework.Assert.assertEqual(#events, 3, "Should retrieve 3 events")
    
    repository:RemoveEventsFromBuffer(3)
    local finalSize = repository:GetBufferSize()
    ServiceTestFramework.Assert.assertEqual(finalSize, initialSize + 2, "Buffer size should decrease by 3")
end)

ServiceTestFramework:AddTest("AnalyticsRepository", "should_manage_configuration", function()
    local repository = AnalyticsRepository.new()
    
    local config = repository:GetConfiguration()
    ServiceTestFramework.Assert.assertType(config, "table", "Configuration should be a table")
    ServiceTestFramework.Assert.assertTrue(config.enabled, "Analytics should be enabled by default")
    
    repository:UpdateConfiguration({
        enabled = false,
        batchSize = 25
    })
    
    local updatedConfig = repository:GetConfiguration()
    ServiceTestFramework.Assert.assertFalse(updatedConfig.enabled, "Analytics should be disabled")
    ServiceTestFramework.Assert.assertEqual(updatedConfig.batchSize, 25, "Batch size should be updated")
end)

-- ========================================
-- ANALYTICS EVENT COLLECTOR TESTS
-- ========================================

local eventCollectorTests = ServiceTestFramework:CreateTestSuite("AnalyticsEventCollector", {
    description = "Tests for event collection and validation",
    timeout = 10
})

ServiceTestFramework:AddTest("AnalyticsEventCollector", "should_validate_event_types", function()
    local repository = AnalyticsRepository.new()
    local collector = AnalyticsEventCollector.new(repository)
    
    ServiceTestFramework.Assert.assertTrue(collector:ValidateEventType("run_start"), "Should validate known event type")
    ServiceTestFramework.Assert.assertTrue(collector:ValidateEventType("custom_event"), "Should validate custom event type")
    ServiceTestFramework.Assert.assertFalse(collector:ValidateEventType(""), "Should reject empty event type")
    ServiceTestFramework.Assert.assertFalse(collector:ValidateEventType(123), "Should reject non-string event type")
end)

ServiceTestFramework:AddTest("AnalyticsEventCollector", "should_enrich_event_data", function()
    local repository = AnalyticsRepository.new()
    local collector = AnalyticsEventCollector.new(repository)
    
    -- Create mock player
    local mockPlayer = {
        UserId = 12345,
        Name = "TestPlayer",
        AccountAge = 30
    }
    
    local originalData = {value = 100}
    local enrichedData = collector:EnrichEventData(mockPlayer, "test_event", originalData)
    
    ServiceTestFramework.Assert.assertEqual(enrichedData.value, 100, "Original data should be preserved")
    ServiceTestFramework.Assert.assertNotNil(enrichedData.serverJobId, "Should add server job ID")
    ServiceTestFramework.Assert.assertNotNil(enrichedData.placeId, "Should add place ID")
    ServiceTestFramework.Assert.assertNotNil(enrichedData.platform, "Should add platform detection")
end)

ServiceTestFramework:AddTest("AnalyticsEventCollector", "should_add_custom_validators", function()
    local repository = AnalyticsRepository.new()
    local collector = AnalyticsEventCollector.new(repository)
    
    collector:AddEventValidator("custom_event", function(data)
        return data.requiredField ~= nil
    end)
    
    ServiceTestFramework.Assert.assertTrue(collector:ValidateEventData("custom_event", {requiredField = "value"}), "Should pass custom validation")
    ServiceTestFramework.Assert.assertFalse(collector:ValidateEventData("custom_event", {otherField = "value"}), "Should fail custom validation")
end)

-- ========================================
-- ANALYTICS SESSION SERVICE TESTS
-- ========================================

local sessionServiceTests = ServiceTestFramework:CreateTestSuite("AnalyticsSessionService", {
    description = "Tests for session tracking and player lifecycle",
    timeout = 10
})

ServiceTestFramework:AddTest("AnalyticsSessionService", "should_start_player_session", function()
    local repository = AnalyticsRepository.new()
    local eventCollector = AnalyticsEventCollector.new(repository)
    local sessionService = AnalyticsSessionService.new(repository, eventCollector)
    
    local mockPlayer = {
        UserId = 12345,
        Name = "TestPlayer",
        AccountAge = 30,
        MembershipType = Enum.MembershipType.None,
        LocaleId = "en-us"
    }
    
    local sessionId = sessionService:StartPlayerSession(mockPlayer)
    
    ServiceTestFramework.Assert.assertType(sessionId, "string", "Should return session ID")
    
    local session = repository:GetPlayerSession(mockPlayer.UserId)
    ServiceTestFramework.Assert.assertNotNil(session, "Session should be created")
    ServiceTestFramework.Assert.assertEqual(session.sessionId, sessionId, "Session ID should match")
    ServiceTestFramework.Assert.assertTrue(session.isActive, "Session should be active")
end)

ServiceTestFramework:AddTest("AnalyticsSessionService", "should_track_run_lifecycle", function()
    local repository = AnalyticsRepository.new()
    local eventCollector = AnalyticsEventCollector.new(repository)
    local sessionService = AnalyticsSessionService.new(repository, eventCollector)
    
    local mockPlayer = {
        UserId = 12345,
        Name = "TestPlayer",
        AccountAge = 30,
        MembershipType = Enum.MembershipType.None
    }
    
    sessionService:StartPlayerSession(mockPlayer)
    
    sessionService:TrackRunStart(mockPlayer, 0)
    local metrics = sessionService:GetSessionMetrics(mockPlayer)
    ServiceTestFramework.Assert.assertTrue(metrics.firstRunStarted, "Should mark first run as started")
    
    sessionService:TrackRunEnd(mockPlayer, 100, 50, 30)
    local updatedMetrics = sessionService:GetSessionMetrics(mockPlayer)
    ServiceTestFramework.Assert.assertEqual(updatedMetrics.runsCompleted, 1, "Should increment runs completed")
    ServiceTestFramework.Assert.assertEqual(updatedMetrics.totalCoinsEarned, 50, "Should track coins earned")
end)

ServiceTestFramework:AddTest("AnalyticsSessionService", "should_track_barrier_attempts", function()
    local repository = AnalyticsRepository.new()
    local eventCollector = AnalyticsEventCollector.new(repository)
    local sessionService = AnalyticsSessionService.new(repository, eventCollector)
    
    local mockPlayer = {
        UserId = 12345,
        Name = "TestPlayer",
        AccountAge = 30,
        MembershipType = Enum.MembershipType.None
    }
    
    sessionService:StartPlayerSession(mockPlayer)
    
    sessionService:TrackBarrierAttempt(mockPlayer, 10, "RED", true)
    sessionService:TrackBarrierAttempt(mockPlayer, 15, "BLUE", false)
    
    local metrics = sessionService:GetSessionMetrics(mockPlayer)
    ServiceTestFramework.Assert.assertEqual(metrics.totalBarriersAttempted, 2, "Should track barrier attempts")
    ServiceTestFramework.Assert.assertEqual(metrics.totalBarriersFailed, 1, "Should track barrier failures")
end)

-- ========================================
-- ANALYTICS REPORTING SERVICE TESTS
-- ========================================

local reportingServiceTests = ServiceTestFramework:CreateTestSuite("AnalyticsReportingService", {
    description = "Tests for analytics reporting and insights",
    timeout = 15
})

ServiceTestFramework:AddTest("AnalyticsReportingService", "should_generate_realtime_metrics", function()
    local repository = AnalyticsRepository.new()
    local eventCollector = AnalyticsEventCollector.new(repository)
    local sessionService = AnalyticsSessionService.new(repository, eventCollector)
    local reportingService = AnalyticsReportingService.new(repository, eventCollector, sessionService)
    
    local metrics = reportingService:GetRealtimeMetrics()
    
    ServiceTestFramework.Assert.assertType(metrics, "table", "Should return metrics table")
    ServiceTestFramework.Assert.assertType(metrics.timestamp, "number", "Should have timestamp")
    ServiceTestFramework.Assert.assertType(metrics.activePlayerCount, "number", "Should have active player count")
    ServiceTestFramework.Assert.assertType(metrics.eventsPerMinute, "number", "Should have events per minute")
end)

ServiceTestFramework:AddTest("AnalyticsReportingService", "should_export_reports", function()
    local repository = AnalyticsRepository.new()
    local eventCollector = AnalyticsEventCollector.new(repository)
    local sessionService = AnalyticsSessionService.new(repository, eventCollector)
    local reportingService = AnalyticsReportingService.new(repository, eventCollector, sessionService)
    
    local jsonReport = reportingService:ExportReport("realtime", "json")
    ServiceTestFramework.Assert.assertType(jsonReport, "string", "Should export JSON string")
    
    local tableReport = reportingService:ExportReport("realtime", "table")
    ServiceTestFramework.Assert.assertType(tableReport, "table", "Should export table")
end)

ServiceTestFramework:AddTest("AnalyticsReportingService", "should_generate_insights", function()
    local repository = AnalyticsRepository.new()
    local eventCollector = AnalyticsEventCollector.new(repository)
    local sessionService = AnalyticsSessionService.new(repository, eventCollector)
    local reportingService = AnalyticsReportingService.new(repository, eventCollector, sessionService)
    
    local insights = reportingService:GenerateInsights()
    
    ServiceTestFramework.Assert.assertType(insights, "table", "Should return insights table")
    ServiceTestFramework.Assert.assertNotNil(insights.playerBehavior, "Should have player behavior insights")
    ServiceTestFramework.Assert.assertNotNil(insights.recommendations, "Should have recommendations")
end)

-- ========================================
-- ANALYTICS ORCHESTRATOR TESTS
-- ========================================

local orchestratorTests = ServiceTestFramework:CreateTestSuite("AnalyticsServiceOrchestrator", {
    description = "Tests for the complete analytics service orchestrator",
    timeout = 20
})

ServiceTestFramework:AddTest("AnalyticsServiceOrchestrator", "should_initialize_successfully", function()
    local analyticsService = AnalyticsServiceOrchestrator.new()
    
    ServiceTestFramework.Assert.assertNotNil(analyticsService.repository, "Should have repository component")
    ServiceTestFramework.Assert.assertNotNil(analyticsService.eventCollector, "Should have event collector component")
    ServiceTestFramework.Assert.assertNotNil(analyticsService.sessionService, "Should have session service component")
    ServiceTestFramework.Assert.assertNotNil(analyticsService.reportingService, "Should have reporting service component")
    
    local success = analyticsService:Initialize()
    ServiceTestFramework.Assert.assertTrue(success, "Should initialize successfully")
    ServiceTestFramework.Assert.assertTrue(analyticsService.isInitialized, "Should be marked as initialized")
    
    analyticsService:Shutdown()
end)

ServiceTestFramework:AddTest("AnalyticsServiceOrchestrator", "should_provide_unified_api", function()
    local analyticsService = AnalyticsServiceOrchestrator.new()
    analyticsService:Initialize()
    
    -- Create mock player with session
    local mockPlayer = {
        UserId = 12345,
        Name = "TestPlayer",
        AccountAge = 30,
        MembershipType = Enum.MembershipType.None
    }
    
    -- Test session creation
    analyticsService:_onPlayerJoined(mockPlayer)
    local sessionId = analyticsService:GetPlayerSessionId(mockPlayer)
    ServiceTestFramework.Assert.assertType(sessionId, "string", "Should return session ID")
    
    -- Test event logging
    local success = analyticsService:LogEvent(mockPlayer, "test_event", {value = 100})
    ServiceTestFramework.Assert.assertTrue(success, "Should log event successfully")
    
    -- Test run tracking
    analyticsService:TrackRunStart(mockPlayer, 0)
    analyticsService:TrackRunEnd(mockPlayer, 100, 50, 30)
    
    local metrics = analyticsService:GetSessionMetrics(mockPlayer)
    ServiceTestFramework.Assert.assertNotNil(metrics, "Should return session metrics")
    ServiceTestFramework.Assert.assertEqual(metrics.runsCompleted, 1, "Should track completed runs")
    
    -- Test reporting
    local realtimeMetrics = analyticsService:GetRealtimeMetrics()
    ServiceTestFramework.Assert.assertType(realtimeMetrics, "table", "Should return realtime metrics")
    
    analyticsService:Shutdown()
end)

ServiceTestFramework:AddTest("AnalyticsServiceOrchestrator", "should_handle_configuration", function()
    local analyticsService = AnalyticsServiceOrchestrator.new()
    analyticsService:Initialize()
    
    local originalConfig = analyticsService:GetConfiguration()
    ServiceTestFramework.Assert.assertType(originalConfig, "table", "Should return configuration")
    
    local success = analyticsService:ConfigureEndpoint("https://test.endpoint.com", "test-api-key", true)
    ServiceTestFramework.Assert.assertTrue(success, "Should configure endpoint successfully")
    
    local updatedConfig = analyticsService:GetConfiguration()
    ServiceTestFramework.Assert.assertEqual(updatedConfig.endpoint, "https://test.endpoint.com", "Should update endpoint")
    ServiceTestFramework.Assert.assertEqual(updatedConfig.apiKey, "test-api-key", "Should update API key")
    
    analyticsService:Shutdown()
end)

ServiceTestFramework:AddTest("AnalyticsServiceOrchestrator", "should_manage_buffer_operations", function()
    local analyticsService = AnalyticsServiceOrchestrator.new()
    analyticsService:Initialize()
    
    local initialSize = analyticsService:GetBufferSize()
    ServiceTestFramework.Assert.assertType(initialSize, "number", "Should return buffer size")
    
    -- Create mock player and log events
    local mockPlayer = {
        UserId = 12345,
        Name = "TestPlayer",
        AccountAge = 30,
        MembershipType = Enum.MembershipType.None
    }
    
    analyticsService:_onPlayerJoined(mockPlayer)
    
    for i = 1, 5 do
        analyticsService:LogEvent(mockPlayer, "test_event", {iteration = i})
    end
    
    local newSize = analyticsService:GetBufferSize()
    ServiceTestFramework.Assert.assertTrue(newSize > initialSize, "Buffer size should increase")
    
    analyticsService:ClearBuffer()
    local clearedSize = analyticsService:GetBufferSize()
    ServiceTestFramework.Assert.assertEqual(clearedSize, 0, "Buffer should be cleared")
    
    analyticsService:Shutdown()
end)

-- ========================================
-- INTEGRATION TESTS
-- ========================================

local integrationTests = ServiceTestFramework:CreateTestSuite("AnalyticsIntegration", {
    description = "Integration tests for the complete analytics system",
    timeout = 30
})

ServiceTestFramework:AddTest("AnalyticsIntegration", "should_handle_complete_player_session", function()
    local analyticsService = AnalyticsServiceOrchestrator.new()
    analyticsService:Initialize()
    
    local mockPlayer = {
        UserId = 12345,
        Name = "TestPlayer",
        AccountAge = 30,
        MembershipType = Enum.MembershipType.None,
        LocaleId = "en-us"
    }
    
    -- Player joins
    analyticsService:_onPlayerJoined(mockPlayer)
    
    -- Player starts and completes runs
    for runNum = 1, 3 do
        analyticsService:TrackRunStart(mockPlayer, 0)
        
        -- Simulate barrier attempts
        for barrier = 1, 10 do
            local success = barrier % 3 ~= 0 -- Fail every 3rd barrier
            analyticsService:TrackBarrierAttempt(mockPlayer, barrier, "RED", success)
        end
        
        analyticsService:TrackRunEnd(mockPlayer, runNum * 20, runNum * 10, runNum * 5)
    end
    
    -- Track some monetization
    analyticsService:TrackGamepassUsage(mockPlayer, "double_coins", "activate")
    analyticsService:TrackPurchaseAttempt(mockPlayer, "speed_boost", 100, true)
    
    -- Player leaves
    analyticsService:_onPlayerLeft(mockPlayer)
    
    -- Verify session was tracked properly
    local bufferSize = analyticsService:GetBufferSize()
    ServiceTestFramework.Assert.assertTrue(bufferSize > 0, "Should have events in buffer")
    
    -- Verify reporting works
    local realtimeMetrics = analyticsService:GetRealtimeMetrics()
    ServiceTestFramework.Assert.assertType(realtimeMetrics, "table", "Should generate realtime metrics")
    
    local insights = analyticsService:GenerateInsights()
    ServiceTestFramework.Assert.assertType(insights, "table", "Should generate insights")
    
    analyticsService:Shutdown()
end)

ServiceTestFramework:AddTest("AnalyticsIntegration", "should_validate_service_health", function()
    local analyticsService = AnalyticsServiceOrchestrator.new()
    analyticsService:Initialize()
    
    local health = analyticsService:GetHealth()
    ServiceTestFramework.Assert.assertNotNil(health, "Should return health status")
    ServiceTestFramework.Assert.assertTrue(health.isHealthy, "Service should be healthy")
    
    local stats = analyticsService:GetServiceStatistics()
    ServiceTestFramework.Assert.assertType(stats, "table", "Should return service statistics")
    ServiceTestFramework.Assert.assertNotNil(stats.repository, "Should have repository stats")
    ServiceTestFramework.Assert.assertNotNil(stats.collector, "Should have collector stats")
    
    analyticsService:Shutdown()
end)

-- ========================================
-- RUN ALL TESTS
-- ========================================

print("🧪 Starting Analytics Refactoring Tests...")

-- Run all test suites
local results = {
    ServiceTestFramework:RunTestSuite("AnalyticsRepository"),
    ServiceTestFramework:RunTestSuite("AnalyticsEventCollector"),
    ServiceTestFramework:RunTestSuite("AnalyticsSessionService"),
    ServiceTestFramework:RunTestSuite("AnalyticsReportingService"),
    ServiceTestFramework:RunTestSuite("AnalyticsServiceOrchestrator"),
    ServiceTestFramework:RunTestSuite("AnalyticsIntegration")
}

-- Calculate overall results
local totalTests = 0
local totalPassed = 0
local totalFailed = 0

for _, result in ipairs(results) do
    totalTests = totalTests + result.totalTests
    totalPassed = totalPassed + result.passedTests
    totalFailed = totalFailed + result.failedTests
end

print("\n" .. "=".rep(80))
print("🧪 ANALYTICS REFACTORING TEST SUMMARY")
print("=".rep(80))
print("Total Test Suites: " .. #results)
print("Total Tests: " .. totalTests)
print("✅ Passed: " .. totalPassed)
print("❌ Failed: " .. totalFailed)
print("📈 Success Rate: " .. string.format("%.1f", (totalPassed / totalTests * 100)) .. "%")
print("=".rep(80))

if totalFailed == 0 then
    print("🎉 ALL ANALYTICS REFACTORING TESTS PASSED!")
    print("✅ Analytics service has been successfully refactored into clean architecture")
else
    print("⚠️ Some tests failed - review the refactoring implementation")
end

return {
    totalTests = totalTests,
    passedTests = totalPassed,
    failedTests = totalFailed,
    successRate = totalPassed / totalTests,
    results = results
}
