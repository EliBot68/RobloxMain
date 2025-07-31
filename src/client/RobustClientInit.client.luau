-- RobustClientInit.client.luau
-- Robust client initialization with comprehensive error handling integration
-- Designed to handle all client startup scenarios with fallbacks and recovery

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterGui = game:GetService("StarterGui")
local TweenService = game:GetService("TweenService")
local _RunService = game:GetService("RunService")
local _UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui", 10)

-- Critical: Wait for essential modules with timeout
local function waitForModule(parent, name, timeout)
    local startTime = tick()
    while not parent:FindFirstChild(name) and tick() - startTime < timeout do
        wait(0.1)
    end
    return parent:FindFirstChild(name)
end

-- Essential modules with fallback handling
local SharedFolder = ReplicatedStorage:WaitForChild("Shared", 10)
local CoreFolder = SharedFolder and SharedFolder:FindFirstChild("core")
local UtilsFolder = SharedFolder and SharedFolder:FindFirstChild("utils")

-- Initialize error handler first (critical for all other operations)
local CriticalErrorHandler = nil
if CoreFolder then
    local errorHandlerModule = waitForModule(CoreFolder, "CriticalErrorHandler", 5)
    if errorHandlerModule then
        CriticalErrorHandler = require(errorHandlerModule).new()
        print("✅ [ClientInit] CriticalErrorHandler initialized")
    else
        warn("❌ [ClientInit] CRITICAL: CriticalErrorHandler not found")
    end
else
    warn("❌ [ClientInit] CRITICAL: Shared core folder not found")
end

-- Safe require with error handling
local SafeRequire = nil
if UtilsFolder then
    local safeRequireModule = waitForModule(UtilsFolder, "SafeRequire", 5)
    if safeRequireModule then
        SafeRequire = require(safeRequireModule)
        print("✅ [ClientInit] SafeRequire initialized")
    end
end

-- Fallback safe require implementation
if not SafeRequire then
    SafeRequire = {
        require = function(moduleScript, defaultValue)
            local success, result = pcall(require, moduleScript)
            if success then
                return result
            else
                warn("[ClientInit] Failed to require: " .. tostring(moduleScript))
                return defaultValue
            end
        end,
        requireWithTimeout = function(moduleScript, timeout, defaultValue)
            return SafeRequire.require(moduleScript, defaultValue)
        end
    }
    print("⚠️ [ClientInit] Using fallback SafeRequire")
end

print("🚀 [ClientInit] Starting robust Color Rush client initialization...")

-- ========================================
-- ROBUST CLIENT INITIALIZATION SYSTEM
-- ========================================

local RobustClientInit = {}

-- Initialization state tracking
local InitializationState = {
    Phase = "STARTING",
    StartTime = tick(),
    CompletedPhases = {},
    Errors = {},
    CriticalErrors = {},
    LoadedControllers = {},
    FailedControllers = {},
    RetryAttempts = {},
    EmergencyMode = false
}

