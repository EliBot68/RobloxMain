-- PartyService.luau
-- Handles party formation, management, and group gameplay features

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local DataStoreService = game:GetService("DataStoreService")
local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local PlayerService = require(script.Parent.PlayerService)
local GameService = require(script.Parent.GameService)
local LevelingService = require(script.Parent.LevelingService)
local RemoteEvents = require(ReplicatedStorage.Shared.modules.RemoteEvents)

local PartyService = {}

-- Party data storage
local parties = {} -- [partyId] = {leader, members, created, settings}
local playerParties = {} -- [userId] = partyId
local partyInvites = {} -- [userId] = {[fromUserId] = inviteData}

-- Party configuration
local MAX_PARTY_SIZE = 4
local PARTY_XP_BONUS = 0.25 -- 25% bonus XP when in party
local INVITE_TIMEOUT = 60 -- 60 seconds for invite to expire

function PartyService:GeneratePartyId()
    -- Generate unique party ID
    local id = "party_" .. tostring(os.time()) .. "_" .. tostring(math.random(1000, 9999))
    while parties[id] do
        id = "party_" .. tostring(os.time()) .. "_" .. tostring(math.random(1000, 9999))
    end
    return id
end

function PartyService:CreateParty(leader)
    local userId = tostring(leader.UserId)
    
    -- Check if player is already in a party
    if playerParties[userId] then
        return false, "You are already in a party"
    end
    
    local partyId = self:GeneratePartyId()
    
    -- Create party data
    parties[partyId] = {
        id = partyId,
        leader = userId,
        members = {userId},
        created = os.time(),
        settings = {
            autoStart = true,
            openToFriends = true,
            xpSharing = true
        },
        gameState = {
            inGame = false,
            gameId = nil,
            startTime = nil
        }
    }
    
    playerParties[userId] = partyId
    
    -- Notify client
    RemoteEvents.PartyCreated:FireClient(leader, partyId, parties[partyId])
    
    print("🎉 " .. leader.Name .. " created party: " .. partyId)
    return true, partyId
end

function PartyService:JoinParty(player, partyId)
    local userId = tostring(player.UserId)
    
    -- Check if player is already in a party
    if playerParties[userId] then
        return false, "You are already in a party"
    end
    
    -- Check if party exists
    local party = parties[partyId]
    if not party then
        return false, "Party not found"
    end
    
    -- Check party size
    if #party.members >= MAX_PARTY_SIZE then
        return false, "Party is full"
    end
    
    -- Check if party is in game
    if party.gameState.inGame then
        return false, "Party is currently in a game"
    end
    
    -- Add player to party
    table.insert(party.members, userId)
    playerParties[userId] = partyId
    
    -- Notify all party members
    for _, memberId in pairs(party.members) do
        local member = Players:GetPlayerByUserId(tonumber(memberId))
        if member then
            RemoteEvents.PartyMemberJoined:FireClient(member, player.Name, party)
        end
    end
    
    print("👥 " .. player.Name .. " joined party: " .. partyId)
    return true, party
end

function PartyService:LeaveParty(player)
    local userId = tostring(player.UserId)
    local partyId = playerParties[userId]
    
    if not partyId then
        return false, "You are not in a party"
    end
    
    local party = parties[partyId]
    if not party then
        return false, "Party not found"
    end
    
    -- Remove player from party
    for i, memberId in pairs(party.members) do
        if memberId == userId then
            table.remove(party.members, i)
            break
        end
    end
    
    playerParties[userId] = nil
    
    -- If leaving player was leader, transfer leadership or disband
    if party.leader == userId then
        if #party.members > 0 then
            -- Transfer leadership to next member
            party.leader = party.members[1]
            local newLeader = Players:GetPlayerByUserId(tonumber(party.leader))
            if newLeader then
                RemoteEvents.PartyLeaderChanged:FireClient(newLeader, party)
            end
        else
            -- Disband party if no members left
            self:DisbandParty(partyId)
            RemoteEvents.PartyLeft:FireClient(player, "Party disbanded")
            return true, "Party disbanded"
        end
    end
    
    -- Notify remaining party members
    for _, memberId in pairs(party.members) do
        local member = Players:GetPlayerByUserId(tonumber(memberId))
        if member then
            RemoteEvents.PartyMemberLeft:FireClient(member, player.Name, party)
        end
    end
    
    RemoteEvents.PartyLeft:FireClient(player, "Left party")
    print("👋 " .. player.Name .. " left party: " .. partyId)
    return true, "Left party"
