-- ScreenEffectsController.client.luau
-- Handles all visual screen effects for game actions
-- Speed boost = FOV zoom + motion blur, Jump = screen shake + trail, Death = fade + desaturation

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local Lighting = game:GetService("Lighting")
local Workspace = game:GetService("Workspace")
local UserInputService = game:GetService("UserInputService")

local ScreenEffectsConfig = require(ReplicatedStorage.Shared.modules.ScreenEffectsConfig)

local player = Players.LocalPlayer
local camera = Workspace.CurrentCamera

local ScreenEffectsController = {}

-- Effect Configuration (now loaded from config module)
local EFFECTS_CONFIG = {
    speedBoost = ScreenEffectsConfig.SpeedBoost,
    jump = ScreenEffectsConfig.Jump,
    death = ScreenEffectsConfig.Death,
    general = ScreenEffectsConfig.General,
    utility = ScreenEffectsConfig.Utility
}

-- Effect Elements
local effectsGui = nil
local vignetteFrame = nil
local fadeFrame = nil
local flashFrame = nil
local blurEffect = nil
local colorCorrectionEffect = nil
local cameraShakeConnection = nil

-- State Tracking
local originalFOV = 70
local isSpeedBoostActive = false
local isJumpActive = false
local isDeathActive = false
local currentShakeIntensity = 0

function ScreenEffectsController:Init()
    print("📹 Initializing Screen Effects Controller...")
    
    -- Store original camera settings
    originalFOV = camera.FieldOfView
    
    -- Create effect UI and lighting effects
    self:CreateEffectGUI()
    self:CreateLightingEffects()
    
    -- Set up event connections
    self:ConnectToGameEvents()
    
    print("✅ Screen Effects Controller initialized!")
end

function ScreenEffectsController:CreateEffectGUI()
    local playerGui = player:WaitForChild("PlayerGui")
    
    -- Main effects GUI
    effectsGui = Instance.new("ScreenGui")
    effectsGui.Name = "ScreenEffects"
    effectsGui.ResetOnSpawn = false
    effectsGui.DisplayOrder = 100
    effectsGui.IgnoreGuiInset = true
    effectsGui.Parent = playerGui
    
    -- Vignette effect (edge darkening)
    vignetteFrame = Instance.new("Frame")
    vignetteFrame.Name = "Vignette"
    vignetteFrame.Size = UDim2.new(1, 0, 1, 0)
    vignetteFrame.Position = UDim2.new(0, 0, 0, 0)
    vignetteFrame.BackgroundColor3 = Color3.new(0, 0, 0)
    vignetteFrame.BackgroundTransparency = 1
    vignetteFrame.BorderSizePixel = 0
    vignetteFrame.Parent = effectsGui
    
    -- Vignette gradient
    local vignetteGradient = Instance.new("UIGradient")
    vignetteGradient.Transparency = NumberSequence.new({
        NumberSequenceKeypoint.new(0, 0),
        NumberSequenceKeypoint.new(0.6, 1),
        NumberSequenceKeypoint.new(1, 0)
    })
    vignetteGradient.Rotation = 0
    vignetteGradient.Parent = vignetteFrame
    
    -- Fade overlay (for death effect)
    fadeFrame = Instance.new("Frame")
    fadeFrame.Name = "FadeOverlay"
    fadeFrame.Size = UDim2.new(1, 0, 1, 0)
    fadeFrame.Position = UDim2.new(0, 0, 0, 0)
    fadeFrame.BackgroundColor3 = Color3.new(0, 0, 0)
    fadeFrame.BackgroundTransparency = 1
    fadeFrame.BorderSizePixel = 0
    fadeFrame.Parent = effectsGui
    
    -- Flash overlay (for impacts and jumps)
    flashFrame = Instance.new("Frame")
    flashFrame.Name = "FlashOverlay"
    flashFrame.Size = UDim2.new(1, 0, 1, 0)
    flashFrame.Position = UDim2.new(0, 0, 0, 0)
    flashFrame.BackgroundColor3 = Color3.new(1, 1, 1)
    flashFrame.BackgroundTransparency = 1
    flashFrame.BorderSizePixel = 0
    flashFrame.Parent = effectsGui
