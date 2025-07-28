-- PurchaseConfirmationController.luau
-- Manages purchase confirmation UI with sound effects and animations

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local SoundService = game:GetService("SoundService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local RemoteEvents = require(ReplicatedStorage.Shared.modules.RemoteEvents)

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local PurchaseConfirmationController = {}

-- GUI state
local confirmationGui = nil
local isShowing = false
local currentPurchaseData = nil

-- Sound effects
local purchaseSuccessSound = nil
local purchaseFailSound = nil
local buttonHoverSound = nil

function PurchaseConfirmationController:Init()
    self:LoadSounds()
    self:SetupRemoteEvents()
    print("🛒 PurchaseConfirmationController initialized")
end

function PurchaseConfirmationController:LoadSounds()
    -- Purchase success sound
    purchaseSuccessSound = Instance.new("Sound")
    purchaseSuccessSound.SoundId = "rbxasset://sounds/impact_water.mp3"
    purchaseSuccessSound.Volume = 0.6
    purchaseSuccessSound.Pitch = 1.2
    purchaseSuccessSound.Parent = SoundService
    
    -- Purchase fail sound
    purchaseFailSound = Instance.new("Sound")
    purchaseFailSound.SoundId = "rbxasset://sounds/impact_water.mp3"
    purchaseFailSound.Volume = 0.4
    purchaseFailSound.Pitch = 0.7
    purchaseFailSound.Parent = SoundService
    
    -- Button hover sound
    buttonHoverSound = Instance.new("Sound")
    buttonHoverSound.SoundId = "rbxasset://sounds/electronicpingshort.wav"
    buttonHoverSound.Volume = 0.2
    buttonHoverSound.Pitch = 1.5
    buttonHoverSound.Parent = SoundService
end

function PurchaseConfirmationController:SetupRemoteEvents()
    -- Handle purchase requests
    RemoteEvents.ShowPurchaseConfirmation.OnClientEvent:Connect(function(purchaseData)
        self:ShowConfirmation(purchaseData)
    end)
    
    -- Handle purchase results
    RemoteEvents.PurchaseResult.OnClientEvent:Connect(function(success, message, newBalance)
        self:ShowPurchaseResult(success, message, newBalance)
    end)
end

function PurchaseConfirmationController:ShowConfirmation(purchaseData)
    if isShowing then
        self:HideConfirmation()
        wait(0.1)
    end
    
    currentPurchaseData = purchaseData
    isShowing = true
    
    self:CreateConfirmationGui(purchaseData)
end

function PurchaseConfirmationController:CreateConfirmationGui(purchaseData)
    -- Remove existing GUI
    local existingGui = playerGui:FindFirstChild("PurchaseConfirmationGui")
    if existingGui then
        existingGui:Destroy()
    end
    
    -- Create main GUI
    confirmationGui = Instance.new("ScreenGui")
    confirmationGui.Name = "PurchaseConfirmationGui"
    confirmationGui.Parent = playerGui
    
    -- Background overlay
    local overlay = Instance.new("Frame")
    overlay.Name = "Overlay"
    overlay.Size = UDim2.new(1, 0, 1, 0)
    overlay.Position = UDim2.new(0, 0, 0, 0)
    overlay.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    overlay.BackgroundTransparency = 0.7
    overlay.BorderSizePixel = 0
    overlay.Parent = confirmationGui
    
    -- Main confirmation frame
    local confirmFrame = Instance.new("Frame")
    confirmFrame.Name = "ConfirmFrame"
    confirmFrame.Size = UDim2.new(0, 400, 0, 300)
    confirmFrame.Position = UDim2.new(0.5, -200, 0.5, -150)
    confirmFrame.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
    confirmFrame.BorderSizePixel = 0
    confirmFrame.Parent = overlay
    
    -- Rounded corners
    local frameCorner = Instance.new("UICorner")
    frameCorner.CornerRadius = UDim.new(0, 15)
    frameCorner.Parent = confirmFrame
    
    -- Border glow
    local frameBorder = Instance.new("UIStroke")
    frameBorder.Color = Color3.fromRGB(0, 162, 255)
    frameBorder.Thickness = 3
    frameBorder.Parent = confirmFrame
    
    -- Title
    local titleLabel = Instance.new("TextLabel")
    titleLabel.Name = "TitleLabel"
    titleLabel.Size = UDim2.new(1, -20, 0, 50)
    titleLabel.Position = UDim2.new(0, 10, 0, 10)
    titleLabel.BackgroundTransparency = 1
    titleLabel.Text = "Confirm Purchase"
    titleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    titleLabel.TextScaled = true
    titleLabel.Font = Enum.Font.GothamBold
    titleLabel.Parent = confirmFrame
    
    -- Item preview frame
    local previewFrame = Instance.new("Frame")
    previewFrame.Name = "PreviewFrame"
    previewFrame.Size = UDim2.new(1, -40, 0, 80)
    previewFrame.Position = UDim2.new(0, 20, 0, 70)
    previewFrame.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
    previewFrame.BorderSizePixel = 0
    previewFrame.Parent = confirmFrame
    
    local previewCorner = Instance.new("UICorner")
    previewCorner.CornerRadius = UDim.new(0, 10)
    previewCorner.Parent = previewFrame
    
    -- Item icon
    local itemIcon = Instance.new("TextLabel")
    itemIcon.Name = "ItemIcon"
    itemIcon.Size = UDim2.new(0, 60, 0, 60)
    itemIcon.Position = UDim2.new(0, 10, 0, 10)
    itemIcon.BackgroundTransparency = 1
    itemIcon.Text = purchaseData.icon or "🎁"
    itemIcon.TextColor3 = Color3.fromRGB(255, 255, 255)
    itemIcon.TextScaled = true
    itemIcon.Font = Enum.Font.SourceSansBold
    itemIcon.Parent = previewFrame
    
    -- Item name and description
    local itemName = Instance.new("TextLabel")
    itemName.Name = "ItemName"
    itemName.Size = UDim2.new(0, 270, 0, 30)
    itemName.Position = UDim2.new(0, 80, 0, 10)
    itemName.BackgroundTransparency = 1
    itemName.Text = purchaseData.name or "Unknown Item"
    itemName.TextColor3 = Color3.fromRGB(255, 255, 255)
    itemName.TextScaled = true
    itemName.Font = Enum.Font.GothamBold
    itemName.TextXAlignment = Enum.TextXAlignment.Left
    itemName.Parent = previewFrame
    
    local itemDescription = Instance.new("TextLabel")
    itemDescription.Name = "ItemDescription"
    itemDescription.Size = UDim2.new(0, 270, 0, 40)
    itemDescription.Position = UDim2.new(0, 80, 0, 35)
    itemDescription.BackgroundTransparency = 1
    itemDescription.Text = purchaseData.description or "No description available"
    itemDescription.TextColor3 = Color3.fromRGB(200, 200, 200)
    itemDescription.TextScaled = true
    itemDescription.Font = Enum.Font.Gotham
    itemDescription.TextXAlignment = Enum.TextXAlignment.Left
    itemDescription.TextWrapped = true
    itemDescription.Parent = previewFrame
    
    -- Price display
    local priceFrame = Instance.new("Frame")
    priceFrame.Name = "PriceFrame"
    priceFrame.Size = UDim2.new(1, -40, 0, 40)
    priceFrame.Position = UDim2.new(0, 20, 0, 165)
    priceFrame.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
    priceFrame.BorderSizePixel = 0
    priceFrame.Parent = confirmFrame
    
    local priceCorner = Instance.new("UICorner")
    priceCorner.CornerRadius = UDim.new(0, 8)
    priceCorner.Parent = priceFrame
    
    local priceLabel = Instance.new("TextLabel")
    priceLabel.Name = "PriceLabel"
    priceLabel.Size = UDim2.new(1, -20, 1, 0)
    priceLabel.Position = UDim2.new(0, 10, 0, 0)
    priceLabel.BackgroundTransparency = 1
    priceLabel.Text = "💰 " .. (purchaseData.price or 0) .. " Coins"
    priceLabel.TextColor3 = Color3.fromRGB(255, 215, 0)
    priceLabel.TextScaled = true
    priceLabel.Font = Enum.Font.GothamBold
    priceLabel.TextXAlignment = Enum.TextXAlignment.Center
    priceLabel.Parent = priceFrame
    
    -- Buttons
    local buttonFrame = Instance.new("Frame")
    buttonFrame.Name = "ButtonFrame"
    buttonFrame.Size = UDim2.new(1, -40, 0, 50)
    buttonFrame.Position = UDim2.new(0, 20, 0, 220)
    buttonFrame.BackgroundTransparency = 1
    buttonFrame.Parent = confirmFrame
    
    -- Confirm button
    local confirmButton = self:CreateButton(
        "ConfirmButton",
        UDim2.new(0, 170, 1, 0),
        UDim2.new(0, 0, 0, 0),
        "CONFIRM PURCHASE",
        Color3.fromRGB(0, 150, 0),
        Color3.fromRGB(0, 200, 0),
        buttonFrame
    )
    
    -- Cancel button
    local cancelButton = self:CreateButton(
        "CancelButton",
        UDim2.new(0, 170, 1, 0),
        UDim2.new(0, 190, 0, 0),
        "CANCEL",
        Color3.fromRGB(150, 0, 0),
        Color3.fromRGB(200, 0, 0),
        buttonFrame
    )
    
    -- Button connections
    confirmButton.MouseButton1Click:Connect(function()
        if buttonHoverSound then buttonHoverSound:Play() end
        self:ConfirmPurchase()
    end)
    
    cancelButton.MouseButton1Click:Connect(function()
        if buttonHoverSound then buttonHoverSound:Play() end
        self:CancelPurchase()
    end)
    
    -- Animate in
    confirmFrame.Size = UDim2.new(0, 0, 0, 0)
    local animateIn = TweenService:Create(
        confirmFrame,
        TweenInfo.new(0.5, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
        {Size = UDim2.new(0, 400, 0, 300)}
    )
    animateIn:Play()
end

function PurchaseConfirmationController:CreateButton(name, size, position, text, normalColor, hoverColor, parent)
    local button = Instance.new("TextButton")
    button.Name = name
    button.Size = size
    button.Position = position
    button.BackgroundColor3 = normalColor
    button.BorderSizePixel = 0
    button.Text = text
    button.TextColor3 = Color3.fromRGB(255, 255, 255)
    button.TextScaled = true
    button.Font = Enum.Font.GothamBold
    button.Parent = parent
    
    local buttonCorner = Instance.new("UICorner")
    buttonCorner.CornerRadius = UDim.new(0, 8)
    buttonCorner.Parent = button
    
    -- Hover effects
    button.MouseEnter:Connect(function()
        if buttonHoverSound then buttonHoverSound:Play() end
        local hoverTween = TweenService:Create(
            button,
            TweenInfo.new(0.2, Enum.EasingStyle.Quad),
            {BackgroundColor3 = hoverColor}
        )
        hoverTween:Play()
    end)
    
    button.MouseLeave:Connect(function()
        local normalTween = TweenService:Create(
            button,
            TweenInfo.new(0.2, Enum.EasingStyle.Quad),
            {BackgroundColor3 = normalColor}
        )
        normalTween:Play()
    end)
    
    return button
end

function PurchaseConfirmationController:ConfirmPurchase()
    if not currentPurchaseData then return end
    
    -- Send purchase request to server
    RemoteEvents.ProcessPurchase:FireServer(currentPurchaseData)
    
    -- Show loading state
    self:ShowLoadingState()
end

function PurchaseConfirmationController:CancelPurchase()
    self:HideConfirmation()
end

function PurchaseConfirmationController:ShowLoadingState()
    if not confirmationGui then return end
    
    local confirmFrame = confirmationGui.Overlay.ConfirmFrame
    local buttonFrame = confirmFrame.ButtonFrame
    
    -- Disable buttons and show loading
    for _, button in pairs(buttonFrame:GetChildren()) do
        if button:IsA("TextButton") then
            button.Text = "Processing..."
            button.Active = false
        end
    end
end

function PurchaseConfirmationController:ShowPurchaseResult(success, message, newBalance)
    if not confirmationGui then return end
    
    local confirmFrame = confirmationGui.Overlay.ConfirmFrame
    
    -- Play appropriate sound
    if success then
        if purchaseSuccessSound then purchaseSuccessSound:Play() end
    else
        if purchaseFailSound then purchaseFailSound:Play() end
    end
    
    -- Create result display
    local resultFrame = Instance.new("Frame")
    resultFrame.Name = "ResultFrame"
    resultFrame.Size = UDim2.new(1, 0, 1, 0)
    resultFrame.Position = UDim2.new(0, 0, 0, 0)
    resultFrame.BackgroundColor3 = success and Color3.fromRGB(0, 100, 0) or Color3.fromRGB(100, 0, 0)
    resultFrame.BackgroundTransparency = 0.1
    resultFrame.BorderSizePixel = 0
    resultFrame.Parent = confirmFrame
    
    local resultCorner = Instance.new("UICorner")
    resultCorner.CornerRadius = UDim.new(0, 15)
    resultCorner.Parent = resultFrame
    
    -- Result icon
    local resultIcon = Instance.new("TextLabel")
    resultIcon.Size = UDim2.new(0, 80, 0, 80)
    resultIcon.Position = UDim2.new(0.5, -40, 0, 30)
    resultIcon.BackgroundTransparency = 1
    resultIcon.Text = success and "✅" or "❌"
    resultIcon.TextScaled = true
    resultIcon.Font = Enum.Font.SourceSansBold
    resultIcon.Parent = resultFrame
    
    -- Result message
    local resultMessage = Instance.new("TextLabel")
    resultMessage.Size = UDim2.new(1, -40, 0, 60)
    resultMessage.Position = UDim2.new(0, 20, 0, 120)
    resultMessage.BackgroundTransparency = 1
    resultMessage.Text = message or (success and "Purchase Successful!" or "Purchase Failed!")
    resultMessage.TextColor3 = Color3.fromRGB(255, 255, 255)
    resultMessage.TextScaled = true
    resultMessage.Font = Enum.Font.GothamBold
    resultMessage.TextWrapped = true
    resultMessage.Parent = resultFrame
    
    -- Balance update (if successful)
    if success and newBalance then
        local balanceLabel = Instance.new("TextLabel")
        balanceLabel.Size = UDim2.new(1, -40, 0, 30)
        balanceLabel.Position = UDim2.new(0, 20, 0, 190)
        balanceLabel.BackgroundTransparency = 1
        balanceLabel.Text = "New Balance: 💰 " .. newBalance .. " Coins"
        balanceLabel.TextColor3 = Color3.fromRGB(255, 215, 0)
        balanceLabel.TextScaled = true
        balanceLabel.Font = Enum.Font.Gotham
        balanceLabel.Parent = resultFrame
    end
    
    -- OK button
    local okButton = self:CreateButton(
        "OkButton",
        UDim2.new(0, 120, 0, 40),
        UDim2.new(0.5, -60, 0, 240),
        "OK",
        Color3.fromRGB(0, 122, 204),
        Color3.fromRGB(0, 162, 255),
        resultFrame
    )
    
    okButton.MouseButton1Click:Connect(function()
        if buttonHoverSound then buttonHoverSound:Play() end
        self:HideConfirmation()
    end)
    
    -- Auto-close after a few seconds
    spawn(function()
        wait(5)
        if confirmationGui and confirmationGui.Parent then
            self:HideConfirmation()
        end
    end)
end

function PurchaseConfirmationController:HideConfirmation()
    if not confirmationGui then return end
    
    local confirmFrame = confirmationGui.Overlay.ConfirmFrame
    
    local animateOut = TweenService:Create(
        confirmFrame,
        TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.In),
        {Size = UDim2.new(0, 0, 0, 0)}
    )
    
    animateOut:Play()
    animateOut.Completed:Connect(function()
        confirmationGui:Destroy()
        confirmationGui = nil
        isShowing = false
        currentPurchaseData = nil
    end)
end

function PurchaseConfirmationController:IsShowing()
    return isShowing
end

function PurchaseConfirmationController:Cleanup()
    if confirmationGui then
        confirmationGui:Destroy()
        confirmationGui = nil
    end
    isShowing = false
    currentPurchaseData = nil
end

return PurchaseConfirmationController
