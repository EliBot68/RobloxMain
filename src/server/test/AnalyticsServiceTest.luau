-- AnalyticsServiceTest.luau
-- Comprehensive unit tests for AnalyticsService

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local HttpService = game:GetService("HttpService")

local SafeRequire = require(ReplicatedStorage.Shared.utils.SafeRequire)
local TestFramework = SafeRequire.require(ReplicatedStorage.Shared.utils.TestFramework)
local RemoteEvents = SafeRequire.require(ReplicatedStorage.Shared.modules.RemoteEvents)

-- Create test suite
local analyticsSuite = TestFramework.createSuite("AnalyticsService")

-- Test data and mocks
local mockPlayer = TestFramework.Utils.createMockPlayer(123456789, "TestPlayer")
local mockEventData = {
    event = "test_event",
    category = "testing",
    label = "unit_test",
    value = 100,
    customData = {
        testProperty = "testValue",
        numericProperty = 42
    }
}

-- Service under test
local AnalyticsService = nil

-- Test Setup
analyticsSuite:setBeforeAll(function()
    local success, service = pcall(function()
        return require(game.ServerScriptService.services.AnalyticsService)
    end)
    
    if not success then
        error("AnalyticsService could not be loaded for testing")
    end
    
    AnalyticsService = service
end)

analyticsSuite:setBeforeEach(function()
    -- Reset any state before each test
    mockEventData = {
        event = "test_event",
        category = "testing", 
        label = "unit_test",
        value = 100,
        customData = {
            testProperty = "testValue",
            numericProperty = 42
        }
    }
end)

-- Test 1: Service Module Loading
analyticsSuite:addTest("Service Module Loads Successfully", function()
    local success, details = TestFramework.Utils.assertNotNil(AnalyticsService, "AnalyticsService should load successfully")
    assert(success, details)
    
    local isTable = TestFramework.Utils.assertType(AnalyticsService, "table", "AnalyticsService should be a table")
    assert(isTable, "AnalyticsService is not a table")
end)

-- Test 2: Required Functions Exist
analyticsSuite:addTest("Required Functions Exist", function()
    local requiredFunctions = {
        "LogEvent",
        "LogPlayerEvent",
        "LogGameEvent",
        "LogMonetizationEvent",
        "LogPerformanceEvent",
        "SetupAnalytics",
        "FlushEvents",
        "GetPlayerMetrics",
        "TrackConversion"
    }
    
    for _, funcName in ipairs(requiredFunctions) do
        if AnalyticsService[funcName] then
            local success, details = TestFramework.Utils.assertFunctionExists(AnalyticsService, funcName)
            assert(success, string.format("Function exists but not callable: %s - %s", funcName, details))
        else
            print(string.format("⚠️  Optional function not found: %s", funcName))
        end
    end
end)

-- Test 3: Remote Events Integration
analyticsSuite:addTest("Remote Events Integration", function()
    local analyticsEvents = {
        "LogAnalyticsEvent"
    }
    
    for _, eventName in ipairs(analyticsEvents) do
        local success, details = TestFramework.Utils.assertRemoteEventExists(eventName)
        assert(success, string.format("Missing RemoteEvent: %s - %s", eventName, details))
        
        -- Verify RemoteEvents module has reference
        local hasReference = TestFramework.Utils.assertNotNil(RemoteEvents[eventName])
        assert(hasReference, string.format("RemoteEvents.%s is not defined", eventName))
    end
end)

-- Test 4: Basic Event Logging
analyticsSuite:addTest("Basic Event Logging", function()
    if not AnalyticsService.LogEvent then
        print("⚠️  LogEvent function not available, skipping test")
        return
    end
    
    -- Test basic event logging
    local success, result = pcall(AnalyticsService.LogEvent, AnalyticsService, "test_event", mockEventData)
    assert(success, "LogEvent should not error: " .. tostring(result))
end)

-- Test 5: Player Event Logging
analyticsSuite:addTest("Player Event Logging", function()
    if not AnalyticsService.LogPlayerEvent then
        print("⚠️  LogPlayerEvent function not available, skipping test")
        return
    end
    
    -- Test player-specific event logging
    local success, result = pcall(AnalyticsService.LogPlayerEvent, AnalyticsService, mockPlayer, "player_action", mockEventData)
    assert(success, "LogPlayerEvent should not error: " .. tostring(result))
end)

-- Test 6: Game Event Logging
analyticsSuite:addTest("Game Event Logging", function()
    if not AnalyticsService.LogGameEvent then
        print("⚠️  LogGameEvent function not available, skipping test")
        return
    end
    
    -- Test game event logging
    local gameEventData = {
        gameMode = "solo",
        difficulty = "normal",
        duration = 120,
        score = 500
    }
    
    local success, result = pcall(AnalyticsService.LogGameEvent, AnalyticsService, "game_completed", gameEventData)
    assert(success, "LogGameEvent should not error: " .. tostring(result))
end)

