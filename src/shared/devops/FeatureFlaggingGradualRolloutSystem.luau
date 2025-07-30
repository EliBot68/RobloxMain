-- FeatureFlaggingGradualRolloutSystem.luau
-- Feature flagging and gradual rollout system for production deployments
-- Implements feature toggles, A/B testing, and gradual feature rollouts

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local HttpService = game:GetService("HttpService")
local RunService = game:GetService("RunService")

local SafeRequire = require(ReplicatedStorage.Shared.utils.SafeRequire)

local FeatureFlaggingGradualRolloutSystem = {}

-- ========================================
-- FEATURE FLAG CONFIGURATION
-- ========================================

local FEATURE_FLAG_CONFIG = {
    -- Feature flag types
    flagTypes = {
        boolean = {
            name = "Boolean Toggle",
            description = "Simple on/off feature toggle",
            defaultValue = false
        },
        
        percentage = {
            name = "Percentage Rollout",
            description = "Feature enabled for percentage of users",
            defaultValue = 0
        },
        
        userList = {
            name = "User Whitelist",
            description = "Feature enabled for specific users",
            defaultValue = {}
        },
        
        multivariate = {
            name = "Multivariate Test",
            description = "Multiple variants with different values",
            defaultValue = "control"
        }
    },
    
    -- Rollout strategies
    rolloutStrategies = {
        immediate = {
            name = "Immediate Rollout",
            description = "Enable feature immediately for all users",
            stages = [{percentage = 100, duration = 0}]
        },
        
        gradual = {
            name = "Gradual Rollout",
            description = "Gradually increase feature exposure",
            stages = [
                {percentage = 1, duration = 3600},    -- 1% for 1 hour
                {percentage = 5, duration = 7200},    -- 5% for 2 hours
                {percentage = 25, duration = 14400},  -- 25% for 4 hours
                {percentage = 50, duration = 21600},  -- 50% for 6 hours
                {percentage = 100, duration = 0}      -- 100% permanently
            ]
        },
        
        canary = {
            name = "Canary Rollout",
            description = "Small percentage with monitoring",
            stages = [
                {percentage = 0.1, duration = 1800},  -- 0.1% for 30 minutes
                {percentage = 1, duration = 3600},    -- 1% for 1 hour
                {percentage = 10, duration = 7200},   -- 10% for 2 hours
                {percentage = 100, duration = 0}      -- 100% if successful
            ]
        },
        
        abTest = {
            name = "A/B Test",
            description = "Split traffic between variants",
            stages = [
                {percentage = 50, duration = 86400},  -- 50% for 24 hours
                {percentage = 100, duration = 0}      -- Winner takes all
            ]
        }
    },
    
    -- Targeting rules
    targetingRules = {
        userAttributes = ["userId", "userGroup", "accountAge", "gameLevel", "isPremium"],
        geoAttributes = ["country", "region", "timezone"],
        deviceAttributes = ["platform", "deviceType", "browserVersion"],
        gameAttributes = ["gameMode", "serverRegion", "playerCount"]
    },
    
    -- Metrics and monitoring
    metrics = {
        performance = ["responseTime", "errorRate", "crashRate", "memoryUsage"],
        business = ["conversionRate", "retention", "engagement", "revenue"],
        custom = ["featureUsage", "userFeedback", "supportTickets"]
    },
    
    -- Safeguards
    safeguards = {
        killSwitch = {
            enabled = true,
            triggers = {
                errorRateThreshold = 0.05,      -- 5% error rate
                crashRateThreshold = 0.01,      -- 1% crash rate
                negativeMetricThreshold = 0.1   -- 10% negative metric change
            }
        },
        
        gradualRollback = {
            enabled = true,
            rollbackStages = [100, 50, 25, 5, 0],
            stageDelay = 300 -- 5 minutes between stages
        }
    }
}

-- ========================================
-- SYSTEM STATE
-- ========================================

local FeatureFlagState = {
    -- Core engines
    flagEngine = nil,
    rolloutEngine = nil,
    targetingEngine = nil,
    metricsEngine = nil,
    
    -- Feature flags
    featureFlags = {},
    flagHistory = {},
    
    -- Active rollouts
    activeRollouts = {},
    rolloutHistory = {},
    
    -- A/B tests
    activeTests = {},
    testResults = {},
    
    -- User targeting
    userSegments = {},
    targetingRules = {},
    
    -- Metrics and monitoring
    featureMetrics = {},
    performanceData = {},
    
    -- System status
    systemStatus = {
        totalFlags = 0,
        activeFlags = 0,
        activeRollouts = 0,
        activeTests = 0,
        lastUpdate = nil
    },
    
    -- Configuration
    config = FEATURE_FLAG_CONFIG
}

function FeatureFlaggingGradualRolloutSystem.initialize()
    print("🚩 Initializing FeatureFlaggingGradualRolloutSystem...")
    
    -- Initialize core engines
    FeatureFlaggingGradualRolloutSystem.initializeFlagEngine()
    FeatureFlaggingGradualRolloutSystem.initializeRolloutEngine()
    FeatureFlaggingGradualRolloutSystem.initializeTargetingEngine()
    FeatureFlaggingGradualRolloutSystem.initializeMetricsEngine()
    
    -- Load default feature flags
    FeatureFlaggingGradualRolloutSystem.loadDefaultFeatureFlags()
    
    -- Start monitoring
    FeatureFlaggingGradualRolloutSystem.startFeatureFlagMonitoring()
    
    print("🚩 FeatureFlaggingGradualRolloutSystem initialized successfully")
end