end

function PartyService:DisbandParty(partyId)
    local party = parties[partyId]
    if not party then return end
    
    -- Remove all members from party tracking
    for _, memberId in pairs(party.members) do
        playerParties[memberId] = nil
        local member = Players:GetPlayerByUserId(tonumber(memberId))
        if member then
            RemoteEvents.PartyDisbanded:FireClient(member)
        end
    end
    
    -- Remove party
    parties[partyId] = nil
    print("💥 Party disbanded: " .. partyId)
end

function PartyService:SendPartyInvite(inviter, targetPlayer)
    local inviterId = tostring(inviter.UserId)
    local targetId = tostring(targetPlayer.UserId)
    
    -- Check if inviter is in a party
    local partyId = playerParties[inviterId]
    if not partyId then
        return false, "You must be in a party to send invites"
    end
    
    local party = parties[partyId]
    if not party then
        return false, "Party not found"
    end
    
    -- Check if inviter is party leader
    if party.leader ~= inviterId then
        return false, "Only the party leader can send invites"
    end
    
    -- Check if target is already in a party
    if playerParties[targetId] then
        return false, targetPlayer.Name .. " is already in a party"
    end
    
    -- Check party size
    if #party.members >= MAX_PARTY_SIZE then
        return false, "Party is full"
    end
    
    -- Check if target already has an invite from this player
    if partyInvites[targetId] and partyInvites[targetId][inviterId] then
        return false, "Invite already sent to " .. targetPlayer.Name
    end
    
    -- Create invite
    if not partyInvites[targetId] then
        partyInvites[targetId] = {}
    end
    
    partyInvites[targetId][inviterId] = {
        partyId = partyId,
        inviterName = inviter.Name,
        inviterId = inviterId,
        timestamp = os.time(),
        expires = os.time() + INVITE_TIMEOUT
    }
    
    -- Send invite to target player
    RemoteEvents.PartyInviteReceived:FireClient(targetPlayer, {
        partyId = partyId,
        inviterName = inviter.Name,
        inviterId = inviterId,
        partySize = #party.members,
        maxSize = MAX_PARTY_SIZE
    })
    
    -- Notify inviter
    RemoteEvents.PartyInviteSent:FireClient(inviter, targetPlayer.Name)
    
    -- Auto-expire invite
    spawn(function()
        wait(INVITE_TIMEOUT)
        if partyInvites[targetId] and partyInvites[targetId][inviterId] then
            partyInvites[targetId][inviterId] = nil
            RemoteEvents.PartyInviteExpired:FireClient(targetPlayer, inviter.Name)
        end
    end)
    
    print("📧 " .. inviter.Name .. " invited " .. targetPlayer.Name .. " to party")
    return true, "Invite sent to " .. targetPlayer.Name
end

function PartyService:AcceptPartyInvite(player, inviterId)
    local userId = tostring(player.UserId)
    local inviterIdStr = tostring(inviterId)
    
    -- Check if invite exists
    if not partyInvites[userId] or not partyInvites[userId][inviterIdStr] then
        return false, "Invite not found or expired"
    end
    
    local invite = partyInvites[userId][inviterIdStr]
    
    -- Check if invite is still valid
    if os.time() > invite.expires then
        partyInvites[userId][inviterIdStr] = nil
        return false, "Invite has expired"
    end
    
    -- Join the party
    local success, result = self:JoinParty(player, invite.partyId)
    
    if success then
        -- Clear the invite
        partyInvites[userId][inviterIdStr] = nil
        
        -- Notify inviter
        local inviter = Players:GetPlayerByUserId(tonumber(inviterIdStr))
        if inviter then
            RemoteEvents.PartyInviteAccepted:FireClient(inviter, player.Name)
        end
    end
    
    return success, result
end

function PartyService:DeclinePartyInvite(player, inviterId)
    local userId = tostring(player.UserId)
    local inviterIdStr = tostring(inviterId)
    
    -- Remove invite
    if partyInvites[userId] and partyInvites[userId][inviterIdStr] then
        partyInvites[userId][inviterIdStr] = nil
        
        -- Notify inviter
        local inviter = Players:GetPlayerByUserId(tonumber(inviterIdStr))
        if inviter then
            RemoteEvents.PartyInviteDeclined:FireClient(inviter, player.Name)
        end
        
        return true, "Invite declined"
    end
    
    return false, "Invite not found"
