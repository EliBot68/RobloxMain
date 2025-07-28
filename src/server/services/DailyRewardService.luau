-- DailyRewardService.luau
-- Server-side daily reward system management

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local DataStoreService = game:GetService("DataStoreService")
local RunService = game:GetService("RunService")

local RemoteEvents = require(ReplicatedStorage.Shared.modules.RemoteEvents)

local DailyRewardService = {}

-- Data store
local dailyRewardStore = DataStoreService:GetDataStore("DailyRewards_v1")

-- Daily rewards configuration
local DAILY_REWARDS = {
    [1] = {coins = 100, xp = 50, crateKeys = 0, special = nil},
    [2] = {coins = 150, xp = 75, crateKeys = 0, special = nil},
    [3] = {coins = 200, xp = 100, crateKeys = 1, special = "Crate Key"},
    [4] = {coins = 300, xp = 150, crateKeys = 0, special = nil},
    [5] = {coins = 400, xp = 200, crateKeys = 1, special = "Crate Key"},
    [6] = {coins = 500, xp = 250, crateKeys = 0, special = nil},
    [7] = {coins = 1000, xp = 500, crateKeys = 3, special = "MEGA BONUS"}
}

-- Constants
local SECONDS_PER_DAY = 24 * 60 * 60
local RESET_HOUR = 0 -- UTC hour for daily reset (midnight)

-- Cache for player data
local playerDailyData = {}

function DailyRewardService:GetCurrentDay()
    -- Get current UTC time
    local currentTime = os.time()
    local utcDate = os.date("!*t", currentTime)
    
    -- Calculate days since epoch (January 1, 1970)
    local epochStart = os.time({year = 1970, month = 1, day = 1, hour = 0, min = 0, sec = 0})
    local daysSinceEpoch = math.floor((currentTime - epochStart) / SECONDS_PER_DAY)
    
    return daysSinceEpoch
end

function DailyRewardService:GetNextResetTime()
    local currentTime = os.time()
    local utcDate = os.date("!*t", currentTime)
    
    -- Calculate next midnight UTC
    local nextMidnight = os.time({
        year = utcDate.year,
        month = utcDate.month,
        day = utcDate.day + 1,
        hour = RESET_HOUR,
        min = 0,
        sec = 0
    })
    
    return nextMidnight
end

function DailyRewardService:GetTimeUntilNextReset()
    local currentTime = os.time()
    local nextReset = self:GetNextResetTime()
    
    return math.max(0, nextReset - currentTime)
end

function DailyRewardService:LoadPlayerDailyData(player)
    local userId = player.UserId
    
    spawn(function()
        local success, data = pcall(function()
            return dailyRewardStore:GetAsync("daily_" .. userId)
        end)
        
        if success and data then
            playerDailyData[userId] = data
            print("📅 Loaded daily reward data for", player.Name)
        else
            -- Initialize new player data
            playerDailyData[userId] = {
                lastClaimDay = 0,
                currentStreak = 0,
                totalRewardsClaimed = 0,
                lastLoginDay = self:GetCurrentDay()
            }
            print("📅 Initialized new daily reward data for", player.Name)
        end
        
        -- Check if player should see daily reward popup
        self:CheckDailyRewardAvailability(player)
    end)
end

function DailyRewardService:SavePlayerDailyData(player)
    local userId = player.UserId
    local data = playerDailyData[userId]
    
    if not data then return end
    
    spawn(function()
        local success, err = pcall(function()
            dailyRewardStore:SetAsync("daily_" .. userId, data)
        end)
        
        if success then
            print("📅 Saved daily reward data for", player.Name)
        else
            warn("📅 Failed to save daily reward data for", player.Name, ":", err)
        end
    end)
end

