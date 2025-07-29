-- PetDatabase.luau
-- Static pet configuration and database management
-- Contains all pet definitions, stats, and lookup functionality

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local PetDatabase = {}

-- ========================================
-- PET DEFINITIONS DATABASE
-- ========================================

local PET_DATABASE = {
    -- ========== COMMON PETS (500-1000 coins) ==========
    {
        id = "spark_bunny",
        name = "⚡ Spark Bunny",
        description = "A zippy bunny that loves speed runs",
        rarity = "Common",
        price = 500,
        currency = "coins",
        passive = {
            type = "speed_bonus",
            value = 0.05, -- 5% speed boost
            description = "+5% running speed"
        },
        reactions = {
            onMatch = "hop_excited",
            onPerfect = "lightning_dance",
            onMiss = "sad_ears"
        },
        model = "SparkBunny",
        size = Vector3.new(2, 2, 2),
        followDistance = 4,
        color = Color3.new(1, 1, 0.6), -- Light yellow
        glowIntensity = 1
    },
    {
        id = "coin_cat",
        name = "💰 Coin Cat",
        description = "A lucky cat that brings fortune",
        rarity = "Common",
        price = 750,
        currency = "coins",
        passive = {
            type = "coin_bonus",
            value = 1,
            description = "+1 coin on perfect streaks"
        },
        reactions = {
            onMatch = "purr_happy",
            onPerfect = "golden_shimmer",
            onMiss = "disappointed_meow"
        },
        model = "CoinCat",
        size = Vector3.new(1.5, 1.5, 2.5),
        followDistance = 3,
        color = Color3.new(1, 0.8, 0.2), -- Golden
        glowIntensity = 1
    },
    {
        id = "forest_turtle",
        name = "🐢 Forest Turtle",
        description = "Slow and steady wins the race",
        rarity = "Common",
        price = 600,
        currency = "coins",
        passive = {
            type = "shield_chance",
            value = 0.1,
            description = "10% chance to ignore missed barriers"
        },
        reactions = {
            onMatch = "shell_glow",
            onPerfect = "nature_bloom",
            onMiss = "shell_retreat"
        },
        model = "ForestTurtle",
        size = Vector3.new(2.2, 1.5, 2.8),
        followDistance = 3.5,
        color = Color3.new(0.3, 0.8, 0.2), -- Forest green
        glowIntensity = 1
    },
    
    -- ========== UNCOMMON PETS (1200-2000 coins) ==========
    {
        id = "fire_fox",
        name = "🔥 Fire Fox",
        description = "A mystical fox with burning spirit",
        rarity = "Uncommon",
        price = 1200,
        currency = "coins",
        passive = {
            type = "streak_bonus",
            value = 0.15,
            description = "+15% bonus points on streaks"
        },
        reactions = {
            onMatch = "flame_swirl",
            onPerfect = "fire_burst",
            onMiss = "ember_fade"
        },
        model = "FireFox",
        size = Vector3.new(2.5, 2, 3),
        followDistance = 4.5,
        color = Color3.new(1, 0.3, 0), -- Fire red
        glowIntensity = 1.5
    },
    {
        id = "crystal_owl",
        name = "💎 Crystal Owl",
        description = "Wise owl with crystalline feathers",
        rarity = "Uncommon",
        price = 1500,
        currency = "coins",
        passive = {
            type = "xp_bonus",
            value = 0.2,
            description = "+20% experience gained"
        },
        reactions = {
            onMatch = "crystal_chime",
            onPerfect = "prism_glow",
            onMiss = "dim_crystals"
        },
        model = "CrystalOwl",
        size = Vector3.new(2, 2.5, 2),
        followDistance = 5,
        color = Color3.new(0.8, 0.9, 1), -- Crystal blue
        glowIntensity = 1.2
    },
    
    -- ========== RARE PETS (3000-5000 coins or Robux) ==========
    {
        id = "shadow_wolf",
        name = "🌙 Shadow Wolf",
        description = "A mysterious wolf from the shadow realm",
        rarity = "Rare",
        price = 3000,
        currency = "coins",
        passive = {
            type = "multi_passive",
            effects = {
                {type = "speed_bonus", value = 0.1},
                {type = "coin_bonus", value = 2}
            },
            description = "+10% speed and +2 coins on perfect streaks"
        },
        reactions = {
            onMatch = "shadow_dash",
            onPerfect = "howl_echo",
            onMiss = "fade_shadow"
        },
        model = "ShadowWolf",
        size = Vector3.new(3, 2.5, 4),
        followDistance = 5,
        color = Color3.new(0.2, 0.2, 0.4), -- Dark purple
        glowIntensity = 2
    },
    {
        id = "rainbow_unicorn",
        name = "🦄 Rainbow Unicorn",
        description = "Magical unicorn with rainbow mane",
        rarity = "Rare",
        price = 199, -- Robux
        currency = "robux",
        passive = {
            type = "multi_passive",
            effects = {
                {type = "xp_bonus", value = 0.3},
                {type = "streak_bonus", value = 0.25}
            },
            description = "+30% XP and +25% streak bonus"
        },
        reactions = {
            onMatch = "rainbow_trail",
            onPerfect = "magic_sparkles",
            onMiss = "sad_neigh"
        },
        model = "RainbowUnicorn",
        size = Vector3.new(3.5, 3, 4),
        followDistance = 6,
        color = Color3.new(1, 0.5, 1), -- Rainbow (changes)
        glowIntensity = 2.5
    },
    
    -- ========== EPIC PETS (Gamepass or special events) ==========
    {
        id = "golden_dragon",
        name = "🐉 Golden Dragon",
        description = "Legendary dragon of prosperity",
        rarity = "Epic",
        price = 0, -- Gamepass only
        currency = "gamepass",
        gamepassId = 123456789,
        passive = {
            type = "multi_passive",
            effects = {
                {type = "speed_bonus", value = 0.2},
                {type = "coin_bonus", value = 5},
                {type = "xp_bonus", value = 0.5}
            },
            description = "+20% speed, +5 coins on perfect, +50% XP"
        },
        reactions = {
            onMatch = "golden_flames",
            onPerfect = "roar_triumph",
            onMiss = "disappointed_growl"
        },
        model = "GoldenDragon",
        size = Vector3.new(4, 3.5, 5),
        followDistance = 7,
        color = Color3.new(1, 0.8, 0), -- Golden
        glowIntensity = 3
    },
    
    -- ========== LEGENDARY PETS (Ultra rare) ==========
    {
        id = "cosmic_phoenix",
        name = "🌟 Cosmic Phoenix",
        description = "Reborn from cosmic stardust",
        rarity = "Legendary",
        price = 0, -- Event/mystery box only
        currency = "special",
        passive = {
            type = "ultimate_passive",
            effects = {
                {type = "speed_bonus", value = 0.3},
                {type = "coin_bonus", value = 10},
                {type = "xp_bonus", value = 1.0}, -- Double XP
                {type = "shield_chance", value = 0.25}
            },
            description = "Ultimate companion: +30% speed, +10 coins, double XP, 25% shield"
        },
        reactions = {
            onMatch = "cosmic_trail",
            onPerfect = "phoenix_rebirth",
            onMiss = "stellar_fade"
        },
        model = "CosmicPhoenix",
        size = Vector3.new(4.5, 4, 5.5),
        followDistance = 8,
        color = Color3.new(0.5, 0.8, 1), -- Cosmic blue
        glowIntensity = 4
    }
}

