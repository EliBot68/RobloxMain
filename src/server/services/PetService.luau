-- PetService.luau
-- Handles pet ownership, behaviors, and passive abilities

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local DataStoreService = game:GetService("DataStoreService")
local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local SafeRequire = require(ReplicatedStorage.Shared.utils.SafeRequire)
local WorldObjectValidator = SafeRequire.require(ReplicatedStorage.Shared.utils.WorldObjectValidator)
local PlayerService = SafeRequire.require(script.Parent.PlayerService)
local RemoteEvents = SafeRequire.require(ReplicatedStorage.Shared.modules.RemoteEvents)

local PetService = {}

-- DataStore for pet ownership
local petDataStore = DataStoreService:GetDataStore("PlayerPets")

-- Pet definitions with stats and abilities
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
    {
        id = "ice_penguin",
        name = "🐧 Ice Penguin",
        description = "A cool companion from the arctic",
        rarity = "Common",
        price = 800,
        currency = "coins",
        passive = {
            type = "freeze_time",
            value = 0.5,
            description = "+0.5 seconds reaction time"
        },
        reactions = {
            onMatch = "ice_slide",
            onPerfect = "blizzard_dance",
            onMiss = "sad_waddle"
        },
        model = "IcePenguin",
        size = Vector3.new(1.8, 2.5, 1.8),
        followDistance = 4,
        color = Color3.new(0.7, 0.9, 1), -- Ice blue
        glowIntensity = 1
    },
    {
        id = "honey_bee",
        name = "🐝 Honey Bee",
        description = "Buzzes with excitement for barriers",
        rarity = "Common",
        price = 900,
        currency = "coins",
        passive = {
            type = "buzz_boost",
            value = 0.08,
            description = "+8% coin collection rate"
        },
        reactions = {
            onMatch = "happy_buzz",
            onPerfect = "pollen_explosion",
            onMiss = "dizzy_spiral"
        },
        model = "HoneyBee",
        size = Vector3.new(1, 1, 1.5),
        followDistance = 5,
        color = Color3.new(1, 0.8, 0), -- Yellow and black
        glowIntensity = 1.2
    },

    -- ========== UNCOMMON PETS (1200-2000 coins) ==========
    {
        id = "rainbow_bird",
        name = "🌈 Rainbow Bird",
        description = "Celebrates every color match",
        rarity = "Uncommon",
        price = 1200,
        currency = "coins",
        passive = {
            type = "color_bonus",
            value = 0.15,
            description = "+15% chance for bonus effects"
        },
        reactions = {
            onMatch = "wing_flutter",
            onPerfect = "rainbow_trail",
            onMiss = "feather_drop"
        },
        model = "RainbowBird",
        size = Vector3.new(1, 1, 1.5),
        followDistance = 5,
        color = Color3.new(0.8, 0.4, 1), -- Purple base
        glowIntensity = 1.5
    },
    {
        id = "electric_fox",
        name = "⚡ Electric Fox",
        description = "Charged with electric energy",
        rarity = "Uncommon",
        price = 1500,
        currency = "coins",
        passive = {
            type = "lightning_speed",
            value = 0.12,
            description = "+12% speed and reaction time"
        },
        reactions = {
            onMatch = "electric_spark",
            onPerfect = "lightning_storm",
            onMiss = "static_shock"
        },
        model = "ElectricFox",
        size = Vector3.new(2, 2, 2.5),
        followDistance = 4,
        color = Color3.new(0.2, 0.8, 1), -- Electric blue
        glowIntensity = 2
    },
    {
        id = "wind_eagle",
        name = "🦅 Wind Eagle",
        description = "Soars above with grace and power",
        rarity = "Uncommon",
        price = 1700,
        currency = "coins",
        passive = {
            type = "aerial_view",
            value = 0.2,
            description = "+20% perfect streak bonus"
        },
        reactions = {
            onMatch = "wind_gust",
            onPerfect = "sky_dive",
            onMiss = "worried_cry"
        },
        model = "WindEagle",
        size = Vector3.new(2.5, 1.5, 3),
        followDistance = 6,
        color = Color3.new(0.6, 0.4, 0.2), -- Brown and white
        glowIntensity = 1.5
    },
    {
        id = "gem_slime",
        name = "💎 Gem Slime",
        description = "A jiggly friend made of precious gems",
        rarity = "Uncommon",
        price = 1800,
        currency = "coins",
        passive = {
            type = "gem_magnet",
            value = 2,
            description = "+2 coins on every 5th barrier"
        },
        reactions = {
            onMatch = "gem_sparkle",
            onPerfect = "crystal_rain",
            onMiss = "slime_deflate"
        },
        model = "GemSlime",
        size = Vector3.new(2, 2, 2),
        followDistance = 3,
        color = Color3.new(0.8, 0.2, 0.8), -- Magenta gems
        glowIntensity = 2
    },

    -- ========== RARE PETS (2500-4000 coins) ==========
    {
        id = "crystal_fox",
        name = "💎 Crystal Fox",
        description = "A mystical fox with crystal powers",
        rarity = "Rare",
        price = 2500,
        currency = "coins",
        passive = {
            type = "combo_protection",
            value = 1,
            description = "Saves you from 1 mistake per game"
        },
        reactions = {
            onMatch = "crystal_glow",
            onPerfect = "crystal_burst",
            onMiss = "protective_shield"
        },
        model = "CrystalFox",
        size = Vector3.new(2, 2, 3),
        followDistance = 3.5,
        color = Color3.new(0.6, 0.8, 1), -- Crystal blue
        glowIntensity = 2.5
    },
    {
        id = "fire_dragon",
        name = "🔥 Fire Dragon",
        description = "A tiny dragon with big attitude",
        rarity = "Rare",
        price = 3000,
        currency = "coins",
        passive = {
            type = "streak_multiplier",
            value = 0.2,
            description = "+20% score on 5+ streaks"
        },
        reactions = {
            onMatch = "flame_puff",
            onPerfect = "fire_roar",
            onMiss = "smoke_sigh"
        },
        model = "FireDragon",
        size = Vector3.new(1.8, 2.5, 2),
        followDistance = 4,
        color = Color3.new(1, 0.3, 0), -- Fire red
        glowIntensity = 3
    },
    {
        id = "moon_wolf",
        name = "🌙 Moon Wolf",
        description = "A mystical wolf blessed by moonlight",
        rarity = "Rare",
        price = 3200,
        currency = "coins",
        passive = {
            type = "lunar_blessing",
            value = 0.25,
            description = "+25% XP during night hours"
        },
        reactions = {
            onMatch = "moon_howl",
            onPerfect = "lunar_eclipse",
            onMiss = "gentle_whine"
        },
        model = "MoonWolf",
        size = Vector3.new(2.2, 2.5, 3),
        followDistance = 4,
        color = Color3.new(0.7, 0.7, 1), -- Moonlight silver
        glowIntensity = 2.5
    },
    {
        id = "magma_bear",
        name = "🌋 Magma Bear",
        description = "A powerful bear from volcanic depths",
        rarity = "Rare",
        price = 3500,
        currency = "coins",
        passive = {
            type = "molten_power",
            value = 0.3,
            description = "+30% coin value from perfect games"
        },
        reactions = {
            onMatch = "lava_stomp",
            onPerfect = "volcanic_eruption",
            onMiss = "cooling_sigh"
        },
        model = "MagmaBear",
        size = Vector3.new(2.5, 3, 2.5),
        followDistance = 3,
        color = Color3.new(1, 0.4, 0), -- Molten orange
        glowIntensity = 3
    },
    {
        id = "storm_owl",
        name = "⛈️ Storm Owl",
        description = "Commands the power of thunder and lightning",
        rarity = "Rare",
        price = 3800,
        currency = "coins",
        passive = {
            type = "storm_surge",
            value = 0.15,
            description = "+15% chance for double coins"
        },
        reactions = {
            onMatch = "thunder_hoot",
            onPerfect = "lightning_strike",
            onMiss = "rain_clouds"
        },
        model = "StormOwl",
        size = Vector3.new(2, 2.5, 2),
        followDistance = 5,
        color = Color3.new(0.3, 0.3, 0.7), -- Storm grey
        glowIntensity = 2.5
    },

    -- ========== EPIC PETS (5000-8000 coins) ==========
    {
        id = "shadow_wolf",
        name = "🌙 Shadow Wolf",
        description = "A loyal companion from the void",
        rarity = "Epic",
        price = 5000,
        currency = "coins",
        passive = {
            type = "shadow_mastery",
            value = 0.3,
            description = "+30% ghost race performance"
        },
        reactions = {
            onMatch = "shadow_step",
            onPerfect = "howl_victory",
            onMiss = "shadow_comfort"
        },
        model = "ShadowWolf",
        size = Vector3.new(2.5, 2.8, 3.5),
        followDistance = 3,
        color = Color3.new(0.2, 0.2, 0.4), -- Dark purple
        glowIntensity = 3.5
    },
    {
        id = "void_dragon",
        name = "🖤 Void Dragon",
        description = "Born from the emptiness between stars",
        rarity = "Epic",
        price = 6000,
        currency = "coins",
        passive = {
            type = "void_absorption",
            value = 0.4,
            description = "+40% score multiplier on perfect streaks"
        },
        reactions = {
            onMatch = "void_pulse",
            onPerfect = "reality_tear",
            onMiss = "dimension_shift"
        },
        model = "VoidDragon",
        size = Vector3.new(3, 3.5, 3),
        followDistance = 5,
        color = Color3.new(0.1, 0.1, 0.2), -- Deep void
        glowIntensity = 4
    },
    {
        id = "prism_unicorn",
        name = "🌈 Prism Unicorn",
        description = "Refracts light into beautiful rainbows",
        rarity = "Epic",
        price = 6500,
        currency = "coins",
        passive = {
            type = "spectral_blessing",
            value = 0.35,
            description = "+35% all bonuses and effects"
        },
        reactions = {
            onMatch = "prism_shine",
            onPerfect = "rainbow_nova",
            onMiss = "light_fade"
        },
        model = "PrismUnicorn",
        size = Vector3.new(2.8, 3.2, 3.5),
        followDistance = 4.5,
        color = Color3.new(1, 1, 1), -- Pure white with rainbow
        glowIntensity = 4
    },
    {
        id = "time_phoenix",
        name = "⏰ Time Phoenix",
        description = "Controls the flow of time itself",
        rarity = "Epic",
        price = 7000,
        currency = "coins",
        passive = {
            type = "temporal_mastery",
            value = 0.25,
            description = "+25% all speeds, -25% cooldowns"
        },
        reactions = {
            onMatch = "time_ripple",
            onPerfect = "temporal_storm",
            onMiss = "time_rewind"
        },
        model = "TimePhoenix",
        size = Vector3.new(2.5, 3.5, 3),
        followDistance = 5,
        color = Color3.new(0.8, 0.6, 1), -- Temporal purple
        glowIntensity = 4.5
    },
    {
        id = "celestial_tiger",
        name = "🐅 Celestial Tiger",
        description = "A majestic predator from the heavens",
        rarity = "Epic",
        price = 7500,
        currency = "coins",
        passive = {
            type = "hunter_instinct",
            value = 0.5,
            description = "+50% perfect game rewards"
        },
        reactions = {
            onMatch = "stellar_prowl",
            onPerfect = "cosmic_roar",
            onMiss = "starlight_comfort"
        },
        model = "CelestialTiger",
        size = Vector3.new(3, 2.5, 4),
        followDistance = 3.5,
        color = Color3.new(1, 0.8, 0.4), -- Golden celestial
        glowIntensity = 4
    },

    -- ========== LEGENDARY PETS (100-250 Robux) ==========
    {
        id = "cosmic_unicorn",
        name = "🦄 Cosmic Unicorn",
        description = "A majestic being from the stars",
        rarity = "Legendary",
        price = 150,
        currency = "robux",
        passive = {
            type = "cosmic_harmony",
            value = 0.4,
            description = "+40% XP from all activities"
        },
        reactions = {
            onMatch = "star_sparkle",
            onPerfect = "cosmic_blessing",
            onMiss = "healing_aura"
        },
        model = "CosmicUnicorn",
        size = Vector3.new(3, 3.5, 4),
        followDistance = 4.5,
        color = Color3.new(0.9, 0.7, 1), -- Cosmic purple
        glowIntensity = 5
    },
    {
        id = "quantum_cat",
        name = "🌌 Quantum Cat",
        description = "Exists in multiple dimensions simultaneously",
        rarity = "Legendary",
        price = 180,
        currency = "robux",
        passive = {
            type = "quantum_entanglement",
            value = 0.6,
            description = "+60% coin multiplier, teleports on mistakes"
        },
        reactions = {
            onMatch = "phase_shift",
            onPerfect = "quantum_leap",
            onMiss = "probability_warp"
        },
        model = "QuantumCat",
        size = Vector3.new(2, 2, 3),
        followDistance = 4,
        color = Color3.new(0.5, 1, 0.8), -- Quantum green
        glowIntensity = 5.5
    },
    {
        id = "galactic_dragon",
        name = "🌌 Galactic Dragon",
        description = "Guardian of entire star systems",
        rarity = "Legendary",
        price = 200,
        currency = "robux",
        passive = {
            type = "galactic_dominance",
            value = 0.75,
            description = "+75% all rewards, cosmic trail"
        },
        reactions = {
            onMatch = "solar_flare",
            onPerfect = "supernova",
            onMiss = "black_hole"
        },
        model = "GalacticDragon",
        size = Vector3.new(4, 4.5, 4),
        followDistance = 6,
        color = Color3.new(0.2, 0.1, 0.8), -- Deep space
        glowIntensity = 6
    },
    {
        id = "infinity_wolf",
        name = "♾️ Infinity Wolf",
        description = "Embodies the concept of limitlessness",
        rarity = "Legendary",
        price = 220,
        currency = "robux",
        passive = {
            type = "infinite_potential",
            value = 1.0,
            description = "Doubles all bonuses, unlimited mistake saves"
        },
        reactions = {
            onMatch = "reality_bend",
            onPerfect = "infinity_howl",
            onMiss = "space_time_heal"
        },
        model = "InfinityWolf",
        size = Vector3.new(3.5, 3, 4.5),
        followDistance = 4,
        color = Color3.new(1, 1, 1), -- Pure infinity
        glowIntensity = 6
    },

    -- ========== MYTHIC PETS (300-500 Robux) ==========
    {
        id = "golden_phoenix",
        name = "🔱 Golden Phoenix",
        description = "The ultimate companion of champions",
        rarity = "Mythic",
        price = 300,
        currency = "robux",
        passive = {
            type = "legendary_rebirth",
            value = 1.0,
            description = "+100% coins and XP from perfect games"
        },
        reactions = {
            onMatch = "golden_feather",
            onPerfect = "phoenix_rebirth",
            onMiss = "encouraging_song"
        },
        model = "GoldenPhoenix",
        size = Vector3.new(2.8, 4, 3.5),
        followDistance = 6,
        color = Color3.new(1, 0.8, 0), -- Pure gold
        glowIntensity = 7
    },
    {
        id = "divine_leviathan",
        name = "🐲 Divine Leviathan",
        description = "An ancient sea dragon of immense power",
        rarity = "Mythic",
        price = 400,
        currency = "robux",
        passive = {
            type = "oceanic_mastery",
            value = 1.5,
            description = "+150% all bonuses, creates water effects"
        },
        reactions = {
            onMatch = "tidal_wave",
            onPerfect = "divine_tsunami",
            onMiss = "healing_waters"
        },
        model = "DivineLeviathan",
        size = Vector3.new(5, 3, 6),
        followDistance = 7,
        color = Color3.new(0.1, 0.6, 1), -- Deep ocean
        glowIntensity = 8
    },
    {
        id = "primordial_beast",
        name = "👹 Primordial Beast",
        description = "The first creature, older than time",
        rarity = "Mythic",
        price = 450,
        currency = "robux",
        passive = {
            type = "primordial_essence",
            value = 2.0,
            description = "+200% ALL effects, reality manipulation"
        },
        reactions = {
            onMatch = "primal_roar",
            onPerfect = "creation_burst",
            onMiss = "time_reversal"
        },
        model = "PrimordialBeast",
        size = Vector3.new(4.5, 4, 5),
        followDistance = 5,
        color = Color3.new(0.8, 0.2, 0.8), -- Primordial energy
        glowIntensity = 9
    },
    {
        id = "omega_deity",
        name = "✨ Omega Deity",
        description = "The ultimate transcendent being",
        rarity = "Mythic",
        price = 500,
        currency = "robux",
        passive = {
            type = "transcendent_power",
            value = 3.0,
            description = "TRIPLES all effects, breaks reality"
        },
        reactions = {
            onMatch = "divine_blessing",
            onPerfect = "reality_rewrite",
            onMiss = "omnipotent_fix"
        },
        model = "OmegaDeity",
        size = Vector3.new(5, 5, 5),
        followDistance = 8,
        color = Color3.new(1, 1, 1), -- Pure divine light
        glowIntensity = 10
    }
}

