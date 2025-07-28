-- HubService.luau
-- Manages the market-style spawn hub area

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local SoundService = game:GetService("SoundService")
local RunService = game:GetService("RunService")
local Lighting = game:GetService("Lighting")

local RemoteEvents = require(ReplicatedStorage.Shared.modules.RemoteEvents)

local HubService = {}

-- Hub configuration
local HUB_CONFIG = {
    size = Vector3.new(200, 20, 200), -- Hub area dimensions
    center = Vector3.new(0, 10, 0), -- Hub center position
    playPortalPosition = Vector3.new(0, 5, -30), -- Main play portal location
    queueAreaPosition = Vector3.new(-15, 2, -30), -- Queue area next to portal
    
    -- Market stall positions (relative to center)
    stalls = {
        {name = "Pet Shop", position = Vector3.new(-40, 0, 20), rotation = 45},
        {name = "Upgrade Stall", position = Vector3.new(40, 0, 20), rotation = -45},
        {name = "Crate Stall", position = Vector3.new(-40, 0, -10), rotation = 135},
        {name = "Cosmetic Boutique", position = Vector3.new(40, 0, -10), rotation = -135},
        {name = "Quest Board", position = Vector3.new(0, 0, 40), rotation = 180},
        {name = "Tournament Arena", position = Vector3.new(-20, 0, 50), rotation = 225},
        {name = "Mystery Shop", position = Vector3.new(20, 0, 50), rotation = 315}
    },
    
    -- NPC spawn points
    npcs = {
        {name = "Merchant", position = Vector3.new(-35, 0, 25), animation = "browsing"},
        {name = "Customer", position = Vector3.new(35, 0, 25), animation = "shopping"},
        {name = "Guard", position = Vector3.new(0, 0, 60), animation = "patrolling"},
        {name = "Vendor", position = Vector3.new(-35, 0, -5), animation = "selling"},
        {name = "Collector", position = Vector3.new(35, 0, -5), animation = "examining"},
        {name = "Announcer", position = Vector3.new(-15, 0, 55), animation = "calling"},
        {name = "Spectator", position = Vector3.new(15, 0, 55), animation = "watching"}
    }
}

-- Hub objects storage
local hubObjects = {
    ground = nil,
    playPortal = nil,
    stalls = {},
    npcs = {},
    decorations = {},
    sounds = {}
}

function HubService:CreateHubGround()
    -- Create main hub platform
    local ground = Instance.new("Part")
    ground.Name = "HubGround"
    ground.Size = HUB_CONFIG.size
    ground.Position = HUB_CONFIG.center
    ground.Anchored = true
    ground.CanCollide = true
    ground.Material = Enum.Material.Cobblestone
    ground.Color = Color3.fromRGB(120, 100, 80)
    ground.TopSurface = Enum.SurfaceType.Smooth
    ground.Parent = Workspace
    
    -- Add decorative texture
    local decal = Instance.new("Decal")
    decal.Face = Enum.NormalId.Top
    decal.Texture = "rbxasset://textures/brick.jpg" -- Cobblestone texture
    decal.Parent = ground
    
    -- Create border/walls
    local borderHeight = 5
    local borderThickness = 2
    
    local borders = {
        {size = Vector3.new(HUB_CONFIG.size.X, borderHeight, borderThickness), position = Vector3.new(0, borderHeight/2, HUB_CONFIG.size.Z/2)},
        {size = Vector3.new(HUB_CONFIG.size.X, borderHeight, borderThickness), position = Vector3.new(0, borderHeight/2, -HUB_CONFIG.size.Z/2)},
        {size = Vector3.new(borderThickness, borderHeight, HUB_CONFIG.size.Z), position = Vector3.new(HUB_CONFIG.size.X/2, borderHeight/2, 0)},
        {size = Vector3.new(borderThickness, borderHeight, HUB_CONFIG.size.Z), position = Vector3.new(-HUB_CONFIG.size.X/2, borderHeight/2, 0)}
    }
    
    for _, borderData in pairs(borders) do
        local border = Instance.new("Part")
        border.Name = "HubBorder"
        border.Size = borderData.size
        border.Position = HUB_CONFIG.center + borderData.position
        border.Anchored = true
        border.CanCollide = true
        border.Material = Enum.Material.Stone
        border.Color = Color3.fromRGB(80, 70, 60)
        border.Parent = Workspace
    end
    
    hubObjects.ground = ground
    return ground
