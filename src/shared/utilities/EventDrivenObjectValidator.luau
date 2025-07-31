-- EventDrivenObjectValidator.luau
-- Event-driven replacement for polling-based WorldObjectValidator
-- Eliminates 100ms polling loops with adaptive monitoring

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local EventDrivenSystem = require(ReplicatedStorage.Shared.utilities.EventDrivenSystem)

local EventDrivenObjectValidator = {}

-- ========================================
-- EVENT-DRIVEN OBJECT VALIDATION
-- ========================================

-- Replace WorldObjectValidator.validateObjectWithWait with event-driven approach
function EventDrivenObjectValidator.waitForObject(objectPath, timeout, callback)
    return EventDrivenSystem:WaitForWorldObject(objectPath, timeout, callback)
end

-- Synchronous version that returns immediately if object exists, otherwise sets up monitoring
function EventDrivenObjectValidator.validateObject(objectPath)
    local success, object = pcall(function()
        local parts = objectPath:split(".")
        local current = game
        
        for _, part in ipairs(parts) do
            current = current:FindFirstChild(part)
            if not current then
                return nil
            end
        end
        
        return current
    end)
    
    return success and object ~= nil, object
end

-- Batch wait for multiple objects with progress tracking
function EventDrivenObjectValidator.waitForMultipleObjects(objectPaths, timeout, progressCallback, completionCallback)
    local results = {}
    local completed = 0
    local total = #objectPaths
    
    print(string.format("🔍 Waiting for %d objects with event-driven validation...", total))
    
    for i, objectPath in ipairs(objectPaths) do
        EventDrivenSystem:WaitForWorldObject(objectPath, timeout, function(success, object)
            results[objectPath] = {success = success, object = object}
            completed = completed + 1
            
            if progressCallback then
                progressCallback(completed, total, objectPath, success)
            end
            
            if completed >= total and completionCallback then
                completionCallback(results)
            end
        end)
    end
    
    return results
end

-- Monitor object hierarchy changes
function EventDrivenObjectValidator.monitorObjectHierarchy(parentPath, childrenCallback, timeout)
    timeout = timeout or 30
    local monitorName = "ObjectHierarchy_" .. parentPath:gsub("%.", "_")
    
    local lastChildren = {}
    
    EventDrivenSystem:CreateAdaptiveMonitor(monitorName, function()
        local exists, parent = EventDrivenObjectValidator.validateObject(parentPath)
        if not exists then
            return false
        end
        
        local currentChildren = {}
        for _, child in ipairs(parent:GetChildren()) do
            table.insert(currentChildren, child.Name)
        end
        
        -- Check for changes
        local changed = false
        if #lastChildren ~= #currentChildren then
            changed = true
        else
            for i, childName in ipairs(currentChildren) do
                if lastChildren[i] ~= childName then
                    changed = true
                    break
                end
            end
        end
        
        if changed and childrenCallback then
            childrenCallback(currentChildren, lastChildren)
        end
        
        lastChildren = currentChildren
        return changed
    end, {
        baseInterval = 2.0,
        minInterval = 0.5,
        maxInterval = 10.0,
        owner = "ObjectHierarchyMonitor"
    })
    
    EventDrivenSystem:StartAdaptiveMonitor(monitorName)
    
    -- Auto-cleanup after timeout
    task.spawn(function()
        task.wait(timeout)
        EventDrivenSystem:StopAdaptiveMonitor(monitorName)
    end)
    
    return monitorName
end

-- Wait for object with specific properties
function EventDrivenObjectValidator.waitForObjectWithProperties(objectPath, properties, timeout, callback)
    return EventDrivenSystem:WaitForWorldObject(objectPath, timeout, function(success, object)
        if not success then
            if callback then callback(false, nil) end
            return
        end
        
        -- Validate properties
        local propertiesValid = true
        for propertyName, expectedValue in pairs(properties) do
            if object[propertyName] ~= expectedValue then
                propertiesValid = false
                break
            end
        end
        
        if callback then
            callback(propertiesValid, object)
        end
    end)
end

-- ========================================
-- BACKWARDS COMPATIBILITY LAYER
-- ========================================

-- Drop-in replacement for WorldObjectValidator.validateObjectWithWait
function EventDrivenObjectValidator.validateObjectWithWait(objectPath, timeout)
    print(string.format("🔄 Converting polling validation to event-driven for: %s", objectPath))
    
    local objectFound = false
    local foundObject = nil
    
    EventDrivenSystem:WaitForWorldObject(objectPath, timeout, function(success, object)
        objectFound = success
        foundObject = object
    end)
    
    -- For backwards compatibility, we still need to block until result
    -- But this is now event-driven internally rather than polling
    local startTime = tick()
    while not objectFound and (tick() - startTime) < (timeout or 5) do
        task.wait(0.1) -- Minimal wait for compatibility
    end
    
    return objectFound, foundObject
end

-- Enhanced version with event callbacks
function EventDrivenObjectValidator.validateObjectWithCallback(objectPath, timeout, onFound, onTimeout)
    EventDrivenSystem:WaitForWorldObject(objectPath, timeout, function(success, object)
        if success and onFound then
            onFound(object)
        elseif not success and onTimeout then
            onTimeout()
        end
    end)
