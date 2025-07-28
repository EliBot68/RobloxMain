-- TeleportService.luau
-- Handles return rings and teleportation back to market plaza (Standardized Enhanced Service)
-- Enhanced with developer teleportation tools

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Debris = game:GetService("Debris")
local RunService = game:GetService("RunService")

local SafeRequire = require(ReplicatedStorage.Shared.utils.SafeRequire)
local ServiceBase = SafeRequire.require(ReplicatedStorage.Shared.utils.ServiceBase)

local TeleportService = ServiceBase.new("TeleportService", {
    enableDetailedLogging = true,
    retryFailedRequires = true,
    maxRetryAttempts = 3,
    validateOnStart = true,
    autoStart = false
})

-- Define dependencies
TeleportService.Dependencies = {
    { path = ReplicatedStorage.Shared.modules.DeveloperConfig, name = "DeveloperConfig", optional = false },
    { path = ReplicatedStorage.Shared.modules.RemoteEvents, name = "RemoteEvents", optional = false },
    { path = script.Parent.PlayerService, name = "PlayerService", optional = false },
}

-- Track active teleportations to prevent spam
local activeTeleports = {}

-- Get developer track positions from config
local function getDeveloperTracks(self)
	return self.DeveloperConfig.TRACK_POSITIONS
end

-- Return ring configurations
local RETURN_RINGS = {
    {
        position = Vector3.new(100, 7, 120),
        name = "Track1_Return"
    },
    {
        position = Vector3.new(-100, 7, 120),
        name = "Track2_Return"
    },
    {
        position = Vector3.new(120, 7, 150),
        name = "Track3_Return"
    }
}

function TeleportService:SetupReturnRings()
    local gameTracks = Workspace:FindFirstChild("GameTracks")
    if not gameTracks then
        warn("GameTracks not found!")
        return
    end
    
    -- Setup each track's return ring
    for i, trackName in pairs({"Track1", "Track2", "Track3"}) do
        local track = gameTracks:FindFirstChild(trackName)
        if track then
            self:SetupSingleReturnRing(track, RETURN_RINGS[i])
        end
    end
end

function TeleportService:SetupSingleReturnRing(track, ringConfig)
    local returnRing = track:FindFirstChild("ReturnRing")
    local ringGlow = track:FindFirstChild("RingGlow")
    
    if not returnRing then return end
    
    -- Add floating text
    local billboardGui = Instance.new("BillboardGui")
    billboardGui.Size = UDim2.new(0, 300, 0, 100)
    billboardGui.StudsOffset = Vector3.new(0, 2, 0)
    billboardGui.Parent = returnRing
    
    local titleLabel = Instance.new("TextLabel")
    titleLabel.Size = UDim2.new(1, 0, 0.6, 0)
    titleLabel.BackgroundTransparency = 1
    titleLabel.Text = "🏠 RETURN TO MARKET"
    titleLabel.TextColor3 = Color3.new(0.4, 0.8, 1)
    titleLabel.TextScaled = true
    titleLabel.Font = Enum.Font.SourceSansBold
    titleLabel.TextStrokeTransparency = 0
    titleLabel.TextStrokeColor3 = Color3.new(0, 0, 0)
    titleLabel.Parent = billboardGui
    
    local subtitleLabel = Instance.new("TextLabel")
    subtitleLabel.Size = UDim2.new(1, 0, 0.4, 0)
    subtitleLabel.Position = UDim2.new(0, 0, 0.6, 0)
    subtitleLabel.BackgroundTransparency = 1
    subtitleLabel.Text = "Touch to teleport back!"
    subtitleLabel.TextColor3 = Color3.new(0.7, 0.9, 1)
    subtitleLabel.TextScaled = true
    subtitleLabel.Font = Enum.Font.SourceSans
    subtitleLabel.TextStrokeTransparency = 0
    subtitleLabel.TextStrokeColor3 = Color3.new(0, 0, 0)
    subtitleLabel.Parent = billboardGui
    
    -- Add pulsing animation
    local pulseTween = TweenService:Create(
        titleLabel,
        TweenInfo.new(1.5, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true),
        {TextTransparency = 0.3}
    )
    pulseTween:Play()
    
    -- Add floating animation
    local floatTween = TweenService:Create(
        billboardGui,
        TweenInfo.new(3, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true),
        {StudsOffset = Vector3.new(0, 3, 0)}
    )
    floatTween:Play()
    
    -- Add ring rotation animation
    if ringGlow then
        local rotateTween = TweenService:Create(
            ringGlow,
            TweenInfo.new(4, Enum.EasingStyle.Linear, Enum.EasingDirection.InOut, -1),
            {CFrame = ringGlow.CFrame * CFrame.Angles(0, math.pi * 2, 0)}
        )
        rotateTween:Play()
    end
    
    -- Add ring pulsing glow
    if ringGlow then
        local glowTween = TweenService:Create(
            ringGlow,
            TweenInfo.new(2, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true),
            {Transparency = 0.1}
        )
        glowTween:Play()
    end
    
    -- Setup touch detection
    local connection
    connection = returnRing.Touched:Connect(function(hit)
        local character = hit.Parent
        local humanoid = character:FindFirstChildOfClass("Humanoid")
        local player = Players:GetPlayerFromCharacter(character)
        
        if player and humanoid then
            self:TeleportPlayerToMarket(player, character)
        end
    end)
    
    print("🌀 Return ring setup complete for " .. track.Name)
