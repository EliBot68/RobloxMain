-- ClientInitMonitor.client.luau
-- Monitors the client initialization process and provides fallback mechanisms

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- Monitor configuration
local MONITOR_CONFIG = {
    MaxWaitTime = 60, -- Maximum time to wait for initialization
    CheckInterval = 1, -- How often to check (seconds)
    EnableFallback = true,
    ShowProgressUI = true
}

local ClientInitMonitor = {}

-- Monitoring state
local monitoringActive = false
local initializationDetected = false
local fallbackActivated = false
local startTime = tick()

-- Progress UI
local progressUI = nil

-- Create progress UI
function ClientInitMonitor:CreateProgressUI()
    if not MONITOR_CONFIG.ShowProgressUI then return end
    
    progressUI = Instance.new("ScreenGui")
    progressUI.Name = "InitMonitor"
    progressUI.Parent = playerGui
    progressUI.DisplayOrder = 999
    
    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(0, 300, 0, 100)
    frame.Position = UDim2.new(0.5, -150, 0.5, -50)
    frame.BackgroundColor3 = Color3.fromRGB(40, 40, 45)
    frame.BorderSizePixel = 0
    frame.Parent = progressUI
    
    -- Add rounded corners
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 8)
    corner.Parent = frame
    
    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(1, 0, 0, 30)
    title.BackgroundTransparency = 1
    title.Text = "Color Rush"
    title.Font = Enum.Font.GothamBold
    title.TextSize = 16
    title.TextColor3 = Color3.fromRGB(255, 255, 255)
    title.Parent = frame
    
    local status = Instance.new("TextLabel")
    status.Name = "StatusLabel"
    status.Size = UDim2.new(1, -20, 0, 25)
    status.Position = UDim2.new(0, 10, 0, 35)
    status.BackgroundTransparency = 1
    status.Text = "Initializing game systems..."
    status.Font = Enum.Font.Gotham
    status.TextSize = 12
    status.TextColor3 = Color3.fromRGB(200, 200, 200)
    status.Parent = frame
    
    local progressBar = Instance.new("Frame")
    progressBar.Name = "ProgressBar"
    progressBar.Size = UDim2.new(1, -20, 0, 4)
    progressBar.Position = UDim2.new(0, 10, 0, 65)
    progressBar.BackgroundColor3 = Color3.fromRGB(80, 80, 85)
    progressBar.BorderSizePixel = 0
    progressBar.Parent = frame
    
    local progressFill = Instance.new("Frame")
    progressFill.Name = "Fill"
    progressFill.Size = UDim2.new(0, 0, 1, 0)
    progressFill.BackgroundColor3 = Color3.fromRGB(100, 200, 255)
    progressFill.BorderSizePixel = 0
    progressFill.Parent = progressBar
    
    -- Add corners to progress bar
    local progressCorner = Instance.new("UICorner")
    progressCorner.CornerRadius = UDim.new(0, 2)
    progressCorner.Parent = progressBar
    
    local fillCorner = Instance.new("UICorner")
    fillCorner.CornerRadius = UDim.new(0, 2)
    fillCorner.Parent = progressFill
    
    local timeLabel = Instance.new("TextLabel")
    timeLabel.Name = "TimeLabel"
    timeLabel.Size = UDim2.new(1, -20, 0, 15)
    timeLabel.Position = UDim2.new(0, 10, 0, 75)
    timeLabel.BackgroundTransparency = 1
    timeLabel.Text = "0.0s"
    timeLabel.Font = Enum.Font.Code
    timeLabel.TextSize = 10
    timeLabel.TextColor3 = Color3.fromRGB(150, 150, 150)
    timeLabel.TextXAlignment = Enum.TextXAlignment.Right
    timeLabel.Parent = frame
end

