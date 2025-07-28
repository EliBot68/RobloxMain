-- PetController.luau
-- Handles pet shop UI and client-side pet interactions

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local SoundService = game:GetService("SoundService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

local RemoteEvents = require(ReplicatedStorage.Shared.modules.RemoteEvents)

local PetController = {}
local player = Players.LocalPlayer

-- UI References
local petShopGui = nil
local petShopFrame = nil
local isShopOpen = false

-- Current shop data
local currentPetDatabase = {}
local currentPlayerPetData = {}

-- UI Constants
local RARITY_COLORS = {
    Common = Color3.new(0.8, 0.8, 0.8),
    Uncommon = Color3.new(0.4, 1, 0.4),
    Rare = Color3.new(0.4, 0.4, 1),
    Epic = Color3.new(0.8, 0.4, 1),
    Legendary = Color3.new(1, 0.8, 0.2),
    Mythic = Color3.new(1, 0.2, 0.2)
}

function PetController:CreatePetShopGui()
    if petShopGui then return end
    
    -- Main GUI
    petShopGui = Instance.new("ScreenGui")
    petShopGui.Name = "PetShopGui"
    petShopGui.ResetOnSpawn = false
    petShopGui.Parent = player.PlayerGui
    
    -- Background blur
    local background = Instance.new("Frame")
    background.Name = "Background"
    background.Size = UDim2.new(1, 0, 1, 0)
    background.Position = UDim2.new(0, 0, 0, 0)
    background.BackgroundColor3 = Color3.new(0, 0, 0)
    background.BackgroundTransparency = 0.5
    background.Parent = petShopGui
    
    -- Main frame
    petShopFrame = Instance.new("Frame")
    petShopFrame.Name = "ShopFrame"
    petShopFrame.Size = UDim2.new(0.8, 0, 0.85, 0)
    petShopFrame.Position = UDim2.new(0.1, 0, 0.075, 0)
    petShopFrame.BackgroundColor3 = Color3.new(0.1, 0.1, 0.15)
    petShopFrame.BorderSizePixel = 0
    petShopFrame.Parent = petShopGui
    
    -- Corner styling
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 15)
    corner.Parent = petShopFrame
    
    -- Header
    local header = Instance.new("Frame")
    header.Name = "Header"
    header.Size = UDim2.new(1, 0, 0.1, 0)
    header.Position = UDim2.new(0, 0, 0, 0)
    header.BackgroundColor3 = Color3.new(0.8, 0.6, 1)
    header.BorderSizePixel = 0
    header.Parent = petShopFrame
    
    local headerCorner = Instance.new("UICorner")
    headerCorner.CornerRadius = UDim.new(0, 15)
    headerCorner.Parent = header
    
    -- Title
    local title = Instance.new("TextLabel")
    title.Name = "Title"
    title.Size = UDim2.new(0.8, 0, 1, 0)
    title.Position = UDim2.new(0.1, 0, 0, 0)
    title.BackgroundTransparency = 1
    title.Text = "🐾 PET SHOP"
    title.TextColor3 = Color3.new(1, 1, 1)
    title.TextScaled = true
    title.Font = Enum.Font.SourceSansBold
    title.TextStrokeTransparency = 0
    title.TextStrokeColor3 = Color3.new(0, 0, 0)
    title.Parent = header
    
    -- Close button
    local closeButton = Instance.new("TextButton")
    closeButton.Name = "CloseButton"
    closeButton.Size = UDim2.new(0.08, 0, 0.8, 0)
    closeButton.Position = UDim2.new(0.9, 0, 0.1, 0)
    closeButton.BackgroundColor3 = Color3.new(1, 0.3, 0.3)
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
        self:ClosePetShop()
    end)
    
    -- Tabs
    local tabsFrame = Instance.new("Frame")
    tabsFrame.Name = "TabsFrame"
    tabsFrame.Size = UDim2.new(1, 0, 0.08, 0)
    tabsFrame.Position = UDim2.new(0, 0, 0.1, 0)
    tabsFrame.BackgroundTransparency = 1
    tabsFrame.Parent = petShopFrame
    
    -- Shop tab
    local shopTab = Instance.new("TextButton")
    shopTab.Name = "ShopTab"
    shopTab.Size = UDim2.new(0.33, -5, 1, 0)
    shopTab.Position = UDim2.new(0, 5, 0, 0)
    shopTab.BackgroundColor3 = Color3.new(0.2, 0.8, 0.2)
    shopTab.Text = "🛍️ SHOP"
    shopTab.TextColor3 = Color3.new(1, 1, 1)
    shopTab.TextScaled = true
    shopTab.Font = Enum.Font.SourceSansBold
    shopTab.BorderSizePixel = 0
    shopTab.Parent = tabsFrame
    
    local shopTabCorner = Instance.new("UICorner")
    shopTabCorner.CornerRadius = UDim.new(0, 8)
    shopTabCorner.Parent = shopTab
    
    -- Collection tab
    local collectionTab = Instance.new("TextButton")
    collectionTab.Name = "CollectionTab"
    collectionTab.Size = UDim2.new(0.33, -5, 1, 0)
    collectionTab.Position = UDim2.new(0.33, 0, 0, 0)
    collectionTab.BackgroundColor3 = Color3.new(0.6, 0.6, 0.6)
    collectionTab.Text = "📦 COLLECTION"
    collectionTab.TextColor3 = Color3.new(1, 1, 1)
    collectionTab.TextScaled = true
    collectionTab.Font = Enum.Font.SourceSansBold
    collectionTab.BorderSizePixel = 0
    collectionTab.Parent = tabsFrame
    
    local collectionTabCorner = Instance.new("UICorner")
    collectionTabCorner.CornerRadius = UDim.new(0, 8)
    collectionTabCorner.Parent = collectionTab
    
    -- Active tab
    local activeTab = Instance.new("TextButton")
    activeTab.Name = "ActiveTab"
    activeTab.Size = UDim2.new(0.33, -5, 1, 0)
    activeTab.Position = UDim2.new(0.66, 0, 0, 0)
    activeTab.BackgroundColor3 = Color3.new(0.6, 0.6, 0.6)
    activeTab.Text = "⭐ ACTIVE"
    activeTab.TextColor3 = Color3.new(1, 1, 1)
    activeTab.TextScaled = true
    activeTab.Font = Enum.Font.SourceSansBold
    activeTab.BorderSizePixel = 0
    activeTab.Parent = tabsFrame
    
    local activeTabCorner = Instance.new("UICorner")
    activeTabCorner.CornerRadius = UDim.new(0, 8)
    activeTabCorner.Parent = activeTab
    
    -- Content area
    local contentFrame = Instance.new("ScrollingFrame")
    contentFrame.Name = "ContentFrame"
    contentFrame.Size = UDim2.new(1, -20, 0.82, -10)
    contentFrame.Position = UDim2.new(0, 10, 0.18, 5)
    contentFrame.BackgroundColor3 = Color3.new(0.15, 0.15, 0.2)
    contentFrame.BorderSizePixel = 0
    contentFrame.ScrollBarThickness = 8
    contentFrame.ScrollBarImageColor3 = Color3.new(0.8, 0.6, 1)
    contentFrame.Parent = petShopFrame
    
    local contentCorner = Instance.new("UICorner")
    contentCorner.CornerRadius = UDim.new(0, 10)
    contentCorner.Parent = contentFrame
    
    -- Grid layout for pets
    local gridLayout = Instance.new("UIGridLayout")
    gridLayout.CellSize = UDim2.new(0.3, -10, 0, 180)
    gridLayout.CellPadding = UDim2.new(0, 10, 0, 10)
    gridLayout.HorizontalAlignment = Enum.HorizontalAlignment.Left
    gridLayout.VerticalAlignment = Enum.VerticalAlignment.Top
    gridLayout.SortOrder = Enum.SortOrder.Name
    gridLayout.Parent = contentFrame
    
    -- Tab click handlers
    shopTab.MouseButton1Click:Connect(function()
        self:ShowShopTab(shopTab, collectionTab, activeTab)
    end)
    
    collectionTab.MouseButton1Click:Connect(function()
        self:ShowCollectionTab(shopTab, collectionTab, activeTab)
    end)
    
    activeTab.MouseButton1Click:Connect(function()
        self:ShowActiveTab(shopTab, collectionTab, activeTab)
    end)
    
    -- Start with shop tab
    self:ShowShopTab(shopTab, collectionTab, activeTab)
    
    -- Hide initially
    petShopGui.Enabled = false
