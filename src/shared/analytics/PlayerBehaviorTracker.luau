-- PlayerBehaviorTracker.luau
-- Comprehensive player behavior tracking and analysis system
-- Provides detailed insights into player actions, patterns, and engagement

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local SafeRequire = require(ReplicatedStorage.Shared.utils.SafeRequire)

local PlayerBehaviorTracker = {}

-- ========================================
-- TRACKING CONFIGURATION
-- ========================================

local TRACKING_CONFIG = {
    -- Event categories
    eventCategories = {
        gameplay = {
            "level_start", "level_complete", "level_fail", "checkpoint_reached",
            "power_up_used", "obstacle_hit", "score_achieved", "combo_performed"
        },
        
        navigation = {
            "menu_opened", "menu_closed", "button_clicked", "screen_viewed",
            "tab_switched", "popup_opened", "popup_closed", "search_performed"
        },
        
        social = {
            "friend_added", "message_sent", "party_joined", "party_left",
            "leaderboard_viewed", "achievement_shared", "invite_sent", "invite_accepted"
        },
        
        economy = {
            "purchase_initiated", "purchase_completed", "purchase_cancelled",
            "currency_earned", "currency_spent", "item_equipped", "item_sold"
        },
        
        engagement = {
            "session_started", "session_ended", "daily_login", "tutorial_started",
            "tutorial_completed", "help_viewed", "settings_changed", "feedback_submitted"
        }
    },
    
    -- Tracking intervals
    intervals = {
        realtime = 1,     -- 1 second
        activity = 5,     -- 5 seconds
        session = 60,     -- 1 minute
        heartbeat = 300   -- 5 minutes
    },
    
    -- Data retention
    retention = {
        realtime = 3600,     -- 1 hour
        session = 86400,     -- 24 hours
        daily = 2592000,     -- 30 days
        archive = 31536000   -- 1 year
    },
    
    -- Analysis settings
    analysis = {
        enableHeatmaps = true,
        enableFunnelAnalysis = true,
        enableCohortAnalysis = true,
        enablePathAnalysis = true,
        enableAnomalyDetection = true,
        enablePredictiveModeling = true
    },
    
    -- Privacy settings
    privacy = {
        enableDataCollection = true,
        enablePersonalization = true,
        anonymizeData = false,
        respectDoNotTrack = true,
        dataRetentionDays = 365
    }
}

-- ========================================
-- TRACKING STATE
-- ========================================

local TrackingState = {
    -- Player sessions
    activeSessions = {},
    sessionHistory = {},
    
    -- Event tracking
    eventQueue = {},
    eventHistory = {},
    
    -- Behavior patterns
    playerProfiles = {},
    behaviorPatterns = {},
    
    -- Analysis results
    heatmapData = {},
    funnelData = {},
    cohortData = {},
    pathData = {},
    
    -- Real-time monitoring
    activeTrackers = {},
    trackedPlayers = {},
    
    -- Statistics
    stats = {
        totalEvents = 0,
        uniquePlayers = 0,
        averageSessionLength = 0,
        totalSessions = 0,
        eventsPerSecond = 0,
        dataPointsCollected = 0
    }
}

function PlayerBehaviorTracker.initialize()
    print("👤 Initializing PlayerBehaviorTracker...")
    
    -- Set up event tracking
    PlayerBehaviorTracker.setupEventTracking()
    
    -- Initialize session management
    PlayerBehaviorTracker.initializeSessionManagement()
    
    -- Set up behavior analysis
    PlayerBehaviorTracker.setupBehaviorAnalysis()
    
    -- Initialize real-time tracking
    PlayerBehaviorTracker.initializeRealtimeTracking()
    
    -- Set up data processing
    PlayerBehaviorTracker.setupDataProcessing()
    
    print("👤 PlayerBehaviorTracker initialized successfully")
end

-- ========================================
-- EVENT TRACKING SYSTEM
-- ========================================

function PlayerBehaviorTracker.setupEventTracking()
    -- Initialize event processors
    TrackingState.eventProcessors = {
        gameplay = PlayerBehaviorTracker.createGameplayProcessor(),
        navigation = PlayerBehaviorTracker.createNavigationProcessor(),
        social = PlayerBehaviorTracker.createSocialProcessor(),
        economy = PlayerBehaviorTracker.createEconomyProcessor(),
        engagement = PlayerBehaviorTracker.createEngagementProcessor()
    }
    
    -- Set up event queue processing
    PlayerBehaviorTracker.startEventQueueProcessing()
    
    print("📊 Event tracking system started")
end

function PlayerBehaviorTracker.createGameplayProcessor()
    return {
        name = "gameplay",
        category = "gameplay",
        
        process = function(self, event)
            return PlayerBehaviorTracker.processGameplayEvent(event)
        end,
        
        analyze = function(self, events)
            return PlayerBehaviorTracker.analyzeGameplayPatterns(events)
        end
    }
