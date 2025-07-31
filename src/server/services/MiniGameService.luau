-- MiniGameService.luau
-- Handles mini-games in the hub area for player engagement

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

local SafeRequire = require(ReplicatedStorage.Shared.utils.SafeRequire)
local WorldObjectValidator = SafeRequire.require(ReplicatedStorage.Shared.utils.WorldObjectValidator)
local PlayerService = SafeRequire.require(script.Parent.core.PlayerService)
local QuestService = SafeRequire.require(script.Parent.QuestService)
local RemoteEvents = SafeRequire.require(ReplicatedStorage.Shared.modules.RemoteEvents)

local MiniGameService = {}

-- Mini-game data
local activeMiniGames = {} -- [gameId] = {gameData}
local playerScores = {} -- [gameId] = {[userId] = score}
local gameCooldowns = {} -- [userId] = {[gameType] = lastPlayTime}

-- Game configurations
local MINI_GAMES = {
    jumpTarget = {
        name = "🎯 Jump to the Target",
        description = "Jump and touch the floating target!",
        duration = 10, -- seconds
        cooldown = 30, -- seconds between plays
        rewards = {
            coins = {min = 10, max = 50},
            xp = {min = 5, max = 25}
        },
        position = Vector3.new(35, 5, -25), -- Near queue area
        targetHeight = 8,
        targetRadius = 2
    },
    coinClicker = {
        name = "💰 Coin Clicker Rush",
        description = "Click coins as fast as you can!",
        duration = 8, -- seconds
        cooldown = 25, -- seconds between plays
        rewards = {
            coins = {min = 15, max = 60},
            xp = {min = 8, max = 30}
        },
        position = Vector3.new(-35, 5, -25), -- Near queue area opposite side
        spawnRate = 0.3, -- coins per second
        maxCoins = 25
    }
}

function MiniGameService:Init()
    print("🎮 MiniGameService initializing...")
    
    -- Validate mini-game-related world objects
    print("🔍 Validating mini-game world objects...")
    local missingObjects = WorldObjectValidator.validateAllRequired()
    if #missingObjects > 0 then
        warn("⚠️ MiniGameService: Missing required world objects:")
        for _, missing in ipairs(missingObjects) do
            warn("  • " .. missing)
        end
    end
    
    -- Validate hub area for mini-games
    local hubExists = WorldObjectValidator.validateObjectWithWait("workspace.Hub", 5)
    if not hubExists then
        warn("⚠️ MiniGameService: Hub not found - mini-games may not work properly")
    else
        print("✅ MiniGameService: Hub validated for mini-game placement")
    end
    
    -- Validate coin spawners area
    local coinSpawnersExist = WorldObjectValidator.validateObjectWithWait("workspace.CoinSpawners", 3)
    if not coinSpawnersExist then
        warn("⚠️ MiniGameService: CoinSpawners folder not found - coin clicker game may not work")
    else
        print("✅ MiniGameService: CoinSpawners validated")
    end
    
    wait(2) -- Wait for workspace to be ready
    
    -- Setup mini-game areas
    self:SetupJumpTargetGame()
    self:SetupCoinClickerGame()
    
    -- Setup remote event handlers
    self:SetupRemoteEvents()
    
    print("✅ MiniGameService initialized with hub mini-games!")
end

function MiniGameService:SetupJumpTargetGame()
    local gameConfig = MINI_GAMES.jumpTarget
    local gameArea = self:CreateGameArea(gameConfig, "JumpTargetArea")
    
    -- Create interaction pad
    local interactionPad = Instance.new("Part")
    interactionPad.Name = "JumpTargetPad"
    interactionPad.Size = Vector3.new(6, 1, 6)
    interactionPad.Position = gameConfig.position
    interactionPad.Material = Enum.Material.Neon
    interactionPad.BrickColor = BrickColor.new("Bright yellow")
    interactionPad.Anchored = true
    interactionPad.Parent = gameArea
    
    local padCorner = Instance.new("SpecialMesh")
    padCorner.MeshType = Enum.MeshType.Cylinder
    padCorner.Parent = interactionPad
    
    -- Add floating title
    self:CreateGameTitle(interactionPad, gameConfig.name, gameConfig.description)
    
    -- Add click detector
    local clickDetector = Instance.new("ClickDetector")
    clickDetector.MaxActivationDistance = 10
    clickDetector.Parent = interactionPad
    
    clickDetector.MouseClick:Connect(function(player)
        self:StartJumpTargetGame(player)
    end)
    
    -- Add glowing effect
    self:AddGlowEffect(interactionPad, Color3.new(1, 1, 0.2))
