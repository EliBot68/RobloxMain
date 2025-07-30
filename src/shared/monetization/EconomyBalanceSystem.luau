-- EconomyBalanceSystem.luau
-- Advanced economy balancing with mathematical models and optimization
-- Provides dynamic balance adjustments, inflation control, and fair progression

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local HttpService = game:GetService("HttpService")
local RunService = game:GetService("RunService")

local SafeRequire = require(ReplicatedStorage.Shared.utils.SafeRequire)

local EconomyBalanceSystem = {}

-- ========================================
-- BALANCE CONFIGURATION
-- ========================================

local BALANCE_CONFIG = {
    -- Mathematical models
    models = {
        -- Exponential progression model
        exponential = {
            name = "Exponential Progression",
            formula = "base * (multiplier ^ level)",
            parameters = {
                base = 100,
                multiplier = 1.15,
                maxLevel = 100
            },
            useCase = "level_requirements"
        },
        
        -- Logarithmic balance model
        logarithmic = {
            name = "Logarithmic Balance",
            formula = "base * log(level + offset)",
            parameters = {
                base = 50,
                offset = 1,
                scale = 10
            },
            useCase = "reward_scaling"
        },
        
        -- Power law distribution
        powerLaw = {
            name = "Power Law Distribution",
            formula = "coefficient * (x ^ exponent)",
            parameters = {
                coefficient = 1000,
                exponent = -1.2
            },
            useCase = "rare_item_probability"
        },
        
        -- Sigmoid curve for diminishing returns
        sigmoid = {
            name = "Sigmoid Curve",
            formula = "max_value / (1 + exp(-steepness * (x - midpoint)))",
            parameters = {
                maxValue = 1000,
                steepness = 0.1,
                midpoint = 50
            },
            useCase = "upgrade_costs"
        },
        
        -- Linear progression for fair elements
        linear = {
            name = "Linear Progression",
            formula = "base + (slope * level)",
            parameters = {
                base = 10,
                slope = 5
            },
            useCase = "basic_rewards"
        }
    },
    
    -- Balance targets
    targets = {
        -- Currency flow targets
        currencyFlow = {
            targetInflationRate = 0.02,    -- 2% monthly inflation
            maxInflationRate = 0.05,       -- 5% emergency threshold
            targetDeflationRate = -0.01,   -- -1% acceptable deflation
            circulationVelocity = 2.0,     -- Currency changes hands 2x per day
            reserveRatio = 0.15            -- 15% of currency in reserves
        },
        
        -- Player progression targets
        progression = {
            averageSessionProgression = 0.05,  -- 5% progress per session
            maxDailyProgression = 0.2,         -- 20% max daily progress
            newPlayerRetention7Day = 0.4,      -- 40% 7-day retention
            skillToProgressRatio = 0.7,        -- 70% skill, 30% time/money
            fairnessIndex = 0.85               -- 85% fairness score
        },
        
        -- Economic health indicators
        healthIndicators = {
            giniCoefficient = 0.4,        -- 0.4 wealth distribution (fair)
            purchasingPowerStability = 0.95, -- 95% stability
            marketLiquidityRatio = 0.8,   -- 80% market liquidity
            priceStabilityIndex = 0.9,    -- 90% price stability
            economicMobilityRate = 0.3    -- 30% players improve economic status monthly
        }
    },
    
    -- Auto-balance triggers
    autoBalance = {
        enableAutoBalance = true,
        checkFrequency = 300,           -- 5 minutes
        adjustmentMagnitude = 0.05,     -- 5% adjustment per trigger
        maxAdjustmentsPerHour = 6,      -- Max 6 adjustments per hour
        emergencyThresholds = {
            inflation = 0.1,            -- 10% inflation triggers emergency
            deflation = -0.05,          -- -5% deflation triggers emergency
            inequalitySpike = 0.2,      -- 20% inequality increase
            massChurn = 0.3             -- 30% player churn rate
        }
    },
    
    -- Balance constraints
    constraints = {
        -- Progression constraints
        minProgressionTime = 30,        -- 30 seconds minimum between major progress
        maxProgressionJumps = 5,        -- Max 5 levels per session
        skillGateRequirements = true,   -- Require skill demonstrations
        
        -- Economic constraints
        maxWealthConcentration = 0.3,   -- Top 10% can't hold >30% of wealth
        minEconomicMobility = 0.1,      -- 10% monthly mobility minimum
        maxPriceVolatility = 0.15,      -- 15% max price swings
        
        -- Fairness constraints
        payToWinMaxAdvantage = 0.1,     -- 10% max advantage from purchases
        timeVsMoneyRatio = 3.0,         -- 3:1 time vs money efficiency
        freePlayerViability = 0.8       -- 80% content accessible to free players
    }
}

-- ========================================
-- BALANCE STATE
-- ========================================

local BalanceState = {
    -- Economic indicators
    indicators = {
        inflationRate = 0,
        deflationRate = 0,
        circulationVelocity = 0,
        giniCoefficient = 0,
        purchasingPower = 100
    },
    
    -- Player progression tracking
    progressionMetrics = {
        averageProgression = {},
        skillBasedProgression = {},
        timeBasedProgression = {},
        progressionFairness = {}
    },
    
    -- Auto-balance history
    balanceHistory = {},
    adjustments = {},
    
    -- Mathematical models
    activeModels = {},
    modelResults = {},
    
    -- Monitoring data
    marketData = {},
    playerBehavior = {},
    economicHealth = {},
    
    -- Balance enforcement
    violations = {},
    corrections = {},
    
    -- Statistics
    stats = {
        totalBalanceAdjustments = 0,
        economicHealthScore = 100,
        fairnessScore = 100,
        stabilityIndex = 100,
        playerSatisfactionScore = 100
    }
}

