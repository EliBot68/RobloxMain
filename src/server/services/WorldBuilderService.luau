-- WorldBuilderService.luau
-- Creates the actual game world from scratch with proper hub and market areas

local Workspace = game:GetService("Workspace")
local Lighting = game:GetService("Lighting")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local WorldBuilderService = {}

-- Color palette for consistent theming
local COLORS = {
    Primary = Color3.fromRGB(100, 150, 255),    -- Blue
    Secondary = Color3.fromRGB(255, 200, 100),  -- Gold
    Accent = Color3.fromRGB(150, 255, 150),     -- Green
    White = Color3.fromRGB(255, 255, 255),
    Dark = Color3.fromRGB(45, 45, 45),
    Stone = Color3.fromRGB(120, 120, 120),
    Wood = Color3.fromRGB(160, 130, 90),
}

-- World configuration
local WORLD_CONFIG = {
    hubCenter = Vector3.new(0, 5, 0),
    spawnPoint = Vector3.new(0, 6, -25),
    playPortal = Vector3.new(0, 5, 25),
    marketRadius = 40,
    fountainRadius = 8,
}

function WorldBuilderService:ClearOldWorld()
    print("🧹 Clearing old world structures...")
    
    -- List of old items to remove
    local itemsToRemove = {
        "Hub", "MarketPlaza", "GameArena", "TournamentArena",
        "VIPLounge", "PrestigePalace", "OldSpawn", "LegacyBuilding",
        "TestBuilding", "TempBuilding", "Fountain", "Shop",
        "UpgradeStall", "CrateStall", "RebirthShrine", "GameTrack",
        "PlayPortal", "DifficultyPortals"
    }
    
    local removed = 0
    for _, itemName in pairs(itemsToRemove) do
        -- Add error handling for world object removal
        local success, error = pcall(function()
            local item = Workspace:FindFirstChild(itemName)
            if item then
                print("   Removing: " .. itemName)
                item:Destroy()
                removed = removed + 1
            end
        end)
        
        if not success then
            warn("   Failed to remove " .. itemName .. ": " .. tostring(error))
        end
    end
    
    -- Remove any spawn locations except baseplate
    for _, obj in pairs(Workspace:GetDescendants()) do
        if obj:IsA("SpawnLocation") and obj.Name ~= "SpawnLocation" then
            obj:Destroy()
            removed = removed + 1
        end
    end
    
    print("✅ Removed " .. removed .. " old world objects")
end

function WorldBuilderService:CreateBaseTerrain()
    print("🏗️ Creating base terrain...")
    
    -- Create main hub platform
    local hubPlatform = Instance.new("Part")
    hubPlatform.Name = "HubPlatform"
    hubPlatform.Size = Vector3.new(120, 4, 120)
    hubPlatform.Position = Vector3.new(0, 0, 0)
    hubPlatform.Material = Enum.Material.SmoothPlastic
    hubPlatform.BrickColor = BrickColor.new("Light stone grey")
    hubPlatform.Anchored = true
    hubPlatform.CanCollide = true
    hubPlatform.Parent = Workspace
    
    -- Add platform pattern
    local hubTexture = Instance.new("Texture")
    hubTexture.Texture = "rbxasset://textures/brick.png"
    hubTexture.StudsPerTileU = 8
    hubTexture.StudsPerTileV = 8
    hubTexture.Face = Enum.NormalId.Top
    hubTexture.Parent = hubPlatform
    
    -- Create spawn area platform
    local spawnPlatform = Instance.new("Part")
    spawnPlatform.Name = "SpawnPlatform"
    spawnPlatform.Size = Vector3.new(20, 2, 12)
    spawnPlatform.Position = WORLD_CONFIG.spawnPoint + Vector3.new(0, -1, 0)
    spawnPlatform.Material = Enum.Material.Marble
    spawnPlatform.BrickColor = BrickColor.new("Institutional white")
    spawnPlatform.Anchored = true
    spawnPlatform.Parent = Workspace
    
    return hubPlatform
end

