-- PartyControllerEnhanced.luau
-- Enhanced client-side party management with creative features

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local SoundService = game:GetService("SoundService")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

local RemoteEvents = require(ReplicatedStorage.Shared.modules.RemoteEvents)
local GameConstants = require(ReplicatedStorage.Shared.constants.GameConstants)

local PartyController = {}
local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- UI Variables
local partyUI = nil
local partyFrame = nil
local membersFrame = nil
local inviteFrame = nil
local voiceFrame = nil
local emoteFrame = nil
local achievementFrame = nil
local celebrationFrame = nil

-- Party state
local currentParty = nil
local voiceCommands = {}
local emotes = {}
local currentCelebrations = {}

-- Enhanced UI creation
function PartyController:CreatePartyUI()
    if partyUI then partyUI:Destroy() end
    
    -- Main UI
    partyUI = Instance.new("ScreenGui")
    partyUI.Name = "PartyUI"
    partyUI.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    partyUI.Parent = playerGui
    
    -- Modern glass-morphism main frame
    partyFrame = Instance.new("Frame")
    partyFrame.Name = "PartyFrame"
    partyFrame.Size = UDim2.new(0, 400, 0, 600)
    partyFrame.Position = UDim2.new(0, 20, 0.5, -300)
    partyFrame.BackgroundColor3 = Color3.new(0.1, 0.1, 0.15)
    partyFrame.BackgroundTransparency = 0.1
    partyFrame.BorderSizePixel = 0
    partyFrame.Parent = partyUI
    
    -- Glass effect
    local blur = Instance.new("ImageLabel")
    blur.Size = UDim2.new(1, 0, 1, 0)
    blur.BackgroundTransparency = 1
    blur.Image = "rbxasset://textures/ui/GuiImagePlaceholder.png"
    blur.ImageColor3 = Color3.new(1, 1, 1)
    blur.ImageTransparency = 0.85
    blur.Parent = partyFrame
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 15)
    corner.Parent = partyFrame
    
    local stroke = Instance.new("UIStroke")
    stroke.Color = Color3.new(0.8, 0.4, 1)
    stroke.Thickness = 2
    stroke.Transparency = 0.3
    stroke.Parent = partyFrame
    
    -- Animated title
    local titleLabel = Instance.new("TextLabel")
    titleLabel.Name = "TitleLabel"
    titleLabel.Size = UDim2.new(1, -40, 0, 60)
    titleLabel.Position = UDim2.new(0, 20, 0, 10)
    titleLabel.BackgroundTransparency = 1
    titleLabel.Text = "🎉 PARTY HUB"
    titleLabel.TextColor3 = Color3.new(1, 1, 1)
    titleLabel.TextScaled = true
    titleLabel.Font = Enum.Font.SourceSansBold
    titleLabel.TextStrokeTransparency = 0
    titleLabel.TextStrokeColor3 = Color3.new(0.5, 0.2, 0.8)
    titleLabel.Parent = partyFrame
    
    -- Animated gradient effect
    local gradient = Instance.new("UIGradient")
    gradient.Color = ColorSequence.new{
        ColorSequenceKeypoint.new(0, Color3.new(1, 0.5, 1)),
        ColorSequenceKeypoint.new(0.5, Color3.new(0.5, 0.8, 1)),
        ColorSequenceKeypoint.new(1, Color3.new(1, 1, 0.5))
    }
    gradient.Parent = titleLabel
    
    -- Animate the gradient
    spawn(function()
        while titleLabel.Parent do
            local tween = TweenService:Create(gradient, TweenInfo.new(3, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {Rotation = 360})
            tween:Play()
            tween.Completed:Wait()
            gradient.Rotation = 0
        end
    end)
    
    self:CreateMembersSection()
    self:CreateActionButtons()
    self:CreateVoicePanel()
    self:CreateEmotePanel()
    self:CreateStatsPanel()
    
    -- Entrance animation
    partyFrame.Position = UDim2.new(0, -400, 0.5, -300)
    local entranceTween = TweenService:Create(
        partyFrame,
        TweenInfo.new(0.5, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
        {Position = UDim2.new(0, 20, 0.5, -300)}
    )
    entranceTween:Play()
    
    print("🎨 Enhanced PartyUI created with modern design!")
end

function PartyController:CreateMembersSection()
    local membersScrollFrame = Instance.new("ScrollingFrame")
    membersScrollFrame.Name = "MembersScrollFrame"
    membersScrollFrame.Size = UDim2.new(1, -40, 0, 200)
    membersScrollFrame.Position = UDim2.new(0, 20, 0, 80)
    membersScrollFrame.BackgroundColor3 = Color3.new(0.05, 0.05, 0.1)
    membersScrollFrame.BackgroundTransparency = 0.3
    membersScrollFrame.BorderSizePixel = 0
    membersScrollFrame.ScrollBarThickness = 8
    membersScrollFrame.ScrollBarImageColor3 = Color3.new(0.8, 0.4, 1)
    membersScrollFrame.Parent = partyFrame
    
    local membersCorner = Instance.new("UICorner")
    membersCorner.CornerRadius = UDim.new(0, 10)
    membersCorner.Parent = membersScrollFrame
    
    local membersLayout = Instance.new("UIListLayout")
    membersLayout.SortOrder = Enum.SortOrder.LayoutOrder
    membersLayout.Padding = UDim.new(0, 5)
    membersLayout.Parent = membersScrollFrame
    
    membersFrame = membersScrollFrame
    
    -- Members header
    local membersHeader = Instance.new("TextLabel")
    membersHeader.Name = "MembersHeader"
    membersHeader.Size = UDim2.new(1, 0, 0, 30)
    membersHeader.BackgroundColor3 = Color3.new(0.2, 0.1, 0.3)
    membersHeader.BackgroundTransparency = 0.2
    membersHeader.Text = "👥 PARTY MEMBERS"
    membersHeader.TextColor3 = Color3.new(1, 1, 1)
    membersHeader.TextScaled = true
    membersHeader.Font = Enum.Font.SourceSansBold
    membersHeader.LayoutOrder = 1
    membersHeader.Parent = membersScrollFrame
    
    local headerCorner = Instance.new("UICorner")
    headerCorner.CornerRadius = UDim.new(0, 8)
    headerCorner.Parent = membersHeader
end

function PartyController:CreateActionButtons()
    local buttonsFrame = Instance.new("Frame")
    buttonsFrame.Name = "ButtonsFrame"
    buttonsFrame.Size = UDim2.new(1, -40, 0, 80)
    buttonsFrame.Position = UDim2.new(0, 20, 0, 290)
    buttonsFrame.BackgroundTransparency = 1
    buttonsFrame.Parent = partyFrame
    
    local buttonLayout = Instance.new("UIGridLayout")
    buttonLayout.CellSize = UDim2.new(0, 120, 0, 35)
    buttonLayout.CellPadding = UDim2.new(0, 10, 0, 5)
    buttonLayout.Parent = buttonsFrame
    
    -- Create Party button
    local createButton = self:CreateStyledButton("🎉 Create", Color3.new(0.2, 0.8, 0.2))
    createButton.Name = "CreateButton"
    createButton.Parent = buttonsFrame
    createButton.MouseButton1Click:Connect(function()
        self:CreatePartyClicked()
    end)
    
    -- Invite Friends button
    local inviteButton = self:CreateStyledButton("📨 Invite", Color3.new(0.2, 0.5, 0.8))
    inviteButton.Name = "InviteButton"
    inviteButton.Parent = buttonsFrame
    inviteButton.MouseButton1Click:Connect(function()
        self:ShowInviteMenu()
    end)
    
    -- Start Game button
    local startButton = self:CreateStyledButton("🚀 Start", Color3.new(0.8, 0.2, 0.8))
    startButton.Name = "StartButton"
    startButton.Parent = buttonsFrame
    startButton.MouseButton1Click:Connect(function()
        self:StartPartyGame()
    end)
    
    -- Leave Party button
    local leaveButton = self:CreateStyledButton("👋 Leave", Color3.new(0.8, 0.2, 0.2))
    leaveButton.Name = "LeaveButton"
    leaveButton.Parent = buttonsFrame
    leaveButton.MouseButton1Click:Connect(function()
        self:LeavePartyClicked()
    end)
end

function PartyController:CreateStyledButton(text, color)
    local button = Instance.new("TextButton")
    button.Size = UDim2.new(0, 120, 0, 35)
    button.BackgroundColor3 = color
    button.BorderSizePixel = 0
    button.Text = text
    button.TextColor3 = Color3.new(1, 1, 1)
    button.TextScaled = true
    button.Font = Enum.Font.SourceSansBold
    button.TextStrokeTransparency = 0.5
    button.TextStrokeColor3 = Color3.new(0, 0, 0)
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 8)
    corner.Parent = button
    
    local stroke = Instance.new("UIStroke")
    stroke.Color = Color3.new(1, 1, 1)
    stroke.Thickness = 1
    stroke.Transparency = 0.7
    stroke.Parent = button
    
    -- Hover effects
    button.MouseEnter:Connect(function()
        local hoverTween = TweenService:Create(button, TweenInfo.new(0.2), {BackgroundColor3 = color:lerp(Color3.new(1, 1, 1), 0.2)})
        hoverTween:Play()
    end)
    
    button.MouseLeave:Connect(function()
        local leaveTween = TweenService:Create(button, TweenInfo.new(0.2), {BackgroundColor3 = color})
        leaveTween:Play()
    end)
    
    return button
end

function PartyController:CreateVoicePanel()
    voiceFrame = Instance.new("Frame")
    voiceFrame.Name = "VoiceFrame"
    voiceFrame.Size = UDim2.new(1, -40, 0, 100)
    voiceFrame.Position = UDim2.new(0, 20, 0, 380)
    voiceFrame.BackgroundColor3 = Color3.new(0.1, 0.3, 0.1)
    voiceFrame.BackgroundTransparency = 0.2
    voiceFrame.BorderSizePixel = 0
    voiceFrame.Parent = partyFrame
    
    local voiceCorner = Instance.new("UICorner")
    voiceCorner.CornerRadius = UDim.new(0, 10)
    voiceCorner.Parent = voiceFrame
    
    local voiceTitle = Instance.new("TextLabel")
    voiceTitle.Size = UDim2.new(1, 0, 0, 25)
    voiceTitle.BackgroundTransparency = 1
    voiceTitle.Text = "🎤 VOICE COMMANDS"
    voiceTitle.TextColor3 = Color3.new(1, 1, 1)
    voiceTitle.TextScaled = true
    voiceTitle.Font = Enum.Font.SourceSansBold
    voiceTitle.Parent = voiceFrame
    
    local voiceScrollFrame = Instance.new("ScrollingFrame")
    voiceScrollFrame.Size = UDim2.new(1, -10, 1, -30)
    voiceScrollFrame.Position = UDim2.new(0, 5, 0, 25)
    voiceScrollFrame.BackgroundTransparency = 1
    voiceScrollFrame.ScrollBarThickness = 4
    voiceScrollFrame.Parent = voiceFrame
    
    local voiceLayout = Instance.new("UIGridLayout")
    voiceLayout.CellSize = UDim2.new(0, 85, 0, 20)
    voiceLayout.CellPadding = UDim2.new(0, 2, 0, 2)
    voiceLayout.Parent = voiceScrollFrame
    
    -- Create voice command buttons (will be populated when we get the commands)
    self.voiceScrollFrame = voiceScrollFrame
end

function PartyController:CreateEmotePanel()
    emoteFrame = Instance.new("Frame")
    emoteFrame.Name = "EmoteFrame"
    emoteFrame.Size = UDim2.new(1, -40, 0, 80)
    emoteFrame.Position = UDim2.new(0, 20, 0, 490)
    emoteFrame.BackgroundColor3 = Color3.new(0.3, 0.1, 0.3)
    emoteFrame.BackgroundTransparency = 0.2
    emoteFrame.BorderSizePixel = 0
    emoteFrame.Parent = partyFrame
    
    local emoteCorner = Instance.new("UICorner")
    emoteCorner.CornerRadius = UDim.new(0, 10)
    emoteCorner.Parent = emoteFrame
    
    local emoteTitle = Instance.new("TextLabel")
    emoteTitle.Size = UDim2.new(1, 0, 0, 25)
    emoteTitle.BackgroundTransparency = 1
    emoteTitle.Text = "😊 PARTY EMOTES"
    emoteTitle.TextColor3 = Color3.new(1, 1, 1)
    emoteTitle.TextScaled = true
    emoteTitle.Font = Enum.Font.SourceSansBold
    emoteTitle.Parent = emoteFrame
    
    local emoteScrollFrame = Instance.new("ScrollingFrame")
    emoteScrollFrame.Size = UDim2.new(1, -10, 1, -30)
    emoteScrollFrame.Position = UDim2.new(0, 5, 0, 25)
    emoteScrollFrame.BackgroundTransparency = 1
    emoteScrollFrame.ScrollBarThickness = 4
    emoteScrollFrame.Parent = emoteFrame
    
    local emoteLayout = Instance.new("UIGridLayout")
    emoteLayout.CellSize = UDim2.new(0, 30, 0, 25)
    emoteLayout.CellPadding = UDim2.new(0, 5, 0, 2)
    emoteLayout.Parent = emoteScrollFrame
    
    self.emoteScrollFrame = emoteScrollFrame
end

function PartyController:CreateStatsPanel()
    local statsFrame = Instance.new("Frame")
    statsFrame.Name = "StatsFrame"
    statsFrame.Size = UDim2.new(1, -40, 0, 20)
    statsFrame.Position = UDim2.new(0, 20, 1, -25)
    statsFrame.BackgroundTransparency = 1
    statsFrame.Parent = partyFrame
    
    local statsLabel = Instance.new("TextLabel")
    statsLabel.Name = "StatsLabel"
    statsLabel.Size = UDim2.new(1, 0, 1, 0)
    statsLabel.BackgroundTransparency = 1
    statsLabel.Text = "💫 Ready to party!"
    statsLabel.TextColor3 = Color3.new(0.8, 0.8, 0.8)
    statsLabel.TextScaled = true
    statsLabel.Font = Enum.Font.SourceSansItalic
    statsLabel.Parent = statsFrame
    
    self.statsLabel = statsLabel
end

function PartyController:UpdateVoiceCommands(commands)
    voiceCommands = commands
    
    -- Clear existing buttons
    for _, child in pairs(self.voiceScrollFrame:GetChildren()) do
        if child:IsA("GuiObject") then
            child:Destroy()
        end
    end
    
    -- Create new voice command buttons
    for i, command in pairs(commands) do
        local button = Instance.new("TextButton")
        button.Size = UDim2.new(0, 85, 0, 20)
        button.BackgroundColor3 = Color3.new(0.2, 0.6, 0.2)
        button.BorderSizePixel = 0
        button.Text = command
        button.TextColor3 = Color3.new(1, 1, 1)
        button.TextScaled = true
        button.Font = Enum.Font.SourceSans
        button.Parent = self.voiceScrollFrame
        
        local corner = Instance.new("UICorner")
        corner.CornerRadius = UDim.new(0, 4)
        corner.Parent = button
        
        button.MouseButton1Click:Connect(function()
            RemoteEvents.SendPartyVoice:FireServer(i)
            self:AnimateButton(button)
        end)
    end
    
    -- Update scroll frame size
    local layout = self.voiceScrollFrame:FindFirstChild("UIGridLayout")
    if layout then
        self.voiceScrollFrame.CanvasSize = UDim2.new(0, 0, 0, layout.AbsoluteContentSize.Y)
    end
end

function PartyController:UpdateEmotes(emoteList)
    emotes = emoteList
    
    -- Clear existing buttons
    for _, child in pairs(self.emoteScrollFrame:GetChildren()) do
        if child:IsA("GuiObject") then
            child:Destroy()
        end
    end
    
    -- Create new emote buttons
    for i, emote in pairs(emoteList) do
        local button = Instance.new("TextButton")
        button.Size = UDim2.new(0, 30, 0, 25)
        button.BackgroundColor3 = Color3.new(0.6, 0.2, 0.6)
        button.BorderSizePixel = 0
        button.Text = emote
        button.TextColor3 = Color3.new(1, 1, 1)
        button.TextScaled = true
        button.Font = Enum.Font.SourceSans
        button.Parent = self.emoteScrollFrame
        
        local corner = Instance.new("UICorner")
        corner.CornerRadius = UDim.new(0, 6)
        corner.Parent = button
        
        button.MouseButton1Click:Connect(function()
            RemoteEvents.SendPartyEmote:FireServer(i)
            self:AnimateButton(button)
        end)
    end
    
    -- Update scroll frame size
    local layout = self.emoteScrollFrame:FindFirstChild("UIGridLayout")
    if layout then
        self.emoteScrollFrame.CanvasSize = UDim2.new(0, 0, 0, layout.AbsoluteContentSize.Y)
    end
end

function PartyController:AnimateButton(button)
    local originalSize = button.Size
    local scaleUp = TweenService:Create(button, TweenInfo.new(0.1), {Size = originalSize * 1.2})
    local scaleDown = TweenService:Create(button, TweenInfo.new(0.1), {Size = originalSize})
    
    scaleUp:Play()
    scaleUp.Completed:Connect(function()
        scaleDown:Play()
    end)
end

function PartyController:ShowInviteNotification(inviteData)
    local notificationFrame = Instance.new("Frame")
    notificationFrame.Name = "InviteNotification"
    notificationFrame.Size = UDim2.new(0, 350, 0, 120)
    notificationFrame.Position = UDim2.new(1, -370, 0, 20)
    notificationFrame.BackgroundColor3 = Color3.new(0.1, 0.2, 0.4)
    notificationFrame.BorderSizePixel = 0
    notificationFrame.Parent = playerGui
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 12)
    corner.Parent = notificationFrame
    
    local stroke = Instance.new("UIStroke")
    stroke.Color = Color3.new(0.3, 0.6, 1)
    stroke.Thickness = 2
    stroke.Parent = notificationFrame
    
    -- Animated header
    local header = Instance.new("TextLabel")
    header.Size = UDim2.new(1, -20, 0, 30)
    header.Position = UDim2.new(0, 10, 0, 5)
    header.BackgroundTransparency = 1
    header.Text = "🎉 PARTY INVITE!"
    header.TextColor3 = Color3.new(1, 1, 0.5)
    header.TextScaled = true
    header.Font = Enum.Font.SourceSansBold
    header.Parent = notificationFrame
    
    -- Party info
    local infoLabel = Instance.new("TextLabel")
    infoLabel.Size = UDim2.new(1, -20, 0, 40)
    infoLabel.Position = UDim2.new(0, 10, 0, 35)
    infoLabel.BackgroundTransparency = 1
    infoLabel.Text = inviteData.inviter .. " invited you!\nParty Level " .. (inviteData.partyLevel or 1) .. " • " .. inviteData.partySize .. "/" .. inviteData.maxSize .. " members"
    infoLabel.TextColor3 = Color3.new(1, 1, 1)
    infoLabel.TextScaled = true
    infoLabel.Font = Enum.Font.SourceSans
    infoLabel.Parent = notificationFrame
    
    -- Motto
    local mottoLabel = Instance.new("TextLabel")
    mottoLabel.Size = UDim2.new(1, -20, 0, 15)
    mottoLabel.Position = UDim2.new(0, 10, 0, 75)
    mottoLabel.BackgroundTransparency = 1
    mottoLabel.Text = "\"" .. (inviteData.partyMotto or "Together we rise!") .. "\""
    mottoLabel.TextColor3 = Color3.new(0.8, 0.8, 1)
    mottoLabel.TextScaled = true
    mottoLabel.Font = Enum.Font.SourceSansItalic
    mottoLabel.Parent = notificationFrame
    
    -- Buttons
    local acceptButton = Instance.new("TextButton")
    acceptButton.Size = UDim2.new(0, 80, 0, 25)
    acceptButton.Position = UDim2.new(0, 10, 1, -30)
    acceptButton.BackgroundColor3 = Color3.new(0.2, 0.8, 0.2)
    acceptButton.BorderSizePixel = 0
    acceptButton.Text = "✅ Accept"
    acceptButton.TextColor3 = Color3.new(1, 1, 1)
    acceptButton.TextScaled = true
    acceptButton.Font = Enum.Font.SourceSansBold
    acceptButton.Parent = notificationFrame
    
    local acceptCorner = Instance.new("UICorner")
    acceptCorner.CornerRadius = UDim.new(0, 6)
    acceptCorner.Parent = acceptButton
    
    local declineButton = Instance.new("TextButton")
    declineButton.Size = UDim2.new(0, 80, 0, 25)
    declineButton.Position = UDim2.new(1, -90, 1, -30)
    declineButton.BackgroundColor3 = Color3.new(0.8, 0.2, 0.2)
    declineButton.BorderSizePixel = 0
    declineButton.Text = "❌ Decline"
    declineButton.TextColor3 = Color3.new(1, 1, 1)
    declineButton.TextScaled = true
    declineButton.Font = Enum.Font.SourceSansBold
    declineButton.Parent = notificationFrame
    
    local declineCorner = Instance.new("UICorner")
    declineCorner.CornerRadius = UDim.new(0, 6)
    declineCorner.Parent = declineButton
    
    -- Entrance animation
    notificationFrame.Position = UDim2.new(1, 20, 0, 20)
    local entranceTween = TweenService:Create(
        notificationFrame,
        TweenInfo.new(0.4, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
        {Position = UDim2.new(1, -370, 0, 20)}
    )
    entranceTween:Play()
    
    -- Button connections
    acceptButton.MouseButton1Click:Connect(function()
        RemoteEvents.AcceptPartyInvite:FireServer(inviteData.inviterUserId)
        self:HideNotification(notificationFrame)
    end)
    
    declineButton.MouseButton1Click:Connect(function()
        self:HideNotification(notificationFrame)
    end)
    
    -- Auto-hide after timeout
    spawn(function()
        wait(inviteData.expiresIn or 60)
        if notificationFrame.Parent then
            self:HideNotification(notificationFrame)
        end
    end)
end

function PartyController:HideNotification(notification)
    local exitTween = TweenService:Create(
        notification,
        TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.In),
        {Position = UDim2.new(1, 20, notification.Position.Y.Scale, notification.Position.Y.Offset)}
    )
    exitTween:Play()
    exitTween.Completed:Connect(function()
        notification:Destroy()
    end)
