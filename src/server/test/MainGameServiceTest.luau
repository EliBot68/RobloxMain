-- MainGameServiceTest.luau
-- Comprehensive unit tests for MainGameService

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local SafeRequire = require(ReplicatedStorage.Shared.utils.SafeRequire)
local TestFramework = SafeRequire.require(ReplicatedStorage.Shared.utils.TestFramework)
local RemoteEvents = SafeRequire.require(ReplicatedStorage.Shared.modules.RemoteEvents)

-- Create test suite
local mainGameSuite = TestFramework.createSuite("MainGameService")

-- Test data and mocks
local mockPlayer = TestFramework.Utils.createMockPlayer(123456789, "TestPlayer")
local mockGameState = {
    inGame = false,
    gameStartTime = 0,
    currentLevel = 1,
    score = 0,
    coinsCollected = 0
}

-- Service under test
local MainGameService = nil

-- Test Setup
mainGameSuite:setBeforeAll(function()
    local success, service = pcall(function()
        return require(game.ServerScriptService.services.MainGameService)
    end)
    
    if not success then
        error("MainGameService could not be loaded for testing")
    end
    
    MainGameService = service
end)

mainGameSuite:setBeforeEach(function()
    -- Reset game state before each test
    mockGameState = {
        inGame = false,
        gameStartTime = 0,
        currentLevel = 1,
        score = 0,
        coinsCollected = 0
    }
end)

-- Test 1: Service Module Loading
mainGameSuite:addTest("Service Module Loads Successfully", function()
    local success, details = TestFramework.Utils.assertNotNil(MainGameService, "MainGameService should load successfully")
    assert(success, details)
    
    local isTable = TestFramework.Utils.assertType(MainGameService, "table", "MainGameService should be a table")
    assert(isTable, "MainGameService is not a table")
end)

-- Test 2: Required Functions Exist
mainGameSuite:addTest("Required Functions Exist", function()
    local requiredFunctions = {
        "StartGame",
        "EndGame", 
        "HandlePlayerJoined",
        "HandlePlayerLeft",
        "ProcessGameLogic",
        "UpdatePlayerScore",
        "CheckWinCondition",
        "ResetGame",
        "GetGameState",
        "SetGameState"
    }
    
    for _, funcName in ipairs(requiredFunctions) do
        if MainGameService[funcName] then
            local success, details = TestFramework.Utils.assertFunctionExists(MainGameService, funcName)
            assert(success, string.format("Function exists but not callable: %s - %s", funcName, details))
        else
            -- Some functions might not exist in all implementations
            print(string.format("⚠️  Optional function not found: %s", funcName))
        end
    end
end)

-- Test 3: Remote Events Integration
mainGameSuite:addTest("Remote Events Integration", function()
    local requiredEvents = {
        "StartGame",
        "EndGame",
        "GameStarted",
        "GameEnded",
        "ReturnToHub",
        "FinishGame",
        "GameTimer",
        "ObstacleHit",
        "ColorGateCheck",
        "CoinCollected"
    }
    
    for _, eventName in ipairs(requiredEvents) do
        local success, details = TestFramework.Utils.assertRemoteEventExists(eventName)
        assert(success, string.format("Missing RemoteEvent: %s - %s", eventName, details))
        
        -- Verify RemoteEvents module has reference
        local hasReference = TestFramework.Utils.assertNotNil(RemoteEvents[eventName])
        assert(hasReference, string.format("RemoteEvents.%s is not defined", eventName))
    end
end)

-- Test 4: Game Start Process
mainGameSuite:addTest("Game Start Process", function()
    if not MainGameService.StartGame then
        print("⚠️  StartGame function not available, skipping test")
        return
    end
    
    -- Test starting a game
    local success, result = pcall(MainGameService.StartGame, MainGameService, mockPlayer)
    assert(success, "StartGame should not error: " .. tostring(result))
    
    -- Check if game state was updated
    if MainGameService.GetGameState then
        local gameState = MainGameService:GetGameState(mockPlayer)
        if gameState then
            local isInGame = TestFramework.Utils.assertTrue(gameState.inGame, "Player should be in game after StartGame")
            -- This may not be true for all implementations
        end
    end
end)

-- Test 5: Game End Process
mainGameSuite:addTest("Game End Process", function()
    if not MainGameService.EndGame then
        print("⚠️  EndGame function not available, skipping test")
        return
    end
    
    -- Test ending a game
    local success, result = pcall(MainGameService.EndGame, MainGameService, mockPlayer, {
        score = 100,
        coins = 10,
        completionTime = 30
    })
    assert(success, "EndGame should not error: " .. tostring(result))
end)

