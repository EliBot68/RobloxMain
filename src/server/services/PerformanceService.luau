-- PerformanceService.luau
-- Server-side performance monitoring service that integrates with QA health checks

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local Services = require(game.ReplicatedStorage.Shared.core.Services)
local RemoteEvents = require(ReplicatedStorage.Shared.modules.RemoteEvents)
local PerformanceMonitoringService = require(ReplicatedStorage.Shared.services.PerformanceMonitoringService)

local PerformanceService = {}

-- Service state
local activeClients = {}
local lastBroadcast = 0
local broadcastInterval = 5 -- seconds

-- Integration with existing QA health check
local function getQAHealthStatus()
    local success, qaRunner = pcall(function()
        return require(game.ServerScriptService.QATestRunner)
    end)
    
    if success and qaRunner and qaRunner.runHealthCheck then
        local qaSuccess, qaResults = pcall(qaRunner.runHealthCheck, qaRunner)
        if qaSuccess then
            return qaResults
        end
    end
    
    return nil
end

-- Enhanced health check that combines performance and QA data
function PerformanceService.comprehensiveHealthCheck()
    local performanceReport = PerformanceMonitoringService.getReport()
    local qaHealth = getQAHealthStatus()
    
    local combinedReport = {
        timestamp = tick(),
        performance = performanceReport,
        qa = qaHealth,
        integration = {
            status = "healthy",
            issues = {},
            score = 100
        }
    }
    
    -- Calculate integration score
    local issues = {}
    local score = 100
    
    -- Performance issues
    if performanceReport.overall == "critical" then
        score = score - 40
        table.insert(issues, "Critical performance issues detected")
    elseif performanceReport.overall == "warning" then
        score = score - 20
        table.insert(issues, "Performance warnings detected")
    end
    
    -- Service health issues
    if performanceReport.services then
        for serviceName, serviceStatus in pairs(performanceReport.services) do
            if not serviceStatus.healthy then
                score = score - 15
                table.insert(issues, string.format("Service %s is unhealthy", serviceName))
            end
        end
    end
    
    -- QA health issues
    if qaHealth then
        if qaHealth.overallStatus == "FAIL" then
            score = score - 30
            table.insert(issues, "QA health check failed")
        elseif qaHealth.overallStatus == "WARN" then
            score = score - 10
            table.insert(issues, "QA health check warnings")
        end
    end
    
    -- Determine overall status
    combinedReport.integration.score = math.max(0, score)
    combinedReport.integration.issues = issues
    
    if score >= 80 then
        combinedReport.integration.status = "healthy"
    elseif score >= 60 then
        combinedReport.integration.status = "warning"
    else
        combinedReport.integration.status = "critical"
    end
    
    return combinedReport
end

-- Handle client performance report requests
function PerformanceService.handlePerformanceRequest(player)
    if not player or not Players:FindFirstChild(player.Name) then
        return
    end
    
    -- Add client to active list
    activeClients[player.UserId] = {
        player = player,
        lastRequest = tick()
    }
    
    -- Send current performance data
    local report = PerformanceMonitoringService.getReport()
    RemoteEvents.PerformanceReportUpdated:FireClient(player, report)
end

-- Handle health check requests
function PerformanceService.handleHealthCheckRequest(player)
    if not player or not Players:FindFirstChild(player.Name) then
        return
    end
    
    local healthReport = PerformanceService.comprehensiveHealthCheck()
    RemoteEvents.HealthCheckResult:FireClient(player, healthReport)
end

-- Broadcast performance updates to active clients
function PerformanceService.broadcastPerformanceUpdates()
    local currentTime = tick()
    if currentTime - lastBroadcast < broadcastInterval then
        return
    end
    
    lastBroadcast = currentTime
    
    -- Clean up inactive clients
    for userId, clientData in pairs(activeClients) do
        if currentTime - clientData.lastRequest > 30 then -- 30 seconds timeout
            activeClients[userId] = nil
        end
    end
    
    -- Send updates to active clients
    if next(activeClients) then
        local report = PerformanceMonitoringService.getReport()
        
        for userId, clientData in pairs(activeClients) do
            if clientData.player and Players:FindFirstChild(clientData.player.Name) then
                RemoteEvents.PerformanceReportUpdated:FireClient(clientData.player, report)
            end
        end
    end
end

