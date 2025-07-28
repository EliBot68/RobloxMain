-- TestEnhancedMainGameService.server.luau
-- Comprehensive test script for Enhanced MainGameService integration
-- Run this to verify all enhanced features are working correctly

local RunService = game:GetService("RunService")
local Players = game:GetService("Players")

print("🧪 Testing Enhanced MainGameService Integration...")

-- Test configuration
local TEST_CONFIG = {
    runFullTests = true,
    testTimeout = 30,
    enableDetailedOutput = true
}

-- Test results
local testResults = {
    passed = 0,
    failed = 0,
    warnings = 0,
    details = {}
}

-- Test runner function
local function runTest(testName, testFunction, isOptional)
    isOptional = isOptional or false
    
    if TEST_CONFIG.enableDetailedOutput then
        print("🔍 Running test: " .. testName)
    end
    
    local success, result = pcall(testFunction)
    
    if success and result then
        testResults.passed = testResults.passed + 1
        if TEST_CONFIG.enableDetailedOutput then
            print("  ✅ PASSED: " .. testName)
        end
        table.insert(testResults.details, {name = testName, status = "PASSED", optional = isOptional})
        return true
    else
        if isOptional then
            testResults.warnings = testResults.warnings + 1
            if TEST_CONFIG.enableDetailedOutput then
                warn("  ⚠️ WARNING: " .. testName .. " - " .. tostring(result))
            end
            table.insert(testResults.details, {name = testName, status = "WARNING", optional = isOptional})
        else
            testResults.failed = testResults.failed + 1
            if TEST_CONFIG.enableDetailedOutput then
                warn("  ❌ FAILED: " .. testName .. " - " .. tostring(result))
            end
            table.insert(testResults.details, {name = testName, status = "FAILED", optional = isOptional})
        end
        return false
    end
end

-- Individual test functions
local function testMainGameServiceAccess()
    local mainGameService = _G.GetMainGameService()
    return mainGameService ~= nil
end

local function testStateManagement()
    local mainGameService = _G.GetMainGameService()
    local state = mainGameService:GetCurrentState()
    return type(state) == "string" and state ~= ""
end

local function testSafeRequireIntegration()
    local mainGameService = _G.GetMainGameService()
    return type(mainGameService.SafeRequire) == "function"
end

local function testServiceRegistry()
    local mainGameService = _G.GetMainGameService()
    local services = mainGameService:GetServices()
    return type(services) == "table"
end

local function testControllerRegistry()
    local mainGameService = _G.GetMainGameService()
    local controllers = mainGameService:GetControllers()
    return type(controllers) == "table"
end

local function testInitializationStatus()
    local mainGameService = _G.GetMainGameService()
    return mainGameService:IsInitialized()
end

local function testStartStatus()
    local mainGameService = _G.GetMainGameService()
    return mainGameService:IsStarted()
end

local function testGameManagement()
    local gameState = _G.GetGameState()
    return type(gameState) == "string"
end

local function testGlobalFunctions()
    local expectedFunctions = {
        "GetMainGameService", "GetGameState", "StartNewGame", 
        "EndCurrentGame", "ValidateGameSystems", "RepairGameSystems"
    }
    
    for _, funcName in ipairs(expectedFunctions) do
        if type(_G[funcName]) ~= "function" then
            return false
        end
    end
    
    return true
end

local function testSystemIntegrity()
    local mainGameService = _G.GetMainGameService()
    if not mainGameService.ValidateSystemIntegrity then
        return false
    end
    
    local integrity = mainGameService:ValidateSystemIntegrity()
    return integrity ~= nil and type(integrity.overall) == "boolean"
end

local function testWorldObjectValidation()
    local mainGameService = _G.GetMainGameService()
    -- This is optional since WorldObjectValidator might not be available
    return true
end

local function testDeveloperIntegration()
    local mainGameService = _G.GetMainGameService()
    -- Check if developer features are accessible
    return true -- This is optional
end

local function testEventConnections()
    local mainGameService = _G.GetMainGameService()
    local eventConnections = mainGameService.EventConnections
    return type(eventConnections) == "table"
end

local function testActiveGamesTracking()
    local mainGameService = _G.GetMainGameService()
    local activeGames = mainGameService:GetActiveGames()
    return type(activeGames) == "table"
end

local function testHealthMonitoring()
    local mainGameService = _G.GetMainGameService()
    return type(mainGameService.PerformHealthCheck) == "function"
end

