-- DailyStreakService.luau
-- Handles daily login streaks with escalating rewards

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local DataStoreService = game:GetService("DataStoreService")
local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local RemoteEvents = require(ReplicatedStorage.Shared.modules.RemoteEvents)

-- Forward declare services to avoid circular dependencies
local PlayerService = nil
local AnalyticsService = nil
local QuestService = nil

local DailyStreakService = {}

-- Event signals
DailyStreakService.StreakUpdated = nil -- Placeholder for optional signal

-- DataStore for tracking daily streaks
local dailyStreakStore = DataStoreService:GetDataStore("DailyStreakProgress")

-- Daily streak reward configurations
local STREAK_REWARDS = {
    [1] = {coins = 10, type = "coins", message = "Welcome back! Starting your streak!"},
    [2] = {coins = 15, type = "coins", message = "Day 2! Keep it up!"},
    [3] = {coins = 20, type = "coins", message = "Day 3! You're on a roll!"},
    [4] = {coins = 30, type = "coins", message = "Day 4! Impressive dedication!"},
    [5] = {coins = 40, type = "coins", message = "Day 5! Almost a week!"},
    [6] = {coins = 50, type = "coins", message = "Day 6! One more for the weekly bonus!"},
    [7] = {coins = 75, type = "special", effect = "golden_aura", duration = 300, message = "WEEK COMPLETE! Amazing streak!"},
    [8] = {coins = 25, type = "coins", message = "Day 8! Starting week 2!"},
    [9] = {coins = 30, type = "coins", message = "Day 9! Consistency pays off!"},
    [10] = {coins = 35, type = "coins", message = "Day 10! Double digits!"},
    [11] = {coins = 40, type = "coins", message = "Day 11! You're unstoppable!"},
    [12] = {coins = 45, type = "coins", message = "Day 12! Elite dedication!"},
    [13] = {coins = 50, type = "coins", message = "Day 13! Lucky streak!"},
    [14] = {coins = 100, type = "mega", effect = "rainbow_explosion", duration = 600, message = "TWO WEEKS! LEGENDARY STREAK!"},
    [21] = {coins = 150, type = "mega", effect = "cosmic_aura", duration = 900, message = "THREE WEEKS! COSMIC DEDICATION!"},
    [30] = {coins = 250, type = "ultimate", effect = "streak_master", duration = 1200, message = "ONE MONTH! STREAK MASTER ACHIEVED!"}
}

-- Default reward for days beyond configured rewards
local DEFAULT_LONG_STREAK_REWARD = {coins = 60, type = "coins", message = "Amazing long streak! Keep going!"}

-- Player streak tracking
local playerStreaks = {}

function DailyStreakService:Init()
    self:SetupDailyStreakStall()
    print("✅ DailyStreakService initialized")
end

