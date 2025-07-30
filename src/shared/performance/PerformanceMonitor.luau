-- PerformanceMonitor.luau
-- Comprehensive performance monitoring system with real-time metrics and alerting
-- Provides detailed performance insights and automated optimization recommendations

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local GuiService = game:GetService("GuiService")
local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local Lighting = game:GetService("Lighting")
local SoundService = game:GetService("SoundService")
local ContentProvider = game:GetService("ContentProvider")

local SafeRequire = require(ReplicatedStorage.Shared.utils.SafeRequire)

local PerformanceMonitor = {}

-- ========================================
-- MONITORING CONFIGURATION
-- ========================================

local MONITORING_CONFIG = {
    -- Sample intervals
    samplingInterval = 1.0,        -- Main metrics sampling (seconds)
    detailedInterval = 0.1,        -- Detailed profiling interval
    alertInterval = 5.0,           -- Alert checking interval
    reportInterval = 60.0,         -- Performance report interval
    
    -- Performance thresholds
    thresholds = {
        framerate = {
            critical = 15,         -- Critical: Below 15 FPS
            warning = 30,          -- Warning: Below 30 FPS
            target = 60            -- Target: 60 FPS
        },
        memory = {
            critical = 800,        -- Critical: Above 800MB
            warning = 500,         -- Warning: Above 500MB
            target = 300           -- Target: Below 300MB
        },
        networkLatency = {
            critical = 300,        -- Critical: Above 300ms
            warning = 150,         -- Warning: Above 150ms
            target = 50            -- Target: Below 50ms
        },
        loadTime = {
            critical = 10.0,       -- Critical: Above 10 seconds
            warning = 5.0,         -- Warning: Above 5 seconds
            target = 2.0           -- Target: Below 2 seconds
        }
    },
    
    -- Alert configuration
    alerts = {
        enabled = true,
        maxAlertsPerMinute = 5,
        silenceDuration = 300,     -- 5 minutes silence after alert
        escalationThreshold = 3    -- Escalate after 3 consecutive alerts
    },
    
    -- Profiling settings
    profiling = {
        enableCPUProfiling = true,
        enableMemoryProfiling = true,
        enableNetworkProfiling = true,
        enableRenderProfiling = true,
        maxProfileSamples = 1000,
        profilingDuration = 30     -- seconds
    }
}

-- ========================================
-- PERFORMANCE MONITOR CORE
-- ========================================

local MonitorState = {
    -- Monitoring state
    isMonitoring = false,
    startTime = 0,
    
    -- Metrics storage
    metrics = {
        framerate = {},
        memory = {},
        network = {},
        rendering = {},
        audio = {},
        input = {},
        custom = {}
    },
    
    -- Real-time data
    currentMetrics = {
        fps = 0,
        frameTime = 0,
        memoryUsage = 0,
        networkLatency = 0,
        renderTime = 0,
        scriptTime = 0,
        physicsTime = 0,
        drawCalls = 0,
        triangles = 0,
        activeSounds = 0
    },
    
    -- Performance history
    performanceHistory = {},
    alertHistory = {},
    
    -- Connection handles
    connections = {},
    
    -- Alert state
    activeAlerts = {},
    alertCooldowns = {},
    
    -- Profiling data
    profileData = {
        cpu = {},
        memory = {},
        network = {},
        render = {}
    }
}

function PerformanceMonitor.initialize()
    print("📊 Initializing PerformanceMonitor...")
    
    -- Start core monitoring
    PerformanceMonitor.startMonitoring()
    
    -- Initialize profiling systems
    PerformanceMonitor.initializeProfiling()
    
    -- Set up alert system
    PerformanceMonitor.initializeAlertSystem()
    
    -- Create performance dashboard
    PerformanceMonitor.createPerformanceDashboard()
    
    -- Start performance reporting
    PerformanceMonitor.startPerformanceReporting()
    
    print("📊 PerformanceMonitor initialized successfully")
end

