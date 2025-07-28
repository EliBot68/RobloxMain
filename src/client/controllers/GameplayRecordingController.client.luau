-- GameplayRecordingController.client.luau
-- Professional gameplay footage capture system with UI management and camera automation
-- Hides debug UI, disables distractions, and provides cinematic camera presets

local Players = game:GetService("Players")
local StarterGui = game:GetService("StarterGui")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
local camera = Workspace.CurrentCamera

local GameplayRecordingController = {}

-- Recording State
local isRecordingMode = false
local originalSettings = {}
local currentCameraPreset = nil
local cameraConnection = nil
local recordingGUI = nil

-- Camera Presets Configuration
local CAMERA_PRESETS = {
    ActionFollow = {
        name = "Action Follow",
        description = "Close follow for single player action",
        distance = 10,
        height = 4,
        fov = 75,
        followSmoothing = 0.15,
        rotationSmoothing = 0.1,
        anticipation = 2,
        shakeReduction = 0.3
    },
    
    DramaticClose = {
        name = "Dramatic Close",
        description = "Intimate camera for tension moments",
        distance = 6,
        height = 2,
        fov = 65,
        followSmoothing = 0.08,
        rotationSmoothing = 0.05,
        anticipation = 1,
        shakeReduction = 0.8,
        dutchAngle = 5
    },
    
    MultiplayerWide = {
        name = "Multiplayer Wide",
        description = "Wide shot for group coverage",
        distance = 18,
        height = 10,
        fov = 90,
        followSmoothing = 0.25,
        rotationSmoothing = 0.2,
        anticipation = 3,
        shakeReduction = 0.1,
        groupTracking = true
    },
    
    CinematicSweep = {
        name = "Cinematic Sweep",
        description = "Sweeping shots for establishing scenes",
        distance = 25,
        height = 15,
        fov = 100,
        followSmoothing = 0.4,
        rotationSmoothing = 0.3,
        anticipation = 0,
        shakeReduction = 0,
        sweepPath = true
    }
}

-- UI Elements to Hide During Recording
local UI_ELEMENTS_TO_HIDE = {
    "TopBarEnabled",
    "HealthGuiEnabled", 
    "PlayerListEnabled",
    "BackpackGuiEnabled",
    "ChatBarDisabled",
    "ResetButtonCallback"
}

function GameplayRecordingController:Init()
    print("🎬 Initializing Gameplay Recording Controller...")
    
    -- Store original settings
    self:StoreOriginalSettings()
    
    -- Create recording GUI
    self:CreateRecordingGUI()
    
    -- Set up hotkeys
    self:SetupHotkeys()
    
    print("✅ Gameplay Recording Controller initialized!")
    print("📹 Press F9 to toggle recording mode")
    print("🎥 Press F1-F4 to switch camera presets during recording")
end

function GameplayRecordingController:StoreOriginalSettings()
    originalSettings = {
        topBarEnabled = StarterGui:GetCoreGuiEnabled(Enum.CoreGuiType.TopBar),
        healthGuiEnabled = StarterGui:GetCoreGuiEnabled(Enum.CoreGuiType.Health),
        playerListEnabled = StarterGui:GetCoreGuiEnabled(Enum.CoreGuiType.PlayerList),
        backpackGuiEnabled = StarterGui:GetCoreGuiEnabled(Enum.CoreGuiType.Backpack),
        chatEnabled = StarterGui:GetCoreGuiEnabled(Enum.CoreGuiType.Chat),
        cameraType = camera.CameraType,
        cameraSubject = camera.CameraSubject,
        fieldOfView = camera.FieldOfView
    }
    
    print("💾 Original UI settings stored")
end