function WorldBuilderService:CreateSpawnArea()
    print("🚀 Creating spawn area...")
    
    -- Create spawn location
    local spawnLocation = Instance.new("SpawnLocation")
    spawnLocation.Name = "MainSpawn"
    spawnLocation.Size = Vector3.new(6, 1, 6)
    spawnLocation.Position = WORLD_CONFIG.spawnPoint
    spawnLocation.Material = Enum.Material.Neon
    spawnLocation.BrickColor = BrickColor.new("Bright blue")
    spawnLocation.Anchored = true
    spawnLocation.CanCollide = true
    spawnLocation.Shape = Enum.PartType.Cylinder
    spawnLocation.Parent = Workspace
    
    -- Add spawn effects
    local spawnLight = Instance.new("PointLight")
    spawnLight.Color = COLORS.Primary
    spawnLight.Brightness = 2
    spawnLight.Range = 15
    spawnLight.Parent = spawnLocation
    
    -- Add particle effect
    local attachment = Instance.new("Attachment")
    attachment.Parent = spawnLocation
    
    local particles = Instance.new("ParticleEmitter")
    particles.Texture = "rbxasset://textures/particles/sparkles_main.dds"
    particles.Color = ColorSequence.new(COLORS.Primary)
    particles.Size = NumberSequence.new{
        NumberSequenceKeypoint.new(0, 0.5),
        NumberSequenceKeypoint.new(1, 1.5)
    }
    particles.Lifetime = NumberRange.new(2, 4)
    particles.Rate = 20
    particles.SpreadAngle = Vector2.new(45, 45)
    particles.Speed = NumberRange.new(5, 15)
    particles.Parent = attachment
    
    -- Create welcome sign
    local welcomeSign = Instance.new("Part")
    welcomeSign.Name = "WelcomeSign"
    welcomeSign.Size = Vector3.new(12, 6, 1)
    welcomeSign.Position = WORLD_CONFIG.spawnPoint + Vector3.new(0, 4, -8)
    welcomeSign.Material = Enum.Material.SmoothPlastic
    welcomeSign.BrickColor = BrickColor.new("Really black")
    welcomeSign.Anchored = true
    welcomeSign.Parent = Workspace
    
    local signGui = Instance.new("SurfaceGui")
    signGui.Face = Enum.NormalId.Front
    signGui.Parent = welcomeSign
    
    local titleLabel = Instance.new("TextLabel")
    titleLabel.Size = UDim2.new(1, 0, 0.6, 0)
    titleLabel.Position = UDim2.new(0, 0, 0.1, 0)
    titleLabel.BackgroundTransparency = 1
    titleLabel.Text = "🏃 RUNNER'S PARADISE 🏃"
    titleLabel.TextColor3 = COLORS.Secondary
    titleLabel.TextScaled = true
    titleLabel.Font = Enum.Font.SourceSansBold
    titleLabel.TextStrokeTransparency = 0
    titleLabel.TextStrokeColor3 = Color3.new(0, 0, 0)
    titleLabel.Parent = signGui
    
    local subtitleLabel = Instance.new("TextLabel")
    subtitleLabel.Size = UDim2.new(1, 0, 0.3, 0)
    subtitleLabel.Position = UDim2.new(0, 0, 0.7, 0)
    subtitleLabel.BackgroundTransparency = 1
    subtitleLabel.Text = "Welcome to the Hub! Explore and upgrade!"
    subtitleLabel.TextColor3 = COLORS.White
    subtitleLabel.TextScaled = true
    subtitleLabel.Font = Enum.Font.SourceSans
    subtitleLabel.Parent = signGui
    
    print("✅ Spawn area created")
    return spawnLocation
end

function WorldBuilderService:CreatePlayPortals()
    print("🌟 Creating difficulty portals...")
    
    -- Portal configurations for each difficulty
    local portalConfigs = {
        {
            difficulty = "Easy",
            position = Vector3.new(-25, 5, 40),
            color = Color3.fromRGB(85, 255, 85),
            title = "🟢 EASY TRACK",
            subtitle = "Perfect for beginners",
            xpRequired = 0
        },
        {
            difficulty = "Medium", 
            position = Vector3.new(0, 5, 40),
            color = Color3.fromRGB(255, 255, 85),
            title = "🟡 MEDIUM TRACK",
            subtitle = "For experienced runners",
            xpRequired = 500
        },
        {
            difficulty = "Hard",
            position = Vector3.new(25, 5, 40),
            color = Color3.fromRGB(255, 85, 85),
            title = "🔴 HARD TRACK",
            subtitle = "For elite runners only",
            xpRequired = 1500
        }
    }
    
    local portals = {}
    
    for _, config in pairs(portalConfigs) do
        local portal = self:CreateDifficultyPortal(config)
        table.insert(portals, portal)
    end
    
    print("✅ All difficulty portals created")
    return portals
end

