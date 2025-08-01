-- RebirthController.luau
-- Handles rebirth UI and client-side functionality

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local StarterGui = game:GetService("StarterGui")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local RebirthController = {}

-- UI References
local rebirthGui = nil
local rebirthFrame = nil
local rebirthButton = nil
local rebirthInfo = nil
local confirmDialog = nil

-- Remote events
local rebirthRemote = ReplicatedStorage:WaitForChild("RebirthRemote")
local checkRebirthRemote = ReplicatedStorage:WaitForChild("CheckRebirthRemote")

-- Current rebirth info
local currentRebirthInfo = nil

function RebirthController:CreateRebirthGUI()
    -- Create main ScreenGui
    rebirthGui = Instance.new("ScreenGui")
    rebirthGui.Name = "RebirthGui"
    rebirthGui.ResetOnSpawn = false
    rebirthGui.Parent = playerGui
    
    -- Main rebirth frame (larger for more info)
    rebirthFrame = Instance.new("Frame")
    rebirthFrame.Name = "RebirthFrame"
    rebirthFrame.Size = UDim2.new(0, 320, 0, 450)
    rebirthFrame.Position = UDim2.new(1, -340, 0, 20)
    rebirthFrame.BackgroundColor3 = Color3.fromRGB(15, 15, 25)
    rebirthFrame.BorderSizePixel = 0
    rebirthFrame.Parent = rebirthGui
    
    -- Add corner rounding
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 12)
    corner.Parent = rebirthFrame
    
    -- Add gradient background
    local gradient = Instance.new("UIGradient")
    gradient.Color = ColorSequence.new{
        ColorSequenceKeypoint.new(0, Color3.fromRGB(25, 25, 35)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(15, 15, 25))
    }
    gradient.Rotation = 45
    gradient.Parent = rebirthFrame
    
    -- Add animated stroke
    local stroke = Instance.new("UIStroke")
    stroke.Color = Color3.fromRGB(100, 200, 255)
    stroke.Thickness = 3
    stroke.Transparency = 0.3
    stroke.Parent = rebirthFrame
    
    -- Animate stroke glow
    local strokeTween = TweenService:Create(
        stroke,
        TweenInfo.new(2, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true),
        {Transparency = 0.8}
    )
    strokeTween:Play()
    
    -- Enhanced title with rebirth level
    local title = Instance.new("TextLabel")
    title.Name = "Title"
    title.Size = UDim2.new(1, -20, 0, 50)
    title.Position = UDim2.new(0, 10, 0, 5)
    title.BackgroundTransparency = 1
    title.Text = "⭐ ENHANCED REBIRTH ⭐"
    title.TextColor3 = Color3.fromRGB(255, 215, 100)
    title.TextScaled = true
    title.Font = Enum.Font.SourceSansBold
    title.TextStrokeTransparency = 0
    title.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
    title.Parent = rebirthFrame
    
    -- Current rebirth level display
    local currentLevel = Instance.new("TextLabel")
    currentLevel.Name = "CurrentLevel"
    currentLevel.Size = UDim2.new(1, -20, 0, 30)
    currentLevel.Position = UDim2.new(0, 10, 0, 55)
    currentLevel.BackgroundTransparency = 1
    currentLevel.Text = "Current Rebirth: Level 0"
    currentLevel.TextColor3 = Color3.fromRGB(200, 200, 255)
    currentLevel.TextScaled = true
    currentLevel.Font = Enum.Font.SourceSans
    currentLevel.Parent = rebirthFrame
    
    -- Enhanced rebirth info display
    rebirthInfo = Instance.new("ScrollingFrame")
    rebirthInfo.Name = "RebirthInfo"
    rebirthInfo.Size = UDim2.new(1, -20, 0, 300)
    rebirthInfo.Position = UDim2.new(0, 10, 0, 90)
    rebirthInfo.BackgroundColor3 = Color3.fromRGB(20, 20, 30)
    rebirthInfo.BackgroundTransparency = 0.5
    rebirthInfo.BorderSizePixel = 0
    rebirthInfo.ScrollBarThickness = 8
    rebirthInfo.ScrollBarImageColor3 = Color3.fromRGB(100, 200, 255)
    rebirthInfo.Parent = rebirthFrame
    
    local infoCorner = Instance.new("UICorner")
    infoCorner.CornerRadius = UDim.new(0, 8)
    infoCorner.Parent = rebirthInfo
    
    -- Layout for info with better spacing
    local infoLayout = Instance.new("UIListLayout")
    infoLayout.SortOrder = Enum.SortOrder.LayoutOrder
    infoLayout.Padding = UDim.new(0, 8)
    infoLayout.Parent = rebirthInfo
    
    -- Add padding to scroll frame
    local infoPadding = Instance.new("UIPadding")
    infoPadding.PaddingAll = UDim.new(0, 10)
    infoPadding.Parent = rebirthInfo
    
    -- Enhanced rebirth button
    rebirthButton = Instance.new("TextButton")
    rebirthButton.Name = "RebirthButton"
    rebirthButton.Size = UDim2.new(1, -20, 0, 45)
    rebirthButton.Position = UDim2.new(0, 10, 1, -55)
    rebirthButton.BackgroundColor3 = Color3.fromRGB(150, 100, 255)
    rebirthButton.Text = "🌟 REBIRTH NOW! 🌟"
    rebirthButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    rebirthButton.TextScaled = true
    rebirthButton.Font = Enum.Font.SourceSansBold
    rebirthButton.TextStrokeTransparency = 0
    rebirthButton.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
    rebirthButton.Parent = rebirthFrame
    
    local buttonCorner = Instance.new("UICorner")
    buttonCorner.CornerRadius = UDim.new(0, 8)
    buttonCorner.Parent = rebirthButton
    
    -- Add button glow effect
    local buttonGlow = Instance.new("UIStroke")
    buttonGlow.Color = Color3.fromRGB(255, 255, 255)
    buttonGlow.Thickness = 2
    buttonGlow.Transparency = 0.7
    buttonGlow.Parent = rebirthButton
    
    -- Animate button glow
    local buttonTween = TweenService:Create(
        buttonGlow,
        TweenInfo.new(1.5, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true),
        {Transparency = 0.3}
    )
    buttonTween:Play()
    
    -- Button click handler
    rebirthButton.MouseButton1Click:Connect(function()
        self:ShowEnhancedConfirmDialog()
    end)
    
    -- Create enhanced confirmation dialog
    self:CreateEnhancedConfirmDialog()
    
    -- Update info initially
    self:UpdateRebirthInfo()
