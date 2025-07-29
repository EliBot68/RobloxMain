-- PerformanceOptimizer.luau
-- Utilities to replace tight polling loops with event-driven patterns and optimize performance
-- Provides tools to convert while true loops to intelligent monitoring systems

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local ConfigurationManager = require(ReplicatedStorage.Shared.core.ConfigurationManager)

local PerformanceOptimizer = {}

-- ========================================
-- EVENT-DRIVEN PATTERN REPLACEMENTS
-- ========================================

-- Replace tight polling with intelligent event-driven monitoring
function PerformanceOptimizer:CreateSmartMonitor(config)
    --[[
    config = {
        name = "MonitorName",
        checkFunction = function() ... end,
        onTrigger = function(result) ... end,
        interval = 1.0, -- seconds
        condition = function(result) return result ~= nil end, -- when to trigger
        maxChecksPerSecond = 10, -- performance limit
        adaptiveInterval = true -- adjust interval based on results
    }
    --]]
    
    local monitor = {
        name = config.name or "UnnamedMonitor",
        isRunning = false,
        connection = nil,
        stats = {
            checks = 0,
            triggers = 0,
            avgInterval = config.interval or 1.0,
            lastCheck = 0,
            adaptiveMultiplier = 1.0
        }
    }
    
    function monitor:Start()
        if self.isRunning then
            warn("⚠️ Monitor '" .. self.name .. "' is already running")
            return false
        end
        
        self.isRunning = true
        local lastCheckTime = 0
        local maxInterval = 1.0 / (config.maxChecksPerSecond or 10)
        
        self.connection = RunService.Heartbeat:Connect(function()
            local currentTime = tick()
            local targetInterval = (config.interval or 1.0) * self.stats.adaptiveMultiplier
            
            -- Respect performance limits
            if currentTime - lastCheckTime < math.max(targetInterval, maxInterval) then
                return
            end
            
            lastCheckTime = currentTime
            self.stats.checks = self.stats.checks + 1
            self.stats.lastCheck = currentTime
            
            -- Execute check function
            local success, result = pcall(config.checkFunction)
            if not success then
                warn("❌ Monitor '" .. self.name .. "' check failed: " .. tostring(result))
                return
            end
            
            -- Check trigger condition
            if config.condition and config.condition(result) then
                self.stats.triggers = self.stats.triggers + 1
                
                -- Execute trigger function
                local triggerSuccess, triggerResult = pcall(config.onTrigger, result)
                if not triggerSuccess then
                    warn("❌ Monitor '" .. self.name .. "' trigger failed: " .. tostring(triggerResult))
                end
                
                -- Adaptive interval adjustment
                if config.adaptiveInterval then
                    -- Decrease interval when triggers are frequent (more responsive)
                    self.stats.adaptiveMultiplier = math.max(0.5, self.stats.adaptiveMultiplier * 0.9)
                end
            else
                -- Adaptive interval adjustment
                if config.adaptiveInterval then
                    -- Increase interval when no triggers (less CPU usage)
                    self.stats.adaptiveMultiplier = math.min(3.0, self.stats.adaptiveMultiplier * 1.05)
                end
            end
        end)
        
        print("🔍 Started smart monitor: " .. self.name .. " (interval: " .. (config.interval or 1.0) .. "s)")
        return true
    end
    
    function monitor:Stop()
        if not self.isRunning then
            return false
        end
        
        self.isRunning = false
        if self.connection then
            self.connection:Disconnect()
            self.connection = nil
        end
        
        print("⏹️ Stopped monitor: " .. self.name)
        return true
    end
    
    function monitor:GetStats()
        local runtime = tick() - (self.stats.lastCheck or 0)
        return {
            name = self.name,
            checks = self.stats.checks,
            triggers = self.stats.triggers,
            triggerRate = self.stats.triggers / math.max(self.stats.checks, 1),
            avgInterval = self.stats.avgInterval,
            currentMultiplier = self.stats.adaptiveMultiplier,
            isRunning = self.isRunning
        }
    end
    
    return monitor
end

