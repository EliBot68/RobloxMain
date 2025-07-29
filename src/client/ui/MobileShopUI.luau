-- MobileShopUI.luau
-- Mobile-optimized shop interface with responsive design

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

local SafeRequire = require(ReplicatedStorage.Shared.utils.SafeRequire)
local RemoteEvents = SafeRequire.require(ReplicatedStorage.Shared.modules.RemoteEvents)
local MobileOptimizationService = require(script.Parent.Parent.services.MobileOptimizationService)

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local MobileShopUI = {}

-- Shop data and state
local shopData = {
    categories = {"Skins", "Trails", "Buffs", "Pets", "Gamepasses"},
    currentCategory = "Skins",
    items = {},
    playerCoins = 0,
    isVisible = false
}

local shopGui = nil
local currentModal = nil

-- Create mobile-optimized shop interface
function MobileShopUI.createShopUI()
    local layoutProps = MobileOptimizationService.getLayoutProperties()
    
    -- Create modal for shop
    currentModal = MobileOptimizationService.createMobileModal({
        title = "🛍️ Shop",
        height = math.min(layoutProps.screenSize.Y * 0.8, 600),
        backgroundColor = Color3.fromRGB(248, 249, 250),
        titleBackgroundColor = Color3.fromRGB(52, 152, 219),
        closeOnBackgroundTap = true
    })
    
    shopGui = currentModal.modal
    local contentArea = currentModal.contentArea
    
    -- Create shop layout
    MobileShopUI.createShopContent(contentArea, layoutProps)
    
    -- Request shop data from server
    if RemoteEvents.RequestShopData then
        RemoteEvents.RequestShopData:FireServer()
    end
    
    shopData.isVisible = true
    return currentModal
end

