-- PetServiceOrchestrator.luau
-- Clean orchestrator service that coordinates pet components
-- Implements clean architecture with proper separation of concerns

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local ServiceArchitecture = require(ReplicatedStorage.Shared.core.ServiceArchitecture)
local ServiceRegistry = require(ReplicatedStorage.Shared.core.ServiceRegistry)

-- Component imports
local PetRepository = require(ReplicatedStorage.Shared.data.PetRepository)
local PetDatabase = require(ReplicatedStorage.Shared.data.PetDatabase)
local PetBehaviorService = require(ReplicatedStorage.Shared.services.PetBehaviorService)
local PetModelService = require(ReplicatedStorage.Shared.services.PetModelService)

local PetServiceOrchestrator = {}
PetServiceOrchestrator.__index = PetServiceOrchestrator

-- Extend the base service
setmetatable(PetServiceOrchestrator, {__index = ServiceArchitecture.BaseService})

function PetServiceOrchestrator.new()
    local self = ServiceArchitecture.BaseService.new("PetService", "2.0.0")
    setmetatable(self, PetServiceOrchestrator)
    
    -- Component instances
    self.repository = nil
    self.behaviorService = nil
    self.modelService = nil
    
    -- Dependencies
    self:SetDependencies({"PlayerService", "CurrencyService"})
    
    return self
end

-- ========================================
-- SERVICE LIFECYCLE
-- ========================================

function PetServiceOrchestrator:_initialize()
    print("🔧 Initializing Pet Service components...")
    
    -- Initialize components
    self.repository = PetRepository.new()
    self.behaviorService = PetBehaviorService.new()
    self.modelService = PetModelService.new()
    
    -- Validate pet database
    local issues = PetDatabase:ValidatePetData()
    if #issues > 0 then
        warn("⚠️ Pet database validation issues found:")
        for _, issue in ipairs(issues) do
            warn("  - " .. issue)
        end
    else
        print("✅ Pet database validation passed")
    end
    
    -- Setup event handlers
    self:_setupEventHandlers()
    
    print("✅ Pet Service components initialized")
end

function PetServiceOrchestrator:_start()
    print("🚀 Starting Pet Service...")
    
    -- Setup player connection handlers
    Players.PlayerAdded:Connect(function(player)
        self:_onPlayerAdded(player)
    end)
    
    Players.PlayerRemoving:Connect(function(player)
        self:_onPlayerRemoving(player)
    end)
    
    -- Handle existing players
    for _, player in ipairs(Players:GetPlayers()) do
        self:_onPlayerAdded(player)
    end
    
    print("✅ Pet Service started")
end

function PetServiceOrchestrator:_stop()
    print("🛑 Stopping Pet Service...")
    
    -- Clean up all active pets
    self.modelService:ClearAllModels()
    
    -- Clear behavior connections
    for _, player in ipairs(Players:GetPlayers()) do
        self.behaviorService:DespawnPetBehavior(player.UserId)
    end
    
    print("✅ Pet Service stopped")
end

-- ========================================
-- EVENT HANDLERS
-- ========================================

function PetServiceOrchestrator:_setupEventHandlers()
    -- Pet purchase events
    self:AddEvent("pet_purchased", function(player, petId)
        self:_onPetPurchased(player, petId)
    end)
    
    -- Pet equipped events
    self:AddEvent("pet_equipped", function(player, petId)
        self:_onPetEquipped(player, petId)
    end)
    
    -- Game events for pet reactions
    self:AddEvent("barrier_matched", function(player, extraData)
        self:TriggerPetReaction(player, "onMatch", extraData)
    end)
    
    self:AddEvent("perfect_streak", function(player, extraData)
        self:TriggerPetReaction(player, "onPerfect", extraData)
    end)
    
    self:AddEvent("barrier_missed", function(player, extraData)
        self:TriggerPetReaction(player, "onMiss", extraData)
    end)
end