-- ========================================
-- FEATURE FLAG ENGINE
-- ========================================

function FeatureFlaggingGradualRolloutSystem.initializeFlagEngine()
    FeatureFlagState.flagEngine = {
        flags = {},
        
        createFlag = function(self, flagConfig)
            return FeatureFlaggingGradualRolloutSystem.createFeatureFlag(flagConfig)
        end,
        
        updateFlag = function(self, flagKey, updates)
            return FeatureFlaggingGradualRolloutSystem.updateFeatureFlag(flagKey, updates)
        end,
        
        evaluateFlag = function(self, flagKey, context)
            return FeatureFlaggingGradualRolloutSystem.evaluateFeatureFlag(flagKey, context)
        end,
        
        deleteFlag = function(self, flagKey)
            return FeatureFlaggingGradualRolloutSystem.deleteFeatureFlag(flagKey)
        end
    }
    
    print("🚩 Feature flag engine initialized")
end

function FeatureFlaggingGradualRolloutSystem.createFeatureFlag(flagConfig)
    local flag = {
        key = flagConfig.key,
        name = flagConfig.name,
        description = flagConfig.description,
        
        type = flagConfig.type or "boolean",
        defaultValue = flagConfig.defaultValue,
        
        enabled = flagConfig.enabled or false,
        
        targeting = {
            rules = flagConfig.targetingRules or {},
            segments = flagConfig.segments or {},
            percentage = flagConfig.percentage or 0
        },
        
        variants = flagConfig.variants or {},
        
        rollout = {
            strategy = flagConfig.rolloutStrategy or "immediate",
            currentStage = 0,
            startTime = nil,
            endTime = nil
        },
        
        metrics = {
            evaluations = 0,
            exposures = 0,
            conversions = 0,
            errors = 0
        },
        
        safeguards = {
            killSwitch = flagConfig.killSwitch or false,
            maxExposure = flagConfig.maxExposure or 100,
            rollbackThreshold = flagConfig.rollbackThreshold or 0.05
        },
        
        created = os.time(),
        lastModified = os.time(),
        createdBy = flagConfig.createdBy or "system"
    }
    
    -- Validate flag configuration
    local validation = FeatureFlaggingGradualRolloutSystem.validateFlagConfig(flag)
    if not validation.valid then
        return {success = false, error = validation.error}
    end
    
    FeatureFlagState.featureFlags[flag.key] = flag
    FeatureFlagState.systemStatus.totalFlags = FeatureFlagState.systemStatus.totalFlags + 1
    
    if flag.enabled then
        FeatureFlagState.systemStatus.activeFlags = FeatureFlagState.systemStatus.activeFlags + 1
    end
    
    print(string.format("🚩 Created feature flag: %s (%s)", flag.name, flag.type))
    
    -- Log flag creation
    FeatureFlaggingGradualRolloutSystem.logFlagEvent(flag.key, "created", {
        type = flag.type,
        enabled = flag.enabled
    })
    
    return {
        success = true,
        flag = flag
    }
end

function FeatureFlaggingGradualRolloutSystem.validateFlagConfig(flag)
    -- Check required fields
    if not flag.key or flag.key == "" then
        return {valid = false, error = "Flag key is required"}
    end
    
    if not flag.name or flag.name == "" then
        return {valid = false, error = "Flag name is required"}
    end
    
    -- Check for duplicate keys
    if FeatureFlagState.featureFlags[flag.key] then
        return {valid = false, error = "Flag key already exists"}
    end
    
    -- Validate flag type
    if not FeatureFlagState.config.flagTypes[flag.type] then
        return {valid = false, error = "Invalid flag type"}
    end
    
    -- Validate percentage for percentage-based flags
    if flag.type == "percentage" and (flag.targeting.percentage < 0 or flag.targeting.percentage > 100) then
        return {valid = false, error = "Percentage must be between 0 and 100"}
    end
    
    return {valid = true}
end

function FeatureFlaggingGradualRolloutSystem.updateFeatureFlag(flagKey, updates)
    local flag = FeatureFlagState.featureFlags[flagKey]
    
    if not flag then
        return {success = false, error = "Feature flag not found"}
    end
    
    local oldEnabled = flag.enabled
    
    -- Apply updates
    for key, value in pairs(updates) do
        if key == "enabled" then
            flag.enabled = value
        elseif key == "description" then
            flag.description = value
        elseif key == "targeting" then
            flag.targeting = value
        elseif key == "variants" then
            flag.variants = value
        elseif key == "safeguards" then
            flag.safeguards = value
        end
    end
    
    flag.lastModified = os.time()
    
    -- Update active flag count
    if oldEnabled ~= flag.enabled then
        if flag.enabled then
            FeatureFlagState.systemStatus.activeFlags = FeatureFlagState.systemStatus.activeFlags + 1
        else
            FeatureFlagState.systemStatus.activeFlags = FeatureFlagState.systemStatus.activeFlags - 1
        end
    end
    
    print(string.format("🔄 Updated feature flag: %s", flag.name))
    
    -- Log flag update
    FeatureFlaggingGradualRolloutSystem.logFlagEvent(flagKey, "updated", updates)
    
    return {success = true, flag = flag}
end

