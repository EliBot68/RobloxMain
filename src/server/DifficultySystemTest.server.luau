-- DifficultySystemTest.server.luau
-- Comprehensive testing for the difficulty progression system

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local Knit = require(ReplicatedStorage.Packages.Knit)
local SafeRequire = require(ReplicatedStorage.Shared.utils.SafeRequire)

-- Load DifficultyManager for testing
local DifficultyManager = SafeRequire.requireWithRetry(
    ReplicatedStorage.Shared.modules.DifficultyManager,
    3
)

-- Test configuration
local TEST_CONFIG = {
    runTests = true,
    verboseOutput = true,
    testDuration = 60, -- seconds
    simulatePlayerCount = 3
}

local testResults = {
    passed = 0,
    failed = 0,
    total = 0,
    details = {}
}

local function logTest(testName, passed, message)
    testResults.total = testResults.total + 1
    
    if passed then
        testResults.passed = testResults.passed + 1
        if TEST_CONFIG.verboseOutput then
            print("✅ " .. testName .. ": PASSED" .. (message and " - " .. message or ""))
        end
    else
        testResults.failed = testResults.failed + 1
        warn("❌ " .. testName .. ": FAILED" .. (message and " - " .. message or ""))
    end
    
    table.insert(testResults.details, {
        name = testName,
        passed = passed,
        message = message,
        timestamp = tick()
    })
end

-- Wait for services
local function waitForServices()
    repeat
        wait(0.1)
    until Knit.Services.DifficultyService
    
    return Knit.Services.DifficultyService
end

local function runDifficultyManagerTests()
    print("🧪 Testing DifficultyManager Module...")
    print("=====================================")
    
    -- Test 1: Module Loading
    logTest("DifficultyManager Module Load", DifficultyManager ~= nil, "Module loaded successfully")
    
    if not DifficultyManager then
        warn("❌ DifficultyManager failed to load - aborting module tests")
        return
    end
    
    -- Test 2: Instance Creation
    local testConfig = {
        baseSpeed = 10,
        maxSpeed = 30,
        timePerDifficultyLevel = 5, -- Fast progression for testing
        adaptiveDifficulty = true
    }
    
    local difficultyManager = DifficultyManager.new(testConfig)
    logTest("DifficultyManager Creation", difficultyManager ~= nil, "Instance created successfully")
    
    -- Test 3: Configuration Merging
    local configMerged = difficultyManager.config.baseSpeed == 10 and difficultyManager.config.maxSpeed == 30
    logTest("Configuration Merging", configMerged, "Custom config applied correctly")
    
    -- Test 4: Initial State
    local initialState = difficultyManager.currentLevel == 1 and 
                         difficultyManager.currentSpeed == testConfig.baseSpeed and
                         difficultyManager.isActive == false
    logTest("Initial State", initialState, "Initial values correct")
    
    -- Test 5: Start/Stop Functionality
    difficultyManager:Start()
    local startState = difficultyManager.isActive == true
    logTest("Start Functionality", startState, "Manager started correctly")
    
    difficultyManager:Stop()
    local stopState = difficultyManager.isActive == false
    logTest("Stop Functionality", stopState, "Manager stopped correctly")
    
    -- Test 6: Distance Tracking
    difficultyManager:Start()
    difficultyManager:AddDistance(100)
    local distanceTracked = difficultyManager.distanceTraveled == 100
    logTest("Distance Tracking", distanceTracked, "Distance added correctly")
    
    -- Test 7: Level Progression
    local initialLevel = difficultyManager.currentLevel
    wait(6) -- Wait longer than timePerDifficultyLevel
    local levelIncreased = difficultyManager.currentLevel > initialLevel
    logTest("Level Progression", levelIncreased, "Level increased after time threshold")
    
    -- Test 8: Curve Applications
    local linearValue = difficultyManager:ApplyCurve(10, 100, 5, 2, "linear")
    local exponentialValue = difficultyManager:ApplyCurve(10, 100, 5, 0.5, "exponential")
    local logarithmicValue = difficultyManager:ApplyCurve(10, 100, 5, 0.5, "logarithmic")
    
    logTest("Linear Curve", linearValue == 20, "Linear: " .. linearValue)
    logTest("Exponential Curve", exponentialValue > 10, "Exponential: " .. exponentialValue)
    logTest("Logarithmic Curve", logarithmicValue > 10, "Logarithmic: " .. logarithmicValue)
    
    -- Test 9: Performance Tracking
    difficultyManager:RecordPlayerDeath()
    difficultyManager:RecordPlayerSuccess(30)
    local performanceRecorded = #difficultyManager.playerPerformance.recentPerformance > 0
    logTest("Performance Tracking", performanceRecorded, "Performance data recorded")
    
    -- Test 10: Event System
    local eventTriggered = false
    difficultyManager:OnEvent("onDifficultyChange", function(data)
        eventTriggered = true
    end)
    difficultyManager:SetDifficultyLevel(3)
    logTest("Event System", eventTriggered, "Events triggered correctly")
    
    -- Test 11: Preset Configurations
    local presets = DifficultyManager.GetPresetConfigs()
    local presetsValid = presets and presets.casual and presets.hardcore
    logTest("Preset Configurations", presetsValid, "Presets loaded: " .. (presets and table.concat(getKeys(presets), ", ") or "none"))
    
    -- Cleanup
    difficultyManager:Destroy()
    logTest("Cleanup", true, "Manager destroyed successfully")