-- Active pets tracking
local activePets = {} -- [userId] = {petData, petModel, behaviorConnection}
local petBehaviors = {} -- Connection tracking for cleanup

function PetService:CreatePetModel(petData, player)
    -- Create a simple pet model (in a real game, you'd load actual 3D models)
    local petModel = Instance.new("Model")
    petModel.Name = petData.name .. "_Pet"
    
    -- Main body
    local body = Instance.new("Part")
    body.Name = "Body"
    body.Size = petData.size
    body.Shape = Enum.PartType.Ball
    body.Material = Enum.Material.ForceField
    body.Color = petData.color
    body.CanCollide = false
    body.Anchored = false
    body.Parent = petModel
    
    -- Enhanced glow based on rarity
    local glowIntensity = petData.glowIntensity or 1
    local pointLight = Instance.new("PointLight")
    pointLight.Color = petData.color
    pointLight.Brightness = glowIntensity * 2
    pointLight.Range = glowIntensity * 15
    pointLight.Parent = body
    
    -- Rarity-based material effects
    if petData.rarity == "Common" then
        body.Material = Enum.Material.Neon
    elseif petData.rarity == "Uncommon" then
        body.Material = Enum.Material.ForceField
    elseif petData.rarity == "Rare" then
        body.Material = Enum.Material.Glass
        -- Add sparkle effect
        local sparkleGui = Instance.new("BillboardGui")
        sparkleGui.Size = UDim2.new(2, 0, 2, 0)
        sparkleGui.Parent = body
        
        local sparkleLabel = Instance.new("TextLabel")
        sparkleLabel.Size = UDim2.new(1, 0, 1, 0)
        sparkleLabel.BackgroundTransparency = 1
        sparkleLabel.Text = "✨"
        sparkleLabel.TextColor3 = Color3.new(1, 1, 1)
        sparkleLabel.TextScaled = true
        sparkleLabel.Parent = sparkleGui
        
    elseif petData.rarity == "Epic" then
        body.Material = Enum.Material.ForceField
        -- Add epic glow ring
        local glowRing = Instance.new("Part")
        glowRing.Name = "GlowRing"
        glowRing.Size = Vector3.new(petData.size.X + 2, 0.5, petData.size.Z + 2)
        glowRing.Shape = Enum.PartType.Cylinder
        glowRing.Material = Enum.Material.Neon
        glowRing.Color = petData.color
        glowRing.Anchored = false
        glowRing.CanCollide = false
        glowRing.Transparency = 0.5
        glowRing.Parent = petModel
        
        -- Weld ring to body
        local weld = Instance.new("WeldConstraint")
        weld.Part0 = body
        weld.Part1 = glowRing
        weld.Parent = body
        
    elseif petData.rarity == "Legendary" then
        body.Material = Enum.Material.ForceField
        -- Add legendary aura
        local aura = Instance.new("Part")
        aura.Name = "Aura"
        aura.Size = petData.size * 1.5
        aura.Shape = Enum.PartType.Ball
        aura.Material = Enum.Material.ForceField
        aura.Color = petData.color
        aura.Anchored = false
        aura.CanCollide = false
        aura.Transparency = 0.8
        aura.Parent = petModel
        
        -- Weld aura to body
        local weld = Instance.new("WeldConstraint")
        weld.Part0 = body
        weld.Part1 = aura
        weld.Parent = body
        
        -- Pulsing aura animation
        local auraTween = TweenService:Create(
            aura,
            TweenInfo.new(2, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true),
            {Transparency = 0.9, Size = petData.size * 1.8}
        )
        auraTween:Play()
        
    elseif petData.rarity == "Mythic" then
        body.Material = Enum.Material.ForceField
        -- Add mythic reality distortion
        local distortion = Instance.new("Part")
        distortion.Name = "Distortion"
        distortion.Size = petData.size * 2
        distortion.Shape = Enum.PartType.Ball
        distortion.Material = Enum.Material.ForceField
        distortion.Color = Color3.new(1, 1, 1)
        distortion.Anchored = false
        distortion.CanCollide = false
        distortion.Transparency = 0.95
        distortion.Parent = petModel
        
        -- Weld distortion to body
        local weld = Instance.new("WeldConstraint")
        weld.Part0 = body
        weld.Part1 = distortion
        weld.Parent = body
        
        -- Reality warping effect
        local warpTween = TweenService:Create(
            distortion,
            TweenInfo.new(3, Enum.EasingStyle.Elastic, Enum.EasingDirection.InOut, -1, true),
            {Size = petData.size * 0.5, Transparency = 0.99}
        )
        warpTween:Play()
        
        -- Multiple colored lights for mythic
        local colors = {
            Color3.new(1, 0, 0), -- Red
            Color3.new(0, 1, 0), -- Green  
            Color3.new(0, 0, 1), -- Blue
            Color3.new(1, 1, 0), -- Yellow
            Color3.new(1, 0, 1), -- Magenta
            Color3.new(0, 1, 1)  -- Cyan
        }
        
        for i, color in pairs(colors) do
            local colorLight = Instance.new("PointLight")
            colorLight.Color = color
            colorLight.Brightness = glowIntensity
            colorLight.Range = glowIntensity * 10
            colorLight.Parent = body
            
            -- Animate light brightness
            spawn(function()
                while body.Parent do
                    local brightnessTween = TweenService:Create(
                        colorLight,
                        TweenInfo.new(1 + i * 0.2, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true),
                        {Brightness = glowIntensity * 2}
                    )
                    brightnessTween:Play()
                    wait(0.1)
                end
            end)
        end
    end
    
    -- Add a cute face
    local face = Instance.new("Decal")
    face.Texture = "rbxasset://textures/face.png"
    face.Face = Enum.NormalId.Front
    face.Parent = body
    
    -- Add body physics
    local bodyVelocity = Instance.new("BodyVelocity")
    bodyVelocity.MaxForce = Vector3.new(4000, 4000, 4000)
    bodyVelocity.Velocity = Vector3.new(0, 0, 0)
    bodyVelocity.Parent = body
    
    local bodyPosition = Instance.new("BodyPosition")
    bodyPosition.MaxForce = Vector3.new(4000, 4000, 4000)
    bodyPosition.Position = body.Position
    bodyPosition.D = 2000
    bodyPosition.P = 10000
    bodyPosition.Parent = body
    
    -- Enhanced floating effect based on rarity
    local floatHeight = 1 + (glowIntensity * 0.5)
    local floatSpeed = 2 - (glowIntensity * 0.1)
    
    local floatTween = TweenService:Create(
        body,
        TweenInfo.new(floatSpeed, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true),
        {Position = body.Position + Vector3.new(0, floatHeight, 0)}
    )
    
    -- Store references
    petModel:SetAttribute("PetId", petData.id)
    petModel:SetAttribute("OwnerId", player.UserId)
    petModel:SetAttribute("Rarity", petData.rarity)
    
    return petModel, bodyPosition, bodyVelocity, floatTween
end

function PetService:SpawnPet(player, petId)
    if not player.Character or not player.Character:FindFirstChild("HumanoidRootPart") then
        return false
    end
    
    -- Find pet data
    local petData = nil
    for _, pet in pairs(PET_DATABASE) do
        if pet.id == petId then
            petData = pet
            break
        end
    end
    
    if not petData then
        warn("Pet not found: " .. petId)
        return false
    end
    
    local userId = tostring(player.UserId)
    
    -- Remove existing pet if any
    self:DespawnPet(player)
    
    -- Create pet model
    local petModel, bodyPosition, bodyVelocity, floatTween = self:CreatePetModel(petData, player)
    
    -- Position near player
    local playerPosition = player.Character.HumanoidRootPart.Position
    local spawnPosition = playerPosition + Vector3.new(math.random(-3, 3), 2, math.random(-3, 3))
    petModel:SetPrimaryPartCFrame(CFrame.new(spawnPosition))
    
    petModel.Parent = Workspace
    
    -- Start floating animation
    floatTween:Play()
    
    -- Setup following behavior
    local behaviorConnection = RunService.Heartbeat:Connect(function()
        self:UpdatePetBehavior(player, petModel, petData, bodyPosition, bodyVelocity)
    end)
    
    -- Store active pet data
    activePets[userId] = {
        petData = petData,
        petModel = petModel,
        bodyPosition = bodyPosition,
        bodyVelocity = bodyVelocity,
        floatTween = floatTween,
        behaviorConnection = behaviorConnection,
        lastReaction = 0
    }
    
    print("🐾 Spawned " .. petData.name .. " for " .. player.Name)
    return true
end

function PetService:DespawnPet(player)
    local userId = tostring(player.UserId)
    local activePet = activePets[userId]
    
    if activePet then
        -- Cleanup connections
        if activePet.behaviorConnection then
            activePet.behaviorConnection:Disconnect()
        end
        
        if activePet.floatTween then
            activePet.floatTween:Cancel()
        end
        
        -- Remove model
        if activePet.petModel and activePet.petModel.Parent then
            activePet.petModel:Destroy()
        end
        
        activePets[userId] = nil
        print("🐾 Despawned pet for " .. player.Name)
    end
end

function PetService:UpdatePetBehavior(player, petModel, petData, bodyPosition, bodyVelocity)
    if not player.Character or not player.Character:FindFirstChild("HumanoidRootPart") or not petModel.PrimaryPart then
        return
    end
    
    local playerPosition = player.Character.HumanoidRootPart.Position
    local petPosition = petModel.PrimaryPart.Position
    
    -- Calculate follow position
    local direction = (playerPosition - petPosition)
    direction = Vector3.new(direction.X, 0, direction.Z).Unit
    local followPosition = playerPosition - direction * petData.followDistance
    followPosition = followPosition + Vector3.new(0, 3, 0) -- Float above ground
    
    -- Smooth following
    local distance = (followPosition - petPosition).Magnitude
    if distance > petData.followDistance * 1.5 then
        -- Pet is too far, move quickly
        bodyPosition.Position = followPosition
        bodyVelocity.Velocity = direction * 16
    elseif distance > petData.followDistance * 0.8 then
        -- Pet should follow normally
        bodyPosition.Position = followPosition
        bodyVelocity.Velocity = direction * 8
    else
        -- Pet is close enough, slow down
        bodyVelocity.Velocity = Vector3.new(0, 0, 0)
    end
    
    -- Face the player
    if distance > 1 then
        local lookDirection = (playerPosition - petPosition).Unit
        local newCFrame = CFrame.lookAt(petPosition, petPosition + lookDirection)
        petModel:SetPrimaryPartCFrame(newCFrame)
    end
end

function PetService:TriggerPetReaction(player, reactionType, extraData)
    local userId = tostring(player.UserId)
    local activePet = activePets[userId]
    
    if not activePet or not activePet.petModel or not activePet.petModel.PrimaryPart then
        return
    end
    
    local petData = activePet.petData
    local petModel = activePet.petModel
    local currentTime = tick()
    
    -- Rate limit reactions
    if currentTime - activePet.lastReaction < 0.3 then
        return
    end
    activePet.lastReaction = currentTime
    
    -- Get reaction animation
    local reaction = petData.reactions[reactionType]
    if not reaction then return end
    
    local body = petModel:FindFirstChild("Body")
    if not body then return end
    
    local originalPosition = body.Position
    local originalColor = body.Color
    local glowIntensity = petData.glowIntensity or 1
    
    -- Enhanced reactions based on rarity and type
    if reaction == "hop_excited" or reaction == "happy_buzz" or reaction == "ice_slide" then
        -- Basic hop animation
        local hopHeight = 2 + glowIntensity
        local hopTween = TweenService:Create(
            body,
            TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
            {Position = originalPosition + Vector3.new(0, hopHeight, 0)}
        )
        hopTween:Play()
        hopTween.Completed:Connect(function()
            local fallTween = TweenService:Create(
                body,
                TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
                {Position = originalPosition}
            )
            fallTween:Play()
        end)
        
    elseif reaction == "lightning_dance" or reaction == "electric_spark" or reaction == "thunder_hoot" then
        -- Electric/Lightning effects
        local flashColor = Color3.new(1, 1, 0.8) -- Bright electric
        
        -- Multiple rapid flashes
        for i = 1, 5 do
            spawn(function()
                wait(i * 0.1)
                local flashTween = TweenService:Create(
                    body,
                    TweenInfo.new(0.1, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut),
                    {Color = flashColor, Size = petData.size * 1.2}
                )
                flashTween:Play()
                flashTween.Completed:Connect(function()
                    local resetTween = TweenService:Create(
                        body,
                        TweenInfo.new(0.1, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut),
                        {Color = originalColor, Size = petData.size}
                    )
                    resetTween:Play()
                end)
            end)
        end
        
        -- Create sparkle effects
        for i = 1, glowIntensity * 3 do
            spawn(function()
                local sparkle = Instance.new("Part")
                sparkle.Size = Vector3.new(0.2, 0.2, 0.2)
                sparkle.Material = Enum.Material.Neon
                sparkle.Color = flashColor
                sparkle.Shape = Enum.PartType.Ball
                sparkle.CanCollide = false
                sparkle.Anchored = true
                sparkle.Position = originalPosition + Vector3.new(
                    math.random(-3, 3),
                    math.random(-2, 2),
                    math.random(-3, 3)
                )
                sparkle.Parent = Workspace
                
                -- Animate sparkle
                local sparkleTween = TweenService:Create(
                    sparkle,
                    TweenInfo.new(1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
                    {
                        Transparency = 1,
                        Size = Vector3.new(0.5, 0.5, 0.5),
                        Position = sparkle.Position + Vector3.new(0, 3, 0)
                    }
                )
                sparkleTween:Play()
                sparkleTween.Completed:Connect(function()
                    sparkle:Destroy()
                end)
            end)
        end
        
    elseif reaction == "golden_shimmer" or reaction == "gem_sparkle" or reaction == "crystal_glow" then
        -- Shimmer/Glow effects
        local shimmerColor = petData.rarity == "Mythic" and Color3.new(1, 1, 1) or Color3.new(1, 0.8, 0.2)
        
        -- Pulsing glow
        local glowTween = TweenService:Create(
            body,
            TweenInfo.new(0.5, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, 3, true),
            {Color = shimmerColor, Size = petData.size * 1.3}
        )
        glowTween:Play()
        
        -- Add shimmer particles
        for i = 1, glowIntensity * 5 do
            spawn(function()
                wait(i * 0.05)
                local particle = Instance.new("Part")
                particle.Size = Vector3.new(0.1, 0.1, 0.1)
                particle.Material = Enum.Material.Neon
                particle.Color = shimmerColor
                particle.Shape = Enum.PartType.Ball
                particle.CanCollide = false
                particle.Anchored = true
                particle.Position = originalPosition + Vector3.new(
                    math.random(-2, 2),
                    math.random(-1, 3),
                    math.random(-2, 2)
                )
                particle.Parent = Workspace
                
                local particleTween = TweenService:Create(
                    particle,
                    TweenInfo.new(2, Enum.EasingStyle.Sine, Enum.EasingDirection.Out),
                    {Transparency = 1, Position = particle.Position + Vector3.new(0, 5, 0)}
                )
                particleTween:Play()
                particleTween.Completed:Connect(function()
                    particle:Destroy()
                end)
            end)
        end
        
    elseif reaction == "rainbow_trail" or reaction == "prism_shine" or reaction == "rainbow_nova" then
        -- Rainbow effects
        local rainbowColors = {
            Color3.new(1, 0, 0), -- Red
            Color3.new(1, 0.5, 0), -- Orange
            Color3.new(1, 1, 0), -- Yellow
            Color3.new(0, 1, 0), -- Green
            Color3.new(0, 0, 1), -- Blue
            Color3.new(0.5, 0, 1), -- Indigo
            Color3.new(1, 0, 1) -- Violet
        }
        
        -- Cycle through rainbow colors
        for i, color in pairs(rainbowColors) do
            spawn(function()
                wait(i * 0.1)
                local colorTween = TweenService:Create(
                    body,
                    TweenInfo.new(0.2, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut),
                    {Color = color}
                )
                colorTween:Play()
                
                if i == #rainbowColors then
                    colorTween.Completed:Connect(function()
                        local resetTween = TweenService:Create(
                            body,
                            TweenInfo.new(0.3, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut),
                            {Color = originalColor}
                        )
                        resetTween:Play()
                    end)
                end
            end)
        end
        
    elseif reaction == "crystal_burst" or reaction == "supernova" or reaction == "cosmic_blessing" then
        -- Epic burst effects
        local burstSize = glowIntensity * 2
        
        -- Main burst
        local burstTween = TweenService:Create(
            body,
            TweenInfo.new(0.5, Enum.EasingStyle.Quart, Enum.EasingDirection.Out),
            {Size = petData.size * burstSize, Transparency = 0.3}
        )
        burstTween:Play()
        burstTween.Completed:Connect(function()
            local shrinkTween = TweenService:Create(
                body,
                TweenInfo.new(0.3, Enum.EasingStyle.Quart, Enum.EasingDirection.In),
                {Size = petData.size, Transparency = 0}
            )
            shrinkTween:Play()
        end)
        
        -- Shockwave effect
        local shockwave = Instance.new("Part")
        shockwave.Size = Vector3.new(1, 0.5, 1)
        shockwave.Material = Enum.Material.ForceField
        shockwave.Color = body.Color
        shockwave.Shape = Enum.PartType.Cylinder
        shockwave.CanCollide = false
        shockwave.Anchored = true
        shockwave.Transparency = 0.5
        shockwave.Position = originalPosition
        shockwave.Parent = Workspace
        
        local shockwaveTween = TweenService:Create(
            shockwave,
            TweenInfo.new(1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
            {
                Size = Vector3.new(burstSize * 10, 0.5, burstSize * 10),
                Transparency = 1
            }
        )
        shockwaveTween:Play()
        shockwaveTween.Completed:Connect(function()
            shockwave:Destroy()
        end)
        
    elseif reaction == "phoenix_rebirth" or reaction == "reality_rewrite" or reaction == "creation_burst" then
        -- Mythic-tier reality-bending effects
        
        -- Phase out
        local fadeOutTween = TweenService:Create(
            body,
            TweenInfo.new(0.5, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut),
            {Transparency = 1, Size = Vector3.new(0.1, 0.1, 0.1)}
        )
        fadeOutTween:Play()
        
        fadeOutTween.Completed:Connect(function()
            -- Reality distortion
            for i = 1, 20 do
                spawn(function()
                    local orb = Instance.new("Part")
                    orb.Size = Vector3.new(0.5, 0.5, 0.5)
                    orb.Material = Enum.Material.ForceField
                    orb.Color = Color3.new(math.random(), math.random(), math.random())
                    orb.Shape = Enum.PartType.Ball
                    orb.CanCollide = false
                    orb.Anchored = true
                    orb.Position = originalPosition + Vector3.new(
                        math.random(-10, 10),
                        math.random(-5, 5),
                        math.random(-10, 10)
                    )
                    orb.Parent = Workspace
                    
                    local orbTween = TweenService:Create(
                        orb,
                        TweenInfo.new(2, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut),
                        {
                            Position = originalPosition,
                            Transparency = 1,
                            Size = Vector3.new(2, 2, 2)
                        }
                    )
                    orbTween:Play()
                    orbTween.Completed:Connect(function()
                        orb:Destroy()
                    end)
                end)
            end
            
            -- Phase back in with enhanced effects
            wait(1)
            local fadeInTween = TweenService:Create(
                body,
                TweenInfo.new(0.5, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut),
                {Transparency = 0, Size = petData.size * 1.5}
            )
            fadeInTween:Play()
            
            fadeInTween.Completed:Connect(function()
                local normalTween = TweenService:Create(
                    body,
                    TweenInfo.new(0.3, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut),
                    {Size = petData.size}
                )
                normalTween:Play()
            end)
        end)
        
    elseif reaction == "sad_ears" or reaction == "disappointed_meow" or reaction == "worried_cry" or reaction == "slime_deflate" then
        -- Sad reactions
        local sadTween = TweenService:Create(
            body,
            TweenInfo.new(0.8, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
            {
                Position = originalPosition - Vector3.new(0, 1, 0),
                Size = petData.size * 0.8,
                Color = Color3.new(0.5, 0.5, 0.7) -- Sad blue tint
            }
        )
        sadTween:Play()
        
        -- Return to normal after a moment
        sadTween.Completed:Connect(function()
            wait(1)
            local recoverTween = TweenService:Create(
                body,
                TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
                {
                    Position = originalPosition,
                    Size = petData.size,
                    Color = originalColor
                }
            )
            recoverTween:Play()
        end)
    end
    
    print("🐾 " .. petData.name .. " (" .. petData.rarity .. ") reacted with: " .. reaction)
end

function PetService:ApplyPetPassive(player, passiveType, gameData)
    local userId = tostring(player.UserId)
    local activePet = activePets[userId]
    
    if not activePet then return gameData end
    
    local petData = activePet.petData
    local passive = petData.passive
    
    if passive.type == passiveType then
        if passiveType == "coin_bonus" and gameData.isPerfectStreak then
            gameData.bonusCoins = (gameData.bonusCoins or 0) + passive.value
            print("🐾 " .. petData.name .. " gave +" .. passive.value .. " bonus coins!")
            
        elseif passiveType == "speed_bonus" then
            gameData.speedMultiplier = (gameData.speedMultiplier or 1) + passive.value
            
        elseif passiveType == "streak_multiplier" and gameData.comboCount >= 5 then
            gameData.scoreMultiplier = (gameData.scoreMultiplier or 1) + passive.value
            
        elseif passiveType == "experience_boost" then
            gameData.xpMultiplier = (gameData.xpMultiplier or 1) + passive.value
            
        elseif passiveType == "double_rewards" and gameData.isPerfectGame then
            gameData.coinMultiplier = (gameData.coinMultiplier or 1) + passive.value
            gameData.xpMultiplier = (gameData.xpMultiplier or 1) + passive.value
        end
    end
    
    return gameData
end

function PetService:LoadPlayerPets(player)
    local userId = tostring(player.UserId)
    
    local success, data = pcall(function()
        return petDataStore:GetAsync(userId) or {}
    end)
    
    if not success then
        warn("Failed to load pet data for " .. player.Name)
        data = {}
    end
    
    -- Ensure data structure
    data.ownedPets = data.ownedPets or {}
    data.activePet = data.activePet or nil
    data.petStats = data.petStats or {}
    
    print("🐾 Loaded pet data for " .. player.Name .. " (" .. #data.ownedPets .. " pets owned)")
    return data
end

function PetService:SavePlayerPets(player, data)
    local userId = tostring(player.UserId)
    
    local success = pcall(function()
        petDataStore:SetAsync(userId, data)
    end)
    
    if not success then
        warn("Failed to save pet data for " .. player.Name)
    end
end

function PetService:PurchasePet(player, petId)
    local petData = nil
    for _, pet in pairs(PET_DATABASE) do
        if pet.id == petId then
            petData = pet
            break
        end
    end
    
    if not petData then
        return false, "Pet not found"
    end
    
    local playerData = PlayerService:GetPlayerData(player)
    local petPlayerData = self:LoadPlayerPets(player)
    
    -- Check if already owned
    for _, ownedPetId in pairs(petPlayerData.ownedPets) do
        if ownedPetId == petId then
            return false, "Already owned"
        end
    end
    
    -- Check currency
    if petData.currency == "coins" then
        if playerData.coins < petData.price then
            return false, "Insufficient coins"
        end
        playerData.coins = playerData.coins - petData.price
        PlayerService:UpdatePlayerData(player, playerData)
        
    elseif petData.currency == "robux" then
        -- In a real game, you'd handle Robux purchases through Roblox APIs
        -- For now, we'll simulate this
        return false, "Robux purchases not implemented in demo"
    end
    
    -- Add to owned pets
    table.insert(petPlayerData.ownedPets, petId)
    
    -- Track quest progress
    if QuestService then
        QuestService:UpdateQuestProgress(player, "pet_purchased", 1)
        QuestService:UpdateQuestProgress(player, "pets_owned", #petPlayerData.ownedPets)
        
        -- Check for rare pet purchase
        if petData.rarity ~= "Common" then
            QuestService:UpdateQuestProgress(player, "rare_pet_purchased", 1, {rarity = petData.rarity})
        end
    end
    
    -- Set as active if first pet
    if #petPlayerData.ownedPets == 1 then
        petPlayerData.activePet = petId
        self:SpawnPet(player, petId)
    end
    
    -- Save data
    self:SavePlayerPets(player, petPlayerData)
    
    print("🐾 " .. player.Name .. " purchased " .. petData.name)
    return true, "Purchase successful"
end

function PetService:AwardMysteryPet(player, minRarity)
    -- Award a random pet from mystery crate with guaranteed minimum rarity
    minRarity = minRarity or "epic" -- Default to epic+ guarantee
    
    -- Get pets of appropriate rarity
    local eligiblePets = {}
    local rarityOrder = {"common", "uncommon", "rare", "epic", "legendary", "mythic"}
    local minRarityIndex = 4 -- epic by default
    
    for i, rarity in ipairs(rarityOrder) do
        if string.lower(rarity) == string.lower(minRarity) then
            minRarityIndex = i
            break
        end
    end
    
    -- Collect pets that meet rarity requirement
    for _, pet in pairs(PET_DATABASE) do
        local petRarityIndex = 1
        for i, rarity in ipairs(rarityOrder) do
            if string.lower(pet.rarity) == string.lower(rarity) then
                petRarityIndex = i
                break
            end
        end
        
        if petRarityIndex >= minRarityIndex then
            table.insert(eligiblePets, pet)
        end
    end
    
    if #eligiblePets == 0 then
        warn("❌ No eligible pets found for mystery crate with rarity: " .. minRarity)
        return nil
    end
    
    -- Select random pet
    local selectedPet = eligiblePets[math.random(1, #eligiblePets)]
    
    -- Get player pet data
    local petPlayerData = self:LoadPlayerPets(player)
    
    -- Add to owned pets if not already owned
    local alreadyOwned = false
    for _, ownedPetId in pairs(petPlayerData.ownedPets) do
        if ownedPetId == selectedPet.id then
            alreadyOwned = true
            break
        end
    end
    
    if not alreadyOwned then
        table.insert(petPlayerData.ownedPets, selectedPet.id)
        
        -- Set as active if first pet
        if #petPlayerData.ownedPets == 1 then
            petPlayerData.activePet = selectedPet.id
            self:SpawnPet(player, selectedPet.id)
        end
        
        -- Track quest progress
        if QuestService then
            QuestService:UpdateQuestProgress(player, "pet_purchased", 1)
            QuestService:UpdateQuestProgress(player, "pets_owned", #petPlayerData.ownedPets)
            QuestService:UpdateQuestProgress(player, "rare_pet_purchased", 1, {rarity = selectedPet.rarity})
            QuestService:UpdateQuestProgress(player, "mystery_crate_opened", 1)
        end
        
        -- Save data
        self:SavePlayerPets(player, petPlayerData)
        
        print("🎁 " .. player.Name .. " received " .. selectedPet.name .. " (" .. selectedPet.rarity .. ") from mystery crate!")
        
        return {
            id = selectedPet.id,
            name = selectedPet.name,
            rarity = selectedPet.rarity,
            description = selectedPet.description,
            isNew = true
        }
    else
        -- Pet already owned, give compensation (coins or pet level up)
        local playerData = PlayerService:GetPlayerData(player)
        local compensationCoins = 500 -- Base compensation
        
        -- Higher compensation for rarer pets
        if selectedPet.rarity == "Legendary" then
            compensationCoins = 2000
        elseif selectedPet.rarity == "Epic" then
            compensationCoins = 1000
        end
        
        playerData.coins = playerData.coins + compensationCoins
        PlayerService:UpdatePlayerData(player, playerData)
        
        print("🎁 " .. player.Name .. " got duplicate " .. selectedPet.name .. ", received " .. compensationCoins .. " coins compensation")
        
        return {
            id = selectedPet.id,
            name = selectedPet.name,
            rarity = selectedPet.rarity,
            description = selectedPet.description,
            isNew = false,
            compensation = compensationCoins
        }
    end
end

function PetService:EquipPet(player, petId)
    local petPlayerData = self:LoadPlayerPets(player)
    
    -- Check if owned
    local isOwned = false
    for _, ownedPetId in pairs(petPlayerData.ownedPets) do
        if ownedPetId == petId then
            isOwned = true
            break
        end
    end
    
    if not isOwned and petId ~= nil then
        return false, "Pet not owned"
    end
    
    -- Update active pet
    petPlayerData.activePet = petId
    self:SavePlayerPets(player, petPlayerData)
    
    -- Spawn/despawn pet
    if petId then
        self:SpawnPet(player, petId)
    else
        self:DespawnPet(player)
    end
    
    print("🐾 " .. player.Name .. " equipped pet: " .. (petId or "none"))
    return true, "Pet equipped"
end

function PetService:GetPlayerPetData(player)
    return self:LoadPlayerPets(player)
end

function PetService:GetPetDatabase()
    return PET_DATABASE
end

function PetService:SetupPetVendor()
    -- Find pet vendor in the hub
    local petVendor = Workspace.MarketPlaza:FindFirstChild("PetVendor")
    if not petVendor then
        -- Create pet vendor structure
        petVendor = Instance.new("Model")
        petVendor.Name = "PetVendor"
        petVendor.Parent = Workspace.MarketPlaza
        
        -- Vendor stand
        local stand = Instance.new("Part")
        stand.Name = "Stand"
        stand.Size = Vector3.new(6, 1, 6)
        stand.Position = Vector3.new(-15, 1, 25) -- Position in plaza
        stand.Anchored = true
        stand.Material = Enum.Material.Marble
        stand.Color = Color3.new(0.9, 0.7, 1) -- Light purple
        stand.Parent = petVendor
        
        -- Vendor NPC
        local npc = Instance.new("Part")
        npc.Name = "NPC"
        npc.Size = Vector3.new(2, 6, 2)
        npc.Position = stand.Position + Vector3.new(0, 4, 0)
        npc.Anchored = true
        npc.Material = Enum.Material.Neon
        npc.Color = Color3.new(0.8, 0.6, 1)
        npc.Shape = Enum.PartType.Cylinder
        npc.Parent = petVendor
        
        -- Click detector
        local clickDetector = Instance.new("ClickDetector")
        clickDetector.MaxActivationDistance = 15
        clickDetector.Parent = npc
        
        print("🐾 Created pet vendor structure")
    end
    
    local clickDetector = petVendor.NPC:FindFirstChild("ClickDetector")
    if clickDetector then
        clickDetector.MouseClick:Connect(function(player)
            local petData = self:GetPlayerPetData(player)
            RemoteEvents.ShowPetShop:FireClient(player, PET_DATABASE, petData)
        end)
        print("🐾 Pet vendor click detector connected")
    end
    
    -- Add floating title
    local npc = petVendor.NPC
    local billboardGui = Instance.new("BillboardGui")
    billboardGui.Size = UDim2.new(0, 300, 0, 60)
    billboardGui.StudsOffset = Vector3.new(0, 3, 0)
    billboardGui.Parent = npc
    
    local titleLabel = Instance.new("TextLabel")
    titleLabel.Size = UDim2.new(1, 0, 1, 0)
    titleLabel.BackgroundTransparency = 1
    titleLabel.Text = "🐾 PET VENDOR"
    titleLabel.TextColor3 = Color3.new(0.8, 0.6, 1)
    titleLabel.TextScaled = true
    titleLabel.Font = Enum.Font.SourceSansBold
    titleLabel.TextStrokeTransparency = 0
    titleLabel.TextStrokeColor3 = Color3.new(0, 0, 0)
    titleLabel.Parent = billboardGui
    
    -- Add floating animation
    local floatTween = TweenService:Create(
        billboardGui,
        TweenInfo.new(3, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true),
        {StudsOffset = Vector3.new(0, 4, 0)}
    )
    floatTween:Play()
end

function PetService:Initialize()
    print("🐾 PetService initializing...")
    
    -- Validate pet-related world objects
    print("🔍 Validating pet world objects...")
    local missingObjects = WorldObjectValidator.validateAllRequired()
    if #missingObjects > 0 then
        warn("⚠️ PetService: Missing required world objects:")
        for _, missing in ipairs(missingObjects) do
            warn("  • " .. missing)
        end
    end
    
    -- Validate pet hatcher locations
    local petHatchersExists = WorldObjectValidator.validateObjectWithWait("workspace.PetHatchers", 3)
    if not petHatchersExists then
        warn("⚠️ PetService: PetHatchers folder not found")
        -- Try to create it
        WorldObjectValidator.createObjectIfMissing("workspace.PetHatchers", "Folder", "workspace")
    else
        print("✅ PetService: PetHatchers folder validated")
    end
    
    -- Validate marketplace for pet vendor
    local marketExists = WorldObjectValidator.validateObjectWithWait("workspace.MarketPlaza", 3)
    if not marketExists then
        warn("⚠️ PetService: MarketPlaza not found - pet vendor may not work")
    else
        print("✅ PetService: MarketPlaza validated for pet vendor")
    end
    
    -- Wait for workspace to be ready
    wait(1)
    
    -- Setup pet vendor
    self:SetupPetVendor()
    
    print("✅ PetService initialized successfully!")
end

-- Handle player joining
local function onPlayerAdded(player)
    spawn(function()
        wait(3) -- Wait for player to fully load
        
        local petData = PetService:LoadPlayerPets(player)
        if petData.activePet then
            -- Spawn their active pet
            PetService:SpawnPet(player, petData.activePet)
        end
    end)
end

-- Handle player leaving
local function onPlayerRemoving(player)
    PetService:DespawnPet(player)
end

-- Connect events
Players.PlayerAdded:Connect(onPlayerAdded)
Players.PlayerRemoving:Connect(onPlayerRemoving)

-- Remote event handlers
RemoteEvents.PurchasePet.OnServerEvent:Connect(function(player, petId)
    local success, message = PetService:PurchasePet(player, petId)
    RemoteEvents.PetPurchaseResult:FireClient(player, success, message, petId)
end)

RemoteEvents.EquipPet.OnServerEvent:Connect(function(player, petId)
    local success, message = PetService:EquipPet(player, petId)
    RemoteEvents.PetEquipResult:FireClient(player, success, message, petId)
end)

-- Auto-initialize when required
PetService:Initialize()

return PetService
