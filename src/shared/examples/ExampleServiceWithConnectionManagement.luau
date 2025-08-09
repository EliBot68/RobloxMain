--[[
	ExampleServiceWithConnectionManagement.luau
	
	Example service demonstrating proper connection management patterns
	that prevent memory leaks. This serves as a template for updating
	existing services.
--]]

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

-- Safe require
local function safeRequire(module, fallback)
	local success, result = pcall(require, module)
	return success and result or fallback or {}
end

local SafeRequire = safeRequire(ReplicatedStorage.Shared.utils.SafeRequire)
local ConnectionManagerService = SafeRequire and SafeRequire.require(game.ReplicatedStorage.Shared.services.ConnectionManagerService) or safeRequire(game.ReplicatedStorage.Shared.services.ConnectionManagerService)

local ExampleService = {
	Name = "ExampleService",
	_initialized = false,
	_connections = {}, -- Store connection IDs for manual cleanup if needed
	_playerData = {}, -- Store player-specific data
}

-- Initialize the service
function ExampleService:Initialize()
	if self._initialized then return end
	
	-- Ensure ConnectionManagerService is initialized
	if ConnectionManagerService and ConnectionManagerService.Initialize then
		ConnectionManagerService:Initialize()
	end
	
	-- Set up player event connections using ConnectionManagerService
	self:_setupPlayerEvents()
	self:_setupRemoteHandlers()
	self:_setupStateWatchers()
	self:_setupTimers()
	
	self._initialized = true
	print("✅ ExampleService initialized with connection management")
end

-- Set up player-related event connections
function ExampleService:_setupPlayerEvents()
	if not ConnectionManagerService then return end
	
	-- Player joining - this connection will be automatically cleaned up when the service shuts down
	local playerAddedId = ConnectionManagerService:ConnectPlayerEvent(
		Players, -- Note: connecting to Players service, not individual player
		Players.PlayerAdded,
		function(player)
			self:_onPlayerAdded(player)
		end,
		self.Name,
		"Player joined game"
	)
	table.insert(self._connections, playerAddedId)
	
	-- Player leaving - this handles individual player cleanup
	local playerRemovingId = ConnectionManagerService:ConnectPlayerEvent(
		Players,
		Players.PlayerRemoving,
		function(player)
			self:_onPlayerRemoving(player)
		end,
		self.Name,
		"Player leaving game"
	)
	table.insert(self._connections, playerRemovingId)
end

-- Set up remote event handlers
function ExampleService:_setupRemoteHandlers()
	if not ConnectionManagerService then return end
	
	-- Example: Handle a RemoteEvent
	local remoteEvents = ReplicatedStorage:FindFirstChild("RemoteEvents")
	if remoteEvents then
		local exampleRemote = remoteEvents:FindFirstChild("ExampleRemote")
		if exampleRemote then
			local remoteId = ConnectionManagerService:ConnectRemoteHandler(
				exampleRemote,
				"OnServerEvent",
				function(player, data)
					self:_handleRemoteEvent(player, data)
				end,
				self.Name,
				"Example remote event handler"
			)
			table.insert(self._connections, remoteId)
		end
	end
end

-- Set up state watchers
function ExampleService:_setupStateWatchers()
	if not ConnectionManagerService then return end
	
	-- Example: Watch for game state changes
	-- This would typically connect to a signal from another service
	local heartbeatId = ConnectionManagerService:ConnectRunServiceEvent(
		"Heartbeat",
		function()
			self:_updateGameState()
		end,
		self.Name,
		nil, -- No specific player
		"Game state update loop"
	)
	table.insert(self._connections, heartbeatId)
end

-- Set up timers
function ExampleService:_setupTimers()
	if not ConnectionManagerService then return end
	
	-- Example: Create a timer that runs every 5 seconds
	local timerId = ConnectionManagerService:CreateTimer(
		5.0, -- 5 second interval
		function(callCount, totalTime)
			self:_onTimerTick(callCount, totalTime)
		end,
		self.Name,
		nil, -- No specific player
		"5-second status timer",
		nil -- No max calls limit
	)
	table.insert(self._connections, timerId)
end

-- Handle player joining
function ExampleService:_onPlayerAdded(player)
	print("📥 Player joined:", player.Name)
	
	-- Initialize player data
	self._playerData[player] = {
		joinTime = tick(),
		score = 0,
		connections = {} -- Store player-specific connection IDs
	}
	
	-- Set up player-specific connections that will be automatically cleaned up when player leaves
	self:_setupPlayerSpecificConnections(player)
end

-- Set up connections specific to a player
function ExampleService:_setupPlayerSpecificConnections(player)
	if not ConnectionManagerService then return end
	
	local playerData = self._playerData[player]
	if not playerData then return end
	
	-- Example: Watch for character spawning
	local charAddedId = ConnectionManagerService:ConnectPlayerEvent(
		player,
		player.CharacterAdded,
		function(character)
			self:_onCharacterAdded(player, character)
		end,
		self.Name,
		string.format("Character spawned for %s", player.Name)
	)
	table.insert(playerData.connections, charAddedId)
	
	-- Example: Watch for character removing
	local charRemovingId = ConnectionManagerService:ConnectPlayerEvent(
		player,
		player.CharacterRemoving,
		function(character)
			self:_onCharacterRemoving(player, character)
		end,
		self.Name,
		string.format("Character removing for %s", player.Name)
	)
	table.insert(playerData.connections, charRemovingId)
	
	-- Example: Set up player-specific timer
	local playerTimerId = ConnectionManagerService:CreateTimer(
		1.0, -- 1 second interval
		function(callCount, totalTime)
			self:_updatePlayerStats(player, callCount, totalTime)
		end,
		self.Name,
		player,
		string.format("Stats timer for %s", player.Name)
	)
	table.insert(playerData.connections, playerTimerId)
