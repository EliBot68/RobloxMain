-- DynamicAssetLoadingSystem.luau
-- Dynamic asset loading based on device capabilities
-- Provides adaptive asset loading with device-specific optimization

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local HttpService = game:GetService("HttpService")
local ContentProvider = game:GetService("ContentProvider")
local UserInputService = game:GetService("UserInputService")
local GuiService = game:GetService("GuiService")
local Stats = game:GetService("Stats")

local SafeRequire = require(ReplicatedStorage.Shared.utils.SafeRequire)

local DynamicAssetLoadingSystem = {}

-- ========================================
-- DYNAMIC LOADING CONFIGURATION
-- ========================================

local DYNAMIC_LOADING_CONFIG = {
    -- Device capability tiers
    deviceTiers = {
        low = {
            name = "Low-End Device",
            memory = {min = 0, max = 2 * 1024 * 1024 * 1024},        -- 0-2GB
            cpu = {cores = 2, frequency = 1.5},                      -- Dual-core 1.5GHz
            gpu = {memory = 512 * 1024 * 1024, tier = "low"},        -- 512MB VRAM
            network = {bandwidth = 1000000, latency = 200},          -- 1 Mbps, 200ms
            platform = {"mobile", "old_desktop"}
        },
        
        medium = {
            name = "Mid-Range Device",
            memory = {min = 2 * 1024 * 1024 * 1024, max = 8 * 1024 * 1024 * 1024}, -- 2-8GB
            cpu = {cores = 4, frequency = 2.4},                      -- Quad-core 2.4GHz
            gpu = {memory = 2 * 1024 * 1024 * 1024, tier = "medium"}, -- 2GB VRAM
            network = {bandwidth = 10000000, latency = 100},         -- 10 Mbps, 100ms
            platform = {"desktop", "console", "high_end_mobile"}
        },
        
        high = {
            name = "High-End Device",
            memory = {min = 8 * 1024 * 1024 * 1024, max = 32 * 1024 * 1024 * 1024}, -- 8-32GB
            cpu = {cores = 8, frequency = 3.2},                      -- Octa-core 3.2GHz
            gpu = {memory = 8 * 1024 * 1024 * 1024, tier = "high"},  -- 8GB VRAM
            network = {bandwidth = 50000000, latency = 50},          -- 50 Mbps, 50ms
            platform = {"gaming_pc", "next_gen_console"}
        },
        
        premium = {
            name = "Premium Device",
            memory = {min = 32 * 1024 * 1024 * 1024, max = math.huge}, -- 32GB+
            cpu = {cores = 16, frequency = 4.0},                     -- 16-core 4.0GHz
            gpu = {memory = 16 * 1024 * 1024 * 1024, tier = "premium"}, -- 16GB VRAM
            network = {bandwidth = 100000000, latency = 20},         -- 100 Mbps, 20ms
            platform = {"workstation", "server"}
        }
    },
    
    -- Asset quality levels per device tier
    assetQuality = {
        low = {
            images = {resolution = 512, compression = 0.7, format = "jpg"},
            audio = {bitrate = 128, sampleRate = 22050, format = "mp3"},
            models = {lod = 3, triangles = 1000, textureSize = 256},
            animations = {fps = 15, compression = 0.8},
            effects = {particles = 50, shaders = "basic"}
        },
        
        medium = {
            images = {resolution = 1024, compression = 0.8, format = "png"},
            audio = {bitrate = 192, sampleRate = 44100, format = "mp3"},
            models = {lod = 2, triangles = 5000, textureSize = 512},
            animations = {fps = 30, compression = 0.9},
            effects = {particles = 200, shaders = "standard"}
        },
        
        high = {
            images = {resolution = 2048, compression = 0.9, format = "png"},
            audio = {bitrate = 256, sampleRate = 48000, format = "ogg"},
            models = {lod = 1, triangles = 15000, textureSize = 1024},
            animations = {fps = 60, compression = 0.95},
            effects = {particles = 500, shaders = "advanced"}
        },
        
        premium = {
            images = {resolution = 4096, compression = 1.0, format = "png"},
            audio = {bitrate = 320, sampleRate = 96000, format = "wav"},
            models = {lod = 0, triangles = 50000, textureSize = 2048},
            animations = {fps = 120, compression = 1.0},
            effects = {particles = 1000, shaders = "ultra"}
        }
    },
    
    -- Loading strategies
    loadingStrategies = {
        immediate = {priority = 1, timeout = 5000},
        progressive = {priority = 2, batchSize = 5},
        adaptive = {priority = 3, adjustment = 0.1},
        predictive = {priority = 4, confidence = 0.7},
        background = {priority = 5, idleOnly = true}
    },
    
    -- Performance thresholds
    performance = {
        loadTime = {low = 10000, medium = 5000, high = 2000, premium = 1000}, -- ms
        frameRate = {low = 30, medium = 45, high = 60, premium = 120},        -- FPS
        memoryUsage = {low = 0.8, medium = 0.6, high = 0.4, premium = 0.2}   -- Percentage
    }
}

-- ========================================
-- DYNAMIC LOADING STATE
-- ========================================

local LoadingState = {
    -- Device profiling
    deviceProfile = {},
    deviceTier = "medium",
    capabilities = {},
    
    -- Asset management
    assetRegistry = {},
    loadedAssets = {},
    assetVariants = {},
    loadingQueue = {},
    
    -- Performance monitoring
    performanceMonitor = {},
    frameRateTracker = {},
    memoryTracker = {},
    loadTimeTracker = {},
    
    -- Adaptive systems
    adaptiveEngine = {},
    qualityScaler = {},
    loadBalancer = {},
    
    -- Statistics
    stats = {
        totalAssets = 0,
        loadedAssets = 0,
        failedLoads = 0,
        averageLoadTime = 0,
        memoryUsage = 0,
        adaptiveAdjustments = 0
    }
}