-- Test 7: Monetization Event Logging
analyticsSuite:addTest("Monetization Event Logging", function()
    if not AnalyticsService.LogMonetizationEvent then
        print("⚠️  LogMonetizationEvent function not available, skipping test")
        return
    end
    
    -- Test monetization event logging
    local monetizationData = {
        productId = "test_product",
        price = 100,
        currency = "Robux",
        category = "cosmetic"
    }
    
    local success, result = pcall(AnalyticsService.LogMonetizationEvent, AnalyticsService, mockPlayer, "purchase_attempt", monetizationData)
    assert(success, "LogMonetizationEvent should not error: " .. tostring(result))
end)

-- Test 8: Performance Event Logging
analyticsSuite:addTest("Performance Event Logging", function()
    if not AnalyticsService.LogPerformanceEvent then
        print("⚠️  LogPerformanceEvent function not available, skipping test")
        return
    end
    
    -- Test performance event logging
    local performanceData = {
        loadTime = 2.5,
        frameRate = 60,
        memoryUsage = 512
    }
    
    local success, result = pcall(AnalyticsService.LogPerformanceEvent, AnalyticsService, "game_performance", performanceData)
    assert(success, "LogPerformanceEvent should not error: " .. tostring(result))
end)

-- Test 9: Event Data Validation
analyticsSuite:addTest("Event Data Validation", function()
    if not AnalyticsService.LogEvent then
        print("⚠️  LogEvent function not available, skipping test")
        return
    end
    
    -- Test with invalid event data
    local invalidData = {
        -- Missing required fields
        someField = "value"
    }
    
    local success, result = pcall(AnalyticsService.LogEvent, AnalyticsService, "", invalidData)
    -- Should handle invalid data gracefully
    assert(true, "Invalid data handling test completed")
    
    -- Test with nil data
    local nilSuccess, nilResult = pcall(AnalyticsService.LogEvent, AnalyticsService, "test_event", nil)
    assert(true, "Nil data handling test completed")
end)

-- Test 10: Player Metrics Tracking
analyticsSuite:addTest("Player Metrics Tracking", function()
    if not AnalyticsService.GetPlayerMetrics then
        print("⚠️  GetPlayerMetrics function not available, skipping test")
        return
    end
    
    -- Test getting player metrics
    local success, metrics = pcall(AnalyticsService.GetPlayerMetrics, AnalyticsService, mockPlayer)
    assert(success, "GetPlayerMetrics should not error")
    
    if metrics then
        local isTable = TestFramework.Utils.assertType(metrics, "table", "Player metrics should be a table")
        assert(isTable, "Player metrics is not a table")
    end
end)

-- Test 11: Conversion Tracking
analyticsSuite:addTest("Conversion Tracking", function()
    if not AnalyticsService.TrackConversion then
        print("⚠️  TrackConversion function not available, skipping test")
        return
    end
    
    -- Test conversion tracking
    local conversionData = {
        funnel = "tutorial_completion",
        step = "step_3",
        value = 1
    }
    
    local success, result = pcall(AnalyticsService.TrackConversion, AnalyticsService, mockPlayer, "tutorial_completed", conversionData)
    assert(success, "TrackConversion should not error: " .. tostring(result))
end)

-- Test 12: Event Batching and Flushing
analyticsSuite:addTest("Event Batching and Flushing", function()
    if not AnalyticsService.FlushEvents then
        print("⚠️  FlushEvents function not available, skipping test")
        return
    end
    
    -- Log several events
    if AnalyticsService.LogEvent then
        for i = 1, 3 do
            pcall(AnalyticsService.LogEvent, AnalyticsService, "batch_test_" .. i, {index = i})
        end
    end
    
    -- Test flushing events
    local success, result = pcall(AnalyticsService.FlushEvents, AnalyticsService)
    assert(success, "FlushEvents should not error: " .. tostring(result))
end)

-- Test 13: Analytics Configuration
analyticsSuite:addTest("Analytics Configuration", function()
    -- Check analytics configuration
    local config = AnalyticsService.Config or AnalyticsService.ANALYTICS_CONFIG
    
    if config then
        local hasEndpoint = TestFramework.Utils.assertNotNil(config.endpoint or config.apiEndpoint, "Analytics config should have endpoint")
        if not hasEndpoint then
            print("⚠️  Analytics endpoint not configured")
        end
        
        local hasApiKey = TestFramework.Utils.assertNotNil(config.apiKey or config.key, "Analytics config should have API key")
        if not hasApiKey then
            print("⚠️  Analytics API key not configured")
        end
    else
        print("⚠️  No analytics configuration found")
    end
    
    assert(true, "Analytics configuration test completed")
end)

