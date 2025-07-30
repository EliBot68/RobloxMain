-- BusinessMetricsTracker.luau
-- Business metrics tracking system for retention, monetization, and engagement
-- Provides comprehensive KPI monitoring and business intelligence capabilities

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local MarketplaceService = game:GetService("MarketplaceService")

local SafeRequire = require(ReplicatedStorage.Shared.utils.SafeRequire)

local BusinessMetricsTracker = {}

-- ========================================
-- METRICS CONFIGURATION
-- ========================================

local METRICS_CONFIG = {
    -- Retention metrics
    retention = {
        trackingPeriods = {1, 3, 7, 14, 30, 60, 90}, -- Days
        cohortSize = 100,                             -- Minimum cohort size
        enableCohortAnalysis = true,
        enableRetentionFunnels = true,
        segmentBy = {"acquisition_channel", "device_type", "geography"}
    },
    
    -- Monetization metrics
    monetization = {
        currencies = {"Robux", "Premium"},
        revenueCategories = {
            "gamepass", "developer_product", "premium", "advertising"
        },
        ltv_periods = {30, 90, 180, 365}, -- Days for LTV calculation
        enableRevenueAttribution = true,
        enablePurchaseFunnels = true,
        conversionWindows = {1, 3, 7, 14, 30} -- Days
    },
    
    -- Engagement metrics
    engagement = {
        sessionMetrics = {
            "session_duration", "actions_per_session", "feature_usage",
            "social_interactions", "content_consumption"
        },
        engagementLevels = {
            casual = {sessions_per_week = 2, avg_session_duration = 300},
            regular = {sessions_per_week = 5, avg_session_duration = 900},
            hardcore = {sessions_per_week = 10, avg_session_duration = 1800}
        },
        enableEngagementScoring = true,
        enableBehavioralSegmentation = true
    },
    
    -- Business KPIs
    kpis = {
        dau = {name = "Daily Active Users", aggregation = "count"},
        mau = {name = "Monthly Active Users", aggregation = "count"},
        wau = {name = "Weekly Active Users", aggregation = "count"},
        arpdau = {name = "Average Revenue Per DAU", aggregation = "average"},
        arppu = {name = "Average Revenue Per Paying User", aggregation = "average"},
        ltv = {name = "Lifetime Value", aggregation = "average"},
        cac = {name = "Customer Acquisition Cost", aggregation = "average"},
        roas = {name = "Return on Ad Spend", aggregation = "ratio"}
    },
    
    -- Data collection
    collection = {
        realTimeTracking = true,
        batchProcessing = true,
        batchSize = 1000,
        batchFrequency = 300,           -- 5 minutes
        dataRetention = 365 * 86400,   -- 1 year
        enableDataExport = true
    }
}

-- ========================================
-- METRICS STATE
-- ========================================

local MetricsState = {
    -- User tracking
    userSessions = {},
    userMetrics = {},
    userCohorts = {},
    
    -- Revenue tracking
    revenueEvents = {},
    purchaseHistory = {},
    monetizationFunnels = {},
    
    -- Engagement tracking
    engagementEvents = {},
    featureUsage = {},
    behaviorSegments = {},
    
    -- Aggregated metrics
    dailyMetrics = {},
    weeklyMetrics = {},
    monthlyMetrics = {},
    
    -- Business KPIs
    kpiValues = {},
    kpiTrends = {},
    
    -- Real-time counters
    realtimeCounters = {
        activeUsers = 0,
        revenue = 0,
        sessions = 0,
        purchases = 0
    },
    
    -- Statistics
    stats = {
        totalUsers = 0,
        totalRevenue = 0,
        totalSessions = 0,
        averageSessionDuration = 0,
        retentionRate = 0,
        conversionRate = 0,
        lifetimeValue = 0
    }
}

function BusinessMetricsTracker.initialize()
    print("📊 Initializing BusinessMetricsTracker...")
    
    -- Set up retention tracking
    BusinessMetricsTracker.setupRetentionTracking()
    
    -- Initialize monetization tracking
    BusinessMetricsTracker.initializeMonetizationTracking()
    
    -- Set up engagement tracking
    BusinessMetricsTracker.setupEngagementTracking()
    
    -- Initialize KPI monitoring
    BusinessMetricsTracker.initializeKPIMonitoring()
    
    -- Start metrics collection
    BusinessMetricsTracker.startMetricsCollection()
    
    print("📊 BusinessMetricsTracker initialized successfully")
end

-- ========================================
-- RETENTION TRACKING
-- ========================================

function BusinessMetricsTracker.setupRetentionTracking()
    MetricsState.retentionTracker = {
        cohortManager = BusinessMetricsTracker.createCohortManager(),
        retentionCalculator = BusinessMetricsTracker.createRetentionCalculator(),
        funnelAnalyzer = BusinessMetricsTracker.createFunnelAnalyzer()
    }
    
    print("🔄 Retention tracking system initialized")
end

function BusinessMetricsTracker.createCohortManager()
    return {
        name = "cohort_manager",
        
        createCohort = function(self, date, acquisitionChannel)
            return BusinessMetricsTracker.createUserCohort(date, acquisitionChannel)
        end,
        
        addUserToCohort = function(self, userId, cohortId)
            BusinessMetricsTracker.addUserToCohort(userId, cohortId)
        end
    }