-- Send performance alerts to clients
function PerformanceService.sendPerformanceAlert(alertType, message, targetPlayer)
    if targetPlayer then
        RemoteEvents.PerformanceAlert:FireClient(targetPlayer, alertType, message)
    else
        -- Broadcast to all active clients
        for userId, clientData in pairs(activeClients) do
            if clientData.player and Players:FindFirstChild(clientData.player.Name) then
                RemoteEvents.PerformanceAlert:FireClient(clientData.player, alertType, message)
            end
        end
    end
end

-- Monitor for performance threshold violations
function PerformanceService.monitorThresholds()
    local report = PerformanceMonitoringService.getReport()
    
    -- FPS alerts
    if report.fps.status == "critical" then
        PerformanceService.sendPerformanceAlert("critical", 
            string.format("Critical FPS: %d fps (threshold: 15)", report.fps.current))
    elseif report.fps.status == "warning" then
        PerformanceService.sendPerformanceAlert("warning",
            string.format("Low FPS: %d fps (threshold: 30)", report.fps.current))
    end
    
    -- Memory alerts
    if report.memory.status == "critical" then
        PerformanceService.sendPerformanceAlert("critical",
            string.format("Critical Memory: %s (threshold: 800MB)", report.memory.current))
    elseif report.memory.status == "warning" then
        PerformanceService.sendPerformanceAlert("warning",
            string.format("High Memory: %s (threshold: 500MB)", report.memory.current))
    end
    
    -- Service health alerts
    if report.services then
        for serviceName, serviceStatus in pairs(report.services) do
            if not serviceStatus.healthy then
                PerformanceService.sendPerformanceAlert("warning",
                    string.format("Service %s is unhealthy", serviceName))
            end
        end
    end
end

-- Admin commands for performance monitoring
function PerformanceService.handleAdminCommand(player, command, args)
    -- Check if player has admin permissions (implement your admin check here)
    local isAdmin = player.Name == "EliBot68" or player.UserId == 1 -- Replace with your admin check
    
    if not isAdmin then
        return
    end
    
    if command == "perf_show" then
        RemoteEvents.ShowPerformanceUI:FireClient(player)
    elseif command == "perf_hide" then
        RemoteEvents.HidePerformanceUI:FireClient(player)
    elseif command == "perf_report" then
        local report = PerformanceService.comprehensiveHealthCheck()
        -- Send detailed report to admin (implement as needed)
        print("=== COMPREHENSIVE PERFORMANCE REPORT ===")
        print(game:GetService("HttpService"):JSONEncode(report))
    elseif command == "perf_reset" then
        PerformanceMonitoringService.resetMetrics()
        RemoteEvents.PerformanceMetricsReset:FireClient(player)
    elseif command == "perf_config" and args then
        -- Update performance monitoring configuration
        PerformanceMonitoringService.updateConfig(args)
    end
end

-- Initialize performance service
function PerformanceService.initialize()
    -- Connect remote events
    RemoteEvents.RequestPerformanceReport.OnServerEvent:Connect(PerformanceService.handlePerformanceRequest)
    RemoteEvents.RequestHealthCheck.OnServerEvent:Connect(PerformanceService.handleHealthCheckRequest)
    
    -- Start monitoring using heartbeat connections
    local RunService = game:GetService("RunService")
    local lastUpdateTime = 0
    local lastThresholdCheckTime = 0
    
    PerformanceService.updateConnection = RunService.Heartbeat:Connect(function()
        local currentTime = tick()
        
        -- Broadcast updates every second
        if currentTime - lastUpdateTime >= 1 then
            lastUpdateTime = currentTime
            PerformanceService.broadcastPerformanceUpdates()
        end
        
        -- Monitor thresholds every 10 seconds
        if currentTime - lastThresholdCheckTime >= 10 then
            lastThresholdCheckTime = currentTime
            PerformanceService.monitorThresholds()
        end
    end)
    
    -- Clean up when players leave
    Players.PlayerRemoving:Connect(function(player)
        activeClients[player.UserId] = nil
    end)
    
    print("[PerformanceService] Initialized with comprehensive monitoring")
end

-- Public API for integration with other services
PerformanceService.getHealthReport = PerformanceService.comprehensiveHealthCheck
PerformanceService.sendAlert = PerformanceService.sendPerformanceAlert
PerformanceService.getActiveClients = function() return activeClients end

-- Register with centralized Services module
local Services = require(game.ReplicatedStorage.Shared.core.Services)
Services.Register("PerformanceService", PerformanceService)

-- Auto-initialize
PerformanceService.initialize()

return PerformanceService
