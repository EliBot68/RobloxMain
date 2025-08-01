-- AssetPipelineSystem.luau
-- Professional asset pipeline with automated optimization and compression
-- Provides comprehensive asset processing, optimization, and delivery management

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local HttpService = game:GetService("HttpService")
local ContentProvider = game:GetService("ContentProvider")
local SoundService = game:GetService("SoundService")

local SafeRequire = require(ReplicatedStorage.Shared.utils.SafeRequire)

local AssetPipelineSystem = {}

-- ========================================
-- ASSET PIPELINE CONFIGURATION
-- ========================================

local PIPELINE_CONFIG = {
    -- Pipeline settings
    pipeline = {
        enableAutomaticOptimization = true,
        enableCompression = true,
        enableValidation = true,
        enableBatching = true,
        enableCaching = true,
        maxConcurrentProcessing = 5,
        processingTimeout = 30000
    },
    
    -- Asset optimization settings
    optimization = {
        images = {
            enableResize = true,
            enableCompression = true,
            enableFormatConversion = true,
            maxWidth = 1024,
            maxHeight = 1024,
            compressionQuality = 85,
            preferredFormat = "png"
        },
        
        audio = {
            enableCompression = true,
            enableNormalization = true,
            enableTrimming = true,
            maxBitrate = 128,
            preferredFormat = "ogg",
            normalizeVolume = -14 -- LUFS
        },
        
        models = {
            enableLODGeneration = true,
            enableTextureOptimization = true,
            enableMeshOptimization = true,
            maxTriangles = 10000,
            maxTextureSize = 512,
            lodLevels = 3
        }
    },
    
    -- Quality settings
    quality = {
        lowQuality = {
            imageResolution = 256,
            audioBitrate = 64,
            modelTriangles = 2500
        },
        
        mediumQuality = {
            imageResolution = 512,
            audioBitrate = 96,
            modelTriangles = 5000
        },
        
        highQuality = {
            imageResolution = 1024,
            audioBitrate = 128,
            modelTriangles = 10000
        }
    },
    
    -- Processing stages
    stages = {
        validation = true,
        preprocessing = true,
        optimization = true,
        compression = true,
        postprocessing = true,
        packaging = true
    }
}

-- ========================================
-- ASSET PIPELINE STATE
-- ========================================

local PipelineState = {
    -- Processing queues
    processingQueue = {},
    activeProcessing = {},
    completedProcessing = {},
    
    -- Asset registry
    assetRegistry = {},
    optimizedAssets = {},
    assetMetadata = {},
    
    -- Pipeline stages
    pipelineStages = {},
    stageTasks = {},
    
    -- Processing results
    processingResults = {},
    optimizationMetrics = {},
    
    -- Statistics
    stats = {
        assetsProcessed = 0,
        totalSizeBefore = 0,
        totalSizeAfter = 0,
        compressionRatio = 0,
        processingTime = 0,
        failedProcessing = 0
    }
}

function AssetPipelineSystem.initialize()
    print("🏭 Initializing AssetPipelineSystem...")
    
    -- Set up pipeline stages
    AssetPipelineSystem.setupPipelineStages()
    
    -- Initialize asset processors
    AssetPipelineSystem.initializeAssetProcessors()
    
    -- Set up optimization engines
    AssetPipelineSystem.setupOptimizationEngines()
    
    -- Initialize quality control
    AssetPipelineSystem.initializeQualityControl()
    
    -- Start pipeline processing
    AssetPipelineSystem.startPipelineProcessing()
    
    print("🏭 AssetPipelineSystem initialized successfully")
end

-- ========================================
-- PIPELINE STAGES
-- ========================================

function AssetPipelineSystem.setupPipelineStages()
    PipelineState.pipelineStages = {
        validation = AssetPipelineSystem.createValidationStage(),
        preprocessing = AssetPipelineSystem.createPreprocessingStage(),
        optimization = AssetPipelineSystem.createOptimizationStage(),
        compression = AssetPipelineSystem.createCompressionStage(),
        postprocessing = AssetPipelineSystem.createPostprocessingStage(),
        packaging = AssetPipelineSystem.createPackagingStage()
    }
    
    print("🔄 Pipeline stages initialized")