end

function BusinessMetricsTracker.createRetentionCalculator()
    return {
        name = "retention_calculator",
        
        calculate = function(self, cohortId, period)
            return BusinessMetricsTracker.calculateRetentionRate(cohortId, period)
        end
    }
end

function BusinessMetricsTracker.createFunnelAnalyzer()
    return {
        name = "funnel_analyzer",
        
        analyze = function(self, funnelSteps)
            return BusinessMetricsTracker.analyzeFunnel(funnelSteps)
        end
    }
end

function BusinessMetricsTracker.trackUserRegistration(userId, acquisitionData)
    local registrationEvent = {
        userId = userId,
        timestamp = tick(),
        acquisitionChannel = acquisitionData.channel or "direct",
        deviceType = acquisitionData.deviceType or "unknown",
        geography = acquisitionData.geography or "unknown",
        campaignId = acquisitionData.campaignId,
        referrer = acquisitionData.referrer
    }
    
    -- Create or find cohort for this day and channel
    local cohortDate = BusinessMetricsTracker.getDayFromTimestamp(registrationEvent.timestamp)
    local cohortId = BusinessMetricsTracker.getCohortId(cohortDate, registrationEvent.acquisitionChannel)
    
    if not MetricsState.userCohorts[cohortId] then
        MetricsState.retentionTracker.cohortManager:createCohort(cohortDate, registrationEvent.acquisitionChannel)
    end
    
    -- Add user to cohort
    MetricsState.retentionTracker.cohortManager:addUserToCohort(userId, cohortId)
    
    -- Initialize user metrics
    MetricsState.userMetrics[userId] = {
        registrationDate = registrationEvent.timestamp,
        acquisitionChannel = registrationEvent.acquisitionChannel,
        deviceType = registrationEvent.deviceType,
        geography = registrationEvent.geography,
        cohortId = cohortId,
        sessionCount = 0,
        totalPlaytime = 0,
        lastSeen = registrationEvent.timestamp,
        isActive = true,
        lifetimeRevenue = 0,
        purchaseCount = 0
    }
    
    -- Update statistics
    MetricsState.stats.totalUsers = MetricsState.stats.totalUsers + 1
    
    print(string.format("👤 User %d registered and added to cohort %s", userId, cohortId))
    
    return registrationEvent
end

function BusinessMetricsTracker.trackUserSession(userId, sessionData)
    local session = {
        id = HttpService:GenerateGUID(false),
        userId = userId,
        startTime = sessionData.startTime or tick(),
        endTime = sessionData.endTime,
        duration = sessionData.duration,
        actions = sessionData.actions or {},
        features = sessionData.features or {},
        deviceType = sessionData.deviceType,
        location = sessionData.location
    }
    
    -- Store session
    if not MetricsState.userSessions[userId] then
        MetricsState.userSessions[userId] = {}
    end
    
    table.insert(MetricsState.userSessions[userId], session)
    
    -- Update user metrics
    local userMetrics = MetricsState.userMetrics[userId]
    if userMetrics then
        userMetrics.sessionCount = userMetrics.sessionCount + 1
        userMetrics.totalPlaytime = userMetrics.totalPlaytime + (session.duration or 0)
        userMetrics.lastSeen = session.startTime
        
        -- Update retention tracking
        BusinessMetricsTracker.updateRetentionTracking(userId, session.startTime)
    end
    
    -- Update real-time counters
    MetricsState.realtimeCounters.sessions = MetricsState.realtimeCounters.sessions + 1
    MetricsState.realtimeCounters.activeUsers = BusinessMetricsTracker.countActiveUsers()
    
    -- Update statistics
    MetricsState.stats.totalSessions = MetricsState.stats.totalSessions + 1
    BusinessMetricsTracker.updateAverageSessionDuration()
    
    return session
end

function BusinessMetricsTracker.createUserCohort(date, acquisitionChannel)
    local cohortId = BusinessMetricsTracker.getCohortId(date, acquisitionChannel)
    
    local cohort = {
        id = cohortId,
        date = date,
        acquisitionChannel = acquisitionChannel,
        users = {},
        size = 0,
        retentionRates = {},
        createdAt = tick()
    }
    
    MetricsState.userCohorts[cohortId] = cohort
    
    print(string.format("📊 Created user cohort: %s", cohortId))
    
    return cohort
end

function BusinessMetricsTracker.addUserToCohort(userId, cohortId)
    local cohort = MetricsState.userCohorts[cohortId]
    if not cohort then return false end
    
    table.insert(cohort.users, userId)
    cohort.size = cohort.size + 1
    
    return true
end

function BusinessMetricsTracker.calculateRetentionRate(cohortId, daysPeriod)
    local cohort = MetricsState.userCohorts[cohortId]
    if not cohort then return 0 end
    
    local cohortDate = cohort.date
    local targetDate = cohortDate + (daysPeriod * 86400)
    local retainedUsers = 0
    
    -- Count users who were active on the target date
    for _, userId in ipairs(cohort.users) do
        if BusinessMetricsTracker.wasUserActiveOnDate(userId, targetDate) then
            retainedUsers = retainedUsers + 1
        end
    end
    
    local retentionRate = cohort.size > 0 and (retainedUsers / cohort.size) or 0
    
    -- Store retention rate
    cohort.retentionRates[daysPeriod] = {
        rate = retentionRate,
        retainedUsers = retainedUsers,
        calculatedAt = tick()
    }
    
    return retentionRate
