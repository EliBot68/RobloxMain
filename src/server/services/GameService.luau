-- GameService.luau
-- Enhanced core game mechanics with comprehensive memory management
-- Handles barrier spawning, collision detection, score tracking, and multiplayer coordination

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local DataStoreService = game:GetService("DataStoreService")

-- Dependencies
local SafeRequire = require(ReplicatedStorage.Shared.utils.SafeRequire)
local RemoteEvents = SafeRequire.require(ReplicatedStorage.Shared.modules.RemoteEvents)
local GameConstants = SafeRequire.require(ReplicatedStorage.Shared.constants.GameConstants)
local WorldObjectValidator = SafeRequire.require(ReplicatedStorage.Shared.utils.WorldObjectValidator)
local MemoryManager = require(ReplicatedStorage.Shared.utilities.MemoryManager)

local GameService = {}

-- Game Sessions Management
local activeGames = {} -- [player.UserId] = gameSession
local multiplayerSessions = {} -- [sessionId] = multiplayerSession
local barrierInstances = {} -- [player.UserId] = {barriers}

-- Memory management tracking
local gameConnections = {} -- Track game-related connections
local gameTweens = {} -- Track game-related tweens
local gameUpdateTasks = {} -- Track game update tasks

-- Game Configuration
local GAME_CONFIG = {
    -- Barrier spawning
    baseBarrierDistance = 50, -- studs between barriers
    barrierDistanceVariation = 20, -- random variation
    maxBarriersPerPlayer = 20,
    barrierCleanupDistance = 200, -- remove barriers behind player
    
    -- Scoring
    barrierPassScore = 10,
    perfectMatchBonus = 5,
    comboMultiplier = 1.5,
    timeBonus = 1,
    
    -- Multiplayer
    maxMultiplayerPlayers = 6,
    multiplayerXpBonus = 0.25, -- 25% bonus XP
    leaderboardUpdateInterval = 2, -- seconds
    
    -- Game mechanics
    defaultGameTime = 60,
    invincibilityTime = 3,
    respawnDelay = 2,
    
    -- Colors for barriers
    availableColors = {"Red", "Blue", "Green", "Yellow", "Purple", "Orange"}
}

-- Performance tracking
local performanceMetrics = {
    activeGameSessions = 0,
    totalBarriersSpawned = 0,
    totalGamesPlayed = 0,
    averageGameDuration = 0
}

-- ========================================
-- INITIALIZATION AND SETUP
-- ========================================

function GameService:Initialize()
    print("🎮 GameService initializing...")
    
    -- Validate world objects required for game mechanics
    print("🔍 Validating game world objects...")
    local missingObjects = WorldObjectValidator.validateAllRequired()
    if #missingObjects > 0 then
        warn("⚠️ GameService: Missing required world objects:")
        for _, missing in ipairs(missingObjects) do
            warn("  • " .. missing)
        end
    end
    
    -- Validate specific game objects
    local gameTrackExists = WorldObjectValidator.validateObjectWithWait("workspace.GameTrack", 5)
    if not gameTrackExists then
        warn("⚠️ GameService: GameTrack not found - creating fallback structure")
        WorldObjectValidator.createObjectIfMissing("workspace.GameTrack", "Folder", "workspace")
    end
    
    -- Setup remote events
    self:SetupRemoteEvents()
    
    -- Setup player connections
    self:SetupPlayerConnections()
    
    -- Initialize performance monitoring
    self:StartPerformanceMonitoring()
    
    print("✅ GameService initialized successfully")
    return true
end

function GameService:SetupRemoteEvents()
    -- Core game events
    RemoteEvents.StartGame.OnServerEvent:Connect(function(player, gameData)
        self:StartGame(player, gameData)
    end)
    
    RemoteEvents.EndGame.OnServerEvent:Connect(function(player, reason)
        self:EndGame(player, reason)
    end)
    
    RemoteEvents.PlayerHitBarrier.OnServerEvent:Connect(function(player, barrierData)
        self:HandleBarrierCollision(player, barrierData)
    end)
    
    RemoteEvents.PlayerMovement.OnServerEvent:Connect(function(player, movementData)
        self:HandlePlayerMovement(player, movementData)
    end)
    
    RemoteEvents.PlayerColorSwitch.OnServerEvent:Connect(function(player, newColor)
        self:HandleColorSwitch(player, newColor)
    end)
    
    -- Multiplayer events
    RemoteEvents.StartMultiplayerGame.OnServerEvent:Connect(function(player, sessionId, allPlayers)
        self:StartMultiplayerGame(player, sessionId, allPlayers)
    end)
    
    RemoteEvents.RequestGameData.OnServerEvent:Connect(function(player)
        self:SendGameDataToPlayer(player)
    end)
    
    print("📡 GameService remote events configured")
end

function GameService:SetupPlayerConnections()
    -- Handle player joining
    Players.PlayerAdded:Connect(function(player)
        self:OnPlayerAdded(player)
    end)
    
    -- Handle player leaving
    Players.PlayerRemoving:Connect(function(player)
        self:OnPlayerRemoving(player)
    end)
    
    -- Handle existing players
    for _, player in pairs(Players:GetPlayers()) do
        self:OnPlayerAdded(player)
    end
    
    print("👥 GameService player connections established")
end

-- ========================================
-- PLAYER MANAGEMENT
-- ========================================

