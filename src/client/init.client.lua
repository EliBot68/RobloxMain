-- init.client.lua
-- Enterprise client initialization following Rojo conventions
-- This is the main client entry point that Rojo will recognize

print("🏢 [Client] Loading Enterprise Color Rush Client...")

-- Essential Roblox Services
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local StarterGui = game:GetService("StarterGui")

-- Player references
local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- Wait for shared modules to be available
local SharedFolder = ReplicatedStorage:WaitForChild("Shared", 10)
if not SharedFolder then
    error("🚨 [Client] Failed to load shared modules from ReplicatedStorage!")
end

print("✅ [Client] Shared modules loaded from ReplicatedStorage")

-- ========================================
-- ENTERPRISE CLIENT FRAMEWORK
-- ========================================

local EnterpriseClient = {}
local clientMetrics = {
    startTime = tick(),
    controllersLoaded = 0,
    totalControllers = 0,
    failedControllers = 0,
    initializationTime = 0
}

-- Safe require function
local function SafeRequire(moduleScript, defaultValue)
    local success, result = pcall(require, moduleScript)
    if success then
        return result
    else
        warn("⚠️ [Client] Failed to require:", moduleScript.Name, "-", result)
        return defaultValue or {}
    end
end

-- ========================================
-- ENTERPRISE UI SYSTEM
-- ========================================

local EnterpriseUI = {}

function EnterpriseUI:Initialize()
    print("🎨 [Client] Initializing Enterprise UI System...")
    
    -- Create main interface container
    self.mainGui = self:CreateMainInterface()
    
    -- Setup performance monitor
    self.performanceMonitor = self:CreatePerformanceMonitor()
    
    -- Setup mobile optimization
    self:ApplyMobileOptimizations()
    
    print("✅ [Client] Enterprise UI System initialized")
end

function EnterpriseUI:CreateMainInterface()
    local mainGui = Instance.new("ScreenGui")
    mainGui.Name = "EnterpriseMainInterface"
    mainGui.ResetOnSpawn = false
    mainGui.IgnoreGuiInset = true
    mainGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    mainGui.Parent = playerGui
    
    -- Create HUD container
    local hudFrame = Instance.new("Frame")
    hudFrame.Name = "HUD"
    hudFrame.Size = UDim2.new(1, 0, 1, 0)
    hudFrame.BackgroundTransparency = 1
    hudFrame.Parent = mainGui
    
    print("🎨 [Client] Main interface created")
    return mainGui
end

function EnterpriseUI:CreatePerformanceMonitor()
    local monitor = Instance.new("Frame")
    monitor.Name = "PerformanceMonitor"
    monitor.Size = UDim2.new(0, 220, 0, 120)
    monitor.Position = UDim2.new(1, -230, 0, 10)
    monitor.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    monitor.BackgroundTransparency = 0.8
    monitor.BorderSizePixel = 0
    monitor.Visible = false -- Hidden by default
    monitor.Parent = self.mainGui
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 8)
    corner.Parent = monitor
    
    -- Title
    local title = Instance.new("TextLabel")
    title.Name = "Title"
    title.Size = UDim2.new(1, 0, 0, 20)
    title.Position = UDim2.new(0, 0, 0, 5)
    title.BackgroundTransparency = 1
    title.Text = "📊 Performance Monitor"
    title.TextColor3 = Color3.fromRGB(255, 255, 255)
    title.TextScaled = true
    title.Font = Enum.Font.GothamMedium
    title.Parent = monitor
    
    -- FPS counter
    local fpsLabel = Instance.new("TextLabel")
    fpsLabel.Name = "FPS"
    fpsLabel.Size = UDim2.new(1, 0, 0, 20)
    fpsLabel.Position = UDim2.new(0, 0, 0, 25)
    fpsLabel.BackgroundTransparency = 1
    fpsLabel.Text = "FPS: --"
    fpsLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    fpsLabel.TextScaled = true
    fpsLabel.Font = Enum.Font.Gotham
    fpsLabel.Parent = monitor
    
    -- Memory usage
    local memoryLabel = Instance.new("TextLabel")
    memoryLabel.Name = "Memory"
    memoryLabel.Size = UDim2.new(1, 0, 0, 20)
    memoryLabel.Position = UDim2.new(0, 0, 0, 45)
    memoryLabel.BackgroundTransparency = 1
    memoryLabel.Text = "Memory: --MB"
    memoryLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    memoryLabel.TextScaled = true
    memoryLabel.Font = Enum.Font.Gotham
    memoryLabel.Parent = monitor
    
    -- Player count
    local playersLabel = Instance.new("TextLabel")
    playersLabel.Name = "Players"
    playersLabel.Size = UDim2.new(1, 0, 0, 20)
    playersLabel.Position = UDim2.new(0, 0, 0, 65)
    playersLabel.BackgroundTransparency = 1
    playersLabel.Text = "Players: --"
    playersLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    playersLabel.TextScaled = true
    playersLabel.Font = Enum.Font.Gotham
    playersLabel.Parent = monitor
    
    -- Toggle button
    local toggleButton = Instance.new("TextButton")
    toggleButton.Name = "ToggleButton"
    toggleButton.Size = UDim2.new(0, 60, 0, 20)
    toggleButton.Position = UDim2.new(1, -70, 0, 10)
    toggleButton.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
    toggleButton.Text = "📊"
    toggleButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    toggleButton.Font = Enum.Font.GothamMedium
    toggleButton.TextScaled = true
    toggleButton.Parent = playerGui
    
    local toggleCorner = Instance.new("UICorner")
    toggleCorner.CornerRadius = UDim.new(0, 4)
    toggleCorner.Parent = toggleButton
    
    toggleButton.Activated:Connect(function()
        monitor.Visible = not monitor.Visible
    end)
    
    -- Update performance metrics
    spawn(function()
        local lastTime = tick()
        local frameCount = 0
        
        RunService.Heartbeat:Connect(function()
            frameCount = frameCount + 1
            local currentTime = tick()
            
            if currentTime - lastTime >= 1 then
                local fps = frameCount / (currentTime - lastTime)
                fpsLabel.Text = string.format("FPS: %d", math.floor(fps))
                
                -- Color code FPS
                if fps >= 55 then
                    fpsLabel.TextColor3 = Color3.fromRGB(0, 255, 0) -- Green
                elseif fps >= 30 then
                    fpsLabel.TextColor3 = Color3.fromRGB(255, 255, 0) -- Yellow
                else
                    fpsLabel.TextColor3 = Color3.fromRGB(255, 0, 0) -- Red
                end
                
                -- Update memory usage
                local memoryUsage = gcinfo()
                memoryLabel.Text = string.format("Memory: %.1fMB", memoryUsage)
                
                -- Update player count
                local playerCount = #Players:GetPlayers()
                playersLabel.Text = string.format("Players: %d", playerCount)
                
                frameCount = 0
                lastTime = currentTime
            end
        end)
    end)
    
    return monitor
