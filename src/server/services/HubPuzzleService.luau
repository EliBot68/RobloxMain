-- HubPuzzleService.luau
-- Server-side service for managing the hidden orb puzzle in the hub

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local DataStoreService = game:GetService("DataStoreService")
local RunService = game:GetService("RunService")

local RemoteEvents = require(ReplicatedStorage.Shared.modules.RemoteEvents)

local HubPuzzleService = {}

-- Data store
local puzzleStore = DataStoreService:GetDataStore("HubPuzzle_v1")

-- Configuration
local PUZZLE_REWARDS = {
    {type = "trail", name = "Rainbow Trail", id = "rainbow_trail"},
    {type = "trail", name = "Lightning Trail", id = "lightning_trail"},
    {type = "trail", name = "Fire Trail", id = "fire_trail"},
    {type = "trail", name = "Ice Trail", id = "ice_trail"},
    {type = "crate_key", name = "3 Crate Keys", amount = 3}
}

-- Constants
local RESET_INTERVAL = 7 * 24 * 60 * 60 -- 7 days in seconds
local ORBS_REQUIRED = 5

-- Cache for player data
local playerPuzzleData = {}
local currentWeek = 0

function HubPuzzleService:GetCurrentWeek()
    -- Calculate week number since epoch
    local currentTime = os.time()
    local epochStart = os.time({year = 2024, month = 1, day = 1, hour = 0, min = 0, sec = 0}) -- Game launch reference
    local weeksSinceEpoch = math.floor((currentTime - epochStart) / (7 * 24 * 60 * 60))
    
    return weeksSinceEpoch
end

function HubPuzzleService:GetTimeUntilReset()
    local currentTime = os.time()
    local currentWeekStart = currentWeek * (7 * 24 * 60 * 60)
    local nextWeekStart = currentWeekStart + (7 * 24 * 60 * 60)
    
    return math.max(0, nextWeekStart - (currentTime - os.time({year = 2024, month = 1, day = 1, hour = 0, min = 0, sec = 0})))
end

function HubPuzzleService:LoadPlayerPuzzleData(player)
    local userId = player.UserId
    
    spawn(function()
        local success, data = pcall(function()
            return puzzleStore:GetAsync("puzzle_" .. userId)
        end)
        
        if success and data then
            playerPuzzleData[userId] = data
            print("🔍 Loaded puzzle data for", player.Name)
        else
            -- Initialize new player data
            playerPuzzleData[userId] = {
                completedWeeks = {},
                totalCompletions = 0,
                orbsCollectedThisWeek = {},
                lastCompletionWeek = -1
            }
            print("🔍 Initialized new puzzle data for", player.Name)
        end
        
        -- Check if player should see the puzzle
        self:CheckPuzzleAvailability(player)
    end)
end

function HubPuzzleService:SavePlayerPuzzleData(player)
    local userId = player.UserId
    local data = playerPuzzleData[userId]
    
    if not data then return end
    
    spawn(function()
        local success, err = pcall(function()
            puzzleStore:SetAsync("puzzle_" .. userId, data)
        end)
        
        if success then
            print("🔍 Saved puzzle data for", player.Name)
        else
            warn("🔍 Failed to save puzzle data for", player.Name, ":", err)
        end
    end)
end

function HubPuzzleService:GetPlayerPuzzleState(player)
    local userId = player.UserId
    local data = playerPuzzleData[userId]
    
    if not data then
        return nil
    end
    
    local currentWeekKey = "week_" .. currentWeek
    local hasCompletedThisWeek = data.completedWeeks[currentWeekKey] ~= nil
    local orbsCollected = data.orbsCollectedThisWeek[currentWeekKey] or {}
    
    return {
        hasCompleted = hasCompletedThisWeek,
        orbsCollected = orbsCollected,
        orbCount = self:CountCollectedOrbs(orbsCollected),
        canPlay = not hasCompletedThisWeek,
        timeUntilReset = self:GetTimeUntilReset(),
        currentWeek = currentWeek,
        totalCompletions = data.totalCompletions
    }
end

function HubPuzzleService:CountCollectedOrbs(orbsCollected)
    local count = 0
    for i = 1, ORBS_REQUIRED do
        if orbsCollected[i] then
            count = count + 1
        end
    end
    return count
end

