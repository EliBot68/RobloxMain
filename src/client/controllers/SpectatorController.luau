-- SpectatorController.luau
-- Client-side spectator mode UI and camera controls

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SoundService = game:GetService("SoundService")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local RemoteEvents = require(ReplicatedStorage.Shared.modules.RemoteEvents)

local SpectatorController = {}
local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local camera = Workspace.CurrentCamera

-- Spectator state
local isSpectating = false
local currentTarget = nil
local spectatorData = {}
local availableTargets = {}
local cheerEmotes = {}

-- UI elements
local spectatorGui = nil
local spectatorHUD = nil
local cheerPanel = nil
local targetInfo = nil

-- Camera control
local cameraConnection = nil
local lastMousePosition = Vector2.new(0, 0)
local isDragging = false

-- Sound effects
local sounds = {
    enterSpectator = nil,
    switchTarget = nil,
    cheer = nil,
    cheerReceived = nil
}

function SpectatorController:Init()
    print("👁️ SpectatorController initializing...")
    
    self:CreateSpectatorUI()
    self:SetupRemoteEvents()
    self:SetupInputHandling()
    self:LoadSounds()
    
    print("✅ SpectatorController initialized!")
end

function SpectatorController:CreateSpectatorUI()
    -- Create main spectator UI
    spectatorGui = Instance.new("ScreenGui")
    spectatorGui.Name = "SpectatorGui"
    spectatorGui.ResetOnSpawn = false
    spectatorGui.Enabled = false
    spectatorGui.Parent = playerGui
    
    -- Create spectator HUD
    self:CreateSpectatorHUD()
    
    -- Create cheer panel
    self:CreateCheerPanel()
    
    -- Create target info display
    self:CreateTargetInfoDisplay()
end

function SpectatorController:CreateSpectatorHUD()
    spectatorHUD = Instance.new("Frame")
    spectatorHUD.Name = "SpectatorHUD"
    spectatorHUD.Size = UDim2.new(1, 0, 0, 100)
    spectatorHUD.Position = UDim2.new(0, 0, 0, 0)
    spectatorHUD.BackgroundColor3 = Color3.new(0, 0, 0)
    spectatorHUD.BackgroundTransparency = 0.3
    spectatorHUD.BorderSizePixel = 0
    spectatorHUD.Parent = spectatorGui
    
    -- Spectator mode indicator
    local modeLabel = Instance.new("TextLabel")
    modeLabel.Name = "ModeLabel"
    modeLabel.Size = UDim2.new(0, 200, 1, 0)
    modeLabel.Position = UDim2.new(0, 20, 0, 0)
    modeLabel.BackgroundTransparency = 1
    modeLabel.Text = "👁️ SPECTATOR MODE"
    modeLabel.TextColor3 = Color3.new(1, 1, 1)
    modeLabel.TextScaled = true
    modeLabel.Font = Enum.Font.SourceSansBold
    modeLabel.TextStrokeTransparency = 0
    modeLabel.TextStrokeColor3 = Color3.new(0, 0, 0)
    modeLabel.Parent = spectatorHUD
    
    -- Current target display
    local targetLabel = Instance.new("TextLabel")
    targetLabel.Name = "TargetLabel"
    targetLabel.Size = UDim2.new(0, 300, 1, 0)
    targetLabel.Position = UDim2.new(0, 240, 0, 0)
    targetLabel.BackgroundTransparency = 1
    targetLabel.Text = "Watching: Player"
    targetLabel.TextColor3 = Color3.new(0.8, 1, 0.8)
    targetLabel.TextScaled = true
    targetLabel.Font = Enum.Font.SourceSans
    targetLabel.TextStrokeTransparency = 0
    targetLabel.TextStrokeColor3 = Color3.new(0, 0, 0)
    targetLabel.Parent = spectatorHUD
    
    -- Controls hint
    local controlsLabel = Instance.new("TextLabel")
    controlsLabel.Name = "ControlsLabel"
    controlsLabel.Size = UDim2.new(0, 400, 1, 0)
    controlsLabel.Position = UDim2.new(1, -420, 0, 0)
    controlsLabel.BackgroundTransparency = 1
    controlsLabel.Text = "← → Switch Targets | Mouse: Pan Camera | Q: Exit"
    controlsLabel.TextColor3 = Color3.new(0.7, 0.7, 0.7)
    controlsLabel.TextScaled = true
    controlsLabel.Font = Enum.Font.SourceSans
    controlsLabel.Parent = spectatorHUD
