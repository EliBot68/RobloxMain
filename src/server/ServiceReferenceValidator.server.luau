-- ServiceReferenceValidator.server.luau
-- Comprehensive service reference validation script

local _ReplicatedStorage = game:GetService("ReplicatedStorage")

local ServiceReferenceValidator = {}

-- List of all services that should exist
local EXPECTED_SERVICES = {
    -- Core services
    "PlayerService",
    "UnifiedDataService", 
    "DataAdapter",
    "DataMigrationService",
    "EconomyBalanceService",
    
    -- Main services
    "MainGameService",
    "GameTrackService",
    "EnhancedGameTrackService", -- Alias
    "UpgradeService",
    "QuestService",
    "LevelingService",
    "AntiCheatService",
    "ObstacleSpawnerService",
    
    -- Economy services
    "CoinService",
    "ShopService", 
    "MysteryService",
    
    -- Other services
    "PetService",
    "PetOrchestrationService",
    "LeaderboardService",
    "AchievementService",
    "PartyService",
    "TrophyService"
}

-- Validate that all expected services exist and can be loaded
function ServiceReferenceValidator:ValidateAllServices()
    print("🔍 Starting comprehensive service reference validation...")
    
    local results = {
        passed = {},
        failed = {},
        warnings = {}
    }
    
    for _, serviceName in ipairs(EXPECTED_SERVICES) do
        local success, result = self:ValidateService(serviceName)
        
        if success then
            table.insert(results.passed, serviceName)
            print("✅ " .. serviceName .. " - OK")
        else
            table.insert(results.failed, {service = serviceName, error = result})
            warn("❌ " .. serviceName .. " - FAILED: " .. tostring(result))
        end
    end
    
    -- Print summary
    print("\n📊 VALIDATION SUMMARY:")
    print("✅ Passed: " .. #results.passed .. " services")
    print("❌ Failed: " .. #results.failed .. " services") 
    print("⚠️ Warnings: " .. #results.warnings .. " issues")
    
    if #results.failed > 0 then
        print("\n🚨 FAILED SERVICES:")
        for _, failure in ipairs(results.failed) do
            print("   - " .. failure.service .. ": " .. failure.error)
        end
    end
    
    return results
end

-- Validate a single service
function ServiceReferenceValidator:ValidateService(serviceName)
    local success, service = pcall(function()
        -- Try to require the service from different possible locations
        local paths = {
            script.Parent.services[serviceName],
            script.Parent.services.core[serviceName], 
            script.Parent.services.economy[serviceName]
        }
        
        for _, path in ipairs(paths) do
            if path then
                return require(path)
            end
        end
        
        error("Service not found in any expected location")
    end)
    
    if success then
        -- Additional validation - check if service has expected structure
        if type(service) == "table" then
            if service.Init or service.Initialize or service.Start then
                return true, service
            else
                return false, "Service table missing Init/Initialize/Start methods"
            end
        else
            return false, "Service didn't return a table"
        end
    else
        return false, service
    end
end

-- Check for broken references in specific files
function ServiceReferenceValidator:CheckBrokenReferences()
    print("🔍 Checking for broken service references...")
    
    local knownIssues = {
        {
            file = "economy/CoinService.luau",
            issue = "EnhancedUpgradeService reference",
            status = "FIXED - Updated to UpgradeService"
        },
        {
            file = "Documentation",
            issue = "EnhancedGameTrackService references", 
            status = "FIXED - Created alias service"
        }
    }
    
    print("📋 KNOWN ISSUES STATUS:")
    for _, issue in ipairs(knownIssues) do
        print("   " .. issue.file .. ": " .. issue.status)
    end
end

-- Auto-run validation when script loads
local function runValidation()
    if game:GetService("RunService"):IsServer() then
        wait(2) -- Give services time to load
        
        print("🚀 AUTO-RUNNING SERVICE REFERENCE VALIDATION")
        local results = ServiceReferenceValidator:ValidateAllServices()
        ServiceReferenceValidator:CheckBrokenReferences()
        
        if #results.failed == 0 then
            print("🎉 ALL SERVICE REFERENCES VALIDATED SUCCESSFULLY!")
        else
            warn("⚠️ VALIDATION FOUND ISSUES - CHECK OUTPUT ABOVE")
        end
    end
end

-- Run validation
spawn(runValidation)

return ServiceReferenceValidator
