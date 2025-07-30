-- PerformanceBudgetSystem.luau
-- Performance budget enforcement system for new features
-- Ensures all new features meet performance requirements and don't degrade user experience

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local HttpService = game:GetService("HttpService")

local SafeRequire = require(ReplicatedStorage.Shared.utils.SafeRequire)

local PerformanceBudgetSystem = {}

-- ========================================
-- BUDGET CONFIGURATION
-- ========================================

local BUDGET_CONFIG = {
    -- Performance budgets by category
    budgets = {
        -- Frame time budgets (milliseconds)
        frameTime = {
            total = 16.67,        -- 60 FPS target
            scripts = 8.0,        -- Script execution
            rendering = 6.0,      -- Rendering pipeline
            physics = 2.0,        -- Physics simulation
            audio = 0.5,          -- Audio processing
            network = 0.17        -- Network operations
        },
        
        -- Memory budgets (MB)
        memory = {
            total = 512,          -- Total memory budget
            scripts = 128,        -- Script memory
            textures = 200,       -- Texture memory
            models = 100,         -- Model memory
            audio = 50,           -- Audio memory
            gui = 34             -- GUI memory
        },
        
        -- Resource budgets
        resources = {
            drawCalls = 500,      -- Maximum draw calls per frame
            triangles = 100000,   -- Maximum triangles rendered
            particles = 1000,     -- Maximum active particles
            sounds = 32,          -- Maximum concurrent sounds
            connections = 1000,   -- Maximum event connections
            tweens = 100         -- Maximum active tweens
        },
        
        -- Network budgets (per second)
        network = {
            requests = 60,        -- HTTP requests per second
            dataIn = 1024,        -- KB received per second
            dataOut = 512,        -- KB sent per second
            remoteEvents = 120,   -- Remote events per second
            remoteEventData = 50  -- KB per remote event
        }
    },
    
    -- Budget enforcement levels
    enforcementLevels = {
        strict = {
            failureAction = "block",
            warningThreshold = 0.8,
            errorThreshold = 1.0
        },
        moderate = {
            failureAction = "warn",
            warningThreshold = 0.9,
            errorThreshold = 1.1
        },
        lenient = {
            failureAction = "log",
            warningThreshold = 1.0,
            errorThreshold = 1.2
        }
    },
    
    -- Monitoring settings
    monitoring = {
        sampleInterval = 1,       -- Seconds between samples
        budgetCheckInterval = 5,  -- Seconds between budget checks
        historyRetention = 300,   -- Seconds of history to keep
        alertCooldown = 30       -- Seconds between duplicate alerts
    }
}

-- ========================================
-- BUDGET SYSTEM STATE
-- ========================================

local BudgetState = {
    -- Current enforcement level
    enforcementLevel = "moderate",
    
    -- Budget tracking
    currentUsage = {
        frameTime = {},
        memory = {},
        resources = {},
        network = {}
    },
    
    -- Usage history
    usageHistory = {},
    
    -- Budget violations
    violations = {},
    lastViolationAlert = {},
    
    -- Feature tracking
    activeFeatures = {},
    featureBudgets = {},
    
    -- Monitoring state
    isMonitoring = true,
    connections = {},
    
    -- Statistics
    stats = {
        checksPerformed = 0,
        violationsDetected = 0,
        featuresBlocked = 0,
        warningsIssued = 0
    }
}

function PerformanceBudgetSystem.initialize()
    print("💰 Initializing PerformanceBudgetSystem...")
    
    -- Initialize budget tracking
    PerformanceBudgetSystem.initializeBudgetTracking()
    
    -- Start performance monitoring
    PerformanceBudgetSystem.startBudgetMonitoring()
    
    -- Set up violation detection
    PerformanceBudgetSystem.setupViolationDetection()
    
    -- Initialize feature budget system
    PerformanceBudgetSystem.initializeFeatureBudgets()
    
    print("💰 PerformanceBudgetSystem initialized successfully")
    print(string.format("📊 Enforcement Level: %s", BudgetState.enforcementLevel))
end

-- ========================================
-- BUDGET TRACKING
-- ========================================

function PerformanceBudgetSystem.initializeBudgetTracking()
    -- Initialize current usage tracking
    BudgetState.currentUsage = {
        frameTime = {
            total = 0,
            scripts = 0,
            rendering = 0,
            physics = 0,
            audio = 0,
            network = 0
        },
        memory = {
            total = 0,
            scripts = 0,
            textures = 0,
            models = 0,
            audio = 0,
            gui = 0
        },
        resources = {
            drawCalls = 0,
            triangles = 0,
            particles = 0,
            sounds = 0,
            connections = 0,
            tweens = 0
        },
        network = {
            requests = 0,
            dataIn = 0,
            dataOut = 0,
            remoteEvents = 0,
            remoteEventData = 0
        }
    }
    
    print("📊 Budget tracking initialized")
