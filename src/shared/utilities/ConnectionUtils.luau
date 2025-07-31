-- ConnectionUtils.luau
-- Utility functions and patterns for easy migration to ConnectionManager
-- Provides backwards-compatible wrappers and migration helpers

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local ConnectionManager = require(script.Parent.ConnectionManager)

local ConnectionUtils = {}

-- ========================================
-- BACKWARDS-COMPATIBLE WRAPPERS
-- ========================================

-- Simple connection wrapper that auto-registers with ConnectionManager
function ConnectionUtils.Connect(signal, callback, owner, connectionName, connectionType)
    owner = owner or ("AutoDetected_" .. tick()) -- Fallback owner name
    connectionName = connectionName or ("Connection_" .. tick())
    connectionType = connectionType or "Generic"
    
    local connection = signal:Connect(callback)
    ConnectionManager:RegisterConnection(owner, connectionName, connection, connectionType)
    
    return connection
end

-- Enhanced connection wrapper with automatic cleanup registration
function ConnectionUtils.ConnectWithCleanup(signal, callback, owner, cleanupFunction)
    owner = owner or ("AutoCleanup_" .. tick())
    local connectionName = "AutoCleanup_" .. tick()
    
    local connection = signal:Connect(function(...)
        local success, result = pcall(callback, ...)
        if not success then
            warn("Connection callback error: " .. tostring(result))
            -- Auto-cleanup on error
            if cleanupFunction then
                cleanupFunction()
            end
            ConnectionManager:UnregisterConnection(owner, connectionName)
        end
    end)
    
    ConnectionManager:RegisterConnection(owner, connectionName, connection, "AutoCleanup")
    return connection, connectionName
end

-- ========================================
-- MIGRATION HELPERS
-- ========================================

-- Service migration helper - wraps a service with connection management
function ConnectionUtils.WrapService(serviceInstance, serviceName)
    serviceName = serviceName or serviceInstance.Name or "UnknownService"
    
    -- Add connection tracking methods to service
    serviceInstance._connections = {}
    serviceInstance._connectionManager = ConnectionManager
    
    -- Enhanced connection method
    function serviceInstance:AddConnection(name, signal, callback, connectionType)
        local connection = ConnectionUtils.Connect(signal, callback, serviceName, name, connectionType)
        self._connections[name] = connection
        return connection
    end
    
    -- Cleanup method
    function serviceInstance:CleanupConnections()
        return ConnectionManager:DisconnectAllForOwner(serviceName)
    end
    
    -- Get connection stats
    function serviceInstance:GetConnectionStats()
        local registry = ConnectionManager:GetConnectionRegistry(serviceName)
        if not registry then return {count = 0, connections = {}} end
        
        local stats = {count = 0, connections = {}}
        for name, data in pairs(registry) do
            stats.count = stats.count + 1
            stats.connections[name] = {
                type = data.type,
                state = data.state,
                age = tick() - data.timestamp
            }
        end
        return stats
    end
    
    return serviceInstance
end

-- Controller migration helper - enhances existing controller base
function ConnectionUtils.EnhanceController(controllerInstance, controllerName)
    controllerName = controllerName or controllerInstance.Name or "UnknownController"
    
    -- Replace existing connection management
    local originalAddConnection = controllerInstance.AddConnection
    function controllerInstance:AddConnection(name, connection, connectionType)
        if originalAddConnection then
            originalAddConnection(self, name, connection)
        end
        
        ConnectionManager:RegisterConnection(controllerName, name, connection, connectionType)
        return connection
    end
    
    -- Enhanced stop method with cleanup
    local originalStop = controllerInstance.Stop
    function controllerInstance:Stop()
        -- Cleanup connections first
        ConnectionManager:DisconnectAllForOwner(controllerName)
        
        -- Call original stop
        if originalStop then
            return originalStop(self)
        end
        return true
    end
    
    return controllerInstance
end

-- ========================================
-- COMMON PATTERNS
-- ========================================

