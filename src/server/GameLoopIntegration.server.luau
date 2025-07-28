-- GameLoopIntegration.server.luau
-- Main game loop integration showing how DifficultyService plugs into the game systems

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local SafeRequire = require(ReplicatedStorage.Shared.utils.SafeRequire)
local Knit = SafeRequire.require(ReplicatedStorage.Packages.Knit)

-- Wait for services to load
local function waitForServices()
    repeat
        wait(0.1)
    until Knit.Services.DifficultyService
    
    return {
        DifficultyService = Knit.Services.DifficultyService,
        MovingObstacleService = Knit.Services.MovingObstacleService, -- Optional
        -- Add other services as they become available
    }
end

local Services = waitForServices()

-- Game state management
local gameStates = {}
local gameLoopConnections = {}

-- Game configuration
local GAME_CONFIG = {
    -- Track configuration
    trackLength = 1000, -- studs
    trackWidth = 20,
    
    -- Base game settings (modified by difficulty)
    basePlayerSpeed = 16,
    baseObstacleSpawnRate = 0.8,
    
    -- Difficulty integration settings
    difficultyConfig = {
        timeBasedProgression = true,
        distanceBasedProgression = true,
        adaptiveDifficulty = true,
        baseSpeed = 16,
        maxSpeed = 50,
        baseSpawnRate = 0.8,
        maxSpawnRate = 3.0
    }
}

-- Initialize player game state
local function initializePlayerGameState(player)
    gameStates[player.UserId] = {
        isPlaying = false,
        startTime = 0,
        distanceTraveled = 0,
        currentSpeed = GAME_CONFIG.basePlayerSpeed,
        lastPositionUpdate = tick(),
        character = nil,
        humanoid = nil,
        
        -- Obstacle tracking
        obstaclesSpawned = 0,
        obstaclesPassed = 0,
        lastObstacleSpawn = 0,
        
        -- Performance tracking
        deaths = 0,
        completedRuns = 0,
        bestTime = math.huge,
        
        -- Difficulty integration
        lastDifficultyUpdate = 0,
        currentDifficulty = nil
    }
    
    print("🎮 Initialized game state for player: " .. player.Name)
end

-- Start game for player
local function startGame(player)
    local gameState = gameStates[player.UserId]
    if not gameState or gameState.isPlaying then
        return false
    end
    
    -- Reset game state
    gameState.isPlaying = true
    gameState.startTime = tick()
    gameState.distanceTraveled = 0
    gameState.obstaclesSpawned = 0
    gameState.obstaclesPassed = 0
    gameState.lastObstacleSpawn = 0
    gameState.lastPositionUpdate = tick()
    
    -- Get character and humanoid
    gameState.character = player.Character
    gameState.humanoid = gameState.character and gameState.character:FindFirstChild("Humanoid")
    
    if not gameState.character or not gameState.humanoid then
        warn("❌ Cannot start game - character not found for: " .. player.Name)
        gameState.isPlaying = false
        return false
    end
    
    -- Start difficulty progression
    local difficultyStarted = Services.DifficultyService:StartGame(player, {
        difficultyConfig = GAME_CONFIG.difficultyConfig
    })
    
    if not difficultyStarted then
        warn("❌ Failed to start difficulty progression for: " .. player.Name)
        gameState.isPlaying = false
        return false
    end
    
    -- Start game loop for this player
    startPlayerGameLoop(player)
    
    print("▶️ Started game for player: " .. player.Name)
    return true
end

-- Stop game for player
local function stopGame(player, reason)
    local gameState = gameStates[player.UserId]
    if not gameState or not gameState.isPlaying then
        return
    end
    
    gameState.isPlaying = false
    
    -- Stop difficulty progression
    Services.DifficultyService:StopGame(player)
    
    -- Stop game loop
    if gameLoopConnections[player.UserId] then
        gameLoopConnections[player.UserId]:Disconnect()
        gameLoopConnections[player.UserId] = nil
    end
    
    -- Record completion or death
    local gameTime = tick() - gameState.startTime
    
    if reason == "completed" then
        gameState.completedRuns = gameState.completedRuns + 1
        gameState.bestTime = math.min(gameState.bestTime, gameTime)
        Services.DifficultyService:RecordPlayerSuccess(player, gameTime)
        print("🏆 " .. player.Name .. " completed the game in " .. string.format("%.2f", gameTime) .. "s")
    elseif reason == "death" then
        gameState.deaths = gameState.deaths + 1
        Services.DifficultyService:RecordPlayerDeath(player)
        print("💀 " .. player.Name .. " died after " .. string.format("%.2f", gameTime) .. "s")
    end
    
    print("⏹️ Stopped game for player: " .. player.Name .. " (" .. reason .. ")")
