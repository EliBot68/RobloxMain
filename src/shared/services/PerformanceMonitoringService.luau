-- PerformanceMonitoringService.luau
-- Comprehensive performance monitoring with FPS, memory, and service health tracking

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local HttpService = game:GetService("HttpService")
local TeleportService = game:GetService("TeleportService")
local Stats = game:GetService("Stats")
local Players = game:GetService("Players")

local Services = require(game.ReplicatedStorage.Shared.core.Services)
local RemoteEvents = require(game.ReplicatedStorage.Shared.modules.RemoteEvents)

local PerformanceMonitoringService = {}

-- Performance metrics storage
local performanceMetrics = {
    fps = {
        current = 0,
        average = 0,
        min = math.huge,
        max = 0,
        samples = {},
        sampleSize = 60 -- 1 minute at 60fps
    },
    memory = {
        current = 0,
        peak = 0,
        trend = {},
        trendSize = 30 -- 30 samples for trend analysis
    },
    ping = {
        current = 0,
        average = 0,
        samples = {},
        sampleSize = 20
    },
    services = {
        lastCheck = 0,
        checkInterval = 30, -- seconds
        status = {},
        failures = {}
    },
    performance = {
        frameDrops = 0,
        lowFpsEvents = 0,
        highMemoryEvents = 0,
        lastFrameTime = 0
    }
}

-- Configuration
local CONFIG = {
    FPS_WARNING_THRESHOLD = 30,
    FPS_CRITICAL_THRESHOLD = 15,
    MEMORY_WARNING_MB = 500,
    MEMORY_CRITICAL_MB = 800,
    PING_WARNING_MS = 200,
    PING_CRITICAL_MS = 500,
    LOG_INTERVAL = 60, -- seconds
    REMOTE_LOG_ENABLED = true,
    DETAILED_LOGGING = false
}

-- Remote logging endpoints (mock interfaces)
local REMOTE_ENDPOINTS = {
    PERFORMANCE_LOG = "https://api.example.com/performance",
    HEALTH_CHECK = "https://api.example.com/health",
    ALERT = "https://api.example.com/alert"
}

-- Service health checkers
local serviceHealthCheckers = {
    TutorialService = function()
        local success, service = pcall(function()
            return require(game.ServerScriptService.Server.services.TutorialService)
        end)
        return success and service ~= nil
    end,
    
    MainGameService = function()
        local success, service = pcall(function()
            return require(game.ServerScriptService.Server.services.MainGameService)
        end)
        return success and service ~= nil
    end,
    
    AnalyticsService = function()
        local success, service = pcall(function()
            return require(game.ServerScriptService.Server.services.AnalyticsService)
        end)
        return success and service ~= nil
    end,
    
    UpgradeService = function()
        local success, service = pcall(function()
            return require(game.ServerScriptService.Server.services.UpgradeService)
        end)
        return success and service ~= nil
    end,
    
    DataService = function()
        local success, service = pcall(function()
            return require(game.ServerScriptService.Server.services.DataService)
        end)
        return success and service ~= nil
    end
}

-- Utility Functions
local function formatBytes(bytes)
    if bytes < 1024 then
        return string.format("%.1f B", bytes)
    elseif bytes < 1024^2 then
        return string.format("%.1f KB", bytes / 1024)
    elseif bytes < 1024^3 then
        return string.format("%.1f MB", bytes / (1024^2))
    else
        return string.format("%.1f GB", bytes / (1024^3))
    end
end

local function calculateAverage(samples)
    if #samples == 0 then return 0 end
    local sum = 0
    for _, sample in ipairs(samples) do
        sum = sum + sample
    end
    return sum / #samples
end

local function addSample(sampleArray, value, maxSize)
    table.insert(sampleArray, value)
    if #sampleArray > maxSize then
        table.remove(sampleArray, 1)
    end
end

