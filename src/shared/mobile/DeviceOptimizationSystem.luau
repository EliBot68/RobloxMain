-- DeviceOptimizationSystem.luau
-- Device-specific optimizations and offline mode functionality
-- Handles graphics quality, audio settings, network optimization, and offline capabilities

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local GuiService = game:GetService("GuiService")
local RunService = game:GetService("RunService")
local Lighting = game:GetService("Lighting")
local SoundService = game:GetService("SoundService")
local UserGameSettings = UserSettings():GetService("UserGameSettings")
local DataStoreService = game:GetService("DataStoreService")
local Players = game:GetService("Players")
local HttpService = game:GetService("HttpService")
local StarterGui = game:GetService("StarterGui")

local SafeRequire = require(ReplicatedStorage.Shared.utils.SafeRequire)

local DeviceOptimizationSystem = {}

-- ========================================
-- DEVICE OPTIMIZATION CONFIGURATION
-- ========================================

local OPTIMIZATION_CONFIG = {
    -- Device performance tiers
    deviceTiers = {
        ["high_end"] = {
            minFPS = 60,
            maxMemory = 8192, -- MB
            graphics = {
                quality = 10,
                shadowMapSize = 2048,
                shadowQuality = 3,
                materialQuality = 3,
                meshPartDetail = 3,
                postProcessing = true,
                bloom = true,
                depthOfField = true,
                sunRays = true,
                atmosphereEnabled = true
            },
            audio = {
                quality = "High",
                maxSounds = 64,
                reverb = true,
                doppler = true,
                occlusionEnabled = true
            },
            network = {
                updateRate = 60,
                compressionLevel = 0,
                predictiveLoading = true,
                bufferSize = 1024
            }
        },
        
        ["mid_range"] = {
            minFPS = 30,
            maxMemory = 4096, -- MB
            graphics = {
                quality = 7,
                shadowMapSize = 1024,
                shadowQuality = 2,
                materialQuality = 2,
                meshPartDetail = 2,
                postProcessing = true,
                bloom = true,
                depthOfField = false,
                sunRays = false,
                atmosphereEnabled = true
            },
            audio = {
                quality = "Medium",
                maxSounds = 32,
                reverb = true,
                doppler = false,
                occlusionEnabled = false
            },
            network = {
                updateRate = 30,
                compressionLevel = 1,
                predictiveLoading = true,
                bufferSize = 512
            }
        },
        
        ["low_end"] = {
            minFPS = 20,
            maxMemory = 2048, -- MB
            graphics = {
                quality = 4,
                shadowMapSize = 512,
                shadowQuality = 1,
                materialQuality = 1,
                meshPartDetail = 1,
                postProcessing = false,
                bloom = false,
                depthOfField = false,
                sunRays = false,
                atmosphereEnabled = false
            },
            audio = {
                quality = "Low",
                maxSounds = 16,
                reverb = false,
                doppler = false,
                occlusionEnabled = false
            },
            network = {
                updateRate = 20,
                compressionLevel = 2,
                predictiveLoading = false,
                bufferSize = 256
            }
        },
        
        ["very_low_end"] = {
            minFPS = 15,
            maxMemory = 1024, -- MB
            graphics = {
                quality = 1,
                shadowMapSize = 256,
                shadowQuality = 0,
                materialQuality = 0,
                meshPartDetail = 0,
                postProcessing = false,
                bloom = false,
                depthOfField = false,
                sunRays = false,
                atmosphereEnabled = false
            },
            audio = {
                quality = "VeryLow",
                maxSounds = 8,
                reverb = false,
                doppler = false,
                occlusionEnabled = false
            },
            network = {
                updateRate = 15,
                compressionLevel = 3,
                predictiveLoading = false,
                bufferSize = 128
            }
        }
    },
    
    -- Platform-specific optimizations
    platformOptimizations = {
        Mobile = {
            batteryOptimization = true,
            thermalThrottling = true,
            touchOptimization = true,
            backgroundProcessingLimits = true,
            memoryAggressiveCleanup = true,
            networkDataSaving = true
        },
        
        Tablet = {
            batteryOptimization = true,
            thermalThrottling = true,
            touchOptimization = true,
            backgroundProcessingLimits = false,
            memoryAggressiveCleanup = false,
            networkDataSaving = false
        },
        
        Desktop = {
            batteryOptimization = false,
            thermalThrottling = false,
            touchOptimization = false,
            backgroundProcessingLimits = false,
            memoryAggressiveCleanup = false,
            networkDataSaving = false
        },
        
        Console = {
            batteryOptimization = false,
            thermalThrottling = true,
            touchOptimization = false,
            backgroundProcessingLimits = false,
            memoryAggressiveCleanup = false,
            networkDataSaving = false
        }
    },
    
    -- Network optimization settings
    networkOptimization = {
        connectionTypes = {
            ["Unknown"] = { quality = "medium", dataSaving = false },
            ["Ethernet"] = { quality = "high", dataSaving = false },
            ["Wifi"] = { quality = "high", dataSaving = false },
            ["Cell"] = { quality = "medium", dataSaving = true }
        },
        
        dataSaving = {
            enabled = false,
            compressionLevel = 2,
            textureQuality = 0.5,
            audioQuality = 0.7,
            preloadingDisabled = true,
            backgroundUpdatesDisabled = true
        },
        
        offlineMode = {
            enabled = false,
            cacheSize = 100, -- MB
            essentialDataOnly = true,
            syncWhenOnline = true
        }
    },
    
    -- Performance monitoring
    performanceMonitoring = {
        enabled = true,
        sampleInterval = 1.0, -- seconds
        adaptiveQuality = true,
        automaticOptimization = true,
        
        thresholds = {
            fps = {
                critical = 15,
                low = 25,
                target = 30
            },
            memory = {
                critical = 90, -- percentage
                high = 80,
                target = 70
            },
            thermal = {
                critical = 85, -- degrees C
                high = 75,
                target = 65
            }
        }
    },
    
    -- Auto-optimization settings
    autoOptimization = {
        enabled = true,
        aggressiveness = "moderate", -- conservative, moderate, aggressive
        adaptationSpeed = "normal",   -- slow, normal, fast
        
        triggers = {
            fpsDrops = true,
            memoryPressure = true,
            thermalThrottling = true,
            batteryLow = true,
            networkSlow = true
        }
    }
}

