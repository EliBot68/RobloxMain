-- LazyLoadingSystem.luau
-- Progressive loading system with code splitting for improved startup times
-- Implements intelligent asset and module loading strategies

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local ContentProvider = game:GetService("ContentProvider")
local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")

local SafeRequire = require(ReplicatedStorage.Shared.utils.SafeRequire)

local LazyLoadingSystem = {}

-- ========================================
-- LAZY LOADING CONFIGURATION
-- ========================================

local LOADING_CONFIG = {
    -- Loading strategies
    strategies = {
        critical = {
            priority = 1,
            preloadDistance = 100,     -- Load within 100 studs
            loadImmediately = true,
            maxConcurrent = 10
        },
        important = {
            priority = 2,
            preloadDistance = 200,     -- Load within 200 studs
            loadImmediately = false,
            maxConcurrent = 5
        },
        normal = {
            priority = 3,
            preloadDistance = 300,     -- Load within 300 studs
            loadImmediately = false,
            maxConcurrent = 3
        },
        background = {
            priority = 4,
            preloadDistance = 500,     -- Load within 500 studs
            loadImmediately = false,
            maxConcurrent = 2
        },
        lazy = {
            priority = 5,
            preloadDistance = 50,      -- Load very close
            loadImmediately = false,
            maxConcurrent = 1
        }
    },
    
    -- Module loading
    moduleLoading = {
        enableCodeSplitting = true,
        chunkSize = 32768,            -- 32KB chunks
        maxConcurrentModules = 5,
        cacheModules = true,
        preloadCriticalModules = true,
        deferNonEssential = true
    },
    
    -- Asset loading
    assetLoading = {
        enableStreaming = true,
        streamingRadius = 400,        -- Streaming radius in studs
        lodLevels = 3,               -- Number of LOD levels
        textureStreamingEnabled = true,
        modelStreamingEnabled = true,
        audioStreamingEnabled = true
    },
    
    -- Performance thresholds
    performance = {
        maxLoadTimePerFrame = 5,      -- Milliseconds per frame
        memoryPressureThreshold = 512, -- MB
        fpsThreshold = 30,            -- Minimum FPS during loading
        bandwidthLimit = 1024,        -- KB/s bandwidth limit
        networkLatencyThreshold = 200  -- ms
    },
    
    -- Caching settings
    caching = {
        enablePersistentCache = true,
        maxCacheSize = 100,           -- MB
        cacheExpiryTime = 86400,      -- 24 hours
        preloadCacheOnStartup = true
    }
}

-- ========================================
-- LAZY LOADING STATE
-- ========================================

local LoadingState = {
    -- Loading management
    loadingQueue = {},
    activeLoads = {},
    loadedAssets = {},
    loadedModules = {},
    
    -- Module system
    moduleRegistry = {},
    moduleChunks = {},
    moduleLoadOrder = {},
    criticalModules = {},
    
    -- Asset streaming
    streamingObjects = {},
    lodCache = {},
    streamingEnabled = true,
    
    -- Performance tracking
    loadingMetrics = {
        totalLoadTime = 0,
        assetsLoaded = 0,
        modulesLoaded = 0,
        cacheHits = 0,
        cacheMisses = 0,
        streamingEvents = 0
    },
    
    -- Spatial tracking
    playerPosition = Vector3.new(0, 0, 0),
    lastPositionUpdate = 0,
    nearbyObjects = {},
    
    -- Loading state
    isInitialized = false,
    startupComplete = false,
    connections = {},
    
    -- Statistics
    stats = {
        startupTime = 0,
        criticalLoadTime = 0,
        totalAssets = 0,
        streamedAssets = 0,
        deferredLoads = 0
    }
}

