-- ModernCleanupService.luau
-- Enhanced cleanup service with comprehensive memory management
-- Converted to modern service architecture eliminating _G.GetService() patterns

local Workspace = game:GetService("Workspace")
local Players = game:GetService("Players")
local _Debris = game:GetService("Debris")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local ModernServiceFramework = require(ReplicatedStorage.Shared.core.ModernServiceFramework)

-- Create modern service with dependency injection
local CleanupService = ModernServiceFramework.CreateService("CleanupService", {
    Dependencies = {},
    OptionalDependencies = {"MainGameService", "ArchwayService", "AnalyticsService"},
    Priority = 80, -- Background service - low priority
    Testable = true,
    ErrorBoundary = function(errorInfo)
        -- Handle cleanup errors gracefully
        if errorInfo.type == "RuntimeError" then
            warn("🛡️ CleanupService: Cleanup error handled gracefully:", errorInfo.message)
            return true -- Continue cleanup operations
        end
        return false
    end
})

-- ========================================
-- SERVICE STATE AND CONFIGURATION
-- ========================================

-- Memory cleanup tracking
local _lastFullCleanup = 0
local cleanupStats = {
    totalCleanupsPerformed = 0,
    lastCleanupTime = 0,
    playersCleanedUp = 0,
    sessionsCleanedUp = 0,
    memoryReclaimed = 0,
    partsRemoved = 0
}

-- Items to remove for performance optimization
local ITEMS_TO_REMOVE = {
    "OldSpawn",
    "LegacySpawn", 
    "TestSpawn",
    "DefaultSpawn",
    "TempSpawn",
    "DebugSpawn"
}

-- Buildings and structures to clean up
local BUILDINGS_TO_REMOVE = {
    "OldBuilding",
    "LegacyStructure", 
    "TestBuilding",
    "TempStructure",
    "DebugBuilding",
    "UnusedModel"
}

-- Performance optimization settings
local CLEANUP_CONFIG = {
    memoryThreshold = 1024 * 1024 * 100, -- 100MB threshold
    cleanupInterval = 300, -- 5 minutes
    maxItemsPerCleanup = 50,
    garbageCollectionCycles = 3,
    deepCleanupInterval = 1800 -- 30 minutes
}

-- ========================================
-- SERVICE LIFECYCLE METHODS
-- ========================================

function CleanupService:Init(config)
    self.Config = config or {}
    
    -- Initialize cleanup tracking
    self:_initializeCleanupMetrics()
    
    -- Setup cleanup schedules
    self:_setupCleanupSchedules()
    
    -- Setup player cleanup handlers
    self:_setupPlayerCleanupHandlers()
    
    print("🔧 CleanupService initialized with modern architecture")
end

function CleanupService:Start()
    -- Start periodic cleanup
    self:_startPeriodicCleanup()
    
    -- Start memory monitoring
    self:_startMemoryMonitoring()
    
    -- Start performance optimization
    self:_startPerformanceOptimization()
    
    print("▶️ CleanupService started successfully")
end

function CleanupService:Stop()
    -- Perform final cleanup
    self:PerformFullCleanup()
    
    -- Save cleanup statistics
    self:_saveCleanupStats()
    
    print("⏹️ CleanupService stopped and performed final cleanup")
end

-- ========================================
-- PRIVATE INITIALIZATION METHODS
-- ========================================

function CleanupService:_initializeCleanupMetrics()
    cleanupStats = {
        totalCleanupsPerformed = 0,
        lastCleanupTime = tick(),
        playersCleanedUp = 0,
        sessionsCleanedUp = 0,
        memoryReclaimed = 0,
        partsRemoved = 0,
        startTime = tick()
    }
end

function CleanupService:_setupCleanupSchedules()
    -- Schedule regular cleanup cycles
    local function scheduleCleanup()
        self:PerformMaintenanceCleanup()
        task.delay(CLEANUP_CONFIG.cleanupInterval, scheduleCleanup)
    end
    
    -- Schedule deep cleanup cycles  
    local function scheduleDeepCleanup()
        self:PerformFullCleanup()
        task.delay(CLEANUP_CONFIG.deepCleanupInterval, scheduleDeepCleanup)
    end
    
    -- Start scheduling
    task.delay(CLEANUP_CONFIG.cleanupInterval, scheduleCleanup)
    task.delay(CLEANUP_CONFIG.deepCleanupInterval, scheduleDeepCleanup)
end

function CleanupService:_setupPlayerCleanupHandlers()
    -- Handle player leaving
    Players.PlayerRemoving:Connect(function(player)
        self:CleanupPlayerData(player)
    end)
    
    -- Handle character cleanup
    Players.PlayerAdded:Connect(function(player)
        player.CharacterRemoving:Connect(function(character)
            self:CleanupCharacterData(character)
        end)
    end)
