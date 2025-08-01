-- ObstacleSpawnerService.luau
-- CONSOLIDATED: Enhanced Obstacle Spawner Service with Comprehensive Error Handling
-- Replaces: ObstacleSpawnerService.luau, ObstacleSpawnerService.luau, ModernObstacleSpawnerService.luau
-- Features: Robust error handling, performance optimization, memory management, graceful degradation

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local _SafeRequire = require(ReplicatedStorage.Shared.utils.SafeRequire)
local ModernServiceFramework = require(ReplicatedStorage.Shared.core.ModernServiceFramework)
local _CriticalErrorHandler = require(ReplicatedStorage.Shared.core.CriticalErrorHandler)
local ConnectionUtils = require(ReplicatedStorage.Shared.utilities.ConnectionUtils)

local ObstacleSpawnerService = {}
setmetatable(ObstacleSpawnerService, {__index = ModernServiceFramework.ServiceBase})

-- ========================================
-- SERVICE INITIALIZATION
-- ========================================

function ObstacleSpawnerService.new(config)
    local self = ModernServiceFramework.CreateService("ObstacleSpawnerService", config or {
        Priority = 5,
        Dependencies = {"CriticalErrorHandler"},
        OptionalDependencies = {"DifficultyService", "AnalyticsService"}
    })
    setmetatable(self, {__index = ObstacleSpawnerService})
    
    -- Get error handler dependency
    self.errorHandler = self:GetDependency("CriticalErrorHandler")
    
    -- Wrap the entire service with error boundaries
    if self.errorHandler then
        self = self.errorHandler:WrapServiceWithErrorBoundaries(self, "ObstacleSpawnerService")
    end
    
    -- Obstacle spawning configuration with fallback values
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
        },
        emergencyMode = false,      -- Emergency low-resource mode
        maxObstaclesPerPlayer = 20, -- Maximum obstacles per player (memory safety)
        errorCount = 0,             -- Track errors for this service
        lastErrorTime = 0,          -- Last error timestamp
        degradedMode = false        -- Whether service is in degraded mode
    }
    
    -- Player-specific spawn settings
    self.playerSpawnRates = {}
    self.activeObstacles = {}
    self.spawnConnections = {}
    
    -- Error tracking for this service
    self.serviceErrors = {
        spawnErrors = 0,
        cleanupErrors = 0,
        playerErrors = 0,
        recoveryAttempts = 0
    }
    
    return self
end

-- ========================================
-- SERVICE LIFECYCLE WITH ERROR HANDLING
-- ========================================

function ObstacleSpawnerService:Initialize()
    if self.IsInitialized then
        return
    end
    
    local initBoundary = self.errorHandler:CreateErrorBoundary(
        "ObstacleSpawnerService.Initialize",
        function()
            print("🏗️ Initializing ObstacleSpawnerService with error handling...")
            
            -- Wrap service with connection management
            ConnectionUtils.WrapService(self, "ObstacleSpawnerService")
            
            -- Set up player connections using error boundaries
            local playerManagementBoundary = self.errorHandler:CreateErrorBoundary(
                "PlayerManagement",
                function()
                    ConnectionUtils.SetupPlayerManagement(self, 
                        function(player)
                            self:InitializePlayerSpawning(player)
                        end,
                        function(player)
                            self:CleanupPlayerSpawning(player)
                        end
                    )
                end,
                {
                    category = self.errorHandler.ERROR_CATEGORIES.SERVICE,
                    severity = self.errorHandler.ERROR_SEVERITY.CRITICAL,
                    recoveryStrategy = self.errorHandler.RECOVERY_STRATEGIES.GRACEFUL,
                    gracefulFunction = function()
                        -- Fallback: Set up basic player tracking without ConnectionUtils
                        self:SetupBasicPlayerTracking()
                    end
                }
            )
            
            playerManagementBoundary()
            
            self.IsInitialized = true
            print("✅ ObstacleSpawnerService initialized with comprehensive error handling")
        end,
        {
            category = self.errorHandler.ERROR_CATEGORIES.SERVICE,
            severity = self.errorHandler.ERROR_SEVERITY.FATAL,
            recoveryStrategy = self.errorHandler.RECOVERY_STRATEGIES.RESTART,
            restartFunction = function()
                -- Reset service state and try again
                self:ResetServiceState()
                self:Initialize()
            end
        }
    )
    
    initBoundary()
end