function LazyLoadingSystem.initialize()
    print("⚡ Initializing LazyLoadingSystem...")
    
    -- Initialize module registry
    LazyLoadingSystem.initializeModuleRegistry()
    
    -- Set up asset streaming
    LazyLoadingSystem.setupAssetStreaming()
    
    -- Start loading queue processor
    LazyLoadingSystem.startLoadingProcessor()
    
    -- Initialize spatial tracking
    LazyLoadingSystem.initializeSpatialTracking()
    
    -- Set up performance monitoring
    LazyLoadingSystem.setupPerformanceMonitoring()
    
    -- Begin startup loading sequence
    LazyLoadingSystem.beginStartupSequence()
    
    LoadingState.isInitialized = true
    print("⚡ LazyLoadingSystem initialized successfully")
end

-- ========================================
-- MODULE REGISTRY AND CODE SPLITTING
-- ========================================

function LazyLoadingSystem.initializeModuleRegistry()
    LoadingState.moduleRegistry = {}
    LoadingState.moduleChunks = {}
    LoadingState.criticalModules = {}
    
    -- Define critical modules that must load immediately
    LoadingState.criticalModules = {
        "CoreServices",
        "PlayerManager", 
        "InputHandler",
        "SafeRequire",
        "ErrorHandler"
    }
    
    -- Define module loading order for optimal performance
    LoadingState.moduleLoadOrder = {
        startup = {"CoreServices", "PlayerManager", "InputHandler"},
        early = {"UISystem", "AudioManager", "NetworkManager"},
        normal = {"GameLogic", "EffectsSystem", "AnalyticsSystem"},
        late = {"SocialFeatures", "ShopSystem", "AchievementSystem"},
        background = {"TutorialSystem", "HelpSystem", "DebugTools"}
    }
    
    print("📦 Module registry initialized")
end

function LazyLoadingSystem.registerModule(moduleName, moduleConfig)
    local module = {
        name = moduleName,
        path = moduleConfig.path,
        priority = moduleConfig.priority or "normal",
        dependencies = moduleConfig.dependencies or {},
        size = moduleConfig.size or 0,
        loadStrategy = moduleConfig.loadStrategy or "normal",
        isLoaded = false,
        loadTime = 0,
        chunk = nil
    }
    
    LoadingState.moduleRegistry[moduleName] = module
    
    -- Create chunks for large modules
    if LOADING_CONFIG.moduleLoading.enableCodeSplitting and module.size > LOADING_CONFIG.moduleLoading.chunkSize then
        LazyLoadingSystem.createModuleChunks(module)
    end
    
    print(string.format("📦 Registered module: %s (%s priority)", moduleName, module.priority))
    return module
end

function LazyLoadingSystem.createModuleChunks(module)
    local chunkCount = math.ceil(module.size / LOADING_CONFIG.moduleLoading.chunkSize)
    local chunks = {}
    
    for i = 1, chunkCount do
        local chunk = {
            id = string.format("%s_chunk_%d", module.name, i),
            index = i,
            size = math.min(LOADING_CONFIG.moduleLoading.chunkSize, module.size - (i - 1) * LOADING_CONFIG.moduleLoading.chunkSize),
            isLoaded = false
        }
        table.insert(chunks, chunk)
    end
    
    LoadingState.moduleChunks[module.name] = chunks
    print(string.format("🧩 Created %d chunks for module: %s", chunkCount, module.name))
end

function LazyLoadingSystem.loadModule(moduleName, callback)
    local module = LoadingState.moduleRegistry[moduleName]
    if not module then
        warn("Module not found: " .. moduleName)
        if callback then callback(false, "Module not found") end
        return
    end
    
    if module.isLoaded then
        if callback then callback(true, LoadingState.loadedModules[moduleName]) end
        return LoadingState.loadedModules[moduleName]
    end
    
    -- Check dependencies first
    local dependenciesLoaded = LazyLoadingSystem.loadDependencies(module.dependencies)
    if not dependenciesLoaded then
        -- Queue for later loading
        LazyLoadingSystem.queueModuleLoad(moduleName, callback)
        return
    end
    
    -- Load module
    local startTime = tick()
    local loadedModule = LazyLoadingSystem.executeModuleLoad(module)
    local loadTime = tick() - startTime
    
    if loadedModule then
        module.isLoaded = true
        module.loadTime = loadTime
        LoadingState.loadedModules[moduleName] = loadedModule
        LoadingState.loadingMetrics.modulesLoaded = LoadingState.loadingMetrics.modulesLoaded + 1
        LoadingState.loadingMetrics.totalLoadTime = LoadingState.loadingMetrics.totalLoadTime + loadTime
        
        print(string.format("📦 Loaded module: %s (%.2fms)", moduleName, loadTime * 1000))
        
        if callback then callback(true, loadedModule) end
        return loadedModule
    else
        warn("Failed to load module: " .. moduleName)
        if callback then callback(false, "Load failed") end
        return nil
    end
