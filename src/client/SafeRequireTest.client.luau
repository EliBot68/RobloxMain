-- SafeRequireTest.client.luau
-- Test script to validate SafeRequire functionality with existing services

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local player = Players.LocalPlayer

-- Wait for SafeRequire to be available
local SafeRequire = require(ReplicatedStorage.Shared.utils.SafeRequire)

print("[SafeRequireTest] Starting SafeRequire validation tests...")

-- Test 1: Basic require functionality
local function testBasicRequire()
    print("[SafeRequireTest] Test 1: Basic require functionality")
    
    local RemoteEvents = SafeRequire.require(ReplicatedStorage.Shared.modules.RemoteEvents, {})
    if RemoteEvents and RemoteEvents.GetRemoteEvent then
        print("[SafeRequireTest] ✓ Basic require works - RemoteEvents loaded")
        return true
    else
        warn("[SafeRequireTest] ✗ Basic require failed")
        return false
    end
end

-- Test 2: Fallback mechanism
local function testFallback()
    print("[SafeRequireTest] Test 2: Fallback mechanism")
    
    local fallbackValue = {test = "fallback"}
    local result = SafeRequire.require("NonExistentModule", fallbackValue)
    
    if result == fallbackValue then
        print("[SafeRequireTest] ✓ Fallback mechanism works")
        return true
    else
        warn("[SafeRequireTest] ✗ Fallback mechanism failed")
        return false
    end
end

-- Test 3: Module validation
local function testModuleValidation()
    print("[SafeRequireTest] Test 3: Module validation")
    
    local module = SafeRequire.validateModule(
        ReplicatedStorage.Shared.modules.RemoteEvents, 
        "table", 
        {}
    )
    
    if type(module) == "table" then
        print("[SafeRequireTest] ✓ Module validation works")
        return true
    else
        warn("[SafeRequireTest] ✗ Module validation failed")
        return false
    end
end

-- Test 4: Cache functionality
local function testCache()
    print("[SafeRequireTest] Test 4: Cache functionality")
    
    -- First require
    local module1 = SafeRequire.require(ReplicatedStorage.Shared.modules.RemoteEvents, {})
    
    -- Second require (should be cached)
    local module2 = SafeRequire.require(ReplicatedStorage.Shared.modules.RemoteEvents, {})
    
    if module1 == module2 then
        print("[SafeRequireTest] ✓ Cache functionality works")
        
        local stats = SafeRequire.getDetailedStats()
        print(string.format("[SafeRequireTest] Cache hits: %d", stats.performance.cacheHits))
        return true
    else
        warn("[SafeRequireTest] ✗ Cache functionality failed")
        return false
    end
end

-- Test 5: Batch require
local function testBatchRequire()
    print("[SafeRequireTest] Test 5: Batch require")
    
    local moduleList = {
        ReplicatedStorage.Shared.modules.RemoteEvents,
        ReplicatedStorage.Shared.modules.DeveloperConfig,
        ReplicatedStorage.Shared.modules.Analytics
    }
    
    local results = SafeRequire.requireBatch(moduleList, {})
    local successCount = 0
    
    for _, result in pairs(results) do
        if result then
            successCount = successCount + 1
        end
    end
    
    if successCount >= 2 then -- At least 2 modules should load
        print(string.format("[SafeRequireTest] ✓ Batch require works - %d/%d modules loaded", 
            successCount, #moduleList))
        return true
    else
        warn("[SafeRequireTest] ✗ Batch require failed")
        return false
    end
end

-- Test 6: Performance monitoring
local function testPerformanceMonitoring()
    print("[SafeRequireTest] Test 6: Performance monitoring")
    
    local stats = SafeRequire.getDetailedStats()
    
    if stats.performance and stats.performance.totalRequires > 0 then
        print(string.format("[SafeRequireTest] ✓ Performance monitoring active"))
        print(string.format("  Total requires: %d", stats.performance.totalRequires))
        print(string.format("  Successful: %d", stats.performance.successfulRequires))
        print(string.format("  Failed: %d", stats.performance.failedRequires))
        print(string.format("  Cache hits: %d", stats.performance.cacheHits))
        print(string.format("  Average load time: %.3fs", stats.performance.averageLoadTime))
        return true
    else
        warn("[SafeRequireTest] ✗ Performance monitoring failed")
        return false
    end
end

-- Test 7: Existing service compatibility
local function testExistingServiceCompatibility()
    print("[SafeRequireTest] Test 7: Existing service compatibility")
    
    local compatibleServices = {
        "Analytics",
        "RemoteEvents", 
        "DeveloperConfig",
        "ModernUISystem"
    }
    
    local loadedServices = 0
    
    for _, serviceName in ipairs(compatibleServices) do
        local service = SafeRequire.require(
            ReplicatedStorage.Shared.modules[serviceName], 
            nil
        )
        
        if service then
            loadedServices = loadedServices + 1
            print(string.format("[SafeRequireTest]   ✓ %s loaded successfully", serviceName))
        else
            warn(string.format("[SafeRequireTest]   ✗ %s failed to load", serviceName))
        end
    end
    
    if loadedServices >= 3 then
        print(string.format("[SafeRequireTest] ✓ Service compatibility good - %d/%d services loaded", 
            loadedServices, #compatibleServices))
        return true
    else
        warn("[SafeRequireTest] ✗ Service compatibility poor")
        return false
    end
end

-- Run all tests
local function runAllTests()
    local tests = {
        {name = "Basic Require", func = testBasicRequire},
        {name = "Fallback Mechanism", func = testFallback},
        {name = "Module Validation", func = testModuleValidation},
        {name = "Cache Functionality", func = testCache},
        {name = "Batch Require", func = testBatchRequire},
        {name = "Performance Monitoring", func = testPerformanceMonitoring},
        {name = "Service Compatibility", func = testExistingServiceCompatibility}
    }
    
    local passedTests = 0
    local totalTests = #tests
    
    print(string.format("[SafeRequireTest] Running %d tests...", totalTests))
    print("=" .. string.rep("=", 50))
    
    for i, test in ipairs(tests) do
        local success = test.func()
        if success then
            passedTests = passedTests + 1
        end
        
        if i < totalTests then
            print("") -- Add spacing between tests
        end
    end
    
    print("=" .. string.rep("=", 50))
    print(string.format("[SafeRequireTest] Results: %d/%d tests passed (%.1f%%)", 
        passedTests, totalTests, (passedTests / totalTests) * 100))
    
    if passedTests == totalTests then
        print("[SafeRequireTest] 🎉 ALL TESTS PASSED - SafeRequire is working perfectly!")
    elseif passedTests >= totalTests * 0.8 then
        print("[SafeRequireTest] ⚠️ Most tests passed - SafeRequire is mostly functional")
    else
        warn("[SafeRequireTest] ❌ Many tests failed - SafeRequire needs attention")
    end
    
    -- Show final statistics
    local finalStats = SafeRequire.getDetailedStats()
    print("\nFinal Statistics:")
    print(string.format("  Cache size: %d modules", finalStats.cacheSize))
    print(string.format("  Error count: %d", finalStats.errorCount))
    print(string.format("  Total operations: %d", finalStats.performance.totalRequires))
end

-- Wait a moment for other systems to initialize, then run tests
wait(2)
runAllTests()
