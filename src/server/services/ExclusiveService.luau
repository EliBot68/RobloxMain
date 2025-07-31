-- ExclusiveService.luau
-- Handles limited-time exclusive cosmetics and FOMO-driven content

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local DataStoreService = game:GetService("DataStoreService")
local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local SafeRequire = require(ReplicatedStorage.Shared.utils.SafeRequire)
local WorldObjectValidator = SafeRequire.require(ReplicatedStorage.Shared.utils.WorldObjectValidator)
local PlayerService = SafeRequire.require(script.Parent.core.PlayerService)
local RemoteEvents = SafeRequire.require(ReplicatedStorage.Shared.modules.RemoteEvents)

local ExclusiveService = {}

-- DataStore for tracking exclusive ownership
local exclusiveStore = DataStoreService:GetDataStore("ExclusiveCosmetics")
local exclusiveScheduleStore = DataStoreService:GetDataStore("ExclusiveSchedule")

-- Current exclusive releases (7-day limited availability)
local EXCLUSIVE_RELEASES = {
    {
        id = "phantom_shadow",
        name = "👻 Phantom Shadow",
        type = "skin",
        description = "A ghostly skin that phases between dimensions - Only 7 days!",
        price = 99, -- Robux
        rarity = "Exclusive",
        effects = {
            transparency = 0.3,
            glowColor = Color3.new(0.5, 0, 1),
            phaseEffect = true,
            ghostTrail = true
        },
        releaseDate = os.time(),
        endDate = os.time() + (7 * 24 * 60 * 60), -- 7 days from now
        category = "Halloween Special",
        exclusivityText = "LIMITED TIME - 7 DAYS ONLY!"
    },
    {
        id = "cosmic_emperor",
        name = "👑 Cosmic Emperor",
        type = "skin",
        description = "Rule the universe with this majestic cosmic skin!",
        price = 149,
        rarity = "Exclusive",
        effects = {
            material = "ForceField",
            glowColor = Color3.new(1, 0.8, 0),
            starField = true,
            crownEffect = true,
            royalAura = true
        },
        releaseDate = os.time(),
        endDate = os.time() + (7 * 24 * 60 * 60),
        category = "Royal Collection",
        exclusivityText = "EMPEROR'S DECREE - 7 DAYS ONLY!"
    },
    {
        id = "neon_rebellion",
        name = "⚡ Neon Rebellion",
        type = "trail",
        description = "Rebel against the ordinary with this electric neon trail!",
        price = 79,
        rarity = "Exclusive",
        effects = {
            trailColor = Color3.new(0, 1, 1),
            electricSparks = true,
            neonGlow = true,
            rebellionSymbols = true
        },
        releaseDate = os.time(),
        endDate = os.time() + (7 * 24 * 60 * 60),
        category = "Cyberpunk Series",
        exclusivityText = "HACK THE SYSTEM - 7 DAYS LEFT!"
    },
    {
        id = "dragon_lord",
        name = "🐉 Dragon Lord",
        type = "skin",
        description = "Command the ancient power of dragons - Extremely Limited!",
        price = 199,
        rarity = "Exclusive",
        effects = {
            dragonScale = true,
            fireBreath = true,
            wingsShadow = true,
            ancientPower = true,
            goldAccents = true
        },
        releaseDate = os.time(),
        endDate = os.time() + (7 * 24 * 60 * 60),
        category = "Legendary Beasts",
        exclusivityText = "ANCIENT POWER - 7 DAYS TO ASCEND!"
    },
    {
        id = "void_walker",
        name = "🌌 Void Walker",
        type = "trail",
        description = "Walk between realities with this otherworldly trail!",
        price = 89,
        rarity = "Exclusive",
        effects = {
            voidPortals = true,
            realityDistortion = true,
            darkMatter = true,
            spaceTears = true
        },
        releaseDate = os.time(),
        endDate = os.time() + (7 * 24 * 60 * 60),
        category = "Interdimensional",
        exclusivityText = "BREACH REALITY - 7 DAYS REMAINING!"
    }
}

-- Track active exclusives and countdown timers
local activeExclusives = {}
local countdownConnections = {}
local exclusiveOwners = {}

