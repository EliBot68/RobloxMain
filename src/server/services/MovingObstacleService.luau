-- MovingObstacleService.luau
-- Server-side service for managing moving obstacles in Color Rush (Enterprise Configuration-Driven Service)

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")

-- Import configuration system
local ConfigurationManager = require(ReplicatedStorage.Shared.core.ConfigurationManager)
local SafeRequire = require(ReplicatedStorage.Shared.utils.SafeRequire)
local ServiceBase = SafeRequire.require(ReplicatedStorage.Shared.utils.ServiceBase)
local WorldObjectValidator = SafeRequire.require(ReplicatedStorage.Shared.utils.WorldObjectValidator)

local MovingObstacleService = ServiceBase.new("MovingObstacleService", {
    enableDetailedLogging = true,
    retryFailedRequires = true,
    maxRetryAttempts = 3,
    validateOnStart = true,
    autoStart = false
})

-- Get configuration instance
local config = ConfigurationManager.getInstance()

local MovingObstacleService = ServiceBase.new("MovingObstacleService", {
    enableDetailedLogging = true,
    retryFailedRequires = true,
    maxRetryAttempts = 3,
    validateOnStart = true,
    autoStart = false
})

-- Define dependencies
MovingObstacleService.Dependencies = {
    { path = ReplicatedStorage.Shared.modules.MovingObstacle, name = "MovingObstacle", optional = false },
}

-- Active obstacles tracking
local activeObstacles = {}
local obstacleCounter = 0

-- Track configuration
local trackObstacles = {}

--[[
    Initializes the MovingObstacleService by validating world objects and
    setting up the obstacle management system.
    
    @return {boolean} - True if initialization was successful
]]
function MovingObstacleService:OnInit()
    -- Validate obstacle-related world objects
    print("🔍 Validating moving obstacle world objects...")
    local missingObjects = WorldObjectValidator.validateAllRequired()
    if #missingObjects > 0 then
        warn("⚠️ MovingObstacleService: Missing required world objects:")
        for _, missing in ipairs(missingObjects) do
            warn("  • " .. missing)
        end
    end
    
    -- Validate game tracks for obstacle placement
    local gameTrackExists = WorldObjectValidator.validateObjectWithWait("workspace.GameTrack", 3)
    if not gameTrackExists then
        warn("⚠️ MovingObstacleService: GameTrack not found - obstacles may not spawn correctly")
    else
        print("✅ MovingObstacleService: GameTrack validated for obstacle placement")
    end
    
    -- Validate specific track folders
    local trackFolders = {"workspace.GameTracks.Easy", "workspace.GameTracks.Medium", "workspace.GameTracks.Hard"}
    local validatedTracks = 0
    for _, trackPath in ipairs(trackFolders) do
        local exists = WorldObjectValidator.validateObjectWithWait(trackPath, 2)
        if exists then
            validatedTracks = validatedTracks + 1
        end
    end
    
    if validatedTracks > 0 then
        print("✅ MovingObstacleService: " .. validatedTracks .. " track folders validated")
    end
    
    if not self.MovingObstacle then
        warn("❌ Failed to load MovingObstacle module - service disabled")
        return false
    end
    
    return true
end

-- Service-specific start logic
function MovingObstacleService:OnStart()
    -- Setup obstacle management
    self:SetupObstacleCleanup()
    
    print("✅ MovingObstacleService started!")
    return true
end

function MovingObstacleService:SetupObstacleCleanup()
    -- Clean up obstacles when players leave games
    game.Players.PlayerRemoving:Connect(function(player)
        self:CleanupPlayerObstacles(player.UserId)
    end)
    
    -- Periodic cleanup of orphaned obstacles
    task.spawn(function() -- UPDATED for modern API
        while true do
            local cleanupInterval = config:Get("performance.MEMORY.GARBAGE_COLLECTION_INTERVAL")
            task.wait(cleanupInterval) -- Configuration-driven cleanup interval
            self:CleanupOrphanedObstacles()
        end
    end)
end

--[[
    Creates a new moving obstacle with the specified configuration and position.
    
    @param config {table} - Configuration table for the obstacle behavior
    @param position {Vector3} - World position where the obstacle should be created
    @param parent {Instance} - Parent instance for the obstacle
    @return {string?} - Unique obstacle ID if creation was successful, nil otherwise
]]
function MovingObstacleService:CreateObstacle(config, position, parent)
    if not MovingObstacle then
        warn("❌ MovingObstacle module not available")
        return nil
    end
    
    obstacleCounter = obstacleCounter + 1
    local obstacleId = "obstacle_" .. obstacleCounter
    
    -- Create obstacle instance
    local obstacle = self.MovingObstacle.new(config)
    local obstaclePart = obstacle:Create(position, parent)
    
    if not obstaclePart then
        warn("❌ Failed to create obstacle part")
        return nil
    end
    
    -- Track the obstacle
    activeObstacles[obstacleId] = {
        obstacle = obstacle,
        part = obstaclePart,
        config = config,
        createdTime = tick(),
        isActive = false
    }
    
    -- Add identification to the part
    obstaclePart:SetAttribute("ObstacleId", obstacleId)
    obstaclePart:SetAttribute("ServiceManaged", true)
    
    print("🚧 Created moving obstacle: " .. obstacleId)
    return obstacleId, obstacle
