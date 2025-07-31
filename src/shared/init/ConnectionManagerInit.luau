-- ConnectionManagerInit.luau
-- Initialization script for the Connection Management System
-- Run this early in your game's startup sequence

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local ConnectionManager = require(ReplicatedStorage.Shared.core.ConnectionManager)

print("🔗 Initializing Connection Management System...")

-- Initialize the ConnectionManager
ConnectionManager:Initialize()

-- Set up game-wide cleanup on shutdown
game:BindToClose(function()
    print("🧹 Game shutting down - cleaning up all connections...")
    local cleanedCount = ConnectionManager:CleanupAllConnections()
    print("✅ Cleanup complete: " .. cleanedCount .. " connections cleaned")
end)

-- Set up periodic statistics reporting (optional)
spawn(function()
    while true do
        wait(300) -- Every 5 minutes
        
        local stats = ConnectionManager:GetStatistics()
        if stats.overview.totalConnections > 0 then
            print("📊 Connection Stats: " .. stats.overview.totalConnections .. " active, " .. 
                  stats.overview.memoryLeaksPreventend .. " leaks prevented")
        end
    end
end)

-- Set up emergency cleanup trigger (optional - for debugging)
local function setupEmergencyCleanup()
    -- Create a way to trigger emergency cleanup via RemoteEvent (server-side only)
    if RunService:IsServer() then
        local emergencyCleanupEvent = Instance.new("RemoteEvent")
        emergencyCleanupEvent.Name = "EmergencyCleanup"
        emergencyCleanupEvent.Parent = ReplicatedStorage
        
        emergencyCleanupEvent.OnServerEvent:Connect(function(player)
            -- Only allow specific players or roles to trigger this
            if player.Name == "YourUsername" or player:GetRankInGroup(0) >= 100 then
                warn("🚨 Emergency cleanup triggered by: " .. player.Name)
                local cleanedCount = ConnectionManager:CleanupAllConnections()
                warn("🧹 Emergency cleanup completed: " .. cleanedCount .. " connections cleaned")
            end
        end)
    end
end

setupEmergencyCleanup()

print("✅ Connection Management System initialized successfully")

-- Export the ConnectionManager for easy access
return ConnectionManager
