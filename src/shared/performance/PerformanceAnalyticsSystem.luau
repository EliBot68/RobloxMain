-- PerformanceAnalyticsSystem.luau
-- Comprehensive performance analytics and user experience tracking system
-- Collects, analyzes, and reports on performance metrics and user experience data

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local TeleportService = game:GetService("TeleportService")

local SafeRequire = require(ReplicatedStorage.Shared.utils.SafeRequire)

local PerformanceAnalyticsSystem = {}

-- ========================================
-- ANALYTICS CONFIGURATION
-- ========================================

local ANALYTICS_CONFIG = {
    -- Data collection settings
    collection = {
        enablePerformanceTracking = true,
        enableUserExperienceTracking = true,
        enableRealTimeAnalytics = true,
        enableSessionTracking = true,
        sampleRate = 1.0,                    -- 100% sampling rate
        batchSize = 50,                      -- Events per batch
        batchTimeout = 30000,                -- 30 seconds
        maxStorageSize = 10485760            -- 10MB local storage
    },
    
    -- Performance metrics
    performanceMetrics = {
        frameRate = {interval = 1, enabled = true},
        memoryUsage = {interval = 5, enabled = true},
        loadTimes = {enabled = true},
        networkLatency = {interval = 10, enabled = true},
        renderPerformance = {interval = 2, enabled = true},
        scriptPerformance = {interval = 5, enabled = true},
        devicePerformance = {interval = 60, enabled = true}
    },
    
    -- User experience metrics
    userExperienceMetrics = {
        sessionDuration = {enabled = true},
        interactionLatency = {enabled = true},
        errorRate = {enabled = true},
        crashRate = {enabled = true},
        loadingExperience = {enabled = true},
        navigationMetrics = {enabled = true},
        engagementMetrics = {enabled = true},
        satisfactionMetrics = {enabled = true}
    },
    
    -- Analytics processing
    processing = {
        enableRealTimeAlerts = true,
        enableTrendAnalysis = true,
        enablePredictiveAnalytics = true,
        enablePerformanceScoring = true,
        alertThresholds = {
            criticalFPS = 15,
            warningFPS = 30,
            criticalMemory = 1024,      -- MB
            warningMemory = 512,        -- MB
            criticalLatency = 500,      -- ms
            warningLatency = 200        -- ms
        }
    },
    
    -- Reporting settings
    reporting = {
        enableAutomaticReports = true,
        reportInterval = 3600,              -- 1 hour
        enableDashboard = true,
        enableExports = true,
        retentionPeriod = 2592000            -- 30 days
    }
}

-- ========================================
-- ANALYTICS SYSTEM STATE
-- ========================================

local AnalyticsState = {
    -- Data collection
    performanceData = {},
    userExperienceData = {},
    sessionData = {},
    eventQueue = {},
    
    -- Real-time tracking
    currentSession = nil,
    realTimeMetrics = {},
    
    -- Analytics processing
    processedAnalytics = {},
    performanceScore = 0,
    trendData = {},
    alertHistory = {},
    
    -- User tracking
    userId = nil,
    userProfile = {},
    userBehavior = {},
    
    -- System state
    isTracking = false,
    startTime = 0,
    connections = {},
    
    -- Statistics
    stats = {
        eventsCollected = 0,
        sessionCount = 0,
        totalPlayTime = 0,
        averagePerformance = 0,
        userExperienceScore = 0
    }
}

function PerformanceAnalyticsSystem.initialize()
    print("📊 Initializing PerformanceAnalyticsSystem...")
    
    -- Initialize user tracking
    PerformanceAnalyticsSystem.initializeUserTracking()
    
    -- Start session tracking
    PerformanceAnalyticsSystem.startSessionTracking()
    
    -- Set up performance data collection
    PerformanceAnalyticsSystem.setupPerformanceCollection()
    
    -- Set up user experience tracking
    PerformanceAnalyticsSystem.setupUserExperienceTracking()
    
    -- Initialize real-time analytics
    PerformanceAnalyticsSystem.initializeRealTimeAnalytics()
    
    -- Start analytics processing
    PerformanceAnalyticsSystem.startAnalyticsProcessing()
    
    -- Set up reporting system
    PerformanceAnalyticsSystem.setupReportingSystem()
    
    AnalyticsState.isTracking = true
    AnalyticsState.startTime = tick()
    
    print("📊 PerformanceAnalyticsSystem initialized successfully")
end

-- ========================================
-- USER TRACKING
-- ========================================

function PerformanceAnalyticsSystem.initializeUserTracking()
    local player = Players.LocalPlayer
    
    if player then
        AnalyticsState.userId = player.UserId
        AnalyticsState.userProfile = {
            userId = player.UserId,
            username = player.Name,
            displayName = player.DisplayName,
            accountAge = player.AccountAge,
            membershipType = tostring(player.MembershipType),
            joinTime = tick()
        }
        
        -- Initialize user behavior tracking
        PerformanceAnalyticsSystem.initializeUserBehaviorTracking()
    end
    
    print(string.format("👤 User tracking initialized for: %s", AnalyticsState.userProfile.username or "Unknown"))
