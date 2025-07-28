-- EnhancedUpgradeService.luau
-- Server service for managing Speed Boost, Coin Bonus, and XP Boost upgrades

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local RemoteEvents = require(ReplicatedStorage.Shared.modules.RemoteEvents)
local DataService = require(script.Parent.DataService)

-- Import PlayerService for data access
local PlayerService = nil
local EconomyBalanceService = nil

local EnhancedUpgradeService = {}

-- Service state
local connectionIds = {}
local upgradeStalls = {}

-- Upgrade definitions (must match client)
local UPGRADE_DEFINITIONS = {
    speed_boost = {
        name = "Speed Boost",
        description = "Increase movement speed during runs",
        baseCost = 100,
        maxLevel = 10,
        costMultiplier = 1.5,
        bonusPerLevel = 0.1 -- 10% speed increase per level
    },
    coin_bonus = {
        name = "Coin Bonus",
        description = "Earn more coins from runs and activities",
        baseCost = 150,
        maxLevel = 10,
        costMultiplier = 1.6,
        bonusPerLevel = 0.15 -- 15% coin bonus per level
    },
    xp_boost = {
        name = "XP Boost",
        description = "Gain more experience from all activities",
        baseCost = 200,
        maxLevel = 10,
        costMultiplier = 1.7,
        bonusPerLevel = 0.2 -- 20% XP bonus per level
    }
}

function EnhancedUpgradeService:Init()
    -- Initialize service references
    EconomyBalanceService = require(script.Parent.core.EconomyBalanceService)
    
    self:SetupUpgradeStalls()
    self:SetupRemoteEvents()
    print("⬆️ EnhancedUpgradeService initialized")
end

function EnhancedUpgradeService:SetupUpgradeStalls()
    -- Create upgrade stalls in the hub
    game.Loaded:Wait()
    
    spawn(function()
        wait(2) -- Wait for world to load
        self:CreateUpgradeStall()
    end)
end

function EnhancedUpgradeService:CreateUpgradeStall()
    -- Find or create upgrade stall location
    local stallPosition = Vector3.new(50, 5, -20) -- Near other shops
    
    -- Create stall structure
    local stallFolder = Instance.new("Folder")
    stallFolder.Name = "UpgradeStall"
    stallFolder.Parent = Workspace
    
    -- Base platform
    local basePart = Instance.new("Part")
    basePart.Name = "UpgradeStallBase"
    basePart.Size = Vector3.new(8, 1, 8)
    basePart.Position = stallPosition
    basePart.Anchored = true
    basePart.Material = Enum.Material.Marble
    basePart.BrickColor = BrickColor.new("Dark stone grey")
    basePart.Parent = stallFolder
    
    -- Stall sign
    local signPart = Instance.new("Part")
    signPart.Name = "UpgradeStallSign"
    signPart.Size = Vector3.new(6, 4, 0.5)
    signPart.Position = stallPosition + Vector3.new(0, 3, 3)
    signPart.Anchored = true
    signPart.Material = Enum.Material.Neon
    signPart.BrickColor = BrickColor.new("Bright blue")
    signPart.Parent = stallFolder
    
    -- Sign text
    local signGui = Instance.new("SurfaceGui")
    signGui.Face = Enum.NormalId.Front
    signGui.Parent = signPart
    
    local signText = Instance.new("TextLabel")
    signText.Size = UDim2.new(1, 0, 1, 0)
    signText.BackgroundTransparency = 1
    signText.Text = "⬆️ UPGRADE STALL ⬆️\nSpeed • Coins • XP"
    signText.TextColor3 = Color3.fromRGB(255, 255, 255)
    signText.TextScaled = true
    signText.Font = Enum.Font.GothamBold
    signText.Parent = signGui
    
    -- Interaction part
    local interactionPart = Instance.new("Part")
    interactionPart.Name = "UpgradeStallInteraction"
    interactionPart.Size = Vector3.new(6, 6, 6)
    interactionPart.Position = stallPosition + Vector3.new(0, 3.5, 0)
    interactionPart.Anchored = true
    interactionPart.CanCollide = false
    interactionPart.Transparency = 0.8
    interactionPart.Material = Enum.Material.ForceField
    interactionPart.BrickColor = BrickColor.new("Bright blue")
    interactionPart.Parent = stallFolder
    
    -- Proximity prompt
    local proximityPrompt = Instance.new("ProximityPrompt")
    proximityPrompt.ActionText = "Open Upgrade Shop"
    proximityPrompt.ObjectText = "Upgrade Stall"
    proximityPrompt.HoldDuration = 0
    proximityPrompt.MaxActivationDistance = 10
    proximityPrompt.Parent = interactionPart
    
    -- Handle interactions
    proximityPrompt.Triggered:Connect(function(player)
        self:OpenUpgradeShop(player)
    end)
    
    -- Store reference
    upgradeStalls.main = {
        folder = stallFolder,
        interaction = interactionPart,
        prompt = proximityPrompt
    }