-- Create shop content layout
function MobileShopUI.createShopContent(parent, layoutProps)
    local config = layoutProps.config
    
    -- Main layout frame
    local mainLayout = Instance.new("UIListLayout")
    mainLayout.FillDirection = Enum.FillDirection.Vertical
    mainLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
    mainLayout.VerticalAlignment = Enum.VerticalAlignment.Top
    mainLayout.Padding = UDim.new(0, config.padding.medium)
    mainLayout.Parent = parent
    
    -- Player coins display
    local coinsFrame = Instance.new("Frame")
    coinsFrame.Name = "CoinsFrame"
    coinsFrame.Size = UDim2.new(1, 0, 0, 50)
    coinsFrame.BackgroundColor3 = Color3.fromRGB(241, 196, 15)
    coinsFrame.BorderSizePixel = 0
    coinsFrame.Parent = parent
    
    local coinsCorner = Instance.new("UICorner")
    coinsCorner.CornerRadius = UDim.new(0, 8)
    coinsCorner.Parent = coinsFrame
    
    local coinsIcon = Instance.new("TextLabel")
    coinsIcon.Size = UDim2.new(0, 40, 1, 0)
    coinsIcon.Position = UDim2.new(0, 0, 0, 0)
    coinsIcon.BackgroundTransparency = 1
    coinsIcon.Text = "💰"
    coinsIcon.TextSize = config.fontSize.large
    coinsIcon.TextXAlignment = Enum.TextXAlignment.Center
    coinsIcon.Parent = coinsFrame
    
    local coinsLabel = Instance.new("TextLabel")
    coinsLabel.Name = "CoinsLabel"
    coinsLabel.Size = UDim2.new(1, -50, 1, 0)
    coinsLabel.Position = UDim2.new(0, 45, 0, 0)
    coinsLabel.BackgroundTransparency = 1
    coinsLabel.Text = string.format("Coins: %d", shopData.playerCoins)
    coinsLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    coinsLabel.TextSize = config.fontSize.large
    coinsLabel.Font = Enum.Font.SourceSansBold
    coinsLabel.TextXAlignment = Enum.TextXAlignment.Left
    coinsLabel.Parent = coinsFrame
    
    -- Category tabs (horizontal scroll on mobile)
    local tabsFrame = Instance.new("Frame")
    tabsFrame.Name = "TabsFrame"
    tabsFrame.Size = UDim2.new(1, 0, 0, 60)
    tabsFrame.BackgroundTransparency = 1
    tabsFrame.Parent = parent
    
    local tabsScrollFrame = MobileOptimizationService.createMobileScrollFrame({
        size = UDim2.new(1, 0, 1, 0),
        backgroundColor = Color3.fromRGB(255, 255, 255),
        backgroundTransparency = 1,
        scrollingDirection = Enum.ScrollingDirection.X,
        canvasSize = UDim2.new(0, #shopData.categories * 120, 1, 0),
        parent = tabsFrame
    })
    
    local tabsLayout = Instance.new("UIListLayout")
    tabsLayout.FillDirection = Enum.FillDirection.Horizontal
    tabsLayout.HorizontalAlignment = Enum.HorizontalAlignment.Left
    tabsLayout.VerticalAlignment = Enum.VerticalAlignment.Center
    tabsLayout.Padding = UDim.new(0, config.padding.small)
    tabsLayout.Parent = tabsScrollFrame
    
    -- Create category tabs
    for i, category in ipairs(shopData.categories) do
        local tabButton = MobileOptimizationService.createMobileButton({
            size = UDim2.new(0, 110, 0, 40),
            backgroundColor = category == shopData.currentCategory and Color3.fromRGB(52, 152, 219) or Color3.fromRGB(149, 165, 166),
            text = category,
            textColor = Color3.fromRGB(255, 255, 255),
            parent = tabsScrollFrame
        })
        
        tabButton.MouseButton1Click:Connect(function()
            MobileShopUI.switchCategory(category, tabsScrollFrame)
        end)
    end
    
    -- Items container
    local itemsContainer = Instance.new("Frame")
    itemsContainer.Name = "ItemsContainer"
    itemsContainer.Size = UDim2.new(1, 0, 1, -160) -- Remaining space after header elements
    itemsContainer.BackgroundTransparency = 1
    itemsContainer.Parent = parent
    
    -- Items scroll frame
    local itemsScrollFrame = MobileOptimizationService.createMobileScrollFrame({
        size = UDim2.new(1, 0, 1, 0),
        backgroundColor = Color3.fromRGB(255, 255, 255),
        backgroundTransparency = 1,
        useListLayout = false,
        parent = itemsContainer
    })
    
    -- Items grid layout
    local itemsGrid = Instance.new("UIGridLayout")
    itemsGrid.CellSize = UDim2.new(0, layoutProps.deviceType == "Phone" and 150 or 180, 0, layoutProps.deviceType == "Phone" and 200 : 220)
    itemsGrid.CellPadding = UDim2.new(0, config.padding.medium, 0, config.padding.medium)
    itemsGrid.HorizontalAlignment = Enum.HorizontalAlignment.Center
    itemsGrid.VerticalAlignment = Enum.VerticalAlignment.Top
    itemsGrid.StartCorner = Enum.StartCorner.TopLeft
    itemsGrid.FillDirection = Enum.FillDirection.Horizontal
    itemsGrid.SortOrder = Enum.SortOrder.LayoutOrder
    itemsGrid.Parent = itemsScrollFrame
    
    -- Update canvas size when grid content changes
    itemsGrid:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        itemsScrollFrame.CanvasSize = UDim2.new(0, 0, 0, itemsGrid.AbsoluteContentSize.Y + config.padding.large)
    end)
    
    -- Store references
    shopGui.CoinsLabel = coinsLabel
    shopGui.TabsScrollFrame = tabsScrollFrame
    shopGui.ItemsScrollFrame = itemsScrollFrame
    
    -- Load initial category items
    MobileShopUI.loadCategoryItems(shopData.currentCategory)
end