function ExclusiveService:GetTimeRemaining(endDate)
    local currentTime = os.time()
    local timeLeft = endDate - currentTime
    
    if timeLeft <= 0 then
        return nil -- Expired
    end
    
    local days = math.floor(timeLeft / 86400)
    local hours = math.floor((timeLeft % 86400) / 3600)
    local minutes = math.floor((timeLeft % 3600) / 60)
    local seconds = timeLeft % 60
    
    return {
        total = timeLeft,
        days = days,
        hours = hours,
        minutes = minutes,
        seconds = seconds
    }
end

function ExclusiveService:FormatCountdown(timeData)
    if not timeData then
        return "EXPIRED"
    end
    
    if timeData.days > 0 then
        return string.format("%dd %dh %dm", timeData.days, timeData.hours, timeData.minutes)
    elseif timeData.hours > 0 then
        return string.format("%dh %dm %ds", timeData.hours, timeData.minutes, timeData.seconds)
    else
        return string.format("%dm %ds", timeData.minutes, timeData.seconds)
    end
end

function ExclusiveService:UpdateCountdownDisplays()
    -- Update countdown displays in the hub
    local hubCountdowns = Workspace.MarketPlaza:FindFirstChild("ExclusiveCountdowns")
    if not hubCountdowns then return end
    
    for i, exclusive in pairs(EXCLUSIVE_RELEASES) do
        local timeRemaining = self:GetTimeRemaining(exclusive.endDate)
        local countdownText = self:FormatCountdown(timeRemaining)
        
        local display = hubCountdowns:FindFirstChild("Exclusive" .. i)
        if display then
            local gui = display:FindFirstChild("CountdownGui")
            if gui then
                local countdownLabel = gui:FindFirstChild("CountdownLabel")
                local statusLabel = gui:FindFirstChild("StatusLabel")
                
                if countdownLabel then
                    if timeRemaining then
                        countdownLabel.Text = countdownText
                        countdownLabel.TextColor3 = timeRemaining.total < 3600 and Color3.new(1, 0.2, 0.2) or Color3.new(1, 1, 1)
                    else
                        countdownLabel.Text = "EXPIRED"
                        countdownLabel.TextColor3 = Color3.new(0.5, 0.5, 0.5)
                    end
                end
                
                if statusLabel then
                    local ownersCount = #(exclusiveOwners[exclusive.id] or {})
                    statusLabel.Text = ownersCount .. " OWNERS - " .. exclusive.exclusivityText
                end
            end
        end
    end
end

