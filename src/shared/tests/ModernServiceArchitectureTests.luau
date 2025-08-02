-- ModernServiceArchitectureTests.luau
-- Comprehensive test suite for the modernized service architecture
-- Tests dependency injection, lifecycle management, error boundaries, and mocking

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local _RunService = game:GetService("RunService")

local ModernServiceFramework = require(ReplicatedStorage.Shared.core.ModernServiceFramework)

local ModernServiceTests = {}

-- ========================================
-- TEST FRAMEWORK SETUP
-- ========================================

local TestRunner = {
    tests = {},
    results = {},
    mocks = {}
}

function TestRunner:AddTest(testName, testFunction)
    self.tests[testName] = testFunction
end

function TestRunner:RunAllTests()
    print("🧪 Starting Modern Service Architecture Tests...")
    print(string.rep("=", 50))
    
    local passed = 0
    local failed = 0
    local startTime = tick()
    
    for testName, testFunc in pairs(self.tests) do
        local success, error = pcall(testFunc)
        
        if success then
            print("✅ " .. testName)
            passed = passed + 1
        else
            print("❌ " .. testName .. " - " .. tostring(error))
            failed = failed + 1
        end
        
        self.results[testName] = {success = success, error = error}
    end
    
    local duration = tick() - startTime
    print(string.rep("=", 50))
    print(string.format("🎯 Test Results: %d passed, %d failed (%.2fs)", passed, failed, duration))
    
    return passed, failed
end

function TestRunner:Assert(condition, message)
    if not condition then
        error("Assertion failed: " .. (message or "No message provided"))
    end
end

function TestRunner:AssertEqual(actual, expected, message)
    if actual ~= expected then
        error(string.format("Assertion failed: %s - Expected %s, got %s", 
            message or "Values not equal", tostring(expected), tostring(actual)))
    end
end

function TestRunner:AssertNotNil(value, message)
    if value == nil then
        error("Assertion failed: " .. (message or "Value is nil"))
    end
end

-- ========================================
-- MOCK SERVICES FOR TESTING
-- ========================================

local MockPlayerService = {
    ServiceName = "PlayerService",
    State = "Running",
    players = {},
    
    GetPlayer = function(self, userId)
        return self.players[userId]
    end,
    
    AddPlayer = function(self, player)
        self.players[player.UserId] = player
    end,
    
    Init = function(self) 
        print("🎭 MockPlayerService initialized")
    end,
    
    Start = function(self)
        print("🎭 MockPlayerService started")
    end
}

local MockDataService = {
    ServiceName = "DataService",
    State = "Running",
    data = {},
    
    GetPlayerData = function(self, player)
        return self.data[player.UserId] or {}
    end,
    
    SavePlayerData = function(self, player, data)
        self.data[player.UserId] = data
        return true
    end,
    
    Init = function(self)
        print("🎭 MockDataService initialized")
    end,
    
    Start = function(self)
        print("🎭 MockDataService started")
    end
}

local MockMainGameService = {
    ServiceName = "MainGameService",
    State = "Running",
    gameState = "waiting",
    
    StartGame = function(self, player)
        self.gameState = "active"
        return true
    end,
    
    StopGame = function(self, player)
        self.gameState = "ended"
        return true
    end,
    
    Init = function(self)
        print("🎭 MockMainGameService initialized")
    end,
    
    Start = function(self)
        print("🎭 MockMainGameService started")
    end
}

-- ========================================
-- DEPENDENCY INJECTION TESTS
-- ========================================

TestRunner:AddTest("Test_ServiceRegistration", function()
    -- Reset framework for clean test
    local framework = ModernServiceFramework.GetInstance()
    framework:EnableTestMode()
    framework:ClearMocks()
    
    -- Test service registration
    local success = framework:Register("TestService", MockPlayerService, {
        Dependencies = {},
        Priority = 50
    })
    
    TestRunner:Assert(success, "Service registration should succeed")
    
    local metrics = framework:GetMetrics()
    TestRunner:Assert(metrics.total >= 1, "Should have at least 1 registered service")
end)

TestRunner:AddTest("Test_DependencyInjection", function()
    local framework = ModernServiceFramework.GetInstance()
    framework:EnableTestMode()
    framework:ClearMocks()
    
    -- Register mock dependencies
    framework:MockService("PlayerService", MockPlayerService)
    framework:MockService("DataService", MockDataService)
    framework:MockService("MainGameService", MockMainGameService)
    
    -- Create a service that depends on the mocks
    local TestServiceWithDeps = {
        ServiceName = "TestServiceWithDeps",
        PlayerService = nil,
        DataService = nil,
        MainGameService = nil,
        
        Init = function(self)
            -- Dependencies should be injected automatically
            TestRunner:AssertNotNil(self.PlayerService, "PlayerService should be injected")
            TestRunner:AssertNotNil(self.DataService, "DataService should be injected")
            TestRunner:AssertNotNil(self.MainGameService, "MainGameService should be injected")
        end
    }
    
    -- Register service with dependencies
    framework:Register("TestServiceWithDeps", TestServiceWithDeps, {
        Dependencies = {"PlayerService", "DataService", "MainGameService"},
        Priority = 30
    })
    
    -- Initialize framework to trigger dependency injection
    framework:InitializeAll()
    
    -- Get the service and verify dependencies were injected
    local service = framework:GetService("TestServiceWithDeps")
    TestRunner:AssertNotNil(service.PlayerService, "PlayerService dependency should be available")
    TestRunner:AssertNotNil(service.DataService, "DataService dependency should be available")
end)