function ObstacleSpawnerService:Start()
    if self.IsRunning then
        return
    end
    
    local startBoundary = self.errorHandler:CreateErrorBoundary(
        "ObstacleSpawnerService.Start",
        function()
            self:Initialize()
            
            -- Start main spawning loop with error boundary
            local spawningBoundary = self.errorHandler:CreateErrorBoundary(
                "SpawningLoop",
                function()
                    return ConnectionUtils.SetupHeartbeat(self, function()
                        self:UpdateSpawning()
                    end, 0, 1/60) -- 60 FPS target
                end,
                {
                    category = self.errorHandler.ERROR_CATEGORIES.GAME_LOGIC,
                    severity = self.errorHandler.ERROR_SEVERITY.CRITICAL,
                    recoveryStrategy = self.errorHandler.RECOVERY_STRATEGIES.GRACEFUL,
                    gracefulFunction = function()
                        -- Fallback to degraded spawning mode
                        self:StartDegradedSpawning()
                    end
                }
            )
            
            local spawningConnection = spawningBoundary()
            if spawningConnection then
                self:AddConnection("mainSpawningLoop", spawningConnection, "Heartbeat")
            end
            
            -- Start error monitoring for this service
            self:StartServiceErrorMonitoring()
            
            self.IsRunning = true
            print("▶️ ObstacleSpawnerService started with error protection")
        end,
        {
            category = self.errorHandler.ERROR_CATEGORIES.SERVICE,
            severity = self.errorHandler.ERROR_SEVERITY.FATAL,
            recoveryStrategy = self.errorHandler.RECOVERY_STRATEGIES.USER_NOTIFY,
            userFriendlyMessage = "Unable to start obstacle spawning system. Some gameplay features may be unavailable."
        }
    )
    
    startBoundary()
end

-- ========================================
-- ERROR-SAFE PLAYER MANAGEMENT
-- ========================================

function ObstacleSpawnerService:InitializePlayerSpawning(player)
    local playerInitBoundary = self.errorHandler:CreateErrorBoundary(
        "InitializePlayerSpawning",
        function()
            local userId = tostring(player.UserId)
            
            -- Validate player object
            if not player or not player.Parent then
                error("Invalid player object")
            end
            
            -- Set default spawn rate with error checking
            self.playerSpawnRates[userId] = {
                rate = self.spawnConfig.baseSpawnRate,
                complexity = 1,
                lastSpawnTime = 0,
                position = Vector3.new(0, 0, 0),
                errorCount = 0,
                lastErrorTime = 0
            }
            
            -- Initialize obstacle tracking with bounds checking
            self.activeObstacles[userId] = {}
            
            print("🏗️ Initialized obstacle spawning for " .. player.Name)
        end,
        {
            category = self.errorHandler.ERROR_CATEGORIES.GAME_LOGIC,
            severity = self.errorHandler.ERROR_SEVERITY.ERROR,
            recoveryStrategy = self.errorHandler.RECOVERY_STRATEGIES.RETRY,
            retryFunction = function()
                task.wait(1) -- Wait before retry
                self:InitializePlayerSpawning(player)
            end,
            onError = function(errorData)
                self.serviceErrors.playerErrors = self.serviceErrors.playerErrors + 1
                
                -- If too many player errors, enter degraded mode
                if self.serviceErrors.playerErrors > 5 then
                    self:EnterDegradedMode("Too many player initialization errors")
                end
            end
        }
    )
    
    playerInitBoundary()
end

function ObstacleSpawnerService:CleanupPlayerSpawning(player)
    local cleanupBoundary = self.errorHandler:CreateErrorBoundary(
        "CleanupPlayerSpawning",
        function()
            local userId = tostring(player.UserId)
            
            -- Cleanup spawn data
            self.playerSpawnRates[userId] = nil
            
            -- Cleanup active obstacles with error protection
            if self.activeObstacles[userId] then
                local cleanupCount = 0
                for _, obstacle in pairs(self.activeObstacles[userId]) do
                    local obstacleCleanupBoundary = self.errorHandler:CreateErrorBoundary(
                        "ObstacleCleanup",
                        function()
                            if obstacle and obstacle.Parent then
                                obstacle:Destroy()
                                cleanupCount = cleanupCount + 1
                            end
                        end,
                        {
                            category = self.errorHandler.ERROR_CATEGORIES.MEMORY,
                            severity = self.errorHandler.ERROR_SEVERITY.WARN,
                            recoveryStrategy = self.errorHandler.RECOVERY_STRATEGIES.IGNORE
                        }
                    )
                    
                    obstacleCleanupBoundary()
                end
                
                self.activeObstacles[userId] = nil
                print("🧹 Cleaned up " .. cleanupCount .. " obstacles for " .. player.Name)
            end
        end,
        {
            category = self.errorHandler.ERROR_CATEGORIES.MEMORY,
            severity = self.errorHandler.ERROR_SEVERITY.ERROR,
            recoveryStrategy = self.errorHandler.RECOVERY_STRATEGIES.GRACEFUL,
            gracefulFunction = function()
                -- Force cleanup even if errors occur
                local userId = tostring(player.UserId)
                self.playerSpawnRates[userId] = nil
                self.activeObstacles[userId] = nil
            end,
            onError = function(errorData)
                self.serviceErrors.cleanupErrors = self.serviceErrors.cleanupErrors + 1
            end
        }
    )
    
    cleanupBoundary()
