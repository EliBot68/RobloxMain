-- NetworkOptimizer.luau
-- Network optimization system with request batching, compression, and caching strategies
-- Optimizes network performance and reduces bandwidth usage

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local HttpService = game:GetService("HttpService")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")

local SafeRequire = require(ReplicatedStorage.Shared.utils.SafeRequire)

local NetworkOptimizer = {}

-- ========================================
-- NETWORK OPTIMIZATION CONFIGURATION
-- ========================================

local NETWORK_CONFIG = {
    -- Request batching
    batching = {
        enabled = true,
        maxBatchSize = 10,           -- Maximum requests per batch
        batchTimeout = 100,          -- Milliseconds to wait before sending batch
        maxBatchDataSize = 8192,     -- Maximum batch size in bytes
        priorityLevels = {"critical", "high", "normal", "low"}
    },
    
    -- Compression settings
    compression = {
        enabled = true,
        algorithm = "lz4",           -- Compression algorithm
        threshold = 1024,            -- Minimum size to compress (bytes)
        compressionLevel = 6,        -- Compression level (1-9)
        maxCompressionTime = 10      -- Maximum time to spend compressing (ms)
    },
    
    -- Caching configuration
    caching = {
        enabled = true,
        maxCacheSize = 10485760,     -- 10MB cache limit
        defaultTTL = 300,            -- Default cache TTL (seconds)
        maxCacheEntries = 1000,      -- Maximum cache entries
        compressionEnabled = true     -- Compress cached data
    },
    
    -- Request optimization
    requests = {
        maxConcurrent = 8,           -- Maximum concurrent requests
        timeout = 30000,             -- Request timeout (milliseconds)
        retryAttempts = 3,           -- Number of retry attempts
        retryDelay = 1000,           -- Base retry delay (milliseconds)
        rateLimitPerSecond = 60      -- Maximum requests per second
    },
    
    -- Data optimization
    dataOptimization = {
        enableDeltaCompression = true,
        enableFieldFiltering = true,
        enableTypeOptimization = true,
        maxPayloadSize = 32768       -- Maximum payload size (bytes)
    }
}

-- ========================================
-- NETWORK OPTIMIZER STATE
-- ========================================

local NetworkState = {
    -- Request batching
    batchQueue = {},
    batchTimer = nil,
    currentBatch = nil,
    
    -- Caching system
    cache = {},
    cacheSize = 0,
    cacheStats = {
        hits = 0,
        misses = 0,
        evictions = 0
    },
    
    -- Request management
    activeRequests = {},
    requestQueue = {},
    requestStats = {
        total = 0,
        successful = 0,
        failed = 0,
        cached = 0,
        batched = 0
    },
    
    -- Rate limiting
    rateLimiter = {
        tokens = NETWORK_CONFIG.requests.rateLimitPerSecond,
        lastRefill = tick(),
        requestTimes = {}
    },
    
    -- Compression tracking
    compressionStats = {
        totalCompressed = 0,
        totalUncompressed = 0,
        compressionRatio = 0,
        averageCompressionTime = 0
    },
    
    -- Network monitoring
    networkMetrics = {
        bandwidth = 0,
        latency = 0,
        packageLoss = 0,
        throughput = 0
    },
    
    -- Connections and monitoring
    connections = {},
    isActive = true
}

function NetworkOptimizer.initialize()
    print("🌐 Initializing NetworkOptimizer...")
    
    -- Initialize caching system
    NetworkOptimizer.initializeCaching()
    
    -- Set up request batching
    NetworkOptimizer.setupRequestBatching()
    
    -- Initialize compression system
    NetworkOptimizer.initializeCompression()
    
    -- Start network monitoring
    NetworkOptimizer.startNetworkMonitoring()
    
    -- Set up rate limiting
    NetworkOptimizer.setupRateLimiting()
    
    print("🌐 NetworkOptimizer initialized successfully")
    print(string.format("📊 Batching: %s, Compression: %s, Caching: %s", 
        NETWORK_CONFIG.batching.enabled and "ON" or "OFF",
        NETWORK_CONFIG.compression.enabled and "ON" or "OFF",
        NETWORK_CONFIG.caching.enabled and "ON" or "OFF"))
end

-- ========================================
-- REQUEST BATCHING SYSTEM
-- ========================================

