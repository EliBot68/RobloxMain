-- GoalService.luau
-- Manages obvious player goals with cosmetic rewards

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local DataService = require(script.Parent.DataService)
local RemoteEvents = ReplicatedStorage:WaitForChild("RemoteEvents")

local GoalService = {}

-- Goal definitions with obvious, achievable targets
local PLAYER_GOALS = {
    {
        id = "reach_level_10",
        title = "Rising Star",
        description = "Reach Level 10",
        icon = "🌟",
        category = "progression",
        targetValue = 10,
        currentValueKey = "level",
        reward = {
            type = "cosmetic",
            item = "star_trail",
            name = "Golden Star Trail",
            description = "A shimmering trail of golden stars"
        },
        priority = 1
    },
    {
        id = "earn_5000_coins",
        title = "Coin Collector",
        description = "Earn 5,000 Coins",
        icon = "💰",
        category = "economy",
        targetValue = 5000,
        currentValueKey = "coins",
        reward = {
            type = "cosmetic",
            item = "coin_hat",
            name = "Golden Coin Crown",
            description = "A crown made of shimmering gold coins"
        },
        priority = 2
    },
    {
        id = "collect_5_pets",
        title = "Pet Master",
        description = "Collect 5 Different Pets",
        icon = "🐾",
        category = "collection",
        targetValue = 5,
        currentValueKey = "ownedPets",
        isArray = true, -- Count array length
        reward = {
            type = "cosmetic",
            item = "pet_badge",
            name = "Pet Master Badge",
            description = "Shows your mastery over pet companions"
        },
        priority = 3
    },
    {
        id = "play_100_games",
        title = "Dedicated Player",
        description = "Complete 100 Runs",
        icon = "🎮",
        category = "engagement",
        targetValue = 100,
        currentValueKey = "gamesPlayed",
        reward = {
            type = "cosmetic",
            item = "dedication_emote",
            name = "Victory Dance Emote",
            description = "An exclusive celebration emote"
        },
        priority = 4
    },
    {
        id = "perfect_streak_10",
        title = "Perfectionist",
        description = "Achieve 10 Perfect Runs in a Row",
        icon = "✨",
        category = "skill",
        targetValue = 10,
        currentValueKey = "perfectStreaks",
        reward = {
            type = "cosmetic",
            item = "perfect_aura",
            name = "Perfectionist Aura",
            description = "A glowing aura that shows your precision"
        },
        priority = 5
    },
    {
        id = "daily_streak_7",
        title = "Loyal Player",
        description = "Login 7 Days in a Row",
        icon = "📅",
        category = "loyalty",
        targetValue = 7,
        currentValueKey = "dailyStreak",
        reward = {
            type = "cosmetic",
            item = "loyalty_wings",
            name = "Angel Wings",
            description = "Beautiful wings for dedicated players"
        },
        priority = 6
    },
    {
        id = "high_score_1000",
        title = "Score Champion",
        description = "Reach a High Score of 1,000",
        icon = "🏆",
        category = "achievement",
        targetValue = 1000,
        currentValueKey = "highScore",
        reward = {
            type = "cosmetic",
            item = "champion_cape",
            name = "Champion's Cape",
            description = "A majestic cape for high achievers"
        },
        priority = 7
    },
    {
        id = "complete_first_quest",
        title = "Quest Beginner",
        description = "Complete Your First Quest",
        icon = "📜",
        category = "tutorial",
        targetValue = 1,
        currentValueKey = "completedQuests",
        isArray = true,
        reward = {
            type = "cosmetic",
            item = "quest_compass",
            name = "Adventure Compass",
            description = "A compass to guide your quests"
        },
        priority = 8
    },
    {
        id = "first_rebirth",
        title = "Ascension",
        description = "Complete Your First Rebirth",
        icon = "⚡",
        category = "progression",
        targetValue = 1,
        currentValueKey = "rebirths",
        reward = {
            type = "cosmetic",
            item = "rebirth_halo",
            name = "Rebirth Halo",
            description = "A divine halo for those who have transcended"
        },
        priority = 9
    }
}

