-- init.client.luau
-- Main client initialization script for Color Rush
-- Handles robust startup of all client-side systems

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterGui = game:GetService("StarterGui")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- Wait for shared modules to load
local SafeRequire = require(ReplicatedStorage.Shared.utils.SafeRequire)
local ControllerRegistry = require(ReplicatedStorage.Shared.utils.ControllerRegistry)

print("[ClientInit] Starting Color Rush client initialization...")

-- Client initialization manager
local ClientInit = {}

-- Initialization phases
local PHASES = {
    CORE = 1,        -- Essential systems
    CONTROLLERS = 2,  -- Game controllers
    UI = 3,          -- User interface
    GAMEPLAY = 4,    -- Gameplay systems
    POLISH = 5       -- Effects and polish
}

-- Controller registration with priorities and phases
local CONTROLLER_CONFIG = {
    -- PHASE 1: CORE SYSTEMS (Priority 100+)
    {name = "InputController", path = ReplicatedStorage.Client.controllers.InputController, priority = 110, phase = PHASES.CORE},
    {name = "GuiController", path = ReplicatedStorage.Client.controllers.GuiController, priority = 105, phase = PHASES.CORE},
    {name = "SettingsController", path = ReplicatedStorage.Client.controllers.SettingsController, priority = 100, phase = PHASES.CORE},
    
    -- PHASE 2: MAIN CONTROLLERS (Priority 80-99)
    {name = "MainGameController", path = ReplicatedStorage.Client.controllers.MainGameController, priority = 95, phase = PHASES.CONTROLLERS},
    {name = "PlayerController", path = ReplicatedStorage.Client.controllers.PlayerController, priority = 90, phase = PHASES.CONTROLLERS},
    {name = "GameController", path = ReplicatedStorage.Client.controllers.GameController, priority = 85, phase = PHASES.CONTROLLERS},
    {name = "HubController", path = ReplicatedStorage.Client.controllers.HubController, priority = 80, phase = PHASES.CONTROLLERS},
    
    -- PHASE 3: UI SYSTEMS (Priority 60-79)
    {name = "MobileUIController", path = ReplicatedStorage.Client.controllers.MobileUIController, priority = 75, phase = PHASES.UI},
    {name = "NotificationController", path = ReplicatedStorage.Client.controllers.NotificationController, priority = 70, phase = PHASES.UI},
    {name = "LeaderboardController", path = ReplicatedStorage.Client.controllers.LeaderboardController, priority = 65, phase = PHASES.UI},
    {name = "ShopController", path = ReplicatedStorage.Client.controllers.ShopController, priority = 60, phase = PHASES.UI},
    
    -- PHASE 4: GAMEPLAY SYSTEMS (Priority 40-59)
    {name = "AchievementController", path = ReplicatedStorage.Client.controllers.AchievementController, priority = 55, phase = PHASES.GAMEPLAY},
    {name = "QuestController", path = ReplicatedStorage.Client.controllers.QuestController, priority = 50, phase = PHASES.GAMEPLAY},
    {name = "SocialController", path = ReplicatedStorage.Client.controllers.SocialController, priority = 45, phase = PHASES.GAMEPLAY},
    {name = "TutorialController", path = ReplicatedStorage.Client.controllers.TutorialController, priority = 40, phase = PHASES.GAMEPLAY},
    
    -- PHASE 5: POLISH & EFFECTS (Priority 20-39)
    {name = "GameAudioController", path = ReplicatedStorage.Client.controllers.GameAudioController, priority = 35, phase = PHASES.POLISH},
    {name = "ScreenEffectsController", path = ReplicatedStorage.Client.controllers.ScreenEffectsController, priority = 30, phase = PHASES.POLISH},
    {name = "TrailController", path = ReplicatedStorage.Client.controllers.TrailController, priority = 25, phase = PHASES.POLISH},
    {name = "PartyController", path = ReplicatedStorage.Client.controllers.PartyController, priority = 20, phase = PHASES.POLISH}
}

-- Error tracking
local initializationErrors = {}
local criticalErrors = {}

