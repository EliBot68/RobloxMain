--[[
	DeveloperConfig
	Configuration file for developer access and settings
	
	CONFIGURED DEVELOPER USERIDS: [268259684, 156886091, 89273541, 194758321]
	
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
	
	-- Get developer info for logging:
	local devName = DeveloperConfig:GetDeveloperName(player)
	if devName then
		print("Developer access granted to: " .. devName)
	end
--]]

local DeveloperConfig = {}

-- Production Developer Team UserIDs
-- WARNING: Keep this list updated and secure - these users have full access to developer tools
DeveloperConfig.DEVELOPER_IDS = {
	268259684, -- EliBot68 (Project Lead)
	156886091, -- Lead Developer 
	89273541,  -- Senior Developer
	194758321, -- QA Lead & Developer
	-- Add new team members here:
	-- Format: UserID, -- Name/Role (Comment)
}

-- Enhanced Developer Tool Settings
DeveloperConfig.SETTINGS = {
	-- GUI toggle key (F9 for console, F8 for developer panel)
	TOGGLE_KEY = Enum.KeyCode.F9,
	DEVELOPER_PANEL_KEY = Enum.KeyCode.F8,
	
	-- Production settings - can be overridden per environment
	SHOW_WELCOME_MESSAGE = true,
	ENABLE_ERROR_NOTIFICATIONS = true,
	ENABLE_PERFORMANCE_MONITORING = true,
	ENABLE_CHAT_COMMANDS = true,
	
	-- Memory and logging configuration
	MAX_ERROR_LOG_SIZE = 500,         -- Reduced for production
	ERROR_RETENTION_TIME = 1800,      -- 30 minutes (reduced from 1 hour)
	MONITORING_INTERVAL = 60,         -- Check every minute
	
	-- Security settings
	VALIDATE_ASSETS_ON_START = true,
	REQUIRE_SECURE_ACCESS = true,     -- Extra validation for sensitive operations
	LOG_DEVELOPER_ACTIONS = true,     -- Track all developer actions for audit
	
	-- Performance thresholds
	MEMORY_WARNING_THRESHOLD = 80,    -- Warn at 80% memory usage
	FPS_WARNING_THRESHOLD = 30,       -- Warn below 30 FPS
	NETWORK_LATENCY_THRESHOLD = 200,  -- Warn above 200ms latency
}

-- Enhanced Track and Testing Positions
DeveloperConfig.TRACK_POSITIONS = {
	Hub = {
		position = Vector3.new(0, 10, 0),
		orientation = CFrame.Angles(0, 0, 0),
		description = "Main Hub Area - Player Spawn"
	},
	BeginnerTrack = {
		position = Vector3.new(150, 15, 0),
		orientation = CFrame.Angles(0, math.rad(90), 0),
		description = "Beginner Track Start (Difficulty 1)"
	},
	IntermediateTrack = {
		position = Vector3.new(300, 20, 0),
		orientation = CFrame.Angles(0, math.rad(180), 0),
		description = "Intermediate Track Start (Difficulty 2-3)"
	},
	AdvancedTrack = {
		position = Vector3.new(450, 25, 0),
		orientation = CFrame.Angles(0, math.rad(270), 0),
		description = "Advanced Track Start (Difficulty 4-5)"
	},
	ExpertTrack = {
		position = Vector3.new(600, 30, 0),
		orientation = CFrame.Angles(0, 0, 0),
		description = "Expert Track Start (Difficulty 6+)"
	},
	Tutorial = {
		position = Vector3.new(-75, 10, 0),
		orientation = CFrame.Angles(0, 0, 0),
		description = "Tutorial Area - New Player Training"
	},
	TestingArena = {
		position = Vector3.new(0, 50, 0),
		orientation = CFrame.Angles(0, 0, 0),
		description = "Developer Testing Arena - Isolated Test Environment"
	}
}