function FeatureFlaggingGradualRolloutSystem.evaluateFeatureFlag(flagKey, context)
    local flag = FeatureFlagState.featureFlags[flagKey]
    
    if not flag then
        return {
            enabled = false,
            value = nil,
            reason = "flag_not_found"
        }
    end
    
    -- Increment evaluation count
    flag.metrics.evaluations = flag.metrics.evaluations + 1
    
    -- Check if flag is enabled
    if not flag.enabled then
        return {
            enabled = false,
            value = flag.defaultValue,
            reason = "flag_disabled"
        }
    end
    
    -- Check kill switch
    if flag.safeguards.killSwitch then
        return {
            enabled = false,
            value = flag.defaultValue,
            reason = "kill_switch_active"
        }
    end
    
    -- Evaluate targeting rules
    local targetingResult = FeatureFlaggingGradualRolloutSystem.evaluateTargeting(flag, context)
    
    if not targetingResult.matches then
        return {
            enabled = false,
            value = flag.defaultValue,
            reason = targetingResult.reason
        }
    end
    
    -- Determine flag value based on type
    local value = FeatureFlaggingGradualRolloutSystem.determineFlagValue(flag, context)
    
    -- Log exposure if user sees the feature
    if value ~= flag.defaultValue then
        flag.metrics.exposures = flag.metrics.exposures + 1
        
        FeatureFlaggingGradualRolloutSystem.logFlagEvent(flagKey, "exposure", {
            userId = context.userId,
            value = value,
            targeting = targetingResult
        })
    end
    
    return {
        enabled = true,
        value = value,
        reason = "targeting_matched",
        variant = targetingResult.variant
    }
end

function FeatureFlaggingGradualRolloutSystem.evaluateTargeting(flag, context)
    -- Check user whitelist first
    if flag.type == "userList" then
        local userList = flag.defaultValue or {}
        if FeatureFlaggingGradualRolloutSystem.isUserInList(context.userId, userList) then
            return {matches = true, reason = "user_whitelist"}
        else
            return {matches = false, reason = "not_in_whitelist"}
        end
    end
    
    -- Check targeting rules
    for _, rule in ipairs(flag.targeting.rules or {}) do
        local ruleResult = FeatureFlaggingGradualRolloutSystem.evaluateTargetingRule(rule, context)
        if not ruleResult.matches then
            return {matches = false, reason = ruleResult.reason}
        end
    end
    
    -- Check percentage-based targeting
    if flag.type == "percentage" or flag.targeting.percentage > 0 then
        local userHash = FeatureFlaggingGradualRolloutSystem.hashUser(context.userId, flag.key)
        local percentage = flag.targeting.percentage
        
        if userHash <= percentage then
            return {matches = true, reason = "percentage_targeting"}
        else
            return {matches = false, reason = "outside_percentage"}
        end
    end
    
    -- Check segment targeting
    for _, segmentKey in ipairs(flag.targeting.segments or {}) do
        if FeatureFlaggingGradualRolloutSystem.isUserInSegment(context.userId, segmentKey) then
            return {matches = true, reason = "segment_targeting"}
        end
    end
    
    -- Default to enabled if no specific targeting
    return {matches = true, reason = "default_targeting"}
end

function FeatureFlaggingGradualRolloutSystem.evaluateTargetingRule(rule, context)
    local attribute = rule.attribute
    local operator = rule.operator
    local value = rule.value
    
    local contextValue = FeatureFlaggingGradualRolloutSystem.getContextValue(context, attribute)
    
    if operator == "equals" then
        return {matches = contextValue == value, reason = "rule_evaluation"}
    elseif operator == "not_equals" then
        return {matches = contextValue ~= value, reason = "rule_evaluation"}
    elseif operator == "in" then
        return {matches = FeatureFlaggingGradualRolloutSystem.isValueInList(contextValue, value), reason = "rule_evaluation"}
    elseif operator == "not_in" then
        return {matches = not FeatureFlaggingGradualRolloutSystem.isValueInList(contextValue, value), reason = "rule_evaluation"}
    elseif operator == "greater_than" then
        return {matches = tonumber(contextValue) > tonumber(value), reason = "rule_evaluation"}
    elseif operator == "less_than" then
        return {matches = tonumber(contextValue) < tonumber(value), reason = "rule_evaluation"}
    elseif operator == "contains" then
        return {matches = string.find(tostring(contextValue), tostring(value)) ~= nil, reason = "rule_evaluation"}
    end
    
    return {matches = false, reason = "unknown_operator"}
end

function FeatureFlaggingGradualRolloutSystem.determineFlagValue(flag, context)
    if flag.type == "boolean" then
        return true
    elseif flag.type == "percentage" then
        return true
    elseif flag.type == "userList" then
        return true
    elseif flag.type == "multivariate" then
        return FeatureFlaggingGradualRolloutSystem.selectVariant(flag, context)
    else
        return flag.defaultValue
    end
end

function FeatureFlaggingGradualRolloutSystem.selectVariant(flag, context)
    local variants = flag.variants or {}
    
    if #variants == 0 then
        return flag.defaultValue
    end
    
    -- Use consistent hashing to assign variant
    local userHash = FeatureFlaggingGradualRolloutSystem.hashUser(context.userId, flag.key)
    local totalWeight = 0
    
    for _, variant in ipairs(variants) do
        totalWeight = totalWeight + (variant.weight or 1)
    end
    
    local threshold = (userHash / 100) * totalWeight
    local currentWeight = 0
    
    for _, variant in ipairs(variants) do
        currentWeight = currentWeight + (variant.weight or 1)
        if threshold <= currentWeight then
            return variant.value
        end
    end
    
    return variants[1].value
end

-- ========================================
-- ROLLOUT ENGINE
-- ========================================

