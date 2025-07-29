-- PetRepository.luau
-- Data layer for pet ownership and persistence
-- Handles all pet data storage, retrieval, and persistence operations

local DataStoreService = game:GetService("DataStoreService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local ServiceArchitecture = require(ReplicatedStorage.Shared.core.ServiceArchitecture)
local PetRepository = {}
PetRepository.__index = PetRepository

-- Extend the repository interface
setmetatable(PetRepository, {__index = ServiceArchitecture.IRepository})

function PetRepository.new()
    local self = setmetatable({}, PetRepository)
    
    -- DataStore setup
    self.petDataStore = DataStoreService:GetDataStore("PlayerPets")
    self.cacheTimeout = 300 -- 5 minutes
    self.dataCache = {}
    self.cacheTimestamps = {}
    
    return self
end

-- ========================================
-- REPOSITORY INTERFACE IMPLEMENTATION
-- ========================================

function PetRepository:Create(playerId, petData)
    local success, error = pcall(function()
        local existingData = self:GetById(playerId) or {}
        table.insert(existingData, petData)
        
        self.petDataStore:SetAsync(tostring(playerId), existingData)
        
        -- Update cache
        self.dataCache[playerId] = existingData
        self.cacheTimestamps[playerId] = tick()
    end)
    
    if success then
        print("📝 Created pet data for player " .. playerId)
        return true
    else
        warn("❌ Failed to create pet data: " .. tostring(error))
        return false
    end
end

function PetRepository:GetById(playerId)
    -- Check cache first
    if self.dataCache[playerId] and 
       self.cacheTimestamps[playerId] and 
       (tick() - self.cacheTimestamps[playerId]) < self.cacheTimeout then
        return self.dataCache[playerId]
    end
    
    -- Load from DataStore
    local success, data = pcall(function()
        return self.petDataStore:GetAsync(tostring(playerId))
    end)
    
    if success then
        data = data or {}
        -- Update cache
        self.dataCache[playerId] = data
        self.cacheTimestamps[playerId] = tick()
        return data
    else
        warn("❌ Failed to load pet data for player " .. playerId .. ": " .. tostring(data))
        return {}
    end
end

function PetRepository:Update(playerId, petData)
    local success, error = pcall(function()
        self.petDataStore:SetAsync(tostring(playerId), petData)
        
        -- Update cache
        self.dataCache[playerId] = petData
        self.cacheTimestamps[playerId] = tick()
    end)
    
    if success then
        print("📝 Updated pet data for player " .. playerId)
        return true
    else
        warn("❌ Failed to update pet data: " .. tostring(error))
        return false
    end
end

function PetRepository:Delete(playerId)
    local success, error = pcall(function()
        self.petDataStore:RemoveAsync(tostring(playerId))
        
        -- Clear cache
        self.dataCache[playerId] = nil
        self.cacheTimestamps[playerId] = nil
    end)
    
    if success then
        print("🗑️ Deleted pet data for player " .. playerId)
        return true
    else
        warn("❌ Failed to delete pet data: " .. tostring(error))
        return false
    end
end

function PetRepository:GetAll(filters)
    -- This would typically require a different DataStore approach for querying
    -- For now, return empty as this is not commonly used for player-specific data
    warn("⚠️ GetAll not implemented for pet repository - use GetById instead")
    return {}
end

function PetRepository:Count(filters)
    -- Not applicable for player-specific pet data
    return 0
end

-- ========================================
-- PET-SPECIFIC REPOSITORY METHODS
-- ========================================

function PetRepository:AddPetToPlayer(playerId, petId)
    local playerPets = self:GetById(playerId)
    
    -- Check if pet already owned
    for _, ownedPetId in ipairs(playerPets) do
        if ownedPetId == petId then
            return false, "Pet already owned"
        end
    end
    
    -- Add pet
    table.insert(playerPets, petId)
    local success = self:Update(playerId, playerPets)
    
    return success, success and "Pet added successfully" or "Failed to add pet"
end

function PetRepository:RemovePetFromPlayer(playerId, petId)
    local playerPets = self:GetById(playerId)
    
    -- Find and remove pet
    for i, ownedPetId in ipairs(playerPets) do
        if ownedPetId == petId then
            table.remove(playerPets, i)
            local success = self:Update(playerId, playerPets)
            return success, success and "Pet removed successfully" or "Failed to remove pet"
        end
    end
    
    return false, "Pet not found"
end

function PetRepository:GetPlayerPetCount(playerId)
    local playerPets = self:GetById(playerId)
    return #playerPets
end

function PetRepository:HasPet(playerId, petId)
    local playerPets = self:GetById(playerId)
    
    for _, ownedPetId in ipairs(playerPets) do
        if ownedPetId == petId then
            return true
        end
    end
    
    return false
end

function PetRepository:GetOwnedPetsByRarity(playerId, rarity)
    local playerPets = self:GetById(playerId)
    local PetDatabase = require(ReplicatedStorage.Shared.data.PetDatabase)
    
    local ownedByRarity = {}
    for _, petId in ipairs(playerPets) do
        local petData = PetDatabase:GetPetById(petId)
        if petData and petData.rarity == rarity then
            table.insert(ownedByRarity, petId)
        end
    end
    
    return ownedByRarity
end

-- ========================================
-- CACHE MANAGEMENT
-- ========================================

function PetRepository:ClearCache(playerId)
    if playerId then
        self.dataCache[playerId] = nil
        self.cacheTimestamps[playerId] = nil
    else
        self.dataCache = {}
        self.cacheTimestamps = {}
    end
end

function PetRepository:GetCacheStats()
    local stats = {
        cacheSize = 0,
        oldestEntry = math.huge,
        newestEntry = 0
    }
    
    for playerId, timestamp in pairs(self.cacheTimestamps) do
        stats.cacheSize = stats.cacheSize + 1
        if timestamp < stats.oldestEntry then
            stats.oldestEntry = timestamp
        end
        if timestamp > stats.newestEntry then
            stats.newestEntry = timestamp
        end
    end
    
    if stats.cacheSize == 0 then
        stats.oldestEntry = 0
    end
    
    return stats
end

function PetRepository:CleanExpiredCache()
    local now = tick()
    local cleaned = 0
    
    for playerId, timestamp in pairs(self.cacheTimestamps) do
        if (now - timestamp) > self.cacheTimeout then
            self.dataCache[playerId] = nil
            self.cacheTimestamps[playerId] = nil
            cleaned = cleaned + 1
        end
    end
    
    if cleaned > 0 then
        print("🧹 Cleaned " .. cleaned .. " expired cache entries")
    end
    
    return cleaned
end

return PetRepository
