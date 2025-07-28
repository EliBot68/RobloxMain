-- TrackGeneratorService.luau
-- Comprehensive track generation service for Color Rush
-- Handles static track creation with lanes, obstacles, and customizable layouts

local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local HttpService = game:GetService("HttpService")
local Debris = game:GetService("Debris")

local TrackGeneratorService = {}

-- Track Configuration
local TRACK_CONFIG = {
    -- Default track settings
    defaultLength = 500,
    defaultWidth = 50,
    defaultLanes = 4,
    
    -- Track sections
    sectionLength = 50, -- Each section is 50 studs long
    
    -- Platform settings
    platformHeight = 2,
    platformMaterial = Enum.Material.Plastic,
    
    -- Lane settings
    laneWidth = 10,
    laneMarkerHeight = 0.1,
    laneMarkerMaterial = Enum.Material.Neon,
    
    -- Color system - MUTED COLORS FOR BETTER VISIBILITY
    trackColors = {
        Red = Color3.fromRGB(180, 60, 60),     -- Darker red, less bright
        Blue = Color3.fromRGB(60, 120, 200),   -- Softer blue
        Green = Color3.fromRGB(80, 180, 80),   -- Muted green
        Yellow = Color3.fromRGB(200, 180, 60), -- Darker yellow/gold
        Neutral = Color3.fromRGB(140, 140, 140) -- Slightly lighter gray
    },
    
    -- Obstacle templates
    obstacleTemplates = {
        wall = {
            size = Vector3.new(8, 10, 2),
            material = Enum.Material.Brick,
            canCollide = true,
            transparency = 0
        },
        barrier = {
            size = Vector3.new(12, 8, 1),
            material = Enum.Material.ForceField,
            canCollide = false,
            transparency = 0.3
        },
        spike = {
            size = Vector3.new(4, 6, 4),
            material = Enum.Material.Cobblestone,
            canCollide = true,
            transparency = 0,
            shape = "Wedge"
        },
        pillar = {
            size = Vector3.new(6, 15, 6),
            material = Enum.Material.Marble,
            canCollide = true,
            transparency = 0,
            shape = "Cylinder"
        }
    },
    
    -- Collectible templates
    collectibleTemplates = {
        coin = {
            size = Vector3.new(2, 2, 0.5),
            material = Enum.Material.Neon,
            canCollide = false,
            transparency = 0,
            shape = "Cylinder",
            color = Color3.fromRGB(200, 160, 30), -- Darker gold, less bright
            rotationSpeed = 2
        },
        gem = {
            size = Vector3.new(3, 3, 3),
            material = Enum.Material.Glass,
            canCollide = false,
            transparency = 0.2,
            shape = "Block",
            color = Color3.fromRGB(60, 180, 180), -- Softer cyan
            bounceHeight = 2
        }
    }
}

-- Track layouts and patterns
local TRACK_LAYOUTS = {
    -- Basic straight track
    straight = {
        name = "Straight Track",
        description = "Simple straight track with evenly spaced obstacles",
        obstaclePattern = "regular",
        laneChanges = false,
        difficulty = 1
    },
    
    -- Alternating lane track
    alternating = {
        name = "Alternating Lanes",
        description = "Track forces players to switch lanes regularly",
        obstaclePattern = "alternating",
        laneChanges = true,
        difficulty = 2
    },
    
    -- Spiral track
    spiral = {
        name = "Spiral Track",
        description = "Track curves in a spiral pattern",
        obstaclePattern = "spiral",
        laneChanges = true,
        difficulty = 3
    },
    
    -- Maze-like track
    maze = {
        name = "Maze Track",
        description = "Complex track with multiple paths",
        obstaclePattern = "maze",
        laneChanges = true,
        difficulty = 4
    },
    
    -- Speed track
    speed = {
        name = "Speed Track",
        description = "Long straight sections with speed boosts",
        obstaclePattern = "speed",
        laneChanges = false,
        difficulty = 2
    }
}

-- Active tracks storage
local activeTracks = {}
local trackCounter = 0

-- Performance tracking
local performanceMetrics = {
    tracksGenerated = 0,
    averageGenerationTime = 0,
    totalObstaclesCreated = 0,
    memoryUsed = 0
}

function TrackGeneratorService:Initialize()
    print("🛤️ Initializing Track Generator Service...")
    
    -- Setup track folder structure
    self:SetupTrackFolders()
    
    -- Load obstacle templates
    self:LoadObstacleTemplates()
    
    -- Initialize performance monitoring
    self:InitializePerformanceMonitoring()
    
    print("✅ Track Generator Service initialized!")
    return true
