-- MovingObstacleMapExample.server.luau
-- Example script showing how to implement moving obstacles in a Color Rush track

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local Knit = require(ReplicatedStorage.Packages.Knit)
local SafeRequire = require(ReplicatedStorage.Shared.utils.SafeRequire)

-- Wait for services to load
repeat
    wait(0.1)
until Knit.Services.MovingObstacleService

local MovingObstacleService = Knit.Services.MovingObstacleService

-- Create example track structure
local function setupExampleTrack()
    -- Create track container
    local trackContainer = Workspace:FindFirstChild("ExampleObstacleTrack")
    if trackContainer then
        trackContainer:Destroy()
    end
    
    trackContainer = Instance.new("Folder")
    trackContainer.Name = "ExampleObstacleTrack"
    trackContainer.Parent = Workspace
    
    -- Create basic track platform
    local platform = Instance.new("Part")
    platform.Name = "TrackPlatform"
    platform.Size = Vector3.new(100, 2, 20)
    platform.Position = Vector3.new(0, 5, 0)
    platform.Anchored = true
    platform.Material = Enum.Material.Neon
    platform.Color = Color3.fromRGB(50, 50, 100)
    platform.Parent = trackContainer
    
    -- Add start and finish markers
    local startMarker = Instance.new("Part")
    startMarker.Name = "StartMarker"
    startMarker.Size = Vector3.new(2, 10, 20)
    startMarker.Position = Vector3.new(-45, 11, 0)
    startMarker.Anchored = true
    startMarker.Material = Enum.Material.Neon
    startMarker.Color = Color3.fromRGB(0, 255, 0)
    startMarker.Parent = trackContainer
    
    local finishMarker = Instance.new("Part")
    finishMarker.Name = "FinishMarker"
    finishMarker.Size = Vector3.new(2, 10, 20)
    finishMarker.Position = Vector3.new(45, 11, 0)
    finishMarker.Anchored = true
    finishMarker.Material = Enum.Material.Neon
    finishMarker.Color = Color3.fromRGB(255, 0, 0)
    finishMarker.Parent = trackContainer
    
    return trackContainer
end

-- Example obstacle configurations for the track
local function createExampleObstacles()
    local presets = MovingObstacleService:GetPresetConfigs()
    
    local obstacleConfigs = {
        -- Obstacle 1: Horizontal slider near start
        {
            position = Vector3.new(-30, 15, 0),
            config = presets.horizontalSlider
        },
        
        -- Obstacle 2: Vertical pendulum in middle
        {
            position = Vector3.new(-15, 20, 0),
            config = presets.verticalPendulum
        },
        
        -- Obstacle 3: Circular spinner
        {
            position = Vector3.new(0, 15, 0),
            config = presets.circularSpinner
        },
        
        -- Obstacle 4: Figure-eight weaver
        {
            position = Vector3.new(15, 15, 0),
            config = presets.figureEightWeaver
        },
        
        -- Obstacle 5: Random roamer near finish
        {
            position = Vector3.new(30, 15, 0),
            config = presets.randomRoamer
        },
        
        -- Additional custom obstacles
        {
            position = Vector3.new(-25, 25, 5),
            config = {
                movementType = "Linear",
                speed = 10,
                direction = Vector3.new(0, 0, 1),
                movementBounds = {
                    min = Vector3.new(0, 0, -8),
                    max = Vector3.new(0, 0, 8)
                },
                obstacleSize = Vector3.new(6, 2, 2),
                obstacleColor = Color3.fromRGB(255, 255, 0),
                trailEnabled = true,
                reverseOnBounds = true,
                rotationEnabled = true
            }
        },
        
        {
            position = Vector3.new(25, 25, -5),
            config = {
                movementType = "Waypoint",
                speed = 7,
                waypoints = {
                    Vector3.new(0, 0, 0),
                    Vector3.new(5, 5, 0),
                    Vector3.new(-5, 0, 0),
                    Vector3.new(0, -3, 0)
                },
                obstacleSize = Vector3.new(3, 3, 8),
                obstacleColor = Color3.fromRGB(150, 255, 150),
                trailEnabled = true,
                pulseEffect = true
            }
        }
    }
    
    return obstacleConfigs
end