-- Batch processing to reduce performance overhead
function PerformanceOptimizer:CreateBatchProcessor(config)
    --[[
    config = {
        name = "BatchProcessor",
        batchSize = 10,
        maxWaitTime = 1.0, -- seconds
        processFunction = function(batch) ... end,
        onError = function(error, batch) ... end
    }
    --]]
    
    local processor = {
        name = config.name or "UnnamedBatchProcessor",
        batch = {},
        lastProcessTime = tick(),
        isRunning = false,
        connection = nil,
        stats = {
            itemsProcessed = 0,
            batchesProcessed = 0,
            errors = 0
        }
    }
    
    function processor:Add(item)
        table.insert(self.batch, item)
        
        -- Process if batch is full
        if #self.batch >= (config.batchSize or 10) then
            self:ProcessBatch()
        end
    end
    
    function processor:ProcessBatch()
        if #self.batch == 0 then
            return
        end
        
        local batchToProcess = self.batch
        self.batch = {}
        self.lastProcessTime = tick()
        
        local success, result = pcall(config.processFunction, batchToProcess)
        if success then
            self.stats.itemsProcessed = self.stats.itemsProcessed + #batchToProcess
            self.stats.batchesProcessed = self.stats.batchesProcessed + 1
        else
            self.stats.errors = self.stats.errors + 1
            if config.onError then
                pcall(config.onError, result, batchToProcess)
            else
                warn("❌ Batch processor '" .. self.name .. "' failed: " .. tostring(result))
            end
        end
    end
    
    function processor:Start()
        if self.isRunning then
            return false
        end
        
        self.isRunning = true
        local maxWaitTime = config.maxWaitTime or 1.0
        
        -- Auto-process batches that have been waiting too long
        self.connection = RunService.Heartbeat:Connect(function()
            if #self.batch > 0 and tick() - self.lastProcessTime >= maxWaitTime then
                self:ProcessBatch()
            end
        end)
        
        print("🔄 Started batch processor: " .. self.name .. " (batch size: " .. (config.batchSize or 10) .. ")")
        return true
    end
    
    function processor:Stop()
        if not self.isRunning then
            return false
        end
        
        self.isRunning = false
        if self.connection then
            self.connection:Disconnect()
            self.connection = nil
        end
        
        -- Process remaining items
        self:ProcessBatch()
        
        print("⏹️ Stopped batch processor: " .. self.name)
        return true
    end
    
    return processor
end

-- ========================================
-- POLLING LOOP REPLACEMENTS
-- ========================================

-- Replace while true loops with intelligent monitoring
function PerformanceOptimizer:ConvertPollingLoop(oldLoopFunction, monitorConfig)
    --[[
    Usage:
    Instead of:
        while true do
            checkSomething()
            task.wait(0.1)
        end
    
    Use:
        PerformanceOptimizer:ConvertPollingLoop(checkSomething, {
            name = "SomethingChecker",
            interval = 0.5,
            adaptiveInterval = true
        })
    --]]
    
    local defaultConfig = {
        name = "ConvertedLoop",
        checkFunction = oldLoopFunction,
        onTrigger = function() end, -- Default no-op
        condition = function() return true end, -- Always trigger
        interval = 0.5, -- Default 500ms instead of 100ms
        adaptiveInterval = true,
        maxChecksPerSecond = 10
    }
    
    -- Merge configs
    for key, value in pairs(monitorConfig or {}) do
        defaultConfig[key] = value
    end
    
    return self:CreateSmartMonitor(defaultConfig)
end

-- Convert anti-cheat style monitoring loops
function PerformanceOptimizer:CreateAntiCheatMonitor(playerCheckFunction, config)
    config = config or {}
    
    return self:CreateSmartMonitor({
        name = config.name or "AntiCheatMonitor",
        checkFunction = function()
            local results = {}
            for _, player in ipairs(game.Players:GetPlayers()) do
                local result = playerCheckFunction(player)
                if result then
                    results[player.UserId] = result
                end
            end
            return results
        end,
        onTrigger = config.onViolation or function(violations)
            for playerId, violation in pairs(violations) do
                warn("🚨 Anti-cheat violation for player " .. playerId .. ": " .. tostring(violation))
            end
        end,
        condition = function(results)
            return next(results) ~= nil -- Has violations
        end,
        interval = config.interval or 1.0, -- Check every second instead of constantly
        adaptiveInterval = true,
        maxChecksPerSecond = 2 -- Limit anti-cheat to 2 checks per second max
    })
end

-- ========================================
-- MEMORY LEAK DETECTION
-- ========================================

