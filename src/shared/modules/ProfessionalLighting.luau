-- ProfessionalLighting.luau
-- Centralized professional lighting settings for consistent visual quality
-- Use this module across all systems for production-ready lighting

local ProfessionalLighting = {}

-- Professional Lighting Constants
ProfessionalLighting.SETTINGS = {
    -- Core lighting properties
    brightness = 1,
    exposureCompensation = -0.5,
    ambient = Color3.fromRGB(80, 80, 80),
    outdoorAmbient = Color3.fromRGB(100, 100, 100),
    
    -- Color correction for professional visuals
    colorCorrection = {
        brightness = -0.1,
        contrast = 0.05,
        saturation = 0.9,
        enabled = true
    },
    
    -- Professional atmosphere settings
    atmosphere = {
        density = 0.3,
        offset = 0.25,
        color = Color3.fromRGB(199, 199, 199),
        decay = Color3.fromRGB(92, 60, 13),
        glare = 0.2,
        haze = 1.8
    },
    
    -- Fog settings for depth and professionalism
    fog = {
        color = Color3.fromRGB(192, 192, 196),
        start = 500,
        end = 2000
    },
    
    -- Professional light brightness limits
    lightLimits = {
        pointLight = 0.8,
        spotLight = 0.8,
        surfaceLight = 0.8,
        maxRange = 20
    },
    
    -- Time settings for optimal lighting
    timeOfDay = "14:00:00",  -- 2 PM for balanced lighting
    geographicLatitude = 0
}

-- Apply professional lighting to game.Lighting
function ProfessionalLighting:ApplyToLighting()
    local Lighting = game:GetService("Lighting")
    local settings = self.SETTINGS
    
    print("🎬 Applying professional lighting settings...")
    
    -- Core lighting properties
    Lighting.Brightness = settings.brightness
    Lighting.ExposureCompensation = settings.exposureCompensation
    Lighting.Ambient = settings.ambient
    Lighting.OutdoorAmbient = settings.outdoorAmbient
    Lighting.TimeOfDay = settings.timeOfDay
    Lighting.GeographicLatitude = settings.geographicLatitude
    
    -- Color correction effect
    if settings.colorCorrection.enabled then
        local colorCorrection = Lighting:FindFirstChildOfClass("ColorCorrectionEffect")
        if not colorCorrection then
            colorCorrection = Instance.new("ColorCorrectionEffect")
            colorCorrection.Parent = Lighting
        end
        
        colorCorrection.Brightness = settings.colorCorrection.brightness
        colorCorrection.Contrast = settings.colorCorrection.contrast
        colorCorrection.Saturation = settings.colorCorrection.saturation
        colorCorrection.Enabled = true
    end
    
    -- Atmosphere effects
    local atmosphere = Lighting:FindFirstChildOfClass("Atmosphere")
    if not atmosphere then
        atmosphere = Instance.new("Atmosphere")
        atmosphere.Parent = Lighting
    end
    
    atmosphere.Density = settings.atmosphere.density
    atmosphere.Offset = settings.atmosphere.offset
    atmosphere.Color = settings.atmosphere.color
    atmosphere.Decay = settings.atmosphere.decay
    atmosphere.Glare = settings.atmosphere.glare
    atmosphere.Haze = settings.atmosphere.haze
    
    -- Fog settings
    Lighting.FogColor = settings.fog.color
    Lighting.FogStart = settings.fog.start
    Lighting.FogEnd = settings.fog.end
    
    print("✨ Professional lighting applied successfully")
end

-- Create a professional PointLight with proper brightness
function ProfessionalLighting:CreatePointLight(color, customBrightness)
    local pointLight = Instance.new("PointLight")
    pointLight.Color = color or Color3.fromRGB(255, 255, 255)
    pointLight.Brightness = customBrightness or self.SETTINGS.lightLimits.pointLight
    pointLight.Range = math.min(pointLight.Range, self.SETTINGS.lightLimits.maxRange)
    return pointLight
end

-- Create a professional SpotLight with proper brightness
function ProfessionalLighting:CreateSpotLight(color, customBrightness)
    local spotLight = Instance.new("SpotLight")
    spotLight.Color = color or Color3.fromRGB(255, 255, 255)
    spotLight.Brightness = customBrightness or self.SETTINGS.lightLimits.spotLight
    spotLight.Range = math.min(spotLight.Range, self.SETTINGS.lightLimits.maxRange)
    return spotLight
end

-- Create a professional SurfaceLight with proper brightness
function ProfessionalLighting:CreateSurfaceLight(color, customBrightness)
    local surfaceLight = Instance.new("SurfaceLight")
    surfaceLight.Color = color or Color3.fromRGB(255, 255, 255)
    surfaceLight.Brightness = customBrightness or self.SETTINGS.lightLimits.surfaceLight
    surfaceLight.Range = math.min(surfaceLight.Range, self.SETTINGS.lightLimits.maxRange)
    return surfaceLight
end

-- Adjust existing light to professional standards
function ProfessionalLighting:AdjustLight(light)
    if not light or not light:IsA("Light") then return end
    
    local limits = self.SETTINGS.lightLimits
    
    if light:IsA("PointLight") then
        light.Brightness = math.min(light.Brightness, limits.pointLight)
    elseif light:IsA("SpotLight") then
        light.Brightness = math.min(light.Brightness, limits.spotLight)
    elseif light:IsA("SurfaceLight") then
        light.Brightness = math.min(light.Brightness, limits.surfaceLight)
    end
    
    -- Adjust range if applicable
    if light:FindFirstChild("Range") then
        light.Range = math.min(light.Range, limits.maxRange)
    end
end

-- Monitor and adjust all lights in workspace to professional standards
function ProfessionalLighting:MonitorAndAdjustLights()
    local Workspace = game:GetService("Workspace")
    
    for _, obj in pairs(Workspace:GetDescendants()) do
        if obj:IsA("Light") then
            self:AdjustLight(obj)
        end
    end
end

-- Get professional brightness for specific light types
function ProfessionalLighting:GetRecommendedBrightness(lightType)
    local limits = self.SETTINGS.lightLimits
    
    if lightType == "PointLight" then
        return limits.pointLight
    elseif lightType == "SpotLight" then
        return limits.spotLight
    elseif lightType == "SurfaceLight" then
        return limits.surfaceLight
    else
        return limits.pointLight  -- Default to point light brightness
    end
end

-- Get professional color with muted tones
function ProfessionalLighting:GetProfessionalColor(originalColor)
    if not originalColor then return Color3.fromRGB(180, 180, 180) end
    
    -- Convert bright colors to muted professional versions
    local r, g, b = math.floor(originalColor.R * 255), math.floor(originalColor.G * 255), math.floor(originalColor.B * 255)
    
    -- Apply muting formula for professional look
    r = math.min(r, 200)  -- Cap brightness
    g = math.min(g, 200)
    b = math.min(b, 200)
    
    -- Ensure minimum contrast
    if r < 60 and g < 60 and b < 60 then
        r, g, b = 80, 80, 80  -- Minimum brightness for visibility
    end
    
    return Color3.fromRGB(r, g, b)
end

-- Initialize professional lighting (call this in server scripts)
function ProfessionalLighting:Initialize()
    print("🎬 Initializing Professional Lighting System...")
    
    -- Apply lighting immediately
    self:ApplyToLighting()
    
    -- Start monitoring system
    spawn(function()
        while true do
            self:MonitorAndAdjustLights()
            wait(10)  -- Check every 10 seconds
        end
    end)
    
    print("✅ Professional Lighting System active")
end

return ProfessionalLighting
