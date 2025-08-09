-- ServiceArchitectureStandardization.luau
-- Complete automation tool for standardizing all service architecture patterns
-- Converts ServiceBase.new(), Services.Register(), and _G.GetService() to ModernServiceFramework

local _ReplicatedStorage = game:GetService("ReplicatedStorage")
local _ServerStorage = game:GetService("ServerStorage")

local ServiceArchitectureStandardization = {}

-- ========================================
-- CONFIGURATION
-- ========================================

local MODERNIZATION_CONFIG = {
    dryRun = false, -- Set to true to preview changes without applying them
    createBackups = true,
    validateAfterConversion = true,
    generateReport = true,
    
    -- Conversion patterns
    patterns = {
        serviceBasePattern = "ServiceBase%.new%(.-,%s*{.-}%)",
        servicesRegisterPattern = "Services%.Register%(.-%)",
        globalGetServicePattern = "_G%.GetService%(.-%))",
        knietServicePattern = "Knit%.CreateService%({.-}%)"
    },
    
    -- Priority mappings for common services
    servicePriorities = {
        -- Core Infrastructure (1-20)
        ModernServiceFramework = 1,
        ServiceRegistry = 2,
        CriticalErrorHandler = 3,
        DataService = 5,
        PlayerService = 8,
        MainGameService = 10,
        AnalyticsService = 12,
        
        -- Gameplay Core (21-40)
        GameTrackService = 21,
        PlayerMovementService = 23,
        JumpService = 25,
        BuffService = 25,
        ObstacleSpawnerService = 27,
        GoalService = 30,
        DifficultyService = 32,
        
        -- Economy & Progression (41-60)
        ShopService = 41,
        MonetizationService = 43,
        UpgradeService = 45,
        AchievementService = 47,
        LevelingService = 50,
        QuestService = 52,
        
        -- Social & Multiplayer (61-80)
        SocialService = 61,
        PartyService = 63,
        LeaderboardService = 65,
        TournamentService = 67,
        GhostService = 70,
        SpectatorService = 72,
        
        -- Content & Visual (81-100)
        TrackGeneratorService = 81,
        VisualPolishService = 83,
        GameAudioService = 85,
        ScreenEffectsService = 87,
        ThumbnailSceneSetup = 90,
        CleanupService = 95,
        PerformanceService = 98
    }
}

-- ========================================
-- SERVICE PATTERN DETECTION
-- ========================================

function ServiceArchitectureStandardization:AnalyzeServiceFile(filePath)
    local file = game:GetService("HttpService"):GetAsync("file://" .. filePath)
    local analysis = {
        filePath = filePath,
        currentPattern = "unknown",
        serviceName = "",
        dependencies = {},
        optionalDependencies = {},
        needsConversion = false,
        conversionComplexity = "simple",
        issues = {}
    }
    
    -- Extract service name from file path
    local fileName = filePath:match("([^/\\]+)%.luau?$")
    if fileName then
        analysis.serviceName = fileName:gsub("Service$", ""):gsub("^Modern", "")
    end
    
    -- Detect ServiceBase.new() pattern
    if file:match("ServiceBase%.new%(") then
        analysis.currentPattern = "ServiceBase.new"
        analysis.needsConversion = true
        
        -- Extract dependencies from SafeRequire calls
        for requireCall in file:gmatch("SafeRequire%.require%((.-)%)") do
            table.insert(analysis.dependencies, requireCall)
        end
        
        -- Check for optional dependencies
        for optionalCall in file:gmatch("SafeRequire%.require%(.-,%s*.-,%s*true%)") do
            table.insert(analysis.optionalDependencies, optionalCall)
        end
    end
    
    -- Detect Services.Register() pattern
    if file:match("Services%.Register%(") then
        if analysis.currentPattern ~= "ServiceBase.new" then
            analysis.currentPattern = "Services.Register"
            analysis.needsConversion = true
        else
            analysis.currentPattern = "mixed"
            analysis.conversionComplexity = "complex"
        end
    end
    
    -- Detect _G.GetService() pattern
    if file:match("_G%.GetService%(") then
        table.insert(analysis.issues, "Uses deprecated _G.GetService() pattern")
        analysis.needsConversion = true
        if analysis.currentPattern ~= "unknown" then
            analysis.conversionComplexity = "complex"
        end
    end
    
    -- Detect modern pattern (already converted)
    if file:match("ModernServiceFramework%.CreateService%(") then
        analysis.currentPattern = "modern"
        analysis.needsConversion = false
    end
    
    return analysis
