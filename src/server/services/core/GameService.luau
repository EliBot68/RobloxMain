-- GameService.luau
-- Handles the core color-matching game mechanics

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local GameConstants = require(ReplicatedStorage.Shared.constants.GameConstants)
local RemoteEvents = require(ReplicatedStorage.Shared.modules.RemoteEvents)

-- Forward declare services to avoid circular dependencies
local PlayerService = nil
local QuestService = nil
local AnalyticsService = nil
local MonetizationService = nil
local LevelingService = nil
local EventService = nil
local GhostService = nil
local UpgradeService = nil
local TrophyService = nil
local PetService = nil
local SpectatorService = nil
local TournamentService = nil
local RebirthService = nil

local GameService = {}
local activeGames = {} -- Store active game sessions per player
local barriers = {} -- Store spawned barriers per player
local coins = {} -- Store spawned coins
local multiplayerSessions = {} -- Store multiplayer game sessions

-- Game state for each player
local function createGameSession(player, multiplayerSessionId)
    return {
        isPlaying = false,
        currentColor = "RED",
        score = 0,
        barriersPassed = 0,
        coinsCollected = 0,
        lastBarrierZ = 0,
        nextBarrierDistance = 25, -- Reduced for 2x track length
        barrierVariation = 0, -- Track barrier spacing variation
        playerStartPosition = nil, -- Track where player started
        nextColorChange = tick() + GameConstants.COLOR_CHANGE_TIME,
        multiplier = 1,
        multiplayerSessionId = multiplayerSessionId, -- Link to multiplayer session
        isMultiplayer = multiplayerSessionId ~= nil
    }
end

