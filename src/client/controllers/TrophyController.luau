-- TrophyController.luau
-- Client-side trophy hall UI and interaction management

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local SoundService = game:GetService("SoundService")
local UserInputService = game:GetService("UserInputService")
local StarterGui = game:GetService("StarterGui")

local RemoteEvents = require(game.ReplicatedStorage.Shared.modules.RemoteEvents)

local TrophyController = {}
local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- UI State
local trophyGui = nil
local currentTrophyData = nil
local isHallOpen = false

-- Sound effects
local sounds = {
    unlock_bronze = "rbxasset://sounds/electronicpingshort.wav",
    unlock_silver = "rbxasset://sounds/victory.wav", 
    unlock_gold = "rbxasset://sounds/snap.wav",
    unlock_diamond = "rbxasset://sounds/chime.wav",
    ui_open = "rbxasset://sounds/button-09.wav",
    ui_close = "rbxasset://sounds/button-10.wav",
    hover = "rbxasset://sounds/button-hover.wav"
}

function TrophyController:Init()
    print("🏆 TrophyController: Initializing...")
    
    -- Set up remote event connections
    self:_setupRemoteEvents()
    
    -- Set up UI
    self:_createTrophyUI()
    
    -- Set up input handling
    self:_setupInputHandling()
    
    -- Request initial trophy data
    RemoteEvents.RequestTrophyData:FireServer()
    
    print("✅ TrophyController: Initialized successfully!")
end

function TrophyController:_setupRemoteEvents()
    RemoteEvents.TrophyUnlocked.OnClientEvent:Connect(function(data)
        self:_onTrophyUnlocked(data)
    end)
    
    RemoteEvents.TrophyDataUpdate.OnClientEvent:Connect(function(trophyData)
        self:_updateTrophyData(trophyData)
    end)
end

function TrophyController:_createTrophyUI()
    -- Create main trophy hall GUI
    trophyGui = Instance.new("ScreenGui")
    trophyGui.Name = "TrophyHallGui"
    trophyGui.ResetOnSpawn = false
    trophyGui.DisplayOrder = 10
    trophyGui.Parent = playerGui
    
    -- Create main frame
    local mainFrame = Instance.new("Frame")
    mainFrame.Name = "MainFrame"
    mainFrame.Size = UDim2.new(0.9, 0, 0.85, 0)
    mainFrame.Position = UDim2.new(0.05, 0, 0.075, 0)
    mainFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
    mainFrame.BorderSizePixel = 0
    mainFrame.Visible = false
    mainFrame.Parent = trophyGui
    
    -- Add corner rounding
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 15)
    corner.Parent = mainFrame
    
    -- Add gradient background
    local gradient = Instance.new("UIGradient")
    gradient.Color = ColorSequence.new{
        ColorSequenceKeypoint.new(0, Color3.fromRGB(40, 40, 50)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(20, 20, 30))
    }
    gradient.Rotation = 45
    gradient.Parent = mainFrame
    
    -- Create header
    self:_createTrophyHeader(mainFrame)
    
    -- Create trophy categories tabs
    self:_createCategoryTabs(mainFrame)
    
    -- Create trophy display area
    self:_createTrophyDisplay(mainFrame)
    
    -- Create close button
    self:_createCloseButton(mainFrame)
    
    -- Create floating trophy notification frame
    self:_createTrophyNotification()
    
    -- Create trophy hall button in main UI
    self:_createTrophyHallButton()
end

