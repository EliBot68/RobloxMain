-- MonetizationShopController.luau
-- Handles the monetization shop interface with polished UI

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local MarketplaceService = game:GetService("MarketplaceService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local RemoteEvents = require(ReplicatedStorage.Shared.modules.RemoteEvents)

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local MonetizationShopController = {}

-- State tracking
local currentShopGui = nil
local monetizationData = {}
local ownedGamepasses = {}

function MonetizationShopController:CreateShopGUI()
    -- Create monetization shop GUI
    local shopGui = Instance.new("ScreenGui")
    shopGui.Name = "MonetizationShopGui"
    shopGui.ResetOnSpawn = false
    shopGui.IgnoreGuiInset = true
    shopGui.Parent = playerGui
    
    -- Dark overlay
    local overlay = Instance.new("Frame")
    overlay.Name = "Overlay"
    overlay.Size = UDim2.new(1, 0, 1, 0)
    overlay.Position = UDim2.new(0, 0, 0, 0)
    overlay.BackgroundColor3 = Color3.new(0, 0, 0)
    overlay.BackgroundTransparency = 0.5
    overlay.BorderSizePixel = 0
    overlay.Parent = shopGui
    
    -- Main shop container
    local shopContainer = Instance.new("Frame")
    shopContainer.Name = "ShopContainer"
    shopContainer.Size = UDim2.new(0, 800, 0, 600)
    shopContainer.Position = UDim2.new(0.5, -400, 0.5, -300)
    shopContainer.BackgroundColor3 = Color3.fromRGB(40, 40, 55)
    shopContainer.BorderSizePixel = 0
    shopContainer.Parent = shopGui
    
    local containerCorner = Instance.new("UICorner")
    containerCorner.CornerRadius = UDim.new(0, 20)
    containerCorner.Parent = shopContainer
    
    -- Gradient background
    local gradient = Instance.new("UIGradient")
    gradient.Color = ColorSequence.new{
        ColorSequenceKeypoint.new(0, Color3.fromRGB(50, 50, 70)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(30, 30, 50))
    }
    gradient.Rotation = 90
    gradient.Parent = shopContainer
    
    -- Title
    local title = Instance.new("TextLabel")
    title.Name = "Title"
    title.Size = UDim2.new(1, 0, 0, 60)
    title.Position = UDim2.new(0, 0, 0, 0)
    title.BackgroundTransparency = 1
    title.Text = "💎 Premium Shop"
    title.TextColor3 = Color3.fromRGB(255, 215, 0)
    title.TextSize = 28
    title.Font = Enum.Font.GothamBold
    title.Parent = shopContainer
    
    -- Close button
    local closeButton = Instance.new("TextButton")
    closeButton.Name = "CloseButton"
    closeButton.Size = UDim2.new(0, 40, 0, 40)
    closeButton.Position = UDim2.new(1, -50, 0, 10)
    closeButton.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
    closeButton.BorderSizePixel = 0
    closeButton.Text = "✕"
    closeButton.TextColor3 = Color3.new(1, 1, 1)
    closeButton.TextSize = 20
    closeButton.Font = Enum.Font.GothamBold
    closeButton.Parent = shopContainer
    
    local closeCorner = Instance.new("UICorner")
    closeCorner.CornerRadius = UDim.new(0, 8)
    closeCorner.Parent = closeButton
    
    -- Content area
    local contentFrame = Instance.new("ScrollingFrame")
    contentFrame.Name = "ContentFrame"
    contentFrame.Size = UDim2.new(1, -40, 1, -80)
    contentFrame.Position = UDim2.new(0, 20, 0, 70)
    contentFrame.BackgroundTransparency = 1
    contentFrame.BorderSizePixel = 0
    contentFrame.ScrollBarThickness = 8
    contentFrame.ScrollBarImageColor3 = Color3.fromRGB(100, 100, 120)
    contentFrame.CanvasSize = UDim2.new(0, 0, 0, 800)
    contentFrame.Parent = shopContainer
    
    -- Layout for items
    local layout = Instance.new("UIListLayout")
    layout.SortOrder = Enum.SortOrder.LayoutOrder
    layout.Padding = UDim.new(0, 20)
    layout.Parent = contentFrame
    
    -- Button connections
    closeButton.MouseButton1Click:Connect(function()
        self:CloseShop()
    end)
    
    overlay.MouseButton1Click:Connect(function()
        self:CloseShop()
    end)
    
    return shopGui
end

function MonetizationShopController:CreateGamepassItem(gamepassKey, gamepassData, layoutOrder)
    local contentFrame = currentShopGui:FindFirstChild("ShopContainer"):FindFirstChild("ContentFrame")
    
    -- Main item container
    local itemContainer = Instance.new("Frame")
    itemContainer.Name = gamepassKey .. "Container"
    itemContainer.Size = UDim2.new(1, 0, 0, 120)
    itemContainer.BackgroundColor3 = Color3.fromRGB(50, 50, 70)
    itemContainer.BorderSizePixel = 0
    itemContainer.LayoutOrder = layoutOrder
    itemContainer.Parent = contentFrame
    
    local itemCorner = Instance.new("UICorner")
    itemCorner.CornerRadius = UDim.new(0, 15)
    itemCorner.Parent = itemContainer
    
    -- Check if player owns this gamepass
    local isOwned = ownedGamepasses[gamepassKey] or false
    
    -- Special effects for Double Coins gamepass
    if gamepassKey == "doubleCoins" and not isOwned then
        -- Glowing effect background
        local glowFrame = Instance.new("Frame")
        glowFrame.Name = "GlowFrame"
        glowFrame.Size = UDim2.new(1, 4, 1, 4)
        glowFrame.Position = UDim2.new(0, -2, 0, -2)
        glowFrame.BackgroundColor3 = Color3.fromRGB(255, 215, 0)
        glowFrame.BorderSizePixel = 0
        glowFrame.ZIndex = itemContainer.ZIndex - 1
        glowFrame.Parent = itemContainer
        
        local glowCorner = Instance.new("UICorner")
        glowCorner.CornerRadius = UDim.new(0, 17)
        glowCorner.Parent = glowFrame
        
        -- Animate glow effect
        local glowTween = TweenService:Create(glowFrame, TweenInfo.new(1.5, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true), {
            BackgroundTransparency = 0.7
        })
        glowTween:Play()
        
        -- Premium gradient
        local premiumGradient = Instance.new("UIGradient")
        premiumGradient.Color = ColorSequence.new{
            ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 215, 0)),
            ColorSequenceKeypoint.new(0.5, Color3.fromRGB(255, 255, 100)),
            ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 215, 0))
        }
        premiumGradient.Parent = itemContainer
    end
    
    -- Icon
    local icon = Instance.new("TextLabel")
    icon.Name = "Icon"
    icon.Size = UDim2.new(0, 80, 0, 80)
    icon.Position = UDim2.new(0, 20, 0.5, -40)
    icon.BackgroundTransparency = 1
    icon.Text = gamepassData.icon
    icon.TextSize = 48
    icon.Font = Enum.Font.GothamBold
    icon.Parent = itemContainer
    
    -- Name
    local nameLabel = Instance.new("TextLabel")
    nameLabel.Name = "NameLabel"
    nameLabel.Size = UDim2.new(0, 300, 0, 30)
    nameLabel.Position = UDim2.new(0, 120, 0, 20)
    nameLabel.BackgroundTransparency = 1
    nameLabel.Text = gamepassData.name
    nameLabel.TextColor3 = Color3.new(1, 1, 1)
    nameLabel.TextSize = 20
    nameLabel.Font = Enum.Font.GothamBold
    nameLabel.TextXAlignment = Enum.TextXAlignment.Left
    nameLabel.Parent = itemContainer
    
    -- Description
    local descLabel = Instance.new("TextLabel")
    descLabel.Name = "DescLabel"
    descLabel.Size = UDim2.new(0, 300, 0, 50)
    descLabel.Position = UDim2.new(0, 120, 0, 50)
    descLabel.BackgroundTransparency = 1
    descLabel.Text = gamepassData.description
    descLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
    descLabel.TextSize = 14
    descLabel.Font = Enum.Font.Gotham
    descLabel.TextXAlignment = Enum.TextXAlignment.Left
    descLabel.TextYAlignment = Enum.TextYAlignment.Top
    descLabel.TextWrapped = true
    descLabel.Parent = itemContainer
    
    -- Purchase button
    local purchaseButton = Instance.new("TextButton")
    purchaseButton.Name = "PurchaseButton"
    purchaseButton.Size = UDim2.new(0, 140, 0, 40)
    purchaseButton.Position = UDim2.new(1, -160, 0.5, -20)
    purchaseButton.BorderSizePixel = 0
    purchaseButton.TextSize = 16
    purchaseButton.Font = Enum.Font.GothamBold
    purchaseButton.Parent = itemContainer
    
    local buttonCorner = Instance.new("UICorner")
    buttonCorner.CornerRadius = UDim.new(0, 8)
    buttonCorner.Parent = purchaseButton
    
    if isOwned then
        -- Owned state
        purchaseButton.BackgroundColor3 = Color3.fromRGB(50, 150, 50)
        purchaseButton.Text = "✅ OWNED"
        purchaseButton.TextColor3 = Color3.new(1, 1, 1)
        purchaseButton.Active = false
    else
        -- Available for purchase
        purchaseButton.BackgroundColor3 = Color3.fromRGB(0, 162, 255)
        purchaseButton.Text = gamepassData.price .. " R$"
        purchaseButton.TextColor3 = Color3.new(1, 1, 1)
        
        -- Purchase button animation
        purchaseButton.MouseEnter:Connect(function()
            local hoverTween = TweenService:Create(purchaseButton, TweenInfo.new(0.2), {
                BackgroundColor3 = Color3.fromRGB(30, 180, 255),
                Size = UDim2.new(0, 145, 0, 42)
            })
            hoverTween:Play()
        end)
        
        purchaseButton.MouseLeave:Connect(function()
            local leaveTween = TweenService:Create(purchaseButton, TweenInfo.new(0.2), {
                BackgroundColor3 = Color3.fromRGB(0, 162, 255),
                Size = UDim2.new(0, 140, 0, 40)
            })
            leaveTween:Play()
        end)
        
        purchaseButton.MouseButton1Click:Connect(function()
            self:PurchaseGamepass(gamepassKey, gamepassData)
        end)
    end
    
    return itemContainer
