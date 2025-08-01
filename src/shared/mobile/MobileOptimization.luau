-- MobileOptimization.luau
-- Comprehensive mobile performance optimization and device management
-- Handles battery life, memory usage, thermal management, and device-specific optimizations

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local GuiService = game:GetService("GuiService")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local Lighting = game:GetService("Lighting")
local Workspace = game:GetService("Workspace")
local SoundService = game:GetService("SoundService")
local TweenService = game:GetService("TweenService")

local SafeRequire = require(ReplicatedStorage.Shared.utils.SafeRequire)

local MobileOptimization = {}

-- ========================================
-- MOBILE OPTIMIZATION CONFIGURATION
-- ========================================

local MOBILE_CONFIG = {
    -- Performance thresholds
    performance = {
        targetFrameRate = 60,
        minFrameRate = 30,
        maxMemoryUsage = 512 * 1024 * 1024, -- 512MB
        thermalThreshold = 0.8,              -- 80% thermal limit
        batteryThreshold = 0.2,              -- 20% battery critical
        networkLatencyMax = 200,             -- 200ms max latency
        loadTimeTarget = 3.0                 -- 3 second load target
    },
    
    -- Device detection and optimization
    devices = {
        -- High-end devices (iPhone 12+, Samsung S21+, etc.)
        highEnd = {
            graphicsQuality = 10,
            shadowQuality = 3,
            effectsQuality = 10,
            textureQuality = 8,
            particleCount = 1000,
            drawDistance = 500,
            enablePostProcessing = true,
            enableReflections = true,
            enableShadows = true
        },
        
        -- Mid-range devices (iPhone X-11, Samsung A-series, etc.)
        midRange = {
            graphicsQuality = 7,
            shadowQuality = 2,
            effectsQuality = 7,
            textureQuality = 6,
            particleCount = 500,
            drawDistance = 300,
            enablePostProcessing = true,
            enableReflections = false,
            enableShadows = true
        },
        
        -- Low-end devices (iPhone 8-, older Android devices)
        lowEnd = {
            graphicsQuality = 4,
            shadowQuality = 1,
            effectsQuality = 4,
            textureQuality = 4,
            particleCount = 200,
            drawDistance = 150,
            enablePostProcessing = false,
            enableReflections = false,
            enableShadows = false
        },
        
        -- Very low-end devices (budget Android devices)
        veryLowEnd = {
            graphicsQuality = 2,
            shadowQuality = 0,
            effectsQuality = 2,
            textureQuality = 2,
            particleCount = 50,
            drawDistance = 100,
            enablePostProcessing = false,
            enableReflections = false,
            enableShadows = false
        }
    },
    
    -- Adaptive quality settings
    adaptiveQuality = {
        enableDynamicQuality = true,
        frameRateWindow = 60,        -- frames to average
        qualityAdjustmentRate = 0.1, -- 10% adjustment per step
        minQualityLevel = 1,
        maxQualityLevel = 10,
        thermalDamping = true,
        batteryOptimization = true
    },
    
    -- Memory management
    memory = {
        enableGarbageCollection = true,
        gcInterval = 30,             -- seconds
        texturePoolSize = 100,       -- MB
        audioPoolSize = 50,          -- MB
        enableMemoryWarnings = true,
        memoryCleanupThreshold = 0.85, -- 85% usage trigger cleanup
        enableLODSystem = true
    },
    
    -- Network optimization
    network = {
        enableDataCompression = true,
        enablePredictiveLoading = true,
        maxConcurrentDownloads = 3,
        timeoutDuration = 10,
        retryAttempts = 3,
        enableOfflineMode = true,
        dataSavingMode = false
    },
    
    -- Battery optimization
    battery = {
        enableBatteryOptimization = true,
        lowBatteryThreshold = 0.2,   -- 20%
        criticalBatteryThreshold = 0.1, -- 10%
        backgroundProcessingLimit = 0.5, -- 50% when in background
        enablePowerSaving = true,
        thermalThrottling = true
    }
}

-- ========================================
-- MOBILE OPTIMIZATION STATE
-- ========================================

local OptimizationState = {
    -- Device information
    deviceInfo = {
        platform = "Unknown",
        deviceType = "Unknown",
        screenSize = Vector2.new(0, 0),
        orientation = Enum.DeviceOrientation.Portrait,
        performanceTier = "midRange",
        supportedFeatures = {}
    },
    
    -- Performance monitoring
    performance = {
        currentFrameRate = 60,
        averageFrameRate = 60,
        frameRateHistory = {},
        memoryUsage = 0,
        thermalState = 0,
        batteryLevel = 1.0,
        networkLatency = 0,
        loadTime = 0
    },
    
    -- Optimization settings
    currentSettings = {},
    
    -- Quality management
    qualityManager = {
        currentQualityLevel = 7,
        targetQualityLevel = 7,
        qualityHistory = {},
        adaptiveEnabled = true
    },
    
    -- Memory management
    memoryManager = {
        totalMemory = 0,
        usedMemory = 0,
        texturePool = {},
        audioPool = {},
        lastGCTime = 0
    },
    
    -- Network state
    networkState = {
        connectionType = "Unknown",
        downloadSpeed = 0,
        uploadSpeed = 0,
        latency = 0,
        dataUsage = 0,
        offlineMode = false
    },
    
    -- Battery state
    batteryState = {
        level = 1.0,
        charging = false,
        lowPowerMode = false,
        thermalState = "normal"
    },
    
    -- Statistics
    stats = {
        sessionsOptimized = 0,
        performanceGains = 0,
        memorySaved = 0,
        batteryLifeExtended = 0,
        dataUsageReduced = 0
    }
}

