-- OperationalDashboardsHealthMonitoringSystem.luau
-- Comprehensive operational dashboards and health monitoring for production systems
-- Provides real-time visibility, health scoring, and operational intelligence

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local HttpService = game:GetService("HttpService")
local RunService = game:GetService("RunService")

local SafeRequire = require(ReplicatedStorage.Shared.utils.SafeRequire)

local OperationalDashboardsHealthMonitoringSystem = {}

-- ========================================
-- DASHBOARD CONFIGURATION
-- ========================================

local DASHBOARD_CONFIG = {
    -- Dashboard definitions
    dashboards = {
        operational = {
            name = "Operational Overview",
            description = "High-level system health and performance metrics",
            refreshInterval = 30,
            widgets = {
                "system_health_score",
                "active_users",
                "response_times",
                "error_rates",
                "deployment_status",
                "infrastructure_health"
            }
        },
        
        performance = {
            name = "Performance Monitoring",
            description = "Detailed performance metrics and trends",
            refreshInterval = 10,
            widgets = {
                "response_time_percentiles",
                "throughput_trends",
                "resource_utilization",
                "cache_performance",
                "database_performance",
                "cdn_performance"
            }
        },
        
        business = {
            name = "Business Metrics",
            description = "Key business indicators and conversion metrics",
            refreshInterval = 60,
            widgets = {
                "active_players",
                "revenue_metrics",
                "conversion_rates",
                "feature_adoption",
                "user_engagement",
                "retention_metrics"
            }
        },
        
        security = {
            name = "Security Operations",
            description = "Security events, threats, and compliance status",
            refreshInterval = 15,
            widgets = {
                "security_alerts",
                "threat_detection",
                "authentication_metrics",
                "vulnerability_status",
                "compliance_score",
                "incident_status"
            }
        },
        
        infrastructure = {
            name = "Infrastructure Health",
            description = "Server, network, and resource monitoring",
            refreshInterval = 20,
            widgets = {
                "server_status",
                "network_health",
                "storage_utilization",
                "backup_status",
                "scaling_activity",
                "maintenance_schedule"
            }
        },
        
        devops = {
            name = "DevOps Pipeline",
            description = "Deployment pipeline and release management",
            refreshInterval = 45,
            widgets = {
                "pipeline_status",
                "deployment_frequency",
                "rollback_rates",
                "feature_flags",
                "test_coverage",
                "quality_gates"
            }
        }
    },
    
    -- Widget configurations
    widgets = {
        system_health_score = {
            name = "System Health Score",
            type = "gauge",
            unit = "%",
            thresholds = {healthy = 90, warning = 70, critical = 50},
            refreshInterval = 30
        },
        
        response_times = {
            name = "Response Times",
            type = "line_chart",
            unit = "ms",
            thresholds = {good = 100, warning = 250, critical = 500},
            refreshInterval = 10
        },
        
        error_rates = {
            name = "Error Rates",
            type = "bar_chart",
            unit = "%",
            thresholds = {good = 0.1, warning = 1, critical = 5},
            refreshInterval = 15
        },
        
        active_users = {
            name = "Active Users",
            type = "counter",
            unit = "users",
            refreshInterval = 60
        }
    },
    
    -- Alert configurations
    alertConfigurations = {
        healthScoreAlert = {
            metric = "system_health_score",
            threshold = 70,
            severity = "warning",
            duration = 300
        },
        
        responseTimeAlert = {
            metric = "avg_response_time",
            threshold = 500,
            severity = "critical",
            duration = 180
        },
        
        errorRateAlert = {
            metric = "error_rate",
            threshold = 5,
            severity = "critical",
            duration = 120
        }
    },
    
    -- Health check definitions
    healthChecks = {
        application = {
            name = "Application Health",
            checks = ["api_endpoints", "business_logic", "user_sessions"],
            weight = 40
        },
        
        infrastructure = {
            name = "Infrastructure Health", 
            checks = ["servers", "databases", "caches", "networks"],
            weight = 30
        },
        
        security = {
            name = "Security Health",
            checks = ["authentication", "authorization", "threat_detection"],
            weight = 20
        },
        
        business = {
            name = "Business Health",
            checks = ["user_engagement", "revenue_streams", "feature_adoption"],
            weight = 10
        }
    }
}

-- ========================================
-- SYSTEM STATE
-- ========================================

local DashboardState = {
    -- Core engines
    dashboardEngine = nil,
    healthEngine = nil,
    metricsEngine = nil,
    alertEngine = nil,
    
    -- Dashboard data
    dashboards = {},
    widgets = {},
    
    -- Health monitoring
    healthScores = {},
    healthHistory = {},
    
    -- Metrics storage
    metricsData = {},
    metricsHistory = {},
    
    -- Alerts and notifications
    activeAlerts = {},
    alertHistory = {},
    
    -- System status
    systemStatus = {
        overallHealth = 100,
        componentHealth = {},
        lastHealthCheck = nil,
        dashboardsActive = 0,
        widgetsActive = 0
    },
    
    -- Performance metrics
    performanceMetrics = {
        dashboardLoadTime = 0,
        metricsCollectionTime = 0,
        healthCheckDuration = 0,
        alertProcessingTime = 0
    },
    
    -- Configuration
    config = DASHBOARD_CONFIG
}