end

function PlayerBehaviorTracker.createNavigationProcessor()
    return {
        name = "navigation",
        category = "navigation",
        
        process = function(self, event)
            return PlayerBehaviorTracker.processNavigationEvent(event)
        end,
        
        analyze = function(self, events)
            return PlayerBehaviorTracker.analyzeNavigationPatterns(events)
        end
    }
end

function PlayerBehaviorTracker.createSocialProcessor()
    return {
        name = "social",
        category = "social",
        
        process = function(self, event)
            return PlayerBehaviorTracker.processSocialEvent(event)
        end,
        
        analyze = function(self, events)
            return PlayerBehaviorTracker.analyzeSocialPatterns(events)
        end
    }
end

function PlayerBehaviorTracker.createEconomyProcessor()
    return {
        name = "economy",
        category = "economy",
        
        process = function(self, event)
            return PlayerBehaviorTracker.processEconomyEvent(event)
        end,
        
        analyze = function(self, events)
            return PlayerBehaviorTracker.analyzeEconomyPatterns(events)
        end
    }
end

function PlayerBehaviorTracker.createEngagementProcessor()
    return {
        name = "engagement",
        category = "engagement",
        
        process = function(self, event)
            return PlayerBehaviorTracker.processEngagementEvent(event)
        end,
        
        analyze = function(self, events)
            return PlayerBehaviorTracker.analyzeEngagementPatterns(events)
        end
    }
end

function PlayerBehaviorTracker.trackEvent(userId, eventName, category, properties)
    local event = {
        id = HttpService:GenerateGUID(false),
        userId = userId,
        eventName = eventName,
        category = category,
        properties = properties or {},
        timestamp = tick(),
        sessionId = PlayerBehaviorTracker.getCurrentSessionId(userId),
        gameContext = PlayerBehaviorTracker.getGameContext(),
        playerContext = PlayerBehaviorTracker.getPlayerContext(userId)
    }
    
    -- Add to event queue
    table.insert(TrackingState.eventQueue, event)
    
    -- Update statistics
    TrackingState.stats.totalEvents = TrackingState.stats.totalEvents + 1
    
    return event.id
end

function PlayerBehaviorTracker.startEventQueueProcessing()
    spawn(function()
        while true do
            PlayerBehaviorTracker.processEventQueue()
            task.wait(TRACKING_CONFIG.intervals.realtime)
        end
    end)
    
    -- Calculate events per second
    spawn(function()
        local lastEventCount = 0
        while true do
            task.wait(1)
            local currentEventCount = TrackingState.stats.totalEvents
            TrackingState.stats.eventsPerSecond = currentEventCount - lastEventCount
            lastEventCount = currentEventCount
        end
    end)
end

function PlayerBehaviorTracker.processEventQueue()
    local eventsToProcess = {}
    
    -- Move events from queue to processing list
    for i = #TrackingState.eventQueue, 1, -1 do
        table.insert(eventsToProcess, table.remove(TrackingState.eventQueue, i))
    end
    
    -- Process each event
    for _, event in ipairs(eventsToProcess) do
        PlayerBehaviorTracker.processEvent(event)
    end
end

function PlayerBehaviorTracker.processEvent(event)
    -- Find appropriate processor
    local processor = TrackingState.eventProcessors[event.category]
    if processor then
        local processedEvent = processor:process(event)
        
        -- Store in event history
        table.insert(TrackingState.eventHistory, processedEvent)
        
        -- Update player profile
        PlayerBehaviorTracker.updatePlayerProfile(event.userId, processedEvent)
        
        -- Trigger real-time analysis
        PlayerBehaviorTracker.analyzeEventRealtime(processedEvent)
    end
end

-- ========================================
-- SESSION MANAGEMENT
-- ========================================

function PlayerBehaviorTracker.initializeSessionManagement()
    -- Track player connections
    Players.PlayerAdded:Connect(function(player)
        PlayerBehaviorTracker.startPlayerSession(player.UserId)
    end)
    
    Players.PlayerRemoving:Connect(function(player)
        PlayerBehaviorTracker.endPlayerSession(player.UserId)
    end)
    
    -- Session heartbeat monitoring
    spawn(function()
        while true do
            PlayerBehaviorTracker.updateActiveSessions()
            task.wait(TRACKING_CONFIG.intervals.heartbeat)
        end
    end)
    
    print("📱 Session management initialized")
end