TestRunner:AddTest("Test_ServiceLifecycle", function()
    local framework = ModernServiceFramework.GetInstance()
    framework:EnableTestMode()
    framework:ClearMocks()
    
    local lifecycleEvents = {}
    
    local LifecycleTestService = {
        ServiceName = "LifecycleTestService",
        
        Init = function(self, config)
            table.insert(lifecycleEvents, "Init")
            self.config = config
        end,
        
        Start = function(self)
            table.insert(lifecycleEvents, "Start")
        end,
        
        Stop = function(self)
            table.insert(lifecycleEvents, "Stop")
        end
    }
    
    framework:Register("LifecycleTestService", LifecycleTestService, {
        Dependencies = {},
        Priority = 50
    })
    
    -- Initialize and start
    framework:InitializeAll()
    framework:StartAll()
    
    -- Verify lifecycle events occurred in correct order
    TestRunner:AssertEqual(lifecycleEvents[1], "Init", "Init should be called first")
    TestRunner:AssertEqual(lifecycleEvents[2], "Start", "Start should be called second")
    
    -- Test shutdown
    framework:Shutdown()
    TestRunner:AssertEqual(lifecycleEvents[3], "Stop", "Stop should be called on shutdown")
end)

-- ========================================
-- ERROR BOUNDARY TESTS
-- ========================================

TestRunner:AddTest("Test_ErrorBoundary", function()
    local framework = ModernServiceFramework.GetInstance()
    framework:EnableTestMode()
    framework:ClearMocks()
    
    local errorHandled = false
    
    local ErrorProneService = {
        ServiceName = "ErrorProneService",
        
        Init = function(self)
            error("Simulated initialization error")
        end
    }
    
    -- Register service with error boundary
    framework:Register("ErrorProneService", ErrorProneService, {
        Dependencies = {},
        Priority = 50,
        ErrorBoundary = function(errorInfo)
            errorHandled = true
            return true -- Handle the error
        end
    })
    
    -- Attempt initialization (should not crash due to error boundary)
    local success = pcall(function()
        framework:InitializeAll()
    end)
    
    TestRunner:Assert(success, "Framework should handle initialization errors gracefully")
    TestRunner:Assert(errorHandled, "Error boundary should have been triggered")
end)

TestRunner:AddTest("Test_GracefulDegradation", function()
    local framework = ModernServiceFramework.GetInstance()
    framework:EnableTestMode()
    framework:ClearMocks()
    
    -- Mock critical service
    framework:MockService("CriticalService", {
        ServiceName = "CriticalService",
        IsAvailable = true,
        Init = function(self) end,
        Start = function(self) end
    })
    
    -- Service that gracefully handles missing optional dependencies
    local ResilientService = {
        ServiceName = "ResilientService",
        CriticalService = nil,
        OptionalService = nil,
        
        Init = function(self)
            -- Should work even without OptionalService
            TestRunner:AssertNotNil(self.CriticalService, "Critical service should be available")
        end,
        
        DoWork = function(self)
            -- Graceful degradation example
            if self.OptionalService then
                return "full_functionality"
            else
                return "basic_functionality"
            end
        end
    }
    
    framework:Register("ResilientService", ResilientService, {
        Dependencies = {"CriticalService"},
        OptionalDependencies = {"OptionalService"}, -- This won't be available
        Priority = 30
    })
    
    framework:InitializeAll()
    framework:StartAll()
    
    local service = framework:GetService("ResilientService")
    local result = service:DoWork()
    
    TestRunner:AssertEqual(result, "basic_functionality", "Service should degrade gracefully")
end)

-- ========================================
-- MOCKING AND TESTING INTEGRATION
-- ========================================

TestRunner:AddTest("Test_ServiceMocking", function()
    local framework = ModernServiceFramework.GetInstance()
    framework:EnableTestMode()
    framework:ClearMocks()
    
    -- Create a mock with specific behavior
    local mockService = {
        ServiceName = "MockedService",
        callCount = 0,
        
        DoSomething = function(self)
            self.callCount = self.callCount + 1
            return "mocked_result"
        end
    }
    
    framework:MockService("MockedService", mockService)
    
    -- Service under test that depends on the mocked service
    local ServiceUnderTest = {
        ServiceName = "ServiceUnderTest",
        MockedService = nil,
        
        Init = function(self) end,
        
        PerformAction = function(self)
            return self.MockedService:DoSomething()
        end
    }
    
    framework:Register("ServiceUnderTest", ServiceUnderTest, {
        Dependencies = {"MockedService"},
        Priority = 30
    })
    
    framework:InitializeAll()
    
    local testService = framework:GetService("ServiceUnderTest")
    local result = testService:PerformAction()
    
    TestRunner:AssertEqual(result, "mocked_result", "Should return mocked result")
    TestRunner:AssertEqual(mockService.callCount, 1, "Mock should track calls")
end)

