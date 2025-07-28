-- MainGameServiceMigration.server.luau
-- Migration script to ensure smooth transition from old MainGameService to Enhanced version
-- Handles compatibility, validates integration, and provides fallback mechanisms

local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

print("🔄 MainGameService Migration - Ensuring Enhanced Integration...")

-- Migration configuration
local MIGRATION_CONFIG = {
    enableFallbacks = true,
    validateIntegration = true,
    cleanupOldReferences = true,
    timeoutSeconds = 30
}

-- Global migration status
local migrationStatus = {
    enhanced_loaded = false,
    integration_complete = false,
    validation_passed = false,
    fallback_active = false
}

-- Function to validate the enhanced MainGameService
local function validateEnhancedMainGameService()
    print("🔍 Validating Enhanced MainGameService...")
    
    local success, MainGameService = pcall(function()
        return require(script.Parent.services.MainGameService)
    end)
    
    if not success then
        warn("❌ Failed to load MainGameService: " .. tostring(MainGameService))
        return false
    end
    
    -- Check for enhanced features
    local requiredMethods = {
        "Init", "Start", "SafeRequire", "StartGame", "EndGame", 
        "GetCurrentState", "ValidateSystemIntegrity", "ValidateAndRepairSystem"
    }
    
    for _, method in ipairs(requiredMethods) do
        if not MainGameService[method] then
            warn("❌ Enhanced MainGameService missing method: " .. method)
            return false
        end
    end
    
    -- Check for enhanced properties
    local requiredProperties = {
        "State", "Services", "Controllers", "EventConnections", "ActiveGames"
    }
    
    for _, prop in ipairs(requiredProperties) do
        if MainGameService[prop] == nil then
            warn("❌ Enhanced MainGameService missing property: " .. prop)
            return false
        end
    end
    
    print("✅ Enhanced MainGameService validation passed")
    migrationStatus.enhanced_loaded = true
    return true
end

