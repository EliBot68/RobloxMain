-- RemoteEventsSetup.luau
-- Comprehensive RemoteEvents creation and organization system
-- Creates and manages all RemoteEvents for Color Rush game
-- Use this script in ServerScriptService to initialize all events

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local RemoteEventsSetup = {}

-- RemoteEvents Configuration
local REMOTE_EVENTS_CONFIG = {
    -- Core Game Events (Prompt 12 Requirements)
    core = {
        "PlayerMovement",       -- Player movement data transmission
        "ObstacleHit",         -- Obstacle collision events
        "ScoreUpdate",         -- Score change notifications
        "GameStateChange",     -- Game state transitions
        "ColorSwitch"          -- Color switching events
    },
    
    -- Extended Game Events (from existing system)
    game = {
        "GameStateChanged",    -- Detailed game state changes
        "PlayerJoinedGame",    -- Player join notifications
        "PlayerLeftGame",      -- Player leave notifications
        "GameStarted",         -- Game start notifications
        "GameEnded",           -- Game end with results
        "CountdownUpdate",     -- Countdown timer updates
        "GameWarning",         -- Game warnings (time, etc.)
        "GameTimerUpdate",     -- Timer updates during game
        "PerformanceUpdate"    -- Performance metrics
    },
    
    -- Player Events
    player = {
        "PlayerWon",           -- Victory notifications
        "PlayerLost",          -- Defeat notifications
        "PlayerSpawned",       -- Spawn notifications
        "PlayerDied",          -- Death notifications
        "PlayerRespawned",     -- Respawn notifications
        "PlayerFinished",      -- Finish line events
        "PlayerEliminated",    -- Elimination events
        "PlayerRevived"        -- Revival events
    },
    
    -- Gameplay Events
    gameplay = {
        "CollectibleCollected", -- Collectible pickup events
        "PowerupActivated",     -- Powerup usage events
        "CheckpointReached",    -- Checkpoint progress
        "ComboUpdated",         -- Combo multiplier changes
        "HealthChanged",        -- Health status updates
        "LivesChanged",         -- Lives count updates
        "SpecialAbilityUsed"    -- Special ability activations
    },
    
    -- Request Events (Client to Server)
    requests = {
        "RequestJoinGame",      -- Join game queue
        "RequestLeaveGame",     -- Leave current game
        "RequestStartGame",     -- Admin start game
        "RequestRespawn",       -- Respawn request
        "RequestSpectate",      -- Spectator mode
        "RequestColorChange",   -- Manual color change
        "RequestPause",         -- Pause game request
        "RequestHelp"           -- Help/tutorial request
    },
    
    -- Admin Events
    admin = {
        "AdminCommand",         -- Admin commands
        "ServerStats",          -- Server statistics
        "AdminSetLives",        -- Admin set player lives
        "AdminSetScore",        -- Admin set player score
        "AdminTeleport",        -- Admin teleport player
        "AdminKick",            -- Admin kick player
        "AdminBan"              -- Admin ban player
    },
    
    -- UI Events
    ui = {
        "UIStateChanged",       -- UI state notifications
        "NotificationSent",     -- Notification events
        "MenuAction",           -- Menu interactions
        "SettingsChanged",      -- Settings updates
        "LeaderboardUpdate",    -- Leaderboard refresh
        "ShopPurchase"          -- Shop transactions
    }
}

-- RemoteFunctions Configuration
local REMOTE_FUNCTIONS_CONFIG = {
    -- Data requests
    data = {
        "GetPlayerData",        -- Retrieve player stats
        "GetGameData",          -- Retrieve game information
        "GetLeaderboard",       -- Retrieve leaderboard
        "GetShopItems",         -- Retrieve shop catalog
        "GetPlayerInventory"    -- Retrieve player items
    },
    
    -- Validation functions
    validation = {
        "ValidateMovement",     -- Validate player movement
        "ValidateScore",        -- Validate score changes
        "ValidatePurchase",     -- Validate shop purchases
        "ValidateAction"        -- Validate player actions
    }
}