end

function HubService:CreatePlayPortal()
    -- Main portal structure
    local portalBase = Instance.new("Part")
    portalBase.Name = "PortalBase"
    portalBase.Size = Vector3.new(12, 2, 12)
    portalBase.Position = HUB_CONFIG.center + HUB_CONFIG.playPortalPosition + Vector3.new(0, 1, 0)
    portalBase.Anchored = true
    portalBase.CanCollide = true
    portalBase.Material = Enum.Material.Marble
    portalBase.Color = Color3.fromRGB(220, 220, 230)
    portalBase.Shape = Enum.PartType.Cylinder
    portalBase.Parent = Workspace
    
    -- Portal ring (visual effect)
    local portalRing = Instance.new("Part")
    portalRing.Name = "PortalRing"
    portalRing.Size = Vector3.new(0.5, 10, 10)
    portalRing.Position = portalBase.Position + Vector3.new(0, 6, 0)
    portalRing.Anchored = true
    portalRing.CanCollide = false
    portalRing.Material = Enum.Material.Neon
    portalRing.Color = Color3.fromRGB(100, 200, 255)
    portalRing.Shape = Enum.PartType.Cylinder
    portalRing.Transparency = 0.3
    portalRing.Parent = Workspace
    
    -- Portal interior effect
    local portalInterior = Instance.new("Part")
    portalInterior.Name = "PortalInterior"
    portalInterior.Size = Vector3.new(0.1, 8, 8)
    portalInterior.Position = portalRing.Position
    portalInterior.Anchored = true
    portalInterior.CanCollide = false
    portalInterior.Material = Enum.Material.ForceField
    portalInterior.Color = Color3.fromRGB(0, 150, 255)
    portalInterior.Shape = Enum.PartType.Cylinder
    portalInterior.Transparency = 0.5
    portalInterior.Parent = Workspace
    
    -- Glowing sign above portal
    local signPost = Instance.new("Part")
    signPost.Name = "SignPost"
    signPost.Size = Vector3.new(1, 8, 1)
    signPost.Position = portalBase.Position + Vector3.new(0, 10, -8)
    signPost.Anchored = true
    signPost.CanCollide = false
    signPost.Material = Enum.Material.Wood
    signPost.Color = Color3.fromRGB(101, 67, 33)
    signPost.Parent = Workspace
    
    local sign = Instance.new("Part")
    sign.Name = "PlaySign"
    sign.Size = Vector3.new(8, 3, 0.5)
    sign.Position = signPost.Position + Vector3.new(0, 3, 0)
    sign.Anchored = true
    sign.CanCollide = false
    sign.Material = Enum.Material.Neon
    sign.Color = Color3.fromRGB(255, 215, 0)
    sign.Parent = Workspace
    
    -- Sign text
    local signGui = Instance.new("SurfaceGui")
    signGui.Face = Enum.NormalId.Front
    signGui.Parent = sign
    
    local signText = Instance.new("TextLabel")
    signText.Size = UDim2.new(1, 0, 1, 0)
    signText.BackgroundTransparency = 1
    signText.Text = "🎮 PLAY GAME 🎮"
    signText.TextColor3 = Color3.fromRGB(0, 0, 0)
    signText.TextScaled = true
    signText.Font = Enum.Font.SourceSansBold
    signText.Parent = signGui
    
    -- Portal animations
    self:AnimatePortal(portalRing, portalInterior)
    self:AnimateSign(sign)
    
    -- Portal interaction
    local clickDetector = Instance.new("ClickDetector")
    clickDetector.MaxActivationDistance = 20
    clickDetector.Parent = portalBase
    
    clickDetector.MouseClick:Connect(function(player)
        self:HandlePortalClick(player)
    end)
    
    hubObjects.playPortal = {
        base = portalBase,
        ring = portalRing,
        interior = portalInterior,
        sign = sign,
        signPost = signPost
    }
    
    return portalBase