end

function LazyLoadingSystem.executeModuleLoad(module)
    -- Simulate module loading (in production, this would use actual module loading)
    if LoadingState.moduleChunks[module.name] then
        -- Load chunked module
        return LazyLoadingSystem.loadChunkedModule(module)
    else
        -- Load regular module
        return LazyLoadingSystem.loadRegularModule(module)
    end
end

function LazyLoadingSystem.loadChunkedModule(module)
    local chunks = LoadingState.moduleChunks[module.name]
    local loadedChunks = {}
    
    for _, chunk in ipairs(chunks) do
        local chunkData = LazyLoadingSystem.loadModuleChunk(chunk)
        if chunkData then
            table.insert(loadedChunks, chunkData)
            chunk.isLoaded = true
        else
            warn(string.format("Failed to load chunk %s", chunk.id))
            return nil
        end
    end
    
    -- Combine chunks into complete module
    local completeModule = LazyLoadingSystem.combineModuleChunks(loadedChunks)
    return completeModule
end

function LazyLoadingSystem.loadRegularModule(module)
    -- Simulate regular module loading
    local success, moduleData = pcall(function()
        -- In production, this would be: require(module.path)
        return {
            name = module.name,
            data = "Module data for " .. module.name,
            timestamp = tick()
        }
    end)
    
    return success and moduleData or nil
end

function LazyLoadingSystem.loadModuleChunk(chunk)
    -- Simulate chunk loading
    return {
        id = chunk.id,
        data = "Chunk data for " .. chunk.id,
        size = chunk.size
    }
end

function LazyLoadingSystem.combineModuleChunks(chunks)
    -- Combine chunks into complete module
    local combinedData = {}
    for _, chunk in ipairs(chunks) do
        table.insert(combinedData, chunk.data)
    end
    
    return {
        data = table.concat(combinedData, ""),
        chunkCount = #chunks,
        combined = true
    }
end

function LazyLoadingSystem.loadDependencies(dependencies)
    for _, dependency in ipairs(dependencies) do
        if not LoadingState.loadedModules[dependency] then
            LazyLoadingSystem.loadModule(dependency)
            return false -- Dependencies not yet loaded
        end
    end
    return true -- All dependencies loaded
end

function LazyLoadingSystem.queueModuleLoad(moduleName, callback)
    table.insert(LoadingState.loadingQueue, {
        type = "module",
        name = moduleName,
        callback = callback,
        timestamp = tick()
    })
end

-- ========================================
-- ASSET STREAMING SYSTEM
-- ========================================

function LazyLoadingSystem.setupAssetStreaming()
    if not LOADING_CONFIG.assetLoading.enableStreaming then
        return
    end
    
    LoadingState.streamingObjects = {}
    LoadingState.lodCache = {}
    
    -- Set up workspace streaming
    if workspace.StreamingEnabled ~= true then
        workspace.StreamingEnabled = true
        workspace.StreamingMinRadius = LOADING_CONFIG.assetLoading.streamingRadius * 0.5
        workspace.StreamingTargetRadius = LOADING_CONFIG.assetLoading.streamingRadius
    end
    
    print("🌊 Asset streaming system active")
end

