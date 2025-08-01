-- BuffController.luau
-- Client-side buff UI and visual effects

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SoundService = game:GetService("SoundService")
local RunService = game:GetService("RunService")

local RemoteEvents = require(ReplicatedStorage.Shared.modules.RemoteEvents)

local BuffController = {}
local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- UI elements
local buffGui = nil
local activeBuffsFrame = nil
local buffShopFrame = nil

-- Active buff tracking
local activeBuffElements = {}
local visualEffects = {}

-- Sound effects
local sounds = {
    buffActivated = nil,
    buffExpired = nil,
    buffCollected = nil,
    shieldBreak = nil
}

function BuffController:Init()
    print("💫 BuffController initializing...")
    
    self:CreateBuffUI()
    self:SetupRemoteEvents()
    self:LoadSounds()
    
    print("✅ BuffController initialized!")
end

function BuffController:CreateBuffUI()
    -- Create main UI
    buffGui = Instance.new("ScreenGui")
    buffGui.Name = "BuffGui"
    buffGui.ResetOnSpawn = false
    buffGui.Parent = playerGui
    
    -- Create active buffs display
    self:CreateActiveBuffsDisplay()
    
    -- Create buff shop interface
    self:CreateBuffShopInterface()
end

function BuffController:CreateActiveBuffsDisplay()
    activeBuffsFrame = Instance.new("Frame")
    activeBuffsFrame.Name = "ActiveBuffsFrame"
    activeBuffsFrame.Size = UDim2.new(0, 300, 0, 100)
    activeBuffsFrame.Position = UDim2.new(1, -320, 0, 20)
    activeBuffsFrame.BackgroundTransparency = 1
    activeBuffsFrame.Parent = buffGui
    
    -- Title
    local titleLabel = Instance.new("TextLabel")
    titleLabel.Name = "TitleLabel"
    titleLabel.Size = UDim2.new(1, 0, 0, 25)
    titleLabel.Position = UDim2.new(0, 0, 0, 0)
    titleLabel.BackgroundTransparency = 1
    titleLabel.Text = "💫 Active Buffs"
    titleLabel.TextColor3 = Color3.new(1, 1, 1)
    titleLabel.TextScaled = true
    titleLabel.Font = Enum.Font.SourceSansBold
    titleLabel.TextStrokeTransparency = 0
    titleLabel.TextStrokeColor3 = Color3.new(0, 0, 0)
    titleLabel.Parent = activeBuffsFrame
    
    -- Buffs container
    local buffsContainer = Instance.new("Frame")
    buffsContainer.Name = "BuffsContainer"
    buffsContainer.Size = UDim2.new(1, 0, 1, -30)
    buffsContainer.Position = UDim2.new(0, 0, 0, 30)
    buffsContainer.BackgroundTransparency = 1
    buffsContainer.Parent = activeBuffsFrame
    
    local listLayout = Instance.new("UIListLayout")
    listLayout.SortOrder = Enum.SortOrder.LayoutOrder
    listLayout.Padding = UDim.new(0, 5)
    listLayout.Parent = buffsContainer
end

