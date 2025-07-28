-- TeleportController.luau
-- Client-side controller for teleport fade effects

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local RemoteEvents = require(ReplicatedStorage.Shared.modules.RemoteEvents)

local TeleportController = {}

-- UI Elements
local fadeGui = nil
local fadeFrame = nil

function TeleportController:CreateFadeUI()
    -- Create fade GUI
    fadeGui = Instance.new("ScreenGui")
    fadeGui.Name = "TeleportFadeGui"
    fadeGui.ResetOnSpawn = false
    fadeGui.Parent = playerGui
    
    -- Fade frame
    fadeFrame = Instance.new("Frame")
    fadeFrame.Size = UDim2.new(1, 0, 1, 0)
    fadeFrame.Position = UDim2.new(0, 0, 0, 0)
    fadeFrame.BackgroundColor3 = Color3.new(0.2, 0.6, 1) -- Blue teleport color
    fadeFrame.BorderSizePixel = 0
    fadeFrame.BackgroundTransparency = 1
    fadeFrame.Visible = false
    fadeFrame.ZIndex = 10
    fadeFrame.Parent = fadeGui
    
    -- Add teleport particles overlay
    local particleFrame = Instance.new("Frame")
    particleFrame.Size = UDim2.new(1, 0, 1, 0)
    particleFrame.Position = UDim2.new(0, 0, 0, 0)
    particleFrame.BackgroundTransparency = 1
    particleFrame.Parent = fadeFrame
    
    -- Create sparkle effect (simulated with ImageLabels)
    for i = 1, 20 do
        local sparkle = Instance.new("ImageLabel")
        sparkle.Size = UDim2.new(0, math.random(10, 30), 0, math.random(10, 30))
        sparkle.Position = UDim2.new(
            0, math.random(0, 800),
            0, math.random(0, 600)
        )
        sparkle.BackgroundTransparency = 1
        sparkle.Image = "rbxasset://textures/particles/sparkles_main.dds"
        sparkle.ImageColor3 = Color3.new(1, 1, 1)
        sparkle.ImageTransparency = 0.3
        sparkle.Parent = particleFrame
        
        -- Animate sparkles
        local moveTween = TweenService:Create(
            sparkle,
            TweenInfo.new(2, Enum.EasingStyle.Linear, Enum.EasingDirection.InOut, -1),
            {
                Position = sparkle.Position + UDim2.new(0, math.random(-100, 100), 0, math.random(-100, 100)),
                Rotation = 360
            }
        )
        
        local fadeTween = TweenService:Create(
            sparkle,
            TweenInfo.new(1, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true),
            {ImageTransparency = 0.8}
        )
        
        -- Store tweens for cleanup
        sparkle:SetAttribute("MoveTween", moveTween)
        sparkle:SetAttribute("FadeTween", fadeTween)
    end
    
    -- Teleport text
    local teleportText = Instance.new("TextLabel")
    teleportText.Size = UDim2.new(0, 400, 0, 100)
    teleportText.Position = UDim2.new(0.5, -200, 0.5, -50)
    teleportText.BackgroundTransparency = 1
    teleportText.Text = "🌀 TELEPORTING..."
    teleportText.TextColor3 = Color3.new(1, 1, 1)
    teleportText.TextScaled = true
    teleportText.Font = Enum.Font.SourceSansBold
    teleportText.TextStrokeTransparency = 0
    teleportText.TextStrokeColor3 = Color3.new(0, 0, 0)
    teleportText.TextTransparency = 1
    teleportText.Parent = fadeFrame
    
    fadeFrame.TeleportText = teleportText
end

function TeleportController:FadeOut()
    if not fadeFrame then return end
    
    print("🌀 Starting teleport fade out...")
    
    fadeFrame.Visible = true
    fadeFrame.BackgroundTransparency = 1
    
    local teleportText = fadeFrame.TeleportText
    if teleportText then
        teleportText.TextTransparency = 1
    end
    
    -- Start sparkle animations
    for _, sparkle in pairs(fadeFrame:GetDescendants()) do
        if sparkle:IsA("ImageLabel") and sparkle.Image ~= "" then
            local moveTween = sparkle:GetAttribute("MoveTween")
            local fadeTween = sparkle:GetAttribute("FadeTween")
            if moveTween then moveTween:Play() end
            if fadeTween then fadeTween:Play() end
        end
    end
    
    -- Fade to blue
    local fadeOutTween = TweenService:Create(
        fadeFrame,
        TweenInfo.new(1, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut),
        {BackgroundTransparency = 0}
    )
    fadeOutTween:Play()
    
    -- Show teleport text
    if teleportText then
        local textTween = TweenService:Create(
            teleportText,
            TweenInfo.new(0.5, Enum.EasingStyle.Sine, Enum.EasingDirection.Out),
            {TextTransparency = 0}
        )
        textTween:Play()
        
        -- Pulse text
        local pulseTween = TweenService:Create(
            teleportText,
            TweenInfo.new(0.5, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true),
            {TextTransparency = 0.3}
        )
        pulseTween:Play()
        
        -- Store for cleanup
        teleportText:SetAttribute("PulseTween", pulseTween)
    end
end

function TeleportController:FadeIn()
    if not fadeFrame or not fadeFrame.Visible then return end
    
    print("✨ Starting teleport fade in...")
    
    local teleportText = fadeFrame.TeleportText
    
    -- Update text
    if teleportText then
        teleportText.Text = "✨ WELCOME BACK!"
        
        -- Stop pulse animation
        local pulseTween = teleportText:GetAttribute("PulseTween")
        if pulseTween then pulseTween:Cancel() end
    end
    
    -- Wait a moment
    wait(0.5)
    
    -- Fade in from blue
    local fadeInTween = TweenService:Create(
        fadeFrame,
        TweenInfo.new(1, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut),
        {BackgroundTransparency = 1}
    )
    
    -- Hide text
    if teleportText then
        local textTween = TweenService:Create(
            teleportText,
            TweenInfo.new(0.5, Enum.EasingStyle.Sine, Enum.EasingDirection.In),
            {TextTransparency = 1}
        )
        textTween:Play()
    end
    
    fadeInTween:Play()
    fadeInTween.Completed:Connect(function()
        fadeFrame.Visible = false
        
        -- Stop all sparkle animations
        for _, sparkle in pairs(fadeFrame:GetDescendants()) do
            if sparkle:IsA("ImageLabel") and sparkle.Image ~= "" then
                local moveTween = sparkle:GetAttribute("MoveTween")
                local fadeTween = sparkle:GetAttribute("FadeTween")
                if moveTween then moveTween:Cancel() end
                if fadeTween then fadeTween:Cancel() end
                
                -- Reset sparkle positions
                sparkle.Position = UDim2.new(
                    0, math.random(0, 800),
                    0, math.random(0, 600)
                )
                sparkle.Rotation = 0
                sparkle.ImageTransparency = 0.3
            end
        end
        
        print("✅ Teleport complete!")
    end)
end

function TeleportController:Initialize()
    print("🌀 TeleportController initializing...")
    
    -- Create fade UI
    self:CreateFadeUI()
    
    -- Connect remote events
    RemoteEvents.TeleportFadeOut.OnClientEvent:Connect(function()
        self:FadeOut()
    end)
    
    RemoteEvents.TeleportFadeIn.OnClientEvent:Connect(function()
        self:FadeIn()
    end)
    
    print("✅ TeleportController initialized!")
end

-- Auto-initialize
TeleportController:Initialize()

return TeleportController
