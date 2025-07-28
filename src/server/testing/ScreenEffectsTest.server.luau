-- ScreenEffectsTest.server.luau
-- Testing script for screen effects - shows how to use the system
-- Can be placed in ServerScriptService or run manually

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local ScreenEffectsService = require(script.Parent.Parent.services.ScreenEffectsService)

local ScreenEffectsTest = {}

function ScreenEffectsTest:TestAllEffects()
    print("🧪 Starting Screen Effects Test Suite...")
    
    -- Wait for players
    local function getTestPlayer()
        for _, player in pairs(Players:GetPlayers()) do
            if player.Character and player.Character:FindFirstChild("Humanoid") then
                return player
            end
        end
        return nil
    end
    
    local testPlayer = getTestPlayer()
    if not testPlayer then
        print("❌ No players found for testing. Waiting for player...")
        
        Players.PlayerAdded:Connect(function(player)
            player.CharacterAdded:Connect(function()
                wait(2)
                self:RunTestSequence(player)
            end)
        end)
        return
    end
    
    self:RunTestSequence(testPlayer)
end

function ScreenEffectsTest:RunTestSequence(player)
    if not player or not player.Character then return end
    
    print("🎬 Running test sequence for " .. player.Name)
    
    spawn(function()
        -- Test 1: Speed Boost Effect
        print("⚡ Testing Speed Boost Effect...")
        ScreenEffectsService:TriggerSpeedBoost(player, 3.0)
        wait(4)
        
        -- Test 2: Jump Effect
        print("🦘 Testing Jump Effect...")
        ScreenEffectsService:TriggerJump(player, 1.5)
        wait(2)
        
        -- Test 3: Screen Shake
        print("📳 Testing Screen Shake...")
        ScreenEffectsService:TriggerShake(player, 2.0, 1.0)
        wait(2)
        
        -- Test 4: Flash Effects
        print("✨ Testing Flash Effects...")
        ScreenEffectsService:TriggerFlash(player, Color3.fromRGB(255, 255, 0), 0.6, 0.3) -- Yellow flash
        wait(1)
        ScreenEffectsService:TriggerFlash(player, Color3.fromRGB(0, 255, 0), 0.4, 0.5) -- Green flash
        wait(2)
        
        -- Test 5: Death Effect (warning: dramatic!)
        print("💀 Testing Death Effect...")
        ScreenEffectsService:TriggerDeath(player)
        wait(3)
        
        -- Test 6: Respawn Effect
        print("❤️ Testing Respawn Effect...")
        ScreenEffectsService:TriggerRespawn(player)
        wait(2)
        
        print("✅ Screen Effects Test Complete!")
    end)
end

function ScreenEffectsTest:TestCombinationEffects(player)
    if not player or not player.Character then return end
    
    print("🎭 Testing combination effects for " .. player.Name)
    
    spawn(function()
        -- Super jump with speed boost
        print("🚀 Super Jump + Speed Combo!")
        ScreenEffectsService:TriggerSpeedBoost(player, 2.0)
        wait(0.5)
        ScreenEffectsService:TriggerJump(player, 2.0)
        wait(3)
        
        -- Impact combo
        print("💥 Impact Combo!")
        ScreenEffectsService:TriggerShake(player, 3.0, 0.5)
        ScreenEffectsService:TriggerFlash(player, Color3.fromRGB(255, 200, 0), 0.8, 0.2)
        wait(2)
        
        print("🎉 Combination test complete!")
    end)
end

function ScreenEffectsTest:TestPerformance()
    print("📊 Testing Screen Effects Performance...")
    
    local startTime = tick()
    local effectCount = 0
    
    -- Rapid fire effects test
    for i = 1, 10 do
        for _, player in pairs(Players:GetPlayers()) do
            if player.Character then
                ScreenEffectsService:TriggerFlash(player, Color3.random(), 0.3, 0.1)
                effectCount = effectCount + 1
            end
        end
        wait(0.1)
    end
    
    local endTime = tick()
    local duration = endTime - startTime
    
    print("📈 Performance Test Results:")
    print("  Effects triggered: " .. effectCount)
    print("  Duration: " .. math.round(duration * 100) / 100 .. " seconds")
    print("  Effects per second: " .. math.round((effectCount / duration) * 100) / 100)
