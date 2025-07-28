-- ContentController.luau
-- Client-side content management for dynamic updates

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local SoundService = game:GetService("SoundService")

local RemoteEvents = ReplicatedStorage:WaitForChild("RemoteEvents")
local Player = Players.LocalPlayer
local PlayerGui = Player:WaitForChild("PlayerGui")

local ContentController = {}

-- Local content cache
local activeContent = {
    events = {},
    trails = {},
    pets = {},
    cosmetics = {},
    seasonalItems = {},
    leaderboardConfig = {}
}

-- UI Elements
local contentNotifications = {}
local eventBanners = {}

function ContentController:Init()
    -- Initialize content controller
    self:SetupEventConnections()
    self:RequestContentSync()
    self:CreateContentUI()
    
    print("📦 ContentController initialized - Ready for dynamic content")
end

function ContentController:SetupEventConnections()
    -- Handle content updates from server
    RemoteEvents.ContentUpdate.OnClientEvent:Connect(function(updateType, data)
        self:HandleContentUpdate(updateType, data)
    end)
end

function ContentController:RequestContentSync()
    -- Request full content sync from server
    local success, content = pcall(function()
        return RemoteEvents.GetActiveContent:InvokeServer()
    end)
    
    if success and content then
        activeContent = content
        self:UpdateContentDisplays()
    end
end

function ContentController:HandleContentUpdate(updateType, data)
    if updateType == "full_sync" then
        activeContent = data
        self:UpdateContentDisplays()
        
    elseif updateType == "event_added" then
        activeContent.events[data.id] = data
        self:ShowEventBanner(data)
        self:ShowContentNotification("New Event Available!", data.name .. " - " .. data.description, data.icon)
        
    elseif updateType == "trail_added" then
        activeContent.trails[data.id] = data
        self:ShowContentNotification("New Trail Available!", data.name .. " - " .. data.description, data.icon)
        
    elseif updateType == "pet_added" then
        activeContent.pets[data.id] = data
        self:ShowContentNotification("New Pet Available!", data.name .. " - " .. data.description, data.icon)
        
    elseif updateType == "cosmetic_added" then
        activeContent.cosmetics[data.id] = data
        self:ShowContentNotification("New Cosmetic Available!", data.name .. " - " .. data.description, data.icon)
        
    elseif updateType == "seasonal_added" then
        activeContent.seasonalItems[data.id] = data
        self:ShowSeasonalUpdate(data)
        
    elseif updateType == "event_expired" then
        if activeContent.events[data.id] then
            activeContent.events[data.id].enabled = false
        end
        self:HideEventBanner(data.id)
        self:ShowContentNotification("Event Ended", data.name .. " has concluded. Thanks for participating!", "⏰")
        
    elseif updateType == "seasonal_expired" then
        if activeContent.seasonalItems[data.id] then
            activeContent.seasonalItems[data.id].enabled = false
        end
        self:ShowContentNotification("Season Changed", data.name .. " has ended. See you next time!", "🍂")
        
    elseif updateType == "content_swapped" then
        self:HandleContentSwap(data)
        
    elseif updateType == "notification" then
        self:ShowContentNotification("Game Update", data.message, "📢")
        
    end
    
    self:UpdateContentDisplays()
end

function ContentController:CreateContentUI()
    -- Create UI elements for content display
    self:CreateEventBannerContainer()
    self:CreateContentNotificationSystem()
end

function ContentController:CreateEventBannerContainer()
    -- Create container for event banners
    local bannerContainer = Instance.new("Frame")
    bannerContainer.Name = "EventBanners"
    bannerContainer.Size = UDim2.new(1, 0, 0, 100)
    bannerContainer.Position = UDim2.new(0, 0, 0, 0)
    bannerContainer.BackgroundTransparency = 1
    bannerContainer.Parent = PlayerGui:FindFirstChild("ScreenGui") or PlayerGui
    
    local listLayout = Instance.new("UIListLayout")
    listLayout.SortOrder = Enum.SortOrder.LayoutOrder
    listLayout.FillDirection = Enum.FillDirection.Vertical
    listLayout.Padding = UDim.new(0, 5)
    listLayout.Parent = bannerContainer
end

function ContentController:CreateContentNotificationSystem()
    -- Create notification system for content updates
    -- This would integrate with existing notification system
    print("📦 Content notification system ready")
end