function BuffController:CreateBuffShopInterface()
    buffShopFrame = Instance.new("Frame")
    buffShopFrame.Name = "BuffShopFrame"
    buffShopFrame.Size = UDim2.new(0, 600, 0, 400)
    buffShopFrame.Position = UDim2.new(0.5, -300, 0.5, -200)
    buffShopFrame.BackgroundColor3 = Color3.new(0.1, 0.1, 0.2)
    buffShopFrame.BackgroundTransparency = 0.1
    buffShopFrame.BorderSizePixel = 0
    buffShopFrame.Visible = false
    buffShopFrame.Parent = buffGui
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 20)
    corner.Parent = buffShopFrame
    
    local stroke = Instance.new("UIStroke")
    stroke.Color = Color3.new(0.6, 0.3, 1)
    stroke.Thickness = 3
    stroke.Parent = buffShopFrame
    
    -- Shop title
    local shopTitle = Instance.new("TextLabel")
    shopTitle.Name = "ShopTitle"
    shopTitle.Size = UDim2.new(1, -40, 0, 60)
    shopTitle.Position = UDim2.new(0, 20, 0, 10)
    shopTitle.BackgroundTransparency = 1
    shopTitle.Text = "💫 Power-Up Shop"
    shopTitle.TextColor3 = Color3.new(1, 1, 1)
    shopTitle.TextScaled = true
    shopTitle.Font = Enum.Font.SourceSansBold
    shopTitle.TextStrokeTransparency = 0
    shopTitle.TextStrokeColor3 = Color3.new(0, 0, 0)
    shopTitle.Parent = buffShopFrame
    
    -- Close button
    local closeButton = Instance.new("TextButton")
    closeButton.Name = "CloseButton"
    closeButton.Size = UDim2.new(0, 40, 0, 40)
    closeButton.Position = UDim2.new(1, -50, 0, 10)
    closeButton.BackgroundColor3 = Color3.new(0.8, 0.2, 0.2)
    closeButton.BorderSizePixel = 0
    closeButton.Text = "✕"
    closeButton.TextColor3 = Color3.new(1, 1, 1)
    closeButton.TextScaled = true
    closeButton.Font = Enum.Font.SourceSansBold
    closeButton.Parent = buffShopFrame
    
    local closeCorner = Instance.new("UICorner")
    closeCorner.CornerRadius = UDim.new(0, 10)
    closeCorner.Parent = closeButton
    
    closeButton.MouseButton1Click:Connect(function()
        self:CloseBuffShop()
    end)
    
    -- Scroll frame for buffs
    local scrollFrame = Instance.new("ScrollingFrame")
    scrollFrame.Name = "BuffScrollFrame"
    scrollFrame.Size = UDim2.new(1, -40, 1, -100)
    scrollFrame.Position = UDim2.new(0, 20, 0, 80)
    scrollFrame.BackgroundTransparency = 1
    scrollFrame.BorderSizePixel = 0
    scrollFrame.ScrollBarThickness = 8
    scrollFrame.Parent = buffShopFrame
    
    local gridLayout = Instance.new("UIGridLayout")
    gridLayout.CellSize = UDim2.new(0, 160, 0, 120)
    gridLayout.CellPadding = UDim2.new(0, 10, 0, 10)
    gridLayout.SortOrder = Enum.SortOrder.LayoutOrder
    gridLayout.Parent = scrollFrame
    
    -- Populate shop with buff items
    self:PopulateBuffShop(scrollFrame)
end

function BuffController:PopulateBuffShop(parent)
    local buffTypes = {
        "coinMagnet", "comboStreak", "speedBoost", 
        "shieldProtection", "timeFreeze", "doubleCoins"
    }
    
    local buffConfigs = {
        coinMagnet = {name = "💰 Coin Magnet", price = 50, description = "Attracts nearby coins"},
        comboStreak = {name = "🔥 Combo Streak", price = 75, description = "2x score multiplier"},
        speedBoost = {name = "⚡ Speed Boost", price = 40, description = "25% faster movement"},
        shieldProtection = {name = "🛡️ Shield", price = 100, description = "Survive one collision"},
        timeFreeze = {name = "❄️ Time Freeze", price = 80, description = "Slow down barriers"},
        doubleCoins = {name = "💎 Double Coins", price = 60, description = "2x coin rewards"}
    }
    
    for i, buffType in ipairs(buffTypes) do
        local config = buffConfigs[buffType]
        if config then
            self:CreateBuffShopItem(parent, buffType, config, i)
        end
    end
end

