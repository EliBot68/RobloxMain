-- ModernObstacleSpawnerService.luau
-- Modernized obstacle spawner using ModernServiceFramework architecture
-- Converted from legacy ServiceBase pattern with enhanced features

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local Players = game:GetService("Players")

local ModernServiceFramework = require(ReplicatedStorage.Shared.core.ModernServiceFramework)

local ModernObstacleSpawnerService = {}
setmetatable(ModernObstacleSpawnerService, {__index = ModernServiceFramework.ServiceBase})

-- Create new service instance
function ModernObstacleSpawnerService.new(config)
    local self = ModernServiceFramework.CreateService("ObstacleSpawnerService", config or {
        Priority = 5,
        Dependencies = {"DifficultyService", "ConnectionManager"},
        OptionalDependencies = {"AnalyticsService", "PerformanceMonitor"}
    })
    setmetatable(self, {__index = ModernObstacleSpawnerService})
    
    -- Service-specific configuration
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
    
    -- Service state
    self.playerSpawnRates = {}
    self.activeObstacles = {}
    self.spawnMetrics = {
        totalSpawned = 0,
        totalDespawned = 0,
        averageLifetime = 0,
        peakObstacles = 0
    }
    
    return self
end

-- Initialize the service
function ModernObstacleSpawnerService:Initialize()
    print("🚀 Initializing ModernObstacleSpawnerService...")
    
    -- Get injected dependencies
    self.difficultyService = self:GetDependency("DifficultyService")
    self.connectionManager = self:GetDependency("ConnectionManager")
    self.analyticsService = self:GetDependency("AnalyticsService") -- Optional
    self.performanceMonitor = self:GetDependency("PerformanceMonitor") -- Optional
    
    -- Initialize connection groups for organized cleanup
    self:CreateConnectionGroup("playerConnections")
    self:CreateConnectionGroup("heartbeatConnections")
    self:CreateConnectionGroup("gameConnections")
    
    print("✅ ModernObstacleSpawnerService initialized with dependency injection")
end

-- Start the service
function ModernObstacleSpawnerService:Start()
    print("▶️ Starting ModernObstacleSpawnerService...")
    
    -- Set up player management with automatic connection cleanup
    self:AddConnection("playerAdded", Players.PlayerAdded:Connect(function(player)
        self:InitializePlayerSpawning(player)
    end), "playerConnections")
    
    self:AddConnection("playerRemoving", Players.PlayerRemoving:Connect(function(player)
        self:CleanupPlayerSpawning(player)
    end), "playerConnections")
    
    -- Initialize existing players
    for _, player in pairs(Players:GetPlayers()) do
        self:InitializePlayerSpawning(player)
    end
    
    -- Start main spawning loop with performance tracking
    self:AddConnection("spawnLoop", game:GetService("RunService").Heartbeat:Connect(function()
        self:TrackOperation("UpdateSpawning", function()
            self:UpdateSpawning()
        end)
    end), "heartbeatConnections")
    
    -- Start metrics collection if analytics available
    if self.analyticsService then
        self:StartMetricsCollection()
    end
    
    print("✅ ModernObstacleSpawnerService started with managed connections")
end

-- Stop the service
function ModernObstacleSpawnerService:Stop()
    print("⏹️ Stopping ModernObstacleSpawnerService...")
    
    -- Stop metrics collection
    self:StopMetricsCollection()
    
    -- Clean up all players
    for _, player in pairs(Players:GetPlayers()) do
        self:CleanupPlayerSpawning(player)
    end
    
    -- Connections are automatically cleaned up by ModernServiceFramework
    
    print("✅ ModernObstacleSpawnerService stopped with complete cleanup")
end

