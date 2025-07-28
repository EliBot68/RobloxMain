-- MysteryController.luau
-- Client-side controller for Mystery Crate system

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local SoundService = game:GetService("SoundService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local RemoteEvents = require(ReplicatedStorage.Shared.modules.RemoteEvents)
local GuiController = require(script.Parent.GuiController)

local MysteryController = {}
local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- UI References
local mysteryGui = nil
local currentMysteryData = nil

-- Sound effects
local openBoxSound = nil
local rareSound = nil
local epicSound = nil

function MysteryController:CreateMysteryUI()
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "MysteryGui"
    screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    screenGui.ResetOnSpawn = false
    screenGui.Parent = playerGui
    
    -- Background overlay
    local overlay = Instance.new("Frame")
    overlay.Name = "Overlay"
    overlay.Size = UDim2.new(1, 0, 1, 0)
    overlay.Position = UDim2.new(0, 0, 0, 0)
    overlay.BackgroundColor3 = Color3.new(0, 0, 0)
    overlay.BackgroundTransparency = 0.5
    overlay.BorderSizePixel = 0
    overlay.Visible = false
    overlay.Parent = screenGui
    
    -- Main mystery frame
    local mysteryFrame = Instance.new("Frame")
    mysteryFrame.Name = "MysteryFrame"
    mysteryFrame.Size = UDim2.new(0.6, 0, 0.7, 0)
    mysteryFrame.Position = UDim2.new(0.2, 0, 0.15, 0)
    mysteryFrame.BackgroundColor3 = Color3.new(0.1, 0.1, 0.15)
    mysteryFrame.BorderSizePixel = 3
    mysteryFrame.BorderColor3 = Color3.new(0.8, 0.2, 1)
    mysteryFrame.Parent = overlay
    
    -- Add corner rounding
    local cornerRounding = Instance.new("UICorner")
    cornerRounding.CornerRadius = UDim.new(0, 12)
    cornerRounding.Parent = mysteryFrame
    
    -- Title
    local titleLabel = Instance.new("TextLabel")
    titleLabel.Name = "Title"
    titleLabel.Size = UDim2.new(1, 0, 0.12, 0)
    titleLabel.BackgroundTransparency = 1
    titleLabel.Text = "🎲 MYSTERY CRATE SHOP 🎲"
    titleLabel.TextColor3 = Color3.new(1, 1, 0.2)
    titleLabel.TextScaled = true
    titleLabel.Font = Enum.Font.SourceSansBold
    titleLabel.TextStrokeTransparency = 0
    titleLabel.TextStrokeColor3 = Color3.new(0, 0, 0)
    titleLabel.Parent = mysteryFrame
    
    -- Coins display
    local coinsLabel = Instance.new("TextLabel")
    coinsLabel.Name = "CoinsLabel"
    coinsLabel.Size = UDim2.new(0.4, 0, 0.08, 0)
    coinsLabel.Position = UDim2.new(0.55, 0, 0.13, 0)
    coinsLabel.BackgroundTransparency = 1
    coinsLabel.Text = "💰 Coins: 0"
    coinsLabel.TextColor3 = Color3.new(1, 1, 0.2)
    coinsLabel.TextScaled = true
    coinsLabel.Font = Enum.Font.SourceSansBold
    coinsLabel.Parent = mysteryFrame
    
    -- Close button
    local closeButton = Instance.new("TextButton")
    closeButton.Name = "CloseButton"
    closeButton.Size = UDim2.new(0.08, 0, 0.08, 0)
    closeButton.Position = UDim2.new(0.9, 0, 0.02, 0)
    closeButton.BackgroundColor3 = Color3.new(0.8, 0.2, 0.2)
    closeButton.BorderSizePixel = 0
    closeButton.Text = "✕"
    closeButton.TextColor3 = Color3.new(1, 1, 1)
    closeButton.TextScaled = true
    closeButton.Font = Enum.Font.SourceSansBold
    closeButton.Parent = mysteryFrame
    
    local closeCorner = Instance.new("UICorner")
    closeCorner.CornerRadius = UDim.new(1, 0)
    closeCorner.Parent = closeButton
    
    closeButton.MouseButton1Click:Connect(function()
        self:CloseMysteryShop()
    end)
    
    -- Mystery box display
    local boxFrame = Instance.new("Frame")
    boxFrame.Name = "BoxFrame"
    boxFrame.Size = UDim2.new(0.45, 0, 0.6, 0)
    boxFrame.Position = UDim2.new(0.05, 0, 0.25, 0)
    boxFrame.BackgroundColor3 = Color3.new(0.05, 0.05, 0.1)
    boxFrame.BorderSizePixel = 2
    boxFrame.BorderColor3 = Color3.new(0.8, 0.2, 1)
    boxFrame.Parent = mysteryFrame
    
    local boxCorner = Instance.new("UICorner")
    boxCorner.CornerRadius = UDim.new(0, 8)
    boxCorner.Parent = boxFrame
    
    -- Mystery box icon
    local boxIcon = Instance.new("TextLabel")
    boxIcon.Name = "BoxIcon"
    boxIcon.Size = UDim2.new(1, 0, 0.6, 0)
    boxIcon.Position = UDim2.new(0, 0, 0.1, 0)
    boxIcon.BackgroundTransparency = 1
    boxIcon.Text = "📦"
    boxIcon.TextColor3 = Color3.new(0.8, 0.2, 1)
    boxIcon.TextScaled = true
    boxIcon.Font = Enum.Font.SourceSansBold
    boxIcon.Parent = boxFrame
    
    -- Box cost label
    local costLabel = Instance.new("TextLabel")
    costLabel.Name = "CostLabel"
    costLabel.Size = UDim2.new(1, 0, 0.2, 0)
    costLabel.Position = UDim2.new(0, 0, 0.7, 0)
    costLabel.BackgroundTransparency = 1
    costLabel.Text = "25 COINS"
    costLabel.TextColor3 = Color3.new(1, 1, 0.2)
    costLabel.TextScaled = true
    costLabel.Font = Enum.Font.SourceSansBold
    costLabel.Parent = boxFrame
    
    -- Open box button
    local openButton = Instance.new("TextButton")
    openButton.Name = "OpenButton"
    openButton.Size = UDim2.new(0.8, 0, 0.15, 0)
    openButton.Position = UDim2.new(0.1, 0, 0.88, 0)
    openButton.BackgroundColor3 = Color3.new(0.2, 0.8, 0.2)
    openButton.BorderSizePixel = 0
    openButton.Text = "OPEN MYSTERY BOX!"
    openButton.TextColor3 = Color3.new(1, 1, 1)
    openButton.TextScaled = true
    openButton.Font = Enum.Font.SourceSansBold
    openButton.Parent = mysteryFrame
    
    local buttonCorner = Instance.new("UICorner")
    buttonCorner.CornerRadius = UDim.new(0, 8)
    buttonCorner.Parent = openButton
    
    openButton.MouseButton1Click:Connect(function()
        self:PurchaseMysteryBox()
    end)
    
    -- Info panel
    local infoFrame = Instance.new("Frame")
    infoFrame.Name = "InfoFrame"
    infoFrame.Size = UDim2.new(0.45, 0, 0.6, 0)
    infoFrame.Position = UDim2.new(0.52, 0, 0.25, 0)
    infoFrame.BackgroundColor3 = Color3.new(0.05, 0.05, 0.1)
    infoFrame.BorderSizePixel = 2
    infoFrame.BorderColor3 = Color3.new(0.8, 0.2, 1)
    infoFrame.Parent = mysteryFrame
    
    local infoCorner = Instance.new("UICorner")
    infoCorner.CornerRadius = UDim.new(0, 8)
    infoCorner.Parent = infoFrame
    
    -- Info title
    local infoTitle = Instance.new("TextLabel")
    infoTitle.Name = "InfoTitle"
    infoTitle.Size = UDim2.new(1, 0, 0.15, 0)
    infoTitle.BackgroundTransparency = 1
    infoTitle.Text = "📊 STATISTICS & RATES"
    infoTitle.TextColor3 = Color3.new(1, 1, 1)
    infoTitle.TextScaled = true
    infoTitle.Font = Enum.Font.SourceSansBold
    infoTitle.Parent = infoFrame
    
    -- Statistics display
    local statsScroll = Instance.new("ScrollingFrame")
    statsScroll.Name = "StatsScroll"
    statsScroll.Size = UDim2.new(0.95, 0, 0.8, 0)
    statsScroll.Position = UDim2.new(0.025, 0, 0.18, 0)
    statsScroll.BackgroundTransparency = 1
    statsScroll.BorderSizePixel = 0
    statsScroll.ScrollBarThickness = 8
    statsScroll.CanvasSize = UDim2.new(0, 0, 0, 400)
    statsScroll.Parent = infoFrame
    
    return screenGui
end

function MysteryController:CreateResultPopup(reward, alreadyOwned, stats)
    local resultGui = Instance.new("ScreenGui")
    resultGui.Name = "MysteryResultGui"
    resultGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    resultGui.ResetOnSpawn = false
    resultGui.Parent = playerGui
    
    -- Background
    local overlay = Instance.new("Frame")
    overlay.Size = UDim2.new(1, 0, 1, 0)
    overlay.BackgroundColor3 = Color3.new(0, 0, 0)
    overlay.BackgroundTransparency = 0.3
    overlay.BorderSizePixel = 0
    overlay.Parent = resultGui
    
    -- Result frame
    local resultFrame = Instance.new("Frame")
    resultFrame.Name = "ResultFrame"
    resultFrame.Size = UDim2.new(0.5, 0, 0.6, 0)
    resultFrame.Position = UDim2.new(0.25, 0, 0.2, 0)
    resultFrame.BackgroundColor3 = Color3.new(0.1, 0.1, 0.15)
    resultFrame.BorderSizePixel = 3
    resultFrame.BorderColor3 = reward.rarity.color
    resultFrame.Parent = overlay
    
    local resultCorner = Instance.new("UICorner")
    resultCorner.CornerRadius = UDim.new(0, 15)
    resultCorner.Parent = resultFrame
    
    -- Rarity background glow
    local glowFrame = Instance.new("Frame")
    glowFrame.Size = UDim2.new(1.1, 0, 1.1, 0)
    glowFrame.Position = UDim2.new(-0.05, 0, -0.05, 0)
    glowFrame.BackgroundColor3 = reward.rarity.glowColor
    glowFrame.BackgroundTransparency = 0.8
    glowFrame.BorderSizePixel = 0
    glowFrame.ZIndex = resultFrame.ZIndex - 1
    glowFrame.Parent = resultFrame
    
    local glowCorner = Instance.new("UICorner")
    glowCorner.CornerRadius = UDim.new(0, 20)
    glowCorner.Parent = glowFrame
    
    -- Animate glow
    local glowTween = TweenService:Create(
        glowFrame,
        TweenInfo.new(1, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true),
        {BackgroundTransparency = 0.6}
    )
    glowTween:Play()
    
    -- Title
    local titleText = alreadyOwned and "DUPLICATE ITEM!" or "CONGRATULATIONS!"
    local titleLabel = Instance.new("TextLabel")
    titleLabel.Size = UDim2.new(1, 0, 0.15, 0)
    titleLabel.BackgroundTransparency = 1
    titleLabel.Text = titleText
    titleLabel.TextColor3 = alreadyOwned and Color3.new(1, 0.5, 0) or Color3.new(1, 1, 1)
    titleLabel.TextScaled = true
    titleLabel.Font = Enum.Font.SourceSansBold
    titleLabel.TextStrokeTransparency = 0
    titleLabel.TextStrokeColor3 = Color3.new(0, 0, 0)
    titleLabel.Parent = resultFrame
    
    -- Rarity display
    local rarityLabel = Instance.new("TextLabel")
    rarityLabel.Size = UDim2.new(1, 0, 0.12, 0)
    rarityLabel.Position = UDim2.new(0, 0, 0.15, 0)
    rarityLabel.BackgroundTransparency = 1
    rarityLabel.Text = reward.rarity.icon .. " " .. reward.rarity.name:upper() .. " " .. reward.rarity.icon
    rarityLabel.TextColor3 = reward.rarity.color
    rarityLabel.TextScaled = true
    rarityLabel.Font = Enum.Font.SourceSansBold
    rarityLabel.TextStrokeTransparency = 0
    rarityLabel.TextStrokeColor3 = Color3.new(0, 0, 0)
    rarityLabel.Parent = resultFrame
    
    -- Reward name
    local rewardLabel = Instance.new("TextLabel")
    rewardLabel.Size = UDim2.new(1, 0, 0.15, 0)
    rewardLabel.Position = UDim2.new(0, 0, 0.3, 0)
    rewardLabel.BackgroundTransparency = 1
    rewardLabel.Text = reward.name
    rewardLabel.TextColor3 = Color3.new(1, 1, 1)
    rewardLabel.TextScaled = true
    rewardLabel.Font = Enum.Font.SourceSansBold
    rewardLabel.Parent = resultFrame
    
    -- Reward preview
    local previewFrame = Instance.new("Frame")
    previewFrame.Size = UDim2.new(0.3, 0, 0.25, 0)
    previewFrame.Position = UDim2.new(0.35, 0, 0.48, 0)
    previewFrame.BackgroundColor3 = reward.color
    previewFrame.BorderSizePixel = 2
    previewFrame.BorderColor3 = Color3.new(1, 1, 1)
    previewFrame.Parent = resultFrame
    
    local previewCorner = Instance.new("UICorner")
    previewCorner.CornerRadius = UDim.new(0, 8)
    previewCorner.Parent = previewFrame
    
    -- Type indicator
    local typeLabel = Instance.new("TextLabel")
    typeLabel.Size = UDim2.new(1, 0, 0.08, 0)
    typeLabel.Position = UDim2.new(0, 0, 0.75, 0)
    typeLabel.BackgroundTransparency = 1
    typeLabel.Text = (reward.type == "skin" and "🎨 SKIN" or "🌟 TRAIL")
    typeLabel.TextColor3 = Color3.new(0.8, 0.8, 0.8)
    typeLabel.TextScaled = true
    typeLabel.Font = Enum.Font.SourceSans
    typeLabel.Parent = resultFrame
    
    -- Close button
    local closeButton = Instance.new("TextButton")
    closeButton.Size = UDim2.new(0.3, 0, 0.1, 0)
    closeButton.Position = UDim2.new(0.35, 0, 0.85, 0)
    closeButton.BackgroundColor3 = Color3.new(0.2, 0.6, 1)
    closeButton.BorderSizePixel = 0
    closeButton.Text = "AWESOME!"
    closeButton.TextColor3 = Color3.new(1, 1, 1)
    closeButton.TextScaled = true
    closeButton.Font = Enum.Font.SourceSansBold
    closeButton.Parent = resultFrame
    
    local closeCorner = Instance.new("UICorner")
    closeCorner.CornerRadius = UDim.new(0, 8)
    closeCorner.Parent = closeButton
    
    closeButton.MouseButton1Click:Connect(function()
        resultGui:Destroy()
    end)
    
    -- Animate in
    resultFrame.Size = UDim2.new(0, 0, 0, 0)
    resultFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
    
    local openTween = TweenService:Create(
        resultFrame,
        TweenInfo.new(0.5, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
        {
            Size = UDim2.new(0.5, 0, 0.6, 0),
            Position = UDim2.new(0.25, 0, 0.2, 0)
        }
    )
    openTween:Play()
    
    -- Auto close after 10 seconds
    game:GetService("Debris"):AddItem(resultGui, 10)
    
    return resultGui
end

function MysteryController:UpdateStatsDisplay()
    if not mysteryGui or not currentMysteryData then return end
    
    local statsScroll = mysteryGui.Overlay.MysteryFrame.InfoFrame.StatsScroll
    
    -- Clear existing stats
    for _, child in pairs(statsScroll:GetChildren()) do
        child:Destroy()
    end
    
    local yPos = 0
    local stats = currentMysteryData.stats
    
    -- Create stats labels
    local statsInfo = {
        {"📦 Total Opened:", tostring(stats.totalOpened)},
        {"💰 Coins Spent:", tostring(stats.coinsSpent)},
        {"", ""},
        {"🔘 Common Items:", tostring(stats.commonReceived) .. " (60% chance)"},
        {"💚 Rare Items:", tostring(stats.rareReceived) .. " (30% chance)"},
        {"💜 Epic Items:", tostring(stats.epicReceived) .. " (10% chance)"},
        {"", ""},
        {"Next Box In:", self:GetCooldownText()}
    }
    
    for i, info in pairs(statsInfo) do
        if info[1] ~= "" then
            local statLabel = Instance.new("TextLabel")
            statLabel.Name = "Stat" .. i
            statLabel.Size = UDim2.new(1, 0, 0, 25)
            statLabel.Position = UDim2.new(0, 0, 0, yPos)
            statLabel.BackgroundTransparency = 1
            statLabel.Text = info[1] .. " " .. info[2]
            statLabel.TextColor3 = Color3.new(1, 1, 1)
            statLabel.TextScaled = true
            statLabel.Font = Enum.Font.SourceSans
            statLabel.TextXAlignment = Enum.TextXAlignment.Left
            statLabel.Parent = statsScroll
            
            yPos = yPos + 30
        else
            yPos = yPos + 15
        end
    end
    
    statsScroll.CanvasSize = UDim2.new(0, 0, 0, yPos)
end

function MysteryController:GetCooldownText()
    if not currentMysteryData or currentMysteryData.cooldownRemaining <= 0 then
        return "Ready!"
    end
    
    return math.ceil(currentMysteryData.cooldownRemaining) .. " seconds"
end

function MysteryController:UpdateUI()
    if not mysteryGui or not currentMysteryData then return end
    
    local coinsLabel = mysteryGui.Overlay.MysteryFrame.CoinsLabel
    local openButton = mysteryGui.Overlay.MysteryFrame.OpenButton
    
    coinsLabel.Text = "💰 Coins: " .. currentMysteryData.playerCoins
    
    -- Update button state
    if currentMysteryData.cooldownRemaining > 0 then
        openButton.Text = "COOLDOWN: " .. math.ceil(currentMysteryData.cooldownRemaining) .. "s"
        openButton.BackgroundColor3 = Color3.new(0.5, 0.5, 0.5)
    elseif currentMysteryData.playerCoins < currentMysteryData.boxCost then
        openButton.Text = "NOT ENOUGH COINS"
        openButton.BackgroundColor3 = Color3.new(0.8, 0.2, 0.2)
    else
        openButton.Text = "OPEN MYSTERY BOX!"
        openButton.BackgroundColor3 = Color3.new(0.2, 0.8, 0.2)
    end
    
    self:UpdateStatsDisplay()
end

function MysteryController:OpenMysteryShop(mysteryData)
    currentMysteryData = mysteryData
    
    if not mysteryGui then
        mysteryGui = self:CreateMysteryUI()
    end
    
    self:UpdateUI()
    
    -- Show with animation
    local overlay = mysteryGui.Overlay
    overlay.Visible = true
    overlay.BackgroundTransparency = 1
    
    local mysteryFrame = overlay.MysteryFrame
    mysteryFrame.Size = UDim2.new(0, 0, 0, 0)
    mysteryFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
    
    local bgTween = TweenService:Create(
        overlay,
        TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
        {BackgroundTransparency = 0.5}
    )
    
    local frameTween = TweenService:Create(
        mysteryFrame,
        TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
        {
            Size = UDim2.new(0.6, 0, 0.7, 0),
            Position = UDim2.new(0.2, 0, 0.15, 0)
        }
    )
    
    bgTween:Play()
    frameTween:Play()
    
    -- Start cooldown countdown
    self:StartCooldownCounter()
end

function MysteryController:CloseMysteryShop()
    if not mysteryGui then return end
    
    local overlay = mysteryGui.Overlay
    local mysteryFrame = overlay.MysteryFrame
    
    local bgTween = TweenService:Create(
        overlay,
        TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
        {BackgroundTransparency = 1}
    )
    
    local frameTween = TweenService:Create(
        mysteryFrame,
        TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.In),
        {
            Size = UDim2.new(0, 0, 0, 0),
            Position = UDim2.new(0.5, 0, 0.5, 0)
        }
    )
    
    frameTween.Completed:Connect(function()
        overlay.Visible = false
    end)
    
    bgTween:Play()
    frameTween:Play()
end

function MysteryController:StartCooldownCounter()
    spawn(function()
        while mysteryGui and mysteryGui.Overlay.Visible and currentMysteryData do
            if currentMysteryData.cooldownRemaining > 0 then
                currentMysteryData.cooldownRemaining = currentMysteryData.cooldownRemaining - 1
                self:UpdateUI()
                wait(1)
            else
                break
            end
        end
    end)
end

function MysteryController:PurchaseMysteryBox()
    if not currentMysteryData then return end
    
    if currentMysteryData.cooldownRemaining > 0 then
        GuiController:ShowNotification("⏰ Please wait " .. math.ceil(currentMysteryData.cooldownRemaining) .. " seconds!", Color3.new(1, 0.5, 0))
        return
    end
    
    if currentMysteryData.playerCoins < currentMysteryData.boxCost then
        GuiController:ShowNotification("💰 Not enough coins! You need " .. currentMysteryData.boxCost .. " coins.", Color3.new(1, 0, 0))
        return
    end
    
    -- Animate box opening
    local boxIcon = mysteryGui.Overlay.MysteryFrame.BoxFrame.BoxIcon
    
    local shakeTween = TweenService:Create(
        boxIcon,
        TweenInfo.new(0.1, Enum.EasingStyle.Linear, Enum.EasingDirection.InOut, 5, true),
        {Rotation = 5}
    )
    shakeTween:Play()
    
    -- Play sound effect
    if openBoxSound then
        openBoxSound:Play()
    end
    
    -- Send purchase request
    RemoteEvents.PurchaseMysteryBox:FireServer()
end

function MysteryController:HandleMysteryBoxResult(result)
    if result.specialAnnouncement then
        -- Show server-wide announcement
        GuiController:ShowNotification(result.message, result.rarity.color, 5)
        return
    end
    
    if not result.success then
        GuiController:ShowNotification("❌ " .. result.error, Color3.new(1, 0, 0))
        return
    end
    
    -- Update current data
    currentMysteryData.playerCoins = result.newCoinTotal
    currentMysteryData.stats = result.stats
    currentMysteryData.cooldownRemaining = 5 -- Reset cooldown
    
    -- Show result popup
    self:CreateResultPopup(result.reward, result.alreadyOwned, result.stats)
    
    -- Play rarity-appropriate sound
    if result.reward.rarity.name == "Epic" and epicSound then
        epicSound:Play()
    elseif result.reward.rarity.name == "Rare" and rareSound then
        rareSound:Play()
    end
    
    -- Update UI
    self:UpdateUI()
    
    -- Show notification
    local message = result.alreadyOwned and 
        "📦 Got duplicate " .. result.reward.name .. "!" or
        "🎉 Got " .. result.reward.rarity.name .. " " .. result.reward.name .. "!"
    
    GuiController:ShowNotification(message, result.reward.rarity.color)
end

function MysteryController:LoadSounds()
    -- Create sound effects (you can replace these with actual sound IDs)
    openBoxSound = Instance.new("Sound")
    openBoxSound.SoundId = "rbxasset://sounds/electronicpingshort.wav"
    openBoxSound.Volume = 0.5
    openBoxSound.Parent = SoundService
    
    rareSound = Instance.new("Sound")
    rareSound.SoundId = "rbxasset://sounds/bell.wav"
    rareSound.Volume = 0.7
    rareSound.Parent = SoundService
    
    epicSound = Instance.new("Sound")
    epicSound.SoundId = "rbxasset://sounds/victory.wav"
    epicSound.Volume = 0.8
    epicSound.Parent = SoundService
end

function MysteryController:Init()
    self:LoadSounds()
    
    -- Handle remote events
    RemoteEvents.OpenMysteryShop.OnClientEvent:Connect(function(mysteryData)
        self:OpenMysteryShop(mysteryData)
    end)
    
    RemoteEvents.MysteryBoxResult.OnClientEvent:Connect(function(result)
        self:HandleMysteryBoxResult(result)
    end)
    
    print("✅ MysteryController initialized")
end

return MysteryController
