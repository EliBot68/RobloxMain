-- ThumbnailSceneSetup.server.luau
-- Server-side scene management for thumbnail photography
-- Creates and manages props, effects, and staging for professional thumbnails

local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")

local ThumbnailSceneSetup = {}

-- Scene Configuration
local SCENE_CONFIGS = {
    ActionShot = {
        obstacles = {
            {type = "RedBarrier", position = Vector3.new(-5, 5, 0), size = Vector3.new(2, 8, 1), color = Color3.fromRGB(255, 100, 100)},
            {type = "RedBarrier", position = Vector3.new(3, 3, -2), size = Vector3.new(1, 6, 2), color = Color3.fromRGB(255, 80, 80)},
            {type = "GreenSafe", position = Vector3.new(8, 2, 1), size = Vector3.new(3, 4, 1), color = Color3.fromRGB(100, 255, 100)}
        },
        effects = {
            speedLines = true,
            particleTrails = true,
            energyFields = true
        },
        track = {
            width = 20,
            length = 100,
            material = Enum.Material.Neon,
            color = Color3.fromRGB(100, 200, 255)
        }
    },
    
    GroupShot = {
        startingPositions = {
            Vector3.new(-6, 0, 0),
            Vector3.new(-2, 0, 0),
            Vector3.new(2, 0, 0),
            Vector3.new(6, 0, 0)
        },
        track = {
            width = 30,
            length = 200,
            lanes = 4,
            material = Enum.Material.SmoothPlastic,
            color = Color3.fromRGB(200, 200, 255)
        },
        stadium = {
            createStands = true,
            spectatorCount = 50,
            lightingRigs = true
        },
        finishLine = {
            position = Vector3.new(0, 0, 50),
            width = 35,
            height = 10
        }
    },
    
    Cinematic = {
        arena = {
            radius = 100,
            height = 50,
            wallSections = 12,
            materialPrimary = Enum.Material.Metal,
            materialAccent = Enum.Material.Neon
        },
        environment = {
            skybox = "Futuristic",
            atmosphere = true,
            volumetricLighting = true
        },
        effects = {
            holographicDisplays = true,
            energyBeams = true,
            particleSystems = true,
            lightingAnimation = true
        }
    }
}

-- Scene Storage
local activeScenes = {}
local sceneFolder = nil

function ThumbnailSceneSetup:Init()
    print("🎬 Initializing Thumbnail Scene Setup...")
    
    -- Create scene folder
    sceneFolder = Instance.new("Folder")
    sceneFolder.Name = "ThumbnailScenes"
    sceneFolder.Parent = Workspace
    
    print("✅ Thumbnail Scene Setup ready!")
    print("📋 Use :CreateScene(sceneName) to build thumbnail scenes")
end

function ThumbnailSceneSetup:CreateScene(sceneName)
    local config = SCENE_CONFIGS[sceneName]
    if not config then
        warn("❌ Scene '" .. sceneName .. "' not found!")
        return
    end
    
    print("🎬 Creating scene: " .. sceneName)
    
    -- Clear existing scene
    self:ClearScene(sceneName)
    
    -- Create scene container
    local sceneContainer = Instance.new("Model")
    sceneContainer.Name = sceneName .. "Scene"
    sceneContainer.Parent = sceneFolder
    
    activeScenes[sceneName] = sceneContainer
    
    -- Build scene based on type
    if sceneName == "ActionShot" then
        self:BuildActionScene(sceneContainer, config)
    elseif sceneName == "GroupShot" then
        self:BuildGroupScene(sceneContainer, config)
    elseif sceneName == "Cinematic" then
        self:BuildCinematicScene(sceneContainer, config)
    end
    
    print("✅ Scene '" .. sceneName .. "' created successfully!")
end

function ThumbnailSceneSetup:BuildActionScene(container, config)
    print("🏃 Building action scene...")
    
    -- Create dynamic track
    local track = self:CreateTrack(config.track, container)
    
    -- Create obstacles with motion
    for i, obstacleConfig in ipairs(config.obstacles) do
        local obstacle = self:CreateObstacle(obstacleConfig, container)
        
        -- Add motion to obstacles
        if obstacleConfig.type == "RedBarrier" then
            self:AnimateObstacle(obstacle, "slide", 3.0)
        end
    end
    
    -- Add speed effect elements
    if config.effects.speedLines then
        self:CreateSpeedLines(container)
    end
    
    if config.effects.particleTrails then
        self:CreateParticleTrails(container)
    end
    
    if config.effects.energyFields then
        self:CreateEnergyFields(container)
    end
    
    -- Create environmental props
    self:CreateActionEnvironment(container)
