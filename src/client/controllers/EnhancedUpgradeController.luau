-- EnhancedUpgradeController.luau
-- Manages upgrade stall UI with Speed Boost, Coin Bonus, and XP Boost upgrades

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SoundService = game:GetService("SoundService")

local RemoteEvents = require(ReplicatedStorage.Shared.modules.RemoteEvents)

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local EnhancedUpgradeController = {}

-- GUI state
local upgradeGui = nil
local currentUpgrades = {}
local isOpen = false

-- Sound effects
local upgradeSuccessSound = nil
local buttonHoverSound = nil

-- Upgrade definitions
local UPGRADE_DEFINITIONS = {
    speed_boost = {
        name = "Speed Boost",
        description = "Increase movement speed during runs",
        icon = "🏃",
        baseCost = 100,
        maxLevel = 10,
        costMultiplier = 1.5,
        bonusPerLevel = 0.1, -- 10% speed increase per level
        color = Color3.fromRGB(0, 162, 255)
    },
    coin_bonus = {
        name = "Coin Bonus",
        description = "Earn more coins from runs and activities",
        icon = "💰",
        baseCost = 150,
        maxLevel = 10,
        costMultiplier = 1.6,
        bonusPerLevel = 0.15, -- 15% coin bonus per level
        color = Color3.fromRGB(255, 215, 0)
    },
    xp_boost = {
        name = "XP Boost", 
        description = "Gain more experience from all activities",
        icon = "⭐",
        baseCost = 200,
        maxLevel = 10,
        costMultiplier = 1.7,
        bonusPerLevel = 0.2, -- 20% XP bonus per level
        color = Color3.fromRGB(138, 43, 226)
    }
}

function EnhancedUpgradeController:Init()
    self:LoadSounds()
    self:SetupRemoteEvents()
    print("⬆️ EnhancedUpgradeController initialized")
end

function EnhancedUpgradeController:LoadSounds()
    -- Upgrade success sound
    upgradeSuccessSound = Instance.new("Sound")
    upgradeSuccessSound.SoundId = "rbxasset://sounds/electronicpingshort.wav"
    upgradeSuccessSound.Volume = 0.7
    upgradeSuccessSound.Pitch = 1.3
    upgradeSuccessSound.Parent = SoundService
    
    -- Button hover sound
    buttonHoverSound = Instance.new("Sound")
    buttonHoverSound.SoundId = "rbxasset://sounds/impact_water.mp3"
    buttonHoverSound.Volume = 0.2
    buttonHoverSound.Pitch = 2.0
    buttonHoverSound.Parent = SoundService
end

function EnhancedUpgradeController:SetupRemoteEvents()
    -- Handle upgrade stall interactions
    RemoteEvents.ShowUpgradeShop.OnClientEvent:Connect(function(playerUpgrades)
        self:OpenUpgradeShop(playerUpgrades)
    end)
    
    -- Handle upgrade purchase results
    RemoteEvents.UpgradePurchaseResult.OnClientEvent:Connect(function(success, upgradeType, newLevel, message)
        self:HandleUpgradeResult(success, upgradeType, newLevel, message)
    end)
    
    -- Handle upgrade data updates
    RemoteEvents.UpgradeDataUpdated.OnClientEvent:Connect(function(playerUpgrades)
        currentUpgrades = playerUpgrades
        if isOpen then
            self:RefreshUpgradeDisplay()
        end
    end)
end

function EnhancedUpgradeController:OpenUpgradeShop(playerUpgrades)
    if isOpen then
        self:CloseUpgradeShop()
        return
    end
    
    currentUpgrades = playerUpgrades or {}
    isOpen = true
    
    self:CreateUpgradeShopGui()
end

