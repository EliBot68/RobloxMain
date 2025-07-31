-- ConnectionMigrationTool.luau
-- Automated migration tool for converting services to use ConnectionManager
-- Analyzes code patterns and generates migration recommendations

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ConnectionManager = require(ReplicatedStorage.Shared.utilities.ConnectionManager)

local ConnectionMigrationTool = {}

-- ========================================
-- PATTERN DETECTION
-- ========================================

-- Common connection patterns to detect
local CONNECTION_PATTERNS = {
    -- Player events
    {
        pattern = "Players%.PlayerAdded:Connect%(([^)]+)%)",
        replacement = "ConnectionUtils.SetupPlayerManagement(self, %1, nil)",
        description = "Player added event"
    },
    {
        pattern = "Players%.PlayerRemoving:Connect%(([^)]+)%)",
        replacement = "ConnectionUtils.SetupPlayerManagement(self, nil, %1)",
        description = "Player removing event"
    },
    
    -- Character events
    {
        pattern = "player%.CharacterAdded:Connect%(([^)]+)%)",
        replacement = "ConnectionUtils.SetupCharacterManagement(self, player, %1, nil)",
        description = "Character added event"
    },
    
    -- Heartbeat events
    {
        pattern = "RunService%.Heartbeat:Connect%(([^)]+)%)",
        replacement = "ConnectionUtils.SetupHeartbeat(self, %1, 0)",
        description = "Heartbeat connection"
    },
    
    -- Touch events
    {
        pattern = "([%w_]+)%.Touched:Connect%(([^)]+)%)",
        replacement = "ConnectionUtils.SetupTouchEvents(self, {%1}, %2)",
        description = "Touch event"
    },
    
    -- Remote events
    {
        pattern = "RemoteEvents%.([%w_]+)%.OnServerEvent:Connect%(([^)]+)%)",
        replacement = "ConnectionUtils.SetupRemoteEvents(self, {%1 = %2})",
        description = "Remote event connection"
    },
    
    -- Tween completed
    {
        pattern = "([%w_]+)%.Completed:Connect%(([^)]+)%)",
        replacement = "ConnectionManager:ConnectTweenCompleted(%1, %2, self.Name)",
        description = "Tween completed event"
    },
    
    -- Mouse click
    {
        pattern = "([%w_]+)%.MouseClick:Connect%(([^)]+)%)",
        replacement = "ConnectionUtils.Connect(%1.MouseClick, %2, self.Name, '%1_MouseClick', 'MouseClick')",
        description = "Mouse click event"
    }
}

-- Analyze service code for connection patterns
function ConnectionMigrationTool:AnalyzeService(serviceCode, serviceName)
    local analysis = {
        serviceName = serviceName,
        totalPatterns = 0,
        detectedPatterns = {},
        migrationNeeded = false,
        estimatedComplexity = "Low",
        recommendations = {}
    }
    
    -- Detect patterns
    for _, patternInfo in ipairs(CONNECTION_PATTERNS) do
        local matches = {}
        for match in serviceCode:gmatch(patternInfo.pattern) do
            table.insert(matches, match)
            analysis.totalPatterns = analysis.totalPatterns + 1
        end
        
        if #matches > 0 then
            analysis.migrationNeeded = true
            table.insert(analysis.detectedPatterns, {
                description = patternInfo.description,
                pattern = patternInfo.pattern,
                replacement = patternInfo.replacement,
                matches = matches,
                count = #matches
            })
        end
    end
    
    -- Check for manual disconnect calls
    local disconnectCount = 0
    for _ in serviceCode:gmatch(":Disconnect%(%s*%)") do
        disconnectCount = disconnectCount + 1
    end
    
    -- Estimate complexity
    if analysis.totalPatterns > 20 or disconnectCount > 10 then
        analysis.estimatedComplexity = "High"
    elseif analysis.totalPatterns > 10 or disconnectCount > 5 then
        analysis.estimatedComplexity = "Medium"
    end
    
    -- Generate recommendations
    analysis.recommendations = self:GenerateRecommendations(analysis)
    
    return analysis
end

