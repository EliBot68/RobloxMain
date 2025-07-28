-- GoalIntegration.luau
-- Handles automatic goal progress updates when game events occur

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local GoalService = require(script.Parent.services.GoalService)
local DataService = require(script.Parent.services.DataService)
local RemoteEvents = ReplicatedStorage:WaitForChild("RemoteEvents")

local GoalIntegration = {}

function GoalIntegration:Init()
    -- Set up event listeners for automatic goal progress tracking
    self:SetupLevelingIntegration()
    self:SetupCoinIntegration()
    self:SetupPetIntegration()
    self:SetupGameplayIntegration()
    self:SetupQuestIntegration()
    self:SetupStreakIntegration()
    self:SetupScoreIntegration()
    
    print("🎯 GoalIntegration initialized - automatic goal tracking active")
end

function GoalIntegration:SetupLevelingIntegration()
    -- Track level changes for "Reach Level 10" goal
    local LevelingService = require(script.Parent.services.LevelingService)
    
    -- Hook into level up events
    if LevelingService.PlayerLeveledUp then
        LevelingService.PlayerLeveledUp:Connect(function(player, newLevel, oldLevel)
            self:TriggerGoalUpdate(player, "level_change")
        end)
    end
    
    -- Also check XP changes that might lead to level changes
    RemoteEvents.PlayerDataChanged.OnServerEvent:Connect(function(player, dataType, newValue)
        if dataType == "level" or dataType == "xp" then
            self:TriggerGoalUpdate(player, "progression_change")
        end
    end)
end

function GoalIntegration:SetupCoinIntegration()
    -- Track coin changes for "Earn 5,000 Coins" goal
    RemoteEvents.PlayerDataChanged.OnServerEvent:Connect(function(player, dataType, newValue)
        if dataType == "coins" then
            self:TriggerGoalUpdate(player, "coin_change")
        end
    end)
    
    -- Hook into coin earning events
    if RemoteEvents:FindFirstChild("CoinEarned") then
        RemoteEvents.CoinEarned.OnServerEvent:Connect(function(player, amount, source)
            self:TriggerGoalUpdate(player, "coin_earned")
        end)
    end
end

function GoalIntegration:SetupPetIntegration()
    -- Track pet collection for "Collect 5 Pets" goal
    local PetService = require(script.Parent.services.PetService)
    
    -- Hook into pet unlock events
    if PetService.PetUnlocked then
        PetService.PetUnlocked:Connect(function(player, petId)
            self:TriggerGoalUpdate(player, "pet_collected")
        end)
    end
    
    -- Also track when pets are added to player data
    RemoteEvents.PlayerDataChanged.OnServerEvent:Connect(function(player, dataType, newValue)
        if dataType == "ownedPets" then
            self:TriggerGoalUpdate(player, "pet_collection_change")
        end
    end)
end

function GoalIntegration:SetupGameplayIntegration()
    -- Track game completion for "Complete 100 Runs" goal
    local GameService = require(script.Parent.services.GameService)
    
    -- Hook into game completion events
    if GameService.GameCompleted then
        GameService.GameCompleted:Connect(function(player, score, wasWin)
            self:TriggerGoalUpdate(player, "game_completed")
        end)
    end
    
    -- Track perfect runs for "10 Perfect Runs" goal
    if GameService.PerfectRunCompleted then
        GameService.PerfectRunCompleted:Connect(function(player, streakCount)
            self:TriggerGoalUpdate(player, "perfect_run")
        end)
    end
    
    -- Track games played counter
    RemoteEvents.PlayerDataChanged.OnServerEvent:Connect(function(player, dataType, newValue)
        if dataType == "gamesPlayed" or dataType == "perfectStreaks" then
            self:TriggerGoalUpdate(player, "gameplay_stats_change")
        end
    end)
end