end

function ScreenEffectsController:CreateLightingEffects()
    -- Motion blur effect
    blurEffect = Instance.new("BlurEffect")
    blurEffect.Name = "ScreenEffectsBlur"
    blurEffect.Size = 0
    blurEffect.Parent = Lighting
    
    -- Color correction for desaturation and tinting
    colorCorrectionEffect = Instance.new("ColorCorrectionEffect")
    colorCorrectionEffect.Name = "ScreenEffectsColorCorrection"
    colorCorrectionEffect.Saturation = 0
    colorCorrectionEffect.Contrast = 0
    colorCorrectionEffect.Brightness = 0
    colorCorrectionEffect.TintColor = Color3.new(1, 1, 1)
    colorCorrectionEffect.Parent = Lighting
end

function ScreenEffectsController:ConnectToGameEvents()
    -- Listen for server-triggered effects
    local gameEvents = ReplicatedStorage:WaitForChild("Events", 10)
    if gameEvents then
        -- Speed boost event
        local speedBoostEvent = gameEvents:WaitForChild("SpeedBoostActivated", 5)
        if speedBoostEvent then
            speedBoostEvent.OnClientEvent:Connect(function(duration)
                self:TriggerSpeedBoostEffect(duration or 1.0)
            end)
        end
        
        -- Jump event  
        local jumpEvent = gameEvents:WaitForChild("PlayerJumped", 5)
        if jumpEvent then
            jumpEvent.OnClientEvent:Connect(function(jumpPower)
                self:TriggerJumpEffect(jumpPower or 1.0)
            end)
        end
        
        -- Death event
        local deathEvent = gameEvents:WaitForChild("PlayerDied", 5)
        if deathEvent then
            deathEvent.OnClientEvent:Connect(function()
                self:TriggerDeathEffect()
            end)
        end
        
        -- Respawn event
        local respawnEvent = gameEvents:WaitForChild("PlayerRespawned", 5)
        if respawnEvent then
            respawnEvent.OnClientEvent:Connect(function()
                self:ResetDeathEffects()
            end)
        end
        
        -- Flash effect event
        local flashEvent = gameEvents:WaitForChild("FlashEffect", 5)
        if flashEvent then
            flashEvent.OnClientEvent:Connect(function(color, intensity, duration)
                self:TriggerFlashEffect(color, intensity, duration)
            end)
        end
        
        -- Screen shake event
        local shakeEvent = gameEvents:WaitForChild("ScreenShake", 5)
        if shakeEvent then
            shakeEvent.OnClientEvent:Connect(function(intensity, duration)
                self:TriggerScreenShake(intensity, duration)
            end)
        end
        
        -- NEW SCREEN EFFECT EVENTS
        
        -- Trigger Screen Shake (from CollisionController)
        local triggerShakeEvent = gameEvents:WaitForChild("TriggerScreenShake", 5)
        if triggerShakeEvent then
            triggerShakeEvent.OnClientEvent:Connect(function(intensity, duration)
                self:TriggerScreenShake(intensity, duration)
            end)
        end
        
        -- Trigger Flash Effect (from CollisionController)
        local triggerFlashEvent = gameEvents:WaitForChild("TriggerFlashEffect", 5)
        if triggerFlashEvent then
            triggerFlashEvent.OnClientEvent:Connect(function(color, intensity, duration)
                self:TriggerFlashEffect(color, intensity, duration)
            end)
        end
        
        -- Trigger FOV Zoom (from PlayerMovementController)
        local triggerFOVZoomEvent = gameEvents:WaitForChild("TriggerFOVZoom", 5)
        if triggerFOVZoomEvent then
            triggerFOVZoomEvent.OnClientEvent:Connect(function(intensity, duration)
                self:TriggerFOVZoom(intensity, duration)
            end)
        end
        
        -- Trigger Jump Effect (from PlayerMovementController)
        local triggerJumpEvent = gameEvents:WaitForChild("TriggerJumpEffect", 5)
        if triggerJumpEvent then
            triggerJumpEvent.OnClientEvent:Connect(function(jumpType, jumpPower)
                self:TriggerJumpEffect(jumpPower)
                if jumpType == "air" then
                    self:TriggerJumpAnticipation()
                end
            end)
        end
        
        -- Trigger Speed Boost Effect (from PlayerMovementController)
        local triggerSpeedBoostEvent = gameEvents:WaitForChild("TriggerSpeedBoostEffect", 5)
        if triggerSpeedBoostEvent then
            triggerSpeedBoostEvent.OnClientEvent:Connect(function(duration)
                self:TriggerSpeedBoostEffect(duration)
            end)
        end
        
        -- Trigger Color Mismatch Effect (from CollisionController)
        local triggerColorMismatchEvent = gameEvents:WaitForChild("TriggerColorMismatchEffect", 5)
        if triggerColorMismatchEvent then
            triggerColorMismatchEvent.OnClientEvent:Connect(function(effectData)
                self:TriggerColorMismatchEffect(effectData)
            end)
        end
    end
    
    -- Listen for local player character events
    player.CharacterAdded:Connect(function(character)
        self:SetupCharacterEffects(character)
    end)
    
    -- Setup effects for current character if it exists
    if player.Character then
        self:SetupCharacterEffects(player.Character)
    end