end

function TrackGeneratorService:SetupTrackFolders()
    -- Create main tracks folder
    local tracksFolder = Workspace:FindFirstChild("Tracks")
    if not tracksFolder then
        tracksFolder = Instance.new("Folder")
        tracksFolder.Name = "Tracks"
        tracksFolder.Parent = Workspace
    end
    
    -- Create subfolders for organization
    local subfolders = {"Platforms", "Obstacles", "Collectibles", "Effects", "Boundaries"}
    for _, folderName in ipairs(subfolders) do
        if not tracksFolder:FindFirstChild(folderName) then
            local folder = Instance.new("Folder")
            folder.Name = folderName
            folder.Parent = tracksFolder
        end
    end
    
    print("📁 Track folder structure created")
end

function TrackGeneratorService:LoadObstacleTemplates()
    -- Check for custom obstacle templates in ReplicatedStorage
    local customTemplates = ReplicatedStorage:FindFirstChild("ObstacleTemplates")
    if customTemplates then
        for _, template in ipairs(customTemplates:GetChildren()) do
            if template:IsA("Model") then
                TRACK_CONFIG.obstacleTemplates[template.Name] = {
                    model = template,
                    custom = true
                }
                print("📦 Loaded custom obstacle template: " .. template.Name)
            end
        end
    end
end

function TrackGeneratorService:InitializePerformanceMonitoring()
    spawn(function()
        while true do
            wait(10) -- Update every 10 seconds
            performanceMetrics.memoryUsed = gcinfo()
        end
    end)
end

-- Main track generation function
function TrackGeneratorService:GenerateTrack(config)
    local startTime = tick()
    
    config = config or {}
    
    -- Apply default configuration
    local trackConfig = {
        id = config.id or self:GenerateTrackId(),
        length = config.length or TRACK_CONFIG.defaultLength,
        width = config.width or TRACK_CONFIG.defaultWidth,
        lanes = config.lanes or TRACK_CONFIG.defaultLanes,
        layout = config.layout or "straight",
        difficulty = config.difficulty or 1,
        obstacleFrequency = config.obstacleFrequency or 0.3,
        collectibleFrequency = config.collectibleFrequency or 0.2,
        position = config.position or Vector3.new(0, 0, 0),
        colorScheme = config.colorScheme or "default"
    }
    
    print(string.format("🔨 Generating track: %s (%.0fx%.0f, %d lanes)", 
        trackConfig.id, trackConfig.length, trackConfig.width, trackConfig.lanes))
    
    -- Clear existing track if specified
    if config.clearExisting then
        self:ClearTrack(trackConfig.id)
    end
    
    local track = {
        id = trackConfig.id,
        config = trackConfig,
        startTime = startTime,
        platforms = {},
        obstacles = {},
        collectibles = {},
        boundaries = {},
        effects = {},
        sections = {}
    }
    
    -- Generate track components
    self:GenerateTrackPlatforms(track)
    self:GenerateLaneMarkers(track)
    self:GenerateTrackBoundaries(track)
    self:GenerateObstacles(track)
    self:GenerateCollectibles(track)
    self:GenerateStartFinishLines(track)
    self:GenerateTrackEffects(track)
    
    -- Store track data
    activeTracks[trackConfig.id] = track
    
    -- Update performance metrics
    local generationTime = tick() - startTime
    performanceMetrics.tracksGenerated = performanceMetrics.tracksGenerated + 1
    performanceMetrics.averageGenerationTime = 
        (performanceMetrics.averageGenerationTime * (performanceMetrics.tracksGenerated - 1) + generationTime) / 
        performanceMetrics.tracksGenerated
    
    print(string.format("✅ Track '%s' generated in %.2f seconds", trackConfig.id, generationTime))
    
    return track
end