end

function HubService:CreateMultiplayerQueue()
    local queuePosition = HUB_CONFIG.center + HUB_CONFIG.queueAreaPosition
    
    -- Queue area platform
    local queuePlatform = Instance.new("Part")
    queuePlatform.Name = "QueuePlatform"
    queuePlatform.Size = Vector3.new(12, 1, 8)
    queuePlatform.Position = queuePosition
    queuePlatform.Anchored = true
    queuePlatform.CanCollide = true
    queuePlatform.Material = Enum.Material.Marble
    queuePlatform.Color = Color3.fromRGB(100, 255, 150)
    queuePlatform.Shape = Enum.PartType.Block
    queuePlatform.Parent = Workspace
    
    -- Add glowing effect
    local queueGlow = Instance.new("PointLight")
    queueGlow.Color = Color3.fromRGB(100, 255, 150)
    queueGlow.Brightness = 2
    queueGlow.Range = 15
    queueGlow.Parent = queuePlatform
    
    -- Queue sign post
    local signPost = Instance.new("Part")
    signPost.Name = "QueueSignPost"
    signPost.Size = Vector3.new(0.5, 8, 0.5)
    signPost.Position = queuePosition + Vector3.new(0, 4.5, -3)
    signPost.Anchored = true
    signPost.CanCollide = false
    signPost.Material = Enum.Material.Wood
    signPost.Color = Color3.fromRGB(139, 90, 43)
    signPost.Parent = Workspace
    
    -- Queue sign
    local queueSign = Instance.new("Part")
    queueSign.Name = "QueueSign"
    queueSign.Size = Vector3.new(8, 4, 0.2)
    queueSign.Position = signPost.Position + Vector3.new(0, 2, 0)
    queueSign.Anchored = true
    queueSign.CanCollide = false
    queueSign.Material = Enum.Material.SmoothPlastic
    queueSign.Color = Color3.fromRGB(50, 150, 255)
    queueSign.Parent = Workspace
    
    -- Sign GUI
    local signGui = Instance.new("SurfaceGui")
    signGui.Face = Enum.NormalId.Front
    signGui.Parent = queueSign
    
    local signText = Instance.new("TextLabel")
    signText.Size = UDim2.new(1, 0, 1, 0)
    signText.BackgroundTransparency = 1
    signText.Text = "👥 GROUP RUN QUEUE\n\nWalk here to join\nmultiplayer game!"
    signText.TextColor3 = Color3.fromRGB(255, 255, 255)
    signText.TextScaled = true
    signText.Font = Enum.Font.SourceSansBold
    signText.Parent = signGui
    
    -- Queue waiting spots (visual indicators)
    local waitingSpots = {}
    for i = 1, 6 do
        local spot = Instance.new("Part")
        spot.Name = "QueueSpot" .. i
        spot.Size = Vector3.new(1.5, 0.2, 1.5)
        spot.Position = queuePosition + Vector3.new(
            ((i - 1) % 3 - 1) * 3, -- X: -3, 0, 3, then repeat
            0.6, -- Y: slightly above platform
            math.floor((i - 1) / 3) * 2 - 1 -- Z: -1, -1, -1, 1, 1, 1
        )
        spot.Anchored = true
        spot.CanCollide = false
        spot.Material = Enum.Material.Neon
        spot.Color = Color3.fromRGB(150, 255, 150)
        spot.Shape = Enum.PartType.Cylinder
        spot.Transparency = 0.3
        spot.Parent = Workspace
        
        -- Add pulsing animation
        local pulseTween = TweenService:Create(
            spot,
            TweenInfo.new(2, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true),
            {Transparency = 0.8}
        )
        pulseTween:Play()
        
        table.insert(waitingSpots, spot)
    end
    
    -- Add floating particles
    local attachment = Instance.new("Attachment")
    attachment.Parent = queuePlatform
    
    local particles = Instance.new("ParticleEmitter")
    particles.Parent = attachment
    particles.Enabled = true
    particles.Lifetime = NumberRange.new(2, 4)
    particles.Rate = 50
    particles.SpreadAngle = Vector2.new(45, 45)
    particles.Speed = NumberRange.new(5, 10)
    particles.Color = ColorSequence.new{
        ColorSequenceKeypoint.new(0, Color3.fromRGB(100, 255, 150)),
        ColorSequenceKeypoint.new(0.5, Color3.fromRGB(150, 255, 200)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(200, 255, 100))
    }
    particles.Texture = "rbxasset://textures/particles/sparkles_main.dds"
    
    -- Setup queue area detection
    local queueDetector = Instance.new("Part")
    queueDetector.Name = "QueueDetector"
    queueDetector.Size = Vector3.new(14, 6, 10)
    queueDetector.Position = queuePosition + Vector3.new(0, 3, 0)
    queueDetector.Anchored = true
    queueDetector.CanCollide = false
    queueDetector.Transparency = 1
    queueDetector.Parent = Workspace
    
    -- Queue area interaction
    queueDetector.Touched:Connect(function(hit)
        local character = hit.Parent
        local humanoid = character:FindFirstChildOfClass("Humanoid")
        local player = Players:GetPlayerFromCharacter(character)
        
        if player and humanoid then
            -- Show game mode selection
            RemoteEvents.ShowGameModeSelection:FireClient(player)
        end
    end)
    
    -- Store queue objects
    hubObjects.queueArea = {
        platform = queuePlatform,
        sign = queueSign,
        signPost = signPost,
        waitingSpots = waitingSpots,
        detector = queueDetector
    }
    
    print("👥 Multiplayer queue area created!")
    return queuePlatform
