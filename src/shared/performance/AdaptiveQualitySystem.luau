-- AdaptiveQualitySystem.luau
-- Dynamic quality adjustment system based on device capabilities and performance
-- Automatically optimizes settings for optimal user experience across all devices

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Lighting = game:GetService("Lighting")
local Workspace = game:GetService("Workspace")
local SoundService = game:GetService("SoundService")
local ContentProvider = game:GetService("ContentProvider")
local GuiService = game:GetService("GuiService")

local SafeRequire = require(ReplicatedStorage.Shared.utils.SafeRequire)

local AdaptiveQualitySystem = {}

-- ========================================
-- QUALITY CONFIGURATION
-- ========================================

local QUALITY_CONFIG = {
    -- Performance monitoring
    performanceThresholds = {
        excellent = {minFPS = 50, maxMemory = 300, maxCPU = 40},
        good = {minFPS = 35, maxMemory = 500, maxCPU = 60},
        fair = {minFPS = 25, maxMemory = 700, maxCPU = 80},
        poor = {minFPS = 15, maxMemory = 900, maxCPU = 95}
    },
    
    -- Device detection
    deviceTypes = {
        high_end = {
            platforms = {"Windows", "Mac"},
            minMemory = 4096, -- MB
            indicators = {"TouchEnabled", "KeyboardEnabled", "MouseEnabled"}
        },
        mid_range = {
            platforms = {"Windows", "Mac", "iOS", "Android"},
            minMemory = 2048,
            indicators = {"TouchEnabled"}
        },
        low_end = {
            platforms = {"iOS", "Android", "Xbox"},
            minMemory = 1024,
            indicators = {"GamepadEnabled", "TouchEnabled"}
        }
    },
    
    -- Quality presets
    qualityPresets = {
        ultra = {
            name = "Ultra",
            graphics = 10,
            lighting = "Future",
            shadows = true,
            postProcessing = true,
            particleCount = 100,
            textureQuality = 1.0,
            modelLOD = 1.0,
            audioQuality = 1.0,
            uiAnimations = true,
            renderDistance = 1000
        },
        high = {
            name = "High",
            graphics = 8,
            lighting = "ShadowMap",
            shadows = true,
            postProcessing = true,
            particleCount = 75,
            textureQuality = 0.9,
            modelLOD = 0.9,
            audioQuality = 0.9,
            uiAnimations = true,
            renderDistance = 800
        },
        medium = {
            name = "Medium",
            graphics = 6,
            lighting = "Voxel",
            shadows = false,
            postProcessing = false,
            particleCount = 50,
            textureQuality = 0.7,
            modelLOD = 0.7,
            audioQuality = 0.8,
            uiAnimations = true,
            renderDistance = 600
        },
        low = {
            name = "Low",
            graphics = 4,
            lighting = "Compatibility",
            shadows = false,
            postProcessing = false,
            particleCount = 25,
            textureQuality = 0.5,
            modelLOD = 0.5,
            audioQuality = 0.6,
            uiAnimations = false,
            renderDistance = 400
        },
        minimal = {
            name = "Minimal",
            graphics = 1,
            lighting = "Compatibility",
            shadows = false,
            postProcessing = false,
            particleCount = 10,
            textureQuality = 0.3,
            modelLOD = 0.3,
            audioQuality = 0.4,
            uiAnimations = false,
            renderDistance = 200
        }
    },
    
    -- Adaptive settings
    adaptiveSettings = {
        monitoringInterval = 5,     -- Seconds between performance checks
        adjustmentCooldown = 15,    -- Seconds to wait before next adjustment
        emergencyThreshold = 10,    -- FPS threshold for emergency quality reduction
        recoveryThreshold = 45,     -- FPS threshold for quality recovery
        memoryPressureThreshold = 800, -- MB threshold for memory-based adjustments
        stabilityRequirement = 10   -- Seconds of stable performance before upgrading
    }
}

-- ========================================
-- ADAPTIVE QUALITY STATE
-- ========================================

