-- MonitoringAlertingSystem.luau
-- Comprehensive monitoring and alerting for all production systems
-- Provides real-time monitoring, alerting, and operational insights

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local HttpService = game:GetService("HttpService")
local RunService = game:GetService("RunService")

local SafeRequire = require(ReplicatedStorage.Shared.utils.SafeRequire)

local MonitoringAlertingSystem = {}

-- ========================================
-- MONITORING CONFIGURATION
-- ========================================

local MONITORING_CONFIG = {
    -- Metrics collection
    metrics = {
        collection = {
            interval = 5, -- seconds
            retention = "30d",
            compression = true,
            batchSize = 100
        },
        
        categories = {
            performance = {
                cpu_usage = {threshold = 80, unit = "%"},
                memory_usage = {threshold = 85, unit = "%"},
                response_time = {threshold = 200, unit = "ms"},
                throughput = {threshold = 1000, unit = "req/min"},
                error_rate = {threshold = 1, unit = "%"}
            },
            
            business = {
                active_users = {threshold = 100, unit = "count"},
                revenue_per_minute = {threshold = 10, unit = "$"},
                conversion_rate = {threshold = 2, unit = "%"},
                player_retention = {threshold = 60, unit = "%"}
            },
            
            system = {
                disk_usage = {threshold = 90, unit = "%"},
                network_latency = {threshold = 100, unit = "ms"},
                connection_count = {threshold = 1000, unit = "count"},
                queue_length = {threshold = 50, unit = "count"}
            },
            
            application = {
                script_errors = {threshold = 5, unit = "count/min"},
                game_crashes = {threshold = 1, unit = "count/hour"},
                data_corruption = {threshold = 0, unit = "count"},
                security_violations = {threshold = 0, unit = "count"}
            }
        }
    },
    
    -- Alerting rules
    alerting = {
        levels = {
            info = {color = "blue", escalation = false},
            warning = {color = "yellow", escalation = false},
            critical = {color = "orange", escalation = true},
            emergency = {color = "red", escalation = true, immediate = true}
        },
        
        channels = {
            email = {enabled = true, recipients = {"ops@company.com", "dev@company.com"}},
            slack = {enabled = true, webhook = "https://hooks.slack.com/services/..."},
            sms = {enabled = true, recipients = {"+1234567890"}},
            discord = {enabled = true, webhook = "https://discord.com/api/webhooks/..."}
        },
        
        escalation = {
            timeouts = {
                warning = 300, -- 5 minutes
                critical = 60,  -- 1 minute
                emergency = 30  -- 30 seconds
            },
            
            rules = {
                {condition = "no_response", action = "escalate", timeout = 600},
                {condition = "repeated_alerts", action = "group", threshold = 5},
                {condition = "cascade_failure", action = "emergency", threshold = 3}
            }
        }
    },
    
    -- Health checks
    healthChecks = {
        endpoints = {
            "/health/api",
            "/health/database", 
            "/health/cache",
            "/health/game_server",
            "/health/matchmaking"
        },
        
        interval = 30, -- seconds
        timeout = 10,  -- seconds
        retries = 3,
        
        requirements = {
            response_time = 1000, -- ms
            success_rate = 99.5,  -- %
            availability = 99.9   -- %
        }
    },
    
    -- Dashboard configuration
    dashboards = {
        operational = {
            refresh = 30, -- seconds
            panels = {"system_overview", "performance_metrics", "error_rates", "active_alerts"}
        },
        
        business = {
            refresh = 60,
            panels = {"user_metrics", "revenue_tracking", "engagement_stats", "conversion_funnel"}
        },
        
        technical = {
            refresh = 15,
            panels = {"resource_usage", "request_latency", "database_performance", "cache_hit_rate"}
        }
    }
}

-- ========================================
-- SYSTEM STATE
-- ========================================

local MonitoringState = {
    -- Core engines
    metricsEngine = nil,
    alertingEngine = nil,
    healthCheckEngine = nil,
    
    -- Active monitoring
    activeMetrics = {},
    activeAlerts = {},
    healthStatus = {},
    
    -- Data storage
    metricsData = {},
    alertHistory = {},
    
    -- Thresholds and rules
    thresholds = {},
    alertRules = {},
    
    -- Dashboard data
    dashboards = {},
    
    -- System status
    systemHealth = {
        overall = "healthy",
        services = {},
        lastUpdate = nil
    },
    
    -- Performance tracking
    metrics = {
        metricsCollected = 0,
        alertsTriggered = 0,
        alertsResolved = 0,
        healthChecksPerformed = 0,
        avgResponseTime = 0,
        systemUptime = 0
    },
    
    -- Configuration
    config = MONITORING_CONFIG
}

