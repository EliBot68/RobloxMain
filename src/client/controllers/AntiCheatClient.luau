-- AntiCheatClient.luau
-- Client-side anti-cheat monitoring and reporting

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local GuiService = game:GetService("GuiService")

local SafeRequire = require(ReplicatedStorage.Shared.utils.SafeRequire)
local RemoteEvents = SafeRequire.require(ReplicatedStorage.Shared.modules.RemoteEvents)

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local AntiCheatClient = {}

-- Client monitoring configuration
local CLIENT_CONFIG = {
    -- Environment monitoring
    checkExploits = true,
    monitorConsole = true,
    checkDebugger = false, -- Can cause false positives
    
    -- Input monitoring
    monitorInputs = true,
    maxInputRate = 50, -- inputs per second
    suspiciousInputThreshold = 100,
    
    -- Performance monitoring
    monitorFPS = true,
    minFPS = 10,
    maxFPS = 200,
    
    -- UI monitoring
    monitorUI = true,
    checkUIModifications = true,
    
    -- Reporting
    enableReporting = true,
    reportCooldown = 5.0 -- seconds
}

-- Monitoring state
local monitoringState = {
    isActive = false,
    lastReportTime = 0,
    inputCount = 0,
    lastInputReset = tick(),
    suspiciousActivities = {},
    warningCount = 0
}

-- Warning GUI
local warningGui = nil

-- Initialize client anti-cheat
function AntiCheatClient:Init()
    print("🛡️ Client Anti-Cheat initializing...")
    
    self:SetupRemoteEvents()
    self:StartMonitoring()
    self:CreateWarningGUI()
    
    monitoringState.isActive = true
    print("✅ Client Anti-Cheat initialized")
end

-- Setup remote event handlers
function AntiCheatClient:SetupRemoteEvents()
    -- Handle warnings from server
    if RemoteEvents.ShowAntiCheatWarning then
        RemoteEvents.ShowAntiCheatWarning.OnClientEvent:Connect(function(message, warningNumber)
            self:ShowWarning(message, warningNumber)
        end)
    end
    
    -- Handle stat reversions
    if RemoteEvents.RevertPlayerStat then
        RemoteEvents.RevertPlayerStat.OnClientEvent:Connect(function(statType, correctValue)
            self:HandleStatReversion(statType, correctValue)
        end)
    end
end

-- Start monitoring systems
function AntiCheatClient:StartMonitoring()
    if CLIENT_CONFIG.checkExploits then
        task.spawn(function() -- UPDATED for modern API
            self:MonitorExploits()
        end)
    end
    
    if CLIENT_CONFIG.monitorInputs then
        task.spawn(function() -- UPDATED for modern API
            self:MonitorInputs()
        end)
    end
    
    if CLIENT_CONFIG.monitorFPS then
        task.spawn(function() -- UPDATED for modern API
            self:MonitorPerformance()
        end)
    end
    
    if CLIENT_CONFIG.monitorUI then
        task.spawn(function() -- UPDATED for modern API
            self:MonitorUI()
        end)
    end
end

-- Event-driven exploit monitoring (NO POLLING)
function AntiCheatClient:MonitorExploits()
    local exploitMonitorEvent = Instance.new("BindableEvent")
    
    local function performExploitCheck()
        if not monitoringState.isActive then return end
        
        -- Check for common exploit environments
        local suspiciousGlobals = {
            "getrawmetatable",
            "setreadonly",
            "getgenv",
            "getsenv",
            "getfenv",
            "dumpstring",
            "loadstring",
            "checkcaller",
            "islclosure"
        }
        
        for _, globalName in ipairs(suspiciousGlobals) do
            if _G[globalName] or getfenv()[globalName] then
                self:ReportSuspiciousActivity("exploit_environment", {
                    detectedGlobal = globalName,
                    severity = "high"
                })
                break
            end
        end
        
        -- Check for common exploit GUIs
        local suspiciousGuis = {
            "Synapse X",
            "KRNL",
            "Fluxus",
            "Script-Ware",
            "ProtoSmasher",
            "Sentinel",
            "Sirhurt"
        }
        
        for _, gui in ipairs(playerGui:GetChildren()) do
            if gui:IsA("ScreenGui") then
                for _, suspiciousName in ipairs(suspiciousGuis) do
                    if string.find(gui.Name:lower(), suspiciousName:lower()) then
                        self:ReportSuspiciousActivity("exploit_gui", {
                            guiName = gui.Name,
                            severity = "critical"
                        })
                    end
                end
            end
        end
    end
end