-- Production Test Currency Amounts
DeveloperConfig.TEST_AMOUNTS = {
	COINS = {
		SMALL = 250,      -- Small test amount
		MEDIUM = 2500,    -- Medium test amount  
		LARGE = 25000,    -- Large test amount
		MASSIVE = 100000  -- Full test amount
	},
	XP = {
		SMALL = 100,      -- Small XP boost
		MEDIUM = 1000,    -- Medium XP boost
		LARGE = 10000,    -- Large XP boost
		LEVEL_UP = 50000  -- Instant level up amount
	},
	GEMS = {
		SMALL = 10,       -- Small premium currency
		MEDIUM = 100,     -- Medium premium currency
		LARGE = 1000,     -- Large premium currency
		WHALE = 10000     -- Maximum premium currency
	}
}

-- Critical Game Objects Validation (Production Ready)
DeveloperConfig.REQUIRED_OBJECTS = {
	WORKSPACE = {
		"GameTracks",           -- Main track storage folder
		"MarketPlaza",          -- Shop and monetization area
		"SpawnLocation",        -- Default player spawn
		"Lighting",             -- Lighting configuration
		"SoundService"          -- Audio management
	},
	GAME_TRACKS = {
		"BeginnerTrack",        -- Difficulty 1 track
		"IntermediateTrack",    -- Difficulty 2-3 tracks
		"AdvancedTrack",        -- Difficulty 4-5 tracks
		"ExpertTrack",          -- Difficulty 6+ tracks
		"TutorialTrack"         -- New player tutorial track
	},
	REPLICATED_STORAGE = {
		"Shared",               -- Shared modules and utilities
		"Packages",             -- External packages and dependencies
		"RemoteEvents",         -- Client-server communication
		"RemoteFunctions"       -- Client-server function calls
	},
	SHARED_FOLDERS = {
		"modules",              -- Shared module scripts
		"constants",            -- Game constants and configuration
		"types",                -- Type definitions
		"utils"                 -- Utility functions
	},
	SERVER_STORAGE = {
		"ServerStorage",        -- Server-only data
		"PlayerData",           -- Player save data templates
		"Analytics"             -- Analytics and tracking data
	}
}

-- Developer Permission Levels
DeveloperConfig.PERMISSION_LEVELS = {
	FULL_ACCESS = {
		description = "Full developer access - all tools and commands",
		users = {268259684}, -- Project lead only
		permissions = {"teleport", "currency", "analytics", "server_control", "player_management"}
	},
	DEVELOPER = {
		description = "Standard developer access - most tools except server control",
		users = {156886091, 89273541},
		permissions = {"teleport", "currency", "analytics", "player_management"}
	},
	QA_TESTER = {
		description = "QA testing access - limited tools for testing",
		users = {194758321},
		permissions = {"teleport", "analytics"}
	}
}

-- Enhanced Developer Status Check with Security
function DeveloperConfig:IsDeveloper(player)
	if not player or not player.UserId then
		return false
	end
	
	local userId = player.UserId
	
	-- Check UserID list with enhanced security
	for _, devId in pairs(self.DEVELOPER_IDS) do
		if userId == devId then
			-- Log developer access for security audit
			if self.SETTINGS.LOG_DEVELOPER_ACTIONS then
				print("🛠️ Developer access granted: " .. player.Name .. " (ID: " .. userId .. ")")
			end
			return true
		end
	end
	
	-- Check if player owns the game (game creator)
	if game.CreatorType == Enum.CreatorType.User and game.CreatorId == userId then
		if self.SETTINGS.LOG_DEVELOPER_ACTIONS then
			print("👑 Game owner access granted: " .. player.Name .. " (ID: " .. userId .. ")")
		end
		return true
	elseif game.CreatorType == Enum.CreatorType.Group then
		-- Check if player has sufficient group rank for development
		local groupId = game.CreatorId
		local success, rank = pcall(function()
			return player:GetRankInGroup(groupId)
		end)
		if success and rank >= 100 then -- Assume rank 100+ for developers
			if self.SETTINGS.LOG_DEVELOPER_ACTIONS then
				print("🏢 Group developer access granted: " .. player.Name .. " (Rank: " .. rank .. ")")
			end
			return true
		end
	end
	
	-- Studio testing mode (only if explicitly enabled)
	if game:GetService("RunService"):IsStudio() then
		-- In production, comment out the next line for security
		-- return true -- WARNING: This allows all players in Studio!
	end
	
	return false
