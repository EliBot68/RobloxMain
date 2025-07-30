-- VisualComfortController.luau
-- Uses centralized professional lighting for consistent visual quality
-- Place this in ServerScriptService to automatically improve game visuals

local Lighting = game:GetService("Lighting")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

-- Import centralized professional lighting module
local ProfessionalLighting = require(script.Parent.Parent.shared.modules.ProfessionalLighting)

local VisualComfortController = {}

function VisualComfortController:Initialize()
    print("👁️ Initializing Visual Comfort Controller with Professional Lighting...")
    
    -- Initialize professional lighting system
    ProfessionalLighting:Initialize()
    
    -- Start additional brightness monitoring for legacy objects
    self:StartBrightnessMonitoring()
    
    print("✅ Visual comfort settings with professional lighting applied!")
end

function VisualComfortController:SetupComfortableLighting()
    -- Delegate to professional lighting module
    ProfessionalLighting:ApplyToLighting()
end

function VisualComfortController:StartBrightnessMonitoring()
    -- Monitor brightness using heartbeat connection instead of polling
    local RunService = game:GetService("RunService")
    local lastCheckTime = 0
    local checkInterval = 5 -- seconds
    
    self.brightnessConnection = RunService.Heartbeat:Connect(function()
        local currentTime = tick()
        if currentTime - lastCheckTime >= checkInterval then
            lastCheckTime = currentTime
            self:ReduceExcessiveBrightness()
        end
    end)
end

function VisualComfortController:ReduceExcessiveBrightness()
    -- Use professional lighting module for light adjustment
    ProfessionalLighting:MonitorAndAdjustLights()
    
    -- Additional legacy brightness reduction for parts
    for _, obj in pairs(Workspace:GetDescendants()) do        
        -- Reduce overly saturated neon materials
        if obj:IsA("BasePart") and obj.Material == Enum.Material.Neon then
            if obj.Color.R > 0.9 and obj.Color.G > 0.9 and obj.Color.B > 0.9 then
                -- Make pure white neon less bright using professional colors
                obj.Color = ProfessionalLighting:GetProfessionalColor(obj.Color)
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
    -- Delegate to professional lighting module
    ProfessionalLighting:ApplyToLighting()
end

-- Initialize automatically with professional lighting
VisualComfortController:Initialize()

return VisualComfortController