function HubPuzzleService:CanPlayPuzzle(player)
    local puzzleState = self:GetPlayerPuzzleState(player)
    return puzzleState and puzzleState.canPlay
end

function HubPuzzleService:CollectOrb(player, orbId)
    local userId = player.UserId
    local data = playerPuzzleData[userId]
    
    if not data then
        return false, "Player data not found"
    end
    
    local puzzleState = self:GetPlayerPuzzleState(player)
    if not puzzleState.canPlay then
        return false, "Puzzle already completed this week"
    end
    
    local currentWeekKey = "week_" .. currentWeek
    
    -- Initialize week data if needed
    if not data.orbsCollectedThisWeek[currentWeekKey] then
        data.orbsCollectedThisWeek[currentWeekKey] = {}
    end
    
    -- Check if orb already collected
    if data.orbsCollectedThisWeek[currentWeekKey][orbId] then
        return false, "Orb already collected"
    end
    
    -- Collect the orb
    data.orbsCollectedThisWeek[currentWeekKey][orbId] = true
    
    -- Save data
    self:SavePlayerPuzzleData(player)
    
    print("✨ Player", player.Name, "collected orb", orbId)
    
    return true
end

function HubPuzzleService:CompletePuzzle(player)
    local userId = player.UserId
    local data = playerPuzzleData[userId]
    
    if not data then
        return false, "Player data not found"
    end
    
    local puzzleState = self:GetPlayerPuzzleState(player)
    if not puzzleState.canPlay then
        return false, "Puzzle already completed this week"
    end
    
    if puzzleState.orbCount < ORBS_REQUIRED then
        return false, "Not all orbs collected"
    end
    
    local currentWeekKey = "week_" .. currentWeek
    
    -- Mark puzzle as completed
    data.completedWeeks[currentWeekKey] = os.time()
    data.totalCompletions = data.totalCompletions + 1
    data.lastCompletionWeek = currentWeek
    
    -- Give reward
    local reward = self:SelectReward(player)
    local success = self:GiveReward(player, reward)
    
    if success then
        -- Save updated data
        self:SavePlayerPuzzleData(player)
        
        -- Send completion notification
        RemoteEvents.HubPuzzleReward:FireClient(player, reward.type, reward.name)
        
        -- End puzzle for this player
        RemoteEvents.EndHubPuzzle:FireClient(player)
        
        print("🏆 Player", player.Name, "completed hub puzzle and received:", reward.name)
        
        return true, reward
    else
        -- Revert completion if reward failed
        data.completedWeeks[currentWeekKey] = nil
        data.totalCompletions = data.totalCompletions - 1
        data.lastCompletionWeek = puzzleState.lastCompletionWeek
        
        return false, "Failed to give reward"
    end
end

