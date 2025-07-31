-- ServiceConnectionHelper.luau
-- Helper utilities for services to easily integrate with ConnectionManager
-- Provides common patterns and simplified APIs for connection management

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local ConnectionManager = require(ReplicatedStorage.Shared.core.ConnectionManager)

local ServiceConnectionHelper = {}

--[[
    Create a service-specific connection manager helper
    This provides a scoped API for a service to manage its connections
    
    @param serviceName: Name of the service
    @returns: ServiceHelper instance
--]]
function ServiceConnectionHelper.CreateServiceHelper(serviceName)
    local ServiceHelper = {
        serviceName = serviceName,
        connections = {}
    }
    
    -- Track a connection with service context
    function ServiceHelper:TrackConnection(connection, options)
        options = options or {}
        options.service = self.serviceName
        
        local connectionId = ConnectionManager:TrackConnection(connection, options)
        if connectionId then
            self.connections[connectionId] = true
        end
        return connectionId
    end
    
    -- Connect to player events with automatic cleanup
    function ServiceHelper:ConnectPlayerEvent(eventName, callback, options)
        options = options or {}
        options.connectionType = ConnectionManager.ConnectionTypes.PLAYER_EVENT
        options.description = options.description or (self.serviceName .. " - " .. eventName)
        
        local connection = Players[eventName]:Connect(function(player, ...)
            callback(player, ...)
        end)
        
        return self:TrackConnection(connection, options)
    end
    
    -- Connect to a player's character events
    function ServiceHelper:ConnectPlayerCharacterEvent(player, eventName, callback, options)
        options = options or {}
        options.player = player
        options.connectionType = ConnectionManager.ConnectionTypes.PLAYER_EVENT
        options.description = options.description or (self.serviceName .. " - " .. player.Name .. " character " .. eventName)
        
        local function setupCharacterConnection(character)
            if character and character[eventName] then
                local connection = character[eventName]:Connect(callback)
                return self:TrackConnection(connection, options)
            end
            return nil
        end
        
        -- Connect to current character if it exists
        if player.Character then
            setupCharacterConnection(player.Character)
        end
        
        -- Connect to future characters
        local characterConnection = player.CharacterAdded:Connect(setupCharacterConnection)
        return self:TrackConnection(characterConnection, {
            player = player,
            connectionType = ConnectionManager.ConnectionTypes.PLAYER_EVENT,
            description = self.serviceName .. " - " .. player.Name .. " CharacterAdded watcher"
        })
    end
    
    -- Connect to RemoteEvent with automatic type setting
    function ServiceHelper:ConnectRemoteEvent(remoteEvent, callback, options)
        options = options or {}
        options.connectionType = ConnectionManager.ConnectionTypes.REMOTE_HANDLER
        options.description = options.description or (self.serviceName .. " - RemoteEvent: " .. tostring(remoteEvent))
        
        local connection
        if remoteEvent.OnServerEvent then
            connection = remoteEvent.OnServerEvent:Connect(callback)
        elseif remoteEvent.OnClientEvent then
            connection = remoteEvent.OnClientEvent:Connect(callback)
        else
            warn("Invalid RemoteEvent: " .. tostring(remoteEvent))
            return nil
        end
        
        return self:TrackConnection(connection, options)
    end
    
    -- Connect to GUI events with proper cleanup
    function ServiceHelper:ConnectGUIEvent(guiObject, eventName, callback, options)
        options = options or {}
        options.connectionType = ConnectionManager.ConnectionTypes.GUI
        options.description = options.description or (self.serviceName .. " - " .. tostring(guiObject) .. "." .. eventName)
        
        if not guiObject or not guiObject[eventName] then
            warn("Invalid GUI object or event: " .. tostring(guiObject) .. "." .. tostring(eventName))
            return nil
        end
        
        local connection = guiObject[eventName]:Connect(callback)
        return self:TrackConnection(connection, options)
    end
    
    -- Connect to RunService events with managed connections
    function ServiceHelper:ConnectRunServiceEvent(eventName, callback, options)
        options = options or {}
        options.connectionType = options.connectionType or ConnectionManager.ConnectionTypes.HEARTBEAT
        options.description = options.description or (self.serviceName .. " - " .. eventName)
        
        if not RunService[eventName] then
            warn("Invalid RunService event: " .. tostring(eventName))
            return nil
        end
        
        local connection = RunService[eventName]:Connect(callback)
        return self:TrackConnection(connection, options)
    end
    
    -- Connect to Part.Touched events with debouncing
    function ServiceHelper:ConnectTouchEvent(part, callback, debounceTime, options)
        options = options or {}
        options.connectionType = ConnectionManager.ConnectionTypes.PHYSICS
        options.description = options.description or (self.serviceName .. " - " .. tostring(part) .. ".Touched")
        
        debounceTime = debounceTime or 0.1
        local lastTouchTime = {}
        
        local connection = part.Touched:Connect(function(hit, ...)
            local character = hit.Parent
            local humanoid = character:FindFirstChild("Humanoid")
            if not humanoid then return end
            
            local player = Players:GetPlayerFromCharacter(character)
            if not player then return end
            
            local now = tick()
            local lastTouch = lastTouchTime[player.UserId] or 0
            
            if now - lastTouch >= debounceTime then
                lastTouchTime[player.UserId] = now
                callback(hit, player, character, ...)
            end
        end)
        
        return self:TrackConnection(connection, options)
    end
    
    -- Connect with automatic retry on failure
    function ServiceHelper:ConnectWithRetry(signalGetter, callback, maxRetries, retryDelay, options)
        maxRetries = maxRetries or 3
        retryDelay = retryDelay or 1
        options = options or {}
        
        local function attemptConnection(attempt)
            local success, signal = pcall(signalGetter)
            if success and signal then
                local connection = signal:Connect(callback)
                return self:TrackConnection(connection, options)
            else
                if attempt < maxRetries then
                    warn(string.format("Connection attempt %d failed, retrying in %d seconds...", attempt, retryDelay))
                    task.wait(retryDelay)
                    return attemptConnection(attempt + 1)
                else
                    warn(string.format("Connection failed after %d attempts", maxRetries))
                    return nil
                end
            end
        end
        
        return attemptConnection(1)
    end
    
    -- Batch connect multiple signals
    function ServiceHelper:BatchConnect(signalDefinitions)
        local connectionIds = {}
        
        for i, definition in ipairs(signalDefinitions) do
            local signal = definition.signal
            local callback = definition.callback
            local options = definition.options or {}
            options.description = options.description or (self.serviceName .. " - Batch connection " .. i)
            
            local connection = signal:Connect(callback)
            local connectionId = self:TrackConnection(connection, options)
            
            if connectionId then
                table.insert(connectionIds, connectionId)
            end
        end
        
        return connectionIds
    end
    
    -- Disconnect a specific connection
    function ServiceHelper:DisconnectConnection(connectionId)
        if self.connections[connectionId] then
            self.connections[connectionId] = nil
            return ConnectionManager:DisconnectConnection(connectionId)
        end
        return false
    end
    
    -- Clean up all connections for this service
    function ServiceHelper:CleanupAll()
        local cleanedCount = ConnectionManager:CleanupServiceConnections(self.serviceName)
        self.connections = {}
        return cleanedCount
    end
    
    -- Get statistics for this service
    function ServiceHelper:GetStatistics()
        local stats = ConnectionManager:GetStatistics()
        return {
            totalConnections = stats.byService[self.serviceName] or 0,
            serviceConnections = self.connections,
            activeConnectionCount = 0 -- Will be calculated
        }
    end
    
    -- Add cleanup to service shutdown
    function ServiceHelper:AddToShutdownSequence()
        game:BindToClose(function()
            print("🧹 Shutting down " .. self.serviceName .. " connections...")
            self:CleanupAll()
        end)
    end
    
    return ServiceHelper