end

-- Enhanced Developer ID Check with Caching
function DeveloperConfig:IsDeveloperById(userId)
	if not userId or userId <= 0 then
		return false
	end
	
	-- Cache for performance (avoid repeated checks)
	if not self._idCache then
		self._idCache = {}
		for _, devId in pairs(self.DEVELOPER_IDS) do
			self._idCache[devId] = true
		end
	end
	
	-- Quick cache lookup
	if self._idCache[userId] then
		return true
	end
	
	-- Check game creator
	if game.CreatorType == Enum.CreatorType.User and game.CreatorId == userId then
		return true
	end
	
	return false
end

-- Get Developer Permission Level
function DeveloperConfig:GetDeveloperPermissions(player)
	if not self:IsDeveloper(player) then
		return nil
	end
	
	local userId = player.UserId
	
	-- Check permission levels
	for levelName, config in pairs(self.PERMISSION_LEVELS) do
		for _, allowedId in pairs(config.users) do
			if userId == allowedId then
				return {
					level = levelName,
					description = config.description,
					permissions = config.permissions
				}
			end
		end
	end
	
	-- Default to basic developer permissions if not specified
	return {
		level = "BASIC_DEVELOPER",
		description = "Basic developer access",
		permissions = {"teleport"}
	}
end

-- Check if developer has specific permission
function DeveloperConfig:HasPermission(player, permission)
	local perms = self:GetDeveloperPermissions(player)
	if not perms then
		return false
	end
	
	for _, perm in pairs(perms.permissions) do
		if perm == permission then
			return true
		end
	end
	
	return false
end
-- Enhanced Developer Info with Permission Display
function DeveloperConfig:GetDeveloperName(player)
	if not self:IsDeveloper(player) then
		return nil
	end
	
	local perms = self:GetDeveloperPermissions(player)
	local permLevel = perms and perms.level or "UNKNOWN"
	
	if game.CreatorType == Enum.CreatorType.User and game.CreatorId == player.UserId then
		return player.Name .. " (Game Owner - " .. permLevel .. ")"
	elseif game.CreatorType == Enum.CreatorType.Group then
		local success, rank = pcall(function()
			return player:GetRankInGroup(game.CreatorId)
		end)
		if success and rank >= 100 then
			return player.Name .. " (Group Dev - Rank " .. rank .. ")"
		end
	end
	
	return player.Name .. " (" .. permLevel .. ")"
end

-- Production-Ready Configuration Validation
function DeveloperConfig:ValidateConfig()
	local issues = {}
	local warnings = {}
	
	-- Critical validation checks
	if #self.DEVELOPER_IDS == 0 then
		table.insert(issues, "❌ CRITICAL: No developer UserIDs configured - no one will have developer access!")
	end
	
	-- Check for placeholder IDs
	local hasPlaceholders = false
	for _, id in pairs(self.DEVELOPER_IDS) do
		if id == 1 or id == 123456789 or id == 5479389335 then
			hasPlaceholders = true
			break
		end
	end
	
	if hasPlaceholders then
		table.insert(warnings, "⚠️ WARNING: Placeholder UserIDs detected - update with real developer IDs")
	end
	
	-- Validate track positions
	for trackName, config in pairs(self.TRACK_POSITIONS) do
		if not config.position or typeof(config.position) ~= "Vector3" then
			table.insert(issues, "❌ Invalid position for track: " .. trackName)
		end
		if not config.description or config.description == "" then
			table.insert(warnings, "⚠️ Missing description for track: " .. trackName)
		end
	end
	
	-- Validate permission levels
	for levelName, config in pairs(self.PERMISSION_LEVELS) do
		if not config.users or #config.users == 0 then
			table.insert(warnings, "⚠️ No users assigned to permission level: " .. levelName)
		end
		if not config.permissions or #config.permissions == 0 then
			table.insert(issues, "❌ No permissions defined for level: " .. levelName)
		end
	end
	
	-- Validate settings
	if self.SETTINGS.MONITORING_INTERVAL < 10 then
		table.insert(warnings, "⚠️ Monitoring interval very low - may impact performance")
	end
	
	if self.SETTINGS.MAX_ERROR_LOG_SIZE > 1000 then
		table.insert(warnings, "⚠️ Error log size very high - may impact memory usage")
	end
	
	-- Return validation results
	local hasIssues = #issues > 0
	return not hasIssues, issues, warnings
