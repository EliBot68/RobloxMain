-- AnalyticsSessionService.luau
-- Business logic for session tracking and player lifecycle management
-- Handles session metrics, player behavior analysis, and engagement tracking

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local SafeRequire = require(ReplicatedStorage.Shared.utils.SafeRequire)
local ServiceArchitecture = SafeRequire.require(ReplicatedStorage.Shared.core.ServiceArchitecture)

local AnalyticsSessionService = {}
AnalyticsSessionService.__index = AnalyticsSessionService

-- Implement IDomainService interface
setmetatable(AnalyticsSessionService, {__index = ServiceArchitecture.IDomainService})

-- ========================================
-- SESSION TRACKING DATA
-- ========================================

local sessionMetrics = {}
local difficultyMetrics = {}
local monetizationMetrics = {}

function AnalyticsSessionService.new(repository, eventCollector)
    local self = setmetatable({}, AnalyticsSessionService)
    
    self.repository = repository
    self.eventCollector = eventCollector
    
    print("📊 AnalyticsSessionService initialized")
    return self
end

-- ========================================
-- SESSION LIFECYCLE
-- ========================================

function AnalyticsSessionService:StartPlayerSession(player)
    local sessionId = self.repository:GenerateSessionId()
    local joinTime = os.time()
    
    -- Create session in repository
    local sessionData = {
        sessionId = sessionId,
        playerName = player.Name,
        sessionStart = joinTime,
        platform = self:DetectPlatform(player),
        metadata = {
            accountAge = player.AccountAge,
            membershipType = tostring(player.MembershipType),
            locale = player.LocaleId or "en-us"
        }
    }
    
    self.repository:CreatePlayerSession(player.UserId, sessionData)
    
    -- Initialize comprehensive session metrics
    sessionMetrics[player.UserId] = {
        sessionStart = joinTime,
        runsCompleted = 0,
        totalCoinsEarned = 0,
        coinsAtSessionStart = self:GetPlayerCoins(player),
        totalBarriersAttempted = 0,
        totalBarriersFailed = 0,
        averageRunLength = 0,
        longestRun = 0,
        shortestRun = math.huge,
        totalRunTime = 0,
        perfectRuns = 0,
        hasGamepass = false,
        gamepassesOwned = {},
        gamepassUsage = {},
        firstRunStarted = false,
        bounced = false,
        barrierFailsByType = {},
        coinsPerRun = {},
        runDifficulty = {},
        interactionCount = 0,
        timeInMenus = 0,
        purchaseAttempts = 0,
        currentPosition = nil,
        currentRunStartTime = nil,
        currentRunStartPosition = 0,
        barriersInCurrentRun = 0,
        colorSwitchTimes = {},
        failureSequences = {},
        improvementTracking = {}
    }
    
    -- Check gamepass ownership
    local gamepasses = self:CheckPlayerGamepasses(player)
    sessionMetrics[player.UserId].hasGamepass = #gamepasses > 0
    sessionMetrics[player.UserId].gamepassesOwned = gamepasses
    
    -- Initialize difficulty tracking
    difficultyMetrics[player.UserId] = {
        barriersByPosition = {},
        colorSwitchSpeed = {},
        failurePatterns = {},
        learningCurve = {},
        adaptiveSettings = {
            currentDifficulty = 1.0,
            adjustmentHistory = {},
            reactionTimeBaseline = 350 -- milliseconds
        }
    }
    
    -- Initialize monetization tracking
    monetizationMetrics[player.UserId] = {
        purchaseHistory = {},
        gamepassUsageFrequency = {},
        revenueContribution = 0,
        conversionEvents = {},
        engagementLevel = "new"
    }
    
    -- Log join event
    self.eventCollector:CollectEvent(player, "player_join", {
        rejoin = self:IsRejoinPlayer(player),
        platform = sessionData.platform,
        hasGamepass = sessionMetrics[player.UserId].hasGamepass,
        gamepassCount = #gamepasses,
        firstTimePlayer = self:IsFirstTimePlayer(player),
        accountAge = player.AccountAge,
        membershipType = tostring(player.MembershipType)
    })
    
    print("📊 Session started for " .. player.Name .. " (" .. sessionId .. ")")
    return sessionId
end