end

-- ========================================
-- CORE CLEANUP METHODS
-- ========================================

function CleanupService:PerformFullCleanup()
    print("🚀 Starting full workspace cleanup and optimization...")
    local startTime = tick()
    
    -- Step 1: Remove old spawn points
    self:RemoveOldSpawnPoints()
    
    -- Step 2: Remove old buildings (sequenced with task.delay)
    task.delay(1, function()
        self:RemoveOldBuildings() 
        
        -- Step 3: Optimize performance (sequenced)
        task.delay(1, function()
            self:OptimizeWorkspacePerformance()
            
            -- Step 4: Clean memory
            task.delay(1, function()
                self:CleanupMemoryLeaks()
                
                -- Step 5: Event-driven final garbage collection (NO POLLING)
                local gcCycles = 0
                local function finalGarbageCollection()
                    if gcCycles < CLEANUP_CONFIG.garbageCollectionCycles then
                        collectgarbage("collect")
                        gcCycles = gcCycles + 1
                        task.delay(0.15, finalGarbageCollection) -- Optimized interval
                    else
                        local endTime = tick()
                        local duration = endTime - startTime
                        
                        print("✅ Full cleanup and optimization complete!")
                        print(string.format("📊 Cleanup completed in %.2fs", duration))
                        
                        -- Report final workspace stats
                        self:_reportWorkspaceStats()
                        
                        -- Update cleanup metrics
                        cleanupStats.totalCleanupsPerformed = cleanupStats.totalCleanupsPerformed + 1
                        cleanupStats.lastCleanupTime = endTime
                    end
                end
                
                finalGarbageCollection()
            end)
        end)
    end)
end

function CleanupService:PerformMaintenanceCleanup()
    print("🧹 Performing maintenance cleanup...")
    local startTime = tick()
    
    local itemsRemoved = 0
    
    -- Clean up temporary objects
    itemsRemoved = itemsRemoved + self:_cleanupTemporaryObjects()
    
    -- Clean up disconnected parts
    itemsRemoved = itemsRemoved + self:_cleanupDisconnectedParts()
    
    -- Clean up old effects
    itemsRemoved = itemsRemoved + self:_cleanupOldEffects()
    
    -- Optimize memory if needed
    local memoryUsage = collectgarbage("count") * 1024
    if memoryUsage > CLEANUP_CONFIG.memoryThreshold then
        collectgarbage("collect")
        print("🗑️ Performed garbage collection due to memory threshold")
    end
    
    local duration = tick() - startTime
    cleanupStats.partsRemoved = cleanupStats.partsRemoved + itemsRemoved
    
    print(string.format("✅ Maintenance cleanup complete - %d items removed in %.2fs", itemsRemoved, duration))
end

function CleanupService:RemoveOldSpawnPoints()
    local spawnPointsRemoved = 0
    
    for _, item in pairs(Workspace:GetChildren()) do
        if table.find(ITEMS_TO_REMOVE, item.Name) then
            pcall(function()
                item:Destroy()
                spawnPointsRemoved = spawnPointsRemoved + 1
            end)
        end
    end
    
    print(string.format("🗑️ Removed %d old spawn points", spawnPointsRemoved))
    return spawnPointsRemoved
end

function CleanupService:RemoveOldBuildings()
    local buildingsRemoved = 0
    
    for _, item in pairs(Workspace:GetChildren()) do
        if table.find(BUILDINGS_TO_REMOVE, item.Name) then
            pcall(function()
                item:Destroy()
                buildingsRemoved = buildingsRemoved + 1
            end)
        end
    end
    
    print(string.format("🏗️ Removed %d old buildings", buildingsRemoved))
    return buildingsRemoved
end

function CleanupService:OptimizeWorkspacePerformance()
    print("⚡ Optimizing workspace performance...")
    
    local optimizations = 0
    
    -- Optimize lighting
    if game.Lighting then
        game.Lighting.GlobalShadows = false -- Disable for performance
        optimizations = optimizations + 1
    end
    
    -- Optimize rendering for distant objects
    for _, obj in pairs(Workspace:GetDescendants()) do
        if obj:IsA("BasePart") then
            pcall(function()
                if obj.Size.Magnitude < 1 then
                    obj.CanCollide = false -- Small parts don't need collision
                    optimizations = optimizations + 1
                end
            end)
        end
    end
    
    print(string.format("⚡ Applied %d performance optimizations", optimizations))
    return optimizations
end