function BuffController:CreateBuffShopItem(parent, buffType, config, layoutOrder)
    local itemFrame = Instance.new("Frame")
    itemFrame.Name = "BuffItem_" .. buffType
    itemFrame.Size = UDim2.new(0, 160, 0, 120)
    itemFrame.BackgroundColor3 = Color3.new(0.2, 0.2, 0.3)
    itemFrame.BorderSizePixel = 0
    itemFrame.LayoutOrder = layoutOrder
    itemFrame.Parent = parent
    
    local itemCorner = Instance.new("UICorner")
    itemCorner.CornerRadius = UDim.new(0, 15)
    itemCorner.Parent = itemFrame
    
    local itemStroke = Instance.new("UIStroke")
    itemStroke.Color = Color3.new(0.4, 0.4, 0.5)
    itemStroke.Thickness = 2
    itemStroke.Parent = itemFrame
    
    -- Buff name
    local nameLabel = Instance.new("TextLabel")
    nameLabel.Size = UDim2.new(1, -10, 0, 30)
    nameLabel.Position = UDim2.new(0, 5, 0, 5)
    nameLabel.BackgroundTransparency = 1
    nameLabel.Text = config.name
    nameLabel.TextColor3 = Color3.new(1, 1, 1)
    nameLabel.TextScaled = true
    nameLabel.Font = Enum.Font.SourceSansBold
    nameLabel.Parent = itemFrame
    
    -- Description
    local descLabel = Instance.new("TextLabel")
    descLabel.Size = UDim2.new(1, -10, 0, 40)
    descLabel.Position = UDim2.new(0, 5, 0, 35)
    descLabel.BackgroundTransparency = 1
    descLabel.Text = config.description
    descLabel.TextColor3 = Color3.new(0.8, 0.8, 0.8)
    descLabel.TextScaled = true
    descLabel.Font = Enum.Font.SourceSans
    descLabel.TextWrapped = true
    descLabel.Parent = itemFrame
    
    -- Purchase button
    local purchaseButton = Instance.new("TextButton")
    purchaseButton.Size = UDim2.new(1, -10, 0, 30)
    purchaseButton.Position = UDim2.new(0, 5, 1, -35)
    purchaseButton.BackgroundColor3 = Color3.new(0.3, 0.6, 1)
    purchaseButton.BorderSizePixel = 0
    purchaseButton.Text = "💰 " .. config.price .. " coins"
    purchaseButton.TextColor3 = Color3.new(1, 1, 1)
    purchaseButton.TextScaled = true
    purchaseButton.Font = Enum.Font.SourceSansBold
    purchaseButton.Parent = itemFrame
    
    local buttonCorner = Instance.new("UICorner")
    buttonCorner.CornerRadius = UDim.new(0, 10)
    buttonCorner.Parent = purchaseButton
    
    -- Purchase click handler
    purchaseButton.MouseButton1Click:Connect(function()
        self:PurchaseBuff(buffType)
    end)
    
    -- Hover effects
    purchaseButton.MouseEnter:Connect(function()
        local hoverTween = TweenService:Create(
            purchaseButton,
            TweenInfo.new(0.2, Enum.EasingStyle.Quad),
            {BackgroundColor3 = Color3.new(0.4, 0.7, 1)}
        )
        hoverTween:Play()
    end)
    
    purchaseButton.MouseLeave:Connect(function()
        local leaveTween = TweenService:Create(
            purchaseButton,
            TweenInfo.new(0.2, Enum.EasingStyle.Quad),
            {BackgroundColor3 = Color3.new(0.3, 0.6, 1)}
        )
        leaveTween:Play()
    end)
end