function PlayerBehaviorTracker.startPlayerSession(userId)
    local sessionId = HttpService:GenerateGUID(false)
    
    local session = {
        id = sessionId,
        userId = userId,
        startTime = tick(),
        endTime = nil,
        duration = 0,
        events = {},
        context = PlayerBehaviorTracker.getGameContext(),
        platform = PlayerBehaviorTracker.getPlayerPlatform(userId),
        isActive = true,
        heartbeats = 0,
        lastActivity = tick()
    }
    
    TrackingState.activeSessions[userId] = session
    
    -- Track session start event
    PlayerBehaviorTracker.trackEvent(userId, "session_started", "engagement", {
        sessionId = sessionId,
        platform = session.platform
    })
    
    -- Update statistics
    TrackingState.stats.totalSessions = TrackingState.stats.totalSessions + 1
    PlayerBehaviorTracker.updateUniquePlayerCount()
    
    print(string.format("📱 Started session for player %d: %s", userId, sessionId))
end

function PlayerBehaviorTracker.endPlayerSession(userId)
    local session = TrackingState.activeSessions[userId]
    if not session then return end
    
    session.endTime = tick()
    session.duration = session.endTime - session.startTime
    session.isActive = false
    
    -- Track session end event
    PlayerBehaviorTracker.trackEvent(userId, "session_ended", "engagement", {
        sessionId = session.id,
        duration = session.duration,
        eventCount = #session.events
    })
    
    -- Move to session history
    table.insert(TrackingState.sessionHistory, session)
    TrackingState.activeSessions[userId] = nil
    
    -- Update session length statistics
    PlayerBehaviorTracker.updateSessionStatistics(session.duration)
    
    print(string.format("📱 Ended session for player %d: %.2fs", userId, session.duration))
end

function PlayerBehaviorTracker.updateActiveSessions()
    local currentTime = tick()
    
    for userId, session in pairs(TrackingState.activeSessions) do
        session.heartbeats = session.heartbeats + 1
        session.duration = currentTime - session.startTime
        
        -- Check for inactive sessions
        if currentTime - session.lastActivity > 1800 then -- 30 minutes inactive
            print(string.format("📱 Session timeout for player %d", userId))
            PlayerBehaviorTracker.endPlayerSession(userId)
        end
    end
end

function PlayerBehaviorTracker.getCurrentSessionId(userId)
    local session = TrackingState.activeSessions[userId]
    return session and session.id or nil
end

function PlayerBehaviorTracker.updatePlayerActivity(userId)
    local session = TrackingState.activeSessions[userId]
    if session then
        session.lastActivity = tick()
    end
end

-- ========================================
-- BEHAVIOR ANALYSIS
-- ========================================

function PlayerBehaviorTracker.setupBehaviorAnalysis()
    -- Initialize analysis engines
    TrackingState.analysisEngines = {
        patternRecognition = PlayerBehaviorTracker.createPatternRecognitionEngine(),
        funnelAnalysis = PlayerBehaviorTracker.createFunnelAnalysisEngine(),
        cohortAnalysis = PlayerBehaviorTracker.createCohortAnalysisEngine(),
        pathAnalysis = PlayerBehaviorTracker.createPathAnalysisEngine(),
        anomalyDetection = PlayerBehaviorTracker.createAnomalyDetectionEngine()
    }
    
    -- Start analysis processes
    spawn(function()
        while true do
            PlayerBehaviorTracker.runBehaviorAnalysis()
            task.wait(TRACKING_CONFIG.intervals.session)
        end
    end)
    
    print("🧠 Behavior analysis systems started")
end

function PlayerBehaviorTracker.createPatternRecognitionEngine()
    return {
        name = "pattern_recognition",
        
        analyze = function(self, playerData)
            return PlayerBehaviorTracker.recognizePlayerPatterns(playerData)
        end
    }
end

function PlayerBehaviorTracker.createFunnelAnalysisEngine()
    return {
        name = "funnel_analysis",
        
        analyze = function(self, events)
            return PlayerBehaviorTracker.analyzeFunnelConversion(events)
        end
    }
end

function PlayerBehaviorTracker.createCohortAnalysisEngine()
    return {
        name = "cohort_analysis",
        
        analyze = function(self, playerData)
            return PlayerBehaviorTracker.performCohortAnalysis(playerData)
        end
    }
end

function PlayerBehaviorTracker.createPathAnalysisEngine()
    return {
        name = "path_analysis",
        
        analyze = function(self, navigationEvents)
            return PlayerBehaviorTracker.analyzeUserPaths(navigationEvents)
        end
    }
end

function PlayerBehaviorTracker.createAnomalyDetectionEngine()
    return {
        name = "anomaly_detection",
        
        analyze = function(self, behaviorData)
            return PlayerBehaviorTracker.detectAnomalies(behaviorData)
        end
    }
end

function PlayerBehaviorTracker.runBehaviorAnalysis()
    -- Analyze recent player behavior
    for userId, session in pairs(TrackingState.activeSessions) do
        if #session.events > 0 then
            PlayerBehaviorTracker.analyzePlayerBehavior(userId, session.events)
        end
    end
    
    -- Run global analysis
    PlayerBehaviorTracker.analyzeGlobalBehaviorTrends()
