-- RemoteEventsClient.luau
-- Client module for accessing RemoteEvents
-- Use in LocalScripts to connect to server events

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer

local RemoteEventsClient = {}
RemoteEventsClient.__index = RemoteEventsClient

-- Wait for events to be created by server
local function waitForEventsFolder()
    local eventsFolder = ReplicatedStorage:WaitForChild("Events", 30)
    if not eventsFolder then
        error("❌ Events folder not found in ReplicatedStorage! Make sure server script is running.")
    end
    return eventsFolder
end

local eventsFolder = waitForEventsFolder()

-- Core Events Cache (Prompt 12 requirements)
local CORE_EVENTS = {
    PlayerMovement = nil,
    ObstacleHit = nil,
    ScoreUpdate = nil,
    GameStateChange = nil,
    ColorSwitch = nil
}

-- Extended Events Cache
local EXTENDED_EVENTS = {
    GameStateChanged = nil,
    PlayerJoinedGame = nil,
    PlayerLeftGame = nil,
    GameStarted = nil,
    GameEnded = nil,
    CountdownUpdate = nil,
    GameTimerUpdate = nil,
    PlayerWon = nil,
    PlayerLost = nil,
    PlayerDied = nil,
    PlayerSpawned = nil,
    PlayerFinished = nil,
    CollectibleCollected = nil,
    PowerupActivated = nil,
    CheckpointReached = nil,
    ComboUpdated = nil,
    UIStateChanged = nil,
    NotificationSent = nil,
    LeaderboardUpdate = nil
}

-- Connection storage for cleanup
local connections = {}

function RemoteEventsClient.new()
    local self = setmetatable({}, RemoteEventsClient)
    self:CacheEvents()
    return self
end

function RemoteEventsClient:CacheEvents()
    print("🔗 Caching RemoteEvents for client access...")
    
    -- Cache core events
    for eventName, _ in pairs(CORE_EVENTS) do
        local event = eventsFolder:WaitForChild(eventName, 5)
        if event then
            CORE_EVENTS[eventName] = event
            print("✅ Cached core event: " .. eventName)
        else
            warn("⚠️ Core event not found: " .. eventName)
        end
    end
    
    -- Cache extended events
    for eventName, _ in pairs(EXTENDED_EVENTS) do
        local event = eventsFolder:FindFirstChild(eventName)
        if event then
            EXTENDED_EVENTS[eventName] = event
            print("✅ Cached extended event: " .. eventName)
        end
    end
    
    print("✅ Event caching complete!")
end

-- Core Event Access Functions (Prompt 12)
function RemoteEventsClient:GetPlayerMovement()
    return CORE_EVENTS.PlayerMovement
end

function RemoteEventsClient:GetObstacleHit()
    return CORE_EVENTS.ObstacleHit
end

function RemoteEventsClient:GetScoreUpdate()
    return CORE_EVENTS.ScoreUpdate
end

function RemoteEventsClient:GetGameStateChange()
    return CORE_EVENTS.GameStateChange
end

function RemoteEventsClient:GetColorSwitch()
    return CORE_EVENTS.ColorSwitch
end

-- Generic event getter
function RemoteEventsClient:GetEvent(eventName)
    -- Check core events first
    if CORE_EVENTS[eventName] then
        return CORE_EVENTS[eventName]
    end
    
    -- Check extended events
    if EXTENDED_EVENTS[eventName] then
        return EXTENDED_EVENTS[eventName]
    end
    
    -- Fall back to direct lookup
    return eventsFolder:FindFirstChild(eventName)
end

-- Event Connection Helpers
function RemoteEventsClient:ConnectToEvent(eventName, callback)
    local event = self:GetEvent(eventName)
    if event then
        local connection = event.OnClientEvent:Connect(callback)
        
        -- Store connection for cleanup
        if not connections[eventName] then
            connections[eventName] = {}
        end
        table.insert(connections[eventName], connection)
        
        print("🔗 Connected to event: " .. eventName)
        return connection
    else
        warn("❌ Event not found: " .. eventName)
        return nil
    end
end

function RemoteEventsClient:DisconnectFromEvent(eventName)
    if connections[eventName] then
        for _, connection in pairs(connections[eventName]) do
            connection:Disconnect()
        end
        connections[eventName] = {}
        print("🔌 Disconnected from event: " .. eventName)
    end