-- Switch shop category
function MobileShopUI.switchCategory(category, tabsFrame)
    shopData.currentCategory = category
    
    -- Update tab appearances
    for _, tab in pairs(tabsFrame:GetChildren()) do
        if tab:IsA("TextButton") then
            if tab.Text == category then
                tab.BackgroundColor3 = Color3.fromRGB(52, 152, 219)
            else
                tab.BackgroundColor3 = Color3.fromRGB(149, 165, 166)
            end
        end
    end
    
    -- Load category items
    MobileShopUI.loadCategoryItems(category)
end

-- Load items for category
function MobileShopUI.loadCategoryItems(category)
    if not shopGui or not shopGui.ItemsScrollFrame then return end
    
    local itemsScrollFrame = shopGui.ItemsScrollFrame
    local layoutProps = MobileOptimizationService.getLayoutProperties()
    local config = layoutProps.config
    
    -- Clear existing items
    for _, child in pairs(itemsScrollFrame:GetChildren()) do
        if child:IsA("Frame") and child.Name ~= "UIGridLayout" then
            child:Destroy()
        end
    end
    
    -- Mock shop items data
    local categoryItems = MobileShopUI.getMockItems(category)
    
    -- Create item cards
    for i, item in ipairs(categoryItems) do
        local itemCard = Instance.new("Frame")
        itemCard.Name = "ItemCard_" .. i
        itemCard.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
        itemCard.BorderSizePixel = 0
        itemCard.LayoutOrder = i
        itemCard.Parent = itemsScrollFrame
        
        local cardCorner = Instance.new("UICorner")
        cardCorner.CornerRadius = UDim.new(0, 8)
        cardCorner.Parent = itemCard
        
        -- Drop shadow effect
        local shadow = Instance.new("Frame")
        shadow.Size = UDim2.new(1, 4, 1, 4)
        shadow.Position = UDim2.new(0, -2, 0, -2)
        shadow.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
        shadow.BackgroundTransparency = 0.9
        shadow.ZIndex = itemCard.ZIndex - 1
        shadow.Parent = itemCard
        
        local shadowCorner = Instance.new("UICorner")
        shadowCorner.CornerRadius = UDim.new(0, 8)
        shadowCorner.Parent = shadow
        
        -- Item image/preview
        local itemImage = Instance.new("Frame")
        itemImage.Size = UDim2.new(1, -20, 0, 80)
        itemImage.Position = UDim2.new(0, 10, 0, 10)
        itemImage.BackgroundColor3 = item.previewColor or Color3.fromRGB(200, 200, 200)
        itemImage.BorderSizePixel = 0
        itemImage.Parent = itemCard
        
        local imageCorner = Instance.new("UICorner")
        imageCorner.CornerRadius = UDim.new(0, 6)
        imageCorner.Parent = itemImage
        
        local itemIcon = Instance.new("TextLabel")
        itemIcon.Size = UDim2.new(1, 0, 1, 0)
        itemIcon.BackgroundTransparency = 1
        itemIcon.Text = item.icon or "🎨"
        itemIcon.TextSize = config.fontSize.title * 1.5
        itemIcon.TextXAlignment = Enum.TextXAlignment.Center
        itemIcon.Parent = itemImage
        
        -- Item name
        local itemName = Instance.new("TextLabel")
        itemName.Size = UDim2.new(1, -20, 0, 30)
        itemName.Position = UDim2.new(0, 10, 0, 95)
        itemName.BackgroundTransparency = 1
        itemName.Text = item.name
        itemName.TextColor3 = Color3.fromRGB(44, 62, 80)
        itemName.TextSize = config.fontSize.medium
        itemName.Font = Enum.Font.SourceSansBold
        itemName.TextWrapped = true
        itemName.TextXAlignment = Enum.TextXAlignment.Center
        itemName.Parent = itemCard
        
        -- Item price
        local priceFrame = Instance.new("Frame")
        priceFrame.Size = UDim2.new(1, -20, 0, 25)
        priceFrame.Position = UDim2.new(0, 10, 0, 130)
        priceFrame.BackgroundColor3 = Color3.fromRGB(241, 196, 15)
        priceFrame.BorderSizePixel = 0
        priceFrame.Parent = itemCard
        
        local priceCorner = Instance.new("UICorner")
        priceCorner.CornerRadius = UDim.new(0, 4)
        priceCorner.Parent = priceFrame
        
        local priceLabel = Instance.new("TextLabel")
        priceLabel.Size = UDim2.new(1, 0, 1, 0)
        priceLabel.BackgroundTransparency = 1
        priceLabel.Text = item.price > 0 and string.format("💰 %d", item.price) or "FREE"
        priceLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
        priceLabel.TextSize = config.fontSize.small
        priceLabel.Font = Enum.Font.SourceSansBold
        priceLabel.TextXAlignment = Enum.TextXAlignment.Center
        priceLabel.Parent = priceFrame
        
        -- Purchase button
        local purchaseButton = MobileOptimizationService.createMobileButton({
            size = UDim2.new(1, -20, 0, 35),
            position = UDim2.new(0, 10, 1, -45),
            backgroundColor = item.owned and Color3.fromRGB(46, 204, 113) or Color3.fromRGB(52, 152, 219),
            text = item.owned and "✓ OWNED" or "BUY",
            textColor = Color3.fromRGB(255, 255, 255),
            parent = itemCard
        })
        
        if not item.owned then
            purchaseButton.MouseButton1Click:Connect(function()
                MobileShopUI.purchaseItem(item, itemCard)
            end)
        end
        
        -- Add touch feedback animation
        local function addCardAnimation()
            local originalSize = itemCard.Size
            
            itemCard.MouseButton1Down:Connect(function()
                local shrinkTween = TweenService:Create(itemCard,
                    TweenInfo.new(0.1, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut),
                    {Size = UDim2.new(originalSize.X.Scale * 0.95, originalSize.X.Offset * 0.95, originalSize.Y.Scale * 0.95, originalSize.Y.Offset * 0.95)}
                )
                shrinkTween:Play()
            end)
            
            itemCard.MouseButton1Up:Connect(function()
                local expandTween = TweenService:Create(itemCard,
                    TweenInfo.new(0.1, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut),
                    {Size = originalSize}
                )
                expandTween:Play()
            end)
        end
        
        if layoutProps.touchEnabled then
            addCardAnimation()
        end
    end