end

function ThumbnailSceneSetup:BuildGroupScene(container, config)
    print("👥 Building group scene...")
    
    -- Create wide racing track
    local track = self:CreateMultiLaneTrack(config.track, container)
    
    -- Create stadium environment
    if config.stadium.createStands then
        self:CreateStadiumStands(container, config.stadium)
    end
    
    -- Create finish line
    local finishLine = self:CreateFinishLine(config.finishLine, container)
    
    -- Add crowd and atmosphere
    self:CreateCrowdEffects(container)
    
    -- Create starting platforms
    for i, position in ipairs(config.startingPositions) do
        self:CreateStartingPlatform(position, i, container)
    end
    
    -- Add competitive elements
    self:CreateLeaderboard(container)
    self:CreateSpotlights(container)
end

function ThumbnailSceneSetup:BuildCinematicScene(container, config)
    print("🌌 Building cinematic scene...")
    
    -- Create massive arena structure
    local arena = self:CreateArena(config.arena, container)
    
    -- Create futuristic environment
    if config.environment.skybox then
        self:SetupCinematicSkybox(config.environment.skybox)
    end
    
    -- Add dramatic effects
    if config.effects.holographicDisplays then
        self:CreateHolographicDisplays(container)
    end
    
    if config.effects.energyBeams then
        self:CreateEnergyBeams(container)
    end
    
    if config.effects.particleSystems then
        self:CreateAtmosphericParticles(container)
    end
    
    -- Create architectural details
    self:CreateArchitecturalDetails(container)
    
    -- Setup dramatic lighting
    if config.effects.lightingAnimation then
        self:CreateAnimatedLighting(container)
    end
end

-- Obstacle Creation Functions
function ThumbnailSceneSetup:CreateObstacle(obstacleConfig, parent)
    local obstacle = Instance.new("Part")
    obstacle.Name = obstacleConfig.type
    obstacle.Size = obstacleConfig.size
    obstacle.Position = obstacleConfig.position
    obstacle.Material = Enum.Material.ForceField
    obstacle.Color = obstacleConfig.color
    obstacle.Anchored = true
    obstacle.CanCollide = false
    obstacle.Parent = parent
    
    -- Add glow effect
    local pointLight = Instance.new("PointLight")
    pointLight.Brightness = 2
    pointLight.Range = 20
    pointLight.Color = obstacleConfig.color
    pointLight.Parent = obstacle
    
    -- Add selection box for visibility
    local selectionBox = Instance.new("SelectionBox")
    selectionBox.Adornee = obstacle
    selectionBox.Color3 = obstacleConfig.color
    selectionBox.LineThickness = 0.2
    selectionBox.Transparency = 0.5
    selectionBox.Parent = obstacle
    
    return obstacle
end

function ThumbnailSceneSetup:CreateTrack(trackConfig, parent)
    local track = Instance.new("Part")
    track.Name = "MainTrack"
    track.Size = Vector3.new(trackConfig.width, 1, trackConfig.length)
    track.Position = Vector3.new(0, -0.5, 0)
    track.Material = trackConfig.material
    track.Color = trackConfig.color
    track.Anchored = true
    track.CanCollide = true
    track.Parent = parent
    
    -- Add track lighting strips
    for i = 1, 10 do
        local lightStrip = Instance.new("Part")
        lightStrip.Name = "LightStrip" .. i
        lightStrip.Size = Vector3.new(1, 0.2, trackConfig.length)
        lightStrip.Position = Vector3.new(-trackConfig.width/2 + (i-1) * trackConfig.width/10, 0.5, 0)
        lightStrip.Material = Enum.Material.Neon
        lightStrip.Color = Color3.fromRGB(255, 255, 255)
        lightStrip.Anchored = true
        lightStrip.CanCollide = false
        lightStrip.Parent = parent
        
        -- Animate light strips
        self:AnimateLightStrip(lightStrip, i * 0.2)
    end
    
    return track
end

