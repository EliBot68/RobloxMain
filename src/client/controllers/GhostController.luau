-- GhostController.luau
-- Handles client-side ghost runner display and interactions

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local RemoteEvents = require(ReplicatedStorage.Shared.modules.RemoteEvents)

local player = Players.LocalPlayer
local GhostController = {}

-- UI References
local ghostGui = nil
local ghostLeaderboard = nil
local isGhostUIOpen = false

-- Ghost viewing state
local currentGhosts = {}
local viewingGhosts = false

function GhostController:CreateGhostUI()
    -- Create main ghost GUI
    ghostGui = Instance.new("ScreenGui")
    ghostGui.Name = "GhostGUI"
    ghostGui.ResetOnSpawn = false
    ghostGui.Parent = player:WaitForChild("PlayerGui")
    
    -- Ghost info panel (top-right)
    local infoPanel = Instance.new("Frame")
    infoPanel.Name = "GhostInfoPanel"
    infoPanel.Size = UDim2.new(0, 300, 0, 150)
    infoPanel.Position = UDim2.new(1, -320, 0, 20)
    infoPanel.BackgroundColor3 = Color3.new(0.1, 0.1, 0.1)
    infoPanel.BackgroundTransparency = 0.2
    infoPanel.Visible = false
    infoPanel.Parent = ghostGui
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 10)
    corner.Parent = infoPanel
    
    -- Title
    local title = Instance.new("TextLabel")
    title.Name = "Title"
    title.Size = UDim2.new(1, 0, 0, 30)
    title.Position = UDim2.new(0, 0, 0, 0)
    title.BackgroundTransparency = 1
    title.Text = "👻 GHOST RUNNERS"
    title.TextColor3 = Color3.new(0.8, 0.8, 1)
    title.TextScaled = true
    title.Font = Enum.Font.SourceSansBold
    title.Parent = infoPanel
    
    -- Ghost list container
    local listContainer = Instance.new("ScrollingFrame")
    listContainer.Name = "GhostList"
    listContainer.Size = UDim2.new(1, -10, 1, -40)
    listContainer.Position = UDim2.new(0, 5, 0, 35)
    listContainer.BackgroundTransparency = 1
    listContainer.ScrollBarThickness = 4
    listContainer.Parent = infoPanel
    
    -- Race comparison panel
    self:CreateRaceComparisonPanel()
    
    return ghostGui
end

function GhostController:CreateRaceComparisonPanel()
    -- Panel to show real-time comparison with ghost
    local comparisonPanel = Instance.new("Frame")
    comparisonPanel.Name = "RaceComparison"
    comparisonPanel.Size = UDim2.new(0, 250, 0, 100)
    comparisonPanel.Position = UDim2.new(0, 20, 1, -120)
    comparisonPanel.BackgroundColor3 = Color3.new(0.1, 0.1, 0.1)
    comparisonPanel.BackgroundTransparency = 0.3
    comparisonPanel.Visible = false
    comparisonPanel.Parent = ghostGui
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 8)
    corner.Parent = comparisonPanel
    
    -- Comparison text
    local comparisonText = Instance.new("TextLabel")
    comparisonText.Name = "ComparisonText"
    comparisonText.Size = UDim2.new(1, -10, 1, -10)
    comparisonText.Position = UDim2.new(0, 5, 0, 5)
    comparisonText.BackgroundTransparency = 1
    comparisonText.Text = "Racing against ghost..."
    comparisonText.TextColor3 = Color3.new(1, 1, 1)
    comparisonText.TextSize = 16
    comparisonText.Font = Enum.Font.SourceSans
    comparisonText.TextWrapped = true
    comparisonText.Parent = comparisonPanel
end