function EconomyBalanceSystem.initialize()
    print("⚖️ Initializing EconomyBalanceSystem...")
    
    -- Set up mathematical models
    EconomyBalanceSystem.setupMathematicalModels()
    
    -- Initialize balance monitoring
    EconomyBalanceSystem.initializeBalanceMonitoring()
    
    -- Set up auto-balance system
    EconomyBalanceSystem.setupAutoBalanceSystem()
    
    -- Initialize fairness enforcement
    EconomyBalanceSystem.initializeFairnessEnforcement()
    
    -- Start balance monitoring
    EconomyBalanceSystem.startBalanceMonitoring()
    
    print("⚖️ EconomyBalanceSystem initialized successfully")
end

-- ========================================
-- MATHEMATICAL MODELS
-- ========================================

function EconomyBalanceSystem.setupMathematicalModels()
    BalanceState.modelEngine = {
        exponential = EconomyBalanceSystem.createExponentialModel(),
        logarithmic = EconomyBalanceSystem.createLogarithmicModel(),
        powerLaw = EconomyBalanceSystem.createPowerLawModel(),
        sigmoid = EconomyBalanceSystem.createSigmoidModel(),
        linear = EconomyBalanceSystem.createLinearModel()
    }
    
    -- Initialize model results storage
    for modelName in pairs(BALANCE_CONFIG.models) do
        BalanceState.modelResults[modelName] = {}
    end
    
    print("📐 Mathematical models initialized")
end

function EconomyBalanceSystem.createExponentialModel()
    return {
        name = "exponential",
        
        calculate = function(self, level, customParams)
            local params = customParams or BALANCE_CONFIG.models.exponential.parameters
            return params.base * math.pow(params.multiplier, level)
        end,
        
        inverse = function(self, value, customParams)
            local params = customParams or BALANCE_CONFIG.models.exponential.parameters
            return math.log(value / params.base) / math.log(params.multiplier)
        end,
        
        optimize = function(self, targetValues, levels)
            return EconomyBalanceSystem.optimizeExponentialParameters(targetValues, levels)
        end
    }
end

function EconomyBalanceSystem.createLogarithmicModel()
    return {
        name = "logarithmic",
        
        calculate = function(self, level, customParams)
            local params = customParams or BALANCE_CONFIG.models.logarithmic.parameters
            return params.base * math.log(level + params.offset) * params.scale
        end,
        
        inverse = function(self, value, customParams)
            local params = customParams or BALANCE_CONFIG.models.logarithmic.parameters
            return math.exp(value / (params.base * params.scale)) - params.offset
        end,
        
        optimize = function(self, targetValues, levels)
            return EconomyBalanceSystem.optimizeLogarithmicParameters(targetValues, levels)
        end
    }
end

function EconomyBalanceSystem.createPowerLawModel()
    return {
        name = "power_law",
        
        calculate = function(self, x, customParams)
            local params = customParams or BALANCE_CONFIG.models.powerLaw.parameters
            return params.coefficient * math.pow(x, params.exponent)
        end,
        
        generateDistribution = function(self, size, customParams)
            return EconomyBalanceSystem.generatePowerLawDistribution(size, customParams)
        end
    }
end

function EconomyBalanceSystem.createSigmoidModel()
    return {
        name = "sigmoid",
        
        calculate = function(self, x, customParams)
            local params = customParams or BALANCE_CONFIG.models.sigmoid.parameters
            local exponential = math.exp(-params.steepness * (x - params.midpoint))
            return params.maxValue / (1 + exponential)
        end,
        
        derivative = function(self, x, customParams)
            local params = customParams or BALANCE_CONFIG.models.sigmoid.parameters
            local sigmoid = self:calculate(x, customParams)
            return sigmoid * (1 - sigmoid / params.maxValue) * params.steepness
        end
    }
end

function EconomyBalanceSystem.createLinearModel()
    return {
        name = "linear",
        
        calculate = function(self, level, customParams)
            local params = customParams or BALANCE_CONFIG.models.linear.parameters
            return params.base + (params.slope * level)
        end,
        
        inverse = function(self, value, customParams)
            local params = customParams or BALANCE_CONFIG.models.linear.parameters
            return (value - params.base) / params.slope
        end
    }
end

function EconomyBalanceSystem.calculateProgression(progressionType, level, customParams)
    local model = BalanceState.modelEngine[progressionType]
    if not model then
        return 0
    end
    
    return model:calculate(level, customParams)
end

function EconomyBalanceSystem.optimizeModelParameters(modelType, targetValues, inputValues)
    local model = BalanceState.modelEngine[modelType]
    if not model or not model.optimize then
        return nil
    end
    
    return model:optimize(targetValues, inputValues)
end

function EconomyBalanceSystem.optimizeExponentialParameters(targetValues, levels)
    -- Use least squares optimization for exponential model
    local sumLogY = 0
    local sumLogYX = 0
    local sumX = 0
    local sumX2 = 0
    local n = #targetValues
    
    for i = 1, n do
        local x = levels[i]
        local logY = math.log(targetValues[i])
        
        sumLogY = sumLogY + logY
        sumLogYX = sumLogYX + logY * x
        sumX = sumX + x
        sumX2 = sumX2 + x * x
    end
    
    -- Calculate optimized parameters
    local slope = (n * sumLogYX - sumX * sumLogY) / (n * sumX2 - sumX * sumX)
    local intercept = (sumLogY - slope * sumX) / n
    
    return {
        base = math.exp(intercept),
        multiplier = math.exp(slope)
    }
