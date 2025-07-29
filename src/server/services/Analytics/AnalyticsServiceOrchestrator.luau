-- AnalyticsServiceOrchestrator.luau
-- Clean orchestrator for the Analytics system following service architecture patterns
-- Coordinates all analytics components and provides unified public API

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local SafeRequire = require(ReplicatedStorage.Shared.utils.SafeRequire)
local ServiceArchitecture = SafeRequire.require(ReplicatedStorage.Shared.core.ServiceArchitecture)
local ServiceRegistry = SafeRequire.require(ReplicatedStorage.Shared.core.ServiceRegistry)

-- Import analytics components
local AnalyticsRepository = require(script.Parent.AnalyticsRepository)
local AnalyticsEventCollector = require(script.Parent.AnalyticsEventCollector)
local AnalyticsSessionService = require(script.Parent.AnalyticsSessionService)
local AnalyticsReportingService = require(script.Parent.AnalyticsReportingService)

local AnalyticsServiceOrchestrator = {}
AnalyticsServiceOrchestrator.__index = AnalyticsServiceOrchestrator

-- Extend BaseService
setmetatable(AnalyticsServiceOrchestrator, {__index = ServiceArchitecture.BaseService})

-- ========================================
-- SERVICE INITIALIZATION
-- ========================================

function AnalyticsServiceOrchestrator.new()
    local self = setmetatable({}, AnalyticsServiceOrchestrator)
    
    -- Initialize base service
    ServiceArchitecture.BaseService._init(self, "AnalyticsService", "1.2.0")
    
    -- Initialize components
    self.repository = AnalyticsRepository.new()
    self.eventCollector = AnalyticsEventCollector.new(self.repository)
    self.sessionService = AnalyticsSessionService.new(self.repository, self.eventCollector)
    self.reportingService = AnalyticsReportingService.new(self.repository, self.eventCollector, self.sessionService)
    
    -- Service state
    self.isInitialized = false
    self.autoFlushConnection = nil
    self.playerConnections = {}
    
    -- Event handlers
    self.onPlayerAdded = function(player)
        self:_onPlayerJoined(player)
    end
    
    self.onPlayerRemoving = function(player)
        self:_onPlayerLeft(player)
    end
    
    print("📊 AnalyticsServiceOrchestrator created")
    return self
end

-- ========================================
-- SERVICE LIFECYCLE
-- ========================================

function AnalyticsServiceOrchestrator:Initialize()
    if self.isInitialized then
        return true
    end
    
    -- Connect player events
    self.playerConnections.playerAdded = Players.PlayerAdded:Connect(self.onPlayerAdded)
    self.playerConnections.playerRemoving = Players.PlayerRemoving:Connect(self.onPlayerRemoving)
    
    -- Handle existing players
    for _, player in pairs(Players:GetPlayers()) do
        task.spawn(function()
            self:_onPlayerJoined(player)
        end)
    end
    
    -- Start auto-flush system
    self:_startAutoFlush()
    
    -- Register with service registry
    ServiceRegistry:RegisterService("AnalyticsService", self)
    
    self.isInitialized = true
    self:_setHealthy("Analytics service initialized successfully")
    
    print("📊 Analytics service initialized with all components")
    return true
end

function AnalyticsServiceOrchestrator:Shutdown()
    -- Disconnect player events
    for _, connection in pairs(self.playerConnections) do
        if connection then
            connection:Disconnect()
        end
    end
    self.playerConnections = {}
    
    -- Stop auto-flush
    if self.autoFlushConnection then
        self.autoFlushConnection:Disconnect()
        self.autoFlushConnection = nil
    end
    
    -- Final flush
    self.repository:FlushBuffer()
    
    -- Unregister from service registry
    ServiceRegistry:UnregisterService("AnalyticsService")
    
    self.isInitialized = false
    print("📊 Analytics service shut down")
end

-- ========================================
-- PUBLIC API - EVENT TRACKING
-- ========================================

function AnalyticsServiceOrchestrator:LogEvent(player, eventType, eventData)
    if not self:_validateService() then
        return false
    end
    
    return self.eventCollector:CollectEvent(player, eventType, eventData)
end

-- Legacy compatibility
function AnalyticsServiceOrchestrator:TrackEvent(player, eventType, eventData)
    return self:LogEvent(player, eventType, eventData)
end

