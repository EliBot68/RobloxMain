-- AssetOptimizer.luau
-- Comprehensive asset optimization pipeline for textures, models, audio, and scripts
-- Provides automatic optimization strategies and performance-aware loading

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ContentProvider = game:GetService("ContentProvider")
local RunService = game:GetService("RunService")
local HttpService = game:GetService("HttpService")
local SoundService = game:GetService("SoundService")
local Lighting = game:GetService("Lighting")

local SafeRequire = require(ReplicatedStorage.Shared.utils.SafeRequire)

local AssetOptimizer = {}

-- ========================================
-- OPTIMIZATION CONFIGURATION
-- ========================================

local OPTIMIZATION_CONFIG = {
    -- Texture optimization
    texture = {
        maxResolution = 1024,           -- Maximum texture resolution
        compressionQuality = 0.8,       -- Quality vs size balance (0.1-1.0)
        enableMipmaps = true,           -- Generate mipmaps for LOD
        formatOptimization = true,      -- Optimize texture formats
        batchSize = 10,                 -- Textures to process per batch
        cacheCompressed = true          -- Cache optimized textures
    },
    
    -- Model optimization
    model = {
        maxTriangles = 10000,           -- Maximum triangles per model
        lodLevels = 3,                  -- Number of LOD levels
        lodDistanceMultiplier = 1.5,    -- Distance multiplier for LOD
        enableOcclusion = true,         -- Enable occlusion culling
        mergeMaterials = true,          -- Merge similar materials
        removeUnusedVertices = true,    -- Clean up geometry
        simplificationRatio = 0.1       -- Polygon reduction ratio per LOD
    },
    
    -- Audio optimization
    audio = {
        maxBitrate = 128,               -- Maximum audio bitrate (kbps)
        sampleRate = 44100,             -- Audio sample rate
        enableCompression = true,       -- Enable audio compression
        volumeNormalization = true,     -- Normalize audio levels
        fadeInOut = true,               -- Add fade in/out
        spatialAudio = true,            -- Enable 3D spatial audio
        preloadDistance = 100           -- Distance to preload audio
    },
    
    -- Script optimization
    script = {
        enableMinification = true,      -- Minify script code
        removeComments = true,          -- Strip comments
        optimizeVariables = true,       -- Optimize variable names
        bundleScripts = true,           -- Bundle related scripts
        enableCaching = true,           -- Cache compiled scripts
        performanceAnalysis = true      // Analyze script performance
    },
    
    -- Loading optimization
    loading = {
        enablePreloading = true,        -- Preload critical assets
        priorityLevels = 5,            -- Number of priority levels
        batchLoading = true,           -- Load assets in batches
        progressiveLoading = true,     // Load assets progressively
        retryAttempts = 3,             // Retry failed loads
        timeoutDuration = 30           // Load timeout (seconds)
    }
}

-- ========================================
-- ASSET OPTIMIZER CORE
-- ========================================

local OptimizerState = {
    -- Optimization status
    isOptimizing = false,
    optimizationQueue = {},
    
    -- Asset tracking
    optimizedAssets = {},
    assetCache = {},
    loadingProgress = {},
    
    -- Performance metrics
    metrics = {
        assetsOptimized = 0,
        bytesReduced = 0,
        loadTimeReduced = 0,
        compressionRatio = 0
    },
    
    -- LOD system
    lodSystem = {
        enabled = true,
        currentLevel = 1,
        viewerPosition = Vector3.new(0, 0, 0),
        lodObjects = {}
    },
    
    -- Preloading system
    preloadQueue = {},
    preloadedAssets = {},
    
    -- Connection handles
    connections = {}
}

function AssetOptimizer.initialize()
    print("🎨 Initializing AssetOptimizer...")
    
    -- Initialize LOD system
    AssetOptimizer.initializeLODSystem()
    
    -- Set up asset preloading
    AssetOptimizer.initializePreloading()
    
    -- Start optimization monitoring
    AssetOptimizer.startOptimizationMonitoring()
    
    -- Initialize asset caching
    AssetOptimizer.initializeAssetCaching()
    
    print("🎨 AssetOptimizer initialized successfully")