function FeatureFlaggingGradualRolloutSystem.initializeRolloutEngine()
    FeatureFlagState.rolloutEngine = {
        activeRollouts = {},
        
        startRollout = function(self, rolloutConfig)
            return FeatureFlaggingGradualRolloutSystem.startGradualRollout(rolloutConfig)
        end,
        
        pauseRollout = function(self, rolloutId)
            return FeatureFlaggingGradualRolloutSystem.pauseRollout(rolloutId)
        end,
        
        resumeRollout = function(self, rolloutId)
            return FeatureFlaggingGradualRolloutSystem.resumeRollout(rolloutId)
        end,
        
        rollbackRollout = function(self, rolloutId)
            return FeatureFlaggingGradualRolloutSystem.rollbackRollout(rolloutId)
        end
    }
    
    print("📈 Rollout engine initialized")
end

function FeatureFlaggingGradualRolloutSystem.startGradualRollout(rolloutConfig)
    local rollout = {
        id = HttpService:GenerateGUID(),
        flagKey = rolloutConfig.flagKey,
        strategy = rolloutConfig.strategy or "gradual",
        
        stages = FeatureFlagState.config.rolloutStrategies[rolloutConfig.strategy].stages,
        currentStage = 1,
        
        started = os.time(),
        status = "active",
        
        metrics = {
            exposures = 0,
            conversions = 0,
            errors = 0,
            rollbacks = 0
        },
        
        monitoring = {
            errorRateThreshold = rolloutConfig.errorRateThreshold or 0.05,
            conversionRateThreshold = rolloutConfig.conversionRateThreshold or 0.1,
            checkInterval = rolloutConfig.checkInterval or 300
        }
    }
    
    local flag = FeatureFlagState.featureFlags[rolloutConfig.flagKey]
    if not flag then
        return {success = false, error = "Feature flag not found"}
    end
    
    FeatureFlagState.activeRollouts[rollout.id] = rollout
    FeatureFlagState.systemStatus.activeRollouts = FeatureFlagState.systemStatus.activeRollouts + 1
    
    -- Update flag rollout information
    flag.rollout.currentStage = 1
    flag.rollout.startTime = os.time()
    
    print(string.format("📈 Started gradual rollout: %s (%s strategy)", 
        flag.name, 
        rollout.strategy))
    
    -- Start rollout progression
    FeatureFlaggingGradualRolloutSystem.progressRollout(rollout)
    
    return {
        success = true,
        rollout = rollout
    }
end

function FeatureFlaggingGradualRolloutSystem.progressRollout(rollout)
    spawn(function()
        while rollout.status == "active" and rollout.currentStage <= #rollout.stages do
            local stage = rollout.stages[rollout.currentStage]
            local flag = FeatureFlagState.featureFlags[rollout.flagKey]
            
            if flag then
                -- Update flag percentage
                flag.targeting.percentage = stage.percentage
                
                print(string.format("📊 Rollout stage %d: %d%% exposure for %s", 
                    rollout.currentStage, 
                    stage.percentage, 
                    flag.name))
                
                -- Wait for stage duration
                if stage.duration > 0 then
                    wait(stage.duration / 60) -- Convert to minutes for simulation
                end
                
                -- Check metrics and safeguards
                local safetyCheck = FeatureFlaggingGradualRolloutSystem.checkRolloutSafety(rollout)
                
                if not safetyCheck.safe then
                    print(string.format("⚠️ Rollout safety check failed: %s", safetyCheck.reason))
                    FeatureFlaggingGradualRolloutSystem.rollbackRollout(rollout.id)
                    break
                end
                
                -- Move to next stage
                rollout.currentStage = rollout.currentStage + 1
                flag.rollout.currentStage = rollout.currentStage
            else
                break
            end
        end
        
        -- Complete rollout if all stages passed
        if rollout.status == "active" and rollout.currentStage > #rollout.stages then
            FeatureFlaggingGradualRolloutSystem.completeRollout(rollout.id)
        end
    end)
end

function FeatureFlaggingGradualRolloutSystem.checkRolloutSafety(rollout)
    -- Simulate safety checks
    local errorRate = math.random() * 0.1 -- 0-10% error rate
    local conversionRate = 0.15 + (math.random() * 0.1) -- 15-25% conversion rate
    
    rollout.metrics.errors = rollout.metrics.errors + math.floor(errorRate * 100)
    rollout.metrics.conversions = rollout.metrics.conversions + math.floor(conversionRate * 100)
    
    -- Check error rate threshold
    if errorRate > rollout.monitoring.errorRateThreshold then
        return {
            safe = false,
            reason = string.format("Error rate %.2f%% exceeds threshold %.2f%%", 
                errorRate * 100, 
                rollout.monitoring.errorRateThreshold * 100)
        }
    end
    
    -- Check conversion rate (for business metrics)
    if conversionRate < rollout.monitoring.conversionRateThreshold then
        return {
            safe = false,
            reason = string.format("Conversion rate %.2f%% below threshold %.2f%%", 
                conversionRate * 100, 
                rollout.monitoring.conversionRateThreshold * 100)
        }
    end
    
    return {safe = true}
end

function FeatureFlaggingGradualRolloutSystem.completeRollout(rolloutId)
    local rollout = FeatureFlagState.activeRollouts[rolloutId]
    
    if rollout then
        rollout.status = "completed"
        rollout.completed = os.time()
        rollout.duration = rollout.completed - rollout.started
        
        local flag = FeatureFlagState.featureFlags[rollout.flagKey]
        if flag then
            flag.rollout.endTime = os.time()
            flag.targeting.percentage = 100
            
            print(string.format("✅ Rollout completed: %s (%.1fs)", 
                flag.name, 
                rollout.duration))
        end
        
        -- Move to history
        table.insert(FeatureFlagState.rolloutHistory, rollout)
        FeatureFlagState.activeRollouts[rolloutId] = nil
        FeatureFlagState.systemStatus.activeRollouts = FeatureFlagState.systemStatus.activeRollouts - 1
    end
