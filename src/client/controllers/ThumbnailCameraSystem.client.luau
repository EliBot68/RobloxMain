-- ThumbnailCameraSystem.client.luau
-- Professional thumbnail capture system for Color Rush
-- Provides preset camera angles and lighting for promotional screenshots

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local Lighting = game:GetService("Lighting")
local Workspace = game:GetService("Workspace")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
local camera = Workspace.CurrentCamera

local ThumbnailCameraSystem = {}

-- Thumbnail Presets Configuration
local THUMBNAIL_PRESETS = {
    ActionShot = {
        name = "Action Shot - The Dodge",
        description = "Dynamic player dodging obstacles",
        cameraOffset = Vector3.new(8, -3, 12),
        lookAtOffset = Vector3.new(0, 2, 0),
        fov = 75,
        tilt = 12, -- Dutch angle in degrees
        lighting = {
            ambientColor = Color3.fromRGB(50, 50, 80),
            brightness = 0.3,
            sunDirection = Vector3.new(-0.5, -0.8, -0.2),
            sunSize = 8,
            diffuseScale = 1.2,
            specularScale = 0.8
        },
        effects = {
            bloom = {intensity = 2.5, size = 15, threshold = 1.2},
            colorCorrection = {brightness = 0.1, contrast = 0.2, saturation = 0.1},
            sunRays = {intensity = 0.4, spread = 0.1}
        }
    },
    
    GroupShot = {
        name = "Group Shot - Team Rush",
        description = "Multiple players racing together",
        cameraOffset = Vector3.new(0, 15, 25),
        lookAtOffset = Vector3.new(0, 0, 0),
        fov = 85,
        tilt = 0,
        lighting = {
            ambientColor = Color3.fromRGB(80, 80, 120),
            brightness = 0.5,
            sunDirection = Vector3.new(0, -0.9, -0.1),
            sunSize = 12,
            diffuseScale = 1.0,
            specularScale = 1.0
        },
        effects = {
            bloom = {intensity = 2.0, size = 12, threshold = 1.0},
            colorCorrection = {brightness = 0.05, contrast = 0.15, saturation = 0.05},
            sunRays = {intensity = 0.2, spread = 0.05}
        }
    },
    
    Cinematic = {
        name = "Cinematic - The Arena",
        description = "Epic environmental overview",
        cameraOffset = Vector3.new(-20, 5, 30),
        lookAtOffset = Vector3.new(0, 10, 0),
        fov = 100,
        tilt = -5,
        lighting = {
            ambientColor = Color3.fromRGB(30, 30, 60),
            brightness = 0.2,
            sunDirection = Vector3.new(0.3, -0.7, -0.6),
            sunSize = 20,
            diffuseScale = 1.5,
            specularScale = 1.2
        },
        effects = {
            bloom = {intensity = 3.0, size = 20, threshold = 0.8},
            colorCorrection = {brightness = -0.05, contrast = 0.3, saturation = -0.1},
            sunRays = {intensity = 0.6, spread = 0.2},
            atmosphere = {density = 0.3, offset = 0.2, color = Color3.fromRGB(100, 150, 255)}
        }
    }
}

-- State Management
local originalCameraSettings = {}
local originalLightingSettings = {}
local currentPreset = nil
local isCapturing = false
local thumbnailGui = nil

function ThumbnailCameraSystem:Init()
    print("📸 Initializing Thumbnail Camera System...")
    
    -- Store original settings
    self:StoreOriginalSettings()
    
    -- Create thumbnail GUI
    self:CreateThumbnailGUI()
    
    -- Set up input handling
    self:SetupInputHandling()
    
    print("✅ Thumbnail Camera System ready!")
    print("📋 Use number keys 1-3 to switch presets, R to reset, C to capture")
end

function ThumbnailCameraSystem:StoreOriginalSettings()
    -- Store original camera settings
    originalCameraSettings = {
        cameraType = camera.CameraType,
        cframe = camera.CFrame,
        fov = camera.FieldOfView
    }
    
    -- Store original lighting settings
    originalLightingSettings = {
        ambient = Lighting.Ambient,
        brightness = Lighting.Brightness,
        colorShift_Bottom = Lighting.ColorShift_Bottom,
        colorShift_Top = Lighting.ColorShift_Top,
        sunDirection = Lighting.SunDirection,
        sunSize = Lighting.SunSize,
        diffuseScale = Lighting.DiffuseScale,
        specularScale = Lighting.SpecularScale
    }
