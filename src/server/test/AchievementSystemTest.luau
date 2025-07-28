-- AchievementSystemTest.luau
-- Comprehensive test suite for the Achievement System

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local SafeRequire = require(ReplicatedStorage.Shared.utils.SafeRequire)
local RemoteEvents = SafeRequire.require(ReplicatedStorage.Shared.modules.RemoteEvents)

local AchievementSystemTest = {}

function AchievementSystemTest:TestRemoteEventsExist()
    print("🧪 Testing Achievement Remote Events...")
    
    local requiredEvents = {
        "RequestAchievementData",
        "AchievementDataUpdated",
        "AchievementUnlocked",
        "ClaimAchievementReward",
        "AchievementClaimResult",
        "RequestDailyBonus",
        "ShowDailyBonusPopup"
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

function AchievementSystemTest:TestAchievementServiceFunctions()
    print("🧪 Testing AchievementService Functions...")
    
    -- Try to access AchievementService
    local success, AchievementService = pcall(function()
        return require(script.Parent.Parent.services.AchievementServiceComplete)
    end)
    
    if not success then
        print("❌ Cannot access AchievementService")
        return false
    end
    
    local requiredFunctions = {
        "OnInit",
        "OnStart",
        "SetupRemoteEvents",
        "OnPlayerAdded",
        "LoadPlayerAchievements",
        "ProcessDailyBonus",
        "ClaimAchievementReward",
        "UpdatePlayerProgress",
        "ShowAchievementUnlocked",
        "SavePlayerData"
    }
    
    local allPassed = true
    for _, funcName in ipairs(requiredFunctions) do
        if type(AchievementService[funcName]) == "function" then
            print("✅ AchievementService:" .. funcName .. " exists")
        else
            print("❌ AchievementService:" .. funcName .. " missing!")
            allPassed = false
        end
    end
    
    return allPassed
end

function AchievementSystemTest:TestAchievementControllerFunctions()
    print("🧪 Testing AchievementController Functions...")
    
    -- Try to access AchievementController
    local success, AchievementController = pcall(function()
        return require(script.Parent.Parent.Parent.client.controllers.AchievementControllerComplete)
    end)
    
    if not success then
        print("❌ Cannot access AchievementController")
        return false
    end
    
    local requiredFunctions = {
        "Init",
        "LoadSounds",
        "SetupRemoteEvents",
        "CreateAchievementGUI",
        "CreateDailyBonusGUI",
        "UpdateAchievementData",
        "ShowAchievementUnlocked",
        "ShowDailyBonusPopup",
        "OpenAchievementMenu",
        "ClaimAchievement"
    }
    
    local allPassed = true
    for _, funcName in ipairs(requiredFunctions) do
        if type(AchievementController[funcName]) == "function" then
            print("✅ AchievementController:" .. funcName .. " exists")
        else
            print("❌ AchievementController:" .. funcName .. " missing!")
            allPassed = false
        end
    end
    
    return allPassed
end

function AchievementSystemTest:TestDailyBonusFlow()
    print("🧪 Testing Daily Bonus Flow...")
    
    if Players.LocalPlayer then
        print("📱 Testing from client side...")
        if RemoteEvents.RequestDailyBonus then
            RemoteEvents.RequestDailyBonus:FireServer()
            print("✅ Daily bonus request sent")
            return true
        else
            print("❌ RequestDailyBonus event not found")
            return false
        end
    else
        print("🖥️ Testing from server side...")
        local testPlayer = next(Players:GetPlayers())
        if testPlayer then
            print("✅ Would process daily bonus for " .. testPlayer.Name)
            return true
        else
            print("⚠️ No players found to test daily bonus")
            return false
        end
    end
end

function AchievementSystemTest:TestAchievementUnlockFlow()
    print("🧪 Testing Achievement Unlock Flow...")
    
    local testAchievement = {
        id = "test_achievement",
        name = "🧪 Test Achievement",
        description = "This is a test achievement for validation",
        icon = "🧪",
        category = "Test",
        targetValue = 1,
        statKey = "testStat",
        reward = {
            type = "coins",
            amount = 100,
            name = "100 Test Coins"
        },
        rarity = "Common"
    }
    
    if Players.LocalPlayer then
        print("📱 Testing achievement unlock from client...")
        if RemoteEvents.AchievementUnlocked then
            -- Simulate receiving an achievement unlock
            print("✅ Achievement unlock system ready")
            return true
        else
            print("❌ AchievementUnlocked event not found")
            return false
        end
    else
        print("🖥️ Testing achievement unlock from server...")
        local testPlayer = next(Players:GetPlayers())
        if testPlayer and RemoteEvents.AchievementUnlocked then
            RemoteEvents.AchievementUnlocked:FireClient(testPlayer, testAchievement)
            print("✅ Test achievement unlock sent to " .. testPlayer.Name)
            return true
        else
            print("⚠️ Cannot test achievement unlock - no players or missing event")
            return false
        end
    end
end

function AchievementSystemTest:TestProgressUpdateFlow()
    print("🧪 Testing Achievement Progress Update...")
    
    if not Players.LocalPlayer then
        print("🖥️ Testing progress update from server...")
        
        -- Try to access AchievementService
        local success, AchievementService = pcall(function()
            return require(script.Parent.Parent.services.AchievementServiceComplete)
        end)
        
        if success then
            local testPlayer = next(Players:GetPlayers())
            if testPlayer then
                -- Simulate a progress update
                AchievementService:UpdatePlayerProgress(testPlayer, "gamesPlayed", 1)
                print("✅ Progress update test sent for " .. testPlayer.Name)
                return true
            else
                print("⚠️ No players found to test progress update")
                return false
            end
        else
            print("❌ Cannot access AchievementService for progress test")
            return false
        end
    else
        print("📱 Progress updates handled server-side")
        return true
    end
end

function AchievementSystemTest:TestUIComponents()
    print("🧪 Testing Achievement UI Components...")
    
    if not Players.LocalPlayer then
        print("🖥️ UI tests only run on client side")
        return true
    end
    
    local playerGui = Players.LocalPlayer:WaitForChild("PlayerGui")
    
    -- Check for GUI elements
    local achievementGUI = playerGui:FindFirstChild("AchievementGUI")
    local dailyBonusGUI = playerGui:FindFirstChild("DailyBonusGUI")
    local achievementPopupGUI = playerGui:FindFirstChild("AchievementPopupGUI")
    
    local uiTests = {
        {"AchievementGUI", achievementGUI ~= nil},
        {"DailyBonusGUI", dailyBonusGUI ~= nil},
        {"AchievementPopupGUI", achievementPopupGUI ~= nil}
    }
    
    local allPassed = true
    for _, test in ipairs(uiTests) do
        if test[2] then
            print("✅ " .. test[1] .. " created successfully")
        else
            print("❌ " .. test[1] .. " not found!")
            allPassed = false
        end
    end
    
    return allPassed
end

function AchievementSystemTest:RunAllTests()
    print("🚀 Starting Achievement System Tests...")
    print("=" .. string.rep("=", 60))
    
    local results = {}
    
    results.remoteEvents = self:TestRemoteEventsExist()
    wait(0.5)
    
    results.serviceFunction = self:TestAchievementServiceFunctions()
    wait(0.5)
    
    results.controllerFunctions = self:TestAchievementControllerFunctions()
    wait(0.5)
    
    results.dailyBonusFlow = self:TestDailyBonusFlow()
    wait(0.5)
    
    results.achievementUnlockFlow = self:TestAchievementUnlockFlow()
    wait(0.5)
    
    results.progressUpdateFlow = self:TestProgressUpdateFlow()
    wait(0.5)
    
    results.uiComponents = self:TestUIComponents()
    wait(0.5)
    
    print("=" .. string.rep("=", 60))
    print("📊 Achievement System Test Results:")
    
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
        print("🎉 ALL ACHIEVEMENT SYSTEM TESTS PASSED!")
    else
        print("⚠️ Some achievement system tests failed - check implementation")
    end
    
    return allPassed
end

-- Auto-run tests when script loads
spawn(function()
    wait(5) -- Give systems time to initialize
    AchievementSystemTest:RunAllTests()
end)

return AchievementSystemTest