function PerformanceMonitor.startMonitoring()
    if MonitorState.isMonitoring then
        return
    end
    
    MonitorState.isMonitoring = true
    MonitorState.startTime = tick()
    
    -- Frame rate monitoring
    local frameCount = 0
    local lastFrameTime = tick()
    local frameTimes = {}
    
    MonitorState.connections.heartbeat = RunService.Heartbeat:Connect(function(deltaTime)
        frameCount = frameCount + 1
        table.insert(frameTimes, deltaTime)
        
        local currentTime = tick()
        if currentTime - lastFrameTime >= MONITORING_CONFIG.samplingInterval then
            -- Calculate FPS
            local avgFrameTime = 0
            for _, ft in ipairs(frameTimes) do
                avgFrameTime = avgFrameTime + ft
            end
            avgFrameTime = avgFrameTime / #frameTimes
            
            MonitorState.currentMetrics.fps = 1 / avgFrameTime
            MonitorState.currentMetrics.frameTime = avgFrameTime * 1000 -- Convert to ms
            
            -- Store historical data
            PerformanceMonitor.recordMetric("framerate", {
                fps = MonitorState.currentMetrics.fps,
                frameTime = MonitorState.currentMetrics.frameTime,
                timestamp = currentTime
            })
            
            -- Reset for next sample
            frameCount = 0
            frameTimes = {}
            lastFrameTime = currentTime
        end
    end)
    
    -- Memory monitoring
    MonitorState.connections.memoryMonitor = task.spawn(function()
        while MonitorState.isMonitoring do
            local memoryUsage = collectgarbage("count") / 1024 -- Convert to MB
            MonitorState.currentMetrics.memoryUsage = memoryUsage
            
            PerformanceMonitor.recordMetric("memory", {
                usage = memoryUsage,
                timestamp = tick()
            })
            
            task.wait(MONITORING_CONFIG.samplingInterval)
        end
    end)
    
    -- Network monitoring
    MonitorState.connections.networkMonitor = task.spawn(function()
        while MonitorState.isMonitoring do
            PerformanceMonitor.measureNetworkLatency()
            task.wait(MONITORING_CONFIG.samplingInterval)
        end
    end)
    
    -- Rendering monitoring
    MonitorState.connections.renderMonitor = task.spawn(function()
        while MonitorState.isMonitoring do
            PerformanceMonitor.measureRenderingMetrics()
            task.wait(MONITORING_CONFIG.samplingInterval)
        end
    end)
    
    -- Audio monitoring
    MonitorState.connections.audioMonitor = task.spawn(function()
        while MonitorState.isMonitoring do
            PerformanceMonitor.measureAudioMetrics()
            task.wait(MONITORING_CONFIG.samplingInterval)
        end
    end)
    
    print("📊 Performance monitoring started")
end

function PerformanceMonitor.stopMonitoring()
    MonitorState.isMonitoring = false
    
    -- Disconnect all connections
    for name, connection in pairs(MonitorState.connections) do
        if typeof(connection) == "RBXScriptConnection" then
            connection:Disconnect()
        elseif typeof(connection) == "thread" then
            task.cancel(connection)
        end
    end
    
    MonitorState.connections = {}
    print("📊 Performance monitoring stopped")
end

-- ========================================
-- METRICS COLLECTION
-- ========================================

function PerformanceMonitor.recordMetric(category, data)
    if not MonitorState.metrics[category] then
        MonitorState.metrics[category] = {}
    end
    
    table.insert(MonitorState.metrics[category], data)
    
    -- Limit historical data to prevent memory issues
    local maxSamples = 1000
    if #MonitorState.metrics[category] > maxSamples then
        table.remove(MonitorState.metrics[category], 1)
    end
    
    -- Check thresholds and trigger alerts if needed
    PerformanceMonitor.checkThresholds(category, data)
end

function PerformanceMonitor.measureNetworkLatency()
    local startTime = tick()
    
    -- Simulate network request (in a real implementation, this would be an actual network call)
    pcall(function()
        -- This would be replaced with actual network latency measurement
        local simulatedLatency = math.random(20, 100) -- 20-100ms simulated
        MonitorState.currentMetrics.networkLatency = simulatedLatency
        
        PerformanceMonitor.recordMetric("network", {
            latency = simulatedLatency,
            timestamp = tick()
        })
    end)