function DailyRewardService:GetPlayerDailyRewardData(player)
    local userId = player.UserId
    local data = playerDailyData[userId]
    
    if not data then
        return nil
    end
    
    local currentDay = self:GetCurrentDay()
    local daysSinceLastClaim = currentDay - data.lastClaimDay
    
    -- Calculate current streak day (1-7)
    local currentStreakDay = (data.currentStreak % 7) + 1
    
    -- Check if player can claim today's reward
    local canClaim = daysSinceLastClaim >= 1
    
    -- If player missed more than 1 day, reset streak
    if daysSinceLastClaim > 1 then
        data.currentStreak = 0
        currentStreakDay = 1
        canClaim = true
    end
    
    return {
        currentDay = currentStreakDay,
        canClaim = canClaim,
        timeUntilNext = self:GetTimeUntilNextReset(),
        currentStreak = data.currentStreak,
        totalRewardsClaimed = data.totalRewardsClaimed,
        lastClaimDay = data.lastClaimDay,
        daysSinceLastClaim = daysSinceLastClaim
    }
end

function DailyRewardService:CanClaimDailyReward(player)
    local rewardData = self:GetPlayerDailyRewardData(player)
    return rewardData and rewardData.canClaim
end

function DailyRewardService:ClaimDailyReward(player, requestedDay)
    local userId = player.UserId
    local data = playerDailyData[userId]
    
    if not data then
        return false, "Player data not found"
    end
    
    local rewardData = self:GetPlayerDailyRewardData(player)
    
    if not rewardData.canClaim then
        return false, "Daily reward already claimed or not available"
    end
    
    -- Validate requested day matches current available day
    if requestedDay and requestedDay ~= rewardData.currentDay then
        return false, "Invalid day requested"
    end
    
    local currentDay = self:GetCurrentDay()
    local dayToReward = rewardData.currentDay
    local reward = DAILY_REWARDS[dayToReward]
    
    if not reward then
        return false, "Invalid reward day"
    end
    
    -- Update player data
    data.lastClaimDay = currentDay
    data.currentStreak = data.currentStreak + 1
    data.totalRewardsClaimed = data.totalRewardsClaimed + 1
    
    -- Give rewards to player
    local success = self:GiveRewardsToPlayer(player, reward)
    
    if success then
        -- Save updated data
        self:SavePlayerDailyData(player)
        
        print("🎁 Player", player.Name, "claimed daily reward for day", dayToReward)
        
        return true, reward
    else
        -- Revert data changes if reward giving failed
        data.lastClaimDay = data.lastClaimDay
        data.currentStreak = data.currentStreak - 1
        data.totalRewardsClaimed = data.totalRewardsClaimed - 1
        
        return false, "Failed to give rewards"
    end
end

function DailyRewardService:GiveRewardsToPlayer(player, reward)
    local success = true
    
    -- Give coins
    if reward.coins and reward.coins > 0 then
        local coinsSuccess = pcall(function()
            RemoteEvents.CoinCollected:FireClient(player, reward.coins)
        end)
        if not coinsSuccess then success = false end
    end
    
    -- Give XP
    if reward.xp and reward.xp > 0 then
        local xpSuccess = pcall(function()
            RemoteEvents.XpGained:FireClient(player, reward.xp)
        end)
        if not xpSuccess then success = false end
    end
    
    -- Give crate keys
    if reward.crateKeys and reward.crateKeys > 0 then
        local keysSuccess = pcall(function()
            RemoteEvents.CrateKeyUpdate:FireClient(player, reward.crateKeys)
        end)
        if not keysSuccess then success = false end
    end
    
    return success
end

function DailyRewardService:CheckDailyRewardAvailability(player)
    local rewardData = self:GetPlayerDailyRewardData(player)
    
    if rewardData and rewardData.canClaim then
        -- Show daily reward popup
        spawn(function()
            wait(3) -- Wait a bit after player joins
            RemoteEvents.ShowDailyRewardPopup:FireClient(player, rewardData)
        end)
    end
end

function DailyRewardService:BroadcastDailyRewardUpdate(player)
    local rewardData = self:GetPlayerDailyRewardData(player)
    
    if rewardData then
        RemoteEvents.UpdateDailyRewardData:FireClient(player, rewardData)
    end
end