end

function ScreenEffectsController:SetupCharacterEffects(character)
    local humanoid = character:WaitForChild("Humanoid")
    
    -- Local jump detection (immediate feedback)
    humanoid.Jumping:Connect(function()
        -- Only trigger local effect if no server effect is active
        if not isJumpActive then
            self:TriggerJumpEffect(1.0)
        end
    end)
    
    -- Local death detection (immediate feedback)
    humanoid.Died:Connect(function()
        -- Only trigger local effect if no server effect is active
        if not isDeathActive then
            self:TriggerDeathEffect()
        end
    end)
    
    -- Health change effects
    humanoid.HealthChanged:Connect(function(health)
        local maxHealth = humanoid.MaxHealth
        local healthPercent = health / maxHealth
        
        -- Flash red when taking damage
        if health < humanoid.MaxHealth and health > 0 then
            local damageIntensity = math.min(0.4, (maxHealth - health) / maxHealth)
            self:TriggerFlashEffect(Color3.fromRGB(255, 100, 100), damageIntensity, 0.2)
        end
        
        -- Green flash when healing
        local prevHealth = humanoid:GetAttribute("PreviousHealth") or maxHealth
        if health > prevHealth and health < maxHealth then
            self:TriggerFlashEffect(Color3.fromRGB(100, 255, 100), 0.2, 0.3)
        end
        
        humanoid:SetAttribute("PreviousHealth", health)
    end)
    
    print("🎮 Character effects setup for " .. character.Name)
end

-- SPEED BOOST EFFECTS
function ScreenEffectsController:TriggerSpeedBoostEffect(duration)
    if isSpeedBoostActive then return end
    isSpeedBoostActive = true
    
    print("⚡ Triggering speed boost effect for " .. duration .. " seconds")
    
    -- FOV zoom effect
    self:AnimateFOVZoom(duration)
    
    -- Motion blur effect
    self:AnimateMotionBlur(duration)
    
    -- Vignette intensity
    self:AnimateVignette(duration, EFFECTS_CONFIG.speedBoost.vignetteIntensity)
    
    -- Chromatic aberration simulation
    self:AnimateChromaticAberration(duration)
    
    -- Reset after duration
    spawn(function()
        wait(duration)
        self:ResetSpeedBoostEffects()
        isSpeedBoostActive = false
    end)
end