function ThumbnailSceneSetup:CreateMultiLaneTrack(trackConfig, parent)
    local mainTrack = Instance.new("Part")
    mainTrack.Name = "MultiLaneTrack"
    mainTrack.Size = Vector3.new(trackConfig.width, 1, trackConfig.length)
    mainTrack.Position = Vector3.new(0, -0.5, 0)
    mainTrack.Material = trackConfig.material
    mainTrack.Color = trackConfig.color
    mainTrack.Anchored = true
    mainTrack.CanCollide = true
    mainTrack.Parent = parent
    
    -- Create lane dividers
    for i = 1, trackConfig.lanes - 1 do
        local divider = Instance.new("Part")
        divider.Name = "LaneDivider" .. i
        divider.Size = Vector3.new(0.2, 0.5, trackConfig.length)
        divider.Position = Vector3.new(-trackConfig.width/2 + i * (trackConfig.width/trackConfig.lanes), 0.25, 0)
        divider.Material = Enum.Material.Neon
        divider.Color = Color3.fromRGB(255, 255, 0)
        divider.Anchored = true
        divider.CanCollide = false
        divider.Parent = parent
    end
    
    return mainTrack
end

function ThumbnailSceneSetup:CreateArena(arenaConfig, parent)
    local arenaModel = Instance.new("Model")
    arenaModel.Name = "FuturisticArena"
    arenaModel.Parent = parent
    
    -- Create arena walls
    for i = 1, arenaConfig.wallSections do
        local angle = (i - 1) * (360 / arenaConfig.wallSections)
        local radians = math.rad(angle)
        
        local wall = Instance.new("Part")
        wall.Name = "ArenaWall" .. i
        wall.Size = Vector3.new(15, arenaConfig.height, 3)
        wall.Position = Vector3.new(
            math.cos(radians) * arenaConfig.radius,
            arenaConfig.height / 2,
            math.sin(radians) * arenaConfig.radius
        )
        wall.Rotation = Vector3.new(0, math.deg(radians), 0)
        wall.Material = arenaConfig.materialPrimary
        wall.Color = Color3.fromRGB(100, 100, 120)
        wall.Anchored = true
        wall.Parent = arenaModel
        
        -- Add neon accents
        local accent = Instance.new("Part")
        accent.Name = "WallAccent" .. i
        accent.Size = Vector3.new(12, 2, 0.5)
        accent.Position = wall.Position + Vector3.new(0, 0, 2)
        accent.Rotation = wall.Rotation
        accent.Material = arenaConfig.materialAccent
        accent.Color = Color3.fromRGB(0, 255, 255)
        accent.Anchored = true
        accent.Parent = arenaModel
        
        -- Animate accent lighting
        self:AnimateNeonAccent(accent, i * 0.1)
    end
    
    return arenaModel
end

-- Effect Creation Functions
function ThumbnailSceneSetup:CreateSpeedLines(parent)
    for i = 1, 20 do
        local speedLine = Instance.new("Part")
        speedLine.Name = "SpeedLine" .. i
        speedLine.Size = Vector3.new(0.1, 0.1, 10)
        speedLine.Position = Vector3.new(
            math.random(-15, 15),
            math.random(2, 8),
            math.random(-20, 20)
        )
        speedLine.Material = Enum.Material.Neon
        speedLine.Color = Color3.fromRGB(255, 255, 255)
        speedLine.Anchored = true
        speedLine.CanCollide = false
        speedLine.Transparency = 0.3
        speedLine.Parent = parent
        
        -- Animate speed lines
        self:AnimateSpeedLine(speedLine)
    end
end

function ThumbnailSceneSetup:CreateParticleTrails(parent)
    local attachment = Instance.new("Attachment")
    attachment.Position = Vector3.new(0, 5, 0)
    
    local trail = Instance.new("Trail")
    trail.Attachment0 = attachment
    trail.Attachment1 = attachment
    trail.Lifetime = 2.0
    trail.MinLength = 0.1
    trail.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Color3.fromRGB(100, 255, 255)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 100, 255))
    })
    trail.Transparency = NumberSequence.new({
        NumberSequenceKeypoint.new(0, 0),
        NumberSequenceKeypoint.new(1, 1)
    })
    trail.Parent = attachment
    
    -- Create invisible part to hold attachment
    local trailPart = Instance.new("Part")
    trailPart.Name = "TrailHolder"
    trailPart.Size = Vector3.new(1, 1, 1)
    trailPart.Transparency = 1
    trailPart.CanCollide = false
    trailPart.Anchored = true
    trailPart.Parent = parent
    
    attachment.Parent = trailPart
end