end

function HubService:CreateMarketStall(stallData)
    local stallPosition = HUB_CONFIG.center + stallData.position
    
    -- Stall base
    local stallBase = Instance.new("Part")
    stallBase.Name = stallData.name .. "Base"
    stallBase.Size = Vector3.new(8, 1, 8)
    stallBase.Position = stallPosition + Vector3.new(0, 0.5, 0)
    stallBase.Anchored = true
    stallBase.CanCollide = true
    stallBase.Material = Enum.Material.Wood
    stallBase.Color = Color3.fromRGB(139, 90, 43)
    stallBase.Parent = Workspace
    
    -- Stall roof/canopy
    local canopy = Instance.new("Part")
    canopy.Name = stallData.name .. "Canopy"
    canopy.Size = Vector3.new(10, 0.5, 10)
    canopy.Position = stallPosition + Vector3.new(0, 6, 0)
    canopy.Anchored = true
    canopy.CanCollide = false
    canopy.Material = Enum.Material.Fabric
    canopy.Color = self:GetStallColor(stallData.name)
    canopy.Parent = Workspace
    
    -- Support posts
    local postPositions = {
        Vector3.new(-4, 3, -4), Vector3.new(4, 3, -4),
        Vector3.new(-4, 3, 4), Vector3.new(4, 3, 4)
    }
    
    for _, postPos in pairs(postPositions) do
        local post = Instance.new("Part")
        post.Name = "StallPost"
        post.Size = Vector3.new(0.5, 6, 0.5)
        post.Position = stallPosition + postPos
        post.Anchored = true
        post.CanCollide = false
        post.Material = Enum.Material.Wood
        post.Color = Color3.fromRGB(101, 67, 33)
        post.Parent = Workspace
    end
    
    -- Stall sign
    local stallSign = Instance.new("Part")
    stallSign.Name = stallData.name .. "Sign"
    stallSign.Size = Vector3.new(6, 1.5, 0.2)
    stallSign.Position = stallPosition + Vector3.new(0, 4, -4.5)
    stallSign.Anchored = true
    stallSign.CanCollide = false
    stallSign.Material = Enum.Material.SmoothPlastic
    stallSign.Color = Color3.fromRGB(255, 255, 255)
    stallSign.Parent = Workspace
    
    -- Sign text
    local signGui = Instance.new("SurfaceGui")
    signGui.Face = Enum.NormalId.Front
    signGui.Parent = stallSign
    
    local signText = Instance.new("TextLabel")
    signText.Size = UDim2.new(1, 0, 1, 0)
    signText.BackgroundTransparency = 1
    signText.Text = self:GetStallIcon(stallData.name) .. " " .. stallData.name
    signText.TextColor3 = Color3.fromRGB(0, 0, 0)
    signText.TextScaled = true
    signText.Font = Enum.Font.SourceSansBold
    signText.Parent = signGui
    
    -- Decorative items on stall counter
    self:AddStallDecorations(stallData, stallPosition)
    
    -- Rotation
    local stallModel = Instance.new("Model")
    stallModel.Name = stallData.name
    stallModel.Parent = Workspace
    
    stallBase.Parent = stallModel
    canopy.Parent = stallModel
    stallSign.Parent = stallModel
    
    -- Rotate the entire stall
    for _, part in pairs(stallModel:GetChildren()) do
        if part:IsA("BasePart") then
            local rotatedCFrame = CFrame.new(stallPosition) * CFrame.fromEulerAnglesXYZ(0, math.rad(stallData.rotation), 0) * CFrame.new(part.Position - stallPosition)
            part.CFrame = rotatedCFrame
        end
    end
    
    hubObjects.stalls[stallData.name] = stallModel
    return stallModel
