-- AssetVersioningSystem.luau
-- Asset versioning and content delivery network (CDN) integration
-- Provides comprehensive asset versioning, CDN management, and delivery optimization

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local HttpService = game:GetService("HttpService")
local ContentProvider = game:GetService("ContentProvider")
local Players = game:GetService("Players")

local SafeRequire = require(ReplicatedStorage.Shared.utils.SafeRequire)

local AssetVersioningSystem = {}

-- ========================================
-- VERSIONING AND CDN CONFIGURATION
-- ========================================

local VERSIONING_CONFIG = {
    -- Versioning settings
    versioning = {
        enableVersioning = true,
        enableBranching = true,
        enableTagging = true,
        enableDeltaVersions = true,
        maxVersionHistory = 50,
        compressionEnabled = true
    },
    
    -- CDN settings
    cdn = {
        enableCDN = true,
        primaryEndpoint = "https://cdn.robloxgame.com/assets/",
        fallbackEndpoints = {
            "https://backup-cdn.robloxgame.com/assets/",
            "https://assets.roblox.com/assets/"
        },
        enableCaching = true,
        enableCompression = true,
        enableEdgeCaching = true,
        cacheTimeToLive = 3600000, -- 1 hour
        maxRetries = 3,
        timeoutMs = 10000
    },
    
    -- Distribution settings
    distribution = {
        enableMultiRegion = true,
        enableLoadBalancing = true,
        enableFailover = true,
        regions = {
            "us-east", "us-west", "eu-west", "asia-pacific"
        },
        distributionStrategy = "proximity" -- "proximity", "performance", "random"
    },
    
    -- Performance optimization
    optimization = {
        enablePrefetching = true,
        enableBundling = true,
        enableStreaming = true,
        enableAdaptiveQuality = true,
        bandwidthThresholds = {
            low = 1000000,    -- 1 Mbps
            medium = 5000000, -- 5 Mbps
            high = 25000000   -- 25 Mbps
        }
    }
}

-- ========================================
-- VERSIONING AND CDN STATE
-- ========================================

local VersioningState = {
    -- Version management
    assetVersions = {},
    versionHistory = {},
    versionTags = {},
    branches = {},
    
    -- CDN management
    cdnEndpoints = {},
    assetDistribution = {},
    cdnCache = {},
    distributionMetrics = {},
    
    -- Asset tracking
    assetManifest = {},
    dependencyGraph = {},
    downloadQueue = {},
    activeDownloads = {},
    
    -- Performance metrics
    performanceMetrics = {
        downloadTimes = {},
        cacheHitRates = {},
        bandwidthUsage = {},
        failoverEvents = {}
    },
    
    -- Statistics
    stats = {
        totalVersions = 0,
        activeAssets = 0,
        cacheHitRate = 0,
        averageDownloadTime = 0,
        bandwidthSaved = 0,
        cdnRequests = 0
    }
}

function AssetVersioningSystem.initialize()
    print("📦 Initializing AssetVersioningSystem...")
    
    -- Set up versioning system
    AssetVersioningSystem.setupVersioningSystem()
    
    -- Initialize CDN integration
    AssetVersioningSystem.initializeCDNIntegration()
    
    -- Set up asset distribution
    AssetVersioningSystem.setupAssetDistribution()
    
    -- Initialize caching system
    AssetVersioningSystem.initializeCachingSystem()
    
    -- Start performance monitoring
    AssetVersioningSystem.startPerformanceMonitoring()
    
    print("📦 AssetVersioningSystem initialized successfully")
end

-- ========================================
-- VERSIONING SYSTEM
-- ========================================

function AssetVersioningSystem.setupVersioningSystem()
    VersioningState.versionManager = {
        versions = {},
        branches = {},
        tags = {},
        history = {}
    }
    
    -- Initialize default branch
    AssetVersioningSystem.createBranch("main", {
        description = "Main production branch",
        protected = true
    })
    
    print("🔢 Versioning system initialized")
end