function TrophyController:_createTrophyHeader(parent)
    local header = Instance.new("Frame")
    header.Name = "Header"
    header.Size = UDim2.new(1, 0, 0.12, 0)
    header.Position = UDim2.new(0, 0, 0, 0)
    header.BackgroundTransparency = 1
    header.Parent = parent
    
    local titleLabel = Instance.new("TextLabel")
    titleLabel.Name = "Title"
    titleLabel.Size = UDim2.new(0.8, 0, 1, 0)
    titleLabel.Position = UDim2.new(0.1, 0, 0, 0)
    titleLabel.BackgroundTransparency = 1
    titleLabel.Text = "🏆 TROPHY HALL 🏆"
    titleLabel.TextColor3 = Color3.fromRGB(255, 215, 0)
    titleLabel.TextScaled = true
    titleLabel.Font = Enum.Font.SourceSansBold
    titleLabel.TextStrokeTransparency = 0
    titleLabel.TextStrokeColor3 = Color3.new(0, 0, 0)
    titleLabel.Parent = header
    
    local subtitleLabel = Instance.new("TextLabel")
    subtitleLabel.Name = "Subtitle"
    subtitleLabel.Size = UDim2.new(0.6, 0, 0.4, 0)
    subtitleLabel.Position = UDim2.new(0.2, 0, 0.6, 0)
    subtitleLabel.BackgroundTransparency = 1
    subtitleLabel.Text = "Showcase your greatest achievements"
    subtitleLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
    subtitleLabel.TextScaled = true
    subtitleLabel.Font = Enum.Font.SourceSans
    subtitleLabel.Parent = header
end

function TrophyController:_createCategoryTabs(parent)
    local tabFrame = Instance.new("Frame")
    tabFrame.Name = "CategoryTabs"
    tabFrame.Size = UDim2.new(1, 0, 0.08, 0)
    tabFrame.Position = UDim2.new(0, 0, 0.12, 0)
    tabFrame.BackgroundTransparency = 1
    tabFrame.Parent = parent
    
    local tabLayout = Instance.new("UIListLayout")
    tabLayout.FillDirection = Enum.FillDirection.Horizontal
    tabLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
    tabLayout.SortOrder = Enum.SortOrder.LayoutOrder
    tabLayout.Padding = UDim.new(0, 10)
    tabLayout.Parent = tabFrame
    
    local categories = {"All", "Performance", "Dedication", "Racing", "Collection", "Skill", "Social"}
    
    for i, category in ipairs(categories) do
        local tab = self:_createCategoryTab(category, i == 1) -- First tab is selected by default
        tab.LayoutOrder = i
        tab.Parent = tabFrame
    end
end

function TrophyController:_createCategoryTab(categoryName, isSelected)
    local tab = Instance.new("TextButton")
    tab.Name = categoryName .. "Tab"
    tab.Size = UDim2.new(0, 120, 1, 0)
    tab.BackgroundColor3 = isSelected and Color3.fromRGB(255, 215, 0) or Color3.fromRGB(60, 60, 70)
    tab.BorderSizePixel = 0
    tab.Text = categoryName:upper()
    tab.TextColor3 = isSelected and Color3.fromRGB(0, 0, 0) or Color3.fromRGB(255, 255, 255)
    tab.TextScaled = true
    tab.Font = Enum.Font.SourceSansBold
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 8)
    corner.Parent = tab
    
    -- Tab selection logic
    tab.MouseButton1Click:Connect(function()
        self:_selectCategory(categoryName)
        self:_playSound("hover")
    end)
    
    -- Hover effect
    tab.MouseEnter:Connect(function()
        if tab.BackgroundColor3 ~= Color3.fromRGB(255, 215, 0) then
            TweenService:Create(tab, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(80, 80, 90)}):Play()
        end
    end)
    
    tab.MouseLeave:Connect(function()
        if tab.BackgroundColor3 ~= Color3.fromRGB(255, 215, 0) then
            TweenService:Create(tab, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(60, 60, 70)}):Play()
        end
    end)
    
    return tab
end