function RemoteEventsSetup:Init()
    print("🔗 Initializing RemoteEvents Setup...")
    
    -- Create main folder structure
    self:CreateFolderStructure()
    
    -- Create all RemoteEvents
    self:CreateRemoteEvents()
    
    -- Create all RemoteFunctions
    self:CreateRemoteFunctions()
    
    -- Setup event organization
    self:OrganizeEvents()
    
    -- Validate setup
    self:ValidateSetup()
    
    print("✅ RemoteEvents Setup complete!")
    return self:GetEventReferences()
end

function RemoteEventsSetup:CreateFolderStructure()
    print("📁 Creating folder structure...")
    
    -- Main RemoteEvents folder
    local remoteEventsFolder = ReplicatedStorage:FindFirstChild("RemoteEvents")
    if not remoteEventsFolder then
        remoteEventsFolder = Instance.new("Folder")
        remoteEventsFolder.Name = "RemoteEvents"
        remoteEventsFolder.Parent = ReplicatedStorage
        print("✅ Created main RemoteEvents folder")
    else
        print("📁 RemoteEvents folder already exists")
    end
    
    -- Alternative folder name for compatibility
    local eventsFolder = ReplicatedStorage:FindFirstChild("Events")
    if not eventsFolder then
        eventsFolder = Instance.new("Folder")
        eventsFolder.Name = "Events"
        eventsFolder.Parent = ReplicatedStorage
        print("✅ Created Events folder for compatibility")
    end
    
    -- Create category subfolders for organization
    local categories = {"Core", "Game", "Player", "Gameplay", "Requests", "Admin", "UI", "Functions"}
    
    for _, category in pairs(categories) do
        local categoryFolder = remoteEventsFolder:FindFirstChild(category)
        if not categoryFolder then
            categoryFolder = Instance.new("Folder")
            categoryFolder.Name = category
            categoryFolder.Parent = remoteEventsFolder
        end
    end
    
    print("✅ Folder structure created!")
end

function RemoteEventsSetup:CreateRemoteEvents()
    print("🔗 Creating RemoteEvents...")
    
    local remoteEventsFolder = ReplicatedStorage:FindFirstChild("RemoteEvents")
    local eventsFolder = ReplicatedStorage:FindFirstChild("Events")
    
    local totalEvents = 0
    
    -- Create events by category
    for category, events in pairs(REMOTE_EVENTS_CONFIG) do
        print("📡 Creating " .. category .. " events...")
        
        local categoryFolder = remoteEventsFolder:FindFirstChild(string.upper(string.sub(category, 1, 1)) .. string.sub(category, 2))
        
        for _, eventName in pairs(events) do
            -- Create in main Events folder for compatibility
            local event = eventsFolder:FindFirstChild(eventName)
            if not event then
                event = Instance.new("RemoteEvent")
                event.Name = eventName
                event.Parent = eventsFolder
                totalEvents = totalEvents + 1
            end
            
            -- Create reference in category folder
            if categoryFolder then
                local categoryEvent = categoryFolder:FindFirstChild(eventName)
                if not categoryEvent then
                    categoryEvent = Instance.new("ObjectValue")
                    categoryEvent.Name = eventName
                    categoryEvent.Value = event
                    categoryEvent.Parent = categoryFolder
                end
            end
        end
    end
    
    print("✅ Created " .. totalEvents .. " RemoteEvents!")
end

function RemoteEventsSetup:CreateRemoteFunctions()
    print("🔧 Creating RemoteFunctions...")
    
    local remoteEventsFolder = ReplicatedStorage:FindFirstChild("RemoteEvents")
    local functionsFolder = remoteEventsFolder:FindFirstChild("Functions")
    
    local totalFunctions = 0
    
    for category, functions in pairs(REMOTE_FUNCTIONS_CONFIG) do
        print("⚙️ Creating " .. category .. " functions...")
        
        for _, functionName in pairs(functions) do
            local remoteFunction = functionsFolder:FindFirstChild(functionName)
            if not remoteFunction then
                remoteFunction = Instance.new("RemoteFunction")
                remoteFunction.Name = functionName
                remoteFunction.Parent = functionsFolder
                totalFunctions = totalFunctions + 1
            end
        end
    end
    
    print("✅ Created " .. totalFunctions .. " RemoteFunctions!")
