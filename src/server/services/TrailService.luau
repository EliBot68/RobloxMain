-- TrailService.luau
-- Server-side trail management and crate system

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local RemoteEvents = require(ReplicatedStorage.Shared.modules.RemoteEvents)

-- Import DataService for integrated data persistence
local DataService = require(script.Parent.DataService)

-- Import PlayerService for data access
local PlayerService = nil

local TrailService = {}

-- Player data cache (now integrated with main data system)
local playerTrailData = {}

-- Crate system configuration
local CRATE_COST = 500 -- Coins
local CRATE_ITEMS = {
    {id = "common_sparkle", name = "Sparkle Trail", rarity = "Common", weight = 50},
    {id = "rare_flame", name = "Flame Trail", rarity = "Rare", weight = 30},
    {id = "epic_rainbow", name = "Rainbow Trail", rarity = "Epic", weight = 20},
}

function TrailService:Init()
    self:SetupRemoteEvents()
    self:SetupPlayerEvents()
    print("🌟 TrailService initialized")
end

function TrailService:SetupRemoteEvents()
    -- Handle crate spinning requests
    RemoteEvents.SpinCrate.OnServerEvent:Connect(function(player)
        self:HandleCrateSpin(player)
    end)
    
    -- Handle trail equip requests
    RemoteEvents.EquipTrail.OnServerEvent:Connect(function(player, trailId)
        self:EquipPlayerTrail(player, trailId)
    end)
    
    -- Handle trail unequip requests
    RemoteEvents.UnequipTrail.OnServerEvent:Connect(function(player)
        self:UnequipPlayerTrail(player)
    end)
    
    -- Handle trail data requests
    RemoteEvents.GetPlayerTrails.OnServerEvent:Connect(function(player)
        self:SendPlayerTrailData(player)
    end)
end

function TrailService:SetupPlayerEvents()
    -- Handle player joining
    Players.PlayerAdded:Connect(function(player)
        self:LoadPlayerTrailData(player)
    end)
    
    -- Handle player leaving
    Players.PlayerRemoving:Connect(function(player)
        self:SavePlayerTrailData(player)
        playerTrailData[player.UserId] = nil
    end)
end

function TrailService:LoadPlayerTrailData(player)
    -- Get trail data from main player data system
    if not PlayerService then
        warn("❌ PlayerService not available for trail data")
        return
    end
    
    local playerData = PlayerService:GetPlayerData(player)
    if playerData then
        local userId = player.UserId
        playerTrailData[userId] = {
            ownedTrails = playerData.ownedTrails or {"common_sparkle"},
            equippedTrail = playerData.equippedTrail
        }
        
        -- Ensure basic trail is always owned
        if not table.find(playerTrailData[userId].ownedTrails, "common_sparkle") then
            table.insert(playerTrailData[userId].ownedTrails, "common_sparkle")
            self:SavePlayerTrailData(player)
        end
    else
        -- Fallback for new players
        local userId = player.UserId
        playerTrailData[userId] = {
            ownedTrails = {"common_sparkle"},
            equippedTrail = nil
        }
    end
    
    -- Send initial trail data to client
    spawn(function()
        wait(1) -- Wait for client to initialize
        self:SendPlayerTrailData(player)
    end)
end

function TrailService:SavePlayerTrailData(player)
    -- Save trail data through main data system for consistency
    if not PlayerService then
        warn("❌ PlayerService not available for trail save")
        return
    end
    
    local userId = player.UserId
    local trailData = playerTrailData[userId]
    
    if not trailData then return end
    
    -- Update main player data
    local playerData = PlayerService:GetPlayerData(player)
    if playerData then
        playerData.ownedTrails = trailData.ownedTrails
        playerData.equippedTrail = trailData.equippedTrail
        
        -- Trigger immediate save for trail changes
        DataService:TriggerImmediateSaveForCriticalChange(player, "TRAIL_UPDATE", "Trail data modified")
        
        -- Update player data through PlayerService
        PlayerService:UpdatePlayerData(player, playerData)
    end
end

