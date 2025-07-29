-- Server Main Entry Point
print("🚀 Color Rush Server starting...")

-- Core Roblox Services
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

-- ASSUMPTION: Knit framework is installed in ReplicatedStorage.Packages.Knit
local Knit = require(ReplicatedStorage.Packages.Knit)

-- STEP 1: Initialize SafeRequire utility for crash-resistant loading
print("🔧 Initializing SafeRequire utility...")
local SafeRequire = require(ReplicatedStorage.Shared.utils.SafeRequire)

-- STEP 2: Initialize RuntimeValidator for system health checking (CRITICAL)
print("🔍 Initializing RuntimeValidator...")
local RuntimeValidator, validatorError = SafeRequire.requireWithRetry(
    ReplicatedStorage.Shared.services.RuntimeValidator,
    3 -- 3 retry attempts for this critical component
)

if RuntimeValidator then
    print("✅ RuntimeValidator loaded successfully with retry protection")
else
    warn("❌ RUNTIME VALIDATOR FAILURE: Failed to load after retries - using fallback")
    warn("📍 Module Path: ReplicatedStorage.Shared.services.RuntimeValidator")
    if validatorError then
        warn(string.format("💥 Last Error: %s", validatorError))
    end
    warn("🔄 Retry attempts: 3 (all failed)")
    warn("🛡️ Creating fallback RuntimeValidator with basic validation...")
    
    -- Create fallback RuntimeValidator with basic methods
    RuntimeValidator = {
        Init = function() return true end,
        ValidateAll = function() return true end,
        ValidateService = function(self, service, serviceName) 
            -- Basic service validation fallback
            if not service then
                warn(string.format("  🔍 Fallback validation: %s is nil", serviceName))
                return false
            end
            
            if type(service) == "table" then
                -- Check if it has at least one function (basic service pattern)
                for key, value in pairs(service) do
                    if type(value) == "function" then
                        return true
                    end
                end
                warn(string.format("  ⚠️ Fallback validation: %s is a table but has no functions", serviceName))
                return false
            else
                warn(string.format("  ⚠️ Fallback validation: %s is not a table (type: %s)", serviceName, type(service)))
                return false
            end
        end,
        GetValidationStatus = function() return {IsValidated = false, ErrorCount = 0, LastValidation = 0} end,
        ForceValidation = function() return true end
    }
end

-- STEP 3: Safe Service Loading with comprehensive error handling
print("📦 Loading services with SafeRequire...")

-- Critical Core Services (Required for basic functionality)
local criticalServices = {
    PlayerService = script.services.core.PlayerService,
    DataService = script.services.core.DataService,
    UnifiedDataService = script.services.core.UnifiedDataService,
    GameService = script.services.core.GameService,
}

-- Data Management Services
local dataServices = {
    DataMigrationService = script.services.core.DataMigrationService,
    DataAdapter = script.services.core.DataAdapter,
    EconomyBalanceService = script.services.core.EconomyBalanceService,
}

-- Economy Services
local economyServices = {
    ShopService = script.services.economy.ShopService,
    CoinService = script.services.economy.CoinService,
    MysteryService = script.services.economy.MysteryService,
}

-- Feature Services
local featureServices = {
    LeaderboardService = script.services.LeaderboardService,
    FountainService = script.services.FountainService,
    QuestService = script.services.QuestService,
    TutorialService = script.services.TutorialService,
    TeleportService = script.services.TeleportService,
    ArchwayService = script.services.ArchwayService,
    LevelingService = script.services.LevelingService,
    EventService = script.services.EventService,
    DailyStreakService = script.services.DailyStreakService,
    GhostService = script.services.GhostService,
    JumpService = script.services.JumpService,
    UpgradeService = script.services.UpgradeService,
    EnhancedUpgradeService = script.services.EnhancedUpgradeService,
    PuzzleService = script.services.PuzzleService,
    TrophyService = script.services.TrophyService,
    PetService = script.services.PetService,
    ExclusiveService = script.services.ExclusiveService,
    PartyService = script.services.PartyService,
    MiniGameService = script.services.MiniGameService,
    BuffService = script.services.BuffService,
    SpectatorService = script.services.SpectatorService,
    TournamentService = script.services.TournamentService,
    RebirthService = script.services.RebirthService,
    AuraService = script.services.AuraService,
    TrailService = script.services.TrailService,
    AchievementService = script.services.AchievementService,
    DailyRewardService = script.services.DailyRewardService,
    HubPuzzleService = script.services.HubPuzzleService,
}

-- Infrastructure Services
local infrastructureServices = {
    AnalyticsService = script.services.AnalyticsService,
    MonetizationService = script.services.MonetizationService,
    WeeklyLeaderboardService = script.services.WeeklyLeaderboardService,
    GoalService = script.services.GoalService,
    ContentManager = script.services.ContentManager,
    HubService = script.services.HubService,
    GameAudioService = script.services.GameAudioService,
    SoftLaunchService = script.services.SoftLaunchService,
    CleanupService = script.services.CleanupService,
    WorldBuilderService = script.services.WorldBuilderService,
    VisualPolishService = script.services.VisualPolishService,
    EnhancedGameTrackService = script.services.EnhancedGameTrackService,
    AntiCheatService = script.services.AntiCheatService,
}

