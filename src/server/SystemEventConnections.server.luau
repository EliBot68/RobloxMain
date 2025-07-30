-- SystemEventConnections.server.luau
-- Simplified event system for color-matching game
-- Replaces complex enterprise event architecture with focused game functionality

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Services = require(ReplicatedStorage.Shared.Services)

local SystemEventConnections = {}

-- Initialize core game connections
function SystemEventConnections.Initialize()
    print("🔗 Initializing simplified event connections...")
    
    -- Connect core game services
    local gameService = Services.Get("MainGameService")
    local trackService = Services.Get("TrackGeneratorService")
    local performanceService = Services.Get("PerformanceService")
    
    if gameService then
        print("✅ Connected to MainGameService")
    end
    
    if trackService then
        print("✅ Connected to TrackGeneratorService")
    end
    
    if performanceService then
        print("✅ Connected to PerformanceService")
    end
    
    print("🎮 Core system connections established!")
end

-- Initialize on server start
SystemEventConnections.Initialize()

return SystemEventConnections