-- Controller configuration with fallback priorities
local CONTROLLER_CONFIG = {
    -- CRITICAL CONTROLLERS (Must load for basic functionality)
    {
        name = "InputController",
        path = "Client/controllers/InputController",
        priority = 100,
        critical = true,
        fallback = "BasicInputFallback",
        description = "Handles player input and controls"
    },
    {
        name = "GuiController", 
        path = "Client/controllers/GuiController",
        priority = 95,
        critical = true,
        fallback = "BasicGuiFallback",
        description = "Core GUI system management"
    },
    {
        name = "SettingsController",
        path = "Client/controllers/SettingsController", 
        priority = 90,
        critical = false,
        fallback = "DefaultSettings",
        description = "Game settings and preferences"
    },

    -- GAMEPLAY CONTROLLERS
    {
        name = "MainGameController",
        path = "Client/controllers/MainGameController",
        priority = 85,
        critical = true,
        fallback = "BasicGameplayFallback",
        description = "Main game logic controller"
    },
    {
        name = "PlayerController",
        path = "Client/controllers/PlayerController",
        priority = 80,
        critical = true,
        fallback = "BasicPlayerFallback", 
        description = "Player state management"
    },
    {
        name = "HubController",
        path = "Client/controllers/HubController",
        priority = 75,
        critical = false,
        fallback = nil,
        description = "Hub/lobby functionality"
    },

    -- UI CONTROLLERS
    {
        name = "MobileUIController",
        path = "Client/controllers/MobileUIController",
        priority = 70,
        critical = false,
        fallback = "TouchControlsFallback",
        description = "Mobile-specific UI elements"
    },
    {
        name = "NotificationController",
        path = "Client/controllers/NotificationController",
        priority = 65,
        critical = false,
        fallback = "BasicNotifications",
        description = "In-game notifications"
    },
    {
        name = "ShopController",
        path = "Client/controllers/ShopController",
        priority = 60,
        critical = false,
        fallback = nil,
        description = "In-game shop system"
    },

    -- FEATURE CONTROLLERS
    {
        name = "AchievementController",
        path = "Client/controllers/AchievementController",
        priority = 55,
        critical = false,
        fallback = nil,
        description = "Achievement tracking"
    },
    {
        name = "LeaderboardController",
        path = "Client/controllers/LeaderboardController", 
        priority = 50,
        critical = false,
        fallback = nil,
        description = "Leaderboard display"
    },
    {
        name = "SocialController",
        path = "Client/controllers/SocialController",
        priority = 45,
        critical = false,
        fallback = nil,
        description = "Social features"
    },

    -- AUDIO & EFFECTS 
    {
        name = "GameAudioController",
        path = "Client/controllers/GameAudioController",
        priority = 40,
        critical = false,
        fallback = "SilentMode",
        description = "Game audio management"
    },
    {
        name = "ScreenEffectsController",
        path = "Client/controllers/ScreenEffectsController",
        priority = 35,
        critical = false,
        fallback = nil,
        description = "Visual effects"
    },
    {
        name = "TrailController",
        path = "Client/controllers/TrailController",
        priority = 30,
        critical = false,
        fallback = nil,
        description = "Player trails and cosmetics"
    }
}

-- ========================================
-- ERROR HANDLING WITH BOUNDARIES
-- ========================================

function RobustClientInit:HandleError(error, context, isCritical)
    local errorInfo = {
        error = tostring(error),
        context = context,
        timestamp = tick(),
        critical = isCritical or false
    }

    if isCritical then
        table.insert(InitializationState.CriticalErrors, errorInfo)
        print(string.format("🚨 [ClientInit] CRITICAL ERROR in %s: %s", context, tostring(error)))
    else
        table.insert(InitializationState.Errors, errorInfo)
        print(string.format("⚠️ [ClientInit] ERROR in %s: %s", context, tostring(error)))
    end

    -- Use error handler if available
    if CriticalErrorHandler then
        if isCritical then
            CriticalErrorHandler:Critical(tostring(error), "ClientInit:" .. context)
        else
            CriticalErrorHandler:Error(tostring(error), "ClientInit:" .. context)
        end
    end

    return errorInfo
end

function RobustClientInit:CreatePhaseErrorBoundary(phaseName, phaseFunction)
    if not CriticalErrorHandler then
        -- Fallback error boundary without CriticalErrorHandler
        return function()
            local success, result = pcall(phaseFunction)
            if not success then
                self:HandleError(result, phaseName, false)
                return false
            end
            return result
        end
    end

    -- Use comprehensive error boundary
    return CriticalErrorHandler:CreateErrorBoundary(
        "ClientInit." .. phaseName,
        phaseFunction,
        {
            category = CriticalErrorHandler.ERROR_CATEGORIES.SYSTEM,
            severity = CriticalErrorHandler.ERROR_SEVERITY.CRITICAL,
            recoveryStrategy = CriticalErrorHandler.RECOVERY_STRATEGIES.GRACEFUL,
            gracefulFunction = function()
                self:HandleError("Phase " .. phaseName .. " failed, continuing with next phase", phaseName, false)
                return false
            end,
            onError = function(errorData)
                self:HandleError(errorData.error, phaseName, false)
            end
        }
    )