function WorldBuilderService:CreateDifficultyPortal(config)
    print("🌟 Creating " .. config.difficulty .. " portal...")
    
    -- Create portal platform
    local portalPlatform = Instance.new("Part")
    portalPlatform.Name = "PortalPlatform_" .. config.difficulty
    portalPlatform.Size = Vector3.new(12, 2, 12)
    portalPlatform.Position = config.position + Vector3.new(0, -1, 0)
    portalPlatform.Material = Enum.Material.Marble
    portalPlatform.Color = config.color
    portalPlatform.Anchored = true
    portalPlatform.Parent = Workspace
    
    -- Create portal archway
    local portalArch = Instance.new("Part")
    portalArch.Name = "PortalArch_" .. config.difficulty
    portalArch.Size = Vector3.new(10, 10, 2)
    portalArch.Position = config.position + Vector3.new(0, 5, 0)
    portalArch.Material = Enum.Material.Neon
    portalArch.Color = config.color
    portalArch.Anchored = true
    portalArch.CanCollide = false
    portalArch.Shape = Enum.PartType.Ball
    portalArch.Parent = Workspace
    
    -- Add portal effects
    local portalLight = Instance.new("PointLight")
    portalLight.Color = config.color
    portalLight.Brightness = 3
    portalLight.Range = 20
    portalLight.Parent = portalArch
    
    -- Portal particles
    local attachment = Instance.new("Attachment")
    attachment.Parent = portalArch
    
    local portalParticles = Instance.new("ParticleEmitter")
    portalParticles.Texture = "rbxasset://textures/particles/fire_main.dds"
    portalParticles.Color = ColorSequence.new(config.color)
    portalParticles.Size = NumberSequence.new{
        NumberSequenceKeypoint.new(0, 1),
        NumberSequenceKeypoint.new(1, 0)
    }
    portalParticles.Lifetime = NumberRange.new(1, 3)
    portalParticles.Rate = 40
    portalParticles.SpreadAngle = Vector2.new(360, 360)
    portalParticles.Speed = NumberRange.new(2, 8)
    portalParticles.Parent = attachment
    
    -- Add click detector for teleporting to game
    local clickDetector = Instance.new("ClickDetector")
    clickDetector.MaxActivationDistance = 15
    clickDetector.Parent = portalPlatform
    
    -- Connect to enhanced game start with error handling
    clickDetector.MouseClick:Connect(function(player)
        print("🎮 Player " .. player.Name .. " clicked " .. config.difficulty .. " portal")
        
        -- Enhanced error handling for game start
        local success, result = pcall(function()
            local ServerScriptService = game:GetService("ServerScriptService")
            local GameTrackService = require(ServerScriptService.Server.services.GameTrackService)
            return GameTrackService:StartGame(player, config.difficulty)
        end)
        
        if not success then
            warn("❌ Portal click error for " .. player.Name .. ": " .. tostring(result))
            self:ShowErrorMessage(player, "Game service unavailable. Please try again.")
            return
        end
        
        local gameSuccess, message = result, "Game started successfully"
        if type(result) == "table" then
            gameSuccess, message = result[1], result[2] or "Unknown error"
        end
        
        if gameSuccess then
            print("✅ Started " .. config.difficulty .. " game for " .. player.Name)
        else
            print("❌ Could not start " .. config.difficulty .. " game for " .. player.Name .. ": " .. tostring(message))
            self:ShowErrorMessage(player, tostring(message))
        end
    end)
    
    -- Create portal sign
    local portalSign = Instance.new("Part")
    portalSign.Name = "PortalSign_" .. config.difficulty
    portalSign.Size = Vector3.new(8, 4, 1)
    portalSign.Position = config.position + Vector3.new(0, 2, 6)
    portalSign.Material = Enum.Material.SmoothPlastic
    portalSign.BrickColor = BrickColor.new("Really black")
    portalSign.Anchored = true
    portalSign.Parent = Workspace
    
    local portalGui = Instance.new("SurfaceGui")
    portalGui.Face = Enum.NormalId.Front
    portalGui.Parent = portalSign
    
    local titleLabel = Instance.new("TextLabel")
    titleLabel.Size = UDim2.new(1, 0, 0.6, 0)
    titleLabel.Position = UDim2.new(0, 0, 0.1, 0)
    titleLabel.BackgroundTransparency = 1
    titleLabel.Text = config.title
    titleLabel.TextColor3 = config.color
    titleLabel.TextScaled = true
    titleLabel.Font = Enum.Font.SourceSansBold
    titleLabel.TextStrokeTransparency = 0
    titleLabel.TextStrokeColor3 = Color3.new(0, 0, 0)
    titleLabel.Parent = portalGui
    
    local subtitleLabel = Instance.new("TextLabel")
    subtitleLabel.Size = UDim2.new(1, 0, 0.25, 0)
    subtitleLabel.Position = UDim2.new(0, 0, 0.65, 0)
    subtitleLabel.BackgroundTransparency = 1
    subtitleLabel.Text = config.subtitle
    subtitleLabel.TextColor3 = Color3.new(1, 1, 1)
    subtitleLabel.TextScaled = true
    subtitleLabel.Font = Enum.Font.SourceSans
    subtitleLabel.Parent = portalGui
    
    local xpLabel = Instance.new("TextLabel")
    xpLabel.Size = UDim2.new(1, 0, 0.15, 0)
    xpLabel.Position = UDim2.new(0, 0, 0.85, 0)
    xpLabel.BackgroundTransparency = 1
    xpLabel.Text = config.xpRequired > 0 and ("Requires " .. config.xpRequired .. " XP") or "UNLOCKED"
    xpLabel.TextColor3 = config.xpRequired > 0 and Color3.fromRGB(255, 255, 100) or Color3.fromRGB(100, 255, 100)
    xpLabel.TextScaled = true
    xpLabel.Font = Enum.Font.SourceSansItalic
    xpLabel.Parent = portalGui
    
    print("✅ " .. config.difficulty .. " portal created")
    return portalArch
