-- MonetizationAnalytics.luau
-- Advanced monetization analytics and revenue optimization
-- Provides comprehensive tracking, analysis, and optimization tools

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local SafeRequire = require(ReplicatedStorage.Shared.utils.SafeRequire)

local MonetizationAnalytics = {}

-- ========================================
-- ANALYTICS CONFIGURATION
-- ========================================

local ANALYTICS_CONFIG = {
    -- Tracking settings
    tracking = {
        enableRevenueTracking = true,
        enableConversionTracking = true,
        enableRetentionTracking = true,
        enableCohortAnalysis = true,
        enableFunnelAnalysis = true,
        enableLTVCalculation = true,
        realTimeAnalytics = true,
        dataRetentionDays = 365
    },
    
    -- KPI thresholds
    kpiThresholds = {
        conversionRate = {
            excellent = 0.15,  -- 15%+
            good = 0.08,       -- 8-15%
            average = 0.03,    -- 3-8%
            poor = 0.01        -- 1-3%
        },
        
        arpu = {
            excellent = 50,    -- $50+
            good = 20,         -- $20-50
            average = 5,       -- $5-20
            poor = 1           -- $1-5
        },
        
        retention = {
            day1 = 0.4,        -- 40% day 1
            day7 = 0.2,        -- 20% day 7
            day30 = 0.1        -- 10% day 30
        },
        
        ltv = {
            excellent = 100,   -- $100+
            good = 50,         -- $50-100
            average = 20,      -- $20-50
            poor = 5           -- $5-20
        }
    },
    
    -- Optimization settings
    optimization = {
        enableABTesting = true,
        enableDynamicPricing = true,
        enablePersonalization = true,
        enablePredictiveAnalytics = true,
        optimizationCycles = 7,        -- Weekly optimization
        minDataSampleSize = 100,
        confidenceLevel = 0.95
    },
    
    -- Segmentation rules
    segmentation = {
        spendingTiers = {
            whale = 1000,      -- $1000+
            dolphin = 100,     -- $100-999
            minnow = 10,       -- $10-99
            free = 0           -- $0-9
        },
        
        engagementTiers = {
            high = 0.8,        -- 80%+ engagement
            medium = 0.5,      -- 50-80%
            low = 0.2          -- 20-50%
        },
        
        lifecycleStages = {
            new = 1,           -- 0-1 days
            growing = 7,       -- 1-7 days
            mature = 30,       -- 7-30 days
            veteran = 90       -- 30+ days
        }
    }
}

-- ========================================
-- ANALYTICS STATE
-- ========================================

local AnalyticsState = {
    -- Revenue analytics
    revenueData = {},
    conversionData = {},
    cohortData = {},
    
    -- Player analytics
    playerMetrics = {},
    segmentData = {},
    behaviorPatterns = {},
    
    -- Funnel analytics
    conversionFunnels = {},
    dropoffAnalysis = {},
    
    -- Optimization data
    abTestResults = {},
    pricingExperiments = {},
    personalizationResults = {},
    
    -- Performance tracking
    kpiMetrics = {},
    trends = {},
    forecasts = {},
    
    -- Real-time data
    realTimeMetrics = {},
    liveEvents = {},
    
    -- Historical data
    dailyMetrics = {},
    weeklyMetrics = {},
    monthlyMetrics = {},
    
    -- Statistics
    stats = {
        totalRevenue = 0,
        totalConversions = 0,
        averageARPU = 0,
        averageLTV = 0,
        overallConversionRate = 0,
        retentionRate7Day = 0,
        retentionRate30Day = 0,
        optimizationImpact = 0
    }
}

function MonetizationAnalytics.initialize()
    print("📊 Initializing MonetizationAnalytics...")
    
    -- Set up analytics engine
    MonetizationAnalytics.setupAnalyticsEngine()
    
    -- Initialize KPI tracking
    MonetizationAnalytics.initializeKPITracking()
    
    -- Set up optimization engine
    MonetizationAnalytics.setupOptimizationEngine()
    
    -- Initialize real-time monitoring
    MonetizationAnalytics.initializeRealTimeMonitoring()
    
    -- Start analytics collection
    MonetizationAnalytics.startAnalyticsCollection()
    
    print("📊 MonetizationAnalytics initialized successfully")
end

-- ========================================
-- ANALYTICS ENGINE
-- ========================================

function MonetizationAnalytics.setupAnalyticsEngine()
    AnalyticsState.analyticsEngine = {
        revenueAnalyzer = MonetizationAnalytics.createRevenueAnalyzer(),
        conversionTracker = MonetizationAnalytics.createConversionTracker(),
        cohortAnalyzer = MonetizationAnalytics.createCohortAnalyzer(),
        funnelAnalyzer = MonetizationAnalytics.createFunnelAnalyzer(),
        segmentAnalyzer = MonetizationAnalytics.createSegmentAnalyzer()
    }
    
    print("🔧 Analytics engine initialized")
end

function MonetizationAnalytics.createRevenueAnalyzer()
    return {
        name = "revenue_analyzer",
        
        analyzeRevenue = function(self, timeframe)
            return MonetizationAnalytics.analyzeRevenue(timeframe)
        end,
        
        calculateARPU = function(self, playerSegment)
            return MonetizationAnalytics.calculateARPU(playerSegment)
        end,
        
        calculateLTV = function(self, playerCohort)
            return MonetizationAnalytics.calculateLTV(playerCohort)
        end
    }
end

