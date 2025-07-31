-- EnhancedClientInit.client.luau
-- Enhanced client initialization with advanced features and monitoring
-- Provides debugging tools, performance monitoring, and failover capabilities

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local _TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local HttpService = game:GetService("HttpService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- Wait for shared modules
local SafeRequire = require(ReplicatedStorage.Shared.utils.SafeRequire)
local ControllerRegistry = require(ReplicatedStorage.Shared.utils.ControllerRegistry)

print("[EnhancedClientInit] Starting enhanced Color Rush client initialization...")

-- Enhanced client initialization manager
local EnhancedClientInit = {}

-- Performance monitoring
local PerformanceMonitor = {
    InitStartTime = tick(),
    PhaseTimings = {},
    MemoryUsage = {},
    FPS = 60,
    HeartbeatConnection = nil
}

-- Advanced configuration
local ADVANCED_CONFIG = {
    EnablePerformanceMonitoring = true,
    EnableDebugUI = game:GetService("Players").LocalPlayer.Name == "EliBot68", -- Debug UI for developer
    EnableFailoverMode = true,
    MaxInitializationTime = 45,
    EnableAnalytics = true,
    LogLevel = "INFO" -- DEBUG, INFO, WARN, ERROR
}

-- Debug UI
local debugUI = nil
local debugMessages = {}

-- Initialize performance monitoring
function PerformanceMonitor:Start()
    if not ADVANCED_CONFIG.EnablePerformanceMonitoring then return end
    
    self.HeartbeatConnection = RunService.Heartbeat:Connect(function()
        self.FPS = math.floor(1 / RunService.Heartbeat:Wait() + 0.5)
        
        -- Track memory usage
        local memStats = game:GetService("Stats"):GetTotalMemoryUsageMb()
        table.insert(self.MemoryUsage, {
            timestamp = tick(),
            usage = memStats
        })
        
        -- Keep only last 100 entries
        if #self.MemoryUsage > 100 then
            table.remove(self.MemoryUsage, 1)
        end
    end)
end

function PerformanceMonitor:Stop()
    if self.HeartbeatConnection then
        self.HeartbeatConnection:Disconnect()
        self.HeartbeatConnection = nil
    end
end

function PerformanceMonitor:RecordPhase(phaseName, duration)
    self.PhaseTimings[phaseName] = duration
    self:Log("INFO", string.format("Phase '%s' completed in %.2fs", phaseName, duration))
end

function PerformanceMonitor:Log(level, message)
    local logEntry = {
        level = level,
        message = message,
        timestamp = tick(),
        time = os.date("%H:%M:%S")
    }
    
    table.insert(debugMessages, logEntry)
    
    -- Print based on log level
    if level == "ERROR" then
        warn("[EnhancedClientInit] " .. message)
    elseif level == "WARN" then  
        warn("[EnhancedClientInit] " .. message)
    else
        print("[EnhancedClientInit] " .. message)
    end
    
    -- Update debug UI
    if debugUI then
        EnhancedClientInit:UpdateDebugUI()
    end
end

-- Create debug UI
function EnhancedClientInit:CreateDebugUI()
    if not ADVANCED_CONFIG.EnableDebugUI then return end
    
    debugUI = Instance.new("ScreenGui")
    debugUI.Name = "ClientInitDebug"
    debugUI.Parent = playerGui
    debugUI.DisplayOrder = 1000
    
    -- Main frame
    local frame = Instance.new("Frame")
    frame.Name = "DebugFrame"
    frame.Size = UDim2.new(0, 400, 0, 600)
    frame.Position = UDim2.new(1, -420, 0, 20)
    frame.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    frame.BackgroundTransparency = 0.3
    frame.BorderSizePixel = 0
    frame.Parent = debugUI
    
    -- Title
    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(1, 0, 0, 30)
    title.BackgroundColor3 = Color3.fromRGB(50, 150, 250)
    title.Text = "Client Init Debug"
    title.Font = Enum.Font.GothamBold
    title.TextSize = 14
    title.TextColor3 = Color3.fromRGB(255, 255, 255)
    title.Parent = frame
    
    -- Stats area
    local statsFrame = Instance.new("Frame")
    statsFrame.Size = UDim2.new(1, 0, 0, 100)
    statsFrame.Position = UDim2.new(0, 0, 0, 30)
    statsFrame.BackgroundTransparency = 1
    statsFrame.Parent = frame
    
    local statsText = Instance.new("TextLabel")
    statsText.Name = "StatsText"
    statsText.Size = UDim2.new(1, -10, 1, 0)
    statsText.Position = UDim2.new(0, 5, 0, 0)
    statsText.BackgroundTransparency = 1
    statsText.Text = "Initializing..."
    statsText.Font = Enum.Font.Code
    statsText.TextSize = 10
    statsText.TextColor3 = Color3.fromRGB(255, 255, 255)
    statsText.TextXAlignment = Enum.TextXAlignment.Left
    statsText.TextYAlignment = Enum.TextYAlignment.Top
    statsText.TextWrapped = true
    statsText.Parent = statsFrame
    
    -- Log area
    local logFrame = Instance.new("ScrollingFrame")
    logFrame.Size = UDim2.new(1, 0, 1, -130)
    logFrame.Position = UDim2.new(0, 0, 0, 130)
    logFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
    logFrame.BorderSizePixel = 0
    logFrame.ScrollBarThickness = 5
    logFrame.Parent = frame
    
    local logText = Instance.new("TextLabel")
    logText.Name = "LogText"
    logText.Size = UDim2.new(1, -10, 1, 0)
    logText.Position = UDim2.new(0, 5, 0, 0)
    logText.BackgroundTransparency = 1
    logText.Text = ""
    logText.Font = Enum.Font.Code
    logText.TextSize = 9
    logText.TextColor3 = Color3.fromRGB(200, 200, 200)
    logText.TextXAlignment = Enum.TextXAlignment.Left
    logText.TextYAlignment = Enum.TextYAlignment.Top
    logText.TextWrapped = true
    logText.Parent = logFrame
    
    -- Toggle visibility with F12
    UserInputService.InputBegan:Connect(function(input)
        if input.KeyCode == Enum.KeyCode.F12 then
            debugUI.Enabled = not debugUI.Enabled
        end
    end)
    
    self:UpdateDebugUI()
end

-- Update debug UI
function EnhancedClientInit:UpdateDebugUI()
    if not debugUI then return end
    
    local statsText = debugUI.DebugFrame:FindFirstChild("StatsText", true)
    local logText = debugUI.DebugFrame:FindFirstChild("LogText", true)
    
    if statsText then
        local stats = string.format(
            "FPS: %d\nMemory: %.1f MB\nUptime: %.1fs\nControllers: %d\nPhases: %s",
            PerformanceMonitor.FPS,
            game:GetService("Stats"):GetTotalMemoryUsageMb(),
            tick() - PerformanceMonitor.InitStartTime,
            ControllerRegistry:GetStatus().TotalControllers,
            HttpService:JSONEncode(PerformanceMonitor.PhaseTimings)
        )
        statsText.Text = stats
    end
    
    if logText then
        -- Show last 50 log messages
        local recentLogs = {}
        local startIndex = math.max(1, #debugMessages - 49)
        
        for i = startIndex, #debugMessages do
            local entry = debugMessages[i]
            local color = entry.level == "ERROR" and "FF5555" or 
                         entry.level == "WARN" and "FFAA00" or "FFFFFF"
            table.insert(recentLogs, string.format('<font color="#%s">[%s] %s</font>', 
                color, entry.time, entry.message))
        end
        
        logText.Text = table.concat(recentLogs, "\n")
        
        -- Auto-scroll to bottom
        local logFrame = logText.Parent
        logFrame.CanvasPosition = Vector2.new(0, logText.AbsoluteSize.Y)
    end
end

-- Enhanced controller registration with dependency checking
function EnhancedClientInit:RegisterControllersWithDependencies()
    PerformanceMonitor:Log("INFO", "Starting enhanced controller registration...")
    
    local phaseStartTime = tick()
    
    -- Controller dependency map
    local _dependencies = {
        MainGameController = {"InputController", "GuiController"},
        PlayerController = {"InputController"},
        MobileUIController = {"GuiController"},
        ShopController = {"GuiController", "NotificationController"},
        AchievementController = {"NotificationController"},
        SocialController = {"PlayerController"}
    }
    
    -- Register controllers with dependency awareness
    local registeredCount = 0
    local failedCount = 0
    
    -- Essential controllers first (no dependencies)
    local essentialControllers = {
        "InputController",
        "GuiController", 
        "SettingsController",
        "NotificationController"
    }
    
    for _, controllerName in ipairs(essentialControllers) do
        local success = self:SafeRegisterController(controllerName, 100)
        if success then
            registeredCount = registeredCount + 1
        else
            failedCount = failedCount + 1
        end
    end
    
    -- Register remaining controllers
    local remainingControllers = {
        "MainGameController", "PlayerController", "GameController", "HubController",
        "MobileUIController", "LeaderboardController", "ShopController",
        "AchievementController", "QuestController", "SocialController", "TutorialController",
        "GameAudioController", "ScreenEffectsController", "TrailController", "PartyController"
    }
    
    for _, controllerName in ipairs(remainingControllers) do
        local success = self:SafeRegisterController(controllerName, 50)
        if success then
            registeredCount = registeredCount + 1
        else
            failedCount = failedCount + 1
        end
    end
    
    local phaseDuration = tick() - phaseStartTime
    PerformanceMonitor:RecordPhase("ControllerRegistration", phaseDuration)
    
    PerformanceMonitor:Log("INFO", string.format(
        "Controller registration complete - Success: %d, Failed: %d", 
        registeredCount, failedCount))
    
    return registeredCount > 0
end

-- Safe controller registration
function EnhancedClientInit:SafeRegisterController(controllerName, priority)
    local success, error = pcall(function()
        local controllerPath = ReplicatedStorage.Client.controllers:FindFirstChild(controllerName)
        if controllerPath then
            ControllerRegistry:RegisterController(controllerName, controllerPath, priority)
            return true
        else
            PerformanceMonitor:Log("WARN", string.format("Controller not found: %s", controllerName))
            return false
        end
    end)
    
    if not success then
        PerformanceMonitor:Log("ERROR", string.format("Failed to register %s: %s", controllerName, tostring(error)))
        return false
    end
    
    return success
end

-- Enhanced initialization with detailed progress tracking
function EnhancedClientInit:InitializeWithProgress()
    local totalStartTime = tick()
    
    -- Start performance monitoring
    PerformanceMonitor:Start()
    
    -- Create debug UI
    self:CreateDebugUI()
    
    PerformanceMonitor:Log("INFO", "Starting enhanced client initialization...")
    
    -- Phase 1: Core Systems
    local phaseStartTime = tick()
    PerformanceMonitor:Log("INFO", "Phase 1: Core systems initialization")
    
    -- Initialize core error handling
    local coreSuccess = true
    
    -- Wait for essential shared modules with timeout
    local essentialModules = {"RemoteEvents", "ModernUISystem", "DeveloperConfig", "Analytics"}
    
    for _, moduleName in ipairs(essentialModules) do
        local module = SafeRequire.requireWithTimeout(
            ReplicatedStorage.Shared.modules[moduleName], 
            10, 
            nil
        )
        
        if module then
            PerformanceMonitor:Log("INFO", string.format("✓ Loaded %s", moduleName))
        else
            PerformanceMonitor:Log("ERROR", string.format("✗ Failed to load %s", moduleName))
            coreSuccess = false
        end
    end
    
    PerformanceMonitor:RecordPhase("CoreSystems", tick() - phaseStartTime)
    
    if not coreSuccess and not ADVANCED_CONFIG.EnableFailoverMode then
        error("Core systems initialization failed")
    end
    
    -- Phase 2: Controller Registration
    phaseStartTime = tick()
    PerformanceMonitor:Log("INFO", "Phase 2: Controller registration")
    
    local registrationSuccess = self:RegisterControllersWithDependencies()
    PerformanceMonitor:RecordPhase("ControllerRegistration", tick() - phaseStartTime)
    
    if not registrationSuccess then
        if ADVANCED_CONFIG.EnableFailoverMode then
            PerformanceMonitor:Log("WARN", "Controller registration failed - entering failover mode")
        else
            error("Controller registration failed")
        end
    end
    
    -- Phase 3: Controller Initialization
    phaseStartTime = tick()
    PerformanceMonitor:Log("INFO", "Phase 3: Controller initialization")
    
    local initSuccess = ControllerRegistry:InitializeAll()
    PerformanceMonitor:RecordPhase("ControllerInitialization", tick() - phaseStartTime)
    
    if not initSuccess then
        if ADVANCED_CONFIG.EnableFailoverMode then
            PerformanceMonitor:Log("WARN", "Controller initialization failed - attempting recovery")
            -- Try to initialize essential controllers only
            initSuccess = self:InitializeEssentialControllersOnly()
        else
            error("Controller initialization failed")
        end
    end
    
    -- Phase 4: Controller Startup
    phaseStartTime = tick()
    PerformanceMonitor:Log("INFO", "Phase 4: Controller startup")
    
    local startSuccess = ControllerRegistry:StartAll()
    PerformanceMonitor:RecordPhase("ControllerStartup", tick() - phaseStartTime)
    
    if not startSuccess then
        PerformanceMonitor:Log("ERROR", "Controller startup failed")
        if not ADVANCED_CONFIG.EnableFailoverMode then
            error("Controller startup failed")
        end
    end
    
    -- Phase 5: Final Setup
    phaseStartTime = tick()
    PerformanceMonitor:Log("INFO", "Phase 5: Final setup and services")
    
    self:SetupAdvancedServices()
    PerformanceMonitor:RecordPhase("FinalSetup", tick() - phaseStartTime)
    
    local totalTime = tick() - totalStartTime
    PerformanceMonitor:Log("INFO", string.format("✓ Enhanced initialization completed in %.2fs", totalTime))
    
    -- Generate initialization report
    local report = self:GenerateInitializationReport(totalTime)
    self:SendInitializationAnalytics(report)
    
    return true
end

-- Initialize essential controllers only (failover mode)
function EnhancedClientInit:InitializeEssentialControllersOnly()
    PerformanceMonitor:Log("WARN", "Attempting essential controllers initialization only")
    
    local essentialControllers = {"InputController", "GuiController", "MainGameController"}
    local successCount = 0
    
    for _, controllerName in ipairs(essentialControllers) do
        local controller = ControllerRegistry:GetController(controllerName)
        if controller and controller.Initialize then
            local success = pcall(function()
                controller:Initialize()
            end)
            if success then
                successCount = successCount + 1
                PerformanceMonitor:Log("INFO", string.format("✓ Essential controller %s initialized", controllerName))
            end
        end
    end
    
    return successCount > 0
end

-- Setup advanced services
function EnhancedClientInit:SetupAdvancedServices()
    -- Analytics initialization
    if ADVANCED_CONFIG.EnableAnalytics then
        local Analytics = SafeRequire.require(ReplicatedStorage.Shared.modules.Analytics)
        if Analytics and Analytics.InitializeClient then
            pcall(function()
                Analytics:InitializeClient()
                PerformanceMonitor:Log("INFO", "✓ Analytics initialized")
            end)
        end
    end
    
    -- Mobile optimization
    local MobileOptimizationService = SafeRequire.require(
        ReplicatedStorage.Client.services.MobileOptimizationService
    )
    if MobileOptimizationService and MobileOptimizationService.Initialize then
        pcall(function()
            MobileOptimizationService:Initialize()
            PerformanceMonitor:Log("INFO", "✓ Mobile optimization initialized")
        end)
    end
end

-- Generate comprehensive initialization report
function EnhancedClientInit:GenerateInitializationReport(totalTime)
    local report = {
        Success = true,
        TotalTime = totalTime,
        PhaseTimings = PerformanceMonitor.PhaseTimings,
        ControllerStatus = ControllerRegistry:GetStatus(),
        ErrorCount = 0,
        WarningCount = 0,
        Timestamp = os.time(),
        PlayerInfo = {
            UserId = player.UserId,
            Name = player.Name,
            AccountAge = player.AccountAge
        }
    }
    
    -- Count errors and warnings
    for _, entry in ipairs(debugMessages) do
        if entry.level == "ERROR" then
            report.ErrorCount = report.ErrorCount + 1
            report.Success = false
        elseif entry.level == "WARN" then
            report.WarningCount = report.WarningCount + 1
        end
    end
    
    return report
end

-- Send initialization analytics
function EnhancedClientInit:SendInitializationAnalytics(report)
    if not ADVANCED_CONFIG.EnableAnalytics then return end
    
    pcall(function()
        local Analytics = SafeRequire.require(ReplicatedStorage.Shared.modules.Analytics)
        if Analytics and Analytics.TrackEvent then
            Analytics:TrackEvent("ClientInitialization", {
                success = report.Success,
                totalTime = report.TotalTime,
                errorCount = report.ErrorCount,
                warningCount = report.WarningCount,
                controllerCount = report.ControllerStatus.TotalControllers
            })
        end
    end)
end

-- Main enhanced initialization
local function startEnhancedInitialization()
    local success, error = pcall(function()
        EnhancedClientInit:InitializeWithProgress()
    end)
    
    if not success then
        PerformanceMonitor:Log("ERROR", "FATAL: " .. tostring(error))
        
        -- Fallback to basic initialization
        if ADVANCED_CONFIG.EnableFailoverMode then
            PerformanceMonitor:Log("WARN", "Attempting fallback initialization...")
            
            pcall(function()
                -- Try basic controller setup
                local basicControllers = {"InputController", "GuiController", "MainGameController"}
                for _, name in ipairs(basicControllers) do
                    local path = ReplicatedStorage.Client.controllers:FindFirstChild(name)
                    if path then
                        ControllerRegistry:RegisterController(name, path, 100)
                    end
                end
                
                ControllerRegistry:InitializeAll()
                ControllerRegistry:StartAll()
                
                PerformanceMonitor:Log("INFO", "✓ Fallback initialization completed")
            end)
        else
            error(error)
        end
    end
end

-- Start the enhanced initialization
startEnhancedInitialization()
