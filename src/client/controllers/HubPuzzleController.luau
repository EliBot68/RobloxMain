-- HubPuzzleController.luau
-- Client-side controller for hidden orb puzzle game in the hub

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local SoundService = game:GetService("SoundService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local RemoteEvents = require(ReplicatedStorage.Shared.modules.RemoteEvents)

local HubPuzzleController = {}

-- Configuration
local ORB_POSITIONS = {
    Vector3.new(-15, 8, 25),   -- Hidden behind fountain
    Vector3.new(35, 5, -20),   -- Near teleporter arch
    Vector3.new(-40, 12, -5),  -- On elevated platform
    Vector3.new(0, 15, 45),    -- High up near spawn
    Vector3.new(20, 3, 30)     -- Behind shop area
}

local ORB_COLORS = {
    Color3.new(1, 0.3, 0.8),    -- Pink
    Color3.new(0.3, 1, 0.8),    -- Cyan
    Color3.new(1, 0.8, 0.3),    -- Gold
    Color3.new(0.8, 0.3, 1),    -- Purple
    Color3.new(0.3, 0.8, 1)     -- Blue
}

-- State
local orbModels = {}
local collectedOrbs = {}
local puzzleActive = false
local progressGui = nil
local orbSounds = {}

function HubPuzzleController:CreateOrbModel(position, color, orbId)
    -- Create orb model
    local orbModel = Instance.new("Model")
    orbModel.Name = "PuzzleOrb_" .. orbId
    
    -- Main orb part
    local orb = Instance.new("Part")
    orb.Name = "Orb"
    orb.Size = Vector3.new(2, 2, 2)
    orb.Shape = Enum.PartType.Ball
    orb.Material = Enum.Material.ForceField
    orb.Color = color
    orb.Position = position
    orb.Anchored = true
    orb.CanCollide = false
    orb.Parent = orbModel
    
    -- Add glow effect
    local pointLight = Instance.new("PointLight")
    pointLight.Color = color
    pointLight.Brightness = 2
    pointLight.Range = 15
    pointLight.Parent = orb
    
    -- Add particle effects
    local attachment = Instance.new("Attachment")
    attachment.Parent = orb
    
    -- Sparkle particles
    local sparkles = Instance.new("ParticleEmitter")
    sparkles.Parent = attachment
    sparkles.Texture = "rbxasset://textures/particles/sparkles_main.dds"
    sparkles.Color = ColorSequence.new(color)
    sparkles.Size = NumberSequence.new{
        NumberSequenceKeypoint.new(0, 0.5),
        NumberSequenceKeypoint.new(0.5, 1),
        NumberSequenceKeypoint.new(1, 0.5)
    }
    sparkles.Transparency = NumberSequence.new{
        NumberSequenceKeypoint.new(0, 0.3),
        NumberSequenceKeypoint.new(0.5, 0.1),
        NumberSequenceKeypoint.new(1, 1)
    }
    sparkles.Lifetime = NumberRange.new(1, 2)
    sparkles.Rate = 50
    sparkles.SpreadAngle = Vector2.new(180, 180)
    sparkles.Speed = NumberRange.new(2, 5)
    
    -- Glow particles
    local glow = Instance.new("ParticleEmitter")
    glow.Parent = attachment
    glow.Texture = "rbxasset://textures/particles/fire_main.dds"
    glow.Color = ColorSequence.new(color)
    glow.Size = NumberSequence.new{
        NumberSequenceKeypoint.new(0, 1),
        NumberSequenceKeypoint.new(0.5, 2),
        NumberSequenceKeypoint.new(1, 1)
    }
    glow.Transparency = NumberSequence.new{
        NumberSequenceKeypoint.new(0, 0.8),
        NumberSequenceKeypoint.new(0.5, 0.5),
        NumberSequenceKeypoint.new(1, 1)
    }
    glow.Lifetime = NumberRange.new(0.5, 1)
    glow.Rate = 20
    glow.SpreadAngle = Vector2.new(360, 360)
    glow.Speed = NumberRange.new(0.5, 1)
    
    -- Add floating animation
    local floatTween = TweenService:Create(
        orb,
        TweenInfo.new(3, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true),
        {Position = position + Vector3.new(0, 2, 0)}
    )
    floatTween:Play()
    
    -- Add rotation animation
    local rotationTween = TweenService:Create(
        orb,
        TweenInfo.new(5, Enum.EasingStyle.Linear, Enum.EasingDirection.InOut, -1),
        {Rotation = Vector3.new(0, 360, 0)}
    )
    rotationTween:Play()
    
    -- Add pulsing glow animation
    local glowTween = TweenService:Create(
        pointLight,
        TweenInfo.new(2, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true),
        {Brightness = 4}
    )
    glowTween:Play()
    
    -- Store animations for cleanup
    orb:SetAttribute("FloatTween", floatTween)
    orb:SetAttribute("RotationTween", rotationTween)
    orb:SetAttribute("GlowTween", glowTween)
    
    -- Add collision detection
    local clickDetector = Instance.new("ClickDetector")
    clickDetector.MaxActivationDistance = 10
    clickDetector.Parent = orb
    
    clickDetector.MouseClick:Connect(function(clickingPlayer)
        if clickingPlayer == player then
            self:CollectOrb(orbId)
        end
    end)
    
    -- Add touch detection for mobile
    local connection
    connection = orb.Touched:Connect(function(hit)
        local humanoid = hit.Parent:FindFirstChild("Humanoid")
        if humanoid and hit.Parent == player.Character then
            self:CollectOrb(orbId)
        end
    end)
    
    orb:SetAttribute("TouchConnection", connection)
    
    return orbModel
end

function HubPuzzleController:CreateOrbSound(orbId, color)
    -- Create unique sound for each orb
    local sound = Instance.new("Sound")
    sound.Name = "OrbCollectionSound_" .. orbId
    sound.SoundId = "rbxasset://sounds/electronicpingshort.wav"
    sound.Volume = 0.8
    sound.Parent = SoundService
    
    -- Vary pitch based on orb color for unique sound
    local hue = color.R + color.G + color.B
    sound.Pitch = 0.8 + (hue * 0.6) -- Range from 0.8 to 1.4
    
    return sound
end

function HubPuzzleController:CollectOrb(orbId)
    if collectedOrbs[orbId] or not puzzleActive then return end
    
    print("✨ Collected puzzle orb", orbId)
    
    -- Mark as collected
    collectedOrbs[orbId] = true
    
    -- Play collection sound
    if orbSounds[orbId] then
        orbSounds[orbId]:Play()
    end
    
    -- Create collection effect
    self:PlayCollectionEffect(orbId)
    
    -- Hide the orb
    local orbModel = orbModels[orbId]
    if orbModel then
        self:RemoveOrb(orbModel)
    end
    
    -- Update progress
    self:UpdateProgress()
    
    -- Check if puzzle is complete
    local collectedCount = 0
    for i = 1, 5 do
        if collectedOrbs[i] then
            collectedCount = collectedCount + 1
        end
    end
    
    if collectedCount >= 5 then
        self:CompletePuzzle()
    else
        -- Notify server of individual orb collection
        RemoteEvents.HubPuzzleOrbCollected:FireServer(orbId)
    end
end

function HubPuzzleController:PlayCollectionEffect(orbId)
    local orbModel = orbModels[orbId]
    if not orbModel or not orbModel:FindFirstChild("Orb") then return end
    
    local orb = orbModel.Orb
    local color = ORB_COLORS[orbId]
    
    -- Create burst effect
    local burstGui = Instance.new("BillboardGui")
    burstGui.Size = UDim2.new(4, 0, 4, 0)
    burstGui.StudsOffset = Vector3.new(0, 3, 0)
    burstGui.Parent = orb
    
    local burstFrame = Instance.new("Frame")
    burstFrame.Size = UDim2.new(1, 0, 1, 0)
    burstFrame.BackgroundTransparency = 1
    burstFrame.Parent = burstGui
    
    -- Create sparkle burst
    for i = 1, 15 do
        local sparkle = Instance.new("Frame")
        sparkle.Size = UDim2.new(0, 8, 0, 8)
        sparkle.Position = UDim2.new(0.5, -4, 0.5, -4)
        sparkle.BackgroundColor3 = color
        sparkle.BorderSizePixel = 0
        sparkle.Parent = burstFrame
        
        -- Random burst direction
        local angle = math.rad(i * 24)
        local distance = math.random(50, 100)
        local endX = math.cos(angle) * distance
        local endY = math.sin(angle) * distance
        
        local burstTween = TweenService:Create(
            sparkle,
            TweenInfo.new(1, Enum.EasingStyle.Quart, Enum.EasingDirection.Out),
            {
                Position = UDim2.new(0.5, endX, 0.5, endY),
                BackgroundTransparency = 1,
                Size = UDim2.new(0, 2, 0, 2)
            }
        )
        burstTween:Play()
    end
    
    -- Create "+1 ORB FOUND!" text
    local foundText = Instance.new("TextLabel")
    foundText.Size = UDim2.new(2, 0, 0.3, 0)
    foundText.Position = UDim2.new(-0.5, 0, 0.2, 0)
    foundText.BackgroundTransparency = 1
    foundText.Text = "✨ ORB FOUND! ✨"
    foundText.TextColor3 = color
    foundText.TextScaled = true
    foundText.Font = Enum.Font.SourceSansBold
    foundText.TextStrokeTransparency = 0
    foundText.TextStrokeColor3 = Color3.new(0, 0, 0)
    foundText.Parent = burstFrame
    
    -- Animate text
    local textTween = TweenService:Create(
        foundText,
        TweenInfo.new(2, Enum.EasingStyle.Quart, Enum.EasingDirection.Out),
        {
            Position = UDim2.new(-0.5, 0, -0.5, 0),
            TextTransparency = 1,
            TextStrokeTransparency = 1
        }
    )
    textTween:Play()
    
    -- Clean up effect
    spawn(function()
        wait(2)
        if burstGui then
            burstGui:Destroy()
        end
    end)
end

function HubPuzzleController:RemoveOrb(orbModel)
    if not orbModel then return end
    
    local orb = orbModel:FindFirstChild("Orb")
    if orb then
        -- Stop all animations
        local floatTween = orb:GetAttribute("FloatTween")
        local rotationTween = orb:GetAttribute("RotationTween")
        local glowTween = orb:GetAttribute("GlowTween")
        local touchConnection = orb:GetAttribute("TouchConnection")
        
        if floatTween then floatTween:Cancel() end
        if rotationTween then rotationTween:Cancel() end
        if glowTween then glowTween:Cancel() end
        if touchConnection then touchConnection:Disconnect() end
        
        -- Fade out orb
        local fadeTween = TweenService:Create(
            orb,
            TweenInfo.new(1, Enum.EasingStyle.Quart, Enum.EasingDirection.Out),
            {Transparency = 1, Size = Vector3.new(0.1, 0.1, 0.1)}
        )
        fadeTween:Play()
        
        fadeTween.Completed:Connect(function()
            orbModel:Destroy()
        end)
    end
end

function HubPuzzleController:CreateProgressGUI()
    if progressGui then return end
    
    progressGui = Instance.new("ScreenGui")
    progressGui.Name = "HubPuzzleProgress"
    progressGui.ResetOnSpawn = false
    progressGui.Parent = playerGui
    
    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(0, 300, 0, 80)
    frame.Position = UDim2.new(1, -320, 0, 150)
    frame.BackgroundColor3 = Color3.new(0.1, 0.1, 0.2)
    frame.BackgroundTransparency = 0.3
    frame.BorderSizePixel = 0
    frame.Parent = progressGui
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 10)
    corner.Parent = frame
    
    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(1, 0, 0.4, 0)
    title.Position = UDim2.new(0, 0, 0, 0)
    title.BackgroundTransparency = 1
    title.Text = "🔍 HIDDEN ORBS"
    title.TextColor3 = Color3.new(1, 1, 1)
    title.TextScaled = true
    title.Font = Enum.Font.SourceSansBold
    title.Parent = frame
    
    local progress = Instance.new("TextLabel")
    progress.Name = "ProgressText"
    progress.Size = UDim2.new(1, 0, 0.6, 0)
    progress.Position = UDim2.new(0, 0, 0.4, 0)
    progress.BackgroundTransparency = 1
    progress.Text = "0 / 5 FOUND"
    progress.TextColor3 = Color3.new(0.8, 0.8, 1)
    progress.TextScaled = true
    progress.Font = Enum.Font.SourceSans
    progress.Parent = frame
    
    -- Add orb indicators
    local orbContainer = Instance.new("Frame")
    orbContainer.Size = UDim2.new(1, -20, 0, 20)
    orbContainer.Position = UDim2.new(0, 10, 1, -25)
    orbContainer.BackgroundTransparency = 1
    orbContainer.Parent = frame
    
    local layout = Instance.new("UIListLayout")
    layout.FillDirection = Enum.FillDirection.Horizontal
    layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
    layout.SortOrder = Enum.SortOrder.LayoutOrder
    layout.Padding = UDim.new(0, 5)
    layout.Parent = orbContainer
    
    for i = 1, 5 do
        local orbIndicator = Instance.new("Frame")
        orbIndicator.Name = "Orb" .. i
        orbIndicator.Size = UDim2.new(0, 15, 0, 15)
        orbIndicator.BackgroundColor3 = ORB_COLORS[i]
        orbIndicator.BackgroundTransparency = 0.7
        orbIndicator.BorderSizePixel = 0
        orbIndicator.LayoutOrder = i
        orbIndicator.Parent = orbContainer
        
        local orbCorner = Instance.new("UICorner")
        orbCorner.CornerRadius = UDim.new(1, 0)
        orbCorner.Parent = orbIndicator
    end