end

function EconomyBalanceSystem.optimizeLogarithmicParameters(targetValues, levels)
    -- Use least squares for logarithmic optimization
    local bestParams = {base = 50, offset = 1, scale = 10}
    local bestError = math.huge
    
    -- Grid search optimization (simplified)
    for base = 10, 100, 10 do
        for offset = 0.1, 2, 0.1 do
            for scale = 1, 20, 1 do
                local error = 0
                
                for i = 1, #targetValues do
                    local predicted = base * math.log(levels[i] + offset) * scale
                    error = error + math.pow(predicted - targetValues[i], 2)
                end
                
                if error < bestError then
                    bestError = error
                    bestParams = {base = base, offset = offset, scale = scale}
                end
            end
        end
    end
    
    return bestParams
end

-- ========================================
-- BALANCE MONITORING
-- ========================================

function EconomyBalanceSystem.initializeBalanceMonitoring()
    BalanceState.balanceMonitor = {
        economicTracker = EconomyBalanceSystem.createEconomicTracker(),
        progressionAnalyzer = EconomyBalanceSystem.createProgressionAnalyzer(),
        fairnessMonitor = EconomyBalanceSystem.createFairnessMonitor(),
        stabilityChecker = EconomyBalanceSystem.createStabilityChecker()
    }
    
    print("📊 Balance monitoring initialized")
end

function EconomyBalanceSystem.createEconomicTracker()
    return {
        name = "economic_tracker",
        
        track = function(self)
            EconomyBalanceSystem.trackEconomicIndicators()
        end,
        
        analyze = function(self)
            return EconomyBalanceSystem.analyzeEconomicHealth()
        end
    }
end

function EconomyBalanceSystem.createProgressionAnalyzer()
    return {
        name = "progression_analyzer",
        
        analyze = function(self)
            return EconomyBalanceSystem.analyzeProgressionBalance()
        end
    }
end

function EconomyBalanceSystem.createFairnessMonitor()
    return {
        name = "fairness_monitor",
        
        monitor = function(self)
            return EconomyBalanceSystem.monitorFairness()
        end
    }
end

function EconomyBalanceSystem.createStabilityChecker()
    return {
        name = "stability_checker",
        
        check = function(self)
            return EconomyBalanceSystem.checkStability()
        end
    }
end

function EconomyBalanceSystem.trackEconomicIndicators()
    -- Track inflation/deflation
    BalanceState.indicators.inflationRate = EconomyBalanceSystem.calculateInflationRate()
    BalanceState.indicators.deflationRate = EconomyBalanceSystem.calculateDeflationRate()
    
    -- Track currency circulation
    BalanceState.indicators.circulationVelocity = EconomyBalanceSystem.calculateCirculationVelocity()
    
    -- Track wealth distribution
    BalanceState.indicators.giniCoefficient = EconomyBalanceSystem.calculateGiniCoefficient()
    
    -- Track purchasing power
    BalanceState.indicators.purchasingPower = EconomyBalanceSystem.calculatePurchasingPower()
end

function EconomyBalanceSystem.calculateInflationRate()
    -- Calculate inflation based on price changes over time
    -- Simplified calculation for demonstration
    local currentPrices = EconomyBalanceSystem.getCurrentAveragePrices()
    local historicalPrices = EconomyBalanceSystem.getHistoricalAveragePrices()
    
    if historicalPrices == 0 then
        return 0
    end
    
    return (currentPrices - historicalPrices) / historicalPrices
end

function EconomyBalanceSystem.calculateDeflationRate()
    local inflationRate = BalanceState.indicators.inflationRate
    return inflationRate < 0 and -inflationRate or 0
end

function EconomyBalanceSystem.calculateCirculationVelocity()
    -- Calculate how often currency changes hands
    local totalTransactions = EconomyBalanceSystem.getTotalTransactions()
    local totalCurrency = EconomyBalanceSystem.getTotalCurrencyInCirculation()
    
    if totalCurrency == 0 then
        return 0
    end
    
    return totalTransactions / totalCurrency
end

function EconomyBalanceSystem.calculateGiniCoefficient()
    -- Calculate wealth inequality using Gini coefficient
    local wealthDistribution = EconomyBalanceSystem.getWealthDistribution()
    
    if #wealthDistribution == 0 then
        return 0
    end
    
    -- Sort wealth in ascending order
    table.sort(wealthDistribution)
    
    local n = #wealthDistribution
    local sum = 0
    local weightedSum = 0
    
    for i = 1, n do
        sum = sum + wealthDistribution[i]
        weightedSum = weightedSum + (2 * i - n - 1) * wealthDistribution[i]
    end
    
    if sum == 0 then
        return 0
    end
    
    return weightedSum / (n * sum)
end

function EconomyBalanceSystem.calculatePurchasingPower()
    -- Calculate purchasing power based on currency value stability
    local baselineValue = 100
    local currentInflation = BalanceState.indicators.inflationRate
    
    return baselineValue * (1 - currentInflation)
end