function AnalyticsSessionService:EndPlayerSession(player)
    local session = self.repository:GetPlayerSession(player.UserId)
    local metrics = sessionMetrics[player.UserId]
    
    if not session or not metrics then
        warn("⚠️ No session data found for " .. player.Name)
        return
    end
    
    local sessionDuration = os.time() - session.sessionStart
    
    -- Calculate comprehensive session metrics
    local bounced = not metrics.firstRunStarted and sessionDuration < 120
    local avgCoinsPerRun = metrics.runsCompleted > 0 and (metrics.totalCoinsEarned / metrics.runsCompleted) or 0
    local failRate = metrics.totalBarriersAttempted > 0 and (metrics.totalBarriersFailed / metrics.totalBarriersAttempted) or 0
    local perfectRunRate = metrics.runsCompleted > 0 and (metrics.perfectRuns / metrics.runsCompleted) or 0
    local avgRunTime = metrics.runsCompleted > 0 and (metrics.totalRunTime / metrics.runsCompleted) or 0
    
    -- Log comprehensive session metrics
    self.eventCollector:CollectEvent(player, "session_metrics", {
        sessionDuration = sessionDuration,
        runsCompleted = metrics.runsCompleted,
        avgCoinsPerRun = avgCoinsPerRun,
        totalCoinsEarned = metrics.totalCoinsEarned,
        failRate = failRate,
        bounced = bounced,
        hasGamepass = metrics.hasGamepass,
        gamepassUsageCount = self:CountGamepassUsage(metrics),
        perfectRunRate = perfectRunRate,
        avgRunTime = avgRunTime,
        purchaseAttempts = metrics.purchaseAttempts,
        timeInMenus = metrics.timeInMenus,
        platform = session.platform,
        improvementRate = self:CalculateImprovementRate(player),
        engagementLevel = self:CalculateEngagementLevel(metrics)
    })
    
    -- Log bounce rate if applicable
    if bounced then
        self.eventCollector:CollectEvent(player, "bounce_rate", {
            sessionDuration = sessionDuration,
            reason = sessionDuration < 30 and "immediate_leave" or "no_engagement",
            platform = session.platform,
            hadTutorial = self:PlayerCompletedTutorial(player),
            accountAge = player.AccountAge
        })
    end
    
    -- Log difficulty analysis
    if metrics.runsCompleted > 0 then
        self.eventCollector:CollectEvent(player, "fail_rate_analysis", {
            overallFailRate = failRate,
            barrierFailsByType = metrics.barrierFailsByType,
            improvementRate = self:CalculateImprovementRate(player),
            difficultySpikes = self:IdentifyDifficultySpikes(metrics),
            recommendedAdjustments = self:GenerateDifficultyRecommendations(metrics),
            adaptiveSettings = difficultyMetrics[player.UserId] and difficultyMetrics[player.UserId].adaptiveSettings or {}
        })
    end
    
    -- Log gamepass usage patterns
    if metrics.hasGamepass then
        self.eventCollector:CollectEvent(player, "gamepass_usage", {
            gamepassesOwned = metrics.gamepassesOwned,
            usageFrequency = self:CalculateGamepassUsageFrequency(metrics),
            valueRealized = self:CalculateGamepassValue(metrics),
            sessionLength = sessionDuration,
            engagementLevel = self:CalculateEngagementLevel(metrics),
            revenueContribution = monetizationMetrics[player.UserId] and monetizationMetrics[player.UserId].revenueContribution or 0
        })
    end
    
    -- Log final leave event
    self.eventCollector:CollectEvent(player, "player_leave", {
        sessionDuration = sessionDuration,
        eventsLogged = session.eventsLogged,
        runsCompleted = metrics.runsCompleted,
        totalCoinsEarned = metrics.totalCoinsEarned,
        engagementLevel = self:CalculateEngagementLevel(metrics)
    })
    
    -- End session in repository
    self.repository:EndPlayerSession(player.UserId)
    
    -- Clean up metrics data
    sessionMetrics[player.UserId] = nil
    difficultyMetrics[player.UserId] = nil
    monetizationMetrics[player.UserId] = nil
    
    print("📊 Session ended for " .. player.Name .. " (Duration: " .. sessionDuration .. "s)")
end

-- ========================================
-- RUN TRACKING
-- ========================================