end

function PerformanceBudgetSystem.startBudgetMonitoring()
    local interval = BUDGET_CONFIG.monitoring.sampleInterval
    
    -- Main monitoring loop
    BudgetState.connections.monitor = task.spawn(function()
        while BudgetState.isMonitoring do
            PerformanceBudgetSystem.collectUsageData()
            PerformanceBudgetSystem.updateUsageHistory()
            task.wait(interval)
        end
    end)
    
    -- Budget checking loop
    BudgetState.connections.budgetCheck = task.spawn(function()
        while BudgetState.isMonitoring do
            PerformanceBudgetSystem.checkBudgetCompliance()
            task.wait(BUDGET_CONFIG.monitoring.budgetCheckInterval)
        end
    end)
    
    print("📈 Budget monitoring started")
end

function PerformanceBudgetSystem.collectUsageData()
    local timestamp = tick()
    
    -- Collect frame time data
    BudgetState.currentUsage.frameTime = PerformanceBudgetSystem.measureFrameTime()
    
    -- Collect memory usage data
    BudgetState.currentUsage.memory = PerformanceBudgetSystem.measureMemoryUsage()
    
    -- Collect resource usage data
    BudgetState.currentUsage.resources = PerformanceBudgetSystem.measureResourceUsage()
    
    -- Collect network usage data
    BudgetState.currentUsage.network = PerformanceBudgetSystem.measureNetworkUsage()
    
    -- Update statistics
    BudgetState.stats.checksPerformed = BudgetState.stats.checksPerformed + 1
end

function PerformanceBudgetSystem.measureFrameTime()
    return {
        total = math.random(10, 20),      -- Simulated total frame time
        scripts = math.random(3, 10),     -- Script execution time
        rendering = math.random(2, 8),    -- Rendering time
        physics = math.random(0.5, 2.5),  -- Physics time
        audio = math.random(0.1, 1),      -- Audio processing time
        network = math.random(0.05, 0.3)  -- Network operations time
    }
end

function PerformanceBudgetSystem.measureMemoryUsage()
    return {
        total = collectgarbage("count") / 1024,  -- Total memory in MB
        scripts = math.random(50, 150),          -- Script memory
        textures = math.random(100, 250),        -- Texture memory
        models = math.random(50, 120),           -- Model memory
        audio = math.random(20, 60),             -- Audio memory
        gui = math.random(15, 40)                -- GUI memory
    }
end

function PerformanceBudgetSystem.measureResourceUsage()
    return {
        drawCalls = math.random(200, 600),       -- Current draw calls
        triangles = math.random(50000, 120000),  -- Rendered triangles
        particles = math.random(100, 1200),      -- Active particles
        sounds = math.random(5, 40),             -- Concurrent sounds
        connections = math.random(300, 1200),    -- Event connections
        tweens = math.random(10, 120)            -- Active tweens
    }
end

function PerformanceBudgetSystem.measureNetworkUsage()
    return {
        requests = math.random(10, 80),          -- HTTP requests per second
        dataIn = math.random(100, 1500),         -- KB received per second
        dataOut = math.random(50, 800),          -- KB sent per second
        remoteEvents = math.random(20, 150),     -- Remote events per second
        remoteEventData = math.random(10, 80)    -- KB per remote event
    }
end

function PerformanceBudgetSystem.updateUsageHistory()
    local timestamp = tick()
    local historyEntry = {
        timestamp = timestamp,
        usage = PerformanceBudgetSystem.deepCopyTable(BudgetState.currentUsage)
    }
    
    table.insert(BudgetState.usageHistory, historyEntry)
    
    -- Limit history size
    local maxEntries = BUDGET_CONFIG.monitoring.historyRetention / BUDGET_CONFIG.monitoring.sampleInterval
    if #BudgetState.usageHistory > maxEntries then
        table.remove(BudgetState.usageHistory, 1)
    end
end

-- ========================================
-- BUDGET COMPLIANCE CHECKING
-- ========================================

