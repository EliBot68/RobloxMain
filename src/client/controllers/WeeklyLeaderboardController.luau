-- WeeklyLeaderboardController.luau
-- Weekly leaderboard system for hub area

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local RemoteEvents = require(ReplicatedStorage.Shared.modules.RemoteEvents)

local WeeklyLeaderboardController = {}

-- UI Elements
local leaderboardGui = nil
local leaderboardFrame = nil
local rewardChestGui = nil
local currentLeaderboardData = {}
local lastUpdateTime = 0

-- Configuration
local LEADERBOARD_POSITION = Vector3.new(0, 5, -50) -- Position in hub
local CHEST_POSITION = Vector3.new(5, 3, -50) -- Reward chest position
local UPDATE_INTERVAL = 30 -- Update every 30 seconds

function WeeklyLeaderboardController:CreateLeaderboardUI()
    -- Create leaderboard GUI
    leaderboardGui = Instance.new("ScreenGui")
    leaderboardGui.Name = "WeeklyLeaderboardGui"
    leaderboardGui.ResetOnSpawn = false
    leaderboardGui.Parent = playerGui
    
    -- Main leaderboard frame
    leaderboardFrame = Instance.new("Frame")
    leaderboardFrame.Name = "LeaderboardFrame"
    leaderboardFrame.Size = UDim2.new(0, 400, 0, 600)
    leaderboardFrame.Position = UDim2.new(0, 50, 0.5, -300)
    leaderboardFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
    leaderboardFrame.BorderSizePixel = 0
    leaderboardFrame.Visible = false
    leaderboardFrame.Parent = leaderboardGui
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 15)
    corner.Parent = leaderboardFrame
    
    -- Glow effect
    local glow = Instance.new("Frame")
    glow.Name = "Glow"
    glow.Size = UDim2.new(1, 20, 1, 20)
    glow.Position = UDim2.new(0, -10, 0, -10)
    glow.BackgroundColor3 = Color3.fromRGB(255, 215, 0)
    glow.BackgroundTransparency = 0.8
    glow.BorderSizePixel = 0
    glow.ZIndex = leaderboardFrame.ZIndex - 1
    glow.Parent = leaderboardFrame
    
    local glowCorner = Instance.new("UICorner")
    glowCorner.CornerRadius = UDim.new(0, 20)
    glowCorner.Parent = glow
    
    -- Animate glow
    local glowTween = TweenService:Create(glow, 
        TweenInfo.new(2, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true),
        {BackgroundTransparency = 0.6}
    )
    glowTween:Play()
    
    -- Header
    local header = Instance.new("Frame")
    header.Name = "Header"
    header.Size = UDim2.new(1, 0, 0, 80)
    header.Position = UDim2.new(0, 0, 0, 0)
    header.BackgroundColor3 = Color3.fromRGB(255, 215, 0)
    header.BorderSizePixel = 0
    header.Parent = leaderboardFrame
    
    local headerCorner = Instance.new("UICorner")
    headerCorner.CornerRadius = UDim.new(0, 15)
    headerCorner.Parent = header
    
    -- Fix header corner to only round top
    local headerBottomCover = Instance.new("Frame")
    headerBottomCover.Size = UDim2.new(1, 0, 0, 15)
    headerBottomCover.Position = UDim2.new(0, 0, 1, -15)
    headerBottomCover.BackgroundColor3 = Color3.fromRGB(255, 215, 0)
    headerBottomCover.BorderSizePixel = 0
    headerBottomCover.Parent = header
    
    -- Title
    local title = Instance.new("TextLabel")
    title.Name = "Title"
    title.Size = UDim2.new(1, -20, 0, 40)
    title.Position = UDim2.new(0, 10, 0, 5)
    title.BackgroundTransparency = 1
    title.Text = "🏆 WEEKLY LEADERBOARD"
    title.TextColor3 = Color3.new(0, 0, 0)
    title.TextSize = 20
    title.Font = Enum.Font.GothamBold
    title.TextStrokeTransparency = 0
    title.TextStrokeColor3 = Color3.new(1, 1, 1)
    title.Parent = header
    
    -- Subtitle
    local subtitle = Instance.new("TextLabel")
    subtitle.Name = "Subtitle"
    subtitle.Size = UDim2.new(1, -20, 0, 30)
    subtitle.Position = UDim2.new(0, 10, 0, 45)
    subtitle.BackgroundTransparency = 1
    subtitle.Text = "Most Coins This Week"
    subtitle.TextColor3 = Color3.fromRGB(80, 80, 80)
    subtitle.TextSize = 14
    subtitle.Font = Enum.Font.Gotham
    subtitle.Parent = header
    
    -- Reset timer
    local resetTimer = Instance.new("TextLabel")
    resetTimer.Name = "ResetTimer"
    resetTimer.Size = UDim2.new(1, -20, 0, 25)
    resetTimer.Position = UDim2.new(0, 10, 1, -30)
    resetTimer.BackgroundTransparency = 1
    resetTimer.Text = "Resets in: Loading..."
    resetTimer.TextColor3 = Color3.fromRGB(150, 150, 150)
    resetTimer.TextSize = 12
    resetTimer.Font = Enum.Font.Gotham
    resetTimer.Parent = leaderboardFrame
    
    -- Players list container
    local playersContainer = Instance.new("ScrollingFrame")
    playersContainer.Name = "PlayersContainer"
    playersContainer.Size = UDim2.new(1, -20, 1, -140)
    playersContainer.Position = UDim2.new(0, 10, 0, 90)
    playersContainer.BackgroundTransparency = 1
    playersContainer.BorderSizePixel = 0
    playersContainer.ScrollBarThickness = 6
    playersContainer.ScrollBarImageColor3 = Color3.fromRGB(255, 215, 0)
    playersContainer.Parent = leaderboardFrame
    
    local listLayout = Instance.new("UIListLayout")
    listLayout.SortOrder = Enum.SortOrder.LayoutOrder
    listLayout.Padding = UDim.new(0, 10)
    listLayout.Parent = playersContainer
    
    return leaderboardFrame