end

function SpectatorController:CreateCheerPanel()
    cheerPanel = Instance.new("Frame")
    cheerPanel.Name = "CheerPanel"
    cheerPanel.Size = UDim2.new(0, 320, 0, 180)
    cheerPanel.Position = UDim2.new(1, -340, 0, 120)
    cheerPanel.BackgroundColor3 = Color3.new(0.1, 0.1, 0.2)
    cheerPanel.BackgroundTransparency = 0.1
    cheerPanel.BorderSizePixel = 0
    cheerPanel.Parent = spectatorGui
    
    local panelCorner = Instance.new("UICorner")
    panelCorner.CornerRadius = UDim.new(0, 15)
    panelCorner.Parent = cheerPanel
    
    local panelStroke = Instance.new("UIStroke")
    panelStroke.Color = Color3.new(1, 0.6, 0.2)
    panelStroke.Thickness = 2
    panelStroke.Parent = cheerPanel
    
    -- Cheer panel title
    local cheerTitle = Instance.new("TextLabel")
    cheerTitle.Name = "CheerTitle"
    cheerTitle.Size = UDim2.new(1, -20, 0, 30)
    cheerTitle.Position = UDim2.new(0, 10, 0, 5)
    cheerTitle.BackgroundTransparency = 1
    cheerTitle.Text = "🎉 Cheer for Player!"
    cheerTitle.TextColor3 = Color3.new(1, 1, 1)
    cheerTitle.TextScaled = true
    cheerTitle.Font = Enum.Font.SourceSansBold
    cheerTitle.TextStrokeTransparency = 0
    cheerTitle.TextStrokeColor3 = Color3.new(0, 0, 0)
    cheerTitle.Parent = cheerPanel
    
    -- Scroll frame for cheer buttons
    local cheerScrollFrame = Instance.new("ScrollingFrame")
    cheerScrollFrame.Name = "CheerScrollFrame"
    cheerScrollFrame.Size = UDim2.new(1, -20, 1, -45)
    cheerScrollFrame.Position = UDim2.new(0, 10, 0, 35)
    cheerScrollFrame.BackgroundTransparency = 1
    cheerScrollFrame.BorderSizePixel = 0
    cheerScrollFrame.ScrollBarThickness = 6
    cheerScrollFrame.Parent = cheerPanel
    
    local gridLayout = Instance.new("UIGridLayout")
    gridLayout.CellSize = UDim2.new(0, 70, 0, 35)
    gridLayout.CellPadding = UDim2.new(0, 5, 0, 5)
    gridLayout.SortOrder = Enum.SortOrder.LayoutOrder
    gridLayout.Parent = cheerScrollFrame
    
    -- Store reference for populating later
    self.cheerScrollFrame = cheerScrollFrame
end