end

-- ========================================
-- MONETIZATION TRACKING
-- ========================================

function BusinessMetricsTracker.initializeMonetizationTracking()
    MetricsState.monetizationTracker = {
        revenueProcessor = BusinessMetricsTracker.createRevenueProcessor(),
        ltvCalculator = BusinessMetricsTracker.createLTVCalculator(),
        conversionTracker = BusinessMetricsTracker.createConversionTracker()
    }
    
    print("💰 Monetization tracking system initialized")
end

function BusinessMetricsTracker.createRevenueProcessor()
    return {
        name = "revenue_processor",
        
        process = function(self, revenueEvent)
            return BusinessMetricsTracker.processRevenueEvent(revenueEvent)
        end
    }
end

function BusinessMetricsTracker.createLTVCalculator()
    return {
        name = "ltv_calculator",
        
        calculate = function(self, userId, period)
            return BusinessMetricsTracker.calculateUserLTV(userId, period)
        end
    }
end

function BusinessMetricsTracker.createConversionTracker()
    return {
        name = "conversion_tracker",
        
        track = function(self, userId, conversionEvent)
            BusinessMetricsTracker.trackConversion(userId, conversionEvent)
        end
    }
end

function BusinessMetricsTracker.trackPurchase(userId, purchaseData)
    local purchase = {
        id = HttpService:GenerateGUID(false),
        userId = userId,
        timestamp = tick(),
        productId = purchaseData.productId,
        productType = purchaseData.productType, -- gamepass, developer_product, etc.
        price = purchaseData.price,
        currency = purchaseData.currency or "Robux",
        category = purchaseData.category,
        paymentMethod = purchaseData.paymentMethod,
        transactionId = purchaseData.transactionId
    }
    
    -- Store purchase
    if not MetricsState.purchaseHistory[userId] then
        MetricsState.purchaseHistory[userId] = {}
    end
    
    table.insert(MetricsState.purchaseHistory[userId], purchase)
    
    -- Process revenue event
    local revenueEvent = {
        type = "purchase",
        userId = userId,
        amount = purchase.price,
        currency = purchase.currency,
        category = purchase.category,
        timestamp = purchase.timestamp
    }
    
    MetricsState.monetizationTracker.revenueProcessor:process(revenueEvent)
    
    -- Update user metrics
    local userMetrics = MetricsState.userMetrics[userId]
    if userMetrics then
        userMetrics.lifetimeRevenue = userMetrics.lifetimeRevenue + purchase.price
        userMetrics.purchaseCount = userMetrics.purchaseCount + 1
    end
    
    -- Track conversion
    MetricsState.monetizationTracker.conversionTracker:track(userId, {
        type = "purchase",
        productId = purchase.productId,
        amount = purchase.price
    })
    
    -- Update real-time counters
    MetricsState.realtimeCounters.revenue = MetricsState.realtimeCounters.revenue + purchase.price
    MetricsState.realtimeCounters.purchases = MetricsState.realtimeCounters.purchases + 1
    
    -- Update statistics
    MetricsState.stats.totalRevenue = MetricsState.stats.totalRevenue + purchase.price
    BusinessMetricsTracker.updateConversionRate()
    
    print(string.format("💰 Purchase tracked: User %d bought %s for %d %s", 
        userId, purchase.productId, purchase.price, purchase.currency))
    
    return purchase
end

function BusinessMetricsTracker.processRevenueEvent(revenueEvent)
    -- Store revenue event
    table.insert(MetricsState.revenueEvents, revenueEvent)
    
    -- Update daily metrics
    local dateKey = BusinessMetricsTracker.getDayFromTimestamp(revenueEvent.timestamp)
    
    if not MetricsState.dailyMetrics[dateKey] then
        MetricsState.dailyMetrics[dateKey] = {
            revenue = 0,
            purchases = 0,
            activeUsers = 0,
            newUsers = 0
        }
    end
    
    MetricsState.dailyMetrics[dateKey].revenue = 
        MetricsState.dailyMetrics[dateKey].revenue + revenueEvent.amount
    MetricsState.dailyMetrics[dateKey].purchases = 
        MetricsState.dailyMetrics[dateKey].purchases + 1
    
    return true
end

function BusinessMetricsTracker.calculateUserLTV(userId, periodDays)
    local userMetrics = MetricsState.userMetrics[userId]
    if not userMetrics then return 0 end
    
    local registrationDate = userMetrics.registrationDate
    local periodEnd = registrationDate + (periodDays * 86400)
    local currentTime = tick()
    
    -- If period hasn't elapsed, calculate pro-rated LTV
    local actualPeriod = math.min(currentTime - registrationDate, periodEnd - registrationDate)
    
    if actualPeriod <= 0 then return 0 end
    
    -- Calculate revenue within period
    local periodRevenue = 0
    local purchases = MetricsState.purchaseHistory[userId] or {}
    
    for _, purchase in ipairs(purchases) do
        if purchase.timestamp >= registrationDate and purchase.timestamp <= periodEnd then
            periodRevenue = periodRevenue + purchase.price
        end
    end
    
    -- Calculate LTV (total revenue for completed period)
    local ltv = periodRevenue
    
    -- If period is incomplete, project LTV
    if currentTime < periodEnd then
        local completionRatio = actualPeriod / (periodDays * 86400)
        if completionRatio > 0 then
            ltv = periodRevenue / completionRatio
        end
    end
    
    return ltv
