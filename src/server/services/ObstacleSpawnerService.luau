-- ObstacleSpawnerService.luau
-- Service for spawning and managing obstacles during gameplay
-- Integrates with DifficultyService for dynamic obstacle management

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local SafeRequire = require(ReplicatedStorage.Shared.utils.SafeRequire)
local ServiceBase = SafeRequire.require(ReplicatedStorage.Shared.utils.ServiceBase)
local ConnectionUtils = require(ReplicatedStorage.Shared.utilities.ConnectionUtils)

local ObstacleSpawnerService = {}
setmetatable(ObstacleSpawnerService, {__index = ServiceBase})

-- Service initialization
function ObstacleSpawnerService.new()
    local self = ServiceBase.new("ObstacleSpawnerService", {
        Priority = 5,
        Dependencies = {}
    })
    setmetatable(self, {__index = ObstacleSpawnerService})
    
    -- Obstacle spawning configuration
    self.spawnConfig = {
        baseSpawnRate = 2.0,        -- Base obstacles per second
        maxSpawnRate = 8.0,         -- Maximum spawn rate
        spawnDistance = 100,        -- Distance ahead to spawn
        despawnDistance = 50,       -- Distance behind to despawn
        complexity = 1,             -- Complexity multiplier
        obstacleTypes = {
            "simple_block",
            "moving_platform", 
            "color_barrier",
            "speed_boost",
            "jump_pad"
        }
    }
    
    -- Player-specific spawn settings
    self.playerSpawnRates = {}
    self.activeObstacles = {}
    self.spawnConnections = {}
    
    return self
end

-- Initialize the service
function ObstacleSpawnerService:Initialize()
    if self.IsInitialized then
        return
    end
    
    print("🏗️ Initializing ObstacleSpawnerService...")
    
    -- Wrap service with connection management
    ConnectionUtils.WrapService(self, "ObstacleSpawnerService")
    
    -- Set up player connections using ConnectionUtils
    ConnectionUtils.SetupPlayerManagement(self, 
        function(player)
            self:InitializePlayerSpawning(player)
        end,
        function(player)
            self:CleanupPlayerSpawning(player)
        end
    )
    
    self.IsInitialized = true
    print("✅ ObstacleSpawnerService initialized with enhanced connection management")
end

-- Start the service
function ObstacleSpawnerService:Start()
    if self.IsRunning then
        return
    end
    
    self:Initialize()
    
    -- Start main spawning loop using ConnectionUtils
    self:AddConnection("mainSpawningLoop", 
        ConnectionUtils.SetupHeartbeat(self, function()
            self:UpdateSpawning()
        end, 0, 1/60), -- 60 FPS target
        "Heartbeat"
    )
    
    self.IsRunning = true
    print("▶️ ObstacleSpawnerService started with managed connections")
end

-- Stop the service
function ObstacleSpawnerService:Stop()
    if not self.IsRunning then
        return
    end
    
    -- Use enhanced cleanup from ConnectionUtils wrapper
    self:CleanupConnections()
    
    self.IsRunning = false
    print("⏹️ ObstacleSpawnerService stopped with complete connection cleanup")
end

-- Initialize spawning for a specific player
function ObstacleSpawnerService:InitializePlayerSpawning(player)
    local userId = tostring(player.UserId)
    
    -- Set default spawn rate
    self.playerSpawnRates[userId] = {
        rate = self.spawnConfig.baseSpawnRate,
        complexity = 1,
        lastSpawnTime = 0,
        position = Vector3.new(0, 0, 0)
    }
    
    -- Initialize obstacle tracking
    self.activeObstacles[userId] = {}
    
    print("🏗️ Initialized obstacle spawning for " .. player.Name)
end

-- Cleanup spawning for a player
function ObstacleSpawnerService:CleanupPlayerSpawning(player)
    local userId = tostring(player.UserId)
    
    -- Cleanup spawn data
    self.playerSpawnRates[userId] = nil
    
    -- Cleanup active obstacles
    if self.activeObstacles[userId] then
        for _, obstacle in pairs(self.activeObstacles[userId]) do
            if obstacle and obstacle.Parent then
                obstacle:Destroy()
            end
        end
        self.activeObstacles[userId] = nil
    end
    
    print("🧹 Cleaned up obstacle spawning for " .. player.Name)
