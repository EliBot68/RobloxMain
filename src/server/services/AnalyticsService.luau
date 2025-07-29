-- AnalyticsService.luau
-- Handles analytics logging for game events

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local HttpService = game:GetService("HttpService")

local SafeRequire = require(ReplicatedStorage.Shared.utils.SafeRequire)
local RemoteEvents = SafeRequire.require(ReplicatedStorage.Shared.modules.RemoteEvents)

local AnalyticsService = {}

-- Analytics data buffer
local analyticsBuffer = {}
local playerAnalytics = {} -- Per-player analytics data
local sessionMetrics = {} -- Session-specific metrics for balancing
local difficultyMetrics = {} -- Barrier difficulty and fail rate tracking
local monetizationMetrics = {} -- Gamepass usage and revenue tracking

-- HTTP Analytics Configuration
local ANALYTICS_CONFIG = {
    enabled = true, -- Set to false to disable HTTP sending
    endpoint = "https://your-analytics-service.com/api/events", -- Replace with your actual endpoint
    apiKey = "your-api-key-here", -- Replace with your actual API key
    batchSize = 50, -- Number of events to send per batch
    timeout = 10 -- HTTP timeout in seconds
}

-- Analytics event types
local EventTypes = {
    RUN_START = "run_start",
    BARRIER_MATCH = "barrier_match",
    BARRIER_MISS = "barrier_miss", 
    GOLDEN_GATE = "golden_gate",
    COIN_COLLECTED = "coin_collected",
    RUN_END = "run_end",
    NEW_HIGH_SCORE = "new_high_score",
    MULTIPLAYER_RUN_START = "multiplayer_run_start",
    PLAYER_JOIN = "player_join",
    PLAYER_LEAVE = "player_leave",
    SHOP_PURCHASE = "shop_purchase",
    MYSTERY_BOX_OPENED = "mystery_box_opened",
    XP_GAINED = "xp_gained",
    LEVEL_UP = "level_up",
    LEVEL_MILESTONE = "level_milestone",
    EVENT_RUN_START = "event_run_start",
    EVENT_RUN_END = "event_run_end",
    DAILY_STREAK_CLAIMED = "daily_streak_claimed",
    DAILY_STREAK_BROKEN = "daily_streak_broken",
    ACCESSIBILITY_SETTING_CHANGED = "accessibility_setting_changed",
    CONTROLLER_INPUT = "controller_input",
    -- New analytics events for balancing and monetization
    SESSION_METRICS = "session_metrics",
    BARRIER_DIFFICULTY = "barrier_difficulty",
    GAMEPASS_USAGE = "gamepass_usage",
    BOUNCE_RATE = "bounce_rate",
    COINS_PER_RUN = "coins_per_run",
    FAIL_RATE_ANALYSIS = "fail_rate_analysis"
    -- New metrics for game balancing and monetization
    SESSION_METRICS = "session_metrics",
    BARRIER_DIFFICULTY = "barrier_difficulty",
    GAMEPASS_USAGE = "gamepass_usage",
    BOUNCE_RATE = "bounce_rate",
    REVENUE_EVENT = "revenue_event",
    DIFFICULTY_ADJUSTMENT = "difficulty_adjustment"
}