-- Initialize the example track
local function initializeExampleTrack()
    print("🚧 Setting up moving obstacles example track...")
    
    -- Setup track structure
    local trackContainer = setupExampleTrack()
    
    -- Wait a moment for everything to load
    wait(1)
    
    -- Get obstacle configurations
    local obstacleConfigs = createExampleObstacles()
    
    -- Create obstacles for the track
    local createdObstacles = {}
    
    for i, obstacleData in ipairs(obstacleConfigs) do
        local obstacleId, obstacle = MovingObstacleService:CreateObstacle(
            obstacleData.config,
            obstacleData.position,
            trackContainer
        )
        
        if obstacleId then
            table.insert(createdObstacles, obstacleId)
            print("✅ Created obstacle " .. i .. ": " .. obstacleId)
        else
            warn("❌ Failed to create obstacle " .. i)
        end
    end
    
    -- Start all obstacles after a brief delay
    spawn(function()
        wait(2)
        print("▶️ Starting all obstacles...")
        
        for _, obstacleId in ipairs(createdObstacles) do
            MovingObstacleService:StartObstacle(obstacleId)
        end
        
        print("🎮 Example track ready! " .. #createdObstacles .. " obstacles active.")
        print("📍 Track location: " .. tostring(trackContainer.TrackPlatform.Position))
    end)
    
    -- Create a simple control system for testing
    local function createTestControls()
        local gui = Instance.new("ScreenGui")
        gui.Name = "ObstacleTestControls"
        gui.ResetOnSpawn = false
        
        local frame = Instance.new("Frame")
        frame.Size = UDim2.new(0, 200, 0, 150)
        frame.Position = UDim2.new(0, 10, 0, 10)
        frame.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
        frame.BorderSizePixel = 0
        frame.Parent = gui
        
        local title = Instance.new("TextLabel")
        title.Size = UDim2.new(1, 0, 0, 30)
        title.Position = UDim2.new(0, 0, 0, 0)
        title.Text = "Obstacle Controls"
        title.TextColor3 = Color3.fromRGB(255, 255, 255)
        title.BackgroundTransparency = 1
        title.Parent = frame
        
        local stopButton = Instance.new("TextButton")
        stopButton.Size = UDim2.new(0.9, 0, 0, 25)
        stopButton.Position = UDim2.new(0.05, 0, 0, 40)
        stopButton.Text = "Stop All Obstacles"
        stopButton.BackgroundColor3 = Color3.fromRGB(255, 100, 100)
        stopButton.Parent = frame
        
        local startButton = Instance.new("TextButton")
        startButton.Size = UDim2.new(0.9, 0, 0, 25)
        startButton.Position = UDim2.new(0.05, 0, 0, 70)
        startButton.Text = "Start All Obstacles"
        startButton.BackgroundColor3 = Color3.fromRGB(100, 255, 100)
        startButton.Parent = frame
        
        local clearButton = Instance.new("TextButton")
        clearButton.Size = UDim2.new(0.9, 0, 0, 25)
        clearButton.Position = UDim2.new(0.05, 0, 0, 100)
        clearButton.Text = "Clear All Obstacles"
        clearButton.BackgroundColor3 = Color3.fromRGB(255, 255, 100)
        clearButton.Parent = frame
        
        -- Button functionality
        stopButton.Activated:Connect(function()
            for _, obstacleId in ipairs(createdObstacles) do
                MovingObstacleService:StopObstacle(obstacleId)
            end
            print("⏹️ Stopped all obstacles")
        end)
        
        startButton.Activated:Connect(function()
            for _, obstacleId in ipairs(createdObstacles) do
                MovingObstacleService:StartObstacle(obstacleId)
            end
            print("▶️ Started all obstacles")
        end)
        
        clearButton.Activated:Connect(function()
            for _, obstacleId in ipairs(createdObstacles) do
                MovingObstacleService:DestroyObstacle(obstacleId)
            end
            createdObstacles = {}
            gui:Destroy()
            if trackContainer then
                trackContainer:Destroy()
            end
            print("🗑️ Cleared all obstacles and track")
        end)
        
        -- Add to StarterGui for all players
        local StarterGui = game:GetService("StarterGui")
        local success, error = pcall(function()
            gui.Parent = StarterGui
        end)
        
        if not success then
            warn("Failed to add test controls to StarterGui: " .. tostring(error))
            gui:Destroy()
        end
    end
    
    -- Create test controls after a delay
    spawn(function()
        wait(3)
        createTestControls()
    end)
end

-- Add usage instructions
local function printUsageInstructions()
    print("🎮 MOVING OBSTACLES EXAMPLE TRACK")
    print("=====================================")
    print("This example demonstrates the MovingObstacle system with:")
    print("• 5 different movement patterns")
    print("• Custom obstacle configurations")
    print("• Track-based obstacle management")
    print("• Runtime control system")
    print("")
    print("🎯 Features demonstrated:")
    print("  - Linear horizontal movement")
    print("  - Pendulum swinging motion")
    print("  - Circular spinning")
    print("  - Figure-eight patterns")
    print("  - Random movement")
    print("  - Waypoint following")
    print("")
    print("🎮 Test controls available in StarterGui")
    print("📍 Track spawned at (0, 5, 0)")
    print("=====================================")
end

-- Initialize everything
spawn(function()
    wait(2) -- Wait for services to fully load
    printUsageInstructions()
    initializeExampleTrack()
end)