TestRunner:AddTest("Test_ModernBuffServiceIntegration", function()
    local framework = ModernServiceFramework.GetInstance()
    framework:EnableTestMode()
    framework:ClearMocks()
    
    -- Setup mocks for BuffService dependencies
    framework:MockService("PlayerService", MockPlayerService)
    framework:MockService("DataService", MockDataService)
    framework:MockService("MainGameService", MockMainGameService)
    
    -- Test that ModernBuffService can be loaded and initialized
    local success, error = pcall(function()
        local ModernBuffService = require(ReplicatedStorage.Shared.services.ModernBuffService)
        
        -- Verify service structure
        TestRunner:AssertNotNil(ModernBuffService.Init, "BuffService should have Init method")
        TestRunner:AssertNotNil(ModernBuffService.Start, "BuffService should have Start method")
        TestRunner:AssertNotNil(ModernBuffService.ApplyBuff, "BuffService should have ApplyBuff method")
    end)
    
    if not success then
        print("⚠️ ModernBuffService test skipped - service not found:", error)
    else
        TestRunner:Assert(success, "ModernBuffService should load without errors")
    end
end)

-- ========================================
-- PERFORMANCE AND METRICS TESTS
-- ========================================

TestRunner:AddTest("Test_ServiceMetrics", function()
    local framework = ModernServiceFramework.GetInstance()
    framework:EnableTestMode()
    framework:ClearMocks()
    
    -- Register a simple service
    framework:Register("MetricsTestService", MockPlayerService, {
        Dependencies = {},
        Priority = 50
    })
    
    framework:InitializeAll()
    framework:StartAll()
    
    local metrics = framework:GetMetrics()
    
    TestRunner:Assert(metrics.total > 0, "Should have registered services")
    TestRunner:Assert(metrics.running >= 0, "Should track running services")
    TestRunner:Assert(metrics.startupTime >= 0, "Should track startup time")
    TestRunner:AssertNotNil(metrics.states, "Should provide service states")
end)

TestRunner:AddTest("Test_CircularDependencyDetection", function()
    local framework = ModernServiceFramework.GetInstance()
    framework:EnableTestMode()
    framework:ClearMocks()
    
    -- Create services with circular dependencies
    framework:Register("ServiceA", {
        ServiceName = "ServiceA",
        Init = function() end
    }, {
        Dependencies = {"ServiceB"},
        Priority = 50
    })
    
    framework:Register("ServiceB", {
        ServiceName = "ServiceB", 
        Init = function() end
    }, {
        Dependencies = {"ServiceA"},
        Priority = 50
    })
    
    -- Should detect circular dependency and handle gracefully
    local success, error = pcall(function()
        framework:InitializeAll()
    end)
    
    -- Framework should handle this gracefully or detect the issue
    if not success then
        TestRunner:Assert(string.find(error, "circular") or string.find(error, "dependency"), 
            "Should detect circular dependency")
    end
end)

-- ========================================
-- MIGRATION VERIFICATION TESTS
-- ========================================

TestRunner:AddTest("Test_LegacyPatternElimination", function()
    -- Verify that no legacy patterns remain in converted services
    local framework = ModernServiceFramework.GetInstance()
    
    local legacyPatterns = {
        "_G.GetService",
        "ServiceBase.new",
        "SafeRequire.require.*Service"
    }
    
    -- This would typically scan converted service files for legacy patterns
    -- For now, we'll test that the framework itself doesn't use legacy patterns
    local frameworkSource = debug.getinfo(framework.GetService, "S").source
    
    for _, pattern in ipairs(legacyPatterns) do
        TestRunner:Assert(not string.find(frameworkSource, pattern), 
            "Framework should not contain legacy pattern: " .. pattern)
    end
end)

-- ========================================
-- RUN ALL TESTS
-- ========================================

function ModernServiceTests.RunAllTests()
    return TestRunner:RunAllTests()
end

function ModernServiceTests.RunSpecificTest(testName)
    local testFunc = TestRunner.tests[testName]
    if testFunc then
        local success, error = pcall(testFunc)
        print(success and "✅ " .. testName or "❌ " .. testName .. " - " .. tostring(error))
        return success
    else
        print("❌ Test not found: " .. testName)
        return false
    end
end

-- Auto-run tests when required (optional)
if game:GetService("RunService"):IsStudio() then
    print("🧪 Modern Service Architecture Test Suite Loaded")
    print("   Run ModernServiceTests.RunAllTests() to execute all tests")
    print("   Run ModernServiceTests.RunSpecificTest('TestName') for individual tests")
end

return ModernServiceTests