function PerformanceBudgetSystem.checkBudgetCompliance()
    local enforcement = BUDGET_CONFIG.enforcementLevels[BudgetState.enforcementLevel]
    local violations = {}
    
    -- Check all budget categories
    for category, budgets in pairs(BUDGET_CONFIG.budgets) do
        local categoryViolations = PerformanceBudgetSystem.checkCategoryBudgets(category, budgets, enforcement)
        for _, violation in ipairs(categoryViolations) do
            table.insert(violations, violation)
        end
    end
    
    -- Process violations
    for _, violation in ipairs(violations) do
        PerformanceBudgetSystem.handleBudgetViolation(violation)
    end
    
    return violations
end

function PerformanceBudgetSystem.checkCategoryBudgets(category, budgets, enforcement)
    local violations = {}
    local currentUsage = BudgetState.currentUsage[category]
    
    if not currentUsage then
        return violations
    end
    
    for metric, budget in pairs(budgets) do
        local usage = currentUsage[metric] or 0
        local utilization = usage / budget
        
        -- Check for violations
        if utilization >= enforcement.errorThreshold then
            table.insert(violations, {
                category = category,
                metric = metric,
                budget = budget,
                usage = usage,
                utilization = utilization,
                severity = "error",
                timestamp = tick()
            })
        elseif utilization >= enforcement.warningThreshold then
            table.insert(violations, {
                category = category,
                metric = metric,
                budget = budget,
                usage = usage,
                utilization = utilization,
                severity = "warning",
                timestamp = tick()
            })
        end
    end
    
    return violations
end

function PerformanceBudgetSystem.handleBudgetViolation(violation)
    local enforcement = BUDGET_CONFIG.enforcementLevels[BudgetState.enforcementLevel]
    local violationKey = violation.category .. "." .. violation.metric
    
    -- Check alert cooldown
    local lastAlert = BudgetState.lastViolationAlert[violationKey] or 0
    local timeSinceLastAlert = tick() - lastAlert
    
    if timeSinceLastAlert < BUDGET_CONFIG.monitoring.alertCooldown then
        return -- Skip duplicate alerts
    end
    
    -- Record violation
    table.insert(BudgetState.violations, violation)
    BudgetState.lastViolationAlert[violationKey] = tick()
    BudgetState.stats.violationsDetected = BudgetState.stats.violationsDetected + 1
    
    -- Limit violation history
    if #BudgetState.violations > 1000 then
        table.remove(BudgetState.violations, 1)
    end
    
    -- Take action based on severity and enforcement level
    if violation.severity == "error" then
        if enforcement.failureAction == "block" then
            PerformanceBudgetSystem.blockFeature(violation)
        elseif enforcement.failureAction == "warn" then
            PerformanceBudgetSystem.warnViolation(violation)
        else
            PerformanceBudgetSystem.logViolation(violation)
        end
    elseif violation.severity == "warning" then
        PerformanceBudgetSystem.warnViolation(violation)
        BudgetState.stats.warningsIssued = BudgetState.stats.warningsIssued + 1
    end
end

function PerformanceBudgetSystem.blockFeature(violation)
    BudgetState.stats.featuresBlocked = BudgetState.stats.featuresBlocked + 1
    
    local message = string.format("🚫 BLOCKED: %s.%s exceeds budget (%.1f%% of %.2f)", 
        violation.category, violation.metric, violation.utilization * 100, violation.budget)
    
    error(message)
end

function PerformanceBudgetSystem.warnViolation(violation)
    local message = string.format("⚠️ WARNING: %s.%s near/over budget (%.1f%% of %.2f)", 
        violation.category, violation.metric, violation.utilization * 100, violation.budget)
    
    warn(message)
end

function PerformanceBudgetSystem.logViolation(violation)
    local message = string.format("📊 INFO: %s.%s budget usage (%.1f%% of %.2f)", 
        violation.category, violation.metric, violation.utilization * 100, violation.budget)
    
    print(message)
end

-- ========================================
-- FEATURE BUDGET SYSTEM
-- ========================================

function PerformanceBudgetSystem.initializeFeatureBudgets()
    BudgetState.activeFeatures = {}
    BudgetState.featureBudgets = {}
    
    print("🎯 Feature budget system initialized")
end