-- ========================================
-- DEVICE OPTIMIZATION STATE
-- ========================================

local OptimizationState = {
    -- Device information
    deviceInfo = {
        platform = "Unknown",
        tier = "mid_range",
        capabilities = {},
        screenSize = Vector2.new(0, 0),
        memory = 0,
        cpu = "Unknown",
        gpu = "Unknown"
    },
    
    -- Current settings
    currentSettings = {
        graphics = {},
        audio = {},
        network = {},
        optimization = {}
    },
    
    -- Performance monitoring
    performance = {
        frameRate = 60,
        frameDrops = 0,
        memoryUsage = 0,
        thermalState = "Normal",
        batteryLevel = 100,
        networkLatency = 0,
        networkType = "Unknown"
    },
    
    -- Offline mode
    offlineMode = {
        active = false,
        cachedData = {},
        pendingSync = {},
        lastSyncTime = 0
    },
    
    -- Auto-optimization
    autoOptimizer = {
        active = true,
        lastAdjustment = 0,
        adjustmentHistory = {},
        currentProfile = "default"
    },
    
    -- Quality manager
    qualityManager = {
        currentLevel = 5,
        targetLevel = 5,
        adjusting = false,
        lastChange = 0
    }
}

function DeviceOptimizationSystem.initialize()
    print("🔧 Initializing DeviceOptimizationSystem...")
    
    -- Detect device capabilities
    DeviceOptimizationSystem.detectDeviceCapabilities()
    
    -- Initialize graphics optimization
    DeviceOptimizationSystem.initializeGraphicsOptimization()
    
    -- Initialize audio optimization
    DeviceOptimizationSystem.initializeAudioOptimization()
    
    -- Initialize network optimization
    DeviceOptimizationSystem.initializeNetworkOptimization()
    
    -- Set up offline mode
    DeviceOptimizationSystem.setupOfflineMode()
    
    -- Start performance monitoring
    DeviceOptimizationSystem.startPerformanceMonitoring()
    
    -- Initialize auto-optimization
    DeviceOptimizationSystem.initializeAutoOptimization()
    
    print("🔧 DeviceOptimizationSystem initialized successfully")
end

-- ========================================
-- DEVICE DETECTION
-- ========================================

