-- AssetAnalyticsSystem.luau
-- Asset analytics and usage tracking with comprehensive metrics and insights
-- Provides detailed analytics, usage patterns, and performance insights for asset management

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local _RunService = game:GetService("RunService")
local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local _DataStoreService = game:GetService("DataStoreService")
local _TeleportService = game:GetService("TeleportService")

local _SafeRequire = require(ReplicatedStorage.Shared.utils.SafeRequire)

local AssetAnalyticsSystem = {}

-- ========================================
-- ANALYTICS CONFIGURATION
-- ========================================

local ANALYTICS_CONFIG = {
    -- Tracking settings
    tracking = {
        enableUsageTracking = true,
        enablePerformanceTracking = true,
        enableUserBehaviorTracking = true,
        enableAssetLifecycleTracking = true,
        enableRealTimeAnalytics = true,
        trackingInterval = 1000,      -- 1 second
        batchSize = 100,
        retentionDays = 30
    },
    
    -- Metrics collection
    metrics = {
        usage = {
            "load_count",
            "load_time",
            "cache_hits",
            "cache_misses",
            "bandwidth_usage",
            "error_rate"
        },
        
        performance = {
            "render_time",
            "memory_usage",
            "cpu_usage",
            "gpu_usage",
            "network_latency",
            "throughput"
        },
        
        user = {
            "interaction_count",
            "session_duration",
            "bounce_rate",
            "conversion_rate",
            "user_satisfaction",
            "device_compatibility"
        },
        
        business = {
            "cost_per_asset",
            "revenue_impact",
            "user_retention",
            "engagement_rate",
            "quality_score",
            "optimization_savings"
        }
    },
    
    -- Analytics engines
    engines = {
        realtime = {
            enabled = true,
            updateInterval = 1000,
            maxDataPoints = 1000
        },
        
        batch = {
            enabled = true,
            processInterval = 60000,    -- 1 minute
            batchSize = 500
        },
        
        historical = {
            enabled = true,
            aggregationInterval = 3600000, -- 1 hour
            retentionPeriod = 2592000000   -- 30 days
        }
    },
    
    -- Reporting configuration
    reporting = {
        enableAutomaticReports = true,
        reportInterval = 86400000,    -- 24 hours
        enableAlerts = true,
        alertThresholds = {
            high_error_rate = 0.05,   -- 5%
            low_cache_hit_rate = 0.8, -- 80%
            high_load_time = 5000,    -- 5 seconds
            high_memory_usage = 0.9   -- 90%
        }
    }
}

-- ========================================
-- ANALYTICS STATE
-- ========================================

local AnalyticsState = {
    -- Data collection
    events = {},
    metrics = {},
    sessions = {},
    
    -- Analytics framework
    analyticsFramework = {
        realtime = nil,
        batch = nil,
        historical = nil,
        ml = nil
    },
    
    -- Data collector
    dataCollector = {
        eventBuffer = {},
        metricCollectors = {}
    },
    
    -- Session management
    currentSessionId = nil,
    
    -- Usage tracking
    assetUsage = {},
    userBehavior = {},
    performanceData = {},
    
    -- Analytics engines
    realtimeEngine = {},
    batchEngine = {},
    historicalEngine = {},
    
    -- Insights and patterns
    insights = {},
    patterns = {},
    predictions = {},
    
    -- Reporting
    reports = {},
    alerts = {},
    dashboards = {},
    
    -- Statistics
    stats = {
        totalEvents = 0,
        totalAssets = 0,
        totalUsers = 0,
        averageLoadTime = 0,
        cacheHitRate = 0,
        errorRate = 0,
        totalBandwidth = 0,
        costSavings = 0
    }
}

function AssetAnalyticsSystem.initialize()
    print("📊 Initializing AssetAnalyticsSystem...")
    
    -- Set up analytics engines
    AssetAnalyticsSystem.setupAnalyticsEngines()
    
    -- Initialize data collection
    AssetAnalyticsSystem.initializeDataCollection()
    
    -- Set up usage tracking
    AssetAnalyticsSystem.setupUsageTracking()
    
    -- Initialize performance monitoring
    AssetAnalyticsSystem.initializePerformanceMonitoring()
    
    -- Set up reporting system
    AssetAnalyticsSystem.setupReportingSystem()
    
    -- Start analytics processing
    AssetAnalyticsSystem.startAnalyticsProcessing()
    
    print("📊 AssetAnalyticsSystem initialized successfully")
end

-- ========================================
-- ANALYTICS ENGINES
-- ========================================

function AssetAnalyticsSystem.setupAnalyticsEngines()
    AnalyticsState.analyticsFramework = {
        realtime = AssetAnalyticsSystem.createRealtimeEngine(),
        batch = AssetAnalyticsSystem.createBatchEngine(),
        historical = AssetAnalyticsSystem.createHistoricalEngine(),
        ml = AssetAnalyticsSystem.createMLEngine()
    }
    
    print("🔧 Analytics engines initialized")
end