end

function AssetPipelineSystem.createValidationStage()
    return {
        name = "validation",
        description = "Validate asset format, size, and quality",
        process = function(asset)
            return AssetPipelineSystem.validateAsset(asset)
        end,
        timeout = 5000,
        retries = 2
    }
end

function AssetPipelineSystem.createPreprocessingStage()
    return {
        name = "preprocessing",
        description = "Prepare assets for optimization",
        process = function(asset)
            return AssetPipelineSystem.preprocessAsset(asset)
        end,
        timeout = 10000,
        retries = 1
    }
end

function AssetPipelineSystem.createOptimizationStage()
    return {
        name = "optimization",
        description = "Optimize asset size and quality",
        process = function(asset)
            return AssetPipelineSystem.optimizeAsset(asset)
        end,
        timeout = 30000,
        retries = 2
    }
end

function AssetPipelineSystem.createCompressionStage()
    return {
        name = "compression",
        description = "Apply compression algorithms",
        process = function(asset)
            return AssetPipelineSystem.compressAsset(asset)
        end,
        timeout = 15000,
        retries = 1
    }
end

function AssetPipelineSystem.createPostprocessingStage()
    return {
        name = "postprocessing",
        description = "Final processing and cleanup",
        process = function(asset)
            return AssetPipelineSystem.postprocessAsset(asset)
        end,
        timeout = 5000,
        retries = 1
    }
end

function AssetPipelineSystem.createPackagingStage()
    return {
        name = "packaging",
        description = "Package and finalize assets",
        process = function(asset)
            return AssetPipelineSystem.packageAsset(asset)
        end,
        timeout = 10000,
        retries = 1
    }
end

-- ========================================
-- ASSET PROCESSORS
-- ========================================

function AssetPipelineSystem.initializeAssetProcessors()
    PipelineState.assetProcessors = {
        image = AssetPipelineSystem.createImageProcessor(),
        audio = AssetPipelineSystem.createAudioProcessor(),
        model = AssetPipelineSystem.createModelProcessor(),
        animation = AssetPipelineSystem.createAnimationProcessor(),
        script = AssetPipelineSystem.createScriptProcessor()
    }
    
    print("🔧 Asset processors initialized")
end

function AssetPipelineSystem.createImageProcessor()
    return {
        supportedFormats = {"png", "jpg", "jpeg", "bmp", "tga"},
        
        validate = function(asset)
            return AssetPipelineSystem.validateImageAsset(asset)
        end,
        
        optimize = function(asset, options)
            return AssetPipelineSystem.optimizeImageAsset(asset, options)
        end,
        
        compress = function(asset, options)
            return AssetPipelineSystem.compressImageAsset(asset, options)
        end,
        
        generateVariants = function(asset)
            return AssetPipelineSystem.generateImageVariants(asset)
        end
    }
end

function AssetPipelineSystem.createAudioProcessor()
    return {
        supportedFormats = {"mp3", "ogg", "wav", "m4a"},
        
        validate = function(asset)
            return AssetPipelineSystem.validateAudioAsset(asset)
        end,
        
        optimize = function(asset, options)
            return AssetPipelineSystem.optimizeAudioAsset(asset, options)
        end,
        
        compress = function(asset, options)
            return AssetPipelineSystem.compressAudioAsset(asset, options)
        end,
        
        normalize = function(asset)
            return AssetPipelineSystem.normalizeAudioAsset(asset)
        end
    }
end

function AssetPipelineSystem.createModelProcessor()
    return {
        supportedFormats = {"fbx", "obj", "dae", "3ds"},
        
        validate = function(asset)
            return AssetPipelineSystem.validateModelAsset(asset)
        end,
        
        optimize = function(asset, options)
            return AssetPipelineSystem.optimizeModelAsset(asset, options)
        end,
        
        generateLOD = function(asset)
            return AssetPipelineSystem.generateModelLOD(asset)
        end,
        
        optimizeTextures = function(asset)
            return AssetPipelineSystem.optimizeModelTextures(asset)
        end
    }
end