end

-- ========================================
-- LOADING SCREEN SYSTEM
-- ========================================

function RobustClientInit:CreateLoadingScreen()
    local loadingBoundary = self:CreatePhaseErrorBoundary("LoadingScreen", function()
        if not playerGui then
            error("PlayerGui not available")
        end

        local loadingGui = Instance.new("ScreenGui")
        loadingGui.Name = "RobustLoadingScreen"
        loadingGui.ResetOnSpawn = false
        loadingGui.Parent = playerGui

        -- Main frame
        local frame = Instance.new("Frame")
        frame.Size = UDim2.new(1, 0, 1, 0)
        frame.Position = UDim2.new(0, 0, 0, 0)
        frame.BackgroundColor3 = Color3.fromRGB(15, 15, 20)
        frame.BorderSizePixel = 0
        frame.Parent = loadingGui

        -- Gradient background
        local gradient = Instance.new("UIGradient")
        gradient.Color = ColorSequence.new{
            ColorSequenceKeypoint.new(0, Color3.fromRGB(25, 25, 35)),
            ColorSequenceKeypoint.new(1, Color3.fromRGB(10, 10, 15))
        }
        gradient.Rotation = 45
        gradient.Parent = frame

        -- Logo
        local logo = Instance.new("TextLabel")
        logo.Name = "Logo"
        logo.Size = UDim2.new(0, 500, 0, 100)
        logo.Position = UDim2.new(0.5, -250, 0.35, -50)
        logo.BackgroundTransparency = 1
        logo.Text = "COLOR RUSH"
        logo.Font = Enum.Font.FredokaOne
        logo.TextSize = 56
        logo.TextColor3 = Color3.fromRGB(255, 255, 255)
        logo.TextStrokeTransparency = 0.5
        logo.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
        logo.Parent = frame

        -- Status text
        local statusText = Instance.new("TextLabel")
        statusText.Name = "StatusText"
        statusText.Size = UDim2.new(0, 400, 0, 50)
        statusText.Position = UDim2.new(0.5, -200, 0.55, 0)
        statusText.BackgroundTransparency = 1
        statusText.Text = "Initializing game systems..."
        statusText.Font = Enum.Font.Gotham
        statusText.TextSize = 20
        statusText.TextColor3 = Color3.fromRGB(200, 200, 200)
        statusText.Parent = frame

        -- Progress bar background
        local progressBg = Instance.new("Frame")
        progressBg.Name = "ProgressBackground"
        progressBg.Size = UDim2.new(0, 400, 0, 8)
        progressBg.Position = UDim2.new(0.5, -200, 0.65, 0)
        progressBg.BackgroundColor3 = Color3.fromRGB(40, 40, 50)
        progressBg.BorderSizePixel = 0
        progressBg.Parent = frame

        local progressCorners = Instance.new("UICorner")
        progressCorners.CornerRadius = UDim.new(0, 4)
        progressCorners.Parent = progressBg

        -- Progress bar fill
        local progressFill = Instance.new("Frame")
        progressFill.Name = "ProgressFill"
        progressFill.Size = UDim2.new(0, 0, 1, 0)
        progressFill.Position = UDim2.new(0, 0, 0, 0)
        progressFill.BackgroundColor3 = Color3.fromRGB(0, 150, 255)
        progressFill.BorderSizePixel = 0
        progressFill.Parent = progressBg

        local fillCorners = Instance.new("UICorner")
        fillCorners.CornerRadius = UDim.new(0, 4)
        fillCorners.Parent = progressFill

        -- Progress gradient
        local progressGradient = Instance.new("UIGradient")
        progressGradient.Color = ColorSequence.new{
            ColorSequenceKeypoint.new(0, Color3.fromRGB(0, 120, 255)),
            ColorSequenceKeypoint.new(1, Color3.fromRGB(0, 200, 255))
        }
        progressGradient.Parent = progressFill

        -- Error display (initially hidden)
        local errorFrame = Instance.new("Frame")
        errorFrame.Name = "ErrorFrame"
        errorFrame.Size = UDim2.new(0, 500, 0, 100)
        errorFrame.Position = UDim2.new(0.5, -250, 0.75, 0)
        errorFrame.BackgroundColor3 = Color3.fromRGB(150, 50, 50)
        errorFrame.BackgroundTransparency = 1
        errorFrame.BorderSizePixel = 0
        errorFrame.Visible = false
        errorFrame.Parent = frame

        local errorText = Instance.new("TextLabel")
        errorText.Name = "ErrorText"
        errorText.Size = UDim2.new(1, -20, 1, -20)
        errorText.Position = UDim2.new(0, 10, 0, 10)
        errorText.BackgroundTransparency = 1
        errorText.Text = ""
        errorText.Font = Enum.Font.Gotham
        errorText.TextSize = 16
        errorText.TextColor3 = Color3.fromRGB(255, 200, 200)
        errorText.TextWrapped = true
        errorText.Parent = errorFrame

        -- Update functions
        local function updateStatus(text)
            if statusText then
                statusText.Text = text
            end
        end

        local function updateProgress(percentage)
            if progressFill then
                local tween = TweenService:Create(
                    progressFill,
                    TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
                    {Size = UDim2.new(percentage / 100, 0, 1, 0)}
                )
                tween:Play()
            end
        end

        local function showError(errorMessage)
            if errorFrame and errorText then
                errorText.Text = errorMessage
                errorFrame.Visible = true
                errorFrame.BackgroundTransparency = 0.2
            end
        end

        return loadingGui, updateStatus, updateProgress, showError
    end)

    return loadingBoundary()
