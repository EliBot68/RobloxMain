-- ShopController.luau
-- Handles client-side shop UI and interactions

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local RemoteEvents = require(ReplicatedStorage.Shared.modules.RemoteEvents)
local GuiController = require(script.Parent.GuiController)

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local ShopController = {}
local shopGui = nil
local currentShopData = nil

function ShopController:CreateShopUI()
    -- Main shop GUI
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "ShopUI"
    screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    screenGui.Parent = playerGui
    
    -- Background overlay
    local overlay = Instance.new("Frame")
    overlay.Name = "Overlay"
    overlay.Size = UDim2.new(1, 0, 1, 0)
    overlay.BackgroundColor3 = Color3.new(0, 0, 0)
    overlay.BackgroundTransparency = 0.5
    overlay.BorderSizePixel = 0
    overlay.Visible = false
    overlay.Parent = screenGui
    
    -- Main shop frame
    local shopFrame = Instance.new("Frame")
    shopFrame.Name = "ShopFrame"
    shopFrame.Size = UDim2.new(0.8, 0, 0.8, 0)
    shopFrame.Position = UDim2.new(0.1, 0, 0.1, 0)
    shopFrame.BackgroundColor3 = Color3.new(0.95, 0.95, 0.95)
    shopFrame.BorderSizePixel = 0
    shopFrame.Parent = overlay
    
    -- Shop title
    local titleLabel = Instance.new("TextLabel")
    titleLabel.Name = "Title"
    titleLabel.Size = UDim2.new(1, 0, 0.1, 0)
    titleLabel.BackgroundTransparency = 1
    titleLabel.Text = "🎨 SKINS & TRAILS SHOP 🌟"
    titleLabel.TextColor3 = Color3.new(0.2, 0.2, 0.8)
    titleLabel.TextScaled = true
    titleLabel.Font = Enum.Font.SourceSansBold
    titleLabel.Parent = shopFrame
    
    -- Coins display
    local coinsLabel = Instance.new("TextLabel")
    coinsLabel.Name = "CoinsLabel"
    coinsLabel.Size = UDim2.new(0.3, 0, 0.08, 0)
    coinsLabel.Position = UDim2.new(0.05, 0, 0.12, 0)
    coinsLabel.BackgroundColor3 = Color3.new(1, 0.9, 0.2)
    coinsLabel.BorderSizePixel = 0
    coinsLabel.Text = "💰 Coins: 0"
    coinsLabel.TextColor3 = Color3.new(0.2, 0.2, 0.2)
    coinsLabel.TextScaled = true
    coinsLabel.Font = Enum.Font.SourceSansBold
    coinsLabel.Parent = shopFrame
    
    -- Close button
    local closeButton = Instance.new("TextButton")
    closeButton.Name = "CloseButton"
    closeButton.Size = UDim2.new(0.1, 0, 0.08, 0)
    closeButton.Position = UDim2.new(0.85, 0, 0.12, 0)
    closeButton.BackgroundColor3 = Color3.new(0.8, 0.2, 0.2)
    closeButton.BorderSizePixel = 0
    closeButton.Text = "✕"
    closeButton.TextColor3 = Color3.new(1, 1, 1)
    closeButton.TextScaled = true
    closeButton.Font = Enum.Font.SourceSansBold
    closeButton.Parent = shopFrame
    
    closeButton.MouseButton1Click:Connect(function()
        self:CloseShop()
    end)
    
    -- Tabs frame
    local tabsFrame = Instance.new("Frame")
    tabsFrame.Name = "TabsFrame"
    tabsFrame.Size = UDim2.new(0.9, 0, 0.08, 0)
    tabsFrame.Position = UDim2.new(0.05, 0, 0.22, 0)
    tabsFrame.BackgroundTransparency = 1
    tabsFrame.Parent = shopFrame
    
    -- Skins tab
    local skinsTab = Instance.new("TextButton")
    skinsTab.Name = "SkinsTab"
    skinsTab.Size = UDim2.new(0.33, -5, 1, 0)
    skinsTab.Position = UDim2.new(0, 0, 0, 0)
    skinsTab.BackgroundColor3 = Color3.new(0.2, 0.6, 1)
    skinsTab.BorderSizePixel = 0
    skinsTab.Text = "🎨 SKINS"
    skinsTab.TextColor3 = Color3.new(1, 1, 1)
    skinsTab.TextScaled = true
    skinsTab.Font = Enum.Font.SourceSansBold
    skinsTab.Parent = tabsFrame
    
    -- Trails tab
    local trailsTab = Instance.new("TextButton")
    trailsTab.Name = "TrailsTab"
    trailsTab.Size = UDim2.new(0.33, -5, 1, 0)
    trailsTab.Position = UDim2.new(0.33, 3, 0, 0)
    trailsTab.BackgroundColor3 = Color3.new(0.6, 0.6, 0.6)
    trailsTab.BorderSizePixel = 0
    trailsTab.Text = "🌟 TRAILS"
    trailsTab.TextColor3 = Color3.new(1, 1, 1)
    trailsTab.TextScaled = true
    trailsTab.Font = Enum.Font.SourceSansBold
    trailsTab.Parent = tabsFrame
    
    -- Robux tab
    local robuxTab = Instance.new("TextButton")
    robuxTab.Name = "RobuxTab"
    robuxTab.Size = UDim2.new(0.33, -5, 1, 0)
    robuxTab.Position = UDim2.new(0.66, 5, 0, 0)
    robuxTab.BackgroundColor3 = Color3.new(0.6, 0.6, 0.6)
    robuxTab.BorderSizePixel = 0
    robuxTab.Text = "💎 ROBUX"
    robuxTab.TextColor3 = Color3.new(1, 1, 1)
    robuxTab.TextScaled = true
    robuxTab.Font = Enum.Font.SourceSansBold
    robuxTab.Parent = tabsFrame
    
    -- Items scroll frame
    local scrollFrame = Instance.new("ScrollingFrame")
    scrollFrame.Name = "ItemsScrollFrame"
    scrollFrame.Size = UDim2.new(0.9, 0, 0.58, 0)
    scrollFrame.Position = UDim2.new(0.05, 0, 0.32, 0)
    scrollFrame.BackgroundColor3 = Color3.new(0.9, 0.9, 0.9)
    scrollFrame.BorderSizePixel = 0
    scrollFrame.ScrollBarThickness = 8
    scrollFrame.Parent = shopFrame
    
    -- Tab functionality
    skinsTab.MouseButton1Click:Connect(function()
        self:ShowCategory("skin")
        skinsTab.BackgroundColor3 = Color3.new(0.2, 0.6, 1)
        trailsTab.BackgroundColor3 = Color3.new(0.6, 0.6, 0.6)
        robuxTab.BackgroundColor3 = Color3.new(0.6, 0.6, 0.6)
    end)
    
    trailsTab.MouseButton1Click:Connect(function()
        self:ShowCategory("trail")
        trailsTab.BackgroundColor3 = Color3.new(0.2, 0.6, 1)
        skinsTab.BackgroundColor3 = Color3.new(0.6, 0.6, 0.6)
        robuxTab.BackgroundColor3 = Color3.new(0.6, 0.6, 0.6)
    end)
    
    robuxTab.MouseButton1Click:Connect(function()
        self:ShowCategory("robux")
        robuxTab.BackgroundColor3 = Color3.new(0.2, 0.6, 1)
        skinsTab.BackgroundColor3 = Color3.new(0.6, 0.6, 0.6)
        trailsTab.BackgroundColor3 = Color3.new(0.6, 0.6, 0.6)
    end)
    
    return screenGui