local QualityState = {
    -- Current settings
    currentPreset = "medium",
    customSettings = {},
    overrides = {},
    
    -- Device information
    deviceInfo = {
        type = "unknown",
        capabilities = {},
        performance = "unknown",
        platform = "unknown"
    },
    
    -- Performance monitoring
    performanceHistory = {},
    currentPerformance = {
        fps = 60,
        memory = 0,
        cpu = 0,
        stability = 0
    },
    
    -- Adaptive behavior
    lastAdjustment = 0,
    adjustmentHistory = {},
    emergencyMode = false,
    stabilityTimer = 0,
    
    -- Quality settings applied
    appliedSettings = {},
    
    -- Monitoring connections
    connections = {},
    
    -- Statistics
    stats = {
        adjustments = 0,
        emergencyAdjustments = 0,
        qualityUpgrades = 0,
        qualityDowngrades = 0,
        averagePerformance = 0
    }
}

function AdaptiveQualitySystem.initialize()
    print("🎛️ Initializing AdaptiveQualitySystem...")
    
    -- Detect device capabilities
    AdaptiveQualitySystem.detectDeviceCapabilities()
    
    -- Set initial quality preset
    AdaptiveQualitySystem.setInitialQualityPreset()
    
    -- Start performance monitoring
    AdaptiveQualitySystem.startPerformanceMonitoring()
    
    -- Set up adaptive adjustment system
    AdaptiveQualitySystem.setupAdaptiveSystem()
    
    print("🎛️ AdaptiveQualitySystem initialized successfully")
    print(string.format("📱 Device: %s, Initial Preset: %s", QualityState.deviceInfo.type, QualityState.currentPreset))
end

-- ========================================
-- DEVICE DETECTION
-- ========================================

function AdaptiveQualitySystem.detectDeviceCapabilities()
    local deviceInfo = QualityState.deviceInfo
    
    -- Detect platform
    if UserInputService.TouchEnabled then
        if UserInputService.AccelerometerEnabled then
            deviceInfo.platform = "Mobile"
        else
            deviceInfo.platform = "Tablet"
        end
    elseif UserInputService.GamepadEnabled then
        deviceInfo.platform = "Console"
    elseif UserInputService.KeyboardEnabled then
        deviceInfo.platform = "PC"
    else
        deviceInfo.platform = "Unknown"
    end
    
    -- Detect capabilities
    deviceInfo.capabilities = {
        touch = UserInputService.TouchEnabled,
        keyboard = UserInputService.KeyboardEnabled,
        mouse = UserInputService.MouseEnabled,
        gamepad = UserInputService.GamepadEnabled,
        accelerometer = UserInputService.AccelerometerEnabled,
        gyroscope = UserInputService.GyroscopeEnabled
    }
    
    -- Estimate device type based on capabilities and initial performance
    deviceInfo.type = AdaptiveQualitySystem.estimateDeviceType()
    
    print(string.format("📱 Device detected: %s (%s)", deviceInfo.type, deviceInfo.platform))
end

function AdaptiveQualitySystem.estimateDeviceType()
    local caps = QualityState.deviceInfo.capabilities
    local platform = QualityState.deviceInfo.platform
    
    -- High-end device indicators
    if platform == "PC" and caps.keyboard and caps.mouse then
        return "high_end"
    end
    
    -- Mid-range device indicators
    if platform == "Tablet" or (platform == "Mobile" and not caps.accelerometer) then
        return "mid_range"
    end
    
    -- Low-end device indicators
    if platform == "Mobile" or platform == "Console" then
        return "low_end"
    end
    
    return "mid_range" -- Default fallback
end

-- ========================================
-- QUALITY PRESET MANAGEMENT
-- ========================================

function AdaptiveQualitySystem.setInitialQualityPreset()
    local deviceType = QualityState.deviceInfo.type
    local presetMap = {
        high_end = "high",
        mid_range = "medium",
        low_end = "low"
    }
    
    local initialPreset = presetMap[deviceType] or "medium"
    AdaptiveQualitySystem.applyQualityPreset(initialPreset)
end

function AdaptiveQualitySystem.applyQualityPreset(presetName)
    local preset = QUALITY_CONFIG.qualityPresets[presetName]
    if not preset then
        warn("Unknown quality preset: " .. tostring(presetName))
        return false
    end
    
    QualityState.currentPreset = presetName
    
    -- Apply graphics settings
    AdaptiveQualitySystem.applyGraphicsSettings(preset)
    
    -- Apply lighting settings
    AdaptiveQualitySystem.applyLightingSettings(preset)
    
    -- Apply audio settings
    AdaptiveQualitySystem.applyAudioSettings(preset)
    
    -- Apply UI settings
    AdaptiveQualitySystem.applyUISettings(preset)
    
    -- Apply performance settings
    AdaptiveQualitySystem.applyPerformanceSettings(preset)
    
    -- Store applied settings
    QualityState.appliedSettings = preset
    
    print(string.format("🎛️ Applied quality preset: %s", preset.name))
    return true