-- Detect and fix common memory leak patterns
function PerformanceOptimizer:CreateMemoryLeakDetector()
    local detector = {
        trackedObjects = {},
        leakThresholds = {
            connections = 100,
            instances = 1000,
            tables = 500
        },
        lastReport = 0
    }
    
    function detector:TrackObject(objectType, object, owner)
        if not self.trackedObjects[objectType] then
            self.trackedObjects[objectType] = {}
        end
        
        if not self.trackedObjects[objectType][owner] then
            self.trackedObjects[objectType][owner] = {}
        end
        
        table.insert(self.trackedObjects[objectType][owner], {
            object = object,
            timestamp = tick(),
            type = typeof(object)
        })
    end
    
    function detector:CheckForLeaks()
        local currentTime = tick()
        local leaks = {}
        
        for objectType, owners in pairs(self.trackedObjects) do
            for owner, objects in pairs(owners) do
                local count = #objects
                local threshold = self.leakThresholds[objectType] or 100
                
                if count > threshold then
                    leaks[owner] = leaks[owner] or {}
                    leaks[owner][objectType] = count
                end
            end
        end
        
        return leaks
    end
    
    function detector:StartMonitoring()
        return PerformanceOptimizer:CreateSmartMonitor({
            name = "MemoryLeakDetector",
            checkFunction = function()
                return self:CheckForLeaks()
            end,
            onTrigger = function(leaks)
                for owner, objectTypes in pairs(leaks) do
                    local message = "🚨 MEMORY LEAK DETECTED for " .. tostring(owner) .. ":"
                    for objectType, count in pairs(objectTypes) do
                        message = message .. "\n  " .. objectType .. ": " .. count .. " objects"
                    end
                    warn(message)
                end
            end,
            condition = function(leaks)
                return next(leaks) ~= nil
            end,
            interval = 10.0, -- Check every 10 seconds
            adaptiveInterval = false
        })
    end
    
    return detector
end

-- ========================================
-- ASSET CLEANUP SYSTEM
-- ========================================

-- Automatic cleanup for old/unused assets and cached data
function PerformanceOptimizer:CreateAssetCleanupSystem()
    local cleanupSystem = {
        cachedAssets = {},
        assetMetadata = {},
        cleanupThresholds = {
            maxAge = 300, -- 5 minutes
            maxCacheSize = 100,
            maxMemoryUsage = 50 * 1024 -- 50 MB
        }
    }
    
    function cleanupSystem:CacheAsset(assetId, assetData, metadata)
        self.cachedAssets[assetId] = assetData
        self.assetMetadata[assetId] = {
            timestamp = tick(),
            size = metadata and metadata.size or 0,
            accessCount = 0,
            lastAccess = tick()
        }
    end
    
    function cleanupSystem:GetAsset(assetId)
        local asset = self.cachedAssets[assetId]
        if asset and self.assetMetadata[assetId] then
            self.assetMetadata[assetId].accessCount = self.assetMetadata[assetId].accessCount + 1
            self.assetMetadata[assetId].lastAccess = tick()
        end
        return asset
    end
    
    function cleanupSystem:CleanupOldAssets()
        local currentTime = tick()
        local cleanedCount = 0
        local freedMemory = 0
        
        for assetId, metadata in pairs(self.assetMetadata) do
            local age = currentTime - metadata.timestamp
            local timeSinceAccess = currentTime - metadata.lastAccess
            
            local shouldCleanup = age > self.cleanupThresholds.maxAge or
                                  timeSinceAccess > self.cleanupThresholds.maxAge or
                                  metadata.accessCount == 0
            
            if shouldCleanup then
                self.cachedAssets[assetId] = nil
                freedMemory = freedMemory + metadata.size
                self.assetMetadata[assetId] = nil
                cleanedCount = cleanedCount + 1
            end
        end
        
        return cleanedCount, freedMemory
    end
    
    function cleanupSystem:StartAutoCleanup()
        return PerformanceOptimizer:CreateSmartMonitor({
            name = "AssetCleanupSystem",
            checkFunction = function()
                return self:CleanupOldAssets()
            end,
            onTrigger = function(result)
                local cleanedCount, freedMemory = result[1], result[2]
                if cleanedCount > 0 then
                    print("🧹 Asset cleanup: removed " .. cleanedCount .. " assets, freed " .. 
                          math.floor(freedMemory / 1024) .. " KB")
                end
            end,
            condition = function(result)
                return result[1] > 0 -- Has assets to clean
            end,
            interval = 30.0, -- Check every 30 seconds
            adaptiveInterval = true
        })
    end
    
    return cleanupSystem