end

function PetController:ShowShopTab(shopTab, collectionTab, activeTab)
    -- Update tab colors
    shopTab.BackgroundColor3 = Color3.new(0.2, 0.8, 0.2)
    collectionTab.BackgroundColor3 = Color3.new(0.6, 0.6, 0.6)
    activeTab.BackgroundColor3 = Color3.new(0.6, 0.6, 0.6)
    
    self:PopulateShopContent()
end

function PetController:ShowCollectionTab(shopTab, collectionTab, activeTab)
    -- Update tab colors
    shopTab.BackgroundColor3 = Color3.new(0.6, 0.6, 0.6)
    collectionTab.BackgroundColor3 = Color3.new(0.2, 0.8, 0.2)
    activeTab.BackgroundColor3 = Color3.new(0.6, 0.6, 0.6)
    
    self:PopulateCollectionContent()
end

function PetController:ShowActiveTab(shopTab, collectionTab, activeTab)
    -- Update tab colors
    shopTab.BackgroundColor3 = Color3.new(0.6, 0.6, 0.6)
    collectionTab.BackgroundColor3 = Color3.new(0.6, 0.6, 0.6)
    activeTab.BackgroundColor3 = Color3.new(0.2, 0.8, 0.2)
    
    self:PopulateActiveContent()