end

-- Main game loop for individual player
function startPlayerGameLoop(player)
    local gameState = gameStates[player.UserId]
    
    gameLoopConnections[player.UserId] = RunService.Heartbeat:Connect(function(deltaTime)
        if not gameState.isPlaying then
            return
        end
        
        -- Update player position and distance
        updatePlayerPosition(player, deltaTime)
        
        -- Update difficulty-based game speed
        updateGameSpeed(player)
        
        -- Handle obstacle spawning based on difficulty
        handleObstacleSpawning(player, deltaTime)
        
        -- Check win/lose conditions
        checkGameConditions(player)
        
        -- Update difficulty system with current distance
        updateDifficultySystem(player)
    end)
end

-- Update player position and calculate distance traveled
function updatePlayerPosition(player, deltaTime)
    local gameState = gameStates[player.UserId]
    
    if not gameState.character or not gameState.humanoid then
        return
    end
    
    local humanoidRootPart = gameState.character:FindFirstChild("HumanoidRootPart")
    if not humanoidRootPart then
        return
    end
    
    -- Calculate distance traveled this frame
    local currentTime = tick()
    local timeDelta = currentTime - gameState.lastPositionUpdate
    
    if timeDelta > 0 then
        local distanceThisFrame = gameState.currentSpeed * timeDelta
        gameState.distanceTraveled = gameState.distanceTraveled + distanceThisFrame
        gameState.lastPositionUpdate = currentTime
    end
end

-- Update game speed based on current difficulty
function updateGameSpeed(player)
    local gameState = gameStates[player.UserId]
    local difficulty = Services.DifficultyService:GetPlayerDifficulty(player)
    
    if difficulty then
        gameState.currentSpeed = difficulty.speed
        gameState.currentDifficulty = difficulty
        
        -- Apply speed to player character if needed
        if gameState.humanoid then
            gameState.humanoid.WalkSpeed = difficulty.speed
        end
    end
end

-- Handle obstacle spawning based on difficulty spawn rate
function handleObstacleSpawning(player, deltaTime)
    local gameState = gameStates[player.UserId]
    local difficulty = Services.DifficultyService:GetPlayerDifficulty(player)
    
    if not difficulty then
        return
    end
    
    local currentTime = tick()
    local timeSinceLastSpawn = currentTime - gameState.lastObstacleSpawn
    local spawnInterval = 1.0 / difficulty.spawnRate -- Convert spawn rate to interval
    
    if timeSinceLastSpawn >= spawnInterval then
        spawnObstacleForPlayer(player, difficulty)
        gameState.lastObstacleSpawn = currentTime
        gameState.obstaclesSpawned = gameState.obstaclesSpawned + 1
    end
end

-- Spawn obstacle based on current difficulty complexity
function spawnObstacleForPlayer(player, difficulty)
    if not Services.MovingObstacleService then
        return -- MovingObstacleService not available
    end
    
    -- Select obstacle type based on complexity
    local presets = Services.MovingObstacleService:GetPresetConfigs()
    local obstacleConfig
    
    if difficulty.complexity <= 2 then
        obstacleConfig = presets.horizontalSlider
    elseif difficulty.complexity <= 4 then
        obstacleConfig = presets.circularSpinner
    elseif difficulty.complexity <= 6 then
        obstacleConfig = presets.verticalPendulum
    elseif difficulty.complexity <= 8 then
        obstacleConfig = presets.figureEightWeaver
    else
        obstacleConfig = presets.randomRoamer
    end
    
    -- Adjust obstacle speed based on difficulty
    if obstacleConfig then
        local modifiedConfig = table.clone(obstacleConfig)
        modifiedConfig.speed = modifiedConfig.speed * (1 + (difficulty.complexity - 1) * 0.2)
        
        -- Calculate spawn position ahead of player
        local spawnDistance = 50 + (difficulty.level * 10)
        local spawnPosition = Vector3.new(
            math.random(-GAME_CONFIG.trackWidth/2, GAME_CONFIG.trackWidth/2),
            15,
            spawnDistance
        )
        
        -- Create obstacle
        local obstacleId = Services.MovingObstacleService:CreateObstacle(
            modifiedConfig,
            spawnPosition,
            workspace
        )
        
        if obstacleId then
            Services.MovingObstacleService:StartObstacle(obstacleId)
        end
    end