end

function MiniGameService:SetupCoinClickerGame()
    local gameConfig = MINI_GAMES.coinClicker
    local gameArea = self:CreateGameArea(gameConfig, "CoinClickerArea")
    
    -- Create interaction pad
    local interactionPad = Instance.new("Part")
    interactionPad.Name = "CoinClickerPad"
    interactionPad.Size = Vector3.new(6, 1, 6)
    interactionPad.Position = gameConfig.position
    interactionPad.Material = Enum.Material.Neon
    interactionPad.BrickColor = BrickColor.new("Bright green")
    interactionPad.Anchored = true
    interactionPad.Parent = gameArea
    
    local padCorner = Instance.new("SpecialMesh")
    padCorner.MeshType = Enum.MeshType.Cylinder
    padCorner.Parent = interactionPad
    
    -- Add floating title
    self:CreateGameTitle(interactionPad, gameConfig.name, gameConfig.description)
    
    -- Add click detector
    local clickDetector = Instance.new("ClickDetector")
    clickDetector.MaxActivationDistance = 10
    clickDetector.Parent = interactionPad
    
    clickDetector.MouseClick:Connect(function(player)
        self:StartCoinClickerGame(player)
    end)
    
    -- Add glowing effect
    self:AddGlowEffect(interactionPad, Color3.new(0.2, 1, 0.2))
end

function MiniGameService:CreateGameArea(gameConfig, areaName)
    local marketPlaza = Workspace:FindFirstChild("MarketPlaza")
    if not marketPlaza then
        warn("MarketPlaza not found for mini-games!")
        return Workspace
    end
    
    local gameArea = Instance.new("Model")
    gameArea.Name = areaName
    gameArea.Parent = marketPlaza
    
    return gameArea
end

function MiniGameService:CreateGameTitle(parent, title, description)
    local billboardGui = Instance.new("BillboardGui")
    billboardGui.Size = UDim2.new(0, 400, 0, 120)
    billboardGui.StudsOffset = Vector3.new(0, 4, 0)
    billboardGui.Parent = parent
    
    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(1, 0, 1, 0)
    frame.BackgroundColor3 = Color3.new(0.1, 0.1, 0.2)
    frame.BackgroundTransparency = 0.2
    frame.BorderSizePixel = 0
    frame.Parent = billboardGui
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 15)
    corner.Parent = frame
    
    local titleLabel = Instance.new("TextLabel")
    titleLabel.Size = UDim2.new(1, -20, 0, 50)
    titleLabel.Position = UDim2.new(0, 10, 0, 10)
    titleLabel.BackgroundTransparency = 1
    titleLabel.Text = title
    titleLabel.TextColor3 = Color3.new(1, 1, 1)
    titleLabel.TextScaled = true
    titleLabel.Font = Enum.Font.SourceSansBold
    titleLabel.TextStrokeTransparency = 0
    titleLabel.TextStrokeColor3 = Color3.new(0, 0, 0)
    titleLabel.Parent = frame
    
    local descLabel = Instance.new("TextLabel")
    descLabel.Size = UDim2.new(1, -20, 0, 30)
    descLabel.Position = UDim2.new(0, 10, 0, 60)
    descLabel.BackgroundTransparency = 1
    descLabel.Text = description
    descLabel.TextColor3 = Color3.new(0.8, 0.8, 0.8)
    descLabel.TextScaled = true
    descLabel.Font = Enum.Font.SourceSans
    descLabel.Parent = frame
    
    local playLabel = Instance.new("TextLabel")
    playLabel.Size = UDim2.new(1, -20, 0, 20)
    playLabel.Position = UDim2.new(0, 10, 0, 90)
    playLabel.BackgroundTransparency = 1
    playLabel.Text = "Click to play!"
    playLabel.TextColor3 = Color3.new(0.5, 1, 0.5)
    playLabel.TextScaled = true
    playLabel.Font = Enum.Font.SourceSansItalic
    playLabel.Parent = frame
    
    -- Add floating animation
    local floatTween = TweenService:Create(
        billboardGui,
        TweenInfo.new(3, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true),
        {StudsOffset = Vector3.new(0, 5, 0)}
    )
    floatTween:Play()