function LazyLoadingSystem.registerStreamingObject(object, config)
    local streamingObject = {
        object = object,
        position = config.position or object:FindFirstChild("Position") and object.Position or Vector3.new(0, 0, 0),
        priority = config.priority or "normal",
        loadDistance = config.loadDistance or LOADING_CONFIG.strategies[config.priority or "normal"].preloadDistance,
        isLoaded = false,
        lodLevel = 0,
        assetIds = config.assetIds or {},
        size = config.size or 0
    }
    
    LoadingState.streamingObjects[object] = streamingObject
    return streamingObject
end

function LazyLoadingSystem.updateStreaming()
    if not LoadingState.streamingEnabled then
        return
    end
    
    local playerPosition = LoadingState.playerPosition
    local nearbyObjects = {}
    
    -- Find objects within streaming range
    for object, streamingData in pairs(LoadingState.streamingObjects) do
        local distance = (playerPosition - streamingData.position).Magnitude
        
        if distance <= streamingData.loadDistance then
            table.insert(nearbyObjects, {
                object = object,
                data = streamingData,
                distance = distance
            })
        end
    end
    
    -- Sort by distance and priority
    table.sort(nearbyObjects, function(a, b)
        if a.data.priority == b.data.priority then
            return a.distance < b.distance
        end
        return LOADING_CONFIG.strategies[a.data.priority].priority < LOADING_CONFIG.strategies[b.data.priority].priority
    end)
    
    -- Load nearby objects
    for _, objectData in ipairs(nearbyObjects) do
        LazyLoadingSystem.streamObject(objectData.object, objectData.data, objectData.distance)
    end
    
    LoadingState.nearbyObjects = nearbyObjects
    LoadingState.loadingMetrics.streamingEvents = LoadingState.loadingMetrics.streamingEvents + 1
end

function LazyLoadingSystem.streamObject(object, streamingData, distance)
    if streamingData.isLoaded then
        -- Update LOD based on distance
        LazyLoadingSystem.updateObjectLOD(object, streamingData, distance)
        return
    end
    
    -- Load object assets
    local strategy = LOADING_CONFIG.strategies[streamingData.priority]
    if #LoadingState.activeLoads < strategy.maxConcurrent then
        LazyLoadingSystem.loadObjectAssets(object, streamingData)
    else
        -- Queue for later loading
        LazyLoadingSystem.queueAssetLoad(object, streamingData)
    end
end

function LazyLoadingSystem.loadObjectAssets(object, streamingData)
    local loadId = HttpService:GenerateGUID(false)
    LoadingState.activeLoads[loadId] = {
        object = object,
        data = streamingData,
        startTime = tick()
    }
    
    -- Preload assets
    if #streamingData.assetIds > 0 then
        ContentProvider:PreloadAsync(streamingData.assetIds, function(assetId, assetFetchStatus)
            if assetFetchStatus == Enum.AssetFetchStatus.Success then
                LoadingState.loadingMetrics.assetsLoaded = LoadingState.loadingMetrics.assetsLoaded + 1
            end
        end)
    end
    
    -- Mark as loaded
    streamingData.isLoaded = true
    LoadingState.activeLoads[loadId] = nil
    
    LoadingState.stats.streamedAssets = LoadingState.stats.streamedAssets + 1
    print(string.format("🌊 Streamed object: %s", object.Name or "Unknown"))
end

function LazyLoadingSystem.updateObjectLOD(object, streamingData, distance)
    local lodLevel = LazyLoadingSystem.calculateLODLevel(distance, streamingData.loadDistance)
    
    if lodLevel ~= streamingData.lodLevel then
        LazyLoadingSystem.applyLOD(object, lodLevel)
        streamingData.lodLevel = lodLevel
    end
end

function LazyLoadingSystem.calculateLODLevel(distance, maxDistance)
    local ratio = distance / maxDistance
    local lodLevels = LOADING_CONFIG.assetLoading.lodLevels
    
    if ratio <= 0.3 then
        return 0 -- Highest quality
    elseif ratio <= 0.6 then
        return math.min(1, lodLevels - 1)
    elseif ratio <= 0.9 then
        return math.min(2, lodLevels - 1)
    else
        return lodLevels - 1 -- Lowest quality
    end
end