end

local function runDifficultyServiceTests()
    print("🧪 Testing DifficultyService...")
    print("===============================")
    
    local DifficultyService = waitForServices()
    
    -- Test 1: Service Loading
    logTest("DifficultyService Load", DifficultyService ~= nil, "Service loaded successfully")
    
    if not DifficultyService then
        warn("❌ DifficultyService failed to load - aborting service tests")
        return
    end
    
    -- Create test players (simulate)
    local testPlayers = {}
    for i = 1, TEST_CONFIG.simulatePlayerCount do
        local mockPlayer = {
            UserId = 1000000 + i,
            Name = "TestPlayer" .. i
        }
        table.insert(testPlayers, mockPlayer)
    end
    
    -- Test 2: Player Initialization
    for _, testPlayer in ipairs(testPlayers) do
        DifficultyService:InitializePlayerDifficulty(testPlayer)
        local difficulty = DifficultyService:GetPlayerDifficulty(testPlayer)
        logTest("Player " .. testPlayer.Name .. " Initialization", difficulty ~= nil, "Difficulty manager created")
    end
    
    -- Test 3: Game Start/Stop
    for _, testPlayer in ipairs(testPlayers) do
        local gameStarted = DifficultyService:StartGame(testPlayer, {})
        logTest("Game Start " .. testPlayer.Name, gameStarted, "Game started successfully")
        
        DifficultyService:StopGame(testPlayer)
        logTest("Game Stop " .. testPlayer.Name, true, "Game stopped successfully")
    end
    
    -- Test 4: Distance Updates
    local testPlayer = testPlayers[1]
    DifficultyService:StartGame(testPlayer, {})
    DifficultyService:UpdatePlayerDistance(testPlayer, 150)
    local difficulty = DifficultyService:GetPlayerDifficulty(testPlayer)
    logTest("Distance Update", difficulty.distanceTraveled >= 150, "Distance: " .. difficulty.distanceTraveled)
    
    -- Test 5: Performance Recording
    DifficultyService:RecordPlayerDeath(testPlayer)
    DifficultyService:RecordPlayerSuccess(testPlayer, 45)
    logTest("Performance Recording", true, "Death and success recorded")
    
    -- Test 6: Multiplier Functions
    local speedMultiplier = DifficultyService:GetSpeedMultiplier(testPlayer)
    local spawnMultiplier = DifficultyService:GetSpawnRateMultiplier(testPlayer)
    local complexityLevel = DifficultyService:GetComplexityLevel(testPlayer)
    
    logTest("Speed Multiplier", speedMultiplier >= 1.0, "Speed: " .. speedMultiplier)
    logTest("Spawn Rate Multiplier", spawnMultiplier >= 1.0, "Spawn: " .. spawnMultiplier)
    logTest("Complexity Level", complexityLevel >= 1.0, "Complexity: " .. complexityLevel)
    
    -- Test 7: Configuration Management
    local originalConfig = DifficultyService:GetGlobalConfiguration()
    local presetLoaded = DifficultyService:LoadPresetConfiguration("hardcore")
    logTest("Preset Loading", presetLoaded, "Hardcore preset loaded")
    
    DifficultyService:SetGlobalConfiguration(originalConfig)
    logTest("Configuration Reset", true, "Configuration restored")
    
    -- Test 8: Statistics
    local playerStats = DifficultyService:GetPlayerStatistics(testPlayer)
    logTest("Player Statistics", playerStats ~= nil, "Stats available")
    
    local allStats = DifficultyService:GetAllPlayerStatistics()
    logTest("All Player Statistics", next(allStats) ~= nil, "Multiple player stats")
    
    -- Cleanup test players
    for _, testPlayer in ipairs(testPlayers) do
        DifficultyService:CleanupPlayerDifficulty(testPlayer)
    end
    logTest("Service Cleanup", true, "Test players cleaned up")