end

function MonetizationShopController:CreateProductItem(productKey, productData, layoutOrder)
    local contentFrame = currentShopGui:FindFirstChild("ShopContainer"):FindFirstChild("ContentFrame")
    
    -- Main item container
    local itemContainer = Instance.new("Frame")
    itemContainer.Name = productKey .. "Container"
    itemContainer.Size = UDim2.new(1, 0, 0, 120)
    itemContainer.BackgroundColor3 = Color3.fromRGB(50, 50, 70)
    itemContainer.BorderSizePixel = 0
    itemContainer.LayoutOrder = layoutOrder
    itemContainer.Parent = contentFrame
    
    local itemCorner = Instance.new("UICorner")
    itemCorner.CornerRadius = UDim.new(0, 15)
    itemCorner.Parent = itemContainer
    
    -- Special styling for crate keys
    if productKey == "crateKey" then
        local crateGradient = Instance.new("UIGradient")
        crateGradient.Color = ColorSequence.new{
            ColorSequenceKeypoint.new(0, Color3.fromRGB(120, 50, 200)),
            ColorSequenceKeypoint.new(1, Color3.fromRGB(80, 30, 150))
        }
        crateGradient.Rotation = 45
        crateGradient.Parent = itemContainer
    end
    
    -- Icon
    local icon = Instance.new("TextLabel")
    icon.Name = "Icon"
    icon.Size = UDim2.new(0, 80, 0, 80)
    icon.Position = UDim2.new(0, 20, 0.5, -40)
    icon.BackgroundTransparency = 1
    icon.Text = productData.icon
    icon.TextSize = 48
    icon.Font = Enum.Font.GothamBold
    icon.Parent = itemContainer
    
    -- Name
    local nameLabel = Instance.new("TextLabel")
    nameLabel.Name = "NameLabel"
    nameLabel.Size = UDim2.new(0, 300, 0, 30)
    nameLabel.Position = UDim2.new(0, 120, 0, 20)
    nameLabel.BackgroundTransparency = 1
    nameLabel.Text = productData.name
    nameLabel.TextColor3 = Color3.new(1, 1, 1)
    nameLabel.TextSize = 20
    nameLabel.Font = Enum.Font.GothamBold
    nameLabel.TextXAlignment = Enum.TextXAlignment.Left
    nameLabel.Parent = itemContainer
    
    -- Description
    local descLabel = Instance.new("TextLabel")
    descLabel.Name = "DescLabel"
    descLabel.Size = UDim2.new(0, 300, 0, 50)
    descLabel.Position = UDim2.new(0, 120, 0, 50)
    descLabel.BackgroundTransparency = 1
    descLabel.Text = productData.description
    descLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
    descLabel.TextSize = 14
    descLabel.Font = Enum.Font.Gotham
    descLabel.TextXAlignment = Enum.TextXAlignment.Left
    descLabel.TextYAlignment = Enum.TextYAlignment.Top
    descLabel.TextWrapped = true
    descLabel.Parent = itemContainer
    
    -- Purchase button
    local purchaseButton = Instance.new("TextButton")
    purchaseButton.Name = "PurchaseButton"
    purchaseButton.Size = UDim2.new(0, 140, 0, 40)
    purchaseButton.Position = UDim2.new(1, -160, 0.5, -20)
    purchaseButton.BackgroundColor3 = Color3.fromRGB(255, 100, 0)
    purchaseButton.BorderSizePixel = 0
    purchaseButton.Text = productData.price .. " R$"
    purchaseButton.TextColor3 = Color3.new(1, 1, 1)
    purchaseButton.TextSize = 16
    purchaseButton.Font = Enum.Font.GothamBold
    purchaseButton.Parent = itemContainer
    
    local buttonCorner = Instance.new("UICorner")
    buttonCorner.CornerRadius = UDim.new(0, 8)
    buttonCorner.Parent = purchaseButton
    
    -- Purchase button animation
    purchaseButton.MouseEnter:Connect(function()
        local hoverTween = TweenService:Create(purchaseButton, TweenInfo.new(0.2), {
            BackgroundColor3 = Color3.fromRGB(255, 130, 30),
            Size = UDim2.new(0, 145, 0, 42)
        })
        hoverTween:Play()
    end)
    
    purchaseButton.MouseLeave:Connect(function()
        local leaveTween = TweenService:Create(purchaseButton, TweenInfo.new(0.2), {
            BackgroundColor3 = Color3.fromRGB(255, 100, 0),
            Size = UDim2.new(0, 140, 0, 40)
        })
        leaveTween:Play()
    end)
    
    purchaseButton.MouseButton1Click:Connect(function()
        self:PurchaseProduct(productKey, productData)
    end)
    
    return itemContainer
