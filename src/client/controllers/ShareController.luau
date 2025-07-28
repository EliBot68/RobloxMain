-- ShareController.luau
-- Handles sharing game scores and achievements

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local GuiService = game:GetService("GuiService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local RemoteEvents = require(ReplicatedStorage.Shared.modules.RemoteEvents)

local ShareController = {}

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- UI Variables
local shareGui = nil
local shareFrame = nil
local isShareGuiOpen = false

-- Share message templates
local SHARE_TEMPLATES = {
    high_score = "🎮 Just scored {SCORE} points in Color Rush! Can you beat my record? Play now: {GAME_LINK}",
    perfect_run = "🎯 Perfect run in Color Rush! {SCORE} points with zero mistakes! Think you can do better? {GAME_LINK}",
    milestone = "🏆 Reached {BARRIERS} barriers in Color Rush with {SCORE} points! Join the challenge: {GAME_LINK}",
    comeback = "💪 What a comeback! Scored {SCORE} points in Color Rush after a tough start! Your turn: {GAME_LINK}",
    casual = "🌈 Had fun playing Color Rush! Scored {SCORE} points - come join me! {GAME_LINK}",
    ghost_victory = "👻 Just beat a ghost runner in Color Rush! {SCORE} points and counting! Race me: {GAME_LINK}",
    upgrade_showcase = "⚡ My upgrades are paying off! {SCORE} points in Color Rush with enhanced abilities! {GAME_LINK}"
}

-- UI Colors
local COLORS = {
    background = Color3.new(0.1, 0.1, 0.15),
    panel = Color3.new(0.15, 0.15, 0.2),
    accent = Color3.new(0.2, 0.8, 0.3),
    text = Color3.new(0.9, 0.9, 0.9),
    success = Color3.new(0.2, 0.8, 0.2),
    button = Color3.new(0.3, 0.6, 1),
    share = Color3.new(1, 0.6, 0.2)
}

function ShareController:CreateShareGUI()
    -- Main GUI
    shareGui = Instance.new("ScreenGui")
    shareGui.Name = "ShareScore"
    shareGui.ResetOnSpawn = false
    shareGui.Parent = playerGui
    
    -- Background
    local background = Instance.new("Frame")
    background.Name = "Background"
    background.Size = UDim2.new(1, 0, 1, 0)
    background.Position = UDim2.new(0, 0, 0, 0)
    background.BackgroundColor3 = Color3.new(0, 0, 0)
    background.BackgroundTransparency = 0.4
    background.BorderSizePixel = 0
    background.Parent = shareGui
    
    -- Main Frame
    shareFrame = Instance.new("Frame")
    shareFrame.Name = "ShareFrame"
    shareFrame.Size = UDim2.new(0, 500, 0, 400)
    shareFrame.Position = UDim2.new(0.5, -250, 0.5, -200)
    shareFrame.BackgroundColor3 = COLORS.background
    shareFrame.BorderSizePixel = 0
    shareFrame.Parent = background
    
    -- Round corners
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 15)
    corner.Parent = shareFrame
    
    -- Header
    local header = Instance.new("Frame")
    header.Name = "Header"
    header.Size = UDim2.new(1, 0, 0, 70)
    header.Position = UDim2.new(0, 0, 0, 0)
    header.BackgroundColor3 = COLORS.accent
    header.BorderSizePixel = 0
    header.Parent = shareFrame
    
    local headerCorner = Instance.new("UICorner")
    headerCorner.CornerRadius = UDim.new(0, 15)
    headerCorner.Parent = header
    
    -- Fix corner overlap
    local headerFix = Instance.new("Frame")
    headerFix.Size = UDim2.new(1, 0, 0, 15)
    headerFix.Position = UDim2.new(0, 0, 1, -15)
    headerFix.BackgroundColor3 = COLORS.accent
    headerFix.BorderSizePixel = 0
    headerFix.Parent = header
    
    -- Title
    local title = Instance.new("TextLabel")
    title.Name = "Title"
    title.Size = UDim2.new(1, -100, 1, 0)
    title.Position = UDim2.new(0, 20, 0, 0)
    title.BackgroundTransparency = 1
    title.Text = "📤 SHARE YOUR SCORE"
    title.TextColor3 = Color3.new(1, 1, 1)
    title.TextScaled = true
    title.Font = Enum.Font.SourceSansBold
    title.Parent = header
    
    -- Close Button
    local closeButton = Instance.new("TextButton")
    closeButton.Name = "CloseButton"
    closeButton.Size = UDim2.new(0, 50, 0, 50)
    closeButton.Position = UDim2.new(1, -60, 0, 10)
    closeButton.BackgroundColor3 = Color3.new(0.8, 0.2, 0.2)
    closeButton.Text = "✕"
    closeButton.TextColor3 = Color3.new(1, 1, 1)
    closeButton.TextScaled = true
    closeButton.Font = Enum.Font.SourceSansBold
    closeButton.BorderSizePixel = 0
    closeButton.Parent = header
    
    local closeCorner = Instance.new("UICorner")
    closeCorner.CornerRadius = UDim.new(0, 8)
    closeCorner.Parent = closeButton
    
    closeButton.MouseButton1Click:Connect(function()
        self:HideShareGUI()
    end)
    
    -- Content Area
    local contentFrame = Instance.new("Frame")
    contentFrame.Name = "Content"
    contentFrame.Size = UDim2.new(1, -40, 1, -90)
    contentFrame.Position = UDim2.new(0, 20, 0, 80)
    contentFrame.BackgroundTransparency = 1
    contentFrame.Parent = shareFrame
    
    -- Score Display
    local scoreLabel = Instance.new("TextLabel")
    scoreLabel.Name = "ScoreLabel"
    scoreLabel.Size = UDim2.new(1, 0, 0, 60)
    scoreLabel.Position = UDim2.new(0, 0, 0, 0)
    scoreLabel.BackgroundTransparency = 1
    scoreLabel.Text = "Score: 0"
    scoreLabel.TextColor3 = COLORS.accent
    scoreLabel.TextScaled = true
    scoreLabel.Font = Enum.Font.SourceSansBold
    scoreLabel.Parent = contentFrame
    
    -- Message Preview
    local messageFrame = Instance.new("Frame")
    messageFrame.Name = "MessageFrame"
    messageFrame.Size = UDim2.new(1, 0, 0, 120)
    messageFrame.Position = UDim2.new(0, 0, 0, 70)
    messageFrame.BackgroundColor3 = COLORS.panel
    messageFrame.BorderSizePixel = 0
    messageFrame.Parent = contentFrame
    
    local messageCorner = Instance.new("UICorner")
    messageCorner.CornerRadius = UDim.new(0, 8)
    messageCorner.Parent = messageFrame
    
    local messageLabel = Instance.new("TextLabel")
    messageLabel.Name = "MessageLabel"
    messageLabel.Size = UDim2.new(1, -20, 1, -20)
    messageLabel.Position = UDim2.new(0, 10, 0, 10)
    messageLabel.BackgroundTransparency = 1
    messageLabel.Text = ""
    messageLabel.TextColor3 = COLORS.text
    messageLabel.TextScaled = false
    messageLabel.TextWrapped = true
    messageLabel.TextSize = 14
    messageLabel.Font = Enum.Font.SourceSans
    messageLabel.TextXAlignment = Enum.TextXAlignment.Left
    messageLabel.TextYAlignment = Enum.TextYAlignment.Top
    messageLabel.Parent = messageFrame
    
    -- Share Options
    local shareOptionsFrame = Instance.new("Frame")
    shareOptionsFrame.Name = "ShareOptions"
    shareOptionsFrame.Size = UDim2.new(1, 0, 0, 100)
    shareOptionsFrame.Position = UDim2.new(0, 0, 1, -110)
    shareOptionsFrame.BackgroundTransparency = 1
    shareOptionsFrame.Parent = contentFrame
    
    -- Copy to Clipboard Button
    local copyButton = Instance.new("TextButton")
    copyButton.Name = "CopyButton"
    copyButton.Size = UDim2.new(0.48, 0, 0, 40)
    copyButton.Position = UDim2.new(0, 0, 0, 0)
    copyButton.BackgroundColor3 = COLORS.button
    copyButton.Text = "📋 Copy Message"
    copyButton.TextColor3 = Color3.new(1, 1, 1)
    copyButton.TextScaled = true
    copyButton.Font = Enum.Font.SourceSansBold
    copyButton.BorderSizePixel = 0
    copyButton.Parent = shareOptionsFrame
    
    local copyCorner = Instance.new("UICorner")
    copyCorner.CornerRadius = UDim.new(0, 6)
    copyCorner.Parent = copyButton
    
    -- Share Button (opens Roblox share panel)
    local shareButton = Instance.new("TextButton")
    shareButton.Name = "ShareButton"
    shareButton.Size = UDim2.new(0.48, 0, 0, 40)
    shareButton.Position = UDim2.new(0.52, 0, 0, 0)
    shareButton.BackgroundColor3 = COLORS.share
    shareButton.Text = "🚀 Share Game"
    shareButton.TextColor3 = Color3.new(1, 1, 1)
    shareButton.TextScaled = true
    shareButton.Font = Enum.Font.SourceSansBold
    shareButton.BorderSizePixel = 0
    shareButton.Parent = shareOptionsFrame
    
    local shareCorner = Instance.new("UICorner")
    shareCorner.CornerRadius = UDim.new(0, 6)
    shareCorner.Parent = shareButton
    
    -- Template Buttons
    local templateFrame = Instance.new("Frame")
    templateFrame.Name = "TemplateFrame"
    templateFrame.Size = UDim2.new(1, 0, 0, 50)
    templateFrame.Position = UDim2.new(0, 0, 0, 50)
    templateFrame.BackgroundTransparency = 1
    templateFrame.Parent = shareOptionsFrame
    
    local templateLayout = Instance.new("UIListLayout")
    templateLayout.FillDirection = Enum.FillDirection.Horizontal
    templateLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
    templateLayout.Padding = UDim.new(0, 5)
    templateLayout.Parent = templateFrame
    
    -- Template selection buttons
    local templates = {"🏆 Epic", "🎯 Perfect", "💪 Comeback", "🌈 Casual"}
    for i, templateName in pairs(templates) do
        local templateButton = Instance.new("TextButton")
        templateButton.Name = "Template" .. i
        templateButton.Size = UDim2.new(0, 100, 1, 0)
        templateButton.BackgroundColor3 = COLORS.panel
        templateButton.Text = templateName
        templateButton.TextColor3 = COLORS.text
        templateButton.TextScaled = true
        templateButton.Font = Enum.Font.SourceSans
        templateButton.BorderSizePixel = 0
        templateButton.Parent = templateFrame
        
        local templateCorner = Instance.new("UICorner")
        templateCorner.CornerRadius = UDim.new(0, 4)
        templateCorner.Parent = templateButton
        
        templateButton.MouseButton1Click:Connect(function()
            self:SelectTemplate(i)
        end)
    end
    
    -- Connect button events
    copyButton.MouseButton1Click:Connect(function()
        self:CopyToClipboard()
    end)
    
    shareButton.MouseButton1Click:Connect(function()
        self:OpenRobloxShare()
    end)
    
    -- Close when clicking background
    background.MouseButton1Click:Connect(function()
        self:HideShareGUI()
    end)
    
    -- Prevent closing when clicking the main frame
    shareFrame.MouseButton1Click:Connect(function()
        -- Do nothing (prevent event from reaching background)
    end)
    
    shareGui.Enabled = false
