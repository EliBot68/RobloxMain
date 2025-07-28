-- PartyServiceEnhanced.luau
-- Enhanced party system with creative social features

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local DataStoreService = game:GetService("DataStoreService")
local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local SoundService = game:GetService("SoundService")

local SafeRequire = require(ReplicatedStorage.Shared.utils.SafeRequire)
local PlayerService = SafeRequire.require(script.Parent.PlayerService)
local GameService = SafeRequire.require(script.Parent.GameService)
local LevelingService = SafeRequire.require(script.Parent.LevelingService)
local QuestService = SafeRequire.require(script.Parent.QuestService)
local RemoteEvents = SafeRequire.require(ReplicatedStorage.Shared.modules.RemoteEvents)
local GameConstants = SafeRequire.require(ReplicatedStorage.Shared.constants.GameConstants)

local PartyService = {}

-- Enhanced party data storage
local parties = {} -- [partyId] = {comprehensive party data}
local playerParties = {} -- [userId] = partyId
local partyInvites = {} -- [userId] = {[fromUserId] = inviteData}
local partyVoiceCooldowns = {} -- [userId] = lastVoiceTime
local partyEmoteCooldowns = {} -- [userId] = lastEmoteTime
local partyStats = {} -- [partyId] = detailed statistics
local partyGameResults = {} -- [partyId] = recent game results
local partyAchievements = {} -- [partyId] = achievements unlocked
local partyCelebrations = {} -- [partyId] = ongoing celebrations

-- Party voice commands and emotes
local PARTY_VOICE_COMMANDS = {
    "Nice run!", "Good job team!", "Let's go!", "Almost there!", "Perfect!", 
    "Great sync!", "Team work!", "Focus up!", "We got this!", "Amazing!"
}

local PARTY_EMOTES = {
    "👍", "🔥", "⚡", "🎉", "💪", "🌟", "✨", "🏆", "💫", "🎯"
}

local PARTY_ACHIEVEMENTS = {
    {id = "sync_masters", name = "Sync Masters", desc = "Complete 5 perfect synchronized runs", requirement = 5},
    {id = "streak_legends", name = "Streak Legends", desc = "Achieve 10-game win streak", requirement = 10},
    {id = "team_perfection", name = "Team Perfection", desc = "All members get perfect scores", requirement = 1},
    {id = "speed_demons", name = "Speed Demons", desc = "Complete run in under 60 seconds together", requirement = 1},
    {id = "loyalty_squad", name = "Loyalty Squad", desc = "Play 50 games with same party", requirement = 50}
}

function PartyService:GeneratePartyId()
    local id = "party_" .. tostring(os.time()) .. "_" .. tostring(math.random(1000, 9999))
    while parties[id] do
        id = "party_" .. tostring(os.time()) .. "_" .. tostring(math.random(1000, 9999))
    end
    return id
end

function PartyService:CreateParty(leader)
    local userId = tostring(leader.UserId)
    
    if playerParties[userId] then
        return false, "You are already in a party"
    end
    
    local partyId = self:GeneratePartyId()
    
    -- Create comprehensive party data
    parties[partyId] = {
        id = partyId,
        leader = userId,
        members = {userId},
        created = os.time(),
        settings = {
            autoStart = false,
            voiceEnabled = true,
            emotesEnabled = true,
            celebrationMode = true,
            syncMode = true
        },
        streak = 0,
        bestStreak = 0,
        perfectRuns = 0,
        totalGames = 0,
        averageScore = 0,
        theme = "default",
        motto = "Together we rise!",
        partyLevel = 1,
        partyXP = 0
    }
    
    -- Initialize party stats
    partyStats[partyId] = {
        gamesPlayed = 0,
        totalXP = 0,
        averagePerformance = 0,
        bestScore = 0,
        fastestTime = math.huge,
        longestStreak = 0,
        membersJoined = {userId},
        achievements = {}
    }
    
    partyGameResults[partyId] = {
        lastGameScores = {},
        lastGameTimes = {},
        recentPerformance = {}
    }
    
    playerParties[userId] = partyId
    
    -- Create party visual indicator in world
    self:CreatePartyIndicator(leader, partyId)
    
    -- Update quest progress
    if QuestService then
        QuestService:UpdateQuestProgress(leader, "party_created", 1)
    end
    
    print("🎉 " .. leader.Name .. " created party: " .. partyId)
    return true, partyId
