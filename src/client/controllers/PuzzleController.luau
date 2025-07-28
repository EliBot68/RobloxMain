-- PuzzleController.luau
-- Client-side controller for weekly puzzle piece collection system

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local SoundService = game:GetService("SoundService")
local StarterGui = game:GetService("StarterGui")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local RemoteEvents = require(ReplicatedStorage.Shared.modules.RemoteEvents)
local GameConstants = require(ReplicatedStorage.Shared.constants.GameConstants)

local player = Players.LocalPlayer
local PuzzleController = {}

-- UI elements
local puzzleUI = nil
local progressFrame = nil
local hintsFrame = nil
local collectionNotification = nil

-- Sound effects
local puzzleSounds = {}

function PuzzleController:LoadSounds()
    -- Collection sound
    local collectSound = Instance.new("Sound")
    collectSound.SoundId = "rbxasset://sounds/electronicpingshort.wav"
    collectSound.Volume = 0.7
    collectSound.Pitch = 1.2
    collectSound.Parent = SoundService
    puzzleSounds.collect = collectSound
    
    -- Completion sound
    local completeSound = Instance.new("Sound")
    completeSound.SoundId = "rbxasset://sounds/bell.wav"
    completeSound.Volume = 0.8
    completeSound.Pitch = 0.8
    completeSound.Parent = SoundService
    puzzleSounds.complete = completeSound
    
    print("🧩 Puzzle sounds loaded")
end