end

function PartyController:ShowXpBonus(bonusData)
    local bonusFrame = Instance.new("Frame")
    bonusFrame.Size = UDim2.new(0, 300, 0, 100)
    bonusFrame.Position = UDim2.new(0.5, -150, 0.3, 0)
    bonusFrame.BackgroundColor3 = Color3.new(0.1, 0.1, 0.1)
    bonusFrame.BackgroundTransparency = 0.2
    bonusFrame.BorderSizePixel = 0
    bonusFrame.Parent = playerGui
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 15)
    corner.Parent = bonusFrame
    
    local glow = Instance.new("UIStroke")
    glow.Color = Color3.new(1, 0.8, 0.2)
    glow.Thickness = 3
    glow.Transparency = 0.5
    glow.Parent = bonusFrame
    
    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(1, 0, 0, 30)
    title.Position = UDim2.new(0, 0, 0, 10)
    title.BackgroundTransparency = 1
    title.Text = "🎉 PARTY BONUS XP!"
    title.TextColor3 = Color3.new(1, 1, 0.2)
    title.TextScaled = true
    title.Font = Enum.Font.SourceSansBold
    title.Parent = bonusFrame
    
    local details = Instance.new("TextLabel")
    details.Size = UDim2.new(1, 0, 0, 60)
    details.Position = UDim2.new(0, 0, 0, 40)
    details.BackgroundTransparency = 1
    details.Text = string.format(
        "Base XP: %d\nBonus XP: +%d (%.1fx multiplier)\nStreak: %d%s",
        bonusData.baseXP,
        bonusData.bonusXP,
        bonusData.totalMultiplier,
        bonusData.streak or 0,
        bonusData.isPerfect and " 🌟 PERFECT!" or ""
    )
    details.TextColor3 = Color3.new(1, 1, 1)
    details.TextScaled = true
    details.Font = Enum.Font.SourceSans
    details.Parent = bonusFrame
    
    -- Celebration animation
    local celebrationTween = TweenService:Create(
        bonusFrame,
        TweenInfo.new(0.5, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
        {Size = UDim2.new(0, 320, 0, 110)}
    )
    celebrationTween:Play()
    
    -- Auto-hide
    spawn(function()
        wait(4)
        local hideTween = TweenService:Create(
            bonusFrame,
            TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
            {Position = UDim2.new(0.5, -150, -0.2, 0), BackgroundTransparency = 1}
        )
        hideTween:Play()
        hideTween.Completed:Connect(function()
            bonusFrame:Destroy()
        end)
    end)
end

function PartyController:CreatePartyClicked()
    RemoteEvents.CreateParty:FireServer()
end

function PartyController:StartPartyGame()
    RemoteEvents.StartPartyGame:FireServer()
end

function PartyController:LeavePartyClicked()
    RemoteEvents.LeaveParty:FireServer()
end

function PartyController:ShowInviteMenu()
    -- Simple friend selection (placeholder - would integrate with actual friends system)
    local friendNames = {}
    for _, player in pairs(Players:GetPlayers()) do
        if player ~= Players.LocalPlayer then
            table.insert(friendNames, player.Name)
        end
    end
    
    if #friendNames == 0 then
        self:ShowNotification("No friends online to invite!", "warning")
        return
    end
    
    -- Create quick invite menu
    local inviteMenu = Instance.new("Frame")
    inviteMenu.Size = UDim2.new(0, 200, 0, math.min(#friendNames * 35 + 40, 300))
    inviteMenu.Position = UDim2.new(0.5, -100, 0.5, -150)
    inviteMenu.BackgroundColor3 = Color3.new(0.1, 0.1, 0.2)
    inviteMenu.BorderSizePixel = 0
    inviteMenu.Parent = playerGui
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 10)
    corner.Parent = inviteMenu
    
    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(1, 0, 0, 30)
    title.BackgroundTransparency = 1
    title.Text = "📨 Invite Friends"
    title.TextColor3 = Color3.new(1, 1, 1)
    title.TextScaled = true
    title.Font = Enum.Font.SourceSansBold
    title.Parent = inviteMenu
    
    local scrollFrame = Instance.new("ScrollingFrame")
    scrollFrame.Size = UDim2.new(1, -10, 1, -40)
    scrollFrame.Position = UDim2.new(0, 5, 0, 35)
    scrollFrame.BackgroundTransparency = 1
    scrollFrame.Parent = inviteMenu
    
    local layout = Instance.new("UIListLayout")
    layout.Padding = UDim.new(0, 2)
    layout.Parent = scrollFrame
    
    for _, friendName in pairs(friendNames) do
        local friendButton = Instance.new("TextButton")
        friendButton.Size = UDim2.new(1, -10, 0, 30)
        friendButton.BackgroundColor3 = Color3.new(0.2, 0.4, 0.6)
        friendButton.BorderSizePixel = 0
        friendButton.Text = "👤 " .. friendName
        friendButton.TextColor3 = Color3.new(1, 1, 1)
        friendButton.TextScaled = true
        friendButton.Font = Enum.Font.SourceSans
        friendButton.Parent = scrollFrame
        
        local buttonCorner = Instance.new("UICorner")
        buttonCorner.CornerRadius = UDim.new(0, 6)
        buttonCorner.Parent = friendButton
        
        friendButton.MouseButton1Click:Connect(function()
            RemoteEvents.SendPartyInvite:FireServer(friendName)
            inviteMenu:Destroy()
        end)
    end
    
    scrollFrame.CanvasSize = UDim2.new(0, 0, 0, layout.AbsoluteContentSize.Y)
    
    -- Click outside to close
    local closeDetector = Instance.new("TextButton")
    closeDetector.Size = UDim2.new(1, 0, 1, 0)
    closeDetector.BackgroundTransparency = 1
    closeDetector.Text = ""
    closeDetector.ZIndex = inviteMenu.ZIndex - 1
    closeDetector.Parent = playerGui
    closeDetector.MouseButton1Click:Connect(function()
        inviteMenu:Destroy()
        closeDetector:Destroy()
    end)
end

function PartyController:ShowNotification(message, notificationType)
    local notification = Instance.new("Frame")
    notification.Size = UDim2.new(0, 300, 0, 60)
    notification.Position = UDim2.new(0.5, -150, 0, -70)
    notification.BackgroundColor3 = notificationType == "warning" and Color3.new(0.8, 0.6, 0.2) or Color3.new(0.2, 0.6, 0.8)
    notification.BorderSizePixel = 0
    notification.Parent = playerGui
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 8)
    corner.Parent = notification
    
    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, -20, 1, 0)
    label.Position = UDim2.new(0, 10, 0, 0)
    label.BackgroundTransparency = 1
    label.Text = message
    label.TextColor3 = Color3.new(1, 1, 1)
    label.TextScaled = true
    label.Font = Enum.Font.SourceSans
    label.TextWrapped = true
    label.Parent = notification
    
    -- Slide down animation
    local slideTween = TweenService:Create(
        notification,
        TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
        {Position = UDim2.new(0.5, -150, 0, 20)}
    )
    slideTween:Play()
    
    -- Auto-hide
    spawn(function()
        wait(3)
        local hideTween = TweenService:Create(
            notification,
            TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
            {Position = UDim2.new(0.5, -150, 0, -70)}
        )
        hideTween:Play()
        hideTween.Completed:Connect(function()
            notification:Destroy()
        end)
    end)