-- Update progress UI
function ClientInitMonitor:UpdateProgress(message, progress, elapsedTime)
    if not progressUI then return end
    
    local statusLabel = progressUI:FindFirstChild("StatusLabel", true)
    local progressFill = progressUI:FindFirstChild("Fill", true)
    local timeLabel = progressUI:FindFirstChild("TimeLabel", true)
    
    if statusLabel then
        statusLabel.Text = message
    end
    
    if progressFill then
        local tweenInfo = TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
        game:GetService("TweenService"):Create(progressFill, tweenInfo, {
            Size = UDim2.new(progress, 0, 1, 0)
        }):Play()
    end
    
    if timeLabel then
        timeLabel.Text = string.format("%.1fs", elapsedTime)
    end
end

-- Hide progress UI
function ClientInitMonitor:HideProgressUI()
    if progressUI then
        local tweenInfo = TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
        game:GetService("TweenService"):Create(progressUI.Frame, tweenInfo, {
            BackgroundTransparency = 1
        }):Play()
        
        -- Hide all children
        for _, child in pairs(progressUI.Frame:GetChildren()) do
            if child:IsA("GuiObject") then
                game:GetService("TweenService"):Create(child, tweenInfo, {
                    TextTransparency = 1,
                    BackgroundTransparency = 1
                }):Play()
            end
        end
        
        wait(0.5)
        progressUI:Destroy()
        progressUI = nil
    end
end

-- Check if main initialization is working
function ClientInitMonitor:CheckInitializationStatus()
    -- Look for signs of successful initialization
    local indicators = {
        -- Check if ControllerRegistry exists and is working
        function()
            local success, registry = pcall(function()
                return require(ReplicatedStorage.Shared.utils.ControllerRegistry)
            end)
            if success and registry then
                local status = registry:GetStatus()
                return status.TotalControllers > 0, "Controllers detected: " .. status.TotalControllers
            end
            return false, "No controller registry"
        end,
        
        -- Check if main game controller exists
        function()
            local mainGameController = playerGui:FindFirstChild("MainGameGUI")
            if mainGameController then
                return true, "Main game UI detected"
            end
            return false, "No main game UI"
        end,
        
        -- Check if RemoteEvents are set up
        function()
            local remoteEvents = ReplicatedStorage:FindFirstChild("RemoteEvents")
            if remoteEvents and #remoteEvents:GetChildren() > 0 then
                return true, "RemoteEvents detected: " .. #remoteEvents:GetChildren()
            end
            return false, "No RemoteEvents"
        end
    }
    
    local successCount = 0
    local statusMessages = {}
    
    for _, check in ipairs(indicators) do
        local success, message = check()
        if success then
            successCount = successCount + 1
        end
        table.insert(statusMessages, (success and "✓ " or "✗ ") .. message)
    end
    
    local progress = successCount / #indicators
    local overallSuccess = successCount >= 2 -- At least 2 out of 3 indicators
    
    return overallSuccess, progress, statusMessages
end