function BuffController:ShowActiveBuffDisplay(buffData)
    local buffType = buffData.buffType
    local config = buffData.config
    
    if activeBuffElements[buffType] then
        -- Update existing display
        self:UpdateBuffDisplay(buffType, buffData)
        return
    end
    
    -- Create new buff display
    local buffsContainer = activeBuffsFrame.BuffsContainer
    
    local buffFrame = Instance.new("Frame")
    buffFrame.Name = "Buff_" .. buffType
    buffFrame.Size = UDim2.new(1, 0, 0, 60)
    buffFrame.BackgroundColor3 = Color3.new(0.1, 0.1, 0.2)
    buffFrame.BackgroundTransparency = 0.2
    buffFrame.BorderSizePixel = 0
    buffFrame.Parent = buffsContainer
    
    local buffCorner = Instance.new("UICorner")
    buffCorner.CornerRadius = UDim.new(0, 10)
    buffCorner.Parent = buffFrame
    
    local buffStroke = Instance.new("UIStroke")
    buffStroke.Color = Color3.new(0.6, 0.3, 1)
    buffStroke.Thickness = 2
    buffStroke.Parent = buffFrame
    
    -- Buff icon and name
    local iconLabel = Instance.new("TextLabel")
    iconLabel.Size = UDim2.new(0, 120, 1, -10)
    iconLabel.Position = UDim2.new(0, 5, 0, 5)
    iconLabel.BackgroundTransparency = 1
    iconLabel.Text = config.name
    iconLabel.TextColor3 = Color3.new(1, 1, 1)
    iconLabel.TextScaled = true
    iconLabel.Font = Enum.Font.SourceSansBold
    iconLabel.TextStrokeTransparency = 0
    iconLabel.TextStrokeColor3 = Color3.new(0, 0, 0)
    iconLabel.Parent = buffFrame
    
    -- Timer display
    local timerLabel = Instance.new("TextLabel")
    timerLabel.Name = "TimerLabel"
    timerLabel.Size = UDim2.new(0, 60, 1, -10)
    timerLabel.Position = UDim2.new(1, -65, 0, 5)
    timerLabel.BackgroundTransparency = 1
    timerLabel.Text = tostring(math.ceil(buffData.duration or 30))
    timerLabel.TextColor3 = Color3.new(1, 1, 0.3)
    timerLabel.TextScaled = true
    timerLabel.Font = Enum.Font.SourceSans
    timerLabel.TextStrokeTransparency = 0
    timerLabel.TextStrokeColor3 = Color3.new(0, 0, 0)
    timerLabel.Parent = buffFrame
    
    -- Progress bar
    local progressBG = Instance.new("Frame")
    progressBG.Size = UDim2.new(1, -10, 0, 8)
    progressBG.Position = UDim2.new(0, 5, 1, -15)
    progressBG.BackgroundColor3 = Color3.new(0.2, 0.2, 0.3)
    progressBG.BorderSizePixel = 0
    progressBG.Parent = buffFrame
    
    local progressCorner = Instance.new("UICorner")
    progressCorner.CornerRadius = UDim.new(0, 4)
    progressCorner.Parent = progressBG
    
    local progressBar = Instance.new("Frame")
    progressBar.Name = "ProgressBar"
    progressBar.Size = UDim2.new(1, 0, 1, 0)
    progressBar.Position = UDim2.new(0, 0, 0, 0)
    progressBar.BackgroundColor3 = Color3.new(0.6, 0.3, 1)
    progressBar.BorderSizePixel = 0
    progressBar.Parent = progressBG
    
    local barCorner = Instance.new("UICorner")
    barCorner.CornerRadius = UDim.new(0, 4)
    barCorner.Parent = progressBar
    
    -- Store reference
    activeBuffElements[buffType] = {
        frame = buffFrame,
        timer = timerLabel,
        progressBar = progressBar,
        startTime = tick(),
        duration = buffData.duration or 30
    }
    
    -- Animate entrance
    buffFrame.Position = UDim2.new(1, 0, 0, 0)
    local slideIn = TweenService:Create(
        buffFrame,
        TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
        {Position = UDim2.new(0, 0, 0, 0)}
    )
    slideIn:Play()
    
    -- Start timer countdown
    self:StartBuffTimer(buffType)
    
    -- Play activation sound
    if sounds.buffActivated then
        sounds.buffActivated:Play()
    end
end

function BuffController:StartBuffTimer(buffType)
    local buffElement = activeBuffElements[buffType]
    if not buffElement then return end
    
    spawn(function()
        while buffElement.frame.Parent do
            local elapsed = tick() - buffElement.startTime
            local remaining = math.max(0, buffElement.duration - elapsed)
            local progress = remaining / buffElement.duration
            
            -- Update timer
            buffElement.timer.Text = tostring(math.ceil(remaining))
            
            -- Update progress bar
            buffElement.progressBar.Size = UDim2.new(progress, 0, 1, 0)
            
            -- Change color as time runs out
            if progress > 0.5 then
                buffElement.progressBar.BackgroundColor3 = Color3.new(0.3, 1, 0.3) -- Green
            elseif progress > 0.25 then
                buffElement.progressBar.BackgroundColor3 = Color3.new(1, 1, 0.3) -- Yellow
            else
                buffElement.progressBar.BackgroundColor3 = Color3.new(1, 0.3, 0.3) -- Red
            end
            
            if remaining <= 0 then
                break
            end
            
            task.delay(0.15, function() -- Continue countdown with optimized interval
                -- Countdown continues in next iteration
            end)
        end
    end)
end