end

function RobustClientInit:HideLoadingScreen(loadingGui)
    if not loadingGui then return end
    
    local hideBoundary = self:CreatePhaseErrorBoundary("HideLoadingScreen", function()
        local tween = TweenService:Create(
            loadingGui.Frame,
            TweenInfo.new(0.8, Enum.EasingStyle.Quart, Enum.EasingDirection.Out),
            {BackgroundTransparency = 1}
        )
        
        -- Tween all children
        for _, child in pairs(loadingGui.Frame:GetChildren()) do
            if child:IsA("GuiObject") then
                local childTween = TweenService:Create(
                    child,
                    TweenInfo.new(0.8, Enum.EasingStyle.Quart, Enum.EasingDirection.Out),
                    {BackgroundTransparency = 1, TextTransparency = 1}
                )
                childTween:Play()
            end
        end
        
        tween:Play()
        tween.Completed:Connect(function()
            loadingGui:Destroy()
        end)
        
        return true
    end)
    
    hideBoundary()
end

-- ========================================
-- CONTROLLER MANAGEMENT
-- ========================================

function RobustClientInit:GetControllerModule(config)
    local getBoundary = self:CreatePhaseErrorBoundary("GetController_" .. config.name, function()
        -- Try multiple path formats
        local pathVariations = {
            ReplicatedStorage:FindFirstChild("Client"),
            ReplicatedStorage:FindFirstChild("client"),
            ReplicatedStorage:FindFirstChild("CLIENT")
        }
        
        for _, clientFolder in pairs(pathVariations) do
            if clientFolder then
                local controllersFolder = clientFolder:FindFirstChild("controllers") or 
                                        clientFolder:FindFirstChild("Controllers") or
                                        clientFolder:FindFirstChild("CONTROLLERS")
                
                if controllersFolder then
                    local controllerModule = controllersFolder:FindFirstChild(config.name)
                    if controllerModule then
                        return controllerModule
                    end
                end
            end
        end
        
        error("Controller module not found: " .. config.name)
    end)
    
    return getBoundary()
end