end

function PartyService:CreatePartyIndicator(leader, partyId)
    -- Create floating party indicator above leader
    local character = leader.Character
    if not character or not character:FindFirstChild("HumanoidRootPart") then return end
    
    local indicator = Instance.new("BillboardGui")
    indicator.Name = "PartyIndicator"
    indicator.Size = UDim2.new(0, 200, 0, 100)
    indicator.StudsOffset = Vector3.new(0, 3, 0)
    indicator.Parent = character.HumanoidRootPart
    
    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(1, 0, 1, 0)
    frame.BackgroundColor3 = Color3.new(0.1, 0.3, 0.8)
    frame.BackgroundTransparency = 0.2
    frame.BorderSizePixel = 0
    frame.Parent = indicator
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 10)
    corner.Parent = frame
    
    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, 0, 0.6, 0)
    label.BackgroundTransparency = 1
    label.Text = "🎉 PARTY LEADER"
    label.TextColor3 = Color3.new(1, 1, 1)
    label.TextScaled = true
    label.Font = Enum.Font.SourceSansBold
    label.Parent = frame
    
    local memberCount = Instance.new("TextLabel")
    memberCount.Size = UDim2.new(1, 0, 0.4, 0)
    memberCount.Position = UDim2.new(0, 0, 0.6, 0)
    memberCount.BackgroundTransparency = 1
    memberCount.Text = "Members: 1/" .. GameConstants.MAX_PARTY_SIZE
    memberCount.TextColor3 = Color3.new(0.8, 0.8, 0.8)
    memberCount.TextScaled = true
    memberCount.Font = Enum.Font.SourceSans
    memberCount.Parent = frame
    
    -- Store reference for updates
    if not parties[partyId] then return end
    parties[partyId].indicator = indicator
    parties[partyId].memberCountLabel = memberCount
    
    -- Floating animation
    local tween = TweenService:Create(
        indicator,
        TweenInfo.new(2, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true),
        {StudsOffset = Vector3.new(0, 4, 0)}
    )
    tween:Play()
end

function PartyService:UpdatePartyIndicator(partyId)
    local party = parties[partyId]
    if not party or not party.indicator or not party.memberCountLabel then return end
    
    party.memberCountLabel.Text = "Members: " .. #party.members .. "/" .. GameConstants.MAX_PARTY_SIZE
    
    -- Change color based on party size
    local frame = party.indicator:FindFirstChild("Frame")
    if frame then
        local memberCount = #party.members
        if memberCount == GameConstants.MAX_PARTY_SIZE then
            frame.BackgroundColor3 = Color3.new(0.8, 0.2, 0.8) -- Purple for full party
        elseif memberCount >= 3 then
            frame.BackgroundColor3 = Color3.new(0.2, 0.8, 0.2) -- Green for good size
        else
            frame.BackgroundColor3 = Color3.new(0.1, 0.3, 0.8) -- Blue for small party
        end
    end
end