end

function MonetizationShopController:PurchaseGamepass(gamepassKey, gamepassData)
    -- Show confirmation popup first
    self:ShowPurchaseConfirmation("gamepass", gamepassKey, gamepassData, function()
        -- Fire to server to prompt purchase
        RemoteEvents.PromptGamepassPurchase:FireServer(gamepassKey)
    end)
end

function MonetizationShopController:PurchaseProduct(productKey, productData)
    -- Show confirmation popup first
    self:ShowPurchaseConfirmation("product", productKey, productData, function()
        -- Fire to server to prompt purchase
        RemoteEvents.PromptProductPurchase:FireServer(productKey)
    end)
end

function MonetizationShopController:ShowPurchaseConfirmation(itemType, itemKey, itemData, confirmCallback)
    -- Create confirmation popup
    local confirmGui = Instance.new("ScreenGui")
    confirmGui.Name = "PurchaseConfirmGui"
    confirmGui.ResetOnSpawn = false
    confirmGui.IgnoreGuiInset = true
    confirmGui.Parent = playerGui
    
    -- Background overlay
    local overlay = Instance.new("Frame")
    overlay.Name = "Overlay"
    overlay.Size = UDim2.new(1, 0, 1, 0)
    overlay.Position = UDim2.new(0, 0, 0, 0)
    overlay.BackgroundColor3 = Color3.new(0, 0, 0)
    overlay.BackgroundTransparency = 0.3
    overlay.BorderSizePixel = 0
    overlay.Parent = confirmGui
    
    -- Confirmation container
    local confirmContainer = Instance.new("Frame")
    confirmContainer.Name = "ConfirmContainer"
    confirmContainer.Size = UDim2.new(0, 400, 0, 250)
    confirmContainer.Position = UDim2.new(0.5, -200, 0.5, -125)
    confirmContainer.BackgroundColor3 = Color3.fromRGB(40, 40, 55)
    confirmContainer.BorderSizePixel = 0
    confirmContainer.Parent = confirmGui
    
    local confirmCorner = Instance.new("UICorner")
    confirmCorner.CornerRadius = UDim.new(0, 15)
    confirmCorner.Parent = confirmContainer
    
    -- Title
    local title = Instance.new("TextLabel")
    title.Name = "Title"
    title.Size = UDim2.new(1, 0, 0, 40)
    title.Position = UDim2.new(0, 0, 0, 10)
    title.BackgroundTransparency = 1
    title.Text = "💳 Confirm Purchase"
    title.TextColor3 = Color3.fromRGB(255, 215, 0)
    title.TextSize = 20
    title.Font = Enum.Font.GothamBold
    title.Parent = confirmContainer
    
    -- Item info
    local itemInfo = Instance.new("TextLabel")
    itemInfo.Name = "ItemInfo"
    itemInfo.Size = UDim2.new(1, -40, 0, 80)
    itemInfo.Position = UDim2.new(0, 20, 0, 60)
    itemInfo.BackgroundTransparency = 1
    itemInfo.Text = string.format("%s %s\n%s\n\nPrice: %d Robux", itemData.icon, itemData.name, itemData.description, itemData.price)
    itemInfo.TextColor3 = Color3.new(1, 1, 1)
    itemInfo.TextSize = 16
    itemInfo.Font = Enum.Font.Gotham
    itemInfo.TextWrapped = true
    itemInfo.TextYAlignment = Enum.TextYAlignment.Top
    itemInfo.Parent = confirmContainer
    
    -- Confirm button
    local confirmButton = Instance.new("TextButton")
    confirmButton.Name = "ConfirmButton"
    confirmButton.Size = UDim2.new(0, 150, 0, 40)
    confirmButton.Position = UDim2.new(0, 50, 1, -60)
    confirmButton.BackgroundColor3 = Color3.fromRGB(50, 150, 50)
    confirmButton.BorderSizePixel = 0
    confirmButton.Text = "✅ Confirm"
    confirmButton.TextColor3 = Color3.new(1, 1, 1)
    confirmButton.TextSize = 16
    confirmButton.Font = Enum.Font.GothamBold
    confirmButton.Parent = confirmContainer
    
    local confirmButtonCorner = Instance.new("UICorner")
    confirmButtonCorner.CornerRadius = UDim.new(0, 8)
    confirmButtonCorner.Parent = confirmButton
    
    -- Cancel button
    local cancelButton = Instance.new("TextButton")
    cancelButton.Name = "CancelButton"
    cancelButton.Size = UDim2.new(0, 150, 0, 40)
    cancelButton.Position = UDim2.new(1, -200, 1, -60)
    cancelButton.BackgroundColor3 = Color3.fromRGB(150, 50, 50)
    cancelButton.BorderSizePixel = 0
    cancelButton.Text = "❌ Cancel"
    cancelButton.TextColor3 = Color3.new(1, 1, 1)
    cancelButton.TextSize = 16
    cancelButton.Font = Enum.Font.GothamBold
    cancelButton.Parent = confirmContainer
    
    local cancelButtonCorner = Instance.new("UICorner")
    cancelButtonCorner.CornerRadius = UDim.new(0, 8)
    cancelButtonCorner.Parent = cancelButton
    
    -- Button connections
    confirmButton.MouseButton1Click:Connect(function()
        confirmGui:Destroy()
        if confirmCallback then
            confirmCallback()
        end
    end)
    
    cancelButton.MouseButton1Click:Connect(function()
        confirmGui:Destroy()
    end)
    
    overlay.MouseButton1Click:Connect(function()
        confirmGui:Destroy()
    end)
    
    -- Slide in animation
    confirmContainer.Position = UDim2.new(0.5, -200, 1, 0)
    local slideIn = TweenService:Create(confirmContainer, TweenInfo.new(0.3, Enum.EasingStyle.Back), {
        Position = UDim2.new(0.5, -200, 0.5, -125)
    })
    slideIn:Play()
