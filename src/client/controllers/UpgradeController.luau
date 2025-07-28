-- UpgradeController.luau
-- Handles client-side upgrade shop interface

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local GuiService = game:GetService("GuiService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local RemoteEvents = require(ReplicatedStorage.Shared.modules.RemoteEvents)

local UpgradeController = {}

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- UI Variables
local upgradeGui = nil
local upgradeFrame = nil
local upgradeList = nil
local currentUpgrades = {}
local availableUpgrades = {}

-- UI Colors
local COLORS = {
    background = Color3.new(0.1, 0.1, 0.15),
    panel = Color3.new(0.15, 0.15, 0.2),
    accent = Color3.new(1, 0.8, 0.2),
    text = Color3.new(0.9, 0.9, 0.9),
    success = Color3.new(0.2, 0.8, 0.2),
    error = Color3.new(0.8, 0.2, 0.2),
    disabled = Color3.new(0.5, 0.5, 0.5)
}

function UpgradeController:CreateUpgradeGUI()
    -- Main GUI
    upgradeGui = Instance.new("ScreenGui")
    upgradeGui.Name = "UpgradeShop"
    upgradeGui.ResetOnSpawn = false
    upgradeGui.Parent = playerGui
    
    -- Background
    local background = Instance.new("Frame")
    background.Name = "Background"
    background.Size = UDim2.new(1, 0, 1, 0)
    background.Position = UDim2.new(0, 0, 0, 0)
    background.BackgroundColor3 = Color3.new(0, 0, 0)
    background.BackgroundTransparency = 0.3
    background.BorderSizePixel = 0
    background.Parent = upgradeGui
    
    -- Main Frame
    upgradeFrame = Instance.new("Frame")
    upgradeFrame.Name = "UpgradeFrame"
    upgradeFrame.Size = UDim2.new(0, 800, 0, 600)
    upgradeFrame.Position = UDim2.new(0.5, -400, 0.5, -300)
    upgradeFrame.BackgroundColor3 = COLORS.background
    upgradeFrame.BorderSizePixel = 0
    upgradeFrame.Parent = background
    
    -- Round corners
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 12)
    corner.Parent = upgradeFrame
    
    -- Header
    local header = Instance.new("Frame")
    header.Name = "Header"
    header.Size = UDim2.new(1, 0, 0, 80)
    header.Position = UDim2.new(0, 0, 0, 0)
    header.BackgroundColor3 = COLORS.accent
    header.BorderSizePixel = 0
    header.Parent = upgradeFrame
    
    local headerCorner = Instance.new("UICorner")
    headerCorner.CornerRadius = UDim.new(0, 12)
    headerCorner.Parent = header
    
    -- Fix corner overlap
    local headerFix = Instance.new("Frame")
    headerFix.Size = UDim2.new(1, 0, 0, 12)
    headerFix.Position = UDim2.new(0, 0, 1, -12)
    headerFix.BackgroundColor3 = COLORS.accent
    headerFix.BorderSizePixel = 0
    headerFix.Parent = header
    
    -- Title
    local title = Instance.new("TextLabel")
    title.Name = "Title"
    title.Size = UDim2.new(1, -100, 1, 0)
    title.Position = UDim2.new(0, 20, 0, 0)
    title.BackgroundTransparency = 1
    title.Text = "⚡ UPGRADE SHOP"
    title.TextColor3 = Color3.new(0, 0, 0)
    title.TextScaled = true
    title.Font = Enum.Font.SourceSansBold
    title.Parent = header
    
    -- Close Button
    local closeButton = Instance.new("TextButton")
    closeButton.Name = "CloseButton"
    closeButton.Size = UDim2.new(0, 60, 0, 60)
    closeButton.Position = UDim2.new(1, -70, 0, 10)
    closeButton.BackgroundColor3 = Color3.new(0.8, 0.2, 0.2)
    closeButton.Text = "✕"
    closeButton.TextColor3 = Color3.new(1, 1, 1)
    closeButton.TextScaled = true
    closeButton.Font = Enum.Font.SourceSansBold
    closeButton.BorderSizePixel = 0
    closeButton.Parent = header
    
    local closeCorner = Instance.new("UICorner")
    closeCorner.CornerRadius = UDim.new(0, 8)
    closeCorner.Parent = closeButton
    
    closeButton.MouseButton1Click:Connect(function()
        self:HideUpgradeShop()
    end)
    
    -- Content Area
    local contentFrame = Instance.new("Frame")
    contentFrame.Name = "Content"
    contentFrame.Size = UDim2.new(1, -40, 1, -120)
    contentFrame.Position = UDim2.new(0, 20, 0, 100)
    contentFrame.BackgroundTransparency = 1
    contentFrame.Parent = upgradeFrame
    
    -- Scroll Frame for upgrades
    upgradeList = Instance.new("ScrollingFrame")
    upgradeList.Name = "UpgradeList"
    upgradeList.Size = UDim2.new(1, 0, 1, 0)
    upgradeList.Position = UDim2.new(0, 0, 0, 0)
    upgradeList.BackgroundTransparency = 1
    upgradeList.BorderSizePixel = 0
    upgradeList.ScrollBarThickness = 8
    upgradeList.ScrollBarImageColor3 = COLORS.accent
    upgradeList.Parent = contentFrame
    
    -- List Layout
    local listLayout = Instance.new("UIListLayout")
    listLayout.SortOrder = Enum.SortOrder.LayoutOrder
    listLayout.Padding = UDim.new(0, 10)
    listLayout.Parent = upgradeList
    
    -- Close when clicking background
    background.MouseButton1Click:Connect(function()
        self:HideUpgradeShop()
    end)
    
    -- Prevent closing when clicking the main frame
    upgradeFrame.MouseButton1Click:Connect(function()
        -- Do nothing (prevent event from reaching background)
    end)
    
    upgradeGui.Enabled = false