function GameplayRecordingController:CreateRecordingGUI()
    local playerGui = player:WaitForChild("PlayerGui")
    
    -- Main recording control GUI
    recordingGUI = Instance.new("ScreenGui")
    recordingGUI.Name = "GameplayRecording"
    recordingGUI.ResetOnSpawn = false
    recordingGUI.DisplayOrder = 1000
    recordingGUI.Parent = playerGui
    
    -- Recording status indicator
    local statusFrame = Instance.new("Frame")
    statusFrame.Name = "StatusFrame"
    statusFrame.Size = UDim2.new(0, 200, 0, 40)
    statusFrame.Position = UDim2.new(0, 10, 0, 10)
    statusFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
    statusFrame.BackgroundTransparency = 0.2
    statusFrame.BorderSizePixel = 0
    statusFrame.Visible = false
    statusFrame.Parent = recordingGUI
    
    -- Rounded corners
    local statusCorner = Instance.new("UICorner")
    statusCorner.CornerRadius = UDim.new(0, 8)
    statusCorner.Parent = statusFrame
    
    -- Recording indicator
    local recordingDot = Instance.new("Frame")
    recordingDot.Name = "RecordingDot"
    recordingDot.Size = UDim2.new(0, 12, 0, 12)
    recordingDot.Position = UDim2.new(0, 8, 0.5, -6)
    recordingDot.BackgroundColor3 = Color3.fromRGB(255, 100, 100)
    recordingDot.BorderSizePixel = 0
    recordingDot.Parent = statusFrame
    
    local dotCorner = Instance.new("UICorner")
    dotCorner.CornerRadius = UDim.new(1, 0)
    dotCorner.Parent = recordingDot
    
    -- Status text
    local statusLabel = Instance.new("TextLabel")
    statusLabel.Name = "StatusLabel"
    statusLabel.Size = UDim2.new(1, -30, 1, 0)
    statusLabel.Position = UDim2.new(0, 25, 0, 0)
    statusLabel.BackgroundTransparency = 1
    statusLabel.Text = "RECORDING MODE"
    statusLabel.TextColor3 = Color3.new(1, 1, 1)
    statusLabel.TextScaled = true
    statusLabel.Font = Enum.Font.GothamBold
    statusLabel.Parent = statusFrame
    
    -- Camera preset selector
    local presetFrame = Instance.new("Frame")
    presetFrame.Name = "PresetFrame"
    presetFrame.Size = UDim2.new(0, 220, 0, 160)
    presetFrame.Position = UDim2.new(0, 10, 0, 60)
    presetFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
    presetFrame.BackgroundTransparency = 0.1
    presetFrame.BorderSizePixel = 0
    presetFrame.Visible = false
    presetFrame.Parent = recordingGUI
    
    local presetCorner = Instance.new("UICorner")
    presetCorner.CornerRadius = UDim.new(0, 8)
    presetCorner.Parent = presetFrame
    
    -- Preset title
    local presetTitle = Instance.new("TextLabel")
    presetTitle.Name = "PresetTitle"
    presetTitle.Size = UDim2.new(1, 0, 0, 30)
    presetTitle.Position = UDim2.new(0, 0, 0, 0)
    presetTitle.BackgroundTransparency = 1
    presetTitle.Text = "CAMERA PRESETS"
    presetTitle.TextColor3 = Color3.new(1, 1, 1)
    presetTitle.TextScaled = true
    presetTitle.Font = Enum.Font.GothamBold
    presetTitle.Parent = presetFrame
    
    -- Create preset buttons
    local presetNames = {"ActionFollow", "DramaticClose", "MultiplayerWide", "CinematicSweep"}
    local buttonKeys = {"F1", "F2", "F3", "F4"}
    
    for i, presetName in ipairs(presetNames) do
        local button = Instance.new("TextButton")
        button.Name = presetName .. "Button"
        button.Size = UDim2.new(1, -10, 0, 25)
        button.Position = UDim2.new(0, 5, 0, 30 + (i-1) * 30)
        button.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
        button.BorderSizePixel = 0
        button.Text = buttonKeys[i] .. " - " .. CAMERA_PRESETS[presetName].name
        button.TextColor3 = Color3.new(1, 1, 1)
        button.TextScaled = true
        button.Font = Enum.Font.Gotham
        button.Parent = presetFrame
        
        local buttonCorner = Instance.new("UICorner")
        buttonCorner.CornerRadius = UDim.new(0, 4)
        buttonCorner.Parent = button
        
        -- Button click functionality
        button.MouseButton1Click:Connect(function()
            self:ApplyCameraPreset(presetName)
        end)
        
        -- Hover effects
        button.MouseEnter:Connect(function()
            local hoverTween = TweenService:Create(
                button,
                TweenInfo.new(0.2, Enum.EasingStyle.Quad),
                {BackgroundColor3 = Color3.fromRGB(70, 70, 70)}
            )
            hoverTween:Play()
        end)
        
        button.MouseLeave:Connect(function()
            local unhoverTween = TweenService:Create(
                button,
                TweenInfo.new(0.2, Enum.EasingStyle.Quad),
                {BackgroundColor3 = Color3.fromRGB(50, 50, 50)}
            )
            unhoverTween:Play()
        end)
    end
    
    -- Controls help
    local helpFrame = Instance.new("Frame")
    helpFrame.Name = "HelpFrame"
    helpFrame.Size = UDim2.new(0, 200, 0, 80)
    helpFrame.Position = UDim2.new(0, 10, 0, 230)
    helpFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
    helpFrame.BackgroundTransparency = 0.3
    helpFrame.BorderSizePixel = 0
    helpFrame.Visible = false
    helpFrame.Parent = recordingGUI
    
    local helpCorner = Instance.new("UICorner")
    helpCorner.CornerRadius = UDim.new(0, 8)
    helpCorner.Parent = helpFrame
    
    local helpText = Instance.new("TextLabel")
    helpText.Name = "HelpText"
    helpText.Size = UDim2.new(1, -10, 1, -10)
    helpText.Position = UDim2.new(0, 5, 0, 5)
    helpText.BackgroundTransparency = 1
    helpText.Text = "F9 - Toggle Recording\nF1-F4 - Camera Presets\nF5 - Reset Camera\nH - Hide/Show UI"
    helpText.TextColor3 = Color3.new(0.8, 0.8, 0.8)
    helpText.TextScaled = true
    helpText.Font = Enum.Font.Gotham
    helpText.TextXAlignment = Enum.TextXAlignment.Left
    helpText.Parent = helpFrame
    
    -- Store GUI elements
    self.statusFrame = statusFrame
    self.presetFrame = presetFrame
    self.helpFrame = helpFrame
    self.recordingDot = recordingDot