function AssetVersioningSystem.createAssetVersion(assetId, content, metadata)
    local version = {
        id = HttpService:GenerateGUID(false),
        assetId = assetId,
        version = AssetVersioningSystem.generateVersionNumber(assetId),
        content = content,
        metadata = metadata or {},
        branch = metadata.branch or "main",
        timestamp = tick(),
        author = metadata.author or "system",
        changeLog = metadata.changeLog or "",
        parentVersion = AssetVersioningSystem.getLatestVersion(assetId),
        checksum = AssetVersioningSystem.calculateChecksum(content),
        size = AssetVersioningSystem.calculateSize(content),
        compressed = false,
        distributed = false
    }
    
    -- Store version
    if not VersioningState.assetVersions[assetId] then
        VersioningState.assetVersions[assetId] = {}
    end
    
    table.insert(VersioningState.assetVersions[assetId], version)
    
    -- Update version history
    AssetVersioningSystem.updateVersionHistory(assetId, version)
    
    -- Generate delta if enabled
    if VERSIONING_CONFIG.versioning.enableDeltaVersions and version.parentVersion then
        version.delta = AssetVersioningSystem.generateDelta(version.parentVersion, version)
    end
    
    VersioningState.stats.totalVersions = VersioningState.stats.totalVersions + 1
    
    print(string.format("📦 Created version %s for asset %s", version.version, assetId))
    
    return version
end

function AssetVersioningSystem.generateVersionNumber(assetId)
    local versions = VersioningState.assetVersions[assetId] or {}
    local latestVersion = #versions > 0 and versions[#versions] or nil
    
    if not latestVersion then
        return "1.0.0"
    end
    
    -- Parse current version (major.minor.patch)
    local major, minor, patch = string.match(latestVersion.version, "(%d+)%.(%d+)%.(%d+)")
    major, minor, patch = tonumber(major) or 1, tonumber(minor) or 0, tonumber(patch) or 0
    
    -- Increment patch version by default
    patch = patch + 1
    
    return string.format("%d.%d.%d", major, minor, patch)
end

function AssetVersioningSystem.createBranch(branchName, options)
    options = options or {}
    
    local branch = {
        name = branchName,
        description = options.description or "",
        protected = options.protected or false,
        createdAt = tick(),
        parentBranch = options.parentBranch or "main",
        versions = {},
        tags = {}
    }
    
    VersioningState.branches[branchName] = branch
    
    print(string.format("🌿 Created branch: %s", branchName))
    
    return branch
end

function AssetVersioningSystem.tagVersion(assetId, version, tagName, description)
    local tag = {
        name = tagName,
        description = description or "",
        assetId = assetId,
        version = version,
        timestamp = tick()
    }
    
    if not VersioningState.versionTags[assetId] then
        VersioningState.versionTags[assetId] = {}
    end
    
    VersioningState.versionTags[assetId][tagName] = tag
    
    print(string.format("🏷️ Tagged version %s as '%s'", version, tagName))
    
    return tag
end

