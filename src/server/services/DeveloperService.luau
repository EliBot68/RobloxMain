--[[
	DeveloperService
	Server-side service for developer tools and testing
	Handles teleportation, economy grants, save resets, and debugging
--]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TeleportService = game:GetService("TeleportService")
local Workspace = game:GetService("Workspace")

local Knit = require(ReplicatedStorage.Packages.Knit)
local DeveloperConfig = require(ReplicatedStorage.Shared.modules.DeveloperConfig)

local DeveloperService = Knit.CreateService {
	Name = "DeveloperService",
	Client = {},
}

-- Check if player is a developer
local function isDeveloper(player)
	return DeveloperConfig:IsDeveloper(player)
end

-- Missing asset tracking (fallback for ConsoleMonitorService)
local missingAssets = {}
local missingScripts = {}

-- Log missing assets and scripts
local function logMissingAsset(assetType, assetName, location)
	local key = assetType .. ":" .. assetName
	if not missingAssets[key] then
		missingAssets[key] = {
			type = assetType,
			name = assetName,
			location = location,
			firstSeen = tick()
		}
		warn(string.format("Missing %s: %s (Location: %s)", assetType, assetName, location))
	end
end

-- Validate game assets on startup
local function validateGameAssets()
	print("🔍 Validating game assets...")
	
	-- Check for common missing assets
	local commonAssets = {
		-- Sounds
		{type = "Sound", id = "rbxassetid://131961136", name = "RunFootstep"},
		{type = "Sound", id = "rbxassetid://131961136", name = "JumpSound"},
		{type = "Sound", id = "rbxassetid://131961136", name = "CoinCollect"},
		
		-- Images
		{type = "Image", id = "rbxassetid://0", name = "CoinIcon"},
		{type = "Image", id = "rbxassetid://0", name = "XPIcon"},
		
		-- Meshes
		{type = "Mesh", id = "rbxassetid://0", name = "PlayerModel"},
	}
	
	for _, asset in pairs(commonAssets) do
		-- Try to load asset
		local success, result = pcall(function()
			if asset.type == "Sound" then
				local sound = Instance.new("Sound")
				sound.SoundId = asset.id
				sound.Parent = Workspace
				sound:Destroy()
			elseif asset.type == "Image" then
				local image = Instance.new("ImageLabel")
				image.Image = asset.id
				image.Parent = ReplicatedStorage
				image:Destroy()
			end
		end)
		
		if not success then
			logMissingAsset(asset.type, asset.name, "Asset validation")
		end
	end
	
	print("✅ Asset validation complete")
end

-- Check for script errors
local function checkScriptErrors()
	print("🔍 Checking for script errors...")
	
	local function checkContainer(container, containerName)
		for _, child in pairs(container:GetChildren()) do
			if child:IsA("LocalScript") or child:IsA("Script") or child:IsA("ModuleScript") then
				-- Try to require ModuleScripts to check for syntax errors
				if child:IsA("ModuleScript") then
					local success, result = pcall(function()
						return require(child)
					end)
					
					if not success then
						warn(string.format("Script Error in %s/%s: %s", containerName, child.Name, tostring(result)))
						missingScripts[child.Name] = {
							script = child,
							error = tostring(result),
							location = containerName,
							timestamp = tick()
						}
					end
				end
			end
			
			-- Recursively check children
			if child:GetChildren() and #child:GetChildren() > 0 then
				checkContainer(child, containerName .. "/" .. child.Name)
			end
		end
	end
	
	-- Check all script containers
	checkContainer(ReplicatedStorage, "ReplicatedStorage")
	checkContainer(game.ServerScriptService, "ServerScriptService")
	checkContainer(game.StarterPlayer.StarterPlayerScripts, "StarterPlayerScripts")
	
	print("✅ Script error check complete")
end

-- Teleport player to track
function DeveloperService.Client:TeleportToTrack(player, trackName)
	if not isDeveloper(player) then
		warn("Unauthorized teleport attempt by " .. player.Name)
		return
	end
	
	local position = TRACK_POSITIONS[trackName]
	if not position then
		warn("Unknown track: " .. trackName)
		return
	end
	
	local character = player.Character
	if character and character:FindFirstChild("HumanoidRootPart") then
		character.HumanoidRootPart.CFrame = CFrame.new(position)
		print(string.format("Teleported %s to %s", player.Name, trackName))
	end
end

-- Grant coins to player
function DeveloperService.Client:GrantCoins(player, amount)
	if not isDeveloper(player) then
		warn("Unauthorized coin grant attempt by " .. player.Name)
		return
	end
	
	local UnifiedDataService = Knit.GetService("UnifiedDataService")
	local playerData = UnifiedDataService:GetPlayerData(player)
	
	if playerData then
		playerData.coins = (playerData.coins or 0) + amount
		UnifiedDataService:SavePlayerData(player)
		print(string.format("Granted %d coins to %s", amount, player.Name))
		
		-- Update client
		local ReplicatedDataService = Knit.GetService("ReplicatedDataService")
		ReplicatedDataService:UpdatePlayerStat(player, "coins", playerData.coins)
	end
end

-- Grant XP to player
function DeveloperService.Client:GrantXP(player, amount)
	if not isDeveloper(player) then
		warn("Unauthorized XP grant attempt by " .. player.Name)
		return
	end
	
	local UnifiedDataService = Knit.GetService("UnifiedDataService")
	local playerData = UnifiedDataService:GetPlayerData(player)
	
	if playerData then
		playerData.experience = (playerData.experience or 0) + amount
		
		-- Update level if needed
		local EconomyBalanceService = Knit.GetService("EconomyBalanceService")
		local newLevel = EconomyBalanceService:CalculateLevel(playerData.experience)
		playerData.level = newLevel
		
		UnifiedDataService:SavePlayerData(player)
		print(string.format("Granted %d XP to %s (new level: %d)", amount, player.Name, newLevel))
		
		-- Update client
		local ReplicatedDataService = Knit.GetService("ReplicatedDataService")
		ReplicatedDataService:UpdatePlayerStat(player, "experience", playerData.experience)
		ReplicatedDataService:UpdatePlayerStat(player, "level", playerData.level)
	end
end

-- Reset player save data
function DeveloperService.Client:ResetPlayerSave(player)
	if not isDeveloper(player) then
		warn("Unauthorized save reset attempt by " .. player.Name)
		return
	end
	
	local UnifiedDataService = Knit.GetService("UnifiedDataService")
	
	-- Create fresh player data
	local freshData = UnifiedDataService:CreateDefaultPlayerData()
	UnifiedDataService:SetPlayerData(player, freshData)
	UnifiedDataService:SavePlayerData(player)
	
	print(string.format("Reset save data for %s", player.Name))
	
	-- Update client with fresh data
	local ReplicatedDataService = Knit.GetService("ReplicatedDataService")
	ReplicatedDataService:ReplicateFullPlayerData(player, freshData)
	
	-- Kick player to reload (optional)
	player:Kick("Save data reset. Please rejoin to continue.")
end

-- Skip tutorial
function DeveloperService.Client:SkipTutorial(player)
	if not isDeveloper(player) then
		warn("Unauthorized tutorial skip attempt by " .. player.Name)
		return
	end
	
	local UnifiedDataService = Knit.GetService("UnifiedDataService")
	local playerData = UnifiedDataService:GetPlayerData(player)
	
	if playerData then
		playerData.tutorialCompleted = true
		playerData.settings = playerData.settings or {}
		playerData.settings.skipTutorial = true
		
		UnifiedDataService:SavePlayerData(player)
		print(string.format("Skipped tutorial for %s", player.Name))
		
		-- Notify tutorial controller
		local TutorialService = Knit.GetService("TutorialService")
		if TutorialService then
			TutorialService:SkipTutorial(player)
		end
	end
end

-- Log missing assets
function DeveloperService.Client:LogMissingAssets(player)
	if not isDeveloper(player) then
		warn("Unauthorized asset log request by " .. player.Name)
		return
	end
	
	-- Use ConsoleMonitorService for detailed error reporting
	local ConsoleMonitorService = Knit.GetService("ConsoleMonitorService")
	if ConsoleMonitorService then
		local report = ConsoleMonitorService.Client:GetErrorReport(player)
		
		print("📋 Missing Assets & Errors Report:")
		print("==================================")
		print(string.format("Total Errors: %d", report.summary.totalErrors))
		print(string.format("Script Errors: %d", report.summary.scriptErrors))
		print(string.format("Asset Errors: %d", report.summary.assetErrors))
		print(string.format("Missing Objects: %d", report.summary.missingObjects))
		print(string.format("Warnings: %d", report.summary.warnings))
		print("==================================")
		
		if #report.recentErrors > 0 then
			print("Recent Errors (last 5 minutes):")
			for i, error in pairs(report.recentErrors) do
				if i <= 10 then -- Show only first 10
					print(string.format("  [%s] %s: %s", error.type, error.dateTime or "Unknown", error.message))
				end
			end
		else
			print("✅ No recent errors")
		end
		
		-- Trigger new validation
		ConsoleMonitorService.Client:ValidateAssets(player)
	else
		-- Fallback to original asset checking
		print("📋 Missing Assets Report:")
		print("========================")
		
		if next(missingAssets) then
			for key, asset in pairs(missingAssets) do
				print(string.format("❌ %s: %s (Location: %s, First seen: %.2fs ago)", 
					asset.type, asset.name, asset.location, tick() - asset.firstSeen))
			end
		else
			print("✅ No missing assets detected")
		end
		
		print("========================")
		validateGameAssets()
	end
end

-- Check script errors
function DeveloperService.Client:CheckScriptErrors(player)
	if not isDeveloper(player) then
		warn("Unauthorized script check request by " .. player.Name)
		return
	end
	
	-- Use ConsoleMonitorService for detailed error reporting
	local ConsoleMonitorService = Knit.GetService("ConsoleMonitorService")
	if ConsoleMonitorService then
		local report = ConsoleMonitorService.Client:GetErrorReport(player)
		
		print("📋 Script Errors Report:")
		print("========================")
		
		local scriptErrorCount = 0
		for _, error in pairs(report.errors) do
			if error.type == "SCRIPT" then
				scriptErrorCount = scriptErrorCount + 1
				print(string.format("❌ %s: %s", error.source or "Unknown", error.message))
				if error.stack then
					print(string.format("   Stack: %s", error.stack))
				end
			end
		end
		
		if scriptErrorCount == 0 then
			print("✅ No script errors detected")
		end
		
		print("========================")
	else
		-- Fallback to original script checking
		print("📋 Script Errors Report:")
		print("========================")
		
		if next(missingScripts) then
			for name, info in pairs(missingScripts) do
				print(string.format("❌ %s: %s (Location: %s, Time: %.2fs ago)", 
					name, info.error, info.location, tick() - info.timestamp))
			end
		else
			print("✅ No script errors detected")
		end
		
		print("========================")
		checkScriptErrors()
	end
end

-- Unlock all content for testing
function DeveloperService.Client:UnlockAllContent(player)
	if not isDeveloper(player) then
		warn("Unauthorized unlock attempt by " .. player.Name)
		return
	end
	
	local UnifiedDataService = Knit.GetService("UnifiedDataService")
	local playerData = UnifiedDataService:GetPlayerData(player)
	
	if playerData then
		-- Unlock all tracks
		playerData.unlockedTracks = {"Track1", "Track2", "Track3", "Hub"}
		
		-- Unlock all cosmetics
		playerData.unlockedCosmetics = playerData.unlockedCosmetics or {}
		local allCosmetics = {"RedHat", "BlueShirt", "GreenPants", "SpeedBoots", "GoldenCrown"}
		for _, cosmetic in pairs(allCosmetics) do
			playerData.unlockedCosmetics[cosmetic] = true
		end
		
		-- Unlock all upgrades
		playerData.upgrades = playerData.upgrades or {}
		playerData.upgrades.speed = 10
		playerData.upgrades.jump = 10
		playerData.upgrades.coinMultiplier = 5
		
		UnifiedDataService:SavePlayerData(player)
		print(string.format("Unlocked all content for %s", player.Name))
		
		-- Update client
		local ReplicatedDataService = Knit.GetService("ReplicatedDataService")
		ReplicatedDataService:ReplicateFullPlayerData(player, playerData)
	end
end

-- Max player stats
function DeveloperService.Client:MaxPlayerStats(player)
	if not isDeveloper(player) then
		warn("Unauthorized stats max attempt by " .. player.Name)
		return
	end
	
	local UnifiedDataService = Knit.GetService("UnifiedDataService")
	local playerData = UnifiedDataService:GetPlayerData(player)
	
	if playerData then
		-- Max level and experience
		playerData.level = 100
		playerData.experience = 1000000
		
		-- Max coins
		playerData.coins = 1000000
		
		-- Max stats
		playerData.totalRuns = 1000
		playerData.totalDistance = 1000000
		playerData.bestTime = 10.5
		
		-- Max rebirths
		playerData.rebirths = 10
		
		UnifiedDataService:SavePlayerData(player)
		print(string.format("Maxed stats for %s", player.Name))
		
		-- Update client
		local ReplicatedDataService = Knit.GetService("ReplicatedDataService")
		ReplicatedDataService:ReplicateFullPlayerData(player, playerData)
	end
end

-- Monitor for missing assets during runtime
local function monitorAssets()
	-- Hook into common asset loading failures
	game.ContentProvider.RequestQueueSize:GetPropertyChangedSignal():Connect(function()
		if game.ContentProvider.RequestQueueSize > 10 then
			warn("⚠️ High asset request queue size: " .. game.ContentProvider.RequestQueueSize)
		end
	end)
	
	-- Monitor script errors
	game.ScriptContext.Error:Connect(function(message, stack, script)
		if script then
			local errorInfo = {
				message = message,
				stack = stack,
				script = script.Name,
				location = script.Parent and script.Parent.Name or "Unknown",
				timestamp = tick()
			}
			
			missingScripts[script.Name .. "_runtime"] = errorInfo
			warn(string.format("Runtime Script Error in %s: %s", script.Name, message))
		end
	end)
end

function DeveloperService:KnitStart()
	-- Start asset validation and monitoring
	validateGameAssets()
	checkScriptErrors()
	monitorAssets()
	
	print("🛠️ DeveloperService started - Developer tools available")
end

return DeveloperService
