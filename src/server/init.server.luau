-- Server Main Entry Point
print("🚀 Color Rush Server starting...")

-- Core Roblox Services
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

-- Wait for shared modules to load
local SharedFolder = ReplicatedStorage:WaitForChild("Shared", 10)
if not SharedFolder then
    error("Failed to load shared modules!")
end

-- Get shared utilities
local _Shared = require(SharedFolder)
print("✅ Shared modules loaded")

-- Initialize essential game services locally
print("🔧 Initializing core services...")

-- Simple service initializer function
local function InitializeService(serviceName)
    local success, service = pcall(function()
        return require(ServerScriptService.Server.services[serviceName])
    end)
    
    if success and service then
        if service.Initialize then
            local initSuccess = pcall(function()
                service:Initialize()
            end)
            if initSuccess then
                print("✅", serviceName, "initialized")
                return service
            else
                warn("❌ Failed to initialize", serviceName)
            end
        else
            warn("⚠️", serviceName, "has no Initialize method")
        end
    else
        warn("❌ Failed to load", serviceName)
    end
    return nil
end

-- Initialize core services
local mainGameService = InitializeService("MainGameService")
local trackGeneratorService = InitializeService("TrackGeneratorService")
local performanceService = InitializeService("PerformanceService")

print("🎮 Color Rush Server initialization complete!")

-- Simple player join handling
Players.PlayerAdded:Connect(function(player)
    print("👋 Player joined:", player.Name)
    
    -- Basic player setup
    if mainGameService and mainGameService.OnPlayerJoined then
        pcall(function()
            mainGameService:OnPlayerJoined(player)
        end)
    end
end)

Players.PlayerRemoving:Connect(function(player)
    print("👋 Player leaving:", player.Name)
    
    -- Basic player cleanup
    if mainGameService and mainGameService.OnPlayerLeaving then
        pcall(function()
            mainGameService:OnPlayerLeaving(player)
        end)
    end
end)