-- Initialize spawning for a specific player
function ModernObstacleSpawnerService:InitializePlayerSpawning(player)
    return self:TrackOperation("InitializePlayerSpawning", function()
        local userId = tostring(player.UserId)
        
        -- Set default spawn rate
        self.playerSpawnRates[userId] = {
            rate = self.spawnConfig.baseSpawnRate,
            complexity = 1,
            lastSpawnTime = 0,
            position = Vector3.new(0, 0, 0),
            initialized = os.time()
        }
        
        -- Initialize obstacle tracking
        self.activeObstacles[userId] = {}
        
        -- Register with difficulty service for dynamic adjustments
        if self.difficultyService then
            self.difficultyService:RegisterPlayer(player, {
                onSpawnRateChange = function(newRate)
                    self:UpdateSpawnRate(player, newRate)
                end,
                onComplexityChange = function(newComplexity)
                    self:UpdateComplexity(player, newComplexity)
                end
            })
        end
        
        print(string.format("🏗️ Initialized obstacle spawning for %s", player.Name))
        return true
    end)
end

-- Cleanup spawning for a player
function ModernObstacleSpawnerService:CleanupPlayerSpawning(player)
    return self:TrackOperation("CleanupPlayerSpawning", function()
        local userId = tostring(player.UserId)
        
        -- Cleanup spawn data
        self.playerSpawnRates[userId] = nil
        
        -- Cleanup active obstacles
        if self.activeObstacles[userId] then
            local cleaned = 0
            for _, obstacle in pairs(self.activeObstacles[userId]) do
                if obstacle and obstacle.Parent then
                    obstacle:Destroy()
                    cleaned = cleaned + 1
                end
            end
            self.activeObstacles[userId] = nil
            self.spawnMetrics.totalDespawned = self.spawnMetrics.totalDespawned + cleaned
        end
        
        -- Unregister from difficulty service
        if self.difficultyService then
            self.difficultyService:UnregisterPlayer(player)
        end
        
        print(string.format("🧹 Cleaned up obstacle spawning for %s", player.Name))
        return true
    end)
end

-- Update spawn rate for a player (called by DifficultyService)
function ModernObstacleSpawnerService:UpdateSpawnRate(player, newRate)
    return self:TrackOperation("UpdateSpawnRate", function()
        local userId = tostring(player.UserId)
        local playerData = self.playerSpawnRates[userId]
        
        if playerData then
            local oldRate = playerData.rate
            playerData.rate = math.clamp(newRate, 0.1, self.spawnConfig.maxSpawnRate)
            
            -- Analytics tracking
            if self.analyticsService then
                self.analyticsService:TrackEvent("SpawnRateChanged", {
                    playerId = userId,
                    oldRate = oldRate,
                    newRate = playerData.rate
                })
            end
            
            print(string.format("📈 Updated spawn rate for %s: %.2f/sec", player.Name, playerData.rate))
        end
        
        return true
    end)
end

-- Update complexity for a player (called by DifficultyService)
function ModernObstacleSpawnerService:UpdateComplexity(player, complexity)
    return self:TrackOperation("UpdateComplexity", function()
        local userId = tostring(player.UserId)
        local playerData = self.playerSpawnRates[userId]
        
        if playerData then
            local oldComplexity = playerData.complexity
            playerData.complexity = math.max(1, complexity)
            
            -- Analytics tracking
            if self.analyticsService then
                self.analyticsService:TrackEvent("ComplexityChanged", {
                    playerId = userId,
                    oldComplexity = oldComplexity,
                    newComplexity = playerData.complexity
                })
            end
            
            print(string.format("🎯 Updated complexity for %s: %d", player.Name, playerData.complexity))
        end
        
        return true
    end)
end

-- Main spawning update loop with error boundaries
function ModernObstacleSpawnerService:UpdateSpawning()
    local currentTime = tick()
    local spawnedThisFrame = 0
    
    for _, player in pairs(Players:GetPlayers()) do
        local success, result = pcall(function()
            local userId = tostring(player.UserId)
            local playerData = self.playerSpawnRates[userId]
            
            if playerData and self:ShouldSpawnObstacle(playerData, currentTime) then
                local spawnSuccess = self:SpawnObstacleForPlayer(player, playerData)
                if spawnSuccess then
                    playerData.lastSpawnTime = currentTime
                    spawnedThisFrame = spawnedThisFrame + 1
                end
            end
            
            -- Cleanup distant obstacles
            self:CleanupDistantObstacles(player)
        end)
        
        if not success then
            self:HandleError(string.format("UpdateSpawning failed for player %s: %s", player.Name, result))
        end
    end
    
    -- Update metrics
    if spawnedThisFrame > 0 then
        self.spawnMetrics.totalSpawned = self.spawnMetrics.totalSpawned + spawnedThisFrame
        
        local currentObstacles = self:GetTotalActiveObstacles()
        if currentObstacles > self.spawnMetrics.peakObstacles then
            self.spawnMetrics.peakObstacles = currentObstacles
        end
    end