end

function WeeklyLeaderboardController:CreatePlayerEntry(rank, playerData, parent)
    local entry = Instance.new("Frame")
    entry.Name = "PlayerEntry" .. rank
    entry.Size = UDim2.new(1, -10, 0, 80)
    entry.BackgroundColor3 = self:GetRankColor(rank)
    entry.BorderSizePixel = 0
    entry.LayoutOrder = rank
    entry.Parent = parent
    
    local entryCorner = Instance.new("UICorner")
    entryCorner.CornerRadius = UDim.new(0, 10)
    entryCorner.Parent = entry
    
    -- Rank badge
    local rankBadge = Instance.new("Frame")
    rankBadge.Name = "RankBadge"
    rankBadge.Size = UDim2.new(0, 60, 0, 60)
    rankBadge.Position = UDim2.new(0, 10, 0, 10)
    rankBadge.BackgroundColor3 = self:GetBadgeColor(rank)
    rankBadge.BorderSizePixel = 0
    rankBadge.Parent = entry
    
    local badgeCorner = Instance.new("UICorner")
    badgeCorner.CornerRadius = UDim.new(0, 30)
    badgeCorner.Parent = rankBadge
    
    local rankText = Instance.new("TextLabel")
    rankText.Size = UDim2.new(1, 0, 1, 0)
    rankText.BackgroundTransparency = 1
    rankText.Text = self:GetRankIcon(rank)
    rankText.TextColor3 = Color3.new(1, 1, 1)
    rankText.TextSize = rank <= 3 and 24 or 20
    rankText.Font = Enum.Font.GothamBold
    rankText.Parent = rankBadge
    
    -- Player avatar (simplified)
    local avatarFrame = Instance.new("Frame")
    avatarFrame.Name = "AvatarFrame"
    avatarFrame.Size = UDim2.new(0, 50, 0, 50)
    avatarFrame.Position = UDim2.new(0, 80, 0, 15)
    avatarFrame.BackgroundColor3 = Color3.fromRGB(100, 100, 100)
    avatarFrame.BorderSizePixel = 0
    avatarFrame.Parent = entry
    
    local avatarCorner = Instance.new("UICorner")
    avatarCorner.CornerRadius = UDim.new(0, 25)
    avatarCorner.Parent = avatarFrame
    
    -- Try to load actual avatar
    local avatarImage = Instance.new("ImageLabel")
    avatarImage.Size = UDim2.new(1, 0, 1, 0)
    avatarImage.BackgroundTransparency = 1
    avatarImage.Image = "https://www.roblox.com/headshot-thumbnail/image?userId=" .. playerData.userId .. "&width=150&height=150&format=png"
    avatarImage.Parent = avatarFrame
    
    local avatarImageCorner = Instance.new("UICorner")
    avatarImageCorner.CornerRadius = UDim.new(0, 25)
    avatarImageCorner.Parent = avatarImage
    
    -- Player name
    local nameLabel = Instance.new("TextLabel")
    nameLabel.Name = "NameLabel"
    nameLabel.Size = UDim2.new(0, 150, 0, 25)
    nameLabel.Position = UDim2.new(0, 140, 0, 15)
    nameLabel.BackgroundTransparency = 1
    nameLabel.Text = playerData.displayName or playerData.username
    nameLabel.TextColor3 = Color3.new(1, 1, 1)
    nameLabel.TextSize = 16
    nameLabel.Font = Enum.Font.GothamBold
    nameLabel.TextXAlignment = Enum.TextXAlignment.Left
    nameLabel.TextStrokeTransparency = 0
    nameLabel.TextStrokeColor3 = Color3.new(0, 0, 0)
    nameLabel.Parent = entry
    
    -- Coins amount
    local coinsLabel = Instance.new("TextLabel")
    coinsLabel.Name = "CoinsLabel"
    coinsLabel.Size = UDim2.new(0, 150, 0, 25)
    coinsLabel.Position = UDim2.new(0, 140, 0, 40)
    coinsLabel.BackgroundTransparency = 1
    coinsLabel.Text = "💰 " .. self:FormatNumber(playerData.weeklyCoins)
    coinsLabel.TextColor3 = Color3.fromRGB(255, 215, 0)
    coinsLabel.TextSize = 14
    coinsLabel.Font = Enum.Font.Gotham
    coinsLabel.TextXAlignment = Enum.TextXAlignment.Left
    coinsLabel.TextStrokeTransparency = 0
    coinsLabel.TextStrokeColor3 = Color3.new(0, 0, 0)
    coinsLabel.Parent = entry
    
    -- Special effects for top 3
    if rank <= 3 then
        self:AddSpecialEffects(entry, rank)
    end
    
    return entry