end

-- Purchase item
function MobileShopUI.purchaseItem(item, itemCard)
    if shopData.playerCoins < item.price then
        MobileShopUI.showNotification("❌ Not enough coins!", Color3.fromRGB(231, 76, 60))
        return
    end
    
    -- Create confirmation modal
    local confirmModal = MobileOptimizationService.createMobileModal({
        title = "Confirm Purchase",
        height = 250,
        backgroundColor = Color3.fromRGB(255, 255, 255),
        closeOnBackgroundTap = true
    })
    
    local layoutProps = MobileOptimizationService.getLayoutProperties()
    local config = layoutProps.config
    
    -- Confirmation content
    local confirmText = Instance.new("TextLabel")
    confirmText.Size = UDim2.new(1, 0, 0, 60)
    confirmText.Position = UDim2.new(0, 0, 0, 20)
    confirmText.BackgroundTransparency = 1
    confirmText.Text = string.format("Purchase %s for %d coins?", item.name, item.price)
    confirmText.TextColor3 = Color3.fromRGB(44, 62, 80)
    confirmText.TextSize = config.fontSize.medium
    confirmText.Font = Enum.Font.SourceSans
    confirmText.TextWrapped = true
    confirmText.TextXAlignment = Enum.TextXAlignment.Center
    confirmText.Parent = confirmModal.contentArea
    
    -- Button container
    local buttonContainer = Instance.new("Frame")
    buttonContainer.Size = UDim2.new(1, 0, 0, 50)
    buttonContainer.Position = UDim2.new(0, 0, 1, -70)
    buttonContainer.BackgroundTransparency = 1
    buttonContainer.Parent = confirmModal.contentArea
    
    local buttonLayout = Instance.new("UIListLayout")
    buttonLayout.FillDirection = Enum.FillDirection.Horizontal
    buttonLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
    buttonLayout.VerticalAlignment = Enum.VerticalAlignment.Center
    buttonLayout.Padding = UDim.new(0, config.padding.medium)
    buttonLayout.Parent = buttonContainer
    
    -- Cancel button
    local cancelButton = MobileOptimizationService.createMobileButton({
        size = UDim2.new(0, 100, 1, 0),
        backgroundColor = Color3.fromRGB(149, 165, 166),
        text = "Cancel",
        parent = buttonContainer
    })
    
    cancelButton.MouseButton1Click:Connect(function()
        MobileOptimizationService.closeMobileModal(confirmModal.overlay)
    end)
    
    -- Confirm button
    local confirmButton = MobileOptimizationService.createMobileButton({
        size = UDim2.new(0, 100, 1, 0),
        backgroundColor = Color3.fromRGB(46, 204, 113),
        text = "Buy",
        parent = buttonContainer
    })
    
    confirmButton.MouseButton1Click:Connect(function()
        -- Send purchase request to server
        if RemoteEvents.PurchaseShopItem then
            RemoteEvents.PurchaseShopItem:FireServer(item.id, item.category)
        end
        
        MobileOptimizationService.closeMobileModal(confirmModal.overlay)
    end)