function ContentController:ShowEventBanner(eventData)
    -- Display event banner at top of screen
    local bannerContainer = PlayerGui:FindFirstChild("ScreenGui"):FindFirstChild("EventBanners")
    if not bannerContainer then return end
    
    local banner = Instance.new("Frame")
    banner.Name = "EventBanner_" .. eventData.id
    banner.Size = UDim2.new(1, -20, 0, 80)
    banner.Position = UDim2.new(0, 10, 0, 0)
    banner.BackgroundColor3 = eventData.bannerColor or Color3.fromRGB(255, 215, 0)
    banner.BorderSizePixel = 0
    banner.Parent = bannerContainer
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 8)
    corner.Parent = banner
    
    -- Event icon
    local icon = Instance.new("TextLabel")
    icon.Name = "Icon"
    icon.Size = UDim2.new(0, 60, 0, 60)
    icon.Position = UDim2.new(0, 10, 0, 10)
    icon.BackgroundTransparency = 1
    icon.Text = eventData.icon
    icon.TextColor3 = Color3.fromRGB(0, 0, 0)
    icon.TextScaled = true
    icon.Font = Enum.Font.Gotham
    icon.Parent = banner
    
    -- Event title
    local title = Instance.new("TextLabel")
    title.Name = "Title"
    title.Size = UDim2.new(1, -180, 0, 30)
    title.Position = UDim2.new(0, 80, 0, 10)
    title.BackgroundTransparency = 1
    title.Text = eventData.name
    title.TextColor3 = Color3.fromRGB(0, 0, 0)
    title.TextScaled = true
    title.Font = Enum.Font.GothamBold
    title.TextXAlignment = Enum.TextXAlignment.Left
    title.Parent = banner
    
    -- Event description
    local description = Instance.new("TextLabel")
    description.Name = "Description"
    description.Size = UDim2.new(1, -180, 0, 20)
    description.Position = UDim2.new(0, 80, 0, 40)
    description.BackgroundTransparency = 1
    description.Text = eventData.description
    description.TextColor3 = Color3.fromRGB(50, 50, 50)
    description.TextScaled = true
    description.Font = Enum.Font.Gotham
    description.TextXAlignment = Enum.TextXAlignment.Left
    description.Parent = banner
    
    -- Time remaining
    local timeRemaining = Instance.new("TextLabel")
    timeRemaining.Name = "TimeRemaining"
    timeRemaining.Size = UDim2.new(0, 100, 0, 25)
    timeRemaining.Position = UDim2.new(1, -110, 0, 10)
    timeRemaining.BackgroundColor3 = Color3.fromRGB(255, 100, 100)
    timeRemaining.BorderSizePixel = 0
    timeRemaining.Text = self:FormatTimeRemaining(eventData.endDate - os.time())
    timeRemaining.TextColor3 = Color3.fromRGB(255, 255, 255)
    timeRemaining.TextScaled = true
    timeRemaining.Font = Enum.Font.GothamBold
    timeRemaining.Parent = banner
    
    local timeCorner = Instance.new("UICorner")
    timeCorner.CornerRadius = UDim.new(0, 4)
    timeCorner.Parent = timeRemaining
    
    -- Animate banner entrance
    banner.Position = UDim2.new(0, -banner.AbsoluteSize.X, 0, 0)
    local showTween = TweenService:Create(
        banner,
        TweenInfo.new(0.5, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
        {Position = UDim2.new(0, 10, 0, 0)}
    )
    showTween:Play()
    
    -- Store banner reference
    eventBanners[eventData.id] = banner
    
    -- Update timer
    spawn(function()
        while banner.Parent and eventData.enabled do
            wait(1)
            local remaining = eventData.endDate - os.time()
            if remaining > 0 then
                timeRemaining.Text = self:FormatTimeRemaining(remaining)
            else
                break
            end
        end
    end)
end

function ContentController:HideEventBanner(eventId)
    -- Hide and remove event banner
    local banner = eventBanners[eventId]
    if banner then
        local hideTween = TweenService:Create(
            banner,
            TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
            {Position = UDim2.new(0, -banner.AbsoluteSize.X, 0, 0)}
        )
        hideTween:Play()
        
        hideTween.Completed:Connect(function()
            banner:Destroy()
            eventBanners[eventId] = nil
        end)
    end
end

function ContentController:ShowSeasonalUpdate(seasonalData)
    -- Display seasonal content update
    self:ShowContentNotification(
        "🌟 " .. seasonalData.name .. " is Here!",
        "New seasonal content available for a limited time!",
        seasonalData.icon
    )
    
    -- Apply seasonal decorations if any
    if seasonalData.decorations then
        self:ApplySeasonalDecorations(seasonalData.decorations)
    end
    
    -- Change music if specified
    if seasonalData.music and seasonalData.music ~= "" then
        self:PlaySeasonalMusic(seasonalData.music)
    end
end

function ContentController:ShowContentNotification(title, message, icon)
    -- Show content update notification
    local notification = Instance.new("Frame")
    notification.Name = "ContentNotification"
    notification.Size = UDim2.new(0, 300, 0, 80)
    notification.Position = UDim2.new(1, 0, 0, 200 + (#contentNotifications * 90))
    notification.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
    notification.BorderSizePixel = 0
    notification.Parent = PlayerGui:FindFirstChild("ScreenGui") or PlayerGui
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 8)
    corner.Parent = notification
    
    -- Notification icon
    local notifIcon = Instance.new("TextLabel")
    notifIcon.Name = "Icon"
    notifIcon.Size = UDim2.new(0, 50, 0, 50)
    notifIcon.Position = UDim2.new(0, 10, 0, 15)
    notifIcon.BackgroundTransparency = 1
    notifIcon.Text = icon or "📦"
    notifIcon.TextColor3 = Color3.fromRGB(255, 255, 255)
    notifIcon.TextScaled = true
    notifIcon.Font = Enum.Font.Gotham
    notifIcon.Parent = notification
    
    -- Notification title
    local notifTitle = Instance.new("TextLabel")
    notifTitle.Name = "Title"
    notifTitle.Size = UDim2.new(1, -70, 0, 25)
    notifTitle.Position = UDim2.new(0, 65, 0, 10)
    notifTitle.BackgroundTransparency = 1
    notifTitle.Text = title
    notifTitle.TextColor3 = Color3.fromRGB(255, 255, 255)
    notifTitle.TextScaled = true
    notifTitle.Font = Enum.Font.GothamBold
    notifTitle.TextXAlignment = Enum.TextXAlignment.Left
    notifTitle.Parent = notification
    
    -- Notification message
    local notifMessage = Instance.new("TextLabel")
    notifMessage.Name = "Message"
    notifMessage.Size = UDim2.new(1, -70, 0, 35)
    notifMessage.Position = UDim2.new(0, 65, 0, 35)
    notifMessage.BackgroundTransparency = 1
    notifMessage.Text = message
    notifMessage.TextColor3 = Color3.fromRGB(200, 200, 200)
    notifMessage.TextScaled = true
    notifMessage.Font = Enum.Font.Gotham
    notifMessage.TextXAlignment = Enum.TextXAlignment.Left
    notifMessage.TextWrapped = true
    notifMessage.Parent = notification
    
    -- Add to tracking
    table.insert(contentNotifications, notification)
    
    -- Animate in
    local slideInTween = TweenService:Create(
        notification,
        TweenInfo.new(0.5, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
        {Position = UDim2.new(1, -310, 0, 200 + ((#contentNotifications - 1) * 90))}
    )
    slideInTween:Play()
    
    -- Auto-remove after 6 seconds
    wait(6)
    
    local slideOutTween = TweenService:Create(
        notification,
        TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
        {Position = UDim2.new(1, 0, 0, 200 + ((#contentNotifications - 1) * 90))}
    )
    slideOutTween:Play()
    
    slideOutTween.Completed:Connect(function()
        notification:Destroy()
        
        -- Remove from tracking
        for i, notif in pairs(contentNotifications) do
            if notif == notification then
                table.remove(contentNotifications, i)
                break
            end
        end
        
        -- Reposition remaining notifications
        for i, notif in pairs(contentNotifications) do
            local repositionTween = TweenService:Create(
                notif,
                TweenInfo.new(0.2, Enum.EasingStyle.Quad),
                {Position = UDim2.new(1, -310, 0, 200 + ((i - 1) * 90))}
            )
            repositionTween:Play()
        end
    end)
end

function ContentController:HandleContentSwap(swapData)
    -- Handle content hot-swapping
    local contentType = swapData.type
    local oldId = swapData.oldId
    local newContent = swapData.newContent
    
    -- Remove old content from cache
    if activeContent[contentType] and activeContent[contentType][oldId] then
        activeContent[contentType][oldId] = nil
    end
    
    -- Add new content
    if not activeContent[contentType] then
        activeContent[contentType] = {}
    end
    activeContent[contentType][newContent.id] = newContent
    
    -- Show notification
    self:ShowContentNotification(
        "Content Updated!",
        "New " .. contentType:sub(1, -2) .. " available: " .. newContent.name,
        newContent.icon or "🔄"
    )
end

function ContentController:ApplySeasonalDecorations(decorations)
    -- Apply seasonal decorations to the game world
    for _, decoration in pairs(decorations) do
        -- This would integrate with your world decoration system
        print("🎨 Applying seasonal decoration: " .. decoration)
    end
end

function ContentController:PlaySeasonalMusic(musicFile)
    -- Play seasonal background music
    local sound = Instance.new("Sound")
    sound.SoundId = "rbxasset://sounds/" .. musicFile
    sound.Volume = 0.3
    sound.Looped = true
    sound.Parent = SoundService
    sound:Play()
    
    print("🎵 Playing seasonal music: " .. musicFile)
end

function ContentController:FormatTimeRemaining(seconds)
    -- Format time remaining for display
    if seconds <= 0 then
        return "Ended"
    end
    
    local days = math.floor(seconds / 86400)
    local hours = math.floor((seconds % 86400) / 3600)
    local minutes = math.floor((seconds % 3600) / 60)
    
    if days > 0 then
        return string.format("%dd %dh", days, hours)
    elseif hours > 0 then
        return string.format("%dh %dm", hours, minutes)
    else
        return string.format("%dm", minutes)
    end
end

function ContentController:UpdateContentDisplays()
    -- Update all content-related UI displays
    -- This would refresh shop items, event displays, etc.
    print("📦 Content displays updated")
end

function ContentController:GetActiveContent(contentType)
    -- Get active content for UI systems
    if contentType then
        return activeContent[contentType] or {}
    else
        return activeContent
    end
end

function ContentController:IsContentAvailable(contentType, contentId)
    -- Check if specific content is available and enabled
    return activeContent[contentType] and 
           activeContent[contentType][contentId] and 
           activeContent[contentType][contentId].enabled
end

return ContentController