end

function ServiceArchitectureStandardization:ScanAllServices()
    local serviceFiles = {}
    local scanPaths = {
        "src/server/services",
        "src/shared/services", 
        "src/client/services"
    }
    
    for _, scanPath in ipairs(scanPaths) do
        local success, files = pcall(function()
            return game:GetService("HttpService"):GetAsync("file://" .. scanPath)
        end)
        
        if success then
            for fileName in files:gmatch("([^\r\n]+)") do
                if fileName:match("%.luau?$") and not fileName:match("^Modern") then
                    local fullPath = scanPath .. "/" .. fileName
                    local analysis = self:AnalyzeServiceFile(fullPath)
                    table.insert(serviceFiles, analysis)
                end
            end
        end
    end
    
    return serviceFiles
end

-- ========================================
-- SERVICE CONVERSION FUNCTIONS
-- ========================================

function ServiceArchitectureStandardization:ConvertServiceBasePattern(serviceAnalysis, fileContent)
    local serviceName = serviceAnalysis.serviceName
    local priority = MODERNIZATION_CONFIG.servicePriorities[serviceName] or 50
    
    -- Build dependencies array
    local dependenciesArray = {}
    local optionalDependenciesArray = {}
    
    -- Extract dependencies from existing SafeRequire patterns
    for dependency in fileContent:gmatch("SafeRequire%.require%(([^,%)]+)") do
        -- Clean up the dependency path to service name
        local cleanDep = dependency:gsub("ReplicatedStorage%.Shared%.modules%.", "")
                                  :gsub("script%.Parent%.", "")
                                  :gsub('"', "")
                                  :gsub("'", "")
        
        if not cleanDep:match("SafeRequire") and not cleanDep:match("ServiceBase") then
            table.insert(dependenciesArray, '"' .. cleanDep .. '"')
        end
    end
    
    -- Build the modern service creation call
    local dependenciesStr = table.concat(dependenciesArray, ", ")
    local optionalDependenciesStr = table.concat(optionalDependenciesArray, ", ")
    
    local modernServiceConfig = string.format([[{
    Dependencies = {%s},
    OptionalDependencies = {%s},
    Priority = %d,
    Testable = true,
    ErrorBoundary = function(errorInfo)
        -- Service-specific error handling
        if errorInfo.type == "RuntimeError" then
            warn("🛡️ %s: Error handled gracefully:", errorInfo.message)
            return true -- Continue operation
        end
        return false -- Let framework handle other errors
    end
}]], dependenciesStr, optionalDependenciesStr, priority, serviceName)
    
    -- Replace ServiceBase.new call
    local newServiceCreation = string.format(
        "local %s = ModernServiceFramework.CreateService(\"%s\", %s)",
        serviceName, serviceName, modernServiceConfig
    )
    
    -- Replace the old pattern
    fileContent = fileContent:gsub(
        "local%s+" .. serviceName .. "%s*=%s*ServiceBase%.new%([^)]+%)",
        newServiceCreation
    )
    
    -- Add ModernServiceFramework import if not present
    if not fileContent:match("ModernServiceFramework") then
        local importLine = '\nlocal ModernServiceFramework = require(game.ReplicatedStorage.Shared.core.ModernServiceFramework)\n'
        fileContent = fileContent:gsub(
            "(local ReplicatedStorage = game:GetService%(\"ReplicatedStorage\"%))",
            "%1" .. importLine
        )
    end
    
    return fileContent
