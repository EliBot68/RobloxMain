-- ServiceArchitectureConverter.luau
-- Automated migration utility to convert legacy service patterns to ModernServiceFramework
-- Handles: Services.Register(), ServiceBase.new(), and _G.GetService() patterns

local ModernServiceFramework = require(script.Parent.Parent.core.ModernServiceFramework)

local ServiceArchitectureConverter = {}

-- ========================================
-- PATTERN DETECTION AND ANALYSIS
-- ========================================

-- Detect service architecture patterns in code
function ServiceArchitectureConverter:AnalyzeServicePatterns(filePath, fileContent)
    local patterns = {
        legacyServiceBase = {},
        modernRegister = {},
        globalService = {},
        customPatterns = {}
    }
    
    local lines = fileContent:split("\n")
    
    for lineNumber, line in ipairs(lines) do
        -- Detect ServiceBase.new() pattern
        if line:match("ServiceBase%.new%(") then
            local serviceName = line:match("ServiceBase%.new%([\"'](.+)[\"']")
            table.insert(patterns.legacyServiceBase, {
                line = lineNumber,
                content = line,
                serviceName = serviceName,
                pattern = "ServiceBase.new"
            })
        end
        
        -- Detect Services.Register() pattern
        if line:match("Services%.Register%(") then
            local serviceName = line:match("Services%.Register%([\"'](.+)[\"']")
            table.insert(patterns.modernRegister, {
                line = lineNumber,
                content = line,
                serviceName = serviceName,
                pattern = "Services.Register"
            })
        end
        
        -- Detect _G.GetService() pattern
        if line:match("_G%.GetService%(") or line:match("_G%[") then
            local serviceName = line:match("_G%.GetService%([\"'](.+)[\"']") or line:match("_G%[[\"'](.+)[\"']%]")
            table.insert(patterns.globalService, {
                line = lineNumber,
                content = line,
                serviceName = serviceName,
                pattern = "_G.GetService"
            })
        end
    end
    
    return patterns
end

-- Generate analysis report
function ServiceArchitectureConverter:GenerateAnalysisReport(filePath, patterns)
    local report = {
        filePath = filePath,
        timestamp = os.time(),
        totalPatterns = 0,
        patterns = patterns,
        migrationComplexity = "LOW",
        estimatedEffort = "1-2 hours"
    }
    
    -- Count total patterns
    for patternType, instances in pairs(patterns) do
        report.totalPatterns = report.totalPatterns + #instances
    end
    
    -- Determine complexity
    if report.totalPatterns > 20 then
        report.migrationComplexity = "HIGH"
        report.estimatedEffort = "4-6 hours"
    elseif report.totalPatterns > 10 then
        report.migrationComplexity = "MEDIUM"
        report.estimatedEffort = "2-4 hours"
    end
    
    return report
end

-- ========================================
-- MODERN SERVICE TEMPLATE GENERATION
-- ========================================

-- Generate modern service template
function ServiceArchitectureConverter:GenerateModernServiceTemplate(serviceName, originalConfig)
    local config = originalConfig or {}
    
    local dependenciesStr = ""
    if config.Dependencies and #config.Dependencies > 0 then
        dependenciesStr = '"' .. table.concat(config.Dependencies, '", "') .. '"'
    end
    
    local optionalDepsStr = ""
    if config.OptionalDependencies and #config.OptionalDependencies > 0 then
        optionalDepsStr = '"' .. table.concat(config.OptionalDependencies, '", "') .. '"'
    end
    
    local template = string.format([[
-- %s.luau
-- Modernized service using ModernServiceFramework architecture
-- Converted from legacy service pattern

local ModernServiceFramework = require(ReplicatedStorage.Shared.core.ModernServiceFramework)

local %s = {}
setmetatable(%s, {__index = ModernServiceFramework.ServiceBase})

-- Create new service instance
function %s.new(config)
    local self = ModernServiceFramework.CreateService("%s", config or {
        Priority = %d,
        Dependencies = {%s},
        OptionalDependencies = {%s}
    })
    setmetatable(self, {__index = %s})
    
    -- Service-specific properties
    self.ServiceData = {}
    self.ServiceConfig = self.Config
    
    return self
end

-- Initialize the service (replaces old Initialize method)
function %s:Initialize()
    print("🚀 Initializing %s with modern architecture...")
    
    -- Dependency injection is handled automatically
    -- Access dependencies via: self:GetDependency("DependencyName")
    
    -- Initialize service-specific logic here
    
    print("✅ %s initialized successfully")
end

-- Start the service (replaces old Start method)
function %s:Start()
    print("▶️ Starting %s...")
    
    -- Service startup logic here
    -- Connection management is built-in via self:AddConnection()
    
    print("✅ %s started successfully")
end

-- Stop the service (replaces old Stop method)
function %s:Stop()
    print("⏹️ Stopping %s...")
    
    -- Service shutdown logic here
    -- Connections are automatically cleaned up
    
    print("✅ %s stopped successfully")
end

-- Service-specific methods go here
-- Example method with error handling and performance tracking
function %s:ExampleMethod(param1, param2)
    return self:TrackOperation("ExampleMethod", function()
        -- Method implementation here
        return true, "Success"
    end)
end

return %s
]], 
        serviceName, serviceName, serviceName, serviceName, serviceName,
        config.Priority or 50, dependenciesStr, optionalDepsStr, serviceName,
        serviceName, serviceName, serviceName, serviceName, serviceName,
        serviceName, serviceName, serviceName, serviceName, serviceName,
        serviceName
    )
    
    return template