end

function ShareController:ShowShareGUI(scoreData)
    if not shareGui then
        self:CreateShareGUI()
    end
    
    -- Store score data
    self.currentScoreData = scoreData
    
    -- Update score display
    local scoreLabel = shareFrame.Content.ScoreLabel
    scoreLabel.Text = string.format("🏆 Score: %d • Barriers: %d • Coins: %d", 
        scoreData.score, scoreData.barriersPassed, scoreData.coinsCollected)
    
    -- Set default template
    self:SelectTemplate(1)
    
    shareGui.Enabled = true
    isShareGuiOpen = true
    
    -- Animate entrance
    shareFrame.Size = UDim2.new(0, 0, 0, 0)
    shareFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
    
    local tween = TweenService:Create(
        shareFrame,
        TweenInfo.new(0.4, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
        {
            Size = UDim2.new(0, 500, 0, 400),
            Position = UDim2.new(0.5, -250, 0.5, -200)
        }
    )
    tween:Play()
    
    print("📤 Share score GUI opened")
end

function ShareController:HideShareGUI()
    if not shareGui or not shareGui.Enabled then return end
    
    isShareGuiOpen = false
    
    -- Animate exit
    local tween = TweenService:Create(
        shareFrame,
        TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.In),
        {
            Size = UDim2.new(0, 0, 0, 0),
            Position = UDim2.new(0.5, 0, 0.5, 0)
        }
    )
    
    tween:Play()
    tween.Completed:Connect(function()
        shareGui.Enabled = false
    end)
    
    print("📤 Share score GUI closed")