end

function PetController:PopulateShopContent()
    local contentFrame = petShopFrame.ContentFrame
    
    -- Clear existing content
    for _, child in pairs(contentFrame:GetChildren()) do
        if child:IsA("Frame") then
            child:Destroy()
        end
    end
    
    -- Add pets for sale
    for i, petData in pairs(currentPetDatabase) do
        self:CreatePetCard(contentFrame, petData, "shop")
    end
    
    -- Update scroll size
    local gridLayout = contentFrame.UIGridLayout
    contentFrame.CanvasSize = UDim2.new(0, 0, 0, gridLayout.AbsoluteContentSize.Y + 20)
end

function PetController:PopulateCollectionContent()
    local contentFrame = petShopFrame.ContentFrame
    
    -- Clear existing content
    for _, child in pairs(contentFrame:GetChildren()) do
        if child:IsA("Frame") then
            child:Destroy()
        end
    end
    
    -- Add owned pets
    for _, ownedPetId in pairs(currentPlayerPetData.ownedPets or {}) do
        for _, petData in pairs(currentPetDatabase) do
            if petData.id == ownedPetId then
                self:CreatePetCard(contentFrame, petData, "collection")
                break
            end
        end
    end
    
    -- Update scroll size
    local gridLayout = contentFrame.UIGridLayout
    contentFrame.CanvasSize = UDim2.new(0, 0, 0, gridLayout.AbsoluteContentSize.Y + 20)
end

function PetController:PopulateActiveContent()
    local contentFrame = petShopFrame.ContentFrame
    
    -- Clear existing content
    for _, child in pairs(contentFrame:GetChildren()) do
        if child:IsA("Frame") then
            child:Destroy()
        end
    end
    
    -- Add active pet management
    local activePetFrame = Instance.new("Frame")
    activePetFrame.Name = "ActivePetFrame"
    activePetFrame.Size = UDim2.new(1, -20, 0, 200)
    activePetFrame.Position = UDim2.new(0, 10, 0, 10)
    activePetFrame.BackgroundColor3 = Color3.new(0.2, 0.2, 0.25)
    activePetFrame.BorderSizePixel = 0
    activePetFrame.Parent = contentFrame
    
    local activeCorner = Instance.new("UICorner")
    activeCorner.CornerRadius = UDim.new(0, 10)
    activeCorner.Parent = activePetFrame
    
    -- Active pet display
    if currentPlayerPetData.activePet then
        local activePetData = nil
        for _, petData in pairs(currentPetDatabase) do
            if petData.id == currentPlayerPetData.activePet then
                activePetData = petData
                break
            end
        end
        
        if activePetData then
            local petName = Instance.new("TextLabel")
            petName.Size = UDim2.new(1, 0, 0.3, 0)
            petName.Position = UDim2.new(0, 0, 0.1, 0)
            petName.BackgroundTransparency = 1
            petName.Text = "Active Pet: " .. activePetData.name
            petName.TextColor3 = Color3.new(1, 1, 1)
            petName.TextScaled = true
            petName.Font = Enum.Font.SourceSansBold
            petName.Parent = activePetFrame
            
            local petPassive = Instance.new("TextLabel")
            petPassive.Size = UDim2.new(1, 0, 0.3, 0)
            petPassive.Position = UDim2.new(0, 0, 0.4, 0)
            petPassive.BackgroundTransparency = 1
            petPassive.Text = "Passive: " .. activePetData.passive.description
            petPassive.TextColor3 = Color3.new(0.8, 0.8, 1)
            petPassive.TextScaled = true
            petPassive.Font = Enum.Font.SourceSans
            petPassive.Parent = activePetFrame
        end
    else
        local noPetLabel = Instance.new("TextLabel")
        noPetLabel.Size = UDim2.new(1, 0, 0.6, 0)
        noPetLabel.Position = UDim2.new(0, 0, 0.2, 0)
        noPetLabel.BackgroundTransparency = 1
        noPetLabel.Text = "No Active Pet\nEquip a pet from your collection!"
        noPetLabel.TextColor3 = Color3.new(0.7, 0.7, 0.7)
        noPetLabel.TextScaled = true
        noPetLabel.Font = Enum.Font.SourceSans
        noPetLabel.Parent = activePetFrame
    end
    
    -- Unequip button
    local unequipButton = Instance.new("TextButton")
    unequipButton.Size = UDim2.new(0.3, 0, 0.25, 0)
    unequipButton.Position = UDim2.new(0.35, 0, 0.7, 0)
    unequipButton.BackgroundColor3 = Color3.new(1, 0.4, 0.4)
    unequipButton.Text = "Unequip Pet"
    unequipButton.TextColor3 = Color3.new(1, 1, 1)
    unequipButton.TextScaled = true
    unequipButton.Font = Enum.Font.SourceSansBold
    unequipButton.BorderSizePixel = 0
    unequipButton.Parent = activePetFrame
    
    local unequipCorner = Instance.new("UICorner")
    unequipCorner.CornerRadius = UDim.new(0, 8)
    unequipCorner.Parent = unequipButton
    
    unequipButton.MouseButton1Click:Connect(function()
        RemoteEvents.EquipPet:FireServer(nil)
    end)
    
    -- Update scroll size
    contentFrame.CanvasSize = UDim2.new(0, 0, 0, 250)
