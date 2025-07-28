-- TrophyService.luau
-- Manages trophy hall with physical badge displays and achievements

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local TweenService = game:GetService("TweenService")
local DataStoreService = game:GetService("DataStoreService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local PlayerService = require(script.Parent.PlayerService)
local RemoteEvents = require(ReplicatedStorage.Shared.modules.RemoteEvents)

-- Service references (set via setters)
local QuestService = nil

local TrophyService = {}

-- DataStore for trophy progress
local trophyDataStore = DataStoreService:GetDataStore("TrophyProgress")

-- Trophy/Badge definitions
local TROPHY_BADGES = {
    -- Score Achievements
    {
        id = "score_100",
        name = "🏅 Century Scorer",
        description = "Achieve a score of 100 in a single game",
        category = "Performance",
        requirement = {type = "high_score", amount = 100},
        rarity = "Bronze",
        trophyModel = "BronzeTrophy",
        color = Color3.fromRGB(205, 127, 50),
        unlockSound = "achievement_bronze"
    },
    {
        id = "score_250",
        name = "🥈 Silver Champion",
        description = "Score 250 points in one amazing run",
        category = "Performance",
        requirement = {type = "high_score", amount = 250},
        rarity = "Silver",
        trophyModel = "SilverTrophy",
        color = Color3.fromRGB(192, 192, 192),
        unlockSound = "achievement_silver"
    },
    {
        id = "score_500",
        name = "🥇 Golden Legend",
        description = "Reach the legendary 500 point milestone",
        category = "Performance",
        requirement = {type = "high_score", amount = 500},
        rarity = "Gold",
        trophyModel = "GoldTrophy",
        color = Color3.fromRGB(255, 215, 0),
        unlockSound = "achievement_gold"
    },
    {
        id = "score_1000",
        name = "💎 Diamond Master",
        description = "Achieve the ultimate 1000 point score",
        category = "Performance",
        requirement = {type = "high_score", amount = 1000},
        rarity = "Diamond",
        trophyModel = "DiamondTrophy",
        color = Color3.fromRGB(185, 242, 255),
        unlockSound = "achievement_diamond"
    },
    
    -- Streak & Dedication Achievements
    {
        id = "play_3_days",
        name = "🗓️ Weekend Warrior",
        description = "Play for 3 consecutive days",
        category = "Dedication",
        requirement = {type = "login_streak", amount = 3},
        rarity = "Bronze",
        trophyModel = "CalendarTrophy",
        color = Color3.fromRGB(139, 69, 19),
        unlockSound = "achievement_bronze"
    },
    {
        id = "play_7_days",
        name = "📅 Weekly Champion",
        description = "Maintain a 7-day login streak",
        category = "Dedication",
        requirement = {type = "login_streak", amount = 7},
        rarity = "Silver",
        trophyModel = "CalendarTrophy",
        color = Color3.fromRGB(192, 192, 192),
        unlockSound = "achievement_silver"
    },
    {
        id = "play_30_days",
        name = "📆 Monthly Legend",
        description = "Play for an entire month straight",
        category = "Dedication",
        requirement = {type = "login_streak", amount = 30},
        rarity = "Gold",
        trophyModel = "CalendarTrophy",
        color = Color3.fromRGB(255, 215, 0),
        unlockSound = "achievement_gold"
    },
    
    -- Racing & Competition Achievements
    {
        id = "ghost_victory_1",
        name = "👻 Ghost Buster",
        description = "Win your first ghost race",
        category = "Racing",
        requirement = {type = "ghost_victories", amount = 1},
        rarity = "Bronze",
        trophyModel = "RaceTrophy",
        color = Color3.fromRGB(138, 43, 226),
        unlockSound = "achievement_bronze"
    },
    {
        id = "ghost_victory_10",
        name = "👻 Phantom Racer",
        description = "Win 10 ghost races",
        category = "Racing",
        requirement = {type = "ghost_victories", amount = 10},
        rarity = "Silver",
        trophyModel = "RaceTrophy",
        color = Color3.fromRGB(192, 192, 192),
        unlockSound = "achievement_silver"
    },
    {
        id = "ghost_victory_50",
        name = "👻 Spectral Champion",
        description = "Dominate with 50 ghost race wins",
        category = "Racing",
        requirement = {type = "ghost_victories", amount = 50},
        rarity = "Gold",
        trophyModel = "RaceTrophy",
        color = Color3.fromRGB(255, 215, 0),
        unlockSound = "achievement_gold"
    },
    
    -- Collection & Exploration Achievements
    {
        id = "coins_10k",
        name = "💰 Coin Collector",
        description = "Collect 10,000 total coins",
        category = "Collection",
        requirement = {type = "total_coins", amount = 10000},
        rarity = "Bronze",
        trophyModel = "CoinTrophy",
        color = Color3.fromRGB(255, 215, 0),
        unlockSound = "achievement_bronze"
    },
    {
        id = "coins_50k",
        name = "💎 Treasure Hunter",
        description = "Amass 50,000 coins",
        category = "Collection",
        requirement = {type = "total_coins", amount = 50000},
        rarity = "Silver",
        trophyModel = "CoinTrophy",
        color = Color3.fromRGB(192, 192, 192),
        unlockSound = "achievement_silver"
    },
    {
        id = "coins_100k",
        name = "👑 Coin Royalty",
        description = "Reach the ultimate 100,000 coins",
        category = "Collection",
        requirement = {type = "total_coins", amount = 100000},
        rarity = "Gold",
        trophyModel = "CoinTrophy",
        color = Color3.fromRGB(255, 215, 0),
        unlockSound = "achievement_gold"
    },
    {
        id = "puzzle_master",
        name = "🧩 Puzzle Master",
        description = "Complete 5 weekly puzzle challenges",
        category = "Collection",
        requirement = {type = "puzzles_completed", amount = 5},
        rarity = "Silver",
        trophyModel = "PuzzleTrophy",
        color = Color3.fromRGB(138, 43, 226),
        unlockSound = "achievement_silver"
    },
    
    -- Perfection & Skill Achievements
    {
        id = "perfect_10",
        name = "🎯 Perfectionist",
        description = "Complete 10 perfect games",
        category = "Skill",
        requirement = {type = "perfect_games", amount = 10},
        rarity = "Silver",
        trophyModel = "StarTrophy",
        color = Color3.fromRGB(255, 255, 0),
        unlockSound = "achievement_silver"
    },
    {
        id = "perfect_50",
        name = "⭐ Flawless Legend",
        description = "Achieve 50 perfect games",
        category = "Skill",
        requirement = {type = "perfect_games", amount = 50},
        rarity = "Gold",
        trophyModel = "StarTrophy",
        color = Color3.fromRGB(255, 215, 0),
        unlockSound = "achievement_gold"
    },
    {
        id = "combo_100",
        name = "🔥 Combo King",
        description = "Achieve a 100-barrier combo",
        category = "Skill",
        requirement = {type = "max_combo", amount = 100},
        rarity = "Gold",
        trophyModel = "FlameTrophy",
        color = Color3.fromRGB(255, 69, 0),
        unlockSound = "achievement_gold"
    },
    
    -- Social & Event Achievements
    {
        id = "event_participant",
        name = "🌟 Event Explorer",
        description = "Participate in 10 world events",
        category = "Social",
        requirement = {type = "events_participated", amount = 10},
        rarity = "Bronze",
        trophyModel = "EventTrophy",
        color = Color3.fromRGB(255, 20, 147),
        unlockSound = "achievement_bronze"
    },
    {
        id = "event_champion",
        name = "🏆 Event Champion",
        description = "Win 5 world events",
        category = "Social",
        requirement = {type = "events_won", amount = 5},
        rarity = "Gold",
        trophyModel = "EventTrophy",
        color = Color3.fromRGB(255, 215, 0),
        unlockSound = "achievement_gold"
    },
    {
        id = "social_butterfly",
        name = "🦋 Social Butterfly",
        description = "Share your scores 25 times",
        category = "Social",
        requirement = {type = "scores_shared", amount = 25},
        rarity = "Silver",
        trophyModel = "ShareTrophy",
        color = Color3.fromRGB(255, 105, 180),
        unlockSound = "achievement_silver"
    }
}

-- Player trophy progress tracking
local playerTrophyProgress = {}
local playerUnlockedTrophies = {}

function TrophyService:Init()
    print("🏆 TrophyService: Initializing...")
    
    -- Set up remote events
    self:_setupRemoteEvents()
    
    -- Initialize trophy hall
    self:_initializeTrophyHall()
    
    -- Handle player connections
    Players.PlayerAdded:Connect(function(player)
        self:_onPlayerAdded(player)
    end)
    
    Players.PlayerRemoving:Connect(function(player)
        self:_onPlayerRemoving(player)
    end)
    
    print("✅ TrophyService: Initialized successfully!")
end

function TrophyService:_setupRemoteEvents()
    -- Create remote events if they don't exist
    if not RemoteEvents.TrophyUnlocked then
        RemoteEvents.TrophyUnlocked = Instance.new("RemoteEvent")
        RemoteEvents.TrophyUnlocked.Name = "TrophyUnlocked"
        RemoteEvents.TrophyUnlocked.Parent = game.ReplicatedStorage
    end
    
    if not RemoteEvents.RequestTrophyData then
        RemoteEvents.RequestTrophyData = Instance.new("RemoteEvent")
        RemoteEvents.RequestTrophyData.Name = "RequestTrophyData"
        RemoteEvents.RequestTrophyData.Parent = game.ReplicatedStorage
    end
    
    if not RemoteEvents.TrophyDataUpdate then
        RemoteEvents.TrophyDataUpdate = Instance.new("RemoteEvent")
        RemoteEvents.TrophyDataUpdate.Name = "TrophyDataUpdate"
        RemoteEvents.TrophyDataUpdate.Parent = game.ReplicatedStorage
    end
    
    if not RemoteEvents.ViewTrophyHall then
        RemoteEvents.ViewTrophyHall = Instance.new("RemoteEvent")
        RemoteEvents.ViewTrophyHall.Name = "ViewTrophyHall"
        RemoteEvents.ViewTrophyHall.Parent = game.ReplicatedStorage
    end
    
    -- Connect remote events
    RemoteEvents.RequestTrophyData.OnServerEvent:Connect(function(player)
        self:_sendTrophyDataToPlayer(player)
    end)
    
    RemoteEvents.ViewTrophyHall.OnServerEvent:Connect(function(player)
        self:_openTrophyHall(player)
    end)
end

function TrophyService:_initializeTrophyHall()
    local hubModel = workspace:FindFirstChild("Hub")
    if not hubModel then
        warn("⚠️ TrophyService: Hub not found, creating placeholder")
        hubModel = Instance.new("Model")
        hubModel.Name = "Hub"
        hubModel.Parent = workspace
    end
    
    -- Create trophy hall building
    local trophyHall = hubModel:FindFirstChild("TrophyHall")
    if trophyHall then
        trophyHall:Destroy()
    end
    
    trophyHall = Instance.new("Model")
    trophyHall.Name = "TrophyHall"
    trophyHall.Parent = hubModel
    
    -- Create the hall structure
    self:_createTrophyHallStructure(trophyHall)
    
    -- Create trophy shelves
    self:_createTrophyShelves(trophyHall)
    
    -- Add entrance portal
    self:_createHallEntrance(trophyHall)
end

function TrophyService:_createTrophyHallStructure(parent)
    -- Create main hall building
    local hallBase = Instance.new("Part")
    hallBase.Name = "HallBase"
    hallBase.Size = Vector3.new(60, 2, 40)
    hallBase.Position = Vector3.new(0, 1, -150) -- Position away from main hub
    hallBase.Anchored = true
    hallBase.BrickColor = BrickColor.new("Dark stone grey")
    hallBase.Material = Enum.Material.Marble
    hallBase.Parent = parent
    
    -- Create walls
    local walls = {
        {size = Vector3.new(60, 20, 2), position = Vector3.new(0, 11, -170)}, -- Back wall
        {size = Vector3.new(60, 20, 2), position = Vector3.new(0, 11, -130)}, -- Front wall
        {size = Vector3.new(2, 20, 40), position = Vector3.new(-30, 11, -150)}, -- Left wall
        {size = Vector3.new(2, 20, 40), position = Vector3.new(30, 11, -150)}   -- Right wall
    }
    
    for i, wallData in ipairs(walls) do
        local wall = Instance.new("Part")
        wall.Name = "Wall" .. i
        wall.Size = wallData.size
        wall.Position = wallData.position
        wall.Anchored = true
        wall.BrickColor = BrickColor.new("Light stone grey")
        wall.Material = Enum.Material.Marble
        wall.Parent = parent
        
        -- Add decorative elements
        if i <= 2 then -- Front and back walls
            self:_addWallDecorations(wall)
        end
    end
    
    -- Create ceiling
    local ceiling = Instance.new("Part")
    ceiling.Name = "Ceiling"
    ceiling.Size = Vector3.new(60, 2, 40)
    ceiling.Position = Vector3.new(0, 21, -150)
    ceiling.Anchored = true
    ceiling.BrickColor = BrickColor.new("Light stone grey")
    ceiling.Material = Enum.Material.Marble
    ceiling.Parent = parent
    
    -- Add chandeliers
    self:_createChandeliers(ceiling)
end

function TrophyService:_addWallDecorations(wall)
    -- Add golden trim
    local trim = Instance.new("Part")
    trim.Size = Vector3.new(wall.Size.X * 0.9, 1, 0.5)
    trim.Position = wall.Position + Vector3.new(0, wall.Size.Y/2 - 2, wall.CFrame.LookVector.X * 1.5)
    trim.Anchored = true
    trim.BrickColor = BrickColor.new("Bright yellow")
    trim.Material = Enum.Material.Neon
    trim.Parent = wall.Parent
    
    -- Add floating text for hall title
    if wall.Name == "Wall1" then -- Back wall
        local billboardGui = Instance.new("BillboardGui")
        billboardGui.Size = UDim2.new(0, 800, 0, 200)
        billboardGui.StudsOffset = Vector3.new(0, 5, 0)
        billboardGui.Parent = wall
        
        local titleLabel = Instance.new("TextLabel")
        titleLabel.Size = UDim2.new(1, 0, 1, 0)
        titleLabel.BackgroundTransparency = 1
        titleLabel.Text = "🏆 TROPHY HALL 🏆"
        titleLabel.TextColor3 = Color3.fromRGB(255, 215, 0)
        titleLabel.TextScaled = true
        titleLabel.Font = Enum.Font.SourceSansBold
        titleLabel.TextStrokeTransparency = 0
        titleLabel.TextStrokeColor3 = Color3.new(0, 0, 0)
        titleLabel.Parent = billboardGui
    end
end

function TrophyService:_createChandeliers(ceiling)
    local chandelier1 = self:_createChandelier(Vector3.new(-15, -3, -10))
    local chandelier2 = self:_createChandelier(Vector3.new(15, -3, -10))
    local chandelier3 = self:_createChandelier(Vector3.new(0, -3, 10))
    
    chandelier1.Parent = ceiling
    chandelier2.Parent = ceiling
    chandelier3.Parent = ceiling
end

function TrophyService:_createChandelier(offset)
    local chandelier = Instance.new("Model")
    chandelier.Name = "Chandelier"
    
    -- Center piece
    local center = Instance.new("Part")
    center.Name = "Center"
    center.Size = Vector3.new(2, 1, 2)
    center.Position = offset
    center.Anchored = true
    center.BrickColor = BrickColor.new("Bright yellow")
    center.Material = Enum.Material.Neon
    center.Shape = Enum.PartType.Ball
    center.Parent = chandelier
    
    -- Light effect
    local pointLight = Instance.new("PointLight")
    pointLight.Brightness = 3
    pointLight.Color = Color3.fromRGB(255, 255, 200)
    pointLight.Range = 25
    pointLight.Parent = center
    
    -- Floating animation
    local floatTween = TweenService:Create(
        chandelier,
        TweenInfo.new(4, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true),
        {}
    )
    
    spawn(function()
        while chandelier.Parent do
            for _, part in pairs(chandelier:GetChildren()) do
                if part:IsA("BasePart") then
                    part.Position = part.Position + Vector3.new(0, 0.5, 0)
                end
            end
            wait(2)
            for _, part in pairs(chandelier:GetChildren()) do
                if part:IsA("BasePart") then
                    part.Position = part.Position - Vector3.new(0, 0.5, 0)
                end
            end
            wait(2)
        end
    end)
    
    return chandelier
end

function TrophyService:_createTrophyShelves(parent)
    -- Create category-based shelves
    local categories = {"Performance", "Dedication", "Racing", "Collection", "Skill", "Social"}
    local shelfSpacing = 8
    
    for i, category in ipairs(categories) do
        local shelf = self:_createCategoryShelf(category, i, shelfSpacing)
        shelf.Parent = parent
    end
end

function TrophyService:_createCategoryShelf(category, index, spacing)
    local shelf = Instance.new("Model")
    shelf.Name = category .. "Shelf"
    
    -- Calculate position
    local xPos = -25 + ((index - 1) % 3) * 25
    local zPos = -165 + math.floor((index - 1) / 3) * 20
    
    -- Create shelf base
    local shelfBase = Instance.new("Part")
    shelfBase.Name = "ShelfBase"
    shelfBase.Size = Vector3.new(20, 1, 5)
    shelfBase.Position = Vector3.new(xPos, 5, zPos)
    shelfBase.Anchored = true
    shelfBase.BrickColor = BrickColor.new("Dark stone grey")
    shelfBase.Material = Enum.Material.Marble
    shelfBase.Parent = shelf
    
    -- Create shelf backing
    local backing = Instance.new("Part")
    backing.Name = "Backing"
    backing.Size = Vector3.new(20, 10, 1)
    backing.Position = Vector3.new(xPos, 10, zPos - 2.5)
    backing.Anchored = true
    backing.BrickColor = BrickColor.new("Light stone grey")
    backing.Material = Enum.Material.Marble
    backing.Parent = shelf
    
    -- Add category label
    local billboardGui = Instance.new("BillboardGui")
    billboardGui.Size = UDim2.new(0, 400, 0, 100)
    billboardGui.StudsOffset = Vector3.new(0, 8, 0)
    billboardGui.Parent = backing
    
    local categoryLabel = Instance.new("TextLabel")
    categoryLabel.Size = UDim2.new(1, 0, 1, 0)
    categoryLabel.BackgroundTransparency = 1
    categoryLabel.Text = category:upper()
    categoryLabel.TextColor3 = Color3.fromRGB(255, 215, 0)
    categoryLabel.TextScaled = true
    categoryLabel.Font = Enum.Font.SourceSansBold
    categoryLabel.TextStrokeTransparency = 0
    categoryLabel.TextStrokeColor3 = Color3.new(0, 0, 0)
    categoryLabel.Parent = billboardGui
    
    -- Create trophy spots
    self:_createTrophySpots(shelf, category, xPos, zPos)
    
    return shelf
end

function TrophyService:_createTrophySpots(shelf, category, xPos, zPos)
    local trophiesInCategory = {}
    
    -- Find trophies for this category
    for _, trophy in ipairs(TROPHY_BADGES) do
        if trophy.category == category then
            table.insert(trophiesInCategory, trophy)
        end
    end
    
    -- Create spots for each trophy
    for i, trophy in ipairs(trophiesInCategory) do
        local spotX = xPos - 8 + ((i - 1) * 4)
        local spotZ = zPos + 1
        
        self:_createTrophySpot(shelf, trophy, Vector3.new(spotX, 6, spotZ), i)
    end
end

function TrophyService:_createTrophySpot(parent, trophyData, position, index)
    local spot = Instance.new("Model")
    spot.Name = trophyData.id .. "_Spot"
    spot.Parent = parent
    
    -- Create base pedestal
    local pedestal = Instance.new("Part")
    pedestal.Name = "Pedestal"
    pedestal.Size = Vector3.new(2, 1, 2)
    pedestal.Position = position
    pedestal.Anchored = true
    pedestal.BrickColor = BrickColor.new("Dark stone grey")
    pedestal.Material = Enum.Material.Marble
    pedestal.Shape = Enum.PartType.Cylinder
    pedestal.Parent = spot
    
    -- Create placeholder (locked trophy)
    local placeholder = Instance.new("Part")
    placeholder.Name = "Placeholder"
    placeholder.Size = Vector3.new(1.5, 2, 1.5)
    placeholder.Position = position + Vector3.new(0, 2, 0)
    placeholder.Anchored = true
    placeholder.BrickColor = BrickColor.new("Really black")
    placeholder.Material = Enum.Material.Glass
    placeholder.Transparency = 0.7
    placeholder.Parent = spot
    
    -- Add question mark
    local billboardGui = Instance.new("BillboardGui")
    billboardGui.Size = UDim2.new(0, 100, 0, 100)
    billboardGui.Parent = placeholder
    
    local questionLabel = Instance.new("TextLabel")
    questionLabel.Size = UDim2.new(1, 0, 1, 0)
    questionLabel.BackgroundTransparency = 1
    questionLabel.Text = "?"
    questionLabel.TextColor3 = Color3.new(0.5, 0.5, 0.5)
    questionLabel.TextScaled = true
    questionLabel.Font = Enum.Font.SourceSansBold
    questionLabel.Parent = billboardGui
    
    -- Store trophy data in spot
    local objectValue = Instance.new("ObjectValue")
    objectValue.Name = "TrophyData"
    objectValue.Parent = spot
    
    local stringValue = Instance.new("StringValue")
    stringValue.Name = "TrophyId"
    stringValue.Value = trophyData.id
    stringValue.Parent = spot
end

function TrophyService:_createHallEntrance(parent)
    -- Create entrance portal in main hub
    local hubModel = workspace:FindFirstChild("Hub")
    if not hubModel then return end
    
    local entrance = Instance.new("Model")
    entrance.Name = "TrophyHallEntrance"
    entrance.Parent = hubModel
    
    -- Create portal arch
    local arch = Instance.new("Part")
    arch.Name = "PortalArch"
    arch.Size = Vector3.new(8, 12, 2)
    arch.Position = Vector3.new(-60, 6, 30) -- Position in hub
    arch.Anchored = true
    arch.BrickColor = BrickColor.new("Bright yellow")
    arch.Material = Enum.Material.Neon
    arch.Parent = entrance
    
    -- Add portal effect
    local portal = Instance.new("Part")
    portal.Name = "Portal"
    portal.Size = Vector3.new(6, 10, 0.5)
    portal.Position = arch.Position
    portal.Anchored = true
    portal.BrickColor = BrickColor.new("Bright blue")
    portal.Material = Enum.Material.ForceField
    portal.Transparency = 0.3
    portal.Parent = entrance
    
    -- Add swirling effect
    local attachment = Instance.new("Attachment")
    attachment.Parent = portal
    
    local particles = Instance.new("ParticleEmitter")
    particles.Texture = "rbxasset://textures/particles/sparkles_main.dds"
    particles.Lifetime = NumberRange.new(1, 3)
    particles.Rate = 50
    particles.SpreadAngle = Vector2.new(360, 360)
    particles.Speed = NumberRange.new(5, 10)
    particles.Color = ColorSequence.new(Color3.fromRGB(255, 215, 0))
    particles.Parent = attachment
    
    -- Add portal sign
    local billboardGui = Instance.new("BillboardGui")
    billboardGui.Size = UDim2.new(0, 300, 0, 100)
    billboardGui.StudsOffset = Vector3.new(0, 8, 0)
    billboardGui.Parent = arch
    
    local signLabel = Instance.new("TextLabel")
    signLabel.Size = UDim2.new(1, 0, 1, 0)
    signLabel.BackgroundTransparency = 1
    signLabel.Text = "🏆 TROPHY HALL 🏆"
    signLabel.TextColor3 = Color3.fromRGB(255, 215, 0)
    signLabel.TextScaled = true
    signLabel.Font = Enum.Font.SourceSansBold
    signLabel.TextStrokeTransparency = 0
    signLabel.TextStrokeColor3 = Color3.new(0, 0, 0)
    signLabel.Parent = billboardGui
    
    -- Add click detector for teleportation
    local clickDetector = Instance.new("ClickDetector")
    clickDetector.MaxActivationDistance = 20
    clickDetector.Parent = portal
    
    clickDetector.MouseClick:Connect(function(player)
        self:_teleportToTrophyHall(player)
    end)
    
    -- Add floating animation
    local floatTween = TweenService:Create(
        arch,
        TweenInfo.new(3, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true),
        {Position = arch.Position + Vector3.new(0, 1, 0)}
    )
    floatTween:Play()
end

function TrophyService:_teleportToTrophyHall(player)
    if player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
        player.Character.HumanoidRootPart.CFrame = CFrame.new(0, 10, -150) -- Trophy hall center
        
        -- Send trophy data when player enters
        self:_sendTrophyDataToPlayer(player)
        
        -- Play teleport effect
        RemoteEvents.TrophyUnlocked:FireClient(player, {
            effect = "teleport",
            message = "Welcome to the Trophy Hall!"
        })
    end
end

function TrophyService:_onPlayerAdded(player)
    -- Load player trophy data
    local trophyData = self:_loadPlayerTrophyData(player)
    playerTrophyProgress[player.UserId] = trophyData.progress or {}
    playerUnlockedTrophies[player.UserId] = trophyData.unlocked or {}
    
    -- Check for any trophies that should already be unlocked
    wait(3) -- Wait for player data to load
    self:_checkAllTrophyProgress(player)
    
    -- Update trophy displays
    self:_updatePlayerTrophyDisplays(player)
end

function TrophyService:_onPlayerRemoving(player)
    -- Save trophy data
    if playerTrophyProgress[player.UserId] then
        self:_savePlayerTrophyData(player)
        playerTrophyProgress[player.UserId] = nil
        playerUnlockedTrophies[player.UserId] = nil
    end
end

function TrophyService:_loadPlayerTrophyData(player)
    local success, data = pcall(function()
        return trophyDataStore:GetAsync(player.UserId)
    end)
    
    if success and data then
        return data
    else
        -- Initialize new trophy data
        return {
            progress = {},
            unlocked = {},
            lastUpdate = os.time()
        }
    end
end

function TrophyService:_savePlayerTrophyData(player)
    local data = {
        progress = playerTrophyProgress[player.UserId] or {},
        unlocked = playerUnlockedTrophies[player.UserId] or {},
        lastUpdate = os.time()
    }
    
    pcall(function()
        trophyDataStore:SetAsync(player.UserId, data)
    end)
end

function TrophyService:_sendTrophyDataToPlayer(player)
    local trophyData = {
        badges = TROPHY_BADGES,
        progress = playerTrophyProgress[player.UserId] or {},
        unlocked = playerUnlockedTrophies[player.UserId] or {}
    }
    
    RemoteEvents.TrophyDataUpdate:FireClient(player, trophyData)
end

function TrophyService:_checkAllTrophyProgress(player)
    if not PlayerService then return end
    
    local playerData = PlayerService:GetPlayerData(player)
    if not playerData then return end
    
    local progress = playerTrophyProgress[player.UserId] or {}
    local unlocked = playerUnlockedTrophies[player.UserId] or {}
    
    for _, trophy in ipairs(TROPHY_BADGES) do
        if not unlocked[trophy.id] then
            local currentValue = self:_getPlayerStatValue(playerData, trophy.requirement.type)
            
            if currentValue >= trophy.requirement.amount then
                self:_unlockTrophy(player, trophy.id)
            else
                -- Update progress
                progress[trophy.id] = currentValue
            end
        end
    end
    
    playerTrophyProgress[player.UserId] = progress
end

function TrophyService:_getPlayerStatValue(playerData, statType)
    if statType == "high_score" then
        return playerData.highScore or 0
    elseif statType == "login_streak" then
        return playerData.currentStreak or 0
    elseif statType == "ghost_victories" then
        return playerData.ghostVictories or 0
    elseif statType == "total_coins" then
        return playerData.totalCoinsEarned or 0
    elseif statType == "puzzles_completed" then
        return playerData.puzzlesCompleted or 0
    elseif statType == "perfect_games" then
        return playerData.perfectGames or 0
    elseif statType == "max_combo" then
        return playerData.maxCombo or 0
    elseif statType == "events_participated" then
        return playerData.eventsParticipated or 0
    elseif statType == "events_won" then
        return playerData.eventsWon or 0
    elseif statType == "scores_shared" then
        return playerData.scoresShared or 0
    end
    
    return 0
end

function TrophyService:_unlockTrophy(player, trophyId)
    local trophy = nil
    for _, t in ipairs(TROPHY_BADGES) do
        if t.id == trophyId then
            trophy = t
            break
        end
    end
    
    if not trophy then return end
    
    -- Mark as unlocked
    if not playerUnlockedTrophies[player.UserId] then
        playerUnlockedTrophies[player.UserId] = {}
    end
    playerUnlockedTrophies[player.UserId][trophyId] = {
        unlockedAt = os.time(),
        trophyData = trophy
    }
    
    -- Update physical display
    self:_updateTrophyDisplay(trophyId, trophy, true)
    
    -- Save data
    self:_savePlayerTrophyData(player)
    
    -- Notify player
    RemoteEvents.TrophyUnlocked:FireClient(player, {
        trophy = trophy,
        message = "🏆 Trophy Unlocked: " .. trophy.name,
        effect = "unlock"
    })
    
    -- Update quest progress if available
    if QuestService then
        QuestService:UpdateQuestProgress(player, "trophy_unlocked", 1, {trophyId = trophyId})
    end
    
    print("🏆 " .. player.Name .. " unlocked trophy: " .. trophy.name)
end

function TrophyService:_updatePlayerTrophyDisplays(player)
    local unlocked = playerUnlockedTrophies[player.UserId] or {}
    
    for trophyId, data in pairs(unlocked) do
        self:_updateTrophyDisplay(trophyId, data.trophyData, true)
    end
end

function TrophyService:_updateTrophyDisplay(trophyId, trophyData, isUnlocked)
    local trophyHall = workspace:FindFirstChild("Hub"):FindFirstChild("TrophyHall")
    if not trophyHall then return end
    
    -- Find the trophy spot
    local spot = nil
    for _, shelf in pairs(trophyHall:GetChildren()) do
        if shelf:FindFirstChild(trophyId .. "_Spot") then
            spot = shelf:FindFirstChild(trophyId .. "_Spot")
            break
        end
    end
    
    if not spot then return end
    
    -- Remove placeholder if unlocked
    if isUnlocked then
        local placeholder = spot:FindFirstChild("Placeholder")
        if placeholder then
            placeholder:Destroy()
        end
        
        -- Create actual trophy
        self:_createActualTrophy(spot, trophyData)
    end
end

function TrophyService:_createActualTrophy(spot, trophyData)
    local pedestal = spot:FindFirstChild("Pedestal")
    if not pedestal then return end
    
    -- Create trophy model
    local trophy = Instance.new("Part")
    trophy.Name = "Trophy"
    trophy.Size = Vector3.new(1.5, 3, 1.5)
    trophy.Position = pedestal.Position + Vector3.new(0, 2.5, 0)
    trophy.Anchored = true
    trophy.BrickColor = BrickColor.new(trophyData.color)
    trophy.Material = Enum.Material.Neon
    trophy.Parent = spot
    
    -- Add special shapes based on trophy type
    if trophyData.trophyModel == "BronzeTrophy" or trophyData.trophyModel == "SilverTrophy" or trophyData.trophyModel == "GoldTrophy" or trophyData.trophyModel == "DiamondTrophy" then
        trophy.Shape = Enum.PartType.Block
        -- Add cup details
        local cup = Instance.new("SpecialMesh")
        cup.MeshType = Enum.MeshType.FileMesh
        cup.MeshId = "rbxasset://fonts/trophy.mesh"
        cup.Parent = trophy
    elseif trophyData.trophyModel == "StarTrophy" then
        local star = Instance.new("SpecialMesh")
        star.MeshType = Enum.MeshType.FileMesh
        star.MeshId = "rbxasset://fonts/star.mesh"
        star.Parent = trophy
    end
    
    -- Add glow effect
    local pointLight = Instance.new("PointLight")
    pointLight.Brightness = 2
    pointLight.Color = trophyData.color
    pointLight.Range = 8
    pointLight.Parent = trophy
    
    -- Add floating animation
    local floatTween = TweenService:Create(
        trophy,
        TweenInfo.new(3, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true),
        {Position = trophy.Position + Vector3.new(0, 0.5, 0)}
    )
    floatTween:Play()
    
    -- Add rotation animation
    local rotateTween = TweenService:Create(
        trophy,
        TweenInfo.new(8, Enum.EasingStyle.Linear, Enum.EasingDirection.InOut, -1),
        {CFrame = trophy.CFrame * CFrame.Angles(0, math.rad(360), 0)}
    )
    rotateTween:Play()
    
    -- Add trophy info display
    local billboardGui = Instance.new("BillboardGui")
    billboardGui.Size = UDim2.new(0, 200, 0, 80)
    billboardGui.StudsOffset = Vector3.new(0, 3, 0)
    billboardGui.Parent = trophy
    
    local nameLabel = Instance.new("TextLabel")
    nameLabel.Size = UDim2.new(1, 0, 0.6, 0)
    nameLabel.BackgroundTransparency = 1
    nameLabel.Text = trophyData.name
    nameLabel.TextColor3 = trophyData.color
    nameLabel.TextScaled = true
    nameLabel.Font = Enum.Font.SourceSansBold
    nameLabel.TextStrokeTransparency = 0
    nameLabel.TextStrokeColor3 = Color3.new(0, 0, 0)
    nameLabel.Parent = billboardGui
    
    local rarityLabel = Instance.new("TextLabel")
    rarityLabel.Size = UDim2.new(1, 0, 0.4, 0)
    rarityLabel.Position = UDim2.new(0, 0, 0.6, 0)
    rarityLabel.BackgroundTransparency = 1
    rarityLabel.Text = trophyData.rarity:upper()
    rarityLabel.TextColor3 = trophyData.color
    rarityLabel.TextScaled = true
    rarityLabel.Font = Enum.Font.SourceSans
    rarityLabel.TextStrokeTransparency = 0
    rarityLabel.TextStrokeColor3 = Color3.new(0, 0, 0)
    rarityLabel.Parent = billboardGui
end

function TrophyService:_openTrophyHall(player)
    -- Just send the data - client handles the UI
    self:_sendTrophyDataToPlayer(player)
end

-- Public methods for integration
function TrophyService:UpdateTrophyProgress(player, statType, value)
    if not playerTrophyProgress[player.UserId] then
        playerTrophyProgress[player.UserId] = {}
    end
    
    local progress = playerTrophyProgress[player.UserId]
    local unlocked = playerUnlockedTrophies[player.UserId] or {}
    
    -- Check all trophies of this stat type
    for _, trophy in ipairs(TROPHY_BADGES) do
        if trophy.requirement.type == statType and not unlocked[trophy.id] then
            if value >= trophy.requirement.amount then
                self:_unlockTrophy(player, trophy.id)
            else
                progress[trophy.id] = value
            end
        end
    end
end

function TrophyService:GetPlayerTrophies(player)
    return playerUnlockedTrophies[player.UserId] or {}
end

function TrophyService:GetTrophyProgress(player)
    return playerTrophyProgress[player.UserId] or {}
end

-- Service setters
function TrophyService:SetPlayerService(playerService)
    PlayerService = playerService
end

function TrophyService:SetQuestService(questService)
    QuestService = questService
end

return TrophyService