end

function EnterpriseUI:ApplyMobileOptimizations()
    local deviceType = self:GetDeviceType()
    
    if deviceType == "Mobile" then
        print("📱 [Client] Applying mobile UI optimizations...")
        
        -- Adjust UI scaling for mobile
        if self.mainGui then
            local hudFrame = self.mainGui:FindFirstChild("HUD")
            if hudFrame then
                -- Create mobile-friendly UI adjustments
                local uiScale = Instance.new("UIScale")
                uiScale.Scale = 1.2 -- Slightly larger for mobile
                uiScale.Parent = hudFrame
            end
        end
        
        print("✅ [Client] Mobile UI optimizations applied")
    end
end

function EnterpriseUI:GetDeviceType()
    if UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled then
        return "Mobile"
    elseif UserInputService.GamepadEnabled then
        return "Console"
    else
        return "Desktop"
    end
end

-- ========================================
-- SERVER COMMUNICATION SYSTEM
-- ========================================

local EnterpriseComms = {}

function EnterpriseComms:Initialize()
    print("📡 [Client] Initializing Enterprise Communication System...")
    
    -- Wait for RemoteEvents
    local remoteEventsFolder = ReplicatedStorage:WaitForChild("RemoteEvents", 10)
    local remoteFunctionsFolder = ReplicatedStorage:WaitForChild("RemoteFunctions", 10)
    
    if remoteEventsFolder then
        self.remoteEvents = {}
        for _, remoteEvent in pairs(remoteEventsFolder:GetDescendants()) do
            if remoteEvent:IsA("RemoteEvent") then
                self.remoteEvents[remoteEvent.Name] = remoteEvent
            end
        end
        print("✅ [Client] RemoteEvents loaded:", #self.remoteEvents)
    end
    
    if remoteFunctionsFolder then
        self.remoteFunctions = {}
        for _, remoteFunction in pairs(remoteFunctionsFolder:GetDescendants()) do
            if remoteFunction:IsA("RemoteFunction") then
                self.remoteFunctions[remoteFunction.Name] = remoteFunction
            end
        end
        print("✅ [Client] RemoteFunctions loaded:", #self.remoteFunctions)
    end
    
    -- Setup event listeners
    self:SetupEventListeners()
    
    print("✅ [Client] Enterprise Communication System initialized")
end

function EnterpriseComms:SetupEventListeners()
    -- Listen for analytics events
    if self.remoteEvents.AnalyticsEvent then
        self.remoteEvents.AnalyticsEvent.OnClientEvent:Connect(function(eventType, eventData)
            print("📊 [Client] Analytics event received:", eventType)
        end)
    end
    
    -- Listen for player data sync
    if self.remoteEvents.PlayerDataSync then
        self.remoteEvents.PlayerDataSync.OnClientEvent:Connect(function(playerData)
            print("💾 [Client] Player data sync received")
            EnterpriseClient.playerData = playerData
        end)
    end
    
    -- Listen for security alerts
    if self.remoteEvents.SecurityAlert then
        self.remoteEvents.SecurityAlert.OnClientEvent:Connect(function(alertType, alertData)
            warn("🚨 [Client] Security alert:", alertType)
        end)
    end
end

function EnterpriseComms:SendAnalyticsEvent(eventType, eventData)
    if self.remoteEvents.AnalyticsEvent then
        self.remoteEvents.AnalyticsEvent:FireServer(eventType, eventData)
    end
end

function EnterpriseComms:GetPlayerData()
    if self.remoteFunctions.GetPlayerData then
        return self.remoteFunctions.GetPlayerData:InvokeServer()
    end
    return nil
end

-- ========================================
-- PERFORMANCE MONITORING
-- ========================================

local ClientPerformance = {}

function ClientPerformance:Initialize()
    print("📈 [Client] Initializing Performance Monitoring...")
    
    -- Start performance tracking
    spawn(function()
        while true do
            wait(10) -- Every 10 seconds
            
            local memoryUsage = gcinfo() * 1024 -- Convert to bytes
            local deviceType = EnterpriseUI:GetDeviceType()
            
            -- Send performance data to server
            EnterpriseComms:SendAnalyticsEvent("client_performance", {
                memoryUsage = memoryUsage,
                deviceType = deviceType,
                playerCount = #Players:GetPlayers(),
                timestamp = tick()
            })
        end
    end)
    
    print("✅ [Client] Performance Monitoring initialized")
end

-- ========================================
-- MOBILE OPTIMIZATION
-- ========================================

local MobileOptimization = {}

function MobileOptimization:Initialize()
    local deviceType = EnterpriseUI:GetDeviceType()
    
    if deviceType == "Mobile" then
        print("📱 [Client] Applying mobile optimizations...")
        
        -- Reduce rendering quality for mobile
        local lighting = game:GetService("Lighting")
        lighting.GlobalShadows = false
        
        -- Optimize workspace settings
        local workspace = game:GetService("Workspace")
        workspace.StreamingEnabled = true
        
        print("✅ [Client] Mobile optimizations applied")
    end
end

-- ========================================
-- ENTERPRISE CLIENT INITIALIZATION
-- ========================================

print("🔧 [Client] Starting enterprise client initialization...")

-- Initialize all systems
EnterpriseUI:Initialize()
EnterpriseComms:Initialize()
ClientPerformance:Initialize()
MobileOptimization:Initialize()

-- Calculate initialization metrics
clientMetrics.initializationTime = tick() - clientMetrics.startTime

-- Setup global access
EnterpriseClient.UI = EnterpriseUI
EnterpriseClient.Communications = EnterpriseComms
EnterpriseClient.Performance = ClientPerformance
EnterpriseClient.Mobile = MobileOptimization
EnterpriseClient.Metrics = clientMetrics

-- Export to global
_G.EnterpriseClient = EnterpriseClient

print("🎊 [Client] Enterprise Color Rush Client fully operational!")
print("   ⏱️ Initialization time:", math.floor(clientMetrics.initializationTime * 1000) .. "ms")
print("   📱 Device type:", EnterpriseUI:GetDeviceType())
print("   🏢 Enterprise client architecture: ACTIVE")

-- Send client startup analytics
EnterpriseComms:SendAnalyticsEvent("client_startup", {
    initializationTime = clientMetrics.initializationTime,
    deviceType = EnterpriseUI:GetDeviceType(),
    timestamp = tick()
})

-- ========================================
-- CHARACTER SPAWN HANDLING
-- ========================================

local function onCharacterAdded(character)
    print("🏃 [Client] Character spawned for enterprise client")
    
    -- Send analytics event
    EnterpriseComms:SendAnalyticsEvent("character_spawned", {
        characterName = character.Name,
        spawnTime = tick(),
        deviceType = EnterpriseUI:GetDeviceType()
    })
    
    -- Setup character-specific systems
    spawn(function()
        local humanoid = character:WaitForChild("Humanoid", 5)
        if humanoid then
            -- Setup movement tracking or other character systems
            print("✅ [Client] Character systems initialized")
        end
    end)
end

-- Connect character events
if player.Character then
    onCharacterAdded(player.Character)
end
player.CharacterAdded:Connect(onCharacterAdded)

-- ========================================
-- ERROR HANDLING
-- ========================================

local function handleClientError(message, trace)
    EnterpriseComms:SendAnalyticsEvent("client_error", {
        message = message,
        trace = trace,
        deviceType = EnterpriseUI:GetDeviceType(),
        timestamp = os.time()
    })
    
    warn("🚨 [Client] Error occurred:", message)
end

-- Setup error handling
pcall(function()
    game:GetService("ScriptContext").Error:Connect(handleClientError)
end)

print("🌟 [Client] Enterprise client is ready for action!")