end

-- Interactive Commands
function ScreenEffectsTest:CreateTestCommands()
    -- Create test commands that can be called via chat or other means
    local commands = {
        ["!speedboost"] = function(player, args)
            local duration = tonumber(args[1]) or 2.0
            ScreenEffectsService:TriggerSpeedBoost(player, duration)
        end,
        
        ["!jump"] = function(player, args)
            local power = tonumber(args[1]) or 1.0
            ScreenEffectsService:TriggerJump(player, power)
        end,
        
        ["!shake"] = function(player, args)
            local intensity = tonumber(args[1]) or 1.0
            local duration = tonumber(args[2]) or 0.5
            ScreenEffectsService:TriggerShake(player, intensity, duration)
        end,
        
        ["!flash"] = function(player, args)
            local r = tonumber(args[1]) or 255
            local g = tonumber(args[2]) or 255
            local b = tonumber(args[3]) or 255
            local intensity = tonumber(args[4]) or 0.5
            ScreenEffectsService:TriggerFlash(player, Color3.fromRGB(r, g, b), intensity, 0.3)
        end,
        
        ["!death"] = function(player, args)
            ScreenEffectsService:TriggerDeath(player)
        end,
        
        ["!respawn"] = function(player, args)
            ScreenEffectsService:TriggerRespawn(player)
        end,
        
        ["!testall"] = function(player, args)
            ScreenEffectsTest:RunTestSequence(player)
        end,
        
        ["!combo"] = function(player, args)
            ScreenEffectsTest:TestCombinationEffects(player)
        end
    }
    
    -- Set up chat command system
    Players.PlayerAdded:Connect(function(player)
        player.Chatted:Connect(function(message)
            local args = string.split(message:lower(), " ")
            local command = args[1]
            table.remove(args, 1)
            
            if commands[command] then
                commands[command](player, args)
                print("🎮 " .. player.Name .. " used command: " .. command)
            end
        end)
    end)
    
    -- Set up existing players
    for _, player in pairs(Players:GetPlayers()) do
        player.Chatted:Connect(function(message)
            local args = string.split(message:lower(), " ")
            local command = args[1]
            table.remove(args, 1)
            
            if commands[command] then
                commands[command](player, args)
                print("🎮 " .. player.Name .. " used command: " .. command)
            end
        end)
    end
    
    print("💬 Screen Effects Test Commands Available:")
    for command, _ in pairs(commands) do
        print("  " .. command)
    end
end

-- Auto-start testing system
function ScreenEffectsTest:AutoStart()
    wait(3) -- Wait for services to initialize
    
    print("🎬 Screen Effects Test System Ready!")
    print("📝 Available test functions:")
    print("  ScreenEffectsTest:TestAllEffects() - Run full test suite")
    print("  ScreenEffectsTest:TestPerformance() - Performance test")
    print("  ScreenEffectsTest:CreateTestCommands() - Enable chat commands")
    
    -- Enable chat commands by default
    self:CreateTestCommands()
    
    -- Auto-test if there are players
    if #Players:GetPlayers() > 0 then
        wait(2)
        -- Uncomment to auto-run tests
        -- self:TestAllEffects()
    end
end

-- Example integration with game events
function ScreenEffectsTest:SetupGameIntegration()
    -- Example: Trigger speed boost when player collects speed powerup
    -- Replace with your actual game logic
    
    Players.PlayerAdded:Connect(function(player)
        player.CharacterAdded:Connect(function(character)
            local humanoid = character:WaitForChild("Humanoid")
            
            -- Example: Speed boost when running fast
            spawn(function()
                while character.Parent do
                    wait(0.1)
                    if humanoid.WalkSpeed > 30 then -- If speed boosted
                        -- Could trigger screen effect here
                        -- ScreenEffectsService:TriggerSpeedBoost(player, 1.0)
                    end
                end
            end)
            
            -- Example: Jump effect on high jumps
            humanoid.Jumping:Connect(function()
                if humanoid.JumpPower > 50 then -- High jump
                    ScreenEffectsService:TriggerJump(player, humanoid.JumpPower / 50)
                end
            end)
        end)
    end)
end

-- Initialize
spawn(function()
    ScreenEffectsTest:AutoStart()
end)

return ScreenEffectsTest
