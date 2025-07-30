-- StateManager.luau
-- Client-side state management system for data synchronization
-- Handles client state, server sync, and conflict resolution

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local SafeRequire = require(ReplicatedStorage.Shared.utils.SafeRequire)
local RemoteEvents = SafeRequire.require(ReplicatedStorage.Shared.RemoteEvents)
local ServiceArchitecture = SafeRequire.require(ReplicatedStorage.Shared.core.ServiceArchitecture)

local StateManager = {}
StateManager.__index = StateManager

-- Implement IStateManager interface
setmetatable(StateManager, {__index = ServiceArchitecture.IStateManager})

local Player = Players.LocalPlayer

-- ========================================
-- STATE MANAGEMENT CONFIGURATION
-- ========================================

local SYNC_CONFIG = {
    syncInterval = 5, -- seconds
    maxPendingChanges = 50,
    conflictResolutionTimeout = 10,
    optimisticUpdates = true,
    batchUpdates = true,
    maxBatchSize = 10
}

local STATE_PRIORITIES = {
    HIGH = 1,    -- Critical data (coins, level)
    MEDIUM = 2,  -- Important data (upgrades, settings)
    LOW = 3      -- Nice-to-have data (cosmetics, preferences)
}

-- ========================================
-- CORE STATE MANAGER
-- ========================================

function StateManager.new()
    local self = setmetatable({}, StateManager)
    
    -- Client state storage
    self.localState = {}
    self.serverState = {}
    self.pendingChanges = {}
    self.conflictQueue = {}
    
    -- Sync management
    self.lastSyncTime = 0
    self.syncInProgress = false
    self.changeListeners = {}
    self.stateVersion = 0
    self.serverVersion = 0
    
    -- Performance tracking
    self.stats = {
        syncs = 0,
        conflicts = 0,
        optimisticUpdates = 0,
        rollbacks = 0,
        networkErrors = 0
    }
    
    -- Initialize state sync
    self:InitializeSync()
    
    print("🎯 StateManager initialized for client-side data synchronization")
    return self
end

-- ========================================
-- STATE INITIALIZATION
-- ========================================

function StateManager:InitializeSync()
    -- Request initial state from server
    local success, initialData = pcall(function()
        return RemoteEvents.GetPlayerData:InvokeServer()
    end)
    
    if success and initialData then
        self:SetServerState(initialData.data, initialData.version)
        self:SetLocalState(initialData.data)
        self.serverVersion = initialData.version
        self.stateVersion = initialData.version
        
        print("🔄 Initial state synchronized from server (version " .. initialData.version .. ")")
    else
        warn("⚠️ Failed to initialize state from server: " .. tostring(initialData))
        self:SetDefaultState()
    end
    
    -- Set up periodic sync
    self:StartPeriodicSync()
    
    -- Set up remote event listeners
    self:SetupRemoteListeners()
end

function StateManager:SetDefaultState()
    local defaultState = {
        coins = 0,
        level = 1,
        experience = 0,
        highScore = 0,
        upgrades = {},
        cosmetics = {
            equipped = {},
            owned = {}
        },
        settings = {
            music = true,
            sfx = true,
            graphics = "Medium"
        },
        achievements = {},
        quests = {
            active = {},
            completed = {}
        },
        pets = {
            active = nil,
            owned = {}
        },
        buffs = {},
        lastPlayed = os.time()
    }
    
    self:SetLocalState(defaultState)
    self:SetServerState(defaultState, 0)
end

-- ========================================
-- STATE ACCESS AND MUTATION
-- ========================================

function StateManager:GetState(path)
    if not path then
        return self.localState
    end
    
    local current = self.localState
    local keys = string.split(path, ".")
    
    for _, key in ipairs(keys) do
        if type(current) == "table" and current[key] ~= nil then
            current = current[key]
        else
            return nil
        end
    end
    
    return current
end

function StateManager:SetState(path, value, priority)
    priority = priority or STATE_PRIORITIES.MEDIUM
    
    -- Validate the change
    local validationResult = self:ValidateStateChange(path, value)
    if not validationResult.isValid then
        warn("❌ Invalid state change for " .. path .. ": " .. table.concat(validationResult.errors, ", "))
        return false
    end
    
    -- Apply optimistic update locally
    if SYNC_CONFIG.optimisticUpdates then
        local oldValue = self:GetState(path)
        self:ApplyLocalChange(path, value)
        
        self.stats.optimisticUpdates = self.stats.optimisticUpdates + 1
        
        -- Notify listeners of optimistic change
        self:NotifyListeners(path, value, oldValue, "optimistic")
    end
    
    -- Queue change for server sync
    self:QueuePendingChange(path, value, priority)
    
    -- Trigger immediate sync for high priority changes
    if priority == STATE_PRIORITIES.HIGH then
        self:SyncToServer()
    end
    
    return true
