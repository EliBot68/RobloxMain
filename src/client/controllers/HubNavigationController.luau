--[[
	HubNavigationController
	Client-side controller for hub navigation and interactions
	Handles building interactions, zone detection, and mobile-friendly UI
--]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")

local Knit = require(ReplicatedStorage.Packages.Knit)

local HubNavigationController = Knit.CreateController {
	Name = "HubNavigationController",
}

-- Services
local HubManagerService = nil
local TeleportService = nil

-- UI Elements
local hubGui = nil
local currentZoneLabel = nil
local interactionPrompt = nil
local miniMap = nil

-- State tracking
local currentZone = nil
local nearbyBuildings = {}
local isInHub = false

-- Zone detection configuration
local ZONE_CHECK_INTERVAL = 1 -- Check zone every second
local INTERACTION_DISTANCE = 8 -- Distance to show interaction prompts

-- Building interaction mappings
local BUILDING_INTERACTIONS = {
	Shop = {
		title = "🛍️ Shop",
		description = "Purchase upgrades and items",
		action = "OpenShop"
	},
	CrateStation = {
		title = "📦 Mystery Crates",
		description = "Open crates for random rewards",
		action = "OpenCrates"
	},
	CosmeticsBoutique = {
		title = "👗 Cosmetics",
		description = "Customize your character",
		action = "OpenCosmetics"
	},
	RebirthTemple = {
		title = "⭐ Rebirth",
		description = "Reset progress for permanent bonuses",
		action = "OpenRebirth"
	},
	UpgradeStation = {
		title = "⚡ Upgrades",
		description = "Improve your abilities",
		action = "OpenUpgrades"
	},
	Fountain = {
		title = "⛲ Fountain",
		description = "Make a wish (coming soon)",
		action = "MakeWish"
	}
}

-- Create hub navigation UI
local function createHubUI()
	-- Main GUI
	hubGui = Instance.new("ScreenGui")
	hubGui.Name = "HubNavigation"
	hubGui.ResetOnSpawn = false
	hubGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	hubGui.Parent = Players.LocalPlayer:WaitForChild("PlayerGui")
	
	-- Current zone indicator
	currentZoneLabel = Instance.new("TextLabel")
	currentZoneLabel.Name = "CurrentZone"
	currentZoneLabel.Size = UDim2.new(0, 300, 0, 40)
	currentZoneLabel.Position = UDim2.new(0, 20, 0, 20)
	currentZoneLabel.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
	currentZoneLabel.BackgroundTransparency = 0.3
	currentZoneLabel.BorderSizePixel = 0
	currentZoneLabel.Text = "Hub Area"
	currentZoneLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
	currentZoneLabel.TextScaled = true
	currentZoneLabel.Font = Enum.Font.GothamBold
	currentZoneLabel.Visible = false
	currentZoneLabel.Parent = hubGui
	
	-- Corner rounding
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 8)
	corner.Parent = currentZoneLabel
	
	-- Interaction prompt
	interactionPrompt = Instance.new("Frame")
	interactionPrompt.Name = "InteractionPrompt"
	interactionPrompt.Size = UDim2.new(0, 350, 0, 120)
	interactionPrompt.Position = UDim2.new(0.5, -175, 1, -150)
	interactionPrompt.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
	interactionPrompt.BorderSizePixel = 0
	interactionPrompt.Visible = false
	interactionPrompt.Parent = hubGui
	
	local promptCorner = Instance.new("UICorner")
	promptCorner.CornerRadius = UDim.new(0, 12)
	promptCorner.Parent = interactionPrompt
	
	-- Interaction title
	local interactionTitle = Instance.new("TextLabel")
	interactionTitle.Name = "Title"
	interactionTitle.Size = UDim2.new(1, -20, 0, 30)
	interactionTitle.Position = UDim2.new(0, 10, 0, 10)
	interactionTitle.BackgroundTransparency = 1
	interactionTitle.Text = "Building Name"
	interactionTitle.TextColor3 = Color3.fromRGB(255, 255, 255)
	interactionTitle.TextScaled = true
	interactionTitle.Font = Enum.Font.GothamBold
	interactionTitle.TextXAlignment = Enum.TextXAlignment.Left
	interactionTitle.Parent = interactionPrompt
	
	-- Interaction description
	local interactionDesc = Instance.new("TextLabel")
	interactionDesc.Name = "Description"
	interactionDesc.Size = UDim2.new(1, -20, 0, 40)
	interactionDesc.Position = UDim2.new(0, 10, 0, 35)
	interactionDesc.BackgroundTransparency = 1
	interactionDesc.Text = "Description of what this building does"
	interactionDesc.TextColor3 = Color3.fromRGB(200, 200, 200)
	interactionDesc.TextScaled = true
	interactionDesc.Font = Enum.Font.Gotham
	interactionDesc.TextXAlignment = Enum.TextXAlignment.Left
	interactionDesc.TextWrapped = true
	interactionDesc.Parent = interactionPrompt
	
	-- Interaction button
	local interactionButton = Instance.new("TextButton")
	interactionButton.Name = "InteractionButton"
	interactionButton.Size = UDim2.new(1, -20, 0, 35)
	interactionButton.Position = UDim2.new(0, 10, 1, -45)
	interactionButton.BackgroundColor3 = Color3.fromRGB(70, 130, 180)
	interactionButton.BorderSizePixel = 0
	interactionButton.Text = "Interact"
	interactionButton.TextColor3 = Color3.fromRGB(255, 255, 255)
	interactionButton.TextScaled = true
	interactionButton.Font = Enum.Font.GothamBold
	interactionButton.Parent = interactionPrompt
	
	local buttonCorner = Instance.new("UICorner")
	buttonCorner.CornerRadius = UDim.new(0, 8)
	buttonCorner.Parent = interactionButton
	
	-- Button hover effects
	interactionButton.MouseEnter:Connect(function()
		TweenService:Create(interactionButton, TweenInfo.new(0.2), {
			BackgroundColor3 = Color3.fromRGB(90, 150, 200)
		}):Play()
	end)
	
	interactionButton.MouseLeave:Connect(function()
		TweenService:Create(interactionButton, TweenInfo.new(0.2), {
			BackgroundColor3 = Color3.fromRGB(70, 130, 180)
		}):Play()
	end)
	
	-- Store references for later use
	HubNavigationController.interactionTitle = interactionTitle
	HubNavigationController.interactionDesc = interactionDesc
	HubNavigationController.interactionButton = interactionButton
	
	-- Mobile touch/PC click support
	interactionButton.Activated:Connect(function()
		HubNavigationController:HandleInteraction()
	end)
	
	-- Create mini-map
	createMiniMap()
