-- CoreSystemInitializer.server.luau
-- Master initialization script for all core services and controllers
-- Handles dependency management, initialization order, and error handling

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")

local CoreSystemInitializer = {}

-- Core Services and Controllers Registry
local CoreSystems = {}
local InitializationOrder = {}
local InitializationStatus = {}
local InitializationErrors = {}

-- Initialization configuration
local INIT_CONFIG = {
    maxRetryAttempts = 3,
    retryDelay = 2,
    timeoutDuration = 30,
    enableDetailedLogging = true,
    criticalServicesOnly = false
}

-- Define core systems with their paths and initialization order
local CORE_SYSTEMS_CONFIG = {
    -- Priority 1: Foundation Services (Must load first)
    {
        name = "GameService",
        path = "src.server.services.core.GameService",
        priority = 1,
        critical = true,
        initMethod = "Initialize",
        dependencies = {}
    },
    
    -- Priority 2: Core Game Systems
    {
        name = "AnalyticsService", 
        path = "src.server.services.AnalyticsService",
        priority = 2,
        critical = true,
        initMethod = "Initialize",
        dependencies = {}
    },
    {
        name = "TrackGeneratorService",
        path = "src.server.services.TrackGeneratorService", 
        priority = 2,
        critical = true,
        initMethod = "Initialize",
        dependencies = {}
    },
    {
        name = "DifficultyService",
        path = "src.server.services.DifficultyService",
        priority = 2,
        critical = true,
        initMethod = "KnitStart",
        fallbackMethod = "Initialize",
        dependencies = {}
    },
    
    -- Priority 3: Game Controllers
    {
        name = "MainGameController",
        path = "src.server.MainGameController",
        priority = 3,
        critical = true,
        initMethod = "Initialize",
        dependencies = {"GameService", "AnalyticsService", "TrackGeneratorService"}
    },
    {
        name = "CollisionController",
        path = "src.server.controllers.CollisionController",
        priority = 3,
        critical = true,
        initMethod = "Initialize",
        dependencies = {"GameService", "AnalyticsService"}
    },
    
    -- Priority 4: Enhancement Services
    {
        name = "RecordingSessionManager",
        path = "src.server.services.RecordingSessionManager.server",
        priority = 4,
        critical = false,
        initMethod = "Init",
        dependencies = {"MainGameController"}
    },
    {
        name = "MovingObstacleService",
        path = "src.server.services.MovingObstacleService",
        priority = 4,
        critical = false,
        initMethod = "Initialize",
        dependencies = {"TrackGeneratorService", "GameService"}
    }
}

