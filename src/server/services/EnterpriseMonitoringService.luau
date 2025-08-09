-- EnterpriseMonitoringService.luau
-- Real-time system monitoring and admin dashboard for enterprise-level game management
-- Provides comprehensive health monitoring, performance tracking, and administrative controls

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local HttpService = game:GetService("HttpService")
local TeleportService = game:GetService("TeleportService")

local EnterpriseMonitoringService = {}
EnterpriseMonitoringService.__index = EnterpriseMonitoringService

-- ========================================
-- MONITORING CONFIGURATION
-- ========================================

local MONITORING_CONFIG = {
    -- Health checks
    healthCheckInterval = 30, -- seconds
    performanceInterval = 5, -- seconds
    alertThresholds = {
        memoryUsage = 500 * 1024 * 1024, -- 500MB
        playerCapacity = 0.9, -- 90% of max players
        errorRate = 0.05, -- 5% error rate
        responseTime = 1000 -- 1 second
    },
    
    -- Dashboard
    enableAdminDashboard = true,
    dashboardUpdateInterval = 2, -- seconds
    maxLogEntries = 1000,
    
    -- Alerts
    enableSlackIntegration = false,
    enableDiscordIntegration = false,
    enableEmailAlerts = false
}

-- Admin user IDs (replace with actual admin user IDs)
local ADMIN_USER_IDS = {
    123456789, -- Replace with actual admin user IDs
    987654321
}

-- ========================================
-- ENTERPRISE MONITORING SERVICE
-- ========================================

function EnterpriseMonitoringService.new(dependencies)
    local self = setmetatable({}, EnterpriseMonitoringService)
    
    -- Dependencies
    self.dataService = dependencies and dependencies.EnterpriseDataService
    self.analyticsService = dependencies and dependencies.EnterpriseAnalyticsService
    self.playerService = dependencies and dependencies.EnterprisePlayerService
    
    -- Monitoring data
    self.systemHealth = {
        overall = "Unknown",
        services = {},
        lastUpdate = 0
    }
    
    self.performanceMetrics = {
        fps = 0,
        memoryUsage = 0,
        playerCount = 0,
        cpuUsage = 0,
        networkLatency = 0,
        errorCount = 0,
        responseTime = 0
    }
    
    self.alertHistory = {}
    self.logEntries = {}
    self.adminSessions = {}
    
    -- Dashboard UI elements
    self.dashboardGuis = {}
    
    print("📊 [Monitoring] Enterprise Monitoring Service initialized")
    return self
end

-- ========================================
-- HEALTH MONITORING SYSTEM
-- ========================================

function EnterpriseMonitoringService:PerformSystemHealthCheck()
    local healthData = {
        timestamp = os.time(),
        services = {},
        overall = "Healthy"
    }
    
    -- Check core services
    if self.dataService then
        local dataHealth = self.dataService:GetSystemHealth()
        healthData.services.DataService = {
            status = dataHealth.isHealthy and "Healthy" or "Critical",
            metrics = dataHealth.metrics,
            details = dataHealth
        }
        
        if not dataHealth.isHealthy then
            healthData.overall = "Critical"
        end
    end
    
    if self.analyticsService then
        local analyticsHealth = self.analyticsService:GetSystemHealth()
        healthData.services.AnalyticsService = {
            status = analyticsHealth.isHealthy and "Healthy" or "Warning",
            metrics = analyticsHealth,
            details = analyticsHealth
        }
        
        if not analyticsHealth.isHealthy and healthData.overall == "Healthy" then
            healthData.overall = "Warning"
        end
    end
    
    if self.playerService then
        local playerHealth = self.playerService:GetSystemHealth()
        healthData.services.PlayerService = {
            status = playerHealth.isHealthy and "Healthy" or "Warning",
            metrics = playerHealth.metrics,
            details = playerHealth
        }
        
        if not playerHealth.isHealthy and healthData.overall == "Healthy" then
            healthData.overall = "Warning"
        end
    end
    
    -- Check server performance
    healthData.services.ServerPerformance = {
        status = self:CheckServerPerformance(),
        metrics = self.performanceMetrics,
        details = {
            playerCount = #Players:GetPlayers(),
            memoryUsage = gcinfo() * 1024,
            uptime = tick()
        }
    }
    
    self.systemHealth = healthData
    
    -- Check for critical alerts
    self:CheckCriticalAlerts(healthData)
    
    return healthData
