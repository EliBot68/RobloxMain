-- Server Main Entry Point
print("🚀 Color Rush Server starting...")

-- Core Roblox Services
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

-- Import Services for clean dependency management
local Services = require(game.ReplicatedStorage.Shared.core.Services)

-- Initialize essential game services
print("🔧 Initializing core services...")

-- Initialize Services system on server
Services.Initialize()

-- Initialize main game service
local MainGameService = Services.Get("MainGameService")
if MainGameService and MainGameService.Initialize then
    MainGameService:Initialize()
    print("✅ MainGameService initialized")
end

-- Initialize track generator
local TrackGeneratorService = Services.Get("TrackGeneratorService") 
if TrackGeneratorService and TrackGeneratorService.Initialize then
    TrackGeneratorService:Initialize()
    print("✅ TrackGeneratorService initialized")
end

-- Initialize performance monitoring
local PerformanceService = Services.Get("PerformanceService")
if PerformanceService and PerformanceService.Initialize then
    PerformanceService:Initialize()
    print("✅ PerformanceService initialized")
end

print("🎮 Color Rush Server initialization complete!")