end

function RebirthController:CreateConfirmDialog()
    confirmDialog = Instance.new("Frame")
    confirmDialog.Name = "ConfirmDialog"
    confirmDialog.Size = UDim2.new(0, 400, 0, 250)
    confirmDialog.Position = UDim2.new(0.5, -200, 0.5, -125)
    confirmDialog.BackgroundColor3 = Color3.fromRGB(30, 30, 35)
    confirmDialog.BorderSizePixel = 0
    confirmDialog.Visible = false
    confirmDialog.Parent = rebirthGui
    
    local dialogCorner = Instance.new("UICorner")
    dialogCorner.CornerRadius = UDim.new(0, 10)
    dialogCorner.Parent = confirmDialog
    
    local dialogStroke = Instance.new("UIStroke")
    dialogStroke.Color = Color3.fromRGB(255, 200, 100)
    dialogStroke.Thickness = 3
    dialogStroke.Parent = confirmDialog
    
    -- Warning title
    local warningTitle = Instance.new("TextLabel")
    warningTitle.Size = UDim2.new(1, 0, 0, 40)
    warningTitle.Position = UDim2.new(0, 0, 0, 10)
    warningTitle.BackgroundTransparency = 1
    warningTitle.Text = "⚠️ REBIRTH CONFIRMATION ⚠️"
    warningTitle.TextColor3 = Color3.fromRGB(255, 200, 100)
    warningTitle.TextScaled = true
    warningTitle.Font = Enum.Font.SourceSansBold
    warningTitle.Parent = confirmDialog
    
    -- Warning text
    local warningText = Instance.new("TextLabel")
    warningText.Size = UDim2.new(1, -20, 0, 120)
    warningText.Position = UDim2.new(0, 10, 0, 60)
    warningText.BackgroundTransparency = 1
    warningText.Text = "Rebirthing will RESET your level, coins, and high score!\n\nYou will keep:\n• Cosmetics & Pets\n• Achievements & Goals\n• Gamepasses\n\nYou will gain permanent upgrades!"
    warningText.TextColor3 = Color3.fromRGB(255, 255, 255)
    warningText.TextWrapped = true
    warningText.TextScaled = true
    warningText.Font = Enum.Font.SourceSans
    warningText.Parent = confirmDialog
    
    -- Confirm button
    local confirmButton = Instance.new("TextButton")
    confirmButton.Size = UDim2.new(0, 120, 0, 35)
    confirmButton.Position = UDim2.new(0, 20, 1, -50)
    confirmButton.BackgroundColor3 = Color3.fromRGB(200, 100, 100)
    confirmButton.Text = "CONFIRM REBIRTH"
    confirmButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    confirmButton.TextScaled = true
    confirmButton.Font = Enum.Font.SourceSansBold
    confirmButton.Parent = confirmDialog
    
    local confirmCorner = Instance.new("UICorner")
    confirmCorner.CornerRadius = UDim.new(0, 5)
    confirmCorner.Parent = confirmButton
    
    -- Cancel button
    local cancelButton = Instance.new("TextButton")
    cancelButton.Size = UDim2.new(0, 120, 0, 35)
    cancelButton.Position = UDim2.new(1, -140, 1, -50)
    cancelButton.BackgroundColor3 = Color3.fromRGB(100, 100, 100)
    cancelButton.Text = "CANCEL"
    cancelButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    cancelButton.TextScaled = true
    cancelButton.Font = Enum.Font.SourceSansBold
    cancelButton.Parent = confirmDialog
    
    local cancelCorner = Instance.new("UICorner")
    cancelCorner.CornerRadius = UDim.new(0, 5)
    cancelCorner.Parent = cancelButton
    
    -- Button handlers
    confirmButton.MouseButton1Click:Connect(function()
        self:PerformRebirth()
        confirmDialog.Visible = false
    end)
    
    cancelButton.MouseButton1Click:Connect(function()
        confirmDialog.Visible = false
    end)
