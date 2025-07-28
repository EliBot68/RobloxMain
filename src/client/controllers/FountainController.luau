-- FountainController.luau
-- Client-side controller for fountain interactions and effects

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterGui = game:GetService("StarterGui")
local SoundService = game:GetService("SoundService")
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local RemoteEvents = require(ReplicatedStorage.Shared.modules.RemoteEvents)

local FountainController = {}

-- UI Elements
local fountainGui = nil
local rewardFrame = nil
local cooldownFrame = nil

-- Effect tracking
local activeMultipliers = {}
local specialEffects = {}

function FountainController:CreateFountainUI()
    -- Create main GUI
    fountainGui = Instance.new("ScreenGui")
    fountainGui.Name = "FountainGui"
    fountainGui.ResetOnSpawn = false
    fountainGui.Parent = playerGui
    
    -- Reward display frame
    rewardFrame = Instance.new("Frame")
    rewardFrame.Size = UDim2.new(0, 400, 0, 200)
    rewardFrame.Position = UDim2.new(0.5, -200, 0.3, -100)
    rewardFrame.BackgroundColor3 = Color3.new(0.1, 0.1, 0.2)
    rewardFrame.BorderSizePixel = 0
    rewardFrame.Visible = false
    rewardFrame.Parent = fountainGui
    
    -- Add rounded corners
    local rewardCorner = Instance.new("UICorner")
    rewardCorner.CornerRadius = UDim.new(0, 15)
    rewardCorner.Parent = rewardFrame
    
    -- Add gradient
    local gradient = Instance.new("UIGradient")
    gradient.Color = ColorSequence.new{
        ColorSequenceKeypoint.new(0, Color3.new(0.2, 0.1, 0.4)),
        ColorSequenceKeypoint.new(1, Color3.new(0.1, 0.1, 0.2))
    }
    gradient.Rotation = 45
    gradient.Parent = rewardFrame
    
    -- Reward title
    local rewardTitle = Instance.new("TextLabel")
    rewardTitle.Size = UDim2.new(1, -20, 0, 50)
    rewardTitle.Position = UDim2.new(0, 10, 0, 10)
    rewardTitle.BackgroundTransparency = 1
    rewardTitle.Text = "🎁 FOUNTAIN BLESSING!"
    rewardTitle.TextColor3 = Color3.new(1, 1, 0.6)
    rewardTitle.TextScaled = true
    rewardTitle.Font = Enum.Font.SourceSansBold
    rewardTitle.TextStrokeTransparency = 0
    rewardTitle.TextStrokeColor3 = Color3.new(0, 0, 0)
    rewardTitle.Parent = rewardFrame
    
    -- Reward name
    local rewardName = Instance.new("TextLabel")
    rewardName.Name = "RewardName"
    rewardName.Size = UDim2.new(1, -20, 0, 40)
    rewardName.Position = UDim2.new(0, 10, 0, 60)
    rewardName.BackgroundTransparency = 1
    rewardName.Text = ""
    rewardName.TextColor3 = Color3.new(1, 1, 1)
    rewardName.TextScaled = true
    rewardName.Font = Enum.Font.SourceSansBold
    rewardName.TextStrokeTransparency = 0
    rewardName.TextStrokeColor3 = Color3.new(0, 0, 0)
    rewardName.Parent = rewardFrame
    
    -- Reward description
    local rewardDesc = Instance.new("TextLabel")
    rewardDesc.Name = "RewardDescription"
    rewardDesc.Size = UDim2.new(1, -20, 0, 60)
    rewardDesc.Position = UDim2.new(0, 10, 0, 100)
    rewardDesc.BackgroundTransparency = 1
    rewardDesc.Text = ""
    rewardDesc.TextColor3 = Color3.new(0.8, 0.8, 1)
    rewardDesc.TextScaled = true
    rewardDesc.Font = Enum.Font.SourceSans
    rewardDesc.TextWrapped = true
    rewardDesc.TextStrokeTransparency = 0
    rewardDesc.TextStrokeColor3 = Color3.new(0, 0, 0)
    rewardDesc.Parent = rewardFrame
    
    -- Close button
    local closeButton = Instance.new("TextButton")
    closeButton.Size = UDim2.new(0, 80, 0, 30)
    closeButton.Position = UDim2.new(0.5, -40, 1, -40)
    closeButton.BackgroundColor3 = Color3.new(0.3, 0.7, 0.3)
    closeButton.Text = "Awesome!"
    closeButton.TextColor3 = Color3.new(1, 1, 1)
    closeButton.TextScaled = true
    closeButton.Font = Enum.Font.SourceSansBold
    closeButton.Parent = rewardFrame
    
    local buttonCorner = Instance.new("UICorner")
    buttonCorner.CornerRadius = UDim.new(0, 8)
    buttonCorner.Parent = closeButton
    
    closeButton.MouseButton1Click:Connect(function()
        self:HideRewardDisplay()
    end)
    
    -- Cooldown display frame
    cooldownFrame = Instance.new("Frame")
    cooldownFrame.Size = UDim2.new(0, 300, 0, 120)
    cooldownFrame.Position = UDim2.new(0.5, -150, 0.4, -60)
    cooldownFrame.BackgroundColor3 = Color3.new(0.2, 0.1, 0.1)
    cooldownFrame.BorderSizePixel = 0
    cooldownFrame.Visible = false
    cooldownFrame.Parent = fountainGui
    
    local cooldownCorner = Instance.new("UICorner")
    cooldownCorner.CornerRadius = UDim.new(0, 12)
    cooldownCorner.Parent = cooldownFrame
    
    -- Cooldown title
    local cooldownTitle = Instance.new("TextLabel")
    cooldownTitle.Size = UDim2.new(1, -20, 0, 40)
    cooldownTitle.Position = UDim2.new(0, 10, 0, 10)
    cooldownTitle.BackgroundTransparency = 1
    cooldownTitle.Text = "⏰ FOUNTAIN COOLDOWN"
    cooldownTitle.TextColor3 = Color3.new(1, 0.6, 0.6)
    cooldownTitle.TextScaled = true
    cooldownTitle.Font = Enum.Font.SourceSansBold
    cooldownTitle.TextStrokeTransparency = 0
    cooldownTitle.TextStrokeColor3 = Color3.new(0, 0, 0)
    cooldownTitle.Parent = cooldownFrame
    
    -- Cooldown timer
    local cooldownTimer = Instance.new("TextLabel")
    cooldownTimer.Name = "CooldownTimer"
    cooldownTimer.Size = UDim2.new(1, -20, 0, 60)
    cooldownTimer.Position = UDim2.new(0, 10, 0, 50)
    cooldownTimer.BackgroundTransparency = 1
    cooldownTimer.Text = ""
    cooldownTimer.TextColor3 = Color3.new(1, 1, 0.6)
    cooldownTimer.TextScaled = true
    cooldownTimer.Font = Enum.Font.SourceSans
    cooldownTimer.TextStrokeTransparency = 0
    cooldownTimer.TextStrokeColor3 = Color3.new(0, 0, 0)
    cooldownTimer.Parent = cooldownFrame