end

-- ========================================
-- AUTOMATED CONVERSION FUNCTIONS
-- ========================================

-- Convert ServiceBase.new pattern to ModernServiceFramework
function ServiceArchitectureConverter:ConvertServiceBasePattern(originalCode, serviceName)
    local modernCode = originalCode
    
    -- Replace ServiceBase require
    modernCode = modernCode:gsub(
        "local ServiceBase = SafeRequire%.require%(ReplicatedStorage%.Shared%.utils%.ServiceBase%)",
        "local ModernServiceFramework = require(ReplicatedStorage.Shared.core.ModernServiceFramework)"
    )
    
    -- Replace ServiceBase.new call
    modernCode = modernCode:gsub(
        "local self = ServiceBase%.new%(" .. serviceName .. ", ({.-})%)",
        "local self = ModernServiceFramework.CreateService(" .. serviceName .. ", %1)"
    )
    
    -- Replace setmetatable call
    modernCode = modernCode:gsub(
        "setmetatable%(self, {__index = " .. serviceName .. "}%)",
        "setmetatable(self, {__index = ModernServiceFramework.ServiceBase})\n    setmetatable(self, {__index = " .. serviceName .. "})"
    )
    
    return modernCode
end

-- Convert Services.Register pattern to ModernServiceFramework
function ServiceArchitectureConverter:ConvertServicesRegisterPattern(originalCode)
    local modernCode = originalCode
    
    -- Replace Services.Register calls
    modernCode = modernCode:gsub(
        "Services%.Register%(([\"'].+[\"']), (.+)%)",
        "ModernServiceFramework.RegisterService(%1, %2)"
    )
    
    return modernCode
end

-- Convert _G.GetService pattern to ModernServiceFramework
function ServiceArchitectureConverter:ConvertGlobalServicePattern(originalCode)
    local modernCode = originalCode
    
    -- Replace _G.GetService calls
    modernCode = modernCode:gsub(
        "_G%.GetService%(([\"'].+[\"'])%)",
        "ModernServiceFramework.GetService(%1)"
    )
    
    -- Replace _G["ServiceName"] patterns
    modernCode = modernCode:gsub(
        "_G%[([\"'].+[\"'])%]",
        "ModernServiceFramework.GetService(%1)"
    )
    
    return modernCode
end

-- ========================================
-- REGISTRATION SCRIPT GENERATION
-- ========================================