function CleanupService:CleanupMemoryLeaks()
    print("💾 Cleaning up memory leaks...")
    
    local initialMemory = collectgarbage("count") * 1024
    
    -- Force garbage collection
    for i = 1, CLEANUP_CONFIG.garbageCollectionCycles do
        collectgarbage("collect")
        task.wait(0.1)
    end
    
    local finalMemory = collectgarbage("count") * 1024
    local memoryReclaimed = initialMemory - finalMemory
    
    cleanupStats.memoryReclaimed = cleanupStats.memoryReclaimed + memoryReclaimed
    
    print(string.format("💾 Memory cleanup complete - %.2f MB reclaimed", memoryReclaimed / (1024 * 1024)))
    return memoryReclaimed
end

-- ========================================
-- PLAYER AND SESSION CLEANUP
-- ========================================

function CleanupService:CleanupPlayerData(player)
    print(string.format("🧹 Cleaning up data for player: %s", player.Name))
    
    local cleanupTasks = 0
    
    -- Clean up player-specific objects in workspace
    for _, obj in pairs(Workspace:GetChildren()) do
        if obj:GetAttribute("PlayerId") == player.UserId then
            pcall(function()
                obj:Destroy()
                cleanupTasks = cleanupTasks + 1
            end)
        end
    end
    
    -- Clean up player trails and effects  
    cleanupTasks = cleanupTasks + self:_cleanupPlayerEffects(player)
    
    -- Use dependency injection for optional services
    if self.MainGameService then
        pcall(function()
            self.MainGameService:CleanupPlayerSession(player)
            cleanupTasks = cleanupTasks + 1
        end)
    end
    
    if self.ArchwayService then
        pcall(function()
            self.ArchwayService:CleanupPlayerData(player)
            cleanupTasks = cleanupTasks + 1
        end)
    end
    
    cleanupStats.playersCleanedUp = cleanupStats.playersCleanedUp + 1
    
    print(string.format("✅ Player cleanup complete - %d tasks performed", cleanupTasks))
    return cleanupTasks
end

function CleanupService:CleanupCharacterData(character)
    if not character then return 0 end
    
    print(string.format("👤 Cleaning up character data: %s", character.Name))
    
    local cleanupTasks = 0
    
    -- Clean up character accessories and effects
    for _, obj in pairs(character:GetChildren()) do
        if obj:GetAttribute("IsTemporary") then
            pcall(function()
                obj:Destroy()
                cleanupTasks = cleanupTasks + 1
            end)
        end
    end
    
    -- Clean up character trails
    cleanupTasks = cleanupTasks + self:_cleanupCharacterTrails(character)
    
    print(string.format("✅ Character cleanup complete - %d tasks performed", cleanupTasks))
    return cleanupTasks
end

function CleanupService:CleanupGameSessions()
    print("🎮 Cleaning up active game sessions...")
    
    local sessionsCleanedUp = 0
    
    -- Clean up abandoned game instances
    for _, obj in pairs(Workspace:GetChildren()) do
        if obj:GetAttribute("IsGameSession") and obj:GetAttribute("LastActivity") then
            local lastActivity = obj:GetAttribute("LastActivity")
            if tick() - lastActivity > 600 then -- 10 minutes inactive
                pcall(function()
                    obj:Destroy()
                    sessionsCleanedUp = sessionsCleanedUp + 1
                end)
            end
        end
    end
    
    cleanupStats.sessionsCleanedUp = cleanupStats.sessionsCleanedUp + sessionsCleanedUp
    
    print(string.format("✅ Game session cleanup complete - %d sessions cleaned", sessionsCleanedUp))
    return sessionsCleanedUp
end

-- ========================================
-- PRIVATE HELPER METHODS
-- ========================================

function CleanupService:_cleanupTemporaryObjects()
    local removed = 0
    
    for _, obj in pairs(Workspace:GetDescendants()) do
        if obj:GetAttribute("IsTemporary") or obj.Name:find("Temp") then
            pcall(function()
                obj:Destroy()
                removed = removed + 1
            end)
        end
    end
    
    return removed
end

function CleanupService:_cleanupDisconnectedParts()
    local removed = 0
    
    for _, obj in pairs(Workspace:GetDescendants()) do
        if obj:IsA("BasePart") and not obj.Anchored and not obj.Parent:FindFirstChild("Humanoid") then
            local connections = obj:GetConnections()
            if #connections == 0 then
                pcall(function()
                    obj:Destroy()
                    removed = removed + 1
                end)
            end
        end
    end
    
    return removed
end

