-- AnalyticsEventCollector.luau
-- Business logic for collecting and processing analytics events
-- Handles event validation, enrichment, and categorization

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local SafeRequire = require(ReplicatedStorage.Shared.utils.SafeRequire)
local ServiceArchitecture = SafeRequire.require(ReplicatedStorage.Shared.core.ServiceArchitecture)

local AnalyticsEventCollector = {}
AnalyticsEventCollector.__index = AnalyticsEventCollector

-- Implement IDomainService interface
setmetatable(AnalyticsEventCollector, {__index = ServiceArchitecture.IDomainService})

-- ========================================
-- EVENT TYPE DEFINITIONS
-- ========================================

local EventTypes = {
    -- Core gameplay events
    RUN_START = "run_start",
    RUN_END = "run_end",
    BARRIER_MATCH = "barrier_match",
    BARRIER_MISS = "barrier_miss",
    GOLDEN_GATE = "golden_gate",
    COIN_COLLECTED = "coin_collected",
    NEW_HIGH_SCORE = "new_high_score",
    
    -- Session events
    PLAYER_JOIN = "player_join",
    PLAYER_LEAVE = "player_leave",
    SESSION_METRICS = "session_metrics",
    
    -- Multiplayer events
    MULTIPLAYER_RUN_START = "multiplayer_run_start",
    
    -- Monetization events
    SHOP_PURCHASE = "shop_purchase",
    MYSTERY_BOX_OPENED = "mystery_box_opened",
    GAMEPASS_USAGE = "gamepass_usage",
    REVENUE_EVENT = "revenue_event",
    
    -- Progression events
    XP_GAINED = "xp_gained",
    LEVEL_UP = "level_up",
    LEVEL_MILESTONE = "level_milestone",
    
    -- Event system
    EVENT_RUN_START = "event_run_start",
    EVENT_RUN_END = "event_run_end",
    
    -- Daily systems
    DAILY_STREAK_CLAIMED = "daily_streak_claimed",
    DAILY_STREAK_BROKEN = "daily_streak_broken",
    
    -- Accessibility
    ACCESSIBILITY_SETTING_CHANGED = "accessibility_setting_changed",
    CONTROLLER_INPUT = "controller_input",
    
    -- Performance metrics
    BOUNCE_RATE = "bounce_rate",
    COINS_PER_RUN = "coins_per_run",
    FAIL_RATE_ANALYSIS = "fail_rate_analysis",
    BARRIER_DIFFICULTY = "barrier_difficulty",
    DIFFICULTY_ADJUSTMENT = "difficulty_adjustment",
    
    -- Custom events
    COLOR_SWITCH = "color_switch",
    PLATFORM_DETECTION = "platform_detection"
}

function AnalyticsEventCollector.new(repository)
    local self = setmetatable({}, AnalyticsEventCollector)
    
    self.repository = repository
    self.eventValidators = {}
    self.eventEnrichers = {}
    self.eventFilters = {}
    
    -- Initialize default validators and enrichers
    self:SetupDefaultValidators()
    self:SetupDefaultEnrichers()
    
    print("📊 AnalyticsEventCollector initialized")
    return self
end

-- ========================================
-- CORE EVENT COLLECTION
-- ========================================

function AnalyticsEventCollector:CollectEvent(player, eventType, eventData)
    -- Validate inputs
    if not self:ValidatePlayer(player) then
        warn("⚠️ Invalid player for analytics event: " .. eventType)
        return false
    end
    
    if not self:ValidateEventType(eventType) then
        warn("⚠️ Invalid event type: " .. tostring(eventType))
        return false
    end
    
    -- Get player session
    local session = self.repository:GetPlayerSession(player.UserId)
    if not session then
        warn("⚠️ No active session for player: " .. player.Name)
        return false
    end
    
    -- Prepare event data
    local enrichedData = self:EnrichEventData(player, eventType, eventData or {})
    
    -- Validate event data
    if not self:ValidateEventData(eventType, enrichedData) then
        warn("⚠️ Invalid event data for: " .. eventType)
        return false
    end
    
    -- Apply filters
    if not self:ShouldCollectEvent(player, eventType, enrichedData) then
        return false -- Event filtered out
    end
    
    -- Create the analytics event
    local analyticsEvent = {
        playerId = player.UserId,
        playerName = player.Name,
        sessionId = session.sessionId,
        eventType = eventType,
        eventData = enrichedData
    }
    
    -- Store in repository
    local storedEvent = self.repository:Create(analyticsEvent)
    if storedEvent then
        -- Update session activity
        self.repository:UpdatePlayerSession(player.UserId, {
            eventsLogged = session.eventsLogged + 1,
            lastActivity = os.time()
        })
        
        print("📊 Collected event: " .. player.Name .. " - " .. eventType)
        return true
    end
    
    return false