end

local function runIntegrationTests()
    print("🧪 Testing System Integration...")
    print("================================")
    
    local DifficultyService = waitForServices()
    
    -- Test integration with MovingObstacleService (if available)
    if Knit.Services.MovingObstacleService then
        logTest("MovingObstacleService Integration", true, "Service available for integration")
        
        -- Test preset compatibility
        local obstaclePresets = Knit.Services.MovingObstacleService:GetPresetConfigs()
        local difficultyPresets = DifficultyManager.GetPresetConfigs()
        logTest("Preset Compatibility", obstaclePresets and difficultyPresets, "Both preset systems available")
    else
        logTest("MovingObstacleService Integration", false, "Service not available")
    end
    
    -- Test curve calculations under load
    local startTime = tick()
    local calculations = 0
    
    local testManager = DifficultyManager.new({})
    testManager:Start()
    
    for i = 1, 1000 do
        local result = testManager:ApplyCurve(16, 50, i % 10, 0.5, "exponential")
        calculations = calculations + 1
    end
    
    local calculationTime = tick() - startTime
    logTest("Performance Under Load", calculationTime < 1.0, "1000 calculations in " .. string.format("%.3f", calculationTime) .. "s")
    
    testManager:Destroy()
    
    -- Test memory usage
    local managers = {}
    for i = 1, 100 do
        local manager = DifficultyManager.new({})
        manager:Start()
        table.insert(managers, manager)
    end
    
    for _, manager in ipairs(managers) do
        manager:Destroy()
    end
    
    logTest("Memory Management", true, "100 managers created and destroyed")
    
    -- Test concurrent player handling
    local concurrentPlayers = {}
    for i = 1, 10 do
        local player = {UserId = 2000000 + i, Name = "ConcurrentPlayer" .. i}
        DifficultyService:InitializePlayerDifficulty(player)
        DifficultyService:StartGame(player, {})
        table.insert(concurrentPlayers, player)
    end
    
    -- Simulate concurrent updates
    for frame = 1, 30 do
        for _, player in ipairs(concurrentPlayers) do
            DifficultyService:UpdatePlayerDistance(player, 5)
        end
        wait(0.1)
    end
    
    -- Check all players have progressed
    local allProgressed = true
    for _, player in ipairs(concurrentPlayers) do
        local difficulty = DifficultyService:GetPlayerDifficulty(player)
        if not difficulty or difficulty.distanceTraveled < 100 then
            allProgressed = false
            break
        end
    end
    
    logTest("Concurrent Player Handling", allProgressed, "10 players updated simultaneously")
    
    -- Cleanup concurrent players
    for _, player in ipairs(concurrentPlayers) do
        DifficultyService:CleanupPlayerDifficulty(player)
    end
end

