-- TournamentService.luau
-- Manages weekly tournaments with leaderboards and exclusive prizes

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local DataStoreService = game:GetService("DataStoreService")

local RemoteEvents = require(ReplicatedStorage.Shared.modules.RemoteEvents)

-- Forward declare services
local PlayerService = nil
local AnalyticsService = nil
local QuestService = nil

local TournamentService = {}

-- Data stores
local tournamentDataStore = DataStoreService:GetDataStore("TournamentData_v1")
local weeklyLeaderboardStore = DataStoreService:GetDataStore("WeeklyLeaderboards_v1")

-- Tournament state
local currentWeek = nil
local weeklyLeaderboards = {
    topScore = {},
    mostRuns = {},
    longestStreak = {}
}

-- Player weekly stats
local playerWeeklyStats = {}

-- Tournament prizes (exclusive cosmetics)
local tournamentPrizes = {
    topScore = {
        [1] = {type = "trail", id = "tournament_champion_trail", name = "Champion's Golden Trail", color = Color3.new(1, 0.8, 0)},
        [2] = {type = "trail", id = "tournament_silver_trail", name = "Silver Streak Trail", color = Color3.new(0.8, 0.8, 0.8)},
        [3] = {type = "trail", id = "tournament_bronze_trail", name = "Bronze Runner Trail", color = Color3.new(0.7, 0.4, 0.2)},
        [4] = {type = "skin", id = "tournament_top5_skin", name = "Elite Runner Skin", color = Color3.new(0.2, 0.8, 1)},
        [5] = {type = "skin", id = "tournament_top5_skin", name = "Elite Runner Skin", color = Color3.new(0.2, 0.8, 1)}
    },
    mostRuns = {
        [1] = {type = "hat", id = "tournament_grind_crown", name = "Grinder's Crown", color = Color3.new(1, 0.6, 0)},
        [2] = {type = "hat", id = "tournament_dedication_helm", name = "Dedication Helmet", color = Color3.new(0.6, 0.6, 0.9)},
        [3] = {type = "accessory", id = "tournament_stamina_badge", name = "Stamina Badge", color = Color3.new(0.8, 0.2, 0.2)},
        [4] = {type = "emote", id = "tournament_victory_dance", name = "Victory Dance Emote", animation = "rbxassetid://123456789"},
        [5] = {type = "emote", id = "tournament_victory_dance", name = "Victory Dance Emote", animation = "rbxassetid://123456789"}
    },
    longestStreak = {
        [1] = {type = "aura", id = "tournament_perfect_aura", name = "Perfectionist Aura", color = Color3.new(1, 1, 0.8)},
        [2] = {type = "aura", id = "tournament_precision_aura", name = "Precision Aura", color = Color3.new(0.8, 1, 0.8)},
        [3] = {type = "particle", id = "tournament_streak_particles", name = "Streak Particles", effect = "sparkles"},
        [4] = {type = "title", id = "tournament_consistent", name = "The Consistent", displayText = "⚡ The Consistent"},
        [5] = {type = "title", id = "tournament_consistent", name = "The Consistent", displayText = "⚡ The Consistent"}
    }
}

function TournamentService:Init()
    print("🏆 TournamentService initializing...")
    
    self:LoadCurrentWeek()
    self:SetupRemoteEvents()
    self:StartWeeklyResetScheduler()
    
    -- Load current leaderboards
    self:LoadWeeklyLeaderboards()
    
    print("✅ TournamentService initialized! Current week: " .. tostring(currentWeek))
end

function TournamentService:GetCurrentWeek()
    -- Calculate week number based on days since epoch
    local currentTime = os.time()
    local daysSinceEpoch = math.floor(currentTime / 86400) -- 86400 seconds in a day
    local weeksSinceEpoch = math.floor(daysSinceEpoch / 7)
    return weeksSinceEpoch
end

function TournamentService:LoadCurrentWeek()
    currentWeek = self:GetCurrentWeek()
    
    -- Initialize player weekly stats for connected players
    for _, player in pairs(Players:GetPlayers()) do
        self:InitializePlayerWeeklyStats(player)
    end
end

function TournamentService:InitializePlayerWeeklyStats(player)
    local weekKey = "week_" .. currentWeek
    local userId = tostring(player.UserId)
    
    if not playerWeeklyStats[userId] then
        playerWeeklyStats[userId] = {}
    end
    
    if not playerWeeklyStats[userId][weekKey] then
        playerWeeklyStats[userId][weekKey] = {
            topScore = 0,
            totalRuns = 0,
            longestStreak = 0,
            currentStreak = 0,
            lastScoreTime = 0
        }
        
        -- Try to load existing data
        pcall(function()
            local savedData = tournamentDataStore:GetAsync(userId .. "_" .. weekKey)
            if savedData then
                playerWeeklyStats[userId][weekKey] = savedData
            end
        end)
    end