end

-- ========================================
-- ERROR-SAFE SPAWNING LOGIC
-- ========================================

function ObstacleSpawnerService:UpdateSpawning()
    -- Skip spawning if in emergency mode
    if self.spawnConfig.emergencyMode then
        return
    end
    
    local spawnUpdateBoundary = self.errorHandler:CreateErrorBoundary(
        "UpdateSpawning",
        function()
            local currentTime = tick()
            local Players = game:GetService("Players")
            local playersToProcess = Players:GetPlayers()
            
            -- Validate players list
            if not playersToProcess or #playersToProcess == 0 then
                return
            end
            
            -- Process each player with individual error boundaries
            for _, player in pairs(playersToProcess) do
                local playerSpawnBoundary = self.errorHandler:CreateErrorBoundary(
                    "PlayerSpawning",
                    function()
                        self:ProcessPlayerSpawning(player, currentTime)
                    end,
                    {
                        category = self.errorHandler.ERROR_CATEGORIES.GAME_LOGIC,
                        severity = self.errorHandler.ERROR_SEVERITY.WARN,
                        recoveryStrategy = self.errorHandler.RECOVERY_STRATEGIES.IGNORE,
                        onError = function(errorData)
                            -- Track per-player errors
                            local userId = tostring(player.UserId)
                            if self.playerSpawnRates[userId] then
                                self.playerSpawnRates[userId].errorCount = 
                                    (self.playerSpawnRates[userId].errorCount or 0) + 1
                            end
                        end
                    }
                )
                
                playerSpawnBoundary()
            end
        end,
        {
            category = self.errorHandler.ERROR_CATEGORIES.GAME_LOGIC,
            severity = self.errorHandler.ERROR_SEVERITY.ERROR,
            recoveryStrategy = self.errorHandler.RECOVERY_STRATEGIES.GRACEFUL,
            gracefulFunction = function()
                -- If main spawning fails, enter degraded mode
                self:EnterDegradedMode("Main spawning loop failed")
            end,
            onError = function(errorData)
                self.serviceErrors.spawnErrors = self.serviceErrors.spawnErrors + 1
                
                -- If too many spawn errors, trigger emergency mode
                if self.serviceErrors.spawnErrors > 10 then
                    self:EnterEmergencyMode("Excessive spawning errors")
                end
            end
        }
    )
    
    spawnUpdateBoundary()
end

function ObstacleSpawnerService:ProcessPlayerSpawning(player, currentTime)
    local userId = tostring(player.UserId)
    local playerData = self.playerSpawnRates[userId]
    
    -- Validate player data
    if not playerData then
        return
    end
    
    -- Check if player has too many errors
    if playerData.errorCount and playerData.errorCount > 3 then
        -- Temporarily skip this player
        return
    end
    
    -- Check if we should spawn obstacle
    if self:ShouldSpawnObstacle(playerData, currentTime) then
        local spawnBoundary = self.errorHandler:CreateErrorBoundary(
            "SpawnObstacle",
            function()
                self:SpawnObstacleForPlayer(player, playerData)
                playerData.lastSpawnTime = currentTime
            end,
            {
                category = self.errorHandler.ERROR_CATEGORIES.GAME_LOGIC,
                severity = self.errorHandler.ERROR_SEVERITY.WARN,
                recoveryStrategy = self.errorHandler.RECOVERY_STRATEGIES.RETRY,
                retryFunction = function()
                    -- Try spawning a simpler obstacle
                    self:SpawnSimpleObstacleForPlayer(player, playerData)
                end
            }
        )
        
        spawnBoundary()
    end
    
    -- Cleanup distant obstacles with error protection
    local cleanupBoundary = self.errorHandler:CreateErrorBoundary(
        "CleanupObstacles",
        function()
            self:CleanupDistantObstacles(player)
        end,
        {
            category = self.errorHandler.ERROR_CATEGORIES.MEMORY,
            severity = self.errorHandler.ERROR_SEVERITY.WARN,
            recoveryStrategy = self.errorHandler.RECOVERY_STRATEGIES.GRACEFUL,
            gracefulFunction = function()
                -- Force cleanup if normal cleanup fails
                self:ForceCleanupPlayerObstacles(player)
            end
        }
    )
    
    cleanupBoundary()