function DailyStreakService:SetupDailyStreakStall()
    local marketPlaza = Workspace:FindFirstChild("MarketPlaza")
    if not marketPlaza then
        warn("MarketPlaza not found!")
        return
    end
    
    -- Create daily streak stall
    local streakStall = Instance.new("Part")
    streakStall.Name = "DailyStreakStall"
    streakStall.Size = Vector3.new(8, 10, 8)
    streakStall.Position = Vector3.new(40, 5, -10) -- Position in market plaza
    streakStall.Material = Enum.Material.Neon
    streakStall.BrickColor = BrickColor.new("Bright orange")
    streakStall.CanCollide = false
    streakStall.Anchored = true
    streakStall.Shape = Enum.PartType.Cylinder
    streakStall.Parent = marketPlaza
    
    -- Add rotating animation
    local rotationTween = TweenService:Create(
        streakStall,
        TweenInfo.new(10, Enum.EasingStyle.Linear, Enum.EasingDirection.InOut, -1, false),
        {Rotation = streakStall.Rotation + Vector3.new(0, 360, 0)}
    )
    rotationTween:Play()
    
    -- Add floating effect
    local floatTween = TweenService:Create(
        streakStall,
        TweenInfo.new(3, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true),
        {Position = streakStall.Position + Vector3.new(0, 2, 0)}
    )
    floatTween:Play()
    
    -- Add particle effects
    local attachment = Instance.new("Attachment")
    attachment.Parent = streakStall
    
    local sparkles = Instance.new("ParticleEmitter")
    sparkles.Parent = attachment
    sparkles.Enabled = true
    sparkles.Lifetime = NumberRange.new(1, 3)
    sparkles.Rate = 20
    sparkles.SpreadAngle = Vector2.new(45, 45)
    sparkles.Speed = NumberRange.new(5, 15)
    sparkles.Color = ColorSequence.new{
        ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 215, 0)),
        ColorSequenceKeypoint.new(0.5, Color3.fromRGB(255, 165, 0)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 100, 0))
    }
    sparkles.Transparency = NumberSequence.new{
        NumberSequenceKeypoint.new(0, 0.3),
        NumberSequenceKeypoint.new(0.5, 0.1),
        NumberSequenceKeypoint.new(1, 1)
    }
    
    -- Add title billboard
    local billboardGui = Instance.new("BillboardGui")
    billboardGui.Size = UDim2.new(0, 300, 0, 120)
    billboardGui.StudsOffset = Vector3.new(0, 6, 0)
    billboardGui.Parent = streakStall
    
    local titleLabel = Instance.new("TextLabel")
    titleLabel.Size = UDim2.new(1, 0, 0.6, 0)
    titleLabel.BackgroundTransparency = 1
    titleLabel.Text = "🔥 DAILY STREAK"
    titleLabel.TextColor3 = Color3.fromRGB(255, 215, 0)
    titleLabel.TextScaled = true
    titleLabel.Font = Enum.Font.GothamBold
    titleLabel.TextStrokeTransparency = 0
    titleLabel.TextStrokeColor3 = Color3.new(0, 0, 0)
    titleLabel.Parent = billboardGui
    
    local subtitleLabel = Instance.new("TextLabel")
    subtitleLabel.Size = UDim2.new(1, 0, 0.4, 0)
    subtitleLabel.Position = UDim2.new(0, 0, 0.6, 0)
    subtitleLabel.BackgroundTransparency = 1
    subtitleLabel.Text = "Consecutive Login Rewards!"
    subtitleLabel.TextColor3 = Color3.fromRGB(255, 200, 100)
    subtitleLabel.TextScaled = true
    subtitleLabel.Font = Enum.Font.Gotham
    subtitleLabel.TextStrokeTransparency = 0
    subtitleLabel.TextStrokeColor3 = Color3.new(0, 0, 0)
    subtitleLabel.Parent = billboardGui
    
    -- Pulsing animation for title
    local pulseTween = TweenService:Create(
        titleLabel,
        TweenInfo.new(1.5, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true),
        {TextTransparency = 0.2}
    )
    pulseTween:Play()
    
    -- Add click detector
    local clickDetector = Instance.new("ClickDetector")
    clickDetector.MaxActivationDistance = 25
    clickDetector.Parent = streakStall
    
    clickDetector.MouseClick:Connect(function(player)
        self:ShowStreakUI(player)
    end)
    
    -- Add collision detection for walking into
    local function onTouched(hit)
        local humanoid = hit.Parent:FindFirstChild("Humanoid")
        if humanoid then
            local player = Players:GetPlayerFromCharacter(hit.Parent)
            if player then
                self:ShowStreakUI(player)
            end
        end
    end
    
    streakStall.Touched:Connect(onTouched)
    
    print("🔥 Daily Streak stall created")
end

function DailyStreakService:GetDaysSinceEpoch()
    return math.floor(os.time() / 86400)
end