-- Monitor input patterns
function AntiCheatClient:MonitorInputs()
    local inputConnection
    
    inputConnection = UserInputService.InputBegan:Connect(function(input, gameProcessed)
        if not monitoringState.isActive then
            inputConnection:Disconnect()
            return
        end
        
        monitoringState.inputCount = monitoringState.inputCount + 1
        
        -- Check input rate every second
        local currentTime = tick()
        if currentTime - monitoringState.lastInputReset >= 1.0 then
            if monitoringState.inputCount > CLIENT_CONFIG.maxInputRate then
                self:ReportSuspiciousActivity("high_input_rate", {
                    inputsPerSecond = monitoringState.inputCount,
                    maxAllowed = CLIENT_CONFIG.maxInputRate,
                    severity = "medium"
                })
            end
            
            if monitoringState.inputCount > CLIENT_CONFIG.suspiciousInputThreshold then
                self:ReportSuspiciousActivity("suspicious_input_rate", {
                    inputsPerSecond = monitoringState.inputCount,
                    threshold = CLIENT_CONFIG.suspiciousInputThreshold,
                    severity = "high"
                })
            end
            
            monitoringState.inputCount = 0
            monitoringState.lastInputReset = currentTime
        end
    end)
end

-- Event-driven performance monitoring (NO POLLING)
function AntiCheatClient:MonitorPerformance()
    local performanceEvent = Instance.new("BindableEvent")
    
    local function checkPerformance()
        if not monitoringState.isActive then return end
        
        local fps = 1 / RunService.Heartbeat:Wait() -- Intentionally not using task.wait()
        
        -- Check for unusually high FPS (could indicate speed hacks)
        if fps > CLIENT_CONFIG.maxFPS then
            self:ReportSuspiciousActivity("high_fps", {
                fps = fps,
                maxExpected = CLIENT_CONFIG.maxFPS,
                severity = "medium"
            })
        end
        
        -- Check for unusually low FPS (could indicate lag switching)
        if fps < CLIENT_CONFIG.minFPS then
            self:ReportSuspiciousActivity("low_fps", {
                fps = fps,
                minExpected = CLIENT_CONFIG.minFPS,
                severity = "low"
            })
        end
    end
end

-- Monitor UI for modifications
function AntiCheatClient:MonitorUI()
    local coreGui = game:GetService("CoreGui")
    
    -- Monitor StarterGui changes
    local starterGuiConnection
    starterGuiConnection = game:GetService("StarterGui").ChildAdded:Connect(function(child)
        if not monitoringState.isActive then
            starterGuiConnection:Disconnect()
            return
        end
        
        -- Check for suspicious UI additions
        if child:IsA("ScreenGui") and child.Name:find("Exploit") or child.Name:find("Hack") then
            self:ReportSuspiciousActivity("suspicious_ui", {
                uiName = child.Name,
                uiType = child.ClassName,
                severity = "high"
            })
        end
    end)
    
    -- Monitor PlayerGui for unauthorized modifications
    local playerGuiConnection
    playerGuiConnection = playerGui.ChildAdded:Connect(function(child)
        if not monitoringState.isActive then
            playerGuiConnection:Disconnect()
            return
        end
        
        -- Check for unauthorized GUI injection
        if child:IsA("ScreenGui") and not child:GetAttribute("Authorized") then
            task.wait(1) -- UPDATED for modern API - Give it time to be authorized
            
            if not child:GetAttribute("Authorized") and child.Parent then
                self:ReportSuspiciousActivity("unauthorized_gui", {
                    guiName = child.Name,
                    severity = "medium"
                })
            end
        end
    end)
end

-- Report suspicious activity to server
function AntiCheatClient:ReportSuspiciousActivity(activityType, data)
    if not CLIENT_CONFIG.enableReporting then return end
    
    local currentTime = tick()
    
    -- Check cooldown
    if currentTime - monitoringState.lastReportTime < CLIENT_CONFIG.reportCooldown then
        return
    end
    
    -- Log locally
    table.insert(monitoringState.suspiciousActivities, {
        type = activityType,
        data = data,
        time = currentTime
    })
    
    -- Keep only last 50 activities
    if #monitoringState.suspiciousActivities > 50 then
        table.remove(monitoringState.suspiciousActivities, 1)
    end
    
    -- Report to server
    if RemoteEvents.ReportSuspiciousActivity then
        RemoteEvents.ReportSuspiciousActivity:FireServer(activityType, data)
    end
    
    monitoringState.lastReportTime = currentTime
    
    print("⚠️ [CLIENT ANTI-CHEAT] Reported: " .. activityType)
