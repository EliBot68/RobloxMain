-- ControllerRegistry.luau
-- Centralized registry for all standardized client controllers

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SafeRequire = require(ReplicatedStorage.Shared.utils.SafeRequire)

local ControllerRegistry = {}

-- Controller definitions with metadata
ControllerRegistry.Controllers = {
    -- Core Controllers (Critical)
    GameController = {
        path = script.Parent.Parent.client.controllers.core.GameController,
        category = "core",
        critical = true,
        autoStart = true
    },
    InputController = {
        path = script.Parent.Parent.client.controllers.InputController,
        category = "core",
        critical = true,
        autoStart = true
    },
    GuiController = {
        path = script.Parent.Parent.client.controllers.GuiController,
        category = "core",
        critical = true,
        autoStart = true
    },
    
    -- UI Controllers
    EnhancedUIController = {
        path = script.Parent.Parent.client.controllers.ui.EnhancedUIController,
        category = "ui",
        critical = false,
        autoStart = true
    },
    MobileUIController = {
        path = script.Parent.Parent.client.controllers.MobileUIController,
        category = "ui",
        critical = false,
        autoStart = true
    },
    
    -- Feature Controllers
    HubNavigationController = {
        path = script.Parent.Parent.client.controllers.HubNavigationController,
        category = "features",
        critical = false,
        autoStart = true
    },
    PlayerController = {
        path = script.Parent.Parent.client.controllers.PlayerController,
        category = "features",
        critical = true,
        autoStart = true
    },
    
    -- Enhancement Controllers
    PartyController = {
        path = script.Parent.Parent.client.controllers.PartyController,
        category = "enhancement",
        critical = false,
        autoStart = false
    },
    TutorialController = {
        path = script.Parent.Parent.client.controllers.TutorialController,
        category = "enhancement",
        critical = false,
        autoStart = true
    },
    
    -- Social Controllers
    SocialController = {
        path = script.Parent.Parent.client.controllers.SocialController,
        category = "social",
        critical = false,
        autoStart = true
    },
    LeaderboardController = {
        path = script.Parent.Parent.client.controllers.LeaderboardController,
        category = "social",
        critical = false,
        autoStart = true
    },
    SocialEngagementController = {
        path = script.Parent.Parent.client.controllers.SocialEngagementController,
        category = "social",
        critical = false,
        autoStart = true
    },
    
    -- Achievement Controllers
    AchievementController = {
        path = script.Parent.Parent.client.controllers.AchievementControllerComplete,
        category = "progression",
        critical = false,
        autoStart = true
    }
}

-- Loaded controllers cache
ControllerRegistry.LoadedControllers = {}

-- Load a controller by name using SafeRequire
function ControllerRegistry:LoadController(controllerName)
    if self.LoadedControllers[controllerName] then
        return self.LoadedControllers[controllerName]
    end
    
    local controllerConfig = self.Controllers[controllerName]
    if not controllerConfig then
        warn(string.format("❌ ControllerRegistry: Unknown controller '%s'", controllerName))
        return nil
    end
    
    local controller = SafeRequire.requireWithRetry(
        controllerConfig.path,
        controllerConfig.critical and 3 or 1
    )
    
    if controller then
        self.LoadedControllers[controllerName] = controller
        print(string.format("✅ ControllerRegistry: Loaded %s", controllerName))
        return controller
    else
        if controllerConfig.critical then
            error(string.format("❌ ControllerRegistry: Critical controller '%s' failed to load", controllerName))
        else
            warn(string.format("⚠️ ControllerRegistry: Optional controller '%s' failed to load", controllerName))
        end
        return nil
    end
end

-- Initialize all controllers in dependency order
function ControllerRegistry:InitializeAll()
    print("🔧 ControllerRegistry: Initializing all controllers...")
    
    local categories = {"core", "ui", "features", "enhancement"}
    local initializedCount = 0
    local failedControllers = {}
    
    for _, category in ipairs(categories) do
        print(string.format("📦 Initializing %s controllers...", category))
        
        for controllerName, config in pairs(self.Controllers) do
            if config.category == category then
                local controller = self:LoadController(controllerName)
                
                if controller and controller.Init then
                    local success = pcall(function()
                        controller:Init()
                    end)
                    
                    if success then
                        initializedCount = initializedCount + 1
                        print(string.format("  ✅ %s initialized", controllerName))
                    else
                        table.insert(failedControllers, controllerName)
                        if config.critical then
                            error(string.format("❌ Critical controller %s failed to initialize", controllerName))
                        else
                            warn(string.format("⚠️ Optional controller %s failed to initialize", controllerName))
                        end
                    end
                end
            end
        end
    end
    
    print(string.format("✅ ControllerRegistry: Initialized %d controllers", initializedCount))
    if #failedControllers > 0 then
        warn(string.format("⚠️ ControllerRegistry: %d controllers failed: %s", #failedControllers, table.concat(failedControllers, ", ")))
    end
    
    return initializedCount, failedControllers
end

-- Start all auto-start controllers
function ControllerRegistry:StartAll()
    print("🚀 ControllerRegistry: Starting auto-start controllers...")
    
    local startedCount = 0
    
    for controllerName, config in pairs(self.Controllers) do
        if config.autoStart then
            local controller = self.LoadedControllers[controllerName]
            
            if controller and controller.Start then
                local success = pcall(function()
                    controller:Start()
                end)
                
                if success then
                    startedCount = startedCount + 1
                    print(string.format("  ✅ %s started", controllerName))
                else
                    warn(string.format("⚠️ %s failed to start", controllerName))
                end
            end
        end
    end
    
    print(string.format("✅ ControllerRegistry: Started %d controllers", startedCount))
    return startedCount
end

-- Get controller by name
function ControllerRegistry:GetController(controllerName)
    return self.LoadedControllers[controllerName] or self:LoadController(controllerName)
end

-- Get controller status for all controllers
function ControllerRegistry:GetStatus()
    local status = {
        total = 0,
        loaded = 0,
        initialized = 0,
        started = 0,
        failed = 0,
        controllers = {}
    }
    
    for controllerName, config in pairs(self.Controllers) do
        status.total = status.total + 1
        local controller = self.LoadedControllers[controllerName]
        
        local controllerStatus = {
            name = controllerName,
            category = config.category,
            critical = config.critical,
            loaded = controller ~= nil,
            initialized = controller and controller.IsInitialized or false,
            started = controller and controller.IsStarted or false
        }
        
        if controllerStatus.loaded then status.loaded = status.loaded + 1 end
        if controllerStatus.initialized then status.initialized = status.initialized + 1 end
        if controllerStatus.started then status.started = status.started + 1 end
        
        status.controllers[controllerName] = controllerStatus
    end
    
    return status
end

return ControllerRegistry
