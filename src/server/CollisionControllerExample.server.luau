-- CollisionControllerExample.server.luau
-- Example script showing how CollisionController connects to player characters
-- This demonstrates the automatic character integration system

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Require the CollisionController
local CollisionController = require(script.Parent.controllers.CollisionController)

-- Initialize the collision system
CollisionController:Initialize()

print("🔗 CollisionController Character Integration Example")
print("=====================================")

-- Example: Manual player setup (normally handled automatically)
local function demonstratePlayerSetup(player)
    print("👤 Setting up collision for: " .. player.Name)
    
    -- The CollisionController automatically handles this when initialized,
    -- but here's what happens under the hood:
    
    player.CharacterAdded:Connect(function(character)
        print("👨‍🎮 Character spawned for: " .. player.Name)
        
        -- Wait for character to fully load
        local humanoid = character:WaitForChild("Humanoid")
        local humanoidRootPart = character:WaitForChild("HumanoidRootPart")
        
        -- Get player's collision data
        local playerData = CollisionController:GetPlayerData(player)
        if playerData then
            print("📊 Player Data:")
            print("  Health: " .. playerData.health .. "/" .. playerData.maxHealth)
            print("  Lives: " .. playerData.lives)
            print("  Color: " .. playerData.currentColor)
            print("  Invincible: " .. tostring(playerData.isInvincible))
        end
        
        -- Example: Manually change player color
        wait(2)
        print("🎨 Changing " .. player.Name .. " to Blue color")
        CollisionController:SetPlayerColor(player, "Blue")
        
        -- Example: Test damage
        wait(3)
        print("💥 Testing damage on " .. player.Name)
        CollisionController:DamagePlayer(player, 25, "test", {
            type = {name = "Test", damage = 25},
            color = "Red",
            position = humanoidRootPart.Position
        })
        
        -- Example: Test healing
        wait(2)
        print("💚 Testing healing on " .. player.Name)
        CollisionController:HealPlayer(player, 15)
        
        -- Example: Test color change
        wait(2)
        print("🎨 Testing color change to Green")
        CollisionController:SetPlayerColor(player, "Green")
    end)
end

-- Example: Set up collision monitoring for existing players
for _, player in pairs(Players:GetPlayers()) do
    demonstratePlayerSetup(player)
end

-- Example: Set up collision monitoring for new players
Players.PlayerAdded:Connect(demonstratePlayerSetup)

-- Example: Monitor collision events
local Events = ReplicatedStorage:WaitForChild("Events")

if Events:FindFirstChild("PlayerHitObstacle") then
    Events.PlayerHitObstacle.OnServerEvent:Connect(function(player, data)
        print("💥 " .. player.Name .. " hit obstacle: " .. (data.obstacle or "unknown"))
        print("  Damage: " .. (data.damage or 0))
        print("  Color Match: " .. tostring(data.colorMatch or false))
        print("  Player Color: " .. (data.playerColor or "unknown"))
        print("  Obstacle Color: " .. (data.obstacleColor or "unknown"))
    end)
end

if Events:FindFirstChild("PlayerColorChanged") then
    Events.PlayerColorChanged.OnServerEvent:Connect(function(player, data)
        print("🎨 " .. player.Name .. " changed color: " .. 
              (data.oldColor or "unknown") .. " → " .. (data.newColor or "unknown"))
    end)
end

if Events:FindFirstChild("PlayerHealthChanged") then
    Events.PlayerHealthChanged.OnServerEvent:Connect(function(player, data)
        print("❤️ " .. player.Name .. " health changed: " .. 
              (data.health or 0) .. "/" .. (data.maxHealth or 100))
        
        if data.damage then
            print("  Damage taken: " .. data.damage .. " from " .. (data.source or "unknown"))
        end
        
        if data.healing then
            print("  Healing received: " .. data.healing .. " from " .. (data.source or "unknown"))
        end
    end)
end