end

function WorldBuilderService:CreateMarketStalls()
    print("🏪 Creating market stalls...")
    
    local marketStalls = Instance.new("Folder")
    marketStalls.Name = "MarketStalls"
    marketStalls.Parent = Workspace
    
    -- Stall configurations
    local stallConfigs = {
        {
            name = "ShopStall",
            position = Vector3.new(-30, 5, -15),
            color = COLORS.Primary,
            title = "🛍️ COSMETIC SHOP",
            subtitle = "Skins & Trails"
        },
        {
            name = "CrateStall", 
            position = Vector3.new(30, 5, -15),
            color = COLORS.Secondary,
            title = "📦 MYSTERY CRATES",
            subtitle = "Random Rewards"
        },
        {
            name = "UpgradeStall",
            position = Vector3.new(-30, 5, 15),
            color = COLORS.Accent,
            title = "⚡ UPGRADES",
            subtitle = "Boost Your Power"
        },
        {
            name = "RebirthShrine",
            position = Vector3.new(30, 5, 15),
            color = Color3.fromRGB(255, 100, 255),
            title = "⭐ REBIRTH SHRINE",
            subtitle = "Ascend to Greatness"
        }
    }
    
    for _, config in pairs(stallConfigs) do
        -- Create stall base
        local stallBase = Instance.new("Part")
        stallBase.Name = config.name .. "Base"
        stallBase.Size = Vector3.new(12, 6, 12)
        stallBase.Position = config.position
        stallBase.Material = Enum.Material.SmoothPlastic
        stallBase.Color = config.color
        stallBase.Anchored = true
        stallBase.Parent = marketStalls
        
        -- Add stall roof
        local stallRoof = Instance.new("Part")
        stallRoof.Name = config.name .. "Roof"
        stallRoof.Size = Vector3.new(14, 1, 14)
        stallRoof.Position = config.position + Vector3.new(0, 4, 0)
        stallRoof.Material = Enum.Material.Wood
        stallRoof.BrickColor = BrickColor.new("Reddish brown")
        stallRoof.Anchored = true
        stallRoof.Parent = marketStalls
        
        -- Create interaction pad
        local interactionPad = Instance.new("Part")
        interactionPad.Name = config.name
        interactionPad.Size = Vector3.new(8, 1, 8)
        interactionPad.Position = config.position + Vector3.new(0, -2.5, 0)
        interactionPad.Material = Enum.Material.Neon
        interactionPad.Color = config.color
        interactionPad.Anchored = true
        interactionPad.Parent = marketStalls
        
        -- Add click detector
        local clickDetector = Instance.new("ClickDetector")
        clickDetector.MaxActivationDistance = 15
        clickDetector.Parent = interactionPad
        
        -- Add stall light
        local stallLight = Instance.new("PointLight")
        stallLight.Color = config.color
        stallLight.Brightness = 2
        stallLight.Range = 20
        stallLight.Parent = stallBase
        
        -- Create stall sign
        local stallSign = Instance.new("Part")
        stallSign.Name = config.name .. "Sign"
        stallSign.Size = Vector3.new(10, 3, 1)
        stallSign.Position = config.position + Vector3.new(0, 1, -6.5)
        stallSign.Material = Enum.Material.SmoothPlastic
        stallSign.BrickColor = BrickColor.new("Really black")
        stallSign.Anchored = true
        stallSign.Parent = marketStalls
        
        local signGui = Instance.new("SurfaceGui")
        signGui.Face = Enum.NormalId.Front
        signGui.Parent = stallSign
        
        local titleLabel = Instance.new("TextLabel")
        titleLabel.Size = UDim2.new(1, 0, 0.6, 0)
        titleLabel.Position = UDim2.new(0, 0, 0.1, 0)
        titleLabel.BackgroundTransparency = 1
        titleLabel.Text = config.title
        titleLabel.TextColor3 = config.color
        titleLabel.TextScaled = true
        titleLabel.Font = Enum.Font.SourceSansBold
        titleLabel.TextStrokeTransparency = 0
        titleLabel.TextStrokeColor3 = Color3.new(0, 0, 0)
        titleLabel.Parent = signGui
        
        local subtitleLabel = Instance.new("TextLabel")
        subtitleLabel.Size = UDim2.new(1, 0, 0.3, 0)
        subtitleLabel.Position = UDim2.new(0, 0, 0.7, 0)
        subtitleLabel.BackgroundTransparency = 1
        subtitleLabel.Text = config.subtitle
        subtitleLabel.TextColor3 = COLORS.White
        subtitleLabel.TextScaled = true
        subtitleLabel.Font = Enum.Font.SourceSans
        subtitleLabel.Parent = signGui
    end
    
    print("✅ Market stalls created")
    return marketStalls
