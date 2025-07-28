-- MovingObstacleIntegrationTest.server.luau
-- Integration test for the MovingObstacle system

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Knit = require(ReplicatedStorage.Packages.Knit)
local SafeRequire = require(ReplicatedStorage.Shared.utils.SafeRequire)

-- Test configuration
local TEST_CONFIG = {
    runTests = true,
    verboseOutput = true,
    testDuration = 30 -- seconds
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

local function runMovingObstacleTests()
    if not TEST_CONFIG.runTests then
        print("🔧 Moving Obstacle integration tests disabled")
        return
    end
    
    print("🧪 Starting Moving Obstacle Integration Tests...")
    print("================================================")
    
    -- Wait for services to load
    repeat
        wait(0.1)
    until Knit.Services.MovingObstacleService
    
    local MovingObstacleService = Knit.Services.MovingObstacleService
    local MovingObstacle = SafeRequire.requireWithRetry(
        ReplicatedStorage.Shared.modules.MovingObstacle,
        3
    )
    
    -- Test 1: Module Loading
    logTest("MovingObstacle Module Load", MovingObstacle ~= nil, "Module loaded successfully")
    logTest("MovingObstacleService Load", MovingObstacleService ~= nil, "Service loaded successfully")
    
    if not MovingObstacle or not MovingObstacleService then
        warn("❌ Critical components failed to load - aborting tests")
        return
    end
    
    -- Test 2: Basic Obstacle Creation
    local testConfig = {
        movementType = "Linear",
        speed = 5,
        direction = Vector3.new(1, 0, 0),
        movementBounds = {
            min = Vector3.new(-10, 0, 0),
            max = Vector3.new(10, 0, 0)
        },
        obstacleSize = Vector3.new(2, 4, 2),
        obstacleColor = Color3.fromRGB(255, 100, 100)
    }
    
    local testObstacleId, testObstacle = MovingObstacleService:CreateObstacle(
        testConfig,
        Vector3.new(0, 50, 0),
        workspace
    )
    
    logTest("Obstacle Creation", testObstacleId ~= nil, "Obstacle ID: " .. tostring(testObstacleId))
    
    -- Test 3: Obstacle Movement
    if testObstacleId then
        local startSuccess = MovingObstacleService:StartObstacle(testObstacleId)
        logTest("Obstacle Start Movement", startSuccess, "Movement started successfully")
        
        -- Wait and check if obstacle is moving
        wait(2)
        local stopSuccess = MovingObstacleService:StopObstacle(testObstacleId)
        logTest("Obstacle Stop Movement", stopSuccess, "Movement stopped successfully")
    end
    
    -- Test 4: Service Management Functions
    local activeCount = MovingObstacleService:GetActiveObstacles()
    logTest("Active Obstacle Count", activeCount > 0, "Active obstacles: " .. activeCount)
    
    local presets = MovingObstacleService:GetPresetConfigs()
    logTest("Preset Configurations", presets ~= nil and next(presets) ~= nil, "Presets loaded: " .. (presets and #presets or 0))
    
    -- Test 5: Multiple Movement Types
    local movementTypes = {"Linear", "Circular", "Pendulum", "FigureEight", "Random", "Waypoint"}
    local createdTestObstacles = {}
    
    for i, movementType in ipairs(movementTypes) do
        local config = table.clone(testConfig)
        config.movementType = movementType
        
        if movementType == "Waypoint" then
            config.waypoints = {
                Vector3.new(0, 0, 0),
                Vector3.new(5, 0, 0),
                Vector3.new(0, 5, 0),
                Vector3.new(-5, 0, 0)
            }
        end
        
        local obstacleId = MovingObstacleService:CreateObstacle(
            config,
            Vector3.new(i * 10, 60, 0),
            workspace
        )
        
        if obstacleId then
            table.insert(createdTestObstacles, obstacleId)
            MovingObstacleService:StartObstacle(obstacleId)
        end
        
        logTest(movementType .. " Movement Type", obstacleId ~= nil, "Created with ID: " .. tostring(obstacleId))
    end
    
    -- Test 6: Track-based Management
    local trackConfigs = {
        {
            position = Vector3.new(0, 70, 0),
            config = presets and presets.horizontalSlider or testConfig
        },
        {
            position = Vector3.new(10, 70, 0),
            config = presets and presets.circularSpinner or testConfig
        }
    }
    
    local trackObstacles = MovingObstacleService:CreateTrackObstacles("TestTrack", trackConfigs)
    logTest("Track Obstacle Creation", #trackObstacles > 0, "Created " .. #trackObstacles .. " track obstacles")
    
    local trackStarted = MovingObstacleService:StartTrackObstacles("TestTrack")
    logTest("Track Obstacle Start", trackStarted, "Track obstacles started")
    
    -- Test 7: Performance Test (brief)
    local performanceStartTime = tick()
    
    -- Create many obstacles quickly
    local performanceObstacles = {}
    for i = 1, 10 do
        local obstacleId = MovingObstacleService:CreateObstacle(
            testConfig,
            Vector3.new(math.random(-50, 50), 80, math.random(-50, 50)),
            workspace
        )
        if obstacleId then
            table.insert(performanceObstacles, obstacleId)
            MovingObstacleService:StartObstacle(obstacleId)
        end
    end
    
    local performanceTime = tick() - performanceStartTime
    logTest("Performance Test", performanceTime < 1, "Created 10 obstacles in " .. string.format("%.3f", performanceTime) .. "s")
    
    -- Test 8: Cleanup Test
    wait(3) -- Let obstacles run briefly
    
    -- Clean up test obstacles
    if testObstacleId then
        local destroySuccess = MovingObstacleService:DestroyObstacle(testObstacleId)
        logTest("Individual Obstacle Cleanup", destroySuccess, "Test obstacle destroyed")
    end
    
    for _, obstacleId in ipairs(createdTestObstacles) do
        MovingObstacleService:DestroyObstacle(obstacleId)
    end
    
    for _, obstacleId in ipairs(performanceObstacles) do
        MovingObstacleService:DestroyObstacle(obstacleId)
    end
    
    local trackCleared = MovingObstacleService:ClearTrackObstacles("TestTrack")
    logTest("Track Cleanup", trackCleared, "Test track cleared")
    
    -- Final obstacle count check
    wait(1)
    local finalCount = MovingObstacleService:GetActiveObstacles()
    logTest("Final Cleanup Verification", finalCount == 0, "Final active count: " .. finalCount)
    
    -- Print test summary
    print("================================================")
    print("🧪 Moving Obstacle Integration Test Results:")
    print("   Total Tests: " .. testResults.total)
    print("   Passed: " .. testResults.passed .. " ✅")
    print("   Failed: " .. testResults.failed .. " ❌")
    print("   Success Rate: " .. string.format("%.1f", (testResults.passed / testResults.total) * 100) .. "%")
    
    if testResults.failed == 0 then
        print("🎉 ALL TESTS PASSED! Moving Obstacle system is working correctly.")
    else
        warn("⚠️ Some tests failed. Check the details above.")
    end
    
    print("================================================")
    
    return testResults
end

-- Enhanced validation function
local function validateSystemIntegration()
    print("🔍 Validating Moving Obstacle System Integration...")
    
    local validationResults = {
        moduleStructure = false,
        serviceIntegration = false,
        knittIntegration = false,
        errorHandling = false
    }
    
    -- Check module structure
    local MovingObstacle = SafeRequire.requireWithRetry(
        ReplicatedStorage.Shared.modules.MovingObstacle,
        3
    )
    
    if MovingObstacle and MovingObstacle.new and MovingObstacle.CreateLinear then
        validationResults.moduleStructure = true
        print("✅ MovingObstacle module structure valid")
    else
        warn("❌ MovingObstacle module structure invalid")
    end
    
    -- Check service integration
    if Knit.Services.MovingObstacleService then
        validationResults.serviceIntegration = true
        print("✅ MovingObstacleService integration valid")
    else
        warn("❌ MovingObstacleService integration failed")
    end
    
    -- Check Knit integration
    local service = Knit.Services.MovingObstacleService
    if service and service.CreateObstacle and service.GetPresetConfigs then
        validationResults.knittIntegration = true
        print("✅ Knit framework integration valid")
    else
        warn("❌ Knit framework integration failed")
    end
    
    -- Check error handling
    pcall(function()
        if service then
            service:CreateObstacle(nil, nil, nil) -- Should handle gracefully
            validationResults.errorHandling = true
            print("✅ Error handling validation passed")
        end
    end)
    
    local allValid = validationResults.moduleStructure and 
                     validationResults.serviceIntegration and 
                     validationResults.knittIntegration and
                     validationResults.errorHandling
    
    if allValid then
        print("🎯 System integration validation: PASSED")
    else
        warn("🚨 System integration validation: FAILED")
    end
    
    return validationResults
end

-- Run tests after a delay to ensure everything is loaded
spawn(function()
    wait(5) -- Wait for full system initialization
    
    validateSystemIntegration()
    wait(2)
    runMovingObstacleTests()
end)