function TrophyController:_createTrophyDisplay(parent)
    local displayFrame = Instance.new("Frame")
    displayFrame.Name = "TrophyDisplay"
    displayFrame.Size = UDim2.new(1, -20, 0.75, 0)
    displayFrame.Position = UDim2.new(0, 10, 0.2, 0)
    displayFrame.BackgroundColor3 = Color3.fromRGB(25, 25, 35)
    displayFrame.BorderSizePixel = 0
    displayFrame.Parent = parent
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 10)
    corner.Parent = displayFrame
    
    -- Create scrolling frame for trophies
    local scrollFrame = Instance.new("ScrollingFrame")
    scrollFrame.Name = "TrophyScroll"
    scrollFrame.Size = UDim2.new(1, -20, 1, -20)
    scrollFrame.Position = UDim2.new(0, 10, 0, 10)
    scrollFrame.BackgroundTransparency = 1
    scrollFrame.BorderSizePixel = 0
    scrollFrame.ScrollBarThickness = 6
    scrollFrame.ScrollBarImageColor3 = Color3.fromRGB(255, 215, 0)
    scrollFrame.Parent = displayFrame
    
    -- Create grid layout for trophies
    local gridLayout = Instance.new("UIGridLayout")
    gridLayout.CellSize = UDim2.new(0, 180, 0, 220)
    gridLayout.CellPadding = UDim2.new(0, 15, 0, 15)
    gridLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
    gridLayout.SortOrder = Enum.SortOrder.LayoutOrder
    gridLayout.Parent = scrollFrame
    
    return scrollFrame
end

function TrophyController:_createCloseButton(parent)
    local closeButton = Instance.new("TextButton")
    closeButton.Name = "CloseButton"
    closeButton.Size = UDim2.new(0, 40, 0, 40)
    closeButton.Position = UDim2.new(1, -50, 0, 10)
    closeButton.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
    closeButton.BorderSizePixel = 0
    closeButton.Text = "✕"
    closeButton.TextColor3 = Color3.new(1, 1, 1)
    closeButton.TextScaled = true
    closeButton.Font = Enum.Font.SourceSansBold
    closeButton.Parent = parent
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 20)
    corner.Parent = closeButton
    
    closeButton.MouseButton1Click:Connect(function()
        self:_closeTrophyHall()
    end)
    
    -- Hover effect
    closeButton.MouseEnter:Connect(function()
        TweenService:Create(closeButton, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(255, 70, 70)}):Play()
    end)
    
    closeButton.MouseLeave:Connect(function()
        TweenService:Create(closeButton, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(200, 50, 50)}):Play()
    end)
end

function TrophyController:_createTrophyNotification()
    local notificationFrame = Instance.new("Frame")
    notificationFrame.Name = "TrophyNotification"
    notificationFrame.Size = UDim2.new(0, 400, 0, 120)
    notificationFrame.Position = UDim2.new(0.5, -200, 0, -130) -- Start off-screen
    notificationFrame.BackgroundColor3 = Color3.fromRGB(40, 40, 50)
    notificationFrame.BorderSizePixel = 0
    notificationFrame.Parent = trophyGui
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 15)
    corner.Parent = notificationFrame
    
    local gradient = Instance.new("UIGradient")
    gradient.Color = ColorSequence.new{
        ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 215, 0)),
        ColorSequenceKeypoint.new(0.5, Color3.fromRGB(40, 40, 50)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 215, 0))
    }
    gradient.Rotation = 90
    gradient.Parent = notificationFrame
    
    -- Trophy icon
    local trophyIcon = Instance.new("TextLabel")
    trophyIcon.Name = "TrophyIcon"
    trophyIcon.Size = UDim2.new(0, 60, 0, 60)
    trophyIcon.Position = UDim2.new(0, 15, 0.5, -30)
    trophyIcon.BackgroundTransparency = 1
    trophyIcon.Text = "🏆"
    trophyIcon.TextColor3 = Color3.fromRGB(255, 215, 0)
    trophyIcon.TextScaled = true
    trophyIcon.Font = Enum.Font.SourceSansBold
    trophyIcon.Parent = notificationFrame
    
    -- Title label
    local titleLabel = Instance.new("TextLabel")
    titleLabel.Name = "Title"
    titleLabel.Size = UDim2.new(0, 300, 0, 40)
    titleLabel.Position = UDim2.new(0, 90, 0, 15)
    titleLabel.BackgroundTransparency = 1
    titleLabel.Text = "TROPHY UNLOCKED!"
    titleLabel.TextColor3 = Color3.fromRGB(255, 215, 0)
    titleLabel.TextScaled = true
    titleLabel.Font = Enum.Font.SourceSansBold
    titleLabel.TextStrokeTransparency = 0
    titleLabel.TextStrokeColor3 = Color3.new(0, 0, 0)
    titleLabel.Parent = notificationFrame
    
    -- Description label
    local descLabel = Instance.new("TextLabel")
    descLabel.Name = "Description"
    descLabel.Size = UDim2.new(0, 300, 0, 30)
    descLabel.Position = UDim2.new(0, 90, 0, 55)
    descLabel.BackgroundTransparency = 1
    descLabel.Text = ""
    descLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
    descLabel.TextScaled = true
    descLabel.Font = Enum.Font.SourceSans
    descLabel.Parent = notificationFrame
    
    -- Rarity label
    local rarityLabel = Instance.new("TextLabel")
    rarityLabel.Name = "Rarity"
    rarityLabel.Size = UDim2.new(0, 300, 0, 25)
    rarityLabel.Position = UDim2.new(0, 90, 0, 85)
    rarityLabel.BackgroundTransparency = 1
    rarityLabel.Text = ""
    rarityLabel.TextColor3 = Color3.fromRGB(255, 215, 0)
    rarityLabel.TextScaled = true
    rarityLabel.Font = Enum.Font.SourceSansItalic
    rarityLabel.Parent = notificationFrame
