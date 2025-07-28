-- SpectatorService.luau
-- Handles spectating functionality when players are eliminated from races

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local GameService = require(script.Parent.GameService)
local PlayerService = require(script.Parent.PlayerService)
local RemoteEvents = require(ReplicatedStorage.Shared.modules.RemoteEvents)

local SpectatorService = {}

-- Active spectators and their targets
local activeSpectators = {} -- [userId] = {targetPlayer, spectatorData}
local activeRaces = {} -- [gameId] = {players, spectators, status}
local spectatorConnections = {} -- [userId] = {connections}

-- Spectator system configuration
local SPECTATOR_CONFIG = {
    cameraHeight = 15, -- Camera height above player
    cameraDistance = 10, -- Distance behind player
    panSpeed = 2, -- Camera panning speed
    smoothTime = 0.3, -- Camera smoothing
    cheerCooldown = 3, -- Seconds between cheers
    maxSpectators = 10, -- Max spectators per race
    autoSwitchTime = 15 -- Auto-switch target after inactivity
}

-- Available cheer emotes
local CHEER_EMOTES = {
    {
        id = "cheer_wave",
        name = "👋 Wave",
        message = "{player} waves encouragingly!",
        animation = "wave",
        cooldown = 2
    },
    {
        id = "cheer_clap",
        name = "👏 Clap",
        message = "{player} is clapping for you!",
        animation = "clap",
        cooldown = 2
    },
    {
        id = "cheer_thumbsup",
        name = "👍 Thumbs Up",
        message = "{player} gives you a thumbs up!",
        animation = "thumbsup",
        cooldown = 3
    },
    {
        id = "cheer_point",
        name = "👉 Point",
        message = "{player} is pointing at you!",
        animation = "point",
        cooldown = 2
    },
    {
        id = "cheer_dance",
        name = "💃 Dance",
        message = "{player} is dancing for you!",
        animation = "dance",
        cooldown = 4
    },
    {
        id = "cheer_jump",
        name = "🦘 Jump",
        message = "{player} jumps with excitement!",
        animation = "jump",
        cooldown = 3
    },
    {
        id = "cheer_spin",
        name = "🌪️ Spin",
        message = "{player} spins with joy!",
        animation = "spin",
        cooldown = 3
    },
    {
        id = "cheer_salute",
        name = "🫡 Salute",
        message = "{player} salutes your skill!",
        animation = "salute",
        cooldown = 3
    }
}

function SpectatorService:Init()
    print("👁️ SpectatorService initializing...")
    
    -- Setup remote event handlers
    self:SetupRemoteEvents()
    
    -- Monitor game events
    self:SetupGameEventMonitoring()
    
    print("✅ SpectatorService initialized with spectating system!")
end

function SpectatorService:SetupRemoteEvents()
    -- Handle spectator mode requests
    RemoteEvents.StartSpectating.OnServerEvent:Connect(function(player, targetPlayerId)
        self:StartSpectating(player, targetPlayerId)
    end)
    
    -- Handle spectator camera controls
    RemoteEvents.SpectatorCameraControl.OnServerEvent:Connect(function(player, controlData)
        self:HandleCameraControl(player, controlData)
    end)
    
    -- Handle spectator target switching
    RemoteEvents.SwitchSpectatorTarget.OnServerEvent:Connect(function(player, direction)
        self:SwitchSpectatorTarget(player, direction)
    end)
    
    -- Handle cheer emotes
    RemoteEvents.SpectatorCheer.OnServerEvent:Connect(function(player, cheerType)
        self:HandleSpectatorCheer(player, cheerType)
    end)
    
    -- Handle spectator mode exit
    RemoteEvents.StopSpectating.OnServerEvent:Connect(function(player)
        self:StopSpectating(player)
    end)
end

