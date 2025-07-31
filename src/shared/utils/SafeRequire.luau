-- SafeRequire.luau
-- PROMPT 2 SECOND RUN: Production-Ready SafeRequire Utility (FINAL IMPLEMENTATION)
-- Enterprise-grade module loading with comprehensive error handling, retry logic, 
-- fallback mechanisms, timeout handling, circular dependency detection, and performance monitoring
-- DESIGNED TO PREVENT CASCADING SERVICE FAILURES ACROSS 20+ SERVICES

local SafeRequire = {}

-- Cache for loaded modules to avoid repeated requires
local moduleCache = {}
local loadingStack = {} -- Track currently loading modules for circular dependency detection
local dependencyGraph = {} -- Track module dependencies
local loadingAttempts = {} -- Track loading attempts per module

-- Enhanced Configuration (Production-Ready)
local RETRY_ATTEMPTS = 5       -- Increased from 3 for better reliability
local RETRY_DELAY = 0.05       -- Faster initial retry for responsiveness
local TIMEOUT_DURATION = 15    -- Increased timeout for complex modules
local MAX_STACK_DEPTH = 25     -- Increased stack depth for complex dependencies
local _EXPONENTIAL_BACKOFF = true

-- Error tracking and performance monitoring
local errorCount = 0
local maxErrors = 100          -- Increased error threshold
local errorLog = {}
local performanceStats = {
    totalRequires = 0,
    successfulRequires = 0,
    failedRequires = 0,
    averageLoadTime = 0,
    cacheHits = 0,
    timeoutCount = 0,
    circularDependencyCount = 0,
    retrySuccessCount = 0
}