end

function EnterpriseMonitoringService:CheckServerPerformance()
    local playerCount = #Players:GetPlayers()
    local memoryUsage = gcinfo() * 1024
    
    -- Check thresholds
    if memoryUsage > MONITORING_CONFIG.alertThresholds.memoryUsage then
        return "Critical"
    end
    
    if playerCount >= game:GetService("Players").MaxPlayers * MONITORING_CONFIG.alertThresholds.playerCapacity then
        return "Warning"
    end
    
    return "Healthy"
end

function EnterpriseMonitoringService:CheckCriticalAlerts(healthData)
    local currentTime = os.time()
    
    -- Check for new critical issues
    for serviceName, serviceHealth in pairs(healthData.services) do
        if serviceHealth.status == "Critical" then
            local alertKey = serviceName .. "_critical"
            
            -- Check if this alert was already sent recently (avoid spam)
            local lastAlert = nil
            for i = #self.alertHistory, 1, -1 do
                if self.alertHistory[i].key == alertKey then
                    lastAlert = self.alertHistory[i]
                    break
                end
            end
            
            if not lastAlert or currentTime - lastAlert.timestamp > 300 then -- 5 minutes
                self:SendCriticalAlert(serviceName, serviceHealth)
                
                table.insert(self.alertHistory, {
                    key = alertKey,
                    timestamp = currentTime,
                    serviceName = serviceName,
                    status = serviceHealth.status,
                    details = serviceHealth.details
                })
            end
        end
    end
end

function EnterpriseMonitoringService:SendCriticalAlert(serviceName, serviceHealth)
    local alertMessage = string.format(
        "🚨 CRITICAL ALERT: %s is in critical state\nDetails: %s\nTime: %s",
        serviceName,
        HttpService:JSONEncode(serviceHealth.details),
        os.date("%Y-%m-%d %H:%M:%S", os.time())
    )
    
    -- Log the alert
    self:LogMessage("CRITICAL", alertMessage)
    
    -- Send to admins
    for _, admin in pairs(self.adminSessions) do
        self:SendAdminNotification(admin, alertMessage)
    end
    
    print("🚨 [Monitoring]", alertMessage)
end

-- ========================================
-- PERFORMANCE TRACKING
-- ========================================

function EnterpriseMonitoringService:UpdatePerformanceMetrics()
    -- Calculate FPS
    local frameTime = 1 / 60 -- Default to 60 FPS, would need actual measurement
    self.performanceMetrics.fps = 1 / frameTime
    
    -- Memory usage
    self.performanceMetrics.memoryUsage = gcinfo() * 1024
    
    -- Player count
    self.performanceMetrics.playerCount = #Players:GetPlayers()
    
    -- CPU usage (placeholder - would need actual measurement)
    self.performanceMetrics.cpuUsage = math.random(10, 50) -- Simulated
    
    -- Network latency (placeholder)
    self.performanceMetrics.networkLatency = math.random(20, 100) -- Simulated
    
    -- Update error count from analytics
    if self.analyticsService then
        local analyticsHealth = self.analyticsService:GetSystemHealth()
        self.performanceMetrics.errorCount = analyticsHealth.totalErrors or 0
    end
end

-- ========================================
-- ADMIN DASHBOARD SYSTEM
-- ========================================

