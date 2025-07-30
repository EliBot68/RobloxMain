-- CacheManager.luau
-- High-performance caching layer for data persistence optimization
-- Implements LRU cache with TTL and smart invalidation strategies

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local SafeRequire = require(ReplicatedStorage.Shared.utils.SafeRequire)
local ServiceArchitecture = SafeRequire.require(ReplicatedStorage.Shared.core.ServiceArchitecture)

local CacheManager = {}
CacheManager.__index = CacheManager

-- Implement ICacheManager interface
setmetatable(CacheManager, {__index = ServiceArchitecture.ICacheManager})

-- ========================================
-- CACHE CONFIGURATION
-- ========================================

local CACHE_CONFIG = {
    maxSize = 1000,           -- Maximum number of cached entries
    defaultTTL = 300,         -- Default TTL in seconds (5 minutes)
    cleanupInterval = 60,     -- Cleanup interval in seconds
    compressionThreshold = 1024, -- Compress entries larger than this
    maxMemoryUsage = 50 * 1024 * 1024, -- 50MB max memory usage
    hitRatioTarget = 0.8,     -- Target cache hit ratio
    evictionStrategy = "LRU"  -- LRU, LFU, or FIFO
}

local CACHE_LEVELS = {
    L1 = {
        name = "L1_Memory",
        maxSize = 100,
        maxTTL = 60,
        priority = 1
    },
    L2 = {
        name = "L2_Memory", 
        maxSize = 500,
        maxTTL = 300,
        priority = 2
    },
    L3 = {
        name = "L3_Persistent",
        maxSize = 1000,
        maxTTL = 3600,
        priority = 3
    }
}

-- ========================================
-- CORE CACHE MANAGER
-- ========================================

function CacheManager.new()
    local self = setmetatable({}, CacheManager)
    
    -- Multi-level cache storage
    self.caches = {}
    for level, config in pairs(CACHE_LEVELS) do
        self.caches[level] = {
            config = config,
            entries = {},
            accessOrder = {},
            stats = {
                hits = 0,
                misses = 0,
                evictions = 0,
                size = 0
            }
        }
    end
    
    -- Cache metadata
    self.globalStats = {
        totalHits = 0,
        totalMisses = 0,
        totalEvictions = 0,
        totalWrites = 0,
        totalDeletes = 0,
        memoryUsage = 0,
        hitRatio = 0
    }
    
    -- Invalidation tracking
    self.invalidationGroups = {}
    self.dependencyMap = {}
    
    -- Start background tasks
    self:StartCleanupTask()
    self:StartStatsUpdater()
    
    print("🚀 CacheManager initialized with multi-level caching")
    return self
end

-- ========================================
-- CACHE OPERATIONS
-- ========================================

function CacheManager:Get(key, defaultValue)
    -- Try each cache level from L1 to L3
    for level, cache in pairs(self.caches) do
        local entry = cache.entries[key]
        
        if entry and not self:IsExpired(entry) then
            -- Cache hit
            cache.stats.hits = cache.stats.hits + 1
            self.globalStats.totalHits = self.globalStats.totalHits + 1
            
            -- Update access order for LRU
            self:UpdateAccessOrder(level, key)
            
            -- Promote to higher cache level if appropriate
            self:PromoteEntry(key, entry, level)
            
            -- Decompress if needed
            local value = entry.compressed and self:DecompressValue(entry.value) or entry.value
            
            print("🎯 Cache hit (L" .. level .. "): " .. key)
            return value
        end
    end
    
    -- Cache miss
    for _, cache in pairs(self.caches) do
        cache.stats.misses = cache.stats.misses + 1
    end
    self.globalStats.totalMisses = self.globalStats.totalMisses + 1
    
    print("❌ Cache miss: " .. key)
    return defaultValue
end