end

function MonetizationShopController:ShowPurchaseResult(success, itemData, extraData)
    -- Create result popup
    local resultGui = Instance.new("ScreenGui")
    resultGui.Name = "PurchaseResultGui"
    resultGui.ResetOnSpawn = false
    resultGui.IgnoreGuiInset = true
    resultGui.Parent = playerGui
    
    -- Result container
    local resultContainer = Instance.new("Frame")
    resultContainer.Name = "ResultContainer"
    resultContainer.Size = UDim2.new(0, 350, 0, 200)
    resultContainer.Position = UDim2.new(0.5, -175, 0, -200)
    resultContainer.BackgroundColor3 = success and Color3.fromRGB(40, 80, 40) or Color3.fromRGB(80, 40, 40)
    resultContainer.BorderSizePixel = 0
    resultContainer.Parent = resultGui
    
    local resultCorner = Instance.new("UICorner")
    resultCorner.CornerRadius = UDim.new(0, 15)
    resultCorner.Parent = resultContainer
    
    -- Result icon
    local resultIcon = Instance.new("TextLabel")
    resultIcon.Name = "ResultIcon"
    resultIcon.Size = UDim2.new(0, 60, 0, 60)
    resultIcon.Position = UDim2.new(0.5, -30, 0, 20)
    resultIcon.BackgroundTransparency = 1
    resultIcon.Text = success and "✅" or "❌"
    resultIcon.TextSize = 48
    resultIcon.Font = Enum.Font.GothamBold
    resultIcon.Parent = resultContainer
    
    -- Result message
    local resultMessage = Instance.new("TextLabel")
    resultMessage.Name = "ResultMessage"
    resultMessage.Size = UDim2.new(1, -20, 0, 80)
    resultMessage.Position = UDim2.new(0, 10, 0, 90)
    resultMessage.BackgroundTransparency = 1
    resultMessage.TextColor3 = Color3.new(1, 1, 1)
    resultMessage.TextSize = 16
    resultMessage.Font = Enum.Font.Gotham
    resultMessage.TextWrapped = true
    resultMessage.Parent = resultContainer
    
    if success then
        if extraData and extraData.alreadyOwned then
            resultMessage.Text = "You already own " .. itemData.name .. "!\nBenefits have been applied."
        else
            resultMessage.Text = "Successfully purchased " .. itemData.name .. "!\nEnjoy your new benefits!"
        end
    else
        resultMessage.Text = "Purchase failed or was cancelled.\nPlease try again later."
    end
    
    -- Slide down animation
    local slideDown = TweenService:Create(resultContainer, TweenInfo.new(0.5, Enum.EasingStyle.Back), {
        Position = UDim2.new(0.5, -175, 0, 50)
    })
    slideDown:Play()
    
    -- Auto-hide after 3 seconds
    spawn(function()
        wait(3)
        local slideUp = TweenService:Create(resultContainer, TweenInfo.new(0.3), {
            Position = UDim2.new(0.5, -175, 0, -200)
        })
        slideUp:Play()
        slideUp.Completed:Connect(function()
            resultGui:Destroy()
        end)
    end)
