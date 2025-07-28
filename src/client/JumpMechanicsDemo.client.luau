-- JumpMechanicsDemo.client.luau
-- Demo script showing jump mechanics integration and testing

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- Wait for RemoteEvents to be available
local SafeRequire = require(ReplicatedStorage.Shared.utils.SafeRequire)
local RemoteEvents
repeat
    wait(0.1)
    RemoteEvents = SafeRequire.require(ReplicatedStorage.Shared.modules.RemoteEvents)
until RemoteEvents

-- Demo UI
local demoGui = Instance.new("ScreenGui")
demoGui.Name = "JumpMechanicsDemo"
demoGui.ResetOnSpawn = false
demoGui.Parent = playerGui

local mainFrame = Instance.new("Frame")
mainFrame.Name = "DemoPanel"
mainFrame.Size = UDim2.new(0, 300, 0, 400)
mainFrame.Position = UDim2.new(0, 20, 0, 20)
mainFrame.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
mainFrame.BorderSizePixel = 0
mainFrame.Parent = demoGui

local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0, 10)
corner.Parent = mainFrame

-- Title
local title = Instance.new("TextLabel")
title.Name = "Title"
title.Size = UDim2.new(1, 0, 0, 40)
title.Position = UDim2.new(0, 0, 0, 0)
title.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
title.BorderSizePixel = 0
title.Text = "🦘 Jump Mechanics Demo"
title.TextColor3 = Color3.new(1, 1, 1)
title.TextSize = 18
title.Font = Enum.Font.SourceSansBold
title.Parent = mainFrame

local titleCorner = Instance.new("UICorner")
titleCorner.CornerRadius = UDim.new(0, 10)
titleCorner.Parent = title

-- Status labels
local statusFrame = Instance.new("Frame")
statusFrame.Name = "StatusFrame"
statusFrame.Size = UDim2.new(1, -20, 0, 200)
statusFrame.Position = UDim2.new(0, 10, 0, 50)
statusFrame.BackgroundTransparency = 1
statusFrame.Parent = mainFrame

local statusLabels = {}
local statusTypes = {"CanJump", "IsJumping", "IsInAir", "JumpCount", "Platform"}

for i, statusType in ipairs(statusTypes) do
    local label = Instance.new("TextLabel")
    label.Name = statusType .. "Label"
    label.Size = UDim2.new(1, 0, 0, 30)
    label.Position = UDim2.new(0, 0, 0, (i-1) * 35)
    label.BackgroundTransparency = 1
    label.Text = statusType .. ": Unknown"
    label.TextColor3 = Color3.new(1, 1, 1)
    label.TextSize = 14
    label.Font = Enum.Font.SourceSans
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Parent = statusFrame
    
    statusLabels[statusType] = label
end

-- Control buttons
local buttonFrame = Instance.new("Frame")
buttonFrame.Name = "ButtonFrame"
buttonFrame.Size = UDim2.new(1, -20, 0, 100)
buttonFrame.Position = UDim2.new(0, 10, 0, 270)
buttonFrame.BackgroundTransparency = 1
buttonFrame.Parent = mainFrame

-- Jump button
local jumpButton = Instance.new("TextButton")
jumpButton.Name = "JumpButton"
jumpButton.Size = UDim2.new(1, 0, 0, 40)
jumpButton.Position = UDim2.new(0, 0, 0, 0)
jumpButton.BackgroundColor3 = Color3.fromRGB(100, 200, 100)
jumpButton.BorderSizePixel = 0
jumpButton.Text = "🦘 JUMP (Space)"
jumpButton.TextColor3 = Color3.new(1, 1, 1)
jumpButton.TextSize = 16
jumpButton.Font = Enum.Font.SourceSansBold
jumpButton.Parent = buttonFrame

local jumpCorner = Instance.new("UICorner")
jumpCorner.CornerRadius = UDim.new(0, 8)
jumpCorner.Parent = jumpButton

-- Toggle effects button
local effectsButton = Instance.new("TextButton")
effectsButton.Name = "EffectsButton"
effectsButton.Size = UDim2.new(1, 0, 0, 40)
effectsButton.Position = UDim2.new(0, 0, 0, 50)
effectsButton.BackgroundColor3 = Color3.fromRGB(100, 150, 200)
effectsButton.BorderSizePixel = 0
effectsButton.Text = "✨ Toggle Effects: ON"
effectsButton.TextColor3 = Color3.new(1, 1, 1)
effectsButton.TextSize = 16
effectsButton.Font = Enum.Font.SourceSansBold
effectsButton.Parent = buttonFrame

local effectsCorner = Instance.new("UICorner")
effectsCorner.CornerRadius = UDim.new(0, 8)
effectsCorner.Parent = effectsButton

-- Demo state
local demoState = {
    canJump = true,
    isJumping = false,
    isInAir = false,
    jumpCount = 0,
    effectsEnabled = true,
    platform = UserInputService.TouchEnabled and "Mobile" or "Desktop"
}