end

function MiniGameService:AddGlowEffect(part, color)
    local pointLight = Instance.new("PointLight")
    pointLight.Color = color
    pointLight.Brightness = 2
    pointLight.Range = 10
    pointLight.Parent = part
    
    -- Pulsing glow animation
    local glowTween = TweenService:Create(
        pointLight,
        TweenInfo.new(2, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true),
        {Brightness = 0.5}
    )
    glowTween:Play()
end

function MiniGameService:StartJumpTargetGame(player)
    local gameConfig = MINI_GAMES.jumpTarget
    
    -- Check cooldown
    if not self:CheckCooldown(player, "jumpTarget") then
        RemoteEvents.ShowMiniGameMessage:FireClient(player, "⏰ Please wait before playing again!", "warning")
        return
    end
    
    -- Create game session
    local gameId = self:GenerateGameId()
    local gameData = {
        id = gameId,
        type = "jumpTarget",
        player = player,
        startTime = tick(),
        duration = gameConfig.duration,
        score = 0,
        target = nil,
        isActive = true
    }
    
    activeMiniGames[gameId] = gameData
    
    -- Create floating target
    self:CreateJumpTarget(gameId, gameConfig)
    
    -- Start game countdown
    RemoteEvents.StartMiniGameCountdown:FireClient(player, {
        gameType = "jumpTarget",
        duration = gameConfig.duration,
        gameId = gameId
    })
    
    -- Update cooldown
    self:UpdateCooldown(player, "jumpTarget")
    
    -- Start game timer
    spawn(function()
        wait(gameConfig.duration)
        self:EndJumpTargetGame(gameId)
    end)
    
    print("🎯 " .. player.Name .. " started Jump Target mini-game")
end

function MiniGameService:CreateJumpTarget(gameId, gameConfig)
    local gameData = activeMiniGames[gameId]
    if not gameData then return end
    
    -- Create target
    local target = Instance.new("Part")
    target.Name = "JumpTarget_" .. gameId
    target.Size = Vector3.new(gameConfig.targetRadius * 2, 1, gameConfig.targetRadius * 2)
    target.Shape = Enum.PartType.Cylinder
    target.Position = gameConfig.position + Vector3.new(
        math.random(-8, 8), 
        gameConfig.targetHeight + math.random(-2, 4), 
        math.random(-8, 8)
    )
    target.Material = Enum.Material.Neon
    target.BrickColor = BrickColor.new("Really red")
    target.Anchored = true
    target.CanCollide = false
    target.Parent = Workspace
    
    gameData.target = target
    
    -- Add glowing effect
    local pointLight = Instance.new("PointLight")
    pointLight.Color = Color3.new(1, 0.2, 0.2)
    pointLight.Brightness = 3
    pointLight.Range = 15
    pointLight.Parent = target
    
    -- Add floating animation
    local floatTween = TweenService:Create(
        target,
        TweenInfo.new(2, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true),
        {Position = target.Position + Vector3.new(0, 2, 0)}
    )
    floatTween:Play()
    
    -- Add rotation animation
    local spinTween = TweenService:Create(
        target,
        TweenInfo.new(4, Enum.EasingStyle.Linear, Enum.EasingDirection.InOut, -1),
        {CFrame = target.CFrame * CFrame.Angles(0, math.pi * 2, 0)}
    )
    spinTween:Play()
    
    -- Touch detection
    local connection
    connection = target.Touched:Connect(function(hit)
        local character = hit.Parent
        local humanoid = character:FindFirstChildOfClass("Humanoid")
        local touchPlayer = Players:GetPlayerFromCharacter(character)
        
        if touchPlayer == gameData.player and humanoid then
            -- Player hit the target!
            self:OnTargetHit(gameId)
            connection:Disconnect()
        end
    end)
