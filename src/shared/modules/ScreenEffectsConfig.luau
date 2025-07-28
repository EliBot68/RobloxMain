-- ScreenEffectsConfig.luau
-- Configuration module for screen effects system
-- Customize all effect parameters here

local ScreenEffectsConfig = {}

-- SPEED BOOST EFFECTS CONFIGURATION
ScreenEffectsConfig.SpeedBoost = {
    -- Field of View Effects
    fovIncrease = 15,              -- How much to increase FOV (degrees)
    fovTransitionTime = 0.3,       -- Time to transition FOV in/out
    
    -- Motion Blur Effects  
    blurSize = 8,                  -- Maximum blur intensity
    blurFadeInTime = 0.2,          -- Time to fade blur in
    blurFadeOutTime = 0.2,         -- Time to fade blur out
    
    -- Vignette Effects
    vignetteIntensity = 0.3,       -- Edge darkening strength (0-1)
    vignetteTransitionTime = 0.3,  -- Vignette fade time
    
    -- Color Effects
    chromaticAberration = 2,       -- Color separation intensity
    tintColor = Color3.fromRGB(255, 250, 240), -- Slight warm tint
    contrastBoost = 0.1,           -- Slight contrast increase
    
    -- Audio Enhancement (if applicable)
    soundPitch = 1.2,              -- Speed up audio slightly
    soundVolume = 0.8,             -- Lower volume during effect
    
    -- Performance Settings
    updateRate = 60,               -- FPS for smooth transitions
    enabledOnMobile = true,        -- Enable on mobile devices
    reducedQualityOnMobile = true  -- Use lighter effects on mobile
}

-- JUMP EFFECTS CONFIGURATION  
ScreenEffectsConfig.Jump = {
    -- Camera Shake
    shakeIntensity = 1.5,          -- Base shake strength
    shakeDuration = 0.4,           -- How long shake lasts
    shakeDecay = 0.8,              -- How quickly shake fades
    
    -- Screen Bounce
    bounceScale = 1.2,             -- Screen scale multiplier
    bounceDuration = 0.3,          -- Bounce animation time
    bounceEasing = Enum.EasingStyle.Back, -- Bounce animation style
    
    -- Anticipation Effect
    anticipationTime = 0.1,        -- Pre-jump wind-up time
    anticipationFOV = -5,          -- FOV reduction before jump
    
    -- Motion Trail
    trailDuration = 0.6,           -- Trail effect duration
    trailBlurSize = 4,             -- Trail blur intensity
    trailFadeTime = 0.4,           -- Trail fade out time
    
    -- Flash Effect
    flashColor = Color3.new(1, 1, 1), -- White flash
    flashIntensity = 0.3,          -- Flash brightness
    flashDuration = 0.1,           -- Flash duration
    
    -- Power Scaling
    minPower = 0.5,                -- Minimum effect power
    maxPower = 3.0,                -- Maximum effect power
    powerCurve = 1.2,              -- Power scaling curve
    
    -- Mobile Optimization
    reducedShakeOnMobile = true,   -- Reduce shake on mobile
    mobileShakeMultiplier = 0.7    -- Mobile shake reduction
}

-- DEATH EFFECTS CONFIGURATION
ScreenEffectsConfig.Death = {
    -- Color Desaturation
    desaturationTime = 1.5,        -- Time to drain color
    finalSaturation = -1,          -- Final saturation level
    brightnessReduction = -0.3,    -- Brightness reduction
    contrastReduction = -0.2,      -- Contrast reduction
    
    -- Fade to Black
    fadeDelay = 1.2,               -- Delay before fade starts
    fadeDuration = 0.8,            -- Fade to black duration
    fadeEasing = Enum.EasingStyle.Quart, -- Fade animation style
    
    -- Vignette Growth
    vignetteDelay = 0.5,           -- Delay before vignette starts
    vignetteGrowthTime = 1.0,      -- Vignette expansion time
    maxVignetteIntensity = 0.9,    -- Maximum vignette darkness
    
    -- Blur Effect
    blurDelay = 0.8,               -- Delay before blur starts
    blurGrowthTime = 1.2,          -- Blur growth duration
    maxBlurSize = 12,              -- Maximum blur intensity
    
    -- Initial Flash
    damageFlashColor = Color3.fromRGB(255, 100, 100), -- Red damage flash
    damageFlashIntensity = 0.4,    -- Flash brightness
    damageFlashDuration = 0.2,     -- Flash duration
    
    -- Sound Effects (if applicable)
    muteAudioOnDeath = true,       -- Gradually mute audio
    audioFadeTime = 2.0,           -- Audio fade duration
    
    -- Respawn Settings
    respawnFadeTime = 1.0,         -- Fade back in time
    respawnColorTime = 1.5,        -- Color restoration time
    respawnBlurTime = 1.0,         -- Blur removal time
    respawnVignetteTime = 1.0      -- Vignette removal time
}