end

function BusinessMetricsTracker.trackConversion(userId, conversionEvent)
    local userMetrics = MetricsState.userMetrics[userId]
    if not userMetrics then return end
    
    local registrationDate = userMetrics.registrationDate
    local conversionTime = tick() - registrationDate
    
    -- Track conversion by time window
    for _, window in ipairs(METRICS_CONFIG.monetization.conversionWindows) do
        local windowSeconds = window * 86400
        
        if conversionTime <= windowSeconds then
            local windowKey = string.format("conversion_%dd", window)
            
            if not MetricsState.kpiValues[windowKey] then
                MetricsState.kpiValues[windowKey] = {
                    conversions = 0,
                    totalUsers = 0,
                    rate = 0
                }
            end
            
            MetricsState.kpiValues[windowKey].conversions = 
                MetricsState.kpiValues[windowKey].conversions + 1
        end
    end
end

-- ========================================
-- ENGAGEMENT TRACKING
-- ========================================

function BusinessMetricsTracker.setupEngagementTracking()
    MetricsState.engagementTracker = {
        scoreCalculator = BusinessMetricsTracker.createEngagementScoreCalculator(),
        segmentAnalyzer = BusinessMetricsTracker.createSegmentAnalyzer(),
        featureTracker = BusinessMetricsTracker.createFeatureTracker()
    }
    
    print("🎯 Engagement tracking system initialized")
end

function BusinessMetricsTracker.createEngagementScoreCalculator()
    return {
        name = "engagement_score_calculator",
        
        calculate = function(self, userId)
            return BusinessMetricsTracker.calculateEngagementScore(userId)
        end
    }
end

function BusinessMetricsTracker.createSegmentAnalyzer()
    return {
        name = "segment_analyzer",
        
        analyze = function(self, userId)
            return BusinessMetricsTracker.analyzeUserSegment(userId)
        end
    }
end

function BusinessMetricsTracker.createFeatureTracker()
    return {
        name = "feature_tracker",
        
        track = function(self, userId, feature, action)
            BusinessMetricsTracker.trackFeatureUsage(userId, feature, action)
        end
    }
end

function BusinessMetricsTracker.trackEngagementEvent(userId, eventData)
    local engagementEvent = {
        id = HttpService:GenerateGUID(false),
        userId = userId,
        timestamp = tick(),
        eventType = eventData.eventType,
        feature = eventData.feature,
        action = eventData.action,
        value = eventData.value,
        sessionId = eventData.sessionId,
        context = eventData.context or {}
    }
    
    -- Store engagement event
    if not MetricsState.engagementEvents[userId] then
        MetricsState.engagementEvents[userId] = {}
    end
    
    table.insert(MetricsState.engagementEvents[userId], engagementEvent)
    
    -- Track feature usage
    if engagementEvent.feature then
        MetricsState.engagementTracker.featureTracker:track(
            userId, engagementEvent.feature, engagementEvent.action
        )
    end
    
    -- Update engagement score
    local engagementScore = MetricsState.engagementTracker.scoreCalculator:calculate(userId)
    
    -- Update user segment
    local segment = MetricsState.engagementTracker.segmentAnalyzer:analyze(userId)
    
    return engagementEvent
end

function BusinessMetricsTracker.calculateEngagementScore(userId)
    local userMetrics = MetricsState.userMetrics[userId]
    if not userMetrics then return 0 end
    
    local currentTime = tick()
    local weekAgo = currentTime - (7 * 86400)
    
    -- Get recent sessions
    local recentSessions = BusinessMetricsTracker.getSessionsInPeriod(userId, weekAgo, currentTime)
    
    -- Calculate engagement factors
    local sessionFrequency = #recentSessions / 7 -- Sessions per day
    local avgSessionDuration = BusinessMetricsTracker.getAverageSessionDuration(recentSessions)
    local featureUsage = BusinessMetricsTracker.getFeatureUsageScore(userId, weekAgo)
    local socialInteractions = BusinessMetricsTracker.getSocialInteractionScore(userId, weekAgo)
    
    -- Calculate weighted engagement score (0-100)
    local engagementScore = math.min(100, (
        sessionFrequency * 20 +           -- 20 points max for session frequency
        (avgSessionDuration / 1800) * 30 + -- 30 points max for session duration (30 min baseline)
        featureUsage * 25 +               -- 25 points max for feature usage
        socialInteractions * 25           -- 25 points max for social interactions
    ))
    
    return engagementScore
end

