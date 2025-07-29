--[[
	HubManagerService
	Manages the game hub layout, building placement, and area definitions (Standardized Enhanced Service)
	Provides utilities for creating and managing hub elements
--]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local Lighting = game:GetService("Lighting")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")

local SafeRequire = require(ReplicatedStorage.Shared.utils.SafeRequire)
local ServiceBase = SafeRequire.require(ReplicatedStorage.Shared.utils.ServiceBase)
local WorldObjectValidator = SafeRequire.require(ReplicatedStorage.Shared.utils.WorldObjectValidator)

local HubManagerService = ServiceBase.new("HubManagerService", {
    enableDetailedLogging = true,
    retryFailedRequires = true,
    maxRetryAttempts = 3,
    validateOnStart = true,
    autoStart = false
})

-- Hub zone definitions
local HUB_ZONES = {
	CentralPlaza = {
		name = "Central Plaza",
		position = Vector3.new(0, 5, 0),
		size = Vector3.new(40, 20, 40),
		description = "Main gathering point and navigation hub",
		color = Color3.fromRGB(100, 150, 255)
	},
	PlayPortal = {
		name = "Play Portal Area",
		position = Vector3.new(0, 5, 50),
		size = Vector3.new(30, 15, 25),
		description = "Access to all game tracks",
		color = Color3.fromRGB(255, 100, 100)
	},
	CommerceDistrict = {
		name = "Commerce District",
		position = Vector3.new(-40, 5, 0),
		size = Vector3.new(35, 15, 60),
		description = "Shopping and economic activities",
		color = Color3.fromRGB(255, 200, 100)
	},
	ProgressionHub = {
		name = "Progression Hub",
		position = Vector3.new(40, 5, 0),
		size = Vector3.new(35, 15, 60),
		description = "Player advancement and achievements",
		color = Color3.fromRGB(100, 255, 150)
	},
	TutorialGarden = {
		name = "Tutorial Garden",
		position = Vector3.new(-30, 5, -50),
		size = Vector3.new(25, 15, 25),
		description = "New player onboarding",
		color = Color3.fromRGB(150, 255, 150)
	},
	SocialCorner = {
		name = "Social Corner",
		position = Vector3.new(0, 5, -50),
		size = Vector3.new(30, 15, 25),
		description = "Community interaction and settings",
		color = Color3.fromRGB(255, 150, 255)
	}
}

-- Building templates for easy placement
local BUILDING_TEMPLATES = {
	Shop = {
		name = "Shop Building",
		size = Vector3.new(15, 10, 12),
		color = Color3.fromRGB(139, 69, 19), -- Brown
		material = Enum.Material.Brick,
		features = {"Door", "Windows", "Sign", "Roof"}
	},
	CrateStation = {
		name = "Crate Station",
		size = Vector3.new(8, 8, 8),
		color = Color3.fromRGB(70, 70, 70), -- Dark Gray
		material = Enum.Material.Metal,
		features = {"Dispenser", "Platform", "Particles"}
	},
	CosmeticsBoutique = {
		name = "Cosmetics Boutique",
		size = Vector3.new(12, 8, 10),
		color = Color3.fromRGB(255, 192, 203), -- Pink
		material = Enum.Material.SmoothPlastic,
		features = {"Mirror", "Runway", "Display"}
	},
	RebirthTemple = {
		name = "Rebirth Temple",
		size = Vector3.new(10, 12, 10),
		color = Color3.fromRGB(128, 0, 128), -- Purple
		material = Enum.Material.Marble,
		features = {"Altar", "Pillars", "Mystical Effects"}
	},
	UpgradeStation = {
		name = "Upgrade Station",
		size = Vector3.new(10, 8, 10),
		color = Color3.fromRGB(0, 100, 200), -- Blue
		material = Enum.Material.Neon,
		features = {"Terminal", "Displays", "Tech Effects"}
	},
	Fountain = {
		name = "Central Fountain",
		size = Vector3.new(12, 6, 12),
		color = Color3.fromRGB(200, 200, 200), -- Light Gray
		material = Enum.Material.Marble,
		features = {"Water", "Benches", "Lighting"}
	}
}

-- Hub folder management
local hubFolder = nil

-- Create hub folder structure
local function createHubStructure()
	-- Remove existing hub if it exists
	local existingHub = Workspace:FindFirstChild("GameHub")
	if existingHub then
		existingHub:Destroy()
	end
	
	-- Create main hub folder
	hubFolder = Instance.new("Folder")
	hubFolder.Name = "GameHub"
	hubFolder.Parent = Workspace
	
	-- Create zone folders
	for zoneName, zoneData in pairs(HUB_ZONES) do
		local zoneFolder = Instance.new("Folder")
		zoneFolder.Name = zoneName
		zoneFolder.Parent = hubFolder
		
		-- Create zone boundary (invisible for reference)
		local zoneBoundary = Instance.new("Part")
		zoneBoundary.Name = "ZoneBoundary"
		zoneBoundary.Size = zoneData.size
		zoneBoundary.Position = zoneData.position
		zoneBoundary.Anchored = true
		zoneBoundary.CanCollide = false
		zoneBoundary.Transparency = 1
		zoneBoundary.BrickColor = BrickColor.new(zoneData.color)
		zoneBoundary.Parent = zoneFolder
		
		-- Add zone identification
		local zoneGui = Instance.new("BillboardGui")
		zoneGui.Name = "ZoneInfo"
		zoneGui.Size = UDim2.new(6, 0, 2, 0)
		zoneGui.StudsOffset = Vector3.new(0, zoneData.size.Y/2 + 5, 0)
		zoneGui.Parent = zoneBoundary
		
		local zoneLabel = Instance.new("TextLabel")
		zoneLabel.Name = "ZoneLabel"
		zoneLabel.Size = UDim2.new(1, 0, 1, 0)
		zoneLabel.BackgroundTransparency = 1
		zoneLabel.Text = zoneData.name
		zoneLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
		zoneLabel.TextStrokeTransparency = 0
		zoneLabel.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
		zoneLabel.TextScaled = true
		zoneLabel.Font = Enum.Font.GothamBold
		zoneLabel.Parent = zoneGui
	end
	
	print("🏗️ Hub structure created with " .. #HUB_ZONES .. " zones")
end

-- Create a basic building from template
function HubManagerService:CreateBuilding(buildingType, position, rotation)
	local template = BUILDING_TEMPLATES[buildingType]
	if not template then
		warn("Unknown building type: " .. buildingType)
		return nil
	end
	
	if not hubFolder then
		warn("Hub folder not initialized")
		return nil
	end
	
	-- Find appropriate zone folder
	local zoneFolder = self:GetZoneForPosition(position)
	if not zoneFolder then
		zoneFolder = hubFolder -- Fallback to main folder
	end
	
	-- Create main building part
	local building = Instance.new("Part")
	building.Name = template.name
	building.Size = template.size
	building.Position = position
	building.Rotation = rotation or Vector3.new(0, 0, 0)
	building.Anchored = true
	building.Material = template.material
	building.BrickColor = BrickColor.new(template.color)
	building.Parent = zoneFolder
	
	-- Add building features
	self:AddBuildingFeatures(building, template.features)
	
	-- Add interaction detection
	self:AddInteractionZone(building, buildingType)
	
	print(string.format("🏢 Created %s at %s", template.name, tostring(position)))
	return building
end

-- Add features to buildings
function HubManagerService:AddBuildingFeatures(building, features)
	for _, feature in pairs(features) do
		if feature == "Door" then
			self:AddDoor(building)
		elseif feature == "Windows" then
			self:AddWindows(building)
		elseif feature == "Sign" then
			self:AddSign(building)
		elseif feature == "Roof" then
			self:AddRoof(building)
		elseif feature == "Water" then
			self:AddWaterEffect(building)
		elseif feature == "Benches" then
			self:AddBenches(building)
		elseif feature == "Lighting" then
			self:AddLighting(building)
		elseif feature == "Particles" then
			self:AddParticleEffects(building)
		end
	end
end

-- Add a door to building
function HubManagerService:AddDoor(building)
	local door = Instance.new("Part")
	door.Name = "Door"
	door.Size = Vector3.new(0.2, 6, 3)
	door.Position = building.Position + Vector3.new(building.Size.X/2, 0, 0)
	door.Anchored = true
	door.Material = Enum.Material.Wood
	door.BrickColor = BrickColor.new("Dark orange")
	door.Parent = building
	
	-- Add door handle
	local handle = Instance.new("Part")
	handle.Name = "Handle"
	handle.Size = Vector3.new(0.3, 0.3, 0.3)
	handle.Position = door.Position + Vector3.new(0, 0, 1)
	handle.Anchored = true
	handle.Material = Enum.Material.Metal
	handle.BrickColor = BrickColor.new("Really black")
	handle.Shape = Enum.PartType.Ball
	handle.Parent = door
end

-- Add windows to building
function HubManagerService:AddWindows(building)
	local windowCount = math.floor(building.Size.X / 4)
	for i = 1, windowCount do
		local window = Instance.new("Part")
		window.Name = "Window_" .. i
		window.Size = Vector3.new(0.1, 3, 2)
		window.Position = building.Position + Vector3.new(
			building.Size.X/2 + 0.1,
			building.Size.Y/4,
			-building.Size.Z/2 + (i * 4)
		)
		window.Anchored = true
		window.Material = Enum.Material.Glass
		window.BrickColor = BrickColor.new("Institutional white")
		window.Transparency = 0.5
		window.Parent = building
	end
end

-- Add sign to building
function HubManagerService:AddSign(building)
	local sign = Instance.new("Part")
	sign.Name = "Sign"
	sign.Size = Vector3.new(0.2, 2, 4)
	sign.Position = building.Position + Vector3.new(building.Size.X/2 + 0.5, building.Size.Y/2, 0)
	sign.Anchored = true
	sign.Material = Enum.Material.SmoothPlastic
	sign.BrickColor = BrickColor.new("Institutional white")
	sign.Parent = building
	
	-- Add text to sign
	local gui = Instance.new("SurfaceGui")
	gui.Face = Enum.NormalId.Front
	gui.Parent = sign
	
	local textLabel = Instance.new("TextLabel")
	textLabel.Size = UDim2.new(1, 0, 1, 0)
	textLabel.BackgroundTransparency = 1
	textLabel.Text = building.Name
	textLabel.TextColor3 = Color3.fromRGB(0, 0, 0)
	textLabel.TextScaled = true
	textLabel.Font = Enum.Font.GothamBold
	textLabel.Parent = gui
end

-- Add roof to building
function HubManagerService:AddRoof(building)
	local roof = Instance.new("Part")
	roof.Name = "Roof"
	roof.Size = Vector3.new(building.Size.X + 2, 1, building.Size.Z + 2)
	roof.Position = building.Position + Vector3.new(0, building.Size.Y/2 + 0.5, 0)
	roof.Anchored = true
	roof.Material = Enum.Material.Slate
	roof.BrickColor = BrickColor.new("Dark red")
	roof.Parent = building
end

-- Add water effect to fountain
function HubManagerService:AddWaterEffect(building)
	-- Water base
	local water = Instance.new("Part")
	water.Name = "Water"
	water.Size = Vector3.new(building.Size.X - 2, 1, building.Size.Z - 2)
	water.Position = building.Position + Vector3.new(0, -building.Size.Y/2 + 0.5, 0)
	water.Anchored = true
	water.Material = Enum.Material.Water
	water.BrickColor = BrickColor.new("Bright blue")
	water.Transparency = 0.3
	water.Parent = building
	
	-- Water particles
	local attachment = Instance.new("Attachment")
	attachment.Position = Vector3.new(0, building.Size.Y/2, 0)
	attachment.Parent = building
	
	local particles = Instance.new("ParticleEmitter")
	particles.Texture = "rbxasset://textures/particles/water_splash_01.png"
	particles.Rate = 50
	particles.SpreadAngle = Vector2.new(45, 45)
	particles.Speed = NumberRange.new(5, 15)
	particles.Lifetime = NumberRange.new(1, 3)
	particles.Color = ColorSequence.new(Color3.fromRGB(100, 150, 255))
	particles.Parent = attachment
end

-- Add benches around building
function HubManagerService:AddBenches(building)
	local benchPositions = {
		Vector3.new(building.Size.X/2 + 3, -building.Size.Y/2, 0),
		Vector3.new(-building.Size.X/2 - 3, -building.Size.Y/2, 0),
		Vector3.new(0, -building.Size.Y/2, building.Size.Z/2 + 3),
		Vector3.new(0, -building.Size.Y/2, -building.Size.Z/2 - 3)
	}
	
	for i, offset in pairs(benchPositions) do
		local bench = Instance.new("Part")
		bench.Name = "Bench_" .. i
		bench.Size = Vector3.new(4, 1, 1)
		bench.Position = building.Position + offset
		bench.Anchored = true
		bench.Material = Enum.Material.Wood
		bench.BrickColor = BrickColor.new("Brown")
		bench.Parent = building
		
		-- Add seat detection
		self:AddSeatFunction(bench)
	end
end

-- Add lighting to building
function HubManagerService:AddLighting(building)
	local light = Instance.new("PointLight")
	light.Brightness = 2
	light.Range = 20
	light.Color = Color3.fromRGB(255, 220, 150)
	light.Parent = building
	
	-- Add lamp post
	local lampPost = Instance.new("Part")
	lampPost.Name = "LampPost"
	lampPost.Size = Vector3.new(0.5, 8, 0.5)
	lampPost.Position = building.Position + Vector3.new(building.Size.X/2 + 5, 0, 0)
	lampPost.Anchored = true
	lampPost.Material = Enum.Material.Metal
	lampPost.BrickColor = BrickColor.new("Dark grey")
	lampPost.Parent = building
	
	-- Add lamp
	local lamp = Instance.new("Part")
	lamp.Name = "Lamp"
	lamp.Size = Vector3.new(2, 1, 2)
	lamp.Position = lampPost.Position + Vector3.new(0, 4, 0)
	lamp.Anchored = true
	lamp.Material = Enum.Material.Neon
	lamp.BrickColor = BrickColor.new("Institutional white")
	lamp.Shape = Enum.PartType.Ball
	lamp.Parent = lampPost
	
	-- Add light to lamp
	local lampLight = Instance.new("PointLight")
	lampLight.Brightness = 1.5
	lampLight.Range = 15
	lampLight.Color = Color3.fromRGB(255, 240, 200)
	lampLight.Parent = lamp
end

-- Add particle effects
function HubManagerService:AddParticleEffects(building)
	local attachment = Instance.new("Attachment")
	attachment.Position = Vector3.new(0, building.Size.Y/2, 0)
	attachment.Parent = building
	
	local particles = Instance.new("ParticleEmitter")
	particles.Texture = "rbxasset://textures/particles/sparkles_main.dds"
	particles.Rate = 20
	particles.SpreadAngle = Vector2.new(360, 360)
	particles.Speed = NumberRange.new(2, 8)
	particles.Lifetime = NumberRange.new(2, 5)
	particles.Color = ColorSequence.new(Color3.fromRGB(255, 255, 100))
	particles.Parent = attachment
end

-- Add seat functionality to benches
function HubManagerService:AddSeatFunction(bench)
	local seat = Instance.new("Seat")
	seat.Size = bench.Size
	seat.Position = bench.Position + Vector3.new(0, 0.5, 0)
	seat.Anchored = true
	seat.Material = bench.Material
	seat.BrickColor = bench.BrickColor
	seat.Transparency = 1 -- Invisible, but functional
	seat.Parent = bench
end

-- Add interaction zone to buildings
function HubManagerService:AddInteractionZone(building, buildingType)
	local interactionZone = Instance.new("Part")
	interactionZone.Name = "InteractionZone"
	interactionZone.Size = building.Size + Vector3.new(4, 4, 4)
	interactionZone.Position = building.Position
	interactionZone.Anchored = true
	interactionZone.CanCollide = false
	interactionZone.Transparency = 1
	interactionZone.Parent = building
	
	-- Store building type for interaction handling
	local stringValue = Instance.new("StringValue")
	stringValue.Name = "BuildingType"
	stringValue.Value = buildingType
	stringValue.Parent = interactionZone
end

-- Get zone folder for position
function HubManagerService:GetZoneForPosition(position)
	if not hubFolder then return nil end
	
	for zoneName, zoneData in pairs(HUB_ZONES) do
		local distance = (position - zoneData.position).Magnitude
		local maxDistance = math.max(zoneData.size.X, zoneData.size.Z) / 2
		
		if distance <= maxDistance then
			return hubFolder:FindFirstChild(zoneName)
		end
	end
	
	return nil
end

-- Create pathways between zones
function HubManagerService:CreatePathways()
	if not hubFolder then return end
	
	local pathwaysFolder = Instance.new("Folder")
	pathwaysFolder.Name = "Pathways"
	pathwaysFolder.Parent = hubFolder
	
	-- Main pathways connecting zones
	local pathConnections = {
		{HUB_ZONES.CentralPlaza.position, HUB_ZONES.PlayPortal.position},
		{HUB_ZONES.CentralPlaza.position, HUB_ZONES.CommerceDistrict.position},
		{HUB_ZONES.CentralPlaza.position, HUB_ZONES.ProgressionHub.position},
		{HUB_ZONES.CentralPlaza.position, HUB_ZONES.SocialCorner.position},
		{HUB_ZONES.CommerceDistrict.position, HUB_ZONES.TutorialGarden.position}
	}
	
	for i, connection in pairs(pathConnections) do
		self:CreatePathway(connection[1], connection[2], pathwaysFolder, "MainPath_" .. i)
	end
	
	print("🛤️ Created " .. #pathConnections .. " pathways")
end

-- Create a pathway between two points
function HubManagerService:CreatePathway(startPos, endPos, parent, name)
	local direction = (endPos - startPos)
	local distance = direction.Magnitude
	local midPoint = startPos + direction / 2
	
	local pathway = Instance.new("Part")
	pathway.Name = name
	pathway.Size = Vector3.new(4, 0.2, distance)
	pathway.Position = midPoint
	pathway.Anchored = true
	pathway.Material = Enum.Material.Concrete
	pathway.BrickColor = BrickColor.new("Medium grey")
	pathway.Parent = parent
	
	-- Rotate to align with direction
	pathway.CFrame = CFrame.lookAt(midPoint, endPos)
	
	-- Add pathway lighting
	local lightSpacing = 10
	local lightCount = math.floor(distance / lightSpacing)
	
	for i = 1, lightCount do
		local lightPos = startPos + direction * (i / lightCount)
		self:CreatePathwayLight(lightPos, pathway)
	end
end

-- Create pathway lighting
function HubManagerService:CreatePathwayLight(position, parent)
	local light = Instance.new("Part")
	light.Name = "PathwayLight"
	light.Size = Vector3.new(0.5, 4, 0.5)
	light.Position = position + Vector3.new(0, 2, 0)
	light.Anchored = true
	light.Material = Enum.Material.Metal
	light.BrickColor = BrickColor.new("Dark grey")
	light.Parent = parent
	
	local lamp = Instance.new("Part")
	lamp.Name = "Lamp"
	lamp.Size = Vector3.new(1, 0.5, 1)
	lamp.Position = light.Position + Vector3.new(0, 2.25, 0)
	lamp.Anchored = true
	lamp.Material = Enum.Material.Neon
	lamp.BrickColor = BrickColor.new("Institutional white")
	lamp.Parent = light
	
	local pointLight = Instance.new("PointLight")
	pointLight.Brightness = 1
	pointLight.Range = 8
	pointLight.Color = Color3.fromRGB(255, 240, 200)
	pointLight.Parent = lamp
end

-- Setup complete hub
function HubManagerService:SetupCompleteHub()
	print("🏗️ Setting up complete game hub...")
	
	-- Create structure
	self:CreateHubStructure()
	
	-- Create pathways
	self:CreatePathways()
	
	-- Create key buildings
	self:CreateBuilding("Fountain", HUB_ZONES.CentralPlaza.position, Vector3.new(0, 0, 0))
	self:CreateBuilding("Shop", HUB_ZONES.CommerceDistrict.position + Vector3.new(-15, 0, 10), Vector3.new(0, 0, 0))
	self:CreateBuilding("CrateStation", HUB_ZONES.CommerceDistrict.position + Vector3.new(-15, 0, -10), Vector3.new(0, 0, 0))
	self:CreateBuilding("CosmeticsBoutique", HUB_ZONES.CommerceDistrict.position + Vector3.new(5, 0, -20), Vector3.new(0, 0, 0))
	self:CreateBuilding("RebirthTemple", HUB_ZONES.ProgressionHub.position + Vector3.new(15, 0, 10), Vector3.new(0, 0, 0))
	self:CreateBuilding("UpgradeStation", HUB_ZONES.ProgressionHub.position + Vector3.new(15, 0, -10), Vector3.new(0, 0, 0))
	
	-- Setup ambient lighting
	self:SetupHubLighting()
	
	print("✅ Complete hub setup finished!")
end

-- Setup ambient lighting for hub
function HubManagerService:SetupHubLighting()
	-- Adjust overall lighting
	Lighting.Brightness = 2
	Lighting.Ambient = Color3.fromRGB(100, 100, 120)
	Lighting.OutdoorAmbient = Color3.fromRGB(150, 150, 180)
	Lighting.TimeOfDay = "14:00:00" -- Afternoon lighting
	
	-- Add sky if not present
	if not Lighting:FindFirstChild("Sky") then
		local sky = Instance.new("Sky")
		sky.SkyboxBk = "rbxasset://textures/sky/sky512_bk.tex"
		sky.SkyboxDn = "rbxasset://textures/sky/sky512_dn.tex"
		sky.SkyboxFt = "rbxasset://textures/sky/sky512_ft.tex"
		sky.SkyboxLf = "rbxasset://textures/sky/sky512_lf.tex"
		sky.SkyboxRt = "rbxasset://textures/sky/sky512_rt.tex"
		sky.SkyboxUp = "rbxasset://textures/sky/sky512_up.tex"
		sky.Parent = Lighting
	end
end

-- Get zone information
function HubManagerService.Client:GetZoneInfo(player, zoneName)
	local zoneData = HUB_ZONES[zoneName]
	if not zoneData then
		return {success = false, message = "Zone not found"}
	end
	
	return {
		success = true,
		zone = {
			name = zoneData.name,
			description = zoneData.description,
			position = zoneData.position,
			size = zoneData.size
		}
	}
end

-- Get all zones
function HubManagerService.Client:GetAllZones(player)
	local zones = {}
	for zoneName, zoneData in pairs(HUB_ZONES) do
		zones[zoneName] = {
			name = zoneData.name,
			description = zoneData.description,
			position = zoneData.position,
			size = zoneData.size,
			color = zoneData.color
		}
	end
	
	return {success = true, zones = zones}
end

-- Service-specific initialization
function HubManagerService:OnInit()
	-- Validate hub-related world objects
	print("🔍 Validating hub world objects...")
	local missingObjects = WorldObjectValidator.validateAllRequired()
	if #missingObjects > 0 then
		warn("⚠️ HubManagerService: Missing required world objects:")
		for _, missing in ipairs(missingObjects) do
			warn("  • " .. missing)
		end
	end
	
	-- Ensure critical hub objects exist
	local hubExists = WorldObjectValidator.validateObjectWithWait("workspace.Hub", 5)
	if not hubExists then
		print("🔧 HubManagerService: Creating Hub folder...")
		WorldObjectValidator.createObjectIfMissing("workspace.Hub", "Folder", "workspace")
	end
	
	-- Validate spawn location
	local spawnExists = WorldObjectValidator.validateObjectWithWait("workspace.SpawnLocation", 3)
	if not spawnExists then
		warn("⚠️ HubManagerService: SpawnLocation missing - players may spawn incorrectly")
	end
	
	print("✅ Hub world object validation completed")
	return true
end

-- Service-specific start logic
function HubManagerService:OnStart()
	print("🏙️ HubManagerService starting...")
	
	-- Wait for workspace to be ready
	task.wait(2) -- UPDATED for modern API
	
	-- Setup the complete hub
	self:SetupCompleteHub()
	
	print("✅ HubManagerService ready - Game hub is live!")
	return true
end

return HubManagerService