end

function WeeklyLeaderboardController:GetRankColor(rank)
    if rank == 1 then
        return Color3.fromRGB(255, 215, 0) -- Gold
    elseif rank == 2 then
        return Color3.fromRGB(192, 192, 192) -- Silver
    elseif rank == 3 then
        return Color3.fromRGB(205, 127, 50) -- Bronze
    else
        return Color3.fromRGB(60, 60, 70) -- Default
    end
end

function WeeklyLeaderboardController:GetBadgeColor(rank)
    if rank == 1 then
        return Color3.fromRGB(218, 165, 32) -- Dark gold
    elseif rank == 2 then
        return Color3.fromRGB(169, 169, 169) -- Dark silver
    elseif rank == 3 then
        return Color3.fromRGB(184, 115, 51) -- Dark bronze
    else
        return Color3.fromRGB(40, 40, 50) -- Dark default
    end
end

function WeeklyLeaderboardController:GetRankIcon(rank)
    if rank == 1 then
        return "👑"
    elseif rank == 2 then
        return "🥈"
    elseif rank == 3 then
        return "🥉"
    else
        return "#" .. rank
    end
end

function WeeklyLeaderboardController:AddSpecialEffects(entry, rank)
    -- Glow effect for top 3
    local glow = Instance.new("Frame")
    glow.Name = "Glow"
    glow.Size = UDim2.new(1, 6, 1, 6)
    glow.Position = UDim2.new(0, -3, 0, -3)
    glow.BackgroundColor3 = self:GetRankColor(rank)
    glow.BackgroundTransparency = 0.7
    glow.BorderSizePixel = 0
    glow.ZIndex = entry.ZIndex - 1
    glow.Parent = entry
    
    local glowCorner = Instance.new("UICorner")
    glowCorner.CornerRadius = UDim.new(0, 13)
    glowCorner.Parent = glow
    
    -- Animate glow for rank 1
    if rank == 1 then
        local glowTween = TweenService:Create(glow,
            TweenInfo.new(1.5, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true),
            {BackgroundTransparency = 0.4}
        )
        glowTween:Play()
    end
    
    -- Sparkle particles for rank 1
    if rank == 1 then
        for i = 1, 5 do
            local sparkle = Instance.new("ImageLabel")
            sparkle.Size = UDim2.new(0, 15, 0, 15)
            sparkle.Position = UDim2.new(
                0, math.random(10, entry.AbsoluteSize.X - 25),
                0, math.random(10, entry.AbsoluteSize.Y - 25)
            )
            sparkle.BackgroundTransparency = 1
            sparkle.Image = "rbxasset://textures/particles/sparkles_main.dds"
            sparkle.ImageColor3 = Color3.fromRGB(255, 255, 0)
            sparkle.Parent = entry
            
            -- Animate sparkles
            local moveTween = TweenService:Create(sparkle,
                TweenInfo.new(3, Enum.EasingStyle.Linear, Enum.EasingDirection.InOut, -1),
                {
                    Position = sparkle.Position + UDim2.new(0, math.random(-20, 20), 0, math.random(-20, 20)),
                    Rotation = 360
                }
            )
            
            local fadeTween = TweenService:Create(sparkle,
                TweenInfo.new(1.5, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true),
                {ImageTransparency = 0.8}
            )
            
            moveTween:Play()
            fadeTween:Play()
        end
    end
