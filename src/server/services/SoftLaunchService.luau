-- SoftLaunchService.luau
-- Handles soft launch configuration and setup

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")
local RunService = game:GetService("RunService")

local SoftLaunchService = {}

-- Game version and configuration
local GAME_VERSION = "1.0"
local IS_SOFT_LAUNCH = true

-- Spawn point configuration
local HUB_SPAWN_POSITION = Vector3.new(0, 10, 0)
local HUB_SPAWN_ORIENTATION = Vector3.new(0, 0, 0)

-- Areas to lock until future updates
local LOCKED_AREAS = {
    "Tournament Arena",
    "VIP Lounge", 
    "Prestige Palace",
    "Future Update Zone",
    "Coming Soon Area"
}

-- Dev tools to remove
local DEV_TOOLS_TO_REMOVE = {
    "AdminCommands",
    "DebugTools",
    "TestingPanel",
    "DeveloperConsole",
    "CheatButtons",
    "SpeedButton",
    "FlyButton",
    "GodModeButton"
}

function SoftLaunchService:SetupProperSpawnPoint()
    print("🚀 Setting up proper spawn point for soft launch...")
    
    -- Create spawn point in hub
    local spawnLocation = Instance.new("SpawnLocation")
    spawnLocation.Name = "HubSpawn"
    spawnLocation.Size = Vector3.new(6, 1, 6)
    spawnLocation.Position = HUB_SPAWN_POSITION
    spawnLocation.Orientation = HUB_SPAWN_ORIENTATION
    spawnLocation.Material = Enum.Material.Neon
    spawnLocation.BrickColor = BrickColor.new("Bright blue")
    spawnLocation.Anchored = true
    spawnLocation.CanCollide = true
    spawnLocation.Shape = Enum.PartType.Cylinder
    spawnLocation.TopSurface = Enum.SurfaceType.Smooth
    spawnLocation.BottomSurface = Enum.SurfaceType.Smooth
    
    -- Add spawn location to hub
    local hubModel = Workspace:FindFirstChild("Hub")
    if hubModel then
        spawnLocation.Parent = hubModel
    else
        spawnLocation.Parent = Workspace
    end
    
    -- Add spawn effects
    local pointLight = Instance.new("PointLight")
    pointLight.Color = Color3.new(0.2, 0.6, 1)
    pointLight.Brightness = 2
    pointLight.Range = 20
    pointLight.Parent = spawnLocation
    
    -- Add spawn particles
    local attachment = Instance.new("Attachment")
    attachment.Parent = spawnLocation
    
    local sparkles = Instance.new("ParticleEmitter")
    sparkles.Parent = attachment
    sparkles.Texture = "rbxasset://textures/particles/sparkles_main.dds"
    sparkles.Color = ColorSequence.new(Color3.new(0.2, 0.6, 1))
    sparkles.Size = NumberSequence.new(1)
    sparkles.Lifetime = NumberRange.new(1, 3)
    sparkles.Rate = 50
    sparkles.SpreadAngle = Vector2.new(180, 180)
    
    print("✅ Hub spawn point created successfully!")
end

function SoftLaunchService:RemoveDevTools()
    print("🧹 Removing development tools for soft launch...")
    
    local removed = 0
    
    -- Remove from Workspace
    for _, toolName in pairs(DEV_TOOLS_TO_REMOVE) do
        local tool = Workspace:FindFirstChild(toolName)
        if tool then
            tool:Destroy()
            removed = removed + 1
            print("  ❌ Removed:", toolName)
        end
    end
    
    -- Remove from ReplicatedStorage
    for _, toolName in pairs(DEV_TOOLS_TO_REMOVE) do
        local tool = ReplicatedStorage:FindFirstChild(toolName)
        if tool then
            tool:Destroy()
            removed = removed + 1
            print("  ❌ Removed:", toolName)
        end
    end
    
    -- Remove admin commands from server init
    local serverInit = script.Parent.Parent:FindFirstChild("init.server.luau")
    if serverInit then
        -- This would normally require modifying the actual file
        print("  ⚠️ Note: Remove admin commands from server init manually")
    end
    
    print("✅ Removed", removed, "development tools!")
end