function LazyLoadingSystem.applyLOD(object, lodLevel)
    -- Apply Level of Detail settings to object
    -- This would typically involve texture resolution, mesh complexity, etc.
    if object:IsA("MeshPart") then
        -- Adjust mesh detail
        LazyLoadingSystem.adjustMeshLOD(object, lodLevel)
    elseif object:IsA("Part") then
        -- Adjust part detail
        LazyLoadingSystem.adjustPartLOD(object, lodLevel)
    end
end

function LazyLoadingSystem.adjustMeshLOD(meshPart, lodLevel)
    -- Placeholder for mesh LOD adjustment
    -- In production, this would adjust mesh complexity
end

function LazyLoadingSystem.adjustPartLOD(part, lodLevel)
    -- Placeholder for part LOD adjustment
    -- In production, this would adjust texture resolution, etc.
end

function LazyLoadingSystem.queueAssetLoad(object, streamingData)
    table.insert(LoadingState.loadingQueue, {
        type = "asset",
        object = object,
        data = streamingData,
        timestamp = tick()
    })
end

-- ========================================
-- LOADING QUEUE PROCESSOR
-- ========================================

function LazyLoadingSystem.startLoadingProcessor()
    LoadingState.connections.processor = task.spawn(function()
        while LoadingState.isInitialized do
            LazyLoadingSystem.processLoadingQueue()
            task.wait(1 / 60) -- Process at 60 FPS
        end
    end)
    
    print("⚙️ Loading queue processor started")
end

function LazyLoadingSystem.processLoadingQueue()
    local frameStartTime = tick()
    local maxFrameTime = LOADING_CONFIG.performance.maxLoadTimePerFrame / 1000
    
    while #LoadingState.loadingQueue > 0 do
        local frameTime = tick() - frameStartTime
        if frameTime >= maxFrameTime then
            break -- Don't exceed frame time budget
        end
        
        local loadItem = table.remove(LoadingState.loadingQueue, 1)
        LazyLoadingSystem.processLoadItem(loadItem)
    end
    
    -- Update streaming
    LazyLoadingSystem.updateStreaming()
end

function LazyLoadingSystem.processLoadItem(loadItem)
    if loadItem.type == "module" then
        LazyLoadingSystem.loadModule(loadItem.name, loadItem.callback)
    elseif loadItem.type == "asset" then
        LazyLoadingSystem.loadObjectAssets(loadItem.object, loadItem.data)
    end
end

-- ========================================
-- SPATIAL TRACKING
-- ========================================

function LazyLoadingSystem.initializeSpatialTracking()
    local player = Players.LocalPlayer
    
    -- Track player position for streaming
    LoadingState.connections.positionTracker = RunService.Heartbeat:Connect(function()
        if player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
            LoadingState.playerPosition = player.Character.HumanoidRootPart.Position
            LoadingState.lastPositionUpdate = tick()
        end
    end)
    
    print("📍 Spatial tracking initialized")
end

-- ========================================
-- PERFORMANCE MONITORING
-- ========================================

function LazyLoadingSystem.setupPerformanceMonitoring()
    -- CONVERTED: Polling loop → Event-driven performance monitoring
    local PerformanceMonitorEvent = Instance.new("BindableEvent")
    local monitorInterval = 15 -- Start with 15 seconds (was 5s)
    local lastFPS = 60
    
    local function schedulePerformanceCheck()
        if not LoadingState.isInitialized then
            return
        end
        
        task.delay(monitorInterval, function()
            if LoadingState.isInitialized then
                PerformanceMonitorEvent:Fire()
                schedulePerformanceCheck() -- Schedule next check
            end
        end)
    end
    
    PerformanceMonitorEvent.Event:Connect(function()
        local currentFPS = 1 / RunService.Heartbeat:Wait()
        local fpsChange = math.abs(currentFPS - lastFPS)
        
        -- Adaptive interval based on performance stability
        if fpsChange > 10 or currentFPS < 30 then -- Unstable performance
            monitorInterval = math.max(5, monitorInterval * 0.8) -- More frequent monitoring
            print(string.format("⚠️ Performance instability detected: %.1f FPS", currentFPS))
        else
            monitorInterval = math.min(60, monitorInterval * 1.1) -- Less frequent when stable
        end
        
        lastFPS = currentFPS
        LazyLoadingSystem.monitorLoadingPerformance()
        print(string.format("📊 Performance monitored: %.1f FPS (next check in %.0fs)", 
            currentFPS, monitorInterval))
    end)
    
    -- Start event-driven monitoring
    schedulePerformanceCheck()
    print("✅ Loading performance monitoring converted to event-driven system (NO POLLING)")
    
    print("📊 Loading performance monitoring active")