end

function PartyController:Init()
    print("🎉 Enhanced PartyController initializing...")
    
    -- Create the enhanced UI
    self:CreatePartyUI()
    
    -- Request voice commands and emotes from server
    spawn(function()
        wait(1)
        -- These would be requested from server in real implementation
        self:UpdateVoiceCommands({"Nice run!", "Good job!", "Let's go!", "Perfect!", "Amazing!"})
        self:UpdateEmotes({"👍", "🔥", "⚡", "🎉", "💪", "🌟", "✨", "🏆"})
    end)
    
    -- Remote event connections
    RemoteEvents.PartyInviteReceived.OnClientEvent:Connect(function(inviteData)
        self:ShowInviteNotification(inviteData)
    end)
    
    RemoteEvents.PartyXPBonus.OnClientEvent:Connect(function(bonusData)
        self:ShowXpBonus(bonusData)
    end)
    
    RemoteEvents.PartyNotification.OnClientEvent:Connect(function(data)
        self:ShowNotification(data.message, data.type)
    end)
    
    RemoteEvents.PartyVoiceMessage.OnClientEvent:Connect(function(data)
        self:ShowVoiceMessage(data)
    end)
    
    RemoteEvents.PartyEmote.OnClientEvent:Connect(function(data)
        self:ShowEmoteEffect(data)
    end)
    
    RemoteEvents.PartyCelebration.OnClientEvent:Connect(function(data)
        self:PlayCelebration(data)
    end)
    
    print("✅ Enhanced PartyController initialized with creative features!")