function AssetPipelineSystem.createAnimationProcessor()
    return {
        supportedFormats = {"fbx", "dae"},
        
        validate = function(asset)
            return AssetPipelineSystem.validateAnimationAsset(asset)
        end,
        
        optimize = function(asset, options)
            return AssetPipelineSystem.optimizeAnimationAsset(asset, options)
        end,
        
        compress = function(asset)
            return AssetPipelineSystem.compressAnimationAsset(asset)
        end
    }
end

function AssetPipelineSystem.createScriptProcessor()
    return {
        supportedFormats = {"lua", "luau"},
        
        validate = function(asset)
            return AssetPipelineSystem.validateScriptAsset(asset)
        end,
        
        optimize = function(asset, options)
            return AssetPipelineSystem.optimizeScriptAsset(asset, options)
        end,
        
        minify = function(asset)
            return AssetPipelineSystem.minifyScriptAsset(asset)
        end
    }
end

-- ========================================
-- ASSET PROCESSING
-- ========================================

function AssetPipelineSystem.processAsset(assetInfo, options)
    options = options or {}
    
    local processingTask = {
        id = HttpService:GenerateGUID(false),
        asset = assetInfo,
        options = options,
        status = "queued",
        stages = {},
        startTime = tick(),
        endTime = nil,
        results = {}
    }
    
    table.insert(PipelineState.processingQueue, processingTask)
    
    print(string.format("📥 Asset queued for processing: %s", assetInfo.name))
    
    return processingTask.id
end

function AssetPipelineSystem.executeProcessingTask(task)
    task.status = "processing"
    PipelineState.activeProcessing[task.id] = task
    
    print(string.format("🔄 Processing asset: %s", task.asset.name))
    
    local success = true
    local finalAsset = task.asset
    
    -- Execute pipeline stages
    for stageName, stage in pairs(PipelineState.pipelineStages) do
        if PIPELINE_CONFIG.stages[stageName] then
            local stageResult = AssetPipelineSystem.executeStage(stage, finalAsset, task)
            
            task.stages[stageName] = stageResult
            
            if stageResult.success then
                finalAsset = stageResult.asset
            else
                success = false
                task.status = "failed"
                task.error = stageResult.error
                break
            end
        end
    end
    
    if success then
        task.status = "completed"
        task.results = finalAsset
        PipelineState.optimizedAssets[task.asset.id] = finalAsset
    end
    
    task.endTime = tick()
    task.duration = task.endTime - task.startTime
    
    PipelineState.activeProcessing[task.id] = nil
    PipelineState.completedProcessing[task.id] = task
    
    PipelineState.stats.assetsProcessed = PipelineState.stats.assetsProcessed + 1
    PipelineState.stats.processingTime = PipelineState.stats.processingTime + task.duration
    
    if not success then
        PipelineState.stats.failedProcessing = PipelineState.stats.failedProcessing + 1
    end
    
    print(string.format("✅ Asset processing %s: %s (%.2fs)", 
        success and "completed" or "failed", task.asset.name, task.duration))
    
    return success
end

function AssetPipelineSystem.executeStage(stage, asset, task)
    local stageResult = {
        stage = stage.name,
        startTime = tick(),
        endTime = nil,
        success = false,
        asset = asset,
        error = nil,
        metrics = {}
    }
    
    local success, result = pcall(stage.process, asset)
    
    stageResult.endTime = tick()
    stageResult.duration = stageResult.endTime - stageResult.startTime
    
    if success then
        stageResult.success = true
        stageResult.asset = result.asset or asset
        stageResult.metrics = result.metrics or {}
    else
        stageResult.success = false
        stageResult.error = result
    end
    
    return stageResult
end

-- ========================================
-- ASSET VALIDATION
-- ========================================

function AssetPipelineSystem.validateAsset(asset)
    local validation = {
        asset = asset,
        valid = true,
        issues = {},
        metrics = {}
    }
    
    -- Get asset processor
    local processor = PipelineState.assetProcessors[asset.type]
    if not processor then
        validation.valid = false
        table.insert(validation.issues, string.format("No processor available for asset type: %s", asset.type))
        return validation
    end
    
    -- Run type-specific validation
    local typeValidation = processor.validate(asset)
    validation.valid = typeValidation.valid
    
    if not typeValidation.valid then
        for _, issue in ipairs(typeValidation.issues) do
            table.insert(validation.issues, issue)
        end
    end
    
    validation.metrics.validationTime = tick() - (validation.startTime or tick())
    
    return validation