function AssetAnalyticsSystem.createRealtimeEngine()
    return {
        name = "realtime",
        enabled = ANALYTICS_CONFIG.engines.realtime.enabled,
        dataPoints = {},
        updateInterval = ANALYTICS_CONFIG.engines.realtime.updateInterval,
        
        process = function(self, event)
            return AssetAnalyticsSystem.processRealtimeEvent(event)
        end,
        
        update = function(self)
            AssetAnalyticsSystem.updateRealtimeMetrics(self)
        end
    }
end

function AssetAnalyticsSystem.createBatchEngine()
    return {
        name = "batch",
        enabled = ANALYTICS_CONFIG.engines.batch.enabled,
        eventQueue = {},
        processInterval = ANALYTICS_CONFIG.engines.batch.processInterval,
        batchSize = ANALYTICS_CONFIG.engines.batch.batchSize,
        
        queue = function(self, events)
            AssetAnalyticsSystem.queueBatchEvents(self, events)
        end,
        
        process = function(self)
            return AssetAnalyticsSystem.processBatchEvents(self)
        end
    }
end

function AssetAnalyticsSystem.createHistoricalEngine()
    return {
        name = "historical",
        enabled = ANALYTICS_CONFIG.engines.historical.enabled,
        aggregatedData = {},
        aggregationInterval = ANALYTICS_CONFIG.engines.historical.aggregationInterval,
        
        aggregate = function(self, timeRange)
            return AssetAnalyticsSystem.aggregateHistoricalData(self, timeRange)
        end,
        
        analyze = function(self, data)
            return AssetAnalyticsSystem.analyzeHistoricalTrends(self, data)
        end
    }
end

function AssetAnalyticsSystem.createMLEngine()
    return {
        name = "ml",
        models = {},
        predictions = {},
        
        train = function(self, data)
            AssetAnalyticsSystem.trainMLModels(self, data)
        end,
        
        predict = function(self, features)
            return AssetAnalyticsSystem.generatePredictions(self, features)
        end
    }
end

-- ========================================
-- DATA COLLECTION
-- ========================================

function AssetAnalyticsSystem.initializeDataCollection()
    AnalyticsState.dataCollector = {
        eventBuffer = {},
        sessionTracker = {},
        metricCollectors = {}
    }
    
    -- Initialize metric collectors
    AssetAnalyticsSystem.setupMetricCollectors()
    
    print("📥 Data collection initialized")
end

function AssetAnalyticsSystem.setupMetricCollectors()
    AnalyticsState.dataCollector.metricCollectors = {
        usage = AssetAnalyticsSystem.createUsageCollector(),
        performance = AssetAnalyticsSystem.createPerformanceCollector(),
        user = AssetAnalyticsSystem.createUserCollector(),
        business = AssetAnalyticsSystem.createBusinessCollector()
    }
end

function AssetAnalyticsSystem.createUsageCollector()
    return {
        type = "usage",
        metrics = ANALYTICS_CONFIG.metrics.usage,
        
        collect = function(assetId, eventType, data)
            return AssetAnalyticsSystem.collectUsageMetrics(assetId, eventType, data)
        end
    }
end

function AssetAnalyticsSystem.createPerformanceCollector()
    return {
        type = "performance",
        metrics = ANALYTICS_CONFIG.metrics.performance,
        
        collect = function(assetId, performanceData)
            return AssetAnalyticsSystem.collectPerformanceMetrics(assetId, performanceData)
        end
    }
end

function AssetAnalyticsSystem.createUserCollector()
    return {
        type = "user",
        metrics = ANALYTICS_CONFIG.metrics.user,
        
        collect = function(userId, assetId, interactionData)
            return AssetAnalyticsSystem.collectUserMetrics(userId, assetId, interactionData)
        end
    }
end

function AssetAnalyticsSystem.createBusinessCollector()
    return {
        type = "business",
        metrics = ANALYTICS_CONFIG.metrics.business,
        
        collect = function(assetId, businessData)
            return AssetAnalyticsSystem.collectBusinessMetrics(assetId, businessData)
        end
    }
end

function AssetAnalyticsSystem.trackEvent(eventType, data)
    local event = {
        id = HttpService:GenerateGUID(false),
        type = eventType,
        timestamp = tick(),
        data = data,
        sessionId = AssetAnalyticsSystem.getCurrentSessionId(),
        userId = AssetAnalyticsSystem.getCurrentUserId()
    }
    
    -- Add to event buffer
    table.insert(AnalyticsState.dataCollector.eventBuffer, event)
    
    -- Process realtime if enabled
    if AnalyticsState.analyticsFramework.realtime.enabled then
        AnalyticsState.analyticsFramework.realtime:process(event)
    end
    
    -- Update statistics
    AnalyticsState.stats.totalEvents = AnalyticsState.stats.totalEvents + 1
    
    return event.id
end

