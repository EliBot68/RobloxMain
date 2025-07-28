-- CoinService.luau
-- Server service for managing coin display, balance updates, and purchase processing

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local RemoteEvents = require(ReplicatedStorage.Shared.modules.RemoteEvents)
local PlayerDataService = require(script.Parent.PlayerDataService)

local CoinService = {}

-- Service state
local connectionIds = {}

function CoinService:Init()
    self:SetupRemoteEvents()
    print("💰 CoinService initialized")
end

function CoinService:SetupRemoteEvents()
    -- Handle coin balance requests
    connectionIds.RequestPlayerCoins = RemoteEvents.RequestPlayerCoins.OnServerEvent:Connect(function(player)
        self:SendPlayerCoins(player)
    end)
    
    -- Handle purchase processing
    connectionIds.ProcessPurchase = RemoteEvents.ProcessPurchase.OnServerEvent:Connect(function(player, purchaseData)
        self:ProcessPurchase(player, purchaseData)
    end)
    
    -- Hook into existing coin collection events
    connectionIds.CoinCollected = RemoteEvents.CoinCollected.OnServerEvent:Connect(function(player, coinValue, runningTotal)
        self:HandleCoinCollection(player, coinValue, runningTotal)
    end)
end

function CoinService:SendPlayerCoins(player)
    -- Get current coin balance from PlayerDataService
    local playerData = PlayerDataService:GetPlayerData(player)
    if playerData then
        local coinBalance = playerData.coins or 0
        RemoteEvents.CoinBalanceUpdated:FireClient(player, coinBalance)
    end
end

function CoinService:HandleCoinCollection(player, coinValue, runningTotal)
    -- Update the live coin display during runs
    RemoteEvents.CoinCollected:FireClient(player, runningTotal)
end

function CoinService:UpdatePlayerCoins(player, newCoinAmount, animate)
    -- Update coins in player data
    local playerData = PlayerDataService:GetPlayerData(player)
    if playerData then
        playerData.coins = newCoinAmount
        PlayerDataService:SavePlayerData(player)
        
        -- Send update to client
        if animate then
            RemoteEvents.CoinCollected:FireClient(player, newCoinAmount)
        else
            RemoteEvents.InstantCoinUpdate:FireClient(player, newCoinAmount)
        end
    end
end

function CoinService:ProcessPurchase(player, purchaseData)
    if not purchaseData or not purchaseData.price or not purchaseData.itemId then
        RemoteEvents.PurchaseResult:FireClient(player, false, "Invalid purchase data", nil)
        return
    end
    
    -- Delegate upgrade purchases to EnhancedUpgradeService
    if purchaseData.itemType == "upgrade" then
        local EnhancedUpgradeService = require(script.Parent.EnhancedUpgradeService)
        local success, message = EnhancedUpgradeService:ProcessUpgradePurchase(player, purchaseData)
        
        if success then
            RemoteEvents.PurchaseResult:FireClient(player, true, message, nil)
        else
            RemoteEvents.PurchaseResult:FireClient(player, false, message, nil)
        end
        return
    end
    
    local playerData = PlayerDataService:GetPlayerData(player)
    if not playerData then
        RemoteEvents.PurchaseResult:FireClient(player, false, "Player data not found", nil)
        return
    end
    
    local currentCoins = playerData.coins or 0
    local price = purchaseData.price
    
    -- Check if player has enough coins
    if currentCoins < price then
        RemoteEvents.PurchaseResult:FireClient(player, false, 
            "Not enough coins! You need " .. price .. " but only have " .. currentCoins, currentCoins)
        return
    end
    
    -- Process the purchase based on item type
    local success, message = self:ProcessSpecificPurchase(player, purchaseData, playerData)
    
    if success then
        -- Deduct coins
        local newBalance = currentCoins - price
        playerData.coins = newBalance
        PlayerDataService:SavePlayerData(player)
        
        -- Send success result
        RemoteEvents.PurchaseResult:FireClient(player, true, message or "Purchase successful!", newBalance)
        
        -- Update coin display
        RemoteEvents.InstantCoinUpdate:FireClient(player, newBalance)
        
        -- Log analytics
        self:LogPurchaseAnalytics(player, purchaseData, newBalance)
    else
        -- Send failure result
        RemoteEvents.PurchaseResult:FireClient(player, false, message or "Purchase failed", currentCoins)
    end
end

function CoinService:ProcessSpecificPurchase(player, purchaseData, playerData)
    local itemType = purchaseData.itemType or "unknown"
    local itemId = purchaseData.itemId
    
    if itemType == "shop_item" then
        return self:ProcessShopItemPurchase(player, purchaseData, playerData)
    elseif itemType == "upgrade" then
        return self:ProcessUpgradePurchase(player, purchaseData, playerData)
    elseif itemType == "buff" then
        return self:ProcessBuffPurchase(player, purchaseData, playerData)
    elseif itemType == "mystery_box" then
        return self:ProcessMysteryBoxPurchase(player, purchaseData, playerData)
    elseif itemType == "rebirth" then
        return self:ProcessRebirthPurchase(player, purchaseData, playerData)
    else
        return false, "Unknown item type: " .. itemType
    end