end

function ShopController:CreateItemFrame(item, index)
    local scrollFrame = shopGui.Overlay.ShopFrame.ItemsScrollFrame
    
    local itemFrame = Instance.new("Frame")
    itemFrame.Name = "Item_" .. item.id
    itemFrame.Size = UDim2.new(0.45, 0, 0, 120)
    itemFrame.Position = UDim2.new(
        (index % 2) * 0.5 + 0.025, 0,
        0, math.floor(index / 2) * 130 + 10
    )
    itemFrame.BackgroundColor3 = Color3.new(1, 1, 1)
    itemFrame.BorderSizePixel = 1
    itemFrame.BorderColor3 = Color3.new(0.8, 0.8, 0.8)
    itemFrame.Parent = scrollFrame
    
    -- Color preview
    local colorPreview = Instance.new("Frame")
    colorPreview.Size = UDim2.new(0.25, 0, 0.6, 0)
    colorPreview.Position = UDim2.new(0.05, 0, 0.2, 0)
    colorPreview.BackgroundColor3 = item.color
    colorPreview.BorderSizePixel = 2
    colorPreview.BorderColor3 = Color3.new(0.5, 0.5, 0.5)
    colorPreview.Parent = itemFrame
    
    -- Item name
    local nameLabel = Instance.new("TextLabel")
    nameLabel.Size = UDim2.new(0.65, 0, 0.4, 0)
    nameLabel.Position = UDim2.new(0.32, 0, 0.05, 0)
    nameLabel.BackgroundTransparency = 1
    nameLabel.Text = item.name
    nameLabel.TextColor3 = Color3.new(0.2, 0.2, 0.2)
    nameLabel.TextScaled = true
    nameLabel.Font = Enum.Font.SourceSansBold
    nameLabel.Parent = itemFrame
    
    -- Price label
    local priceLabel = Instance.new("TextLabel")
    priceLabel.Size = UDim2.new(0.65, 0, 0.25, 0)
    priceLabel.Position = UDim2.new(0.32, 0, 0.4, 0)
    priceLabel.BackgroundTransparency = 1
    priceLabel.Text = "💰 " .. item.price .. " coins"
    priceLabel.TextColor3 = Color3.new(0.8, 0.6, 0.2)
    priceLabel.TextScaled = true
    priceLabel.Font = Enum.Font.SourceSans
    priceLabel.Parent = itemFrame
    
    -- Action button
    local actionButton = Instance.new("TextButton")
    actionButton.Size = UDim2.new(0.65, 0, 0.25, 0)
    actionButton.Position = UDim2.new(0.32, 0, 0.7, 0)
    actionButton.BorderSizePixel = 0
    actionButton.TextScaled = true
    actionButton.Font = Enum.Font.SourceSansBold
    actionButton.Parent = itemFrame
    
    -- Determine button state
    local isOwned = false
    local isEquipped = false
    
    if item.category == "skin" then
        isOwned = currentShopData.ownedSkins[item.id] or false
        isEquipped = currentShopData.equippedSkin == item.id
    elseif item.category == "trail" then
        isOwned = currentShopData.ownedTrails[item.id] or false
        isEquipped = currentShopData.equippedTrail == item.id
    end
    
    if isEquipped then
        actionButton.Text = "EQUIPPED"
        actionButton.BackgroundColor3 = Color3.new(0.2, 0.8, 0.2)
        actionButton.TextColor3 = Color3.new(1, 1, 1)
    elseif isOwned then
        actionButton.Text = "EQUIP"
        actionButton.BackgroundColor3 = Color3.new(0.2, 0.6, 1)
        actionButton.TextColor3 = Color3.new(1, 1, 1)
        actionButton.MouseButton1Click:Connect(function()
            self:EquipItem(item.id, item.category)
        end)
    else
        if currentShopData.playerCoins >= item.price then
            actionButton.Text = "BUY"
            actionButton.BackgroundColor3 = Color3.new(0.2, 0.8, 0.2)
            actionButton.TextColor3 = Color3.new(1, 1, 1)
            actionButton.MouseButton1Click:Connect(function()
                self:PurchaseItem(item.id)
            end)
        else
            actionButton.Text = "NOT ENOUGH COINS"
            actionButton.BackgroundColor3 = Color3.new(0.6, 0.6, 0.6)
            actionButton.TextColor3 = Color3.new(0.4, 0.4, 0.4)
        end
    end
    
    return itemFrame