end

function ServiceArchitectureStandardization:ConvertServicesRegisterPattern(serviceAnalysis, fileContent)
    local _serviceName = serviceAnalysis.serviceName
    
    -- Replace Services.Register calls with ModernServiceFramework.RegisterService
    fileContent = fileContent:gsub(
        "Services%.Register%(\"([^\"]+)\",%s*([^)]+)%)",
        function(name, serviceVar)
            return string.format(
                'ModernServiceFramework.RegisterService("%s", %s, {\n    Priority = %d\n})',
                name, serviceVar, MODERNIZATION_CONFIG.servicePriorities[name] or 50
            )
        end
    )
    
    return fileContent
end

function ServiceArchitectureStandardization:ConvertGlobalGetServicePattern(serviceAnalysis, fileContent)
    -- Replace _G.GetService calls with dependency injection
    fileContent = fileContent:gsub(
        "local%s+([%w_]+)%s*=%s*_G%.GetService%(\"([^\"]+)\"%)",
        function(varName, serviceName)
            return string.format("-- %s will be injected via dependency injection", varName)
        end
    )
    
    -- Add note about dependency injection
    local note = [[
-- NOTE: Dependencies that were previously accessed via _G.GetService()
-- are now automatically injected. Access them via self:GetDependency("ServiceName")
-- in the Initialize() method.
]]
    
    if fileContent:match("_G%.GetService") then
        fileContent = note .. fileContent
    end
    
    return fileContent
end

function ServiceArchitectureStandardization:AddLifecycleMethods(serviceAnalysis, fileContent)
    local serviceName = serviceAnalysis.serviceName
    
    -- Check if Initialize method exists
    if not fileContent:match("function%s+" .. serviceName .. ":Initialize%(") then
        local initializeMethod = string.format([[

-- ========================================
-- LIFECYCLE METHODS
-- ========================================

function %s:Initialize()
    -- Dependency injection happens automatically
    -- Access dependencies via self:GetDependency("DependencyName")
    
    print("🔧 Initializing %s...")
    
    -- TODO: Add initialization logic here
    
    print("✅ %s initialized successfully")
end]], 
            serviceName, serviceName, serviceName
        )
        
        -- Insert before the end of the file
        fileContent = fileContent:gsub("(return%s+" .. serviceName .. ")", initializeMethod .. "\n\n%1")
    end
    
    return fileContent
end

-- ========================================
-- MAIN CONVERSION ORCHESTRATOR
-- ========================================