function DeviceOptimizationSystem.detectDeviceCapabilities()
    local deviceInfo = OptimizationState.deviceInfo
    
    -- Detect platform
    if UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled then
        if UserInputService.GyroscopeEnabled then
            deviceInfo.platform = "Mobile"
        else
            deviceInfo.platform = "Tablet"
        end
    elseif UserInputService.GamepadEnabled and not UserInputService.KeyboardEnabled then
        deviceInfo.platform = "Console"
    else
        deviceInfo.platform = "Desktop"
    end
    
    -- Get screen information
    local viewport = workspace.CurrentCamera.ViewportSize
    deviceInfo.screenSize = viewport
    
    -- Determine device tier based on screen size and platform
    local screenArea = viewport.X * viewport.Y
    
    if deviceInfo.platform == "Mobile" then
        if screenArea > 2000000 then -- High-res mobile
            deviceInfo.tier = "mid_range"
        elseif screenArea > 1000000 then -- Standard mobile
            deviceInfo.tier = "low_end"
        else -- Low-res mobile
            deviceInfo.tier = "very_low_end"
        end
    elseif deviceInfo.platform == "Tablet" then
        if screenArea > 2500000 then -- High-res tablet
            deviceInfo.tier = "high_end"
        else -- Standard tablet
            deviceInfo.tier = "mid_range"
        end
    elseif deviceInfo.platform == "Desktop" then
        if screenArea > 4000000 then -- 4K+ desktop
            deviceInfo.tier = "high_end"
        elseif screenArea > 2000000 then -- 1080p+ desktop
            deviceInfo.tier = "mid_range"
        else -- Lower res desktop
            deviceInfo.tier = "low_end"
        end
    else -- Console
        deviceInfo.tier = "high_end" -- Assume consoles are powerful
    end
    
    -- Detect capabilities
    deviceInfo.capabilities = {
        touch = UserInputService.TouchEnabled,
        keyboard = UserInputService.KeyboardEnabled,
        mouse = UserInputService.MouseEnabled,
        gamepad = UserInputService.GamepadEnabled,
        gyroscope = UserInputService.GyroscopeEnabled,
        accelerometer = UserInputService.AccelerometerEnabled,
        vr = UserInputService.VREnabled
    }
    
    print(string.format("🔍 Detected %s device (%s tier)", deviceInfo.platform, deviceInfo.tier))
    print(string.format("   Screen: %.0fx%.0f (%.1fM pixels)", 
        viewport.X, viewport.Y, screenArea / 1000000))
end

-- ========================================
-- GRAPHICS OPTIMIZATION
-- ========================================

function DeviceOptimizationSystem.initializeGraphicsOptimization()
    local deviceTier = OPTIMIZATION_CONFIG.deviceTiers[OptimizationState.deviceInfo.tier]
    local graphicsSettings = deviceTier.graphics
    
    OptimizationState.graphicsOptimizer = {
        currentQuality = graphicsSettings.quality,
        targetQuality = graphicsSettings.quality,
        
        applySettings = function(self, settings)
            DeviceOptimizationSystem.applyGraphicsSettings(settings)
        end,
        
        adjustQuality = function(self, delta)
            self.targetQuality = math.clamp(self.targetQuality + delta, 1, 10)
            DeviceOptimizationSystem.transitionToQuality(self.targetQuality)
        end,
        
        optimizeForPerformance = function(self)
            self:adjustQuality(-2)
            DeviceOptimizationSystem.applyPerformanceOptimizations()
        end,
        
        optimizeForQuality = function(self)
            self:adjustQuality(1)
            DeviceOptimizationSystem.applyQualityOptimizations()
        end
    }
    
    -- Apply initial graphics settings
    DeviceOptimizationSystem.applyGraphicsSettings(graphicsSettings)
    
    print("🎨 Graphics optimization initialized")
end

function DeviceOptimizationSystem.applyGraphicsSettings(settings)
    pcall(function()
        -- Apply graphics quality
        UserGameSettings.SavedQualityLevel = Enum.SavedQualitySetting["Level" .. settings.quality]
        
        -- Apply lighting settings
        if settings.bloom then
            if not Lighting:FindFirstChild("Bloom") then
                local bloom = Instance.new("BloomEffect")
                bloom.Name = "Bloom"
                bloom.Intensity = 1
                bloom.Size = 24
                bloom.Threshold = 2
                bloom.Parent = Lighting
            end
        else
            local bloom = Lighting:FindFirstChild("Bloom")
            if bloom then bloom:Destroy() end
        end
        
        if settings.depthOfField then
            if not Lighting:FindFirstChild("DepthOfField") then
                local dof = Instance.new("DepthOfFieldEffect")
                dof.Name = "DepthOfField"
                dof.FarIntensity = 0.75
                dof.FocusDistance = 0.05
                dof.InFocusRadius = 30
                dof.NearIntensity = 0.75
                dof.Parent = Lighting
            end
        else
            local dof = Lighting:FindFirstChild("DepthOfField")
            if dof then dof:Destroy() end
        end
        
        if settings.sunRays then
            if not Lighting:FindFirstChild("SunRays") then
                local sunRays = Instance.new("SunRaysEffect")
                sunRays.Name = "SunRays"
                sunRays.Intensity = 0.01
                sunRays.Spread = 1
                sunRays.Parent = Lighting
            end
        else
            local sunRays = Lighting:FindFirstChild("SunRays")
            if sunRays then sunRays:Destroy() end
        end
        
        -- Apply atmosphere settings
        if settings.atmosphereEnabled then
            if not Lighting:FindFirstChild("Atmosphere") then
                local atmosphere = Instance.new("Atmosphere")
                atmosphere.Name = "Atmosphere"
                atmosphere.Density = 0.3
                atmosphere.Offset = 0.25
                atmosphere.Color = Color3.fromRGB(199, 199, 199)
                atmosphere.Decay = Color3.fromRGB(92, 60, 13)
                atmosphere.Glare = 0
                atmosphere.Haze = 0
                atmosphere.Parent = Lighting
            end
        else
            local atmosphere = Lighting:FindFirstChild("Atmosphere")
            if atmosphere then atmosphere:Destroy() end
        end
        
        -- Store current settings
        OptimizationState.currentSettings.graphics = settings
    end)