end

-- Create warning GUI
function AntiCheatClient:CreateWarningGUI()
    warningGui = Instance.new("ScreenGui")
    warningGui.Name = "AntiCheatWarningGUI"
    warningGui.ResetOnSpawn = false
    warningGui.DisplayOrder = 1000
    warningGui.Enabled = false
    warningGui.Parent = playerGui
    
    -- Warning frame
    local warningFrame = Instance.new("Frame")
    warningFrame.Name = "WarningFrame"
    warningFrame.Size = UDim2.new(0.6, 0, 0.3, 0)
    warningFrame.Position = UDim2.new(0.2, 0, 0.35, 0)
    warningFrame.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
    warningFrame.BorderSizePixel = 3
    warningFrame.BorderColor3 = Color3.fromRGB(255, 0, 0)
    warningFrame.Parent = warningGui
    
    local warningCorner = Instance.new("UICorner")
    warningCorner.CornerRadius = UDim.new(0, 10)
    warningCorner.Parent = warningFrame
    
    -- Warning title
    local titleLabel = Instance.new("TextLabel")
    titleLabel.Name = "TitleLabel"
    titleLabel.Size = UDim2.new(1, 0, 0.3, 0)
    titleLabel.Position = UDim2.new(0, 0, 0, 0)
    titleLabel.BackgroundTransparency = 1
    titleLabel.Text = "⚠️ ANTI-CHEAT WARNING ⚠️"
    titleLabel.TextColor3 = Color3.fromRGB(255, 255, 0)
    titleLabel.TextSize = 24
    titleLabel.Font = Enum.Font.SourceSansBold
    titleLabel.TextScaled = true
    titleLabel.Parent = warningFrame
    
    -- Warning message
    local messageLabel = Instance.new("TextLabel")
    messageLabel.Name = "MessageLabel"
    messageLabel.Size = UDim2.new(1, -20, 0.5, 0)
    messageLabel.Position = UDim2.new(0, 10, 0.3, 0)
    messageLabel.BackgroundTransparency = 1
    messageLabel.Text = "Suspicious activity detected. Please play fairly."
    messageLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    messageLabel.TextSize = 18
    messageLabel.Font = Enum.Font.SourceSans
    messageLabel.TextWrapped = true
    messageLabel.TextXAlignment = Enum.TextXAlignment.Center
    messageLabel.TextYAlignment = Enum.TextYAlignment.Center
    messageLabel.Parent = warningFrame
    
    -- Close button
    local closeButton = Instance.new("TextButton")
    closeButton.Name = "CloseButton"
    closeButton.Size = UDim2.new(0.2, 0, 0.2, 0)
    closeButton.Position = UDim2.new(0.4, 0, 0.8, 0)
    closeButton.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
    closeButton.BorderSizePixel = 2
    closeButton.BorderColor3 = Color3.fromRGB(200, 200, 200)
    closeButton.Text = "I Understand"
    closeButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    closeButton.TextSize = 14
    closeButton.Font = Enum.Font.SourceSansBold
    closeButton.Parent = warningFrame
    
    local buttonCorner = Instance.new("UICorner")
    buttonCorner.CornerRadius = UDim.new(0, 5)
    buttonCorner.Parent = closeButton
    
    closeButton.MouseButton1Click:Connect(function()
        self:HideWarning()
    end)
    
    -- Auto-hide after 10 seconds
    task.spawn(function() -- UPDATED for modern API
        task.wait(10) -- UPDATED for modern API
        if warningGui.Enabled then
            self:HideWarning()
        end
    end)
end

-- Show warning
function AntiCheatClient:ShowWarning(message, warningNumber)
    if not warningGui then
        self:CreateWarningGUI()
    end
    
    monitoringState.warningCount = warningNumber or (monitoringState.warningCount + 1)
    
    -- Update warning message
    local messageLabel = warningGui.WarningFrame.MessageLabel
    messageLabel.Text = message
    
    -- Update title with warning number
    local titleLabel = warningGui.WarningFrame.TitleLabel
    titleLabel.Text = string.format("⚠️ ANTI-CHEAT WARNING #%d ⚠️", monitoringState.warningCount)
    
    -- Show warning
    warningGui.Enabled = true
    
    -- Play warning sound
    local sound = Instance.new("Sound")
    sound.SoundId = "rbxassetid://131961136" -- Warning sound
    sound.Volume = 0.5
    sound.Parent = warningGui
    sound:Play()
    
    sound.Ended:Connect(function()
        sound:Destroy()
    end)
    
    print("⚠️ Displaying anti-cheat warning #" .. monitoringState.warningCount)