function EnterpriseMonitoringService:CreateAdminDashboard(player)
    if not self:IsPlayerAdmin(player) then
        return false
    end
    
    local playerGui = player:WaitForChild("PlayerGui")
    
    -- Remove existing dashboard
    local existingDashboard = playerGui:FindFirstChild("AdminDashboard")
    if existingDashboard then
        existingDashboard:Destroy()
    end
    
    -- Create dashboard GUI
    local dashboardGui = Instance.new("ScreenGui")
    dashboardGui.Name = "AdminDashboard"
    dashboardGui.ResetOnSpawn = false
    dashboardGui.Parent = playerGui
    
    -- Main frame
    local mainFrame = Instance.new("Frame")
    mainFrame.Name = "MainFrame"
    mainFrame.Size = UDim2.new(0, 800, 0, 600)
    mainFrame.Position = UDim2.new(0.5, -400, 0.5, -300)
    mainFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 35)
    mainFrame.BorderSizePixel = 0
    mainFrame.Parent = dashboardGui
    
    -- Corner radius
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 12)
    corner.Parent = mainFrame
    
    -- Title bar
    local titleBar = Instance.new("Frame")
    titleBar.Name = "TitleBar"
    titleBar.Size = UDim2.new(1, 0, 0, 40)
    titleBar.BackgroundColor3 = Color3.fromRGB(45, 45, 50)
    titleBar.BorderSizePixel = 0
    titleBar.Parent = mainFrame
    
    local titleCorner = Instance.new("UICorner")
    titleCorner.CornerRadius = UDim.new(0, 12)
    titleCorner.Parent = titleBar
    
    local title = Instance.new("TextLabel")
    title.Name = "Title"
    title.Size = UDim2.new(1, -100, 1, 0)
    title.Position = UDim2.new(0, 10, 0, 0)
    title.BackgroundTransparency = 1
    title.Text = "🏢 Enterprise Admin Dashboard"
    title.Font = Enum.Font.GothamBold
    title.TextSize = 18
    title.TextColor3 = Color3.fromRGB(255, 255, 255)
    title.TextXAlignment = Enum.TextXAlignment.Left
    title.Parent = titleBar
    
    -- Close button
    local closeButton = Instance.new("TextButton")
    closeButton.Name = "CloseButton"
    closeButton.Size = UDim2.new(0, 30, 0, 30)
    closeButton.Position = UDim2.new(1, -35, 0, 5)
    closeButton.BackgroundColor3 = Color3.fromRGB(255, 100, 100)
    closeButton.Text = "×"
    closeButton.Font = Enum.Font.GothamBold
    closeButton.TextSize = 20
    closeButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    closeButton.Parent = titleBar
    
    local closeCorner = Instance.new("UICorner")
    closeCorner.CornerRadius = UDim.new(0, 6)
    closeCorner.Parent = closeButton
    
    closeButton.Activated:Connect(function()
        dashboardGui:Destroy()
        self.adminSessions[tostring(player.UserId)] = nil
    end)
    
    -- Content area
    local contentArea = Instance.new("ScrollingFrame")
    contentArea.Name = "ContentArea"
    contentArea.Size = UDim2.new(1, -20, 1, -60)
    contentArea.Position = UDim2.new(0, 10, 0, 50)
    contentArea.BackgroundTransparency = 1
    contentArea.CanvasSize = UDim2.new(0, 0, 2, 0)
    contentArea.ScrollBarThickness = 8
    contentArea.Parent = mainFrame
    
    -- Add sections
    self:CreateSystemHealthSection(contentArea)
    self:CreatePerformanceSection(contentArea)
    self:CreatePlayerManagementSection(contentArea)
    self:CreateServerControlsSection(contentArea)
    
    -- Store dashboard reference
    self.dashboardGuis[tostring(player.UserId)] = dashboardGui
    self.adminSessions[tostring(player.UserId)] = {
        player = player,
        dashboard = dashboardGui,
        loginTime = tick()
    }
    
    -- Make draggable
    self:MakeDraggable(mainFrame, titleBar)
    
    print("📊 [Monitoring] Admin dashboard created for:", player.Name)
    return true