function ExclusiveService:CreateCountdownDisplay()
    local marketPlaza = Workspace.MarketPlaza
    local countdownArea = Instance.new("Folder")
    countdownArea.Name = "ExclusiveCountdowns"
    countdownArea.Parent = marketPlaza
    
    for i, exclusive in pairs(EXCLUSIVE_RELEASES) do
        local display = Instance.new("Part")
        display.Name = "Exclusive" .. i
        display.Size = Vector3.new(6, 8, 0.2)
        display.Material = Enum.Material.Neon
        display.Color = Color3.new(0.1, 0.1, 0.1)
        display.Anchored = true
        display.CanCollide = false
        display.Position = Vector3.new(-20 + (i * 8), 15, -5)
        display.Parent = countdownArea
        
        -- Add holographic effect
        local holoEffect = Instance.new("SelectionBox")
        holoEffect.Adornee = display
        holoEffect.Color3 = exclusive.type == "skin" and Color3.new(1, 0.5, 0) or Color3.new(0, 0.8, 1)
        holoEffect.Transparency = 0.3
        holoEffect.LineThickness = 0.2
        holoEffect.Parent = display
        
        -- Create GUI for countdown
        local gui = Instance.new("SurfaceGui")
        gui.Name = "CountdownGui"
        gui.Face = Enum.NormalId.Front
        gui.Parent = display
        
        -- Title
        local titleLabel = Instance.new("TextLabel")
        titleLabel.Name = "TitleLabel"
        titleLabel.Size = UDim2.new(1, 0, 0.3, 0)
        titleLabel.Position = UDim2.new(0, 0, 0, 0)
        titleLabel.BackgroundTransparency = 1
        titleLabel.Text = exclusive.name
        titleLabel.TextColor3 = Color3.new(1, 1, 1)
        titleLabel.TextScaled = true
        titleLabel.Font = Enum.Font.SourceSansBold
        titleLabel.TextStrokeTransparency = 0
        titleLabel.TextStrokeColor3 = Color3.new(0, 0, 0)
        titleLabel.Parent = gui
        
        -- Countdown
        local countdownLabel = Instance.new("TextLabel")
        countdownLabel.Name = "CountdownLabel"
        countdownLabel.Size = UDim2.new(1, 0, 0.25, 0)
        countdownLabel.Position = UDim2.new(0, 0, 0.3, 0)
        countdownLabel.BackgroundTransparency = 1
        countdownLabel.Text = "Loading..."
        countdownLabel.TextColor3 = Color3.new(1, 1, 1)
        countdownLabel.TextScaled = true
        countdownLabel.Font = Enum.Font.SourceSans
        countdownLabel.TextStrokeTransparency = 0
        countdownLabel.Parent = gui
        
        -- Price
        local priceLabel = Instance.new("TextLabel")
        priceLabel.Name = "PriceLabel"
        priceLabel.Size = UDim2.new(1, 0, 0.2, 0)
        priceLabel.Position = UDim2.new(0, 0, 0.55, 0)
        priceLabel.BackgroundTransparency = 1
        priceLabel.Text = "💎 " .. exclusive.price .. " ROBUX"
        priceLabel.TextColor3 = Color3.new(0, 1, 0.5)
        priceLabel.TextScaled = true
        priceLabel.Font = Enum.Font.SourceSansBold
        priceLabel.TextStrokeTransparency = 0
        priceLabel.Parent = gui
        
        -- Status
        local statusLabel = Instance.new("TextLabel")
        statusLabel.Name = "StatusLabel"
        statusLabel.Size = UDim2.new(1, 0, 0.25, 0)
        statusLabel.Position = UDim2.new(0, 0, 0.75, 0)
        statusLabel.BackgroundTransparency = 1
        statusLabel.Text = exclusive.exclusivityText
        statusLabel.TextColor3 = Color3.new(1, 0.8, 0)
        statusLabel.TextScaled = true
        statusLabel.Font = Enum.Font.SourceSansItalic
        statusLabel.TextStrokeTransparency = 0
        statusLabel.Parent = gui
        
        -- Click detector for purchase
        local clickDetector = Instance.new("ClickDetector")
        clickDetector.MaxActivationDistance = 20
        clickDetector.Parent = display
        
        clickDetector.MouseClick:Connect(function(player)
            self:OpenExclusivePurchase(player, exclusive)
            
            -- Track countdown viewing for quests
            local QuestService = require(script.Parent.QuestService)
            if QuestService then
                QuestService:UpdateQuestProgress(player, "countdown_viewed", 1)
            end
        end)
        
        -- Floating animation
        local floatTween = TweenService:Create(
            display,
            TweenInfo.new(3, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true),
            {Position = display.Position + Vector3.new(0, 1, 0)}
        )
        floatTween:Play()
        
        -- Pulsing glow for urgency
        local glowTween = TweenService:Create(
            holoEffect,
            TweenInfo.new(2, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true),
            {Transparency = 0.1}
        )
        glowTween:Play()
    end
end

function ExclusiveService:OpenExclusivePurchase(player, exclusive)
    local timeRemaining = self:GetTimeRemaining(exclusive.endDate)
    
    if not timeRemaining then
        RemoteEvents.ShowNotification:FireClient(player, "❌ This exclusive has expired!", "error")
        return
    end
    
    -- Check if player already owns this exclusive
    local userId = tostring(player.UserId)
    local playerData = PlayerService:GetPlayerData(player)
    
    if playerData.exclusiveCosmetics and playerData.exclusiveCosmetics[exclusive.id] then
        RemoteEvents.ShowNotification:FireClient(player, "✅ You already own this exclusive!", "info")
        return
    end
    
    -- Send purchase data to client
    RemoteEvents.ShowExclusivePurchase:FireClient(player, exclusive, timeRemaining)
end