end

function AdaptiveQualitySystem.applyGraphicsSettings(preset)
    -- Set render quality
    if settings():FindFirstChild("Rendering") then
        local rendering = settings().Rendering
        if rendering:FindFirstChild("QualityLevel") then
            rendering.QualityLevel = preset.graphics
        end
    end
    
    -- Apply texture quality
    AdaptiveQualitySystem.setTextureQuality(preset.textureQuality)
    
    -- Apply model LOD
    AdaptiveQualitySystem.setModelLOD(preset.modelLOD)
    
    -- Set render distance
    AdaptiveQualitySystem.setRenderDistance(preset.renderDistance)
end

function AdaptiveQualitySystem.applyLightingSettings(preset)
    -- Set lighting technology
    if preset.lighting == "Future" then
        Lighting.Technology = Enum.Technology.Future
    elseif preset.lighting == "ShadowMap" then
        Lighting.Technology = Enum.Technology.ShadowMap
    elseif preset.lighting == "Voxel" then
        Lighting.Technology = Enum.Technology.Voxel
    else
        Lighting.Technology = Enum.Technology.Compatibility
    end
    
    -- Configure shadows
    Lighting.GlobalShadows = preset.shadows
    
    -- Configure post-processing effects
    AdaptiveQualitySystem.configurePostProcessing(preset.postProcessing)
end

function AdaptiveQualitySystem.applyAudioSettings(preset)
    -- Set audio quality
    SoundService.RespectFilteringEnabled = preset.audioQuality > 0.8
    
    -- Adjust spatial audio
    AdaptiveQualitySystem.configureSpatialAudio(preset.audioQuality)
    
    -- Set audio compression
    AdaptiveQualitySystem.setAudioCompression(1.0 - preset.audioQuality)
end

function AdaptiveQualitySystem.applyUISettings(preset)
    -- Configure UI animations
    AdaptiveQualitySystem.setUIAnimations(preset.uiAnimations)
    
    -- Set particle count limits
    AdaptiveQualitySystem.setParticleCount(preset.particleCount)
end

function AdaptiveQualitySystem.applyPerformanceSettings(preset)
    -- Configure performance-related settings based on preset
    local performanceSettings = {
        cullingDistance = preset.renderDistance,
        updateFrequency = preset.graphics >= 6 and 60 or 30,
        enableOcclusion = preset.graphics >= 8,
        enableBatching = preset.graphics <= 6
    }
    
    -- Apply performance settings
    for setting, value in pairs(performanceSettings) do
        AdaptiveQualitySystem.applyPerformanceSetting(setting, value)
    end
end

-- ========================================
-- PERFORMANCE MONITORING
-- ========================================

function AdaptiveQualitySystem.startPerformanceMonitoring()
    local interval = QUALITY_CONFIG.adaptiveSettings.monitoringInterval
    
    QualityState.connections.monitor = task.spawn(function()
        while true do
            AdaptiveQualitySystem.collectPerformanceData()
            AdaptiveQualitySystem.evaluatePerformance()
            task.wait(interval)
        end
    end)
    
    -- Emergency performance monitoring (more frequent)
    QualityState.connections.emergency = RunService.Heartbeat:Connect(function(deltaTime)
        local fps = 1 / deltaTime
        if fps < QUALITY_CONFIG.adaptiveSettings.emergencyThreshold then
            AdaptiveQualitySystem.handleEmergencyPerformance(fps)
        end
    end)
    
    print("📊 Performance monitoring started")
end

function AdaptiveQualitySystem.collectPerformanceData()
    local fps = AdaptiveQualitySystem.getCurrentFPS()
    local memory = AdaptiveQualitySystem.getCurrentMemoryUsage()
    local cpu = AdaptiveQualitySystem.getCurrentCPUUsage()
    
    local performanceData = {
        timestamp = tick(),
        fps = fps,
        memory = memory,
        cpu = cpu,
        preset = QualityState.currentPreset
    }
    
    -- Store performance history
    table.insert(QualityState.performanceHistory, performanceData)
    
    -- Limit history size
    if #QualityState.performanceHistory > 60 then -- Keep last 5 minutes (5s intervals)
        table.remove(QualityState.performanceHistory, 1)
    end
    
    -- Update current performance
    QualityState.currentPerformance = {
        fps = fps,
        memory = memory,
        cpu = cpu,
        stability = AdaptiveQualitySystem.calculateStability()
    }