end

function TrophyController:_createTrophyHallButton()
    -- Create trophy hall access button in the main UI
    local mainGui = playerGui:WaitForChild("MainGui", 5)
    if not mainGui then return end
    
    local trophyButton = Instance.new("TextButton")
    trophyButton.Name = "TrophyHallButton"
    trophyButton.Size = UDim2.new(0, 120, 0, 40)
    trophyButton.Position = UDim2.new(0, 10, 0, 120) -- Position below other UI elements
    trophyButton.BackgroundColor3 = Color3.fromRGB(255, 215, 0)
    trophyButton.BorderSizePixel = 0
    trophyButton.Text = "🏆 TROPHIES"
    trophyButton.TextColor3 = Color3.new(0, 0, 0)
    trophyButton.TextScaled = true
    trophyButton.Font = Enum.Font.SourceSansBold
    trophyButton.Parent = mainGui
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 8)
    corner.Parent = trophyButton
    
    trophyButton.MouseButton1Click:Connect(function()
        self:_openTrophyHall()
    end)
    
    -- Hover effect
    trophyButton.MouseEnter:Connect(function()
        TweenService:Create(trophyButton, TweenInfo.new(0.2), {
            BackgroundColor3 = Color3.fromRGB(255, 235, 50),
            Size = UDim2.new(0, 125, 0, 42)
        }):Play()
    end)
    
    trophyButton.MouseLeave:Connect(function()
        TweenService:Create(trophyButton, TweenInfo.new(0.2), {
            BackgroundColor3 = Color3.fromRGB(255, 215, 0),
            Size = UDim2.new(0, 120, 0, 40)
        }):Play()
    end)
end

function TrophyController:_setupInputHandling()
    UserInputService.InputBegan:Connect(function(input, gameProcessed)
        if gameProcessed then return end
        
        if input.KeyCode == Enum.KeyCode.T and UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) then
            if isHallOpen then
                self:_closeTrophyHall()
            else
                self:_openTrophyHall()
            end
        end
    end)
end

function TrophyController:_onTrophyUnlocked(data)
    if data.effect == "unlock" and data.trophy then
        self:_showTrophyNotification(data.trophy, data.message)
        self:_playSound("unlock_" .. data.trophy.rarity:lower())
    elseif data.effect == "teleport" then
        self:_showSimpleNotification(data.message)
        self:_playSound("ui_open")
    end