end

function RemoteEventsSetup:OrganizeEvents()
    print("📋 Organizing events...")
    
    -- Create easy access references
    local eventsFolder = ReplicatedStorage:FindFirstChild("Events")
    
    -- Set up event attributes for easier identification
    for category, events in pairs(REMOTE_EVENTS_CONFIG) do
        for _, eventName in pairs(events) do
            local event = eventsFolder:FindFirstChild(eventName)
            if event then
                event:SetAttribute("Category", category)
                event:SetAttribute("Created", tick())
                event:SetAttribute("Type", "RemoteEvent")
            end
        end
    end
    
    print("✅ Events organized!")
end

function RemoteEventsSetup:ValidateSetup()
    print("✅ Validating RemoteEvents setup...")
    
    local eventsFolder = ReplicatedStorage:FindFirstChild("Events")
    local remoteEventsFolder = ReplicatedStorage:FindFirstChild("RemoteEvents")
    
    if not eventsFolder then
        warn("❌ Events folder not found!")
        return false
    end
    
    if not remoteEventsFolder then
        warn("❌ RemoteEvents folder not found!")
        return false
    end
    
    -- Validate core events (Prompt 12 requirements)
    local coreEvents = REMOTE_EVENTS_CONFIG.core
    local missingEvents = {}
    
    for _, eventName in pairs(coreEvents) do
        local event = eventsFolder:FindFirstChild(eventName)
        if not event then
            table.insert(missingEvents, eventName)
        end
    end
    
    if #missingEvents > 0 then
        warn("❌ Missing core events: " .. table.concat(missingEvents, ", "))
        return false
    end
    
    print("✅ All core events validated!")
    print("✅ RemoteEvents setup validation complete!")
    return true
end

function RemoteEventsSetup:GetEventReferences()
    print("📖 Creating event references...")
    
    local eventsFolder = ReplicatedStorage:FindFirstChild("Events")
    local events = {}
    
    -- Core events (Prompt 12)
    events.PlayerMovement = eventsFolder:FindFirstChild("PlayerMovement")
    events.ObstacleHit = eventsFolder:FindFirstChild("ObstacleHit")
    events.ScoreUpdate = eventsFolder:FindFirstChild("ScoreUpdate")
    events.GameStateChange = eventsFolder:FindFirstChild("GameStateChange")
    events.ColorSwitch = eventsFolder:FindFirstChild("ColorSwitch")
    
    -- Extended events
    events.GameStateChanged = eventsFolder:FindFirstChild("GameStateChanged")
    events.PlayerJoinedGame = eventsFolder:FindFirstChild("PlayerJoinedGame")
    events.PlayerLeftGame = eventsFolder:FindFirstChild("PlayerLeftGame")
    events.GameStarted = eventsFolder:FindFirstChild("GameStarted")
    events.GameEnded = eventsFolder:FindFirstChild("GameEnded")
    events.CountdownUpdate = eventsFolder:FindFirstChild("CountdownUpdate")
    events.GameTimerUpdate = eventsFolder:FindFirstChild("GameTimerUpdate")
    events.ScoreUpdated = eventsFolder:FindFirstChild("ScoreUpdate") -- Alias
    
    -- Player events
    events.PlayerWon = eventsFolder:FindFirstChild("PlayerWon")
    events.PlayerLost = eventsFolder:FindFirstChild("PlayerLost")
    events.PlayerDied = eventsFolder:FindFirstChild("PlayerDied")
    events.PlayerSpawned = eventsFolder:FindFirstChild("PlayerSpawned")
    events.PlayerFinished = eventsFolder:FindFirstChild("PlayerFinished")
    
    -- Gameplay events
    events.CollectibleCollected = eventsFolder:FindFirstChild("CollectibleCollected")
    events.PowerupActivated = eventsFolder:FindFirstChild("PowerupActivated")
    events.CheckpointReached = eventsFolder:FindFirstChild("CheckpointReached")
    events.ComboUpdated = eventsFolder:FindFirstChild("ComboUpdated")
    
    -- Request events
    events.RequestJoinGame = eventsFolder:FindFirstChild("RequestJoinGame")
    events.RequestLeaveGame = eventsFolder:FindFirstChild("RequestLeaveGame")
    events.RequestStartGame = eventsFolder:FindFirstChild("RequestStartGame")
    events.RequestRespawn = eventsFolder:FindFirstChild("RequestRespawn")
    events.RequestColorChange = eventsFolder:FindFirstChild("RequestColorChange")
    
    -- Admin events
    events.AdminCommand = eventsFolder:FindFirstChild("AdminCommand")
    events.ServerStats = eventsFolder:FindFirstChild("ServerStats")
    
    print("✅ Event references created!")
    return events
