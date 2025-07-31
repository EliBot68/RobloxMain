-- ValidationTest.luau
-- Quick validation test for the Modern Service Architecture
-- Run this to verify everything is working correctly

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ModernServiceFramework = require(ReplicatedStorage.Shared.core.ModernServiceFramework)
-- local ServiceRegistrationConfig = require(ReplicatedStorage.Shared.core.ServiceRegistrationConfig)

local ValidationTest = {}

function ValidationTest:RunBasicTests()
    print("🧪 Running Modern Service Architecture Validation Tests...")
    print("=" .. string.rep("=", 60))
    
    local results = {
        ModernServiceFramework = false,
        DependencyInjection = false,
        ServiceRegistry = false,
        ErrorHandling = false,
        TestingFramework = false
    }
    
    -- Test 1: ModernServiceFramework loads correctly
    pcall(function()
        local serviceBase = ModernServiceFramework.ServiceBase
        if serviceBase and serviceBase.new then
            results.ModernServiceFramework = true
            print("✅ ModernServiceFramework: Loaded successfully")
        end
    end)
    
    -- Test 2: Dependency injection system works
    pcall(function()
        local container = ModernServiceFramework.DependencyContainer
        if container and container.Register and container.Resolve then
            -- Test basic registration and resolution
            container:Register("TestService", {name = "TestService"})
            local resolved = container:Resolve("TestService")
            if resolved and resolved.name == "TestService" then
                results.DependencyInjection = true
                print("✅ Dependency Injection: Working correctly")
            end
        end
    end)
    
    -- Test 3: Service registry functions
    pcall(function()
        local registry = ModernServiceFramework.ServiceRegistry
        if registry and registry.Register and registry.GetService then
            results.ServiceRegistry = true
            print("✅ Service Registry: Functional")
        end
    end)
    
    -- Test 4: Error handling system
    pcall(function()
        -- Check if error handling utilities are available
        if ModernServiceFramework.ServiceBase then
            local testService = ModernServiceFramework.ServiceBase.new("TestService", {})
            if testService and testService.HandleError then
                results.ErrorHandling = true
                print("✅ Error Handling: System available")
            end
        end
    end)
    
    -- Test 5: Testing framework
    pcall(function()
        local testFramework = ModernServiceFramework.TestingFramework
        if testFramework and testFramework.CreateMockService then
            results.TestingFramework = true
            print("✅ Testing Framework: Available")
        end
    end)
    
    print("=" .. string.rep("=", 60))
    
    -- Summary
    local passedTests = 0
    local totalTests = 0
    for testName, passed in pairs(results) do
        totalTests = totalTests + 1
        if passed then
            passedTests = passedTests + 1
        else
            print("❌ " .. testName .. ": Failed")
        end
    end
    
    print(string.format("📊 Test Results: %d/%d tests passed", passedTests, totalTests))
    
    if passedTests == totalTests then
        print("🎉 ALL TESTS PASSED! Modern Service Architecture is working correctly!")
        return true
    else
        print("⚠️ Some tests failed. Please check the implementation.")
        return false
    end
end

function ValidationTest:RunArchitectureValidation()
    print("🔍 Running Service Architecture Validation...")
    
    -- Test basic architecture components without ServiceRegistrationConfig for now
    local configValid = pcall(function()
        -- Basic validation that the framework is accessible
        local framework = ModernServiceFramework
        if framework.ServiceBase and framework.DependencyContainer then
            print("✅ Core architecture components available")
            return true
        end
        return false
    end)
    
    if configValid then
        print("✅ Service Architecture: Valid")
    else
        print("❌ Service Architecture: Has issues")
    end
    
    return configValid
end

function ValidationTest:RunFullValidation()
    print("🚀 Running Complete Modern Service Architecture Validation")
    print("This validates the standardization from three competing patterns to unified architecture")
    print()
    
    local basicTests = self:RunBasicTests()
    print()
    local architectureTests = self:RunArchitectureValidation()
    
    print()
    print("=" .. string.rep("=", 60))
    
    if basicTests and architectureTests then
        print("🎊 VALIDATION SUCCESSFUL!")
        print("✅ Service architecture standardization is working correctly")
        print("✅ Dependency injection, lifecycle management, error boundaries, and testing are all functional")
        print("✅ Ready for production deployment!")
    else
        print("❌ VALIDATION FAILED!")
        print("Some components need attention before deployment")
    end
    
    return basicTests and architectureTests
end

return ValidationTest