end

function MovingObstacleService:StartObstacle(obstacleId)
    local obstacleData = activeObstacles[obstacleId]
    if not obstacleData then
        warn("❌ Obstacle not found: " .. tostring(obstacleId))
        return false
    end
    
    obstacleData.obstacle:StartMovement()
    obstacleData.isActive = true
    
    print("▶️ Started obstacle movement: " .. obstacleId)
    return true
end

function MovingObstacleService:StopObstacle(obstacleId)
    local obstacleData = activeObstacles[obstacleId]
    if not obstacleData then
        warn("❌ Obstacle not found: " .. tostring(obstacleId))
        return false
    end
    
    obstacleData.obstacle:StopMovement()
    obstacleData.isActive = false
    
    print("⏹️ Stopped obstacle movement: " .. obstacleId)
    return true
end

function MovingObstacleService:DestroyObstacle(obstacleId)
    local obstacleData = activeObstacles[obstacleId]
    if not obstacleData then
        warn("❌ Obstacle not found: " .. tostring(obstacleId))
        return false
    end
    
    obstacleData.obstacle:Destroy()
    activeObstacles[obstacleId] = nil
    
    print("🗑️ Destroyed obstacle: " .. obstacleId)
    return true
end

function MovingObstacleService:CreateTrackObstacles(trackName, obstacleConfigs)
    if not trackObstacles[trackName] then
        trackObstacles[trackName] = {}
    end
    
    local createdObstacles = {}
    
    for i, config in ipairs(obstacleConfigs) do
        local position = config.position or Vector3.new(0, 10, i * 20)
        local parent = workspace:FindFirstChild("GameTracks") and workspace.GameTracks:FindFirstChild(trackName)
        
        if not parent then
            parent = workspace
        end
        
        local obstacleId, obstacle = self:CreateObstacle(config, position, parent)
        if obstacleId then
            table.insert(trackObstacles[trackName], obstacleId)
            table.insert(createdObstacles, {id = obstacleId, obstacle = obstacle})
        end
    end
    
    print("🛤️ Created " .. #createdObstacles .. " obstacles for track: " .. trackName)
    return createdObstacles
end

function MovingObstacleService:StartTrackObstacles(trackName)
    local obstacles = trackObstacles[trackName]
    if not obstacles then
        warn("❌ No obstacles found for track: " .. trackName)
        return false
    end
    
    local startedCount = 0
    for _, obstacleId in ipairs(obstacles) do
        if self:StartObstacle(obstacleId) then
            startedCount = startedCount + 1
        end
    end
    
    print("▶️ Started " .. startedCount .. " obstacles for track: " .. trackName)
    return startedCount > 0
end

function MovingObstacleService:StopTrackObstacles(trackName)
    local obstacles = trackObstacles[trackName]
    if not obstacles then
        warn("❌ No obstacles found for track: " .. trackName)
        return false
    end
    
    local stoppedCount = 0
    for _, obstacleId in ipairs(obstacles) do
        if self:StopObstacle(obstacleId) then
            stoppedCount = stoppedCount + 1
        end
    end
    
    print("⏹️ Stopped " .. stoppedCount .. " obstacles for track: " .. trackName)
    return stoppedCount > 0
end

function MovingObstacleService:ClearTrackObstacles(trackName)
    local obstacles = trackObstacles[trackName]
    if not obstacles then
        return true
    end
    
    local destroyedCount = 0
    for _, obstacleId in ipairs(obstacles) do
        if self:DestroyObstacle(obstacleId) then
            destroyedCount = destroyedCount + 1
        end
    end
    
    trackObstacles[trackName] = nil
    print("🗑️ Cleared " .. destroyedCount .. " obstacles from track: " .. trackName)
    return true
end

function MovingObstacleService:GetActiveObstacles()
    local count = 0
    for _ in pairs(activeObstacles) do
        count = count + 1
    end
    return count
end

function MovingObstacleService:GetTrackObstacles(trackName)
    return trackObstacles[trackName] or {}
end

function MovingObstacleService:CleanupPlayerObstacles(userId)
    -- Clean up any player-specific obstacles if needed
    -- For now, this is a placeholder for future player-specific obstacle management
    print("🧹 Cleaned up obstacles for player: " .. userId)
end

function MovingObstacleService:CleanupOrphanedObstacles()
    local cleanedCount = 0
    
    for obstacleId, obstacleData in pairs(activeObstacles) do
        -- Check if obstacle part still exists and is valid
        if not obstacleData.part or not obstacleData.part.Parent then
            activeObstacles[obstacleId] = nil
            cleanedCount = cleanedCount + 1
        end
        
        -- Clean up very old obstacles (safety measure)
        local age = tick() - obstacleData.createdTime
        if age > 3600 then -- 1 hour old
            self:DestroyObstacle(obstacleId)
            cleanedCount = cleanedCount + 1
        end
    end
    
    if cleanedCount > 0 then
        print("🧹 Cleaned up " .. cleanedCount .. " orphaned obstacles")
    end
end

-- Preset obstacle configurations for easy use (now configuration-driven)
function MovingObstacleService:GetPresetConfigs()
    local obstacleColors = config:Get("assets.OBSTACLES.COLORS")
    local obstacleSizes = config:Get("assets.OBSTACLES.SIZES")
    local obstacleSpeeds = config:Get("assets.OBSTACLES.SPEEDS")
    local movementBounds = config:Get("assets.OBSTACLES.MOVEMENT_BOUNDS")
    
    return {
        horizontalSlider = {
            movementType = "Linear",
            speed = obstacleSpeeds.FAST,
            direction = Vector3.new(1, 0, 0),
            movementBounds = {
                min = Vector3.new(-movementBounds.MEDIUM_RANGE, 0, 0),
                max = Vector3.new(movementBounds.MEDIUM_RANGE, 0, 0)
            },
            obstacleSize = obstacleSizes.WALL,
            obstacleColor = obstacleColors.HORIZONTAL_SLIDER,
            trailEnabled = true,
            reverseOnBounds = true
        },
        
        verticalPendulum = {
            movementType = "Pendulum",
            speed = obstacleSpeeds.SLOW,
            movementBounds = {
                min = Vector3.new(-movementBounds.SMALL_RANGE, -movementBounds.SMALL_RANGE, 0),
                max = Vector3.new(movementBounds.SMALL_RANGE, 0, 0)
            },
            obstacleSize = obstacleSizes.PLATFORM,
            obstacleColor = obstacleColors.VERTICAL_PENDULUM,
            trailEnabled = true,
            rotationEnabled = true
        },
        
        circularSpinner = {
            movementType = "Circular",
            speed = obstacleSpeeds.MEDIUM,
            movementBounds = {
                min = Vector3.new(-movementBounds.SMALL_RANGE - 2, 0, -movementBounds.SMALL_RANGE - 2),
                max = Vector3.new(movementBounds.SMALL_RANGE + 2, 0, movementBounds.SMALL_RANGE + 2)
            },
            obstacleSize = obstacleSizes.SPINNER,
            obstacleColor = obstacleColors.CIRCULAR_SPINNER,
            trailEnabled = true,
            pulseEffect = true
        },
        
        figureEightWeaver = {
            movementType = "FigureEight",
            speed = obstacleSpeeds.MEDIUM + 1, -- Slightly faster than medium
            movementBounds = {
                min = Vector3.new(-movementBounds.SMALL_RANGE + 2, 0, -movementBounds.SMALL_RANGE + 2),
                max = Vector3.new(movementBounds.SMALL_RANGE - 2, 0, movementBounds.SMALL_RANGE - 2)
            },
            obstacleSize = obstacleSizes.MEDIUM,
            obstacleColor = obstacleColors.ZIGZAG_MOVER,
            trailEnabled = true,
            rotationEnabled = true
        },
        
        randomRoamer = {
            movementType = "Random",
            speed = obstacleSpeeds.FAST - 2, -- Slightly slower than fast
            movementBounds = {
                min = Vector3.new(-movementBounds.LARGE_RANGE, 0, -movementBounds.SMALL_RANGE),
                max = Vector3.new(movementBounds.LARGE_RANGE, 0, movementBounds.SMALL_RANGE)
            },
            obstacleSize = obstacleSizes.SPINNER,
            obstacleColor = obstacleColors.RANDOM_TELEPORTER,
            trailEnabled = true,
            pulseEffect = true
        }
    }
end

-- Client-facing methods
function MovingObstacleService.Client:GetObstacleCount(player)
    return self.Server:GetActiveObstacles()
end

function MovingObstacleService.Client:GetPresets(player)
    return self.Server:GetPresetConfigs()
end

return MovingObstacleService