end

function PerformanceAnalyticsSystem.initializeUserBehaviorTracking()
    AnalyticsState.userBehavior = {
        interactions = {},
        navigation = {},
        preferences = {},
        performanceImpact = {}
    }
    
    -- Track user input for interaction analysis
    if UserInputService then
        AnalyticsState.connections.inputTracker = UserInputService.InputBegan:Connect(function(input)
            PerformanceAnalyticsSystem.trackUserInteraction(input)
        end)
    end
end

function PerformanceAnalyticsSystem.trackUserInteraction(input)
    local interaction = {
        inputType = tostring(input.UserInputType),
        keyCode = input.KeyCode and tostring(input.KeyCode) or nil,
        timestamp = tick(),
        sessionTime = tick() - AnalyticsState.startTime
    }
    
    table.insert(AnalyticsState.userBehavior.interactions, interaction)
    
    -- Limit interaction history
    if #AnalyticsState.userBehavior.interactions > 1000 then
        table.remove(AnalyticsState.userBehavior.interactions, 1)
    end
    
    -- Track interaction latency
    PerformanceAnalyticsSystem.measureInteractionLatency(interaction)
end

function PerformanceAnalyticsSystem.measureInteractionLatency(interaction)
    local currentFPS = 1 / RunService.Heartbeat:Wait()
    local responseTime = 1000 / currentFPS -- Convert to milliseconds
    
    local latencyData = {
        interactionType = interaction.inputType,
        responseTime = responseTime,
        timestamp = interaction.timestamp,
        fps = currentFPS
    }
    
    PerformanceAnalyticsSystem.recordUserExperienceMetric("interactionLatency", latencyData)
end

-- ========================================
-- SESSION TRACKING
-- ========================================

function PerformanceAnalyticsSystem.startSessionTracking()
    local sessionId = HttpService:GenerateGUID(false)
    
    AnalyticsState.currentSession = {
        sessionId = sessionId,
        userId = AnalyticsState.userId,
        startTime = tick(),
        deviceInfo = PerformanceAnalyticsSystem.getDeviceInfo(),
        performanceProfile = PerformanceAnalyticsSystem.getInitialPerformanceProfile(),
        events = {},
        metrics = {}
    }
    
    AnalyticsState.stats.sessionCount = AnalyticsState.stats.sessionCount + 1
    
    -- Track session end
    AnalyticsState.connections.sessionEnd = Players.PlayerRemoving:Connect(function(player)
        if player == Players.LocalPlayer then
            PerformanceAnalyticsSystem.endSession()
        end
    end)
    
    print(string.format("📅 Session started: %s", sessionId))
end

function PerformanceAnalyticsSystem.getDeviceInfo()
    return {
        platform = PerformanceAnalyticsSystem.detectPlatform(),
        inputMethods = PerformanceAnalyticsSystem.getInputMethods(),
        screenSize = PerformanceAnalyticsSystem.getScreenInfo(),
        performanceTier = PerformanceAnalyticsSystem.estimatePerformanceTier()
    }
end

function PerformanceAnalyticsSystem.detectPlatform()
    if UserInputService.TouchEnabled then
        return UserInputService.AccelerometerEnabled and "Mobile" or "Tablet"
    elseif UserInputService.GamepadEnabled then
        return "Console"
    elseif UserInputService.KeyboardEnabled then
        return "PC"
    else
        return "Unknown"
    end
end

function PerformanceAnalyticsSystem.getInputMethods()
    return {
        touch = UserInputService.TouchEnabled,
        keyboard = UserInputService.KeyboardEnabled,
        mouse = UserInputService.MouseEnabled,
        gamepad = UserInputService.GamepadEnabled
    }
end

function PerformanceAnalyticsSystem.getScreenInfo()
    local camera = workspace.CurrentCamera
    return {
        viewportSize = camera and camera.ViewportSize or Vector2.new(1920, 1080),
        aspectRatio = camera and (camera.ViewportSize.X / camera.ViewportSize.Y) or 16/9
    }
end

function PerformanceAnalyticsSystem.estimatePerformanceTier()
    local fps = 1 / RunService.Heartbeat:Wait()
    local memory = collectgarbage("count") / 1024
    
    if fps >= 55 and memory <= 256 then
        return "High"
    elseif fps >= 35 and memory <= 512 then
        return "Medium"
    else
        return "Low"
    end
end

function PerformanceAnalyticsSystem.getInitialPerformanceProfile()
    return {
        initialFPS = 1 / RunService.Heartbeat:Wait(),
        initialMemory = collectgarbage("count") / 1024,
        loadStartTime = tick()
    }