end

function ShopController:CreateRobuxItemFrame(item, index, itemType)
    local scrollFrame = shopGui.Overlay.ShopFrame.ItemsScrollFrame
    
    local itemFrame = Instance.new("Frame")
    itemFrame.Name = itemType .. "_" .. (item.key or item.name)
    itemFrame.Size = UDim2.new(0.9, 0, 0, 100)
    
    -- Position items vertically for robux items
    local yPos = index * 110 + 10
    itemFrame.Position = UDim2.new(0.05, 0, 0, yPos)
    itemFrame.BackgroundColor3 = Color3.new(0.95, 0.95, 0.95)
    itemFrame.BorderSizePixel = 2
    itemFrame.BorderColor3 = Color3.new(0.8, 0.8, 0.8)
    itemFrame.Parent = scrollFrame
    
    -- Item icon/symbol
    local iconLabel = Instance.new("TextLabel")
    iconLabel.Size = UDim2.new(0, 80, 0, 80)
    iconLabel.Position = UDim2.new(0, 10, 0, 10)
    iconLabel.BackgroundColor3 = (itemType == "gamepass") and Color3.new(1, 0.8, 0) or Color3.new(0.2, 0.8, 0.2)
    iconLabel.BorderSizePixel = 0
    iconLabel.Text = (itemType == "gamepass") and "🎫" or "💰"
    iconLabel.TextColor3 = Color3.new(1, 1, 1)
    iconLabel.TextScaled = true
    iconLabel.Font = Enum.Font.SourceSansBold
    iconLabel.Parent = itemFrame
    
    -- Item name
    local nameLabel = Instance.new("TextLabel")
    nameLabel.Size = UDim2.new(0.4, 0, 0.4, 0)
    nameLabel.Position = UDim2.new(0, 100, 0, 5)
    nameLabel.BackgroundTransparency = 1
    nameLabel.Text = item.name
    nameLabel.TextColor3 = Color3.new(0.2, 0.2, 0.2)
    nameLabel.TextScaled = true
    nameLabel.Font = Enum.Font.SourceSansBold
    nameLabel.TextXAlignment = Enum.TextXAlignment.Left
    nameLabel.Parent = itemFrame
    
    -- Item description
    local descLabel = Instance.new("TextLabel")
    descLabel.Size = UDim2.new(0.4, 0, 0.5, 0)
    descLabel.Position = UDim2.new(0, 100, 0.4, 0)
    descLabel.BackgroundTransparency = 1
    descLabel.Text = item.description
    descLabel.TextColor3 = Color3.new(0.5, 0.5, 0.5)
    descLabel.TextScaled = true
    descLabel.Font = Enum.Font.SourceSans
    descLabel.TextXAlignment = Enum.TextXAlignment.Left
    descLabel.TextWrapped = true
    descLabel.Parent = itemFrame
    
    -- Purchase button
    local purchaseButton = Instance.new("TextButton")
    purchaseButton.Size = UDim2.new(0, 120, 0, 40)
    purchaseButton.Position = UDim2.new(1, -130, 0.5, -20)
    purchaseButton.BackgroundColor3 = (itemType == "gamepass") and Color3.new(1, 0.7, 0) or Color3.new(0.2, 0.7, 0.2)
    purchaseButton.BorderSizePixel = 0
    purchaseButton.Text = (itemType == "gamepass") and "BUY GAMEPASS" or "BUY NOW"
    purchaseButton.TextColor3 = Color3.new(1, 1, 1)
    purchaseButton.TextScaled = true
    purchaseButton.Font = Enum.Font.SourceSansBold
    purchaseButton.Parent = itemFrame
    
    -- Purchase button click
    purchaseButton.MouseButton1Click:Connect(function()
        if itemType == "gamepass" then
            RemoteEvents.PromptGamepassPurchase:FireServer(item.key)
        elseif itemType == "product" then
            RemoteEvents.PromptProductPurchase:FireServer(item.key)
        else
            -- Use new purchase confirmation system for coin purchases
            local purchaseData = {
                itemType = "shop_item",
                itemId = item.key,
                name = item.name,
                description = item.description,
                price = item.price,
                icon = item.icon or "🎁"
            }
            RemoteEvents.ShowPurchaseConfirmation:FireServer(purchaseData)
        end
    end)
    
    return itemFrame
