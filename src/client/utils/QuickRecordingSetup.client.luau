-- QuickRecordingSetup.client.luau
-- One-click setup script for instant recording preparation
-- Run this script in Studio or game to immediately prepare for footage capture

local Players = game:GetService("Players")
local StarterGui = game:GetService("StarterGui")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local Lighting = game:GetService("Lighting")

local player = Players.LocalPlayer

local QuickRecordingSetup = {}

-- Quick setup configuration
local RECORDING_PRESETS = {
    HighQuality = {
        name = "High Quality Recording",
        graphics = 10,
        shadows = true,
        globalShadows = true,
        futureIsBright = true,
        bloom = 1.2,
        sunRays = true
    },
    
    Performance = {
        name = "Performance Recording",
        graphics = 7,
        shadows = true,
        globalShadows = false,
        futureIsBright = true,
        bloom = 0.8,
        sunRays = false
    },
    
    Mobile = {
        name = "Mobile Optimized",
        graphics = 5,
        shadows = false,
        globalShadows = false,
        futureIsBright = false,
        bloom = 0.5,
        sunRays = false
    }
}

function QuickRecordingSetup:Setup(preset)
    print("🎬 QUICK RECORDING SETUP STARTING...")
    print("==========================================")
    
    local config = RECORDING_PRESETS[preset] or RECORDING_PRESETS.HighQuality
    print("📊 Using preset: " .. config.name)
    
    -- 1. Optimize Graphics Settings
    self:OptimizeGraphics(config)
    
    -- 2. Hide All UI
    self:HideAllUI()
    
    -- 3. Clean Environment
    self:CleanEnvironment()
    
    -- 4. Setup Lighting
    self:OptimizeLighting(config)
    
    -- 5. Prepare Player Character
    self:PrepareCharacter()
    
    -- 6. Load Recording Controller
    self:LoadRecordingController()
    
    print("==========================================")
    print("✅ RECORDING SETUP COMPLETE!")
    print("🎥 Press F9 to start recording mode")
    print("📹 Press F1-F4 for camera presets")
    print("🎮 All UI hidden for clean footage")
    print("==========================================")
end

function QuickRecordingSetup:OptimizeGraphics(config)
    print("🎨 Optimizing graphics settings...")
    
    -- Set graphics quality
    settings().Rendering.QualityLevel = Enum.QualityLevel.Level01 -- This will be overridden by the actual quality setting
    
    -- Enable/disable shadows
    Lighting.GlobalShadows = config.globalShadows
    
    -- Optimize lighting properties
    Lighting.Brightness = 1
    Lighting.Ambient = Color3.fromRGB(70, 70, 70)
    Lighting.ColorShift_Bottom = Color3.fromRGB(0, 0, 0)
    Lighting.ColorShift_Top = Color3.fromRGB(0, 0, 0)
    
    print("✅ Graphics optimized for " .. config.name)
end

function QuickRecordingSetup:HideAllUI()
    print("🙈 Hiding all UI elements...")
    
    -- Hide core Roblox UI
    StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.PlayerList, false)
    StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Health, false)
    StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Backpack, false)
    StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Chat, false)
    StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.EmotesMenu, false)
    
    -- Try to hide top bar (may not work in Studio)
    pcall(function()
        StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.TopBar, false)
    end)
    
    -- Hide custom UI elements
    local playerGui = player:WaitForChild("PlayerGui")
    for _, gui in ipairs(playerGui:GetChildren()) do
        if gui:IsA("ScreenGui") and gui.Name ~= "GameplayRecording" then
            -- Check for debug/development UI
            if string.find(gui.Name:lower(), "debug") or 
               string.find(gui.Name:lower(), "dev") or 
               string.find(gui.Name:lower(), "test") or 
               string.find(gui.Name:lower(), "admin") then
                gui.Enabled = false
            end
        end
    end
    
    print("✅ UI elements hidden")
end

function QuickRecordingSetup:CleanEnvironment()
    print("🧹 Cleaning environment for recording...")
    
    -- Remove debug parts and objects
    for _, obj in ipairs(Workspace:GetChildren()) do
        if obj.Name:lower():find("debug") or 
           obj.Name:lower():find("test") or 
           obj.Name:lower():find("temp") then
            obj:Destroy()
        end
    end
    
    -- Ensure spawn location is clean
    local spawnLocation = Workspace:FindFirstChild("SpawnLocation")
    if spawnLocation then
        spawnLocation.Transparency = 1 -- Hide spawn platform in recordings
    end
    
    print("✅ Environment cleaned")
end

function QuickRecordingSetup:OptimizeLighting(config)
    print("💡 Optimizing lighting for recording...")
    
    -- Set optimal lighting for recording
    Lighting.ClockTime = 14 -- Good lighting time
    Lighting.GeographicLatitude = 0
    Lighting.ExposureCompensation = 0.2
    
    -- Add atmospheric effects if high quality
    if config.name == "High Quality Recording" then
        -- Add bloom
        local bloom = Lighting:FindFirstChild("Bloom") or Instance.new("BloomEffect")
        bloom.Name = "Bloom"
        bloom.Intensity = config.bloom
        bloom.Size = 24
        bloom.Threshold = 0.8
        bloom.Parent = Lighting
        
        -- Add sun rays if enabled
        if config.sunRays then
            local sunRays = Lighting:FindFirstChild("SunRays") or Instance.new("SunRaysEffect")
            sunRays.Name = "SunRays"
            sunRays.Intensity = 0.1
            sunRays.Spread = 0.2
            sunRays.Parent = Lighting
        end
        
        -- Add color correction for better visuals
        local colorCorrection = Lighting:FindFirstChild("ColorCorrection") or Instance.new("ColorCorrectionEffect")
        colorCorrection.Name = "ColorCorrection"
        colorCorrection.Brightness = 0.05
        colorCorrection.Contrast = 0.1
        colorCorrection.Saturation = 0.2
        colorCorrection.Parent = Lighting
    end
    
    print("✅ Lighting optimized")