end

function WorldBuilderService:CreateCenterFountain()
    print("⛲ Creating center fountain...")
    
    local fountain = Instance.new("Model")
    fountain.Name = "CenterFountain"
    fountain.Parent = Workspace
    
    -- Fountain base
    local fountainBase = Instance.new("Part")
    fountainBase.Name = "FountainBase"
    fountainBase.Size = Vector3.new(16, 2, 16)
    fountainBase.Position = WORLD_CONFIG.hubCenter + Vector3.new(0, -1, 0)
    fountainBase.Material = Enum.Material.Marble
    fountainBase.BrickColor = BrickColor.new("Institutional white")
    fountainBase.Anchored = true
    fountainBase.Shape = Enum.PartType.Cylinder
    fountainBase.Parent = fountain
    
    -- Water basin
    local waterBasin = Instance.new("Part")
    waterBasin.Name = "WaterBasin"
    waterBasin.Size = Vector3.new(14, 1, 14)
    waterBasin.Position = WORLD_CONFIG.hubCenter + Vector3.new(0, 0.5, 0)
    waterBasin.Material = Enum.Material.Water
    waterBasin.BrickColor = BrickColor.new("Bright blue")
    waterBasin.Anchored = true
    waterBasin.CanCollide = false
    waterBasin.Shape = Enum.PartType.Cylinder
    waterBasin.Parent = fountain
    
    -- Central pillar
    local centerPillar = Instance.new("Part")
    centerPillar.Name = "CenterPillar"
    centerPillar.Size = Vector3.new(3, 8, 3)
    centerPillar.Position = WORLD_CONFIG.hubCenter + Vector3.new(0, 4, 0)
    centerPillar.Material = Enum.Material.Marble
    centerPillar.BrickColor = BrickColor.new("Light stone grey")
    centerPillar.Anchored = true
    centerPillar.Parent = fountain
    
    -- Fountain top
    local fountainTop = Instance.new("Part")
    fountainTop.Name = "FountainTop"
    fountainTop.Size = Vector3.new(2, 1, 2)
    fountainTop.Position = WORLD_CONFIG.hubCenter + Vector3.new(0, 8.5, 0)
    centerPillar.Material = Enum.Material.Marble
    fountainTop.BrickColor = BrickColor.new("Institutional white")
    fountainTop.Anchored = true
    fountainTop.Shape = Enum.PartType.Ball
    fountainTop.Parent = fountain
    
    -- Add water particles
    local attachment = Instance.new("Attachment")
    attachment.Position = Vector3.new(0, 0.5, 0)
    attachment.Parent = fountainTop
    
    local waterParticles = Instance.new("ParticleEmitter")
    waterParticles.Texture = "rbxasset://textures/particles/water_splash_01.dds"
    waterParticles.Color = ColorSequence.new(Color3.fromRGB(173, 216, 230))
    waterParticles.Size = NumberSequence.new{
        NumberSequenceKeypoint.new(0, 0.2),
        NumberSequenceKeypoint.new(1, 0.8)
    }
    waterParticles.Lifetime = NumberRange.new(2, 4)
    waterParticles.Rate = 30
    waterParticles.SpreadAngle = Vector2.new(25, 25)
    waterParticles.Speed = NumberRange.new(10, 20)
    waterParticles.Acceleration = Vector3.new(0, -20, 0)
    waterParticles.Parent = attachment
    
    -- Add fountain light
    local fountainLight = Instance.new("PointLight")
    fountainLight.Color = Color3.fromRGB(173, 216, 230)
    fountainLight.Brightness = 1.5
    fountainLight.Range = 30
    fountainLight.Parent = centerPillar
    
    print("✅ Center fountain created")
    return fountain
