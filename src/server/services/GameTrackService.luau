-- GameTrackService.luau
-- Multi-difficulty track system with XP progression unlocks (Standardized Enhanced Service)

local Workspace = game:GetService("Workspace")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local Debris = game:GetService("Debris")

local SafeRequire = require(ReplicatedStorage.Shared.utils.SafeRequire)
local ServiceBase = SafeRequire.require(ReplicatedStorage.Shared.utils.ServiceBase)
local WorldObjectValidator = SafeRequire.require(ReplicatedStorage.Shared.utils.WorldObjectValidator)

local GameTrackService = ServiceBase.new("GameTrackService", {
    enableDetailedLogging = true,
    retryFailedRequires = true,
    maxRetryAttempts = 3,
    validateOnStart = true,
    autoStart = false
})

-- Define dependencies
GameTrackService.Dependencies = {
    { path = ReplicatedStorage.Shared.modules.RemoteEvents, name = "RemoteEvents", optional = false },
    { path = script.Parent.core.PlayerService, name = "PlayerService", optional = true },
    { path = script.Parent.economy.CoinService, name = "CoinService", optional = true },
    { path = script.Parent.AnalyticsService, name = "AnalyticsService", optional = true },
    { path = script.Parent.LevelingService, name = "LevelingService", optional = true },
    { path = script.Parent.core.EconomyBalanceService, name = "EconomyBalanceService", optional = true },
}

-- Service state
local connectionIds = {}
local activeGames = {}
local trackModels = {}

-- Difficulty Configurations
local DIFFICULTY_SETTINGS = {
	Easy = {
		trackLength = 400,
		trackWidth = 35,
		gameDuration = 90, -- More time for beginners
		gateInterval = 50, -- Gates further apart
		obstacleFrequency = 0.15, -- 15% chance of obstacles
		coinInterval = 6, -- More coins
		speedMultiplier = 1.0,
		xpRequirement = 0, -- Always unlocked
		rewardMultiplier = 1.0,
		color = Color3.fromRGB(85, 255, 85), -- Green theme
		name = "Easy Track",
		description = "Perfect for beginners",
		position = Vector3.new(150, 5, 0)
	},
	Medium = {
		trackLength = 500,
		trackWidth = 30,
		gameDuration = 75,
		gateInterval = 40,
		obstacleFrequency = 0.25, -- 25% chance
		coinInterval = 8,
		speedMultiplier = 1.2,
		xpRequirement = 500, -- Need 500 XP to unlock
		rewardMultiplier = 1.5,
		color = Color3.fromRGB(255, 255, 85), -- Yellow theme
		name = "Medium Track",
		description = "For experienced runners",
		position = Vector3.new(200, 5, 0)
	},
	Hard = {
		trackLength = 600,
		trackWidth = 25,
		gameDuration = 60, -- Less time
		gateInterval = 30, -- Gates closer together
		obstacleFrequency = 0.4, -- 40% chance
		coinInterval = 10, -- Fewer coins
		speedMultiplier = 1.5,
		xpRequirement = 1500, -- Need 1500 XP to unlock
		rewardMultiplier = 2.0,
		color = Color3.fromRGB(255, 85, 85), -- Red theme
		name = "Hard Track",
		description = "For elite runners only",
		position = Vector3.new(250, 5, 0)
	}
}

-- Color system
local COLORS = {
    Red = {color = Color3.fromRGB(255, 100, 100), name = "Red"},
    Blue = {color = Color3.fromRGB(100, 150, 255), name = "Blue"},
    Green = {color = Color3.fromRGB(100, 255, 100), name = "Green"},
    Yellow = {color = Color3.fromRGB(255, 255, 100), name = "Yellow"},
}

local COLOR_ORDER = {"Red", "Blue", "Green", "Yellow"}

-- Game state tracking
local activeGames = {}
local trackModels = {}

-- Service-specific initialization
function GameTrackService:OnInit()
    -- Validate track-related world objects
    print("🔍 Validating game track world objects...")
    local missingObjects = WorldObjectValidator.validateAllRequired()
    if #missingObjects > 0 then
        warn("⚠️ GameTrackService: Missing required world objects:")
        for _, missing in ipairs(missingObjects) do
            warn("  • " .. missing)
        end
    end
    
    -- Validate teleport pads for difficulty selection
    local teleportPadsValidated = 0
    local teleportPads = {"workspace.TeleportPads.EasyPad", "workspace.TeleportPads.MediumPad", "workspace.TeleportPads.HardPad"}
    for _, padPath in ipairs(teleportPads) do
        local exists = WorldObjectValidator.validateObjectWithWait(padPath, 3)
        if exists then
            teleportPadsValidated = teleportPadsValidated + 1
        else
            warn("⚠️ GameTrackService: Missing teleport pad: " .. padPath)
        end
    end
    
    if teleportPadsValidated > 0 then
        print("✅ GameTrackService: " .. teleportPadsValidated .. " teleport pads validated")
    end
    
    -- Initialize game state
    activeGames = {}
    trackModels = {}
    
    return true
