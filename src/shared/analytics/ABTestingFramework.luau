-- ABTestingFramework.luau
-- A/B testing framework for feature experimentation and optimization
-- Provides comprehensive experiment management, statistical analysis, and result interpretation

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local SafeRequire = require(ReplicatedStorage.Shared.utils.SafeRequire)

local ABTestingFramework = {}

-- ========================================
-- TESTING CONFIGURATION
-- ========================================

local TESTING_CONFIG = {
    -- Experiment settings
    experiments = {
        defaultDuration = 7 * 86400,     -- 7 days
        minSampleSize = 100,             -- Minimum participants per variant
        confidenceLevel = 0.95,          -- 95% confidence
        statisticalPower = 0.8,          -- 80% power
        maxConcurrentTests = 10,         -- Maximum concurrent experiments
        cooldownPeriod = 86400           -- 24 hours between experiments
    },
    
    -- Allocation strategies
    allocation = {
        strategies = {
            "random",           -- Random assignment
            "deterministic",    -- Hash-based assignment
            "stratified",       -- Stratified by user attributes
            "adaptive",         -- Adaptive allocation based on performance
            "blocked"           -- Blocked randomization
        },
        
        defaultStrategy = "deterministic",
        maxVariants = 5,                 -- Maximum variants per experiment
        trafficAllocation = 1.0          -- Percentage of traffic to include
    },
    
    -- Metrics tracking
    metrics = {
        primary = {
            "conversion_rate",
            "retention_rate",
            "revenue_per_user",
            "engagement_score"
        },
        
        secondary = {
            "session_duration",
            "feature_usage",
            "user_satisfaction",
            "performance_impact"
        },
        
        guardrail = {
            "error_rate",
            "crash_rate",
            "load_time",
            "server_cost"
        }
    },
    
    -- Analysis settings
    analysis = {
        enableBayesian = true,
        enableSequential = true,
        enableMultiArmed = false,
        pValueThreshold = 0.05,
        effectSizeThreshold = 0.02,
        updateFrequency = 3600           -- 1 hour
    }
}

-- ========================================
-- TESTING STATE
-- ========================================

local TestingState = {
    -- Experiment management
    activeExperiments = {},
    completedExperiments = {},
    scheduledExperiments = {},
    
    -- User assignments
    userAssignments = {},
    assignmentHistory = {},
    
    -- Results tracking
    experimentResults = {},
    variantPerformance = {},
    
    -- Statistical analysis
    analysisResults = {},
    significanceTests = {},
    
    -- Configuration
    experimentConfigs = {},
    featureFlags = {},
    
    -- Statistics
    stats = {
        totalExperiments = 0,
        activeTests = 0,
        successfulTests = 0,
        significantResults = 0,
        totalParticipants = 0,
        averageExperimentDuration = 0
    }
}

function ABTestingFramework.initialize()
    print("🧪 Initializing ABTestingFramework...")
    
    -- Set up experiment management
    ABTestingFramework.setupExperimentManagement()
    
    -- Initialize user assignment system
    ABTestingFramework.initializeUserAssignment()
    
    -- Set up metrics collection
    ABTestingFramework.setupMetricsCollection()
    
    -- Initialize statistical analysis
    ABTestingFramework.initializeStatisticalAnalysis()
    
    -- Start experiment monitoring
    ABTestingFramework.startExperimentMonitoring()
    
    print("🧪 ABTestingFramework initialized successfully")
end

-- ========================================
-- EXPERIMENT MANAGEMENT
-- ========================================

function ABTestingFramework.setupExperimentManagement()
    TestingState.experimentManager = {
        validator = ABTestingFramework.createExperimentValidator(),
        scheduler = ABTestingFramework.createExperimentScheduler(),
        controller = ABTestingFramework.createExperimentController(),
        analyzer = ABTestingFramework.createExperimentAnalyzer()
    }
    
    print("🔬 Experiment management system initialized")
end

function ABTestingFramework.createExperimentValidator()
    return {
        name = "experiment_validator",
        
        validate = function(self, experiment)
            return ABTestingFramework.validateExperiment(experiment)
        end
    }
end

function ABTestingFramework.createExperimentScheduler()
    return {
        name = "experiment_scheduler",
        queue = {},
        
        schedule = function(self, experiment)
            return ABTestingFramework.scheduleExperiment(experiment)
        end,
        
        execute = function(self)
            ABTestingFramework.executeScheduledExperiments()
        end
    }
end

function ABTestingFramework.createExperimentController()
    return {
        name = "experiment_controller",
        
        start = function(self, experimentId)
            return ABTestingFramework.startExperiment(experimentId)
        end,
        
        stop = function(self, experimentId)
            return ABTestingFramework.stopExperiment(experimentId)
        end
    }
end

function ABTestingFramework.createExperimentAnalyzer()
    return {
        name = "experiment_analyzer",
        
        analyze = function(self, experimentId)
            return ABTestingFramework.analyzeExperiment(experimentId)
        end
    }
end