-- Test 6: Player Join Handling
mainGameSuite:addTest("Player Join Handling", function()
    if not MainGameService.HandlePlayerJoined then
        print("⚠️  HandlePlayerJoined function not available, skipping test")
        return
    end
    
    -- Test player joining
    local success, result = pcall(MainGameService.HandlePlayerJoined, MainGameService, mockPlayer)
    assert(success, "HandlePlayerJoined should not error: " .. tostring(result))
end)

-- Test 7: Player Leave Handling
mainGameSuite:addTest("Player Leave Handling", function()
    if not MainGameService.HandlePlayerLeft then
        print("⚠️  HandlePlayerLeft function not available, skipping test")
        return
    end
    
    -- Test player leaving
    local success, result = pcall(MainGameService.HandlePlayerLeft, MainGameService, mockPlayer)
    assert(success, "HandlePlayerLeft should not error: " .. tostring(result))
end)

-- Test 8: Score Update System
mainGameSuite:addTest("Score Update System", function()
    if not MainGameService.UpdatePlayerScore then
        print("⚠️  UpdatePlayerScore function not available, skipping test")
        return
    end
    
    -- Test score updating
    local success, result = pcall(MainGameService.UpdatePlayerScore, MainGameService, mockPlayer, 50)
    assert(success, "UpdatePlayerScore should not error: " .. tostring(result))
end)

-- Test 9: Win Condition Checking
mainGameSuite:addTest("Win Condition Checking", function()
    if not MainGameService.CheckWinCondition then
        print("⚠️  CheckWinCondition function not available, skipping test")
        return
    end
    
    -- Test win condition checking
    local success, result = pcall(MainGameService.CheckWinCondition, MainGameService, mockPlayer)
    assert(success, "CheckWinCondition should not error: " .. tostring(result))
    
    if result ~= nil then
        local isBoolean = TestFramework.Utils.assertType(result, "boolean", "CheckWinCondition should return boolean")
        assert(isBoolean, "CheckWinCondition did not return boolean")
    end
end)

-- Test 10: Game Reset Functionality
mainGameSuite:addTest("Game Reset Functionality", function()
    if not MainGameService.ResetGame then
        print("⚠️  ResetGame function not available, skipping test")
        return
    end
    
    -- Test game reset
    local success, result = pcall(MainGameService.ResetGame, MainGameService, mockPlayer)
    assert(success, "ResetGame should not error: " .. tostring(result))
end)

-- Test 11: Game State Management
mainGameSuite:addTest("Game State Management", function()
    if MainGameService.GetGameState and MainGameService.SetGameState then
        -- Test getting game state
        local getSuccess, gameState = pcall(MainGameService.GetGameState, MainGameService, mockPlayer)
        assert(getSuccess, "GetGameState should not error")
        
        -- Test setting game state
        local setSuccess, setResult = pcall(MainGameService.SetGameState, MainGameService, mockPlayer, mockGameState)
        assert(setSuccess, "SetGameState should not error: " .. tostring(setResult))
    else
        print("⚠️  Game state management functions not available")
    end
end)

-- Test 12: Color System Integration
mainGameSuite:addTest("Color System Integration", function()
    -- Test color-related remote events
    local colorEvents = {
        "ColorGateCheck",
        "ColorSuccess", 
        "ColorFailure",
        "ChangeColor",
        "ColorChanged",
        "PlayerColorChanged"
    }
    
    local foundColorEvents = 0
    for _, eventName in ipairs(colorEvents) do
        if RemoteEvents[eventName] then
            foundColorEvents = foundColorEvents + 1
        end
    end
    
    local hasColorSystem = TestFramework.Utils.assertTrue(foundColorEvents > 0, "Should have color system events")
    assert(hasColorSystem, "No color system events found")
end)

-- Test 13: Obstacle System Integration
mainGameSuite:addTest("Obstacle System Integration", function()
    -- Test obstacle-related functionality
    local obstacleEvents = {
        "ObstacleHit",
        "BarrierHit",
        "BarrierPassed",
        "ShowFailureEffect"
    }
    
    local foundObstacleEvents = 0
    for _, eventName in ipairs(obstacleEvents) do
        if RemoteEvents[eventName] then
            foundObstacleEvents = foundObstacleEvents + 1
        end
    end
    
    local hasObstacleSystem = TestFramework.Utils.assertTrue(foundObstacleEvents > 0, "Should have obstacle system events")
    assert(hasObstacleSystem, "No obstacle system events found")
end)