end

function ShopController:ShowCategory(category)
    local scrollFrame = shopGui.Overlay.ShopFrame.ItemsScrollFrame
    
    -- Clear existing items
    for _, child in pairs(scrollFrame:GetChildren()) do
        if child.Name:sub(1, 5) == "Item_" or child.Name:sub(1, 9) == "gamepass_" or child.Name:sub(1, 8) == "product_" then
            child:Destroy()
        end
    end
    
    if category == "robux" then
        -- Show robux items (gamepasses and developer products)
        local index = 0
        
        -- Add gamepasses
        if currentShopData.monetization and currentShopData.monetization.gamepasses then
            for key, gamepass in pairs(currentShopData.monetization.gamepasses) do
                local item = {
                    key = key,
                    name = gamepass.name,
                    description = gamepass.description
                }
                self:CreateRobuxItemFrame(item, index, "gamepass")
                index = index + 1
            end
        end
        
        -- Add developer products
        if currentShopData.monetization and currentShopData.monetization.developerProducts then
            for key, product in pairs(currentShopData.monetization.developerProducts) do
                local item = {
                    key = key,
                    name = product.name,
                    description = product.description
                }
                self:CreateRobuxItemFrame(item, index, "product")
                index = index + 1
            end
        end
        
        -- Update scroll frame size for vertical layout
        scrollFrame.CanvasSize = UDim2.new(0, 0, 0, index * 110 + 20)
    else
        -- Add regular items for skin/trail categories
        local index = 0
        for _, item in pairs(currentShopData.items) do
            if item.category == category then
                self:CreateItemFrame(item, index)
                index = index + 1
            end
        end
        
        -- Update scroll frame size for grid layout
        local rows = math.ceil(index / 2)
        scrollFrame.CanvasSize = UDim2.new(0, 0, 0, rows * 130 + 20)
    end
