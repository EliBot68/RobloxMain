-- CrateMachineController.luau
-- Manages crate machine UI with spinning wheel animation and sounds

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local SoundService = game:GetService("SoundService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local RemoteEvents = require(ReplicatedStorage.Shared.modules.RemoteEvents)

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local CrateMachineController = {}

-- GUI state
local crateGui = nil
local isOpen = false
local isSpinning = false

-- Sound effects
local spinSound = nil
local winSound = nil
local openSound = nil

-- Crate definitions
local CRATE_ITEMS = {
    {id = "common_sparkle", name = "Sparkle Trail", rarity = "Common", weight = 50, color = Color3.fromRGB(200, 200, 200)},
    {id = "rare_flame", name = "Flame Trail", rarity = "Rare", weight = 30, color = Color3.fromRGB(0, 162, 255)},
    {id = "epic_rainbow", name = "Rainbow Trail", rarity = "Epic", weight = 20, color = Color3.fromRGB(128, 0, 128)},
}

function CrateMachineController:Init()
    self:LoadSounds()
    self:SetupRemoteEvents()
    print("📦 CrateMachineController initialized")
end

function CrateMachineController:LoadSounds()
    -- Spinning sound
    spinSound = Instance.new("Sound")
    spinSound.SoundId = "rbxasset://sounds/electronicpingshort.wav"
    spinSound.Volume = 0.5
    spinSound.Pitch = 0.8
    spinSound.Looped = true
    spinSound.Parent = SoundService
    
    -- Win sound
    winSound = Instance.new("Sound")
    winSound.SoundId = "rbxasset://sounds/impact_water.mp3"
    winSound.Volume = 0.8
    winSound.Pitch = 1.2
    winSound.Parent = SoundService
    
    -- Crate open sound
    openSound = Instance.new("Sound")
    openSound.SoundId = "rbxasset://sounds/impact_water.mp3"
    openSound.Volume = 0.6
    openSound.Pitch = 1.5
    openSound.Parent = SoundService
end

function CrateMachineController:SetupRemoteEvents()
    -- Handle crate machine interactions
    RemoteEvents.ShowCrateMachine.OnClientEvent:Connect(function()
        self:OpenCrateMachine()
    end)
    
    -- Handle crate opening results
    RemoteEvents.CrateOpenResult.OnClientEvent:Connect(function(success, item, message)
        self:HandleCrateResult(success, item, message)
    end)
    
    -- Handle crate key updates
    RemoteEvents.CrateKeyUpdate.OnClientEvent:Connect(function(keyCount)
        self:UpdateKeyDisplay(keyCount)
    end)
end

function CrateMachineController:OpenCrateMachine()
    if isOpen then
        self:CloseCrateMachine()
        return
    end
    
    isOpen = true
    self:CreateCrateMachineGui()
    
    if openSound then
        openSound:Play()
    end
end

function CrateMachineController:CreateCrateMachineGui()
    -- Remove existing GUI
    local existingGui = playerGui:FindFirstChild("CrateMachineGui")
    if existingGui then
        existingGui:Destroy()
    end
    
    -- Create main GUI
    crateGui = Instance.new("ScreenGui")
    crateGui.Name = "CrateMachineGui"
    crateGui.Parent = playerGui
    
    -- Background overlay
    local overlay = Instance.new("Frame")
    overlay.Name = "Overlay"
    overlay.Size = UDim2.new(1, 0, 1, 0)
    overlay.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    overlay.BackgroundTransparency = 0.6
    overlay.BorderSizePixel = 0
    overlay.Parent = crateGui
    
    -- Main crate machine frame
    local machineFrame = Instance.new("Frame")
    machineFrame.Name = "MachineFrame"
    machineFrame.Size = UDim2.new(0, 500, 0, 600)
    machineFrame.Position = UDim2.new(0.5, -250, 0.5, -300)
    machineFrame.BackgroundColor3 = Color3.fromRGB(60, 40, 20)
    machineFrame.BorderSizePixel = 0
    machineFrame.Parent = overlay
    
    local frameCorner = Instance.new("UICorner")
    frameCorner.CornerRadius = UDim.new(0, 15)
    frameCorner.Parent = machineFrame
    
    local frameBorder = Instance.new("UIStroke")
    frameBorder.Color = Color3.fromRGB(255, 215, 0)
    frameBorder.Thickness = 3
    frameBorder.Parent = machineFrame
    
    -- Title
    local titleLabel = Instance.new("TextLabel")
    titleLabel.Name = "Title"
    titleLabel.Size = UDim2.new(1, -20, 0, 60)
    titleLabel.Position = UDim2.new(0, 10, 0, 10)
    titleLabel.BackgroundTransparency = 1
    titleLabel.Text = "📦 MYSTERY CRATE MACHINE 📦"
    titleLabel.TextColor3 = Color3.fromRGB(255, 215, 0)
    titleLabel.TextScaled = true
    titleLabel.Font = Enum.Font.GothamBold
    titleLabel.Parent = machineFrame
    
    -- Spinning wheel container
    local wheelContainer = Instance.new("Frame")
    wheelContainer.Name = "WheelContainer"
    wheelContainer.Size = UDim2.new(0, 350, 0, 350)
    wheelContainer.Position = UDim2.new(0.5, -175, 0, 80)
    wheelContainer.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
    wheelContainer.BorderSizePixel = 0
    wheelContainer.Parent = machineFrame
    
    local wheelCorner = Instance.new("UICorner")
    wheelCorner.CornerRadius = UDim.new(0.5, 0) -- Make it circular
    wheelCorner.Parent = wheelContainer
    
    local wheelBorder = Instance.new("UIStroke")
    wheelBorder.Color = Color3.fromRGB(255, 255, 255)
    wheelBorder.Thickness = 4
    wheelBorder.Parent = wheelContainer
    
    -- Create wheel segments
    self:CreateWheelSegments(wheelContainer)
    
    -- Spinning pointer
    local pointer = Instance.new("Frame")
    pointer.Name = "Pointer"
    pointer.Size = UDim2.new(0, 20, 0, 40)
    pointer.Position = UDim2.new(0.5, -10, 0, -20)
    pointer.BackgroundColor3 = Color3.fromRGB(255, 0, 0)
    pointer.BorderSizePixel = 0
    pointer.ZIndex = 10
    pointer.Parent = wheelContainer
    
    local pointerCorner = Instance.new("UICorner")
    pointerCorner.CornerRadius = UDim.new(0, 5)
    pointerCorner.Parent = pointer
    
    -- Cost display
    local costFrame = Instance.new("Frame")
    costFrame.Name = "CostFrame"
    costFrame.Size = UDim2.new(1, -40, 0, 50)
    costFrame.Position = UDim2.new(0, 20, 0, 450)
    costFrame.BackgroundColor3 = Color3.fromRGB(80, 80, 80)
    costFrame.BorderSizePixel = 0
    costFrame.Parent = machineFrame
    
    local costCorner = Instance.new("UICorner")
    costCorner.CornerRadius = UDim.new(0, 10)
    costCorner.Parent = costFrame
    
    local costLabel = Instance.new("TextLabel")
    costLabel.Name = "CostLabel"
    costLabel.Size = UDim2.new(0.6, -10, 1, 0)
    costLabel.Position = UDim2.new(0, 10, 0, 0)
    costLabel.BackgroundTransparency = 1
    costLabel.Text = "💰 Cost: 500 Coins"
    costLabel.TextColor3 = Color3.fromRGB(255, 215, 0)
    costLabel.TextScaled = true
    costLabel.Font = Enum.Font.GothamBold
    costLabel.Parent = costFrame
    
    -- Key display
    local keyLabel = Instance.new("TextLabel")
    keyLabel.Name = "KeyLabel"
    keyLabel.Size = UDim2.new(0.4, -10, 1, 0)
    keyLabel.Position = UDim2.new(0.6, 10, 0, 0)
    keyLabel.BackgroundTransparency = 1
    keyLabel.Text = "🗝️ Keys: 0"
    keyLabel.TextColor3 = Color3.fromRGB(255, 215, 0)
    keyLabel.TextScaled = true
    keyLabel.Font = Enum.Font.GothamBold
    keyLabel.Parent = costFrame
    
    -- Spin button
    local spinButton = Instance.new("TextButton")
    spinButton.Name = "SpinButton"
    spinButton.Size = UDim2.new(0, 180, 0, 60)
    spinButton.Position = UDim2.new(0, 20, 0, 520)
    spinButton.BackgroundColor3 = Color3.fromRGB(0, 200, 0)
    spinButton.BorderSizePixel = 0
    spinButton.Text = "SPIN CRATE!"
    spinButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    spinButton.TextScaled = true
    spinButton.Font = Enum.Font.GothamBold
    spinButton.Parent = machineFrame
    
    local spinCorner = Instance.new("UICorner")
    spinCorner.CornerRadius = UDim.new(0, 10)
    spinCorner.Parent = spinButton
    
    -- Use Key button
    local useKeyButton = Instance.new("TextButton")
    useKeyButton.Name = "UseKeyButton"
    useKeyButton.Size = UDim2.new(0, 180, 0, 60)
    useKeyButton.Position = UDim2.new(0, 220, 0, 520)
    useKeyButton.BackgroundColor3 = Color3.fromRGB(255, 140, 0)
    useKeyButton.BorderSizePixel = 0
    useKeyButton.Text = "🗝️ USE KEY!"
    useKeyButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    useKeyButton.TextScaled = true
    useKeyButton.Font = Enum.Font.GothamBold
    useKeyButton.Parent = machineFrame
    
    local useKeyCorner = Instance.new("UICorner")
    useKeyCorner.CornerRadius = UDim.new(0, 10)
    useKeyCorner.Parent = useKeyButton
    
    -- Buy Keys button
    local buyKeysButton = Instance.new("TextButton")
    buyKeysButton.Name = "BuyKeysButton"
    buyKeysButton.Size = UDim2.new(0, 100, 0, 30)
    buyKeysButton.Position = UDim2.new(1, -120, 0, 415)
    buyKeysButton.BackgroundColor3 = Color3.fromRGB(0, 122, 204)
    buyKeysButton.BorderSizePixel = 0
    buyKeysButton.Text = "💎 BUY KEYS"
    buyKeysButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    buyKeysButton.TextScaled = true
    buyKeysButton.Font = Enum.Font.GothamBold
    buyKeysButton.Parent = machineFrame
    
    local buyKeysCorner = Instance.new("UICorner")
    buyKeysCorner.CornerRadius = UDim.new(0, 8)
    buyKeysCorner.Parent = buyKeysButton
    
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
    closeButton.Parent = machineFrame
    
    local closeCorner = Instance.new("UICorner")
    closeCorner.CornerRadius = UDim.new(0, 8)
    closeCorner.Parent = closeButton
    
    -- Button connections
    spinButton.MouseButton1Click:Connect(function()
        if not isSpinning then
            self:SpinCrate(false) -- false = use coins
        end
    end)
    
    useKeyButton.MouseButton1Click:Connect(function()
        if not isSpinning then
            self:SpinCrate(true) -- true = use key
        end
    end)
    
    buyKeysButton.MouseButton1Click:Connect(function()
        self:ShowKeyPurchaseOptions()
    end)
    
    closeButton.MouseButton1Click:Connect(function()
        self:CloseCrateMachine()
    end)
    
    -- Animate in
    machineFrame.Size = UDim2.new(0, 0, 0, 0)
    local animateIn = TweenService:Create(
        machineFrame,
        TweenInfo.new(0.5, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
        {Size = UDim2.new(0, 500, 0, 600)}
    )
    animateIn:Play()
end

function CrateMachineController:CreateWheelSegments(wheelContainer)
    local segmentCount = #CRATE_ITEMS
    local anglePerSegment = 360 / segmentCount
    
    for i, item in ipairs(CRATE_ITEMS) do
        local segment = Instance.new("Frame")
        segment.Name = "Segment" .. i
        segment.Size = UDim2.new(1, 0, 1, 0)
        segment.Position = UDim2.new(0, 0, 0, 0)
        segment.BackgroundTransparency = 1
        segment.Parent = wheelContainer
        
        -- Segment background (wedge shape approximation)
        local segmentBg = Instance.new("Frame")
        segmentBg.Size = UDim2.new(0.4, 0, 0.4, 0)
        segmentBg.Position = UDim2.new(0.5, -50, 0.3, 0)
        segmentBg.BackgroundColor3 = item.color
        segmentBg.BorderSizePixel = 0
        segmentBg.Parent = segment
        
        local segmentCorner = Instance.new("UICorner")
        segmentCorner.CornerRadius = UDim.new(0, 10)
        segmentCorner.Parent = segmentBg
        
        -- Item text
        local itemText = Instance.new("TextLabel")
        itemText.Size = UDim2.new(1, 0, 1, 0)
        itemText.BackgroundTransparency = 1
        itemText.Text = item.name
        itemText.TextColor3 = Color3.fromRGB(255, 255, 255)
        itemText.TextScaled = true
        itemText.Font = Enum.Font.GothamBold
        itemText.TextStrokeTransparency = 0
        itemText.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
        itemText.Parent = segmentBg
        
        -- Rotate segment
        segment.Rotation = (i - 1) * anglePerSegment
    end
end

function CrateMachineController:SpinCrate(useKey)
    if isSpinning then return end
    
    useKey = useKey or false
    isSpinning = true
    
    -- Disable spin buttons
    local spinButton = crateGui.Overlay.MachineFrame.SpinButton
    local useKeyButton = crateGui.Overlay.MachineFrame.UseKeyButton
    
    spinButton.Text = "SPINNING..."
    spinButton.BackgroundColor3 = Color3.fromRGB(100, 100, 100)
    spinButton.Active = false
    
    useKeyButton.Text = "SPINNING..."
    useKeyButton.BackgroundColor3 = Color3.fromRGB(150, 100, 0)
    useKeyButton.Active = false
    
    -- Start spinning sound
    if spinSound then
        spinSound:Play()
    end
    
    -- Send spin request to server
    RemoteEvents.SpinCrate:FireServer(useKey)
    
    -- Start wheel animation
    self:AnimateWheelSpin()
end

function CrateMachineController:AnimateWheelSpin()
    local wheelContainer = crateGui.Overlay.MachineFrame.WheelContainer
    
    -- Spin animation
    local totalRotation = 1440 + math.random(0, 360) -- 4 full rotations plus random
    
    local spinTween = TweenService:Create(
        wheelContainer,
        TweenInfo.new(3, Enum.EasingStyle.Quart, Enum.EasingDirection.Out),
        {Rotation = wheelContainer.Rotation + totalRotation}
    )
    
    spinTween:Play()
    
    -- Stop spinning after animation
    spinTween.Completed:Connect(function()
        if spinSound then
            spinSound:Stop()
        end
        
        -- Wait for server result
        spawn(function()
            wait(1)
            if isSpinning then
                -- Fallback if no server response
                self:HandleCrateResult(false, nil, "Connection error")
            end
        end)
    end)
end

function CrateMachineController:HandleCrateResult(success, item, message)
    isSpinning = false
    
    if spinSound then
        spinSound:Stop()
    end
    
    if success and winSound then
        winSound:Play()
    end
    
    -- Show result
    self:ShowCrateResult(success, item, message)
    
    -- Re-enable spin buttons
    local spinButton = crateGui.Overlay.MachineFrame.SpinButton
    local useKeyButton = crateGui.Overlay.MachineFrame.UseKeyButton
    
    spinButton.Text = "SPIN CRATE!"
    spinButton.BackgroundColor3 = Color3.fromRGB(0, 200, 0)
    spinButton.Active = true
    
    useKeyButton.Text = "🗝️ USE KEY!"
    useKeyButton.BackgroundColor3 = Color3.fromRGB(255, 140, 0)
    useKeyButton.Active = true
end

function CrateMachineController:ShowCrateResult(success, item, message)
    if not crateGui then return end
    
    -- Create result overlay
    local resultOverlay = Instance.new("Frame")
    resultOverlay.Name = "ResultOverlay"
    resultOverlay.Size = UDim2.new(1, 0, 1, 0)
    resultOverlay.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    resultOverlay.BackgroundTransparency = 0.3
    resultOverlay.BorderSizePixel = 0
    resultOverlay.Parent = crateGui
    
    -- Result frame
    local resultFrame = Instance.new("Frame")
    resultFrame.Name = "ResultFrame"
    resultFrame.Size = UDim2.new(0, 400, 0, 300)
    resultFrame.Position = UDim2.new(0.5, -200, 0.5, -150)
    resultFrame.BackgroundColor3 = success and Color3.fromRGB(0, 150, 0) or Color3.fromRGB(150, 0, 0)
    resultFrame.BorderSizePixel = 0
    resultFrame.Parent = resultOverlay
    
    local resultCorner = Instance.new("UICorner")
    resultCorner.CornerRadius = UDim.new(0, 15)
    resultCorner.Parent = resultFrame
    
    -- Result content
    if success and item then
        -- Success - show item won
        local itemIcon = Instance.new("TextLabel")
        itemIcon.Size = UDim2.new(0, 100, 0, 100)
        itemIcon.Position = UDim2.new(0.5, -50, 0, 30)
        itemIcon.BackgroundTransparency = 1
        itemIcon.Text = "✨"
        itemIcon.TextScaled = true
        itemIcon.Font = Enum.Font.SourceSansBold
        itemIcon.Parent = resultFrame
        
        local itemName = Instance.new("TextLabel")
        itemName.Size = UDim2.new(1, -40, 0, 60)
        itemName.Position = UDim2.new(0, 20, 0, 140)
        itemName.BackgroundTransparency = 1
        itemName.Text = "YOU WON!\n" .. item.name
        itemName.TextColor3 = Color3.fromRGB(255, 255, 255)
        itemName.TextScaled = true
        itemName.Font = Enum.Font.GothamBold
        itemName.Parent = resultFrame
        
        local rarityLabel = Instance.new("TextLabel")
        rarityLabel.Size = UDim2.new(1, -40, 0, 40)
        rarityLabel.Position = UDim2.new(0, 20, 0, 210)
        rarityLabel.BackgroundTransparency = 1
        rarityLabel.Text = item.rarity .. " Rarity"
        rarityLabel.TextColor3 = item.color
        rarityLabel.TextScaled = true
        rarityLabel.Font = Enum.Font.Gotham
        rarityLabel.Parent = resultFrame
    else
        -- Failure - show error message
        local failIcon = Instance.new("TextLabel")
        failIcon.Size = UDim2.new(0, 100, 0, 100)
        failIcon.Position = UDim2.new(0.5, -50, 0, 50)
        failIcon.BackgroundTransparency = 1
        failIcon.Text = "❌"
        failIcon.TextScaled = true
        failIcon.Font = Enum.Font.SourceSansBold
        failIcon.Parent = resultFrame
        
        local failMessage = Instance.new("TextLabel")
        failMessage.Size = UDim2.new(1, -40, 0, 100)
        failMessage.Position = UDim2.new(0, 20, 0, 160)
        failMessage.BackgroundTransparency = 1
        failMessage.Text = message or "Crate opening failed!"
        failMessage.TextColor3 = Color3.fromRGB(255, 255, 255)
        failMessage.TextScaled = true
        failMessage.Font = Enum.Font.Gotham
        failMessage.TextWrapped = true
        failMessage.Parent = resultFrame
    end
    
    -- OK button
    local okButton = Instance.new("TextButton")
    okButton.Size = UDim2.new(0, 120, 0, 40)
    okButton.Position = UDim2.new(0.5, -60, 0, 250)
    okButton.BackgroundColor3 = Color3.fromRGB(0, 122, 204)
    okButton.BorderSizePixel = 0
    okButton.Text = "OK"
    okButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    okButton.TextScaled = true
    okButton.Font = Enum.Font.GothamBold
    okButton.Parent = resultFrame
    
    local okCorner = Instance.new("UICorner")
    okCorner.CornerRadius = UDim.new(0, 8)
    okCorner.Parent = okButton
    
    okButton.MouseButton1Click:Connect(function()
        resultOverlay:Destroy()
    end)
    
    -- Animate result in
    resultFrame.Size = UDim2.new(0, 0, 0, 0)
    local animateIn = TweenService:Create(
        resultFrame,
        TweenInfo.new(0.5, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
        {Size = UDim2.new(0, 400, 0, 300)}
    )
    animateIn:Play()
    
    -- Auto-close after 5 seconds
    spawn(function()
        wait(5)
        if resultOverlay and resultOverlay.Parent then
            resultOverlay:Destroy()
        end
    end)
end

function CrateMachineController:CloseCrateMachine()
    if not crateGui then return end
    
    local machineFrame = crateGui.Overlay.MachineFrame
    
    local animateOut = TweenService:Create(
        machineFrame,
        TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.In),
        {Size = UDim2.new(0, 0, 0, 0)}
    )
    
    animateOut:Play()
    animateOut.Completed:Connect(function()
        crateGui:Destroy()
        crateGui = nil
        isOpen = false
    end)
end

function CrateMachineController:UpdateKeyDisplay(keyCount)
    -- Update the key display in the crate machine
    if crateGui and crateGui:FindFirstChild("Overlay") then
        local keyLabel = crateGui.Overlay.MachineFrame.CostFrame.KeyLabel
        if keyLabel then
            keyLabel.Text = "🗝️ Keys: " .. tostring(keyCount or 0)
        end
    end
end

function CrateMachineController:ShowKeyPurchaseOptions()
    -- Show monetization purchase options for crate keys
    local purchaseData = {
        type = "product",
        key = "crateKey",
        name = "🗝️ Unlock Crate Key",
        description = "Get a special key to unlock mystery crates for free!",
        price = 50,
        icon = "🗝️",
        itemId = "product_crate_key"
    }
    
    -- Request purchase confirmation from PurchaseConfirmationController
    RemoteEvents.ShowPurchaseConfirmation:FireClient(game.Players.LocalPlayer, purchaseData)
end

function CrateMachineController:Cleanup()
    if crateGui then
        crateGui:Destroy()
        crateGui = nil
    end
    isOpen = false
    isSpinning = false
end

return CrateMachineController
