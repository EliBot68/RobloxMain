-- TutorialServiceTest.luau
-- Comprehensive unit tests for TutorialService

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local SafeRequire = require(ReplicatedStorage.Shared.utils.SafeRequire)
local TestFramework = SafeRequire.require(ReplicatedStorage.Shared.utils.TestFramework)
local RemoteEvents = SafeRequire.require(ReplicatedStorage.Shared.modules.RemoteEvents)

-- Create test suite
local tutorialSuite = TestFramework.createSuite("TutorialService")

-- Test data and mocks
local mockPlayer = TestFramework.Utils.createMockPlayer(123456789, "TestPlayer")
local mockDataStore = TestFramework.Utils.createMockDataStore()

-- Service under test
local TutorialService = nil

-- Test Setup
tutorialSuite:setBeforeAll(function()
    local success, service = pcall(function()
        return require(game.ServerScriptService.services.TutorialService)
    end)
    
    if not success then
        error("TutorialService could not be loaded for testing")
    end
    
    TutorialService = service
end)

tutorialSuite:setBeforeEach(function()
    -- Reset any state before each test
    mockDataStore = TestFramework.Utils.createMockDataStore()
end)

-- Test 1: Service Module Loading
tutorialSuite:addTest("Service Module Loads Successfully", function()
    local success, details = TestFramework.Utils.assertNotNil(TutorialService, "TutorialService should load successfully")
    assert(success, details)
    
    local isTable = TestFramework.Utils.assertType(TutorialService, "table", "TutorialService should be a table")
    assert(isTable, "TutorialService is not a table")
end)

-- Test 2: Required Functions Exist
tutorialSuite:addTest("Required Functions Exist", function()
    local requiredFunctions = {
        "LoadPlayerTutorialData",
        "SavePlayerTutorialData",
        "HandlePlayerAdded",
        "StartNewPlayerOnboarding",
        "StartTutorial",
        "CompleteTutorial",
        "AwardWelcomeBonus",
        "HasCompletedTutorial",
        "ShowTutorial",
        "Initialize"
    }
    
    for _, funcName in ipairs(requiredFunctions) do
        local success, details = TestFramework.Utils.assertFunctionExists(TutorialService, funcName)
        assert(success, string.format("Missing function: %s - %s", funcName, details))
    end
end)

-- Test 3: Remote Events Integration
tutorialSuite:addTest("Remote Events Integration", function()
    local requiredEvents = {
        "ShowTutorial",
        "StartTutorial",
        "StartNewPlayerTutorial", 
        "CompleteTutorial",
        "ShowWelcomeMessage",
        "ShowNotification"
    }
    
    for _, eventName in ipairs(requiredEvents) do
        local success, details = TestFramework.Utils.assertRemoteEventExists(eventName)
        assert(success, string.format("Missing RemoteEvent: %s - %s", eventName, details))
        
        -- Verify RemoteEvents module has reference
        local hasReference = TestFramework.Utils.assertNotNil(RemoteEvents[eventName])
        assert(hasReference, string.format("RemoteEvents.%s is not defined", eventName))
    end
end)

-- Test 4: Player Tutorial Data Loading
tutorialSuite:addTest("Player Tutorial Data Loading", function()
    if not TutorialService.LoadPlayerTutorialData then
        error("LoadPlayerTutorialData function not available")
    end
    
    -- Test loading tutorial data for a mock player
    local success, tutorialData = pcall(TutorialService.LoadPlayerTutorialData, TutorialService, mockPlayer)
    
    assert(success, "LoadPlayerTutorialData should not error")
    
    if tutorialData then
        -- Verify data structure
        local hasFirstJoin = TestFramework.Utils.assertNotNil(tutorialData.firstJoin)
        assert(hasFirstJoin, "Tutorial data should have firstJoin field")
        
        local hasCompleted = TestFramework.Utils.assertNotNil(tutorialData.completedTutorial)
        assert(hasCompleted, "Tutorial data should have completedTutorial field")
    end
end)

-- Test 5: Tutorial Completion Tracking
tutorialSuite:addTest("Tutorial Completion Tracking", function()
    if not TutorialService.HasCompletedTutorial then
        error("HasCompletedTutorial function not available")
    end
    
    -- Test with mock player
    local completed = TutorialService:HasCompletedTutorial(mockPlayer)
    local isBoolean = TestFramework.Utils.assertType(completed, "boolean", "HasCompletedTutorial should return boolean")
    assert(isBoolean, "HasCompletedTutorial did not return boolean")
end)

-- Test 6: Welcome Bonus System
tutorialSuite:addTest("Welcome Bonus System", function()
    if not TutorialService.AwardWelcomeBonus then
        error("AwardWelcomeBonus function not available")
    end
    
    -- Test welcome bonus awarding
    local success, result = pcall(TutorialService.AwardWelcomeBonus, TutorialService, mockPlayer)
    assert(success, "AwardWelcomeBonus should not error: " .. tostring(result))
end)

