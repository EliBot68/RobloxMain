-- RunCriticalTests.luau
-- Simple script to execute all critical system unit tests
-- Place this in ServerScriptService or run from command bar

local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Import the test runner
local SafeRequire = require(ReplicatedStorage.Shared.utils.SafeRequire)
local CriticalSystemsTestRunner = SafeRequire.require(ReplicatedStorage.src.server.test.CriticalSystemsTestRunner)

-- Function to run all critical tests
local function runCriticalTests()
    print("🚀 Starting Critical Systems Unit Tests...")
    print("=" .. string.rep("=", 50))
    
    local results = CriticalSystemsTestRunner.runAllTests()
    
    print("\n" .. string.rep("=", 50))
    print("🏁 Critical Systems Testing Complete!")
    
    return results
end

-- Function to run quick health check
local function runHealthCheck()
    print("🏥 Running Critical Systems Health Check...")
    
    local health = CriticalSystemsTestRunner.healthCheck()
    
    print("\n💊 Health Check Complete!")
    return health
end

-- Main execution
print("Critical Systems Test Suite Available!")
print("Commands:")
print("  runCriticalTests() - Run full test suite")
print("  runHealthCheck() - Quick system health check")
print("")

-- Uncomment the line below to auto-run tests on script execution
-- runCriticalTests()

-- Export functions for manual execution
_G.runCriticalTests = runCriticalTests
_G.runHealthCheck = runHealthCheck

return {
    runCriticalTests = runCriticalTests,
    runHealthCheck = runHealthCheck,
    CriticalSystemsTestRunner = CriticalSystemsTestRunner
}