end

function CoinService:ProcessShopItemPurchase(player, purchaseData, playerData)
    local itemId = purchaseData.itemId
    
    -- Add item to player inventory
    if not playerData.inventory then
        playerData.inventory = {}
    end
    
    if not playerData.inventory.cosmetics then
        playerData.inventory.cosmetics = {}
    end
    
    -- Check if already owned
    if playerData.inventory.cosmetics[itemId] then
        return false, "You already own this item!"
    end
    
    -- Add to inventory
    playerData.inventory.cosmetics[itemId] = {
        purchased = os.time(),
        equipped = false
    }
    
    return true, "Cosmetic item purchased successfully!"
end

function CoinService:ProcessUpgradePurchase(player, purchaseData, playerData)
    -- This method is kept for compatibility but shouldn't be called
    -- Upgrade purchases are now handled by EnhancedUpgradeService
    return false, "Upgrade purchases should be handled by EnhancedUpgradeService"
end

function CoinService:ProcessBuffPurchase(player, purchaseData, playerData)
    local buffType = purchaseData.buffType or purchaseData.itemId
    local duration = purchaseData.duration or 300 -- 5 minutes default
    
    -- Apply temporary buff
    RemoteEvents.ApplyTempMultiplier:FireClient(player, buffType, duration, purchaseData.multiplier or 2)
    
    return true, "Buff activated for " .. (duration / 60) .. " minutes!"
end

function CoinService:ProcessMysteryBoxPurchase(player, purchaseData, playerData)
    -- Let mystery controller handle the specific logic
    RemoteEvents.PurchaseMysteryBox:FireServer(player, purchaseData)
    return true, "Mystery box purchased! Opening..."
end

function CoinService:ProcessRebirthPurchase(player, purchaseData, playerData)
    -- Handle rebirth purchase
    local rebirthLevel = playerData.rebirths or 0
    local newLevel = rebirthLevel + 1
    
    -- Reset player progress but increase rebirth level
    playerData.rebirths = newLevel
    playerData.highScore = 0
    playerData.level = 1
    playerData.xp = 0
    
    -- Grant rebirth benefits
    local coinsBonus = newLevel * 1000
    playerData.coins = (playerData.coins or 0) + coinsBonus
    
    return true, "Rebirth successful! You are now Rebirth " .. newLevel .. " and received " .. coinsBonus .. " bonus coins!"
end

function CoinService:LogPurchaseAnalytics(player, purchaseData, newBalance)
    -- Log purchase analytics
    RemoteEvents.LogAnalyticsEvent:FireServer(player, "coin_purchase", {
        item_type = purchaseData.itemType,
        item_id = purchaseData.itemId,
        price = purchaseData.price,
        remaining_balance = newBalance,
        timestamp = os.time()
    })
end

function CoinService:AwardCoins(player, amount, reason, animate)
    animate = animate ~= false -- Default to true
    
    local playerData = PlayerDataService:GetPlayerData(player)
    if playerData then
        local currentCoins = playerData.coins or 0
        local newTotal = currentCoins + amount
        
        playerData.coins = newTotal
        PlayerDataService:SavePlayerData(player)
        
        if animate then
            RemoteEvents.CoinCollected:FireClient(player, newTotal)
        else
            RemoteEvents.InstantCoinUpdate:FireClient(player, newTotal)
        end
        
        -- Show reward notification if reason provided
        if reason then
            -- Could send to a reward notification system
        end
        
        return newTotal
    end
    
    return 0
end

function CoinService:DeductCoins(player, amount, reason)
    local playerData = PlayerDataService:GetPlayerData(player)
    if playerData then
        local currentCoins = playerData.coins or 0
        
        if currentCoins >= amount then
            local newTotal = currentCoins - amount
            playerData.coins = newTotal
            PlayerDataService:SavePlayerData(player)
            
            RemoteEvents.InstantCoinUpdate:FireClient(player, newTotal)
            return true, newTotal
        end
    end
    
    return false, 0
end

function CoinService:GetPlayerCoins(player)
    local playerData = PlayerDataService:GetPlayerData(player)
    if playerData then
        return playerData.coins or 0
    end
    return 0
end

function CoinService:HandlePlayerAdded(player)
    -- Send initial coin balance when player joins
    player.CharacterAdded:Connect(function()
        wait(2) -- Give time for client to initialize
        self:SendPlayerCoins(player)
    end)
end

function CoinService:HandlePlayerRemoving(player)
    -- Clean up any player-specific data
    -- PlayerDataService handles the main cleanup
end

function CoinService:Cleanup()
    -- Disconnect all remote event connections
    for _, connection in pairs(connectionIds) do
        if connection then
            connection:Disconnect()
        end
    end
    connectionIds = {}
end

return CoinService