function HubPuzzleService:SelectReward(player)
    local userId = player.UserId
    local data = playerPuzzleData[userId]
    
    -- Simple rotation based on completion count
    local rewardIndex = (data.totalCompletions % #PUZZLE_REWARDS) + 1
    return PUZZLE_REWARDS[rewardIndex]
end

function HubPuzzleService:GiveReward(player, reward)
    local success = true
    
    if reward.type == "trail" then
        -- Give trail reward
        local trailSuccess = pcall(function()
            RemoteEvents.UnlockTrail:FireClient(player, reward.id)
        end)
        if not trailSuccess then success = false end
        
    elseif reward.type == "crate_key" then
        -- Give crate keys
        local keySuccess = pcall(function()
            RemoteEvents.CrateKeyUpdate:FireClient(player, reward.amount)
        end)
        if not keySuccess then success = false end
    end
    
    return success
end

function HubPuzzleService:CheckPuzzleAvailability(player)
    if not self:CanPlayPuzzle(player) then
        return
    end
    
    -- Start puzzle for this player
    spawn(function()
        wait(2) -- Wait a bit after player joins
        RemoteEvents.StartHubPuzzle:FireClient(player, {
            week = currentWeek,
            timeUntilReset = self:GetTimeUntilReset()
        })
    end)
end

function HubPuzzleService:ResetWeeklyPuzzles()
    print("🔄 Resetting weekly hub puzzles...")
    
    -- Update current week
    currentWeek = self:GetCurrentWeek()
    
    -- Notify all online players about reset
    for _, player in pairs(Players:GetPlayers()) do
        self:CheckPuzzleAvailability(player)
    end
    
    print("✅ Weekly hub puzzles reset to week", currentWeek)
end

function HubPuzzleService:GetPlayerStats(player)
    local userId = player.UserId
    local data = playerPuzzleData[userId]
    
    if not data then
        return {
            totalCompletions = 0,
            currentStreak = 0,
            completedThisWeek = false
        }
    end
    
    local currentWeekKey = "week_" .. currentWeek
    local completedThisWeek = data.completedWeeks[currentWeekKey] ~= nil
    
    return {
        totalCompletions = data.totalCompletions,
        completedThisWeek = completedThisWeek,
        lastCompletion = data.lastCompletionWeek
    }
end

-- Remote event handlers
function HubPuzzleService:OnRequestPuzzleState(player)
    local puzzleState = self:GetPlayerPuzzleState(player)
    
    if puzzleState and puzzleState.canPlay then
        RemoteEvents.StartHubPuzzle:FireClient(player, {
            week = currentWeek,
            timeUntilReset = self:GetTimeUntilReset(),
            orbsCollected = puzzleState.orbsCollected
        })
    end
end

function HubPuzzleService:OnOrbCollected(player, orbId)
    if not orbId or orbId < 1 or orbId > ORBS_REQUIRED then
        return
    end
    
    local success, result = self:CollectOrb(player, orbId)
    
    if success then
        print("✨ Orb", orbId, "collected by", player.Name)
        
        -- Check if puzzle is now complete
        local puzzleState = self:GetPlayerPuzzleState(player)
        if puzzleState.orbCount >= ORBS_REQUIRED then
            -- Don't auto-complete here, wait for client to send completion request
            -- This allows for better client-side effects
        end
    else
        warn("⚠️ Failed to collect orb", orbId, "for", player.Name, ":", result)
    end
end

function HubPuzzleService:OnPuzzleCompleted(player)
    local success, result = self:CompletePuzzle(player)
    
    if success then
        print("🏆 Hub puzzle completed by", player.Name, "- reward:", result.name)
        
        -- Log analytics
        print("📊 Puzzle completion:", player.Name, "Week", currentWeek, 
              "Total completions:", self:GetPlayerStats(player).totalCompletions)
        
    else
        warn("⚠️ Failed to complete puzzle for", player.Name, ":", result)
    end
end

function HubPuzzleService:OnPlayerAdded(player)
    print("🔍 Setting up hub puzzle for", player.Name)
    
    -- Load player's puzzle data
    self:LoadPlayerPuzzleData(player)
end

function HubPuzzleService:OnPlayerRemoving(player)
    local userId = player.UserId
    
    -- Save player data before they leave
    self:SavePlayerPuzzleData(player)
    
    -- Clean up cache
    playerPuzzleData[userId] = nil
    
    print("🔍 Cleaned up puzzle data for", player.Name)
end

function HubPuzzleService:Initialize()
    print("🔍 HubPuzzleService initializing...")
    
    -- Initialize current week
    currentWeek = self:GetCurrentWeek()
    print("🔍 Current puzzle week:", currentWeek)
    
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
    RemoteEvents.RequestHubPuzzleState.OnServerEvent:Connect(function(player)
        self:OnRequestPuzzleState(player)
    end)
    
    RemoteEvents.HubPuzzleOrbCollected.OnServerEvent:Connect(function(player, orbId)
        self:OnOrbCollected(player, orbId)
    end)
    
    RemoteEvents.HubPuzzleCompleted.OnServerEvent:Connect(function(player)
        self:OnPuzzleCompleted(player)
    end)
    
    -- Weekly reset checker (every hour)
    spawn(function()
        while true do
            wait(3600) -- 1 hour
            local newWeek = self:GetCurrentWeek()
            if newWeek ~= currentWeek then
                self:ResetWeeklyPuzzles()
            end
        end
    end)
    
    -- Auto-save all player data every 10 minutes
    spawn(function()
        while true do
            wait(600) -- 10 minutes
            for _, player in pairs(Players:GetPlayers()) do
                self:SavePlayerPuzzleData(player)
            end
        end
    end)
    
    print("✅ HubPuzzleService initialized!")
end

return HubPuzzleService