function ScreenEffectsController:AnimateFOVZoom(duration)
    local targetFOV = originalFOV + EFFECTS_CONFIG.speedBoost.fovIncrease
    
    -- Zoom in
    local zoomInTween = TweenService:Create(
        camera,
        TweenInfo.new(
            EFFECTS_CONFIG.speedBoost.duration * 0.3,
            EFFECTS_CONFIG.general.transitionEasing,
            EFFECTS_CONFIG.general.transitionDirection
        ),
        {FieldOfView = targetFOV}
    )
    
    zoomInTween:Play()
    
    -- Zoom out after effect
    zoomInTween.Completed:Connect(function()
        wait(duration - EFFECTS_CONFIG.speedBoost.duration * 0.6)
        
        local zoomOutTween = TweenService:Create(
            camera,
            TweenInfo.new(
                EFFECTS_CONFIG.speedBoost.duration * 0.3,
                EFFECTS_CONFIG.general.transitionEasing,
                Enum.EasingDirection.In
            ),
            {FieldOfView = originalFOV}
        )
        
        zoomOutTween:Play()
    end)
end

function ScreenEffectsController:AnimateMotionBlur(duration)
    -- Blur in
    local blurInTween = TweenService:Create(
        blurEffect,
        TweenInfo.new(
            EFFECTS_CONFIG.speedBoost.duration * 0.2,
            Enum.EasingStyle.Quad,
            Enum.EasingDirection.Out
        ),
        {Size = EFFECTS_CONFIG.speedBoost.blurSize}
    )
    
    blurInTween:Play()
    
    -- Blur out
    blurInTween.Completed:Connect(function()
        wait(duration - EFFECTS_CONFIG.speedBoost.duration * 0.4)
        
        local blurOutTween = TweenService:Create(
            blurEffect,
            TweenInfo.new(
                EFFECTS_CONFIG.speedBoost.duration * 0.2,
                Enum.EasingStyle.Quad,
                Enum.EasingDirection.In
            ),
            {Size = 0}
        )
        
        blurOutTween:Play()
    end)
end

function ScreenEffectsController:AnimateVignette(duration, intensity)
    -- Vignette in
    local vignetteInTween = TweenService:Create(
        vignetteFrame,
        TweenInfo.new(
            EFFECTS_CONFIG.speedBoost.duration * 0.3,
            Enum.EasingStyle.Sine,
            Enum.EasingDirection.Out
        ),
        {BackgroundTransparency = 1 - intensity}
    )
    
    vignetteInTween:Play()
    
    -- Vignette out
    vignetteInTween.Completed:Connect(function()
        wait(duration - EFFECTS_CONFIG.speedBoost.duration * 0.6)
        
        local vignetteOutTween = TweenService:Create(
            vignetteFrame,
            TweenInfo.new(
                EFFECTS_CONFIG.speedBoost.duration * 0.3,
                Enum.EasingStyle.Sine,
                Enum.EasingDirection.In
            ),
            {BackgroundTransparency = 1}
        )
        
        vignetteOutTween:Play()
    end)
end

function ScreenEffectsController:AnimateChromaticAberration(duration)
    -- Simulate chromatic aberration with slight color shifts
    local aberrationTween = TweenService:Create(
        colorCorrectionEffect,
        TweenInfo.new(
            EFFECTS_CONFIG.speedBoost.duration * 0.2,
            Enum.EasingStyle.Sine,
            Enum.EasingDirection.Out
        ),
        {
            TintColor = Color3.fromRGB(255, 250, 240),
            Contrast = 0.1
        }
    )
    
    aberrationTween:Play()
    
    -- Reset chromatic aberration
    aberrationTween.Completed:Connect(function()
        wait(duration - EFFECTS_CONFIG.speedBoost.duration * 0.4)
        
        local resetTween = TweenService:Create(
            colorCorrectionEffect,
            TweenInfo.new(
                EFFECTS_CONFIG.speedBoost.duration * 0.2,
                Enum.EasingStyle.Sine,
                Enum.EasingDirection.In
            ),
            {
                TintColor = Color3.new(1, 1, 1),
                Contrast = 0
            }
        )
        
        resetTween:Play()
    end)
end

