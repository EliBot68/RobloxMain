-- ServiceReferenceFixScript.server.luau
-- Script to fix broken service references throughout the codebase

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SafeRequire = require(ReplicatedStorage.Shared.utils.SafeRequire)

print("🔧 SERVICE REFERENCE FIX SCRIPT STARTING...")

-- Reference fixes to apply
local referenceFixes = {
    -- PlayerService is in core subdirectory, not parent directory
    {
        pattern = "require%(script%.Parent%.PlayerService%)",
        replacement = "require(script.Parent.core.PlayerService)",
        description = "Fix PlayerService path to core subdirectory"
    },
    {
        pattern = "SafeRequire%.require%(script%.Parent%.PlayerService%)",
        replacement = "SafeRequire.require(script.Parent.core.PlayerService)",
        description = "Fix SafeRequire PlayerService path to core subdirectory"
    },
    
    -- Services that reference non-existent GameService
    {
        pattern = "require%(script%.Parent%.GameService%)",
        replacement = "require(script.Parent.MainGameService)",
        description = "Fix GameService reference to MainGameService"
    },
    
    -- Fix Services require path
    {
        pattern = "require%(script%.Parent%.Parent%.Services%)",
        replacement = "require(script.Parent.Parent.core.Services)",
        description = "Fix Services path to core subdirectory"
    },
    
    -- Economy services trying to require PlayerService from wrong location
    {
        pattern = "require%(script%.Parent%.Parent%.PlayerService%)",
        replacement = "require(script.Parent.Parent.core.PlayerService)",
        description = "Fix economy service PlayerService path"
    }
}

local filesToFix = {
    -- Core services with broken PlayerService references
    "src/server/services/BuffService.luau",
    "src/server/services/ExclusiveService.luau", 
    "src/server/services/LeaderboardService.luau",
    "src/server/services/MiniGameService.luau",
    "src/server/services/PartyService.luau",
    "src/server/services/PetService.luau",
    "src/server/services/PuzzleService.luau",
    "src/server/services/QuestService.luau",
    "src/server/services/SpectatorService.luau",
    "src/server/services/TrophyService.luau",
    "src/server/services/FountainService.luau",
    
    -- Economy services with broken PlayerService references
    "src/server/services/economy/MysteryService.luau",
    "src/server/services/economy/ShopService.luau",
    
    -- Services with other broken references
    "src/server/services/HubService.luau",
    "src/server/services/MovingObstacleService.luau",
    "src/shared/ui/SimpleUISystem.luau",
    "src/server/SystemEventConnections.server.luau"
}

-- Function to check if file exists
local function fileExists(filePath)
    local success, _ = pcall(function()
        local file = io.open(filePath, "r")
        if file then
            file:close()
            return true
        end
        return false
    end)
    return success
end

-- Function to read file content
local function readFile(filePath)
    local file = io.open(filePath, "r")
    if not file then
        return nil
    end
    local content = file:read("*all")
    file:close()
    return content
end

-- Function to write file content
local function writeFile(filePath, content)
    local file = io.open(filePath, "w")
    if not file then
        return false
    end
    file:write(content)
    file:close()
    return true
end

-- Function to apply fixes to content
local function applyFixes(content, filePath)
    local originalContent = content
    local fixesApplied = 0
    
    for _, fix in ipairs(referenceFixes) do
        local before = content
        content = string.gsub(content, fix.pattern, fix.replacement)
        if content ~= before then
            fixesApplied = fixesApplied + 1
            print("  ✅ Applied: " .. fix.description)
        end
    end
    
    return content, fixesApplied, content ~= originalContent
end

-- Main fixing process
local totalFilesProcessed = 0
local totalFilesFixed = 0
local totalFixesApplied = 0

print("\n📁 Processing files...")

for _, relativeFilePath in ipairs(filesToFix) do
    local fullPath = game.ServerScriptService.Parent.Parent .. "\\" .. string.gsub(relativeFilePath, "/", "\\")
    
    print("\n🔍 Checking: " .. relativeFilePath)
    totalFilesProcessed = totalFilesProcessed + 1
    
    if fileExists(fullPath) then
        local content = readFile(fullPath)
        if content then
            local newContent, fixesApplied, wasModified = applyFixes(content, relativeFilePath)
            
            if wasModified then
                if writeFile(fullPath, newContent) then
                    totalFilesFixed = totalFilesFixed + 1
                    totalFixesApplied = totalFixesApplied + fixesApplied
                    print("  💾 File updated with " .. fixesApplied .. " fixes")
                else
                    print("  ❌ Failed to write file")
                end
            else
                print("  ℹ️  No fixes needed")
            end
        else
            print("  ❌ Failed to read file")
        end
    else
        print("  ⚠️  File not found")
    end
end

-- Summary
print("\n" .. string.rep("=", 50))
print("🎯 SERVICE REFERENCE FIX SUMMARY")
print(string.rep("=", 50))
print("📊 Files processed: " .. totalFilesProcessed)
print("🔧 Files fixed: " .. totalFilesFixed)
print("✅ Total fixes applied: " .. totalFixesApplied)

if totalFixesApplied > 0 then
    print("\n🎉 Service reference fixes completed successfully!")
    print("💡 Services should now have correct require paths")
else
    print("\n⚠️  No fixes were applied - references may already be correct")
end

print("\n🔄 Restart required for changes to take effect")

-- Log completion
local timestamp = os.date("%Y-%m-%d %H:%M:%S")
print("⏰ Completed at: " .. timestamp)