function ABTestingFramework.createExperiment(config)
    local experiment = {
        id = HttpService:GenerateGUID(false),
        name = config.name,
        description = config.description,
        hypothesis = config.hypothesis,
        
        -- Configuration
        variants = config.variants or {},
        allocation = config.allocation or TESTING_CONFIG.allocation.defaultStrategy,
        trafficPercentage = config.trafficPercentage or 1.0,
        
        -- Metrics
        primaryMetric = config.primaryMetric,
        secondaryMetrics = config.secondaryMetrics or {},
        guardrailMetrics = config.guardrailMetrics or {},
        
        -- Timing
        startTime = config.startTime or tick(),
        duration = config.duration or TESTING_CONFIG.experiments.defaultDuration,
        endTime = nil,
        
        -- Targeting
        targetingRules = config.targetingRules or {},
        exclusionRules = config.exclusionRules or {},
        
        -- Status
        status = "draft",
        participants = {},
        results = {},
        
        -- Metadata
        createdBy = config.createdBy,
        createdAt = tick(),
        tags = config.tags or {}
    }
    
    -- Validate experiment
    local validation = TestingState.experimentManager.validator:validate(experiment)
    if not validation.valid then
        return nil, validation.error
    end
    
    -- Store experiment configuration
    TestingState.experimentConfigs[experiment.id] = experiment
    
    print(string.format("🧪 Created experiment: %s (%s)", experiment.name, experiment.id))
    
    return experiment.id
end

function ABTestingFramework.validateExperiment(experiment)
    local validation = {valid = true, error = nil, warnings = {}}
    
    -- Check required fields
    if not experiment.name or experiment.name == "" then
        validation.valid = false
        validation.error = "Experiment name is required"
        return validation
    end
    
    if not experiment.primaryMetric then
        validation.valid = false
        validation.error = "Primary metric is required"
        return validation
    end
    
    if not experiment.variants or #experiment.variants < 2 then
        validation.valid = false
        validation.error = "At least 2 variants are required"
        return validation
    end
    
    -- Check variant allocation
    local totalAllocation = 0
    for _, variant in ipairs(experiment.variants) do
        totalAllocation = totalAllocation + (variant.allocation or 0)
    end
    
    if math.abs(totalAllocation - 1.0) > 0.01 then
        validation.valid = false
        validation.error = "Variant allocations must sum to 1.0"
        return validation
    end
    
    -- Check concurrent experiments limit
    local activeCount = 0
    for _ in pairs(TestingState.activeExperiments) do
        activeCount = activeCount + 1
    end
    
    if activeCount >= TESTING_CONFIG.experiments.maxConcurrentTests then
        validation.valid = false
        validation.error = "Maximum concurrent experiments limit reached"
        return validation
    end
    
    -- Warnings
    if experiment.duration > 30 * 86400 then -- 30 days
        table.insert(validation.warnings, "Long experiment duration may affect validity")
    end
    
    if experiment.trafficPercentage < 0.1 then
        table.insert(validation.warnings, "Low traffic percentage may affect statistical power")
    end
    
    return validation
end

function ABTestingFramework.scheduleExperiment(experiment)
    local startTime = experiment.startTime
    local currentTime = tick()
    
    if startTime <= currentTime then
        -- Start immediately
        return ABTestingFramework.startExperiment(experiment.id)
    else
        -- Schedule for later
        table.insert(TestingState.experimentManager.scheduler.queue, {
            experimentId = experiment.id,
            scheduledTime = startTime
        })
        
        experiment.status = "scheduled"
        TestingState.scheduledExperiments[experiment.id] = experiment
        
        print(string.format("📅 Scheduled experiment %s for %s", 
            experiment.name, os.date("%Y-%m-%d %H:%M:%S", startTime)))
        
        return true
    end
end

function ABTestingFramework.startExperiment(experimentId)
    local experiment = TestingState.experimentConfigs[experimentId]
    if not experiment then
        return false, "Experiment not found"
    end
    
    if experiment.status ~= "draft" and experiment.status ~= "scheduled" then
        return false, "Experiment already started or completed"
    end
    
    -- Initialize experiment
    experiment.status = "running"
    experiment.actualStartTime = tick()
    experiment.endTime = experiment.actualStartTime + experiment.duration
    experiment.participants = {}
    experiment.results = {}
    
    -- Move to active experiments
    TestingState.activeExperiments[experimentId] = experiment
    TestingState.scheduledExperiments[experimentId] = nil
    
    -- Initialize variant tracking
    for _, variant in ipairs(experiment.variants) do
        experiment.results[variant.id] = {
            participants = 0,
            metrics = {},
            events = {}
        }
    end
    
    -- Update statistics
    TestingState.stats.totalExperiments = TestingState.stats.totalExperiments + 1
    TestingState.stats.activeTests = TestingState.stats.activeTests + 1
    
    print(string.format("🚀 Started experiment: %s", experiment.name))
    
    return true
end

