-- PolishController.luau
-- Handles game polish features: jump animations, colored sparkles, wind FX, and coin pickup sounds

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local SoundService = game:GetService("SoundService")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local RemoteEvents = require(ReplicatedStorage.Shared.modules.RemoteEvents)
local GameConstants = require(ReplicatedStorage.Shared.constants.GameConstants)

local player = Players.LocalPlayer
local PolishController = {}

-- State tracking
local isPolishEnabled = true
local currentSpeedEffects = {}
local jumpCooldown = {}
local windEffectConnection = nil

-- Sound effect instances
local coinPickupSounds = {}
local jumpSounds = {}
local windSoundLoop = nil

-- Wind FX threshold
local WIND_SPEED_THRESHOLD = 20 -- WalkSpeed above this triggers wind effects

function PolishController:LoadSounds()
    -- Load coin pickup sounds (varied for satisfaction)
    local coinSoundIds = {
        "rbxasset://sounds/electronicpingshort.wav",
        "rbxasset://sounds/pop_mid_up.wav",
        "rbxasset://sounds/bell.wav"
    }
    
    for i, soundId in ipairs(coinSoundIds) do
        local sound = Instance.new("Sound")
        sound.SoundId = soundId
        sound.Volume = 0.6
        sound.Pitch = 1 + (i * 0.2) -- Vary pitch for different tones
        sound.Parent = SoundService
        table.insert(coinPickupSounds, sound)
    end
    
    -- Load jump sounds
    local jumpSoundIds = {
        "rbxasset://sounds/impact_generic_large_water_1.mp3",
        "rbxasset://sounds/pop_mid_down.wav"
    }
    
    for _, soundId in ipairs(jumpSoundIds) do
        local sound = Instance.new("Sound")
        sound.SoundId = soundId
        sound.Volume = 0.4
        sound.Pitch = 1.3 -- Higher pitch for jump
        sound.Parent = SoundService
        table.insert(jumpSounds, sound)
    end
    
    -- Load wind sound loop
    windSoundLoop = Instance.new("Sound")
    windSoundLoop.SoundId = "rbxasset://sounds/impact_generic_large_water_1.mp3"
    windSoundLoop.Volume = 0.3
    windSoundLoop.Pitch = 0.5
    windSoundLoop.Looped = true
    windSoundLoop.Parent = SoundService
    
    print("🎵 Polish sounds loaded successfully!")
end