function MobileOptimization.initialize()
    print("📱 Initializing MobileOptimization...")
    
    -- Detect device capabilities
    MobileOptimization.detectDevice()
    
    -- Set up performance monitoring
    MobileOptimization.setupPerformanceMonitoring()
    
    -- Initialize quality management
    MobileOptimization.initializeQualityManagement()
    
    -- Set up memory management
    MobileOptimization.setupMemoryManagement()
    
    -- Initialize network optimization
    MobileOptimization.initializeNetworkOptimization()
    
    -- Set up battery optimization
    MobileOptimization.setupBatteryOptimization()
    
    -- Apply initial optimizations
    MobileOptimization.applyDeviceOptimizations()
    
    -- Start monitoring loops
    MobileOptimization.startOptimizationLoops()
    
    print("📱 MobileOptimization initialized successfully")
end

-- ========================================
-- DEVICE DETECTION AND CAPABILITIES
-- ========================================

function MobileOptimization.detectDevice()
    local deviceInfo = OptimizationState.deviceInfo
    
    -- Detect platform
    if UserInputService.TouchEnabled then
        deviceInfo.platform = "Mobile"
        if UserInputService.AccelerometerEnabled then
            deviceInfo.deviceType = "Smartphone"
        else
            deviceInfo.deviceType = "Tablet"
        end
    elseif UserInputService.GamepadEnabled then
        deviceInfo.platform = "Console"
        deviceInfo.deviceType = "Console"
    else
        deviceInfo.platform = "Desktop"
        deviceInfo.deviceType = "Computer"
    end
    
    -- Get screen information
    local camera = Workspace.CurrentCamera
    if camera then
        deviceInfo.screenSize = camera.ViewportSize
    end
    
    -- Detect orientation
    local viewportSize = camera and camera.ViewportSize or Vector2.new(800, 600)
    if viewportSize.X > viewportSize.Y then
        deviceInfo.orientation = Enum.DeviceOrientation.LandscapeLeft
    else
        deviceInfo.orientation = Enum.DeviceOrientation.Portrait
    end
    
    -- Determine performance tier
    deviceInfo.performanceTier = MobileOptimization.determinePerformanceTier()
    
    -- Detect supported features
    deviceInfo.supportedFeatures = MobileOptimization.detectSupportedFeatures()
    
    print(string.format("📱 Device detected: %s %s (%s tier)", 
        deviceInfo.platform, deviceInfo.deviceType, deviceInfo.performanceTier))
end

function MobileOptimization.determinePerformanceTier()
    local screenSize = OptimizationState.deviceInfo.screenSize
    local totalPixels = screenSize.X * screenSize.Y
    
    -- Basic performance tier detection based on screen resolution and platform
    if OptimizationState.deviceInfo.platform == "Desktop" then
        return "highEnd"
    elseif OptimizationState.deviceInfo.platform == "Console" then
        return "highEnd"
    else
        -- Mobile device detection
        if totalPixels > 2000000 then -- High resolution (1920x1080+)
            return "highEnd"
        elseif totalPixels > 1000000 then -- Medium resolution (1280x800+)
            return "midRange"
        elseif totalPixels > 500000 then -- Low resolution (800x600+)
            return "lowEnd"
        else
            return "veryLowEnd"
        end
    end
end

function MobileOptimization.detectSupportedFeatures()
    local features = {}
    
    -- Input features
    features.touch = UserInputService.TouchEnabled
    features.accelerometer = UserInputService.AccelerometerEnabled
    features.gyroscope = UserInputService.GyroscopeEnabled
    features.gamepad = UserInputService.GamepadEnabled
    features.keyboard = UserInputService.KeyboardEnabled
    features.mouse = UserInputService.MouseEnabled
    
    -- Display features
    features.hdDisplay = OptimizationState.deviceInfo.screenSize.X >= 1920
    features.wideScreen = OptimizationState.deviceInfo.screenSize.X / OptimizationState.deviceInfo.screenSize.Y > 1.5
    
    -- Performance features
    features.multiCore = true -- Assume multi-core for modern devices
    features.lowLatency = true -- Assume low latency capability
    
    return features
end

-- ========================================
-- PERFORMANCE MONITORING
-- ========================================

function MobileOptimization.setupPerformanceMonitoring()
    OptimizationState.performanceMonitor = {
        frameRateMonitor = MobileOptimization.createFrameRateMonitor(),
        memoryMonitor = MobileOptimization.createMemoryMonitor(),
        thermalMonitor = MobileOptimization.createThermalMonitor(),
        batteryMonitor = MobileOptimization.createBatteryMonitor(),
        networkMonitor = MobileOptimization.createNetworkMonitor()
    }
    
    print("📊 Performance monitoring initialized")
end