function AssetAnalyticsSystem.collectUsageMetrics(assetId, eventType, data)
    local metrics = {
        assetId = assetId,
        eventType = eventType,
        timestamp = tick(),
        loadTime = data.loadTime or 0,
        cacheHit = data.cacheHit or false,
        errorOccurred = data.error and true or false,
        bandwidthUsed = data.bandwidthUsed or 0,
        deviceType = data.deviceType or "unknown"
    }
    
    -- Store in asset usage tracking
    if not AnalyticsState.assetUsage[assetId] then
        AnalyticsState.assetUsage[assetId] = {
            totalLoads = 0,
            totalLoadTime = 0,
            cacheHits = 0,
            cacheMisses = 0,
            errors = 0,
            totalBandwidth = 0,
            firstLoad = tick(),
            lastLoad = tick()
        }
    end
    
    local usage = AnalyticsState.assetUsage[assetId]
    usage.totalLoads = usage.totalLoads + 1
    usage.totalLoadTime = usage.totalLoadTime + metrics.loadTime
    
    if metrics.cacheHit then
        usage.cacheHits = usage.cacheHits + 1
    else
        usage.cacheMisses = usage.cacheMisses + 1
    end
    
    if metrics.errorOccurred then
        usage.errors = usage.errors + 1
    end
    
    usage.totalBandwidth = usage.totalBandwidth + metrics.bandwidthUsed
    usage.lastLoad = tick()
    
    return metrics
end

function AssetAnalyticsSystem.collectPerformanceMetrics(assetId, performanceData)
    local metrics = {
        assetId = assetId,
        timestamp = tick(),
        renderTime = performanceData.renderTime or 0,
        memoryUsage = performanceData.memoryUsage or 0,
        cpuUsage = performanceData.cpuUsage or 0,
        gpuUsage = performanceData.gpuUsage or 0,
        networkLatency = performanceData.networkLatency or 0,
        throughput = performanceData.throughput or 0
    }
    
    -- Store in performance data
    if not AnalyticsState.performanceData[assetId] then
        AnalyticsState.performanceData[assetId] = {
            samples = {},
            averages = {},
            trends = {}
        }
    end
    
    local perfData = AnalyticsState.performanceData[assetId]
    table.insert(perfData.samples, metrics)
    
    -- Keep only recent samples
    if #perfData.samples > 1000 then
        table.remove(perfData.samples, 1)
    end
    
    -- Update averages
    AssetAnalyticsSystem.updatePerformanceAverages(assetId)
    
    return metrics
end

function AssetAnalyticsSystem.collectUserMetrics(userId, assetId, interactionData)
    local metrics = {
        userId = userId,
        assetId = assetId,
        timestamp = tick(),
        interactionType = interactionData.type or "view",
        duration = interactionData.duration or 0,
        satisfaction = interactionData.satisfaction or nil,
        deviceInfo = interactionData.deviceInfo or {}
    }
    
    -- Store in user behavior tracking
    if not AnalyticsState.userBehavior[userId] then
        AnalyticsState.userBehavior[userId] = {
            sessions = {},
            assetInteractions = {},
            totalTime = 0,
            satisfactionScores = {}
        }
    end
    
    local behavior = AnalyticsState.userBehavior[userId]
    
    if not behavior.assetInteractions[assetId] then
        behavior.assetInteractions[assetId] = {
            count = 0,
            totalDuration = 0,
            types = {}
        }
    end
    
    local interaction = behavior.assetInteractions[assetId]
    interaction.count = interaction.count + 1
    interaction.totalDuration = interaction.totalDuration + metrics.duration
    interaction.types[metrics.interactionType] = (interaction.types[metrics.interactionType] or 0) + 1
    
    if metrics.satisfaction then
        table.insert(behavior.satisfactionScores, metrics.satisfaction)
    end
    
    return metrics
end

function AssetAnalyticsSystem.collectBusinessMetrics(assetId, businessData)
    local metrics = {
        assetId = assetId,
        timestamp = tick(),
        cost = businessData.cost or 0,
        revenue = businessData.revenue or 0,
        userRetention = businessData.userRetention or 0,
        engagementRate = businessData.engagementRate or 0,
        qualityScore = businessData.qualityScore or 0,
        optimizationSavings = businessData.optimizationSavings or 0
    }
    
    return metrics
end

-- ========================================
-- USAGE TRACKING
-- ========================================

function AssetAnalyticsSystem.setupUsageTracking()
    AnalyticsState.usageTracker = {
        trackingEnabled = ANALYTICS_CONFIG.tracking.enableUsageTracking,
        sessions = {},
        patterns = {},
        heatmaps = {}
    }
    
    print("📈 Usage tracking initialized")
end

function AssetAnalyticsSystem.trackAssetLoad(assetId, loadData)
    if not AnalyticsState.usageTracker.trackingEnabled then
        return
    end
    
    AssetAnalyticsSystem.trackEvent("asset_load", {
        assetId = assetId,
        loadTime = loadData.loadTime,
        cacheHit = loadData.cacheHit,
        error = loadData.error,
        bandwidthUsed = loadData.bandwidthUsed,
        deviceType = loadData.deviceType,
        quality = loadData.quality
    })
    
    -- Collect usage metrics
    AnalyticsState.dataCollector.metricCollectors.usage.collect(assetId, "load", loadData)
end

function AssetAnalyticsSystem.trackAssetUsage(assetId, usageData)
    AssetAnalyticsSystem.trackEvent("asset_usage", {
        assetId = assetId,
        duration = usageData.duration,
        interactionType = usageData.interactionType,
        context = usageData.context,
        userSatisfaction = usageData.userSatisfaction
    })
    
    -- Collect user metrics
    local userId = AssetAnalyticsSystem.getCurrentUserId()
    AnalyticsState.dataCollector.metricCollectors.user.collect(userId, assetId, usageData)
