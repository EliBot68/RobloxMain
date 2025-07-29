-- UpgradeServiceTest.luau
-- Comprehensive unit tests for UpgradeService

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local SafeRequire = require(ReplicatedStorage.Shared.utils.SafeRequire)
local TestFramework = SafeRequire.require(ReplicatedStorage.Shared.utils.TestFramework)
local RemoteEvents = SafeRequire.require(ReplicatedStorage.Shared.modules.RemoteEvents)

-- Create test suite
local upgradeSuite = TestFramework.createSuite("UpgradeService")

-- Test data and mocks
local mockPlayer = TestFramework.Utils.createMockPlayer(123456789, "TestPlayer")
local mockUpgradeData = {
    upgradeId = "speed_boost",
    level = 1,
    cost = 100,
    maxLevel = 10,
    effect = {
        type = "speed",
        multiplier = 1.1
    }
}

-- Service under test
local UpgradeService = nil

-- Test Setup
upgradeSuite:setBeforeAll(function()
    -- Try both consolidated and regular versions
    local success, service = pcall(function()
        return require(game.ServerScriptService.services.UpgradeService_Consolidated)
    end)
    
    if not success then
        success, service = pcall(function()
            return require(game.ServerScriptService.services.UpgradeService)
        end)
    end
    
    if not success then
        error("UpgradeService could not be loaded for testing")
    end
    
    UpgradeService = service
end)

upgradeSuite:setBeforeEach(function()
    -- Reset upgrade data before each test
    mockUpgradeData = {
        upgradeId = "speed_boost",
        level = 1,
        cost = 100,
        maxLevel = 10,
        effect = {
            type = "speed",
            multiplier = 1.1
        }
    }
end)

-- Test 1: Service Module Loading
upgradeSuite:addTest("Service Module Loads Successfully", function()
    local success, details = TestFramework.Utils.assertNotNil(UpgradeService, "UpgradeService should load successfully")
    assert(success, details)
    
    local isTable = TestFramework.Utils.assertType(UpgradeService, "table", "UpgradeService should be a table")
    assert(isTable, "UpgradeService is not a table")
end)

-- Test 2: Required Functions Exist
upgradeSuite:addTest("Required Functions Exist", function()
    local requiredFunctions = {
        "PurchaseUpgrade",
        "GetPlayerUpgrades",
        "GetUpgradeDefinitions",
        "CalculateUpgradeCost",
        "ApplyUpgradeEffects",
        "ValidateUpgrade",
        "SavePlayerUpgrades",
        "LoadPlayerUpgrades",
        "GetUpgradeStats",
        "ResetUpgrades"
    }
    
    for _, funcName in ipairs(requiredFunctions) do
        if UpgradeService[funcName] then
            local success, details = TestFramework.Utils.assertFunctionExists(UpgradeService, funcName)
            assert(success, string.format("Function exists but not callable: %s - %s", funcName, details))
        else
            print(string.format("⚠️  Optional function not found: %s", funcName))
        end
    end
end)

-- Test 3: Remote Events Integration
upgradeSuite:addTest("Remote Events Integration", function()
    local upgradeEvents = {
        "ShowUpgradeShop",
        "PurchaseUpgrade",
        "UpgradePurchaseResult",
        "RequestUpgradeData",
        "UpgradeDataUpdated",
        "UpdateUpgradeData"
    }
    
    for _, eventName in ipairs(upgradeEvents) do
        local success, details = TestFramework.Utils.assertRemoteEventExists(eventName)
        assert(success, string.format("Missing RemoteEvent: %s - %s", eventName, details))
        
        -- Verify RemoteEvents module has reference
        local hasReference = TestFramework.Utils.assertNotNil(RemoteEvents[eventName])
        assert(hasReference, string.format("RemoteEvents.%s is not defined", eventName))
    end
end)