-- Track player goal progress
local playerGoalProgress = {}

function GoalService:Init()
    -- Ensure RemoteEvents folder exists
    if not ReplicatedStorage:FindFirstChild("RemoteEvents") then
        local remoteEventsFolder = Instance.new("Folder")
        remoteEventsFolder.Name = "RemoteEvents"
        remoteEventsFolder.Parent = ReplicatedStorage
    end
    
    -- Set up remote events for goal UI communication
    if not RemoteEvents:FindFirstChild("UpdateGoalProgress") then
        local updateEvent = Instance.new("RemoteEvent")
        updateEvent.Name = "UpdateGoalProgress"
        updateEvent.Parent = RemoteEvents
    end
    
    if not RemoteEvents:FindFirstChild("ClaimGoalReward") then
        local claimEvent = Instance.new("RemoteEvent")
        claimEvent.Name = "ClaimGoalReward"
        claimEvent.Parent = RemoteEvents
    end
    
    if not RemoteEvents:FindFirstChild("GetPlayerGoals") then
        local getGoalsEvent = Instance.new("RemoteFunction")
        getGoalsEvent.Name = "GetPlayerGoals"
        getGoalsEvent.Parent = RemoteEvents
    end
    
    if not RemoteEvents:FindFirstChild("PlayerDataChanged") then
        local dataChangedEvent = Instance.new("RemoteEvent")
        dataChangedEvent.Name = "PlayerDataChanged"
        dataChangedEvent.Parent = RemoteEvents
    end
    
    -- Handle goal reward claims
    RemoteEvents.ClaimGoalReward.OnServerEvent:Connect(function(player, goalId)
        self:ClaimGoalReward(player, goalId)
    end)
    
    -- Handle goal data requests
    RemoteEvents.GetPlayerGoals.OnServerInvoke = function(player)
        return self:GetPlayerGoalData(player)
    end
    
    -- Set up player connections
    Players.PlayerAdded:Connect(function(player)
        self:InitializePlayerGoals(player)
    end)
    
    Players.PlayerRemoving:Connect(function(player)
        if playerGoalProgress[player.UserId] then
            playerGoalProgress[player.UserId] = nil
        end
    end)
    
    -- Monitor goal progress every 5 seconds
    spawn(function()
        while true do
            wait(5)
            self:UpdateAllPlayerGoals()
        end
    end)
    
    print("🎯 GoalService initialized with " .. #PLAYER_GOALS .. " player goals")
end

function GoalService:InitializePlayerGoals(player)
    local playerData = DataService:GetPlayerData(player)
    
    -- Initialize goal tracking for player
    playerGoalProgress[player.UserId] = {
        goals = {},
        lastUpdate = os.time()
    }
    
    -- Set up goal progress from player data
    for _, goal in pairs(PLAYER_GOALS) do
        local isCompleted = playerData.completedGoals and playerData.completedGoals[goal.id] or false
        local isClaimedReward = playerData.claimedGoalRewards and playerData.claimedGoalRewards[goal.id] or false
        
        playerGoalProgress[player.UserId].goals[goal.id] = {
            completed = isCompleted,
            claimed = isClaimedReward,
            progress = self:GetCurrentProgress(playerData, goal),
            target = goal.targetValue,
            lastNotified = 0
        }
    end
    
    -- Send initial goal data to client
    wait(1) -- Wait for client to load
    self:SendGoalDataToPlayer(player)
end

function GoalService:GetCurrentProgress(playerData, goal)
    local value = playerData[goal.currentValueKey]
    
    if goal.isArray and type(value) == "table" then
        -- Count array elements (like pets, completed quests)
        local count = 0
        for _ in pairs(value) do
            count = count + 1
        end
        return count
    else
        return value or 0
    end
end

function GoalService:UpdateAllPlayerGoals()
    for _, player in pairs(Players:GetPlayers()) do
        if playerGoalProgress[player.UserId] then
            self:UpdatePlayerGoals(player)
        end
    end
end

function GoalService:UpdatePlayerGoals(player)
    local playerData = DataService:GetPlayerData(player)
    local goalData = playerGoalProgress[player.UserId]
    
    if not goalData then return end
    
    local hasUpdates = false
    local newCompletions = {}
    
    for _, goal in pairs(PLAYER_GOALS) do
        local goalProgress = goalData.goals[goal.id]
        
        if goalProgress and not goalProgress.completed then
            local currentProgress = self:GetCurrentProgress(playerData, goal)
            local oldProgress = goalProgress.progress
            
            -- Update progress
            goalProgress.progress = currentProgress
            
            -- Check if goal was just completed
            if currentProgress >= goal.targetValue and oldProgress < goal.targetValue then
                goalProgress.completed = true
                hasUpdates = true
                
                -- Save completion to player data
                if not playerData.completedGoals then
                    playerData.completedGoals = {}
                end
                playerData.completedGoals[goal.id] = true
                DataService:SavePlayerData(player)
                
                table.insert(newCompletions, goal)
                print("🎯 Player " .. player.Name .. " completed goal: " .. goal.title)
            elseif currentProgress ~= oldProgress then
                hasUpdates = true
            end
        end
    end
    
    -- Send updates to client if needed
    if hasUpdates then
        self:SendGoalDataToPlayer(player)
        
        -- Notify about new completions
        for _, goal in pairs(newCompletions) do
            self:NotifyGoalCompletion(player, goal)
        end
    end
end

function GoalService:SendGoalDataToPlayer(player)
    local goalData = self:GetPlayerGoalData(player)
    RemoteEvents.UpdateGoalProgress:FireClient(player, goalData)
end

function GoalService:GetPlayerGoalData(player)
    local playerProgress = playerGoalProgress[player.UserId]
    if not playerProgress then return {} end
    
    local goalData = {}
    
    for _, goal in pairs(PLAYER_GOALS) do
        local progress = playerProgress.goals[goal.id]
        
        if progress then
            table.insert(goalData, {
                id = goal.id,
                title = goal.title,
                description = goal.description,
                icon = goal.icon,
                category = goal.category,
                progress = progress.progress,
                target = goal.targetValue,
                completed = progress.completed,
                claimed = progress.claimed,
                reward = goal.reward,
                priority = goal.priority,
                progressPercent = math.min(100, (progress.progress / goal.targetValue) * 100)
            })
        end
    end
    
    -- Sort by priority (lower numbers first)
    table.sort(goalData, function(a, b) return a.priority < b.priority end)
    
    return goalData
end

function GoalService:NotifyGoalCompletion(player, goal)
    -- Send completion notification to client
    local notificationData = {
        type = "goal_completed",
        title = "Goal Completed! 🎉",
        message = goal.title .. " - " .. goal.description,
        icon = goal.icon,
        reward = goal.reward,
        duration = 5
    }
    
    RemoteEvents.UpdateGoalProgress:FireClient(player, "notification", notificationData)
end

function GoalService:ClaimGoalReward(player, goalId)
    local playerData = DataService:GetPlayerData(player)
    local goalProgress = playerGoalProgress[player.UserId]
    
    if not goalProgress or not goalProgress.goals[goalId] then
        return false
    end
    
    local progress = goalProgress.goals[goalId]
    
    -- Check if goal is completed and reward not already claimed
    if not progress.completed or progress.claimed then
        return false
    end
    
    -- Find the goal definition
    local goal = nil
    for _, g in pairs(PLAYER_GOALS) do
        if g.id == goalId then
            goal = g
            break
        end
    end
    
    if not goal then return false end
    
    -- Award the cosmetic reward
    local success = self:AwardCosmeticReward(player, goal.reward)
    
    if success then
        -- Mark reward as claimed
        progress.claimed = true
        
        -- Save to player data
        if not playerData.claimedGoalRewards then
            playerData.claimedGoalRewards = {}
        end
        playerData.claimedGoalRewards[goalId] = true
        
        DataService:SavePlayerData(player)
        
        -- Update client
        self:SendGoalDataToPlayer(player)
        
        -- Send reward notification
        local rewardNotification = {
            type = "reward_claimed",
            title = "Reward Claimed! ✨",
            message = "You received: " .. goal.reward.name,
            icon = "🎁",
            duration = 4
        }
        
        RemoteEvents.UpdateGoalProgress:FireClient(player, "notification", rewardNotification)
        
        print("🎁 Player " .. player.Name .. " claimed reward: " .. goal.reward.name)
        return true
    end
    
    return false
end

function GoalService:AwardCosmeticReward(player, reward)
    local playerData = DataService:GetPlayerData(player)
    
    -- Initialize cosmetics if not present
    if not playerData.ownedCosmetics then
        playerData.ownedCosmetics = {}
    end
    
    -- Add the cosmetic item
    if not playerData.ownedCosmetics[reward.item] then
        playerData.ownedCosmetics[reward.item] = {
            name = reward.name,
            description = reward.description,
            source = "goal_reward",
            dateEarned = os.time()
        }
        
        return true
    end
    
    return false -- Already owned
end

function GoalService:ForceUpdatePlayerGoals(player)
    -- Manual trigger for immediate goal checking
    self:UpdatePlayerGoals(player)
end

function GoalService:AddCustomGoal(goalData)
    -- Allow adding custom goals dynamically
    table.insert(PLAYER_GOALS, goalData)
    
    -- Update all active players
    for _, player in pairs(Players:GetPlayers()) do
        if playerGoalProgress[player.UserId] then
            -- Initialize new goal for existing players
            local playerData = DataService:GetPlayerData(player)
            local isCompleted = playerData.completedGoals and playerData.completedGoals[goalData.id] or false
            local isClaimedReward = playerData.claimedGoalRewards and playerData.claimedGoalRewards[goalData.id] or false
            
            playerGoalProgress[player.UserId].goals[goalData.id] = {
                completed = isCompleted,
                claimed = isClaimedReward,
                progress = self:GetCurrentProgress(playerData, goalData),
                target = goalData.targetValue,
                lastNotified = 0
            }
            
            self:SendGoalDataToPlayer(player)
        end
    end
end

function GoalService:GetGoalStatistics()
    -- Get statistics about goal completion rates
    local stats = {
        totalGoals = #PLAYER_GOALS,
        playerStats = {},
        goalCompletionRates = {}
    }
    
    for _, goal in pairs(PLAYER_GOALS) do
        stats.goalCompletionRates[goal.id] = {
            totalPlayers = 0,
            completedCount = 0,
            claimedCount = 0,
            completionRate = 0,
            claimRate = 0
        }
    end
    
    for playerId, progress in pairs(playerGoalProgress) do
        local completedGoals = 0
        local claimedRewards = 0
        
        for goalId, goalProgress in pairs(progress.goals) do
            if goalProgress.completed then
                completedGoals = completedGoals + 1
                stats.goalCompletionRates[goalId].completedCount = stats.goalCompletionRates[goalId].completedCount + 1
            end
            
            if goalProgress.claimed then
                claimedRewards = claimedRewards + 1
                stats.goalCompletionRates[goalId].claimedCount = stats.goalCompletionRates[goalId].claimedCount + 1
            end
            
            stats.goalCompletionRates[goalId].totalPlayers = stats.goalCompletionRates[goalId].totalPlayers + 1
        end
        
        stats.playerStats[playerId] = {
            completedGoals = completedGoals,
            claimedRewards = claimedRewards,
            completionPercentage = (completedGoals / #PLAYER_GOALS) * 100
        }
    end
    
    -- Calculate completion rates
    for goalId, data in pairs(stats.goalCompletionRates) do
        if data.totalPlayers > 0 then
            data.completionRate = (data.completedCount / data.totalPlayers) * 100
            data.claimRate = (data.claimedCount / data.totalPlayers) * 100
        end
    end
    
    return stats
end

return GoalService