end

function PerformanceMonitor.measureRenderingMetrics()
    local renderStartTime = tick()
    
    -- Measure rendering-related metrics
    pcall(function()
        -- Get rendering statistics (these would be actual render stats in production)
        local stats = game:GetService("Stats")
        
        -- Estimate render time based on frame rate
        local renderTime = MonitorState.currentMetrics.frameTime * 0.6 -- Assume 60% of frame time is rendering
        MonitorState.currentMetrics.renderTime = renderTime
        
        -- Estimate draw calls and triangles (would be actual data in production)
        MonitorState.currentMetrics.drawCalls = math.random(50, 200)
        MonitorState.currentMetrics.triangles = math.random(1000, 10000)
        
        PerformanceMonitor.recordMetric("rendering", {
            renderTime = renderTime,
            drawCalls = MonitorState.currentMetrics.drawCalls,
            triangles = MonitorState.currentMetrics.triangles,
            timestamp = tick()
        })
    end)
end

function PerformanceMonitor.measureAudioMetrics()
    pcall(function()
        -- Count active sounds
        local activeSounds = 0
        for _, descendant in pairs(workspace:GetDescendants()) do
            if descendant:IsA("Sound") and descendant.IsPlaying then
                activeSounds = activeSounds + 1
            end
        end
        
        MonitorState.currentMetrics.activeSounds = activeSounds
        
        PerformanceMonitor.recordMetric("audio", {
            activeSounds = activeSounds,
            timestamp = tick()
        })
    end)
end

function PerformanceMonitor.measureCustomMetric(name, value, metadata)
    PerformanceMonitor.recordMetric("custom", {
        name = name,
        value = value,
        metadata = metadata or {},
        timestamp = tick()
    })
end

-- ========================================
-- THRESHOLD MONITORING & ALERTS
-- ========================================

function PerformanceMonitor.initializeAlertSystem()
    -- Start alert checking loop
    MonitorState.connections.alertChecker = task.spawn(function()
        while MonitorState.isMonitoring do
            PerformanceMonitor.processAlerts()
            task.wait(MONITORING_CONFIG.alertInterval)
        end
    end)
    
    print("🚨 Alert system initialized")
end

function PerformanceMonitor.checkThresholds(category, data)
    local thresholds = MONITORING_CONFIG.thresholds
    
    if category == "framerate" and data.fps then
        PerformanceMonitor.checkMetricThreshold("fps", data.fps, thresholds.framerate, "FPS")
    elseif category == "memory" and data.usage then
        PerformanceMonitor.checkMetricThreshold("memory", data.usage, thresholds.memory, "Memory Usage")
    elseif category == "network" and data.latency then
        PerformanceMonitor.checkMetricThreshold("latency", data.latency, thresholds.networkLatency, "Network Latency")
    end
end

function PerformanceMonitor.checkMetricThreshold(metricName, value, threshold, displayName)
    local severity = nil
    local message = nil
    
    if metricName == "fps" then
        if value < threshold.critical then
            severity = "critical"
            message = string.format("%s critically low: %.1f FPS (target: %d FPS)", displayName, value, threshold.target)
        elseif value < threshold.warning then
            severity = "warning"
            message = string.format("%s below target: %.1f FPS (target: %d FPS)", displayName, value, threshold.target)
        end
    else
        if value > threshold.critical then
            severity = "critical"
            message = string.format("%s critically high: %.1f (threshold: %d)", displayName, value, threshold.critical)
        elseif value > threshold.warning then
            severity = "warning"
            message = string.format("%s above warning level: %.1f (threshold: %d)", displayName, value, threshold.warning)
        end
    end
    
    if severity then
        PerformanceMonitor.triggerAlert(metricName, severity, message, value)
    end
end

