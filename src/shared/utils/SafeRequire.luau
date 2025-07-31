-- SafeRequire.luau
-- Utility for safely requiring modules with proper error handling and fallbacks
-- Enhanced with circular dependency detection and comprehensive error handling

local SafeRequire = {}

-- Cache for loaded modules to avoid repeated requires
local moduleCache = {}
local loadingStack = {} -- Track currently loading modules for circular dependency detection
local dependencyGraph = {} -- Track module dependencies
local loadingAttempts = {} -- Track loading attempts per module

-- Configuration
local RETRY_ATTEMPTS = 3
local RETRY_DELAY = 0.1
local TIMEOUT_DURATION = 10
local MAX_STACK_DEPTH = 20

-- Error tracking
local errorCount = 0
local maxErrors = 50
local errorLog = {}
local performanceStats = {
    totalRequires = 0,
    successfulRequires = 0,
    failedRequires = 0,
    averageLoadTime = 0,
    cacheHits = 0
}

-- Enhanced require function with circular dependency detection and comprehensive error handling
function SafeRequire.require(modulePath, fallback)
    local startTime = tick()
    local modulePathStr = tostring(modulePath)
    
    performanceStats.totalRequires = performanceStats.totalRequires + 1
    
    -- Check cache first
    if moduleCache[modulePathStr] then
        performanceStats.cacheHits = performanceStats.cacheHits + 1
        return moduleCache[modulePathStr]
    end
    
    -- Check for circular dependency
    if SafeRequire._isInLoadingStack(modulePathStr) then
        local circularPath = SafeRequire._getCircularPath(modulePathStr)
        local errorMsg = string.format("Circular dependency detected: %s", circularPath)
        SafeRequire._logError(modulePathStr, errorMsg, "CIRCULAR_DEPENDENCY")
        warn("[SafeRequire] " .. errorMsg)
        return fallback
    end
    
    -- Check loading attempts
    loadingAttempts[modulePathStr] = (loadingAttempts[modulePathStr] or 0) + 1
    if loadingAttempts[modulePathStr] > 10 then
        local errorMsg = string.format("Module %s has been attempted too many times (%d)", 
            modulePathStr, loadingAttempts[modulePathStr])
        SafeRequire._logError(modulePathStr, errorMsg, "TOO_MANY_ATTEMPTS")
        warn("[SafeRequire] " .. errorMsg)
        return fallback
    end
    
    -- Prevent error spam
    if errorCount >= maxErrors then
        warn("[SafeRequire] Maximum error count reached, using fallback for:", modulePathStr)
        return fallback
    end
    
    -- Check stack depth
    if #loadingStack >= MAX_STACK_DEPTH then
        local errorMsg = string.format("Maximum loading stack depth reached (%d)", MAX_STACK_DEPTH)
        SafeRequire._logError(modulePathStr, errorMsg, "STACK_OVERFLOW")
        warn("[SafeRequire] " .. errorMsg)
        return fallback
    end
    
    -- Add to loading stack
    table.insert(loadingStack, modulePathStr)
    
    local success, result
    local attempts = 0
    
    while attempts < RETRY_ATTEMPTS do
        attempts = attempts + 1
        
        success, result = pcall(function()
            return require(modulePath)
        end)
        
        if success then
            -- Remove from loading stack
            SafeRequire._removeFromLoadingStack(modulePathStr)
            
            -- Cache successful require
            moduleCache[modulePathStr] = result
            
            -- Update performance stats
            performanceStats.successfulRequires = performanceStats.successfulRequires + 1
            local loadTime = tick() - startTime
            performanceStats.averageLoadTime = 
                (performanceStats.averageLoadTime * (performanceStats.successfulRequires - 1) + loadTime) / 
                performanceStats.successfulRequires
            
            -- Track dependency
            if #loadingStack > 0 then
                local parent = loadingStack[#loadingStack]
                if not dependencyGraph[parent] then
                    dependencyGraph[parent] = {}
                end
                dependencyGraph[parent][modulePathStr] = true
            end
            
            return result
        else
            local errorMsg = string.format("Attempt %d/%d failed: %s", attempts, RETRY_ATTEMPTS, tostring(result))
            SafeRequire._logError(modulePathStr, errorMsg, "REQUIRE_FAILED")
            
            warn(string.format("[SafeRequire] %s for %s", errorMsg, modulePathStr))
            
            if attempts < RETRY_ATTEMPTS then
                wait(RETRY_DELAY)
            end
        end
    end
    
    -- All attempts failed
    SafeRequire._removeFromLoadingStack(modulePathStr)
    errorCount = errorCount + 1
    performanceStats.failedRequires = performanceStats.failedRequires + 1
    
    local finalErrorMsg = string.format("Failed to require %s after %d attempts", modulePathStr, RETRY_ATTEMPTS)
    SafeRequire._logError(modulePathStr, finalErrorMsg, "FINAL_FAILURE")
    warn("[SafeRequire] " .. finalErrorMsg)
    
    return fallback
end

-- Enhanced require with timeout and monitoring
function SafeRequire.requireWithTimeout(modulePath, timeout, fallback)
    timeout = timeout or TIMEOUT_DURATION
    local modulePathStr = tostring(modulePath)
    
    local startTime = tick()
    local result = nil
    local completed = false
    
    spawn(function()
        result = SafeRequire.require(modulePath, fallback)
        completed = true
    end)
    
    -- Wait for completion or timeout
    while not completed and (tick() - startTime) < timeout do
        wait(0.1)
    end
    
    if not completed then
        local errorMsg = string.format("Timeout after %ds for %s", timeout, modulePathStr)
        SafeRequire._logError(modulePathStr, errorMsg, "TIMEOUT")
        warn("[SafeRequire] " .. errorMsg)
        return fallback
    end
    
    return result
end

-- Preload modules for better performance
function SafeRequire.preload(moduleList, onComplete)
    local loadedCount = 0
    local totalCount = #moduleList
    local results = {}
    
    for i, modulePath in ipairs(moduleList) do
        spawn(function()
            local result = SafeRequire.require(modulePath, nil)
            results[tostring(modulePath)] = result
            loadedCount = loadedCount + 1
            
            if loadedCount == totalCount and onComplete then
                onComplete(results)
            end
        end)
    end
end

-- Batch require multiple modules
function SafeRequire.requireBatch(moduleList, fallbackMap)
    local results = {}
    fallbackMap = fallbackMap or {}
    
    for _, modulePath in ipairs(moduleList) do
        local modulePathStr = tostring(modulePath)
        results[modulePathStr] = SafeRequire.require(modulePath, fallbackMap[modulePathStr])
    end
    
    return results
end

-- Enhanced module existence check with caching
function SafeRequire.moduleExists(modulePath)
    local modulePathStr = tostring(modulePath)
    
    -- Check cache first
    if moduleCache[modulePathStr] then
        return true
    end
    
    local success = pcall(function()
        require(modulePath)
    end)
    
    return success
end

-- Safe module validation - checks if module returns expected type
function SafeRequire.validateModule(modulePath, expectedType, fallback)
    local module = SafeRequire.require(modulePath, fallback)
    
    if module == nil then
        return fallback
    end
    
    if expectedType and type(module) ~= expectedType then
        local errorMsg = string.format("Module %s returned %s, expected %s", 
            tostring(modulePath), type(module), expectedType)
        SafeRequire._logError(tostring(modulePath), errorMsg, "TYPE_MISMATCH")
        warn("[SafeRequire] " .. errorMsg)
        return fallback
    end
    
    return module
end

-- Require with retry on specific errors
function SafeRequire.requireWithRetry(modulePath, retryCondition, maxRetries, fallback)
    maxRetries = maxRetries or RETRY_ATTEMPTS
    local attempt = 0
    
    while attempt < maxRetries do
        attempt = attempt + 1
        
        local success, result = pcall(function()
            return require(modulePath)
        end)
        
        if success then
            return result
        elseif retryCondition and not retryCondition(result) then
            -- Error doesn't match retry condition, fail immediately
            break
        end
        
        if attempt < maxRetries then
            wait(RETRY_DELAY * attempt) -- Exponential backoff
        end
    end
    
    return fallback
end

-- Enhanced cache management
function SafeRequire.clearCache(modulePath)
    if modulePath then
        moduleCache[tostring(modulePath)] = nil
        loadingAttempts[tostring(modulePath)] = nil
    end
end

-- Clear all cached modules with options
function SafeRequire.clearAllCache(clearAttempts)
    moduleCache = {}
    
    if clearAttempts then
        loadingAttempts = {}
    end
end

-- Get cache information
function SafeRequire.getCacheInfo()
    local cacheInfo = {
        totalCached = 0,
        modules = {}
    }
    
    for modulePath, module in pairs(moduleCache) do
        cacheInfo.totalCached = cacheInfo.totalCached + 1
        cacheInfo.modules[modulePath] = {
            type = type(module),
            attempts = loadingAttempts[modulePath] or 0
        }
    end
    
    return cacheInfo
end

-- Force reload a module (clears cache and re-requires)
function SafeRequire.forceReload(modulePath, fallback)
    SafeRequire.clearCache(modulePath)
    return SafeRequire.require(modulePath, fallback)
end

-- Get error statistics
function SafeRequire.getStats()
    return {
        errorCount = errorCount,
        maxErrors = maxErrors,
        cacheSize = #moduleCache
    }
end

-- Reset error count
function SafeRequire.resetErrorCount()
    errorCount = 0
end

-- Get comprehensive statistics
function SafeRequire.getDetailedStats()
    return {
        errorCount = errorCount,
        maxErrors = maxErrors,
        cacheSize = #moduleCache,
        performance = performanceStats,
        loadingStackSize = #loadingStack,
        dependencyCount = #dependencyGraph,
        errorLogSize = #errorLog
    }
end

-- Get dependency graph
function SafeRequire.getDependencyGraph()
    return dependencyGraph
end

-- Get error log
function SafeRequire.getErrorLog(maxEntries)
    maxEntries = maxEntries or 50
    local recentErrors = {}
    local startIndex = math.max(1, #errorLog - maxEntries + 1)
    
    for i = startIndex, #errorLog do
        table.insert(recentErrors, errorLog[i])
    end
    
    return recentErrors
end

-- Check if module has circular dependencies
function SafeRequire.hasCircularDependency(modulePath)
    return SafeRequire._detectCircularDependency(tostring(modulePath), {})
end

-- Internal helper functions
function SafeRequire._isInLoadingStack(modulePathStr)
    for _, path in ipairs(loadingStack) do
        if path == modulePathStr then
            return true
        end
    end
    return false
end

function SafeRequire._getCircularPath(modulePathStr)
    local path = {}
    local found = false
    
    for _, stackPath in ipairs(loadingStack) do
        if found or stackPath == modulePathStr then
            found = true
            table.insert(path, stackPath)
        end
    end
    
    table.insert(path, modulePathStr)
    return table.concat(path, " -> ")
end

function SafeRequire._removeFromLoadingStack(modulePathStr)
    for i = #loadingStack, 1, -1 do
        if loadingStack[i] == modulePathStr then
            table.remove(loadingStack, i)
            break
        end
    end
end

function SafeRequire._logError(modulePathStr, errorMsg, errorType)
    local errorEntry = {
        timestamp = tick(),
        time = os.date("%Y-%m-%d %H:%M:%S"),
        module = modulePathStr,
        message = errorMsg,
        type = errorType,
        stack = table.concat(loadingStack, " -> ")
    }
    
    table.insert(errorLog, errorEntry)
    
    -- Keep only last 1000 errors to prevent memory issues
    if #errorLog > 1000 then
        table.remove(errorLog, 1)
    end
end

function SafeRequire._detectCircularDependency(modulePathStr, visited)
    if visited[modulePathStr] then
        return true
    end
    
    visited[modulePathStr] = true
    
    if dependencyGraph[modulePathStr] then
        for dependency, _ in pairs(dependencyGraph[modulePathStr]) do
            if SafeRequire._detectCircularDependency(dependency, visited) then
                return true
            end
        end
    end
    
    visited[modulePathStr] = nil
    return false
end

-- Configuration functions
function SafeRequire.setRetryAttempts(attempts)
    RETRY_ATTEMPTS = math.max(1, math.min(10, attempts))
end

function SafeRequire.setRetryDelay(delay)
    RETRY_DELAY = math.max(0.01, math.min(5, delay))
end

function SafeRequire.setTimeoutDuration(duration)
    TIMEOUT_DURATION = math.max(1, math.min(60, duration))
end

function SafeRequire.setMaxErrors(max)
    maxErrors = math.max(10, math.min(1000, max))
end

return SafeRequire