end

function MiniGameService:OnTargetHit(gameId)
    local gameData = activeMiniGames[gameId]
    if not gameData or not gameData.isActive then return end
    
    local gameConfig = MINI_GAMES[gameData.type]
    gameData.score = gameData.score + 1
    
    -- Show hit effect
    if gameData.target then
        self:CreateHitEffect(gameData.target.Position)
        gameData.target:Destroy()
    end
    
    -- Create new target if time remaining
    local timeRemaining = gameData.duration - (tick() - gameData.startTime)
    if timeRemaining > 1 then
        self:CreateJumpTarget(gameId, gameConfig)
        
        -- Show success message
        RemoteEvents.ShowMiniGameMessage:FireClient(gameData.player, "🎯 Target Hit! +" .. gameData.score, "success")
    end
end

function MiniGameService:EndJumpTargetGame(gameId)
    local gameData = activeMiniGames[gameId]
    if not gameData then return end
    
    gameData.isActive = false
    
    -- Clean up target
    if gameData.target then
        gameData.target:Destroy()
    end
    
    -- Calculate rewards
    local rewards = self:CalculateRewards(gameData)
    
    -- Give rewards
    self:GiveRewards(gameData.player, rewards)
    
    -- Show results
    RemoteEvents.ShowMiniGameResults:FireClient(gameData.player, {
        gameType = "jumpTarget",
        score = gameData.score,
        rewards = rewards,
        message = "🎯 Jump Target Complete!\nTargets Hit: " .. gameData.score
    })
    
    -- Update quest progress
    if QuestService then
        QuestService:UpdateQuestProgress(gameData.player, "minigame_played", 1, {gameType = "jumpTarget"})
        QuestService:UpdateQuestProgress(gameData.player, "targets_hit", gameData.score)
        
        -- Check for perfect target game achievement (5+ targets)
        if gameData.score >= 5 then
            QuestService:UpdateQuestProgress(gameData.player, "perfect_target_game", 1, {gameType = "jumpTarget", score = gameData.score})
        end
    end
    
    -- Clean up
    activeMiniGames[gameId] = nil
    
    print("🎯 " .. gameData.player.Name .. " finished Jump Target with score: " .. gameData.score)
end

function MiniGameService:StartCoinClickerGame(player)
    local gameConfig = MINI_GAMES.coinClicker
    
    -- Check cooldown
    if not self:CheckCooldown(player, "coinClicker") then
        RemoteEvents.ShowMiniGameMessage:FireClient(player, "⏰ Please wait before playing again!", "warning")
        return
    end
    
    -- Create game session
    local gameId = self:GenerateGameId()
    local gameData = {
        id = gameId,
        type = "coinClicker",
        player = player,
        startTime = tick(),
        duration = gameConfig.duration,
        score = 0,
        coinsClicked = 0,
        activeCoins = {},
        isActive = true
    }
    
    activeMiniGames[gameId] = gameData
    
    -- Start coin spawning
    self:StartCoinSpawning(gameId, gameConfig)
    
    -- Start game countdown
    RemoteEvents.StartMiniGameCountdown:FireClient(player, {
        gameType = "coinClicker",
        duration = gameConfig.duration,
        gameId = gameId
    })
    
    -- Update cooldown
    self:UpdateCooldown(player, "coinClicker")
    
    -- Start game timer
    spawn(function()
        wait(gameConfig.duration)
        self:EndCoinClickerGame(gameId)
    end)
    
    print("💰 " .. player.Name .. " started Coin Clicker mini-game")
end