function PartyService:SendPartyInvite(inviter, targetPlayer)
    local inviterUserId = tostring(inviter.UserId)
    local targetUserId = tostring(targetPlayer.UserId)
    
    -- Check if inviter is in a party
    local partyId = playerParties[inviterUserId]
    if not partyId then
        return false, "You must be in a party to send invites"
    end
    
    local party = parties[partyId]
    if not party then
        return false, "Party not found"
    end
    
    -- Check if inviter is party leader or has invite permissions
    if party.leader ~= inviterUserId then
        return false, "Only the party leader can send invites"
    end
    
    -- Check party size
    if #party.members >= GameConstants.MAX_PARTY_SIZE then
        return false, "Party is full"
    end
    
    -- Check if target is already in a party
    if playerParties[targetUserId] then
        return false, targetPlayer.Name .. " is already in a party"
    end
    
    -- Check if invite already exists
    if partyInvites[targetUserId] and partyInvites[targetUserId][inviterUserId] then
        return false, "Invite already sent to " .. targetPlayer.Name
    end
    
    -- Create invite
    if not partyInvites[targetUserId] then
        partyInvites[targetUserId] = {}
    end
    
    partyInvites[targetUserId][inviterUserId] = {
        partyId = partyId,
        inviter = inviter,
        expires = os.time() + GameConstants.PARTY_INVITE_TIMEOUT,
        partySize = #party.members,
        partyStats = {
            level = party.partyLevel or 1,
            streak = party.streak or 0,
            motto = party.motto or "Together we rise!"
        }
    }
    
    -- Send enhanced invite to client
    RemoteEvents.PartyInviteReceived:FireClient(targetPlayer, {
        inviter = inviter.Name,
        inviterUserId = inviterUserId,
        partyId = partyId,
        partySize = #party.members,
        maxSize = GameConstants.MAX_PARTY_SIZE,
        partyLevel = party.partyLevel or 1,
        partyStreak = party.streak or 0,
        partyMotto = party.motto or "Together we rise!",
        expiresIn = GameConstants.PARTY_INVITE_TIMEOUT
    })
    
    print("📬 " .. inviter.Name .. " sent enhanced party invite to " .. targetPlayer.Name)
    return true, "Invite sent to " .. targetPlayer.Name
end

function PartyService:AcceptPartyInvite(player, inviterUserId)
    local userId = tostring(player.UserId)
    
    -- Check if invite exists
    if not partyInvites[userId] or not partyInvites[userId][inviterUserId] then
        return false, "Invite not found or expired"
    end
    
    local invite = partyInvites[userId][inviterUserId]
    
    -- Check if invite is expired
    if os.time() > invite.expires then
        partyInvites[userId][inviterUserId] = nil
        return false, "Invite has expired"
    end
    
    -- Check if party still exists
    local party = parties[invite.partyId]
    if not party then
        partyInvites[userId][inviterUserId] = nil
        return false, "Party no longer exists"
    end
    
    -- Check if player is already in a party
    if playerParties[userId] then
        return false, "You are already in a party"
    end
    
    -- Check party size
    if #party.members >= GameConstants.MAX_PARTY_SIZE then
        return false, "Party is full"
    end
    
    -- Add player to party
    table.insert(party.members, userId)
    playerParties[userId] = invite.partyId
    
    -- Track new member in stats
    if not table.find(partyStats[invite.partyId].membersJoined, userId) then
        table.insert(partyStats[invite.partyId].membersJoined, userId)
    end
    
    -- Clean up invite
    partyInvites[userId][inviterUserId] = nil
    
    -- Update party indicator
    self:UpdatePartyIndicator(invite.partyId)
    
    -- Create member indicator for new member
    self:CreateMemberIndicator(player, invite.partyId)
    
    -- Notify all party members with enhanced message
    self:NotifyPartyMembers(invite.partyId, "🎉 " .. player.Name .. " joined the party!", "celebration")
    
    -- Party celebration effect
    self:TriggerPartyCelebration(invite.partyId, "member_joined")
    
    print("✅ " .. player.Name .. " joined party: " .. invite.partyId)
    return true, "Successfully joined the party!"
end