end

-- Hide warning
function AntiCheatClient:HideWarning()
    if warningGui then
        warningGui.Enabled = false
    end
end

-- Handle stat reversion
function AntiCheatClient:HandleStatReversion(statType, correctValue)
    -- This would integrate with your UI to show the corrected value
    print("🔧 Stat reverted: " .. statType .. " set to " .. tostring(correctValue))
    
    -- Show notification to player
    local notificationMessage = string.format(
        "Your %s has been corrected to %s due to suspicious activity.",
        statType,
        tostring(correctValue)
    )
    
    -- Display notification (you would integrate with your notification system)
    self:ShowNotification(notificationMessage, "warning")
end

-- Show notification
function AntiCheatClient:ShowNotification(message, type)
    -- Create temporary notification
    local notification = Instance.new("ScreenGui")
    notification.Name = "AntiCheatNotification"
    notification.Parent = playerGui
    
    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(0.4, 0, 0.1, 0)
    frame.Position = UDim2.new(0.3, 0, 0.1, 0)
    frame.BackgroundColor3 = type == "warning" and Color3.fromRGB(255, 165, 0) or Color3.fromRGB(255, 0, 0)
    frame.BorderSizePixel = 0
    frame.Parent = notification
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 8)
    corner.Parent = frame
    
    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, -20, 1, 0)
    label.Position = UDim2.new(0, 10, 0, 0)
    label.BackgroundTransparency = 1
    label.Text = message
    label.TextColor3 = Color3.fromRGB(255, 255, 255)
    label.TextSize = 14
    label.Font = Enum.Font.SourceSans
    label.TextWrapped = true
    label.TextXAlignment = Enum.TextXAlignment.Center
    label.TextYAlignment = Enum.TextYAlignment.Center
    label.Parent = frame
    
    -- Auto-destroy after 5 seconds
    game:GetService("Debris"):AddItem(notification, 5)
end

-- Enable/disable monitoring
function AntiCheatClient:SetMonitoringEnabled(enabled)
    monitoringState.isActive = enabled
    
    if enabled then
        print("✅ Client anti-cheat monitoring enabled")
    else
        print("⛔ Client anti-cheat monitoring disabled")
    end
end

-- Get monitoring status
function AntiCheatClient:GetStatus()
    return {
        isActive = monitoringState.isActive,
        warningCount = monitoringState.warningCount,
        activitiesReported = #monitoringState.suspiciousActivities,
        lastReport = monitoringState.lastReportTime
    }
end

-- Get recent suspicious activities
function AntiCheatClient:GetRecentActivities(count)
    count = count or 10
    local activities = {}
    
    local startIndex = math.max(1, #monitoringState.suspiciousActivities - count + 1)
    
    for i = startIndex, #monitoringState.suspiciousActivities do
        table.insert(activities, monitoringState.suspiciousActivities[i])
    end
    
    return activities
end

-- Manual integrity check
function AntiCheatClient:PerformIntegrityCheck()
    print("🔍 Performing client integrity check...")
    
    local issues = {}
    
    -- Check if core services are accessible
    local coreServices = {
        "Players",
        "ReplicatedStorage", 
        "Workspace",
        "RunService",
        "UserInputService"
    }
    
    for _, serviceName in ipairs(coreServices) do
        local success, service = pcall(function()
            return game:GetService(serviceName)
        end)
        
        if not success or not service then
            table.insert(issues, "Core service inaccessible: " .. serviceName)
        end
    end
    
    -- Check for modified core functions
    local expectedTypes = {
        ["tostring"] = "function",
        ["tonumber"] = "function",
        ["pairs"] = "function",
        ["ipairs"] = "function",
        ["next"] = "function"
    }
    
    for funcName, expectedType in pairs(expectedTypes) do
        if type(_G[funcName]) ~= expectedType then
            table.insert(issues, "Core function modified: " .. funcName)
        end
    end
    
    if #issues > 0 then
        self:ReportSuspiciousActivity("integrity_check_failed", {
            issues = issues,
            severity = "critical"
        })
    end
    
    print("✅ Client integrity check completed (" .. #issues .. " issues found)")
    return issues
end

-- Cleanup
function AntiCheatClient:Cleanup()
    monitoringState.isActive = false
    
    if warningGui then
        warningGui:Destroy()
        warningGui = nil
    end
    
    print("🧹 Client anti-cheat cleanup completed")
end

return AntiCheatClient