end

-- Update spawn rate for a player (called by DifficultyService)
function ObstacleSpawnerService:UpdateSpawnRate(player, newRate)
    local userId = tostring(player.UserId)
    local playerData = self.playerSpawnRates[userId]
    
    if playerData then
        playerData.rate = math.clamp(newRate, 0.1, self.spawnConfig.maxSpawnRate)
        print(string.format("📈 Updated spawn rate for %s: %.2f/sec", player.Name, playerData.rate))
    end
end

-- Update complexity for a player (called by DifficultyService) 
function ObstacleSpawnerService:UpdateComplexity(player, complexity)
    local userId = tostring(player.UserId)
    local playerData = self.playerSpawnRates[userId]
    
    if playerData then
        playerData.complexity = math.max(1, complexity)
        print(string.format("🎯 Updated complexity for %s: %d", player.Name, playerData.complexity))
    end
end

-- Main spawning update loop
function ObstacleSpawnerService:UpdateSpawning()
    local currentTime = tick()
    local Players = game:GetService("Players")
    
    for player in pairs(Players:GetPlayers()) do
        local userId = tostring(player.UserId)
        local playerData = self.playerSpawnRates[userId]
        
        if playerData and self:ShouldSpawnObstacle(playerData, currentTime) then
            self:SpawnObstacleForPlayer(player, playerData)
            playerData.lastSpawnTime = currentTime
        end
        
        -- Cleanup distant obstacles
        self:CleanupDistantObstacles(player)
    end
end

-- Check if we should spawn an obstacle for a player
function ObstacleSpawnerService:ShouldSpawnObstacle(playerData, currentTime)
    local timeSinceLastSpawn = currentTime - playerData.lastSpawnTime
    local spawnInterval = 1 / playerData.rate -- Convert rate to interval
    
    return timeSinceLastSpawn >= spawnInterval
end

-- Spawn an obstacle for a specific player
function ObstacleSpawnerService:SpawnObstacleForPlayer(player, playerData)
    local character = player.Character
    if not character or not character:FindFirstChild("HumanoidRootPart") then
        return
    end
    
    local rootPart = character.HumanoidRootPart
    local spawnPosition = rootPart.Position + Vector3.new(
        math.random(-20, 20),
        5,
        self.spawnConfig.spawnDistance
    )
    
    -- Select obstacle type based on complexity
    local obstacleType = self:SelectObstacleType(playerData.complexity)
    local obstacle = self:CreateObstacle(obstacleType, spawnPosition)
    
    if obstacle then
        local userId = tostring(player.UserId)
        table.insert(self.activeObstacles[userId], obstacle)
    end
end