function GameService:OnPlayerAdded(player)
    print("👤 GameService: Player joined - " .. player.Name)
    
    -- Initialize player data structures
    barrierInstances[player.UserId] = {}
    
    -- Load player data if needed
    self:LoadPlayerData(player)
    
    -- Setup character spawning
    player.CharacterAdded:Connect(function(character)
        self:OnPlayerCharacterAdded(player, character)
    end)
    
    -- Send initial game data
    task.wait(1) -- Brief delay to ensure client is ready
    self:SendGameDataToPlayer(player)
end

function GameService:OnPlayerRemoving(player)
    print("👋 GameService: Player leaving - " .. player.Name)
    
    -- End any active games
    if self:IsPlayerInGame(player) then
        self:EndGame(player, "player_left")
    end
    
    -- Cleanup player data
    self:CleanupPlayerData(player)
end

function GameService:OnPlayerCharacterAdded(player, character)
    local gameSession = activeGames[player.UserId]
    if not gameSession or not gameSession.isPlaying then
        return
    end
    
    -- Setup character for active game
    local humanoid = character:WaitForChild("Humanoid")
    local humanoidRootPart = character:WaitForChild("HumanoidRootPart")
    
    -- Position player at start of track
    if gameSession.playerStartPosition then
        humanoidRootPart.CFrame = CFrame.new(gameSession.playerStartPosition)
    end
    
    -- Setup collision detection
    self:SetupCollisionDetection(player, character)
    
    -- Apply any game-specific character modifications
    if gameSession.invincible and gameSession.invincibilityEndTime > tick() then
        self:ApplyInvincibility(player, character)
    end
end

-- ========================================
-- CORE GAME MECHANICS
-- ========================================

function GameService:StartGame(player, gameData)
    if activeGames[player.UserId] and activeGames[player.UserId].isPlaying then
        warn("⚠️ " .. player.Name .. " is already in a game")
        return false
    end
    
    print("🎮 Starting game for: " .. player.Name)
    
    -- Clean up any existing game data
    self:CleanupPlayerData(player)
    
    -- Create game session
    local gameSession = self:CreateGameSession(player, gameData)
    activeGames[player.UserId] = gameSession
    
    -- Setup initial game state
    self:InitializeGameSession(player, gameSession)
    
    -- Start game mechanics
    self:StartGameMechanics(player, gameSession)
    
    -- Notify client
    RemoteEvents.GameStarted:FireClient(player, gameSession.currentColor, {
        gameTime = gameSession.gameTime,
        gameMode = gameSession.gameMode,
        sessionId = gameSession.sessionId
    })
    
    -- Track analytics
    self:TrackGameStart(player, gameSession)
    
    print("✅ Game started for: " .. player.Name .. " (Session: " .. gameSession.sessionId .. ")")
    return true
end

function GameService:EndGame(player, reason)
    local gameSession = activeGames[player.UserId]
    if not gameSession or not gameSession.isPlaying then
        return false
    end
    
    print("🏁 Ending game for: " .. player.Name .. " (Reason: " .. (reason or "unknown") .. ")")
    
    -- Calculate final results
    local results = self:CalculateGameResults(player, gameSession, reason)
    
    -- Stop game mechanics
    self:StopGameMechanics(player, gameSession)
    
    -- Handle multiplayer session if applicable
    if gameSession.isMultiplayer then
        self:HandleMultiplayerGameEnd(player, gameSession, results)
    end
    
    -- Update player data
    self:UpdatePlayerGameData(player, results)
    
    -- Cleanup game session
    self:CleanupGameSession(player, gameSession)
    
    -- Notify client
    RemoteEvents.GameEnded:FireClient(player, results)
    
    -- Track analytics
    self:TrackGameEnd(player, gameSession, results)
    
    print("✅ Game ended for: " .. player.Name)
    return true
end

function GameService:CreateGameSession(player, gameData)
    local sessionId = player.UserId .. "_" .. tick()
    
    return {
        sessionId = sessionId,
        player = player,
        isPlaying = true,
        startTime = tick(),
        endTime = nil,
        
        -- Game state
        currentColor = self:GetRandomColor(),
        score = 0,
        barriersPassed = 0,
        coinsCollected = 0,
        perfectMatches = 0,
        combo = 0,
        maxCombo = 0,
        deaths = 0,
        
        -- Game settings
        gameTime = (gameData and gameData.gameTime) or GAME_CONFIG.defaultGameTime,
        gameMode = (gameData and gameData.gameMode) or "normal",
        difficulty = (gameData and gameData.difficulty) or 1,
        
        -- Player state
        isAlive = true,
        invincible = false,
        invincibilityEndTime = 0,
        lastPosition = Vector3.new(0, 0, 0),
        distanceTraveled = 0,
        
        -- Track data
        nextBarrierDistance = GAME_CONFIG.baseBarrierDistance,
        playerStartPosition = Vector3.new(0, 10, 0),
        
        -- Multiplayer data
        isMultiplayer = false,
        multiplayerSessionId = nil,
        
        -- Performance tracking
        updateConnection = nil,
        lastUpdateTime = tick()
    }
end

