-- LeaderboardService.luau
-- Handles global leaderboards with DataStore persistence and real-time updates

local Players = game:GetService("Players")
local DataStoreService = game:GetService("DataStoreService")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local PlayerService = require(script.Parent.PlayerService)

local LeaderboardService = {}

-- DataStores for leaderboards
local highScoreStore = DataStoreService:GetOrderedDataStore("GlobalHighScores")
local totalCoinsStore = DataStoreService:GetOrderedDataStore("GlobalTotalCoins")

-- Cache for leaderboard data
local highScoreLeaderboard = {}
local coinsLeaderboard = {}

-- Update intervals
local LEADERBOARD_UPDATE_INTERVAL = 30 -- seconds
local lastUpdate = 0

function LeaderboardService:GetTopPlayers(dataStore, count)
    local success, result = pcall(function()
        return dataStore:GetSortedAsync(false, count or 5)
    end)
    
    if success and result then
        local topPlayers = {}
        local currentPage = result:GetCurrentPage()
        
        for rank, entry in ipairs(currentPage) do
            table.insert(topPlayers, {
                rank = rank,
                userId = entry.key,
                value = entry.value,
                playerName = "Loading..." -- Will be resolved later
            })
        end
        
        return topPlayers
    else
        warn("Failed to fetch leaderboard data")
        return {}
    end
end

function LeaderboardService:ResolvePlayerNames(leaderboardData)
    for _, entry in pairs(leaderboardData) do
        local success, playerName = pcall(function()
            return Players:GetNameFromUserIdAsync(tonumber(entry.userId))
        end)
        
        if success then
            entry.playerName = playerName
        else
            entry.playerName = "Unknown Player"
        end
    end
end

function LeaderboardService:UpdatePlayerScore(userId, newHighScore)
    local success = pcall(function()
        -- Get current score
        local currentScore = highScoreStore:GetAsync(tostring(userId)) or 0
        
        -- Only update if new score is higher
        if newHighScore > currentScore then
            highScoreStore:SetAsync(tostring(userId), newHighScore)
            print("📊 Updated high score for user " .. userId .. ": " .. newHighScore)
            
            -- Trigger leaderboard refresh
            self:RefreshLeaderboards()
        end
    end)
    
    if not success then
        warn("Failed to update high score for user " .. userId)
    end
end

function LeaderboardService:UpdatePlayerCoins(userId, totalCoins)
    local success = pcall(function()
        totalCoinsStore:SetAsync(tostring(userId), totalCoins)
        print("💰 Updated total coins for user " .. userId .. ": " .. totalCoins)
        
        -- Trigger leaderboard refresh  
        self:RefreshLeaderboards()
    end)
    
    if not success then
        warn("Failed to update total coins for user " .. userId)
    end
end

function LeaderboardService:RefreshLeaderboards()
    -- Get top 5 high scores
    highScoreLeaderboard = self:GetTopPlayers(highScoreStore, 5)
    self:ResolvePlayerNames(highScoreLeaderboard)
    
    -- Get top 5 coin collectors
    coinsLeaderboard = self:GetTopPlayers(totalCoinsStore, 5)
    self:ResolvePlayerNames(coinsLeaderboard)
    
    -- Update the display screens
    self:UpdateLeaderboardDisplays()
    
    print("📊 Leaderboards refreshed")
end

