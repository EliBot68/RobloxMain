--[[
	ConsoleMonitorService
	Monitors and logs console errors for missing assets and scripts
	Provides debugging information for developers
--]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local ContentProvider = game:GetService("ContentProvider")
local ScriptContext = game:GetService("ScriptContext")

local SafeRequire = require(ReplicatedStorage.Shared.utils.SafeRequire)
local Knit = SafeRequire.require(ReplicatedStorage.Packages.Knit)
local DeveloperConfig = SafeRequire.require(ReplicatedStorage.Shared.modules.DeveloperConfig)

local ConsoleMonitorService = Knit.CreateService {
	Name = "ConsoleMonitorService",
	Client = {},
}

-- Error tracking
local errorLog = {}
local assetErrors = {}
local scriptErrors = {}
local warningLog = {}

-- Check if player is a developer
local function isDeveloper(player)
	return DeveloperConfig:IsDeveloper(player)
end

-- Log error with detailed information
local function logError(errorType, message, source, stack)
	local timestamp = tick()
	local errorId = errorType .. "_" .. timestamp
	
	local errorData = {
		id = errorId,
		type = errorType,
		message = message,
		source = source,
		stack = stack,
		timestamp = timestamp,
		dateTime = os.date("%Y-%m-%d %H:%M:%S", timestamp)
	}
	
	errorLog[errorId] = errorData
	
	-- Print to console with formatting
	local formattedMessage = string.format(
		"🚨 [%s] %s Error: %s\n   Source: %s\n   Time: %s",
		errorType,
		errorData.dateTime,
		message,
		source or "Unknown",
		errorData.dateTime
	)
	
	warn(formattedMessage)
	
	-- Notify online developers
	for _, player in pairs(Players:GetPlayers()) do
		if isDeveloper(player) then
			-- Send error notification to developer
			ConsoleMonitorService.Client.ErrorNotification:Fire(player, errorData)
		end
	end
	
	return errorData
end

-- Monitor script errors
local function setupScriptErrorMonitoring()
	ScriptContext.Error:Connect(function(message, stack, script)
		local source = "Unknown Script"
		local location = "Unknown Location"
		
		if script then
			source = script.Name
			if script.Parent then
				location = script.Parent.Name
			end
		end
		
		local errorData = logError("SCRIPT", message, source .. " (" .. location .. ")", stack)
		scriptErrors[source] = errorData
	end)
	
	print("📡 Script error monitoring active")
end

-- Monitor asset loading errors
local function setupAssetErrorMonitoring()
	-- Monitor ContentProvider for asset loading issues
	ContentProvider.RequestQueueSize:GetPropertyChangedSignal():Connect(function()
		local queueSize = ContentProvider.RequestQueueSize
		if queueSize > 50 then
			local warningData = {
				type = "ASSET_QUEUE",
				message = "High asset request queue size: " .. queueSize,
				timestamp = tick(),
				severity = queueSize > 100 and "HIGH" or "MEDIUM"
			}
			
			warningLog[#warningLog + 1] = warningData
			warn("⚠️ High asset request queue: " .. queueSize .. " pending requests")
		end
	end)
	
	-- Hook into common asset loading functions
	local originalLoadAsset = ContentProvider.PreloadAsync
	ContentProvider.PreloadAsync = function(self, assets, callback)
		local success, result = pcall(originalLoadAsset, self, assets, callback)
		
		if not success then
			logError("ASSET", "Failed to preload assets: " .. tostring(result), "ContentProvider.PreloadAsync")
		end
		
		return success and result
	end
	
	print("📡 Asset error monitoring active")
end

-- Monitor missing workspace objects
local function checkWorkspaceObjects()
	local requiredObjects = DeveloperConfig.REQUIRED_OBJECTS
	
	-- Check workspace objects
	for _, objectName in pairs(requiredObjects.WORKSPACE) do
		if not Workspace:FindFirstChild(objectName) then
			logError("MISSING_OBJECT", "Required workspace object not found: " .. objectName, "Workspace")
		end
	end
	
	-- Check for game tracks
	local gameTracks = Workspace:FindFirstChild("GameTracks")
	if gameTracks then
		for _, trackName in pairs(requiredObjects.GAME_TRACKS) do
			if not gameTracks:FindFirstChild(trackName) then
				logError("MISSING_TRACK", "Required track not found: " .. trackName, "GameTracks")
			end
		end
	end
end

-- Monitor ReplicatedStorage structure
local function checkReplicatedStorageStructure()
	local requiredObjects = DeveloperConfig.REQUIRED_OBJECTS
	
	-- Check ReplicatedStorage folders
	for _, folderName in pairs(requiredObjects.REPLICATED_STORAGE) do
		if not ReplicatedStorage:FindFirstChild(folderName) then
			logError("MISSING_FOLDER", "Required ReplicatedStorage folder not found: " .. folderName, "ReplicatedStorage")
		end
	end
	
	-- Check Shared structure
	local shared = ReplicatedStorage:FindFirstChild("Shared")
	if shared then
		for _, folderName in pairs(requiredObjects.SHARED_FOLDERS) do
			if not shared:FindFirstChild(folderName) then
				logError("MISSING_SHARED", "Required Shared folder not found: " .. folderName, "ReplicatedStorage.Shared")
			end
		end
	end
end

-- Get error report for developers
function ConsoleMonitorService.Client:GetErrorReport(player)
	if not isDeveloper(player) then
		return {success = false, message = "Access denied"}
	end
	
	local report = {
		success = true,
		timestamp = tick(),
		summary = {
			totalErrors = 0,
			scriptErrors = 0,
			assetErrors = 0,
			missingObjects = 0,
			warnings = #warningLog
		},
		errors = {},
		recentErrors = {}
	}
	
	-- Count and categorize errors
	for _, errorData in pairs(errorLog) do
		report.summary.totalErrors = report.summary.totalErrors + 1
		
		if errorData.type == "SCRIPT" then
			report.summary.scriptErrors = report.summary.scriptErrors + 1
		elseif errorData.type == "ASSET" then
			report.summary.assetErrors = report.summary.assetErrors + 1
		elseif errorData.type == "MISSING_OBJECT" or errorData.type == "MISSING_TRACK" or errorData.type == "MISSING_FOLDER" then
			report.summary.missingObjects = report.summary.missingObjects + 1
		end
		
		-- Add to full error list
		table.insert(report.errors, errorData)
		
		-- Add to recent errors (last 5 minutes)
		if tick() - errorData.timestamp < 300 then
			table.insert(report.recentErrors, errorData)
		end
	end
	
	-- Sort recent errors by timestamp (newest first)
	table.sort(report.recentErrors, function(a, b)
		return a.timestamp > b.timestamp
	end)
	
	return report
end

-- Clear error log (developer only)
function ConsoleMonitorService.Client:ClearErrorLog(player)
	if not isDeveloper(player) then
		return {success = false, message = "Access denied"}
	end
	
	local clearedCount = 0
	for _ in pairs(errorLog) do
		clearedCount = clearedCount + 1
	end
	
	errorLog = {}
	assetErrors = {}
	scriptErrors = {}
	warningLog = {}
	
	print(string.format("🧹 Error log cleared by %s (%d errors removed)", player.Name, clearedCount))
	
	return {success = true, message = string.format("Cleared %d errors", clearedCount)}
end

-- Force asset validation check
function ConsoleMonitorService.Client:ValidateAssets(player)
	if not isDeveloper(player) then
		return {success = false, message = "Access denied"}
	end
	
	print("🔍 Running asset validation check...")
	
	-- Re-run all validation checks
	checkWorkspaceObjects()
	checkReplicatedStorageStructure()
	
	-- Test common asset IDs
	local testAssets = {
		"rbxassetid://131961136", -- Common sound
		"rbxassetid://0", -- Invalid asset
	}
	
	for _, assetId in pairs(testAssets) do
		spawn(function()
			local success, result = pcall(function()
				ContentProvider:PreloadAsync({assetId})
			end)
			
			if not success then
				logError("ASSET", "Failed to load test asset: " .. assetId, "Asset Validation")
			end
		end)
	end
	
	return {success = true, message = "Asset validation started"}
end

-- Real-time error monitoring
local function startRealTimeMonitoring()
	spawn(function()
		local interval = DeveloperConfig.SETTINGS.MONITORING_INTERVAL
		
		while true do
			wait(interval)
			
			-- Check ContentProvider queue
			local queueSize = ContentProvider.RequestQueueSize
			if queueSize > 20 then
				local warningData = {
					type = "ASSET_QUEUE_MONITOR",
					message = "Persistent high asset queue: " .. queueSize,
					timestamp = tick(),
					severity = "MEDIUM"
				}
				warningLog[#warningLog + 1] = warningData
			end
			
			-- Clean old warnings and errors
			local currentTime = tick()
			local retentionTime = DeveloperConfig.SETTINGS.ERROR_RETENTION_TIME
			
			-- Clean warnings
			for i = #warningLog, 1, -1 do
				if currentTime - warningLog[i].timestamp > retentionTime then
					table.remove(warningLog, i)
				end
			end
			
			-- Clean old errors if we exceed max log size
			local maxLogSize = DeveloperConfig.SETTINGS.MAX_ERROR_LOG_SIZE
			local errorCount = 0
			for _ in pairs(errorLog) do
				errorCount = errorCount + 1
			end
			
			if errorCount > maxLogSize then
				-- Remove oldest errors
				local sortedErrors = {}
				for _, error in pairs(errorLog) do
					table.insert(sortedErrors, error)
				end
				
				table.sort(sortedErrors, function(a, b)
					return a.timestamp < b.timestamp
				end)
				
				-- Remove oldest half
				local removeCount = math.floor(errorCount / 2)
				for i = 1, removeCount do
					if sortedErrors[i] then
						errorLog[sortedErrors[i].id] = nil
					end
				end
			end
		end
	end)
end

function ConsoleMonitorService:KnitStart()
	print("🖥️ ConsoleMonitorService starting...")
	
	-- Print developer config status
	DeveloperConfig:PrintStatus()
	
	-- Setup error monitoring
	setupScriptErrorMonitoring()
	setupAssetErrorMonitoring()
	
	-- Initial validation checks (if enabled)
	if DeveloperConfig.SETTINGS.VALIDATE_ASSETS_ON_START then
		wait(2) -- Wait for game to load
		checkWorkspaceObjects()
		checkReplicatedStorageStructure()
	end
	
	-- Start real-time monitoring
	startRealTimeMonitoring()
	
	print("✅ ConsoleMonitorService active - Error monitoring enabled")
end

return ConsoleMonitorService