function EconomyBalanceSystem.analyzeProgressionBalance()
    local analysis = {
        skillVsTimeRatio = 0,
        progressionFairness = 0,
        newPlayerExperience = 0,
        veteranPlayerSatisfaction = 0,
        overallBalance = 0
    }
    
    -- Analyze skill vs time investment
    analysis.skillVsTimeRatio = EconomyBalanceSystem.calculateSkillTimeRatio()
    
    -- Analyze progression fairness
    analysis.progressionFairness = EconomyBalanceSystem.calculateProgressionFairness()
    
    -- Analyze new player experience
    analysis.newPlayerExperience = EconomyBalanceSystem.analyzeNewPlayerProgression()
    
    -- Analyze veteran satisfaction
    analysis.veteranPlayerSatisfaction = EconomyBalanceSystem.analyzeVeteranProgression()
    
    -- Calculate overall balance score
    analysis.overallBalance = (
        analysis.skillVsTimeRatio + 
        analysis.progressionFairness + 
        analysis.newPlayerExperience + 
        analysis.veteranPlayerSatisfaction
    ) / 4
    
    return analysis
end

function EconomyBalanceSystem.calculateSkillTimeRatio()
    -- Calculate the ratio of skill-based vs time-based progression
    local skillBasedProgress = EconomyBalanceSystem.getSkillBasedProgressTotal()
    local timeBasedProgress = EconomyBalanceSystem.getTimeBasedProgressTotal()
    
    local totalProgress = skillBasedProgress + timeBasedProgress
    if totalProgress == 0 then
        return BALANCE_CONFIG.targets.progression.skillToProgressRatio
    end
    
    return skillBasedProgress / totalProgress
end

function EconomyBalanceSystem.calculateProgressionFairness()
    -- Calculate how fair the progression system is
    local payingPlayerProgress = EconomyBalanceSystem.getAveragePayingPlayerProgress()
    local freePlayerProgress = EconomyBalanceSystem.getAverageFreePlayerProgress()
    
    if payingPlayerProgress == 0 then
        return 1.0
    end
    
    local progressRatio = freePlayerProgress / payingPlayerProgress
    local maxAdvantage = BALANCE_CONFIG.constraints.payToWinMaxAdvantage
    
    -- Fairness score based on how close the ratio is to the ideal
    local idealRatio = 1.0 - maxAdvantage
    return 1.0 - math.abs(progressRatio - idealRatio)
end

function EconomyBalanceSystem.monitorFairness()
    local fairnessMetrics = {
        payToWinAdvantage = 0,
        timeVsMoneyEfficiency = 0,
        freePlayerViability = 0,
        economicMobility = 0,
        competitiveBalance = 0
    }
    
    -- Check pay-to-win advantage
    fairnessMetrics.payToWinAdvantage = EconomyBalanceSystem.calculatePayToWinAdvantage()
    
    -- Check time vs money efficiency
    fairnessMetrics.timeVsMoneyEfficiency = EconomyBalanceSystem.calculateTimeMoneyEfficiency()
    
    -- Check free player viability
    fairnessMetrics.freePlayerViability = EconomyBalanceSystem.calculateFreePlayerViability()
    
    -- Check economic mobility
    fairnessMetrics.economicMobility = EconomyBalanceSystem.calculateEconomicMobility()
    
    -- Check competitive balance
    fairnessMetrics.competitiveBalance = EconomyBalanceSystem.calculateCompetitiveBalance()
    
    return fairnessMetrics
end

function EconomyBalanceSystem.calculatePayToWinAdvantage()
    -- Calculate the advantage paying players have over free players
    local payingPlayerMetrics = EconomyBalanceSystem.getPayingPlayerMetrics()
    local freePlayerMetrics = EconomyBalanceSystem.getFreePlayerMetrics()
    
    if freePlayerMetrics.averagePower == 0 then
        return 0
    end
    
    return (payingPlayerMetrics.averagePower - freePlayerMetrics.averagePower) / freePlayerMetrics.averagePower
end

function EconomyBalanceSystem.calculateTimeMoneyEfficiency()
    -- Calculate the efficiency ratio between time and money investment
    local timeEfficiency = EconomyBalanceSystem.getTimeInvestmentEfficiency()
    local moneyEfficiency = EconomyBalanceSystem.getMoneyInvestmentEfficiency()
    
    if moneyEfficiency == 0 then
        return BALANCE_CONFIG.constraints.timeVsMoneyRatio
    end
    
    return timeEfficiency / moneyEfficiency
end

-- ========================================
-- AUTO-BALANCE SYSTEM
-- ========================================

function EconomyBalanceSystem.setupAutoBalanceSystem()
    BalanceState.autoBalancer = {
        adjustmentEngine = EconomyBalanceSystem.createAdjustmentEngine(),
        emergencyHandler = EconomyBalanceSystem.createEmergencyHandler(),
        optimizationEngine = EconomyBalanceSystem.createOptimizationEngine()
    }
    
    print("🤖 Auto-balance system initialized")
end

function EconomyBalanceSystem.createAdjustmentEngine()
    return {
        name = "adjustment_engine",
        adjustmentCount = 0,
        lastAdjustment = 0,
        
        adjust = function(self, imbalanceType, severity)
            return EconomyBalanceSystem.performBalanceAdjustment(imbalanceType, severity)
        end
    }
end

function EconomyBalanceSystem.createEmergencyHandler()
    return {
        name = "emergency_handler",
        
        handle = function(self, emergency)
            return EconomyBalanceSystem.handleEmergencyImbalance(emergency)
        end
    }
end

function EconomyBalanceSystem.createOptimizationEngine()
    return {
        name = "optimization_engine",
        
        optimize = function(self)
            return EconomyBalanceSystem.optimizeEconomyParameters()
        end
    }
end

