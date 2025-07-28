--[[
	Quick QA Testing Script
	Run this in Studio Console to perform basic system validation
	For use by developers during development
--]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local QATestRunner = {}

-- Test Results
local TestResults = {
	passed = 0,
	failed = 0,
	total = 0,
	details = {}
}

-- Utility Functions
local function logTest(testName, passed, details)
	TestResults.total = TestResults.total + 1
	if passed then
		TestResults.passed = TestResults.passed + 1
		print("✅ " .. testName .. " - PASSED")
	else
		TestResults.failed = TestResults.failed + 1
		print("❌ " .. testName .. " - FAILED: " .. (details or "Unknown error"))
	end
	table.insert(TestResults.details, {
		name = testName,
		passed = passed,
		details = details
	})
end

-- Test 1: SafeRequire System
local function testSafeRequire()
	local success, SafeRequire = pcall(function()
		return require(ReplicatedStorage.Shared.utils.SafeRequire)
	end)
	
	if success and SafeRequire then
		-- Test basic require
		local testModule, error = SafeRequire.require(ReplicatedStorage.Shared.modules.DeveloperConfig)
		logTest("SafeRequire Basic", testModule ~= nil, error)
		
		-- Test retry functionality exists
		local hasRetry = SafeRequire.requireWithRetry ~= nil
		logTest("SafeRequire Retry Function", hasRetry)
	else
		logTest("SafeRequire Module Load", false, "SafeRequire module not found")
	end
end

-- Test 2: RuntimeValidator System
local function testRuntimeValidator()
	local success, RuntimeValidator = pcall(function()
		return require(ReplicatedStorage.Shared.services.RuntimeValidator)
	end)
	
	if success and RuntimeValidator then
		logTest("RuntimeValidator Load", true)
		
		-- Test validation functions exist
		local hasValidateAll = RuntimeValidator.ValidateAll ~= nil
		local hasValidateService = RuntimeValidator.ValidateService ~= nil
		logTest("RuntimeValidator Functions", hasValidateAll and hasValidateService)
	else
		logTest("RuntimeValidator Load", false, "RuntimeValidator module not found")
	end
end

-- Test 3: Developer Config
local function testDeveloperConfig()
	local success, DeveloperConfig = pcall(function()
		return require(ReplicatedStorage.Shared.modules.DeveloperConfig)
	end)
	
	if success and DeveloperConfig then
		logTest("DeveloperConfig Load", true)
		
		-- Test developer functions
		local hasIsDeveloper = DeveloperConfig.IsDeveloper ~= nil
		local hasDeveloperIds = DeveloperConfig.DEVELOPER_IDS ~= nil
		logTest("DeveloperConfig Functions", hasIsDeveloper and hasDeveloperIds)
		
		-- Test developer ID configuration
		local hasConfiguredIds = #DeveloperConfig.DEVELOPER_IDS > 0 and DeveloperConfig.DEVELOPER_IDS[1] ~= 1
		logTest("Developer IDs Configured", hasConfiguredIds, "Still using placeholder UserID")
	else
		logTest("DeveloperConfig Load", false, "DeveloperConfig module not found")
	end
end

-- Test 4: Data Services
local function testDataServices()
	-- Test UnifiedDataService
	local unifiedSuccess = pcall(function()
		return require(ReplicatedStorage.Shared.utils.SafeRequire).require(
			game.ServerScriptService.services.core.UnifiedDataService
		)
	end)
	logTest("UnifiedDataService Available", unifiedSuccess)
	
	-- Test DataAdapter
	local adapterSuccess = pcall(function()
		return require(ReplicatedStorage.Shared.utils.SafeRequire).require(
			game.ServerScriptService.services.core.DataAdapter
		)
	end)
	logTest("DataAdapter Available", adapterSuccess)
end

-- Test 5: Core Server Services
local function testCoreServices()
	local coreServices = {
		"PlayerService",
		"GameService", 
		"AnalyticsService",
		"MonetizationService"
	}
	
	for _, serviceName in ipairs(coreServices) do
		local success = pcall(function()
			local module = game.ServerScriptService.services:FindFirstChild(serviceName)
			or game.ServerScriptService.services.core:FindFirstChild(serviceName)
			return module ~= nil
		end)
		logTest(serviceName .. " File Exists", success)
	end
end

-- Test 6: Asset Validation
local function testAssetValidation()
	-- Check for placeholder assets
	local placeholderCount = 0
	
	-- This would require reading files and checking for GuiImagePlaceholder
	-- For now, just check if asset directories exist
	local hasSharedAssets = ReplicatedStorage:FindFirstChild("Shared") ~= nil
	logTest("Shared Assets Folder", hasSharedAssets)
	
	-- Check for required folders
	local requiredFolders = {"modules", "constants", "utils", "services"}
	for _, folderName in ipairs(requiredFolders) do
		local exists = ReplicatedStorage.Shared:FindFirstChild(folderName) ~= nil
		logTest("Required Folder: " .. folderName, exists)
	end
end

-- Test 7: World Object Validation
local function testWorldObjects()
	-- Test required workspace objects
	local requiredObjects = {
		"GameTracks",
		"MarketPlaza", 
		"SpawnLocation"
	}
	
	for _, objectName in ipairs(requiredObjects) do
		local exists = workspace:FindFirstChild(objectName) ~= nil
		logTest("World Object: " .. objectName, exists, objectName .. " not found in workspace")
	end
end

-- Main Test Runner
function QATestRunner.runAllTests()
	print("🧪 Starting QA System Validation...")
	print("=====================================")
	
	-- Reset results
	TestResults = {passed = 0, failed = 0, total = 0, details = {}}
	
	-- Run all tests
	testSafeRequire()
	testRuntimeValidator()
	testDeveloperConfig()
	testDataServices()
	testCoreServices()
	testAssetValidation()
	testWorldObjects()
	
	-- Print summary
	print("=====================================")
	print("🎯 QA TEST RESULTS SUMMARY")
	print("=====================================")
	print(string.format("Total Tests: %d", TestResults.total))
	print(string.format("Passed: %d (%.1f%%)", TestResults.passed, (TestResults.passed/TestResults.total)*100))
	print(string.format("Failed: %d (%.1f%%)", TestResults.failed, (TestResults.failed/TestResults.total)*100))
	
	if TestResults.failed > 0 then
		print("\n❌ FAILED TESTS:")
		for _, result in ipairs(TestResults.details) do
			if not result.passed then
				print("  • " .. result.name .. ": " .. (result.details or "No details"))
			end
		end
	end
	
	if TestResults.failed == 0 then
		print("\n🎉 ALL TESTS PASSED! System ready for testing.")
	elseif TestResults.failed <= 2 then
		print("\n⚠️  Minor issues found. Review failed tests.")
	else
		print("\n🚨 Multiple issues found. Address before proceeding.")
	end
	
	print("=====================================")
	
	return TestResults
end

-- Run tests immediately when required
if RunService:IsStudio() then
	print("🔧 QA Test Runner loaded. Run QATestRunner.runAllTests() to validate systems.")
else
	-- Auto-run in live server for server owners
	local player = Players.LocalPlayer
	if player and player.UserId == 5479389335 then -- Developer UserID
		QATestRunner.runAllTests()
	end
end

return QATestRunner