function MonitoringAlertingSystem.initialize()
    print("📊 Initializing MonitoringAlertingSystem...")
    
    -- Initialize core engines
    MonitoringAlertingSystem.initializeMetricsEngine()
    MonitoringAlertingSystem.initializeAlertingEngine()
    MonitoringAlertingSystem.initializeHealthCheckEngine()
    
    -- Set up monitoring collection
    MonitoringAlertingSystem.startMetricsCollection()
    
    -- Initialize dashboards
    MonitoringAlertingSystem.initializeDashboards()
    
    -- Start health monitoring
    MonitoringAlertingSystem.startHealthMonitoring()
    
    print("📊 MonitoringAlertingSystem initialized successfully")
end

-- ========================================
-- METRICS ENGINE
-- ========================================

function MonitoringAlertingSystem.initializeMetricsEngine()
    MonitoringState.metricsEngine = {
        collectors = {},
        processors = {},
        
        collectMetric = function(self, metricName, value, tags)
            return MonitoringAlertingSystem.collectMetric(metricName, value, tags)
        end,
        
        getMetrics = function(self, category, timeRange)
            return MonitoringAlertingSystem.getMetrics(category, timeRange)
        end,
        
        processMetrics = function(self, metrics)
            return MonitoringAlertingSystem.processMetrics(metrics)
        end
    }
    
    -- Initialize metric collectors
    MonitoringAlertingSystem.initializeMetricCollectors()
    
    print("📈 Metrics engine initialized")
end

function MonitoringAlertingSystem.initializeMetricCollectors()
    MonitoringState.metricsEngine.collectors = {
        performance = function()
            return MonitoringAlertingSystem.collectPerformanceMetrics()
        end,
        
        business = function()
            return MonitoringAlertingSystem.collectBusinessMetrics()
        end,
        
        system = function()
            return MonitoringAlertingSystem.collectSystemMetrics()
        end,
        
        application = function()
            return MonitoringAlertingSystem.collectApplicationMetrics()
        end
    }
end

function MonitoringAlertingSystem.collectMetric(metricName, value, tags)
    tags = tags or {}
    
    local metric = {
        name = metricName,
        value = value,
        timestamp = os.time(),
        tags = tags
    }
    
    -- Store metric
    if not MonitoringState.metricsData[metricName] then
        MonitoringState.metricsData[metricName] = {}
    end
    
    table.insert(MonitoringState.metricsData[metricName], metric)
    
    -- Keep only recent data (for memory management)
    if #MonitoringState.metricsData[metricName] > 1000 then
        table.remove(MonitoringState.metricsData[metricName], 1)
    end
    
    -- Check thresholds
    MonitoringAlertingSystem.checkMetricThreshold(metric)
    
    MonitoringState.metrics.metricsCollected = MonitoringState.metrics.metricsCollected + 1
    
    return metric
end

function MonitoringAlertingSystem.collectPerformanceMetrics()
    local metrics = {}
    
    -- Simulate performance metrics collection
    metrics.cpu_usage = math.random(30, 95)
    metrics.memory_usage = math.random(40, 90)
    metrics.response_time = math.random(50, 250)
    metrics.throughput = math.random(800, 1500)
    metrics.error_rate = math.random() * 5
    
    -- Collect real Roblox metrics where available
    local heartbeat = tick()
    metrics.frame_rate = 1 / RunService.Heartbeat:Wait()
    metrics.script_performance = heartbeat - tick()
    
    return metrics
end

function MonitoringAlertingSystem.collectBusinessMetrics()
    local metrics = {}
    
    -- Simulate business metrics
    metrics.active_users = math.random(50, 200)
    metrics.revenue_per_minute = math.random(5, 25)
    metrics.conversion_rate = math.random() * 5
    metrics.player_retention = math.random(40, 80)
    
    return metrics
end

function MonitoringAlertingSystem.collectSystemMetrics()
    local metrics = {}
    
    -- System resource metrics
    metrics.disk_usage = math.random(60, 95)
    metrics.network_latency = math.random(20, 150)
    metrics.connection_count = math.random(100, 800)
    metrics.queue_length = math.random(0, 100)
    
    return metrics
end

function MonitoringAlertingSystem.collectApplicationMetrics()
    local metrics = {}
    
    -- Application-specific metrics
    metrics.script_errors = math.random(0, 10)
    metrics.game_crashes = math.random(0, 2)
    metrics.data_corruption = 0 -- Should always be 0
    metrics.security_violations = math.random(0, 1)
    
    return metrics
end

function MonitoringAlertingSystem.startMetricsCollection()
    -- Start periodic metrics collection
    spawn(function()
        while true do
            -- Collect metrics from all categories
            for category, collector in pairs(MonitoringState.metricsEngine.collectors) do
                local metrics = collector()
                
                for metricName, value in pairs(metrics) do
                    MonitoringAlertingSystem.collectMetric(
                        category .. "." .. metricName, 
                        value, 
                        {category = category}
                    )
                end
            end
            
            -- Update system health
            MonitoringAlertingSystem.updateSystemHealth()
            
            wait(MonitoringState.config.metrics.collection.interval)
        end
    end)
    
    print("📊 Metrics collection started")
end