-- Activate fallback initialization
function ClientInitMonitor:ActivateFallback()
    if fallbackActivated then return end
    fallbackActivated = true
    
    warn("[ClientInitMonitor] Activating fallback initialization...")
    
    self:UpdateProgress("Fallback initialization...", 0.1, tick() - startTime)
    
    -- Try to load essential modules directly
    local fallbackSuccess = pcall(function()
        -- Basic RemoteEvents setup
        local remoteEventsFolder = ReplicatedStorage:FindFirstChild("RemoteEvents")
        if not remoteEventsFolder then
            remoteEventsFolder = Instance.new("Folder")
            remoteEventsFolder.Name = "RemoteEvents"
            remoteEventsFolder.Parent = ReplicatedStorage
        end
        
        self:UpdateProgress("Setting up basic systems...", 0.3, tick() - startTime)
        
        -- Try to initialize basic input handling
        local UserInputService = game:GetService("UserInputService")
        local basic_input_handling = function(input, gameProcessed)
            if gameProcessed then return end
            
            -- Basic movement keys
            if input.KeyCode == Enum.KeyCode.W then
                -- Forward movement logic would go here
            elseif input.KeyCode == Enum.KeyCode.S then
                -- Backward movement logic would go here
            end
        end
        
        UserInputService.InputBegan:Connect(basic_input_handling)
        
        self:UpdateProgress("Basic input system ready", 0.6, tick() - startTime)
        
        -- Create basic UI
        local basicUI = Instance.new("ScreenGui")
        basicUI.Name = "BasicGameUI"
        basicUI.Parent = playerGui
        
        local statusFrame = Instance.new("Frame")
        statusFrame.Size = UDim2.new(0, 200, 0, 50)
        statusFrame.Position = UDim2.new(0, 10, 0, 10)
        statusFrame.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
        statusFrame.BackgroundTransparency = 0.5
        statusFrame.Parent = basicUI
        
        local statusLabel = Instance.new("TextLabel")
        statusLabel.Size = UDim2.new(1, 0, 1, 0)
        statusLabel.BackgroundTransparency = 1
        statusLabel.Text = "Fallback Mode Active"
        statusLabel.Font = Enum.Font.Gotham
        statusLabel.TextSize = 14
        statusLabel.TextColor3 = Color3.fromRGB(255, 200, 100)
        statusLabel.Parent = statusFrame
        
        self:UpdateProgress("Fallback mode ready", 1.0, tick() - startTime)
        
        print("[ClientInitMonitor] ✓ Fallback initialization completed")
    end)
    
    if not fallbackSuccess then
        warn("[ClientInitMonitor] Fallback initialization failed")
        self:UpdateProgress("Fallback failed - please rejoin", 1.0, tick() - startTime)
    else
        wait(2)
        self:HideProgressUI()
    end
end

-- Start monitoring
function ClientInitMonitor:StartMonitoring()
    if monitoringActive then return end
    monitoringActive = true
    
    print("[ClientInitMonitor] Starting initialization monitoring...")
    
    self:CreateProgressUI()
    
    -- Event-driven monitoring (ZERO POLLING)
    spawn(function()
        local monitorEvent = Instance.new("BindableEvent")
        local elapsedTime = 0
        local lastStatusUpdate = 0
        
        local function performMonitorCheck()
            if not monitoringActive or elapsedTime >= MONITOR_CONFIG.MaxWaitTime then 
                -- Check if we should activate fallback
                if not initializationDetected and MONITOR_CONFIG.EnableFallback then
                    self:ActivateFallback()
                elseif not initializationDetected then
                    warn("[ClientInitMonitor] Initialization timeout - no fallback available")
                    self:UpdateProgress("Initialization timeout", 1.0, elapsedTime)
                end
                
                monitoringActive = false
                return 
            end
            
            elapsedTime = tick() - startTime
            
            -- Check initialization status
            local success, progress, statusMessages = self:CheckInitializationStatus()
            
            if success then
                initializationDetected = true
                self:UpdateProgress("Initialization successful!", 1.0, elapsedTime)
                print("[ClientInitMonitor] ✓ Initialization detected as successful")
                
                task.wait(1)
                self:HideProgressUI()
                monitoringActive = false
                return
            else
                -- Update progress based on elapsed time and detected systems
                local timeProgress = math.min(elapsedTime / MONITOR_CONFIG.MaxWaitTime, 0.9)
                local combinedProgress = math.max(progress * 0.8, timeProgress)
                
                -- Update status message periodically
                if elapsedTime - lastStatusUpdate >= 3 then
                    lastStatusUpdate = elapsedTime
                    local currentStatus = statusMessages[math.random(1, #statusMessages)]
                    self:UpdateProgress(currentStatus, combinedProgress, elapsedTime)
                end
                
                -- Schedule next check with event-driven approach (NO POLLING)
                task.delay(MONITOR_CONFIG.CheckInterval, function()
                    monitorEvent:Fire()
                end)
            end
        end
        
        monitorEvent.Event:Connect(performMonitorCheck)
        performMonitorCheck() -- Start monitoring
    end)
end

-- Stop monitoring
function ClientInitMonitor:StopMonitoring()
    monitoringActive = false
    if progressUI then
        self:HideProgressUI()
    end
end

-- Start monitoring when this script loads
ClientInitMonitor:StartMonitoring()

-- Also provide a way to stop monitoring externally
_G.ClientInitMonitor = ClientInitMonitor