function GameService:InitializeGameSession(player, gameSession)
    -- Set player start position
    gameSession.playerStartPosition = self:GetPlayerStartPosition(player, gameSession)
    
    -- Initialize barriers tracking
    barrierInstances[player.UserId] = {}
    
    -- Update performance metrics
    performanceMetrics.activeGameSessions = performanceMetrics.activeGameSessions + 1
    
    -- Apply any game mode specific initialization
    if gameSession.gameMode == "event" then
        self:InitializeEventMode(player, gameSession)
    end
end

function GameService:StartGameMechanics(player, gameSession)
    -- Start movement tracking and barrier spawning
    gameSession.updateConnection = RunService.Heartbeat:Connect(function()
        self:UpdateGameSession(player, gameSession)
    end)
    
    -- Start game timer
    task.spawn(function()
        self:RunGameTimer(player, gameSession)
    end)
    
    -- Apply initial invincibility
    self:ApplyInvincibilityPeriod(player, gameSession)
end

-- ========================================
-- GAME LOOP AND UPDATES
-- ========================================

function GameService:UpdateGameSession(player, gameSession)
    if not gameSession.isPlaying or not player.Character then
        return
    end
    
    local humanoidRootPart = player.Character:FindFirstChild("HumanoidRootPart")
    if not humanoidRootPart then
        return
    end
    
    local currentTime = tick()
    local deltaTime = currentTime - gameSession.lastUpdateTime
    gameSession.lastUpdateTime = currentTime
    
    -- Update player position and distance
    local currentPosition = humanoidRootPart.Position
    local distanceDelta = (currentPosition - gameSession.lastPosition).Magnitude
    gameSession.distanceTraveled = gameSession.distanceTraveled + distanceDelta
    gameSession.lastPosition = currentPosition
    
    -- Check for barrier spawning
    self:CheckBarrierSpawning(player, gameSession, currentPosition)
    
    -- Cleanup old barriers
    self:CleanupOldBarriers(player, currentPosition)
    
    -- Update invincibility
    if gameSession.invincible and currentTime > gameSession.invincibilityEndTime then
        gameSession.invincible = false
        RemoteEvents.InvincibilityEnded:FireClient(player)
    end
    
    -- Check game end conditions
    self:CheckGameEndConditions(player, gameSession)
end

function GameService:CheckBarrierSpawning(player, gameSession, currentPosition)
    -- Check if player has traveled far enough for next barrier
    if gameSession.distanceTraveled >= gameSession.nextBarrierDistance then
        self:SpawnNextBarrier(player, gameSession, currentPosition)
    end
end

function GameService:SpawnNextBarrier(player, gameSession, currentPosition)
    -- Calculate spawn position
    local baseDistance = GAME_CONFIG.baseBarrierDistance
    local variation = math.random(-GAME_CONFIG.barrierDistanceVariation, GAME_CONFIG.barrierDistanceVariation)
    local spawnDistance = baseDistance + variation
    
    local spawnPosition = Vector3.new(
        currentPosition.X + spawnDistance,
        currentPosition.Y + 3,
        currentPosition.Z
    )
    
    -- Spawn barrier with random color
    local barrierColor = self:GetRandomColor()
    local barrier = self:CreateBarrier(player, spawnPosition, barrierColor)
    
    if barrier then
        -- Track barrier
        table.insert(barrierInstances[player.UserId], {
            barrier = barrier,
            color = barrierColor,
            spawnTime = tick(),
            position = spawnPosition
        })
        
        -- Update next spawn distance
        gameSession.nextBarrierDistance = gameSession.distanceTraveled + baseDistance + variation
        
        -- Update metrics
        performanceMetrics.totalBarriersSpawned = performanceMetrics.totalBarriersSpawned + 1
        
        print("🚧 Spawned barrier for " .. player.Name .. " at distance " .. math.floor(gameSession.distanceTraveled))
    end
end

function GameService:CreateBarrier(player, position, color)
    -- Create barrier part
    local barrier = Instance.new("Part")
    barrier.Name = "ColorBarrier_" .. color
    barrier.Size = Vector3.new(40, 12, 2)
    barrier.Position = position
    barrier.Anchored = true
    barrier.CanCollide = false
    barrier.Material = Enum.Material.Neon
    barrier.BrickColor = BrickColor.new(color)
    barrier.Transparency = 0.3
    
    -- Add barrier identification
    local colorValue = Instance.new("StringValue")
    colorValue.Name = "BarrierColor"
    colorValue.Value = color
    colorValue.Parent = barrier
    
    local ownerValue = Instance.new("ObjectValue")
    ownerValue.Name = "Owner"
    ownerValue.Value = player
    ownerValue.Parent = barrier
    
    -- Add visual effects
    self:AddBarrierEffects(barrier, color)
    
    -- Parent to workspace
    barrier.Parent = Workspace
    
    return barrier
end

function GameService:AddBarrierEffects(barrier, color)
    -- Add glow effect
    local pointLight = Instance.new("PointLight")
    pointLight.Color = barrier.Color
    pointLight.Brightness = 1
    pointLight.Range = 20
    pointLight.Parent = barrier
    
    -- Add pulsing tween
    local pulseTween = TweenService:Create(
        barrier,
        TweenInfo.new(1, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true),
        {Transparency = 0.1}
    )
    pulseTween:Play()
end

-- ========================================
-- COLLISION AND SCORING
-- ========================================