end

-- Create mini-map for navigation
function createMiniMap()
	miniMap = Instance.new("Frame")
	miniMap.Name = "MiniMap"
	miniMap.Size = UDim2.new(0, 200, 0, 200)
	miniMap.Position = UDim2.new(1, -220, 0, 20)
	miniMap.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
	miniMap.BackgroundTransparency = 0.3
	miniMap.BorderSizePixel = 0
	miniMap.Visible = false
	miniMap.Parent = hubGui
	
	local mapCorner = Instance.new("UICorner")
	mapCorner.CornerRadius = UDim.new(0, 12)
	mapCorner.Parent = miniMap
	
	-- Map title
	local mapTitle = Instance.new("TextLabel")
	mapTitle.Name = "MapTitle"
	mapTitle.Size = UDim2.new(1, 0, 0, 25)
	mapTitle.Position = UDim2.new(0, 0, 0, 0)
	mapTitle.BackgroundTransparency = 1
	mapTitle.Text = "🗺️ Hub Map"
	mapTitle.TextColor3 = Color3.fromRGB(255, 255, 255)
	mapTitle.TextScaled = true
	mapTitle.Font = Enum.Font.GothamBold
	mapTitle.Parent = miniMap
	
	-- Map content frame
	local mapContent = Instance.new("Frame")
	mapContent.Name = "MapContent"
	mapContent.Size = UDim2.new(1, -10, 1, -35)
	mapContent.Position = UDim2.new(0, 5, 0, 30)
	mapContent.BackgroundTransparency = 1
	mapContent.Parent = miniMap
	
	-- Add zone indicators to mini-map
	HubManagerService:GetAllZones():andThen(function(result)
		if result.success then
			for zoneName, zoneData in pairs(result.zones) do
				local zoneIndicator = Instance.new("Frame")
				zoneIndicator.Name = zoneName .. "_Indicator"
				zoneIndicator.Size = UDim2.new(0, 30, 0, 30)
				zoneIndicator.BackgroundColor3 = zoneData.color
				zoneIndicator.BorderSizePixel = 0
				zoneIndicator.Parent = mapContent
				
				local indicatorCorner = Instance.new("UICorner")
				indicatorCorner.CornerRadius = UDim.new(0, 4)
				indicatorCorner.Parent = zoneIndicator
				
				-- Position based on zone position (simplified mapping)
				local mapX = (zoneData.position.X + 100) / 200 -- Normalize to 0-1
				local mapZ = (zoneData.position.Z + 100) / 200 -- Normalize to 0-1
				zoneIndicator.Position = UDim2.new(mapX, -15, mapZ, -15)
				
				-- Zone label
				local zoneLabel = Instance.new("TextLabel")
				zoneLabel.Size = UDim2.new(1, 0, 1, 0)
				zoneLabel.BackgroundTransparency = 1
				zoneLabel.Text = string.sub(zoneName, 1, 1) -- First letter
				zoneLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
				zoneLabel.TextScaled = true
				zoneLabel.Font = Enum.Font.GothamBold
				zoneLabel.Parent = zoneIndicator
			end
		end
	end)