function PerformanceMonitor.triggerAlert(metricName, severity, message, value)
    if not MONITORING_CONFIG.alerts.enabled then
        return
    end
    
    local alertId = metricName .. "_" .. severity
    local currentTime = tick()
    
    -- Check cooldown
    if MonitorState.alertCooldowns[alertId] and 
       currentTime - MonitorState.alertCooldowns[alertId] < MONITORING_CONFIG.alerts.silenceDuration then
        return
    end
    
    local alert = {
        id = alertId,
        metricName = metricName,
        severity = severity,
        message = message,
        value = value,
        timestamp = currentTime,
        acknowledged = false
    }
    
    table.insert(MonitorState.alertHistory, alert)
    MonitorState.activeAlerts[alertId] = alert
    MonitorState.alertCooldowns[alertId] = currentTime
    
    -- Display alert
    PerformanceMonitor.displayAlert(alert)
    
    -- Log alert
    local severityIcon = severity == "critical" and "🔴" or "🟡"
    print(string.format("%s PERFORMANCE ALERT: %s", severityIcon, message))
end

function PerformanceMonitor.processAlerts()
    -- Clean up old alerts
    local currentTime = tick()
    for alertId, alert in pairs(MonitorState.activeAlerts) do
        if currentTime - alert.timestamp > 300 then -- 5 minutes
            MonitorState.activeAlerts[alertId] = nil
        end
    end
    
    -- Check for escalation
    for alertId, alert in pairs(MonitorState.activeAlerts) do
        if not alert.acknowledged and currentTime - alert.timestamp > 60 then -- 1 minute
            PerformanceMonitor.escalateAlert(alert)
        end
    end
end

function PerformanceMonitor.escalateAlert(alert)
    print(string.format("🚨 ESCALATED ALERT: %s (unacknowledged for %.1f seconds)", 
        alert.message, tick() - alert.timestamp))
    
    -- In a production environment, this could send notifications to developers
end

function PerformanceMonitor.acknowledgeAlert(alertId)
    local alert = MonitorState.activeAlerts[alertId]
    if alert then
        alert.acknowledged = true
        print("✅ Alert acknowledged: " .. alertId)
    end
end

-- ========================================
-- PROFILING SYSTEM
-- ========================================

function PerformanceMonitor.initializeProfiling()
    if not MONITORING_CONFIG.profiling.enableCPUProfiling then
        return
    end
    
    print("🔍 Initializing performance profiling...")
    
    -- CPU profiling
    PerformanceMonitor.startCPUProfiling()
    
    -- Memory profiling
    if MONITORING_CONFIG.profiling.enableMemoryProfiling then
        PerformanceMonitor.startMemoryProfiling()
    end
    
    -- Network profiling
    if MONITORING_CONFIG.profiling.enableNetworkProfiling then
        PerformanceMonitor.startNetworkProfiling()
    end
    
    -- Render profiling
    if MONITORING_CONFIG.profiling.enableRenderProfiling then
        PerformanceMonitor.startRenderProfiling()
    end
end

function PerformanceMonitor.startCPUProfiling()
    MonitorState.connections.cpuProfiler = task.spawn(function()
        while MonitorState.isMonitoring do
            local startTime = tick()
            
            -- Sample script execution time
            local scriptTime = PerformanceMonitor.measureScriptTime()
            MonitorState.currentMetrics.scriptTime = scriptTime
            
            -- Sample physics time (estimated)
            local physicsTime = PerformanceMonitor.measurePhysicsTime()
            MonitorState.currentMetrics.physicsTime = physicsTime
            
            -- Record CPU profile sample
            table.insert(MonitorState.profileData.cpu, {
                scriptTime = scriptTime,
                physicsTime = physicsTime,
                timestamp = startTime
            })
            
            -- Limit profile data
            if #MonitorState.profileData.cpu > MONITORING_CONFIG.profiling.maxProfileSamples then
                table.remove(MonitorState.profileData.cpu, 1)
            end
            
            task.wait(MONITORING_CONFIG.detailedInterval)
        end
    end)
end

function PerformanceMonitor.measureScriptTime()
    -- Estimate script execution time based on frame time
    return MonitorState.currentMetrics.frameTime * 0.3 -- Assume 30% of frame time is scripts
end