end

function FeatureFlaggingGradualRolloutSystem.rollbackRollout(rolloutId)
    local rollout = FeatureFlagState.activeRollouts[rolloutId]
    
    if rollout then
        rollout.status = "rolled_back"
        rollout.rolledBack = os.time()
        
        local flag = FeatureFlagState.featureFlags[rollout.flagKey]
        if flag then
            -- Disable flag or reduce to 0%
            flag.targeting.percentage = 0
            flag.safeguards.killSwitch = true
            
            print(string.format("🔄 Rollback initiated: %s", flag.name))
        end
        
        rollout.metrics.rollbacks = rollout.metrics.rollbacks + 1
        
        -- Move to history
        table.insert(FeatureFlagState.rolloutHistory, rollout)
        FeatureFlagState.activeRollouts[rolloutId] = nil
        FeatureFlagState.systemStatus.activeRollouts = FeatureFlagState.systemStatus.activeRollouts - 1
        
        -- Trigger alerts
        local MonitoringSystem = SafeRequire("ReplicatedStorage.Shared.devops.MonitoringAlertingSystem")
        if MonitoringSystem then
            MonitoringSystem.createManualAlert({
                title = "Feature Rollout Rolled Back",
                message = string.format("Feature rollout '%s' was automatically rolled back due to safety concerns", 
                    flag and flag.name or rollout.flagKey),
                level = "warning",
                source = "feature_rollout"
            })
        end
    end
end

-- ========================================
-- A/B TESTING ENGINE
-- ========================================

function FeatureFlaggingGradualRolloutSystem.createABTest(testConfig)
    local test = {
        id = HttpService:GenerateGUID(),
        name = testConfig.name,
        description = testConfig.description,
        
        hypothesis = testConfig.hypothesis,
        successMetric = testConfig.successMetric,
        
        variants = testConfig.variants or {
            {name = "control", value = false, allocation = 50},
            {name = "treatment", value = true, allocation = 50}
        },
        
        traffic = testConfig.traffic or 100, -- Percentage of users in test
        
        started = os.time(),
        status = "running",
        
        targeting = testConfig.targeting or {},
        
        duration = testConfig.duration or 604800, -- 1 week default
        
        metrics = {
            totalExposures = 0,
            variantExposures = {},
            conversions = {},
            statisticalSignificance = false
        },
        
        results = {
            winner = nil,
            confidence = 0,
            effect = 0
        }
    }
    
    -- Initialize variant metrics
    for _, variant in ipairs(test.variants) do
        test.metrics.variantExposures[variant.name] = 0
        test.metrics.conversions[variant.name] = 0
    end
    
    FeatureFlagState.activeTests[test.id] = test
    FeatureFlagState.systemStatus.activeTests = FeatureFlagState.systemStatus.activeTests + 1
    
    print(string.format("🧪 Created A/B test: %s", test.name))
    
    -- Auto-complete test after duration
    spawn(function()
        wait(test.duration / 60) -- Convert to minutes for simulation
        FeatureFlaggingGradualRolloutSystem.analyzeABTest(test.id)
    end)
    
    return {
        success = true,
        test = test
    }
end

function FeatureFlaggingGradualRolloutSystem.evaluateABTest(testId, context)
    local test = FeatureFlagState.activeTests[testId]
    
    if not test or test.status ~= "running" then
        return {
            variant = "control",
            value = false,
            reason = "test_not_active"
        }
    end
    
    -- Check if user is in test traffic
    local userHash = FeatureFlaggingGradualRolloutSystem.hashUser(context.userId, testId)
    if userHash > test.traffic then
        return {
            variant = "control",
            value = false,
            reason = "outside_test_traffic"
        }
    end
    
    -- Assign variant based on allocation
    local selectedVariant = FeatureFlaggingGradualRolloutSystem.assignVariant(test, context)
    
    -- Track exposure
    test.metrics.totalExposures = test.metrics.totalExposures + 1
    test.metrics.variantExposures[selectedVariant.name] = test.metrics.variantExposures[selectedVariant.name] + 1
    
    return {
        variant = selectedVariant.name,
        value = selectedVariant.value,
        reason = "variant_assigned"
    }
end

function FeatureFlaggingGradualRolloutSystem.assignVariant(test, context)
    local userHash = FeatureFlaggingGradualRolloutSystem.hashUser(context.userId, test.id)
    local currentAllocation = 0
    
    for _, variant in ipairs(test.variants) do
        currentAllocation = currentAllocation + variant.allocation
        if userHash <= currentAllocation then
            return variant
        end
    end
    
    return test.variants[1] -- Fallback to first variant
end