end

function HubPuzzleController:UpdateProgress()
    if not progressGui then return end
    
    local frame = progressGui:FindFirstChild("Frame")
    if not frame then return end
    
    local progressText = frame:FindFirstChild("ProgressText")
    local orbContainer = frame:FindFirstChild("Frame")
    
    if not progressText or not orbContainer then return end
    
    -- Count collected orbs
    local collectedCount = 0
    for i = 1, 5 do
        if collectedOrbs[i] then
            collectedCount = collectedCount + 1
            
            -- Update indicator
            local indicator = orbContainer:FindFirstChild("Orb" .. i)
            if indicator then
                indicator.BackgroundTransparency = 0
                
                -- Add glow effect
                local glow = indicator:FindFirstChild("Glow")
                if not glow then
                    glow = Instance.new("Frame")
                    glow.Name = "Glow"
                    glow.Size = UDim2.new(1.4, 0, 1.4, 0)
                    glow.Position = UDim2.new(-0.2, 0, -0.2, 0)
                    glow.BackgroundColor3 = ORB_COLORS[i]
                    glow.BackgroundTransparency = 0.8
                    glow.BorderSizePixel = 0
                    glow.ZIndex = -1
                    glow.Parent = indicator
                    
                    local glowCorner = Instance.new("UICorner")
                    glowCorner.CornerRadius = UDim.new(1, 0)
                    glowCorner.Parent = glow
                    
                    -- Pulse glow
                    local pulseTween = TweenService:Create(
                        glow,
                        TweenInfo.new(1, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true),
                        {BackgroundTransparency = 0.5}
                    )
                    pulseTween:Play()
                end
            end
        end
    end
    
    progressText.Text = collectedCount .. " / 5 FOUND"
    
    if collectedCount >= 5 then
        progressText.Text = "✅ PUZZLE COMPLETE!"
        progressText.TextColor3 = Color3.new(0.3, 1, 0.3)
    end