-- FPS Monitoring
function PerformanceMonitoringService.updateFPSMetrics()
    local currentTime = tick()
    local frameTime = currentTime - performanceMetrics.performance.lastFrameTime
    performanceMetrics.performance.lastFrameTime = currentTime
    
    if frameTime > 0 then
        local fps = 1 / frameTime
        
        -- Update FPS metrics
        performanceMetrics.fps.current = fps
        addSample(performanceMetrics.fps.samples, fps, performanceMetrics.fps.sampleSize)
        
        performanceMetrics.fps.average = calculateAverage(performanceMetrics.fps.samples)
        performanceMetrics.fps.min = math.min(performanceMetrics.fps.min, fps)
        performanceMetrics.fps.max = math.max(performanceMetrics.fps.max, fps)
        
        -- Check for performance issues
        if fps < CONFIG.FPS_CRITICAL_THRESHOLD then
            performanceMetrics.performance.frameDrops = performanceMetrics.performance.frameDrops + 1
            PerformanceMonitoringService.logPerformanceEvent("CRITICAL_FPS", {
                fps = fps,
                frameTime = frameTime,
                timestamp = currentTime
            })
        elseif fps < CONFIG.FPS_WARNING_THRESHOLD then
            performanceMetrics.performance.lowFpsEvents = performanceMetrics.performance.lowFpsEvents + 1
        end
    end
end

-- Memory Monitoring
function PerformanceMonitoringService.updateMemoryMetrics()
    local memoryUsage = Stats:GetTotalMemoryUsageMb()
    
    performanceMetrics.memory.current = memoryUsage
    performanceMetrics.memory.peak = math.max(performanceMetrics.memory.peak, memoryUsage)
    
    addSample(performanceMetrics.memory.trend, memoryUsage, performanceMetrics.memory.trendSize)
    
    -- Check for memory issues
    if memoryUsage > CONFIG.MEMORY_CRITICAL_MB then
        performanceMetrics.performance.highMemoryEvents = performanceMetrics.performance.highMemoryEvents + 1
        PerformanceMonitoringService.logPerformanceEvent("CRITICAL_MEMORY", {
            memoryMB = memoryUsage,
            peakMB = performanceMetrics.memory.peak,
            timestamp = tick()
        })
    elseif memoryUsage > CONFIG.MEMORY_WARNING_MB then
        PerformanceMonitoringService.logPerformanceEvent("WARNING_MEMORY", {
            memoryMB = memoryUsage,
            peakMB = performanceMetrics.memory.peak,
            timestamp = tick()
        })
    end
end

-- Ping Monitoring
function PerformanceMonitoringService.updatePingMetrics(player)
    if not player or not player:IsA("Player") then return end
    
    local ping = player:GetNetworkPing() * 1000 -- Convert to milliseconds
    
    performanceMetrics.ping.current = ping
    addSample(performanceMetrics.ping.samples, ping, performanceMetrics.ping.sampleSize)
    performanceMetrics.ping.average = calculateAverage(performanceMetrics.ping.samples)
    
    -- Check for connection issues
    if ping > CONFIG.PING_CRITICAL_MS then
        PerformanceMonitoringService.logPerformanceEvent("CRITICAL_PING", {
            pingMs = ping,
            playerId = player.UserId,
            timestamp = tick()
        })
    elseif ping > CONFIG.PING_WARNING_MS then
        PerformanceMonitoringService.logPerformanceEvent("WARNING_PING", {
            pingMs = ping,
            playerId = player.UserId,
            timestamp = tick()
        })
    end
end

-- Service Health Monitoring
function PerformanceMonitoringService.checkServiceHealth()
    local currentTime = tick()
    if currentTime - performanceMetrics.services.lastCheck < performanceMetrics.services.checkInterval then
        return performanceMetrics.services.status
    end
    
    performanceMetrics.services.lastCheck = currentTime
    local healthReport = {}
    
    for serviceName, checker in pairs(serviceHealthCheckers) do
        local success, isHealthy = pcall(checker)
        
        if success then
            healthReport[serviceName] = {
                status = isHealthy and "healthy" or "unhealthy",
                lastCheck = currentTime,
                healthy = isHealthy
            }
            
            if not isHealthy then
                if not performanceMetrics.services.failures[serviceName] then
                    performanceMetrics.services.failures[serviceName] = 0
                end
                performanceMetrics.services.failures[serviceName] = performanceMetrics.services.failures[serviceName] + 1
                
                PerformanceMonitoringService.logPerformanceEvent("SERVICE_UNHEALTHY", {
                    service = serviceName,
                    failures = performanceMetrics.services.failures[serviceName],
                    timestamp = currentTime
                })
            end
        else
            healthReport[serviceName] = {
                status = "error",
                lastCheck = currentTime,
                healthy = false,
                error = tostring(isHealthy)
            }
            
            PerformanceMonitoringService.logPerformanceEvent("SERVICE_ERROR", {
                service = serviceName,
                error = tostring(isHealthy),
                timestamp = currentTime
            })
        end
    end
    
    performanceMetrics.services.status = healthReport
    return healthReport