end

function FountainController:ShowRewardDisplay(reward)
    if not rewardFrame then return end
    
    local rewardName = rewardFrame:FindFirstChild("RewardName")
    local rewardDesc = rewardFrame:FindFirstChild("RewardDescription")
    
    if rewardName then
        rewardName.Text = reward.name
        rewardName.TextColor3 = self:GetRarityColor(reward.rarity)
    end
    
    if rewardDesc then
        rewardDesc.Text = reward.description
    end
    
    -- Show with animation
    rewardFrame.Visible = true
    rewardFrame.Size = UDim2.new(0, 0, 0, 0)
    rewardFrame.Position = UDim2.new(0.5, 0, 0.3, 0)
    
    local showTween = TweenService:Create(
        rewardFrame,
        TweenInfo.new(0.5, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
        {
            Size = UDim2.new(0, 400, 0, 200),
            Position = UDim2.new(0.5, -200, 0.3, -100)
        }
    )
    showTween:Play()
    
    -- Play celebration sound
    self:PlayCelebrationSound(reward.rarity)
    
    -- Auto-hide after 5 seconds
    spawn(function()
        wait(5)
        self:HideRewardDisplay()
    end)
end

function FountainController:HideRewardDisplay()
    if not rewardFrame or not rewardFrame.Visible then return end
    
    local hideTween = TweenService:Create(
        rewardFrame,
        TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.In),
        {
            Size = UDim2.new(0, 0, 0, 0),
            Position = UDim2.new(0.5, 0, 0.3, 0)
        }
    )
    
    hideTween:Play()
    hideTween.Completed:Connect(function()
        rewardFrame.Visible = false
    end)