function AnalyticsSessionService:TrackRunStart(player, currentPosition)
    local metrics = sessionMetrics[player.UserId]
    if not metrics then
        return
    end
    
    metrics.firstRunStarted = true
    metrics.currentRunStartTime = os.time()
    metrics.currentRunStartPosition = currentPosition or 0
    metrics.barriersInCurrentRun = 0
    
    self.eventCollector:CollectEvent(player, "run_start", {
        startPosition = currentPosition or 0,
        sessionTime = os.time() - (self.repository:GetPlayerSession(player.UserId).sessionStart or os.time()),
        runNumber = metrics.runsCompleted + 1,
        hasGamepass = metrics.hasGamepass,
        previousRunPerformance = self:GetPreviousRunPerformance(player)
    })
end

function AnalyticsSessionService:TrackRunEnd(player, finalPosition, coins, runTime)
    local metrics = sessionMetrics[player.UserId]
    if not metrics then
        return
    end
    
    metrics.runsCompleted = metrics.runsCompleted + 1
    metrics.totalCoinsEarned = metrics.totalCoinsEarned + (coins or 0)
    metrics.totalRunTime = metrics.totalRunTime + (runTime or 0)
    
    table.insert(metrics.coinsPerRun, coins or 0)
    
    -- Track run length stats
    local runLength = finalPosition or 0
    if runLength > metrics.longestRun then
        metrics.longestRun = runLength
    end
    if runLength < metrics.shortestRun then
        metrics.shortestRun = runLength
    end
    
    -- Check if perfect run
    if self:WasPerfectRun(player) then
        metrics.perfectRuns = metrics.perfectRuns + 1
    end
    
    -- Reset current run tracking
    metrics.currentPosition = nil
    metrics.currentRunStartTime = nil
    metrics.currentRunStartPosition = 0
    metrics.barriersInCurrentRun = 0
    
    -- Update improvement tracking
    self:UpdateImprovementTracking(player, runLength, runTime, coins)
    
    self.eventCollector:CollectEvent(player, "run_end", {
        finalPosition = runLength,
        coinsEarned = coins or 0,
        runTime = runTime or 0,
        barriersCleared = metrics.barriersInCurrentRun,
        isPerfectRun = self:WasPerfectRun(player),
        totalRuns = metrics.runsCompleted,
        averageCoinsPerRun = metrics.runsCompleted > 0 and (metrics.totalCoinsEarned / metrics.runsCompleted) or 0,
        improvementFromPrevious = self:CalculateRunImprovement(player, runLength)
    })
end

function AnalyticsSessionService:TrackRunProgress(player, currentPosition, barriersCleared)
    local metrics = sessionMetrics[player.UserId]
    if not metrics then
        return
    end
    
    metrics.currentPosition = currentPosition
    metrics.barriersInCurrentRun = barriersCleared or 0
end

-- ========================================
-- BARRIER DIFFICULTY TRACKING
-- ========================================

function AnalyticsSessionService:TrackBarrierAttempt(player, barrierPosition, barrierColor, success)
    local metrics = sessionMetrics[player.UserId]
    local difficulty = difficultyMetrics[player.UserId]
    
    if not metrics or not difficulty then
        return
    end
    
    metrics.totalBarriersAttempted = metrics.totalBarriersAttempted + 1
    
    if not success then
        metrics.totalBarriersFailed = metrics.totalBarriersFailed + 1
        
        -- Track failure by type
        local failType = barrierColor .. "_" .. barrierPosition
        metrics.barrierFailsByType[failType] = (metrics.barrierFailsByType[failType] or 0) + 1
        
        -- Track failure patterns for learning analysis
        table.insert(difficulty.failurePatterns, {
            position = barrierPosition,
            color = barrierColor,
            timestamp = os.time(),
            playerColor = self:GetPlayerCurrentColor(player)
        })
    end
    
    -- Track barrier difficulty by position
    if not difficulty.barriersByPosition[barrierPosition] then
        difficulty.barriersByPosition[barrierPosition] = {attempts = 0, failures = 0}
    end
    
    difficulty.barriersByPosition[barrierPosition].attempts = difficulty.barriersByPosition[barrierPosition].attempts + 1
    if not success then
        difficulty.barriersByPosition[barrierPosition].failures = difficulty.barriersByPosition[barrierPosition].failures + 1
    end
    
    self.eventCollector:CollectEvent(player, success and "barrier_match" or "barrier_miss", {
        barrierPosition = barrierPosition,
        barrierColor = barrierColor,
        playerColor = self:GetPlayerCurrentColor(player),
        reactionTime = self:CalculateReactionTime(player),
        difficulty = self:CalculateBarrierDifficulty(barrierPosition),
        sessionFailRate = metrics.totalBarriersAttempted > 0 and (metrics.totalBarriersFailed / metrics.totalBarriersAttempted) or 0
    })
    
    -- Update adaptive difficulty
    self:UpdateAdaptiveDifficulty(player, barrierPosition, success)