function EconomyBalanceSystem.performBalanceAdjustment(imbalanceType, severity)
    local adjustment = {
        id = HttpService:GenerateGUID(false),
        timestamp = tick(),
        type = imbalanceType,
        severity = severity,
        adjustments = {},
        effectiveness = 0
    }
    
    if imbalanceType == "inflation" then
        -- Reduce currency sources, increase sinks
        adjustment.adjustments = EconomyBalanceSystem.createInflationAdjustments(severity)
        
    elseif imbalanceType == "deflation" then
        -- Increase currency sources, reduce sinks
        adjustment.adjustments = EconomyBalanceSystem.createDeflationAdjustments(severity)
        
    elseif imbalanceType == "inequality" then
        -- Improve economic mobility, redistribute opportunities
        adjustment.adjustments = EconomyBalanceSystem.createInequalityAdjustments(severity)
        
    elseif imbalanceType == "progression_imbalance" then
        -- Adjust progression curves
        adjustment.adjustments = EconomyBalanceSystem.createProgressionAdjustments(severity)
        
    elseif imbalanceType == "pay_to_win" then
        -- Reduce paid advantages, increase free player opportunities
        adjustment.adjustments = EconomyBalanceSystem.createPayToWinAdjustments(severity)
    end
    
    -- Apply adjustments
    EconomyBalanceSystem.applyBalanceAdjustments(adjustment.adjustments)
    
    -- Store adjustment record
    table.insert(BalanceState.balanceHistory, adjustment)
    BalanceState.stats.totalBalanceAdjustments = BalanceState.stats.totalBalanceAdjustments + 1
    
    print(string.format("⚖️ Applied balance adjustment: %s (severity: %.2f)", 
        imbalanceType, severity))
    
    return adjustment
end

function EconomyBalanceSystem.createInflationAdjustments(severity)
    local adjustments = {}
    local magnitude = severity * BALANCE_CONFIG.autoBalance.adjustmentMagnitude
    
    -- Reduce earning rates
    table.insert(adjustments, {
        type = "earning_rate_reduction",
        value = magnitude,
        target = "currency_sources"
    })
    
    -- Increase costs
    table.insert(adjustments, {
        type = "cost_increase",
        value = magnitude * 0.5,
        target = "major_purchases"
    })
    
    -- Increase currency sinks
    table.insert(adjustments, {
        type = "sink_increase",
        value = magnitude,
        target = "maintenance_costs"
    })
    
    return adjustments
end

function EconomyBalanceSystem.createDeflationAdjustments(severity)
    local adjustments = {}
    local magnitude = severity * BALANCE_CONFIG.autoBalance.adjustmentMagnitude
    
    -- Increase earning rates
    table.insert(adjustments, {
        type = "earning_rate_increase",
        value = magnitude,
        target = "currency_sources"
    })
    
    -- Reduce costs
    table.insert(adjustments, {
        type = "cost_reduction",
        value = magnitude * 0.5,
        target = "major_purchases"
    })
    
    -- Add bonus rewards
    table.insert(adjustments, {
        type = "bonus_rewards",
        value = magnitude,
        target = "daily_activities"
    })
    
    return adjustments
end

function EconomyBalanceSystem.createInequalityAdjustments(severity)
    local adjustments = {}
    local magnitude = severity * BALANCE_CONFIG.autoBalance.adjustmentMagnitude
    
    -- Increase opportunities for lower-wealth players
    table.insert(adjustments, {
        type = "progressive_rewards",
        value = magnitude,
        target = "low_wealth_players"
    })
    
    -- Add wealth redistribution mechanisms
    table.insert(adjustments, {
        type = "wealth_redistribution",
        value = magnitude * 0.3,
        target = "high_wealth_players"
    })
    
    -- Improve economic mobility
    table.insert(adjustments, {
        type = "mobility_enhancement",
        value = magnitude,
        target = "progression_systems"
    })
    
    return adjustments
end

function EconomyBalanceSystem.createProgressionAdjustments(severity)
    local adjustments = {}
    local magnitude = severity * BALANCE_CONFIG.autoBalance.adjustmentMagnitude
    
    -- Adjust progression curves
    table.insert(adjustments, {
        type = "progression_curve_adjustment",
        value = magnitude,
        target = "leveling_requirements"
    })
    
    -- Balance skill vs time requirements
    table.insert(adjustments, {
        type = "skill_time_balance",
        value = magnitude,
        target = "progression_gates"
    })
    
    return adjustments
end

function EconomyBalanceSystem.createPayToWinAdjustments(severity)
    local adjustments = {}
    local magnitude = severity * BALANCE_CONFIG.autoBalance.adjustmentMagnitude
    
    -- Reduce paid advantages
    table.insert(adjustments, {
        type = "advantage_reduction",
        value = magnitude,
        target = "paid_benefits"
    })
    
    -- Increase free player opportunities
    table.insert(adjustments, {
        type = "free_player_boost",
        value = magnitude,
        target = "free_progression"
    })
    
    return adjustments
end

function EconomyBalanceSystem.applyBalanceAdjustments(adjustments)
    for _, adjustment in ipairs(adjustments) do
        if adjustment.type == "earning_rate_reduction" then
            EconomyBalanceSystem.adjustEarningRates(-adjustment.value)
            
        elseif adjustment.type == "earning_rate_increase" then
            EconomyBalanceSystem.adjustEarningRates(adjustment.value)
            
        elseif adjustment.type == "cost_increase" then
            EconomyBalanceSystem.adjustCosts(adjustment.value)
            
        elseif adjustment.type == "cost_reduction" then
            EconomyBalanceSystem.adjustCosts(-adjustment.value)
            
        elseif adjustment.type == "progressive_rewards" then
            EconomyBalanceSystem.implementProgressiveRewards(adjustment.value)
            
        elseif adjustment.type == "progression_curve_adjustment" then
            EconomyBalanceSystem.adjustProgressionCurves(adjustment.value)
        end
    end