end

-- Check win/lose conditions
function checkGameConditions(player)
    local gameState = gameStates[player.UserId]
    
    if not gameState.character or not gameState.humanoid then
        stopGame(player, "death")
        return
    end
    
    -- Check if player reached the end
    if gameState.distanceTraveled >= GAME_CONFIG.trackLength then
        stopGame(player, "completed")
        return
    end
    
    -- Check if player died
    if gameState.humanoid.Health <= 0 then
        stopGame(player, "death")
        return
    end
    
    -- Check if player fell off the track (example condition)
    local humanoidRootPart = gameState.character:FindFirstChild("HumanoidRootPart")
    if humanoidRootPart and humanoidRootPart.Position.Y < -50 then
        stopGame(player, "death")
        return
    end
end

-- Update difficulty system with current progress
function updateDifficultySystem(player)
    local gameState = gameStates[player.UserId]
    local currentTime = tick()
    
    -- Update distance in difficulty system every second
    if currentTime - gameState.lastDifficultyUpdate >= 1.0 then
        local distanceThisUpdate = gameState.distanceTraveled - (gameState.lastDistanceUpdate or 0)
        Services.DifficultyService:UpdatePlayerDistance(player, distanceThisUpdate)
        
        gameState.lastDifficultyUpdate = currentTime
        gameState.lastDistanceUpdate = gameState.distanceTraveled
    end
end

-- Player management
Players.PlayerAdded:Connect(function(player)
    initializePlayerGameState(player)
    
    -- Auto-start game when player spawns (for testing)
    player.CharacterAdded:Connect(function(character)
        wait(2) -- Wait for character to fully load
        if not gameStates[player.UserId].isPlaying then
            startGame(player)
        end
    end)
end)

Players.PlayerRemoving:Connect(function(player)
    if gameStates[player.UserId] then
        stopGame(player, "disconnect")
        gameStates[player.UserId] = nil
    end
    
    if gameLoopConnections[player.UserId] then
        gameLoopConnections[player.UserId]:Disconnect()
        gameLoopConnections[player.UserId] = nil
    end
end)

-- Initialize existing players
for _, player in pairs(Players:GetPlayers()) do
    initializePlayerGameState(player)
end

-- Remote events for manual game control (optional)
local function createGameControlRemotes()
    local remoteEvents = Instance.new("Folder")
    remoteEvents.Name = "GameControlRemotes"
    remoteEvents.Parent = ReplicatedStorage
    
    local startGameRemote = Instance.new("RemoteEvent")
    startGameRemote.Name = "StartGame"
    startGameRemote.Parent = remoteEvents
    
    local stopGameRemote = Instance.new("RemoteEvent")
    stopGameRemote.Name = "StopGame"
    stopGameRemote.Parent = remoteEvents
    
    startGameRemote.OnServerEvent:Connect(function(player)
        startGame(player)
    end)
    
    stopGameRemote.OnServerEvent:Connect(function(player)
        stopGame(player, "manual")
    end)
end

-- Create game control remotes
createGameControlRemotes()

-- Debug information
spawn(function()
    while true do
        wait(10) -- Print stats every 10 seconds
        
        local activePlayers = 0
        for userId, gameState in pairs(gameStates) do
            if gameState.isPlaying then
                activePlayers = activePlayers + 1
                local player = Players:GetPlayerByUserId(userId)
                if player then
                    local difficulty = Services.DifficultyService:GetPlayerDifficulty(player)
                    if difficulty then
                        print("🎮 " .. player.Name .. " - Level: " .. difficulty.level .. 
                              " Speed: " .. string.format("%.1f", difficulty.speed) .. 
                              " Distance: " .. string.format("%.1f", gameState.distanceTraveled))
                    end
                end
            end
        end
        
        if activePlayers > 0 then
            print("📊 Active players: " .. activePlayers)
        end
    end
end)

print("🎮 Game Loop Integration initialized with Difficulty System!")
print("📍 Key Integration Points:")
print("   • Player speed updated from difficulty.speed")
print("   • Obstacle spawn rate from difficulty.spawnRate")
print("   • Obstacle complexity from difficulty.complexity")
print("   • Distance tracking feeds back to difficulty system")
print("   • Performance tracking (deaths/completions) adjusts adaptive difficulty")
print("🔄 Main game loop handles all difficulty-based adjustments automatically!")
