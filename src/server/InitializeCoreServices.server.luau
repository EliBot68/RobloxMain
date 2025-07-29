-- InitializeCoreServices.server.luau
-- Direct initialization of all core services and controllers
-- Place this in ServerScriptService for automatic-- 8. MovingObstacleService (Dynamic obstacles)
print("8/8 Loading MovingObstacleService...")
CoreServices.MovingObstacleService = SafeRequire(
    script.Parent.services.MovingObstacleService,
    "MovingObstacleService"
)
SafeInitialize(CoreServices.MovingObstacleService, "MovingObstacleService", "Initialize")

-- 9. SystemEventConnections (Event binding and connections)
print("9/9 Loading SystemEventConnections...")
CoreServices.SystemEventConnections = SafeRequire(
    script.Parent.SystemEventConnections,
    "SystemEventConnections"
)
-- Note: SystemEventConnections auto-initializes itself after all core services are loaded

totalServices = 9ion

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

print("🚀 Initializing Core Services and Controllers...")

-- ========================================
-- CORE SERVICES AND CONTROLLERS REGISTRY
-- ========================================

local CoreServices = {}
local loadedCount = 0
local totalServices = 11

-- ========================================
-- SERVICE LOADING FUNCTIONS
-- ========================================

local function SafeRequire(modulePath, serviceName)
    local success, result = pcall(function()
        return require(modulePath)
    end)
    
    if success then
        print("✅ " .. serviceName .. " loaded successfully")
        return result
    else
        warn("❌ Failed to load " .. serviceName .. ": " .. tostring(result))
        return nil
    end
end

local function SafeInitialize(service, serviceName, initMethod)
    initMethod = initMethod or "Initialize"
    
    if not service then
        warn("❌ Cannot initialize " .. serviceName .. " - service not loaded")
        return false
    end
    
    if service[initMethod] then
        local success, result = pcall(function()
            service[initMethod](service)
        end)
        
        if success then
            print("✅ " .. serviceName .. " initialized successfully")
            loadedCount = loadedCount + 1
            return true
        else
            warn("❌ Failed to initialize " .. serviceName .. ": " .. tostring(result))
            return false
        end
    else
        -- Some services don't need explicit initialization
        print("📋 " .. serviceName .. " loaded (no initialization method)")
        loadedCount = loadedCount + 1
        return true
    end
end

-- ========================================
-- LOAD CORE SERVICES
-- ========================================

print("\n🔧 Loading Core Services...")

-- 0. MemoryManager (Memory management utility) - Load First
print("0/8 Loading MemoryManager...")
local MemoryManager = SafeRequire(
    ReplicatedStorage.Shared.utilities.MemoryManager,
    "MemoryManager"
)
if MemoryManager then
    MemoryManager:Init()
    print("✅ MemoryManager initialized for system-wide memory management")
end

-- 1. GameService (Core game mechanics)
print("1/8 Loading GameService...")
CoreServices.GameService = SafeRequire(
    script.Parent.services.core.GameService,
    "GameService"
)
SafeInitialize(CoreServices.GameService, "GameService", "Initialize")

-- 2. AnalyticsService (Event tracking)
print("2/8 Loading AnalyticsService...")
CoreServices.AnalyticsService = SafeRequire(
    script.Parent.services.AnalyticsService,
    "AnalyticsService"
)
SafeInitialize(CoreServices.AnalyticsService, "AnalyticsService", "Initialize")

-- 3. TrackGeneratorService (Track creation)
print("3/8 Loading TrackGeneratorService...")
CoreServices.TrackGeneratorService = SafeRequire(
    script.Parent.services.TrackGeneratorService,
    "TrackGeneratorService"
)
SafeInitialize(CoreServices.TrackGeneratorService, "TrackGeneratorService", "Initialize")

-- 4. DifficultyService (Dynamic difficulty)
print("4/8 Loading DifficultyService...")
CoreServices.DifficultyService = SafeRequire(
    script.Parent.services.DifficultyService,
    "DifficultyService"
)
-- Try KnitStart first, then Initialize
if CoreServices.DifficultyService then
    if CoreServices.DifficultyService.KnitStart then
        SafeInitialize(CoreServices.DifficultyService, "DifficultyService", "KnitStart")
    else
        SafeInitialize(CoreServices.DifficultyService, "DifficultyService", "Initialize")
    end
end

-- ========================================
-- LOAD CONTROLLERS
-- ========================================

print("\n🎮 Loading Controllers...")