end

function AdaptiveQualitySystem.evaluatePerformance()
    local perf = QualityState.currentPerformance
    local thresholds = QUALITY_CONFIG.performanceThresholds
    
    -- Determine performance level
    local performanceLevel = "poor"
    for level, threshold in pairs(thresholds) do
        if perf.fps >= threshold.minFPS and 
           perf.memory <= threshold.maxMemory and 
           perf.cpu <= threshold.maxCPU then
            performanceLevel = level
            break
        end
    end
    
    -- Check if adjustment is needed
    local shouldAdjust = AdaptiveQualitySystem.shouldAdjustQuality(performanceLevel)
    
    if shouldAdjust then
        AdaptiveQualitySystem.adjustQualityBasedOnPerformance(performanceLevel)
    end
    
    -- Update stability tracking
    AdaptiveQualitySystem.updateStabilityTracking(performanceLevel)
end

function AdaptiveQualitySystem.shouldAdjustQuality(performanceLevel)
    local currentTime = tick()
    local timeSinceLastAdjustment = currentTime - QualityState.lastAdjustment
    local cooldown = QUALITY_CONFIG.adaptiveSettings.adjustmentCooldown
    
    -- Check cooldown
    if timeSinceLastAdjustment < cooldown then
        return false
    end
    
    -- Check if quality change is warranted
    local currentPresetLevel = AdaptiveQualitySystem.getPresetLevel(QualityState.currentPreset)
    local targetPresetLevel = AdaptiveQualitySystem.getTargetPresetLevel(performanceLevel)
    
    return currentPresetLevel ~= targetPresetLevel
end

function AdaptiveQualitySystem.adjustQualityBasedOnPerformance(performanceLevel)
    local targetPreset = AdaptiveQualitySystem.getTargetPreset(performanceLevel)
    
    if targetPreset ~= QualityState.currentPreset then
        local wasUpgrade = AdaptiveQualitySystem.isQualityUpgrade(QualityState.currentPreset, targetPreset)
        
        -- Apply new preset
        AdaptiveQualitySystem.applyQualityPreset(targetPreset)
        
        -- Record adjustment
        AdaptiveQualitySystem.recordQualityAdjustment(targetPreset, performanceLevel, wasUpgrade)
        
        -- Update statistics
        QualityState.stats.adjustments = QualityState.stats.adjustments + 1
        if wasUpgrade then
            QualityState.stats.qualityUpgrades = QualityState.stats.qualityUpgrades + 1
        else
            QualityState.stats.qualityDowngrades = QualityState.stats.qualityDowngrades + 1
        end
        
        QualityState.lastAdjustment = tick()
        
        print(string.format("🎛️ Quality %s: %s → %s (Performance: %s)", 
            wasUpgrade and "upgraded" or "downgraded", 
            QualityState.currentPreset, targetPreset, performanceLevel))
    end
end

function AdaptiveQualitySystem.handleEmergencyPerformance(fps)
    if QualityState.emergencyMode then
        return -- Already in emergency mode
    end
    
    QualityState.emergencyMode = true
    
    -- Immediately apply minimal quality
    AdaptiveQualitySystem.applyQualityPreset("minimal")
    
    -- Record emergency adjustment
    QualityState.stats.emergencyAdjustments = QualityState.stats.emergencyAdjustments + 1
    
    warn(string.format("🚨 Emergency quality reduction: FPS %.1f below threshold", fps))
    
    -- Reset emergency mode after delay
    task.delay(30, function()
        QualityState.emergencyMode = false
    end)
end

-- ========================================
-- ADAPTIVE SYSTEM LOGIC
-- ========================================

function AdaptiveQualitySystem.setupAdaptiveSystem()
    -- Set up quality adjustment logic
    AdaptiveQualitySystem.initializeAdaptiveParameters()
    
    -- Start stability monitoring
    AdaptiveQualitySystem.startStabilityMonitoring()
    
    print("🔄 Adaptive quality system active")