function BusinessMetricsTracker.analyzeUserSegment(userId)
    local engagementScore = MetricsState.engagementTracker.scoreCalculator:calculate(userId)
    local userMetrics = MetricsState.userMetrics[userId]
    
    if not userMetrics then return "unknown" end
    
    local segment = "casual"
    
    -- Determine segment based on engagement patterns
    local currentTime = tick()
    local weekAgo = currentTime - (7 * 86400)
    local recentSessions = BusinessMetricsTracker.getSessionsInPeriod(userId, weekAgo, currentTime)
    
    local sessionsPerWeek = #recentSessions
    local avgSessionDuration = BusinessMetricsTracker.getAverageSessionDuration(recentSessions)
    
    -- Apply segment rules
    for segmentName, criteria in pairs(METRICS_CONFIG.engagement.engagementLevels) do
        if sessionsPerWeek >= criteria.sessions_per_week and 
           avgSessionDuration >= criteria.avg_session_duration then
            segment = segmentName
        end
    end
    
    -- Store segment
    MetricsState.behaviorSegments[userId] = {
        segment = segment,
        engagementScore = engagementScore,
        updatedAt = tick()
    }
    
    return segment
end

function BusinessMetricsTracker.trackFeatureUsage(userId, feature, action)
    local featureEvent = {
        userId = userId,
        feature = feature,
        action = action,
        timestamp = tick()
    }
    
    -- Store feature usage
    if not MetricsState.featureUsage[feature] then
        MetricsState.featureUsage[feature] = {}
    end
    
    if not MetricsState.featureUsage[feature][userId] then
        MetricsState.featureUsage[feature][userId] = {}
    end
    
    table.insert(MetricsState.featureUsage[feature][userId], featureEvent)
    
    return featureEvent
end

-- ========================================
-- KPI MONITORING
-- ========================================

function BusinessMetricsTracker.initializeKPIMonitoring()
    MetricsState.kpiMonitor = {
        calculator = BusinessMetricsTracker.createKPICalculator(),
        trendAnalyzer = BusinessMetricsTracker.createTrendAnalyzer(),
        alertSystem = BusinessMetricsTracker.createAlertSystem()
    }
    
    -- Initialize KPI values
    for kpiName in pairs(METRICS_CONFIG.kpis) do
        MetricsState.kpiValues[kpiName] = 0
        MetricsState.kpiTrends[kpiName] = {}
    end
    
    print("📈 KPI monitoring system initialized")
end

function BusinessMetricsTracker.createKPICalculator()
    return {
        name = "kpi_calculator",
        
        calculate = function(self, kpiName, period)
            return BusinessMetricsTracker.calculateKPI(kpiName, period)
        end
    }
end

function BusinessMetricsTracker.createTrendAnalyzer()
    return {
        name = "trend_analyzer",
        
        analyze = function(self, kpiName, period)
            return BusinessMetricsTracker.analyzeTrend(kpiName, period)
        end
    }
end

function BusinessMetricsTracker.createAlertSystem()
    return {
        name = "alert_system",
        
        check = function(self)
            BusinessMetricsTracker.checkKPIAlerts()
        end
    }
end

function BusinessMetricsTracker.calculateKPI(kpiName, period)
    period = period or "daily"
    local currentTime = tick()
    
    if kpiName == "dau" then
        return BusinessMetricsTracker.calculateDAU()
    elseif kpiName == "mau" then
        return BusinessMetricsTracker.calculateMAU()
    elseif kpiName == "wau" then
        return BusinessMetricsTracker.calculateWAU()
    elseif kpiName == "arpdau" then
        return BusinessMetricsTracker.calculateARPDAU()
    elseif kpiName == "arppu" then
        return BusinessMetricsTracker.calculateARPPU()
    elseif kpiName == "ltv" then
        return BusinessMetricsTracker.calculateAverageLTV(30) -- 30-day LTV
    elseif kpiName == "cac" then
        return BusinessMetricsTracker.calculateCAC()
    elseif kpiName == "roas" then
        return BusinessMetricsTracker.calculateROAS()
    end
    
    return 0
end

function BusinessMetricsTracker.calculateDAU()
    local currentTime = tick()
    local dayStart = currentTime - (currentTime % 86400)
    local dayEnd = dayStart + 86400
    
    local activeUsers = {}
    
    -- Count unique users who had sessions today
    for userId, sessions in pairs(MetricsState.userSessions) do
        for _, session in ipairs(sessions) do
            if session.startTime >= dayStart and session.startTime < dayEnd then
                activeUsers[userId] = true
                break
            end
        end
    end
    
    local dau = 0
    for _ in pairs(activeUsers) do
        dau = dau + 1
    end
    
    MetricsState.kpiValues.dau = dau
    return dau
end

function BusinessMetricsTracker.calculateMAU()
    local currentTime = tick()
    local monthStart = currentTime - (30 * 86400)
    
    local activeUsers = {}
    
    -- Count unique users who had sessions in the last 30 days
    for userId, sessions in pairs(MetricsState.userSessions) do
        for _, session in ipairs(sessions) do
            if session.startTime >= monthStart then
                activeUsers[userId] = true
                break
            end
        end
    end
    
    local mau = 0
    for _ in pairs(activeUsers) do
        mau = mau + 1
    end
    
    MetricsState.kpiValues.mau = mau
    return mau
end

function BusinessMetricsTracker.calculateWAU()
    local currentTime = tick()
    local weekStart = currentTime - (7 * 86400)
    
    local activeUsers = {}
    
    -- Count unique users who had sessions in the last 7 days
    for userId, sessions in pairs(MetricsState.userSessions) do
        for _, session in ipairs(sessions) do
            if session.startTime >= weekStart then
                activeUsers[userId] = true
                break
            end
        end
    end
    
    local wau = 0
    for _ in pairs(activeUsers) do
        wau = wau + 1
    end
    
    MetricsState.kpiValues.wau = wau
    return wau
