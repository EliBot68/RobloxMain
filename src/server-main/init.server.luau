-- Streamlined Server Entry Point - FIXED AND WORKING!
print("🚀 Streamlined Color Rush Server starting... LIVE SYNC TEST!")

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Basic game state
local GameState = {
    playersConnected = 0,
    gameStarted = false
}

-- Simple player management
Players.PlayerAdded:Connect(function(player)
    GameState.playersConnected = GameState.playersConnected + 1
    print("👤 Player joined:", player.Name, "| Total players:", GameState.playersConnected)
    
    -- Simple welcome
    player.CharacterAdded:Connect(function(character)
        print("🏃 Character spawned for:", player.Name)
    end)
end)

Players.PlayerRemoving:Connect(function(player)
    GameState.playersConnected = GameState.playersConnected - 1
    print("👋 Player left:", player.Name, "| Total players:", GameState.playersConnected)
end)

-- Simple game loop
local function startGameLoop()
    print("🎮 Starting basic game loop...")
    
    task.spawn(function()
        while true do
            task.wait(5) -- Every 5 seconds
            if GameState.playersConnected > 0 then
                print("💓 Server heartbeat - Players:", GameState.playersConnected)
            end
        end
    end)
end

-- Initialize everything
print("� Initializing streamlined server...")
startGameLoop()
print("✅ Server ready for players!")
print("🔧 Live sync is working - make edits to see changes!")
