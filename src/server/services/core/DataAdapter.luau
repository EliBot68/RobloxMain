-- DataAdapter.luau
-- Adapter service to help existing services transition to the unified data system

local Players = game:GetService("Players")

local DataAdapter = {}

-- Reference to the unified data service
local UnifiedDataService = nil

function DataAdapter:SetUnifiedDataService(service)
    UnifiedDataService = service
end

-- Legacy compatibility functions for existing services

-- Upgrade Service compatibility
function DataAdapter:GetPlayerUpgrades(player)
    local data = UnifiedDataService:GetPlayerData(player)
    return data and data.upgrades or {}
end

function DataAdapter:SavePlayerUpgrades(player, upgrades)
    return UnifiedDataService:UpdatePlayerData(player, {upgrades = upgrades})
end

function DataAdapter:GetEnhancedUpgrades(player)
    local data = UnifiedDataService:GetPlayerData(player)
    return data and data.enhancedUpgrades or {}
end

function DataAdapter:SaveEnhancedUpgrades(player, enhancedUpgrades)
    return UnifiedDataService:UpdatePlayerData(player, {enhancedUpgrades = enhancedUpgrades})
end

-- Quest Service compatibility
function DataAdapter:GetQuestProgress(player)
    local data = UnifiedDataService:GetPlayerData(player)
    return data and {
        questProgress = data.questProgress or {},
        dailyQuests = data.dailyQuests or {},
        lastQuestReset = data.lastQuestReset or 0
    } or {}
end

function DataAdapter:SaveQuestProgress(player, questData)
    return UnifiedDataService:UpdatePlayerData(player, {
        questProgress = questData.questProgress,
        dailyQuests = questData.dailyQuests,
        lastQuestReset = questData.lastQuestReset
    })
end

-- Puzzle Service compatibility
function DataAdapter:GetPuzzleProgress(player)
    local data = UnifiedDataService:GetPlayerData(player)
    return data and data.weeklyPuzzleData or {}
end

function DataAdapter:SavePuzzleProgress(player, puzzleData)
    return UnifiedDataService:UpdatePlayerData(player, {
        weeklyPuzzleData = puzzleData,
        puzzlesCompleted = (puzzleData.completed or 0)
    })
end

-- Tournament Service compatibility
function DataAdapter:GetTournamentData(player)
    local data = UnifiedDataService:GetPlayerData(player)
    return data and data.weeklyTournamentData or {}
end

function DataAdapter:SaveTournamentData(player, tournamentData)
    return UnifiedDataService:UpdatePlayerData(player, {
        weeklyTournamentData = tournamentData
    })
end

-- Weekly Leaderboard Service compatibility
function DataAdapter:GetWeeklyStats(player)
    local data = UnifiedDataService:GetPlayerData(player)
    return data and data.weeklyStats or {}
end

function DataAdapter:SaveWeeklyStats(player, weeklyStats)
    return UnifiedDataService:UpdatePlayerData(player, {
        weeklyStats = weeklyStats
    })
end

function DataAdapter:GetWeeklyRewards(player)
    local data = UnifiedDataService:GetPlayerData(player)
    return data and data.weeklyRewards or {}
end

function DataAdapter:SaveWeeklyRewards(player, weeklyRewards)
    return UnifiedDataService:UpdatePlayerData(player, {
        weeklyRewards = weeklyRewards
    })
end

-- Exclusive Service compatibility
function DataAdapter:GetExclusiveCosmetics(player)
    local data = UnifiedDataService:GetPlayerData(player)
    return data and data.exclusiveCosmetics or {}
end

function DataAdapter:SaveExclusiveCosmetics(player, exclusiveData)
    return UnifiedDataService:UpdatePlayerData(player, {
        exclusiveCosmetics = exclusiveData
    })
end

function DataAdapter:GetExclusiveSchedule()
    -- For schedule data, we can use a special system-wide key
    local scheduleData = UnifiedDataService:GetSystemData("exclusiveSchedule")
    return scheduleData or {}
end

function DataAdapter:SaveExclusiveSchedule(scheduleData)
    return UnifiedDataService:SaveSystemData("exclusiveSchedule", scheduleData)
end

-- Pet Service compatibility
function DataAdapter:GetPetData(player)
    local data = UnifiedDataService:GetPlayerData(player)
    return data and {
        ownedPets = data.ownedPets or {},
        activePet = data.activePet,
        petStats = data.petStats or {}
    } or {}
end

function DataAdapter:SavePetData(player, petData)
    return UnifiedDataService:UpdatePlayerData(player, {
        ownedPets = petData.ownedPets,
        activePet = petData.activePet,
        petStats = petData.petStats
    })
end

-- Buff Service compatibility
function DataAdapter:GetBuffData(player)
    local data = UnifiedDataService:GetPlayerData(player)
    return data and {
        buffInventory = data.buffInventory or {},
        totalBuffsUsed = data.totalBuffsUsed or 0,
        buffUsageStats = data.buffUsageStats or {}
    } or {}
end

function DataAdapter:SaveBuffData(player, buffData)
    return UnifiedDataService:UpdatePlayerData(player, {
        buffInventory = buffData.buffInventory,
        totalBuffsUsed = buffData.totalBuffsUsed,
        buffUsageStats = buffData.buffUsageStats
    })
end

-- General data access methods
function DataAdapter:GetPlayerField(player, fieldName)
    local data = UnifiedDataService:GetPlayerData(player)
    return data and data[fieldName]
end

function DataAdapter:SetPlayerField(player, fieldName, value)
    return UnifiedDataService:UpdatePlayerData(player, {[fieldName] = value})
end

function DataAdapter:IncrementPlayerField(player, fieldName, amount)
    local data = UnifiedDataService:GetPlayerData(player)
    if data and data[fieldName] then
        local newValue = (tonumber(data[fieldName]) or 0) + (amount or 1)
        return UnifiedDataService:UpdatePlayerData(player, {[fieldName] = newValue})
    end
    return false
end

-- Batch update method for efficiency
function DataAdapter:UpdateMultipleFields(player, updates)
    return UnifiedDataService:UpdatePlayerData(player, updates)
end

-- Queue a save for the player
function DataAdapter:QueueSave(player)
    UnifiedDataService:QueueSave(player)
end

-- Force immediate save
function DataAdapter:ForceSave(player)
    return UnifiedDataService:SavePlayerData(player)
end

function DataAdapter:Init()
    print("🔌 Data Adapter initialized")
end

return DataAdapter