-- Generate migration recommendations based on analysis
function ConnectionMigrationTool:GenerateRecommendations(analysis)
    local recommendations = {}
    
    if not analysis.migrationNeeded then
        table.insert(recommendations, "✅ No connection patterns detected - service may not need migration")
        return recommendations
    end
    
    -- Add connection manager import
    table.insert(recommendations, "1. Add ConnectionManager import:")
    table.insert(recommendations, "   local ConnectionUtils = require(ReplicatedStorage.Shared.utilities.ConnectionUtils)")
    
    -- Wrap service
    table.insert(recommendations, "2. Wrap service with connection management:")
    table.insert(recommendations, "   ConnectionUtils.WrapService(self, '" .. analysis.serviceName .. "')")
    
    -- Pattern-specific recommendations
    for _, pattern in ipairs(analysis.detectedPatterns) do
        table.insert(recommendations, string.format("3. Replace %s patterns (%d found):", 
            pattern.description, pattern.count))
        table.insert(recommendations, "   FROM: " .. pattern.pattern)
        table.insert(recommendations, "   TO:   " .. pattern.replacement)
    end
    
    -- Add cleanup method
    table.insert(recommendations, "4. Add cleanup method to service:")
    table.insert(recommendations, "   function " .. analysis.serviceName .. ":Cleanup()")
    table.insert(recommendations, "       return self:CleanupConnections()")
    table.insert(recommendations, "   end")
    
    -- Complexity warnings
    if analysis.estimatedComplexity == "High" then
        table.insert(recommendations, "⚠️  HIGH COMPLEXITY: Consider manual review and testing")
    elseif analysis.estimatedComplexity == "Medium" then
        table.insert(recommendations, "⚠️  MEDIUM COMPLEXITY: Test thoroughly after migration")
    end
    
    return recommendations
end

-- ========================================
-- AUTOMATED MIGRATION
-- ========================================

-- Generate migrated service code
function ConnectionMigrationTool:GenerateMigratedCode(originalCode, serviceName)
    local migratedCode = originalCode
    local changes = {}
    
    -- Add ConnectionUtils import if not present
    if not migratedCode:match("ConnectionUtils") then
        local importLine = "local ConnectionUtils = require(ReplicatedStorage.Shared.utilities.ConnectionUtils)\n"
        
        -- Find where to insert import (after other requires)
        local lastRequire = migratedCode:match(".*local%s+%w+%s*=%s*require%(.*\n")
        if lastRequire then
            migratedCode = migratedCode:gsub("(local%s+%w+%s*=%s*require%([^)]+%).-\n)", "%1" .. importLine)
        else
            -- Insert at beginning
            migratedCode = importLine .. migratedCode
        end
        
        table.insert(changes, "Added ConnectionUtils import")
    end
    
    -- Replace connection patterns
    for _, patternInfo in ipairs(CONNECTION_PATTERNS) do
        local newCode = migratedCode:gsub(patternInfo.pattern, patternInfo.replacement)
        if newCode ~= migratedCode then
            table.insert(changes, "Replaced " .. patternInfo.description .. " patterns")
            migratedCode = newCode
        end
    end
    
    -- Add service wrapping in Initialize method
    if migratedCode:match("function%s+[%w_]+:Initialize%(%)") then
        local wrapLine = "\n    -- Wrap service with connection management\n    ConnectionUtils.WrapService(self, '" .. serviceName .. "')\n"
        migratedCode = migratedCode:gsub("(function%s+[%w_]+:Initialize%(%%).-\n)", "%1" .. wrapLine)
        table.insert(changes, "Added service wrapping to Initialize method")
    end
    
    -- Add cleanup method if not present
    if not migratedCode:match("function%s+[%w_]+:Cleanup%(%)") then
        local cleanupMethod = [[

-- Cleanup all connections
function ]] .. serviceName .. [[:Cleanup()
    if self.CleanupConnections then
        return self:CleanupConnections()
    end
    return 0
end]]
        
        migratedCode = migratedCode .. cleanupMethod
        table.insert(changes, "Added Cleanup method")
    end
    
    return migratedCode, changes
end

-- ========================================
-- BATCH MIGRATION
-- ========================================

-- Migrate multiple services at once
function ConnectionMigrationTool:BatchMigrate(servicePaths)
    local results = {}
    
    for _, path in ipairs(servicePaths) do
        local serviceName = path:match("([%w_]+)%.luau$") or "UnknownService"
        
        -- Read original code (simulated - would read from file system)
        local originalCode = "-- Service code would be read here"
        
        -- Analyze service
        local analysis = self:AnalyzeService(originalCode, serviceName)
        
        -- Generate migration if needed
        local migration = {
            serviceName = serviceName,
            path = path,
            analysis = analysis,
            migrated = false,
            error = nil
        }
        
        if analysis.migrationNeeded then
            local success, result = pcall(function()
                return self:GenerateMigratedCode(originalCode, serviceName)
            end)
            
            if success then
                migration.migratedCode = result
                migration.migrated = true
            else
                migration.error = result
            end
        end
        
        table.insert(results, migration)
    end
    
    return results
end

-- ========================================
-- VALIDATION AND TESTING
-- ========================================

