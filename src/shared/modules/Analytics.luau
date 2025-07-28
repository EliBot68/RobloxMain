-- Analytics.luau
-- Client-side analytics helper for logging events

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RemoteEvents = require(ReplicatedStorage.Shared.modules.RemoteEvents)

local Analytics = {}

-- Analytics event types (must match server)
Analytics.EventTypes = {
    RUN_START = "run_start",
    BARRIER_MATCH = "barrier_match",
    BARRIER_MISS = "barrier_miss", 
    GOLDEN_GATE = "golden_gate",
    COIN_COLLECTED = "coin_collected",
    RUN_END = "run_end",
    PLAYER_JOIN = "player_join",
    PLAYER_LEAVE = "player_leave",
    SHOP_PURCHASE = "shop_purchase"
}

-- Log an analytics event to the server
function Analytics:LogEvent(eventType, eventData)
    -- Validate event type
    local validEventType = false
    for _, validType in pairs(Analytics.EventTypes) do
        if eventType == validType then
            validEventType = true
            break
        end
    end
    
    if not validEventType then
        warn("❌ Invalid analytics event type: " .. tostring(eventType))
        return
    end
    
    -- Send to server
    RemoteEvents.LogAnalyticsEvent:FireServer(eventType, eventData)
    print("📊 Analytics logged: " .. eventType)
end

-- Quick helper functions for common events
function Analytics:LogRunStart(startColor)
    self:LogEvent(self.EventTypes.RUN_START, {
        startColor = startColor,
        startTime = tick()
    })
end

function Analytics:LogBarrierMatch(barrierColor, playerColor, score)
    self:LogEvent(self.EventTypes.BARRIER_MATCH, {
        barrierColor = barrierColor,
        playerColor = playerColor,
        currentScore = score
    })
end

function Analytics:LogBarrierMiss(barrierColor, playerColor, score)
    self:LogEvent(self.EventTypes.BARRIER_MISS, {
        barrierColor = barrierColor,
        playerColor = playerColor,
        currentScore = score
    })
end

function Analytics:LogGoldenGate(gateType, bonusPoints)
    self:LogEvent(self.EventTypes.GOLDEN_GATE, {
        gateType = gateType,
        bonusPoints = bonusPoints
    })
end

function Analytics:LogCoinCollected(coinMultiplier, totalCoins)
    self:LogEvent(self.EventTypes.COIN_COLLECTED, {
        coinMultiplier = coinMultiplier,
        totalCoins = totalCoins
    })
end

function Analytics:LogRunEnd(finalScore, gameTime, endReason)
    self:LogEvent(self.EventTypes.RUN_END, {
        finalScore = finalScore,
        gameTime = gameTime,
        endReason = endReason
    })
end

return Analytics
