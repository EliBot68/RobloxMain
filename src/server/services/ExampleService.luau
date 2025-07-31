-- ExampleService.luau
-- Example service demonstrating proper ConnectionManager usage
-- This shows how to prevent memory leaks in a typical game service

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local _Players = game:GetService("Players")
local _RunService = game:GetService("RunService")

local ServiceConnectionHelper = require(ReplicatedStorage.Shared.utils.ServiceConnectionHelper)
local RemoteEvents = require(ReplicatedStorage.Shared.modules.RemoteEvents)

local ExampleService = {}

-- Create service-specific connection helper
local connectionHelper = ServiceConnectionHelper.CreateServiceHelper("ExampleService")

-- Service state
local activePlayers = {}
local gameLoopRunning = false

function ExampleService:Initialize()
    print("🚀 ExampleService initializing with proper connection management...")
    
    -- Set up player lifecycle management with automatic cleanup
    self:SetupPlayerManagement()
    
    -- Set up remote event handlers with managed connections
    self:SetupRemoteEventHandlers()
    
    -- Set up game loop with managed heartbeat connection
    self:SetupGameLoop()
    
    -- Set up automatic cleanup on shutdown
    connectionHelper:AddToShutdownSequence()
    
    print("✅ ExampleService initialized successfully")
end

function ExampleService:SetupPlayerManagement()
    -- Connect to PlayerAdded with automatic tracking
    connectionHelper:ConnectPlayerEvent("PlayerAdded", function(player)
        self:OnPlayerJoined(player)
    end, {
        description = "Player joining handler",
        connectionType = "PLAYER_EVENT"
    })
    
    -- Connect to PlayerRemoving with automatic cleanup
    connectionHelper:ConnectPlayerEvent("PlayerRemoving", function(player)
        self:OnPlayerLeaving(player)
    end, {
        description = "Player leaving handler", 
        connectionType = "PLAYER_EVENT"
    })
end

function ExampleService:SetupRemoteEventHandlers()
    -- Example: Connect to a quest update remote event
    if RemoteEvents.UpdateQuestProgress then
        connectionHelper:ConnectRemoteEvent(RemoteEvents.UpdateQuestProgress, function(player, questId, progress, data)
            self:HandleQuestUpdate(player, questId, progress, data)
        end, {
            description = "Quest progress update handler"
        })
    end
    
    -- Example: Connect to player data update remote event
    if RemoteEvents.PlayerDataUpdated then
        connectionHelper:ConnectRemoteEvent(RemoteEvents.PlayerDataUpdated, function(player, dataType, newData)
            self:HandlePlayerDataUpdate(player, dataType, newData)
        end, {
            description = "Player data update handler"
        })
    end
end

function ExampleService:SetupGameLoop()
    -- Main game loop with managed connection
    connectionHelper:ConnectRunServiceEvent("Heartbeat", function(deltaTime)
        if gameLoopRunning then
            self:UpdateGameState(deltaTime)
        end
    end, {
        description = "Main game loop heartbeat",
        connectionType = "HEARTBEAT"
    })
    
    gameLoopRunning = true
end

function ExampleService:OnPlayerJoined(player)
    print("👋 Player joined: " .. player.Name)
    
    -- Initialize player data
    activePlayers[player] = {
        joinTime = tick(),
        connections = {}
    }
    
    -- Set up player-specific connections
    self:SetupPlayerConnections(player)
end

function ExampleService:SetupPlayerConnections(player)
    -- Example: Character spawning handler
    connectionHelper:ConnectPlayerCharacterEvent(player, "CharacterAdded", function(character)
        self:OnCharacterSpawned(player, character)
    end, {
        description = "Character spawn handler for " .. player.Name
    })
    
    -- Example: Character dying handler  
    connectionHelper:ConnectPlayerCharacterEvent(player, "CharacterRemoving", function(character)
        self:OnCharacterDespawned(player, character)
    end, {
        description = "Character despawn handler for " .. player.Name
    })
    
    -- Example: Connect to player's GUI events if they exist
    spawn(function()
        local playerGui = player:WaitForChild("PlayerGui", 10)
        if playerGui then
            self:SetupPlayerGUI(player, playerGui)
        end
    end)
end

