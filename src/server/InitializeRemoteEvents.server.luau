-- InitializeRemoteEvents.server.luau
-- Server script to initialize all RemoteEvents
-- Place this in ServerScriptService

local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Wait for shared modules to load
local SharedModules = ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Modules")
local RemoteEventsSetup = require(SharedModules:WaitForChild("RemoteEventsSetup"))

-- Initialize the RemoteEvents system
print("🚀 Starting RemoteEvents initialization...")

local events = RemoteEventsSetup:Init()
RemoteEventsSetup:PrintSummary()

-- Expose events globally for easy access by other server scripts
_G.RemoteEvents = events
_G.GetRemoteEvent = function(eventName)
    return RemoteEventsSetup:GetEvent(eventName)
end
_G.GetRemoteFunction = function(functionName)
    return RemoteEventsSetup:GetFunction(functionName)
end

print("🌐 RemoteEvents now available globally via _G.RemoteEvents")
print("🔍 Use _G.GetRemoteEvent(name) to access specific events")
print("⚙️ Use _G.GetRemoteFunction(name) to access specific functions")
print("✅ RemoteEvents initialization complete!")

-- Test core events (Prompt 12 requirements)
local coreEvents = {
    "PlayerMovement",
    "ObstacleHit", 
    "ScoreUpdate",
    "GameStateChange",
    "ColorSwitch"
}

print("\n🧪 Testing core events...")
for _, eventName in pairs(coreEvents) do
    local event = _G.GetRemoteEvent(eventName)
    if event then
        print("✅ " .. eventName .. " - Ready")
    else
        warn("❌ " .. eventName .. " - Not found!")
    end
end
print("🧪 Core events test complete!\n")