end

-- ========================================
-- EVENT VALIDATION
-- ========================================

function AnalyticsEventCollector:ValidatePlayer(player)
    return player and typeof(player) == "Instance" and player:IsA("Player") and player.Parent == Players
end

function AnalyticsEventCollector:ValidateEventType(eventType)
    -- Check if it's a known event type
    for _, knownType in pairs(EventTypes) do
        if eventType == knownType then
            return true
        end
    end
    
    -- Allow custom event types if they follow naming convention
    if type(eventType) == "string" and string.len(eventType) > 0 and string.len(eventType) <= 50 then
        return true
    end
    
    return false
end

function AnalyticsEventCollector:ValidateEventData(eventType, eventData)
    -- Run custom validator if available
    local validator = self.eventValidators[eventType]
    if validator then
        return validator(eventData)
    end
    
    -- Default validation
    if type(eventData) ~= "table" then
        return false
    end
    
    -- Check for reserved fields that shouldn't be in eventData
    local reservedFields = {"playerId", "playerName", "sessionId", "eventType", "timestamp"}
    for _, field in ipairs(reservedFields) do
        if eventData[field] ~= nil then
            return false
        end
    end
    
    return true
end

function AnalyticsEventCollector:SetupDefaultValidators()
    -- RUN_START validator
    self.eventValidators[EventTypes.RUN_START] = function(data)
        return type(data.startPosition) == "number" and data.startPosition >= 0
    end
    
    -- RUN_END validator
    self.eventValidators[EventTypes.RUN_END] = function(data)
        return type(data.finalPosition) == "number" and 
               data.finalPosition >= 0 and
               type(data.runTime) == "number" and 
               data.runTime > 0
    end
    
    -- COIN_COLLECTED validator
    self.eventValidators[EventTypes.COIN_COLLECTED] = function(data)
        return type(data.coinsEarned) == "number" and data.coinsEarned > 0
    end
    
    -- BARRIER events validator
    local barrierValidator = function(data)
        return type(data.barrierPosition) == "number" and
               data.barrierPosition >= 0 and
               type(data.barrierColor) == "string" and
               data.barrierColor ~= ""
    end
    
    self.eventValidators[EventTypes.BARRIER_MATCH] = barrierValidator
    self.eventValidators[EventTypes.BARRIER_MISS] = barrierValidator
    
    -- SHOP_PURCHASE validator
    self.eventValidators[EventTypes.SHOP_PURCHASE] = function(data)
        return type(data.itemId) == "string" and
               data.itemId ~= "" and
               type(data.cost) == "number" and
               data.cost > 0
    end
    
    -- GAMEPASS_USAGE validator
    self.eventValidators[EventTypes.GAMEPASS_USAGE] = function(data)
        return type(data.gamepassType) == "string" and
               data.gamepassType ~= "" and
               type(data.action) == "string" and
               data.action ~= ""
    end
end

-- ========================================
-- EVENT ENRICHMENT
-- ========================================

function AnalyticsEventCollector:EnrichEventData(player, eventType, eventData)
    local enriched = table.clone(eventData)
    
    -- Add common enrichment data
    enriched.serverJobId = game.JobId
    enriched.placeId = game.PlaceId
    enriched.platform = self:DetectPlatform(player)
    enriched.playerAge = self:GetPlayerAge(player)
    enriched.isFirstTimePlayer = self:IsFirstTimePlayer(player)
    
    -- Apply custom enrichers
    local enricher = self.eventEnrichers[eventType]
    if enricher then
        enriched = enricher(player, enriched) or enriched
    end
    
    -- Apply global enrichers
    for _, globalEnricher in pairs(self.eventEnrichers["*"] or {}) do
        enriched = globalEnricher(player, eventType, enriched) or enriched
    end
    
    return enriched