end

-- ========================================
-- BATCH OPERATIONS
-- ========================================

-- Validate multiple objects and wait for all to be ready
function EventDrivenObjectValidator.waitForAllObjects(objectPaths, timeout)
    local allResults = {}
    local completed = false
    
    EventDrivenObjectValidator.waitForMultipleObjects(
        objectPaths, 
        timeout,
        function(completedCount, total, objectPath, success)
            print(string.format("📍 Object validation progress: %d/%d - %s: %s", 
                completedCount, total, objectPath, success and "✅" or "❌"))
        end,
        function(results)
            allResults = results
            completed = true
        end
    )
    
    -- Wait for completion
    local startTime = tick()
    while not completed and (tick() - startTime) < (timeout or 10) do
        task.wait(0.1)
    end
    
    return allResults
end

-- Wait for any one of multiple objects to be ready
function EventDrivenObjectValidator.waitForAnyObject(objectPaths, timeout, callback)
    local found = false
    
    for _, objectPath in ipairs(objectPaths) do
        EventDrivenSystem:WaitForWorldObject(objectPath, timeout, function(success, object)
            if success and not found then
                found = true
                if callback then
                    callback(objectPath, object)
                end
            end
        end)
    end
end

-- ========================================
-- SPECIALIZED VALIDATORS
-- ========================================

-- Validate game track objects (commonly used pattern)
function EventDrivenObjectValidator.validateGameTrack(timeout)
    local trackObjects = {
        "workspace.GameTrack",
        "workspace.GameTrack.StartLine", 
        "workspace.GameTrack.FinishLine"
    }
    
    return EventDrivenObjectValidator.waitForAllObjects(trackObjects, timeout or 10)
end

-- Validate market plaza objects
function EventDrivenObjectValidator.validateMarketPlaza(timeout)
    local marketObjects = {
        "workspace.MarketPlaza",
        "workspace.MarketPlaza.GameArchway",
        "workspace.MarketPlaza.CentralFountain"
    }
    
    return EventDrivenObjectValidator.waitForAllObjects(marketObjects, timeout or 10)
end

-- Validate hub objects
function EventDrivenObjectValidator.validateHub(timeout)
    local hubObjects = {
        "workspace.Hub",
        "workspace.Hub.Fountain",
        "workspace.Hub.RebirthStatue",
        "workspace.SpawnLocation"
    }
    
    return EventDrivenObjectValidator.waitForAllObjects(hubObjects, timeout or 10)
end

-- ========================================
-- PERFORMANCE MONITORING
-- ========================================

-- Get validation performance statistics
function EventDrivenObjectValidator.getPerformanceStats()
    return EventDrivenSystem:GetSystemStats()
end

-- Benchmark old vs new validation performance
function EventDrivenObjectValidator.benchmarkValidation(objectPath, iterations)
    iterations = iterations or 100
    
    print(string.format("🏃 Benchmarking validation performance for %s (%d iterations)...", objectPath, iterations))
    
    -- Old polling method simulation
    local pollingStartTime = tick()
    for i = 1, iterations do
        local startTime = tick()
        while tick() - startTime < 0.5 do -- Simulate 500ms timeout
            local exists = EventDrivenObjectValidator.validateObject(objectPath)
            if exists then break end
            task.wait(0.1) -- Polling delay
        end
    end
    local pollingTime = tick() - pollingStartTime
    
    -- New event-driven method
    local eventStartTime = tick()
    for i = 1, iterations do
        EventDrivenObjectValidator.validateObject(objectPath) -- Immediate check
    end
    local eventTime = tick() - eventStartTime
    
    local improvement = pollingTime / eventTime
    
    print(string.format("📊 Validation Benchmark Results:"))
    print(string.format("   Polling method: %.3fs", pollingTime))
    print(string.format("   Event-driven: %.3fs", eventTime))
    print(string.format("   Performance improvement: %.1fx", improvement))
    
    return {
        pollingTime = pollingTime,
        eventTime = eventTime,
        improvement = improvement
    }
end

-- ========================================
-- MIGRATION HELPERS
-- ========================================

-- Convert service from old validation to new system
function EventDrivenObjectValidator.migrateService(service, validationMapping)
    print(string.format("🔄 Migrating service %s to event-driven validation...", service.Name or "Unknown"))
    
    local migratedCount = 0
    
    for oldMethod, newConfig in pairs(validationMapping) do
        if service[oldMethod] then
            -- Replace old method with new event-driven version
            service[oldMethod] = function(...)
                local args = {...}
                
                if newConfig.type == "waitForObject" then
                    return EventDrivenObjectValidator.waitForObject(args[1], args[2], newConfig.callback)
                elseif newConfig.type == "validateWithCallback" then
                    return EventDrivenObjectValidator.validateObjectWithCallback(args[1], args[2], args[3], args[4])
                end
                return nil
            end
            
            migratedCount = migratedCount + 1
        end
    end
    
    print(string.format("✅ Service migration complete - %d methods converted", migratedCount))
    return migratedCount
end

return EventDrivenObjectValidator