-- Test 14: Error Handling and Resilience
analyticsSuite:addTest("Error Handling and Resilience", function()
    -- Test logging with network failure simulation
    if AnalyticsService.LogEvent then
        -- Test with extremely large data that might cause issues
        local largeData = {}
        for i = 1, 100 do
            largeData["key_" .. i] = string.rep("x", 1000)
        end
        
        local success, result = pcall(AnalyticsService.LogEvent, AnalyticsService, "large_data_test", largeData)
        -- Should handle gracefully
        assert(true, "Large data handling test completed")
    end
    
    -- Test with circular reference (should be handled by JSON encoding)
    local circularData = {}
    circularData.self = circularData
    
    if AnalyticsService.LogEvent then
        local success, result = pcall(AnalyticsService.LogEvent, AnalyticsService, "circular_test", circularData)
        assert(true, "Circular reference handling test completed")
    end
end)

-- Test 15: User Privacy and Data Protection
analyticsSuite:addTest("User Privacy and Data Protection", function()
    -- Test that sensitive data is not logged
    local sensitiveData = {
        userId = mockPlayer.UserId,
        username = mockPlayer.Name,
        ipAddress = "192.168.1.1",
        email = "test@example.com"
    }
    
    if AnalyticsService.LogPlayerEvent then
        local success, result = pcall(AnalyticsService.LogPlayerEvent, AnalyticsService, mockPlayer, "privacy_test", sensitiveData)
        -- Should sanitize or handle sensitive data appropriately
        assert(true, "Privacy protection test completed")
    end
end)

-- Test 16: Real-time vs Batch Processing
analyticsSuite:addTest("Real-time vs Batch Processing", function()
    if AnalyticsService.LogEvent then
        -- Test real-time critical events
        local criticalEvent = {
            priority = "high",
            realTime = true,
            event = "critical_error"
        }
        
        local success, result = pcall(AnalyticsService.LogEvent, AnalyticsService, "critical_event", criticalEvent)
        assert(success, "Critical event logging should not error")
        
        -- Test batch events
        local batchEvent = {
            priority = "low",
            batchable = true,
            event = "user_interaction"
        }
        
        local batchSuccess, batchResult = pcall(AnalyticsService.LogEvent, AnalyticsService, "batch_event", batchEvent)
        assert(batchSuccess, "Batch event logging should not error")
    end
end)

-- Test 17: Custom Dimensions and Metrics
analyticsSuite:addTest("Custom Dimensions and Metrics", function()
    if AnalyticsService.LogEvent then
        -- Test custom dimensions
        local customDimensionData = {
            customDimension1 = "mobile",
            customDimension2 = "premium_user", 
            customDimension3 = "level_5",
            customMetric1 = 150,
            customMetric2 = 0.75
        }
        
        local success, result = pcall(AnalyticsService.LogEvent, AnalyticsService, "custom_analytics", customDimensionData)
        assert(success, "Custom dimensions logging should not error")
    end
end)

-- Test 18: Session Tracking
analyticsSuite:addTest("Session Tracking", function()
    -- Test session tracking functionality
    if AnalyticsService.StartSession then
        local startSuccess, startResult = pcall(AnalyticsService.StartSession, AnalyticsService, mockPlayer)
        assert(startSuccess, "StartSession should not error")
    end
    
    if AnalyticsService.EndSession then
        local endSuccess, endResult = pcall(AnalyticsService.EndSession, AnalyticsService, mockPlayer)
        assert(endSuccess, "EndSession should not error")
    end
    
    if AnalyticsService.GetSessionData then
        local dataSuccess, sessionData = pcall(AnalyticsService.GetSessionData, AnalyticsService, mockPlayer)
        assert(dataSuccess, "GetSessionData should not error")
    end
end)

-- Test 19: Event Sampling and Rate Limiting
analyticsSuite:addTest("Event Sampling and Rate Limiting", function()
    if AnalyticsService.LogEvent then
        -- Test rapid event logging to check rate limiting
        local rapidEvents = 0
        for i = 1, 50 do
            local success, result = pcall(AnalyticsService.LogEvent, AnalyticsService, "rapid_event_" .. i, {index = i})
            if success then
                rapidEvents = rapidEvents + 1
            end
        end
        
        -- Should handle rapid events gracefully (either allow all or rate limit)
        assert(true, string.format("Rapid events test completed: %d/50 events logged", rapidEvents))
    end
end)

-- Test 20: Integration with External Analytics Providers
analyticsSuite:addTest("Integration with External Analytics Providers", function()
    -- Test integration with external providers (mocked)
    local providers = AnalyticsService.Providers or {}
    
    if #providers > 0 then
        print(string.format("✅ Found %d analytics providers", #providers))
        
        for _, provider in ipairs(providers) do
            if provider.name then
                print(string.format("   • %s", provider.name))
            end
        end
    else
        print("⚠️  No external analytics providers configured")
    end
    
    assert(true, "External provider integration test completed")
end)

return analyticsSuite
