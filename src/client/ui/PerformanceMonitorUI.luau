-- PerformanceMonitorUI.luau
-- Client-side performance monitoring UI and display

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")

local SafeRequire = require(ReplicatedStorage.Shared.utils.SafeRequire)
local RemoteEvents = SafeRequire.require(ReplicatedStorage.Shared.modules.RemoteEvents)

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local PerformanceMonitorUI = {}

-- UI State
local isVisible = false
local performanceGui = nil
local updateConnection = nil

-- UI Elements
local mainFrame = nil
local fpsLabel = nil
local memoryLabel = nil
local pingLabel = nil
local statusLabel = nil
local alertFrame = nil
local minimizedFrame = nil

-- Configuration
local UI_CONFIG = {
    UPDATE_INTERVAL = 1, -- seconds
    POSITION_TWEEN_TIME = 0.3,
    FADE_TWEEN_TIME = 0.5,
    AUTO_HIDE_ALERTS = true,
    ALERT_DURATION = 5 -- seconds
}

-- Color schemes for different status levels
local STATUS_COLORS = {
    good = Color3.fromRGB(46, 204, 113),
    warning = Color3.fromRGB(241, 196, 15),
    critical = Color3.fromRGB(231, 76, 60),
    neutral = Color3.fromRGB(149, 165, 166)
}