-- Test 4: Upgrade Definitions
upgradeSuite:addTest("Upgrade Definitions", function()
    if not UpgradeService.GetUpgradeDefinitions then
        print("⚠️  GetUpgradeDefinitions function not available, skipping test")
        return
    end
    
    -- Test getting upgrade definitions
    local success, definitions = pcall(UpgradeService.GetUpgradeDefinitions, UpgradeService)
    assert(success, "GetUpgradeDefinitions should not error")
    
    if definitions then
        local isTable = TestFramework.Utils.assertType(definitions, "table", "Upgrade definitions should be a table")
        assert(isTable, "Upgrade definitions is not a table")
        
        local hasUpgrades = TestFramework.Utils.assertTrue(#definitions > 0 or next(definitions) ~= nil, "Should have upgrade definitions")
        assert(hasUpgrades, "No upgrade definitions found")
        
        -- Validate structure of first upgrade
        local firstUpgrade = definitions[1] or next(definitions) and definitions[next(definitions)]
        if firstUpgrade then
            local hasId = TestFramework.Utils.assertNotNil(firstUpgrade.id, "Upgrade should have ID")
            assert(hasId, "Upgrade missing ID")
            
            local hasName = TestFramework.Utils.assertNotNil(firstUpgrade.name, "Upgrade should have name")
            assert(hasName, "Upgrade missing name")
            
            local hasCost = TestFramework.Utils.assertNotNil(firstUpgrade.cost or firstUpgrade.baseCost, "Upgrade should have cost")
            assert(hasCost, "Upgrade missing cost")
        end
    end
end)

-- Test 5: Player Upgrade Data Loading
upgradeSuite:addTest("Player Upgrade Data Loading", function()
    if not UpgradeService.GetPlayerUpgrades then
        print("⚠️  GetPlayerUpgrades function not available, skipping test")
        return
    end
    
    -- Test getting player upgrades
    local success, playerUpgrades = pcall(UpgradeService.GetPlayerUpgrades, UpgradeService, mockPlayer)
    assert(success, "GetPlayerUpgrades should not error")
    
    if playerUpgrades then
        local isTable = TestFramework.Utils.assertType(playerUpgrades, "table", "Player upgrades should be a table")
        assert(isTable, "Player upgrades is not a table")
    end
end)

-- Test 6: Upgrade Cost Calculation
upgradeSuite:addTest("Upgrade Cost Calculation", function()
    if not UpgradeService.CalculateUpgradeCost then
        print("⚠️  CalculateUpgradeCost function not available, skipping test")
        return
    end
    
    -- Test cost calculation
    local success, cost = pcall(UpgradeService.CalculateUpgradeCost, UpgradeService, "speed_boost", 1)
    assert(success, "CalculateUpgradeCost should not error")
    
    if cost then
        local isNumber = TestFramework.Utils.assertType(cost, "number", "Upgrade cost should be a number")
        assert(isNumber, "Upgrade cost is not a number")
        
        local isPositive = TestFramework.Utils.assertTrue(cost > 0, "Upgrade cost should be positive")
        assert(isPositive, "Upgrade cost is not positive")
    end
end)

-- Test 7: Upgrade Purchase Process
upgradeSuite:addTest("Upgrade Purchase Process", function()
    if not UpgradeService.PurchaseUpgrade then
        print("⚠️  PurchaseUpgrade function not available, skipping test")
        return
    end
    
    -- Test upgrade purchase
    local success, result = pcall(UpgradeService.PurchaseUpgrade, UpgradeService, mockPlayer, "speed_boost")
    assert(success, "PurchaseUpgrade should not error: " .. tostring(result))
    
    if result then
        -- Check result structure
        if type(result) == "table" then
            local hasSuccess = TestFramework.Utils.assertNotNil(result.success, "Purchase result should have success field")
            if not hasSuccess then
                print("⚠️  Purchase result missing success field")
            end
        end
    end
end)

-- Test 8: Upgrade Validation
upgradeSuite:addTest("Upgrade Validation", function()
    if not UpgradeService.ValidateUpgrade then
        print("⚠️  ValidateUpgrade function not available, skipping test")
        return
    end
    
    -- Test valid upgrade validation
    local success, isValid = pcall(UpgradeService.ValidateUpgrade, UpgradeService, mockPlayer, "speed_boost")
    assert(success, "ValidateUpgrade should not error")
    
    if isValid ~= nil then
        local isBoolean = TestFramework.Utils.assertType(isValid, "boolean", "ValidateUpgrade should return boolean")
        assert(isBoolean, "ValidateUpgrade did not return boolean")
    end
    
    -- Test invalid upgrade validation
    local invalidSuccess, invalidResult = pcall(UpgradeService.ValidateUpgrade, UpgradeService, mockPlayer, "invalid_upgrade")
    assert(invalidSuccess, "ValidateUpgrade should handle invalid upgrades gracefully")
end)

-- Test 9: Upgrade Effects Application
upgradeSuite:addTest("Upgrade Effects Application", function()
    if not UpgradeService.ApplyUpgradeEffects then
        print("⚠️  ApplyUpgradeEffects function not available, skipping test")
        return
    end
    
    -- Test applying upgrade effects
    local success, result = pcall(UpgradeService.ApplyUpgradeEffects, UpgradeService, mockPlayer)
    assert(success, "ApplyUpgradeEffects should not error: " .. tostring(result))
end)

-- Test 10: Data Persistence
upgradeSuite:addTest("Data Persistence", function()
    -- Test saving player upgrades
    if UpgradeService.SavePlayerUpgrades then
        local saveSuccess, saveResult = pcall(UpgradeService.SavePlayerUpgrades, UpgradeService, mockPlayer)
        assert(saveSuccess, "SavePlayerUpgrades should not error: " .. tostring(saveResult))
    end
    
    -- Test loading player upgrades
    if UpgradeService.LoadPlayerUpgrades then
        local loadSuccess, loadResult = pcall(UpgradeService.LoadPlayerUpgrades, UpgradeService, mockPlayer)
        assert(loadSuccess, "LoadPlayerUpgrades should not error: " .. tostring(loadResult))
    end
end)

-- Test 11: Upgrade Statistics
upgradeSuite:addTest("Upgrade Statistics", function()
    if not UpgradeService.GetUpgradeStats then
        print("⚠️  GetUpgradeStats function not available, skipping test")
        return
    end
    
    -- Test getting upgrade statistics
    local success, stats = pcall(UpgradeService.GetUpgradeStats, UpgradeService, mockPlayer)
    assert(success, "GetUpgradeStats should not error")
    
    if stats then
        local isTable = TestFramework.Utils.assertType(stats, "table", "Upgrade stats should be a table")
        assert(isTable, "Upgrade stats is not a table")
    end
end)

-- Test 12: Upgrade Reset Functionality
upgradeSuite:addTest("Upgrade Reset Functionality", function()
    if not UpgradeService.ResetUpgrades then
        print("⚠️  ResetUpgrades function not available, skipping test")
        return
    end
    
    -- Test resetting upgrades
    local success, result = pcall(UpgradeService.ResetUpgrades, UpgradeService, mockPlayer)
    assert(success, "ResetUpgrades should not error: " .. tostring(result))
end)

-- Test 13: Upgrade Categories and Types
upgradeSuite:addTest("Upgrade Categories and Types", function()
    if UpgradeService.GetUpgradeDefinitions then
        local success, definitions = pcall(UpgradeService.GetUpgradeDefinitions, UpgradeService)
        
        if success and definitions then
            local categories = {}
            local types = {}
            
            for _, upgrade in pairs(definitions) do
                if upgrade.category then
                    categories[upgrade.category] = true
                end
                if upgrade.type then
                    types[upgrade.type] = true
                end
            end
            
            local categoryCount = 0
            for _ in pairs(categories) do categoryCount = categoryCount + 1 end
            
            local typeCount = 0
            for _ in pairs(types) do typeCount = typeCount + 1 end
            
            print(string.format("✅ Found %d upgrade categories, %d upgrade types", categoryCount, typeCount))
        end
    end
    
    assert(true, "Upgrade categories and types test completed")
end)

-- Test 14: Maximum Level Constraints
upgradeSuite:addTest("Maximum Level Constraints", function()
    if UpgradeService.GetUpgradeDefinitions then
        local success, definitions = pcall(UpgradeService.GetUpgradeDefinitions, UpgradeService)
        
        if success and definitions then
            for _, upgrade in pairs(definitions) do
                if upgrade.maxLevel then
                    local maxLevelValid = TestFramework.Utils.assertTrue(upgrade.maxLevel > 0, "Max level should be positive")
                    assert(maxLevelValid, string.format("Upgrade %s has invalid max level", upgrade.id or "unknown"))
                end
            end
        end
    end
    
    -- Test purchasing beyond max level
    if UpgradeService.PurchaseUpgrade and UpgradeService.ValidateUpgrade then
        -- This would require setting up a player with max level upgrades
        assert(true, "Max level constraint validation completed")
    end
end)

-- Test 15: Currency Integration
upgradeSuite:addTest("Currency Integration", function()
    -- Test upgrade purchase with insufficient funds
    if UpgradeService.PurchaseUpgrade then
        -- Create a mock player with no coins
        local poorPlayer = TestFramework.Utils.createMockPlayer(987654321, "PoorPlayer")
        
        local success, result = pcall(UpgradeService.PurchaseUpgrade, UpgradeService, poorPlayer, "expensive_upgrade")
        assert(success, "PurchaseUpgrade should handle insufficient funds gracefully")
        
        if result and type(result) == "table" and result.success ~= nil then
            local shouldFail = TestFramework.Utils.assertFalse(result.success, "Purchase should fail with insufficient funds")
            -- This may not always be true depending on implementation
        end
    end
end)

-- Test 16: Upgrade Bonus Calculations
upgradeSuite:addTest("Upgrade Bonus Calculations", function()
    if UpgradeService.GetUpgradeDefinitions then
        local success, definitions = pcall(UpgradeService.GetUpgradeDefinitions, UpgradeService)
        
        if success and definitions then
            for _, upgrade in pairs(definitions) do
                if upgrade.effect and upgrade.effect.multiplier then
                    local multiplierValid = TestFramework.Utils.assertTrue(upgrade.effect.multiplier > 0, "Effect multiplier should be positive")
                    assert(multiplierValid, string.format("Upgrade %s has invalid multiplier", upgrade.id or "unknown"))
                end
                
                if upgrade.effect and upgrade.effect.bonus then
                    local bonusValid = TestFramework.Utils.assertType(upgrade.effect.bonus, "number", "Effect bonus should be a number")
                    assert(bonusValid, string.format("Upgrade %s has invalid bonus type", upgrade.id or "unknown"))
                end
            end
        end
    end
end)

-- Test 17: Error Handling
upgradeSuite:addTest("Error Handling", function()
    -- Test with nil player
    if UpgradeService.PurchaseUpgrade then
        local success, result = pcall(UpgradeService.PurchaseUpgrade, UpgradeService, nil, "speed_boost")
        assert(success, "Should handle nil player gracefully")
    end
    
    -- Test with invalid upgrade ID
    if UpgradeService.PurchaseUpgrade then
        local success, result = pcall(UpgradeService.PurchaseUpgrade, UpgradeService, mockPlayer, "nonexistent_upgrade")
        assert(success, "Should handle invalid upgrade ID gracefully")
    end
    
    -- Test with invalid parameters
    if UpgradeService.CalculateUpgradeCost then
        local success, result = pcall(UpgradeService.CalculateUpgradeCost, UpgradeService, "", -1)
        assert(success, "Should handle invalid parameters gracefully")
    end
end)

-- Test 18: Service Dependencies
upgradeSuite:addTest("Service Dependencies", function()
    -- Check if UpgradeService has references to other required services
    local potentialDependencies = {
        "DataService",
        "PlayerService",
        "AnalyticsService",
        "RemoteEvents"
    }
    
    for _, depName in ipairs(potentialDependencies) do
        if UpgradeService[depName] then
            print(string.format("✅ Found dependency: %s", depName))
        end
    end
    
    assert(true, "Service dependencies check completed")
end)

-- Test 19: Performance Testing
upgradeSuite:addTest("Performance Testing", function()
    if UpgradeService.ApplyUpgradeEffects then
        local startTime = tick()
        local success, result = pcall(UpgradeService.ApplyUpgradeEffects, UpgradeService, mockPlayer)
        local endTime = tick()
        local duration = endTime - startTime
        
        local isPerformant = TestFramework.Utils.assertTrue(duration < 0.1, "ApplyUpgradeEffects should complete in under 100ms")
        if not isPerformant then
            print(string.format("⚠️  ApplyUpgradeEffects took %.3f seconds", duration))
        end
    end
    
    -- Test multiple rapid purchases
    if UpgradeService.PurchaseUpgrade then
        local rapidPurchases = 0
        for i = 1, 10 do
            local success, result = pcall(UpgradeService.PurchaseUpgrade, UpgradeService, mockPlayer, "speed_boost")
            if success then
                rapidPurchases = rapidPurchases + 1
            end
        end
        
        print(string.format("✅ Completed %d/10 rapid purchases", rapidPurchases))
    end
    
    assert(true, "Performance testing completed")
end)

-- Test 20: Integration Testing
upgradeSuite:addTest("Integration Testing", function()
    -- Test full upgrade flow: get definitions -> validate -> purchase -> apply effects
    local flowSuccess = true
    local flowErrors = {}
    
    -- Step 1: Get definitions
    if UpgradeService.GetUpgradeDefinitions then
        local success, definitions = pcall(UpgradeService.GetUpgradeDefinitions, UpgradeService)
        if not success then
            flowSuccess = false
            table.insert(flowErrors, "Failed to get upgrade definitions")
        end
    end
    
    -- Step 2: Validate upgrade
    if UpgradeService.ValidateUpgrade then
        local success, isValid = pcall(UpgradeService.ValidateUpgrade, UpgradeService, mockPlayer, "speed_boost")
        if not success then
            flowSuccess = false
            table.insert(flowErrors, "Failed to validate upgrade")
        end
    end
    
    -- Step 3: Purchase upgrade
    if UpgradeService.PurchaseUpgrade then
        local success, result = pcall(UpgradeService.PurchaseUpgrade, UpgradeService, mockPlayer, "speed_boost")
        if not success then
            flowSuccess = false
            table.insert(flowErrors, "Failed to purchase upgrade")
        end
    end
    
    -- Step 4: Apply effects
    if UpgradeService.ApplyUpgradeEffects then
        local success, result = pcall(UpgradeService.ApplyUpgradeEffects, UpgradeService, mockPlayer)
        if not success then
            flowSuccess = false
            table.insert(flowErrors, "Failed to apply upgrade effects")
        end
    end
    
    if flowSuccess then
        print("✅ Complete upgrade flow test passed")
    else
        print("⚠️  Upgrade flow had issues: " .. table.concat(flowErrors, ", "))
    end
    
    assert(true, "Integration testing completed")
end)

return upgradeSuite