function MiniGameService:StartCoinSpawning(gameId, gameConfig)
    local gameData = activeMiniGames[gameId]
    if not gameData then return end
    
    spawn(function()
        while gameData.isActive and #gameData.activeCoins < gameConfig.maxCoins do
            wait(1 / gameConfig.spawnRate) -- Spawn delay based on rate
            
            if gameData.isActive then
                self:SpawnClickableCoin(gameId, gameConfig)
            end
        end
    end)
end

function MiniGameService:SpawnClickableCoin(gameId, gameConfig)
    local gameData = activeMiniGames[gameId]
    if not gameData or not gameData.isActive then return end
    
    -- Create coin
    local coin = Instance.new("Part")
    coin.Name = "ClickableCoin_" .. gameId .. "_" .. #gameData.activeCoins
    coin.Size = Vector3.new(2, 2, 0.5)
    coin.Shape = Enum.PartType.Cylinder
    coin.Position = gameConfig.position + Vector3.new(
        math.random(-10, 10),
        math.random(3, 8),
        math.random(-10, 10)
    )
    coin.Material = Enum.Material.Neon
    coin.BrickColor = BrickColor.new("Bright yellow")
    coin.Anchored = true
    coin.CanCollide = false
    coin.Parent = Workspace
    
    -- Add click detector
    local clickDetector = Instance.new("ClickDetector")
    clickDetector.MaxActivationDistance = 20
    clickDetector.Parent = coin
    
    -- Add to active coins
    table.insert(gameData.activeCoins, coin)
    
    -- Add glowing effect
    local pointLight = Instance.new("PointLight")
    pointLight.Color = Color3.new(1, 1, 0.2)
    pointLight.Brightness = 2
    pointLight.Range = 8
    pointLight.Parent = coin
    
    -- Add floating and spinning animation
    local floatTween = TweenService:Create(
        coin,
        TweenInfo.new(3, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true),
        {Position = coin.Position + Vector3.new(0, 1.5, 0)}
    )
    floatTween:Play()
    
    local spinTween = TweenService:Create(
        coin,
        TweenInfo.new(2, Enum.EasingStyle.Linear, Enum.EasingDirection.InOut, -1),
        {CFrame = coin.CFrame * CFrame.Angles(0, 0, math.pi * 2)}
    )
    spinTween:Play()
    
    -- Click detection
    clickDetector.MouseClick:Connect(function(clickPlayer)
        if clickPlayer == gameData.player and gameData.isActive then
            self:OnCoinClicked(gameId, coin)
        end
    end)
    
    -- Auto-remove after 4 seconds if not clicked
    spawn(function()
        wait(4)
        if coin.Parent then
            self:RemoveCoinFromGame(gameId, coin)
        end
    end)
end

function MiniGameService:OnCoinClicked(gameId, coin)
    local gameData = activeMiniGames[gameId]
    if not gameData or not gameData.isActive then return end
    
    gameData.coinsClicked = gameData.coinsClicked + 1
    gameData.score = gameData.score + 10 -- 10 points per coin
    
    -- Show click effect
    self:CreateCoinClickEffect(coin.Position)
    
    -- Remove coin
    self:RemoveCoinFromGame(gameId, coin)
    
    -- Show score update
    RemoteEvents.ShowMiniGameMessage:FireClient(gameData.player, "💰 +10 points! Total: " .. gameData.score, "success")
end

function MiniGameService:RemoveCoinFromGame(gameId, coin)
    local gameData = activeMiniGames[gameId]
    if not gameData then return end
    
    -- Remove from active coins list
    for i, activeCoin in pairs(gameData.activeCoins) do
        if activeCoin == coin then
            table.remove(gameData.activeCoins, i)
            break
        end
    end
    
    -- Destroy coin
    coin:Destroy()
end