end

-- Performance Event Logging
function PerformanceMonitoringService.logPerformanceEvent(eventType, data)
    local logEntry = {
        type = eventType,
        timestamp = tick(),
        data = data,
        gameId = game.GameId,
        placeId = game.PlaceId
    }
    
    -- Local logging
    if CONFIG.DETAILED_LOGGING then
        print(string.format("[PERF] %s: %s", eventType, HttpService:JSONEncode(data)))
    end
    
    -- Remote logging (mock implementation)
    if CONFIG.REMOTE_LOG_ENABLED then
        PerformanceMonitoringService.sendRemoteLog(logEntry)
    end
    
    -- Notify analytics service if available
    pcall(function()
        if RemoteEvents.LogAnalyticsEvent then
            RemoteEvents.LogAnalyticsEvent:FireServer("performance_event", logEntry)
        end
    end)
end

-- Remote Logging (Mock Interface)
function PerformanceMonitoringService.sendRemoteLog(logEntry)
    -- Mock implementation - in production, this would send to actual logging service
    pcall(function()
        local jsonData = HttpService:JSONEncode(logEntry)
        
        -- Simulate HTTP request with mock response
        local success = math.random() > 0.1 -- 90% success rate
        
        if success then
            if CONFIG.DETAILED_LOGGING then
                print("[REMOTE_LOG] Successfully sent:", logEntry.type)
            end
        else
            warn("[REMOTE_LOG] Failed to send:", logEntry.type)
        end
    end)
end

-- Comprehensive Performance Report
function PerformanceMonitoringService.generatePerformanceReport()
    local report = {
        timestamp = tick(),
        fps = {
            current = math.floor(performanceMetrics.fps.current),
            average = math.floor(performanceMetrics.fps.average),
            min = math.floor(performanceMetrics.fps.min),
            max = math.floor(performanceMetrics.fps.max),
            status = PerformanceMonitoringService.getFPSStatus()
        },
        memory = {
            current = formatBytes(performanceMetrics.memory.current * 1024 * 1024),
            peak = formatBytes(performanceMetrics.memory.peak * 1024 * 1024),
            currentMB = performanceMetrics.memory.current,
            peakMB = performanceMetrics.memory.peak,
            status = PerformanceMonitoringService.getMemoryStatus()
        },
        ping = {
            current = math.floor(performanceMetrics.ping.current),
            average = math.floor(performanceMetrics.ping.average),
            status = PerformanceMonitoringService.getPingStatus()
        },
        services = PerformanceMonitoringService.checkServiceHealth(),
        performance = {
            frameDrops = performanceMetrics.performance.frameDrops,
            lowFpsEvents = performanceMetrics.performance.lowFpsEvents,
            highMemoryEvents = performanceMetrics.performance.highMemoryEvents
        },
        overall = PerformanceMonitoringService.getOverallHealthStatus()
    }
    
    return report
end

-- Status Helper Functions
function PerformanceMonitoringService.getFPSStatus()
    local fps = performanceMetrics.fps.current
    if fps < CONFIG.FPS_CRITICAL_THRESHOLD then
        return "critical"
    elseif fps < CONFIG.FPS_WARNING_THRESHOLD then
        return "warning"
    else
        return "good"
    end
end

function PerformanceMonitoringService.getMemoryStatus()
    local memory = performanceMetrics.memory.current
    if memory > CONFIG.MEMORY_CRITICAL_MB then
        return "critical"
    elseif memory > CONFIG.MEMORY_WARNING_MB then
        return "warning"
    else
        return "good"
    end
end

function PerformanceMonitoringService.getPingStatus()
    local ping = performanceMetrics.ping.current
    if ping > CONFIG.PING_CRITICAL_MS then
        return "critical"
    elseif ping > CONFIG.PING_WARNING_MS then
        return "warning"
    else
        return "good"
    end
end