end

function RebirthController:ShowConfirmDialog()
    if not currentRebirthInfo or not currentRebirthInfo.canRebirth then
        self:ShowNotification("Cannot rebirth yet! Reach level " .. (currentRebirthInfo.nextRequirement or "?"), Color3.fromRGB(255, 100, 100))
        return
    end
    
    confirmDialog.Visible = true
    
    -- Animate dialog appearance
    confirmDialog.Size = UDim2.new(0, 0, 0, 0)
    confirmDialog.Position = UDim2.new(0.5, 0, 0.5, 0)
    
    local tween = TweenService:Create(confirmDialog, TweenInfo.new(0.3, Enum.EasingStyle.Back), {
        Size = UDim2.new(0, 400, 0, 250),
        Position = UDim2.new(0.5, -200, 0.5, -125)
    })
    tween:Play()
end

function RebirthController:UpdateRebirthInfo()
    currentRebirthInfo = checkRebirthRemote:InvokeServer()
    
    if not currentRebirthInfo then return end
    
    -- Clear existing info
    for _, child in pairs(rebirthInfo:GetChildren()) do
        if child:IsA("TextLabel") then
            child:Destroy()
        end
    end
    
    local yOffset = 10
    
    -- Current rebirth status
    local currentLabel = Instance.new("TextLabel")
    currentLabel.Size = UDim2.new(1, -10, 0, 30)
    currentLabel.Position = UDim2.new(0, 5, 0, yOffset)
    currentLabel.BackgroundTransparency = 1
    currentLabel.Text = "Current Rebirths: " .. currentRebirthInfo.currentRebirths
    currentLabel.TextColor3 = Color3.fromRGB(100, 255, 100)
    currentLabel.TextScaled = true
    currentLabel.Font = Enum.Font.SourceSansBold
    currentLabel.TextXAlignment = Enum.TextXAlignment.Left
    currentLabel.Parent = rebirthInfo
    yOffset = yOffset + 35
    
    -- Current bonuses
    if currentRebirthInfo.currentBonuses and next(currentRebirthInfo.currentBonuses) then
        local bonusLabel = Instance.new("TextLabel")
        bonusLabel.Size = UDim2.new(1, -10, 0, 25)
        bonusLabel.Position = UDim2.new(0, 5, 0, yOffset)
        bonusLabel.BackgroundTransparency = 1
        bonusLabel.Text = "Current Bonuses:"
        bonusLabel.TextColor3 = Color3.fromRGB(255, 255, 100)
        bonusLabel.TextScaled = true
        bonusLabel.Font = Enum.Font.SourceSansBold
        bonusLabel.TextXAlignment = Enum.TextXAlignment.Left
        bonusLabel.Parent = rebirthInfo
        yOffset = yOffset + 30
        
        local bonuses = currentRebirthInfo.currentBonuses
        if bonuses.coinMultiplier then
            local coinLabel = Instance.new("TextLabel")
            coinLabel.Size = UDim2.new(1, -10, 0, 20)
            coinLabel.Position = UDim2.new(0, 15, 0, yOffset)
            coinLabel.BackgroundTransparency = 1
            coinLabel.Text = "• Coin Gain: +" .. math.floor((bonuses.coinMultiplier - 1) * 100) .. "%"
            coinLabel.TextColor3 = Color3.fromRGB(255, 215, 0)
            coinLabel.TextScaled = true
            coinLabel.Font = Enum.Font.SourceSans
            coinLabel.TextXAlignment = Enum.TextXAlignment.Left
            coinLabel.Parent = rebirthInfo
            yOffset = yOffset + 25
        end
        
        if bonuses.crateOddsBonus then
            local crateLabel = Instance.new("TextLabel")
            crateLabel.Size = UDim2.new(1, -10, 0, 20)
            crateLabel.Position = UDim2.new(0, 15, 0, yOffset)
            crateLabel.BackgroundTransparency = 1
            crateLabel.Text = "• Crate Odds: +" .. math.floor(bonuses.crateOddsBonus * 100) .. "%"
            crateLabel.TextColor3 = Color3.fromRGB(255, 100, 255)
            crateLabel.TextScaled = true
            crateLabel.Font = Enum.Font.SourceSans
            crateLabel.TextXAlignment = Enum.TextXAlignment.Left
            crateLabel.Parent = rebirthInfo
            yOffset = yOffset + 25
        end
        
        if bonuses.auraEffect then
            local auraLabel = Instance.new("TextLabel")
            auraLabel.Size = UDim2.new(1, -10, 0, 20)
            auraLabel.Position = UDim2.new(0, 15, 0, yOffset)
            auraLabel.BackgroundTransparency = 1
            auraLabel.Text = "• Aura: " .. bonuses.auraEffect
            auraLabel.TextColor3 = Color3.fromRGB(100, 255, 255)
            auraLabel.TextScaled = true
            auraLabel.Font = Enum.Font.SourceSans
            auraLabel.TextXAlignment = Enum.TextXAlignment.Left
            auraLabel.Parent = rebirthInfo
            yOffset = yOffset + 25
        end
    end
    
    -- Next rebirth info
    if currentRebirthInfo.nextRewards then
        yOffset = yOffset + 10
        
        local nextLabel = Instance.new("TextLabel")
        nextLabel.Size = UDim2.new(1, -10, 0, 25)
        nextLabel.Position = UDim2.new(0, 5, 0, yOffset)
        nextLabel.BackgroundTransparency = 1
        nextLabel.Text = "Next Rebirth (Level " .. currentRebirthInfo.nextRequirement .. "):"
        nextLabel.TextColor3 = Color3.fromRGB(255, 150, 100)
        nextLabel.TextScaled = true
        nextLabel.Font = Enum.Font.SourceSansBold
        nextLabel.TextXAlignment = Enum.TextXAlignment.Left
        nextLabel.Parent = rebirthInfo
        yOffset = yOffset + 30
        
        local rewards = currentRebirthInfo.nextRewards
        
        local rewardsList = {
            "• Coin Gain: +" .. math.floor(rewards.coinBonus * 100) .. "%",
            "• Crate Odds: +" .. math.floor(rewards.crateOddsBonus * 100) .. "%",
            "• Unlock: " .. rewards.auraEffect .. " Aura"
        }
        
        for _, unlockText in pairs(rewards.unlocks or {}) do
            table.insert(rewardsList, "• Unlock: " .. unlockText)
        end
        
        for _, rewardText in pairs(rewardsList) do
            local rewardLabel = Instance.new("TextLabel")
            rewardLabel.Size = UDim2.new(1, -10, 0, 20)
            rewardLabel.Position = UDim2.new(0, 15, 0, yOffset)
            rewardLabel.BackgroundTransparency = 1
            rewardLabel.Text = rewardText
            rewardLabel.TextColor3 = Color3.fromRGB(200, 255, 200)
            rewardLabel.TextScaled = true
            rewardLabel.Font = Enum.Font.SourceSans
            rewardLabel.TextXAlignment = Enum.TextXAlignment.Left
            rewardLabel.Parent = rebirthInfo
            yOffset = yOffset + 25
        end
    end
    
    -- Update button state
    if currentRebirthInfo.canRebirth then
        rebirthButton.BackgroundColor3 = Color3.fromRGB(100, 200, 100)
        rebirthButton.Text = "REBIRTH AVAILABLE!"
    else
        rebirthButton.BackgroundColor3 = Color3.fromRGB(100, 100, 100)
        rebirthButton.Text = "Level " .. (currentRebirthInfo.nextRequirement or "MAX") .. " Required"
    end
    
    -- Update canvas size
    rebirthInfo.CanvasSize = UDim2.new(0, 0, 0, yOffset + 10)
