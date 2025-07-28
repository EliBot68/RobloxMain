-- PlayerSpawnLogic.server.luau
-- Enhanced player spawn logic coordination
-- Manages comprehensive player initialization across all services

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local PlayerSpawnLogic = {}

-- Spawn tracking
local PlayerSpawnStatus = {}
local SpawnTimeouts = {}

-- Configuration
local SPAWN_CONFIG = {
    enableDetailedLogging = true,
    spawnTimeout = 30,
    characterLoadTimeout = 10,
    retryFailedSpawns = true,
    maxRetryAttempts = 3,
    spawnRetryDelay = 2
}

-- Spawn phases
local SPAWN_PHASES = {
    "PLAYER_JOINING",
    "SERVICES_NOTIFICATION", 
    "DATA_LOADING",
    "CHARACTER_SETUP",
    "GAME_PREPARATION",
    "SPAWN_COMPLETE"
}

function PlayerSpawnLogic:Initialize()
    print("👥 Initializing Enhanced Player Spawn Logic...")
    
    -- Connect to player events
    Players.PlayerAdded:Connect(function(player)
        self:HandlePlayerSpawn(player)
    end)
    
    Players.PlayerRemoving:Connect(function(player)
        self:HandlePlayerDespawn(player)
    end)
    
    -- Handle existing players
    for _, player in pairs(Players:GetPlayers()) do
        spawn(function()
            self:HandlePlayerSpawn(player)
        end)
    end
    
    print("✅ Enhanced Player Spawn Logic initialized")
    return true
end

function PlayerSpawnLogic:HandlePlayerSpawn(player)
    local spawnId = player.UserId .. "_" .. tick()
    
    if SPAWN_CONFIG.enableDetailedLogging then
        print("🎮 Starting enhanced spawn sequence for: " .. player.Name .. " (ID: " .. spawnId .. ")")
    end
    
    -- Initialize spawn status tracking
    PlayerSpawnStatus[player.UserId] = {
        player = player,
        spawnId = spawnId,
        currentPhase = "PLAYER_JOINING",
        startTime = tick(),
        phaseTimestamps = {},
        retryCount = 0,
        success = false
    }
    
    -- Start spawn timeout
    SpawnTimeouts[player.UserId] = spawn(function()
        wait(SPAWN_CONFIG.spawnTimeout)
        if PlayerSpawnStatus[player.UserId] and not PlayerSpawnStatus[player.UserId].success then
            warn("⏰ Player spawn timeout for: " .. player.Name)
            self:HandleSpawnTimeout(player)
        end
    end)
    
    -- Execute spawn sequence
    self:ExecuteSpawnSequence(player)
end

function PlayerSpawnLogic:ExecuteSpawnSequence(player)
    local status = PlayerSpawnStatus[player.UserId]
    if not status then return end
    
    -- Phase 1: Player Joining
    self:SetSpawnPhase(player, "PLAYER_JOINING")
    if not self:ExecutePlayerJoiningPhase(player) then
        return self:HandleSpawnFailure(player, "Player joining phase failed")
    end
    
    -- Phase 2: Services Notification
    self:SetSpawnPhase(player, "SERVICES_NOTIFICATION")
    if not self:ExecuteServicesNotificationPhase(player) then
        return self:HandleSpawnFailure(player, "Services notification phase failed")
    end
    
    -- Phase 3: Data Loading
    self:SetSpawnPhase(player, "DATA_LOADING")
    if not self:ExecuteDataLoadingPhase(player) then
        return self:HandleSpawnFailure(player, "Data loading phase failed")
    end
    
    -- Phase 4: Character Setup
    self:SetSpawnPhase(player, "CHARACTER_SETUP")
    self:ExecuteCharacterSetupPhase(player)
    
    -- Phase 5: Game Preparation
    self:SetSpawnPhase(player, "GAME_PREPARATION")
    if not self:ExecuteGamePreparationPhase(player) then
        return self:HandleSpawnFailure(player, "Game preparation phase failed")
    end
    
    -- Phase 6: Spawn Complete
    self:SetSpawnPhase(player, "SPAWN_COMPLETE")
    self:ExecuteSpawnCompletePhase(player)
end