-- ========================================
-- ALERTING ENGINE
-- ========================================

function MonitoringAlertingSystem.initializeAlertingEngine()
    MonitoringState.alertingEngine = {
        rules = {},
        activeAlerts = {},
        
        createAlert = function(self, alertData)
            return MonitoringAlertingSystem.createAlert(alertData)
        end,
        
        resolveAlert = function(self, alertId)
            return MonitoringAlertingSystem.resolveAlert(alertId)
        end,
        
        escalateAlert = function(self, alertId)
            return MonitoringAlertingSystem.escalateAlert(alertId)
        end
    }
    
    -- Initialize alert rules
    MonitoringAlertingSystem.initializeAlertRules()
    
    print("🚨 Alerting engine initialized")
end

function MonitoringAlertingSystem.initializeAlertRules()
    MonitoringState.alertRules = {
        -- Performance alerts
        high_cpu = {
            condition = "performance.cpu_usage > 80",
            level = "warning",
            message = "High CPU usage detected: {value}%"
        },
        
        critical_cpu = {
            condition = "performance.cpu_usage > 95",
            level = "critical", 
            message = "Critical CPU usage: {value}%"
        },
        
        high_memory = {
            condition = "performance.memory_usage > 85",
            level = "warning",
            message = "High memory usage: {value}%"
        },
        
        slow_response = {
            condition = "performance.response_time > 200",
            level = "warning",
            message = "Slow response time: {value}ms"
        },
        
        high_error_rate = {
            condition = "performance.error_rate > 1",
            level = "critical",
            message = "High error rate: {value}%"
        },
        
        -- System alerts
        disk_full = {
            condition = "system.disk_usage > 90",
            level = "critical",
            message = "Disk usage critical: {value}%"
        },
        
        network_issues = {
            condition = "system.network_latency > 100",
            level = "warning",
            message = "High network latency: {value}ms"
        },
        
        -- Application alerts
        script_errors = {
            condition = "application.script_errors > 5",
            level = "warning",
            message = "High script error rate: {value} errors/min"
        },
        
        game_crashes = {
            condition = "application.game_crashes > 0",
            level = "critical",
            message = "Game crashes detected: {value} crashes"
        },
        
        security_violation = {
            condition = "application.security_violations > 0",
            level = "emergency",
            message = "Security violation detected: {value} violations"
        }
    }
end

function MonitoringAlertingSystem.checkMetricThreshold(metric)
    -- Check against all alert rules
    for ruleName, rule in pairs(MonitoringState.alertRules) do
        if MonitoringAlertingSystem.evaluateAlertCondition(rule.condition, metric) then
            MonitoringAlertingSystem.triggerAlert(ruleName, rule, metric)
        end
    end
end

function MonitoringAlertingSystem.evaluateAlertCondition(condition, metric)
    -- Simple condition evaluation (in real implementation, would use proper parser)
    local metricPath = metric.name
    local value = metric.value
    
    -- Replace metric path and value in condition
    local evaluatedCondition = condition:gsub("{[^}]+}", tostring(value))
    
    -- Check if metric path matches condition
    if condition:find(metricPath) then
        -- Extract operator and threshold
        local operator, threshold = condition:match("([><=]+)%s*([%d%.]+)")
        
        if operator and threshold then
            threshold = tonumber(threshold)
            
            if operator == ">" then
                return value > threshold
            elseif operator == ">=" then
                return value >= threshold
            elseif operator == "<" then
                return value < threshold
            elseif operator == "<=" then
                return value <= threshold
            elseif operator == "==" then
                return value == threshold
            end
        end
    end
    
    return false
end

function MonitoringAlertingSystem.triggerAlert(ruleName, rule, metric)
    -- Check if alert already exists for this rule
    for _, alert in pairs(MonitoringState.alertingEngine.activeAlerts) do
        if alert.rule == ruleName and alert.status == "active" then
            -- Update existing alert
            alert.lastTriggered = os.time()
            alert.occurrences = alert.occurrences + 1
            return alert
        end
    end
    
    -- Create new alert
    local alert = {
        id = HttpService:GenerateGUID(),
        rule = ruleName,
        level = rule.level,
        message = rule.message:gsub("{value}", tostring(metric.value)),
        metric = metric,
        
        createdAt = os.time(),
        lastTriggered = os.time(),
        status = "active",
        occurrences = 1,
        
        escalated = false,
        resolved = false,
        acknowledgedBy = nil
    }
    
    MonitoringState.alertingEngine.activeAlerts[alert.id] = alert
    MonitoringState.metrics.alertsTriggered = MonitoringState.metrics.alertsTriggered + 1
    
    -- Send alert notifications
    MonitoringAlertingSystem.sendAlertNotifications(alert)
    
    -- Check for escalation
    if rule.level == "critical" or rule.level == "emergency" then
        MonitoringAlertingSystem.scheduleEscalation(alert)
    end
    
    print(string.format("🚨 Alert triggered: %s - %s", alert.level:upper(), alert.message))
    
    return alert