end

function MonetizationShopController:OpenShop()
    -- Request monetization data from server
    RemoteEvents.RequestMonetizationInfo:FireServer()
end

function MonetizationShopController:CloseShop()
    if currentShopGui then
        local container = currentShopGui:FindFirstChild("ShopContainer")
        if container then
            local slideOut = TweenService:Create(container, TweenInfo.new(0.3), {
                Position = UDim2.new(0.5, -400, 1, 0)
            })
            slideOut:Play()
            slideOut.Completed:Connect(function()
                currentShopGui:Destroy()
                currentShopGui = nil
            end)
        else
            currentShopGui:Destroy()
            currentShopGui = nil
        end
    end
end

function MonetizationShopController:UpdateShopContent()
    if not currentShopGui then return end
    
    local contentFrame = currentShopGui:FindFirstChild("ShopContainer"):FindFirstChild("ContentFrame")
    
    -- Clear existing items
    for _, child in pairs(contentFrame:GetChildren()) do
        if child:IsA("Frame") then
            child:Destroy()
        end
    end
    
    local layoutOrder = 1
    
    -- Add gamepass items
    if monetizationData.gamepasses then
        for key, gamepass in pairs(monetizationData.gamepasses) do
            self:CreateGamepassItem(key, gamepass, layoutOrder)
            layoutOrder = layoutOrder + 1
        end
    end
    
    -- Add developer product items
    if monetizationData.developerProducts then
        for key, product in pairs(monetizationData.developerProducts) do
            self:CreateProductItem(key, product, layoutOrder)
            layoutOrder = layoutOrder + 1
        end
    end
    
    -- Update canvas size
    contentFrame.CanvasSize = UDim2.new(0, 0, 0, layoutOrder * 140)