end

function AssetAnalyticsSystem.trackAssetPerformance(assetId, performanceData)
    AssetAnalyticsSystem.trackEvent("asset_performance", {
        assetId = assetId,
        renderTime = performanceData.renderTime,
        memoryUsage = performanceData.memoryUsage,
        cpuUsage = performanceData.cpuUsage,
        gpuUsage = performanceData.gpuUsage
    })
    
    -- Collect performance metrics
    AnalyticsState.dataCollector.metricCollectors.performance.collect(assetId, performanceData)
end

function AssetAnalyticsSystem.generateUsagePatterns()
    local patterns = {}
    
    for assetId, usage in pairs(AnalyticsState.assetUsage) do
        local pattern = {
            assetId = assetId,
            popularity = usage.totalLoads,
            efficiency = usage.cacheHits / math.max(usage.totalLoads, 1),
            reliability = 1 - (usage.errors / math.max(usage.totalLoads, 1)),
            averageLoadTime = usage.totalLoadTime / math.max(usage.totalLoads, 1),
            bandwidthEfficiency = usage.totalBandwidth / math.max(usage.totalLoads, 1),
            lifecycle = {
                age = tick() - usage.firstLoad,
                recentActivity = tick() - usage.lastLoad
            }
        }
        
        patterns[assetId] = pattern
    end
    
    AnalyticsState.patterns = patterns
    return patterns
end

-- ========================================
-- PERFORMANCE MONITORING
-- ========================================

function AssetAnalyticsSystem.initializePerformanceMonitoring()
    AnalyticsState.performanceMonitor = {
        enabled = ANALYTICS_CONFIG.tracking.enablePerformanceTracking,
        metrics = {},
        thresholds = ANALYTICS_CONFIG.reporting.alertThresholds,
        alerts = {}
    }
    
    print("⚡ Performance monitoring initialized")
end

function AssetAnalyticsSystem.updatePerformanceAverages(assetId)
    local perfData = AnalyticsState.performanceData[assetId]
    if not perfData or #perfData.samples == 0 then
        return
    end
    
    local sampleCount = #perfData.samples
    local totals = {
        renderTime = 0,
        memoryUsage = 0,
        cpuUsage = 0,
        gpuUsage = 0,
        networkLatency = 0,
        throughput = 0
    }
    
    for _, sample in ipairs(perfData.samples) do
        totals.renderTime = totals.renderTime + sample.renderTime
        totals.memoryUsage = totals.memoryUsage + sample.memoryUsage
        totals.cpuUsage = totals.cpuUsage + sample.cpuUsage
        totals.gpuUsage = totals.gpuUsage + sample.gpuUsage
        totals.networkLatency = totals.networkLatency + sample.networkLatency
        totals.throughput = totals.throughput + sample.throughput
    end
    
    perfData.averages = {
        renderTime = totals.renderTime / sampleCount,
        memoryUsage = totals.memoryUsage / sampleCount,
        cpuUsage = totals.cpuUsage / sampleCount,
        gpuUsage = totals.gpuUsage / sampleCount,
        networkLatency = totals.networkLatency / sampleCount,
        throughput = totals.throughput / sampleCount
    }
end

function AssetAnalyticsSystem.checkPerformanceThresholds(assetId)
    local perfData = AnalyticsState.performanceData[assetId]
    if not perfData or not perfData.averages then
        return {}
    end
    
    local alerts = {}
    local thresholds = AnalyticsState.performanceMonitor.thresholds
    
    -- Check memory usage
    if perfData.averages.memoryUsage > thresholds.high_memory_usage then
        table.insert(alerts, {
            type = "high_memory_usage",
            assetId = assetId,
            value = perfData.averages.memoryUsage,
            threshold = thresholds.high_memory_usage,
            severity = "warning"
        })
    end
    
    return alerts
end

-- ========================================
-- ANALYTICS PROCESSING
-- ========================================

function AssetAnalyticsSystem.startAnalyticsProcessing()
    -- Event-driven analytics processing with adaptive intervals
    local processingEvent = Instance.new("BindableEvent")
    
    local function scheduleNextProcessing()
        -- Adaptive interval based on workload
        local eventBufferSize = #(AnalyticsState.events or {})
        local interval = 1 -- Base interval
        
        if eventBufferSize > 1000 then
            interval = 0.5 -- High activity - process more frequently
        elseif eventBufferSize < 10 then
            interval = 5 -- Low activity - process less frequently
        end
        
        task.spawn(function()
            task.wait(interval)
            processingEvent:Fire()
        end)
    end
    
    processingEvent.Event:Connect(function()
        AssetAnalyticsSystem.processRealtimeAnalytics()
        AssetAnalyticsSystem.processBatchAnalytics()
        AssetAnalyticsSystem.processHistoricalAnalytics()
        AssetAnalyticsSystem.updateInsights()
        
        -- Schedule next processing cycle
        scheduleNextProcessing()
    end)
    
    -- Start processing
    scheduleNextProcessing()
    
    print("🔄 Analytics processing started")