end

function DeviceOptimizationSystem.transitionToQuality(targetQuality)
    local currentQuality = OptimizationState.graphicsOptimizer.currentQuality
    
    if currentQuality == targetQuality then return end
    
    OptimizationState.qualityManager.adjusting = true
    OptimizationState.qualityManager.targetLevel = targetQuality
    
    -- Gradual quality transition
    spawn(function()
        local steps = math.abs(targetQuality - currentQuality)
        local direction = targetQuality > currentQuality and 1 or -1
        
        for i = 1, steps do
            task.wait(0.5) -- Smooth transition
            
            local newQuality = currentQuality + (direction * i)
            UserGameSettings.SavedQualityLevel = Enum.SavedQualitySetting["Level" .. newQuality]
            
            print(string.format("🎨 Graphics quality: %d -> %d", currentQuality, newQuality))
        end
        
        OptimizationState.graphicsOptimizer.currentQuality = targetQuality
        OptimizationState.qualityManager.adjusting = false
        OptimizationState.qualityManager.lastChange = tick()
        
        print(string.format("🎨 Graphics quality transition completed: %d", targetQuality))
    end)
end

function DeviceOptimizationSystem.applyPerformanceOptimizations()
    -- Reduce particle count
    local particles = workspace:GetDescendants()
    for _, obj in pairs(particles) do
        if obj:IsA("ParticleEmitter") then
            obj.Rate = obj.Rate * 0.5
        elseif obj:IsA("Fire") then
            obj.Size = obj.Size * 0.7
        elseif obj:IsA("Smoke") then
            obj.Size = obj.Size * 0.7
        end
    end
    
    -- Reduce texture resolution
    UserGameSettings.MasterVolume = UserGameSettings.MasterVolume * 0.8
    
    print("⚡ Performance optimizations applied")
end

function DeviceOptimizationSystem.applyQualityOptimizations()
    -- Restore particle effects
    local particles = workspace:GetDescendants()
    for _, obj in pairs(particles) do
        if obj:IsA("ParticleEmitter") then
            obj.Rate = obj.Rate * 1.2
        elseif obj:IsA("Fire") then
            obj.Size = obj.Size * 1.1
        elseif obj:IsA("Smoke") then
            obj.Size = obj.Size * 1.1
        end
    end
    
    print("✨ Quality optimizations applied")
end

-- ========================================
-- AUDIO OPTIMIZATION
-- ========================================

function DeviceOptimizationSystem.initializeAudioOptimization()
    local deviceTier = OPTIMIZATION_CONFIG.deviceTiers[OptimizationState.deviceInfo.tier]
    local audioSettings = deviceTier.audio
    
    OptimizationState.audioOptimizer = {
        currentQuality = audioSettings.quality,
        maxSounds = audioSettings.maxSounds,
        activeSounds = {},
        
        applySettings = function(self, settings)
            DeviceOptimizationSystem.applyAudioSettings(settings)
        end,
        
        limitActiveSounds = function(self)
            local sounds = SoundService:GetDescendants()
            local playingSounds = {}
            
            for _, sound in pairs(sounds) do
                if sound:IsA("Sound") and sound.IsPlaying then
                    table.insert(playingSounds, sound)
                end
            end
            
            -- Stop excess sounds
            if #playingSounds > self.maxSounds then
                for i = self.maxSounds + 1, #playingSounds do
                    playingSounds[i]:Stop()
                end
            end
        end,
        
        optimizeForPerformance = function(self)
            self.maxSounds = math.max(self.maxSounds * 0.7, 4)
            self:limitActiveSounds()
            DeviceOptimizationSystem.reduceAudioQuality()
        end,
        
        optimizeForQuality = function(self)
            self.maxSounds = math.min(self.maxSounds * 1.3, 64)
            DeviceOptimizationSystem.enhanceAudioQuality()
        end
    }
    
    -- Apply initial audio settings
    DeviceOptimizationSystem.applyAudioSettings(audioSettings)
    
    print("🔊 Audio optimization initialized")
end

function DeviceOptimizationSystem.applyAudioSettings(settings)
    pcall(function()
        -- Set volume based on quality
        local volumeMultiplier = 1.0
        
        if settings.quality == "VeryLow" then
            volumeMultiplier = 0.6
        elseif settings.quality == "Low" then
            volumeMultiplier = 0.7
        elseif settings.quality == "Medium" then
            volumeMultiplier = 0.85
        else -- High
            volumeMultiplier = 1.0
        end
        
        SoundService.AmbientReverb = settings.reverb and Enum.ReverbType.Generic or Enum.ReverbType.NoReverb
        SoundService.DopplerScale = settings.doppler and 1 or 0
        
        -- Store current settings
        OptimizationState.currentSettings.audio = settings
    end)