function DynamicAssetLoadingSystem.initialize()
    print("🎯 Initializing DynamicAssetLoadingSystem...")
    
    -- Profile device capabilities
    DynamicAssetLoadingSystem.profileDevice()
    
    -- Set up adaptive loading engine
    DynamicAssetLoadingSystem.setupAdaptiveEngine()
    
    -- Initialize performance monitoring
    DynamicAssetLoadingSystem.initializePerformanceMonitoring()
    
    -- Set up asset management
    DynamicAssetLoadingSystem.setupAssetManagement()
    
    -- Start dynamic processing
    DynamicAssetLoadingSystem.startDynamicProcessing()
    
    print("🎯 DynamicAssetLoadingSystem initialized successfully")
end

-- ========================================
-- DEVICE PROFILING
-- ========================================

function DynamicAssetLoadingSystem.profileDevice()
    LoadingState.deviceProfiler = {
        profile = function()
            return DynamicAssetLoadingSystem.createDeviceProfile()
        end,
        
        updateProfile = function()
            DynamicAssetLoadingSystem.updateDeviceProfile()
        end,
        
        classifyDevice = function()
            return DynamicAssetLoadingSystem.classifyDeviceTier()
        end
    }
    
    -- Initial device profiling
    LoadingState.deviceProfile = LoadingState.deviceProfiler.profile()
    LoadingState.deviceTier = LoadingState.deviceProfiler.classifyDevice()
    
    print(string.format("📱 Device profiled: %s (%s tier)", 
        LoadingState.deviceProfile.platform, LoadingState.deviceTier))
end

function DynamicAssetLoadingSystem.createDeviceProfile()
    local profile = {
        -- Platform detection
        platform = DynamicAssetLoadingSystem.detectPlatform(),
        
        -- Hardware capabilities
        memory = DynamicAssetLoadingSystem.detectMemory(),
        cpu = DynamicAssetLoadingSystem.detectCPU(),
        gpu = DynamicAssetLoadingSystem.detectGPU(),
        
        -- Display capabilities
        display = DynamicAssetLoadingSystem.detectDisplay(),
        
        -- Network capabilities
        network = DynamicAssetLoadingSystem.detectNetwork(),
        
        -- Input capabilities
        input = DynamicAssetLoadingSystem.detectInput(),
        
        -- Performance baseline
        performance = DynamicAssetLoadingSystem.measureBaseline(),
        
        -- Timestamp
        timestamp = tick()
    }
    
    return profile
end