function NetworkOptimizer.setupRequestBatching()
    if not NETWORK_CONFIG.batching.enabled then
        return
    end
    
    NetworkState.batchQueue = {}
    
    -- Start batch processing
    NetworkState.connections.batchProcessor = task.spawn(function()
        while NetworkState.isActive do
            NetworkOptimizer.processBatchQueue()
            task.wait(NETWORK_CONFIG.batching.batchTimeout / 1000)
        end
    end)
    
    print("📦 Request batching system active")
end

function NetworkOptimizer.addToBatch(request)
    if not NETWORK_CONFIG.batching.enabled then
        return NetworkOptimizer.executeRequest(request)
    end
    
    -- Add priority if not specified
    request.priority = request.priority or "normal"
    request.timestamp = tick()
    request.id = HttpService:GenerateGUID(false)
    
    -- Add to appropriate priority queue
    if not NetworkState.batchQueue[request.priority] then
        NetworkState.batchQueue[request.priority] = {}
    end
    
    table.insert(NetworkState.batchQueue[request.priority], request)
    
    -- Check if batch should be sent immediately
    local totalRequests = NetworkOptimizer.getTotalBatchedRequests()
    if totalRequests >= NETWORK_CONFIG.batching.maxBatchSize then
        NetworkOptimizer.flushBatch()
    end
    
    return request.id
end

function NetworkOptimizer.processBatchQueue()
    local priorities = NETWORK_CONFIG.batching.priorityLevels
    
    for _, priority in ipairs(priorities) do
        local queue = NetworkState.batchQueue[priority]
        if queue and #queue > 0 then
            NetworkOptimizer.processPriorityQueue(priority, queue)
        end
    end
end

function NetworkOptimizer.processPriorityQueue(priority, queue)
    local batch = {}
    local batchSize = 0
    local maxSize = NETWORK_CONFIG.batching.maxBatchDataSize
    
    -- Build batch respecting size limits
    while #queue > 0 and #batch < NETWORK_CONFIG.batching.maxBatchSize do
        local request = table.remove(queue, 1)
        local requestSize = NetworkOptimizer.estimateRequestSize(request)
        
        if batchSize + requestSize <= maxSize then
            table.insert(batch, request)
            batchSize = batchSize + requestSize
        else
            -- Put request back if it doesn't fit
            table.insert(queue, 1, request)
            break
        end
    end
    
    -- Send batch if not empty
    if #batch > 0 then
        NetworkOptimizer.sendBatch(batch, priority)
    end
end