-- Create Performance Monitor GUI
function PerformanceMonitorUI.createGUI()
    if performanceGui then
        performanceGui:Destroy()
    end
    
    -- Main ScreenGui
    performanceGui = Instance.new("ScreenGui")
    performanceGui.Name = "PerformanceMonitorGUI"
    performanceGui.ResetOnSpawn = false
    performanceGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    performanceGui.Parent = playerGui
    
    -- Main Frame
    mainFrame = Instance.new("Frame")
    mainFrame.Name = "MainFrame"
    mainFrame.Size = UDim2.new(0, 280, 0, 160)
    mainFrame.Position = UDim2.new(1, -290, 0, 10)
    mainFrame.BackgroundColor3 = Color3.fromRGB(44, 62, 80)
    mainFrame.BorderSizePixel = 0
    mainFrame.Visible = false
    mainFrame.Parent = performanceGui
    
    -- Main Frame Corner
    local mainCorner = Instance.new("UICorner")
    mainCorner.CornerRadius = UDim.new(0, 8)
    mainCorner.Parent = mainFrame
    
    -- Title Label
    local titleLabel = Instance.new("TextLabel")
    titleLabel.Name = "TitleLabel"
    titleLabel.Size = UDim2.new(1, 0, 0, 30)
    titleLabel.Position = UDim2.new(0, 0, 0, 0)
    titleLabel.BackgroundColor3 = Color3.fromRGB(52, 73, 94)
    titleLabel.BorderSizePixel = 0
    titleLabel.Text = "Performance Monitor"
    titleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    titleLabel.TextScaled = true
    titleLabel.Font = Enum.Font.SourceSansBold
    titleLabel.Parent = mainFrame
    
    local titleCorner = Instance.new("UICorner")
    titleCorner.CornerRadius = UDim.new(0, 8)
    titleCorner.Parent = titleLabel
    
    -- Content Frame
    local contentFrame = Instance.new("Frame")
    contentFrame.Name = "ContentFrame"
    contentFrame.Size = UDim2.new(1, -20, 1, -40)
    contentFrame.Position = UDim2.new(0, 10, 0, 35)
    contentFrame.BackgroundTransparency = 1
    contentFrame.Parent = mainFrame
    
    -- FPS Label
    fpsLabel = Instance.new("TextLabel")
    fpsLabel.Name = "FPSLabel"
    fpsLabel.Size = UDim2.new(1, 0, 0, 25)
    fpsLabel.Position = UDim2.new(0, 0, 0, 0)
    fpsLabel.BackgroundTransparency = 1
    fpsLabel.Text = "FPS: --"
    fpsLabel.TextColor3 = STATUS_COLORS.neutral
    fpsLabel.TextScaled = true
    fpsLabel.Font = Enum.Font.SourceSans
    fpsLabel.TextXAlignment = Enum.TextXAlignment.Left
    fpsLabel.Parent = contentFrame
    
    -- Memory Label
    memoryLabel = Instance.new("TextLabel")
    memoryLabel.Name = "MemoryLabel"
    memoryLabel.Size = UDim2.new(1, 0, 0, 25)
    memoryLabel.Position = UDim2.new(0, 0, 0, 30)
    memoryLabel.BackgroundTransparency = 1
    memoryLabel.Text = "Memory: --"
    memoryLabel.TextColor3 = STATUS_COLORS.neutral
    memoryLabel.TextScaled = true
    memoryLabel.Font = Enum.Font.SourceSans
    memoryLabel.TextXAlignment = Enum.TextXAlignment.Left
    memoryLabel.Parent = contentFrame
    
    -- Ping Label
    pingLabel = Instance.new("TextLabel")
    pingLabel.Name = "PingLabel"
    pingLabel.Size = UDim2.new(1, 0, 0, 25)
    pingLabel.Position = UDim2.new(0, 0, 0, 60)
    pingLabel.BackgroundTransparency = 1
    pingLabel.Text = "Ping: --"
    pingLabel.TextColor3 = STATUS_COLORS.neutral
    pingLabel.TextScaled = true
    pingLabel.Font = Enum.Font.SourceSans
    pingLabel.TextXAlignment = Enum.TextXAlignment.Left
    pingLabel.Parent = contentFrame
    
    -- Status Label
    statusLabel = Instance.new("TextLabel")
    statusLabel.Name = "StatusLabel"
    statusLabel.Size = UDim2.new(1, 0, 0, 25)
    statusLabel.Position = UDim2.new(0, 0, 0, 90)
    statusLabel.BackgroundTransparency = 1
    statusLabel.Text = "Status: Good"
    statusLabel.TextColor3 = STATUS_COLORS.good
    statusLabel.TextScaled = true
    statusLabel.Font = Enum.Font.SourceSansBold
    statusLabel.TextXAlignment = Enum.TextXAlignment.Left
    statusLabel.Parent = contentFrame
    
    -- Toggle Button
    local toggleButton = Instance.new("TextButton")
    toggleButton.Name = "ToggleButton"
    toggleButton.Size = UDim2.new(0, 20, 0, 20)
    toggleButton.Position = UDim2.new(1, -25, 0, 5)
    toggleButton.BackgroundColor3 = Color3.fromRGB(231, 76, 60)
    toggleButton.BorderSizePixel = 0
    toggleButton.Text = "X"
    toggleButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    toggleButton.TextScaled = true
    toggleButton.Font = Enum.Font.SourceSansBold
    toggleButton.Parent = mainFrame
    
    local toggleCorner = Instance.new("UICorner")
    toggleCorner.CornerRadius = UDim.new(0, 4)
    toggleCorner.Parent = toggleButton
    
    toggleButton.MouseButton1Click:Connect(function()
        PerformanceMonitorUI.hide()
    end)
    
    -- Minimized Frame
    minimizedFrame = Instance.new("Frame")
    minimizedFrame.Name = "MinimizedFrame"
    minimizedFrame.Size = UDim2.new(0, 80, 0, 30)
    minimizedFrame.Position = UDim2.new(1, -90, 0, 10)
    minimizedFrame.BackgroundColor3 = Color3.fromRGB(44, 62, 80)
    minimizedFrame.BorderSizePixel = 0
    minimizedFrame.Visible = true
    minimizedFrame.Parent = performanceGui
    
    local minCorner = Instance.new("UICorner")
    minCorner.CornerRadius = UDim.new(0, 6)
    minCorner.Parent = minimizedFrame
    
    local minLabel = Instance.new("TextLabel")
    minLabel.Name = "MinLabel"
    minLabel.Size = UDim2.new(1, -30, 1, 0)
    minLabel.Position = UDim2.new(0, 5, 0, 0)
    minLabel.BackgroundTransparency = 1
    minLabel.Text = "PERF"
    minLabel.TextColor3 = STATUS_COLORS.good
    minLabel.TextScaled = true
    minLabel.Font = Enum.Font.SourceSansBold
    minLabel.TextXAlignment = Enum.TextXAlignment.Left
    minLabel.Parent = minimizedFrame
    
    local expandButton = Instance.new("TextButton")
    expandButton.Name = "ExpandButton"
    expandButton.Size = UDim2.new(0, 20, 0, 20)
    expandButton.Position = UDim2.new(1, -25, 0, 5)
    expandButton.BackgroundColor3 = Color3.fromRGB(46, 204, 113)
    expandButton.BorderSizePixel = 0
    expandButton.Text = "+"
    expandButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    expandButton.TextScaled = true
    expandButton.Font = Enum.Font.SourceSansBold
    expandButton.Parent = minimizedFrame
    
    local expandCorner = Instance.new("UICorner")
    expandCorner.CornerRadius = UDim.new(0, 4)
    expandCorner.Parent = expandButton
    
    expandButton.MouseButton1Click:Connect(function()
        PerformanceMonitorUI.show()
    end)
    
    -- Alert Frame
    alertFrame = Instance.new("Frame")
    alertFrame.Name = "AlertFrame"
    alertFrame.Size = UDim2.new(0, 300, 0, 80)
    alertFrame.Position = UDim2.new(0.5, -150, 0, -100)
    alertFrame.BackgroundColor3 = Color3.fromRGB(231, 76, 60)
    alertFrame.BorderSizePixel = 0
    alertFrame.Visible = false
    alertFrame.Parent = performanceGui
    
    local alertCorner = Instance.new("UICorner")
    alertCorner.CornerRadius = UDim.new(0, 8)
    alertCorner.Parent = alertFrame
    
    local alertLabel = Instance.new("TextLabel")
    alertLabel.Name = "AlertLabel"
    alertLabel.Size = UDim2.new(1, -20, 1, -20)
    alertLabel.Position = UDim2.new(0, 10, 0, 10)
    alertLabel.BackgroundTransparency = 1
    alertLabel.Text = "Performance Alert"
    alertLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    alertLabel.TextScaled = true
    alertLabel.Font = Enum.Font.SourceSansBold
    alertLabel.TextWrapped = true
    alertLabel.Parent = alertFrame
    
    return performanceGui