end

-- Utility functions for easy access
function RemoteEventsSetup:GetEvent(eventName)
    local eventsFolder = ReplicatedStorage:FindFirstChild("Events")
    return eventsFolder and eventsFolder:FindFirstChild(eventName)
end

function RemoteEventsSetup:GetFunction(functionName)
    local remoteEventsFolder = ReplicatedStorage:FindFirstChild("RemoteEvents")
    local functionsFolder = remoteEventsFolder and remoteEventsFolder:FindFirstChild("Functions")
    return functionsFolder and functionsFolder:FindFirstChild(functionName)
end

function RemoteEventsSetup:ListAllEvents()
    local eventsFolder = ReplicatedStorage:FindFirstChild("Events")
    if not eventsFolder then return {} end
    
    local eventsList = {}
    for _, child in pairs(eventsFolder:GetChildren()) do
        if child:IsA("RemoteEvent") then
            table.insert(eventsList, child.Name)
        end
    end
    
    return eventsList
end

function RemoteEventsSetup:GetEventsByCategory(category)
    local events = {}
    local categoryEvents = REMOTE_EVENTS_CONFIG[category]
    
    if categoryEvents then
        local eventsFolder = ReplicatedStorage:FindFirstChild("Events")
        for _, eventName in pairs(categoryEvents) do
            local event = eventsFolder:FindFirstChild(eventName)
            if event then
                events[eventName] = event
            end
        end
    end
    
    return events
end

-- Create summary of setup
function RemoteEventsSetup:PrintSummary()
    print("\n🔗 REMOTEEVENTS SETUP SUMMARY")
    print("=" .. string.rep("=", 40))
    
    -- Count events by category
    local totalEvents = 0
    for category, events in pairs(REMOTE_EVENTS_CONFIG) do
        local count = #events
        totalEvents = totalEvents + count
        print("📡 " .. string.upper(category) .. ": " .. count .. " events")
    end
    
    -- Count functions
    local totalFunctions = 0
    for category, functions in pairs(REMOTE_FUNCTIONS_CONFIG) do
        local count = #functions
        totalFunctions = totalFunctions + count
        print("⚙️ " .. string.upper(category) .. " Functions: " .. count)
    end
    
    print("=" .. string.rep("=", 40))
    print("📊 TOTAL: " .. totalEvents .. " RemoteEvents, " .. totalFunctions .. " RemoteFunctions")
    print("✅ Setup complete and ready for use!")
    print("=" .. string.rep("=", 40) .. "\n")
end

-- Auto-initialize if run directly
if RunService:IsServer() then
    RemoteEventsSetup:Init()
    RemoteEventsSetup:PrintSummary()
end

return RemoteEventsSetup