end

function EnhancedUpgradeService:SetupRemoteEvents()
    -- Handle upgrade shop requests
    connectionIds.ShowUpgradeShop = RemoteEvents.ShowUpgradeShop.OnServerEvent:Connect(function(player)
        self:OpenUpgradeShop(player)
    end)
    
    -- Handle upgrade data requests
    connectionIds.RequestUpgradeData = RemoteEvents.RequestUpgradeData.OnServerEvent:Connect(function(player)
        self:SendUpgradeData(player)
    end)
end

function EnhancedUpgradeService:OpenUpgradeShop(player)
    if not PlayerService then
        warn("❌ PlayerService not available for upgrade shop")
        return
    end
    
    local playerData = PlayerService:GetPlayerData(player)
    if not playerData then
        return
    end
    
    -- Ensure upgrades table exists
    if not playerData.upgrades then
        playerData.upgrades = {}
    end
    
    -- Send upgrade data to client
    RemoteEvents.ShowUpgradeShop:FireClient(player, playerData.upgrades)
end

function EnhancedUpgradeService:SendUpgradeData(player)
    if not PlayerService then
        return
    end
    
    local playerData = PlayerService:GetPlayerData(player)
    if not playerData then
        return
    end
    end
    
    if not playerData.upgrades then
        playerData.upgrades = {}
    end
    
    RemoteEvents.UpgradeDataUpdated:FireClient(player, playerData.upgrades)
end

function EnhancedUpgradeService:CalculateUpgradeCost(upgradeType, level, playerLevel)
    -- Use EconomyBalanceService for balanced pricing
    if EconomyBalanceService then
        return EconomyBalanceService:GetUpgradePrice("enhanced", upgradeType, level, playerLevel or 1)
    end
    
    -- Fallback to old system if economy service not available
    local upgrade = UPGRADE_DEFINITIONS[upgradeType]
    if not upgrade then return 0 end
    
    return math.floor(upgrade.baseCost * (upgrade.costMultiplier ^ (level - 1)))
end

function EnhancedUpgradeService:ProcessUpgradePurchase(player, purchaseData)
    if not purchaseData or purchaseData.itemType ~= "upgrade" then
        return false, "Invalid upgrade purchase data"
    end
    
    local upgradeType = purchaseData.upgradeType or purchaseData.itemId
    local upgrade = UPGRADE_DEFINITIONS[upgradeType]
    
    if not upgrade then
        return false, "Unknown upgrade type: " .. tostring(upgradeType)
    end
    
    if not PlayerService then
        return false, "PlayerService not available"
    end
    
    local playerData = PlayerService:GetPlayerData(player)
    if not playerData then
        return false, "Player data not found"
    end
    
    -- Ensure upgrades table exists
    if not playerData.upgrades then
        playerData.upgrades = {}
    end
    
    local currentLevel = playerData.upgrades[upgradeType] or 0
    local nextLevel = currentLevel + 1
    
    -- Check level limits
    if currentLevel >= upgrade.maxLevel then
        return false, "Upgrade already at maximum level!"
    end
    
    -- Calculate cost (using player level for scaling)
    local cost = self:CalculateUpgradeCost(upgradeType, nextLevel, playerData.level or 1)
    
    -- Check if player has enough coins
    local currentCoins = playerData.coins or 0
    if currentCoins < cost then
        return false, "Not enough coins! You need " .. cost .. " but only have " .. currentCoins
    end
    
    -- Process the purchase
    playerData.coins = currentCoins - cost
    playerData.upgrades[upgradeType] = nextLevel
    
    -- Trigger immediate save for upgrade purchase
    DataService:TriggerImmediateSaveForCriticalChange(player, "UPGRADE_PURCHASE", 
        string.format("%s upgraded to Level %d", upgradeType, nextLevel))
    
    -- Save data through PlayerService for integrated data management
    if PlayerService then
        PlayerService:UpdatePlayerData(player, playerData)
    else
        DataService:ImmediateSave(player, playerData, "Upgrade purchase")
    end
    
    -- Apply the upgrade effect immediately
    self:ApplyUpgradeEffect(player, upgradeType, nextLevel)
    
    -- Send success result
    RemoteEvents.UpgradePurchaseResult:FireClient(player, true, upgradeType, nextLevel, 
        upgrade.name .. " upgraded to Level " .. nextLevel .. "!")
    
    -- Update upgrade data
    RemoteEvents.UpgradeDataUpdated:FireClient(player, playerData.upgrades)
    
    -- Update coin display
    RemoteEvents.InstantCoinUpdate:FireClient(player, playerData.coins)
    
    return true, "Upgrade successful!"
