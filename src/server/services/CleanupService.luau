-- CleanupService.luau
-- Enhanced cleanup service with comprehensive memory management
-- Handles cleanup of old spawn points, buildings, performance optimization, and memory leaks

local Workspace = game:GetService("Workspace")
local Players = game:GetService("Players")
local Debris = game:GetService("Debris")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Import memory manager
local MemoryManager = require(ReplicatedStorage.Shared.utilities.MemoryManager)

local CleanupService = {}

-- Memory cleanup tracking
local lastFullCleanup = 0
local cleanupStats = {
    totalCleanupsPerformed = 0,
    lastCleanupTime = 0,
    playersCleanedUp = 0,
    sessionsCleanedUp = 0
}

-- Items to remove for performance optimization
local ITEMS_TO_REMOVE = {
    "OldSpawn",
    "LegacySpawn", 
    "TestSpawn",
    "DefaultSpawn",
    "TempSpawn",
    "DevSpawn",
    "OldBuilding",
    "LegacyBuilding",
    "TestBuilding",
    "TempBuilding",
    "DevBuilding",
    "UnusedBuilding",
    "OldTeleporter",
    "LegacyTeleporter",
    "TestTeleporter",
    "TempTeleporter",
    "DevTeleporter",
    -- Old part names
    "Part1",
    "Part2", 
    "Part3",
    "Part4",
    "Part5",
}

-- Performance optimization settings
local OPTIMIZATION_CONFIG = {
    maxPartsInWorkspace = 5000,
    maxDecalsPerPart = 3,
    maxLightsInWorkspace = 100,
    maxSoundsInWorkspace = 50,
    cleanupInterval = 300, -- 5 minutes
}

function CleanupService:RemoveOldSpawnPoints()
    print("🧹 Cleaning up old spawn points...")
    local removed = 0
    
    -- Remove old spawn locations
    for _, obj in pairs(Workspace:GetDescendants()) do
        if obj:IsA("SpawnLocation") then
            -- Keep only the new hub spawn
            if obj.Name ~= "HubSpawn" then
                print("   Removing old spawn: " .. obj.Name)
                obj:Destroy()
                removed = removed + 1
            end
        end
    end
    
    -- Remove specifically named old items
    for _, itemName in pairs(ITEMS_TO_REMOVE) do
        local item = Workspace:FindFirstChild(itemName)
        if item then
            print("   Removing old item: " .. itemName)
            item:Destroy()
            removed = removed + 1
        end
        
        -- Also check in deeper hierarchy
        for _, obj in pairs(Workspace:GetDescendants()) do
            if obj.Name == itemName then
                print("   Removing nested old item: " .. itemName)
                obj:Destroy()
                removed = removed + 1
            end
        end
    end
    
    print("✅ Removed " .. removed .. " old spawn points and items")
end

function CleanupService:RemoveOldBuildings()
    print("🏗️ Cleaning up old buildings and structures...")
    local removed = 0
    
    -- Look for common old building patterns
    local oldPatterns = {
        "old",
        "legacy", 
        "temp",
        "test",
        "unused",
        "backup",
        "dev",
        "debug"
    }
    
    for _, obj in pairs(Workspace:GetChildren()) do
        if obj:IsA("Model") or obj:IsA("Folder") then
            local objName = obj.Name:lower()
            
            for _, pattern in pairs(oldPatterns) do
                if string.find(objName, pattern) then
                    print("   Removing old structure: " .. obj.Name)
                    obj:Destroy()
                    removed = removed + 1
                    break
                end
            end
        end
    end
    
    print("✅ Removed " .. removed .. " old buildings and structures")
end

