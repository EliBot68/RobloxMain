-- MemoryManagementTest.server.luau
-- Test script to validate memory management and cleanup functionality

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local MemoryManager = require(ReplicatedStorage.Shared.utilities.MemoryManager)

local MemoryManagementTest = {}

-- Test configuration
local TEST_CONFIG = {
    enableDetailedLogging = true,
    testPlayerLimit = 5,
    testConnectionCount = 10,
    testTweenCount = 5,
    testTaskCount = 3
}

-- ========================================
-- CONNECTION MANAGEMENT TESTS
-- ========================================

function MemoryManagementTest:TestConnectionManagement()
    print("🧪 Testing Connection Management...")
    
    local testPlayerId = "test_player_connections"
    local testConnections = {}
    
    -- Create test connections
    for i = 1, TEST_CONFIG.testConnectionCount do
        local connection = workspace.ChildAdded:Connect(function() end)
        local connectionName = "test_connection_" .. i
        
        MemoryManager:RegisterConnection(testPlayerId, connectionName, connection)
        testConnections[connectionName] = connection
    end
    
    -- Verify connections are registered
    local stats = MemoryManager:GetMemoryStats()
    local playerStats = stats.playerDetails[testPlayerId]
    
    if playerStats and playerStats.connections == TEST_CONFIG.testConnectionCount then
        print("✅ Connection registration test passed")
    else
        warn("❌ Connection registration test failed")
        return false
    end
    
    -- Test individual disconnection
    MemoryManager:DisconnectConnection(testPlayerId, "test_connection_1")
    
    stats = MemoryManager:GetMemoryStats()
    playerStats = stats.playerDetails[testPlayerId]
    
    if playerStats and playerStats.connections == (TEST_CONFIG.testConnectionCount - 1) then
        print("✅ Individual connection disconnection test passed")
    else
        warn("❌ Individual connection disconnection test failed")
        return false
    end
    
    -- Test bulk disconnection
    MemoryManager:DisconnectAllPlayerConnections(testPlayerId)
    
    stats = MemoryManager:GetMemoryStats()
    playerStats = stats.playerDetails[testPlayerId]
    
    if not playerStats or playerStats.connections == 0 then
        print("✅ Bulk connection disconnection test passed")
        return true
    else
        warn("❌ Bulk connection disconnection test failed")
        return false
    end
end

-- ========================================
-- TWEEN MANAGEMENT TESTS
-- ========================================

function MemoryManagementTest:TestTweenManagement()
    print("🧪 Testing Tween Management...")
    
    local testPlayerId = "test_player_tweens"
    local TweenService = game:GetService("TweenService")
    
    -- Create test part for tweening
    local testPart = Instance.new("Part")
    testPart.Name = "TestPart"
    testPart.Parent = workspace
    
    -- Create test tweens
    for i = 1, TEST_CONFIG.testTweenCount do
        local tween = TweenService:Create(
            testPart,
            TweenInfo.new(1, Enum.EasingStyle.Linear),
            {Transparency = 0.5}
        )
        
        local tweenName = "test_tween_" .. i
        MemoryManager:RegisterTween(testPlayerId, tweenName, tween)
    end
    
    -- Verify tweens are registered
    local stats = MemoryManager:GetMemoryStats()
    local playerStats = stats.playerDetails[testPlayerId]
    
    if playerStats and playerStats.tweens == TEST_CONFIG.testTweenCount then
        print("✅ Tween registration test passed")
    else
        warn("❌ Tween registration test failed")
        testPart:Destroy()
        return false
    end
    
    -- Test tween cleanup
    MemoryManager:CleanupAllPlayerTweens(testPlayerId)
    
    stats = MemoryManager:GetMemoryStats()
    playerStats = stats.playerDetails[testPlayerId]
    
    if not playerStats or playerStats.tweens == 0 then
        print("✅ Tween cleanup test passed")
        testPart:Destroy()
        return true
    else
        warn("❌ Tween cleanup test failed")
        testPart:Destroy()
        return false
    end
end

-- ========================================
-- TASK MANAGEMENT TESTS
-- ========================================

function MemoryManagementTest:TestTaskManagement()
    print("🧪 Testing Task Management...")
    
    local testPlayerId = "test_player_tasks"
    
    -- Create test tasks
    for i = 1, TEST_CONFIG.testTaskCount do
        local taskThread = task.spawn(function()
            while true do
                task.wait(1)
            end
        end)
        
        local taskName = "test_task_" .. i
        MemoryManager:RegisterTask(testPlayerId, taskName, taskThread)
    end
    
    -- Verify tasks are registered
    local stats = MemoryManager:GetMemoryStats()
    local playerStats = stats.playerDetails[testPlayerId]
    
    if playerStats and playerStats.tasks == TEST_CONFIG.testTaskCount then
        print("✅ Task registration test passed")
    else
        warn("❌ Task registration test failed")
        return false
    end
    
    -- Test task cleanup
    MemoryManager:CancelAllPlayerTasks(testPlayerId)
    
    stats = MemoryManager:GetMemoryStats()
    playerStats = stats.playerDetails[testPlayerId]
    
    if not playerStats or playerStats.tasks == 0 then
        print("✅ Task cleanup test passed")
        return true
    else
        warn("❌ Task cleanup test failed")
        return false
    end