function ScreenEffectsController:ResetSpeedBoostEffects()
    -- Ensure all speed boost effects are reset
    camera.FieldOfView = originalFOV
    blurEffect.Size = 0
    vignetteFrame.BackgroundTransparency = 1
    colorCorrectionEffect.TintColor = Color3.new(1, 1, 1)
    colorCorrectionEffect.Contrast = 0
end

-- JUMP EFFECTS
function ScreenEffectsController:TriggerJumpEffect(jumpPower)
    if isJumpActive then return end
    isJumpActive = true
    
    print("🦘 Triggering jump effect with power " .. jumpPower)
    
    -- Pre-jump anticipation
    self:TriggerJumpAnticipation()
    
    -- Screen shake
    spawn(function()
        wait(EFFECTS_CONFIG.jump.anticipationTime)
        self:TriggerScreenShake(EFFECTS_CONFIG.jump.shakeIntensity * jumpPower, EFFECTS_CONFIG.jump.shakeDuration)
    end)
    
    -- Screen bounce
    spawn(function()
        wait(EFFECTS_CONFIG.jump.anticipationTime)
        self:TriggerScreenBounce(jumpPower)
    end)
    
    -- Motion trail effect
    spawn(function()
        wait(EFFECTS_CONFIG.jump.anticipationTime)
        self:TriggerMotionTrail(EFFECTS_CONFIG.jump.trailLength)
    end)
    
    -- Flash effect
    self:TriggerFlashEffect(Color3.new(1, 1, 1), 0.3, 0.1)
    
    -- Reset jump state
    spawn(function()
        wait(EFFECTS_CONFIG.jump.shakeDuration + EFFECTS_CONFIG.jump.anticipationTime)
        isJumpActive = false
    end)
end

function ScreenEffectsController:TriggerJumpAnticipation()
    -- Slight screen compression before jump
    local anticipationTween = TweenService:Create(
        camera,
        TweenInfo.new(
            EFFECTS_CONFIG.jump.anticipationTime,
            Enum.EasingStyle.Back,
            Enum.EasingDirection.In
        ),
        {FieldOfView = originalFOV - 5}
    )
    
    anticipationTween:Play()
    
    anticipationTween.Completed:Connect(function()
        local releaseTween = TweenService:Create(
            camera,
            TweenInfo.new(
                EFFECTS_CONFIG.jump.anticipationTime,
                Enum.EasingStyle.Back,
                Enum.EasingDirection.Out
            ),
            {FieldOfView = originalFOV}
        )
        
        releaseTween:Play()
    end)
end

function ScreenEffectsController:TriggerScreenShake(intensity, duration)
    currentShakeIntensity = intensity
    
    -- Create shake effect using camera manipulation
    if cameraShakeConnection then
        cameraShakeConnection:Disconnect()
    end
    
    local originalCFrame = camera.CFrame
    local shakeStartTime = tick()
    
    cameraShakeConnection = RunService.RenderStepped:Connect(function()
        local elapsed = tick() - shakeStartTime
        local progress = elapsed / duration
        
        if progress >= 1 then
            -- End shake
            cameraShakeConnection:Disconnect()
            cameraShakeConnection = nil
            currentShakeIntensity = 0
            return
        end
        
        -- Calculate shake with decreasing intensity
        local currentIntensity = intensity * (1 - progress)
        local randomX = (math.random() - 0.5) * currentIntensity
        local randomY = (math.random() - 0.5) * currentIntensity
        local randomZ = (math.random() - 0.5) * currentIntensity
        
        -- Apply shake to camera
        local shakeOffset = Vector3.new(randomX, randomY, randomZ)
        camera.CFrame = camera.CFrame + shakeOffset
    end)
end

