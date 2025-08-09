-- SocialService.luau
-- Comprehensive friend management and social engagement system

local Players = game:GetService("Players")
local DataStoreService = game:GetService("DataStoreService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local HttpService = game:GetService("HttpService")
local RunService = game:GetService("RunService")

local Services = require(game.ReplicatedStorage.Shared.core.Services)
local RemoteEvents = require(game.ReplicatedStorage.Shared.modules.RemoteEvents)
local WorldObjectValidator = require(game.ReplicatedStorage.Shared.utils.WorldObjectValidator)

local SocialService = {}

-- DataStores
local friendsStore = DataStoreService:GetDataStore("PlayerFriends")
local socialDataStore = DataStoreService:GetDataStore("SocialData")
local challengeStore = DataStoreService:GetDataStore("PlayerChallenges")

-- Cache
local playerFriends = {} -- [userId] = {friends = {}, requests = {}}
local onlineStatus = {} -- [userId] = true/false
local socialStats = {} -- [userId] = {likes = 0, shares = 0, challenges = 0}
local activeChallenges = {} -- [challengeId] = challengeData

-- Constants
local MAX_FRIENDS = 100
local MAX_FRIEND_REQUESTS = 20
local CHALLENGE_DURATION = 300 -- 5 minutes

--[[
    Initializes the SocialService and sets up all necessary connections and systems.
    This is called automatically when the service starts.
    
    @return {void}
]]
function SocialService:Initialize()
    print("🤝 Initializing SocialService...")
    
    self:SetupEventConnections()
    self:StartSocialUpdates()
    
    -- Handle player connections
    Players.PlayerAdded:Connect(function(player)
        self:PlayerJoined(player)
    end)
    
    Players.PlayerRemoving:Connect(function(player)
        self:PlayerLeft(player)
    end)
    
    print("✅ SocialService initialized successfully!")
end

--[[
    Sets up all remote event connections for the social system.
    Handles friend requests, social engagement, and challenge events.
    
    @return {void}
]]
function SocialService:SetupEventConnections()
    -- Friend system events
    RemoteEvents.SendFriendRequest.OnServerEvent:Connect(function(player, targetUserId)
        self:SendFriendRequest(player, targetUserId)
    end)
    
    RemoteEvents.AcceptFriendRequest.OnServerEvent:Connect(function(player, requesterId)
        self:AcceptFriendRequest(player, requesterId)
    end)
    
    RemoteEvents.DeclineFriendRequest.OnServerEvent:Connect(function(player, requesterId)
        self:DeclineFriendRequest(player, requesterId)
    end)
    
    RemoteEvents.RemoveFriend.OnServerEvent:Connect(function(player, friendId)
        self:RemoveFriend(player, friendId)
    end)
    
    RemoteEvents.GetFriendsList.OnServerEvent:Connect(function(player)
        self:SendFriendsList(player)
    end)
    
    RemoteEvents.GetFriendRequests.OnServerEvent:Connect(function(player)
        self:SendFriendRequests(player)
    end)
    
    -- Social engagement events
    RemoteEvents.LikePlayerScore.OnServerEvent:Connect(function(player, targetUserId)
        self:LikePlayerScore(player, targetUserId)
    end)
    
    RemoteEvents.ChallengePlayer.OnServerEvent:Connect(function(player, targetUserId, challengeType)
        self:ChallengePlayer(player, targetUserId, challengeType)
    end)
    
    RemoteEvents.ChallengeAccepted.OnServerEvent:Connect(function(player, challengeId)
        self:AcceptChallenge(player, challengeId)
    end)
    
    RemoteEvents.ShareAchievement.OnServerEvent:Connect(function(player, achievementId)
        self:ShareAchievement(player, achievementId)
    end)
    
    -- Leaderboard events
    RemoteEvents.RequestSocialLeaderboard.OnServerEvent:Connect(function(player, leaderboardType)
        self:SendSocialLeaderboard(player, leaderboardType)
    end)
end

--[[
    Handles when a player joins the game. Sets up their online status,
    loads their social data, and notifies friends they're online.
    
    @param player {Player} - The player who joined the game
    @return {void}
]]
function SocialService:PlayerJoined(player)
    local userId = player.UserId
    onlineStatus[userId] = true
    
    -- Load player's social data
    self:LoadPlayerSocialData(player)
    
    -- Notify friends that player is online
    spawn(function()
        self:NotifyFriendsOnline(player)
    end)
end

--[[
    Handles when a player leaves the game. Updates their online status,
    saves their social data, and notifies friends they're offline.
    
    @param player {Player} - The player who left the game
    @return {void}
]]
function SocialService:PlayerLeft(player)
    local userId = player.UserId
    onlineStatus[userId] = false
    
    -- Save social data
    self:SavePlayerSocialData(player)
    
    -- Notify friends that player is offline
    spawn(function()
        self:NotifyFriendsOffline(player)
    end)
end

--[[
    Loads a player's social data from the DataStore including friends,
    friend requests, and social statistics.
    
    @param player {Player} - The player whose data should be loaded
    @return {void}
]]
function SocialService:LoadPlayerSocialData(player)
    local userId = player.UserId
    
    spawn(function()
        local success, friendData = pcall(function()
            return friendsStore:GetAsync(tostring(userId))
        end)
        
        if success and friendData then
            playerFriends[userId] = friendData
        else
            playerFriends[userId] = {
                friends = {},
                sentRequests = {},
                receivedRequests = {}
            }
        end
        
        -- Load social stats
        local success2, socialData = pcall(function()
            return socialDataStore:GetAsync(tostring(userId))
        end)
        
        if success2 and socialData then
            socialStats[userId] = socialData
        else
            socialStats[userId] = {
                likes = 0,
                shares = 0,
                challenges = 0,
                challengesWon = 0
            }
        end
        
        print("📊 Loaded social data for " .. player.Name)
    end)
end

--[[
    Saves a player's social data to the DataStore including friends,
    friend requests, and social statistics.
    
    @param player {Player} - The player whose data should be saved
    @return {void}
]]
function SocialService:SavePlayerSocialData(player)
    local userId = player.UserId
    
    if playerFriends[userId] then
        spawn(function()
            pcall(function()
                friendsStore:SetAsync(tostring(userId), playerFriends[userId])
            end)
        end)
    end
    
    if socialStats[userId] then
        spawn(function()
            pcall(function()
                socialDataStore:SetAsync(tostring(userId), socialStats[userId])
            end)
        end)
    end
end

--[[
    Sends a friend request from one player to another. Validates the request
    and handles friend limits, duplicate requests, and mutual friends.
    
    @param player {Player} - The player sending the friend request
    @param targetUserId {number} - The User ID of the player to send a request to
    @return {void}
]]
function SocialService:SendFriendRequest(player, targetUserId)
    local senderId = player.UserId
    
    -- Validation
    if senderId == targetUserId then
        RemoteEvents.FriendRequestSent:FireClient(player, false, "Cannot send friend request to yourself")
        return
    end
    
    local senderData = playerFriends[senderId] or {friends = {}, sentRequests = {}, receivedRequests = {}}
    
    -- Check if already friends
    if senderData.friends[tostring(targetUserId)] then
        RemoteEvents.FriendRequestSent:FireClient(player, false, "Already friends with this player")
        return
    end
    
    -- Check if request already sent
    if senderData.sentRequests[tostring(targetUserId)] then
        RemoteEvents.FriendRequestSent:FireClient(player, false, "Friend request already sent")
        return
    end
    
    -- Check friend request limit
    local requestCount = 0
    for _ in pairs(senderData.sentRequests) do
        requestCount = requestCount + 1
    end
    
    if requestCount >= MAX_FRIEND_REQUESTS then
        RemoteEvents.FriendRequestSent:FireClient(player, false, "Too many pending friend requests")
        return
    end
    
    -- Add to sender's sent requests
    senderData.sentRequests[tostring(targetUserId)] = {
        timestamp = os.time(),
        playerName = player.Name
    }
    playerFriends[senderId] = senderData
    
    -- Add to target's received requests (load if needed)
    self:AddReceivedFriendRequest(targetUserId, senderId, player.Name)
    
    RemoteEvents.FriendRequestSent:FireClient(player, true, "Friend request sent!")
    
    -- Notify target if online
    local targetPlayer = Players:GetPlayerByUserId(targetUserId)
    if targetPlayer then
        RemoteEvents.FriendRequestReceived:FireClient(targetPlayer, senderId, player.Name)
        self:SendFriendRequests(targetPlayer)
    end
    
    print("📤 " .. player.Name .. " sent friend request to user " .. targetUserId)
end

function SocialService:AddReceivedFriendRequest(targetUserId, senderId, senderName)
    spawn(function()
        local success, targetData = pcall(function()
            return friendsStore:GetAsync(tostring(targetUserId))
        end)
        
        if not success or not targetData then
            targetData = {friends = {}, sentRequests = {}, receivedRequests = {}}
        end
        
        targetData.receivedRequests[tostring(senderId)] = {
            timestamp = os.time(),
            playerName = senderName
        }
        
        -- Save immediately
        pcall(function()
            friendsStore:SetAsync(tostring(targetUserId), targetData)
        end)
        
        -- Update cache if player is online
        if onlineStatus[targetUserId] then
            playerFriends[targetUserId] = targetData
        end
    end)
end

function SocialService:AcceptFriendRequest(player, requesterId)
    local userId = player.UserId
    local playerData = playerFriends[userId]
    
    if not playerData or not playerData.receivedRequests[tostring(requesterId)] then
        RemoteEvents.FriendRequestAccepted:FireClient(player, false, "Friend request not found")
        return
    end
    
    -- Check friend limit
    local friendCount = 0
    for _ in pairs(playerData.friends) do
        friendCount = friendCount + 1
    end
    
    if friendCount >= MAX_FRIENDS then
        RemoteEvents.FriendRequestAccepted:FireClient(player, false, "Friend list is full")
        return
    end
    
    -- Add to both players' friend lists
    local requesterName = playerData.receivedRequests[tostring(requesterId)].playerName
    
    -- Add to accepter's friends
    playerData.friends[tostring(requesterId)] = {
        playerName = requesterName,
        addedTime = os.time()
    }
    
    -- Remove from requests
    playerData.receivedRequests[tostring(requesterId)] = nil
    
    -- Add to requester's friends (load data if needed)
    self:AddMutualFriend(requesterId, userId, player.Name)
    
    RemoteEvents.FriendRequestAccepted:FireClient(player, true, "Friend added!")
    RemoteEvents.FriendAdded:FireClient(player, requesterId, requesterName)
    
    -- Notify requester if online
    local requesterPlayer = Players:GetPlayerByUserId(requesterId)
    if requesterPlayer then
        RemoteEvents.FriendAdded:FireClient(requesterPlayer, userId, player.Name)
        self:SendFriendsList(requesterPlayer)
    end
    
    self:SendFriendsList(player)
    self:SendFriendRequests(player)
    
    print("🤝 " .. player.Name .. " accepted friend request from " .. requesterName)
end

function SocialService:AddMutualFriend(requesterId, accepterId, accepterName)
    spawn(function()
        local success, requesterData = pcall(function()
            return friendsStore:GetAsync(tostring(requesterId))
        end)
        
        if not success or not requesterData then
            requesterData = {friends = {}, sentRequests = {}, receivedRequests = {}}
        end
        
        -- Add friend
        requesterData.friends[tostring(accepterId)] = {
            playerName = accepterName,
            addedTime = os.time()
        }
        
        -- Remove from sent requests
        requesterData.sentRequests[tostring(accepterId)] = nil
        
        -- Save immediately
        pcall(function()
            friendsStore:SetAsync(tostring(requesterId), requesterData)
        end)
        
        -- Update cache if player is online
        if onlineStatus[requesterId] then
            playerFriends[requesterId] = requesterData
        end
    end)
end

function SocialService:DeclineFriendRequest(player, requesterId)
    local userId = player.UserId
    local playerData = playerFriends[userId]
    
    if not playerData or not playerData.receivedRequests[tostring(requesterId)] then
        RemoteEvents.FriendRequestDeclined:FireClient(player, false, "Friend request not found")
        return
    end
    
    local requesterName = playerData.receivedRequests[tostring(requesterId)].playerName
    
    -- Remove from received requests
    playerData.receivedRequests[tostring(requesterId)] = nil
    
    -- Remove from requester's sent requests
    self:RemoveSentFriendRequest(requesterId, userId)
    
    RemoteEvents.FriendRequestDeclined:FireClient(player, true, "Friend request declined")
    self:SendFriendRequests(player)
    
    print("❌ " .. player.Name .. " declined friend request from " .. requesterName)
end

function SocialService:RemoveSentFriendRequest(requesterId, targetId)
    spawn(function()
        local success, requesterData = pcall(function()
            return friendsStore:GetAsync(tostring(requesterId))
        end)
        
        if success and requesterData and requesterData.sentRequests then
            requesterData.sentRequests[tostring(targetId)] = nil
            
            pcall(function()
                friendsStore:SetAsync(tostring(requesterId), requesterData)
            end)
            
            if onlineStatus[requesterId] then
                playerFriends[requesterId] = requesterData
            end
        end
    end)
end

function SocialService:RemoveFriend(player, friendId)
    local userId = player.UserId
    local playerData = playerFriends[userId]
    
    if not playerData or not playerData.friends[tostring(friendId)] then
        RemoteEvents.FriendRemoved:FireClient(player, false, "Friend not found")
        return
    end
    
    local friendName = playerData.friends[tostring(friendId)].playerName
    
    -- Remove from both players' friend lists
    playerData.friends[tostring(friendId)] = nil
    self:RemoveMutualFriend(friendId, userId)
    
    RemoteEvents.FriendRemoved:FireClient(player, true, "Friend removed")
    self:SendFriendsList(player)
    
    -- Notify friend if online
    local friendPlayer = Players:GetPlayerByUserId(friendId)
    if friendPlayer then
        RemoteEvents.FriendRemoved:FireClient(friendPlayer, true, player.Name .. " removed you as a friend")
        self:SendFriendsList(friendPlayer)
    end
    
    print("💔 " .. player.Name .. " removed " .. friendName .. " as friend")
end

function SocialService:RemoveMutualFriend(friendId, removerId)
    spawn(function()
        local success, friendData = pcall(function()
            return friendsStore:GetAsync(tostring(friendId))
        end)
        
        if success and friendData and friendData.friends then
            friendData.friends[tostring(removerId)] = nil
            
            pcall(function()
                friendsStore:SetAsync(tostring(friendId), friendData)
            end)
            
            if onlineStatus[friendId] then
                playerFriends[friendId] = friendData
            end
        end
    end)
end

function SocialService:SendFriendsList(player)
    local userId = player.UserId
    local playerData = playerFriends[userId]
    
    if not playerData then
        RemoteEvents.FriendsListUpdated:FireClient(player, {})
        return
    end
    
    local friendsList = {}
    for friendId, friendData in pairs(playerData.friends) do
        table.insert(friendsList, {
            userId = tonumber(friendId),
            playerName = friendData.playerName,
            isOnline = onlineStatus[tonumber(friendId)] or false,
            addedTime = friendData.addedTime
        })
    end
    
    -- Sort by online status, then by name
    table.sort(friendsList, function(a, b)
        if a.isOnline ~= b.isOnline then
            return a.isOnline
        end
        return a.playerName < b.playerName
    end)
    
    RemoteEvents.FriendsListUpdated:FireClient(player, friendsList)
end

function SocialService:SendFriendRequests(player)
    local userId = player.UserId
    local playerData = playerFriends[userId]
    
    if not playerData then
        RemoteEvents.GetFriendRequests:FireClient(player, {})
        return
    end
    
    local requests = {}
    for requesterId, requestData in pairs(playerData.receivedRequests) do
        table.insert(requests, {
            userId = tonumber(requesterId),
            playerName = requestData.playerName,
            timestamp = requestData.timestamp
        })
    end
    
    -- Sort by timestamp (newest first)
    table.sort(requests, function(a, b)
        return a.timestamp > b.timestamp
    end)
    
    RemoteEvents.GetFriendRequests:FireClient(player, requests)
end

function SocialService:NotifyFriendsOnline(player)
    local userId = player.UserId
    local playerData = playerFriends[userId]
    
    if not playerData then return end
    
    for friendId, _ in pairs(playerData.friends) do
        local friendPlayer = Players:GetPlayerByUserId(tonumber(friendId))
        if friendPlayer then
            RemoteEvents.OnlineFriendsUpdated:FireClient(friendPlayer)
            self:SendFriendsList(friendPlayer)
        end
    end
end

function SocialService:NotifyFriendsOffline(player)
    local userId = player.UserId
    local playerData = playerFriends[userId]
    
    if not playerData then return end
    
    for friendId, _ in pairs(playerData.friends) do
        local friendPlayer = Players:GetPlayerByUserId(tonumber(friendId))
        if friendPlayer then
            RemoteEvents.OnlineFriendsUpdated:FireClient(friendPlayer)
            self:SendFriendsList(friendPlayer)
        end
    end
end

function SocialService:LikePlayerScore(player, targetUserId)
    local senderId = player.UserId
    
    if not socialStats[targetUserId] then
        socialStats[targetUserId] = {likes = 0, shares = 0, challenges = 0, challengesWon = 0}
    end
    
    socialStats[targetUserId].likes = socialStats[targetUserId].likes + 1
    
    -- Notify target if online
    local targetPlayer = Players:GetPlayerByUserId(targetUserId)
    if targetPlayer then
        RemoteEvents.ScoreLikeReceived:FireClient(targetPlayer, senderId, player.Name)
    end
    
    print("👍 " .. player.Name .. " liked score of user " .. targetUserId)
end

function SocialService:ChallengePlayer(player, targetUserId, challengeType)
    local senderId = player.UserId
    local challengeId = HttpService:GenerateGUID(false)
    
    local challenge = {
        id = challengeId,
        challengerId = senderId,
        challengerName = player.Name,
        targetId = targetUserId,
        challengeType = challengeType,
        timestamp = os.time(),
        duration = CHALLENGE_DURATION,
        status = "pending"
    }
    
    activeChallenges[challengeId] = challenge
    
    -- Notify target if online
    local targetPlayer = Players:GetPlayerByUserId(targetUserId)
    if targetPlayer then
        RemoteEvents.ChallengeReceived:FireClient(targetPlayer, challenge)
    end
    
    -- Update challenger's stats
    if not socialStats[senderId] then
        socialStats[senderId] = {likes = 0, shares = 0, challenges = 0, challengesWon = 0}
    end
    socialStats[senderId].challenges = socialStats[senderId].challenges + 1
    
    print("⚔️ " .. player.Name .. " challenged user " .. targetUserId .. " to " .. challengeType)
end

function SocialService:AcceptChallenge(player, challengeId)
    local challenge = activeChallenges[challengeId]
    
    if not challenge or challenge.targetId ~= player.UserId then
        return
    end
    
    challenge.status = "active"
    challenge.startTime = os.time()
    
    -- Notify challenger
    local challengerPlayer = Players:GetPlayerByUserId(challenge.challengerId)
    if challengerPlayer then
        RemoteEvents.ChallengeAccepted:FireClient(challengerPlayer, challenge)
    end
    
    RemoteEvents.ChallengeAccepted:FireClient(player, challenge)
    
    print("⚔️ " .. player.Name .. " accepted challenge from " .. challenge.challengerName)
end

function SocialService:ShareAchievement(player, achievementId)
    local userId = player.UserId
    local playerData = playerFriends[userId]
    
    if not playerData then return end
    
    -- Update stats
    if not socialStats[userId] then
        socialStats[userId] = {likes = 0, shares = 0, challenges = 0, challengesWon = 0}
    end
    socialStats[userId].shares = socialStats[userId].shares + 1
    
    -- Notify all friends
    for friendId, _ in pairs(playerData.friends) do
        local friendPlayer = Players:GetPlayerByUserId(tonumber(friendId))
        if friendPlayer then
            RemoteEvents.AchievementShared:FireClient(friendPlayer, userId, player.Name, achievementId)
        end
    end
    
    print("🏆 " .. player.Name .. " shared achievement: " .. achievementId)
end

function SocialService:SendSocialLeaderboard(player, leaderboardType)
    if leaderboardType == "friends" then
        self:SendFriendsLeaderboard(player)
    elseif leaderboardType == "global" then
        self:SendGlobalLeaderboard(player)
    elseif leaderboardType == "party" then
        self:SendPartyLeaderboard(player)
    end
end

function SocialService:SendFriendsLeaderboard(player)
    local userId = player.UserId
    local playerData = playerFriends[userId]
    
    if not playerData then
        RemoteEvents.FriendsLeaderboardUpdated:FireClient(player, {})
        return
    end
    
    local friendsLeaderboard = {}
    
    -- Add player's own score
    table.insert(friendsLeaderboard, {
        userId = userId,
        playerName = player.Name,
        score = player.leaderstats.HighScore.Value or 0,
        coins = player.leaderstats.Coins.Value or 0,
        isPlayer = true
    })
    
    -- Add friends' scores (mock data for now)
    for friendId, friendData in pairs(playerData.friends) do
        table.insert(friendsLeaderboard, {
            userId = tonumber(friendId),
            playerName = friendData.playerName,
            score = math.random(1000, 10000), -- Mock data
            coins = math.random(100, 5000), -- Mock data
            isOnline = onlineStatus[tonumber(friendId)] or false
        })
    end
    
    -- Sort by score
    table.sort(friendsLeaderboard, function(a, b)
        return a.score > b.score
    end)
    
    -- Add ranks
    for i, entry in ipairs(friendsLeaderboard) do
        entry.rank = i
    end
    
    RemoteEvents.FriendsLeaderboardUpdated:FireClient(player, friendsLeaderboard)
end

function SocialService:SendGlobalLeaderboard(player)
    -- Mock global leaderboard for now
    local globalLeaderboard = {
        {rank = 1, playerName = "ProRunner123", score = 15000, coins = 8000},
        {rank = 2, playerName = "SpeedDemon", score = 12500, coins = 6500},
        {rank = 3, playerName = "JumpMaster", score = 11000, coins = 5800},
        {rank = 4, playerName = "RunnerElite", score = 9500, coins = 4900},
        {rank = 5, playerName = "FastFeet", score = 8200, coins = 4100}
    }
    
    RemoteEvents.GlobalLeaderboardUpdated:FireClient(player, globalLeaderboard)
end

function SocialService:SendPartyLeaderboard(player)
    -- This would integrate with PartyService
    -- For now, send empty leaderboard
    RemoteEvents.PartyLeaderboardUpdated:FireClient(player, {})
end

function SocialService:StartSocialUpdates()
    local RunService = game:GetService("RunService")
    local lastSocialUpdate = 0
    
    self.socialConnection = RunService.Heartbeat:Connect(function()
        local currentTime = tick()
        if currentTime - lastSocialUpdate >= 30 then -- Update every 30 seconds
            lastSocialUpdate = currentTime
            
            -- Clean up old challenges
            for challengeId, challenge in pairs(activeChallenges) do
                if os.time() - challenge.timestamp > challenge.duration then
                    activeChallenges[challengeId] = nil
                end
            end
            
            -- Save social data for online players
            for _, player in pairs(Players:GetPlayers()) do
                self:SavePlayerSocialData(player)
            end
        end
    end)
end

-- Register service with centralized Services module
Services.Register("SocialService", SocialService)

return SocialService