function ExclusiveService:PurchaseExclusive(player, exclusiveId)
    -- Find the exclusive
    local exclusive = nil
    for _, ex in pairs(EXCLUSIVE_RELEASES) do
        if ex.id == exclusiveId then
            exclusive = ex
            break
        end
    end
    
    if not exclusive then
        return false, "Exclusive not found"
    end
    
    -- Check if still available
    local timeRemaining = self:GetTimeRemaining(exclusive.endDate)
    if not timeRemaining then
        return false, "This exclusive has expired"
    end
    
    local userId = tostring(player.UserId)
    local playerData = PlayerService:GetPlayerData(player)
    
    -- Check if already owned
    if playerData.exclusiveCosmetics and playerData.exclusiveCosmetics[exclusiveId] then
        return false, "You already own this exclusive"
    end
    
    -- Note: In a real game, you'd integrate with Roblox's Developer Products for Robux purchases
    -- For now, we'll simulate the purchase
    
    -- Initialize exclusive cosmetics if needed
    if not playerData.exclusiveCosmetics then
        playerData.exclusiveCosmetics = {}
    end
    
    -- Grant the exclusive
    playerData.exclusiveCosmetics[exclusiveId] = {
        purchaseDate = os.time(),
        exclusiveData = exclusive
    }
    
    -- Track ownership for social features
    if not exclusiveOwners[exclusiveId] then
        exclusiveOwners[exclusiveId] = {}
    end
    
    local purchaseRank = #exclusiveOwners[exclusiveId] + 1
    table.insert(exclusiveOwners[exclusiveId], {
        userId = userId,
        playerName = player.Name,
        purchaseDate = os.time(),
        purchaseRank = purchaseRank
    })
    
    -- Save to DataStore
    pcall(function()
        exclusiveStore:SetAsync(userId .. "_" .. exclusiveId, {
            purchased = true,
            purchaseDate = os.time(),
            playerName = player.Name,
            purchaseRank = purchaseRank
        })
    end)
    
    PlayerService:UpdatePlayerData(player, playerData)
    
    -- Update quest progress
    local QuestService = require(script.Parent.QuestService)
    if QuestService then
        -- Track exclusive purchase
        QuestService:UpdateQuestProgress(player, "exclusive_purchased", 1, {
            exclusiveId = exclusiveId,
            price = exclusive.price,
            rarity = exclusive.rarity
        })
        
        -- Track premium exclusive purchase
        if exclusive.price >= 150 then
            QuestService:UpdateQuestProgress(player, "premium_exclusive_purchased", 1, {
                price = exclusive.price
            })
        end
        
        -- Track early purchase (first 10)
        if purchaseRank <= 10 then
            QuestService:UpdateQuestProgress(player, "early_exclusive_purchase", 1, {
                purchaseRank = purchaseRank
            })
        end
        
        -- Track last minute purchase
        if timeRemaining and timeRemaining.total < 86400 then -- Less than 24 hours
            QuestService:UpdateQuestProgress(player, "last_minute_purchase", 1, {
                timeRemaining = timeRemaining.total
            })
        end
        
        -- Track total exclusives owned
        local totalExclusives = 0
        for _ in pairs(playerData.exclusiveCosmetics) do
            totalExclusives = totalExclusives + 1
        end
        QuestService:UpdateQuestProgress(player, "exclusives_owned", totalExclusives)
    end
    
    -- Notify success with celebration
    RemoteEvents.ExclusivePurchased:FireClient(player, exclusive)
    RemoteEvents.ApplySpecialEffect:FireClient(player, "exclusive_celebration", 10)
    
    -- Update leaderboard display
    self:UpdateLeaderboardDisplay(player, exclusive)
    
    print("🌟 " .. player.Name .. " purchased exclusive: " .. exclusive.name)
    
    return true, "Exclusive purchased successfully!"
end

function ExclusiveService:UpdateLeaderboardDisplay(player, exclusive)
    -- Update the leaderboard to show off exclusive owners
    local leaderboard = Workspace.MarketPlaza:FindFirstChild("Leaderboard")
    if not leaderboard then return end
    
    -- Add exclusive badge to player's leaderboard entry
    spawn(function()
        wait(1) -- Wait for leaderboard to update
        
        local leaderboardGui = leaderboard:FindFirstChild("LeaderboardGui")
        if not leaderboardGui then return end
        
        local playerFrame = leaderboardGui:FindFirstChild(player.Name .. "_Frame")
        if not playerFrame then return end
        
        -- Add exclusive badge
        local exclusiveBadge = Instance.new("ImageLabel")
        exclusiveBadge.Name = "ExclusiveBadge"
        exclusiveBadge.Size = UDim2.new(0, 30, 0, 30)
        exclusiveBadge.Position = UDim2.new(1, -35, 0, 5)
        exclusiveBadge.BackgroundTransparency = 1
        exclusiveBadge.Image = "rbxasset://textures/ui/GuiImagePlaceholder.png" -- Replace with actual exclusive badge
        exclusiveBadge.Parent = playerFrame
        
        -- Add glow effect
        local glowEffect = Instance.new("ImageLabel")
        glowEffect.Size = UDim2.new(1.5, 0, 1.5, 0)
        glowEffect.Position = UDim2.new(-0.25, 0, -0.25, 0)
        glowEffect.BackgroundTransparency = 1
        glowEffect.Image = "rbxasset://textures/ui/GuiImagePlaceholder.png" -- Glow texture
        glowEffect.ImageColor3 = Color3.new(1, 0.8, 0)
        glowEffect.ImageTransparency = 0.5
        glowEffect.Parent = exclusiveBadge
        
        -- Pulsing animation for envy generation
        local pulseTween = TweenService:Create(
            glowEffect,
            TweenInfo.new(2, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true),
            {ImageTransparency = 0.2}
        )
        pulseTween:Play()
    end)