function MonetizationAnalytics.createConversionTracker()
    return {
        name = "conversion_tracker",
        
        trackConversion = function(self, event)
            MonetizationAnalytics.trackConversionEvent(event)
        end,
        
        calculateConversionRate = function(self, funnel)
            return MonetizationAnalytics.calculateConversionRate(funnel)
        end
    }
end

function MonetizationAnalytics.createCohortAnalyzer()
    return {
        name = "cohort_analyzer",
        
        createCohort = function(self, players, period)
            return MonetizationAnalytics.createPlayerCohort(players, period)
        end,
        
        analyzeCohort = function(self, cohortId)
            return MonetizationAnalytics.analyzeCohortPerformance(cohortId)
        end
    }
end

function MonetizationAnalytics.createFunnelAnalyzer()
    return {
        name = "funnel_analyzer",
        
        analyzeFunnel = function(self, funnelSteps)
            return MonetizationAnalytics.analyzeFunnel(funnelSteps)
        end
    }
end

function MonetizationAnalytics.createSegmentAnalyzer()
    return {
        name = "segment_analyzer",
        
        segmentPlayers = function(self, criteria)
            return MonetizationAnalytics.segmentPlayers(criteria)
        end,
        
        analyzeSegment = function(self, segmentId)
            return MonetizationAnalytics.analyzeSegmentPerformance(segmentId)
        end
    }
end

function MonetizationAnalytics.trackRevenue(playerId, amount, productId, timestamp)
    timestamp = timestamp or tick()
    
    local revenueEvent = {
        playerId = playerId,
        amount = amount,
        productId = productId,
        timestamp = timestamp,
        date = os.date("%Y-%m-%d", timestamp),
        hour = os.date("%H", timestamp)
    }
    
    table.insert(AnalyticsState.revenueData, revenueEvent)
    
    -- Update player metrics
    MonetizationAnalytics.updatePlayerMetrics(playerId, "revenue", amount)
    
    -- Update real-time metrics
    MonetizationAnalytics.updateRealTimeRevenue(amount)
    
    -- Update statistics
    AnalyticsState.stats.totalRevenue = AnalyticsState.stats.totalRevenue + amount
    MonetizationAnalytics.updateARPU()
    
    print(string.format("💰 Revenue tracked: Player %d spent R$%d on %s", 
        playerId, amount, productId))
end

function MonetizationAnalytics.trackConversionEvent(event)
    local conversionEvent = {
        playerId = event.playerId,
        eventType = event.eventType,
        step = event.step,
        value = event.value,
        timestamp = tick(),
        metadata = event.metadata or {}
    }
    
    table.insert(AnalyticsState.conversionData, conversionEvent)
    
    -- Update conversion funnel
    MonetizationAnalytics.updateConversionFunnel(event.eventType, event.step)
    
    -- Check for conversion completion
    if event.step == "purchase" then
        AnalyticsState.stats.totalConversions = AnalyticsState.stats.totalConversions + 1
        MonetizationAnalytics.updateConversionRate()
    end
    
    print(string.format("🎯 Conversion tracked: Player %d - %s:%s", 
        event.playerId, event.eventType, event.step))
end

function MonetizationAnalytics.analyzeRevenue(timeframe)
    timeframe = timeframe or "daily"
    
    local analysis = {
        timeframe = timeframe,
        totalRevenue = 0,
        transactionCount = 0,
        averageTransactionValue = 0,
        revenueByProduct = {},
        revenueBySegment = {},
        trends = {}
    }
    
    local cutoffTime = MonetizationAnalytics.getTimeframeCutoff(timeframe)
    
    -- Analyze revenue data
    for _, revenueEvent in ipairs(AnalyticsState.revenueData) do
        if revenueEvent.timestamp >= cutoffTime then
            analysis.totalRevenue = analysis.totalRevenue + revenueEvent.amount
            analysis.transactionCount = analysis.transactionCount + 1
            
            -- Revenue by product
            if not analysis.revenueByProduct[revenueEvent.productId] then
                analysis.revenueByProduct[revenueEvent.productId] = 0
            end
            analysis.revenueByProduct[revenueEvent.productId] = 
                analysis.revenueByProduct[revenueEvent.productId] + revenueEvent.amount
        end
    end
    
    -- Calculate averages
    if analysis.transactionCount > 0 then
        analysis.averageTransactionValue = analysis.totalRevenue / analysis.transactionCount
    end
    
    -- Analyze trends
    analysis.trends = MonetizationAnalytics.calculateRevenueTrends(timeframe)
    
    return analysis
end

function MonetizationAnalytics.calculateARPU(playerSegment)
    playerSegment = playerSegment or "all"
    
    local totalRevenue = 0
    local playerCount = 0
    local activePlayers = {}
    
    -- Get players in segment
    for _, revenueEvent in ipairs(AnalyticsState.revenueData) do
        if not activePlayers[revenueEvent.playerId] then
            activePlayers[revenueEvent.playerId] = {revenue = 0, count = 0}
            playerCount = playerCount + 1
        end
        
        activePlayers[revenueEvent.playerId].revenue = 
            activePlayers[revenueEvent.playerId].revenue + revenueEvent.amount
        totalRevenue = totalRevenue + revenueEvent.amount
    end
    
    local arpu = playerCount > 0 and (totalRevenue / playerCount) or 0
    
    return {
        segment = playerSegment,
        arpu = arpu,
        totalRevenue = totalRevenue,
        playerCount = playerCount
    }
end

