-- EnhancedMainGameServiceIntegration.server.luau
-- Integration script to properly register the Enhanced MainGameService with the core systems
-- This ensures compatibility with existing InitializeCoreServices while providing enhanced features

local RunService = game:GetService("RunService")

print("🔗 Integrating Enhanced MainGameService with Core Systems...")

-- Wait for core services to be available
local function waitForCoreServices()
    local attempts = 0
    local maxAttempts = 30 -- 30 seconds timeout
    
    while attempts < maxAttempts do
        if _G.GetCoreService and _G.RegisterCoreService then
            return true
        end
        wait(1)
        attempts = attempts + 1
    end
    
    return false
end

-- Integration function
local function integrateMainGameService()
    -- Wait for core services system to be ready
    if not waitForCoreServices() then
        warn("❌ Core services system not available - proceeding without integration")
        return
    end
    
    -- Wait for MainGameService to be initialized
    local MainGameService = nil
    local attempts = 0
    
    while attempts < 30 do -- 30 second timeout
        local success, service = pcall(function()
            return require(script.Parent.services.MainGameService)
        end)
        
        if success and service and service.IsInitialized and service:IsInitialized() then
            MainGameService = service
            break
        end
        
        wait(1)
        attempts = attempts + 1
    end
    
    if not MainGameService then
        warn("❌ Enhanced MainGameService not available for integration")
        return
    end
    
    print("✅ Enhanced MainGameService found and initialized")
    
    -- Register with core services system
    _G.RegisterCoreService("MainGameService", MainGameService)
    print("📍 MainGameService registered with core services")
    
    -- Add enhanced service access functions
    _G.GetMainGameService = function()
        return MainGameService
    end
    
    _G.GetGameState = function()
        return MainGameService:GetCurrentState()
    end
    
    _G.StartNewGame = function(player, config)
        return MainGameService:StartGame(player, config)
    end
    
    _G.EndCurrentGame = function(player, results)
        return MainGameService:EndGame(player, results)
    end
    
    _G.ValidateGameSystems = function()
        return MainGameService:ValidateSystemIntegrity()
    end
    
    _G.RepairGameSystems = function()
        return MainGameService:ValidateAndRepairSystem()
    end
    
    print("🎮 Enhanced MainGameService global functions registered:")
    print("  • _G.GetMainGameService()")
    print("  • _G.GetGameState()")
    print("  • _G.StartNewGame(player, config)")
    print("  • _G.EndCurrentGame(player, results)")
    print("  • _G.ValidateGameSystems()")
    print("  • _G.RepairGameSystems()")
    
    -- Integrate with existing service health monitoring
    if _G.GetCoreServiceStatus then
        local originalGetStatus = _G.GetCoreServiceStatus
        
        _G.GetCoreServiceStatus = function()
            local status = originalGetStatus()
            
            -- Add MainGameService specific status
            status.MainGameService = {
                loaded = MainGameService ~= nil,
                initialized = MainGameService and MainGameService:IsInitialized() or false,
                started = MainGameService and MainGameService:IsStarted() or false,
                state = MainGameService and MainGameService:GetCurrentState() or "Unknown",
                activeGames = MainGameService and #MainGameService:GetActiveGames() or 0
            }
            
            -- Add system integrity status
            if MainGameService and MainGameService.ValidateSystemIntegrity then
                local integrity = MainGameService:ValidateSystemIntegrity()
                status.SystemIntegrity = {
                    overall = integrity.overall,
                    worldObjects = integrity.worldObjects.valid,
                    services = integrity.services.valid,
                    configuration = integrity.configuration.valid
                }
            end
            
            return status
        end
    end
    
    print("✅ Enhanced MainGameService integration complete!")
    
    -- Final validation
    spawn(function()
        wait(2)
        print("🔍 Running post-integration validation...")
        
        local integrity = MainGameService:ValidateSystemIntegrity()
        if integrity.overall then
            print("✅ All systems validated and operational")
        else
            warn("⚠️ Some system issues detected - check logs")
        end
    end)
end

-- Start integration
if RunService:IsServer() then
    spawn(integrateMainGameService)
end