end

function UpgradeController:CreateUpgradeEntry(upgrade)
    local currentLevel = currentUpgrades[upgrade.id] or 0
    local isMaxLevel = currentLevel >= upgrade.maxLevel
    local nextCost = isMaxLevel and 0 or math.floor(upgrade.baseCost * (upgrade.costMultiplier ^ currentLevel))
    
    -- Main entry frame
    local entry = Instance.new("Frame")
    entry.Name = upgrade.id
    entry.Size = UDim2.new(1, -20, 0, 120)
    entry.BackgroundColor3 = COLORS.panel
    entry.BorderSizePixel = 0
    entry.Parent = upgradeList
    
    local entryCorner = Instance.new("UICorner")
    entryCorner.CornerRadius = UDim.new(0, 8)
    entryCorner.Parent = entry
    
    -- Icon
    local icon = Instance.new("TextLabel")
    icon.Name = "Icon"
    icon.Size = UDim2.new(0, 60, 0, 60)
    icon.Position = UDim2.new(0, 15, 0, 15)
    icon.BackgroundTransparency = 1
    icon.Text = upgrade.icon
    icon.TextColor3 = COLORS.accent
    icon.TextScaled = true
    icon.Font = Enum.Font.SourceSans
    icon.Parent = entry
    
    -- Name
    local nameLabel = Instance.new("TextLabel")
    nameLabel.Name = "NameLabel"
    nameLabel.Size = UDim2.new(0, 300, 0, 25)
    nameLabel.Position = UDim2.new(0, 90, 0, 10)
    nameLabel.BackgroundTransparency = 1
    nameLabel.Text = upgrade.name
    nameLabel.TextColor3 = COLORS.text
    nameLabel.TextXAlignment = Enum.TextXAlignment.Left
    nameLabel.TextScaled = true
    nameLabel.Font = Enum.Font.SourceSansBold
    nameLabel.Parent = entry
    
    -- Description
    local description = Instance.new("TextLabel")
    description.Name = "Description"
    description.Size = UDim2.new(0, 300, 0, 20)
    description.Position = UDim2.new(0, 90, 0, 35)
    description.BackgroundTransparency = 1
    description.Text = upgrade.description
    description.TextColor3 = Color3.new(0.7, 0.7, 0.7)
    description.TextXAlignment = Enum.TextXAlignment.Left
    description.TextScaled = true
    description.Font = Enum.Font.SourceSans
    description.Parent = entry
    
    -- Level indicator
    local levelLabel = Instance.new("TextLabel")
    levelLabel.Name = "LevelLabel"
    levelLabel.Size = UDim2.new(0, 200, 0, 20)
    levelLabel.Position = UDim2.new(0, 90, 0, 60)
    levelLabel.BackgroundTransparency = 1
    levelLabel.Text = "Level: " .. currentLevel .. "/" .. upgrade.maxLevel
    levelLabel.TextColor3 = isMaxLevel and COLORS.success or COLORS.text
    levelLabel.TextXAlignment = Enum.TextXAlignment.Left
    levelLabel.TextScaled = true
    levelLabel.Font = Enum.Font.SourceSans
    levelLabel.Parent = entry
    
    -- Effect display
    local effectValue = upgrade.baseEffect * currentLevel
    local effectText = ""
    
    if upgrade.effectType == "speed_multiplier" or upgrade.effectType == "score_multiplier" then
        effectText = "+" .. math.floor(effectValue * 100) .. "%"
    elseif upgrade.effectType == "bonus_coins" then
        effectText = "+" .. effectValue .. " coins"
    elseif upgrade.effectType == "penalty_reduction" then
        effectText = "-" .. math.floor(effectValue * 100) .. "% penalty"
    elseif upgrade.effectType == "time_slowdown" then
        effectText = "+" .. math.floor(effectValue * 100) .. "% time"
    elseif upgrade.effectType == "ghost_victory_bonus" then
        effectText = "+" .. effectValue .. " coins/victory"
    else
        effectText = "Level " .. currentLevel
    end
    
    local effectLabel = Instance.new("TextLabel")
    effectLabel.Name = "EffectLabel"
    effectLabel.Size = UDim2.new(0, 200, 0, 20)
    effectLabel.Position = UDim2.new(0, 90, 0, 85)
    effectLabel.BackgroundTransparency = 1
    effectLabel.Text = "Current: " .. effectText
    effectLabel.TextColor3 = COLORS.success
    effectLabel.TextXAlignment = Enum.TextXAlignment.Left
    effectLabel.TextScaled = true
    effectLabel.Font = Enum.Font.SourceSansBold
    effectLabel.Parent = entry
    
    -- Purchase button
    local purchaseButton = Instance.new("TextButton")
    purchaseButton.Name = "PurchaseButton"
    purchaseButton.Size = UDim2.new(0, 150, 0, 40)
    purchaseButton.Position = UDim2.new(1, -170, 0, 40)
    purchaseButton.BorderSizePixel = 0
    purchaseButton.Font = Enum.Font.SourceSansBold
    purchaseButton.TextScaled = true
    purchaseButton.Parent = entry
    
    local buttonCorner = Instance.new("UICorner")
    buttonCorner.CornerRadius = UDim.new(0, 6)
    buttonCorner.Parent = purchaseButton
    
    if isMaxLevel then
        purchaseButton.Text = "MAX LEVEL"
        purchaseButton.BackgroundColor3 = COLORS.disabled
        purchaseButton.TextColor3 = Color3.new(0.3, 0.3, 0.3)
        purchaseButton.Active = false
    else
        purchaseButton.Text = "💰 " .. nextCost
        purchaseButton.BackgroundColor3 = COLORS.accent
        purchaseButton.TextColor3 = Color3.new(0, 0, 0)
        purchaseButton.Active = true
        
        purchaseButton.MouseButton1Click:Connect(function()
            self:PurchaseUpgrade(upgrade.id)
        end)
        
        -- Hover effect
        purchaseButton.MouseEnter:Connect(function()
            if purchaseButton.Active then
                purchaseButton.BackgroundColor3 = Color3.new(1, 0.9, 0.3)
            end
        end)
        
        purchaseButton.MouseLeave:Connect(function()
            if purchaseButton.Active then
                purchaseButton.BackgroundColor3 = COLORS.accent
            end
        end)
    end
    
    return entry
