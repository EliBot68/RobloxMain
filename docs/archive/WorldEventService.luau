-- WorldEventService.luau
-- Handles special world events that occur every 30 minutes with unique visuals and rewards

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local DataStoreService = game:GetService("DataStoreService")

local PlayerService = require(script.Parent.PlayerService)
local GameService = require(script.Parent.GameService)
local AnalyticsService = require(script.Parent.AnalyticsService)
local RemoteEvents = require(ReplicatedStorage.Shared.modules.RemoteEvents)
local GameConstants = require(ReplicatedStorage.Shared.constants.GameConstants)

local WorldEventService = {}

-- DataStore for event leaderboards
local eventLeaderboardStore = DataStoreService:GetDataStore("WorldEventLeaderboards")

-- Event configuration
local EVENT_INTERVAL = 1800 -- 30 minutes in seconds
local EVENT_DURATION = 300 -- 5 minutes per event
local ANNOUNCEMENT_TIME = 60 -- Announce 1 minute before event

-- Event themes with unique visuals and mechanics
local EVENT_THEMES = {
    {
        id = "cosmic_rush",
        name = "🌌 Cosmic Rush",
        description = "Race through the stars with cosmic trails and stellar rewards!",
        colors = {
            primary = Color3.new(0.4, 0.2, 0.8),
            secondary = Color3.new(0.8, 0.4, 1),
            accent = Color3.new(1, 0.8, 0.2)
        },
        effects = {
            barrier_particles = "cosmic_sparkles",
            background_music = "cosmic_ambient",
            player_trail = "star_trail",
            speed_boost = 1.2
        },
        rewards = {
            coin_multiplier = 2.5,
            special_cosmetic = "cosmic_aura",
            bonus_xp = 1.5
        }
    },
    {
        id = "neon_night",
        name = "🌃 Neon Night",
        description = "Light up the darkness in this electrifying neon-themed challenge!",
        colors = {
            primary = Color3.new(0, 1, 1),
            secondary = Color3.new(1, 0, 1),
            accent = Color3.new(0, 1, 0)
        },
        effects = {
            barrier_particles = "neon_glow",
            background_music = "synthwave_beat",
            player_trail = "electric_trail",
            speed_boost = 1.3
        },
        rewards = {
            coin_multiplier = 2.2,
            special_cosmetic = "neon_outline",
            bonus_xp = 1.4
        }
    },
    {
        id = "rainbow_mania",
        name = "🌈 Rainbow Mania",
        description = "Surf the rainbow waves in this colorful spectacular!",
        colors = {
            primary = Color3.new(1, 0.5, 0.5),
            secondary = Color3.new(0.5, 1, 0.5),
            accent = Color3.new(0.5, 0.5, 1)
        },
        effects = {
            barrier_particles = "rainbow_burst",
            background_music = "upbeat_rainbow",
            player_trail = "rainbow_streak",
            speed_boost = 1.1
        },
        rewards = {
            coin_multiplier = 3.0,
            special_cosmetic = "rainbow_trail",
            bonus_xp = 2.0
        }
    },
    {
        id = "storm_surge",
        name = "⚡ Storm Surge",
        description = "Weather the lightning storm with electrifying speed!",
        colors = {
            primary = Color3.new(0.2, 0.2, 0.4),
            secondary = Color3.new(0.8, 0.8, 1),
            accent = Color3.new(1, 1, 0)
        },
        effects = {
            barrier_particles = "lightning_bolts",
            background_music = "storm_thunder",
            player_trail = "electric_charge",
            speed_boost = 1.4
        },
        rewards = {
            coin_multiplier = 2.8,
            special_cosmetic = "storm_aura",
            bonus_xp = 1.8
        }
    },
    {
        id = "golden_hour",
        name = "🌅 Golden Hour",
        description = "Chase the sunset in this warm, glowing adventure!",
        colors = {
            primary = Color3.new(1, 0.8, 0.2),
            secondary = Color3.new(1, 0.6, 0.1),
            accent = Color3.new(1, 0.4, 0)
        },
        effects = {
            barrier_particles = "golden_shimmer",
            background_music = "sunset_melody",
            player_trail = "golden_glow",
            speed_boost = 1.15
        },
        rewards = {
            coin_multiplier = 2.3,
            special_cosmetic = "golden_wings",
            bonus_xp = 1.6
        }
    },
    {
        id = "ice_crystal",
        name = "❄️ Ice Crystal",
        description = "Glide through the frozen wonderland with crystal precision!",
        colors = {
            primary = Color3.new(0.7, 0.9, 1),
            secondary = Color3.new(0.5, 0.8, 1),
            accent = Color3.new(0.3, 0.6, 1)
        },
        effects = {
            barrier_particles = "ice_crystals",
            background_music = "winter_chimes",
            player_trail = "frost_trail",
            speed_boost = 1.0
        },
        rewards = {
            coin_multiplier = 2.4,
            special_cosmetic = "ice_aura",
            bonus_xp = 1.5
        }
    }
}