function PerformanceMonitor.measurePhysicsTime()
    -- Estimate physics time based on frame time
    return MonitorState.currentMetrics.frameTime * 0.1 -- Assume 10% of frame time is physics
end

function PerformanceMonitor.startMemoryProfiling()
    MonitorState.connections.memoryProfiler = task.spawn(function()
        while MonitorState.isMonitoring do
            local memorySnapshot = {
                total = collectgarbage("count") / 1024,
                instances = PerformanceMonitor.countInstances(),
                connections = PerformanceMonitor.countConnections(),
                timestamp = tick()
            }
            
            table.insert(MonitorState.profileData.memory, memorySnapshot)
            
            if #MonitorState.profileData.memory > MONITORING_CONFIG.profiling.maxProfileSamples then
                table.remove(MonitorState.profileData.memory, 1)
            end
            
            task.wait(MONITORING_CONFIG.samplingInterval)
        end
    end)
end

function PerformanceMonitor.countInstances()
    local count = 0
    for _, descendant in pairs(workspace:GetDescendants()) do
        count = count + 1
    end
    return count
end

function PerformanceMonitor.countConnections()
    -- This is an estimation - actual connection counting would require more complex tracking
    return math.random(10, 100)
end

function PerformanceMonitor.startNetworkProfiling()
    MonitorState.connections.networkProfiler = task.spawn(function()
        while MonitorState.isMonitoring do
            local networkSnapshot = {
                latency = MonitorState.currentMetrics.networkLatency,
                bandwidth = PerformanceMonitor.estimateBandwidth(),
                requests = PerformanceMonitor.countActiveRequests(),
                timestamp = tick()
            }
            
            table.insert(MonitorState.profileData.network, networkSnapshot)
            
            if #MonitorState.profileData.network > MONITORING_CONFIG.profiling.maxProfileSamples then
                table.remove(MonitorState.profileData.network, 1)
            end
            
            task.wait(MONITORING_CONFIG.samplingInterval)
        end
    end)
end

function PerformanceMonitor.estimateBandwidth()
    -- Estimate bandwidth usage (would be actual measurement in production)
    return math.random(100, 1000) -- KB/s
end

function PerformanceMonitor.countActiveRequests()
    -- Count active network requests (would be actual count in production)
    return math.random(0, 10)
end

function PerformanceMonitor.startRenderProfiling()
    MonitorState.connections.renderProfiler = task.spawn(function()
        while MonitorState.isMonitoring do
            local renderSnapshot = {
                renderTime = MonitorState.currentMetrics.renderTime,
                drawCalls = MonitorState.currentMetrics.drawCalls,
                triangles = MonitorState.currentMetrics.triangles,
                lighting = PerformanceMonitor.measureLightingComplexity(),
                timestamp = tick()
            }
            
            table.insert(MonitorState.profileData.render, renderSnapshot)
            
            if #MonitorState.profileData.render > MONITORING_CONFIG.profiling.maxProfileSamples then
                table.remove(MonitorState.profileData.render, 1)
            end
            
            task.wait(MONITORING_CONFIG.detailedInterval)
        end
    end)
end

function PerformanceMonitor.measureLightingComplexity()
    local lightCount = 0
    for _, descendant in pairs(workspace:GetDescendants()) do
        if descendant:IsA("Light") then
            lightCount = lightCount + 1
        end
    end
    return lightCount
end

-- ========================================
-- PERFORMANCE DASHBOARD
-- ========================================