function MonetizationAnalytics.calculateLTV(playerCohort)
    playerCohort = playerCohort or "all"
    
    local cohortRevenue = {}
    local cohortDays = {}
    
    -- Group revenue by days since first purchase
    for _, revenueEvent in ipairs(AnalyticsState.revenueData) do
        local playerMetrics = AnalyticsState.playerMetrics[revenueEvent.playerId]
        if playerMetrics and playerMetrics.firstPurchase then
            local daysSinceFirst = math.floor((revenueEvent.timestamp - playerMetrics.firstPurchase) / 86400)
            
            if not cohortRevenue[daysSinceFirst] then
                cohortRevenue[daysSinceFirst] = 0
                cohortDays[daysSinceFirst] = 0
            end
            
            cohortRevenue[daysSinceFirst] = cohortRevenue[daysSinceFirst] + revenueEvent.amount
            cohortDays[daysSinceFirst] = cohortDays[daysSinceFirst] + 1
        end
    end
    
    -- Calculate cumulative LTV
    local cumulativeLTV = {}
    local totalLTV = 0
    
    for day = 0, 90 do -- 90-day LTV
        if cohortRevenue[day] then
            totalLTV = totalLTV + (cohortRevenue[day] / math.max(1, cohortDays[day]))
        end
        cumulativeLTV[day] = totalLTV
    end
    
    return {
        cohort = playerCohort,
        ltv30 = cumulativeLTV[30] or 0,
        ltv60 = cumulativeLTV[60] or 0,
        ltv90 = cumulativeLTV[90] or 0,
        cumulativeLTV = cumulativeLTV
    }
end

function MonetizationAnalytics.calculateConversionRate(funnel)
    funnel = funnel or "purchase"
    
    local funnelData = AnalyticsState.conversionFunnels[funnel]
    if not funnelData then
        return {funnel = funnel, rate = 0, steps = {}}
    end
    
    local steps = {}
    local stepNames = {"view", "interest", "intent", "purchase"}
    
    for i, stepName in ipairs(stepNames) do
        local stepCount = funnelData[stepName] or 0
        local previousCount = i == 1 and stepCount or (funnelData[stepNames[i-1]] or 0)
        
        steps[stepName] = {
            count = stepCount,
            rate = previousCount > 0 and (stepCount / previousCount) or 0
        }
    end
    
    local overallRate = (funnelData.view or 0) > 0 and 
        ((funnelData.purchase or 0) / funnelData.view) or 0
    
    return {
        funnel = funnel,
        rate = overallRate,
        steps = steps
    }
end

-- ========================================
-- KPI TRACKING
-- ========================================

function MonetizationAnalytics.initializeKPITracking()
    AnalyticsState.kpiTracker = {
        conversionRateTracker = MonetizationAnalytics.createConversionRateTracker(),
        arpuTracker = MonetizationAnalytics.createARPUTracker(),
        ltvTracker = MonetizationAnalytics.createLTVTracker(),
        retentionTracker = MonetizationAnalytics.createRetentionTracker()
    }
    
    print("📈 KPI tracking initialized")
end

function MonetizationAnalytics.createConversionRateTracker()
    return {
        name = "conversion_rate_tracker",
        
        track = function(self)
            return MonetizationAnalytics.trackConversionRateKPI()
        end
    }
end

function MonetizationAnalytics.createARPUTracker()
    return {
        name = "arpu_tracker",
        
        track = function(self)
            return MonetizationAnalytics.trackARPUKPI()
        end
    }
end

function MonetizationAnalytics.createLTVTracker()
    return {
        name = "ltv_tracker",
        
        track = function(self)
            return MonetizationAnalytics.trackLTVKPI()
        end
    }
end

function MonetizationAnalytics.createRetentionTracker()
    return {
        name = "retention_tracker",
        
        track = function(self)
            return MonetizationAnalytics.trackRetentionKPI()
        end
    }
end

function MonetizationAnalytics.trackConversionRateKPI()
    local conversionAnalysis = MonetizationAnalytics.calculateConversionRate("purchase")
    local rate = conversionAnalysis.rate
    
    local performance = "poor"
    local thresholds = ANALYTICS_CONFIG.kpiThresholds.conversionRate
    
    if rate >= thresholds.excellent then
        performance = "excellent"
    elseif rate >= thresholds.good then
        performance = "good"
    elseif rate >= thresholds.average then
        performance = "average"
    end
    
    local kpi = {
        name = "conversion_rate",
        value = rate,
        performance = performance,
        timestamp = tick(),
        trend = MonetizationAnalytics.calculateKPITrend("conversion_rate", rate)
    }
    
    AnalyticsState.kpiMetrics.conversion_rate = kpi
    return kpi
end

function MonetizationAnalytics.trackARPUKPI()
    local arpuAnalysis = MonetizationAnalytics.calculateARPU("all")
    local arpu = arpuAnalysis.arpu
    
    local performance = "poor"
    local thresholds = ANALYTICS_CONFIG.kpiThresholds.arpu
    
    if arpu >= thresholds.excellent then
        performance = "excellent"
    elseif arpu >= thresholds.good then
        performance = "good"
    elseif arpu >= thresholds.average then
        performance = "average"
    end
    
    local kpi = {
        name = "arpu",
        value = arpu,
        performance = performance,
        timestamp = tick(),
        trend = MonetizationAnalytics.calculateKPITrend("arpu", arpu)
    }
    
    AnalyticsState.kpiMetrics.arpu = kpi
    AnalyticsState.stats.averageARPU = arpu
    
    return kpi
end