end

function PerformanceAnalyticsSystem.endSession()
    if not AnalyticsState.currentSession then
        return
    end
    
    local session = AnalyticsState.currentSession
    session.endTime = tick()
    session.duration = session.endTime - session.startTime
    session.finalPerformanceProfile = PerformanceAnalyticsSystem.getFinalPerformanceProfile()
    
    -- Calculate session metrics
    session.summary = PerformanceAnalyticsSystem.calculateSessionSummary(session)
    
    -- Store session data
    table.insert(AnalyticsState.sessionData, session)
    AnalyticsState.stats.totalPlayTime = AnalyticsState.stats.totalPlayTime + session.duration
    
    print(string.format("📅 Session ended: %.1f seconds", session.duration))
    
    -- Send session data
    PerformanceAnalyticsSystem.queueAnalyticsEvent("sessionEnd", session.summary)
    
    AnalyticsState.currentSession = nil
end

function PerformanceAnalyticsSystem.getFinalPerformanceProfile()
    return {
        finalFPS = 1 / RunService.Heartbeat:Wait(),
        finalMemory = collectgarbage("count") / 1024,
        sessionEndTime = tick()
    }
end

function PerformanceAnalyticsSystem.calculateSessionSummary(session)
    return {
        sessionId = session.sessionId,
        duration = session.duration,
        platform = session.deviceInfo.platform,
        performanceTier = session.deviceInfo.performanceTier,
        averagePerformance = AnalyticsState.performanceScore,
        userExperienceScore = AnalyticsState.stats.userExperienceScore,
        eventCount = #session.events,
        interactionCount = #AnalyticsState.userBehavior.interactions
    }
end

-- ========================================
-- PERFORMANCE DATA COLLECTION
-- ========================================

function PerformanceAnalyticsSystem.setupPerformanceCollection()
    -- Set up frame rate monitoring
    if ANALYTICS_CONFIG.performanceMetrics.frameRate.enabled then
        AnalyticsState.connections.fpsMonitor = task.spawn(function()
            while AnalyticsState.isTracking do
                PerformanceAnalyticsSystem.collectFrameRateData()
                task.wait(ANALYTICS_CONFIG.performanceMetrics.frameRate.interval)
            end
        end)
    end
    
    -- Set up memory monitoring
    if ANALYTICS_CONFIG.performanceMetrics.memoryUsage.enabled then
        AnalyticsState.connections.memoryMonitor = task.spawn(function()
            while AnalyticsState.isTracking do
                PerformanceAnalyticsSystem.collectMemoryData()
                task.wait(ANALYTICS_CONFIG.performanceMetrics.memoryUsage.interval)
            end
        end)
    end
    
    -- Set up network latency monitoring
    if ANALYTICS_CONFIG.performanceMetrics.networkLatency.enabled then
        AnalyticsState.connections.networkMonitor = task.spawn(function()
            while AnalyticsState.isTracking do
                PerformanceAnalyticsSystem.collectNetworkData()
                task.wait(ANALYTICS_CONFIG.performanceMetrics.networkLatency.interval)
            end
        end)
    end
    
    -- Set up render performance monitoring
    if ANALYTICS_CONFIG.performanceMetrics.renderPerformance.enabled then
        AnalyticsState.connections.renderMonitor = task.spawn(function()
            while AnalyticsState.isTracking do
                PerformanceAnalyticsSystem.collectRenderData()
                task.wait(ANALYTICS_CONFIG.performanceMetrics.renderPerformance.interval)
            end
        end)
    end
    
    print("📈 Performance data collection started")
end

function PerformanceAnalyticsSystem.collectFrameRateData()
    local fps = 1 / RunService.Heartbeat:Wait()
    local timestamp = tick()
    
    local fpsData = {
        fps = fps,
        timestamp = timestamp,
        sessionTime = timestamp - AnalyticsState.startTime
    }
    
    PerformanceAnalyticsSystem.recordPerformanceMetric("frameRate", fpsData)
    
    -- Update real-time metrics
    AnalyticsState.realTimeMetrics.currentFPS = fps
    
    -- Check for performance alerts
    PerformanceAnalyticsSystem.checkPerformanceAlert("fps", fps)
end

function PerformanceAnalyticsSystem.collectMemoryData()
    local memory = collectgarbage("count") / 1024 -- Convert to MB
    local timestamp = tick()
    
    local memoryData = {
        memory = memory,
        timestamp = timestamp,
        sessionTime = timestamp - AnalyticsState.startTime
    }
    
    PerformanceAnalyticsSystem.recordPerformanceMetric("memoryUsage", memoryData)
    
    -- Update real-time metrics
    AnalyticsState.realTimeMetrics.currentMemory = memory
    
    -- Check for memory alerts
    PerformanceAnalyticsSystem.checkPerformanceAlert("memory", memory)