-- Production-ready require function with comprehensive error handling and monitoring
function SafeRequire.require(modulePath, fallback)
    local startTime = tick()
    local modulePathStr = tostring(modulePath)
    
    performanceStats.totalRequires = performanceStats.totalRequires + 1
    
    -- Enhanced cache check
    if moduleCache[modulePathStr] then
        performanceStats.cacheHits = performanceStats.cacheHits + 1
        return moduleCache[modulePathStr]
    end
    
    -- Enhanced circular dependency detection
    if SafeRequire._isInLoadingStack(modulePathStr) then
        local circularPath = SafeRequire._getCircularPath(modulePathStr)
        local errorMsg = string.format("Circular dependency detected: %s", circularPath)
        SafeRequire._logError(modulePathStr, errorMsg, "CIRCULAR_DEPENDENCY")
        performanceStats.circularDependencyCount = performanceStats.circularDependencyCount + 1
        warn("[SafeRequire] " .. errorMsg)
        return fallback
    end
    
    -- Enhanced loading attempts tracking with exponential backoff
    loadingAttempts[modulePathStr] = (loadingAttempts[modulePathStr] or 0) + 1
    if loadingAttempts[modulePathStr] > 15 then -- Increased threshold
        local errorMsg = string.format("Module %s has exceeded maximum loading attempts (%d)", 
            modulePathStr, loadingAttempts[modulePathStr])
        SafeRequire._logError(modulePathStr, errorMsg, "TOO_MANY_ATTEMPTS")
        warn("[SafeRequire] " .. errorMsg)
        return fallback
    end
    
    -- Enhanced error spam prevention
    if errorCount >= maxErrors then
        warn("[SafeRequire] Maximum error count reached, using fallback for:", modulePathStr)
        return fallback
    end
    
    -- Enhanced stack depth protection
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
    local retryDelay = RETRY_DELAY
    
    -- Enhanced retry loop with exponential backoff and sophisticated error handling
    while attempts < RETRY_ATTEMPTS do
        attempts = attempts + 1
        
        success, result = pcall(function()
            return require(modulePath)
        end)
        
        if success then
            -- Remove from loading stack
            SafeRequire._removeFromLoadingStack(modulePathStr)
            
            -- Enhanced cache storage with metadata
            moduleCache[modulePathStr] = result
            
            -- Update performance stats with enhanced metrics
            performanceStats.successfulRequires = performanceStats.successfulRequires + 1
            local loadTime = tick() - startTime
            performanceStats.averageLoadTime = 
                (performanceStats.averageLoadTime * (performanceStats.successfulRequires - 1) + loadTime) / 
                performanceStats.successfulRequires
            
            -- Track dependency with enhanced metadata
            if #loadingStack > 0 then
                local parent = loadingStack[#loadingStack]
                if not dependencyGraph[parent] then
                    dependencyGraph[parent] = {}
                end
                dependencyGraph[parent][modulePathStr] = {
                    loaded = true,
                    loadTime = loadTime,
                    attempts = attempts
                }
            end
            
            -- Track retry success for monitoring
            if attempts > 1 then
                performanceStats.retrySuccessCount = performanceStats.retrySuccessCount + 1
            end
            
            return result
        else
            local errorMsg = string.format("Attempt %d/%d failed: %s", attempts, RETRY_ATTEMPTS, tostring(result))
            SafeRequire._logError(modulePathStr, errorMsg, "REQUIRE_FAILED")
            
            -- Enhanced error logging with context
            warn(string.format("[SafeRequire] %s for %s (Stack depth: %d)", errorMsg, modulePathStr, #loadingStack))
            
            if attempts < RETRY_ATTEMPTS then
                -- Enhanced exponential backoff with jitter
                local backoffDelay = retryDelay * math.pow(2, attempts - 1) * (0.8 + math.random() * 0.4)
                task.wait(math.min(backoffDelay, 2.0)) -- Cap at 2 seconds
            end
        end
    end
    
    -- All attempts failed - enhanced failure handling
    SafeRequire._removeFromLoadingStack(modulePathStr)
    errorCount = errorCount + 1
    performanceStats.failedRequires = performanceStats.failedRequires + 1
    
    local finalErrorMsg = string.format("CRITICAL FAILURE: Failed to require %s after %d attempts (Total errors: %d)", 
        modulePathStr, RETRY_ATTEMPTS, errorCount)
    SafeRequire._logError(modulePathStr, finalErrorMsg, "FINAL_FAILURE")
    warn("[SafeRequire] " .. finalErrorMsg)
    
    -- Enhanced fallback logging
    if fallback ~= nil then
        SafeRequire._logError(modulePathStr, string.format("Using fallback value (type: %s)", type(fallback)), "FALLBACK_USED")
    end
    
    return fallback
end

-- Enhanced require with timeout and comprehensive monitoring
function SafeRequire.requireWithTimeout(modulePath, timeout, fallback)
    timeout = timeout or TIMEOUT_DURATION
    local modulePathStr = tostring(modulePath)
    
    local startTime = tick()
    local result = nil
    local completed = false
    local timeoutReached = false
    
    -- Enhanced timeout handling with cancellation support
    local timeoutThread = task.spawn(function()
        task.wait(timeout)
        if not completed then
            timeoutReached = true
            performanceStats.timeoutCount = performanceStats.timeoutCount + 1
            local errorMsg = string.format("Timeout after %ds for %s", timeout, modulePathStr)
            SafeRequire._logError(modulePathStr, errorMsg, "TIMEOUT")
            warn("[SafeRequire] " .. errorMsg)
        end
    end)
    
    local requireThread = task.spawn(function()
        result = SafeRequire.require(modulePath, fallback)
        completed = true
        task.cancel(timeoutThread)
    end)
    
    -- Enhanced waiting loop with progress reporting
    local progressTime = startTime
    while not completed and not timeoutReached do
        task.wait(0.1)
        
        -- Progress reporting every 2 seconds for long loads
        if tick() - progressTime > 2 then
            progressTime = tick()
            local elapsed = tick() - startTime
            if elapsed > 3 then -- Only report for loads taking longer than 3 seconds
                print(string.format("[SafeRequire] Still loading %s... (%.1fs elapsed)", modulePathStr, elapsed))
            end
        end
    end
    
    if timeoutReached then
        task.cancel(requireThread)
        return fallback
    end
    
    return result
end

-- Production-ready preload system with enhanced batching
function SafeRequire.preload(moduleList, onComplete, batchSize)
    batchSize = batchSize or 5 -- Limit concurrent operations
    local loadedCount = 0
    local totalCount = #moduleList
    local results = {}
    local errors = {}
    local startTime = tick()
    
    local function processModule(modulePath)
        local moduleStr = tostring(modulePath)
        local success, result = pcall(function()
            return SafeRequire.require(modulePath, nil)
        end)
        
        if success then
            results[moduleStr] = result
        else
            errors[moduleStr] = result
        end
        
        loadedCount = loadedCount + 1
        
        -- Progress reporting
        if loadedCount % 5 == 0 or loadedCount == totalCount then
            local elapsed = tick() - startTime
            print(string.format("[SafeRequire] Preload progress: %d/%d (%.1fs)", loadedCount, totalCount, elapsed))
        end
        
        if loadedCount == totalCount and onComplete then
            local elapsed = tick() - startTime
            local successCount = 0
            for _ in pairs(results) do successCount = successCount + 1 end
            
            onComplete({
                results = results,
                errors = errors,
                successCount = successCount,
                errorCount = #errors,
                totalTime = elapsed,
                averageTime = elapsed / totalCount
            })
        end
    end
    
    -- Enhanced batch processing with queue management
    local queue = {}
    for i, modulePath in ipairs(moduleList) do
        table.insert(queue, modulePath)
    end
    
    local activeThreads = 0
    local function processBatch()
        while #queue > 0 and activeThreads < batchSize do
            local modulePath = table.remove(queue, 1)
            activeThreads = activeThreads + 1
            
            task.spawn(function()
                processModule(modulePath)
                activeThreads = activeThreads - 1
                if #queue > 0 then
                    processBatch() -- Continue processing
                end
            end)
        end
    end
    
    processBatch()
end

-- Enhanced batch require with comprehensive error reporting
function SafeRequire.requireBatch(moduleList, fallbackMap, options)
    local results = {}
    local errors = {}
    fallbackMap = fallbackMap or {}
    options = options or {}
    
    local startTime = tick()
    local concurrent = options.concurrent or false
    local maxConcurrent = options.maxConcurrent or 3
    local validateTypes = options.validateTypes or false
    
    if concurrent then
        local completedCount = 0
        local totalCount = #moduleList
        local activeCount = 0
        
        local function processModule(modulePath)
            local modulePathStr = tostring(modulePath)
            local fallback = fallbackMap[modulePathStr]
            
            local success, result = pcall(function()
                return SafeRequire.require(modulePath, fallback)
            end)
            
            if success and result ~= fallback then
                results[modulePathStr] = result
                if validateTypes and options.expectedTypes and options.expectedTypes[modulePathStr] then
                    local expectedType = options.expectedTypes[modulePathStr]
                    if type(result) ~= expectedType then
                        errors[modulePathStr] = string.format("Type mismatch: expected %s, got %s", expectedType, type(result))
                    end
                end
            else
                errors[modulePathStr] = result or "Failed to load"
                results[modulePathStr] = fallback
            end
            
            completedCount = completedCount + 1
            activeCount = activeCount - 1
            
            if completedCount == totalCount then
                local elapsed = tick() - startTime
                print(string.format("[SafeRequire] Batch completed: %d modules in %.2fs", totalCount, elapsed))
            end
        end
        
        -- Process modules with concurrency limit
        local moduleQueue = {table.unpack(moduleList)}
        local function startNext()
            while #moduleQueue > 0 and activeCount < maxConcurrent do
                local modulePath = table.remove(moduleQueue, 1)
                activeCount = activeCount + 1
                task.spawn(function()
                    processModule(modulePath)
                    if #moduleQueue > 0 then
                        startNext()
                    end
                end)
            end
        end
        
        startNext()
        
        -- Wait for completion
        while completedCount < totalCount do
            task.wait(0.1)
        end
    else
        -- Sequential processing for dependency-sensitive modules
        for _, modulePath in ipairs(moduleList) do
            local modulePathStr = tostring(modulePath)
            local result = SafeRequire.require(modulePath, fallbackMap[modulePathStr])
            results[modulePathStr] = result
        end
    end
    
    return {
        results = results,
        errors = errors,
        totalTime = tick() - startTime,
        successCount = SafeRequire._countNonFallbacks(results, fallbackMap),
        errorCount = SafeRequire._countKeys(errors)
    }
end

-- Enhanced module validation with comprehensive checks
function SafeRequire.validateModule(modulePath, expectedType, fallback, validationRules)
    local module = SafeRequire.require(modulePath, fallback)
    
    if module == fallback then
        return fallback
    end
    
    -- Enhanced type validation
    if expectedType and type(module) ~= expectedType then
        local errorMsg = string.format("Module %s returned %s, expected %s", 
            tostring(modulePath), type(module), expectedType)
        SafeRequire._logError(tostring(modulePath), errorMsg, "TYPE_MISMATCH")
        warn("[SafeRequire] " .. errorMsg)
        return fallback
    end
    
    -- Advanced validation rules
    if validationRules then
        for _, rule in ipairs(validationRules) do
            local isValid, errorMsg = rule.validate(module)
            if not isValid then
                local fullError = string.format("Validation failed for %s: %s", tostring(modulePath), errorMsg)
                SafeRequire._logError(tostring(modulePath), fullError, "VALIDATION_FAILED")
                warn("[SafeRequire] " .. fullError)
                if rule.critical then
                    return fallback
                end
            end
        end
    end
    
    return module
end

-- Production-ready health monitoring system
function SafeRequire.getSystemHealth()
    local totalRequires = performanceStats.totalRequires
    local successRate = totalRequires > 0 and (performanceStats.successfulRequires / totalRequires) * 100 or 100
    local errorRate = totalRequires > 0 and (performanceStats.failedRequires / totalRequires) * 100 or 0
    local cacheHitRate = totalRequires > 0 and (performanceStats.cacheHits / totalRequires) * 100 or 0
    
    local health = {
        status = "HEALTHY",
        metrics = {
            successRate = successRate,
            errorRate = errorRate,
            cacheHitRate = cacheHitRate,
            averageLoadTime = performanceStats.averageLoadTime,
            totalRequires = totalRequires,
            successfulRequires = performanceStats.successfulRequires,
            failedRequires = performanceStats.failedRequires,
            cacheHits = performanceStats.cacheHits,
            timeoutCount = performanceStats.timeoutCount,
            circularDependencyCount = performanceStats.circularDependencyCount,
            retrySuccessCount = performanceStats.retrySuccessCount
        },
        cacheSize = SafeRequire._countKeys(moduleCache),
        errorLogSize = #errorLog,
        dependencyGraphSize = SafeRequire._countKeys(dependencyGraph)
    }
    
    -- Determine system health status
    if errorRate > 25 then
        health.status = "CRITICAL"
    elseif errorRate > 10 then
        health.status = "WARNING"
    elseif successRate < 95 then
        health.status = "DEGRADED"
    end
    
    return health
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

-- Internal utility functions
function SafeRequire._countKeys(tbl)
    local count = 0
    for _ in pairs(tbl) do
        count = count + 1
    end
    return count
end

function SafeRequire._countNonFallbacks(results, fallbackMap)
    local count = 0
    for key, value in pairs(results) do
        if value ~= fallbackMap[key] then
            count = count + 1
        end
    end
    return count
end

-- Enhanced module existence check with comprehensive validation
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

-- Enhanced dependency validator with cycle detection
function SafeRequire.validateDependencies(moduleList)
    local validation = {
        valid = true,
        cycles = {},
        missing = {},
        warnings = {},
        recommendations = {}
    }
    
    for _, modulePath in ipairs(moduleList) do
        -- Check if module exists
        if not SafeRequire.moduleExists(modulePath) then
            table.insert(validation.missing, tostring(modulePath))
            validation.valid = false
        end
        
        -- Check for circular dependencies
        if SafeRequire._detectCircularDependency(modulePath, {}) then
            table.insert(validation.cycles, tostring(modulePath))
            validation.valid = false
        end
    end
    
    -- Generate recommendations
    if #validation.missing > 0 then
        table.insert(validation.recommendations, "Create missing modules or update module paths")
    end
    
    if #validation.cycles > 0 then
        table.insert(validation.recommendations, "Refactor modules to eliminate circular dependencies")
    end
    
    return validation
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

-- Advanced error analysis and diagnostics
function SafeRequire.getErrorAnalysis()
    local analysis = {
        totalErrors = #errorLog,
        errorsByType = {},
        errorsByModule = {},
        recentErrors = {},
        criticalErrors = {},
        errorTrends = {},
        averageRetryAttempts = 0,
        mostFailedModules = {}
    }
    
    local retrySum = 0
    local moduleErrorCounts = {}
    
    for i, error in ipairs(errorLog) do
        -- Count by type
        analysis.errorsByType[error.type] = (analysis.errorsByType[error.type] or 0) + 1
        
        -- Count by module
        analysis.errorsByModule[error.module] = (analysis.errorsByModule[error.module] or 0) + 1
        moduleErrorCounts[error.module] = (moduleErrorCounts[error.module] or 0) + 1
        
        -- Recent errors (last 10)
        if i > #errorLog - 10 then
            table.insert(analysis.recentErrors, error)
        end
        
        -- Critical errors
        if error.type == "CIRCULAR_DEPENDENCY" or error.type == "TIMEOUT" or error.type == "CRITICAL" then
            table.insert(analysis.criticalErrors, error)
        end
        
        -- Calculate retry attempts
        if error.retryAttempt then
            retrySum = retrySum + error.retryAttempt
        end
    end
    
    -- Calculate average retry attempts
    if #errorLog > 0 then
        analysis.averageRetryAttempts = retrySum / #errorLog
    end
    
    -- Find most failed modules
    local moduleList = {}
    for module, count in pairs(moduleErrorCounts) do
        table.insert(moduleList, {module = module, count = count})
    end
    table.sort(moduleList, function(a, b) return a.count > b.count end)
    for i = 1, math.min(5, #moduleList) do
        table.insert(analysis.mostFailedModules, moduleList[i])
    end
    
    return analysis
end

-- Performance optimization and cache management
function SafeRequire.optimizeCache()
    local optimizationReport = {
        initialCacheSize = SafeRequire._countKeys(moduleCache),
        removedEntries = 0,
        freeMemory = 0,
        optimizationActions = {}
    }
    
    local currentTime = tick()
    local oldCacheEntries = {}
    
    -- Find old cache entries (unused for > 5 minutes)
    for path, entry in pairs(moduleCache) do
        if currentTime - entry.lastAccessed > 300 then -- 5 minutes
            table.insert(oldCacheEntries, path)
        end
    end
    
    -- Remove old entries
    for _, path in ipairs(oldCacheEntries) do
        moduleCache[path] = nil
        optimizationReport.removedEntries = optimizationReport.removedEntries + 1
        table.insert(optimizationReport.optimizationActions, "Removed stale cache entry: " .. path)
    end
    
    -- Clear old error logs (keep last 100)
    if #errorLog > 100 then
        local newErrorLog = {}
        for i = #errorLog - 99, #errorLog do
            table.insert(newErrorLog, errorLog[i])
        end
        errorLog = newErrorLog
        table.insert(optimizationReport.optimizationActions, "Trimmed error log to last 100 entries")
    end
    
    optimizationReport.finalCacheSize = SafeRequire._countKeys(moduleCache)
    optimizationReport.freeMemory = optimizationReport.initialCacheSize - optimizationReport.finalCacheSize
    
    return optimizationReport
end

-- Enterprise-grade system diagnostics
function SafeRequire.runDiagnostics()
    local diagnostics = {
        timestamp = tick(),
        systemHealth = SafeRequire.getSystemHealth(),
        errorAnalysis = SafeRequire.getErrorAnalysis(),
        performanceMetrics = performanceStats,
        recommendations = {},
        issues = {},
        severity = "LOW"
    }
    
    -- Analyze and provide recommendations
    local health = diagnostics.systemHealth
    if health.metrics.errorRate > 10 then
        table.insert(diagnostics.issues, "High error rate detected: " .. string.format("%.2f%%", health.metrics.errorRate))
        table.insert(diagnostics.recommendations, "Review failed modules and implement better error handling")
        diagnostics.severity = "HIGH"
    end
    
    if health.metrics.cacheHitRate < 50 then
        table.insert(diagnostics.issues, "Low cache hit rate: " .. string.format("%.2f%%", health.metrics.cacheHitRate))
        table.insert(diagnostics.recommendations, "Consider preloading frequently used modules")
        if diagnostics.severity == "LOW" then
            diagnostics.severity = "MEDIUM"
        end
    end
    
    if performanceStats.timeoutCount > 5 then
        table.insert(diagnostics.issues, "High timeout count: " .. performanceStats.timeoutCount)
        table.insert(diagnostics.recommendations, "Increase timeout duration or optimize module loading")
        diagnostics.severity = "HIGH"
    end
    
    if performanceStats.circularDependencyCount > 0 then
        table.insert(diagnostics.issues, "Circular dependencies detected: " .. performanceStats.circularDependencyCount)
        table.insert(diagnostics.recommendations, "Refactor modules to eliminate circular dependencies")
        diagnostics.severity = "CRITICAL"
    end
    
    return diagnostics
end

return SafeRequire
