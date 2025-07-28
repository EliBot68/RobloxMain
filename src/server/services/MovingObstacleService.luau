-- MovingObstacleService.luau
-- Server-side service for managing moving obstacles in Color Rush (Standardized Enhanced Service)

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")

local ServiceBase = require(ReplicatedStorage.Shared.utils.ServiceBase)

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

-- Service-specific initialization
function MovingObstacleService:OnInit()
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
    spawn(function()
        while true do
            wait(30) -- Clean up every 30 seconds
            self:CleanupOrphanedObstacles()
        end
    end)
end

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

-- Preset obstacle configurations for easy use
function MovingObstacleService:GetPresetConfigs()
    return {
        horizontalSlider = {
            movementType = "Linear",
            speed = 8,
            direction = Vector3.new(1, 0, 0),
            movementBounds = {
                min = Vector3.new(-15, 0, 0),
                max = Vector3.new(15, 0, 0)
            },
            obstacleSize = Vector3.new(2, 8, 2),
            obstacleColor = Color3.fromRGB(255, 100, 100),
            trailEnabled = true,
            reverseOnBounds = true
        },
        
        verticalPendulum = {
            movementType = "Pendulum",
            speed = 3,
            movementBounds = {
                min = Vector3.new(-10, -10, 0),
                max = Vector3.new(10, 0, 0)
            },
            obstacleSize = Vector3.new(8, 2, 2),
            obstacleColor = Color3.fromRGB(255, 200, 100),
            trailEnabled = true,
            rotationEnabled = true
        },
        
        circularSpinner = {
            movementType = "Circular",
            speed = 4,
            movementBounds = {
                min = Vector3.new(-12, 0, -12),
                max = Vector3.new(12, 0, 12)
            },
            obstacleSize = Vector3.new(3, 6, 3),
            obstacleColor = Color3.fromRGB(100, 255, 100),
            trailEnabled = true,
            pulseEffect = true
        },
        
        figureEightWeaver = {
            movementType = "FigureEight",
            speed = 5,
            movementBounds = {
                min = Vector3.new(-8, 0, -8),
                max = Vector3.new(8, 0, 8)
            },
            obstacleSize = Vector3.new(4, 4, 4),
            obstacleColor = Color3.fromRGB(200, 100, 255),
            trailEnabled = true,
            rotationEnabled = true
        },
        
        randomRoamer = {
            movementType = "Random",
            speed = 6,
            movementBounds = {
                min = Vector3.new(-20, 0, -10),
                max = Vector3.new(20, 0, 10)
            },
            obstacleSize = Vector3.new(3, 5, 3),
            obstacleColor = Color3.fromRGB(255, 150, 200),
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