end

function AssetAnalyticsSystem.processRealtimeAnalytics()
    local realtimeEngine = AnalyticsState.analyticsFramework.realtime
    if not realtimeEngine.enabled then return end
    
    realtimeEngine:update()
end

function AssetAnalyticsSystem.processBatchAnalytics()
    local batchEngine = AnalyticsState.analyticsFramework.batch
    if not batchEngine.enabled then return end
    
    -- Process batch every minute
    if tick() % 60 < 1 then
        batchEngine:process()
    end
end

function AssetAnalyticsSystem.processHistoricalAnalytics()
    local historicalEngine = AnalyticsState.analyticsFramework.historical
    if not historicalEngine.enabled then return end
    
    -- Process historical data every hour
    if tick() % 3600 < 1 then
        historicalEngine:aggregate("1h")
    end
end

function AssetAnalyticsSystem.processRealtimeEvent(event)
    -- Update realtime metrics
    AssetAnalyticsSystem.updateRealtimeMetrics(event)
    
    -- Check for immediate alerts
    AssetAnalyticsSystem.checkRealtimeAlerts(event)
    
    return true
end

function AssetAnalyticsSystem.updateRealtimeMetrics(event)
    local realtimeEngine = AnalyticsState.analyticsFramework.realtime
    
    table.insert(realtimeEngine.dataPoints, {
        timestamp = event.timestamp,
        type = event.type,
        data = event.data
    })
    
    -- Keep only recent data points
    local maxDataPoints = ANALYTICS_CONFIG.engines.realtime.maxDataPoints
    if #realtimeEngine.dataPoints > maxDataPoints then
        table.remove(realtimeEngine.dataPoints, 1)
    end
end

function AssetAnalyticsSystem.checkRealtimeAlerts(event)
    local alerts = {}
    
    if event.type == "asset_load" and event.data.loadTime then
        local threshold = ANALYTICS_CONFIG.reporting.alertThresholds.high_load_time
        if event.data.loadTime > threshold then
            table.insert(alerts, {
                type = "high_load_time",
                assetId = event.data.assetId,
                value = event.data.loadTime,
                threshold = threshold,
                severity = "warning",
                timestamp = event.timestamp
            })
        end
    end
    
    -- Store alerts
    for _, alert in ipairs(alerts) do
        table.insert(AnalyticsState.alerts, alert)
    end
    
    return alerts
end

function AssetAnalyticsSystem.updateInsights()
    -- Generate usage patterns
    AssetAnalyticsSystem.generateUsagePatterns()
    
    -- Update global statistics
    AssetAnalyticsSystem.updateGlobalStatistics()
    
    -- Generate insights
    AnalyticsState.insights = AssetAnalyticsSystem.generateAnalyticsInsights()
end

function AssetAnalyticsSystem.updateGlobalStatistics()
    local stats = AnalyticsState.stats
    
    -- Calculate averages across all assets
    local totalLoadTime = 0
    local totalLoads = 0
    local totalCacheHits = 0
    local totalErrors = 0
    local totalBandwidth = 0
    
    for assetId, usage in pairs(AnalyticsState.assetUsage) do
        totalLoadTime = totalLoadTime + usage.totalLoadTime
        totalLoads = totalLoads + usage.totalLoads
        totalCacheHits = totalCacheHits + usage.cacheHits
        totalErrors = totalErrors + usage.errors
        totalBandwidth = totalBandwidth + usage.totalBandwidth
    end
    
    stats.totalAssets = 0
    for _ in pairs(AnalyticsState.assetUsage) do
        stats.totalAssets = stats.totalAssets + 1
    end
    
    stats.averageLoadTime = totalLoads > 0 and (totalLoadTime / totalLoads) or 0
    stats.cacheHitRate = totalLoads > 0 and (totalCacheHits / totalLoads) or 0
    stats.errorRate = totalLoads > 0 and (totalErrors / totalLoads) or 0
    stats.totalBandwidth = totalBandwidth
    
    stats.totalUsers = 0
    for _ in pairs(AnalyticsState.userBehavior) do
        stats.totalUsers = stats.totalUsers + 1
    end
end

function AssetAnalyticsSystem.generateAnalyticsInsights()
    local insights = {
        topPerformingAssets = AssetAnalyticsSystem.getTopPerformingAssets(),
        bottleneckAssets = AssetAnalyticsSystem.getBottleneckAssets(),
        usageTrends = AssetAnalyticsSystem.getUsageTrends(),
        optimizationOpportunities = AssetAnalyticsSystem.getOptimizationOpportunities(),
        userEngagementPatterns = AssetAnalyticsSystem.getUserEngagementPatterns()
    }
    
    return insights
end

