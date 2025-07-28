-- DifficultyService.luau
-- Server-side service for managing game difficulty progression

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local Knit = require(ReplicatedStorage.Packages.Knit)
local SafeRequire = require(ReplicatedStorage.Shared.utils.SafeRequire)

-- Safe require for DifficultyManager
local DifficultyManager = SafeRequire.requireWithRetry(
    ReplicatedStorage.Shared.modules.DifficultyManager,
    3
)

local DifficultyService = Knit.CreateService {
    Name = "DifficultyService",
    Client = {
        DifficultyChanged = Knit.CreateSignal(),
        LevelUp = Knit.CreateSignal(),
        SpikeActivated = Knit.CreateSignal()
    }
}

-- Player difficulty managers
local playerDifficulties = {}
local activeGames = {}

-- Global difficulty settings
local globalDifficultyConfig = nil

function DifficultyService:KnitStart()
    print("🎚️ DifficultyService starting...")
    
    if not DifficultyManager then
        warn("❌ Failed to load DifficultyManager module - service disabled")
        return
    end
    
    -- Setup player management
    self:SetupPlayerManagement()
    
    -- Load default configuration
    self:LoadGlobalConfiguration()
    
    print("✅ DifficultyService started!")
end

function DifficultyService:KnitInit()
    -- Initialize service
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

function DifficultyService:LoadGlobalConfiguration()
    -- Load default difficulty configuration
    globalDifficultyConfig = DifficultyManager.GetPresetConfigs().normal
    
    print("🎚️ Loaded global difficulty configuration")
end

function DifficultyService:InitializePlayerDifficulty(player)
    if playerDifficulties[player.UserId] then
        return -- Already initialized
    end
    
    local difficultyManager = DifficultyManager.new(globalDifficultyConfig)
    
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
    
    -- Fire client signal
    self.Client.LevelUp:Fire(player, data)
    
    -- Trigger other systems that might need to know about level changes
    -- (e.g., obstacle spawning, visual effects, achievements)
end

function DifficultyService:HandleDifficultyChange(player, data)
    -- Fire client signal for UI updates
    self.Client.DifficultyChanged:Fire(player, data)
    
    -- Update other systems based on difficulty changes
    self:UpdateSystemsForDifficulty(player, data)
end

function DifficultyService:HandleSpike(player, data)
    print("⚡ Difficulty spike activated for " .. player.Name .. " - Duration: " .. data.duration .. "s")
    
    -- Fire client signal
    self.Client.SpikeActivated:Fire(player, data)
end

function DifficultyService:UpdateSystemsForDifficulty(player, difficulty)
    -- Integration point for other game systems
    -- This is where the difficulty system plugs into the main game loop
    
    -- Update obstacle spawning (if ObstacleSpawnerService exists)
    if Knit.Services.ObstacleSpawnerService then
        Knit.Services.ObstacleSpawnerService:UpdateSpawnRate(player, difficulty.spawnRate)
        Knit.Services.ObstacleSpawnerService:UpdateComplexity(player, difficulty.complexity)
    end
    
    -- Update moving obstacles (if MovingObstacleService exists)
    if Knit.Services.MovingObstacleService then
        Knit.Services.MovingObstacleService:UpdateDifficulty(player, difficulty)
    end
    
    -- Update player speed (if PlayerMovementService exists)
    if Knit.Services.PlayerMovementService then
        Knit.Services.PlayerMovementService:UpdateSpeed(player, difficulty.speed)
    end
    
    -- Update game environment (if EnvironmentService exists)
    if Knit.Services.EnvironmentService then
        Knit.Services.EnvironmentService:UpdateDifficulty(player, difficulty)
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
