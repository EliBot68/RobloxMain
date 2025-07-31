--[[
	ConnectionManagerService.luau
	
	Service wrapper for ConnectionManager that provides easy integration
	patterns for all game services. This handles the most common connection
	patterns and provides bulletproof cleanup.
--]]

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Safe require with fallback
local function safeRequire(module, fallback)
	local success, result = pcall(require, module)
	return success and result or fallback or {}
end

local _SafeRequire = safeRequire(ReplicatedStorage.Shared.utils.SafeRequire)
local ConnectionManager = safeRequire(ReplicatedStorage.Shared.core.ConnectionManager)

local ConnectionManagerService = {
	_initialized = false,
	_serviceConnections = {}, -- [serviceName] = { connectionIds }
	_playerServiceConnections = {}, -- [player][serviceName] = { connectionIds }
}

--[[
	Initialize the connection manager service
	This should be called once during game startup
--]]
function ConnectionManagerService:Initialize()
	if self._initialized then return end
	
	if ConnectionManager and ConnectionManager.Initialize then
		ConnectionManager:Initialize()
	end
	
	-- Set up automatic service cleanup tracking
	Players.PlayerRemoving:Connect(function(player)
		self:CleanupPlayerServiceConnections(player)
	end)
	
	self._initialized = true
	print("✅ ConnectionManagerService initialized")
end

--[[
	Connect a player event with automatic cleanup
	
	@param player: Player instance
	@param signal: The signal to connect to (e.g., player.CharacterAdded)
	@param callback: Function to call when signal fires
	@param serviceName: Name of the service creating this connection
	@param description: Optional description for debugging
	
	@returns: connectionId for manual cleanup if needed
--]]
function ConnectionManagerService:ConnectPlayerEvent(player, signal, callback, serviceName, description)
	if not ConnectionManager then return nil end
	
	local connectionId = ConnectionManager:TrackConnection(
		signal:Connect(callback),
		{
			player = player,
			service = serviceName,
			description = description or "Player event connection",
			connectionType = ConnectionManager.ConnectionTypes.PLAYER_EVENT
		}
	)
	
	-- Track for service cleanup
	if serviceName then
		self:_trackServiceConnection(serviceName, connectionId)
		self:_trackPlayerServiceConnection(player, serviceName, connectionId)
	end
	
	return connectionId
end

--[[
	Connect a RemoteEvent or RemoteFunction with automatic cleanup
	
	@param remoteObject: RemoteEvent or RemoteFunction
	@param eventType: "OnServerEvent", "OnClientEvent", "OnServerInvoke", "OnClientInvoke"
	@param callback: Function to call when remote fires
	@param serviceName: Name of the service creating this connection
	@param description: Optional description for debugging
	
	@returns: connectionId for manual cleanup if needed
--]]
function ConnectionManagerService:ConnectRemoteHandler(remoteObject, eventType, callback, serviceName, description)
	if not ConnectionManager then return nil end
	if not remoteObject or not remoteObject[eventType] then return nil end
	
	local connectionId = ConnectionManager:TrackConnection(
		remoteObject[eventType]:Connect(callback),
		{
			service = serviceName,
			description = description or string.format("Remote %s handler", eventType),
			connectionType = ConnectionManager.ConnectionTypes.REMOTE_HANDLER
		}
	)
	
	-- Track for service cleanup
	if serviceName then
		self:_trackServiceConnection(serviceName, connectionId)
	end
	
	return connectionId
end

--[[
	Connect a RunService event (Heartbeat, Stepped, RenderStepped) with automatic cleanup
	
	@param serviceType: "Heartbeat", "Stepped", or "RenderStepped"
	@param callback: Function to call each frame/step
	@param serviceName: Name of the service creating this connection
	@param player: Optional player if this is player-specific
	@param description: Optional description for debugging
	
	@returns: connectionId for manual cleanup if needed
--]]
function ConnectionManagerService:ConnectRunServiceEvent(serviceType, callback, serviceName, player, description)
	if not ConnectionManager then return nil end
	
	local signal
	if serviceType == "Heartbeat" then
		signal = RunService.Heartbeat
	elseif serviceType == "Stepped" then
		signal = RunService.Stepped
	elseif serviceType == "RenderStepped" then
		signal = RunService.RenderStepped
	else
		warn("Invalid RunService event type:", serviceType)
		return nil
	end
	
	local connectionType = ConnectionManager.ConnectionTypes.HEARTBEAT
	if serviceType == "Stepped" then
		connectionType = ConnectionManager.ConnectionTypes.STEPPED
	elseif serviceType == "RenderStepped" then
		connectionType = ConnectionManager.ConnectionTypes.RENDERSTEPPED
	end
	
	local connectionId = ConnectionManager:TrackConnection(
		signal:Connect(callback),
		{
			service = serviceName,
			player = player,
			description = description or string.format("%s connection", serviceType),
			connectionType = connectionType
		}
	)
	
	-- Track for service cleanup
	if serviceName then
		self:_trackServiceConnection(serviceName, connectionId)
		if player then
			self:_trackPlayerServiceConnection(player, serviceName, connectionId)
		end
	end
	
	return connectionId