end

function PetController:CreatePetCard(parent, petData, cardType)
    local isOwned = false
    for _, ownedPetId in pairs(currentPlayerPetData.ownedPets or {}) do
        if ownedPetId == petData.id then
            isOwned = true
            break
        end
    end
    
    local isActive = currentPlayerPetData.activePet == petData.id
    
    -- Pet card frame
    local petCard = Instance.new("Frame")
    petCard.Name = petData.id .. "_Card"
    petCard.BackgroundColor3 = Color3.new(0.25, 0.25, 0.3)
    petCard.BorderSizePixel = 0
    petCard.Parent = parent
    
    local cardCorner = Instance.new("UICorner")
    cardCorner.CornerRadius = UDim.new(0, 8)
    cardCorner.Parent = petCard
    
    -- Rarity border
    local rarityBorder = Instance.new("Frame")
    rarityBorder.Name = "RarityBorder"
    rarityBorder.Size = UDim2.new(1, 4, 1, 4)
    rarityBorder.Position = UDim2.new(0, -2, 0, -2)
    rarityBorder.BackgroundColor3 = RARITY_COLORS[petData.rarity] or Color3.new(0.5, 0.5, 0.5)
    rarityBorder.BorderSizePixel = 0
    rarityBorder.ZIndex = petCard.ZIndex - 1
    rarityBorder.Parent = petCard
    
    local borderCorner = Instance.new("UICorner")
    borderCorner.CornerRadius = UDim.new(0, 10)
    borderCorner.Parent = rarityBorder
    
    -- Pet icon/preview
    local petIcon = Instance.new("Frame")
    petIcon.Name = "PetIcon"
    petIcon.Size = UDim2.new(1, -10, 0.4, 0)
    petIcon.Position = UDim2.new(0, 5, 0, 5)
    petIcon.BackgroundColor3 = petData.color
    petIcon.BorderSizePixel = 0
    petIcon.Parent = petCard
    
    local iconCorner = Instance.new("UICorner")
    iconCorner.CornerRadius = UDim.new(0, 6)
    iconCorner.Parent = petIcon
    
    -- Pet name
    local petName = Instance.new("TextLabel")
    petName.Name = "PetName"
    petName.Size = UDim2.new(1, -10, 0.15, 0)
    petName.Position = UDim2.new(0, 5, 0.42, 0)
    petName.BackgroundTransparency = 1
    petName.Text = petData.name
    petName.TextColor3 = Color3.new(1, 1, 1)
    petName.TextScaled = true
    petName.Font = Enum.Font.SourceSansBold
    petName.Parent = petCard
    
    -- Passive ability
    local passiveLabel = Instance.new("TextLabel")
    passiveLabel.Name = "PassiveLabel"
    passiveLabel.Size = UDim2.new(1, -10, 0.2, 0)
    passiveLabel.Position = UDim2.new(0, 5, 0.57, 0)
    passiveLabel.BackgroundTransparency = 1
    passiveLabel.Text = petData.passive.description
    passiveLabel.TextColor3 = Color3.new(0.8, 0.8, 1)
    passiveLabel.TextScaled = true
    passiveLabel.Font = Enum.Font.SourceSans
    passiveLabel.TextWrapped = true
    passiveLabel.Parent = petCard
    
    -- Action button
    local actionButton = Instance.new("TextButton")
    actionButton.Name = "ActionButton"
    actionButton.Size = UDim2.new(1, -10, 0.18, 0)
    actionButton.Position = UDim2.new(0, 5, 0.77, 0)
    actionButton.BorderSizePixel = 0
    actionButton.TextScaled = true
    actionButton.Font = Enum.Font.SourceSansBold
    actionButton.Parent = petCard
    
    local actionCorner = Instance.new("UICorner")
    actionCorner.CornerRadius = UDim.new(0, 6)
    actionCorner.Parent = actionButton
    
    if cardType == "shop" then
        if isOwned then
            actionButton.BackgroundColor3 = Color3.new(0.5, 0.5, 0.5)
            actionButton.Text = "OWNED"
            actionButton.TextColor3 = Color3.new(0.8, 0.8, 0.8)
        else
            actionButton.BackgroundColor3 = Color3.new(0.2, 0.8, 0.2)
            actionButton.Text = "BUY " .. petData.price .. (petData.currency == "coins" and " 🪙" or " R$")
            actionButton.TextColor3 = Color3.new(1, 1, 1)
            
            actionButton.MouseButton1Click:Connect(function()
                self:PurchasePet(petData.id)
            end)
        end
        
    elseif cardType == "collection" then
        if isActive then
            actionButton.BackgroundColor3 = Color3.new(1, 0.8, 0.2)
            actionButton.Text = "ACTIVE"
            actionButton.TextColor3 = Color3.new(0, 0, 0)
        else
            actionButton.BackgroundColor3 = Color3.new(0.2, 0.8, 0.2)
            actionButton.Text = "EQUIP"
            actionButton.TextColor3 = Color3.new(1, 1, 1)
            
            actionButton.MouseButton1Click:Connect(function()
                self:EquipPet(petData.id)
            end)
        end
    end
    
    -- Active indicator
    if isActive then
        local activeIndicator = Instance.new("Frame")
        activeIndicator.Name = "ActiveIndicator"
        activeIndicator.Size = UDim2.new(0.3, 0, 0.15, 0)
        activeIndicator.Position = UDim2.new(0.65, 0, 0.05, 0)
        activeIndicator.BackgroundColor3 = Color3.new(1, 0.8, 0.2)
        activeIndicator.BorderSizePixel = 0
        activeIndicator.Parent = petCard
        
        local indicatorCorner = Instance.new("UICorner")
        indicatorCorner.CornerRadius = UDim.new(0, 4)
        indicatorCorner.Parent = activeIndicator
        
        local activeText = Instance.new("TextLabel")
        activeText.Size = UDim2.new(1, 0, 1, 0)
        activeText.BackgroundTransparency = 1
        activeText.Text = "⭐"
        activeText.TextColor3 = Color3.new(0, 0, 0)
        activeText.TextScaled = true
        activeText.Font = Enum.Font.SourceSansBold
        activeText.Parent = activeIndicator
    end