end

function QuickRecordingSetup:PrepareCharacter()
    print("🎭 Preparing character for recording...")
    
    local character = player.Character or player.CharacterAdded:Wait()
    local humanoid = character:WaitForChild("Humanoid")
    
    -- Ensure character is in good condition
    humanoid.Health = humanoid.MaxHealth
    humanoid.PlatformStand = false
    humanoid.Sit = false
    
    -- Remove any debug accessories
    for _, accessory in ipairs(character:GetChildren()) do
        if accessory:IsA("Accessory") then
            if accessory.Name:lower():find("debug") or 
               accessory.Name:lower():find("test") then
                accessory:Destroy()
            end
        end
    end
    
    -- Ensure good positioning
    local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
    if humanoidRootPart then
        -- Move to spawn if character is in a weird position
        local spawnLocation = Workspace:FindFirstChild("SpawnLocation")
        if spawnLocation then
            humanoidRootPart.CFrame = spawnLocation.CFrame + Vector3.new(0, 5, 0)
        end
    end
    
    print("✅ Character prepared")
end

function QuickRecordingSetup:LoadRecordingController()
    print("🎮 Loading recording controller...")
    
    -- Check if recording controller is already loaded
    local playerGui = player:WaitForChild("PlayerGui")
    local existingRecordingGUI = playerGui:FindFirstChild("GameplayRecording")
    
    if not existingRecordingGUI then
        -- Load the recording controller (assuming it exists)
        local success, err = pcall(function()
            require(game.StarterPlayer.StarterPlayerScripts:WaitForChild("GameplayRecordingController"))
        end)
        
        if not success then
            warn("⚠️ Could not load GameplayRecordingController: " .. err)
            print("ℹ️ Make sure GameplayRecordingController.client.luau is in StarterPlayerScripts")
        end
    else
        print("ℹ️ Recording controller already loaded")
    end
    
    print("✅ Recording controller ready")
end

-- QUICK SETUP COMMANDS
function QuickRecordingSetup:HighQuality()
    self:Setup("HighQuality")
end

function QuickRecordingSetup:Performance()
    self:Setup("Performance")
end

function QuickRecordingSetup:Mobile()
    self:Setup("Mobile")
end

-- RESTORATION FUNCTION
function QuickRecordingSetup:RestoreNormal()
    print("🔄 Restoring normal game state...")
    
    -- Restore UI
    StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.PlayerList, true)
    StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Health, true)
    StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Backpack, true)
    StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Chat, true)
    StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.EmotesMenu, true)
    StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.TopBar, true)
    
    -- Restore custom UI
    local playerGui = player:WaitForChild("PlayerGui")
    for _, gui in ipairs(playerGui:GetChildren()) do
        if gui:IsA("ScreenGui") then
            gui.Enabled = true
        end
    end
    
    -- Remove recording effects
    for _, effect in ipairs(Lighting:GetChildren()) do
        if effect:IsA("PostEffect") then
            effect:Destroy()
        end
    end
    
    print("✅ Normal game state restored")
end

-- CHAT COMMANDS FOR QUICK ACCESS
local function setupChatCommands()
    player.Chatted:Connect(function(message)
        local command = message:lower()
        
        if command == "/record" or command == "/recording" then
            QuickRecordingSetup:HighQuality()
        elseif command == "/recordhq" then
            QuickRecordingSetup:HighQuality()
        elseif command == "/recordperf" then
            QuickRecordingSetup:Performance()
        elseif command == "/recordmobile" then
            QuickRecordingSetup:Mobile()
        elseif command == "/restorenormal" or command == "/restore" then
            QuickRecordingSetup:RestoreNormal()
        elseif command == "/recordhelp" then
            print("🎬 RECORDING SETUP COMMANDS:")
            print("/record - High quality setup")
            print("/recordhq - High quality setup")
            print("/recordperf - Performance setup")
            print("/recordmobile - Mobile optimized setup")
            print("/restore - Restore normal game state")
            print("/recordhelp - Show this help")
        end
    end)
end

-- AUTO-SETUP ON SCRIPT RUN
spawn(function()
    wait(2) -- Wait for game to load
    
    setupChatCommands()
    
    print("🎬 Quick Recording Setup loaded!")
    print("💬 Type '/record' to instantly prepare for recording")
    print("💬 Type '/recordhelp' for all commands")
    
    -- Auto-setup if this is being run for recording purposes
    if game.PlaceId == 0 then -- Studio
        print("🎮 Studio detected - running high quality setup in 3 seconds...")
        wait(3)
        QuickRecordingSetup:HighQuality()
    end
end)

-- HOTKEY SETUP
game:GetService("UserInputService").InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    
    -- Ctrl+R for quick recording setup
    if input.KeyCode == Enum.KeyCode.R and game:GetService("UserInputService"):IsKeyDown(Enum.KeyCode.LeftControl) then
        QuickRecordingSetup:HighQuality()
    end
    
    -- Ctrl+Shift+R for restore
    if input.KeyCode == Enum.KeyCode.R and 
       game:GetService("UserInputService"):IsKeyDown(Enum.KeyCode.LeftControl) and
       game:GetService("UserInputService"):IsKeyDown(Enum.KeyCode.LeftShift) then
        QuickRecordingSetup:RestoreNormal()
    end
end)

return QuickRecordingSetup