end

function PerformanceAnalyticsSystem.collectNetworkData()
    local latency = PerformanceAnalyticsSystem.measureNetworkLatency()
    local timestamp = tick()
    
    local networkData = {
        latency = latency,
        timestamp = timestamp,
        sessionTime = timestamp - AnalyticsState.startTime
    }
    
    PerformanceAnalyticsSystem.recordPerformanceMetric("networkLatency", networkData)
    
    -- Update real-time metrics
    AnalyticsState.realTimeMetrics.currentLatency = latency
    
    -- Check for latency alerts
    PerformanceAnalyticsSystem.checkPerformanceAlert("latency", latency)
end

function PerformanceAnalyticsSystem.collectRenderData()
    local renderTime = PerformanceAnalyticsSystem.estimateRenderTime()
    local timestamp = tick()
    
    local renderData = {
        renderTime = renderTime,
        timestamp = timestamp,
        sessionTime = timestamp - AnalyticsState.startTime
    }
    
    PerformanceAnalyticsSystem.recordPerformanceMetric("renderPerformance", renderData)
end

function PerformanceAnalyticsSystem.measureNetworkLatency()
    -- Simulate network latency measurement
    return math.random(20, 150)
end

function PerformanceAnalyticsSystem.estimateRenderTime()
    -- Estimate render time based on frame time
    local frameTime = RunService.Heartbeat:Wait()
    return frameTime * 0.6 * 1000 -- Estimate 60% of frame time for rendering, convert to ms
end

function PerformanceAnalyticsSystem.recordPerformanceMetric(metricType, data)
    if not AnalyticsState.performanceData[metricType] then
        AnalyticsState.performanceData[metricType] = {}
    end
    
    table.insert(AnalyticsState.performanceData[metricType], data)
    
    -- Limit data retention
    local maxEntries = 3600 -- Keep 1 hour of data at 1-second intervals
    if #AnalyticsState.performanceData[metricType] > maxEntries then
        table.remove(AnalyticsState.performanceData[metricType], 1)
    end
    
    -- Queue for analytics processing
    PerformanceAnalyticsSystem.queueAnalyticsEvent("performance", {
        type = metricType,
        data = data
    })
end

function PerformanceAnalyticsSystem.checkPerformanceAlert(alertType, value)
    local thresholds = ANALYTICS_CONFIG.processing.alertThresholds
    local alertLevel = nil
    
    if alertType == "fps" then
        if value <= thresholds.criticalFPS then
            alertLevel = "critical"
        elseif value <= thresholds.warningFPS then
            alertLevel = "warning"
        end
    elseif alertType == "memory" then
        if value >= thresholds.criticalMemory then
            alertLevel = "critical"
        elseif value >= thresholds.warningMemory then
            alertLevel = "warning"
        end
    elseif alertType == "latency" then
        if value >= thresholds.criticalLatency then
            alertLevel = "critical"
        elseif value >= thresholds.warningLatency then
            alertLevel = "warning"
        end
    end
    
    if alertLevel then
        PerformanceAnalyticsSystem.triggerPerformanceAlert(alertType, value, alertLevel)
    end
end

function PerformanceAnalyticsSystem.triggerPerformanceAlert(alertType, value, level)
    if not ANALYTICS_CONFIG.processing.enableRealTimeAlerts then
        return
    end
    
    local alert = {
        type = alertType,
        value = value,
        level = level,
        timestamp = tick(),
        sessionId = AnalyticsState.currentSession and AnalyticsState.currentSession.sessionId or nil
    }
    
    table.insert(AnalyticsState.alertHistory, alert)
    
    -- Log alert
    if level == "critical" then
        warn(string.format("🚨 CRITICAL %s alert: %.1f", string.upper(alertType), value))
    else
        warn(string.format("⚠️ %s alert: %.1f", alertType, value))
    end
    
    -- Queue alert event
    PerformanceAnalyticsSystem.queueAnalyticsEvent("alert", alert)
end

-- ========================================
-- USER EXPERIENCE TRACKING
-- ========================================

function PerformanceAnalyticsSystem.setupUserExperienceTracking()
    -- Track loading experience
    if ANALYTICS_CONFIG.userExperienceMetrics.loadingExperience.enabled then
        PerformanceAnalyticsSystem.trackLoadingExperience()
    end
    
    -- Track navigation metrics
    if ANALYTICS_CONFIG.userExperienceMetrics.navigationMetrics.enabled then
        PerformanceAnalyticsSystem.setupNavigationTracking()
    end
    
    -- Track engagement metrics
    if ANALYTICS_CONFIG.userExperienceMetrics.engagementMetrics.enabled then
        PerformanceAnalyticsSystem.setupEngagementTracking()
    end
    
    print("👥 User experience tracking started")
end