end

function BusinessMetricsTracker.calculateARPDAU()
    local dau = BusinessMetricsTracker.calculateDAU()
    
    if dau == 0 then return 0 end
    
    -- Calculate daily revenue
    local currentTime = tick()
    local dayStart = currentTime - (currentTime % 86400)
    local dayEnd = dayStart + 86400
    
    local dailyRevenue = 0
    
    for _, revenueEvent in ipairs(MetricsState.revenueEvents) do
        if revenueEvent.timestamp >= dayStart and revenueEvent.timestamp < dayEnd then
            dailyRevenue = dailyRevenue + revenueEvent.amount
        end
    end
    
    local arpdau = dailyRevenue / dau
    MetricsState.kpiValues.arpdau = arpdau
    return arpdau
end

function BusinessMetricsTracker.calculateARPPU()
    -- Calculate for paying users only
    local currentTime = tick()
    local monthStart = currentTime - (30 * 86400)
    
    local payingUsers = {}
    local totalRevenue = 0
    
    for userId, purchases in pairs(MetricsState.purchaseHistory) do
        local userRevenue = 0
        
        for _, purchase in ipairs(purchases) do
            if purchase.timestamp >= monthStart then
                userRevenue = userRevenue + purchase.price
                totalRevenue = totalRevenue + purchase.price
            end
        end
        
        if userRevenue > 0 then
            payingUsers[userId] = userRevenue
        end
    end
    
    local payingUserCount = 0
    for _ in pairs(payingUsers) do
        payingUserCount = payingUserCount + 1
    end
    
    local arppu = payingUserCount > 0 and (totalRevenue / payingUserCount) or 0
    MetricsState.kpiValues.arppu = arppu
    return arppu
end

function BusinessMetricsTracker.calculateAverageLTV(periodDays)
    local totalLTV = 0
    local userCount = 0
    
    for userId in pairs(MetricsState.userMetrics) do
        local ltv = MetricsState.monetizationTracker.ltvCalculator:calculate(userId, periodDays)
        totalLTV = totalLTV + ltv
        userCount = userCount + 1
    end
    
    local avgLTV = userCount > 0 and (totalLTV / userCount) or 0
    MetricsState.kpiValues.ltv = avgLTV
    return avgLTV
end

function BusinessMetricsTracker.calculateCAC()
    -- Simplified CAC calculation (would need advertising spend data)
    local acquisitionCost = 5.0 -- Estimated $5 per user
    MetricsState.kpiValues.cac = acquisitionCost
    return acquisitionCost
end

function BusinessMetricsTracker.calculateROAS()
    -- Return on advertising spend (would need advertising spend data)
    local ltv = MetricsState.kpiValues.ltv or 0
    local cac = MetricsState.kpiValues.cac or 1
    
    local roas = cac > 0 and (ltv / cac) or 0
    MetricsState.kpiValues.roas = roas
    return roas
end

-- ========================================
-- METRICS COLLECTION
-- ========================================

function BusinessMetricsTracker.startMetricsCollection()
    spawn(function()
        while true do
            BusinessMetricsTracker.performMetricsCollection()
            task.wait(METRICS_CONFIG.collection.batchFrequency)
        end
    end)
    
    print("🔄 Metrics collection started")
end

function BusinessMetricsTracker.performMetricsCollection()
    -- Calculate all KPIs
    for kpiName in pairs(METRICS_CONFIG.kpis) do
        local kpiValue = MetricsState.kpiMonitor.calculator:calculate(kpiName)
        
        -- Store KPI trend
        table.insert(MetricsState.kpiTrends[kpiName], {
            value = kpiValue,
            timestamp = tick()
        })
        
        -- Keep trend data manageable
        if #MetricsState.kpiTrends[kpiName] > 100 then
            table.remove(MetricsState.kpiTrends[kpiName], 1)
        end
    end
    
    -- Update retention rates for cohorts
    BusinessMetricsTracker.updateCohortRetention()
    
    -- Check for alerts
    MetricsState.kpiMonitor.alertSystem:check()
    
    -- Update statistics
    BusinessMetricsTracker.updateBusinessStatistics()
end

function BusinessMetricsTracker.updateCohortRetention()
    for cohortId, cohort in pairs(MetricsState.userCohorts) do
        for _, period in ipairs(METRICS_CONFIG.retention.trackingPeriods) do
            local retentionRate = MetricsState.retentionTracker.retentionCalculator:calculate(cohortId, period)
        end
    end
end

-- ========================================
-- UTILITY FUNCTIONS
-- ========================================

function BusinessMetricsTracker.getDayFromTimestamp(timestamp)
    return math.floor(timestamp / 86400)
end

function BusinessMetricsTracker.getCohortId(date, acquisitionChannel)
    return string.format("cohort_%s_%s", date, acquisitionChannel)
end

function BusinessMetricsTracker.wasUserActiveOnDate(userId, targetDate)
    local sessions = MetricsState.userSessions[userId] or {}
    local dayStart = targetDate - (targetDate % 86400)
    local dayEnd = dayStart + 86400
    
    for _, session in ipairs(sessions) do
        if session.startTime >= dayStart and session.startTime < dayEnd then
            return true
        end
    end
    
    return false