end

function EnterpriseMonitoringService:CreateSystemHealthSection(parent)
    local section = Instance.new("Frame")
    section.Name = "SystemHealthSection"
    section.Size = UDim2.new(1, 0, 0, 200)
    section.Position = UDim2.new(0, 0, 0, 0)
    section.BackgroundColor3 = Color3.fromRGB(40, 40, 45)
    section.BorderSizePixel = 0
    section.Parent = parent
    
    local sectionCorner = Instance.new("UICorner")
    sectionCorner.CornerRadius = UDim.new(0, 8)
    sectionCorner.Parent = section
    
    local sectionTitle = Instance.new("TextLabel")
    sectionTitle.Name = "SectionTitle"
    sectionTitle.Size = UDim2.new(1, -20, 0, 30)
    sectionTitle.Position = UDim2.new(0, 10, 0, 10)
    sectionTitle.BackgroundTransparency = 1
    sectionTitle.Text = "💚 System Health"
    sectionTitle.Font = Enum.Font.GothamBold
    sectionTitle.TextSize = 16
    sectionTitle.TextColor3 = Color3.fromRGB(255, 255, 255)
    sectionTitle.TextXAlignment = Enum.TextXAlignment.Left
    sectionTitle.Parent = section
    
    -- Health status display
    local healthStatus = Instance.new("TextLabel")
    healthStatus.Name = "HealthStatus"
    healthStatus.Size = UDim2.new(1, -20, 1, -50)
    healthStatus.Position = UDim2.new(0, 10, 0, 40)
    healthStatus.BackgroundTransparency = 1
    healthStatus.Text = "Loading health data..."
    healthStatus.Font = Enum.Font.Gotham
    healthStatus.TextSize = 12
    healthStatus.TextColor3 = Color3.fromRGB(200, 200, 200)
    healthStatus.TextXAlignment = Enum.TextXAlignment.Left
    healthStatus.TextYAlignment = Enum.TextYAlignment.Top
    healthStatus.TextWrapped = true
    healthStatus.Parent = section
    
    return section
end

function EnterpriseMonitoringService:CreatePerformanceSection(parent)
    local section = Instance.new("Frame")
    section.Name = "PerformanceSection"
    section.Size = UDim2.new(1, 0, 0, 150)
    section.Position = UDim2.new(0, 0, 0, 220)
    section.BackgroundColor3 = Color3.fromRGB(40, 40, 45)
    section.BorderSizePixel = 0
    section.Parent = parent
    
    local sectionCorner = Instance.new("UICorner")
    sectionCorner.CornerRadius = UDim.new(0, 8)
    sectionCorner.Parent = section
    
    local sectionTitle = Instance.new("TextLabel")
    sectionTitle.Name = "SectionTitle"
    sectionTitle.Size = UDim2.new(1, -20, 0, 30)
    sectionTitle.Position = UDim2.new(0, 10, 0, 10)
    sectionTitle.BackgroundTransparency = 1
    sectionTitle.Text = "📈 Performance Metrics"
    sectionTitle.Font = Enum.Font.GothamBold
    sectionTitle.TextSize = 16
    sectionTitle.TextColor3 = Color3.fromRGB(255, 255, 255)
    sectionTitle.TextXAlignment = Enum.TextXAlignment.Left
    sectionTitle.Parent = section
    
    -- Performance display
    local performanceDisplay = Instance.new("TextLabel")
    performanceDisplay.Name = "PerformanceDisplay"
    performanceDisplay.Size = UDim2.new(1, -20, 1, -50)
    performanceDisplay.Position = UDim2.new(0, 10, 0, 40)
    performanceDisplay.BackgroundTransparency = 1
    performanceDisplay.Text = "Loading performance data..."
    performanceDisplay.Font = Enum.Font.Gotham
    performanceDisplay.TextSize = 12
    performanceDisplay.TextColor3 = Color3.fromRGB(200, 200, 200)
    performanceDisplay.TextXAlignment = Enum.TextXAlignment.Left
    performanceDisplay.TextYAlignment = Enum.TextYAlignment.Top
    performanceDisplay.TextWrapped = true
    performanceDisplay.Parent = section
    
    return section