function PuzzleController:CreatePuzzleUI()
    local playerGui = player:WaitForChild("PlayerGui")
    
    -- Main puzzle UI
    local puzzleScreenGui = Instance.new("ScreenGui")
    puzzleScreenGui.Name = "PuzzleUI"
    puzzleScreenGui.ResetOnSpawn = false
    puzzleScreenGui.Parent = playerGui
    
    -- Progress indicator (always visible)
    progressFrame = Instance.new("Frame")
    progressFrame.Name = "PuzzleProgress"
    progressFrame.Size = UDim2.new(0, 250, 0, 60)
    progressFrame.Position = UDim2.new(0, 20, 0, 150)
    progressFrame.BackgroundColor3 = Color3.new(0.1, 0.1, 0.2)
    progressFrame.BorderSizePixel = 0
    progressFrame.Visible = false
    progressFrame.Parent = puzzleScreenGui
    
    local progressCorner = Instance.new("UICorner")
    progressCorner.CornerRadius = UDim.new(0, 8)
    progressCorner.Parent = progressFrame
    
    -- Progress title
    local progressTitle = Instance.new("TextLabel")
    progressTitle.Name = "Title"
    progressTitle.Size = UDim2.new(1, -10, 0, 25)
    progressTitle.Position = UDim2.new(0, 5, 0, 5)
    progressTitle.BackgroundTransparency = 1
    progressTitle.Text = "🧩 WEEKLY PUZZLE"
    progressTitle.TextColor3 = Color3.new(1, 1, 0)
    progressTitle.TextScaled = true
    progressTitle.Font = Enum.Font.SourceSansBold
    progressTitle.TextXAlignment = Enum.TextXAlignment.Left
    progressTitle.Parent = progressFrame
    
    -- Progress bar background
    local progressBarBG = Instance.new("Frame")
    progressBarBG.Name = "ProgressBarBG"
    progressBarBG.Size = UDim2.new(1, -10, 0, 20)
    progressBarBG.Position = UDim2.new(0, 5, 0, 30)
    progressBarBG.BackgroundColor3 = Color3.new(0.2, 0.2, 0.3)
    progressBarBG.BorderSizePixel = 0
    progressBarBG.Parent = progressFrame
    
    local progressBarCorner = Instance.new("UICorner")
    progressBarCorner.CornerRadius = UDim.new(0, 4)
    progressBarCorner.Parent = progressBarBG
    
    -- Progress bar fill
    local progressBarFill = Instance.new("Frame")
    progressBarFill.Name = "ProgressBarFill"
    progressBarFill.Size = UDim2.new(0, 0, 1, 0)
    progressBarFill.Position = UDim2.new(0, 0, 0, 0)
    progressBarFill.BackgroundColor3 = Color3.new(0.2, 1, 0.2)
    progressBarFill.BorderSizePixel = 0
    progressBarFill.Parent = progressBarBG
    
    local fillCorner = Instance.new("UICorner")
    fillCorner.CornerRadius = UDim.new(0, 4)
    fillCorner.Parent = progressBarFill
    
    -- Progress text
    local progressText = Instance.new("TextLabel")
    progressText.Name = "ProgressText"
    progressText.Size = UDim2.new(1, 0, 1, 0)
    progressText.Position = UDim2.new(0, 0, 0, 0)
    progressText.BackgroundTransparency = 1
    progressText.Text = "0/5 pieces"
    progressText.TextColor3 = Color3.new(1, 1, 1)
    progressText.TextScaled = true
    progressText.Font = Enum.Font.SourceSans
    progressText.TextStrokeTransparency = 0
    progressText.TextStrokeColor3 = Color3.new(0, 0, 0)
    progressText.Parent = progressBarBG
    
    -- Hints button
    local hintsButton = Instance.new("TextButton")
    hintsButton.Name = "HintsButton"
    hintsButton.Size = UDim2.new(0, 80, 0, 25)
    hintsButton.Position = UDim2.new(1, -85, 0, 5)
    hintsButton.BackgroundColor3 = Color3.new(0.3, 0.3, 0.5)
    hintsButton.Text = "💡 Hints"
    hintsButton.TextColor3 = Color3.new(1, 1, 1)
    hintsButton.TextScaled = true
    hintsButton.Font = Enum.Font.SourceSans
    hintsButton.Parent = progressFrame
    
    local hintsButtonCorner = Instance.new("UICorner")
    hintsButtonCorner.CornerRadius = UDim.new(0, 4)
    hintsButtonCorner.Parent = hintsButton
    
    -- Hints frame (hidden by default)
    hintsFrame = Instance.new("Frame")
    hintsFrame.Name = "HintsFrame"
    hintsFrame.Size = UDim2.new(0, 400, 0, 300)
    hintsFrame.Position = UDim2.new(0.5, -200, 0.5, -150)
    hintsFrame.BackgroundColor3 = Color3.new(0.05, 0.05, 0.15)
    hintsFrame.BorderSizePixel = 0
    hintsFrame.Visible = false
    hintsFrame.Parent = puzzleScreenGui
    
    local hintsFrameCorner = Instance.new("UICorner")
    hintsFrameCorner.CornerRadius = UDim.new(0, 10)
    hintsFrameCorner.Parent = hintsFrame
    
    -- Hints title
    local hintsTitle = Instance.new("TextLabel")
    hintsTitle.Size = UDim2.new(1, -50, 0, 40)
    hintsTitle.Position = UDim2.new(0, 10, 0, 10)
    hintsTitle.BackgroundTransparency = 1
    hintsTitle.Text = "🧩 Puzzle Piece Hints"
    hintsTitle.TextColor3 = Color3.new(1, 1, 0)
    hintsTitle.TextScaled = true
    hintsTitle.Font = Enum.Font.SourceSansBold
    hintsTitle.TextXAlignment = Enum.TextXAlignment.Left
    hintsTitle.Parent = hintsFrame
    
    -- Close button
    local closeButton = Instance.new("TextButton")
    closeButton.Size = UDim2.new(0, 30, 0, 30)
    closeButton.Position = UDim2.new(1, -35, 0, 5)
    closeButton.BackgroundColor3 = Color3.new(0.8, 0.2, 0.2)
    closeButton.Text = "✕"
    closeButton.TextColor3 = Color3.new(1, 1, 1)
    closeButton.TextScaled = true
    closeButton.Font = Enum.Font.SourceSansBold
    closeButton.Parent = hintsFrame
    
    -- Hints scroll frame
    local hintsScroll = Instance.new("ScrollingFrame")
    hintsScroll.Size = UDim2.new(1, -20, 1, -60)
    hintsScroll.Position = UDim2.new(0, 10, 0, 50)
    hintsScroll.BackgroundTransparency = 1
    hintsScroll.ScrollBarThickness = 8
    hintsScroll.Parent = hintsFrame
    
    local hintsLayout = Instance.new("UIListLayout")
    hintsLayout.SortOrder = Enum.SortOrder.LayoutOrder
    hintsLayout.Padding = UDim.new(0, 5)
    hintsLayout.Parent = hintsScroll
    
    -- Store references
    puzzleUI = {
        screenGui = puzzleScreenGui,
        progress = progressFrame,
        hints = hintsFrame,
        hintsScroll = hintsScroll,
        hintsLayout = hintsLayout
    }
    
    -- Connect events
    hintsButton.MouseButton1Click:Connect(function()
        self:ShowHints()
    end)
    
    closeButton.MouseButton1Click:Connect(function()
        self:HideHints()
    end)
    
    print("🧩 Puzzle UI created")