function TrailService:SendPlayerTrailData(player)
    local userId = player.UserId
    local data = playerTrailData[userId]
    
    if data then
        RemoteEvents.PlayerTrailsUpdate:FireClient(player, data.ownedTrails, data.equippedTrail)
    end
end

function TrailService:HandleCrateSpin(player)
    local userId = player.UserId
    
    -- Check if player has enough coins
    local currentCoins = self:GetPlayerCoins(player)
    if currentCoins < CRATE_COST then
        RemoteEvents.CrateOpenResult:FireClient(player, false, nil, "Not enough coins! Need " .. CRATE_COST .. " coins.")
        return
    end
    
    -- Deduct coins
    local coinDeductSuccess = self:DeductPlayerCoins(player, CRATE_COST)
    if not coinDeductSuccess then
        RemoteEvents.CrateOpenResult:FireClient(player, false, nil, "Failed to deduct coins.")
        return
    end
    
    -- Roll for crate item
    local wonItem = self:RollCrateItem()
    if not wonItem then
        RemoteEvents.CrateOpenResult:FireClient(player, false, nil, "Crate rolling failed.")
        return
    end
    
    -- Add trail to player's collection if not already owned
    local playerData = playerTrailData[userId]
    if not playerData then
        playerData = {ownedTrails = {"common_sparkle"}, equippedTrail = nil}
        playerTrailData[userId] = playerData
    end
    
    local alreadyOwned = table.find(playerData.ownedTrails, wonItem.id) ~= nil
    
    if not alreadyOwned then
        table.insert(playerData.ownedTrails, wonItem.id)
        
        -- Trigger immediate save for crate opening
        DataService:TriggerImmediateSaveForCriticalChange(player, "CRATE_OPEN", "Won new trail: " .. wonItem.name)
        self:SavePlayerTrailData(player)
        self:SendPlayerTrailData(player)
        
        RemoteEvents.CrateOpenResult:FireClient(player, true, wonItem, "Congratulations! You won a new trail!")
    else
        -- Convert duplicate to coins (could implement different reward)
        local bonusCoins = math.floor(CRATE_COST * 0.5) -- 50% refund for duplicates
        self:AddPlayerCoins(player, bonusCoins)
        
        RemoteEvents.CrateOpenResult:FireClient(player, true, wonItem, "You already own this trail! Received " .. bonusCoins .. " bonus coins instead.")
    end
end

function TrailService:RollCrateItem()
    -- Calculate total weight
    local totalWeight = 0
    for _, item in ipairs(CRATE_ITEMS) do
        totalWeight = totalWeight + item.weight
    end
    
    -- Roll random number
    local roll = math.random(1, totalWeight)
    
    -- Find winning item
    local currentWeight = 0
    for _, item in ipairs(CRATE_ITEMS) do
        currentWeight = currentWeight + item.weight
        if roll <= currentWeight then
            return item
        end
    end
    
    -- Fallback to first item
    return CRATE_ITEMS[1]
end

function TrailService:EquipPlayerTrail(player, trailId)
    local userId = player.UserId
    local playerData = playerTrailData[userId]
    
    if not playerData then
        RemoteEvents.TrailEquipResult:FireClient(player, false, trailId, "No trail data found.")
        return
    end
    
    -- Check if player owns this trail
    local ownsTrail = table.find(playerData.ownedTrails, trailId) ~= nil
    if not ownsTrail then
        RemoteEvents.TrailEquipResult:FireClient(player, false, trailId, "You don't own this trail.")
        return
    end
    
    -- Equip the trail
    playerData.equippedTrail = trailId
    
    -- Trigger immediate save for trail equipment change
    DataService:TriggerImmediateSaveForCriticalChange(player, "TRAIL_EQUIP", "Equipped trail: " .. trailId)
    self:SavePlayerTrailData(player)
    self:SendPlayerTrailData(player)
    
    RemoteEvents.TrailEquipResult:FireClient(player, true, trailId, "Trail equipped successfully!")
end