function MiniGameService:EndCoinClickerGame(gameId)
    local gameData = activeMiniGames[gameId]
    if not gameData then return end
    
    gameData.isActive = false
    
    -- Clean up remaining coins
    for _, coin in pairs(gameData.activeCoins) do
        if coin and coin.Parent then
            coin:Destroy()
        end
    end
    
    -- Calculate rewards
    local rewards = self:CalculateRewards(gameData)
    
    -- Give rewards
    self:GiveRewards(gameData.player, rewards)
    
    -- Show results
    RemoteEvents.ShowMiniGameResults:FireClient(gameData.player, {
        gameType = "coinClicker",
        score = gameData.score,
        coinsClicked = gameData.coinsClicked,
        rewards = rewards,
        message = "💰 Coin Clicker Complete!\nCoins Clicked: " .. gameData.coinsClicked .. "\nTotal Score: " .. gameData.score
    })
    
    -- Update quest progress
    if QuestService then
        QuestService:UpdateQuestProgress(gameData.player, "minigame_played", 1, {gameType = "coinClicker"})
        QuestService:UpdateQuestProgress(gameData.player, "coins_clicked", gameData.coinsClicked)
        
        -- Check for perfect clicker game achievement (20+ coins)
        if gameData.coinsClicked >= 20 then
            QuestService:UpdateQuestProgress(gameData.player, "perfect_clicker_game", 1, {gameType = "coinClicker", coinsClicked = gameData.coinsClicked})
        end
    end
    
    -- Clean up
    activeMiniGames[gameId] = nil
    
    print("💰 " .. gameData.player.Name .. " finished Coin Clicker with " .. gameData.coinsClicked .. " coins clicked")
end

function MiniGameService:CalculateRewards(gameData)
    local gameConfig = MINI_GAMES[gameData.type]
    local rewards = {coins = 0, xp = 0}
    
    if gameData.type == "jumpTarget" then
        -- Reward based on targets hit
        local multiplier = math.min(gameData.score / 3, 2) -- Up to 2x multiplier for hitting 3+ targets
        rewards.coins = math.floor(gameConfig.rewards.coins.min + (gameConfig.rewards.coins.max - gameConfig.rewards.coins.min) * multiplier)
        rewards.xp = math.floor(gameConfig.rewards.xp.min + (gameConfig.rewards.xp.max - gameConfig.rewards.xp.min) * multiplier)
    elseif gameData.type == "coinClicker" then
        -- Reward based on coins clicked
        local multiplier = math.min(gameData.coinsClicked / 15, 2) -- Up to 2x multiplier for clicking 15+ coins
        rewards.coins = math.floor(gameConfig.rewards.coins.min + (gameConfig.rewards.coins.max - gameConfig.rewards.coins.min) * multiplier)
        rewards.xp = math.floor(gameConfig.rewards.xp.min + (gameConfig.rewards.xp.max - gameConfig.rewards.xp.min) * multiplier)
    end
    
    return rewards
end

function MiniGameService:GiveRewards(player, rewards)
    if not PlayerService then return end
    
    local playerData = PlayerService:GetPlayerData(player)
    if not playerData then return end
    
    -- Give coins
    playerData.coins = playerData.coins + rewards.coins
    playerData.totalCoinsEarned = (playerData.totalCoinsEarned or 0) + rewards.coins
    
    -- Update player data
    PlayerService:UpdatePlayerData(player, playerData)
    
    -- Give XP (if LevelingService exists)
    if script.Parent:FindFirstChild("LevelingService") then
        local LevelingService = require(script.Parent.LevelingService)
        LevelingService:AddExperience(player, rewards.xp)
    end
end

function MiniGameService:CreateHitEffect(position)
    -- Create hit particle effect
    local effectPart = Instance.new("Part")
    effectPart.Size = Vector3.new(0.1, 0.1, 0.1)
    effectPart.Position = position
    effectPart.Anchored = true
    effectPart.CanCollide = false
    effectPart.Transparency = 1
    effectPart.Parent = Workspace
    
    local attachment = Instance.new("Attachment")
    attachment.Parent = effectPart
    
    -- Star burst effect
    local burst = Instance.new("ParticleEmitter")
    burst.Parent = attachment
    burst.Enabled = true
    burst.Lifetime = NumberRange.new(0.5, 1.2)
    burst.Rate = 500
    burst.SpreadAngle = Vector2.new(360, 360)
    burst.Speed = NumberRange.new(20, 40)
    burst.Color = ColorSequence.new{
        ColorSequenceKeypoint.new(0, Color3.new(1, 0.8, 0.2)),
        ColorSequenceKeypoint.new(0.5, Color3.new(1, 0.4, 0.2)),
        ColorSequenceKeypoint.new(1, Color3.new(1, 0.2, 0.2))
    }
    burst.Texture = "rbxasset://textures/particles/sparkles_main.dds"
    
    -- Clean up after 2 seconds
    game:GetService("Debris"):AddItem(effectPart, 2)
    
    -- Disable emitter after 0.1 seconds
    spawn(function()
        wait(0.1)
        burst.Enabled = false
    end)