function AssetVersioningSystem.getAssetVersion(assetId, versionSpec)
    local versions = VersioningState.assetVersions[assetId]
    if not versions or #versions == 0 then
        return nil
    end
    
    -- Handle different version specifications
    if not versionSpec or versionSpec == "latest" then
        return versions[#versions]
    elseif type(versionSpec) == "string" then
        -- Check if it's a tag
        local tags = VersioningState.versionTags[assetId]
        if tags and tags[versionSpec] then
            return AssetVersioningSystem.findVersionByNumber(assetId, tags[versionSpec].version)
        end
        
        -- Treat as version number
        return AssetVersioningSystem.findVersionByNumber(assetId, versionSpec)
    elseif type(versionSpec) == "number" then
        return versions[versionSpec]
    end
    
    return nil
end

function AssetVersioningSystem.findVersionByNumber(assetId, versionNumber)
    local versions = VersioningState.assetVersions[assetId] or {}
    
    for _, version in ipairs(versions) do
        if version.version == versionNumber then
            return version
        end
    end
    
    return nil
end

function AssetVersioningSystem.getLatestVersion(assetId)
    local versions = VersioningState.assetVersions[assetId]
    return versions and #versions > 0 and versions[#versions] or nil
end

function AssetVersioningSystem.updateVersionHistory(assetId, version)
    if not VersioningState.versionHistory[assetId] then
        VersioningState.versionHistory[assetId] = {}
    end
    
    table.insert(VersioningState.versionHistory[assetId], {
        version = version.version,
        timestamp = version.timestamp,
        author = version.author,
        changeLog = version.changeLog,
        size = version.size
    })
    
    -- Maintain history size limit
    local history = VersioningState.versionHistory[assetId]
    if #history > VERSIONING_CONFIG.versioning.maxVersionHistory then
        table.remove(history, 1)
    end
end

function AssetVersioningSystem.generateDelta(parentVersion, currentVersion)
    -- Simplified delta generation
    local delta = {
        type = "delta",
        parentChecksum = parentVersion.checksum,
        currentChecksum = currentVersion.checksum,
        operations = AssetVersioningSystem.calculateDeltaOperations(
            parentVersion.content, 
            currentVersion.content
        ),
        compressionRatio = 0.3 -- Simulate delta compression
    }
    
    return delta
end

function AssetVersioningSystem.calculateDeltaOperations(oldContent, newContent)
    -- Simplified delta calculation
    return {
        {operation = "modify", offset = 0, data = "simulated_delta_data"}
    }
end

-- ========================================
-- CDN INTEGRATION
-- ========================================

function AssetVersioningSystem.initializeCDNIntegration()
    VersioningState.cdnManager = {
        endpoints = {},
        healthStatus = {},
        loadBalancer = {},
        failoverSystem = {}
    }
    
    -- Initialize CDN endpoints
    AssetVersioningSystem.setupCDNEndpoints()
    
    -- Set up load balancing
    AssetVersioningSystem.setupLoadBalancing()
    
    -- Initialize health monitoring
    AssetVersioningSystem.startCDNHealthMonitoring()
    
    print("🌐 CDN integration initialized")
end

function AssetVersioningSystem.setupCDNEndpoints()
    local endpoints = {
        {
            id = "primary",
            url = VERSIONING_CONFIG.cdn.primaryEndpoint,
            region = "us-east",
            priority = 1,
            status = "active",
            latency = 50,
            bandwidth = 1000000000 -- 1 Gbps
        }
    }
    
    -- Add fallback endpoints
    for i, fallbackUrl in ipairs(VERSIONING_CONFIG.cdn.fallbackEndpoints) do
        table.insert(endpoints, {
            id = "fallback_" .. i,
            url = fallbackUrl,
            region = "us-west",
            priority = i + 1,
            status = "active",
            latency = 75 + i * 25,
            bandwidth = 500000000 -- 500 Mbps
        })
    end
    
    VersioningState.cdnEndpoints = endpoints
    
    print(string.format("🌐 Configured %d CDN endpoints", #endpoints))
end

function AssetVersioningSystem.setupLoadBalancing()
    VersioningState.loadBalancer = {
        strategy = VERSIONING_CONFIG.distribution.distributionStrategy,
        activeEndpoints = {},
        requestCounts = {},
        performanceMetrics = {}
    }
    
    -- Initialize active endpoints
    for _, endpoint in ipairs(VersioningState.cdnEndpoints) do
        if endpoint.status == "active" then
            VersioningState.loadBalancer.activeEndpoints[endpoint.id] = endpoint
            VersioningState.loadBalancer.requestCounts[endpoint.id] = 0
        end
    end
end

function AssetVersioningSystem.selectCDNEndpoint(assetRequest)
    local strategy = VersioningState.loadBalancer.strategy
    local activeEndpoints = VersioningState.loadBalancer.activeEndpoints
    
    if strategy == "proximity" then
        return AssetVersioningSystem.selectByProximity(assetRequest, activeEndpoints)
    elseif strategy == "performance" then
        return AssetVersioningSystem.selectByPerformance(activeEndpoints)
    elseif strategy == "random" then
        return AssetVersioningSystem.selectRandom(activeEndpoints)
    else
        -- Default to primary endpoint
        return activeEndpoints.primary
    end
end

function AssetVersioningSystem.selectByProximity(assetRequest, endpoints)
    -- Simulate proximity selection based on user region
    local userRegion = assetRequest.userRegion or "us-east"
    
    local bestEndpoint = nil
    local bestScore = math.huge
    
    for _, endpoint in pairs(endpoints) do
        local score = AssetVersioningSystem.calculateProximityScore(userRegion, endpoint.region)
        if score < bestScore then
            bestScore = score
            bestEndpoint = endpoint
        end
    end
    
    return bestEndpoint or endpoints.primary
end

function AssetVersioningSystem.selectByPerformance(endpoints)
    local bestEndpoint = nil
    local bestScore = 0
    
    for _, endpoint in pairs(endpoints) do
        local score = AssetVersioningSystem.calculatePerformanceScore(endpoint)
        if score > bestScore then
            bestScore = score
            bestEndpoint = endpoint
        end
    end
    
    return bestEndpoint
end

function AssetVersioningSystem.selectRandom(endpoints)
    local endpointList = {}
    for _, endpoint in pairs(endpoints) do
        table.insert(endpointList, endpoint)
    end
    
    if #endpointList > 0 then
        return endpointList[math.random(1, #endpointList)]
    end
    
    return nil
end

function AssetVersioningSystem.calculateProximityScore(userRegion, endpointRegion)
    -- Simplified proximity calculation
    local regionDistances = {
        ["us-east"] = {["us-east"] = 0, ["us-west"] = 100, ["eu-west"] = 200, ["asia-pacific"] = 300},
        ["us-west"] = {["us-east"] = 100, ["us-west"] = 0, ["eu-west"] = 250, ["asia-pacific"] = 150},
        ["eu-west"] = {["us-east"] = 200, ["us-west"] = 250, ["eu-west"] = 0, ["asia-pacific"] = 400},
        ["asia-pacific"] = {["us-east"] = 300, ["us-west"] = 150, ["eu-west"] = 400, ["asia-pacific"] = 0}
    }
    
    return regionDistances[userRegion] and regionDistances[userRegion][endpointRegion] or 1000
end

function AssetVersioningSystem.calculatePerformanceScore(endpoint)
    -- Calculate performance score based on latency and bandwidth
    local latencyScore = math.max(0, 100 - endpoint.latency)
    local bandwidthScore = math.min(100, endpoint.bandwidth / 10000000) -- Scale bandwidth
    
    return (latencyScore + bandwidthScore) / 2
end

-- ========================================
-- ASSET DISTRIBUTION
-- ========================================

function AssetVersioningSystem.setupAssetDistribution()
    VersioningState.distributionManager = {
        manifest = {},
        distributionQueue = {},
        distributedAssets = {},
        replicationStatus = {}
    }
    
    print("📡 Asset distribution initialized")
end

function AssetVersioningSystem.distributeAsset(assetVersion)
    local distribution = {
        id = HttpService:GenerateGUID(false),
        assetId = assetVersion.assetId,
        version = assetVersion.version,
        status = "pending",
        startTime = tick(),
        endTime = nil,
        endpoints = {},
        replicationStatus = {}
    }
    
    table.insert(VersioningState.distributionManager.distributionQueue, distribution)
    
    print(string.format("📡 Queued distribution for asset %s v%s", 
        assetVersion.assetId, assetVersion.version))
    
    return distribution.id
end

function AssetVersioningSystem.executeDistribution(distribution)
    distribution.status = "distributing"
    
    local assetVersion = AssetVersioningSystem.getAssetVersion(
        distribution.assetId, 
        distribution.version
    )
    
    if not assetVersion then
        distribution.status = "failed"
        distribution.error = "Asset version not found"
        return false
    end
    
    -- Distribute to all active endpoints
    local success = true
    for _, endpoint in pairs(VersioningState.loadBalancer.activeEndpoints) do
        local replicationResult = AssetVersioningSystem.replicateToEndpoint(assetVersion, endpoint)
        distribution.replicationStatus[endpoint.id] = replicationResult
        
        if not replicationResult.success then
            success = false
        end
    end
    
    distribution.status = success and "completed" or "partial"
    distribution.endTime = tick()
    distribution.duration = distribution.endTime - distribution.startTime
    
    if success then
        assetVersion.distributed = true
        VersioningState.distributionManager.distributedAssets[assetVersion.id] = assetVersion
    end
    
    print(string.format("📡 Distribution %s for asset %s v%s", 
        success and "completed" or "failed",
        distribution.assetId, 
        distribution.version))
    
    return success
end

function AssetVersioningSystem.replicateToEndpoint(assetVersion, endpoint)
    local replication = {
        endpointId = endpoint.id,
        assetId = assetVersion.assetId,
        version = assetVersion.version,
        startTime = tick(),
        success = false,
        error = nil
    }
    
    -- Simulate replication to CDN endpoint
    local simulatedLatency = endpoint.latency / 1000 -- Convert to seconds
    task.wait(simulatedLatency)
    
    -- Simulate success/failure
    local successRate = 0.95 -- 95% success rate
    replication.success = math.random() < successRate
    
    if not replication.success then
        replication.error = "Network timeout during replication"
    end
    
    replication.endTime = tick()
    replication.duration = replication.endTime - replication.startTime
    
    return replication
end

-- ========================================
-- CACHING SYSTEM
-- ========================================

function AssetVersioningSystem.initializeCachingSystem()
    VersioningState.cacheManager = {
        cache = {},
        cacheIndex = {},
        cacheStats = {
            hits = 0,
            misses = 0,
            evictions = 0
        },
        maxCacheSize = 100 * 1024 * 1024, -- 100MB
        currentCacheSize = 0
    }
    
    print("💾 Caching system initialized")
end

function AssetVersioningSystem.cacheAsset(assetId, version, content)
    local cacheKey = string.format("%s:%s", assetId, version)
    local cacheEntry = {
        key = cacheKey,
        assetId = assetId,
        version = version,
        content = content,
        size = AssetVersioningSystem.calculateSize(content),
        timestamp = tick(),
        accessCount = 0,
        lastAccessed = tick()
    }
    
    -- Check cache size limits
    if cacheEntry.size > VersioningState.cacheManager.maxCacheSize then
        return false -- Asset too large to cache
    end
    
    -- Evict entries if necessary
    AssetVersioningSystem.evictCacheEntries(cacheEntry.size)
    
    -- Add to cache
    VersioningState.cacheManager.cache[cacheKey] = cacheEntry
    VersioningState.cacheManager.currentCacheSize = 
        VersioningState.cacheManager.currentCacheSize + cacheEntry.size
    
    -- Update cache index
    table.insert(VersioningState.cacheManager.cacheIndex, cacheKey)
    
    return true
end

function AssetVersioningSystem.getCachedAsset(assetId, version)
    local cacheKey = string.format("%s:%s", assetId, version)
    local cacheEntry = VersioningState.cacheManager.cache[cacheKey]
    
    if cacheEntry then
        -- Update access statistics
        cacheEntry.accessCount = cacheEntry.accessCount + 1
        cacheEntry.lastAccessed = tick()
        
        VersioningState.cacheManager.cacheStats.hits = 
            VersioningState.cacheManager.cacheStats.hits + 1
        
        return cacheEntry.content
    else
        VersioningState.cacheManager.cacheStats.misses = 
            VersioningState.cacheManager.cacheStats.misses + 1
        
        return nil
    end
end

function AssetVersioningSystem.evictCacheEntries(requiredSpace)
    local manager = VersioningState.cacheManager
    
    while manager.currentCacheSize + requiredSpace > manager.maxCacheSize and 
          #manager.cacheIndex > 0 do
        
        -- Use LRU eviction strategy
        local oldestKey = manager.cacheIndex[1]
        local evictedEntry = manager.cache[oldestKey]
        
        if evictedEntry then
            manager.cache[oldestKey] = nil
            manager.currentCacheSize = manager.currentCacheSize - evictedEntry.size
            manager.cacheStats.evictions = manager.cacheStats.evictions + 1
        end
        
        table.remove(manager.cacheIndex, 1)
    end
end

function AssetVersioningSystem.calculateCacheHitRate()
    local stats = VersioningState.cacheManager.cacheStats
    local totalRequests = stats.hits + stats.misses
    
    if totalRequests > 0 then
        return (stats.hits / totalRequests) * 100
    else
        return 0
    end
end

-- ========================================
-- ASSET DELIVERY
-- ========================================

function AssetVersioningSystem.requestAsset(assetId, versionSpec, options)
    options = options or {}
    
    local request = {
        id = HttpService:GenerateGUID(false),
        assetId = assetId,
        versionSpec = versionSpec or "latest",
        userRegion = options.userRegion or "us-east",
        priority = options.priority or "normal",
        cacheEnabled = options.cacheEnabled ~= false,
        startTime = tick(),
        status = "pending"
    }
    
    -- Check cache first
    if request.cacheEnabled then
        local version = AssetVersioningSystem.getAssetVersion(assetId, versionSpec)
        if version then
            local cachedContent = AssetVersioningSystem.getCachedAsset(assetId, version.version)
            if cachedContent then
                request.status = "completed"
                request.source = "cache"
                request.content = cachedContent
                request.endTime = tick()
                request.duration = request.endTime - request.startTime
                
                return request
            end
        end
    end
    
    -- Queue for CDN download
    table.insert(VersioningState.downloadQueue, request)
    
    print(string.format("📥 Queued asset request: %s v%s", assetId, versionSpec))
    
    return request
end

function AssetVersioningSystem.processAssetRequest(request)
    request.status = "downloading"
    VersioningState.activeDownloads[request.id] = request
    
    -- Get asset version
    local assetVersion = AssetVersioningSystem.getAssetVersion(request.assetId, request.versionSpec)
    if not assetVersion then
        request.status = "failed"
        request.error = "Asset version not found"
        return request
    end
    
    -- Select CDN endpoint
    local endpoint = AssetVersioningSystem.selectCDNEndpoint(request)
    if not endpoint then
        request.status = "failed"
        request.error = "No available CDN endpoints"
        return request
    end
    
    request.endpoint = endpoint
    
    -- Simulate download
    local downloadResult = AssetVersioningSystem.downloadFromCDN(assetVersion, endpoint)
    
    if downloadResult.success then
        request.status = "completed"
        request.content = downloadResult.content
        request.source = "cdn"
        
        -- Cache the asset
        if request.cacheEnabled then
            AssetVersioningSystem.cacheAsset(assetVersion.assetId, assetVersion.version, downloadResult.content)
        end
    else
        request.status = "failed"
        request.error = downloadResult.error
    end
    
    request.endTime = tick()
    request.duration = request.endTime - request.startTime
    
    VersioningState.activeDownloads[request.id] = nil
    
    -- Update statistics
    VersioningState.stats.cdnRequests = VersioningState.stats.cdnRequests + 1
    
    if request.status == "completed" then
        local downloadTime = request.duration * 1000 -- Convert to ms
        table.insert(VersioningState.performanceMetrics.downloadTimes, downloadTime)
        
        -- Maintain metrics history
        if #VersioningState.performanceMetrics.downloadTimes > 100 then
            table.remove(VersioningState.performanceMetrics.downloadTimes, 1)
        end
    end
    
    return request
end

function AssetVersioningSystem.downloadFromCDN(assetVersion, endpoint)
    local download = {
        success = false,
        content = nil,
        error = nil,
        startTime = tick()
    }
    
    -- Simulate network latency
    local latency = endpoint.latency / 1000
    task.wait(latency)
    
    -- Simulate download with potential failure
    local successRate = 0.98 -- 98% success rate
    download.success = math.random() < successRate
    
    if download.success then
        download.content = assetVersion.content
    else
        download.error = "Network error during download"
    end
    
    download.endTime = tick()
    download.duration = download.endTime - download.startTime
    
    return download
end

-- ========================================
-- PERFORMANCE MONITORING
-- ========================================

function AssetVersioningSystem.startPerformanceMonitoring()
    -- Event-driven performance monitoring system
    local performanceMonitoringEvent = Instance.new("BindableEvent")
    
    local function schedulePerformanceMonitoring()
        AssetVersioningSystem.updatePerformanceMetrics()
        AssetVersioningSystem.processDownloadQueue()
        AssetVersioningSystem.processDistributionQueue()
        
        -- Adaptive interval based on queue sizes
        local downloadQueueSize = #VersioningState.downloadQueue
        local distributionQueueSize = #VersioningState.distributionQueue
        local totalQueueSize = downloadQueueSize + distributionQueueSize
        
        local interval = totalQueueSize > 50 and 0.5 or (totalQueueSize > 10 and 0.8 or 1.2)
        task.wait(interval)
        performanceMonitoringEvent:Fire()
    end
    
    performanceMonitoringEvent.Event:Connect(function()
        spawn(schedulePerformanceMonitoring)
    end)
    
    -- Start the performance monitoring cycle
    spawn(schedulePerformanceMonitoring)
    
    print("📊 Performance monitoring started")
end

function AssetVersioningSystem.updatePerformanceMetrics()
    -- Update cache hit rate
    VersioningState.stats.cacheHitRate = AssetVersioningSystem.calculateCacheHitRate()
    
    -- Update average download time
    local downloadTimes = VersioningState.performanceMetrics.downloadTimes
    if #downloadTimes > 0 then
        local total = 0
        for _, time in ipairs(downloadTimes) do
            total = total + time
        end
        VersioningState.stats.averageDownloadTime = total / #downloadTimes
    end
    
    -- Update active assets count
    VersioningState.stats.activeAssets = 0
    for _ in pairs(VersioningState.distributionManager.distributedAssets) do
        VersioningState.stats.activeAssets = VersioningState.stats.activeAssets + 1
    end
end

function AssetVersioningSystem.processDownloadQueue()
    local maxConcurrent = 5
    local activeCount = 0
    
    for _ in pairs(VersioningState.activeDownloads) do
        activeCount = activeCount + 1
    end
    
    local requestsToProcess = math.min(maxConcurrent - activeCount, #VersioningState.downloadQueue)
    
    for i = 1, requestsToProcess do
        local request = table.remove(VersioningState.downloadQueue, 1)
        if request then
            spawn(function()
                AssetVersioningSystem.processAssetRequest(request)
            end)
        end
    end
end

function AssetVersioningSystem.processDistributionQueue()
    local maxConcurrent = 3
    local distributionQueue = VersioningState.distributionManager.distributionQueue
    
    local distributionsToProcess = math.min(maxConcurrent, #distributionQueue)
    
    for i = 1, distributionsToProcess do
        local distribution = table.remove(distributionQueue, 1)
        if distribution then
            spawn(function()
                AssetVersioningSystem.executeDistribution(distribution)
            end)
        end
    end
end

function AssetVersioningSystem.startCDNHealthMonitoring()
    -- Event-driven CDN health monitoring system
    local cdnHealthEvent = Instance.new("BindableEvent")
    
    local function scheduleCDNHealthCheck()
        AssetVersioningSystem.checkCDNHealth()
        
        -- Adaptive interval based on CDN health status
        local unhealthyCount = 0
        for _, endpoint in ipairs(VersioningState.cdnEndpoints) do
            if not endpoint.healthy then
                unhealthyCount = unhealthyCount + 1
            end
        end
        
        local interval = unhealthyCount > 0 and 15 or 30 -- More frequent checks if CDN issues
        task.wait(interval)
        cdnHealthEvent:Fire()
    end
    
    cdnHealthEvent.Event:Connect(function()
        spawn(scheduleCDNHealthCheck)
    end)
    
    -- Start the CDN health monitoring cycle
    spawn(scheduleCDNHealthCheck)
end

function AssetVersioningSystem.checkCDNHealth()
    for _, endpoint in ipairs(VersioningState.cdnEndpoints) do
        -- Simulate health check
        local isHealthy = math.random() > 0.05 -- 95% uptime
        
        if isHealthy then
            endpoint.status = "active"
            VersioningState.loadBalancer.activeEndpoints[endpoint.id] = endpoint
        else
            endpoint.status = "unhealthy"
            VersioningState.loadBalancer.activeEndpoints[endpoint.id] = nil
            
            print(string.format("⚠️ CDN endpoint %s is unhealthy", endpoint.id))
        end
    end
end

-- ========================================
-- UTILITY FUNCTIONS
-- ========================================

function AssetVersioningSystem.calculateChecksum(content)
    -- Simplified checksum calculation
    local checksum = 0
    local contentStr = tostring(content)
    
    for i = 1, #contentStr do
        checksum = checksum + string.byte(contentStr, i)
    end
    
    return checksum
end

function AssetVersioningSystem.calculateSize(content)
    -- Simplified size calculation
    if type(content) == "string" then
        return #content
    elseif type(content) == "table" then
        local serialized = HttpService:JSONEncode(content)
        return #serialized
    else
        return 1024 -- Default size
    end
end

-- ========================================
-- PUBLIC API
-- ========================================

function AssetVersioningSystem.runVersioningDemo()
    print("📦 Running asset versioning demonstration...")
    
    -- Create sample asset versions
    local sampleAssets = {
        {
            id = "ui_button_primary",
            content = {type = "image", data = "button_primary_v1"},
            metadata = {author = "designer", changeLog = "Initial design"}
        },
        {
            id = "audio_menu_music",
            content = {type = "audio", data = "menu_music_v1"},
            metadata = {author = "composer", changeLog = "Initial composition"}
        },
        {
            id = "model_player_character",
            content = {type = "model", data = "character_v1"},
            metadata = {author = "modeler", changeLog = "Base character model"}
        }
    }
    
    -- Create versions and distribute
    print("  📦 Creating asset versions...")
    for _, asset in ipairs(sampleAssets) do
        local version = AssetVersioningSystem.createAssetVersion(
            asset.id, asset.content, asset.metadata
        )
        
        -- Tag important versions
        AssetVersioningSystem.tagVersion(asset.id, version.version, "v1.0", "Initial release")
        
        -- Distribute to CDN
        AssetVersioningSystem.distributeAsset(version)
    end
    
    -- Wait for distribution
    task.wait(2)
    
    -- Demonstrate asset requests
    print("  📥 Testing asset delivery...")
    local requests = {}
    
    for _, asset in ipairs(sampleAssets) do
        local request = AssetVersioningSystem.requestAsset(asset.id, "latest", {
            userRegion = "us-east",
            cacheEnabled = true
        })
        table.insert(requests, request)
    end
    
    -- Wait for downloads
    task.wait(3)
    
    -- Show performance metrics
    local stats = AssetVersioningSystem.getVersioningStats()
    print(string.format("  📊 Performance metrics:"))
    print(string.format("    Total versions: %d", stats.totalVersions))
    print(string.format("    Active assets: %d", stats.activeAssets))
    print(string.format("    Cache hit rate: %.1f%%", stats.cacheHitRate))
    print(string.format("    Average download time: %.1fms", stats.averageDownloadTime))
    print(string.format("    CDN requests: %d", stats.cdnRequests))
    
    print("📦 Asset versioning demonstration completed")
end

function AssetVersioningSystem.getAssetManifest()
    local manifest = {
        timestamp = tick(),
        totalAssets = 0,
        totalVersions = VersioningState.stats.totalVersions,
        assets = {}
    }
    
    for assetId, versions in pairs(VersioningState.assetVersions) do
        manifest.assets[assetId] = {
            id = assetId,
            totalVersions = #versions,
            latestVersion = versions[#versions].version,
            distributed = versions[#versions].distributed,
            size = versions[#versions].size
        }
        manifest.totalAssets = manifest.totalAssets + 1
    end
    
    return manifest
end

function AssetVersioningSystem.getVersioningStats()
    return VersioningState.stats
end

function AssetVersioningSystem.getCDNStatus()
    return {
        endpoints = VersioningState.cdnEndpoints,
        activeEndpoints = VersioningState.loadBalancer.activeEndpoints,
        performanceMetrics = VersioningState.performanceMetrics
    }
end

-- Export API
AssetVersioningSystem.createAssetVersion = AssetVersioningSystem.createAssetVersion
AssetVersioningSystem.getAssetVersion = AssetVersioningSystem.getAssetVersion
AssetVersioningSystem.requestAsset = AssetVersioningSystem.requestAsset
AssetVersioningSystem.distributeAsset = AssetVersioningSystem.distributeAsset
AssetVersioningSystem.tagVersion = AssetVersioningSystem.tagVersion
AssetVersioningSystem.createBranch = AssetVersioningSystem.createBranch

-- Initialize the asset versioning system
AssetVersioningSystem.initialize()

print("📦 AssetVersioningSystem loaded with comprehensive versioning and CDN capabilities")

return AssetVersioningSystem
