-- TrailManagerController.luau
-- Manages trail equipping/unequipping interface

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local SoundService = game:GetService("SoundService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local RemoteEvents = require(ReplicatedStorage.Shared.modules.RemoteEvents)
local TrailController = require(script.Parent.TrailController)

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local TrailManagerController = {}

-- GUI state
local trailGui = nil
local isOpen = false

-- Player data
local ownedTrails = {}
local equippedTrail = nil

-- Sound effects
local selectSound = nil
local equipSound = nil
local unequipSound = nil

-- Trail definitions (matching TrailController)
local TRAIL_DEFINITIONS = {
    common_sparkle = {
        name = "Sparkle Trail",
        rarity = "Common",
        color = Color3.fromRGB(200, 200, 200),
        icon = "✨",
        description = "Basic sparkle particles that follow your run"
    },
    rare_flame = {
        name = "Flame Trail",
        rarity = "Rare", 
        color = Color3.fromRGB(0, 162, 255),
        icon = "🔥",
        description = "Fiery orange and red flames with heat distortion"
    },
    epic_rainbow = {
        name = "Rainbow Trail",
        rarity = "Epic",
        color = Color3.fromRGB(128, 0, 128),
        icon = "🌈",
        description = "Spectacular rainbow particles that cycle through all colors"
    }
}

function TrailManagerController:Init()
    self:LoadSounds()
    self:SetupRemoteEvents()
    self:RequestPlayerTrails()
    print("🌟 TrailManagerController initialized")
end

function TrailManagerController:LoadSounds()
    -- Selection sound
    selectSound = Instance.new("Sound")
    selectSound.SoundId = "rbxasset://sounds/electronicpingshort.wav"
    selectSound.Volume = 0.3
    selectSound.Pitch = 1.2
    selectSound.Parent = SoundService
    
    -- Equip sound
    equipSound = Instance.new("Sound")
    equipSound.SoundId = "rbxasset://sounds/impact_water.mp3"
    equipSound.Volume = 0.5
    equipSound.Pitch = 1.1
    equipSound.Parent = SoundService
    
    -- Unequip sound
    unequipSound = Instance.new("Sound")
    unequipSound.SoundId = "rbxasset://sounds/snap.mp3"
    unequipSound.Volume = 0.4
    unequipSound.Pitch = 0.9
    unequipSound.Parent = SoundService
end

function TrailManagerController:SetupRemoteEvents()
    -- Handle trail manager requests
    RemoteEvents.ShowTrailManager.OnClientEvent:Connect(function()
        self:OpenTrailManager()
    end)
    
    -- Handle player trail data updates
    RemoteEvents.PlayerTrailsUpdate.OnClientEvent:Connect(function(trails, equipped)
        self:UpdatePlayerTrails(trails, equipped)
    end)
    
    -- Handle trail equip/unequip responses
    RemoteEvents.TrailEquipResult.OnClientEvent:Connect(function(success, trailId, message)
        self:HandleEquipResult(success, trailId, message)
    end)
end

function TrailManagerController:RequestPlayerTrails()
    -- Request current trail data from server
    RemoteEvents.GetPlayerTrails:FireServer()
end

function TrailManagerController:UpdatePlayerTrails(trails, equipped)
    ownedTrails = trails or {}
    equippedTrail = equipped
    
    -- Update GUI if open
    if isOpen and trailGui then
        self:RefreshTrailList()
    end
    
    -- Update TrailController's equipped trail
    if TrailController and TrailController.SetEquippedTrail then
        TrailController:SetEquippedTrail(equipped)
    end
end

function TrailManagerController:OpenTrailManager()
    if isOpen then
        self:CloseTrailManager()
        return
    end
    
    isOpen = true
    self:CreateTrailManagerGui()
    self:RequestPlayerTrails() -- Refresh data when opening
end

function TrailManagerController:CreateTrailManagerGui()
    -- Remove existing GUI
    local existingGui = playerGui:FindFirstChild("TrailManagerGui")
    if existingGui then
        existingGui:Destroy()
    end
    
    -- Create main GUI
    trailGui = Instance.new("ScreenGui")
    trailGui.Name = "TrailManagerGui"
    trailGui.Parent = playerGui
    
    -- Background overlay
    local overlay = Instance.new("Frame")
    overlay.Name = "Overlay"
    overlay.Size = UDim2.new(1, 0, 1, 0)
    overlay.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    overlay.BackgroundTransparency = 0.6
    overlay.BorderSizePixel = 0
    overlay.Parent = trailGui
    
    -- Main trail manager frame
    local managerFrame = Instance.new("Frame")
    managerFrame.Name = "ManagerFrame"
    managerFrame.Size = UDim2.new(0, 600, 0, 500)
    managerFrame.Position = UDim2.new(0.5, -300, 0.5, -250)
    managerFrame.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
    managerFrame.BorderSizePixel = 0
    managerFrame.Parent = overlay
    
    local frameCorner = Instance.new("UICorner")
    frameCorner.CornerRadius = UDim.new(0, 15)
    frameCorner.Parent = managerFrame
    
    local frameBorder = Instance.new("UIStroke")
    frameBorder.Color = Color3.fromRGB(100, 100, 100)
    frameBorder.Thickness = 2
    frameBorder.Parent = managerFrame
    
    -- Title
    local titleLabel = Instance.new("TextLabel")
    titleLabel.Name = "Title"
    titleLabel.Size = UDim2.new(1, -20, 0, 50)
    titleLabel.Position = UDim2.new(0, 10, 0, 10)
    titleLabel.BackgroundTransparency = 1
    titleLabel.Text = "🌟 TRAIL MANAGER 🌟"
    titleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    titleLabel.TextScaled = true
    titleLabel.Font = Enum.Font.GothamBold
    titleLabel.Parent = managerFrame
    
    -- Currently equipped display
    local equippedFrame = Instance.new("Frame")
    equippedFrame.Name = "EquippedFrame"
    equippedFrame.Size = UDim2.new(1, -40, 0, 80)
    equippedFrame.Position = UDim2.new(0, 20, 0, 70)
    equippedFrame.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
    equippedFrame.BorderSizePixel = 0
    equippedFrame.Parent = managerFrame
    
    local equippedCorner = Instance.new("UICorner")
    equippedCorner.CornerRadius = UDim.new(0, 10)
    equippedCorner.Parent = equippedFrame
    
    local equippedLabel = Instance.new("TextLabel")
    equippedLabel.Name = "EquippedLabel"
    equippedLabel.Size = UDim2.new(1, -20, 1, 0)
    equippedLabel.Position = UDim2.new(0, 10, 0, 0)
    equippedLabel.BackgroundTransparency = 1
    equippedLabel.Text = "Currently Equipped: None"
    equippedLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
    equippedLabel.TextScaled = true
    equippedLabel.Font = Enum.Font.Gotham
    equippedLabel.Parent = equippedFrame
    
    -- Trail list container
    local listContainer = Instance.new("ScrollingFrame")
    listContainer.Name = "ListContainer"
    listContainer.Size = UDim2.new(1, -40, 0, 280)
    listContainer.Position = UDim2.new(0, 20, 0, 170)
    listContainer.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
    listContainer.BorderSizePixel = 0
    listContainer.ScrollBarThickness = 8
    listContainer.ScrollBarImageColor3 = Color3.fromRGB(100, 100, 100)
    listContainer.Parent = managerFrame
    
    local listCorner = Instance.new("UICorner")
    listCorner.CornerRadius = UDim.new(0, 10)
    listCorner.Parent = listContainer
    
    -- List layout
    local listLayout = Instance.new("UIListLayout")
    listLayout.SortOrder = Enum.SortOrder.LayoutOrder
    listLayout.Padding = UDim.new(0, 5)
    listLayout.Parent = listContainer
    
    -- Close button
    local closeButton = Instance.new("TextButton")
    closeButton.Name = "CloseButton"
    closeButton.Size = UDim2.new(0, 40, 0, 40)
    closeButton.Position = UDim2.new(1, -50, 0, 10)
    closeButton.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
    closeButton.BorderSizePixel = 0
    closeButton.Text = "✕"
    closeButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    closeButton.TextScaled = true
    closeButton.Font = Enum.Font.GothamBold
    closeButton.Parent = managerFrame
    
    local closeCorner = Instance.new("UICorner")
    closeCorner.CornerRadius = UDim.new(0, 8)
    closeCorner.Parent = closeButton
    
    -- Unequip all button
    local unequipButton = Instance.new("TextButton")
    unequipButton.Name = "UnequipButton"
    unequipButton.Size = UDim2.new(0, 150, 0, 30)
    unequipButton.Position = UDim2.new(0, 20, 0, 460)
    unequipButton.BackgroundColor3 = Color3.fromRGB(180, 100, 0)
    unequipButton.BorderSizePixel = 0
    unequipButton.Text = "Unequip All"
    unequipButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    unequipButton.TextScaled = true
    unequipButton.Font = Enum.Font.Gotham
    unequipButton.Parent = managerFrame
    
    local unequipCorner = Instance.new("UICorner")
    unequipCorner.CornerRadius = UDim.new(0, 8)
    unequipCorner.Parent = unequipButton
    
    -- Preview button
    local previewButton = Instance.new("TextButton")
    previewButton.Name = "PreviewButton"
    previewButton.Size = UDim2.new(0, 150, 0, 30)
    previewButton.Position = UDim2.new(0, 180, 0, 460)
    previewButton.BackgroundColor3 = Color3.fromRGB(0, 150, 200)
    previewButton.BorderSizePixel = 0
    previewButton.Text = "Preview Trail"
    previewButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    previewButton.TextScaled = true
    previewButton.Font = Enum.Font.Gotham
    previewButton.Parent = managerFrame
    
    local previewCorner = Instance.new("UICorner")
    previewCorner.CornerRadius = UDim.new(0, 8)
    previewCorner.Parent = previewButton
    
    -- Button connections
    closeButton.MouseButton1Click:Connect(function()
        self:CloseTrailManager()
    end)
    
    unequipButton.MouseButton1Click:Connect(function()
        self:UnequipAllTrails()
    end)
    
    previewButton.MouseButton1Click:Connect(function()
        self:PreviewEquippedTrail()
    end)
    
    -- Populate trail list
    self:RefreshTrailList()
    
    -- Animate in
    managerFrame.Size = UDim2.new(0, 0, 0, 0)
    local animateIn = TweenService:Create(
        managerFrame,
        TweenInfo.new(0.5, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
        {Size = UDim2.new(0, 600, 0, 500)}
    )
    animateIn:Play()
end

function TrailManagerController:RefreshTrailList()
    if not trailGui then return end
    
    local listContainer = trailGui.Overlay.ManagerFrame.ListContainer
    local equippedLabel = trailGui.Overlay.ManagerFrame.EquippedFrame.EquippedLabel
    
    -- Clear existing items
    for _, child in ipairs(listContainer:GetChildren()) do
        if child:IsA("Frame") then
            child:Destroy()
        end
    end
    
    -- Update equipped display
    if equippedTrail and TRAIL_DEFINITIONS[equippedTrail] then
        local trailData = TRAIL_DEFINITIONS[equippedTrail]
        equippedLabel.Text = "Currently Equipped: " .. trailData.icon .. " " .. trailData.name
        equippedLabel.TextColor3 = trailData.color
    else
        equippedLabel.Text = "Currently Equipped: None"
        equippedLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
    end
    
    -- Create trail items
    local yOffset = 0
    for trailId, trailData in pairs(TRAIL_DEFINITIONS) do
        local isOwned = table.find(ownedTrails, trailId) ~= nil
        local isEquipped = equippedTrail == trailId
        
        self:CreateTrailItem(listContainer, trailId, trailData, isOwned, isEquipped, yOffset)
        yOffset = yOffset + 85
    end
    
    -- Update canvas size
    listContainer.CanvasSize = UDim2.new(0, 0, 0, yOffset)
end

function TrailManagerController:CreateTrailItem(parent, trailId, trailData, isOwned, isEquipped, yOffset)
    -- Main item frame
    local itemFrame = Instance.new("Frame")
    itemFrame.Name = trailId
    itemFrame.Size = UDim2.new(1, -10, 0, 80)
    itemFrame.Position = UDim2.new(0, 5, 0, yOffset)
    itemFrame.BackgroundColor3 = isEquipped and Color3.fromRGB(0, 100, 0) or 
                                  isOwned and Color3.fromRGB(60, 60, 60) or 
                                  Color3.fromRGB(40, 40, 40)
    itemFrame.BorderSizePixel = 0
    itemFrame.Parent = parent
    
    local itemCorner = Instance.new("UICorner")
    itemCorner.CornerRadius = UDim.new(0, 8)
    itemCorner.Parent = itemFrame
    
    -- Trail icon
    local iconLabel = Instance.new("TextLabel")
    iconLabel.Size = UDim2.new(0, 60, 0, 60)
    iconLabel.Position = UDim2.new(0, 10, 0, 10)
    iconLabel.BackgroundColor3 = trailData.color
    iconLabel.BorderSizePixel = 0
    iconLabel.Text = trailData.icon
    iconLabel.TextScaled = true
    iconLabel.Font = Enum.Font.SourceSansBold
    iconLabel.Parent = itemFrame
    
    local iconCorner = Instance.new("UICorner")
    iconCorner.CornerRadius = UDim.new(0, 8)
    iconCorner.Parent = iconLabel
    
    -- Trail info
    local nameLabel = Instance.new("TextLabel")
    nameLabel.Size = UDim2.new(0, 200, 0, 25)
    nameLabel.Position = UDim2.new(0, 80, 0, 10)
    nameLabel.BackgroundTransparency = 1
    nameLabel.Text = trailData.name
    nameLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    nameLabel.TextScaled = true
    nameLabel.Font = Enum.Font.GothamBold
    nameLabel.TextXAlignment = Enum.TextXAlignment.Left
    nameLabel.Parent = itemFrame
    
    local rarityLabel = Instance.new("TextLabel")
    rarityLabel.Size = UDim2.new(0, 200, 0, 20)
    rarityLabel.Position = UDim2.new(0, 80, 0, 35)
    rarityLabel.BackgroundTransparency = 1
    rarityLabel.Text = trailData.rarity .. " Rarity"
    rarityLabel.TextColor3 = trailData.color
    rarityLabel.TextScaled = true
    rarityLabel.Font = Enum.Font.Gotham
    rarityLabel.TextXAlignment = Enum.TextXAlignment.Left
    rarityLabel.Parent = itemFrame
    
    local descLabel = Instance.new("TextLabel")
    descLabel.Size = UDim2.new(0, 200, 0, 15)
    descLabel.Position = UDim2.new(0, 80, 0, 55)
    descLabel.BackgroundTransparency = 1
    descLabel.Text = trailData.description
    descLabel.TextColor3 = Color3.fromRGB(180, 180, 180)
    descLabel.TextScaled = true
    descLabel.Font = Enum.Font.Gotham
    descLabel.TextXAlignment = Enum.TextXAlignment.Left
    descLabel.Parent = itemFrame
    
    -- Status/Action button
    local actionButton = Instance.new("TextButton")
    actionButton.Size = UDim2.new(0, 100, 0, 30)
    actionButton.Position = UDim2.new(1, -110, 0, 25)
    actionButton.BorderSizePixel = 0
    actionButton.TextScaled = true
    actionButton.Font = Enum.Font.GothamBold
    actionButton.Parent = itemFrame
    
    local actionCorner = Instance.new("UICorner")
    actionCorner.CornerRadius = UDim.new(0, 6)
    actionCorner.Parent = actionButton
    
    -- Set button appearance and function based on status
    if not isOwned then
        actionButton.Text = "LOCKED"
        actionButton.BackgroundColor3 = Color3.fromRGB(100, 50, 50)
        actionButton.TextColor3 = Color3.fromRGB(200, 200, 200)
        actionButton.Active = false
    elseif isEquipped then
        actionButton.Text = "EQUIPPED"
        actionButton.BackgroundColor3 = Color3.fromRGB(0, 150, 0)
        actionButton.TextColor3 = Color3.fromRGB(255, 255, 255)
        actionButton.Active = false
    else
        actionButton.Text = "EQUIP"
        actionButton.BackgroundColor3 = Color3.fromRGB(0, 122, 204)
        actionButton.TextColor3 = Color3.fromRGB(255, 255, 255)
        actionButton.Active = true
        
        actionButton.MouseButton1Click:Connect(function()
            self:EquipTrail(trailId)
        end)
    end
    
    -- Hover effects for owned trails
    if isOwned then
        local function onEnter()
            if selectSound then selectSound:Play() end
            local hoverTween = TweenService:Create(
                itemFrame,
                TweenInfo.new(0.2, Enum.EasingStyle.Quad),
                {BackgroundColor3 = isEquipped and Color3.fromRGB(0, 130, 0) or Color3.fromRGB(80, 80, 80)}
            )
            hoverTween:Play()
        end
        
        local function onLeave()
            local normalTween = TweenService:Create(
                itemFrame,
                TweenInfo.new(0.2, Enum.EasingStyle.Quad),
                {BackgroundColor3 = isEquipped and Color3.fromRGB(0, 100, 0) or Color3.fromRGB(60, 60, 60)}
            )
            normalTween:Play()
        end
        
        itemFrame.MouseEnter:Connect(onEnter)
        itemFrame.MouseLeave:Connect(onLeave)
    end
end

function TrailManagerController:EquipTrail(trailId)
    -- Send equip request to server
    RemoteEvents.EquipTrail:FireServer(trailId)
    
    if equipSound then
        equipSound:Play()
    end
end

function TrailManagerController:UnequipAllTrails()
    -- Send unequip request to server
    RemoteEvents.UnequipTrail:FireServer()
    
    if unequipSound then
        unequipSound:Play()
    end
end

function TrailManagerController:PreviewEquippedTrail()
    if not equippedTrail then return end
    
    -- Use TrailController to show a brief preview
    if TrailController and TrailController.PreviewTrail then
        TrailController:PreviewTrail(equippedTrail, 3) -- 3 second preview
    end
end

function TrailManagerController:HandleEquipResult(success, trailId, message)
    if success then
        print("Trail equipped:", trailId)
    else
        print("Trail equip failed:", message)
        -- Could show error message to user here
    end
end

function TrailManagerController:CloseTrailManager()
    if not trailGui then return end
    
    local managerFrame = trailGui.Overlay.ManagerFrame
    
    local animateOut = TweenService:Create(
        managerFrame,
        TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.In),
        {Size = UDim2.new(0, 0, 0, 0)}
    )
    
    animateOut:Play()
    animateOut.Completed:Connect(function()
        trailGui:Destroy()
        trailGui = nil
        isOpen = false
    end)
end

function TrailManagerController:Cleanup()
    if trailGui then
        trailGui:Destroy()
        trailGui = nil
    end
    isOpen = false
end

return TrailManagerController