-- Player management pattern
function ConnectionUtils.SetupPlayerManagement(service, onPlayerAdded, onPlayerRemoving)
    local serviceName = service.Name or "PlayerManager"
    
    -- Player added connection
    if onPlayerAdded then
        ConnectionManager:ConnectPlayerEvent("PlayerAdded", onPlayerAdded, serviceName)
    end
    
    -- Player removing connection
    if onPlayerRemoving then
        ConnectionManager:ConnectPlayerEvent("PlayerRemoving", function(player)
            onPlayerRemoving(player)
            -- Auto-cleanup player-specific connections
            ConnectionManager:DisconnectAllForOwner(tostring(player.UserId))
        end, serviceName)
    end
    
    -- Handle existing players
    if onPlayerAdded then
        for _, player in ipairs(Players:GetPlayers()) do
            task.spawn(onPlayerAdded, player)
        end
    end
end

-- Character management pattern
function ConnectionUtils.SetupCharacterManagement(service, player, onCharacterAdded, onCharacterRemoving)
    local serviceName = service.Name or "CharacterManager"
    local playerId = tostring(player.UserId)
    
    -- Character added connection
    if onCharacterAdded then
        ConnectionManager:ConnectCharacterEvent(player, "CharacterAdded", onCharacterAdded, serviceName)
    end
    
    -- Character removing connection  
    if onCharacterRemoving then
        ConnectionManager:ConnectCharacterEvent(player, "CharacterRemoving", function(character)
            onCharacterRemoving(character)
            -- Cleanup character-specific resources
            local characterConnections = playerId .. "_character"
            ConnectionManager:DisconnectAllForOwner(characterConnections)
        end, serviceName)
    end
    
    -- Handle existing character
    if player.Character and onCharacterAdded then
        task.spawn(onCharacterAdded, player.Character)
    end
end

-- Remote event management pattern
function ConnectionUtils.SetupRemoteEvents(service, remoteEvents)
    local serviceName = service.Name or "RemoteEventHandler"
    
    for eventName, callback in pairs(remoteEvents) do
        local remoteEvent = ReplicatedStorage.Shared.modules.RemoteEvents[eventName]
        if remoteEvent then
            ConnectionManager:ConnectRemoteEvent(remoteEvent, callback, serviceName)
        else
            warn("RemoteEvent not found: " .. eventName)
        end
    end
end

-- Touch event management with rate limiting
function ConnectionUtils.SetupTouchEvents(service, parts, callback, cooldown)
    cooldown = cooldown or 1 -- 1 second default cooldown
    local serviceName = service.Name or "TouchEventHandler"
    local lastTouchTimes = {}
    
    for _, part in ipairs(parts) do
        local wrappedCallback = function(hit)
            local player = Players:GetPlayerFromCharacter(hit.Parent)
            if not player then return end
            
            local playerId = tostring(player.UserId)
            local now = tick()
            
            if not lastTouchTimes[playerId] or now - lastTouchTimes[playerId] >= cooldown then
                lastTouchTimes[playerId] = now
                callback(hit, player)
            end
        end
        
        ConnectionManager:ConnectTouchEvent(part, wrappedCallback, serviceName)
    end
end

-- Heartbeat management with performance optimization
function ConnectionUtils.SetupHeartbeat(service, callback, interval, maxExecutionTime)
    interval = interval or 0
    maxExecutionTime = maxExecutionTime or 1/30 -- 30 FPS budget
    local serviceName = service.Name or "HeartbeatHandler"
    
    local wrappedCallback = function()
        local startTime = tick()
        
        local success, result = pcall(callback)
        
        local executionTime = tick() - startTime
        if executionTime > maxExecutionTime then
            warn(string.format("Heartbeat callback for %s took %.3fs (exceeds %.3fs budget)", 
                serviceName, executionTime, maxExecutionTime))
        end
        
        if not success then
            warn("Heartbeat callback error in " .. serviceName .. ": " .. tostring(result))
        end
    end
    
    return ConnectionManager:ConnectHeartbeat(wrappedCallback, interval, serviceName)
end

-- ========================================
-- BATCH OPERATIONS
-- ========================================

-- Connect multiple signals at once
function ConnectionUtils.ConnectBatch(service, signalCallbackPairs)
    local serviceName = service.Name or "BatchConnector"
    local connections = {}
    
    for i, pair in ipairs(signalCallbackPairs) do
        local signal = pair[1] or pair.signal
        local callback = pair[2] or pair.callback
        local connectionType = pair[3] or pair.type or "Batch"
        local connectionName = pair[4] or pair.name or ("Batch_" .. i)
        
        local connection = ConnectionUtils.Connect(signal, callback, serviceName, connectionName, connectionType)
        connections[connectionName] = connection
    end
    
    return connections