end

function AssetPipelineSystem.validateImageAsset(asset)
    local validation = {valid = true, issues = {}}
    
    -- Check file size
    if asset.size > 10 * 1024 * 1024 then -- 10MB
        validation.valid = false
        table.insert(validation.issues, "Image file size exceeds 10MB limit")
    end
    
    -- Check dimensions (simulated)
    local width = asset.metadata.width or 512
    local height = asset.metadata.height or 512
    
    if width > 2048 or height > 2048 then
        validation.valid = false
        table.insert(validation.issues, "Image dimensions exceed 2048x2048 limit")
    end
    
    -- Check format
    local format = asset.format or "png"
    local supportedFormats = {"png", "jpg", "jpeg", "bmp"}
    local formatSupported = false
    
    for _, supportedFormat in ipairs(supportedFormats) do
        if format:lower() == supportedFormat then
            formatSupported = true
            break
        end
    end
    
    if not formatSupported then
        validation.valid = false
        table.insert(validation.issues, string.format("Unsupported image format: %s", format))
    end
    
    return validation
end

function AssetPipelineSystem.validateAudioAsset(asset)
    local validation = {valid = true, issues = {}}
    
    -- Check file size
    if asset.size > 50 * 1024 * 1024 then -- 50MB
        validation.valid = false
        table.insert(validation.issues, "Audio file size exceeds 50MB limit")
    end
    
    -- Check duration
    local duration = asset.metadata.duration or 30
    if duration > 300 then -- 5 minutes
        validation.valid = false
        table.insert(validation.issues, "Audio duration exceeds 5 minute limit")
    end
    
    -- Check bitrate
    local bitrate = asset.metadata.bitrate or 128
    if bitrate > 320 then
        table.insert(validation.issues, "High bitrate detected - consider compression")
    end
    
    return validation
end

function AssetPipelineSystem.validateModelAsset(asset)
    local validation = {valid = true, issues = {}}
    
    -- Check file size
    if asset.size > 100 * 1024 * 1024 then -- 100MB
        validation.valid = false
        table.insert(validation.issues, "Model file size exceeds 100MB limit")
    end
    
    -- Check triangle count
    local triangles = asset.metadata.triangles or 5000
    if triangles > 50000 then
        validation.valid = false
        table.insert(validation.issues, "Model triangle count exceeds 50,000 limit")
    end
    
    return validation
end

function AssetPipelineSystem.validateAnimationAsset(asset)
    local validation = {valid = true, issues = {}}
    
    -- Check file size
    if asset.size > 20 * 1024 * 1024 then -- 20MB
        validation.valid = false
        table.insert(validation.issues, "Animation file size exceeds 20MB limit")
    end
    
    -- Check frame rate
    local frameRate = asset.metadata.frameRate or 30
    if frameRate > 60 then
        table.insert(validation.issues, "High frame rate detected - consider optimization")
    end
    
    return validation
end

function AssetPipelineSystem.validateScriptAsset(asset)
    local validation = {valid = true, issues = {}}
    
    -- Check file size
    if asset.size > 1024 * 1024 then -- 1MB
        validation.valid = false
        table.insert(validation.issues, "Script file size exceeds 1MB limit")
    end
    
    -- Basic syntax validation (simulated)
    local content = asset.content or ""
    if not string.find(content, "return") and string.find(content, "local.*=") then
        table.insert(validation.issues, "Script may be missing return statement")
    end
    
    return validation
end

-- ========================================
-- ASSET OPTIMIZATION
-- ========================================

function AssetPipelineSystem.optimizeAsset(asset)
    local processor = PipelineState.assetProcessors[asset.type]
    if not processor then
        error(string.format("No processor available for asset type: %s", asset.type))
    end
    
    local options = AssetPipelineSystem.getOptimizationOptions(asset)
    return processor.optimize(asset, options)