-- GENERAL EFFECT SETTINGS
ScreenEffectsConfig.General = {
    -- Performance
    maxConcurrentEffects = 3,      -- Maximum effects at once
    effectQuality = "High",        -- "Low", "Medium", "High"
    frameRateThreshold = 30,       -- Reduce quality below this FPS
    
    -- Platform Optimization
    mobileOptimizations = {
        reducedBlur = true,         -- Reduce blur on mobile
        simplifiedShake = true,     -- Simpler shake on mobile  
        fasterTransitions = true,   -- Faster transitions on mobile
        reducedParticles = true     -- Fewer particles on mobile
    },
    
    -- Accessibility
    accessibilityMode = false,     -- Reduced effects for sensitivity
    reducedFlashing = false,       -- Reduce flash effects
    reducedMotion = false,         -- Reduce motion effects
    colorBlindSupport = true,      -- Enhanced color contrast
    
    -- Animation Settings
    defaultEasing = Enum.EasingStyle.Quart,
    defaultDirection = Enum.EasingDirection.Out,
    smoothTransitions = true,      -- Use smooth transitions
    
    -- Debug Settings
    enableDebugOutput = false,     -- Print debug information
    showEffectNames = false,       -- Show effect names on screen
    logPerformance = false         -- Log performance metrics
}

-- UTILITY EFFECTS CONFIGURATION
ScreenEffectsConfig.Utility = {
    -- Flash Effects
    defaultFlashColor = Color3.new(1, 1, 1),
    defaultFlashIntensity = 0.5,
    defaultFlashDuration = 0.2,
    
    -- Screen Shake
    defaultShakeIntensity = 1.0,
    defaultShakeDuration = 0.5,
    maxShakeDistance = 10,         -- Maximum shake displacement
    
    -- Camera Effects
    defaultFOV = 70,               -- Default field of view
    maxFOVChange = 20,             -- Maximum FOV modification
    fovSmoothness = 0.1,           -- FOV transition smoothness
    
    -- Color Effects
    colorTransitionTime = 0.5,     -- Default color transition time
    maxSaturationChange = 2,       -- Maximum saturation change
    maxBrightnessChange = 1,       -- Maximum brightness change
    maxContrastChange = 1          -- Maximum contrast change
}

-- PRESET CONFIGURATIONS
ScreenEffectsConfig.Presets = {
    -- Subtle effects for sensitive players
    Subtle = {
        speedBoostFOV = 8,
        jumpShake = 0.8,
        deathFade = 1.0,
        flashIntensity = 0.3
    },
    
    -- Standard effects (default)
    Standard = {
        speedBoostFOV = 15,
        jumpShake = 1.5,
        deathFade = 2.0,
        flashIntensity = 0.5
    },
    
    -- Intense effects for dramatic gameplay
    Intense = {
        speedBoostFOV = 25,
        jumpShake = 2.5,
        deathFade = 3.0,
        flashIntensity = 0.8
    },
    
    -- Mobile optimized
    Mobile = {
        speedBoostFOV = 10,
        jumpShake = 1.0,
        deathFade = 1.5,
        flashIntensity = 0.4,
        reducedBlur = true,
        fasterTransitions = true
    }
}