-- Select appropriate obstacle type based on complexity
function ObstacleSpawnerService:SelectObstacleType(complexity)
    -- Simple selection based on complexity
    local availableTypes = {}
    
    -- Basic obstacles always available
    table.insert(availableTypes, "simple_block")
    
    if complexity >= 2 then
        table.insert(availableTypes, "moving_platform")
        table.insert(availableTypes, "color_barrier")
    end
    
    if complexity >= 3 then
        table.insert(availableTypes, "speed_boost")
        table.insert(availableTypes, "jump_pad")
    end
    
    return availableTypes[math.random(1, #availableTypes)]
end

-- Create an obstacle of the specified type
function ObstacleSpawnerService:CreateObstacle(obstacleType, position)
    local obstacle = Instance.new("Part")
    obstacle.Name = "Obstacle_" .. obstacleType
    obstacle.Position = position
    obstacle.Anchored = true
    obstacle.CanCollide = true
    
    -- Configure based on type
    if obstacleType == "simple_block" then
        obstacle.Size = Vector3.new(4, 8, 2)
        obstacle.Color = Color3.fromRGB(255, 100, 100)
        
    elseif obstacleType == "moving_platform" then
        obstacle.Size = Vector3.new(8, 2, 8)
        obstacle.Color = Color3.fromRGB(100, 255, 100)
        
        -- Add movement behavior
        local bodyPosition = Instance.new("BodyPosition")
        bodyPosition.MaxForce = Vector3.new(4000, 4000, 4000)
        bodyPosition.Position = position
        bodyPosition.Parent = obstacle
        
    elseif obstacleType == "color_barrier" then
        obstacle.Size = Vector3.new(12, 10, 1)
        obstacle.Color = Color3.fromRGB(100, 100, 255)
        obstacle.Transparency = 0.3
        
    elseif obstacleType == "speed_boost" then
        obstacle.Size = Vector3.new(6, 1, 6)
        obstacle.Color = Color3.fromRGB(255, 255, 100)
        obstacle.Shape = Enum.PartType.Cylinder
        
    elseif obstacleType == "jump_pad" then
        obstacle.Size = Vector3.new(6, 2, 6)
        obstacle.Color = Color3.fromRGB(255, 150, 255)
    end
    
    obstacle.Parent = Workspace
    return obstacle
end

-- Cleanup obstacles that are too far from the player
function ObstacleSpawnerService:CleanupDistantObstacles(player)
    local userId = tostring(player.UserId)
    local obstacles = self.activeObstacles[userId]
    
    if not obstacles then
        return
    end
    
    local character = player.Character
    if not character or not character:FindFirstChild("HumanoidRootPart") then
        return
    end
    
    local playerPosition = character.HumanoidRootPart.Position
    
    for i = #obstacles, 1, -1 do
        local obstacle = obstacles[i]
        if obstacle and obstacle.Parent then
            local distance = (obstacle.Position - playerPosition).Magnitude
            
            if distance > self.spawnConfig.despawnDistance then
                obstacle:Destroy()
                table.remove(obstacles, i)
            end
        else
            -- Remove invalid obstacle reference
            table.remove(obstacles, i)
        end
    end
end

-- Get spawning statistics for a player
function ObstacleSpawnerService:GetPlayerStats(player)
    local userId = tostring(player.UserId)
    local playerData = self.playerSpawnRates[userId]
    local obstacles = self.activeObstacles[userId]
    
    if not playerData then
        return nil
    end
    
    return {
        spawnRate = playerData.rate,
        complexity = playerData.complexity,
        activeObstacles = obstacles and #obstacles or 0,
        lastSpawnTime = playerData.lastSpawnTime
    }
end

-- Get overall service statistics
function ObstacleSpawnerService:GetServiceStats()
    local totalObstacles = 0
    local totalPlayers = 0
    
    for _, obstacles in pairs(self.activeObstacles) do
        totalObstacles = totalObstacles + #obstacles
        totalPlayers = totalPlayers + 1
    end
    
    return {
        totalPlayers = totalPlayers,
        totalActiveObstacles = totalObstacles,
        averageObstaclesPerPlayer = totalPlayers > 0 and (totalObstacles / totalPlayers) or 0,
        isRunning = self.IsRunning
    }
end

-- Enhanced cleanup method
function ObstacleSpawnerService:Cleanup()
    print("🧹 ObstacleSpawnerService comprehensive cleanup...")
    
    -- Use ConnectionUtils cleanup
    local connectionsCleanedUp = 0
    if self.CleanupConnections then
        connectionsCleanedUp = self:CleanupConnections()
    end
    
    -- Clean up all player data
    for playerId, _ in pairs(self.playerSpawnRates) do
        local player = game:GetService("Players"):GetPlayerByUserId(tonumber(playerId))
        if player then
            self:CleanupPlayerSpawning(player)
        end
    end
    
    -- Clear all data
    self.playerSpawnRates = {}
    self.activeObstacles = {}
    self.spawnConnections = {}
    
    print(string.format("✅ ObstacleSpawnerService cleanup complete - %d connections cleaned", connectionsCleanedUp))
    return connectionsCleanedUp
end

return ObstacleSpawnerService