end

-- ========================================
-- ERROR-SAFE OBSTACLE CREATION
-- ========================================

function ObstacleSpawnerService:SpawnObstacleForPlayer(player, playerData)
    -- Check obstacle limits to prevent memory issues
    local userId = tostring(player.UserId)
    local activeCount = self.activeObstacles[userId] and #self.activeObstacles[userId] or 0
    
    if activeCount >= self.spawnConfig.maxObstaclesPerPlayer then
        -- Force cleanup oldest obstacles
        self:ForceCleanupOldestObstacles(player, 5)
    end
    
    local character = player.Character
    if not character or not character:FindFirstChild("HumanoidRootPart") then
        error("Player character not ready")
    end
    
    local rootPart = character.HumanoidRootPart
    local spawnPosition = rootPart.Position + Vector3.new(
        math.random(-20, 20),
        5,
        self.spawnConfig.spawnDistance
    )
    
    -- Validate spawn position
    if not self:IsValidSpawnPosition(spawnPosition) then
        error("Invalid spawn position")
    end
    
    -- Select obstacle type based on complexity
    local obstacleType = self:SelectObstacleType(playerData.complexity)
    
    local createBoundary = self.errorHandler:CreateErrorBoundary(
        "CreateObstacle",
        function()
            local obstacle = self:CreateObstacle(obstacleType, spawnPosition)
            
            if obstacle then
                -- Validate obstacle was created successfully
                if not obstacle.Parent or not obstacle.Position then
                    error("Obstacle creation validation failed")
                end
                
                table.insert(self.activeObstacles[userId], obstacle)
            else
                error("Failed to create obstacle")
            end
        end,
        {
            category = self.errorHandler.ERROR_CATEGORIES.GAME_LOGIC,
            severity = self.errorHandler.ERROR_SEVERITY.WARN,
            recoveryStrategy = self.errorHandler.RECOVERY_STRATEGIES.FALLBACK,
            fallbackFunction = function()
                -- Create simple block as fallback
                return self:CreateSimpleObstacle(spawnPosition)
            end
        }
    )
    
    createBoundary()
end

function ObstacleSpawnerService:SpawnSimpleObstacleForPlayer(player, playerData)
    -- Simplified spawning for error recovery
    local character = player.Character
    if not character or not character:FindFirstChild("HumanoidRootPart") then
        return
    end
    
    local rootPart = character.HumanoidRootPart
    local spawnPosition = rootPart.Position + Vector3.new(0, 5, 50) -- Simple position
    
    local obstacle = self:CreateSimpleObstacle(spawnPosition)
    if obstacle then
        local userId = tostring(player.UserId)
        table.insert(self.activeObstacles[userId], obstacle)
    end
end

function ObstacleSpawnerService:CreateObstacle(obstacleType, position)
    local createBoundary = self.errorHandler:CreateErrorBoundary(
        "CreateObstacleInstance",
        function()
            local obstacle = Instance.new("Part")
            obstacle.Name = "Obstacle_" .. obstacleType
            obstacle.Position = position
            obstacle.Anchored = true
            obstacle.CanCollide = true
            
            -- Configure based on type with error checking
            if obstacleType == "simple_block" then
                obstacle.Size = Vector3.new(4, 8, 2)
                obstacle.Color = Color3.fromRGB(255, 100, 100)
                
            elseif obstacleType == "moving_platform" then
                obstacle.Size = Vector3.new(8, 2, 8)
                obstacle.Color = Color3.fromRGB(100, 255, 100)
                
                -- Add movement behavior with error protection
                local movementBoundary = self.errorHandler:CreateErrorBoundary(
                    "MovementBehavior",
                    function()
                        local bodyPosition = Instance.new("BodyPosition")
                        bodyPosition.MaxForce = Vector3.new(4000, 4000, 4000)
                        bodyPosition.Position = position
                        bodyPosition.Parent = obstacle
                    end,
                    {
                        category = self.errorHandler.ERROR_CATEGORIES.PHYSICS,
                        severity = self.errorHandler.ERROR_SEVERITY.WARN,
                        recoveryStrategy = self.errorHandler.RECOVERY_STRATEGIES.IGNORE
                    }
                )
                
                movementBoundary()
                
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
            
            -- Safely parent to workspace
            local parentBoundary = self.errorHandler:CreateErrorBoundary(
                "ParentObstacle",
                function()
                    obstacle.Parent = Workspace
                end,
                {
                    category = self.errorHandler.ERROR_CATEGORIES.SYSTEM,
                    severity = self.errorHandler.ERROR_SEVERITY.ERROR,
                    recoveryStrategy = self.errorHandler.RECOVERY_STRATEGIES.RETRY,
                    retryFunction = function()
                        task.wait(0.1)
                        obstacle.Parent = Workspace
                    end
                }
            )
            
            parentBoundary()
            
            return obstacle
        end,
        {
            category = self.errorHandler.ERROR_CATEGORIES.GAME_LOGIC,
            severity = self.errorHandler.ERROR_SEVERITY.ERROR,
            recoveryStrategy = self.errorHandler.RECOVERY_STRATEGIES.FALLBACK,
            fallbackFunction = function()
                return self:CreateSimpleObstacle(position)
            end
        }
    )
    
    return createBoundary()