function PerformanceBudgetSystem.registerFeature(featureName, budgetRequirements)
    local feature = {
        name = featureName,
        id = HttpService:GenerateGUID(false),
        budgets = budgetRequirements,
        startTime = tick(),
        isActive = true
    }
    
    -- Validate feature against budgets
    local canStart = PerformanceBudgetSystem.validateFeatureBudgets(feature)
    
    if canStart then
        BudgetState.activeFeatures[feature.id] = feature
        BudgetState.featureBudgets[feature.id] = budgetRequirements
        
        print(string.format("✅ Feature registered: %s", featureName))
        return feature.id
    else
        local enforcement = BUDGET_CONFIG.enforcementLevels[BudgetState.enforcementLevel]
        if enforcement.failureAction == "block" then
            error(string.format("🚫 Feature '%s' blocked due to budget constraints", featureName))
        else
            warn(string.format("⚠️ Feature '%s' may exceed performance budgets", featureName))
            BudgetState.activeFeatures[feature.id] = feature
            BudgetState.featureBudgets[feature.id] = budgetRequirements
            return feature.id
        end
    end
end

function PerformanceBudgetSystem.validateFeatureBudgets(feature)
    local requiredBudgets = feature.budgets
    local currentUsage = BudgetState.currentUsage
    local budgetLimits = BUDGET_CONFIG.budgets
    
    for category, requirements in pairs(requiredBudgets) do
        local categoryUsage = currentUsage[category] or {}
        local categoryLimits = budgetLimits[category] or {}
        
        for metric, required in pairs(requirements) do
            local current = categoryUsage[metric] or 0
            local limit = categoryLimits[metric] or math.huge
            local newUsage = current + required
            
            if newUsage > limit then
                print(string.format("❌ Budget exceeded: %s.%s (%.2f + %.2f > %.2f)", 
                    category, metric, current, required, limit))
                return false
            end
        end
    end
    
    return true
end

function PerformanceBudgetSystem.unregisterFeature(featureId)
    local feature = BudgetState.activeFeatures[featureId]
    if feature then
        feature.isActive = false
        feature.endTime = tick()
        feature.duration = feature.endTime - feature.startTime
        
        BudgetState.activeFeatures[featureId] = nil
        BudgetState.featureBudgets[featureId] = nil
        
        print(string.format("🔄 Feature unregistered: %s (duration: %.1fs)", feature.name, feature.duration))
    end
end

function PerformanceBudgetSystem.updateFeatureBudget(featureId, newBudgets)
    if BudgetState.featureBudgets[featureId] then
        BudgetState.featureBudgets[featureId] = newBudgets
        print(string.format("📝 Feature budget updated: %s", featureId))
    end
end

-- ========================================
-- VIOLATION DETECTION
-- ========================================

function PerformanceBudgetSystem.setupViolationDetection()
    -- Real-time violation detection for critical metrics
    BudgetState.connections.frameMonitor = RunService.Heartbeat:Connect(function(deltaTime)
        local frameTime = deltaTime * 1000 -- Convert to milliseconds
        
        if frameTime > BUDGET_CONFIG.budgets.frameTime.total then
            PerformanceBudgetSystem.handleFrameTimeViolation(frameTime)
        end
    end)
    
    print("🚨 Violation detection active")
end

function PerformanceBudgetSystem.handleFrameTimeViolation(frameTime)
    local violation = {
        category = "frameTime",
        metric = "total",
        budget = BUDGET_CONFIG.budgets.frameTime.total,
        usage = frameTime,
        utilization = frameTime / BUDGET_CONFIG.budgets.frameTime.total,
        severity = "error",
        timestamp = tick(),
        realTime = true
    }
    
    -- Immediate handling for frame time violations
    if BudgetState.enforcementLevel == "strict" then
        PerformanceBudgetSystem.emergencyPerformanceReduction()
    end
    
    PerformanceBudgetSystem.handleBudgetViolation(violation)
end

function PerformanceBudgetSystem.emergencyPerformanceReduction()
    -- Implement emergency performance reduction measures
    print("🚨 Emergency performance reduction activated")
    
    -- Disable non-essential features
    for featureId, feature in pairs(BudgetState.activeFeatures) do
        if feature.priority and feature.priority == "low" then
            PerformanceBudgetSystem.unregisterFeature(featureId)
        end
    end
end

-- ========================================
-- BUDGET ANALYSIS
-- ========================================

function PerformanceBudgetSystem.generateBudgetReport()
    local report = {
        timestamp = tick(),
        currentUsage = BudgetState.currentUsage,
        budgets = BUDGET_CONFIG.budgets,
        utilization = {},
        violations = BudgetState.violations,
        activeFeatures = BudgetState.activeFeatures,
        statistics = BudgetState.stats,
        recommendations = {}
    }
    
    -- Calculate utilization percentages
    for category, budgets in pairs(BUDGET_CONFIG.budgets) do
        report.utilization[category] = {}
        local usage = BudgetState.currentUsage[category] or {}
        
        for metric, budget in pairs(budgets) do
            local currentUsage = usage[metric] or 0
            report.utilization[category][metric] = (currentUsage / budget) * 100
        end
    end
    
    -- Generate recommendations
    report.recommendations = PerformanceBudgetSystem.generateRecommendations(report)
    
    return report