function MonetizationAnalytics.trackLTVKPI()
    local ltvAnalysis = MonetizationAnalytics.calculateLTV("all")
    local ltv = ltvAnalysis.ltv30
    
    local performance = "poor"
    local thresholds = ANALYTICS_CONFIG.kpiThresholds.ltv
    
    if ltv >= thresholds.excellent then
        performance = "excellent"
    elseif ltv >= thresholds.good then
        performance = "good"
    elseif ltv >= thresholds.average then
        performance = "average"
    end
    
    local kpi = {
        name = "ltv_30",
        value = ltv,
        performance = performance,
        timestamp = tick(),
        trend = MonetizationAnalytics.calculateKPITrend("ltv", ltv)
    }
    
    AnalyticsState.kpiMetrics.ltv = kpi
    AnalyticsState.stats.averageLTV = ltv
    
    return kpi
end

function MonetizationAnalytics.trackRetentionKPI()
    local retention7 = MonetizationAnalytics.calculateRetentionRate(7)
    local retention30 = MonetizationAnalytics.calculateRetentionRate(30)
    
    local performance7 = retention7 >= ANALYTICS_CONFIG.kpiThresholds.retention.day7 and "good" or "poor"
    local performance30 = retention30 >= ANALYTICS_CONFIG.kpiThresholds.retention.day30 and "good" or "poor"
    
    local kpi = {
        name = "retention",
        day7 = {
            value = retention7,
            performance = performance7
        },
        day30 = {
            value = retention30,
            performance = performance30
        },
        timestamp = tick()
    }
    
    AnalyticsState.kpiMetrics.retention = kpi
    AnalyticsState.stats.retentionRate7Day = retention7
    AnalyticsState.stats.retentionRate30Day = retention30
    
    return kpi
end

function MonetizationAnalytics.calculateRetentionRate(days)
    -- Simplified retention calculation
    local cutoffDate = tick() - (days * 86400)
    local newPlayers = 0
    local retainedPlayers = 0
    
    -- Count new players and those who returned
    for playerId, metrics in pairs(AnalyticsState.playerMetrics) do
        if metrics.firstSeen and metrics.firstSeen >= cutoffDate then
            newPlayers = newPlayers + 1
            
            if metrics.lastSeen and (metrics.lastSeen - metrics.firstSeen) >= (days * 86400 * 0.8) then
                retainedPlayers = retainedPlayers + 1
            end
        end
    end
    
    return newPlayers > 0 and (retainedPlayers / newPlayers) or 0
end

-- ========================================
-- OPTIMIZATION ENGINE
-- ========================================

function MonetizationAnalytics.setupOptimizationEngine()
    AnalyticsState.optimizationEngine = {
        abTester = MonetizationAnalytics.createABTester(),
        pricingOptimizer = MonetizationAnalytics.createPricingOptimizer(),
        personalizer = MonetizationAnalytics.createPersonalizer(),
        predictor = MonetizationAnalytics.createPredictor()
    }
    
    print("🎯 Optimization engine initialized")
end

function MonetizationAnalytics.createABTester()
    return {
        name = "ab_tester",
        
        createTest = function(self, testConfig)
            return MonetizationAnalytics.createABTest(testConfig)
        end,
        
        analyzeResults = function(self, testId)
            return MonetizationAnalytics.analyzeABTestResults(testId)
        end
    }
end

function MonetizationAnalytics.createPricingOptimizer()
    return {
        name = "pricing_optimizer",
        
        optimize = function(self, productId)
            return MonetizationAnalytics.optimizeProductPricing(productId)
        end
    }
end

function MonetizationAnalytics.createPersonalizer()
    return {
        name = "personalizer",
        
        personalize = function(self, playerId)
            return MonetizationAnalytics.personalizeOffers(playerId)
        end
    }
end

function MonetizationAnalytics.createPredictor()
    return {
        name = "predictor",
        
        predict = function(self, playerId, metric)
            return MonetizationAnalytics.predictPlayerMetric(playerId, metric)
        end
    }
end

function MonetizationAnalytics.createABTest(testConfig)
    local abTest = {
        id = HttpService:GenerateGUID(false),
        name = testConfig.name,
        hypothesis = testConfig.hypothesis,
        variants = testConfig.variants,
        trafficAllocation = testConfig.trafficAllocation or {50, 50},
        successMetric = testConfig.successMetric,
        startTime = tick(),
        endTime = nil,
        status = "running",
        results = {},
        participants = {}
    }
    
    AnalyticsState.abTestResults[abTest.id] = abTest
    
    print(string.format("🧪 A/B Test created: %s (%s)", abTest.name, abTest.id))
    
    return abTest
end