end

function PartyController:ShowVoiceMessage(data)
    -- Create floating voice message
    local voiceMsg = Instance.new("Frame")
    voiceMsg.Size = UDim2.new(0, 250, 0, 50)
    voiceMsg.Position = UDim2.new(math.random(20, 60)/100, 0, math.random(30, 70)/100, 0)
    voiceMsg.BackgroundColor3 = Color3.new(0.1, 0.3, 0.1)
    voiceMsg.BackgroundTransparency = 0.1
    voiceMsg.BorderSizePixel = 0
    voiceMsg.Parent = playerGui
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 15)
    corner.Parent = voiceMsg
    
    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, -20, 1, 0)
    label.Position = UDim2.new(0, 10, 0, 0)
    label.BackgroundTransparency = 1
    label.Text = "🎤 " .. data.sender .. ": \"" .. data.message .. "\""
    label.TextColor3 = Color3.new(1, 1, 1)
    label.TextScaled = true
    label.Font = Enum.Font.SourceSansItalic
    label.Parent = voiceMsg
    
    -- Floating and fade animation
    local floatTween = TweenService:Create(
        voiceMsg,
        TweenInfo.new(3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
        {Position = voiceMsg.Position + UDim2.new(0, 0, -0.1, 0), BackgroundTransparency = 1}
    )
    
    local fadeTween = TweenService:Create(
        label,
        TweenInfo.new(3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
        {TextTransparency = 1}
    )
    
    floatTween:Play()
    fadeTween:Play()
    
    floatTween.Completed:Connect(function()
        voiceMsg:Destroy()
    end)
end

function PartyController:ShowEmoteEffect(data)
    -- Create big floating emote
    local emoteEffect = Instance.new("TextLabel")
    emoteEffect.Size = UDim2.new(0, 80, 0, 80)
    emoteEffect.Position = UDim2.new(math.random(10, 80)/100, 0, math.random(20, 60)/100, 0)
    emoteEffect.BackgroundTransparency = 1
    emoteEffect.Text = data.emote
    emoteEffect.TextColor3 = Color3.new(1, 1, 1)
    emoteEffect.TextScaled = true
    emoteEffect.Font = Enum.Font.SourceSans
    emoteEffect.ZIndex = 10
    emoteEffect.Parent = playerGui
    
    -- Bounce and spin animation
    local originalSize = emoteEffect.Size
    local bounceTween = TweenService:Create(
        emoteEffect,
        TweenInfo.new(0.2, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
        {Size = originalSize * 1.5}
    )
    
    local shrinkTween = TweenService:Create(
        emoteEffect,
        TweenInfo.new(2, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
        {Size = UDim2.new(0, 0, 0, 0), TextTransparency = 1, Rotation = 360}
    )
    
    bounceTween:Play()
    bounceTween.Completed:Connect(function()
        shrinkTween:Play()
    end)
    
    shrinkTween.Completed:Connect(function()
        emoteEffect:Destroy()
    end)
end

function PartyController:PlayCelebration(data)
    -- Create massive celebration effect
    for i = 1, 10 do
        local particle = Instance.new("TextLabel")
        particle.Size = UDim2.new(0, 60, 0, 60)
        particle.Position = UDim2.new(0.5, math.random(-200, 200), 0.5, math.random(-200, 200))
        particle.BackgroundTransparency = 1
        particle.Text = ({"🎉", "🎊", "✨", "🌟", "💫", "🎆"})[math.random(1, 6)]
        particle.TextColor3 = Color3.new(math.random(), math.random(), math.random())
        particle.TextScaled = true
        particle.Font = Enum.Font.SourceSans
        particle.ZIndex = 10
        particle.Parent = playerGui
        
        local celebrationTween = TweenService:Create(
            particle,
            TweenInfo.new(2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
            {
                Position = particle.Position + UDim2.new(0, math.random(-100, 100), 0, -300),
                TextTransparency = 1,
                Rotation = math.random(-360, 360)
            }
        )
        
        celebrationTween:Play()
        celebrationTween.Completed:Connect(function()
            particle:Destroy()
        end)
    end
end

return PartyController
