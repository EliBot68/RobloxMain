-- GoalController.luau
-- Client-side controller for displaying player goals and rewards

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local SoundService = game:GetService("SoundService")

local RemoteEvents = ReplicatedStorage:WaitForChild("RemoteEvents")
local Player = Players.LocalPlayer
local PlayerGui = Player:WaitForChild("PlayerGui")

local GoalController = {}

-- UI Elements
local goalGui = nil
local goalFrame = nil
local goalList = nil
local goalNotifications = {}

-- Goal tracking
local currentGoals = {}
local isGoalUIVisible = false

function GoalController:Init()
    -- Wait for remote events
    self:WaitForRemoteEvents()
    
    -- Create goal UI
    self:CreateGoalUI()
    
    -- Set up event connections
    self:SetupEventConnections()
    
    -- Request initial goal data
    self:RequestGoalData()
    
    print("🎯 GoalController initialized")
end

function GoalController:WaitForRemoteEvents()
    RemoteEvents:WaitForChild("UpdateGoalProgress")
    RemoteEvents:WaitForChild("ClaimGoalReward")
    RemoteEvents:WaitForChild("GetPlayerGoals")
end

function GoalController:CreateGoalUI()
    -- Create main goal GUI
    goalGui = Instance.new("ScreenGui")
    goalGui.Name = "GoalGui"
    goalGui.ResetOnSpawn = false
    goalGui.Parent = PlayerGui
    
    -- Create goal button (to show/hide goals)
    local goalButton = Instance.new("TextButton")
    goalButton.Name = "GoalButton"
    goalButton.Size = UDim2.new(0, 100, 0, 40)
    goalButton.Position = UDim2.new(1, -120, 0, 100)
    goalButton.BackgroundColor3 = Color3.fromRGB(255, 215, 0) -- Gold
    goalButton.BorderSizePixel = 0
    goalButton.Text = "🎯 Goals"
    goalButton.TextColor3 = Color3.fromRGB(0, 0, 0)
    goalButton.TextScaled = true
    goalButton.Font = Enum.Font.GothamBold
    goalButton.Parent = goalGui
    
    -- Add corner rounding
    local buttonCorner = Instance.new("UICorner")
    buttonCorner.CornerRadius = UDim.new(0, 8)
    buttonCorner.Parent = goalButton
    
    -- Create main goal frame (initially hidden)
    goalFrame = Instance.new("Frame")
    goalFrame.Name = "GoalFrame"
    goalFrame.Size = UDim2.new(0, 400, 0, 600)
    goalFrame.Position = UDim2.new(0.5, -200, 0.5, -300)
    goalFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
    goalFrame.BorderSizePixel = 0
    goalFrame.Visible = false
    goalFrame.Parent = goalGui
    
    -- Add frame corner rounding
    local frameCorner = Instance.new("UICorner")
    frameCorner.CornerRadius = UDim.new(0, 12)
    frameCorner.Parent = goalFrame
    
    -- Create goal frame header
    local header = Instance.new("Frame")
    header.Name = "Header"
    header.Size = UDim2.new(1, 0, 0, 60)
    header.Position = UDim2.new(0, 0, 0, 0)
    header.BackgroundColor3 = Color3.fromRGB(255, 215, 0)
    header.BorderSizePixel = 0
    header.Parent = goalFrame
    
    local headerCorner = Instance.new("UICorner")
    headerCorner.CornerRadius = UDim.new(0, 12)
    headerCorner.Parent = header
    
    -- Header title
    local headerTitle = Instance.new("TextLabel")
    headerTitle.Name = "Title"
    headerTitle.Size = UDim2.new(1, -100, 1, 0)
    headerTitle.Position = UDim2.new(0, 20, 0, 0)
    headerTitle.BackgroundTransparency = 1
    headerTitle.Text = "🎯 Player Goals"
    headerTitle.TextColor3 = Color3.fromRGB(0, 0, 0)
    headerTitle.TextScaled = true
    headerTitle.Font = Enum.Font.GothamBold
    headerTitle.TextXAlignment = Enum.TextXAlignment.Left
    headerTitle.Parent = header
    
    -- Close button
    local closeButton = Instance.new("TextButton")
    closeButton.Name = "CloseButton"
    closeButton.Size = UDim2.new(0, 40, 0, 40)
    closeButton.Position = UDim2.new(1, -50, 0, 10)
    closeButton.BackgroundColor3 = Color3.fromRGB(220, 50, 50)
    closeButton.BorderSizePixel = 0
    closeButton.Text = "✕"
    closeButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    closeButton.TextScaled = true
    closeButton.Font = Enum.Font.GothamBold
    closeButton.Parent = header
    
    local closeCorner = Instance.new("UICorner")
    closeCorner.CornerRadius = UDim.new(0, 6)
    closeCorner.Parent = closeButton
    
    -- Create scrolling goal list
    local scrollFrame = Instance.new("ScrollingFrame")
    scrollFrame.Name = "GoalScrollFrame"
    scrollFrame.Size = UDim2.new(1, -20, 1, -80)
    scrollFrame.Position = UDim2.new(0, 10, 0, 70)
    scrollFrame.BackgroundTransparency = 1
    scrollFrame.BorderSizePixel = 0
    scrollFrame.ScrollBarThickness = 8
    scrollFrame.ScrollBarImageColor3 = Color3.fromRGB(255, 215, 0)
    scrollFrame.Parent = goalFrame
    
    goalList = scrollFrame
    
    -- Add UIListLayout for automatic arrangement
    local listLayout = Instance.new("UIListLayout")
    listLayout.SortOrder = Enum.SortOrder.LayoutOrder
    listLayout.Padding = UDim.new(0, 10)
    listLayout.Parent = goalList
    
    -- Set up button connections
    goalButton.MouseButton1Click:Connect(function()
        self:ToggleGoalUI()
    end)
    
    closeButton.MouseButton1Click:Connect(function()
        self:HideGoalUI()
    end)