end

function HubService:CreateNPC(npcData)
    local npcPosition = HUB_CONFIG.center + npcData.position
    
    -- Create NPC model
    local npcModel = Instance.new("Model")
    npcModel.Name = npcData.name .. "NPC"
    npcModel.Parent = Workspace
    
    -- NPC body parts
    local torso = Instance.new("Part")
    torso.Name = "Torso"
    torso.Size = Vector3.new(2, 2, 1)
    torso.Position = npcPosition + Vector3.new(0, 3, 0)
    torso.Anchored = true
    torso.CanCollide = false
    torso.Material = Enum.Material.SmoothPlastic
    torso.Color = self:GetNPCColor(npcData.name)
    torso.Parent = npcModel
    
    local head = Instance.new("Part")
    head.Name = "Head"
    head.Size = Vector3.new(1.5, 1.5, 1.5)
    head.Position = torso.Position + Vector3.new(0, 1.75, 0)
    head.Anchored = true
    head.CanCollide = false
    head.Material = Enum.Material.SmoothPlastic
    head.Color = Color3.fromRGB(255, 220, 177)
    head.Shape = Enum.PartType.Ball
    head.Parent = npcModel
    
    -- NPC face
    local face = Instance.new("Decal")
    face.Face = Enum.NormalId.Front
    face.Texture = "rbxasset://textures/face.png"
    face.Parent = head
    
    -- NPC name tag
    local nameGui = Instance.new("BillboardGui")
    nameGui.Size = UDim2.new(0, 100, 0, 25)
    nameGui.StudsOffset = Vector3.new(0, 2, 0)
    nameGui.Parent = head
    
    local nameLabel = Instance.new("TextLabel")
    nameLabel.Size = UDim2.new(1, 0, 1, 0)
    nameLabel.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    nameLabel.BackgroundTransparency = 0.3
    nameLabel.Text = npcData.name
    nameLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    nameLabel.TextScaled = true
    nameLabel.Font = Enum.Font.SourceSansBold
    nameLabel.Parent = nameGui
    
    -- Add corner rounding
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 5)
    corner.Parent = nameLabel
    
    -- Start NPC animation
    self:AnimateNPC(npcModel, npcData.animation)
    
    hubObjects.npcs[npcData.name] = npcModel
    return npcModel
end