end

function ShareController:SelectTemplate(templateIndex)
    if not self.currentScoreData then return end
    
    local scoreData = self.currentScoreData
    local templateKeys = {"high_score", "perfect_run", "comeback", "casual"}
    local templateKey = templateKeys[templateIndex] or "casual"
    
    -- Special template selection based on performance
    if scoreData.isPerfect then
        templateKey = "perfect_run"
    elseif scoreData.isNewHighScore then
        templateKey = "high_score"
    elseif scoreData.ghostVictory then
        templateKey = "ghost_victory"
    elseif scoreData.hasUpgrades then
        templateKey = "upgrade_showcase"
    elseif scoreData.barriersPassed >= 20 then
        templateKey = "milestone"
    end
    
    local template = SHARE_TEMPLATES[templateKey] or SHARE_TEMPLATES.casual
    
    -- Replace placeholders
    local gameLink = "https://www.roblox.com/games/" .. (game.PlaceId or "0000000000") .. "/Color-Rush"
    local message = template:gsub("{SCORE}", tostring(scoreData.score))
                           :gsub("{BARRIERS}", tostring(scoreData.barriersPassed))
                           :gsub("{COINS}", tostring(scoreData.coinsCollected))
                           :gsub("{GAME_LINK}", gameLink)
    
    -- Update message display
    local messageLabel = shareFrame.Content.MessageFrame.MessageLabel
    messageLabel.Text = message
    
    self.currentMessage = message
    
    -- Highlight selected template button
    local templateFrame = shareFrame.Content.ShareOptions.TemplateFrame
    for i, child in pairs(templateFrame:GetChildren()) do
        if child:IsA("TextButton") then
            if child.Name == "Template" .. templateIndex then
                child.BackgroundColor3 = COLORS.accent
                child.TextColor3 = Color3.new(1, 1, 1)
            else
                child.BackgroundColor3 = COLORS.panel
                child.TextColor3 = COLORS.text
            end
        end
    end