function PerformanceAnalyticsSystem.trackLoadingExperience()
    local loadingStart = tick()
    
    -- Track various loading stages
    local loadingStages = {
        "assetsLoading",
        "modulesLoading", 
        "initialization",
        "firstFrame"
    }
    
    for _, stage in ipairs(loadingStages) do
        PerformanceAnalyticsSystem.recordLoadingStage(stage, loadingStart)
    end
end

function PerformanceAnalyticsSystem.recordLoadingStage(stage, startTime)
    local stageTime = tick() - startTime
    
    local loadingData = {
        stage = stage,
        duration = stageTime * 1000, -- Convert to milliseconds
        timestamp = tick()
    }
    
    PerformanceAnalyticsSystem.recordUserExperienceMetric("loadingExperience", loadingData)
end

function PerformanceAnalyticsSystem.setupNavigationTracking()
    -- Track page/scene transitions (simulated)
    AnalyticsState.connections.navigationTracker = task.spawn(function()
        while AnalyticsState.isTracking do
            -- Simulate navigation events
            if math.random() < 0.01 then -- 1% chance per second
                PerformanceAnalyticsSystem.trackNavigation("sceneTransition")
            end
            task.wait(1)
        end
    end)
end

function PerformanceAnalyticsSystem.trackNavigation(navigationType)
    local navigationData = {
        type = navigationType,
        timestamp = tick(),
        sessionTime = tick() - AnalyticsState.startTime,
        performanceAtNavigation = {
            fps = AnalyticsState.realTimeMetrics.currentFPS or 0,
            memory = AnalyticsState.realTimeMetrics.currentMemory or 0
        }
    }
    
    table.insert(AnalyticsState.userBehavior.navigation, navigationData)
    PerformanceAnalyticsSystem.recordUserExperienceMetric("navigationMetrics", navigationData)
end

function PerformanceAnalyticsSystem.setupEngagementTracking()
    -- Track user engagement through activity
    AnalyticsState.connections.engagementTracker = task.spawn(function()
        local lastActivity = tick()
        
        while AnalyticsState.isTracking do
            local currentTime = tick()
            local timeSinceActivity = currentTime - lastActivity
            
            -- Check if user is still engaged
            if timeSinceActivity > 60 then -- 60 seconds of inactivity
                PerformanceAnalyticsSystem.recordEngagementMetric("inactivity", timeSinceActivity)
                lastActivity = currentTime
            end
            
            task.wait(10) -- Check every 10 seconds
        end
    end)
end

function PerformanceAnalyticsSystem.recordEngagementMetric(metricType, value)
    local engagementData = {
        type = metricType,
        value = value,
        timestamp = tick(),
        sessionTime = tick() - AnalyticsState.startTime
    }
    
    PerformanceAnalyticsSystem.recordUserExperienceMetric("engagementMetrics", engagementData)
end

function PerformanceAnalyticsSystem.recordUserExperienceMetric(metricType, data)
    if not AnalyticsState.userExperienceData[metricType] then
        AnalyticsState.userExperienceData[metricType] = {}
    end
    
    table.insert(AnalyticsState.userExperienceData[metricType], data)
    
    -- Queue for analytics processing
    PerformanceAnalyticsSystem.queueAnalyticsEvent("userExperience", {
        type = metricType,
        data = data
    })
    
    AnalyticsState.stats.eventsCollected = AnalyticsState.stats.eventsCollected + 1
end

-- ========================================
-- REAL-TIME ANALYTICS
-- ========================================

function PerformanceAnalyticsSystem.initializeRealTimeAnalytics()
    if not ANALYTICS_CONFIG.collection.enableRealTimeAnalytics then
        return
    end
    
    AnalyticsState.realTimeMetrics = {
        currentFPS = 0,
        currentMemory = 0,
        currentLatency = 0,
        performanceScore = 0,
        userExperienceScore = 0
    }
    
    -- Start real-time processing
    AnalyticsState.connections.realTimeProcessor = task.spawn(function()
        while AnalyticsState.isTracking do
            PerformanceAnalyticsSystem.processRealTimeMetrics()
            task.wait(5) -- Update every 5 seconds
        end
    end)
    
    print("⚡ Real-time analytics active")
end

function PerformanceAnalyticsSystem.processRealTimeMetrics()
    -- Calculate performance score
    AnalyticsState.performanceScore = PerformanceAnalyticsSystem.calculatePerformanceScore()
    
    -- Calculate user experience score
    AnalyticsState.stats.userExperienceScore = PerformanceAnalyticsSystem.calculateUserExperienceScore()
    
    -- Update real-time metrics
    AnalyticsState.realTimeMetrics.performanceScore = AnalyticsState.performanceScore
    AnalyticsState.realTimeMetrics.userExperienceScore = AnalyticsState.stats.userExperienceScore
    
    -- Process trend analysis
    if ANALYTICS_CONFIG.processing.enableTrendAnalysis then
        PerformanceAnalyticsSystem.updateTrendAnalysis()
    end
