-- WorldEventController.luau
-- Client-side controller for world event UI, effects, and participation

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local SoundService = game:GetService("SoundService")
local Lighting = game:GetService("Lighting")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterGui = game:GetService("StarterGui")

local RemoteEvents = require(ReplicatedStorage.Shared.modules.RemoteEvents)
local GameConstants = require(ReplicatedStorage.Shared.constants.GameConstants)

local player = Players.LocalPlayer
local WorldEventController = {}

-- Event state
local currentEventTheme = nil
local eventUI = nil
local originalLightingProperties = {}
local eventSounds = {}
local isEventActive = false

-- UI elements
local eventNotificationFrame = nil
local eventInfoFrame = nil
local leaderboardFrame = nil

function WorldEventController:CreateEventUI()
    local playerGui = player:WaitForChild("PlayerGui")
    
    -- Create main event UI container
    local eventScreenGui = Instance.new("ScreenGui")
    eventScreenGui.Name = "WorldEventUI"
    eventScreenGui.ResetOnSpawn = false
    eventScreenGui.Parent = playerGui
    
    -- Event notification frame (appears during events)
    eventNotificationFrame = Instance.new("Frame")
    eventNotificationFrame.Name = "EventNotification"
    eventNotificationFrame.Size = UDim2.new(0, 400, 0, 100)
    eventNotificationFrame.Position = UDim2.new(1, -420, 0, 20)
    eventNotificationFrame.BackgroundColor3 = Color3.new(0.1, 0.1, 0.3)
    eventNotificationFrame.BorderSizePixel = 0
    eventNotificationFrame.Visible = false
    eventNotificationFrame.Parent = eventScreenGui
    
    -- Add corner radius
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 10)
    corner.Parent = eventNotificationFrame
    
    -- Event name label
    local eventNameLabel = Instance.new("TextLabel")
    eventNameLabel.Name = "EventName"
    eventNameLabel.Size = UDim2.new(1, -20, 0.5, 0)
    eventNameLabel.Position = UDim2.new(0, 10, 0, 5)
    eventNameLabel.BackgroundTransparency = 1
    eventNameLabel.Text = "🌟 EVENT ACTIVE"
    eventNameLabel.TextColor3 = Color3.new(1, 1, 0)
    eventNameLabel.TextScaled = true
    eventNameLabel.Font = Enum.Font.SourceSansBold
    eventNameLabel.TextXAlignment = Enum.TextXAlignment.Left
    eventNameLabel.Parent = eventNotificationFrame
    
    -- Event description label
    local eventDescLabel = Instance.new("TextLabel")
    eventDescLabel.Name = "EventDesc"
    eventDescLabel.Size = UDim2.new(1, -20, 0.4, 0)
    eventDescLabel.Position = UDim2.new(0, 10, 0.5, 0)
    eventDescLabel.BackgroundTransparency = 1
    eventDescLabel.Text = "Double coins • Special effects"
    eventDescLabel.TextColor3 = Color3.new(0.8, 0.8, 1)
    eventDescLabel.TextScaled = true
    eventDescLabel.Font = Enum.Font.SourceSans
    eventDescLabel.TextXAlignment = Enum.TextXAlignment.Left
    eventDescLabel.TextWrapped = true
    eventDescLabel.Parent = eventNotificationFrame
    
    -- Event info frame (detailed info when clicking board)
    eventInfoFrame = Instance.new("Frame")
    eventInfoFrame.Name = "EventInfo"
    eventInfoFrame.Size = UDim2.new(0, 500, 0, 400)
    eventInfoFrame.Position = UDim2.new(0.5, -250, 0.5, -200)
    eventInfoFrame.BackgroundColor3 = Color3.new(0.05, 0.05, 0.15)
    eventInfoFrame.BorderSizePixel = 0
    eventInfoFrame.Visible = false
    eventInfoFrame.Parent = eventScreenGui
    
    -- Add corner radius and shadow
    local infoCorner = Instance.new("UICorner")
    infoCorner.CornerRadius = UDim.new(0, 15)
    infoCorner.Parent = eventInfoFrame
    
    -- Close button
    local closeButton = Instance.new("TextButton")
    closeButton.Name = "CloseButton"
    closeButton.Size = UDim2.new(0, 30, 0, 30)
    closeButton.Position = UDim2.new(1, -35, 0, 5)
    closeButton.BackgroundColor3 = Color3.new(0.8, 0.2, 0.2)
    closeButton.Text = "✕"
    closeButton.TextColor3 = Color3.new(1, 1, 1)
    closeButton.TextScaled = true
    closeButton.Font = Enum.Font.SourceSansBold
    closeButton.Parent = eventInfoFrame
    
    closeButton.MouseButton1Click:Connect(function()
        self:HideEventInfo()
    end)
    
    -- Title
    local infoTitle = Instance.new("TextLabel")
    infoTitle.Name = "Title"
    infoTitle.Size = UDim2.new(1, -50, 0, 50)
    infoTitle.Position = UDim2.new(0, 10, 0, 10)
    infoTitle.BackgroundTransparency = 1
    infoTitle.Text = "🌟 WORLD EVENTS"
    infoTitle.TextColor3 = Color3.new(1, 1, 0)
    infoTitle.TextScaled = true
    infoTitle.Font = Enum.Font.SourceSansBold
    infoTitle.TextXAlignment = Enum.TextXAlignment.Left
    infoTitle.Parent = eventInfoFrame
    
    -- Event details container
    local detailsFrame = Instance.new("ScrollingFrame")
    detailsFrame.Name = "Details"
    detailsFrame.Size = UDim2.new(1, -20, 1, -70)
    detailsFrame.Position = UDim2.new(0, 10, 0, 60)
    detailsFrame.BackgroundTransparency = 1
    detailsFrame.ScrollBarThickness = 8
    detailsFrame.Parent = eventInfoFrame
    
    eventUI = {
        screenGui = eventScreenGui,
        notification = eventNotificationFrame,
        info = eventInfoFrame,
        details = detailsFrame
    }
    
    print("🎮 World Event UI created!")