end

function AssetPipelineSystem.getOptimizationOptions(asset)
    local qualityLevel = asset.qualityLevel or "medium"
    local baseOptions = PIPELINE_CONFIG.optimization[asset.type] or {}
    local qualityOptions = PIPELINE_CONFIG.quality[qualityLevel] or {}
    
    local options = {}
    
    -- Merge base options with quality-specific options
    for key, value in pairs(baseOptions) do
        options[key] = value
    end
    
    for key, value in pairs(qualityOptions) do
        options[key] = value
    end
    
    return options
end

function AssetPipelineSystem.optimizeImageAsset(asset, options)
    local optimized = {
        asset = AssetPipelineSystem.copyAsset(asset),
        metrics = {}
    }
    
    local startSize = asset.size
    local startTime = tick()
    
    -- Resize if needed
    if options.enableResize then
        local width = asset.metadata.width or 512
        local height = asset.metadata.height or 512
        
        if width > options.maxWidth or height > options.maxHeight then
            local scale = math.min(options.maxWidth / width, options.maxHeight / height)
            optimized.asset.metadata.width = math.floor(width * scale)
            optimized.asset.metadata.height = math.floor(height * scale)
            optimized.asset.size = math.floor(asset.size * scale * scale)
        end
    end
    
    -- Apply compression
    if options.enableCompression then
        local compressionRatio = options.compressionQuality / 100
        optimized.asset.size = math.floor(optimized.asset.size * compressionRatio)
    end
    
    optimized.metrics = {
        originalSize = startSize,
        optimizedSize = optimized.asset.size,
        compressionRatio = optimized.asset.size / startSize,
        processingTime = tick() - startTime
    }
    
    return optimized
end

function AssetPipelineSystem.optimizeAudioAsset(asset, options)
    local optimized = {
        asset = AssetPipelineSystem.copyAsset(asset),
        metrics = {}
    }
    
    local startSize = asset.size
    local startTime = tick()
    
    -- Apply bitrate optimization
    local currentBitrate = asset.metadata.bitrate or 128
    if currentBitrate > options.maxBitrate then
        local bitrateRatio = options.maxBitrate / currentBitrate
        optimized.asset.size = math.floor(asset.size * bitrateRatio)
        optimized.asset.metadata.bitrate = options.maxBitrate
    end
    
    -- Apply normalization
    if options.enableNormalization then
        optimized.asset.metadata.normalized = true
        optimized.asset.metadata.targetLUFS = options.normalizeVolume
    end
    
    optimized.metrics = {
        originalSize = startSize,
        optimizedSize = optimized.asset.size,
        compressionRatio = optimized.asset.size / startSize,
        processingTime = tick() - startTime
    }
    
    return optimized
end

function AssetPipelineSystem.optimizeModelAsset(asset, options)
    local optimized = {
        asset = AssetPipelineSystem.copyAsset(asset),
        metrics = {}
    }
    
    local startSize = asset.size
    local startTime = tick()
    
    -- Optimize triangle count
    local triangles = asset.metadata.triangles or 5000
    if triangles > options.maxTriangles then
        local reductionRatio = options.maxTriangles / triangles
        optimized.asset.metadata.triangles = options.maxTriangles
        optimized.asset.size = math.floor(asset.size * reductionRatio)
    end
    
    -- Generate LOD levels
    if options.enableLODGeneration then
        optimized.asset.lod = AssetPipelineSystem.generateLODLevels(asset, options.lodLevels)
    end
    
    optimized.metrics = {
        originalSize = startSize,
        optimizedSize = optimized.asset.size,
        compressionRatio = optimized.asset.size / startSize,
        processingTime = tick() - startTime
    }
    
    return optimized
end