end

-- Check current zone
local function checkCurrentZone()
	if not isInHub then return end
	
	local player = Players.LocalPlayer
	local character = player.Character
	if not character or not character:FindFirstChild("HumanoidRootPart") then
		return
	end
	
	local position = character.HumanoidRootPart.Position
	
	-- Get zone information
	HubManagerService:GetAllZones():andThen(function(result)
		if result.success then
			local newZone = nil
			local minDistance = math.huge
			
			-- Find closest zone
			for zoneName, zoneData in pairs(result.zones) do
				local distance = (position - zoneData.position).Magnitude
				local maxDistance = math.max(zoneData.size.X, zoneData.size.Z) / 2
				
				if distance <= maxDistance and distance < minDistance then
					newZone = zoneName
					minDistance = distance
				end
			end
			
			-- Update zone if changed
			if newZone ~= currentZone then
				currentZone = newZone
				updateZoneDisplay()
			end
		end
	end)
end

-- Update zone display
function updateZoneDisplay()
	if not currentZoneLabel then return end
	
	if currentZone then
		HubManagerService:GetZoneInfo(currentZone):andThen(function(result)
			if result.success then
				currentZoneLabel.Text = "📍 " .. result.zone.name
				currentZoneLabel.Visible = true
				
				-- Animate zone change
				currentZoneLabel.BackgroundTransparency = 1
				TweenService:Create(currentZoneLabel, TweenInfo.new(0.5), {
					BackgroundTransparency = 0.3
				}):Play()
			end
		end)
	else
		currentZoneLabel.Visible = false
	end
end

-- Check for nearby buildings
local function checkNearbyBuildings()
	if not isInHub then return end
	
	local player = Players.LocalPlayer
	local character = player.Character
	if not character or not character:FindFirstChild("HumanoidRootPart") then
		return
	end
	
	local position = character.HumanoidRootPart.Position
	local newNearbyBuildings = {}
	
	-- Find GameHub folder
	local gameHub = Workspace:FindFirstChild("GameHub")
	if not gameHub then return end
	
	-- Check all interaction zones
	for _, zone in pairs(gameHub:GetChildren()) do
		if zone:IsA("Folder") then
			for _, building in pairs(zone:GetChildren()) do
				local interactionZone = building:FindFirstChild("InteractionZone")
				if interactionZone then
					local distance = (position - interactionZone.Position).Magnitude
					if distance <= INTERACTION_DISTANCE then
						local buildingType = interactionZone:FindFirstChild("BuildingType")
						if buildingType and BUILDING_INTERACTIONS[buildingType.Value] then
							table.insert(newNearbyBuildings, {
								building = building,
								type = buildingType.Value,
								distance = distance
							})
						end
					end
				end
			end
		end
	end
	
	-- Sort by distance
	table.sort(newNearbyBuildings, function(a, b)
		return a.distance < b.distance
	end)
	
	-- Update interaction prompt
	if #newNearbyBuildings > 0 and #newNearbyBuildings ~= #nearbyBuildings then
		showInteractionPrompt(newNearbyBuildings[1])
	elseif #newNearbyBuildings == 0 and interactionPrompt then
		hideInteractionPrompt()
	end
	
	nearbyBuildings = newNearbyBuildings
end

-- Show interaction prompt
function showInteractionPrompt(buildingData)
	if not interactionPrompt then return end
	
	local interaction = BUILDING_INTERACTIONS[buildingData.type]
	if not interaction then return end
	
	-- Update prompt content
	HubNavigationController.interactionTitle.Text = interaction.title
	HubNavigationController.interactionDesc.Text = interaction.description
	HubNavigationController.interactionButton.Text = "Press to " .. interaction.action:gsub("Open", "Enter ")
	
	-- Store current interaction
	HubNavigationController.currentInteraction = interaction
	
	-- Show with animation
	interactionPrompt.Position = UDim2.new(0.5, -175, 1, 0)
	interactionPrompt.Visible = true
	
	TweenService:Create(interactionPrompt, TweenInfo.new(0.3, Enum.EasingStyle.Back), {
		Position = UDim2.new(0.5, -175, 1, -150)
	}):Play()
end