function AnalyticsService:LogEvent(player, eventType, eventData)
    local timestamp = os.time()
    local sessionId = self:GetPlayerSessionId(player)
    
    local analyticsEvent = {
        playerId = player.UserId,
        playerName = player.Name,
        sessionId = sessionId,
        eventType = eventType,
        timestamp = timestamp,
        data = eventData or {}
    }
    
    -- Add to buffer
    table.insert(analyticsBuffer, analyticsEvent)
    
    -- Update player-specific analytics
    if not playerAnalytics[player.UserId] then
        playerAnalytics[player.UserId] = {
            sessionId = sessionId,
            sessionStart = timestamp,
            eventsLogged = 0,
            lastActivity = timestamp
        }
    end
    
    playerAnalytics[player.UserId].eventsLogged = playerAnalytics[player.UserId].eventsLogged + 1
    playerAnalytics[player.UserId].lastActivity = timestamp
    
    print("📊 Analytics: " .. player.Name .. " - " .. eventType .. " (" .. #analyticsBuffer .. " events in buffer)")
    
    -- Auto-flush buffer if it gets too large
    if #analyticsBuffer >= 100 then
        self:FlushBuffer()
    end
end

-- Alias for compatibility with existing code
function AnalyticsService:TrackEvent(player, eventType, eventData)
    return self:LogEvent(player, eventType, eventData)
end

function AnalyticsService:GetPlayerSessionId(player)
    if playerAnalytics[player.UserId] then
        return playerAnalytics[player.UserId].sessionId
    else
        -- Generate new session ID (timestamp + random)
        return tostring(os.time()) .. "_" .. tostring(math.random(1000, 9999))
    end
end

function AnalyticsService:OnPlayerJoined(player)
    local sessionId = tostring(os.time()) .. "_" .. tostring(math.random(1000, 9999))
    local joinTime = os.time()
    
    playerAnalytics[player.UserId] = {
        sessionId = sessionId,
        sessionStart = joinTime,
        eventsLogged = 0,
        lastActivity = joinTime
    }
    
    -- Initialize comprehensive session metrics tracking
    sessionMetrics[player.UserId] = {
        sessionStart = joinTime,
        runsCompleted = 0,
        totalCoinsEarned = 0,
        coinsAtSessionStart = 0, -- Track starting coins for delta calculation
        totalBarriersAttempted = 0,
        totalBarriersFailed = 0,
        averageRunLength = 0,
        longestRun = 0,
        shortestRun = math.huge,
        totalRunTime = 0,
        perfectRuns = 0,
        hasGamepass = false,
        gamepassesOwned = {},
        gamepassUsage = {},
        firstRunStarted = false,
        bounced = false, -- True if player leaves without starting a run
        barrierFailsByType = {}, -- Track fails by barrier position/color
        coinsPerRun = {}, -- Track coins earned per individual run
        runDifficulty = {}, -- Track perceived difficulty per run
        interactionCount = 0, -- Total UI interactions
        timeInMenus = 0, -- Time spent in shop/settings
        purchaseAttempts = 0, -- Number of purchase attempts (successful or failed)
        -- New fields for enhanced position and run tracking
        currentPosition = nil, -- Real-time position in current run
        currentRunStartTime = nil, -- When current run started
        currentRunStartPosition = 0, -- Starting position of current run
        barriersInCurrentRun = 0 -- Barriers cleared in current run
    }
    
    -- Check gamepass ownership for monetization tracking
    local gamepasses = self:CheckPlayerGamepasses(player)
    sessionMetrics[player.UserId].hasGamepass = #gamepasses > 0
    sessionMetrics[player.UserId].gamepassesOwned = gamepasses
    
    -- Initialize difficulty tracking for this player
    difficultyMetrics[player.UserId] = {
        barriersByPosition = {}, -- Track barrier difficulty by position in run
        colorSwitchSpeed = {}, -- Track how fast player switches colors
        failurePatterns = {}, -- Track common failure sequences
        learningCurve = {}, -- Track improvement over time
    }
    
    self:LogEvent(player, EventTypes.PLAYER_JOIN, {
        rejoin = false, -- Could be enhanced to detect rejoins
        platform = self:DetectPlatform(player),
        hasGamepass = sessionMetrics[player.UserId].hasGamepass,
        gamepassCount = #gamepasses,
        firstTimePlayer = self:IsFirstTimePlayer(player)
    })
    
    print("📊 Comprehensive session tracking started for " .. player.Name)
end

function AnalyticsService:OnPlayerLeft(player)
    if playerAnalytics[player.UserId] then
        local sessionData = playerAnalytics[player.UserId]
        local sessionDuration = os.time() - sessionData.sessionStart
        
        -- Calculate comprehensive session metrics
        local metrics = sessionMetrics[player.UserId]
        if metrics then
            -- Calculate bounce rate (left without starting a run)
            local bounced = not metrics.firstRunStarted and sessionDuration < 120 -- Less than 2 minutes
            
            -- Calculate average session metrics
            local avgSessionTime = sessionDuration
            local avgCoinsPerRun = metrics.runsCompleted > 0 and (metrics.totalCoinsEarned / metrics.runsCompleted) or 0
            local failRate = metrics.totalBarriersAttempted > 0 and (metrics.totalBarriersFailed / metrics.totalBarriersAttempted) or 0
            local gamepassUsagePercent = metrics.hasGamepass and ((metrics.interactionCount > 0 and 1) or 0) or 0
            
            -- Log comprehensive session completion
            self:LogEvent(player, EventTypes.SESSION_METRICS, {
                sessionDuration = sessionDuration,
                runsCompleted = metrics.runsCompleted,
                avgCoinsPerRun = avgCoinsPerRun,
                totalCoinsEarned = metrics.totalCoinsEarned,
                failRate = failRate,
                bounced = bounced,
                hasGamepass = metrics.hasGamepass,
                gamepassUsagePercent = gamepassUsagePercent,
                perfectRunRate = metrics.runsCompleted > 0 and (metrics.perfectRuns / metrics.runsCompleted) or 0,
                avgRunLength = metrics.runsCompleted > 0 and (metrics.totalRunTime / metrics.runsCompleted) or 0,
                purchaseAttempts = metrics.purchaseAttempts,
                timeInMenus = metrics.timeInMenus,
                platform = self:DetectPlatform(player)
            })
            
            -- Log bounce rate if applicable
            if bounced then
                self:LogEvent(player, EventTypes.BOUNCE_RATE, {
                    sessionDuration = sessionDuration,
                    reason = sessionDuration < 30 and "immediate_leave" or "no_engagement",
                    platform = self:DetectPlatform(player),
                    hadTutorial = self:PlayerCompletedTutorial(player)
                })
            end
            
            -- Log difficulty analysis
            if metrics.runsCompleted > 0 then
                self:LogEvent(player, EventTypes.FAIL_RATE_ANALYSIS, {
                    overallFailRate = failRate,
                    barrierFailsByType = metrics.barrierFailsByType,
                    improvementRate = self:CalculateImprovementRate(player),
                    difficultySpikes = self:IdentifyDifficultySpikes(metrics),
                    recommendedAdjustments = self:GenerateDifficultyRecommendations(metrics)
                })
            end
            
            -- Log gamepass usage patterns
            if metrics.hasGamepass then
                self:LogEvent(player, EventTypes.GAMEPASS_USAGE, {
                    gamepassesOwned = metrics.gamepassesOwned,
                    usageFrequency = gamepassUsagePercent,
                    valueRealized = avgCoinsPerRun * (metrics.hasGamepass and 2 or 1), -- Assuming 2x multiplier
                    sessionLength = sessionDuration,
                    engagementLevel = metrics.runsCompleted > 5 and "high" or (metrics.runsCompleted > 2 and "medium" or "low")
                })
            end
            
            -- Calculate average coins per run
            local avgCoinsPerRun = metrics.runsCompleted > 0 and metrics.totalCoinsEarned / metrics.runsCompleted or 0
            
            -- Calculate fail rate
            local failRate = metrics.totalBarriersAttempted > 0 and metrics.totalBarriersFailed / metrics.totalBarriersAttempted or 0
            
            -- Log comprehensive session metrics
            self:LogEvent(player, EventTypes.SESSION_METRICS, {
                sessionDuration = sessionDuration,
                runsCompleted = metrics.runsCompleted,
                totalCoinsEarned = metrics.totalCoinsEarned,
                avgCoinsPerRun = avgCoinsPerRun,
                totalBarriersAttempted = metrics.totalBarriersAttempted,
                totalBarriersFailed = metrics.totalBarriersFailed,
                failRate = failRate,
                bounced = bounced,
                hasGamepass = metrics.hasGamepass,
                gamepassUsageEvents = #metrics.gamepassUsage
            })
            
            -- Log bounce rate specifically
            if bounced then
                self:LogEvent(player, EventTypes.BOUNCE_RATE, {
                    sessionDuration = sessionDuration,
                    reason = sessionDuration < 30 and "immediate_exit" or "early_exit"
                })
            end
        end
        
        self:LogEvent(player, EventTypes.PLAYER_LEAVE, {
            sessionDuration = sessionDuration,
            eventsLogged = sessionData.eventsLogged
        })
        
        -- Trigger immediate flush when player leaves to capture their session data
        task.spawn(function() -- UPDATED for modern API
            task.wait(1) -- UPDATED for modern API - Small delay to ensure the leave event is logged
            self:FlushBuffer()
        end)
        
        -- Clean up analytics data
        playerAnalytics[player.UserId] = nil
        sessionMetrics[player.UserId] = nil
    end
end

function AnalyticsService:SendAnalyticsToEndpoint(events)
    if not ANALYTICS_CONFIG.enabled or #events == 0 then
        return false
    end
    
    -- Prepare the payload
    local payload = {
        gameId = "color-rush-roblox",
        gameVersion = "1.0.0",
        timestamp = os.time(),
        eventCount = #events,
        events = events
    }
    
    -- Convert to JSON
    local jsonPayload = HttpService:JSONEncode(payload)
    
    -- Prepare HTTP headers
    local headers = {
        ["Content-Type"] = "application/json",
        ["Authorization"] = "Bearer " .. ANALYTICS_CONFIG.apiKey,
        ["User-Agent"] = "ColorRush-Analytics/1.0"
    }
    
    -- Send the HTTP request
    local success, result = pcall(function()
        return HttpService:PostAsync(
            ANALYTICS_CONFIG.endpoint,
            jsonPayload,
            Enum.HttpContentType.ApplicationJson,
            false, -- compress
            headers
        )
    end)
    
    if success then
        print("📊 Successfully sent " .. #events .. " analytics events to endpoint")
        return true
    else
        warn("❌ Failed to send analytics data: " .. tostring(result))
        return false
    end
end

function AnalyticsService:FlushBuffer()
    if #analyticsBuffer > 0 then
        print("📊 Flushing analytics buffer with " .. #analyticsBuffer .. " events")
        
        -- Send events to HTTP endpoint in batches
        if ANALYTICS_CONFIG.enabled then
            local eventsToSend = {}
            local batchSize = ANALYTICS_CONFIG.batchSize
            
            -- Send in batches to avoid overwhelming the endpoint
            for i = 1, #analyticsBuffer, batchSize do
                eventsToSend = {}
                
                -- Collect batch of events
                for j = i, math.min(i + batchSize - 1, #analyticsBuffer) do
                    table.insert(eventsToSend, analyticsBuffer[j])
                end
                
                -- Send batch to endpoint
                task.spawn(function() -- UPDATED for modern API
                    self:SendAnalyticsToEndpoint(eventsToSend)
                end)
            end
        end
        
        -- Keep recent events for debugging
        local recentEvents = {}
        local keepRecent = math.min(20, #analyticsBuffer) -- Keep last 20 events
        
        for i = #analyticsBuffer - keepRecent + 1, #analyticsBuffer do
            if analyticsBuffer[i] then
                table.insert(recentEvents, analyticsBuffer[i])
            end
        end
        
        analyticsBuffer = recentEvents
        print("📊 Buffer flushed, keeping " .. #analyticsBuffer .. " recent events")
    end
end

function AnalyticsService:ConfigureEndpoint(endpoint, apiKey, enabled)
    -- Allow runtime configuration of analytics endpoint
    if endpoint then
        ANALYTICS_CONFIG.endpoint = endpoint
    end
    if apiKey then
        ANALYTICS_CONFIG.apiKey = apiKey
    end
    if enabled ~= nil then
        ANALYTICS_CONFIG.enabled = enabled
    end
    
    print("📊 Analytics endpoint configured: " .. (ANALYTICS_CONFIG.enabled and "ENABLED" or "DISABLED"))
    print("📊 Endpoint: " .. ANALYTICS_CONFIG.endpoint)
end

function AnalyticsService:ManualFlush()
    -- Allow manual triggering of buffer flush
    print("📊 Manual analytics flush triggered")
    self:FlushBuffer()
end

function AnalyticsService:GetConfiguration()
    -- Return current configuration (without sensitive data)
    return {
        enabled = ANALYTICS_CONFIG.enabled,
        endpoint = ANALYTICS_CONFIG.endpoint,
        batchSize = ANALYTICS_CONFIG.batchSize,
        timeout = ANALYTICS_CONFIG.timeout,
        bufferSize = #analyticsBuffer,
        activePlayers = self:GetActivePlayerCount()
    }
end

function AnalyticsService:GetActivePlayerCount()
    local count = 0
    for playerId, data in pairs(playerAnalytics) do
        count = count + 1
    end
    return count
end

-- Helper functions for comprehensive analytics

function AnalyticsService:CheckPlayerGamepasses(player)
    -- Check what gamepasses the player owns
    local gamepasses = {}
    
    -- This would integrate with your MonetizationService
    local MonetizationService = nil
    local success, service = pcall(require, script.Parent.MonetizationService)
    if success then
        MonetizationService = service
        local owned = MonetizationService:CheckPlayerGamepasses(player)
        for gamepassKey, isOwned in pairs(owned) do
            if isOwned then
                table.insert(gamepasses, gamepassKey)
            end
        end
    end
    
    return gamepasses
end

function AnalyticsService:DetectPlatform(player)
    -- Detect player platform for analytics
    local UserInputService = game:GetService("UserInputService")
    if UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled then
        return "Mobile"
    elseif UserInputService.GamepadEnabled then
        return "Console"
    else
        return "PC"
    end
end

function AnalyticsService:IsFirstTimePlayer(player)
    -- Check if this is player's first time joining
    local PlayerService = nil
    local success, service = pcall(require, script.Parent.PlayerService)
    if success then
        PlayerService = service
        local playerData = PlayerService:GetPlayerData(player)
        return playerData and playerData.gamesPlayed == 0
    end
    return false
end

function AnalyticsService:PlayerCompletedTutorial(player)
    -- Check if player completed tutorial
    local PlayerService = nil
    local success, service = pcall(require, script.Parent.PlayerService)
    if success then
        PlayerService = service
        local playerData = PlayerService:GetPlayerData(player)
        return playerData and playerData.tutorialCompleted
    end
    return false
end

function AnalyticsService:CalculateImprovementRate(player)
    -- Calculate how much player has improved over their session
    local metrics = sessionMetrics[player.UserId]
    if not metrics or metrics.runsCompleted < 3 then
        return 0
    end
    
    -- Compare first 3 runs to last 3 runs
    local firstRuns = {}
    local lastRuns = {}
    
    for i = 1, math.min(3, #metrics.coinsPerRun) do
        table.insert(firstRuns, metrics.coinsPerRun[i])
    end
    
    for i = math.max(1, #metrics.coinsPerRun - 2), #metrics.coinsPerRun do
        table.insert(lastRuns, metrics.coinsPerRun[i])
    end
    
    local firstAvg = 0
    local lastAvg = 0
    
    for _, coins in pairs(firstRuns) do
        firstAvg = firstAvg + coins
    end
    firstAvg = firstAvg / #firstRuns
    
    for _, coins in pairs(lastRuns) do
        lastAvg = lastAvg + coins
    end
    lastAvg = lastAvg / #lastRuns
    
    return lastAvg > 0 and ((lastAvg - firstAvg) / firstAvg) or 0
end

function AnalyticsService:IdentifyDifficultySpikes(metrics)
    -- Identify points where difficulty seems to spike based on fail patterns
    local spikes = {}
    
    for barrierPos, fails in pairs(metrics.barrierFailsByType) do
        local failRate = fails.total > 0 and (fails.failures / fails.total) or 0
        if failRate > 0.7 then -- 70%+ fail rate indicates difficulty spike
            table.insert(spikes, {
                position = barrierPos,
                failRate = failRate,
                attempts = fails.total,
                severity = failRate > 0.9 and "critical" or "high"
            })
        end
    end
    
    return spikes
end

function AnalyticsService:GenerateDifficultyRecommendations(metrics)
    -- Generate recommendations for difficulty balancing
    local recommendations = {}
    
    local overallFailRate = metrics.totalBarriersAttempted > 0 and (metrics.totalBarriersFailed / metrics.totalBarriersAttempted) or 0
    
    if overallFailRate > 0.8 then
        table.insert(recommendations, "reduce_overall_difficulty")
    elseif overallFailRate < 0.2 then
        table.insert(recommendations, "increase_challenge")
    end
    
    if metrics.runsCompleted > 0 and metrics.perfectRuns / metrics.runsCompleted > 0.8 then
        table.insert(recommendations, "add_advanced_patterns")
    end
    
    if metrics.averageRunLength < 30 then -- Runs too short
        table.insert(recommendations, "reduce_early_difficulty")
    end
    
    return recommendations
end

-- Enhanced tracking functions

function AnalyticsService:TrackBarrierAttempt(player, barrierPosition, barrierColor, success)
    local metrics = sessionMetrics[player.UserId]
    if metrics then
        metrics.totalBarriersAttempted = metrics.totalBarriersAttempted + 1
        
        if not success then
            metrics.totalBarriersFailed = metrics.totalBarriersFailed + 1
            
            -- Track by barrier type
            local key = barrierPosition .. "_" .. barrierColor
            if not metrics.barrierFailsByType[key] then
                metrics.barrierFailsByType[key] = {total = 0, failures = 0}
            end
            metrics.barrierFailsByType[key].total = metrics.barrierFailsByType[key].total + 1
            metrics.barrierFailsByType[key].failures = metrics.barrierFailsByType[key].failures + 1
        else
            local key = barrierPosition .. "_" .. barrierColor
            if not metrics.barrierFailsByType[key] then
                metrics.barrierFailsByType[key] = {total = 0, failures = 0}
            end
            metrics.barrierFailsByType[key].total = metrics.barrierFailsByType[key].total + 1
            
            -- Update current run barrier count for successful attempts
            metrics.barriersInCurrentRun = (metrics.barriersInCurrentRun or 0) + 1
        end
    end
    
    -- Log individual barrier event
    self:LogEvent(player, success and EventTypes.BARRIER_MATCH or EventTypes.BARRIER_MISS, {
        barrierPosition = barrierPosition,
        barrierColor = barrierColor,
        playerColor = self:GetPlayerColor(player),
        reactionTime = self:CalculateReactionTime(player),
        runPosition = self:GetCurrentRunPosition(player)
    })
end

function AnalyticsService:TrackCoinsPerRun(player, coinsEarned, runLength)
    local metrics = sessionMetrics[player.UserId]
    if metrics then
        metrics.runsCompleted = metrics.runsCompleted + 1
        metrics.totalCoinsEarned = metrics.totalCoinsEarned + coinsEarned
        metrics.totalRunTime = metrics.totalRunTime + runLength
        
        table.insert(metrics.coinsPerRun, coinsEarned)
        
        -- Track run length stats
        if runLength > metrics.longestRun then
            metrics.longestRun = runLength
        end
        if runLength < metrics.shortestRun then
            metrics.shortestRun = runLength
        end
        
        -- Check if perfect run
        if self:WasPerfectRun(player) then
            metrics.perfectRuns = metrics.perfectRuns + 1
        end
    end
    
    -- Log coins per run for analysis
    self:LogEvent(player, EventTypes.COINS_PER_RUN, {
        coinsEarned = coinsEarned,
        runLength = runLength,
        avgCoinsPerSecond = runLength > 0 and (coinsEarned / runLength) or 0,
        hasGamepass = metrics and metrics.hasGamepass or false,
        runNumber = metrics and metrics.runsCompleted or 1
    })
end

function AnalyticsService:TrackGamepassUsage(player, gamepassType, action)
    local metrics = sessionMetrics[player.UserId]
    if metrics then
        if not metrics.gamepassUsage[gamepassType] then
            metrics.gamepassUsage[gamepassType] = 0
        end
        metrics.gamepassUsage[gamepassType] = metrics.gamepassUsage[gamepassType] + 1
        metrics.interactionCount = metrics.interactionCount + 1
    end
    
    self:LogEvent(player, EventTypes.GAMEPASS_USAGE, {
        gamepassType = gamepassType,
        action = action,
        sessionTime = os.time() - (playerAnalytics[player.UserId] and playerAnalytics[player.UserId].sessionStart or os.time()),
        totalUsage = metrics and metrics.gamepassUsage[gamepassType] or 1
    })
end

-- Helper functions for tracking
function AnalyticsService:TrackColorSwitchTiming(player, reactionTimeMs)
    -- Track color switch reaction time for analytics
    if not difficultyMetrics[player.UserId] then
        difficultyMetrics[player.UserId] = {
            barriersByPosition = {},
            colorSwitchSpeed = {},
            failurePatterns = {},
            learningCurve = {},
        }
    end
    
    local playerMetrics = difficultyMetrics[player.UserId]
    table.insert(playerMetrics.colorSwitchSpeed, reactionTimeMs)
    
    -- Keep only last 20 reaction times to prevent memory bloat
    if #playerMetrics.colorSwitchSpeed > 20 then
        table.remove(playerMetrics.colorSwitchSpeed, 1)
    end
    
    -- Log analytics event for color switch
    self:LogEvent(player, "COLOR_SWITCH", {
        reactionTime = reactionTimeMs,
        averageReaction = self:CalculateReactionTime(player),
        switchCount = #playerMetrics.colorSwitchSpeed
    })
end

function AnalyticsService:TrackRunStart(player, currentPosition)
    -- Track when player starts a run and their starting position
    local metrics = sessionMetrics[player.UserId]
    if metrics then
        metrics.firstRunStarted = true
        metrics.currentRunStartTime = os.time()
        metrics.currentRunStartPosition = currentPosition or 0
    end
    
    self:LogEvent(player, EventTypes.RUN_START, {
        startPosition = currentPosition or 0,
        sessionTime = os.time() - (playerAnalytics[player.UserId] and playerAnalytics[player.UserId].sessionStart or os.time()),
        runNumber = metrics and (metrics.runsCompleted + 1) or 1
    })
end

function AnalyticsService:TrackRunProgress(player, currentPosition, barriersCleared)
    -- Track ongoing run progress for position analytics
    local metrics = sessionMetrics[player.UserId]
    if metrics then
        metrics.currentPosition = currentPosition
        metrics.barriersInCurrentRun = barriersCleared or 0
    end
end

function AnalyticsService:TrackRunEnd(player, finalPosition, coins, runTime)
    -- Track when a run ends and reset tracking data
    local metrics = sessionMetrics[player.UserId]
    if metrics then
        -- Record run completion
        metrics.runsCompleted = metrics.runsCompleted + 1
        
        -- Add coins to totals and per-run tracking
        metrics.totalCoinsEarned = metrics.totalCoinsEarned + (coins or 0)
        table.insert(metrics.coinsPerRun, coins or 0)
        
        -- Track run length and time
        local runLength = finalPosition or self:GetCurrentRunPosition(player)
        metrics.totalRunTime = metrics.totalRunTime + (runTime or 0)
        
        if runLength > metrics.longestRun then
            metrics.longestRun = runLength
        end
        if runLength < metrics.shortestRun then
            metrics.shortestRun = runLength
        end
        
        -- Check if it was a perfect run
        if metrics.barriersInCurrentRun > 0 and metrics.totalBarriersFailed == 0 then
            metrics.perfectRuns = metrics.perfectRuns + 1
        end
        
        -- Reset current run tracking
        metrics.currentPosition = nil
        metrics.currentRunStartTime = nil
        metrics.currentRunStartPosition = 0
        metrics.barriersInCurrentRun = 0
        
        -- Log run end event
        self:LogEvent(player, EventTypes.RUN_END, {
            finalPosition = runLength,
            coinsEarned = coins or 0,
            runTime = runTime or 0,
            barriersCleared = metrics.barriersInCurrentRun,
            isPerfectRun = self:WasPerfectRun(player),
            totalRuns = metrics.runsCompleted
        })
    end
end

function AnalyticsService:GetPlayerColor(player)
    -- Get current player color from PlayerService
    local PlayerService = nil
    local success, service = pcall(require, script.Parent.PlayerService)
    if success then
        PlayerService = service
        local playerData = PlayerService:GetPlayerData(player)
        return playerData and playerData.currentColor or "UNKNOWN"
    end
    return "UNKNOWN"
end

function AnalyticsService:CalculateReactionTime(player)
    -- Calculate reaction time for barrier changes based on player's color switch timing
    local difficultyData = difficultyMetrics[player.UserId]
    if not difficultyData or not difficultyData.colorSwitchSpeed or #difficultyData.colorSwitchSpeed == 0 then
        -- If no timing data available, return default fast reaction time (300ms)
        return 300
    end
    
    -- Calculate average reaction time from recent color switches
    local recentSwitches = {}
    local maxSamples = 10 -- Use last 10 color switches for calculation
    
    for i = math.max(1, #difficultyData.colorSwitchSpeed - maxSamples + 1), #difficultyData.colorSwitchSpeed do
        table.insert(recentSwitches, difficultyData.colorSwitchSpeed[i])
    end
    
    if #recentSwitches == 0 then
        return 350 -- Default reaction time
    end
    
    -- Calculate weighted average (more recent switches have higher weight)
    local totalWeight = 0
    local weightedSum = 0
    
    for i, reactionTime in pairs(recentSwitches) do
        local weight = i / #recentSwitches -- More recent = higher weight
        weightedSum = weightedSum + (reactionTime * weight)
        totalWeight = totalWeight + weight
    end
    
    local averageReaction = math.floor(weightedSum / totalWeight)
    
    -- Clamp to realistic ranges (150ms to 1000ms)
    return math.max(150, math.min(1000, averageReaction))
end

function AnalyticsService:GetCurrentRunPosition(player)
    -- Get current position in the run based on detailed tracking data
    local metrics = sessionMetrics[player.UserId]
    if not metrics then
        return 0 -- Player not in a tracked session
    end
    
    -- If we have real-time position tracking from TrackRunProgress
    if metrics.currentPosition then
        return metrics.currentPosition
    end
    
    -- If player is currently in a run, calculate position from barriers attempted
    if metrics.totalBarriersAttempted > 0 and metrics.firstRunStarted then
        -- Calculate current run barriers (total minus previous runs)
        local barriersInCurrentRun = metrics.barriersInCurrentRun or 0
        
        -- Each barrier represents roughly 50 units of distance in the run
        local basePosition = barriersInCurrentRun * 50
        
        -- Add starting position if available
        local startPosition = metrics.currentRunStartPosition or 0
        local currentPosition = startPosition + basePosition
        
        -- Add some variance based on success rate (better players go further faster)
        local successRate = metrics.totalBarriersFailed > 0 and 
            (1 - (metrics.totalBarriersFailed / metrics.totalBarriersAttempted)) or 1
        
        -- Bonus distance for high success rate players (up to 25 extra units)
        local bonusDistance = math.floor(successRate * 25)
        currentPosition = currentPosition + bonusDistance
        
        return math.max(0, currentPosition)
    end
    
    -- If they've started a run but no barriers attempted yet
    if metrics.firstRunStarted then
        return metrics.currentRunStartPosition or 10 -- Just started position
    end
    
    return 0 -- Not in a run or no tracking data
end

function AnalyticsService:WasPerfectRun(player)
    -- Check if the last run was perfect (no barrier failures)
    local metrics = sessionMetrics[player.UserId]
    return metrics and metrics.totalBarriersFailed == 0
end

function AnalyticsService:GetAnalyticsSummary()
    local summary = {
        totalEvents = #analyticsBuffer,
        activePlayers = 0,
        eventTypes = {},
        recentEvents = {},
        -- Comprehensive balancing metrics
        balancingInsights = {
            averageSessionTime = 0,
            avgCoinsPerRun = 0,
            overallFailRate = 0,
            gamepassUsagePercent = 0,
            bounceRate = 0,
            difficultyRecommendations = {},
            monetizationInsights = {}
        },
        -- Enhanced failure rate analysis
        failureAnalysis = {
            byFeature = {
                tutorial = { failRate = 0, attempts = 0, criticalThreshold = false },
                earlyGame = { failRate = 0, attempts = 0, criticalThreshold = false },
                midGame = { failRate = 0, attempts = 0, criticalThreshold = false },
                lateGame = { failRate = 0, attempts = 0, criticalThreshold = false },
                colorSwitch = { failRate = 0, attempts = 0, criticalThreshold = false },
                speedIncrease = { failRate = 0, attempts = 0, criticalThreshold = false },
                complexPatterns = { failRate = 0, attempts = 0, criticalThreshold = false }
            },
            byPlatform = {
                mobile = { failRate = 0, attempts = 0, players = 0, criticalThreshold = false },
                desktop = { failRate = 0, attempts = 0, players = 0, criticalThreshold = false },
                console = { failRate = 0, attempts = 0, players = 0, criticalThreshold = false },
                tablet = { failRate = 0, attempts = 0, players = 0, criticalThreshold = false }
            },
            byTimeOfDay = {
                morning = { failRate = 0, attempts = 0, players = 0, criticalThreshold = false }, -- 6-12
                afternoon = { failRate = 0, attempts = 0, players = 0, criticalThreshold = false }, -- 12-18
                evening = { failRate = 0, attempts = 0, players = 0, criticalThreshold = false }, -- 18-24
                night = { failRate = 0, attempts = 0, players = 0, criticalThreshold = false } -- 0-6
            },
            criticalFailurePoints = {},
            recommendedActions = {}
        }
    }
    
    -- Count active players and calculate session metrics
    local totalSessionTime = 0
    local totalCoinsEarned = 0
    local totalRuns = 0
    local totalBarriersAttempted = 0
    local totalBarriersFailed = 0
    local gamepassPlayers = 0
    local bouncedPlayers = 0
    local totalPlayers = 0
    
    for playerId, data in pairs(playerAnalytics) do
        summary.activePlayers = summary.activePlayers + 1
        
        local metrics = sessionMetrics[playerId]
        if metrics then
            totalPlayers = totalPlayers + 1
            totalSessionTime = totalSessionTime + (os.time() - metrics.sessionStart)
            totalCoinsEarned = totalCoinsEarned + metrics.totalCoinsEarned
            totalRuns = totalRuns + metrics.runsCompleted
            totalBarriersAttempted = totalBarriersAttempted + metrics.totalBarriersAttempted
            totalBarriersFailed = totalBarriersFailed + metrics.totalBarriersFailed
            
            if metrics.hasGamepass then
                gamepassPlayers = gamepassPlayers + 1
            end
            
            if metrics.bounced then
                bouncedPlayers = bouncedPlayers + 1
            end
        end
    end
    
    -- Calculate balancing insights
    if totalPlayers > 0 then
        summary.balancingInsights.averageSessionTime = totalSessionTime / totalPlayers
        summary.balancingInsights.gamepassUsagePercent = (gamepassPlayers / totalPlayers) * 100
        summary.balancingInsights.bounceRate = (bouncedPlayers / totalPlayers) * 100
    end
    
    if totalRuns > 0 then
        summary.balancingInsights.avgCoinsPerRun = totalCoinsEarned / totalRuns
    end
    
    if totalBarriersAttempted > 0 then
        summary.balancingInsights.overallFailRate = (totalBarriersFailed / totalBarriersAttempted) * 100
    end
    
    -- Enhanced Failure Rate Analysis by Feature, Platform, and Time
    self:AnalyzeFailuresByFeature(summary.failureAnalysis)
    self:AnalyzeFailuresByPlatform(summary.failureAnalysis)
    self:AnalyzeFailuresByTimeOfDay(summary.failureAnalysis)
    self:IdentifyCriticalFailurePoints(summary.failureAnalysis)
    self:GenerateFailureActionPlan(summary.failureAnalysis)
    
    if totalBarriersAttempted > 0 then
        summary.balancingInsights.overallFailRate = (totalBarriersFailed / totalBarriersAttempted) * 100
    end
    
    -- Generate difficulty recommendations
    local failRate = summary.balancingInsights.overallFailRate
    if failRate > 70 then
        table.insert(summary.balancingInsights.difficultyRecommendations, "CRITICAL: Reduce difficulty - 70%+ fail rate")
    elseif failRate > 50 then
        table.insert(summary.balancingInsights.difficultyRecommendations, "HIGH: Consider difficulty reduction - 50%+ fail rate")
    elseif failRate < 20 then
        table.insert(summary.balancingInsights.difficultyRecommendations, "LOW: Consider increasing challenge - <20% fail rate")
    end
    
    if summary.balancingInsights.bounceRate > 40 then
        table.insert(summary.balancingInsights.difficultyRecommendations, "RETENTION: High bounce rate - improve onboarding")
    end
    
    if summary.balancingInsights.averageSessionTime < 300 then -- Less than 5 minutes
        table.insert(summary.balancingInsights.difficultyRecommendations, "ENGAGEMENT: Short sessions - add early hooks")
    end
    
    -- Generate monetization insights
    if summary.balancingInsights.gamepassUsagePercent < 10 then
        table.insert(summary.balancingInsights.monetizationInsights, "LOW: Gamepass adoption under 10% - improve value proposition")
    elseif summary.balancingInsights.gamepassUsagePercent > 30 then
        table.insert(summary.balancingInsights.monetizationInsights, "HIGH: Strong gamepass adoption - consider premium offerings")
    end
    
    if summary.balancingInsights.avgCoinsPerRun < 50 then
        table.insert(summary.balancingInsights.monetizationInsights, "ECONOMY: Low coin rewards - may need rebalancing")
    elseif summary.balancingInsights.avgCoinsPerRun > 200 then
        table.insert(summary.balancingInsights.monetizationInsights, "ECONOMY: High coin rewards - check inflation risk")
    end
    
    -- Count event types and get recent events
    for i = math.max(1, #analyticsBuffer - 9), #analyticsBuffer do
        local event = analyticsBuffer[i]
        if event then
            -- Count event types
            summary.eventTypes[event.eventType] = (summary.eventTypes[event.eventType] or 0) + 1
            
            -- Add to recent events
            table.insert(summary.recentEvents, {
                player = event.playerName,
                type = event.eventType,
                timestamp = event.timestamp
            })
        end
    end
    
    return summary
end

function AnalyticsService:HandleAnalyticsEvent(player, eventType, eventData)
    -- Validate event type
    local validEventType = false
    for _, validType in pairs(EventTypes) do
        if eventType == validType then
            validEventType = true
            break
        end
    end
    
    if not validEventType then
        warn("❌ Invalid analytics event type: " .. tostring(eventType))
        return
    end
    
    -- Enhance event data with common fields
    if not eventData then
        eventData = {}
    end
    
    -- Add score context for relevant events
    if eventType == EventTypes.RUN_END or eventType == EventTypes.BARRIER_MATCH then
        -- Could get current score from GameService if needed
        eventData.currentScore = eventData.currentScore or 0
    end
    
    self:LogEvent(player, eventType, eventData)
end

function AnalyticsService:Init()
    -- Handle analytics events from clients
    RemoteEvents.LogAnalyticsEvent.OnServerEvent:Connect(function(player, eventType, eventData)
        self:HandleAnalyticsEvent(player, eventType, eventData)
    end)
    
    -- Set up periodic buffer flush (every 5 minutes)
    task.spawn(function() -- UPDATED for modern API
        while true do
            task.wait(300) -- UPDATED for modern API - 5 minutes
            self:FlushBuffer()
        end
    end)
    
    -- Set up player connection events
    game.Players.PlayerAdded:Connect(function(player)
        self:OnPlayerJoined(player)
    end)
    
    game.Players.PlayerRemoving:Connect(function(player)
        self:OnPlayerLeft(player)
    end)
    
    print("📊 AnalyticsService initialized with comprehensive failure analysis")
end

-- =============================================
-- COMPREHENSIVE FAILURE RATE ANALYSIS SYSTEM
-- =============================================

function AnalyticsService:AnalyzeFailuresByFeature(failureAnalysis)
    -- Analyze failure rates by specific game features
    local featureData = {
        tutorial = { attempts = 0, failures = 0 },
        earlyGame = { attempts = 0, failures = 0 },
        midGame = { attempts = 0, failures = 0 },
        lateGame = { attempts = 0, failures = 0 },
        colorSwitch = { attempts = 0, failures = 0 },
        speedIncrease = { attempts = 0, failures = 0 },
        complexPatterns = { attempts = 0, failures = 0 }
    }
    
    -- Analyze session metrics for feature-specific failures
    for playerId, metrics in pairs(sessionMetrics) do
        if metrics.totalBarriersAttempted > 0 then
            -- Categorize barriers by game features
            for barrierPos, failData in pairs(metrics.barrierFailsByType) do
                local feature = self:CategorizeBarrierByFeature(barrierPos, playerId)
                
                if featureData[feature] then
                    featureData[feature].attempts = featureData[feature].attempts + failData.total
                    featureData[feature].failures = featureData[feature].failures + failData.failures
                end
            end
        end
    end
    
    -- Calculate failure rates and identify critical thresholds
    for feature, data in pairs(featureData) do
        if data.attempts > 0 then
            local failRate = (data.failures / data.attempts) * 100
            failureAnalysis.byFeature[feature] = {
                failRate = failRate,
                attempts = data.attempts,
                criticalThreshold = failRate > 70
            }
        end
    end
end

function AnalyticsService:AnalyzeFailuresByPlatform(failureAnalysis)
    -- Analyze failure rates by platform (Mobile, Desktop, Console, Tablet)
    local platformData = {
        mobile = { attempts = 0, failures = 0, players = 0 },
        desktop = { attempts = 0, failures = 0, players = 0 },
        console = { attempts = 0, failures = 0, players = 0 },
        tablet = { attempts = 0, failures = 0, players = 0 }
    }
    
    for playerId, metrics in pairs(sessionMetrics) do
        local player = game.Players:GetPlayerByUserId(playerId)
        if player and metrics.totalBarriersAttempted > 0 then
            local platform = self:DetectPlatform(player)
            
            if platformData[platform] then
                platformData[platform].attempts = platformData[platform].attempts + metrics.totalBarriersAttempted
                platformData[platform].failures = platformData[platform].failures + metrics.totalBarriersFailed
                platformData[platform].players = platformData[platform].players + 1
            end
        end
    end
    
    -- Calculate platform-specific failure rates
    for platform, data in pairs(platformData) do
        if data.attempts > 0 then
            local failRate = (data.failures / data.attempts) * 100
            failureAnalysis.byPlatform[platform] = {
                failRate = failRate,
                attempts = data.attempts,
                players = data.players,
                criticalThreshold = failRate > 70
            }
        end
    end
end

function AnalyticsService:AnalyzeFailuresByTimeOfDay(failureAnalysis)
    -- Analyze failure rates by time of day to identify peak difficulty periods
    local timeData = {
        morning = { attempts = 0, failures = 0, players = 0 },   -- 6-12
        afternoon = { attempts = 0, failures = 0, players = 0 }, -- 12-18
        evening = { attempts = 0, failures = 0, players = 0 },   -- 18-24
        night = { attempts = 0, failures = 0, players = 0 }      -- 0-6
    }
    
    for playerId, metrics in pairs(sessionMetrics) do
        if metrics.totalBarriersAttempted > 0 then
            local timeOfDay = self:GetTimeOfDayCategory(metrics.sessionStart)
            
            if timeData[timeOfDay] then
                timeData[timeOfDay].attempts = timeData[timeOfDay].attempts + metrics.totalBarriersAttempted
                timeData[timeOfDay].failures = timeData[timeOfDay].failures + metrics.totalBarriersFailed
                timeData[timeOfDay].players = timeData[timeOfDay].players + 1
            end
        end
    end
    
    -- Calculate time-based failure rates
    for timeSlot, data in pairs(timeData) do
        if data.attempts > 0 then
            local failRate = (data.failures / data.attempts) * 100
            failureAnalysis.byTimeOfDay[timeSlot] = {
                failRate = failRate,
                attempts = data.attempts,
                players = data.players,
                criticalThreshold = failRate > 70
            }
        end
    end
end

function AnalyticsService:IdentifyCriticalFailurePoints(failureAnalysis)
    -- Identify specific failure points that exceed 70% threshold
    local criticalPoints = {}
    
    -- Check feature-based critical failures
    for feature, data in pairs(failureAnalysis.byFeature) do
        if data.criticalThreshold then
            table.insert(criticalPoints, {
                type = "feature",
                name = feature,
                failRate = data.failRate,
                severity = data.failRate > 85 and "critical" or "high",
                priority = data.failRate > 90 and 1 or (data.failRate > 80 and 2 or 3)
            })
        end
    end
    
    -- Check platform-based critical failures
    for platform, data in pairs(failureAnalysis.byPlatform) do
        if data.criticalThreshold then
            table.insert(criticalPoints, {
                type = "platform",
                name = platform,
                failRate = data.failRate,
                severity = data.failRate > 85 and "critical" or "high",
                priority = data.failRate > 90 and 1 or (data.failRate > 80 and 2 or 3),
                playerCount = data.players
            })
        end
    end
    
    -- Check time-based critical failures
    for timeSlot, data in pairs(failureAnalysis.byTimeOfDay) do
        if data.criticalThreshold then
            table.insert(criticalPoints, {
                type = "timeOfDay",
                name = timeSlot,
                failRate = data.failRate,
                severity = data.failRate > 85 and "critical" or "high",
                priority = data.failRate > 90 and 1 or (data.failRate > 80 and 2 or 3),
                playerCount = data.players
            })
        end
    end
    
    -- Sort by priority (highest first)
    table.sort(criticalPoints, function(a, b) return a.priority < b.priority end)
    
    failureAnalysis.criticalFailurePoints = criticalPoints
end

function AnalyticsService:GenerateFailureActionPlan(failureAnalysis)
    -- Generate specific recommended actions based on failure analysis
    local actions = {}
    
    -- Feature-specific recommendations
    for feature, data in pairs(failureAnalysis.byFeature) do
        if data.criticalThreshold then
            if feature == "tutorial" then
                table.insert(actions, {
                    action = "Simplify tutorial barriers and add more guidance",
                    urgency = "immediate",
                    feature = feature,
                    failRate = data.failRate
                })
            elseif feature == "earlyGame" then
                table.insert(actions, {
                    action = "Reduce early game difficulty curve - players quitting too early",
                    urgency = "immediate",
                    feature = feature,
                    failRate = data.failRate
                })
            elseif feature == "colorSwitch" then
                table.insert(actions, {
                    action = "Add visual indicators for color switch timing",
                    urgency = "high",
                    feature = feature,
                    failRate = data.failRate
                })
            elseif feature == "speedIncrease" then
                table.insert(actions, {
                    action = "Gradual speed increase instead of sudden jumps",
                    urgency = "high",
                    feature = feature,
                    failRate = data.failRate
                })
            end
        end
    end
    
    -- Platform-specific recommendations
    for platform, data in pairs(failureAnalysis.byPlatform) do
        if data.criticalThreshold then
            if platform == "mobile" then
                table.insert(actions, {
                    action = "Optimize mobile controls - larger touch areas and better responsiveness",
                    urgency = "immediate",
                    platform = platform,
                    failRate = data.failRate,
                    affectedPlayers = data.players
                })
            elseif platform == "console" then
                table.insert(actions, {
                    action = "Improve controller input responsiveness and timing",
                    urgency = "high",
                    platform = platform,
                    failRate = data.failRate,
                    affectedPlayers = data.players
                })
            end
        end
    end
    
    -- Time-based recommendations
    for timeSlot, data in pairs(failureAnalysis.byTimeOfDay) do
        if data.criticalThreshold then
            table.insert(actions, {
                action = string.format("High failure rate during %s - consider server performance or player fatigue factors", timeSlot),
                urgency = "medium",
                timeSlot = timeSlot,
                failRate = data.failRate,
                suggestion = timeSlot == "night" and "Possible tired players - add difficulty scaling" or "Check server performance during peak hours"
            })
        end
    end
    
    failureAnalysis.recommendedActions = actions
end

-- Helper functions for failure analysis

function AnalyticsService:CategorizeBarrierByFeature(barrierPosition, playerId)
    -- Categorize barriers by game features based on position and context
    local metrics = sessionMetrics[playerId]
    
    if barrierPosition <= 5 then
        return "tutorial"
    elseif barrierPosition <= 20 then
        return "earlyGame"
    elseif barrierPosition <= 50 then
        return "midGame"
    else
        return "lateGame"
    end
    
    -- Additional feature detection based on patterns
    -- This would be enhanced with actual game logic
end

function AnalyticsService:GetTimeOfDayCategory(timestamp)
    -- Convert timestamp to hour and categorize
    local dateTime = os.date("*t", timestamp)
    local hour = dateTime.hour
    
    if hour >= 6 and hour < 12 then
        return "morning"
    elseif hour >= 12 and hour < 18 then
        return "afternoon"
    elseif hour >= 18 and hour < 24 then
        return "evening"
    else
        return "night"
    end
end

function AnalyticsService:GetFailureHotspots()
    -- Get real-time failure hotspots for immediate action
    local hotspots = {}
    local summary = self:GetAnalyticsSummary()
    
    for _, point in pairs(summary.failureAnalysis.criticalFailurePoints) do
        if point.failRate > 80 then -- Ultra-critical threshold
            table.insert(hotspots, {
                location = point.name,
                type = point.type,
                failRate = point.failRate,
                recommendedAction = "IMMEDIATE ATTENTION REQUIRED",
                impactLevel = point.playerCount and "High" or "Medium"
            })
        end
    end
    
    return hotspots
end
        self:OnPlayerLeft(player)
    end)
    
    print("✅ AnalyticsService initialized")
end

-- Export event types for other services
AnalyticsService.EventTypes = EventTypes

return AnalyticsService