end

-- ========================================
-- FAIRNESS ENFORCEMENT
-- ========================================

function EconomyBalanceSystem.initializeFairnessEnforcement()
    BalanceState.fairnessEnforcer = {
        payToWinPreventer = EconomyBalanceSystem.createPayToWinPreventer(),
        progressionGuardian = EconomyBalanceSystem.createProgressionGuardian(),
        equalityMonitor = EconomyBalanceSystem.createEqualityMonitor()
    }
    
    print("⚖️ Fairness enforcement initialized")
end

function EconomyBalanceSystem.createPayToWinPreventer()
    return {
        name = "pay_to_win_preventer",
        
        prevent = function(self)
            return EconomyBalanceSystem.preventPayToWinViolations()
        end
    }
end

function EconomyBalanceSystem.createProgressionGuardian()
    return {
        name = "progression_guardian",
        
        guard = function(self)
            return EconomyBalanceSystem.guardProgressionFairness()
        end
    }
end

function EconomyBalanceSystem.createEqualityMonitor()
    return {
        name = "equality_monitor",
        
        monitor = function(self)
            return EconomyBalanceSystem.monitorEqualityMetrics()
        end
    }
end

function EconomyBalanceSystem.preventPayToWinViolations()
    local violations = {}
    local maxAdvantage = BALANCE_CONFIG.constraints.payToWinMaxAdvantage
    
    -- Check current pay-to-win advantage
    local currentAdvantage = EconomyBalanceSystem.calculatePayToWinAdvantage()
    
    if currentAdvantage > maxAdvantage then
        table.insert(violations, {
            type = "excessive_paid_advantage",
            severity = (currentAdvantage - maxAdvantage) / maxAdvantage,
            currentValue = currentAdvantage,
            threshold = maxAdvantage
        })
        
        -- Apply corrective measures
        EconomyBalanceSystem.correctPayToWinViolation(currentAdvantage, maxAdvantage)
    end
    
    return violations
end

function EconomyBalanceSystem.correctPayToWinViolation(currentAdvantage, maxAdvantage)
    local correction = {
        timestamp = tick(),
        type = "pay_to_win_correction",
        before = currentAdvantage,
        target = maxAdvantage,
        actions = {}
    }
    
    -- Reduce advantages of paid features
    local reductionNeeded = currentAdvantage - maxAdvantage
    
    table.insert(correction.actions, {
        action = "reduce_paid_benefits",
        magnitude = reductionNeeded * 0.5
    })
    
    table.insert(correction.actions, {
        action = "boost_free_progression",
        magnitude = reductionNeeded * 0.3
    })
    
    table.insert(correction.actions, {
        action = "add_skill_gates",
        magnitude = reductionNeeded * 0.2
    })
    
    -- Apply corrections
    EconomyBalanceSystem.applyCorrections(correction.actions)
    
    table.insert(BalanceState.corrections, correction)
    
    print(string.format("🔒 Applied pay-to-win correction: %.1f%% -> %.1f%%", 
        currentAdvantage * 100, maxAdvantage * 100))
end

function EconomyBalanceSystem.applyCorrections(actions)
    for _, action in ipairs(actions) do
        if action.action == "reduce_paid_benefits" then
            EconomyBalanceSystem.reducePaidBenefits(action.magnitude)
            
        elseif action.action == "boost_free_progression" then
            EconomyBalanceSystem.boostFreeProgression(action.magnitude)
            
        elseif action.action == "add_skill_gates" then
            EconomyBalanceSystem.addSkillGates(action.magnitude)
        end
    end
end

-- ========================================
-- MONITORING AND OPTIMIZATION
-- ========================================

function EconomyBalanceSystem.startBalanceMonitoring()
    spawn(function()
        while true do
            EconomyBalanceSystem.performBalanceCheck()
            EconomyBalanceSystem.updateBalanceMetrics()
            EconomyBalanceSystem.checkEmergencyConditions()
            
            task.wait(BALANCE_CONFIG.autoBalance.checkFrequency)
        end
    end)
    
    print("🔄 Balance monitoring started")
end

function EconomyBalanceSystem.performBalanceCheck()
    -- Check economic indicators
    BalanceState.balanceMonitor.economicTracker:track()
    
    -- Analyze progression balance
    local progressionAnalysis = BalanceState.balanceMonitor.progressionAnalyzer:analyze()
    
    -- Monitor fairness
    local fairnessMetrics = BalanceState.balanceMonitor.fairnessMonitor:monitor()
    
    -- Check stability
    local stabilityCheck = BalanceState.balanceMonitor.stabilityChecker:check()
    
    -- Identify imbalances
    local imbalances = EconomyBalanceSystem.identifyImbalances(
        progressionAnalysis, fairnessMetrics, stabilityCheck
    )
    
    -- Apply auto-balance if needed
    if BALANCE_CONFIG.autoBalance.enableAutoBalance then
        EconomyBalanceSystem.handleImbalances(imbalances)
    end
end