-- Initialize core client systems
function ClientInit:InitializeCore()
    print("[ClientInit] Phase 1: Initializing core systems...")
    
    -- Reset StarterGui
    StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.PlayerList, false)
    
    -- Initialize error tracking
    local errorTracker = {
        CoreGuiErrors = 0,
        ModuleLoadErrors = 0,
        ControllerErrors = 0
    }
    
    -- Set up error handling
    local function handleError(error, context)
        warn(string.format("[ClientInit] Error in %s: %s", context, tostring(error)))
        table.insert(initializationErrors, {
            context = context,
            error = error,
            timestamp = tick()
        })
        
        errorTracker[context .. "Errors"] = (errorTracker[context .. "Errors"] or 0) + 1
    end
    
    -- Wait for essential shared modules
    local essentialModules = {
        "RemoteEvents",
        "ModernUISystem",
        "DeveloperConfig"
    }
    
    for _, moduleName in ipairs(essentialModules) do
        local module = SafeRequire.requireWithTimeout(
            ReplicatedStorage.Shared.modules[moduleName], 
            5, 
            nil
        )
        
        if not module then
            handleError("Failed to load " .. moduleName, "ModuleLoad")
        else
            print(string.format("[ClientInit] ✓ Loaded %s", moduleName))
        end
    end
    
    return errorTracker
end

-- Register all controllers
function ClientInit:RegisterControllers()
    print("[ClientInit] Phase 2: Registering controllers...")
    
    local registeredCount = 0
    local failedCount = 0
    
    for _, config in ipairs(CONTROLLER_CONFIG) do
        local success = pcall(function()
            if config.path:FindFirstChild(config.name) then
                ControllerRegistry:RegisterController(
                    config.name,
                    config.path[config.name],
                    config.priority
                )
                registeredCount = registeredCount + 1
            else
                warn(string.format("[ClientInit] Controller not found: %s", config.name))
                failedCount = failedCount + 1
            end
        end)
        
        if not success then
            failedCount = failedCount + 1
        end
    end
    
    print(string.format("[ClientInit] Controller registration complete - Success: %d, Failed: %d", 
        registeredCount, failedCount))
    
    return registeredCount > 0
end

-- Initialize all controllers in phases
function ClientInit:InitializeControllers()
    print("[ClientInit] Phase 3: Initializing controllers...")
    
    local success = ControllerRegistry:InitializeAll()
    
    if not success then
        table.insert(criticalErrors, "Controller initialization failed")
        return false
    end
    
    return true
end

-- Start all controllers
function ClientInit:StartControllers()
    print("[ClientInit] Phase 4: Starting controllers...")
    
    local success = ControllerRegistry:StartAll()
    
    if not success then
        table.insert(criticalErrors, "Controller startup failed")
        return false
    end
    
    return true
end

-- Setup client-specific services
function ClientInit:SetupClientServices()
    print("[ClientInit] Phase 5: Setting up client services...")
    
    -- Mobile optimization
    local MobileOptimizationService = SafeRequire.require(
        ReplicatedStorage.Client.services.MobileOptimizationService
    )
    
    if MobileOptimizationService and MobileOptimizationService.Initialize then
        pcall(function()
            MobileOptimizationService:Initialize()
            print("[ClientInit] ✓ Mobile optimization initialized")
        end)
    end
    
    -- Setup analytics client
    local Analytics = SafeRequire.require(ReplicatedStorage.Shared.modules.Analytics)
    if Analytics and Analytics.InitializeClient then
        pcall(function()
            Analytics:InitializeClient()
            print("[ClientInit] ✓ Analytics client initialized")
        end)
    end
    
    return true
end

-- Show loading screen
function ClientInit:ShowLoadingScreen()
    local loadingGui = Instance.new("ScreenGui")
    loadingGui.Name = "LoadingScreen"
    loadingGui.Parent = playerGui
    
    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(1, 0, 1, 0)
    frame.BackgroundColor3 = Color3.fromRGB(20, 20, 25)
    frame.BorderSizePixel = 0
    frame.Parent = loadingGui
    
    local logo = Instance.new("TextLabel")
    logo.Size = UDim2.new(0, 400, 0, 80)
    logo.Position = UDim2.new(0.5, -200, 0.4, -40)
    logo.BackgroundTransparency = 1
    logo.Text = "COLOR RUSH"
    logo.Font = Enum.Font.FredokaOne
    logo.TextSize = 48
    logo.TextColor3 = Color3.fromRGB(255, 255, 255)
    logo.Parent = frame
    
    local status = Instance.new("TextLabel")
    status.Size = UDim2.new(0, 300, 0, 40)
    status.Position = UDim2.new(0.5, -150, 0.6, 0)
    status.BackgroundTransparency = 1
    status.Text = "Initializing..."
    status.Font = Enum.Font.Gotham
    status.TextSize = 18
    status.TextColor3 = Color3.fromRGB(200, 200, 200)
    status.Parent = frame
    
    -- Return status updater function
    return function(text)
        if status then
            status.Text = text
        end
    end, loadingGui