end

function UpgradeController:RefreshUpgradeList()
    -- Clear existing entries
    for _, child in pairs(upgradeList:GetChildren()) do
        if child:IsA("Frame") then
            child:Destroy()
        end
    end
    
    -- Create new entries
    for _, upgrade in pairs(availableUpgrades) do
        self:CreateUpgradeEntry(upgrade)
    end
    
    -- Update canvas size
    upgradeList.CanvasSize = UDim2.new(0, 0, 0, #availableUpgrades * 130)
end

function UpgradeController:ShowUpgradeShop(upgrades, playerUpgrades)
    availableUpgrades = upgrades or {}
    currentUpgrades = playerUpgrades or {}
    
    if not upgradeGui then
        self:CreateUpgradeGUI()
    end
    
    self:RefreshUpgradeList()
    
    upgradeGui.Enabled = true
    
    -- Animate entrance
    upgradeFrame.Size = UDim2.new(0, 0, 0, 0)
    upgradeFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
    
    local tween = TweenService:Create(
        upgradeFrame,
        TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
        {
            Size = UDim2.new(0, 800, 0, 600),
            Position = UDim2.new(0.5, -400, 0.5, -300)
        }
    )
    tween:Play()
    
    print("⚡ Upgrade shop opened")
end

function UpgradeController:HideUpgradeShop()
    if not upgradeGui or not upgradeGui.Enabled then return end
    
    -- Animate exit
    local tween = TweenService:Create(
        upgradeFrame,
        TweenInfo.new(0.2, Enum.EasingStyle.Back, Enum.EasingDirection.In),
        {
            Size = UDim2.new(0, 0, 0, 0),
            Position = UDim2.new(0.5, 0, 0.5, 0)
        }
    )
    
    tween:Play()
    tween.Completed:Connect(function()
        upgradeGui.Enabled = false
    end)
    
    print("⚡ Upgrade shop closed")
end

function UpgradeController:PurchaseUpgrade(upgradeId)
    print("⚡ Attempting to purchase upgrade: " .. upgradeId)
    RemoteEvents.PurchaseUpgrade:FireServer(upgradeId)
end

function UpgradeController:ShowPurchaseResult(success, message, upgradeId)
    -- Create notification
    local notification = Instance.new("Frame")
    notification.Name = "UpgradeNotification"
    notification.Size = UDim2.new(0, 300, 0, 80)
    notification.Position = UDim2.new(0.5, -150, 0, -100)
    notification.BackgroundColor3 = success and COLORS.success or COLORS.error
    notification.BorderSizePixel = 0
    notification.Parent = playerGui
    
    local notifCorner = Instance.new("UICorner")
    notifCorner.CornerRadius = UDim.new(0, 8)
    notifCorner.Parent = notification
    
    local notifText = Instance.new("TextLabel")
    notifText.Size = UDim2.new(1, -20, 1, 0)
    notifText.Position = UDim2.new(0, 10, 0, 0)
    notifText.BackgroundTransparency = 1
    notifText.Text = message
    notifText.TextColor3 = Color3.new(1, 1, 1)
    notifText.TextScaled = true
    notifText.Font = Enum.Font.SourceSansBold
    notifText.Parent = notification
    
    -- Animate in
    notification.Position = UDim2.new(0.5, -150, 0, -100)
    local slideIn = TweenService:Create(
        notification,
        TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
        {Position = UDim2.new(0.5, -150, 0, 20)}
    )
    slideIn:Play()
    
    -- Auto-remove after 3 seconds
    spawn(function()
        wait(3)
        local slideOut = TweenService:Create(
            notification,
            TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.In),
            {Position = UDim2.new(0.5, -150, 0, -100)}
        )
        slideOut:Play()
        slideOut.Completed:Connect(function()
            notification:Destroy()
        end)
    end)