function ScreenEffectsController:TriggerScreenBounce(jumpPower)
    -- Brief screen scale effect
    local bounceScale = 1 + (EFFECTS_CONFIG.jump.bounceScale - 1) * jumpPower
    
    -- Create temporary frame for bounce effect
    local bounceFrame = Instance.new("Frame")
    bounceFrame.Name = "BounceEffect"
    bounceFrame.Size = UDim2.new(bounceScale, 0, bounceScale, 0)
    bounceFrame.Position = UDim2.new(0.5 - bounceScale/2, 0, 0.5 - bounceScale/2, 0)
    bounceFrame.BackgroundTransparency = 1
    bounceFrame.Parent = effectsGui
    
    -- Animate bounce
    local bounceInTween = TweenService:Create(
        bounceFrame,
        TweenInfo.new(
            EFFECTS_CONFIG.jump.shakeDuration * 0.3,
            Enum.EasingStyle.Back,
            Enum.EasingDirection.Out
        ),
        {
            Size = UDim2.new(1, 0, 1, 0),
            Position = UDim2.new(0, 0, 0, 0)
        }
    )
    
    bounceInTween:Play()
    
    bounceInTween.Completed:Connect(function()
        bounceFrame:Destroy()
    end)
end

function ScreenEffectsController:TriggerMotionTrail(duration)
    -- Create fading trail effect
    local trailTween = TweenService:Create(
        blurEffect,
        TweenInfo.new(
            duration * 0.3,
            Enum.EasingStyle.Quart,
            Enum.EasingDirection.Out
        ),
        {Size = 4}
    )
    
    trailTween:Play()
    
    trailTween.Completed:Connect(function()
        local fadeTrailTween = TweenService:Create(
            blurEffect,
            TweenInfo.new(
                duration * 0.7,
                Enum.EasingStyle.Quart,
                Enum.EasingDirection.In
            ),
            {Size = 0}
        )
        
        fadeTrailTween:Play()
    end)
end

-- DEATH EFFECTS
function ScreenEffectsController:TriggerDeathEffect()
    if isDeathActive then return end
    isDeathActive = true
    
    print("💀 Triggering death effect")
    
    -- Red damage flash
    self:TriggerFlashEffect(Color3.fromRGB(255, 100, 100), EFFECTS_CONFIG.death.redFlashIntensity, 0.2)
    
    -- Gradual desaturation
    spawn(function()
        wait(0.3)
        self:TriggerDesaturation()
    end)
    
    -- Vignette growth
    spawn(function()
        wait(0.5)
        self:TriggerDeathVignette()
    end)
    
    -- Blur growth
    spawn(function()
        wait(0.8)
        self:TriggerDeathBlur()
    end)
    
    -- Final fade to black
    spawn(function()
        wait(1.2)
        self:TriggerFadeToBlack()
    end)
end

function ScreenEffectsController:TriggerDesaturation()
    local desaturationTween = TweenService:Create(
        colorCorrectionEffect,
        TweenInfo.new(
            EFFECTS_CONFIG.death.desaturationTime,
            Enum.EasingStyle.Quart,
            Enum.EasingDirection.Out
        ),
        {
            Saturation = -1,
            Brightness = -0.3,
            Contrast = -0.2
        }
    )
    
    desaturationTween:Play()
end

function ScreenEffectsController:TriggerDeathVignette()
    local vignetteTween = TweenService:Create(
        vignetteFrame,
        TweenInfo.new(
            EFFECTS_CONFIG.death.fadeDuration * 0.6,
            Enum.EasingStyle.Quart,
            Enum.EasingDirection.Out
        ),
        {BackgroundTransparency = 1 - EFFECTS_CONFIG.death.vignetteGrowth}
    )
    
    vignetteTween:Play()
end

function ScreenEffectsController:TriggerDeathBlur()
    local blurTween = TweenService:Create(
        blurEffect,
        TweenInfo.new(
            EFFECTS_CONFIG.death.fadeDuration * 0.8,
            Enum.EasingStyle.Quart,
            Enum.EasingDirection.Out
        ),
        {Size = EFFECTS_CONFIG.death.blurGrowth}
    )
    
    blurTween:Play()
end

function ScreenEffectsController:TriggerFadeToBlack()
    local fadeTween = TweenService:Create(
        fadeFrame,
        TweenInfo.new(
            EFFECTS_CONFIG.death.fadeDuration * 0.4,
            Enum.EasingStyle.Quart,
            Enum.EasingDirection.Out
        ),
        {BackgroundTransparency = 0}
    )
    
    fadeTween:Play()