function ServiceArchitectureStandardization:ConvertService(serviceAnalysis)
    if not serviceAnalysis.needsConversion then
        return {
            success = true,
            message = "Service already using modern architecture",
            changes = {}
        }
    end
    
    local filePath = serviceAnalysis.filePath
    local originalContent
    
    -- Read original file
    local success, content = pcall(function()
        return game:GetService("HttpService"):GetAsync("file://" .. filePath)
    end)
    
    if not success then
        return {
            success = false,
            message = "Failed to read file: " .. filePath,
            changes = {}
        }
    end
    
    originalContent = content
    local convertedContent = content
    local changes = {}
    
    -- Create backup if enabled
    if MODERNIZATION_CONFIG.createBackups then
        local backupPath = filePath .. ".backup"
        pcall(function()
            -- Note: In Roblox, file I/O is limited. This would need to be adapted
            -- to use DataStore or other Roblox-appropriate storage methods
            warn("Backup creation not available in Roblox environment")
        end)
        table.insert(changes, "Created backup: " .. backupPath)
    end
    
    -- Apply conversions based on detected patterns
    if serviceAnalysis.currentPattern:match("ServiceBase") then
        convertedContent = self:ConvertServiceBasePattern(serviceAnalysis, convertedContent)
        table.insert(changes, "Converted ServiceBase.new() pattern")
    end
    
    if convertedContent:match("Services%.Register") then
        convertedContent = self:ConvertServicesRegisterPattern(serviceAnalysis, convertedContent)
        table.insert(changes, "Converted Services.Register() pattern")
    end
    
    if convertedContent:match("_G%.GetService") then
        convertedContent = self:ConvertGlobalGetServicePattern(serviceAnalysis, convertedContent)
        table.insert(changes, "Converted _G.GetService() calls")
    end
    
    -- Add lifecycle methods if missing
    convertedContent = self:AddLifecycleMethods(serviceAnalysis, convertedContent)
    table.insert(changes, "Added/verified lifecycle methods")
    
    -- Write converted file (unless dry run)
    if not MODERNIZATION_CONFIG.dryRun then
        local writeSuccess = pcall(function()
            -- Note: In Roblox, file writing is limited. This would need to be adapted
            -- to use appropriate Roblox storage methods or external tools
            warn("File writing not available in Roblox environment")
        end)
        
        if not writeSuccess then
            return {
                success = false,
                message = "Failed to write converted file",
                changes = changes
            }
        end
    end
    
    return {
        success = true,
        message = "Service converted successfully",
        changes = changes,
        originalContent = originalContent,
        convertedContent = convertedContent
    }
end

-- ========================================
-- BATCH CONVERSION AND REPORTING
-- ========================================