end

function MiniGameService:CreateCoinClickEffect(position)
    -- Create coin collect effect
    local effectPart = Instance.new("Part")
    effectPart.Size = Vector3.new(0.1, 0.1, 0.1)
    effectPart.Position = position
    effectPart.Anchored = true
    effectPart.CanCollide = false
    effectPart.Transparency = 1
    effectPart.Parent = Workspace
    
    local attachment = Instance.new("Attachment")
    attachment.Parent = effectPart
    
    -- Sparkle effect
    local sparkles = Instance.new("ParticleEmitter")
    sparkles.Parent = attachment
    sparkles.Enabled = true
    sparkles.Lifetime = NumberRange.new(0.8, 1.5)
    sparkles.Rate = 300
    sparkles.SpreadAngle = Vector2.new(180, 180)
    sparkles.Speed = NumberRange.new(10, 25)
    sparkles.Color = ColorSequence.new{
        ColorSequenceKeypoint.new(0, Color3.new(1, 1, 0.2)),
        ColorSequenceKeypoint.new(0.5, Color3.new(1, 0.8, 0.2)),
        ColorSequenceKeypoint.new(1, Color3.new(0.8, 0.6, 0.2))
    }
    sparkles.Texture = "rbxasset://textures/particles/sparkles_main.dds"
    
    -- Clean up after 2 seconds
    game:GetService("Debris"):AddItem(effectPart, 2)
    
    -- Disable emitter after 0.2 seconds
    spawn(function()
        wait(0.2)
        sparkles.Enabled = false
    end)
end

function MiniGameService:CheckCooldown(player, gameType)
    local userId = tostring(player.UserId)
    if not gameCooldowns[userId] then
        gameCooldowns[userId] = {}
    end
    
    local lastPlayTime = gameCooldowns[userId][gameType]
    if not lastPlayTime then return true end
    
    local cooldownTime = MINI_GAMES[gameType].cooldown
    return (tick() - lastPlayTime) >= cooldownTime
end

function MiniGameService:UpdateCooldown(player, gameType)
    local userId = tostring(player.UserId)
    if not gameCooldowns[userId] then
        gameCooldowns[userId] = {}
    end
    
    gameCooldowns[userId][gameType] = tick()
end

function MiniGameService:GenerateGameId()
    return "minigame_" .. tostring(tick()) .. "_" .. tostring(math.random(1000, 9999))
end

function MiniGameService:SetupRemoteEvents()
    -- Handle mini-game requests
    RemoteEvents.PlayMiniGame.OnServerEvent:Connect(function(player, gameType)
        if gameType == "jumpTarget" then
            self:StartJumpTargetGame(player)
        elseif gameType == "coinClicker" then
            self:StartCoinClickerGame(player)
        end
    end)
end

-- Handle player leaving cleanup
Players.PlayerRemoving:Connect(function(player)
    local userId = tostring(player.UserId)
    
    -- Clean up any active games
    for gameId, gameData in pairs(activeMiniGames) do
        if gameData.player == player then
            if gameData.target then
                gameData.target:Destroy()
            end
            for _, coin in pairs(gameData.activeCoins or {}) do
                if coin and coin.Parent then
                    coin:Destroy()
                end
            end
            activeMiniGames[gameId] = nil
        end
    end
    
    -- Clean up cooldowns
    gameCooldowns[userId] = nil
end)

return MiniGameService