end

-- Enhanced obstacle spawning with error handling
function ModernObstacleSpawnerService:SpawnObstacleForPlayer(player, playerData)
    return self:TrackOperation("SpawnObstacle", function()
        local character = player.Character
        if not character or not character:FindFirstChild("HumanoidRootPart") then
            return false
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
            
            -- Add metadata for tracking
            obstacle:SetAttribute("SpawnTime", os.time())
            obstacle:SetAttribute("PlayerId", userId)
            obstacle:SetAttribute("ObstacleType", obstacleType)
            
            table.insert(self.activeObstacles[userId], obstacle)
            
            -- Analytics tracking
            if self.analyticsService then
                self.analyticsService:TrackEvent("ObstacleSpawned", {
                    playerId = userId,
                    obstacleType = obstacleType,
                    complexity = playerData.complexity,
                    position = spawnPosition
                })
            end
            
            return true
        end
        
        return false
    end)
end

-- Enhanced obstacle creation with better error handling
function ModernObstacleSpawnerService:CreateObstacle(obstacleType, position)
    local success, obstacle = pcall(function()
        local newObstacle = Instance.new("Part")
        newObstacle.Name = "Obstacle_" .. obstacleType
        newObstacle.Position = position
        newObstacle.Anchored = true
        newObstacle.CanCollide = true
        
        -- Configure based on type
        if obstacleType == "simple_block" then
            newObstacle.Size = Vector3.new(4, 8, 2)
            newObstacle.Color = Color3.fromRGB(255, 100, 100)
            
        elseif obstacleType == "moving_platform" then
            newObstacle.Size = Vector3.new(8, 2, 8)
            newObstacle.Color = Color3.fromRGB(100, 255, 100)
            
            -- Add movement behavior with error protection
            local bodyPosition = Instance.new("BodyPosition")
            bodyPosition.MaxForce = Vector3.new(4000, 4000, 4000)
            bodyPosition.Position = position
            bodyPosition.Parent = newObstacle
            
        elseif obstacleType == "color_barrier" then
            newObstacle.Size = Vector3.new(12, 10, 1)
            newObstacle.Color = Color3.fromRGB(100, 100, 255)
            newObstacle.Transparency = 0.3
            
        elseif obstacleType == "speed_boost" then
            newObstacle.Size = Vector3.new(6, 1, 6)
            newObstacle.Color = Color3.fromRGB(255, 255, 100)
            newObstacle.Shape = Enum.PartType.Cylinder
            
        elseif obstacleType == "jump_pad" then
            newObstacle.Size = Vector3.new(6, 2, 6)
            newObstacle.Color = Color3.fromRGB(255, 150, 255)
        end
        
        newObstacle.Parent = Workspace
        return newObstacle
    end)
    
    if success then
        return obstacle
    else
        self:HandleError(string.format("Failed to create obstacle type '%s': %s", obstacleType, obstacle))
        return nil
    end
end

-- Select appropriate obstacle type based on complexity
function ModernObstacleSpawnerService:SelectObstacleType(complexity)
    local availableTypes = {"simple_block"}
    
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

-- Check if we should spawn an obstacle for a player
function ModernObstacleSpawnerService:ShouldSpawnObstacle(playerData, currentTime)
    local timeSinceLastSpawn = currentTime - playerData.lastSpawnTime
    local spawnInterval = 1 / playerData.rate -- Convert rate to interval
    
    return timeSinceLastSpawn >= spawnInterval
end