function CacheManager:Set(key, value, ttl, level, tags)
    ttl = ttl or CACHE_CONFIG.defaultTTL
    level = level or "L2"
    tags = tags or {}
    
    if not self.caches[level] then
        warn("⚠️ Invalid cache level: " .. tostring(level))
        level = "L2"
    end
    
    local cache = self.caches[level]
    local now = os.time()
    
    -- Check if compression is needed
    local valueSize = self:CalculateSize(value)
    local shouldCompress = valueSize > CACHE_CONFIG.compressionThreshold
    local finalValue = shouldCompress and self:CompressValue(value) or value
    
    -- Create cache entry
    local entry = {
        key = key,
        value = finalValue,
        compressed = shouldCompress,
        originalSize = valueSize,
        createdAt = now,
        lastAccessed = now,
        expiresAt = now + ttl,
        accessCount = 1,
        level = level,
        tags = tags
    }
    
    -- Check if we need to evict
    if cache.stats.size >= cache.config.maxSize then
        self:EvictEntries(level, 1)
    end
    
    -- Store entry
    cache.entries[key] = entry
    table.insert(cache.accessOrder, key)
    cache.stats.size = cache.stats.size + 1
    self.globalStats.totalWrites = self.globalStats.totalWrites + 1
    
    -- Update memory usage
    self:UpdateMemoryUsage()
    
    -- Handle tags for invalidation groups
    self:ProcessEntryTags(key, tags)
    
    print("💾 Cached (L" .. level .. "): " .. key .. " (TTL: " .. ttl .. "s, Size: " .. valueSize .. " bytes)")
    
    return true
end

function CacheManager:Delete(key)
    local found = false
    
    for level, cache in pairs(self.caches) do
        if cache.entries[key] then
            cache.entries[key] = nil
            cache.stats.size = cache.stats.size - 1
            
            -- Remove from access order
            for i, orderKey in ipairs(cache.accessOrder) do
                if orderKey == key then
                    table.remove(cache.accessOrder, i)
                    break
                end
            end
            
            found = true
            print("🗑️ Deleted from cache (L" .. level .. "): " .. key)
        end
    end
    
    if found then
        self.globalStats.totalDeletes = self.globalStats.totalDeletes + 1
        self:UpdateMemoryUsage()
        
        -- Clean up tag associations
        self:CleanupEntryTags(key)
    end
    
    return found
end

function CacheManager:Has(key)
    for _, cache in pairs(self.caches) do
        local entry = cache.entries[key]
        if entry and not self:IsExpired(entry) then
            return true
        end
    end
    return false
end

function CacheManager:Clear(level)
    if level then
        -- Clear specific level
        local cache = self.caches[level]
        if cache then
            cache.entries = {}
            cache.accessOrder = {}
            cache.stats.size = 0
            print("🧹 Cleared cache level: " .. level)
        end
    else
        -- Clear all levels
        for lvl, cache in pairs(self.caches) do
            cache.entries = {}
            cache.accessOrder = {}
            cache.stats.size = 0
        end
        self.invalidationGroups = {}
        self.dependencyMap = {}
        print("🧹 Cleared all cache levels")
    end
    
    self:UpdateMemoryUsage()
end

-- ========================================
-- CACHE EVICTION
-- ========================================

function CacheManager:EvictEntries(level, count)
    local cache = self.caches[level]
    if not cache then
        return
    end
    
    local evicted = 0
    
    if CACHE_CONFIG.evictionStrategy == "LRU" then
        evicted = self:EvictLRU(level, count)
    elseif CACHE_CONFIG.evictionStrategy == "LFU" then
        evicted = self:EvictLFU(level, count)
    elseif CACHE_CONFIG.evictionStrategy == "FIFO" then
        evicted = self:EvictFIFO(level, count)
    end
    
    cache.stats.evictions = cache.stats.evictions + evicted
    self.globalStats.totalEvictions = self.globalStats.totalEvictions + evicted
    
    if evicted > 0 then
        print("♻️ Evicted " .. evicted .. " entries from L" .. level .. " cache")
    end
    
    return evicted
end

function CacheManager:EvictLRU(level, count)
    local cache = self.caches[level]
    local evicted = 0
    
    -- Evict from the beginning of access order (least recently used)
    while evicted < count and #cache.accessOrder > 0 do
        local keyToEvict = cache.accessOrder[1]
        table.remove(cache.accessOrder, 1)
        
        if cache.entries[keyToEvict] then
            cache.entries[keyToEvict] = nil
            cache.stats.size = cache.stats.size - 1
            evicted = evicted + 1
            
            self:CleanupEntryTags(keyToEvict)
        end
    end
    
    return evicted
