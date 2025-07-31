--[[
	ConnectionManager.luau
	
	Comprehensive connection management system for preventing memory leaks
	from unmanaged RBXScriptConnections across all services.
	
	Features:
	- Automatic connection tracking and cleanup
	- Player-specific connection pools
	- Service-specific connection management
	- Safe disconnection with error handling
	- Memory leak prevention and monitoring
	- Bulk cleanup operations
	- Connection lifecycle management
	- Debug logging and analytics
--]]

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local HttpService = game:GetService("HttpService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Safe require with fallback
local function safeRequire(module, fallback)
	local success, result = pcall(require, module)
	return success and result or fallback or {}
end

local SafeRequire = safeRequire(ReplicatedStorage.Shared.utils.SafeRequire)
local StructuredLogger = SafeRequire and SafeRequire.require(ReplicatedStorage.Shared.services.StructuredLogger) or {}

local ConnectionManager = {
	-- Connection storage
	_playerConnections = {}, -- [player] = { [connectionId] = connection }
	_serviceConnections = {}, -- [serviceName] = { [connectionId] = connection }
	_globalConnections = {}, -- [connectionId] = connection
	_taggedConnections = {}, -- [tag] = { [connectionId] = connection }
	
	-- Metadata storage
	_connectionMetadata = {}, -- [connectionId] = { created, service, player, tag, description }
	_connectionCounts = {}, -- Service and player connection counts
	_cleanupCallbacks = {}, -- [connectionId] = cleanup function
	
	-- Configuration
	Config = {
		MAX_CONNECTIONS_PER_PLAYER = 500,
		MAX_CONNECTIONS_PER_SERVICE = 1000,
		CLEANUP_INTERVAL = 30, -- seconds
		ENABLE_DEBUG_LOGGING = true,
		ENABLE_MEMORY_MONITORING = true,
		AUTO_CLEANUP_THRESHOLD = 0.8, -- Cleanup when 80% of max reached
		CONNECTION_TIMEOUT = 300, -- 5 minutes
	},
	
	-- Statistics
	Stats = {
		totalConnections = 0,
		connectionsCreated = 0,
		connectionsDestroyed = 0,
		memoryLeaksPreventend = 0,
		lastCleanupTime = 0,
		cleanupErrors = 0,
	},
	
	-- Connection types for tracking
	ConnectionTypes = {
		PLAYER_EVENT = "player_event",
		REMOTE_HANDLER = "remote_handler", 
		STATE_WATCHER = "state_watcher",
		HEARTBEAT = "heartbeat",
		STEPPED = "stepped",
		RENDERSTEPPED = "renderstepped",
		SIGNAL = "signal",
		TIMER = "timer",
		TWEEN = "tween",
		SOUND = "sound",
		GUI = "gui",
		PHYSICS = "physics",
		OTHER = "other"
	}
}

-- Generate unique connection ID
function ConnectionManager:_generateConnectionId()
	return HttpService:GenerateGUID(false):gsub("-", ""):sub(1, 16)
end

-- Log connection activity
function ConnectionManager:_log(level, message, data)
	if not self.Config.ENABLE_DEBUG_LOGGING then return end
	
	if StructuredLogger and StructuredLogger.Log then
		StructuredLogger:Log(level, "ConnectionManager", message, data or {})
	else
		print(string.format("[ConnectionManager][%s] %s", level:upper(), message))
		if data then
			print("Data:", HttpService:JSONEncode(data))
		end
	end
end

-- Update connection statistics
function ConnectionManager:_updateStats(action, connectionType, service)
	if action == "created" then
		self.Stats.connectionsCreated = self.Stats.connectionsCreated + 1
		self.Stats.totalConnections = self.Stats.totalConnections + 1
	elseif action == "destroyed" then
		self.Stats.connectionsDestroyed = self.Stats.connectionsDestroyed + 1
		self.Stats.totalConnections = math.max(0, self.Stats.totalConnections - 1)
	end
	
	-- Update service counts
	if service then
		self._connectionCounts[service] = self._connectionCounts[service] or 0
		if action == "created" then
			self._connectionCounts[service] = self._connectionCounts[service] + 1
		elseif action == "destroyed" then
			self._connectionCounts[service] = math.max(0, self._connectionCounts[service] - 1)
		end
	end
end

-- Check if connection is valid
function ConnectionManager:_isValidConnection(connection)
	if not connection then return false end
	
	local success, connected = pcall(function()
		return connection.Connected
	end)
	
	return success and connected == true
end

-- Safe disconnect with error handling
function ConnectionManager:_safeDisconnect(connection, connectionId, metadata)
	local success, error = pcall(function()
		if self:_isValidConnection(connection) then
			connection:Disconnect()
			return true
		end
		return false
	end)
	
	if not success then
		self.Stats.cleanupErrors = self.Stats.cleanupErrors + 1
		self:_log("error", "Failed to disconnect connection", {
			connectionId = connectionId,
			error = tostring(error),
			service = metadata and metadata.service,
			player = metadata and metadata.player and metadata.player.Name
		})
		return false
	end
	
	return true
end

--[[
	Track a new connection with comprehensive metadata
	
	@param connection: The RBXScriptConnection to track
	@param options: Table with tracking options
		- service: Service name (string)
		- player: Player instance
		- tag: Custom tag for grouping (string)
		- description: Human-readable description (string)
		- connectionType: Type from ConnectionTypes enum
		- cleanupCallback: Function to call during cleanup
		- timeout: Custom timeout in seconds
	
	@returns: connectionId for later reference
--]]
function ConnectionManager:TrackConnection(connection, options)
	if not connection then
		self:_log("error", "Attempted to track nil connection")
		return nil
	end
	
	options = options or {}
	local connectionId = self:_generateConnectionId()
	local timestamp = tick()
	
	-- Store connection metadata
	local metadata = {
		connectionId = connectionId,
		connection = connection,
		created = timestamp,
		service = options.service,
		player = options.player,
		tag = options.tag,
		description = options.description or "Unknown connection",
		connectionType = options.connectionType or self.ConnectionTypes.OTHER,
		timeout = options.timeout or self.Config.CONNECTION_TIMEOUT,
		lastAccessed = timestamp
	}
	
	self._connectionMetadata[connectionId] = metadata
	
	-- Store cleanup callback if provided
	if options.cleanupCallback and type(options.cleanupCallback) == "function" then
		self._cleanupCallbacks[connectionId] = options.cleanupCallback
	end
	
	-- Store in appropriate pools
	if options.player then
		self._playerConnections[options.player] = self._playerConnections[options.player] or {}
		self._playerConnections[options.player][connectionId] = connection
		
		-- Check player connection limits
		local playerConnectionCount = 0
		for _ in pairs(self._playerConnections[options.player]) do
			playerConnectionCount = playerConnectionCount + 1
		end
		
		if playerConnectionCount > self.Config.MAX_CONNECTIONS_PER_PLAYER then
			self:_log("warn", "Player connection limit exceeded", {
				player = options.player.Name,
				count = playerConnectionCount,
				limit = self.Config.MAX_CONNECTIONS_PER_PLAYER
			})
		end
	end
	
	if options.service then
		self._serviceConnections[options.service] = self._serviceConnections[options.service] or {}
		self._serviceConnections[options.service][connectionId] = connection
		
		-- Check service connection limits
		local serviceConnectionCount = 0
		for _ in pairs(self._serviceConnections[options.service]) do
			serviceConnectionCount = serviceConnectionCount + 1
		end
		
		if serviceConnectionCount > self.Config.MAX_CONNECTIONS_PER_SERVICE then
			self:_log("warn", "Service connection limit exceeded", {
				service = options.service,
				count = serviceConnectionCount,
				limit = self.Config.MAX_CONNECTIONS_PER_SERVICE
			})
		end
	end
	
	if options.tag then
		self._taggedConnections[options.tag] = self._taggedConnections[options.tag] or {}
		self._taggedConnections[options.tag][connectionId] = connection
	end
	
	-- Always store in global pool
	self._globalConnections[connectionId] = connection
	
	-- Update statistics
	self:_updateStats("created", metadata.connectionType, options.service)
	
	self:_log("debug", "Connection tracked", {
		connectionId = connectionId,
		service = options.service,
		player = options.player and options.player.Name,
		tag = options.tag,
		type = metadata.connectionType,
		description = metadata.description
	})
	
	return connectionId
end

--[[
	Disconnect and clean up a specific connection
	
	@param connectionId: The ID returned from TrackConnection
	@returns: success (boolean)
--]]
function ConnectionManager:DisconnectConnection(connectionId)
	if not connectionId then return false end
	
	local metadata = self._connectionMetadata[connectionId]
	if not metadata then
		self:_log("warn", "Attempted to disconnect unknown connection", { connectionId = connectionId })
		return false
	end
	
	local connection = self._globalConnections[connectionId]
	local success = self:_safeDisconnect(connection, connectionId, metadata)
	
	if success then
		-- Execute cleanup callback if exists
		local cleanupCallback = self._cleanupCallbacks[connectionId]
		if cleanupCallback then
			local callbackSuccess, callbackError = pcall(cleanupCallback)
			if not callbackSuccess then
				self:_log("error", "Cleanup callback failed", {
					connectionId = connectionId,
					error = tostring(callbackError)
				})
			end
		end
		
		-- Remove from all pools
		self:_removeFromPools(connectionId, metadata)
		
		-- Update statistics
		self:_updateStats("destroyed", metadata.connectionType, metadata.service)
		
		self:_log("debug", "Connection disconnected", {
			connectionId = connectionId,
			service = metadata.service,
			description = metadata.description
		})
		
		return true
	end
	
	return false
end

-- Remove connection from all storage pools
function ConnectionManager:_removeFromPools(connectionId, metadata)
	-- Remove from global pool
	self._globalConnections[connectionId] = nil
	self._connectionMetadata[connectionId] = nil
	self._cleanupCallbacks[connectionId] = nil
	
	-- Remove from player pool
	if metadata.player and self._playerConnections[metadata.player] then
		self._playerConnections[metadata.player][connectionId] = nil
		
		-- Clean up empty player pool
		if next(self._playerConnections[metadata.player]) == nil then
			self._playerConnections[metadata.player] = nil
		end
	end
	
	-- Remove from service pool
	if metadata.service and self._serviceConnections[metadata.service] then
		self._serviceConnections[metadata.service][connectionId] = nil
		
		-- Clean up empty service pool
		if next(self._serviceConnections[metadata.service]) == nil then
			self._serviceConnections[metadata.service] = nil
		end
	end
	
	-- Remove from tag pool
	if metadata.tag and self._taggedConnections[metadata.tag] then
		self._taggedConnections[metadata.tag][connectionId] = nil
		
		-- Clean up empty tag pool
		if next(self._taggedConnections[metadata.tag]) == nil then
			self._taggedConnections[metadata.tag] = nil
		end
	end
end

--[[
	Clean up all connections for a specific player
	This should be called when a player leaves the game
	
	@param player: Player instance
	@returns: number of connections cleaned up
--]]
function ConnectionManager:CleanupPlayerConnections(player)
	if not player then return 0 end
	
	local playerConnections = self._playerConnections[player]
	if not playerConnections then return 0 end
	
	local cleanedCount = 0
	local errors = {}
	
	for connectionId, connection in pairs(playerConnections) do
		local metadata = self._connectionMetadata[connectionId]
		local success = self:_safeDisconnect(connection, connectionId, metadata)
		
		if success then
			self:_removeFromPools(connectionId, metadata)
			self:_updateStats("destroyed", metadata and metadata.connectionType, metadata and metadata.service)
			cleanedCount = cleanedCount + 1
		else
			table.insert(errors, connectionId)
		end
	end
	
	-- Force cleanup player pool even if some connections failed
	self._playerConnections[player] = nil
	
	self.Stats.memoryLeaksPreventend = self.Stats.memoryLeaksPreventend + cleanedCount
	
	self:_log("info", "Player connections cleaned up", {
		player = player.Name,
		cleanedCount = cleanedCount,
		errorCount = #errors,
		errors = errors
	})
	
	return cleanedCount
end

--[[
	Clean up all connections for a specific service
	This should be called when a service shuts down
	
	@param serviceName: Name of the service
	@returns: number of connections cleaned up
--]]
function ConnectionManager:CleanupServiceConnections(serviceName)
	if not serviceName then return 0 end
	
	local serviceConnections = self._serviceConnections[serviceName]
	if not serviceConnections then return 0 end
	
	local cleanedCount = 0
	local errors = {}
	
	for connectionId, connection in pairs(serviceConnections) do
		local metadata = self._connectionMetadata[connectionId]
		local success = self:_safeDisconnect(connection, connectionId, metadata)
		
		if success then
			self:_removeFromPools(connectionId, metadata)
			self:_updateStats("destroyed", metadata and metadata.connectionType, serviceName)
			cleanedCount = cleanedCount + 1
		else
			table.insert(errors, connectionId)
		end
	end
	
	-- Force cleanup service pool even if some connections failed
	self._serviceConnections[serviceName] = nil
	self._connectionCounts[serviceName] = nil
	
	self.Stats.memoryLeaksPreventend = self.Stats.memoryLeaksPreventend + cleanedCount
	
	self:_log("info", "Service connections cleaned up", {
		service = serviceName,
		cleanedCount = cleanedCount,
		errorCount = #errors,
		errors = errors
	})
	
	return cleanedCount
end

--[[
	Clean up connections by tag
	Useful for cleaning up themed or temporary connections
	
	@param tag: Tag string
	@returns: number of connections cleaned up
--]]
function ConnectionManager:CleanupTaggedConnections(tag)
	if not tag then return 0 end
	
	local taggedConnections = self._taggedConnections[tag]
	if not taggedConnections then return 0 end
	
	local cleanedCount = 0
	
	for connectionId, connection in pairs(taggedConnections) do
		local metadata = self._connectionMetadata[connectionId]
		local success = self:_safeDisconnect(connection, connectionId, metadata)
		
		if success then
			self:_removeFromPools(connectionId, metadata)
			self:_updateStats("destroyed", metadata and metadata.connectionType, metadata and metadata.service)
			cleanedCount = cleanedCount + 1
		end
	end
	
	self._taggedConnections[tag] = nil
	
	self:_log("info", "Tagged connections cleaned up", {
		tag = tag,
		cleanedCount = cleanedCount
	})
	
	return cleanedCount
end

--[[
	Clean up stale connections (based on timeout or invalid state)
	This runs automatically but can be called manually
	
	@returns: number of connections cleaned up
--]]
function ConnectionManager:CleanupStaleConnections()
	local currentTime = tick()
	local cleanedCount = 0
	local staleConnections = {}
	
	-- Find stale connections
	for connectionId, metadata in pairs(self._connectionMetadata) do
		local connection = self._globalConnections[connectionId]
		local isStale = false
		
		-- Check if connection is invalid
		if not self:_isValidConnection(connection) then
			isStale = true
		-- Check if connection has timed out
		elseif currentTime - metadata.created > metadata.timeout then
			isStale = true
		end
		
		if isStale then
			table.insert(staleConnections, connectionId)
		end
	end
	
	-- Clean up stale connections
	for _, connectionId in ipairs(staleConnections) do
		local metadata = self._connectionMetadata[connectionId]
		local connection = self._globalConnections[connectionId]
		
		self:_safeDisconnect(connection, connectionId, metadata)
		self:_removeFromPools(connectionId, metadata)
		self:_updateStats("destroyed", metadata and metadata.connectionType, metadata and metadata.service)
		cleanedCount = cleanedCount + 1
	end
	
	self.Stats.lastCleanupTime = currentTime
	
	if cleanedCount > 0 then
		self:_log("info", "Stale connections cleaned up", {
			cleanedCount = cleanedCount,
			totalConnections = self.Stats.totalConnections
		})
	end
	
	return cleanedCount
end

--[[
	Clean up ALL connections (nuclear option)
	Use with caution - this will disconnect everything
	
	@returns: number of connections cleaned up
--]]
function ConnectionManager:CleanupAllConnections()
	local cleanedCount = 0
	
	for connectionId, connection in pairs(self._globalConnections) do
		local metadata = self._connectionMetadata[connectionId]
		local success = self:_safeDisconnect(connection, connectionId, metadata)
		
		if success then
			cleanedCount = cleanedCount + 1
		end
	end
	
	-- Clear all pools
	self._playerConnections = {}
	self._serviceConnections = {}
	self._globalConnections = {}
	self._taggedConnections = {}
	self._connectionMetadata = {}
	self._connectionCounts = {}
	self._cleanupCallbacks = {}
	
	-- Reset stats
	self.Stats.totalConnections = 0
	self.Stats.memoryLeaksPreventend = self.Stats.memoryLeaksPreventend + cleanedCount
	
	self:_log("warn", "ALL connections cleaned up", {
		cleanedCount = cleanedCount
	})
	
	return cleanedCount
end

--[[
	Get comprehensive statistics about connection usage
	
	@returns: Table with detailed statistics
--]]
function ConnectionManager:GetStatistics()
	local stats = {
		overview = {
			totalConnections = self.Stats.totalConnections,
			connectionsCreated = self.Stats.connectionsCreated,
			connectionsDestroyed = self.Stats.connectionsDestroyed,
			memoryLeaksPreventend = self.Stats.memoryLeaksPreventend,
			cleanupErrors = self.Stats.cleanupErrors,
			lastCleanupTime = self.Stats.lastCleanupTime
		},
		
		byService = {},
		byPlayer = {},
		byTag = {},
		byType = {},
		
		limits = {
			maxConnectionsPerPlayer = self.Config.MAX_CONNECTIONS_PER_PLAYER,
			maxConnectionsPerService = self.Config.MAX_CONNECTIONS_PER_SERVICE,
			autoCleanupThreshold = self.Config.AUTO_CLEANUP_THRESHOLD
		}
	}
	
	-- Service statistics
	for serviceName, count in pairs(self._connectionCounts) do
		stats.byService[serviceName] = count
	end
	
	-- Player statistics
	for player, connections in pairs(self._playerConnections) do
		local count = 0
		for _ in pairs(connections) do count = count + 1 end
		stats.byPlayer[player.Name] = count
	end
	
	-- Tag statistics
	for tag, connections in pairs(self._taggedConnections) do
		local count = 0
		for _ in pairs(connections) do count = count + 1 end
		stats.byTag[tag] = count
	end
	
	-- Type statistics
	for _, metadata in pairs(self._connectionMetadata) do
		local connectionType = metadata.connectionType
		stats.byType[connectionType] = (stats.byType[connectionType] or 0) + 1
	end
	
	return stats
end

--[[
	Get detailed information about all connections
	Useful for debugging and monitoring
	
	@returns: Table with connection details
--]]
function ConnectionManager:GetConnectionDetails()
	local details = {}
	
	for connectionId, metadata in pairs(self._connectionMetadata) do
		local connection = self._globalConnections[connectionId]
		
		details[connectionId] = {
			id = connectionId,
			description = metadata.description,
			service = metadata.service,
			player = metadata.player and metadata.player.Name,
			tag = metadata.tag,
			connectionType = metadata.connectionType,
			created = metadata.created,
			age = tick() - metadata.created,
			timeout = metadata.timeout,
			isValid = self:_isValidConnection(connection),
			hasCleanupCallback = self._cleanupCallbacks[connectionId] ~= nil
		}
	end
	
	return details
end

--[[
	Helper function to create and track common connection types
	with automatic cleanup setup
--]]
function ConnectionManager:CreateTrackedConnection(signal, callback, options)
	if not signal or not callback then
		self:_log("error", "Invalid signal or callback provided to CreateTrackedConnection")
		return nil
	end
	
	options = options or {}
	
	local connection
	local success, error = pcall(function()
		connection = signal:Connect(callback)
	end)
	
	if not success then
		self:_log("error", "Failed to create connection", {
			error = tostring(error),
			service = options.service,
			description = options.description
		})
		return nil
	end
	
	local connectionId = self:TrackConnection(connection, options)
	
	return {
		connectionId = connectionId,
		connection = connection,
		disconnect = function()
			return self:DisconnectConnection(connectionId)
		end
	}
end

-- Initialize the connection manager
function ConnectionManager:Initialize()
	self:_log("info", "Initializing ConnectionManager")
	
	-- Set up automatic player cleanup
	Players.PlayerRemoving:Connect(function(player)
		self:CleanupPlayerConnections(player)
	end)
	
	-- Set up automatic stale connection cleanup
	if self.Config.CLEANUP_INTERVAL > 0 then
		RunService.Heartbeat:Connect(function()
			local currentTime = tick()
			if currentTime - self.Stats.lastCleanupTime >= self.Config.CLEANUP_INTERVAL then
				self:CleanupStaleConnections()
			end
		end)
	end
	
	-- Set up memory monitoring if enabled
	if self.Config.ENABLE_MEMORY_MONITORING then
		spawn(function()
			while true do
				wait(60) -- Check every minute
				
				local stats = self:GetStatistics()
				if stats.overview.totalConnections > 1000 then
					self:_log("warn", "High connection count detected", {
						totalConnections = stats.overview.totalConnections,
						suggestion = "Consider reviewing connection cleanup patterns"
					})
				end
			end
		end)
	end
	
	self:_log("info", "ConnectionManager initialized successfully")
end

-- Shutdown the connection manager
function ConnectionManager:Shutdown()
	self:_log("info", "Shutting down ConnectionManager")
	
	local cleanedCount = self:CleanupAllConnections()
	
	self:_log("info", "ConnectionManager shutdown complete", {
		cleanedConnections = cleanedCount
	})
end

return ConnectionManager
