-- init.client.luau
-- Main client initialization script for Color Rush with comprehensive error handling
-- Handles robust startup of all client-side systems with recovery mechanisms

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterGui = game:GetService("StarterGui")
local TweenService = game:GetService("TweenService")
local _RunService = game:GetService("RunService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- Essential modules with error handling
local SharedFolder = ReplicatedStorage:WaitForChild("Shared", 10)
local SafeRequire = nil
local CriticalErrorHandler = nil

-- Initialize error handler first
if SharedFolder then
    local coreFolder = SharedFolder:FindFirstChild("core")
    if coreFolder then
        local errorHandlerModule = coreFolder:FindFirstChild("CriticalErrorHandler")
        if errorHandlerModule then
            CriticalErrorHandler = require(errorHandlerModule).new()
            print("✅ [ClientInit] CriticalErrorHandler integrated")
        end
    end
    
    local utilsFolder = SharedFolder:FindFirstChild("utils")
    if utilsFolder then
        local safeRequireModule = utilsFolder:FindFirstChild("SafeRequire")
        if safeRequireModule then
            SafeRequire = require(safeRequireModule)
        end
    end
end

-- Fallback SafeRequire if not found
if not SafeRequire then
    SafeRequire = {
        require = function(moduleScript, defaultValue)
            local success, result = pcall(require, moduleScript)
            return success and result or defaultValue
        end,
        requireWithTimeout = function(moduleScript, timeout, defaultValue)
            return SafeRequire.require(moduleScript, defaultValue)
        end
    }
end

-- Try to get ControllerRegistry
local ControllerRegistry = nil
if SharedFolder then
    local utilsFolder = SharedFolder:FindFirstChild("utils")
    if utilsFolder then
        local registryModule = utilsFolder:FindFirstChild("ControllerRegistry")
        if registryModule then
            ControllerRegistry = SafeRequire.require(registryModule)
        end
    end
end

print("[ClientInit] Starting Color Rush client initialization with error handling...")

-- Client initialization manager with error boundaries
local ClientInit = {}

-- Controller configuration for this implementation
local CONTROLLER_CONFIG = {
    -- Core controllers
    {name = "InputController", priority = 100, critical = true},
    {name = "GuiController", priority = 95, critical = true},
    {name = "SettingsController", priority = 90, critical = false},
    {name = "MainGameController", priority = 85, critical = true},
    {name = "PlayerController", priority = 80, critical = true},
    {name = "HubController", priority = 75, critical = false},
    {name = "MobileUIController", priority = 70, critical = false},
    {name = "NotificationController", priority = 65, critical = false},
    {name = "AchievementController", priority = 60, critical = false},
    {name = "GameAudioController", priority = 55, critical = false}
}

-- Error tracking
local initializationErrors = {}
local criticalErrors = {}

-- Create error boundary wrapper
local function _createErrorBoundary(name, func, isCritical)
    if CriticalErrorHandler then
        return CriticalErrorHandler:CreateErrorBoundary(
            "ClientInit." .. name,
            func,
            {
                category = CriticalErrorHandler.ERROR_CATEGORIES.SYSTEM,
                severity = isCritical and CriticalErrorHandler.ERROR_SEVERITY.CRITICAL or CriticalErrorHandler.ERROR_SEVERITY.ERROR,
                recoveryStrategy = CriticalErrorHandler.RECOVERY_STRATEGIES.GRACEFUL,
                gracefulFunction = function()
                    print("⚠️ [ClientInit] " .. name .. " failed, using fallback")
                    return false
                end,
                onError = function(errorData)
                    local errorInfo = {
                        context = name,
                        error = errorData.error,
                        timestamp = tick(),
                        critical = isCritical
                    }
                    
                    if isCritical then
                        table.insert(criticalErrors, errorInfo)
                    else
                        table.insert(initializationErrors, errorInfo)
                    end
                end
            }
        )
    else
        -- Fallback error boundary
        return function()
            local success, result = pcall(func)
            if not success then
                warn("[ClientInit] " .. name .. " failed: " .. tostring(result))
                local errorInfo = {
                    context = name,
                    error = result,
                    timestamp = tick(),
                    critical = isCritical
                }
                
                if isCritical then
                    table.insert(criticalErrors, errorInfo)
                else
                    table.insert(initializationErrors, errorInfo)
                end
                return false
            end
            return result  
        end
    end
end

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
        table.insert(criticalErrors, {
            context = "Controller initialization",
            error = "ControllerRegistry:InitializeAll() failed",
            timestamp = tick(),
            critical = true
        })
        return false
    end
    
    return true
end

-- Start all controllers
function ClientInit:StartControllers()
    print("[ClientInit] Phase 4: Starting controllers...")
    
    local success = ControllerRegistry:StartAll()
    
    if not success then
        table.insert(criticalErrors, {
            context = "Controller startup",
            error = "ControllerRegistry:StartAll() failed",
            timestamp = tick(),
            critical = true
        })
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
    local _coreErrors = self:InitializeCore()
    wait(0.1)
    
    updateStatus("Registering controllers...")
    local registrationSuccess = self:RegisterControllers()
    wait(0.1)
    
    if not registrationSuccess then
        table.insert(criticalErrors, {
            context = "Controller registration",
            error = "RegisterControllers() failed",
            timestamp = tick(),
            critical = true
        })
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