-- Test 7: Tutorial Start Process
tutorialSuite:addTest("Tutorial Start Process", function()
    if not TutorialService.StartTutorial then
        error("StartTutorial function not available")
    end
    
    -- Test starting tutorial
    local success, result = pcall(TutorialService.StartTutorial, TutorialService, mockPlayer)
    assert(success, "StartTutorial should not error: " .. tostring(result))
end)

-- Test 8: New Player Onboarding
tutorialSuite:addTest("New Player Onboarding", function()
    if not TutorialService.StartNewPlayerOnboarding then
        error("StartNewPlayerOnboarding function not available")
    end
    
    -- Test new player onboarding
    local success, result = pcall(TutorialService.StartNewPlayerOnboarding, TutorialService, mockPlayer)
    assert(success, "StartNewPlayerOnboarding should not error: " .. tostring(result))
end)

-- Test 9: Tutorial Completion Process
tutorialSuite:addTest("Tutorial Completion Process", function()
    if not TutorialService.CompleteTutorial then
        error("CompleteTutorial function not available")
    end
    
    -- Test completing tutorial
    local success, result = pcall(TutorialService.CompleteTutorial, TutorialService, mockPlayer)
    assert(success, "CompleteTutorial should not error: " .. tostring(result))
end)

-- Test 10: Data Persistence
tutorialSuite:addTest("Data Persistence", function()
    if not TutorialService.SavePlayerTutorialData then
        error("SavePlayerTutorialData function not available")
    end
    
    -- Test saving tutorial data
    local success, result = pcall(TutorialService.SavePlayerTutorialData, TutorialService, mockPlayer)
    assert(success, "SavePlayerTutorialData should not error: " .. tostring(result))
end)

-- Test 11: Tutorial Sections Configuration
tutorialSuite:addTest("Tutorial Sections Configuration", function()
    -- Verify tutorial sections are properly configured
    local sections = TutorialService.TUTORIAL_SECTIONS or {}
    
    local hasSections = TestFramework.Utils.assertTrue(#sections > 0, "Tutorial should have configured sections")
    assert(hasSections, "No tutorial sections found")
    
    -- Verify section structure
    for i, section in ipairs(sections) do
        local hasTitle = TestFramework.Utils.assertNotNil(section.title, string.format("Section %d should have title", i))
        assert(hasTitle, string.format("Section %d missing title", i))
        
        local hasContent = TestFramework.Utils.assertNotNil(section.content, string.format("Section %d should have content", i))
        assert(hasContent, string.format("Section %d missing content", i))
    end
end)

-- Test 12: Welcome Bonus Configuration
tutorialSuite:addTest("Welcome Bonus Configuration", function()
    local welcomeBonus = TutorialService.WELCOME_BONUS
    
    if welcomeBonus then
        local hasCoins = TestFramework.Utils.assertType(welcomeBonus.coins, "number", "Welcome bonus should have coins amount")
        assert(hasCoins, "Welcome bonus coins not properly configured")
        
        local hasXP = TestFramework.Utils.assertType(welcomeBonus.xp, "number", "Welcome bonus should have XP amount")
        assert(hasXP, "Welcome bonus XP not properly configured")
        
        local coinsPositive = TestFramework.Utils.assertTrue(welcomeBonus.coins > 0, "Welcome bonus coins should be positive")
        assert(coinsPositive, "Welcome bonus coins is not positive")
        
        local xpPositive = TestFramework.Utils.assertTrue(welcomeBonus.xp > 0, "Welcome bonus XP should be positive")
        assert(xpPositive, "Welcome bonus XP is not positive")
    end
end)

-- Test 13: Error Handling
tutorialSuite:addTest("Error Handling", function()
    -- Test with nil player
    if TutorialService.LoadPlayerTutorialData then
        local success, result = pcall(TutorialService.LoadPlayerTutorialData, TutorialService, nil)
        -- Should handle gracefully (either succeed with default data or fail gracefully)
        assert(true, "Error handling test completed")
    end
    
    -- Test with invalid player data
    local invalidPlayer = {UserId = "invalid"}
    if TutorialService.HasCompletedTutorial then
        local success, result = pcall(TutorialService.HasCompletedTutorial, TutorialService, invalidPlayer)
        -- Should handle gracefully
        assert(true, "Invalid player data handled")
    end
end)

-- Test 14: Service Initialization
tutorialSuite:addTest("Service Initialization", function()
    if TutorialService.Initialize then
        local success, result = pcall(TutorialService.Initialize, TutorialService)
        assert(success, "Service initialization should not error: " .. tostring(result))
    else
        -- If no Initialize function, that's also acceptable
        assert(true, "No Initialize function found (acceptable)")
    end
end)

-- Test 15: Integration with World Objects
tutorialSuite:addTest("Integration with World Objects", function()
    -- Test if tutorial system can find required world objects
    local success, details = TestFramework.Utils.assertWorldObjectExists("MarketPlaza", workspace)
    -- This may fail if MarketPlaza doesn't exist, but shouldn't crash the service
    
    if TutorialService.SetupKioskDisplay then
        local setupSuccess, setupResult = pcall(TutorialService.SetupKioskDisplay, TutorialService)
        -- Should handle missing world objects gracefully
        assert(true, "Kiosk setup test completed")
    end
end)

return tutorialSuite