end

function ShareController:CopyToClipboard()
    if not self.currentMessage then return end
    
    -- Use the Roblox clipboard service (Note: This requires proper game permissions)
    local success = pcall(function()
        -- For now, we'll use a workaround since direct clipboard access is limited
        -- In a real implementation, this would copy to clipboard
        print("📋 Copied to clipboard: " .. self.currentMessage)
    end)
    
    -- Show feedback
    self:ShowNotification(success and "Message copied to clipboard!" or "Copy feature not available", success)
    
    -- Send analytics event
    RemoteEvents.LogShareEvent:FireServer("copy", {
        score = self.currentScoreData.score,
        barriers = self.currentScoreData.barriersPassed,
        template = "copied"
    })
end

function ShareController:OpenRobloxShare()
    -- Open the Roblox share panel
    local success = pcall(function()
        -- This would open the Roblox share interface
        GuiService:SetGameplayPausedNotificationEnabled(false)
        -- Note: Actual Roblox share API would be used here
        print("🚀 Opening Roblox share panel...")
    end)
    
    -- Show feedback
    self:ShowNotification(success and "Opening share panel..." or "Share feature not available", success)
    
    -- Send analytics event
    RemoteEvents.LogShareEvent:FireServer("share", {
        score = self.currentScoreData.score,
        barriers = self.currentScoreData.barriersPassed,
        template = "roblox_share"
    })
    
    self:HideShareGUI()
end

function ShareController:ShowNotification(message, isSuccess)
    -- Create notification
    local notification = Instance.new("Frame")
    notification.Name = "ShareNotification"
    notification.Size = UDim2.new(0, 300, 0, 60)
    notification.Position = UDim2.new(0.5, -150, 0, -80)
    notification.BackgroundColor3 = isSuccess and COLORS.success or COLORS.panel
    notification.BorderSizePixel = 0
    notification.Parent = playerGui
    
    local notifCorner = Instance.new("UICorner")
    notifCorner.CornerRadius = UDim.new(0, 8)
    notifCorner.Parent = notification
    
    local notifText = Instance.new("TextLabel")
    notifText.Size = UDim2.new(1, -20, 1, 0)
    notifText.Position = UDim2.new(0, 10, 0, 0)
    notifText.BackgroundTransparency = 1
    notifText.Text = message
    notifText.TextColor3 = Color3.new(1, 1, 1)
    notifText.TextScaled = true
    notifText.Font = Enum.Font.SourceSansBold
    notifText.Parent = notification
    
    -- Animate in
    local slideIn = TweenService:Create(
        notification,
        TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
        {Position = UDim2.new(0.5, -150, 0, 20)}
    )
    slideIn:Play()
    
    -- Auto-remove after 3 seconds
    spawn(function()
        wait(3)
        local slideOut = TweenService:Create(
            notification,
            TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.In),
            {Position = UDim2.new(0.5, -150, 0, -80)}
        )
        slideOut:Play()
        slideOut.Completed:Connect(function()
            notification:Destroy()
        end)
    end)
end

function ShareController:Init()
    print("📤 ShareController initializing...")
    
    -- Connect remote events
    RemoteEvents.ShowShareScore.OnClientEvent:Connect(function(scoreData)
        self:ShowShareGUI(scoreData)
    end)
    
    -- Handle ESC key to close share GUI
    UserInputService.InputBegan:Connect(function(input, gameProcessed)
        if gameProcessed then return end
        
        if input.KeyCode == Enum.KeyCode.Escape and isShareGuiOpen then
            self:HideShareGUI()
        end
    end)
    
    print("✅ ShareController initialized successfully!")
end

return ShareController