end

function PerformanceAnalyticsSystem.calculatePerformanceScore()
    local fps = AnalyticsState.realTimeMetrics.currentFPS or 0
    local memory = AnalyticsState.realTimeMetrics.currentMemory or 0
    local latency = AnalyticsState.realTimeMetrics.currentLatency or 0
    
    -- Calculate score components (0-100 scale)
    local fpsScore = math.min(100, (fps / 60) * 100)
    local memoryScore = math.max(0, 100 - (memory / 10)) -- Penalize high memory usage
    local latencyScore = math.max(0, 100 - (latency / 5)) -- Penalize high latency
    
    -- Weighted average
    local performanceScore = (fpsScore * 0.5) + (memoryScore * 0.3) + (latencyScore * 0.2)
    
    return math.floor(performanceScore + 0.5)
end

function PerformanceAnalyticsSystem.calculateUserExperienceScore()
    -- Base score on performance and user interactions
    local performanceComponent = AnalyticsState.performanceScore * 0.6
    
    -- Interaction responsiveness component
    local interactionScore = PerformanceAnalyticsSystem.calculateInteractionScore() * 0.3
    
    -- Engagement component
    local engagementScore = PerformanceAnalyticsSystem.calculateEngagementScore() * 0.1
    
    local totalScore = performanceComponent + interactionScore + engagementScore
    
    return math.floor(totalScore + 0.5)
end

function PerformanceAnalyticsSystem.calculateInteractionScore()
    local interactions = AnalyticsState.userBehavior.interactions
    if #interactions == 0 then
        return 100 -- No interactions to measure
    end
    
    -- Calculate average interaction responsiveness
    local totalResponseTime = 0
    local recentInteractions = 0
    local cutoffTime = tick() - 60 -- Last minute
    
    for _, interaction in ipairs(interactions) do
        if interaction.timestamp >= cutoffTime then
            totalResponseTime = totalResponseTime + (interaction.responseTime or 16.67) -- Default to 60 FPS
            recentInteractions = recentInteractions + 1
        end
    end
    
    if recentInteractions == 0 then
        return 100
    end
    
    local averageResponseTime = totalResponseTime / recentInteractions
    return math.max(0, 100 - (averageResponseTime / 2)) -- Score based on response time
end

function PerformanceAnalyticsSystem.calculateEngagementScore()
    local sessionTime = tick() - AnalyticsState.startTime
    local interactionCount = #AnalyticsState.userBehavior.interactions
    
    -- Score based on interaction frequency
    local interactionRate = interactionCount / math.max(sessionTime / 60, 1) -- Interactions per minute
    
    return math.min(100, interactionRate * 10)
end

function PerformanceAnalyticsSystem.updateTrendAnalysis()
    local currentTime = tick()
    local trendWindow = 300 -- 5 minute window
    
    -- Collect recent performance data
    local recentPerformance = PerformanceAnalyticsSystem.getRecentPerformanceData(trendWindow)
    
    -- Calculate trends
    local trends = {
        fpsTrend = PerformanceAnalyticsSystem.calculateTrend(recentPerformance.fps),
        memoryTrend = PerformanceAnalyticsSystem.calculateTrend(recentPerformance.memory),
        latencyTrend = PerformanceAnalyticsSystem.calculateTrend(recentPerformance.latency),
        timestamp = currentTime
    }
    
    table.insert(AnalyticsState.trendData, trends)
    
    -- Limit trend data
    if #AnalyticsState.trendData > 100 then
        table.remove(AnalyticsState.trendData, 1)
    end
end

function PerformanceAnalyticsSystem.getRecentPerformanceData(timeWindow)
    local cutoffTime = tick() - timeWindow
    local recentData = {fps = {}, memory = {}, latency = {}}
    
    -- Collect FPS data
    if AnalyticsState.performanceData.frameRate then
        for _, data in ipairs(AnalyticsState.performanceData.frameRate) do
            if data.timestamp >= cutoffTime then
                table.insert(recentData.fps, data.fps)
            end
        end
    end
    
    -- Collect memory data
    if AnalyticsState.performanceData.memoryUsage then
        for _, data in ipairs(AnalyticsState.performanceData.memoryUsage) do
            if data.timestamp >= cutoffTime then
                table.insert(recentData.memory, data.memory)
            end
        end
    end
    
    -- Collect latency data
    if AnalyticsState.performanceData.networkLatency then
        for _, data in ipairs(AnalyticsState.performanceData.networkLatency) do
            if data.timestamp >= cutoffTime then
                table.insert(recentData.latency, data.latency)
            end
        end
    end
    
    return recentData
end