end

function GameplayRecordingController:SetupHotkeys()
    UserInputService.InputBegan:Connect(function(input, gameProcessed)
        if gameProcessed then return end
        
        if input.KeyCode == Enum.KeyCode.F9 then
            self:ToggleRecordingMode()
        elseif isRecordingMode then
            if input.KeyCode == Enum.KeyCode.F1 then
                self:ApplyCameraPreset("ActionFollow")
            elseif input.KeyCode == Enum.KeyCode.F2 then
                self:ApplyCameraPreset("DramaticClose")
            elseif input.KeyCode == Enum.KeyCode.F3 then
                self:ApplyCameraPreset("MultiplayerWide")
            elseif input.KeyCode == Enum.KeyCode.F4 then
                self:ApplyCameraPreset("CinematicSweep")
            elseif input.KeyCode == Enum.KeyCode.F5 then
                self:ResetCamera()
            elseif input.KeyCode == Enum.KeyCode.H then
                self:ToggleRecordingGUI()
            end
        end
    end)
end

function GameplayRecordingController:ToggleRecordingMode()
    isRecordingMode = not isRecordingMode
    
    if isRecordingMode then
        self:EnterRecordingMode()
    else
        self:ExitRecordingMode()
    end
end

function GameplayRecordingController:EnterRecordingMode()
    print("🎬 Entering recording mode...")
    
    -- Hide UI elements
    self:HideGameUI()
    
    -- Show recording GUI
    self:ShowRecordingGUI()
    
    -- Apply default camera preset
    self:ApplyCameraPreset("ActionFollow")
    
    -- Start recording dot animation
    self:StartRecordingAnimation()
    
    print("📹 Recording mode active! All UI hidden for clean footage.")
end

function GameplayRecordingController:ExitRecordingMode()
    print("🎬 Exiting recording mode...")
    
    -- Restore UI elements
    self:RestoreGameUI()
    
    -- Hide recording GUI
    self:HideRecordingGUI()
    
    -- Reset camera
    self:ResetCamera()
    
    -- Stop recording animation
    self:StopRecordingAnimation()
    
    print("✅ Recording mode disabled. UI restored.")
end

function GameplayRecordingController:HideGameUI()
    -- Hide core GUI elements
    StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.TopBar, false)
    StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.PlayerList, false)
    StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Health, false)
    StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Backpack, false)
    StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Chat, false)
    
    -- Hide custom debug UI (if exists)
    local playerGui = player:WaitForChild("PlayerGui")
    
    -- Common debug UI names to hide
    local debugUINames = {
        "DebugGUI", "DeveloperGUI", "TestingGUI", "AdminGUI",
        "StatsGUI", "PerformanceGUI", "DiagnosticsGUI"
    }
    
    for _, uiName in ipairs(debugUINames) do
        local debugUI = playerGui:FindFirstChild(uiName)
        if debugUI then
            debugUI.Enabled = false
        end
    end
    
    print("🙈 Game UI hidden for recording")