function MonetizationAnalytics.analyzeABTestResults(testId)
    local test = AnalyticsState.abTestResults[testId]
    if not test then
        return nil
    end
    
    local analysis = {
        testId = testId,
        testName = test.name,
        variants = {},
        winner = nil,
        confidence = 0,
        statisticalSignificance = false,
        recommendation = ""
    }
    
    -- Analyze each variant
    for variantName, variantData in pairs(test.variants) do
        local variantAnalysis = {
            name = variantName,
            participants = #(test.participants[variantName] or {}),
            conversions = 0,
            conversionRate = 0,
            revenue = 0,
            arpu = 0
        }
        
        -- Calculate metrics for variant
        if test.participants[variantName] then
            for _, playerId in ipairs(test.participants[variantName]) do
                -- Calculate conversions and revenue for this player
                local playerRevenue = MonetizationAnalytics.getPlayerRevenue(playerId, test.startTime)
                variantAnalysis.revenue = variantAnalysis.revenue + playerRevenue
                
                if playerRevenue > 0 then
                    variantAnalysis.conversions = variantAnalysis.conversions + 1
                end
            end
            
            variantAnalysis.conversionRate = variantAnalysis.participants > 0 and 
                (variantAnalysis.conversions / variantAnalysis.participants) or 0
            
            variantAnalysis.arpu = variantAnalysis.participants > 0 and 
                (variantAnalysis.revenue / variantAnalysis.participants) or 0
        end
        
        analysis.variants[variantName] = variantAnalysis
    end
    
    -- Determine winner
    local bestVariant = nil
    local bestMetric = 0
    
    for variantName, variantData in pairs(analysis.variants) do
        local metric = test.successMetric == "revenue" and variantData.arpu or variantData.conversionRate
        
        if metric > bestMetric then
            bestMetric = metric
            bestVariant = variantName
        end
    end
    
    analysis.winner = bestVariant
    analysis.confidence = MonetizationAnalytics.calculateStatisticalConfidence(analysis.variants)
    analysis.statisticalSignificance = analysis.confidence > 0.95
    
    if analysis.statisticalSignificance then
        analysis.recommendation = string.format("Implement variant '%s' - statistically significant improvement", 
            bestVariant)
    else
        analysis.recommendation = "Continue test - not yet statistically significant"
    end
    
    return analysis
end

function MonetizationAnalytics.optimizeProductPricing(productId)
    local optimization = {
        productId = productId,
        currentPrice = 0,
        recommendedPrice = 0,
        expectedRevenueLift = 0,
        confidence = 0,
        reasoning = {}
    }
    
    -- Get current pricing data
    local pricingData = MonetizationAnalytics.getProductPricingData(productId)
    optimization.currentPrice = pricingData.currentPrice
    
    -- Analyze demand elasticity
    local elasticity = MonetizationAnalytics.calculatePriceElasticity(productId)
    
    -- Calculate optimal price point
    local optimalPrice = MonetizationAnalytics.calculateOptimalPrice(productId, elasticity)
    optimization.recommendedPrice = optimalPrice
    
    -- Calculate expected impact
    local currentRevenue = pricingData.revenue
    local expectedRevenue = MonetizationAnalytics.predictRevenueAtPrice(productId, optimalPrice)
    optimization.expectedRevenueLift = (expectedRevenue - currentRevenue) / currentRevenue
    
    optimization.confidence = 0.8 -- Would calculate based on data quality
    
    table.insert(optimization.reasoning, string.format("Price elasticity: %.2f", elasticity))
    table.insert(optimization.reasoning, string.format("Expected %.1f%% revenue increase", 
        optimization.expectedRevenueLift * 100))
    
    return optimization
end

function MonetizationAnalytics.personalizeOffers(playerId)
    local playerMetrics = AnalyticsState.playerMetrics[playerId]
    if not playerMetrics then
        return {}
    end
    
    local offers = {}
    
    -- Analyze player spending behavior
    local spendingTier = MonetizationAnalytics.getPlayerSpendingTier(playerId)
    local engagementLevel = MonetizationAnalytics.getPlayerEngagementLevel(playerId)
    local churnRisk = MonetizationAnalytics.calculatePlayerChurnRisk(playerId)
    
    -- Generate personalized offers
    if spendingTier == "whale" then
        table.insert(offers, {
            type = "premium_bundle",
            discount = 0.15,
            reason = "High-value customer appreciation"
        })
        
    elseif spendingTier == "free" and engagementLevel == "high" then
        table.insert(offers, {
            type = "first_purchase_incentive",
            discount = 0.5,
            reason = "High engagement, no purchases yet"
        })
        
    elseif churnRisk > 0.7 then
        table.insert(offers, {
            type = "retention_offer",
            discount = 0.3,
            reason = "High churn risk detected"
        })
    end
    
    return offers
end

-- ========================================
-- REAL-TIME MONITORING
-- ========================================

function MonetizationAnalytics.initializeRealTimeMonitoring()
    AnalyticsState.realTimeMonitor = {
        revenueTracker = MonetizationAnalytics.createRealTimeRevenueTracker(),
        conversionTracker = MonetizationAnalytics.createRealTimeConversionTracker(),
        alertSystem = MonetizationAnalytics.createAlertSystem()
    }
    
    print("⚡ Real-time monitoring initialized")
end

function MonetizationAnalytics.createRealTimeRevenueTracker()
    return {
        name = "realtime_revenue_tracker",
        
        update = function(self, amount)
            MonetizationAnalytics.updateRealTimeRevenue(amount)
        end
    }
end

function MonetizationAnalytics.createRealTimeConversionTracker()
    return {
        name = "realtime_conversion_tracker",
        
        update = function(self)
            MonetizationAnalytics.updateRealTimeConversions()
        end
    }
end

function MonetizationAnalytics.createAlertSystem()
    return {
        name = "alert_system",
        
        checkAlerts = function(self)
            MonetizationAnalytics.checkMonetizationAlerts()
        end
    }
end

function MonetizationAnalytics.updateRealTimeRevenue(amount)
    local currentTime = tick()
    local currentHour = os.date("%H", currentTime)
    
    if not AnalyticsState.realTimeMetrics.hourlyRevenue then
        AnalyticsState.realTimeMetrics.hourlyRevenue = {}
    end
    
    if not AnalyticsState.realTimeMetrics.hourlyRevenue[currentHour] then
        AnalyticsState.realTimeMetrics.hourlyRevenue[currentHour] = 0
    end
    
    AnalyticsState.realTimeMetrics.hourlyRevenue[currentHour] = 
        AnalyticsState.realTimeMetrics.hourlyRevenue[currentHour] + amount
    
    -- Update daily total
    AnalyticsState.realTimeMetrics.dailyRevenue = 
        (AnalyticsState.realTimeMetrics.dailyRevenue or 0) + amount