end

function ShopController:UpdateCoinsDisplay()
    if shopGui then
        local coinsLabel = shopGui.Overlay.ShopFrame.CoinsLabel
        coinsLabel.Text = "💰 Coins: " .. (currentShopData.playerCoins or 0)
    end
end

function ShopController:OpenShop(shopData)
    currentShopData = shopData
    
    if not shopGui then
        shopGui = self:CreateShopUI()
    end
    
    self:UpdateCoinsDisplay()
    
    -- Show skins by default
    self:ShowCategory("skin")
    
    -- Animate in
    local overlay = shopGui.Overlay
    overlay.Visible = true
    overlay.BackgroundTransparency = 1
    
    local shopFrame = overlay.ShopFrame
    shopFrame.Size = UDim2.new(0, 0, 0, 0)
    shopFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
    
    local bgTween = TweenService:Create(
        overlay,
        TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
        {BackgroundTransparency = 0.5}
    )
    
    local frameTween = TweenService:Create(
        shopFrame,
        TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
        {
            Size = UDim2.new(0.8, 0, 0.8, 0),
            Position = UDim2.new(0.1, 0, 0.1, 0)
        }
    )
    
    bgTween:Play()
    frameTween:Play()
end

function ShopController:CloseShop()
    if not shopGui then return end
    
    local overlay = shopGui.Overlay
    local shopFrame = overlay.ShopFrame
    
    local bgTween = TweenService:Create(
        overlay,
        TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
        {BackgroundTransparency = 1}
    )
    
    local frameTween = TweenService:Create(
        shopFrame,
        TweenInfo.new(0.2, Enum.EasingStyle.Back, Enum.EasingDirection.In),
        {
            Size = UDim2.new(0, 0, 0, 0),
            Position = UDim2.new(0.5, 0, 0.5, 0)
        }
    )
    
    frameTween.Completed:Connect(function()
        overlay.Visible = false
    end)
    
    bgTween:Play()
    frameTween:Play()
end

function ShopController:PurchaseItem(itemId)
    RemoteEvents.PurchaseShopItem:FireServer(itemId)
end

function ShopController:EquipItem(itemId, category)
    RemoteEvents.EquipShopItem:FireServer(itemId, category)
end

function ShopController:Init()
    -- Handle remote events
    RemoteEvents.OpenShop.OnClientEvent:Connect(function(shopData)
        self:OpenShop(shopData)
    end)
    
    RemoteEvents.ShopPurchaseResult.OnClientEvent:Connect(function(success, message, itemId)
        if success then
            print("✅ Purchase successful: " .. message)
            -- Refresh shop data
            RemoteEvents.RequestShopData:FireServer()
        else
            print("❌ Purchase failed: " .. message)
        end
    end)
    
    RemoteEvents.ShopEquipResult.OnClientEvent:Connect(function(success, message, itemId, category)
        if success then
            print("✅ Item equipped: " .. message)
            -- Refresh shop data
            RemoteEvents.RequestShopData:FireServer()
        else
            print("❌ Equip failed: " .. message)
        end
    end)
    
    -- Handle monetization purchase results
    RemoteEvents.GamepassPurchaseResult.OnClientEvent:Connect(function(result)
        if result.success then
            if result.alreadyOwned then
                GuiController:ShowNotification("🎫 You already own " .. result.gamepassName .. "!", Color3.new(0, 0.8, 0))
            else
                GuiController:ShowNotification("🎫 " .. result.gamepassName .. " purchased! " .. (result.benefits or ""), Color3.new(0, 0.8, 0))
            end
        else
            GuiController:ShowNotification("❌ Purchase failed: " .. (result.error or "Unknown error"), Color3.new(0.8, 0, 0))
        end
    end)
    
    RemoteEvents.ProductPurchaseResult.OnClientEvent:Connect(function(result)
        if result.success then
            GuiController:ShowNotification("💰 " .. result.productName .. " purchased! Received " .. result.coinsReceived .. " coins!", Color3.new(0, 0.8, 0))
        else
            GuiController:ShowNotification("❌ Purchase failed: " .. (result.error or "Unknown error"), Color3.new(0.8, 0, 0))
        end
    end)
    
    RemoteEvents.MonetizationInfoUpdated.OnClientEvent:Connect(function(monetizationInfo)
        if currentShopData then
            currentShopData.monetization = monetizationInfo
        end
    end)
    
    -- Request monetization data when shop is opened
    RemoteEvents.RequestMonetizationInfo:FireServer()
    
    print("✅ ShopController initialized")
end

return ShopController