function GoalIntegration:SetupQuestIntegration()
    -- Track quest completion for "Complete First Quest" goal
    local QuestService = require(script.Parent.services.QuestService)
    
    -- Hook into quest completion events
    if QuestService.QuestCompleted then
        QuestService.QuestCompleted:Connect(function(player, questId, reward)
            self:TriggerGoalUpdate(player, "quest_completed")
        end)
    end
    
    -- Track completed quests array changes
    RemoteEvents.PlayerDataChanged.OnServerEvent:Connect(function(player, dataType, newValue)
        if dataType == "completedQuests" then
            self:TriggerGoalUpdate(player, "quest_progress_change")
        end
    end)
end

function GoalIntegration:SetupStreakIntegration()
    -- Track daily login streaks for "Login 7 Days" goal
    local DailyStreakService = require(script.Parent.services.DailyStreakService)
    
    -- Hook into streak events
    if DailyStreakService.StreakUpdated then
        DailyStreakService.StreakUpdated:Connect(function(player, newStreak, oldStreak)
            self:TriggerGoalUpdate(player, "streak_updated")
        end)
    end
    
    -- Track daily streak changes
    RemoteEvents.PlayerDataChanged.OnServerEvent:Connect(function(player, dataType, newValue)
        if dataType == "dailyStreak" then
            self:TriggerGoalUpdate(player, "daily_streak_change")
        end
    end)
end

function GoalIntegration:SetupScoreIntegration()
    -- Track high score achievements for "Reach Score 1,000" goal
    RemoteEvents.PlayerDataChanged.OnServerEvent:Connect(function(player, dataType, newValue)
        if dataType == "highScore" then
            self:TriggerGoalUpdate(player, "high_score_change")
        end
    end)
    
    -- Hook into score submission events
    if RemoteEvents:FindFirstChild("ScoreSubmitted") then
        RemoteEvents.ScoreSubmitted.OnServerEvent:Connect(function(player, score, isNewRecord)
            if isNewRecord then
                self:TriggerGoalUpdate(player, "new_high_score")
            end
        end)
    end
end

function GoalIntegration:TriggerGoalUpdate(player, eventType)
    -- Trigger goal update for specific player and event
    if not player or not player.Parent then return end
    
    -- Use spawn to prevent blocking the original event
    spawn(function()
        -- Small delay to ensure data is saved
        wait(0.1)
        
        -- Force goal update
        GoalService:ForceUpdatePlayerGoals(player)
        
        -- Debug logging
        print("🎯 Goal update triggered for " .. player.Name .. " (Event: " .. eventType .. ")")
    end)
end

function GoalIntegration:ManualTriggerUpdate(player)
    -- Allow manual triggering of goal updates
    self:TriggerGoalUpdate(player, "manual_trigger")
end

function GoalIntegration:TriggerAllPlayersUpdate()
    -- Update goals for all active players
    for _, player in pairs(Players:GetPlayers()) do
        self:TriggerGoalUpdate(player, "mass_update")
    end
end

-- Event integration functions for specific game systems

function GoalIntegration:OnPlayerLevelUp(player, newLevel)
    -- Called when player levels up
    self:TriggerGoalUpdate(player, "level_up")
end

function GoalIntegration:OnCoinsEarned(player, amount)
    -- Called when player earns coins
    self:TriggerGoalUpdate(player, "coins_earned")
end

function GoalIntegration:OnPetUnlocked(player, petId)
    -- Called when player unlocks a new pet
    self:TriggerGoalUpdate(player, "pet_unlocked")
end

function GoalIntegration:OnGameCompleted(player, score)
    -- Called when player completes a game
    self:TriggerGoalUpdate(player, "game_complete")
end

function GoalIntegration:OnQuestCompleted(player, questId)
    -- Called when player completes a quest
    self:TriggerGoalUpdate(player, "quest_complete")
end

function GoalIntegration:OnPerfectRun(player, streakCount)
    -- Called when player achieves a perfect run
    self:TriggerGoalUpdate(player, "perfect_achievement")
end

function GoalIntegration:OnDailyLogin(player, streakDays)
    -- Called when player logs in (daily streak)
    self:TriggerGoalUpdate(player, "daily_login")
end

function GoalIntegration:OnHighScore(player, newScore)
    -- Called when player achieves a new high score
    self:TriggerGoalUpdate(player, "high_score_achievement")
end

return GoalIntegration