function EconomyBalanceSystem.identifyImbalances(progressionAnalysis, fairnessMetrics, stabilityCheck)
    local imbalances = {}
    
    -- Check inflation/deflation
    local inflationRate = BalanceState.indicators.inflationRate
    if math.abs(inflationRate) > BALANCE_CONFIG.targets.currencyFlow.targetInflationRate * 2 then
        table.insert(imbalances, {
            type = inflationRate > 0 and "inflation" or "deflation",
            severity = math.abs(inflationRate) / BALANCE_CONFIG.targets.currencyFlow.maxInflationRate
        })
    end
    
    -- Check inequality
    local giniCoefficient = BalanceState.indicators.giniCoefficient
    if giniCoefficient > BALANCE_CONFIG.targets.healthIndicators.giniCoefficient * 1.2 then
        table.insert(imbalances, {
            type = "inequality",
            severity = (giniCoefficient - BALANCE_CONFIG.targets.healthIndicators.giniCoefficient) / 
                      BALANCE_CONFIG.targets.healthIndicators.giniCoefficient
        })
    end
    
    -- Check pay-to-win violations
    if fairnessMetrics.payToWinAdvantage > BALANCE_CONFIG.constraints.payToWinMaxAdvantage then
        table.insert(imbalances, {
            type = "pay_to_win",
            severity = (fairnessMetrics.payToWinAdvantage - BALANCE_CONFIG.constraints.payToWinMaxAdvantage) /
                      BALANCE_CONFIG.constraints.payToWinMaxAdvantage
        })
    end
    
    -- Check progression balance
    if progressionAnalysis.overallBalance < 0.7 then
        table.insert(imbalances, {
            type = "progression_imbalance",
            severity = (0.7 - progressionAnalysis.overallBalance) / 0.7
        })
    end
    
    return imbalances
end

function EconomyBalanceSystem.handleImbalances(imbalances)
    local adjuster = BalanceState.autoBalancer.adjustmentEngine
    
    -- Check adjustment rate limits
    local currentTime = tick()
    local hoursSinceLastAdjustment = (currentTime - adjuster.lastAdjustment) / 3600
    
    if hoursSinceLastAdjustment < 1 and adjuster.adjustmentCount >= BALANCE_CONFIG.autoBalance.maxAdjustmentsPerHour then
        print("⚠️ Balance adjustment rate limit reached")
        return
    end
    
    -- Apply adjustments for each imbalance
    for _, imbalance in ipairs(imbalances) do
        if imbalance.severity > 0.1 then -- Only adjust significant imbalances
            adjuster:adjust(imbalance.type, imbalance.severity)
            
            adjuster.adjustmentCount = adjuster.adjustmentCount + 1
            adjuster.lastAdjustment = currentTime
        end
    end
    
    -- Reset adjustment count after an hour
    if hoursSinceLastAdjustment >= 1 then
        adjuster.adjustmentCount = 0
    end
end

function EconomyBalanceSystem.updateBalanceMetrics()
    -- Update economic health score
    local healthFactors = {
        inflationStability = 1 - math.min(1, math.abs(BalanceState.indicators.inflationRate) / 0.1),
        wealthDistribution = 1 - math.max(0, BalanceState.indicators.giniCoefficient - 0.4) / 0.6,
        purchasingPower = BalanceState.indicators.purchasingPower / 100,
        circulationHealth = math.min(1, BalanceState.indicators.circulationVelocity / 2)
    }
    
    local totalHealth = 0
    for _, factor in pairs(healthFactors) do
        totalHealth = totalHealth + factor
    end
    
    BalanceState.stats.economicHealthScore = (totalHealth / 4) * 100
    
    -- Update fairness score
    local fairnessMetrics = BalanceState.balanceMonitor.fairnessMonitor:monitor()
    local fairnessFactors = {
        payToWinFairness = 1 - math.max(0, fairnessMetrics.payToWinAdvantage - BALANCE_CONFIG.constraints.payToWinMaxAdvantage),
        timeMoneyBalance = math.min(1, fairnessMetrics.timeVsMoneyEfficiency / BALANCE_CONFIG.constraints.timeVsMoneyRatio),
        freePlayerViability = fairnessMetrics.freePlayerViability,
        economicMobility = fairnessMetrics.economicMobility
    }
    
    local totalFairness = 0
    for _, factor in pairs(fairnessFactors) do
        totalFairness = totalFairness + factor
    end
    
    BalanceState.stats.fairnessScore = (totalFairness / 4) * 100
    
    -- Update stability index
    local recentAdjustments = #BalanceState.balanceHistory
    local stabilityPenalty = math.min(50, recentAdjustments * 5) -- Penalty for frequent adjustments
    
    BalanceState.stats.stabilityIndex = math.max(50, 100 - stabilityPenalty)
end

-- ========================================
-- UTILITY FUNCTIONS
-- ========================================

function EconomyBalanceSystem.getCurrentAveragePrices()
    -- Simulate average price calculation
    return 100 + math.random(-10, 10)
end

function EconomyBalanceSystem.getHistoricalAveragePrices()
    -- Simulate historical price data
    return 95 + math.random(-5, 5)
end

function EconomyBalanceSystem.getTotalTransactions()
    -- Simulate transaction count
    return math.random(1000, 5000)
end

function EconomyBalanceSystem.getTotalCurrencyInCirculation()
    -- Simulate total currency
    return math.random(100000, 500000)
end

function EconomyBalanceSystem.getWealthDistribution()
    -- Simulate wealth distribution data
    local distribution = {}
    for i = 1, 100 do
        -- Generate power-law distribution for wealth
        local wealth = math.pow(math.random(), -1.5) * 1000
        table.insert(distribution, wealth)
    end
    return distribution
end

function EconomyBalanceSystem.getSkillBasedProgressTotal()
    return math.random(1000, 5000)
end

function EconomyBalanceSystem.getTimeBasedProgressTotal()
    return math.random(500, 2000)
end

function EconomyBalanceSystem.getAveragePayingPlayerProgress()
    return math.random(80, 120)
end

function EconomyBalanceSystem.getAverageFreePlayerProgress()
    return math.random(60, 90)
end

function EconomyBalanceSystem.getPayingPlayerMetrics()
    return {averagePower = math.random(90, 110)}