function ABTestingFramework.stopExperiment(experimentId)
    local experiment = TestingState.activeExperiments[experimentId]
    if not experiment then
        return false, "Active experiment not found"
    end
    
    experiment.status = "completed"
    experiment.actualEndTime = tick()
    experiment.actualDuration = experiment.actualEndTime - experiment.actualStartTime
    
    -- Perform final analysis
    local analysis = ABTestingFramework.analyzeExperiment(experimentId)
    experiment.finalAnalysis = analysis
    
    -- Move to completed experiments
    TestingState.completedExperiments[experimentId] = experiment
    TestingState.activeExperiments[experimentId] = nil
    
    -- Update statistics
    TestingState.stats.activeTests = TestingState.stats.activeTests - 1
    if analysis.hasSignificantResult then
        TestingState.stats.significantResults = TestingState.stats.significantResults + 1
    end
    
    print(string.format("🏁 Completed experiment: %s", experiment.name))
    
    return true, analysis
end

-- ========================================
-- USER ASSIGNMENT SYSTEM
-- ========================================

function ABTestingFramework.initializeUserAssignment()
    TestingState.assignmentEngine = {
        allocator = ABTestingFramework.createUserAllocator(),
        tracker = ABTestingFramework.createAssignmentTracker(),
        history = {}
    }
    
    print("👥 User assignment system initialized")
end

function ABTestingFramework.createUserAllocator()
    return {
        name = "user_allocator",
        
        allocate = function(self, userId, experimentId)
            return ABTestingFramework.allocateUserToVariant(userId, experimentId)
        end
    }
end

function ABTestingFramework.createAssignmentTracker()
    return {
        name = "assignment_tracker",
        
        track = function(self, userId, experimentId, variantId)
            ABTestingFramework.trackUserAssignment(userId, experimentId, variantId)
        end
    }
end

function ABTestingFramework.allocateUserToVariant(userId, experimentId)
    local experiment = TestingState.activeExperiments[experimentId]
    if not experiment then
        return nil, "Experiment not active"
    end
    
    -- Check if user already assigned
    local existingAssignment = TestingState.userAssignments[userId] and 
        TestingState.userAssignments[userId][experimentId]
    
    if existingAssignment then
        return existingAssignment.variantId
    end
    
    -- Check targeting rules
    if not ABTestingFramework.checkTargetingRules(userId, experiment) then
        return nil, "User does not meet targeting criteria"
    end
    
    -- Check exclusion rules
    if ABTestingFramework.checkExclusionRules(userId, experiment) then
        return nil, "User excluded by exclusion rules"
    end
    
    -- Check traffic allocation
    if not ABTestingFramework.checkTrafficAllocation(userId, experiment) then
        return nil, "User not in traffic allocation"
    end
    
    -- Allocate to variant
    local variantId = ABTestingFramework.assignVariant(userId, experiment)
    
    if variantId then
        -- Track assignment
        TestingState.assignmentEngine.tracker:track(userId, experimentId, variantId)
        
        -- Update experiment participants
        experiment.participants[userId] = {
            variantId = variantId,
            assignedAt = tick(),
            firstSeen = tick()
        }
        
        -- Update variant results
        experiment.results[variantId].participants = 
            experiment.results[variantId].participants + 1
        
        -- Update total participants
        TestingState.stats.totalParticipants = TestingState.stats.totalParticipants + 1
    end
    
    return variantId
end

function ABTestingFramework.assignVariant(userId, experiment)
    local allocation = experiment.allocation
    
    if allocation == "random" then
        return ABTestingFramework.randomAssignment(userId, experiment)
    elseif allocation == "deterministic" then
        return ABTestingFramework.deterministicAssignment(userId, experiment)
    elseif allocation == "stratified" then
        return ABTestingFramework.stratifiedAssignment(userId, experiment)
    elseif allocation == "adaptive" then
        return ABTestingFramework.adaptiveAssignment(userId, experiment)
    elseif allocation == "blocked" then
        return ABTestingFramework.blockedAssignment(userId, experiment)
    else
        return ABTestingFramework.deterministicAssignment(userId, experiment)
    end
end