end

function WorldBuilderService:CreateDecorativeAssets()
    print("🌳 Creating decorative assets...")
    
    local decorations = Instance.new("Folder")
    decorations.Name = "Decorations"
    decorations.Parent = Workspace
    
    -- Create benches around the hub
    local benchPositions = {
        Vector3.new(-15, 5, 30),
        Vector3.new(15, 5, 30),
        Vector3.new(-35, 5, 0),
        Vector3.new(35, 5, 0),
        Vector3.new(-15, 5, -30),
        Vector3.new(15, 5, -30)
    }
    
    for i, pos in pairs(benchPositions) do
        local bench = Instance.new("Part")
        bench.Name = "Bench" .. i
        bench.Size = Vector3.new(6, 1, 2)
        bench.Position = pos
        bench.Material = Enum.Material.Wood
        bench.BrickColor = BrickColor.new("Reddish brown")
        bench.Anchored = true
        bench.Parent = decorations
        
        -- Bench back
        local benchBack = Instance.new("Part")
        benchBack.Name = "BenchBack" .. i
        benchBack.Size = Vector3.new(6, 3, 0.5)
        benchBack.Position = pos + Vector3.new(0, 1.5, -0.75)
        benchBack.Material = Enum.Material.Wood
        benchBack.BrickColor = BrickColor.new("Reddish brown")
        benchBack.Anchored = true
        benchBack.Parent = decorations
    end
    
    -- Create lamp posts
    local lampPositions = {
        Vector3.new(-25, 5, -25),
        Vector3.new(25, 5, -25),
        Vector3.new(-25, 5, 25),
        Vector3.new(25, 5, 25),
        Vector3.new(0, 5, -40),
        Vector3.new(0, 5, 40)
    }
    
    for i, pos in pairs(lampPositions) do
        -- Lamp post
        local lampPost = Instance.new("Part")
        lampPost.Name = "LampPost" .. i
        lampPost.Size = Vector3.new(0.5, 12, 0.5)
        lampPost.Position = pos + Vector3.new(0, 6, 0)
        lampPost.Material = Enum.Material.Metal
        lampPost.BrickColor = BrickColor.new("Really black")
        lampPost.Anchored = true
        lampPost.Parent = decorations
        
        -- Lamp top
        local lampTop = Instance.new("Part")
        lampTop.Name = "LampTop" .. i
        lampTop.Size = Vector3.new(2, 1, 2)
        lampTop.Position = pos + Vector3.new(0, 12.5, 0)
        lampTop.Material = Enum.Material.Neon
        lampTop.BrickColor = BrickColor.new("Bright yellow")
        lampTop.Anchored = true
        lampTop.Shape = Enum.PartType.Ball
        lampTop.Parent = decorations
        
        -- Lamp light
        local lampLight = Instance.new("PointLight")
        lampLight.Color = Color3.fromRGB(255, 255, 200)
        lampLight.Brightness = 1
        lampLight.Range = 25
        lampLight.Parent = lampTop
    end
    
    -- Create directional signs
    local signData = {
        {pos = Vector3.new(0, 5, 35), text = "🎮 PLAY AREA 🎮", rotation = 0},
        {pos = Vector3.new(-40, 5, 0), text = "🛍️ SHOP & UPGRADES", rotation = 90},
        {pos = Vector3.new(40, 5, 0), text = "📦 CRATES & REBIRTH", rotation = -90},
        {pos = Vector3.new(0, 5, -35), text = "🏠 SPAWN AREA", rotation = 180}
    }
    
    for i, data in pairs(signData) do
        local sign = Instance.new("Part")
        sign.Name = "DirectionalSign" .. i
        sign.Size = Vector3.new(8, 3, 1)
        sign.Position = data.pos
        sign.Material = Enum.Material.SmoothPlastic
        sign.BrickColor = BrickColor.new("Really black")
        sign.Anchored = true
        sign.Orientation = Vector3.new(0, data.rotation, 0)
        sign.Parent = decorations
        
        local signGui = Instance.new("SurfaceGui")
        signGui.Face = Enum.NormalId.Front
        signGui.Parent = sign
        
        local signLabel = Instance.new("TextLabel")
        signLabel.Size = UDim2.new(1, 0, 1, 0)
        signLabel.BackgroundTransparency = 1
        signLabel.Text = data.text
        signLabel.TextColor3 = COLORS.Secondary
        signLabel.TextScaled = true
        signLabel.Font = Enum.Font.SourceSansBold
        signLabel.TextStrokeTransparency = 0
        signLabel.TextStrokeColor3 = Color3.new(0, 0, 0)
        signLabel.Parent = signGui
    end
    
    print("✅ Decorative assets created")
    return decorations