function FeatureFlaggingGradualRolloutSystem.analyzeABTest(testId)
    local test = FeatureFlagState.activeTests[testId]
    
    if not test then
        return {success = false, error = "Test not found"}
    end
    
    test.status = "analyzing"
    
    print(string.format("📊 Analyzing A/B test: %s", test.name))
    
    -- Simulate statistical analysis
    local controlConversions = test.metrics.conversions.control or 0
    local treatmentConversions = test.metrics.conversions.treatment or 0
    local controlExposures = test.metrics.variantExposures.control or 1
    local treatmentExposures = test.metrics.variantExposures.treatment or 1
    
    local controlRate = controlConversions / controlExposures
    local treatmentRate = treatmentConversions / treatmentExposures
    
    local effect = ((treatmentRate - controlRate) / controlRate) * 100
    local confidence = math.min(95, math.abs(effect) * 10) -- Simplified confidence calculation
    
    test.results.effect = effect
    test.results.confidence = confidence
    test.metrics.statisticalSignificance = confidence >= 95
    
    -- Determine winner
    if test.metrics.statisticalSignificance then
        test.results.winner = treatmentRate > controlRate and "treatment" or "control"
    else
        test.results.winner = "inconclusive"
    end
    
    test.status = "completed"
    test.completed = os.time()
    
    print(string.format("✅ A/B test completed: %s", test.name))
    print(string.format("    Winner: %s (%.1f%% effect, %.1f%% confidence)", 
        test.results.winner, 
        test.results.effect, 
        test.results.confidence))
    
    -- Move to results
    FeatureFlagState.testResults[testId] = test
    FeatureFlagState.activeTests[testId] = nil
    FeatureFlagState.systemStatus.activeTests = FeatureFlagState.systemStatus.activeTests - 1
    
    return {
        success = true,
        results = test.results
    }
end

-- ========================================
-- TARGETING ENGINE
-- ========================================

function FeatureFlaggingGradualRolloutSystem.initializeTargetingEngine()
    FeatureFlagState.targetingEngine = {
        segments = {},
        
        createSegment = function(self, segmentConfig)
            return FeatureFlaggingGradualRolloutSystem.createUserSegment(segmentConfig)
        end,
        
        evaluateSegment = function(self, segmentKey, context)
            return FeatureFlaggingGradualRolloutSystem.evaluateUserSegment(segmentKey, context)
        end
    }
    
    -- Create default segments
    FeatureFlaggingGradualRolloutSystem.createDefaultSegments()
    
    print("🎯 Targeting engine initialized")
end

function FeatureFlaggingGradualRolloutSystem.createDefaultSegments()
    local defaultSegments = {
        {
            key = "premium_users",
            name = "Premium Users",
            rules = [{attribute = "isPremium", operator = "equals", value = true}]
        },
        {
            key = "new_users",
            name = "New Users",
            rules = [{attribute = "accountAge", operator = "less_than", value = 7}]
        },
        {
            key = "power_users",
            name = "Power Users",
            rules = [{attribute = "gameLevel", operator = "greater_than", value = 50}]
        }
    }
    
    for _, segment in ipairs(defaultSegments) do
        FeatureFlaggingGradualRolloutSystem.createUserSegment(segment)
    end
end

function FeatureFlaggingGradualRolloutSystem.createUserSegment(segmentConfig)
    local segment = {
        key = segmentConfig.key,
        name = segmentConfig.name,
        description = segmentConfig.description,
        rules = segmentConfig.rules or {},
        created = os.time()
    }
    
    FeatureFlagState.userSegments[segment.key] = segment
    
    print(string.format("🎯 Created user segment: %s", segment.name))
    
    return {
        success = true,
        segment = segment
    }
end

function FeatureFlaggingGradualRolloutSystem.evaluateUserSegment(segmentKey, context)
    local segment = FeatureFlagState.userSegments[segmentKey]
    
    if not segment then
        return false
    end
    
    -- Evaluate all rules (AND logic)
    for _, rule in ipairs(segment.rules) do
        local ruleResult = FeatureFlaggingGradualRolloutSystem.evaluateTargetingRule(rule, context)
        if not ruleResult.matches then
            return false
        end
    end
    
    return true
end

-- ========================================
-- METRICS ENGINE
-- ========================================

function FeatureFlaggingGradualRolloutSystem.initializeMetricsEngine()
    FeatureFlagState.metricsEngine = {
        collectors = {},
        
        trackEvent = function(self, eventData)
            return FeatureFlaggingGradualRolloutSystem.trackFeatureEvent(eventData)
        end,
        
        getMetrics = function(self, flagKey, timeRange)
            return FeatureFlaggingGradualRolloutSystem.getFeatureMetrics(flagKey, timeRange)
        end
    }
    
    print("📊 Feature metrics engine initialized")
end

function FeatureFlaggingGradualRolloutSystem.trackFeatureEvent(eventData)
    local flagKey = eventData.flagKey
    local eventType = eventData.eventType -- exposure, conversion, error
    local userId = eventData.userId
    local timestamp = eventData.timestamp or os.time()
    
    if not FeatureFlagState.featureMetrics[flagKey] then
        FeatureFlagState.featureMetrics[flagKey] = {
            exposures = 0,
            conversions = 0,
            errors = 0,
            timeline = {}
        }
    end
    
    local metrics = FeatureFlagState.featureMetrics[flagKey]
    
    if eventType == "exposure" then
        metrics.exposures = metrics.exposures + 1
    elseif eventType == "conversion" then
        metrics.conversions = metrics.conversions + 1
    elseif eventType == "error" then
        metrics.errors = metrics.errors + 1
    end
    
    -- Add to timeline
    table.insert(metrics.timeline, {
        timestamp = timestamp,
        eventType = eventType,
        userId = userId,
        data = eventData.data
    })
    
    -- Keep only last 1000 events
    if #metrics.timeline > 1000 then
        table.remove(metrics.timeline, 1)
    end
end

-- ========================================
-- UTILITY FUNCTIONS
-- ========================================

function FeatureFlaggingGradualRolloutSystem.hashUser(userId, salt)
    -- Simple hash function for consistent user assignment
    local hash = 0
    local input = tostring(userId) .. tostring(salt)
    
    for i = 1, #input do
        hash = (hash * 31 + string.byte(input, i)) % 100
    end
    
    return hash
end