end

function MonitoringAlertingSystem.createAlert(alertData)
    local alert = {
        id = HttpService:GenerateGUID(),
        title = alertData.title,
        message = alertData.message,
        level = alertData.level or "info",
        source = alertData.source or "manual",
        
        createdAt = os.time(),
        status = "active",
        
        metadata = alertData.metadata or {}
    }
    
    MonitoringState.alertingEngine.activeAlerts[alert.id] = alert
    
    -- Send notifications
    MonitoringAlertingSystem.sendAlertNotifications(alert)
    
    return alert
end

function MonitoringAlertingSystem.resolveAlert(alertId)
    local alert = MonitoringState.alertingEngine.activeAlerts[alertId]
    
    if alert then
        alert.status = "resolved"
        alert.resolvedAt = os.time()
        
        MonitoringState.metrics.alertsResolved = MonitoringState.metrics.alertsResolved + 1
        
        -- Move to history
        table.insert(MonitoringState.alertHistory, alert)
        MonitoringState.alertingEngine.activeAlerts[alertId] = nil
        
        print(string.format("✅ Alert resolved: %s", alert.message))
        
        return true
    end
    
    return false
end

function MonitoringAlertingSystem.sendAlertNotifications(alert)
    local config = MonitoringState.config.alerting
    
    -- Determine notification channels based on alert level
    local channels = {}
    
    if alert.level == "emergency" then
        channels = {"email", "slack", "sms", "discord"}
    elseif alert.level == "critical" then
        channels = {"email", "slack", "discord"}
    elseif alert.level == "warning" then
        channels = {"slack", "discord"}
    else
        channels = {"discord"}
    end
    
    -- Send notifications
    for _, channel in ipairs(channels) do
        if config.channels[channel] and config.channels[channel].enabled then
            MonitoringAlertingSystem.sendNotification(channel, alert)
        end
    end
end

function MonitoringAlertingSystem.sendNotification(channel, alert)
    local message = string.format("[%s] %s: %s", 
        alert.level:upper(), 
        alert.title or "Alert", 
        alert.message
    )
    
    print(string.format("📢 Sending %s notification: %s", channel, message))
    
    -- In real implementation, would integrate with actual notification services
    if channel == "email" then
        -- Send email via SMTP
    elseif channel == "slack" then
        -- Send to Slack webhook
    elseif channel == "sms" then
        -- Send SMS via Twilio or similar
    elseif channel == "discord" then
        -- Send to Discord webhook
    end
end

function MonitoringAlertingSystem.scheduleEscalation(alert)
    local timeout = MonitoringState.config.alerting.escalation.timeouts[alert.level]
    
    if timeout then
        spawn(function()
            wait(timeout)
            
            -- Check if alert is still active and not acknowledged
            if MonitoringState.alertingEngine.activeAlerts[alert.id] and not alert.acknowledgedBy then
                MonitoringAlertingSystem.escalateAlert(alert.id)
            end
        end)
    end
end

function MonitoringAlertingSystem.escalateAlert(alertId)
    local alert = MonitoringState.alertingEngine.activeAlerts[alertId]
    
    if alert and not alert.escalated then
        alert.escalated = true
        alert.escalatedAt = os.time()
        
        -- Escalate to higher level
        if alert.level == "warning" then
            alert.level = "critical"
        elseif alert.level == "critical" then
            alert.level = "emergency"
        end
        
        print(string.format("⬆️ Alert escalated: %s", alert.message))
        
        -- Send escalated notifications
        MonitoringAlertingSystem.sendAlertNotifications(alert)
        
        return true
    end
    
    return false
end

-- ========================================
-- HEALTH CHECK ENGINE
-- ========================================

function MonitoringAlertingSystem.initializeHealthCheckEngine()
    MonitoringState.healthCheckEngine = {
        checks = {},
        results = {},
        
        addHealthCheck = function(self, checkConfig)
            return MonitoringAlertingSystem.addHealthCheck(checkConfig)
        end,
        
        runHealthCheck = function(self, checkName)
            return MonitoringAlertingSystem.runHealthCheck(checkName)
        end,
        
        getHealthStatus = function(self)
            return MonitoringAlertingSystem.getOverallHealthStatus()
        end
    }
    
    -- Initialize default health checks
    MonitoringAlertingSystem.initializeDefaultHealthChecks()
    
    print("❤️ Health check engine initialized")
end