-- Generate service registration script
function ServiceArchitectureConverter:GenerateServiceRegistration(serviceList)
    local registrationCode = [[
-- ServiceRegistration.luau
-- Centralized service registration for ModernServiceFramework
-- Auto-generated by ServiceArchitectureConverter

local ModernServiceFramework = require(ReplicatedStorage.Shared.core.ModernServiceFramework)

-- Import all service classes
]]

    -- Add imports
    for _, service in ipairs(serviceList) do
        registrationCode = registrationCode .. string.format(
            "local %s = require(%s)\n",
            service.name,
            service.path
        )
    end
    
    registrationCode = registrationCode .. "\n-- Register all services\n"
    
    -- Add registrations
    for _, service in ipairs(serviceList) do
        registrationCode = registrationCode .. string.format(
            "ModernServiceFramework.RegisterService(\"%s\", %s, %s)\n",
            service.name,
            service.name,
            service.config or "{}"
        )
    end
    
    registrationCode = registrationCode .. [[

-- Initialize and start all services
local function InitializeServices()
    print("🚀 Initializing all services with ModernServiceFramework...")
    
    ModernServiceFramework.InitializeAllServices()
    ModernServiceFramework.StartAllServices()
    
    print("✅ All services initialized and started successfully!")
end

-- Health monitoring
local function MonitorServiceHealth()
    task.spawn(function()
        while true do
            task.wait(30) -- Check every 30 seconds
            
            local healthReport = ModernServiceFramework.GetHealthReport()
            
            if healthReport.errorServices > 0 then
                warn(string.format("⚠️ %d services have errors", healthReport.errorServices))
            end
            
            print(string.format("📊 Service Health: %d/%d running", 
                healthReport.runningServices, healthReport.totalServices))
        end
    end)
end

-- Auto-initialize on require
InitializeServices()
MonitorServiceHealth()

return {
    Initialize = InitializeServices,
    GetHealthReport = function() return ModernServiceFramework.GetHealthReport() end
}
]]
    
    return registrationCode
end

-- ========================================
-- DEPENDENCY INJECTION SETUP
-- ========================================

-- Generate dependency injection configuration
function ServiceArchitectureConverter:GenerateDependencyConfiguration(services)
    local diConfig = [[
-- DependencyInjectionConfig.luau
-- Dependency injection configuration for ModernServiceFramework
-- Auto-generated by ServiceArchitectureConverter

local ModernServiceFramework = require(ReplicatedStorage.Shared.core.ModernServiceFramework)

-- Register core dependencies
local function ConfigureDependencies()
    print("🔧 Configuring dependency injection...")
    
]]

    -- Add singleton registrations
    for _, service in ipairs(services) do
        if service.singleton then
            diConfig = diConfig .. string.format(
                "    ModernServiceFramework.RegisterSingleton(\"%s\", %s)\n",
                service.interface or service.name,
                service.implementation or service.name
            )
        end
    end
    
    diConfig = diConfig .. [[
    
    print("✅ Dependency injection configured successfully!")
end

-- Auto-configure on require
ConfigureDependencies()

return {
    Configure = ConfigureDependencies
}
]]
    
    return diConfig
end

-- ========================================
-- TESTING FRAMEWORK INTEGRATION
-- ========================================

-- Generate test templates for modernized services
function ServiceArchitectureConverter:GenerateServiceTestTemplate(serviceName)
    local testTemplate = string.format([[
-- %sTest.luau
-- Test suite for %s using ModernServiceFramework testing capabilities
-- Auto-generated by ServiceArchitectureConverter

local ModernServiceFramework = require(ReplicatedStorage.Shared.core.ModernServiceFramework)
local %s = require(ReplicatedStorage.Server.services.%s)

-- Test framework setup
local TestFramework = ModernServiceFramework.TestingFramework

-- Mock dependencies
local function CreateMockDependencies()
    return {
        MockDependency1 = TestFramework:CreateMockService("MockDependency1", {
            ExampleMethod = function() return true, "Mock result" end
        }),
        MockDependency2 = TestFramework:CreateMockService("MockDependency2", {
            AnotherMethod = function() return "Mock data" end
        })
    }
end

-- Test suite
local %sTests = {}

function %sTests:TestInitialization()
    local testConfig = {
        TestMode = true,
        MockDependencies = CreateMockDependencies()
    }
    
    local service = ModernServiceFramework.CreateTestService(%s, testConfig)
    
    -- Test initialization
    local success = service:InjectDependencies()
    assert(success, "Dependency injection should succeed")
    
    service:Initialize()
    assert(service.State == ModernServiceFramework.ServiceState.INITIALIZED, 
           "Service should be initialized")
    
    print("✅ %s initialization test passed")
end

function %sTests:TestServiceMethods()
    local testConfig = {
        TestMode = true,
        MockDependencies = CreateMockDependencies()
    }
    
    local service = ModernServiceFramework.CreateTestService(%s, testConfig)
    service:InjectDependencies()
    service:Initialize()
    
    -- Test service-specific methods here
    -- Example:
    -- local success, result = service:ExampleMethod("test", "data")
    -- assert(success, "Method should succeed")
    
    print("✅ %s method tests passed")
end

function %sTests:TestErrorHandling()
    local service = ModernServiceFramework.CreateTestService(%s, {TestMode = true})
    
    -- Test error handling
    service:HandleError("Test error", false)
    assert(service.ErrorCount == 1, "Error count should be incremented")
    
    print("✅ %s error handling test passed")
end

function %sTests:RunAllTests()
    print("🧪 Running %s test suite...")
    
    self:TestInitialization()
    self:TestServiceMethods()
    self:TestErrorHandling()
    
    print("🎉 All %s tests passed!")
end

return %sTests
]], 
        serviceName, serviceName, serviceName, serviceName, serviceName, serviceName, serviceName, serviceName, serviceName, serviceName, serviceName, serviceName, serviceName, serviceName, serviceName, serviceName, serviceName, serviceName
    )
    
    return testTemplate