end

-- Show notification
function MobileShopUI.showNotification(message, color)
    local layoutProps = MobileOptimizationService.getLayoutProperties()
    local config = layoutProps.config
    
    local notification = Instance.new("Frame")
    notification.Size = UDim2.new(0.8, 0, 0, 60)
    notification.Position = UDim2.new(0.1, 0, 0.1, 0)
    notification.BackgroundColor3 = color or Color3.fromRGB(52, 152, 219)
    notification.BorderSizePixel = 0
    notification.Parent = playerGui
    
    local notifCorner = Instance.new("UICorner")
    notifCorner.CornerRadius = UDim.new(0, 8)
    notifCorner.Parent = notification
    
    local notifLabel = Instance.new("TextLabel")
    notifLabel.Size = UDim2.new(1, -20, 1, 0)
    notifLabel.Position = UDim2.new(0, 10, 0, 0)
    notifLabel.BackgroundTransparency = 1
    notifLabel.Text = message
    notifLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    notifLabel.TextSize = config.fontSize.medium
    notifLabel.Font = Enum.Font.SourceSansBold
    notifLabel.TextWrapped = true
    notifLabel.TextXAlignment = Enum.TextXAlignment.Center
    notifLabel.Parent = notification
    
    -- Animation
    notification.Position = UDim2.new(0.1, 0, -0.2, 0)
    local showTween = TweenService:Create(notification,
        TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
        {Position = UDim2.new(0.1, 0, 0.1, 0)}
    )
    showTween:Play()
    
    -- Auto-hide
    task.wait(3)
    local hideTween = TweenService:Create(notification,
        TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
        {Position = UDim2.new(0.1, 0, -0.2, 0)}
    )
    hideTween:Play()
    hideTween.Completed:Connect(function()
        notification:Destroy()
    end)
end