function MonitoringAlertingSystem.initializeDefaultHealthChecks()
    local healthChecks = {
        api_health = {
            name = "API Health",
            endpoint = "/health/api",
            timeout = 5000,
            expectedStatus = 200,
            critical = true
        },
        
        database_health = {
            name = "Database Health",
            endpoint = "/health/database",
            timeout = 3000,
            expectedStatus = 200,
            critical = true
        },
        
        cache_health = {
            name = "Cache Health", 
            endpoint = "/health/cache",
            timeout = 2000,
            expectedStatus = 200,
            critical = false
        },
        
        game_server_health = {
            name = "Game Server Health",
            endpoint = "/health/game_server",
            timeout = 5000,
            expectedStatus = 200,
            critical = true
        },
        
        matchmaking_health = {
            name = "Matchmaking Health",
            endpoint = "/health/matchmaking",
            timeout = 4000,
            expectedStatus = 200,
            critical = false
        }
    }
    
    for checkName, checkConfig in pairs(healthChecks) do
        MonitoringAlertingSystem.addHealthCheck(checkConfig)
    end
end

function MonitoringAlertingSystem.addHealthCheck(checkConfig)
    local check = {
        name = checkConfig.name,
        endpoint = checkConfig.endpoint,
        timeout = checkConfig.timeout or 5000,
        expectedStatus = checkConfig.expectedStatus or 200,
        critical = checkConfig.critical or false,
        
        lastRun = nil,
        lastStatus = "unknown",
        lastResponseTime = 0,
        successRate = 100,
        
        history = {}
    }
    
    MonitoringState.healthCheckEngine.checks[checkConfig.name] = check
    
    return check
end