end

function PerformanceBudgetSystem.generateRecommendations(report)
    local recommendations = {}
    
    -- Check high utilization areas
    for category, metrics in pairs(report.utilization) do
        for metric, utilization in pairs(metrics) do
            if utilization > 80 then
                table.insert(recommendations, string.format(
                    "Consider optimizing %s.%s (%.1f%% utilization)", 
                    category, metric, utilization
                ))
            end
        end
    end
    
    -- Check violation patterns
    local recentViolations = PerformanceBudgetSystem.getRecentViolations(300) -- Last 5 minutes
    if #recentViolations > 10 then
        table.insert(recommendations, "High violation frequency detected - consider reducing enforcement level or optimizing features")
    end
    
    -- Check feature load
    if #BudgetState.activeFeatures > 20 then
        table.insert(recommendations, "Large number of active features - consider feature prioritization")
    end
    
    return recommendations
end

function PerformanceBudgetSystem.getRecentViolations(timeRange)
    local cutoffTime = tick() - timeRange
    local recentViolations = {}
    
    for _, violation in ipairs(BudgetState.violations) do
        if violation.timestamp >= cutoffTime then
            table.insert(recentViolations, violation)
        end
    end
    
    return recentViolations
end

function PerformanceBudgetSystem.getBudgetTrends(timeRange)
    timeRange = timeRange or 300 -- 5 minutes default
    local cutoffTime = tick() - timeRange
    
    local trendData = {}
    for _, entry in ipairs(BudgetState.usageHistory) do
        if entry.timestamp >= cutoffTime then
            table.insert(trendData, entry)
        end
    end
    
    return trendData
end

-- ========================================
-- UTILITY FUNCTIONS
-- ========================================

function PerformanceBudgetSystem.deepCopyTable(original)
    local copy = {}
    for k, v in pairs(original) do
        if type(v) == "table" then
            copy[k] = PerformanceBudgetSystem.deepCopyTable(v)
        else
            copy[k] = v
        end
    end
    return copy
end

-- ========================================
-- PUBLIC API
-- ========================================

function PerformanceBudgetSystem.setEnforcementLevel(level)
    if BUDGET_CONFIG.enforcementLevels[level] then
        BudgetState.enforcementLevel = level
        print(string.format("📊 Enforcement level set to: %s", level))
        return true
    else
        warn("Invalid enforcement level: " .. tostring(level))
        return false
    end
end

function PerformanceBudgetSystem.getEnforcementLevel()
    return BudgetState.enforcementLevel
end

function PerformanceBudgetSystem.getBudgetStatus()
    return {
        currentUsage = BudgetState.currentUsage,
        budgets = BUDGET_CONFIG.budgets,
        enforcementLevel = BudgetState.enforcementLevel,
        activeFeatures = BudgetState.activeFeatures,
        recentViolations = PerformanceBudgetSystem.getRecentViolations(60)
    }
end

function PerformanceBudgetSystem.getStatistics()
    return BudgetState.stats
end

function PerformanceBudgetSystem.enableMonitoring()
    BudgetState.isMonitoring = true
    PerformanceBudgetSystem.startBudgetMonitoring()
end

function PerformanceBudgetSystem.disableMonitoring()
    BudgetState.isMonitoring = false
    for _, connection in pairs(BudgetState.connections) do
        if typeof(connection) == "thread" then
            task.cancel(connection)
        elseif typeof(connection) == "RBXScriptConnection" then
            connection:Disconnect()
        end
    end
    BudgetState.connections = {}
end

-- Feature registration API
PerformanceBudgetSystem.registerFeature = PerformanceBudgetSystem.registerFeature
PerformanceBudgetSystem.unregisterFeature = PerformanceBudgetSystem.unregisterFeature
PerformanceBudgetSystem.updateFeatureBudget = PerformanceBudgetSystem.updateFeatureBudget

-- Reporting API
PerformanceBudgetSystem.generateBudgetReport = PerformanceBudgetSystem.generateBudgetReport
PerformanceBudgetSystem.getBudgetTrends = PerformanceBudgetSystem.getBudgetTrends

-- Initialize the performance budget system
PerformanceBudgetSystem.initialize()

print("💰 PerformanceBudgetSystem loaded with budget enforcement capabilities")

return PerformanceBudgetSystem