function DailyStreakService:LoadPlayerStreak(player)
    local userId = tostring(player.UserId)
    local currentDay = self:GetDaysSinceEpoch()
    
    -- Try to load from DataStore
    local success, data = pcall(function()
        return dailyStreakStore:GetAsync(userId) or {}
    end)
    
    if not success then
        warn("Failed to load streak data for " .. player.Name)
        data = {}
    end
    
    -- Initialize default data if needed
    if not data.lastLoginDay then
        data = {
            currentStreak = 0,
            longestStreak = 0,
            lastLoginDay = 0,
            totalRewardsClaimed = 0,
            streakRewardsClaimed = {}
        }
    end
    
    -- Check if streak should continue or reset
    if data.lastLoginDay == currentDay then
        -- Already logged in today
        playerStreaks[userId] = data
        return data, false -- false = no new reward
    elseif data.lastLoginDay == currentDay - 1 then
        -- Logged in yesterday, continue streak
        data.currentStreak = data.currentStreak + 1
        data.lastLoginDay = currentDay
        
        -- Update longest streak if needed
        if data.currentStreak > data.longestStreak then
            data.longestStreak = data.currentStreak
        end
        
        playerStreaks[userId] = data
        self:SavePlayerStreak(player, data)
        return data, true -- true = new reward available
    else
        -- Streak broken or first time
        local wasStreakBroken = data.currentStreak > 0
        data.currentStreak = 1
        data.lastLoginDay = currentDay
        
        playerStreaks[userId] = data
        self:SavePlayerStreak(player, data)
        
        -- Log streak break if applicable
        if wasStreakBroken and AnalyticsService then
            AnalyticsService:LogEvent(player, AnalyticsService.EventTypes.DAILY_STREAK_BROKEN, {
                brokenStreak = data.currentStreak,
                daysMissed = currentDay - data.lastLoginDay - 1
            })
        end
        
        return data, true -- true = new reward available (day 1)
    end
end

function DailyStreakService:SavePlayerStreak(player, data)
    local userId = tostring(player.UserId)
    
    local success = pcall(function()
        dailyStreakStore:SetAsync(userId, data)
    end)
    
    if not success then
        warn("Failed to save streak data for " .. player.Name)
    end
    
    -- Sync with main player data if PlayerService is available
    if PlayerService then
        local playerData = PlayerService:GetPlayerData(player)
        if playerData then
            playerData.dailyStreak = data.currentStreak
            playerData.longestStreak = data.longestStreak
            playerData.lastStreakLogin = data.lastLoginDay
            PlayerService:UpdatePlayerData(player, playerData)
        end
    end
end

function DailyStreakService:GetStreakReward(streakDay)
    return STREAK_REWARDS[streakDay] or DEFAULT_LONG_STREAK_REWARD
end

function DailyStreakService:ClaimDailyReward(player)
    local userId = tostring(player.UserId)
    local streakData = playerStreaks[userId]
    
    if not streakData then
        -- Load streak data first
        streakData, _ = self:LoadPlayerStreak(player)
    end
    
    local currentDay = self:GetDaysSinceEpoch()
    
    -- Check if already claimed today
    if streakData.streakRewardsClaimed[currentDay] then
        RemoteEvents.ShowNotification:FireClient(player, "⚠️ Daily reward already claimed today!")
        return false
    end
    
    -- Get reward for current streak
    local reward = self:GetStreakReward(streakData.currentStreak)
    
    -- Apply reward
    if PlayerService then
        local playerData = PlayerService:GetPlayerData(player)
        if playerData then
            playerData.coins = playerData.coins + reward.coins
            playerData.totalCoinsEarned = (playerData.totalCoinsEarned or 0) + reward.coins
            PlayerService:UpdatePlayerData(player, playerData)
        end
    end
    
    -- Apply special effects
    if reward.type == "special" then
        RemoteEvents.ApplySpecialEffect:FireClient(player, reward.effect, reward.duration)
    elseif reward.type == "mega" then
        RemoteEvents.ApplySpecialEffect:FireClient(player, reward.effect, reward.duration)
        RemoteEvents.PlaySpecialSound:FireClient(player, "mega_reward")
    elseif reward.type == "ultimate" then
        RemoteEvents.ApplySpecialEffect:FireClient(player, reward.effect, reward.duration)
        RemoteEvents.PlaySpecialSound:FireClient(player, "ultimate_reward")
    end
    
    -- Mark as claimed
    streakData.streakRewardsClaimed[currentDay] = true
    streakData.totalRewardsClaimed = streakData.totalRewardsClaimed + 1
    
    -- Save updated data
    self:SavePlayerStreak(player, streakData)
    
    -- Show reward notification
    RemoteEvents.ShowStreakReward:FireClient(player, {
        day = streakData.currentStreak,
        coins = reward.coins,
        message = reward.message,
        type = reward.type,
        effect = reward.effect
    })
    
    -- Analytics
    if AnalyticsService then
        AnalyticsService:LogEvent(player, AnalyticsService.EventTypes.DAILY_STREAK_CLAIMED, {
            streakDay = streakData.currentStreak,
            coinsRewarded = reward.coins,
            rewardType = reward.type,
            longestStreak = streakData.longestStreak
        })
    end
    
    -- Update quest progress
    if QuestService then
        QuestService:UpdateQuestProgress(player, "daily_streak", streakData.currentStreak)
    end
    
    print("🔥 " .. player.Name .. " claimed day " .. streakData.currentStreak .. " streak reward: " .. reward.coins .. " coins")
    return true