function PetServiceOrchestrator:_onPlayerAdded(player)
    -- Load player's pet data
    local playerPets = self.repository:GetById(player.UserId)
    print("📂 Loaded " .. #playerPets .. " pets for " .. player.Name)
    
    -- If player has an equipped pet, spawn it
    -- This would typically check for an "equipped" flag in the data
    if #playerPets > 0 then
        -- For now, equip the first pet (in a real system, check for equipped flag)
        spawn(function()
            wait(5) -- Give time for character to load
            self:EquipPet(player, playerPets[1])
        end)
    end
end

function PetServiceOrchestrator:_onPlayerRemoving(player)
    -- Save any pending data and clean up
    self:DespawnPet(player)
    self.repository:ClearCache(player.UserId)
    print("💾 Saved and cleaned up pet data for " .. player.Name)
end

function PetServiceOrchestrator:_onPetPurchased(player, petId)
    local success, message = self.repository:AddPetToPlayer(player.UserId, petId)
    if success then
        print("🛒 " .. player.Name .. " purchased pet: " .. petId)
        self:TriggerEvent("pet_inventory_updated", player, petId, "purchased")
    else
        warn("❌ Failed to add purchased pet: " .. message)
    end
end

function PetServiceOrchestrator:_onPetEquipped(player, petId)
    local success = self:EquipPet(player, petId)
    if success then
        print("✨ " .. player.Name .. " equipped pet: " .. petId)
        self:TriggerEvent("pet_equipped_success", player, petId)
    else
        warn("❌ Failed to equip pet: " .. petId)
    end
end

-- ========================================
-- PUBLIC API - PET OWNERSHIP
-- ========================================

function PetServiceOrchestrator:PurchasePet(player, petId, currency)
    -- Validate input
    local isValid, error = self.behaviorService:ValidateInput({
        petId = petId,
        playerId = player.UserId
    })
    
    if not isValid then
        return false, error
    end
    
    -- Get pet data
    local petData = PetDatabase:GetPetById(petId)
    if not petData then
        return false, "Pet not found: " .. petId
    end
    
    -- Check if already owned
    if self.repository:HasPet(player.UserId, petId) then
        return false, "Pet already owned"
    end
    
    -- Validate currency and cost
    if currency ~= petData.currency then
        return false, "Invalid currency for pet"
    end
    
    -- Check if player can afford (this would integrate with CurrencyService)
    local currencyService = ServiceRegistry.getInstance():GetService("CurrencyService")
    if currencyService then
        local canAfford = currencyService:CanAfford(player, petData.price, currency)
        if not canAfford then
            return false, "Insufficient " .. currency
        end
        
        -- Deduct cost
        local deducted = currencyService:DeductCurrency(player, petData.price, currency)
        if not deducted then
            return false, "Failed to deduct currency"
        end
    end
    
    -- Add to player's collection
    local success, message = self.repository:AddPetToPlayer(player.UserId, petId)
    if success then
        self:TriggerEvent("pet_purchased", player, petId)
        return true, "Pet purchased successfully"
    else
        -- Refund if addition failed
        if currencyService then
            currencyService:AddCurrency(player, petData.price, currency)
        end
        return false, message
    end
end

function PetServiceOrchestrator:AwardPet(player, petId, reason)
    -- Award pet without cost (for events, achievements, etc.)
    local success, message = self.repository:AddPetToPlayer(player.UserId, petId)
    if success then
        self:TriggerEvent("pet_awarded", player, petId, reason)
        print("🎁 Awarded pet to " .. player.Name .. ": " .. petId .. " (reason: " .. reason .. ")")
        return true, "Pet awarded successfully"
    else
        return false, message
    end
end

function PetServiceOrchestrator:GetPlayerPets(player)
    return self.repository:GetById(player.UserId)
end

function PetServiceOrchestrator:GetPlayerPetCount(player)
    return self.repository:GetPlayerPetCount(player.UserId)
end

-- ========================================
-- PUBLIC API - PET MANAGEMENT
-- ========================================

function PetServiceOrchestrator:EquipPet(player, petId)
    -- Validate ownership
    if not self.repository:HasPet(player.UserId, petId) then
        return false, "Pet not owned"
    end
    
    -- Get pet data
    local petData = PetDatabase:GetPetById(petId)
    if not petData then
        return false, "Pet data not found"
    end
    
    -- Despawn current pet
    self:DespawnPet(player)
    
    -- Create pet model
    local petModel, modelError = self.modelService:CreatePetModel(petData, player)
    if not petModel then
        return false, "Failed to create pet model: " .. (modelError or "Unknown error")
    end
    
    -- Start pet behavior
    local behaviorSuccess, behaviorError = self.behaviorService:SpawnPetBehavior(player.UserId, petId, petModel)
    if not behaviorSuccess then
        -- Clean up model if behavior failed
        self.modelService:DestroyPetModel(player)
        return false, "Failed to start pet behavior: " .. (behaviorError or "Unknown error")
    end
    
    self:TriggerEvent("pet_equipped", player, petId)
    return true, "Pet equipped successfully"
end

function PetServiceOrchestrator:DespawnPet(player)
    local behaviorSuccess = self.behaviorService:DespawnPetBehavior(player.UserId)
    local modelSuccess = self.modelService:DestroyPetModel(player)
    
    return behaviorSuccess or modelSuccess, "Pet despawned"
end

function PetServiceOrchestrator:GetActivePet(player)
    return self.behaviorService:GetActivePetStatus(player.UserId)
end

-- ========================================
-- PUBLIC API - PET INTERACTIONS
-- ========================================

function PetServiceOrchestrator:TriggerPetReaction(player, reactionType, extraData)
    local success, message = self.behaviorService:TriggerPetReaction(player.UserId, reactionType, extraData)
    return success, message
end

function PetServiceOrchestrator:ApplyPetPassive(player, gameData)
    local success, result = self.behaviorService:ApplyPetPassive(player.UserId, gameData)
    if success then
        self:TriggerEvent("pet_passive_applied", player, result)
    end
    return success, result
end

function PetServiceOrchestrator:UpdatePetVisual(player, visualData)
    local success, message = self.modelService:UpdatePetVisual(player, visualData)
    return success, message
end

-- ========================================
-- PUBLIC API - ADMINISTRATION
-- ========================================

function PetServiceOrchestrator:GetPetDatabase()
    return PetDatabase:GetAllPets()
end

function PetServiceOrchestrator:GetPetStats()
    return PetDatabase:GetDatabaseStats()
end

function PetServiceOrchestrator:GetServiceStats()
    local activePets = self.behaviorService:GetActivePetCount()
    local activeModels = 0
    for _ in pairs(self.modelService:GetActiveModels()) do
        activeModels = activeModels + 1
    end
    
    local cacheStats = self.repository:GetCacheStats()
    
    return {
        activePets = activePets,
        activeModels = activeModels,
        cacheSize = cacheStats.cacheSize,
        databaseStats = PetDatabase:GetDatabaseStats()
    }
end

function PetServiceOrchestrator:CleanupInactiveData()
    local modelsCleaned = self.modelService:CleanupInactiveModels()
    local cacheCleaned = self.repository:CleanExpiredCache()
    
    return {
        modelsCleaned = modelsCleaned,
        cacheCleaned = cacheCleaned
    }
end

-- ========================================
-- MYSTERY PET SYSTEM
-- ========================================

function PetServiceOrchestrator:OpenMysteryBox(player, boxType, minRarity)
    minRarity = minRarity or "Common"
    
    -- Get weighted random pet
    local randomPet = PetDatabase:GetWeightedRandomPet(true) -- Exclude special pets
    
    if not randomPet then
        return false, "No pets available in mystery box"
    end
    
    -- Filter by minimum rarity
    local rarityOrder = {"Common", "Uncommon", "Rare", "Epic", "Legendary"}
    local minRarityIndex = table.find(rarityOrder, minRarity) or 1
    local petRarityIndex = table.find(rarityOrder, randomPet.rarity) or 1
    
    if petRarityIndex < minRarityIndex then
        -- Try again with better odds for higher rarity
        for attempts = 1, 5 do
            randomPet = PetDatabase:GetWeightedRandomPet(true)
            petRarityIndex = table.find(rarityOrder, randomPet.rarity) or 1
            if petRarityIndex >= minRarityIndex then
                break
            end
        end
    end
    
    -- Award the pet
    local success, message = self:AwardPet(player, randomPet.id, "mystery_box")
    if success then
        self:TriggerEvent("mystery_box_opened", player, randomPet, boxType)
        return true, randomPet
    else
        return false, message
    end
end

-- ========================================
-- HEALTH STATUS IMPLEMENTATION
-- ========================================

function PetServiceOrchestrator:GetHealthStatus()
    local activePets = self.behaviorService:GetActivePetCount()
    local stats = self:GetServiceStats()
    
    local isHealthy = true
    local issues = {}
    
    -- Check for issues
    if stats.activePets ~= stats.activeModels then
        isHealthy = false
        table.insert(issues, "Mismatch between active pets and models")
    end
    
    if stats.cacheSize > 100 then
        table.insert(issues, "Large cache size: " .. stats.cacheSize)
    end
    
    return {
        isHealthy = isHealthy,
        status = isHealthy and "Healthy" or "Issues detected",
        metrics = {
            activePets = activePets,
            activeModels = stats.activeModels,
            cacheSize = stats.cacheSize,
            totalPetsInDatabase = stats.databaseStats.totalPets
        },
        issues = issues
    }
end

return PetServiceOrchestrator