end

function AnalyticsSessionService:TrackColorSwitchTiming(player, reactionTimeMs)
    local difficulty = difficultyMetrics[player.UserId]
    if not difficulty then
        return
    end
    
    table.insert(difficulty.colorSwitchSpeed, reactionTimeMs)
    
    -- Keep only last 20 reaction times
    if #difficulty.colorSwitchSpeed > 20 then
        table.remove(difficulty.colorSwitchSpeed, 1)
    end
    
    -- Update reaction time baseline
    if difficulty.adaptiveSettings then
        local avgReaction = self:CalculateAverageReactionTime(player)
        difficulty.adaptiveSettings.reactionTimeBaseline = avgReaction
    end
    
    self.eventCollector:CollectEvent(player, "color_switch", {
        reactionTime = reactionTimeMs,
        averageReaction = self:CalculateAverageReactionTime(player),
        switchCount = #difficulty.colorSwitchSpeed,
        improvementFromBaseline = reactionTimeMs - (difficulty.adaptiveSettings and difficulty.adaptiveSettings.reactionTimeBaseline or 350)
    })
end

-- ========================================
-- MONETIZATION TRACKING
-- ========================================

function AnalyticsSessionService:TrackGamepassUsage(player, gamepassType, action)
    local metrics = sessionMetrics[player.UserId]
    local monetization = monetizationMetrics[player.UserId]
    
    if not metrics or not monetization then
        return
    end
    
    if not metrics.gamepassUsage[gamepassType] then
        metrics.gamepassUsage[gamepassType] = 0
    end
    metrics.gamepassUsage[gamepassType] = metrics.gamepassUsage[gamepassType] + 1
    metrics.interactionCount = metrics.interactionCount + 1
    
    -- Track monetization metrics
    if not monetization.gamepassUsageFrequency[gamepassType] then
        monetization.gamepassUsageFrequency[gamepassType] = 0
    end
    monetization.gamepassUsageFrequency[gamepassType] = monetization.gamepassUsageFrequency[gamepassType] + 1
    
    local session = self.repository:GetPlayerSession(player.UserId)
    
    self.eventCollector:CollectEvent(player, "gamepass_usage", {
        gamepassType = gamepassType,
        action = action,
        sessionTime = os.time() - (session and session.sessionStart or os.time()),
        totalUsage = metrics.gamepassUsage[gamepassType],
        engagementLevel = self:CalculateEngagementLevel(metrics),
        valueRealized = self:CalculateGamepassValue(metrics)
    })
end

function AnalyticsSessionService:TrackPurchaseAttempt(player, itemType, cost, success)
    local metrics = sessionMetrics[player.UserId]
    local monetization = monetizationMetrics[player.UserId]
    
    if not metrics or not monetization then
        return
    end
    
    metrics.purchaseAttempts = metrics.purchaseAttempts + 1
    
    if success then
        monetization.revenueContribution = monetization.revenueContribution + (cost or 0)
        table.insert(monetization.purchaseHistory, {
            item = itemType,
            cost = cost,
            timestamp = os.time()
        })
    end
    
    self.eventCollector:CollectEvent(player, success and "shop_purchase" or "purchase_failed", {
        itemType = itemType,
        cost = cost or 0,
        playerCoins = self:GetPlayerCoins(player),
        purchaseNumber = metrics.purchaseAttempts,
        sessionTime = os.time() - (self.repository:GetPlayerSession(player.UserId).sessionStart or os.time())
    })
end

-- ========================================
-- ANALYTICS CALCULATIONS
-- ========================================