function BuffController:UpdateBuffDisplay(buffType, buffData)
    local buffElement = activeBuffElements[buffType]
    if not buffElement then return end
    
    -- Extend duration for buff refresh
    if buffData.isExtended then
        buffElement.duration = buffData.timeRemaining
        buffElement.startTime = tick()
        
        -- Show extension effect
        local extendTween = TweenService:Create(
            buffElement.frame,
            TweenInfo.new(0.3, Enum.EasingStyle.Bounce),
            {Size = UDim2.new(1, 10, 0, 70)}
        )
        extendTween:Play()
        
        extendTween.Completed:Connect(function()
            local resetTween = TweenService:Create(
                buffElement.frame,
                TweenInfo.new(0.2, Enum.EasingStyle.Quad),
                {Size = UDim2.new(1, 0, 0, 60)}
            )
            resetTween:Play()
        end)
    end
end

function BuffController:RemoveBuffDisplay(buffType)
    local buffElement = activeBuffElements[buffType]
    if not buffElement then return end
    
    -- Animate exit
    local slideOut = TweenService:Create(
        buffElement.frame,
        TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.In),
        {Position = UDim2.new(1, 0, 0, 0)}
    )
    slideOut:Play()
    
    slideOut.Completed:Connect(function()
        if buffElement.frame then
            buffElement.frame:Destroy()
        end
    end)
    
    -- Clean up reference
    activeBuffElements[buffType] = nil
    
    -- Play expiration sound
    if sounds.buffExpired then
        sounds.buffExpired:Play()
    end
end

function BuffController:CreateVisualEffect(effectData)
    if effectData.effectType == "shieldBreak" then
        self:CreateShieldBreakEffect(effectData.position)
    elseif effectData.effectType == "timeFreeze" then
        self:CreateTimeFreezeEffect()
    elseif effectData.effectType == "coinMagnet" then
        self:CreateCoinMagnetEffect()
    end
end

function BuffController:CreateShieldBreakEffect(position)
    -- Create dramatic shield break particles
    local effectPart = Instance.new("Part")
    effectPart.Size = Vector3.new(0.1, 0.1, 0.1)
    effectPart.Position = position
    effectPart.Anchored = true
    effectPart.CanCollide = false
    effectPart.Transparency = 1
    effectPart.Parent = workspace
    
    local attachment = Instance.new("Attachment")
    attachment.Parent = effectPart
    
    -- Shield break particles
    local shieldBreak = Instance.new("ParticleEmitter")
    shieldBreak.Parent = attachment
    shieldBreak.Enabled = true
    shieldBreak.Lifetime = NumberRange.new(1.0, 2.0)
    shieldBreak.Rate = 300
    shieldBreak.SpreadAngle = Vector2.new(360, 360)
    shieldBreak.Speed = NumberRange.new(15, 30)
    shieldBreak.Color = ColorSequence.new{
        ColorSequenceKeypoint.new(0, Color3.new(0.3, 0.8, 0.3)),
        ColorSequenceKeypoint.new(0.5, Color3.new(0.8, 1, 0.8)),
        ColorSequenceKeypoint.new(1, Color3.new(0.2, 0.4, 0.2))
    }
    
    -- Play shield break sound
    if sounds.shieldBreak then
        sounds.shieldBreak:Play()
    end
    
    -- Event-driven cleanup (NO POLLING)
    task.delay(0.8, function() -- Slightly longer effect
        shieldBreak.Enabled = false
        task.delay(2.5, function() -- Extended cleanup time
            effectPart:Destroy()
        end)
    end)
end

function BuffController:CreateTimeFreezeEffect()
    -- Create screen-wide time freeze effect
    local screenEffect = Instance.new("Frame")
    screenEffect.Size = UDim2.new(1, 0, 1, 0)
    screenEffect.Position = UDim2.new(0, 0, 0, 0)
    screenEffect.BackgroundColor3 = Color3.new(0.7, 0.9, 1)
    screenEffect.BackgroundTransparency = 0.8
    screenEffect.BorderSizePixel = 0
    screenEffect.Parent = buffGui
    
    -- Pulsing effect
    local pulseTween = TweenService:Create(
        screenEffect,
        TweenInfo.new(1, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true),
        {BackgroundTransparency = 0.9}
    )
    pulseTween:Play()
    
    -- Remove after 15 seconds
    spawn(function()
        wait(15)
        pulseTween:Cancel()
        screenEffect:Destroy()
    end)