end

-- ========================================
-- PERFORMANCE MONITORING
-- ========================================

-- Monitor and report performance degradation
function PerformanceOptimizer:CreatePerformanceMonitor()
    local monitor = {
        performanceHistory = {},
        thresholds = {
            maxFrameTime = 16.67, -- 60 FPS target
            maxMemoryGrowth = 1024, -- 1 MB per minute
            maxCPUUsage = 80 -- 80%
        },
        alerts = {}
    }
    
    function monitor:RecordPerformance()
        local currentTime = tick()
        local frameTime = 1000 / (workspace:GetRealPhysicsFPS() or 60) -- ms
        local memory = collectgarbage("count")
        
        local sample = {
            timestamp = currentTime,
            frameTime = frameTime,
            memory = memory,
            fps = workspace:GetRealPhysicsFPS()
        }
        
        table.insert(self.performanceHistory, sample)
        
        -- Keep only last 60 samples (1 minute at 1Hz)
        if #self.performanceHistory > 60 then
            table.remove(self.performanceHistory, 1)
        end
        
        return sample
    end
    
    function monitor:AnalyzePerformance()
        if #self.performanceHistory < 10 then
            return nil
        end
        
        local recent = {}
        for i = math.max(1, #self.performanceHistory - 10), #self.performanceHistory do
            table.insert(recent, self.performanceHistory[i])
        end
        
        local avgFrameTime = 0
        local memoryGrowth = 0
        
        for i, sample in ipairs(recent) do
            avgFrameTime = avgFrameTime + sample.frameTime
            if i > 1 then
                memoryGrowth = memoryGrowth + (sample.memory - recent[i-1].memory)
            end
        end
        
        avgFrameTime = avgFrameTime / #recent
        memoryGrowth = memoryGrowth / math.max(#recent - 1, 1)
        
        local issues = {}
        
        if avgFrameTime > self.thresholds.maxFrameTime then
            table.insert(issues, "HIGH_FRAME_TIME")
        end
        
        if memoryGrowth > self.thresholds.maxMemoryGrowth then
            table.insert(issues, "MEMORY_LEAK")
        end
        
        return {
            avgFrameTime = avgFrameTime,
            memoryGrowth = memoryGrowth,
            issues = issues
        }
    end
    
    function monitor:StartMonitoring()
        return PerformanceOptimizer:CreateSmartMonitor({
            name = "PerformanceMonitor",
            checkFunction = function()
                self:RecordPerformance()
                return self:AnalyzePerformance()
            end,
            onTrigger = function(analysis)
                if analysis and #analysis.issues > 0 then
                    local message = "⚠️ PERFORMANCE DEGRADATION DETECTED:"
                    for _, issue in ipairs(analysis.issues) do
                        if issue == "HIGH_FRAME_TIME" then
                            message = message .. "\n  High frame time: " .. 
                                     string.format("%.2f", analysis.avgFrameTime) .. "ms"
                        elseif issue == "MEMORY_LEAK" then
                            message = message .. "\n  Memory growth: " .. 
                                     string.format("%.2f", analysis.memoryGrowth) .. "KB/sample"
                        end
                    end
                    warn(message)
                end
            end,
            condition = function(analysis)
                return analysis and #analysis.issues > 0
            end,
            interval = 1.0,
            adaptiveInterval = true
        })
    end
    
    return monitor
end

-- ========================================
-- INITIALIZATION
-- ========================================

-- Initialize performance optimizer with common optimizations
function PerformanceOptimizer:Init()
    print("⚡ PerformanceOptimizer initializing...")
    
    -- Start global performance monitoring
    local performanceMonitor = self:CreatePerformanceMonitor()
    performanceMonitor:StartMonitoring()
    
    -- Start memory leak detection
    local leakDetector = self:CreateMemoryLeakDetector()
    leakDetector:StartMonitoring()
    
    -- Start asset cleanup system
    local assetCleanup = self:CreateAssetCleanupSystem()
    assetCleanup:StartAutoCleanup()
    
    print("✅ PerformanceOptimizer initialized with global monitoring")
    return true
end

return PerformanceOptimizer