function PlayerSpawnLogic:SetSpawnPhase(player, phase)
    local status = PlayerSpawnStatus[player.UserId]
    if not status then return end
    
    status.currentPhase = phase
    status.phaseTimestamps[phase] = tick()
    
    if SPAWN_CONFIG.enableDetailedLogging then
        print("📋 " .. player.Name .. " → " .. phase)
    end
end

-- ========================================
-- SPAWN PHASE IMPLEMENTATIONS
-- ========================================

function PlayerSpawnLogic:ExecutePlayerJoiningPhase(player)
    -- Basic player validation
    if not player or not player.Parent then
        warn("❌ Invalid player object")
        return false
    end
    
    -- Track join analytics
    local analyticsService = _G.GetAnalyticsService()
    if analyticsService then
        analyticsService:TrackEvent(player, "player_join_started", {
            timestamp = tick(),
            playerName = player.Name,
            userId = player.UserId,
            accountAge = player.AccountAge
        })
    end
    
    return true
end

function PlayerSpawnLogic:ExecuteServicesNotificationPhase(player)
    local services = {
        {"GameService", "OnPlayerAdded"},
        {"MainGameController", "OnPlayerAdded"},
        {"DifficultyService", "OnPlayerAdded"},
        {"CollisionController", "OnPlayerAdded"},
        {"RecordingSessionManager", "SetupPlayerForRecording"},
        {"MovingObstacleService", "OnPlayerAdded"}
    }
    
    local notificationResults = {}
    
    for _, serviceInfo in ipairs(services) do
        local serviceName, methodName = serviceInfo[1], serviceInfo[2]
        local service = _G.GetCoreService and _G.GetCoreService(serviceName) or _G["Get" .. serviceName] and _G["Get" .. serviceName]()
        
        if service and service[methodName] then
            local success, error = pcall(function()
                service[methodName](service, player)
            end)
            
            notificationResults[serviceName] = success
            
            if success then
                if SPAWN_CONFIG.enableDetailedLogging then
                    print("✅ " .. serviceName .. " notified of player: " .. player.Name)
                end
            else
                warn("❌ Failed to notify " .. serviceName .. ": " .. tostring(error))
            end
        else
            warn("⚠️ " .. serviceName .. " not available or missing method: " .. methodName)
            notificationResults[serviceName] = false
        end
    end
    
    -- Check if critical services were notified
    local criticalServices = {"GameService", "MainGameController"}
    for _, serviceName in ipairs(criticalServices) do
        if not notificationResults[serviceName] then
            warn("❌ Critical service notification failed: " .. serviceName)
            return false
        end
    end
    
    return true
end

function PlayerSpawnLogic:ExecuteDataLoadingPhase(player)
    -- Load player data through GameService
    local gameService = _G.GetGameService()
    if gameService then
        if gameService.LoadPlayerData then
            local success, playerData = pcall(function()
                return gameService:LoadPlayerData(player)
            end)
            
            if success and playerData then
                if SPAWN_CONFIG.enableDetailedLogging then
                    print("✅ Player data loaded for: " .. player.Name)
                end
                return true
            else
                warn("❌ Failed to load player data: " .. tostring(playerData))
                return false
            end
        else
            -- If no LoadPlayerData method, assume data loading is handled elsewhere
            return true
        end
    else
        warn("❌ GameService not available for data loading")
        return false
    end
end

function PlayerSpawnLogic:ExecuteCharacterSetupPhase(player)
    -- Setup character spawning handler
    local characterConnection
    characterConnection = player.CharacterAdded:Connect(function(character)
        self:HandleCharacterSpawned(player, character)
        characterConnection:Disconnect()
    end)
    
    -- Handle existing character
    if player.Character then
        spawn(function()
            self:HandleCharacterSpawned(player, player.Character)
        end)
    end
    
    return true
end