end

function BuffController:PurchaseBuff(buffType)
    RemoteEvents.PurchaseBuff:FireServer(buffType)
end

function BuffController:OpenBuffShop()
    buffShopFrame.Visible = true
    buffShopFrame.Size = UDim2.new(0, 0, 0, 0)
    buffShopFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
    
    local openTween = TweenService:Create(
        buffShopFrame,
        TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
        {
            Size = UDim2.new(0, 600, 0, 400),
            Position = UDim2.new(0.5, -300, 0.5, -200)
        }
    )
    openTween:Play()
end

function BuffController:CloseBuffShop()
    local closeTween = TweenService:Create(
        buffShopFrame,
        TweenInfo.new(0.2, Enum.EasingStyle.Back, Enum.EasingDirection.In),
        {
            Size = UDim2.new(0, 0, 0, 0),
            Position = UDim2.new(0.5, 0, 0.5, 0)
        }
    )
    closeTween:Play()
    
    closeTween.Completed:Connect(function()
        buffShopFrame.Visible = false
    end)
end

function BuffController:LoadSounds()
    sounds.buffActivated = Instance.new("Sound")
    sounds.buffActivated.SoundId = "rbxasset://sounds/action_get_up.mp3"
    sounds.buffActivated.Volume = 0.6
    sounds.buffActivated.Parent = SoundService
    
    sounds.buffExpired = Instance.new("Sound")
    sounds.buffExpired.SoundId = "rbxasset://sounds/electronicpingshort.wav"
    sounds.buffExpired.Volume = 0.4
    sounds.buffExpired.Parent = SoundService
    
    sounds.buffCollected = Instance.new("Sound")
    sounds.buffCollected.SoundId = "rbxasset://sounds/action_footsteps_plastic.mp3"
    sounds.buffCollected.Volume = 0.5
    sounds.buffCollected.Parent = SoundService
    
    sounds.shieldBreak = Instance.new("Sound")
    sounds.shieldBreak.SoundId = "rbxasset://sounds/impact_generic.mp3"
    sounds.shieldBreak.Volume = 0.8
    sounds.shieldBreak.Parent = SoundService
end

function BuffController:SetupRemoteEvents()
    -- Handle buff activation
    RemoteEvents.BuffActivated.OnClientEvent:Connect(function(buffData)
        self:ShowActiveBuffDisplay(buffData)
    end)
    
    -- Handle buff expiration
    RemoteEvents.BuffExpired.OnClientEvent:Connect(function(buffData)
        self:RemoveBuffDisplay(buffData.buffType)
    end)
    
    -- Handle buff time updates
    RemoteEvents.BuffTimeUpdate.OnClientEvent:Connect(function(updateData)
        -- Update handled by timer system
    end)
    
    -- Handle buff updates (extensions)
    RemoteEvents.BuffUpdated.OnClientEvent:Connect(function(updateData)
        self:UpdateBuffDisplay(updateData.buffType, updateData)
    end)
    
    -- Handle visual effects
    RemoteEvents.CreateEffect.OnClientEvent:Connect(function(effectData)
        self:CreateVisualEffect(effectData)
    end)
    
    -- Handle shield activation
    RemoteEvents.ShieldActivated.OnClientEvent:Connect(function()
        -- Create shield activation effect
        print("🛡️ Shield activated!")
    end)
    
    -- Handle streak effects
    RemoteEvents.ShowStreakEffect.OnClientEvent:Connect(function(streakData)
        -- Show combo streak multiplier
        print("🔥 Combo x" .. streakData.multiplier .. " (" .. streakData.comboCount .. " streak)")
    end)
end

-- Keyboard shortcut to open buff shop
UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    
    if input.KeyCode == Enum.KeyCode.B then
        if buffShopFrame.Visible then
            BuffController:CloseBuffShop()
        else
            BuffController:OpenBuffShop()
        end
    end
end)

-- Handle character respawn
player.CharacterAdded:Connect(function()
    wait(1)
    -- Clear active buffs on respawn
    for buffType, _ in pairs(activeBuffElements) do
        BuffController:RemoveBuffDisplay(buffType)
    end
    activeBuffElements = {}
end)

return BuffController