function TrackGeneratorService:GenerateTrackPlatforms(track)
    local config = track.config
    local platformsFolder = Workspace.Tracks.Platforms
    
    local sectionsCount = math.ceil(config.length / TRACK_CONFIG.sectionLength)
    
    for section = 0, sectionsCount do
        local sectionZ = config.position.Z + (section * TRACK_CONFIG.sectionLength)
        local sectionWidth = config.width
        
        -- Adjust width for different layouts
        if config.layout == "spiral" then
            local spiralFactor = math.sin(section * 0.3) * 0.3
            sectionWidth = config.width * (1 + spiralFactor)
        end
        
        -- Create platform section
        local platform = Instance.new("Part")
        platform.Name = string.format("Platform_%s_Section_%d", track.id, section)
        platform.Anchored = true
        platform.CanCollide = true
        platform.Size = Vector3.new(sectionWidth, TRACK_CONFIG.platformHeight, TRACK_CONFIG.sectionLength)
        platform.Position = Vector3.new(
            config.position.X,
            config.position.Y - TRACK_CONFIG.platformHeight/2,
            sectionZ
        )
        platform.Material = TRACK_CONFIG.platformMaterial
        platform.BrickColor = BrickColor.new("Medium stone grey")
        platform.TopSurface = Enum.SurfaceType.Smooth
        platform.BottomSurface = Enum.SurfaceType.Smooth
        
        -- Add track identification
        platform:SetAttribute("TrackId", track.id)
        platform:SetAttribute("Section", section)
        platform:SetAttribute("GeneratedTrack", true)
        
        platform.Parent = platformsFolder
        table.insert(track.platforms, platform)
        
        -- Add section data
        track.sections[section] = {
            platform = platform,
            obstacles = {},
            collectibles = {},
            position = Vector3.new(config.position.X, config.position.Y, sectionZ),
            width = sectionWidth
        }
    end
    
    print(string.format("🏗️ Generated %d platform sections", sectionsCount + 1))
end

function TrackGeneratorService:GenerateLaneMarkers(track)
    local config = track.config
    local platformsFolder = Workspace.Tracks.Platforms
    
    if config.lanes <= 1 then return end
    
    local laneWidth = config.width / config.lanes
    
    for section = 0, #track.sections do
        local sectionZ = config.position.Z + (section * TRACK_CONFIG.sectionLength)
        
        -- Generate lane dividers
        for lane = 1, config.lanes - 1 do
            local laneX = config.position.X - (config.width/2) + (lane * laneWidth)
            
            local marker = Instance.new("Part")
            marker.Name = string.format("LaneMarker_%s_S%d_L%d", track.id, section, lane)
            marker.Anchored = true
            marker.CanCollide = false
            marker.Size = Vector3.new(0.5, TRACK_CONFIG.laneMarkerHeight, TRACK_CONFIG.sectionLength)
            marker.Position = Vector3.new(laneX, config.position.Y + 0.1, sectionZ)
            marker.Material = TRACK_CONFIG.laneMarkerMaterial
            marker.BrickColor = BrickColor.new("Bright orange") -- Changed from bright yellow
            
            -- Add glowing effect - REDUCED BRIGHTNESS
            local pointLight = Instance.new("PointLight")
            pointLight.Brightness = 0.3 -- Reduced from 0.5
            pointLight.Color = Color3.fromRGB(255, 140, 0) -- Orange instead of yellow
            pointLight.Range = 8 -- Reduced from 10
            pointLight.Parent = marker
            
            marker:SetAttribute("TrackId", track.id)
            marker:SetAttribute("LaneMarker", true)
            marker:SetAttribute("GeneratedTrack", true)
            
            marker.Parent = platformsFolder
        end
    end
    
    print(string.format("🛣️ Generated lane markers for %d lanes", config.lanes))
end

function TrackGeneratorService:GenerateTrackBoundaries(track)
    local config = track.config
    local boundariesFolder = Workspace.Tracks.Boundaries
    
    local boundaryHeight = 15
    local boundaryThickness = 2
    
    -- Left boundary
    local leftBoundary = Instance.new("Part")
    leftBoundary.Name = string.format("LeftBoundary_%s", track.id)
    leftBoundary.Anchored = true
    leftBoundary.CanCollide = true
    leftBoundary.Size = Vector3.new(boundaryThickness, boundaryHeight, config.length)
    leftBoundary.Position = Vector3.new(
        config.position.X - (config.width/2) - (boundaryThickness/2),
        config.position.Y + (boundaryHeight/2),
        config.position.Z + (config.length/2)
    )
    leftBoundary.Material = Enum.Material.Neon
    leftBoundary.BrickColor = BrickColor.new("Bright red")
    leftBoundary.Transparency = 0.5 -- Increased transparency to reduce brightness
    leftBoundary:SetAttribute("TrackId", track.id)
    leftBoundary:SetAttribute("Boundary", true)
    leftBoundary:SetAttribute("GeneratedTrack", true)
    leftBoundary.Parent = boundariesFolder
    table.insert(track.boundaries, leftBoundary)
    
    -- Right boundary
    local rightBoundary = Instance.new("Part")
    rightBoundary.Name = string.format("RightBoundary_%s", track.id)
    rightBoundary.Anchored = true
    rightBoundary.CanCollide = true
    rightBoundary.Size = Vector3.new(boundaryThickness, boundaryHeight, config.length)
    rightBoundary.Position = Vector3.new(
        config.position.X + (config.width/2) + (boundaryThickness/2),
        config.position.Y + (boundaryHeight/2),
        config.position.Z + (config.length/2)
    )
    rightBoundary.Material = Enum.Material.Neon
    rightBoundary.BrickColor = BrickColor.new("Bright red")
    rightBoundary.Transparency = 0.5 -- Increased transparency to reduce brightness
    rightBoundary:SetAttribute("TrackId", track.id)
    rightBoundary:SetAttribute("Boundary", true)
    rightBoundary:SetAttribute("GeneratedTrack", true)
    rightBoundary.Parent = boundariesFolder
    table.insert(track.boundaries, rightBoundary)
    
    print("🚧 Generated track boundaries")