function GameService:SetupCollisionDetection(player, character)
    local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
    if not humanoidRootPart then
        return
    end
    
    -- Setup collision detection for barriers
    local function onTouched(hit)
        if hit.Name:find("ColorBarrier_") and hit:FindFirstChild("Owner") then
            local owner = hit.Owner.Value
            if owner == player then
                self:HandleBarrierCollision(player, {
                    barrier = hit,
                    color = hit:FindFirstChild("BarrierColor") and hit.BarrierColor.Value or "Unknown"
                })
            end
        end
    end
    
    humanoidRootPart.Touched:Connect(onTouched)
end

function GameService:HandleBarrierCollision(player, barrierData)
    local gameSession = activeGames[player.UserId]
    if not gameSession or not gameSession.isPlaying or gameSession.invincible then
        return
    end
    
    local barrier = barrierData.barrier
    local barrierColor = barrierData.color
    
    -- Check if colors match
    if barrierColor == gameSession.currentColor then
        self:HandleCorrectMatch(player, gameSession, barrier)
    else
        self:HandleIncorrectMatch(player, gameSession, barrier)
    end
    
    -- Remove barrier after collision
    if barrier and barrier.Parent then
        barrier:Destroy()
    end
    
    -- Remove from tracking
    self:RemoveBarrierFromTracking(player, barrier)
end

function GameService:HandleCorrectMatch(player, gameSession, barrier)
    -- Award points
    local baseScore = GAME_CONFIG.barrierPassScore
    local bonusScore = GAME_CONFIG.perfectMatchBonus
    local comboMultiplier = 1 + (gameSession.combo * 0.1)
    
    local totalScore = math.floor((baseScore + bonusScore) * comboMultiplier)
    gameSession.score = gameSession.score + totalScore
    gameSession.barriersPassed = gameSession.barriersPassed + 1
    gameSession.perfectMatches = gameSession.perfectMatches + 1
    gameSession.combo = gameSession.combo + 1
    
    if gameSession.combo > gameSession.maxCombo then
        gameSession.maxCombo = gameSession.combo
    end
    
    -- Notify client
    RemoteEvents.CorrectMatch:FireClient(player, {
        score = totalScore,
        totalScore = gameSession.score,
        combo = gameSession.combo,
        barriersPassed = gameSession.barriersPassed
    })
    
    -- Update multiplayer leaderboard if applicable
    if gameSession.isMultiplayer then
        self:UpdateMultiplayerLeaderboard(gameSession.multiplayerSessionId)
    end
    
    print("✅ " .. player.Name .. " correct match! Score: " .. totalScore .. " (Total: " .. gameSession.score .. ")")
end

function GameService:HandleIncorrectMatch(player, gameSession, barrier)
    -- Break combo
    gameSession.combo = 0
    
    -- Apply damage/consequences based on game mode
    if not gameSession.invincible then
        self:ApplyCollisionConsequences(player, gameSession)
    end
    
    -- Notify client
    RemoteEvents.IncorrectMatch:FireClient(player, {
        correctColor = gameSession.currentColor,
        hitColor = barrier:FindFirstChild("BarrierColor") and barrier.BarrierColor.Value or "Unknown",
        totalScore = gameSession.score
    })
    
    print("❌ " .. player.Name .. " incorrect match! Combo broken.")
end

function GameService:ApplyCollisionConsequences(player, gameSession)
    -- For now, just apply brief invincibility to prevent spam
    self:ApplyInvincibilityPeriod(player, gameSession)
    
    -- Could add lives system, health reduction, etc. here
    -- gameSession.lives = gameSession.lives - 1
    -- if gameSession.lives <= 0 then
    --     self:EndGame(player, "no_lives")
    -- end
end

-- ========================================
-- MULTIPLAYER SUPPORT
-- ========================================

function GameService:StartMultiplayerGame(player, sessionId, allPlayers)
    if activeGames[player.UserId] and activeGames[player.UserId].isPlaying then
        warn("⚠️ " .. player.Name .. " is already in a game")
        return false
    end
    
    print("🎮 Starting multiplayer game for: " .. player.Name .. " (Session: " .. sessionId .. ")")
    
    -- Create multiplayer session if it doesn't exist
    if not multiplayerSessions[sessionId] then
        multiplayerSessions[sessionId] = {
            sessionId = sessionId,
            players = {},
            startTime = tick(),
            leaderboard = {},
            isActive = true
        }
        
        -- Add all players to the session
        for _, sessionPlayer in pairs(allPlayers) do
            if sessionPlayer and sessionPlayer.Parent then
                table.insert(multiplayerSessions[sessionId].players, sessionPlayer)
                multiplayerSessions[sessionId].leaderboard[sessionPlayer.UserId] = {
                    player = sessionPlayer,
                    score = 0,
                    barriersPassed = 0,
                    coinsCollected = 0
                }
            end
        end
    end
    
    -- Start individual game with multiplayer flags
    local gameData = {
        gameMode = "multiplayer",
        isMultiplayer = true,
        multiplayerSessionId = sessionId
    }
    
    local success = self:StartGame(player, gameData)
    if success then
        -- Mark as multiplayer
        local gameSession = activeGames[player.UserId]
        gameSession.isMultiplayer = true
        gameSession.multiplayerSessionId = sessionId
        
        -- Start leaderboard updates for this session
        self:StartMultiplayerLeaderboardUpdates(sessionId)
        
        -- Notify client with multiplayer info
        RemoteEvents.MultiplayerGameStarted:FireClient(player, gameSession.currentColor, {
            sessionId = sessionId,
            playerCount = #allPlayers,
            playerNames = self:GetMultiplayerPlayerNames(sessionId)
        })
    end
    
    return success