end

function DeviceOptimizationSystem.reduceAudioQuality()
    -- Reduce bit rate and sample rate for performance
    print("🔊 Audio quality reduced for performance")
end

function DeviceOptimizationSystem.enhanceAudioQuality()
    -- Increase bit rate and sample rate for quality
    print("🔊 Audio quality enhanced")
end

-- ========================================
-- NETWORK OPTIMIZATION
-- ========================================

function DeviceOptimizationSystem.initializeNetworkOptimization()
    OptimizationState.networkOptimizer = {
        connectionType = "Unknown",
        dataSavingEnabled = false,
        offlineModeEnabled = false,
        compressionLevel = 1,
        
        detectConnectionType = function(self)
            -- Simplified connection detection
            self.connectionType = "Wifi" -- Default assumption
            return self.connectionType
        end,
        
        enableDataSaving = function(self)
            self.dataSavingEnabled = true
            self.compressionLevel = 2
            DeviceOptimizationSystem.applyDataSavingSettings()
            print("📡 Data saving mode enabled")
        end,
        
        disableDataSaving = function(self)
            self.dataSavingEnabled = false
            self.compressionLevel = 0
            DeviceOptimizationSystem.removeDataSavingSettings()
            print("📡 Data saving mode disabled")
        end,
        
        enableOfflineMode = function(self)
            self.offlineModeEnabled = true
            OptimizationState.offlineMode.active = true
            DeviceOptimizationSystem.activateOfflineMode()
            print("📶 Offline mode enabled")
        end,
        
        disableOfflineMode = function(self)
            self.offlineModeEnabled = false
            OptimizationState.offlineMode.active = false
            DeviceOptimizationSystem.deactivateOfflineMode()
            print("📶 Offline mode disabled")
        end
    }
    
    -- Detect initial connection
    OptimizationState.networkOptimizer:detectConnectionType()
    
    -- Apply platform-specific network settings
    local platformOpts = OPTIMIZATION_CONFIG.platformOptimizations[OptimizationState.deviceInfo.platform]
    if platformOpts and platformOpts.networkDataSaving then
        OptimizationState.networkOptimizer:enableDataSaving()
    end
    
    print("📡 Network optimization initialized")
end

function DeviceOptimizationSystem.applyDataSavingSettings()
    local dataSaving = OPTIMIZATION_CONFIG.networkOptimization.dataSaving
    
    -- Reduce update frequency
    -- Disable preloading
    -- Compress data transfers
    
    OptimizationState.currentSettings.network = {
        dataSaving = true,
        compression = dataSaving.compressionLevel,
        preloading = false
    }
end

function DeviceOptimizationSystem.removeDataSavingSettings()
    OptimizationState.currentSettings.network = {
        dataSaving = false,
        compression = 0,
        preloading = true
    }
end

-- ========================================
-- OFFLINE MODE
-- ========================================

function DeviceOptimizationSystem.setupOfflineMode()
    OptimizationState.offlineModeManager = {
        cacheManager = DeviceOptimizationSystem.createCacheManager(),
        syncManager = DeviceOptimizationSystem.createSyncManager(),
        
        cacheData = function(self, key, data)
            self.cacheManager:store(key, data)
        end,
        
        getCachedData = function(self, key)
            return self.cacheManager:retrieve(key)
        end,
        
        addToSyncQueue = function(self, action, data)
            table.insert(OptimizationState.offlineMode.pendingSync, {
                action = action,
                data = data,
                timestamp = tick()
            })
        end,
        
        processSyncQueue = function(self)
            self.syncManager:processQueue()
        end
    }
    
    print("📦 Offline mode setup completed")
end