end

function EnterpriseMonitoringService:CreatePlayerManagementSection(parent)
    local section = Instance.new("Frame")
    section.Name = "PlayerManagementSection"
    section.Size = UDim2.new(1, 0, 0, 200)
    section.Position = UDim2.new(0, 0, 0, 390)
    section.BackgroundColor3 = Color3.fromRGB(40, 40, 45)
    section.BorderSizePixel = 0
    section.Parent = parent
    
    local sectionCorner = Instance.new("UICorner")
    sectionCorner.CornerRadius = UDim.new(0, 8)
    sectionCorner.Parent = section
    
    local sectionTitle = Instance.new("TextLabel")
    sectionTitle.Name = "SectionTitle"
    sectionTitle.Size = UDim2.new(1, -20, 0, 30)
    sectionTitle.Position = UDim2.new(0, 10, 0, 10)
    sectionTitle.BackgroundTransparency = 1
    sectionTitle.Text = "👥 Player Management"
    sectionTitle.Font = Enum.Font.GothamBold
    sectionTitle.TextSize = 16
    sectionTitle.TextColor3 = Color3.fromRGB(255, 255, 255)
    sectionTitle.TextXAlignment = Enum.TextXAlignment.Left
    sectionTitle.Parent = section
    
    -- Player list
    local playerList = Instance.new("ScrollingFrame")
    playerList.Name = "PlayerList"
    playerList.Size = UDim2.new(1, -20, 1, -50)
    playerList.Position = UDim2.new(0, 10, 0, 40)
    playerList.BackgroundTransparency = 1
    playerList.CanvasSize = UDim2.new(0, 0, 0, 0)
    playerList.ScrollBarThickness = 6
    playerList.Parent = section
    
    return section
end

function EnterpriseMonitoringService:CreateServerControlsSection(parent)
    local section = Instance.new("Frame")
    section.Name = "ServerControlsSection"
    section.Size = UDim2.new(1, 0, 0, 100)
    section.Position = UDim2.new(0, 0, 0, 610)
    section.BackgroundColor3 = Color3.fromRGB(40, 40, 45)
    section.BorderSizePixel = 0
    section.Parent = parent
    
    local sectionCorner = Instance.new("UICorner")
    sectionCorner.CornerRadius = UDim.new(0, 8)
    sectionCorner.Parent = section
    
    local sectionTitle = Instance.new("TextLabel")
    sectionTitle.Name = "SectionTitle"
    sectionTitle.Size = UDim2.new(1, -20, 0, 30)
    sectionTitle.Position = UDim2.new(0, 10, 0, 10)
    sectionTitle.BackgroundTransparency = 1
    sectionTitle.Text = "🎛️ Server Controls"
    sectionTitle.Font = Enum.Font.GothamBold
    sectionTitle.TextSize = 16
    sectionTitle.TextColor3 = Color3.fromRGB(255, 255, 255)
    sectionTitle.TextXAlignment = Enum.TextXAlignment.Left
    sectionTitle.Parent = section
    
    -- Add control buttons
    self:CreateControlButton(section, "🔄 Restart Services", UDim2.new(0, 10, 0, 45), function()
        self:RestartServices()
    end)
    
    self:CreateControlButton(section, "💾 Save All Data", UDim2.new(0, 150, 0, 45), function()
        self:SaveAllPlayerData()
    end)
    
    self:CreateControlButton(section, "📊 Export Logs", UDim2.new(0, 290, 0, 45), function()
        self:ExportLogs()
    end)
    
    return section
end