function LeaderboardService:CreateLeaderboardGUI(screen, title, leaderboardData, valuePrefix)
    -- Remove existing GUI
    local existingGui = screen:FindFirstChild("SurfaceGui")
    if existingGui then
        existingGui:Destroy()
    end
    
    -- Create new GUI
    local surfaceGui = Instance.new("SurfaceGui")
    surfaceGui.Face = Enum.NormalId.Back
    surfaceGui.Parent = screen
    
    -- Background
    local background = Instance.new("Frame")
    background.Size = UDim2.new(1, 0, 1, 0)
    background.BackgroundColor3 = Color3.new(0.05, 0.05, 0.1)
    background.BorderSizePixel = 0
    background.Parent = surfaceGui
    
    -- Title
    local titleLabel = Instance.new("TextLabel")
    titleLabel.Size = UDim2.new(1, 0, 0.15, 0)
    titleLabel.Position = UDim2.new(0, 0, 0.05, 0)
    titleLabel.BackgroundTransparency = 1
    titleLabel.Text = title
    titleLabel.TextColor3 = Color3.new(1, 1, 1)
    titleLabel.TextScaled = true
    titleLabel.Font = Enum.Font.SourceSansBold
    titleLabel.Parent = background
    
    -- Create entries
    for i, entry in ipairs(leaderboardData) do
        local entryFrame = Instance.new("Frame")
        entryFrame.Size = UDim2.new(0.9, 0, 0.12, 0)
        entryFrame.Position = UDim2.new(0.05, 0, 0.2 + (i - 1) * 0.14, 0)
        entryFrame.BackgroundColor3 = Color3.new(0.1, 0.1, 0.15)
        entryFrame.BorderSizePixel = 1
        entryFrame.BorderColor3 = Color3.new(0.3, 0.3, 0.4)
        entryFrame.Parent = background
        
        -- Rank
        local rankLabel = Instance.new("TextLabel")
        rankLabel.Size = UDim2.new(0.15, 0, 1, 0)
        rankLabel.BackgroundTransparency = 1
        rankLabel.Text = "#" .. entry.rank
        rankLabel.TextColor3 = self:GetRankColor(entry.rank)
        rankLabel.TextScaled = true
        rankLabel.Font = Enum.Font.SourceSansBold
        rankLabel.Parent = entryFrame
        
        -- Player name
        local nameLabel = Instance.new("TextLabel")
        nameLabel.Size = UDim2.new(0.55, 0, 1, 0)
        nameLabel.Position = UDim2.new(0.15, 0, 0, 0)
        nameLabel.BackgroundTransparency = 1
        nameLabel.Text = entry.playerName
        nameLabel.TextColor3 = Color3.new(1, 1, 1)
        nameLabel.TextScaled = true
        nameLabel.Font = Enum.Font.SourceSans
        nameLabel.TextXAlignment = Enum.TextXAlignment.Left
        nameLabel.Parent = entryFrame
        
        -- Value
        local valueLabel = Instance.new("TextLabel")
        valueLabel.Size = UDim2.new(0.3, 0, 1, 0)
        valueLabel.Position = UDim2.new(0.7, 0, 0, 0)
        valueLabel.BackgroundTransparency = 1
        valueLabel.Text = valuePrefix .. entry.value
        valueLabel.TextColor3 = Color3.new(0.8, 1, 0.8)
        valueLabel.TextScaled = true
        valueLabel.Font = Enum.Font.SourceSansBold
        valueLabel.TextXAlignment = Enum.TextXAlignment.Right
        valueLabel.Parent = entryFrame
    end
    
    -- Last updated timestamp
    local timestampLabel = Instance.new("TextLabel")
    timestampLabel.Size = UDim2.new(1, 0, 0.08, 0)
    timestampLabel.Position = UDim2.new(0, 0, 0.9, 0)
    timestampLabel.BackgroundTransparency = 1
    timestampLabel.Text = "Updated: " .. os.date("%H:%M:%S")
    timestampLabel.TextColor3 = Color3.new(0.6, 0.6, 0.6)
    timestampLabel.TextScaled = true
    timestampLabel.Font = Enum.Font.SourceSans
    timestampLabel.Parent = background
end

function LeaderboardService:GetRankColor(rank)
    if rank == 1 then
        return Color3.new(1, 0.8, 0) -- Gold
    elseif rank == 2 then
        return Color3.new(0.7, 0.7, 0.7) -- Silver
    elseif rank == 3 then
        return Color3.new(0.8, 0.5, 0.3) -- Bronze
    else
        return Color3.new(0.9, 0.9, 0.9) -- White
    end
end

function LeaderboardService:UpdateLeaderboardDisplays()
    local plaza = Workspace:FindFirstChild("MarketPlaza")
    if not plaza then return end
    
    local screens = plaza:FindFirstChild("LeaderboardScreens")
    if not screens then return end
    
    -- Update High Score Screen
    local highScoreScreen = screens:FindFirstChild("HighScoreScreen")
    if highScoreScreen then
        local screenDisplay = highScoreScreen:FindFirstChild("ScreenDisplay")
        if screenDisplay then
            self:CreateLeaderboardGUI(
                screenDisplay,
                "🏆 TOP RUNNERS 🏆",
                highScoreLeaderboard,
                ""
            )
        end
    end
    
    -- Update Coins Screen
    local coinsScreen = screens:FindFirstChild("CoinsScreen")
    if coinsScreen then
        local screenDisplay = coinsScreen:FindFirstChild("ScreenDisplay")
        if screenDisplay then
            self:CreateLeaderboardGUI(
                screenDisplay,
                "💰 TOP COLLECTORS 💰",
                coinsLeaderboard,
                "💰"
            )
        end
    end
end

function LeaderboardService:HandlePlayerDataUpdate(player, newData)
    local userId = player.UserId
    
    -- Update high score if it's higher
    if newData.highScore and newData.highScore > 0 then
        self:UpdatePlayerScore(userId, newData.highScore)
    end
    
    -- Update total coins earned (not current coins)
    if newData.totalCoinsEarned and newData.totalCoinsEarned > 0 then
        self:UpdatePlayerCoins(userId, newData.totalCoinsEarned)
    end
end

function LeaderboardService:Init()
    -- Initial leaderboard load
    self:RefreshLeaderboards()
    
    -- Set up periodic updates
    RunService.Heartbeat:Connect(function()
        if tick() - lastUpdate >= LEADERBOARD_UPDATE_INTERVAL then
            lastUpdate = tick()
            self:RefreshLeaderboards()
        end
    end)
    
    -- Listen for player data updates
    Players.PlayerRemoving:Connect(function(player)
        -- Ensure final data is saved to leaderboards
        local playerData = PlayerService:GetPlayerData(player)
        if playerData then
            self:HandlePlayerDataUpdate(player, playerData)
        end
    end)
    
    print("✅ LeaderboardService initialized")
end

-- Function to be called by PlayerService when data updates
function LeaderboardService:OnPlayerDataUpdated(player, newData)
    self:HandlePlayerDataUpdate(player, newData)
end

return LeaderboardService