end

function PuzzleController:UpdateProgressDisplay(collected, total)
    if not puzzleUI or not puzzleUI.progress then return end
    
    local progressFrame = puzzleUI.progress
    local progressBarFill = progressFrame:FindFirstChild("ProgressBarBG"):FindFirstChild("ProgressBarFill")
    local progressText = progressFrame:FindFirstChild("ProgressBarBG"):FindFirstChild("ProgressText")
    
    if progressBarFill and progressText then
        local percentage = collected / total
        progressText.Text = collected .. "/" .. total .. " pieces"
        
        -- Animate progress bar
        local fillTween = TweenService:Create(
            progressBarFill,
            TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
            {Size = UDim2.new(percentage, 0, 1, 0)}
        )
        fillTween:Play()
        
        -- Change color based on progress
        if percentage >= 1 then
            progressBarFill.BackgroundColor3 = Color3.new(1, 0.8, 0.2) -- Gold
        elseif percentage >= 0.6 then
            progressBarFill.BackgroundColor3 = Color3.new(0.2, 0.8, 1) -- Blue
        else
            progressBarFill.BackgroundColor3 = Color3.new(0.2, 1, 0.2) -- Green
        end
    end
    
    -- Show/hide progress frame
    if collected > 0 then
        progressFrame.Visible = true
    end
end

function PuzzleController:ShowHints()
    if not puzzleUI or not puzzleUI.hints then return end
    
    -- Request hints from server
    RemoteEvents.GetPuzzleHints:FireServer()
end

function PuzzleController:DisplayHints(hints)
    if not puzzleUI or not puzzleUI.hintsScroll then return end
    
    local hintsScroll = puzzleUI.hintsScroll
    
    -- Clear existing hints
    for _, child in pairs(hintsScroll:GetChildren()) do
        if not child:IsA("UIListLayout") then
            child:Destroy()
        end
    end
    
    -- Add hint entries
    for i, hint in ipairs(hints) do
        local hintFrame = Instance.new("Frame")
        hintFrame.Size = UDim2.new(1, -10, 0, 70)
        hintFrame.BackgroundColor3 = hint.collected and Color3.new(0.1, 0.3, 0.1) or Color3.new(0.2, 0.2, 0.3)
        hintFrame.BorderSizePixel = 0
        hintFrame.LayoutOrder = i
        hintFrame.Parent = hintsScroll
        
        local hintCorner = Instance.new("UICorner")
        hintCorner.CornerRadius = UDim.new(0, 5)
        hintCorner.Parent = hintFrame
        
        -- Piece name
        local nameLabel = Instance.new("TextLabel")
        nameLabel.Size = UDim2.new(1, -10, 0, 25)
        nameLabel.Position = UDim2.new(0, 5, 0, 5)
        nameLabel.BackgroundTransparency = 1
        nameLabel.Text = hint.name .. (hint.collected and " ✓" or "")
        nameLabel.TextColor3 = hint.collected and Color3.new(0.8, 1, 0.8) or Color3.new(1, 1, 1)
        nameLabel.TextScaled = true
        nameLabel.Font = Enum.Font.SourceSansBold
        nameLabel.TextXAlignment = Enum.TextXAlignment.Left
        nameLabel.Parent = hintFrame
        
        -- Hint text
        local hintLabel = Instance.new("TextLabel")
        hintLabel.Size = UDim2.new(1, -10, 0, 35)
        hintLabel.Position = UDim2.new(0, 5, 0, 30)
        hintLabel.BackgroundTransparency = 1
        hintLabel.Text = hint.collected and "Collected!" or hint.hint
        hintLabel.TextColor3 = hint.collected and Color3.new(0.6, 0.9, 0.6) or Color3.new(0.8, 0.8, 1)
        hintLabel.TextScaled = true
        hintLabel.Font = Enum.Font.SourceSans
        hintLabel.TextWrapped = true
        hintLabel.TextXAlignment = Enum.TextXAlignment.Left
        hintLabel.Parent = hintFrame
        
        -- Color indicator
        local colorIndicator = Instance.new("Frame")
        colorIndicator.Size = UDim2.new(0, 8, 1, -10)
        colorIndicator.Position = UDim2.new(1, -13, 0, 5)
        colorIndicator.BackgroundColor3 = hint.color
        colorIndicator.BorderSizePixel = 0
        colorIndicator.Parent = hintFrame
    end
    
    -- Update canvas size
    hintsScroll.CanvasSize = UDim2.new(0, 0, 0, puzzleUI.hintsLayout.AbsoluteContentSize.Y)
    
    -- Show hints frame
    puzzleUI.hints.Visible = true
    puzzleUI.hints.Size = UDim2.new(0, 0, 0, 0)
    
    local showTween = TweenService:Create(
        puzzleUI.hints,
        TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
        {Size = UDim2.new(0, 400, 0, 300)}
    )
    showTween:Play()