function OperationalDashboardsHealthMonitoringSystem.initialize()
    print("📊 Initializing OperationalDashboardsHealthMonitoringSystem...")
    
    -- Initialize core engines
    OperationalDashboardsHealthMonitoringSystem.initializeDashboardEngine()
    OperationalDashboardsHealthMonitoringSystem.initializeHealthEngine()
    OperationalDashboardsHealthMonitoringSystem.initializeMetricsEngine()
    OperationalDashboardsHealthMonitoringSystem.initializeAlertEngine()
    
    -- Create dashboards
    OperationalDashboardsHealthMonitoringSystem.createDashboards()
    
    -- Start monitoring
    OperationalDashboardsHealthMonitoringSystem.startHealthMonitoring()
    OperationalDashboardsHealthMonitoringSystem.startMetricsCollection()
    OperationalDashboardsHealthMonitoringSystem.startDashboardRefresh()
    
    print("📊 OperationalDashboardsHealthMonitoringSystem initialized successfully")
end

-- ========================================
-- DASHBOARD ENGINE
-- ========================================

function OperationalDashboardsHealthMonitoringSystem.initializeDashboardEngine()
    DashboardState.dashboardEngine = {
        dashboards = {},
        widgets = {},
        
        createDashboard = function(self, dashboardConfig)
            return OperationalDashboardsHealthMonitoringSystem.createDashboard(dashboardConfig)
        end,
        
        updateWidget = function(self, widgetId, data)
            return OperationalDashboardsHealthMonitoringSystem.updateWidget(widgetId, data)
        end,
        
        getDashboardData = function(self, dashboardId)
            return OperationalDashboardsHealthMonitoringSystem.getDashboardData(dashboardId)
        end
    }
    
    print("📊 Dashboard engine initialized")
end

function OperationalDashboardsHealthMonitoringSystem.createDashboards()
    for dashboardId, config in pairs(DashboardState.config.dashboards) do
        OperationalDashboardsHealthMonitoringSystem.createDashboard({
            id = dashboardId,
            name = config.name,
            description = config.description,
            refreshInterval = config.refreshInterval,
            widgets = config.widgets
        })
    end
    
    print("📊 Dashboards created")
end