end

function WorldEventController:ShowEventNotification(eventTheme)
    if not eventNotificationFrame then return end
    
    -- Update content
    local nameLabel = eventNotificationFrame:FindFirstChild("EventName")
    local descLabel = eventNotificationFrame:FindFirstChild("EventDesc")
    
    if nameLabel and eventTheme then
        nameLabel.Text = "🔥 " .. eventTheme.name
    end
    
    if descLabel and eventTheme then
        descLabel.Text = eventTheme.description
    end
    
    -- Show with animation
    eventNotificationFrame.Visible = true
    eventNotificationFrame.Position = UDim2.new(1, 0, 0, 20)
    
    local slideIn = TweenService:Create(
        eventNotificationFrame,
        TweenInfo.new(0.5, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
        {Position = UDim2.new(1, -420, 0, 20)}
    )
    
    slideIn:Play()
    
    -- Auto-hide after 10 seconds
    spawn(function()
        wait(10)
        self:HideEventNotification()
    end)
end

function WorldEventController:HideEventNotification()
    if not eventNotificationFrame or not eventNotificationFrame.Visible then return end
    
    local slideOut = TweenService:Create(
        eventNotificationFrame,
        TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
        {Position = UDim2.new(1, 0, 0, 20)}
    )
    
    slideOut:Play()
    slideOut.Completed:Connect(function()
        eventNotificationFrame.Visible = false
    end)
end

function WorldEventController:ShowEventInfo(eventData)
    if not eventInfoFrame then return end
    
    local detailsFrame = eventUI.details
    
    -- Clear existing content
    for _, child in pairs(detailsFrame:GetChildren()) do
        if not child:IsA("UIListLayout") then
            child:Destroy()
        end
    end
    
    -- Add list layout if not exists
    if not detailsFrame:FindFirstChild("UIListLayout") then
        local listLayout = Instance.new("UIListLayout")
        listLayout.SortOrder = Enum.SortOrder.LayoutOrder
        listLayout.Padding = UDim.new(0, 10)
        listLayout.Parent = detailsFrame
    end
    
    -- Current event status
    local statusLabel = Instance.new("TextLabel")
    statusLabel.Size = UDim2.new(1, 0, 0, 60)
    statusLabel.BackgroundTransparency = 1
    statusLabel.TextColor3 = Color3.new(1, 1, 1)
    statusLabel.TextScaled = true
    statusLabel.Font = Enum.Font.SourceSans
    statusLabel.TextWrapped = true
    statusLabel.LayoutOrder = 1
    statusLabel.Parent = detailsFrame
    
    if eventData.isActive and eventData.currentEvent then
        statusLabel.Text = "🔥 ACTIVE: " .. eventData.currentEvent.name .. "\n" .. eventData.currentEvent.description
        statusLabel.TextColor3 = Color3.new(1, 0.8, 0.2)
    else
        local timeUntil = eventData.timeUntilNext
        local hours = math.floor(timeUntil / 3600)
        local minutes = math.floor((timeUntil % 3600) / 60)
        statusLabel.Text = string.format("⏰ Next event in: %d:%02d\nEvents occur every 30 minutes with unique themes!", hours, minutes)
        statusLabel.TextColor3 = Color3.new(0.8, 0.8, 1)
    end
    
    -- Event benefits
    local benefitsLabel = Instance.new("TextLabel")
    benefitsLabel.Size = UDim2.new(1, 0, 0, 80)
    benefitsLabel.BackgroundTransparency = 1
    benefitsLabel.Text = "🎁 EVENT BENEFITS:\n• 2-3x Coin Multipliers\n• Unique Visual Effects\n• Special Cosmetic Rewards\n• Exclusive Leaderboards"
    benefitsLabel.TextColor3 = Color3.new(0.7, 1, 0.7)
    benefitsLabel.TextScaled = true
    benefitsLabel.Font = Enum.Font.SourceSans
    benefitsLabel.TextWrapped = true
    benefitsLabel.TextXAlignment = Enum.TextXAlignment.Left
    benefitsLabel.LayoutOrder = 2
    benefitsLabel.Parent = detailsFrame
    
    -- Leaderboard
    if eventData.leaderboard and #eventData.leaderboard > 0 then
        local leaderboardTitle = Instance.new("TextLabel")
        leaderboardTitle.Size = UDim2.new(1, 0, 0, 40)
        leaderboardTitle.BackgroundTransparency = 1
        leaderboardTitle.Text = "🏆 TOP SCORES"
        leaderboardTitle.TextColor3 = Color3.new(1, 1, 0)
        leaderboardTitle.TextScaled = true
        leaderboardTitle.Font = Enum.Font.SourceSansBold
        leaderboardTitle.LayoutOrder = 3
        leaderboardTitle.Parent = detailsFrame
        
        for i, scoreData in ipairs(eventData.leaderboard) do
            local scoreLabel = Instance.new("TextLabel")
            scoreLabel.Size = UDim2.new(1, 0, 0, 30)
            scoreLabel.BackgroundTransparency = 1
            scoreLabel.Text = string.format("%d. %s - %d points", i, scoreData.playerName, scoreData.score)
            scoreLabel.TextColor3 = i <= 3 and Color3.new(1, 0.8, 0.2) or Color3.new(0.8, 0.8, 1)
            scoreLabel.TextScaled = true
            scoreLabel.Font = Enum.Font.SourceSans
            scoreLabel.TextXAlignment = Enum.TextXAlignment.Left
            scoreLabel.LayoutOrder = 3 + i
            scoreLabel.Parent = detailsFrame
        end
    end
    
    -- Update canvas size
    detailsFrame.CanvasSize = UDim2.new(0, 0, 0, detailsFrame.UIListLayout.AbsoluteContentSize.Y)
    
    -- Show frame
    eventInfoFrame.Visible = true
    eventInfoFrame.Size = UDim2.new(0, 0, 0, 0)
    
    local openTween = TweenService:Create(
        eventInfoFrame,
        TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
        {Size = UDim2.new(0, 500, 0, 400)}
    )
    
    openTween:Play()
end

function WorldEventController:HideEventInfo()
    if not eventInfoFrame or not eventInfoFrame.Visible then return end
    
    local closeTween = TweenService:Create(
        eventInfoFrame,
        TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
        {Size = UDim2.new(0, 0, 0, 0)}
    )
    
    closeTween:Play()
    closeTween.Completed:Connect(function()
        eventInfoFrame.Visible = false
    end)
end

function WorldEventController:ApplyEventEffects(eventTheme)
    if not eventTheme then return end
    
    currentEventTheme = eventTheme
    isEventActive = true
    
    -- Store original lighting properties
    originalLightingProperties = {
        Ambient = Lighting.Ambient,
        Brightness = Lighting.Brightness,
        ColorShift_Bottom = Lighting.ColorShift_Bottom,
        ColorShift_Top = Lighting.ColorShift_Top,
        OutdoorAmbient = Lighting.OutdoorAmbient
    }
    
    -- Apply theme-specific lighting
    if eventTheme.colors then
        local targetProperties = {}
        
        if eventTheme.id == "cosmic_rush" then
            targetProperties.Ambient = Color3.new(0.2, 0.1, 0.4)
            targetProperties.ColorShift_Bottom = eventTheme.colors.primary
            targetProperties.ColorShift_Top = eventTheme.colors.secondary
            targetProperties.OutdoorAmbient = Color3.new(0.3, 0.2, 0.5)
        elseif eventTheme.id == "neon_night" then
            targetProperties.Ambient = Color3.new(0.1, 0.1, 0.2)
            targetProperties.ColorShift_Bottom = eventTheme.colors.primary
            targetProperties.ColorShift_Top = eventTheme.colors.secondary
            targetProperties.Brightness = 0.5
        elseif eventTheme.id == "rainbow_mania" then
            targetProperties.ColorShift_Bottom = eventTheme.colors.primary
            targetProperties.ColorShift_Top = eventTheme.colors.secondary
            targetProperties.Brightness = 2
        elseif eventTheme.id == "storm_surge" then
            targetProperties.Ambient = Color3.new(0.1, 0.1, 0.2)
            targetProperties.ColorShift_Bottom = Color3.new(0.3, 0.3, 0.6)
            targetProperties.OutdoorAmbient = Color3.new(0.2, 0.2, 0.4)
        elseif eventTheme.id == "golden_hour" then
            targetProperties.ColorShift_Bottom = Color3.new(1, 0.8, 0.4)
            targetProperties.ColorShift_Top = Color3.new(1, 0.6, 0.2)
            targetProperties.OutdoorAmbient = Color3.new(0.8, 0.6, 0.3)
            targetProperties.Brightness = 1.5
        elseif eventTheme.id == "ice_crystal" then
            targetProperties.Ambient = Color3.new(0.4, 0.5, 0.6)
            targetProperties.ColorShift_Bottom = Color3.new(0.7, 0.9, 1)
            targetProperties.ColorShift_Top = Color3.new(0.5, 0.8, 1)
            targetProperties.OutdoorAmbient = Color3.new(0.6, 0.8, 1)
        end
        
        -- Tween lighting changes
        for property, value in pairs(targetProperties) do
            if Lighting[property] then
                local tween = TweenService:Create(
                    Lighting,
                    TweenInfo.new(2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
                    {[property] = value}
                )
                tween:Play()
            end
        end
    end
    
    -- Play event music
    self:PlayEventMusic(eventTheme)
    
    -- Show notification
    self:ShowEventNotification(eventTheme)
    
    print("🌟 Applied event effects for: " .. eventTheme.name)
end

function WorldEventController:RemoveEventEffects()
    if not isEventActive then return end
    
    isEventActive = false
    currentEventTheme = nil
    
    -- Restore original lighting
    if originalLightingProperties then
        local restoreTween = TweenService:Create(
            Lighting,
            TweenInfo.new(3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
            originalLightingProperties
        )
        restoreTween:Play()
    end
    
    -- Stop event music
    self:StopEventMusic()
    
    -- Hide notification
    self:HideEventNotification()
    
    print("🌟 Removed event effects")
end

function WorldEventController:PlayEventMusic(eventTheme)
    if not eventTheme or not eventTheme.effects then return end
    
    -- Stop any existing event music
    self:StopEventMusic()
    
    -- Create and play event-themed music
    local musicId = "rbxasset://sounds/electronicpingshort.wav" -- Placeholder
    
    if eventTheme.id == "cosmic_rush" then
        musicId = "rbxasset://sounds/impact_generic_large_water_1.mp3"
    elseif eventTheme.id == "neon_night" then
        musicId = "rbxasset://sounds/pop_mid_up.wav"
    end
    
    local eventMusic = Instance.new("Sound")
    eventMusic.Name = "EventMusic"
    eventMusic.SoundId = musicId
    eventMusic.Volume = 0.3
    eventMusic.Looped = true
    eventMusic.Parent = SoundService
    
    eventSounds.music = eventMusic
    eventMusic:Play()
    
    -- Fade in music
    eventMusic.Volume = 0
    local fadeIn = TweenService:Create(
        eventMusic,
        TweenInfo.new(2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
        {Volume = 0.3}
    )
    fadeIn:Play()
end

function WorldEventController:StopEventMusic()
    if eventSounds.music then
        local fadeOut = TweenService:Create(
            eventSounds.music,
            TweenInfo.new(1, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
            {Volume = 0}
        )
        fadeOut:Play()
        fadeOut.Completed:Connect(function()
            if eventSounds.music then
                eventSounds.music:Destroy()
                eventSounds.music = nil
            end
        end)
    end
end

function WorldEventController:ShowEventAnnouncement(data)
    -- Create countdown announcement
    local announcementGui = Instance.new("ScreenGui")
    announcementGui.Name = "EventAnnouncement"
    announcementGui.Parent = player.PlayerGui
    
    local announcementFrame = Instance.new("Frame")
    announcementFrame.Size = UDim2.new(0, 600, 0, 200)
    announcementFrame.Position = UDim2.new(0.5, -300, 0.5, -100)
    announcementFrame.BackgroundColor3 = Color3.new(0.1, 0.1, 0.3)
    announcementFrame.BorderSizePixel = 0
    announcementFrame.Parent = announcementGui
    
    -- Corner radius
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 15)
    corner.Parent = announcementFrame
    
    -- Title
    local titleLabel = Instance.new("TextLabel")
    titleLabel.Size = UDim2.new(1, -20, 0, 50)
    titleLabel.Position = UDim2.new(0, 10, 0, 10)
    titleLabel.BackgroundTransparency = 1
    titleLabel.Text = data.message or "🌟 WORLD EVENT STARTING!"
    titleLabel.TextColor3 = Color3.new(1, 1, 0)
    titleLabel.TextScaled = true
    titleLabel.Font = Enum.Font.SourceSansBold
    titleLabel.Parent = announcementFrame
    
    -- Event name
    local eventLabel = Instance.new("TextLabel")
    eventLabel.Size = UDim2.new(1, -20, 0, 40)
    eventLabel.Position = UDim2.new(0, 10, 0, 60)
    eventLabel.BackgroundTransparency = 1
    eventLabel.Text = data.eventName or "Special Event"
    eventLabel.TextColor3 = Color3.new(0.8, 1, 0.8)
    eventLabel.TextScaled = true
    eventLabel.Font = Enum.Font.SourceSans
    eventLabel.Parent = announcementFrame
    
    -- Description
    local descLabel = Instance.new("TextLabel")
    descLabel.Size = UDim2.new(1, -20, 0, 60)
    descLabel.Position = UDim2.new(0, 10, 0, 100)
    descLabel.BackgroundTransparency = 1
    descLabel.Text = data.description or "Get ready for unique visuals and double rewards!"
    descLabel.TextColor3 = Color3.new(0.7, 0.7, 1)
    descLabel.TextScaled = true
    descLabel.Font = Enum.Font.SourceSans
    descLabel.TextWrapped = true
    descLabel.Parent = announcementFrame
    
    -- Countdown
    local countdownLabel = Instance.new("TextLabel")
    countdownLabel.Size = UDim2.new(1, -20, 0, 30)
    countdownLabel.Position = UDim2.new(0, 10, 1, -40)
    countdownLabel.BackgroundTransparency = 1
    countdownLabel.Text = "Starting in: " .. (data.timeUntilStart or 60) .. " seconds"
    countdownLabel.TextColor3 = Color3.new(1, 0.8, 0.2)
    countdownLabel.TextScaled = true
    countdownLabel.Font = Enum.Font.SourceSansBold
    countdownLabel.Parent = announcementFrame
    
    -- Animate entrance
    announcementFrame.Size = UDim2.new(0, 0, 0, 0)
    local enterTween = TweenService:Create(
        announcementFrame,
        TweenInfo.new(0.5, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
        {Size = UDim2.new(0, 600, 0, 200)}
    )
    enterTween:Play()
    
    -- Auto-remove after countdown
    spawn(function()
        local timeLeft = data.timeUntilStart or 60
        for i = timeLeft, 1, -1 do
            countdownLabel.Text = "Starting in: " .. i .. " seconds"
            wait(1)
        end
        
        -- Exit animation
        local exitTween = TweenService:Create(
            announcementFrame,
            TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
            {Size = UDim2.new(0, 0, 0, 0)}
        )
        exitTween:Play()
        exitTween.Completed:Connect(function()
            announcementGui:Destroy()
        end)
    end)
end

function WorldEventController:GetCurrentEventTheme()
    return currentEventTheme
end

function WorldEventController:IsEventActive()
    return isEventActive
end

function WorldEventController:Init()
    print("🌟 WorldEventController initializing...")
    
    -- Create UI
    self:CreateEventUI()
    
    -- Setup event handlers
    RemoteEvents.WorldEventStarted.OnClientEvent:Connect(function(eventTheme)
        self:ApplyEventEffects(eventTheme)
    end)
    
    RemoteEvents.WorldEventEnded.OnClientEvent:Connect(function(data)
        self:RemoveEventEffects()
        
        -- Show results if player participated
        if data.playerRank then
            self:ShowEventResults(data)
        end
    end)
    
    RemoteEvents.ShowWorldEventInfo.OnClientEvent:Connect(function(eventData)
        self:ShowEventInfo(eventData)
    end)
    
    RemoteEvents.ShowEventAnnouncement.OnClientEvent:Connect(function(data)
        self:ShowEventAnnouncement(data)
    end)
    
    RemoteEvents.ShowEventReward.OnClientEvent:Connect(function(rewardData)
        self:ShowEventReward(rewardData)
    end)
    
    print("✅ WorldEventController initialized successfully!")
end

function WorldEventController:ShowEventResults(data)
    -- Create results UI (implementation similar to existing UI patterns)
    print("🏁 Event ended! Your rank: " .. (data.playerRank or "Unranked"))
end

function WorldEventController:ShowEventReward(rewardData)
    -- Create reward notification UI
    print("🎁 Event reward: " .. (rewardData.coins or 0) .. " coins, " .. (rewardData.xp or 0) .. " XP")
end

return WorldEventController