end

function GameplayRecordingController:RestoreGameUI()
    -- Restore core GUI elements
    StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.TopBar, originalSettings.topBarEnabled)
    StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.PlayerList, originalSettings.playerListEnabled)
    StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Health, originalSettings.healthGuiEnabled)
    StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Backpack, originalSettings.backpackGuiEnabled)
    StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Chat, originalSettings.chatEnabled)
    
    -- Restore custom debug UI
    local playerGui = player:WaitForChild("PlayerGui")
    
    local debugUINames = {
        "DebugGUI", "DeveloperGUI", "TestingGUI", "AdminGUI",
        "StatsGUI", "PerformanceGUI", "DiagnosticsGUI"
    }
    
    for _, uiName in ipairs(debugUINames) do
        local debugUI = playerGui:FindFirstChild(uiName)
        if debugUI then
            debugUI.Enabled = true
        end
    end
    
    print("👁️ Game UI restored")
end

function GameplayRecordingController:ShowRecordingGUI()
    self.statusFrame.Visible = true
    self.presetFrame.Visible = true
    self.helpFrame.Visible = true
end

function GameplayRecordingController:HideRecordingGUI()
    self.statusFrame.Visible = false
    self.presetFrame.Visible = false
    self.helpFrame.Visible = false
end

function GameplayRecordingController:ToggleRecordingGUI()
    local isVisible = self.statusFrame.Visible
    self.statusFrame.Visible = not isVisible
    self.presetFrame.Visible = not isVisible
    self.helpFrame.Visible = not isVisible
    
    print(isVisible and "🙈 Recording UI hidden" or "👁️ Recording UI shown")
end

function GameplayRecordingController:StartRecordingAnimation()
    -- Animate recording dot
    local function animateDot()
        local pulseIn = TweenService:Create(
            self.recordingDot,
            TweenInfo.new(0.8, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut),
            {BackgroundTransparency = 0.3}
        )
        
        local pulseOut = TweenService:Create(
            self.recordingDot,
            TweenInfo.new(0.8, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut),
            {BackgroundTransparency = 0}
        )
        
        pulseIn:Play()
        pulseIn.Completed:Connect(function()
            if isRecordingMode then
                pulseOut:Play()
                pulseOut.Completed:Connect(function()
                    if isRecordingMode then
                        animateDot()
                    end
                end)
            end
        end)
    end
    
    animateDot()
end

function GameplayRecordingController:StopRecordingAnimation()
    -- Animation will stop automatically when isRecordingMode becomes false
end

function GameplayRecordingController:ApplyCameraPreset(presetName)
    local preset = CAMERA_PRESETS[presetName]
    if not preset then
        warn("❌ Unknown camera preset: " .. presetName)
        return
    end
    
    currentCameraPreset = presetName
    print("🎥 Applying camera preset: " .. preset.name)
    
    -- Set camera type to scriptable
    camera.CameraType = Enum.CameraType.Scriptable
    camera.FieldOfView = preset.fov
    
    -- Disconnect previous camera connection
    if cameraConnection then
        cameraConnection:Disconnect()
    end
    
    -- Start camera following
    if preset.sweepPath then
        self:StartCinematicSweep(preset)
    elseif preset.groupTracking then
        self:StartGroupTracking(preset)
    else
        self:StartPlayerFollowing(preset)
    end
    
    print("✅ Camera preset applied: " .. preset.name)
end

function GameplayRecordingController:StartPlayerFollowing(preset)
    local character = player.Character
    if not character then return end
    
    local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
    if not humanoidRootPart then return end
    
    cameraConnection = RunService.RenderStepped:Connect(function()
        if not humanoidRootPart.Parent then return end
        
        -- Calculate target position
        local playerPosition = humanoidRootPart.Position
        local playerLookDirection = humanoidRootPart.CFrame.LookVector
        
        -- Apply anticipation (camera looks ahead of player movement)
        local anticipatedPosition = playerPosition + (playerLookDirection * preset.anticipation)
        
        -- Calculate camera position
        local targetPosition = anticipatedPosition - (playerLookDirection * preset.distance)
        targetPosition = targetPosition + Vector3.new(0, preset.height, 0)
        
        -- Apply Dutch angle if specified
        local targetCFrame = CFrame.lookAt(targetPosition, anticipatedPosition)
        if preset.dutchAngle then
            local roll = math.rad(preset.dutchAngle)
            targetCFrame = targetCFrame * CFrame.Angles(0, 0, roll)
        end
        
        -- Smooth camera movement
        camera.CFrame = camera.CFrame:Lerp(targetCFrame, preset.followSmoothing)
    end)