end

-- Handle character spawning
function ExampleService:_onCharacterAdded(player, character)
	print("🚶 Character spawned for:", player.Name)
	
	if not ConnectionManagerService then return end
	
	local playerData = self._playerData[player]
	if not playerData then return end
	
	-- Example: Set up physics connections for the character
	local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
	if humanoidRootPart then
		-- Watch for part touches
		local touchedId = ConnectionManagerService:ConnectPhysicsEvent(
			humanoidRootPart,
			"Touched",
			function(hit)
				self:_onPartTouched(player, hit)
			end,
			self.Name,
			player,
			string.format("Touch detection for %s", player.Name)
		)
		table.insert(playerData.connections, touchedId)
	end
	
	-- Example: Set up GUI connections (client-side)
	if RunService:IsClient() then
		local playerGui = player:FindFirstChild("PlayerGui")
		if playerGui then
			local screenGui = playerGui:FindFirstChild("ScreenGui")
			if screenGui then
				local button = screenGui:FindFirstChild("ExampleButton")
				if button then
					local buttonId = ConnectionManagerService:ConnectGUIEvent(
						button,
						"Activated",
						function()
							self:_onButtonClicked(player)
						end,
						self.Name,
						player,
						string.format("Button click for %s", player.Name)
					)
					table.insert(playerData.connections, buttonId)
				end
			end
		end
	end
end

-- Handle character removing
function ExampleService:_onCharacterRemoving(player, character)
	print("🚫 Character removing for:", player.Name)
	-- Character-specific connections will be automatically cleaned up
	-- when the player leaves, but you can do manual cleanup here if needed
end

-- Handle player leaving
function ExampleService:_onPlayerRemoving(player)
	print("📤 Player leaving:", player.Name)
	
	-- Manual cleanup of player data
	-- Note: ConnectionManagerService will automatically clean up all
	-- player-specific connections, so we don't need to do that manually
	self._playerData[player] = nil
	
	print("✅ Player cleanup completed for:", player.Name)
end

-- Example event handlers
function ExampleService:_handleRemoteEvent(player, data)
	print("📡 Remote event from", player.Name, ":", data)
end

function ExampleService:_updateGameState()
	-- This runs every heartbeat - be careful not to do heavy work here
	-- Example: Check if any cleanup is needed
end

function ExampleService:_onTimerTick(callCount, totalTime)
	print(string.format("⏰ Timer tick #%d after %.1f seconds", callCount, totalTime))
end

function ExampleService:_updatePlayerStats(player, callCount, totalTime)
	local playerData = self._playerData[player]
	if playerData then
		-- Update player-specific stats
		-- This runs every second for each player
	end
end

function ExampleService:_onPartTouched(player, hit)
	-- Handle part touches
	print("👆 Part touched by", player.Name, ":", hit.Name)
end

function ExampleService:_onButtonClicked(player)
	print("🔘 Button clicked by", player.Name)
end

-- Manual cleanup method (called when service shuts down)
function ExampleService:Cleanup()
	print("🧹 Cleaning up ExampleService...")
	
	-- The ConnectionManagerService will automatically clean up all our connections
	-- when we call CleanupServiceConnections, but we can also manually disconnect
	-- specific connections if needed
	
	if ConnectionManagerService then
		local cleanedCount = ConnectionManagerService:CleanupServiceConnections(self.Name)
		print(string.format("✅ Cleaned up %d connections for %s", cleanedCount, self.Name))
	end
	
	-- Clear our local data
	self._connections = {}
	self._playerData = {}
	self._initialized = false
	
	print("✅ ExampleService cleanup completed")
end

-- Get service statistics
function ExampleService:GetStats()
	local stats = {
		initialized = self._initialized,
		trackedConnections = #self._connections,
		playerCount = 0,
		playerConnections = 0
	}
	
	for player, data in pairs(self._playerData) do
		stats.playerCount = stats.playerCount + 1
		if data.connections then
			stats.playerConnections = stats.playerConnections + #data.connections
		end
	end
	
	-- Get detailed stats from ConnectionManagerService
	if ConnectionManagerService then
		local detailedStats = ConnectionManagerService:GetStatistics()
		stats.connectionManagerStats = detailedStats
	end
	
	return stats
end

-- Example method showing how to create a one-off connection with custom cleanup
function ExampleService:CreateTemporaryConnection(player, duration)
	if not ConnectionManagerService then return end
	
	print(string.format("⏱️ Creating temporary connection for %s (%.1fs)", player.Name, duration))
	
	-- Create a connection that automatically disconnects after a certain time
	local connectionId = ConnectionManagerService:CreateTimer(
		0.1, -- Check every 0.1 seconds
		function(callCount, totalTime)
			-- Do something periodically
			print(string.format("🔄 Temporary task for %s: call #%d", player.Name, callCount))
		end,
		self.Name,
		player,
		string.format("Temporary connection for %s", player.Name),
		math.floor(duration / 0.1) -- Max calls = duration / interval
	)
	
	return connectionId
end

return ExampleService