-- 5. MainGameController (Central game management)
print("5/8 Loading MainGameController...")
CoreServices.MainGameController = SafeRequire(
    script.Parent.MainGameController,
    "MainGameController"
)
SafeInitialize(CoreServices.MainGameController, "MainGameController", "Initialize")

-- 6. CollisionController (Collision detection)
print("6/8 Loading CollisionController...")
CoreServices.CollisionController = SafeRequire(
    script.Parent.controllers.CollisionController,
    "CollisionController"
)
SafeInitialize(CoreServices.CollisionController, "CollisionController", "Initialize")

-- ========================================
-- LOAD ENHANCEMENT SERVICES
-- ========================================

print("\n🌟 Loading Enhancement Services...")

-- 7. RecordingSessionManager (Recording management)
print("7/8 Loading RecordingSessionManager...")
local recordingPath = script.Parent.services:FindFirstChild("RecordingSessionManager.server") or
                     script.Parent.services:FindFirstChild("RecordingSessionManager")
if recordingPath then
    CoreServices.RecordingSessionManager = SafeRequire(
        recordingPath,
        "RecordingSessionManager"
    )
    SafeInitialize(CoreServices.RecordingSessionManager, "RecordingSessionManager", "Init")
else
    warn("⚠️ RecordingSessionManager not found")
end

-- 8. MovingObstacleService (Moving obstacles)
print("8/9 Loading MovingObstacleService...")
CoreServices.MovingObstacleService = SafeRequire(
    script.Parent.services.MovingObstacleService,
    "MovingObstacleService"
)
SafeInitialize(CoreServices.MovingObstacleService, "MovingObstacleService", "Initialize")

-- 9. SystemEventConnections (Event binding and connections)
print("9/10 Loading SystemEventConnections...")
CoreServices.SystemEventConnections = SafeRequire(
    script.Parent.SystemEventConnections,
    "SystemEventConnections"
)
-- Note: SystemEventConnections auto-initializes itself after all core services are loaded

-- 10. GameStateEventManager (Game state event management)
print("10/11 Loading GameStateEventManager...")
CoreServices.GameStateEventManager = SafeRequire(
    script.Parent.GameStateEventManager,
    "GameStateEventManager"
)
-- Note: GameStateEventManager auto-initializes itself after all other services are loaded

-- 11. GameLifecycleManager (Complete lifecycle management)
print("11/11 Loading GameLifecycleManager...")
CoreServices.GameLifecycleManager = SafeRequire(
    script.Parent.GameLifecycleManager,
    "GameLifecycleManager"
)
-- Note: GameLifecycleManager auto-initializes itself and manages the entire game lifecycle

totalServices = 11

-- ========================================
-- SETUP GLOBAL ACCESS
-- ========================================

print("\n🌐 Setting up Global Access...")

-- Make services globally accessible
_G.CoreServices = CoreServices

-- Individual service accessors
_G.GetGameService = function()
    return CoreServices.GameService
end

_G.GetAnalyticsService = function()
    return CoreServices.AnalyticsService
end

_G.GetTrackGeneratorService = function()
    return CoreServices.TrackGeneratorService
end

_G.GetDifficultyService = function()
    return CoreServices.DifficultyService
end

_G.GetMainGameController = function()
    return CoreServices.MainGameController
end

_G.GetCollisionController = function()
    return CoreServices.CollisionController
end

_G.GetRecordingSessionManager = function()
    return CoreServices.RecordingSessionManager
end

_G.GetMovingObstacleService = function()
    return CoreServices.MovingObstacleService
end

_G.GetSystemEventConnections = function()
    return CoreServices.SystemEventConnections
end

_G.GetGameStateEventManager = function()
    return CoreServices.GameStateEventManager
end

_G.GetGameLifecycleManager = function()
    return CoreServices.GameLifecycleManager
end

-- Utility functions
_G.GetCoreService = function(serviceName)
    return CoreServices[serviceName]
end

_G.ListCoreServices = function()
    local services = {}
    for name, service in pairs(CoreServices) do
        table.insert(services, name)
    end
    return services
end

_G.GetCoreServiceStatus = function()
    local status = {}
    for name, service in pairs(CoreServices) do
        status[name] = service ~= nil
    end
    return status
end

print("✅ Global access configured")

-- ========================================
-- CONNECT SYSTEMS
-- ========================================

print("\n🔗 Connecting Systems...")