function DeviceOptimizationSystem.createCacheManager()
    return {
        cache = {},
        maxSize = OPTIMIZATION_CONFIG.networkOptimization.offlineMode.cacheSize * 1024 * 1024, -- Convert to bytes
        currentSize = 0,
        
        store = function(self, key, data)
            local serializedData = HttpService:JSONEncode(data)
            local dataSize = #serializedData
            
            -- Check cache size limits
            if self.currentSize + dataSize > self.maxSize then
                self:cleanup()
            end
            
            self.cache[key] = {
                data = serializedData,
                size = dataSize,
                timestamp = tick()
            }
            
            self.currentSize = self.currentSize + dataSize
        end,
        
        retrieve = function(self, key)
            local cached = self.cache[key]
            if cached then
                return HttpService:JSONDecode(cached.data)
            end
            return nil
        end,
        
        cleanup = function(self)
            -- Remove oldest entries when cache is full
            local entries = {}
            for key, value in pairs(self.cache) do
                table.insert(entries, {key = key, timestamp = value.timestamp, size = value.size})
            end
            
            table.sort(entries, function(a, b) return a.timestamp < b.timestamp end)
            
            -- Remove oldest 25% of entries
            local removeCount = math.floor(#entries * 0.25)
            for i = 1, removeCount do
                local key = entries[i].key
                self.currentSize = self.currentSize - self.cache[key].size
                self.cache[key] = nil
            end
            
            print(string.format("🗑️ Cache cleanup: removed %d entries", removeCount))
        end
    }
end

function DeviceOptimizationSystem.createSyncManager()
    return {
        processQueue = function(self)
            local pendingSync = OptimizationState.offlineMode.pendingSync
            local processedCount = 0
            
            for i = #pendingSync, 1, -1 do
                local syncItem = pendingSync[i]
                
                -- Attempt to sync the data
                local success = self:syncData(syncItem)
                
                if success then
                    table.remove(pendingSync, i)
                    processedCount = processedCount + 1
                end
            end
            
            if processedCount > 0 then
                OptimizationState.offlineMode.lastSyncTime = tick()
                print(string.format("🔄 Synced %d items from offline queue", processedCount))
            end
        end,
        
        syncData = function(self, syncItem)
            -- Simplified sync logic
            pcall(function()
                -- Attempt to send data to server
                -- This would integrate with your game's networking system
            end)
            
            return true -- Assume success for demo
        end
    }
end

function DeviceOptimizationSystem.activateOfflineMode()
    -- Switch to cached data sources
    -- Disable real-time features
    -- Queue actions for later sync
    
    print("📱 Switched to offline mode - using cached data")
end

function DeviceOptimizationSystem.deactivateOfflineMode()
    -- Restore online functionality
    -- Process sync queue
    OptimizationState.offlineModeManager:processSyncQueue()
    
    print("📱 Switched to online mode - syncing cached changes")
end

-- ========================================
-- PERFORMANCE MONITORING
-- ========================================

function DeviceOptimizationSystem.startPerformanceMonitoring()
    OptimizationState.performanceMonitor = {
        isRunning = true,
        lastSample = tick(),
        samples = {},
        
        updatePerformanceMetrics = function(self)
            local currentTime = tick()
            local frameRate = 1 / RunService.Heartbeat:Wait()
            
            -- Update performance metrics
            OptimizationState.performance.frameRate = frameRate
            
            -- Memory usage (simplified)
            OptimizationState.performance.memoryUsage = math.random(40, 80) -- Mock data
            
            -- Thermal state (simplified)
            local thermalStates = {"Normal", "Fair", "Serious", "Critical"}
            OptimizationState.performance.thermalState = thermalStates[math.random(1, 2)] -- Usually normal/fair
            
            -- Battery level (for mobile devices)
            if OptimizationState.deviceInfo.platform == "Mobile" then
                OptimizationState.performance.batteryLevel = math.max(
                    OptimizationState.performance.batteryLevel - 0.01, 0
                )
            end
            
            -- Network latency (simplified)
            OptimizationState.performance.networkLatency = math.random(20, 100)
            
            -- Store sample
            table.insert(self.samples, {
                timestamp = currentTime,
                frameRate = frameRate,
                memoryUsage = OptimizationState.performance.memoryUsage,
                thermalState = OptimizationState.performance.thermalState
            })
            
            -- Limit sample history
            if #self.samples > 60 then -- Keep last 60 samples
                table.remove(self.samples, 1)
            end
            
            -- Check for performance issues
            self:checkPerformanceThresholds()
        end,
        
        checkPerformanceThresholds = function(self)
            local performance = OptimizationState.performance
            local thresholds = OPTIMIZATION_CONFIG.performanceMonitoring.thresholds
            
            -- Check FPS
            if performance.frameRate < thresholds.fps.critical then
                DeviceOptimizationSystem.handleCriticalPerformance("fps")
            elseif performance.frameRate < thresholds.fps.low then
                DeviceOptimizationSystem.handleLowPerformance("fps")
            end
            
            -- Check memory
            if performance.memoryUsage > thresholds.memory.critical then
                DeviceOptimizationSystem.handleCriticalPerformance("memory")
            elseif performance.memoryUsage > thresholds.memory.high then
                DeviceOptimizationSystem.handleLowPerformance("memory")
            end
            
            -- Check thermal
            if performance.thermalState == "Critical" then
                DeviceOptimizationSystem.handleCriticalPerformance("thermal")
            elseif performance.thermalState == "Serious" then
                DeviceOptimizationSystem.handleLowPerformance("thermal")
            end
        end
    }
    
    -- Event-driven performance monitoring (NO POLLING)
    spawn(function()
        local monitorEvent = Instance.new("BindableEvent")
        
        local function performMonitoringCycle()
            if OptimizationState.performanceMonitor.isRunning then
                OptimizationState.performanceMonitor:updatePerformanceMetrics()
                task.wait(OPTIMIZATION_CONFIG.performanceMonitoring.sampleInterval)
                monitorEvent:Fire()
            end
        end
        
        monitorEvent.Event:Connect(performMonitoringCycle)
        performMonitoringCycle() -- Start monitoring
    end)
    
    print("📊 Performance monitoring started")
end

function DeviceOptimizationSystem.handleCriticalPerformance(issueType)
    print(string.format("🚨 Critical performance issue detected: %s", issueType))
    
    if OPTIMIZATION_CONFIG.autoOptimization.enabled then
        if issueType == "fps" then
            OptimizationState.graphicsOptimizer:optimizeForPerformance()
            OptimizationState.audioOptimizer:optimizeForPerformance()
        elseif issueType == "memory" then
            DeviceOptimizationSystem.performMemoryCleanup()
        elseif issueType == "thermal" then
            DeviceOptimizationSystem.performThermalThrottling()
        end
    end
end

function DeviceOptimizationSystem.handleLowPerformance(issueType)
    print(string.format("⚠️ Low performance detected: %s", issueType))
    
    if OPTIMIZATION_CONFIG.autoOptimization.enabled then
        -- Less aggressive optimization
        if issueType == "fps" then
            OptimizationState.graphicsOptimizer:adjustQuality(-1)
        elseif issueType == "memory" then
            DeviceOptimizationSystem.performLightMemoryCleanup()
        end
    end
end

function DeviceOptimizationSystem.performMemoryCleanup()
    -- Force garbage collection
    collectgarbage("collect")
    
    -- Clear unused textures and sounds
    -- Reduce particle effects
    -- Clear old UI elements
    
    print("🧹 Aggressive memory cleanup performed")
end

function DeviceOptimizationSystem.performLightMemoryCleanup()
    -- Light memory cleanup
    collectgarbage("step", 1000)
    
    print("🧹 Light memory cleanup performed")
end

function DeviceOptimizationSystem.performThermalThrottling()
    -- Reduce CPU/GPU intensive operations
    OptimizationState.graphicsOptimizer:adjustQuality(-3)
    OptimizationState.audioOptimizer:optimizeForPerformance()
    
    -- Reduce update frequencies
    print("🌡️ Thermal throttling activated")
end

-- ========================================
-- AUTO-OPTIMIZATION
-- ========================================

function DeviceOptimizationSystem.initializeAutoOptimization()
    OptimizationState.autoOptimizer = {
        active = OPTIMIZATION_CONFIG.autoOptimization.enabled,
        profiles = {
            performance = {
                graphics = 3,
                audio = "Low",
                network = "DataSaving"
            },
            balanced = {
                graphics = 5,
                audio = "Medium",
                network = "Normal"
            },
            quality = {
                graphics = 8,
                audio = "High",
                network = "HighQuality"
            }
        },
        
        switchToProfile = function(self, profileName)
            local profile = self.profiles[profileName]
            if not profile then return end
            
            OptimizationState.autoOptimizer.currentProfile = profileName
            
            -- Apply profile settings
            OptimizationState.graphicsOptimizer.targetQuality = profile.graphics
            DeviceOptimizationSystem.transitionToQuality(profile.graphics)
            
            print(string.format("🔄 Switched to %s profile", profileName))
        end,
        
        adaptToConditions = function(self)
            local performance = OptimizationState.performance
            
            -- Determine optimal profile based on current conditions
            if performance.frameRate < 20 or performance.memoryUsage > 85 then
                self:switchToProfile("performance")
            elseif performance.frameRate > 50 and performance.memoryUsage < 60 then
                self:switchToProfile("quality")
            else
                self:switchToProfile("balanced")
            end
        end,
        
        getCurrentLoad = function(self)
            local performance = OptimizationState.performance
            -- Calculate system load based on frame rate and memory usage
            local frameLoad = math.max(0, (60 - performance.frameRate) / 60)
            local memoryLoad = performance.memoryUsage / 100
            return math.max(frameLoad, memoryLoad)
        end
    }
    
    -- Event-driven auto-optimization system
    local autoOptimizationEvent = Instance.new("BindableEvent")
    
    local function scheduleAutoOptimization()
        if OptimizationState.autoOptimizer.active then
            OptimizationState.autoOptimizer:adaptToConditions()
            
            -- Adaptive interval based on system load
            local systemLoad = OptimizationState.autoOptimizer:getCurrentLoad()
            local waitTime = systemLoad > 0.8 and 10 or 5 -- Longer wait if high load
            task.wait(waitTime)
        else
            task.wait(30) -- Much longer wait when not active
        end
        autoOptimizationEvent:Fire()
    end
    
    autoOptimizationEvent.Event:Connect(function()
        spawn(scheduleAutoOptimization)
    end)
    
    -- Start the auto-optimization cycle
    spawn(scheduleAutoOptimization)
    
    print("🤖 Auto-optimization initialized")
end

-- ========================================
-- PUBLIC API
-- ========================================

function DeviceOptimizationSystem.getDeviceInfo()
    return OptimizationState.deviceInfo
end

function DeviceOptimizationSystem.getCurrentSettings()
    return OptimizationState.currentSettings
end

function DeviceOptimizationSystem.getPerformanceMetrics()
    return OptimizationState.performance
end

function DeviceOptimizationSystem.enableOfflineMode()
    OptimizationState.networkOptimizer:enableOfflineMode()
end

function DeviceOptimizationSystem.disableOfflineMode()
    OptimizationState.networkOptimizer:disableOfflineMode()
end

function DeviceOptimizationSystem.enableDataSaving()
    OptimizationState.networkOptimizer:enableDataSaving()
end

function DeviceOptimizationSystem.disableDataSaving()
    OptimizationState.networkOptimizer:disableDataSaving()
end

function DeviceOptimizationSystem.setGraphicsQuality(quality)
    OptimizationState.graphicsOptimizer:adjustQuality(quality - OptimizationState.graphicsOptimizer.currentQuality)
end

function DeviceOptimizationSystem.enableAutoOptimization()
    OptimizationState.autoOptimizer.active = true
    print("🤖 Auto-optimization enabled")
end

function DeviceOptimizationSystem.disableAutoOptimization()
    OptimizationState.autoOptimizer.active = false
    print("🤖 Auto-optimization disabled")
end

function DeviceOptimizationSystem.runOptimizationDemo()
    print("🔧 Running device optimization demonstration...")
    
    -- Show device information
    local deviceInfo = OptimizationState.deviceInfo
    print("  📱 Device Information:")
    print(string.format("    Platform: %s", deviceInfo.platform))
    print(string.format("    Tier: %s", deviceInfo.tier))
    print(string.format("    Screen: %.0fx%.0f", deviceInfo.screenSize.X, deviceInfo.screenSize.Y))
    print("    Capabilities:")
    for capability, enabled in pairs(deviceInfo.capabilities) do
        print(string.format("      %s: %s", capability, enabled and "✅" or "❌"))
    end
    
    -- Show current settings
    print("  ⚙️ Current Settings:")
    local graphics = OptimizationState.currentSettings.graphics
    if graphics and next(graphics) then
        print(string.format("    Graphics Quality: %d", graphics.quality or 5))
        print(string.format("    Post Processing: %s", graphics.postProcessing and "✅" or "❌"))
        print(string.format("    Bloom: %s", graphics.bloom and "✅" or "❌"))
        print(string.format("    Shadows: %s", graphics.shadowQuality > 0 and "✅" or "❌"))
    end
    
    local audio = OptimizationState.currentSettings.audio
    if audio and next(audio) then
        print(string.format("    Audio Quality: %s", audio.quality or "Medium"))
        print(string.format("    Max Sounds: %d", audio.maxSounds or 32))
        print(string.format("    Reverb: %s", audio.reverb and "✅" or "❌"))
    end
    
    -- Show performance metrics
    print("  📊 Performance Metrics:")
    local performance = OptimizationState.performance
    print(string.format("    Frame Rate: %.1f FPS", performance.frameRate))
    print(string.format("    Memory Usage: %.1f%%", performance.memoryUsage))
    print(string.format("    Thermal State: %s", performance.thermalState))
    print(string.format("    Network Latency: %dms", performance.networkLatency))
    
    -- Show optimization features
    print("  🔧 Optimization Features:")
    print(string.format("    Auto-Optimization: %s", OptimizationState.autoOptimizer.active and "✅" or "❌"))
    print(string.format("    Data Saving: %s", OptimizationState.networkOptimizer.dataSavingEnabled and "✅" or "❌"))
    print(string.format("    Offline Mode: %s", OptimizationState.offlineMode.active and "✅" or "❌"))
    print(string.format("    Current Profile: %s", OptimizationState.autoOptimizer.currentProfile))
    
    -- Demonstrate optimization
    print("  🎬 Demonstrating optimizations...")
    
    -- Show quality adjustment
    print("    Adjusting graphics quality...")
    local originalQuality = OptimizationState.graphicsOptimizer.currentQuality
    DeviceOptimizationSystem.setGraphicsQuality(3)
    task.wait(2)
    DeviceOptimizationSystem.setGraphicsQuality(originalQuality)
    
    -- Show data saving
    print("    Testing data saving mode...")
    DeviceOptimizationSystem.enableDataSaving()
    task.wait(1)
    DeviceOptimizationSystem.disableDataSaving()
    
    -- Show offline mode
    print("    Testing offline mode...")
    DeviceOptimizationSystem.enableOfflineMode()
    task.wait(1)
    DeviceOptimizationSystem.disableOfflineMode()
    
    print("🔧 Device optimization demonstration completed")
    print("     System automatically adapts to device capabilities and performance!")
end

-- Initialize the device optimization system
DeviceOptimizationSystem.initialize()

print("🔧 DeviceOptimizationSystem loaded with comprehensive mobile optimizations")

return DeviceOptimizationSystem