function GameService:GetRandomBarrierColor()
    local colors = {"RED", "GREEN", "BLUE"}
    return colors[math.random(1, #colors)]
end

function GameService:GetTrackDirection(startPosition)
    -- Determine track direction based on start position
    if startPosition.X > 50 then
        return "FORWARD" -- Track 1: moves in +Z direction
    elseif startPosition.X < -50 then
        return "FORWARD" -- Track 2: moves in +Z direction  
    else
        return "RIGHT" -- Track 3: moves in +X direction
    end
end

function GameService:SpawnBarrier(player, position, color)
    local userId = tostring(player.UserId)
    
    -- Initialize player barriers array if needed
    if not barriers[userId] then
        barriers[userId] = {}
    end
    
    -- Create barrier
    local barrier = Instance.new("Part")
    barrier.Name = "GameBarrier_" .. userId .. "_" .. #barriers[userId]
    barrier.Size = Vector3.new(8, 6, 2) -- Wide enough to block the track
    barrier.Position = position
    barrier.Anchored = true
    barrier.CanCollide = true
    barrier.Material = Enum.Material.Neon
    barrier.Shape = Enum.PartType.Block
    
    -- Set color based on barrier type
    if color == "RED" then
        barrier.BrickColor = BrickColor.new("Really red")
        barrier.Color = Color3.new(1, 0.2, 0.2)
    elseif color == "GREEN" then
        barrier.BrickColor = BrickColor.new("Bright green")
        barrier.Color = Color3.new(0.2, 1, 0.2)
    elseif color == "BLUE" then
        barrier.BrickColor = BrickColor.new("Bright blue")
        barrier.Color = Color3.new(0.2, 0.2, 1)
    end
    
    -- Add glowing effect
    local pointLight = Instance.new("PointLight")
    pointLight.Color = barrier.Color
    pointLight.Brightness = 2
    pointLight.Range = 20
    pointLight.Parent = barrier
    
    -- Add pulsing animation
    local pulseInfo = TweenInfo.new(1, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true)
    local pulseTween = TweenService:Create(barrier, pulseInfo, {
        Transparency = 0.3,
        Size = Vector3.new(8.5, 6.5, 2.2)
    })
    pulseTween:Play()
    
    -- Add barrier collision detection
    local connection
    connection = barrier.Touched:Connect(function(hit)
        local hitCharacter = hit.Parent
        local hitHumanoid = hitCharacter:FindFirstChildOfClass("Humanoid")
        local hitPlayer = Players:GetPlayerFromCharacter(hitCharacter)
        
        -- Check if it's the correct player
        if hitPlayer and hitPlayer == player and hitHumanoid then
            -- Get player's current color state
            local playerData = PlayerService:GetPlayerData(player)
            local playerColor = playerData and playerData.currentColor or "RED"
            
            print("🚧 " .. player.Name .. " hit " .. color .. " barrier (player color: " .. playerColor .. ")")
            
            -- Check color match
            if playerColor == color then
                -- Correct color - success!
                self:OnBarrierSuccess(player, barrier, color)
            else
                -- Wrong color - game over!
                self:OnBarrierFailure(player, barrier, color, playerColor)
            end
            
            -- Disconnect this barrier's touch event
            connection:Disconnect()
        end
    end)
    
    -- Store barrier data
    local barrierData = {
        part = barrier,
        color = color,
        position = position,
        tween = pulseTween,
        connection = connection
    }
    
    table.insert(barriers[userId], barrierData)
    
    -- Parent to workspace
    barrier.Parent = Workspace
    
    print("🚧 Spawned " .. color .. " barrier for " .. player.Name .. " at " .. tostring(position))
    
    return barrierData
end

function GameService:OnBarrierSuccess(player, barrier, barrierColor)
    local session = activeGames[player.UserId]
    if not session or not session.isPlaying then
        return
    end
    
    -- Award points
    self:AwardPoint(player)
    
    -- Award coin
    self:AwardCoin(player)
    
    -- Create success particle effects at barrier location
    self:CreateBarrierPassParticles(player, barrier, barrierColor)
    
    -- Trigger pet reaction
    if PetService then
        PetService:TriggerPetReaction(player, "onMatch", {color = barrierColor:lower()})
        
        -- Check for perfect streaks (multiple consecutive matches)
        if session.score > 0 and session.score % 5 == 0 then
            PetService:TriggerPetReaction(player, "onPerfect", {streak = session.score})
        end
    end
    
    -- Destroy barrier with success effect
    self:DestroyBarrierWithEffect(barrier, "success")
    
    -- Remove from barriers array
    self:RemoveBarrierFromArray(player, barrier)
    
    -- Play barrier pass sound effect
    RemoteEvents.PlayBarrierPassSound:FireClient(player)
    
    print("✅ " .. player.Name .. " successfully passed " .. barrierColor .. " barrier!")
end

function GameService:OnBarrierFailure(player, barrier, barrierColor, playerColor)
    local session = activeGames[player.UserId]
    if not session or not session.isPlaying then
        return
    end
    
    -- Trigger pet reaction for failure
    if PetService then
        PetService:TriggerPetReaction(player, "onMiss", {
            expectedColor = barrierColor:lower(),
            playerColor = playerColor:lower()
        })
    end
    
    -- Show failure effects
    self:ShowFailureEffects(player, barrierColor, playerColor)
    
    -- Destroy barrier with failure effect
    self:DestroyBarrierWithEffect(barrier, "failure")
    
    -- Check if this player should enter spectator mode (if in multiplayer and others are still playing)
    if session.isMultiplayer and SpectatorService then
        local sessionId = session.multiplayerSessionId
        local activePlayers = self:GetActivePlayersInSession(sessionId, player.UserId)
        
        if #activePlayers > 0 then
            -- Enter spectator mode before ending the game
            SpectatorService:AddSpectator(player, activePlayers)
        end
    end
    
    -- End the game
    self:EndRun(player, "wrong_color")
    
    print("❌ " .. player.Name .. " hit wrong color! Expected: " .. barrierColor .. ", Player: " .. playerColor)
end

function GameService:GetActivePlayersInSession(sessionId, excludeUserId)
    local activePlayers = {}
    
    if multiplayerSessions[sessionId] then
        for _, sessionPlayer in pairs(multiplayerSessions[sessionId].players) do
            if sessionPlayer and sessionPlayer.Parent and sessionPlayer.UserId ~= excludeUserId then
                local playerSession = activeGames[sessionPlayer.UserId]
                if playerSession and playerSession.isPlaying then
                    table.insert(activePlayers, sessionPlayer)
                end
            end
        end
    end
    
    return activePlayers
end

function GameService:AwardPoint(player)
    local session = activeGames[player.UserId]
    if not session or not session.isPlaying then
        return
    end
    
    session.score = session.score + GameConstants.BARRIER_REWARD
    session.barriersPassed = session.barriersPassed + 1
    
    -- Track quest progress for color matching
    if QuestService then
        QuestService:UpdateQuestProgress(player, "color_match", 1)
    end
    
    -- Notify client
    RemoteEvents.BarrierPassed:FireClient(player, true, session.score)
    
    print("🏆 " .. player.Name .. " earned " .. GameConstants.BARRIER_REWARD .. " points! Total: " .. session.score)
end

function GameService:AwardCoin(player)
    local session = activeGames[player.UserId]
    if not session or not session.isPlaying then
        return
    end
    
    local coinsToAward = 1
    
    -- Apply pet passive bonuses for perfect streaks
    if PetService and session.score > 0 and session.score % 3 == 0 then -- Check every 3 barriers for perfect streak
        local gameData = {
            isPerfectStreak = true,
            bonusCoins = 0
        }
        gameData = PetService:ApplyPetPassive(player, "coin_bonus", gameData)
        coinsToAward = coinsToAward + (gameData.bonusCoins or 0)
        
        if gameData.bonusCoins and gameData.bonusCoins > 0 then
            print("🐾 Pet bonus: +" .. gameData.bonusCoins .. " coins for perfect streak!")
        end
    end
    
    -- Apply rebirth multiplier
    if RebirthService then
        local rebirthMultiplier = RebirthService:GetCoinMultiplier(player)
        if rebirthMultiplier > 1 then
            local originalCoins = coinsToAward
            coinsToAward = math.floor(coinsToAward * rebirthMultiplier)
            print("🌟 Rebirth bonus: " .. originalCoins .. " → " .. coinsToAward .. " coins (x" .. rebirthMultiplier .. ")")
        end
    end
    
    session.coinsCollected = session.coinsCollected + coinsToAward
    
    -- Notify client
    RemoteEvents.CoinCollected:FireClient(player, session.coinsCollected)
    
    print("💰 " .. player.Name .. " earned " .. coinsToAward .. " coin(s)! Total: " .. session.coinsCollected)
end

function GameService:ShowFailureEffects(player, barrierColor, playerColor)
    -- Send failure effects to client
    RemoteEvents.ShowFailureEffect:FireClient(player, {
        barrierColor = barrierColor,
        playerColor = playerColor,
        showRedFlash = true,
        playFailSound = true
    })
end

function GameService:DestroyBarrierWithEffect(barrier, effectType)
    if not barrier or not barrier.Parent then
        return
    end
    
    if effectType == "success" then
        -- Success effect: bright flash and scale up
        local successTween = TweenService:Create(barrier, 
            TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
            {
                Size = barrier.Size * 1.5,
                Transparency = 1
            }
        )
        successTween:Play()
        
        successTween.Completed:Connect(function()
            barrier:Destroy()
        end)
    elseif effectType == "failure" then
        -- Failure effect: red flash and shake
        barrier.Color = Color3.new(1, 0, 0) -- Flash red
        
        local shakeTween = TweenService:Create(barrier,
            TweenInfo.new(0.2, Enum.EasingStyle.Bounce, Enum.EasingDirection.InOut, 3),
            {
                Position = barrier.Position + Vector3.new(2, 0, 0)
            }
        )
        shakeTween:Play()
        
        shakeTween.Completed:Connect(function()
            local fadeTween = TweenService:Create(barrier,
                TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
                {Transparency = 1}
            )
            fadeTween:Play()
            
            fadeTween.Completed:Connect(function()
                barrier:Destroy()
            end)
        end)
    else
        -- Default: just destroy
        barrier:Destroy()
    end
end

function GameService:CreateBarrierPassParticles(player, barrier, barrierColor)
    if not barrier or not barrier.Parent then
        return
    end
    
    -- Create particle effect at barrier location
    local effectPart = Instance.new("Part")
    effectPart.Name = "BarrierPassEffect"
    effectPart.Size = Vector3.new(1, 1, 1)
    effectPart.Position = barrier.Position
    effectPart.Anchored = true
    effectPart.CanCollide = false
    effectPart.Transparency = 1
    effectPart.Parent = Workspace
    
    local attachment = Instance.new("Attachment")
    attachment.Parent = effectPart
    
    -- Create particle emitter
    local particles = Instance.new("ParticleEmitter")
    particles.Parent = attachment
    particles.Enabled = true
    particles.Lifetime = NumberRange.new(0.8, 1.5)
    particles.Rate = 150
    particles.SpreadAngle = Vector2.new(45, 45)
    particles.Speed = NumberRange.new(8, 15)
    
    -- Set color based on barrier color
    local particleColor
    if barrierColor == "RED" then
        particleColor = ColorSequence.new{
            ColorSequenceKeypoint.new(0, Color3.new(1, 0.2, 0.2)),
            ColorSequenceKeypoint.new(0.5, Color3.new(1, 0.6, 0.6)),
            ColorSequenceKeypoint.new(1, Color3.new(1, 0.8, 0.8))
        }
    elseif barrierColor == "GREEN" then
        particleColor = ColorSequence.new{
            ColorSequenceKeypoint.new(0, Color3.new(0.2, 1, 0.2)),
            ColorSequenceKeypoint.new(0.5, Color3.new(0.6, 1, 0.6)),
            ColorSequenceKeypoint.new(1, Color3.new(0.8, 1, 0.8))
        }
    elseif barrierColor == "BLUE" then
        particleColor = ColorSequence.new{
            ColorSequenceKeypoint.new(0, Color3.new(0.2, 0.2, 1)),
            ColorSequenceKeypoint.new(0.5, Color3.new(0.6, 0.6, 1)),
            ColorSequenceKeypoint.new(1, Color3.new(0.8, 0.8, 1))
        }
    else
        particleColor = ColorSequence.new(Color3.new(1, 1, 1)) -- Default white
    end
    
    particles.Color = particleColor
    particles.Transparency = NumberSequence.new{
        NumberSequenceKeypoint.new(0, 0.3),
        NumberSequenceKeypoint.new(0.5, 0.6),
        NumberSequenceKeypoint.new(1, 1)
    }
    
    -- Add sparkle texture
    particles.Texture = "rbxasset://textures/particles/sparkles_main.dds"
    
    -- Clean up after effect
    game:GetService("Debris"):AddItem(effectPart, 3)
    
    -- Disable particles after brief burst
    spawn(function()
        wait(0.3)
        particles.Enabled = false
    end)
    
    -- Fire particle sound to client
    RemoteEvents.PlayBarrierParticleSound:FireClient(player)
    
    print("✨ Created " .. barrierColor .. " barrier pass particles for " .. player.Name)
end

function GameService:RemoveBarrierFromArray(player, barrier)
    local userId = tostring(player.UserId)
    
    if barriers[userId] then
        for i, barrierData in ipairs(barriers[userId]) do
            if barrierData.part == barrier then
                -- Disconnect touch event
                if barrierData.connection then
                    barrierData.connection:Disconnect()
                end
                -- Remove from array
                table.remove(barriers[userId], i)
                break
            end
        end
    end
end

function GameService:EndRun(player, reason)
    -- Call the existing EndGame function
    self:EndGame(player, reason)
end

function GameService:CleanupPlayerBarriers(player)
    local userId = tostring(player.UserId)
    
    if barriers[userId] then
        for _, barrierData in pairs(barriers[userId]) do
            if barrierData.tween then
                barrierData.tween:Cancel()
            end
            if barrierData.connection then
                barrierData.connection:Disconnect()
            end
            if barrierData.part and barrierData.part.Parent then
                barrierData.part:Destroy()
            end
        end
        barriers[userId] = {}
    end
end

function GameService:CleanupOldBarriers(player)
    -- Clean up barriers that are behind the player to free memory and maintain performance
    local userId = tostring(player.UserId)
    local session = activeGames[player.UserId]
    
    if not session or not session.isPlaying or not barriers[userId] then
        return
    end
    
    local character = player.Character
    if not character then return end
    
    local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
    if not humanoidRootPart then return end
    
    local playerPosition = humanoidRootPart.Position
    local trackDirection = self:GetTrackDirection(session.playerStartPosition)
    local cleanupDistance = 50 -- Clean up barriers more than 50 studs behind player
    local cleanedCount = 0
    
    -- Create a new array to hold barriers that should remain
    local remainingBarriers = {}
    
    for _, barrierData in pairs(barriers[userId]) do
        local barrier = barrierData.part
        if barrier and barrier.Parent then
            local barrierPosition = barrier.Position
            local shouldCleanup = false
            
            -- Check if barrier is behind player based on track direction
            if trackDirection == "FORWARD" then
                -- For forward tracks, check Z position
                if barrierPosition.Z < (playerPosition.Z - cleanupDistance) then
                    shouldCleanup = true
                end
            else -- RIGHT
                -- For right tracks, check X position
                if barrierPosition.X < (playerPosition.X - cleanupDistance) then
                    shouldCleanup = true
                end
            end
            
            if shouldCleanup then
                -- Clean up this old barrier
                if barrierData.tween then
                    barrierData.tween:Cancel()
                end
                if barrierData.connection then
                    barrierData.connection:Disconnect()
                end
                barrier:Destroy()
                cleanedCount = cleanedCount + 1
            else
                -- Keep this barrier
                table.insert(remainingBarriers, barrierData)
            end
        end
    end
    
    -- Update the barriers array with only remaining barriers
    barriers[userId] = remainingBarriers
    
    if cleanedCount > 0 then
        print("🧹 Cleaned up " .. cleanedCount .. " old barriers for " .. player.Name .. " (Memory optimization)")
        
        -- Log analytics event for cleanup tracking
        if AnalyticsService then
            AnalyticsService:LogEvent(player, "barrier_cleanup", {
                barriersRemoved = cleanedCount,
                barriersRemaining = #remainingBarriers,
                playerPosition = {x = playerPosition.X, z = playerPosition.Z},
                trackDirection = trackDirection
            })
        end
    end
end

function GameService:GetBarrierStats()
    -- Get statistics about current barrier counts for monitoring
    local stats = {
        totalPlayers = 0,
        totalBarriers = 0,
        playerBarrierCounts = {}
    }
    
    for userId, barrierArray in pairs(barriers) do
        local barrierCount = #barrierArray
        stats.totalBarriers = stats.totalBarriers + barrierCount
        stats.totalPlayers = stats.totalPlayers + 1
        stats.playerBarrierCounts[userId] = barrierCount
    end
    
    return stats
end

function GameService:UpdateBarrierSpawning(player)
    local session = activeGames[player.UserId]
    if not session or not session.isPlaying then
        return
    end
    
    local character = player.Character
    if not character then return end
    
    local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
    if not humanoidRootPart then return end
    
    local currentPosition = humanoidRootPart.Position
    
    -- Set start position on first update
    if not session.playerStartPosition then
        session.playerStartPosition = currentPosition
        session.lastBarrierZ = currentPosition.Z
        return
    end
    
    local trackDirection = self:GetTrackDirection(session.playerStartPosition)
    local distanceTraveled = 0
    
    -- Calculate distance based on track direction
    if trackDirection == "FORWARD" then
        distanceTraveled = currentPosition.Z - session.playerStartPosition.Z
    else -- RIGHT
        distanceTraveled = currentPosition.X - session.playerStartPosition.X
    end
    
    -- Check if we need to spawn a new barrier
    local nextBarrierAt = session.nextBarrierDistance
    
    if distanceTraveled >= nextBarrierAt then
        -- Add variation to barrier spacing (20-35 studs)
        local baseDistance = 25
        local variation = math.random(-5, 10) -- Random variation
        session.barrierVariation = variation
        
        -- Calculate spawn position ahead of player
        local spawnDistance = 15 + math.random(0, 5) -- 15-20 studs ahead for variety
        local spawnPosition
        if trackDirection == "FORWARD" then
            spawnPosition = Vector3.new(
                session.playerStartPosition.X, -- Same X as track
                currentPosition.Y + 3, -- Slightly above ground
                currentPosition.Z + spawnDistance
            )
        else -- RIGHT  
            spawnPosition = Vector3.new(
                currentPosition.X + spawnDistance,
                currentPosition.Y + 3, -- Slightly above ground
                session.playerStartPosition.Z -- Same Z as track
            )
        end
        
        -- Spawn barrier with random color
        local barrierColor = self:GetRandomBarrierColor()
        self:SpawnBarrier(player, spawnPosition, barrierColor)
        
        -- Update next barrier distance with variation
        session.nextBarrierDistance = session.nextBarrierDistance + baseDistance + variation
        
        print("📏 " .. player.Name .. " traveled " .. math.floor(distanceTraveled) .. " studs, spawned barrier at " .. tostring(spawnPosition))
    end
end

function GameService:StartGame(player, gameData)
    local userId = tostring(player.UserId)
    
    -- Check if player is already in a game
    if activeGames[userId] then
        print("⚠️ " .. player.Name .. " is already in a game")
        return false
    end
    
    -- Check if player is in a party
    local PartyService = require(script.Parent.PartyService)
    local party = PartyService:GetPlayerParty(player)
    
    if party and #party.members > 1 then
        -- Start party game - teleport all members together
        print("🎮 Starting party game for " .. #party.members .. " members")
        
        local gameId = self:GenerateGameId()
        local partyGameData = {
            gameId = gameId,
            isPartyGame = true,
            partyId = party.id,
            startTime = os.time()
        }
        
        -- Start game for all party members
        for _, memberId in pairs(party.members) do
            local member = Players:GetPlayerByUserId(tonumber(memberId))
            if member then
                self:StartSinglePlayerGame(member, partyGameData)
            end
        end
        
        -- Notify party service
        PartyService:StartPartyGame(party.id, partyGameData)
        
        return true
    else
        -- Start solo game
        local gameId = self:GenerateGameId()
        local soloGameData = gameData or {
            gameId = gameId,
            isPartyGame = false,
            startTime = os.time()
        }
        
        return self:StartSinglePlayerGame(player, soloGameData)
    end
end

function GameService:StartSinglePlayerGame(player, gameData)
    if activeGames[player.UserId] and activeGames[player.UserId].isPlaying then
        return false -- Already playing
    end
    
    -- Clean up any existing barriers for this player
    self:CleanupPlayerBarriers(player)
    
    activeGames[player.UserId] = createGameSession(player, nil) -- nil for solo games
    activeGames[player.UserId].isPlaying = true
    activeGames[player.UserId].startTime = tick() -- Track start time for quest purposes
    activeGames[player.UserId].gameMode = gameMode or "normal" -- Track game mode
    
    -- Set initial color
    local randomColor = GameConstants.COLOR_NAMES[math.random(1, #GameConstants.COLOR_NAMES)]
    activeGames[player.UserId].currentColor = randomColor
    
    -- Update player data
    local playerData = PlayerService:GetPlayerData(player)
    playerData.currentColor = randomColor
    PlayerService:UpdatePlayerData(player, playerData)
    
    -- Notify client
    RemoteEvents.GameStarted:FireClient(player, randomColor)
    
    -- Start background music for the run
    RemoteEvents.ClientStartGameMusic:FireClient(player)
    
    -- Start ghost recording
    if GhostService then
        local trackType = gameMode == "event" and "event" or "main"
        GhostService:StartRecording(player, trackType)
    end
    
    -- Log analytics event for run start
    if AnalyticsService then
        local eventType = gameMode == "event" and AnalyticsService.EventTypes.EVENT_RUN_START or AnalyticsService.EventTypes.RUN_START
        AnalyticsService:LogEvent(player, eventType, {
            startColor = randomColor,
            startTime = tick(),
            gameMode = gameMode or "normal"
        })
    end
    
    print("🎮 " .. player.Name .. " started Color Rush game (" .. (gameMode or "normal") .. " mode)!")
    return true
end

function GameService:IsPlayerInGame(player)
    return activeGames[player.UserId] and activeGames[player.UserId].isPlaying
end

function GameService:StartMultiplayerGame(player, sessionId, allPlayers)
    if activeGames[player.UserId] and activeGames[player.UserId].isPlaying then
        return false -- Already playing
    end
    
    -- Clean up any existing barriers for this player
    self:CleanupPlayerBarriers(player)
    
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
    
    -- Create game session with multiplayer link
    activeGames[player.UserId] = createGameSession(player, sessionId)
    activeGames[player.UserId].isPlaying = true
    activeGames[player.UserId].startTime = tick()
    
    -- Set initial color (synchronized across all players)
    local randomColor = GameConstants.COLOR_NAMES[math.random(1, #GameConstants.COLOR_NAMES)]
    activeGames[player.UserId].currentColor = randomColor
    
    -- Update player data
    local playerData = PlayerService:GetPlayerData(player)
    playerData.currentColor = randomColor
    PlayerService:UpdatePlayerData(player, playerData)
    
    -- Notify client with multiplayer info
    RemoteEvents.MultiplayerGameStarted:FireClient(player, randomColor, {
        sessionId = sessionId,
        playerCount = #allPlayers,
        playerNames = self:GetMultiplayerPlayerNames(sessionId)
    })
    
    -- Start broadcasting leaderboard updates
    self:StartMultiplayerLeaderboardUpdates(sessionId)
    
    -- Log analytics event for multiplayer run start
    if AnalyticsService then
        AnalyticsService:LogEvent(player, AnalyticsService.EventTypes.MULTIPLAYER_RUN_START, {
            sessionId = sessionId,
            playerCount = #allPlayers,
            startColor = randomColor,
            startTime = tick()
        })
    end
    
    print("🎮 " .. player.Name .. " started multiplayer Color Rush game! (Session: " .. sessionId .. ")")
    return true
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

function GameService:StartMultiplayerLeaderboardUpdates(sessionId)
    -- Start a background process to update leaderboards every 2 seconds
    spawn(function()
        while multiplayerSessions[sessionId] and multiplayerSessions[sessionId].isActive do
            self:UpdateMultiplayerLeaderboard(sessionId)
            wait(2)
        end
    end)
end

function GameService:UpdateMultiplayerLeaderboard(sessionId)
    if not multiplayerSessions[sessionId] then return end
    
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

function GameService:EndMultiplayerGame(player, reason)
    local session = activeGames[player.UserId]
    if not session or not session.isPlaying or not session.isMultiplayer then
        -- Fall back to regular EndGame for non-multiplayer
        return self:EndGame(player, reason)
    end
    
    local sessionId = session.multiplayerSessionId
    
    -- End the individual player's game
    self:EndGame(player, reason)
    
    -- Check if all players in the multiplayer session have finished
    local activePlayers = 0
    if multiplayerSessions[sessionId] then
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
end

function GameService:CleanupMultiplayerSession(sessionId)
    if multiplayerSessions[sessionId] then
        -- Send final results to all players
        self:SendMultiplayerResults(sessionId)
        
        -- Mark session as inactive
        multiplayerSessions[sessionId].isActive = false
        
        -- Schedule cleanup
        spawn(function()
            wait(60) -- Keep session data for 1 minute
            multiplayerSessions[sessionId] = nil
            print("🧹 Cleaned up multiplayer session: " .. sessionId)
        end)
        
        print("🏁 Multiplayer session " .. sessionId .. " completed")
    end
end

function GameService:SendMultiplayerResults(sessionId)
    if not multiplayerSessions[sessionId] then return end
    
    local session = multiplayerSessions[sessionId]
    local finalResults = {}
    
    -- Collect final scores
    for _, sessionPlayer in pairs(session.players) do
        if sessionPlayer and sessionPlayer.Parent then
            local leaderboardEntry = session.leaderboard[sessionPlayer.UserId]
            if leaderboardEntry then
                table.insert(finalResults, {
                    name = sessionPlayer.Name,
                    score = leaderboardEntry.score,
                    barriersPassed = leaderboardEntry.barriersPassed,
                    coinsCollected = leaderboardEntry.coinsCollected
                })
            end
        end
    end
    
    -- Sort by score
    table.sort(finalResults, function(a, b)
        return a.score > b.score
    end)
    
    -- Send results to all players
    for _, sessionPlayer in pairs(session.players) do
        if sessionPlayer and sessionPlayer.Parent then
            RemoteEvents.MultiplayerGameCompleted:FireClient(sessionPlayer, finalResults)
        end
    end
end

function GameService:EndGame(player, reason)
    local session = activeGames[player.UserId]
    if not session or not session.isPlaying then
        return
    end
    
    -- Check if this is a multiplayer game that needs special handling
    if session.isMultiplayer then
        return self:EndMultiplayerGame(player, reason)
    end
    
    session.isPlaying = false
    
    -- Clean up barriers for this player
    self:CleanupPlayerBarriers(player)
    
    -- Track quest progress
    if QuestService then
        QuestService:UpdateQuestProgress(player, "games_played", 1)
        
        -- Check if player has an active pet
        local playerData = PlayerService:GetPlayerData(player)
        local hasPet = playerData.activePet ~= nil
        if hasPet then
            QuestService:UpdateQuestProgress(player, "games_with_pet", 1, {hasPet = true})
        end
        
        -- Check for perfect game (no wrong barriers hit)
        if reason ~= "wrong_color" then
            QuestService:UpdateQuestProgress(player, "perfect_games", 1, {perfect = true})
        end
        
        -- Check for fast game completion
        local gameTime = tick() - (session.startTime or tick())
        if gameTime <= 180 then -- 3 minutes
            QuestService:UpdateQuestProgress(player, "fast_games", 1, {time = gameTime})
        end
        
        -- Check high score quest
        if session.score >= 15 then
            QuestService:UpdateQuestProgress(player, "high_score", session.score)
        end
        
        -- Track coins collected
        QuestService:UpdateQuestProgress(player, "coins_collected", session.coinsCollected)
    end
    
    -- Update player stats
    local playerData = PlayerService:GetPlayerData(player)
    playerData.gamesPlayed = playerData.gamesPlayed + 1
    playerData.totalBarriersPassed = playerData.totalBarriersPassed + session.barriersPassed
    
    -- Track perfect games
    if reason ~= "wrong_color" then
        playerData.perfectGames = (playerData.perfectGames or 0) + 1
    end
    
    -- Track max combo
    if session.score > (playerData.maxCombo or 0) then
        playerData.maxCombo = session.score
    end
    
    -- Check and update high score through PlayerService
    local isNewHighScore = PlayerService:UpdateHighScore(player, session.score)
    if isNewHighScore then
        RemoteEvents.NewHighScore:FireClient(player, session.score)
    end
    
    -- Track tournament stats
    if TournamentService then
        TournamentService:RecordPlayerScore(player, session.score, isNewHighScore)
        
        -- Track perfect games for tournament streak
        if reason ~= "wrong_color" then
            TournamentService:RecordPerfectGame(player)
        else
            TournamentService:RecordImperfectGame(player)
        end
    end
    
    -- Award coins with world event multiplier
    local coinReward = session.coinsCollected * GameConstants.COIN_VALUE
    
    -- Apply pet passives
    local gameData = {
        coinMultiplier = 1,
        xpMultiplier = 1,
        isPerfectGame = reason ~= "wrong_color" and session.barriersPassed > 0
    }
    
    if PetService then
        -- Apply experience boost passive
        gameData = PetService:ApplyPetPassive(player, "experience_boost", gameData)
        
        -- Apply double rewards for perfect games
        if gameData.isPerfectGame then
            gameData = PetService:ApplyPetPassive(player, "double_rewards", gameData)
        end
    end
    
    -- Check for world event multiplier
    local WorldEventService = require(script.Parent.WorldEventService)
    local isWorldEventActive = WorldEventService and WorldEventService:IsEventActive()
    if isWorldEventActive then
        local eventMultiplier = WorldEventService:GetCurrentEventMultiplier() or 2.0
        coinReward = math.floor(coinReward * eventMultiplier)
        session.eventMultiplierApplied = eventMultiplier
        
        -- Record world event score
        WorldEventService:RecordEventScore(player, session.score, {
            coinsEarned = session.coinsCollected * GameConstants.COIN_VALUE,
            xpEarned = session.score,
            barriersPassed = session.barriersPassed,
            gameTime = tick() - (session.startTime or tick())
        })
    end
    
    -- Apply pet coin bonus
    if gameData.coinMultiplier > 1 then
        coinReward = math.floor(coinReward * gameData.coinMultiplier)
        print("🐾 Pet bonus applied: " .. ((gameData.coinMultiplier - 1) * 100) .. "% coin bonus!")
    end
    
    playerData.coins = playerData.coins + coinReward
    playerData.totalCoinsEarned = (playerData.totalCoinsEarned or 0) + coinReward
    
    PlayerService:UpdatePlayerData(player, playerData)
    
    -- Update coin display instantly
    RemoteEvents.InstantCoinUpdate:FireClient(player, playerData.coins)
    
    -- Award XP with party bonus
    local baseXp = session.score * GameConstants.XP_PER_POINT
    
    -- Apply pet XP multiplier
    if gameData.xpMultiplier > 1 then
        baseXp = math.floor(baseXp * gameData.xpMultiplier)
    end
    
    -- Check for party XP bonus
    local PartyService = require(script.Parent.PartyService)
    local party = PartyService:GetPlayerParty(player)
    local partyXpMultiplier = PartyService:GetPartyXpMultiplier(player)
    
    -- Check for multiplayer XP bonus
    local multiplayerBonus = 1
    if session.multiplayerSessionId and multiplayerSessions[session.multiplayerSessionId] then
        local multiplayerSession = multiplayerSessions[session.multiplayerSessionId]
        if multiplayerSession.players and #multiplayerSession.players > 1 then
            multiplayerBonus = 1.25 -- 25% bonus XP for multiplayer games
            print("🎮 " .. player.Name .. " earned 25% multiplayer XP bonus!")
        end
    end
    
    local finalXp = math.floor(baseXp * partyXpMultiplier * multiplayerBonus)
    
    -- Award XP through LevelingService
    if LevelingService then
        LevelingService:GiveXP(player, finalXp, "Game Completion")
        
        -- If party bonus was applied, notify about it
        if party and #party.members > 1 then
            local bonusXp = finalXp - baseXp
            RemoteEvents.PartyXpBonus:FireClient(player, bonusXp, #party.members)
            print("🎊 " .. player.Name .. " earned " .. bonusXp .. " bonus XP from party play!")
        end
        
        -- If multiplayer bonus was applied, notify about it
        if multiplayerBonus > 1 then
            local bonusXp = finalXp - math.floor(baseXp * partyXpMultiplier)
            RemoteEvents.MultiplayerXpBonus:FireClient(player, bonusXp, multiplayerBonus)
            print("🎮 " .. player.Name .. " earned " .. bonusXp .. " bonus XP from multiplayer play!")
        end
    end
    
    -- Record game results for party tracking
    local gameResults = {
        score = session.score,
        coinsEarned = coinReward,
        xpEarned = finalXp,
        barriersPassed = session.barriersPassed,
        gameTime = tick() - (session.startTime or tick()),
        isPerfect = reason ~= "wrong_color"
    }
    
    -- Notify party service of game completion
    if party then
        PartyService:EndPartyGame(party.id, gameResults)
    end
    
    -- Update trophy progress
    if TrophyService then
        TrophyService:UpdateTrophyProgress(player, "high_score", session.score)
        TrophyService:UpdateTrophyProgress(player, "total_coins", playerData.totalCoinsEarned or 0)
        
        -- Check for perfect game trophies
        if reason ~= "wrong_color" then
            TrophyService:UpdateTrophyProgress(player, "perfect_games", (playerData.perfectGames or 0) + 1)
        end
        
        -- Update login streak progress
        TrophyService:UpdateTrophyProgress(player, "login_streak", playerData.currentStreak or 0)
    end
    
    -- Update weekly leaderboard with coins earned
    if coinReward > 0 then
        -- Get the weekly leaderboard service and add coins
        local WeeklyLeaderboardService = require(script.Parent.WeeklyLeaderboardService)
        WeeklyLeaderboardService:AddCoinsToPlayer(player, coinReward)
    end
    
    -- Notify client
    RemoteEvents.GameEnded:FireClient(player, {
        score = session.score,
        barriersPassed = session.barriersPassed,
        coinsCollected = session.coinsCollected,
        coinReward = coinReward,
        reason = reason,
        isWorldEvent = isWorldEventActive,
        eventMultiplier = session.eventMultiplierApplied
    })
    
    -- Stop background music for the run
    RemoteEvents.ClientStopGameMusic:FireClient(player)
    
    -- Award XP based on performance
    if LevelingService then
        local gameTime = tick() - (session.startTime or tick())
        local isPerfectGame = session.barriersPassed > 0 and session.score >= session.barriersPassed * 10 -- No missed barriers
        
        -- Apply pet XP multiplier
        local xpMultiplier = gameData.xpMultiplier or 1
        LevelingService:AwardXp(player, session.score, session.barriersPassed, isPerfectGame, isNewHighScore, xpMultiplier)
        
        if xpMultiplier > 1 then
            print("🐾 Pet XP bonus applied: " .. ((xpMultiplier - 1) * 100) .. "% XP boost!")
        end
    end
    
    -- Handle event run completion
    if EventService and session.gameMode == "event" and EventService:IsPlayerInEvent(player) then
        EventService:EndEventRun(player, session.score, session.barriersPassed)
    end
    
    -- Stop ghost recording and save
    if GhostService then
        local ghostRun = GhostService:StopRecording(player, session.score)
        if ghostRun then
            -- Notify client that ghost was saved
            RemoteEvents.GhostSaved:FireClient(player, {
                score = session.score,
                duration = ghostRun.duration,
                pathPoints = #ghostRun.path
            })
        end
    end
    
    -- Show share score interface
    local shareData = {
        score = session.score,
        barriersPassed = session.barriersPassed,
        coinsCollected = session.coinsCollected,
        coinReward = coinReward,
        gameMode = session.gameMode,
        isNewHighScore = isNewHighScore,
        isPerfect = session.barriersPassed > 0 and session.score >= session.barriersPassed * 10,
        hasUpgrades = self:PlayerHasUpgrades(player),
        ghostVictory = session.ghostVictory or false,
        gameTime = tick() - (session.startTime or tick())
    }
    
    -- Only show share interface for meaningful scores (3+ barriers or new high score)
    if session.barriersPassed >= 3 or isNewHighScore or shareData.isPerfect then
        RemoteEvents.ShowShareScore:FireClient(player, shareData)
    end
    
    -- Log analytics event for run end
    if AnalyticsService then
        local gameTime = tick() - (session.startTime or tick())
        local eventType = session.gameMode == "event" and AnalyticsService.EventTypes.EVENT_RUN_END or AnalyticsService.EventTypes.RUN_END
        AnalyticsService:LogEvent(player, eventType, {
            finalScore = session.score,
            barriersPassed = session.barriersPassed,
            coinsCollected = session.coinsCollected,
            coinReward = coinReward,
            gameTime = gameTime,
            endReason = reason,
            isNewHighScore = isNewHighScore,
            gameMode = session.gameMode or "normal"
        })
    end
    
    print("🏁 " .. player.Name .. " finished with score: " .. session.score .. " (" .. (session.gameMode or "normal") .. " mode)")
end

function GameService:PassBarrier(player, barrierColor, playerColor)
    local session = activeGames[player.UserId]
    if not session or not session.isPlaying then
        return
    end
    
    if barrierColor == playerColor then
        -- Correct color!
        local baseReward = GameConstants.BARRIER_REWARD
        
        -- Apply upgrade effects
        local finalReward = baseReward
        local bonusCoins = 0
        
        if UpgradeService then
            -- Apply score multiplier upgrade
            finalReward = UpgradeService:ApplyUpgradeEffects(player, baseReward, "score_multiplier")
            
            -- Apply bonus coins upgrade
            bonusCoins = UpgradeService:ApplyUpgradeEffects(player, 0, "bonus_coins")
        end
        
        session.score = session.score + finalReward
        session.barriersPassed = session.barriersPassed + 1
        
        -- Award bonus coins if player has upgrade
        if bonusCoins > 0 and PlayerService then
            local playerData = PlayerService:GetPlayerData(player)
            if playerData then
                playerData.coins = playerData.coins + bonusCoins
                PlayerService:UpdatePlayerData(player, playerData)
                
                -- Notify client about bonus coins
                RemoteEvents.BonusCoinsEarned:FireClient(player, bonusCoins)
                print("💰 " .. player.Name .. " earned " .. bonusCoins .. " bonus coins from upgrade!")
            end
        end
        
        -- Track quest progress for color matching
        if QuestService then
            QuestService:UpdateQuestProgress(player, "color_match", 1, {color = barrierColor:lower()})
        end
        
        -- Log analytics event for successful barrier match
        if AnalyticsService then
            AnalyticsService:LogEvent(player, AnalyticsService.EventTypes.BARRIER_MATCH, {
                barrierColor = barrierColor,
                playerColor = playerColor,
                newScore = session.score,
                barriersPassed = session.barriersPassed
            })
        end
        
        -- Record ghost barrier interaction
        if GhostService then
            local character = player.Character
            if character and character:FindFirstChild("HumanoidRootPart") then
                GhostService:RecordBarrierInteraction(player, character.HumanoidRootPart.Position, barrierColor, true, session.score)
            end
        end
        
        RemoteEvents.BarrierPassed:FireClient(player, true, session.score)
        print("✅ " .. player.Name .. " passed " .. barrierColor .. " barrier!")
    else
        -- Wrong color!
        local basePenalty = GameConstants.WRONG_COLOR_PENALTY
        local finalPenalty = basePenalty
        
        -- Apply upgrade effects to reduce penalty
        if UpgradeService then
            finalPenalty = UpgradeService:ApplyUpgradeEffects(player, basePenalty, "penalty_reduction")
        end
        
        session.score = math.max(0, session.score + finalPenalty)
        
        print("❌ " .. player.Name .. " hit wrong color! Penalty: " .. finalPenalty .. " (was " .. basePenalty .. ")")
        
        -- Log analytics event for barrier miss
        if AnalyticsService then
            AnalyticsService:LogEvent(player, AnalyticsService.EventTypes.BARRIER_MISS, {
                barrierColor = barrierColor,
                playerColor = playerColor,
                newScore = session.score,
                penalty = GameConstants.WRONG_COLOR_PENALTY
            })
        end
        
        -- Record ghost barrier interaction (miss)
        if GhostService then
            local character = player.Character
            if character and character:FindFirstChild("HumanoidRootPart") then
                GhostService:RecordBarrierInteraction(player, character.HumanoidRootPart.Position, barrierColor, false, session.score)
            end
        end
        
        RemoteEvents.BarrierPassed:FireClient(player, false, session.score)
        print("❌ " .. player.Name .. " hit wrong color barrier!")
        
        -- End game on wrong color
        self:EndGame(player, "wrong_color")
    end
end

function GameService:CollectCoin(player)
    local session = activeGames[player.UserId]
    if not session or not session.isPlaying then
        return
    end
    
    -- Get coin multiplier from player upgrades and VIP gamepass
    local coinMultiplier = 1
    if MonetizationService then
        coinMultiplier = MonetizationService:GetPlayerCoinMultiplier(player)
    else
        -- Fallback to basic upgrade multiplier if MonetizationService not available
        local playerData = PlayerService:GetPlayerData(player)
        if playerData and playerData.coinMultiplier then
            coinMultiplier = playerData.coinMultiplier
        end
    end
    
    session.coinsCollected = session.coinsCollected + coinMultiplier
    
    -- Log analytics event for coin collection
    if AnalyticsService then
        AnalyticsService:LogEvent(player, AnalyticsService.EventTypes.COIN_COLLECTED, {
            coinMultiplier = coinMultiplier,
            totalCoins = session.coinsCollected
        })
    end
    
    RemoteEvents.CoinCollected:FireClient(player, session.coinsCollected)
    print("💰 " .. player.Name .. " collected a coin! (x" .. coinMultiplier .. " multiplier)")
end

function GameService:ChangePlayerColor(player)
    local session = activeGames[player.UserId]
    if not session or not session.isPlaying then
        return
    end
    
    -- Pick a new random color different from current
    local availableColors = {}
    for _, colorName in pairs(GameConstants.COLOR_NAMES) do
        if colorName ~= session.currentColor then
            table.insert(availableColors, colorName)
        end
    end
    
    local newColor = availableColors[math.random(1, #availableColors)]
    session.currentColor = newColor
    session.nextColorChange = tick() + GameConstants.COLOR_CHANGE_TIME
    
    -- Update player data
    local playerData = PlayerService:GetPlayerData(player)
    playerData.currentColor = newColor
    PlayerService:UpdatePlayerData(player, playerData)
    
    RemoteEvents.ColorChanged:FireClient(player, newColor)
    print("🎨 " .. player.Name .. " color changed to " .. newColor)
end

function GameService:ReturnPlayerToHub(player)
    -- Clean up any active game session
    if activeGames[player.UserId] then
        self:CleanupPlayerBarriers(player)
        activeGames[player.UserId] = nil
        print("🏠 " .. player.Name .. " cleaned up game session")
    end
    
    -- Teleport player back to market plaza
    local character = player.Character
    if character and character:FindFirstChild("HumanoidRootPart") then
        -- Use the same spawn positions as PlayerService
        local spawnPositions = {
            Vector3.new(8, 5, 8),   -- Northeast of fountain
            Vector3.new(-8, 5, 8),  -- Northwest of fountain
            Vector3.new(8, 5, -8),  -- Southeast of fountain
            Vector3.new(-8, 5, -8), -- Southwest of fountain
            Vector3.new(0, 5, 12),  -- North of fountain
            Vector3.new(0, 5, -12), -- South of fountain
            Vector3.new(12, 5, 0),  -- East of fountain
            Vector3.new(-12, 5, 0)  -- West of fountain
        }
        
        local randomSpawn = spawnPositions[math.random(1, #spawnPositions)]
        character.HumanoidRootPart.CFrame = CFrame.new(randomSpawn)
        
        print("🏠 " .. player.Name .. " returned to market plaza")
    end
end

function GameService:Init()
    -- Handle color change timing and barrier spawning
    RunService.Heartbeat:Connect(function()
        for userId, session in pairs(activeGames) do
            if session.isPlaying then
                local player = Players:GetPlayerByUserId(userId)
                if player then
                    -- Handle color changes
                    if tick() >= session.nextColorChange then
                        self:ChangePlayerColor(player)
                    end
                    
                    -- Handle barrier spawning
                    self:UpdateBarrierSpawning(player)
                end
            end
        end
    end)
    
    -- Periodic barrier cleanup system (every 30 seconds)
    spawn(function()
        while true do
            wait(30) -- Wait 30 seconds between cleanup cycles
            
            local totalCleaned = 0
            local activePlayers = 0
            
            -- Clean up old barriers for all active players
            for userId, session in pairs(activeGames) do
                if session.isPlaying then
                    local player = Players:GetPlayerByUserId(userId)
                    if player then
                        local beforeCount = barriers[userId] and #barriers[userId] or 0
                        self:CleanupOldBarriers(player)
                        local afterCount = barriers[userId] and #barriers[userId] or 0
                        totalCleaned = totalCleaned + (beforeCount - afterCount)
                        activePlayers = activePlayers + 1
                    end
                end
            end
            
            -- Get overall barrier statistics
            local stats = self:GetBarrierStats()
            
            print("🧹 Periodic barrier cleanup completed - Players: " .. activePlayers .. ", Total cleaned: " .. totalCleaned .. ", Remaining barriers: " .. stats.totalBarriers)
            
            -- Log analytics for system monitoring
            if AnalyticsService and (totalCleaned > 0 or stats.totalBarriers > 50) then
                AnalyticsService:LogEvent(nil, "barrier_system_stats", {
                    activePlayers = activePlayers,
                    totalBarriersCleaned = totalCleaned,
                    remainingBarriers = stats.totalBarriers,
                    playersWithBarriers = stats.totalPlayers
                })
            end
        end
    end)
    
    -- Handle remote events
    RemoteEvents.StartGame.OnServerEvent:Connect(function(player)
        self:StartGame(player)
    end)
    
    RemoteEvents.EndGame.OnServerEvent:Connect(function(player, reason)
        self:EndGame(player, reason or "manual")
    end)
    
    RemoteEvents.BarrierHit.OnServerEvent:Connect(function(player, barrierColor, playerColor)
        self:PassBarrier(player, barrierColor, playerColor)
    end)
    
    RemoteEvents.CoinHit.OnServerEvent:Connect(function(player)
        self:CollectCoin(player)
    end)
    
    RemoteEvents.ReturnToHub.OnServerEvent:Connect(function(player)
        self:ReturnPlayerToHub(player)
    end)
    
    -- Handle share events for analytics
    RemoteEvents.LogShareEvent.OnServerEvent:Connect(function(player, shareType, shareData)
        if AnalyticsService then
            AnalyticsService:LogEvent(player, "score_shared", {
                shareType = shareType,
                score = shareData.score,
                barriers = shareData.barriers,
                template = shareData.template,
                timestamp = os.time()
            })
        end
        
        -- Update quest progress for sharing
        if QuestService then
            QuestService:UpdateQuestProgress(player, "score_shared", 1, shareData)
            
            -- Check for epic share (perfect run or high score)
            if shareData.isPerfect or shareData.isNewHighScore then
                QuestService:UpdateQuestProgress(player, "epic_share", 1, shareData)
            end
        end
        
        print("📤 " .. player.Name .. " shared their score (" .. shareType .. "): " .. (shareData.score or 0))
    end)
    
    -- Handle player leaving to clean up barriers
    Players.PlayerRemoving:Connect(function(player)
        self:CleanupPlayerBarriers(player)
        if activeGames[player.UserId] then
            activeGames[player.UserId] = nil
        end
    end)
    
    print("✅ GameService initialized")
end

function GameService:PlayerHasUpgrades(player)
    -- Check if player has any upgrades
    if UpgradeService then
        local upgrades = UpgradeService:GetPlayerUpgrades(player)
        if upgrades then
            for _, level in pairs(upgrades) do
                if level > 0 then
                    return true
                end
            end
        end
    end
    return false
end

function GameService:SetQuestService(service)
    QuestService = service
end

function GameService:SetPlayerService(service)
    PlayerService = service
end

function GameService:SetAnalyticsService(service)
    AnalyticsService = service
end

function GameService:SetMonetizationService(service)
    MonetizationService = service
end

function GameService:SetLevelingService(service)
    LevelingService = service
end

function GameService:SetEventService(service)
    EventService = service
end

function GameService:SetGhostService(service)
    GhostService = service
end

function GameService:SetUpgradeService(service)
    UpgradeService = service
end

function GameService:SetTrophyService(service)
    TrophyService = service
end

function GameService:SetPetService(service)
    PetService = service
end

function GameService:SetSpectatorService(service)
    SpectatorService = service
end

function GameService:SetTournamentService(service)
    TournamentService = service
end

function GameService:SetRebirthService(service)
    RebirthService = service
end

return GameService