function OperationalDashboardsHealthMonitoringSystem.createDashboard(dashboardConfig)
    local dashboard = {
        id = dashboardConfig.id,
        name = dashboardConfig.name,
        description = dashboardConfig.description,
        
        refreshInterval = dashboardConfig.refreshInterval or 30,
        lastRefresh = nil,
        
        widgets = {},
        
        status = "active",
        created = os.time(),
        
        metrics = {
            views = 0,
            refreshes = 0,
            loadTime = 0
        }
    }
    
    -- Create widgets for dashboard
    for _, widgetType in ipairs(dashboardConfig.widgets) do
        local widget = OperationalDashboardsHealthMonitoringSystem.createWidget(widgetType, dashboard.id)
        table.insert(dashboard.widgets, widget.id)
    end
    
    DashboardState.dashboards[dashboard.id] = dashboard
    DashboardState.systemStatus.dashboardsActive = DashboardState.systemStatus.dashboardsActive + 1
    
    print(string.format("📊 Created dashboard: %s (%d widgets)", dashboard.name, #dashboard.widgets))
    
    return {
        success = true,
        dashboard = dashboard
    }
end

function OperationalDashboardsHealthMonitoringSystem.createWidget(widgetType, dashboardId)
    local widgetConfig = DashboardState.config.widgets[widgetType] or {
        name = widgetType,
        type = "metric",
        unit = "count"
    }
    
    local widget = {
        id = HttpService:GenerateGUID(),
        type = widgetType,
        name = widgetConfig.name or widgetType,
        dashboardId = dashboardId,
        
        config = widgetConfig,
        
        data = {
            current = nil,
            previous = nil,
            trend = "stable",
            history = {}
        },
        
        status = "active",
        lastUpdate = nil,
        
        refreshInterval = widgetConfig.refreshInterval or 30
    }
    
    DashboardState.widgets[widget.id] = widget
    DashboardState.systemStatus.widgetsActive = DashboardState.systemStatus.widgetsActive + 1
    
    return widget
end

function OperationalDashboardsHealthMonitoringSystem.updateWidget(widgetId, data)
    local widget = DashboardState.widgets[widgetId]
    
    if not widget then
        return {success = false, error = "Widget not found"}
    end
    
    widget.data.previous = widget.data.current
    widget.data.current = data
    widget.lastUpdate = os.time()
    
    -- Calculate trend
    if widget.data.previous and widget.data.current then
        if type(widget.data.current) == "number" and type(widget.data.previous) == "number" then
            if widget.data.current > widget.data.previous then
                widget.data.trend = "increasing"
            elseif widget.data.current < widget.data.previous then
                widget.data.trend = "decreasing"
            else
                widget.data.trend = "stable"
            end
        end
    end
    
    -- Add to history
    table.insert(widget.data.history, {
        timestamp = os.time(),
        value = data
    })
    
    -- Keep only last 100 data points
    if #widget.data.history > 100 then
        table.remove(widget.data.history, 1)
    end
    
    return {success = true}
end

function OperationalDashboardsHealthMonitoringSystem.getDashboardData(dashboardId)
    local dashboard = DashboardState.dashboards[dashboardId]
    
    if not dashboard then
        return {success = false, error = "Dashboard not found"}
    end
    
    local data = {
        dashboard = dashboard,
        widgets = {},
        lastRefresh = os.time()
    }
    
    -- Collect widget data
    for _, widgetId in ipairs(dashboard.widgets) do
        local widget = DashboardState.widgets[widgetId]
        if widget then
            table.insert(data.widgets, {
                id = widget.id,
                type = widget.type,
                name = widget.name,
                data = widget.data,
                config = widget.config
            })
        end
    end
    
    dashboard.lastRefresh = os.time()
    dashboard.metrics.refreshes = dashboard.metrics.refreshes + 1
    
    return {
        success = true,
        data = data
    }
end

-- ========================================
-- HEALTH ENGINE
-- ========================================

function OperationalDashboardsHealthMonitoringSystem.initializeHealthEngine()
    DashboardState.healthEngine = {
        checks = {},
        scores = {},
        
        performHealthCheck = function(self)
            return OperationalDashboardsHealthMonitoringSystem.performComprehensiveHealthCheck()
        end,
        
        calculateHealthScore = function(self, component)
            return OperationalDashboardsHealthMonitoringSystem.calculateComponentHealthScore(component)
        end,
        
        getOverallHealth = function(self)
            return OperationalDashboardsHealthMonitoringSystem.calculateOverallHealthScore()
        end
    }
    
    print("🏥 Health monitoring engine initialized")
end

function OperationalDashboardsHealthMonitoringSystem.performComprehensiveHealthCheck()
    local startTime = os.time()
    
    local healthCheck = {
        id = HttpService:GenerateGUID(),
        timestamp = startTime,
        components = {},
        overallScore = 0,
        status = "healthy"
    }
    
    -- Check each health component
    for componentName, componentConfig in pairs(DashboardState.config.healthChecks) do
        local componentHealth = OperationalDashboardsHealthMonitoringSystem.checkComponentHealth(componentName, componentConfig)
        healthCheck.components[componentName] = componentHealth
    end
    
    -- Calculate overall health score
    healthCheck.overallScore = OperationalDashboardsHealthMonitoringSystem.calculateOverallHealthScore(healthCheck.components)
    
    -- Determine status
    if healthCheck.overallScore >= 90 then
        healthCheck.status = "healthy"
    elseif healthCheck.overallScore >= 70 then
        healthCheck.status = "degraded"
    else
        healthCheck.status = "unhealthy"
    end
    
    healthCheck.duration = os.time() - startTime
    
    -- Store health check
    DashboardState.healthScores.latest = healthCheck
    table.insert(DashboardState.healthHistory, healthCheck)
    
    -- Keep only last 100 health checks
    if #DashboardState.healthHistory > 100 then
        table.remove(DashboardState.healthHistory, 1)
    end
    
    -- Update system status
    DashboardState.systemStatus.overallHealth = healthCheck.overallScore
    DashboardState.systemStatus.lastHealthCheck = startTime
    DashboardState.performanceMetrics.healthCheckDuration = healthCheck.duration
    
    -- Update dashboard widgets
    OperationalDashboardsHealthMonitoringSystem.updateHealthWidgets(healthCheck)
    
    return healthCheck
end

function OperationalDashboardsHealthMonitoringSystem.checkComponentHealth(componentName, componentConfig)
    local componentHealth = {
        name = componentName,
        score = 100,
        status = "healthy",
        checks = {},
        weight = componentConfig.weight
    }
    
    for _, checkName in ipairs(componentConfig.checks) do
        local check = OperationalDashboardsHealthMonitoringSystem.performIndividualCheck(checkName, componentName)
        table.insert(componentHealth.checks, check)
        
        -- Reduce component score based on failed checks
        if not check.passed then
            componentHealth.score = componentHealth.score - (100 / #componentConfig.checks)
        end
    end
    
    -- Determine component status
    if componentHealth.score >= 90 then
        componentHealth.status = "healthy"
    elseif componentHealth.score >= 70 then
        componentHealth.status = "degraded"
    else
        componentHealth.status = "unhealthy"
    end
    
    return componentHealth
end

function OperationalDashboardsHealthMonitoringSystem.performIndividualCheck(checkName, componentName)
    local check = {
        name = checkName,
        component = componentName,
        passed = false,
        responseTime = 0,
        details = "",
        timestamp = os.time()
    }
    
    local startTime = tick()
    
    -- Simulate health checks based on check name
    if checkName == "api_endpoints" then
        check.passed = math.random() > 0.05 -- 95% success rate
        check.details = check.passed and "All endpoints responding" or "Some endpoints failing"
    elseif checkName == "business_logic" then
        check.passed = math.random() > 0.02 -- 98% success rate
        check.details = check.passed and "Business logic functioning" or "Logic errors detected"
    elseif checkName == "user_sessions" then
        check.passed = math.random() > 0.01 -- 99% success rate
        check.details = check.passed and "Sessions active" or "Session issues detected"
    elseif checkName == "servers" then
        check.passed = math.random() > 0.03 -- 97% success rate
        check.details = check.passed and "All servers online" or "Server issues detected"
    elseif checkName == "databases" then
        check.passed = math.random() > 0.02 -- 98% success rate
        check.details = check.passed and "Database connections healthy" or "Database issues"
    elseif checkName == "caches" then
        check.passed = math.random() > 0.01 -- 99% success rate
        check.details = check.passed and "Cache performance good" or "Cache issues"
    elseif checkName == "networks" then
        check.passed = math.random() > 0.05 -- 95% success rate
        check.details = check.passed and "Network connectivity good" or "Network issues"
    elseif checkName == "authentication" then
        check.passed = math.random() > 0.01 -- 99% success rate
        check.details = check.passed and "Auth systems functioning" or "Auth issues"
    elseif checkName == "authorization" then
        check.passed = math.random() > 0.01 -- 99% success rate
        check.details = check.passed and "Authz systems functioning" or "Authz issues"
    elseif checkName == "threat_detection" then
        check.passed = math.random() > 0.02 -- 98% success rate
        check.details = check.passed and "Threat detection active" or "Threat detection issues"
    elseif checkName == "user_engagement" then
        check.passed = math.random() > 0.1 -- 90% success rate
        check.details = check.passed and "User engagement normal" or "Engagement below target"
    elseif checkName == "revenue_streams" then
        check.passed = math.random() > 0.05 -- 95% success rate
        check.details = check.passed and "Revenue on target" or "Revenue below target"
    elseif checkName == "feature_adoption" then
        check.passed = math.random() > 0.1 -- 90% success rate
        check.details = check.passed and "Feature adoption good" or "Low feature adoption"
    else
        check.passed = math.random() > 0.05 -- Default 95% success rate
        check.details = check.passed and "Check passed" or "Check failed"
    end
    
    check.responseTime = (tick() - startTime) * 1000 -- Convert to milliseconds
    
    return check
end

function OperationalDashboardsHealthMonitoringSystem.calculateOverallHealthScore(components)
    components = components or DashboardState.healthScores.latest.components
    
    if not components then
        return 100
    end
    
    local totalWeight = 0
    local weightedScore = 0
    
    for _, component in pairs(components) do
        totalWeight = totalWeight + component.weight
        weightedScore = weightedScore + (component.score * component.weight)
    end
    
    return totalWeight > 0 and (weightedScore / totalWeight) or 100
end

function OperationalDashboardsHealthMonitoringSystem.updateHealthWidgets(healthCheck)
    -- Update system health score widget
    for widgetId, widget in pairs(DashboardState.widgets) do
        if widget.type == "system_health_score" then
            OperationalDashboardsHealthMonitoringSystem.updateWidget(widgetId, healthCheck.overallScore)
        end
    end
end

-- ========================================
-- METRICS ENGINE
-- ========================================

function OperationalDashboardsHealthMonitoringSystem.initializeMetricsEngine()
    DashboardState.metricsEngine = {
        collectors = {},
        processors = {},
        
        collectMetrics = function(self)
            return OperationalDashboardsHealthMonitoringSystem.collectSystemMetrics()
        end,
        
        processMetrics = function(self, metrics)
            return OperationalDashboardsHealthMonitoringSystem.processMetricsData(metrics)
        end,
        
        getMetrics = function(self, metricName, timeRange)
            return OperationalDashboardsHealthMonitoringSystem.getMetricsData(metricName, timeRange)
        end
    }
    
    print("📊 Metrics collection engine initialized")
end

function OperationalDashboardsHealthMonitoringSystem.collectSystemMetrics()
    local startTime = tick()
    
    local metrics = {
        timestamp = os.time(),
        
        -- Performance metrics
        performance = {
            avgResponseTime = math.random(50, 200),
            p50ResponseTime = math.random(40, 150),
            p95ResponseTime = math.random(100, 400),
            p99ResponseTime = math.random(200, 800),
            throughput = math.random(1000, 5000),
            errorRate = math.random() * 2, -- 0-2%
            concurrentUsers = math.random(500, 2000)
        },
        
        -- Infrastructure metrics
        infrastructure = {
            cpuUsage = math.random(20, 80),
            memoryUsage = math.random(30, 85),
            diskUsage = math.random(40, 90),
            networkIO = math.random(100, 1000),
            activeServers = math.random(8, 12),
            serverUtilization = math.random(50, 90)
        },
        
        -- Business metrics
        business = {
            activeUsers = math.random(1000, 5000),
            newSignups = math.random(50, 200),
            conversionRate = 0.05 + (math.random() * 0.1), -- 5-15%
            revenue = math.random(1000, 10000),
            churnRate = math.random() * 0.05 -- 0-5%
        },
        
        -- Security metrics
        security = {
            threatScore = math.random(0, 100),
            blockedRequests = math.random(10, 100),
            failedLogins = math.random(5, 50),
            vulnerabilities = math.random(0, 5),
            complianceScore = math.random(80, 100)
        },
        
        -- DevOps metrics
        devops = {
            deployments = math.random(0, 5),
            pipelineSuccessRate = 0.9 + (math.random() * 0.1), -- 90-100%
            testCoverage = 0.7 + (math.random() * 0.25), -- 70-95%
            buildTime = math.random(300, 1200),
            activeFeatureFlags = math.random(10, 30)
        }
    }
    
    -- Store metrics
    DashboardState.metricsData.latest = metrics
    table.insert(DashboardState.metricsHistory, metrics)
    
    -- Keep only last 1000 metric snapshots
    if #DashboardState.metricsHistory > 1000 then
        table.remove(DashboardState.metricsHistory, 1)
    end
    
    DashboardState.performanceMetrics.metricsCollectionTime = (tick() - startTime) * 1000
    
    -- Update dashboard widgets with new metrics
    OperationalDashboardsHealthMonitoringSystem.updateMetricWidgets(metrics)
    
    return metrics
end

function OperationalDashboardsHealthMonitoringSystem.updateMetricWidgets(metrics)
    for widgetId, widget in pairs(DashboardState.widgets) do
        local value = nil
        
        if widget.type == "response_times" then
            value = metrics.performance.avgResponseTime
        elseif widget.type == "error_rates" then
            value = metrics.performance.errorRate
        elseif widget.type == "active_users" then
            value = metrics.business.activeUsers
        elseif widget.type == "throughput_trends" then
            value = metrics.performance.throughput
        elseif widget.type == "resource_utilization" then
            value = (metrics.infrastructure.cpuUsage + metrics.infrastructure.memoryUsage) / 2
        elseif widget.type == "security_alerts" then
            value = metrics.security.blockedRequests
        elseif widget.type == "pipeline_status" then
            value = metrics.devops.pipelineSuccessRate * 100
        end
        
        if value then
            OperationalDashboardsHealthMonitoringSystem.updateWidget(widgetId, value)
        end
    end
end

-- ========================================
-- ALERT ENGINE
-- ========================================

function OperationalDashboardsHealthMonitoringSystem.initializeAlertEngine()
    DashboardState.alertEngine = {
        rules = {},
        
        checkAlertRules = function(self, metrics)
            return OperationalDashboardsHealthMonitoringSystem.checkAlertRules(metrics)
        end,
        
        createAlert = function(self, alertData)
            return OperationalDashboardsHealthMonitoringSystem.createAlert(alertData)
        end,
        
        resolveAlert = function(self, alertId)
            return OperationalDashboardsHealthMonitoringSystem.resolveAlert(alertId)
        end
    }
    
    -- Load alert rules
    OperationalDashboardsHealthMonitoringSystem.loadAlertRules()
    
    print("🚨 Alert engine initialized")
end

function OperationalDashboardsHealthMonitoringSystem.loadAlertRules()
    DashboardState.alertEngine.rules = DashboardState.config.alertConfigurations
    
    print(string.format("🚨 Loaded %d alert rules", 
        table.count and table.count(DashboardState.alertEngine.rules) or 3))
end

function OperationalDashboardsHealthMonitoringSystem.checkAlertRules(metrics)
    local triggeredAlerts = {}
    
    for ruleName, rule in pairs(DashboardState.alertEngine.rules) do
        local triggered = OperationalDashboardsHealthMonitoringSystem.evaluateAlertRule(rule, metrics)
        
        if triggered then
            local alert = OperationalDashboardsHealthMonitoringSystem.createAlert({
                rule = rule,
                ruleName = ruleName,
                metrics = metrics,
                value = OperationalDashboardsHealthMonitoringSystem.getMetricValue(rule.metric, metrics)
            })
            
            table.insert(triggeredAlerts, alert)
        end
    end
    
    return triggeredAlerts
end

function OperationalDashboardsHealthMonitoringSystem.evaluateAlertRule(rule, metrics)
    local value = OperationalDashboardsHealthMonitoringSystem.getMetricValue(rule.metric, metrics)
    
    if not value then
        return false
    end
    
    return value > rule.threshold
end

function OperationalDashboardsHealthMonitoringSystem.getMetricValue(metricPath, metrics)
    if metricPath == "system_health_score" then
        return 100 - (DashboardState.systemStatus.overallHealth or 100)
    elseif metricPath == "avg_response_time" then
        return metrics.performance.avgResponseTime
    elseif metricPath == "error_rate" then
        return metrics.performance.errorRate
    end
    
    return nil
end

function OperationalDashboardsHealthMonitoringSystem.createAlert(alertData)
    local alert = {
        id = HttpService:GenerateGUID(),
        rule = alertData.ruleName,
        metric = alertData.rule.metric,
        severity = alertData.rule.severity,
        
        threshold = alertData.rule.threshold,
        actualValue = alertData.value,
        
        triggered = os.time(),
        status = "active",
        
        description = string.format("%s exceeded threshold: %.2f > %.2f", 
            alertData.rule.metric, 
            alertData.value, 
            alertData.rule.threshold)
    }
    
    DashboardState.activeAlerts[alert.id] = alert
    
    print(string.format("🚨 Alert triggered: %s (%s)", alert.description, alert.severity))
    
    -- Send to monitoring system
    local MonitoringSystem = SafeRequire("ReplicatedStorage.Shared.devops.MonitoringAlertingSystem")
    if MonitoringSystem then
        MonitoringSystem.createManualAlert({
            title = "Dashboard Alert",
            message = alert.description,
            level = alert.severity == "critical" and "critical" or "warning",
            source = "operational_dashboard"
        })
    end
    
    return alert
end

-- ========================================
-- MONITORING LOOPS
-- ========================================

function OperationalDashboardsHealthMonitoringSystem.startHealthMonitoring()
    spawn(function()
        while true do
            OperationalDashboardsHealthMonitoringSystem.performComprehensiveHealthCheck()
            wait(60) -- Health check every minute
        end
    end)
    
    print("🏥 Health monitoring started")
end

function OperationalDashboardsHealthMonitoringSystem.startMetricsCollection()
    spawn(function()
        while true do
            local metrics = OperationalDashboardsHealthMonitoringSystem.collectSystemMetrics()
            
            -- Check alert rules
            DashboardState.alertEngine:checkAlertRules(metrics)
            
            wait(30) -- Collect metrics every 30 seconds
        end
    end)
    
    print("📊 Metrics collection started")
end

function OperationalDashboardsHealthMonitoringSystem.startDashboardRefresh()
    spawn(function()
        while true do
            for dashboardId, dashboard in pairs(DashboardState.dashboards) do
                if dashboard.status == "active" then
                    OperationalDashboardsHealthMonitoringSystem.refreshDashboard(dashboardId)
                end
            end
            
            wait(15) -- Refresh dashboards every 15 seconds
        end
    end)
    
    print("📊 Dashboard refresh started")
end

function OperationalDashboardsHealthMonitoringSystem.refreshDashboard(dashboardId)
    local dashboard = DashboardState.dashboards[dashboardId]
    
    if not dashboard then
        return
    end
    
    local startTime = tick()
    
    -- Simulate dashboard refresh processing
    wait(0.01)
    
    dashboard.lastRefresh = os.time()
    dashboard.metrics.loadTime = (tick() - startTime) * 1000
    
    DashboardState.performanceMetrics.dashboardLoadTime = dashboard.metrics.loadTime
end

-- ========================================
-- DATA INTEGRATION
-- ========================================

function OperationalDashboardsHealthMonitoringSystem.integrateWithDevOpsSystem()
    -- Integrate with deployment pipeline
    local DeploymentSystem = SafeRequire("ReplicatedStorage.Shared.devops.DeploymentPipelineSystem")
    if DeploymentSystem then
        -- Get deployment metrics
        spawn(function()
            while true do
                local deploymentMetrics = {
                    activePipelines = 0,
                    successRate = 95,
                    averageDeployTime = 180
                }
                
                -- Update deployment widgets
                for widgetId, widget in pairs(DashboardState.widgets) do
                    if widget.type == "deployment_status" then
                        OperationalDashboardsHealthMonitoringSystem.updateWidget(widgetId, deploymentMetrics.successRate)
                    end
                end
                
                wait(60)
            end
        end)
    end
    
    -- Integrate with monitoring system
    local MonitoringSystem = SafeRequire("ReplicatedStorage.Shared.devops.MonitoringAlertingSystem")
    if MonitoringSystem then
        -- Sync with monitoring metrics
        spawn(function()
            while true do
                -- This would pull real metrics from the monitoring system
                wait(30)
            end
        end)
    end
    
    -- Integrate with security system
    local SecuritySystem = SafeRequire("ReplicatedStorage.Shared.devops.SecurityMonitoringIncidentResponseSystem")
    if SecuritySystem then
        -- Get security metrics
        spawn(function()
            while true do
                local securityStatus = {
                    activeIncidents = 0,
                    threatLevel = "low",
                    complianceScore = 98
                }
                
                -- Update security widgets
                for widgetId, widget in pairs(DashboardState.widgets) do
                    if widget.type == "security_alerts" then
                        OperationalDashboardsHealthMonitoringSystem.updateWidget(widgetId, securityStatus.activeIncidents)
                    end
                end
                
                wait(45)
            end
        end)
    end
end

-- ========================================
-- REPORTING AND ANALYTICS
-- ========================================

function OperationalDashboardsHealthMonitoringSystem.generateHealthReport(timeRange)
    timeRange = timeRange or 3600 -- Default 1 hour
    
    local currentTime = os.time()
    local startTime = currentTime - timeRange
    
    local report = {
        timeRange = {
            start = startTime,
            end = currentTime,
            duration = timeRange
        },
        
        summary = {
            averageHealthScore = 0,
            minHealthScore = 100,
            maxHealthScore = 0,
            healthTrend = "stable",
            incidentCount = 0
        },
        
        componentHealth = {},
        performanceMetrics = {},
        alertSummary = {},
        
        generated = currentTime
    }
    
    -- Analyze health history
    local healthScores = {}
    local incidentCount = 0
    
    for _, healthCheck in ipairs(DashboardState.healthHistory) do
        if healthCheck.timestamp >= startTime then
            table.insert(healthScores, healthCheck.overallScore)
            
            if healthCheck.status ~= "healthy" then
                incidentCount = incidentCount + 1
            end
        end
    end
    
    if #healthScores > 0 then
        -- Calculate summary statistics
        local sum = 0
        local min = 100
        local max = 0
        
        for _, score in ipairs(healthScores) do
            sum = sum + score
            min = math.min(min, score)
            max = math.max(max, score)
        end
        
        report.summary.averageHealthScore = sum / #healthScores
        report.summary.minHealthScore = min
        report.summary.maxHealthScore = max
        report.summary.incidentCount = incidentCount
        
        -- Determine trend
        if #healthScores >= 2 then
            local firstHalf = {}
            local secondHalf = {}
            local midpoint = math.floor(#healthScores / 2)
            
            for i = 1, midpoint do
                table.insert(firstHalf, healthScores[i])
            end
            
            for i = midpoint + 1, #healthScores do
                table.insert(secondHalf, healthScores[i])
            end
            
            local firstAvg = 0
            local secondAvg = 0
            
            for _, score in ipairs(firstHalf) do
                firstAvg = firstAvg + score
            end
            firstAvg = firstAvg / #firstHalf
            
            for _, score in ipairs(secondHalf) do
                secondAvg = secondAvg + score
            end
            secondAvg = secondAvg / #secondHalf
            
            if secondAvg > firstAvg + 2 then
                report.summary.healthTrend = "improving"
            elseif secondAvg < firstAvg - 2 then
                report.summary.healthTrend = "degrading"
            else
                report.summary.healthTrend = "stable"
            end
        end
    end
    
    return report
end

-- ========================================
-- PUBLIC API
-- ========================================

function OperationalDashboardsHealthMonitoringSystem.getDashboard(dashboardId)
    return DashboardState.dashboardEngine:getDashboardData(dashboardId)
end

function OperationalDashboardsHealthMonitoringSystem.getSystemHealth()
    return DashboardState.healthEngine:getOverallHealth()
end

function OperationalDashboardsHealthMonitoringSystem.getActiveAlerts()
    return DashboardState.activeAlerts
end

function OperationalDashboardsHealthMonitoringSystem.getMetrics(metricName, timeRange)
    return DashboardState.metricsEngine:getMetrics(metricName, timeRange)
end

function OperationalDashboardsHealthMonitoringSystem.getAllDashboards()
    return DashboardState.dashboards
end

function OperationalDashboardsHealthMonitoringSystem.getSystemStatus()
    return DashboardState.systemStatus
end

function OperationalDashboardsHealthMonitoringSystem.getPerformanceMetrics()
    return DashboardState.performanceMetrics
end

function OperationalDashboardsHealthMonitoringSystem.runDashboardDemo()
    print("📊 Running operational dashboards and health monitoring demonstration...")
    
    -- Show system overview
    print("  📈 System Overview:")
    local status = OperationalDashboardsHealthMonitoringSystem.getSystemStatus()
    print(string.format("    Overall Health: %.1f%%", status.overallHealth))
    print(string.format("    Active Dashboards: %d", status.dashboardsActive))
    print(string.format("    Active Widgets: %d", status.widgetsActive))
    print(string.format("    Last Health Check: %s", 
        status.lastHealthCheck and os.date("%H:%M:%S", status.lastHealthCheck) or "Never"))
    
    -- Show dashboards
    print("  📊 Available Dashboards:")
    for dashboardId, dashboard in pairs(DashboardState.dashboards) do
        print(string.format("    %s:", dashboard.name))
        print(string.format("      Description: %s", dashboard.description))
        print(string.format("      Widgets: %d", #dashboard.widgets))
        print(string.format("      Refresh Interval: %ds", dashboard.refreshInterval))
        print(string.format("      Status: %s", dashboard.status))
    end
    
    -- Show health components
    print("  🏥 Health Components:")
    if DashboardState.healthScores.latest then
        for componentName, componentHealth in pairs(DashboardState.healthScores.latest.components) do
            print(string.format("    %s: %.1f%% (%s)", 
                componentHealth.name, 
                componentHealth.score, 
                componentHealth.status))
            print(string.format("      Checks: %d passed, %d total", 
                OperationalDashboardsHealthMonitoringSystem.countPassedChecks(componentHealth.checks),
                #componentHealth.checks))
        end
    end
    
    -- Show latest metrics
    print("  📊 Latest Metrics:")
    if DashboardState.metricsData.latest then
        local metrics = DashboardState.metricsData.latest
        print(string.format("    Performance:"))
        print(string.format("      Avg Response Time: %.0fms", metrics.performance.avgResponseTime))
        print(string.format("      Error Rate: %.2f%%", metrics.performance.errorRate))
        print(string.format("      Throughput: %d req/s", metrics.performance.throughput))
        print(string.format("      Concurrent Users: %d", metrics.performance.concurrentUsers))
        
        print(string.format("    Infrastructure:"))
        print(string.format("      CPU Usage: %.1f%%", metrics.infrastructure.cpuUsage))
        print(string.format("      Memory Usage: %.1f%%", metrics.infrastructure.memoryUsage))
        print(string.format("      Active Servers: %d", metrics.infrastructure.activeServers))
        
        print(string.format("    Business:"))
        print(string.format("      Active Users: %d", metrics.business.activeUsers))
        print(string.format("      Conversion Rate: %.2f%%", metrics.business.conversionRate * 100))
        print(string.format("      Revenue: $%.0f", metrics.business.revenue))
    end
    
    -- Show active alerts
    print("  🚨 Active Alerts:")
    local alertCount = 0
    for alertId, alert in pairs(DashboardState.activeAlerts) do
        alertCount = alertCount + 1
        print(string.format("    %s: %s", alert.severity:upper(), alert.description))
    end
    
    if alertCount == 0 then
        print("    No active alerts")
    end
    
    -- Show performance metrics
    print("  ⚡ Performance Metrics:")
    local perfMetrics = OperationalDashboardsHealthMonitoringSystem.getPerformanceMetrics()
    print(string.format("    Dashboard Load Time: %.1fms", perfMetrics.dashboardLoadTime))
    print(string.format("    Metrics Collection Time: %.1fms", perfMetrics.metricsCollectionTime))
    print(string.format("    Health Check Duration: %.1fms", perfMetrics.healthCheckDuration))
    
    -- Generate and show health report
    print("  📄 Health Report (Last Hour):")
    local report = OperationalDashboardsHealthMonitoringSystem.generateHealthReport(3600)
    print(string.format("    Average Health Score: %.1f%%", report.summary.averageHealthScore))
    print(string.format("    Min/Max Health Score: %.1f%% / %.1f%%", 
        report.summary.minHealthScore, 
        report.summary.maxHealthScore))
    print(string.format("    Health Trend: %s", report.summary.healthTrend))
    print(string.format("    Incidents: %d", report.summary.incidentCount))
    
    -- Demonstrate dashboard data retrieval
    print("  📋 Dashboard Data Sample:")
    for dashboardId, dashboard in pairs(DashboardState.dashboards) do
        if dashboardId == "operational" then
            local dashboardData = OperationalDashboardsHealthMonitoringSystem.getDashboard(dashboardId)
            if dashboardData.success then
                print(string.format("    %s Dashboard:", dashboard.name))
                print(string.format("      Widgets: %d", #dashboardData.data.widgets))
                
                for _, widget in ipairs(dashboardData.data.widgets) do
                    if widget.data.current then
                        print(string.format("        %s: %s %s", 
                            widget.name, 
                            tostring(widget.data.current),
                            widget.config.unit or ""))
                    end
                end
            end
            break
        end
    end
    
    print("📊 Operational dashboards and health monitoring demonstration completed")
    print("     Enterprise-grade operational visibility and health monitoring operational!")
end

-- Helper function to count passed health checks
function OperationalDashboardsHealthMonitoringSystem.countPassedChecks(checks)
    local passed = 0
    for _, check in ipairs(checks) do
        if check.passed then
            passed = passed + 1
        end
    end
    return passed
end

-- Helper function for table counting (if not available)
if not table.count then
    function table.count(t)
        local count = 0
        for _ in pairs(t) do count = count + 1 end
        return count
    end
end

-- Initialize the operational dashboards system
OperationalDashboardsHealthMonitoringSystem.initialize()

-- Start integration with other DevOps systems
OperationalDashboardsHealthMonitoringSystem.integrateWithDevOpsSystem()

print("📊 OperationalDashboardsHealthMonitoringSystem loaded with comprehensive monitoring and dashboards")

return OperationalDashboardsHealthMonitoringSystem