function EnterpriseMonitoringService:CreateControlButton(parent, text, position, callback)
    local button = Instance.new("TextButton")
    button.Size = UDim2.new(0, 130, 0, 30)
    button.Position = position
    button.BackgroundColor3 = Color3.fromRGB(70, 130, 180)
    button.Text = text
    button.Font = Enum.Font.Gotham
    button.TextSize = 12
    button.TextColor3 = Color3.fromRGB(255, 255, 255)
    button.Parent = parent
    
    local buttonCorner = Instance.new("UICorner")
    buttonCorner.CornerRadius = UDim.new(0, 6)
    buttonCorner.Parent = button
    
    button.Activated:Connect(callback)
    
    return button
end

-- ========================================
-- ADMIN FUNCTIONALITY
-- ========================================

function EnterpriseMonitoringService:IsPlayerAdmin(player)
    return table.find(ADMIN_USER_IDS, player.UserId) ~= nil
end

function EnterpriseMonitoringService:SendAdminNotification(adminSession, message)
    if not adminSession or not adminSession.player or not adminSession.player.Parent then
        return
    end
    
    -- Send notification through chat or GUI
    local success = pcall(function()
        game:GetService("StarterGui"):SetCore("ChatMakeSystemMessage", {
            Text = "[ADMIN] " .. message,
            Font = Enum.Font.GothamBold,
            Color = Color3.fromRGB(255, 100, 100)
        })
    end)
end

function EnterpriseMonitoringService:RestartServices()
    print("🔄 [Monitoring] Admin requested service restart")
    
    -- Notify all services to restart (implementation depends on service architecture)
    self:LogMessage("ADMIN", "Service restart initiated by admin")
end

function EnterpriseMonitoringService:SaveAllPlayerData()
    print("💾 [Monitoring] Admin requested save all player data")
    
    if self.playerService then
        for _, player in pairs(Players:GetPlayers()) do
            spawn(function()
                self.playerService:SavePlayerDataAsync(player)
            end)
        end
    end
    
    self:LogMessage("ADMIN", "Save all player data initiated by admin")
end

function EnterpriseMonitoringService:ExportLogs()
    print("📊 [Monitoring] Admin requested log export")
    
    local logData = {
        timestamp = os.time(),
        systemHealth = self.systemHealth,
        performanceMetrics = self.performanceMetrics,
        alertHistory = self.alertHistory,
        logEntries = self.logEntries
    }
    
    -- In a real implementation, this would export to a file or external service
    print("Log export data:", HttpService:JSONEncode(logData))
    
    self:LogMessage("ADMIN", "Log export initiated by admin")
end

-- ========================================
-- UTILITY METHODS
-- ========================================

function EnterpriseMonitoringService:LogMessage(level, message)
    local logEntry = {
        timestamp = os.time(),
        level = level,
        message = message
    }
    
    table.insert(self.logEntries, logEntry)
    
    -- Keep log size manageable
    if #self.logEntries > MONITORING_CONFIG.maxLogEntries then
        table.remove(self.logEntries, 1)
    end
    
    print(string.format("[%s] %s: %s", os.date("%H:%M:%S"), level, message))
end

function EnterpriseMonitoringService:MakeDraggable(frame, dragHandle)
    local dragging = false
    local dragStart = nil
    local startPos = nil
    
    dragHandle.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true
            dragStart = input.Position
            startPos = frame.Position
        end
    end)
    
    dragHandle.InputChanged:Connect(function(input)
        if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
            local delta = input.Position - dragStart
            frame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, 
                                      startPos.Y.Scale, startPos.Y.Offset + delta.Y)
        end
    end)
    
    dragHandle.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = false
        end
    end)
end

-- ========================================
-- SERVICE LIFECYCLE
-- ========================================

