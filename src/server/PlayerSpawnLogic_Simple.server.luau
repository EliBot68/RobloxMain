-- PlayerSpawnLogic.server.luau
-- Simplified player spawn logic using Services module

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Import centralized Services module
local Services = require(ReplicatedStorage.Shared.core.Services)

local PlayerSpawnLogic = {}

function PlayerSpawnLogic:Initialize()
    print("👥 Initializing Player Spawn Logic...")
    
    -- Connect to player events
    Players.PlayerAdded:Connect(function(player)
        self:HandlePlayerAdded(player)
    end)
    
    Players.PlayerRemoving:Connect(function(player)
        self:HandlePlayerRemoving(player)
    end)
    
    print("✅ Player Spawn Logic initialized")
end

function PlayerSpawnLogic:HandlePlayerAdded(player)
    print("👋 Setting up player: " .. player.Name)
    
    -- Get core services
    local dataService = Services.Get("DataService")
    local playerService = Services.Get("PlayerService")
    local mainController = Services.Get("MainGameController")
    
    -- Load player data first
    if dataService and dataService.LoadPlayerData then
        dataService:LoadPlayerData(player)
    end
    
    -- Setup player in services
    if playerService and playerService.SetupPlayer then
        playerService:SetupPlayer(player)
    end
    
    -- Add player to game controller
    if mainController and mainController.OnPlayerJoined then
        mainController:OnPlayerJoined(player)
    end
    
    -- Handle character spawning
    player.CharacterAdded:Connect(function(character)
        self:HandleCharacterAdded(player, character)
    end)
    
    -- Handle existing character
    if player.Character then
        self:HandleCharacterAdded(player, player.Character)
    end
end

function PlayerSpawnLogic:HandleCharacterAdded(player, character)
    print("👨‍🎮 Character spawned for: " .. player.Name)
    
    -- Wait for essential components
    local humanoid = character:WaitForChild("Humanoid", 10)
    local humanoidRootPart = character:WaitForChild("HumanoidRootPart", 10)
    
    if not humanoid or not humanoidRootPart then
        warn("❌ Failed to load character components for: " .. player.Name)
        return
    end
    
    -- Notify services
    local mainController = Services.Get("MainGameController")
    if mainController and mainController.OnPlayerCharacterAdded then
        mainController:OnPlayerCharacterAdded(player, character)
    end
    
    local collisionController = Services.Get("CollisionController")
    if collisionController and collisionController.SetupPlayerCollision then
        collisionController:SetupPlayerCollision(player, character)
    end
end

function PlayerSpawnLogic:HandlePlayerRemoving(player)
    print("👋 Cleaning up player: " .. player.Name)
    
    -- Get core services
    local dataService = Services.Get("DataService")
    local playerService = Services.Get("PlayerService")
    local mainController = Services.Get("MainGameController")
    
    -- Save player data
    if dataService and dataService.SavePlayerData then
        dataService:SavePlayerData(player)
    end
    
    -- Cleanup in services
    if playerService and playerService.CleanupPlayer then
        playerService:CleanupPlayer(player)
    end
    
    if mainController and mainController.OnPlayerRemoving then
        mainController:OnPlayerRemoving(player)
    end
end

-- Initialize automatically
PlayerSpawnLogic:Initialize()

return PlayerSpawnLogic