end

-- Setup multiple remote events with error handling
function ConnectionUtils.SetupRemoteEventsBatch(service, eventDefinitions)
    local serviceName = service.Name or "RemoteEventBatch"
    local connections = {}
    
    for eventName, definition in pairs(eventDefinitions) do
        local remoteEvent = ReplicatedStorage.Shared.modules.RemoteEvents[eventName]
        if remoteEvent then
            local callback = definition.callback
            local validation = definition.validation
            local errorHandler = definition.errorHandler
            
            local wrappedCallback = function(player, ...)
                -- Validation
                if validation and not validation(player, ...) then
                    warn("Validation failed for " .. eventName .. " from " .. player.Name)
                    return
                end
                
                -- Execute callback with error handling
                local success, result = pcall(callback, player, ...)
                if not success then
                    if errorHandler then
                        errorHandler(player, result, ...)
                    else
                        warn("Error in " .. eventName .. ": " .. tostring(result))
                    end
                end
            end
            
            connections[eventName] = ConnectionManager:ConnectRemoteEvent(remoteEvent, wrappedCallback, serviceName)
        else
            warn("RemoteEvent not found: " .. eventName)
        end
    end
    
    return connections
end

-- ========================================
-- DEBUGGING AND DIAGNOSTICS
-- ========================================

-- Debug a service's connections
function ConnectionUtils.DebugServiceConnections(serviceName)
    print("🔍 DEBUG: Connections for " .. serviceName)
    print("=====================================")
    
    local registry = ConnectionManager:GetConnectionRegistry(serviceName)
    if not registry then
        print("❌ No connections found")
        return
    end
    
    for connectionName, connectionData in pairs(registry) do
        print(string.format("🔗 %s:", connectionName))
        print(string.format("   Type: %s", connectionData.type))
        print(string.format("   State: %s", connectionData.state))
        print(string.format("   Age: %.2fs", tick() - connectionData.timestamp))
        print(string.format("   Owner: %s", tostring(connectionData.owner)))
    end
end

-- Test connection patterns for performance
function ConnectionUtils.BenchmarkConnections(iterations)
    iterations = iterations or 1000
    print("🏃 Benchmarking connection patterns...")
    
    local testSignal = Instance.new("BindableEvent").Event
    local testCallback = function() end
    
    -- Standard connections
    local startTime = tick()
    local standardConnections = {}
    for i = 1, iterations do
        standardConnections[i] = testSignal:Connect(testCallback)
    end
    local standardTime = tick() - startTime
    
    -- Managed connections
    startTime = tick()
    local managedConnections = {}
    for i = 1, iterations do
        managedConnections[i] = ConnectionUtils.Connect(testSignal, testCallback, "Benchmark", "Test" .. i)
    end
    local managedTime = tick() - startTime
    
    -- Cleanup
    for _, connection in ipairs(standardConnections) do
        connection:Disconnect()
    end
    ConnectionManager:DisconnectAllForOwner("Benchmark")
    
    print(string.format("📊 Results for %d connections:", iterations))
    print(string.format("   Standard: %.3fs", standardTime))
    print(string.format("   Managed: %.3fs (%.1fx overhead)", managedTime, managedTime / standardTime))
end

-- ========================================
-- MIGRATION VALIDATOR
-- ========================================

-- Validate that a service has been properly migrated
function ConnectionUtils.ValidateMigration(serviceName)
    local issues = {}
    
    -- Check if service uses ConnectionManager
    local registry = ConnectionManager:GetConnectionRegistry(serviceName)
    if not registry then
        table.insert(issues, "Service not registered with ConnectionManager")
    else
        local connectionCount = 0
        for _ in pairs(registry) do
            connectionCount = connectionCount + 1
        end
        
        if connectionCount == 0 then
            table.insert(issues, "No connections registered (may be unused or not migrated)")
        end
    end
    
    -- Return validation results
    return {
        isValid = #issues == 0,
        issues = issues,
        connectionCount = registry and table.maxn(registry) or 0
    }
end

return ConnectionUtils