function DailyRewardService:GetPlayerStreakInfo(player)
    local userId = player.UserId
    local data = playerDailyData[userId]
    
    if not data then
        return {
            currentStreak = 0,
            longestStreak = 0,
            totalRewardsClaimed = 0
        }
    end
    
    return {
        currentStreak = data.currentStreak,
        longestStreak = data.longestStreak or 0,
        totalRewardsClaimed = data.totalRewardsClaimed
    }
end

function DailyRewardService:ResetExpiredStreaks()
    -- Check all online players for expired streaks
    for _, player in pairs(Players:GetPlayers()) do
        local userId = player.UserId
        local data = playerDailyData[userId]
        
        if data then
            local currentDay = self:GetCurrentDay()
            local daysSinceLastClaim = currentDay - data.lastClaimDay
            
            -- If player missed more than 1 day, reset their streak
            if daysSinceLastClaim > 1 and data.currentStreak > 0 then
                print("📅 Resetting expired streak for", player.Name, "- missed", daysSinceLastClaim, "days")
                data.currentStreak = 0
                self:SavePlayerDailyData(player)
            end
        end
    end
end

-- Remote event handlers
function DailyRewardService:OnRequestDailyRewardData(player)
    local rewardData = self:GetPlayerDailyRewardData(player)
    
    if rewardData then
        RemoteEvents.UpdateDailyRewardData:FireClient(player, rewardData)
        
        -- Also show popup if reward is available
        if rewardData.canClaim then
            RemoteEvents.ShowDailyRewardPopup:FireClient(player, rewardData)
        end
    end
end

function DailyRewardService:OnClaimDailyReward(player, requestedDay)
    local success, result = self:ClaimDailyReward(player, requestedDay)
    
    if success then
        -- Send success response
        RemoteEvents.DailyRewardClaimResult:FireClient(player, true, result, nil)
        
        -- Update player's reward data
        self:BroadcastDailyRewardUpdate(player)
        
        -- Log analytics
        print("📊 Daily reward claimed:", player.Name, "Day", requestedDay or "auto", 
              "Coins:", result.coins, "XP:", result.xp, "Keys:", result.crateKeys or 0)
        
    else
        -- Send error response
        RemoteEvents.DailyRewardClaimResult:FireClient(player, false, nil, result)
    end
end

function DailyRewardService:OnPlayerAdded(player)
    print("📅 Setting up daily rewards for", player.Name)
    
    -- Load player's daily reward data
    self:LoadPlayerDailyData(player)
end

function DailyRewardService:OnPlayerRemoving(player)
    local userId = player.UserId
    
    -- Save player data before they leave
    self:SavePlayerDailyData(player)
    
    -- Clean up cache
    playerDailyData[userId] = nil
    
    print("📅 Cleaned up daily reward data for", player.Name)
end

function DailyRewardService:Initialize()
    print("📅 DailyRewardService initializing...")
    
    -- Connect player events
    Players.PlayerAdded:Connect(function(player)
        self:OnPlayerAdded(player)
    end)
    
    Players.PlayerRemoving:Connect(function(player)
        self:OnPlayerRemoving(player)
    end)
    
    -- Handle existing players
    for _, player in pairs(Players:GetPlayers()) do
        self:OnPlayerAdded(player)
    end
    
    -- Connect remote events
    RemoteEvents.RequestDailyRewardData.OnServerEvent:Connect(function(player)
        self:OnRequestDailyRewardData(player)
    end)
    
    RemoteEvents.ClaimDailyReward.OnServerEvent:Connect(function(player, requestedDay)
        self:OnClaimDailyReward(player, requestedDay)
    end)
    
    -- Periodic streak reset checker (every hour)
    spawn(function()
        while true do
            wait(3600) -- 1 hour
            self:ResetExpiredStreaks()
        end
    end)
    
    -- Auto-save all player data every 10 minutes
    spawn(function()
        while true do
            wait(600) -- 10 minutes
            for _, player in pairs(Players:GetPlayers()) do
                self:SavePlayerDailyData(player)
            end
        end
    end)
    
    print("✅ DailyRewardService initialized!")
end

return DailyRewardService