end

function GameService:StartMultiplayerLeaderboardUpdates(sessionId)
    if not multiplayerSessions[sessionId] or multiplayerSessions[sessionId].leaderboardUpdating then
        return
    end
    
    multiplayerSessions[sessionId].leaderboardUpdating = true
    
    task.spawn(function()
        while multiplayerSessions[sessionId] and multiplayerSessions[sessionId].isActive do
            self:UpdateMultiplayerLeaderboard(sessionId)
            task.wait(GAME_CONFIG.leaderboardUpdateInterval)
        end
    end)
end

function GameService:UpdateMultiplayerLeaderboard(sessionId)
    if not multiplayerSessions[sessionId] then
        return
    end
    
    local session = multiplayerSessions[sessionId]
    local leaderboardData = {}
    
    -- Collect current scores from all players
    for _, sessionPlayer in pairs(session.players) do
        if sessionPlayer and sessionPlayer.Parent then
            local playerSession = activeGames[sessionPlayer.UserId]
            if playerSession and playerSession.isPlaying then
                session.leaderboard[sessionPlayer.UserId].score = playerSession.score
                session.leaderboard[sessionPlayer.UserId].barriersPassed = playerSession.barriersPassed
                session.leaderboard[sessionPlayer.UserId].coinsCollected = playerSession.coinsCollected
                
                table.insert(leaderboardData, {
                    name = sessionPlayer.Name,
                    userId = sessionPlayer.UserId,
                    score = playerSession.score,
                    barriersPassed = playerSession.barriersPassed,
                    coinsCollected = playerSession.coinsCollected
                })
            end
        end
    end
    
    -- Sort by score (highest first)
    table.sort(leaderboardData, function(a, b)
        return a.score > b.score
    end)
    
    -- Send updated leaderboard to all players in session
    for _, sessionPlayer in pairs(session.players) do
        if sessionPlayer and sessionPlayer.Parent then
            RemoteEvents.MultiplayerLeaderboardUpdate:FireClient(sessionPlayer, leaderboardData)
        end
    end
end

function GameService:HandleMultiplayerGameEnd(player, gameSession, results)
    local sessionId = gameSession.multiplayerSessionId
    if not multiplayerSessions[sessionId] then
        return
    end
    
    -- Check if all players in the session have finished
    local activePlayers = 0
    for _, sessionPlayer in pairs(multiplayerSessions[sessionId].players) do
        if sessionPlayer and sessionPlayer.Parent then
            local playerSession = activeGames[sessionPlayer.UserId]
            if playerSession and playerSession.isPlaying then
                activePlayers = activePlayers + 1
            end
        end
    end
    
    -- If this was the last active player, clean up the session
    if activePlayers == 0 then
        self:CleanupMultiplayerSession(sessionId)
    end
end

function GameService:CleanupMultiplayerSession(sessionId)
    if not multiplayerSessions[sessionId] then
        return
    end
    
    -- Send final results to all players
    self:SendMultiplayerResults(sessionId)
    
    -- Mark session as inactive
    multiplayerSessions[sessionId].isActive = false
    
    -- Schedule cleanup
    task.spawn(function()
        task.wait(60) -- Keep session data for 1 minute
        multiplayerSessions[sessionId] = nil
        print("🧹 Cleaned up multiplayer session: " .. sessionId)
    end)
    
    print("🏁 Multiplayer session " .. sessionId .. " completed")
end

function GameService:SendMultiplayerResults(sessionId)
    local session = multiplayerSessions[sessionId]
    if not session then
        return
    end
    
    -- Calculate final results for all players
    local finalResults = {}
    for _, sessionPlayer in pairs(session.players) do
        if sessionPlayer and sessionPlayer.Parent then
            local leaderboardEntry = session.leaderboard[sessionPlayer.UserId]
            if leaderboardEntry then
                table.insert(finalResults, {
                    name = sessionPlayer.Name,
                    userId = sessionPlayer.UserId,
                    score = leaderboardEntry.score,
                    barriersPassed = leaderboardEntry.barriersPassed,
                    coinsCollected = leaderboardEntry.coinsCollected,
                    placement = 0 -- Will be calculated below
                })
            end
        end
    end
    
    -- Sort and assign placements
    table.sort(finalResults, function(a, b) return a.score > b.score end)
    for i, result in ipairs(finalResults) do
        result.placement = i
    end
    
    -- Send final results to all players
    for _, sessionPlayer in pairs(session.players) do
        if sessionPlayer and sessionPlayer.Parent then
            RemoteEvents.MultiplayerGameCompleted:FireClient(sessionPlayer, finalResults)
            
            -- Apply multiplayer XP bonus
            local bonus = math.floor(session.leaderboard[sessionPlayer.UserId].score * GAME_CONFIG.multiplayerXpBonus)
            if bonus > 0 then
                RemoteEvents.MultiplayerXpBonus:FireClient(sessionPlayer, bonus)
            end
        end
    end
end