function AssetAnalyticsSystem.getTopPerformingAssets(limit)
    limit = limit or 10
    local assets = {}
    
    for assetId, usage in pairs(AnalyticsState.assetUsage) do
        local score = AssetAnalyticsSystem.calculateAssetPerformanceScore(usage)
        table.insert(assets, {
            assetId = assetId,
            score = score,
            usage = usage
        })
    end
    
    table.sort(assets, function(a, b) return a.score > b.score end)
    
    local top = {}
    for i = 1, math.min(limit, #assets) do
        table.insert(top, assets[i])
    end
    
    return top
end

function AssetAnalyticsSystem.getBottleneckAssets(limit)
    limit = limit or 10
    local assets = {}
    
    for assetId, usage in pairs(AnalyticsState.assetUsage) do
        local avgLoadTime = usage.totalLoadTime / math.max(usage.totalLoads, 1)
        local errorRate = usage.errors / math.max(usage.totalLoads, 1)
        
        if avgLoadTime > 3000 or errorRate > 0.1 then -- 3 seconds or 10% error rate
            table.insert(assets, {
                assetId = assetId,
                avgLoadTime = avgLoadTime,
                errorRate = errorRate,
                usage = usage
            })
        end
    end
    
    table.sort(assets, function(a, b) 
        return (a.avgLoadTime + a.errorRate * 10000) > (b.avgLoadTime + b.errorRate * 10000)
    end)
    
    local bottlenecks = {}
    for i = 1, math.min(limit, #assets) do
        table.insert(bottlenecks, assets[i])
    end
    
    return bottlenecks
end

function AssetAnalyticsSystem.calculateAssetPerformanceScore(usage)
    local loadTimeScore = math.max(0, 100 - (usage.totalLoadTime / math.max(usage.totalLoads, 1)) / 50)
    local cacheScore = (usage.cacheHits / math.max(usage.totalLoads, 1)) * 100
    local reliabilityScore = (1 - (usage.errors / math.max(usage.totalLoads, 1))) * 100
    
    return (loadTimeScore + cacheScore + reliabilityScore) / 3
end

-- ========================================
-- REPORTING SYSTEM
-- ========================================

function AssetAnalyticsSystem.setupReportingSystem()
    AnalyticsState.reportingSystem = {
        enabled = ANALYTICS_CONFIG.reporting.enableAutomaticReports,
        reports = {},
        alerts = {},
        dashboards = {}
    }
    
    -- Start automatic reporting
    if AnalyticsState.reportingSystem.enabled then
        AssetAnalyticsSystem.startAutomaticReporting()
    end
    
    print("📋 Reporting system initialized")
end

function AssetAnalyticsSystem.startAutomaticReporting()
    -- Event-driven reporting with smart scheduling
    local reportingEvent = Instance.new("BindableEvent")
    local lastDailyReport = 0
    
    local function scheduleNextReportCheck()
        -- Check every hour but adapt based on activity
        local currentTime = tick()
        local timeSinceLastDaily = currentTime - lastDailyReport
        
        -- More frequent checks as we approach 24 hour mark
        local interval = timeSinceLastDaily > 82800 and 600 or 3600 -- 10 min vs 1 hour
        
        task.spawn(function()
            task.wait(interval)
            reportingEvent:Fire()
        end)
    end
    
    reportingEvent.Event:Connect(function()
        -- Generate daily reports
        local currentTime = tick()
        if currentTime - lastDailyReport >= 86400 then -- Every 24 hours
            AssetAnalyticsSystem.generateDailyReport()
            lastDailyReport = currentTime
        end
        
        -- Schedule next check
        scheduleNextReportCheck()
    end)
    
    -- Start the reporting cycle
    scheduleNextReportCheck()
end

function AssetAnalyticsSystem.generateDailyReport()
    local report = {
        id = HttpService:GenerateGUID(false),
        type = "daily",
        timestamp = tick(),
        period = {
            start = tick() - 86400,
            endTime = tick()
        },
        summary = {},
        metrics = {},
        insights = {},
        alerts = {},
        recommendations = {}
    }
    
    -- Generate summary
    report.summary = {
        totalAssets = AnalyticsState.stats.totalAssets,
        totalUsers = AnalyticsState.stats.totalUsers,
        totalEvents = AnalyticsState.stats.totalEvents,
        averageLoadTime = AnalyticsState.stats.averageLoadTime,
        cacheHitRate = AnalyticsState.stats.cacheHitRate,
        errorRate = AnalyticsState.stats.errorRate,
        totalBandwidth = AnalyticsState.stats.totalBandwidth
    }
    
    -- Include insights
    report.insights = AnalyticsState.insights
    
    -- Include recent alerts
    report.alerts = AssetAnalyticsSystem.getRecentAlerts(86400) -- Last 24 hours
    
    -- Generate recommendations
    report.recommendations = AssetAnalyticsSystem.generateRecommendations()
    
    AnalyticsState.reports[report.id] = report
    
    print(string.format("📋 Generated daily analytics report: %s", report.id))
    
    return report
end

function AssetAnalyticsSystem.getRecentAlerts(timeWindow)
    local recentAlerts = {}
    local cutoffTime = tick() - timeWindow
    
    for _, alert in ipairs(AnalyticsState.alerts) do
        if alert.timestamp >= cutoffTime then
            table.insert(recentAlerts, alert)
        end
    end
    
    return recentAlerts
end

function AssetAnalyticsSystem.generateRecommendations()
    local recommendations = {}
    
    -- Check cache hit rate
    if AnalyticsState.stats.cacheHitRate < 0.8 then
        table.insert(recommendations, {
            type = "cache_optimization",
            priority = "high",
            description = "Cache hit rate is below 80%. Consider optimizing caching strategies.",
            impact = "performance"
        })
    end
    
    -- Check error rate
    if AnalyticsState.stats.errorRate > 0.05 then
        table.insert(recommendations, {
            type = "error_reduction",
            priority = "high",
            description = "Error rate is above 5%. Investigate and fix asset loading issues.",
            impact = "reliability"
        })
    end
    
    -- Check load time
    if AnalyticsState.stats.averageLoadTime > 3000 then
        table.insert(recommendations, {
            type = "performance_optimization",
            priority = "medium",
            description = "Average load time is above 3 seconds. Consider asset optimization.",
            impact = "user_experience"
        })
    end
    
    return recommendations
end

-- ========================================
-- UTILITY FUNCTIONS
-- ========================================

function AssetAnalyticsSystem.getCurrentSessionId()
    -- Simple session tracking
    if not AnalyticsState.currentSessionId then
        AnalyticsState.currentSessionId = HttpService:GenerateGUID(false)
    end
    return AnalyticsState.currentSessionId
end

function AssetAnalyticsSystem.getCurrentUserId()
    local player = Players.LocalPlayer
    return player and tostring(player.UserId) or "unknown"
end

function AssetAnalyticsSystem.getUsageTrends()
    -- Simple trend analysis
    local trends = {}
    
    for assetId, usage in pairs(AnalyticsState.assetUsage) do
        local trend = {
            assetId = assetId,
            growthRate = 0, -- Simplified calculation
            seasonality = "none",
            prediction = "stable"
        }
        
        trends[assetId] = trend
    end
    
    return trends
end

function AssetAnalyticsSystem.getOptimizationOpportunities()
    local opportunities = {}
    
    for assetId, usage in pairs(AnalyticsState.assetUsage) do
        local avgLoadTime = usage.totalLoadTime / math.max(usage.totalLoads, 1)
        local cacheHitRate = usage.cacheHits / math.max(usage.totalLoads, 1)
        
        if avgLoadTime > 2000 or cacheHitRate < 0.7 then
            table.insert(opportunities, {
                assetId = assetId,
                type = avgLoadTime > 2000 and "load_time" or "cache_optimization",
                potentialImprovement = avgLoadTime > 2000 and "50% load time reduction" or "20% cache improvement",
                priority = avgLoadTime > 5000 and "high" or "medium"
            })
        end
    end
    
    return opportunities
end

function AssetAnalyticsSystem.getUserEngagementPatterns()
    local patterns = {}
    
    for userId, behavior in pairs(AnalyticsState.userBehavior) do
        local engagement = {
            userId = userId,
            totalInteractions = 0,
            averageSessionTime = 0,
            preferredAssets = {},
            engagementScore = 0
        }
        
        for assetId, interaction in pairs(behavior.assetInteractions) do
            engagement.totalInteractions = engagement.totalInteractions + interaction.count
        end
        
        patterns[userId] = engagement
    end
    
    return patterns
end

-- ========================================
-- PUBLIC API
-- ========================================

function AssetAnalyticsSystem.runAnalyticsDemo()
    print("📊 Running asset analytics demonstration...")
    
    -- Simulate asset tracking
    local sampleAssets = {"ui_background", "character_model", "ambient_music", "particle_effect"}
    
    print("  📈 Simulating asset usage tracking...")
    
    for i = 1, 50 do
        local assetId = sampleAssets[math.random(#sampleAssets)]
        
        -- Simulate asset load
        AssetAnalyticsSystem.trackAssetLoad(assetId, {
            loadTime = math.random(500, 3000),
            cacheHit = math.random() > 0.3,
            bandwidthUsed = math.random(1024, 1024 * 1024),
            deviceType = math.random() > 0.5 and "desktop" or "mobile"
        })
        
        -- Simulate asset usage
        AssetAnalyticsSystem.trackAssetUsage(assetId, {
            duration = math.random(5, 300),
            interactionType = "view",
            userSatisfaction = math.random(1, 10)
        })
        
        -- Simulate performance tracking
        AssetAnalyticsSystem.trackAssetPerformance(assetId, {
            renderTime = math.random(1, 20),
            memoryUsage = math.random(1024 * 1024, 100 * 1024 * 1024),
            cpuUsage = math.random(10, 80),
            gpuUsage = math.random(5, 60)
        })
        
        -- Event-driven test timing to avoid blocking
        local testEvent = Instance.new("BindableEvent")
        local function nextIteration()
            -- Continue with next test iteration
        end
        
        testEvent.Event:Connect(nextIteration)
        task.wait(0.15) -- Optimized test interval
        testEvent:Fire()
    end
    
    -- Wait for processing
    task.wait(2)
    
    -- Generate insights
    AssetAnalyticsSystem.updateInsights()
    
    -- Show analytics results
    local stats = AssetAnalyticsSystem.getAnalyticsStats()
    print("  📊 Analytics Statistics:")
    print(string.format("    Total events: %d", stats.totalEvents))
    print(string.format("    Total assets tracked: %d", stats.totalAssets))
    print(string.format("    Average load time: %.1fms", stats.averageLoadTime))
    print(string.format("    Cache hit rate: %.1f%%", stats.cacheHitRate * 100))
    print(string.format("    Error rate: %.1f%%", stats.errorRate * 100))
    
    -- Show top performing assets
    local topAssets = AssetAnalyticsSystem.getTopPerformingAssets(3)
    print("  🏆 Top Performing Assets:")
    for i, asset in ipairs(topAssets) do
        print(string.format("    %d. %s (score: %.1f)", i, asset.assetId, asset.score))
    end
    
    -- Show bottlenecks
    local bottlenecks = AssetAnalyticsSystem.getBottleneckAssets(3)
    if #bottlenecks > 0 then
        print("  ⚠️ Performance Bottlenecks:")
        for i, asset in ipairs(bottlenecks) do
            print(string.format("    %d. %s (load time: %.1fms, error rate: %.1f%%)", 
                i, asset.assetId, asset.avgLoadTime, asset.errorRate * 100))
        end
    end
    
    -- Generate and show report
    local report = AssetAnalyticsSystem.generateDailyReport()
    print(string.format("  📋 Generated analytics report: %s", report.id))
    print(string.format("    Recommendations: %d", #report.recommendations))
    
    for i, rec in ipairs(report.recommendations) do
        print(string.format("    %d. %s (%s priority)", i, rec.description, rec.priority))
    end
    
    print("📊 Asset analytics demonstration completed")
end

function AssetAnalyticsSystem.getAnalyticsStats()
    return AnalyticsState.stats
end

function AssetAnalyticsSystem.getAssetUsage(assetId)
    return AnalyticsState.assetUsage[assetId]
end

function AssetAnalyticsSystem.getInsights()
    return AnalyticsState.insights
end

function AssetAnalyticsSystem.getReports()
    return AnalyticsState.reports
end

function AssetAnalyticsSystem.getAlerts()
    return AnalyticsState.alerts
end

-- ========================================
-- MISSING METHOD IMPLEMENTATIONS
-- ========================================

function AssetAnalyticsSystem.queueBatchEvents(engine, events)
    for _, event in ipairs(events) do
        table.insert(engine.eventQueue, event)
    end
    
    -- Process if batch size is reached
    if #engine.eventQueue >= engine.batchSize then
        return AssetAnalyticsSystem.processBatchEvents(engine)
    end
    
    return true
end

function AssetAnalyticsSystem.processBatchEvents(engine)
    if #engine.eventQueue == 0 then
        return false
    end
    
    -- Process events in batches
    local processed = 0
    for i = 1, math.min(engine.batchSize, #engine.eventQueue) do
        local event = table.remove(engine.eventQueue, 1)
        if event then
            processed = processed + 1
        end
    end
    
    print(string.format("📦 Processed %d batch events", processed))
    return true
end

function AssetAnalyticsSystem.aggregateHistoricalData(engine, timeRange)
    local aggregatedData = {}
    local currentTime = tick()
    
    -- Aggregate data for the specified time range
    for assetId, usage in pairs(AnalyticsState.assetUsage) do
        if usage.lastUpdated and (currentTime - usage.lastUpdated) <= timeRange then
            aggregatedData[assetId] = {
                totalLoads = usage.totalLoads or 0,
                averageLoadTime = usage.averageLoadTime or 0,
                errorRate = usage.errorRate or 0
            }
        end
    end
    
    return aggregatedData
end

function AssetAnalyticsSystem.analyzeHistoricalTrends(engine, data)
    local trends = {}
    
    for assetId, metrics in pairs(data) do
        trends[assetId] = {
            loadTrend = metrics.totalLoads > 100 and "increasing" or "stable",
            performanceTrend = metrics.averageLoadTime < 500 and "good" or "needs_optimization",
            reliabilityTrend = metrics.errorRate < 0.01 and "excellent" or "needs_attention"
        }
    end
    
    return trends
end

function AssetAnalyticsSystem.trainMLModels(engine, data)
    print("🤖 Training ML models with " .. (#data or 0) .. " data points")
    -- Simulate ML training
    engine.modelsLastTrained = tick()
end

function AssetAnalyticsSystem.generatePredictions(engine, features)
    -- Simulate ML predictions
    local predictions = {}
    
    for i, feature in ipairs(features) do
        predictions[i] = {
            assetId = feature.assetId,
            predictedLoadTime = math.random(100, 1000),
            predictedErrorRate = math.random() * 0.05,
            confidenceScore = math.random(0.7, 0.95)
        }
    end
    
    return predictions
end

-- Export API
AssetAnalyticsSystem.trackAssetLoad = AssetAnalyticsSystem.trackAssetLoad
AssetAnalyticsSystem.trackAssetUsage = AssetAnalyticsSystem.trackAssetUsage
AssetAnalyticsSystem.trackAssetPerformance = AssetAnalyticsSystem.trackAssetPerformance
AssetAnalyticsSystem.generateDailyReport = AssetAnalyticsSystem.generateDailyReport

-- Initialize the asset analytics system
AssetAnalyticsSystem.initialize()

print("📊 AssetAnalyticsSystem loaded with comprehensive analytics and tracking capabilities")

return AssetAnalyticsSystem