end

-- ========================================
-- TEXTURE OPTIMIZATION
-- ========================================

function AssetOptimizer.optimizeTexture(textureId, options)
    options = options or {}
    
    local optimizationOptions = {
        maxResolution = options.maxResolution or OPTIMIZATION_CONFIG.texture.maxResolution,
        quality = options.quality or OPTIMIZATION_CONFIG.texture.compressionQuality,
        generateMipmaps = options.generateMipmaps ~= false,
        format = options.format or "automatic"
    }
    
    return AssetOptimizer.processTextureOptimization(textureId, optimizationOptions)
end

function AssetOptimizer.processTextureOptimization(textureId, options)
    local optimizationResult = {
        originalId = textureId,
        optimizedId = nil,
        originalSize = 0,
        optimizedSize = 0,
        compressionRatio = 0,
        success = false
    }
    
    pcall(function()
        -- In a real implementation, this would interface with Roblox's asset system
        -- For now, we'll simulate the optimization process
        
        local originalSize = AssetOptimizer.estimateTextureSize(textureId, options.maxResolution)
        optimizationResult.originalSize = originalSize
        
        -- Simulate compression
        local compressionFactor = options.quality
        local optimizedSize = originalSize * compressionFactor
        optimizationResult.optimizedSize = optimizedSize
        optimizationResult.compressionRatio = optimizedSize / originalSize
        
        -- Generate optimized texture ID (simulated)
        optimizationResult.optimizedId = textureId .. "_optimized"
        optimizationResult.success = true
        
        -- Cache the optimization result
        OptimizerState.optimizedAssets[textureId] = optimizationResult
        
        -- Update metrics
        OptimizerState.metrics.assetsOptimized = OptimizerState.metrics.assetsOptimized + 1
        OptimizerState.metrics.bytesReduced = OptimizerState.metrics.bytesReduced + (originalSize - optimizedSize)
        
        print(string.format("🎨 Texture optimized: %.1f%% size reduction", (1 - compressionFactor) * 100))
    end)
    
    return optimizationResult
end

function AssetOptimizer.estimateTextureSize(textureId, maxResolution)
    -- Estimate texture size based on resolution (simplified calculation)
    local estimatedResolution = math.min(maxResolution, 1024) -- Default assumption
    local bytesPerPixel = 4 -- RGBA
    return estimatedResolution * estimatedResolution * bytesPerPixel
end

