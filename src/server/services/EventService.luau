-- EventService.luau
-- Handles special event runs with themed tracks, unique barriers, and temporary rewards

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local SoundService = game:GetService("SoundService")

local GameConstants = require(ReplicatedStorage.Shared.constants.GameConstants)
local RemoteEvents = require(ReplicatedStorage.Shared.modules.RemoteEvents)

-- Forward declare services to avoid circular dependencies
local PlayerService = nil
local GameService = nil
local AnalyticsService = nil
local QuestService = nil

local EventService = {}

-- Event configurations
local EVENT_THEMES = {
    {
        id = "rainbow_rush",
        name = "🌈 Rainbow Rush",
        description = "All colors cycle rapidly with rainbow effects!",
        duration = 3600, -- 1 hour
        barrierEffect = "rainbow_cycle",
        trackColors = {"rainbow"},
        music = "rbxasset://sounds/electronicpingshort.wav", -- Placeholder
        rewards = {
            xpMultiplier = 1.5,
            coinMultiplier = 1.3,
            temporarySkin = "Rainbow Runner",
            temporaryTrail = "Rainbow Burst"
        }
    },
    {
        id = "neon_nights",
        name = "🌃 Neon Nights",
        description = "Glowing neon barriers in a dark cyber world!",
        duration = 3600,
        barrierEffect = "neon_glow",
        trackColors = {"neon_blue", "neon_pink", "neon_green"},
        music = "rbxasset://sounds/bell.wav", -- Placeholder
        rewards = {
            xpMultiplier = 1.4,
            coinMultiplier = 1.2,
            temporarySkin = "Cyber Runner",
            temporaryTrail = "Neon Stream"
        }
    },
    {
        id = "fire_festival",
        name = "🔥 Fire Festival",
        description = "Hot barriers with flame effects and fire trails!",
        duration = 3600,
        barrierEffect = "fire_particles",
        trackColors = {"fire_red", "fire_orange", "fire_yellow"},
        music = "rbxasset://sounds/electronicpingshort.wav", -- Placeholder
        rewards = {
            xpMultiplier = 1.6,
            coinMultiplier = 1.4,
            temporarySkin = "Fire Dancer",
            temporaryTrail = "Flame Trail"
        }
    },
    {
        id = "ice_crystal",
        name = "❄️ Ice Crystal",
        description = "Crystalline barriers with frosty particle effects!",
        duration = 3600,
        barrierEffect = "ice_crystals",
        trackColors = {"ice_blue", "ice_white", "ice_cyan"},
        music = "rbxasset://sounds/bell.wav", -- Placeholder
        rewards = {
            xpMultiplier = 1.3,
            coinMultiplier = 1.5,
            temporarySkin = "Ice Walker",
            temporaryTrail = "Frost Trail"
        }
    }
}

-- Current active event
local currentEvent = nil
local eventStartTime = 0
local eventPlayers = {} -- Players currently in event runs

function EventService:Init()
    self:SetupEventPortal()
    self:StartRandomEvent()
    print("✅ EventService initialized")
end