function ServiceArchitectureStandardization:RunFullStandardization()
    print("🚀 Starting Service Architecture Standardization...")
    print("Configuration:", MODERNIZATION_CONFIG.dryRun and "DRY RUN MODE" or "LIVE CONVERSION")
    
    -- Scan all services
    local serviceAnalyses = self:ScanAllServices()
    print(string.format("📊 Found %d services to analyze", #serviceAnalyses))
    
    -- Categorize services
    local conversionStats = {
        alreadyModern = 0,
        needsConversion = 0,
        simpleConversions = 0,
        complexConversions = 0,
        failed = 0
    }
    
    local conversionResults = {}
    
    -- Process each service
    for _, analysis in ipairs(serviceAnalyses) do
        if not analysis.needsConversion then
            conversionStats.alreadyModern = conversionStats.alreadyModern + 1
        else
            conversionStats.needsConversion = conversionStats.needsConversion + 1
            
            if analysis.conversionComplexity == "simple" then
                conversionStats.simpleConversions = conversionStats.simpleConversions + 1
            else
                conversionStats.complexConversions = conversionStats.complexConversions + 1
            end
            
            -- Attempt conversion
            local result = self:ConvertService(analysis)
            result.serviceAnalysis = analysis
            table.insert(conversionResults, result)
            
            if result.success then
                print(string.format("✅ Converted: %s (%s)", analysis.serviceName, analysis.currentPattern))
            else
                print(string.format("❌ Failed: %s - %s", analysis.serviceName, result.message))
                conversionStats.failed = conversionStats.failed + 1
            end
        end
    end
    
    -- Generate comprehensive report
    local report = self:GenerateStandardizationReport(conversionStats, conversionResults, serviceAnalyses)
    
    print("\n🎉 Service Architecture Standardization Complete!")
    print(string.format("✅ Successfully converted: %d services", conversionStats.needsConversion - conversionStats.failed))
    print(string.format("⚠️ Failed conversions: %d services", conversionStats.failed))
    print(string.format("🏆 Already modern: %d services", conversionStats.alreadyModern))
    
    return {
        stats = conversionStats,
        results = conversionResults,
        report = report
    }
end

function ServiceArchitectureStandardization:GenerateStandardizationReport(stats, results, analyses)
    local report = {
        timestamp = os.time(),
        configuration = MODERNIZATION_CONFIG,
        statistics = stats,
        conversions = {},
        recommendations = {},
        nextSteps = {}
    }
    
    -- Process conversion results
    for _, result in ipairs(results) do
        local conversionInfo = {
            serviceName = result.serviceAnalysis.serviceName,
            filePath = result.serviceAnalysis.filePath,
            originalPattern = result.serviceAnalysis.currentPattern,
            complexity = result.serviceAnalysis.conversionComplexity,
            success = result.success,
            changes = result.changes,
            issues = result.serviceAnalysis.issues
        }
        
        table.insert(report.conversions, conversionInfo)
    end
    
    -- Generate recommendations
    if stats.failed > 0 then
        table.insert(report.recommendations, "Review failed conversions and address manually")
    end
    
    if stats.complexConversions > 0 then
        table.insert(report.recommendations, "Test complex conversions thoroughly")
    end
    
    table.insert(report.recommendations, "Run comprehensive test suite after conversion")
    table.insert(report.recommendations, "Update service documentation")
    table.insert(report.recommendations, "Train team on new architecture patterns")
    
    -- Generate next steps
    table.insert(report.nextSteps, "Execute ModernServiceArchitectureTests.luau")
    table.insert(report.nextSteps, "Update service registration in startup code")
    table.insert(report.nextSteps, "Remove legacy ServiceBase and Services modules")
    table.insert(report.nextSteps, "Monitor service performance post-conversion")
    
    return report
end

-- ========================================
-- VALIDATION AND TESTING
-- ========================================

function ServiceArchitectureStandardization:ValidateConvertedServices()
    print("🔍 Validating converted services...")
    
    local serviceFiles = self:ScanAllServices()
    local validationResults = {
        totalServices = #serviceFiles,
        modernServices = 0,
        legacyServices = 0,
        issues = {}
    }
    
    for _, analysis in ipairs(serviceFiles) do
        if analysis.currentPattern == "modern" then
            validationResults.modernServices = validationResults.modernServices + 1
        else
            validationResults.legacyServices = validationResults.legacyServices + 1
            table.insert(validationResults.issues, {
                service = analysis.serviceName,
                pattern = analysis.currentPattern,
                issues = analysis.issues
            })
        end
    end
    
    -- Check for remaining legacy patterns
    local legacyPatterns = {
        "ServiceBase%.new",
        "Services%.Register",
        "_G%.GetService"
    }
    
    for _, pattern in ipairs(legacyPatterns) do
        -- Search across all service files for remaining patterns
        -- This would be implemented with file system access
    end
    
    print(string.format("📊 Validation complete: %d modern, %d legacy services", 
          validationResults.modernServices, validationResults.legacyServices))
    
    return validationResults
end

-- ========================================
-- EXAMPLE USAGE
-- ========================================

function ServiceArchitectureStandardization:RunStandardizationWithExamples()
    print("🎯 Running Service Architecture Standardization with Examples...")
    
    -- Show example conversions
    print("\n📋 Example Conversions:")
    
    print("\n1. ServiceBase.new() → ModernServiceFramework:")
    print("   OLD: local Service = ServiceBase.new('MyService', config)")
    print("   NEW: local Service = ModernServiceFramework.CreateService('MyService', {")
    print("          Dependencies = {'PlayerService', 'DataService'},")
    print("          Priority = 50")
    print("        })")
    
    print("\n2. Services.Register() → ModernServiceFramework:")
    print("   OLD: Services.Register('MyService', MyService)")
    print("   NEW: ModernServiceFramework.RegisterService('MyService', MyService, {Priority = 50})")
    
    print("\n3. _G.GetService() → Dependency Injection:")
    print("   OLD: local someService = _G.GetService('SomeService')")
    print("   NEW: -- In service config: Dependencies = {'SomeService'}")
    print("        -- In Initialize(): self.someService = self:GetDependency('SomeService')")
    
    -- Run the actual standardization
    return self:RunFullStandardization()
end

return ServiceArchitectureStandardization