end

function PuzzleController:HideHints()
    if not puzzleUI or not puzzleUI.hints then return end
    
    local hideTween = TweenService:Create(
        puzzleUI.hints,
        TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
        {Size = UDim2.new(0, 0, 0, 0)}
    )
    hideTween:Play()
    hideTween.Completed:Connect(function()
        puzzleUI.hints.Visible = false
    end)
end

function PuzzleController:ShowCollectionNotification(data)
    local playerGui = player:WaitForChild("PlayerGui")
    
    -- Create notification
    local notificationFrame = Instance.new("Frame")
    notificationFrame.Size = UDim2.new(0, 350, 0, 80)
    notificationFrame.Position = UDim2.new(0.5, -175, 0, -100)
    notificationFrame.BackgroundColor3 = Color3.new(0.1, 0.3, 0.1)
    notificationFrame.BorderSizePixel = 0
    notificationFrame.Parent = playerGui
    
    local notificationCorner = Instance.new("UICorner")
    notificationCorner.CornerRadius = UDim.new(0, 10)
    notificationCorner.Parent = notificationFrame
    
    -- Title
    local titleLabel = Instance.new("TextLabel")
    titleLabel.Size = UDim2.new(1, -10, 0, 35)
    titleLabel.Position = UDim2.new(0, 5, 0, 5)
    titleLabel.BackgroundTransparency = 1
    titleLabel.Text = "🧩 PIECE COLLECTED!"
    titleLabel.TextColor3 = Color3.new(1, 1, 0)
    titleLabel.TextScaled = true
    titleLabel.Font = Enum.Font.SourceSansBold
    titleLabel.Parent = notificationFrame
    
    -- Details
    local detailsLabel = Instance.new("TextLabel")
    detailsLabel.Size = UDim2.new(1, -10, 0, 35)
    detailsLabel.Position = UDim2.new(0, 5, 0, 40)
    detailsLabel.BackgroundTransparency = 1
    detailsLabel.Text = data.pieceName .. " (" .. data.totalCollected .. "/" .. data.totalRequired .. ")"
    detailsLabel.TextColor3 = Color3.new(0.8, 1, 0.8)
    detailsLabel.TextScaled = true
    detailsLabel.Font = Enum.Font.SourceSans
    detailsLabel.Parent = notificationFrame
    
    -- Animate entrance
    local entranceTween = TweenService:Create(
        notificationFrame,
        TweenInfo.new(0.5, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
        {Position = UDim2.new(0.5, -175, 0, 50)}
    )
    entranceTween:Play()
    
    -- Auto-hide after 3 seconds
    spawn(function()
        wait(3)
        local exitTween = TweenService:Create(
            notificationFrame,
            TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
            {Position = UDim2.new(0.5, -175, 0, -100)}
        )
        exitTween:Play()
        exitTween.Completed:Connect(function()
            notificationFrame:Destroy()
        end)
    end)
    
    -- Update progress display
    self:UpdateProgressDisplay(data.totalCollected, data.totalRequired)
end

function PuzzleController:ShowCompletionCelebration(data)
    local playerGui = player:WaitForChild("PlayerGui")
    
    -- Create celebration frame
    local celebrationFrame = Instance.new("Frame")
    celebrationFrame.Size = UDim2.new(1, 0, 1, 0)
    celebrationFrame.Position = UDim2.new(0, 0, 0, 0)
    celebrationFrame.BackgroundColor3 = Color3.new(0, 0, 0)
    celebrationFrame.BackgroundTransparency = 0.5
    celebrationFrame.BorderSizePixel = 0
    celebrationFrame.Parent = playerGui
    
    -- Main content frame
    local contentFrame = Instance.new("Frame")
    contentFrame.Size = UDim2.new(0, 500, 0, 400)
    contentFrame.Position = UDim2.new(0.5, -250, 0.5, -200)
    contentFrame.BackgroundColor3 = Color3.new(0.1, 0.1, 0.3)
    contentFrame.BorderSizePixel = 0
    contentFrame.Parent = celebrationFrame
    
    local contentCorner = Instance.new("UICorner")
    contentCorner.CornerRadius = UDim.new(0, 15)
    contentCorner.Parent = contentFrame
    
    -- Title
    local titleLabel = Instance.new("TextLabel")
    titleLabel.Size = UDim2.new(1, -20, 0, 80)
    titleLabel.Position = UDim2.new(0, 10, 0, 10)
    titleLabel.BackgroundTransparency = 1
    titleLabel.Text = "🎉 PUZZLE COMPLETED! 🎉"
    titleLabel.TextColor3 = Color3.new(1, 1, 0)
    titleLabel.TextScaled = true
    titleLabel.Font = Enum.Font.SourceSansBold
    titleLabel.Parent = contentFrame
    
    -- Reward info
    local rewardLabel = Instance.new("TextLabel")
    rewardLabel.Size = UDim2.new(1, -20, 0, 60)
    rewardLabel.Position = UDim2.new(0, 10, 0, 90)
    rewardLabel.BackgroundTransparency = 1
    rewardLabel.Text = "You unlocked: " .. data.reward.name
    rewardLabel.TextColor3 = Color3.new(0.8, 1, 0.8)
    rewardLabel.TextScaled = true
    rewardLabel.Font = Enum.Font.SourceSans
    rewardLabel.Parent = contentFrame
    
    -- Rarity label
    local rarityLabel = Instance.new("TextLabel")
    rarityLabel.Size = UDim2.new(1, -20, 0, 40)
    rarityLabel.Position = UDim2.new(0, 10, 0, 150)
    rarityLabel.BackgroundTransparency = 1
    rarityLabel.Text = "Rarity: " .. data.reward.rarity
    rarityLabel.TextColor3 = data.reward.rarity == "Legendary" and Color3.new(1, 0.8, 0.2) or Color3.new(0.8, 0.2, 1)
    rarityLabel.TextScaled = true
    rarityLabel.Font = Enum.Font.SourceSans
    rarityLabel.Parent = contentFrame
    
    -- Bonus info
    local bonusLabel = Instance.new("TextLabel")
    bonusLabel.Size = UDim2.new(1, -20, 0, 40)
    bonusLabel.Position = UDim2.new(0, 10, 0, 190)
    bonusLabel.BackgroundTransparency = 1
    bonusLabel.Text = "Bonus: " .. data.bonusCoins .. " coins!"
    bonusLabel.TextColor3 = Color3.new(1, 1, 0.2)
    bonusLabel.TextScaled = true
    bonusLabel.Font = Enum.Font.SourceSans
    bonusLabel.Parent = contentFrame
    
    -- Statistics
    local statsLabel = Instance.new("TextLabel")
    statsLabel.Size = UDim2.new(1, -20, 0, 60)
    statsLabel.Position = UDim2.new(0, 10, 0, 240)
    statsLabel.BackgroundTransparency = 1
    statsLabel.Text = "Total puzzles completed: " .. data.totalCompleted .. "\nWeek " .. data.weekId .. " completed!"
    statsLabel.TextColor3 = Color3.new(0.7, 0.7, 1)
    statsLabel.TextScaled = true
    statsLabel.Font = Enum.Font.SourceSans
    statsLabel.TextWrapped = true
    statsLabel.Parent = contentFrame
    
    -- Close button
    local closeButton = Instance.new("TextButton")
    closeButton.Size = UDim2.new(0, 100, 0, 40)
    closeButton.Position = UDim2.new(0.5, -50, 1, -60)
    closeButton.BackgroundColor3 = Color3.new(0.2, 0.8, 0.2)
    closeButton.Text = "Awesome!"
    closeButton.TextColor3 = Color3.new(1, 1, 1)
    closeButton.TextScaled = true
    closeButton.Font = Enum.Font.SourceSansBold
    closeButton.Parent = contentFrame
    
    local closeCorner = Instance.new("UICorner")
    closeCorner.CornerRadius = UDim.new(0, 5)
    closeCorner.Parent = closeButton
    
    -- Animate entrance
    contentFrame.Size = UDim2.new(0, 0, 0, 0)
    local entranceTween = TweenService:Create(
        contentFrame,
        TweenInfo.new(0.5, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
        {Size = UDim2.new(0, 500, 0, 400)}
    )
    entranceTween:Play()
    
    -- Close event
    closeButton.MouseButton1Click:Connect(function()
        local exitTween = TweenService:Create(
            contentFrame,
            TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
            {Size = UDim2.new(0, 0, 0, 0)}
        )
        exitTween:Play()
        exitTween.Completed:Connect(function()
            celebrationFrame:Destroy()
        end)
    end)
end

function PuzzleController:ShowMessage(data)
    -- Simple message notification
    if data.type == "warning" then
        StarterGui:SetCore("ChatMakeSystemMessage", {
            Text = data.message,
            Color = Color3.new(1, 0.8, 0.2),
            FontSize = Enum.FontSize.Size18
        })
    end
end

function PuzzleController:HidePuzzlePiece(pieceId)
    -- Find and hide the puzzle piece for this player
    local piece = Workspace:FindFirstChild("PuzzlePiece_" .. pieceId)
    if piece then
        piece.Transparency = 1
        if piece:FindFirstChild("BillboardGui") then
            piece.BillboardGui.Enabled = false
        end
        if piece:FindFirstChild("PointLight") then
            piece.PointLight.Enabled = false
        end
    end
end

function PuzzleController:PlaySound(soundType)
    if puzzleSounds[soundType] then
        puzzleSounds[soundType]:Play()
    end
end

function PuzzleController:RequestInitialProgress()
    -- Request current progress from server
    RemoteEvents.GetPuzzleProgress:FireServer()
end

function PuzzleController:Init()
    print("🧩 PuzzleController initializing...")
    
    -- Load sounds
    self:LoadSounds()
    
    -- Create UI
    self:CreatePuzzleUI()
    
    -- Setup event handlers
    RemoteEvents.PuzzlePieceCollected.OnClientEvent:Connect(function(data)
        self:ShowCollectionNotification(data)
    end)
    
    RemoteEvents.PuzzleCompleted.OnClientEvent:Connect(function(data)
        self:ShowCompletionCelebration(data)
    end)
    
    RemoteEvents.GetPuzzleHints.OnClientEvent:Connect(function(hints)
        self:DisplayHints(hints)
    end)
    
    RemoteEvents.GetPuzzleProgress.OnClientEvent:Connect(function(progress)
        if progress and progress.collectedPieces then
            self:UpdateProgressDisplay(#progress.collectedPieces, 5)
        end
    end)
    
    RemoteEvents.ShowPuzzleMessage.OnClientEvent:Connect(function(data)
        self:ShowMessage(data)
    end)
    
    RemoteEvents.PlayPuzzleSound.OnClientEvent:Connect(function(soundType)
        self:PlaySound(soundType)
    end)
    
    RemoteEvents.HidePuzzlePiece.OnClientEvent:Connect(function(pieceId)
        self:HidePuzzlePiece(pieceId)
    end)
    
    RemoteEvents.PuzzleWeekReset.OnClientEvent:Connect(function(data)
        StarterGui:SetCore("ChatMakeSystemMessage", {
            Text = data.message,
            Color = Color3.new(0.2, 1, 0.8),
            FontSize = Enum.FontSize.Size18
        })
        
        -- Reset progress display
        self:UpdateProgressDisplay(0, 5)
    end)
    
    -- Request initial progress after a delay
    spawn(function()
        wait(3)
        self:RequestInitialProgress()
    end)
    
    print("✅ PuzzleController initialized successfully!")
end

return PuzzleController
