-- MonetizationService.luau
-- Handles Gamepass and Developer Product purchases

local Players = game:GetService("Players")
local MarketplaceService = game:GetService("MarketplaceService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local SafeRequire = require(ReplicatedStorage.Shared.utils.SafeRequire)
local RemoteEvents = SafeRequire.require(ReplicatedStorage.Shared.modules.RemoteEvents)

-- Forward declare services
local PlayerService = nil
local DataService = nil
local AnalyticsService = nil

local MonetizationService = {}

-- Product and Gamepass Configuration
local MONETIZATION_CONFIG = {
    gamepasses = {
        doubleCoins = {
            id = 123456789, -- Replace with your actual gamepass ID
            name = "💰 Double Coins",
            description = "Permanently doubles all coin rewards from runs!",
            price = 99, -- Robux price for display
            icon = "💰",
            multiplier = 2.0,
            category = "booster"
        },
        vipTrail = {
            id = 987654321, -- Replace with your actual gamepass ID
            name = "✨ VIP Trail",
            description = "Unlock exclusive VIP rainbow trail with sparkle effects!",
            price = 149, -- Robux price for display
            icon = "✨",
            trailEffect = "VIPRainbow",
            category = "cosmetic"
        }
    },
    developerProducts = {
        coins100Pack = {
            id = 111222333, -- Replace with your actual developer product ID
            name = "💰 100 Coins Pack",
            description = "Instantly get 100 coins to spend in the shop!",
            price = 25, -- Robux price for display
            icon = "💰",
            coinAmount = 100,
            category = "currency"
        },
        crateKey = {
            id = 444555666, -- Replace with your actual developer product ID
            name = "🗝️ Unlock Crate Key",
            description = "Get a special key to unlock mystery crates for free!",
            price = 50, -- Robux price for display
            icon = "🗝️",
            keyAmount = 1,
            category = "consumable"
        }
    }
}

function MonetizationService:CheckPlayerGamepasses(player)
    -- Check all gamepasses the player owns
    local ownedGamepasses = {}
    
    for gamepassKey, gamepassData in pairs(MONETIZATION_CONFIG.gamepasses) do
        if gamepassData.id > 0 then
            local success, ownsGamepass = pcall(function()
                return MarketplaceService:UserOwnsGamePassAsync(player.UserId, gamepassData.id)
            end)
            
            if success and ownsGamepass then
                ownedGamepasses[gamepassKey] = true
                print("🎫 " .. player.Name .. " owns gamepass: " .. gamepassData.name)
            else
                ownedGamepasses[gamepassKey] = false
            end
        end
    end
    
    return ownedGamepasses
end

function MonetizationService:ApplyGamepassBenefits(player)
    -- Apply gamepass benefits to player data
    if not PlayerService then
        warn("❌ PlayerService not available for gamepass benefits")
        return
    end
    
    local playerData = PlayerService:GetPlayerData(player)
    if not playerData then
        warn("❌ No player data found for gamepass benefits")
        return
    end
    
    local ownedGamepasses = self:CheckPlayerGamepasses(player)
    
    -- Initialize gamepass benefits
    playerData.vipCoinMultiplier = 1
    playerData.vipXpMultiplier = 1
    playerData.unlockedTrails = playerData.unlockedTrails or {}
    playerData.rebirthUnlocked = false
    
    -- Apply VIP Trail gamepass
    if ownedGamepasses.vipTrail then
        local trailData = MONETIZATION_CONFIG.gamepasses.vipTrail
        
        -- Unlock VIP trail effect
        if not table.find(playerData.unlockedTrails, trailData.trailEffect) then
            table.insert(playerData.unlockedTrails, trailData.trailEffect)
        end
        
        -- Log analytics
        if AnalyticsService then
            AnalyticsService:LogEvent(player, "gamepass_benefit_applied", {
                gamepassName = trailData.name,
                trailEffect = trailData.trailEffect
            })
        end
        
        print("🌈 Applied VIP Trail gamepass to " .. player.Name)
    end
    
    -- Apply Double Coins gamepass
    if ownedGamepasses.doubleCoins then
        local coinsData = MONETIZATION_CONFIG.gamepasses.doubleCoins
        
        -- Set coin multiplier (this will stack with upgrade multipliers)
        playerData.vipCoinMultiplier = coinsData.multiplier
        
        -- Log analytics
        if AnalyticsService then
            AnalyticsService:LogEvent(player, "gamepass_benefit_applied", {
                gamepassName = coinsData.name,
                multiplier = coinsData.multiplier
            })
        end
        
        print("💎 Applied Double Coins gamepass to " .. player.Name)
    end
    
    -- Apply Rebirth Unlocker gamepass
    if ownedGamepasses.rebirthUnlocker then
        local rebirthData = MONETIZATION_CONFIG.gamepasses.rebirthUnlocker
        
        -- Set XP multiplier and unlock rebirth
        playerData.vipXpMultiplier = rebirthData.xpMultiplier
        playerData.rebirthUnlocked = rebirthData.unlockRebirth
        
        -- Log analytics
        if AnalyticsService then
            AnalyticsService:LogEvent(player, "gamepass_benefit_applied", {
                gamepassName = rebirthData.name,
                xpMultiplier = rebirthData.xpMultiplier,
                rebirthUnlocked = rebirthData.unlockRebirth
            })
        end
        
        print("⭐ Applied Rebirth Unlocker gamepass to " .. player.Name)
    end
    
    -- Update player data
    PlayerService:UpdatePlayerData(player, playerData)
end

function MonetizationService:ProcessReceipt(receiptInfo)
    -- Handle developer product purchases
    local player = Players:GetPlayerByUserId(receiptInfo.PlayerId)
    if not player then
        warn("❌ Player not found for receipt: " .. receiptInfo.PlayerId)
        return Enum.ProductPurchaseDecision.NotProcessedYet
    end
    
    -- Find the product
    local productData = nil
    local productKey = nil
    
    for key, product in pairs(MONETIZATION_CONFIG.developerProducts) do
        if product.id == receiptInfo.ProductId then
            productData = product
            productKey = key
            break
        end
    end
    
    if not productData then
        warn("❌ Unknown product ID: " .. receiptInfo.ProductId)
        return Enum.ProductPurchaseDecision.NotProcessedYet
    end
    
    -- Get player data
    if not PlayerService then
        warn("❌ PlayerService not available for product purchase")
        return Enum.ProductPurchaseDecision.NotProcessedYet
    end
    
    local playerData = PlayerService:GetPlayerData(player)
    if not playerData then
        warn("❌ No player data found for product purchase")
        return Enum.ProductPurchaseDecision.NotProcessedYet
    end
    
    -- Process the purchase based on product type
    if productKey == "coins100Pack" then
        -- Add coins to player
        local coinsToAdd = productData.coinAmount
        playerData.coins = playerData.coins + coinsToAdd
        
        -- Track purchase statistics
        playerData.totalRobuxSpent = (playerData.totalRobuxSpent or 0) + receiptInfo.CurrencySpent
        playerData.totalDevProductPurchases = (playerData.totalDevProductPurchases or 0) + 1
        
        -- Update and save player data
        PlayerService:UpdatePlayerData(player, playerData)
        if DataService then
            DataService:SavePlayerData(player, playerData, "Coins purchase")
        end
        
        -- Log analytics
        if AnalyticsService then
            AnalyticsService:LogEvent(player, "developer_product_purchase", {
                productName = productData.name,
                productId = receiptInfo.ProductId,
                currencySpent = receiptInfo.CurrencySpent,
                coinsReceived = coinsToAdd,
                newCoinTotal = playerData.coins,
                totalSpent = playerData.totalRobuxSpent
            })
        end
        
        -- Notify player
        RemoteEvents.ProductPurchaseResult:FireClient(player, {
            success = true,
            productName = productData.name,
            coinsReceived = coinsToAdd,
            newCoinTotal = playerData.coins
        })
        
        print("💰 " .. player.Name .. " purchased " .. productData.name .. " for " .. receiptInfo.CurrencySpent .. " Robux, received " .. coinsToAdd .. " coins")
        
        return Enum.ProductPurchaseDecision.PurchaseGranted
        
    elseif productKey == "crateKey" then
        -- Add crate keys to player
        local keysToAdd = productData.keyAmount
        playerData.crateKeys = (playerData.crateKeys or 0) + keysToAdd
        
        -- Track purchase statistics
        playerData.totalRobuxSpent = (playerData.totalRobuxSpent or 0) + receiptInfo.CurrencySpent
        playerData.totalDevProductPurchases = (playerData.totalDevProductPurchases or 0) + 1
        playerData.crateKeysPurchased = (playerData.crateKeysPurchased or 0) + keysToAdd
        
        -- Update and save player data
        PlayerService:UpdatePlayerData(player, playerData)
        if DataService then
            DataService:SavePlayerData(player, playerData, "Crate keys purchase")
        end
        
        -- Log analytics
        if AnalyticsService then
            AnalyticsService:LogEvent(player, "developer_product_purchase", {
                productName = productData.name,
                productId = receiptInfo.ProductId,
                currencySpent = receiptInfo.CurrencySpent,
                keysReceived = keysToAdd,
                newKeyTotal = playerData.crateKeys,
                totalSpent = playerData.totalRobuxSpent
            })
        end
        
        -- Notify player
        RemoteEvents.ProductPurchaseResult:FireClient(player, {
            success = true,
            productName = productData.name,
            keysReceived = keysToAdd,
            newKeyTotal = playerData.crateKeys
        })
        
        print("�️ " .. player.Name .. " purchased " .. productData.name .. " for " .. receiptInfo.CurrencySpent .. " Robux, received " .. keysToAdd .. " keys")
        
        return Enum.ProductPurchaseDecision.PurchaseGranted
    end
    
    -- Unknown product type
    warn("❌ Unhandled product type: " .. productKey)
    return Enum.ProductPurchaseDecision.NotProcessedYet
end

function MonetizationService:PromptGamepassPurchase(player, gamepassKey)
    -- Prompt player to purchase a gamepass
    local gamepassData = MONETIZATION_CONFIG.gamepasses[gamepassKey]
    if not gamepassData or gamepassData.id <= 0 then
        warn("❌ Invalid gamepass key: " .. tostring(gamepassKey))
        return false
    end
    
    -- Check if player already owns it
    local success, ownsGamepass = pcall(function()
        return MarketplaceService:UserOwnsGamePassAsync(player.UserId, gamepassData.id)
    end)
    
    if success and ownsGamepass then
        -- Player already owns it, just apply benefits
        self:ApplyGamepassBenefits(player)
        RemoteEvents.GamepassPurchaseResult:FireClient(player, {
            success = true,
            alreadyOwned = true,
            gamepassName = gamepassData.name
        })
        return true
    end
    
    -- Prompt purchase
    local promptSuccess = pcall(function()
        MarketplaceService:PromptGamePassPurchase(player, gamepassData.id)
    end)
    
    if not promptSuccess then
        warn("❌ Failed to prompt gamepass purchase for " .. player.Name)
        RemoteEvents.GamepassPurchaseResult:FireClient(player, {
            success = false,
            error = "Failed to open purchase prompt"
        })
        return false
    end
    
    print("🎫 Prompted " .. player.Name .. " to purchase " .. gamepassData.name)
    return true
end

function MonetizationService:PromptProductPurchase(player, productKey)
    -- Prompt player to purchase a developer product
    local productData = MONETIZATION_CONFIG.developerProducts[productKey]
    if not productData or productData.id <= 0 then
        warn("❌ Invalid product key: " .. tostring(productKey))
        return false
    end
    
    -- Prompt purchase
    local success = pcall(function()
        MarketplaceService:PromptProductPurchase(player, productData.id)
    end)
    
    if not success then
        warn("❌ Failed to prompt product purchase for " .. player.Name)
        RemoteEvents.ProductPurchaseResult:FireClient(player, {
            success = false,
            error = "Failed to open purchase prompt"
        })
        return false
    end
    
    print("💰 Prompted " .. player.Name .. " to purchase " .. productData.name)
    return true
end

function MonetizationService:GetPlayerCoinMultiplier(player)
    -- Calculate total coin multiplier including VIP gamepass
    if not PlayerService then
        return 1
    end
    
    local playerData = PlayerService:GetPlayerData(player)
    if not playerData then
        return 1
    end
    
    local baseMultiplier = playerData.coinMultiplier or 1 -- From upgrades
    local vipMultiplier = playerData.vipCoinMultiplier or 1 -- From VIP gamepass
    
    return baseMultiplier * vipMultiplier
end

function MonetizationService:GetMonetizationInfo()
    -- Return information about available purchases (for UI)
    local info = {
        gamepasses = {},
        developerProducts = {}
    }
    
    -- Gamepass information
    for key, gamepass in pairs(MONETIZATION_CONFIG.gamepasses) do
        info.gamepasses[key] = {
            name = gamepass.name,
            description = gamepass.description,
            id = gamepass.id,
            price = gamepass.price,
            icon = gamepass.icon,
            category = gamepass.category
        }
    end
    
    -- Developer Product information
    for key, product in pairs(MONETIZATION_CONFIG.developerProducts) do
        info.developerProducts[key] = {
            name = product.name,
            description = product.description,
            id = product.id,
            price = product.price,
            icon = product.icon,
            category = product.category
        }
    end
    
    return info
end

function MonetizationService:CheckPlayerOwnedGamepasses(player)
    -- Returns which gamepasses the player owns
    local owned = {}
    
    for key, gamepass in pairs(MONETIZATION_CONFIG.gamepasses) do
        if gamepass.id > 0 then
            local success, ownsGamepass = pcall(function()
                return MarketplaceService:UserOwnsGamePassAsync(player.UserId, gamepass.id)
            end)
            
            owned[key] = (success and ownsGamepass) or false
        else
            owned[key] = false
        end
    end
    
    return owned
end

function MonetizationService:IsPlayerVIP(player)
    -- Check if player owns any VIP gamepasses
    local ownedGamepasses = self:CheckPlayerOwnedGamepasses(player)
    
    -- Player is VIP if they own any gamepass
    for key, owned in pairs(ownedGamepasses) do
        if owned then
            return true
        end
    end
    
    return false
end

function MonetizationService:GetVIPBenefits(player)
    -- Returns a list of VIP benefits the player has
    local benefits = {}
    local ownedGamepasses = self:CheckPlayerOwnedGamepasses(player)
    
    if ownedGamepasses.doubleCoins then
        table.insert(benefits, "2x Coin Multiplier")
    end
    
    if ownedGamepasses.vipTrail then
        table.insert(benefits, "Exclusive VIP Trail")
    end
    
    return benefits
end
        name = MONETIZATION_CONFIG.gamepasses.rebirthUnlocker.name,
        description = MONETIZATION_CONFIG.gamepasses.rebirthUnlocker.description,
        id = MONETIZATION_CONFIG.gamepasses.rebirthUnlocker.id,
        icon = "⭐",
        category = "progression",
        benefit = "Unlock rebirth system + 25% XP bonus"
    }
    
    -- Developer product information
    info.developerProducts.mysteryPetCrate = {
        name = MONETIZATION_CONFIG.developerProducts.mysteryPetCrate.name,
        description = MONETIZATION_CONFIG.developerProducts.mysteryPetCrate.description,
        id = MONETIZATION_CONFIG.developerProducts.mysteryPetCrate.id,
        icon = "🎁",
        category = "pets",
        benefit = "Guaranteed epic+ rarity pet"
    }
    
    info.developerProducts.coins1000Pack = {
        name = MONETIZATION_CONFIG.developerProducts.coins1000Pack.name,
        description = MONETIZATION_CONFIG.developerProducts.coins1000Pack.description,
        id = MONETIZATION_CONFIG.developerProducts.coins1000Pack.id,
        icon = "💰",
        category = "currency",
        benefit = "1000 coins instantly"
    }
    
    return info
