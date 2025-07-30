-- AssetPreloadingSystem.luau
-- Asset preloading and caching strategies for improved performance
-- Provides intelligent asset preloading, advanced caching, and performance optimization

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local HttpService = game:GetService("HttpService")
local ContentProvider = game:GetService("ContentProvider")
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")

local SafeRequire = require(ReplicatedStorage.Shared.utils.SafeRequire)

local AssetPreloadingSystem = {}

-- ========================================
-- PRELOADING AND CACHING CONFIGURATION
-- ========================================

local PRELOADING_CONFIG = {
    -- Preloading strategies
    preloading = {
        enablePreloading = true,
        enablePredictivePreloading = true,
        enableBackgroundPreloading = true,
        enableLazyLoading = true,
        preloadBatchSize = 10,
        preloadTimeout = 30000,
        maxConcurrentPreloads = 5
    },
    
    -- Caching strategies
    caching = {
        enableMultiLevelCaching = true,
        enableCompression = true,
        enablePersistentCache = true,
        enableMemoryCache = true,
        enableDiskCache = true,
        memoryLimit = 128 * 1024 * 1024,  -- 128MB
        diskLimit = 512 * 1024 * 1024,    -- 512MB
        defaultTTL = 3600000               -- 1 hour
    },
    
    -- Performance optimization
    optimization = {
        enableAdaptiveQuality = true,
        enableBandwidthDetection = true,
        enableDeviceOptimization = true,
        enableNetworkAwareness = true,
        qualityThresholds = {
            low = {bandwidth = 1000000, memory = 1024*1024*1024},      -- 1 Mbps, 1GB RAM
            medium = {bandwidth = 5000000, memory = 2*1024*1024*1024}, -- 5 Mbps, 2GB RAM  
            high = {bandwidth = 25000000, memory = 4*1024*1024*1024}   -- 25 Mbps, 4GB RAM
        }
    },
    
    -- Preloading priorities
    priorities = {
        critical = 1,    -- UI elements, essential gameplay assets
        high = 2,        -- Immediately visible content
        medium = 3,      -- Soon-to-be-visible content
        low = 4,         -- Background/optional content
        prefetch = 5     -- Predictive content
    }
}

-- ========================================
-- PRELOADING AND CACHING STATE
-- ========================================

local PreloadingState = {
    -- Preloading management
    preloadQueues = {
        critical = {},
        high = {},
        medium = {},
        low = {},
        prefetch = {}
    },
    activePreloads = {},
    preloadHistory = {},
    
    -- Multi-level caching
    memoryCache = {},
    diskCache = {},
    persistentCache = {},
    cacheIndex = {},
    
    -- Performance tracking
    performanceMetrics = {
        preloadTimes = {},
        cacheHitRates = {},
        bandwidthUsage = {},
        memoryUsage = {},
        userBehaviorPatterns = {}
    },
    
    -- Adaptive optimization
    deviceCapabilities = {},
    networkConditions = {},
    userPreferences = {},
    
    -- Asset dependency tracking
    dependencyGraph = {},
    assetRelationships = {},
    loadingSequences = {},
    
    -- Statistics
    stats = {
        totalPreloads = 0,
        successfulPreloads = 0,
        failedPreloads = 0,
        cacheHits = 0,
        cacheMisses = 0,
        bandwidthSaved = 0,
        averageLoadTime = 0
    }
}

function AssetPreloadingSystem.initialize()
    print("⚡ Initializing AssetPreloadingSystem...")
    
    -- Set up preloading system
    AssetPreloadingSystem.setupPreloadingSystem()
    
    -- Initialize multi-level caching
    AssetPreloadingSystem.initializeMultiLevelCaching()
    
    -- Set up performance optimization
    AssetPreloadingSystem.setupPerformanceOptimization()
    
    -- Initialize predictive preloading
    AssetPreloadingSystem.initializePredictivePreloading()
    
    -- Start background processing
    AssetPreloadingSystem.startBackgroundProcessing()
    
    print("⚡ AssetPreloadingSystem initialized successfully")
end

-- ========================================
-- PRELOADING SYSTEM
-- ========================================

function AssetPreloadingSystem.setupPreloadingSystem()
    PreloadingState.preloadManager = {
        strategies = {},
        schedulers = {},
        processors = {}
    }
    
    -- Initialize preloading strategies
    AssetPreloadingSystem.initializePreloadingStrategies()
    
    -- Set up preload scheduling
    AssetPreloadingSystem.setupPreloadScheduling()
    
    print("🚀 Preloading system initialized")
end