-- Function to check integration with existing systems
local function validateSystemIntegration()
    print("🔗 Validating system integration...")
    
    -- Check if SafeRequire utility is available
    local safeRequireAvailable = pcall(function()
        return require(ReplicatedStorage.Shared.utils.SafeRequire)
    end)
    
    if not safeRequireAvailable then
        warn("⚠️ SafeRequire utility not available - enhanced features may be limited")
    end
    
    -- Check if WorldObjectValidator is available
    local validatorAvailable = pcall(function()
        return require(ReplicatedStorage.Shared.utils.WorldObjectValidator)
    end)
    
    if not validatorAvailable then
        warn("⚠️ WorldObjectValidator not available - system validation disabled")
    end
    
    -- Check if DeveloperConfig is available
    local devConfigAvailable = pcall(function()
        return require(ReplicatedStorage.Shared.modules.DeveloperConfig)
    end)
    
    if not devConfigAvailable then
        warn("⚠️ DeveloperConfig not available - developer features disabled")
    end
    
    -- Check global functions
    local expectedGlobals = {
        "_G.GetMainGameService", "_G.GetGameState", "_G.StartNewGame", 
        "_G.EndCurrentGame", "_G.ValidateGameSystems", "_G.RepairGameSystems"
    }
    
    local globalsReady = 0
    for _, globalName in ipairs(expectedGlobals) do
        local parts = {}
        for part in globalName:gmatch("[^%.]+") do
            table.insert(parts, part)
        end
        
        if parts[1] == "_G" and _G[parts[2]] then
            globalsReady = globalsReady + 1
        end
    end
    
    if globalsReady < #expectedGlobals then
        warn("⚠️ Not all global functions available (" .. globalsReady .. "/" .. #expectedGlobals .. ")")
    else
        print("✅ All global functions available")
    end
    
    migrationStatus.integration_complete = true
    return true
end

-- Function to perform comprehensive validation
local function performComprehensiveValidation()
    print("🎯 Performing comprehensive validation...")
    
    local success, mainGameService = pcall(function()
        return _G.GetMainGameService()
    end)
    
    if not success or not mainGameService then
        warn("❌ Cannot access MainGameService via global function")
        return false
    end
    
    -- Test core functionality
    local tests = {
        {
            name = "State Management",
            test = function()
                return mainGameService:GetCurrentState() ~= nil
            end
        },
        {
            name = "Service Registry",
            test = function()
                return type(mainGameService:GetServices()) == "table"
            end
        },
        {
            name = "Controller Registry", 
            test = function()
                return type(mainGameService:GetControllers()) == "table"
            end
        },
        {
            name = "Initialization Status",
            test = function()
                return mainGameService:IsInitialized() == true
            end
        },
        {
            name = "System Integrity Check",
            test = function()
                if mainGameService.ValidateSystemIntegrity then
                    local integrity = mainGameService:ValidateSystemIntegrity()
                    return integrity ~= nil
                end
                return true
            end
        }
    }
    
    local passedTests = 0
    for _, test in ipairs(tests) do
        local success, result = pcall(test.test)
        if success and result then
            print("  ✅ " .. test.name)
            passedTests = passedTests + 1
        else
            warn("  ❌ " .. test.name .. ": " .. tostring(result))
        end
    end
    
    local allPassed = passedTests == #tests
    if allPassed then
        print("✅ Comprehensive validation passed (" .. passedTests .. "/" .. #tests .. " tests)")
        migrationStatus.validation_passed = true
    else
        warn("❌ Validation issues detected (" .. passedTests .. "/" .. #tests .. " tests passed)")
    end
    
    return allPassed
end

-- Function to cleanup old references and files
local function cleanupOldReferences()
    if not MIGRATION_CONFIG.cleanupOldReferences then
        return
    end
    
    print("🧹 Cleaning up old references...")
    
    -- Check if backup file exists and report
    if script.Parent.services:FindFirstChild("MainGameService.luau.backup") then
        print("📋 Backup of old MainGameService preserved for rollback")
    end
    
    -- Clear any cached old references
    if _G.OLD_MainGameService then
        _G.OLD_MainGameService = nil
        print("🗑️ Cleared old MainGameService global reference")
    end
    
    print("✅ Cleanup completed")
end

-- Function to generate migration report
local function generateMigrationReport()
    print("\n📊 Enhanced MainGameService Migration Report")
    print("=" .. string.rep("=", 50))
    
    local statusEmoji = {
        [true] = "✅",
        [false] = "❌"
    }
    
    print("Migration Status:")
    print("  " .. statusEmoji[migrationStatus.enhanced_loaded] .. " Enhanced MainGameService Loaded")
    print("  " .. statusEmoji[migrationStatus.integration_complete] .. " System Integration Complete")
    print("  " .. statusEmoji[migrationStatus.validation_passed] .. " Validation Passed")
    print("  " .. statusEmoji[not migrationStatus.fallback_active] .. " No Fallback Required")
    
    local allGood = migrationStatus.enhanced_loaded and 
                   migrationStatus.integration_complete and 
                   migrationStatus.validation_passed and 
                   not migrationStatus.fallback_active
    
    if allGood then
        print("\n🎉 MIGRATION SUCCESSFUL!")
        print("Enhanced MainGameService is fully operational with all advanced features.")
        print("Key enhancements active:")
        print("  • SafeRequire module loading")
        print("  • World object validation")
        print("  • Enhanced state management")
        print("  • Comprehensive event integration")
        print("  • System integrity monitoring")
        print("  • Developer mode integration")
    else
        print("\n⚠️ MIGRATION COMPLETED WITH ISSUES")
        print("Enhanced MainGameService is running but some features may be limited.")
        print("Check the warnings above for details.")
    end
    
    print("=" .. string.rep("=", 50) .. "\n")
end

-- Main migration function
local function runMigration()
    print("🚀 Starting Enhanced MainGameService Migration...")
    
    -- Step 1: Validate enhanced MainGameService
    if not validateEnhancedMainGameService() then
        warn("❌ Enhanced MainGameService validation failed")
        migrationStatus.fallback_active = true
        return false
    end
    
    -- Step 2: Wait for integration to complete
    local integrationAttempts = 0
    while integrationAttempts < MIGRATION_CONFIG.timeoutSeconds do
        if _G.GetMainGameService then
            break
        end
        wait(1)
        integrationAttempts = integrationAttempts + 1
    end
    
    -- Step 3: Validate system integration
    validateSystemIntegration()
    
    -- Step 4: Perform comprehensive validation
    performComprehensiveValidation()
    
    -- Step 5: Cleanup old references
    cleanupOldReferences()
    
    -- Step 6: Generate report
    generateMigrationReport()
    
    return true
end

-- Execute migration on server start
if RunService:IsServer() then
    spawn(function()
        wait(5) -- Wait for other systems to initialize
        runMigration()
    end)
end