end

-- Enhanced Status Display for Production
function DeveloperConfig:PrintStatus()
	print("\n🛠️ Color Rush Developer Tools Configuration")
	print("=" .. string.rep("=", 50))
	print("📊 System Status:")
	print("  • Configured Developers: " .. #self.DEVELOPER_IDS)
	print("  • Permission Levels: " .. self:CountTableEntries(self.PERMISSION_LEVELS))
	print("  • Available Tracks: " .. self:CountTableEntries(self.TRACK_POSITIONS))
	print("  • Required Objects: " .. self:CountTableEntries(self.REQUIRED_OBJECTS))
	
	print("\n⚙️ Settings:")
	print("  • Toggle Key: " .. self.SETTINGS.TOGGLE_KEY.Name)
	print("  • Developer Panel Key: " .. self.SETTINGS.DEVELOPER_PANEL_KEY.Name)
	print("  • Error Monitoring: " .. (self.SETTINGS.ENABLE_ERROR_NOTIFICATIONS and "✅ Enabled" or "❌ Disabled"))
	print("  • Performance Monitoring: " .. (self.SETTINGS.ENABLE_PERFORMANCE_MONITORING and "✅ Enabled" or "❌ Disabled"))
	print("  • Chat Commands: " .. (self.SETTINGS.ENABLE_CHAT_COMMANDS and "✅ Enabled" or "❌ Disabled"))
	print("  • Action Logging: " .. (self.SETTINGS.LOG_DEVELOPER_ACTIONS and "✅ Enabled" or "❌ Disabled"))
	
	print("\n🔒 Security:")
	print("  • Asset Validation: " .. (self.SETTINGS.VALIDATE_ASSETS_ON_START and "✅ Enabled" or "❌ Disabled"))
	print("  • Secure Access: " .. (self.SETTINGS.REQUIRE_SECURE_ACCESS and "✅ Enabled" or "❌ Disabled"))
	
	-- Validation results
	local isValid, issues, warnings = self:ValidateConfig()
	
	if isValid and #warnings == 0 then
		print("\n✅ Configuration Status: HEALTHY")
	elseif isValid then
		print("\n⚠️ Configuration Status: WARNINGS DETECTED")
		for _, warning in pairs(warnings) do
			print("  " .. warning)
		end
	else
		print("\n❌ Configuration Status: ISSUES DETECTED")
		for _, issue in pairs(issues) do
			print("  " .. issue)
		end
		if #warnings > 0 then
			print("\n⚠️ Additional Warnings:")
			for _, warning in pairs(warnings) do
				print("  " .. warning)
			end
		end
	end
	
	print("=" .. string.rep("=", 50) .. "\n")
end

-- Utility function to count table entries
function DeveloperConfig:CountTableEntries(tbl)
	local count = 0
	for _ in pairs(tbl) do
		count = count + 1
	end
	return count
end

-- Initialize developer cache and perform startup validation
function DeveloperConfig:Initialize()
	-- Clear any existing cache
	self._idCache = nil
	
	-- Perform startup validation
	if self.SETTINGS.VALIDATE_ASSETS_ON_START then
		local isValid, issues, warnings = self:ValidateConfig()
		
		if not isValid then
			warn("🚨 DeveloperConfig validation failed! Check configuration before production use.")
			for _, issue in pairs(issues) do
				warn(issue)
			end
		end
		
		if #warnings > 0 then
			for _, warning in pairs(warnings) do
				warn(warning)
			end
		end
	end
	
	print("🛠️ DeveloperConfig initialized successfully")
	return true
end

-- Auto-initialize when module is required
spawn(function()
	wait(1) -- Brief delay to ensure other systems are ready
	DeveloperConfig:Initialize()
end)

return DeveloperConfig