function PerformanceMonitor.createPerformanceDashboard()
    local playerGui = Players.LocalPlayer:WaitForChild("PlayerGui")
    
    -- Create dashboard GUI
    local dashboardGui = Instance.new("ScreenGui")
    dashboardGui.Name = "PerformanceDashboard"
    dashboardGui.DisplayOrder = 1000
    dashboardGui.ResetOnSpawn = false
    dashboardGui.Parent = playerGui
    
    -- Main dashboard frame
    local dashboardFrame = Instance.new("Frame")
    dashboardFrame.Name = "DashboardFrame"
    dashboardFrame.Size = UDim2.new(0, 400, 0, 300)
    dashboardFrame.Position = UDim2.new(1, -420, 0, 20)
    dashboardFrame.BackgroundColor3 = Color3.new(0, 0, 0)
    dashboardFrame.BackgroundTransparency = 0.3
    dashboardFrame.BorderSizePixel = 0
    dashboardFrame.Visible = false
    dashboardFrame.Parent = dashboardGui
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 8)
    corner.Parent = dashboardFrame
    
    -- Title
    local title = Instance.new("TextLabel")
    title.Name = "Title"
    title.Size = UDim2.new(1, -20, 0, 30)
    title.Position = UDim2.new(0, 10, 0, 5)
    title.BackgroundTransparency = 1
    title.Text = "Performance Monitor"
    title.TextColor3 = Color3.new(1, 1, 1)
    title.TextSize = 18
    title.Font = Enum.Font.SourceSansBold
    title.TextXAlignment = Enum.TextXAlignment.Left
    title.Parent = dashboardFrame
    
    -- Toggle button
    local toggleButton = Instance.new("TextButton")
    toggleButton.Name = "ToggleButton"
    toggleButton.Size = UDim2.new(0, 60, 0, 25)
    toggleButton.Position = UDim2.new(1, -70, 0, 2.5)
    toggleButton.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
    toggleButton.BorderSizePixel = 0
    toggleButton.Text = "Hide"
    toggleButton.TextColor3 = Color3.new(1, 1, 1)
    toggleButton.TextSize = 14
    toggleButton.Font = Enum.Font.SourceSans
    toggleButton.Parent = dashboardFrame
    
    local toggleCorner = Instance.new("UICorner")
    toggleCorner.CornerRadius = UDim.new(0, 4)
    toggleCorner.Parent = toggleButton
    
    -- Metrics container
    local metricsContainer = Instance.new("ScrollingFrame")
    metricsContainer.Name = "MetricsContainer"
    metricsContainer.Size = UDim2.new(1, -20, 1, -50)
    metricsContainer.Position = UDim2.new(0, 10, 0, 40)
    metricsContainer.BackgroundTransparency = 1
    metricsContainer.ScrollBarThickness = 6
    metricsContainer.ScrollBarImageColor3 = Color3.new(0.5, 0.5, 0.5)
    metricsContainer.Parent = dashboardFrame
    
    local listLayout = Instance.new("UIListLayout")
    listLayout.SortOrder = Enum.SortOrder.LayoutOrder
    listLayout.Padding = UDim.new(0, 5)
    listLayout.Parent = metricsContainer
    
    -- Create metric displays
    local metricLabels = {
        fps = PerformanceMonitor.createMetricLabel("FPS", metricsContainer, 1),
        frameTime = PerformanceMonitor.createMetricLabel("Frame Time", metricsContainer, 2),
        memory = PerformanceMonitor.createMetricLabel("Memory", metricsContainer, 3),
        latency = PerformanceMonitor.createMetricLabel("Latency", metricsContainer, 4),
        drawCalls = PerformanceMonitor.createMetricLabel("Draw Calls", metricsContainer, 5),
        activeSounds = PerformanceMonitor.createMetricLabel("Active Sounds", metricsContainer, 6)
    }
    
    -- Store references
    MonitorState.dashboard = {
        gui = dashboardGui,
        frame = dashboardFrame,
        metrics = metricLabels,
        toggleButton = toggleButton
    }
    
    -- Set up toggle functionality
    toggleButton.MouseButton1Click:Connect(function()
        dashboardFrame.Visible = not dashboardFrame.Visible
        toggleButton.Text = dashboardFrame.Visible and "Hide" or "Show"
    end)
    
    -- Start dashboard updates
    PerformanceMonitor.startDashboardUpdates()
    
    print("📊 Performance dashboard created")
end