end

function ThumbnailCameraSystem:CreateThumbnailGUI()
    local playerGui = player:WaitForChild("PlayerGui")
    
    thumbnailGui = Instance.new("ScreenGui")
    thumbnailGui.Name = "ThumbnailCameraGUI"
    thumbnailGui.ResetOnSpawn = false
    thumbnailGui.DisplayOrder = 200
    thumbnailGui.Parent = playerGui
    
    -- Main frame
    local mainFrame = Instance.new("Frame")
    mainFrame.Name = "MainFrame"
    mainFrame.Size = UDim2.new(0, 400, 0, 300)
    mainFrame.Position = UDim2.new(0, 20, 0, 20)
    mainFrame.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
    mainFrame.BorderSizePixel = 0
    mainFrame.Parent = thumbnailGui
    
    -- Add corner radius
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 10)
    corner.Parent = mainFrame
    
    -- Title
    local titleLabel = Instance.new("TextLabel")
    titleLabel.Name = "Title"
    titleLabel.Size = UDim2.new(1, -20, 0, 40)
    titleLabel.Position = UDim2.new(0, 10, 0, 10)
    titleLabel.BackgroundTransparency = 1
    titleLabel.Text = "📸 Thumbnail Camera System"
    titleLabel.TextColor3 = Color3.new(1, 1, 1)
    titleLabel.TextScaled = true
    titleLabel.Font = Enum.Font.GothamBold
    titleLabel.Parent = mainFrame
    
    -- Preset buttons
    local buttonHeight = 50
    local buttonSpacing = 60
    
    for i, presetName in ipairs({"ActionShot", "GroupShot", "Cinematic"}) do
        local preset = THUMBNAIL_PRESETS[presetName]
        
        local button = Instance.new("TextButton")
        button.Name = presetName .. "Button"
        button.Size = UDim2.new(1, -20, 0, buttonHeight)
        button.Position = UDim2.new(0, 10, 0, 50 + (i - 1) * buttonSpacing)
        button.BackgroundColor3 = Color3.fromRGB(60, 120, 200)
        button.BorderSizePixel = 0
        button.Text = i .. ". " .. preset.name
        button.TextColor3 = Color3.new(1, 1, 1)
        button.TextScaled = true
        button.Font = Enum.Font.Gotham
        button.Parent = mainFrame
        
        -- Button corner
        local buttonCorner = Instance.new("UICorner")
        buttonCorner.CornerRadius = UDim.new(0, 5)
        buttonCorner.Parent = button
        
        -- Button functionality
        button.MouseButton1Click:Connect(function()
            self:ApplyPreset(presetName)
        end)
        
        -- Description label
        local descLabel = Instance.new("TextLabel")
        descLabel.Name = presetName .. "Desc"
        descLabel.Size = UDim2.new(1, -20, 0, 20)
        descLabel.Position = UDim2.new(0, 10, 0, 50 + (i - 1) * buttonSpacing + buttonHeight + 5)
        descLabel.BackgroundTransparency = 1
        descLabel.Text = preset.description
        descLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
        descLabel.TextScaled = true
        descLabel.Font = Enum.Font.Gotham
        descLabel.Parent = mainFrame
    end
    
    -- Control instructions
    local controlsFrame = Instance.new("Frame")
    controlsFrame.Name = "Controls"
    controlsFrame.Size = UDim2.new(1, -20, 0, 60)
    controlsFrame.Position = UDim2.new(0, 10, 1, -70)
    controlsFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
    controlsFrame.BorderSizePixel = 0
    controlsFrame.Parent = mainFrame
    
    local controlsCorner = Instance.new("UICorner")
    controlsCorner.CornerRadius = UDim.new(0, 5)
    controlsCorner.Parent = controlsFrame
    
    local controlsText = Instance.new("TextLabel")
    controlsText.Size = UDim2.new(1, -10, 1, -10)
    controlsText.Position = UDim2.new(0, 5, 0, 5)
    controlsText.BackgroundTransparency = 1
    controlsText.Text = "Controls:\n1-3: Switch Presets | R: Reset | C: Capture | H: Hide GUI"
    controlsText.TextColor3 = Color3.fromRGB(255, 255, 100)
    controlsText.TextScaled = true
    controlsText.Font = Enum.Font.Gotham
    controlsText.TextXAlignment = Enum.TextXAlignment.Left
    controlsText.Parent = controlsFrame
end

