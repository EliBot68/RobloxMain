-- PuzzleService.luau
-- Handles weekly puzzle piece collection system with hidden treasures around the hub

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local DataStoreService = game:GetService("DataStoreService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local SafeRequire = require(ReplicatedStorage.Shared.utils.SafeRequire)
local PlayerService = SafeRequire.require(script.Parent.core.PlayerService)
local RemoteEvents = require(ReplicatedStorage.Shared.modules.RemoteEvents)
local _GameConstants = require(ReplicatedStorage.Shared.constants.GameConstants)

-- Service references (set via setters)
local QuestService = nil

local PuzzleService = {}

-- DataStore for puzzle progress
local puzzleProgressStore = DataStoreService:GetDataStore("WeeklyPuzzleProgress")

-- Weekly reset configuration
local WEEK_DURATION = 604800 -- 7 days in seconds
local PUZZLE_PIECES_COUNT = 5

-- Puzzle piece definitions with locations and colors
local PUZZLE_PIECE_LOCATIONS = {
    {
        id = "red_piece",
        name = "🔴 Crimson Fragment",
        color = Color3.new(1, 0.2, 0.2),
        position = Vector3.new(25, 3, 15), -- Near fountain area
        hint = "Where the water flows eternally..."
    },
    {
        id = "green_piece", 
        name = "🟢 Emerald Shard",
        color = Color3.new(0.2, 1, 0.2),
        position = Vector3.new(-30, 5, -20), -- Near shop area
        hint = "Among the treasures for sale..."
    },
    {
        id = "blue_piece",
        name = "🔵 Sapphire Crystal",
        color = Color3.new(0.2, 0.2, 1),
        position = Vector3.new(45, 8, -5), -- Near quest board
        hint = "Where daily challenges await..."
    },
    {
        id = "yellow_piece",
        name = "🟡 Golden Gem",
        color = Color3.new(1, 1, 0.2),
        position = Vector3.new(-15, 12, 30), -- Hidden elevated spot
        hint = "High above where few dare to climb..."
    },
    {
        id = "purple_piece",
        name = "🟣 Amethyst Core",
        color = Color3.new(0.8, 0.2, 1),
        position = Vector3.new(0, 6, -40), -- Behind spawn area
        hint = "Where journeys begin, but few look back..."
    }
}

-- Reward pools for completing puzzles
local PUZZLE_REWARDS = {
    trails = {
        {
            id = "stellar_trail",
            name = "⭐ Stellar Trail",
            rarity = "Epic",
            effect = "cosmic_sparkles"
        },
        {
            id = "rainbow_spiral",
            name = "🌈 Rainbow Spiral",
            rarity = "Legendary", 
            effect = "rainbow_helix"
        },
        {
            id = "lightning_bolt",
            name = "⚡ Lightning Bolt",
            rarity = "Epic",
            effect = "electric_trail"
        },
        {
            id = "frost_wake",
            name = "❄️ Frost Wake",
            rarity = "Epic",
            effect = "ice_crystals"
        }
    },
    skins = {
        {
            id = "puzzle_master_skin",
            name = "🧩 Puzzle Master",
            rarity = "Legendary",
            colors = {
                Color3.new(1, 0.8, 0.2),
                Color3.new(0.8, 0.2, 1),
                Color3.new(0.2, 1, 0.8)
            }
        },
        {
            id = "treasure_hunter_skin",
            name = "💎 Treasure Hunter",
            rarity = "Epic",
            colors = {
                Color3.new(0.9, 0.7, 0.3),
                Color3.new(0.7, 0.5, 0.2)
            }
        }
    }
}

-- Player progress tracking
local playerPuzzleProgress = {}
local activePuzzlePieces = {}
local currentWeekId = 0

function PuzzleService:GetCurrentWeekId()
    -- Calculate week ID based on Unix timestamp
    return math.floor(os.time() / WEEK_DURATION)
end

function PuzzleService:GetSecondsUntilWeekReset()
    local currentTime = os.time()
    local currentWeek = math.floor(currentTime / WEEK_DURATION)
    local nextWeekStart = (currentWeek + 1) * WEEK_DURATION
    return nextWeekStart - currentTime
end

function PuzzleService:LoadPlayerProgress(player)
    local userId = tostring(player.UserId)
    local weekId = self:GetCurrentWeekId()
    
    -- Try to load from DataStore
    local success, data = pcall(function()
        return puzzleProgressStore:GetAsync(userId) or {}
    end)
    
    if not success then
        warn("Failed to load puzzle data for " .. player.Name)
        data = {}
    end
    
    -- Check if we need to reset for new week
    if not data.weekId or data.weekId < weekId then
        print("🧩 Resetting puzzle progress for " .. player.Name .. " (new week: " .. weekId .. ")")
        data = {
            weekId = weekId,
            collectedPieces = {},
            completedWeeks = data.completedWeeks or {},
            totalPuzzlesCompleted = data.totalPuzzlesCompleted or 0
        }
        
        -- Save immediately
        self:SavePlayerProgress(player, data)
    end
    
    playerPuzzleProgress[userId] = data
    
    print("🧩 Loaded puzzle progress for " .. player.Name .. ": " .. #data.collectedPieces .. "/" .. PUZZLE_PIECES_COUNT .. " pieces")
    return data
end

function PuzzleService:SavePlayerProgress(player, data)
    local userId = tostring(player.UserId)
    
    local success = pcall(function()
        puzzleProgressStore:SetAsync(userId, data)
    end)
    
    if not success then
        warn("Failed to save puzzle data for " .. player.Name)
    end
    
    -- Update in-memory data
    playerPuzzleProgress[userId] = data
end

function PuzzleService:CreatePuzzlePiece(pieceData)
    -- Create the puzzle piece part
    local piece = Instance.new("Part")
    piece.Name = "PuzzlePiece_" .. pieceData.id
    piece.Size = Vector3.new(2, 2, 0.5)
    piece.Material = Enum.Material.Neon
    piece.BrickColor = BrickColor.new("Bright blue")
    piece.Color = pieceData.color
    piece.Anchored = true
    piece.CanCollide = false
    piece.Position = pieceData.position
    piece.Shape = Enum.PartType.Ball
    
    -- Add glow effect
    local pointLight = Instance.new("PointLight")
    pointLight.Color = pieceData.color
    pointLight.Brightness = 2
    pointLight.Range = 10
    pointLight.Parent = piece
    
    -- Create floating animation
    local floatTween = TweenService:Create(
        piece,
        TweenInfo.new(3, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true),
        {Position = pieceData.position + Vector3.new(0, 2, 0)}
    )
    floatTween:Play()
    
    -- Create spinning animation
    local spinConnection
    spinConnection = RunService.Heartbeat:Connect(function()
        if piece and piece.Parent then
            piece.Rotation = piece.Rotation + Vector3.new(0, 2, 1)
        else
            spinConnection:Disconnect()
        end
    end)
    
    -- Add particle effects
    local attachment = Instance.new("Attachment")
    attachment.Parent = piece
    
    local particles = Instance.new("ParticleEmitter")
    particles.Texture = "rbxasset://textures/particles/sparkles_main.dds"
    particles.Lifetime = NumberRange.new(1, 2)
    particles.Rate = 20
    particles.SpreadAngle = Vector2.new(45, 45)
    particles.Speed = NumberRange.new(2, 5)
    particles.Color = ColorSequence.new(pieceData.color)
    particles.Size = NumberSequence.new{
        NumberSequenceKeypoint.new(0, 0.2),
        NumberSequenceKeypoint.new(0.5, 0.5),
        NumberSequenceKeypoint.new(1, 0)
    }
    particles.Parent = attachment
    
    -- Add click detector
    local clickDetector = Instance.new("ClickDetector")
    clickDetector.MaxActivationDistance = 15
    clickDetector.Parent = piece
    
    -- Handle collection
    clickDetector.MouseClick:Connect(function(player)
        self:CollectPuzzlePiece(player, pieceData.id)
    end)
    
    -- Add billboard GUI with hint
    local billboardGui = Instance.new("BillboardGui")
    billboardGui.Size = UDim2.new(0, 200, 0, 60)
    billboardGui.StudsOffset = Vector3.new(0, 3, 0)
    billboardGui.Parent = piece
    
    local nameLabel = Instance.new("TextLabel")
    nameLabel.Size = UDim2.new(1, 0, 0.6, 0)
    nameLabel.BackgroundTransparency = 1
    nameLabel.Text = pieceData.name
    nameLabel.TextColor3 = Color3.new(1, 1, 1)
    nameLabel.TextScaled = true
    nameLabel.Font = Enum.Font.SourceSansBold
    nameLabel.TextStrokeTransparency = 0
    nameLabel.TextStrokeColor3 = Color3.new(0, 0, 0)
    nameLabel.Parent = billboardGui
    
    local hintLabel = Instance.new("TextLabel")
    hintLabel.Size = UDim2.new(1, 0, 0.4, 0)
    hintLabel.Position = UDim2.new(0, 0, 0.6, 0)
    hintLabel.BackgroundTransparency = 1
    hintLabel.Text = "Click to collect!"
    hintLabel.TextColor3 = Color3.new(0.8, 0.8, 1)
    hintLabel.TextScaled = true
    hintLabel.Font = Enum.Font.SourceSans
    hintLabel.TextStrokeTransparency = 0
    hintLabel.TextStrokeColor3 = Color3.new(0, 0, 0)
    hintLabel.Parent = billboardGui
    
    -- Parent to workspace
    piece.Parent = Workspace
    
    return piece
end

function PuzzleService:SpawnAllPuzzlePieces()
    print("🧩 Spawning puzzle pieces for week " .. self:GetCurrentWeekId())
    
    -- Clear existing pieces
    for _, piece in pairs(activePuzzlePieces) do
        if piece and piece.Parent then
            piece:Destroy()
        end
    end
    activePuzzlePieces = {}
    
    -- Spawn new pieces
    for _, pieceData in ipairs(PUZZLE_PIECE_LOCATIONS) do
        local piece = self:CreatePuzzlePiece(pieceData)
        activePuzzlePieces[pieceData.id] = piece
    end
    
    print("✅ Spawned " .. #PUZZLE_PIECE_LOCATIONS .. " puzzle pieces")
end

function PuzzleService:CollectPuzzlePiece(player, pieceId)
    local userId = tostring(player.UserId)
    local progress = playerPuzzleProgress[userId]
    
    if not progress then
        progress = self:LoadPlayerProgress(player)
    end
    
    -- Check if already collected
    for _, collectedId in ipairs(progress.collectedPieces) do
        if collectedId == pieceId then
            RemoteEvents.ShowPuzzleMessage:FireClient(player, {
                message = "🧩 You already have this piece!",
                type = "warning"
            })
            return
        end
    end
    
    -- Add to collection
    table.insert(progress.collectedPieces, pieceId)
    
    -- Find piece data for feedback
    local pieceData = nil
    for _, data in ipairs(PUZZLE_PIECE_LOCATIONS) do
        if data.id == pieceId then
            pieceData = data
            break
        end
    end
    
    -- Remove the physical piece for this player
    if activePuzzlePieces[pieceId] then
        local piece = activePuzzlePieces[pieceId]
        
        -- Play collection effect
        self:PlayCollectionEffect(piece, player, pieceData)
        
        -- Hide piece for this player only (in a real implementation, you'd use FilteringEnabled properly)
        spawn(function()
            wait(2) -- Wait for effect to play
            -- For now, we'll make it transparent for the collector
            RemoteEvents.HidePuzzlePiece:FireClient(player, pieceId)
        end)
    end
    
    -- Save progress
    self:SavePlayerProgress(player, progress)
    
    -- Notify client
    RemoteEvents.PuzzlePieceCollected:FireClient(player, {
        pieceId = pieceId,
        pieceName = pieceData and pieceData.name or "Unknown Piece",
        totalCollected = #progress.collectedPieces,
        totalRequired = PUZZLE_PIECES_COUNT
    })
    
    print("🧩 " .. player.Name .. " collected " .. pieceId .. " (" .. #progress.collectedPieces .. "/" .. PUZZLE_PIECES_COUNT .. ")")
    
    -- Update quest progress
    if QuestService then
        QuestService:UpdateQuestProgress(player, "puzzle_piece_collected", 1)
    end
    
    -- Check if puzzle is complete
    if #progress.collectedPieces >= PUZZLE_PIECES_COUNT then
        self:CompletePuzzle(player)
    end
end

function PuzzleService:PlayCollectionEffect(piece, player, pieceData)
    if not piece or not piece.Parent then return end
    
    -- Create burst particle effect
    local attachment = piece:FindFirstChild("Attachment")
    if attachment then
        local burstParticles = Instance.new("ParticleEmitter")
        burstParticles.Texture = "rbxasset://textures/particles/sparkles_main.dds"
        burstParticles.Lifetime = NumberRange.new(0.5, 1.5)
        burstParticles.Rate = 200
        burstParticles.SpreadAngle = Vector2.new(360, 360)
        burstParticles.Speed = NumberRange.new(8, 15)
        burstParticles.Color = ColorSequence.new(pieceData and pieceData.color or Color3.new(1, 1, 1))
        burstParticles.Size = NumberSequence.new{
            NumberSequenceKeypoint.new(0, 0.5),
            NumberSequenceKeypoint.new(0.5, 1),
            NumberSequenceKeypoint.new(1, 0)
        }
        burstParticles.Parent = attachment
        
        -- Emit burst
        burstParticles:Emit(50)
        
        -- Clean up
        spawn(function()
            wait(2)
            burstParticles:Destroy()
        end)
    end
    
    -- Scale down animation
    local scaleTween = TweenService:Create(
        piece,
        TweenInfo.new(1.5, Enum.EasingStyle.Back, Enum.EasingDirection.In),
        {Size = Vector3.new(0, 0, 0)}
    )
    scaleTween:Play()
    
    -- Play collection sound for player
    RemoteEvents.PlayPuzzleSound:FireClient(player, "collect")
end

function PuzzleService:CompletePuzzle(player)
    local userId = tostring(player.UserId)
    local progress = playerPuzzleProgress[userId]
    
    if not progress then return end
    
    -- Mark puzzle as completed
    local weekId = self:GetCurrentWeekId()
    table.insert(progress.completedWeeks, weekId)
    progress.totalPuzzlesCompleted = progress.totalPuzzlesCompleted + 1
    
    -- Select random reward
    local rewardType = math.random() < 0.6 and "trails" or "skins" -- 60% chance for trail
    local rewardPool = PUZZLE_REWARDS[rewardType]
    local selectedReward = rewardPool[math.random(1, #rewardPool)]
    
    -- Give reward to player
    local playerData = PlayerService:GetPlayerData(player)
    if playerData then
        if rewardType == "trails" then
            if not playerData.unlockedTrails then
                playerData.unlockedTrails = {}
            end
            playerData.unlockedTrails[selectedReward.id] = {
                name = selectedReward.name,
                rarity = selectedReward.rarity,
                effect = selectedReward.effect,
                unlockedDate = os.time(),
                source = "weekly_puzzle"
            }
        elseif rewardType == "skins" then
            if not playerData.unlockedSkins then
                playerData.unlockedSkins = {}
            end
            playerData.unlockedSkins[selectedReward.id] = {
                name = selectedReward.name,
                rarity = selectedReward.rarity,
                colors = selectedReward.colors,
                unlockedDate = os.time(),
                source = "weekly_puzzle"
            }
        end
        
        -- Bonus coins for completion
        playerData.coins = playerData.coins + 1000
        playerData.totalCoinsEarned = (playerData.totalCoinsEarned or 0) + 1000
        
        PlayerService:UpdatePlayerData(player, playerData)
    end
    
    -- Save progress
    self:SavePlayerProgress(player, progress)
    
    -- Notify client with celebration
    RemoteEvents.PuzzleCompleted:FireClient(player, {
        reward = selectedReward,
        rewardType = rewardType,
        weekId = weekId,
        totalCompleted = progress.totalPuzzlesCompleted,
        bonusCoins = 1000
    })
    
    -- Play completion sound for all players
    for _, otherPlayer in pairs(Players:GetPlayers()) do
        RemoteEvents.PlayPuzzleSound:FireClient(otherPlayer, "complete")
    end
    
    print("🎉 " .. player.Name .. " completed the weekly puzzle! Reward: " .. selectedReward.name)
    
    -- Update quest progress
    if QuestService then
        QuestService:UpdateQuestProgress(player, "puzzle_completed", 1, {completed = true})
    end
    
    -- Log analytics
    if PlayerService.AnalyticsService then
        PlayerService.AnalyticsService:LogEvent(player, "puzzle_completed", {
            weekId = weekId,
            rewardType = rewardType,
            rewardId = selectedReward.id,
            totalPuzzlesCompleted = progress.totalPuzzlesCompleted
        })
    end
end

function PuzzleService:GetPlayerProgress(player)
    local userId = tostring(player.UserId)
    return playerPuzzleProgress[userId] or self:LoadPlayerProgress(player)
end

function PuzzleService:GetPuzzleHints(player)
    local progress = self:GetPlayerProgress(player)
    local hints = {}
    
    for _, pieceData in ipairs(PUZZLE_PIECE_LOCATIONS) do
        local isCollected = false
        for _, collectedId in ipairs(progress.collectedPieces) do
            if collectedId == pieceData.id then
                isCollected = true
                break
            end
        end
        
        table.insert(hints, {
            id = pieceData.id,
            name = pieceData.name,
            hint = pieceData.hint,
            collected = isCollected,
            color = pieceData.color
        })
    end
    
    return hints
end

function PuzzleService:ScheduleWeeklyReset()
    local secondsUntilReset = self:GetSecondsUntilWeekReset()
    local days = math.floor(secondsUntilReset / 86400)
    local hours = math.floor((secondsUntilReset % 86400) / 3600)
    
    print("⏰ Next weekly puzzle reset in " .. days .. " days and " .. hours .. " hours")
    
    -- Schedule the reset
    spawn(function()
        wait(secondsUntilReset)
        self:PerformWeeklyReset()
        
        -- Event-driven recurring reset system
        local weeklyResetEvent = Instance.new("BindableEvent")
        
        local function scheduleWeeklyReset()
            wait(WEEK_DURATION)
            weeklyResetEvent:Fire()
        end
        
        weeklyResetEvent.Event:Connect(function()
            self:PerformWeeklyReset()
            spawn(scheduleWeeklyReset)
        end)
        
        -- Start the weekly reset cycle
        spawn(scheduleWeeklyReset)
    end)
end

function PuzzleService:PerformWeeklyReset()
    print("🔄 Performing weekly puzzle reset...")
    
    currentWeekId = self:GetCurrentWeekId()
    
    -- Reset all player progress for new week
    for userId, progress in pairs(playerPuzzleProgress) do
        progress.weekId = currentWeekId
        progress.collectedPieces = {}
        
        -- Save to DataStore
        local player = Players:GetPlayerByUserId(tonumber(userId))
        if player then
            self:SavePlayerProgress(player, progress)
            
            -- Notify client
            RemoteEvents.PuzzleWeekReset:FireClient(player, {
                weekId = currentWeekId,
                message = "🧩 New puzzle pieces have appeared around the hub!"
            })
        end
    end
    
    -- Respawn puzzle pieces
    self:SpawnAllPuzzlePieces()
    
    print("✅ Weekly puzzle reset completed for week " .. currentWeekId)
end

function PuzzleService:Initialize()
    print("🧩 PuzzleService initializing...")
    
    -- Wait for workspace to load
    wait(2)
    
    -- Set current week
    currentWeekId = self:GetCurrentWeekId()
    
    -- Spawn puzzle pieces
    self:SpawnAllPuzzlePieces()
    
    -- Schedule weekly resets
    self:ScheduleWeeklyReset()
    
    print("✅ PuzzleService initialized successfully!")
    print("🧩 Current week: " .. currentWeekId)
    print("🧩 " .. PUZZLE_PIECES_COUNT .. " puzzle pieces hidden around the hub")
end

-- Remote event handlers
RemoteEvents.GetPuzzleProgress = RemoteEvents:GetRemoteEvent("GetPuzzleProgress")
RemoteEvents.GetPuzzleHints = RemoteEvents:GetRemoteEvent("GetPuzzleHints")
RemoteEvents.PuzzlePieceCollected = RemoteEvents:GetRemoteEvent("PuzzlePieceCollected")
RemoteEvents.PuzzleCompleted = RemoteEvents:GetRemoteEvent("PuzzleCompleted")
RemoteEvents.PuzzleWeekReset = RemoteEvents:GetRemoteEvent("PuzzleWeekReset")
RemoteEvents.ShowPuzzleMessage = RemoteEvents:GetRemoteEvent("ShowPuzzleMessage")
RemoteEvents.PlayPuzzleSound = RemoteEvents:GetRemoteEvent("PlayPuzzleSound")
RemoteEvents.HidePuzzlePiece = RemoteEvents:GetRemoteEvent("HidePuzzlePiece")

RemoteEvents.GetPuzzleProgress.OnServerEvent:Connect(function(player)
    local progress = PuzzleService:GetPlayerProgress(player)
    RemoteEvents.GetPuzzleProgress:FireClient(player, progress)
end)

RemoteEvents.GetPuzzleHints.OnServerEvent:Connect(function(player)
    local hints = PuzzleService:GetPuzzleHints(player)
    RemoteEvents.GetPuzzleHints:FireClient(player, hints)
end)

-- Handle player joining
local function onPlayerAdded(player)
    spawn(function()
        wait(3) -- Wait for player to fully load
        PuzzleService:LoadPlayerProgress(player)
    end)
end

Players.PlayerAdded:Connect(onPlayerAdded)

-- Auto-initialize
PuzzleService:Initialize()

-- Service setters for integration
function PuzzleService:SetPlayerService(playerService)
    PlayerService = playerService
end

function PuzzleService:SetQuestService(questService)
    QuestService = questService
end

return PuzzleService