function PerformanceAnalyticsSystem.calculateTrend(dataPoints)
    if #dataPoints < 2 then
        return 0 -- No trend available
    end
    
    -- Simple linear regression to calculate trend
    local n = #dataPoints
    local sumX = 0
    local sumY = 0
    local sumXY = 0
    local sumXX = 0
    
    for i, value in ipairs(dataPoints) do
        sumX = sumX + i
        sumY = sumY + value
        sumXY = sumXY + (i * value)
        sumXX = sumXX + (i * i)
    end
    
    local slope = (n * sumXY - sumX * sumY) / (n * sumXX - sumX * sumX)
    return slope
end

-- ========================================
-- ANALYTICS PROCESSING
-- ========================================

function PerformanceAnalyticsSystem.startAnalyticsProcessing()
    -- Start event queue processor
    AnalyticsState.connections.eventProcessor = task.spawn(function()
        while AnalyticsState.isTracking do
            PerformanceAnalyticsSystem.processEventQueue()
            task.wait(1) -- Process every second
        end
    end)
    
    print("⚙️ Analytics processing started")
end

function PerformanceAnalyticsSystem.queueAnalyticsEvent(eventType, eventData)
    local event = {
        type = eventType,
        data = eventData,
        timestamp = tick(),
        sessionId = AnalyticsState.currentSession and AnalyticsState.currentSession.sessionId or nil,
        userId = AnalyticsState.userId
    }
    
    table.insert(AnalyticsState.eventQueue, event)
    
    -- Process immediately if queue is full
    if #AnalyticsState.eventQueue >= ANALYTICS_CONFIG.collection.batchSize then
        PerformanceAnalyticsSystem.processEventBatch()
    end
end

function PerformanceAnalyticsSystem.processEventQueue()
    if #AnalyticsState.eventQueue == 0 then
        return
    end
    
    -- Check if batch timeout has been reached
    local oldestEvent = AnalyticsState.eventQueue[1]
    local timeSinceOldest = (tick() - oldestEvent.timestamp) * 1000
    
    if timeSinceOldest >= ANALYTICS_CONFIG.collection.batchTimeout or
       #AnalyticsState.eventQueue >= ANALYTICS_CONFIG.collection.batchSize then
        PerformanceAnalyticsSystem.processEventBatch()
    end
end