-- Update status display
local function updateStatus()
    statusLabels.CanJump.Text = "Can Jump: " .. (demoState.canJump and "✅ YES" or "❌ NO")
    statusLabels.CanJump.TextColor3 = demoState.canJump and Color3.fromRGB(100, 255, 100) or Color3.fromRGB(255, 100, 100)
    
    statusLabels.IsJumping.Text = "Is Jumping: " .. (demoState.isJumping and "✅ YES" or "❌ NO")
    statusLabels.IsJumping.TextColor3 = demoState.isJumping and Color3.fromRGB(255, 255, 100) or Color3.fromRGB(200, 200, 200)
    
    statusLabels.IsInAir.Text = "Is In Air: " .. (demoState.isInAir and "✅ YES" or "❌ NO")
    statusLabels.IsInAir.TextColor3 = demoState.isInAir and Color3.fromRGB(100, 200, 255) or Color3.fromRGB(200, 200, 200)
    
    statusLabels.JumpCount.Text = "Jump Count: " .. demoState.jumpCount
    statusLabels.JumpCount.TextColor3 = Color3.fromRGB(255, 200, 100)
    
    statusLabels.Platform.Text = "Platform: " .. demoState.platform
    statusLabels.Platform.TextColor3 = Color3.fromRGB(200, 150, 255)
end

-- Simulate jump mechanics
local function attemptJump()
    if not demoState.canJump or demoState.isJumping or demoState.isInAir then
        print("❌ Jump blocked - conditions not met")
        return false
    end
    
    -- Simulate jump
    demoState.canJump = false
    demoState.isJumping = true
    demoState.isInAir = true
    demoState.jumpCount = demoState.jumpCount + 1
    
    print("🦘 Demo jump executed! Count: " .. demoState.jumpCount)
    
    -- Try to execute real jump if character available
    local character = player.Character
    if character and character:FindFirstChild("Humanoid") then
        character.Humanoid.Jump = true
        
        -- Notify server if available
        if RemoteEvents.PlayerJumped then
            RemoteEvents.PlayerJumped:FireServer()
        end
    end
    
    updateStatus()
    
    -- Simulate landing after delay
    spawn(function()
        wait(1) -- Simulate jump duration
        demoState.isJumping = false
        
        wait(0.5) -- Simulate air time
        demoState.isInAir = false
        
        wait(0.5) -- Simulate cooldown
        demoState.canJump = true
        
        updateStatus()
        print("✅ Jump completed - ready for next jump")
    end)
    
    return true
end

-- Button connections
jumpButton.MouseButton1Click:Connect(function()
    attemptJump()
end)

effectsButton.MouseButton1Click:Connect(function()
    demoState.effectsEnabled = not demoState.effectsEnabled
    effectsButton.Text = "✨ Toggle Effects: " .. (demoState.effectsEnabled and "ON" or "OFF")
    effectsButton.BackgroundColor3 = demoState.effectsEnabled and Color3.fromRGB(100, 150, 200) or Color3.fromRGB(150, 100, 100)
    
    -- Try to update global jump mechanics if available
    if _G.JumpMechanics then
        _G.JumpMechanics:SetEffectsEnabled(demoState.effectsEnabled)
    end
    
    print("🎨 Effects " .. (demoState.effectsEnabled and "enabled" or "disabled"))
end)

-- Keyboard input
UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    
    if input.KeyCode == Enum.KeyCode.Space then
        attemptJump()
    elseif input.KeyCode == Enum.KeyCode.H then
        -- Toggle demo panel
        mainFrame.Visible = not mainFrame.Visible
    end
end)

-- Listen for remote events if available
if RemoteEvents.JumpValidated then
    RemoteEvents.JumpValidated.OnClientEvent:Connect(function(isValid, reason)
        if isValid then
            print("✅ Server validated jump")
        else
            print("❌ Server rejected jump: " .. (reason or "Unknown"))
            -- Reset demo state if server rejects
            demoState.canJump = true
            demoState.isJumping = false
            updateStatus()
        end
    end)
end

if RemoteEvents.UpdateJumpState then
    RemoteEvents.UpdateJumpState.OnClientEvent:Connect(function(serverState)
        -- Update demo state with server state
        demoState.canJump = serverState.canJump
        demoState.isJumping = serverState.isJumping
        demoState.isInAir = serverState.isInAir
        if serverState.jumpCount then
            demoState.jumpCount = serverState.jumpCount
        end
        updateStatus()
        print("📡 Server state update received")
    end)
end

-- Initial status update
updateStatus()

-- Instructions
print("🦘 Jump Mechanics Demo loaded!")
print("   - Press SPACE or click JUMP button to jump")
print("   - Press H to toggle demo panel")
print("   - Effects button toggles visual/audio effects")

-- Show instructions in UI
local instructions = Instance.new("TextLabel")
instructions.Name = "Instructions"
instructions.Size = UDim2.new(1, -20, 0, 30)
instructions.Position = UDim2.new(0, 10, 1, -40)
instructions.BackgroundTransparency = 1
instructions.Text = "Press H to toggle | Space to jump"
instructions.TextColor3 = Color3.fromRGB(150, 150, 150)
instructions.TextSize = 12
instructions.Font = Enum.Font.SourceSans
instructions.TextXAlignment = Enum.TextXAlignment.Center
instructions.Parent = mainFrame
