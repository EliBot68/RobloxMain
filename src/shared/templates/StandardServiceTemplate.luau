-- StandardServiceTemplate.luau
-- Template for all standardized services in Color Rush
-- Based on ServiceBase with consistent architecture patterns

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local SafeRequire = require(ReplicatedStorage.Shared.utils.SafeRequire)
local ServiceBase = SafeRequire.require(ReplicatedStorage.Shared.utils.ServiceBase, {})

-- Template Service Class
local StandardService = ServiceBase.new("StandardService", {
    Priority = 50,
    Dependencies = {}
})

-- STANDARDIZED SERVICE STRUCTURE
-- All services should follow this pattern:

-- 1. Dependencies Declaration
StandardService.Dependencies = {
    { path = ReplicatedStorage.Shared.modules.RemoteEvents, name = "RemoteEvents", optional = false },
    { path = ReplicatedStorage.Shared.modules.Analytics, name = "Analytics", optional = true },
    -- Add other dependencies as needed
}

-- 2. Service Configuration
local SERVICE_CONFIG = {
    enableLogging = true,
    autoStart = true,
    validateDependencies = true,
    retryOnFailure = true
}

-- 3. Local Variables (private to service)
local connections = {}
local remoteEvents = {}
local players = {}

-- 4. Helper Functions (private)
local function setupRemoteEvents()
    local RemoteEvents = SafeRequire.require(ReplicatedStorage.Shared.modules.RemoteEvents, {})
    
    if RemoteEvents and RemoteEvents.GetRemoteEvent then
        -- Example remote events setup
        remoteEvents.ServiceAction = RemoteEvents:GetRemoteEvent("ServiceAction")
        remoteEvents.ServiceUpdate = RemoteEvents:GetRemoteEvent("ServiceUpdate")
    end
end

local function validatePlayerData(player)
    -- Standardized player data validation
    if not player or not player.Parent then
        return false
    end
    
    return true
end

-- 5. Required Service Methods (must be implemented)

-- Initialize service
function StandardService:OnInitialize()
    self:LogInfo("Initializing StandardService...")
    
    -- Setup remote events
    setupRemoteEvents()
    
    -- Initialize data structures
    players = {}
    
    self:LogInfo("StandardService initialized successfully")
end

-- Start service
function StandardService:OnStart()
    self:LogInfo("Starting StandardService...")
    
    -- Connect to player events
    connections.PlayerAdded = Players.PlayerAdded:Connect(function(player)
        self:OnPlayerAdded(player)
    end)
    
    connections.PlayerRemoving = Players.PlayerRemoving:Connect(function(player)
        self:OnPlayerRemoving(player)
    end)
    
    -- Connect existing players
    for _, player in ipairs(Players:GetPlayers()) do
        self:OnPlayerAdded(player)
    end
    
    self:LogInfo("StandardService started successfully")
end

-- Stop service
function StandardService:OnStop()
    self:LogInfo("Stopping StandardService...")
    
    -- Disconnect all connections
    for name, connection in pairs(connections) do
        if connection and connection.Disconnect then
            connection:Disconnect()
        end
    end
    connections = {}
    
    -- Clear player data
    players = {}
    
    self:LogInfo("StandardService stopped successfully")
end

-- 6. Player Event Handlers (standard pattern)

function StandardService:OnPlayerAdded(player)
    if not validatePlayerData(player) then
        self:LogWarn("Invalid player data for", player.Name)
        return
    end
    
    -- Initialize player data
    players[player.UserId] = {
        player = player,
        joinTime = tick(),
        data = {}
    }
    
    self:LogInfo("Player added:", player.Name)
    
    -- Track analytics if available
    local Analytics = SafeRequire.require(ReplicatedStorage.Shared.modules.Analytics, nil)
    if Analytics and Analytics.TrackEvent then
        Analytics:TrackEvent("PlayerJoined", {
            userId = player.UserId,
            service = self.Name
        })
    end
end

function StandardService:OnPlayerRemoving(player)
    if players[player.UserId] then
        -- Cleanup player data
        local playerData = players[player.UserId]
        
        -- Save any persistent data here
        
        players[player.UserId] = nil
        self:LogInfo("Player removed:", player.Name)
        
        -- Track analytics
        local Analytics = SafeRequire.require(ReplicatedStorage.Shared.modules.Analytics, nil)
        if Analytics and Analytics.TrackEvent then
            Analytics:TrackEvent("PlayerLeft", {
                userId = player.UserId,
                service = self.Name,
                sessionTime = tick() - (playerData.joinTime or 0)
            })
        end
    end
end

-- 7. Public API Methods (service-specific functionality)

function StandardService:DoServiceAction(player, actionData)
    if not validatePlayerData(player) then
        return false, "Invalid player"
    end
    
    if not players[player.UserId] then
        self:LogWarn("Player not found in service:", player.Name)
        return false, "Player not registered"
    end
    
    -- Implement service-specific logic here
    self:LogInfo("Service action performed for", player.Name)
    
    return true, "Action completed"
end

function StandardService:GetPlayerData(player)
    if not player or not players[player.UserId] then
        return nil
    end
    
    return players[player.UserId].data
end

function StandardService:UpdatePlayerData(player, newData)
    if not player or not players[player.UserId] then
        return false
    end
    
    players[player.UserId].data = newData
    return true
end

-- 8. Validation Methods (ensure service integrity)

function StandardService:ValidateService()
    local issues = {}
    
    -- Check remote events
    if not remoteEvents.ServiceAction then
        table.insert(issues, "ServiceAction remote event not found")
    end
    
    -- Check dependencies
    if not SafeRequire.moduleExists(ReplicatedStorage.Shared.modules.RemoteEvents) then
        table.insert(issues, "RemoteEvents module not available")
    end
    
    -- Check player data integrity
    for userId, playerData in pairs(players) do
        if not playerData.player or not playerData.player.Parent then
            table.insert(issues, string.format("Invalid player data for user %d", userId))
        end
    end
    
    return #issues == 0, issues
end

-- 9. Utility Methods (common patterns)

function StandardService:GetServiceStats()
    return {
        name = self.Name,
        playerCount = self:CountTable(players),
        connectionCount = self:CountTable(connections),
        uptime = self.IsRunning and (tick() - (self.Metrics.StartTime or 0)) or 0,
        lastValidation = self.LastValidation or 0
    }
end

function StandardService:CountTable(t)
    local count = 0
    for _ in pairs(t) do
        count = count + 1
    end
    return count
end

-- 10. Service Health Check

function StandardService:HealthCheck()
    local health = {
        status = "healthy",
        issues = {},
        metrics = self:GetServiceStats()
    }
    
    -- Check if service is running
    if not self.IsRunning then
        health.status = "stopped"
        table.insert(health.issues, "Service is not running")
    end
    
    -- Validate service integrity
    local isValid, validationIssues = self:ValidateService()
    if not isValid then
        health.status = "unhealthy"
        for _, issue in ipairs(validationIssues) do
            table.insert(health.issues, issue)
        end
    end
    
    -- Check memory usage
    if health.metrics.playerCount > 100 then
        table.insert(health.issues, "High player count may impact performance")
    end
    
    return health
end

return StandardService