function PartyService:CreateMemberIndicator(player, partyId)
    local character = player.Character
    if not character or not character:FindFirstChild("HumanoidRootPart") then return end
    
    local indicator = Instance.new("BillboardGui")
    indicator.Name = "PartyMemberIndicator"
    indicator.Size = UDim2.new(0, 150, 0, 60)
    indicator.StudsOffset = Vector3.new(0, 2.5, 0)
    indicator.Parent = character.HumanoidRootPart
    
    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(1, 0, 1, 0)
    frame.BackgroundColor3 = Color3.new(0.2, 0.6, 0.2)
    frame.BackgroundTransparency = 0.3
    frame.BorderSizePixel = 0
    frame.Parent = indicator
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 8)
    corner.Parent = frame
    
    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, 0, 1, 0)
    label.BackgroundTransparency = 1
    label.Text = "🎊 PARTY MEMBER"
    label.TextColor3 = Color3.new(1, 1, 1)
    label.TextScaled = true
    label.Font = Enum.Font.SourceSansBold
    label.Parent = frame
    
    -- Subtle floating animation
    local tween = TweenService:Create(
        indicator,
        TweenInfo.new(3, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true),
        {StudsOffset = Vector3.new(0, 3.2, 0)}
    )
    tween:Play()
end

function PartyService:NotifyPartyMembers(partyId, message, notificationType)
    local party = parties[partyId]
    if not party then return end
    
    for _, memberId in pairs(party.members) do
        local player = Players:GetPlayerByUserId(tonumber(memberId))
        if player then
            RemoteEvents.PartyNotification:FireClient(player, {
                message = message,
                type = notificationType or "info",
                duration = 3,
                partyId = partyId
            })
        end
    end
end

function PartyService:TriggerPartyCelebration(partyId, celebrationType)
    local party = parties[partyId]
    if not party or not party.settings.celebrationMode then return end
    
    -- Don't spam celebrations
    if partyCelebrations[partyId] and (os.time() - partyCelebrations[partyId]) < 2 then
        return
    end
    
    partyCelebrations[partyId] = os.time()
    
    for _, memberId in pairs(party.members) do
        local player = Players:GetPlayerByUserId(tonumber(memberId))
        if player then
            RemoteEvents.Partycelebration:FireClient(player, {
                type = celebrationType,
                duration = GameConstants.PARTY_CELEBRATION_DURATION,
                partyLevel = party.partyLevel or 1
            })
        end
    end
end

function PartyService:SendPartyVoiceMessage(player, messageIndex)
    local userId = tostring(player.UserId)
    local partyId = playerParties[userId]
    
    if not partyId then return false, "You are not in a party" end
    
    local party = parties[partyId]
    if not party or not party.settings.voiceEnabled then 
        return false, "Voice messages are disabled" 
    end
    
    -- Check cooldown
    local currentTime = os.time()
    if partyVoiceCooldowns[userId] and 
       (currentTime - partyVoiceCooldowns[userId]) < GameConstants.PARTY_VOICE_COOLDOWN then
        return false, "Please wait before sending another voice message"
    end
    
    -- Validate message index
    if not messageIndex or messageIndex < 1 or messageIndex > #PARTY_VOICE_COMMANDS then
        return false, "Invalid voice message"
    end
    
    partyVoiceCooldowns[userId] = currentTime
    local message = PARTY_VOICE_COMMANDS[messageIndex]
    
    -- Send to all party members
    for _, memberId in pairs(party.members) do
        local member = Players:GetPlayerByUserId(tonumber(memberId))
        if member then
            RemoteEvents.PartyVoiceMessage:FireClient(member, {
                sender = player.Name,
                message = message,
                senderUserId = userId
            })
        end
    end
    
    return true, "Voice message sent!"
end