end

function PetController:PurchasePet(petId)
    print("🐾 Attempting to purchase pet: " .. petId)
    RemoteEvents.PurchasePet:FireServer(petId)
end

function PetController:EquipPet(petId)
    print("🐾 Attempting to equip pet: " .. petId)
    RemoteEvents.EquipPet:FireServer(petId)
end

function PetController:OpenPetShop(petDatabase, playerPetData)
    if not petShopGui then
        self:CreatePetShopGui()
    end
    
    currentPetDatabase = petDatabase
    currentPlayerPetData = playerPetData
    
    petShopGui.Enabled = true
    isShopOpen = true
    
    -- Animate open
    petShopFrame.Size = UDim2.new(0, 0, 0, 0)
    petShopFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
    
    local openTween = TweenService:Create(
        petShopFrame,
        TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
        {
            Size = UDim2.new(0.8, 0, 0.85, 0),
            Position = UDim2.new(0.1, 0, 0.075, 0)
        }
    )
    openTween:Play()
    
    -- Populate initial content
    self:ShowShopTab(petShopFrame.TabsFrame.ShopTab, petShopFrame.TabsFrame.CollectionTab, petShopFrame.TabsFrame.ActiveTab)
    
    print("🐾 Pet shop opened")
end

function PetController:ClosePetShop()
    if not isShopOpen then return end
    
    isShopOpen = false
    
    local closeTween = TweenService:Create(
        petShopFrame,
        TweenInfo.new(0.2, Enum.EasingStyle.Back, Enum.EasingDirection.In),
        {
            Size = UDim2.new(0, 0, 0, 0),
            Position = UDim2.new(0.5, 0, 0.5, 0)
        }
    )
    closeTween:Play()
    
    closeTween.Completed:Connect(function()
        petShopGui.Enabled = false
    end)
    
    print("🐾 Pet shop closed")