end

function FountainController:ShowCooldownTimer(hoursLeft)
    if not cooldownFrame then return end
    
    local cooldownTimer = cooldownFrame:FindFirstChild("CooldownTimer")
    if cooldownTimer then
        cooldownTimer.Text = "Come back in " .. hoursLeft .. " hours\nfor your next blessing!"
    end
    
    -- Show cooldown display
    cooldownFrame.Visible = true
    cooldownFrame.Size = UDim2.new(0, 0, 0, 0)
    cooldownFrame.Position = UDim2.new(0.5, 0, 0.4, 0)
    
    local showTween = TweenService:Create(
        cooldownFrame,
        TweenInfo.new(0.4, Enum.EasingStyle.Bounce, Enum.EasingDirection.Out),
        {
            Size = UDim2.new(0, 300, 0, 120),
            Position = UDim2.new(0.5, -150, 0.4, -60)
        }
    )
    showTween:Play()
    
    -- Auto-hide after 3 seconds
    spawn(function()
        wait(3)
        local hideTween = TweenService:Create(
            cooldownFrame,
            TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
            {
                Size = UDim2.new(0, 0, 0, 0),
                Position = UDim2.new(0.5, 0, 0.4, 0)
            }
        )
        hideTween:Play()
        hideTween.Completed:Connect(function()
            cooldownFrame.Visible = false
        end)
    end)
end

function FountainController:GetRarityColor(rarity)
    local colors = {
        common = Color3.new(0.8, 0.8, 0.8),
        uncommon = Color3.new(0.2, 1, 0.2),
        rare = Color3.new(0.2, 0.4, 1),
        epic = Color3.new(0.8, 0.2, 1),
        legendary = Color3.new(1, 0.8, 0.2)
    }
    return colors[rarity] or colors.common
end

function FountainController:PlayCelebrationSound(rarity)
    -- Create different sounds based on rarity
    local soundId = "rbxasset://sounds/electronicpingshort.wav" -- Default
    
    if rarity == "legendary" then
        soundId = "rbxasset://sounds/victory_fanfare_harp.mp3"
    elseif rarity == "epic" then
        soundId = "rbxasset://sounds/impact_generic_large_water_1.mp3"
    elseif rarity == "rare" then
        soundId = "rbxasset://sounds/pop_mid_down.wav"
    end
    
    local sound = Instance.new("Sound")
    sound.SoundId = soundId
    sound.Volume = 0.5
    sound.Parent = workspace
    sound:Play()
    
    sound.Ended:Connect(function()
        sound:Destroy()
    end)
end

function FountainController:ApplyTemporaryMultiplier(multiplier, duration)
    print("🚀 Applied " .. multiplier .. "x multiplier for " .. duration .. " seconds!")
    
    -- Track the multiplier
    activeMultipliers[#activeMultipliers + 1] = {
        multiplier = multiplier,
        endTime = tick() + duration
    }
    
    -- Show notification
    StarterGui:SetCore("SendNotification", {
        Title = "⚡ Speed Boost Active!";
        Text = multiplier .. "x speed for " .. math.floor(duration/60) .. " minutes!";
        Duration = 3;
    })
    
    -- Apply character speed boost
    if player.Character and player.Character:FindFirstChild("Humanoid") then
        local humanoid = player.Character.Humanoid
        humanoid.WalkSpeed = humanoid.WalkSpeed * multiplier
        
        -- Revert after duration
        spawn(function()
            wait(duration)
            if player.Character and player.Character:FindFirstChild("Humanoid") then
                player.Character.Humanoid.WalkSpeed = player.Character.Humanoid.WalkSpeed / multiplier
            end
        end)
    end
end

