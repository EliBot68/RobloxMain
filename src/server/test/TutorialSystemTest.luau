-- TutorialSystemTest.luau
-- Quick test script to validate the tutorial system implementation

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local SafeRequire = require(ReplicatedStorage.Shared.utils.SafeRequire)
local RemoteEvents = SafeRequire.require(ReplicatedStorage.Shared.modules.RemoteEvents)
local TutorialService = SafeRequire.require(script.Parent.Parent.services.TutorialService)

local TutorialSystemTest = {}

function TutorialSystemTest:TestRemoteEventsExist()
    print("🧪 Testing Tutorial Remote Events...")
    
    local requiredEvents = {
        "ShowTutorial",
        "StartTutorial", 
        "StartNewPlayerTutorial",
        "CompleteTutorial",
        "ShowWelcomeMessage",
        "ShowNotification"
    }
    
    local allPassed = true
    for _, eventName in ipairs(requiredEvents) do
        if RemoteEvents[eventName] then
            print("✅ " .. eventName .. " exists")
        else
            print("❌ " .. eventName .. " missing!")
            allPassed = false
        end
    end
    
    return allPassed
end

function TutorialSystemTest:TestTutorialServiceFunctions()
    print("🧪 Testing TutorialService Functions...")
    
    local requiredFunctions = {
        "LoadPlayerTutorialData",
        "SavePlayerTutorialData", 
        "HandlePlayerAdded",
        "StartNewPlayerOnboarding",
        "StartTutorial",
        "CompleteTutorial",
        "AwardWelcomeBonus",
        "HasCompletedTutorial",
        "ShowTutorial"
    }
    
    local allPassed = true
    for _, funcName in ipairs(requiredFunctions) do
        if type(TutorialService[funcName]) == "function" then
            print("✅ TutorialService:" .. funcName .. " exists")
        else
            print("❌ TutorialService:" .. funcName .. " missing!")
            allPassed = false
        end
    end
    
    return allPassed
end

function TutorialSystemTest:TestWelcomeMessage()
    print("🧪 Testing Welcome Message System...")
    
    -- Test with a mock player (for server testing)
    if Players.LocalPlayer then
        print("📱 Testing from client side...")
        RemoteEvents.ShowWelcomeMessage:FireServer({
            title = "🧪 Test Welcome",
            message = "This is a test welcome message from the tutorial system test!",
            duration = 3
        })
        print("✅ Welcome message test sent")
        return true
    else
        print("🖥️ Testing from server side...")
        -- Find a player to test with
        local testPlayer = next(Players:GetPlayers())
        if testPlayer then
            RemoteEvents.ShowWelcomeMessage:FireClient(testPlayer, {
                title = "🧪 Test Welcome", 
                message = "This is a test welcome message from the tutorial system test!",
                duration = 3
            })
            print("✅ Welcome message test sent to " .. testPlayer.Name)
            return true
        else
            print("⚠️ No players found to test welcome message")
            return false
        end
    end
end

function TutorialSystemTest:TestTutorialStart()
    print("🧪 Testing Tutorial Start...")
    
    if Players.LocalPlayer then
        print("📱 Testing tutorial start from client...")
        RemoteEvents.StartTutorial:FireServer()
        print("✅ Tutorial start signal sent")
        return true
    else
        print("🖥️ Testing tutorial start from server...")
        local testPlayer = next(Players:GetPlayers())
        if testPlayer then
            TutorialService:StartTutorial(testPlayer)
            print("✅ Tutorial started for " .. testPlayer.Name)
            return true
        else
            print("⚠️ No players found to test tutorial start")
            return false
        end
    end
end

function TutorialSystemTest:RunAllTests()
    print("🚀 Starting Tutorial System Tests...")
    print("=" .. string.rep("=", 50))
    
    local results = {}
    
    results.remoteEvents = self:TestRemoteEventsExist()
    wait(0.5)
    
    results.serviceFunctions = self:TestTutorialServiceFunctions() 
    wait(0.5)
    
    results.welcomeMessage = self:TestWelcomeMessage()
    wait(1)
    
    results.tutorialStart = self:TestTutorialStart()
    wait(0.5)
    
    print("=" .. string.rep("=", 50))
    print("📊 Tutorial System Test Results:")
    
    local allPassed = true
    for testName, passed in pairs(results) do
        if passed then
            print("✅ " .. testName .. ": PASSED")
        else
            print("❌ " .. testName .. ": FAILED")
            allPassed = false
        end
    end
    
    if allPassed then
        print("🎉 ALL TUTORIAL SYSTEM TESTS PASSED!")
    else
        print("⚠️ Some tutorial system tests failed - check implementation")
    end
    
    return allPassed
end

-- Auto-run tests when script loads
spawn(function()
    wait(3) -- Give systems time to initialize
    TutorialSystemTest:RunAllTests()
end)

return TutorialSystemTest