function GameService:GetMultiplayerPlayerNames(sessionId)
    local names = {}
    if multiplayerSessions[sessionId] then
        for _, sessionPlayer in pairs(multiplayerSessions[sessionId].players) do
            if sessionPlayer and sessionPlayer.Parent then
                table.insert(names, sessionPlayer.Name)
            end
        end
    end
    return names
end

-- ========================================
-- UTILITY AND HELPER FUNCTIONS
-- ========================================

function GameService:IsPlayerInGame(player)
    return activeGames[player.UserId] and activeGames[player.UserId].isPlaying
end

function GameService:GetPlayerGameSession(player)
    return activeGames[player.UserId]
end

function GameService:LoadPlayerData(player)
    -- This would typically load from DataStore
    -- For now, return basic default data
    return {
        coins = 0,
        highScore = 0,
        gamesPlayed = 0,
        totalDistance = 0,
        achievements = {}
    }
end

function GameService:UpdatePlayerGameData(player, results)
    -- Update player statistics based on game results
    -- This would typically save to DataStore
    local playerData = self:LoadPlayerData(player)
    
    playerData.gamesPlayed = playerData.gamesPlayed + 1
    playerData.totalDistance = playerData.totalDistance + (results.distanceTraveled or 0)
    
    if results.score > playerData.highScore then
        playerData.highScore = results.score
    end
    
    -- Add coins based on performance
    local coinsEarned = math.floor(results.score / 10)
    playerData.coins = playerData.coins + coinsEarned
    
    -- Notify client of data update
    RemoteEvents.PlayerDataUpdated:FireClient(player, playerData)
    
    return playerData
end

