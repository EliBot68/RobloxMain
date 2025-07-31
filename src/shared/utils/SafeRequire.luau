-- SafeRequire.luau
-- Utility for safely requiring modules with proper error handling and fallbacks

local SafeRequire = {}

-- Cache for loaded modules to avoid repeated requires
local moduleCache = {}

-- Configuration
local RETRY_ATTEMPTS = 3
local RETRY_DELAY = 0.1
local TIMEOUT_DURATION = 10

-- Error tracking
local errorCount = 0
local maxErrors = 50

-- Safe require function with error handling
function SafeRequire.require(modulePath, fallback)
    -- Check cache first
    if moduleCache[modulePath] then
        return moduleCache[modulePath]
    end
    
    -- Prevent error spam
    if errorCount >= maxErrors then
        warn("[SafeRequire] Maximum error count reached, using fallback for:", modulePath)
        return fallback
    end
    
    local success, result
    local attempts = 0
    
    while attempts < RETRY_ATTEMPTS do
        attempts = attempts + 1
        
        success, result = pcall(function()
            return require(modulePath)
        end)
        
        if success then
            -- Cache successful require
            moduleCache[modulePath] = result
            return result
        else
            warn(string.format("[SafeRequire] Attempt %d/%d failed for %s: %s", 
                attempts, RETRY_ATTEMPTS, tostring(modulePath), tostring(result)))
            
            if attempts < RETRY_ATTEMPTS then
                wait(RETRY_DELAY)
            end
        end
    end
    
    -- All attempts failed
    errorCount = errorCount + 1
    warn(string.format("[SafeRequire] Failed to require %s after %d attempts", 
        tostring(modulePath), RETRY_ATTEMPTS))
    
    return fallback
end

-- Safe require with timeout
function SafeRequire.requireWithTimeout(modulePath, timeout, fallback)
    timeout = timeout or TIMEOUT_DURATION
    
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
        warn(string.format("[SafeRequire] Timeout after %ds for %s", timeout, tostring(modulePath)))
        return fallback
    end
    
    return result
end

-- Check if module exists without requiring
function SafeRequire.moduleExists(modulePath)
    local success = pcall(function()
        return require(modulePath)
    end)
    return success
end

-- Clear cache for a specific module
function SafeRequire.clearCache(modulePath)
    moduleCache[modulePath] = nil
end

-- Clear all cached modules
function SafeRequire.clearAllCache()
    moduleCache = {}
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

return SafeRequire