function RobustClientInit:LoadController(config)
    local loadBoundary = self:CreatePhaseErrorBoundary("LoadController_" .. config.name, function()
        print(string.format("🔄 [ClientInit] Loading %s (%s)", config.name, config.description))
        
        -- Check if already loaded
        if InitializationState.LoadedControllers[config.name] then
            print(string.format("✅ [ClientInit] %s already loaded", config.name))
            return InitializationState.LoadedControllers[config.name]
        end
        
        -- Check retry limit
        InitializationState.RetryAttempts[config.name] = InitializationState.RetryAttempts[config.name] or 0
        if InitializationState.RetryAttempts[config.name] >= 3 then
            error("Too many retry attempts for " .. config.name)
        end
        
        -- Get controller module
        local controllerModule = self:GetControllerModule(config)
        if not controllerModule then
            error("Module not found")
        end
        
        -- Require controller
        local controller = SafeRequire.require(controllerModule)
        if not controller then
            error("Failed to require controller")
        end
        
        -- Initialize controller if it has an Initialize method
        if controller.Initialize then
            local initSuccess, initError = pcall(controller.Initialize, controller)
            if not initSuccess then
                error("Controller initialization failed: " .. tostring(initError))
            end
        end
        
        -- Store loaded controller
        InitializationState.LoadedControllers[config.name] = controller
        print(string.format("✅ [ClientInit] %s loaded successfully", config.name))
        
        return controller
    end)
    
    local result = loadBoundary()
    if not result and config.critical then
        InitializationState.CriticalErrors[#InitializationState.CriticalErrors + 1] = {
            controller = config.name,
            error = "Critical controller failed to load",
            timestamp = tick()
        }
    end
    
    return result
end

function RobustClientInit:LoadAllControllers(updateProgress)
    local loadAllBoundary = self:CreatePhaseErrorBoundary("LoadAllControllers", function()
        InitializationState.Phase = "LOADING_CONTROLLERS"
        print("🔄 [ClientInit] Loading all controllers...")
        
        -- Sort controllers by priority (highest first)
        local sortedControllers = {}
        for _, config in pairs(CONTROLLER_CONFIG) do
            table.insert(sortedControllers, config)
        end
        
        table.sort(sortedControllers, function(a, b)
            return a.priority > b.priority
        end)
        
        local totalControllers = #sortedControllers
        local loadedCount = 0
        local criticalFailures = 0
        
        for i, config in ipairs(sortedControllers) do
            local controller = self:LoadController(config)
            
            if controller then
                loadedCount = loadedCount + 1
            else
                table.insert(InitializationState.FailedControllers, config.name)
                if config.critical then
                    criticalFailures = criticalFailures + 1
                end
            end
            
            -- Update progress
            if updateProgress then
                local progress = (i / totalControllers) * 100
                updateProgress(progress)
            end
            
            wait(0.05) -- Small delay to show progress
        end
        
        print(string.format("📊 [ClientInit] Controller loading complete: %d/%d loaded", loadedCount, totalControllers))
        
        if criticalFailures > 0 then
            error(string.format("Critical controller failures: %d", criticalFailures))
        end
        
        return loadedCount > 0
    end)
    
    return loadAllBoundary()
end

-- ========================================
-- SERVICE INITIALIZATION
-- ========================================

function RobustClientInit:InitializeClientServices()
    local initServicesBoundary = self:CreatePhaseErrorBoundary("InitializeClientServices", function()
        InitializationState.Phase = "INITIALIZING_SERVICES"
        print("🔄 [ClientInit] Initializing client services...")
        
        local services = {}
        
        -- Mobile optimization service
        local clientFolder = ReplicatedStorage:FindFirstChild("Client")
        if clientFolder then
            local servicesFolder = clientFolder:FindFirstChild("services")
            if servicesFolder then
                local mobileService = servicesFolder:FindFirstChild("MobileOptimizationService")
                if mobileService then
                    local service = SafeRequire.require(mobileService)
                    if service and service.Initialize then
                        pcall(service.Initialize, service)
                        services.MobileOptimization = service
                        print("✅ [ClientInit] Mobile optimization service initialized")
                    end
                end
            end
        end
        
        -- Analytics client
        local sharedModules = ReplicatedStorage.Shared:FindFirstChild("modules")
        if sharedModules then
            local analyticsModule = sharedModules:FindFirstChild("Analytics")
            if analyticsModule then
                local analytics = SafeRequire.require(analyticsModule)
                if analytics and analytics.InitializeClient then
                    pcall(analytics.InitializeClient, analytics)
                    services.Analytics = analytics
                    print("✅ [ClientInit] Analytics client initialized")
                end
            end
        end
        
        return services
    end)
    
    return initServicesBoundary()