end

function HubPuzzleController:ShowCompletionReward(rewardType, rewardName)
    -- Create completion popup
    local completionGui = Instance.new("ScreenGui")
    completionGui.Name = "PuzzleCompletion"
    completionGui.ResetOnSpawn = false
    completionGui.Parent = playerGui
    
    local background = Instance.new("Frame")
    background.Size = UDim2.new(1, 0, 1, 0)
    background.BackgroundColor3 = Color3.new(0, 0, 0)
    background.BackgroundTransparency = 0.5
    background.BorderSizePixel = 0
    background.Parent = completionGui
    
    local popup = Instance.new("Frame")
    popup.Size = UDim2.new(0, 400, 0, 300)
    popup.Position = UDim2.new(0.5, -200, 0.5, -150)
    popup.BackgroundColor3 = Color3.new(0.1, 0.1, 0.3)
    popup.BorderSizePixel = 0
    popup.Parent = background
    
    local popupCorner = Instance.new("UICorner")
    popupCorner.CornerRadius = UDim.new(0, 15)
    popupCorner.Parent = popup
    
    -- Title
    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(1, 0, 0.3, 0)
    title.Position = UDim2.new(0, 0, 0, 0)
    title.BackgroundTransparency = 1
    title.Text = "🏆 PUZZLE COMPLETE!"
    title.TextColor3 = Color3.new(1, 0.8, 0.3)
    title.TextScaled = true
    title.Font = Enum.Font.SourceSansBold
    title.Parent = popup
    
    -- Reward text
    local rewardText = Instance.new("TextLabel")
    rewardText.Size = UDim2.new(1, -40, 0.3, 0)
    rewardText.Position = UDim2.new(0, 20, 0.3, 0)
    rewardText.BackgroundTransparency = 1
    rewardText.Text = "🎁 You earned: " .. rewardName
    rewardText.TextColor3 = Color3.new(1, 1, 1)
    rewardText.TextScaled = true
    rewardText.Font = Enum.Font.SourceSans
    rewardText.TextWrapped = true
    rewardText.Parent = popup
    
    -- Close button
    local closeButton = Instance.new("TextButton")
    closeButton.Size = UDim2.new(0, 120, 0, 40)
    closeButton.Position = UDim2.new(0.5, -60, 0.75, 0)
    closeButton.BackgroundColor3 = Color3.new(0.3, 0.6, 1)
    closeButton.Text = "AWESOME!"
    closeButton.TextColor3 = Color3.new(1, 1, 1)
    closeButton.TextScaled = true
    closeButton.Font = Enum.Font.SourceSansBold
    closeButton.BorderSizePixel = 0
    closeButton.Parent = popup
    
    local closeCorner = Instance.new("UICorner")
    closeCorner.CornerRadius = UDim.new(0, 8)
    closeCorner.Parent = closeButton
    
    closeButton.MouseButton1Click:Connect(function()
        completionGui:Destroy()
    end)
    
    -- Animate popup appearance
    popup.Size = UDim2.new(0, 0, 0, 0)
    popup.Position = UDim2.new(0.5, 0, 0.5, 0)
    
    local appearTween = TweenService:Create(
        popup,
        TweenInfo.new(0.5, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
        {
            Size = UDim2.new(0, 400, 0, 300),
            Position = UDim2.new(0.5, -200, 0.5, -150)
        }
    )
    appearTween:Play()
    
    -- Auto-close after 10 seconds
    spawn(function()
        wait(10)
        if completionGui then
            completionGui:Destroy()
        end
    end)
end

function HubPuzzleController:CompletePuzzle()
    print("🏆 Hub puzzle completed!")
    
    -- Notify server
    RemoteEvents.HubPuzzleCompleted:FireServer()
    
    -- Hide progress GUI after a moment
    spawn(function()
        wait(3)
        if progressGui then
            progressGui:Destroy()
            progressGui = nil
        end
    end)
end

function HubPuzzleController:StartPuzzle(puzzleData)
    print("🔍 Starting hub puzzle game...")
    
    puzzleActive = true
    collectedOrbs = {}
    
    -- Clear existing orbs
    for _, orbModel in pairs(orbModels) do
        if orbModel then
            orbModel:Destroy()
        end
    end
    orbModels = {}
    
    -- Create progress GUI
    self:CreateProgressGUI()
    
    -- Create orbs in the hub
    local hubModel = Workspace:FindFirstChild("Hub")
    if not hubModel then
        warn("Hub model not found!")
        return
    end
    
    for i = 1, 5 do
        local orbModel = self:CreateOrbModel(ORB_POSITIONS[i], ORB_COLORS[i], i)
        orbModel.Parent = hubModel
        orbModels[i] = orbModel
        
        -- Create sound for this orb
        orbSounds[i] = self:CreateOrbSound(i, ORB_COLORS[i])
    end
    
    -- Show start notification
    local startGui = Instance.new("ScreenGui")
    startGui.Name = "PuzzleStart"
    startGui.ResetOnSpawn = false
    startGui.Parent = playerGui
    
    local notification = Instance.new("Frame")
    notification.Size = UDim2.new(0, 400, 0, 100)
    notification.Position = UDim2.new(0.5, -200, 0, -100)
    notification.BackgroundColor3 = Color3.new(0.2, 0.1, 0.4)
    notification.BorderSizePixel = 0
    notification.Parent = startGui
    
    local notifCorner = Instance.new("UICorner")
    notifCorner.CornerRadius = UDim.new(0, 10)
    notifCorner.Parent = notification
    
    local notifText = Instance.new("TextLabel")
    notifText.Size = UDim2.new(1, -20, 1, -20)
    notifText.Position = UDim2.new(0, 10, 0, 10)
    notifText.BackgroundTransparency = 1
    notifText.Text = "🔍 FIND 5 HIDDEN ORBS IN THE HUB!"
    notifText.TextColor3 = Color3.new(1, 1, 1)
    notifText.TextScaled = true
    notifText.Font = Enum.Font.SourceSansBold
    notifText.Parent = notification
    
    -- Animate notification
    local slideTween = TweenService:Create(
        notification,
        TweenInfo.new(0.5, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
        {Position = UDim2.new(0.5, -200, 0, 20)}
    )
    slideTween:Play()
    
    -- Hide after 5 seconds
    spawn(function()
        wait(5)
        if startGui then
            local hideStart = TweenService:Create(
                notification,
                TweenInfo.new(0.5, Enum.EasingStyle.Quart, Enum.EasingDirection.In),
                {Position = UDim2.new(0.5, -200, 0, -100)}
            )
            hideStart:Play()
            hideStart.Completed:Connect(function()
                startGui:Destroy()
            end)
        end
    end)
    
    print("✅ Hub puzzle started - find all 5 orbs!")
end

function HubPuzzleController:EndPuzzle()
    print("📝 Ending hub puzzle...")
    
    puzzleActive = false
    collectedOrbs = {}
    
    -- Remove all orbs
    for _, orbModel in pairs(orbModels) do
        if orbModel then
            orbModel:Destroy()
        end
    end
    orbModels = {}
    
    -- Clean up sounds
    for _, sound in pairs(orbSounds) do
        if sound then
            sound:Destroy()
        end
    end
    orbSounds = {}
    
    -- Remove progress GUI
    if progressGui then
        progressGui:Destroy()
        progressGui = nil
    end
end

function HubPuzzleController:Init()
    print("🔍 HubPuzzleController initializing...")
    
    -- Connect remote events
    RemoteEvents.StartHubPuzzle.OnClientEvent:Connect(function(puzzleData)
        self:StartPuzzle(puzzleData)
    end)
    
    RemoteEvents.EndHubPuzzle.OnClientEvent:Connect(function()
        self:EndPuzzle()
    end)
    
    RemoteEvents.HubPuzzleReward.OnClientEvent:Connect(function(rewardType, rewardName)
        self:ShowCompletionReward(rewardType, rewardName)
    end)
    
    -- Request current puzzle state when joining
    spawn(function()
        wait(2) -- Wait for other systems to initialize
        RemoteEvents.RequestHubPuzzleState:FireServer()
    end)
    
    print("✅ HubPuzzleController initialized!")
end

return HubPuzzleController