end

--[[
	Connect a state watcher (for observing data changes) with automatic cleanup
	
	@param signal: Signal that fires when state changes
	@param callback: Function to call when state changes
	@param serviceName: Name of the service creating this connection
	@param player: Optional player if this is player-specific
	@param description: Optional description for debugging
	
	@returns: connectionId for manual cleanup if needed
--]]
function ConnectionManagerService:ConnectStateWatcher(signal, callback, serviceName, player, description)
	if not ConnectionManager then return nil end
	
	local connectionId = ConnectionManager:TrackConnection(
		signal:Connect(callback),
		{
			service = serviceName,
			player = player,
			description = description or "State watcher connection",
			connectionType = ConnectionManager.ConnectionTypes.STATE_WATCHER
		}
	)
	
	-- Track for service cleanup
	if serviceName then
		self:_trackServiceConnection(serviceName, connectionId)
		if player then
			self:_trackPlayerServiceConnection(player, serviceName, connectionId)
		end
	end
	
	return connectionId
end

--[[
	Connect a GUI event with automatic cleanup
	
	@param guiObject: GUI object (Button, TextBox, etc.)
	@param eventName: Event name ("Activated", "MouseButton1Click", etc.)
	@param callback: Function to call when event fires
	@param serviceName: Name of the service creating this connection
	@param player: Player who owns the GUI
	@param description: Optional description for debugging
	
	@returns: connectionId for manual cleanup if needed
--]]
function ConnectionManagerService:ConnectGUIEvent(guiObject, eventName, callback, serviceName, player, description)
	if not ConnectionManager then return nil end
	if not guiObject or not guiObject[eventName] then return nil end
	
	local connectionId = ConnectionManager:TrackConnection(
		guiObject[eventName]:Connect(callback),
		{
			service = serviceName,
			player = player,
			description = description or string.format("GUI %s event", eventName),
			connectionType = ConnectionManager.ConnectionTypes.GUI
		}
	)
	
	-- Track for service cleanup
	if serviceName then
		self:_trackServiceConnection(serviceName, connectionId)
		if player then
			self:_trackPlayerServiceConnection(player, serviceName, connectionId)
		end
	end
	
	return connectionId
end

--[[
	Connect a sound event with automatic cleanup
	
	@param sound: Sound object
	@param eventName: Event name ("Ended", "Played", etc.)
	@param callback: Function to call when event fires
	@param serviceName: Name of the service creating this connection
	@param player: Optional player if this is player-specific
	@param description: Optional description for debugging
	
	@returns: connectionId for manual cleanup if needed
--]]
function ConnectionManagerService:ConnectSoundEvent(sound, eventName, callback, serviceName, player, description)
	if not ConnectionManager then return nil end
	if not sound or not sound[eventName] then return nil end
	
	local connectionId = ConnectionManager:TrackConnection(
		sound[eventName]:Connect(callback),
		{
			service = serviceName,
			player = player,
			description = description or string.format("Sound %s event", eventName),
			connectionType = ConnectionManager.ConnectionTypes.SOUND
		}
	)
	
	-- Track for service cleanup
	if serviceName then
		self:_trackServiceConnection(serviceName, connectionId)
		if player then
			self:_trackPlayerServiceConnection(player, serviceName, connectionId)
		end
	end
	
	return connectionId
end

--[[
	Connect a physics event with automatic cleanup
	
	@param part: BasePart with the physics event
	@param eventName: Event name ("Touched", "TouchEnded", etc.)
	@param callback: Function to call when event fires
	@param serviceName: Name of the service creating this connection
	@param player: Optional player if this is player-specific
	@param description: Optional description for debugging
	
	@returns: connectionId for manual cleanup if needed
--]]
function ConnectionManagerService:ConnectPhysicsEvent(part, eventName, callback, serviceName, player, description)
	if not ConnectionManager then return nil end
	if not part or not part[eventName] then return nil end
	
	local connectionId = ConnectionManager:TrackConnection(
		part[eventName]:Connect(callback),
		{
			service = serviceName,
			player = player,
			description = description or string.format("Physics %s event", eventName),
			connectionType = ConnectionManager.ConnectionTypes.PHYSICS
		}
	)
	
	-- Track for service cleanup
	if serviceName then
		self:_trackServiceConnection(serviceName, connectionId)
		if player then
			self:_trackPlayerServiceConnection(player, serviceName, connectionId)
		end
	end
	
	return connectionId
end