-- Hide interaction prompt
function hideInteractionPrompt()
	if not interactionPrompt or not interactionPrompt.Visible then return end
	
	local hideTween = TweenService:Create(interactionPrompt, TweenInfo.new(0.3, Enum.EasingStyle.Back), {
		Position = UDim2.new(0.5, -175, 1, 0)
	})
	hideTween:Play()
	
	-- Event-driven visibility change (NO POLLING)
	hideTween.Completed:Connect(function()
		interactionPrompt.Visible = false
		HubNavigationController.currentInteraction = nil
	end)
end

-- Handle building interaction
function HubNavigationController:HandleInteraction()
	if not self.currentInteraction then return end
	
	local action = self.currentInteraction.action
	
	-- Route to appropriate service
	if action == "OpenShop" then
		local ShopService = Knit.GetService("ShopService")
		if ShopService then
			ShopService:OpenShop()
		end
	elseif action == "OpenCrates" then
		local CrateService = Knit.GetService("CrateService")
		if CrateService then
			CrateService:OpenCrateUI()
		end
	elseif action == "OpenCosmetics" then
		local CosmeticService = Knit.GetService("CosmeticService")
		if CosmeticService then
			CosmeticService:OpenCosmeticsUI()
		end
	elseif action == "OpenRebirth" then
		local RebirthService = Knit.GetService("RebirthService")
		if RebirthService then
			RebirthService:OpenRebirthUI()
		end
	elseif action == "OpenUpgrades" then
		local UpgradeService = Knit.GetService("UpgradeService")
		if UpgradeService then
			UpgradeService:OpenUpgradeUI()
		end
	elseif action == "MakeWish" then
		-- Fun feature for fountain
		print("🌟 You made a wish at the fountain!")
	end
	
	-- Hide prompt after interaction
	hideInteractionPrompt()
end

-- Detect if player is in hub
local function detectHubPresence()
	local player = Players.LocalPlayer
	local character = player.Character
	if not character or not character:FindFirstChild("HumanoidRootPart") then
		return
	end
	
	local position = character.HumanoidRootPart.Position
	local gameHub = Workspace:FindFirstChild("GameHub")
	
	if gameHub then
		-- Check if player is within hub bounds (simple distance check)
		local hubCenter = Vector3.new(0, 5, 0) -- Central plaza position
		local hubRadius = 150 -- Maximum distance from center
		local distance = (position - hubCenter).Magnitude
		
		local wasInHub = isInHub
		isInHub = distance <= hubRadius
		
		-- Show/hide UI based on hub presence
		if isInHub ~= wasInHub then
			if isInHub then
				showHubUI()
			else
				hideHubUI()
			end
		end
	end
end

-- Show hub UI
function showHubUI()
	if currentZoneLabel then
		currentZoneLabel.Visible = true
	end
	if miniMap then
		miniMap.Visible = true
	end
end

-- Hide hub UI
function hideHubUI()
	if currentZoneLabel then
		currentZoneLabel.Visible = false
	end
	if miniMap then
		miniMap.Visible = false
	end
	if interactionPrompt then
		hideInteractionPrompt()
	end
	currentZone = nil
	nearbyBuildings = {}
end

-- Keyboard shortcut for map toggle
local function setupKeyboardShortcuts()
	UserInputService.InputBegan:Connect(function(input, gameProcessed)
		if gameProcessed then return end
		
		if input.KeyCode == Enum.KeyCode.M and isInHub then
			-- Toggle mini-map
			if miniMap then
				miniMap.Visible = not miniMap.Visible
			end
		end
	end)
end

function HubNavigationController:KnitStart()
	print("🧭 HubNavigationController starting...")
	
	-- Get services
	HubManagerService = Knit.GetService("HubManagerService")
	TeleportService = Knit.GetService("TeleportService")
	
	-- Create UI
	createHubUI()
	
	-- Setup keyboard shortcuts
	setupKeyboardShortcuts()
	
	-- Start monitoring using single heartbeat connection
	local RunService = game:GetService("RunService")
	local lastHubCheck = 0
	local lastZoneCheck = 0
	local lastBuildingCheck = 0
	
	HubNavigationController.monitorConnection = RunService.Heartbeat:Connect(function()
		local currentTime = tick()
		
		-- Hub presence check every 0.5 seconds
		if currentTime - lastHubCheck >= 0.5 then
			lastHubCheck = currentTime
			detectHubPresence()
		end
		
		-- Zone check at specified interval
		if currentTime - lastZoneCheck >= ZONE_CHECK_INTERVAL then
			lastZoneCheck = currentTime
			checkCurrentZone()
		end
		
		-- Building check every 0.2 seconds for responsiveness
		if currentTime - lastBuildingCheck >= 0.2 then
			lastBuildingCheck = currentTime
			checkNearbyBuildings()
		end
	end)
	
	print("✅ HubNavigationController ready - Hub navigation active!")
end

return HubNavigationController