end

-- Service-specific start logic  
function GameTrackService:OnStart()
    -- Create all difficulty tracks
    self:CreateAllTracks()
    
    print("✅ GameTrackService started with", #DIFFICULTY_SETTINGS, "difficulty tracks")
    return true
end

-- Setup remote events
function GameTrackService:SetupRemoteEvents()
    if self.RemoteEvents then
        -- Start game
        local startGameEvent = self.RemoteEvents:GetRemoteFunction("StartTrackGame")
        if startGameEvent then
            startGameEvent.OnServerInvoke = function(player, difficulty)
                return self:StartGame(player, difficulty)
            end
        end
        
        -- End game
        local endGameEvent = self.RemoteEvents:GetRemoteFunction("EndTrackGame") 
        if endGameEvent then
            endGameEvent.OnServerInvoke = function(player, reason)
                return self:EndGame(player, reason)
            end
        end
        
        -- Get unlocked difficulties
        local difficultiesEvent = self.RemoteEvents:GetRemoteFunction("GetUnlockedDifficulties")
        if difficultiesEvent then
            difficultiesEvent.OnServerInvoke = function(player)
                return self:GetUnlockedDifficulties(player)
            end
        end
    end
end

-- Setup connections
function GameTrackService:SetupConnections()
    -- Player management
    self.Connections.PlayerRemoving = Players.PlayerRemoving:Connect(function(player)
        if self:IsPlayerInGame(player) then
            self:EndGame(player, "disconnect")
        end
    end)
end

function GameTrackService:Initialize()
    -- Legacy method compatibility - use OnInit instead
    return self:OnInit()
end

function GameTrackService:CreateAllTracks()
    print("🏗️ Creating all difficulty tracks...")
    
    for difficulty, config in pairs(DIFFICULTY_SETTINGS) do
        trackModels[difficulty] = self:CreateTrack(difficulty, config)
    end
end

function GameTrackService:CreateTrack(difficulty, config)
    print("🏁 Creating " .. difficulty .. " track...")
    
    -- Create track container
    local trackModel = Instance.new("Model")
    trackModel.Name = "GameTrack_" .. difficulty
    trackModel.Parent = Workspace
    
    -- Create start platform
    local startPlatform = Instance.new("Part")
    startPlatform.Name = "StartPlatform"
    startPlatform.Size = Vector3.new(config.trackWidth, 2, 20)
    startPlatform.Position = config.position
    startPlatform.Anchored = true
    startPlatform.BrickColor = BrickColor.new("Bright green")
    startPlatform.Material = Enum.Material.Neon
    startPlatform.Parent = trackModel
    
    -- Add start line text
    local startGui = Instance.new("SurfaceGui")
    startGui.Face = Enum.NormalId.Top
    startGui.Parent = startPlatform
    
    local startLabel = Instance.new("TextLabel")
    startLabel.Size = UDim2.new(1, 0, 1, 0)
    startLabel.BackgroundTransparency = 1
    startLabel.Text = config.name .. "\n" .. config.description
    startLabel.TextColor3 = Color3.new(1, 1, 1)
    startLabel.TextScaled = true
    startLabel.Font = Enum.Font.SourceSansBold
    startLabel.Parent = startGui
    
    -- Create main track sections
    local sectionCount = math.ceil(config.trackLength / config.gateInterval)
    
    for i = 1, sectionCount do
        local sectionZ = i * config.gateInterval
        
        -- Create track section
        self:CreateTrackSection(trackModel, config, sectionZ, i)
        
        -- Add color gate
        if i > 1 then -- Skip first section
            self:CreateColorGate(trackModel, config, sectionZ - config.gateInterval/2, difficulty)
        end
        
        -- Add obstacles based on frequency
        if math.random() < config.obstacleFrequency and i > 1 then
            self:CreateObstacle(trackModel, config, sectionZ - config.gateInterval/4, difficulty)
        end
        
        -- Add coin pickups
        local coinZ = sectionZ - config.gateInterval/2
        if i > 1 and coinZ % config.coinInterval == 0 then
            self:CreateCoinPickup(trackModel, config, coinZ)
        end
    end
    
    -- Create finish line
    self:CreateFinishLine(trackModel, config, config.trackLength)
    
    return trackModel
end

function GameTrackService:CreateTrackSection(trackModel, config, zPosition, sectionIndex)
    local laneWidth = config.trackWidth / 3
    
    for lane = 1, 3 do
        local part = Instance.new("Part")
        part.Name = "TrackSection_" .. sectionIndex .. "_Lane" .. lane
        part.Size = Vector3.new(laneWidth - 1, 1, config.gateInterval)
        part.Position = Vector3.new(
            config.position.X + (lane - 2) * laneWidth,
            config.position.Y - 1,
            config.position.Z + zPosition
        )
        part.Anchored = true
        part.BrickColor = BrickColor.new("Medium stone grey")
        part.Material = Enum.Material.Concrete
        part.Parent = trackModel
        
        -- Add lane markings
        if lane < 3 then
            local marker = Instance.new("Part")
            marker.Name = "LaneMarker"
            marker.Size = Vector3.new(0.5, 0.1, config.gateInterval)
            marker.Position = part.Position + Vector3.new(laneWidth/2, 0.5, 0)
            marker.Anchored = true
            marker.BrickColor = BrickColor.new("Bright yellow")
            marker.Material = Enum.Material.Neon
            marker.Parent = trackModel
        end
    end
end

function GameTrackService:CreateColorGate(trackModel, config, zPosition, difficulty)
    local gateColor = COLOR_ORDER[math.random(#COLOR_ORDER)]
    local colorData = COLORS[gateColor]
    
    local gate = Instance.new("Part")
    gate.Name = "ColorGate_" .. gateColor
    gate.Size = Vector3.new(config.trackWidth + 5, 8, 2)
    gate.Position = Vector3.new(config.position.X, config.position.Y + 4, config.position.Z + zPosition)
    gate.Anchored = true
    gate.BrickColor = BrickColor.new(gateColor)
    gate.Material = Enum.Material.ForceField
    gate.Transparency = 0.3
    gate.CanCollide = false
    gate.Parent = trackModel
    
    -- Add gate indicator
    local indicator = Instance.new("SurfaceGui")
    indicator.Face = Enum.NormalId.Front
    indicator.Parent = gate
    
    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, 0, 1, 0)
    label.BackgroundTransparency = 1
    label.Text = gateColor:upper()
    label.TextColor3 = Color3.new(1, 1, 1)
    label.TextScaled = true
    label.Font = Enum.Font.SourceSansBold
    label.Parent = indicator
    
    -- Store gate data
    gate:SetAttribute("RequiredColor", gateColor)
    gate:SetAttribute("Difficulty", difficulty)
    
    return gate
end

function GameTrackService:CreateObstacle(trackModel, config, zPosition, difficulty)
    local lane = math.random(1, 3)
    local laneWidth = config.trackWidth / 3
    
    local obstacle = Instance.new("Part")
    obstacle.Name = "Obstacle"
    obstacle.Size = Vector3.new(laneWidth - 2, 4, 3)
    obstacle.Position = Vector3.new(
        config.position.X + (lane - 2) * laneWidth,
        config.position.Y + 2,
        config.position.Z + zPosition
    )
    obstacle.Anchored = true
    obstacle.BrickColor = BrickColor.new("Really red")
    obstacle.Material = Enum.Material.Neon
    obstacle.Parent = trackModel
    
    -- Add warning stripes
    for i = 1, 3 do
        local stripe = Instance.new("Part")
        stripe.Name = "WarningStripe"
        stripe.Size = Vector3.new(laneWidth - 2, 0.2, 0.5)
        stripe.Position = obstacle.Position + Vector3.new(0, 2.5, -1 + i * 0.5)
        stripe.Anchored = true
        stripe.BrickColor = BrickColor.new("Bright yellow")
        stripe.Material = Enum.Material.Neon
        stripe.Parent = trackModel
    end
    
    -- Add collision detection
    obstacle:SetAttribute("IsObstacle", true)
    obstacle:SetAttribute("Difficulty", difficulty)
    
    return obstacle
end

function GameTrackService:CreateCoinPickup(trackModel, config, zPosition)
    local lane = math.random(1, 3)
    local laneWidth = config.trackWidth / 3
    
    local coin = Instance.new("Part")
    coin.Name = "CoinPickup"
    coin.Size = Vector3.new(2, 2, 0.5)
    coin.Position = Vector3.new(
        config.position.X + (lane - 2) * laneWidth,
        config.position.Y + 3,
        config.position.Z + zPosition
    )
    coin.Anchored = true
    coin.BrickColor = BrickColor.new("Bright yellow")
    coin.Material = Enum.Material.Neon
    coin.Shape = Enum.PartType.Cylinder
    coin.CanCollide = false
    coin.Parent = trackModel
    
    -- Add spinning animation
    local spinTween = TweenService:Create(
        coin,
        TweenInfo.new(2, Enum.EasingStyle.Linear, Enum.EasingDirection.InOut, -1),
        {Rotation = coin.Rotation + Vector3.new(0, 360, 0)}
    )
    spinTween:Play()
    
    -- Add coin pickup detection
    coin:SetAttribute("IsCoin", true)
    coin:SetAttribute("CoinValue", 10)
    
    return coin
end

function GameTrackService:CreateFinishLine(trackModel, config, zPosition)
    local finishLine = Instance.new("Part")
    finishLine.Name = "FinishLine"
    finishLine.Size = Vector3.new(config.trackWidth + 5, 8, 2)
    finishLine.Position = Vector3.new(config.position.X, config.position.Y + 4, config.position.Z + zPosition)
    finishLine.Anchored = true
    finishLine.BrickColor = BrickColor.new("Institutional white")
    finishLine.Material = Enum.Material.Neon
    finishLine.Transparency = 0.5
    finishLine.CanCollide = false
    finishLine.Parent = trackModel
    
    -- Add checkered pattern
    for i = 1, 8 do
        for j = 1, 4 do
            local square = Instance.new("Part")
            square.Name = "CheckerSquare"
            square.Size = Vector3.new(config.trackWidth/4, 2, 0.1)
            square.Position = finishLine.Position + Vector3.new(
                (j - 2.5) * config.trackWidth/4,
                (i - 4.5) * 2,
                0.1
            )
            square.Anchored = true
            square.CanCollide = false
            
            if (i + j) % 2 == 0 then
                square.BrickColor = BrickColor.new("Really black")
            else
                square.BrickColor = BrickColor.new("Institutional white")
            end
            
            square.Parent = trackModel
        end
    end
    
    finishLine:SetAttribute("IsFinishLine", true)
    
    return finishLine
end

function GameTrackService:StartGame(player, difficulty)
    if activeGames[player] then
        return false, "Already in a game"
    end
    
    local config = DIFFICULTY_SETTINGS[difficulty]
    if not config then
        return false, "Invalid difficulty"
    end
    
    -- Check XP requirement using SafeRequire
    local playerXP = 0
    if self.LevelingService then
        playerXP = self.LevelingService:GetPlayerXP(player)
    end
    
    if playerXP < config.xpRequirement then
        return false, "Need " .. config.xpRequirement .. " XP to unlock " .. difficulty .. " track"
    end
    
    -- Initialize game state
    local gameState = {
        player = player,
        difficulty = difficulty,
        config = config,
        startTime = tick(),
        score = 0,
        coinsCollected = 0,
        obstaclesHit = 0,
        gatesPassed = 0,
        currentColor = "Red",
        timeRemaining = config.gameDuration,
        active = true
    }
    
    activeGames[player] = gameState
    
    -- Teleport player to start
    if player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
        player.Character.HumanoidRootPart.CFrame = CFrame.new(config.position + Vector3.new(0, 3, -10))
    end
    
    -- Start game timer
    self:StartGameTimer(gameState)
    
    -- Notify client using SafeRequire
    if self.RemoteEvents then
        local gameStartedEvent = self.RemoteEvents:GetRemoteEvent("GameStarted")
        if gameStartedEvent then
            gameStartedEvent:FireClient(player, difficulty, config)
        end
    end
    
    print("🎮 Started " .. difficulty .. " game for " .. player.Name)
    
    return true, "Game started!"
end

function GameTrackService:StartGameTimer(gameState)
    local connection
    connection = RunService.Heartbeat:Connect(function()
        if not gameState.active then
            connection:Disconnect()
            return
        end
        
        gameState.timeRemaining = gameState.config.gameDuration - (tick() - gameState.startTime)
        
        if gameState.timeRemaining <= 0 then
            self:EndGame(gameState.player, "timeout")
            connection:Disconnect()
        else
            -- Update client timer using SafeRequire
            if self.RemoteEvents then
                local gameTimerEvent = self.RemoteEvents:GetRemoteEvent("GameTimer")
                if gameTimerEvent then
                    gameTimerEvent:FireClient(gameState.player, gameState.timeRemaining)
                end
            end
        end
    end)
end

function GameTrackService:EndGame(player, reason)
    local gameState = activeGames[player]
    if not gameState then
        return
    end
    
    gameState.active = false
    
    -- Calculate final score
    local finalScore = self:CalculateScore(gameState)
    
    -- Prepare run data for economy balance service
    local runData = {
        difficulty = string.lower(gameState.difficulty),
        correctBarriers = gameState.gatesPassed,
        perfect = (gameState.obstaclesHit == 0 and reason == "completed"),
        streak = gameState.streak or 0,
        coinsCollected = gameState.coinsCollected,
        timeTaken = gameState.timeRemaining and (gameState.config.gameDuration - gameState.timeRemaining) or gameState.config.gameDuration
    }
    
    -- Calculate balanced rewards using SafeRequire
    local rewardData = {coins = 0, xp = 0}
    if self.EconomyBalanceService then
        rewardData = self.EconomyBalanceService:CalculateRunReward(player, runData)
    end
    
    -- Award rewards (only if not on cooldown or capped) using SafeRequire
    if rewardData.coins > 0 and rewardData.xp > 0 then
        if self.CoinService then
            self.CoinService:AddCoins(player, rewardData.coins)
        end
        if self.LevelingService then
            self.LevelingService:AddXP(player, rewardData.xp)
        end
        
        print("🏁 " .. player.Name .. " earned " .. rewardData.coins .. " coins, " .. rewardData.xp .. " XP from " .. gameState.difficulty .. " run")
    elseif rewardData.reason then
        warn("⚠️ " .. player.Name .. " reward limited: " .. rewardData.reason)
    end
    
    -- Send results to client
    local results = {
        score = finalScore,
        coinsCollected = gameState.coinsCollected,
        coinReward = rewardData.coins,
        xpReward = rewardData.xp,
        difficulty = gameState.difficulty,
        gatesPassed = gameState.gatesPassed,
        obstaclesHit = gameState.obstaclesHit,
        rewardReason = rewardData.reason,
        rewardBreakdown = rewardData.breakdown -- For debugging/transparency
    }
    
    -- Send results to client using SafeRequire
    if self.RemoteEvents then
        local gameResultsEvent = self.RemoteEvents:GetRemoteEvent("GameResults")
        if gameResultsEvent then
            gameResultsEvent:FireClient(player, results)
        end
    end
    
    -- Analytics using SafeRequire
    if self.AnalyticsService then
        self.AnalyticsService:TrackEvent(player, "game_completed", {
            difficulty = gameState.difficulty,
            score = finalScore,
            reason = reason
        })
    end
    
    -- Clean up
    activeGames[player] = nil
    
    -- Teleport back to hub after delay
    task.wait(5)
    if player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
        player.Character.HumanoidRootPart.CFrame = CFrame.new(0, 10, 0) -- Hub spawn
    end
    
    print("🏁 Game ended for " .. player.Name .. " - Score: " .. finalScore)
end

function GameTrackService:CalculateScore(gameState)
    local baseScore = gameState.gatesPassed * 100
    local coinBonus = gameState.coinsCollected * 50
    local timeBonus = math.max(0, gameState.timeRemaining * 10)
    local obstaclePenalty = gameState.obstaclesHit * 25
    
    return math.max(0, baseScore + coinBonus + timeBonus - obstaclePenalty)
end

function GameTrackService:GetPlayerDifficulty(player)
    local gameState = activeGames[player]
    return gameState and gameState.difficulty or nil
end

function GameTrackService:IsPlayerInGame(player)
    return activeGames[player] ~= nil
end

function GameTrackService:GetUnlockedDifficulties(player)
    local playerXP = 0
    if self.LevelingService then
        playerXP = self.LevelingService:GetPlayerXP(player)
    end
    
    local unlocked = {}
    
    for difficulty, config in pairs(DIFFICULTY_SETTINGS) do
        if playerXP >= config.xpRequirement then
            table.insert(unlocked, {
                difficulty = difficulty,
                config = config
            })
        end
    end
    
    return unlocked
end

-- Service-specific cleanup
function GameTrackService:OnCleanup()
    -- End all active games
    for player, gameState in pairs(activeGames) do
        if gameState.active then
            self:EndGame(player, "shutdown")
        end
    end
    
    -- Clean up track models
    for difficulty, trackModel in pairs(trackModels) do
        if trackModel and trackModel.Parent then
            trackModel:Destroy()
        end
    end
    
    trackModels = {}
    activeGames = {}
end

return GameTrackService