end

function TrophyController:_showTrophyNotification(trophy, message)
    local notification = trophyGui:FindFirstChild("TrophyNotification")
    if not notification then return end
    
    -- Update notification content
    notification.Title.Text = trophy.name
    notification.Description.Text = trophy.description
    notification.Rarity.Text = trophy.rarity:upper() .. " TROPHY"
    notification.Rarity.TextColor3 = trophy.color
    notification.TrophyIcon.TextColor3 = trophy.color
    
    -- Animate in
    local tweenIn = TweenService:Create(
        notification,
        TweenInfo.new(0.5, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
        {Position = UDim2.new(0.5, -200, 0, 20)}
    )
    
    -- Animate out after delay
    local tweenOut = TweenService:Create(
        notification,
        TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.In),
        {Position = UDim2.new(0.5, -200, 0, -130)}
    )
    
    tweenIn:Play()
    
    spawn(function()
        wait(4) -- Show for 4 seconds
        tweenOut:Play()
    end)
end

function TrophyController:_showSimpleNotification(message)
    -- Show a simple text notification
    StarterGui:SetCore("ChatMakeSystemMessage", {
        Text = message;
        Color = Color3.fromRGB(255, 215, 0);
        Font = Enum.Font.SourceSansBold;
        FontSize = Enum.FontSize.Size18;
    })
end

function TrophyController:_updateTrophyData(trophyData)
    currentTrophyData = trophyData
    
    if isHallOpen then
        self:_refreshTrophyDisplay()
    end
end

function TrophyController:_openTrophyHall()
    if isHallOpen then return end
    
    isHallOpen = true
    local mainFrame = trophyGui.MainFrame
    
    -- Show frame
    mainFrame.Visible = true
    mainFrame.Size = UDim2.new(0, 0, 0, 0)
    mainFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
    
    -- Animate in
    local openTween = TweenService:Create(
        mainFrame,
        TweenInfo.new(0.4, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
        {
            Size = UDim2.new(0.9, 0, 0.85, 0),
            Position = UDim2.new(0.05, 0, 0.075, 0)
        }
    )
    
    openTween:Play()
    self:_playSound("ui_open")
    
    -- Request fresh trophy data
    RemoteEvents.RequestTrophyData:FireServer()
    
    -- Refresh display
    if currentTrophyData then
        self:_refreshTrophyDisplay()
    end
end

function TrophyController:_closeTrophyHall()
    if not isHallOpen then return end
    
    isHallOpen = false
    local mainFrame = trophyGui.MainFrame
    
    -- Animate out
    local closeTween = TweenService:Create(
        mainFrame,
        TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.In),
        {
            Size = UDim2.new(0, 0, 0, 0),
            Position = UDim2.new(0.5, 0, 0.5, 0)
        }
    )
    
    closeTween:Play()
    self:_playSound("ui_close")
    
    closeTween.Completed:Connect(function()
        mainFrame.Visible = false
    end)
end

function TrophyController:_selectCategory(category)
    -- Update tab appearance
    local tabFrame = trophyGui.MainFrame.CategoryTabs
    for _, tab in pairs(tabFrame:GetChildren()) do
        if tab:IsA("TextButton") then
            if tab.Name == category .. "Tab" then
                tab.BackgroundColor3 = Color3.fromRGB(255, 215, 0)
                tab.TextColor3 = Color3.fromRGB(0, 0, 0)
            else
                tab.BackgroundColor3 = Color3.fromRGB(60, 60, 70)
                tab.TextColor3 = Color3.fromRGB(255, 255, 255)
            end
        end
    end
    
    -- Refresh display with filtered trophies
    self:_refreshTrophyDisplay(category)
end