function AnalyticsSessionService:CalculateImprovementRate(player)
    local metrics = sessionMetrics[player.UserId]
    if not metrics or #metrics.improvementTracking < 2 then
        return 0
    end
    
    local recent = metrics.improvementTracking[#metrics.improvementTracking]
    local baseline = metrics.improvementTracking[1]
    
    local runImprovement = (recent.runLength - baseline.runLength) / math.max(baseline.runLength, 1)
    local coinsImprovement = (recent.coins - baseline.coins) / math.max(baseline.coins, 1)
    
    return (runImprovement + coinsImprovement) / 2
end

function AnalyticsSessionService:CalculateEngagementLevel(metrics)
    if metrics.runsCompleted >= 10 then
        return "high"
    elseif metrics.runsCompleted >= 3 then
        return "medium"
    else
        return "low"
    end
end

function AnalyticsSessionService:CalculateAverageReactionTime(player)
    local difficulty = difficultyMetrics[player.UserId]
    if not difficulty or #difficulty.colorSwitchSpeed == 0 then
        return 350 -- Default
    end
    
    local sum = 0
    for _, time in ipairs(difficulty.colorSwitchSpeed) do
        sum = sum + time
    end
    
    return sum / #difficulty.colorSwitchSpeed
end

function AnalyticsSessionService:CalculateGamepassUsageFrequency(metrics)
    local total = 0
    for _, count in pairs(metrics.gamepassUsage) do
        total = total + count
    end
    
    return metrics.interactionCount > 0 and (total / metrics.interactionCount) or 0
end

function AnalyticsSessionService:CalculateGamepassValue(metrics)
    -- Calculate the value realized from gamepass ownership
    local baseCoinsPerRun = metrics.runsCompleted > 0 and (metrics.totalCoinsEarned / metrics.runsCompleted) or 0
    return baseCoinsPerRun * (metrics.hasGamepass and 2 or 1) -- Assuming 2x multiplier
end

function AnalyticsSessionService:UpdateAdaptiveDifficulty(player, barrierPosition, success)
    local difficulty = difficultyMetrics[player.UserId]
    if not difficulty or not difficulty.adaptiveSettings then
        return
    end
    
    local settings = difficulty.adaptiveSettings
    local adjustment = 0
    
    if success then
        -- Successful barrier - slightly increase difficulty
        adjustment = 0.05
    else
        -- Failed barrier - decrease difficulty
        adjustment = -0.1
    end
    
    -- Apply adjustment with bounds
    settings.currentDifficulty = math.max(0.5, math.min(2.0, settings.currentDifficulty + adjustment))
    
    table.insert(settings.adjustmentHistory, {
        position = barrierPosition,
        adjustment = adjustment,
        newDifficulty = settings.currentDifficulty,
        timestamp = os.time()
    })
    
    -- Keep only last 10 adjustments
    if #settings.adjustmentHistory > 10 then
        table.remove(settings.adjustmentHistory, 1)
    end
end

-- ========================================
-- UTILITY FUNCTIONS
-- ========================================

function AnalyticsSessionService:DetectPlatform(player)
    if player:GetAttribute("Platform") then
        return player:GetAttribute("Platform")
    end
    
    local UserInputService = game:GetService("UserInputService")
    if UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled then
        return "Mobile"
    elseif UserInputService.GamepadEnabled then
        return "Console"
    elseif UserInputService.KeyboardEnabled then
        return "PC"
    end
    
    return "Unknown"
end

function AnalyticsSessionService:IsRejoinPlayer(player)
    -- Simple check - in production this might check against a data store
    return false
end

function AnalyticsSessionService:IsFirstTimePlayer(player)
    return player.AccountAge < 1
end

function AnalyticsSessionService:PlayerCompletedTutorial(player)
    -- Check if player has completed tutorial - would integrate with tutorial system
    return player:GetAttribute("TutorialCompleted") or false
end

function AnalyticsSessionService:CheckPlayerGamepasses(player)
    -- Return list of owned gamepasses
    local MarketplaceService = game:GetService("MarketplaceService")
    local gamepasses = {}
    
    local knownGamepasses = {
        {id = 123456, name = "Double Coins"},
        {id = 123457, name = "Speed Boost"},
        {id = 123458, name = "VIP Access"}
    }
    
    for _, gamepass in ipairs(knownGamepasses) do
        local success, owns = pcall(function()
            return MarketplaceService:UserOwnsGamePassAsync(player.UserId, gamepass.id)
        end)
        
        if success and owns then
            table.insert(gamepasses, gamepass.name)
        end
    end
    
    return gamepasses
end

function AnalyticsSessionService:GetPlayerCoins(player)
    local leaderstats = player:FindFirstChild("leaderstats")
    if leaderstats then
        local coins = leaderstats:FindFirstChild("Coins")
        if coins then
            return coins.Value
        end
    end
    return 0
end

function AnalyticsSessionService:GetPlayerCurrentColor(player)
    -- Integration point with player service
    return player:GetAttribute("CurrentColor") or "UNKNOWN"
end

function AnalyticsSessionService:WasPerfectRun(player)
    local metrics = sessionMetrics[player.UserId]
    return metrics and metrics.barriersInCurrentRun > 0 and metrics.totalBarriersFailed == 0
end

function AnalyticsSessionService:GetPreviousRunPerformance(player)
    local metrics = sessionMetrics[player.UserId]
    if not metrics or #metrics.coinsPerRun == 0 then
        return nil
    end
    
    return {
        coins = metrics.coinsPerRun[#metrics.coinsPerRun],
        runLength = metrics.longestRun
    }
end

function AnalyticsSessionService:CalculateRunImprovement(player, currentRunLength)
    local metrics = sessionMetrics[player.UserId]
    if not metrics or metrics.runsCompleted == 0 then
        return 0
    end
    
    local avgRunLength = metrics.totalRunTime / metrics.runsCompleted
    return currentRunLength - avgRunLength
end

function AnalyticsSessionService:UpdateImprovementTracking(player, runLength, runTime, coins)
    local metrics = sessionMetrics[player.UserId]
    if not metrics then
        return
    end
    
    table.insert(metrics.improvementTracking, {
        runLength = runLength,
        runTime = runTime,
        coins = coins,
        timestamp = os.time()
    })
    
    -- Keep only last 10 runs for improvement tracking
    if #metrics.improvementTracking > 10 then
        table.remove(metrics.improvementTracking, 1)
    end
end

function AnalyticsSessionService:CountGamepassUsage(metrics)
    local total = 0
    for _, count in pairs(metrics.gamepassUsage) do
        total = total + count
    end
    return total
end

function AnalyticsSessionService:CalculateReactionTime(player)
    return self:CalculateAverageReactionTime(player)
end

function AnalyticsSessionService:CalculateBarrierDifficulty(barrierPosition)
    -- Simple difficulty calculation based on position
    return math.min(2.0, 1.0 + (barrierPosition / 100))
end

function AnalyticsSessionService:IdentifyDifficultySpikes(metrics)
    -- Analyze failure patterns to identify difficulty spikes
    local spikes = {}
    
    for failType, count in pairs(metrics.barrierFailsByType) do
        if count > 3 then -- More than 3 failures of same type
            table.insert(spikes, {
                type = failType,
                failureCount = count,
                severity = count > 10 and "high" or "medium"
            })
        end
    end
    
    return spikes
end

function AnalyticsSessionService:GenerateDifficultyRecommendations(metrics)
    local recommendations = {}
    
    local failRate = metrics.totalBarriersAttempted > 0 and (metrics.totalBarriersFailed / metrics.totalBarriersAttempted) or 0
    
    if failRate > 0.7 then
        table.insert(recommendations, "Reduce barrier frequency")
        table.insert(recommendations, "Increase color switch timing window")
    elseif failRate < 0.2 then
        table.insert(recommendations, "Increase barrier frequency")
        table.insert(recommendations, "Add more complex patterns")
    end
    
    return recommendations
end

-- ========================================
-- PUBLIC INTERFACE
-- ========================================

function AnalyticsSessionService:GetSessionMetrics(player)
    return sessionMetrics[player.UserId]
end

function AnalyticsSessionService:GetDifficultyMetrics(player)
    return difficultyMetrics[player.UserId]
end

function AnalyticsSessionService:GetMonetizationMetrics(player)
    return monetizationMetrics[player.UserId]
end

return AnalyticsSessionService