end

function GoalController:SetupEventConnections()
    -- Handle goal updates from server
    RemoteEvents.UpdateGoalProgress.OnClientEvent:Connect(function(data, notificationType, notificationData)
        if notificationType == "notification" then
            self:ShowNotification(notificationData)
        else
            self:UpdateGoalDisplay(data)
        end
    end)
end

function GoalController:RequestGoalData()
    -- Request current goal data from server
    local success, goalData = pcall(function()
        return RemoteEvents.GetPlayerGoals:InvokeServer()
    end)
    
    if success and goalData then
        self:UpdateGoalDisplay(goalData)
    end
end

function GoalController:UpdateGoalDisplay(goalData)
    currentGoals = goalData
    
    -- Clear existing goal displays
    for _, child in pairs(goalList:GetChildren()) do
        if child:IsA("Frame") then
            child:Destroy()
        end
    end
    
    -- Create goal entries
    for i, goal in pairs(goalData) do
        self:CreateGoalEntry(goal, i)
    end
    
    -- Update scroll frame size
    local contentHeight = #goalData * 120 + (#goalData - 1) * 10 -- 120 per goal + 10 padding
    goalList.CanvasSize = UDim2.new(0, 0, 0, contentHeight)
end

function GoalController:CreateGoalEntry(goal, index)
    -- Create goal entry frame
    local goalEntry = Instance.new("Frame")
    goalEntry.Name = "Goal_" .. goal.id
    goalEntry.Size = UDim2.new(1, -10, 0, 110)
    goalEntry.BackgroundColor3 = goal.completed and Color3.fromRGB(50, 100, 50) or Color3.fromRGB(50, 50, 50)
    goalEntry.BorderSizePixel = 0
    goalEntry.LayoutOrder = index
    goalEntry.Parent = goalList
    
    local entryCorner = Instance.new("UICorner")
    entryCorner.CornerRadius = UDim.new(0, 8)
    entryCorner.Parent = goalEntry
    
    -- Goal icon
    local iconLabel = Instance.new("TextLabel")
    iconLabel.Name = "Icon"
    iconLabel.Size = UDim2.new(0, 60, 0, 60)
    iconLabel.Position = UDim2.new(0, 10, 0, 10)
    iconLabel.BackgroundTransparency = 1
    iconLabel.Text = goal.icon
    iconLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    iconLabel.TextScaled = true
    iconLabel.Font = Enum.Font.Gotham
    iconLabel.Parent = goalEntry
    
    -- Goal title
    local titleLabel = Instance.new("TextLabel")
    titleLabel.Name = "Title"
    titleLabel.Size = UDim2.new(1, -180, 0, 25)
    titleLabel.Position = UDim2.new(0, 80, 0, 10)
    titleLabel.BackgroundTransparency = 1
    titleLabel.Text = goal.title
    titleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    titleLabel.TextScaled = true
    titleLabel.Font = Enum.Font.GothamBold
    titleLabel.TextXAlignment = Enum.TextXAlignment.Left
    titleLabel.Parent = goalEntry
    
    -- Goal description
    local descLabel = Instance.new("TextLabel")
    descLabel.Name = "Description"
    descLabel.Size = UDim2.new(1, -180, 0, 20)
    descLabel.Position = UDim2.new(0, 80, 0, 35)
    descLabel.BackgroundTransparency = 1
    descLabel.Text = goal.description
    descLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
    descLabel.TextScaled = true
    descLabel.Font = Enum.Font.Gotham
    descLabel.TextXAlignment = Enum.TextXAlignment.Left
    descLabel.Parent = goalEntry
    
    -- Progress display
    local progressText = string.format("%d / %d", goal.progress, goal.target)
    local progressLabel = Instance.new("TextLabel")
    progressLabel.Name = "Progress"
    progressLabel.Size = UDim2.new(1, -180, 0, 20)
    progressLabel.Position = UDim2.new(0, 80, 0, 55)
    progressLabel.BackgroundTransparency = 1
    progressLabel.Text = progressText
    progressLabel.TextColor3 = goal.completed and Color3.fromRGB(100, 255, 100) or Color3.fromRGB(255, 215, 0)
    progressLabel.TextScaled = true
    progressLabel.Font = Enum.Font.Gotham
    progressLabel.TextXAlignment = Enum.TextXAlignment.Left
    progressLabel.Parent = goalEntry
    
    -- Progress bar
    local progressBarBG = Instance.new("Frame")
    progressBarBG.Name = "ProgressBarBG"
    progressBarBG.Size = UDim2.new(1, -180, 0, 8)
    progressBarBG.Position = UDim2.new(0, 80, 0, 80)
    progressBarBG.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
    progressBarBG.BorderSizePixel = 0
    progressBarBG.Parent = goalEntry
    
    local progressBarCorner = Instance.new("UICorner")
    progressBarCorner.CornerRadius = UDim.new(0, 4)
    progressBarCorner.Parent = progressBarBG
    
    local progressBar = Instance.new("Frame")
    progressBar.Name = "ProgressBar"
    progressBar.Size = UDim2.new(goal.progressPercent / 100, 0, 1, 0)
    progressBar.Position = UDim2.new(0, 0, 0, 0)
    progressBar.BackgroundColor3 = goal.completed and Color3.fromRGB(100, 255, 100) or Color3.fromRGB(255, 215, 0)
    progressBar.BorderSizePixel = 0
    progressBar.Parent = progressBarBG
    
    local progressFillCorner = Instance.new("UICorner")
    progressFillCorner.CornerRadius = UDim.new(0, 4)
    progressFillCorner.Parent = progressBar
    
    -- Claim button (if completed and not claimed)
    if goal.completed and not goal.claimed then
        local claimButton = Instance.new("TextButton")
        claimButton.Name = "ClaimButton"
        claimButton.Size = UDim2.new(0, 80, 0, 30)
        claimButton.Position = UDim2.new(1, -90, 0, 10)
        claimButton.BackgroundColor3 = Color3.fromRGB(100, 255, 100)
        claimButton.BorderSizePixel = 0
        claimButton.Text = "🎁 Claim"
        claimButton.TextColor3 = Color3.fromRGB(0, 0, 0)
        claimButton.TextScaled = true
        claimButton.Font = Enum.Font.GothamBold
        claimButton.Parent = goalEntry
        
        local claimCorner = Instance.new("UICorner")
        claimCorner.CornerRadius = UDim.new(0, 6)
        claimCorner.Parent = claimButton
        
        -- Claim button functionality
        claimButton.MouseButton1Click:Connect(function()
            self:ClaimGoalReward(goal.id)
            claimButton.Enabled = false
            claimButton.Text = "Claimed!"
            claimButton.BackgroundColor3 = Color3.fromRGB(150, 150, 150)
        end)
    elseif goal.claimed then
        -- Show claimed status
        local claimedLabel = Instance.new("TextLabel")
        claimedLabel.Name = "ClaimedLabel"
        claimedLabel.Size = UDim2.new(0, 80, 0, 30)
        claimedLabel.Position = UDim2.new(1, -90, 0, 10)
        claimedLabel.BackgroundColor3 = Color3.fromRGB(150, 150, 150)
        claimedLabel.BorderSizePixel = 0
        claimedLabel.Text = "✅ Claimed"
        claimedLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
        claimedLabel.TextScaled = true
        claimedLabel.Font = Enum.Font.Gotham
        claimedLabel.Parent = goalEntry
        
        local claimedCorner = Instance.new("UICorner")
        claimedCorner.CornerRadius = UDim.new(0, 6)
        claimedCorner.Parent = claimedLabel
    end
    
    -- Animate progress bar
    if goal.progressPercent > 0 then
        progressBar.Size = UDim2.new(0, 0, 1, 0)
        
        local progressTween = TweenService:Create(
            progressBar,
            TweenInfo.new(1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
            {Size = UDim2.new(goal.progressPercent / 100, 0, 1, 0)}
        )
        progressTween:Play()
    end
end

function GoalController:ToggleGoalUI()
    if isGoalUIVisible then
        self:HideGoalUI()
    else
        self:ShowGoalUI()
    end
end

function GoalController:ShowGoalUI()
    isGoalUIVisible = true
    goalFrame.Visible = true
    
    -- Animate entrance
    goalFrame.Size = UDim2.new(0, 0, 0, 0)
    goalFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
    
    local showTween = TweenService:Create(
        goalFrame,
        TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
        {
            Size = UDim2.new(0, 400, 0, 600),
            Position = UDim2.new(0.5, -200, 0.5, -300)
        }
    )
    showTween:Play()
    
    -- Request fresh goal data
    self:RequestGoalData()
end

function GoalController:HideGoalUI()
    isGoalUIVisible = false
    
    -- Animate exit
    local hideTween = TweenService:Create(
        goalFrame,
        TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
        {
            Size = UDim2.new(0, 0, 0, 0),
            Position = UDim2.new(0.5, 0, 0.5, 0)
        }
    )
    hideTween:Play()
    
    hideTween.Completed:Connect(function()
        goalFrame.Visible = false
    end)
end

function GoalController:ClaimGoalReward(goalId)
    -- Send claim request to server
    RemoteEvents.ClaimGoalReward:FireServer(goalId)
end

function GoalController:ShowNotification(notificationData)
    -- Create notification popup
    local notification = Instance.new("Frame")
    notification.Name = "Notification"
    notification.Size = UDim2.new(0, 350, 0, 100)
    notification.Position = UDim2.new(1, 0, 0, 150 + (#goalNotifications * 110))
    notification.BackgroundColor3 = notificationData.type == "goal_completed" and Color3.fromRGB(100, 255, 100) or Color3.fromRGB(255, 215, 0)
    notification.BorderSizePixel = 0
    notification.Parent = goalGui
    
    local notifCorner = Instance.new("UICorner")
    notifCorner.CornerRadius = UDim.new(0, 8)
    notifCorner.Parent = notification
    
    -- Notification icon
    local notifIcon = Instance.new("TextLabel")
    notifIcon.Name = "Icon"
    notifIcon.Size = UDim2.new(0, 60, 0, 60)
    notifIcon.Position = UDim2.new(0, 10, 0, 20)
    notifIcon.BackgroundTransparency = 1
    notifIcon.Text = notificationData.icon or "🎯"
    notifIcon.TextColor3 = Color3.fromRGB(0, 0, 0)
    notifIcon.TextScaled = true
    notifIcon.Font = Enum.Font.Gotham
    notifIcon.Parent = notification
    
    -- Notification text
    local notifText = Instance.new("TextLabel")
    notifText.Name = "Text"
    notifText.Size = UDim2.new(1, -80, 1, 0)
    notifText.Position = UDim2.new(0, 70, 0, 0)
    notifText.BackgroundTransparency = 1
    notifText.Text = notificationData.title .. "\n" .. notificationData.message
    notifText.TextColor3 = Color3.fromRGB(0, 0, 0)
    notifText.TextScaled = true
    notifText.Font = Enum.Font.GothamBold
    notifText.TextXAlignment = Enum.TextXAlignment.Left
    notifText.Parent = notification
    
    -- Add to tracking
    table.insert(goalNotifications, notification)
    
    -- Animate in
    local slideInTween = TweenService:Create(
        notification,
        TweenInfo.new(0.5, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
        {Position = UDim2.new(1, -360, 0, 150 + ((#goalNotifications - 1) * 110))}
    )
    slideInTween:Play()
    
    -- Auto-remove after duration
    wait(notificationData.duration or 4)
    
    local slideOutTween = TweenService:Create(
        notification,
        TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
        {Position = UDim2.new(1, 0, 0, 150 + ((#goalNotifications - 1) * 110))}
    )
    slideOutTween:Play()
    
    slideOutTween.Completed:Connect(function()
        notification:Destroy()
        
        -- Remove from tracking
        for i, notif in pairs(goalNotifications) do
            if notif == notification then
                table.remove(goalNotifications, i)
                break
            end
        end
        
        -- Reposition remaining notifications
        for i, notif in pairs(goalNotifications) do
            local repositionTween = TweenService:Create(
                notif,
                TweenInfo.new(0.2, Enum.EasingStyle.Quad),
                {Position = UDim2.new(1, -360, 0, 150 + ((i - 1) * 110))}
            )
            repositionTween:Play()
        end
    end)
end

return GoalController