end

-- UTILITY EFFECTS
function ScreenEffectsController:TriggerFlashEffect(color, intensity, duration)
    flashFrame.BackgroundColor3 = color
    flashFrame.BackgroundTransparency = 1 - intensity
    
    local flashTween = TweenService:Create(
        flashFrame,
        TweenInfo.new(
            duration,
            Enum.EasingStyle.Quart,
            Enum.EasingDirection.Out
        ),
        {BackgroundTransparency = 1}
    )
    
    flashTween:Play()
end

-- RESET FUNCTIONS
function ScreenEffectsController:ResetAllEffects()
    print("🔄 Resetting all screen effects")
    
    -- Stop camera shake
    if cameraShakeConnection then
        cameraShakeConnection:Disconnect()
        cameraShakeConnection = nil
    end
    
    -- Reset camera
    camera.FieldOfView = originalFOV
    
    -- Reset lighting effects
    blurEffect.Size = 0
    colorCorrectionEffect.Saturation = 0
    colorCorrectionEffect.Contrast = 0
    colorCorrectionEffect.Brightness = 0
    colorCorrectionEffect.TintColor = Color3.new(1, 1, 1)
    
    -- Reset UI effects
    vignetteFrame.BackgroundTransparency = 1
    fadeFrame.BackgroundTransparency = 1
    flashFrame.BackgroundTransparency = 1
    
    -- Reset state
    isSpeedBoostActive = false
    isJumpActive = false
    isDeathActive = false
    currentShakeIntensity = 0
end

function ScreenEffectsController:ResetDeathEffects()
    print("❤️ Resetting death effects (respawn)")
    
    -- Fade back in
    local respawnTween = TweenService:Create(
        fadeFrame,
        TweenInfo.new(
            1.0,
            Enum.EasingStyle.Quart,
            Enum.EasingDirection.Out
        ),
        {BackgroundTransparency = 1}
    )
    
    respawnTween:Play()
    
    -- Restore color
    local colorTween = TweenService:Create(
        colorCorrectionEffect,
        TweenInfo.new(
            1.5,
            Enum.EasingStyle.Quart,
            Enum.EasingDirection.Out
        ),
        {
            Saturation = 0,
            Brightness = 0,
            Contrast = 0
        }
    )
    
    colorTween:Play()
    
    -- Remove vignette
    local vignetteTween = TweenService:Create(
        vignetteFrame,
        TweenInfo.new(
            1.0,
            Enum.EasingStyle.Quart,
            Enum.EasingDirection.Out
        ),
        {BackgroundTransparency = 1}
    )
    
    vignetteTween:Play()
    
    -- Remove blur
    local blurTween = TweenService:Create(
        blurEffect,
        TweenInfo.new(
            1.0,
            Enum.EasingStyle.Quart,
            Enum.EasingDirection.Out
        ),
        {Size = 0}
    )
    
    blurTween:Play()
    
    isDeathActive = false
end

-- NEW SCREEN EFFECT FUNCTIONS

function ScreenEffectsController:TriggerFOVZoom(intensity, duration)
    if not camera then return end
    
    local targetFOV = originalFOV * (1 + intensity) -- Zoom effect
    duration = duration or 0.5
    
    print(string.format("🔍 FOV Zoom: %d → %d for %.1fs", originalFOV, targetFOV, duration))
    
    -- Zoom in
    local zoomInTween = TweenService:Create(
        camera,
        TweenInfo.new(
            duration * 0.3, -- Quick zoom in
            Enum.EasingStyle.Quart,
            Enum.EasingDirection.Out
        ),
        {FieldOfView = targetFOV}
    )
    
    -- Zoom back out
    local zoomOutTween = TweenService:Create(
        camera,
        TweenInfo.new(
            duration * 0.7, -- Slower zoom out
            Enum.EasingStyle.Quart,
            Enum.EasingDirection.InOut
        ),
        {FieldOfView = originalFOV}
    )
    
    zoomInTween:Play()
    zoomInTween.Completed:Connect(function()
        zoomOutTween:Play()
    end)