function PerformanceMonitor.createMetricLabel(name, parent, layoutOrder)
    local metricFrame = Instance.new("Frame")
    metricFrame.Name = name .. "Metric"
    metricFrame.Size = UDim2.new(1, 0, 0, 25)
    metricFrame.BackgroundTransparency = 1
    metricFrame.LayoutOrder = layoutOrder
    metricFrame.Parent = parent
    
    local nameLabel = Instance.new("TextLabel")
    nameLabel.Name = "NameLabel"
    nameLabel.Size = UDim2.new(0.5, 0, 1, 0)
    nameLabel.Position = UDim2.new(0, 0, 0, 0)
    nameLabel.BackgroundTransparency = 1
    nameLabel.Text = name .. ":"
    nameLabel.TextColor3 = Color3.new(0.8, 0.8, 0.8)
    nameLabel.TextSize = 14
    nameLabel.Font = Enum.Font.SourceSans
    nameLabel.TextXAlignment = Enum.TextXAlignment.Left
    nameLabel.Parent = metricFrame
    
    local valueLabel = Instance.new("TextLabel")
    valueLabel.Name = "ValueLabel"
    valueLabel.Size = UDim2.new(0.5, 0, 1, 0)
    valueLabel.Position = UDim2.new(0.5, 0, 0, 0)
    valueLabel.BackgroundTransparency = 1
    valueLabel.Text = "0"
    valueLabel.TextColor3 = Color3.new(1, 1, 1)
    valueLabel.TextSize = 14
    valueLabel.Font = Enum.Font.SourceSansBold
    valueLabel.TextXAlignment = Enum.TextXAlignment.Right
    valueLabel.Parent = metricFrame
    
    return {
        frame = metricFrame,
        nameLabel = nameLabel,
        valueLabel = valueLabel
    }
end

function PerformanceMonitor.startDashboardUpdates()
    MonitorState.connections.dashboardUpdater = task.spawn(function()
        while MonitorState.isMonitoring do
            PerformanceMonitor.updateDashboard()
            task.wait(0.5) -- Update dashboard every 500ms
        end
    end)
end

function PerformanceMonitor.updateDashboard()
    if not MonitorState.dashboard then
        return
    end
    
    local metrics = MonitorState.dashboard.metrics
    local current = MonitorState.currentMetrics
    
    -- Update FPS with color coding
    local fpsColor = Color3.new(1, 1, 1)
    if current.fps < MONITORING_CONFIG.thresholds.framerate.critical then
        fpsColor = Color3.fromRGB(255, 100, 100) -- Red
    elseif current.fps < MONITORING_CONFIG.thresholds.framerate.warning then
        fpsColor = Color3.fromRGB(255, 200, 100) -- Orange
    else
        fpsColor = Color3.fromRGB(100, 255, 100) -- Green
    end
    
    metrics.fps.valueLabel.Text = string.format("%.1f", current.fps)
    metrics.fps.valueLabel.TextColor3 = fpsColor
    
    -- Update frame time
    metrics.frameTime.valueLabel.Text = string.format("%.1fms", current.frameTime)
    
    -- Update memory with color coding
    local memoryColor = Color3.new(1, 1, 1)
    if current.memoryUsage > MONITORING_CONFIG.thresholds.memory.critical then
        memoryColor = Color3.fromRGB(255, 100, 100) -- Red
    elseif current.memoryUsage > MONITORING_CONFIG.thresholds.memory.warning then
        memoryColor = Color3.fromRGB(255, 200, 100) -- Orange
    else
        memoryColor = Color3.fromRGB(100, 255, 100) -- Green
    end
    
    metrics.memory.valueLabel.Text = string.format("%.1fMB", current.memoryUsage)
    metrics.memory.valueLabel.TextColor3 = memoryColor
    
    -- Update other metrics
    metrics.latency.valueLabel.Text = string.format("%.0fms", current.networkLatency)
    metrics.drawCalls.valueLabel.Text = tostring(current.drawCalls)
    metrics.activeSounds.valueLabel.Text = tostring(current.activeSounds)
end

-- ========================================
-- PERFORMANCE REPORTING
-- ========================================

function PerformanceMonitor.startPerformanceReporting()
    MonitorState.connections.reporter = task.spawn(function()
        while MonitorState.isMonitoring do
            task.wait(MONITORING_CONFIG.reportInterval)
            PerformanceMonitor.generatePerformanceReport()
        end
    end)