function TrophyController:_refreshTrophyDisplay(filterCategory)
    if not currentTrophyData then return end
    
    local scrollFrame = trophyGui.MainFrame.TrophyDisplay.TrophyScroll
    
    -- Clear existing trophies
    for _, child in pairs(scrollFrame:GetChildren()) do
        if child:IsA("Frame") then
            child:Destroy()
        end
    end
    
    -- Filter trophies
    local filteredTrophies = {}
    for _, trophy in ipairs(currentTrophyData.badges) do
        if not filterCategory or filterCategory == "All" or trophy.category == filterCategory then
            table.insert(filteredTrophies, trophy)
        end
    end
    
    -- Create trophy cards
    for i, trophy in ipairs(filteredTrophies) do
        local trophyCard = self:_createTrophyCard(trophy, i)
        trophyCard.Parent = scrollFrame
    end
    
    -- Update scroll canvas size
    local gridLayout = scrollFrame:FindFirstChild("UIGridLayout")
    if gridLayout then
        scrollFrame.CanvasSize = UDim2.new(0, 0, 0, gridLayout.AbsoluteContentSize.Y + 20)
    end
end

function TrophyController:_createTrophyCard(trophy, layoutOrder)
    local isUnlocked = currentTrophyData.unlocked[trophy.id] ~= nil
    local progress = currentTrophyData.progress[trophy.id] or 0
    
    local card = Instance.new("Frame")
    card.Name = trophy.id .. "_Card"
    card.LayoutOrder = layoutOrder
    card.BackgroundColor3 = isUnlocked and Color3.fromRGB(50, 50, 60) or Color3.fromRGB(30, 30, 40)
    card.BorderSizePixel = 0
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 10)
    corner.Parent = card
    
    -- Trophy icon
    local iconLabel = Instance.new("TextLabel")
    iconLabel.Name = "Icon"
    iconLabel.Size = UDim2.new(0, 60, 0, 60)
    iconLabel.Position = UDim2.new(0.5, -30, 0, 15)
    iconLabel.BackgroundTransparency = 1
    iconLabel.Text = isUnlocked and "🏆" or "🔒"
    iconLabel.TextColor3 = isUnlocked and trophy.color or Color3.fromRGB(100, 100, 100)
    iconLabel.TextScaled = true
    iconLabel.Font = Enum.Font.SourceSansBold
    iconLabel.Parent = card
    
    -- Trophy name
    local nameLabel = Instance.new("TextLabel")
    nameLabel.Name = "Name"
    nameLabel.Size = UDim2.new(1, -10, 0, 30)
    nameLabel.Position = UDim2.new(0, 5, 0, 80)
    nameLabel.BackgroundTransparency = 1
    nameLabel.Text = trophy.name
    nameLabel.TextColor3 = isUnlocked and Color3.fromRGB(255, 255, 255) or Color3.fromRGB(150, 150, 150)
    nameLabel.TextScaled = true
    nameLabel.Font = Enum.Font.SourceSansBold
    nameLabel.TextWrapped = true
    nameLabel.Parent = card
    
    -- Trophy description
    local descLabel = Instance.new("TextLabel")
    descLabel.Name = "Description"
    descLabel.Size = UDim2.new(1, -10, 0, 40)
    descLabel.Position = UDim2.new(0, 5, 0, 115)
    descLabel.BackgroundTransparency = 1
    descLabel.Text = trophy.description
    descLabel.TextColor3 = isUnlocked and Color3.fromRGB(200, 200, 200) or Color3.fromRGB(120, 120, 120)
    descLabel.TextScaled = true
    descLabel.Font = Enum.Font.SourceSans
    descLabel.TextWrapped = true
    descLabel.Parent = card
    
    -- Progress bar (for locked trophies)
    if not isUnlocked then
        local progressFrame = Instance.new("Frame")
        progressFrame.Name = "ProgressFrame"
        progressFrame.Size = UDim2.new(1, -20, 0, 8)
        progressFrame.Position = UDim2.new(0, 10, 0, 170)
        progressFrame.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
        progressFrame.BorderSizePixel = 0
        progressFrame.Parent = card
        
        local progressCorner = Instance.new("UICorner")
        progressCorner.CornerRadius = UDim.new(0, 4)
        progressCorner.Parent = progressFrame
        
        local progressBar = Instance.new("Frame")
        progressBar.Name = "ProgressBar"
        progressBar.Size = UDim2.new(math.min(progress / trophy.requirement.amount, 1), 0, 1, 0)
        progressBar.Position = UDim2.new(0, 0, 0, 0)
        progressBar.BackgroundColor3 = trophy.color
        progressBar.BorderSizePixel = 0
        progressBar.Parent = progressFrame
        
        local barCorner = Instance.new("UICorner")
        barCorner.CornerRadius = UDim.new(0, 4)
        barCorner.Parent = progressBar
        
        -- Progress text
        local progressText = Instance.new("TextLabel")
        progressText.Name = "ProgressText"
        progressText.Size = UDim2.new(1, -10, 0, 20)
        progressText.Position = UDim2.new(0, 5, 0, 185)
        progressText.BackgroundTransparency = 1
        progressText.Text = progress .. " / " .. trophy.requirement.amount
        progressText.TextColor3 = Color3.fromRGB(150, 150, 150)
        progressText.TextScaled = true
        progressText.Font = Enum.Font.SourceSans
        progressText.Parent = card
    else
        -- Unlocked date
        local unlockedData = currentTrophyData.unlocked[trophy.id]
        if unlockedData and unlockedData.unlockedAt then
            local dateText = os.date("%m/%d/%Y", unlockedData.unlockedAt)
            
            local dateLabel = Instance.new("TextLabel")
            dateLabel.Name = "UnlockedDate"
            dateLabel.Size = UDim2.new(1, -10, 0, 20)
            dateLabel.Position = UDim2.new(0, 5, 0, 170)
            dateLabel.BackgroundTransparency = 1
            dateLabel.Text = "Unlocked: " .. dateText
            dateLabel.TextColor3 = Color3.fromRGB(100, 200, 100)
            dateLabel.TextScaled = true
            dateLabel.Font = Enum.Font.SourceSansItalic
            dateLabel.Parent = card
        end
        
        -- Rarity badge
        local rarityBadge = Instance.new("TextLabel")
        rarityBadge.Name = "RarityBadge"
        rarityBadge.Size = UDim2.new(0, 60, 0, 20)
        rarityBadge.Position = UDim2.new(1, -65, 0, 195)
        rarityBadge.BackgroundColor3 = trophy.color
        rarityBadge.Text = trophy.rarity:upper()
        rarityBadge.TextColor3 = Color3.new(0, 0, 0)
        rarityBadge.TextScaled = true
        rarityBadge.Font = Enum.Font.SourceSansBold
        rarityBadge.Parent = card
        
        local badgeCorner = Instance.new("UICorner")
        badgeCorner.CornerRadius = UDim.new(0, 10)
        badgeCorner.Parent = rarityBadge
    end
    
    -- Hover effect
    card.MouseEnter:Connect(function()
        TweenService:Create(card, TweenInfo.new(0.2), {
            BackgroundColor3 = isUnlocked and Color3.fromRGB(70, 70, 80) or Color3.fromRGB(50, 50, 60)
        }):Play()
    end)
    
    card.MouseLeave:Connect(function()
        TweenService:Create(card, TweenInfo.new(0.2), {
            BackgroundColor3 = isUnlocked and Color3.fromRGB(50, 50, 60) or Color3.fromRGB(30, 30, 40)
        }):Play()
    end)
    
    return card
end

function TrophyController:_playSound(soundName)
    if not sounds[soundName] then return end
    
    local sound = Instance.new("Sound")
    sound.SoundId = sounds[soundName]
    sound.Volume = 0.5
    sound.Parent = SoundService
    
    sound:Play()
    
    sound.Ended:Connect(function()
        sound:Destroy()
    end)
end

return TrophyController