function PartyService:SendPartyEmote(player, emoteIndex)
    local userId = tostring(player.UserId)
    local partyId = playerParties[userId]
    
    if not partyId then return false, "You are not in a party" end
    
    local party = parties[partyId]
    if not party or not party.settings.emotesEnabled then 
        return false, "Emotes are disabled" 
    end
    
    -- Check cooldown
    local currentTime = os.time()
    if partyEmoteCooldowns[userId] and 
       (currentTime - partyEmoteCooldowns[userId]) < GameConstants.PARTY_EMOTE_COOLDOWN then
        return false, "Please wait before sending another emote"
    end
    
    -- Validate emote index
    if not emoteIndex or emoteIndex < 1 or emoteIndex > #PARTY_EMOTES then
        return false, "Invalid emote"
    end
    
    partyEmoteCooldowns[userId] = currentTime
    local emote = PARTY_EMOTES[emoteIndex]
    
    -- Send to all party members with visual effect
    for _, memberId in pairs(party.members) do
        local member = Players:GetPlayerByUserId(tonumber(memberId))
        if member then
            RemoteEvents.PartyEmote:FireClient(member, {
                sender = player.Name,
                emote = emote,
                senderUserId = userId
            })
        end
    end
    
    return true, "Emote sent!"
end

function PartyService:StartPartyGame(leader)
    local userId = tostring(leader.UserId)
    local partyId = playerParties[userId]
    
    if not partyId then
        return false, "You are not in a party"
    end
    
    local party = parties[partyId]
    if not party then
        return false, "Party not found"
    end
    
    if party.leader ~= userId then
        return false, "Only the party leader can start games"
    end
    
    local partyMembers = {}
    local allReady = true
    
    -- Check if all members are ready and in the hub
    for _, memberId in pairs(party.members) do
        local player = Players:GetPlayerByUserId(tonumber(memberId))
        if player then
            table.insert(partyMembers, player)
            
            -- Check if player is in hub
            local playerData = PlayerService:GetPlayerData(player)
            if playerData.gameState ~= "hub" then
                allReady = false
                RemoteEvents.PartyNotification:FireClient(leader, {
                    message = player.Name .. " is not in the hub!",
                    type = "warning",
                    duration = 3
                })
            end
        else
            allReady = false
        end
    end
    
    if not allReady then
        return false, "All party members must be in the hub"
    end
    
    if #partyMembers < 2 then
        return false, "Need at least 2 party members to start"
    end
    
    -- Enhanced party game start with countdown
    if party.settings.syncMode then
        self:StartSynchronizedPartyGame(partyId, partyMembers)
    else
        self:StartRegularPartyGame(partyId, partyMembers)
    end
    
    return true, "Starting party game!"
end

function PartyService:StartSynchronizedPartyGame(partyId, members)
    local party = parties[partyId]
    
    -- Notify all members of synchronized start
    for _, player in pairs(members) do
        RemoteEvents.PartySyncCountdown:FireClient(player, {
            countdown = GameConstants.PARTY_SYNC_COUNTDOWN,
            partySize = #members,
            syncMode = true
        })
    end
    
    -- Wait for countdown
    spawn(function()
        wait(GameConstants.PARTY_SYNC_COUNTDOWN)
        
        -- Start game for all members simultaneously
        for _, player in pairs(members) do
            local success = GameService:StartGame(player, {
                isPartyGame = true,
                partyId = partyId,
                partySize = #members,
                synchronized = true
            })
            
            if success then
                -- Update quest progress
                if QuestService then
                    QuestService:UpdateQuestProgress(player, "party_games_played", 1, {isPartyGame = true})
                end
            end
        end
        
        -- Update party stats
        partyStats[partyId].gamesPlayed = partyStats[partyId].gamesPlayed + 1
        party.totalGames = party.totalGames + 1
        
        print("🚀 Synchronized party game started for party: " .. partyId)
    end)
end

function PartyService:StartRegularPartyGame(partyId, members)
    local party = parties[partyId]
    
    -- Start game for all members
    for _, player in pairs(members) do
        local success = GameService:StartGame(player, {
            isPartyGame = true,
            partyId = partyId,
            partySize = #members,
            synchronized = false
        })
        
        if success then
            -- Update quest progress
            if QuestService then
                QuestService:UpdateQuestProgress(player, "party_games_played", 1, {isPartyGame = true})
            end
        end
    end
    
    -- Update party stats
    partyStats[partyId].gamesPlayed = partyStats[partyId].gamesPlayed + 1
    party.totalGames = party.totalGames + 1
    
    print("🚀 Party game started for party: " .. partyId)