end

-- ========================================
-- STARTUP CONTROLLERS
-- ========================================

function RobustClientInit:StartAllControllers()
    local startBoundary = self:CreatePhaseErrorBoundary("StartAllControllers", function()
        InitializationState.Phase = "STARTING_CONTROLLERS"
        print("🔄 [ClientInit] Starting all controllers...")
        
        local startedCount = 0
        local totalControllers = 0
        
        for name, controller in pairs(InitializationState.LoadedControllers) do
            totalControllers = totalControllers + 1
            
            if controller.Start then
                local success, error = pcall(controller.Start, controller)
                if success then
                    startedCount = startedCount + 1
                    print(string.format("✅ [ClientInit] %s started", name))
                else
                    warn(string.format("❌ [ClientInit] Failed to start %s: %s", name, tostring(error)))
                end
            else
                -- No Start method, consider it started
                startedCount = startedCount + 1
            end
        end
        
        print(string.format("📊 [ClientInit] Controllers started: %d/%d", startedCount, totalControllers))
        return startedCount > 0
    end)
    
    return startBoundary()
end

-- ========================================
-- EMERGENCY MODE
-- ========================================

function RobustClientInit:EnterEmergencyMode(reason)
    InitializationState.EmergencyMode = true
    InitializationState.Phase = "EMERGENCY"
    
    print("🚨 [ClientInit] ENTERING EMERGENCY MODE: " .. tostring(reason))
    
    if CriticalErrorHandler then
        CriticalErrorHandler:Fatal("Client initialization emergency mode: " .. tostring(reason), "ClientInit")
    end
    
    -- Create minimal emergency UI
    if playerGui then
        local emergencyGui = Instance.new("ScreenGui")
        emergencyGui.Name = "EmergencyMode"
        emergencyGui.Parent = playerGui
        
        local frame = Instance.new("Frame")
        frame.Size = UDim2.new(1, 0, 1, 0)
        frame.BackgroundColor3 = Color3.fromRGB(150, 50, 50)
        frame.Parent = emergencyGui
        
        local title = Instance.new("TextLabel")
        title.Size = UDim2.new(0.8, 0, 0.2, 0)
        title.Position = UDim2.new(0.1, 0, 0.3, 0)
        title.BackgroundTransparency = 1
        title.Text = "GAME INITIALIZATION FAILED"
        title.Font = Enum.Font.GothamBold
        title.TextSize = 36
        title.TextColor3 = Color3.fromRGB(255, 255, 255)
        title.TextWrapped = true
        title.Parent = frame
        
        local message = Instance.new("TextLabel")
        message.Size = UDim2.new(0.8, 0, 0.3, 0)
        message.Position = UDim2.new(0.1, 0, 0.5, 0)
        message.BackgroundTransparency = 1
        message.Text = "The game failed to initialize properly. Please rejoin the game.\n\nReason: " .. tostring(reason)
        message.Font = Enum.Font.Gotham
        message.TextSize = 18
        message.TextColor3 = Color3.fromRGB(255, 255, 255)
        message.TextWrapped = true
        message.Parent = frame
    end
end

-- ========================================
-- MAIN INITIALIZATION PROCESS
-- ========================================