function TrailService:UnequipPlayerTrail(player)
    local userId = player.UserId
    local playerData = playerTrailData[userId]
    
    if not playerData then
        RemoteEvents.TrailEquipResult:FireClient(player, false, nil, "No trail data found.")
        return
    end
    
    -- Unequip current trail
    local previousTrail = playerData.equippedTrail
    playerData.equippedTrail = nil
    
    -- Trigger immediate save for trail unequip
    DataService:TriggerImmediateSaveForCriticalChange(player, "TRAIL_EQUIP", "Unequipped trail: " .. (previousTrail or "none"))
    self:SavePlayerTrailData(player)
    self:SendPlayerTrailData(player)
    
    RemoteEvents.TrailEquipResult:FireClient(player, true, nil, "Trail unequipped successfully!")
end

function TrailService:GetPlayerCoins(player)
    -- This should integrate with your existing coin system
    -- For now, we'll use leaderstats if available
    local leaderstats = player:FindFirstChild("leaderstats")
    if leaderstats then
        local coins = leaderstats:FindFirstChild("Coins")
        if coins then
            return coins.Value
        end
    end
    
    -- Fallback: check for coin data service
    if game.ServerStorage:FindFirstChild("CoinService") then
        local CoinService = require(game.ServerStorage.CoinService)
        if CoinService.GetPlayerCoins then
            return CoinService:GetPlayerCoins(player)
        end
    end
    
    return 0
end

function TrailService:DeductPlayerCoins(player, amount)
    -- This should integrate with your existing coin system
    local leaderstats = player:FindFirstChild("leaderstats")
    if leaderstats then
        local coins = leaderstats:FindFirstChild("Coins")
        if coins and coins.Value >= amount then
            coins.Value = coins.Value - amount
            return true
        end
    end
    
    -- Fallback: check for coin data service
    if game.ServerStorage:FindFirstChild("CoinService") then
        local CoinService = require(game.ServerStorage.CoinService)
        if CoinService.DeductCoins then
            return CoinService:DeductCoins(player, amount)
        end
    end
    
    return false
end

function TrailService:AddPlayerCoins(player, amount)
    -- This should integrate with your existing coin system
    local leaderstats = player:FindFirstChild("leaderstats")
    if leaderstats then
        local coins = leaderstats:FindFirstChild("Coins")
        if coins then
            coins.Value = coins.Value + amount
            return true
        end
    end
    
    -- Fallback: check for coin data service
    if game.ServerStorage:FindFirstChild("CoinService") then
        local CoinService = require(game.ServerStorage.CoinService)
        if CoinService.AddCoins then
            return CoinService:AddCoins(player, amount)
        end
    end
    
    return false
end

function TrailService:GetPlayerTrailData(player)
    local userId = player.UserId
    return playerTrailData[userId]
end

function TrailService:GiveTrailToPlayer(player, trailId)
    -- Admin function to give trails to players
    local userId = player.UserId
    local playerData = playerTrailData[userId]
    
    if not playerData then
        playerData = {ownedTrails = {}, equippedTrail = nil}
        playerTrailData[userId] = playerData
    end
    
    if not table.find(playerData.ownedTrails, trailId) then
        table.insert(playerData.ownedTrails, trailId)
        self:SavePlayerTrailData(player)
        self:SendPlayerTrailData(player)
        return true
    end
    
    return false -- Already owned
end

function TrailService:ShowCrateMachineToPlayer(player)
    -- Function to trigger crate machine GUI (called from interaction)
    RemoteEvents.ShowCrateMachine:FireClient(player)
end

function TrailService:ShowTrailManagerToPlayer(player)
    -- Function to trigger trail manager GUI (called from interaction)
    RemoteEvents.ShowTrailManager:FireClient(player)
end

-- Service dependency setters
function TrailService:SetPlayerService(service)
    PlayerService = service
end

-- Auto-save all player data periodically using heartbeat
local RunService = game:GetService("RunService")
local lastSaveTime = 0
local saveInterval = 300 -- Save every 5 minutes

local saveConnection = RunService.Heartbeat:Connect(function()
    local currentTime = tick()
    if currentTime - lastSaveTime >= saveInterval then
        lastSaveTime = currentTime
        for _, player in ipairs(Players:GetPlayers()) do
            if playerTrailData[player.UserId] then
                TrailService:SavePlayerTrailData(player)
            end
        end
    end
end)

return TrailService
