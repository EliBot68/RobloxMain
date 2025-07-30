-- WeeklyLeaderboardService.luau
-- Server-side weekly leaderboard management

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local DataStoreService = game:GetService("DataStoreService")
local RunService = game:GetService("RunService")

local RemoteEvents = require(ReplicatedStorage.Shared.modules.RemoteEvents)

local WeeklyLeaderboardService = {}

-- Data stores
local weeklyLeaderboardStore = DataStoreService:GetDataStore("WeeklyLeaderboard_v1")
local weeklyRewardsStore = DataStoreService:GetDataStore("WeeklyRewards_v1")

-- Configuration
local RESET_DAY = 1 -- Monday (1 = Monday, 7 = Sunday)
local MAX_LEADERBOARD_SIZE = 100
local REWARD_MULTIPLIERS = {
    [1] = 1000, -- 1st place: 1000 coins
    [2] = 750,  -- 2nd place: 750 coins
    [3] = 500,  -- 3rd place: 500 coins
    [4] = 300,  -- 4th place: 300 coins
    [5] = 200   -- 5th place: 200 coins
}

-- Cache
local currentWeekData = {
    weekId = "",
    startTime = 0,
    endTime = 0,
    playerData = {},
    topPlayers = {}
}

local lastUpdateTime = 0
local UPDATE_INTERVAL = 30 -- Update leaderboard every 30 seconds

function WeeklyLeaderboardService:GetCurrentWeekId()
    local currentTime = os.time()
    local weekStart = self:GetWeekStart(currentTime)
    return "week_" .. weekStart
end

function WeeklyLeaderboardService:GetWeekStart(timestamp)
    local date = os.date("*t", timestamp)
    local dayOfWeek = date.wday -- 1 = Sunday, 2 = Monday, etc.
    
    -- Calculate days to subtract to get to Monday
    local daysToSubtract = (dayOfWeek - RESET_DAY) % 7
    
    -- Get the start of the week (Monday at 00:00:00)
    local weekStart = timestamp - (daysToSubtract * 24 * 60 * 60)
    local weekStartDate = os.date("*t", weekStart)
    weekStartDate.hour = 0
    weekStartDate.min = 0
    weekStartDate.sec = 0
    
    return os.time(weekStartDate)
end

function WeeklyLeaderboardService:GetWeekEnd(weekStart)
    return weekStart + (7 * 24 * 60 * 60) - 1 -- End of Sunday
end

function WeeklyLeaderboardService:InitializeWeekData()
    local currentTime = os.time()
    local weekStart = self:GetWeekStart(currentTime)
    local weekEnd = self:GetWeekEnd(weekStart)
    local weekId = "week_" .. weekStart
    
    currentWeekData.weekId = weekId
    currentWeekData.startTime = weekStart
    currentWeekData.endTime = weekEnd
    currentWeekData.playerData = {}
    currentWeekData.topPlayers = {}
    
    print("📊 Initialized week data:", weekId, "| Start:", os.date("%c", weekStart), "| End:", os.date("%c", weekEnd))
    
    -- Load existing data for this week
    self:LoadWeekData()
end

function WeeklyLeaderboardService:LoadWeekData()
    spawn(function()
        local success, data = pcall(function()
            return weeklyLeaderboardStore:GetAsync(currentWeekData.weekId)
        end)
        
        if success and data then
            currentWeekData.playerData = data.playerData or {}
            print("📊 Loaded", table.getn(currentWeekData.playerData), "players from week data")
        else
            print("📊 No existing week data found, starting fresh")
        end
        
        self:UpdateTopPlayers()
    end)
end

function WeeklyLeaderboardService:SaveWeekData()
    spawn(function()
        local dataToSave = {
            weekId = currentWeekData.weekId,
            startTime = currentWeekData.startTime,
            endTime = currentWeekData.endTime,
            playerData = currentWeekData.playerData,
            lastUpdated = os.time()
        }
        
        local success, err = pcall(function()
            weeklyLeaderboardStore:SetAsync(currentWeekData.weekId, dataToSave)
        end)
        
        if success then
            print("📊 Weekly leaderboard data saved successfully")
        else
            warn("📊 Failed to save weekly leaderboard data:", err)
        end
    end)
end