function ThumbnailSceneSetup:CreateFinishLine(finishConfig, parent)
    local finishLine = Instance.new("Part")
    finishLine.Name = "FinishLine"
    finishLine.Size = Vector3.new(finishConfig.width, finishConfig.height, 1)
    finishLine.Position = finishConfig.position
    finishLine.Material = Enum.Material.Neon
    finishLine.Color = Color3.fromRGB(255, 255, 0)
    finishLine.Anchored = true
    finishLine.CanCollide = false
    finishLine.Parent = parent
    
    -- Add checkered pattern
    for x = 1, 6 do
        for y = 1, 4 do
            if (x + y) % 2 == 0 then
                local checker = Instance.new("Part")
                checker.Name = "Checker"
                checker.Size = Vector3.new(finishConfig.width/6, finishConfig.height/4, 0.2)
                checker.Position = finishLine.Position + Vector3.new(
                    -finishConfig.width/2 + (x-0.5) * finishConfig.width/6,
                    -finishConfig.height/2 + (y-0.5) * finishConfig.height/4,
                    0.5
                )
                checker.Material = Enum.Material.SmoothPlastic
                checker.Color = Color3.new(0, 0, 0)
                checker.Anchored = true
                checker.CanCollide = false
                checker.Parent = parent
            end
        end
    end
    
    return finishLine
end

-- Animation Functions
function ThumbnailSceneSetup:AnimateObstacle(obstacle, animationType, duration)
    if animationType == "slide" then
        local startPos = obstacle.Position
        local endPos = startPos + Vector3.new(10, 0, 0)
        
        local tweenInfo = TweenInfo.new(
            duration,
            Enum.EasingStyle.Sine,
            Enum.EasingDirection.InOut,
            -1,  -- Repeat infinitely
            true -- Reverse
        )
        
        local tween = TweenService:Create(obstacle, tweenInfo, {Position = endPos})
        tween:Play()
    end
end

function ThumbnailSceneSetup:AnimateLightStrip(lightStrip, delay)
    spawn(function()
        wait(delay)
        
        while lightStrip.Parent do
            -- Pulse animation
            local brightTween = TweenService:Create(
                lightStrip,
                TweenInfo.new(1.0, Enum.EasingStyle.Sine),
                {Transparency = 0}
            )
            
            local dimTween = TweenService:Create(
                lightStrip,
                TweenInfo.new(1.0, Enum.EasingStyle.Sine),
                {Transparency = 0.8}
            )
            
            brightTween:Play()
            brightTween.Completed:Wait()
            dimTween:Play()
            dimTween.Completed:Wait()
        end
    end)
end

function ThumbnailSceneSetup:AnimateSpeedLine(speedLine)
    spawn(function()
        while speedLine.Parent do
            local moveDistance = 30
            local startPos = speedLine.Position
            local endPos = startPos + Vector3.new(0, 0, moveDistance)
            
            local moveTween = TweenService:Create(
                speedLine,
                TweenInfo.new(0.5, Enum.EasingStyle.Linear),
                {Position = endPos, Transparency = 1}
            )
            
            moveTween:Play()
            moveTween.Completed:Wait()
            
            -- Reset position
            speedLine.Position = startPos
            speedLine.Transparency = 0.3
            
            wait(math.random(1, 3))
        end
    end)
end

-- Utility Functions
function ThumbnailSceneSetup:ClearScene(sceneName)
    if activeScenes[sceneName] then
        activeScenes[sceneName]:Destroy()
        activeScenes[sceneName] = nil
        print("🧹 Cleared existing " .. sceneName .. " scene")
    end
end

function ThumbnailSceneSetup:ClearAllScenes()
    for sceneName, scene in pairs(activeScenes) do
        scene:Destroy()
        activeScenes[sceneName] = nil
    end
    print("🧹 All thumbnail scenes cleared")
end

function ThumbnailSceneSetup:ListAvailableScenes()
    print("\n📋 Available Thumbnail Scenes:")
    print("=" .. string.rep("=", 30))
    
    for sceneName, config in pairs(SCENE_CONFIGS) do
        print("🎬 " .. sceneName)
        if sceneName == "ActionShot" then
            print("   - Dynamic obstacles and speed effects")
        elseif sceneName == "GroupShot" then
            print("   - Multi-lane track with stadium")
        elseif sceneName == "Cinematic" then
            print("   - Epic arena with atmospheric effects")
        end
    end
    
    print("\n🎮 Commands:")
    print("  :CreateScene('ActionShot')")
    print("  :CreateScene('GroupShot')")
    print("  :CreateScene('Cinematic')")
    print("  :ClearAllScenes()")
    print("=" .. string.rep("=", 30))
end

-- Initialize
ThumbnailSceneSetup:Init()
ThumbnailSceneSetup:ListAvailableScenes()

return ThumbnailSceneSetup
