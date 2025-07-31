-- ConnectionMigrationHelper.luau
-- Helper script to identify and migrate legacy connection patterns
-- Run this to scan your codebase for potential memory leaks

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local _ConnectionManager = require(ReplicatedStorage.Shared.core.ConnectionManager)

local MigrationHelper = {}

-- Common patterns that indicate unmanaged connections
local LEGACY_PATTERNS = {
    "%.PlayerAdded:Connect%(",
    "%.PlayerRemoving:Connect%(",
    "%.CharacterAdded:Connect%(",
    "%.Heartbeat:Connect%(",
    "%.Touched:Connect%(",
    "%.MouseButton1Click:Connect%(",
    "%.OnServerEvent:Connect%(",
    "%.OnClientEvent:Connect%(",
    "%.Died:Connect%(",
    "%.Changed:Connect%("
}

-- Track problematic connection patterns
local connectionIssues = {}

function MigrationHelper:ScanForLegacyConnections(scriptContent, scriptName)
    local issues = {}
    
    for lineNumber, line in ipairs(scriptContent:split("\n")) do
        for _, pattern in ipairs(LEGACY_PATTERNS) do
            if line:match(pattern) then
                -- Check if it's already using ConnectionManager
                if not line:match("ConnectionManager") and not line:match("helper:") then
                    table.insert(issues, {
                        line = lineNumber,
                        content = line:match("^%s*(.-)%s*$"), -- Trim whitespace
                        pattern = pattern,
                        severity = "HIGH"
                    })
                end
            end
        end
    end
    
    if #issues > 0 then
        connectionIssues[scriptName] = issues
    end
    
    return issues
end

function MigrationHelper:GenerateMigrationSuggestions(scriptName, issues)
    local suggestions = {}
    
    table.insert(suggestions, "-- Migration suggestions for " .. scriptName)
    table.insert(suggestions, "-- Add at the top of your script:")
    table.insert(suggestions, "local ServiceConnectionHelper = require(ReplicatedStorage.Shared.utils.ServiceConnectionHelper)")
    table.insert(suggestions, "local helper = ServiceConnectionHelper.CreateServiceHelper(\"" .. scriptName .. "\")")
    table.insert(suggestions, "")
    
    for _, issue in ipairs(issues) do
        local originalLine = issue.content
        local suggestion = MigrationHelper:ConvertToManagedConnection(originalLine)
        
        table.insert(suggestions, "-- Line " .. issue.line .. " (LEGACY):")
        table.insert(suggestions, "-- " .. originalLine)
        table.insert(suggestions, "-- REPLACE WITH:")
        table.insert(suggestions, suggestion)
        table.insert(suggestions, "")
    end
    
    table.insert(suggestions, "-- Add cleanup method:")
    table.insert(suggestions, "function " .. scriptName .. ":Cleanup()")
    table.insert(suggestions, "    helper:CleanupAll()")
    table.insert(suggestions, "end")
    
    return table.concat(suggestions, "\n")
end

function MigrationHelper:ConvertToManagedConnection(line)
    -- Convert common patterns to managed connections
    
    if line:match("Players%.PlayerAdded:Connect") then
        return "helper:ConnectPlayerEvent(\"PlayerAdded\", function(player)\n    -- Your callback here\nend)"
    elseif line:match("Players%.PlayerRemoving:Connect") then
        return "helper:ConnectPlayerEvent(\"PlayerRemoving\", function(player)\n    -- Your callback here\nend)"
    elseif line:match("%.CharacterAdded:Connect") then
        return "helper:ConnectPlayerCharacterEvent(player, \"CharacterAdded\", function(character)\n    -- Your callback here\nend)"
    elseif line:match("RunService%.Heartbeat:Connect") then
        return "helper:ConnectRunServiceEvent(\"Heartbeat\", function(deltaTime)\n    -- Your callback here\nend)"
    elseif line:match("%.Touched:Connect") then
        return "helper:ConnectTouchEvent(part, function(hit, player, character)\n    -- Your callback here\nend, 0.1) -- debounce time"
    elseif line:match("%.MouseButton1Click:Connect") then
        return "helper:ConnectGUIEvent(button, \"MouseButton1Click\", function()\n    -- Your callback here\nend)"
    elseif line:match("%.OnServerEvent:Connect") or line:match("%.OnClientEvent:Connect") then
        return "helper:ConnectRemoteEvent(remoteEvent, function(player, ...)\n    -- Your callback here\nend)"
    else
        return "helper:TrackConnection(originalConnection, {\n    description = \"Description here\",\n    connectionType = ConnectionManager.ConnectionTypes.OTHER\n})"
    end
end

function MigrationHelper:PrintMigrationReport()
    print("🔍 Connection Migration Report")
    print("=============================")
    
    local totalScripts = 0
    local totalIssues = 0
    
    for scriptName, issues in pairs(connectionIssues) do
        totalScripts = totalScripts + 1
        totalIssues = totalIssues + #issues
        
        print("📄 " .. scriptName .. " (" .. #issues .. " issues)")
        for _, issue in ipairs(issues) do
            print("  ⚠️ Line " .. issue.line .. ": " .. issue.content)
        end
    end
    
    print("\n📊 Summary:")
    print("  Scripts with issues: " .. totalScripts)
    print("  Total connection issues: " .. totalIssues)
    print("  Memory leak risk: " .. (totalIssues > 0 and "HIGH" or "LOW"))
    
    if totalIssues > 0 then
        print("\n💡 Next Steps:")
        print("  1. Review each flagged connection")
        print("  2. Replace with managed connections using ServiceConnectionHelper")
        print("  3. Add cleanup methods to all services")
        print("  4. Test thoroughly in a development environment")
    end
end

function MigrationHelper:CreateQuickFixScript(scriptName)
    local issues = connectionIssues[scriptName]
    if not issues then
        print("No issues found for script: " .. scriptName)
        return
    end
    
    local quickFix = MigrationHelper:GenerateMigrationSuggestions(scriptName, issues)
    print("🔧 Quick Fix for " .. scriptName .. ":")
    print("=====================================")
    print(quickFix)
end

-- Example usage:
function MigrationHelper:RunExample()
    -- Example legacy script content
    local exampleScript = [[
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

Players.PlayerAdded:Connect(function(player)
    print("Player joined")
end)

RunService.Heartbeat:Connect(function()
    -- Game loop
end)

local button = script.Parent
button.MouseButton1Click:Connect(function()
    print("Button clicked")
end)
]]
    
    print("🔍 Scanning example script...")
    local issues = self:ScanForLegacyConnections(exampleScript, "ExampleScript")
    
    if #issues > 0 then
        print("Found " .. #issues .. " issues!")
        self:CreateQuickFixScript("ExampleScript")
    else
        print("✅ No issues found!")
    end
end

return MigrationHelper
