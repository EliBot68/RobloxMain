-- AnalyticsRepository.luau
-- Data layer for analytics persistence and storage management
-- Handles data buffering, HTTP endpoints, and analytics data persistence

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local HttpService = game:GetService("HttpService")

local SafeRequire = require(ReplicatedStorage.Shared.utils.SafeRequire)
local ServiceArchitecture = SafeRequire.require(ReplicatedStorage.Shared.core.ServiceArchitecture)

local AnalyticsRepository = {}
AnalyticsRepository.__index = AnalyticsRepository

-- Implement IRepository interface
setmetatable(AnalyticsRepository, {__index = ServiceArchitecture.IRepository})

-- ========================================
-- DATA STORAGE
-- ========================================

local analyticsBuffer = {}
local playerSessions = {}
local configurationData = {}

-- Default HTTP Analytics Configuration
local DEFAULT_CONFIG = {
    enabled = true,
    endpoint = "https://your-analytics-service.com/api/events",
    apiKey = "your-api-key-here",
    batchSize = 50,
    timeout = 10,
    retryAttempts = 3,
    retryDelay = 2
}

function AnalyticsRepository.new()
    local self = setmetatable({}, AnalyticsRepository)
    
    -- Initialize configuration
    configurationData = table.clone(DEFAULT_CONFIG)
    
    print("📊 AnalyticsRepository initialized")
    return self
end

-- ========================================
-- IRepository IMPLEMENTATION
-- ========================================

function AnalyticsRepository:Create(data)
    local eventId = self:GenerateEventId()
    local timestamp = os.time()
    
    local analyticsEvent = {
        id = eventId,
        playerId = data.playerId,
        playerName = data.playerName,
        sessionId = data.sessionId,
        eventType = data.eventType,
        timestamp = timestamp,
        data = data.eventData or {},
        retryCount = 0,
        created = timestamp
    }
    
    table.insert(analyticsBuffer, analyticsEvent)
    
    -- Auto-flush if buffer is getting large
    if #analyticsBuffer >= configurationData.batchSize * 2 then
        task.spawn(function()
            self:FlushBuffer()
        end)
    end
    
    return analyticsEvent
end

function AnalyticsRepository:Read(id)
    for _, event in ipairs(analyticsBuffer) do
        if event.id == id then
            return event
        end
    end
    return nil
end

function AnalyticsRepository:Update(id, updates)
    for i, event in ipairs(analyticsBuffer) do
        if event.id == id then
            for key, value in pairs(updates) do
                event[key] = value
            end
            event.updated = os.time()
            return event
        end
    end
    return nil
end

function AnalyticsRepository:Delete(id)
    for i, event in ipairs(analyticsBuffer) do
        if event.id == id then
            table.remove(analyticsBuffer, i)
            return true
        end
    end
    return false
end

function AnalyticsRepository:List(filters)
    filters = filters or {}
    local results = {}
    
    for _, event in ipairs(analyticsBuffer) do
        local matches = true
        
        if filters.playerId and event.playerId ~= filters.playerId then
            matches = false
        end
        
        if filters.eventType and event.eventType ~= filters.eventType then
            matches = false
        end
        
        if filters.sessionId and event.sessionId ~= filters.sessionId then
            matches = false
        end
        
        if filters.since and event.timestamp < filters.since then
            matches = false
        end
        
        if filters.until and event.timestamp > filters.until then
            matches = false
        end
        
        if matches then
            table.insert(results, event)
        end
    end
    
    return results
end

-- ========================================
-- SESSION MANAGEMENT
-- ========================================

function AnalyticsRepository:CreatePlayerSession(playerId, sessionData)
    local sessionId = sessionData.sessionId or self:GenerateSessionId()
    
    playerSessions[playerId] = {
        sessionId = sessionId,
        playerId = playerId,
        playerName = sessionData.playerName or "Unknown",
        sessionStart = sessionData.sessionStart or os.time(),
        lastActivity = os.time(),
        eventsLogged = 0,
        platform = sessionData.platform or "Unknown",
        isActive = true,
        metadata = sessionData.metadata or {}
    }
    
    return playerSessions[playerId]
end

function AnalyticsRepository:GetPlayerSession(playerId)
    return playerSessions[playerId]
end

function AnalyticsRepository:UpdatePlayerSession(playerId, updates)
    local session = playerSessions[playerId]
    if session then
        for key, value in pairs(updates) do
            session[key] = value
        end
        session.lastActivity = os.time()
        return session
    end
    return nil
end

function AnalyticsRepository:EndPlayerSession(playerId)
    local session = playerSessions[playerId]
    if session then
        session.sessionEnd = os.time()
        session.isActive = false
        session.sessionDuration = session.sessionEnd - session.sessionStart
        
        -- Keep session data for a while for final analytics
        task.spawn(function()
            task.wait(300) -- Keep for 5 minutes
            playerSessions[playerId] = nil
        end)
        
        return session
    end
    return nil
end

function AnalyticsRepository:GetActiveSessions()
    local activeSessions = {}
    for playerId, session in pairs(playerSessions) do
        if session.isActive then
            activeSessions[playerId] = session
        end
    end
    return activeSessions
end

-- ========================================
-- BUFFER MANAGEMENT
-- ========================================

function AnalyticsRepository:GetBufferSize()
    return #analyticsBuffer
end