function ThumbnailCameraSystem:SetupInputHandling()
    UserInputService.InputBegan:Connect(function(input, gameProcessed)
        if gameProcessed then return end
        
        local keyCode = input.KeyCode
        
        if keyCode == Enum.KeyCode.One then
            self:ApplyPreset("ActionShot")
        elseif keyCode == Enum.KeyCode.Two then
            self:ApplyPreset("GroupShot")
        elseif keyCode == Enum.KeyCode.Three then
            self:ApplyPreset("Cinematic")
        elseif keyCode == Enum.KeyCode.R then
            self:ResetToOriginal()
        elseif keyCode == Enum.KeyCode.C then
            self:CaptureScreenshot()
        elseif keyCode == Enum.KeyCode.H then
            self:ToggleGUI()
        end
    end)
end

function ThumbnailCameraSystem:ApplyPreset(presetName)
    local preset = THUMBNAIL_PRESETS[presetName]
    if not preset then return end
    
    currentPreset = presetName
    print("📸 Applying preset: " .. preset.name)
    
    -- Set camera to scriptable
    camera.CameraType = Enum.CameraType.Scriptable
    
    -- Calculate camera position
    local character = player.Character
    local targetPosition = Vector3.new(0, 0, 0)
    
    if character and character.PrimaryPart then
        targetPosition = character.PrimaryPart.Position
    end
    
    -- Apply camera positioning
    local cameraPosition = targetPosition + preset.cameraOffset
    local lookAtPosition = targetPosition + preset.lookAtOffset
    
    -- Create camera CFrame with tilt
    local baseCFrame = CFrame.lookAt(cameraPosition, lookAtPosition)
    local tiltAngle = math.rad(preset.tilt)
    local tiltedCFrame = baseCFrame * CFrame.Angles(0, 0, tiltAngle)
    
    -- Apply camera settings
    camera.CFrame = tiltedCFrame
    camera.FieldOfView = preset.fov
    
    -- Apply lighting
    self:ApplyLighting(preset.lighting)
    
    -- Apply effects
    self:ApplyEffects(preset.effects)
    
    -- Animate camera transition
    local targetCFrame = tiltedCFrame
    local tweenInfo = TweenInfo.new(1.0, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
    local tween = TweenService:Create(camera, tweenInfo, {CFrame = targetCFrame})
    tween:Play()
    
    print("✅ " .. preset.name .. " preset applied!")
end

function ThumbnailCameraSystem:ApplyLighting(lightingConfig)
    -- Apply lighting settings
    Lighting.Ambient = lightingConfig.ambientColor
    Lighting.Brightness = lightingConfig.brightness
    Lighting.SunDirection = lightingConfig.sunDirection
    Lighting.SunSize = lightingConfig.sunSize
    Lighting.DiffuseScale = lightingConfig.diffuseScale
    Lighting.SpecularScale = lightingConfig.specularScale
    
    -- Remove existing lighting effects
    for _, effect in pairs(Lighting:GetChildren()) do
        if effect:IsA("PostEffect") or effect:IsA("Atmosphere") then
            effect:Destroy()
        end
    end
end

function ThumbnailCameraSystem:ApplyEffects(effectsConfig)
    -- Bloom effect
    if effectsConfig.bloom then
        local bloom = Instance.new("BloomEffect")
        bloom.Intensity = effectsConfig.bloom.intensity
        bloom.Size = effectsConfig.bloom.size
        bloom.Threshold = effectsConfig.bloom.threshold
        bloom.Parent = Lighting
    end
    
    -- Color correction
    if effectsConfig.colorCorrection then
        local colorCorrection = Instance.new("ColorCorrectionEffect")
        colorCorrection.Brightness = effectsConfig.colorCorrection.brightness
        colorCorrection.Contrast = effectsConfig.colorCorrection.contrast
        colorCorrection.Saturation = effectsConfig.colorCorrection.saturation
        colorCorrection.Parent = Lighting
    end
    
    -- Sun rays
    if effectsConfig.sunRays then
        local sunRays = Instance.new("SunRaysEffect")
        sunRays.Intensity = effectsConfig.sunRays.intensity
        sunRays.Spread = effectsConfig.sunRays.spread
        sunRays.Parent = Lighting
    end
    
    -- Atmosphere (for cinematic shots)
    if effectsConfig.atmosphere then
        local atmosphere = Instance.new("Atmosphere")
        atmosphere.Density = effectsConfig.atmosphere.density
        atmosphere.Offset = effectsConfig.atmosphere.offset
        atmosphere.Color = effectsConfig.atmosphere.color
        atmosphere.Parent = Lighting
    end
end

function ThumbnailCameraSystem:ResetToOriginal()
    print("🔄 Resetting to original camera and lighting...")
    
    -- Reset camera
    camera.CameraType = originalCameraSettings.cameraType
    camera.CFrame = originalCameraSettings.cframe
    camera.FieldOfView = originalCameraSettings.fov
    
    -- Reset lighting
    Lighting.Ambient = originalLightingSettings.ambient
    Lighting.Brightness = originalLightingSettings.brightness
    Lighting.ColorShift_Bottom = originalLightingSettings.colorShift_Bottom
    Lighting.ColorShift_Top = originalLightingSettings.colorShift_Top
    Lighting.SunDirection = originalLightingSettings.sunDirection
    Lighting.SunSize = originalLightingSettings.sunSize
    Lighting.DiffuseScale = originalLightingSettings.diffuseScale
    Lighting.SpecularScale = originalLightingSettings.specularScale
    
    -- Remove effects
    for _, effect in pairs(Lighting:GetChildren()) do
        if effect:IsA("PostEffect") or effect:IsA("Atmosphere") then
            effect:Destroy()
        end
    end
    
    currentPreset = nil
    print("✅ Reset complete!")
end

function ThumbnailCameraSystem:CaptureScreenshot()
    if not currentPreset then
        print("⚠️ No preset active. Apply a preset first!")
        return
    end
    
    isCapturing = true
    
    -- Hide GUI temporarily
    if thumbnailGui then
        thumbnailGui.Enabled = false
    end
    
    print("📸 Capturing screenshot in 3 seconds...")
    print("📋 Position your character and prepare the scene!")
    
    -- Countdown
    for i = 3, 1, -1 do
        wait(1)
        print("📸 " .. i .. "...")
    end
    
    -- Capture moment
    print("📸 CAPTURE! Screenshot taken!")
    print("💡 Use Roblox's screenshot feature (Print Screen) now!")
    
    wait(2)
    
    -- Show GUI again
    if thumbnailGui then
        thumbnailGui.Enabled = true
    end
    
    isCapturing = false
end

function ThumbnailCameraSystem:ToggleGUI()
    if thumbnailGui then
        thumbnailGui.Enabled = not thumbnailGui.Enabled
        print(thumbnailGui.Enabled and "📺 GUI shown" or "📺 GUI hidden")
    end
end

function ThumbnailCameraSystem:GetPresetInfo()
    print("\n📋 Available Thumbnail Presets:")
    print("=" .. string.rep("=", 40))
    
    for i, presetName in ipairs({"ActionShot", "GroupShot", "Cinematic"}) do
        local preset = THUMBNAIL_PRESETS[presetName]
        print(i .. ". " .. preset.name)
        print("   " .. preset.description)
        print("   FOV: " .. preset.fov .. "°, Tilt: " .. preset.tilt .. "°")
        print()
    end
    
    print("🎮 Controls:")
    print("  1-3: Apply presets")
    print("  R: Reset to original")
    print("  C: Capture countdown") 
    print("  H: Toggle GUI")
    print("=" .. string.rep("=", 40))
end

-- Advanced positioning functions
function ThumbnailCameraSystem:PositionCharacterForAction()
    local character = player.Character
    if not character then return end
    
    local humanoid = character:FindFirstChild("Humanoid")
    local rootPart = character:FindFirstChild("HumanoidRootPart")
    
    if humanoid and rootPart then
        -- Set character in jumping/dodging pose
        humanoid.PlatformStand = true
        rootPart.CFrame = rootPart.CFrame * CFrame.Angles(0, 0, math.rad(15)) -- Lean
        
        -- Animate limbs for action pose
        spawn(function()
            wait(0.5)
            humanoid.PlatformStand = false
        end)
        
        print("🏃 Character positioned for action shot!")
    end
end

function ThumbnailCameraSystem:CreateMultipleCharacters()
    -- This would spawn additional characters for group shots
    print("👥 Multiple character positioning would be implemented here")
    print("💡 Tip: Use team create mode with multiple developers")
end

-- Initialize system
spawn(function()
    wait(2) -- Wait for everything to load
    ThumbnailCameraSystem:Init()
    ThumbnailCameraSystem:GetPresetInfo()
end)

return ThumbnailCameraSystem