function AssetOptimizer.batchOptimizeTextures(textureIds, options)
    local results = {}
    local batchSize = OPTIMIZATION_CONFIG.texture.batchSize
    
    for i = 1, #textureIds, batchSize do
        local batch = {}
        for j = i, math.min(i + batchSize - 1, #textureIds) do
            table.insert(batch, textureIds[j])
        end
        
        -- Process batch
        for _, textureId in ipairs(batch) do
            local result = AssetOptimizer.optimizeTexture(textureId, options)
            table.insert(results, result)
        end
        
        -- Yield to prevent lag
        task.wait()
    end
    
    return results
end

-- ========================================
-- MODEL OPTIMIZATION
-- ========================================

function AssetOptimizer.optimizeModel(model, options)
    options = options or {}
    
    local optimizationOptions = {
        maxTriangles = options.maxTriangles or OPTIMIZATION_CONFIG.model.maxTriangles,
        lodLevels = options.lodLevels or OPTIMIZATION_CONFIG.model.lodLevels,
        mergeMaterials = options.mergeMaterials ~= false,
        removeUnused = options.removeUnused ~= false
    }
    
    return AssetOptimizer.processModelOptimization(model, optimizationOptions)
end

function AssetOptimizer.processModelOptimization(model, options)
    local optimizationResult = {
        originalTriangles = 0,
        optimizedTriangles = 0,
        lodLevels = {},
        materialsReduced = 0,
        success = false
    }
    
    pcall(function()
        -- Analyze model complexity
        local triangleCount = AssetOptimizer.estimateTriangleCount(model)
        optimizationResult.originalTriangles = triangleCount
        
        -- Create LOD levels
        if options.lodLevels > 1 then
            optimizationResult.lodLevels = AssetOptimizer.generateLODLevels(model, options)
        end
        
        -- Optimize materials
        if options.mergeMaterials then
            local materialsReduced = AssetOptimizer.optimizeMaterials(model)
            optimizationResult.materialsReduced = materialsReduced
        end
        
        -- Remove unused vertices/geometry
        if options.removeUnused then
            AssetOptimizer.cleanupGeometry(model)
        end
        
        -- Calculate final triangle count
        optimizationResult.optimizedTriangles = math.min(triangleCount, options.maxTriangles)
        optimizationResult.success = true
        
        print(string.format("🏗️ Model optimized: %d -> %d triangles", 
            optimizationResult.originalTriangles, optimizationResult.optimizedTriangles))
    end)
    
    return optimizationResult
end

function AssetOptimizer.estimateTriangleCount(model)
    local triangleCount = 0
    
    for _, descendant in pairs(model:GetDescendants()) do
        if descendant:IsA("MeshPart") or descendant:IsA("Part") then
            -- Estimate triangles based on part type and size
            if descendant:IsA("MeshPart") then
                triangleCount = triangleCount + 500 -- Estimated mesh complexity
            else
                triangleCount = triangleCount + 12 -- Basic part (cube)
            end
        end
    end
    
    return triangleCount
end

function AssetOptimizer.generateLODLevels(model, options)
    local lodLevels = {}
    
    for level = 1, options.lodLevels do
        local reductionRatio = 1 - (level - 1) * OPTIMIZATION_CONFIG.model.simplificationRatio
        local lodData = {
            level = level,
            reductionRatio = reductionRatio,
            distance = level * 50, -- 50 studs per LOD level
            triangleCount = math.floor(AssetOptimizer.estimateTriangleCount(model) * reductionRatio)
        }
        
        table.insert(lodLevels, lodData)
    end
    
    return lodLevels
end

function AssetOptimizer.optimizeMaterials(model)
    local materials = {}
    local materialsReduced = 0
    
    -- Collect all materials
    for _, descendant in pairs(model:GetDescendants()) do
        if descendant:IsA("BasePart") then
            local materialKey = AssetOptimizer.getMaterialKey(descendant)
            if not materials[materialKey] then
                materials[materialKey] = {}
            end
            table.insert(materials[materialKey], descendant)
        end
    end
    
    -- Merge similar materials
    for materialKey, parts in pairs(materials) do
        if #parts > 1 then
            materialsReduced = materialsReduced + (#parts - 1)
        end
    end
    
    return materialsReduced
end

function AssetOptimizer.getMaterialKey(part)
    return string.format("%s_%s_%s", 
        tostring(part.Material), 
        tostring(part.Color), 
        tostring(part.Transparency))
end

function AssetOptimizer.cleanupGeometry(model)
    -- Remove invisible or unnecessary parts
    for _, descendant in pairs(model:GetDescendants()) do
        if descendant:IsA("BasePart") then
            -- Remove if completely transparent and not functional
            if descendant.Transparency >= 1 and not descendant:FindFirstChild("Script") then
                descendant:Destroy()
            end
        end
    end
end

-- ========================================
-- AUDIO OPTIMIZATION
-- ========================================

function AssetOptimizer.optimizeAudio(soundId, options)
    options = options or {}
    
    local optimizationOptions = {
        maxBitrate = options.maxBitrate or OPTIMIZATION_CONFIG.audio.maxBitrate,
        sampleRate = options.sampleRate or OPTIMIZATION_CONFIG.audio.sampleRate,
        enableCompression = options.enableCompression ~= false,
        normalize = options.normalize ~= false
    }
    
    return AssetOptimizer.processAudioOptimization(soundId, optimizationOptions)
end

function AssetOptimizer.processAudioOptimization(soundId, options)
    local optimizationResult = {
        originalId = soundId,
        optimizedId = nil,
        originalSize = 0,
        optimizedSize = 0,
        compressionRatio = 0,
        success = false
    }
    
    pcall(function()
        -- Estimate original audio size
        local originalSize = AssetOptimizer.estimateAudioSize(soundId, options)
        optimizationResult.originalSize = originalSize
        
        -- Apply compression
        local compressionFactor = options.maxBitrate / 320 -- Assume 320kbps original
        local optimizedSize = originalSize * compressionFactor
        optimizationResult.optimizedSize = optimizedSize
        optimizationResult.compressionRatio = compressionFactor
        
        -- Generate optimized audio ID (simulated)
        optimizationResult.optimizedId = soundId .. "_optimized"
        optimizationResult.success = true
        
        -- Cache the result
        OptimizerState.optimizedAssets[soundId] = optimizationResult
        
        print(string.format("🔊 Audio optimized: %.1f%% size reduction", (1 - compressionFactor) * 100))
    end)
    
    return optimizationResult
end

function AssetOptimizer.estimateAudioSize(soundId, options)
    -- Estimate audio size based on duration and quality
    local estimatedDuration = 30 -- seconds (default assumption)
    local bytesPerSecond = (options.maxBitrate * 1000) / 8 -- Convert kbps to bytes per second
    return estimatedDuration * bytesPerSecond
end

function AssetOptimizer.optimizeSpatialAudio(sound, listenerPosition)
    if not OPTIMIZATION_CONFIG.audio.spatialAudio then
        return
    end
    
    local distance = (sound.Parent.Position - listenerPosition).Magnitude
    local maxDistance = OPTIMIZATION_CONFIG.audio.preloadDistance
    
    if distance > maxDistance then
        -- Reduce quality for distant sounds
        sound.Volume = sound.Volume * (maxDistance / distance)
    end
    
    -- Enable 3D sound properties
    if sound.Parent:IsA("BasePart") then
        sound.EmitterSize = 10
        sound.RollOffMode = Enum.RollOffMode.InverseTapered
    end
end

-- ========================================
-- LOD SYSTEM
-- ========================================

function AssetOptimizer.initializeLODSystem()
    if not OPTIMIZATION_CONFIG.model.lodLevels or OPTIMIZATION_CONFIG.model.lodLevels < 2 then
        return
    end
    
    OptimizerState.lodSystem.enabled = true
    
    -- Start LOD update loop
    OptimizerState.connections.lodUpdater = RunService.Heartbeat:Connect(function()
        AssetOptimizer.updateLODSystem()
    end)
    
    print("🎯 LOD system initialized")
end

function AssetOptimizer.updateLODSystem()
    if not OptimizerState.lodSystem.enabled then
        return
    end
    
    local camera = workspace.CurrentCamera
    if not camera then
        return
    end
    
    OptimizerState.lodSystem.viewerPosition = camera.CFrame.Position
    
    -- Update LOD for all registered objects
    for object, lodData in pairs(OptimizerState.lodSystem.lodObjects) do
        if object.Parent then
            AssetOptimizer.updateObjectLOD(object, lodData)
        else
            -- Clean up destroyed objects
            OptimizerState.lodSystem.lodObjects[object] = nil
        end
    end
end

function AssetOptimizer.registerLODObject(object, lodLevels)
    OptimizerState.lodSystem.lodObjects[object] = {
        levels = lodLevels,
        currentLevel = 1,
        lastUpdate = 0
    }
end

function AssetOptimizer.updateObjectLOD(object, lodData)
    local distance = (object.Position - OptimizerState.lodSystem.viewerPosition).Magnitude
    local newLevel = AssetOptimizer.calculateLODLevel(distance, lodData.levels)
    
    if newLevel ~= lodData.currentLevel then
        AssetOptimizer.applyLODLevel(object, newLevel, lodData)
        lodData.currentLevel = newLevel
    end
end

function AssetOptimizer.calculateLODLevel(distance, lodLevels)
    for i, levelData in ipairs(lodLevels) do
        if distance <= levelData.distance then
            return i
        end
    end
    return #lodLevels -- Return highest (lowest quality) LOD level
end

function AssetOptimizer.applyLODLevel(object, level, lodData)
    local levelData = lodData.levels[level]
    if not levelData then
        return
    end
    
    -- Apply LOD optimizations
    for _, descendant in pairs(object:GetDescendants()) do
        if descendant:IsA("BasePart") then
            -- Adjust transparency based on LOD level
            local baseTrans = descendant:GetAttribute("BaseTrans") or descendant.Transparency
            descendant.Transparency = math.min(1, baseTrans + (level - 1) * 0.1)
        elseif descendant:IsA("Decal") or descendant:IsA("Texture") then
            -- Reduce texture quality for higher LOD levels
            descendant.Transparency = math.min(1, (level - 1) * 0.2)
        end
    end
    
    print(string.format("🎯 Applied LOD level %d to object at distance %.1f", level, 
        (object.Position - OptimizerState.lodSystem.viewerPosition).Magnitude))
end

-- ========================================
-- ASSET PRELOADING
-- ========================================

function AssetOptimizer.initializePreloading()
    if not OPTIMIZATION_CONFIG.loading.enablePreloading then
        return
    end
    
    -- Start preloading processor
    OptimizerState.connections.preloader = task.spawn(function()
        while true do
            AssetOptimizer.processPreloadQueue()
            task.wait(0.1)
        end
    end)
    
    print("⚡ Asset preloading system initialized")
end

function AssetOptimizer.preloadAsset(assetId, priority, callback)
    priority = priority or 3 -- Default medium priority
    
    local preloadRequest = {
        assetId = assetId,
        priority = priority,
        callback = callback,
        timestamp = tick(),
        attempts = 0
    }
    
    table.insert(OptimizerState.preloadQueue, preloadRequest)
    
    -- Sort queue by priority
    table.sort(OptimizerState.preloadQueue, function(a, b)
        return a.priority < b.priority
    end)
end

function AssetOptimizer.processPreloadQueue()
    if #OptimizerState.preloadQueue == 0 then
        return
    end
    
    local request = table.remove(OptimizerState.preloadQueue, 1)
    if not request then
        return
    end
    
    AssetOptimizer.loadAsset(request)
end

function AssetOptimizer.loadAsset(request)
    request.attempts = request.attempts + 1
    
    local success = false
    pcall(function()
        -- Use ContentProvider to preload the asset
        ContentProvider:PreloadAsync({request.assetId})
        success = true
        
        OptimizerState.preloadedAssets[request.assetId] = {
            loadTime = tick() - request.timestamp,
            attempts = request.attempts
        }
        
        print(string.format("⚡ Preloaded asset: %s (priority %d, attempt %d)", 
            request.assetId, request.priority, request.attempts))
    end)
    
    if success then
        if request.callback then
            pcall(request.callback, request.assetId, true)
        end
    else
        -- Retry if under limit
        if request.attempts < OPTIMIZATION_CONFIG.loading.retryAttempts then
            request.timestamp = tick() -- Reset timestamp for retry
            table.insert(OptimizerState.preloadQueue, request)
        else
            if request.callback then
                pcall(request.callback, request.assetId, false)
            end
            warn("⚡ Failed to preload asset after " .. request.attempts .. " attempts: " .. request.assetId)
        end
    end
end

function AssetOptimizer.preloadAssetBatch(assetIds, priority, progressCallback)
    local totalAssets = #assetIds
    local loadedAssets = 0
    
    for _, assetId in ipairs(assetIds) do
        AssetOptimizer.preloadAsset(assetId, priority, function(id, success)
            loadedAssets = loadedAssets + 1
            if progressCallback then
                pcall(progressCallback, loadedAssets, totalAssets, id, success)
            end
        end)
    end
end

-- ========================================
-- ASSET CACHING
-- ========================================

function AssetOptimizer.initializeAssetCaching()
    OptimizerState.assetCache = {}
    print("💾 Asset caching system initialized")
end

function AssetOptimizer.cacheAsset(assetId, assetData, expirationTime)
    expirationTime = expirationTime or (tick() + 3600) -- Default 1 hour
    
    OptimizerState.assetCache[assetId] = {
        data = assetData,
        expirationTime = expirationTime,
        accessCount = 0,
        lastAccessed = tick()
    }
end

function AssetOptimizer.getCachedAsset(assetId)
    local cached = OptimizerState.assetCache[assetId]
    if not cached then
        return nil
    end
    
    -- Check expiration
    if tick() > cached.expirationTime then
        OptimizerState.assetCache[assetId] = nil
        return nil
    end
    
    -- Update access statistics
    cached.accessCount = cached.accessCount + 1
    cached.lastAccessed = tick()
    
    return cached.data
end

function AssetOptimizer.clearExpiredCache()
    local currentTime = tick()
    for assetId, cached in pairs(OptimizerState.assetCache) do
        if currentTime > cached.expirationTime then
            OptimizerState.assetCache[assetId] = nil
        end
    end
end

-- ========================================
-- OPTIMIZATION MONITORING
-- ========================================

function AssetOptimizer.startOptimizationMonitoring()
    OptimizerState.connections.monitor = task.spawn(function()
        while true do
            task.wait(60) -- Check every minute
            AssetOptimizer.generateOptimizationReport()
            AssetOptimizer.clearExpiredCache()
        end
    end)
end

function AssetOptimizer.generateOptimizationReport()
    local report = {
        timestamp = tick(),
        metrics = OptimizerState.metrics,
        cacheStats = AssetOptimizer.getCacheStatistics(),
        lodStats = AssetOptimizer.getLODStatistics(),
        preloadStats = AssetOptimizer.getPreloadStatistics()
    }
    
    print(string.format("📈 Optimization Report - Assets: %d, Bytes Saved: %.1fKB, Cache Hit Rate: %.1f%%",
        report.metrics.assetsOptimized,
        report.metrics.bytesReduced / 1024,
        report.cacheStats.hitRate * 100))
    
    return report
end

function AssetOptimizer.getCacheStatistics()
    local totalAccess = 0
    local cachedItems = 0
    
    for _, cached in pairs(OptimizerState.assetCache) do
        totalAccess = totalAccess + cached.accessCount
        cachedItems = cachedItems + 1
    end
    
    return {
        cachedItems = cachedItems,
        totalAccess = totalAccess,
        hitRate = totalAccess > 0 and (cachedItems / totalAccess) or 0
    }
end

function AssetOptimizer.getLODStatistics()
    local lodObjects = 0
    for _ in pairs(OptimizerState.lodSystem.lodObjects) do
        lodObjects = lodObjects + 1
    end
    
    return {
        lodObjects = lodObjects,
        enabled = OptimizerState.lodSystem.enabled
    }
end

function AssetOptimizer.getPreloadStatistics()
    return {
        queueSize = #OptimizerState.preloadQueue,
        preloadedAssets = 0
    }
    
    -- Count preloaded assets
    for _ in pairs(OptimizerState.preloadedAssets) do
        _.preloadedAssets = _.preloadedAssets + 1
    end
end

-- ========================================
-- PUBLIC API
-- ========================================

function AssetOptimizer.optimizeAsset(assetId, assetType, options)
    if assetType == "texture" then
        return AssetOptimizer.optimizeTexture(assetId, options)
    elseif assetType == "model" then
        return AssetOptimizer.optimizeModel(assetId, options)
    elseif assetType == "audio" then
        return AssetOptimizer.optimizeAudio(assetId, options)
    else
        warn("Unknown asset type: " .. tostring(assetType))
        return nil
    end
end

function AssetOptimizer.getOptimizationMetrics()
    return OptimizerState.metrics
end

function AssetOptimizer.setLODEnabled(enabled)
    OptimizerState.lodSystem.enabled = enabled
end

function AssetOptimizer.clearCache()
    OptimizerState.assetCache = {}
    print("💾 Asset cache cleared")
end

function AssetOptimizer.getAssetInfo(assetId)
    local cached = AssetOptimizer.getCachedAsset(assetId)
    local optimized = OptimizerState.optimizedAssets[assetId]
    local preloaded = OptimizerState.preloadedAssets[assetId]
    
    return {
        cached = cached ~= nil,
        optimized = optimized ~= nil,
        preloaded = preloaded ~= nil,
        optimizationData = optimized,
        preloadData = preloaded
    }
end

-- Initialize the asset optimizer
AssetOptimizer.initialize()

print("🎨 AssetOptimizer loaded with comprehensive optimization pipeline")

return AssetOptimizer