function CleanupService:OptimizeWorkspacePerformance()
    print("⚡ Optimizing workspace for performance...")
    local optimized = 0
    
    -- Remove excessive decals
    for _, obj in pairs(Workspace:GetDescendants()) do
        if obj:IsA("Decal") or obj:IsA("Texture") then
            local parent = obj.Parent
            if parent then
                local decalCount = 0
                for _, child in pairs(parent:GetChildren()) do
                    if child:IsA("Decal") or child:IsA("Texture") then
                        decalCount = decalCount + 1
                    end
                end
                
                if decalCount > OPTIMIZATION_CONFIG.maxDecalsPerPart then
                    obj:Destroy()
                    optimized = optimized + 1
                end
            end
        end
    end
    
    -- Optimize lighting (remove excessive lights)
    local lightCount = 0
    for _, obj in pairs(Workspace:GetDescendants()) do
        if obj:IsA("Light") then
            lightCount = lightCount + 1
            if lightCount > OPTIMIZATION_CONFIG.maxLightsInWorkspace then
                obj:Destroy()
                optimized = optimized + 1
            end
        end
    end
    
    -- Remove excessive sound objects
    local soundCount = 0
    for _, obj in pairs(Workspace:GetDescendants()) do
        if obj:IsA("Sound") then
            soundCount = soundCount + 1
            if soundCount > OPTIMIZATION_CONFIG.maxSoundsInWorkspace then
                obj:Destroy()
                optimized = optimized + 1
            end
        end
    end
    
    -- Clean up loose parts with default names
    for _, obj in pairs(Workspace:GetDescendants()) do
        if obj:IsA("BasePart") and obj.Name:match("^Part%d*$") then
            -- Check if it's not part of an important model
            local isImportant = false
            local parent = obj.Parent
            while parent and parent ~= Workspace do
                local parentName = parent.Name:lower()
                if string.find(parentName, "hub") or 
                   string.find(parentName, "shop") or 
                   string.find(parentName, "arena") or
                   string.find(parentName, "important") then
                    isImportant = true
                    break
                end
                parent = parent.Parent
            end
            
            if not isImportant and not obj:GetAttribute("KeepPart") then
                obj:Destroy()
                optimized = optimized + 1
            end
        end
    end
    
    print("✅ Optimized " .. optimized .. " objects for better performance")
end

function CleanupService:CleanupMemoryLeaks()
    print("🧠 Advanced memory leak cleanup using MemoryManager...")
    
    local memoryStats = MemoryManager:GetMemoryStats()
    print("📊 Current memory usage:")
    print("   Active players: " .. memoryStats.totalPlayers)
    print("   Total connections: " .. memoryStats.totalConnections)
    print("   Total tweens: " .. memoryStats.totalTweens)
    print("   Total tasks: " .. memoryStats.totalTasks)
    print("   Total game objects: " .. memoryStats.totalGameObjects)
    
    local cleaned = 0
    
    -- Clean up disconnected player data using MemoryManager
    local currentPlayerIds = {}
    for _, player in pairs(Players:GetPlayers()) do
        currentPlayerIds[tostring(player.UserId)] = true
    end
    
    -- Find and cleanup data for players who have left
    for playerId, _ in pairs(memoryStats.playerDetails) do
        if not currentPlayerIds[playerId] then
            print("🧹 Cleaning up data for disconnected player: " .. playerId)
            local stats = MemoryManager:CleanupPlayer(playerId)
            cleaned = cleaned + stats.connections + stats.tweens + stats.tasks + stats.gameObjects
            cleanupStats.playersCleanedUp = cleanupStats.playersCleanedUp + 1
        end
    end
    
    -- Event-driven garbage collection for non-blocking cleanup
    local gcCount = 0
    local maxGcCycles = 5
    
    local function performGarbageCollection()
        if gcCount < maxGcCycles then
            collectgarbage("collect")
            gcCount = gcCount + 1
            task.delay(0.2, performGarbageCollection) -- Optimized non-blocking interval
        end
    end
    
    performGarbageCollection() -- Start garbage collection cycle
    
    -- Clean up any orphaned GUI elements
    for _, player in pairs(Players:GetPlayers()) do
        if player.PlayerGui then
            for _, gui in pairs(player.PlayerGui:GetChildren()) do
                if gui:GetAttribute("TempGui") or gui.Name:match("Temp") then
                    gui:Destroy()
                    cleaned = cleaned + 1
                end
            end
        end
    end
    
    -- Clean up workspace debris
    for _, obj in pairs(Workspace:GetDescendants()) do
        if obj:GetAttribute("TempObject") or obj.Name:match("TempEffect") then
            obj:Destroy()
            cleaned = cleaned + 1
        end
    end
    
    cleanupStats.totalCleanupsPerformed = cleanupStats.totalCleanupsPerformed + 1
    cleanupStats.lastCleanupTime = tick()
    
    print("✅ Advanced memory cleanup complete - cleaned " .. cleaned .. " items")
end

function CleanupService:PerformFullCleanup()
    print("🚀 Starting full workspace cleanup and optimization...")
    
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
                    if gcCycles < 5 then
                        collectgarbage("collect")
                        gcCycles = gcCycles + 1
                        task.delay(0.15, finalGarbageCollection) -- Optimized interval
                    else
                        print("✅ Full cleanup and optimization complete!")
                        
                        -- Report final workspace stats
                        local partCount = 0
                        for _, obj in pairs(Workspace:GetDescendants()) do
                            if obj:IsA("BasePart") then
                                partCount = partCount + 1
                            end
                        end
                        
                        print("📊 Workspace Stats:")
                        print("   Parts in workspace: " .. partCount)
                        print("   Memory usage optimized for better performance")
                    end
                end
                
                finalGarbageCollection()
            end)
        end)
    end)