end

--[[
    Create common connection patterns for typical game services
--]]

-- Player lifecycle management helper
function ServiceConnectionHelper.CreatePlayerLifecycleHelper(serviceName)
    local helper = ServiceConnectionHelper.CreateServiceHelper(serviceName)
    
    -- Track all players and their connections
    local playerConnections = {}
    
    function helper:OnPlayerAdded(callback)
        return self:ConnectPlayerEvent("PlayerAdded", function(player)
            playerConnections[player] = {}
            callback(player)
        end)
    end
    
    function helper:OnPlayerRemoving(callback)
        return self:ConnectPlayerEvent("PlayerRemoving", function(player)
            if callback then
                callback(player)
            end
            
            -- Clean up player-specific connections
            if playerConnections[player] then
                for connectionId, _ in pairs(playerConnections[player]) do
                    ConnectionManager:DisconnectConnection(connectionId)
                end
                playerConnections[player] = nil
            end
        end)
    end
    
    function helper:OnCharacterAdded(callback)
        return self:ConnectPlayerEvent("PlayerAdded", function(player)
            local characterConnection = player.CharacterAdded:Connect(function(character)
                callback(player, character)
            end)
            
            local connectionId = self:TrackConnection(characterConnection, {
                player = player,
                connectionType = ConnectionManager.ConnectionTypes.PLAYER_EVENT,
                description = serviceName .. " - " .. player.Name .. " character tracking"
            })
            
            if playerConnections[player] then
                playerConnections[player][connectionId] = true
            end
        end)
    end
    
    return helper
end

-- Remote event helper for client-server communication
function ServiceConnectionHelper.CreateRemoteEventHelper(serviceName, remoteEvents)
    local helper = ServiceConnectionHelper.CreateServiceHelper(serviceName)
    
    function helper:SetupRemoteHandlers(handlers)
        for eventName, callback in pairs(handlers) do
            local remoteEvent = remoteEvents[eventName]
            if remoteEvent then
                self:ConnectRemoteEvent(remoteEvent, callback, {
                    description = serviceName .. " - Remote handler: " .. eventName
                })
            else
                warn("Remote event not found: " .. eventName)
            end
        end
    end
    
    return helper
end

-- Performance monitoring helper
function ServiceConnectionHelper.CreatePerformanceHelper(serviceName, thresholds)
    local helper = ServiceConnectionHelper.CreateServiceHelper(serviceName)
    
    thresholds = thresholds or {
        maxConnections = 100,
        warningThreshold = 80,
        checkInterval = 30
    }
    
    -- Monitor connection count
    helper:ConnectRunServiceEvent("Heartbeat", function()
        local stats = helper:GetStatistics()
        
        if stats.totalConnections > thresholds.warningThreshold then
            warn(string.format("🔍 %s connection count high: %d/%d", 
                serviceName, stats.totalConnections, thresholds.maxConnections))
        end
        
        if stats.totalConnections > thresholds.maxConnections then
            warn(string.format("⚠️ %s connection limit exceeded: %d/%d - forcing cleanup", 
                serviceName, stats.totalConnections, thresholds.maxConnections))
            helper:CleanupAll()
        end
    end, {
        description = serviceName .. " - Performance monitoring"
    })
    
    return helper
end

return ServiceConnectionHelper