end

function TournamentService:SavePlayerWeeklyStats(player)
    local weekKey = "week_" .. currentWeek
    local userId = tostring(player.UserId)
    
    if playerWeeklyStats[userId] and playerWeeklyStats[userId][weekKey] then
        pcall(function()
            tournamentDataStore:SetAsync(userId .. "_" .. weekKey, playerWeeklyStats[userId][weekKey])
        end)
    end
end

function TournamentService:RecordPlayerScore(player, score, isNewHighScore)
    local userId = tostring(player.UserId)
    local weekKey = "week_" .. currentWeek
    
    self:InitializePlayerWeeklyStats(player)
    
    local weeklyStats = playerWeeklyStats[userId][weekKey]
    if not weeklyStats then return end
    
    -- Update stats
    weeklyStats.totalRuns = weeklyStats.totalRuns + 1
    weeklyStats.lastScoreTime = os.time()
    
    if score > weeklyStats.topScore then
        weeklyStats.topScore = score
        self:UpdateLeaderboard("topScore", player, score)
    end
    
    self:UpdateLeaderboard("mostRuns", player, weeklyStats.totalRuns)
    
    -- Save stats
    self:SavePlayerWeeklyStats(player)
    
    -- Send updated tournament data to player
    self:SendTournamentDataToPlayer(player)
    
    -- Log analytics
    if AnalyticsService then
        AnalyticsService:LogEvent(player, "tournament_score_recorded", {
            score = score,
            week = currentWeek,
            totalRuns = weeklyStats.totalRuns,
            isNewPersonalBest = score > (weeklyStats.topScore or 0)
        })
    end
end

function TournamentService:RecordPerfectGame(player)
    local userId = tostring(player.UserId)
    local weekKey = "week_" .. currentWeek
    
    self:InitializePlayerWeeklyStats(player)
    
    local weeklyStats = playerWeeklyStats[userId][weekKey]
    if not weeklyStats then return end
    
    -- Update streak
    weeklyStats.currentStreak = weeklyStats.currentStreak + 1
    if weeklyStats.currentStreak > weeklyStats.longestStreak then
        weeklyStats.longestStreak = weeklyStats.currentStreak
        self:UpdateLeaderboard("longestStreak", player, weeklyStats.longestStreak)
    end
    
    -- Save stats
    self:SavePlayerWeeklyStats(player)
    
    -- Send updated tournament data to player
    self:SendTournamentDataToPlayer(player)
end

function TournamentService:RecordImperfectGame(player)
    local userId = tostring(player.UserId)
    local weekKey = "week_" .. currentWeek
    
    self:InitializePlayerWeeklyStats(player)
    
    local weeklyStats = playerWeeklyStats[userId][weekKey]
    if not weeklyStats then return end
    
    -- Reset current streak
    weeklyStats.currentStreak = 0
    
    -- Save stats
    self:SavePlayerWeeklyStats(player)
end