end

function AnalyticsEventCollector:SetupDefaultEnrichers()
    -- RUN events enricher
    local runEnricher = function(player, data)
        local session = self.repository:GetPlayerSession(player.UserId)
        if session then
            data.sessionTime = os.time() - session.sessionStart
            data.totalSessionEvents = session.eventsLogged
        end
        return data
    end
    
    self.eventEnrichers[EventTypes.RUN_START] = runEnricher
    self.eventEnrichers[EventTypes.RUN_END] = runEnricher
    
    -- BARRIER events enricher
    local barrierEnricher = function(player, data)
        data.playerColor = self:GetPlayerCurrentColor(player)
        data.colorMatchRequired = data.barrierColor == data.playerColor
        return data
    end
    
    self.eventEnrichers[EventTypes.BARRIER_MATCH] = barrierEnricher
    self.eventEnrichers[EventTypes.BARRIER_MISS] = barrierEnricher
    
    -- PURCHASE events enricher
    self.eventEnrichers[EventTypes.SHOP_PURCHASE] = function(player, data)
        data.playerCoins = self:GetPlayerCoins(player)
        data.ownedGamepasses = self:GetPlayerGamepasses(player)
        return data
    end
    
    -- Global session enricher
    if not self.eventEnrichers["*"] then
        self.eventEnrichers["*"] = {}
    end
    
    table.insert(self.eventEnrichers["*"], function(player, eventType, data)
        local session = self.repository:GetPlayerSession(player.UserId)
        if session then
            data.sessionDuration = os.time() - session.sessionStart
            data.sessionEventCount = session.eventsLogged
        end
        return data
    end)
end

-- ========================================
-- EVENT FILTERING
-- ========================================

function AnalyticsEventCollector:ShouldCollectEvent(player, eventType, eventData)
    -- Apply custom filters
    for _, filter in pairs(self.eventFilters) do
        if not filter(player, eventType, eventData) then
            return false
        end
    end
    
    -- Default filters
    return self:ApplyDefaultFilters(player, eventType, eventData)
end

function AnalyticsEventCollector:ApplyDefaultFilters(player, eventType, eventData)
    -- Filter out spam events (same event type within short time)
    if self:IsSpamEvent(player, eventType) then
        return false
    end
    
    -- Filter out events from players with suspicious activity
    if self:IsSuspiciousPlayer(player) then
        return false
    end
    
    -- Filter out test events in production
    if eventType:match("^test_") and not game:GetService("RunService"):IsStudio() then
        return false
    end
    
    return true
end

function AnalyticsEventCollector:IsSpamEvent(player, eventType)
    -- Check if same event was logged very recently
    local recentEvents = self.repository:List({
        playerId = player.UserId,
        eventType = eventType,
        since = os.time() - 5 -- Last 5 seconds
    })
    
    -- Allow maximum 3 of the same event type per 5 seconds
    return #recentEvents >= 3
end

function AnalyticsEventCollector:IsSuspiciousPlayer(player)
    -- Check for suspicious patterns (very high event frequency)
    local recentEvents = self.repository:List({
        playerId = player.UserId,
        since = os.time() - 60 -- Last minute
    })
    
    -- Flag if more than 100 events per minute
    return #recentEvents > 100
end

-- ========================================
-- CUSTOM VALIDATORS AND ENRICHERS
-- ========================================

function AnalyticsEventCollector:AddEventValidator(eventType, validator)
    self.eventValidators[eventType] = validator
    print("📊 Added validator for event type: " .. eventType)
end

function AnalyticsEventCollector:AddEventEnricher(eventType, enricher)
    if not self.eventEnrichers[eventType] then
        self.eventEnrichers[eventType] = enricher
    else
        -- If enricher already exists, create a chain
        local existingEnricher = self.eventEnrichers[eventType]
        self.eventEnrichers[eventType] = function(player, data)
            data = existingEnricher(player, data) or data
            return enricher(player, data) or data
        end
    end
    print("📊 Added enricher for event type: " .. eventType)
end