end

-- Hide loading screen
function ClientInit:HideLoadingScreen(loadingGui)
    if loadingGui then
        local tween = TweenService:Create(
            loadingGui.Frame,
            TweenInfo.new(0.5, Enum.EasingStyle.Quart, Enum.EasingDirection.Out),
            {BackgroundTransparency = 1}
        )
        
        tween:Play()
        tween.Completed:Connect(function()
            loadingGui:Destroy()
        end)
    end
end

-- Get initialization report
function ClientInit:GetInitializationReport()
    local report = {
        Success = #criticalErrors == 0,
        CriticalErrors = criticalErrors,
        InitializationErrors = initializationErrors,
        ControllerStatus = ControllerRegistry:GetStatus(),
        Timestamp = tick()
    }
    
    return report
end

-- Main initialization function
function ClientInit:Initialize()
    local totalStartTime = tick()
    
    -- Show loading screen
    local updateStatus, loadingGui = self:ShowLoadingScreen()
    
    updateStatus("Initializing core systems...")
    local coreErrors = self:InitializeCore()
    wait(0.1)
    
    updateStatus("Registering controllers...")
    local registrationSuccess = self:RegisterControllers()
    wait(0.1)
    
    if not registrationSuccess then
        table.insert(criticalErrors, "Controller registration failed")
        self:HideLoadingScreen(loadingGui)
        error("[ClientInit] CRITICAL: Controller registration failed")
        return false
    end
    
    updateStatus("Loading controllers...")
    local initSuccess = self:InitializeControllers()
    wait(0.1)
    
    if not initSuccess then
        self:HideLoadingScreen(loadingGui)
        error("[ClientInit] CRITICAL: Controller initialization failed")
        return false
    end
    
    updateStatus("Starting game systems...")
    local startSuccess = self:StartControllers()
    wait(0.1)
    
    if not startSuccess then
        self:HideLoadingScreen(loadingGui)
        error("[ClientInit] CRITICAL: Controller startup failed")
        return false
    end
    
    updateStatus("Setting up services...")
    self:SetupClientServices()
    wait(0.1)
    
    updateStatus("Ready!")
    wait(0.5)
    
    -- Hide loading screen
    self:HideLoadingScreen(loadingGui)
    
    local totalTime = tick() - totalStartTime
    
    print(string.format("[ClientInit] ✓ Client initialization completed in %.2fs", totalTime))
    
    -- Log successful initialization
    local report = self:GetInitializationReport()
    if report.Success then
        print("[ClientInit] All systems initialized successfully!")
    else
        warn("[ClientInit] Initialization completed with errors")
        for _, error in ipairs(report.CriticalErrors) do
            warn("[ClientInit] Critical: " .. tostring(error))
        end
    end
    
    return report.Success
end

-- Handle initialization failure
local function handleInitializationFailure(error)
    warn("[ClientInit] FATAL ERROR: " .. tostring(error))
    
    -- Create emergency UI
    local emergencyGui = Instance.new("ScreenGui")
    emergencyGui.Name = "EmergencyUI"
    emergencyGui.Parent = playerGui
    
    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(1, 0, 1, 0)
    frame.BackgroundColor3 = Color3.fromRGB(255, 50, 50)
    frame.Parent = emergencyGui
    
    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(0.8, 0, 0.2, 0)
    label.Position = UDim2.new(0.1, 0, 0.4, 0)
    label.BackgroundTransparency = 1
    label.Text = "Game initialization failed. Please rejoin."
    label.Font = Enum.Font.GothamBold
    label.TextSize = 24
    label.TextColor3 = Color3.fromRGB(255, 255, 255)
    label.TextWrapped = true
    label.Parent = frame
end

-- Start the initialization process
local success, error = pcall(function()
    ClientInit:Initialize()
end)

if not success then
    handleInitializationFailure(error)
end