function HubService:CreateAmbientSounds()
    -- Create ambient sound folder
    local soundFolder = Instance.new("Folder")
    soundFolder.Name = "HubSounds"
    soundFolder.Parent = Workspace
    
    -- Background music
    local bgMusic = Instance.new("Sound")
    bgMusic.Name = "BackgroundMusic"
    bgMusic.SoundId = "rbxasset://sounds/electronicpingshort.wav" -- Placeholder - replace with actual music
    bgMusic.Volume = 0.3
    bgMusic.Looped = true
    bgMusic.Parent = soundFolder
    bgMusic:Play()
    
    -- Bird sounds
    local birdSound = Instance.new("Sound")
    birdSound.Name = "BirdChirping"
    birdSound.SoundId = "rbxasset://sounds/impact_water.mp3" -- Placeholder - replace with bird sounds
    birdSound.Volume = 0.2
    birdSound.Looped = true
    birdSound.Parent = soundFolder
    birdSound:Play()
    
    -- Market chatter (ambient voices)
    local chatterSound = Instance.new("Sound")
    chatterSound.Name = "MarketChatter"
    chatterSound.SoundId = "rbxasset://sounds/button-09.mp3" -- Placeholder - replace with crowd sounds
    chatterSound.Volume = 0.15
    chatterSound.Looped = true
    chatterSound.Parent = soundFolder
    chatterSound:Play()
    
    -- Footsteps sound (triggered by player movement)
    local footstepsSound = Instance.new("Sound")
    footstepsSound.Name = "Footsteps"
    footstepsSound.SoundId = "rbxasset://sounds/impact_water.mp3" -- Placeholder - replace with footstep sounds
    footstepsSound.Volume = 0.4
    footstepsSound.Parent = soundFolder
    
    hubObjects.sounds = {
        bgMusic = bgMusic,
        birds = birdSound,
        chatter = chatterSound,
        footsteps = footstepsSound
    }
    
    return soundFolder
end

function HubService:AnimatePortal(ring, interior)
    -- Rotating portal ring
    local ringTween = TweenService:Create(ring, TweenInfo.new(3, Enum.EasingStyle.Linear, Enum.EasingDirection.InOut, -1), {
        CFrame = ring.CFrame * CFrame.fromEulerAnglesXYZ(math.rad(360), 0, 0)
    })
    ringTween:Play()
    
    -- Pulsing portal interior
    local interiorTween = TweenService:Create(interior, TweenInfo.new(2, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true), {
        Transparency = 0.8
    })
    interiorTween:Play()
end

function HubService:AnimateSign(sign)
    -- Gentle glow pulsing
    local glowTween = TweenService:Create(sign, TweenInfo.new(1.5, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true), {
        Color = Color3.fromRGB(255, 255, 100)
    })
    glowTween:Play()
end

function HubService:AnimateNPC(npcModel, animationType)
    local torso = npcModel:FindFirstChild("Torso")
    local head = npcModel:FindFirstChild("Head")
    if not torso or not head then return end
    
    local originalTorsoPosition = torso.Position
    local originalHeadPosition = head.Position
    
    if animationType == "browsing" then
        -- Gentle side-to-side movement
        local browseTween = TweenService:Create(torso, TweenInfo.new(3, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true), {
            CFrame = torso.CFrame * CFrame.fromEulerAnglesXYZ(0, math.rad(30), 0)
        })
        browseTween:Play()
        
    elseif animationType == "shopping" then
        -- Head nodding motion
        local nodTween = TweenService:Create(head, TweenInfo.new(2, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true), {
            CFrame = head.CFrame * CFrame.fromEulerAnglesXYZ(math.rad(15), 0, 0)
        })
        nodTween:Play()
        
    elseif animationType == "patrolling" then
        -- Walking back and forth
        local walkTween = TweenService:Create(torso, TweenInfo.new(4, Enum.EasingStyle.Linear, Enum.EasingDirection.InOut, -1, true), {
            Position = originalTorsoPosition + Vector3.new(5, 0, 0)
        })
        walkTween:Play()
        
        local headWalk = TweenService:Create(head, TweenInfo.new(4, Enum.EasingStyle.Linear, Enum.EasingDirection.InOut, -1, true), {
            Position = originalHeadPosition + Vector3.new(5, 0, 0)
        })
        headWalk:Play()
        
    elseif animationType == "selling" then
        -- Arm waving gesture (simulated with torso rotation)
        local waveTween = TweenService:Create(torso, TweenInfo.new(1.5, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true), {
            CFrame = torso.CFrame * CFrame.fromEulerAnglesXYZ(0, 0, math.rad(10))
        })
        waveTween:Play()
        
    elseif animationType == "examining" then
        -- Looking around motion
        local examTween = TweenService:Create(head, TweenInfo.new(2.5, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true), {
            CFrame = head.CFrame * CFrame.fromEulerAnglesXYZ(0, math.rad(45), 0)
        })
        examTween:Play()
        
    elseif animationType == "calling" then
        -- Jumping motion
        local jumpTween = TweenService:Create(torso, TweenInfo.new(1, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut, -1, true), {
            Position = originalTorsoPosition + Vector3.new(0, 1, 0)
        })
        jumpTween:Play()
        
        local headJump = TweenService:Create(head, TweenInfo.new(1, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut, -1, true), {
            Position = originalHeadPosition + Vector3.new(0, 1, 0)
        })
        headJump:Play()
        
    elseif animationType == "watching" then
        -- Slow head turning
        local watchTween = TweenService:Create(head, TweenInfo.new(4, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true), {
            CFrame = head.CFrame * CFrame.fromEulerAnglesXYZ(0, math.rad(60), 0)
        })
        watchTween:Play()
    end