end

function PartyService:OnPartyGameEnd(partyId, gameResults)
    local party = parties[partyId]
    if not party then return end
    
    local results = partyGameResults[partyId]
    if not results then
        partyGameResults[partyId] = {lastGameScores = {}, lastGameTimes = {}, recentPerformance = {}}
        results = partyGameResults[partyId]
    end
    
    -- Track game results
    local scores = {}
    local times = {}
    local allPerfect = true
    local totalXP = 0
    local averageScore = 0
    
    for userId, result in pairs(gameResults) do
        table.insert(scores, result.score)
        table.insert(times, result.time)
        totalXP = totalXP + (result.xpEarned or 0)
        averageScore = averageScore + result.score
        
        if not result.perfect then
            allPerfect = false
        end
    end
    
    averageScore = averageScore / #scores
    
    -- Update party stats
    results.lastGameScores = scores
    results.lastGameTimes = times
    table.insert(results.recentPerformance, {
        averageScore = averageScore,
        allPerfect = allPerfect,
        totalXP = totalXP,
        timestamp = os.time()
    })
    
    -- Keep only last 10 performances
    if #results.recentPerformance > 10 then
        table.remove(results.recentPerformance, 1)
    end
    
    -- Update party level and XP
    party.partyXP = party.partyXP + totalXP
    local newLevel = math.floor(party.partyXP / 1000) + 1
    if newLevel > party.partyLevel then
        party.partyLevel = newLevel
        self:TriggerPartyCelebration(partyId, "level_up")
        self:NotifyPartyMembers(partyId, "🎊 Party leveled up to Level " .. newLevel .. "!", "success")
    end
    
    -- Check for achievements
    self:CheckPartyAchievements(partyId, gameResults)
    
    -- Update streak
    if allPerfect then
        party.streak = party.streak + 1
        party.perfectRuns = party.perfectRuns + 1
        if party.streak > party.bestStreak then
            party.bestStreak = party.streak
        end
        
        -- Trigger celebration for perfect party run
        self:TriggerPartyCelebration(partyId, "perfect_run")
        self:NotifyPartyMembers(partyId, "🌟 PERFECT PARTY RUN! Streak: " .. party.streak, "perfect")
    else
        party.streak = 0
    end
    
    -- Calculate enhanced XP bonus
    local xpBonus = GameConstants.PARTY_XP_BONUS
    if allPerfect then
        xpBonus = xpBonus + GameConstants.PARTY_PERFECT_BONUS
    end
    if party.streak > 0 then
        xpBonus = xpBonus + (math.min(party.streak, GameConstants.MAX_PARTY_STREAK) * GameConstants.PARTY_STREAK_BONUS)
    end
    
    -- Apply XP bonus to all members
    for _, memberId in pairs(party.members) do
        local player = Players:GetPlayerByUserId(tonumber(memberId))
        if player and gameResults[memberId] then
            local bonusXP = math.floor(gameResults[memberId].xpEarned * xpBonus)
            LevelingService:AddExperience(player, bonusXP)
            
            -- Update quest progress
            if QuestService then
                QuestService:UpdateQuestProgress(player, "party_bonus_xp", bonusXP)
                QuestService:UpdateQuestProgress(player, "max_party_size", #party.members)
                if party.streak >= 5 then
                    QuestService:UpdateQuestProgress(player, "consistent_party_games", 1, {sameParty = true})
                end
            end
            
            -- Show enhanced XP notification
            RemoteEvents.PartyXPBonus:FireClient(player, {
                baseXP = gameResults[memberId].xpEarned,
                bonusXP = bonusXP,
                totalMultiplier = xpBonus + 1,
                isPerfect = allPerfect,
                streak = party.streak,
                partyLevel = party.partyLevel
            })
        end
    end
    
    print("🎉 Party game ended for " .. partyId .. " - Average Score: " .. averageScore .. " - All Perfect: " .. tostring(allPerfect))
end

function PartyService:CheckPartyAchievements(partyId, gameResults)
    local party = parties[partyId]
    local stats = partyStats[partyId]
    
    if not party or not stats then return end
    
    for _, achievement in pairs(PARTY_ACHIEVEMENTS) do
        if table.find(stats.achievements, achievement.id) then
            continue -- Already unlocked
        end
        
        local unlocked = false
        
        if achievement.id == "sync_masters" and party.perfectRuns >= achievement.requirement then
            unlocked = true
        elseif achievement.id == "streak_legends" and party.bestStreak >= achievement.requirement then
            unlocked = true
        elseif achievement.id == "team_perfection" then
            local allPerfect = true
            for _, result in pairs(gameResults) do
                if not result.perfect then
                    allPerfect = false
                    break
                end
            end
            if allPerfect then unlocked = true end
        elseif achievement.id == "speed_demons" then
            local allFast = true
            for _, result in pairs(gameResults) do
                if result.time > 60 then
                    allFast = false
                    break
                end
            end
            if allFast then unlocked = true end
        elseif achievement.id == "loyalty_squad" and party.totalGames >= achievement.requirement then
            unlocked = true
        end
        
        if unlocked then
            table.insert(stats.achievements, achievement.id)
            self:NotifyPartyMembers(partyId, "🏆 ACHIEVEMENT UNLOCKED: " .. achievement.name .. "!", "achievement")
            self:TriggerPartyCelebration(partyId, "achievement")
            
            -- Give rewards to all members
            for _, memberId in pairs(party.members) do
                local player = Players:GetPlayerByUserId(tonumber(memberId))
                if player then
                    local playerData = PlayerService:GetPlayerData(player)
                    playerData.coins = playerData.coins + 500 -- Achievement reward
                    PlayerService:UpdatePlayerData(player, playerData)
                end
            end
        end
    end
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
    
    -- Remove player's indicator
    if player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
        local indicator = player.Character.HumanoidRootPart:FindFirstChild("PartyMemberIndicator")
        if indicator then indicator:Destroy() end
    end
    
    -- Check if player was leader
    if party.leader == userId then
        if #party.members > 0 then
            -- Transfer leadership to first member
            local newLeaderId = party.members[1]
            party.leader = newLeaderId
            
            local newLeader = Players:GetPlayerByUserId(tonumber(newLeaderId))
            if newLeader then
                self:NotifyPartyMembers(partyId, "👑 " .. newLeader.Name .. " is now the party leader!", "info")
                self:CreatePartyIndicator(newLeader, partyId)
            end
        else
            -- Disband party if no members left
            self:DisbandParty(partyId)
            return true, "Party disbanded"
        end
    end
    
    self:UpdatePartyIndicator(partyId)
    self:NotifyPartyMembers(partyId, "👋 " .. player.Name .. " left the party", "info")
    
    print("👋 " .. player.Name .. " left party: " .. partyId)
    return true, "Left the party"
end

function PartyService:DisbandParty(partyId)
    local party = parties[partyId]
    if not party then return end
    
    -- Remove all indicators
    for _, memberId in pairs(party.members) do
        local player = Players:GetPlayerByUserId(tonumber(memberId))
        if player and player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
            local indicators = player.Character.HumanoidRootPart:GetChildren()
            for _, indicator in pairs(indicators) do
                if indicator.Name:find("Party") and indicator:IsA("BillboardGui") then
                    indicator:Destroy()
                end
            end
        end
        playerParties[memberId] = nil
    end
    
    -- Clean up data
    parties[partyId] = nil
    partyStats[partyId] = nil
    partyGameResults[partyId] = nil
    partyAchievements[partyId] = nil
    partyCelebrations[partyId] = nil
    
    print("🚫 Party disbanded: " .. partyId)
end

function PartyService:GetPartyData(player)
    local userId = tostring(player.UserId)
    local partyId = playerParties[userId]
    
    if not partyId then return nil end
    
    local party = parties[partyId]
    local stats = partyStats[partyId]
    local results = partyGameResults[partyId]
    
    if not party then return nil end
    
    return {
        id = partyId,
        leader = party.leader,
        members = party.members,
        settings = party.settings,
        level = party.partyLevel,
        xp = party.partyXP,
        streak = party.streak,
        bestStreak = party.bestStreak,
        perfectRuns = party.perfectRuns,
        totalGames = party.totalGames,
        motto = party.motto,
        theme = party.theme,
        stats = stats,
        recentResults = results,
        achievements = stats and stats.achievements or {}
    }
end

function PartyService:GetPartyVoiceCommands()
    return PARTY_VOICE_COMMANDS
end

function PartyService:GetPartyEmotes()
    return PARTY_EMOTES
end

function PartyService:Init()
    print("🎉 Enhanced PartyService initializing...")
    
    -- Handle player leaving
    Players.PlayerRemoving:Connect(function(player)
        self:LeaveParty(player)
    end)
    
    -- Clean up expired invites periodically
    spawn(function()
        while true do
            wait(30) -- Check every 30 seconds
            local currentTime = os.time()
            
            for userId, invites in pairs(partyInvites) do
                for fromUserId, invite in pairs(invites) do
                    if currentTime > invite.expires then
                        invites[fromUserId] = nil
                    end
                end
                
                -- Clean up empty invite tables
                if next(invites) == nil then
                    partyInvites[userId] = nil
                end
            end
        end
    end)
    
    print("✅ Enhanced PartyService initialized with creative features!")
end

-- Remote event connections
RemoteEvents.CreateParty.OnServerEvent:Connect(function(player)
    local success, result = PartyService:CreateParty(player)
    RemoteEvents.PartyCreated:FireClient(player, success, result)
end)

RemoteEvents.SendPartyInvite.OnServerEvent:Connect(function(player, targetPlayerName)
    local targetPlayer = Players:FindFirstChild(targetPlayerName)
    if targetPlayer then
        local success, result = PartyService:SendPartyInvite(player, targetPlayer)
        RemoteEvents.PartyInviteResult:FireClient(player, success, result)
    end
end)

RemoteEvents.AcceptPartyInvite.OnServerEvent:Connect(function(player, inviterUserId)
    local success, result = PartyService:AcceptPartyInvite(player, inviterUserId)
    RemoteEvents.PartyJoinResult:FireClient(player, success, result)
end)

RemoteEvents.StartPartyGame.OnServerEvent:Connect(function(player)
    local success, result = PartyService:StartPartyGame(player)
    RemoteEvents.PartyGameStartResult:FireClient(player, success, result)
end)

RemoteEvents.LeaveParty.OnServerEvent:Connect(function(player)
    local success, result = PartyService:LeaveParty(player)
    RemoteEvents.PartyLeaveResult:FireClient(player, success, result)
end)

RemoteEvents.SendPartyVoice.OnServerEvent:Connect(function(player, messageIndex)
    local success, result = PartyService:SendPartyVoiceMessage(player, messageIndex)
    RemoteEvents.PartyVoiceResult:FireClient(player, success, result)
end)

RemoteEvents.SendPartyEmote.OnServerEvent:Connect(function(player, emoteIndex)
    local success, result = PartyService:SendPartyEmote(player, emoteIndex)
    RemoteEvents.PartyEmoteResult:FireClient(player, success, result)
end)

RemoteEvents.GetPartyData.OnServerEvent:Connect(function(player)
    local partyData = PartyService:GetPartyData(player)
    RemoteEvents.PartyDataResponse:FireClient(player, partyData)
end)

return PartyService