end

function TrackGeneratorService:GenerateObstacles(track)
    local config = track.config
    local obstaclesFolder = Workspace.Tracks.Obstacles
    local obstacleCount = 0
    
    -- Select obstacle pattern based on layout
    local pattern = self:GetObstaclePattern(config.layout, config.difficulty)
    
    for section = 1, #track.sections - 1 do -- Skip first and last sections
        if math.random() < config.obstacleFrequency then
            local obstacles = self:GenerateObstaclesForSection(track, section, pattern)
            
            for _, obstacle in ipairs(obstacles) do
                obstacle:SetAttribute("TrackId", track.id)
                obstacle:SetAttribute("Section", section)
                obstacle:SetAttribute("GeneratedTrack", true)
                obstacle.Parent = obstaclesFolder
                
                table.insert(track.obstacles, obstacle)
                table.insert(track.sections[section].obstacles, obstacle)
                obstacleCount = obstacleCount + 1
            end
        end
    end
    
    performanceMetrics.totalObstaclesCreated = performanceMetrics.totalObstaclesCreated + obstacleCount
    print(string.format("🚫 Generated %d obstacles", obstacleCount))
end

function TrackGeneratorService:GenerateObstaclesForSection(track, section, pattern)
    local config = track.config
    local sectionData = track.sections[section]
    local obstacles = {}
    
    local sectionZ = config.position.Z + (section * TRACK_CONFIG.sectionLength)
    local laneWidth = config.width / config.lanes
    
    if pattern == "regular" then
        -- Random obstacles in random lanes
        local numObstacles = math.random(1, math.min(3, config.lanes))
        local usedLanes = {}
        
        for i = 1, numObstacles do
            local lane = math.random(1, config.lanes)
            while usedLanes[lane] do
                lane = math.random(1, config.lanes)
            end
            usedLanes[lane] = true
            
            local obstacle = self:CreateObstacle("wall", {
                position = Vector3.new(
                    config.position.X - (config.width/2) + ((lane - 0.5) * laneWidth),
                    config.position.Y + 5,
                    sectionZ
                ),
                color = self:GetRandomObstacleColor(config)
            })
            
            table.insert(obstacles, obstacle)
        end
        
    elseif pattern == "alternating" then
        -- Block every other lane
        for lane = 1, config.lanes do
            if (section + lane) % 2 == 0 then
                local obstacle = self:CreateObstacle("barrier", {
                    position = Vector3.new(
                        config.position.X - (config.width/2) + ((lane - 0.5) * laneWidth),
                        config.position.Y + 4,
                        sectionZ
                    ),
                    color = TRACK_CONFIG.trackColors.Red
                })
                
                table.insert(obstacles, obstacle)
            end
        end
        
    elseif pattern == "spiral" then
        -- Obstacles follow a spiral pattern
        local spiralLane = ((section - 1) % config.lanes) + 1
        
        local obstacle = self:CreateObstacle("pillar", {
            position = Vector3.new(
                config.position.X - (config.width/2) + ((spiralLane - 0.5) * laneWidth),
                config.position.Y + 7,
                sectionZ
            ),
            color = TRACK_CONFIG.trackColors.Blue
        })
        
        table.insert(obstacles, obstacle)
        
    elseif pattern == "maze" then
        -- Create maze-like obstacles
        local mazePattern = {
            {1, 0, 1, 0}, -- Pattern for 4 lanes
            {0, 1, 0, 1},
            {1, 1, 0, 0},
            {0, 0, 1, 1}
        }
        
        local patternIndex = ((section - 1) % #mazePattern) + 1
        local pattern = mazePattern[patternIndex]
        
        for lane = 1, math.min(config.lanes, #pattern) do
            if pattern[lane] == 1 then
                local obstacle = self:CreateObstacle("wall", {
                    position = Vector3.new(
                        config.position.X - (config.width/2) + ((lane - 0.5) * laneWidth),
                        config.position.Y + 5,
                        sectionZ
                    ),
                    color = TRACK_CONFIG.trackColors.Green
                })
                
                table.insert(obstacles, obstacle)
            end
        end
        
    elseif pattern == "speed" then
        -- Fewer obstacles for speed tracks
        if section % 3 == 0 then
            local lane = math.random(1, config.lanes)
            local obstacle = self:CreateObstacle("spike", {
                position = Vector3.new(
                    config.position.X - (config.width/2) + ((lane - 0.5) * laneWidth),
                    config.position.Y + 3,
                    sectionZ
                ),
                color = TRACK_CONFIG.trackColors.Yellow
            })
            
            table.insert(obstacles, obstacle)
        end
    end
    
    return obstacles
end

function TrackGeneratorService:CreateObstacle(templateName, options)
    local template = TRACK_CONFIG.obstacleTemplates[templateName]
    if not template then
        warn("Unknown obstacle template: " .. templateName)
        template = TRACK_CONFIG.obstacleTemplates.wall
    end
    
    local obstacle
    
    if template.custom and template.model then
        -- Use custom model
        obstacle = template.model:Clone()
        obstacle.Position = options.position
    else
        -- Create obstacle from template
        if template.shape == "Wedge" then
            obstacle = Instance.new("WedgePart")
        elseif template.shape == "Cylinder" then
            obstacle = Instance.new("Part")
            obstacle.Shape = Enum.PartType.Cylinder
        else
            obstacle = Instance.new("Part")
        end
        
        obstacle.Size = template.size
        obstacle.Material = template.material
        obstacle.CanCollide = template.canCollide
        obstacle.Transparency = template.transparency
        obstacle.Anchored = true
        obstacle.Position = options.position
    end
    
    -- Apply color
    if options.color then
        obstacle.Color = options.color
    end
    
    -- Add visual effects
    if template.material == Enum.Material.Neon then
        local pointLight = Instance.new("PointLight")
        pointLight.Brightness = 1
        pointLight.Color = obstacle.Color
        pointLight.Range = 15
        pointLight.Parent = obstacle
    end
    
    -- Add collision handling
    if template.canCollide then
        obstacle.Touched:Connect(function(hit)
            self:HandleObstacleCollision(obstacle, hit)
        end)
    end
    
    obstacle.Name = string.format("Obstacle_%s_%s", templateName, HttpService:GenerateGUID(false):sub(1, 8))
    
    return obstacle
end

function TrackGeneratorService:GenerateCollectibles(track)
    local config = track.config
    local collectiblesFolder = Workspace.Tracks.Collectibles
    local collectibleCount = 0
    
    for section = 1, #track.sections - 1 do
        if math.random() < config.collectibleFrequency then
            -- Don't place collectibles in sections with obstacles
            if #track.sections[section].obstacles == 0 then
                local collectibles = self:GenerateCollectiblesForSection(track, section)
                
                for _, collectible in ipairs(collectibles) do
                    collectible:SetAttribute("TrackId", track.id)
                    collectible:SetAttribute("Section", section)
                    collectible:SetAttribute("GeneratedTrack", true)
                    collectible.Parent = collectiblesFolder
                    
                    table.insert(track.collectibles, collectible)
                    table.insert(track.sections[section].collectibles, collectible)
                    collectibleCount = collectibleCount + 1
                    
                    -- Add animation for collectibles
                    self:AnimateCollectible(collectible)
                end
            end
        end
    end
    
    print(string.format("💎 Generated %d collectibles", collectibleCount))
end

function TrackGeneratorService:GenerateCollectiblesForSection(track, section)
    local config = track.config
    local collectibles = {}
    
    local sectionZ = config.position.Z + (section * TRACK_CONFIG.sectionLength)
    local laneWidth = config.width / config.lanes
    
    -- Random collectible type
    local collectibleTypes = {"coin", "gem"}
    local collectibleType = collectibleTypes[math.random(1, #collectibleTypes)]
    
    -- Place 1-3 collectibles in this section
    local numCollectibles = math.random(1, 3)
    
    for i = 1, numCollectibles do
        local lane = math.random(1, config.lanes)
        local collectible = self:CreateCollectible(collectibleType, {
            position = Vector3.new(
                config.position.X - (config.width/2) + ((lane - 0.5) * laneWidth),
                config.position.Y + 3,
                sectionZ + math.random(-20, 20)
            )
        })
        
        table.insert(collectibles, collectible)
    end
    
    return collectibles
end

function TrackGeneratorService:CreateCollectible(templateName, options)
    local template = TRACK_CONFIG.collectibleTemplates[templateName]
    if not template then
        warn("Unknown collectible template: " .. templateName)
        template = TRACK_CONFIG.collectibleTemplates.coin
    end
    
    local collectible
    
    if template.shape == "Cylinder" then
        collectible = Instance.new("Part")
        collectible.Shape = Enum.PartType.Cylinder
    else
        collectible = Instance.new("Part")
    end
    
    collectible.Size = template.size
    collectible.Material = template.material
    collectible.CanCollide = template.canCollide
    collectible.Transparency = template.transparency
    collectible.Anchored = true
    collectible.Position = options.position
    collectible.Color = template.color
    
    -- Add glowing effect
    local pointLight = Instance.new("PointLight")
    pointLight.Brightness = 2
    pointLight.Color = template.color
    pointLight.Range = 20
    pointLight.Parent = collectible
    
    -- Add collection handling
    collectible.Touched:Connect(function(hit)
        self:HandleCollectibleCollection(collectible, hit)
    end)
    
    collectible.Name = string.format("Collectible_%s_%s", templateName, HttpService:GenerateGUID(false):sub(1, 8))
    
    return collectible
end

function TrackGeneratorService:AnimateCollectible(collectible)
    local template = nil
    
    -- Find template type
    for typeName, typeTemplate in pairs(TRACK_CONFIG.collectibleTemplates) do
        if collectible.Name:find(typeName) then
            template = typeTemplate
            break
        end
    end
    
    if not template then return end
    
    -- Rotation animation
    if template.rotationSpeed then
        spawn(function()
            while collectible.Parent do
                collectible.Rotation = collectible.Rotation + Vector3.new(0, template.rotationSpeed, 0)
                wait(0.1)
            end
        end)
    end
    
    -- Bounce animation
    if template.bounceHeight then
        local originalY = collectible.Position.Y
        local tweenInfo = TweenInfo.new(2, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true)
        
        local tween = TweenService:Create(collectible, tweenInfo, {
            Position = collectible.Position + Vector3.new(0, template.bounceHeight, 0)
        })
        
        tween:Play()
    end
end

function TrackGeneratorService:GenerateStartFinishLines(track)
    local config = track.config
    local effectsFolder = Workspace.Tracks.Effects
    
    -- Start line
    local startLine = Instance.new("Part")
    startLine.Name = string.format("StartLine_%s", track.id)
    startLine.Anchored = true
    startLine.CanCollide = false
    startLine.Size = Vector3.new(config.width, 10, 2)
    startLine.Position = Vector3.new(
        config.position.X,
        config.position.Y + 5,
        config.position.Z - 10
    )
    startLine.Material = Enum.Material.Neon
    startLine.BrickColor = BrickColor.new("Bright green")
    startLine.Transparency = 0.3
    
    -- Add start line effects
    local startLight = Instance.new("PointLight")
    startLight.Brightness = 3
    startLight.Color = Color3.fromRGB(0, 255, 0)
    startLight.Range = 30
    startLight.Parent = startLine
    
    startLine:SetAttribute("TrackId", track.id)
    startLine:SetAttribute("StartLine", true)
    startLine:SetAttribute("GeneratedTrack", true)
    startLine.Parent = effectsFolder
    table.insert(track.effects, startLine)
    
    -- Finish line
    local finishLine = Instance.new("Part")
    finishLine.Name = string.format("FinishLine_%s", track.id)
    finishLine.Anchored = true
    finishLine.CanCollide = false
    finishLine.Size = Vector3.new(config.width, 10, 2)
    finishLine.Position = Vector3.new(
        config.position.X,
        config.position.Y + 5,
        config.position.Z + config.length + 10
    )
    finishLine.Material = Enum.Material.Neon
    finishLine.BrickColor = BrickColor.new("Bright red")
    finishLine.Transparency = 0.3
    
    -- Add finish line effects
    local finishLight = Instance.new("PointLight")
    finishLight.Brightness = 3
    finishLight.Color = Color3.fromRGB(255, 0, 0)
    finishLight.Range = 30
    finishLight.Parent = finishLine
    
    -- Add finish line detection
    finishLine.Touched:Connect(function(hit)
        self:HandleFinishLineTouch(finishLine, hit)
    end)
    
    finishLine:SetAttribute("TrackId", track.id)
    finishLine:SetAttribute("FinishLine", true)
    finishLine:SetAttribute("GeneratedTrack", true)
    finishLine.Parent = effectsFolder
    table.insert(track.effects, finishLine)
    
    print("🏁 Generated start and finish lines")
end

function TrackGeneratorService:GenerateTrackEffects(track)
    local config = track.config
    local effectsFolder = Workspace.Tracks.Effects
    
    -- Add checkpoint markers every 100 studs
    local checkpointInterval = 100
    local checkpointCount = math.floor(config.length / checkpointInterval)
    
    for i = 1, checkpointCount do
        local checkpointZ = config.position.Z + (i * checkpointInterval)
        
        local checkpoint = Instance.new("Part")
        checkpoint.Name = string.format("Checkpoint_%s_%d", track.id, i)
        checkpoint.Anchored = true
        checkpoint.CanCollide = false
        checkpoint.Size = Vector3.new(config.width, 8, 1)
        checkpoint.Position = Vector3.new(
            config.position.X,
            config.position.Y + 4,
            checkpointZ
        )
        checkpoint.Material = Enum.Material.ForceField
        checkpoint.BrickColor = BrickColor.new("Bright blue")
        checkpoint.Transparency = 0.7
        
        -- Add checkpoint light
        local checkpointLight = Instance.new("PointLight")
        checkpointLight.Brightness = 1.5
        checkpointLight.Color = Color3.fromRGB(0, 0, 255)
        checkpointLight.Range = 25
        checkpointLight.Parent = checkpoint
        
        -- Add checkpoint detection
        checkpoint.Touched:Connect(function(hit)
            self:HandleCheckpointTouch(checkpoint, hit, i)
        end)
        
        checkpoint:SetAttribute("TrackId", track.id)
        checkpoint:SetAttribute("Checkpoint", i)
        checkpoint:SetAttribute("GeneratedTrack", true)
        checkpoint.Parent = effectsFolder
        table.insert(track.effects, checkpoint)
    end
    
    print(string.format("🎯 Generated %d checkpoints", checkpointCount))
end

-- Clear track function
function TrackGeneratorService:ClearTrack(trackId)
    if trackId then
        -- Clear specific track
        local track = activeTracks[trackId]
        if track then
            self:ClearTrackObjects(trackId)
            activeTracks[trackId] = nil
            print("🗑️ Cleared track: " .. trackId)
        else
            warn("Track not found: " .. trackId)
        end
    else
        -- Clear all tracks
        for id, track in pairs(activeTracks) do
            self:ClearTrackObjects(id)
        end
        activeTracks = {}
        print("🗑️ Cleared all tracks")
    end
end

function TrackGeneratorService:ClearTrackObjects(trackId)
    local tracksFolder = Workspace:FindFirstChild("Tracks")
    if not tracksFolder then return end
    
    local objectsRemoved = 0
    
    -- Search all track subfolders
    for _, folder in ipairs(tracksFolder:GetChildren()) do
        if folder:IsA("Folder") then
            for _, object in ipairs(folder:GetChildren()) do
                if object:GetAttribute("TrackId") == trackId then
                    object:Destroy()
                    objectsRemoved = objectsRemoved + 1
                end
            end
        end
    end
    
    print(string.format("🗑️ Removed %d objects for track: %s", objectsRemoved, trackId))
end

-- Utility functions
function TrackGeneratorService:GenerateTrackId()
    trackCounter = trackCounter + 1
    return string.format("Track_%d_%s", trackCounter, HttpService:GenerateGUID(false):sub(1, 8))
end

function TrackGeneratorService:GetObstaclePattern(layout, difficulty)
    local patterns = {
        straight = "regular",
        alternating = "alternating", 
        spiral = "spiral",
        maze = "maze",
        speed = "speed"
    }
    
    return patterns[layout] or "regular"
end

function TrackGeneratorService:GetRandomObstacleColor(config)
    local colors = {}
    for colorName, color in pairs(TRACK_CONFIG.trackColors) do
        if colorName ~= "Neutral" then
            table.insert(colors, color)
        end
    end
    
    return colors[math.random(1, #colors)]
end

-- Event handlers
function TrackGeneratorService:HandleObstacleCollision(obstacle, hit)
    local character = hit.Parent
    local humanoid = character:FindFirstChildOfClass("Humanoid")
    if not humanoid then return end
    
    local player = game.Players:GetPlayerFromCharacter(character)
    if not player then return end
    
    -- Notify game controller of collision
    local remoteEvents = ReplicatedStorage:FindFirstChild("Events")
    if remoteEvents and remoteEvents:FindFirstChild("ObstacleHit") then
        remoteEvents.ObstacleHit:FireAllClients(player, obstacle.Name)
    end
    
    print("💥 " .. player.Name .. " hit obstacle: " .. obstacle.Name)
end

function TrackGeneratorService:HandleCollectibleCollection(collectible, hit)
    local character = hit.Parent
    local humanoid = character:FindFirstChildOfClass("Humanoid")
    if not humanoid then return end
    
    local player = game.Players:GetPlayerFromCharacter(character)
    if not player then return end
    
    -- Notify game controller of collection
    local remoteEvents = ReplicatedStorage:FindFirstChild("Events")
    if remoteEvents and remoteEvents:FindFirstChild("CollectibleCollected") then
        remoteEvents.CollectibleCollected:FireAllClients(player, collectible.Name)
    end
    
    -- Remove collectible with effect
    local disappearTween = TweenService:Create(collectible, 
        TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.In), 
        {Transparency = 1, Size = collectible.Size * 2}
    )
    
    disappearTween:Play()
    disappearTween.Completed:Connect(function()
        collectible:Destroy()
    end)
    
    print("💎 " .. player.Name .. " collected: " .. collectible.Name)
end

function TrackGeneratorService:HandleFinishLineTouch(finishLine, hit)
    local character = hit.Parent
    local humanoid = character:FindFirstChildOfClass("Humanoid")
    if not humanoid then return end
    
    local player = game.Players:GetPlayerFromCharacter(character)
    if not player then return end
    
    local trackId = finishLine:GetAttribute("TrackId")
    
    -- Notify game controller of finish
    local remoteEvents = ReplicatedStorage:FindFirstChild("Events")
    if remoteEvents and remoteEvents:FindFirstChild("PlayerFinished") then
        remoteEvents.PlayerFinished:FireAllClients(player, trackId)
    end
    
    print("🏆 " .. player.Name .. " finished track: " .. trackId)
end

function TrackGeneratorService:HandleCheckpointTouch(checkpoint, hit, checkpointNumber)
    local character = hit.Parent
    local humanoid = character:FindFirstChildOfClass("Humanoid")
    if not humanoid then return end
    
    local player = game.Players:GetPlayerFromCharacter(character)
    if not player then return end
    
    local trackId = checkpoint:GetAttribute("TrackId")
    
    -- Notify game controller of checkpoint
    local remoteEvents = ReplicatedStorage:FindFirstChild("Events")
    if remoteEvents and remoteEvents:FindFirstChild("CheckpointReached") then
        remoteEvents.CheckpointReached:FireAllClients(player, checkpointNumber, trackId)
    end
    
    print("🎯 " .. player.Name .. " reached checkpoint " .. checkpointNumber)
end

-- Track management functions
function TrackGeneratorService:GetTrack(trackId)
    return activeTracks[trackId]
end

function TrackGeneratorService:GetAllTracks()
    return activeTracks
end

function TrackGeneratorService:GetTrackCount()
    local count = 0
    for _ in pairs(activeTracks) do
        count = count + 1
    end
    return count
end

function TrackGeneratorService:GetPerformanceMetrics()
    return performanceMetrics
end

function TrackGeneratorService:GetAvailableLayouts()
    return TRACK_LAYOUTS
end

function TrackGeneratorService:GetObstacleTemplates()
    return TRACK_CONFIG.obstacleTemplates
end

-- Advanced generation functions
function TrackGeneratorService:GenerateRandomTrack(difficulty)
    difficulty = difficulty or math.random(1, 4)
    
    local layouts = {"straight", "alternating", "spiral", "maze", "speed"}
    local layout = layouts[math.random(1, #layouts)]
    
    local config = {
        length = 300 + (difficulty * 100),
        width = 60 - (difficulty * 5),
        lanes = math.min(6, 2 + difficulty),
        layout = layout,
        difficulty = difficulty,
        obstacleFrequency = 0.1 + (difficulty * 0.1),
        collectibleFrequency = 0.3 - (difficulty * 0.05)
    }
    
    return self:GenerateTrack(config)
end

function TrackGeneratorService:GenerateSpeedTrack(length)
    local config = {
        length = length or 800,
        width = 60,
        lanes = 3,
        layout = "speed",
        difficulty = 2,
        obstacleFrequency = 0.1,
        collectibleFrequency = 0.4
    }
    
    return self:GenerateTrack(config)
end

function TrackGeneratorService:GenerateMazeTrack(complexity)
    complexity = complexity or 3
    
    local config = {
        length = 400 + (complexity * 50),
        width = 40 + (complexity * 10),
        lanes = 4 + complexity,
        layout = "maze",
        difficulty = complexity,
        obstacleFrequency = 0.4 + (complexity * 0.1),
        collectibleFrequency = 0.2
    }
    
    return self:GenerateTrack(config)
end

return TrackGeneratorService