end

-- Update UI with performance data
function PerformanceMonitorUI.updateDisplay(performanceData)
    if not performanceGui or not mainFrame then return end
    
    local fps = performanceData.fps or {}
    local memory = performanceData.memory or {}
    local ping = performanceData.ping or {}
    local overall = performanceData.overall or "good"
    
    -- Update FPS
    if fpsLabel and fps.current then
        fpsLabel.Text = string.format("FPS: %d (Avg: %d)", fps.current, fps.average or 0)
        fpsLabel.TextColor3 = STATUS_COLORS[fps.status] or STATUS_COLORS.neutral
    end
    
    -- Update Memory
    if memoryLabel and memory.current then
        memoryLabel.Text = string.format("Memory: %s (Peak: %s)", memory.current, memory.peak or "N/A")
        memoryLabel.TextColor3 = STATUS_COLORS[memory.status] or STATUS_COLORS.neutral
    end
    
    -- Update Ping
    if pingLabel and ping.current then
        pingLabel.Text = string.format("Ping: %dms (Avg: %dms)", ping.current, ping.average or 0)
        pingLabel.TextColor3 = STATUS_COLORS[ping.status] or STATUS_COLORS.neutral
    end
    
    -- Update Overall Status
    if statusLabel then
        local statusText = string.upper(overall:sub(1,1)) .. overall:sub(2)
        statusLabel.Text = "Status: " .. statusText
        statusLabel.TextColor3 = STATUS_COLORS[overall] or STATUS_COLORS.neutral
    end
    
    -- Update minimized indicator
    if minimizedFrame then
        local minLabel = minimizedFrame:FindFirstChild("MinLabel")
        if minLabel then
            minLabel.TextColor3 = STATUS_COLORS[overall] or STATUS_COLORS.neutral
        end
    end