function PerformanceMonitoringService.getOverallHealthStatus()
    local fpsStatus = PerformanceMonitoringService.getFPSStatus()
    local memoryStatus = PerformanceMonitoringService.getMemoryStatus()
    local pingStatus = PerformanceMonitoringService.getPingStatus()
    
    -- Check service health
    local serviceIssues = 0
    for _, status in pairs(performanceMetrics.services.status) do
        if not status.healthy then
            serviceIssues = serviceIssues + 1
        end
    end
    
    -- Determine overall status
    if fpsStatus == "critical" or memoryStatus == "critical" or pingStatus == "critical" or serviceIssues > 2 then
        return "critical"
    elseif fpsStatus == "warning" or memoryStatus == "warning" or pingStatus == "warning" or serviceIssues > 0 then
        return "warning"
    else
        return "good"
    end
end

-- Real-time Performance Monitoring (Event-Driven)
function PerformanceMonitoringService.startMonitoring()
    -- FPS monitoring connection (already proper event-driven)
    local fpsConnection = RunService.Heartbeat:Connect(function()
        PerformanceMonitoringService.updateFPSMetrics()
    end)
    
    -- Memory monitoring (every 5 seconds) - converted to heartbeat-based
    local lastMemoryUpdate = 0
    local memoryConnection = RunService.Heartbeat:Connect(function()
        local currentTime = tick()
        if currentTime - lastMemoryUpdate >= 5 then
            lastMemoryUpdate = currentTime
            PerformanceMonitoringService.updateMemoryMetrics()
        end
    end)
    
    -- Ping monitoring for players (every 10 seconds) - converted to heartbeat-based
    local lastPingUpdate = 0
    local pingConnection = RunService.Heartbeat:Connect(function()
        local currentTime = tick()
        if currentTime - lastPingUpdate >= 10 then
            lastPingUpdate = currentTime
            for _, player in pairs(Players:GetPlayers()) do
                PerformanceMonitoringService.updatePingMetrics(player)
            end
        end
    end)
    
    -- Service health monitoring (every 30 seconds) - converted to heartbeat-based
    local lastHealthCheck = 0
    local healthConnection = RunService.Heartbeat:Connect(function()
        local currentTime = tick()
        if currentTime - lastHealthCheck >= 30 then
            lastHealthCheck = currentTime
            PerformanceMonitoringService.checkServiceHealth()
        end
    end)
    
    -- Periodic reporting (every minute) - converted to heartbeat-based
    local lastReportTime = 0
    local reportConnection = RunService.Heartbeat:Connect(function()
        local currentTime = tick()
        if currentTime - lastReportTime >= CONFIG.LOG_INTERVAL then
            lastReportTime = currentTime
            local report = PerformanceMonitoringService.generatePerformanceReport()
            PerformanceMonitoringService.logPerformanceEvent("PERIODIC_REPORT", report)
        end
    end)
    
    return {
        fps = fpsConnection,
        memory = memoryConnection,
        ping = pingConnection,
        health = healthConnection,
        report = reportConnection
    }
end

-- Configuration Functions
function PerformanceMonitoringService.updateConfig(newConfig)
    for key, value in pairs(newConfig) do
        if CONFIG[key] ~= nil then
            CONFIG[key] = value
        end
    end
end

function PerformanceMonitoringService.getConfig()
    return CONFIG
end

-- Reset Functions
function PerformanceMonitoringService.resetMetrics()
    performanceMetrics.fps.samples = {}
    performanceMetrics.fps.min = math.huge
    performanceMetrics.fps.max = 0
    performanceMetrics.memory.trend = {}
    performanceMetrics.ping.samples = {}
    performanceMetrics.performance.frameDrops = 0
    performanceMetrics.performance.lowFpsEvents = 0
    performanceMetrics.performance.highMemoryEvents = 0
    performanceMetrics.services.failures = {}
end

-- Public API
PerformanceMonitoringService.getMetrics = function()
    return performanceMetrics
end

PerformanceMonitoringService.getReport = PerformanceMonitoringService.generatePerformanceReport
PerformanceMonitoringService.getHealthStatus = PerformanceMonitoringService.getOverallHealthStatus

-- Initialize monitoring
PerformanceMonitoringService.connections = PerformanceMonitoringService.startMonitoring()

-- Register service with centralized Services module
Services.Register("PerformanceMonitoringService", PerformanceMonitoringService)

return PerformanceMonitoringService