function SpectatorService:SetupGameEventMonitoring()
    -- Monitor when players get eliminated from races
    if GameService then
        -- Connect to player elimination events
        RemoteEvents.PlayerEliminated.OnServerEvent:Connect(function(player, gameId, eliminationType)
            self:OnPlayerEliminated(player, gameId, eliminationType)
        end)
        
        -- Connect to race completion events
        RemoteEvents.RaceCompleted.OnServerEvent:Connect(function(gameId, winner, participants)
            self:OnRaceCompleted(gameId, winner, participants)
        end)
        
        -- Connect to game start events
        RemoteEvents.GameStarted.OnServerEvent:Connect(function(gameId, players)
            self:OnRaceStarted(gameId, players)
        end)
    end
end

function SpectatorService:OnRaceStarted(gameId, players)
    -- Initialize race data for spectator tracking
    activeRaces[gameId] = {
        players = {},
        spectators = {},
        status = "active",
        startTime = tick()
    }
    
    -- Add all players to the race
    for _, player in pairs(players) do
        activeRaces[gameId].players[tostring(player.UserId)] = {
            player = player,
            isAlive = true,
            position = #activeRaces[gameId].players + 1
        }
    end
    
    print("👁️ Race " .. gameId .. " started with " .. #players .. " players")
end

function SpectatorService:OnPlayerEliminated(player, gameId, eliminationType)
    if not activeRaces[gameId] then return end
    
    local userId = tostring(player.UserId)
    local raceData = activeRaces[gameId]
    
    -- Mark player as eliminated
    if raceData.players[userId] then
        raceData.players[userId].isAlive = false
        raceData.players[userId].eliminationTime = tick()
        raceData.players[userId].eliminationType = eliminationType
    end
    
    -- Get remaining alive players
    local alivePlayerCount = 0
    local alivePlayer = nil
    for _, playerData in pairs(raceData.players) do
        if playerData.isAlive then
            alivePlayerCount = alivePlayerCount + 1
            alivePlayer = playerData.player
        end
    end
    
    -- Only start spectating if there are still players racing
    if alivePlayerCount > 0 then
        self:StartSpectatorMode(player, gameId)
    end
    
    print("👁️ " .. player.Name .. " eliminated from race " .. gameId .. " (" .. alivePlayerCount .. " remaining)")
end

function SpectatorService:StartSpectatorMode(spectatorPlayer, gameId)
    local userId = tostring(spectatorPlayer.UserId)
    local raceData = activeRaces[gameId]
    
    if not raceData then return end
    
    -- Find the best target to spectate (first alive player or leader)
    local targetPlayer = self:FindBestSpectatorTarget(gameId)
    if not targetPlayer then return end
    
    -- Initialize spectator data
    local spectatorData = {
        gameId = gameId,
        targetPlayer = targetPlayer,
        startTime = tick(),
        lastCheerTime = 0,
        cameraOffset = Vector3.new(0, SPECTATOR_CONFIG.cameraHeight, -SPECTATOR_CONFIG.cameraDistance),
        isActive = true
    }
    
    activeSpectators[userId] = spectatorData
    raceData.spectators[userId] = spectatorPlayer
    
    -- Setup spectator connections
    self:SetupSpectatorConnections(spectatorPlayer, spectatorData)
    
    -- Notify client to enter spectator mode
    RemoteEvents.EnterSpectatorMode:FireClient(spectatorPlayer, {
        targetPlayer = targetPlayer,
        gameId = gameId,
        availableTargets = self:GetAvailableTargets(gameId),
        cheerEmotes = CHEER_EMOTES,
        config = SPECTATOR_CONFIG
    })
    
    -- Show spectator UI
    self:ShowSpectatorNotification(spectatorPlayer, targetPlayer)
    
    print("👁️ " .. spectatorPlayer.Name .. " started spectating " .. targetPlayer.Name)
end

function SpectatorService:FindBestSpectatorTarget(gameId)
    local raceData = activeRaces[gameId]
    if not raceData then return nil end
    
    -- Find alive players and prioritize by position/score
    local alivePlayersArray = {}
    for _, playerData in pairs(raceData.players) do
        if playerData.isAlive and playerData.player.Character then
            table.insert(alivePlayersArray, playerData)
        end
    end
    
    -- Sort by position (you might want to integrate with your scoring system)
    table.sort(alivePlayersArray, function(a, b)
        return (a.position or 999) < (b.position or 999)
    end)
    
    -- Return the leading player or first available
    return alivePlayersArray[1] and alivePlayersArray[1].player or nil
end

function SpectatorService:GetAvailableTargets(gameId)
    local raceData = activeRaces[gameId]
    if not raceData then return {} end
    
    local targets = {}
    for _, playerData in pairs(raceData.players) do
        if playerData.isAlive and playerData.player.Character then
            table.insert(targets, {
                player = playerData.player,
                position = playerData.position or 0,
                name = playerData.player.Name
            })
        end
    end
    
    -- Sort by position
    table.sort(targets, function(a, b)
        return a.position < b.position
    end)
    
    return targets
end

function SpectatorService:SetupSpectatorConnections(spectatorPlayer, spectatorData)
    local userId = tostring(spectatorPlayer.UserId)
    
    if not spectatorConnections[userId] then
        spectatorConnections[userId] = {}
    end
    
    -- Auto-update camera position
    local cameraConnection = RunService.Heartbeat:Connect(function()
        if not activeSpectators[userId] or not spectatorData.isActive then
            cameraConnection:Disconnect()
            return
        end
        
        self:UpdateSpectatorCamera(spectatorPlayer, spectatorData)
    end)
    
    -- Auto-switch targets periodically
    local switchConnection = RunService.Heartbeat:Connect(function()
        if not activeSpectators[userId] or not spectatorData.isActive then
            switchConnection:Disconnect()
            return
        end
        
        -- Check if current target is still valid
        if not spectatorData.targetPlayer.Character or not self:IsPlayerInRace(spectatorData.targetPlayer, spectatorData.gameId) then
            self:SwitchToNextTarget(spectatorPlayer)
        end
    end)
    
    spectatorConnections[userId].camera = cameraConnection
    spectatorConnections[userId].autoSwitch = switchConnection
end

function SpectatorService:UpdateSpectatorCamera(spectatorPlayer, spectatorData)
    local targetPlayer = spectatorData.targetPlayer
    if not targetPlayer or not targetPlayer.Character then return end
    
    local targetCharacter = targetPlayer.Character
    local targetHumanoidRootPart = targetCharacter:FindFirstChild("HumanoidRootPart")
    if not targetHumanoidRootPart then return end
    
    -- Calculate camera position
    local targetPosition = targetHumanoidRootPart.Position
    local cameraPosition = targetPosition + spectatorData.cameraOffset
    
    -- Send camera update to client
    RemoteEvents.UpdateSpectatorCamera:FireClient(spectatorPlayer, {
        targetPosition = targetPosition,
        cameraPosition = cameraPosition,
        targetName = targetPlayer.Name,
        targetStats = self:GetTargetStats(targetPlayer)
    })
end

function SpectatorService:GetTargetStats(player)
    -- Get relevant stats about the target player
    local playerData = PlayerService:GetPlayerData(player)
    if not playerData then return {} end
    
    return {
        level = playerData.level or 1,
        highScore = playerData.highScore or 0,
        gamesPlayed = playerData.gamesPlayed or 0,
        currentColor = playerData.currentColor or "RED"
    }
end

function SpectatorService:StartSpectating(spectatorPlayer, targetPlayerId)
    local targetPlayer = Players:GetPlayerByUserId(targetPlayerId)
    if not targetPlayer then return end
    
    local userId = tostring(spectatorPlayer.UserId)
    local spectatorData = activeSpectators[userId]
    
    if not spectatorData then return end
    
    -- Switch target
    spectatorData.targetPlayer = targetPlayer
    spectatorData.lastSwitchTime = tick()
    
    -- Update client
    RemoteEvents.SpectatorTargetChanged:FireClient(spectatorPlayer, {
        newTarget = targetPlayer,
        targetName = targetPlayer.Name,
        targetStats = self:GetTargetStats(targetPlayer)
    })
    
    print("👁️ " .. spectatorPlayer.Name .. " switched to spectating " .. targetPlayer.Name)
end

function SpectatorService:SwitchSpectatorTarget(spectatorPlayer, direction)
    local userId = tostring(spectatorPlayer.UserId)
    local spectatorData = activeSpectators[userId]
    
    if not spectatorData then return end
    
    local availableTargets = self:GetAvailableTargets(spectatorData.gameId)
    if #availableTargets <= 1 then return end
    
    -- Find current target index
    local currentIndex = 1
    for i, targetData in ipairs(availableTargets) do
        if targetData.player == spectatorData.targetPlayer then
            currentIndex = i
            break
        end
    end
    
    -- Calculate new index
    local newIndex
    if direction == "next" then
        newIndex = currentIndex + 1
        if newIndex > #availableTargets then
            newIndex = 1
        end
    else -- previous
        newIndex = currentIndex - 1
        if newIndex < 1 then
            newIndex = #availableTargets
        end
    end
    
    -- Switch to new target
    local newTarget = availableTargets[newIndex].player
    self:StartSpectating(spectatorPlayer, newTarget.UserId)
end

function SpectatorService:SwitchToNextTarget(spectatorPlayer)
    self:SwitchSpectatorTarget(spectatorPlayer, "next")
end

function SpectatorService:HandleCameraControl(spectatorPlayer, controlData)
    local userId = tostring(spectatorPlayer.UserId)
    local spectatorData = activeSpectators[userId]
    
    if not spectatorData then return end
    
    -- Update camera offset based on control input
    if controlData.type == "pan" then
        local panX = controlData.deltaX * SPECTATOR_CONFIG.panSpeed
        local panY = controlData.deltaY * SPECTATOR_CONFIG.panSpeed
        
        -- Apply panning to camera offset
        local currentOffset = spectatorData.cameraOffset
        spectatorData.cameraOffset = Vector3.new(
            math.clamp(currentOffset.X + panX, -20, 20),
            math.clamp(currentOffset.Y + panY, 5, 30),
            math.clamp(currentOffset.Z, -25, -5)
        )
    elseif controlData.type == "zoom" then
        local zoomDelta = controlData.delta * 2
        local currentOffset = spectatorData.cameraOffset
        spectatorData.cameraOffset = Vector3.new(
            currentOffset.X,
            currentOffset.Y,
            math.clamp(currentOffset.Z + zoomDelta, -25, -5)
        )
    end
end

function SpectatorService:HandleSpectatorCheer(spectatorPlayer, cheerType)
    local userId = tostring(spectatorPlayer.UserId)
    local spectatorData = activeSpectators[userId]
    
    if not spectatorData then return end
    
    -- Check cooldown
    local currentTime = tick()
    if currentTime - spectatorData.lastCheerTime < SPECTATOR_CONFIG.cheerCooldown then
        RemoteEvents.ShowNotification:FireClient(spectatorPlayer, {
            type = "warning",
            title = "Cooldown Active",
            message = "Wait " .. math.ceil(SPECTATOR_CONFIG.cheerCooldown - (currentTime - spectatorData.lastCheerTime)) .. " seconds"
        })
        return
    end
    
    -- Find cheer emote data
    local cheerData = nil
    for _, cheer in pairs(CHEER_EMOTES) do
        if cheer.id == cheerType then
            cheerData = cheer
            break
        end
    end
    
    if not cheerData then return end
    
    -- Update cooldown
    spectatorData.lastCheerTime = currentTime
    
    -- Send cheer to target player
    local targetPlayer = spectatorData.targetPlayer
    if targetPlayer and targetPlayer.Character then
        local message = string.gsub(cheerData.message, "{player}", spectatorPlayer.Name)
        
        -- Show cheer message to target
        RemoteEvents.ShowCheerMessage:FireClient(targetPlayer, {
            message = message,
            cheerType = cheerType,
            fromPlayer = spectatorPlayer.Name,
            animation = cheerData.animation
        })
        
        -- Show cheer effect to all players in race
        for _, playerData in pairs(activeRaces[spectatorData.gameId].players) do
            if playerData.isAlive and playerData.player ~= targetPlayer then
                RemoteEvents.ShowSpectatorCheer:FireClient(playerData.player, {
                    spectatorName = spectatorPlayer.Name,
                    targetName = targetPlayer.Name,
                    cheerType = cheerType,
                    message = message
                })
            end
        end
        
        -- Show to other spectators
        for _, spectator in pairs(activeRaces[spectatorData.gameId].spectators) do
            if spectator ~= spectatorPlayer then
                RemoteEvents.ShowSpectatorCheer:FireClient(spectator, {
                    spectatorName = spectatorPlayer.Name,
                    targetName = targetPlayer.Name,
                    cheerType = cheerType,
                    message = message
                })
            end
        end
        
        -- Create visual effect at target location
        self:CreateCheerEffect(targetPlayer, cheerData)
    end
    
    -- Confirm cheer to spectator
    RemoteEvents.CheerConfirmed:FireClient(spectatorPlayer, {
        cheerType = cheerType,
        cooldownTime = cheerData.cooldown
    })
    
    print("👁️ " .. spectatorPlayer.Name .. " cheered (" .. cheerType .. ") for " .. targetPlayer.Name)
end

function SpectatorService:CreateCheerEffect(targetPlayer, cheerData)
    if not targetPlayer.Character then return end
    
    local character = targetPlayer.Character
    local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
    if not humanoidRootPart then return end
    
    -- Create floating cheer effect
    RemoteEvents.CreateCheerEffect:FireClient(nil, {
        position = humanoidRootPart.Position + Vector3.new(0, 5, 0),
        cheerType = cheerData.id,
        animation = cheerData.animation,
        duration = 3
    })
end

function SpectatorService:IsPlayerInRace(player, gameId)
    if not activeRaces[gameId] then return false end
    
    local userId = tostring(player.UserId)
    local playerData = activeRaces[gameId].players[userId]
    
    return playerData and playerData.isAlive
end

function SpectatorService:ShowSpectatorNotification(spectatorPlayer, targetPlayer)
    RemoteEvents.ShowNotification:FireClient(spectatorPlayer, {
        type = "info",
        title = "🎭 Spectator Mode",
        message = "Now spectating " .. targetPlayer.Name .. "! Use arrow keys to switch targets, click emotes to cheer!"
    })
end

function SpectatorService:StopSpectating(spectatorPlayer)
    local userId = tostring(spectatorPlayer.UserId)
    local spectatorData = activeSpectators[userId]
    
    if not spectatorData then return end
    
    -- Mark as inactive
    spectatorData.isActive = false
    
    -- Clean up connections
    if spectatorConnections[userId] then
        for _, connection in pairs(spectatorConnections[userId]) do
            if connection then
                connection:Disconnect()
            end
        end
        spectatorConnections[userId] = nil
    end
    
    -- Remove from race spectators
    if activeRaces[spectatorData.gameId] then
        activeRaces[spectatorData.gameId].spectators[userId] = nil
    end
    
    -- Clean up spectator data
    activeSpectators[userId] = nil
    
    -- Notify client to exit spectator mode
    RemoteEvents.ExitSpectatorMode:FireClient(spectatorPlayer)
    
    print("👁️ " .. spectatorPlayer.Name .. " stopped spectating")
end

function SpectatorService:OnRaceCompleted(gameId, winner, participants)
    if not activeRaces[gameId] then return end
    
    local raceData = activeRaces[gameId]
    
    -- Stop all spectators for this race
    for userId, spectator in pairs(raceData.spectators) do
        self:StopSpectating(spectator)
    end
    
    -- Clean up race data
    activeRaces[gameId] = nil
    
    print("👁️ Race " .. gameId .. " completed, spectators dismissed")
end

-- Handle player leaving cleanup
Players.PlayerRemoving:Connect(function(player)
    local userId = tostring(player.UserId)
    
    -- Clean up if player was spectating
    if activeSpectators[userId] then
        SpectatorService:StopSpectating(player)
    end
    
    -- Remove from all races as a target
    for gameId, raceData in pairs(activeRaces) do
        if raceData.players[userId] then
            raceData.players[userId] = nil
        end
        if raceData.spectators[userId] then
            raceData.spectators[userId] = nil
        end
    end
end)

return SpectatorService