end

function MonetizationService:SetPlayerService(service)
    PlayerService = service
end

function MonetizationService:SetDataService(service)
    DataService = service
end

function MonetizationService:SetAnalyticsService(service)
    AnalyticsService = service
end

function MonetizationService:Init()
    -- Set up MarketplaceService callbacks
    MarketplaceService.ProcessReceipt = function(receiptInfo)
        return self:ProcessReceipt(receiptInfo)
    end
    
    -- Handle gamepass purchase completed
    MarketplaceService.PromptGamePassPurchaseFinished:Connect(function(player, gamePassId, wasPurchased)
        if wasPurchased then
            -- Find which gamepass was purchased
            for key, gamepass in pairs(MONETIZATION_CONFIG.gamepasses) do
                if gamepass.id == gamePassId then
                    print("🎫 " .. player.Name .. " purchased gamepass: " .. gamepass.name)
                    
                    -- Apply benefits immediately
                    self:ApplyGamepassBenefits(player)
                    
                    -- Save player data with gamepass purchase reason
                    if DataService and PlayerService then
                        local playerData = PlayerService:GetPlayerData(player)
                        if playerData then
                            DataService:SavePlayerData(player, playerData, "Gamepass purchase: " .. gamepass.name)
                        end
                    end
                    
                    -- Notify client
                    RemoteEvents.GamepassPurchaseResult:FireClient(player, {
                        success = true,
                        gamepassName = gamepass.name,
                        gamepassKey = key
                    })
                    
                    -- Broadcast VIP status to all players
                    local isVIP = self:IsPlayerVIP(player)
                    for _, otherPlayer in pairs(Players:GetPlayers()) do
                        RemoteEvents.VIPStatusUpdated:FireClient(otherPlayer, player, isVIP)
                    end
                    
                    break
                end
            end
        end
    end)
    
    -- Handle remote events for purchase prompts
    RemoteEvents.PromptGamepassPurchase.OnServerEvent:Connect(function(player, gamepassKey)
        self:PromptGamepassPurchase(player, gamepassKey)
    end)
    
    RemoteEvents.PromptProductPurchase.OnServerEvent:Connect(function(player, productKey)
        self:PromptProductPurchase(player, productKey)
    end)
    
    RemoteEvents.RequestMonetizationInfo.OnServerEvent:Connect(function(player)
        local info = self:GetMonetizationInfo()
        local ownedGamepasses = self:CheckPlayerOwnedGamepasses(player)
        
        RemoteEvents.MonetizationInfoUpdated:FireClient(player, {
            info = info,
            ownedGamepasses = ownedGamepasses
        })
    end)
    
    -- Handle VIP status requests
    RemoteEvents.RequestVIPStatus.OnServerEvent:Connect(function(player, targetPlayer)
        if targetPlayer and targetPlayer.Parent then
            local isVIP = self:IsPlayerVIP(targetPlayer)
            RemoteEvents.VIPStatusUpdated:FireClient(player, targetPlayer, isVIP)
        end
    end)
    
    -- Handle monetization shop open requests
    RemoteEvents.OpenMonetizationShop.OnServerEvent:Connect(function(player)
        -- Send monetization info to open the shop
        local info = self:GetMonetizationInfo()
        local ownedGamepasses = self:CheckPlayerOwnedGamepasses(player)
        
        RemoteEvents.MonetizationInfoUpdated:FireClient(player, {
            info = info,
            ownedGamepasses = ownedGamepasses
        })
    end)
    
    print("💰 MonetizationService initialized")