end

function AdaptiveQualitySystem.initializeAdaptiveParameters()
    QualityState.lastAdjustment = tick()
    QualityState.adjustmentHistory = {}
    QualityState.emergencyMode = false
    QualityState.stabilityTimer = 0
end

function AdaptiveQualitySystem.startStabilityMonitoring()
    QualityState.connections.stability = task.spawn(function()
        while true do
            AdaptiveQualitySystem.checkForQualityUpgrade()
            task.wait(5) -- Check every 5 seconds
        end
    end)
end

function AdaptiveQualitySystem.checkForQualityUpgrade()
    if QualityState.emergencyMode then
        return -- Don't upgrade during emergency mode
    end
    
    local perf = QualityState.currentPerformance
    local recoveryThreshold = QUALITY_CONFIG.adaptiveSettings.recoveryThreshold
    local stabilityRequirement = QUALITY_CONFIG.adaptiveSettings.stabilityRequirement
    
    -- Check if performance is stable and good enough for upgrade
    if perf.fps >= recoveryThreshold and perf.stability >= stabilityRequirement then
        local nextPreset = AdaptiveQualitySystem.getNextHigherPreset(QualityState.currentPreset)
        if nextPreset then
            AdaptiveQualitySystem.applyQualityPreset(nextPreset)
            print(string.format("⬆️ Quality upgraded to %s (stable performance)", nextPreset))
        end
    end
end

function AdaptiveQualitySystem.calculateStability()
    if #QualityState.performanceHistory < 5 then
        return 0
    end
    
    -- Calculate FPS variance over recent history
    local recentSamples = {}
    for i = #QualityState.performanceHistory - 4, #QualityState.performanceHistory do
        table.insert(recentSamples, QualityState.performanceHistory[i].fps)
    end
    
    local mean = 0
    for _, fps in ipairs(recentSamples) do
        mean = mean + fps
    end
    mean = mean / #recentSamples
    
    local variance = 0
    for _, fps in ipairs(recentSamples) do
        variance = variance + (fps - mean)^2
    end
    variance = variance / #recentSamples
    
    -- Convert variance to stability score (lower variance = higher stability)
    local stability = math.max(0, 100 - variance)
    return stability
end

function AdaptiveQualitySystem.updateStabilityTracking(performanceLevel)
    -- Update stability timer based on performance consistency
    if performanceLevel == "excellent" or performanceLevel == "good" then
        QualityState.stabilityTimer = QualityState.stabilityTimer + QUALITY_CONFIG.adaptiveSettings.monitoringInterval
    else
        QualityState.stabilityTimer = 0 -- Reset if performance drops
    end
end

-- ========================================
-- UTILITY FUNCTIONS
-- ========================================

function AdaptiveQualitySystem.getPresetLevel(presetName)
    local levels = {"minimal", "low", "medium", "high", "ultra"}
    for i, level in ipairs(levels) do
        if level == presetName then
            return i
        end
    end
    return 3 -- Default to medium
end

function AdaptiveQualitySystem.getTargetPresetLevel(performanceLevel)
    local mapping = {
        excellent = 5, -- ultra
        good = 4,      -- high
        fair = 3,      -- medium
        poor = 2       -- low
    }
    return mapping[performanceLevel] or 3
end

function AdaptiveQualitySystem.getTargetPreset(performanceLevel)
    local presets = {"minimal", "low", "medium", "high", "ultra"}
    local level = AdaptiveQualitySystem.getTargetPresetLevel(performanceLevel)
    return presets[level] or "medium"
end

function AdaptiveQualitySystem.isQualityUpgrade(currentPreset, targetPreset)
    local currentLevel = AdaptiveQualitySystem.getPresetLevel(currentPreset)
    local targetLevel = AdaptiveQualitySystem.getPresetLevel(targetPreset)
    return targetLevel > currentLevel
end

function AdaptiveQualitySystem.getNextHigherPreset(currentPreset)
    local presets = {"minimal", "low", "medium", "high", "ultra"}
    local currentLevel = AdaptiveQualitySystem.getPresetLevel(currentPreset)
    if currentLevel < #presets then
        return presets[currentLevel + 1]
    end
    return nil -- Already at highest quality
end