function EventService:SetupEventPortal()
    local marketPlaza = Workspace:FindFirstChild("MarketPlaza")
    if not marketPlaza then
        warn("MarketPlaza not found!")
        return
    end
    
    -- Create event portal next to game archway
    local eventPortal = Instance.new("Part")
    eventPortal.Name = "EventPortal"
    eventPortal.Size = Vector3.new(12, 16, 3)
    eventPortal.Position = Vector3.new(-30, 8, -20) -- Position next to main archway
    eventPortal.Material = Enum.Material.ForceField
    eventPortal.BrickColor = BrickColor.new("Electric blue")
    eventPortal.CanCollide = false
    eventPortal.Anchored = true
    eventPortal.Shape = Enum.PartType.Block
    eventPortal.Parent = marketPlaza
    
    -- Add archway shape
    local mesh = Instance.new("SpecialMesh")
    mesh.MeshType = Enum.MeshType.FileMesh
    mesh.MeshId = "rbxasset://fonts/torso.mesh" -- Simple arch shape
    mesh.Scale = Vector3.new(2, 2, 0.5)
    mesh.Parent = eventPortal
    
    -- Add portal effects
    local attachment = Instance.new("Attachment")
    attachment.Parent = eventPortal
    
    -- Swirling portal particles
    local portalEffect = Instance.new("ParticleEmitter")
    portalEffect.Parent = attachment
    portalEffect.Enabled = true
    portalEffect.Lifetime = NumberRange.new(1, 2)
    portalEffect.Rate = 50
    portalEffect.SpreadAngle = Vector2.new(360, 360)
    portalEffect.Speed = NumberRange.new(10, 20)
    portalEffect.Color = ColorSequence.new{
        ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 0, 255)),
        ColorSequenceKeypoint.new(0.5, Color3.fromRGB(0, 255, 255)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 255, 0))
    }
    portalEffect.Transparency = NumberSequence.new{
        NumberSequenceKeypoint.new(0, 0.8),
        NumberSequenceKeypoint.new(0.5, 0.2),
        NumberSequenceKeypoint.new(1, 1)
    }
    
    -- Add event title
    local billboardGui = Instance.new("BillboardGui")
    billboardGui.Size = UDim2.new(0, 400, 0, 120)
    billboardGui.StudsOffset = Vector3.new(0, 3, 0)
    billboardGui.Parent = eventPortal
    
    local titleLabel = Instance.new("TextLabel")
    titleLabel.Size = UDim2.new(1, 0, 0.6, 0)
    titleLabel.BackgroundTransparency = 1
    titleLabel.Text = "🎪 EVENT RUN"
    titleLabel.TextColor3 = Color3.fromRGB(255, 100, 255)
    titleLabel.TextScaled = true
    titleLabel.Font = Enum.Font.GothamBold
    titleLabel.TextStrokeTransparency = 0
    titleLabel.TextStrokeColor3 = Color3.new(0, 0, 0)
    titleLabel.Parent = billboardGui
    
    local subtitleLabel = Instance.new("TextLabel")
    subtitleLabel.Size = UDim2.new(1, 0, 0.4, 0)
    subtitleLabel.Position = UDim2.new(0, 0, 0.6, 0)
    subtitleLabel.BackgroundTransparency = 1
    subtitleLabel.Text = "Special themed track!"
    subtitleLabel.TextColor3 = Color3.fromRGB(200, 200, 255)
    subtitleLabel.TextScaled = true
    subtitleLabel.Font = Enum.Font.Gotham
    subtitleLabel.TextStrokeTransparency = 0
    subtitleLabel.TextStrokeColor3 = Color3.new(0, 0, 0)
    subtitleLabel.Parent = billboardGui
    
    -- Add click detector for portal
    local clickDetector = Instance.new("ClickDetector")
    clickDetector.MaxActivationDistance = 20
    clickDetector.Parent = eventPortal
    
    clickDetector.MouseClick:Connect(function(player)
        self:StartEventRun(player)
    end)
    
    -- Add collision detection for walking through
    local function onTouched(hit)
        local humanoid = hit.Parent:FindFirstChild("Humanoid")
        if humanoid then
            local player = Players:GetPlayerFromCharacter(hit.Parent)
            if player then
                self:StartEventRun(player)
            end
        end
    end
    
    eventPortal.Touched:Connect(onTouched)
    
    -- Floating animation
    local floatTween = TweenService:Create(
        eventPortal,
        TweenInfo.new(4, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true),
        {Position = eventPortal.Position + Vector3.new(0, 2, 0)}
    )
    floatTween:Play()
    
    -- Color shifting animation
    local colorTween = TweenService:Create(
        eventPortal,
        TweenInfo.new(2, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true),
        {Color = Color3.fromRGB(255, 100, 100)}
    )
    colorTween:Play()
    
    print("🎪 Event portal created")
end

