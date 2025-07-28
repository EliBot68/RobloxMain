-- SafeRequire Utility
-- Provides error-safe module requiring with fallback options and retry logic

local SafeRequire = {}

-- Simple safe require with optional fallback
function SafeRequire.require(modulePath: ModuleScript, fallback: any?)
    local success, result = pcall(function()
        return require(modulePath)
    end)
    
    if success then
        return result, nil -- Return module and no error
    else
        local errorMessage = tostring(result)
        warn(string.format("❌ Failed to require %s: %s", tostring(modulePath), errorMessage))
        if fallback ~= nil then
            warn(string.format("🔄 Using fallback for %s", tostring(modulePath)))
            return fallback, errorMessage -- Return fallback and error
        else
            return nil, errorMessage -- Return nil and error (don't crash with error())
        end
    end
end

-- Safe require with retry logic for unstable dependencies
function SafeRequire.requireWithRetry(modulePath: ModuleScript, maxRetries: number?, fallback: any?)
    maxRetries = maxRetries or 3
    local lastError = nil
    
    for attempt = 1, maxRetries do
        local success, result = pcall(function()
            return require(modulePath)
        end)
        
        if success then
            if attempt > 1 then
                print(string.format("✅ Successfully required %s on attempt %d", tostring(modulePath), attempt))
            end
            return result, nil -- Return module and no error
        else
            lastError = tostring(result)
            warn(string.format("⚠️ Require attempt %d/%d failed for %s: %s", 
                attempt, maxRetries, tostring(modulePath), lastError))
            
            if attempt < maxRetries then
                task.wait(0.1 * attempt) -- Exponential backoff
            end
        end
    end
    
    -- All retries failed
    warn(string.format("💥 Failed to require %s after %d attempts", tostring(modulePath), maxRetries))
    
    if fallback ~= nil then
        warn(string.format("🔄 Using fallback for %s after retry failure", tostring(modulePath)))
        return fallback, lastError -- Return fallback and last error
    else
        return nil, lastError -- Return nil and last error (don't crash with error())
    end
end

-- Batch require multiple modules with individual error handling
function SafeRequire.requireBatch(modules: {[string]: ModuleScript}, fallbacks: {[string]: any}?)
    local results = {}
    local errors = {}
    
    for name, modulePath in pairs(modules) do
        local fallback = fallbacks and fallbacks[name] or nil
        local success, result = pcall(SafeRequire.require, modulePath, fallback)
        
        if success then
            results[name] = result
        else
            errors[name] = result
            results[name] = fallback
        end
    end
    
    if next(errors) then
        warn("🚨 Batch require encountered errors:")
        for name, error in pairs(errors) do
            warn(string.format("  • %s: %s", name, tostring(error)))
        end
    end
    
    return results, errors
end

-- Check if a module exists without requiring it
function SafeRequire.moduleExists(modulePath: ModuleScript): boolean
    local success = pcall(function()
        return require(modulePath)
    end)
    return success
end

-- Require with validation function
function SafeRequire.requireWithValidation(modulePath: ModuleScript, validator: (module: any) -> boolean, fallback: any?)
    local success, module = pcall(function()
        return require(modulePath)
    end)
    
    if not success then
        warn(string.format("❌ Failed to require %s: %s", tostring(modulePath), tostring(module)))
        return fallback
    end
    
    if not validator(module) then
        warn(string.format("❌ Module %s failed validation", tostring(modulePath)))
        return fallback
    end
    
    return module
end

return SafeRequire