end

-- Show performance alert
function PerformanceMonitorUI.showAlert(alertType, message)
    if not alertFrame then return end
    
    local alertLabel = alertFrame:FindFirstChild("AlertLabel")
    if alertLabel then
        alertLabel.Text = message
    end
    
    -- Set alert color based on type
    if alertType == "critical" then
        alertFrame.BackgroundColor3 = STATUS_COLORS.critical
    elseif alertType == "warning" then
        alertFrame.BackgroundColor3 = STATUS_COLORS.warning
    else
        alertFrame.BackgroundColor3 = STATUS_COLORS.neutral
    end
    
    -- Show alert with animation
    alertFrame.Position = UDim2.new(0.5, -150, 0, -100)
    alertFrame.Visible = true
    
    local showTween = TweenService:Create(alertFrame, 
        TweenInfo.new(UI_CONFIG.POSITION_TWEEN_TIME, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
        {Position = UDim2.new(0.5, -150, 0, 20)}
    )
    showTween:Play()
    
    -- Auto-hide alert
    if UI_CONFIG.AUTO_HIDE_ALERTS then
        task.wait(UI_CONFIG.ALERT_DURATION)
        PerformanceMonitorUI.hideAlert()
    end
end

-- Hide performance alert
function PerformanceMonitorUI.hideAlert()
    if not alertFrame or not alertFrame.Visible then return end
    
    local hideTween = TweenService:Create(alertFrame,
        TweenInfo.new(UI_CONFIG.POSITION_TWEEN_TIME, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
        {Position = UDim2.new(0.5, -150, 0, -100)}
    )
    
    hideTween:Play()
    hideTween.Completed:Connect(function()
        alertFrame.Visible = false
    end)
end

-- Show performance monitor
function PerformanceMonitorUI.show()
    if not performanceGui then
        PerformanceMonitorUI.createGUI()
    end
    
    isVisible = true
    mainFrame.Visible = true
    minimizedFrame.Visible = false
    
    -- Start update loop
    if not updateConnection then
        updateConnection = task.spawn(function()
            while isVisible do
                RemoteEvents.RequestPerformanceReport:FireServer()
                task.wait(UI_CONFIG.UPDATE_INTERVAL)
            end
        end)
    end
end

-- Hide performance monitor
function PerformanceMonitorUI.hide()
    isVisible = false
    
    if mainFrame then
        mainFrame.Visible = false
    end
    
    if minimizedFrame then
        minimizedFrame.Visible = true
    end
    
    -- Stop update loop
    if updateConnection then
        task.cancel(updateConnection)
        updateConnection = nil
    end
end

-- Toggle visibility
function PerformanceMonitorUI.toggle()
    if isVisible then
        PerformanceMonitorUI.hide()
    else
        PerformanceMonitorUI.show()
    end
end

-- Keyboard shortcut (Ctrl+P)
UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    
    if input.KeyCode == Enum.KeyCode.P and UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) then
        PerformanceMonitorUI.toggle()
    end
end)

-- Remote event connections
RemoteEvents.PerformanceReportUpdated.OnClientEvent:Connect(function(performanceData)
    PerformanceMonitorUI.updateDisplay(performanceData)
end)

RemoteEvents.PerformanceAlert.OnClientEvent:Connect(function(alertType, message)
    PerformanceMonitorUI.showAlert(alertType, message)
end)

RemoteEvents.ShowPerformanceUI.OnClientEvent:Connect(function()
    PerformanceMonitorUI.show()
end)

RemoteEvents.HidePerformanceUI.OnClientEvent:Connect(function()
    PerformanceMonitorUI.hide()
end)

-- Initialize minimized view
PerformanceMonitorUI.createGUI()

return PerformanceMonitorUI