function AssetPipelineSystem.optimizeAnimationAsset(asset, options)
    local optimized = {
        asset = AssetPipelineSystem.copyAsset(asset),
        metrics = {}
    }
    
    local startSize = asset.size
    local startTime = tick()
    
    -- Optimize frame rate
    local frameRate = asset.metadata.frameRate or 30
    if frameRate > 30 then
        local frameRatio = 30 / frameRate
        optimized.asset.size = math.floor(asset.size * frameRatio)
        optimized.asset.metadata.frameRate = 30
    end
    
    -- Apply keyframe optimization
    optimized.asset.metadata.keyframeOptimized = true
    optimized.asset.size = math.floor(optimized.asset.size * 0.8) -- Simulate compression
    
    optimized.metrics = {
        originalSize = startSize,
        optimizedSize = optimized.asset.size,
        compressionRatio = optimized.asset.size / startSize,
        processingTime = tick() - startTime
    }
    
    return optimized
end

function AssetPipelineSystem.optimizeScriptAsset(asset, options)
    local optimized = {
        asset = AssetPipelineSystem.copyAsset(asset),
        metrics = {}
    }
    
    local startSize = asset.size
    local startTime = tick()
    
    -- Remove comments and whitespace (simulated)
    local content = asset.content or ""
    local minified = string.gsub(content, "%s+", " ") -- Simplistic minification
    optimized.asset.content = minified
    optimized.asset.size = #minified
    
    optimized.metrics = {
        originalSize = startSize,
        optimizedSize = optimized.asset.size,
        compressionRatio = optimized.asset.size / startSize,
        processingTime = tick() - startTime
    }
    
    return optimized
end

-- ========================================
-- ASSET COMPRESSION
-- ========================================

function AssetPipelineSystem.compressAsset(asset)
    local processor = PipelineState.assetProcessors[asset.type]
    if not processor and processor.compress then
        return {asset = asset, metrics = {}}
    end
    
    local options = AssetPipelineSystem.getCompressionOptions(asset)
    return processor.compress(asset, options)
end

function AssetPipelineSystem.getCompressionOptions(asset)
    return {
        level = asset.compressionLevel or "standard",
        quality = asset.compressionQuality or 85,
        format = asset.preferredFormat or asset.format
    }
end

function AssetPipelineSystem.compressImageAsset(asset, options)
    local compressed = {
        asset = AssetPipelineSystem.copyAsset(asset),
        metrics = {}
    }
    
    local startSize = asset.size
    local compressionRatio = 0.7 -- Simulate compression
    
    if options.level == "aggressive" then
        compressionRatio = 0.5
    elseif options.level == "light" then
        compressionRatio = 0.85
    end
    
    compressed.asset.size = math.floor(asset.size * compressionRatio)
    compressed.asset.compressed = true
    compressed.asset.compressionLevel = options.level
    
    compressed.metrics = {
        originalSize = startSize,
        compressedSize = compressed.asset.size,
        compressionRatio = compressed.asset.size / startSize
    }
    
    return compressed
end

function AssetPipelineSystem.compressAudioAsset(asset, options)
    local compressed = {
        asset = AssetPipelineSystem.copyAsset(asset),
        metrics = {}
    }
    
    local startSize = asset.size
    local compressionRatio = 0.6 -- Simulate audio compression
    
    compressed.asset.size = math.floor(asset.size * compressionRatio)
    compressed.asset.compressed = true
    compressed.asset.format = options.format or "ogg"
    
    compressed.metrics = {
        originalSize = startSize,
        compressedSize = compressed.asset.size,
        compressionRatio = compressed.asset.size / startSize
    }
    
    return compressed
end

-- ========================================
-- PIPELINE PROCESSING
-- ========================================

function AssetPipelineSystem.startPipelineProcessing()
    if PIPELINE_CONFIG.pipeline.enableAutomaticOptimization then
        -- Event-driven pipeline processing with adaptive intervals
        local processingEvent = Instance.new("BindableEvent")
        
        local function scheduleProcessing()
            local pendingCount = #(PipelineState.processingQueue or {})
            local interval = 1 -- Base interval
            
            -- Adaptive interval based on queue size
            if pendingCount > 50 then
                interval = 0.5 -- Process more frequently with large queue
            elseif pendingCount > 10 then
                interval = 0.8 -- Slightly more frequent with medium queue
            elseif pendingCount == 0 then
                interval = 5 -- Much less frequent when queue is empty
            end
            
            task.spawn(function()
                task.wait(interval)
                processingEvent:Fire()
            end)
        end
        
        processingEvent.Event:Connect(function()
            AssetPipelineSystem.processPendingAssets()
            scheduleProcessing()
        end)
        
        scheduleProcessing()
    end
    
    print("🔄 Pipeline processing started")