end

-- Utility functions
function HubService:GetStallColor(stallName)
    local colors = {
        ["Pet Shop"] = Color3.fromRGB(255, 150, 150),
        ["Upgrade Stall"] = Color3.fromRGB(150, 255, 150),
        ["Crate Stall"] = Color3.fromRGB(150, 150, 255),
        ["Cosmetic Boutique"] = Color3.fromRGB(255, 150, 255),
        ["Quest Board"] = Color3.fromRGB(255, 255, 150),
        ["Tournament Arena"] = Color3.fromRGB(255, 100, 100),
        ["Mystery Shop"] = Color3.fromRGB(100, 100, 255)
    }
    return colors[stallName] or Color3.fromRGB(200, 200, 200)
end

function HubService:GetStallIcon(stallName)
    local icons = {
        ["Pet Shop"] = "🐾",
        ["Upgrade Stall"] = "⚡",
        ["Crate Stall"] = "📦",
        ["Cosmetic Boutique"] = "👗",
        ["Quest Board"] = "📋",
        ["Tournament Arena"] = "🏆",
        ["Mystery Shop"] = "🔮"
    }
    return icons[stallName] or "🏪"
end

function HubService:GetNPCColor(npcName)
    local colors = {
        ["Merchant"] = Color3.fromRGB(100, 150, 200),
        ["Customer"] = Color3.fromRGB(200, 100, 150),
        ["Guard"] = Color3.fromRGB(150, 100, 100),
        ["Vendor"] = Color3.fromRGB(100, 200, 100),
        ["Collector"] = Color3.fromRGB(200, 200, 100),
        ["Announcer"] = Color3.fromRGB(255, 100, 100),
        ["Spectator"] = Color3.fromRGB(100, 100, 255)
    }
    return colors[npcName] or Color3.fromRGB(150, 150, 150)
end

function HubService:AddStallDecorations(stallData, stallPosition)
    -- Add decorative items based on stall type
    if stallData.name == "Pet Shop" then
        -- Pet bowls and toys
        local bowl = Instance.new("Part")
        bowl.Name = "PetBowl"
        bowl.Size = Vector3.new(1, 0.3, 1)
        bowl.Position = stallPosition + Vector3.new(-2, 1.5, 2)
        bowl.Anchored = true
        bowl.Material = Enum.Material.Plastic
        bowl.Color = Color3.fromRGB(255, 200, 100)
        bowl.Shape = Enum.PartType.Cylinder
        bowl.Parent = Workspace
        
    elseif stallData.name == "Upgrade Stall" then
        -- Glowing crystals
        local crystal = Instance.new("Part")
        crystal.Name = "UpgradeCrystal"
        crystal.Size = Vector3.new(0.8, 2, 0.8)
        crystal.Position = stallPosition + Vector3.new(2, 2, 2)
        crystal.Anchored = true
        crystal.Material = Enum.Material.Neon
        crystal.Color = Color3.fromRGB(100, 255, 100)
        crystal.Parent = Workspace
        
    elseif stallData.name == "Crate Stall" then
        -- Stacked crates
        for i = 1, 3 do
            local crate = Instance.new("Part")
            crate.Name = "DecorationCrate" .. i
            crate.Size = Vector3.new(1.5, 1.5, 1.5)
            crate.Position = stallPosition + Vector3.new(-1 + i, 1.5 + (i-1) * 0.5, 1)
            crate.Anchored = true
            crate.Material = Enum.Material.Wood
            crate.Color = Color3.fromRGB(139, 90, 43)
            crate.Parent = Workspace
        end
    end