function PlayerSpawnLogic:HandleCharacterSpawned(player, character)
    if SPAWN_CONFIG.enableDetailedLogging then
        print("👨‍🎮 Character spawned for: " .. player.Name)
    end
    
    -- Wait for essential character components
    local humanoid = character:WaitForChild("Humanoid", SPAWN_CONFIG.characterLoadTimeout)
    local humanoidRootPart = character:WaitForChild("HumanoidRootPart", SPAWN_CONFIG.characterLoadTimeout)
    
    if not humanoid or not humanoidRootPart then
        warn("❌ Character components missing for: " .. player.Name)
        return false
    end
    
    -- Notify services about character spawn
    self:NotifyServicesCharacterSpawned(player, character)
    
    -- Setup collision detection
    local collisionController = _G.GetCollisionController()
    if collisionController then
        if collisionController.SetupPlayerForCollision then
            collisionController:SetupPlayerForCollision(player, character)
        end
        
        if collisionController.EnablePlayerCollision then
            collisionController:EnablePlayerCollision(player)
        end
    end
    
    -- Continue with game preparation
    self:ContinueToGamePreparation(player)
    
    return true
end

function PlayerSpawnLogic:NotifyServicesCharacterSpawned(player, character)
    local services = {
        {"MainGameController", "OnPlayerCharacterAdded"},
        {"CollisionController", "OnPlayerCharacterAdded"},
        {"GameService", "OnPlayerCharacterAdded"},
        {"RecordingSessionManager", "OnPlayerCharacterAdded"}
    }
    
    for _, serviceInfo in ipairs(services) do
        local serviceName, methodName = serviceInfo[1], serviceInfo[2]
        local service = _G.GetCoreService and _G.GetCoreService(serviceName) or _G["Get" .. serviceName] and _G["Get" .. serviceName]()
        
        if service and service[methodName] then
            pcall(function()
                service[methodName](service, player, character)
            end)
        end
    end
end

function PlayerSpawnLogic:ContinueToGamePreparation(player)
    -- Continue spawn sequence after character is ready
    spawn(function()
        wait(0.5) -- Small delay to ensure character is fully set up
        
        if PlayerSpawnStatus[player.UserId] and PlayerSpawnStatus[player.UserId].currentPhase == "CHARACTER_SETUP" then
            -- Phase 5: Game Preparation
            self:SetSpawnPhase(player, "GAME_PREPARATION")
            if not self:ExecuteGamePreparationPhase(player) then
                return self:HandleSpawnFailure(player, "Game preparation phase failed")
            end
            
            -- Phase 6: Spawn Complete
            self:SetSpawnPhase(player, "SPAWN_COMPLETE")
            self:ExecuteSpawnCompletePhase(player)
        end
    end)
end

function PlayerSpawnLogic:ExecuteGamePreparationPhase(player)
    -- Prepare player for gameplay
    local mainController = _G.GetMainGameController()
    if mainController then
        if mainController.PreparePlayerForGame then
            local success, error = pcall(function()
                mainController:PreparePlayerForGame(player)
            end)
            
            if not success then
                warn("❌ Failed to prepare player for game: " .. tostring(error))
                return false
            end
        end
        
        if mainController.SetupPlayerUI then
            pcall(function()
                mainController:SetupPlayerUI(player)
            end)
        end
    end
    
    -- Setup track generation for player
    local trackGenerator = _G.GetTrackGeneratorService()
    if trackGenerator and trackGenerator.PreparePlayerTrack then
        pcall(function()
            trackGenerator:PreparePlayerTrack(player)
        end)
    end
    
    return true
end

function PlayerSpawnLogic:ExecuteSpawnCompletePhase(player)
    local status = PlayerSpawnStatus[player.UserId]
    if not status then return end
    
    -- Mark spawn as successful
    status.success = true
    status.completionTime = tick()
    status.totalDuration = status.completionTime - status.startTime
    
    -- Cancel timeout
    if SpawnTimeouts[player.UserId] then
        spawn(function()
            SpawnTimeouts[player.UserId] = nil
        end)
    end
    
    -- Log completion
    if SPAWN_CONFIG.enableDetailedLogging then
        print("🎉 Spawn complete for: " .. player.Name .. " (Duration: " .. string.format("%.2f", status.totalDuration) .. "s)")
    end
    
    -- Track completion analytics
    local analyticsService = _G.GetAnalyticsService()
    if analyticsService then
        analyticsService:TrackEvent(player, "player_spawn_complete", {
            duration = status.totalDuration,
            retryCount = status.retryCount,
            phaseTimestamps = status.phaseTimestamps
        })
    end
    
    -- Notify all services that player is ready
    self:NotifyServicesPlayerReady(player)
    
    -- Clean up status tracking after a delay
    spawn(function()
        wait(60) -- Keep for 1 minute for debugging
        PlayerSpawnStatus[player.UserId] = nil
    end)