function ExampleService:SetupPlayerGUI(player, playerGui)
    -- Wait for specific GUI elements and connect to them
    local questGui = playerGui:WaitForChild("QuestGUI", 5)
    if questGui then
        local questButton = questGui:WaitForChild("QuestButton", 5)
        if questButton then
            connectionHelper:ConnectGUIEvent(questButton, "MouseButton1Click", function()
                self:HandleQuestButtonClicked(player)
            end, {
                player = player,
                description = "Quest button click for " .. player.Name
            })
        end
    end
end

function ExampleService:OnPlayerLeaving(player)
    print("👋 Player leaving: " .. player.Name)
    
    -- Clean up player data
    if activePlayers[player] then
        activePlayers[player] = nil
    end
    
    -- Note: Player-specific connections are automatically cleaned up by ConnectionManager
    print("✅ Player " .. player.Name .. " cleanup completed")
end

function ExampleService:OnCharacterSpawned(player, character)
    print("🏃 Character spawned for: " .. player.Name)
    
    -- Example: Set up character-specific connections
    local humanoid = character:WaitForChild("Humanoid", 5)
    if humanoid then
        connectionHelper:TrackConnection(humanoid.Died:Connect(function()
            self:OnCharacterDied(player, character)
        end), {
            player = player,
            description = "Humanoid death handler for " .. player.Name,
            connectionType = "PLAYER_EVENT"
        })
    end
    
    -- Example: Set up collision detection
    local rootPart = character:WaitForChild("HumanoidRootPart", 5)
    if rootPart then
        connectionHelper:ConnectTouchEvent(rootPart, function(hit, touchingPlayer, touchingCharacter)
            if touchingPlayer ~= player then
                self:OnPlayerCollision(player, touchingPlayer)
            end
        end, 1.0, { -- 1 second debounce
            player = player,
            description = "Player collision detection for " .. player.Name
        })
    end
end

function ExampleService:OnCharacterDespawned(player, character)
    print("💀 Character despawned for: " .. player.Name)
    -- Character-specific connections are automatically cleaned up
end

function ExampleService:OnCharacterDied(player, character)
    print("☠️ Character died: " .. player.Name)
    -- Handle character death logic here
end

function ExampleService:OnPlayerCollision(player1, player2)
    print("💥 Player collision: " .. player1.Name .. " touched " .. player2.Name)
    -- Handle player collision logic here
end

function ExampleService:HandleQuestUpdate(player, questId, progress, data)
    print("📋 Quest update for " .. player.Name .. ": " .. questId .. " -> " .. tostring(progress))
    -- Handle quest update logic here
end

function ExampleService:HandlePlayerDataUpdate(player, dataType, newData)
    print("💾 Data update for " .. player.Name .. ": " .. dataType)
    -- Handle player data update logic here
end

function ExampleService:HandleQuestButtonClicked(player)
    print("🔘 Quest button clicked by: " .. player.Name)
    -- Handle quest button click logic here
end

function ExampleService:UpdateGameState(deltaTime)
    -- Example game loop logic
    -- This runs every frame but connections are managed properly
    
    -- Process active players
    local currentTime = tick()
    for player, data in pairs(activePlayers) do
        -- Example: Check if player has been idle too long
        if currentTime - data.joinTime > 300 then -- 5 minutes
            -- Handle idle player logic
        end
    end
end

function ExampleService:GetConnectionStatistics()
    return connectionHelper:GetStatistics()
end

function ExampleService:ForceCleanup()
    print("🧹 Forcing ExampleService cleanup...")
    
    -- Stop game loop
    gameLoopRunning = false
    
    -- Clean up all connections
    local cleanedCount = connectionHelper:CleanupAll()
    
    -- Clear service state
    activePlayers = {}
    
    print("✅ ExampleService cleanup completed: " .. cleanedCount .. " connections cleaned")
    return cleanedCount
end

-- Diagnostic method to check for memory leaks
function ExampleService:DiagnosticCheck()
    local stats = connectionHelper:GetStatistics()
    print("🔍 ExampleService Diagnostic Report:")
    print("  Total Connections: " .. stats.totalConnections)
    print("  Active Players: " .. (#activePlayers))
    print("  Game Loop Running: " .. tostring(gameLoopRunning))
    
    -- Check for potential issues
    if stats.totalConnections > #activePlayers * 10 then
        warn("⚠️ High connection count per player detected - possible memory leak")
    end
    
    return stats
end

return ExampleService