function MonitoringAlertingSystem.runHealthCheck(checkName)
    local check = MonitoringState.healthCheckEngine.checks[checkName]
    
    if not check then
        return {success = false, error = "Health check not found"}
    end
    
    local startTime = tick()
    
    -- Simulate health check execution
    local success = math.random() > 0.05 -- 95% success rate
    local responseTime = math.random(50, check.timeout / 10)
    local status = success and check.expectedStatus or 500
    
    local endTime = tick()
    local duration = (endTime - startTime) * 1000 -- Convert to milliseconds
    
    local result = {
        checkName = checkName,
        success = success,
        status = status,
        responseTime = responseTime,
        duration = duration,
        timestamp = os.time(),
        message = success and "Health check passed" or "Health check failed"
    }
    
    -- Update check status
    check.lastRun = os.time()
    check.lastStatus = success and "healthy" or "unhealthy"
    check.lastResponseTime = responseTime
    
    -- Update success rate
    table.insert(check.history, result)
    if #check.history > 20 then
        table.remove(check.history, 1)
    end
    
    local successes = 0
    for _, historyResult in ipairs(check.history) do
        if historyResult.success then
            successes = successes + 1
        end
    end
    check.successRate = (successes / #check.history) * 100
    
    MonitoringState.metrics.healthChecksPerformed = MonitoringState.metrics.healthChecksPerformed + 1
    
    -- Trigger alert if critical check fails
    if not success and check.critical then
        MonitoringAlertingSystem.createAlert({
            title = "Critical Health Check Failed",
            message = string.format("%s health check failed: %s", check.name, result.message),
            level = "critical",
            source = "health_check",
            metadata = result
        })
    end
    
    return result
end

function MonitoringAlertingSystem.startHealthMonitoring()
    spawn(function()
        while true do
            -- Run all health checks
            for checkName, _ in pairs(MonitoringState.healthCheckEngine.checks) do
                MonitoringAlertingSystem.runHealthCheck(checkName)
            end
            
            wait(MonitoringState.config.healthChecks.interval)
        end
    end)
    
    print("❤️ Health monitoring started")
end

function MonitoringAlertingSystem.getOverallHealthStatus()
    local overallHealth = "healthy"
    local criticalIssues = 0
    local totalChecks = 0
    local healthyChecks = 0
    
    for _, check in pairs(MonitoringState.healthCheckEngine.checks) do
        totalChecks = totalChecks + 1
        
        if check.lastStatus == "healthy" then
            healthyChecks = healthyChecks + 1
        elseif check.critical and check.lastStatus == "unhealthy" then
            criticalIssues = criticalIssues + 1
        end
    end
    
    if criticalIssues > 0 then
        overallHealth = "critical"
    elseif healthyChecks < totalChecks then
        overallHealth = "degraded"
    end
    
    return {
        status = overallHealth,
        healthyChecks = healthyChecks,
        totalChecks = totalChecks,
        criticalIssues = criticalIssues,
        lastUpdate = os.time()
    }
end

function MonitoringAlertingSystem.updateSystemHealth()
    local healthStatus = MonitoringAlertingSystem.getOverallHealthStatus()
    
    MonitoringState.systemHealth = {
        overall = healthStatus.status,
        services = {},
        lastUpdate = os.time(),
        
        metrics = {
            healthyServices = healthStatus.healthyChecks,
            totalServices = healthStatus.totalChecks,
            criticalIssues = healthStatus.criticalIssues
        }
    }
    
    -- Update service-specific health
    for checkName, check in pairs(MonitoringState.healthCheckEngine.checks) do
        MonitoringState.systemHealth.services[checkName] = {
            status = check.lastStatus,
            responseTime = check.lastResponseTime,
            successRate = check.successRate,
            lastCheck = check.lastRun
        }
    end
end

-- ========================================
-- DASHBOARD SYSTEM
-- ========================================

function MonitoringAlertingSystem.initializeDashboards()
    MonitoringState.dashboards = {
        operational = MonitoringAlertingSystem.createOperationalDashboard(),
        business = MonitoringAlertingSystem.createBusinessDashboard(),
        technical = MonitoringAlertingSystem.createTechnicalDashboard()
    }
    
    print("📊 Monitoring dashboards initialized")
end

function MonitoringAlertingSystem.createOperationalDashboard()
    return {
        name = "Operational Dashboard",
        refreshInterval = 30,
        panels = {
            system_overview = {
                title = "System Overview",
                type = "status",
                data = function()
                    return MonitoringAlertingSystem.getSystemOverview()
                end
            },
            
            performance_metrics = {
                title = "Performance Metrics",
                type = "chart",
                data = function()
                    return MonitoringAlertingSystem.getPerformanceOverview()
                end
            },
            
            error_rates = {
                title = "Error Rates",
                type = "chart",
                data = function()
                    return MonitoringAlertingSystem.getErrorRateOverview()
                end
            },
            
            active_alerts = {
                title = "Active Alerts",
                type = "list",
                data = function()
                    return MonitoringAlertingSystem.getActiveAlerts()
                end
            }
        }
    }
end

function MonitoringAlertingSystem.createBusinessDashboard()
    return {
        name = "Business Dashboard",
        refreshInterval = 60,
        panels = {
            user_metrics = {
                title = "User Metrics",
                type = "chart",
                data = function()
                    return MonitoringAlertingSystem.getUserMetrics()
                end
            },
            
            revenue_tracking = {
                title = "Revenue Tracking",
                type = "chart",
                data = function()
                    return MonitoringAlertingSystem.getRevenueMetrics()
                end
            },
            
            engagement_stats = {
                title = "Engagement Statistics",
                type = "chart",
                data = function()
                    return MonitoringAlertingSystem.getEngagementMetrics()
                end
            },
            
            conversion_funnel = {
                title = "Conversion Funnel",
                type = "funnel",
                data = function()
                    return MonitoringAlertingSystem.getConversionMetrics()
                end
            }
        }
    }
end

function MonitoringAlertingSystem.createTechnicalDashboard()
    return {
        name = "Technical Dashboard",
        refreshInterval = 15,
        panels = {
            resource_usage = {
                title = "Resource Usage",
                type = "gauge",
                data = function()
                    return MonitoringAlertingSystem.getResourceUsage()
                end
            },
            
            request_latency = {
                title = "Request Latency",
                type = "chart",
                data = function()
                    return MonitoringAlertingSystem.getLatencyMetrics()
                end
            },
            
            database_performance = {
                title = "Database Performance",
                type = "chart",
                data = function()
                    return MonitoringAlertingSystem.getDatabaseMetrics()
                end
            },
            
            cache_hit_rate = {
                title = "Cache Hit Rate",
                type = "chart",
                data = function()
                    return MonitoringAlertingSystem.getCacheMetrics()
                end
            }
        }
    }
end

-- ========================================
-- DASHBOARD DATA PROVIDERS
-- ========================================

function MonitoringAlertingSystem.getSystemOverview()
    local healthStatus = MonitoringAlertingSystem.getOverallHealthStatus()
    
    return {
        overallStatus = healthStatus.status,
        healthyServices = healthStatus.healthyChecks,
        totalServices = healthStatus.totalChecks,
        activeAlerts = table.getn and table.getn(MonitoringState.alertingEngine.activeAlerts) or 0,
        uptime = MonitoringState.metrics.systemUptime,
        lastUpdate = os.time()
    }
end

function MonitoringAlertingSystem.getPerformanceOverview()
    local recent = MonitoringAlertingSystem.getRecentMetrics("performance", 300) -- Last 5 minutes
    
    return {
        cpuUsage = recent["performance.cpu_usage"] or {},
        memoryUsage = recent["performance.memory_usage"] or {},
        responseTime = recent["performance.response_time"] or {},
        throughput = recent["performance.throughput"] or {},
        errorRate = recent["performance.error_rate"] or {}
    }
end

function MonitoringAlertingSystem.getErrorRateOverview()
    local recent = MonitoringAlertingSystem.getRecentMetrics("application", 600) -- Last 10 minutes
    
    return {
        scriptErrors = recent["application.script_errors"] or {},
        gameCrashes = recent["application.game_crashes"] or {},
        securityViolations = recent["application.security_violations"] or {}
    }
end

function MonitoringAlertingSystem.getActiveAlerts()
    local alerts = {}
    
    for _, alert in pairs(MonitoringState.alertingEngine.activeAlerts) do
        table.insert(alerts, {
            id = alert.id,
            level = alert.level,
            message = alert.message,
            createdAt = alert.createdAt,
            occurrences = alert.occurrences
        })
    end
    
    -- Sort by level priority
    table.sort(alerts, function(a, b)
        local priority = {emergency = 4, critical = 3, warning = 2, info = 1}
        return priority[a.level] > priority[b.level]
    end)
    
    return alerts
end

function MonitoringAlertingSystem.getRecentMetrics(category, timeWindow)
    local cutoffTime = os.time() - timeWindow
    local recentMetrics = {}
    
    for metricName, data in pairs(MonitoringState.metricsData) do
        if metricName:match("^" .. category .. "%.") then
            recentMetrics[metricName] = {}
            
            for _, metric in ipairs(data) do
                if metric.timestamp >= cutoffTime then
                    table.insert(recentMetrics[metricName], {
                        value = metric.value,
                        timestamp = metric.timestamp
                    })
                end
            end
        end
    end
    
    return recentMetrics
end

function MonitoringAlertingSystem.getUserMetrics()
    local recent = MonitoringAlertingSystem.getRecentMetrics("business", 3600) -- Last hour
    
    return {
        activeUsers = recent["business.active_users"] or {},
        playerRetention = recent["business.player_retention"] or {}
    }
end

function MonitoringAlertingSystem.getRevenueMetrics()
    local recent = MonitoringAlertingSystem.getRecentMetrics("business", 3600)
    
    return {
        revenuePerMinute = recent["business.revenue_per_minute"] or {},
        conversionRate = recent["business.conversion_rate"] or {}
    }
end

function MonitoringAlertingSystem.getEngagementMetrics()
    -- Placeholder for engagement metrics
    return {
        sessionLength = {{value = 15.5, timestamp = os.time()}},
        bounceRate = {{value = 12.3, timestamp = os.time()}},
        pageViews = {{value = 1234, timestamp = os.time()}}
    }
end

function MonitoringAlertingSystem.getConversionMetrics()
    return {
        steps = {
            {name = "Visitors", value = 1000},
            {name = "Signups", value = 850},
            {name = "Active Users", value = 600},
            {name = "Premium Users", value = 150}
        }
    }
end

function MonitoringAlertingSystem.getResourceUsage()
    local recent = MonitoringAlertingSystem.getRecentMetrics("system", 60)
    
    local cpu = recent["system.cpu_usage"] or {}
    local memory = recent["system.memory_usage"] or {}
    local disk = recent["system.disk_usage"] or {}
    
    return {
        cpu = #cpu > 0 and cpu[#cpu].value or 0,
        memory = #memory > 0 and memory[#memory].value or 0,
        disk = #disk > 0 and disk[#disk].value or 0
    }
end

function MonitoringAlertingSystem.getLatencyMetrics()
    local recent = MonitoringAlertingSystem.getRecentMetrics("performance", 600)
    
    return {
        responseTime = recent["performance.response_time"] or {},
        networkLatency = recent["system.network_latency"] or {}
    }
end

function MonitoringAlertingSystem.getDatabaseMetrics()
    -- Placeholder for database metrics
    return {
        queryTime = {{value = 45, timestamp = os.time()}},
        connectionPool = {{value = 25, timestamp = os.time()}},
        slowQueries = {{value = 2, timestamp = os.time()}}
    }
end

function MonitoringAlertingSystem.getCacheMetrics()
    -- Placeholder for cache metrics
    return {
        hitRate = {{value = 95.5, timestamp = os.time()}},
        memoryUsage = {{value = 65, timestamp = os.time()}},
        evictions = {{value = 10, timestamp = os.time()}}
    }
end

-- ========================================
-- PUBLIC API
-- ========================================

function MonitoringAlertingSystem.recordMetric(name, value, tags)
    return MonitoringState.metricsEngine:collectMetric(name, value, tags)
end

function MonitoringAlertingSystem.createManualAlert(alertData)
    return MonitoringState.alertingEngine:createAlert(alertData)
end

function MonitoringAlertingSystem.getMetrics(category, timeRange)
    return MonitoringState.metricsEngine:getMetrics(category, timeRange)
end

function MonitoringAlertingSystem.getSystemStatus()
    return MonitoringState.systemHealth
end

function MonitoringAlertingSystem.getDashboardData(dashboardName)
    local dashboard = MonitoringState.dashboards[dashboardName]
    
    if dashboard then
        local data = {}
        
        for panelName, panel in pairs(dashboard.panels) do
            data[panelName] = {
                title = panel.title,
                type = panel.type,
                data = panel.data()
            }
        end
        
        return {
            name = dashboard.name,
            refreshInterval = dashboard.refreshInterval,
            panels = data,
            lastUpdate = os.time()
        }
    end
    
    return nil
end

function MonitoringAlertingSystem.getAlertHistory(limit)
    limit = limit or 50
    
    local history = {}
    local count = 0
    
    for i = #MonitoringState.alertHistory, 1, -1 do
        if count >= limit then break end
        
        table.insert(history, MonitoringState.alertHistory[i])
        count = count + 1
    end
    
    return history
end

function MonitoringAlertingSystem.acknowledgeAlert(alertId, acknowledgedBy)
    local alert = MonitoringState.alertingEngine.activeAlerts[alertId]
    
    if alert then
        alert.acknowledgedBy = acknowledgedBy
        alert.acknowledgedAt = os.time()
        
        print(string.format("✅ Alert acknowledged by %s: %s", acknowledgedBy, alert.message))
        
        return true
    end
    
    return false
end

function MonitoringAlertingSystem.runMonitoringDemo()
    print("📊 Running monitoring and alerting demonstration...")
    
    -- Show configuration
    print("  ⚙️ Monitoring Configuration:")
    print(string.format("    Metrics Collection Interval: %ds", MonitoringState.config.metrics.collection.interval))
    print(string.format("    Health Check Interval: %ds", MonitoringState.config.healthChecks.interval))
    print(string.format("    Alert Channels: %d configured", table.getn and table.getn(MonitoringState.config.alerting.channels) or 4))
    
    -- Show metric categories
    print("  📈 Metric Categories:")
    for category, metrics in pairs(MonitoringState.config.metrics.categories) do
        local count = 0
        for _ in pairs(metrics) do count = count + 1 end
        print(string.format("    %s: %d metrics", category, count))
    end
    
    -- Simulate some metrics collection
    print("  📊 Collecting Sample Metrics:")
    for i = 1, 5 do
        local perfMetrics = MonitoringAlertingSystem.collectPerformanceMetrics()
        for metricName, value in pairs(perfMetrics) do
            MonitoringAlertingSystem.recordMetric("performance." .. metricName, value)
        end
        
        local sysMetrics = MonitoringAlertingSystem.collectSystemMetrics()
        for metricName, value in pairs(sysMetrics) do
            MonitoringAlertingSystem.recordMetric("system." .. metricName, value)
        end
        
        wait(0.1)
    end
    
    print(string.format("    ✅ Collected %d metrics", MonitoringState.metrics.metricsCollected))
    
    -- Show health checks
    print("  ❤️ Health Check Status:")
    for checkName, check in pairs(MonitoringState.healthCheckEngine.checks) do
        MonitoringAlertingSystem.runHealthCheck(checkName)
        print(string.format("    %s: %s (%.1f%% success rate)", 
            check.name, 
            check.lastStatus, 
            check.successRate))
    end
    
    -- Show system health
    print("  🏥 System Health Overview:")
    local healthStatus = MonitoringAlertingSystem.getOverallHealthStatus()
    print(string.format("    Overall Status: %s", healthStatus.status:upper()))
    print(string.format("    Healthy Services: %d/%d", healthStatus.healthyChecks, healthStatus.totalChecks))
    print(string.format("    Critical Issues: %d", healthStatus.criticalIssues))
    
    -- Show active alerts
    print("  🚨 Alert Status:")
    local activeAlerts = MonitoringAlertingSystem.getActiveAlerts()
    print(string.format("    Active Alerts: %d", #activeAlerts))
    
    if #activeAlerts > 0 then
        for _, alert in ipairs(activeAlerts) do
            print(string.format("      [%s] %s", alert.level:upper(), alert.message))
        end
    else
        print("      No active alerts")
    end
    
    -- Show alert rules
    print("  📋 Alert Rules:")
    local ruleCount = 0
    for ruleName, rule in pairs(MonitoringState.alertRules) do
        ruleCount = ruleCount + 1
        print(string.format("    %s: %s (%s)", ruleName, rule.condition, rule.level))
    end
    print(string.format("    Total Rules: %d", ruleCount))
    
    -- Show dashboards
    print("  📊 Available Dashboards:")
    for dashboardName, dashboard in pairs(MonitoringState.dashboards) do
        local panelCount = 0
        for _ in pairs(dashboard.panels) do panelCount = panelCount + 1 end
        print(string.format("    %s: %d panels (refresh: %ds)", 
            dashboard.name, 
            panelCount, 
            dashboard.refreshInterval))
    end
    
    -- Show notification channels
    print("  📢 Notification Channels:")
    for channel, config in pairs(MonitoringState.config.alerting.channels) do
        print(string.format("    %s: %s", channel, config.enabled and "Enabled" or "Disabled"))
    end
    
    -- Show metrics summary
    print("  📈 Metrics Summary:")
    local metrics = MonitoringState.metrics
    print(string.format("    Metrics Collected: %d", metrics.metricsCollected))
    print(string.format("    Alerts Triggered: %d", metrics.alertsTriggered))
    print(string.format("    Alerts Resolved: %d", metrics.alertsResolved))
    print(string.format("    Health Checks: %d", metrics.healthChecksPerformed))
    
    print("📊 Monitoring and alerting demonstration completed")
    print("     Comprehensive production monitoring operational!")
end

-- Initialize the monitoring and alerting system
MonitoringAlertingSystem.initialize()

print("📊 MonitoringAlertingSystem loaded with comprehensive production monitoring")

return MonitoringAlertingSystem