function PolishController:PlayCoinPickupSound()
    if not isPolishEnabled then return end
    
    -- Play random coin pickup sound
    local randomSound = coinPickupSounds[math.random(1, #coinPickupSounds)]
    if randomSound then
        randomSound:Play()
    end
end

function PolishController:PlayJumpSound()
    if not isPolishEnabled then return end
    
    -- Play random jump sound
    local randomSound = jumpSounds[math.random(1, #jumpSounds)]
    if randomSound then
        randomSound:Play()
    end
end

function PolishController:PlaySpecialCoinSound()
    if not isPolishEnabled then return end
    
    -- Play special milestone coin sound
    local specialSound = Instance.new("Sound")
    specialSound.SoundId = "rbxasset://sounds/bell.wav"
    specialSound.Volume = 0.8
    specialSound.Pitch = 1.2
    specialSound.Parent = SoundService
    specialSound:Play()
    
    specialSound.Ended:Connect(function()
        specialSound:Destroy()
    end)
end

function PolishController:CreateJumpAnimation(character)
    if not isPolishEnabled or not character then return end
    
    local humanoid = character:FindFirstChild("Humanoid")
    local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
    
    if not humanoid or not humanoidRootPart then return end
    
    local userId = tostring(player.UserId)
    
    -- Cooldown check
    if jumpCooldown[userId] and tick() - jumpCooldown[userId] < 0.5 then
        return
    end
    jumpCooldown[userId] = tick()
    
    -- Create jump animation
    local originalPosition = humanoidRootPart.Position
    local jumpHeight = 5 -- How high to jump
    
    -- Jump up animation
    local jumpUpTween = TweenService:Create(
        humanoidRootPart,
        TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
        {Position = originalPosition + Vector3.new(0, jumpHeight, 0)}
    )
    
    -- Jump down animation
    local jumpDownTween = TweenService:Create(
        humanoidRootPart,
        TweenInfo.new(0.4, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
        {Position = originalPosition}
    )
    
    -- Character scaling effect during jump
    local scaleUpTween = TweenService:Create(
        humanoid,
        TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
        {HipHeight = humanoid.HipHeight + 2}
    )
    
    local scaleDownTween = TweenService:Create(
        humanoid,
        TweenInfo.new(0.55, Enum.EasingStyle.Bounce, Enum.EasingDirection.Out),
        {HipHeight = humanoid.HipHeight}
    )
    
    -- Create jump particles
    self:CreateJumpParticles(humanoidRootPart)
    
    -- Play sound
    self:PlayJumpSound()
    
    -- Execute animation sequence
    jumpUpTween:Play()
    scaleUpTween:Play()
    
    jumpUpTween.Completed:Connect(function()
        jumpDownTween:Play()
        scaleDownTween:Play()
        
        -- Landing particles
        jumpDownTween.Completed:Connect(function()
            self:CreateLandingParticles(humanoidRootPart)
        end)
    end)
    
    print("🦘 " .. player.Name .. " performed jump animation!")
end

function PolishController:CreateJumpParticles(humanoidRootPart)
    if not isPolishEnabled or not humanoidRootPart then return end
    
    -- Create jump trail particles
    local attachment = Instance.new("Attachment")
    attachment.Name = "JumpParticles"
    attachment.Parent = humanoidRootPart
    
    local jumpParticles = Instance.new("ParticleEmitter")
    jumpParticles.Texture = "rbxasset://textures/particles/sparkles_main.dds"
    jumpParticles.Lifetime = NumberRange.new(0.5, 1.2)
    jumpParticles.Rate = 50
    jumpParticles.SpreadAngle = Vector2.new(30, 30)
    jumpParticles.Speed = NumberRange.new(8, 15)
    jumpParticles.Color = ColorSequence.new{
        ColorSequenceKeypoint.new(0, Color3.new(1, 1, 1)),
        ColorSequenceKeypoint.new(0.5, Color3.new(0.8, 0.9, 1)),
        ColorSequenceKeypoint.new(1, Color3.new(0.5, 0.7, 1))
    }
    jumpParticles.Size = NumberSequence.new{
        NumberSequenceKeypoint.new(0, 0.3),
        NumberSequenceKeypoint.new(0.5, 0.6),
        NumberSequenceKeypoint.new(1, 0)
    }
    jumpParticles.Parent = attachment
    
    -- Auto cleanup
    spawn(function()
        wait(1)
        jumpParticles.Enabled = false
        wait(2)
        if attachment then
            attachment:Destroy()
        end
    end)
end

function PolishController:CreateLandingParticles(humanoidRootPart)
    if not isPolishEnabled or not humanoidRootPart then return end
    
    -- Create landing impact particles
    local attachment = Instance.new("Attachment")
    attachment.Name = "LandingParticles"
    attachment.Position = Vector3.new(0, -2.5, 0) -- At feet level
    attachment.Parent = humanoidRootPart
    
    local landingParticles = Instance.new("ParticleEmitter")
    landingParticles.Texture = "rbxasset://textures/particles/sparkles_main.dds"
    landingParticles.Lifetime = NumberRange.new(0.3, 0.8)
    landingParticles.Rate = 100
    landingParticles.SpreadAngle = Vector2.new(360, 10) -- Spread outward from landing point
    landingParticles.Speed = NumberRange.new(5, 12)
    landingParticles.Color = ColorSequence.new{
        ColorSequenceKeypoint.new(0, Color3.new(0.7, 0.5, 0.3)),
        ColorSequenceKeypoint.new(1, Color3.new(0.4, 0.3, 0.2))
    }
    landingParticles.Size = NumberSequence.new{
        NumberSequenceKeypoint.new(0, 0.2),
        NumberSequenceKeypoint.new(0.5, 0.4),
        NumberSequenceKeypoint.new(1, 0)
    }
    landingParticles.Parent = attachment
    
    -- Burst effect
    landingParticles:Emit(30)
    
    -- Event-driven auto cleanup
    spawn(function()
        local cleanupEvent = Instance.new("BindableEvent")
        
        local function performCleanup()
            if attachment then
                attachment:Destroy()
            end
        end
        
        cleanupEvent.Event:Connect(performCleanup)
        task.wait(0.5)
        cleanupEvent:Fire()
    end)
end

function PolishController:CreateColoredSparkles(character, color, success)
    if not isPolishEnabled or not character then return end
    
    local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
    if not humanoidRootPart then return end
    
    -- Create colored sparkle effect for barrier matches
    local attachment = Instance.new("Attachment")
    attachment.Name = "MatchSparkles"
    attachment.Parent = humanoidRootPart
    
    -- Color mapping for sparkles
    local sparkleColors = {
        RED = Color3.new(1, 0.2, 0.2),
        GREEN = Color3.new(0.2, 1, 0.2),
        BLUE = Color3.new(0.2, 0.2, 1),
        YELLOW = Color3.new(1, 1, 0.2)
    }
    
    local targetColor = sparkleColors[color] or Color3.new(1, 1, 1)
    
    local sparkles = Instance.new("ParticleEmitter")
    sparkles.Texture = "rbxasset://textures/particles/sparkles_main.dds"
    sparkles.Lifetime = NumberRange.new(0.8, 1.5)
    sparkles.Rate = success and 80 or 40
    sparkles.SpreadAngle = Vector2.new(45, 45)
    sparkles.Speed = NumberRange.new(6, 12)
    
    if success then
        -- Success sparkles: bright and colorful
        sparkles.Color = ColorSequence.new{
            ColorSequenceKeypoint.new(0, targetColor),
            ColorSequenceKeypoint.new(0.5, Color3.new(1, 1, 1)),
            ColorSequenceKeypoint.new(1, targetColor)
        }
    else
        -- Failure sparkles: darker and more muted
        sparkles.Color = ColorSequence.new{
            ColorSequenceKeypoint.new(0, Color3.new(0.5, 0, 0)),
            ColorSequenceKeypoint.new(1, Color3.new(0.2, 0, 0))
        }
    end
    
    sparkles.Size = NumberSequence.new{
        NumberSequenceKeypoint.new(0, 0.4),
        NumberSequenceKeypoint.new(0.5, 0.8),
        NumberSequenceKeypoint.new(1, 0)
    }
    sparkles.Parent = attachment
    
    -- Burst effect
    sparkles:Emit(success and 50 or 20)
    
    -- Auto cleanup
    spawn(function()
        wait(1.5)
        sparkles.Enabled = false
        wait(2)
        if attachment then
            attachment:Destroy()
        end
    end)
    
    print("✨ Created " .. (success and "success" or "failure") .. " sparkles for " .. color)
end

function PolishController:UpdateWindEffects()
    if not isPolishEnabled then return end
    
    local character = player.Character
    if not character then return end
    
    local humanoid = character:FindFirstChild("Humanoid")
    local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
    
    if not humanoid or not humanoidRootPart then return end
    
    local walkSpeed = humanoid.WalkSpeed
    local userId = tostring(player.UserId)
    
    -- Check if wind effects should be active
    if walkSpeed >= WIND_SPEED_THRESHOLD then
        if not currentSpeedEffects[userId] then
            self:StartWindEffects(humanoidRootPart, walkSpeed)
            currentSpeedEffects[userId] = true
        else
            self:UpdateWindIntensity(humanoidRootPart, walkSpeed)
        end
    else
        if currentSpeedEffects[userId] then
            self:StopWindEffects(humanoidRootPart)
            currentSpeedEffects[userId] = false
        end
    end
end

function PolishController:StartWindEffects(humanoidRootPart, walkSpeed)
    if not isPolishEnabled or not humanoidRootPart then return end
    
    -- Create wind particle trail
    local attachment = Instance.new("Attachment")
    attachment.Name = "WindEffects"
    attachment.Position = Vector3.new(0, 0, 1) -- Behind the player
    attachment.Parent = humanoidRootPart
    
    local windParticles = Instance.new("ParticleEmitter")
    windParticles.Name = "WindTrail"
    windParticles.Texture = "rbxasset://textures/particles/sparkles_main.dds"
    windParticles.Lifetime = NumberRange.new(0.5, 1.0)
    windParticles.Rate = math.min(walkSpeed * 2, 100) -- Scale with speed
    windParticles.SpreadAngle = Vector2.new(20, 20)
    windParticles.Speed = NumberRange.new(-15, -5) -- Trail behind
    windParticles.Color = ColorSequence.new{
        ColorSequenceKeypoint.new(0, Color3.new(0.8, 0.9, 1)),
        ColorSequenceKeypoint.new(0.5, Color3.new(0.6, 0.8, 1)),
        ColorSequenceKeypoint.new(1, Color3.new(0.4, 0.6, 0.8))
    }
    windParticles.Size = NumberSequence.new{
        NumberSequenceKeypoint.new(0, 0.2),
        NumberSequenceKeypoint.new(0.5, 0.5),
        NumberSequenceKeypoint.new(1, 0.1)
    }
    windParticles.Transparency = NumberSequence.new{
        NumberSequenceKeypoint.new(0, 0.3),
        NumberSequenceKeypoint.new(1, 1)
    }
    windParticles.Parent = attachment
    
    -- Create wind sound effect
    if windSoundLoop and not windSoundLoop.IsPlaying then
        windSoundLoop.Volume = math.min(walkSpeed / 100, 0.5)
        windSoundLoop:Play()
    end
    
    print("💨 Started wind effects at speed: " .. walkSpeed)
end

function PolishController:UpdateWindIntensity(humanoidRootPart, walkSpeed)
    if not isPolishEnabled or not humanoidRootPart then return end
    
    local windAttachment = humanoidRootPart:FindFirstChild("WindEffects")
    if not windAttachment then return end
    
    local windParticles = windAttachment:FindFirstChild("WindTrail")
    if windParticles then
        -- Update particle rate based on speed
        windParticles.Rate = math.min(walkSpeed * 2, 100)
    end
    
    -- Update wind sound volume
    if windSoundLoop and windSoundLoop.IsPlaying then
        windSoundLoop.Volume = math.min(walkSpeed / 100, 0.5)
    end
end

function PolishController:StopWindEffects(humanoidRootPart)
    if not humanoidRootPart then return end
    
    local windAttachment = humanoidRootPart:FindFirstChild("WindEffects")
    if windAttachment then
        local windParticles = windAttachment:FindFirstChild("WindTrail")
        if windParticles then
            windParticles.Enabled = false
        end
        
        -- Cleanup after particles finish
        spawn(function()
            wait(2)
            if windAttachment then
                windAttachment:Destroy()
            end
        end)
    end
    
    -- Stop wind sound
    if windSoundLoop and windSoundLoop.IsPlaying then
        windSoundLoop:Stop()
    end
    
    print("💨 Stopped wind effects")
end

function PolishController:SetupPolishEventHandlers()
    -- Handle barrier passing with colored sparkles
    RemoteEvents.BarrierPassed.OnClientEvent:Connect(function(success, score)
        local character = player.Character
        if character then
            -- Get current color from PlayerController
            local currentColor = "BLUE" -- Default fallback
            
            -- Try to get current player color
            local PlayerController = require(script.Parent.PlayerController)
            if PlayerController and PlayerController.GetCurrentColor then
                currentColor = PlayerController:GetCurrentColor()
            end
            
            -- Create colored sparkles
            self:CreateColoredSparkles(character, currentColor, success)
            
            -- Event-driven jump animation trigger
            if success then
                spawn(function()
                    local animationEvent = Instance.new("BindableEvent")
                    
                    local function triggerAnimation()
                        self:CreateJumpAnimation(character)
                    end
                    
                    animationEvent.Event:Connect(triggerAnimation)
                    task.wait(0.15) -- Slightly longer delay for better visual timing
                    animationEvent:Fire()
                end)
            end
        end
    end)
    
    -- Handle coin collection
    RemoteEvents.CoinCollected.OnClientEvent:Connect(function(totalCoins)
        self:PlayCoinPickupSound()
        
        -- Create coin sparkle effect
        local character = player.Character
        if character then
            self:CreateColoredSparkles(character, "YELLOW", true)
            
            -- Event-driven milestone sound
            if totalCoins > 0 and totalCoins % 50 == 0 then
                spawn(function()
                    local soundEvent = Instance.new("BindableEvent")
                    
                    local function playMilestoneSound()
                        self:PlaySpecialCoinSound()
                    end
                    
                    soundEvent.Event:Connect(playMilestoneSound)
                    task.wait(0.12) -- Optimized timing
                    soundEvent:Fire()
                end)
            end
        end
    end)
    
    -- Handle bonus coins from upgrades
    if RemoteEvents.BonusCoinsEarned then
        RemoteEvents.BonusCoinsEarned.OnClientEvent:Connect(function(bonusAmount)
            -- Event-driven bonus coin sound
            spawn(function()
                local bonusSoundEvent = Instance.new("BindableEvent")
                
                local function playBonusSound()
                    self:PlayCoinPickupSound()
                end
                
                bonusSoundEvent.Event:Connect(playBonusSound)
                task.wait(0.25) -- Optimized timing
                bonusSoundEvent:Fire()
            end)
            
            local character = player.Character
            if character then
                spawn(function()
                    local bonusSparkleEvent = Instance.new("BindableEvent")
                    
                    local function createBonusSparkle()
                        self:CreateColoredSparkles(character, "YELLOW", true)
                    end
                    
                    bonusSparkleEvent.Event:Connect(createBonusSparkle)
                    task.wait(0.35) -- Optimized timing
                    bonusSparkleEvent:Fire()
                end)
            end
        end)
    end
end

function PolishController:StartWindEffectMonitoring()
    -- Monitor player speed continuously for wind effects
    if windEffectConnection then
        windEffectConnection:Disconnect()
    end
    
    windEffectConnection = RunService.Heartbeat:Connect(function()
        self:UpdateWindEffects()
    end)
end

function PolishController:StopWindEffectMonitoring()
    if windEffectConnection then
        windEffectConnection:Disconnect()
        windEffectConnection = nil
    end
    
    -- Clean up any active wind effects
    local character = player.Character
    if character and character:FindFirstChild("HumanoidRootPart") then
        self:StopWindEffects(character.HumanoidRootPart)
    end
end

function PolishController:OnCharacterAdded(character)
    -- Reset state for new character
    local userId = tostring(player.UserId)
    currentSpeedEffects[userId] = false
    jumpCooldown[userId] = 0
    
    -- Wait for character to load
    spawn(function()
        wait(1)
        print("🎨 Polish effects ready for " .. player.Name)
    end)
end

function PolishController:TogglePolish(enabled)
    isPolishEnabled = enabled
    
    if not enabled then
        self:StopWindEffectMonitoring()
        
        -- Clean up any active effects
        local character = player.Character
        if character and character:FindFirstChild("HumanoidRootPart") then
            local humanoidRootPart = character.HumanoidRootPart
            
            -- Remove active wind effects
            self:StopWindEffects(humanoidRootPart)
            
            -- Remove any particle attachments
            for _, attachment in pairs(humanoidRootPart:GetChildren()) do
                if attachment:IsA("Attachment") and 
                   (attachment.Name:find("Sparkles") or attachment.Name:find("Jump") or attachment.Name:find("Landing")) then
                    attachment:Destroy()
                end
            end
        end
    else
        self:StartWindEffectMonitoring()
    end
    
    print("🎨 Polish effects " .. (enabled and "enabled" or "disabled"))
end

-- Manual trigger methods for testing/fun
function PolishController:TriggerJumpAnimation()
    local character = player.Character
    if character then
        self:CreateJumpAnimation(character)
    end
end

function PolishController:TriggerSparkles(color, success)
    local character = player.Character
    if character then
        self:CreateColoredSparkles(character, color or "BLUE", success ~= false)
    end
end

function PolishController:GetPolishEnabled()
    return isPolishEnabled
end

function PolishController:Init()
    print("🎨 PolishController initializing...")
    
    -- Load all sound effects
    self:LoadSounds()
    
    -- Setup event handlers
    self:SetupPolishEventHandlers()
    
    -- Handle character spawning
    if player.Character then
        self:OnCharacterAdded(player.Character)
    end
    
    player.CharacterAdded:Connect(function(character)
        self:OnCharacterAdded(character)
    end)
    
    player.CharacterRemoving:Connect(function()
        self:StopWindEffectMonitoring()
    end)
    
    -- Start wind effect monitoring
    self:StartWindEffectMonitoring()
    
    print("✅ PolishController initialized successfully!")
    print("🎨 Features: Jump animations, colored sparkles, wind FX, coin sounds")
end

return PolishController