end

function WeeklyLeaderboardController:CreateRewardChest()
    -- Create reward chest GUI for interaction
    rewardChestGui = Instance.new("ScreenGui")
    rewardChestGui.Name = "RewardChestGui"
    rewardChestGui.ResetOnSpawn = false
    rewardChestGui.Enabled = false
    rewardChestGui.Parent = playerGui
    
    -- Chest interaction prompt
    local chestPrompt = Instance.new("Frame")
    chestPrompt.Name = "ChestPrompt"
    chestPrompt.Size = UDim2.new(0, 300, 0, 200)
    chestPrompt.Position = UDim2.new(0.5, -150, 0.5, -100)
    chestPrompt.BackgroundColor3 = Color3.fromRGB(40, 40, 50)
    chestPrompt.BorderSizePixel = 0
    chestPrompt.Parent = rewardChestGui
    
    local chestCorner = Instance.new("UICorner")
    chestCorner.CornerRadius = UDim.new(0, 15)
    chestCorner.Parent = chestPrompt
    
    -- Chest icon
    local chestIcon = Instance.new("TextLabel")
    chestIcon.Size = UDim2.new(1, 0, 0, 60)
    chestIcon.Position = UDim2.new(0, 0, 0, 20)
    chestIcon.BackgroundTransparency = 1
    chestIcon.Text = "📦"
    chestIcon.TextSize = 48
    chestIcon.Font = Enum.Font.GothamBold
    chestIcon.Parent = chestPrompt
    
    -- Chest title
    local chestTitle = Instance.new("TextLabel")
    chestTitle.Size = UDim2.new(1, -20, 0, 30)
    chestTitle.Position = UDim2.new(0, 10, 0, 90)
    chestTitle.BackgroundTransparency = 1
    chestTitle.Text = "🏆 WEEKLY REWARDS"
    chestTitle.TextColor3 = Color3.fromRGB(255, 215, 0)
    chestTitle.TextSize = 18
    chestTitle.Font = Enum.Font.GothamBold
    chestTitle.Parent = chestPrompt
    
    -- Reward info
    local rewardInfo = Instance.new("TextLabel")
    rewardInfo.Name = "RewardInfo"
    rewardInfo.Size = UDim2.new(1, -20, 0, 40)
    rewardInfo.Position = UDim2.new(0, 10, 0, 125)
    rewardInfo.BackgroundTransparency = 1
    rewardInfo.Text = "Claim your weekly rewards!"
    rewardInfo.TextColor3 = Color3.new(1, 1, 1)
    rewardInfo.TextSize = 14
    rewardInfo.Font = Enum.Font.Gotham
    rewardInfo.TextWrapped = true
    rewardInfo.Parent = chestPrompt
    
    -- Claim button
    local claimButton = Instance.new("TextButton")
    claimButton.Name = "ClaimButton"
    claimButton.Size = UDim2.new(0, 120, 0, 35)
    claimButton.Position = UDim2.new(0.5, -60, 1, -50)
    claimButton.BackgroundColor3 = Color3.fromRGB(100, 200, 100)
    claimButton.BorderSizePixel = 0
    claimButton.Text = "CLAIM REWARD"
    claimButton.TextColor3 = Color3.new(1, 1, 1)
    claimButton.TextSize = 14
    claimButton.Font = Enum.Font.GothamBold
    claimButton.Parent = chestPrompt
    
    local claimCorner = Instance.new("UICorner")
    claimCorner.CornerRadius = UDim.new(0, 8)
    claimCorner.Parent = claimButton
    
    -- Close button
    local closeButton = Instance.new("TextButton")
    closeButton.Name = "CloseButton"
    closeButton.Size = UDim2.new(0, 30, 0, 30)
    closeButton.Position = UDim2.new(1, -35, 0, 5)
    closeButton.BackgroundColor3 = Color3.fromRGB(200, 100, 100)
    closeButton.BorderSizePixel = 0
    closeButton.Text = "✕"
    closeButton.TextColor3 = Color3.new(1, 1, 1)
    closeButton.TextSize = 16
    closeButton.Font = Enum.Font.GothamBold
    closeButton.Parent = chestPrompt
    
    local closeCorner = Instance.new("UICorner")
    closeCorner.CornerRadius = UDim.new(0, 6)
    closeCorner.Parent = closeButton
    
    -- Event connections
    claimButton.MouseButton1Click:Connect(function()
        self:ClaimWeeklyReward()
    end)
    
    closeButton.MouseButton1Click:Connect(function()
        rewardChestGui.Enabled = false
    end)
    
    return rewardChestGui