function DynamicAssetLoadingSystem.detectPlatform()
    -- Simulate platform detection
    local platforms = {
        {name = "Windows", type = "desktop", capabilities = "high"},
        {name = "iOS", type = "mobile", capabilities = "medium"},
        {name = "Android", type = "mobile", capabilities = "medium"},
        {name = "Xbox", type = "console", capabilities = "high"},
        {name = "PlayStation", type = "console", capabilities = "high"},
        {name = "Mac", type = "desktop", capabilities = "high"}
    }
    
    local platform = platforms[math.random(#platforms)]
    
    return {
        name = platform.name,
        type = platform.type,
        version = string.format("%d.%d.%d", 
            math.random(10, 15), math.random(0, 9), math.random(0, 9)),
        capabilities = platform.capabilities
    }
end

function DynamicAssetLoadingSystem.detectMemory()
    -- Simulate memory detection
    local memoryConfigs = {
        {total = 2 * 1024 * 1024 * 1024, available = 1.5 * 1024 * 1024 * 1024}, -- 2GB
        {total = 4 * 1024 * 1024 * 1024, available = 3 * 1024 * 1024 * 1024},   -- 4GB
        {total = 8 * 1024 * 1024 * 1024, available = 6 * 1024 * 1024 * 1024},   -- 8GB
        {total = 16 * 1024 * 1024 * 1024, available = 12 * 1024 * 1024 * 1024}, -- 16GB
        {total = 32 * 1024 * 1024 * 1024, available = 24 * 1024 * 1024 * 1024}  -- 32GB
    }
    
    local config = memoryConfigs[math.random(#memoryConfigs)]
    
    return {
        total = config.total,
        available = config.available,
        used = config.total - config.available,
        usagePercent = ((config.total - config.available) / config.total) * 100
    }
end

function DynamicAssetLoadingSystem.detectCPU()
    -- Simulate CPU detection
    local cpuConfigs = {
        {cores = 2, frequency = 1.8, architecture = "ARM", tier = "low"},
        {cores = 4, frequency = 2.4, architecture = "x64", tier = "medium"},
        {cores = 6, frequency = 3.0, architecture = "x64", tier = "medium"},
        {cores = 8, frequency = 3.6, architecture = "x64", tier = "high"},
        {cores = 16, frequency = 4.2, architecture = "x64", tier = "premium"}
    }
    
    local config = cpuConfigs[math.random(#cpuConfigs)]
    
    return {
        cores = config.cores,
        frequency = config.frequency,
        architecture = config.architecture,
        tier = config.tier,
        usage = math.random(20, 80) -- Current usage percentage
    }
end

function DynamicAssetLoadingSystem.detectGPU()
    -- Simulate GPU detection
    local gpuConfigs = {
        {memory = 512 * 1024 * 1024, tier = "low", shaders = "basic"},
        {memory = 2 * 1024 * 1024 * 1024, tier = "medium", shaders = "standard"},
        {memory = 4 * 1024 * 1024 * 1024, tier = "medium", shaders = "advanced"},
        {memory = 8 * 1024 * 1024 * 1024, tier = "high", shaders = "ultra"},
        {memory = 16 * 1024 * 1024 * 1024, tier = "premium", shaders = "ultra"}
    }
    
    local config = gpuConfigs[math.random(#gpuConfigs)]
    
    return {
        memory = config.memory,
        tier = config.tier,
        shaderSupport = config.shaders,
        usage = math.random(10, 70) -- Current usage percentage
    }
end

function DynamicAssetLoadingSystem.detectDisplay()
    -- Simulate display detection
    local displayConfigs = {
        {width = 1366, height = 768, dpi = 96, refresh = 60},   -- Standard laptop
        {width = 1920, height = 1080, dpi = 96, refresh = 60}, -- Full HD
        {width = 2560, height = 1440, dpi = 109, refresh = 144}, -- QHD gaming
        {width = 3840, height = 2160, dpi = 163, refresh = 60}, -- 4K
        {width = 1080, height = 1920, dpi = 401, refresh = 120} -- Mobile
    }
    
    local config = displayConfigs[math.random(#displayConfigs)]
    
    return {
        resolution = Vector2.new(config.width, config.height),
        dpi = config.dpi,
        refreshRate = config.refresh,
        aspectRatio = config.width / config.height,
        pixelDensity = math.sqrt(config.width^2 + config.height^2) / 
                       math.sqrt(config.width^2 + config.height^2) -- Normalized
    }
end

function DynamicAssetLoadingSystem.detectNetwork()
    -- Simulate network detection
    local networkConfigs = {
        {bandwidth = 1000000, latency = 200, stability = 0.7, type = "mobile_3g"},
        {bandwidth = 5000000, latency = 100, stability = 0.85, type = "mobile_4g"},
        {bandwidth = 25000000, latency = 50, stability = 0.9, type = "wifi"},
        {bandwidth = 100000000, latency = 20, stability = 0.95, type = "fiber"},
        {bandwidth = 1000000000, latency = 5, stability = 0.99, type = "enterprise"}
    }
    
    local config = networkConfigs[math.random(#networkConfigs)]
    
    return {
        bandwidth = config.bandwidth,
        latency = config.latency,
        stability = config.stability,
        type = config.type,
        downloadSpeed = config.bandwidth * 0.8, -- 80% of theoretical
        uploadSpeed = config.bandwidth * 0.4    -- 40% of theoretical
    }
end

function DynamicAssetLoadingSystem.detectInput()
    -- Simulate input detection
    return {
        touch = math.random() > 0.5,
        keyboard = math.random() > 0.3,
        mouse = math.random() > 0.4,
        gamepad = math.random() > 0.6,
        accelerometer = math.random() > 0.5
    }
end

function DynamicAssetLoadingSystem.measureBaseline()
    -- Simulate performance baseline measurement
    return {
        frameRate = math.random(30, 120),
        loadTime = math.random(1000, 10000),
        memoryAccess = math.random(50, 200),
        diskIO = math.random(100, 1000),
        networkThroughput = math.random(1000000, 100000000)
    }
end

function DynamicAssetLoadingSystem.classifyDeviceTier()
    local profile = LoadingState.deviceProfile
    local tiers = DYNAMIC_LOADING_CONFIG.deviceTiers
    
    -- Score device based on capabilities
    local score = 0
    local maxScore = 0
    
    -- Memory scoring
    local memoryScore = math.min(profile.memory.total / (8 * 1024 * 1024 * 1024), 1) * 25
    score = score + memoryScore
    maxScore = maxScore + 25
    
    -- CPU scoring
    local cpuScore = math.min((profile.cpu.cores * profile.cpu.frequency) / (8 * 3.0), 1) * 25
    score = score + cpuScore
    maxScore = maxScore + 25
    
    -- GPU scoring
    local gpuScore = math.min(profile.gpu.memory / (8 * 1024 * 1024 * 1024), 1) * 25
    score = score + gpuScore
    maxScore = maxScore + 25
    
    -- Network scoring
    local networkScore = math.min(profile.network.bandwidth / 100000000, 1) * 25
    score = score + networkScore
    maxScore = maxScore + 25
    
    -- Convert to percentage
    local percentage = (score / maxScore) * 100
    
    -- Classify tier
    if percentage >= 85 then
        return "premium"
    elseif percentage >= 65 then
        return "high"
    elseif percentage >= 40 then
        return "medium"
    else
        return "low"
    end
end

function DynamicAssetLoadingSystem.updateDeviceProfile()
    -- Update performance metrics
    LoadingState.deviceProfile.performance = DynamicAssetLoadingSystem.measureBaseline()
    LoadingState.deviceProfile.memory.used = Stats:GetTotalMemoryUsageMb() * 1024 * 1024
    LoadingState.deviceProfile.memory.available = LoadingState.deviceProfile.memory.total - 
                                                   LoadingState.deviceProfile.memory.used
    LoadingState.deviceProfile.timestamp = tick()
    
    -- Re-classify if significant change
    local newTier = DynamicAssetLoadingSystem.classifyDeviceTier()
    if newTier ~= LoadingState.deviceTier then
        print(string.format("📱 Device tier changed: %s -> %s", LoadingState.deviceTier, newTier))
        LoadingState.deviceTier = newTier
        
        -- Trigger asset quality adjustment
        DynamicAssetLoadingSystem.adjustAssetQuality()
    end
end

-- ========================================
-- ADAPTIVE LOADING ENGINE
-- ========================================

function DynamicAssetLoadingSystem.setupAdaptiveEngine()
    LoadingState.adaptiveEngine = {
        qualityAdapter = DynamicAssetLoadingSystem.createQualityAdapter(),
        loadBalancer = DynamicAssetLoadingSystem.createLoadBalancer(),
        priorityManager = DynamicAssetLoadingSystem.createPriorityManager(),
        performanceOptimizer = DynamicAssetLoadingSystem.createPerformanceOptimizer()
    }
    
    print("🔧 Adaptive loading engine initialized")
end

function DynamicAssetLoadingSystem.createQualityAdapter()
    return {
        currentQuality = LoadingState.deviceTier,
        
        adapt = function(self, asset, context)
            return DynamicAssetLoadingSystem.adaptAssetQuality(asset, context)
        end,
        
        getOptimalVariant = function(self, asset)
            return DynamicAssetLoadingSystem.getOptimalAssetVariant(asset)
        end
    }
end

function DynamicAssetLoadingSystem.createLoadBalancer()
    return {
        activeLoads = {},
        maxConcurrent = DynamicAssetLoadingSystem.calculateMaxConcurrentLoads(),
        
        canLoad = function(self, asset)
            return #self.activeLoads < self.maxConcurrent
        end,
        
        queueLoad = function(self, asset, priority)
            return DynamicAssetLoadingSystem.queueAssetLoad(asset, priority)
        end,
        
        executeLoad = function(self, loadRequest)
            return DynamicAssetLoadingSystem.executeAssetLoad(loadRequest)
        end
    }
end

function DynamicAssetLoadingSystem.createPriorityManager()
    return {
        priorityQueues = {
            immediate = {},
            high = {},
            medium = {},
            low = {},
            background = {}
        },
        
        addToQueue = function(self, asset, priority)
            table.insert(self.priorityQueues[priority], asset)
        end,
        
        getNextAsset = function(self)
            return DynamicAssetLoadingSystem.getNextPriorityAsset()
        end
    }
end

function DynamicAssetLoadingSystem.createPerformanceOptimizer()
    return {
        currentPerformance = {},
        targetPerformance = {},
        
        optimize = function(self)
            return DynamicAssetLoadingSystem.optimizePerformance()
        end,
        
        adjustQuality = function(self, direction)
            DynamicAssetLoadingSystem.adjustGlobalQuality(direction)
        end
    }
end

function DynamicAssetLoadingSystem.adaptAssetQuality(asset, context)
    local deviceTier = LoadingState.deviceTier
    local qualityConfig = DYNAMIC_LOADING_CONFIG.assetQuality[deviceTier]
    
    if not qualityConfig then
        qualityConfig = DYNAMIC_LOADING_CONFIG.assetQuality.medium -- Fallback
    end
    
    local adaptedAsset = {
        id = asset.id,
        type = asset.type,
        originalQuality = asset.quality or "original",
        adaptedQuality = deviceTier,
        variant = DynamicAssetLoadingSystem.selectAssetVariant(asset, qualityConfig),
        context = context
    }
    
    -- Apply quality-specific modifications
    if asset.type == "image" then
        adaptedAsset.resolution = qualityConfig.images.resolution
        adaptedAsset.compression = qualityConfig.images.compression
        adaptedAsset.format = qualityConfig.images.format
    elseif asset.type == "audio" then
        adaptedAsset.bitrate = qualityConfig.audio.bitrate
        adaptedAsset.sampleRate = qualityConfig.audio.sampleRate
        adaptedAsset.format = qualityConfig.audio.format
    elseif asset.type == "model" then
        adaptedAsset.lod = qualityConfig.models.lod
        adaptedAsset.triangles = qualityConfig.models.triangles
        adaptedAsset.textureSize = qualityConfig.models.textureSize
    end
    
    return adaptedAsset
end

function DynamicAssetLoadingSystem.selectAssetVariant(asset, qualityConfig)
    local variants = asset.variants or {}
    
    -- Look for exact quality match
    for _, variant in ipairs(variants) do
        if variant.quality == LoadingState.deviceTier then
            return variant
        end
    end
    
    -- Look for compatible variant
    local tierOrder = {"low", "medium", "high", "premium"}
    local currentTierIndex = 1
    
    for i, tier in ipairs(tierOrder) do
        if tier == LoadingState.deviceTier then
            currentTierIndex = i
            break
        end
    end
    
    -- Find best available variant
    for i = currentTierIndex, 1, -1 do
        local tier = tierOrder[i]
        for _, variant in ipairs(variants) do
            if variant.quality == tier then
                return variant
            end
        end
    end
    
    -- Return default variant or original
    return variants[1] or {
        quality = "default",
        url = asset.url,
        size = asset.size
    }
end

function DynamicAssetLoadingSystem.calculateMaxConcurrentLoads()
    local deviceTier = LoadingState.deviceTier
    local tierLimits = {
        low = 2,
        medium = 4,
        high = 8,
        premium = 16
    }
    
    return tierLimits[deviceTier] or 4
end

function DynamicAssetLoadingSystem.queueAssetLoad(asset, priority)
    priority = priority or "medium"
    
    local loadRequest = {
        id = HttpService:GenerateGUID(false),
        asset = DynamicAssetLoadingSystem.adaptAssetQuality(asset, {priority = priority}),
        priority = priority,
        status = "queued",
        queueTime = tick(),
        retries = 0,
        maxRetries = 3
    }
    
    LoadingState.adaptiveEngine.priorityManager:addToQueue(loadRequest, priority)
    
    print(string.format("📥 Queued asset load: %s (%s priority)", asset.id, priority))
    
    return loadRequest.id
end

function DynamicAssetLoadingSystem.executeAssetLoad(loadRequest)
    loadRequest.status = "loading"
    loadRequest.startTime = tick()
    
    local loadBalancer = LoadingState.adaptiveEngine.loadBalancer
    table.insert(loadBalancer.activeLoads, loadRequest)
    
    print(string.format("⬇️ Loading asset: %s (%s quality)", 
        loadRequest.asset.id, loadRequest.asset.adaptedQuality))
    
    -- Simulate asset loading with device-appropriate timing
    local loadTime = DynamicAssetLoadingSystem.calculateLoadTime(loadRequest.asset)
    
    spawn(function()
        task.wait(loadTime / 1000) -- Convert to seconds
        
        local success = math.random() > 0.05 -- 95% success rate
        
        if success then
            loadRequest.status = "completed"
            loadRequest.loadedAsset = DynamicAssetLoadingSystem.createLoadedAsset(loadRequest.asset)
            
            -- Cache the loaded asset
            LoadingState.loadedAssets[loadRequest.asset.id] = loadRequest.loadedAsset
            
            LoadingState.stats.loadedAssets = LoadingState.stats.loadedAssets + 1
        else
            loadRequest.status = "failed"
            loadRequest.error = "Network error or asset unavailable"
            loadRequest.retries = loadRequest.retries + 1
            
            -- Retry if possible
            if loadRequest.retries < loadRequest.maxRetries then
                print(string.format("🔄 Retrying asset load: %s (attempt %d/%d)", 
                    loadRequest.asset.id, loadRequest.retries + 1, loadRequest.maxRetries))
                
                task.wait(2) -- Wait before retry
                DynamicAssetLoadingSystem.executeAssetLoad(loadRequest)
                return
            else
                LoadingState.stats.failedLoads = LoadingState.stats.failedLoads + 1
            end
        end
        
        loadRequest.endTime = tick()
        loadRequest.duration = loadRequest.endTime - loadRequest.startTime
        
        -- Remove from active loads
        for i, activeLoad in ipairs(loadBalancer.activeLoads) do
            if activeLoad.id == loadRequest.id then
                table.remove(loadBalancer.activeLoads, i)
                break
            end
        end
        
        -- Update statistics
        DynamicAssetLoadingSystem.updateLoadingStatistics(loadRequest)
        
        print(string.format("✅ Asset load %s: %s (%.2fs)", 
            loadRequest.status, loadRequest.asset.id, loadRequest.duration))
    end)
    
    return loadRequest
end

function DynamicAssetLoadingSystem.calculateLoadTime(asset)
    local deviceTier = LoadingState.deviceTier
    local baseTime = DYNAMIC_LOADING_CONFIG.performance.loadTime[deviceTier] or 5000
    
    -- Adjust based on asset size and complexity
    local sizeMultiplier = (asset.size or 1024 * 1024) / (1024 * 1024) -- Per MB
    local typeMultiplier = 1
    
    if asset.type == "model" then
        typeMultiplier = 2
    elseif asset.type == "audio" then
        typeMultiplier = 1.5
    elseif asset.type == "image" then
        typeMultiplier = 0.8
    end
    
    local networkMultiplier = 10000000 / (LoadingState.deviceProfile.network.bandwidth or 10000000)
    
    return baseTime * sizeMultiplier * typeMultiplier * networkMultiplier * 0.1
end

function DynamicAssetLoadingSystem.createLoadedAsset(asset)
    return {
        id = asset.id,
        type = asset.type,
        quality = asset.adaptedQuality,
        variant = asset.variant,
        loadTime = tick(),
        size = asset.size,
        content = {
            type = "loaded_asset",
            data = "asset_data_" .. asset.id,
            metadata = asset
        }
    }
end

-- ========================================
-- PERFORMANCE MONITORING
-- ========================================

function DynamicAssetLoadingSystem.initializePerformanceMonitoring()
    LoadingState.performanceMonitor = {
        frameRateMonitor = DynamicAssetLoadingSystem.createFrameRateMonitor(),
        memoryMonitor = DynamicAssetLoadingSystem.createMemoryMonitor(),
        loadTimeMonitor = DynamicAssetLoadingSystem.createLoadTimeMonitor(),
        adaptiveMonitor = DynamicAssetLoadingSystem.createAdaptiveMonitor()
    }
    
    -- Start monitoring
    DynamicAssetLoadingSystem.startPerformanceMonitoring()
    
    print("📊 Performance monitoring initialized")
end

function DynamicAssetLoadingSystem.createFrameRateMonitor()
    return {
        samples = {},
        targetFPS = DYNAMIC_LOADING_CONFIG.performance.frameRate[LoadingState.deviceTier] or 60,
        
        update = function(self)
            DynamicAssetLoadingSystem.updateFrameRate(self)
        end,
        
        getAverage = function(self)
            return DynamicAssetLoadingSystem.getAverageFrameRate(self)
        end
    }
end

function DynamicAssetLoadingSystem.createMemoryMonitor()
    return {
        samples = {},
        threshold = LoadingState.deviceProfile.memory.total * 
                   DYNAMIC_LOADING_CONFIG.performance.memoryUsage[LoadingState.deviceTier],
        
        update = function(self)
            DynamicAssetLoadingSystem.updateMemoryUsage(self)
        end,
        
        isOverThreshold = function(self)
            return DynamicAssetLoadingSystem.isMemoryOverThreshold(self)
        end
    }
end

function DynamicAssetLoadingSystem.createLoadTimeMonitor()
    return {
        samples = {},
        target = DYNAMIC_LOADING_CONFIG.performance.loadTime[LoadingState.deviceTier] or 5000,
        
        recordLoad = function(self, loadTime)
            table.insert(self.samples, loadTime)
            if #self.samples > 100 then
                table.remove(self.samples, 1)
            end
        end,
        
        getAverage = function(self)
            return DynamicAssetLoadingSystem.getAverageLoadTime(self)
        end
    }
end

function DynamicAssetLoadingSystem.createAdaptiveMonitor()
    return {
        adjustmentHistory = {},
        lastAdjustment = 0,
        
        recordAdjustment = function(self, adjustment)
            table.insert(self.adjustmentHistory, {
                adjustment = adjustment,
                timestamp = tick(),
                reason = adjustment.reason
            })
            
            self.lastAdjustment = tick()
        end,
        
        shouldAdjust = function(self)
            return (tick() - self.lastAdjustment) > 10 -- At least 10 seconds between adjustments
        end
    }
end

function DynamicAssetLoadingSystem.startPerformanceMonitoring()
    spawn(function()
        while true do
            -- Update all monitors
            LoadingState.performanceMonitor.frameRateMonitor:update()
            LoadingState.performanceMonitor.memoryMonitor:update()
            
            -- Check for performance issues and adapt
            DynamicAssetLoadingSystem.checkPerformanceAndAdapt()
            
            task.wait(1) -- Monitor every second
        end
    end)
end

function DynamicAssetLoadingSystem.updateFrameRate(monitor)
    local currentFPS = 1 / RunService.Heartbeat:Wait()
    table.insert(monitor.samples, currentFPS)
    
    -- Keep only recent samples
    if #monitor.samples > 60 then
        table.remove(monitor.samples, 1)
    end
end

function DynamicAssetLoadingSystem.updateMemoryUsage(monitor)
    local currentMemory = Stats:GetTotalMemoryUsageMb() * 1024 * 1024
    table.insert(monitor.samples, currentMemory)
    
    -- Keep only recent samples
    if #monitor.samples > 60 then
        table.remove(monitor.samples, 1)
    end
    
    LoadingState.stats.memoryUsage = currentMemory
end

function DynamicAssetLoadingSystem.getAverageFrameRate(monitor)
    if #monitor.samples == 0 then return 0 end
    
    local total = 0
    for _, fps in ipairs(monitor.samples) do
        total = total + fps
    end
    
    return total / #monitor.samples
end

function DynamicAssetLoadingSystem.getAverageLoadTime(monitor)
    if #monitor.samples == 0 then return 0 end
    
    local total = 0
    for _, time in ipairs(monitor.samples) do
        total = total + time
    end
    
    return total / #monitor.samples
end

function DynamicAssetLoadingSystem.isMemoryOverThreshold(monitor)
    if #monitor.samples == 0 then return false end
    
    local latestMemory = monitor.samples[#monitor.samples]
    return latestMemory > monitor.threshold
end

function DynamicAssetLoadingSystem.checkPerformanceAndAdapt()
    local frameMonitor = LoadingState.performanceMonitor.frameRateMonitor
    local memoryMonitor = LoadingState.performanceMonitor.memoryMonitor
    local adaptiveMonitor = LoadingState.performanceMonitor.adaptiveMonitor
    
    if not adaptiveMonitor:shouldAdjust() then return end
    
    local avgFPS = frameMonitor:getAverage()
    local targetFPS = frameMonitor.targetFPS
    local memoryOverThreshold = memoryMonitor:isOverThreshold()
    
    local adjustment = nil
    
    -- Check if performance is below target
    if avgFPS < targetFPS * 0.8 then -- 20% below target
        adjustment = {
            type = "quality_down",
            reason = "fps_below_target",
            severity = "medium",
            timestamp = tick()
        }
    elseif memoryOverThreshold then
        adjustment = {
            type = "quality_down",
            reason = "memory_over_threshold",
            severity = "high",
            timestamp = tick()
        }
    elseif avgFPS > targetFPS * 1.2 then -- 20% above target, can increase quality
        adjustment = {
            type = "quality_up",
            reason = "performance_headroom",
            severity = "low",
            timestamp = tick()
        }
    end
    
    if adjustment then
        DynamicAssetLoadingSystem.applyPerformanceAdjustment(adjustment)
        adaptiveMonitor:recordAdjustment(adjustment)
    end
end

function DynamicAssetLoadingSystem.applyPerformanceAdjustment(adjustment)
    print(string.format("⚙️ Applying performance adjustment: %s (%s)", 
        adjustment.type, adjustment.reason))
    
    if adjustment.type == "quality_down" then
        DynamicAssetLoadingSystem.decreaseQualityLevel()
    elseif adjustment.type == "quality_up" then
        DynamicAssetLoadingSystem.increaseQualityLevel()
    end
    
    LoadingState.stats.adaptiveAdjustments = LoadingState.stats.adaptiveAdjustments + 1
end

function DynamicAssetLoadingSystem.decreaseQualityLevel()
    local tierOrder = {"premium", "high", "medium", "low"}
    local currentIndex = 1
    
    for i, tier in ipairs(tierOrder) do
        if tier == LoadingState.deviceTier then
            currentIndex = i
            break
        end
    end
    
    if currentIndex < #tierOrder then
        local newTier = tierOrder[currentIndex + 1]
        print(string.format("📉 Decreasing quality level: %s -> %s", LoadingState.deviceTier, newTier))
        LoadingState.deviceTier = newTier
        DynamicAssetLoadingSystem.adjustAssetQuality()
    end
end

function DynamicAssetLoadingSystem.increaseQualityLevel()
    local tierOrder = {"low", "medium", "high", "premium"}
    local currentIndex = 1
    
    for i, tier in ipairs(tierOrder) do
        if tier == LoadingState.deviceTier then
            currentIndex = i
            break
        end
    end
    
    if currentIndex < #tierOrder then
        local newTier = tierOrder[currentIndex + 1]
        print(string.format("📈 Increasing quality level: %s -> %s", LoadingState.deviceTier, newTier))
        LoadingState.deviceTier = newTier
        DynamicAssetLoadingSystem.adjustAssetQuality()
    end
end

function DynamicAssetLoadingSystem.adjustAssetQuality()
    -- Re-evaluate all queued assets with new quality level
    local priorityManager = LoadingState.adaptiveEngine.priorityManager
    
    for priorityLevel, queue in pairs(priorityManager.priorityQueues) do
        for i, loadRequest in ipairs(queue) do
            if loadRequest.status == "queued" then
                loadRequest.asset = DynamicAssetLoadingSystem.adaptAssetQuality(
                    loadRequest.asset, {priority = priorityLevel})
            end
        end
    end
end

-- ========================================
-- ASSET MANAGEMENT
-- ========================================

function DynamicAssetLoadingSystem.setupAssetManagement()
    LoadingState.assetManager = {
        registry = {},
        variants = {},
        dependencies = {},
        preloadCache = {}
    }
    
    -- Initialize asset registry
    DynamicAssetLoadingSystem.initializeAssetRegistry()
    
    print("📦 Asset management initialized")
end

function DynamicAssetLoadingSystem.initializeAssetRegistry()
    -- Sample asset registry
    LoadingState.assetManager.registry = {
        ui_backgrounds = {
            id = "ui_backgrounds",
            type = "image",
            variants = {
                {quality = "low", size = 256 * 1024, url = "low_bg.jpg"},
                {quality = "medium", size = 512 * 1024, url = "med_bg.png"},
                {quality = "high", size = 1024 * 1024, url = "high_bg.png"},
                {quality = "premium", size = 2048 * 1024, url = "ultra_bg.png"}
            }
        },
        
        character_models = {
            id = "character_models",
            type = "model",
            variants = {
                {quality = "low", triangles = 1000, url = "char_low.fbx"},
                {quality = "medium", triangles = 5000, url = "char_med.fbx"},
                {quality = "high", triangles = 15000, url = "char_high.fbx"},
                {quality = "premium", triangles = 50000, url = "char_ultra.fbx"}
            }
        },
        
        ambient_audio = {
            id = "ambient_audio",
            type = "audio",
            variants = {
                {quality = "low", bitrate = 128, url = "ambient_128.mp3"},
                {quality = "medium", bitrate = 192, url = "ambient_192.mp3"},
                {quality = "high", bitrate = 256, url = "ambient_256.ogg"},
                {quality = "premium", bitrate = 320, url = "ambient_320.wav"}
            }
        }
    }
end

function DynamicAssetLoadingSystem.getOptimalAssetVariant(assetId)
    local asset = LoadingState.assetManager.registry[assetId]
    if not asset then return nil end
    
    return DynamicAssetLoadingSystem.selectAssetVariant(asset, 
        DYNAMIC_LOADING_CONFIG.assetQuality[LoadingState.deviceTier])
end

-- ========================================
-- DYNAMIC PROCESSING
-- ========================================

function DynamicAssetLoadingSystem.startDynamicProcessing()
    spawn(function()
        while true do
            -- Process asset loading queue
            DynamicAssetLoadingSystem.processLoadingQueue()
            
            -- Update device profile periodically
            if tick() % 30 < 1 then -- Every 30 seconds
                DynamicAssetLoadingSystem.updateDeviceProfile()
            end
            
            -- Perform maintenance
            DynamicAssetLoadingSystem.performMaintenance()
            
            task.wait(0.5)
        end
    end)
    
    print("🔄 Dynamic processing started")
end

function DynamicAssetLoadingSystem.processLoadingQueue()
    local loadBalancer = LoadingState.adaptiveEngine.loadBalancer
    local priorityManager = LoadingState.adaptiveEngine.priorityManager
    
    while loadBalancer:canLoad(nil) do
        local nextAsset = priorityManager:getNextAsset()
        if not nextAsset then break end
        
        loadBalancer:executeLoad(nextAsset)
    end
end

function DynamicAssetLoadingSystem.getNextPriorityAsset()
    local priorityManager = LoadingState.adaptiveEngine.priorityManager
    local priorityOrder = {"immediate", "high", "medium", "low", "background"}
    
    for _, priority in ipairs(priorityOrder) do
        local queue = priorityManager.priorityQueues[priority]
        if #queue > 0 then
            return table.remove(queue, 1)
        end
    end
    
    return nil
end

function DynamicAssetLoadingSystem.performMaintenance()
    -- Clean up old loaded assets
    local maxCacheSize = 100
    local assetCount = 0
    
    for _ in pairs(LoadingState.loadedAssets) do
        assetCount = assetCount + 1
    end
    
    if assetCount > maxCacheSize then
        -- Remove oldest assets
        local assets = {}
        for id, asset in pairs(LoadingState.loadedAssets) do
            table.insert(assets, {id = id, asset = asset})
        end
        
        table.sort(assets, function(a, b)
            return a.asset.loadTime < b.asset.loadTime
        end)
        
        local toRemove = assetCount - maxCacheSize
        for i = 1, toRemove do
            LoadingState.loadedAssets[assets[i].id] = nil
        end
    end
end

function DynamicAssetLoadingSystem.updateLoadingStatistics(loadRequest)
    -- Update average load time
    local totalTime = LoadingState.stats.averageLoadTime * LoadingState.stats.loadedAssets
    totalTime = totalTime + (loadRequest.duration * 1000) -- Convert to ms
    LoadingState.stats.averageLoadTime = totalTime / (LoadingState.stats.loadedAssets + 1)
    
    -- Record in load time monitor
    LoadingState.performanceMonitor.loadTimeMonitor:recordLoad(loadRequest.duration * 1000)
end

-- ========================================
-- PUBLIC API
-- ========================================

function DynamicAssetLoadingSystem.loadAsset(assetId, options)
    options = options or {}
    
    local asset = LoadingState.assetManager.registry[assetId]
    if not asset then
        print(string.format("❌ Asset not found in registry: %s", assetId))
        return nil
    end
    
    -- Check if already loaded
    local loadedAsset = LoadingState.loadedAssets[assetId]
    if loadedAsset then
        print(string.format("✅ Asset already loaded: %s", assetId))
        return loadedAsset
    end
    
    -- Queue for loading
    local priority = options.priority or "medium"
    return DynamicAssetLoadingSystem.queueAssetLoad(asset, priority)
end

function DynamicAssetLoadingSystem.preloadAssets(assetIds, options)
    options = options or {}
    local priority = options.priority or "background"
    
    local preloadRequests = {}
    
    for _, assetId in ipairs(assetIds) do
        local loadId = DynamicAssetLoadingSystem.loadAsset(assetId, {priority = priority})
        if loadId then
            table.insert(preloadRequests, loadId)
        end
    end
    
    print(string.format("📥 Preloading %d assets with %s priority", #preloadRequests, priority))
    
    return preloadRequests
end

function DynamicAssetLoadingSystem.getLoadedAsset(assetId)
    return LoadingState.loadedAssets[assetId]
end

function DynamicAssetLoadingSystem.isAssetLoaded(assetId)
    return LoadingState.loadedAssets[assetId] ~= nil
end

function DynamicAssetLoadingSystem.runDynamicLoadingDemo()
    print("🎯 Running dynamic asset loading demonstration...")
    
    -- Show device profile
    local profile = LoadingState.deviceProfile
    print("  📱 Device Profile:")
    print(string.format("    Platform: %s (%s)", profile.platform.name, profile.platform.type))
    print(string.format("    Tier: %s", LoadingState.deviceTier))
    print(string.format("    Memory: %.1fGB total, %.1fGB available", 
        profile.memory.total / (1024*1024*1024),
        profile.memory.available / (1024*1024*1024)))
    print(string.format("    CPU: %d cores @ %.1fGHz", profile.cpu.cores, profile.cpu.frequency))
    print(string.format("    GPU: %s tier", profile.gpu.tier))
    print(string.format("    Network: %.1f Mbps", profile.network.bandwidth / 1000000))
    
    -- Test adaptive loading
    print("  🎯 Testing adaptive asset loading...")
    
    local testAssets = {"ui_backgrounds", "character_models", "ambient_audio"}
    local priorities = {"immediate", "high", "medium", "low"}
    
    for _, assetId in ipairs(testAssets) do
        for _, priority in ipairs(priorities) do
            local loadId = DynamicAssetLoadingSystem.loadAsset(assetId, {priority = priority})
            print(string.format("    Queued %s (%s priority): %s", assetId, priority, loadId))
        end
    end
    
    -- Wait for some assets to load
    task.wait(3)
    
    -- Show performance metrics
    local frameMonitor = LoadingState.performanceMonitor.frameRateMonitor
    local memoryMonitor = LoadingState.performanceMonitor.memoryMonitor
    
    print("  📊 Performance Metrics:")
    print(string.format("    Average FPS: %.1f (target: %.1f)", 
        frameMonitor:getAverage(), frameMonitor.targetFPS))
    print(string.format("    Memory usage: %.1fMB", 
        LoadingState.stats.memoryUsage / (1024*1024)))
    print(string.format("    Average load time: %.1fms", LoadingState.stats.averageLoadTime))
    print(string.format("    Adaptive adjustments: %d", LoadingState.stats.adaptiveAdjustments))
    
    -- Test quality adaptation
    print("  ⚙️ Testing quality adaptation...")
    print(string.format("    Current quality tier: %s", LoadingState.deviceTier))
    
    -- Simulate performance issues
    print("    Simulating performance drop...")
    DynamicAssetLoadingSystem.applyPerformanceAdjustment({
        type = "quality_down",
        reason = "demo_simulation",
        severity = "medium"
    })
    
    task.wait(1)
    
    print(string.format("    New quality tier: %s", LoadingState.deviceTier))
    
    -- Show loading statistics
    local stats = LoadingState.stats
    print("  📈 Loading Statistics:")
    print(string.format("    Total assets: %d", stats.totalAssets))
    print(string.format("    Loaded assets: %d", stats.loadedAssets))
    print(string.format("    Failed loads: %d", stats.failedLoads))
    print(string.format("    Success rate: %.1f%%", 
        stats.loadedAssets / math.max(stats.loadedAssets + stats.failedLoads, 1) * 100))
    
    print("🎯 Dynamic asset loading demonstration completed")
end

function DynamicAssetLoadingSystem.getDeviceProfile()
    return LoadingState.deviceProfile
end

function DynamicAssetLoadingSystem.getDeviceTier()
    return LoadingState.deviceTier
end

function DynamicAssetLoadingSystem.getLoadingStats()
    return LoadingState.stats
end

function DynamicAssetLoadingSystem.getPerformanceMetrics()
    return {
        frameRate = LoadingState.performanceMonitor.frameRateMonitor:getAverage(),
        memoryUsage = LoadingState.stats.memoryUsage,
        averageLoadTime = LoadingState.stats.averageLoadTime,
        adaptiveAdjustments = LoadingState.stats.adaptiveAdjustments
    }
end

-- Export API
DynamicAssetLoadingSystem.loadAsset = DynamicAssetLoadingSystem.loadAsset
DynamicAssetLoadingSystem.preloadAssets = DynamicAssetLoadingSystem.preloadAssets
DynamicAssetLoadingSystem.getLoadedAsset = DynamicAssetLoadingSystem.getLoadedAsset
DynamicAssetLoadingSystem.isAssetLoaded = DynamicAssetLoadingSystem.isAssetLoaded

-- Initialize the dynamic asset loading system
DynamicAssetLoadingSystem.initialize()

print("🎯 DynamicAssetLoadingSystem loaded with adaptive device-based optimization")

return DynamicAssetLoadingSystem