end

function BusinessMetricsTracker.countActiveUsers()
    local currentTime = tick()
    local hourAgo = currentTime - 3600
    local activeUsers = {}
    
    for userId, sessions in pairs(MetricsState.userSessions) do
        for _, session in ipairs(sessions) do
            if session.startTime >= hourAgo then
                activeUsers[userId] = true
                break
            end
        end
    end
    
    local count = 0
    for _ in pairs(activeUsers) do
        count = count + 1
    end
    
    return count
end

function BusinessMetricsTracker.updateAverageSessionDuration()
    local totalDuration = 0
    local sessionCount = 0
    
    for _, sessions in pairs(MetricsState.userSessions) do
        for _, session in ipairs(sessions) do
            if session.duration then
                totalDuration = totalDuration + session.duration
                sessionCount = sessionCount + 1
            end
        end
    end
    
    MetricsState.stats.averageSessionDuration = 
        sessionCount > 0 and (totalDuration / sessionCount) or 0
end

function BusinessMetricsTracker.updateConversionRate()
    local totalUsers = MetricsState.stats.totalUsers
    local payingUsers = 0
    
    for _ in pairs(MetricsState.purchaseHistory) do
        payingUsers = payingUsers + 1
    end
    
    MetricsState.stats.conversionRate = 
        totalUsers > 0 and (payingUsers / totalUsers) or 0
end

function BusinessMetricsTracker.getSessionsInPeriod(userId, startTime, endTime)
    local sessions = MetricsState.userSessions[userId] or {}
    local periodSessions = {}
    
    for _, session in ipairs(sessions) do
        if session.startTime >= startTime and session.startTime <= endTime then
            table.insert(periodSessions, session)
        end
    end
    
    return periodSessions
end

function BusinessMetricsTracker.getAverageSessionDuration(sessions)
    if #sessions == 0 then return 0 end
    
    local totalDuration = 0
    local validSessions = 0
    
    for _, session in ipairs(sessions) do
        if session.duration then
            totalDuration = totalDuration + session.duration
            validSessions = validSessions + 1
        end
    end
    
    return validSessions > 0 and (totalDuration / validSessions) or 0
end

function BusinessMetricsTracker.getFeatureUsageScore(userId, sinceTime)
    local usageScore = 0
    
    for feature, users in pairs(MetricsState.featureUsage) do
        local userEvents = users[userId] or {}
        
        for _, event in ipairs(userEvents) do
            if event.timestamp >= sinceTime then
                usageScore = usageScore + 1
            end
        end
    end
    
    return math.min(usageScore / 10, 1) -- Normalize to 0-1
end

function BusinessMetricsTracker.getSocialInteractionScore(userId, sinceTime)
    local interactions = 0
    local events = MetricsState.engagementEvents[userId] or {}
    
    for _, event in ipairs(events) do
        if event.timestamp >= sinceTime and 
           (event.eventType == "social" or event.feature == "chat" or event.feature == "friend") then
            interactions = interactions + 1
        end
    end
    
    return math.min(interactions / 20, 1) -- Normalize to 0-1
end