function FountainController:ApplySpecialEffect(effectType, duration)
    if effectType == "rainbow_trail" then
        self:CreateRainbowTrail(duration)
    elseif effectType == "mega_jackpot" then
        self:CreateMegaJackpotEffect(duration)
    end
end

function FountainController:CreateRainbowTrail(duration)
    if not player.Character then return end
    
    print("🌈 Rainbow trail activated for " .. duration .. " seconds!")
    
    StarterGui:SetCore("SendNotification", {
        Title = "🌈 Rainbow Trail!";
        Text = "You're leaving a magical rainbow trail!";
        Duration = 3;
    })
    
    -- Create rainbow trail attachment
    local humanoidRootPart = player.Character:FindFirstChild("HumanoidRootPart")
    if humanoidRootPart then
        local attachment = Instance.new("Attachment")
        attachment.Name = "RainbowTrailAttachment"
        attachment.Parent = humanoidRootPart
        
        -- Create rainbow trail effect
        local trail = Instance.new("Trail")
        trail.Color = ColorSequence.new{
            ColorSequenceKeypoint.new(0, Color3.new(1, 0, 0)),
            ColorSequenceKeypoint.new(0.2, Color3.new(1, 0.5, 0)),
            ColorSequenceKeypoint.new(0.4, Color3.new(1, 1, 0)),
            ColorSequenceKeypoint.new(0.6, Color3.new(0, 1, 0)),
            ColorSequenceKeypoint.new(0.8, Color3.new(0, 0, 1)),
            ColorSequenceKeypoint.new(1, Color3.new(0.5, 0, 1))
        }
        trail.Transparency = NumberSequence.new{
            NumberSequenceKeypoint.new(0, 0.3),
            NumberSequenceKeypoint.new(1, 1)
        }
        trail.Lifetime = 2
        trail.MinLength = 0
        trail.FaceCamera = true
        trail.Attachment0 = attachment
        trail.Attachment1 = attachment
        trail.Parent = humanoidRootPart
        
        -- Clean up after duration
        spawn(function()
            wait(duration)
            if attachment then attachment:Destroy() end
            if trail then trail:Destroy() end
        end)
    end
end

function FountainController:CreateMegaJackpotEffect(duration)
    print("💫 MEGA JACKPOT EFFECT!")
    
    StarterGui:SetCore("SendNotification", {
        Title = "💫 MEGA JACKPOT!";
        Text = "You hit the fountain jackpot!";
        Duration = 5;
    })
    
    -- Create screen flash effect
    local flashGui = Instance.new("ScreenGui")
    flashGui.Name = "JackpotFlash"
    flashGui.Parent = playerGui
    
    local flash = Instance.new("Frame")
    flash.Size = UDim2.new(1, 0, 1, 0)
    flash.BackgroundColor3 = Color3.new(1, 1, 0)
    flash.BackgroundTransparency = 1
    flash.Parent = flashGui
    
    -- Flash animation
    local flashTween = TweenService:Create(
        flash,
        TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut, 3, true),
        {BackgroundTransparency = 0.7}
    )
    flashTween:Play()
    
    -- Clean up
    spawn(function()
        wait(3)
        flashGui:Destroy()
    end)
end

function FountainController:Initialize()
    print("🌊 FountainController initializing...")
    
    -- Create UI
    self:CreateFountainUI()
    
    -- Connect remote events
    RemoteEvents.FountainRewardClaimed.OnClientEvent:Connect(function(reward)
        self:ShowRewardDisplay(reward)
    end)
    
    RemoteEvents.ShowFountainCooldown.OnClientEvent:Connect(function(hoursLeft)
        self:ShowCooldownTimer(hoursLeft)
    end)
    
    RemoteEvents.ApplyTempMultiplier.OnClientEvent:Connect(function(multiplier, duration)
        self:ApplyTemporaryMultiplier(multiplier, duration)
    end)
    
    RemoteEvents.ApplySpecialEffect.OnClientEvent:Connect(function(effectType, duration)
        self:ApplySpecialEffect(effectType, duration)
    end)
    
    print("✨ FountainController initialized!")
end

-- Auto-initialize
FountainController:Initialize()

return FountainController