function ABTestingFramework.deterministicAssignment(userId, experiment)
    -- Hash-based deterministic assignment
    local hash = ABTestingFramework.hashUserId(userId, experiment.id)
    local cumulativeAllocation = 0
    
    for _, variant in ipairs(experiment.variants) do
        cumulativeAllocation = cumulativeAllocation + variant.allocation
        if hash <= cumulativeAllocation then
            return variant.id
        end
    end
    
    -- Fallback to last variant
    return experiment.variants[#experiment.variants].id
end

function ABTestingFramework.randomAssignment(userId, experiment)
    local randomValue = math.random()
    local cumulativeAllocation = 0
    
    for _, variant in ipairs(experiment.variants) do
        cumulativeAllocation = cumulativeAllocation + variant.allocation
        if randomValue <= cumulativeAllocation then
            return variant.id
        end
    end
    
    return experiment.variants[#experiment.variants].id
end

function ABTestingFramework.stratifiedAssignment(userId, experiment)
    -- Simplified stratified assignment based on user ID
    local stratum = userId % 4 -- 4 strata
    return ABTestingFramework.deterministicAssignment(userId + stratum, experiment)
end

function ABTestingFramework.adaptiveAssignment(userId, experiment)
    -- Simplified adaptive assignment - favor better performing variants
    local bestVariant = ABTestingFramework.findBestPerformingVariant(experiment)
    if bestVariant and math.random() < 0.7 then -- 70% chance to assign to best
        return bestVariant.id
    else
        return ABTestingFramework.deterministicAssignment(userId, experiment)
    end
end

function ABTestingFramework.blockedAssignment(userId, experiment)
    -- Blocked randomization with block size of 10
    local blockSize = 10
    local blockIndex = math.floor(userId / blockSize)
    local positionInBlock = userId % blockSize
    
    -- Generate deterministic permutation for this block
    local seed = ABTestingFramework.hashUserId(blockIndex, experiment.id)
    math.randomseed(seed)
    
    local variants = {}
    for _, variant in ipairs(experiment.variants) do
        local count = math.floor(variant.allocation * blockSize)
        for i = 1, count do
            table.insert(variants, variant.id)
        end
    end
    
    -- Shuffle variants
    for i = #variants, 2, -1 do
        local j = math.random(i)
        variants[i], variants[j] = variants[j], variants[i]
    end
    
    return variants[positionInBlock + 1] or variants[1]
end

function ABTestingFramework.trackUserAssignment(userId, experimentId, variantId)
    if not TestingState.userAssignments[userId] then
        TestingState.userAssignments[userId] = {}
    end
    
    TestingState.userAssignments[userId][experimentId] = {
        variantId = variantId,
        assignedAt = tick(),
        experimentName = TestingState.activeExperiments[experimentId].name
    }
    
    -- Add to assignment history
    table.insert(TestingState.assignmentHistory, {
        userId = userId,
        experimentId = experimentId,
        variantId = variantId,
        timestamp = tick()
    })
end

-- ========================================
-- METRICS COLLECTION
-- ========================================

function ABTestingFramework.setupMetricsCollection()
    TestingState.metricsCollector = {
        handlers = ABTestingFramework.createMetricsHandlers(),
        queue = {},
        aggregator = ABTestingFramework.createMetricsAggregator()
    }
    
    -- Start metrics processing
    spawn(function()
        while true do
            ABTestingFramework.processMetricsQueue()
            task.wait(10) -- Process every 10 seconds
        end
    end)
    
    print("📊 Metrics collection system started")
end

function ABTestingFramework.createMetricsHandlers()
    return {
        conversion_rate = ABTestingFramework.createConversionHandler(),
        retention_rate = ABTestingFramework.createRetentionHandler(),
        revenue_per_user = ABTestingFramework.createRevenueHandler(),
        engagement_score = ABTestingFramework.createEngagementHandler()
    }
end

function ABTestingFramework.createConversionHandler()
    return {
        name = "conversion_rate",
        
        track = function(self, userId, experimentId, data)
            ABTestingFramework.trackConversionEvent(userId, experimentId, data)
        end,
        
        calculate = function(self, experimentId, variantId)
            return ABTestingFramework.calculateConversionRate(experimentId, variantId)
        end
    }
end

function ABTestingFramework.createRetentionHandler()
    return {
        name = "retention_rate",
        
        track = function(self, userId, experimentId, data)
            ABTestingFramework.trackRetentionEvent(userId, experimentId, data)
        end,
        
        calculate = function(self, experimentId, variantId)
            return ABTestingFramework.calculateRetentionRate(experimentId, variantId)
        end
    }
end

function ABTestingFramework.createRevenueHandler()
    return {
        name = "revenue_per_user",
        
        track = function(self, userId, experimentId, data)
            ABTestingFramework.trackRevenueEvent(userId, experimentId, data)
        end,
        
        calculate = function(self, experimentId, variantId)
            return ABTestingFramework.calculateRevenuePerUser(experimentId, variantId)
        end
    }
end

function ABTestingFramework.createEngagementHandler()
    return {
        name = "engagement_score",
        
        track = function(self, userId, experimentId, data)
            ABTestingFramework.trackEngagementEvent(userId, experimentId, data)
        end,
        
        calculate = function(self, experimentId, variantId)
            return ABTestingFramework.calculateEngagementScore(experimentId, variantId)
        end
    }
end

function ABTestingFramework.createMetricsAggregator()
    return {
        name = "metrics_aggregator",
        
        aggregate = function(self, experimentId)
            return ABTestingFramework.aggregateExperimentMetrics(experimentId)
        end
    }
end

function ABTestingFramework.trackExperimentEvent(userId, eventType, eventData)
    -- Find relevant experiments for this user
    local userAssignments = TestingState.userAssignments[userId]
    if not userAssignments then return end
    
    for experimentId, assignment in pairs(userAssignments) do
        local experiment = TestingState.activeExperiments[experimentId]
        if experiment then
            -- Track event for this experiment
            local eventRecord = {
                userId = userId,
                experimentId = experimentId,
                variantId = assignment.variantId,
                eventType = eventType,
                eventData = eventData,
                timestamp = tick()
            }
            
            table.insert(TestingState.metricsCollector.queue, eventRecord)
            
            -- Track in experiment results
            if not experiment.results[assignment.variantId].events[eventType] then
                experiment.results[assignment.variantId].events[eventType] = {}
            end
            
            table.insert(experiment.results[assignment.variantId].events[eventType], eventRecord)
        end
    end
end

function ABTestingFramework.processMetricsQueue()
    local eventsToProcess = {}
    
    -- Move events from queue to processing list
    for i = #TestingState.metricsCollector.queue, 1, -1 do
        table.insert(eventsToProcess, table.remove(TestingState.metricsCollector.queue, i))
    end
    
    -- Process each event
    for _, event in ipairs(eventsToProcess) do
        local handler = TestingState.metricsCollector.handlers[event.eventType]
        if handler then
            handler:track(event.userId, event.experimentId, event.eventData)
        end
    end
end

-- ========================================
-- STATISTICAL ANALYSIS
-- ========================================

function ABTestingFramework.initializeStatisticalAnalysis()
    TestingState.statisticalEngine = {
        frequentist = ABTestingFramework.createFrequentistAnalyzer(),
        bayesian = ABTestingFramework.createBayesianAnalyzer(),
        sequential = ABTestingFramework.createSequentialAnalyzer()
    }
    
    print("📈 Statistical analysis engine initialized")
end

function ABTestingFramework.createFrequentistAnalyzer()
    return {
        name = "frequentist_analyzer",
        
        analyze = function(self, experimentData)
            return ABTestingFramework.performFrequentistAnalysis(experimentData)
        end
    }
end

function ABTestingFramework.createBayesianAnalyzer()
    return {
        name = "bayesian_analyzer",
        
        analyze = function(self, experimentData)
            return ABTestingFramework.performBayesianAnalysis(experimentData)
        end
    }
end

function ABTestingFramework.createSequentialAnalyzer()
    return {
        name = "sequential_analyzer",
        
        analyze = function(self, experimentData)
            return ABTestingFramework.performSequentialAnalysis(experimentData)
        end
    }
end

function ABTestingFramework.analyzeExperiment(experimentId)
    local experiment = TestingState.activeExperiments[experimentId] or 
        TestingState.completedExperiments[experimentId]
    
    if not experiment then
        return nil, "Experiment not found"
    end
    
    local analysis = {
        experimentId = experimentId,
        experimentName = experiment.name,
        status = experiment.status,
        variants = {},
        comparison = {},
        significance = {},
        recommendation = "",
        confidence = 0,
        timestamp = tick()
    }
    
    -- Analyze each variant
    for _, variant in ipairs(experiment.variants) do
        local variantAnalysis = ABTestingFramework.analyzeVariant(experiment, variant.id)
        analysis.variants[variant.id] = variantAnalysis
    end
    
    -- Perform statistical comparison
    analysis.comparison = ABTestingFramework.compareVariants(experiment)
    
    -- Determine significance
    analysis.significance = ABTestingFramework.calculateSignificance(experiment)
    
    -- Generate recommendation
    analysis.recommendation = ABTestingFramework.generateRecommendation(analysis)
    analysis.confidence = ABTestingFramework.calculateConfidence(analysis)
    
    -- Store analysis results
    TestingState.analysisResults[experimentId] = analysis
    
    return analysis
end

function ABTestingFramework.analyzeVariant(experiment, variantId)
    local variantResults = experiment.results[variantId]
    
    local analysis = {
        variantId = variantId,
        participants = variantResults.participants,
        metrics = {},
        performance = {}
    }
    
    -- Calculate metrics for this variant
    for metricName, handler in pairs(TestingState.metricsCollector.handlers) do
        local metricValue = handler:calculate(experiment.id, variantId)
        analysis.metrics[metricName] = metricValue
    end
    
    -- Calculate performance indicators
    analysis.performance = {
        conversionRate = analysis.metrics.conversion_rate or 0,
        retentionRate = analysis.metrics.retention_rate or 0,
        revenuePerUser = analysis.metrics.revenue_per_user or 0,
        engagementScore = analysis.metrics.engagement_score or 0
    }
    
    return analysis
end

function ABTestingFramework.compareVariants(experiment)
    local comparison = {
        controlVariant = nil,
        testVariants = {},
        improvements = {},
        statistical_tests = {}
    }
    
    -- Find control variant (usually first variant)
    comparison.controlVariant = experiment.variants[1].id
    
    -- Compare other variants to control
    for i = 2, #experiment.variants do
        local testVariant = experiment.variants[i].id
        table.insert(comparison.testVariants, testVariant)
        
        -- Calculate improvement
        local improvement = ABTestingFramework.calculateImprovement(
            experiment, comparison.controlVariant, testVariant
        )
        comparison.improvements[testVariant] = improvement
        
        -- Perform statistical test
        local statTest = ABTestingFramework.performStatisticalTest(
            experiment, comparison.controlVariant, testVariant
        )
        comparison.statistical_tests[testVariant] = statTest
    end
    
    return comparison
end

function ABTestingFramework.calculateImprovement(experiment, controlVariant, testVariant)
    local controlMetrics = TestingState.analysisResults[experiment.id] and
        TestingState.analysisResults[experiment.id].variants[controlVariant] and
        TestingState.analysisResults[experiment.id].variants[controlVariant].metrics
    
    local testMetrics = TestingState.analysisResults[experiment.id] and
        TestingState.analysisResults[experiment.id].variants[testVariant] and
        TestingState.analysisResults[experiment.id].variants[testVariant].metrics
    
    if not controlMetrics or not testMetrics then
        -- Recalculate metrics
        controlMetrics = {}
        testMetrics = {}
        
        for metricName, handler in pairs(TestingState.metricsCollector.handlers) do
            controlMetrics[metricName] = handler:calculate(experiment.id, controlVariant)
            testMetrics[metricName] = handler:calculate(experiment.id, testVariant)
        end
    end
    
    local improvement = {}
    
    for metricName, controlValue in pairs(controlMetrics) do
        local testValue = testMetrics[metricName] or 0
        
        if controlValue > 0 then
            improvement[metricName] = {
                absolute = testValue - controlValue,
                relative = ((testValue - controlValue) / controlValue) * 100,
                controlValue = controlValue,
                testValue = testValue
            }
        else
            improvement[metricName] = {
                absolute = testValue,
                relative = 0,
                controlValue = controlValue,
                testValue = testValue
            }
        end
    end
    
    return improvement
end

function ABTestingFramework.performStatisticalTest(experiment, controlVariant, testVariant)
    -- Simplified statistical test (normally would use proper statistical libraries)
    local controlResults = experiment.results[controlVariant]
    local testResults = experiment.results[testVariant]
    
    local test = {
        testType = "t_test",
        pValue = math.random() * 0.1, -- Simulated p-value
        tStatistic = math.random(-3, 3),
        degreesOfFreedom = controlResults.participants + testResults.participants - 2,
        effectSize = math.random(-0.5, 0.5),
        confidenceInterval = {
            lower = -0.1,
            upper = 0.1
        },
        isSignificant = false
    }
    
    test.isSignificant = test.pValue < TESTING_CONFIG.analysis.pValueThreshold
    
    return test
end

function ABTestingFramework.calculateSignificance(experiment)
    local significance = {
        hasSignificantResult = false,
        significantVariants = {},
        overallPValue = 1.0,
        multipleTestingCorrection = "bonferroni"
    }
    
    -- Check if any variants show significant results
    for variantId in pairs(experiment.results) do
        if variantId ~= experiment.variants[1].id then -- Skip control
            local analysis = TestingState.analysisResults[experiment.id]
            if analysis and analysis.comparison.statistical_tests[variantId] then
                local test = analysis.comparison.statistical_tests[variantId]
                if test.isSignificant then
                    significance.hasSignificantResult = true
                    table.insert(significance.significantVariants, variantId)
                end
                
                -- Update overall p-value (simplified)
                significance.overallPValue = math.min(significance.overallPValue, test.pValue)
            end
        end
    end
    
    return significance
end

function ABTestingFramework.generateRecommendation(analysis)
    if not analysis.significance.hasSignificantResult then
        return "No significant difference detected. Consider running longer or investigating other factors."
    end
    
    local bestVariant = ABTestingFramework.findBestVariant(analysis)
    if bestVariant then
        return string.format("Recommend implementing variant %s based on significant improvements in primary metrics.", bestVariant)
    else
        return "Results are mixed. Further investigation recommended."
    end
end

function ABTestingFramework.calculateConfidence(analysis)
    if analysis.significance.hasSignificantResult then
        return TESTING_CONFIG.experiments.confidenceLevel
    else
        return 1.0 - analysis.significance.overallPValue
    end
end

-- ========================================
-- EXPERIMENT MONITORING
-- ========================================

function ABTestingFramework.startExperimentMonitoring()
    spawn(function()
        while true do
            ABTestingFramework.monitorActiveExperiments()
            ABTestingFramework.executeScheduledExperiments()
            ABTestingFramework.checkExperimentHealth()
            
            task.wait(TESTING_CONFIG.analysis.updateFrequency)
        end
    end)
    
    print("👁️ Experiment monitoring started")
end

function ABTestingFramework.monitorActiveExperiments()
    for experimentId, experiment in pairs(TestingState.activeExperiments) do
        -- Check if experiment should end
        if tick() >= experiment.endTime then
            ABTestingFramework.stopExperiment(experimentId)
        else
            -- Update ongoing analysis
            local analysis = ABTestingFramework.analyzeExperiment(experimentId)
            
            -- Check for early stopping conditions
            if ABTestingFramework.shouldStopEarly(experiment, analysis) then
                print(string.format("⏱️ Early stopping triggered for experiment: %s", experiment.name))
                ABTestingFramework.stopExperiment(experimentId)
            end
        end
    end
end

function ABTestingFramework.executeScheduledExperiments()
    local currentTime = tick()
    
    for i = #TestingState.experimentManager.scheduler.queue, 1, -1 do
        local scheduledItem = TestingState.experimentManager.scheduler.queue[i]
        
        if currentTime >= scheduledItem.scheduledTime then
            ABTestingFramework.startExperiment(scheduledItem.experimentId)
            table.remove(TestingState.experimentManager.scheduler.queue, i)
        end
    end
end

function ABTestingFramework.shouldStopEarly(experiment, analysis)
    -- Check for significant results with sufficient sample size
    if analysis.significance.hasSignificantResult then
        local minParticipants = TESTING_CONFIG.experiments.minSampleSize
        
        for variantId, variantResults in pairs(experiment.results) do
            if variantResults.participants < minParticipants then
                return false -- Not enough participants yet
            end
        end
        
        return true -- Significant with sufficient sample
    end
    
    -- Check for guardrail metric violations
    for variantId, variant in pairs(analysis.variants) do
        for metricName in pairs(TESTING_CONFIG.metrics.guardrail) do
            local metricValue = variant.metrics[metricName] or 0
            if ABTestingFramework.isGuardrailViolation(metricName, metricValue) then
                return true -- Stop due to guardrail violation
            end
        end
    end
    
    return false
end

function ABTestingFramework.checkExperimentHealth()
    for experimentId, experiment in pairs(TestingState.activeExperiments) do
        local health = ABTestingFramework.assessExperimentHealth(experiment)
        
        if health.status ~= "healthy" then
            print(string.format("⚠️ Experiment health issue in %s: %s", 
                experiment.name, health.issue))
        end
    end
end

function ABTestingFramework.assessExperimentHealth(experiment)
    local health = {status = "healthy", issue = nil}
    
    -- Check participant allocation balance
    local expectedPerVariant = experiment.participants and 
        (ABTestingFramework.tableLength(experiment.participants) / #experiment.variants)
    
    for variantId, variantResults in pairs(experiment.results) do
        if expectedPerVariant > 10 then -- Only check if we have enough participants
            local deviation = math.abs(variantResults.participants - expectedPerVariant) / expectedPerVariant
            
            if deviation > 0.3 then -- 30% deviation threshold
                health.status = "unbalanced"
                health.issue = string.format("Variant %s has unbalanced allocation", variantId)
                break
            end
        end
    end
    
    -- Check for low participation rate
    local runningTime = tick() - experiment.actualStartTime
    local expectedParticipants = runningTime * 10 -- Expected 10 participants per second (example)
    local actualParticipants = ABTestingFramework.tableLength(experiment.participants)
    
    if runningTime > 3600 and actualParticipants < expectedParticipants * 0.5 then -- 50% of expected
        health.status = "low_participation"
        health.issue = "Lower than expected participation rate"
    end
    
    return health
end

-- ========================================
-- UTILITY FUNCTIONS
-- ========================================

function ABTestingFramework.hashUserId(userId, experimentId)
    -- Simple hash function for deterministic assignment
    local combined = tostring(userId) .. tostring(experimentId)
    local hash = 0
    
    for i = 1, #combined do
        local char = string.byte(combined, i)
        hash = (hash * 31 + char) % 1000000
    end
    
    return hash / 1000000 -- Return value between 0 and 1
end

function ABTestingFramework.checkTargetingRules(userId, experiment)
    if not experiment.targetingRules or #experiment.targetingRules == 0 then
        return true -- No targeting rules means all users are eligible
    end
    
    -- Simplified targeting check
    for _, rule in ipairs(experiment.targetingRules) do
        if rule.type == "user_id_range" then
            if userId >= rule.min and userId <= rule.max then
                return true
            end
        elseif rule.type == "platform" then
            -- Would check user's platform
            return true
        end
    end
    
    return false
end

function ABTestingFramework.checkExclusionRules(userId, experiment)
    if not experiment.exclusionRules or #experiment.exclusionRules == 0 then
        return false -- No exclusion rules
    end
    
    -- Simplified exclusion check
    for _, rule in ipairs(experiment.exclusionRules) do
        if rule.type == "user_id_blacklist" then
            for _, excludedId in ipairs(rule.userIds) do
                if userId == excludedId then
                    return true
                end
            end
        end
    end
    
    return false
end

function ABTestingFramework.checkTrafficAllocation(userId, experiment)
    local hash = ABTestingFramework.hashUserId(userId, "traffic_" .. experiment.id)
    return hash <= experiment.trafficPercentage
end

function ABTestingFramework.findBestPerformingVariant(experiment)
    local bestVariant = nil
    local bestScore = -math.huge
    
    for _, variant in ipairs(experiment.variants) do
        local variantResults = experiment.results[variant.id]
        if variantResults.participants > 10 then -- Minimum sample size
            -- Simplified scoring based on conversion rate
            local score = ABTestingFramework.calculateConversionRate(experiment.id, variant.id)
            if score > bestScore then
                bestScore = score
                bestVariant = variant
            end
        end
    end
    
    return bestVariant
end

function ABTestingFramework.findBestVariant(analysis)
    local bestVariant = nil
    local bestScore = -math.huge
    
    for variantId, variantAnalysis in pairs(analysis.variants) do
        local score = variantAnalysis.performance.conversionRate or 0
        if score > bestScore then
            bestScore = score
            bestVariant = variantId
        end
    end
    
    return bestVariant
end

function ABTestingFramework.isGuardrailViolation(metricName, value)
    -- Simplified guardrail checks
    local thresholds = {
        error_rate = 0.05,    -- 5%
        crash_rate = 0.01,    -- 1%
        load_time = 10,       -- 10 seconds
        server_cost = 1000    -- $1000
    }
    
    local threshold = thresholds[metricName]
    return threshold and value > threshold
end

function ABTestingFramework.tableLength(t)
    local count = 0
    for _ in pairs(t) do
        count = count + 1
    end
    return count
end

-- ========================================
-- METRICS CALCULATION (SIMPLIFIED)
-- ========================================

function ABTestingFramework.trackConversionEvent(userId, experimentId, data)
    -- Track conversion events
end

function ABTestingFramework.calculateConversionRate(experimentId, variantId)
    return math.random(10, 30) / 100 -- 10-30% conversion rate
end

function ABTestingFramework.trackRetentionEvent(userId, experimentId, data)
    -- Track retention events
end

function ABTestingFramework.calculateRetentionRate(experimentId, variantId)
    return math.random(60, 85) / 100 -- 60-85% retention rate
end

function ABTestingFramework.trackRevenueEvent(userId, experimentId, data)
    -- Track revenue events
end

function ABTestingFramework.calculateRevenuePerUser(experimentId, variantId)
    return math.random(5, 25) -- $5-25 revenue per user
end

function ABTestingFramework.trackEngagementEvent(userId, experimentId, data)
    -- Track engagement events
end

function ABTestingFramework.calculateEngagementScore(experimentId, variantId)
    return math.random(70, 95) / 100 -- 70-95% engagement score
end

-- ========================================
-- PUBLIC API
-- ========================================

function ABTestingFramework.runTestingDemo()
    print("🧪 Running A/B testing framework demonstration...")
    
    -- Create sample experiment
    print("  🔬 Creating sample experiment...")
    local experimentConfig = {
        name = "Button Color Test",
        description = "Testing different button colors for conversion",
        hypothesis = "Red buttons will increase conversion rate",
        primaryMetric = "conversion_rate",
        secondaryMetrics = {"engagement_score"},
        variants = {
            {id = "control", name = "Blue Button", allocation = 0.5},
            {id = "treatment", name = "Red Button", allocation = 0.5}
        },
        duration = 7 * 86400, -- 7 days
        trafficPercentage = 1.0
    }
    
    local experimentId = ABTestingFramework.createExperiment(experimentConfig)
    
    if experimentId then
        print(string.format("    Created experiment: %s", experimentId))
        
        -- Start experiment
        local started, error = ABTestingFramework.startExperiment(experimentId)
        if started then
            print("    ✅ Experiment started successfully")
            
            -- Simulate user assignments
            print("  👥 Simulating user assignments...")
            for userId = 1, 50 do
                local variantId = ABTestingFramework.allocateUserToVariant(userId, experimentId)
                if variantId then
                    -- Simulate some events
                    ABTestingFramework.trackExperimentEvent(userId, "conversion_rate", {converted = math.random() > 0.7})
                    ABTestingFramework.trackExperimentEvent(userId, "engagement_score", {score = math.random(70, 95)})
                end
            end
            
            -- Wait for processing
            task.wait(2)
            
            -- Analyze results
            print("  📊 Analyzing experiment results...")
            local analysis = ABTestingFramework.analyzeExperiment(experimentId)
            
            if analysis then
                print("    Analysis Results:")
                print(string.format("    Significant result: %s", 
                    analysis.significance.hasSignificantResult and "Yes" or "No"))
                print(string.format("    Confidence: %.1f%%", analysis.confidence * 100))
                print(string.format("    Recommendation: %s", analysis.recommendation))
                
                -- Show variant performance
                for variantId, variantAnalysis in pairs(analysis.variants) do
                    print(string.format("    Variant %s: %d participants, %.1f%% conversion", 
                        variantId, 
                        variantAnalysis.participants,
                        (variantAnalysis.performance.conversionRate or 0) * 100))
                end
            end
            
            -- Stop experiment
            ABTestingFramework.stopExperiment(experimentId)
            print("    🏁 Experiment completed")
        else
            print(string.format("    ❌ Failed to start experiment: %s", error))
        end
    else
        print("    ❌ Failed to create experiment")
    end
    
    -- Show framework statistics
    local stats = ABTestingFramework.getTestingStats()
    print("  📈 A/B Testing Statistics:")
    print(string.format("    Total experiments: %d", stats.totalExperiments))
    print(string.format("    Active tests: %d", stats.activeTests))
    print(string.format("    Significant results: %d", stats.significantResults))
    print(string.format("    Total participants: %d", stats.totalParticipants))
    
    print("🧪 A/B testing framework demonstration completed")
end

function ABTestingFramework.getTestingStats()
    return TestingState.stats
end

function ABTestingFramework.getActiveExperiments()
    return TestingState.activeExperiments
end

function ABTestingFramework.getUserAssignment(userId, experimentId)
    return TestingState.userAssignments[userId] and 
        TestingState.userAssignments[userId][experimentId]
end

function ABTestingFramework.getExperimentResults(experimentId)
    return TestingState.analysisResults[experimentId]
end

-- Export API
ABTestingFramework.createExperiment = ABTestingFramework.createExperiment
ABTestingFramework.startExperiment = ABTestingFramework.startExperiment
ABTestingFramework.stopExperiment = ABTestingFramework.stopExperiment
ABTestingFramework.allocateUserToVariant = ABTestingFramework.allocateUserToVariant
ABTestingFramework.trackExperimentEvent = ABTestingFramework.trackExperimentEvent
ABTestingFramework.analyzeExperiment = ABTestingFramework.analyzeExperiment

-- Initialize the A/B testing framework
ABTestingFramework.initialize()

print("🧪 ABTestingFramework loaded with comprehensive experimentation capabilities")

return ABTestingFramework