function CleanupService:_cleanupOldEffects()
    local removed = 0
    
    for _, obj in pairs(Workspace:GetDescendants()) do
        if obj:IsA("Attachment") or obj:IsA("ParticleEmitter") or obj:IsA("Trail") then
            if obj:GetAttribute("CreatedTime") then
                local age = tick() - obj:GetAttribute("CreatedTime")
                if age > 300 then -- 5 minutes old
                    pcall(function()
                        obj:Destroy()
                        removed = removed + 1
                    end)
                end
            end
        end
    end
    
    return removed
end

function CleanupService:_cleanupPlayerEffects(player)
    local removed = 0
    
    for _, obj in pairs(Workspace:GetDescendants()) do
        if obj:GetAttribute("OwnerId") == player.UserId then
            pcall(function()
                obj:Destroy()
                removed = removed + 1
            end)
        end
    end
    
    return removed
end

function CleanupService:_cleanupCharacterTrails(character)
    local removed = 0
    
    for _, obj in pairs(character:GetDescendants()) do
        if obj:IsA("Trail") or obj:IsA("ParticleEmitter") then
            pcall(function()
                obj:Destroy()
                removed = removed + 1
            end)
        end
    end
    
    return removed
end

function CleanupService:_reportWorkspaceStats()
    local partCount = 0
    local modelCount = 0
    local effectCount = 0
    
    for _, obj in pairs(Workspace:GetDescendants()) do
        if obj:IsA("BasePart") then
            partCount = partCount + 1
        elseif obj:IsA("Model") then
            modelCount = modelCount + 1
        elseif obj:IsA("ParticleEmitter") or obj:IsA("Trail") then
            effectCount = effectCount + 1
        end
    end
    
    print("📊 Workspace Stats:")
    print(string.format("   Parts: %d", partCount))
    print(string.format("   Models: %d", modelCount))
    print(string.format("   Effects: %d", effectCount))
    print(string.format("   Memory usage: %.2f MB", collectgarbage("count") / 1024))
end

function CleanupService:_saveCleanupStats()
    -- Save cleanup statistics (could integrate with DataService)
    if self.AnalyticsService then
        self.AnalyticsService:TrackEvent("CleanupServiceStats", cleanupStats)
    end
end

function CleanupService:_startPeriodicCleanup()
    -- Start periodic cleanup cycle
    local function periodicCleanup()
        self:PerformMaintenanceCleanup()
        task.delay(CLEANUP_CONFIG.cleanupInterval, periodicCleanup)
    end
    
    task.delay(CLEANUP_CONFIG.cleanupInterval, periodicCleanup)
end

function CleanupService:_startMemoryMonitoring()
    -- Monitor memory usage and trigger cleanup when needed
    local function monitorMemory()
        local memoryUsage = collectgarbage("count") * 1024
        
        if memoryUsage > CLEANUP_CONFIG.memoryThreshold then
            print("⚠️ Memory threshold exceeded, performing emergency cleanup")
            self:PerformMaintenanceCleanup()
        end
        
        task.delay(60, monitorMemory) -- Check every minute
    end
    
    task.delay(60, monitorMemory)
end

function CleanupService:_startPerformanceOptimization()
    -- Periodic performance optimization
    local function optimizePerformance()
        local playerCount = #Players:GetPlayers()
        
        -- Adjust optimization frequency based on player count
        local interval = playerCount > 10 and 120 or 300
        
        self:OptimizeWorkspacePerformance()
        
        task.delay(interval, optimizePerformance)
    end
    
    task.delay(300, optimizePerformance)
end

-- ========================================
-- PUBLIC API METHODS
-- ========================================

function CleanupService:GetCleanupStats()
    local runtime = tick() - cleanupStats.startTime
    
    return {
        totalCleanupsPerformed = cleanupStats.totalCleanupsPerformed,
        lastCleanupTime = cleanupStats.lastCleanupTime,
        playersCleanedUp = cleanupStats.playersCleanedUp,
        sessionsCleanedUp = cleanupStats.sessionsCleanedUp,
        memoryReclaimed = cleanupStats.memoryReclaimed,
        partsRemoved = cleanupStats.partsRemoved,
        runtime = runtime,
        averageCleanupTime = runtime / math.max(1, cleanupStats.totalCleanupsPerformed)
    }
end

function CleanupService:ForceCleanup()
    print("🚨 Force cleanup requested")
    self:PerformFullCleanup()
end

function CleanupService:GetMemoryUsage()
    return {
        current = collectgarbage("count") * 1024,
        threshold = CLEANUP_CONFIG.memoryThreshold,
        percentage = (collectgarbage("count") * 1024) / CLEANUP_CONFIG.memoryThreshold * 100
    }
end

return CleanupService