end

function ExclusiveService:LoadExclusiveOwners()
    -- Load all exclusive owners from DataStore for social features
    for _, exclusive in pairs(EXCLUSIVE_RELEASES) do
        exclusiveOwners[exclusive.id] = {}
        
        -- In a real implementation, you'd batch load from DataStore
        -- For now, we'll populate as players join
    end
end

function ExclusiveService:DisplayExclusiveOnNPC(npc, exclusiveId)
    -- Show exclusive cosmetics on NPCs to generate envy
    local exclusive = nil
    for _, ex in pairs(EXCLUSIVE_RELEASES) do
        if ex.id == exclusiveId then
            exclusive = ex
            break
        end
    end
    
    if not exclusive then return end
    
    -- Apply exclusive effects to NPC
    local npcModel = npc
    if exclusive.type == "skin" then
        for _, part in pairs(npcModel:GetChildren()) do
            if part:IsA("BasePart") then
                if exclusive.effects.material then
                    part.Material = Enum.Material[exclusive.effects.material]
                end
                if exclusive.effects.glowColor then
                    part.Color = exclusive.effects.glowColor
                end
            end
        end
    end
    
    -- Add floating text showing it's exclusive
    local billboardGui = Instance.new("BillboardGui")
    billboardGui.Size = UDim2.new(0, 300, 0, 50)
    billboardGui.StudsOffset = Vector3.new(0, 3, 0)
    billboardGui.Parent = npcModel:FindFirstChild("Head") or npcModel.PrimaryPart
    
    local exclusiveLabel = Instance.new("TextLabel")
    exclusiveLabel.Size = UDim2.new(1, 0, 1, 0)
    exclusiveLabel.BackgroundTransparency = 1
    exclusiveLabel.Text = "✨ " .. exclusive.name .. " ✨"
    exclusiveLabel.TextColor3 = Color3.new(1, 0.8, 0)
    exclusiveLabel.TextScaled = true
    exclusiveLabel.Font = Enum.Font.SourceSansBold
    exclusiveLabel.TextStrokeTransparency = 0
    exclusiveLabel.Parent = billboardGui
    
    -- Glowing animation
    local glowTween = TweenService:Create(
        exclusiveLabel,
        TweenInfo.new(3, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true),
        {TextColor3 = Color3.new(1, 1, 0)}
    )
    glowTween:Play()
end

function ExclusiveService:CheckExpiredExclusives()
    -- Remove expired exclusives from shop
    local currentTime = os.time()
    
    for i = #EXCLUSIVE_RELEASES, 1, -1 do
        local exclusive = EXCLUSIVE_RELEASES[i]
        if currentTime >= exclusive.endDate then
            print("⏰ Exclusive expired: " .. exclusive.name)
            
            -- Remove from active releases
            table.remove(EXCLUSIVE_RELEASES, i)
            
            -- Notify all players about expiration
            for _, player in pairs(Players:GetPlayers()) do
                RemoteEvents.ExclusiveExpired:FireClient(player, exclusive)
            end
        end
    end
end

function ExclusiveService:GetExclusiveLeaderboard(exclusiveId)
    -- Return top owners of a specific exclusive for social display
    local owners = exclusiveOwners[exclusiveId] or {}
    
    -- Sort by purchase date (earliest = most prestigious)
    table.sort(owners, function(a, b)
        return a.purchaseDate < b.purchaseDate
    end)
    
    return owners