function PerformanceAnalyticsSystem.processEventBatch()
    local batch = {}
    local batchSize = math.min(#AnalyticsState.eventQueue, ANALYTICS_CONFIG.collection.batchSize)
    
    -- Extract events for batch
    for i = 1, batchSize do
        table.insert(batch, table.remove(AnalyticsState.eventQueue, 1))
    end
    
    -- Process the batch
    PerformanceAnalyticsSystem.processBatch(batch)
end

function PerformanceAnalyticsSystem.processBatch(batch)
    -- Simulate batch processing
    for _, event in ipairs(batch) do
        PerformanceAnalyticsSystem.processAnalyticsEvent(event)
    end
    
    print(string.format("📊 Processed analytics batch: %d events", #batch))
end

function PerformanceAnalyticsSystem.processAnalyticsEvent(event)
    -- Store processed event
    if not AnalyticsState.processedAnalytics[event.type] then
        AnalyticsState.processedAnalytics[event.type] = {}
    end
    
    table.insert(AnalyticsState.processedAnalytics[event.type], event)
    
    -- Update statistics
    AnalyticsState.stats.eventsCollected = AnalyticsState.stats.eventsCollected + 1
    
    -- Calculate running averages
    PerformanceAnalyticsSystem.updateRunningAverages(event)
end

function PerformanceAnalyticsSystem.updateRunningAverages(event)
    if event.type == "performance" and event.data.type == "frameRate" then
        local fps = event.data.data.fps
        AnalyticsState.stats.averagePerformance = 
            (AnalyticsState.stats.averagePerformance + fps) / 2
    end
end

-- ========================================
-- REPORTING SYSTEM
-- ========================================

function PerformanceAnalyticsSystem.setupReportingSystem()
    if not ANALYTICS_CONFIG.reporting.enableAutomaticReports then
        return
    end
    
    -- Start automatic reporting
    AnalyticsState.connections.reportingSystem = task.spawn(function()
        while AnalyticsState.isTracking do
            task.wait(ANALYTICS_CONFIG.reporting.reportInterval)
            PerformanceAnalyticsSystem.generatePerformanceReport()
        end
    end)
    
    print("📄 Automatic reporting system started")
end

function PerformanceAnalyticsSystem.generatePerformanceReport()
    local report = {
        timestamp = tick(),
        reportId = HttpService:GenerateGUID(false),
        timeRange = ANALYTICS_CONFIG.reporting.reportInterval,
        
        -- Performance summary
        performance = {
            averageFPS = AnalyticsState.stats.averagePerformance,
            performanceScore = AnalyticsState.performanceScore,
            alertCount = #AnalyticsState.alertHistory
        },
        
        -- User experience summary
        userExperience = {
            score = AnalyticsState.stats.userExperienceScore,
            sessionCount = AnalyticsState.stats.sessionCount,
            totalPlayTime = AnalyticsState.stats.totalPlayTime,
            interactionCount = #AnalyticsState.userBehavior.interactions
        },
        
        -- System information
        system = {
            platform = AnalyticsState.currentSession and AnalyticsState.currentSession.deviceInfo.platform or "Unknown",
            performanceTier = AnalyticsState.currentSession and AnalyticsState.currentSession.deviceInfo.performanceTier or "Unknown"
        },
        
        -- Trends
        trends = AnalyticsState.trendData,
        
        -- Events processed
        eventsProcessed = AnalyticsState.stats.eventsCollected
    }
    
    -- Store report
    PerformanceAnalyticsSystem.storeReport(report)
    
    print(string.format("📄 Performance report generated: Score %.0f/100", report.performance.performanceScore))
    
    return report
end

function PerformanceAnalyticsSystem.storeReport(report)
    if not AnalyticsState.resultDatabase.reports then
        AnalyticsState.resultDatabase.reports = {}
    end
    
    table.insert(AnalyticsState.resultDatabase.reports, report)
    
    -- Limit stored reports
    if #AnalyticsState.resultDatabase.reports > 100 then
        table.remove(AnalyticsState.resultDatabase.reports, 1)
    end
end

-- ========================================
-- PUBLIC API
-- ========================================

function PerformanceAnalyticsSystem.getPerformanceScore()
    return AnalyticsState.performanceScore
end

function PerformanceAnalyticsSystem.getUserExperienceScore()
    return AnalyticsState.stats.userExperienceScore
end

function PerformanceAnalyticsSystem.getRealTimeMetrics()
    return AnalyticsState.realTimeMetrics
end

function PerformanceAnalyticsSystem.getAnalyticsStats()
    return AnalyticsState.stats
end

function PerformanceAnalyticsSystem.getCurrentSession()
    return AnalyticsState.currentSession
end

function PerformanceAnalyticsSystem.getPerformanceData()
    return AnalyticsState.performanceData
end

function PerformanceAnalyticsSystem.getUserExperienceData()
    return AnalyticsState.userExperienceData
end

function PerformanceAnalyticsSystem.getTrendData()
    return AnalyticsState.trendData
end

function PerformanceAnalyticsSystem.getAlertHistory()
    return AnalyticsState.alertHistory
end

function PerformanceAnalyticsSystem.getReports()
    return AnalyticsState.resultDatabase.reports or {}
end

function PerformanceAnalyticsSystem.exportAnalyticsData()
    return {
        performance = AnalyticsState.performanceData,
        userExperience = AnalyticsState.userExperienceData,
        sessions = AnalyticsState.sessionData,
        processed = AnalyticsState.processedAnalytics,
        trends = AnalyticsState.trendData,
        alerts = AnalyticsState.alertHistory,
        stats = AnalyticsState.stats
    }
end

function PerformanceAnalyticsSystem.trackCustomEvent(eventName, eventData)
    PerformanceAnalyticsSystem.queueAnalyticsEvent("custom", {
        name = eventName,
        data = eventData
    })
end

function PerformanceAnalyticsSystem.enableTracking(enabled)
    AnalyticsState.isTracking = enabled
    
    if enabled then
        PerformanceAnalyticsSystem.startSessionTracking()
    else
        PerformanceAnalyticsSystem.endSession()
    end
    
    print(string.format("📊 Analytics tracking %s", enabled and "enabled" or "disabled"))
end

function PerformanceAnalyticsSystem.clearAnalyticsData()
    AnalyticsState.performanceData = {}
    AnalyticsState.userExperienceData = {}
    AnalyticsState.processedAnalytics = {}
    AnalyticsState.eventQueue = {}
    AnalyticsState.trendData = {}
    AnalyticsState.alertHistory = {}
    
    print("🧹 Analytics data cleared")
end

function PerformanceAnalyticsSystem.shutdown()
    AnalyticsState.isTracking = false
    
    -- End current session
    if AnalyticsState.currentSession then
        PerformanceAnalyticsSystem.endSession()
    end
    
    -- Cancel all connections
    for _, connection in pairs(AnalyticsState.connections) do
        if typeof(connection) == "thread" then
            task.cancel(connection)
        elseif typeof(connection) == "RBXScriptConnection" then
            connection:Disconnect()
        end
    end
    
    -- Process any remaining events
    if #AnalyticsState.eventQueue > 0 then
        PerformanceAnalyticsSystem.processEventBatch()
    end
    
    print("📊 PerformanceAnalyticsSystem shutdown")
end

-- Initialize the performance analytics system
PerformanceAnalyticsSystem.initialize()

print("📊 PerformanceAnalyticsSystem loaded with comprehensive analytics capabilities")

return PerformanceAnalyticsSystem