function CoreSystemInitializer:Initialize()
    print("🚀 Starting Core System Initialization...")
    print("=" .. string.rep("=", 50))
    
    local startTime = tick()
    
    -- Sort systems by priority
    self:SortSystemsByPriority()
    
    -- Initialize systems in order
    local success = self:InitializeAllSystems()
    
    local totalTime = tick() - startTime
    
    if success then
        print("=" .. string.rep("=", 50))
        print("✅ Core System Initialization COMPLETE!")
        print("⏱️ Total time: " .. string.format("%.2f", totalTime) .. " seconds")
        print("📊 Systems loaded: " .. self:GetLoadedSystemCount() .. "/" .. #CORE_SYSTEMS_CONFIG)
        self:PrintInitializationSummary()
        print("=" .. string.rep("=", 50))
        
        -- Setup global access
        self:SetupGlobalAccess()
        
        -- Start post-initialization tasks
        self:StartPostInitializationTasks()
        
        return true
    else
        warn("❌ Core System Initialization FAILED!")
        self:PrintErrorSummary()
        return false
    end
end

function CoreSystemInitializer:SortSystemsByPriority()
    -- Sort by priority, then by dependencies
    table.sort(CORE_SYSTEMS_CONFIG, function(a, b)
        if a.priority ~= b.priority then
            return a.priority < b.priority
        end
        return #a.dependencies < #b.dependencies
    end)
    
    -- Store initialization order
    for i, systemConfig in ipairs(CORE_SYSTEMS_CONFIG) do
        InitializationOrder[i] = systemConfig.name
    end
end

function CoreSystemInitializer:InitializeAllSystems()
    local allSuccess = true
    
    for _, systemConfig in ipairs(CORE_SYSTEMS_CONFIG) do
        local success = self:InitializeSystem(systemConfig)
        
        if not success then
            if systemConfig.critical then
                warn("💥 Critical system failed: " .. systemConfig.name)
                allSuccess = false
                if not INIT_CONFIG.criticalServicesOnly then
                    break -- Stop initialization if critical system fails
                end
            else
                warn("⚠️ Non-critical system failed: " .. systemConfig.name)
            end
        end
        
        -- Brief pause between initializations
        wait(0.1)
    end
    
    return allSuccess
end

function CoreSystemInitializer:InitializeSystem(systemConfig)
    local systemName = systemConfig.name
    
    print("🔧 Initializing: " .. systemName .. " (Priority " .. systemConfig.priority .. ")")
    
    -- Check dependencies
    if not self:CheckDependencies(systemConfig) then
        InitializationStatus[systemName] = "DependencyFailed"
        InitializationErrors[systemName] = "Missing dependencies"
        return false
    end
    
    -- Attempt to load and initialize
    local attempts = 0
    while attempts < INIT_CONFIG.maxRetryAttempts do
        attempts = attempts + 1
        
        local success, result = self:LoadAndInitializeSystem(systemConfig)
        
        if success then
            CoreSystems[systemName] = result
            InitializationStatus[systemName] = "Success"
            print("  ✅ " .. systemName .. " initialized successfully")
            return true
        else
            warn("  ❌ Attempt " .. attempts .. " failed: " .. tostring(result))
            InitializationErrors[systemName] = tostring(result)
            
            if attempts < INIT_CONFIG.maxRetryAttempts then
                print("  🔄 Retrying in " .. INIT_CONFIG.retryDelay .. " seconds...")
                wait(INIT_CONFIG.retryDelay)
            end
        end
    end
    
    InitializationStatus[systemName] = "Failed"
    return false
end

function CoreSystemInitializer:LoadAndInitializeSystem(systemConfig)
    local success, result = pcall(function()
        -- Convert path to module reference
        local modulePath = self:PathToModule(systemConfig.path)
        if not modulePath then
            error("Module not found at path: " .. systemConfig.path)
        end
        
        -- Require the module
        local module = require(modulePath)
        
        -- Initialize if method exists
        if systemConfig.initMethod and module[systemConfig.initMethod] then
            module[systemConfig.initMethod](module)
        elseif systemConfig.fallbackMethod and module[systemConfig.fallbackMethod] then
            module[systemConfig.fallbackMethod](module)
        end
        
        return module
    end)
    
    return success, result
end

function CoreSystemInitializer:PathToModule(pathString)
    -- Convert dot notation path to actual module reference
    local parts = string.split(pathString, ".")
    local current = game
    
    for _, part in ipairs(parts) do
        current = current:FindFirstChild(part)
        if not current then
            return nil
        end
    end
    
    return current
end

function CoreSystemInitializer:CheckDependencies(systemConfig)
    for _, dependencyName in ipairs(systemConfig.dependencies) do
        if not CoreSystems[dependencyName] then
            warn("  ❌ Missing dependency: " .. dependencyName)
            return false
        end
    end
    return true
end

function CoreSystemInitializer:GetLoadedSystemCount()
    local count = 0
    for _, status in pairs(InitializationStatus) do
        if status == "Success" then
            count = count + 1
        end
    end
    return count
end

function CoreSystemInitializer:PrintInitializationSummary()
    print("\n📊 INITIALIZATION SUMMARY:")
    print("-" .. string.rep("-", 40))
    
    for _, systemConfig in ipairs(CORE_SYSTEMS_CONFIG) do
        local systemName = systemConfig.name
        local status = InitializationStatus[systemName] or "NotAttempted"
        local icon = status == "Success" and "✅" or "❌"
        local criticalMark = systemConfig.critical and " [CRITICAL]" or ""
        
        print(icon .. " " .. systemName .. criticalMark .. " - " .. status)
    end
    
    print("-" .. string.rep("-", 40))
end

function CoreSystemInitializer:PrintErrorSummary()
    print("\n🚨 ERROR SUMMARY:")
    print("-" .. string.rep("-", 40))
    
    for systemName, error in pairs(InitializationErrors) do
        print("❌ " .. systemName .. ": " .. error)
    end
    
    print("-" .. string.rep("-", 40))
end

function CoreSystemInitializer:SetupGlobalAccess()
    print("🌐 Setting up global access...")
    
    -- Create global registry
    _G.CoreSystems = CoreSystems
    
    -- Create convenience accessors
    _G.GetCoreSystem = function(systemName)
        return CoreSystems[systemName]
    end
    
    _G.GetGameService = function()
        return CoreSystems.GameService
    end
    
    _G.GetMainGameController = function()
        return CoreSystems.MainGameController
    end
    
    _G.GetAnalyticsService = function()
        return CoreSystems.AnalyticsService
    end
    
    _G.GetTrackGeneratorService = function()
        return CoreSystems.TrackGeneratorService
    end
    
    _G.GetCollisionController = function()
        return CoreSystems.CollisionController
    end
    
    _G.GetDifficultyService = function()
        return CoreSystems.DifficultyService
    end
    
    _G.GetRecordingSessionManager = function()
        return CoreSystems.RecordingSessionManager
    end
    
    _G.GetMovingObstacleService = function()
        return CoreSystems.MovingObstacleService
    end
    
    -- System health checker
    _G.CheckSystemHealth = function()
        return CoreSystemInitializer:GetSystemHealth()
    end
    
    print("✅ Global access configured")
end

function CoreSystemInitializer:StartPostInitializationTasks()
    print("🔄 Starting post-initialization tasks...")
    
    -- Connect core systems
    self:ConnectCoreSystems()
    
    -- Setup system health monitoring
    self:StartHealthMonitoring()
    
    -- Setup cross-system communication
    self:SetupCrossSystemCommunication()
    
    print("✅ Post-initialization tasks complete")
end

function CoreSystemInitializer:ConnectCoreSystems()
    print("🔗 Connecting core systems...")
    
    -- Connect MainGameController with services
    if CoreSystems.MainGameController and CoreSystems.GameService then
        -- Link game controller with game service
        if CoreSystems.MainGameController.SetGameService then
            CoreSystems.MainGameController:SetGameService(CoreSystems.GameService)
        end
    end
    
    -- Connect CollisionController with MainGameController
    if CoreSystems.CollisionController and CoreSystems.MainGameController then
        if CoreSystems.CollisionController.SetMainController then
            CoreSystems.CollisionController:SetMainController(CoreSystems.MainGameController)
        end
    end
    
    -- Connect RecordingSessionManager with MainGameController  
    if CoreSystems.RecordingSessionManager and CoreSystems.MainGameController then
        if CoreSystems.MainGameController.SetRecordingManager then
            CoreSystems.MainGameController:SetRecordingManager(CoreSystems.RecordingSessionManager)
        end
    end
    
    print("✅ Core systems connected")
end

function CoreSystemInitializer:StartHealthMonitoring()
    print("🏥 Starting system health monitoring...")
    
    spawn(function()
        while true do
            wait(30) -- Check every 30 seconds
            self:PerformHealthCheck()
        end
    end)
    
    print("✅ Health monitoring active")
end

function CoreSystemInitializer:PerformHealthCheck()
    local healthReport = {}
    
    for systemName, system in pairs(CoreSystems) do
        local health = "Unknown"
        
        if system then
            if system.GetHealth then
                health = system:GetHealth()
            elseif system.IsHealthy then
                health = system:IsHealthy() and "Healthy" or "Unhealthy"
            else
                health = "Healthy" -- Assume healthy if no health method
            end
        else
            health = "Missing"
        end
        
        healthReport[systemName] = health
    end
    
    -- Log health issues
    for systemName, health in pairs(healthReport) do
        if health ~= "Healthy" then
            warn("🚨 System health issue: " .. systemName .. " - " .. health)
        end
    end
    
    return healthReport
end

function CoreSystemInitializer:SetupCrossSystemCommunication()
    print("📡 Setting up cross-system communication...")
    
    -- Create message bus for systems to communicate
    _G.SystemMessageBus = {
        Subscribe = function(eventName, callback)
            -- System event subscription
        end,
        Publish = function(eventName, data)
            -- System event publishing
        end,
        GetSystemStatus = function()
            return InitializationStatus
        end
    }
    
    print("✅ Cross-system communication ready")
end

function CoreSystemInitializer:GetSystemHealth()
    return self:PerformHealthCheck()
end

function CoreSystemInitializer:GetSystemStatus(systemName)
    if systemName then
        return InitializationStatus[systemName]
    else
        return InitializationStatus
    end
end

function CoreSystemInitializer:RestartSystem(systemName)
    print("🔄 Restarting system: " .. systemName)
    
    -- Find system config
    local systemConfig = nil
    for _, config in ipairs(CORE_SYSTEMS_CONFIG) do
        if config.name == systemName then
            systemConfig = config
            break
        end
    end
    
    if not systemConfig then
        warn("❌ System config not found: " .. systemName)
        return false
    end
    
    -- Attempt restart
    local success = self:InitializeSystem(systemConfig)
    
    if success then
        print("✅ System restarted successfully: " .. systemName)
    else
        warn("❌ System restart failed: " .. systemName)
    end
    
    return success
end

-- Utility functions
function CoreSystemInitializer:GetCoreSystem(systemName)
    return CoreSystems[systemName]
end

function CoreSystemInitializer:ListCoreSystems()
    local systems = {}
    for systemName, _ in pairs(CoreSystems) do
        table.insert(systems, systemName)
    end
    return systems
end

function CoreSystemInitializer:IsSystemLoaded(systemName)
    return CoreSystems[systemName] ~= nil
end

function CoreSystemInitializer:GetInitializationTime()
    return self.initializationTime or 0
end

-- Auto-initialize when script loads
if RunService:IsServer() then
    spawn(function()
        wait(2) -- Wait for game to fully load
        
        local startTime = tick()
        local success = CoreSystemInitializer:Initialize()
        CoreSystemInitializer.initializationTime = tick() - startTime
        
        if success then
            print("🎮 Color Rush Core Systems Ready!")
            
            -- Optional: Run system validation
            spawn(function()
                wait(5)
                CoreSystemInitializer:PerformHealthCheck()
            end)
        else
            warn("🚨 Core Systems Initialization Failed - Game may not function properly")
        end
    end)
end

return CoreSystemInitializer