end

function WorldBuilderService:SetupLighting()
    print("💡 Setting up world lighting...")
    
    -- Configure lighting for a welcoming hub atmosphere
    Lighting.Brightness = 1.5
    Lighting.Ambient = Color3.fromRGB(70, 70, 80)
    Lighting.ColorShift_Bottom = Color3.fromRGB(100, 100, 120)
    Lighting.ColorShift_Top = Color3.fromRGB(240, 240, 255)
    Lighting.OutdoorAmbient = Color3.fromRGB(128, 128, 128)
    Lighting.FogEnd = 500
    Lighting.FogStart = 0
    
    -- Add atmospheric effects
    local atmosphere = Instance.new("Atmosphere")
    atmosphere.Density = 0.1
    atmosphere.Offset = 0.5
    atmosphere.Color = Color3.fromRGB(199, 199, 199)
    atmosphere.Decay = Color3.fromRGB(106, 112, 125)
    atmosphere.Glare = 0.2
    atmosphere.Haze = 0.3
    atmosphere.Parent = Lighting
    
    print("✅ Lighting configured")
end

function WorldBuilderService:CreateWorldBoundaries()
    print("🚧 Creating world boundaries...")
    
    local boundaries = Instance.new("Folder")
    boundaries.Name = "WorldBoundaries"
    boundaries.Parent = Workspace
    
    -- Create invisible barriers around the hub
    local barrierPositions = {
        {pos = Vector3.new(0, 10, 65), size = Vector3.new(140, 20, 5)},   -- North
        {pos = Vector3.new(0, 10, -65), size = Vector3.new(140, 20, 5)},  -- South  
        {pos = Vector3.new(65, 10, 0), size = Vector3.new(5, 20, 130)},   -- East
        {pos = Vector3.new(-65, 10, 0), size = Vector3.new(5, 20, 130)}   -- West
    }
    
    for i, barrier in pairs(barrierPositions) do
        local wall = Instance.new("Part")
        wall.Name = "Barrier" .. i
        wall.Size = barrier.size
        wall.Position = barrier.pos
        wall.Material = Enum.Material.ForceField
        wall.Anchored = true
        wall.CanCollide = true
        wall.Transparency = 0.8
        wall.Parent = boundaries
    end
    
    print("✅ World boundaries created")
    return boundaries
end