function SpectatorController:CreateTargetInfoDisplay()
    targetInfo = Instance.new("Frame")
    targetInfo.Name = "TargetInfo"
    targetInfo.Size = UDim2.new(0, 250, 0, 120)
    targetInfo.Position = UDim2.new(0, 20, 0, 120)
    targetInfo.BackgroundColor3 = Color3.new(0.1, 0.1, 0.2)
    targetInfo.BackgroundTransparency = 0.1
    targetInfo.BorderSizePixel = 0
    targetInfo.Parent = spectatorGui
    
    local infoCorner = Instance.new("UICorner")
    infoCorner.CornerRadius = UDim.new(0, 15)
    infoCorner.Parent = targetInfo
    
    local infoStroke = Instance.new("UIStroke")
    infoStroke.Color = Color3.new(0.3, 0.8, 1)
    infoStroke.Thickness = 2
    infoStroke.Parent = targetInfo
    
    -- Player name
    local nameLabel = Instance.new("TextLabel")
    nameLabel.Name = "NameLabel"
    nameLabel.Size = UDim2.new(1, -20, 0, 30)
    nameLabel.Position = UDim2.new(0, 10, 0, 5)
    nameLabel.BackgroundTransparency = 1
    nameLabel.Text = "Player Name"
    nameLabel.TextColor3 = Color3.new(1, 1, 1)
    nameLabel.TextScaled = true
    nameLabel.Font = Enum.Font.SourceSansBold
    nameLabel.TextStrokeTransparency = 0
    nameLabel.TextStrokeColor3 = Color3.new(0, 0, 0)
    nameLabel.Parent = targetInfo
    
    -- Stats display
    local statsLabel = Instance.new("TextLabel")
    statsLabel.Name = "StatsLabel"
    statsLabel.Size = UDim2.new(1, -20, 0, 80)
    statsLabel.Position = UDim2.new(0, 10, 0, 35)
    statsLabel.BackgroundTransparency = 1
    statsLabel.Text = "Level: 1\nHigh Score: 0\nGames: 0"
    statsLabel.TextColor3 = Color3.new(0.8, 0.8, 0.8)
    statsLabel.TextScaled = true
    statsLabel.Font = Enum.Font.SourceSans
    statsLabel.TextYAlignment = Enum.TextYAlignment.Top
    statsLabel.Parent = targetInfo
end