function SoftLaunchService:LockUnusedAreas()
    print("🔒 Locking unused areas until future updates...")
    
    for _, areaName in pairs(LOCKED_AREAS) do
        local area = Workspace:FindFirstChild(areaName)
        if area then
            -- Create barrier around area
            local barrier = Instance.new("Part")
            barrier.Name = "ComingSoonBarrier"
            barrier.Size = Vector3.new(20, 15, 20)
            barrier.Position = area.Position + Vector3.new(0, 7.5, 0)
            barrier.Material = Enum.Material.ForceField
            barrier.BrickColor = BrickColor.new("Really red")
            barrier.Transparency = 0.7
            barrier.Anchored = true
            barrier.CanCollide = true
            barrier.Parent = area
            
            -- Add "Coming Soon" GUI
            local gui = Instance.new("SurfaceGui")
            gui.Face = Enum.NormalId.Front
            gui.Parent = barrier
            
            local frame = Instance.new("Frame")
            frame.Size = UDim2.new(1, 0, 1, 0)
            frame.BackgroundColor3 = Color3.new(0, 0, 0)
            frame.BackgroundTransparency = 0.3
            frame.Parent = gui
            
            local title = Instance.new("TextLabel")
            title.Size = UDim2.new(1, 0, 0.4, 0)
            title.Position = UDim2.new(0, 0, 0.1, 0)
            title.BackgroundTransparency = 1
            title.Text = "🚧 COMING SOON 🚧"
            title.TextColor3 = Color3.new(1, 1, 0)
            title.TextScaled = true
            title.Font = Enum.Font.SourceSansBold
            title.Parent = frame
            
            local desc = Instance.new("TextLabel")
            desc.Size = UDim2.new(1, 0, 0.4, 0)
            desc.Position = UDim2.new(0, 0, 0.5, 0)
            desc.BackgroundTransparency = 1
            desc.Text = areaName .. "\nWill be available in\nfuture updates!"
            desc.TextColor3 = Color3.new(1, 1, 1)
            desc.TextScaled = true
            desc.Font = Enum.Font.SourceSans
            desc.Parent = frame
            
            print("  🔒 Locked:", areaName)
        end
    end
    
    print("✅ Locked unused areas successfully!")
end

function SoftLaunchService:CreateVersionUI()
    print("📱 Creating Version 1.0 UI element...")
    
    -- This will be added to each player when they join
    local function addVersionUI(player)
        local playerGui = player:WaitForChild("PlayerGui")
        
        local versionGui = Instance.new("ScreenGui")
        versionGui.Name = "VersionDisplay"
        versionGui.ResetOnSpawn = false
        versionGui.Parent = playerGui
        
        local versionFrame = Instance.new("Frame")
        versionFrame.Size = UDim2.new(0, 120, 0, 40)
        versionFrame.Position = UDim2.new(1, -130, 1, -50)
        versionFrame.BackgroundColor3 = Color3.new(0.1, 0.1, 0.1)
        versionFrame.BackgroundTransparency = 0.3
        versionFrame.BorderSizePixel = 0
        versionFrame.Parent = versionGui
        
        local corner = Instance.new("UICorner")
        corner.CornerRadius = UDim.new(0, 8)
        corner.Parent = versionFrame
        
        local versionLabel = Instance.new("TextLabel")
        versionLabel.Size = UDim2.new(1, -10, 1, -5)
        versionLabel.Position = UDim2.new(0, 5, 0, 2)
        versionLabel.BackgroundTransparency = 1
        versionLabel.Text = "v" .. GAME_VERSION .. (IS_SOFT_LAUNCH and " BETA" or "")
        versionLabel.TextColor3 = Color3.new(0.8, 0.8, 0.8)
        versionLabel.TextScaled = true
        versionLabel.Font = Enum.Font.SourceSans
        versionLabel.Parent = versionFrame
        
        -- Add soft launch indicator if applicable
        if IS_SOFT_LAUNCH then
            local betaLabel = Instance.new("TextLabel")
            betaLabel.Size = UDim2.new(0, 80, 0, 20)
            betaLabel.Position = UDim2.new(1, -90, 1, -70)
            betaLabel.BackgroundColor3 = Color3.new(1, 0.5, 0)
            betaLabel.BackgroundTransparency = 0.2
            betaLabel.Text = "SOFT LAUNCH"
            betaLabel.TextColor3 = Color3.new(1, 1, 1)
            betaLabel.TextScaled = true
            betaLabel.Font = Enum.Font.SourceSansBold
            betaLabel.BorderSizePixel = 0
            betaLabel.Parent = versionGui
            
            local betaCorner = Instance.new("UICorner")
            betaCorner.CornerRadius = UDim.new(0, 4)
            betaCorner.Parent = betaLabel
        end
    end
    
    -- Add to existing players
    for _, player in pairs(Players:GetPlayers()) do
        addVersionUI(player)
    end
    
    -- Add to new players
    Players.PlayerAdded:Connect(addVersionUI)
    
    print("✅ Version UI created successfully!")
end

function SoftLaunchService:Initialize()
    print("🚀 SoftLaunchService initializing for Version " .. GAME_VERSION .. "...")
    
    if not IS_SOFT_LAUNCH then
        print("ℹ️ Not in soft launch mode, skipping some configurations...")
        return
    end
    
    -- Setup spawn point
    self:SetupProperSpawnPoint()
    
    -- Remove development tools
    self:RemoveDevTools()
    
    -- Lock unused areas
    self:LockUnusedAreas()
    
    -- Create version UI
    self:CreateVersionUI()
    
    print("✅ Soft launch setup complete!")
    print("📋 Game is ready for Version " .. GAME_VERSION .. " soft launch!")
end

return SoftLaunchService
