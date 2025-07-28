-- DifficultyService.luau
-- Server-side service for managing game difficulty progression (Standardized Enhanced Service)

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local SafeRequire = require(ReplicatedStorage.Shared.utils.SafeRequire)
local ServiceBase = SafeRequire.require(ReplicatedStorage.Shared.utils.ServiceBase)

local DifficultyService = ServiceBase.new("DifficultyService", {
    enableDetailedLogging = true,
    retryFailedRequires = true,
    maxRetryAttempts = 3,
    validateOnStart = true,
    autoStart = false
})

-- Define dependencies
DifficultyService.Dependencies = {
    { path = ReplicatedStorage.Shared.modules.DifficultyManager, name = "DifficultyManager", optional = false },
}

-- Player difficulty managers
local playerDifficulties = {}
local activeGames = {}

-- Global difficulty settings
local globalDifficultyConfig = nil

-- Client communication events (replacing Knit signals)
DifficultyService.RemoteEvents = {
    DifficultyChanged = nil,
    LevelUp = nil,
    SpikeActivated = nil
}

--[[
    Initializes the DifficultyService by loading the DifficultyManager module
    and setting up global difficulty configuration.
    
    @return {boolean} - True if initialization was successful
]]
function DifficultyService:OnInit()
    if not self.DifficultyManager then
        warn("❌ Failed to load DifficultyManager module - service disabled")
        return false
    end
    
    -- Load default configuration
    self:LoadGlobalConfiguration()
    
    return true
end

--[[
    Starts the DifficultyService by setting up player management systems
    and establishing connections.
    
    @return {boolean} - True if service started successfully
]]
function DifficultyService:OnStart()
    -- Setup player management
    self:SetupPlayerManagement()
    
    print("✅ DifficultyService started!")
    return true
end

-- Setup remote events
function DifficultyService:SetupRemoteEvents()
    local RemoteEvents = self:SafeRequire(ReplicatedStorage.Shared.modules.RemoteEvents, "RemoteEvents", true)
    
    if RemoteEvents then
        self.RemoteEvents.DifficultyChanged = RemoteEvents:GetRemoteEvent("DifficultyChanged")
        self.RemoteEvents.LevelUp = RemoteEvents:GetRemoteEvent("LevelUp")
        self.RemoteEvents.SpikeActivated = RemoteEvents:GetRemoteEvent("SpikeActivated")
    end
end

-- Setup connections
function DifficultyService:SetupConnections()
    -- Setup any additional connections here
end

function DifficultyService:SetupPlayerManagement()
    -- Handle player joining
    Players.PlayerAdded:Connect(function(player)
        self:InitializePlayerDifficulty(player)
    end)
    
    -- Handle player leaving
    Players.PlayerRemoving:Connect(function(player)
        self:CleanupPlayerDifficulty(player)
    end)
    
    -- Initialize existing players
    for _, player in pairs(Players:GetPlayers()) do
        self:InitializePlayerDifficulty(player)
    end
end

--[[
    Loads the global difficulty configuration from the DifficultyManager presets.
    This sets the baseline difficulty settings for all players.
    
    @return {void}
]]
function DifficultyService:LoadGlobalConfiguration()
    -- Load default difficulty configuration
    globalDifficultyConfig = self.DifficultyManager.GetPresetConfigs().normal
    
    print("🎚️ Loaded global difficulty configuration")
end

--[[
    Initializes difficulty management for a specific player. Creates a new
    DifficultyManager instance and sets up event handlers.
    
    @param player {Player} - The player to initialize difficulty for
    @return {void}
]]
function DifficultyService:InitializePlayerDifficulty(player)
    if playerDifficulties[player.UserId] then
        return -- Already initialized
    end
    
    local difficultyManager = self.DifficultyManager.new(globalDifficultyConfig)
    
    -- Setup event handlers
    difficultyManager:OnEvent("onLevelUp", function(data)
        self:HandleLevelUp(player, data)
    end)
    
    difficultyManager:OnEvent("onDifficultyChange", function(data)
        self:HandleDifficultyChange(player, data)
    end)
    
    difficultyManager:OnEvent("onSpike", function(data)
        self:HandleSpike(player, data)
    end)
    
    playerDifficulties[player.UserId] = difficultyManager
    
    print("🎚️ Initialized difficulty manager for player: " .. player.Name)
end