function TournamentService:UpdateLeaderboard(category, player, value)
    local leaderboard = weeklyLeaderboards[category]
    if not leaderboard then return end
    
    -- Find existing entry or create new one
    local playerEntry = nil
    for i, entry in ipairs(leaderboard) do
        if entry.player.UserId == player.UserId then
            playerEntry = entry
            break
        end
    end
    
    if not playerEntry then
        playerEntry = {
            player = player,
            value = value,
            displayName = player.DisplayName,
            userId = player.UserId
        }
        table.insert(leaderboard, playerEntry)
    else
        playerEntry.value = value
    end
    
    -- Sort leaderboard
    table.sort(leaderboard, function(a, b)
        return a.value > b.value
    end)
    
    -- Keep only top 50
    while #leaderboard > 50 do
        table.remove(leaderboard, #leaderboard)
    end
    
    -- Save leaderboard
    self:SaveWeeklyLeaderboards()
    
    -- Broadcast leaderboard update
    self:BroadcastLeaderboardUpdate(category)
end

function TournamentService:SaveWeeklyLeaderboards()
    local weekKey = "week_" .. currentWeek
    
    pcall(function()
        local saveData = {}
        for category, leaderboard in pairs(weeklyLeaderboards) do
            saveData[category] = {}
            for i, entry in ipairs(leaderboard) do
                if i <= 10 then -- Save top 10 for each category
                    table.insert(saveData[category], {
                        displayName = entry.displayName,
                        userId = entry.userId,
                        value = entry.value
                    })
                end
            end
        end
        weeklyLeaderboardStore:SetAsync(weekKey, saveData)
    end)
end

function TournamentService:LoadWeeklyLeaderboards()
    local weekKey = "week_" .. currentWeek
    
    pcall(function()
        local savedData = weeklyLeaderboardStore:GetAsync(weekKey)
        if savedData then
            for category, leaderboard in pairs(savedData) do
                weeklyLeaderboards[category] = {}
                for _, entry in ipairs(leaderboard) do
                    -- Try to find the actual player object
                    local player = Players:GetPlayerByUserId(entry.userId)
                    if player then
                        table.insert(weeklyLeaderboards[category], {
                            player = player,
                            displayName = entry.displayName,
                            userId = entry.userId,
                            value = entry.value
                        })
                    else
                        -- Player not online, store placeholder
                        table.insert(weeklyLeaderboards[category], {
                            player = nil,
                            displayName = entry.displayName,
                            userId = entry.userId,
                            value = entry.value
                        })
                    end
                end
            end
        end
    end)
end

function TournamentService:GetTournamentData(player)
    local userId = tostring(player.UserId)
    local weekKey = "week_" .. currentWeek
    
    self:InitializePlayerWeeklyStats(player)
    
    local playerStats = playerWeeklyStats[userId][weekKey] or {}
    
    -- Get player rankings
    local rankings = {}
    for category, leaderboard in pairs(weeklyLeaderboards) do
        rankings[category] = {
            rank = nil,
            total = #leaderboard
        }
        
        for i, entry in ipairs(leaderboard) do
            if entry.userId == player.UserId then
                rankings[category].rank = i
                break
            end
        end
    end
    
    -- Calculate time until next reset
    local currentTime = os.time()
    local secondsInWeek = 7 * 24 * 60 * 60
    local weekStart = currentWeek * secondsInWeek
    local nextWeekStart = weekStart + secondsInWeek
    local timeUntilReset = nextWeekStart - currentTime
    
    return {
        currentWeek = currentWeek,
        playerStats = playerStats,
        rankings = rankings,
        leaderboards = self:GetFormattedLeaderboards(),
        timeUntilReset = timeUntilReset,
        prizes = tournamentPrizes
    }
end

function TournamentService:GetFormattedLeaderboards()
    local formatted = {}
    
    for category, leaderboard in pairs(weeklyLeaderboards) do
        formatted[category] = {}
        for i, entry in ipairs(leaderboard) do
            if i <= 10 then -- Only send top 10
                table.insert(formatted[category], {
                    rank = i,
                    displayName = entry.displayName,
                    value = entry.value,
                    isPlayer = entry.userId == Players.LocalPlayer and Players.LocalPlayer.UserId or nil
                })
            end
        end
    end
    
    return formatted
end

function TournamentService:SendTournamentDataToPlayer(player)
    local tournamentData = self:GetTournamentData(player)
    RemoteEvents.TournamentDataUpdated:FireClient(player, tournamentData)
end

function TournamentService:BroadcastLeaderboardUpdate(category)
    for _, player in pairs(Players:GetPlayers()) do
        local tournamentData = self:GetTournamentData(player)
        RemoteEvents.TournamentLeaderboardUpdated:FireClient(player, {
            category = category,
            leaderboard = tournamentData.leaderboards[category],
            playerRanking = tournamentData.rankings[category]
        })
    end
end

function TournamentService:StartWeeklyResetScheduler()
    -- Check for week reset every hour
    spawn(function()
        while true do
            wait(3600) -- Check every hour
            
            local newWeek = self:GetCurrentWeek()
            if newWeek ~= currentWeek then
                self:ProcessWeeklyReset()
            end
        end
    end)
end

function TournamentService:ProcessWeeklyReset()
    local oldWeek = currentWeek
    local newWeek = self:GetCurrentWeek()
    
    print("🏆 Processing weekly tournament reset: " .. oldWeek .. " → " .. newWeek)
    
    -- Award prizes for previous week
    self:AwardWeeklyPrizes(oldWeek)
    
    -- Reset leaderboards
    weeklyLeaderboards = {
        topScore = {},
        mostRuns = {},
        longestStreak = {}
    }
    
    -- Update current week
    currentWeek = newWeek
    
    -- Reset player weekly stats
    for userId, playerStats in pairs(playerWeeklyStats) do
        local newWeekKey = "week_" .. newWeek
        if not playerStats[newWeekKey] then
            playerStats[newWeekKey] = {
                topScore = 0,
                totalRuns = 0,
                longestStreak = 0,
                currentStreak = 0,
                lastScoreTime = 0
            }
        end
    end
    
    -- Broadcast reset to all players
    for _, player in pairs(Players:GetPlayers()) do
        RemoteEvents.TournamentWeekReset:FireClient(player, {
            newWeek = newWeek,
            oldWeek = oldWeek
        })
        self:SendTournamentDataToPlayer(player)
    end
    
    -- Log analytics
    if AnalyticsService then
        AnalyticsService:LogEvent(nil, "tournament_week_reset", {
            oldWeek = oldWeek,
            newWeek = newWeek,
            activePlayerCount = #Players:GetPlayers()
        })
    end
    
    print("✅ Tournament week reset completed!")
end

function TournamentService:AwardWeeklyPrizes(week)
    local weekKey = "week_" .. week
    
    for category, leaderboard in pairs(weeklyLeaderboards) do
        local prizes = tournamentPrizes[category]
        if not prizes then continue end
        
        for rank = 1, math.min(5, #leaderboard) do
            local entry = leaderboard[rank]
            local prize = prizes[rank]
            
            if entry and prize and entry.player then
                self:AwardPrize(entry.player, prize, category, rank, week)
            end
        end
    end
end

function TournamentService:AwardPrize(player, prize, category, rank, week)
    if not PlayerService then return end
    
    local playerData = PlayerService:GetPlayerData(player)
    if not playerData then return end
    
    -- Initialize tournament prizes if not exists
    if not playerData.tournamentPrizes then
        playerData.tournamentPrizes = {}
    end
    
    -- Add prize to player's collection
    local prizeId = prize.id .. "_week" .. week
    playerData.tournamentPrizes[prizeId] = {
        id = prize.id,
        name = prize.name,
        type = prize.type,
        category = category,
        rank = rank,
        week = week,
        dateEarned = os.time(),
        color = prize.color,
        animation = prize.animation,
        effect = prize.effect,
        displayText = prize.displayText
    }
    
    -- Send prize notification
    RemoteEvents.TournamentPrizeAwarded:FireClient(player, {
        prize = playerData.tournamentPrizes[prizeId],
        category = category,
        rank = rank,
        week = week
    })
    
    -- Update quest progress
    if QuestService then
        QuestService:UpdateQuestProgress(player, "tournament_prizes", 1)
    end
    
    -- Log analytics
    if AnalyticsService then
        AnalyticsService:LogEvent(player, "tournament_prize_awarded", {
            prizeId = prizeId,
            category = category,
            rank = rank,
            week = week,
            prizeName = prize.name
        })
    end
    
    print("🏆 Awarded " .. prize.name .. " to " .. player.Name .. " (Rank " .. rank .. " in " .. category .. ")")
end

function TournamentService:GetPlayerPrizes(player)
    if not PlayerService then return {} end
    
    local playerData = PlayerService:GetPlayerData(player)
    return playerData.tournamentPrizes or {}
end

function TournamentService:SetupRemoteEvents()
    -- Request tournament data
    RemoteEvents.RequestTournamentData.OnServerEvent:Connect(function(player)
        self:SendTournamentDataToPlayer(player)
    end)
    
    -- Get player tournament prizes
    RemoteEvents.GetTournamentPrizes.OnServerEvent:Connect(function(player)
        local prizes = self:GetPlayerPrizes(player)
        RemoteEvents.TournamentPrizesUpdated:FireClient(player, prizes)
    end)
end

-- Player connection handlers
Players.PlayerAdded:Connect(function(player)
    -- Initialize weekly stats for new player
    TournamentService:InitializePlayerWeeklyStats(player)
    
    -- Send current tournament data
    wait(1) -- Wait for other services to initialize
    TournamentService:SendTournamentDataToPlayer(player)
end)

Players.PlayerRemoving:Connect(function(player)
    -- Save player weekly stats before they leave
    TournamentService:SavePlayerWeeklyStats(player)
    
    -- Clean up from leaderboards
    local userId = player.UserId
    for category, leaderboard in pairs(weeklyLeaderboards) do
        for i = #leaderboard, 1, -1 do
            if leaderboard[i].userId == userId then
                leaderboard[i].player = nil -- Keep entry but mark player as offline
            end
        end
    end
end)

-- Service setters
function TournamentService:SetPlayerService(service)
    PlayerService = service
end

function TournamentService:SetAnalyticsService(service)
    AnalyticsService = service
end

function TournamentService:SetQuestService(service)
    QuestService = service
end

return TournamentService