end

function MonetizationShopController:Initialize()
    print("💰 MonetizationShopController initializing...")
    
    -- Listen for monetization data updates
    RemoteEvents.MonetizationInfoUpdated.OnClientEvent:Connect(function(data)
        monetizationData = data.info or data -- Handle both new and old formats
        ownedGamepasses = data.ownedGamepasses or {}
        
        if not currentShopGui then
            currentShopGui = self:CreateShopGUI()
        end
        
        self:UpdateShopContent()
    end)
    
    -- Listen for purchase results
    RemoteEvents.GamepassPurchaseResult.OnClientEvent:Connect(function(result)
        self:ShowPurchaseResult(result.success, {name = result.gamepassName}, result)
        
        -- Refresh shop if purchase was successful
        if result.success then
            wait(1)
            self:OpenShop()
        end
    end)
    
    RemoteEvents.ProductPurchaseResult.OnClientEvent:Connect(function(result)
        self:ShowPurchaseResult(result.success, {name = result.productName}, result)
    end)
    
    -- Listen for shop open events
    RemoteEvents.OpenMonetizationShop.OnClientEvent:Connect(function()
        self:OpenShop()
    end)
    
    print("✅ MonetizationShopController initialized!")
end

-- Auto-initialize
MonetizationShopController:Initialize()

return MonetizationShopController