end

function ObstacleSpawnerService:CreateSimpleObstacle(position)
    -- Minimal obstacle for error recovery
    local obstacle = Instance.new("Part")
    obstacle.Name = "SimpleObstacle"
    obstacle.Position = position
    obstacle.Size = Vector3.new(4, 4, 2)
    obstacle.Color = Color3.fromRGB(128, 128, 128)
    obstacle.Anchored = true
    obstacle.CanCollide = true
    obstacle.Parent = Workspace
    
    return obstacle
end

-- ========================================
-- ERROR-SAFE CLEANUP
-- ========================================

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
    local cleanupCount = 0
    
    for i = #obstacles, 1, -1 do
        local obstacle = obstacles[i]
        
        local cleanupBoundary = self.errorHandler:CreateErrorBoundary(
            "CleanupObstacle",
            function()
                if obstacle and obstacle.Parent then
                    local distance = (obstacle.Position - playerPosition).Magnitude
                    
                    if distance > self.spawnConfig.despawnDistance then
                        obstacle:Destroy()
                        table.remove(obstacles, i)
                        cleanupCount = cleanupCount + 1
                    end
                else
                    -- Remove invalid obstacle reference
                    table.remove(obstacles, i)
                    cleanupCount = cleanupCount + 1
                end
            end,
            {
                category = self.errorHandler.ERROR_CATEGORIES.MEMORY,
                severity = self.errorHandler.ERROR_SEVERITY.WARN,
                recoveryStrategy = self.errorHandler.RECOVERY_STRATEGIES.GRACEFUL,
                gracefulFunction = function()
                    -- Force remove invalid reference
                    table.remove(obstacles, i)
                end
            }
        )
        
        cleanupBoundary()
    end
    
    if cleanupCount > 0 and self.spawnConfig.degradedMode then
        print("🧹 Cleaned up " .. cleanupCount .. " obstacles for " .. player.Name)
    end
end

function ObstacleSpawnerService:ForceCleanupPlayerObstacles(player)
    -- Emergency cleanup when normal cleanup fails
    local userId = tostring(player.UserId)
    
    if self.activeObstacles[userId] then
        for _, obstacle in pairs(self.activeObstacles[userId]) do
            pcall(function()
                if obstacle and obstacle.Parent then
                    obstacle:Destroy()
                end
            end)
        end
        
        self.activeObstacles[userId] = {}
        print("🚨 Emergency cleanup completed for " .. player.Name)
    end
end

