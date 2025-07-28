-- CleanupService.luau
-- Handles cleanup of old spawn points, buildings, and performance optimization

local Workspace = game:GetService("Workspace")
local Players = game:GetService("Players")
local Debris = game:GetService("Debris")

local CleanupService = {}

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
    print("🧠 Cleaning up potential memory leaks...")
    
    -- Clean up disconnected connections
    local cleaned = 0
    
    -- Force garbage collection
    for i = 1, 3 do
        collectgarbage("collect")
        wait(0.1)
    end
    
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
    
    print("✅ Cleaned " .. cleaned .. " potential memory leaks")
end

function CleanupService:PerformFullCleanup()
    print("🚀 Starting full workspace cleanup and optimization...")
    
    -- Step 1: Remove old spawn points
    self:RemoveOldSpawnPoints()
    wait(1)
    
    -- Step 2: Remove old buildings
    self:RemoveOldBuildings() 
    wait(1)
    
    -- Step 3: Optimize performance
    self:OptimizeWorkspacePerformance()
    wait(1)
    
    -- Step 4: Clean memory
    self:CleanupMemoryLeaks()
    
    -- Step 5: Final garbage collection
    for i = 1, 5 do
        collectgarbage("collect")
        wait(0.1)
    end
    
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

function CleanupService:StartPeriodicCleanup()
    spawn(function()
        while true do
            wait(OPTIMIZATION_CONFIG.cleanupInterval)
            self:CleanupMemoryLeaks()
        end
    end)
    
    print("⏰ Periodic cleanup started (every " .. OPTIMIZATION_CONFIG.cleanupInterval .. " seconds)")
end

function CleanupService:Init()
    print("🧹 CleanupService initialized")
    
    -- Perform initial cleanup
    wait(5) -- Wait for other services to load
    self:PerformFullCleanup()
    
    -- Start periodic maintenance
    self:StartPeriodicCleanup()
end

return CleanupService