end

function MonetizationAnalytics.updateRealTimeConversions()
    AnalyticsState.realTimeMetrics.hourlyConversions = 
        (AnalyticsState.realTimeMetrics.hourlyConversions or 0) + 1
    
    AnalyticsState.realTimeMetrics.dailyConversions = 
        (AnalyticsState.realTimeMetrics.dailyConversions or 0) + 1
end

function MonetizationAnalytics.checkMonetizationAlerts()
    local alerts = {}
    
    -- Check for revenue anomalies
    local currentHourRevenue = AnalyticsState.realTimeMetrics.hourlyRevenue and 
        AnalyticsState.realTimeMetrics.hourlyRevenue[os.date("%H")] or 0
    
    local averageHourlyRevenue = MonetizationAnalytics.getAverageHourlyRevenue()
    
    if currentHourRevenue < averageHourlyRevenue * 0.5 then
        table.insert(alerts, {
            type = "low_revenue",
            severity = "warning",
            message = string.format("Hourly revenue 50%% below average: R$%.2f vs R$%.2f", 
                currentHourRevenue, averageHourlyRevenue)
        })
    end
    
    -- Check conversion rate alerts
    local currentConversionRate = MonetizationAnalytics.getCurrentConversionRate()
    local averageConversionRate = AnalyticsState.stats.overallConversionRate
    
    if currentConversionRate < averageConversionRate * 0.7 then
        table.insert(alerts, {
            type = "low_conversion",
            severity = "warning",
            message = string.format("Conversion rate 30%% below average: %.2f%% vs %.2f%%", 
                currentConversionRate * 100, averageConversionRate * 100)
        })
    end
    
    return alerts
end

-- ========================================
-- ANALYTICS COLLECTION
-- ========================================

function MonetizationAnalytics.startAnalyticsCollection()
    spawn(function()
        while true do
            MonetizationAnalytics.collectPeriodicAnalytics()
            MonetizationAnalytics.updateKPIMetrics()
            MonetizationAnalytics.runOptimizationAnalysis()
            
            task.wait(300) -- Update every 5 minutes
        end
    end)
    
    print("🔄 Analytics collection started")
end

function MonetizationAnalytics.collectPeriodicAnalytics()
    -- Update player metrics
    MonetizationAnalytics.updateAllPlayerMetrics()
    
    -- Update conversion rates
    MonetizationAnalytics.updateConversionRate()
    
    -- Update revenue metrics
    MonetizationAnalytics.updateRevenueMetrics()
    
    -- Update segmentation
    MonetizationAnalytics.updatePlayerSegmentation()
end

function MonetizationAnalytics.updateKPIMetrics()
    if not AnalyticsState.kpiTracker then
        return
    end
    
    -- Update all KPI trackers
    AnalyticsState.kpiTracker.conversionRateTracker:track()
    AnalyticsState.kpiTracker.arpuTracker:track()
    AnalyticsState.kpiTracker.ltvTracker:track()
    AnalyticsState.kpiTracker.retentionTracker:track()
end

function MonetizationAnalytics.runOptimizationAnalysis()
    if not ANALYTICS_CONFIG.optimization.enablePredictiveAnalytics then
        return
    end
    
    -- Run optimization algorithms
    MonetizationAnalytics.optimizeConversionFunnels()
    MonetizationAnalytics.optimizePlayerSegmentation()
    MonetizationAnalytics.generateRevenueForecasts()
end

-- ========================================
-- UTILITY FUNCTIONS
-- ========================================

function MonetizationAnalytics.updatePlayerMetrics(playerId, metricType, value)
    if not AnalyticsState.playerMetrics[playerId] then
        AnalyticsState.playerMetrics[playerId] = {
            firstSeen = tick(),
            lastSeen = tick(),
            totalRevenue = 0,
            totalPurchases = 0,
            averagePurchase = 0,
            firstPurchase = nil
        }
    end
    
    local metrics = AnalyticsState.playerMetrics[playerId]
    metrics.lastSeen = tick()
    
    if metricType == "revenue" then
        metrics.totalRevenue = metrics.totalRevenue + value
        metrics.totalPurchases = metrics.totalPurchases + 1
        metrics.averagePurchase = metrics.totalRevenue / metrics.totalPurchases
        
        if not metrics.firstPurchase then
            metrics.firstPurchase = tick()
        end
    end
end

function MonetizationAnalytics.updateConversionFunnel(eventType, step)
    if not AnalyticsState.conversionFunnels[eventType] then
        AnalyticsState.conversionFunnels[eventType] = {}
    end
    
    local funnel = AnalyticsState.conversionFunnels[eventType]
    funnel[step] = (funnel[step] or 0) + 1
end

function MonetizationAnalytics.updateConversionRate()
    local totalVisitors = 0
    local totalConverters = 0
    
    for eventType, funnel in pairs(AnalyticsState.conversionFunnels) do
        totalVisitors = totalVisitors + (funnel.view or 0)
        totalConverters = totalConverters + (funnel.purchase or 0)
    end
    
    AnalyticsState.stats.overallConversionRate = totalVisitors > 0 and 
        (totalConverters / totalVisitors) or 0