function DifficultyService:CleanupPlayerDifficulty(player)
    local difficultyManager = playerDifficulties[player.UserId]
    if difficultyManager then
        difficultyManager:Destroy()
        playerDifficulties[player.UserId] = nil
    end
    
    if activeGames[player.UserId] then
        activeGames[player.UserId] = nil
    end
    
    print("🧹 Cleaned up difficulty manager for player: " .. player.Name)
end

function DifficultyService:StartGame(player, gameConfig)
    local difficultyManager = playerDifficulties[player.UserId]
    if not difficultyManager then
        warn("❌ No difficulty manager found for player: " .. player.Name)
        return false
    end
    
    -- Apply game-specific configuration if provided
    if gameConfig and gameConfig.difficultyConfig then
        difficultyManager.config = gameConfig.difficultyConfig
    end
    
    -- Reset and start difficulty progression
    difficultyManager:ResetDifficulty()
    difficultyManager:Start()
    
    -- Track active game
    activeGames[player.UserId] = {
        startTime = tick(),
        gameConfig = gameConfig,
        distanceTraveled = 0,
        isActive = true
    }
    
    print("▶️ Started difficulty progression for player: " .. player.Name)
    return true
end

function DifficultyService:StopGame(player)
    local difficultyManager = playerDifficulties[player.UserId]
    if difficultyManager then
        difficultyManager:Stop()
    end
    
    if activeGames[player.UserId] then
        activeGames[player.UserId].isActive = false
    end
    
    print("⏹️ Stopped difficulty progression for player: " .. player.Name)
end

function DifficultyService:UpdatePlayerDistance(player, distanceTraveled)
    local difficultyManager = playerDifficulties[player.UserId]
    if not difficultyManager then
        return
    end
    
    difficultyManager:AddDistance(distanceTraveled)
    
    if activeGames[player.UserId] then
        activeGames[player.UserId].distanceTraveled = activeGames[player.UserId].distanceTraveled + distanceTraveled
    end
end

function DifficultyService:RecordPlayerDeath(player)
    local difficultyManager = playerDifficulties[player.UserId]
    if difficultyManager then
        difficultyManager:RecordPlayerDeath()
    end
end

function DifficultyService:RecordPlayerSuccess(player, completionTime)
    local difficultyManager = playerDifficulties[player.UserId]
    if difficultyManager then
        difficultyManager:RecordPlayerSuccess(completionTime)
    end
end

function DifficultyService:GetPlayerDifficulty(player)
    local difficultyManager = playerDifficulties[player.UserId]
    if difficultyManager then
        return difficultyManager:GetCurrentDifficulty()
    end
    return nil
end

function DifficultyService:SetPlayerDifficultyLevel(player, level)
    local difficultyManager = playerDifficulties[player.UserId]
    if difficultyManager then
        difficultyManager:SetDifficultyLevel(level)
        return true
    end
    return false
end

function DifficultyService:GetSpeedMultiplier(player)
    local difficulty = self:GetPlayerDifficulty(player)
    return difficulty and (difficulty.speed / globalDifficultyConfig.baseSpeed) or 1.0
end

function DifficultyService:GetSpawnRateMultiplier(player)
    local difficulty = self:GetPlayerDifficulty(player)
    return difficulty and (difficulty.spawnRate / globalDifficultyConfig.baseSpawnRate) or 1.0
end

function DifficultyService:GetComplexityLevel(player)
    local difficulty = self:GetPlayerDifficulty(player)
    return difficulty and difficulty.complexity or 1.0
end

-- Event handlers
function DifficultyService:HandleLevelUp(player, data)
    print("🎚️ " .. player.Name .. " leveled up: " .. data.oldLevel .. " → " .. data.newLevel .. " (" .. data.levelName .. ")")
    
    -- Fire client event
    if self.RemoteEvents.LevelUp then
        self.RemoteEvents.LevelUp:FireClient(player, data)
    end
    
    -- Trigger other systems that might need to know about level changes
    -- (e.g., obstacle spawning, visual effects, achievements)
end

function DifficultyService:HandleDifficultyChange(player, data)
    -- Fire client event for UI updates
    if self.RemoteEvents.DifficultyChanged then
        self.RemoteEvents.DifficultyChanged:FireClient(player, data)
    end
    
    -- Update other systems based on difficulty changes
    self:UpdateSystemsForDifficulty(player, data)
end