end

function LazyLoadingSystem.monitorLoadingPerformance()
    local currentFPS = 1 / RunService.Heartbeat:Wait()
    local memoryUsage = collectgarbage("count") / 1024 -- MB
    
    -- Adjust loading behavior based on performance
    if currentFPS < LOADING_CONFIG.performance.fpsThreshold then
        LazyLoadingSystem.reduceLoadingIntensity()
    elseif memoryUsage > LOADING_CONFIG.performance.memoryPressureThreshold then
        LazyLoadingSystem.triggerMemoryCleanup()
    end
    
    -- Update metrics
    LoadingState.loadingMetrics.currentFPS = currentFPS
    LoadingState.loadingMetrics.memoryUsage = memoryUsage
end

function LazyLoadingSystem.reduceLoadingIntensity()
    -- Reduce concurrent loads when performance is poor
    for strategy, config in pairs(LOADING_CONFIG.strategies) do
        config.maxConcurrent = math.max(1, math.floor(config.maxConcurrent * 0.7))
    end
    
    print("🐌 Reduced loading intensity due to low FPS")
end

function LazyLoadingSystem.triggerMemoryCleanup()
    -- Clean up non-essential loaded assets
    local cleanedCount = 0
    
    for object, streamingData in pairs(LoadingState.streamingObjects) do
        if streamingData.isLoaded and streamingData.priority == "background" then
            local distance = (LoadingState.playerPosition - streamingData.position).Magnitude
            if distance > streamingData.loadDistance * 1.5 then
                LazyLoadingSystem.unloadObject(object, streamingData)
                cleanedCount = cleanedCount + 1
            end
        end
    end
    
    collectgarbage("collect")
    print(string.format("🧹 Memory cleanup: unloaded %d objects", cleanedCount))
end

function LazyLoadingSystem.unloadObject(object, streamingData)
    streamingData.isLoaded = false
    streamingData.lodLevel = 0
    -- Additional cleanup logic would go here
end

-- ========================================
-- STARTUP SEQUENCE
-- ========================================

function LazyLoadingSystem.beginStartupSequence()
    local startupStartTime = tick()
    
    -- Load critical modules first
    LazyLoadingSystem.loadCriticalModules(function()
        -- Load important modules
        LazyLoadingSystem.loadImportantModules(function()
            -- Mark startup as complete
            LoadingState.startupComplete = true
            LoadingState.stats.startupTime = tick() - startupStartTime
            
            print(string.format("🚀 Startup sequence complete (%.2fs)", LoadingState.stats.startupTime))
            
            -- Begin background loading
            LazyLoadingSystem.beginBackgroundLoading()
        end)
    end)
end

function LazyLoadingSystem.loadCriticalModules(callback)
    local criticalStartTime = tick()
    local criticalModules = LoadingState.moduleLoadOrder.startup
    local loadedCount = 0
    
    local function onModuleLoaded()
        loadedCount = loadedCount + 1
        if loadedCount >= #criticalModules then
            LoadingState.stats.criticalLoadTime = tick() - criticalStartTime
            print(string.format("⚡ Critical modules loaded (%.2fs)", LoadingState.stats.criticalLoadTime))
            callback()
        end
    end
    
    for _, moduleName in ipairs(criticalModules) do
        LazyLoadingSystem.loadModule(moduleName, onModuleLoaded)
    end
end