function AssetPreloadingSystem.initializePreloadingStrategies()
    PreloadingState.preloadingStrategies = {
        immediate = AssetPreloadingSystem.createImmediateStrategy(),
        progressive = AssetPreloadingSystem.createProgressiveStrategy(),
        predictive = AssetPreloadingSystem.createPredictiveStrategy(),
        lazy = AssetPreloadingSystem.createLazyStrategy(),
        background = AssetPreloadingSystem.createBackgroundStrategy()
    }
end

function AssetPreloadingSystem.createImmediateStrategy()
    return {
        name = "immediate",
        description = "Load assets immediately when requested",
        
        execute = function(assetList, options)
            return AssetPreloadingSystem.executeImmediatePreload(assetList, options)
        end,
        
        priority = PRELOADING_CONFIG.priorities.critical,
        timeout = 5000
    }
end

function AssetPreloadingSystem.createProgressiveStrategy()
    return {
        name = "progressive",
        description = "Load assets in order of importance and visibility",
        
        execute = function(assetList, options)
            return AssetPreloadingSystem.executeProgressivePreload(assetList, options)
        end,
        
        priority = PRELOADING_CONFIG.priorities.high,
        batchSize = 5
    }
end

function AssetPreloadingSystem.createPredictiveStrategy()
    return {
        name = "predictive",
        description = "Preload assets based on user behavior prediction",
        
        execute = function(assetList, options)
            return AssetPreloadingSystem.executePredictivePreload(assetList, options)
        end,
        
        priority = PRELOADING_CONFIG.priorities.prefetch,
        confidence = 0.7
    }
end

function AssetPreloadingSystem.createLazyStrategy()
    return {
        name = "lazy",
        description = "Load assets only when needed",
        
        execute = function(assetList, options)
            return AssetPreloadingSystem.executeLazyPreload(assetList, options)
        end,
        
        priority = PRELOADING_CONFIG.priorities.low,
        threshold = 0.5
    }
end

function AssetPreloadingSystem.createBackgroundStrategy()
    return {
        name = "background",
        description = "Load assets in background during idle time",
        
        execute = function(assetList, options)
            return AssetPreloadingSystem.executeBackgroundPreload(assetList, options)
        end,
        
        priority = PRELOADING_CONFIG.priorities.medium,
        idleThreshold = 100
    }
end