-- Connect services that need references to each other
if CoreServices.MainGameController then
    -- Pass services to MainGameController
    if CoreServices.MainGameController.SetServices then
        CoreServices.MainGameController:SetServices({
            GameService = CoreServices.GameService,
            AnalyticsService = CoreServices.AnalyticsService,
            TrackGeneratorService = CoreServices.TrackGeneratorService,
            DifficultyService = CoreServices.DifficultyService,
            CollisionController = CoreServices.CollisionController,
            RecordingSessionManager = CoreServices.RecordingSessionManager,
            MovingObstacleService = CoreServices.MovingObstacleService
        })
    end
end

-- Connect CollisionController with MainGameController
if CoreServices.CollisionController and CoreServices.MainGameController then
    if CoreServices.CollisionController.SetMainController then
        CoreServices.CollisionController:SetMainController(CoreServices.MainGameController)
    end
end

print("✅ Systems connected")

-- ========================================
-- FINAL VALIDATION AND SUMMARY
-- ========================================

print("\n📊 Initialization Summary:")
print("=" .. string.rep("=", 50))
print("✅ Services loaded: " .. loadedCount .. "/" .. totalServices)

-- List loaded services
print("\n📋 Loaded Services:")
for name, service in pairs(CoreServices) do
    local status = service and "✅ LOADED" or "❌ FAILED"
    print("  " .. status .. " " .. name)
end

-- Check for critical failures
local criticalServices = {
    "GameService",
    "MainGameController", 
    "AnalyticsService",
    "TrackGeneratorService"
}

local criticalFailures = {}
for _, serviceName in ipairs(criticalServices) do
    if not CoreServices[serviceName] then
        table.insert(criticalFailures, serviceName)
    end
end

if #criticalFailures > 0 then
    warn("🚨 CRITICAL SERVICES FAILED:")
    for _, serviceName in ipairs(criticalFailures) do
        warn("  ❌ " .. serviceName)
    end
    warn("⚠️ Game may not function properly!")
else
    print("✅ All critical services loaded successfully")
end

print("=" .. string.rep("=", 50))

if loadedCount >= 6 then -- Allow for some optional services to fail
    print("🎮 Core Services Ready - Game can start!")
    
    -- Optional: Start a quick health check
    spawn(function()
        wait(5)
        print("🏥 Running post-initialization health check...")
        local healthyServices = 0
        for name, service in pairs(CoreServices) do
            if service then
                healthyServices = healthyServices + 1
            end
        end
        print("💚 Health check: " .. healthyServices .. "/" .. #CoreServices .. " services running")
    end)
else
    warn("❌ Insufficient services loaded - Game may not function!")
end

-- ========================================
-- PLAYER CONNECTION SETUP
-- ========================================

print("\n👥 Setting up Player Management...")

-- Ensure player events are connected to core services
Players.PlayerAdded:Connect(function(player)
    print("👋 Player joined: " .. player.Name)
    
    -- Notify core services about new player
    if CoreServices.GameService and CoreServices.GameService.OnPlayerAdded then
        CoreServices.GameService:OnPlayerAdded(player)
    end
    
    if CoreServices.MainGameController and CoreServices.MainGameController.OnPlayerAdded then
        CoreServices.MainGameController:OnPlayerAdded(player)
    end
    
    if CoreServices.AnalyticsService and CoreServices.AnalyticsService.TrackPlayerJoin then
        CoreServices.AnalyticsService:TrackPlayerJoin(player)
    end
end)

Players.PlayerRemoving:Connect(function(player)
    print("👋 Player leaving: " .. player.Name)
    
    -- Notify core services about player leaving
    if CoreServices.GameService and CoreServices.GameService.OnPlayerRemoving then
        CoreServices.GameService:OnPlayerRemoving(player)
    end
    
    if CoreServices.MainGameController and CoreServices.MainGameController.OnPlayerRemoving then
        CoreServices.MainGameController:OnPlayerRemoving(player)
    end
    
    if CoreServices.AnalyticsService and CoreServices.AnalyticsService.TrackPlayerLeave then
        CoreServices.AnalyticsService:TrackPlayerLeave(player)
    end
end)

print("✅ Player management configured")

print("\n🎉 CORE SERVICES INITIALIZATION COMPLETE!")
print("📍 Use _G.GetCoreService(name) to access services")
print("📍 Use _G.ListCoreServices() to see all loaded services")
print("📍 Use _G.GetCoreServiceStatus() to check service status")

return CoreServices