end

function RemoteEventsClient:DisconnectAll()
    for eventName, eventConnections in pairs(connections) do
        for _, connection in pairs(eventConnections) do
            connection:Disconnect()
        end
    end
    connections = {}
    print("🔌 Disconnected from all events")
end

-- Fire Events to Server
function RemoteEventsClient:FireServer(eventName, ...)
    local event = self:GetEvent(eventName)
    if event then
        event:FireServer(...)
        print("📡 Fired event to server: " .. eventName)
    else
        warn("❌ Cannot fire event - not found: " .. eventName)
    end
end

-- Core Event Firing Functions (Prompt 12)
function RemoteEventsClient:FirePlayerMovement(movementData)
    if CORE_EVENTS.PlayerMovement then
        CORE_EVENTS.PlayerMovement:FireServer(movementData)
    else
        warn("❌ PlayerMovement event not available")
    end
end

function RemoteEventsClient:FireObstacleHit(obstacleData)
    if CORE_EVENTS.ObstacleHit then
        CORE_EVENTS.ObstacleHit:FireServer(obstacleData)
    else
        warn("❌ ObstacleHit event not available")
    end
end

function RemoteEventsClient:FireColorSwitch(newColor)
    if CORE_EVENTS.ColorSwitch then
        CORE_EVENTS.ColorSwitch:FireServer(newColor)
    else
        warn("❌ ColorSwitch event not available")
    end
end

-- Convenience Functions for Common Patterns
function RemoteEventsClient:OnGameStateChange(callback)
    return self:ConnectToEvent("GameStateChange", callback)
end

function RemoteEventsClient:OnScoreUpdate(callback)
    return self:ConnectToEvent("ScoreUpdate", callback)
end

function RemoteEventsClient:OnGameStarted(callback)
    return self:ConnectToEvent("GameStarted", callback)
end

function RemoteEventsClient:OnGameEnded(callback)
    return self:ConnectToEvent("GameEnded", callback)
end

function RemoteEventsClient:OnCountdownUpdate(callback)
    return self:ConnectToEvent("CountdownUpdate", callback)
end

function RemoteEventsClient:OnPlayerDied(callback)
    return self:ConnectToEvent("PlayerDied", callback)
end

function RemoteEventsClient:OnPlayerWon(callback)
    return self:ConnectToEvent("PlayerWon", callback)
end

function RemoteEventsClient:OnPlayerLost(callback)
    return self:ConnectToEvent("PlayerLost", callback)
end

-- Request Functions (Client to Server)
function RemoteEventsClient:RequestJoinGame(gameMode)
    self:FireServer("RequestJoinGame", gameMode or "normal")
end

function RemoteEventsClient:RequestLeaveGame()
    self:FireServer("RequestLeaveGame")
end

function RemoteEventsClient:RequestRespawn()
    self:FireServer("RequestRespawn")
end

function RemoteEventsClient:RequestColorChange(color)
    self:FireServer("RequestColorChange", color)
end

-- Utility Functions
function RemoteEventsClient:ListAvailableEvents()
    local events = {}
    for _, event in pairs(eventsFolder:GetChildren()) do
        if event:IsA("RemoteEvent") then
            table.insert(events, event.Name)
        end
    end
    return events
end

function RemoteEventsClient:PrintAvailableEvents()
    print("\n📡 Available RemoteEvents:")
    print("=" .. string.rep("=", 30))
    
    -- Core events
    print("🎯 CORE EVENTS (Prompt 12):")
    for eventName, event in pairs(CORE_EVENTS) do
        local status = event and "✅" or "❌"
        print("  " .. status .. " " .. eventName)
    end
    
    -- Extended events  
    print("\n🎮 EXTENDED EVENTS:")
    for eventName, event in pairs(EXTENDED_EVENTS) do
        if event then
            print("  ✅ " .. eventName)
        end
    end
    
    print("=" .. string.rep("=", 30) .. "\n")
end

-- Auto-cleanup when player leaves
game.Players.PlayerRemoving:Connect(function(leavingPlayer)
    if leavingPlayer == player then
        RemoteEventsClient:DisconnectAll()
    end
end)

return RemoteEventsClient