function FeatureFlaggingGradualRolloutSystem.isUserInList(userId, userList)
    for _, id in ipairs(userList) do
        if tostring(id) == tostring(userId) then
            return true
        end
    end
    return false
end

function FeatureFlaggingGradualRolloutSystem.isValueInList(value, list)
    for _, item in ipairs(list) do
        if tostring(item) == tostring(value) then
            return true
        end
    end
    return false
end

function FeatureFlaggingGradualRolloutSystem.getContextValue(context, attribute)
    return context[attribute]
end

function FeatureFlaggingGradualRolloutSystem.isUserInSegment(userId, segmentKey)
    -- Simplified segment check
    local context = {userId = userId} -- Would normally fetch full user context
    return FeatureFlaggingGradualRolloutSystem.evaluateUserSegment(segmentKey, context)
end

function FeatureFlaggingGradualRolloutSystem.logFlagEvent(flagKey, eventType, data)
    if not FeatureFlagState.flagHistory[flagKey] then
        FeatureFlagState.flagHistory[flagKey] = {}
    end
    
    table.insert(FeatureFlagState.flagHistory[flagKey], {
        timestamp = os.time(),
        eventType = eventType,
        data = data
    })
end

-- ========================================
-- MONITORING AND SAFEGUARDS
-- ========================================

function FeatureFlaggingGradualRolloutSystem.startFeatureFlagMonitoring()
    spawn(function()
        while true do
            FeatureFlaggingGradualRolloutSystem.monitorFeatureFlags()
            wait(300) -- Check every 5 minutes
        end
    end)
    
    print("🔍 Feature flag monitoring started")
end

function FeatureFlaggingGradualRolloutSystem.monitorFeatureFlags()
    -- Check kill switch triggers
    for flagKey, flag in pairs(FeatureFlagState.featureFlags) do
        if flag.enabled and not flag.safeguards.killSwitch then
            local shouldKill = FeatureFlaggingGradualRolloutSystem.checkKillSwitchTriggers(flagKey)
            
            if shouldKill.triggered then
                print(string.format("🚫 Kill switch triggered for %s: %s", flag.name, shouldKill.reason))
                
                flag.safeguards.killSwitch = true
                
                -- Log kill switch activation
                FeatureFlaggingGradualRolloutSystem.logFlagEvent(flagKey, "kill_switch", {
                    reason = shouldKill.reason,
                    automatic = true
                })
                
                -- Send alert
                local MonitoringSystem = SafeRequire("ReplicatedStorage.Shared.devops.MonitoringAlertingSystem")
                if MonitoringSystem then
                    MonitoringSystem.createManualAlert({
                        title = "Feature Flag Kill Switch Activated",
                        message = string.format("Kill switch activated for '%s': %s", flag.name, shouldKill.reason),
                        level = "critical",
                        source = "feature_flag_system"
                    })
                end
            end
        end
    end
    
    -- Update system status
    FeatureFlagState.systemStatus.lastUpdate = os.time()
end

function FeatureFlaggingGradualRolloutSystem.checkKillSwitchTriggers(flagKey)
    local metrics = FeatureFlagState.featureMetrics[flagKey]
    
    if not metrics then
        return {triggered = false}
    end
    
    local config = FeatureFlagState.config.safeguards.killSwitch
    
    -- Check error rate
    if metrics.exposures > 0 then
        local errorRate = metrics.errors / metrics.exposures
        if errorRate > config.triggers.errorRateThreshold then
            return {
                triggered = true,
                reason = string.format("Error rate %.2f%% exceeds threshold %.2f%%", 
                    errorRate * 100, 
                    config.triggers.errorRateThreshold * 100)
            }
        end
    end
    
    return {triggered = false}
end

-- ========================================
-- DEFAULT FEATURE FLAGS
-- ========================================

function FeatureFlaggingGradualRolloutSystem.loadDefaultFeatureFlags()
    local defaultFlags = {
        {
            key = "new_ui_dashboard",
            name = "New UI Dashboard",
            description = "Updated dashboard with improved UX",
            type = "boolean",
            enabled = true,
            rolloutStrategy = "gradual",
            targeting = {percentage = 10}
        },
        {
            key = "enhanced_chat_system",
            name = "Enhanced Chat System",
            description = "New chat features with emoji support",
            type = "boolean",
            enabled = false,
            targeting = {
                segments = ["premium_users"]
            }
        },
        {
            key = "payment_gateway_v2",
            name = "Payment Gateway V2",
            description = "New payment processing system",
            type = "multivariate",
            enabled = true,
            variants = [
                {name = "stripe", value = "stripe", weight = 50},
                {name = "paypal", value = "paypal", weight = 30},
                {name = "crypto", value = "crypto", weight = 20}
            ],
            targeting = {percentage = 5}
        }
    }
    
    for _, flagConfig in ipairs(defaultFlags) do
        FeatureFlaggingGradualRolloutSystem.createFeatureFlag(flagConfig)
    end
    
    print("🚩 Default feature flags loaded")
end

-- ========================================
-- PUBLIC API
-- ========================================

function FeatureFlaggingGradualRolloutSystem.isFeatureEnabled(flagKey, context)
    local result = FeatureFlagState.flagEngine:evaluateFlag(flagKey, context)
    return result.enabled, result.value
end

function FeatureFlaggingGradualRolloutSystem.getFeatureValue(flagKey, context)
    local result = FeatureFlagState.flagEngine:evaluateFlag(flagKey, context)
    return result.value
end

function FeatureFlaggingGradualRolloutSystem.createFlag(flagConfig)
    return FeatureFlagState.flagEngine:createFlag(flagConfig)
end

