--[[
	DeveloperConfig
	Configuration file for developer access and settings
	
	CONFIGURED DEVELOPER USERIDS: [5479389335]
	
	Usage Examples:
	
	-- Check if a player is a developer:
	local DeveloperConfig = require(ReplicatedStorage.Shared.modules.DeveloperConfig)
	if DeveloperConfig:IsDeveloper(player) then
		-- Show developer UI or enable dev commands
	end
	
	-- Check by UserID only:
	if DeveloperConfig:IsDeveloperById(userId) then
		-- Grant developer privileges
	end
--]]

local DeveloperConfig = {}

-- Add your Roblox UserIDs here to grant developer access
-- You can find your UserID by going to your Roblox profile URL
-- Example: https://www.roblox.com/users/123456789/profile -> UserID is 123456789
DeveloperConfig.DEVELOPER_IDS = {
	5479389335, -- Primary developer
	-- Add more developers as needed:
	-- 987654321,
}

-- Developer tool settings
DeveloperConfig.SETTINGS = {
	-- GUI toggle key (default: F9)
	TOGGLE_KEY = Enum.KeyCode.F9,
	
	-- Show welcome message when developer joins
	SHOW_WELCOME_MESSAGE = true,
	
	-- Enable real-time error notifications
	ENABLE_ERROR_NOTIFICATIONS = true,
	
	-- Maximum errors to keep in memory
	MAX_ERROR_LOG_SIZE = 1000,
	
	-- How long to keep errors (in seconds)
	ERROR_RETENTION_TIME = 3600, -- 1 hour
	
	-- Asset validation on startup
	VALIDATE_ASSETS_ON_START = true,
	
	-- Console monitoring interval (seconds)
	MONITORING_INTERVAL = 30,
}

-- Track positions for teleportation
DeveloperConfig.TRACK_POSITIONS = {
	Hub = {
		position = Vector3.new(0, 10, 0),
		orientation = CFrame.Angles(0, 0, 0),
		description = "Main Hub Area"
	},
	Track1 = {
		position = Vector3.new(100, 10, 0),
		orientation = CFrame.Angles(0, math.rad(90), 0),
		description = "Beginner Track"
	},
	Track2 = {
		position = Vector3.new(200, 10, 0),
		orientation = CFrame.Angles(0, math.rad(180), 0),
		description = "Intermediate Track"
	},
	Track3 = {
		position = Vector3.new(300, 10, 0),
		orientation = CFrame.Angles(0, math.rad(270), 0),
		description = "Advanced Track"
	},
	Tutorial = {
		position = Vector3.new(-50, 10, 0),
		orientation = CFrame.Angles(0, 0, 0),
		description = "Tutorial Area"
	}
}

-- Test currency amounts for quick granting
DeveloperConfig.TEST_AMOUNTS = {
	COINS = {100, 1000, 10000},
	XP = {50, 500, 5000}
}

-- Required game objects for validation
DeveloperConfig.REQUIRED_OBJECTS = {
	WORKSPACE = {
		"GameTracks",
		"MarketPlaza",
		"SpawnLocation"
	},
	GAME_TRACKS = {
		"Track1",
		"Track2", 
		"Track3"
	},
	REPLICATED_STORAGE = {
		"Shared",
		"Packages"
	},
	SHARED_FOLDERS = {
		"modules",
		"constants",
		"types"
	}
}

-- Check if player is a developer
function DeveloperConfig:IsDeveloper(player)
	local userId = player.UserId
	
	-- Check UserID list
	for _, devId in pairs(self.DEVELOPER_IDS) do
		if userId == devId then
			return true
		end
	end
	
	-- Check if player owns the game (for Studio testing)
	if game.CreatorType == Enum.CreatorType.User and game.CreatorId == userId then
		return true
	end
	
	-- Check if in Studio (for testing)
	if game:GetService("RunService"):IsStudio() then
		-- In Studio, you can optionally allow all players for testing
		-- return true -- Uncomment this line to allow all players in Studio
	end
	
	return false
end

-- Utility function to check developer status by UserID only
function DeveloperConfig:IsDeveloperById(userId)
	-- Check UserID list
	for _, devId in pairs(self.DEVELOPER_IDS) do
		if userId == devId then
			return true
		end
	end
	
	-- Check if player owns the game
	if game.CreatorType == Enum.CreatorType.User and game.CreatorId == userId then
		return true
	end
	
	return false
end
end

-- Get developer name for logging
function DeveloperConfig:GetDeveloperName(player)
	if self:IsDeveloper(player) then
		if game.CreatorType == Enum.CreatorType.User and game.CreatorId == player.UserId then
			return player.Name .. " (Game Owner)"
		else
			return player.Name .. " (Developer)"
		end
	end
	return nil
end

-- Validate configuration
function DeveloperConfig:ValidateConfig()
	local issues = {}
	
	-- Check if any real developer IDs are set
	if #self.DEVELOPER_IDS == 1 and self.DEVELOPER_IDS[1] == 1 then
		table.insert(issues, "⚠️ No real developer UserIDs configured - update DEVELOPER_IDS in DeveloperConfig")
	end
	
	-- Validate track positions
	for trackName, config in pairs(self.TRACK_POSITIONS) do
		if not config.position or typeof(config.position) ~= "Vector3" then
			table.insert(issues, "❌ Invalid position for track: " .. trackName)
		end
	end
	
	-- Return validation results
	return #issues == 0, issues
end

-- Print configuration status
function DeveloperConfig:PrintStatus()
	print("🛠️ Developer Tools Configuration:")
	print("=====================================")
	print("Configured Developers: " .. #self.DEVELOPER_IDS)
	print("Available Tracks: " .. #self.TRACK_POSITIONS)
	print("Toggle Key: " .. self.SETTINGS.TOGGLE_KEY.Name)
	print("Error Monitoring: " .. (self.SETTINGS.ENABLE_ERROR_NOTIFICATIONS and "Enabled" or "Disabled"))
	
	local isValid, issues = self:ValidateConfig()
	if isValid then
		print("✅ Configuration valid")
	else
		print("❌ Configuration issues found:")
		for _, issue in pairs(issues) do
			print("  " .. issue)
		end
	end
	print("=====================================")
end

return DeveloperConfig