function ObstacleSpawnerService:ForceCleanupOldestObstacles(player, count)
    -- Remove oldest obstacles when limit is reached
    local userId = tostring(player.UserId)
    local obstacles = self.activeObstacles[userId]
    
    if not obstacles then
        return
    end
    
    for i = 1, math.min(count, #obstacles) do
        local obstacle = obstacles[1]
        pcall(function()
            if obstacle and obstacle.Parent then
                obstacle:Destroy()
            end
        end)
        table.remove(obstacles, 1)
    end
end

-- ========================================
-- DEGRADED MODE AND EMERGENCY SYSTEMS
-- ========================================

function ObstacleSpawnerService:EnterDegradedMode(reason)
    if self.spawnConfig.degradedMode then
        return -- Already in degraded mode
    end
    
    self.spawnConfig.degradedMode = true
    
    -- Reduce spawning parameters
    self.spawnConfig.baseSpawnRate = self.spawnConfig.baseSpawnRate * 0.5
    self.spawnConfig.maxObstaclesPerPlayer = math.floor(self.spawnConfig.maxObstaclesPerPlayer * 0.7)
    
    self.errorHandler:Warn(
        "ObstacleSpawnerService entering degraded mode: " .. reason,
        "ObstacleSpawnerService",
        {
            reason = reason,
            serviceErrors = self.serviceErrors
        }
    )
    
    print("⚠️ ObstacleSpawnerService: Degraded mode activated - " .. reason)
end

function ObstacleSpawnerService:EnterEmergencyMode(reason)
    self.spawnConfig.emergencyMode = true
    
    -- Stop all spawning
    if self.spawnConnections then
        for connectionName, connection in pairs(self.spawnConnections) do
            pcall(function()
                connection:Disconnect()
            end)
        end
        self.spawnConnections = {}
    end
    
    self.errorHandler:Critical(
        "ObstacleSpawnerService entering emergency mode: " .. reason,
        "ObstacleSpawnerService",
        {
            reason = reason,
            serviceErrors = self.serviceErrors
        },
        self.errorHandler.ERROR_CATEGORIES.SERVICE
    )
    
    print("🚨 ObstacleSpawnerService: EMERGENCY MODE - All spawning stopped due to: " .. reason)
end

function ObstacleSpawnerService:StartDegradedSpawning()
    -- Simplified spawning for when main spawning fails
    print("🔄 Starting degraded spawning mode...")
    
    local degradedConnection = game:GetService("RunService").Heartbeat:Connect(function()
        if not self.spawnConfig.emergencyMode then
            local Players = game:GetService("Players")
            for _, player in pairs(Players:GetPlayers()) do
                -- Very simple spawning logic
                pcall(function()
                    local userId = tostring(player.UserId)
                    if self.playerSpawnRates[userId] and 
                       tick() - self.playerSpawnRates[userId].lastSpawnTime > 5 then -- Spawn every 5 seconds
                        self:SpawnSimpleObstacleForPlayer(player, self.playerSpawnRates[userId])
                        self.playerSpawnRates[userId].lastSpawnTime = tick()
                    end
                end)
            end
        end
    end)
    
    self:AddConnection("degradedSpawning", degradedConnection, "Connection")
end

-- ========================================
-- FALLBACK AND VALIDATION METHODS
-- ========================================

function ObstacleSpawnerService:SetupBasicPlayerTracking()
    -- Fallback player tracking when ConnectionUtils fails
    print("🔄 Setting up basic player tracking fallback...")
    
    local Players = game:GetService("Players")
    
    local joinConnection = Players.PlayerAdded:Connect(function(player)
        pcall(function()
            self:InitializePlayerSpawning(player)
        end)
    end)
    
    local leaveConnection = Players.PlayerRemoving:Connect(function(player)
        pcall(function()
            self:CleanupPlayerSpawning(player)
        end)
    end)
    
    self:AddConnection("basicPlayerJoin", joinConnection, "Connection")
    self:AddConnection("basicPlayerLeave", leaveConnection, "Connection")
    
    -- Initialize existing players
    for _, player in pairs(Players:GetPlayers()) do
        pcall(function()
            self:InitializePlayerSpawning(player)
        end)
    end
end

function ObstacleSpawnerService:IsValidSpawnPosition(position)
    -- Validate spawn position to prevent errors
    if not position then
        return false
    end
    
    if typeof(position) ~= "Vector3" then
        return false
    end
    
    -- Check for reasonable bounds
    if math.abs(position.X) > 10000 or math.abs(position.Y) > 10000 or math.abs(position.Z) > 10000 then
        return false
    end
    
    return true
end

function ObstacleSpawnerService:ResetServiceState()
    -- Reset service state for restart recovery
    self.IsInitialized = false
    self.IsRunning = false
    
    -- Clear player data safely
    for userId, _ in pairs(self.playerSpawnRates) do
        self.playerSpawnRates[userId] = nil
    end
    
    for userId, obstacles in pairs(self.activeObstacles) do
        for _, obstacle in pairs(obstacles) do
            pcall(function()
                if obstacle and obstacle.Parent then
                    obstacle:Destroy()
                end
            end)
        end
        self.activeObstacles[userId] = nil
    end
    
    -- Reset configuration
    self.spawnConfig.emergencyMode = false
    self.spawnConfig.degradedMode = false
    self.spawnConfig.errorCount = 0
    
    -- Reset error tracking
    self.serviceErrors = {
        spawnErrors = 0,
        cleanupErrors = 0,
        playerErrors = 0,
        recoveryAttempts = 0
    }
    
    print("🔄 ObstacleSpawnerService state reset for recovery")
end

-- ========================================
-- SERVICE ERROR MONITORING
-- ========================================

function ObstacleSpawnerService:StartServiceErrorMonitoring()
    -- Event-driven service health monitoring
    local serviceMonitoringEvent = Instance.new("BindableEvent")
    
    local function scheduleServiceMonitoring()
        if not self.IsRunning then return end
        
        task.wait(30) -- Check every 30 seconds
        serviceMonitoringEvent:Fire()
    end
    
    serviceMonitoringEvent.Event:Connect(function()
        pcall(function()
            self:CheckServiceHealth()
        end)
        spawn(scheduleServiceMonitoring)
    end)
    
    local monitoringConnection = spawn(scheduleServiceMonitoring)
    
    self:AddConnection("errorMonitoring", monitoringConnection, "Thread")
end

function ObstacleSpawnerService:CheckServiceHealth()
    local totalErrors = self.serviceErrors.spawnErrors + 
                       self.serviceErrors.cleanupErrors + 
                       self.serviceErrors.playerErrors
    
    if totalErrors > 20 then
        self:EnterEmergencyMode("Service error threshold exceeded: " .. totalErrors .. " total errors")
    elseif totalErrors > 10 and not self.spawnConfig.degradedMode then
        self:EnterDegradedMode("High error rate detected: " .. totalErrors .. " total errors")
    end
    
    -- Check memory usage via obstacle counts
    local totalObstacles = 0
    for _, obstacles in pairs(self.activeObstacles) do
        totalObstacles = totalObstacles + #obstacles
    end
    
    if totalObstacles > 200 then -- Total obstacle limit
        self.errorHandler:Warn(
            "High obstacle count detected: " .. totalObstacles,
            "ObstacleSpawnerService",
            { totalObstacles = totalObstacles }
        )
        
        -- Force cleanup of some obstacles
        self:PerformEmergencyCleanup()
    end
end

function ObstacleSpawnerService:PerformEmergencyCleanup()
    print("🚨 Performing emergency obstacle cleanup...")
    
    local cleanedCount = 0
    for userId, obstacles in pairs(self.activeObstacles) do
        -- Batch cleanup with event-driven processing to avoid blocking
        local cleanupEvent = Instance.new("BindableEvent")
        
        local function processCleanupBatch()
            local batchSize = 0
            while #obstacles > 10 and batchSize < 5 do -- Process in small batches
                local obstacle = table.remove(obstacles, 1)
                pcall(function()
                    if obstacle and obstacle.Parent then
                        obstacle:Destroy()
                        cleanedCount = cleanedCount + 1
                    end
                end)
                batchSize = batchSize + 1
            end
            
            if #obstacles > 10 then
                -- More batches needed, schedule next batch
                task.wait(0.05) -- Small delay between batches
                cleanupEvent:Fire()
            end
        end
        
        cleanupEvent.Event:Connect(processCleanupBatch)
        spawn(processCleanupBatch)
    end
    
    print("🧹 Emergency cleanup completed: " .. cleanedCount .. " obstacles removed")
end

-- ========================================
-- ORIGINAL API COMPATIBILITY WITH ERROR HANDLING
-- ========================================

-- All original methods are wrapped with error boundaries to maintain compatibility

function ObstacleSpawnerService:ShouldSpawnObstacle(playerData, currentTime)
    local shouldSpawnBoundary = self.errorHandler:CreateErrorBoundary(
        "ShouldSpawnObstacle",
        function()
            if not playerData or not currentTime then
                return false
            end
            
            local timeSinceLastSpawn = currentTime - (playerData.lastSpawnTime or 0)
            local spawnInterval = 1 / (playerData.rate or self.spawnConfig.baseSpawnRate)
            
            return timeSinceLastSpawn >= spawnInterval
        end,
        {
            category = self.errorHandler.ERROR_CATEGORIES.GAME_LOGIC,
            severity = self.errorHandler.ERROR_SEVERITY.WARN,
            recoveryStrategy = self.errorHandler.RECOVERY_STRATEGIES.FALLBACK,
            fallbackValue = false
        }
    )
    
    return shouldSpawnBoundary() or false
end

function ObstacleSpawnerService:SelectObstacleType(complexity)
    local selectBoundary = self.errorHandler:CreateErrorBoundary(
        "SelectObstacleType",
        function()
            complexity = complexity or 1
            
            local availableTypes = {}
            
            -- Basic obstacles always available
            table.insert(availableTypes, "simple_block")
            
            if complexity >= 2 and not self.spawnConfig.degradedMode then
                table.insert(availableTypes, "moving_platform")
                table.insert(availableTypes, "color_barrier")
            end
            
            if complexity >= 3 and not self.spawnConfig.degradedMode and not self.spawnConfig.emergencyMode then
                table.insert(availableTypes, "speed_boost")
                table.insert(availableTypes, "jump_pad")
            end
            
            return availableTypes[math.random(1, #availableTypes)]
        end,
        {
            category = self.errorHandler.ERROR_CATEGORIES.GAME_LOGIC,
            severity = self.errorHandler.ERROR_SEVERITY.WARN,
            recoveryStrategy = self.errorHandler.RECOVERY_STRATEGIES.FALLBACK,
            fallbackValue = "simple_block"
        }
    )
    
    return selectBoundary() or "simple_block"
end

-- Update spawn rate with error protection
function ObstacleSpawnerService:UpdateSpawnRate(player, newRate)
    local updateBoundary = self.errorHandler:CreateErrorBoundary(
        "UpdateSpawnRate",
        function()
            local userId = tostring(player.UserId)
            local playerData = self.playerSpawnRates[userId]
            
            if playerData then
                playerData.rate = math.clamp(newRate, 0.1, self.spawnConfig.maxSpawnRate)
                print(string.format("📈 Updated spawn rate for %s: %.2f/sec", player.Name, playerData.rate))
            end
        end,
        {
            category = self.errorHandler.ERROR_CATEGORIES.GAME_LOGIC,
            severity = self.errorHandler.ERROR_SEVERITY.WARN,
            recoveryStrategy = self.errorHandler.RECOVERY_STRATEGIES.IGNORE
        }
    )
    
    updateBoundary()
end

-- Update complexity with error protection
function ObstacleSpawnerService:UpdateComplexity(player, complexity)
    local updateBoundary = self.errorHandler:CreateErrorBoundary(
        "UpdateComplexity",
        function()
            local userId = tostring(player.UserId)
            local playerData = self.playerSpawnRates[userId]
            
            if playerData then
                playerData.complexity = math.max(1, complexity)
                print(string.format("🎯 Updated complexity for %s: %d", player.Name, playerData.complexity))
            end
        end,
        {
            category = self.errorHandler.ERROR_CATEGORIES.GAME_LOGIC,
            severity = self.errorHandler.ERROR_SEVERITY.WARN,
            recoveryStrategy = self.errorHandler.RECOVERY_STRATEGIES.IGNORE
        }
    )
    
    updateBoundary()
end

-- Get player statistics with error protection
function ObstacleSpawnerService:GetPlayerStats(player)
    local statsBoundary = self.errorHandler:CreateErrorBoundary(
        "GetPlayerStats",
        function()
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
                errorCount = playerData.errorCount or 0,
                degradedMode = self.spawnConfig.degradedMode,
                emergencyMode = self.spawnConfig.emergencyMode
            }
        end,
        {
            category = self.errorHandler.ERROR_CATEGORIES.DATA,
            severity = self.errorHandler.ERROR_SEVERITY.WARN,
            recoveryStrategy = self.errorHandler.RECOVERY_STRATEGIES.FALLBACK,
            fallbackValue = nil
        }
    )
    
    return statsBoundary()
end

-- Get service statistics with error protection
function ObstacleSpawnerService:GetServiceStats()
    local statsBoundary = self.errorHandler:CreateErrorBoundary(
        "GetServiceStats",
        function()
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
                isRunning = self.IsRunning,
                degradedMode = self.spawnConfig.degradedMode,
                emergencyMode = self.spawnConfig.emergencyMode,
                serviceErrors = self.serviceErrors,
                errorHandler = "CriticalErrorHandler integrated"
            }
        end,
        {
            category = self.errorHandler.ERROR_CATEGORIES.DATA,
            severity = self.errorHandler.ERROR_SEVERITY.WARN,
            recoveryStrategy = self.errorHandler.RECOVERY_STRATEGIES.FALLBACK,
            fallbackValue = {
                totalPlayers = 0,
                totalActiveObstacles = 0,
                averageObstaclesPerPlayer = 0,
                isRunning = false,
                degradedMode = true,
                emergencyMode = true,
                serviceErrors = {},
                errorHandler = "Error getting stats"
            }
        }
    )
    
    return statsBoundary()
end

-- Enhanced cleanup with comprehensive error handling
function ObstacleSpawnerService:Cleanup()
    print("🧹 ObstacleSpawnerService comprehensive cleanup with error handling...")
    
    local cleanupBoundary = self.errorHandler:CreateErrorBoundary(
        "ServiceCleanup",
        function()
            local connectionsCleanedUp = 0
            
            -- Use ConnectionUtils cleanup if available
            if self.CleanupConnections then
                connectionsCleanedUp = self:CleanupConnections()
            end
            
            -- Clean up all player data with error protection
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
        end,
        {
            category = self.errorHandler.ERROR_CATEGORIES.SYSTEM,
            severity = self.errorHandler.ERROR_SEVERITY.CRITICAL,
            recoveryStrategy = self.errorHandler.RECOVERY_STRATEGIES.GRACEFUL,
            gracefulFunction = function()
                -- Force cleanup even if errors occur
                pcall(function() self.playerSpawnRates = {} end)
                pcall(function() self.activeObstacles = {} end)
                pcall(function() self.spawnConnections = {} end)
                print("🚨 Force cleanup completed due to errors")
            end
        }
    )
    
    return cleanupBoundary() or 0
end

return ObstacleSpawnerService