function EventService:StartRandomEvent()
    -- Select a random event theme
    local randomIndex = math.random(1, #EVENT_THEMES)
    currentEvent = EVENT_THEMES[randomIndex]
    eventStartTime = tick()
    
    -- Update portal display with current event
    local marketPlaza = Workspace:FindFirstChild("MarketPlaza")
    if marketPlaza then
        local eventPortal = marketPlaza:FindFirstChild("EventPortal")
        if eventPortal then
            local billboardGui = eventPortal:FindFirstChild("BillboardGui")
            if billboardGui then
                local subtitleLabel = billboardGui:FindFirstChild("TextLabel")
                if subtitleLabel and subtitleLabel.Parent == billboardGui then
                    -- Find the second TextLabel (subtitle)
                    for _, child in pairs(billboardGui:GetChildren()) do
                        if child:IsA("TextLabel") and child ~= billboardGui:GetChildren()[1] then
                            child.Text = currentEvent.name
                            break
                        end
                    end
                end
            end
        end
    end
    
    print("🎪 Started event: " .. currentEvent.name)
    
    -- Schedule next event
    spawn(function()
        wait(currentEvent.duration)
        self:StartRandomEvent()
    end)
end

function EventService:StartEventRun(player)
    if not currentEvent then
        self:StartRandomEvent()
    end
    
    -- Check if player is already in a game
    if GameService and GameService:IsPlayerInGame(player) then
        RemoteEvents.ShowNotification:FireClient(player, "⚠️ Finish your current game first!")
        return
    end
    
    -- Apply temporary event cosmetics
    self:ApplyEventCosmetics(player)
    
    -- Start special event game
    local eventStartPos = Vector3.new(0, 6, -200) -- Special event track position
    
    -- Teleport player to event track
    local character = player.Character
    if character and character:FindFirstChild("HumanoidRootPart") then
        character.HumanoidRootPart.CFrame = CFrame.new(eventStartPos)
    end
    
    -- Start event game with special parameters
    if GameService then
        eventPlayers[player.UserId] = {
            eventId = currentEvent.id,
            startTime = tick(),
            bonusActive = true
        }
        
        -- Start game with event modifications
        GameService:StartGame(player, "event")
        
        -- Apply event effects
        RemoteEvents.ApplyEventEffects:FireClient(player, currentEvent)
        
        -- Play event music
        RemoteEvents.PlayEventMusic:FireClient(player, currentEvent.music)
        
        -- Show event notification
        RemoteEvents.ShowNotification:FireClient(player, "🎪 " .. currentEvent.name .. " activated!")
    end
    
    -- Analytics
    if AnalyticsService then
        AnalyticsService:LogEvent(player, AnalyticsService.EventTypes.EVENT_RUN_START, {
            eventId = currentEvent.id,
            eventName = currentEvent.name
        })
    end
    
    print("🎪 " .. player.Name .. " started event run: " .. currentEvent.name)
end

function EventService:ApplyEventCosmetics(player)
    if not currentEvent or not currentEvent.rewards then return end
    
    local character = player.Character
    if not character then return end
    
    -- Apply temporary skin effect
    if currentEvent.rewards.temporarySkin then
        RemoteEvents.ApplyTemporarySkin:FireClient(player, currentEvent.rewards.temporarySkin, 300) -- 5 minutes
    end
    
    -- Apply temporary trail effect
    if currentEvent.rewards.temporaryTrail then
        RemoteEvents.ApplyTemporaryTrail:FireClient(player, currentEvent.rewards.temporaryTrail, 300) -- 5 minutes
    end
end

function EventService:GetEventMultipliers(player)
    local playerEventData = eventPlayers[player.UserId]
    if not playerEventData or not currentEvent then
        return {xp = 1, coins = 1}
    end
    
    return {
        xp = currentEvent.rewards.xpMultiplier or 1,
        coins = currentEvent.rewards.coinMultiplier or 1
    }
end

function EventService:EndEventRun(player, score, barriers)
    local playerEventData = eventPlayers[player.UserId]
    if not playerEventData or not currentEvent then return end
    
    -- Calculate bonus rewards
    local multipliers = self:GetEventMultipliers(player)
    local bonusXp = math.floor(score * 2 * (multipliers.xp - 1)) -- Bonus XP
    local bonusCoins = math.floor(barriers * 10 * (multipliers.coins - 1)) -- Bonus coins
    
    -- Apply bonus rewards
    if PlayerService then
        local playerData = PlayerService:GetPlayerData(player)
        if playerData then
            playerData.coins = playerData.coins + bonusCoins
            playerData.totalCoinsEarned = (playerData.totalCoinsEarned or 0) + bonusCoins
            PlayerService:UpdatePlayerData(player, playerData)
        end
    end
    
    -- Show event completion notification
    RemoteEvents.ShowEventCompletion:FireClient(player, {
        eventName = currentEvent.name,
        bonusXp = bonusXp,
        bonusCoins = bonusCoins,
        totalScore = score,
        totalBarriers = barriers
    })
    
    -- Analytics
    if AnalyticsService then
        AnalyticsService:LogEvent(player, AnalyticsService.EventTypes.EVENT_RUN_END, {
            eventId = currentEvent.id,
            eventName = currentEvent.name,
            score = score,
            barriers = barriers,
            bonusXp = bonusXp,
            bonusCoins = bonusCoins,
            duration = tick() - playerEventData.startTime
        })
    end
    
    -- Update quest progress
    if QuestService then
        QuestService:UpdateQuestProgress(player, "event_runs_completed", 1)
        if score >= 20 then
            QuestService:UpdateQuestProgress(player, "event_high_score", score)
        end
    end
    
    -- Clean up
    eventPlayers[player.UserId] = nil
    
    print("🎪 " .. player.Name .. " completed event run with bonus: +" .. bonusCoins .. " coins, +" .. bonusXp .. " XP")
end

function EventService:GetCurrentEvent()
    return currentEvent
end

function EventService:IsPlayerInEvent(player)
    return eventPlayers[player.UserId] ~= nil
end

function EventService:GetEventBarrierColors()
    if not currentEvent then return GameConstants.COLOR_NAMES end
    
    -- Return event-specific colors or default
    return currentEvent.trackColors or GameConstants.COLOR_NAMES
end

function EventService:GetEventBarrierEffect()
    if not currentEvent then return nil end
    return currentEvent.barrierEffect
end

-- Service dependency setters
function EventService:SetPlayerService(service)
    PlayerService = service
end

function EventService:SetGameService(service)
    GameService = service
end

function EventService:SetAnalyticsService(service)
    AnalyticsService = service
end

function EventService:SetQuestService(service)
    QuestService = service
end

-- Initialize automatically
EventService:Init()

return EventService