function SpectatorController:PopulateCheerButtons()
    if not self.cheerScrollFrame then return end
    
    -- Clear existing buttons
    for _, child in pairs(self.cheerScrollFrame:GetChildren()) do
        if child:IsA("TextButton") then
            child:Destroy()
        end
    end
    
    -- Create buttons for each cheer emote
    for i, cheerData in ipairs(cheerEmotes) do
        local cheerButton = Instance.new("TextButton")
        cheerButton.Name = "CheerButton_" .. cheerData.id
        cheerButton.Size = UDim2.new(0, 70, 0, 35)
        cheerButton.BackgroundColor3 = Color3.new(0.3, 0.6, 1)
        cheerButton.BorderSizePixel = 0
        cheerButton.Text = cheerData.name:sub(1, 8) -- Truncate for button
        cheerButton.TextColor3 = Color3.new(1, 1, 1)
        cheerButton.TextScaled = true
        cheerButton.Font = Enum.Font.SourceSans
        cheerButton.LayoutOrder = i
        cheerButton.Parent = self.cheerScrollFrame
        
        local buttonCorner = Instance.new("UICorner")
        buttonCorner.CornerRadius = UDim.new(0, 8)
        buttonCorner.Parent = cheerButton
        
        -- Click handler
        cheerButton.MouseButton1Click:Connect(function()
            self:SendCheer(cheerData.id)
        end)
        
        -- Hover effects
        cheerButton.MouseEnter:Connect(function()
            local hoverTween = TweenService:Create(
                cheerButton,
                TweenInfo.new(0.2, Enum.EasingStyle.Quad),
                {BackgroundColor3 = Color3.new(0.4, 0.7, 1)}
            )
            hoverTween:Play()
        end)
        
        cheerButton.MouseLeave:Connect(function()
            local leaveTween = TweenService:Create(
                cheerButton,
                TweenInfo.new(0.2, Enum.EasingStyle.Quad),
                {BackgroundColor3 = Color3.new(0.3, 0.6, 1)}
            )
            leaveTween:Play()
        end)
    end
    
    -- Update scroll frame canvas size
    local gridLayout = self.cheerScrollFrame:FindFirstChildOfClass("UIGridLayout")
    if gridLayout then
        local rows = math.ceil(#cheerEmotes / 4)
        self.cheerScrollFrame.CanvasSize = UDim2.new(0, 0, 0, rows * 40)
    end
end

function SpectatorController:EnterSpectatorMode(data)
    isSpectating = true
    currentTarget = data.targetPlayer
    spectatorData = data
    availableTargets = data.availableTargets or {}
    cheerEmotes = data.cheerEmotes or {}
    
    -- Show spectator UI
    spectatorGui.Enabled = true
    
    -- Update UI elements
    self:UpdateTargetDisplay()
    self:PopulateCheerButtons()
    
    -- Set up camera
    self:SetupSpectatorCamera()
    
    -- Play enter sound
    if sounds.enterSpectator then
        sounds.enterSpectator:Play()
    end
    
    print("👁️ Entered spectator mode, watching " .. currentTarget.Name)
end

function SpectatorController:ExitSpectatorMode()
    isSpectating = false
    currentTarget = nil
    
    -- Hide spectator UI
    spectatorGui.Enabled = false
    
    -- Reset camera
    self:ResetCamera()
    
    -- Clean up connections
    if cameraConnection then
        cameraConnection:Disconnect()
        cameraConnection = nil
    end
    
    print("👁️ Exited spectator mode")
end

function SpectatorController:SetupSpectatorCamera()
    camera.CameraType = Enum.CameraType.Scriptable
    
    -- Start camera update loop
    cameraConnection = RunService.Heartbeat:Connect(function()
        self:UpdateCamera()
    end)
end

function SpectatorController:UpdateCamera()
    if not isSpectating or not currentTarget or not currentTarget.Character then
        return
    end
    
    local targetCharacter = currentTarget.Character
    local targetHumanoidRootPart = targetCharacter:FindFirstChild("HumanoidRootPart")
    if not targetHumanoidRootPart then return end
    
    -- Calculate camera position (this will be updated by server)
    local targetPosition = targetHumanoidRootPart.Position
    local cameraOffset = Vector3.new(0, 15, -10) -- Default offset
    
    -- Apply camera position
    local cameraPosition = targetPosition + cameraOffset
    local lookDirection = (targetPosition - cameraPosition).Unit
    
    camera.CFrame = CFrame.lookAt(cameraPosition, targetPosition)
end

function SpectatorController:ResetCamera()
    camera.CameraType = Enum.CameraType.Custom
    camera.CameraSubject = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
end

function SpectatorController:UpdateTargetDisplay()
    if not currentTarget then return end
    
    -- Update HUD target label
    local targetLabel = spectatorHUD:FindFirstChild("TargetLabel")
    if targetLabel then
        targetLabel.Text = "Watching: " .. currentTarget.Name
    end
    
    -- Update target info panel
    local nameLabel = targetInfo:FindFirstChild("NameLabel")
    if nameLabel then
        nameLabel.Text = currentTarget.Name
    end
    
    -- Update cheer panel title
    local cheerTitle = cheerPanel:FindFirstChild("CheerTitle")
    if cheerTitle then
        cheerTitle.Text = "🎉 Cheer for " .. currentTarget.Name .. "!"
    end
end

function SpectatorController:UpdateTargetStats(stats)
    local statsLabel = targetInfo:FindFirstChild("StatsLabel")
    if statsLabel and stats then
        statsLabel.Text = string.format(
            "Level: %d\nHigh Score: %d\nGames: %d\nColor: %s",
            stats.level or 1,
            stats.highScore or 0,
            stats.gamesPlayed or 0,
            stats.currentColor or "RED"
        )
    end
end

function SpectatorController:SwitchTarget(direction)
    if not isSpectating then return end
    
    RemoteEvents.SwitchSpectatorTarget:FireServer(direction)
    
    -- Play switch sound
    if sounds.switchTarget then
        sounds.switchTarget:Play()
    end
end

function SpectatorController:SendCheer(cheerType)
    if not isSpectating or not currentTarget then return end
    
    RemoteEvents.SpectatorCheer:FireServer(cheerType)
    
    -- Play cheer sound
    if sounds.cheer then
        sounds.cheer:Play()
    end
    
    -- Show local feedback
    self:ShowCheerFeedback(cheerType)
end

function SpectatorController:ShowCheerFeedback(cheerType)
    -- Find the cheer data
    local cheerData = nil
    for _, cheer in pairs(cheerEmotes) do
        if cheer.id == cheerType then
            cheerData = cheer
            break
        end
    end
    
    if not cheerData then return end
    
    -- Create temporary feedback
    local feedback = Instance.new("TextLabel")
    feedback.Size = UDim2.new(0, 200, 0, 50)
    feedback.Position = UDim2.new(0.5, -100, 0.5, -25)
    feedback.BackgroundColor3 = Color3.new(0, 0, 0)
    feedback.BackgroundTransparency = 0.3
    feedback.BorderSizePixel = 0
    feedback.Text = "Sent " .. cheerData.name .. "!"
    feedback.TextColor3 = Color3.new(1, 1, 1)
    feedback.TextScaled = true
    feedback.Font = Enum.Font.SourceSansBold
    feedback.Parent = spectatorGui
    
    local feedbackCorner = Instance.new("UICorner")
    feedbackCorner.CornerRadius = UDim.new(0, 15)
    feedbackCorner.Parent = feedback
    
    -- Animate feedback
    feedback.Position = UDim2.new(0.5, -100, 1, 0)
    local showTween = TweenService:Create(
        feedback,
        TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
        {Position = UDim2.new(0.5, -100, 0.5, -25)}
    )
    showTween:Play()
    
    -- Auto-remove after 2 seconds
    spawn(function()
        wait(2)
        local hideTween = TweenService:Create(
            feedback,
            TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
            {Position = UDim2.new(0.5, -100, 1, 0)}
        )
        hideTween:Play()
        hideTween.Completed:Connect(function()
            feedback:Destroy()
        end)
    end)
end

function SpectatorController:ShowCheerMessage(data)
    -- Create floating cheer message
    local cheerMessage = Instance.new("TextLabel")
    cheerMessage.Size = UDim2.new(0, 300, 0, 60)
    cheerMessage.Position = UDim2.new(0.5, -150, 0, 150)
    cheerMessage.BackgroundColor3 = Color3.new(1, 0.8, 0.2)
    cheerMessage.BackgroundTransparency = 0.1
    cheerMessage.BorderSizePixel = 0
    cheerMessage.Text = data.message
    cheerMessage.TextColor3 = Color3.new(0, 0, 0)
    cheerMessage.TextScaled = true
    cheerMessage.Font = Enum.Font.SourceSansBold
    cheerMessage.Parent = playerGui
    
    local messageCorner = Instance.new("UICorner")
    messageCorner.CornerRadius = UDim.new(0, 15)
    messageCorner.Parent = cheerMessage
    
    -- Animate message
    cheerMessage.Position = UDim2.new(0.5, -150, 0, 100)
    local showTween = TweenService:Create(
        cheerMessage,
        TweenInfo.new(0.5, Enum.EasingStyle.Bounce, Enum.EasingDirection.Out),
        {Position = UDim2.new(0.5, -150, 0, 150)}
    )
    showTween:Play()
    
    -- Play received cheer sound
    if sounds.cheerReceived then
        sounds.cheerReceived:Play()
    end
    
    -- Auto-remove after 4 seconds
    spawn(function()
        wait(4)
        local hideTween = TweenService:Create(
            cheerMessage,
            TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
            {
                Position = UDim2.new(0.5, -150, 0, 100),
                BackgroundTransparency = 1,
                TextTransparency = 1
            }
        )
        hideTween:Play()
        hideTween.Completed:Connect(function()
            cheerMessage:Destroy()
        end)
    end)
end

function SpectatorController:SetupInputHandling()
    -- Handle keyboard input for spectator controls
    UserInputService.InputBegan:Connect(function(input, gameProcessed)
        if gameProcessed or not isSpectating then return end
        
        if input.KeyCode == Enum.KeyCode.Left or input.KeyCode == Enum.KeyCode.A then
            self:SwitchTarget("previous")
        elseif input.KeyCode == Enum.KeyCode.Right or input.KeyCode == Enum.KeyCode.D then
            self:SwitchTarget("next")
        elseif input.KeyCode == Enum.KeyCode.Q then
            RemoteEvents.StopSpectating:FireServer()
        end
    end)
    
    -- Handle mouse camera controls
    UserInputService.InputBegan:Connect(function(input, gameProcessed)
        if gameProcessed or not isSpectating then return end
        
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            isDragging = true
            lastMousePosition = UserInputService:GetMouseLocation()
        end
    end)
    
    UserInputService.InputEnded:Connect(function(input, gameProcessed)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            isDragging = false
        end
    end)
    
    UserInputService.InputChanged:Connect(function(input, gameProcessed)
        if gameProcessed or not isSpectating or not isDragging then return end
        
        if input.UserInputType == Enum.UserInputType.MouseMovement then
            local mousePosition = UserInputService:GetMouseLocation()
            local deltaX = mousePosition.X - lastMousePosition.X
            local deltaY = mousePosition.Y - lastMousePosition.Y
            
            -- Send camera control to server
            RemoteEvents.SpectatorCameraControl:FireServer({
                type = "pan",
                deltaX = deltaX * 0.01,
                deltaY = deltaY * 0.01
            })
            
            lastMousePosition = mousePosition
        elseif input.UserInputType == Enum.UserInputType.MouseWheel then
            -- Handle zoom
            RemoteEvents.SpectatorCameraControl:FireServer({
                type = "zoom",
                delta = input.Position.Z
            })
        end
    end)
end

function SpectatorController:LoadSounds()
    sounds.enterSpectator = Instance.new("Sound")
    sounds.enterSpectator.SoundId = "rbxasset://sounds/action_get_up.mp3"
    sounds.enterSpectator.Volume = 0.5
    sounds.enterSpectator.Parent = SoundService
    
    sounds.switchTarget = Instance.new("Sound")
    sounds.switchTarget.SoundId = "rbxasset://sounds/button.wav"
    sounds.switchTarget.Volume = 0.4
    sounds.switchTarget.Parent = SoundService
    
    sounds.cheer = Instance.new("Sound")
    sounds.cheer.SoundId = "rbxasset://sounds/action_footsteps_plastic.mp3"
    sounds.cheer.Volume = 0.6
    sounds.cheer.Parent = SoundService
    
    sounds.cheerReceived = Instance.new("Sound")
    sounds.cheerReceived.SoundId = "rbxasset://sounds/electronicpingshort.wav"
    sounds.cheerReceived.Volume = 0.7
    sounds.cheerReceived.Parent = SoundService
end

function SpectatorController:SetupRemoteEvents()
    -- Handle entering spectator mode
    RemoteEvents.EnterSpectatorMode.OnClientEvent:Connect(function(data)
        self:EnterSpectatorMode(data)
    end)
    
    -- Handle exiting spectator mode
    RemoteEvents.ExitSpectatorMode.OnClientEvent:Connect(function()
        self:ExitSpectatorMode()
    end)
    
    -- Handle target changes
    RemoteEvents.SpectatorTargetChanged.OnClientEvent:Connect(function(data)
        currentTarget = data.newTarget
        self:UpdateTargetDisplay()
        if data.targetStats then
            self:UpdateTargetStats(data.targetStats)
        end
    end)
    
    -- Handle camera updates
    RemoteEvents.UpdateSpectatorCamera.OnClientEvent:Connect(function(data)
        if data.targetStats then
            self:UpdateTargetStats(data.targetStats)
        end
    end)
    
    -- Handle cheer messages
    RemoteEvents.ShowCheerMessage.OnClientEvent:Connect(function(data)
        self:ShowCheerMessage(data)
    end)
    
    -- Handle cheer confirmations
    RemoteEvents.CheerConfirmed.OnClientEvent:Connect(function(data)
        -- Could add cooldown UI feedback here
    end)
end

-- Handle character respawn
player.CharacterAdded:Connect(function()
    if isSpectating then
        -- Reset spectator mode on respawn
        SpectatorController:ExitSpectatorMode()
    end
end)

return SpectatorController