function DifficultyService:HandleSpike(player, data)
    print("⚡ Difficulty spike activated for " .. player.Name .. " - Duration: " .. data.duration .. "s")
    
    -- Fire client event
    if self.RemoteEvents.SpikeActivated then
        self.RemoteEvents.SpikeActivated:FireClient(player, data)
    end
end

function DifficultyService:UpdateSystemsForDifficulty(player, difficulty)
    -- Integration point for other game systems
    -- This is where the difficulty system plugs into the main game loop
    
    -- Update obstacle spawning (if available through ServiceRegistry)
    local ServiceRegistry = self:SafeRequire(ReplicatedStorage.Shared.utils.ServiceRegistry, "ServiceRegistry", true)
    if ServiceRegistry then
        local ObstacleSpawnerService = ServiceRegistry:GetService("ObstacleSpawnerService")
        if ObstacleSpawnerService and ObstacleSpawnerService.UpdateSpawnRate then
            ObstacleSpawnerService:UpdateSpawnRate(player, difficulty.spawnRate)
        end
        if ObstacleSpawnerService and ObstacleSpawnerService.UpdateComplexity then
            ObstacleSpawnerService:UpdateComplexity(player, difficulty.complexity)
        end
        
        -- Update moving obstacles
        local MovingObstacleService = ServiceRegistry:GetService("MovingObstacleService")
        if MovingObstacleService and MovingObstacleService.UpdateDifficulty then
            MovingObstacleService:UpdateDifficulty(player, difficulty)
        end
        
        -- Update player speed
        local PlayerMovementService = ServiceRegistry:GetService("PlayerMovementService")
        if PlayerMovementService and PlayerMovementService.UpdateSpeed then
            PlayerMovementService:UpdateSpeed(player, difficulty.speed)
        end
        
        -- Update game environment
        local EnvironmentService = ServiceRegistry:GetService("EnvironmentService")
        if EnvironmentService and EnvironmentService.UpdateDifficulty then
            EnvironmentService:UpdateDifficulty(player, difficulty)
        end
    end
    
    -- Update UI elements (through client signals)
    -- Client will handle UI updates via the DifficultyChanged signal
end

-- Configuration management
function DifficultyService:SetGlobalConfiguration(config)
    globalDifficultyConfig = config
    
    -- Update all active difficulty managers
    for userId, difficultyManager in pairs(playerDifficulties) do
        for key, value in pairs(config) do
            difficultyManager.config[key] = value
        end
    end
    
    print("🎚️ Updated global difficulty configuration")
end

function DifficultyService:GetGlobalConfiguration()
    return globalDifficultyConfig
end

function DifficultyService:LoadPresetConfiguration(presetName)
    local presets = DifficultyManager.GetPresetConfigs()
    if presets[presetName] then
        self:SetGlobalConfiguration(presets[presetName])
        return true
    end
    return false
end

-- Statistics and monitoring
function DifficultyService:GetActivePlayerCount()
    local count = 0
    for userId, gameData in pairs(activeGames) do
        if gameData.isActive then
            count = count + 1
        end
    end
    return count
end

function DifficultyService:GetPlayerStatistics(player)
    local difficultyManager = playerDifficulties[player.UserId]
    local gameData = activeGames[player.UserId]
    
    if not difficultyManager or not gameData then
        return nil
    end
    
    local difficulty = difficultyManager:GetCurrentDifficulty()
    
    return {
        difficulty = difficulty,
        gameTime = tick() - gameData.startTime,
        distanceTraveled = gameData.distanceTraveled,
        performance = difficultyManager.playerPerformance
    }
end

function DifficultyService:GetAllPlayerStatistics()
    local stats = {}
    
    for _, player in pairs(Players:GetPlayers()) do
        local playerStats = self:GetPlayerStatistics(player)
        if playerStats then
            stats[player.UserId] = playerStats
        end
    end
    
    return stats
end

-- Client-facing methods
function DifficultyService.Client:GetCurrentDifficulty(player)
    return self.Server:GetPlayerDifficulty(player)
end

function DifficultyService.Client:GetStatistics(player)
    return self.Server:GetPlayerStatistics(player)
end

function DifficultyService.Client:SetDifficultyLevel(player, level)
    -- Only allow in testing/debug mode
    if game:GetService("RunService"):IsStudio() then
        return self.Server:SetPlayerDifficultyLevel(player, level)
    end
    return false
end

return DifficultyService