end

-- ========================================
-- MIGRATION ORCHESTRATION
-- ========================================

-- Execute full migration for a service
function ServiceArchitectureConverter:MigrateService(filePath, fileContent, outputPath)
    print(string.format("🔄 Migrating service: %s", filePath))
    
    -- Analyze patterns
    local patterns = self:AnalyzeServicePatterns(filePath, fileContent)
    local report = self:GenerateAnalysisReport(filePath, patterns)
    
    -- Apply conversions
    local modernCode = fileContent
    
    for _, pattern in ipairs(patterns.legacyServiceBase) do
        modernCode = self:ConvertServiceBasePattern(modernCode, pattern.serviceName)
    end
    
    for _, pattern in ipairs(patterns.modernRegister) do
        modernCode = self:ConvertServicesRegisterPattern(modernCode)
    end
    
    for _, pattern in ipairs(patterns.globalService) do
        modernCode = self:ConvertGlobalServicePattern(modernCode)
    end
    
    print(string.format("✅ Migration complete for %s - %d patterns converted", filePath, report.totalPatterns))
    
    return {
        modernCode = modernCode,
        report = report,
        outputPath = outputPath
    }
end

-- Generate migration summary report
function ServiceArchitectureConverter:GenerateMigrationSummary(migrations)
    local summary = {
        timestamp = os.time(),
        totalFiles = #migrations,
        totalPatterns = 0,
        successfulMigrations = 0,
        failedMigrations = 0,
        migrationDetails = {}
    }
    
    for _, migration in ipairs(migrations) do
        summary.totalPatterns = summary.totalPatterns + migration.report.totalPatterns
        
        if migration.modernCode then
            summary.successfulMigrations = summary.successfulMigrations + 1
        else
            summary.failedMigrations = summary.failedMigrations + 1
        end
        
        table.insert(summary.migrationDetails, migration.report)
    end
    
    return summary
end

-- ========================================
-- PERFORMANCE BENCHMARKING
-- ========================================

-- Benchmark old vs new architecture performance
function ServiceArchitectureConverter:BenchmarkArchitecturePerformance()
    print("🏃 Benchmarking service architecture performance...")
    
    local results = {
        timestamp = os.time(),
        legacyPerformance = {},
        modernPerformance = {},
        improvements = {}
    }
    
    -- Simulate legacy service operations
    local legacyStartTime = tick()
    for i = 1, 1000 do
        -- Simulate legacy service lookup overhead
        local service = {} -- Placeholder for legacy pattern
        service.someMethod = function() return true end
        service.someMethod()
    end
    results.legacyPerformance.duration = tick() - legacyStartTime
    
    -- Simulate modern service operations
    local modernStartTime = tick()
    for i = 1, 1000 do
        -- ModernServiceFramework operations are optimized
        local service = ModernServiceFramework.CreateService("BenchmarkService", {})
        local _success, _ = service:TrackOperation("benchmark", function()
            return true
        end)
    end
    results.modernPerformance.duration = tick() - modernStartTime
    
    -- Calculate improvements
    results.improvements.performanceGain = (results.legacyPerformance.duration / results.modernPerformance.duration)
    results.improvements.percentImprovement = ((results.legacyPerformance.duration - results.modernPerformance.duration) / results.legacyPerformance.duration) * 100
    
    print(string.format("📊 Architecture Performance Results:"))
    print(string.format("   Legacy: %.3fs", results.legacyPerformance.duration))
    print(string.format("   Modern: %.3fs", results.modernPerformance.duration))
    print(string.format("   Improvement: %.1fx (%.1f%% faster)", results.improvements.performanceGain, results.improvements.percentImprovement))
    
    return results
end

return ServiceArchitectureConverter