if Events:FindFirstChild("PlayerDied") then
    Events.PlayerDied.OnServerEvent:Connect(function(player, data)
        print("💀 " .. player.Name .. " died!")
        print("  Lives remaining: " .. (data.lives or 0))
        print("  Can respawn: " .. tostring(data.canRespawn or false))
        print("  Source: " .. (data.source or "unknown"))
    end)
end

-- Example: Create a test obstacle for collision testing
local function createTestObstacle()
    local obstacle = Instance.new("Part")
    obstacle.Name = "TestObstacle_Red"
    obstacle.Anchored = true
    obstacle.CanCollide = true
    obstacle.Size = Vector3.new(8, 10, 2)
    obstacle.Position = Vector3.new(0, 10, 0)
    obstacle.Material = Enum.Material.Neon
    obstacle.Color = Color3.fromRGB(255, 0, 0) -- Red
    obstacle.BrickColor = BrickColor.new("Really red")
    
    -- Mark as generated track element so CollisionController recognizes it
    obstacle:SetAttribute("GeneratedTrack", true)
    obstacle:SetAttribute("TrackId", "test_track")
    obstacle:SetAttribute("Color", "Red")
    
    obstacle.Parent = workspace
    
    print("🧱 Created test red obstacle at (0, 10, 0)")
    print("   Players matching red color will take no damage!")
    print("   Players with other colors will take damage!")
end

-- Example: Create a test collectible
local function createTestCollectible()
    local collectible = Instance.new("Part")
    collectible.Name = "Collectible_coin_test"
    collectible.Anchored = true
    collectible.CanCollide = false
    collectible.Size = Vector3.new(2, 2, 0.5)
    collectible.Position = Vector3.new(5, 10, 0)
    collectible.Material = Enum.Material.Neon
    collectible.Color = Color3.fromRGB(255, 215, 0) -- Gold
    collectible.Shape = Enum.PartType.Cylinder
    
    -- Add glow effect
    local pointLight = Instance.new("PointLight")
    pointLight.Brightness = 2
    pointLight.Color = Color3.fromRGB(255, 215, 0)
    pointLight.Range = 20
    pointLight.Parent = collectible
    
    -- Mark as collectible
    collectible:SetAttribute("GeneratedTrack", true)
    collectible:SetAttribute("TrackId", "test_track")
    
    collectible.Parent = workspace
    
    print("💎 Created test collectible at (5, 10, 0)")
    print("   Touch to collect and heal!")
end

-- Create test objects after a delay
spawn(function()
    wait(5)
    createTestObstacle()
    createTestCollectible()
    
    print("🎮 Test setup complete!")
    print("   Walk into the red obstacle to test collision detection")
    print("   Touch the gold collectible to test collection")
    print("   Use number keys (1-4) to change colors and test color matching")
end)

-- Example: Configuration changes
spawn(function()
    wait(10)
    
    print("⚙️ Testing configuration changes...")
    
    -- Test disabling color matching
    print("🔧 Disabling color matching for 10 seconds")
    CollisionController:EnableColorMatching(false)
    
    wait(10)
    
    -- Re-enable color matching
    print("🔧 Re-enabling color matching")
    CollisionController:EnableColorMatching(true)
    
    -- Test changing invincibility duration
    print("🔧 Setting longer invincibility duration")
    CollisionController:SetInvincibilityDuration(5.0)
end)

-- Example: Performance monitoring
spawn(function()
    while true do
        wait(30) -- Every 30 seconds
        
        local metrics = CollisionController:GetPerformanceMetrics()
        print("📊 Collision Performance Metrics:")
        print("  Total Collisions: " .. metrics.totalCollisions)
        print("  Color Matches: " .. metrics.colorMatches)
        print("  Color Mismatches: " .. metrics.colorMismatches)
        print("  Average Processing Time: " .. string.format("%.3f", metrics.averageProcessingTime) .. "ms")
        
        if metrics.totalCollisions > 0 then
            local matchRate = (metrics.colorMatches / metrics.totalCollisions) * 100
            print("  Color Match Rate: " .. string.format("%.1f", matchRate) .. "%")
        end
    end
end)

return CollisionController