function WorldBuilderService:BuildCompleteWorld()
    print("🌍 Building complete game world...")
    
    -- Step 1: Clear old world
    self:ClearOldWorld()
    wait(1)
    
    -- Step 2: Create base terrain
    local hubPlatform = self:CreateBaseTerrain()
    wait(0.5)
    
    -- Step 3: Create spawn area
    local spawnLocation = self:CreateSpawnArea()
    wait(0.5)
    
    -- Step 4: Create play portal
    local playPortals = self:CreatePlayPortals()
    wait(0.5)
    
    -- Step 5: Create market stalls
    local marketStalls = self:CreateMarketStalls()
    wait(0.5)
    
    -- Step 6: Create center fountain
    local fountain = self:CreateCenterFountain()
    wait(0.5)
    
    -- Step 7: Add decorative assets
    local decorations = self:CreateDecorativeAssets()
    wait(0.5)
    
    -- Step 8: Setup lighting
    self:SetupLighting()
    wait(0.5)
    
    -- Step 9: Create boundaries
    local boundaries = self:CreateWorldBoundaries()
    
    -- Step 10: Final touches
    wait(1)
    for i = 1, 3 do
        collectgarbage("collect")
        wait(0.1)
    end
    
    print("🎉 COMPLETE GAME WORLD CREATED SUCCESSFULLY!")
    print("📊 World Statistics:")
    print("   ✅ Fresh spawn plaza with welcome area")
    print("   ✅ Working play portal with effects")
    print("   ✅ 4 market stalls (Shop, Crates, Upgrades, Rebirth)")
    print("   ✅ Decorative centerpiece fountain with particles") 
    print("   ✅ 6 benches and 6 lamp posts")
    print("   ✅ 4 directional signs")
    print("   ✅ Atmospheric lighting and effects")
    print("   ✅ Invisible world boundaries")
    print("   🚀 READY FOR PLAYERS!")
    
    return {
        hubPlatform = hubPlatform,
        spawnLocation = spawnLocation,
        playPortal = playPortal,
        marketStalls = marketStalls,
        fountain = fountain,
        decorations = decorations,
        boundaries = boundaries
    }
end

function WorldBuilderService:ShowErrorMessage(player, message)
    -- Safely show error message to player
    local success, error = pcall(function()
        local playerGui = player:FindFirstChild("PlayerGui")
        if not playerGui then
            warn("Player " .. player.Name .. " has no PlayerGui")
            return
        end
        
        -- Create temporary error message with enhanced styling
        spawn(function()
            local errorGui = Instance.new("ScreenGui")
            errorGui.Name = "ErrorMessage"
            errorGui.Parent = playerGui
            
            local errorFrame = Instance.new("Frame")
            errorFrame.Size = UDim2.new(0, 450, 0, 120)
            errorFrame.Position = UDim2.new(0.5, -225, 0.5, -60)
            errorFrame.BackgroundColor3 = Color3.fromRGB(220, 50, 50)
            errorFrame.BorderSizePixel = 2
            errorFrame.BorderColor3 = Color3.new(1, 1, 1)
            errorFrame.Parent = errorGui
            
            -- Add rounded corners
            local corner = Instance.new("UICorner")
            corner.CornerRadius = UDim.new(0, 10)
            corner.Parent = errorFrame
            
            local errorLabel = Instance.new("TextLabel")
            errorLabel.Size = UDim2.new(1, -20, 1, -20)
            errorLabel.Position = UDim2.new(0, 10, 0, 10)
            errorLabel.BackgroundTransparency = 1
            errorLabel.Text = "⚠️ " .. tostring(message)
            errorLabel.TextColor3 = Color3.new(1, 1, 1)
            errorLabel.TextScaled = true
            errorLabel.Font = Enum.Font.SourceSansBold
            errorLabel.TextWrapped = true
            errorLabel.TextStrokeTransparency = 0
            errorLabel.TextStrokeColor3 = Color3.new(0, 0, 0)
            errorLabel.Parent = errorFrame
            
            -- Slide in animation
            errorFrame.Position = UDim2.new(0.5, -225, -1, 0)
            errorFrame:TweenPosition(
                UDim2.new(0.5, -225, 0.5, -60),
                Enum.EasingDirection.Out,
                Enum.EasingStyle.Back,
                0.5,
                true
            )
            
            wait(4)
            
            -- Slide out animation
            errorFrame:TweenPosition(
                UDim2.new(0.5, -225, 1.5, 0),
                Enum.EasingDirection.In,
                Enum.EasingStyle.Back,
                0.3,
                true,
                function()
                    errorGui:Destroy()
                end
            )
        end)
    end)
    
    if not success then
        warn("Failed to show error message to " .. player.Name .. ": " .. tostring(error))
    end
end

function WorldBuilderService:Init()
    print("🏗️ WorldBuilderService initialized")
    
    -- Build the world after a short delay to ensure other services are ready
    spawn(function()
        wait(3)
        local success, error = pcall(function()
            self:BuildCompleteWorld()
        end)
        
        if not success then
            warn("❌ World building failed: " .. tostring(error))
        end
    end)
end

return WorldBuilderService