function AnalyticsEventCollector:AddEventFilter(filterName, filter)
    self.eventFilters[filterName] = filter
    print("📊 Added event filter: " .. filterName)
end

function AnalyticsEventCollector:RemoveEventFilter(filterName)
    self.eventFilters[filterName] = nil
    print("📊 Removed event filter: " .. filterName)
end

-- ========================================
-- UTILITY FUNCTIONS
-- ========================================

function AnalyticsEventCollector:DetectPlatform(player)
    -- Detect platform based on player input and device
    if player:GetAttribute("Platform") then
        return player:GetAttribute("Platform")
    end
    
    -- Try to detect based on UserInputService (if available in context)
    local UserInputService = game:GetService("UserInputService")
    
    if UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled then
        return "Mobile"
    elseif UserInputService.GamepadEnabled then
        return "Console"
    elseif UserInputService.KeyboardEnabled then
        return "PC"
    end
    
    return "Unknown"
end

function AnalyticsEventCollector:GetPlayerAge(player)
    -- Calculate account age in days
    return math.floor((os.time() - player.AccountAge * 24 * 60 * 60) / (24 * 60 * 60))
end

function AnalyticsEventCollector:IsFirstTimePlayer(player)
    -- Check if this is player's first session
    -- This would typically check against a persistent data store
    return player.AccountAge < 1 -- Simplified check
end

function AnalyticsEventCollector:GetPlayerCurrentColor(player)
    -- Get current player color - this would integrate with the player service
    local PlayerService = game:GetService("ServerStorage"):FindFirstChild("PlayerService")
    if PlayerService then
        local success, module = pcall(require, PlayerService)
        if success and module.GetPlayerData then
            local playerData = module:GetPlayerData(player)
            return playerData and playerData.currentColor or "UNKNOWN"
        end
    end
    return "UNKNOWN"
end

function AnalyticsEventCollector:GetPlayerCoins(player)
    -- Get player's current coin count
    local leaderstats = player:FindFirstChild("leaderstats")
    if leaderstats then
        local coins = leaderstats:FindFirstChild("Coins")
        if coins then
            return coins.Value
        end
    end
    return 0
end

function AnalyticsEventCollector:GetPlayerGamepasses(player)
    -- Get list of gamepasses owned by player
    local MarketplaceService = game:GetService("MarketplaceService")
    local gamepasses = {}
    
    -- This would check against known gamepass IDs
    local knownGamepasses = {
        {id = 123456, name = "Double Coins"},
        {id = 123457, name = "Speed Boost"},
        {id = 123458, name = "VIP Access"}
    }
    
    for _, gamepass in ipairs(knownGamepasses) do
        local success, owns = pcall(function()
            return MarketplaceService:UserOwnsGamePassAsync(player.UserId, gamepass.id)
        end)
        
        if success and owns then
            table.insert(gamepasses, gamepass.name)
        end
    end
    
    return gamepasses
end

-- ========================================
-- BATCH OPERATIONS
-- ========================================

function AnalyticsEventCollector:CollectBatchEvents(events)
    local collected = 0
    local failed = 0
    
    for _, eventInfo in ipairs(events) do
        local success = self:CollectEvent(eventInfo.player, eventInfo.eventType, eventInfo.eventData)
        if success then
            collected = collected + 1
        else
            failed = failed + 1
        end
    end
    
    print("📊 Batch collection: " .. collected .. " collected, " .. failed .. " failed")
    return {collected = collected, failed = failed}
end

-- ========================================
-- DEBUGGING AND MONITORING
-- ========================================

function AnalyticsEventCollector:GetEventTypes()
    return EventTypes
end

function AnalyticsEventCollector:GetCollectionStats()
    return {
        validatorsRegistered = 0,
        enrichersRegistered = 0,
        filtersRegistered = 0
    }
    
    -- Count validators
    for _ in pairs(self.eventValidators) do
        _.validatorsRegistered = _.validatorsRegistered + 1
    end
    
    -- Count enrichers
    for _ in pairs(self.eventEnrichers) do
        _.enrichersRegistered = _.enrichersRegistered + 1
    end
    
    -- Count filters
    for _ in pairs(self.eventFilters) do
        _.filtersRegistered = _.filtersRegistered + 1
    end
end

return AnalyticsEventCollector