function AnalyticsRepository:GetBufferEvents(count)
    count = count or configurationData.batchSize
    local events = {}
    
    for i = 1, math.min(count, #analyticsBuffer) do
        table.insert(events, analyticsBuffer[i])
    end
    
    return events
end

function AnalyticsRepository:RemoveEventsFromBuffer(count)
    count = count or configurationData.batchSize
    
    for i = 1, math.min(count, #analyticsBuffer) do
        table.remove(analyticsBuffer, 1)
    end
end

function AnalyticsRepository:ClearBuffer()
    analyticsBuffer = {}
    print("📊 Analytics buffer cleared")
end

function AnalyticsRepository:FlushBuffer()
    if #analyticsBuffer == 0 then
        return true, "Buffer empty"
    end
    
    if not configurationData.enabled then
        self:ClearBuffer()
        return true, "Analytics disabled, buffer cleared"
    end
    
    local events = self:GetBufferEvents()
    local success, error = self:SendToEndpoint(events)
    
    if success then
        self:RemoveEventsFromBuffer(#events)
        print("📊 Flushed " .. #events .. " analytics events")
        return true, "Flushed " .. #events .. " events"
    else
        -- Increment retry count for failed events
        for _, event in ipairs(events) do
            event.retryCount = (event.retryCount or 0) + 1
        end
        
        warn("⚠️ Failed to flush analytics buffer: " .. tostring(error))
        return false, error
    end
end

-- ========================================
-- HTTP COMMUNICATION
-- ========================================

function AnalyticsRepository:SendToEndpoint(events)
    if not configurationData.enabled or not configurationData.endpoint then
        return false, "Analytics endpoint not configured"
    end
    
    local requestData = {
        events = events,
        timestamp = os.time(),
        server = game.JobId,
        place = game.PlaceId
    }
    
    local headers = {
        ["Content-Type"] = "application/json"
    }
    
    if configurationData.apiKey then
        headers["Authorization"] = "Bearer " .. configurationData.apiKey
    end
    
    local success, response = pcall(function()
        return HttpService:RequestAsync({
            Url = configurationData.endpoint,
            Method = "POST",
            Headers = headers,
            Body = HttpService:JSONEncode(requestData)
        })
    end)
    
    if success and response.Success then
        return true, response.Body
    else
        local errorMsg = success and response.StatusMessage or tostring(response)
        return false, errorMsg
    end
end

function AnalyticsRepository:TestEndpoint()
    local testEvent = {
        id = "test_" .. os.time(),
        eventType = "test_connection",
        timestamp = os.time(),
        data = {message = "Connection test"}
    }
    
    return self:SendToEndpoint({testEvent})
end

-- ========================================
-- CONFIGURATION MANAGEMENT
-- ========================================

function AnalyticsRepository:UpdateConfiguration(config)
    for key, value in pairs(config) do
        if DEFAULT_CONFIG[key] ~= nil then
            configurationData[key] = value
        end
    end
    
    print("📊 Analytics configuration updated")
    return configurationData
end

function AnalyticsRepository:GetConfiguration()
    return table.clone(configurationData)
end

function AnalyticsRepository:IsEnabled()
    return configurationData.enabled
end

function AnalyticsRepository:SetEnabled(enabled)
    configurationData.enabled = enabled
    print("📊 Analytics " .. (enabled and "enabled" or "disabled"))
end

-- ========================================
-- UTILITY FUNCTIONS
-- ========================================

function AnalyticsRepository:GenerateEventId()
    return "evt_" .. os.time() .. "_" .. math.random(1000, 9999)
end

function AnalyticsRepository:GenerateSessionId()
    return "ses_" .. os.time() .. "_" .. math.random(1000, 9999)
end

function AnalyticsRepository:GetStatistics()
    local activeSessions = self:GetActiveSessions()
    
    return {
        bufferSize = #analyticsBuffer,
        activeSessions = 0,
        totalSessionsCreated = 0,
        configuration = self:GetConfiguration(),
        oldestEventAge = #analyticsBuffer > 0 and (os.time() - analyticsBuffer[1].timestamp) or 0,
        memoryUsage = self:CalculateMemoryUsage()
    }
    
    -- Count sessions
    for _ in pairs(activeSessions) do
        _.activeSessions = _.activeSessions + 1
    end
    
    -- Count total sessions ever created (approximate)
    for playerId, session in pairs(playerSessions) do
        _.totalSessionsCreated = _.totalSessionsCreated + 1
    end
end

function AnalyticsRepository:CalculateMemoryUsage()
    -- Rough calculation of memory usage
    local bufferEvents = #analyticsBuffer
    local sessionCount = 0
    for _ in pairs(playerSessions) do
        sessionCount = sessionCount + 1
    end
    
    -- Estimate: ~1KB per event, ~2KB per session
    return (bufferEvents * 1) + (sessionCount * 2)
end

function AnalyticsRepository:Cleanup()
    local currentTime = os.time()
    local maxEventAge = 3600 -- 1 hour
    local cleaned = 0
    
    -- Remove old events that failed to send
    for i = #analyticsBuffer, 1, -1 do
        local event = analyticsBuffer[i]
        if (currentTime - event.timestamp) > maxEventAge or (event.retryCount or 0) > configurationData.retryAttempts then
            table.remove(analyticsBuffer, i)
            cleaned = cleaned + 1
        end
    end
    
    -- Clean up inactive sessions
    for playerId, session in pairs(playerSessions) do
        if not session.isActive and session.sessionEnd and (currentTime - session.sessionEnd) > 1800 then -- 30 minutes
            playerSessions[playerId] = nil
        end
    end
    
    if cleaned > 0 then
        print("📊 Cleaned " .. cleaned .. " old analytics events")
    end
end

-- ========================================
-- EXPORT FUNCTIONS
-- ========================================

function AnalyticsRepository:ExportEvents(filters)
    local events = self:List(filters)
    return {
        events = events,
        count = #events,
        exportTime = os.time(),
        filters = filters
    }
end

function AnalyticsRepository:ExportSessions()
    return {
        sessions = playerSessions,
        exportTime = os.time()
    }
end

return AnalyticsRepository