end

function UpgradeController:UpdateUpgradeData(upgrades, playerUpgrades)
    availableUpgrades = upgrades or {}
    currentUpgrades = playerUpgrades or {}
    
    if upgradeGui and upgradeGui.Enabled then
        self:RefreshUpgradeList()
    end
end

function UpgradeController:Init()
    print("⚡ UpgradeController initializing...")
    
    -- Connect remote events
    RemoteEvents.ShowUpgradeShop.OnClientEvent:Connect(function(upgrades, playerUpgrades)
        self:ShowUpgradeShop(upgrades, playerUpgrades)
    end)
    
    RemoteEvents.UpgradePurchaseResult.OnClientEvent:Connect(function(success, message, upgradeId)
        self:ShowPurchaseResult(success, message, upgradeId)
    end)
    
    RemoteEvents.UpdateUpgradeData.OnClientEvent:Connect(function(upgrades, playerUpgrades)
        self:UpdateUpgradeData(upgrades, playerUpgrades)
    end)
    
    -- Handle ESC key to close shop
    UserInputService.InputBegan:Connect(function(input, gameProcessed)
        if gameProcessed then return end
        
        if input.KeyCode == Enum.KeyCode.Escape and upgradeGui and upgradeGui.Enabled then
            self:HideUpgradeShop()
        end
    end)
    
    print("✅ UpgradeController initialized successfully!")
end

return UpgradeController