-- Event state tracking
local currentEvent = nil
local eventStartTime = 0
local eventLeaderboard = {}
local countdownBoard = nil
local nextEventTime = 0
local eventHistory = {}

function WorldEventService:GetCurrentTime()
    return tick()
end

function WorldEventService:GetNextEventTime()
    local currentTime = self:GetCurrentTime()
    local timeSinceLastEvent = currentTime % EVENT_INTERVAL
    return currentTime + (EVENT_INTERVAL - timeSinceLastEvent)
end

function WorldEventService:GetTimeUntilNextEvent()
    return self:GetNextEventTime() - self:GetCurrentTime()
end

function WorldEventService:IsEventActive()
    return currentEvent ~= nil and (self:GetCurrentTime() - eventStartTime) < EVENT_DURATION
end

function WorldEventService:GetRandomEventTheme()
    return EVENT_THEMES[math.random(1, #EVENT_THEMES)]
end

function WorldEventService:CreateCountdownBoard()
    local marketPlaza = Workspace:FindFirstChild("MarketPlaza")
    if not marketPlaza then
        warn("⚠️ MarketPlaza not found for countdown board!")
        return
    end
    
    -- Create countdown board structure
    local boardBase = Instance.new("Part")
    boardBase.Name = "EventCountdownBoard"
    boardBase.Size = Vector3.new(8, 6, 1)
    boardBase.Material = Enum.Material.Neon
    boardBase.BrickColor = BrickColor.new("Dark blue")
    boardBase.Anchored = true
    boardBase.CanCollide = false
    boardBase.Position = Vector3.new(50, 8, -10) -- Adjust position as needed
    boardBase.Parent = marketPlaza
    
    -- Add click detector
    local clickDetector = Instance.new("ClickDetector")
    clickDetector.MaxActivationDistance = 20
    clickDetector.Parent = boardBase
    
    -- Create main display GUI
    local surfaceGui = Instance.new("SurfaceGui")
    surfaceGui.Face = Enum.NormalId.Front
    surfaceGui.Parent = boardBase
    
    -- Background frame
    local mainFrame = Instance.new("Frame")
    mainFrame.Size = UDim2.new(1, 0, 1, 0)
    mainFrame.BackgroundColor3 = Color3.new(0.1, 0.1, 0.2)
    mainFrame.BorderSizePixel = 0
    mainFrame.Parent = surfaceGui
    
    -- Title
    local titleLabel = Instance.new("TextLabel")
    titleLabel.Size = UDim2.new(1, 0, 0.25, 0)
    titleLabel.Position = UDim2.new(0, 0, 0, 0)
    titleLabel.BackgroundTransparency = 1
    titleLabel.Text = "🌟 NEXT WORLD EVENT"
    titleLabel.TextColor3 = Color3.new(1, 1, 0)
    titleLabel.TextScaled = true
    titleLabel.Font = Enum.Font.SourceSansBold
    titleLabel.TextStrokeTransparency = 0
    titleLabel.TextStrokeColor3 = Color3.new(0, 0, 0)
    titleLabel.Parent = mainFrame
    
    -- Countdown timer
    local countdownLabel = Instance.new("TextLabel")
    countdownLabel.Size = UDim2.new(1, 0, 0.4, 0)
    countdownLabel.Position = UDim2.new(0, 0, 0.25, 0)
    countdownLabel.BackgroundTransparency = 1
    countdownLabel.Text = "Loading..."
    countdownLabel.TextColor3 = Color3.new(0.8, 1, 0.8)
    countdownLabel.TextScaled = true
    countdownLabel.Font = Enum.Font.SourceSans
    countdownLabel.TextStrokeTransparency = 0
    countdownLabel.TextStrokeColor3 = Color3.new(0, 0, 0)
    countdownLabel.Parent = mainFrame
    
    -- Event description
    local descLabel = Instance.new("TextLabel")
    descLabel.Size = UDim2.new(1, 0, 0.35, 0)
    descLabel.Position = UDim2.new(0, 0, 0.65, 0)
    descLabel.BackgroundTransparency = 1
    descLabel.Text = "Unique visuals • Double coins • Special leaderboards"
    descLabel.TextColor3 = Color3.new(0.7, 0.7, 1)
    descLabel.TextScaled = true
    descLabel.Font = Enum.Font.SourceSans
    descLabel.TextStrokeTransparency = 0
    descLabel.TextStrokeColor3 = Color3.new(0, 0, 0)
    descLabel.TextWrapped = true
    descLabel.Parent = mainFrame
    
    -- Add glow effect
    local glowPart = Instance.new("Part")
    glowPart.Name = "GlowEffect"
    glowPart.Size = Vector3.new(10, 8, 0.5)
    glowPart.Material = Enum.Material.ForceField
    glowPart.BrickColor = BrickColor.new("Bright blue")
    glowPart.Transparency = 0.8
    glowPart.Anchored = true
    glowPart.CanCollide = false
    glowPart.Position = boardBase.Position - Vector3.new(0, 0, 0.75)
    glowPart.Parent = boardBase
    
    -- Store references
    countdownBoard = {
        base = boardBase,
        countdownLabel = countdownLabel,
        titleLabel = titleLabel,
        descLabel = descLabel,
        glowPart = glowPart,
        clickDetector = clickDetector
    }
    
    -- Setup click handler
    clickDetector.MouseClick:Connect(function(player)
        self:ShowEventInfo(player)
    end)
    
    -- Start countdown update loop
    self:StartCountdownUpdate()
    
    print("🌟 World Event countdown board created!")
end

function WorldEventService:StartCountdownUpdate()
    spawn(function()
        while countdownBoard and countdownBoard.countdownLabel do
            local timeUntil = self:GetTimeUntilNextEvent()
            
            if self:IsEventActive() then
                -- Show event active status
                local timeLeft = EVENT_DURATION - (self:GetCurrentTime() - eventStartTime)
                local minutes = math.floor(timeLeft / 60)
                local seconds = math.floor(timeLeft % 60)
                
                countdownBoard.countdownLabel.Text = string.format("🔥 EVENT ACTIVE!\n%d:%02d remaining", minutes, seconds)
                countdownBoard.countdownLabel.TextColor3 = Color3.new(1, 0.5, 0.5)
                countdownBoard.titleLabel.Text = "🔥 " .. (currentEvent and currentEvent.name or "WORLD EVENT ACTIVE")
                
                -- Update glow color
                if countdownBoard.glowPart then
                    countdownBoard.glowPart.BrickColor = BrickColor.new("Bright red")
                end
            else
                -- Show countdown to next event
                local hours = math.floor(timeUntil / 3600)
                local minutes = math.floor((timeUntil % 3600) / 60)
                local seconds = math.floor(timeUntil % 60)
                
                if hours > 0 then
                    countdownBoard.countdownLabel.Text = string.format("%d:%02d:%02d", hours, minutes, seconds)
                else
                    countdownBoard.countdownLabel.Text = string.format("%d:%02d", minutes, seconds)
                end
                
                countdownBoard.countdownLabel.TextColor3 = Color3.new(0.8, 1, 0.8)
                countdownBoard.titleLabel.Text = "🌟 NEXT WORLD EVENT"
                
                -- Update glow color
                if countdownBoard.glowPart then
                    countdownBoard.glowPart.BrickColor = BrickColor.new("Bright blue")
                end
                
                -- Check if we should announce upcoming event
                if timeUntil <= ANNOUNCEMENT_TIME and timeUntil > ANNOUNCEMENT_TIME - 5 then
                    self:AnnounceUpcomingEvent()
                end
            end
            
            wait(1)
        end
    end)
end

function WorldEventService:ShowEventInfo(player)
    local eventData = {
        isActive = self:IsEventActive(),
        currentEvent = currentEvent,
        timeUntilNext = self:GetTimeUntilNextEvent(),
        eventDuration = EVENT_DURATION,
        leaderboard = self:GetTopEventScores(10)
    }
    
    RemoteEvents.ShowWorldEventInfo:FireClient(player, eventData)
end

function WorldEventService:AnnounceUpcomingEvent()
    local nextTheme = self:GetRandomEventTheme()
    
    for _, player in pairs(Players:GetPlayers()) do
        RemoteEvents.ShowEventAnnouncement:FireClient(player, {
            message = "🌟 World Event starting in 1 minute!",
            eventName = nextTheme.name,
            description = nextTheme.description,
            timeUntilStart = ANNOUNCEMENT_TIME
        })
    end
    
    print("📢 Announced upcoming event: " .. nextTheme.name)
end

function WorldEventService:StartWorldEvent()
    if self:IsEventActive() then
        return -- Event already active
    end
    
    -- Select random event theme
    currentEvent = self:GetRandomEventTheme()
    eventStartTime = self:GetCurrentTime()
    eventLeaderboard = {}
    
    -- Log event start
    table.insert(eventHistory, {
        theme = currentEvent,
        startTime = eventStartTime,
        participants = {}
    })
    
    -- Announce event start to all players
    for _, player in pairs(Players:GetPlayers()) do
        RemoteEvents.WorldEventStarted:FireClient(player, currentEvent)
        
        -- Track participation
        if #eventHistory > 0 then
            table.insert(eventHistory[#eventHistory].participants, player.UserId)
        end
        
        -- Analytics
        if AnalyticsService then
            AnalyticsService:LogEvent(player, "world_event_started", {
                eventId = currentEvent.id,
                eventName = currentEvent.name,
                startTime = eventStartTime
            })
        end
    end
    
    -- Schedule event end
    spawn(function()
        wait(EVENT_DURATION)
        self:EndWorldEvent()
    end)
    
    print("🌟 World Event started: " .. currentEvent.name)
end

function WorldEventService:EndWorldEvent()
    if not self:IsEventActive() then
        return
    end
    
    -- Calculate final leaderboard
    local finalLeaderboard = self:GetTopEventScores(10)
    
    -- Announce event end and results
    for _, player in pairs(Players:GetPlayers()) do
        RemoteEvents.WorldEventEnded:FireClient(player, {
            eventTheme = currentEvent,
            finalLeaderboard = finalLeaderboard,
            playerRank = self:GetPlayerEventRank(player)
        })
    end
    
    -- Save leaderboard to DataStore
    if currentEvent then
        self:SaveEventLeaderboard(currentEvent.id, finalLeaderboard)
    end
    
    -- Clear current event
    local endedEvent = currentEvent
    currentEvent = nil
    eventStartTime = 0
    
    print("🏁 World Event ended: " .. (endedEvent and endedEvent.name or "Unknown"))
end

function WorldEventService:RecordEventScore(player, score, gameData)
    if not self:IsEventActive() then
        return false
    end
    
    local userId = tostring(player.UserId)
    local eventScore = {
        userId = userId,
        playerName = player.Name,
        score = score,
        timestamp = self:GetCurrentTime(),
        gameData = gameData or {}
    }
    
    -- Apply event multipliers
    if currentEvent and currentEvent.rewards then
        eventScore.coinReward = math.floor((gameData.coinsEarned or 0) * (currentEvent.rewards.coin_multiplier or 1))
        eventScore.xpReward = math.floor((gameData.xpEarned or 0) * (currentEvent.rewards.bonus_xp or 1))
    end
    
    -- Track world event quests
    local QuestService = require(script.Parent.QuestService)
    if QuestService then
        -- General participation
        QuestService:UpdateQuestProgress(player, "world_event_participation", 1)
        
        -- High score achievement
        if score >= 20 then
            QuestService:UpdateQuestProgress(player, "world_event_high_score", score)
        end
        
        -- Specific event completion
        if currentEvent then
            QuestService:UpdateQuestProgress(player, "specific_event_completion", 1, {
                eventId = currentEvent.id
            })
            
            -- Specific event score
            if score >= 15 then
                QuestService:UpdateQuestProgress(player, "specific_event_score", score, {
                    eventId = currentEvent.id
                })
            end
        end
    end
    
    -- Add to leaderboard (keep top scores per player)
    if not eventLeaderboard[userId] or eventLeaderboard[userId].score < score then
        eventLeaderboard[userId] = eventScore
        
        -- Give special rewards for new personal bests
        self:GiveEventRewards(player, eventScore)
        
        -- Analytics
        if AnalyticsService then
            AnalyticsService:LogEvent(player, "world_event_score", {
                eventId = currentEvent.id,
                score = score,
                coinReward = eventScore.coinReward,
                xpReward = eventScore.xpReward,
                isNewBest = true
            })
        end
        
        print("🏆 " .. player.Name .. " set new event best: " .. score .. " in " .. currentEvent.name)
        return true
    end
    
    return false
end

function WorldEventService:GiveEventRewards(player, eventScore)
    if not currentEvent or not eventScore then return end
    
    local playerData = PlayerService:GetPlayerData(player)
    if not playerData then return end
    
    -- Apply coin rewards
    if eventScore.coinReward and eventScore.coinReward > 0 then
        playerData.coins = playerData.coins + eventScore.coinReward
        playerData.totalCoinsEarned = (playerData.totalCoinsEarned or 0) + eventScore.coinReward
        
        -- Notify client
        RemoteEvents.CoinCollected:FireClient(player, playerData.coins)
    end
    
    -- Apply XP rewards
    if eventScore.xpReward and eventScore.xpReward > 0 then
        RemoteEvents.XpGained:FireClient(player, eventScore.xpReward)
    end
    
    -- Give special cosmetic (chance based)
    if currentEvent.rewards.special_cosmetic and math.random() < 0.1 then -- 10% chance
        RemoteEvents.ApplySpecialEffect:FireClient(player, currentEvent.rewards.special_cosmetic, 1800) -- 30 minutes
    end
    
    -- Update player data
    PlayerService:UpdatePlayerData(player, playerData)
    
    -- Show reward notification
    RemoteEvents.ShowEventReward:FireClient(player, {
        coins = eventScore.coinReward,
        xp = eventScore.xpReward,
        eventName = currentEvent.name,
        isSpecialReward = true
    })
end

function WorldEventService:GetTopEventScores(limit)
    local scores = {}
    
    for userId, scoreData in pairs(eventLeaderboard) do
        table.insert(scores, scoreData)
    end
    
    -- Sort by score (descending)
    table.sort(scores, function(a, b)
        return a.score > b.score
    end)
    
    -- Return top scores
    local topScores = {}
    for i = 1, math.min(limit or 10, #scores) do
        table.insert(topScores, scores[i])
    end
    
    return topScores
end

function WorldEventService:GetPlayerEventRank(player)
    local userId = tostring(player.UserId)
    local topScores = self:GetTopEventScores(100) -- Check top 100
    
    for rank, scoreData in ipairs(topScores) do
        if scoreData.userId == userId then
            return rank
        end
    end
    
    return nil -- Player not in top ranks
end

function WorldEventService:SaveEventLeaderboard(eventId, leaderboard)
    local success = pcall(function()
        local key = eventId .. "_" .. os.date("%Y_%m_%d_%H")
        eventLeaderboardStore:SetAsync(key, {
            eventId = eventId,
            timestamp = self:GetCurrentTime(),
            leaderboard = leaderboard
        })
    end)
    
    if success then
        print("💾 Saved event leaderboard for " .. eventId)
    else
        warn("❌ Failed to save event leaderboard for " .. eventId)
    end
end

function WorldEventService:GetEventHistory(limit)
    limit = limit or 5
    local recentHistory = {}
    
    for i = math.max(1, #eventHistory - limit + 1), #eventHistory do
        table.insert(recentHistory, eventHistory[i])
    end
    
    return recentHistory
end

function WorldEventService:GetCurrentEventMultiplier()
    if self:IsEventActive() and currentEvent and currentEvent.rewards then
        return currentEvent.rewards.coin_multiplier or 2.0
    end
    return 1.0
end

function WorldEventService:ScheduleEvents()
    -- Calculate time until next event
    local timeUntilNext = self:GetTimeUntilNextEvent()
    
    print("⏰ Next world event scheduled in " .. math.floor(timeUntilNext / 60) .. " minutes")
    
    -- Schedule the next event
    spawn(function()
        wait(timeUntilNext)
        self:StartWorldEvent()
        
        -- Schedule recurring events
        while true do
            wait(EVENT_INTERVAL)
            if not self:IsEventActive() then
                self:StartWorldEvent()
            end
        end
    end)
end

function WorldEventService:Initialize()
    print("🌟 WorldEventService initializing...")
    
    -- Wait for workspace to load
    wait(2)
    
    -- Create countdown board
    self:CreateCountdownBoard()
    
    -- Schedule events
    self:ScheduleEvents()
    
    print("✅ WorldEventService initialized successfully!")
    print("🌟 Events occur every " .. (EVENT_INTERVAL / 60) .. " minutes")
    print("⏱️ Each event lasts " .. (EVENT_DURATION / 60) .. " minutes")
end

-- Remote event handlers
RemoteEvents.GetWorldEventInfo = RemoteEvents:GetRemoteEvent("GetWorldEventInfo")
RemoteEvents.ShowWorldEventInfo = RemoteEvents:GetRemoteEvent("ShowWorldEventInfo")
RemoteEvents.WorldEventStarted = RemoteEvents:GetRemoteEvent("WorldEventStarted")
RemoteEvents.WorldEventEnded = RemoteEvents:GetRemoteEvent("WorldEventEnded")
RemoteEvents.ShowEventAnnouncement = RemoteEvents:GetRemoteEvent("ShowEventAnnouncement")
RemoteEvents.ShowEventReward = RemoteEvents:GetRemoteEvent("ShowEventReward")

RemoteEvents.GetWorldEventInfo.OnServerEvent:Connect(function(player)
    WorldEventService:ShowEventInfo(player)
end)

-- Auto-initialize
WorldEventService:Initialize()

return WorldEventService