function AdaptiveQualitySystem.recordQualityAdjustment(newPreset, performanceLevel, wasUpgrade)
    local adjustment = {
        timestamp = tick(),
        fromPreset = QualityState.currentPreset,
        toPreset = newPreset,
        performanceLevel = performanceLevel,
        wasUpgrade = wasUpgrade,
        performance = QualityState.currentPerformance
    }
    
    table.insert(QualityState.adjustmentHistory, adjustment)
    
    -- Limit history
    if #QualityState.adjustmentHistory > 50 then
        table.remove(QualityState.adjustmentHistory, 1)
    end
end

-- ========================================
-- PERFORMANCE MEASUREMENT FUNCTIONS
-- ========================================

function AdaptiveQualitySystem.getCurrentFPS()
    -- Use RunService to calculate FPS
    local fps = 1 / RunService.Heartbeat:Wait()
    return math.floor(fps + 0.5)
end

function AdaptiveQualitySystem.getCurrentMemoryUsage()
    -- Get memory usage in MB
    return collectgarbage("count") / 1024
end

function AdaptiveQualitySystem.getCurrentCPUUsage()
    -- Estimate CPU usage (placeholder implementation)
    return math.random(20, 80)
end

-- ========================================
-- SETTING APPLICATION FUNCTIONS
-- ========================================

function AdaptiveQualitySystem.setTextureQuality(quality)
    -- Apply texture quality scaling
    -- This would typically involve texture compression and resolution scaling
end

function AdaptiveQualitySystem.setModelLOD(lodLevel)
    -- Apply model Level of Detail scaling
    -- This would typically involve mesh simplification
end

function AdaptiveQualitySystem.setRenderDistance(distance)
    -- Set maximum render distance
    Workspace.StreamingEnabled = distance < 800
    if Workspace.StreamingEnabled then
        Workspace.StreamingMinRadius = distance * 0.5
        Workspace.StreamingTargetRadius = distance
    end
end

function AdaptiveQualitySystem.configurePostProcessing(enabled)
    -- Configure post-processing effects
    for _, effect in ipairs(Lighting:GetChildren()) do
        if effect:IsA("PostEffect") then
            effect.Enabled = enabled
        end
    end
end

function AdaptiveQualitySystem.configureSpatialAudio(quality)
    -- Configure spatial audio quality
    -- This would typically involve adjusting audio processing complexity
end

function AdaptiveQualitySystem.setAudioCompression(compressionLevel)
    -- Set audio compression level
    -- This would typically involve audio quality reduction
end

function AdaptiveQualitySystem.setUIAnimations(enabled)
    -- Enable or disable UI animations for performance
    -- This would typically involve tweening system configuration
end

function AdaptiveQualitySystem.setParticleCount(maxCount)
    -- Set maximum particle count for effects
    -- This would typically involve particle system limitations
end

function AdaptiveQualitySystem.applyPerformanceSetting(setting, value)
    -- Apply specific performance setting
    -- Placeholder for various performance optimizations
end

-- ========================================
-- PUBLIC API
-- ========================================

function AdaptiveQualitySystem.getDeviceInfo()
    return QualityState.deviceInfo
end

function AdaptiveQualitySystem.getCurrentPreset()
    return QualityState.currentPreset
end

function AdaptiveQualitySystem.getPerformanceHistory()
    return QualityState.performanceHistory
end

function AdaptiveQualitySystem.getAdjustmentHistory()
    return QualityState.adjustmentHistory
end

function AdaptiveQualitySystem.getStatistics()
    return QualityState.stats
end

function AdaptiveQualitySystem.forceQualityPreset(presetName)
    return AdaptiveQualitySystem.applyQualityPreset(presetName)
end

function AdaptiveQualitySystem.enableAdaptiveMode()
    AdaptiveQualitySystem.setupAdaptiveSystem()
end

function AdaptiveQualitySystem.disableAdaptiveMode()
    for _, connection in pairs(QualityState.connections) do
        if typeof(connection) == "thread" then
            task.cancel(connection)
        elseif typeof(connection) == "RBXScriptConnection" then
            connection:Disconnect()
        end
    end
    QualityState.connections = {}
end

-- Initialize the adaptive quality system
AdaptiveQualitySystem.initialize()

print("🎛️ AdaptiveQualitySystem loaded with device-aware quality management")

return AdaptiveQualitySystem