end

function PlayerSpawnLogic:NotifyServicesPlayerReady(player)
    local services = {
        {"MainGameController", "OnPlayerReady"},
        {"GameService", "OnPlayerReady"},
        {"DifficultyService", "OnPlayerReady"}
    }
    
    for _, serviceInfo in ipairs(services) do
        local serviceName, methodName = serviceInfo[1], serviceInfo[2]
        local service = _G.GetCoreService and _G.GetCoreService(serviceName) or _G["Get" .. serviceName] and _G["Get" .. serviceName]()
        
        if service and service[methodName] then
            pcall(function()
                service[methodName](service, player)
            end)
        end
    end
end

-- ========================================
-- ERROR HANDLING AND RECOVERY
-- ========================================

function PlayerSpawnLogic:HandleSpawnFailure(player, reason)
    local status = PlayerSpawnStatus[player.UserId]
    if not status then return end
    
    warn("❌ Spawn failure for " .. player.Name .. ": " .. reason)
    
    -- Track failure analytics
    local analyticsService = _G.GetAnalyticsService()
    if analyticsService then
        analyticsService:TrackEvent(player, "player_spawn_failure", {
            reason = reason,
            phase = status.currentPhase,
            retryCount = status.retryCount,
            duration = tick() - status.startTime
        })
    end
    
    -- Attempt retry if enabled
    if SPAWN_CONFIG.retryFailedSpawns and status.retryCount < SPAWN_CONFIG.maxRetryAttempts then
        status.retryCount = status.retryCount + 1
        
        print("🔄 Retrying spawn for " .. player.Name .. " (attempt " .. status.retryCount .. "/" .. SPAWN_CONFIG.maxRetryAttempts .. ")")
        
        spawn(function()
            wait(SPAWN_CONFIG.spawnRetryDelay)
            self:ExecuteSpawnSequence(player)
        end)
    else
        -- Final failure
        warn("💥 Final spawn failure for " .. player.Name .. " after " .. status.retryCount .. " retries")
        
        if analyticsService then
            analyticsService:TrackEvent(player, "player_spawn_final_failure", {
                reason = reason,
                retryCount = status.retryCount
            })
        end
    end
end

function PlayerSpawnLogic:HandleSpawnTimeout(player)
    local status = PlayerSpawnStatus[player.UserId]
    if not status then return end
    
    warn("⏰ Spawn timeout for " .. player.Name .. " in phase: " .. status.currentPhase)
    
    self:HandleSpawnFailure(player, "Spawn timeout in phase: " .. status.currentPhase)
end

function PlayerSpawnLogic:HandlePlayerDespawn(player)
    if SPAWN_CONFIG.enableDetailedLogging then
        print("👋 Player leaving: " .. player.Name)
    end
    
    -- Clean up spawn tracking
    if PlayerSpawnStatus[player.UserId] then
        PlayerSpawnStatus[player.UserId] = nil
    end
    
    if SpawnTimeouts[player.UserId] then
        SpawnTimeouts[player.UserId] = nil
    end
    
    -- Track leave analytics
    local analyticsService = _G.GetAnalyticsService()
    if analyticsService then
        analyticsService:TrackEvent(player, "player_leave", {
            timestamp = tick()
        })
    end
end

-- ========================================
-- STATUS AND DEBUGGING
-- ========================================

function PlayerSpawnLogic:GetPlayerSpawnStatus(player)
    return PlayerSpawnStatus[player.UserId]
end

function PlayerSpawnLogic:GetAllSpawnStatuses()
    return PlayerSpawnStatus
end

function PlayerSpawnLogic:ForceCompleteSpawn(player)
    local status = PlayerSpawnStatus[player.UserId]
    if status and not status.success then
        print("🔧 Force completing spawn for: " .. player.Name)
        self:ExecuteSpawnCompletePhase(player)
    end
end

return PlayerSpawnLogic