end

function EnhancedUpgradeService:ApplyUpgradeEffect(player, upgradeType, level)
    local character = player.Character
    if not character then return end
    
    local humanoid = character:FindFirstChild("Humanoid")
    if not humanoid then return end
    
    -- Apply speed boost immediately
    if upgradeType == "speed_boost" then
        self:ApplySpeedBoost(player, level)
    end
    
    -- Coin and XP bonuses are applied during gameplay in other services
end

function EnhancedUpgradeService:ApplySpeedBoost(player, level)
    local character = player.Character
    if not character then return end
    
    local humanoid = character:FindFirstChild("Humanoid")
    if not humanoid then return end
    
    local upgrade = UPGRADE_DEFINITIONS.speed_boost
    local speedMultiplier = 1 + (upgrade.bonusPerLevel * level)
    
    -- Apply speed boost (base speed is 16)
    local baseSpeed = 16
    humanoid.WalkSpeed = baseSpeed * speedMultiplier
    
    print("🏃 Applied speed boost Level " .. level .. " to " .. player.Name .. " (Speed: " .. humanoid.WalkSpeed .. ")")
end

function EnhancedUpgradeService:GetUpgradeMultiplier(player, upgradeType)
    if not PlayerService then
        return 1
    end
    
    local playerData = PlayerService:GetPlayerData(player)
    if not playerData or not playerData.upgrades then
        return 1
    end
    
    local level = playerData.upgrades[upgradeType] or 0
    local upgrade = UPGRADE_DEFINITIONS[upgradeType]
    
    if not upgrade or level <= 0 then
        return 1
    end
    
    return 1 + (upgrade.bonusPerLevel * level)
end

function EnhancedUpgradeService:GetCoinMultiplier(player)
    return self:GetUpgradeMultiplier(player, "coin_bonus")
end

function EnhancedUpgradeService:GetXpMultiplier(player)
    return self:GetUpgradeMultiplier(player, "xp_boost")
end

function EnhancedUpgradeService:GetSpeedMultiplier(player)
    return self:GetUpgradeMultiplier(player, "speed_boost")
end

function EnhancedUpgradeService:HandlePlayerAdded(player)
    -- Apply upgrades when player spawns
    player.CharacterAdded:Connect(function(character)
        wait(1) -- Wait for character to fully load
        self:ApplyAllUpgrades(player)
    end)
end

function EnhancedUpgradeService:ApplyAllUpgrades(player)
    if not PlayerService then
        return
    end
    
    local playerData = PlayerService:GetPlayerData(player)
    if not playerData or not playerData.upgrades then
        return
    end
    
    -- Apply speed boost
    local speedLevel = playerData.upgrades.speed_boost or 0
    if speedLevel > 0 then
        self:ApplySpeedBoost(player, speedLevel)
    end
end

function EnhancedUpgradeService:HandlePlayerRemoving(player)
    -- Cleanup any player-specific data
end

function EnhancedUpgradeService:Cleanup()
    -- Disconnect all remote event connections
    for _, connection in pairs(connectionIds) do
        if connection then
            connection:Disconnect()
        end
    end
    connectionIds = {}
    
    -- Clean up upgrade stalls
    for _, stall in pairs(upgradeStalls) do
        if stall.folder and stall.folder.Parent then
            stall.folder:Destroy()
        end
    end
    upgradeStalls = {}
end

-- Service dependency setters
function EnhancedUpgradeService:SetPlayerService(service)
    PlayerService = service
end

return EnhancedUpgradeService