end

function ScreenEffectsController:TriggerColorMismatchEffect(effectData)
    local playerColor = effectData.playerColor
    local obstacleColor = effectData.obstacleColor
    local intensity = effectData.intensity or 0.5
    
    print(string.format("⚠️ Color Mismatch: %s vs %s", playerColor, obstacleColor))
    
    -- Flash red for color mismatch
    self:TriggerFlashEffect(Color3.fromRGB(255, 50, 50), intensity, 0.3)
    
    -- Screen shake for emphasis
    self:TriggerScreenShake(intensity * 0.6, 0.4)
    
    -- Create color mismatch visual indicator
    local indicator = Instance.new("Frame")
    indicator.Name = "ColorMismatchIndicator"
    indicator.Size = UDim2.new(0.4, 0, 0.1, 0)
    indicator.Position = UDim2.new(0.3, 0, 0.1, 0)
    indicator.BackgroundColor3 = Color3.fromRGB(255, 100, 100)
    indicator.BorderSizePixel = 0
    indicator.Parent = effectsGui
    
    -- Add text
    local textLabel = Instance.new("TextLabel")
    textLabel.Size = UDim2.new(1, 0, 1, 0)
    textLabel.BackgroundTransparency = 1
    textLabel.Text = string.format("COLOR MISMATCH!\n%s ≠ %s", playerColor, obstacleColor)
    textLabel.TextColor3 = Color3.new(1, 1, 1)
    textLabel.TextScaled = true
    textLabel.Font = Enum.Font.GothamBold
    textLabel.Parent = indicator
    
    -- Animate indicator
    indicator.BackgroundTransparency = 1
    textLabel.TextTransparency = 1
    
    local appearTween = TweenService:Create(
        indicator,
        TweenInfo.new(0.1, Enum.EasingStyle.Quart, Enum.EasingDirection.Out),
        {BackgroundTransparency = 0.2}
    )
    
    local textAppearTween = TweenService:Create(
        textLabel,
        TweenInfo.new(0.1, Enum.EasingStyle.Quart, Enum.EasingDirection.Out),
        {TextTransparency = 0}
    )
    
    appearTween:Play()
    textAppearTween:Play()
    
    -- Remove after duration
    spawn(function()
        wait(1.5)
        
        local disappearTween = TweenService:Create(
            indicator,
            TweenInfo.new(0.5, Enum.EasingStyle.Quart, Enum.EasingDirection.In),
            {BackgroundTransparency = 1}
        )
        
        local textDisappearTween = TweenService:Create(
            textLabel,
            TweenInfo.new(0.5, Enum.EasingStyle.Quart, Enum.EasingDirection.In),
            {TextTransparency = 1}
        )
        
        disappearTween:Play()
        textDisappearTween:Play()
        
        disappearTween.Completed:Connect(function()
            indicator:Destroy()
        end)
    end)
end

-- PUBLIC API METHODS
function ScreenEffectsController:SpeedBoost(duration)
    self:TriggerSpeedBoostEffect(duration or 1.0)
end

function ScreenEffectsController:Jump(power)
    self:TriggerJumpEffect(power or 1.0)
end

function ScreenEffectsController:Death()
    self:TriggerDeathEffect()
end

function ScreenEffectsController:Respawn()
    self:ResetDeathEffects()
end

function ScreenEffectsController:Flash(color, intensity, duration)
    self:TriggerFlashEffect(color or Color3.new(1, 1, 1), intensity or 0.5, duration or 0.2)
end

function ScreenEffectsController:Shake(intensity, duration)
    self:TriggerScreenShake(intensity or 1.0, duration or 0.5)
end

-- Initialize the controller
spawn(function()
    wait(2) -- Wait for game to load
    ScreenEffectsController:Init()
end)

-- Listen for character respawn
player.CharacterAdded:Connect(function()
    spawn(function()
        wait(1) -- Wait for character to fully load
        ScreenEffectsController:ResetDeathEffects()
    end)
end)

return ScreenEffectsController