-- Validate that a migrated service works correctly
function ConnectionMigrationTool:ValidateMigration(serviceName, testCases)
    local validation = {
        serviceName = serviceName,
        passed = 0,
        failed = 0,
        errors = {},
        warnings = {}
    }
    
    -- Check service registration
    local registry = ConnectionManager:GetConnectionRegistry(serviceName)
    if registry then
        validation.passed = validation.passed + 1
    else
        table.insert(validation.errors, "Service not registered with ConnectionManager")
        validation.failed = validation.failed + 1
    end
    
    -- Run test cases if provided
    if testCases then
        for testName, testFunction in pairs(testCases) do
            local success, result = pcall(testFunction)
            if success then
                validation.passed = validation.passed + 1
            else
                table.insert(validation.errors, testName .. ": " .. tostring(result))
                validation.failed = validation.failed + 1
            end
        end
    end
    
    -- Check for common issues
    local connectionStats = ConnectionManager:GetConnectionStats()
    if connectionStats.totalPlayerConnections + connectionStats.totalServiceConnections == 0 then
        table.insert(validation.warnings, "No active connections detected - service may not be running")
    end
    
    validation.success = validation.failed == 0
    return validation
end

-- ========================================
-- REPORTING
-- ========================================

-- Generate comprehensive migration report
function ConnectionMigrationTool:GenerateReport(migrationResults)
    local report = {
        timestamp = os.date("%Y-%m-%d %H:%M:%S"),
        totalServices = #migrationResults,
        migratedServices = 0,
        skippedServices = 0,
        failedServices = 0,
        details = {}
    }
    
    for _, result in ipairs(migrationResults) do
        if result.migrated then
            report.migratedServices = report.migratedServices + 1
        elseif result.analysis.migrationNeeded then
            report.failedServices = report.failedServices + 1
        else
            report.skippedServices = report.skippedServices + 1
        end
        
        table.insert(report.details, {
            service = result.serviceName,
            status = result.migrated and "MIGRATED" or (result.analysis.migrationNeeded and "FAILED" or "SKIPPED"),
            patterns = result.analysis.totalPatterns,
            complexity = result.analysis.estimatedComplexity,
            error = result.error
        })
    end
    
    return report
end

-- Print migration report
function ConnectionMigrationTool:PrintReport(report)
    print("📋 CONNECTION MIGRATION REPORT")
    print("==============================")
    print("Generated: " .. report.timestamp)
    print(string.format("Total Services: %d", report.totalServices))
    print(string.format("  Migrated: %d", report.migratedServices))
    print(string.format("  Skipped: %d", report.skippedServices))
    print(string.format("  Failed: %d", report.failedServices))
    
    print("\n📊 SERVICE DETAILS:")
    for _, detail in ipairs(report.details) do
        local statusIcon = detail.status == "MIGRATED" and "✅" or 
                          detail.status == "FAILED" and "❌" or "⏭️"
        
        print(string.format("%s %s - %s (%d patterns, %s complexity)", 
            statusIcon, detail.service, detail.status, detail.patterns, detail.complexity))
        
        if detail.error then
            print("    Error: " .. detail.error)
        end
    end
end

-- ========================================
-- INTERACTIVE MIGRATION
-- ========================================

-- Interactive migration workflow
function ConnectionMigrationTool:InteractiveMigration(serviceName, serviceCode)
    print("🔧 Interactive Migration for " .. serviceName)
    print("=========================================")
    
    -- Analyze service
    local analysis = self:AnalyzeService(serviceCode, serviceName)
    
    -- Show analysis results
    print("📊 Analysis Results:")
    print("  Patterns found: " .. analysis.totalPatterns)
    print("  Migration needed: " .. (analysis.migrationNeeded and "YES" or "NO"))
    print("  Complexity: " .. analysis.estimatedComplexity)
    
    if not analysis.migrationNeeded then
        print("✅ No migration needed!")
        return
    end
    
    -- Show detected patterns
    print("\n🔍 Detected Patterns:")
    for i, pattern in ipairs(analysis.detectedPatterns) do
        print(string.format("  %d. %s (%d instances)", i, pattern.description, pattern.count))
    end
    
    -- Show recommendations
    print("\n💡 Recommendations:")
    for i, recommendation in ipairs(analysis.recommendations) do
        print("  " .. recommendation)
    end
    
    -- Generate migrated code
    local migratedCode, changes = self:GenerateMigratedCode(serviceCode, serviceName)
    
    print("\n✏️ Changes Made:")
    for i, change in ipairs(changes) do
        print("  " .. i .. ". " .. change)
    end
    
    return {
        analysis = analysis,
        migratedCode = migratedCode,
        changes = changes
    }
end

return ConnectionMigrationTool