end

function CacheManager:EvictLFU(level, count)
    local cache = self.caches[level]
    local evicted = 0
    
    -- Create list of entries sorted by access count
    local sortedEntries = {}
    for key, entry in pairs(cache.entries) do
        table.insert(sortedEntries, {key = key, accessCount = entry.accessCount})
    end
    
    table.sort(sortedEntries, function(a, b)
        return a.accessCount < b.accessCount
    end)
    
    -- Evict least frequently used
    for i = 1, math.min(count, #sortedEntries) do
        local keyToEvict = sortedEntries[i].key
        cache.entries[keyToEvict] = nil
        cache.stats.size = cache.stats.size - 1
        evicted = evicted + 1
        
        -- Remove from access order
        for j, orderKey in ipairs(cache.accessOrder) do
            if orderKey == keyToEvict then
                table.remove(cache.accessOrder, j)
                break
            end
        end
        
        self:CleanupEntryTags(keyToEvict)
    end
    
    return evicted
end

function CacheManager:EvictFIFO(level, count)
    -- Similar to LRU but based on creation time
    return self:EvictLRU(level, count)
end

-- ========================================
-- CACHE PROMOTION AND DEMOTION
-- ========================================

function CacheManager:PromoteEntry(key, entry, currentLevel)
    -- Promote frequently accessed entries to higher cache levels
    if entry.accessCount < 3 then
        return -- Not accessed enough to promote
    end
    
    local targetLevel = nil
    
    if currentLevel == "L3" and entry.accessCount >= 5 then
        targetLevel = "L2"
    elseif currentLevel == "L2" and entry.accessCount >= 10 then
        targetLevel = "L1"
    end
    
    if targetLevel then
        -- Move entry to higher level
        local targetCache = self.caches[targetLevel]
        
        -- Check if target level has space
        if targetCache.stats.size >= targetCache.config.maxSize then
            self:EvictEntries(targetLevel, 1)
        end
        
        -- Create new entry for target level
        local promotedEntry = self:DeepCopy(entry)
        promotedEntry.level = targetLevel
        promotedEntry.lastAccessed = os.time()
        
        -- Add to target level
        targetCache.entries[key] = promotedEntry
        table.insert(targetCache.accessOrder, key)
        targetCache.stats.size = targetCache.stats.size + 1
        
        -- Remove from current level
        local currentCache = self.caches[currentLevel]
        currentCache.entries[key] = nil
        currentCache.stats.size = currentCache.stats.size - 1
        
        -- Remove from access order
        for i, orderKey in ipairs(currentCache.accessOrder) do
            if orderKey == key then
                table.remove(currentCache.accessOrder, i)
                break
            end
        end
        
        print("⬆️ Promoted " .. key .. " from L" .. currentLevel .. " to L" .. targetLevel)
    end
end

-- ========================================
-- INVALIDATION MANAGEMENT
-- ========================================

function CacheManager:InvalidateByTag(tag)
    local invalidated = 0
    
    if self.invalidationGroups[tag] then
        for key in pairs(self.invalidationGroups[tag]) do
            if self:Delete(key) then
                invalidated = invalidated + 1
            end
        end
        
        self.invalidationGroups[tag] = nil
        print("🔄 Invalidated " .. invalidated .. " entries with tag: " .. tag)
    end
    
    return invalidated
end

function CacheManager:InvalidateByPattern(pattern)
    local invalidated = 0
    
    for level, cache in pairs(self.caches) do
        local keysToDelete = {}
        
        for key in pairs(cache.entries) do
            if string.match(key, pattern) then
                table.insert(keysToDelete, key)
            end
        end
        
        for _, key in ipairs(keysToDelete) do
            if self:Delete(key) then
                invalidated = invalidated + 1
            end
        end
    end
    
    print("🔄 Invalidated " .. invalidated .. " entries matching pattern: " .. pattern)
    return invalidated
end

function CacheManager:InvalidateByDependency(dependency)
    local invalidated = 0
    
    if self.dependencyMap[dependency] then
        for key in pairs(self.dependencyMap[dependency]) do
            if self:Delete(key) then
                invalidated = invalidated + 1
            end
        end
        
        self.dependencyMap[dependency] = nil
        print("🔄 Invalidated " .. invalidated .. " entries dependent on: " .. dependency)
    end
    
    return invalidated
end

function CacheManager:ProcessEntryTags(key, tags)
    for _, tag in ipairs(tags) do
        if not self.invalidationGroups[tag] then
            self.invalidationGroups[tag] = {}
        end
        self.invalidationGroups[tag][key] = true
    end
end

function CacheManager:CleanupEntryTags(key)
    -- Remove key from all invalidation groups
    for tag, keys in pairs(self.invalidationGroups) do
        if keys[key] then
            keys[key] = nil
            
            -- Clean up empty groups
            local hasKeys = false
            for _ in pairs(keys) do
                hasKeys = true
                break
            end
            
            if not hasKeys then
                self.invalidationGroups[tag] = nil
            end
        end
    end
    
    -- Remove from dependency map
    for dependency, keys in pairs(self.dependencyMap) do
        if keys[key] then
            keys[key] = nil
            
            -- Clean up empty dependencies
            local hasKeys = false
            for _ in pairs(keys) do
                hasKeys = true
                break
            end
            
            if not hasKeys then
                self.dependencyMap[dependency] = nil
            end
        end
    end
end

-- ========================================
-- BACKGROUND TASKS
-- ========================================

function CacheManager:StartCleanupTask()
    task.spawn(function()
        while true do
            task.wait(CACHE_CONFIG.cleanupInterval)
            self:CleanupExpiredEntries()
            self:OptimizeMemoryUsage()
        end
    end)
    
    print("🧹 Cache cleanup task started (interval: " .. CACHE_CONFIG.cleanupInterval .. "s)")
end

function CacheManager:StartStatsUpdater()
    task.spawn(function()
        while true do
            task.wait(10) -- Update stats every 10 seconds
            self:UpdateGlobalStats()
        end
    end)
end

function CacheManager:CleanupExpiredEntries()
    local cleaned = 0
    
    for level, cache in pairs(self.caches) do
        local keysToDelete = {}
        
        for key, entry in pairs(cache.entries) do
            if self:IsExpired(entry) then
                table.insert(keysToDelete, key)
            end
        end
        
        for _, key in ipairs(keysToDelete) do
            self:Delete(key)
            cleaned = cleaned + 1
        end
    end
    
    if cleaned > 0 then
        print("🧹 Cleaned up " .. cleaned .. " expired cache entries")
    end
end

function CacheManager:OptimizeMemoryUsage()
    -- Check if memory usage is too high
    if self.globalStats.memoryUsage > CACHE_CONFIG.maxMemoryUsage then
        local targetReduction = self.globalStats.memoryUsage - CACHE_CONFIG.maxMemoryUsage
        local reduced = 0
        
        -- Evict from lowest priority levels first
        for level in pairs({"L3", "L2", "L1"}) do
            if reduced >= targetReduction then
                break
            end
            
            local evictCount = math.ceil(self.caches[level].stats.size * 0.1) -- Evict 10%
            self:EvictEntries(level, evictCount)
            reduced = reduced + evictCount * 1000 -- Rough estimate
        end
        
        warn("⚠️ Memory optimization: reduced usage by ~" .. reduced .. " bytes")
    end
end

-- ========================================
-- UTILITY FUNCTIONS
-- ========================================

function CacheManager:IsExpired(entry)
    return os.time() > entry.expiresAt
end

function CacheManager:UpdateAccessOrder(level, key)
    local cache = self.caches[level]
    local entry = cache.entries[key]
    
    if entry then
        entry.lastAccessed = os.time()
        entry.accessCount = entry.accessCount + 1
        
        -- Move to end of access order (most recently used)
        for i, orderKey in ipairs(cache.accessOrder) do
            if orderKey == key then
                table.remove(cache.accessOrder, i)
                table.insert(cache.accessOrder, key)
                break
            end
        end
    end
end

function CacheManager:UpdateMemoryUsage()
    local totalMemory = 0
    
    for _, cache in pairs(self.caches) do
        for _, entry in pairs(cache.entries) do
            totalMemory = totalMemory + (entry.originalSize or 0)
        end
    end
    
    self.globalStats.memoryUsage = totalMemory
end

function CacheManager:UpdateGlobalStats()
    local totalHits = 0
    local totalMisses = 0
    
    for _, cache in pairs(self.caches) do
        totalHits = totalHits + cache.stats.hits
        totalMisses = totalMisses + cache.stats.misses
    end
    
    local totalRequests = totalHits + totalMisses
    self.globalStats.hitRatio = totalRequests > 0 and (totalHits / totalRequests) or 0
end

function CacheManager:CalculateSize(value)
    -- Rough estimation of memory usage
    if type(value) == "string" then
        return string.len(value)
    elseif type(value) == "table" then
        local size = 0
        for k, v in pairs(value) do
            size = size + self:CalculateSize(k) + self:CalculateSize(v)
        end
        return size
    else
        return 8 -- Rough estimate for numbers, booleans, etc.
    end
end

function CacheManager:CompressValue(value)
    -- Simple compression simulation (in practice, use actual compression)
    return {
        compressed = true,
        data = value,
        originalSize = self:CalculateSize(value)
    }
end

function CacheManager:DecompressValue(compressedValue)
    -- Simple decompression
    if type(compressedValue) == "table" and compressedValue.compressed then
        return compressedValue.data
    end
    return compressedValue
end

function CacheManager:DeepCopy(original)
    if type(original) ~= "table" then
        return original
    end
    
    local copy = {}
    for key, value in pairs(original) do
        copy[key] = self:DeepCopy(value)
    end
    
    return copy
end

-- ========================================
-- STATISTICS AND MONITORING
-- ========================================

function CacheManager:GetStatistics()
    self:UpdateGlobalStats()
    self:UpdateMemoryUsage()
    
    local stats = {
        global = self.globalStats,
        levels = {},
        config = CACHE_CONFIG,
        invalidationGroups = 0,
        dependencies = 0
    }
    
    -- Level-specific stats
    for level, cache in pairs(self.caches) do
        stats.levels[level] = {
            config = cache.config,
            stats = cache.stats,
            hitRatio = cache.stats.hits + cache.stats.misses > 0 and 
                      (cache.stats.hits / (cache.stats.hits + cache.stats.misses)) or 0
        }
    end
    
    -- Count invalidation groups and dependencies
    for _ in pairs(self.invalidationGroups) do
        stats.invalidationGroups = stats.invalidationGroups + 1
    end
    
    for _ in pairs(self.dependencyMap) do
        stats.dependencies = stats.dependencies + 1
    end
    
    return stats
end

function CacheManager:GetCacheInfo(key)
    for level, cache in pairs(self.caches) do
        local entry = cache.entries[key]
        if entry then
            return {
                level = level,
                size = entry.originalSize,
                compressed = entry.compressed,
                createdAt = entry.createdAt,
                lastAccessed = entry.lastAccessed,
                expiresAt = entry.expiresAt,
                accessCount = entry.accessCount,
                tags = entry.tags,
                expired = self:IsExpired(entry)
            }
        end
    end
    
    return nil
end

function CacheManager:ListKeys(level, limit)
    local keys = {}
    local count = 0
    
    if level then
        -- List keys from specific level
        local cache = self.caches[level]
        if cache then
            for key in pairs(cache.entries) do
                table.insert(keys, key)
                count = count + 1
                if limit and count >= limit then
                    break
                end
            end
        end
    else
        -- List keys from all levels
        for lvl, cache in pairs(self.caches) do
            for key in pairs(cache.entries) do
                table.insert(keys, {key = key, level = lvl})
                count = count + 1
                if limit and count >= limit then
                    break
                end
            end
        end
    end
    
    return keys
end

return CacheManager