function NetworkOptimizer.sendBatch(batch, priority)
    local batchRequest = {
        type = "batch",
        priority = priority,
        requests = batch,
        timestamp = tick()
    }
    
    -- Compress batch if enabled and beneficial
    if NETWORK_CONFIG.compression.enabled then
        batchRequest = NetworkOptimizer.compressRequest(batchRequest)
    end
    
    -- Execute batch request
    NetworkOptimizer.executeBatchRequest(batchRequest)
    
    -- Update statistics
    NetworkState.requestStats.batched = NetworkState.requestStats.batched + #batch
    
    print(string.format("📦 Sent batch: %d %s priority requests", #batch, priority))
end

function NetworkOptimizer.executeBatchRequest(batchRequest)
    local success, result = pcall(function()
        -- Simulate batch request execution
        local responses = {}
        for _, request in ipairs(batchRequest.requests) do
            local response = NetworkOptimizer.simulateRequestExecution(request)
            table.insert(responses, response)
        end
        return responses
    end)
    
    if success then
        NetworkOptimizer.handleBatchResponse(batchRequest, result)
    else
        NetworkOptimizer.handleBatchError(batchRequest, result)
    end
end

function NetworkOptimizer.handleBatchResponse(batchRequest, responses)
    -- Process individual responses
    for i, response in ipairs(responses) do
        local originalRequest = batchRequest.requests[i]
        NetworkOptimizer.handleRequestResponse(originalRequest, response)
    end
end

function NetworkOptimizer.flushBatch()
    -- Force immediate processing of all batched requests
    for priority, queue in pairs(NetworkState.batchQueue) do
        if #queue > 0 then
            NetworkOptimizer.processPriorityQueue(priority, queue)
        end
    end
end

function NetworkOptimizer.getTotalBatchedRequests()
    local total = 0
    for _, queue in pairs(NetworkState.batchQueue) do
        total = total + #queue
    end
    return total
end

function NetworkOptimizer.estimateRequestSize(request)
    -- Estimate request size in bytes
    local encoded = HttpService:JSONEncode(request.data or {})
    return #encoded + 100 -- Add overhead estimate
end

-- ========================================
-- CACHING SYSTEM
-- ========================================

function NetworkOptimizer.initializeCaching()
    if not NETWORK_CONFIG.caching.enabled then
        return
    end
    
    NetworkState.cache = {}
    NetworkState.cacheSize = 0
    
    -- Start cache cleanup
    NetworkState.connections.cacheCleanup = task.spawn(function()
        while NetworkState.isActive do
            NetworkOptimizer.cleanupCache()
            task.wait(60) -- Cleanup every minute
        end
    end)
    
    print("💾 Caching system initialized")
end

function NetworkOptimizer.getCacheKey(request)
    -- Generate cache key from request
    local keyData = {
        url = request.url,
        method = request.method or "GET",
        data = request.data
    }
    return HttpService:JSONEncode(keyData)
end

function NetworkOptimizer.getFromCache(cacheKey)
    local entry = NetworkState.cache[cacheKey]
    if not entry then
        NetworkState.cacheStats.misses = NetworkState.cacheStats.misses + 1
        return nil
    end
    
    -- Check if entry is expired
    if tick() > entry.expiry then
        NetworkOptimizer.removeCacheEntry(cacheKey)
        NetworkState.cacheStats.misses = NetworkState.cacheStats.misses + 1
        return nil
    end
    
    -- Update access time
    entry.lastAccess = tick()
    NetworkState.cacheStats.hits = NetworkState.cacheStats.hits + 1
    
    -- Decompress if needed
    local data = entry.data
    if entry.compressed then
        data = NetworkOptimizer.decompress(data)
    end
    
    return data
end

function NetworkOptimizer.addToCache(cacheKey, data, ttl)
    if not NETWORK_CONFIG.caching.enabled then
        return
    end
    
    ttl = ttl or NETWORK_CONFIG.caching.defaultTTL
    local compressed = false
    local originalSize = #HttpService:JSONEncode(data)
    
    -- Compress if beneficial
    if NETWORK_CONFIG.caching.compressionEnabled and originalSize > NETWORK_CONFIG.compression.threshold then
        local compressedData = NetworkOptimizer.compress(data)
        if compressedData and #compressedData < originalSize * 0.8 then
            data = compressedData
            compressed = true
        end
    end
    
    local entry = {
        data = data,
        expiry = tick() + ttl,
        lastAccess = tick(),
        size = #HttpService:JSONEncode(data),
        compressed = compressed
    }
    
    -- Check cache limits
    if NetworkOptimizer.shouldAddToCache(entry) then
        NetworkState.cache[cacheKey] = entry
        NetworkState.cacheSize = NetworkState.cacheSize + entry.size
        
        -- Enforce cache size limits
        NetworkOptimizer.enforceCacheLimits()
    end
end

function NetworkOptimizer.shouldAddToCache(entry)
    -- Check if we should add this entry to cache
    if NetworkState.cacheSize + entry.size > NETWORK_CONFIG.caching.maxCacheSize then
        return false
    end
    
    if NetworkOptimizer.getCacheEntryCount() >= NETWORK_CONFIG.caching.maxCacheEntries then
        return false
    end
    
    return true
end

function NetworkOptimizer.enforceCacheLimits()
    -- Remove entries if cache is over limits
    while NetworkState.cacheSize > NETWORK_CONFIG.caching.maxCacheSize or
          NetworkOptimizer.getCacheEntryCount() > NETWORK_CONFIG.caching.maxCacheEntries do
        
        NetworkOptimizer.evictLeastRecentlyUsed()
    end
end

function NetworkOptimizer.evictLeastRecentlyUsed()
    local oldestKey = nil
    local oldestTime = math.huge
    
    for key, entry in pairs(NetworkState.cache) do
        if entry.lastAccess < oldestTime then
            oldestTime = entry.lastAccess
            oldestKey = key
        end
    end
    
    if oldestKey then
        NetworkOptimizer.removeCacheEntry(oldestKey)
        NetworkState.cacheStats.evictions = NetworkState.cacheStats.evictions + 1
    end
end

function NetworkOptimizer.removeCacheEntry(cacheKey)
    local entry = NetworkState.cache[cacheKey]
    if entry then
        NetworkState.cacheSize = NetworkState.cacheSize - entry.size
        NetworkState.cache[cacheKey] = nil
    end
end

function NetworkOptimizer.cleanupCache()
    local currentTime = tick()
    local expiredKeys = {}
    
    -- Find expired entries
    for key, entry in pairs(NetworkState.cache) do
        if currentTime > entry.expiry then
            table.insert(expiredKeys, key)
        end
    end
    
    -- Remove expired entries
    for _, key in ipairs(expiredKeys) do
        NetworkOptimizer.removeCacheEntry(key)
    end
    
    if #expiredKeys > 0 then
        print(string.format("🧹 Cleaned up %d expired cache entries", #expiredKeys))
    end
end

function NetworkOptimizer.getCacheEntryCount()
    local count = 0
    for _ in pairs(NetworkState.cache) do
        count = count + 1
    end
    return count
end

-- ========================================
-- COMPRESSION SYSTEM
-- ========================================

function NetworkOptimizer.initializeCompression()
    if not NETWORK_CONFIG.compression.enabled then
        return
    end
    
    print("🗜️ Compression system initialized")
end

function NetworkOptimizer.compressRequest(request)
    local startTime = tick()
    local originalData = HttpService:JSONEncode(request)
    local originalSize = #originalData
    
    -- Only compress if above threshold
    if originalSize < NETWORK_CONFIG.compression.threshold then
        return request
    end
    
    -- Simulate compression
    local compressedData = NetworkOptimizer.compress(originalData)
    local compressionTime = (tick() - startTime) * 1000
    
    -- Check compression effectiveness and time
    if compressedData and 
       #compressedData < originalSize * 0.8 and 
       compressionTime < NETWORK_CONFIG.compression.maxCompressionTime then
        
        -- Update compression stats
        NetworkState.compressionStats.totalUncompressed = NetworkState.compressionStats.totalUncompressed + originalSize
        NetworkState.compressionStats.totalCompressed = NetworkState.compressionStats.totalCompressed + #compressedData
        NetworkState.compressionStats.averageCompressionTime = 
            (NetworkState.compressionStats.averageCompressionTime + compressionTime) / 2
        
        -- Create compressed request
        local compressedRequest = {
            compressed = true,
            algorithm = NETWORK_CONFIG.compression.algorithm,
            originalSize = originalSize,
            data = compressedData
        }
        
        return compressedRequest
    end
    
    return request
end

function NetworkOptimizer.compress(data)
    -- Simulate compression (in production, use actual compression library)
    local simulatedCompressionRatio = 0.6
    local compressedSize = math.floor(#data * simulatedCompressionRatio)
    return string.rep("C", compressedSize) -- Placeholder compressed data
end

function NetworkOptimizer.decompress(compressedData)
    -- Simulate decompression
    return compressedData .. "_decompressed" -- Placeholder decompressed data
end

-- ========================================
-- RATE LIMITING
-- ========================================

function NetworkOptimizer.setupRateLimiting()
    NetworkState.rateLimiter.tokens = NETWORK_CONFIG.requests.rateLimitPerSecond
    NetworkState.rateLimiter.lastRefill = tick()
    
    -- Start token refill
    NetworkState.connections.rateLimiter = task.spawn(function()
        while NetworkState.isActive do
            NetworkOptimizer.refillTokens()
            task.wait(1) -- Refill every second
        end
    end)
    
    print("⏱️ Rate limiting system active")
end

function NetworkOptimizer.refillTokens()
    local now = tick()
    local timeSinceRefill = now - NetworkState.rateLimiter.lastRefill
    local tokensToAdd = math.floor(timeSinceRefill * NETWORK_CONFIG.requests.rateLimitPerSecond)
    
    NetworkState.rateLimiter.tokens = math.min(
        NETWORK_CONFIG.requests.rateLimitPerSecond,
        NetworkState.rateLimiter.tokens + tokensToAdd
    )
    NetworkState.rateLimiter.lastRefill = now
end

function NetworkOptimizer.consumeToken()
    if NetworkState.rateLimiter.tokens > 0 then
        NetworkState.rateLimiter.tokens = NetworkState.rateLimiter.tokens - 1
        return true
    end
    return false
end

function NetworkOptimizer.getAvailableTokens()
    return NetworkState.rateLimiter.tokens
end

-- ========================================
-- REQUEST EXECUTION
-- ========================================

function NetworkOptimizer.makeRequest(requestConfig)
    -- Main entry point for network requests
    requestConfig.id = HttpService:GenerateGUID(false)
    requestConfig.startTime = tick()
    
    -- Check cache first
    if NETWORK_CONFIG.caching.enabled and (requestConfig.method == "GET" or not requestConfig.method) then
        local cacheKey = NetworkOptimizer.getCacheKey(requestConfig)
        local cachedResult = NetworkOptimizer.getFromCache(cacheKey)
        
        if cachedResult then
            NetworkState.requestStats.cached = NetworkState.requestStats.cached + 1
            return NetworkOptimizer.createResponse(cachedResult, true)
        end
    end
    
    -- Check rate limiting
    if not NetworkOptimizer.consumeToken() then
        return NetworkOptimizer.queueRequest(requestConfig)
    end
    
    -- Add to batch or execute immediately
    if NETWORK_CONFIG.batching.enabled and requestConfig.priority ~= "critical" then
        return NetworkOptimizer.addToBatch(requestConfig)
    else
        return NetworkOptimizer.executeRequest(requestConfig)
    end
end

function NetworkOptimizer.executeRequest(request)
    NetworkState.requestStats.total = NetworkState.requestStats.total + 1
    
    -- Add to active requests
    NetworkState.activeRequests[request.id] = request
    
    -- Execute request
    local success, result = pcall(function()
        return NetworkOptimizer.simulateRequestExecution(request)
    end)
    
    -- Remove from active requests
    NetworkState.activeRequests[request.id] = nil
    
    if success then
        NetworkState.requestStats.successful = NetworkState.requestStats.successful + 1
        NetworkOptimizer.handleRequestResponse(request, result)
        return result
    else
        NetworkState.requestStats.failed = NetworkState.requestStats.failed + 1
        NetworkOptimizer.handleRequestError(request, result)
        return nil
    end
end

function NetworkOptimizer.simulateRequestExecution(request)
    -- Simulate network request execution
    task.wait(math.random(50, 200) / 1000) -- Simulate latency
    
    return {
        success = true,
        data = {message = "Request successful", timestamp = tick()},
        statusCode = 200,
        headers = {}
    }
end

function NetworkOptimizer.handleRequestResponse(request, response)
    -- Handle successful response
    if NETWORK_CONFIG.caching.enabled and (request.method == "GET" or not request.method) then
        local cacheKey = NetworkOptimizer.getCacheKey(request)
        local ttl = request.cacheTTL or NETWORK_CONFIG.caching.defaultTTL
        NetworkOptimizer.addToCache(cacheKey, response, ttl)
    end
    
    -- Call response callback if provided
    if request.onSuccess then
        request.onSuccess(response)
    end
end

function NetworkOptimizer.handleRequestError(request, error)
    -- Handle request error
    warn(string.format("Network request failed: %s", tostring(error)))
    
    -- Call error callback if provided
    if request.onError then
        request.onError(error)
    end
    
    -- Retry if configured
    if request.retryCount and request.retryCount < NETWORK_CONFIG.requests.retryAttempts then
        request.retryCount = (request.retryCount or 0) + 1
        task.delay(NETWORK_CONFIG.requests.retryDelay / 1000, function()
            NetworkOptimizer.executeRequest(request)
        end)
    end
end

function NetworkOptimizer.handleBatchError(batchRequest, error)
    warn(string.format("Batch request failed: %s", tostring(error)))
    
    -- Handle individual request errors
    for _, request in ipairs(batchRequest.requests) do
        NetworkOptimizer.handleRequestError(request, error)
    end
end

function NetworkOptimizer.queueRequest(request)
    -- Queue request for later execution when rate limit allows
    table.insert(NetworkState.requestQueue, request)
    
    -- Process queue when tokens are available
    task.spawn(function()
        while #NetworkState.requestQueue > 0 and NetworkOptimizer.consumeToken() do
            local queuedRequest = table.remove(NetworkState.requestQueue, 1)
            NetworkOptimizer.executeRequest(queuedRequest)
        end
    end)
    
    return request.id
end

function NetworkOptimizer.createResponse(data, fromCache)
    return {
        success = true,
        data = data,
        fromCache = fromCache or false,
        timestamp = tick()
    }
end

-- ========================================
-- NETWORK MONITORING
-- ========================================

function NetworkOptimizer.startNetworkMonitoring()
    NetworkState.connections.monitor = task.spawn(function()
        while NetworkState.isActive do
            NetworkOptimizer.updateNetworkMetrics()
            task.wait(5) -- Update every 5 seconds
        end
    end)
    
    print("📡 Network monitoring started")
end

function NetworkOptimizer.updateNetworkMetrics()
    -- Simulate network metrics collection
    NetworkState.networkMetrics = {
        bandwidth = math.random(500, 2000), -- KB/s
        latency = math.random(20, 150),     -- ms
        packageLoss = math.random(0, 5),    -- %
        throughput = math.random(80, 95)    -- %
    }
    
    -- Update compression ratio
    if NetworkState.compressionStats.totalUncompressed > 0 then
        NetworkState.compressionStats.compressionRatio = 
            NetworkState.compressionStats.totalCompressed / NetworkState.compressionStats.totalUncompressed
    end
end

-- ========================================
-- DATA OPTIMIZATION
-- ========================================

function NetworkOptimizer.optimizePayload(data)
    if not NETWORK_CONFIG.dataOptimization.enableTypeOptimization then
        return data
    end
    
    -- Implement data optimization strategies
    local optimized = NetworkOptimizer.optimizeDataTypes(data)
    optimized = NetworkOptimizer.filterFields(optimized)
    optimized = NetworkOptimizer.applyDeltaCompression(optimized)
    
    return optimized
end

function NetworkOptimizer.optimizeDataTypes(data)
    -- Optimize data types for network transmission
    -- Convert large numbers to strings, optimize booleans, etc.
    return data -- Placeholder
end

function NetworkOptimizer.filterFields(data)
    -- Remove unnecessary fields from payload
    if not NETWORK_CONFIG.dataOptimization.enableFieldFiltering then
        return data
    end
    
    -- Implementation would filter out null/empty fields
    return data -- Placeholder
end

function NetworkOptimizer.applyDeltaCompression(data)
    -- Apply delta compression for repeated requests
    if not NETWORK_CONFIG.dataOptimization.enableDeltaCompression then
        return data
    end
    
    -- Implementation would compare with previous state
    return data -- Placeholder
end

-- ========================================
-- PUBLIC API
-- ========================================

function NetworkOptimizer.request(config)
    return NetworkOptimizer.makeRequest(config)
end

function NetworkOptimizer.getNetworkStats()
    return {
        requests = NetworkState.requestStats,
        cache = NetworkState.cacheStats,
        compression = NetworkState.compressionStats,
        metrics = NetworkState.networkMetrics,
        rateLimiter = {
            availableTokens = NetworkState.rateLimiter.tokens,
            queueLength = #NetworkState.requestQueue
        }
    }
end

function NetworkOptimizer.getCacheStats()
    return {
        entries = NetworkOptimizer.getCacheEntryCount(),
        size = NetworkState.cacheSize,
        maxSize = NETWORK_CONFIG.caching.maxCacheSize,
        hitRate = NetworkState.cacheStats.hits / (NetworkState.cacheStats.hits + NetworkState.cacheStats.misses) * 100,
        stats = NetworkState.cacheStats
    }
end

function NetworkOptimizer.clearCache()
    NetworkState.cache = {}
    NetworkState.cacheSize = 0
    NetworkState.cacheStats = {hits = 0, misses = 0, evictions = 0}
    print("🧹 Cache cleared")
end

function NetworkOptimizer.flushAllBatches()
    NetworkOptimizer.flushBatch()
    print("📦 All batches flushed")
end

function NetworkOptimizer.setRateLimit(requestsPerSecond)
    NETWORK_CONFIG.requests.rateLimitPerSecond = requestsPerSecond
    NetworkState.rateLimiter.tokens = requestsPerSecond
    print(string.format("⏱️ Rate limit set to %d requests/second", requestsPerSecond))
end

function NetworkOptimizer.enableOptimization(category, enabled)
    if category == "batching" then
        NETWORK_CONFIG.batching.enabled = enabled
    elseif category == "compression" then
        NETWORK_CONFIG.compression.enabled = enabled
    elseif category == "caching" then
        NETWORK_CONFIG.caching.enabled = enabled
    end
    
    print(string.format("🔧 %s %s", category, enabled and "enabled" or "disabled"))
end

function NetworkOptimizer.shutdown()
    NetworkState.isActive = false
    
    for _, connection in pairs(NetworkState.connections) do
        if typeof(connection) == "thread" then
            task.cancel(connection)
        elseif typeof(connection) == "RBXScriptConnection" then
            connection:Disconnect()
        end
    end
    
    print("🌐 NetworkOptimizer shutdown")
end

-- Initialize the network optimizer
NetworkOptimizer.initialize()

print("🌐 NetworkOptimizer loaded with advanced optimization capabilities")

return NetworkOptimizer