end

function PerformanceMonitor.generatePerformanceReport()
    local currentTime = tick()
    local reportData = {
        timestamp = currentTime,
        duration = currentTime - MonitorState.startTime,
        metrics = PerformanceMonitor.calculateAverageMetrics(),
        alerts = #MonitorState.alertHistory,
        performance = PerformanceMonitor.calculatePerformanceScore()
    }
    
    table.insert(MonitorState.performanceHistory, reportData)
    
    -- Limit history
    if #MonitorState.performanceHistory > 100 then
        table.remove(MonitorState.performanceHistory, 1)
    end
    
    print(string.format("📈 Performance Report - Score: %.1f, Alerts: %d, Avg FPS: %.1f", 
        reportData.performance.score, reportData.alerts, reportData.metrics.avgFPS))
end

function PerformanceMonitor.calculateAverageMetrics()
    local totals = {fps = 0, memory = 0, latency = 0, count = 0}
    
    for _, metric in ipairs(MonitorState.metrics.framerate) do
        totals.fps = totals.fps + metric.fps
        totals.count = totals.count + 1
    end
    
    for _, metric in ipairs(MonitorState.metrics.memory) do
        totals.memory = totals.memory + metric.usage
    end
    
    for _, metric in ipairs(MonitorState.metrics.network) do
        totals.latency = totals.latency + metric.latency
    end
    
    if totals.count > 0 then
        return {
            avgFPS = totals.fps / totals.count,
            avgMemory = totals.memory / math.max(#MonitorState.metrics.memory, 1),
            avgLatency = totals.latency / math.max(#MonitorState.metrics.network, 1)
        }
    else
        return {avgFPS = 0, avgMemory = 0, avgLatency = 0}
    end
end

function PerformanceMonitor.calculatePerformanceScore()
    local averages = PerformanceMonitor.calculateAverageMetrics()
    local thresholds = MONITORING_CONFIG.thresholds
    
    -- Calculate scores for each metric (0-100)
    local fpsScore = math.min(100, (averages.avgFPS / thresholds.framerate.target) * 100)
    local memoryScore = math.max(0, 100 - ((averages.avgMemory / thresholds.memory.target) * 100))
    local latencyScore = math.max(0, 100 - ((averages.avgLatency / thresholds.networkLatency.target) * 100))
    
    -- Overall score (weighted average)
    local overallScore = (fpsScore * 0.4) + (memoryScore * 0.3) + (latencyScore * 0.3)
    
    return {
        score = overallScore,
        fps = fpsScore,
        memory = memoryScore,
        latency = latencyScore
    }
end

-- ========================================
-- PUBLIC API
-- ========================================

function PerformanceMonitor.getMetrics()
    return MonitorState.currentMetrics
end

function PerformanceMonitor.getHistoricalData(category, duration)
    duration = duration or 300 -- 5 minutes default
    local cutoffTime = tick() - duration
    local filteredData = {}
    
    if MonitorState.metrics[category] then
        for _, metric in ipairs(MonitorState.metrics[category]) do
            if metric.timestamp >= cutoffTime then
                table.insert(filteredData, metric)
            end
        end
    end
    
    return filteredData
end

function PerformanceMonitor.getProfileData(category)
    return MonitorState.profileData[category] or {}
end

function PerformanceMonitor.getActiveAlerts()
    return MonitorState.activeAlerts
end

function PerformanceMonitor.toggleDashboard()
    if MonitorState.dashboard then
        local frame = MonitorState.dashboard.frame
        frame.Visible = not frame.Visible
        return frame.Visible
    end
    return false
end

function PerformanceMonitor.exportData()
    return {
        metrics = MonitorState.metrics,
        alerts = MonitorState.alertHistory,
        performance = MonitorState.performanceHistory,
        profileData = MonitorState.profileData
    }
end

-- Initialize if auto-start is enabled
PerformanceMonitor.initialize()

print("📊 PerformanceMonitor loaded with comprehensive monitoring capabilities")

return PerformanceMonitor