end

function AssetPipelineSystem.processPendingAssets()
    local activeCount = 0
    for _ in pairs(PipelineState.activeProcessing) do
        activeCount = activeCount + 1
    end
    
    local maxConcurrent = PIPELINE_CONFIG.pipeline.maxConcurrentProcessing
    local tasksToProcess = math.min(maxConcurrent - activeCount, #PipelineState.processingQueue)
    
    for i = 1, tasksToProcess do
        local task = table.remove(PipelineState.processingQueue, 1)
        if task then
            spawn(function()
                AssetPipelineSystem.executeProcessingTask(task)
            end)
        end
    end
end

function AssetPipelineSystem.preprocessAsset(asset)
    return {
        asset = asset,
        metrics = {
            preprocessingTime = 0.1
        }
    }
end

function AssetPipelineSystem.postprocessAsset(asset)
    return {
        asset = asset,
        metrics = {
            postprocessingTime = 0.05
        }
    }
end

function AssetPipelineSystem.packageAsset(asset)
    local packaged = AssetPipelineSystem.copyAsset(asset)
    packaged.packaged = true
    packaged.packagedAt = tick()
    
    return {
        asset = packaged,
        metrics = {
            packagingTime = 0.02
        }
    }
end

-- ========================================
-- UTILITY FUNCTIONS
-- ========================================

function AssetPipelineSystem.copyAsset(asset)
    local copy = {}
    for key, value in pairs(asset) do
        if type(value) == "table" then
            copy[key] = AssetPipelineSystem.copyTable(value)
        else
            copy[key] = value
        end
    end
    return copy
end

function AssetPipelineSystem.copyTable(original)
    local copy = {}
    for key, value in pairs(original) do
        if type(value) == "table" then
            copy[key] = AssetPipelineSystem.copyTable(value)
        else
            copy[key] = value
        end
    end
    return copy
end

function AssetPipelineSystem.generateLODLevels(asset, levels)
    local lodAssets = {}
    
    for i = 1, levels do
        local reductionFactor = i * 0.5
        local lodAsset = AssetPipelineSystem.copyAsset(asset)
        
        lodAsset.name = asset.name .. "_LOD" .. i
        lodAsset.metadata.triangles = math.floor(asset.metadata.triangles * (1 - reductionFactor))
        lodAsset.size = math.floor(asset.size * (1 - reductionFactor))
        lodAsset.lodLevel = i
        
        lodAssets[i] = lodAsset
    end
    
    return lodAssets
end

-- ========================================
-- OPTIMIZATION ENGINES
-- ========================================

function AssetPipelineSystem.setupOptimizationEngines()
    PipelineState.optimizationEngines = {
        textureOptimizer = AssetPipelineSystem.createTextureOptimizer(),
        meshOptimizer = AssetPipelineSystem.createMeshOptimizer(),
        audioOptimizer = AssetPipelineSystem.createAudioOptimizer()
    }
    
    print("⚡ Optimization engines initialized")
end

function AssetPipelineSystem.createTextureOptimizer()
    return {
        optimize = function(texture, options)
            return AssetPipelineSystem.optimizeTexture(texture, options)
        end,
        
        generateMipmaps = function(texture)
            return AssetPipelineSystem.generateMipmaps(texture)
        end,
        
        compressTexture = function(texture, format)
            return AssetPipelineSystem.compressTexture(texture, format)
        end
    }
end

function AssetPipelineSystem.createMeshOptimizer()
    return {
        optimize = function(mesh, options)
            return AssetPipelineSystem.optimizeMesh(mesh, options)
        end,
        
        reduceMesh = function(mesh, targetTriangles)
            return AssetPipelineSystem.reduceMesh(mesh, targetTriangles)
        end,
        
        generateLOD = function(mesh, levels)
            return AssetPipelineSystem.generateMeshLOD(mesh, levels)
        end
    }
end

function AssetPipelineSystem.createAudioOptimizer()
    return {
        optimize = function(audio, options)
            return AssetPipelineSystem.optimizeAudio(audio, options)
        end,
        
        normalize = function(audio, targetLUFS)
            return AssetPipelineSystem.normalizeAudio(audio, targetLUFS)
        end,
        
        compress = function(audio, bitrate)
            return AssetPipelineSystem.compressAudio(audio, bitrate)
        end
    }
end

-- ========================================
-- QUALITY CONTROL
-- ========================================

function AssetPipelineSystem.initializeQualityControl()
    PipelineState.qualityControl = {
        metrics = {},
        thresholds = {
            maxCompressionRatio = 0.3, -- Don't compress below 30% of original
            minQualityScore = 7.0,
            maxProcessingTime = 60
        },
        validators = {}
    }
    
    print("🔍 Quality control initialized")
end

-- ========================================
-- PUBLIC API
-- ========================================

function AssetPipelineSystem.runAssetPipelineDemo()
    print("🏭 Running asset pipeline demonstration...")
    
    -- Create sample assets
    local sampleAssets = {
        {
            id = "img_001",
            name = "PlayerAvatar.png",
            type = "image",
            size = 2048 * 1024, -- 2MB
            format = "png",
            metadata = {width = 1024, height = 1024}
        },
        {
            id = "audio_001", 
            name = "BackgroundMusic.mp3",
            type = "audio",
            size = 5 * 1024 * 1024, -- 5MB
            format = "mp3",
            metadata = {duration = 120, bitrate = 192}
        },
        {
            id = "model_001",
            name = "PlayerCharacter.fbx",
            type = "model",
            size = 15 * 1024 * 1024, -- 15MB
            format = "fbx",
            metadata = {triangles = 8000, textures = 4}
        }
    }
    
    -- Process assets through pipeline
    local processingIds = {}
    for _, asset in ipairs(sampleAssets) do
        local taskId = AssetPipelineSystem.processAsset(asset, {qualityLevel = "medium"})
        table.insert(processingIds, taskId)
    end
    
    -- Wait for processing to complete
    print("  ⏳ Waiting for asset processing...")
    task.wait(3)
    
    -- Show results
    local totalOriginalSize = 0
    local totalOptimizedSize = 0
    
    for _, taskId in ipairs(processingIds) do
        local task = PipelineState.completedProcessing[taskId]
        if task and task.status == "completed" then
            local original = task.asset
            local optimized = task.results
            
            totalOriginalSize = totalOriginalSize + original.size
            totalOptimizedSize = totalOptimizedSize + optimized.size
            
            local compressionRatio = optimized.size / original.size
            print(string.format("    ✅ %s: %.1fMB → %.1fMB (%.1f%% reduction)", 
                original.name, 
                original.size / (1024*1024),
                optimized.size / (1024*1024),
                (1 - compressionRatio) * 100))
        end
    end
    
    local overallCompression = totalOptimizedSize / totalOriginalSize
    print(string.format("  📊 Overall compression: %.1f%% size reduction", 
        (1 - overallCompression) * 100))
    
    print("🏭 Asset pipeline demonstration completed")
end

function AssetPipelineSystem.getProcessingStatus(taskId)
    return PipelineState.activeProcessing[taskId] or PipelineState.completedProcessing[taskId]
end

function AssetPipelineSystem.getPipelineStats()
    return PipelineState.stats
end

function AssetPipelineSystem.getOptimizedAsset(assetId)
    return PipelineState.optimizedAssets[assetId]
end

-- Export API
AssetPipelineSystem.processAsset = AssetPipelineSystem.processAsset
AssetPipelineSystem.validateAsset = AssetPipelineSystem.validateAsset
AssetPipelineSystem.optimizeAsset = AssetPipelineSystem.optimizeAsset
AssetPipelineSystem.compressAsset = AssetPipelineSystem.compressAsset

-- Initialize the asset pipeline system
AssetPipelineSystem.initialize()

print("🏭 AssetPipelineSystem loaded with comprehensive asset processing capabilities")

return AssetPipelineSystem