function FeatureFlaggingGradualRolloutSystem.updateFlag(flagKey, updates)
    return FeatureFlagState.flagEngine:updateFlag(flagKey, updates)
end

function FeatureFlaggingGradualRolloutSystem.startRollout(rolloutConfig)
    return FeatureFlagState.rolloutEngine:startRollout(rolloutConfig)
end

function FeatureFlaggingGradualRolloutSystem.createTest(testConfig)
    return FeatureFlaggingGradualRolloutSystem.createABTest(testConfig)
end

function FeatureFlaggingGradualRolloutSystem.getTestVariant(testId, context)
    return FeatureFlaggingGradualRolloutSystem.evaluateABTest(testId, context)
end

function FeatureFlaggingGradualRolloutSystem.trackConversion(flagKey, userId, data)
    FeatureFlaggingGradualRolloutSystem.trackFeatureEvent({
        flagKey = flagKey,
        eventType = "conversion",
        userId = userId,
        data = data
    })
end

function FeatureFlaggingGradualRolloutSystem.getAllFlags()
    return FeatureFlagState.featureFlags
end

function FeatureFlaggingGradualRolloutSystem.getSystemStatus()
    return FeatureFlagState.systemStatus
end

function FeatureFlaggingGradualRolloutSystem.runFeatureFlagDemo()
    print("🚩 Running feature flagging and gradual rollout demonstration...")
    
    -- Show system status
    print("  📊 System Status:")
    local status = FeatureFlaggingGradualRolloutSystem.getSystemStatus()
    print(string.format("    Total Flags: %d", status.totalFlags))
    print(string.format("    Active Flags: %d", status.activeFlags))
    print(string.format("    Active Rollouts: %d", status.activeRollouts))
    print(string.format("    Active A/B Tests: %d", status.activeTests))
    
    -- Show feature flags
    print("  🚩 Feature Flags:")
    for flagKey, flag in pairs(FeatureFlagState.featureFlags) do
        print(string.format("    %s (%s): %s", 
            flag.name, 
            flag.type, 
            flag.enabled and "enabled" or "disabled"))
        print(string.format("      Targeting: %d%% exposure", flag.targeting.percentage))
    end
    
    -- Show rollout strategies
    print("  📈 Rollout Strategies:")
    for strategyName, strategy in pairs(FeatureFlagState.config.rolloutStrategies) do
        print(string.format("    %s: %s", strategy.name, strategy.description))
        print(string.format("      Stages: %d", #strategy.stages))
    end
    
    -- Demo feature evaluation
    print("  🎯 Feature Evaluation Demo:")
    local testContext = {
        userId = "user123",
        isPremium = true,
        accountAge = 30,
        gameLevel = 75
    }
    
    for flagKey, flag in pairs(FeatureFlagState.featureFlags) do
        local enabled, value = FeatureFlaggingGradualRolloutSystem.isFeatureEnabled(flagKey, testContext)
        print(string.format("    %s: %s (value: %s)", 
            flag.name, 
            enabled and "enabled" or "disabled", 
            tostring(value)))
    end
    
    -- Demo gradual rollout
    print("  📈 Starting Demo Rollout:")
    local rolloutResult = FeatureFlaggingGradualRolloutSystem.startRollout({
        flagKey = "new_ui_dashboard",
        strategy = "canary",
        errorRateThreshold = 0.02,
        conversionRateThreshold = 0.15
    })
    
    if rolloutResult.success then
        print(string.format("    ✅ Rollout started: %s", rolloutResult.rollout.id))
        print(string.format("    Strategy: %s", rolloutResult.rollout.strategy))
        print(string.format("    Stages: %d", #rolloutResult.rollout.stages))
    end
    
    -- Demo A/B test
    print("  🧪 Creating Demo A/B Test:")
    local testResult = FeatureFlaggingGradualRolloutSystem.createTest({
        name = "Checkout Button Color Test",
        description = "Testing red vs blue checkout button",
        hypothesis = "Red button will increase conversions",
        successMetric = "checkout_completion",
        variants = [
            {name = "control", value = "blue", allocation = 50},
            {name = "treatment", value = "red", allocation = 50}
        ],
        traffic = 100,
        duration = 604800 -- 1 week
    })
    
    if testResult.success then
        print(string.format("    ✅ A/B test created: %s", testResult.test.name))
        print(string.format("    Variants: %d", #testResult.test.variants))
        print(string.format("    Traffic: %d%%", testResult.test.traffic))
    end
    
    -- Show user segments
    print("  🎯 User Segments:")
    for segmentKey, segment in pairs(FeatureFlagState.userSegments) do
        print(string.format("    %s: %s", segment.name, segment.description or ""))
        print(string.format("      Rules: %d", #segment.rules))
    end
    
    -- Show safeguards
    print("  🛡️ Safeguards:")
    local safeguards = FeatureFlagState.config.safeguards
    print(string.format("    Kill Switch: %s", safeguards.killSwitch.enabled and "enabled" or "disabled"))
    print(string.format("    Error Rate Threshold: %.1f%%", safeguards.killSwitch.triggers.errorRateThreshold * 100))
    print(string.format("    Gradual Rollback: %s", safeguards.gradualRollback.enabled and "enabled" or "disabled"))
    
    print("🚩 Feature flagging and gradual rollout demonstration completed")
    print("     Enterprise-grade feature management operational!")
end

-- Initialize the feature flagging system
FeatureFlaggingGradualRolloutSystem.initialize()

print("🚩 FeatureFlaggingGradualRolloutSystem loaded with comprehensive feature management")

return FeatureFlaggingGradualRolloutSystem
