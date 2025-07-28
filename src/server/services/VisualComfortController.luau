-- VisualComfortController.luau
-- Reduces overly bright lighting and effects for better visibility
-- Place this in ServerScriptService to automatically improve game visuals

local Lighting = game:GetService("Lighting")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local VisualComfortController = {}

-- Lighting Configuration for Better Visibility
local COMFORT_LIGHTING = {
    -- Reduced brightness settings
    brightness = 1.5,     -- Reduced from default 2
    ambient = Color3.fromRGB(80, 80, 100),  -- Softer ambient light
    outdoorAmbient = Color3.fromRGB(100, 110, 120), -- Softer outdoor ambient
    
    -- Atmosphere settings
    atmosphereDensity = 0.3,
    atmosphereOffset = 0.25,
    atmosphereColor = Color3.fromRGB(199, 199, 199),
    atmosphereDecay = Color3.fromRGB(92, 60, 13),
    atmosphereGlare = 0.2,  -- Reduced glare
    atmosphereHaze = 1.8,
    
    -- Fog for distance comfort
    fogColor = Color3.fromRGB(192, 192, 196),
    fogStart = 500,
    fogEnd = 2000
}

function VisualComfortController:Initialize()
    print("👁️ Initializing Visual Comfort Controller...")
    
    -- Apply comfortable lighting settings
    self:SetupComfortableLighting()
    
    -- Monitor and fix overly bright objects
    self:StartBrightnessMonitoring()
    
    print("✅ Visual comfort settings applied!")
end

function VisualComfortController:SetupComfortableLighting()
    -- Set comfortable lighting values
    Lighting.Brightness = COMFORT_LIGHTING.brightness
    Lighting.Ambient = COMFORT_LIGHTING.ambient
    Lighting.OutdoorAmbient = COMFORT_LIGHTING.outdoorAmbient
    
    -- Create or update atmosphere
    local atmosphere = Lighting:FindFirstChildOfClass("Atmosphere")
    if not atmosphere then
        atmosphere = Instance.new("Atmosphere")
        atmosphere.Parent = Lighting
    end
    
    atmosphere.Density = COMFORT_LIGHTING.atmosphereDensity
    atmosphere.Offset = COMFORT_LIGHTING.atmosphereOffset
    atmosphere.Color = COMFORT_LIGHTING.atmosphereColor
    atmosphere.Decay = COMFORT_LIGHTING.atmosphereDecay
    atmosphere.Glare = COMFORT_LIGHTING.atmosphereGlare
    atmosphere.Haze = COMFORT_LIGHTING.atmosphereHaze
    
    -- Set comfortable fog
    Lighting.FogColor = COMFORT_LIGHTING.fogColor
    Lighting.FogStart = COMFORT_LIGHTING.fogStart
    Lighting.FogEnd = COMFORT_LIGHTING.fogEnd
    
    print("🌅 Comfortable lighting settings applied")
end

function VisualComfortController:StartBrightnessMonitoring()
    -- Monitor every 5 seconds for overly bright objects
    spawn(function()
        while true do
            self:ReduceExcessiveBrightness()
            wait(5)
        end
    end)
end

function VisualComfortController:ReduceExcessiveBrightness()
    -- Find and reduce brightness of overly bright PointLights
    for _, obj in pairs(Workspace:GetDescendants()) do
        if obj:IsA("PointLight") then
            if obj.Brightness > 2 then
                obj.Brightness = math.min(obj.Brightness, 1.5) -- Cap brightness
                print("🔅 Reduced brightness of PointLight in " .. (obj.Parent and obj.Parent.Name or "unknown"))
            end
            
            if obj.Range > 30 then
                obj.Range = math.min(obj.Range, 20) -- Cap range
            end
        elseif obj:IsA("SurfaceLight") then
            if obj.Brightness > 2 then
                obj.Brightness = math.min(obj.Brightness, 1.5)
            end
        elseif obj:IsA("SpotLight") then
            if obj.Brightness > 2 then
                obj.Brightness = math.min(obj.Brightness, 1.5)
            end
        end
        
        -- Reduce overly saturated neon materials
        if obj:IsA("BasePart") and obj.Material == Enum.Material.Neon then
            if obj.Color.R > 0.9 and obj.Color.G > 0.9 and obj.Color.B > 0.9 then
                -- Make pure white neon less bright
                obj.Color = Color3.fromRGB(200, 200, 200)
            end
        end
    end
end

-- Additional helper functions
function VisualComfortController:ReducePartBrightness(part)
    if not part:IsA("BasePart") then return end
    
    -- Make neon parts less aggressive
    if part.Material == Enum.Material.Neon then
        part.Transparency = math.max(part.Transparency, 0.2) -- Add some transparency
    end
    
    -- Reduce brightness of very bright colors
    local color = part.Color
    if color.R > 0.8 and color.G > 0.8 and color.B > 0.8 then
        part.Color = Color3.fromRGB(
            math.floor(color.R * 200),
            math.floor(color.G * 200), 
            math.floor(color.B * 200)
        )
    end
end

function VisualComfortController:ApplyComfortableColors()
    -- Apply the muted color scheme to existing objects
    local tracks = Workspace:FindFirstChild("Tracks")
    if tracks then
        for _, folder in pairs(tracks:GetChildren()) do
            if folder:IsA("Folder") then
                for _, object in pairs(folder:GetChildren()) do
                    if object:IsA("BasePart") then
                        self:ReducePartBrightness(object)
                    end
                end
            end
        end
    end
end

-- Time of day adjustment for comfort
function VisualComfortController:SetComfortableTimeOfDay()
    -- Set a comfortable time that's not too bright or too dark
    Lighting.TimeOfDay = "14:00:00" -- 2 PM - good balance
    Lighting.GeographicLatitude = 0 -- Neutral lighting angle
end

-- Initialize automatically
VisualComfortController:Initialize()
VisualComfortController:SetComfortableTimeOfDay()
VisualComfortController:ApplyComfortableColors()

return VisualComfortController