-- DEVICE-SPECIFIC SETTINGS
ScreenEffectsConfig.DeviceSettings = {
    -- Desktop/Console
    Desktop = {
        enableAllEffects = true,
        highQualityBlur = true,
        complexAnimations = true,
        fullColorRange = true
    },
    
    -- Mobile/Tablet
    Mobile = {
        enableAllEffects = true,
        highQualityBlur = false,
        complexAnimations = false,
        optimizedTransitions = true
    },
    
    -- VR (if applicable)
    VR = {
        reducedShake = true,        -- Reduce motion sickness
        quickerTransitions = true,
        enhancedDepthEffects = true
    }
}

-- SEASONAL/THEMED EFFECTS
ScreenEffectsConfig.Themes = {
    -- Default theme
    Default = {
        speedBoostTint = Color3.fromRGB(255, 250, 240),
        jumpFlash = Color3.new(1, 1, 1),
        deathColor = Color3.new(0, 0, 0)
    },
    
    -- Halloween theme
    Halloween = {
        speedBoostTint = Color3.fromRGB(255, 140, 0),
        jumpFlash = Color3.fromRGB(255, 140, 0),
        deathColor = Color3.fromRGB(139, 0, 0)
    },
    
    -- Christmas theme
    Christmas = {
        speedBoostTint = Color3.fromRGB(255, 240, 240),
        jumpFlash = Color3.fromRGB(0, 255, 0),
        deathColor = Color3.fromRGB(139, 0, 0)
    },
    
    -- Neon theme
    Neon = {
        speedBoostTint = Color3.fromRGB(0, 255, 255),
        jumpFlash = Color3.fromRGB(255, 0, 255),
        deathColor = Color3.fromRGB(0, 0, 0)
    }
}

-- VALIDATION AND HELPER FUNCTIONS
function ScreenEffectsConfig:ValidateConfig()
    -- Ensure all values are within acceptable ranges
    local function clamp(value, min, max)
        return math.max(min, math.min(max, value))
    end
    
    -- Validate speed boost settings
    self.SpeedBoost.fovIncrease = clamp(self.SpeedBoost.fovIncrease, 0, 30)
    self.SpeedBoost.blurSize = clamp(self.SpeedBoost.blurSize, 0, 20)
    self.SpeedBoost.vignetteIntensity = clamp(self.SpeedBoost.vignetteIntensity, 0, 1)
    
    -- Validate jump settings
    self.Jump.shakeIntensity = clamp(self.Jump.shakeIntensity, 0, 5)
    self.Jump.bounceScale = clamp(self.Jump.bounceScale, 1, 2)
    
    -- Validate death settings
    self.Death.finalSaturation = clamp(self.Death.finalSaturation, -2, 0)
    self.Death.maxBlurSize = clamp(self.Death.maxBlurSize, 0, 30)
    
    print("✅ Screen Effects Config validated!")
end

function ScreenEffectsConfig:ApplyPreset(presetName)
    local preset = self.Presets[presetName]
    if not preset then
        warn("⚠️ Preset '" .. presetName .. "' not found!")
        return false
    end
    
    -- Apply preset values
    if preset.speedBoostFOV then
        self.SpeedBoost.fovIncrease = preset.speedBoostFOV
    end
    if preset.jumpShake then
        self.Jump.shakeIntensity = preset.jumpShake
    end
    if preset.deathFade then
        self.Death.fadeDuration = preset.deathFade
    end
    if preset.flashIntensity then
        self.Utility.defaultFlashIntensity = preset.flashIntensity
    end
    
    print("🎛️ Applied preset: " .. presetName)
    return true
end

function ScreenEffectsConfig:GetCurrentTheme()
    return self.activeTheme or "Default"
end

function ScreenEffectsConfig:SetTheme(themeName)
    local theme = self.Themes[themeName]
    if not theme then
        warn("⚠️ Theme '" .. themeName .. "' not found!")
        return false
    end
    
    self.activeTheme = themeName
    print("🎨 Applied theme: " .. themeName)
    return true
end

-- Initialize with validation
spawn(function()
    ScreenEffectsConfig:ValidateConfig()
    ScreenEffectsConfig:SetTheme("Default")
end)

return ScreenEffectsConfig