function EnterpriseMonitoringService:Initialize()
    print("🚀 [Monitoring] Initializing Enterprise Monitoring Service...")
    
    -- Start health monitoring
    spawn(function()
        while true do
            self:PerformSystemHealthCheck()
            wait(MONITORING_CONFIG.healthCheckInterval)
        end
    end)
    
    -- Start performance monitoring
    spawn(function()
        while true do
            self:UpdatePerformanceMetrics()
            wait(MONITORING_CONFIG.performanceInterval)
        end
    end)
    
    -- Update dashboards
    if MONITORING_CONFIG.enableAdminDashboard then
        spawn(function()
            while true do
                self:UpdateAdminDashboards()
                wait(MONITORING_CONFIG.dashboardUpdateInterval)
            end
        end)
    end
    
    print("✅ [Monitoring] Enterprise Monitoring Service initialized")
end

function EnterpriseMonitoringService:Start()
    print("🎯 [Monitoring] Starting Enterprise Monitoring Service...")
    
    -- Connect to player events for admin detection
    Players.PlayerAdded:Connect(function(player)
        if self:IsPlayerAdmin(player) then
            player.Chatted:Connect(function(message)
                if message:lower() == "/dashboard" then
                    self:CreateAdminDashboard(player)
                end
            end)
        end
    end)
    
    Players.PlayerRemoving:Connect(function(player)
        local userId = tostring(player.UserId)
        self.adminSessions[userId] = nil
        self.dashboardGuis[userId] = nil
    end)
    
    print("✅ [Monitoring] Enterprise Monitoring Service started")
end

function EnterpriseMonitoringService:Stop()
    print("🛑 [Monitoring] Stopping Enterprise Monitoring Service...")
    
    -- Close all admin dashboards
    for _, gui in pairs(self.dashboardGuis) do
        if gui and gui.Parent then
            gui:Destroy()
        end
    end
    
    print("✅ [Monitoring] Enterprise Monitoring Service stopped")
end

function EnterpriseMonitoringService:HealthCheck()
    return true -- Monitoring service is always healthy if it can respond
end

function EnterpriseMonitoringService:UpdateAdminDashboards()
    for userId, session in pairs(self.adminSessions) do
        if session.dashboard and session.dashboard.Parent then
            self:UpdateDashboardContent(session.dashboard)
        end
    end
end

function EnterpriseMonitoringService:UpdateDashboardContent(dashboard)
    -- Update system health section
    local healthSection = dashboard:FindFirstChild("MainFrame"):FindFirstChild("ContentArea"):FindFirstChild("SystemHealthSection")
    if healthSection then
        local healthStatus = healthSection:FindFirstChild("HealthStatus")
        if healthStatus then
            local healthText = string.format(
                "Overall Status: %s\n\nServices:\n",
                self.systemHealth.overall
            )
            
            for serviceName, serviceData in pairs(self.systemHealth.services) do
                healthText = healthText .. string.format("• %s: %s\n", serviceName, serviceData.status)
            end
            
            healthStatus.Text = healthText
        end
    end
    
    -- Update performance section
    local perfSection = dashboard:FindFirstChild("MainFrame"):FindFirstChild("ContentArea"):FindFirstChild("PerformanceSection")
    if perfSection then
        local perfDisplay = perfSection:FindFirstChild("PerformanceDisplay")
        if perfDisplay then
            local perfText = string.format(
                "Memory: %.1f MB\nPlayers: %d/%d\nCPU: %.1f%%\nLatency: %d ms",
                self.performanceMetrics.memoryUsage / 1024 / 1024,
                self.performanceMetrics.playerCount,
                Players.MaxPlayers,
                self.performanceMetrics.cpuUsage,
                self.performanceMetrics.networkLatency
            )
            
            perfDisplay.Text = perfText
        end
    end
end

-- ========================================
-- PUBLIC API
-- ========================================

function EnterpriseMonitoringService:GetSystemHealth()
    return table.clone(self.systemHealth)
end

function EnterpriseMonitoringService:GetPerformanceMetrics()
    return table.clone(self.performanceMetrics)
end

function EnterpriseMonitoringService:GetAlertHistory()
    return table.clone(self.alertHistory)
end

return EnterpriseMonitoringService