end

function PetController:ShowPurchaseResult(success, message, petId)
    if success then
        print("🐾 Pet purchase successful: " .. message)
        -- Refresh the shop to show updated owned status
        self:PopulateShopContent()
        self:PopulateCollectionContent()
        
        -- Play success sound
        if SoundService:FindFirstChild("PetPurchaseSuccess") then
            SoundService.PetPurchaseSuccess:Play()
        end
    else
        print("🐾 Pet purchase failed: " .. message)
        -- Show error notification
        self:ShowNotification("Purchase Failed: " .. message, Color3.new(1, 0.3, 0.3))
    end
end

function PetController:ShowEquipResult(success, message, petId)
    if success then
        print("🐾 Pet equip successful: " .. message)
        currentPlayerPetData.activePet = petId
        
        -- Refresh all tabs to show updated active status
        self:PopulateShopContent()
        self:PopulateCollectionContent()
        self:PopulateActiveContent()
        
        -- Play equip sound
        if SoundService:FindFirstChild("PetEquip") then
            SoundService.PetEquip:Play()
        end
    else
        print("🐾 Pet equip failed: " .. message)
        self:ShowNotification("Equip Failed: " .. message, Color3.new(1, 0.3, 0.3))
    end
end

function PetController:ShowNotification(text, color)
    -- Create temporary notification
    local notification = Instance.new("Frame")
    notification.Size = UDim2.new(0.3, 0, 0.08, 0)
    notification.Position = UDim2.new(0.35, 0, 0.1, 0)
    notification.BackgroundColor3 = color
    notification.BorderSizePixel = 0
    notification.Parent = player.PlayerGui
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 10)
    corner.Parent = notification
    
    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, 0, 1, 0)
    label.BackgroundTransparency = 1
    label.Text = text
    label.TextColor3 = Color3.new(1, 1, 1)
    label.TextScaled = true
    label.Font = Enum.Font.SourceSansBold
    label.Parent = notification
    
    -- Animate and destroy
    spawn(function()
        wait(3)
        local fadeTween = TweenService:Create(
            notification,
            TweenInfo.new(0.5, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut),
            {BackgroundTransparency = 1}
        )
        local textFadeTween = TweenService:Create(
            label,
            TweenInfo.new(0.5, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut),
            {TextTransparency = 1}
        )
        fadeTween:Play()
        textFadeTween:Play()
        
        fadeTween.Completed:Connect(function()
            notification:Destroy()
        end)
    end)
end

function PetController:Initialize()
    print("🐾 PetController initializing...")
    
    -- Handle ESC key to close shop
    UserInputService.InputBegan:Connect(function(input, gameProcessed)
        if gameProcessed then return end
        
        if input.KeyCode == Enum.KeyCode.Escape and isShopOpen then
            self:ClosePetShop()
        end
    end)
    
    print("✅ PetController initialized successfully!")
end

-- Remote event connections
RemoteEvents.ShowPetShop.OnClientEvent:Connect(function(petDatabase, playerPetData)
    PetController:OpenPetShop(petDatabase, playerPetData)
end)

RemoteEvents.PetPurchaseResult.OnClientEvent:Connect(function(success, message, petId)
    PetController:ShowPurchaseResult(success, message, petId)
end)

RemoteEvents.PetEquipResult.OnClientEvent:Connect(function(success, message, petId)
    PetController:ShowEquipResult(success, message, petId)
end)

-- Auto-initialize
PetController:Initialize()

return PetController