-- ========================================
-- RARITY CONFIGURATION
-- ========================================

local RARITY_CONFIG = {
    Common = {
        weight = 70,
        color = Color3.new(0.8, 0.8, 0.8), -- Light gray
        glowColor = Color3.new(1, 1, 1)
    },
    Uncommon = {
        weight = 20,
        color = Color3.new(0.5, 1, 0.5), -- Light green
        glowColor = Color3.new(0, 1, 0)
    },
    Rare = {
        weight = 7,
        color = Color3.new(0.5, 0.5, 1), -- Light blue
        glowColor = Color3.new(0, 0.5, 1)
    },
    Epic = {
        weight = 2.5,
        color = Color3.new(0.8, 0.3, 1), -- Purple
        glowColor = Color3.new(0.6, 0, 1)
    },
    Legendary = {
        weight = 0.5,
        color = Color3.new(1, 0.8, 0), -- Gold
        glowColor = Color3.new(1, 1, 0)
    }
}

-- ========================================
-- DATABASE QUERY METHODS
-- ========================================

function PetDatabase:GetAllPets()
    return PET_DATABASE
end

function PetDatabase:GetPetById(petId)
    for _, pet in ipairs(PET_DATABASE) do
        if pet.id == petId then
            return pet
        end
    end
    return nil
end

function PetDatabase:GetPetsByRarity(rarity)
    local pets = {}
    for _, pet in ipairs(PET_DATABASE) do
        if pet.rarity == rarity then
            table.insert(pets, pet)
        end
    end
    return pets
end

function PetDatabase:GetPetsByCurrency(currency)
    local pets = {}
    for _, pet in ipairs(PET_DATABASE) do
        if pet.currency == currency then
            table.insert(pets, pet)
        end
    end
    return pets
end

function PetDatabase:GetPetsByPriceRange(minPrice, maxPrice, currency)
    local pets = {}
    for _, pet in ipairs(PET_DATABASE) do
        if pet.currency == currency and pet.price >= minPrice and pet.price <= maxPrice then
            table.insert(pets, pet)
        end
    end
    return pets
end

function PetDatabase:GetPetsWithPassive(passiveType)
    local pets = {}
    for _, pet in ipairs(PET_DATABASE) do
        if pet.passive.type == passiveType or 
           (pet.passive.type == "multi_passive" and self:_hasPassiveInMulti(pet.passive.effects, passiveType)) then
            table.insert(pets, pet)
        end
    end
    return pets