-- Enhanced distant obstacle cleanup with metrics
function ModernObstacleSpawnerService:CleanupDistantObstacles(player)
    local userId = tostring(player.UserId)
    local obstacles = self.activeObstacles[userId]
    
    if not obstacles then return end
    
    local character = player.Character
    if not character or not character:FindFirstChild("HumanoidRootPart") then
        return
    end
    
    local playerPosition = character.HumanoidRootPart.Position
    local cleaned = 0
    
    for i = #obstacles, 1, -1 do
        local obstacle = obstacles[i]
        if obstacle and obstacle.Parent then
            local distance = (obstacle.Position - playerPosition).Magnitude
            
            if distance > self.spawnConfig.despawnDistance then
                -- Calculate lifetime for metrics
                local spawnTime = obstacle:GetAttribute("SpawnTime")
                if spawnTime then
                    local lifetime = os.time() - spawnTime
                    self.spawnMetrics.averageLifetime = (self.spawnMetrics.averageLifetime + lifetime) / 2
                end
                
                obstacle:Destroy()
                table.remove(obstacles, i)
                cleaned = cleaned + 1
            end
        else
            -- Remove invalid obstacle reference
            table.remove(obstacles, i)
        end
    end
    
    if cleaned > 0 then
        self.spawnMetrics.totalDespawned = self.spawnMetrics.totalDespawned + cleaned
    end
end

-- Metrics collection
function ModernObstacleSpawnerService:StartMetricsCollection()
    if not self.analyticsService then return end
    
    self:AddConnection("metricsCollection", task.spawn(function()
        while self.State == ModernServiceFramework.ServiceState.RUNNING do
            task.wait(30) -- Collect metrics every 30 seconds
            
            self.analyticsService:TrackEvent("ObstacleSpawnerMetrics", {
                totalSpawned = self.spawnMetrics.totalSpawned,
                totalDespawned = self.spawnMetrics.totalDespawned,
                averageLifetime = self.spawnMetrics.averageLifetime,
                peakObstacles = self.spawnMetrics.peakObstacles,
                activeObstacles = self:GetTotalActiveObstacles(),
                activePlayers = self:GetActivePlayerCount()
            })
        end
    end), "gameConnections")
end

function ModernObstacleSpawnerService:StopMetricsCollection()
    self:DisconnectGroup("gameConnections")
end

-- Enhanced statistics methods
function ModernObstacleSpawnerService:GetPlayerStats(player)
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
        lastSpawnTime = playerData.lastSpawnTime,
        initialized = playerData.initialized,
        uptime = os.time() - playerData.initialized
    }
end

function ModernObstacleSpawnerService:GetServiceStats()
    return {
        -- Basic stats
        totalPlayers = self:GetActivePlayerCount(),
        totalActiveObstacles = self:GetTotalActiveObstacles(),
        averageObstaclesPerPlayer = self:GetAverageObstaclesPerPlayer(),
        isRunning = self.State == ModernServiceFramework.ServiceState.RUNNING,
        
        -- Enhanced metrics
        spawnMetrics = self.spawnMetrics,
        performance = self.Metrics,
        connectionGroups = {
            playerConnections = #(self.ConnectionGroups.playerConnections or {}),
            heartbeatConnections = #(self.ConnectionGroups.heartbeatConnections or {}),
            gameConnections = #(self.ConnectionGroups.gameConnections or {})
        },
        
        -- Service health
        errorCount = self.ErrorCount,
        lastError = self.LastError,
        uptime = self.StartTime > 0 and (tick() - self.StartTime) or 0
    }
end

-- Helper methods
function ModernObstacleSpawnerService:GetTotalActiveObstacles()
    local total = 0
    for _, obstacles in pairs(self.activeObstacles) do
        total = total + #obstacles
    end
    return total
end

function ModernObstacleSpawnerService:GetActivePlayerCount()
    local count = 0
    for _ in pairs(self.playerSpawnRates) do
        count = count + 1
    end
    return count
end

function ModernObstacleSpawnerService:GetAverageObstaclesPerPlayer()
    local playerCount = self:GetActivePlayerCount()
    if playerCount == 0 then return 0 end
    return self:GetTotalActiveObstacles() / playerCount
end

return ModernObstacleSpawnerService