function EnhancedUpgradeController:CreateUpgradeShopGui()
    -- Remove existing GUI
    local existingGui = playerGui:FindFirstChild("EnhancedUpgradeGui")
    if existingGui then
        existingGui:Destroy()
    end
    
    -- Create main GUI
    upgradeGui = Instance.new("ScreenGui")
    upgradeGui.Name = "EnhancedUpgradeGui"
    upgradeGui.Parent = playerGui
    
    -- Background overlay
    local overlay = Instance.new("Frame")
    overlay.Name = "Overlay"
    overlay.Size = UDim2.new(1, 0, 1, 0)
    overlay.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    overlay.BackgroundTransparency = 0.6
    overlay.BorderSizePixel = 0
    overlay.Parent = upgradeGui
    
    -- Main upgrade frame
    local upgradeFrame = Instance.new("Frame")
    upgradeFrame.Name = "UpgradeFrame"
    upgradeFrame.Size = UDim2.new(0, 600, 0, 500)
    upgradeFrame.Position = UDim2.new(0.5, -300, 0.5, -250)
    upgradeFrame.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
    upgradeFrame.BorderSizePixel = 0
    upgradeFrame.Parent = overlay
    
    local frameCorner = Instance.new("UICorner")
    frameCorner.CornerRadius = UDim.new(0, 15)
    frameCorner.Parent = upgradeFrame
    
    local frameBorder = Instance.new("UIStroke")
    frameBorder.Color = Color3.fromRGB(100, 100, 100)
    frameBorder.Thickness = 2
    frameBorder.Parent = upgradeFrame
    
    -- Title
    local titleLabel = Instance.new("TextLabel")
    titleLabel.Name = "Title"
    titleLabel.Size = UDim2.new(1, -20, 0, 60)
    titleLabel.Position = UDim2.new(0, 10, 0, 10)
    titleLabel.BackgroundTransparency = 1
    titleLabel.Text = "⬆️ UPGRADE STALL ⬆️"
    titleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    titleLabel.TextScaled = true
    titleLabel.Font = Enum.Font.GothamBold
    titleLabel.Parent = upgradeFrame
    
    -- Close button
    local closeButton = Instance.new("TextButton")
    closeButton.Name = "CloseButton"
    closeButton.Size = UDim2.new(0, 40, 0, 40)
    closeButton.Position = UDim2.new(1, -50, 0, 10)
    closeButton.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
    closeButton.BorderSizePixel = 0
    closeButton.Text = "✕"
    closeButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    closeButton.TextScaled = true
    closeButton.Font = Enum.Font.GothamBold
    closeButton.Parent = upgradeFrame
    
    local closeCorner = Instance.new("UICorner")
    closeCorner.CornerRadius = UDim.new(0, 8)
    closeCorner.Parent = closeButton
    
    closeButton.MouseButton1Click:Connect(function()
        self:CloseUpgradeShop()
    end)
    
    -- Upgrades container
    local upgradesContainer = Instance.new("Frame")
    upgradesContainer.Name = "UpgradesContainer"
    upgradesContainer.Size = UDim2.new(1, -20, 0, 400)
    upgradesContainer.Position = UDim2.new(0, 10, 0, 80)
    upgradesContainer.BackgroundTransparency = 1
    upgradesContainer.Parent = upgradeFrame
    
    -- Create upgrade cards
    local upgradeOrder = {"speed_boost", "coin_bonus", "xp_boost"}
    
    for i, upgradeType in ipairs(upgradeOrder) do
        self:CreateUpgradeCard(upgradesContainer, upgradeType, i)
    end
    
    -- Animate in
    upgradeFrame.Size = UDim2.new(0, 0, 0, 0)
    local animateIn = TweenService:Create(
        upgradeFrame,
        TweenInfo.new(0.5, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
        {Size = UDim2.new(0, 600, 0, 500)}
    )
    animateIn:Play()
end

function EnhancedUpgradeController:CreateUpgradeCard(parent, upgradeType, index)
    local upgrade = UPGRADE_DEFINITIONS[upgradeType]
    if not upgrade then return end
    
    local currentLevel = currentUpgrades[upgradeType] or 0
    local nextLevel = currentLevel + 1
    local cost = self:CalculateUpgradeCost(upgradeType, nextLevel)
    local isMaxLevel = currentLevel >= upgrade.maxLevel
    
    -- Card frame
    local cardFrame = Instance.new("Frame")
    cardFrame.Name = upgradeType .. "Card"
    cardFrame.Size = UDim2.new(1, 0, 0, 120)
    cardFrame.Position = UDim2.new(0, 0, 0, (index - 1) * 130)
    cardFrame.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
    cardFrame.BorderSizePixel = 0
    cardFrame.Parent = parent
    
    local cardCorner = Instance.new("UICorner")
    cardCorner.CornerRadius = UDim.new(0, 10)
    cardCorner.Parent = cardFrame
    
    local cardBorder = Instance.new("UIStroke")
    cardBorder.Color = upgrade.color
    cardBorder.Thickness = 2
    cardBorder.Parent = cardFrame
    
    -- Icon
    local iconLabel = Instance.new("TextLabel")
    iconLabel.Name = "Icon"
    iconLabel.Size = UDim2.new(0, 80, 0, 80)
    iconLabel.Position = UDim2.new(0, 10, 0, 20)
    iconLabel.BackgroundTransparency = 1
    iconLabel.Text = upgrade.icon
    iconLabel.TextScaled = true
    iconLabel.Font = Enum.Font.SourceSansBold
    iconLabel.Parent = cardFrame
    
    -- Info section
    local infoFrame = Instance.new("Frame")
    infoFrame.Name = "InfoFrame"
    infoFrame.Size = UDim2.new(0, 300, 0, 100)
    infoFrame.Position = UDim2.new(0, 100, 0, 10)
    infoFrame.BackgroundTransparency = 1
    infoFrame.Parent = cardFrame
    
    -- Name
    local nameLabel = Instance.new("TextLabel")
    nameLabel.Name = "NameLabel"
    nameLabel.Size = UDim2.new(1, 0, 0, 30)
    nameLabel.Position = UDim2.new(0, 0, 0, 0)
    nameLabel.BackgroundTransparency = 1
    nameLabel.Text = upgrade.name
    nameLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    nameLabel.TextScaled = true
    nameLabel.Font = Enum.Font.GothamBold
    nameLabel.TextXAlignment = Enum.TextXAlignment.Left
    nameLabel.Parent = infoFrame
    
    -- Description
    local descLabel = Instance.new("TextLabel")
    descLabel.Name = "DescLabel"
    descLabel.Size = UDim2.new(1, 0, 0, 40)
    descLabel.Position = UDim2.new(0, 0, 0, 35)
    descLabel.BackgroundTransparency = 1
    descLabel.Text = upgrade.description
    descLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
    descLabel.TextScaled = true
    descLabel.Font = Enum.Font.Gotham
    descLabel.TextXAlignment = Enum.TextXAlignment.Left
    descLabel.TextWrapped = true
    descLabel.Parent = infoFrame
    
    -- Level display
    local levelLabel = Instance.new("TextLabel")
    levelLabel.Name = "LevelLabel"
    levelLabel.Size = UDim2.new(1, 0, 0, 25)
    levelLabel.Position = UDim2.new(0, 0, 0, 75)
    levelLabel.BackgroundTransparency = 1
    levelLabel.Text = "Level: " .. currentLevel .. " / " .. upgrade.maxLevel
    levelLabel.TextColor3 = upgrade.color
    levelLabel.TextScaled = true
    levelLabel.Font = Enum.Font.GothamBold
    levelLabel.TextXAlignment = Enum.TextXAlignment.Left
    levelLabel.Parent = infoFrame
    
    -- Purchase button
    local purchaseButton = Instance.new("TextButton")
    purchaseButton.Name = "PurchaseButton"
    purchaseButton.Size = UDim2.new(0, 160, 0, 60)
    purchaseButton.Position = UDim2.new(0, 420, 0, 30)
    purchaseButton.BorderSizePixel = 0
    purchaseButton.TextScaled = true
    purchaseButton.Font = Enum.Font.GothamBold
    purchaseButton.Parent = cardFrame
    
    local buttonCorner = Instance.new("UICorner")
    buttonCorner.CornerRadius = UDim.new(0, 8)
    buttonCorner.Parent = purchaseButton
    
    if isMaxLevel then
        purchaseButton.BackgroundColor3 = Color3.fromRGB(100, 100, 100)
        purchaseButton.Text = "MAX LEVEL"
        purchaseButton.TextColor3 = Color3.fromRGB(200, 200, 200)
        purchaseButton.Active = false
    else
        purchaseButton.BackgroundColor3 = upgrade.color
        purchaseButton.Text = "UPGRADE\n💰 " .. cost .. " Coins"
        purchaseButton.TextColor3 = Color3.fromRGB(255, 255, 255)
        purchaseButton.Active = true
        
        -- Button interactions
        purchaseButton.MouseEnter:Connect(function()
            if buttonHoverSound then buttonHoverSound:Play() end
            local hoverTween = TweenService:Create(
                purchaseButton,
                TweenInfo.new(0.2, Enum.EasingStyle.Quad),
                {BackgroundColor3 = Color3.new(
                    math.min(upgrade.color.R + 0.2, 1),
                    math.min(upgrade.color.G + 0.2, 1),
                    math.min(upgrade.color.B + 0.2, 1)
                )}
            )
            hoverTween:Play()
        end)
        
        purchaseButton.MouseLeave:Connect(function()
            local normalTween = TweenService:Create(
                purchaseButton,
                TweenInfo.new(0.2, Enum.EasingStyle.Quad),
                {BackgroundColor3 = upgrade.color}
            )
            normalTween:Play()
        end)
        
        purchaseButton.MouseButton1Click:Connect(function()
            self:PurchaseUpgrade(upgradeType)
        end)
    end
end

function EnhancedUpgradeController:CalculateUpgradeCost(upgradeType, level)
    local upgrade = UPGRADE_DEFINITIONS[upgradeType]
    if not upgrade then return 0 end
    
    return math.floor(upgrade.baseCost * (upgrade.costMultiplier ^ (level - 1)))
end

function EnhancedUpgradeController:PurchaseUpgrade(upgradeType)
    -- Send purchase request with confirmation
    local upgrade = UPGRADE_DEFINITIONS[upgradeType]
    local currentLevel = currentUpgrades[upgradeType] or 0
    local nextLevel = currentLevel + 1
    local cost = self:CalculateUpgradeCost(upgradeType, nextLevel)
    
    local purchaseData = {
        itemType = "upgrade",
        itemId = upgradeType,
        upgradeType = upgradeType,
        name = upgrade.name,
        description = "Upgrade to Level " .. nextLevel,
        price = cost,
        icon = upgrade.icon,
        maxLevel = upgrade.maxLevel,
        currentLevel = currentLevel
    }
    
    RemoteEvents.ShowPurchaseConfirmation:FireServer(purchaseData)
end

function EnhancedUpgradeController:HandleUpgradeResult(success, upgradeType, newLevel, message)
    if success and upgradeSuccessSound then
        upgradeSuccessSound:Play()
        
        -- Update local data
        currentUpgrades[upgradeType] = newLevel
        
        -- Refresh display
        if isOpen then
            self:RefreshUpgradeDisplay()
        end
        
        -- Show success notification
        self:ShowUpgradeSuccessNotification(upgradeType, newLevel)
    end
end

function EnhancedUpgradeController:ShowUpgradeSuccessNotification(upgradeType, newLevel)
    local upgrade = UPGRADE_DEFINITIONS[upgradeType]
    if not upgrade then return end
    
    -- Create success notification
    local notification = Instance.new("Frame")
    notification.Name = "UpgradeSuccess"
    notification.Size = UDim2.new(0, 300, 0, 80)
    notification.Position = UDim2.new(0.5, -150, 0, 100)
    notification.BackgroundColor3 = upgrade.color
    notification.BorderSizePixel = 0
    notification.Parent = upgradeGui
    
    local notifCorner = Instance.new("UICorner")
    notifCorner.CornerRadius = UDim.new(0, 10)
    notifCorner.Parent = notification
    
    local successText = Instance.new("TextLabel")
    successText.Size = UDim2.new(1, -20, 1, 0)
    successText.Position = UDim2.new(0, 10, 0, 0)
    successText.BackgroundTransparency = 1
    successText.Text = upgrade.icon .. " " .. upgrade.name .. " upgraded to Level " .. newLevel .. "!"
    successText.TextColor3 = Color3.fromRGB(255, 255, 255)
    successText.TextScaled = true
    successText.Font = Enum.Font.GothamBold
    successText.TextWrapped = true
    successText.Parent = notification
    
    -- Animate notification
    notification.Position = UDim2.new(0.5, -150, 0, -100)
    local slideIn = TweenService:Create(
        notification,
        TweenInfo.new(0.5, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
        {Position = UDim2.new(0.5, -150, 0, 100)}
    )
    slideIn:Play()
    
    -- Auto-remove
    spawn(function()
        wait(3)
        local slideOut = TweenService:Create(
            notification,
            TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
            {Position = UDim2.new(0.5, -150, 0, -100)}
        )
        slideOut:Play()
        slideOut.Completed:Connect(function()
            notification:Destroy()
        end)
    end)
end

function EnhancedUpgradeController:RefreshUpgradeDisplay()
    if not upgradeGui then return end
    
    local container = upgradeGui.Overlay.UpgradeFrame.UpgradesContainer
    
    -- Update each upgrade card
    for upgradeType, upgrade in pairs(UPGRADE_DEFINITIONS) do
        local card = container:FindFirstChild(upgradeType .. "Card")
        if card then
            local currentLevel = currentUpgrades[upgradeType] or 0
            local nextLevel = currentLevel + 1
            local cost = self:CalculateUpgradeCost(upgradeType, nextLevel)
            local isMaxLevel = currentLevel >= upgrade.maxLevel
            
            -- Update level display
            local levelLabel = card.InfoFrame.LevelLabel
            levelLabel.Text = "Level: " .. currentLevel .. " / " .. upgrade.maxLevel
            
            -- Update purchase button
            local purchaseButton = card.PurchaseButton
            if isMaxLevel then
                purchaseButton.BackgroundColor3 = Color3.fromRGB(100, 100, 100)
                purchaseButton.Text = "MAX LEVEL"
                purchaseButton.TextColor3 = Color3.fromRGB(200, 200, 200)
                purchaseButton.Active = false
            else
                purchaseButton.BackgroundColor3 = upgrade.color
                purchaseButton.Text = "UPGRADE\n💰 " .. cost .. " Coins"
                purchaseButton.TextColor3 = Color3.fromRGB(255, 255, 255)
                purchaseButton.Active = true
            end
        end
    end
end

function EnhancedUpgradeController:CloseUpgradeShop()
    if not upgradeGui then return end
    
    local upgradeFrame = upgradeGui.Overlay.UpgradeFrame
    
    local animateOut = TweenService:Create(
        upgradeFrame,
        TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.In),
        {Size = UDim2.new(0, 0, 0, 0)}
    )
    
    animateOut:Play()
    animateOut.Completed:Connect(function()
        upgradeGui:Destroy()
        upgradeGui = nil
        isOpen = false
    end)
end

function EnhancedUpgradeController:GetUpgradeDefinitions()
    return UPGRADE_DEFINITIONS
end

function EnhancedUpgradeController:Cleanup()
    if upgradeGui then
        upgradeGui:Destroy()
        upgradeGui = nil
    end
    isOpen = false
    currentUpgrades = {}
end

return EnhancedUpgradeController