end

-- ========================================
-- GAME OBJECT MANAGEMENT TESTS
-- ========================================

function MemoryManagementTest:TestGameObjectManagement()
    print("🧪 Testing Game Object Management...")
    
    local testPlayerId = "test_player_objects"
    
    -- Create test objects
    local testObjects = {}
    for i = 1, 5 do
        local testGui = Instance.new("ScreenGui")
        testGui.Name = "TestGui_" .. i
        testGui.Parent = game.Players.LocalPlayer and game.Players.LocalPlayer.PlayerGui or workspace
        
        local objectName = "test_object_" .. i
        MemoryManager:RegisterGameObject(testPlayerId, objectName, testGui)
        testObjects[objectName] = testGui
    end
    
    -- Verify objects are registered
    local stats = MemoryManager:GetMemoryStats()
    local playerStats = stats.playerDetails[testPlayerId]
    
    if playerStats and playerStats.gameObjects == 5 then
        print("✅ Game object registration test passed")
    else
        warn("❌ Game object registration test failed")
        return false
    end
    
    -- Test object destruction
    MemoryManager:DestroyAllPlayerGameObjects(testPlayerId)
    
    stats = MemoryManager:GetMemoryStats()
    playerStats = stats.playerDetails[testPlayerId]
    
    if not playerStats or playerStats.gameObjects == 0 then
        print("✅ Game object cleanup test passed")
        return true
    else
        warn("❌ Game object cleanup test failed")
        return false
    end
end

-- ========================================
-- COMPREHENSIVE CLEANUP TESTS
-- ========================================

function MemoryManagementTest:TestComprehensiveCleanup()
    print("🧪 Testing Comprehensive Cleanup...")
    
    local testPlayerId = "test_player_comprehensive"
    local TweenService = game:GetService("TweenService")
    
    -- Create mixed resources
    local connection = workspace.ChildAdded:Connect(function() end)
    MemoryManager:RegisterConnection(testPlayerId, "test_connection", connection)
    
    local testPart = Instance.new("Part")
    testPart.Parent = workspace
    local tween = TweenService:Create(testPart, TweenInfo.new(1), {Transparency = 0.5})
    MemoryManager:RegisterTween(testPlayerId, "test_tween", tween)
    
    local taskThread = task.spawn(function()
        while true do task.wait(1) end
    end)
    MemoryManager:RegisterTask(testPlayerId, "test_task", taskThread)
    
    local testGui = Instance.new("ScreenGui")
    testGui.Parent = workspace
    MemoryManager:RegisterGameObject(testPlayerId, "test_gui", testGui)
    
    -- Verify all resources are registered
    local stats = MemoryManager:GetMemoryStats()
    local playerStats = stats.playerDetails[testPlayerId]
    
    if playerStats and 
       playerStats.connections >= 1 and
       playerStats.tweens >= 1 and
       playerStats.tasks >= 1 and
       playerStats.gameObjects >= 1 then
        print("✅ Comprehensive resource registration test passed")
    else
        warn("❌ Comprehensive resource registration test failed")
        testPart:Destroy()
        return false
    end
    
    -- Test comprehensive cleanup
    local cleanupStats = MemoryManager:CleanupPlayer(testPlayerId)
    
    if cleanupStats.connections >= 1 and
       cleanupStats.tweens >= 1 and
       cleanupStats.tasks >= 1 and
       cleanupStats.gameObjects >= 1 then
        print("✅ Comprehensive cleanup test passed")
        testPart:Destroy()
        return true
    else
        warn("❌ Comprehensive cleanup test failed")
        testPart:Destroy()
        return false
    end
end

-- ========================================
-- RUN ALL TESTS
-- ========================================

function MemoryManagementTest:RunAllTests()
    print("🧪 Starting Memory Management Tests...")
    print("=" .. string.rep("=", 50))
    
    local testResults = {}
    
    -- Run individual tests
    testResults.connections = self:TestConnectionManagement()
    testResults.tweens = self:TestTweenManagement()
    testResults.tasks = self:TestTaskManagement()
    testResults.gameObjects = self:TestGameObjectManagement()
    testResults.comprehensive = self:TestComprehensiveCleanup()
    
    -- Calculate results
    local passedTests = 0
    local totalTests = 0
    
    for testName, result in pairs(testResults) do
        totalTests = totalTests + 1
        if result then
            passedTests = passedTests + 1
        end
    end
    
    -- Print results
    print("=" .. string.rep("=", 50))
    print("🧪 Memory Management Test Results:")
    print("   Total Tests: " .. totalTests)
    print("   Passed Tests: " .. passedTests)
    print("   Failed Tests: " .. (totalTests - passedTests))
    print("   Success Rate: " .. math.floor((passedTests / totalTests) * 100) .. "%")
    
    if passedTests == totalTests then
        print("✅ All memory management tests passed!")
        MemoryManager:PrintMemoryReport()
        return true
    else
        warn("❌ Some memory management tests failed!")
        return false
    end
end

-- ========================================
-- AUTO-RUN TESTS
-- ========================================

-- Wait for MemoryManager to be fully loaded
task.wait(2)

-- Run tests
if MemoryManager then
    MemoryManagementTest:RunAllTests()
else
    warn("❌ MemoryManager not found - cannot run tests")
end

return MemoryManagementTest