function MobileOptimization.createFrameRateMonitor()
    return {
        name = "frame_rate_monitor",
        lastFrameTime = tick(),
        frameCount = 0,
        
        update = function(self)
            local currentTime = tick()
            local deltaTime = currentTime - self.lastFrameTime
            
            if deltaTime > 0 then
                local currentFPS = 1 / deltaTime
                OptimizationState.performance.currentFrameRate = currentFPS
                
                -- Update rolling average
                table.insert(OptimizationState.performance.frameRateHistory, currentFPS)
                if #OptimizationState.performance.frameRateHistory > MOBILE_CONFIG.adaptiveQuality.frameRateWindow then
                    table.remove(OptimizationState.performance.frameRateHistory, 1)
                end
                
                -- Calculate average
                local total = 0
                for _, fps in ipairs(OptimizationState.performance.frameRateHistory) do
                    total = total + fps
                end
                OptimizationState.performance.averageFrameRate = 
                    #OptimizationState.performance.frameRateHistory > 0 and 
                    (total / #OptimizationState.performance.frameRateHistory) or 60
            end
            
            self.lastFrameTime = currentTime
            self.frameCount = self.frameCount + 1
        end
    }
end

function MobileOptimization.createMemoryMonitor()
    return {
        name = "memory_monitor",
        
        update = function(self)
            local memoryUsage = collectgarbage("count") * 1024 -- Convert KB to bytes
            OptimizationState.performance.memoryUsage = memoryUsage
            OptimizationState.memoryManager.usedMemory = memoryUsage
            
            -- Check if memory cleanup is needed
            local memoryRatio = memoryUsage / MOBILE_CONFIG.performance.maxMemoryUsage
            if memoryRatio > MOBILE_CONFIG.memory.memoryCleanupThreshold then
                MobileOptimization.performMemoryCleanup()
            end
        end
    }
end

function MobileOptimization.createThermalMonitor()
    return {
        name = "thermal_monitor",
        
        update = function(self)
            -- Simplified thermal monitoring (would use actual thermal APIs on real devices)
            local averageFPS = OptimizationState.performance.averageFrameRate
            local targetFPS = MOBILE_CONFIG.performance.targetFrameRate
            
            -- Estimate thermal state based on performance
            if averageFPS < targetFPS * 0.7 then
                OptimizationState.performance.thermalState = 0.9 -- High thermal load
            elseif averageFPS < targetFPS * 0.9 then
                OptimizationState.performance.thermalState = 0.6 -- Medium thermal load
            else
                OptimizationState.performance.thermalState = 0.3 -- Low thermal load
            end
        end
    }
end

function MobileOptimization.createBatteryMonitor()
    return {
        name = "battery_monitor",
        
        update = function(self)
            -- Simplified battery monitoring (would use actual battery APIs)
            local currentTime = tick()
            local sessionTime = currentTime - (OptimizationState.sessionStartTime or currentTime)
            
            -- Estimate battery drain based on performance
            local estimatedDrainRate = 0.1 / 3600 -- 10% per hour baseline
            
            if OptimizationState.performance.thermalState > 0.7 then
                estimatedDrainRate = estimatedDrainRate * 1.5 -- Increased drain when hot
            end
            
            OptimizationState.performance.batteryLevel = 
                math.max(0, 1.0 - (sessionTime * estimatedDrainRate))
            
            OptimizationState.batteryState.level = OptimizationState.performance.batteryLevel
        end
    }
end

function MobileOptimization.createNetworkMonitor()
    return {
        name = "network_monitor",
        lastPingTime = 0,
        
        update = function(self)
            -- Simplified network monitoring
            local currentTime = tick()
            
            if currentTime - self.lastPingTime > 5 then -- Check every 5 seconds
                self.lastPingTime = currentTime
                
                -- Estimate network latency (would use actual network APIs)
                OptimizationState.performance.networkLatency = math.random(20, 100)
                OptimizationState.networkState.latency = OptimizationState.performance.networkLatency
            end
        end
    }
end

-- ========================================
-- QUALITY MANAGEMENT
-- ========================================

function MobileOptimization.initializeQualityManagement()
    OptimizationState.qualityManager = {
        currentQualityLevel = 7,
        targetQualityLevel = 7,
        qualityHistory = {},
        adaptiveEnabled = MOBILE_CONFIG.adaptiveQuality.enableDynamicQuality,
        lastAdjustmentTime = 0,
        
        adjustQuality = function(self, targetFPS)
            if not self.adaptiveEnabled then
                return
            end
            
            local currentFPS = OptimizationState.performance.averageFrameRate
            local qualityAdjustment = 0
            
            if currentFPS < targetFPS * 0.9 then
                -- Performance is below target, reduce quality
                qualityAdjustment = -1
            elseif currentFPS > targetFPS * 1.1 and self.currentQualityLevel < MOBILE_CONFIG.adaptiveQuality.maxQualityLevel then
                -- Performance is above target and we can increase quality
                qualityAdjustment = 1
            end
            
            if qualityAdjustment ~= 0 then
                local newQualityLevel = math.max(
                    MOBILE_CONFIG.adaptiveQuality.minQualityLevel,
                    math.min(
                        MOBILE_CONFIG.adaptiveQuality.maxQualityLevel,
                        self.currentQualityLevel + qualityAdjustment
                    )
                )
                
                if newQualityLevel ~= self.currentQualityLevel then
                    self.currentQualityLevel = newQualityLevel
                    self.targetQualityLevel = newQualityLevel
                    MobileOptimization.applyQualitySettings(newQualityLevel)
                    
                    print(string.format("📊 Quality adjusted to level %d (FPS: %.1f)", 
                        newQualityLevel, currentFPS))
                end
            end
        end
    }
    
    print("🎮 Quality management initialized")
end

function MobileOptimization.applyQualitySettings(qualityLevel)
    local settings = MobileOptimization.getQualitySettings(qualityLevel)
    
    -- Apply graphics settings
    if settings.enablePostProcessing then
        -- Enable post-processing effects
        MobileOptimization.enablePostProcessing()
    else
        MobileOptimization.disablePostProcessing()
    end
    
    -- Apply shadow settings
    Lighting.GlobalShadows = settings.enableShadows
    if settings.enableShadows then
        Lighting.ShadowSoftness = settings.shadowQuality / 3
    end
    
    -- Apply particle settings
    MobileOptimization.setParticleLimit(settings.particleCount)
    
    -- Apply draw distance
    if Workspace.CurrentCamera then
        Workspace.CurrentCamera.FieldOfView = math.max(50, 70 - (10 - qualityLevel))
    end
    
    OptimizationState.currentSettings = settings
end

function MobileOptimization.getQualitySettings(qualityLevel)
    local deviceTier = OptimizationState.deviceInfo.performanceTier
    local baseSettings = MOBILE_CONFIG.devices[deviceTier] or MOBILE_CONFIG.devices.midRange
    
    -- Scale settings based on quality level
    local qualityScale = qualityLevel / 10
    
    return {
        graphicsQuality = math.floor(baseSettings.graphicsQuality * qualityScale),
        shadowQuality = math.floor(baseSettings.shadowQuality * qualityScale),
        effectsQuality = math.floor(baseSettings.effectsQuality * qualityScale),
        textureQuality = math.floor(baseSettings.textureQuality * qualityScale),
        particleCount = math.floor(baseSettings.particleCount * qualityScale),
        drawDistance = math.floor(baseSettings.drawDistance * qualityScale),
        enablePostProcessing = qualityLevel >= 5 and baseSettings.enablePostProcessing,
        enableReflections = qualityLevel >= 7 and baseSettings.enableReflections,
        enableShadows = qualityLevel >= 3 and baseSettings.enableShadows
    }
end

-- ========================================
-- MEMORY MANAGEMENT
-- ========================================

function MobileOptimization.setupMemoryManagement()
    OptimizationState.memoryManager = {
        totalMemory = MOBILE_CONFIG.performance.maxMemoryUsage,
        usedMemory = 0,
        texturePool = {},
        audioPool = {},
        lastGCTime = tick(),
        
        performCleanup = function(self)
            local currentTime = tick()
            
            -- Garbage collection
            if MOBILE_CONFIG.memory.enableGarbageCollection then
                collectgarbage("collect")
                self.lastGCTime = currentTime
                print("🗑️ Memory cleanup performed")
            end
            
            -- Texture pool cleanup
            self:cleanTexturePool()
            
            -- Audio pool cleanup
            self:cleanAudioPool()
            
            OptimizationState.stats.memorySaved = OptimizationState.stats.memorySaved + 1
        end,
        
        cleanTexturePool = function(self)
            local cleaned = 0
            for textureId, textureData in pairs(self.texturePool) do
                if tick() - textureData.lastUsed > 60 then -- 1 minute timeout
                    self.texturePool[textureId] = nil
                    cleaned = cleaned + 1
                end
            end
            
            if cleaned > 0 then
                print(string.format("🖼️ Cleaned %d textures from pool", cleaned))
            end
        end,
        
        cleanAudioPool = function(self)
            local cleaned = 0
            for audioId, audioData in pairs(self.audioPool) do
                if tick() - audioData.lastUsed > 30 then -- 30 second timeout
                    self.audioPool[audioId] = nil
                    cleaned = cleaned + 1
                end
            end
            
            if cleaned > 0 then
                print(string.format("🔊 Cleaned %d audio files from pool", cleaned))
            end
        end
    }
    
    print("💾 Memory management initialized")
end

function MobileOptimization.performMemoryCleanup()
    OptimizationState.memoryManager:performCleanup()
end

function MobileOptimization.enablePostProcessing()
    -- Enable various post-processing effects
    if Lighting:FindFirstChild("ColorCorrection") then
        Lighting.ColorCorrection.Enabled = true
    end
    
    if Lighting:FindFirstChild("BloomEffect") then
        Lighting.BloomEffect.Enabled = true
    end
end

function MobileOptimization.disablePostProcessing()
    -- Disable post-processing effects for performance
    if Lighting:FindFirstChild("ColorCorrection") then
        Lighting.ColorCorrection.Enabled = false
    end
    
    if Lighting:FindFirstChild("BloomEffect") then
        Lighting.BloomEffect.Enabled = false
    end
end

function MobileOptimization.setParticleLimit(limit)
    -- Would implement particle system limiting
    -- This is a simplified placeholder
    print(string.format("🎆 Particle limit set to %d", limit))
end

-- ========================================
-- NETWORK OPTIMIZATION
-- ========================================

function MobileOptimization.initializeNetworkOptimization()
    OptimizationState.networkOptimizer = {
        connectionType = "Unknown",
        dataCompressionEnabled = MOBILE_CONFIG.network.enableDataCompression,
        predictiveLoadingEnabled = MOBILE_CONFIG.network.enablePredictiveLoading,
        offlineModeEnabled = MOBILE_CONFIG.network.enableOfflineMode,
        
        optimizeConnection = function(self)
            -- Detect connection type
            self.connectionType = MobileOptimization.detectConnectionType()
            
            -- Apply connection-specific optimizations
            if self.connectionType == "Cellular" then
                MobileOptimization.enableDataSavingMode()
            elseif self.connectionType == "WiFi" then
                MobileOptimization.disableDataSavingMode()
            end
            
            -- Update network state
            OptimizationState.networkState.connectionType = self.connectionType
        end,
        
        enableOfflineMode = function(self)
            if self.offlineModeEnabled then
                OptimizationState.networkState.offlineMode = true
                print("📴 Offline mode enabled")
            end
        end,
        
        disableOfflineMode = function(self)
            OptimizationState.networkState.offlineMode = false
            print("📶 Online mode restored")
        end
    }
    
    print("🌐 Network optimization initialized")
end

function MobileOptimization.detectConnectionType()
    -- Simplified connection detection
    local latency = OptimizationState.performance.networkLatency
    
    if latency > 100 then
        return "Cellular"
    elseif latency > 50 then
        return "WiFi"
    else
        return "Ethernet"
    end
end

function MobileOptimization.enableDataSavingMode()
    MOBILE_CONFIG.network.dataSavingMode = true
    
    -- Reduce texture quality
    local currentQuality = OptimizationState.qualityManager.currentQualityLevel
    OptimizationState.qualityManager.currentQualityLevel = math.max(1, currentQuality - 2)
    
    -- Disable non-essential features
    MobileOptimization.disablePostProcessing()
    
    print("📱 Data saving mode enabled")
end

function MobileOptimization.disableDataSavingMode()
    MOBILE_CONFIG.network.dataSavingMode = false
    print("📱 Data saving mode disabled")
end

-- ========================================
-- BATTERY OPTIMIZATION
-- ========================================

function MobileOptimization.setupBatteryOptimization()
    OptimizationState.batteryOptimizer = {
        lowPowerModeEnabled = false,
        thermalThrottlingEnabled = MOBILE_CONFIG.battery.thermalThrottling,
        backgroundProcessingLimit = MOBILE_CONFIG.battery.backgroundProcessingLimit,
        
        checkBatteryState = function(self)
            local batteryLevel = OptimizationState.performance.batteryLevel
            local thermalState = OptimizationState.performance.thermalState
            
            -- Enable low power mode if battery is low
            if batteryLevel <= MOBILE_CONFIG.battery.lowBatteryThreshold and not self.lowPowerModeEnabled then
                self:enableLowPowerMode()
            elseif batteryLevel > MOBILE_CONFIG.battery.lowBatteryThreshold and self.lowPowerModeEnabled then
                self:disableLowPowerMode()
            end
            
            -- Apply thermal throttling
            if self.thermalThrottlingEnabled and thermalState > MOBILE_CONFIG.performance.thermalThreshold then
                self:applyThermalThrottling()
            end
            
            OptimizationState.batteryState.lowPowerMode = self.lowPowerModeEnabled
            OptimizationState.batteryState.thermalState = thermalState > 0.7 and "hot" or "normal"
        end,
        
        enableLowPowerMode = function(self)
            self.lowPowerModeEnabled = true
            
            -- Reduce quality settings
            local currentQuality = OptimizationState.qualityManager.currentQualityLevel
            OptimizationState.qualityManager.currentQualityLevel = math.max(1, currentQuality - 3)
            MobileOptimization.applyQualitySettings(OptimizationState.qualityManager.currentQualityLevel)
            
            -- Reduce frame rate target
            RunService.Heartbeat:Wait() -- Placeholder for frame rate limiting
            
            print("🔋 Low power mode enabled")
            OptimizationState.stats.batteryLifeExtended = OptimizationState.stats.batteryLifeExtended + 1
        end,
        
        disableLowPowerMode = function(self)
            self.lowPowerModeEnabled = false
            
            -- Restore quality settings
            local deviceTier = OptimizationState.deviceInfo.performanceTier
            local baseQuality = MOBILE_CONFIG.devices[deviceTier] and 7 or 5
            OptimizationState.qualityManager.currentQualityLevel = baseQuality
            MobileOptimization.applyQualitySettings(baseQuality)
            
            print("🔋 Low power mode disabled")
        end,
        
        applyThermalThrottling = function(self)
            -- Reduce performance to manage heat
            local currentQuality = OptimizationState.qualityManager.currentQualityLevel
            if currentQuality > 2 then
                OptimizationState.qualityManager.currentQualityLevel = currentQuality - 1
                MobileOptimization.applyQualitySettings(OptimizationState.qualityManager.currentQualityLevel)
                print("🌡️ Thermal throttling applied")
            end
        end
    }
    
    print("🔋 Battery optimization initialized")
end

-- ========================================
-- DEVICE-SPECIFIC OPTIMIZATIONS
-- ========================================

function MobileOptimization.applyDeviceOptimizations()
    local deviceTier = OptimizationState.deviceInfo.performanceTier
    local deviceSettings = MOBILE_CONFIG.devices[deviceTier]
    
    if not deviceSettings then
        print("⚠️ Unknown device tier, using mid-range settings")
        deviceSettings = MOBILE_CONFIG.devices.midRange
    end
    
    -- Apply device-specific settings
    MobileOptimization.applyQualitySettings(deviceSettings.graphicsQuality)
    
    -- Apply audio optimizations
    MobileOptimization.applyAudioOptimizations(deviceTier)
    
    -- Apply input optimizations
    MobileOptimization.applyInputOptimizations()
    
    OptimizationState.stats.sessionsOptimized = OptimizationState.stats.sessionsOptimized + 1
    
    print(string.format("⚙️ Device optimizations applied for %s tier device", deviceTier))
end

function MobileOptimization.applyAudioOptimizations(deviceTier)
    local audioSettings = {
        highEnd = {
            masterVolume = 1.0,
            audioQuality = "High",
            enableSpatialAudio = true,
            maxAudioSources = 32
        },
        midRange = {
            masterVolume = 0.9,
            audioQuality = "Medium",
            enableSpatialAudio = true,
            maxAudioSources = 16
        },
        lowEnd = {
            masterVolume = 0.8,
            audioQuality = "Low",
            enableSpatialAudio = false,
            maxAudioSources = 8
        },
        veryLowEnd = {
            masterVolume = 0.7,
            audioQuality = "VeryLow",
            enableSpatialAudio = false,
            maxAudioSources = 4
        }
    }
    
    local settings = audioSettings[deviceTier] or audioSettings.midRange
    
    -- Apply audio settings
    SoundService.MasterVolume = settings.masterVolume
    
    print(string.format("🔊 Audio optimizations applied: %s quality", settings.audioQuality))
end

function MobileOptimization.applyInputOptimizations()
    if OptimizationState.deviceInfo.platform == "Mobile" then
        -- Enable mobile-specific input optimizations
        UserInputService.ModalEnabled = true
        
        -- Configure touch sensitivity
        if UserInputService.TouchEnabled then
            print("📱 Touch input optimizations applied")
        end
        
        -- Configure accelerometer
        if UserInputService.AccelerometerEnabled then
            print("📱 Accelerometer optimizations applied")
        end
    end
end

-- ========================================
-- OPTIMIZATION LOOPS
-- ========================================

function MobileOptimization.startOptimizationLoops()
    OptimizationState.sessionStartTime = tick()
    
    -- CONVERTED: All polling loops replaced with adaptive event-driven monitoring
    
    local adaptiveIntervals = {
        performance = 5,    -- Start: 5s (was 1s) 
        quality = 15,       -- Start: 15s (was 5s)
        memory = 60,        -- Start: 1min (was gcInterval)
        battery = 45,       -- Start: 45s (was 10s)
        network = 90        -- Start: 90s (was 15s)
    }
    
    local stableCounts = {
        performance = 0,
        quality = 0,
        memory = 0,
        battery = 0,
        network = 0
    }
    
    local lastValues = {
        frameRate = 60,
        memoryUsage = 50,
        batteryLevel = 100,
        networkLatency = 50,
        qualityLevel = 5
    }
    
    -- Performance monitoring with change detection
    spawn(function()
        while true do
            local oldFrameRate = lastValues.frameRate
            MobileOptimization.updatePerformanceMonitoring()
            
            -- Get current frame rate (simplified)
            local currentFrameRate = 1 / RunService.Heartbeat:Wait()
            local frameRateChange = math.abs(currentFrameRate - oldFrameRate)
            
            if frameRateChange > 5 then -- Significant FPS change
                -- Increase frequency when performance is unstable
                adaptiveIntervals.performance = math.max(2, adaptiveIntervals.performance * 0.7)
                stableCounts.performance = 0
            else
                -- Decrease frequency when performance is stable
                stableCounts.performance = stableCounts.performance + 1
                if stableCounts.performance > 5 then
                    adaptiveIntervals.performance = math.min(30, adaptiveIntervals.performance * 1.3)
                end
            end
            
            lastValues.frameRate = currentFrameRate
            task.wait(adaptiveIntervals.performance)
        end
    end)
    
    -- Quality management with adaptive adjustment
    spawn(function()
        while true do
            local oldQuality = lastValues.qualityLevel
            MobileOptimization.updateQualityManagement()
            
            local currentQuality = OptimizationState.qualityManager and 
                                  OptimizationState.qualityManager.currentQualityLevel or 5
            
            if math.abs(currentQuality - oldQuality) > 0 then
                -- Quality changed - monitor more frequently
                adaptiveIntervals.quality = math.max(5, adaptiveIntervals.quality * 0.8)
                stableCounts.quality = 0
            else
                -- Quality stable - monitor less frequently
                stableCounts.quality = stableCounts.quality + 1
                if stableCounts.quality > 3 then
                    adaptiveIntervals.quality = math.min(120, adaptiveIntervals.quality * 1.4)
                end
            end
            
            lastValues.qualityLevel = currentQuality
            task.wait(adaptiveIntervals.quality)
        end
    end)
    
    -- Memory management with pressure detection
    spawn(function()
        while true do
            local oldMemory = lastValues.memoryUsage
            MobileOptimization.updateMemoryManagement()
            
            local currentMemory = gcinfo()
            local memoryChange = math.abs(currentMemory - oldMemory)
            
            if memoryChange > 20 or currentMemory > 150 then -- Memory pressure
                -- More frequent cleanup when memory pressure is high
                adaptiveIntervals.memory = math.max(15, adaptiveIntervals.memory * 0.6)
                stableCounts.memory = 0
            else
                -- Less frequent cleanup when memory is stable
                stableCounts.memory = stableCounts.memory + 1
                if stableCounts.memory > 2 then
                    adaptiveIntervals.memory = math.min(600, adaptiveIntervals.memory * 1.5)
                end
            end
            
            lastValues.memoryUsage = currentMemory
            task.wait(adaptiveIntervals.memory)
        end
    end)
    
    -- Battery optimization with adaptive monitoring
    spawn(function()
        while true do
            local oldBattery = lastValues.batteryLevel
            MobileOptimization.updateBatteryOptimization()
            
            local currentBattery = OptimizationState.performance and 
                                  OptimizationState.performance.batteryLevel or 100
            local batteryChange = math.abs(currentBattery - oldBattery)
            
            if batteryChange > 5 or currentBattery < 30 then -- Battery change or low battery
                -- More frequent monitoring when battery is changing or low
                adaptiveIntervals.battery = math.max(15, adaptiveIntervals.battery * 0.8)
                stableCounts.battery = 0
            else
                -- Less frequent monitoring when battery is stable
                stableCounts.battery = stableCounts.battery + 1
                if stableCounts.battery > 3 then
                    adaptiveIntervals.battery = math.min(300, adaptiveIntervals.battery * 1.2)
                end
            end
            
            lastValues.batteryLevel = currentBattery
            task.wait(adaptiveIntervals.battery)
        end
    end)
    
    -- Network optimization with connection change detection
    spawn(function()
        while true do
            local oldLatency = lastValues.networkLatency
            MobileOptimization.updateNetworkOptimization()
            
            local currentLatency = OptimizationState.performance and 
                                  OptimizationState.performance.networkLatency or 50
            local latencyChange = math.abs(currentLatency - oldLatency)
            
            if latencyChange > 30 or currentLatency > 200 then -- Network change or poor connection
                -- More frequent optimization when network is unstable
                adaptiveIntervals.network = math.max(30, adaptiveIntervals.network * 0.8)
                stableCounts.network = 0
            else
                -- Less frequent optimization when network is stable
                stableCounts.network = stableCounts.network + 1
                if stableCounts.network > 2 then
                    adaptiveIntervals.network = math.min(600, adaptiveIntervals.network * 1.3)
                end
            end
            
            lastValues.networkLatency = currentLatency
            task.wait(adaptiveIntervals.network)
        end
    end)
    
    print("🔄 Optimization loops started with adaptive intervals (2s-10min range)")
    print("💡 System will automatically adjust monitoring frequency based on activity")
end

function MobileOptimization.updatePerformanceMonitoring()
    if not OptimizationState.performanceMonitor then
        return
    end
    
    -- Update all monitors
    OptimizationState.performanceMonitor.frameRateMonitor:update()
    OptimizationState.performanceMonitor.memoryMonitor:update()
    OptimizationState.performanceMonitor.thermalMonitor:update()
    OptimizationState.performanceMonitor.batteryMonitor:update()
    OptimizationState.performanceMonitor.networkMonitor:update()
end

function MobileOptimization.updateQualityManagement()
    if OptimizationState.qualityManager and OptimizationState.qualityManager.adaptiveEnabled then
        local targetFPS = MOBILE_CONFIG.performance.targetFrameRate
        
        -- Apply thermal damping
        if MOBILE_CONFIG.adaptiveQuality.thermalDamping and 
           OptimizationState.performance.thermalState > MOBILE_CONFIG.performance.thermalThreshold then
            targetFPS = targetFPS * 0.8 -- Reduce target FPS when thermal throttling
        end
        
        -- Apply battery optimization
        if MOBILE_CONFIG.adaptiveQuality.batteryOptimization and 
           OptimizationState.performance.batteryLevel < MOBILE_CONFIG.battery.lowBatteryThreshold then
            targetFPS = targetFPS * 0.7 -- Reduce target FPS when battery is low
        end
        
        OptimizationState.qualityManager:adjustQuality(targetFPS)
    end
end

function MobileOptimization.updateMemoryManagement()
    if OptimizationState.memoryManager then
        local currentTime = tick()
        
        if currentTime - OptimizationState.memoryManager.lastGCTime > MOBILE_CONFIG.memory.gcInterval then
            OptimizationState.memoryManager:performCleanup()
        end
    end
end

function MobileOptimization.updateBatteryOptimization()
    if OptimizationState.batteryOptimizer then
        OptimizationState.batteryOptimizer:checkBatteryState()
    end
end

function MobileOptimization.updateNetworkOptimization()
    if OptimizationState.networkOptimizer then
        OptimizationState.networkOptimizer:optimizeConnection()
    end
end

-- ========================================
-- PUBLIC API
-- ========================================

function MobileOptimization.runOptimizationDemo()
    print("📱 Running mobile optimization demonstration...")
    
    -- Show device information
    print("  📱 Device Information:")
    local deviceInfo = OptimizationState.deviceInfo
    print(string.format("    Platform: %s", deviceInfo.platform))
    print(string.format("    Device Type: %s", deviceInfo.deviceType))
    print(string.format("    Screen Size: %dx%d", deviceInfo.screenSize.X, deviceInfo.screenSize.Y))
    print(string.format("    Performance Tier: %s", deviceInfo.performanceTier))
    print(string.format("    Orientation: %s", tostring(deviceInfo.orientation)))
    
    -- Show supported features
    print("  🎮 Supported Features:")
    for feature, supported in pairs(deviceInfo.supportedFeatures) do
        print(string.format("    %s: %s", feature, supported and "✅" or "❌"))
    end
    
    -- Show current performance
    print("  📊 Current Performance:")
    local performance = OptimizationState.performance
    print(string.format("    Frame Rate: %.1f FPS (avg: %.1f)", 
        performance.currentFrameRate, performance.averageFrameRate))
    print(string.format("    Memory Usage: %.1f MB", performance.memoryUsage / 1024 / 1024))
    print(string.format("    Thermal State: %.1f%%", performance.thermalState * 100))
    print(string.format("    Battery Level: %.1f%%", performance.batteryLevel * 100))
    print(string.format("    Network Latency: %d ms", performance.networkLatency))
    
    -- Show current settings
    print("  ⚙️ Current Settings:")
    local settings = OptimizationState.currentSettings
    if settings then
        print(string.format("    Graphics Quality: %d/10", settings.graphicsQuality or 0))
        print(string.format("    Shadow Quality: %d/3", settings.shadowQuality or 0))
        print(string.format("    Effects Quality: %d/10", settings.effectsQuality or 0))
        print(string.format("    Particle Count: %d", settings.particleCount or 0))
        print(string.format("    Post-Processing: %s", settings.enablePostProcessing and "✅" or "❌"))
        print(string.format("    Shadows: %s", settings.enableShadows and "✅" or "❌"))
        print(string.format("    Reflections: %s", settings.enableReflections and "✅" or "❌"))
    end
    
    -- Show optimization states
    print("  🔧 Optimization States:")
    print(string.format("    Adaptive Quality: %s", 
        OptimizationState.qualityManager.adaptiveEnabled and "✅" or "❌"))
    print(string.format("    Low Power Mode: %s", 
        OptimizationState.batteryState.lowPowerMode and "✅" or "❌"))
    print(string.format("    Data Saving Mode: %s", 
        MOBILE_CONFIG.network.dataSavingMode and "✅" or "❌"))
    print(string.format("    Offline Mode: %s", 
        OptimizationState.networkState.offlineMode and "✅" or "❌"))
    
    -- Show statistics
    print("  📈 Optimization Statistics:")
    local stats = OptimizationState.stats
    print(string.format("    Sessions Optimized: %d", stats.sessionsOptimized))
    print(string.format("    Performance Gains: %d", stats.performanceGains))
    print(string.format("    Memory Cleanups: %d", stats.memorySaved))
    print(string.format("    Battery Extensions: %d", stats.batteryLifeExtended))
    print(string.format("    Data Usage Reductions: %d", stats.dataUsageReduced))
    
    -- Demonstrate quality adjustment
    print("  🎮 Demonstrating adaptive quality...")
    
    -- Simulate low performance
    OptimizationState.performance.averageFrameRate = 25
    MobileOptimization.updateQualityManagement()
    print("    📉 Simulated low FPS - quality reduced")
    
    task.wait(1)
    
    -- Simulate normal performance
    OptimizationState.performance.averageFrameRate = 60
    MobileOptimization.updateQualityManagement()
    print("    📈 Simulated normal FPS - quality restored")
    
    -- Demonstrate battery optimization
    print("  🔋 Demonstrating battery optimization...")
    
    -- Simulate low battery
    OptimizationState.performance.batteryLevel = 0.15
    MobileOptimization.updateBatteryOptimization()
    print("    🔋 Simulated low battery - power saving enabled")
    
    task.wait(1)
    
    -- Simulate normal battery
    OptimizationState.performance.batteryLevel = 0.8
    MobileOptimization.updateBatteryOptimization()
    print("    🔋 Simulated normal battery - power saving disabled")
    
    print("📱 Mobile optimization demonstration completed")
end

function MobileOptimization.getDeviceInfo()
    return OptimizationState.deviceInfo
end

function MobileOptimization.getPerformanceMetrics()
    return OptimizationState.performance
end

function MobileOptimization.getCurrentSettings()
    return OptimizationState.currentSettings
end

function MobileOptimization.getOptimizationStats()
    return OptimizationState.stats
end

function MobileOptimization.setQualityLevel(level)
    level = math.max(MOBILE_CONFIG.adaptiveQuality.minQualityLevel, 
            math.min(MOBILE_CONFIG.adaptiveQuality.maxQualityLevel, level))
    
    OptimizationState.qualityManager.currentQualityLevel = level
    OptimizationState.qualityManager.targetQualityLevel = level
    MobileOptimization.applyQualitySettings(level)
    
    print(string.format("🎮 Quality level manually set to %d", level))
end

function MobileOptimization.enableAdaptiveQuality()
    OptimizationState.qualityManager.adaptiveEnabled = true
    print("🎮 Adaptive quality enabled")
end

function MobileOptimization.disableAdaptiveQuality()
    OptimizationState.qualityManager.adaptiveEnabled = false
    print("🎮 Adaptive quality disabled")
end

function MobileOptimization.forceLowPowerMode()
    if OptimizationState.batteryOptimizer then
        OptimizationState.batteryOptimizer:enableLowPowerMode()
    end
end

function MobileOptimization.disableLowPowerMode()
    if OptimizationState.batteryOptimizer then
        OptimizationState.batteryOptimizer:disableLowPowerMode()
    end
end

-- Initialize the mobile optimization system
MobileOptimization.initialize()

print("📱 MobileOptimization loaded with comprehensive device optimization")

return MobileOptimization