end

function HubService:HandlePortalClick(player)
    -- Trigger game start
    local GameService = require(script.Parent.GameService)
    GameService:StartGame(player)
    
    -- Play portal sound effect
    local portalSound = Instance.new("Sound")
    portalSound.SoundId = "rbxasset://sounds/electronicpingshort.wav"
    portalSound.Volume = 0.5
    portalSound.Parent = hubObjects.playPortal.base
    portalSound:Play()
    
    portalSound.Ended:Connect(function()
        portalSound:Destroy()
    end)
end

function HubService:HandlePlayerFootsteps(player)
    if not player.Character or not player.Character:FindFirstChild("HumanoidRootPart") then
        return
    end
    
    local humanoid = player.Character:FindFirstChild("Humanoid")
    if not humanoid then return end
    
    -- Play footstep sounds when player is moving in hub
    humanoid.Running:Connect(function(speed)
        if speed > 0 and hubObjects.sounds.footsteps then
            if not hubObjects.sounds.footsteps.IsPlaying then
                hubObjects.sounds.footsteps:Play()
            end
        else
            if hubObjects.sounds.footsteps and hubObjects.sounds.footsteps.IsPlaying then
                hubObjects.sounds.footsteps:Stop()
            end
        end
    end)
end

function HubService:CreateHub()
    print("🏪 Creating market-style hub...")
    
    -- Create all hub components
    self:CreateHubGround()
    self:CreatePlayPortal()
    self:CreateMultiplayerQueue()
    
    -- Create market stalls
    for _, stallData in pairs(HUB_CONFIG.stalls) do
        self:CreateMarketStall(stallData)
    end
    
    -- Create NPCs
    for _, npcData in pairs(HUB_CONFIG.npcs) do
        self:CreateNPC(npcData)
    end
    
    -- Set up ambient sounds
    self:CreateAmbientSounds()
    
    print("✅ Market hub created successfully!")
end

function HubService:OnPlayerAdded(player)
    player.CharacterAdded:Connect(function(character)
        -- Spawn player in hub
        wait(1) -- Wait for character to fully load
        
        if character:FindFirstChild("HumanoidRootPart") then
            character.HumanoidRootPart.CFrame = CFrame.new(HUB_CONFIG.center + Vector3.new(0, 5, 30))
        end
        
        -- Set up footstep sounds
        self:HandlePlayerFootsteps(player)
    end)
end

function HubService:HandlePartySystemRequest(player)
    -- Handle request to open party system from hub
    print("🎉 " .. player.Name .. " requested party system from hub")
    
    -- Try to show the party UI, if not available show notification
    local success, err = pcall(function()
        RemoteEvents.ShowPartyUI:FireClient(player)
    end)
    
    if success then
        print("🎉 Opened party UI for " .. player.Name)
    else
        -- Fallback: show a notification
        RemoteEvents.ShowNotification:FireClient(player, {
            title = "🎉 Party System",
            message = "Create or join a party to play with friends! Team up for better rewards and more fun!",
            duration = 4,
            type = "info"
        })
        print("📝 Showed party system notification to " .. player.Name)
    end
end

function HubService:Init()
    -- Create the hub
    self:CreateHub()
    
    -- Handle player spawning
    Players.PlayerAdded:Connect(function(player)
        self:OnPlayerAdded(player)
    end)
    
    -- Handle existing players
    for _, player in pairs(Players:GetPlayers()) do
        self:OnPlayerAdded(player)
    end
    
    -- Handle party system requests from hub enhancement
    RemoteEvents.OpenPartySystem.OnServerEvent:Connect(function(player)
        self:HandlePartySystemRequest(player)
    end)
    
    print("HubService initialized")
end

return HubService
