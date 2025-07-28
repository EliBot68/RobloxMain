-- PlayerService.luau
-- Handles player-related functionality

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local DataService = require(script.Parent.DataService)
local RemoteEvents = require(ReplicatedStorage.Shared.modules.RemoteEvents)

-- Forward declare LeaderboardService to avoid circular dependency
local LeaderboardService = nil
local ShopService = nil
local AnalyticsService = nil
local MonetizationService = nil
local AchievementService = nil

local PlayerService = {}
local playerData = {}

function PlayerService:CreateLeaderstats(player)
    local leaderstats = Instance.new("Folder")
    leaderstats.Name = "leaderstats"
    leaderstats.Parent = player
    
    local level = Instance.new("IntValue")
    level.Name = "Level"
    level.Value = playerData[player.UserId].level or 1
    level.Parent = leaderstats
    
    local coins = Instance.new("IntValue")
    coins.Name = "Coins"
    coins.Value = playerData[player.UserId].coins
    coins.Parent = leaderstats
    
    local highScore = Instance.new("IntValue")
    highScore.Name = "High Score"
    highScore.Value = playerData[player.UserId].highScore
    highScore.Parent = leaderstats
    
    local gamesPlayed = Instance.new("IntValue")
    gamesPlayed.Name = "Games Played"
    gamesPlayed.Value = playerData[player.UserId].gamesPlayed
    gamesPlayed.Parent = leaderstats
    
    return leaderstats
end

function PlayerService:OnPlayerAdded(player)
    print("🎮 " .. player.Name .. " joined the game!")
    
    -- Load player data
    playerData[player.UserId] = DataService:GetPlayerData(player)
    
    -- Create leaderstats
    self:CreateLeaderstats(player)
    
    -- Handle spawning in market plaza
    player.CharacterAdded:Connect(function(character)
        self:SpawnInMarketPlaza(player, character)
    end)
    
    -- Send initial data to client
    RemoteEvents.PlayerDataUpdated:FireClient(player, playerData[player.UserId])
    
    -- Send initial coin balance to coin display
    local coinBalance = playerData[player.UserId].coins or 0
    RemoteEvents.CoinBalanceUpdated:FireClient(player, coinBalance)
    
    -- Apply purchased upgrades immediately after data is loaded
    self:ApplyStoredUpgrades(player)
    
    -- Apply gamepass benefits if MonetizationService is available
    if MonetizationService then
        spawn(function()
            wait(0.5) -- Small delay to ensure data is fully loaded
            MonetizationService:ApplyGamepassBenefits(player)
        end)
    end
    
    -- Check if this is a new player and start tutorial
    spawn(function()
        wait(2) -- Give player time to fully load in
        self:CheckForNewPlayerTutorial(player)
    end)
end

