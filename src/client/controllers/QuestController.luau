-- QuestController.luau
-- Client-side controller for quest board interactions and UI

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterGui = game:GetService("StarterGui")
local SoundService = game:GetService("SoundService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local RemoteEvents = require(ReplicatedStorage.Shared.modules.RemoteEvents)

local QuestController = {}

-- UI Elements
local questBoardGui = nil
local questFrame = nil
local currentQuests = {}
local currentProgress = {}

function QuestController:CreateQuestBoardUI()
    -- Create main GUI
    questBoardGui = Instance.new("ScreenGui")
    questBoardGui.Name = "QuestBoardGui"
    questBoardGui.ResetOnSpawn = false
    questBoardGui.Parent = playerGui
    
    -- Main quest frame
    questFrame = Instance.new("Frame")
    questFrame.Size = UDim2.new(0, 600, 0, 500)
    questFrame.Position = UDim2.new(0.5, -300, 0.5, -250)
    questFrame.BackgroundColor3 = Color3.new(0.15, 0.1, 0.05)
    questFrame.BorderSizePixel = 0
    questFrame.Visible = false
    questFrame.Parent = questBoardGui
    
    -- Add wooden texture effect
    local woodCorner = Instance.new("UICorner")
    woodCorner.CornerRadius = UDim.new(0, 12)
    woodCorner.Parent = questFrame
    
    local woodGradient = Instance.new("UIGradient")
    woodGradient.Color = ColorSequence.new{
        ColorSequenceKeypoint.new(0, Color3.new(0.5, 0.3, 0.15)),
        ColorSequenceKeypoint.new(0.5, Color3.new(0.4, 0.25, 0.1)),
        ColorSequenceKeypoint.new(1, Color3.new(0.3, 0.2, 0.08))
    }
    woodGradient.Rotation = 45
    woodGradient.Parent = questFrame
    
    -- Title header
    local titleFrame = Instance.new("Frame")
    titleFrame.Size = UDim2.new(1, -20, 0, 60)
    titleFrame.Position = UDim2.new(0, 10, 0, 10)
    titleFrame.BackgroundColor3 = Color3.new(0.25, 0.15, 0.08)
    titleFrame.BorderSizePixel = 0
    titleFrame.Parent = questFrame
    
    local titleCorner = Instance.new("UICorner")
    titleCorner.CornerRadius = UDim.new(0, 8)
    titleCorner.Parent = titleFrame
    
    local titleLabel = Instance.new("TextLabel")
    titleLabel.Size = UDim2.new(1, 0, 1, 0)
    titleLabel.BackgroundTransparency = 1
    titleLabel.Text = "📋 DAILY QUEST BOARD"
    titleLabel.TextColor3 = Color3.new(1, 0.9, 0.6)
    titleLabel.TextScaled = true
    titleLabel.Font = Enum.Font.SourceSansBold
    titleLabel.TextStrokeTransparency = 0
    titleLabel.TextStrokeColor3 = Color3.new(0, 0, 0)
    titleLabel.Parent = titleFrame
    
    -- Subtitle
    local subtitleLabel = Instance.new("TextLabel")
    subtitleLabel.Size = UDim2.new(1, -20, 0, 25)
    subtitleLabel.Position = UDim2.new(0, 10, 0, 75)
    subtitleLabel.BackgroundTransparency = 1
    subtitleLabel.Text = "Complete quests to earn coins and special rewards!"
    subtitleLabel.TextColor3 = Color3.new(0.8, 0.7, 0.5)
    subtitleLabel.TextScaled = true
    subtitleLabel.Font = Enum.Font.SourceSans
    subtitleLabel.TextStrokeTransparency = 0
    subtitleLabel.TextStrokeColor3 = Color3.new(0, 0, 0)
    subtitleLabel.Parent = questFrame
    
    -- Scroll frame for quests
    local scrollFrame = Instance.new("ScrollingFrame")
    scrollFrame.Size = UDim2.new(1, -20, 1, -150)
    scrollFrame.Position = UDim2.new(0, 10, 0, 110)
    scrollFrame.BackgroundTransparency = 1
    scrollFrame.BorderSizePixel = 0
    scrollFrame.ScrollBarThickness = 8
    scrollFrame.ScrollBarImageColor3 = Color3.new(0.4, 0.25, 0.1)
    scrollFrame.Parent = questFrame
    
    -- Quest container
    local questContainer = Instance.new("UIListLayout")
    questContainer.SortOrder = Enum.SortOrder.LayoutOrder
    questContainer.Padding = UDim.new(0, 10)
    questContainer.Parent = scrollFrame
    
    -- Close button
    local closeButton = Instance.new("TextButton")
    closeButton.Size = UDim2.new(0, 100, 0, 35)
    closeButton.Position = UDim2.new(0.5, -50, 1, -45)
    closeButton.BackgroundColor3 = Color3.new(0.6, 0.3, 0.15)
    closeButton.Text = "Close"
    closeButton.TextColor3 = Color3.new(1, 1, 1)
    closeButton.TextScaled = true
    closeButton.Font = Enum.Font.SourceSansBold
    closeButton.Parent = questFrame
    
    local buttonCorner = Instance.new("UICorner")
    buttonCorner.CornerRadius = UDim.new(0, 8)
    buttonCorner.Parent = closeButton
    
    closeButton.MouseButton1Click:Connect(function()
        self:HideQuestBoard()
    end)
    
    -- Store reference to scroll frame
    questFrame.ScrollFrame = scrollFrame
end

function QuestController:CreateQuestItem(quest, progress, questIndex)
    local questItem = Instance.new("Frame")
    questItem.Size = UDim2.new(1, -20, 0, 120)
    questItem.BackgroundColor3 = Color3.new(0.95, 0.9, 0.8)
    questItem.BorderSizePixel = 0
    
    -- Paper-like appearance
    local paperCorner = Instance.new("UICorner")
    paperCorner.CornerRadius = UDim.new(0, 5)
    paperCorner.Parent = questItem
    
    -- Shadow effect
    local shadow = Instance.new("Frame")
    shadow.Size = UDim2.new(1, 4, 1, 4)
    shadow.Position = UDim2.new(0, 2, 0, 2)
    shadow.BackgroundColor3 = Color3.new(0, 0, 0)
    shadow.BackgroundTransparency = 0.8
    shadow.BorderSizePixel = 0
    shadow.ZIndex = questItem.ZIndex - 1
    shadow.Parent = questItem
    
    local shadowCorner = Instance.new("UICorner")
    shadowCorner.CornerRadius = UDim.new(0, 5)
    shadowCorner.Parent = shadow
    
    -- Difficulty indicator
    local difficultyColors = {
        easy = Color3.new(0.2, 0.8, 0.2),
        medium = Color3.new(1, 0.8, 0.2),
        hard = Color3.new(1, 0.4, 0.2),
        expert = Color3.new(0.8, 0.2, 1)
    }
    
    local difficultyBar = Instance.new("Frame")
    difficultyBar.Size = UDim2.new(0, 5, 1, 0)
    difficultyBar.Position = UDim2.new(0, 0, 0, 0)
    difficultyBar.BackgroundColor3 = difficultyColors[quest.difficulty] or difficultyColors.easy
    difficultyBar.BorderSizePixel = 0
    difficultyBar.Parent = questItem
    
    -- Quest name
    local questName = Instance.new("TextLabel")
    questName.Size = UDim2.new(1, -60, 0, 25)
    questName.Position = UDim2.new(0, 15, 0, 5)
    questName.BackgroundTransparency = 1
    questName.Text = quest.name
    questName.TextColor3 = Color3.new(0.2, 0.1, 0.05)
    questName.TextScaled = true
    questName.Font = Enum.Font.SourceSansBold
    questName.TextXAlignment = Enum.TextXAlignment.Left
    questName.Parent = questItem
    
    -- Quest description
    local questDesc = Instance.new("TextLabel")
    questDesc.Size = UDim2.new(1, -60, 0, 35)
    questDesc.Position = UDim2.new(0, 15, 0, 30)
    questDesc.BackgroundTransparency = 1
    questDesc.Text = quest.description
    questDesc.TextColor3 = Color3.new(0.3, 0.2, 0.1)
    questDesc.TextScaled = true
    questDesc.Font = Enum.Font.SourceSans
    questDesc.TextWrapped = true
    questDesc.TextXAlignment = Enum.TextXAlignment.Left
    questDesc.Parent = questItem
    
    -- Progress bar background
    local progressBg = Instance.new("Frame")
    progressBg.Size = UDim2.new(1, -120, 0, 15)
    progressBg.Position = UDim2.new(0, 15, 0, 70)
    progressBg.BackgroundColor3 = Color3.new(0.7, 0.6, 0.5)
    progressBg.BorderSizePixel = 0
    progressBg.Parent = questItem
    
    local progressBgCorner = Instance.new("UICorner")
    progressBgCorner.CornerRadius = UDim.new(0, 3)
    progressBgCorner.Parent = progressBg
    
    -- Progress bar fill
    local progressFill = Instance.new("Frame")
    local progressPercent = math.min(progress.progress / quest.targetAmount, 1)
    progressFill.Size = UDim2.new(progressPercent, 0, 1, 0)
    progressFill.Position = UDim2.new(0, 0, 0, 0)
    progressFill.BackgroundColor3 = progress.completed and Color3.new(0.2, 0.8, 0.2) or Color3.new(0.2, 0.6, 1)
    progressFill.BorderSizePixel = 0
    progressFill.Parent = progressBg
    
    local progressFillCorner = Instance.new("UICorner")
    progressFillCorner.CornerRadius = UDim.new(0, 3)
    progressFillCorner.Parent = progressFill
    
    -- Progress text
    local progressText = Instance.new("TextLabel")
    progressText.Size = UDim2.new(0, 100, 0, 15)
    progressText.Position = UDim2.new(1, -105, 0, 70)
    progressText.BackgroundTransparency = 1
    progressText.Text = progress.progress .. " / " .. quest.targetAmount
    progressText.TextColor3 = Color3.new(0.2, 0.1, 0.05)
    progressText.TextScaled = true
    progressText.Font = Enum.Font.SourceSans
    progressText.TextXAlignment = Enum.TextXAlignment.Right
    progressText.Parent = questItem
    
    -- Reward info
    local rewardText = Instance.new("TextLabel")
    rewardText.Size = UDim2.new(1, -120, 0, 20)
    rewardText.Position = UDim2.new(0, 15, 0, 90)
    rewardText.BackgroundTransparency = 1
    rewardText.Text = self:GetRewardText(quest.reward)
    rewardText.TextColor3 = Color3.new(0.6, 0.4, 0.1)
    rewardText.TextScaled = true
    rewardText.Font = Enum.Font.SourceSansItalic
    rewardText.TextXAlignment = Enum.TextXAlignment.Left
    rewardText.Parent = questItem
    
    -- Claim/Status button
    local statusButton = Instance.new("TextButton")
    statusButton.Size = UDim2.new(0, 80, 0, 25)
    statusButton.Position = UDim2.new(1, -90, 0, 90)
    statusButton.BorderSizePixel = 0
    statusButton.TextScaled = true
    statusButton.Font = Enum.Font.SourceSansBold
    
    local statusCorner = Instance.new("UICorner")
    statusCorner.CornerRadius = UDim.new(0, 5)
    statusCorner.Parent = statusButton
    
    if progress.claimed then
        statusButton.Text = "✓ Claimed"
        statusButton.BackgroundColor3 = Color3.new(0.5, 0.5, 0.5)
        statusButton.TextColor3 = Color3.new(0.8, 0.8, 0.8)
        statusButton.Active = false
    elseif progress.completed then
        statusButton.Text = "🎁 Claim"
        statusButton.BackgroundColor3 = Color3.new(0.2, 0.8, 0.2)
        statusButton.TextColor3 = Color3.new(1, 1, 1)
        statusButton.MouseButton1Click:Connect(function()
            RemoteEvents.ClaimQuestReward:FireServer(questIndex)
            statusButton.Text = "✓ Claimed"
            statusButton.BackgroundColor3 = Color3.new(0.5, 0.5, 0.5)
            statusButton.TextColor3 = Color3.new(0.8, 0.8, 0.8)
            statusButton.Active = false
        end)
    else
        statusButton.Text = "In Progress"
        statusButton.BackgroundColor3 = Color3.new(0.8, 0.6, 0.2)
        statusButton.TextColor3 = Color3.new(1, 1, 1)
        statusButton.Active = false
    end
    
    statusButton.Parent = questItem
    
    return questItem
end

function QuestController:GetRewardText(reward)
    if reward.type == "coins" then
        return "💰 Reward: " .. reward.amount .. " coins"
    elseif reward.type == "multiplier" then
        return "⚡ Reward: " .. reward.amount .. "x multiplier for " .. math.floor(reward.duration/60) .. " minutes"
    elseif reward.type == "special" then
        return "✨ Reward: " .. reward.effect:gsub("_", " "):gsub("(%l)(%w*)", function(a,b) return string.upper(a)..b end) .. " effect"
    elseif reward.type == "mega" then
        return "💎 Reward: " .. reward.amount .. " coins + special effects!"
    end
    return "🎁 Special reward"
end

function QuestController:ShowQuestBoard(quests, progress)
    currentQuests = quests or {}
    currentProgress = progress or {}
    
    if not questFrame then return end
    
    -- Clear existing quest items
    local scrollFrame = questFrame.ScrollFrame
    for _, child in pairs(scrollFrame:GetChildren()) do
        if child:IsA("Frame") then
            child:Destroy()
        end
    end
    
    -- Create quest items
    for i, quest in pairs(currentQuests) do
        local questProgress = currentProgress[i] or {completed = false, progress = 0, claimed = false}
        local questItem = self:CreateQuestItem(quest, questProgress, i)
        questItem.Parent = scrollFrame
    end
    
    -- Update scroll frame size
    local listLayout = scrollFrame:FindFirstChild("UIListLayout")
    if listLayout then
        scrollFrame.CanvasSize = UDim2.new(0, 0, 0, listLayout.AbsoluteContentSize.Y + 20)
    end
    
    -- Show with animation
    questFrame.Visible = true
    questFrame.Size = UDim2.new(0, 0, 0, 0)
    questFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
    
    local showTween = TweenService:Create(
        questFrame,
        TweenInfo.new(0.5, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
        {
            Size = UDim2.new(0, 600, 0, 500),
            Position = UDim2.new(0.5, -300, 0.5, -250)
        }
    )
    showTween:Play()
    
    -- Play open sound
    self:PlaySound("rbxasset://sounds/pop_mid_up.wav")
end

function QuestController:HideQuestBoard()
    if not questFrame or not questFrame.Visible then return end
    
    local hideTween = TweenService:Create(
        questFrame,
        TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.In),
        {
            Size = UDim2.new(0, 0, 0, 0),
            Position = UDim2.new(0.5, 0, 0.5, 0)
        }
    )
    
    hideTween:Play()
    hideTween.Completed:Connect(function()
        questFrame.Visible = false
    end)
    
    -- Play close sound
    self:PlaySound("rbxasset://sounds/pop_mid_down.wav")
end

function QuestController:ShowQuestCompleted(questIndex, quest)
    print("🎉 Quest completed: " .. quest.name)
    
    StarterGui:SetCore("SendNotification", {
        Title = "🎉 Quest Completed!";
        Text = quest.name .. " - " .. self:GetRewardText(quest.reward);
        Duration = 5;
    })
    
    -- Play celebration sound
    self:PlaySound("rbxasset://sounds/victory_fanfare_harp.mp3")
end

function QuestController:ShowQuestProgress(questIndex, quest, currentProgress)
    -- Optional: Show subtle progress notifications
    -- Could be implemented as a small popup or progress bar update
end

function QuestController:PlaySound(soundId)
    local sound = Instance.new("Sound")
    sound.SoundId = soundId
    sound.Volume = 0.5
    sound.Parent = workspace
    sound:Play()
    
    sound.Ended:Connect(function()
        sound:Destroy()
    end)
end

function QuestController:Initialize()
    print("📋 QuestController initializing...")
    
    -- Create UI
    self:CreateQuestBoardUI()
    
    -- Connect remote events
    RemoteEvents.ShowQuestBoard.OnClientEvent:Connect(function(quests, progress)
        self:ShowQuestBoard(quests, progress)
    end)
    
    RemoteEvents.QuestCompleted.OnClientEvent:Connect(function(questIndex, quest)
        self:ShowQuestCompleted(questIndex, quest)
    end)
    
    RemoteEvents.QuestProgressUpdated.OnClientEvent:Connect(function(questIndex, quest, currentProgress)
        self:ShowQuestProgress(questIndex, quest, currentProgress)
    end)
    
    print("✅ QuestController initialized!")
end

-- Auto-initialize
QuestController:Initialize()

return QuestController