end

function EconomyBalanceSystem.getFreePlayerMetrics()
    return {averagePower = math.random(80, 100)}
end

function EconomyBalanceSystem.getTimeInvestmentEfficiency()
    return math.random(80, 120)
end

function EconomyBalanceSystem.getMoneyInvestmentEfficiency()
    return math.random(30, 50)
end

function EconomyBalanceSystem.adjustEarningRates(adjustment)
    print(string.format("💰 Adjusted earning rates by %.1f%%", adjustment * 100))
end

function EconomyBalanceSystem.adjustCosts(adjustment)
    print(string.format("💸 Adjusted costs by %.1f%%", adjustment * 100))
end

function EconomyBalanceSystem.implementProgressiveRewards(magnitude)
    print(string.format("🎁 Implemented progressive rewards (magnitude: %.2f)", magnitude))
end

function EconomyBalanceSystem.adjustProgressionCurves(adjustment)
    print(string.format("📈 Adjusted progression curves by %.1f%%", adjustment * 100))
end

function EconomyBalanceSystem.reducePaidBenefits(magnitude)
    print(string.format("⬇️ Reduced paid benefits by %.1f%%", magnitude * 100))
end

function EconomyBalanceSystem.boostFreeProgression(magnitude)
    print(string.format("⬆️ Boosted free progression by %.1f%%", magnitude * 100))
end

function EconomyBalanceSystem.addSkillGates(magnitude)
    print(string.format("🚪 Added skill gates (intensity: %.2f)", magnitude))
end

-- ========================================
-- PUBLIC API
-- ========================================

function EconomyBalanceSystem.runBalanceDemo()
    print("⚖️ Running economy balance demonstration...")
    
    -- Show mathematical models
    print("  📐 Mathematical Models:")
    for modelName, model in pairs(BalanceState.modelEngine) do
        if model.calculate then
            local level10 = model:calculate(10)
            local level50 = model:calculate(50)
            print(string.format("    %s: Level 10 = %.1f, Level 50 = %.1f", 
                modelName, level10, level50))
        end
    end
    
    -- Perform balance analysis
    print("  📊 Balance Analysis:")
    EconomyBalanceSystem.trackEconomicIndicators()
    
    print(string.format("    Inflation Rate: %.2f%%", BalanceState.indicators.inflationRate * 100))
    print(string.format("    Gini Coefficient: %.3f", BalanceState.indicators.giniCoefficient))
    print(string.format("    Circulation Velocity: %.2f", BalanceState.indicators.circulationVelocity))
    print(string.format("    Purchasing Power: %.1f", BalanceState.indicators.purchasingPower))
    
    -- Test auto-balance system
    print("  🤖 Testing Auto-Balance:")
    
    -- Simulate inflation scenario
    BalanceState.indicators.inflationRate = 0.08 -- 8% inflation
    local imbalances = EconomyBalanceSystem.identifyImbalances({overallBalance = 0.8}, {payToWinAdvantage = 0.05}, {})
    
    if #imbalances > 0 then
        print(string.format("    Detected %d imbalances:", #imbalances))
        for _, imbalance in ipairs(imbalances) do
            print(string.format("      %s (severity: %.2f)", imbalance.type, imbalance.severity))
        end
        
        EconomyBalanceSystem.handleImbalances(imbalances)
    end
    
    -- Test fairness enforcement
    print("  ⚖️ Fairness Enforcement:")
    local violations = EconomyBalanceSystem.preventPayToWinViolations()
    
    if #violations > 0 then
        print(string.format("    Found %d fairness violations", #violations))
    else
        print("    No fairness violations detected")
    end
    
    -- Show model optimization
    print("  🔧 Model Optimization:")
    local targetValues = {100, 150, 225, 340, 510}
    local levels = {1, 2, 3, 4, 5}
    
    local optimizedParams = EconomyBalanceSystem.optimizeExponentialParameters(targetValues, levels)
    print(string.format("    Optimized Exponential: base=%.2f, multiplier=%.3f", 
        optimizedParams.base, optimizedParams.multiplier))
    
    -- Show balance metrics
    EconomyBalanceSystem.updateBalanceMetrics()
    local stats = EconomyBalanceSystem.getBalanceStats()
    
    print("  📈 Balance Statistics:")
    print(string.format("    Economic Health: %.1f%%", stats.economicHealthScore))
    print(string.format("    Fairness Score: %.1f%%", stats.fairnessScore))
    print(string.format("    Stability Index: %.1f%%", stats.stabilityIndex))
    print(string.format("    Total Adjustments: %d", stats.totalBalanceAdjustments))
    
    print("⚖️ Economy balance demonstration completed")
end

function EconomyBalanceSystem.getBalanceStats()
    return BalanceState.stats
end

function EconomyBalanceSystem.getEconomicIndicators()
    return BalanceState.indicators
end

function EconomyBalanceSystem.getBalanceHistory()
    return BalanceState.balanceHistory
end

function EconomyBalanceSystem.getModelResults()
    return BalanceState.modelResults
end

-- Export API
EconomyBalanceSystem.calculateProgression = EconomyBalanceSystem.calculateProgression
EconomyBalanceSystem.optimizeModelParameters = EconomyBalanceSystem.optimizeModelParameters
EconomyBalanceSystem.performBalanceAdjustment = EconomyBalanceSystem.performBalanceAdjustment

-- Initialize the economy balance system
EconomyBalanceSystem.initialize()

print("⚖️ EconomyBalanceSystem loaded with comprehensive mathematical modeling and auto-balance")

return EconomyBalanceSystem