function WeeklyLeaderboardService:AddCoinsToPlayer(player, coinsEarned)
    local userId = player.UserId
    local playerName = player.Name
    local displayName = player.DisplayName
    
    -- Initialize player data if not exists
    if not currentWeekData.playerData[userId] then
        currentWeekData.playerData[userId] = {
            userId = userId,
            username = playerName,
            displayName = displayName,
            weeklyCoins = 0,
            totalGames = 0,
            lastUpdated = os.time()
        }
    end
    
    -- Add coins
    currentWeekData.playerData[userId].weeklyCoins = currentWeekData.playerData[userId].weeklyCoins + coinsEarned
    currentWeekData.playerData[userId].totalGames = currentWeekData.playerData[userId].totalGames + 1
    currentWeekData.playerData[userId].lastUpdated = os.time()
    
    print("📊 Added", coinsEarned, "coins to", playerName, "| Total this week:", currentWeekData.playerData[userId].weeklyCoins)
    
    -- Update leaderboard if enough time has passed
    if os.time() - lastUpdateTime > UPDATE_INTERVAL then
        self:UpdateTopPlayers()
        self:BroadcastLeaderboardUpdate()
        lastUpdateTime = os.time()
    end
end

function WeeklyLeaderboardService:UpdateTopPlayers()
    local playerList = {}
    
    -- Convert player data to array
    for userId, data in pairs(currentWeekData.playerData) do
        table.insert(playerList, data)
    end
    
    -- Sort by weekly coins (descending)
    table.sort(playerList, function(a, b)
        return a.weeklyCoins > b.weeklyCoins
    end)
    
    -- Keep only top players
    local topPlayers = {}
    for i = 1, math.min(#playerList, MAX_LEADERBOARD_SIZE) do
        topPlayers[i] = playerList[i]
    end
    
    currentWeekData.topPlayers = topPlayers
    
    print("📊 Updated top players list with", #topPlayers, "players")
    
    -- Save data periodically
    if os.time() % 300 == 0 then -- Save every 5 minutes
        self:SaveWeekData()
    end
end

function WeeklyLeaderboardService:GetLeaderboardData()
    local timeUntilReset = currentWeekData.endTime - os.time()
    
    return {
        weekId = currentWeekData.weekId,
        topPlayers = currentWeekData.topPlayers,
        timeUntilReset = math.max(0, timeUntilReset),
        weekStart = currentWeekData.startTime,
        weekEnd = currentWeekData.endTime
    }
end

function WeeklyLeaderboardService:BroadcastLeaderboardUpdate()
    local leaderboardData = self:GetLeaderboardData()
    
    for _, player in pairs(Players:GetPlayers()) do
        RemoteEvents.UpdateWeeklyLeaderboard:FireClient(player, leaderboardData)
    end
end

function WeeklyLeaderboardService:GetPlayerRank(player)
    local userId = player.UserId
    
    for rank, playerData in ipairs(currentWeekData.topPlayers) do
        if playerData.userId == userId then
            return rank
        end
    end
    
    return nil -- Player not in top rankings
end

function WeeklyLeaderboardService:GetPlayerWeeklyCoins(player)
    local userId = player.UserId
    local playerData = currentWeekData.playerData[userId]
    
    return playerData and playerData.weeklyCoins or 0
end

function WeeklyLeaderboardService:CanClaimWeeklyReward(player)
    local userId = player.UserId
    local rank = self:GetPlayerRank(player)
    
    if not rank or rank > 5 then
        return false, "Not in top 5"
    end
    
    -- Check if already claimed this week
    local claimKey = currentWeekData.weekId .. "_" .. userId
    
    local success, alreadyClaimed = pcall(function()
        return weeklyRewardsStore:GetAsync(claimKey)
    end)
    
    if success and alreadyClaimed then
        return false, "Already claimed this week"
    end
    
    return true, "Can claim reward"
end

function WeeklyLeaderboardService:ClaimWeeklyReward(player)
    local canClaim, reason = self:CanClaimWeeklyReward(player)
    
    if not canClaim then
        print("📊 Player", player.Name, "cannot claim reward:", reason)
        return false, reason
    end
    
    local rank = self:GetPlayerRank(player)
    local rewardAmount = REWARD_MULTIPLIERS[rank] or 0
    
    if rewardAmount == 0 then
        return false, "No reward for this rank"
    end
    
    -- Mark as claimed
    local claimKey = currentWeekData.weekId .. "_" .. player.UserId
    
    spawn(function()
        local success, err = pcall(function()
            weeklyRewardsStore:SetAsync(claimKey, {
                claimed = true,
                claimTime = os.time(),
                rank = rank,
                rewardAmount = rewardAmount
            })
        end)
        
        if success then
            print("📊 Marked weekly reward as claimed for", player.Name)
        else
            warn("📊 Failed to mark reward as claimed:", err)
        end
    end)
    
    -- Give coins to player
    RemoteEvents.AddCoins:FireClient(player, rewardAmount)
    RemoteEvents.WeeklyRewardClaimed:FireClient(player, rewardAmount)
    
    print("🎁 Player", player.Name, "claimed weekly reward: Rank", rank, "-", rewardAmount, "coins")
    
    return true, rewardAmount
end

function WeeklyLeaderboardService:CheckForWeekReset()
    local currentTime = os.time()
    
    if currentTime > currentWeekData.endTime then
        print("📊 Week has ended! Preparing for reset...")
        
        -- Save final week data
        self:SaveWeekData()
        
        -- Archive top players for rewards
        self:ArchiveWeekResults()
        
        -- Initialize new week
        self:InitializeWeekData()
        
        -- Broadcast reset
        for _, player in pairs(Players:GetPlayers()) do
            RemoteEvents.WeeklyLeaderboardReset:FireClient(player)
        end
        
        print("📊 Weekly leaderboard reset complete!")
    end
end

function WeeklyLeaderboardService:ArchiveWeekResults()
    local archiveKey = "archive_" .. currentWeekData.weekId
    
    spawn(function()
        local archiveData = {
            weekId = currentWeekData.weekId,
            startTime = currentWeekData.startTime,
            endTime = currentWeekData.endTime,
            topPlayers = currentWeekData.topPlayers,
            totalPlayers = 0,
            archivedTime = os.time()
        }
        
        -- Count total players
        for _ in pairs(currentWeekData.playerData) do
            archiveData.totalPlayers = archiveData.totalPlayers + 1
        end
        
        local success, err = pcall(function()
            weeklyLeaderboardStore:SetAsync(archiveKey, archiveData)
        end)
        
        if success then
            print("📊 Week results archived successfully")
        else
            warn("📊 Failed to archive week results:", err)
        end
    end)
end

-- Remote event handlers
function WeeklyLeaderboardService:OnRequestLeaderboard(player)
    local leaderboardData = self:GetLeaderboardData()
    RemoteEvents.UpdateWeeklyLeaderboard:FireClient(player, leaderboardData)
end

function WeeklyLeaderboardService:OnShowLeaderboard(player)
    RemoteEvents.ShowWeeklyLeaderboard:FireClient(player)
end

function WeeklyLeaderboardService:OnClaimReward(player)
    local success, result = self:ClaimWeeklyReward(player)
    
    if not success then
        -- Show error message
        RemoteEvents.ShowNotification:FireClient(player, "Cannot claim reward: " .. result, "error")
    end
end

function WeeklyLeaderboardService:OnShowRewardChest(player)
    local rank = self:GetPlayerRank(player)
    
    if rank and rank <= 5 then
        local canClaim, reason = self:CanClaimWeeklyReward(player)
        local rewardAmount = REWARD_MULTIPLIERS[rank] or 0
        
        local rewardData = {
            rank = rank,
            rewardAmount = rewardAmount,
            canClaim = canClaim,
            reason = reason
        }
        
        RemoteEvents.ShowWeeklyRewardChest:FireClient(player, rewardData)
    else
        RemoteEvents.ShowNotification:FireClient(player, "You must be in the top 5 to access rewards!", "info")
    end
end

function WeeklyLeaderboardService:Initialize()
    print("📊 WeeklyLeaderboardService initializing...")
    
    -- Initialize week data
    self:InitializeWeekData()
    
    -- Connect remote events
    RemoteEvents.RequestWeeklyLeaderboard.OnServerEvent:Connect(function(player)
        self:OnRequestLeaderboard(player)
    end)
    
    RemoteEvents.ShowWeeklyLeaderboard.OnServerEvent:Connect(function(player)
        self:OnShowLeaderboard(player)
    end)
    
    RemoteEvents.ClaimWeeklyReward.OnServerEvent:Connect(function(player)
        self:OnClaimReward(player)
    end)
    
    RemoteEvents.ShowWeeklyRewardChest.OnServerEvent:Connect(function(player)
        self:OnShowRewardChest(player)
    end)
    
    -- Listen for coin earnings
    RemoteEvents.PlayerEarnedCoins.OnServerEvent:Connect(function(player, coinsEarned)
        self:AddCoinsToPlayer(player, coinsEarned)
    end)
    
    -- Use single heartbeat connection for all timed operations
    local RunService = game:GetService("RunService")
    local lastWeekResetCheck = 0
    local lastUpdate = 0
    local lastSave = 0
    
    self.mainConnection = RunService.Heartbeat:Connect(function()
        local currentTime = tick()
        
        -- Weekly reset checker (every minute)
        if currentTime - lastWeekResetCheck >= 60 then
            lastWeekResetCheck = currentTime
            self:CheckForWeekReset()
        end
        
        -- Periodic leaderboard updates
        if currentTime - lastUpdate >= UPDATE_INTERVAL then
            lastUpdate = currentTime
            self:UpdateTopPlayers()
            self:BroadcastLeaderboardUpdate()
        end
        
        -- Auto-save every 10 minutes
        if currentTime - lastSave >= 600 then
            lastSave = currentTime
            self:SaveWeekData()
        end
    end)
    
    print("✅ WeeklyLeaderboardService initialized!")
end

return WeeklyLeaderboardService