function PlayerService:SpawnInMarketPlaza(player, character)
    local humanoid = character:WaitForChild("Humanoid")
    local humanoidRootPart = character:WaitForChild("HumanoidRootPart")
    
    -- Spawn near the fountain in a random position around it
    local spawnPositions = {
        Vector3.new(8, 5, 8),   -- Northeast of fountain
        Vector3.new(-8, 5, 8),  -- Northwest of fountain
        Vector3.new(8, 5, -8),  -- Southeast of fountain
        Vector3.new(-8, 5, -8), -- Southwest of fountain
        Vector3.new(0, 5, 12),  -- North of fountain
        Vector3.new(0, 5, -12), -- South of fountain
        Vector3.new(12, 5, 0),  -- East of fountain
        Vector3.new(-12, 5, 0)  -- West of fountain
    }
    
    local randomSpawn = spawnPositions[math.random(1, #spawnPositions)]
    humanoidRootPart.CFrame = CFrame.new(randomSpawn)
    
    -- Apply all character-based upgrades before enabling movement
    self:ApplyCharacterUpgrades(player, character)
    
    print("🏪 " .. player.Name .. " spawned in the market plaza with upgrades applied!")
end

function PlayerService:ApplyStoredUpgrades(player)
    -- Validate and repair upgrade data first
    self:ValidateUpgradeData(player)
    
    -- Apply upgrades that don't require a character (data-based effects)
    local data = playerData[player.UserId]
    if not data or not data.ownedUpgrades then
        return
    end
    
    -- Apply coin multiplier and magnet range based on owned upgrades
    if ShopService then
        local allItems = ShopService:GetShopItems()
        
        for itemId, owned in pairs(data.ownedUpgrades) do
            if owned then
                -- Find the upgrade item
                for _, item in pairs(allItems) do
                    if item.id == itemId and item.category == "upgrade" then
                        -- Apply data-based upgrades immediately
                        if item.upgradeType == "coinMagnet" then
                            local magnetRange = 3 + (item.level * 2)
                            data.magnetRange = magnetRange
                            print("🧲 Applied stored Coin Magnet Level " .. item.level .. " to " .. player.Name)
                            
                        elseif item.upgradeType == "doubleCoins" then
                            local coinMultiplier = 1 + item.level
                            data.coinMultiplier = coinMultiplier
                            print("💰 Applied stored Double Coins Level " .. item.level .. " to " .. player.Name)
                        end
                        break
                    end
                end
            end
        end
        
        -- Update the data with applied effects
        self:UpdatePlayerData(player, data)
    end
    
    print("🔄 Applied stored upgrades for " .. player.Name)
end

function PlayerService:ApplyCharacterUpgrades(player, character)
    -- Apply upgrades that require a character (speed, trails, etc.)
    local data = playerData[player.UserId]
    if not data or not data.ownedUpgrades then
        return
    end
    
    local humanoid = character:WaitForChild("Humanoid")
    if not humanoid then
        return
    end
    
    -- Temporarily disable movement while applying upgrades
    local originalWalkSpeed = humanoid.WalkSpeed
    humanoid.WalkSpeed = 0
    humanoid.PlatformStand = true
    
    if ShopService then
        local allItems = ShopService:GetShopItems()
        local speedLevel = 0
        
        -- Find the highest speed upgrade owned
        for itemId, owned in pairs(data.ownedUpgrades) do
            if owned then
                for _, item in pairs(allItems) do
                    if item.id == itemId and item.category == "upgrade" and item.upgradeType == "speed" then
                        if item.level > speedLevel then
                            speedLevel = item.level
                        end
                        break
                    end
                end
            end
        end
        
        -- Apply the highest speed upgrade
        if speedLevel > 0 then
            local baseSpeed = 16
            local speedMultiplier = 1 + (speedLevel * 0.15)
            local newSpeed = baseSpeed * speedMultiplier
            
            humanoid.WalkSpeed = newSpeed
            print("⚡ Applied Speed Boost Level " .. speedLevel .. " to " .. player.Name .. " (Speed: " .. newSpeed .. ")")
        else
            humanoid.WalkSpeed = originalWalkSpeed
        end
        
        -- Apply trail effects and other character-based upgrades
        ShopService:ApplyPlayerCosmetics(player)
    else
        humanoid.WalkSpeed = originalWalkSpeed
    end
    
    -- Re-enable movement
    humanoid.PlatformStand = false
    
    print("⚡ Applied character upgrades for " .. player.Name)
end

function PlayerService:OnPlayerRemoving(player)
    print("👋 " .. player.Name .. " left the game!")
    
    -- Save player data
    if playerData[player.UserId] then
        local success = DataService:SavePlayerData(player, playerData[player.UserId])
        if success then
            print("💾 Successfully saved all data for " .. player.Name)
        else
            warn("❌ Failed to save data for " .. player.Name .. " on disconnect!")
        end
        playerData[player.UserId] = nil
    end
    
    -- Clean up data tracking
    DataService:CleanupPlayerTracking(player)
end

function PlayerService:HandlePurchase(player, itemName, cost)
    local data = playerData[player.UserId]
    
    if data and data.coins >= cost then
        data.coins = data.coins - cost
        
        -- Track purchase statistics
        data.totalPurchases = (data.totalPurchases or 0) + 1
        
        -- Update player data and save immediately
        self:UpdatePlayerData(player, data)
        DataService:SavePlayerData(player, data)
        
        -- Log analytics event for shop purchase
        if AnalyticsService then
            AnalyticsService:LogEvent(player, AnalyticsService.EventTypes.SHOP_PURCHASE, {
                itemName = itemName,
                cost = cost,
                totalPurchases = data.totalPurchases,
                remainingCoins = data.coins
            })
        end
        
        print("💰 " .. player.Name .. " purchased " .. itemName .. " for " .. cost .. " coins (Total purchases: " .. data.totalPurchases .. ")")
        return true
    else
        print("❌ " .. player.Name .. " tried to purchase " .. itemName .. " but doesn't have enough coins (" .. (data and data.coins or 0) .. "/" .. cost .. ")")
        return false
    end
end

function PlayerService:HandleColorChange(player, colorName)
    local data = playerData[player.UserId]
    if data then
        data.currentColor = colorName
        self:UpdatePlayerData(player, data)
        print("🎨 " .. player.Name .. " changed color to " .. colorName)
    end
end

function PlayerService:UpdatePlayerSetting(player, settingKey, value)
    local data = playerData[player.UserId]
    if not data then
        warn("❌ No player data found for setting update: " .. player.Name)
        return false
    end
    
    -- Ensure settings table exists
    if not data.settings then
        data.settings = {
            music = true,
            sfx = true,
            colorblindMode = false,
            controllerEnabled = true
        }
    end
    
    -- Update the specific setting
    data.settings[settingKey] = value
    
    -- Save the updated data
    self:UpdatePlayerData(player, data)
    DataService:SavePlayerData(player, data)
    
    -- Update quest progress for accessibility settings
    if (settingKey == "colorblindMode" or settingKey == "controllerEnabled") and value then
        -- Dynamically require QuestService to avoid circular dependency
        local success, QuestService = pcall(require, script.Parent.QuestService)
        if success and QuestService then
            QuestService:UpdateQuestProgress(player, "accessibility_setting", 1, {
                setting = settingKey,
                enabled = value
            })
        end
    end
    
    -- Log analytics event for accessibility usage
    if AnalyticsService and (settingKey == "colorblindMode" or settingKey == "controllerEnabled") then
        AnalyticsService:LogEvent(player, "accessibility_setting_changed", {
            setting = settingKey,
            enabled = value,
            timestamp = os.time()
        })
    end
    
    print("⚙️ " .. player.Name .. " updated setting " .. settingKey .. " = " .. tostring(value))
    return true
end

function PlayerService:UpdateHighScore(player, newScore)
    -- Update player's high score if it's higher than current
    local data = playerData[player.UserId]
    if not data then
        warn("❌ No player data found for high score update: " .. player.Name)
        return false
    end
    
    local oldHighScore = data.highScore or 0
    if newScore > oldHighScore then
        data.highScore = newScore
        
        -- Update player data and save immediately to DataStore
        self:UpdatePlayerData(player, data)
        DataService:SavePlayerData(player, data)
        
        -- Update Roblox's global leaderboard service
        if LeaderboardService then
            LeaderboardService:UpdatePlayerScore(player.UserId, newScore)
        end
        
        -- Log analytics event for new high score
        if AnalyticsService then
            AnalyticsService:LogEvent(player, AnalyticsService.EventTypes.NEW_HIGH_SCORE, {
                newHighScore = newScore,
                oldHighScore = oldHighScore,
                improvement = newScore - oldHighScore
            })
        end
        
        print("🏆 NEW HIGH SCORE! " .. player.Name .. " scored " .. newScore .. " (was " .. oldHighScore .. ")")
        return true
    end
    
    return false
end

function PlayerService:GetPlayerData(player)
    return playerData[player.UserId]
end

function PlayerService:UpdatePlayerData(player, newData)
    if playerData[player.UserId] then
        local oldData = playerData[player.UserId]
        playerData[player.UserId] = newData
        
        -- Update leaderstats
        if player:FindFirstChild("leaderstats") then
            player.leaderstats.Coins.Value = newData.coins
            player.leaderstats["High Score"].Value = newData.highScore
            player.leaderstats["Games Played"].Value = newData.gamesPlayed
        end
        
        -- Auto-save on critical changes (coins, high score, purchases, level/XP)
        local shouldAutoSave = false
        local changeType = ""
        local changeDetails = ""
        
        if oldData.coins ~= newData.coins then
            shouldAutoSave = true
            changeType = "COIN_CHANGE"
            changeDetails = string.format("%d -> %d", oldData.coins or 0, newData.coins or 0)
        end
        if oldData.highScore ~= newData.highScore then
            shouldAutoSave = true
            changeType = "HIGH_SCORE"
            changeDetails = string.format("%d -> %d", oldData.highScore or 0, newData.highScore or 0)
        end
        if (oldData.totalPurchases or 0) ~= (newData.totalPurchases or 0) then
            shouldAutoSave = true
            changeType = "PURCHASE"
            changeDetails = string.format("Total purchases: %d", newData.totalPurchases or 0)
        end
        if (oldData.level or 1) ~= (newData.level or 1) then
            shouldAutoSave = true
            changeType = "LEVEL_UP"
            changeDetails = string.format("Level %d -> %d", oldData.level or 1, newData.level or 1)
        end
        if (oldData.experience or 0) ~= (newData.experience or 0) then
            shouldAutoSave = true
            changeType = "XP_GAIN"
            changeDetails = string.format("XP %d -> %d", oldData.experience or 0, newData.experience or 0)
        end
        -- Enhanced upgrades
        if oldData.enhancedUpgrades and newData.enhancedUpgrades then
            for upgradeType, newLevel in pairs(newData.enhancedUpgrades) do
                local oldLevel = oldData.enhancedUpgrades[upgradeType] or 0
                if oldLevel ~= newLevel then
                    shouldAutoSave = true
                    changeType = "UPGRADE_PURCHASE"
                    changeDetails = string.format("%s: %d -> %d", upgradeType, oldLevel, newLevel)
                end
            end
        end
        -- Save on cosmetic/progression changes
        if #(oldData.ownedSkins or {}) ~= #(newData.ownedSkins or {}) then
            shouldAutoSave = true
            changeType = "COSMETIC_UNLOCK"
            changeDetails = "New skin unlocked"
        end
        if #(oldData.ownedTrails or {}) ~= #(newData.ownedTrails or {}) then
            shouldAutoSave = true
            changeType = "TRAIL_UNLOCK"
            changeDetails = "New trail unlocked"
        end
        if (oldData.equippedTrail or "") ~= (newData.equippedTrail or "") then
            shouldAutoSave = true
            changeType = "TRAIL_EQUIP"
            changeDetails = string.format("Trail: %s -> %s", oldData.equippedTrail or "none", newData.equippedTrail or "none")
        end
        if #(oldData.ownedPets or {}) ~= #(newData.ownedPets or {}) then
            shouldAutoSave = true
            changeType = "COSMETIC_UNLOCK"
            changeDetails = "New pet unlocked"
        end
        if (oldData.activePet or "") ~= (newData.activePet or "") then
            shouldAutoSave = true
            changeType = "COSMETIC_UNLOCK"
            changeDetails = "Pet equipped"
        end
        if #(oldData.tournamentPrizes or {}) ~= #(newData.tournamentPrizes or {}) then
            shouldAutoSave = true
            changeType = "COSMETIC_UNLOCK"
            changeDetails = "Tournament prize earned"
        end
        
        if shouldAutoSave then
            -- Use immediate save for critical changes
            DataService:ImmediateSave(player, newData, string.format("%s: %s", changeType, changeDetails))
        end
        
        -- Notify LeaderboardService of data change
        if LeaderboardService then
            LeaderboardService:OnPlayerDataUpdated(player, newData)
        end
        
        -- Update achievements when player data changes
        if AchievementService then
            -- Check for achievement progress updates
            if oldData.gamesPlayed ~= newData.gamesPlayed then
                AchievementService:UpdatePlayerProgress(player, "gamesPlayed", newData.gamesPlayed)
            end
            if oldData.totalCoinsEarned ~= newData.totalCoinsEarned then
                AchievementService:UpdatePlayerProgress(player, "totalCoinsEarned", newData.totalCoinsEarned)
            end
            if oldData.level ~= newData.level then
                AchievementService:UpdatePlayerProgress(player, "level", newData.level)
            end
            if oldData.highScore ~= newData.highScore then
                AchievementService:UpdatePlayerProgress(player, "highScore", newData.highScore)
            end
        end
        
        -- Notify client
        RemoteEvents.PlayerDataUpdated:FireClient(player, newData)
    end
end

function PlayerService:ValidateUpgradeData(player)
    -- Ensure upgrade data consistency
    local data = playerData[player.UserId]
    if not data then
        return
    end
    
    -- Initialize upgrade tables if missing
    if not data.ownedUpgrades then
        data.ownedUpgrades = {}
    end
    if not data.upgrades then
        data.upgrades = {}
    end
    
    -- Sync upgrade levels with owned upgrades
    if ShopService then
        local allItems = ShopService:GetShopItems()
        
        -- Reset upgrade levels
        data.upgrades = {
            speed = 0,
            coinMagnet = 0,
            doubleCoins = 0
        }
        
        -- Recalculate based on owned upgrades
        for itemId, owned in pairs(data.ownedUpgrades) do
            if owned then
                for _, item in pairs(allItems) do
                    if item.id == itemId and item.category == "upgrade" then
                        if item.level > (data.upgrades[item.upgradeType] or 0) then
                            data.upgrades[item.upgradeType] = item.level
                        end
                        break
                    end
                end
            end
        end
        
        -- Update the player data
        self:UpdatePlayerData(player, data)
        print("🔧 Validated upgrade data for " .. player.Name)
    end
end

function PlayerService:RefreshPlayerUpgrades(player)
    -- Public function to refresh all upgrades for a player
    self:ValidateUpgradeData(player)
    self:ApplyStoredUpgrades(player)
    
    if player.Character then
        self:ApplyCharacterUpgrades(player, player.Character)
    end
    
    print("🔄 Refreshed all upgrades for " .. player.Name)
end

function PlayerService:SetLeaderboardService(service)
    LeaderboardService = service
end

function PlayerService:SetShopService(service)
    ShopService = service
end

function PlayerService:SetAnalyticsService(service)
    AnalyticsService = service
end

function PlayerService:SetMonetizationService(service)
    MonetizationService = service
end

function PlayerService:SetAchievementService(service)
    AchievementService = service
end

function PlayerService:Init()
    Players.PlayerAdded:Connect(function(player)
        self:OnPlayerAdded(player)
    end)
    
    Players.PlayerRemoving:Connect(function(player)
        self:OnPlayerRemoving(player)
    end)
    
    -- Set up remote event handlers
    self:SetupRemoteEvents()
    
    function PlayerService:CheckForNewPlayerTutorial(player)
    -- Check if this is a new player who hasn't completed the tutorial
    local data = playerData[player.UserId]
    if not data then
        warn("❌ No player data found for tutorial check: " .. player.Name)
        return
    end
    
    -- Check if tutorial hasn't been completed
    if not data.tutorialCompleted then
        print("🎓 Starting new player tutorial for " .. player.Name)
        
        -- Fire the tutorial start event to the client
        RemoteEvents.StartNewPlayerTutorial:FireClient(player)
        
        -- Track analytics
        if AnalyticsService then
            AnalyticsService:LogEvent(player, "tutorial_started", {
                isNewPlayer = true,
                gamesPlayed = data.gamesPlayed,
                joinDate = data.joinDate
            })
        end
        
        -- Mark tutorial as started (will be marked completed when player finishes)
        data.tutorialStarted = true
        self:UpdatePlayerData(player, data)
    else
        print("✅ " .. player.Name .. " has already completed the tutorial")
    end
end

function PlayerService:CompleteTutorial(player)
    -- Mark tutorial as completed for the player
    local data = playerData[player.UserId]
    if not data then
        warn("❌ No player data found for tutorial completion: " .. player.Name)
        return
    end
    
    data.tutorialCompleted = true
    self:UpdatePlayerData(player, data)
    
    -- Give a small welcome bonus
    data.coins = data.coins + 100
    self:UpdatePlayerData(player, data)
    
    -- Track analytics
    if AnalyticsService then
        AnalyticsService:LogEvent(player, "tutorial_completed", {
            timeToComplete = tick() - (data.joinDate or 0),
            gamesPlayed = data.gamesPlayed,
            coinsEarned = data.totalCoinsEarned
        })
    end
    
    print("🎉 " .. player.Name .. " completed the new player tutorial! (+100 coins)")
    
    -- Send updated data to client
    RemoteEvents.PlayerDataUpdated:FireClient(player, data)
end

-- Remote event connections
function PlayerService:SetupRemoteEvents()
    -- Handle purchase requests
    RemoteEvents.PurchaseItem.OnServerEvent:Connect(function(player, itemName, cost)
        self:HandlePurchase(player, itemName, cost)
    end)
    
    -- Handle color change requests
    RemoteEvents.PlayerColorChanged.OnServerEvent:Connect(function(player, colorName)
        self:HandleColorChange(player, colorName)
    end)
    
    -- Handle accessibility settings updates
    RemoteEvents.UpdatePlayerSettings.OnServerEvent:Connect(function(player, settingKey, value)
        self:UpdatePlayerSetting(player, settingKey, value)
    end)
    
    RemoteEvents.ToggleColorblindMode.OnServerEvent:Connect(function(player, enabled)
        self:UpdatePlayerSetting(player, "colorblindMode", enabled)
    end)
    
    RemoteEvents.ToggleControllerSupport.OnServerEvent:Connect(function(player, enabled)
        self:UpdatePlayerSetting(player, "controllerEnabled", enabled)
    end)
    
    -- Handle tutorial completion
    RemoteEvents.CompleteTutorial.OnServerEvent:Connect(function(player)
        self:CompleteTutorial(player)
    end)
    
    -- Handle quest progress updates
    RemoteEvents.UpdateQuestProgress.OnServerEvent:Connect(function(player, questType, amount, extraData)
        -- Forward to QuestService if available
        local success, QuestService = pcall(require, script.Parent.QuestService)
        if success and QuestService then
            QuestService:UpdateQuestProgress(player, questType, amount, extraData)
        end
    end)
    
    -- Handle manual save requests
    RemoteEvents.RequestManualSave.OnServerEvent:Connect(function(player, reason)
        if DataService then
            local data = self:GetPlayerData(player)
            if data then
                DataService:SavePlayerData(player, data, reason or "Manual save")
            end
        end
    end)
    
    -- Handle players already in game
    for _, player in pairs(Players:GetPlayers()) do
        self:OnPlayerAdded(player)
        
        -- Apply upgrades to existing characters
        if player.Character then
            spawn(function()
                wait(0.5) -- Small delay to ensure services are fully connected
                self:ApplyCharacterUpgrades(player, player.Character)
            end)
        end
    end
    
    print("✅ PlayerService initialized")
end

return PlayerService