-- Get mock shop items
function MobileShopUI.getMockItems(category)
    local items = {
        Skins = {
            {id = "skin_blue", name = "Ocean Skin", price = 100, icon = "🌊", previewColor = Color3.fromRGB(52, 152, 219), owned = false, category = "Skins"},
            {id = "skin_fire", name = "Fire Skin", price = 150, icon = "🔥", previewColor = Color3.fromRGB(231, 76, 60), owned = false, category = "Skins"},
            {id = "skin_nature", name = "Nature Skin", price = 120, icon = "🌿", previewColor = Color3.fromRGB(46, 204, 113), owned = true, category = "Skins"},
            {id = "skin_galaxy", name = "Galaxy Skin", price = 500, icon = "🌌", previewColor = Color3.fromRGB(155, 89, 182), owned = false, category = "Skins"},
        },
        Trails = {
            {id = "trail_rainbow", name = "Rainbow Trail", price = 200, icon = "🌈", previewColor = Color3.fromRGB(241, 196, 15), owned = false, category = "Trails"},
            {id = "trail_fire", name = "Fire Trail", price = 180, icon = "🔥", previewColor = Color3.fromRGB(231, 76, 60), owned = false, category = "Trails"},
            {id = "trail_ice", name = "Ice Trail", price = 160, icon = "❄️", previewColor = Color3.fromRGB(174, 214, 241), owned = false, category = "Trails"},
        },
        Buffs = {
            {id = "buff_speed", name = "Speed Boost", price = 50, icon = "⚡", previewColor = Color3.fromRGB(241, 196, 15), owned = false, category = "Buffs"},
            {id = "buff_coins", name = "Coin Magnet", price = 75, icon = "🧲", previewColor = Color3.fromRGB(241, 196, 15), owned = false, category = "Buffs"},
            {id = "buff_shield", name = "Shield", price = 100, icon = "🛡️", previewColor = Color3.fromRGB(52, 152, 219), owned = false, category = "Buffs"},
        },
        Pets = {
            {id = "pet_dog", name = "Loyal Dog", price = 300, icon = "🐕", previewColor = Color3.fromRGB(205, 133, 63), owned = false, category = "Pets"},
            {id = "pet_cat", name = "Swift Cat", price = 250, icon = "🐱", previewColor = Color3.fromRGB(128, 128, 128), owned = false, category = "Pets"},
            {id = "pet_dragon", name = "Mini Dragon", price = 1000, icon = "🐉", previewColor = Color3.fromRGB(231, 76, 60), owned = false, category = "Pets"},
        },
        Gamepasses = {
            {id = "gp_vip", name = "VIP Pass", price = 0, icon = "👑", previewColor = Color3.fromRGB(241, 196, 15), owned = false, category = "Gamepasses", robux = 299},
            {id = "gp_2x_coins", name = "2x Coins", price = 0, icon = "💰", previewColor = Color3.fromRGB(46, 204, 113), owned = false, category = "Gamepasses", robux = 199},
        }
    }
    
    return items[category] or {}
end

-- Show mobile shop
function MobileShopUI.show()
    if shopData.isVisible then return end
    MobileShopUI.createShopUI()
end

-- Hide mobile shop
function MobileShopUI.hide()
    if currentModal then
        MobileOptimizationService.closeMobileModal(currentModal.overlay)
        currentModal = nil
        shopData.isVisible = false
    end
end

-- Update player coins
function MobileShopUI.updateCoins(coins)
    shopData.playerCoins = coins
    if shopGui and shopGui.CoinsLabel then
        shopGui.CoinsLabel.Text = string.format("Coins: %d", coins)
    end
end

-- Remote event connections
if RemoteEvents.OpenShop then
    RemoteEvents.OpenShop.OnClientEvent:Connect(function()
        MobileShopUI.show()
    end)
end

if RemoteEvents.ShopPurchaseResult then
    RemoteEvents.ShopPurchaseResult.OnClientEvent:Connect(function(success, message, newCoinBalance)
        if success then
            MobileShopUI.showNotification("✅ " .. (message or "Purchase successful!"), Color3.fromRGB(46, 204, 113))
            if newCoinBalance then
                MobileShopUI.updateCoins(newCoinBalance)
            end
            -- Refresh current category
            MobileShopUI.loadCategoryItems(shopData.currentCategory)
        else
            MobileShopUI.showNotification("❌ " .. (message or "Purchase failed!"), Color3.fromRGB(231, 76, 60))
        end
    end)
end

if RemoteEvents.CoinBalanceUpdated then
    RemoteEvents.CoinBalanceUpdated.OnClientEvent:Connect(function(newBalance)
        MobileShopUI.updateCoins(newBalance)
    end)
end

return MobileShopUI