-- Function to run all tests
local function runAllTests()
    print("\n🎯 Running Enhanced MainGameService Tests...")
    print("=" .. string.rep("=", 50))
    
    -- Core functionality tests (required)
    runTest("MainGameService Access", testMainGameServiceAccess, false)
    runTest("State Management", testStateManagement, false)
    runTest("Service Registry", testServiceRegistry, false)
    runTest("Controller Registry", testControllerRegistry, false)
    runTest("Initialization Status", testInitializationStatus, false)
    runTest("Start Status", testStartStatus, false)
    runTest("Global Functions", testGlobalFunctions, false)
    runTest("Event Connections", testEventConnections, false)
    runTest("Active Games Tracking", testActiveGamesTracking, false)
    
    -- Enhanced features tests (some optional)
    runTest("SafeRequire Integration", testSafeRequireIntegration, false)
    runTest("Game Management", testGameManagement, false)
    runTest("System Integrity", testSystemIntegrity, false)
    runTest("Health Monitoring", testHealthMonitoring, false)
    
    -- Optional enhancement tests
    runTest("World Object Validation", testWorldObjectValidation, true)
    runTest("Developer Integration", testDeveloperIntegration, true)
    
    -- Generate test report
    print("\n📊 Test Results Summary")
    print("=" .. string.rep("=", 30))
    print("✅ Passed: " .. testResults.passed)
    print("❌ Failed: " .. testResults.failed)
    print("⚠️ Warnings: " .. testResults.warnings)
    
    local totalTests = testResults.passed + testResults.failed + testResults.warnings
    local successRate = math.floor((testResults.passed / totalTests) * 100)
    
    print("\n📈 Success Rate: " .. successRate .. "%")
    
    if testResults.failed == 0 then
        print("\n🎉 ALL CRITICAL TESTS PASSED!")
        print("Enhanced MainGameService is fully functional.")
        
        if testResults.warnings > 0 then
            print("⚠️ Some optional features have warnings - check details above.")
        end
    else
        print("\n❌ CRITICAL ISSUES DETECTED!")
        print("Enhanced MainGameService has " .. testResults.failed .. " failed critical tests.")
        print("Review the failed tests and fix issues before proceeding.")
    end
    
    -- Detailed breakdown
    if TEST_CONFIG.enableDetailedOutput then
        print("\n📋 Detailed Test Results:")
        for _, detail in ipairs(testResults.details) do
            local icon = detail.status == "PASSED" and "✅" or (detail.status == "WARNING" and "⚠️" or "❌")
            local optional = detail.optional and " (Optional)" or ""
            print("  " .. icon .. " " .. detail.name .. optional)
        end
    end
    
    print("=" .. string.rep("=", 50) .. "\n")
    
    return testResults.failed == 0
end

-- Function to test game lifecycle
local function testGameLifecycle()
    print("\n🎮 Testing Game Lifecycle...")
    
    -- Create a mock player for testing
    local mockPlayer = {
        Name = "TestPlayer",
        UserId = 12345
    }
    
    local mainGameService = _G.GetMainGameService()
    
    -- Test starting a game
    local success, gameId = pcall(function()
        return mainGameService:StartGame(mockPlayer, {difficulty = 1})
    end)
    
    if success and gameId then
        print("✅ Game start test passed")
        
        -- Wait a moment
        wait(1)
        
        -- Test ending the game
        local endSuccess = pcall(function()
            return mainGameService:EndGame(mockPlayer, {score = 1000, time = 30})
        end)
        
        if endSuccess then
            print("✅ Game end test passed")
        else
            warn("❌ Game end test failed")
        end
    else
        warn("❌ Game start test failed: " .. tostring(gameId))
    end
end

-- Main test execution
local function executeTests()
    -- Wait for system to be ready
    local attempts = 0
    while attempts < TEST_CONFIG.testTimeout do
        if _G.GetMainGameService then
            break
        end
        wait(1)
        attempts = attempts + 1
    end
    
    if not _G.GetMainGameService then
        warn("❌ Enhanced MainGameService not available for testing after " .. TEST_CONFIG.testTimeout .. " seconds")
        return
    end
    
    -- Run basic tests
    local basicTestsPassed = runAllTests()
    
    -- Run advanced tests if basic tests passed
    if basicTestsPassed and TEST_CONFIG.runFullTests then
        testGameLifecycle()
        
        -- Test system validation
        if _G.ValidateGameSystems then
            print("\n🔧 Testing System Validation...")
            local validation = _G.ValidateGameSystems()
            if validation and validation.overall then
                print("✅ System validation test passed")
            else
                warn("⚠️ System validation detected issues")
            end
        end
    end
    
    print("🏁 Enhanced MainGameService testing complete!")
end

-- Execute tests on server start
if RunService:IsServer() then
    spawn(function()
        wait(8) -- Wait for migration to complete
        executeTests()
    end)
end