function RobustClientInit:Initialize()
    local initBoundary = self:CreatePhaseErrorBoundary("MainInitialization", function()
        local totalStartTime = tick()
        print("🚀 [ClientInit] Starting robust client initialization...")
        
        -- Phase 1: Create loading screen
        local loadingGui, updateStatus, updateProgress, showError = self:CreateLoadingScreen()
        if not loadingGui then
            error("Failed to create loading screen")
        end
        
        -- Phase 2: Basic setup
        updateStatus("Setting up core systems...")
        updateProgress(10)
        
        -- Disable default core GUIs
        pcall(function()
            StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.PlayerList, false)
        end)
        
        wait(0.3)
        
        -- Phase 3: Load controllers
        updateStatus("Loading game controllers...")
        updateProgress(20)
        
        local controllersLoaded = self:LoadAllControllers(function(progress)
            updateProgress(20 + (progress * 0.5)) -- 20-70%
        end)
        
        if not controllersLoaded then
            showError("Failed to load essential game controllers")
            wait(2)
        end
        
        wait(0.3)
        
        -- Phase 4: Initialize services
        updateStatus("Initializing game services...")
        updateProgress(75)
        
        local services = self:InitializeClientServices()
        
        wait(0.3)
        
        -- Phase 5: Start controllers
        updateStatus("Starting game systems...")
        updateProgress(85)
        
        local _controllersStarted = self:StartAllControllers()
        
        wait(0.3)
        
        -- Phase 6: Final setup
        updateStatus("Finalizing initialization...")
        updateProgress(95)
        
        -- Check for critical failures
        if #InitializationState.CriticalErrors > 0 then
            local errorMsg = "Critical errors occurred during initialization"
            showError(errorMsg)
            wait(3)
            error(errorMsg)
        end
        
        wait(0.5)
        
        -- Complete!
        updateStatus("Ready to play!")
        updateProgress(100)
        wait(1)
        
        -- Hide loading screen
        self:HideLoadingScreen(loadingGui)
        
        local totalTime = tick() - totalStartTime
        InitializationState.Phase = "COMPLETE"
        
        print(string.format("✅ [ClientInit] Initialization completed successfully in %.2fs", totalTime))
        print(string.format("📊 [ClientInit] Controllers loaded: %d, Failed: %d", 
            #InitializationState.LoadedControllers, #InitializationState.FailedControllers))
        
        -- Success analytics
        if services and services.Analytics then
            pcall(function()
                services.Analytics:LogEvent("client_init_success", {
                    duration = totalTime,
                    controllers_loaded = #InitializationState.LoadedControllers,
                    controllers_failed = #InitializationState.FailedControllers
                })
            end)
        end
        
        return true
    end)
    
    local success = initBoundary()
    
    if not success then
        self:EnterEmergencyMode("Main initialization failed")
    end
    
    return success
end

-- ========================================
-- START INITIALIZATION
-- ========================================

local function startClientInitialization()
    local startBoundary = function()
        if not playerGui then
            error("PlayerGui not available")
        end
        
        local init = RobustClientInit
        return init:Initialize()
    end
    
    if CriticalErrorHandler then
        local wrappedStart = CriticalErrorHandler:CreateErrorBoundary(
            "ClientInitialization",
            startBoundary,
            {
                category = CriticalErrorHandler.ERROR_CATEGORIES.SYSTEM,
                severity = CriticalErrorHandler.ERROR_SEVERITY.FATAL,
                recoveryStrategy = CriticalErrorHandler.RECOVERY_STRATEGIES.EMERGENCY,
                emergencyFunction = function()
                    RobustClientInit:EnterEmergencyMode("Top-level initialization failure")
                end
            }
        )
        wrappedStart()
    else
        local success, error = pcall(startBoundary)
        if not success then
            RobustClientInit:EnterEmergencyMode("Initialization failed: " .. tostring(error))
        end
    end
end

-- Begin initialization after a short delay
task.wait(0.5)
startClientInitialization()

print("🎮 [ClientInit] Color Rush client initialization script loaded")