end

function DailyStreakService:ShowStreakUI(player)
    local userId = tostring(player.UserId)
    local streakData = playerStreaks[userId]
    
    if not streakData then
        -- Load streak data first
        streakData, hasNewReward = self:LoadPlayerStreak(player)
    end
    
    local currentDay = self:GetDaysSinceEpoch()
    local canClaim = not streakData.streakRewardsClaimed[currentDay]
    
    -- Send streak data to client
    RemoteEvents.ShowStreakUI:FireClient(player, {
        currentStreak = streakData.currentStreak,
        longestStreak = streakData.longestStreak,
        canClaimToday = canClaim,
        nextReward = self:GetStreakReward(streakData.currentStreak + 1),
        currentReward = self:GetStreakReward(streakData.currentStreak),
        totalClaimed = streakData.totalRewardsClaimed
    })
end

function DailyStreakService:GetPlayerStreakData(player)
    local userId = tostring(player.UserId)
    return playerStreaks[userId]
end

function DailyStreakService:CheckAndProcessDailyLogin(player)
    -- Called when player joins - check if they should get a streak reward
    local streakData, hasNewReward = self:LoadPlayerStreak(player)
    
    if hasNewReward then
        -- Show streak notification after a brief delay
        spawn(function()
            wait(3) -- Wait for player to fully load
            
            local currentDay = self:GetDaysSinceEpoch()
            local canClaim = not streakData.streakRewardsClaimed[currentDay]
            
            if canClaim then
                RemoteEvents.ShowStreakAvailable:FireClient(player, {
                    day = streakData.currentStreak,
                    reward = self:GetStreakReward(streakData.currentStreak)
                })
            end
        end)
    end
    
    return streakData
end

-- Service dependency setters
function DailyStreakService:SetPlayerService(service)
    PlayerService = service
end

function DailyStreakService:SetAnalyticsService(service)
    AnalyticsService = service
end

function DailyStreakService:SetQuestService(service)
    QuestService = service
end

-- Handle player joining
local function onPlayerAdded(player)
    spawn(function()
        wait(2) -- Wait for player to fully load
        DailyStreakService:CheckAndProcessDailyLogin(player)
    end)
end

-- Connect events
Players.PlayerAdded:Connect(onPlayerAdded)

-- Remote event handlers
RemoteEvents.ClaimDailyStreak.OnServerEvent:Connect(function(player)
    DailyStreakService:ClaimDailyReward(player)
end)

RemoteEvents.RequestStreakData.OnServerEvent:Connect(function(player)
    DailyStreakService:ShowStreakUI(player)
end)

-- Initialize automatically
DailyStreakService:Init()

return DailyStreakService