end

function GameplayRecordingController:StartGroupTracking(preset)
    cameraConnection = RunService.RenderStepped:Connect(function()
        local players = Players:GetPlayers()
        local positions = {}
        
        -- Collect all player positions
        for _, plr in ipairs(players) do
            if plr.Character and plr.Character:FindFirstChild("HumanoidRootPart") then
                table.insert(positions, plr.Character.HumanoidRootPart.Position)
            end
        end
        
        if #positions == 0 then return end
        
        -- Calculate center point
        local centerPosition = Vector3.new(0, 0, 0)
        for _, pos in ipairs(positions) do
            centerPosition = centerPosition + pos
        end
        centerPosition = centerPosition / #positions
        
        -- Calculate camera position
        local targetPosition = centerPosition - Vector3.new(0, 0, preset.distance)
        targetPosition = targetPosition + Vector3.new(0, preset.height, 0)
        
        local targetCFrame = CFrame.lookAt(targetPosition, centerPosition)
        
        -- Smooth camera movement
        camera.CFrame = camera.CFrame:Lerp(targetCFrame, preset.followSmoothing)
    end)
end

function GameplayRecordingController:StartCinematicSweep(preset)
    local sweepStartTime = tick()
    local sweepDuration = 10 -- 10 second sweep
    
    cameraConnection = RunService.RenderStepped:Connect(function()
        local elapsed = tick() - sweepStartTime
        local progress = (elapsed % sweepDuration) / sweepDuration
        
        -- Create circular sweep path
        local radius = preset.distance
        local height = preset.height
        local angle = progress * math.pi * 2
        
        local centerPosition = Vector3.new(0, 0, 0)
        if player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
            centerPosition = player.Character.HumanoidRootPart.Position
        end
        
        local sweepPosition = centerPosition + Vector3.new(
            math.sin(angle) * radius,
            height,
            math.cos(angle) * radius
        )
        
        local targetCFrame = CFrame.lookAt(sweepPosition, centerPosition)
        
        -- Very smooth movement for cinematic feel
        camera.CFrame = camera.CFrame:Lerp(targetCFrame, preset.followSmoothing)
    end)
end

function GameplayRecordingController:ResetCamera()
    print("🔄 Resetting camera...")
    
    -- Disconnect camera connection
    if cameraConnection then
        cameraConnection:Disconnect()
        cameraConnection = nil
    end
    
    -- Restore original camera settings
    camera.CameraType = originalSettings.cameraType
    camera.CameraSubject = originalSettings.cameraSubject
    camera.FieldOfView = originalSettings.fieldOfView
    
    currentCameraPreset = nil
    print("✅ Camera reset to original settings")
end

-- PUBLIC API METHODS
function GameplayRecordingController:StartRecording()
    if not isRecordingMode then
        self:ToggleRecordingMode()
    end
end

function GameplayRecordingController:StopRecording()
    if isRecordingMode then
        self:ToggleRecordingMode()
    end
end

function GameplayRecordingController:SetCameraPreset(presetName)
    if isRecordingMode then
        self:ApplyCameraPreset(presetName)
    else
        warn("⚠️ Must be in recording mode to change camera presets")
    end
end

function GameplayRecordingController:GetCurrentPreset()
    return currentCameraPreset
end

function GameplayRecordingController:IsRecording()
    return isRecordingMode
end

-- Initialize the controller
spawn(function()
    wait(3) -- Wait for game to fully load
    GameplayRecordingController:Init()
end)

-- Clean up on character respawn
player.CharacterAdded:Connect(function()
    if isRecordingMode and currentCameraPreset then
        spawn(function()
            wait(2) -- Wait for character to fully load
            GameplayRecordingController:ApplyCameraPreset(currentCameraPreset)
        end)
    end
end)

return GameplayRecordingController