end
        self:PromptGamepassPurchase(player, gamepassKey)
    end)
    
    RemoteEvents.PromptProductPurchase.OnServerEvent:Connect(function(player, productKey)
        self:PromptProductPurchase(player, productKey)
    end)
    
    RemoteEvents.RequestMonetizationInfo.OnServerEvent:Connect(function(player)
        local info = self:GetMonetizationInfo()
        RemoteEvents.MonetizationInfoUpdated:FireClient(player, info)
    end)
    
    -- Apply gamepass benefits to existing players
    for _, player in pairs(Players:GetPlayers()) do
        spawn(function()
            wait(1) -- Small delay to ensure other services are ready
            self:ApplyGamepassBenefits(player)
            
            -- Broadcast VIP status to all players
            local isVIP = self:IsPlayerVIP(player)
            for _, otherPlayer in pairs(Players:GetPlayers()) do
                RemoteEvents.VIPStatusUpdated:FireClient(otherPlayer, player, isVIP)
            end
        end)
    end
    
    -- Handle new players joining
    Players.PlayerAdded:Connect(function(player)
        spawn(function()
            wait(2) -- Wait for player data to load
            self:ApplyGamepassBenefits(player)
            
            -- Broadcast this player's VIP status to everyone
            local isVIP = self:IsPlayerVIP(player)
            for _, otherPlayer in pairs(Players:GetPlayers()) do
                RemoteEvents.VIPStatusUpdated:FireClient(otherPlayer, player, isVIP)
            end
            
            -- Send all existing VIP statuses to this new player
            for _, existingPlayer in pairs(Players:GetPlayers()) do
                if existingPlayer ~= player then
                    local existingVIP = self:IsPlayerVIP(existingPlayer)
                    RemoteEvents.VIPStatusUpdated:FireClient(player, existingPlayer, existingVIP)
                end
            end
        end)
    end)
    
    print("✅ MonetizationService initialized")
end

return MonetizationService