end

function MonetizationAnalytics.updateARPU()
    local totalRevenue = AnalyticsState.stats.totalRevenue
    local totalPlayers = 0
    
    for _ in pairs(AnalyticsState.playerMetrics) do
        totalPlayers = totalPlayers + 1
    end
    
    AnalyticsState.stats.averageARPU = totalPlayers > 0 and (totalRevenue / totalPlayers) or 0
end

function MonetizationAnalytics.getTimeframeCutoff(timeframe)
    local currentTime = tick()
    
    if timeframe == "hourly" then
        return currentTime - 3600
    elseif timeframe == "daily" then
        return currentTime - 86400
    elseif timeframe == "weekly" then
        return currentTime - (7 * 86400)
    elseif timeframe == "monthly" then
        return currentTime - (30 * 86400)
    else
        return currentTime - 86400 -- Default to daily
    end
end

function MonetizationAnalytics.calculateRevenueTrends(timeframe)
    -- Simplified trend calculation
    return {
        direction = "up",
        magnitude = 0.05, -- 5% increase
        confidence = 0.8
    }
end

function MonetizationAnalytics.calculateKPITrend(kpiName, currentValue)
    -- Simplified trend calculation
    return {
        direction = "stable",
        change = 0,
        period = "week"
    }
end

function MonetizationAnalytics.getPlayerRevenue(playerId, sinceTime)
    local metrics = AnalyticsState.playerMetrics[playerId]
    if not metrics then
        return 0
    end
    
    local revenue = 0
    for _, revenueEvent in ipairs(AnalyticsState.revenueData) do
        if revenueEvent.playerId == playerId and revenueEvent.timestamp >= sinceTime then
            revenue = revenue + revenueEvent.amount
        end
    end
    
    return revenue
end

function MonetizationAnalytics.calculateStatisticalConfidence(variants)
    -- Simplified confidence calculation
    local totalParticipants = 0
    for _, variant in pairs(variants) do
        totalParticipants = totalParticipants + variant.participants
    end
    
    -- More participants = higher confidence (simplified)
    return math.min(0.99, totalParticipants / 1000)
end

function MonetizationAnalytics.getProductPricingData(productId)
    return {
        currentPrice = 99, -- Would get from actual product data
        revenue = 1000,    -- Would calculate from analytics
        units = 50         -- Would calculate from analytics
    }
end

function MonetizationAnalytics.calculatePriceElasticity(productId)
    -- Simplified elasticity calculation
    return -1.2 -- Typical elasticity for digital goods
end

function MonetizationAnalytics.calculateOptimalPrice(productId, elasticity)
    local currentPrice = MonetizationAnalytics.getProductPricingData(productId).currentPrice
    
    -- Simplified optimization (would use more sophisticated algorithms)
    if elasticity < -1.5 then
        return currentPrice * 0.9 -- Reduce price for elastic demand
    elseif elasticity > -0.8 then
        return currentPrice * 1.1 -- Increase price for inelastic demand
    else
        return currentPrice -- Keep current price
    end
end

function MonetizationAnalytics.predictRevenueAtPrice(productId, price)
    local currentData = MonetizationAnalytics.getProductPricingData(productId)
    local elasticity = MonetizationAnalytics.calculatePriceElasticity(productId)
    
    local priceChange = (price - currentData.currentPrice) / currentData.currentPrice
    local demandChange = elasticity * priceChange
    
    local newUnits = currentData.units * (1 + demandChange)
    return newUnits * price
end

function MonetizationAnalytics.getPlayerSpendingTier(playerId)
    local metrics = AnalyticsState.playerMetrics[playerId]
    if not metrics then
        return "free"
    end
    
    local totalSpent = metrics.totalRevenue
    local tiers = ANALYTICS_CONFIG.segmentation.spendingTiers
    
    if totalSpent >= tiers.whale then
        return "whale"
    elseif totalSpent >= tiers.dolphin then
        return "dolphin"
    elseif totalSpent >= tiers.minnow then
        return "minnow"
    else
        return "free"
    end
end

function MonetizationAnalytics.getPlayerEngagementLevel(playerId)
    -- Simplified engagement calculation
    local metrics = AnalyticsState.playerMetrics[playerId]
    if not metrics then
        return "low"
    end
    
    local daysSinceFirst = (tick() - metrics.firstSeen) / 86400
    local sessionFrequency = daysSinceFirst > 0 and (1 / daysSinceFirst) or 0
    
    if sessionFrequency > 0.8 then
        return "high"
    elseif sessionFrequency > 0.4 then
        return "medium"
    else
        return "low"
    end
end

function MonetizationAnalytics.calculatePlayerChurnRisk(playerId)
    local metrics = AnalyticsState.playerMetrics[playerId]
    if not metrics then
        return 0.5
    end
    
    local daysSinceLastSeen = (tick() - metrics.lastSeen) / 86400
    
    if daysSinceLastSeen > 7 then
        return 0.8 -- High churn risk
    elseif daysSinceLastSeen > 3 then
        return 0.5 -- Medium churn risk
    else
        return 0.2 -- Low churn risk
    end
end

function MonetizationAnalytics.getAverageHourlyRevenue()
    -- Simplified calculation
    return 100 -- Would calculate from historical data
end

function MonetizationAnalytics.getCurrentConversionRate()
    -- Simplified calculation
    return 0.05 -- 5% current conversion rate
end

-- ========================================
-- PUBLIC API
-- ========================================