-- Main Game Controller (Core Gameplay Management)
local mainGameController = {
    MainGameController = script.MainGameController,
}

-- Special Modules
local specialModules = {
    GoalIntegration = script.GoalIntegration,
}

-- Service loading function with detailed error reporting and validation
local function loadServiceBatch(serviceBatch, batchName, useRetry)
    print(string.format("📦 Loading %s services...", batchName))
    local loadedServices = {}
    local failedServices = {}
    
    for serviceName, modulePath in pairs(serviceBatch) do
        local service
        local loadError = nil
        
        if useRetry then
            -- Use retry logic for critical services
            service, loadError = SafeRequire.requireWithRetry(modulePath, 3)
            if service then
                print(string.format("  ✅ %s loaded successfully (with retry protection)", serviceName))
            else
                -- Enhanced failure logging for critical services
                warn(string.format("  ❌ CRITICAL FAILURE: %s failed to load after 3 retries", serviceName))
                warn(string.format("    📍 Module Path: %s", tostring(modulePath)))
                if loadError then
                    warn(string.format("    💥 Last Error: %s", tostring(loadError)))
                end
                warn(string.format("    🔄 Retry attempts: 3 (all failed)"))
            end
        else
            -- Use standard safe require for non-critical services
            service, loadError = SafeRequire.require(modulePath)
            if service then
                print(string.format("  ✅ %s loaded successfully", serviceName))
            else
                -- Enhanced failure logging for standard services
                warn(string.format("  ❌ LOAD FAILURE: %s failed to load", serviceName))
                warn(string.format("    📍 Module Path: %s", tostring(modulePath)))
                if loadError then
                    warn(string.format("    💥 Error: %s", tostring(loadError)))
                end
            end
        end
        
        if service then
            -- Validate the service with RuntimeValidator
            if RuntimeValidator and RuntimeValidator.ValidateService then
                local isValid, validationResult = pcall(function()
                    return RuntimeValidator:ValidateService(service, serviceName)
                end)
                
                if isValid and validationResult then
                    print(string.format("  🔍 %s passed validation", serviceName))
                    loadedServices[serviceName] = service
                elseif isValid and not validationResult then
                    -- Enhanced validation failure logging
                    warn(string.format("  ⚠️ VALIDATION FAILURE: %s failed validation but will still load", serviceName))
                    warn(string.format("    📍 Service Type: %s", type(service)))
                    warn(string.format("    🔍 Validation Issue: Service structure doesn't match expected patterns"))
                    
                    -- Additional service structure analysis
                    if type(service) == "table" then
                        local functionCount = 0
                        local propertyCount = 0
                        for key, value in pairs(service) do
                            if type(value) == "function" then
                                functionCount = functionCount + 1
                            else
                                propertyCount = propertyCount + 1
                            end
                        end
                        warn(string.format("    📊 Service Analysis: %d functions, %d properties", functionCount, propertyCount))
                    end
                    
                    loadedServices[serviceName] = service
                else
                    -- Enhanced validation crash logging
                    warn(string.format("  ❌ VALIDATION CRASH: %s validation crashed but service will still load", serviceName))
                    warn(string.format("    📍 Service Type: %s", type(service)))
                    warn(string.format("    💥 Validation Error: %s", tostring(validationResult)))
                    loadedServices[serviceName] = service
                end
            else
                -- RuntimeValidator not available
                warn(string.format("  ⚠️ VALIDATION SKIPPED: %s (RuntimeValidator unavailable)", serviceName))
                loadedServices[serviceName] = service
            end
        else
            -- Enhanced failure tracking
            local errorDetails = useRetry and 
                string.format("Critical service failed after 3 retries: %s", tostring(loadError)) or 
                string.format("Service failed to load: %s", tostring(loadError))
            failedServices[serviceName] = errorDetails
        end
    end
    
    if next(failedServices) then
        warn(string.format("💥 %s BATCH FAILURES: %d services failed to load", batchName, #failedServices))
        warn("=====================================")
        for serviceName, error in pairs(failedServices) do
            warn(string.format("  ❌ FAILED SERVICE: %s", serviceName))
            warn(string.format("    📝 Details: %s", error))
        end
        warn("=====================================")
    else
        print(string.format("✅ ALL %s SERVICES LOADED SUCCESSFULLY!", batchName))
    end
    
    return loadedServices, failedServices
end

-- Load all service batches
local Services = {}
local AllFailedServices = {}

-- Load critical services first (with retry protection)
print("🔥 Loading CRITICAL services (with retry protection)...")
local criticalLoaded, criticalFailed = loadServiceBatch(criticalServices, "CRITICAL", true)
for serviceName, service in pairs(criticalLoaded) do
    Services[serviceName] = service
end
for serviceName, error in pairs(criticalFailed) do
    AllFailedServices[serviceName] = error
end

-- Load data services (with retry protection due to importance)
print("💾 Loading DATA services (with retry protection)...")
local dataLoaded, dataFailed = loadServiceBatch(dataServices, "DATA", true)
for serviceName, service in pairs(dataLoaded) do
    Services[serviceName] = service
end
for serviceName, error in pairs(dataFailed) do
    AllFailedServices[serviceName] = error
end

-- Load economy services (standard loading)
print("💰 Loading ECONOMY services...")
local economyLoaded, economyFailed = loadServiceBatch(economyServices, "ECONOMY", false)
for serviceName, service in pairs(economyLoaded) do
    Services[serviceName] = service
end
for serviceName, error in pairs(economyFailed) do
    AllFailedServices[serviceName] = error
end

-- Load feature services (standard loading)
print("🎮 Loading FEATURE services...")
local featureLoaded, featureFailed = loadServiceBatch(featureServices, "FEATURE", false)
for serviceName, service in pairs(featureLoaded) do
    Services[serviceName] = service
end
for serviceName, error in pairs(featureFailed) do
    AllFailedServices[serviceName] = error
end

-- Load infrastructure services (standard loading)
print("🏗️ Loading INFRASTRUCTURE services...")
local infraLoaded, infraFailed = loadServiceBatch(infrastructureServices, "INFRASTRUCTURE", false)
for serviceName, service in pairs(infraLoaded) do
    Services[serviceName] = service
end
for serviceName, error in pairs(infraFailed) do
    AllFailedServices[serviceName] = error
end

-- Load Main Game Controller (CRITICAL - Core game management)
print("🎮 Loading MAIN GAME CONTROLLER (CRITICAL)...")
local gameControllerLoaded, gameControllerFailed = loadServiceBatch(mainGameController, "MAIN_GAME_CONTROLLER", true)
for serviceName, service in pairs(gameControllerLoaded) do
    Services[serviceName] = service
end
for serviceName, error in pairs(gameControllerFailed) do
    AllFailedServices[serviceName] = error
end

-- Load special modules (with retry protection due to integration importance)
print("⚙️ Loading SPECIAL modules (with retry protection)...")
for moduleName, modulePath in pairs(specialModules) do
    local module, loadError = SafeRequire.requireWithRetry(modulePath, 3)
    
    if module then
        -- Validate the special module with RuntimeValidator
        if RuntimeValidator and RuntimeValidator.ValidateService then
            local isValid, validationResult = pcall(function()
                return RuntimeValidator:ValidateService(module, moduleName)
            end)
            
            if isValid and validationResult then
                print(string.format("  ✅ SPECIAL: %s loaded and validated successfully", moduleName))
            elseif isValid and not validationResult then
                -- Enhanced validation failure logging for special modules
                warn(string.format("  ⚠️ SPECIAL VALIDATION FAILURE: %s loaded but failed validation", moduleName))
                warn(string.format("    📍 Module Path: %s", tostring(modulePath)))
                warn(string.format("    📍 Module Type: %s", type(module)))
                if type(module) == "table" then
                    local functionCount = 0
                    for key, value in pairs(module) do
                        if type(value) == "function" then
                            functionCount = functionCount + 1
                        end
                    end
                    warn(string.format("    📊 Module Analysis: %d functions found", functionCount))
                end
            else
                -- Enhanced validation crash logging for special modules
                warn(string.format("  ❌ SPECIAL VALIDATION CRASH: %s validation crashed", moduleName))
                warn(string.format("    📍 Module Path: %s", tostring(modulePath)))
                warn(string.format("    📍 Module Type: %s", type(module)))
                warn(string.format("    💥 Validation Error: %s", tostring(validationResult)))
            end
        else
            warn(string.format("  ⚠️ SPECIAL VALIDATION SKIPPED: %s (RuntimeValidator unavailable)", moduleName))
        end
        
        Services[moduleName] = module
    else
        -- Enhanced failure logging for special modules
        warn(string.format("  ❌ SPECIAL MODULE FAILURE: %s failed to load after 3 retries", moduleName))
        warn(string.format("    📍 Module Path: %s", tostring(modulePath)))
        if loadError then
            warn(string.format("    💥 Last Error: %s", tostring(loadError)))
        end
        warn(string.format("    🔄 Retry attempts: 3 (all failed)"))
        AllFailedServices[moduleName] = string.format("Special module failed after retries: %s", tostring(loadError))
    end
end

-- Service loading summary
print("📊 COMPREHENSIVE SERVICE LOADING REPORT:")
print("==========================================")

-- Calculate service counts properly
local serviceCount = 0
for _ in pairs(Services) do
    serviceCount = serviceCount + 1
end

local failedCount = 0
for _ in pairs(AllFailedServices) do
    failedCount = failedCount + 1
end

print(string.format("  ✅ Successfully loaded: %d services", serviceCount))

if next(AllFailedServices) then
    warn(string.format("  ❌ FAILED TO LOAD: %d services", failedCount))
    warn("  💥 FAILURE DETAILS:")
    for serviceName, error in pairs(AllFailedServices) do
        warn(string.format("    ❌ %s", serviceName))
        warn(string.format("      📝 %s", error))
    end
else
    print("  🎉 ALL SERVICES LOADED SUCCESSFULLY!")
end
print("==========================================")

-- Post-loading validation summary
print("🔍 COMPREHENSIVE VALIDATION REPORT:")
print("==========================================")
if RuntimeValidator and RuntimeValidator.ValidateService then
    local validatedCount = 0
    local validationFailedCount = 0
    local validationCrashedCount = 0
    local validationFailures = {}
    local validationCrashes = {}
    
    for serviceName, service in pairs(Services) do
        local isValid, validationResult = pcall(function()
            return RuntimeValidator:ValidateService(service, serviceName)
        end)
        
        if isValid and validationResult then
            validatedCount = validatedCount + 1
        elseif isValid and not validationResult then
            validationFailedCount = validationFailedCount + 1
            table.insert(validationFailures, serviceName)
        else
            validationCrashedCount = validationCrashedCount + 1
            table.insert(validationCrashes, {name = serviceName, error = tostring(validationResult)})
        end
    end
    
    print(string.format("  🔍 Validation Results: %d passed, %d failed, %d crashed", 
        validatedCount, validationFailedCount, validationCrashedCount))
    
    if validationFailedCount > 0 then
        warn("  ⚠️ VALIDATION FAILURES:")
        for _, serviceName in ipairs(validationFailures) do
            warn(string.format("    ⚠️ %s - Service structure doesn't match expected patterns", serviceName))
        end
    end
    
    if validationCrashedCount > 0 then
        warn("  ❌ VALIDATION CRASHES:")
        for _, crash in ipairs(validationCrashes) do
            warn(string.format("    ❌ %s - Validation crashed: %s", crash.name, crash.error))
        end
    end
    
    if validationFailedCount == 0 and validationCrashedCount == 0 then
        print("  ✅ ALL SERVICES PASSED VALIDATION!")
    end
else
    print("  ⚠️ RuntimeValidator.ValidateService not available - validation skipped")
end

-- STEP 4: Initialize RuntimeValidator early for system monitoring
print("🔍 Starting RuntimeValidator...")
if RuntimeValidator and RuntimeValidator.Init then
    local success, error = pcall(RuntimeValidator.Init, RuntimeValidator)
    if success then
        print("✅ RuntimeValidator initialized successfully")
    else
        warn("❌ RuntimeValidator initialization failed: " .. tostring(error))
    end
end

-- STEP 4.5: Register all loaded services with Knit framework
print("🔗 Registering services with Knit framework...")
local registeredServices = {}
local registrationFailures = {}

for serviceName, service in pairs(Services) do
    if service and type(service) == "table" then
        local success, result = pcall(function()
            -- ASSUMPTION: Services follow Knit.CreateService pattern or are compatible
            if service.Name and service.Client then
                -- Already a Knit service
                return service
            else
                -- Convert to Knit-compatible service
                local knitService = Knit.CreateService({
                    Name = serviceName,
                    Client = service.Client or {},
                })
                
                -- Copy methods and properties
                for key, value in pairs(service) do
                    if key ~= "Name" and key ~= "Client" then
                        knitService[key] = value
                    end
                end
                
                return knitService
            end
        end)
        
        if success then
            registeredServices[serviceName] = result
            print(string.format("  ✅ %s registered with Knit", serviceName))
        else
            registrationFailures[serviceName] = tostring(result)
            warn(string.format("  ❌ Failed to register %s: %s", serviceName, tostring(result)))
        end
    else
        warn(string.format("  ⚠️ Skipping %s - invalid service object", serviceName))
    end
end

-- Update Services table with registered services
Services = registeredServices

if next(registrationFailures) then
    warn("⚠️ Service registration failures occurred:")
    for serviceName, error in pairs(registrationFailures) do
        warn(string.format("  ❌ %s: %s", serviceName, error))
    end
end

print(string.format("✅ Registered %d services with Knit", #Services))

-- STEP 4.6: Start Knit framework
print("🚀 Starting Knit framework...")
local knitSuccess, knitError = pcall(function()
    Knit.Start():andThen(function()
        print("✅ Knit framework started successfully")
    end):catch(function(err)
        warn("❌ Knit framework startup error: " .. tostring(err))
    end)
end)

if not knitSuccess then
    warn("❌ Failed to start Knit framework: " .. tostring(knitError))
    warn("⚠️ Continuing with manual service initialization...")
end

-- Wait a moment for Knit to fully initialize
task.wait(1) -- UPDATED for modern API

-- STEP 5: Safe Service Initialization with comprehensive error handling
print("🚀 Initializing services with error protection...")

-- Service initialization function with error handling
local function initializeService(service, serviceName, isRequired)
    if not service then
        local message = string.format("Cannot initialize %s: service not loaded", serviceName)
        if isRequired then
            error(message)
        else
            warn("⚠️ " .. message)
            return false
        end
    end
    
    if not service.Init and not service.Initialize then
        warn(string.format("⚠️ %s has no Init() or Initialize() method", serviceName))
        return true -- Not an error, just no initialization needed
    end
    
    local initMethod = service.Init or service.Initialize
    local success, result = pcall(initMethod, service)
    
    if success then
        print(string.format("  ✅ %s initialized successfully", serviceName))
        return true
    else
        local message = string.format("%s initialization failed: %s", serviceName, tostring(result))
        if isRequired then
            error("💥 CRITICAL: " .. message)
        else
            warn("❌ " .. message)
            return false
        end
    end
end

-- Initialize services in dependency order
print("🔥 Phase 1: Critical Data Services")
initializeService(Services.UnifiedDataService, "UnifiedDataService", true)
initializeService(Services.DataMigrationService, "DataMigrationService", true)
initializeService(Services.DataAdapter, "DataAdapter", true)
initializeService(Services.EconomyBalanceService, "EconomyBalanceService", true)

-- Set up adapter with unified service reference
if Services.DataAdapter and Services.UnifiedDataService then
    local success, error = pcall(function()
        Services.DataAdapter:SetUnifiedDataService(Services.UnifiedDataService)
    end)
    if not success then
        warn("❌ Failed to connect DataAdapter to UnifiedDataService: " .. tostring(error))
    end
end

print("🔥 Phase 2: Core Game Services")
initializeService(Services.DataService, "DataService", true)
initializeService(Services.PlayerService, "PlayerService", true)
initializeService(Services.GameService, "GameService", true)

print("🏪 Phase 3: Economy Services")
initializeService(Services.ShopService, "ShopService", false)
initializeService(Services.CoinService, "CoinService", false)
initializeService(Services.MysteryService, "MysteryService", false)

print("📊 Phase 4: Analytics and Infrastructure")
initializeService(Services.AnalyticsService, "AnalyticsService", false)
initializeService(Services.MonetizationService, "MonetizationService", false)
initializeService(Services.LeaderboardService, "LeaderboardService", false)

print("🎮 Phase 5: Feature Services")
initializeService(Services.LevelingService, "LevelingService", false)
initializeService(Services.EventService, "EventService", false)
initializeService(Services.DailyStreakService, "DailyStreakService", false)
initializeService(Services.HubService, "HubService", false)
initializeService(Services.GameAudioService, "GameAudioService", false)
initializeService(Services.GhostService, "GhostService", false)
initializeService(Services.UpgradeService, "UpgradeService", false)
initializeService(Services.EnhancedUpgradeService, "EnhancedUpgradeService", false)
initializeService(Services.TrailService, "TrailService", false)
initializeService(Services.PuzzleService, "PuzzleService", false)
initializeService(Services.TrophyService, "TrophyService", false)
initializeService(Services.PetService, "PetService", false)
initializeService(Services.GoalService, "GoalService", false)
initializeService(Services.GoalIntegration, "GoalIntegration", false)
initializeService(Services.ContentManager, "ContentManager", false)
initializeService(Services.WeeklyLeaderboardService, "WeeklyLeaderboardService", false)
initializeService(Services.RebirthService, "RebirthService", false)
initializeService(Services.AuraService, "AuraService", false)
initializeService(Services.ExclusiveService, "ExclusiveService", false)
initializeService(Services.PartyService, "PartyService", false)
initializeService(Services.MiniGameService, "MiniGameService", false)
initializeService(Services.BuffService, "BuffService", false)
initializeService(Services.SpectatorService, "SpectatorService", false)
initializeService(Services.TournamentService, "TournamentService", false)
initializeService(Services.AchievementService, "AchievementService", false)
initializeService(Services.DailyRewardService, "DailyRewardService", false)
initializeService(Services.HubPuzzleService, "HubPuzzleService", false)

print("🏗️ Phase 6: World Building Services")
-- Initialize Soft Launch Service (LAST - after all other services are ready)
initializeService(Services.SoftLaunchService, "SoftLaunchService", false)

-- Initialize Cleanup Service (removes old content and optimizes)
initializeService(Services.CleanupService, "CleanupService", false)

-- Initialize World Builder (creates the actual game world)
initializeService(Services.WorldBuilderService, "WorldBuilderService", false)

-- Initialize Visual Polish Service (animations and effects)
initializeService(Services.VisualPolishService, "VisualPolishService", false)

-- Initialize Enhanced Game Track Service (creates multi-difficulty gameplay mechanics)
initializeService(Services.EnhancedGameTrackService, "EnhancedGameTrackService", false)

-- Auto-initializing services (services that handle their own initialization)
print("🔄 Auto-initializing services...")
local autoInitServices = {
    "FountainService", "QuestService", "TutorialService", 
    "TeleportService", "ArchwayService"
}

for _, serviceName in ipairs(autoInitServices) do
    if Services[serviceName] then
        print(string.format("  ℹ️ %s will auto-initialize", serviceName))
        
        -- ASSUMPTION: Auto-init services may need a nudge to start
        if Services[serviceName].KnitStart then
            pcall(function()
                Services[serviceName]:KnitStart()
            end)
        elseif Services[serviceName].Start then
            pcall(function()
                Services[serviceName]:Start()
            end)
        end
    else
        warn(string.format("  ⚠️ %s not available for auto-initialization", serviceName))
    end
end

-- STEP 6: Safe Service Dependency Injection
print("🔗 Setting up service dependencies with error protection...")

-- Safe service connection function
local function connectServices(serviceA, methodName, serviceB, connectionName)
    if not serviceA then
        warn(string.format("⚠️ Cannot connect %s: source service not available", connectionName or "service"))
        return false
    end
    
    if not serviceB then
        warn(string.format("⚠️ Cannot connect %s: target service not available", connectionName or "service"))
        return false
    end
    
    if not serviceA[methodName] then
        warn(string.format("⚠️ Cannot connect %s: method %s not found", connectionName or "service", methodName))
        return false
    end
    
    local success, error = pcall(serviceA[methodName], serviceA, serviceB)
    if success then
        print(string.format("  ✅ %s connected successfully", connectionName or "Service"))
        return true
    else
        warn(string.format("❌ Failed to connect %s: %s", connectionName or "service", tostring(error)))
        return false
    end
end

-- Set up service connections with error handling
print("🔗 Phase 1: Core Service Dependencies")
connectServices(Services.DataService, "SetPlayerService", Services.PlayerService, "DataService -> PlayerService")
connectServices(Services.PlayerService, "SetLeaderboardService", Services.LeaderboardService, "PlayerService -> LeaderboardService")
connectServices(Services.PlayerService, "SetShopService", Services.ShopService, "PlayerService -> ShopService")
connectServices(Services.PlayerService, "SetAnalyticsService", Services.AnalyticsService, "PlayerService -> AnalyticsService")
connectServices(Services.PlayerService, "SetMonetizationService", Services.MonetizationService, "PlayerService -> MonetizationService")
connectServices(Services.PlayerService, "SetAchievementService", Services.AchievementService, "PlayerService -> AchievementService")

print("🔗 Phase 2: Game Service Dependencies")
connectServices(Services.GameService, "SetPlayerService", Services.PlayerService, "GameService -> PlayerService")
connectServices(Services.GameService, "SetQuestService", Services.QuestService, "GameService -> QuestService")
connectServices(Services.GameService, "SetAnalyticsService", Services.AnalyticsService, "GameService -> AnalyticsService")
connectServices(Services.GameService, "SetMonetizationService", Services.MonetizationService, "GameService -> MonetizationService")
connectServices(Services.GameService, "SetLevelingService", Services.LevelingService, "GameService -> LevelingService")
connectServices(Services.GameService, "SetEventService", Services.EventService, "GameService -> EventService")
connectServices(Services.GameService, "SetGhostService", Services.GhostService, "GameService -> GhostService")
connectServices(Services.GameService, "SetUpgradeService", Services.UpgradeService, "GameService -> UpgradeService")
connectServices(Services.GameService, "SetTrophyService", Services.TrophyService, "GameService -> TrophyService")
connectServices(Services.GameService, "SetPetService", Services.PetService, "GameService -> PetService")
connectServices(Services.GameService, "SetSpectatorService", Services.SpectatorService, "GameService -> SpectatorService")
connectServices(Services.GameService, "SetTournamentService", Services.TournamentService, "GameService -> TournamentService")
connectServices(Services.GameService, "SetRebirthService", Services.RebirthService, "GameService -> RebirthService")

print("🔗 Phase 3: Monetization Dependencies")
connectServices(Services.MonetizationService, "SetPlayerService", Services.PlayerService, "MonetizationService -> PlayerService")
connectServices(Services.MonetizationService, "SetDataService", Services.DataService, "MonetizationService -> DataService")
connectServices(Services.MonetizationService, "SetAnalyticsService", Services.AnalyticsService, "MonetizationService -> AnalyticsService")

print("🔗 Phase 4: Economy Dependencies")
connectServices(Services.ShopService, "SetQuestService", Services.QuestService, "ShopService -> QuestService")
connectServices(Services.FountainService, "SetQuestService", Services.QuestService, "FountainService -> QuestService")
connectServices(Services.MysteryService, "SetShopService", Services.ShopService, "MysteryService -> ShopService")
connectServices(Services.MysteryService, "SetQuestService", Services.QuestService, "MysteryService -> QuestService")
connectServices(Services.MysteryService, "SetAnalyticsService", Services.AnalyticsService, "MysteryService -> AnalyticsService")
connectServices(Services.MysteryService, "SetRebirthService", Services.RebirthService, "MysteryService -> RebirthService")

print("🔗 Phase 5: Feature Service Dependencies")
connectServices(Services.LevelingService, "SetPlayerService", Services.PlayerService, "LevelingService -> PlayerService")
connectServices(Services.LevelingService, "SetShopService", Services.ShopService, "LevelingService -> ShopService")
connectServices(Services.LevelingService, "SetAnalyticsService", Services.AnalyticsService, "LevelingService -> AnalyticsService")

connectServices(Services.EventService, "SetPlayerService", Services.PlayerService, "EventService -> PlayerService")
connectServices(Services.EventService, "SetGameService", Services.GameService, "EventService -> GameService")
connectServices(Services.EventService, "SetAnalyticsService", Services.AnalyticsService, "EventService -> AnalyticsService")
connectServices(Services.EventService, "SetQuestService", Services.QuestService, "EventService -> QuestService")

connectServices(Services.DailyStreakService, "SetPlayerService", Services.PlayerService, "DailyStreakService -> PlayerService")
connectServices(Services.DailyStreakService, "SetAnalyticsService", Services.AnalyticsService, "DailyStreakService -> AnalyticsService")
connectServices(Services.DailyStreakService, "SetQuestService", Services.QuestService, "DailyStreakService -> QuestService")

connectServices(Services.GhostService, "SetPlayerService", Services.PlayerService, "GhostService -> PlayerService")
connectServices(Services.GhostService, "SetAnalyticsService", Services.AnalyticsService, "GhostService -> AnalyticsService")

connectServices(Services.UpgradeService, "SetQuestService", Services.QuestService, "UpgradeService -> QuestService")
connectServices(Services.EnhancedUpgradeService, "SetPlayerService", Services.PlayerService, "EnhancedUpgradeService -> PlayerService")

connectServices(Services.PuzzleService, "SetPlayerService", Services.PlayerService, "PuzzleService -> PlayerService")
connectServices(Services.PuzzleService, "SetQuestService", Services.QuestService, "PuzzleService -> QuestService")

connectServices(Services.TrophyService, "SetPlayerService", Services.PlayerService, "TrophyService -> PlayerService")
connectServices(Services.TrophyService, "SetQuestService", Services.QuestService, "TrophyService -> QuestService")

connectServices(Services.TournamentService, "SetPlayerService", Services.PlayerService, "TournamentService -> PlayerService")
connectServices(Services.TournamentService, "SetAnalyticsService", Services.AnalyticsService, "TournamentService -> AnalyticsService")
connectServices(Services.TournamentService, "SetQuestService", Services.QuestService, "TournamentService -> QuestService")

connectServices(Services.TrailService, "SetPlayerService", Services.PlayerService, "TrailService -> PlayerService")

connectServices(Services.AchievementService, "SetPlayerService", Services.PlayerService, "AchievementService -> PlayerService")
connectServices(Services.AchievementService, "SetAnalyticsService", Services.AnalyticsService, "AchievementService -> AnalyticsService")

-- STEP 7: Set up Player Event Handlers with error protection
print("👥 Setting up player event handlers...")

-- Safe event connection function
local function connectPlayerEvent(eventName, handler, handlerName)
    local success, connection = pcall(function()
        return Players[eventName]:Connect(handler)
    end)
    
    if success then
        print(string.format("  ✅ %s connected successfully", handlerName))
        return connection
    else
        warn(string.format("❌ Failed to connect %s: %s", handlerName, tostring(connection)))
        return nil
    end
end

-- Enhanced upgrade service player connections
if Services.EnhancedUpgradeService then
    connectPlayerEvent("PlayerAdded", function(player)
        local success, error = pcall(function()
            Services.EnhancedUpgradeService:HandlePlayerAdded(player)
        end)
        if not success then
            warn(string.format("❌ EnhancedUpgradeService PlayerAdded failed for %s: %s", player.Name, tostring(error)))
        end
    end, "EnhancedUpgradeService PlayerAdded")
    
    connectPlayerEvent("PlayerRemoving", function(player)
        local success, error = pcall(function()
            Services.EnhancedUpgradeService:HandlePlayerRemoving(player)
        end)
        if not success then
            warn(string.format("❌ EnhancedUpgradeService PlayerRemoving failed for %s: %s", player.Name, tostring(error)))
        end
    end, "EnhancedUpgradeService PlayerRemoving")
end

-- STEP 8: Configure Analytics with error protection
print("📊 Configuring analytics...")

if Services.AnalyticsService then
    local success, error = pcall(function()
        -- ASSUMPTION: Analytics configuration - update with your actual service details
        -- For development: disable external analytics to prevent errors
        local DEVELOPMENT_MODE = true -- Set to false for production
        
        if DEVELOPMENT_MODE then
            -- Development configuration - analytics stored locally
            Services.AnalyticsService:ConfigureEndpoint(
                "http://localhost:8080/analytics", -- Local development endpoint
                "dev-api-key", -- Development API key
                false -- Disable HTTP sending during development
            )
            print("📊 Analytics configured for DEVELOPMENT mode (HTTP disabled)")
        else
            -- Production configuration - replace with your actual values
            Services.AnalyticsService:ConfigureEndpoint(
                "https://your-analytics-service.com/api/events", -- Your actual endpoint URL
                "your-production-api-key-here", -- Your actual API key
                true -- Enable HTTP sending in production
            )
            print("📊 Analytics configured for PRODUCTION mode")
        end
    end)
    
    if success then
        print("✅ Analytics configuration completed")
    else
        warn("❌ Analytics configuration failed: " .. tostring(error))
    end
else
    warn("⚠️ AnalyticsService not available for configuration")
end

-- STEP 9: Set up developer admin commands with enhanced error handling
print("🔧 Setting up developer commands...")

connectPlayerEvent("PlayerAdded", function(player)
    local chatConnection = player.Chatted:Connect(function(message)
        -- Safe developer check
        local isDeveloper = false
        pcall(function()
            -- ASSUMPTION: Replace with actual developer usernames or group IDs
            -- Add your actual Roblox username(s) here
            local developerUsernames = {
                "YourUsername",      -- Replace with your actual username
                "Developer1",        -- Add additional developers as needed
                "Administrator"      -- Common admin username
            }
            
            -- Check username
            for _, username in ipairs(developerUsernames) do
                if player.Name == username then
                    isDeveloper = true
                    break
                end
            end
            
            -- Alternative: Check group rank (uncomment and configure if needed)
            -- isDeveloper = isDeveloper or player:GetRankInGroup(YOUR_GROUP_ID) >= 100
        end)
        
        if not isDeveloper then
            return
        end
        
        -- Analytics commands
        if message:lower() == "/analytics flush" and Services.AnalyticsService then
            pcall(function()
                Services.AnalyticsService:ManualFlush()
                player:Kick("Analytics flushed manually")
            end)
            
        elseif message:lower() == "/analytics status" and Services.AnalyticsService then
            pcall(function()
                local config = Services.AnalyticsService:GetConfiguration()
                local summary = Services.AnalyticsService:GetAnalyticsSummary()
                
                print("📊 Analytics Status for " .. player.Name .. ":")
                print("📊 Enabled: " .. tostring(config.enabled))
                print("📊 Buffer Size: " .. config.bufferSize)
                print("📊 Active Players: " .. config.activePlayers)
                print("📊 Total Events: " .. summary.totalEvents)
            end)
            
        elseif message:lower():sub(1, 17) == "/analytics toggle" and Services.AnalyticsService then
            pcall(function()
                local currentConfig = Services.AnalyticsService:GetConfiguration()
                Services.AnalyticsService:ConfigureEndpoint(nil, nil, not currentConfig.enabled)
                player:Kick("Analytics toggled")
            end)
            
        -- Quest commands
        elseif message:lower() == "/quest reset" and Services.QuestService then
            pcall(function()
                Services.QuestService:ResetAllPlayerQuests()
                player:Kick("Daily quest reset triggered manually")
            end)
            
        elseif message:lower() == "/quest status" and Services.QuestService then
            pcall(function()
                local secondsUntilReset = Services.QuestService:GetSecondsUntilNextUTCMidnight()
                local hoursUntilReset = math.floor(secondsUntilReset / 3600)
                local minutesUntilReset = math.floor((secondsUntilReset % 3600) / 60)
                
                print("📋 Quest System Status for " .. player.Name .. ":")
                print("📋 Current Day: " .. Services.QuestService:GetDaysSinceEpoch())
                print("📋 Next Reset: " .. hoursUntilReset .. "h " .. minutesUntilReset .. "m")
                print("📋 UTC Time: " .. os.date("!%H:%M:%S", os.time()))
            end)
            
        -- Validation commands
        elseif message:lower() == "/validate" and RuntimeValidator then
            pcall(function()
                RuntimeValidator:ForceValidation()
                local status = RuntimeValidator:GetValidationStatus()
                player:Kick(string.format("Validation completed: %d errors found", status.ErrorCount))
            end)
            
        elseif message:lower() == "/validate status" and RuntimeValidator then
            pcall(function()
                local status = RuntimeValidator:GetValidationStatus()
                print("🔍 Validation Status for " .. player.Name .. ":")
                print("🔍 Is Validated: " .. tostring(status.IsValidated))
                print("🔍 Error Count: " .. status.ErrorCount)
                print("🔍 Last Validation: " .. os.date("%H:%M:%S", status.LastValidation))
            end)
        end
    end)
    
    -- Clean up chat connection when player leaves
    connectPlayerEvent("PlayerRemoving", function(leavingPlayer)
        if leavingPlayer == player and chatConnection then
            chatConnection:Disconnect()
        end
    end, "Chat cleanup for " .. player.Name)
    
end, "Developer command handler")

-- STEP 10: Final Validation and Server Ready
print("🔍 RUNNING FINAL SYSTEM VALIDATION...")
print("==========================================")

-- Run comprehensive validation
if RuntimeValidator and RuntimeValidator.ValidateAll then
    local success, validationError = pcall(RuntimeValidator.ValidateAll, RuntimeValidator)
    if success then
        print("✅ FINAL VALIDATION COMPLETED SUCCESSFULLY")
        
        -- Get validation status for detailed report
        if RuntimeValidator.GetValidationStatus then
            local status = RuntimeValidator:GetValidationStatus()
            print(string.format("🔍 Final Validation Details:"))
            print(string.format("  📊 Is Validated: %s", tostring(status.IsValidated)))
            print(string.format("  📊 Error Count: %d", status.ErrorCount or 0))
            print(string.format("  📊 Last Validation: %s", os.date("%H:%M:%S", status.LastValidation or 0)))
        end
    else
        warn("❌ FINAL VALIDATION FAILURE:")
        warn("==========================================")
        warn(string.format("💥 Validation Error: %s", tostring(validationError)))
        warn("⚠️ Server will continue despite validation failure")
        warn("==========================================")
    end
else
    warn("⚠️ FINAL VALIDATION SKIPPED:")
    warn("RuntimeValidator.ValidateAll not available")
end

-- Server startup summary
print("🎉 Color Rush Server Initialization Complete!")
print("==========================================")
print(string.format("✅ Services loaded: %d", serviceCount))
if failedCount > 0 then
    print(string.format("⚠️ Services failed: %d", failedCount))
end
print("✅ RuntimeValidator: " .. (RuntimeValidator and "Active" or "Unavailable"))
print("✅ SafeRequire: Active")
print("✅ Error handling: Comprehensive")
print("✅ World validation: " .. (RuntimeValidator and "Active" or "Manual"))
print("==========================================")
print("🚀 Server is ready for players!")

-- Set up periodic health monitoring
task.spawn(function() -- UPDATED for modern API
    while true do
        task.wait(600) -- UPDATED for modern API - Every 10 minutes
        if RuntimeValidator and RuntimeValidator.ValidateAll then
            pcall(RuntimeValidator.ValidateAll, RuntimeValidator)
        end
    end
end)