end

function StateManager:IncrementState(path, amount, priority)
    local currentValue = self:GetState(path)
    if type(currentValue) ~= "number" then
        warn("❌ Cannot increment non-numeric state: " .. path)
        return false
    end
    
    return self:SetState(path, currentValue + amount, priority)
end

function StateManager:ToggleState(path, priority)
    local currentValue = self:GetState(path)
    if type(currentValue) ~= "boolean" then
        warn("❌ Cannot toggle non-boolean state: " .. path)
        return false
    end
    
    return self:SetState(path, not currentValue, priority)
end

-- ========================================
-- LOCAL STATE MANAGEMENT
-- ========================================

function StateManager:SetLocalState(newState)
    self.localState = self:DeepCopy(newState)
    self.stateVersion = self.stateVersion + 1
end

function StateManager:SetServerState(newState, version)
    self.serverState = self:DeepCopy(newState)
    self.serverVersion = version or self.serverVersion
end

function StateManager:ApplyLocalChange(path, value)
    local keys = string.split(path, ".")
    local current = self.localState
    
    -- Navigate to the parent of the target key
    for i = 1, #keys - 1 do
        local key = keys[i]
        if type(current[key]) ~= "table" then
            current[key] = {}
        end
        current = current[key]
    end
    
    -- Set the value
    local finalKey = keys[#keys]
    current[finalKey] = value
    
    self.stateVersion = self.stateVersion + 1
end

function StateManager:RevertLocalChange(path)
    -- Revert to server state value
    local serverValue = self:GetServerStateValue(path)
    if serverValue ~= nil then
        self:ApplyLocalChange(path, serverValue)
        
        self.stats.rollbacks = self.stats.rollbacks + 1
        print("🔄 Reverted local change for " .. path .. " to server value")
    end
end

function StateManager:GetServerStateValue(path)
    local current = self.serverState
    local keys = string.split(path, ".")
    
    for _, key in ipairs(keys) do
        if type(current) == "table" and current[key] ~= nil then
            current = current[key]
        else
            return nil
        end
    end
    
    return current
end

-- ========================================
-- PENDING CHANGES MANAGEMENT
-- ========================================

function StateManager:QueuePendingChange(path, value, priority)
    -- Check if we already have a pending change for this path
    for i, change in ipairs(self.pendingChanges) do
        if change.path == path then
            -- Update existing change
            change.value = value
            change.priority = math.min(change.priority, priority)
            change.timestamp = tick()
            return
        end
    end
    
    -- Add new pending change
    local change = {
        path = path,
        value = value,
        priority = priority,
        timestamp = tick(),
        changeId = self:GenerateChangeId()
    }
    
    table.insert(self.pendingChanges, change)
    
    -- Sort by priority
    table.sort(self.pendingChanges, function(a, b)
        return a.priority < b.priority
    end)
    
    -- Limit queue size
    if #self.pendingChanges > SYNC_CONFIG.maxPendingChanges then
        -- Remove lowest priority changes
        for i = #self.pendingChanges, SYNC_CONFIG.maxPendingChanges + 1, -1 do
            table.remove(self.pendingChanges, i)
        end
        warn("⚠️ Pending changes queue overflow - removed low priority changes")
    end
end

function StateManager:GetPendingChangesBatch()
    local batch = {}
    local batchSize = math.min(#self.pendingChanges, SYNC_CONFIG.maxBatchSize)
    
    for i = 1, batchSize do
        table.insert(batch, self.pendingChanges[i])
    end
    
    return batch
end

function StateManager:ClearPendingChanges(completedChanges)
    for _, completedChange in ipairs(completedChanges) do
        for i = #self.pendingChanges, 1, -1 do
            if self.pendingChanges[i].changeId == completedChange.changeId then
                table.remove(self.pendingChanges, i)
                break
            end
        end
    end
end

-- ========================================
-- SERVER SYNCHRONIZATION
-- ========================================

function StateManager:StartPeriodicSync()
    RunService.Heartbeat:Connect(function()
        if tick() - self.lastSyncTime >= SYNC_CONFIG.syncInterval then
            if #self.pendingChanges > 0 and not self.syncInProgress then
                self:SyncToServer()
            end
        end
    end)
end

function StateManager:SyncToServer()
    if self.syncInProgress then
        return false
    end
    
    if #self.pendingChanges == 0 then
        return true
    end
    
    self.syncInProgress = true
    
    local batch = self:GetPendingChangesBatch()
    if #batch == 0 then
        self.syncInProgress = false
        return true
    end
    
    -- Convert batch to update format
    local updates = {}
    for _, change in ipairs(batch) do
        updates[change.path] = change.value
    end
    
    local syncData = {
        updates = updates,
        clientVersion = self.stateVersion,
        expectedServerVersion = self.serverVersion,
        timestamp = tick()
    }
    
    print("📤 Syncing " .. #batch .. " changes to server...")
    
    local success, result = pcall(function()
        return RemoteEvents.UpdatePlayerData:InvokeServer(syncData)
    end)
    
    self.syncInProgress = false
    self.lastSyncTime = tick()
    self.stats.syncs = self.stats.syncs + 1
    
    if success and result then
        if result.success then
            -- Clear completed changes
            self:ClearPendingChanges(batch)
            
            -- Update server state and version
            self:SetServerState(result.newData, result.newVersion)
            self.serverVersion = result.newVersion
            
            print("✅ Sync completed successfully (server version " .. result.newVersion .. ")")
            return true
            
        elseif result.conflict then
            -- Handle version conflict
            self:HandleVersionConflict(result)
            return false
            
        else
            warn("⚠️ Server sync failed: " .. (result.error or "Unknown error"))
            return false
        end
    else
        self.stats.networkErrors = self.stats.networkErrors + 1
        warn("❌ Network error during sync: " .. tostring(result))
        return false
    end
end

function StateManager:HandleVersionConflict(conflictData)
    self.stats.conflicts = self.stats.conflicts + 1
    
    print("⚠️ Version conflict detected - resolving...")
    
    -- Add to conflict queue for resolution
    table.insert(self.conflictQueue, {
        conflictData = conflictData,
        timestamp = tick(),
        attempts = 0
    })
    
    -- Attempt automatic resolution
    self:ResolveVersionConflict(conflictData)
end

function StateManager:ResolveVersionConflict(conflictData)
    local serverData = conflictData.serverData
    local clientUpdates = conflictData.clientUpdates
    
    -- Update server state to latest
    self:SetServerState(serverData.data, serverData.version)
    self.serverVersion = serverData.version
    
    -- For each client update, decide whether to keep or revert
    for path, clientValue in pairs(clientUpdates) do
        local serverValue = self:GetServerStateValue(path)
        
        if self:ShouldKeepClientValue(path, clientValue, serverValue) then
            -- Keep client value and re-queue for sync
            self:QueuePendingChange(path, clientValue, STATE_PRIORITIES.HIGH)
        else
            -- Revert to server value
            self:RevertLocalChange(path)
            
            -- Notify listeners of conflict resolution
            self:NotifyListeners(path, serverValue, clientValue, "conflict_resolved")
        end
    end
    
    print("🔄 Version conflict resolved - " .. 
          (#self.pendingChanges) .. " changes re-queued for sync")
end

function StateManager:ShouldKeepClientValue(path, clientValue, serverValue)
    -- Priority-based conflict resolution
    local pathPriority = self:GetPathPriority(path)
    
    if pathPriority == STATE_PRIORITIES.HIGH then
        -- Always keep client values for high priority paths (coins, level)
        return true
    elseif pathPriority == STATE_PRIORITIES.LOW then
        -- Always prefer server values for low priority paths
        return false
    else
        -- For medium priority, use type-specific resolution
        if type(clientValue) == "number" and type(serverValue) == "number" then
            -- Keep the larger value for numeric data
            return clientValue > serverValue
        else
            -- For other types, prefer client value if it's more recent
            return true
        end
    end
end

function StateManager:GetPathPriority(path)
    local highPriorityPaths = {"coins", "level", "experience", "highScore"}
    local lowPriorityPaths = {"cosmetics", "settings"}
    
    for _, highPath in ipairs(highPriorityPaths) do
        if string.find(path, highPath) then
            return STATE_PRIORITIES.HIGH
        end
    end
    
    for _, lowPath in ipairs(lowPriorityPaths) do
        if string.find(path, lowPath) then
            return STATE_PRIORITIES.LOW
        end
    end
    
    return STATE_PRIORITIES.MEDIUM
end

-- ========================================
-- REMOTE EVENT LISTENERS
-- ========================================

function StateManager:SetupRemoteListeners()
    -- Listen for server-initiated state updates
    RemoteEvents.ServerStateUpdate.OnClientEvent:Connect(function(updateData)
        self:HandleServerStateUpdate(updateData)
    end)
    
    -- Listen for state invalidation
    RemoteEvents.InvalidateClientState.OnClientEvent:Connect(function(reason)
        self:HandleStateInvalidation(reason)
    end)
end

function StateManager:HandleServerStateUpdate(updateData)
    print("📥 Received server state update (version " .. updateData.version .. ")")
    
    -- Update server state
    self:SetServerState(updateData.data, updateData.version)
    self.serverVersion = updateData.version
    
    -- Merge with local state if no conflicts
    local hasConflicts = false
    for path, serverValue in pairs(updateData.changes or {}) do
        local localValue = self:GetState(path)
        local hasPendingChange = self:HasPendingChange(path)
        
        if hasPendingChange and localValue ~= serverValue then
            hasConflicts = true
            print("⚠️ Conflict detected for " .. path .. " during server update")
        else
            -- Apply server change locally
            self:ApplyLocalChange(path, serverValue)
            
            -- Notify listeners
            self:NotifyListeners(path, serverValue, localValue, "server_update")
        end
    end
    
    if hasConflicts then
        -- Queue for manual conflict resolution
        self:HandleVersionConflict({
            serverData = updateData,
            clientUpdates = self:GetPendingChangesAsUpdates()
        })
    end
end

function StateManager:HandleStateInvalidation(reason)
    warn("⚠️ Client state invalidated by server: " .. reason)
    
    -- Clear all local state and re-sync
    self.pendingChanges = {}
    self.conflictQueue = {}
    
    -- Request fresh state from server
    self:InitializeSync()
end

function StateManager:HasPendingChange(path)
    for _, change in ipairs(self.pendingChanges) do
        if change.path == path then
            return true
        end
    end
    return false
end

function StateManager:GetPendingChangesAsUpdates()
    local updates = {}
    for _, change in ipairs(self.pendingChanges) do
        updates[change.path] = change.value
    end
    return updates
end

-- ========================================
-- CHANGE LISTENERS
-- ========================================

function StateManager:AddChangeListener(path, callback)
    if not self.changeListeners[path] then
        self.changeListeners[path] = {}
    end
    
    local listenerId = self:GenerateListenerId()
    self.changeListeners[path][listenerId] = callback
    
    return listenerId
end

function StateManager:RemoveChangeListener(path, listenerId)
    if self.changeListeners[path] then
        self.changeListeners[path][listenerId] = nil
    end
end

function StateManager:NotifyListeners(path, newValue, oldValue, changeType)
    -- Notify specific path listeners
    if self.changeListeners[path] then
        for _, callback in pairs(self.changeListeners[path]) do
            pcall(callback, newValue, oldValue, changeType)
        end
    end
    
    -- Notify wildcard listeners
    if self.changeListeners["*"] then
        for _, callback in pairs(self.changeListeners["*"]) do
            pcall(callback, path, newValue, oldValue, changeType)
        end
    end
end

-- ========================================
-- VALIDATION
-- ========================================

function StateManager:ValidateStateChange(path, value)
    local result = {
        isValid = true,
        errors = {},
        warnings = {}
    }
    
    -- Type validation based on path
    local expectedType = self:GetExpectedType(path)
    if expectedType and type(value) ~= expectedType then
        table.insert(result.errors, "Expected " .. expectedType .. " for " .. path .. ", got " .. type(value))
        result.isValid = false
    end
    
    -- Range validation for numeric values
    if type(value) == "number" then
        local range = self:GetValidRange(path)
        if range and (value < range.min or value > range.max) then
            table.insert(result.errors, "Value " .. value .. " out of range [" .. range.min .. ", " .. range.max .. "] for " .. path)
            result.isValid = false
        end
    end
    
    return result
end

function StateManager:GetExpectedType(path)
    local typeMap = {
        ["coins"] = "number",
        ["level"] = "number",
        ["experience"] = "number",
        ["highScore"] = "number",
        ["settings.music"] = "boolean",
        ["settings.sfx"] = "boolean",
        ["settings.graphics"] = "string"
    }
    
    return typeMap[path]
end

function StateManager:GetValidRange(path)
    local rangeMap = {
        ["coins"] = {min = 0, max = 999999999},
        ["level"] = {min = 1, max = 1000},
        ["experience"] = {min = 0, max = 999999999},
        ["highScore"] = {min = 0, max = 999999999}
    }
    
    return rangeMap[path]
end

-- ========================================
-- UTILITY FUNCTIONS
-- ========================================

function StateManager:DeepCopy(original)
    if type(original) ~= "table" then
        return original
    end
    
    local copy = {}
    for key, value in pairs(original) do
        copy[key] = self:DeepCopy(value)
    end
    
    return copy
end

function StateManager:GenerateChangeId()
    return "change_" .. tick() .. "_" .. math.random(1000, 9999)
end

function StateManager:GenerateListenerId()
    return "listener_" .. tick() .. "_" .. math.random(1000, 9999)
end

function StateManager:GetStatistics()
    return {
        stats = self.stats,
        localVersion = self.stateVersion,
        serverVersion = self.serverVersion,
        pendingChanges = #self.pendingChanges,
        conflicts = #self.conflictQueue,
        listeners = self:CountListeners(),
        syncInProgress = self.syncInProgress,
        lastSyncTime = self.lastSyncTime
    }
end

function StateManager:CountListeners()
    local count = 0
    for _, pathListeners in pairs(self.changeListeners) do
        for _ in pairs(pathListeners) do
            count = count + 1
        end
    end
    return count
end

return StateManager