end

function CleanupService:StartPeriodicCleanup()
    -- Event-driven cleanup with adaptive intervals
    local cleanupEvent = Instance.new("BindableEvent")
    
    local function scheduleNextCleanup()
        local interval = OPTIMIZATION_CONFIG.cleanupInterval
        -- Adaptive scheduling based on memory usage
        local memoryUsage = collectgarbage("count")
        if memoryUsage > 200000 then -- High memory usage
            interval = interval * 0.5 -- More frequent cleanup
        elseif memoryUsage < 50000 then -- Low memory usage
            interval = interval * 2 -- Less frequent cleanup
        end
        
        task.spawn(function()
            task.wait(interval)
            cleanupEvent:Fire()
        end)
    end
    
    cleanupEvent.Event:Connect(function()
        -- Perform regular cleanup
        self:CleanupMemoryLeaks()
        
        -- Perform full cleanup every 10 cycles (50 minutes by default)
        if tick() - lastFullCleanup > (OPTIMIZATION_CONFIG.cleanupInterval * 10) then
            self:PerformFullCleanup()
            lastFullCleanup = tick()
        end
        
        -- Schedule next cleanup
        scheduleNextCleanup()
    end)
    
    -- Start the first cleanup cycle
    scheduleNextCleanup()
    
    print("⏰ Enhanced periodic cleanup started (every " .. OPTIMIZATION_CONFIG.cleanupInterval .. " seconds)")
end

-- New function to clean up active game sessions
function CleanupService:CleanupGameSessions()
    print("🎮 Cleaning up inactive game sessions...")
    
    local cleaned = 0
    local currentTime = tick()
    
    -- ASSUMPTION: Access to global game services for session cleanup
    if _G.GetGameService then
        local gameService = _G.GetGameService()
        if gameService and gameService.CleanupInactiveSessions then
            cleaned = gameService:CleanupInactiveSessions()
        end
    end
    
    -- Clean up multiplayer sessions
    if _G.GetArchwayService then
        local archwayService = _G.GetArchwayService()
        if archwayService and archwayService.CleanupInactiveMultiplayerSessions then
            local multiplayerCleaned = archwayService:CleanupInactiveMultiplayerSessions()
            cleaned = cleaned + multiplayerCleaned
        end
    end
    
    cleanupStats.sessionsCleanedUp = cleanupStats.sessionsCleanedUp + cleaned
    print("✅ Cleaned up " .. cleaned .. " inactive game sessions")
    
    return cleaned
end

-- New function to clean up player-specific data
function CleanupService:CleanupPlayerData(player)
    if not player then return false end
    
    local playerId = tostring(player.UserId)
    print("🧹 Comprehensive cleanup for player: " .. player.Name)
    
    -- Use MemoryManager for thorough cleanup
    local stats = MemoryManager:CleanupPlayer(playerId)
    
    -- Clean up player-specific workspace objects
    for _, obj in pairs(Workspace:GetDescendants()) do
        if obj:GetAttribute("PlayerId") == playerId or 
           obj.Name:match(player.Name) then
            obj:Destroy()
        end
    end
    
    print("✅ Player cleanup complete for " .. player.Name .. " - freed " .. 
          (stats.connections + stats.tweens + stats.tasks + stats.gameObjects) .. " resources")
    
    return true
end

-- Get cleanup statistics
function CleanupService:GetCleanupStats()
    local stats = cleanupStats
    stats.memoryManagerStats = MemoryManager:GetMemoryStats()
    stats.timeSinceLastCleanup = tick() - cleanupStats.lastCleanupTime
    return stats
end

function CleanupService:Init()
    print("🧹 Enhanced CleanupService with MemoryManager initialized")
    
    -- Initialize MemoryManager
    MemoryManager:Init()
    
    -- Start enhanced periodic cleanup
    self:StartPeriodicCleanup()
    
    -- Register player cleanup on leave
    Players.PlayerRemoving:Connect(function(player)
        self:CleanupPlayerData(player)
    end)
    
    -- Initial cleanup on service start (NO POLLING)
    task.delay(5, function() -- Non-blocking service initialization
        self:PerformFullCleanup()
    end)
    
    return true
end

return CleanupService