end

function ExclusiveService:StartCountdownSystem()
    -- Update countdown displays every second
    local connection = RunService.Heartbeat:Connect(function()
        self:UpdateCountdownDisplays()
        
        -- Check for expired exclusives every minute
        if tick() % 60 < 1 then
            self:CheckExpiredExclusives()
        end
    end)
    
    table.insert(countdownConnections, connection)
end

function ExclusiveService:Initialize()
    print("🌟 ExclusiveService initializing...")
    
    -- Validate exclusive-related world objects
    print("🔍 Validating exclusive world objects...")
    local missingObjects = WorldObjectValidator.validateAllRequired()
    if #missingObjects > 0 then
        warn("⚠️ ExclusiveService: Missing required world objects:")
        for _, missing in ipairs(missingObjects) do
            warn("  • " .. missing)
        end
    end
    
    -- Validate MarketPlaza for exclusive displays
    local marketExists = WorldObjectValidator.validateObjectWithWait("workspace.MarketPlaza", 5)
    if not marketExists then
        warn("⚠️ ExclusiveService: MarketPlaza not found - exclusive displays may not work")
    else
        print("✅ ExclusiveService: MarketPlaza validated for exclusive displays")
    end
    
    -- Validate billboard anchors for countdown displays
    local billboardsExist = WorldObjectValidator.validateObjectWithWait("workspace.BillboardAnchors", 3)
    if not billboardsExist then
        warn("⚠️ ExclusiveService: BillboardAnchors not found - countdown displays may not appear")
    else
        print("✅ ExclusiveService: BillboardAnchors validated")
    end
    
    -- Wait for workspace to be ready
    wait(2)
    
    -- Load existing exclusive owners
    self:LoadExclusiveOwners()
    
    -- Create countdown displays in hub
    self:CreateCountdownDisplay()
    
    -- Start countdown system
    self:StartCountdownSystem()
    
    -- Display exclusives on some NPCs for envy generation
    spawn(function()
        wait(3)
        
        -- Find NPCs and randomly assign exclusive displays
        local npcs = Workspace:FindFirstChild("NPCs")
        if npcs then
            local npcList = npcs:GetChildren()
            for i, npc in pairs(npcList) do
                if i <= #EXCLUSIVE_RELEASES then
                    self:DisplayExclusiveOnNPC(npc, EXCLUSIVE_RELEASES[i].id)
                end
            end
        end
    end)
    
    print("✅ ExclusiveService initialized successfully!")
    print("🎯 " .. #EXCLUSIVE_RELEASES .. " exclusive items available for 7 days!")
end

-- Handle exclusive purchases
local function onPlayerAdded(player)
    -- Load player's exclusive cosmetics when they join
    spawn(function()
        wait(3)
        local playerData = PlayerService:GetPlayerData(player)
        
        if playerData.exclusiveCosmetics then
            for exclusiveId, data in pairs(playerData.exclusiveCosmetics) do
                -- Add to owners list for social features
                if not exclusiveOwners[exclusiveId] then
                    exclusiveOwners[exclusiveId] = {}
                end
                
                local alreadyListed = false
                for _, owner in pairs(exclusiveOwners[exclusiveId]) do
                    if owner.userId == tostring(player.UserId) then
                        alreadyListed = true
                        break
                    end
                end
                
                if not alreadyListed then
                    table.insert(exclusiveOwners[exclusiveId], {
                        userId = tostring(player.UserId),
                        playerName = player.Name,
                        purchaseDate = data.purchaseDate
                    })
                end
            end
        end
    end)
end

Players.PlayerAdded:Connect(onPlayerAdded)

-- Remote event handlers
RemoteEvents.PurchaseExclusive.OnServerEvent:Connect(function(player, exclusiveId)
    local success, message = ExclusiveService:PurchaseExclusive(player, exclusiveId)
    RemoteEvents.ExclusivePurchaseResult:FireClient(player, success, message)
end)

RemoteEvents.GetExclusiveLeaderboard.OnServerEvent:Connect(function(player, exclusiveId)
    local leaderboard = ExclusiveService:GetExclusiveLeaderboard(exclusiveId)
    RemoteEvents.ExclusiveLeaderboardData:FireClient(player, exclusiveId, leaderboard)
end)

-- Auto-initialize
ExclusiveService:Initialize()

return ExclusiveService