function GameService:GetRandomColor()
    return GAME_CONFIG.availableColors[math.random(1, #GAME_CONFIG.availableColors)]
end

function GameService:GetPlayerStartPosition(player, gameSession)
    -- Return appropriate start position based on game mode
    if gameSession.isMultiplayer then
        -- For multiplayer, positions would be assigned by ArchwayService
        return Vector3.new(0, 10, 0) -- Default fallback
    else
        -- Single player start position
        return Vector3.new(0, 10, 0)
    end
end

function GameService:ApplyInvincibilityPeriod(player, gameSession)
    gameSession.invincible = true
    gameSession.invincibilityEndTime = tick() + GAME_CONFIG.invincibilityTime
    
    RemoteEvents.InvincibilityStarted:FireClient(player, GAME_CONFIG.invincibilityTime)
end

function GameService:ApplyInvincibility(player, character)
    -- Visual indication of invincibility
    local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
    if humanoidRootPart then
        local forcefield = Instance.new("ForceField")
        forcefield.Parent = character
        
        -- Remove forcefield after invincibility period
        task.wait(GAME_CONFIG.invincibilityTime)
        if forcefield and forcefield.Parent then
            forcefield:Destroy()
        end
    end
end

function GameService:RunGameTimer(player, gameSession)
    local endTime = gameSession.startTime + gameSession.gameTime
    
    while gameSession.isPlaying and tick() < endTime do
        local timeRemaining = endTime - tick()
        
        -- Send periodic timer updates
        RemoteEvents.GameTimerUpdate:FireClient(player, timeRemaining, gameSession.gameTime)
        
        task.wait(1)
    end
    
    -- Time's up - end game
    if gameSession.isPlaying then
        self:EndGame(player, "time_expired")
    end
end

function GameService:CheckGameEndConditions(player, gameSession)
    -- Check various end conditions
    if not player.Character or not player.Character:FindFirstChild("Humanoid") then
        return
    end
    
    local humanoid = player.Character.Humanoid
    if humanoid.Health <= 0 and gameSession.isAlive then
        gameSession.isAlive = false
        gameSession.deaths = gameSession.deaths + 1
        
        -- Could implement respawn logic here
        -- For now, just end the game
        self:EndGame(player, "player_died")
    end
end

function GameService:CalculateGameResults(player, gameSession, endReason)
    local gameDuration = tick() - gameSession.startTime
    
    return {
        sessionId = gameSession.sessionId,
        player = player,
        endReason = endReason,
        
        -- Score data
        finalScore = gameSession.score,
        barriersPassed = gameSession.barriersPassed,
        coinsCollected = gameSession.coinsCollected,
        perfectMatches = gameSession.perfectMatches,
        maxCombo = gameSession.maxCombo,
        
        -- Performance data
        gameDuration = gameDuration,
        distanceTraveled = gameSession.distanceTraveled,
        deaths = gameSession.deaths,
        
        -- Multiplayer data
        isMultiplayer = gameSession.isMultiplayer,
        multiplayerSessionId = gameSession.multiplayerSessionId
    }
end

-- ========================================
-- CLEANUP AND MAINTENANCE
-- ========================================

function GameService:CleanupPlayerData(player)
    local userId = player.UserId
    local playerId = tostring(userId)
    
    print("🧹 Comprehensive cleanup for player: " .. player.Name)
    
    -- Cleanup barriers with enhanced memory management
    if barrierInstances[userId] then
        for _, barrierData in pairs(barrierInstances[userId]) do
            if barrierData.barrier and barrierData.barrier.Parent then
                barrierData.barrier:Destroy()
            end
            -- Cleanup barrier-related connections and tweens
            if barrierData.connection then
                barrierData.connection:Disconnect()
            end
            if barrierData.tween then
                barrierData.tween:Cancel()
            end
        end
        barrierInstances[userId] = nil
    end
    
    -- Cleanup game session with comprehensive resource management
    if activeGames[userId] then
        local gameSession = activeGames[userId]
        
        -- Disconnect update connection
        if gameSession.updateConnection then
            gameSession.updateConnection:Disconnect()
        end
        
        -- Cancel any active game update tasks
        if gameUpdateTasks[playerId] then
            for taskName, taskThread in pairs(gameUpdateTasks[playerId]) do
                task.cancel(taskThread) -- UPDATED for modern API
            end
            gameUpdateTasks[playerId] = nil
        end
        
        -- Clear session data
        activeGames[userId] = nil
        
        -- Update performance metrics
        performanceMetrics.activeGameSessions = math.max(0, performanceMetrics.activeGameSessions - 1)
    end
    
    -- Use MemoryManager for comprehensive cleanup
    MemoryManager:CleanupPlayer(playerId)
    
    print("✅ Player cleanup complete for " .. player.Name)
end

function GameService:CleanupGameSession(player, gameSession)
    local playerId = tostring(player.UserId)
    
    -- Disconnect update connection with memory management
    if gameSession.updateConnection then
        gameSession.updateConnection:Disconnect()
        gameSession.updateConnection = nil
    end
    
    -- Cancel any associated tweens
    if gameTweens[playerId] then
        for tweenName, tween in pairs(gameTweens[playerId]) do
            if tween then
                tween:Cancel()
            end
        end
        gameTweens[playerId] = nil
    end
    
    -- Cancel any active tasks
    if gameUpdateTasks[playerId] then
        for taskName, taskThread in pairs(gameUpdateTasks[playerId]) do
            task.cancel(taskThread) -- UPDATED for modern API
        end
        gameUpdateTasks[playerId] = nil
    end
    
    -- Update performance metrics
    performanceMetrics.totalGamesPlayed = performanceMetrics.totalGamesPlayed + 1
    performanceMetrics.activeGameSessions = math.max(0, performanceMetrics.activeGameSessions - 1)
    
    -- Calculate average game duration
    if gameSession.startTime then
        local gameDuration = tick() - gameSession.startTime
        performanceMetrics.averageGameDuration = (performanceMetrics.averageGameDuration + gameDuration) / 2
    end
    
    print("🧹 Game session cleanup complete for " .. player.Name)
end

-- Clean up inactive sessions (called by CleanupService)
function GameService:CleanupInactiveSessions()
    local cleaned = 0
    local currentTime = tick()
    local sessionTimeout = 900 -- 15 minutes
    
    print("🧹 Checking for inactive game sessions...")
    
    -- Cleanup inactive single-player sessions
    local inactiveSessions = {}
    for userId, gameSession in pairs(activeGames) do
        if gameSession.startTime and (currentTime - gameSession.startTime) > sessionTimeout then
            table.insert(inactiveSessions, {userId = userId, session = gameSession})
        end
    end
    
    for _, sessionData in pairs(inactiveSessions) do
        local player = Players:GetPlayerByUserId(sessionData.userId)
        if player then
            print("⏰ Cleaning up inactive session for " .. player.Name)
            self:CleanupGameSession(player, sessionData.session)
        end
        activeGames[sessionData.userId] = nil
        cleaned = cleaned + 1
    end
    
    -- Cleanup inactive multiplayer sessions
    local inactiveMultiplayerSessions = {}
    for sessionId, multiplayerSession in pairs(multiplayerSessions) do
        if multiplayerSession.startTime and (currentTime - multiplayerSession.startTime) > sessionTimeout then
            table.insert(inactiveMultiplayerSessions, sessionId)
        end
    end
    
    for _, sessionId in pairs(inactiveMultiplayerSessions) do
        print("⏰ Cleaning up inactive multiplayer session: " .. sessionId)
        self:CleanupMultiplayerSession(sessionId)
        cleaned = cleaned + 1
    end
    
    -- Cleanup barriers for disconnected players
    local disconnectedPlayers = {}
    for userId, _ in pairs(barrierInstances) do
        local player = Players:GetPlayerByUserId(userId)
        if not player then
            table.insert(disconnectedPlayers, userId)
        end
    end
    
    for _, userId in pairs(disconnectedPlayers) do
        if barrierInstances[userId] then
            for _, barrierData in pairs(barrierInstances[userId]) do
                if barrierData.barrier and barrierData.barrier.Parent then
                    barrierData.barrier:Destroy()
                end
                if barrierData.connection then
                    barrierData.connection:Disconnect()
                end
                if barrierData.tween then
                    barrierData.tween:Cancel()
                end
            end
            barrierInstances[userId] = nil
            cleaned = cleaned + 1
        end
    end
    
    if cleaned > 0 then
        print("✅ Cleaned up " .. cleaned .. " inactive sessions and resources")
    end
    
    return cleaned
end

function GameService:CleanupOldBarriers(player, currentPosition)
    local userId = player.UserId
    if not barrierInstances[userId] then
        return
    end
    
    local barriersToRemove = {}
    
    for i, barrierData in pairs(barrierInstances[userId]) do
        local distance = (currentPosition - barrierData.position).Magnitude
        
        -- Remove barriers that are far behind the player
        if distance > GAME_CONFIG.barrierCleanupDistance then
            if barrierData.barrier and barrierData.barrier.Parent then
                barrierData.barrier:Destroy()
            end
            table.insert(barriersToRemove, i)
        end
    end
    
    -- Remove from tracking
    for _, index in pairs(barriersToRemove) do
        barrierInstances[userId][index] = nil
    end
end

function GameService:RemoveBarrierFromTracking(player, barrier)
    local userId = player.UserId
    if not barrierInstances[userId] then
        return
    end
    
    for i, barrierData in pairs(barrierInstances[userId]) do
        if barrierData.barrier == barrier then
            barrierInstances[userId][i] = nil
            break
        end
    end
end

function GameService:StopGameMechanics(player, gameSession)
    -- Disconnect update connection
    if gameSession.updateConnection then
        gameSession.updateConnection:Disconnect()
        gameSession.updateConnection = nil
    end
    
    -- Mark as not playing
    gameSession.isPlaying = false
    gameSession.endTime = tick()
end

-- ========================================
-- ADDITIONAL FEATURES
-- ========================================

function GameService:HandlePlayerMovement(player, movementData)
    local gameSession = activeGames[player.UserId]
    if not gameSession or not gameSession.isPlaying then
        return
    end
    
    -- Basic anti-cheat: validate movement data
    if movementData.speed and movementData.speed > 100 then
        warn("⚠️ Suspicious movement speed from " .. player.Name .. ": " .. movementData.speed)
        -- Could implement anti-cheat measures here
    end
    
    -- Update position if valid
    if movementData.position then
        gameSession.lastPosition = movementData.position
    end
end

function GameService:HandleColorSwitch(player, newColor)
    local gameSession = activeGames[player.UserId]
    if not gameSession or not gameSession.isPlaying then
        return
    end
    
    -- Validate color
    local validColor = false
    for _, color in pairs(GAME_CONFIG.availableColors) do
        if color == newColor then
            validColor = true
            break
        end
    end
    
    if validColor then
        gameSession.currentColor = newColor
        RemoteEvents.ColorSwitched:FireClient(player, newColor)
    else
        warn("⚠️ Invalid color switch attempt from " .. player.Name .. ": " .. tostring(newColor))
    end
end

function GameService:SendGameDataToPlayer(player)
    local gameSession = activeGames[player.UserId]
    
    RemoteEvents.GameDataUpdate:FireClient(player, {
        isInGame = gameSession and gameSession.isPlaying or false,
        gameSession = gameSession,
        availableColors = GAME_CONFIG.availableColors,
        gameConfig = {
            defaultGameTime = GAME_CONFIG.defaultGameTime,
            invincibilityTime = GAME_CONFIG.invincibilityTime,
            barrierPassScore = GAME_CONFIG.barrierPassScore
        }
    })
end

function GameService:InitializeEventMode(player, gameSession)
    -- Special initialization for event game mode
    gameSession.gameTime = 90 -- Longer time for events
    gameSession.scoreMultiplier = 1.5 -- Bonus scoring
    
    print("🎪 Event mode initialized for: " .. player.Name)
end

function GameService:StartPerformanceMonitoring()
    task.spawn(function()
        while true do
            task.wait(30) -- Update every 30 seconds
            
            -- Log performance metrics
            print("📊 GameService Performance:")
            print("  Active Games: " .. performanceMetrics.activeGameSessions)
            print("  Total Barriers: " .. performanceMetrics.totalBarriersSpawned)
            print("  Total Games: " .. performanceMetrics.totalGamesPlayed)
            print("  Avg Duration: " .. string.format("%.1f", performanceMetrics.averageGameDuration) .. "s")
        end
    end)
end

-- ========================================
-- ANALYTICS AND TRACKING
-- ========================================

function GameService:TrackGameStart(player, gameSession)
    local analyticsService = _G.GetAnalyticsService()
    if analyticsService then
        analyticsService:TrackEvent(player, "game_started", {
            sessionId = gameSession.sessionId,
            gameMode = gameSession.gameMode,
            isMultiplayer = gameSession.isMultiplayer,
            gameTime = gameSession.gameTime,
            startColor = gameSession.currentColor
        })
    end
end

function GameService:TrackGameEnd(player, gameSession, results)
    local analyticsService = _G.GetAnalyticsService()
    if analyticsService then
        analyticsService:TrackEvent(player, "game_ended", {
            sessionId = gameSession.sessionId,
            endReason = results.endReason,
            finalScore = results.finalScore,
            gameDuration = results.gameDuration,
            barriersPassed = results.barriersPassed,
            distanceTraveled = results.distanceTraveled,
            isMultiplayer = results.isMultiplayer
        })
    end
end

-- ========================================
-- PUBLIC API FOR OTHER SERVICES
-- ========================================

-- Methods referenced by other services
function GameService:OnPlayerReady(player)
    print("✅ GameService: Player ready - " .. player.Name)
    self:SendGameDataToPlayer(player)
end

function GameService:OnPlayerRemoving(player)
    print("👋 GameService: Player removing - " .. player.Name)
    self:CleanupPlayerData(player)
end

function GameService:CreatePlayerSession(player)
    print("📋 GameService: Creating session for - " .. player.Name)
    -- Session is created when game starts, this is just a placeholder
    return true
end

-- Connect to player events for automatic cleanup
Players.PlayerRemoving:Connect(function(player)
    GameService:OnPlayerRemoving(player)
end)

-- Auto-initialize when required
GameService:Initialize()

return GameService