function GhostController:ShowGhostLeaderboard(ghosts)
    if not ghostGui then
        self:CreateGhostUI()
    end
    
    local infoPanel = ghostGui:FindFirstChild("GhostInfoPanel")
    local listContainer = infoPanel:FindFirstChild("GhostList")
    
    -- Clear existing entries
    for _, child in pairs(listContainer:GetChildren()) do
        if child:IsA("Frame") then
            child:Destroy()
        end
    end
    
    -- Add ghost entries
    for i, ghost in ipairs(ghosts) do
        local ghostEntry = self:CreateGhostEntry(ghost, i)
        ghostEntry.Parent = listContainer
    end
    
    -- Update scroll size
    listContainer.CanvasSize = UDim2.new(0, 0, 0, #ghosts * 60 + 10)
    
    -- Show panel
    infoPanel.Visible = true
    isGhostUIOpen = true
    
    print("👻 Showing ghost leaderboard with " .. #ghosts .. " entries")
end

function GhostController:CreateGhostEntry(ghost, rank)
    local entry = Instance.new("Frame")
    entry.Name = "GhostEntry_" .. rank
    entry.Size = UDim2.new(1, -10, 0, 50)
    entry.Position = UDim2.new(0, 5, 0, (rank - 1) * 60 + 5)
    entry.BackgroundColor3 = Color3.new(0.2, 0.2, 0.2)
    entry.BackgroundTransparency = 0.3
    
    local entryCorner = Instance.new("UICorner")
    entryCorner.CornerRadius = UDim.new(0, 5)
    entryCorner.Parent = entry
    
    -- Rank
    local rankLabel = Instance.new("TextLabel")
    rankLabel.Size = UDim2.new(0, 30, 1, 0)
    rankLabel.Position = UDim2.new(0, 5, 0, 0)
    rankLabel.BackgroundTransparency = 1
    rankLabel.Text = "#" .. rank
    rankLabel.TextColor3 = Color3.new(1, 0.8, 0.2)
    rankLabel.TextScaled = true
    rankLabel.Font = Enum.Font.SourceSansBold
    rankLabel.Parent = entry
    
    -- Player name
    local nameLabel = Instance.new("TextLabel")
    nameLabel.Size = UDim2.new(0, 120, 1, 0)
    nameLabel.Position = UDim2.new(0, 40, 0, 0)
    nameLabel.BackgroundTransparency = 1
    nameLabel.Text = ghost.playerName
    nameLabel.TextColor3 = Color3.new(1, 1, 1)
    nameLabel.TextSize = 14
    nameLabel.Font = Enum.Font.SourceSans
    nameLabel.TextXAlignment = Enum.TextXAlignment.Left
    nameLabel.Parent = entry
    
    -- Score
    local scoreLabel = Instance.new("TextLabel")
    scoreLabel.Size = UDim2.new(0, 60, 1, 0)
    scoreLabel.Position = UDim2.new(0, 170, 0, 0)
    scoreLabel.BackgroundTransparency = 1
    scoreLabel.Text = "🏆 " .. ghost.score
    scoreLabel.TextColor3 = Color3.new(0.2, 1, 0.2)
    scoreLabel.TextSize = 12
    scoreLabel.Font = Enum.Font.SourceSans
    scoreLabel.Parent = entry
    
    -- Race button
    local raceButton = Instance.new("TextButton")
    raceButton.Size = UDim2.new(0, 50, 0, 30)
    raceButton.Position = UDim2.new(1, -55, 0, 10)
    raceButton.BackgroundColor3 = Color3.new(0.2, 0.6, 1)
    raceButton.Text = "Race!"
    raceButton.TextColor3 = Color3.new(1, 1, 1)
    raceButton.TextSize = 12
    raceButton.Font = Enum.Font.SourceSansBold
    raceButton.Parent = entry
    
    local buttonCorner = Instance.new("UICorner")
    buttonCorner.CornerRadius = UDim.new(0, 3)
    buttonCorner.Parent = raceButton
    
    -- Race button functionality
    raceButton.MouseButton1Click:Connect(function()
        self:RequestRaceAgainstGhost(ghost.ghostId)
        self:HideGhostUI()
    end)
    
    return entry
end

function GhostController:RequestRaceAgainstGhost(ghostId)
    RemoteEvents.RaceAgainstGhost:FireServer(ghostId)
    print("🏁 Requesting race against ghost: " .. ghostId)
end

function GhostController:ShowRaceComparison(ghostName, playerScore, ghostScore, playerTime, ghostTime)
    if not ghostGui then
        self:CreateGhostUI()
    end
    
    local comparisonPanel = ghostGui:FindFirstChild("RaceComparison")
    local comparisonText = comparisonPanel:FindFirstChild("ComparisonText")
    
    local scoreDiff = playerScore - ghostScore
    local timeDiff = playerTime - ghostTime
    
    local status = ""
    if scoreDiff > 0 then
        status = "🏆 Leading by " .. scoreDiff .. " points!"
    elseif scoreDiff < 0 then
        status = "📉 Behind by " .. math.abs(scoreDiff) .. " points"
    else
        status = "🤝 Tied score!"
    end
    
    local timeStatus = ""
    if timeDiff < 0 then
        timeStatus = "⚡ " .. string.format("%.1f", math.abs(timeDiff)) .. "s faster"
    else
        timeStatus = "🐌 " .. string.format("%.1f", timeDiff) .. "s slower"
    end
    
    comparisonText.Text = "👻 Racing " .. ghostName .. "\n" .. status .. "\n" .. timeStatus
    comparisonPanel.Visible = true
end

function GhostController:HideRaceComparison()
    if ghostGui then
        local comparisonPanel = ghostGui:FindFirstChild("RaceComparison")
        if comparisonPanel then
            comparisonPanel.Visible = false
        end
    end
end

function GhostController:ShowGhostUI()
    RemoteEvents.RequestGhostLeaderboard:FireServer("main", 10)
end

function GhostController:HideGhostUI()
    if ghostGui then
        local infoPanel = ghostGui:FindFirstChild("GhostInfoPanel")
        if infoPanel then
            infoPanel.Visible = false
            isGhostUIOpen = false
        end
    end
end

function GhostController:ShowGhostSavedNotification(ghostData)
    -- Create notification when a new ghost is saved
    local notification = Instance.new("Frame")
    notification.Size = UDim2.new(0, 300, 0, 80)
    notification.Position = UDim2.new(0.5, -150, 0, -100)
    notification.BackgroundColor3 = Color3.new(0.1, 0.3, 0.1)
    notification.Parent = player.PlayerGui
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 10)
    corner.Parent = notification
    
    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(1, 0, 0.5, 0)
    title.Position = UDim2.new(0, 0, 0, 0)
    title.BackgroundTransparency = 1
    title.Text = "👻 GHOST SAVED!"
    title.TextColor3 = Color3.new(1, 1, 1)
    title.TextScaled = true
    title.Font = Enum.Font.SourceSansBold
    title.Parent = notification
    
    local subtitle = Instance.new("TextLabel")
    subtitle.Size = UDim2.new(1, 0, 0.5, 0)
    subtitle.Position = UDim2.new(0, 0, 0.5, 0)
    subtitle.BackgroundTransparency = 1
    subtitle.Text = "Score: " .. ghostData.score .. " | Others can race you!"
    subtitle.TextColor3 = Color3.new(0.8, 0.8, 0.8)
    subtitle.TextSize = 14
    subtitle.Font = Enum.Font.SourceSans
    subtitle.Parent = notification
    
    -- Animate in
    notification:TweenPosition(
        UDim2.new(0.5, -150, 0, 50),
        Enum.EasingDirection.Out,
        Enum.EasingStyle.Back,
        0.5,
        true
    )
    
    -- Auto-remove after delay
    spawn(function()
        wait(3)
        notification:TweenPosition(
            UDim2.new(0.5, -150, 0, -100),
            Enum.EasingDirection.In,
            Enum.EasingStyle.Back,
            0.3,
            true,
            function()
                notification:Destroy()
            end
        )
    end)
end

function GhostController:UpdateGhostStats(stats)
    -- Could be used to show personal ghost statistics
    print("👻 Ghost Stats - Total: " .. stats.totalGhosts .. ", Best: " .. stats.bestScore)
end

function GhostController:Init()
    print("👻 GhostController initializing...")
    
    -- Listen for ghost-related events
    RemoteEvents.ShowGhostLeaderboard.OnClientEvent:Connect(function(ghosts)
        self:ShowGhostLeaderboard(ghosts)
    end)
    
    RemoteEvents.UpdateRaceComparison.OnClientEvent:Connect(function(ghostName, playerScore, ghostScore, playerTime, ghostTime)
        self:ShowRaceComparison(ghostName, playerScore, ghostScore, playerTime, ghostTime)
    end)
    
    RemoteEvents.GhostSaved.OnClientEvent:Connect(function(ghostData)
        self:ShowGhostSavedNotification(ghostData)
    end)
    
    RemoteEvents.GhostStatsUpdated.OnClientEvent:Connect(function(stats)
        self:UpdateGhostStats(stats)
    end)
    
    RemoteEvents.HideRaceComparison.OnClientEvent:Connect(function()
        self:HideRaceComparison()
    end)
    
    -- Key binding for ghost UI (G key)
    UserInputService.InputBegan:Connect(function(input, gameProcessed)
        if gameProcessed then return end
        
        if input.KeyCode == Enum.KeyCode.G then
            if isGhostUIOpen then
                self:HideGhostUI()
            else
                self:ShowGhostUI()
            end
        end
    end)
    
    print("✅ GhostController initialized (Press G to view ghosts)")
end

return GhostController