function MonetizationAnalytics.runAnalyticsDemo()
    print("📊 Running monetization analytics demonstration...")
    
    -- Simulate some revenue events
    print("  💰 Simulating revenue events...")
    
    for i = 1, 10 do
        local playerId = 1000 + i
        local amount = math.random(10, 500)
        local productId = "product_" .. math.random(1, 5)
        
        MonetizationAnalytics.trackRevenue(playerId, amount, productId)
        
        -- Simulate conversion funnel
        MonetizationAnalytics.trackConversionEvent({
            playerId = playerId,
            eventType = "purchase_funnel",
            step = "view"
        })
        
        if math.random() > 0.3 then
            MonetizationAnalytics.trackConversionEvent({
                playerId = playerId,
                eventType = "purchase_funnel",
                step = "interest"
            })
            
            if math.random() > 0.5 then
                MonetizationAnalytics.trackConversionEvent({
                    playerId = playerId,
                    eventType = "purchase_funnel",
                    step = "purchase"
                })
            end
        end
    end
    
    -- Show analytics results
    print("  📈 Analytics Results:")
    
    -- Revenue analysis
    local revenueAnalysis = MonetizationAnalytics.analyzeRevenue("daily")
    print(string.format("    Daily Revenue: R$%.2f (%d transactions)", 
        revenueAnalysis.totalRevenue, revenueAnalysis.transactionCount))
    print(string.format("    Average Transaction: R$%.2f", 
        revenueAnalysis.averageTransactionValue))
    
    -- ARPU analysis
    local arpuAnalysis = MonetizationAnalytics.calculateARPU("all")
    print(string.format("    ARPU: R$%.2f (%d players)", 
        arpuAnalysis.arpu, arpuAnalysis.playerCount))
    
    -- LTV analysis
    local ltvAnalysis = MonetizationAnalytics.calculateLTV("all")
    print(string.format("    LTV 30-day: R$%.2f", ltvAnalysis.ltv30))
    
    -- Conversion analysis
    local conversionAnalysis = MonetizationAnalytics.calculateConversionRate("purchase_funnel")
    print(string.format("    Overall Conversion Rate: %.2f%%", 
        conversionAnalysis.rate * 100))
    
    -- Show KPI tracking
    print("  📊 KPI Tracking:")
    
    MonetizationAnalytics.updateKPIMetrics()
    
    for kpiName, kpi in pairs(AnalyticsState.kpiMetrics) do
        if kpiName ~= "retention" then
            print(string.format("    %s: %.2f (%s)", 
                kpiName:upper(), kpi.value, kpi.performance))
        else
            print(string.format("    RETENTION: Day 7: %.1f%%, Day 30: %.1f%%", 
                kpi.day7.value * 100, kpi.day30.value * 100))
        end
    end
    
    -- Show optimization recommendations
    print("  🎯 Optimization Recommendations:")
    
    local pricingOptimization = MonetizationAnalytics.optimizeProductPricing("product_1")
    print(string.format("    Product 1 Pricing: R$%d -> R$%d (%.1f%% lift)", 
        pricingOptimization.currentPrice, pricingOptimization.recommendedPrice,
        pricingOptimization.expectedRevenueLift * 100))
    
    -- Show personalization
    local personalizedOffers = MonetizationAnalytics.personalizeOffers(1001)
    if #personalizedOffers > 0 then
        print("    Personalized Offers:")
        for _, offer in ipairs(personalizedOffers) do
            print(string.format("      %s: %.0f%% off (%s)", 
                offer.type, offer.discount * 100, offer.reason))
        end
    end
    
    -- Show real-time metrics
    print("  ⚡ Real-time Metrics:")
    print(string.format("    Daily Revenue: R$%.2f", 
        AnalyticsState.realTimeMetrics.dailyRevenue or 0))
    print(string.format("    Daily Conversions: %d", 
        AnalyticsState.realTimeMetrics.dailyConversions or 0))
    
    -- Check for alerts
    local alerts = MonetizationAnalytics.checkMonetizationAlerts()
    if #alerts > 0 then
        print("  🚨 Alerts:")
        for _, alert in ipairs(alerts) do
            print(string.format("    %s: %s", alert.type:upper(), alert.message))
        end
    else
        print("  ✅ No alerts - all metrics normal")
    end
    
    print("📊 Monetization analytics demonstration completed")
end

function MonetizationAnalytics.getAnalyticsStats()
    return AnalyticsState.stats
end

function MonetizationAnalytics.getKPIMetrics()
    return AnalyticsState.kpiMetrics
end

function MonetizationAnalytics.getRevenueData()
    return AnalyticsState.revenueData
end

function MonetizationAnalytics.getPlayerMetrics(playerId)
    return AnalyticsState.playerMetrics[playerId]
end

function MonetizationAnalytics.getRealTimeMetrics()
    return AnalyticsState.realTimeMetrics
end

-- Export API
MonetizationAnalytics.trackRevenue = MonetizationAnalytics.trackRevenue
MonetizationAnalytics.trackConversionEvent = MonetizationAnalytics.trackConversionEvent
MonetizationAnalytics.analyzeRevenue = MonetizationAnalytics.analyzeRevenue
MonetizationAnalytics.calculateARPU = MonetizationAnalytics.calculateARPU
MonetizationAnalytics.calculateLTV = MonetizationAnalytics.calculateLTV

-- Initialize the monetization analytics system
MonetizationAnalytics.initialize()

print("📊 MonetizationAnalytics loaded with comprehensive tracking and optimization")

return MonetizationAnalytics