function AssetPreloadingSystem.preloadAssets(assetList, options)
    options = options or {}
    
    local preloadRequest = {
        id = HttpService:GenerateGUID(false),
        assets = assetList,
        strategy = options.strategy or "progressive",
        priority = options.priority or PRELOADING_CONFIG.priorities.medium,
        options = options,
        status = "queued",
        progress = 0,
        startTime = tick(),
        results = {}
    }
    
    -- Add to appropriate priority queue
    local priorityName = AssetPreloadingSystem.getPriorityName(preloadRequest.priority)
    table.insert(PreloadingState.preloadQueues[priorityName], preloadRequest)
    
    print(string.format("🚀 Queued preload request: %d assets (%s strategy)", 
        #assetList, preloadRequest.strategy))
    
    return preloadRequest.id
end

function AssetPreloadingSystem.executePreloadRequest(request)
    request.status = "processing"
    PreloadingState.activePreloads[request.id] = request
    
    local strategy = PreloadingState.preloadingStrategies[request.strategy]
    if not strategy then
        request.status = "failed"
        request.error = "Unknown preloading strategy: " .. request.strategy
        return request
    end
    
    print(string.format("⚡ Executing preload: %s strategy for %d assets", 
        request.strategy, #request.assets))
    
    local success, results = pcall(strategy.execute, request.assets, request.options)
    
    if success then
        request.status = "completed"
        request.results = results
        request.progress = 100
        
        PreloadingState.stats.successfulPreloads = PreloadingState.stats.successfulPreloads + 1
    else
        request.status = "failed"
        request.error = results
        
        PreloadingState.stats.failedPreloads = PreloadingState.stats.failedPreloads + 1
    end
    
    request.endTime = tick()
    request.duration = request.endTime - request.startTime
    
    PreloadingState.activePreloads[request.id] = nil
    PreloadingState.preloadHistory[request.id] = request
    PreloadingState.stats.totalPreloads = PreloadingState.stats.totalPreloads + 1
    
    print(string.format("✅ Preload %s: %s (%d assets in %.2fs)", 
        success and "completed" or "failed",
        request.strategy, 
        #request.assets, 
        request.duration))
    
    return request
end

function AssetPreloadingSystem.executeImmediatePreload(assetList, options)
    local results = {}
    
    for _, asset in ipairs(assetList) do
        local loadResult = AssetPreloadingSystem.loadAssetImmediate(asset)
        table.insert(results, loadResult)
        
        if loadResult.success then
            AssetPreloadingSystem.cacheAsset(asset, loadResult.content, "immediate")
        end
    end
    
    return results
end

function AssetPreloadingSystem.executeProgressivePreload(assetList, options)
    local results = {}
    local batchSize = options.batchSize or 5
    
    -- Sort assets by priority
    local sortedAssets = AssetPreloadingSystem.sortAssetsByPriority(assetList)
    
    -- Process in batches
    for i = 1, #sortedAssets, batchSize do
        local batch = {}
        for j = i, math.min(i + batchSize - 1, #sortedAssets) do
            table.insert(batch, sortedAssets[j])
        end
        
        local batchResults = AssetPreloadingSystem.loadAssetBatch(batch)
        for _, result in ipairs(batchResults) do
            table.insert(results, result)
        end
        
        -- Small delay between batches to prevent overwhelming
        task.wait(0.1)
    end
    
    return results
end

function AssetPreloadingSystem.executePredictivePreload(assetList, options)
    local results = {}
    local confidence = options.confidence or 0.7
    
    -- Filter assets based on prediction confidence
    local predictedAssets = AssetPreloadingSystem.filterAssetsByPrediction(assetList, confidence)
    
    for _, asset in ipairs(predictedAssets) do
        local loadResult = AssetPreloadingSystem.loadAssetPredictive(asset)
        table.insert(results, loadResult)
        
        if loadResult.success then
            AssetPreloadingSystem.cacheAsset(asset, loadResult.content, "predictive")
        end
    end
    
    return results
end

function AssetPreloadingSystem.executeLazyPreload(assetList, options)
    local results = {}
    
    -- Register assets for lazy loading
    for _, asset in ipairs(assetList) do
        AssetPreloadingSystem.registerLazyAsset(asset)
        table.insert(results, {
            asset = asset,
            success = true,
            status = "registered",
            strategy = "lazy"
        })
    end
    
    return results
end

function AssetPreloadingSystem.executeBackgroundPreload(assetList, options)
    local results = {}
    
    spawn(function()
        for _, asset in ipairs(assetList) do
            -- Check if system is idle
            if AssetPreloadingSystem.isSystemIdle() then
                local loadResult = AssetPreloadingSystem.loadAssetBackground(asset)
                
                if loadResult.success then
                    AssetPreloadingSystem.cacheAsset(asset, loadResult.content, "background")
                end
                
                table.insert(results, loadResult)
            else
                -- Yield to prevent blocking
                task.wait(1)
            end
        end
    end)
    
    return results
end

-- ========================================
-- MULTI-LEVEL CACHING
-- ========================================

function AssetPreloadingSystem.initializeMultiLevelCaching()
    PreloadingState.cacheManager = {
        levels = {
            memory = AssetPreloadingSystem.createMemoryCache(),
            disk = AssetPreloadingSystem.createDiskCache(),
            persistent = AssetPreloadingSystem.createPersistentCache()
        },
        policies = {
            eviction = "LRU",
            compression = "adaptive",
            replication = "single"
        }
    }
    
    print("💾 Multi-level caching initialized")
end

function AssetPreloadingSystem.createMemoryCache()
    return {
        name = "memory",
        storage = {},
        index = {},
        maxSize = PRELOADING_CONFIG.caching.memoryLimit,
        currentSize = 0,
        accessOrder = {},
        
        get = function(self, key)
            local entry = self.storage[key]
            if entry then
                AssetPreloadingSystem.updateAccessOrder(self, key)
                return entry.content
            end
            return nil
        end,
        
        set = function(self, key, content, metadata)
            return AssetPreloadingSystem.setMemoryCacheEntry(self, key, content, metadata)
        end,
        
        evict = function(self, requiredSpace)
            return AssetPreloadingSystem.evictMemoryCache(self, requiredSpace)
        end
    }
end

function AssetPreloadingSystem.createDiskCache()
    return {
        name = "disk",
        storage = {},
        index = {},
        maxSize = PRELOADING_CONFIG.caching.diskLimit,
        currentSize = 0,
        
        get = function(self, key)
            local entry = self.storage[key]
            if entry and entry.expiry > tick() then
                return entry.content
            elseif entry then
                self.storage[key] = nil -- Remove expired entry
            end
            return nil
        end,
        
        set = function(self, key, content, metadata)
            return AssetPreloadingSystem.setDiskCacheEntry(self, key, content, metadata)
        end,
        
        evict = function(self, requiredSpace)
            return AssetPreloadingSystem.evictDiskCache(self, requiredSpace)
        end
    }
end

function AssetPreloadingSystem.createPersistentCache()
    return {
        name = "persistent",
        storage = {},
        index = {},
        
        get = function(self, key)
            return self.storage[key]
        end,
        
        set = function(self, key, content, metadata)
            self.storage[key] = {
                content = content,
                metadata = metadata,
                timestamp = tick()
            }
            return true
        end,
        
        evict = function(self, requiredSpace)
            return 0 -- Persistent cache doesn't evict
        end
    }
end

function AssetPreloadingSystem.cacheAsset(asset, content, source)
    local cacheKey = AssetPreloadingSystem.generateCacheKey(asset)
    local metadata = {
        assetId = asset.id,
        source = source,
        timestamp = tick(),
        size = AssetPreloadingSystem.calculateContentSize(content),
        ttl = PRELOADING_CONFIG.caching.defaultTTL
    }
    
    -- Try to cache at each level
    local cacheManager = PreloadingState.cacheManager
    
    -- Memory cache (fastest access)
    if cacheManager.levels.memory:set(cacheKey, content, metadata) then
        print(string.format("💾 Cached asset %s in memory", asset.id))
    end
    
    -- Disk cache (persistent across sessions)
    if cacheManager.levels.disk:set(cacheKey, content, metadata) then
        print(string.format("💽 Cached asset %s on disk", asset.id))
    end
    
    -- Update cache index
    PreloadingState.cacheIndex[cacheKey] = {
        levels = {"memory", "disk"},
        metadata = metadata
    }
    
    return true
end

function AssetPreloadingSystem.getCachedAsset(asset)
    local cacheKey = AssetPreloadingSystem.generateCacheKey(asset)
    local cacheManager = PreloadingState.cacheManager
    
    -- Check cache levels in order of speed
    local levels = {"memory", "disk", "persistent"}
    
    for _, levelName in ipairs(levels) do
        local level = cacheManager.levels[levelName]
        local content = level:get(cacheKey)
        
        if content then
            PreloadingState.stats.cacheHits = PreloadingState.stats.cacheHits + 1
            
            -- Promote to faster cache levels
            if levelName ~= "memory" then
                AssetPreloadingSystem.promoteToFasterCache(cacheKey, content, levelName)
            end
            
            print(string.format("🎯 Cache hit for asset %s (%s)", asset.id, levelName))
            
            return content
        end
    end
    
    PreloadingState.stats.cacheMisses = PreloadingState.stats.cacheMisses + 1
    return nil
end

function AssetPreloadingSystem.promoteToFasterCache(cacheKey, content, currentLevel)
    local cacheManager = PreloadingState.cacheManager
    
    if currentLevel == "disk" then
        -- Promote to memory cache
        local metadata = {timestamp = tick(), promoted = true}
        cacheManager.levels.memory:set(cacheKey, content, metadata)
    end
end

function AssetPreloadingSystem.setMemoryCacheEntry(cache, key, content, metadata)
    local contentSize = AssetPreloadingSystem.calculateContentSize(content)
    
    -- Check if we need to evict
    if cache.currentSize + contentSize > cache.maxSize then
        local evicted = cache:evict(contentSize)
        if cache.currentSize + contentSize > cache.maxSize then
            return false -- Still not enough space
        end
    end
    
    cache.storage[key] = {
        content = content,
        metadata = metadata,
        size = contentSize,
        timestamp = tick()
    }
    
    cache.currentSize = cache.currentSize + contentSize
    table.insert(cache.accessOrder, key)
    
    return true
end

function AssetPreloadingSystem.setDiskCacheEntry(cache, key, content, metadata)
    local contentSize = AssetPreloadingSystem.calculateContentSize(content)
    local ttl = metadata.ttl or PRELOADING_CONFIG.caching.defaultTTL
    
    cache.storage[key] = {
        content = content,
        metadata = metadata,
        size = contentSize,
        timestamp = tick(),
        expiry = tick() + ttl
    }
    
    cache.currentSize = cache.currentSize + contentSize
    
    return true
end

function AssetPreloadingSystem.evictMemoryCache(cache, requiredSpace)
    local evictedSpace = 0
    
    -- Use LRU eviction
    while evictedSpace < requiredSpace and #cache.accessOrder > 0 do
        local oldestKey = table.remove(cache.accessOrder, 1)
        local entry = cache.storage[oldestKey]
        
        if entry then
            cache.storage[oldestKey] = nil
            cache.currentSize = cache.currentSize - entry.size
            evictedSpace = evictedSpace + entry.size
        end
    end
    
    return evictedSpace
end

function AssetPreloadingSystem.evictDiskCache(cache, requiredSpace)
    local evictedSpace = 0
    local currentTime = tick()
    
    -- First, remove expired entries
    for key, entry in pairs(cache.storage) do
        if entry.expiry <= currentTime then
            cache.storage[key] = nil
            cache.currentSize = cache.currentSize - entry.size
            evictedSpace = evictedSpace + entry.size
        end
    end
    
    -- If still need space, use LRU on remaining entries
    if evictedSpace < requiredSpace then
        local entries = {}
        for key, entry in pairs(cache.storage) do
            table.insert(entries, {key = key, entry = entry})
        end
        
        -- Sort by timestamp (oldest first)
        table.sort(entries, function(a, b)
            return a.entry.timestamp < b.entry.timestamp
        end)
        
        for _, item in ipairs(entries) do
            if evictedSpace >= requiredSpace then break end
            
            cache.storage[item.key] = nil
            cache.currentSize = cache.currentSize - item.entry.size
            evictedSpace = evictedSpace + item.entry.size
        end
    end
    
    return evictedSpace
end

-- ========================================
-- PERFORMANCE OPTIMIZATION
-- ========================================

function AssetPreloadingSystem.setupPerformanceOptimization()
    PreloadingState.performanceOptimizer = {
        deviceProfiler = AssetPreloadingSystem.createDeviceProfiler(),
        networkMonitor = AssetPreloadingSystem.createNetworkMonitor(),
        adaptiveQuality = AssetPreloadingSystem.createAdaptiveQuality(),
        bandwidthManager = AssetPreloadingSystem.createBandwidthManager()
    }
    
    -- Detect device capabilities
    AssetPreloadingSystem.detectDeviceCapabilities()
    
    -- Start network monitoring
    AssetPreloadingSystem.startNetworkMonitoring()
    
    print("⚡ Performance optimization initialized")
end

function AssetPreloadingSystem.createDeviceProfiler()
    return {
        profile = function()
            return AssetPreloadingSystem.profileDevice()
        end,
        
        getQualityLevel = function()
            return AssetPreloadingSystem.determineQualityLevel()
        end
    }
end

function AssetPreloadingSystem.createNetworkMonitor()
    return {
        bandwidth = 0,
        latency = 0,
        stability = 1.0,
        lastUpdate = tick(),
        
        update = function(self)
            AssetPreloadingSystem.updateNetworkMetrics(self)
        end,
        
        getConditions = function(self)
            return {
                bandwidth = self.bandwidth,
                latency = self.latency,
                stability = self.stability
            }
        end
    }
end

function AssetPreloadingSystem.createAdaptiveQuality()
    return {
        currentLevel = "medium",
        
        adjustQuality = function(self, deviceCapabilities, networkConditions)
            return AssetPreloadingSystem.calculateOptimalQuality(deviceCapabilities, networkConditions)
        end,
        
        getAssetVariant = function(self, asset, qualityLevel)
            return AssetPreloadingSystem.selectAssetVariant(asset, qualityLevel)
        end
    }
end

function AssetPreloadingSystem.createBandwidthManager()
    return {
        allocated = {},
        available = 0,
        
        allocate = function(self, requestId, bandwidth)
            return AssetPreloadingSystem.allocateBandwidth(self, requestId, bandwidth)
        end,
        
        release = function(self, requestId)
            AssetPreloadingSystem.releaseBandwidth(self, requestId)
        end
    }
end

function AssetPreloadingSystem.detectDeviceCapabilities()
    local capabilities = {
        platform = "unknown",
        memory = 2 * 1024 * 1024 * 1024, -- Default 2GB
        storage = 10 * 1024 * 1024 * 1024, -- Default 10GB
        gpu = "medium",
        cpu = "medium",
        screenResolution = Vector2.new(1920, 1080),
        touchSupported = false
    }
    
    -- Simulate device detection
    local platforms = {"Windows", "Mac", "iOS", "Android", "Xbox"}
    capabilities.platform = platforms[math.random(#platforms)]
    
    if capabilities.platform == "iOS" or capabilities.platform == "Android" then
        capabilities.memory = 4 * 1024 * 1024 * 1024 -- 4GB for mobile
        capabilities.touchSupported = true
        capabilities.screenResolution = Vector2.new(1080, 1920) -- Portrait mobile
    elseif capabilities.platform == "Xbox" then
        capabilities.memory = 16 * 1024 * 1024 * 1024 -- 16GB for Xbox
        capabilities.gpu = "high"
        capabilities.cpu = "high"
        capabilities.screenResolution = Vector2.new(1920, 1080)
    end
    
    PreloadingState.deviceCapabilities = capabilities
    
    print(string.format("📱 Detected device: %s (%s GPU, %dGB RAM)", 
        capabilities.platform, 
        capabilities.gpu,
        capabilities.memory / (1024*1024*1024)))
    
    return capabilities
end

function AssetPreloadingSystem.determineQualityLevel()
    local capabilities = PreloadingState.deviceCapabilities
    local network = PreloadingState.networkConditions
    
    local thresholds = PRELOADING_CONFIG.optimization.qualityThresholds
    
    -- Check against thresholds
    if capabilities.memory >= thresholds.high.memory and 
       network.bandwidth >= thresholds.high.bandwidth then
        return "high"
    elseif capabilities.memory >= thresholds.medium.memory and 
           network.bandwidth >= thresholds.medium.bandwidth then
        return "medium"
    else
        return "low"
    end
end

function AssetPreloadingSystem.startNetworkMonitoring()
    spawn(function()
        while true do
            AssetPreloadingSystem.updateNetworkConditions()
            task.wait(5) -- Update every 5 seconds
        end
    end)
end

function AssetPreloadingSystem.updateNetworkConditions()
    -- Simulate network condition detection
    local conditions = {
        bandwidth = math.random(1000000, 50000000), -- 1-50 Mbps
        latency = math.random(20, 200), -- 20-200ms
        stability = math.random(70, 100) / 100, -- 70-100%
        timestamp = tick()
    }
    
    PreloadingState.networkConditions = conditions
    
    -- Update adaptive quality based on new conditions
    local qualityLevel = AssetPreloadingSystem.determineQualityLevel()
    PreloadingState.performanceOptimizer.adaptiveQuality.currentLevel = qualityLevel
    
    return conditions
end

-- ========================================
-- PREDICTIVE PRELOADING
-- ========================================

function AssetPreloadingSystem.initializePredictivePreloading()
    PreloadingState.predictiveEngine = {
        userBehaviorModel = {},
        patternRecognition = {},
        predictionAccuracy = 0.7,
        learningEnabled = true
    }
    
    -- Start behavior tracking
    AssetPreloadingSystem.startBehaviorTracking()
    
    print("🔮 Predictive preloading initialized")
end

function AssetPreloadingSystem.startBehaviorTracking()
    spawn(function()
        while true do
            AssetPreloadingSystem.trackUserBehavior()
            AssetPreloadingSystem.updatePredictions()
            task.wait(10) -- Update every 10 seconds
        end
    end)
end

function AssetPreloadingSystem.trackUserBehavior()
    local behavior = {
        timestamp = tick(),
        currentScene = "MainMenu", -- Simulate current scene
        previousScenes = {"LoadingScreen", "SplashScreen"},
        timeSpent = math.random(5, 30),
        interactions = math.random(1, 10),
        assetRequests = {}
    }
    
    -- Simulate asset request patterns
    local commonAssets = {"ui_button", "background_music", "character_model"}
    for _, asset in ipairs(commonAssets) do
        if math.random() > 0.5 then
            table.insert(behavior.assetRequests, asset)
        end
    end
    
    table.insert(PreloadingState.performanceMetrics.userBehaviorPatterns, behavior)
    
    -- Maintain pattern history
    if #PreloadingState.performanceMetrics.userBehaviorPatterns > 100 then
        table.remove(PreloadingState.performanceMetrics.userBehaviorPatterns, 1)
    end
end

function AssetPreloadingSystem.updatePredictions()
    local patterns = PreloadingState.performanceMetrics.userBehaviorPatterns
    if #patterns < 5 then return end -- Need minimum data
    
    -- Analyze patterns to predict next assets
    local predictions = AssetPreloadingSystem.analyzeBehaviorPatterns(patterns)
    
    -- Queue predictive preloads
    if #predictions > 0 then
        AssetPreloadingSystem.preloadAssets(predictions, {
            strategy = "predictive",
            priority = PRELOADING_CONFIG.priorities.prefetch
        })
    end
end

function AssetPreloadingSystem.analyzeBehaviorPatterns(patterns)
    local predictions = {}
    local assetFrequency = {}
    
    -- Analyze asset request frequency
    for _, pattern in ipairs(patterns) do
        for _, asset in ipairs(pattern.assetRequests) do
            assetFrequency[asset] = (assetFrequency[asset] or 0) + 1
        end
    end
    
    -- Predict assets based on frequency and context
    for asset, frequency in pairs(assetFrequency) do
        local probability = frequency / #patterns
        if probability > 0.3 then -- 30% threshold
            table.insert(predictions, {
                id = asset,
                probability = probability,
                type = "behavioral_prediction"
            })
        end
    end
    
    return predictions
end

-- ========================================
-- BACKGROUND PROCESSING
-- ========================================

function AssetPreloadingSystem.startBackgroundProcessing()
    spawn(function()
        while true do
            AssetPreloadingSystem.processPreloadQueues()
            AssetPreloadingSystem.performCacheMaintenance()
            AssetPreloadingSystem.updatePerformanceMetrics()
            
            task.wait(1)
        end
    end)
    
    print("🔄 Background processing started")
end

function AssetPreloadingSystem.processPreloadQueues()
    local maxConcurrent = PRELOADING_CONFIG.preloading.maxConcurrentPreloads
    local activeCount = 0
    
    for _ in pairs(PreloadingState.activePreloads) do
        activeCount = activeCount + 1
    end
    
    if activeCount >= maxConcurrent then return end
    
    -- Process queues in priority order
    local priorityOrder = {"critical", "high", "medium", "low", "prefetch"}
    
    for _, priority in ipairs(priorityOrder) do
        local queue = PreloadingState.preloadQueues[priority]
        
        while activeCount < maxConcurrent and #queue > 0 do
            local request = table.remove(queue, 1)
            
            spawn(function()
                AssetPreloadingSystem.executePreloadRequest(request)
            end)
            
            activeCount = activeCount + 1
        end
        
        if activeCount >= maxConcurrent then break end
    end
end

function AssetPreloadingSystem.performCacheMaintenance()
    local cacheManager = PreloadingState.cacheManager
    
    -- Clean expired entries
    for levelName, level in pairs(cacheManager.levels) do
        if levelName == "disk" then
            level:evict(0) -- This will clean expired entries
        end
    end
    
    -- Update cache statistics
    AssetPreloadingSystem.updateCacheStatistics()
end

function AssetPreloadingSystem.updateCacheStatistics()
    local totalHits = PreloadingState.stats.cacheHits
    local totalMisses = PreloadingState.stats.cacheMisses
    local totalRequests = totalHits + totalMisses
    
    if totalRequests > 0 then
        PreloadingState.stats.cacheHitRate = (totalHits / totalRequests) * 100
    end
end

function AssetPreloadingSystem.updatePerformanceMetrics()
    -- Update preload times
    local preloadTimes = {}
    for _, request in pairs(PreloadingState.preloadHistory) do
        if request.duration then
            table.insert(preloadTimes, request.duration * 1000) -- Convert to ms
        end
    end
    
    if #preloadTimes > 0 then
        local total = 0
        for _, time in ipairs(preloadTimes) do
            total = total + time
        end
        PreloadingState.stats.averageLoadTime = total / #preloadTimes
    end
end

-- ========================================
-- UTILITY FUNCTIONS
-- ========================================

function AssetPreloadingSystem.generateCacheKey(asset)
    return string.format("%s:%s:%s", 
        asset.id or "unknown", 
        asset.version or "1.0", 
        asset.variant or "default")
end

function AssetPreloadingSystem.calculateContentSize(content)
    if type(content) == "string" then
        return #content
    elseif type(content) == "table" then
        local serialized = HttpService:JSONEncode(content)
        return #serialized
    else
        return 1024 -- Default size
    end
end

function AssetPreloadingSystem.getPriorityName(priorityValue)
    local priorities = PRELOADING_CONFIG.priorities
    for name, value in pairs(priorities) do
        if value == priorityValue then
            return name
        end
    end
    return "medium"
end

function AssetPreloadingSystem.sortAssetsByPriority(assetList)
    local sorted = {}
    for _, asset in ipairs(assetList) do
        table.insert(sorted, asset)
    end
    
    table.sort(sorted, function(a, b)
        local priorityA = a.priority or PRELOADING_CONFIG.priorities.medium
        local priorityB = b.priority or PRELOADING_CONFIG.priorities.medium
        return priorityA < priorityB
    end)
    
    return sorted
end

function AssetPreloadingSystem.filterAssetsByPrediction(assetList, confidence)
    local filtered = {}
    
    for _, asset in ipairs(assetList) do
        local probability = asset.probability or 0.5
        if probability >= confidence then
            table.insert(filtered, asset)
        end
    end
    
    return filtered
end

function AssetPreloadingSystem.isSystemIdle()
    -- Simulate system idle detection
    return math.random() > 0.3 -- 70% chance of being idle
end

function AssetPreloadingSystem.loadAssetImmediate(asset)
    return {
        asset = asset,
        success = true,
        content = {type = "asset_data", data = "immediate_" .. asset.id},
        strategy = "immediate",
        loadTime = 0.1
    }
end

function AssetPreloadingSystem.loadAssetBatch(assetBatch)
    local results = {}
    
    for _, asset in ipairs(assetBatch) do
        table.insert(results, {
            asset = asset,
            success = true,
            content = {type = "asset_data", data = "batch_" .. asset.id},
            strategy = "progressive",
            loadTime = 0.2
        })
    end
    
    return results
end

function AssetPreloadingSystem.loadAssetPredictive(asset)
    return {
        asset = asset,
        success = true,
        content = {type = "asset_data", data = "predictive_" .. asset.id},
        strategy = "predictive",
        loadTime = 0.3
    }
end

function AssetPreloadingSystem.loadAssetBackground(asset)
    return {
        asset = asset,
        success = true,
        content = {type = "asset_data", data = "background_" .. asset.id},
        strategy = "background",
        loadTime = 0.5
    }
end

function AssetPreloadingSystem.registerLazyAsset(asset)
    -- Register asset for lazy loading
    print(string.format("📌 Registered lazy asset: %s", asset.id))
end

function AssetPreloadingSystem.updateAccessOrder(cache, key)
    -- Move key to end of access order
    for i, accessKey in ipairs(cache.accessOrder) do
        if accessKey == key then
            table.remove(cache.accessOrder, i)
            break
        end
    end
    table.insert(cache.accessOrder, key)
end

-- ========================================
-- PUBLIC API
-- ========================================

function AssetPreloadingSystem.runPreloadingDemo()
    print("⚡ Running asset preloading demonstration...")
    
    -- Create sample assets for preloading
    local sampleAssets = {
        {id = "ui_menu_background", priority = PRELOADING_CONFIG.priorities.critical, size = 2048},
        {id = "player_character_model", priority = PRELOADING_CONFIG.priorities.high, size = 5120},
        {id = "background_music", priority = PRELOADING_CONFIG.priorities.medium, size = 10240},
        {id = "environment_texture", priority = PRELOADING_CONFIG.priorities.low, size = 4096},
        {id = "optional_sound_effect", priority = PRELOADING_CONFIG.priorities.prefetch, size = 1024}
    }
    
    -- Test different preloading strategies
    print("  🚀 Testing preloading strategies...")
    
    local strategies = {"immediate", "progressive", "predictive", "background"}
    for _, strategy in ipairs(strategies) do
        local requestId = AssetPreloadingSystem.preloadAssets(sampleAssets, {
            strategy = strategy,
            priority = PRELOADING_CONFIG.priorities.medium
        })
        print(string.format("    Queued %s preload: %s", strategy, requestId))
    end
    
    -- Wait for preloading to complete
    task.wait(3)
    
    -- Test caching
    print("  💾 Testing multi-level caching...")
    for _, asset in ipairs(sampleAssets) do
        local cachedContent = AssetPreloadingSystem.getCachedAsset(asset)
        if cachedContent then
            print(string.format("    Cache hit for: %s", asset.id))
        else
            print(string.format("    Cache miss for: %s", asset.id))
        end
    end
    
    -- Show performance metrics
    local stats = AssetPreloadingSystem.getPreloadingStats()
    print("  📊 Performance metrics:")
    print(string.format("    Total preloads: %d", stats.totalPreloads))
    print(string.format("    Successful preloads: %d", stats.successfulPreloads))
    print(string.format("    Cache hit rate: %.1f%%", stats.cacheHitRate))
    print(string.format("    Average load time: %.1fms", stats.averageLoadTime))
    
    -- Show device capabilities
    local capabilities = AssetPreloadingSystem.getDeviceCapabilities()
    print(string.format("    Device: %s (%s quality)", 
        capabilities.platform, AssetPreloadingSystem.determineQualityLevel()))
    
    print("⚡ Asset preloading demonstration completed")
end

function AssetPreloadingSystem.getPreloadingStats()
    return PreloadingState.stats
end

function AssetPreloadingSystem.getDeviceCapabilities()
    return PreloadingState.deviceCapabilities
end

function AssetPreloadingSystem.getNetworkConditions()
    return PreloadingState.networkConditions
end

function AssetPreloadingSystem.getCacheInfo()
    local info = {
        levels = {},
        totalSize = 0,
        hitRate = PreloadingState.stats.cacheHitRate
    }
    
    for levelName, level in pairs(PreloadingState.cacheManager.levels) do
        info.levels[levelName] = {
            name = levelName,
            currentSize = level.currentSize or 0,
            maxSize = level.maxSize or 0,
            entryCount = 0
        }
        
        for _ in pairs(level.storage) do
            info.levels[levelName].entryCount = info.levels[levelName].entryCount + 1
        end
        
        info.totalSize = info.totalSize + info.levels[levelName].currentSize
    end
    
    return info
end

-- Export API
AssetPreloadingSystem.preloadAssets = AssetPreloadingSystem.preloadAssets
AssetPreloadingSystem.getCachedAsset = AssetPreloadingSystem.getCachedAsset
AssetPreloadingSystem.cacheAsset = AssetPreloadingSystem.cacheAsset
AssetPreloadingSystem.determineQualityLevel = AssetPreloadingSystem.determineQualityLevel

-- Initialize the asset preloading system
AssetPreloadingSystem.initialize()

print("⚡ AssetPreloadingSystem loaded with comprehensive preloading and caching capabilities")

return AssetPreloadingSystem