end

function RebirthController:PerformRebirth()
    rebirthRemote:FireServer()
end

function RebirthController:ShowNotification(text, color)
    -- Create notification
    local notification = Instance.new("Frame")
    notification.Size = UDim2.new(0, 300, 0, 60)
    notification.Position = UDim2.new(0.5, -150, 0, -70)
    notification.BackgroundColor3 = color or Color3.fromRGB(100, 200, 100)
    notification.BorderSizePixel = 0
    notification.Parent = playerGui
    
    local notifCorner = Instance.new("UICorner")
    notifCorner.CornerRadius = UDim.new(0, 10)
    notifCorner.Parent = notification
    
    local notifText = Instance.new("TextLabel")
    notifText.Size = UDim2.new(1, -20, 1, -10)
    notifText.Position = UDim2.new(0, 10, 0, 5)
    notifText.BackgroundTransparency = 1
    notifText.Text = text
    notifText.TextColor3 = Color3.fromRGB(255, 255, 255)
    notifText.TextWrapped = true
    notifText.TextScaled = true
    notifText.Font = Enum.Font.SourceSansBold
    notifText.Parent = notification
    
    -- Animate in
    local tweenIn = TweenService:Create(notification, TweenInfo.new(0.5, Enum.EasingStyle.Back), {
        Position = UDim2.new(0.5, -150, 0, 20)
    })
    tweenIn:Play()
    
    -- Animate out after delay
    wait(3)
    local tweenOut = TweenService:Create(notification, TweenInfo.new(0.5, Enum.EasingStyle.Quad), {
        Position = UDim2.new(0.5, -150, 0, -70),
        BackgroundTransparency = 1
    })
    tweenOut:Play()
    
    tweenOut.Completed:Connect(function()
        notification:Destroy()
    end)