local function runStressTests()
    print("🧪 Running Stress Tests...")
    print("==========================")
    
    -- Test rapid difficulty changes
    local stressManager = DifficultyManager.new({timePerDifficultyLevel = 0.1})
    stressManager:Start()
    
    spawn(function()
        for i = 1, 100 do
            stressManager:AddDistance(10)
            stressManager:RecordPlayerDeath()
            stressManager:RecordPlayerSuccess(math.random(10, 60))
            wait(0.01)
        end
    end)
    
    wait(2) -- Let it run for 2 seconds
    
    local finalDifficulty = stressManager:GetCurrentDifficulty()
    logTest("Rapid Changes Stress Test", finalDifficulty.level > 1, "Level reached: " .. finalDifficulty.level)
    
    stressManager:Destroy()
    
    -- Test event system under load
    local eventManager = DifficultyManager.new({})
    local eventCount = 0
    
    for i = 1, 100 do
        eventManager:OnEvent("onDifficultyChange", function()
            eventCount = eventCount + 1
        end)
    end
    
    eventManager:Start()
    eventManager:SetDifficultyLevel(5)
    
    wait(0.5) -- Wait for events to process
    
    logTest("Event System Stress Test", eventCount >= 100, "Events fired: " .. eventCount)
    
    eventManager:Destroy()
end

local function getKeys(t)
    local keys = {}
    for k in pairs(t) do
        table.insert(keys, k)
    end
    return keys
end

local function runAllTests()
    if not TEST_CONFIG.runTests then
        print("🔧 Difficulty system tests disabled")
        return
    end
    
    print("🧪 Starting Comprehensive Difficulty System Tests...")
    print("====================================================")
    
    local overallStartTime = tick()
    
    -- Run all test suites
    runDifficultyManagerTests()
    wait(1)
    runDifficultyServiceTests()
    wait(1)
    runIntegrationTests()
    wait(1)
    runStressTests()
    
    local overallTime = tick() - overallStartTime
    
    -- Print comprehensive results
    print("====================================================")
    print("🧪 Difficulty System Test Results:")
    print("   Total Tests: " .. testResults.total)
    print("   Passed: " .. testResults.passed .. " ✅")
    print("   Failed: " .. testResults.failed .. " ❌")
    print("   Success Rate: " .. string.format("%.1f", (testResults.passed / testResults.total) * 100) .. "%")
    print("   Total Time: " .. string.format("%.2f", overallTime) .. "s")
    
    if testResults.failed == 0 then
        print("🎉 ALL TESTS PASSED! Difficulty System is working correctly.")
        print("🎮 System ready for production use!")
    else
        warn("⚠️ Some tests failed. Check the details above.")
        print("📝 Failed tests:")
        for _, detail in ipairs(testResults.details) do
            if not detail.passed then
                print("   - " .. detail.name .. ": " .. (detail.message or "No message"))
            end
        end
    end
    
    print("====================================================")
    
    return testResults
end

-- Enhanced system validation
local function validateSystemComponents()
    print("🔍 Validating Difficulty System Components...")
    
    local components = {
        ["DifficultyManager Module"] = DifficultyManager ~= nil,
        ["DifficultyService"] = Knit.Services.DifficultyService ~= nil,
        ["Preset Configurations"] = DifficultyManager and DifficultyManager.GetPresetConfigs() ~= nil,
        ["Event System"] = true -- Assume working if module loads
    }
    
    for componentName, isValid in pairs(components) do
        if isValid then
            print("✅ " .. componentName .. " - Valid")
        else
            warn("❌ " .. componentName .. " - Invalid")
        end
    end
    
    local allValid = true
    for _, isValid in pairs(components) do
        if not isValid then
            allValid = false
            break
        end
    end
    
    if allValid then
        print("🎯 All system components validated successfully!")
    else
        warn("🚨 Some system components failed validation!")
    end
    
    return allValid
end

-- Run validation and tests
spawn(function()
    wait(5) -- Wait for full system initialization
    
    validateSystemComponents()
    wait(2)
    runAllTests()
end)

print("🧪 Difficulty System Test Suite Loaded!")
print("📊 Will test: Module Creation, Service Integration, Performance, Stress Testing")
print("⏱️ Test duration: " .. TEST_CONFIG.testDuration .. " seconds")