end

function TeleportService:TeleportPlayerToMarket(player, character)
    local userId = tostring(player.UserId)
    
    -- Prevent teleport spam
    if activeTeleports[userId] and tick() - activeTeleports[userId] < 3 then
        return
    end
    
    activeTeleports[userId] = tick()
    
    local humanoid = character:FindFirstChildOfClass("Humanoid")
    local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
    
    if not humanoid or not humanoidRootPart then return end
    
    print("🌀 " .. player.Name .. " is teleporting back to market plaza...")
    
    -- Create fade effect
    self:CreateFadeEffect(player)
    
    -- Create teleport particles
    self:CreateTeleportEffect(humanoidRootPart.Position)
    
    -- Disable player movement temporarily
    humanoid.PlatformStand = true
    
    -- Wait for fade effect
    wait(1)
    
    -- Choose random spawn position around fountain
    local spawnPositions = {
        Vector3.new(8, 5, 8),   -- Northeast of fountain
        Vector3.new(-8, 5, 8),  -- Northwest of fountain
        Vector3.new(8, 5, -8),  -- Southeast of fountain
        Vector3.new(-8, 5, -8), -- Southwest of fountain
        Vector3.new(0, 5, 12),  -- North of fountain
        Vector3.new(0, 5, -12), -- South of fountain
        Vector3.new(12, 5, 0),  -- East of fountain
        Vector3.new(-12, 5, 0)  -- West of fountain
    }
    
    local randomSpawn = spawnPositions[math.random(1, #spawnPositions)]
    
    -- Teleport player
    humanoidRootPart.CFrame = CFrame.new(randomSpawn)
    
    -- Create arrival effect
    self:CreateTeleportEffect(randomSpawn)
    
    -- Re-enable movement
    humanoid.PlatformStand = false
    
    -- Play teleport sound
    self:PlayTeleportSound(humanoidRootPart)
    
    -- Fade back in
    self:CreateFadeInEffect(player)
    
    print("✨ " .. player.Name .. " returned to market plaza!")
end

function TeleportService:CreateFadeEffect(player)
    if self.RemoteEvents then
        self.RemoteEvents.TeleportFadeOut:FireClient(player)
    end
end

function TeleportService:CreateFadeInEffect(player)
    if self.RemoteEvents then
        self.RemoteEvents.TeleportFadeIn:FireClient(player)
    end
end

function TeleportService:CreateTeleportEffect(position)
    -- Create teleport particle effect
    local effectPart = Instance.new("Part")
    effectPart.Size = Vector3.new(0.1, 0.1, 0.1)
    effectPart.Position = position
    effectPart.Anchored = true
    effectPart.CanCollide = false
    effectPart.Transparency = 1
    effectPart.Parent = Workspace
    
    local attachment = Instance.new("Attachment")
    attachment.Parent = effectPart
    
    -- Sparkle effect
    local sparkles = Instance.new("ParticleEmitter")
    sparkles.Parent = attachment
    sparkles.Enabled = true
    sparkles.Lifetime = NumberRange.new(1, 2)
    sparkles.Rate = 200
    sparkles.SpreadAngle = Vector2.new(360, 360)
    sparkles.Speed = NumberRange.new(10, 20)
    sparkles.Color = ColorSequence.new{
        ColorSequenceKeypoint.new(0, Color3.new(0.4, 0.8, 1)),
        ColorSequenceKeypoint.new(0.5, Color3.new(0.8, 0.9, 1)),
        ColorSequenceKeypoint.new(1, Color3.new(0.2, 0.6, 1))
    }
    sparkles.Texture = "rbxasset://textures/particles/sparkles_main.dds"
    
    -- Portal effect
    local portal = Instance.new("ParticleEmitter")
    portal.Parent = attachment
    portal.Enabled = true
    portal.Lifetime = NumberRange.new(0.5, 1.5)
    portal.Rate = 100
    portal.SpreadAngle = Vector2.new(45, 45)
    portal.Speed = NumberRange.new(5, 15)
    portal.Color = ColorSequence.new(Color3.new(0.2, 0.6, 1))
    portal.Transparency = NumberSequence.new{
        NumberSequenceKeypoint.new(0, 0.3),
        NumberSequenceKeypoint.new(1, 1)
    }
    
    -- Clean up after 3 seconds
    Debris:AddItem(effectPart, 3)
    
    -- Disable emitters after 1 second
    spawn(function()
        wait(1)
        sparkles.Enabled = false
        portal.Enabled = false
    end)
end

function TeleportService:PlayTeleportSound(humanoidRootPart)
    local sound = Instance.new("Sound")
    sound.SoundId = "rbxasset://sounds/electronicpingshort.wav"
    sound.Volume = 0.5
    sound.Pitch = 1.2
    sound.Parent = humanoidRootPart
    sound:Play()
    
    sound.Ended:Connect(function()
        sound:Destroy()
    end)
end

-- Setup remote events
function TeleportService:SetupRemoteEvents()
    if self.RemoteEvents then
        -- Setup client communication for teleportation
        local teleportToTrackEvent = self.RemoteEvents:GetRemoteFunction("TeleportToTrack")
        if teleportToTrackEvent then
            teleportToTrackEvent.OnServerInvoke = function(player, trackName)
                return self:TeleportToTrack(player, trackName)
            end
        end
    end
end

-- Developer teleportation function  
function TeleportService:TeleportToTrack(player, trackName)
	-- Check if this is a developer request
	local ServiceRegistry = self:SafeRequire(ReplicatedStorage.Shared.utils.ServiceRegistry, "ServiceRegistry", true)
	local DeveloperService = ServiceRegistry and ServiceRegistry:GetService("DeveloperService")
	
	local developerTracks = getDeveloperTracks(self)
	local config = developerTracks[trackName]
	if not config then
		return {success = false, message = "Unknown track: " .. trackName}
	end    local character = player.Character
    if not character or not character:FindFirstChild("HumanoidRootPart") then
        return {success = false, message = "Character not found"}
    end
    
    -- Create target CFrame
    local targetCFrame = CFrame.new(config.position) * config.orientation
    
    -- Teleport with effects
    self:TeleportPlayerWithEffects(player, targetCFrame, trackName)
    
    return {success = true, message = "Teleported to " .. trackName}
end

-- Enhanced teleport with visual effects
function TeleportService:TeleportPlayerWithEffects(player, targetCFrame, locationName)
    local character = player.Character
    if not character or not character:FindFirstChild("HumanoidRootPart") then
        return false
    end
    
    local humanoidRootPart = character.HumanoidRootPart
    local humanoid = character:FindFirstChild("Humanoid")
    
    -- Disable movement temporarily
    if humanoid then
        humanoid.PlatformStand = true
    end
    
    -- Create teleport effect
    local effect = Instance.new("Part")
    effect.Name = "TeleportEffect"
    effect.Size = Vector3.new(8, 8, 8)
    effect.Material = Enum.Material.Neon
    effect.BrickColor = BrickColor.new("Bright blue")
    effect.Shape = Enum.PartType.Ball
    effect.Anchored = true
    effect.CanCollide = false
    effect.CFrame = humanoidRootPart.CFrame
    effect.Parent = Workspace
    
    -- Shrink effect
    local shrinkTween = TweenService:Create(effect, TweenInfo.new(0.5), {
        Size = Vector3.new(0.1, 0.1, 0.1),
        Transparency = 1
    })
    
    shrinkTween:Play()
    shrinkTween.Completed:Connect(function()
        effect:Destroy()
    end)
    
    -- Wait then teleport
    wait(0.3)
    humanoidRootPart.CFrame = targetCFrame
    
    -- Re-enable movement
    if humanoid then
        humanoid.PlatformStand = false
    end
    
    -- Play teleport sound
    self:PlayTeleportSound(humanoidRootPart)
    
    -- Create arrival effect
    self:CreateTeleportEffects(humanoidRootPart.Position)
    
    print(string.format("Teleported %s to %s", player.Name, locationName))
    return true
end

function TeleportService:Initialize()
    print("🌀 TeleportService initializing...")
    
    -- Wait for workspace to be ready
    wait(2)
    
    -- Setup return rings
    self:SetupReturnRings()
    
    print("✅ TeleportService initialized successfully!")
end

-- Service-specific initialization
function TeleportService:OnInit()
    return true
end

-- Service-specific start logic
function TeleportService:OnStart()
    self:Initialize()
    return true
end

return TeleportService