--[[
	Create a timer connection that automatically cleans up
	
	@param interval: Time in seconds between calls
	@param callback: Function to call each interval
	@param serviceName: Name of the service creating this connection
	@param player: Optional player if this is player-specific
	@param description: Optional description for debugging
	@param maxCalls: Optional maximum number of calls before auto-disconnect
	
	@returns: connectionId for manual cleanup if needed
--]]
function ConnectionManagerService:CreateTimer(interval, callback, serviceName, player, description, maxCalls)
	if not ConnectionManager then return nil end
	
	local calls = 0
	local startTime = tick()
	local lastCall = startTime
	local connectionId -- Declare here so it's available in the callback
	
	local function timerCallback()
		local currentTime = tick()
		if currentTime - lastCall >= interval then
			lastCall = currentTime
			calls = calls + 1
			
			callback(calls, currentTime - startTime)
			
			-- Auto-disconnect if max calls reached
			if maxCalls and calls >= maxCalls then
				if connectionId then
					ConnectionManager:DisconnectConnection(connectionId)
				end
			end
		end
	end
	
	connectionId = ConnectionManager:TrackConnection(
		RunService.Heartbeat:Connect(timerCallback),
		{
			service = serviceName,
			player = player,
			description = description or string.format("Timer (%.2fs interval)", interval),
			connectionType = ConnectionManager.ConnectionTypes.TIMER
		}
	)
	
	-- Track for service cleanup
	if serviceName then
		self:_trackServiceConnection(serviceName, connectionId)
		if player then
			self:_trackPlayerServiceConnection(player, serviceName, connectionId)
		end
	end
	
	return connectionId
end

--[[
	Disconnect a specific connection
	
	@param connectionId: The ID returned from any Connect method
	@returns: success (boolean)
--]]
function ConnectionManagerService:DisconnectConnection(connectionId)
	if not ConnectionManager then return false end
	return ConnectionManager:DisconnectConnection(connectionId)
end

--[[
	Clean up all connections for a specific service
	This should be called when a service shuts down
	
	@param serviceName: Name of the service
	@returns: number of connections cleaned up
--]]
function ConnectionManagerService:CleanupServiceConnections(serviceName)
	if not ConnectionManager then return 0 end
	
	local cleanedCount = ConnectionManager:CleanupServiceConnections(serviceName)
	
	-- Clean up our tracking
	self._serviceConnections[serviceName] = nil
	
	-- Clean up player-service tracking
	for player, services in pairs(self._playerServiceConnections) do
		if services[serviceName] then
			services[serviceName] = nil
			
			-- Clean up empty player entry
			if next(services) == nil then
				self._playerServiceConnections[player] = nil
			end
		end
	end
	
	return cleanedCount
end

--[[
	Clean up all connections for a specific player across all services
	
	@param player: Player instance
	@returns: number of connections cleaned up
--]]
function ConnectionManagerService:CleanupPlayerConnections(player)
	if not ConnectionManager then return 0 end
	
	local cleanedCount = ConnectionManager:CleanupPlayerConnections(player)
	
	-- Clean up our tracking
	self._playerServiceConnections[player] = nil
	
	return cleanedCount
end

--[[
	Clean up connections for a specific player in a specific service
	
	@param player: Player instance
	@param serviceName: Name of the service
	@returns: number of connections cleaned up
--]]
function ConnectionManagerService:CleanupPlayerServiceConnections(player, serviceName)
	if not player then return 0 end
	
	local cleanedCount = 0
	local playerServices = self._playerServiceConnections[player]
	
	if playerServices then
		if serviceName then
			-- Clean up specific service for player
			local connectionIds = playerServices[serviceName]
			if connectionIds then
				for _, connectionId in ipairs(connectionIds) do
					if ConnectionManager:DisconnectConnection(connectionId) then
						cleanedCount = cleanedCount + 1
					end
				end
				playerServices[serviceName] = nil
			end
		else
			-- Clean up all services for player
			for service, connectionIds in pairs(playerServices) do
				for _, connectionId in ipairs(connectionIds) do
					if ConnectionManager:DisconnectConnection(connectionId) then
						cleanedCount = cleanedCount + 1
					end
				end
			end
			self._playerServiceConnections[player] = nil
		end
	end
	
	return cleanedCount
end

--[[
	Get statistics about connection usage
	
	@returns: Table with detailed statistics
--]]
function ConnectionManagerService:GetStatistics()
	if not ConnectionManager then return {} end
	return ConnectionManager:GetStatistics()
end

--[[
	Get detailed connection information for debugging
	
	@returns: Table with connection details
--]]
function ConnectionManagerService:GetConnectionDetails()
	if not ConnectionManager then return {} end
	return ConnectionManager:GetConnectionDetails()
end

-- Internal tracking helpers
function ConnectionManagerService:_trackServiceConnection(serviceName, connectionId)
	if not serviceName or not connectionId then return end
	
	self._serviceConnections[serviceName] = self._serviceConnections[serviceName] or {}
	table.insert(self._serviceConnections[serviceName], connectionId)
end

function ConnectionManagerService:_trackPlayerServiceConnection(player, serviceName, connectionId)
	if not player or not serviceName or not connectionId then return end
	
	self._playerServiceConnections[player] = self._playerServiceConnections[player] or {}
	self._playerServiceConnections[player][serviceName] = self._playerServiceConnections[player][serviceName] or {}
	table.insert(self._playerServiceConnections[player][serviceName], connectionId)
end

return ConnectionManagerService