function AnalyticsServiceOrchestrator:LogBatchEvents(events)
    if not self:_validateService() then
        return {collected = 0, failed = #events}
    end
    
    return self.eventCollector:CollectBatchEvents(events)
end

-- ========================================
-- PUBLIC API - SESSION MANAGEMENT
-- ========================================

function AnalyticsServiceOrchestrator:GetPlayerSessionId(player)
    local session = self.repository:GetPlayerSession(player.UserId)
    return session and session.sessionId or nil
end

function AnalyticsServiceOrchestrator:GetSessionMetrics(player)
    return self.sessionService:GetSessionMetrics(player)
end

function AnalyticsServiceOrchestrator:GetDifficultyMetrics(player)
    return self.sessionService:GetDifficultyMetrics(player)
end

function AnalyticsServiceOrchestrator:GetMonetizationMetrics(player)
    return self.sessionService:GetMonetizationMetrics(player)
end

-- ========================================
-- PUBLIC API - GAME TRACKING
-- ========================================

function AnalyticsServiceOrchestrator:TrackRunStart(player, currentPosition)
    if not self:_validateService() then
        return
    end
    
    self.sessionService:TrackRunStart(player, currentPosition)
end

function AnalyticsServiceOrchestrator:TrackRunEnd(player, finalPosition, coins, runTime)
    if not self:_validateService() then
        return
    end
    
    self.sessionService:TrackRunEnd(player, finalPosition, coins, runTime)
end

function AnalyticsServiceOrchestrator:TrackRunProgress(player, currentPosition, barriersCleared)
    if not self:_validateService() then
        return
    end
    
    self.sessionService:TrackRunProgress(player, currentPosition, barriersCleared)
end

function AnalyticsServiceOrchestrator:TrackBarrierAttempt(player, barrierPosition, barrierColor, success)
    if not self:_validateService() then
        return
    end
    
    self.sessionService:TrackBarrierAttempt(player, barrierPosition, barrierColor, success)
end

function AnalyticsServiceOrchestrator:TrackColorSwitchTiming(player, reactionTimeMs)
    if not self:_validateService() then
        return
    end
    
    self.sessionService:TrackColorSwitchTiming(player, reactionTimeMs)
end

function AnalyticsServiceOrchestrator:TrackCoinsPerRun(player, coinsEarned, runLength)
    if not self:_validateService() then
        return
    end
    
    self:LogEvent(player, "coins_per_run", {
        coinsEarned = coinsEarned,
        runLength = runLength,
        avgCoinsPerSecond = runLength > 0 and (coinsEarned / runLength) or 0
    })
end

function AnalyticsServiceOrchestrator:TrackGamepassUsage(player, gamepassType, action)
    if not self:_validateService() then
        return
    end
    
    self.sessionService:TrackGamepassUsage(player, gamepassType, action)
end

function AnalyticsServiceOrchestrator:TrackPurchaseAttempt(player, itemType, cost, success)
    if not self:_validateService() then
        return
    end
    
    self.sessionService:TrackPurchaseAttempt(player, itemType, cost, success)
end

-- ========================================
-- PUBLIC API - REPORTING
-- ========================================

function AnalyticsServiceOrchestrator:GetRealtimeMetrics()
    if not self:_validateService() then
        return {}
    end
    
    return self.reportingService:GetRealtimeMetrics()
end

function AnalyticsServiceOrchestrator:GetHourlyReport()
    if not self:_validateService() then
        return {}
    end
    
    return self.reportingService:GetHourlyReport()
end

function AnalyticsServiceOrchestrator:GetDailyReport()
    if not self:_validateService() then
        return {}
    end
    
    return self.reportingService:GetDailyReport()
end

function AnalyticsServiceOrchestrator:GenerateInsights()
    if not self:_validateService() then
        return {}
    end
    
    return self.reportingService:GenerateInsights()
end

function AnalyticsServiceOrchestrator:ExportReport(reportType, format)
    if not self:_validateService() then
        return nil, "Service not available"
    end
    
    return self.reportingService:ExportReport(reportType, format)
end

function AnalyticsServiceOrchestrator:GetAvailableReports()
    return self.reportingService:GetAvailableReports()
end

-- ========================================
-- PUBLIC API - CONFIGURATION
-- ========================================

function AnalyticsServiceOrchestrator:ConfigureEndpoint(endpoint, apiKey, enabled)
    if not self:_validateService() then
        return false
    end
    
    local config = {
        endpoint = endpoint,
        apiKey = apiKey,
        enabled = enabled
    }
    
    self.repository:UpdateConfiguration(config)
    print("📊 Analytics endpoint configured")
    return true
end

function AnalyticsServiceOrchestrator:GetConfiguration()
    return self.repository:GetConfiguration()
end

function AnalyticsServiceOrchestrator:SetEnabled(enabled)
    self.repository:SetEnabled(enabled)
end

function AnalyticsServiceOrchestrator:IsEnabled()
    return self.repository:IsEnabled()
end

-- ========================================
-- PUBLIC API - BUFFER MANAGEMENT
-- ========================================

function AnalyticsServiceOrchestrator:FlushBuffer()
    if not self:_validateService() then
        return false, "Service not available"
    end
    
    return self.repository:FlushBuffer()
end

function AnalyticsServiceOrchestrator:ManualFlush()
    return self:FlushBuffer()
end

function AnalyticsServiceOrchestrator:GetBufferSize()
    return self.repository:GetBufferSize()
end

function AnalyticsServiceOrchestrator:ClearBuffer()
    self.repository:ClearBuffer()
end

-- ========================================
-- PUBLIC API - VALIDATION AND CUSTOMIZATION
-- ========================================

function AnalyticsServiceOrchestrator:AddEventValidator(eventType, validator)
    self.eventCollector:AddEventValidator(eventType, validator)
end

function AnalyticsServiceOrchestrator:AddEventEnricher(eventType, enricher)
    self.eventCollector:AddEventEnricher(eventType, enricher)
end

function AnalyticsServiceOrchestrator:AddEventFilter(filterName, filter)
    self.eventCollector:AddEventFilter(filterName, filter)
end

function AnalyticsServiceOrchestrator:RemoveEventFilter(filterName)
    self.eventCollector:RemoveEventFilter(filterName)
end

function AnalyticsServiceOrchestrator:GetEventTypes()
    return self.eventCollector:GetEventTypes()
end

-- ========================================
-- PUBLIC API - MONITORING
-- ========================================

function AnalyticsServiceOrchestrator:GetActivePlayerCount()
    local activeSessions = self.repository:GetActiveSessions()
    local count = 0
    for _ in pairs(activeSessions) do
        count = count + 1
    end
    return count
end

function AnalyticsServiceOrchestrator:GetServiceStatistics()
    local repositoryStats = self.repository:GetStatistics()
    local collectorStats = self.eventCollector:GetCollectionStats()
    
    return {
        repository = repositoryStats,
        collector = collectorStats,
        activePlayerCount = self:GetActivePlayerCount(),
        serviceHealth = self:GetHealth(),
        isInitialized = self.isInitialized,
        uptime = self:GetUptime()
    }
end

function AnalyticsServiceOrchestrator:TestEndpoint()
    if not self:_validateService() then
        return false, "Service not available"
    end
    
    return self.repository:TestEndpoint()
end

-- ========================================
-- INTERNAL EVENT HANDLERS
-- ========================================

function AnalyticsServiceOrchestrator:_onPlayerJoined(player)
    if not self.isInitialized then
        return
    end
    
    -- Start session tracking
    self.sessionService:StartPlayerSession(player)
    
    print("📊 Started analytics tracking for " .. player.Name)
end

function AnalyticsServiceOrchestrator:_onPlayerLeft(player)
    if not self.isInitialized then
        return
    end
    
    -- End session tracking
    self.sessionService:EndPlayerSession(player)
    
    -- Trigger buffer flush for player data
    task.spawn(function()
        task.wait(1) -- Small delay to ensure leave event is logged
        self.repository:FlushBuffer()
    end)
    
    print("📊 Ended analytics tracking for " .. player.Name)
end

-- ========================================
-- INTERNAL UTILITIES
-- ========================================

function AnalyticsServiceOrchestrator:_startAutoFlush()
    if self.autoFlushConnection then
        self.autoFlushConnection:Disconnect()
    end
    
    self.autoFlushConnection = task.spawn(function()
        while self.isInitialized do
            task.wait(30) -- Flush every 30 seconds
            
            if self.repository:GetBufferSize() > 0 then
                local success, error = self.repository:FlushBuffer()
                if not success then
                    self:_setUnhealthy("Failed to flush analytics buffer: " .. tostring(error))
                else
                    self:_setHealthy("Analytics buffer flushed successfully")
                end
            end
            
            -- Cleanup old data
            self.repository:Cleanup()
        end
    end)
    
    print("📊 Auto-flush system started")
end

function AnalyticsServiceOrchestrator:_validateService()
    if not self.isInitialized then
        warn("⚠️ Analytics service not initialized")
        return false
    end
    
    if not self.repository:IsEnabled() then
        return false -- Silently fail when disabled
    end
    
    return true
end

-- ========================================
-- LEGACY COMPATIBILITY
-- ========================================

-- Maintain compatibility with existing code
function AnalyticsServiceOrchestrator:OnPlayerJoined(player)
    return self:_onPlayerJoined(player)
end

function AnalyticsServiceOrchestrator:OnPlayerLeft(player)
    return self:_onPlayerLeft(player)
end

function AnalyticsServiceOrchestrator:SendAnalyticsToEndpoint(events)
    return self.repository:SendToEndpoint(events)
end

-- ========================================
-- SERVICE REGISTRATION
-- ========================================

-- Register as singleton service
local AnalyticsService = AnalyticsServiceOrchestrator.new()

-- Auto-initialize if running on server
if RunService:IsServer() then
    task.spawn(function()
        task.wait(1) -- Allow other services to initialize first
        AnalyticsService:Initialize()
    end)
end

return AnalyticsService