function BusinessMetricsTracker.checkKPIAlerts()
    -- Check for significant changes in KPIs
    for kpiName, trends in pairs(MetricsState.kpiTrends) do
        if #trends >= 2 then
            local current = trends[#trends].value
            local previous = trends[#trends - 1].value
            
            if previous > 0 then
                local changePercent = ((current - previous) / previous) * 100
                
                if math.abs(changePercent) > 20 then -- 20% change threshold
                    print(string.format("🚨 KPI Alert: %s changed by %.1f%% (%s → %s)", 
                        kpiName, changePercent, previous, current))
                end
            end
        end
    end
end

function BusinessMetricsTracker.updateBusinessStatistics()
    -- Update retention rate
    local totalRetention = 0
    local cohortCount = 0
    
    for _, cohort in pairs(MetricsState.userCohorts) do
        local retention7d = cohort.retentionRates[7]
        if retention7d then
            totalRetention = totalRetention + retention7d.rate
            cohortCount = cohortCount + 1
        end
    end
    
    MetricsState.stats.retentionRate = 
        cohortCount > 0 and (totalRetention / cohortCount) or 0
    
    -- Update lifetime value
    MetricsState.stats.lifetimeValue = MetricsState.kpiValues.ltv or 0
end

-- ========================================
-- PUBLIC API
-- ========================================

function BusinessMetricsTracker.runMetricsDemo()
    print("📊 Running business metrics tracking demonstration...")
    
    -- Simulate user registrations and activity
    print("  👥 Simulating user activity...")
    
    for userId = 1001, 1050 do
        -- Register user
        local acquisitionData = {
            channel = math.random() > 0.5 and "organic" or "paid",
            deviceType = math.random() > 0.3 and "mobile" or "desktop",
            geography = "US"
        }
        
        BusinessMetricsTracker.trackUserRegistration(userId, acquisitionData)
        
        -- Simulate sessions
        local sessionCount = math.random(1, 5)
        for i = 1, sessionCount do
            local sessionData = {
                startTime = tick() - math.random(0, 7 * 86400), -- Last 7 days
                duration = math.random(300, 3600), -- 5 minutes to 1 hour
                actions = math.random(10, 100),
                deviceType = acquisitionData.deviceType
            }
            
            BusinessMetricsTracker.trackUserSession(userId, sessionData)
        end
        
        -- Simulate purchases (30% conversion rate)
        if math.random() < 0.3 then
            local purchaseData = {
                productId = "premium_currency",
                productType = "developer_product",
                price = math.random(5, 50),
                currency = "Robux",
                category = "currency"
            }
            
            BusinessMetricsTracker.trackPurchase(userId, purchaseData)
        end
        
        -- Simulate engagement events
        for j = 1, math.random(5, 20) do
            local eventData = {
                eventType = "feature_usage",
                feature = {"inventory", "shop", "leaderboard", "social"}[math.random(1, 4)],
                action = "click"
            }
            
            BusinessMetricsTracker.trackEngagementEvent(userId, eventData)
        end
    end
    
    -- Wait for metrics processing
    task.wait(1)
    
    -- Calculate and display KPIs
    print("  📈 Calculating business KPIs...")
    
    local kpis = {}
    for kpiName in pairs(METRICS_CONFIG.kpis) do
        kpis[kpiName] = MetricsState.kpiMonitor.calculator:calculate(kpiName)
    end
    
    print("  📊 Business Metrics Results:")
    print(string.format("    DAU (Daily Active Users): %d", kpis.dau))
    print(string.format("    WAU (Weekly Active Users): %d", kpis.wau))
    print(string.format("    MAU (Monthly Active Users): %d", kpis.mau))
    print(string.format("    ARPDAU: $%.2f", kpis.arpdau))
    print(string.format("    ARPPU: $%.2f", kpis.arppu))
    print(string.format("    LTV (30-day): $%.2f", kpis.ltv))
    print(string.format("    CAC: $%.2f", kpis.cac))
    print(string.format("    ROAS: %.2fx", kpis.roas))
    
    -- Show retention analysis
    print("  🔄 Retention Analysis:")
    for cohortId, cohort in pairs(MetricsState.userCohorts) do
        print(string.format("    Cohort %s: %d users", cohortId, cohort.size))
        
        for period, retentionData in pairs(cohort.retentionRates) do
            print(string.format("      Day %d retention: %.1f%% (%d/%d users)", 
                period, retentionData.rate * 100, retentionData.retainedUsers, cohort.size))
        end
    end
    
    -- Show engagement segments
    print("  🎯 Engagement Segments:")
    local segments = {casual = 0, regular = 0, hardcore = 0}
    
    for userId, segmentData in pairs(MetricsState.behaviorSegments) do
        segments[segmentData.segment] = (segments[segmentData.segment] or 0) + 1
    end
    
    for segment, count in pairs(segments) do
        print(string.format("    %s: %d users", segment, count))
    end
    
    -- Show real-time metrics
    print("  ⚡ Real-time Metrics:")
    print(string.format("    Active users: %d", MetricsState.realtimeCounters.activeUsers))
    print(string.format("    Total sessions: %d", MetricsState.realtimeCounters.sessions))
    print(string.format("    Total revenue: $%.2f", MetricsState.realtimeCounters.revenue))
    print(string.format("    Total purchases: %d", MetricsState.realtimeCounters.purchases))
    
    -- Show overall statistics
    local stats = BusinessMetricsTracker.getBusinessStats()
    print("  📊 Overall Statistics:")
    print(string.format("    Total users: %d", stats.totalUsers))
    print(string.format("    Total revenue: $%.2f", stats.totalRevenue))
    print(string.format("    Total sessions: %d", stats.totalSessions))
    print(string.format("    Avg session duration: %.1f minutes", stats.averageSessionDuration / 60))
    print(string.format("    Conversion rate: %.1f%%", stats.conversionRate * 100))
    print(string.format("    Retention rate (7-day): %.1f%%", stats.retentionRate * 100))
    
    print("📊 Business metrics tracking demonstration completed")
end

function BusinessMetricsTracker.getBusinessStats()
    return MetricsState.stats
end

function BusinessMetricsTracker.getKPIValues()
    return MetricsState.kpiValues
end

function BusinessMetricsTracker.getKPITrends(kpiName)
    return MetricsState.kpiTrends[kpiName] or {}
end

function BusinessMetricsTracker.getUserMetrics(userId)
    return MetricsState.userMetrics[userId]
end

function BusinessMetricsTracker.getCohortData(cohortId)
    return MetricsState.userCohorts[cohortId]
end

function BusinessMetricsTracker.getEngagementSegments()
    return MetricsState.behaviorSegments
end

-- Export API
BusinessMetricsTracker.trackUserRegistration = BusinessMetricsTracker.trackUserRegistration
BusinessMetricsTracker.trackUserSession = BusinessMetricsTracker.trackUserSession
BusinessMetricsTracker.trackPurchase = BusinessMetricsTracker.trackPurchase
BusinessMetricsTracker.trackEngagementEvent = BusinessMetricsTracker.trackEngagementEvent
BusinessMetricsTracker.calculateKPI = BusinessMetricsTracker.calculateKPI

-- Initialize the business metrics tracker
BusinessMetricsTracker.initialize()

print("📊 BusinessMetricsTracker loaded with comprehensive business intelligence capabilities")

return BusinessMetricsTracker