end

function PartyService:GetPlayerParty(player)
    local userId = tostring(player.UserId)
    local partyId = playerParties[userId]
    
    if partyId then
        return parties[partyId]
    end
    
    return nil
end

function PartyService:StartPartyGame(partyId, gameData)
    local party = parties[partyId]
    if not party then return false end
    
    -- Mark party as in game
    party.gameState.inGame = true
    party.gameState.gameId = gameData.gameId
    party.gameState.startTime = os.time()
    
    -- Teleport all party members to game
    for _, memberId in pairs(party.members) do
        local member = Players:GetPlayerByUserId(tonumber(memberId))
        if member then
            -- Use GameService to start game for member
            if GameService then
                GameService:StartGame(member, gameData)
            end
        end
    end
    
    print("🎮 Party " .. partyId .. " started game together")
    return true
end

function PartyService:EndPartyGame(partyId, gameResults)
    local party = parties[partyId]
    if not party then return end
    
    -- Calculate party XP bonus
    local baseXp = gameResults.xpEarned or 0
    local bonusXp = math.floor(baseXp * PARTY_XP_BONUS)
    
    -- Apply bonus XP to all party members
    for _, memberId in pairs(party.members) do
        local member = Players:GetPlayerByUserId(tonumber(memberId))
        if member then
            if LevelingService then
                LevelingService:GiveXP(member, bonusXp, "Party Bonus")
            end
            
            -- Notify about party bonus
            RemoteEvents.PartyXpBonus:FireClient(member, bonusXp, #party.members)
        end
    end
    
    -- Reset party game state
    party.gameState.inGame = false
    party.gameState.gameId = nil
    party.gameState.startTime = nil
    
    print("🎊 Party " .. partyId .. " completed game with " .. bonusXp .. " bonus XP each")
end

function PartyService:GetPartyXpMultiplier(player)
    local party = self:GetPlayerParty(player)
    if party and #party.members > 1 then
        return 1 + PARTY_XP_BONUS
    end
    return 1
end

function PartyService:SetupPartyArea()
    -- Create party formation area in hub
    local marketPlaza = Workspace:FindFirstChild("MarketPlaza")
    if not marketPlaza then return end
    
    local partyArea = Instance.new("Part")
    partyArea.Name = "PartyArea"
    partyArea.Size = Vector3.new(15, 1, 15)
    partyArea.Position = Vector3.new(25, 2, 0) -- Near market plaza
    partyArea.Material = Enum.Material.Neon
    partyArea.Color = Color3.new(0.2, 0.8, 1)
    partyArea.Anchored = true
    partyArea.CanCollide = false
    partyArea.Transparency = 0.7
    partyArea.Parent = marketPlaza
    
    -- Add party sign
    local sign = Instance.new("Part")
    sign.Name = "PartySign"
    sign.Size = Vector3.new(8, 6, 0.5)
    sign.Position = partyArea.Position + Vector3.new(0, 4, -8)
    sign.Material = Enum.Material.SmoothPlastic
    sign.Color = Color3.new(0.1, 0.1, 0.2)
    sign.Anchored = true
    sign.Parent = marketPlaza
    
    -- Add sign GUI
    local signGui = Instance.new("SurfaceGui")
    signGui.Face = Enum.NormalId.Front
    signGui.Parent = sign
    
    local titleLabel = Instance.new("TextLabel")
    titleLabel.Size = UDim2.new(1, 0, 0.4, 0)
    titleLabel.Position = UDim2.new(0, 0, 0, 0)
    titleLabel.BackgroundTransparency = 1
    titleLabel.Text = "👥 PARTY ZONE 👥"
    titleLabel.TextColor3 = Color3.new(1, 1, 1)
    titleLabel.TextScaled = true
    titleLabel.Font = Enum.Font.SourceSansBold
    titleLabel.TextStrokeTransparency = 0
    titleLabel.Parent = signGui
    
    local infoLabel = Instance.new("TextLabel")
    infoLabel.Size = UDim2.new(1, 0, 0.6, 0)
    infoLabel.Position = UDim2.new(0, 0, 0.4, 0)
    infoLabel.BackgroundTransparency = 1
    infoLabel.Text = "Form parties with friends!\n+25% XP when playing together\nMax 4 players per party"
    infoLabel.TextColor3 = Color3.new(0.8, 0.8, 0.8)
    infoLabel.TextScaled = true
    infoLabel.Font = Enum.Font.SourceSans
    infoLabel.TextStrokeTransparency = 0
    infoLabel.Parent = signGui
    
    -- Add click detector for party management
    local clickDetector = Instance.new("ClickDetector")
    clickDetector.MaxActivationDistance = 20
    clickDetector.Parent = sign
    
    clickDetector.MouseClick:Connect(function(player)
        RemoteEvents.ShowPartyUI:FireClient(player)
    end)
    
    -- Add floating animation
    local floatTween = TweenService:Create(
        partyArea,
        TweenInfo.new(4, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true),
        {Position = partyArea.Position + Vector3.new(0, 0.5, 0)}
    )
    floatTween:Play()
    
    print("👥 Party area created in hub")
end

function PartyService:CleanupDisconnectedPlayers()
    -- Clean up parties when players disconnect
    for userId, partyId in pairs(playerParties) do
        local player = Players:GetPlayerByUserId(tonumber(userId))
        if not player then
            -- Player disconnected, remove from party
            local party = parties[partyId]
            if party then
                for i, memberId in pairs(party.members) do
                    if memberId == userId then
                        table.remove(party.members, i)
                        break
                    end
                end
                
                -- Handle leadership transfer or disbanding
                if party.leader == userId then
                    if #party.members > 0 then
                        party.leader = party.members[1]
                    else
                        self:DisbandParty(partyId)
                    end
                end
                
                -- Notify remaining members
                for _, memberId in pairs(party.members) do
                    local member = Players:GetPlayerByUserId(tonumber(memberId))
                    if member then
                        RemoteEvents.PartyMemberLeft:FireClient(member, "Player", party)
                    end
                end
            end
            
            playerParties[userId] = nil
        end
    end
end

function PartyService:Initialize()
    print("👥 PartyService initializing...")
    
    -- Wait for workspace to be ready
    wait(2)
    
    -- Setup party area in hub
    self:SetupPartyArea()
    
    -- Start cleanup timer
    spawn(function()
        while true do
            wait(30) -- Check every 30 seconds
            self:CleanupDisconnectedPlayers()
        end
    end)
    
    print("✅ PartyService initialized successfully!")
end

-- Handle player leaving
local function onPlayerRemoving(player)
    PartyService:LeaveParty(player)
end

Players.PlayerRemoving:Connect(onPlayerRemoving)

-- Remote event handlers
RemoteEvents.CreateParty.OnServerEvent:Connect(function(player)
    local success, result = PartyService:CreateParty(player)
    RemoteEvents.PartyActionResult:FireClient(player, success, result)
end)

RemoteEvents.LeaveParty.OnServerEvent:Connect(function(player)
    local success, result = PartyService:LeaveParty(player)
    RemoteEvents.PartyActionResult:FireClient(player, success, result)
end)

RemoteEvents.SendPartyInvite.OnServerEvent:Connect(function(player, targetPlayerId)
    local targetPlayer = Players:GetPlayerByUserId(targetPlayerId)
    if targetPlayer then
        local success, result = PartyService:SendPartyInvite(player, targetPlayer)
        RemoteEvents.PartyActionResult:FireClient(player, success, result)
    end
end)

RemoteEvents.AcceptPartyInvite.OnServerEvent:Connect(function(player, inviterId)
    local success, result = PartyService:AcceptPartyInvite(player, inviterId)
    RemoteEvents.PartyActionResult:FireClient(player, success, result)
end)

RemoteEvents.DeclinePartyInvite.OnServerEvent:Connect(function(player, inviterId)
    local success, result = PartyService:DeclinePartyInvite(player, inviterId)
    RemoteEvents.PartyActionResult:FireClient(player, success, result)
end)

RemoteEvents.GetPlayerParty.OnServerEvent:Connect(function(player)
    local party = PartyService:GetPlayerParty(player)
    RemoteEvents.PlayerPartyData:FireClient(player, party)
end)

-- Auto-initialize
PartyService:Initialize()

return PartyService