end

-- Handle rebirth responses
rebirthRemote.OnClientEvent:Connect(function(status, message, rebirthData)
    if status == "success" then
        RebirthController:ShowNotification("🎉 " .. message .. "\n" .. "Unlocked: " .. (rebirthData.auraUnlocked or "New Aura") .. "!", Color3.fromRGB(100, 255, 100))
        
        -- Request aura refresh
        local auraRemote = ReplicatedStorage:WaitForChild("AuraRemote")
        auraRemote:FireServer("refresh")
        
        -- Update info after rebirth
        wait(1)
        RebirthController:UpdateRebirthInfo()
    else
        RebirthController:ShowNotification("❌ " .. message, Color3.fromRGB(255, 100, 100))
    end
end)

function RebirthController:Init()
    -- Create GUI when player loads
    spawn(function()
        wait(2) -- Wait for other systems to load
        self:CreateRebirthGUI()
        
        -- Event-driven rebirth info updates
        local rebirthUpdateEvent = Instance.new("BindableEvent")
        
        local function scheduleRebirthUpdate()
            -- Adaptive interval: check more frequently if player is close to rebirth threshold
            local interval = currentRebirthInfo and currentRebirthInfo.canRebirth and 3 or 8
            wait(interval)
            rebirthUpdateEvent:Fire()
        end
        
        rebirthUpdateEvent.Event:Connect(function()
            self:UpdateRebirthInfo()
            spawn(scheduleRebirthUpdate)
        end)
        
        -- Start the update cycle
        spawn(scheduleRebirthUpdate)
    end)
end

return RebirthController