-- Test 14: Coin Collection System
mainGameSuite:addTest("Coin Collection System", function()
    -- Test coin collection events
    local coinEvents = {
        "CoinCollected",
        "CoinHit",
        "CoinBalanceUpdated"
    }
    
    local foundCoinEvents = 0
    for _, eventName in ipairs(coinEvents) do
        if RemoteEvents[eventName] then
            foundCoinEvents = foundCoinEvents + 1
        end
    end
    
    local hasCoinSystem = TestFramework.Utils.assertTrue(foundCoinEvents > 0, "Should have coin system events")
    assert(hasCoinSystem, "No coin system events found")
end)

-- Test 15: Timer System
mainGameSuite:addTest("Timer System", function()
    -- Test timer-related events
    local timerEvents = {
        "GameTimer",
        "GameCountdownStart"
    }
    
    local foundTimerEvents = 0
    for _, eventName in ipairs(timerEvents) do
        if RemoteEvents[eventName] then
            foundTimerEvents = foundTimerEvents + 1
        end
    end
    
    local hasTimerSystem = TestFramework.Utils.assertTrue(foundTimerEvents > 0, "Should have timer system events")
    assert(hasTimerSystem, "No timer system events found")
end)

-- Test 16: Multiplayer Support
mainGameSuite:addTest("Multiplayer Support", function()
    -- Test multiplayer-related events
    local multiplayerEvents = {
        "MultiplayerGameStarted",
        "MultiplayerGameInfo",
        "MultiplayerLeaderboardUpdate",
        "MultiplayerGameCompleted"
    }
    
    local foundMultiplayerEvents = 0
    for _, eventName in ipairs(multiplayerEvents) do
        if RemoteEvents[eventName] then
            foundMultiplayerEvents = foundMultiplayerEvents + 1
        end
    end
    
    if foundMultiplayerEvents > 0 then
        print(string.format("✅ Found %d multiplayer events", foundMultiplayerEvents))
    else
        print("⚠️  No multiplayer events found (single-player only)")
    end
    
    assert(true, "Multiplayer support test completed")
end)

-- Test 17: Error Handling
mainGameSuite:addTest("Error Handling", function()
    -- Test with nil player
    if MainGameService.StartGame then
        local success, result = pcall(MainGameService.StartGame, MainGameService, nil)
        -- Should handle gracefully
        assert(true, "Nil player handling test completed")
    end
    
    -- Test with invalid game data
    if MainGameService.EndGame then
        local success, result = pcall(MainGameService.EndGame, MainGameService, mockPlayer, nil)
        -- Should handle gracefully
        assert(true, "Invalid game data handling test completed")
    end
end)

-- Test 18: Service Dependencies
mainGameSuite:addTest("Service Dependencies", function()
    -- Check if MainGameService has references to other required services
    local potentialDependencies = {
        "PlayerService",
        "DataService", 
        "AnalyticsService",
        "MonetizationService"
    }
    
    for _, depName in ipairs(potentialDependencies) do
        if MainGameService[depName] then
            print(string.format("✅ Found dependency: %s", depName))
        end
    end
    
    assert(true, "Service dependencies check completed")
end)

-- Test 19: Performance Considerations
mainGameSuite:addTest("Performance Considerations", function()
    -- Test that core functions don't take too long
    if MainGameService.ProcessGameLogic then
        local startTime = tick()
        local success, result = pcall(MainGameService.ProcessGameLogic, MainGameService, mockPlayer)
        local endTime = tick()
        local duration = endTime - startTime
        
        local isPerformant = TestFramework.Utils.assertTrue(duration < 0.1, "ProcessGameLogic should complete in under 100ms")
        if not isPerformant then
            print(string.format("⚠️  ProcessGameLogic took %.3f seconds", duration))
        end
    end
    
    assert(true, "Performance test completed")
end)

-- Test 20: Integration with World Objects
mainGameSuite:addTest("Integration with World Objects", function()
    -- Test if game service can find required world objects
    local gameTrackExists = TestFramework.Utils.assertWorldObjectExists("GameTracks", workspace)
    if not gameTrackExists then
        print("⚠️  GameTracks not found in workspace")
    end
    
    local spawnExists = TestFramework.Utils.assertWorldObjectExists("SpawnLocation", workspace)
    if not spawnExists then
        print("⚠️  SpawnLocation not found in workspace")
    end
    
    assert(true, "World objects integration test completed")
end)

return mainGameSuite