end

function WeeklyLeaderboardController:UpdateLeaderboard(leaderboardData)
    if not leaderboardFrame then return end
    
    currentLeaderboardData = leaderboardData
    
    local playersContainer = leaderboardFrame.PlayersContainer
    
    -- Clear existing entries
    for _, child in pairs(playersContainer:GetChildren()) do
        if child:IsA("Frame") and child.Name:find("PlayerEntry") then
            child:Destroy()
        end
    end
    
    -- Create new entries
    for rank, playerData in ipairs(leaderboardData.topPlayers) do
        if rank <= 5 then -- Only show top 5
            self:CreatePlayerEntry(rank, playerData, playersContainer)
        end
    end
    
    -- Update canvas size
    playersContainer.CanvasSize = UDim2.new(0, 0, 0, playersContainer.UIListLayout.AbsoluteContentSize.Y + 20)
    
    -- Update reset timer
    self:UpdateResetTimer(leaderboardData.timeUntilReset)
    
    print("📊 Weekly leaderboard updated with", #leaderboardData.topPlayers, "players")
end

function WeeklyLeaderboardController:UpdateResetTimer(timeUntilReset)
    if not leaderboardFrame then return end
    
    local resetTimer = leaderboardFrame.ResetTimer
    if not resetTimer then return end
    
    if timeUntilReset and timeUntilReset > 0 then
        local days = math.floor(timeUntilReset / 86400)
        local hours = math.floor((timeUntilReset % 86400) / 3600)
        local minutes = math.floor((timeUntilReset % 3600) / 60)
        
        if days > 0 then
            resetTimer.Text = string.format("Resets in: %dd %dh %dm", days, hours, minutes)
        elseif hours > 0 then
            resetTimer.Text = string.format("Resets in: %dh %dm", hours, minutes)
        else
            resetTimer.Text = string.format("Resets in: %dm", minutes)
        end
    else
        resetTimer.Text = "Resets in: Soon..."
    end
end

function WeeklyLeaderboardController:FormatNumber(number)
    if number >= 1000000 then
        return string.format("%.1fM", number / 1000000)
    elseif number >= 1000 then
        return string.format("%.1fK", number / 1000)
    else
        return tostring(number)
    end
end

function WeeklyLeaderboardController:ShowLeaderboard()
    if leaderboardFrame then
        leaderboardFrame.Visible = true
        
        -- Slide in animation
        leaderboardFrame.Position = UDim2.new(0, -400, 0.5, -300)
        local slideIn = TweenService:Create(leaderboardFrame,
            TweenInfo.new(0.5, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
            {Position = UDim2.new(0, 50, 0.5, -300)}
        )
        slideIn:Play()
    end
end

function WeeklyLeaderboardController:HideLeaderboard()
    if leaderboardFrame then
        local slideOut = TweenService:Create(leaderboardFrame,
            TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.In),
            {Position = UDim2.new(0, -400, 0.5, -300)}
        )
        slideOut:Play()
        slideOut.Completed:Connect(function()
            leaderboardFrame.Visible = false
        end)
    end
end

function WeeklyLeaderboardController:ShowRewardChest(rewardData)
    if not rewardChestGui then return end
    
    local chestPrompt = rewardChestGui.ChestPrompt
    local rewardInfo = chestPrompt.RewardInfo
    local claimButton = chestPrompt.ClaimButton
    
    -- Update reward information
    if rewardData then
        rewardInfo.Text = string.format("Rank #%d reward: %d coins!", rewardData.rank, rewardData.rewardAmount)
        claimButton.Text = rewardData.canClaim and "CLAIM REWARD" or "ALREADY CLAIMED"
        claimButton.BackgroundColor3 = rewardData.canClaim and Color3.fromRGB(100, 200, 100) or Color3.fromRGB(100, 100, 100)
        claimButton.Active = rewardData.canClaim
    end
    
    rewardChestGui.Enabled = true
end

function WeeklyLeaderboardController:ClaimWeeklyReward()
    print("🎁 Claiming weekly reward...")
    RemoteEvents.ClaimWeeklyReward:FireServer()
    rewardChestGui.Enabled = false
end

function WeeklyLeaderboardController:RequestLeaderboardUpdate()
    if tick() - lastUpdateTime > UPDATE_INTERVAL then
        RemoteEvents.RequestWeeklyLeaderboard:FireServer()
        lastUpdateTime = tick()
    end
end

function WeeklyLeaderboardController:Initialize()
    print("📊 WeeklyLeaderboardController initializing...")
    
    -- Create UI elements
    self:CreateLeaderboardUI()
    self:CreateRewardChest()
    
    -- Connect remote events
    RemoteEvents.UpdateWeeklyLeaderboard.OnClientEvent:Connect(function(leaderboardData)
        self:UpdateLeaderboard(leaderboardData)
    end)
    
    RemoteEvents.ShowWeeklyLeaderboard.OnClientEvent:Connect(function()
        self:ShowLeaderboard()
    end)
    
    RemoteEvents.HideWeeklyLeaderboard.OnClientEvent:Connect(function()
        self:HideLeaderboard()
    end)
    
    RemoteEvents.ShowWeeklyRewardChest.OnClientEvent:Connect(function(rewardData)
        self:ShowRewardChest(rewardData)
    end)
    
    RemoteEvents.WeeklyRewardClaimed.OnClientEvent:Connect(function(rewardAmount)
        print("🎁 Weekly reward claimed:", rewardAmount, "coins!")
    end)
    
    -- CONVERTED: Auto-update timer → Event-driven with adaptive intervals
    local LeaderboardUpdateEvent = Instance.new("BindableEvent")
    local updateInterval = UPDATE_INTERVAL or 30 -- Default to 30 seconds
    
    local function scheduleLeaderboardUpdate()
        task.delay(updateInterval, function()
            LeaderboardUpdateEvent:Fire()
            scheduleLeaderboardUpdate()
        end)
    end
    
    LeaderboardUpdateEvent.Event:Connect(function()
        if leaderboardFrame and leaderboardFrame.Visible then
            local beforeUpdate = tick()
            self:RequestLeaderboardUpdate()
            local updateTime = tick() - beforeUpdate
            
            -- Adaptive interval based on visibility and update time
            if updateTime > 2.0 then -- Slow updates
                updateInterval = math.min(120, updateInterval * 1.3) -- Less frequent when slow
            else
                updateInterval = math.max(15, updateInterval * 0.95) -- More frequent when fast
            end
            
            print(string.format("📊 Weekly leaderboard updated (%.2fs, next in %.0fs)", 
                updateTime, updateInterval))
        else
            -- Reduce frequency when not visible
            updateInterval = math.min(300, updateInterval * 1.5) -- Much less frequent when hidden
        end
    end)
    
    scheduleLeaderboardUpdate()
    print("✅ Weekly leaderboard auto-update converted to event-driven system (NO POLLING)")
    
    -- Request initial data
    spawn(function()
        wait(2) -- Wait for other systems
        RemoteEvents.RequestWeeklyLeaderboard:FireServer()
    end)
    
    print("✅ WeeklyLeaderboardController initialized!")
end

-- Auto-initialize
WeeklyLeaderboardController:Initialize()

return WeeklyLeaderboardController