end

function PlayerBehaviorTracker.analyzePlayerBehavior(userId, events)
    local analysis = {
        userId = userId,
        eventCount = #events,
        patterns = {},
        anomalies = {},
        engagement = {},
        timestamp = tick()
    }
    
    -- Pattern recognition
    analysis.patterns = TrackingState.analysisEngines.patternRecognition:analyze(events)
    
    -- Anomaly detection
    analysis.anomalies = TrackingState.analysisEngines.anomalyDetection:analyze(events)
    
    -- Engagement analysis
    analysis.engagement = PlayerBehaviorTracker.calculateEngagementMetrics(events)
    
    -- Store analysis results
    if not TrackingState.playerProfiles[userId] then
        TrackingState.playerProfiles[userId] = {}
    end
    table.insert(TrackingState.playerProfiles[userId], analysis)
    
    return analysis
end

function PlayerBehaviorTracker.analyzeGlobalBehaviorTrends()
    local globalAnalysis = {
        totalPlayers = 0,
        averageEngagement = 0,
        topPatterns = {},
        commonPaths = {},
        conversionRates = {},
        timestamp = tick()
    }
    
    -- Calculate global metrics
    for userId, profile in pairs(TrackingState.playerProfiles) do
        globalAnalysis.totalPlayers = globalAnalysis.totalPlayers + 1
        
        if #profile > 0 then
            local latestAnalysis = profile[#profile]
            if latestAnalysis.engagement.score then
                globalAnalysis.averageEngagement = globalAnalysis.averageEngagement + 
                    latestAnalysis.engagement.score
            end
        end
    end
    
    if globalAnalysis.totalPlayers > 0 then
        globalAnalysis.averageEngagement = globalAnalysis.averageEngagement / globalAnalysis.totalPlayers
    end
    
    -- Store global analysis
    TrackingState.globalAnalysis = globalAnalysis
    
    return globalAnalysis
end

-- ========================================
-- PATTERN RECOGNITION
-- ========================================

function PlayerBehaviorTracker.recognizePlayerPatterns(events)
    local patterns = {
        sequence = PlayerBehaviorTracker.findSequencePatterns(events),
        timing = PlayerBehaviorTracker.findTimingPatterns(events),
        frequency = PlayerBehaviorTracker.findFrequencyPatterns(events),
        clustering = PlayerBehaviorTracker.findEventClusters(events)
    }
    
    return patterns
end

function PlayerBehaviorTracker.findSequencePatterns(events)
    local sequences = {}
    local commonSequences = {}
    
    -- Look for common event sequences
    for i = 1, #events - 2 do
        local sequence = {
            events[i].eventName,
            events[i + 1].eventName,
            events[i + 2].eventName
        }
        
        local sequenceKey = table.concat(sequence, "->")
        sequences[sequenceKey] = (sequences[sequenceKey] or 0) + 1
    end
    
    -- Find most common sequences
    for sequence, count in pairs(sequences) do
        if count >= 3 then -- Minimum threshold
            table.insert(commonSequences, {
                sequence = sequence,
                count = count,
                frequency = count / #events
            })
        end
    end
    
    -- Sort by frequency
    table.sort(commonSequences, function(a, b) return a.count > b.count end)
    
    return commonSequences
end

function PlayerBehaviorTracker.findTimingPatterns(events)
    local timingPatterns = {
        averageInterval = 0,
        burstPatterns = {},
        quietPeriods = {}
    }
    
    if #events < 2 then return timingPatterns end
    
    local intervals = {}
    for i = 2, #events do
        local interval = events[i].timestamp - events[i-1].timestamp
        table.insert(intervals, interval)
    end
    
    -- Calculate average interval
    local totalInterval = 0
    for _, interval in ipairs(intervals) do
        totalInterval = totalInterval + interval
    end
    timingPatterns.averageInterval = totalInterval / #intervals
    
    -- Detect burst patterns (rapid succession of events)
    local burstThreshold = timingPatterns.averageInterval * 0.5
    local currentBurst = {}
    
    for i, interval in ipairs(intervals) do
        if interval <= burstThreshold then
            table.insert(currentBurst, i)
        else
            if #currentBurst >= 3 then
                table.insert(timingPatterns.burstPatterns, {
                    startIndex = currentBurst[1],
                    endIndex = currentBurst[#currentBurst],
                    eventCount = #currentBurst + 1,
                    duration = events[currentBurst[#currentBurst] + 1].timestamp - 
                              events[currentBurst[1]].timestamp
                })
            end
            currentBurst = {}
        end
    end
    
    return timingPatterns
end

function PlayerBehaviorTracker.findFrequencyPatterns(events)
    local frequencies = {}
    
    -- Count event frequencies
    for _, event in ipairs(events) do
        frequencies[event.eventName] = (frequencies[event.eventName] or 0) + 1
    end
    
    -- Convert to frequency patterns
    local patterns = {}
    for eventName, count in pairs(frequencies) do
        table.insert(patterns, {
            eventName = eventName,
            count = count,
            frequency = count / #events,
            category = event.category
        })
    end
    
    -- Sort by frequency
    table.sort(patterns, function(a, b) return a.count > b.count end)
    
    return patterns
end

function PlayerBehaviorTracker.findEventClusters(events)
    local clusters = {}
    local timeWindow = 60 -- 1 minute window
    
    for i = 1, #events do
        local event = events[i]
        local cluster = {
            centerEvent = event,
            events = {event},
            startTime = event.timestamp,
            endTime = event.timestamp
        }
        
        -- Find events within time window
        for j = i + 1, #events do
            local nextEvent = events[j]
            if nextEvent.timestamp - event.timestamp <= timeWindow then
                table.insert(cluster.events, nextEvent)
                cluster.endTime = nextEvent.timestamp
            else
                break
            end
        end
        
        -- Only keep clusters with multiple events
        if #cluster.events > 1 then
            cluster.duration = cluster.endTime - cluster.startTime
            cluster.intensity = #cluster.events / cluster.duration
            table.insert(clusters, cluster)
        end
    end
    
    return clusters
end

-- ========================================
-- ENGAGEMENT METRICS
-- ========================================

function PlayerBehaviorTracker.calculateEngagementMetrics(events)
    local metrics = {
        score = 0,
        eventCount = #events,
        timeSpent = 0,
        interactionRate = 0,
        diversityScore = 0,
        consistencyScore = 0
    }
    
    if #events == 0 then return metrics end
    
    -- Calculate time spent
    local firstEvent = events[1]
    local lastEvent = events[#events]
    metrics.timeSpent = lastEvent.timestamp - firstEvent.timestamp
    
    -- Calculate interaction rate (events per minute)
    if metrics.timeSpent > 0 then
        metrics.interactionRate = (#events / metrics.timeSpent) * 60
    end
    
    -- Calculate diversity score (variety of event types)
    local uniqueEvents = {}
    for _, event in ipairs(events) do
        uniqueEvents[event.eventName] = true
    end
    metrics.diversityScore = PlayerBehaviorTracker.tableLength(uniqueEvents) / #events
    
    -- Calculate consistency score (regularity of actions)
    local intervals = {}
    for i = 2, #events do
        table.insert(intervals, events[i].timestamp - events[i-1].timestamp)
    end
    
    if #intervals > 0 then
        local avgInterval = 0
        for _, interval in ipairs(intervals) do
            avgInterval = avgInterval + interval
        end
        avgInterval = avgInterval / #intervals
        
        local variance = 0
        for _, interval in ipairs(intervals) do
            variance = variance + (interval - avgInterval) ^ 2
        end
        variance = variance / #intervals
        
        metrics.consistencyScore = 1 / (1 + variance) -- Lower variance = higher consistency
    end
    
    -- Calculate overall engagement score
    metrics.score = (metrics.interactionRate * 0.4) + 
                   (metrics.diversityScore * 0.3) + 
                   (metrics.consistencyScore * 0.3)
    
    return metrics
end

-- ========================================
-- REAL-TIME TRACKING
-- ========================================

function PlayerBehaviorTracker.initializeRealtimeTracking()
    -- Set up input tracking
    if UserInputService then
        UserInputService.InputBegan:Connect(function(input, gameProcessed)
            if not gameProcessed then
                local player = Players.LocalPlayer
                if player then
                    PlayerBehaviorTracker.trackInputEvent(player.UserId, input)
                end
            end
        end)
    end
    
    -- Set up position tracking
    spawn(function()
        while true do
            PlayerBehaviorTracker.trackPlayerPositions()
            task.wait(TRACKING_CONFIG.intervals.activity)
        end
    end)
    
    -- Set up activity monitoring
    spawn(function()
        while true do
            PlayerBehaviorTracker.monitorPlayerActivity()
            task.wait(TRACKING_CONFIG.intervals.activity)
        end
    end)
    
    print("⚡ Real-time tracking enabled")
end

function PlayerBehaviorTracker.trackInputEvent(userId, input)
    local inputData = {
        inputType = input.UserInputType.Name,
        keyCode = input.KeyCode and input.KeyCode.Name or nil,
        position = input.Position and {
            X = input.Position.X,
            Y = input.Position.Y,
            Z = input.Position.Z
        } or nil
    }
    
    PlayerBehaviorTracker.trackEvent(userId, "input_event", "gameplay", inputData)
    PlayerBehaviorTracker.updatePlayerActivity(userId)
end

function PlayerBehaviorTracker.trackPlayerPositions()
    for _, player in ipairs(Players:GetPlayers()) do
        if player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
            local position = player.Character.HumanoidRootPart.Position
            
            PlayerBehaviorTracker.trackEvent(player.UserId, "position_update", "gameplay", {
                x = position.X,
                y = position.Y,
                z = position.Z,
                mapArea = PlayerBehaviorTracker.getMapArea(position)
            })
        end
    end
end

function PlayerBehaviorTracker.monitorPlayerActivity()
    for userId, session in pairs(TrackingState.activeSessions) do
        local player = Players:GetPlayerByUserId(userId)
        if player then
            local activityLevel = PlayerBehaviorTracker.calculateActivityLevel(userId)
            
            PlayerBehaviorTracker.trackEvent(userId, "activity_check", "engagement", {
                activityLevel = activityLevel,
                sessionDuration = session.duration,
                eventCount = #session.events
            })
        end
    end
end

function PlayerBehaviorTracker.calculateActivityLevel(userId)
    local session = TrackingState.activeSessions[userId]
    if not session then return 0 end
    
    local recentEvents = 0
    local currentTime = tick()
    
    -- Count events in the last 5 minutes
    for _, event in ipairs(session.events) do
        if currentTime - event.timestamp <= 300 then
            recentEvents = recentEvents + 1
        end
    end
    
    -- Normalize to 0-1 scale
    return math.min(recentEvents / 20, 1) -- 20 events = 100% activity
end

-- ========================================
-- DATA PROCESSING
-- ========================================

function PlayerBehaviorTracker.setupDataProcessing()
    -- Start data cleanup processes
    spawn(function()
        while true do
            PlayerBehaviorTracker.cleanupOldData()
            task.wait(3600) -- Run every hour
        end
    end)
    
    -- Start data aggregation
    spawn(function()
        while true do
            PlayerBehaviorTracker.aggregateBehaviorData()
            task.wait(1800) -- Run every 30 minutes
        end
    end)
    
    print("🔄 Data processing systems started")
end

function PlayerBehaviorTracker.cleanupOldData()
    local currentTime = tick()
    local retentionTime = TRACKING_CONFIG.retention.daily
    
    -- Clean up old events
    local newEventHistory = {}
    for _, event in ipairs(TrackingState.eventHistory) do
        if currentTime - event.timestamp <= retentionTime then
            table.insert(newEventHistory, event)
        end
    end
    TrackingState.eventHistory = newEventHistory
    
    -- Clean up old sessions
    local newSessionHistory = {}
    for _, session in ipairs(TrackingState.sessionHistory) do
        if currentTime - session.startTime <= retentionTime then
            table.insert(newSessionHistory, session)
        end
    end
    TrackingState.sessionHistory = newSessionHistory
    
    print("🧹 Old data cleanup completed")
end

function PlayerBehaviorTracker.aggregateBehaviorData()
    local aggregatedData = {
        timestamp = tick(),
        playerCount = PlayerBehaviorTracker.tableLength(TrackingState.activeSessions),
        totalEvents = TrackingState.stats.totalEvents,
        averageSessionLength = TrackingState.stats.averageSessionLength,
        topEvents = PlayerBehaviorTracker.getTopEvents(),
        engagementTrends = PlayerBehaviorTracker.getEngagementTrends()
    }
    
    -- Store aggregated data
    if not TrackingState.aggregatedData then
        TrackingState.aggregatedData = {}
    end
    table.insert(TrackingState.aggregatedData, aggregatedData)
    
    print("📊 Behavior data aggregation completed")
end

function PlayerBehaviorTracker.getTopEvents()
    local eventCounts = {}
    
    for _, event in ipairs(TrackingState.eventHistory) do
        eventCounts[event.eventName] = (eventCounts[event.eventName] or 0) + 1
    end
    
    local topEvents = {}
    for eventName, count in pairs(eventCounts) do
        table.insert(topEvents, {eventName = eventName, count = count})
    end
    
    table.sort(topEvents, function(a, b) return a.count > b.count end)
    
    return {topEvents[1], topEvents[2], topEvents[3]} -- Top 3
end

function PlayerBehaviorTracker.getEngagementTrends()
    local trends = {
        currentEngagement = 0,
        engagementHistory = {},
        trend = "stable"
    }
    
    -- Calculate current engagement
    local totalEngagement = 0
    local playerCount = 0
    
    for userId, profile in pairs(TrackingState.playerProfiles) do
        if #profile > 0 then
            local latestAnalysis = profile[#profile]
            if latestAnalysis.engagement.score then
                totalEngagement = totalEngagement + latestAnalysis.engagement.score
                playerCount = playerCount + 1
            end
        end
    end
    
    if playerCount > 0 then
        trends.currentEngagement = totalEngagement / playerCount
    end
    
    return trends
end

-- ========================================
-- UTILITY FUNCTIONS
-- ========================================

function PlayerBehaviorTracker.getGameContext()
    return {
        gameId = game.GameId,
        placeId = game.PlaceId,
        serverId = game.JobId,
        timestamp = tick()
    }
end

function PlayerBehaviorTracker.getPlayerContext(userId)
    local player = Players:GetPlayerByUserId(userId)
    if not player then return {} end
    
    return {
        displayName = player.DisplayName,
        accountAge = player.AccountAge,
        membershipType = player.MembershipType.Name,
        platform = PlayerBehaviorTracker.getPlayerPlatform(userId)
    }
end

function PlayerBehaviorTracker.getPlayerPlatform(userId)
    -- Simplified platform detection
    return "Unknown"
end

function PlayerBehaviorTracker.getMapArea(position)
    -- Simplified map area detection
    if position.X > 0 and position.Z > 0 then
        return "Northeast"
    elseif position.X > 0 and position.Z <= 0 then
        return "Southeast"
    elseif position.X <= 0 and position.Z > 0 then
        return "Northwest"
    else
        return "Southwest"
    end
end

function PlayerBehaviorTracker.updateUniquePlayerCount()
    local uniquePlayers = {}
    for userId in pairs(TrackingState.activeSessions) do
        uniquePlayers[userId] = true
    end
    for _, session in ipairs(TrackingState.sessionHistory) do
        uniquePlayers[session.userId] = true
    end
    
    TrackingState.stats.uniquePlayers = PlayerBehaviorTracker.tableLength(uniquePlayers)
end

function PlayerBehaviorTracker.updateSessionStatistics(duration)
    local totalDuration = TrackingState.stats.averageSessionLength * (TrackingState.stats.totalSessions - 1)
    totalDuration = totalDuration + duration
    TrackingState.stats.averageSessionLength = totalDuration / TrackingState.stats.totalSessions
end

function PlayerBehaviorTracker.tableLength(t)
    local count = 0
    for _ in pairs(t) do
        count = count + 1
    end
    return count
end

-- ========================================
-- EVENT PROCESSORS
-- ========================================

function PlayerBehaviorTracker.processGameplayEvent(event)
    event.processed = true
    event.gameplayData = {
        isCore = PlayerBehaviorTracker.isCoreGameplayEvent(event.eventName),
        skillLevel = PlayerBehaviorTracker.estimateSkillLevel(event),
        difficulty = PlayerBehaviorTracker.estimateDifficulty(event)
    }
    return event
end

function PlayerBehaviorTracker.processNavigationEvent(event)
    event.processed = true
    event.navigationData = {
        pathDepth = PlayerBehaviorTracker.calculatePathDepth(event),
        isBacktrack = PlayerBehaviorTracker.isBacktrackEvent(event),
        efficiency = PlayerBehaviorTracker.calculateNavigationEfficiency(event)
    }
    return event
end

function PlayerBehaviorTracker.processSocialEvent(event)
    event.processed = true
    event.socialData = {
        interactionType = PlayerBehaviorTracker.getSocialInteractionType(event.eventName),
        socialScore = PlayerBehaviorTracker.calculateSocialScore(event)
    }
    return event
end

function PlayerBehaviorTracker.processEconomyEvent(event)
    event.processed = true
    event.economyData = {
        transactionValue = PlayerBehaviorTracker.getTransactionValue(event),
        economicImpact = PlayerBehaviorTracker.calculateEconomicImpact(event)
    }
    return event
end

function PlayerBehaviorTracker.processEngagementEvent(event)
    event.processed = true
    event.engagementData = {
        engagementWeight = PlayerBehaviorTracker.getEngagementWeight(event.eventName),
        retentionImpact = PlayerBehaviorTracker.calculateRetentionImpact(event)
    }
    return event
end

-- Simplified implementations for demonstration
function PlayerBehaviorTracker.isCoreGameplayEvent(eventName)
    local coreEvents = {"level_start", "level_complete", "score_achieved", "power_up_used"}
    for _, coreEvent in ipairs(coreEvents) do
        if eventName == coreEvent then return true end
    end
    return false
end

function PlayerBehaviorTracker.estimateSkillLevel(event)
    return math.random(1, 10) -- Simplified skill estimation
end

function PlayerBehaviorTracker.estimateDifficulty(event)
    return math.random(1, 5) -- Simplified difficulty estimation
end

function PlayerBehaviorTracker.calculatePathDepth(event)
    return math.random(1, 5) -- Simplified path depth
end

function PlayerBehaviorTracker.isBacktrackEvent(event)
    return math.random() > 0.7 -- 30% chance of backtrack
end

function PlayerBehaviorTracker.calculateNavigationEfficiency(event)
    return math.random(50, 100) / 100 -- 50-100% efficiency
end

function PlayerBehaviorTracker.getSocialInteractionType(eventName)
    if string.find(eventName, "friend") then return "friendship"
    elseif string.find(eventName, "message") then return "communication"
    elseif string.find(eventName, "party") then return "group"
    else return "other"
    end
end

function PlayerBehaviorTracker.calculateSocialScore(event)
    return math.random(1, 10) -- Simplified social score
end

function PlayerBehaviorTracker.getTransactionValue(event)
    return math.random(1, 100) -- $1-100 transaction value
end

function PlayerBehaviorTracker.calculateEconomicImpact(event)
    return math.random(1, 5) -- Impact score 1-5
end

function PlayerBehaviorTracker.getEngagementWeight(eventName)
    local weights = {
        session_started = 5,
        level_complete = 8,
        purchase_completed = 10,
        friend_added = 6,
        achievement_shared = 7
    }
    return weights[eventName] or 3
end

function PlayerBehaviorTracker.calculateRetentionImpact(event)
    return math.random(1, 10) / 10 -- 0.1-1.0 retention impact
end

-- ========================================
-- PUBLIC API
-- ========================================

function PlayerBehaviorTracker.runTrackingDemo()
    print("👤 Running player behavior tracking demonstration...")
    
    -- Simulate player events
    local sampleUserId = 12345
    PlayerBehaviorTracker.startPlayerSession(sampleUserId)
    
    print("  📊 Tracking sample events...")
    
    -- Simulate various events
    local sampleEvents = {
        {name = "level_start", category = "gameplay", props = {level = 1}},
        {name = "menu_opened", category = "navigation", props = {menu = "settings"}},
        {name = "purchase_initiated", category = "economy", props = {item = "coin_pack", price = 4.99}},
        {name = "friend_added", category = "social", props = {friendId = 67890}},
        {name = "achievement_unlocked", category = "engagement", props = {achievement = "first_win"}}
    }
    
    for _, eventData in ipairs(sampleEvents) do
        PlayerBehaviorTracker.trackEvent(sampleUserId, eventData.name, eventData.category, eventData.props)
        task.wait(0.5)
    end
    
    -- Wait for processing
    task.wait(2)
    
    -- Perform analysis
    print("  🧠 Analyzing behavior patterns...")
    local session = TrackingState.activeSessions[sampleUserId]
    if session then
        local analysis = PlayerBehaviorTracker.analyzePlayerBehavior(sampleUserId, session.events)
        print(string.format("    Events analyzed: %d", analysis.eventCount))
        print(string.format("    Engagement score: %.2f", analysis.engagement.score))
        print(string.format("    Patterns found: %d", #analysis.patterns.frequency))
    end
    
    -- Show global trends
    print("  🌍 Global behavior trends:")
    local globalAnalysis = PlayerBehaviorTracker.analyzeGlobalBehaviorTrends()
    print(string.format("    Total players: %d", globalAnalysis.totalPlayers))
    print(string.format("    Average engagement: %.2f", globalAnalysis.averageEngagement))
    
    -- Show tracking statistics
    local stats = PlayerBehaviorTracker.getTrackingStats()
    print("  📈 Tracking Statistics:")
    print(string.format("    Total events: %d", stats.totalEvents))
    print(string.format("    Events per second: %.1f", stats.eventsPerSecond))
    print(string.format("    Unique players: %d", stats.uniquePlayers))
    print(string.format("    Average session: %.1fs", stats.averageSessionLength))
    print(string.format("    Data points: %d", stats.dataPointsCollected))
    
    -- End session
    PlayerBehaviorTracker.endPlayerSession(sampleUserId)
    
    print("👤 Player behavior tracking demonstration completed")
end

function PlayerBehaviorTracker.getTrackingStats()
    return TrackingState.stats
end

function PlayerBehaviorTracker.getPlayerProfile(userId)
    return TrackingState.playerProfiles[userId]
end

function PlayerBehaviorTracker.getActiveSessions()
    return TrackingState.activeSessions
end

function PlayerBehaviorTracker.getBehaviorPatterns()
    return TrackingState.behaviorPatterns
end

-- Export API
PlayerBehaviorTracker.trackEvent = PlayerBehaviorTracker.trackEvent
PlayerBehaviorTracker.startPlayerSession = PlayerBehaviorTracker.startPlayerSession
PlayerBehaviorTracker.endPlayerSession = PlayerBehaviorTracker.endPlayerSession
PlayerBehaviorTracker.analyzePlayerBehavior = PlayerBehaviorTracker.analyzePlayerBehavior

-- Initialize the player behavior tracker
PlayerBehaviorTracker.initialize()

print("👤 PlayerBehaviorTracker loaded with comprehensive behavior analysis")

return PlayerBehaviorTracker