end

function PetDatabase:_hasPassiveInMulti(effects, passiveType)
    for _, effect in ipairs(effects) do
        if effect.type == passiveType then
            return true
        end
    end
    return false
end

-- ========================================
-- RARITY SYSTEM
-- ========================================

function PetDatabase:GetRarityConfig(rarity)
    return RARITY_CONFIG[rarity]
end

function PetDatabase:GetAllRarities()
    local rarities = {}
    for rarity, _ in pairs(RARITY_CONFIG) do
        table.insert(rarities, rarity)
    end
    return rarities
end

function PetDatabase:GetRandomPetByRarity(rarity)
    local pets = self:GetPetsByRarity(rarity)
    if #pets > 0 then
        return pets[math.random(1, #pets)]
    end
    return nil
end

function PetDatabase:GetWeightedRandomPet(excludeSpecial)
    excludeSpecial = excludeSpecial ~= false -- Default to true
    
    local availablePets = {}
    local totalWeight = 0
    
    for _, pet in ipairs(PET_DATABASE) do
        local shouldInclude = true
        
        if excludeSpecial and (pet.currency == "gamepass" or pet.currency == "special") then
            shouldInclude = false
        end
        
        if shouldInclude then
            local rarityConfig = RARITY_CONFIG[pet.rarity]
            if rarityConfig then
                table.insert(availablePets, {
                    pet = pet,
                    weight = rarityConfig.weight
                })
                totalWeight = totalWeight + rarityConfig.weight
            end
        end
    end
    
    if totalWeight == 0 then
        return nil
    end
    
    local random = math.random() * totalWeight
    local currentWeight = 0
    
    for _, entry in ipairs(availablePets) do
        currentWeight = currentWeight + entry.weight
        if random <= currentWeight then
            return entry.pet
        end
    end
    
    -- Fallback to last pet
    return availablePets[#availablePets].pet
end

-- ========================================
-- VALIDATION AND STATISTICS
-- ========================================

function PetDatabase:ValidatePetData()
    local issues = {}
    
    for i, pet in ipairs(PET_DATABASE) do
        -- Check required fields
        local requiredFields = {"id", "name", "description", "rarity", "price", "currency", "passive", "model"}
        for _, field in ipairs(requiredFields) do
            if not pet[field] then
                table.insert(issues, "Pet #" .. i .. " missing field: " .. field)
            end
        end
        
        -- Check rarity exists
        if pet.rarity and not RARITY_CONFIG[pet.rarity] then
            table.insert(issues, "Pet " .. (pet.id or "#" .. i) .. " has invalid rarity: " .. pet.rarity)
        end
        
        -- Check currency
        local validCurrencies = {"coins", "robux", "gamepass", "special"}
        if pet.currency and not table.find(validCurrencies, pet.currency) then
            table.insert(issues, "Pet " .. (pet.id or "#" .. i) .. " has invalid currency: " .. pet.currency)
        end
    end
    
    return issues
end

function PetDatabase:GetDatabaseStats()
    local stats = {
        totalPets = #PET_DATABASE,
        byRarity = {},
        byCurrency = {},
        averagePrice = {coins = 0, robux = 0},
        priceRange = {coins = {min = math.huge, max = 0}, robux = {min = math.huge, max = 0}}
    }
    
    local coinSum, robuxSum = 0, 0
    local coinCount, robuxCount = 0, 0
    
    for _, pet in ipairs(PET_DATABASE) do
        -- Count by rarity
        stats.byRarity[pet.rarity] = (stats.byRarity[pet.rarity] or 0) + 1
        
        -- Count by currency
        stats.byCurrency[pet.currency] = (stats.byCurrency[pet.currency] or 0) + 1
        
        -- Price statistics
        if pet.currency == "coins" and pet.price > 0 then
            coinSum = coinSum + pet.price
            coinCount = coinCount + 1
            if pet.price < stats.priceRange.coins.min then
                stats.priceRange.coins.min = pet.price
            end
            if pet.price > stats.priceRange.coins.max then
                stats.priceRange.coins.max = pet.price
            end
        elseif pet.currency == "robux" and pet.price > 0 then
            robuxSum = robuxSum + pet.price
            robuxCount = robuxCount + 1
            if pet.price < stats.priceRange.robux.min then
                stats.priceRange.robux.min = pet.price
            end
            if pet.price > stats.priceRange.robux.max then
                stats.priceRange.robux.max = pet.price
            end
        end
    end
    
    -- Calculate averages
    if coinCount > 0 then
        stats.averagePrice.coins = coinSum / coinCount
    end
    if robuxCount > 0 then
        stats.averagePrice.robux = robuxSum / robuxCount
    end
    
    -- Handle empty ranges
    if stats.priceRange.coins.min == math.huge then
        stats.priceRange.coins.min = 0
    end
    if stats.priceRange.robux.min == math.huge then
        stats.priceRange.robux.min = 0
    end
    
    return stats
end

return PetDatabase