function LazyLoadingSystem.loadImportantModules(callback)
    local importantModules = LoadingState.moduleLoadOrder.early
    local loadedCount = 0
    
    local function onModuleLoaded()
        loadedCount = loadedCount + 1
        if loadedCount >= #importantModules then
            callback()
        end
    end
    
    for _, moduleName in ipairs(importantModules) do
        LazyLoadingSystem.loadModule(moduleName, onModuleLoaded)
    end
end

function LazyLoadingSystem.beginBackgroundLoading()
    -- Start loading normal and background modules
    for _, phase in ipairs({"normal", "late", "background"}) do
        local modules = LoadingState.moduleLoadOrder[phase]
        if modules then
            for _, moduleName in ipairs(modules) do
                -- Queue for background loading
                table.insert(LoadingState.loadingQueue, {
                    type = "module",
                    name = moduleName,
                    timestamp = tick()
                })
            end
        end
    end
    
    LoadingState.stats.deferredLoads = #LoadingState.loadingQueue
    print(string.format("🔄 Background loading started (%d modules queued)", LoadingState.stats.deferredLoads))
end

-- ========================================
-- PUBLIC API
-- ========================================

function LazyLoadingSystem.requireModule(moduleName, callback)
    return LazyLoadingSystem.loadModule(moduleName, callback)
end

function LazyLoadingSystem.preloadAssets(assetIds, callback)
    local loadId = HttpService:GenerateGUID(false)
    
    ContentProvider:PreloadAsync(assetIds, function(assetId, assetFetchStatus)
        if assetFetchStatus == Enum.AssetFetchStatus.Success then
            LoadingState.loadingMetrics.assetsLoaded = LoadingState.loadingMetrics.assetsLoaded + 1
            LoadingState.loadingMetrics.cacheHits = LoadingState.loadingMetrics.cacheHits + 1
        else
            LoadingState.loadingMetrics.cacheMisses = LoadingState.loadingMetrics.cacheMisses + 1
        end
        
        if callback then
            callback(assetId, assetFetchStatus)
        end
    end)
    
    return loadId
end

function LazyLoadingSystem.enableStreaming(enabled)
    LoadingState.streamingEnabled = enabled
    print(string.format("🌊 Streaming %s", enabled and "enabled" or "disabled"))
end

function LazyLoadingSystem.getLoadingStats()
    return {
        metrics = LoadingState.loadingMetrics,
        stats = LoadingState.stats,
        queueLength = #LoadingState.loadingQueue,
        activeLoads = #LoadingState.activeLoads,
        startupComplete = LoadingState.startupComplete,
        modulesLoaded = LoadingState.loadingMetrics.modulesLoaded,
        assetsLoaded = LoadingState.loadingMetrics.assetsLoaded
    }
end

function LazyLoadingSystem.getModuleStatus(moduleName)
    local module = LoadingState.moduleRegistry[moduleName]
    if not module then
        return nil
    end
    
    return {
        name = module.name,
        isLoaded = module.isLoaded,
        loadTime = module.loadTime,
        priority = module.priority,
        hasChunks = LoadingState.moduleChunks[moduleName] ~= nil
    }
end

function LazyLoadingSystem.forceLoadModule(moduleName)
    -- Force immediate loading regardless of queue
    return LazyLoadingSystem.loadModule(moduleName)
end

function LazyLoadingSystem.clearCache()
    LoadingState.lodCache = {}
    collectgarbage("collect")
    print("🧹 Loading cache cleared")
end

function LazyLoadingSystem.shutdown()
    LoadingState.isInitialized = false
    
    for _, connection in pairs(LoadingState.connections) do
        if typeof(connection) == "thread" then
            task.cancel(connection)
        elseif typeof(connection) == "RBXScriptConnection" then
            connection:Disconnect()
        end
    end
    
    print("⚡ LazyLoadingSystem shutdown")
end

-- Initialize the lazy loading system
LazyLoadingSystem.initialize()

print("⚡ LazyLoadingSystem loaded with progressive loading capabilities")

return LazyLoadingSystem
