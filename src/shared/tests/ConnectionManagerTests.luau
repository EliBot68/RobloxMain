--[[
	ConnectionManagerTests.luau
	
	Comprehensive test suite for the ConnectionManager system
	to verify memory leak prevention and proper cleanup.
--]]

local _Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Safe require
local function safeRequire(module, fallback)
	local success, result = pcall(require, module)
	return success and result or fallback or {}
end

local _SafeRequire = safeRequire(ReplicatedStorage.Shared.utils.SafeRequire)
local ConnectionManager = safeRequire(ReplicatedStorage.Shared.core.ConnectionManager)
local ConnectionManagerService = safeRequire(ReplicatedStorage.Shared.services.ConnectionManagerService)

local ConnectionManagerTests = {
	TestResults = {},
	TotalTests = 0,
	PassedTests = 0,
	FailedTests = 0,
}

-- Test framework helpers
function ConnectionManagerTests:StartTest(testName)
	print(string.format("🧪 Starting test: %s", testName))
	self.TotalTests = self.TotalTests + 1
	return {
		name = testName,
		startTime = tick()
	}
end

function ConnectionManagerTests:EndTest(testContext, success, message)
	local duration = tick() - testContext.startTime
	local status = success and "✅ PASS" or "❌ FAIL"
	
	print(string.format("%s %s (%.3fs) - %s", status, testContext.name, duration, message or ""))
	
	table.insert(self.TestResults, {
		name = testContext.name,
		success = success,
		duration = duration,
		message = message
	})
	
	if success then
		self.PassedTests = self.PassedTests + 1
	else
		self.FailedTests = self.FailedTests + 1
	end
end

function ConnectionManagerTests:Assert(condition, message)
	if not condition then
		error("Assertion failed: " .. (message or "Unknown"))
	end
end

-- Test 1: Basic connection tracking
function ConnectionManagerTests:TestBasicConnectionTracking()
	local test = self:StartTest("Basic Connection Tracking")
	
	if not ConnectionManager then
		self:EndTest(test, false, "ConnectionManager not available")
		return
	end
	
	local success, error = pcall(function()
		-- Create a test connection
		local connection = RunService.Heartbeat:Connect(function() end)
		
		-- Track it
		local connectionId = ConnectionManager:TrackConnection(connection, {
			service = "TestService",
			description = "Test connection",
			connectionType = ConnectionManager.ConnectionTypes.HEARTBEAT
		})
		
		self:Assert(connectionId ~= nil, "Connection ID should not be nil")
		self:Assert(type(connectionId) == "string", "Connection ID should be a string")
		
		-- Verify it's tracked
		local stats = ConnectionManager:GetStatistics()
		self:Assert(stats.overview.totalConnections > 0, "Should have at least 1 connection")
		
		-- Clean up
		local disconnected = ConnectionManager:DisconnectConnection(connectionId)
		self:Assert(disconnected, "Should successfully disconnect")
		
		-- Verify cleanup
		local newStats = ConnectionManager:GetStatistics()
		self:Assert(newStats.overview.totalConnections < stats.overview.totalConnections, "Connection count should decrease")
	end)
	
	self:EndTest(test, success, error and tostring(error) or "Basic tracking works correctly")
end

-- Test 2: Player connection cleanup
function ConnectionManagerTests:TestPlayerConnectionCleanup()
	local test = self:StartTest("Player Connection Cleanup")
	
	if not ConnectionManager then
		self:EndTest(test, false, "ConnectionManager not available")
		return
	end
	
	local success, error = pcall(function()
		-- Create a fake player for testing
		local fakePlayer = {
			Name = "TestPlayer",
			UserId = 12345
		}
		
		-- Create multiple connections for the player
		local connectionIds = {}
		for i = 1, 5 do
			local connection = RunService.Heartbeat:Connect(function() end)
			local connectionId = ConnectionManager:TrackConnection(connection, {
				player = fakePlayer,
				service = "TestService",
				description = string.format("Test player connection %d", i),
				connectionType = ConnectionManager.ConnectionTypes.HEARTBEAT
			})
			table.insert(connectionIds, connectionId)
		end
		
		-- Verify connections exist
		local stats = ConnectionManager:GetStatistics()
		self:Assert(stats.overview.totalConnections >= 5, "Should have at least 5 connections")
		
		-- Clean up player connections
		local cleanedCount = ConnectionManager:CleanupPlayerConnections(fakePlayer)
		self:Assert(cleanedCount == 5, string.format("Should clean up 5 connections, got %d", cleanedCount))
		
		-- Verify cleanup
		local newStats = ConnectionManager:GetStatistics()
		self:Assert(newStats.overview.totalConnections == stats.overview.totalConnections - 5, "Should have 5 fewer connections")
	end)
	
	self:EndTest(test, success, error and tostring(error) or "Player cleanup works correctly")
end

-- Test 3: Service connection cleanup
function ConnectionManagerTests:TestServiceConnectionCleanup()
	local test = self:StartTest("Service Connection Cleanup")
	
	if not ConnectionManager then
		self:EndTest(test, false, "ConnectionManager not available")
		return
	end
	
	local success, error = pcall(function()
		local serviceName = "TestService_" .. tick()
		
		-- Create multiple connections for the service
		local connectionIds = {}
		for i = 1, 3 do
			local connection = RunService.Heartbeat:Connect(function() end)
			local connectionId = ConnectionManager:TrackConnection(connection, {
				service = serviceName,
				description = string.format("Test service connection %d", i),
				connectionType = ConnectionManager.ConnectionTypes.HEARTBEAT
			})
			table.insert(connectionIds, connectionId)
		end
		
		-- Verify connections exist
		local stats = ConnectionManager:GetStatistics()
		self:Assert(stats.byService[serviceName] == 3, "Should have 3 connections for service")
		
		-- Clean up service connections
		local cleanedCount = ConnectionManager:CleanupServiceConnections(serviceName)
		self:Assert(cleanedCount == 3, string.format("Should clean up 3 connections, got %d", cleanedCount))
		
		-- Verify cleanup
		local newStats = ConnectionManager:GetStatistics()
		self:Assert(newStats.byService[serviceName] == nil, "Service should have no connections after cleanup")
	end)
	
	self:EndTest(test, success, error and tostring(error) or "Service cleanup works correctly")
end

-- Test 4: Connection manager service wrapper
function ConnectionManagerTests:TestConnectionManagerService()
	local test = self:StartTest("ConnectionManagerService Wrapper")
	
	if not ConnectionManagerService then
		self:EndTest(test, false, "ConnectionManagerService not available")
		return
	end
	
	local success, error = pcall(function()
		-- Initialize the service
		ConnectionManagerService:Initialize()
		
		-- Test player event connection
		local fakePlayer = {
			Name = "TestPlayer2",
			UserId = 12346,
			CharacterAdded = {
				Connect = function(self, callback)
					return {
						Connected = true,
						Disconnect = function() end
					}
				end
			}
		}
		
		local connectionId = ConnectionManagerService:ConnectPlayerEvent(
			fakePlayer,
			fakePlayer.CharacterAdded,
			function() end,
			"TestService",
			"Test character added"
		)
		
		self:Assert(connectionId ~= nil, "Should return connection ID")
		
		-- Test RunService connection
		local heartbeatId = ConnectionManagerService:ConnectRunServiceEvent(
			"Heartbeat",
			function() end,
			"TestService",
			nil,
			"Test heartbeat"
		)
		
		self:Assert(heartbeatId ~= nil, "Should return heartbeat connection ID")
		
		-- Test timer creation
		local timerId = ConnectionManagerService:CreateTimer(
			1.0,
			function() end,
			"TestService",
			nil,
			"Test timer"
		)
		
		self:Assert(timerId ~= nil, "Should return timer connection ID")
		
		-- Test cleanup
		local cleanedCount = ConnectionManagerService:CleanupServiceConnections("TestService")
		self:Assert(cleanedCount >= 2, "Should clean up at least 2 connections")
	end)
	
	self:EndTest(test, success, error and tostring(error) or "ConnectionManagerService works correctly")
end

-- Test 5: Memory leak prevention
function ConnectionManagerTests:TestMemoryLeakPrevention()
	local test = self:StartTest("Memory Leak Prevention")
	
	if not ConnectionManager then
		self:EndTest(test, false, "ConnectionManager not available")
		return
	end
	
	local success, error = pcall(function()
		local initialStats = ConnectionManager:GetStatistics()
		local createdConnections = {}
		
		-- Create many connections without tracking (simulate old pattern)
		for i = 1, 10 do
			local connection = RunService.Heartbeat:Connect(function() end)
			table.insert(createdConnections, connection)
		end
		
		-- Now track them properly
		local trackedIds = {}
		for i, connection in ipairs(createdConnections) do
			-- Disconnect the untracked connection first
			connection:Disconnect()
			
			-- Create a new tracked connection
			local newConnection = RunService.Heartbeat:Connect(function() end)
			local connectionId = ConnectionManager:TrackConnection(newConnection, {
				service = "MemoryTestService",
				description = string.format("Memory test connection %d", i),
				connectionType = ConnectionManager.ConnectionTypes.HEARTBEAT
			})
			table.insert(trackedIds, connectionId)
		end
		
		-- Verify all are tracked
		local midStats = ConnectionManager:GetStatistics()
		self:Assert(midStats.overview.totalConnections >= initialStats.overview.totalConnections + 10, "Should have more connections")
		
		-- Clean up all tracked connections
		local cleanedCount = ConnectionManager:CleanupServiceConnections("MemoryTestService")
		self:Assert(cleanedCount == 10, string.format("Should clean up 10 connections, got %d", cleanedCount))
		
		-- Verify we're back to initial state (or better)
		local finalStats = ConnectionManager:GetStatistics()
		self:Assert(finalStats.overview.totalConnections <= initialStats.overview.totalConnections, "Should not have more connections than started with")
	end)
	
	self:EndTest(test, success, error and tostring(error) or "Memory leak prevention works correctly")
end

-- Test 6: Connection timeout and stale cleanup
function ConnectionManagerTests:TestStaleConnectionCleanup()
	local test = self:StartTest("Stale Connection Cleanup")
	
	if not ConnectionManager then
		self:EndTest(test, false, "ConnectionManager not available")
		return
	end
	
	local success, error = pcall(function()
		-- Create a connection with a very short timeout
		local connection = RunService.Heartbeat:Connect(function() end)
		
		local connectionId = ConnectionManager:TrackConnection(connection, {
			service = "StaleTestService",
			description = "Short-lived test connection",
			connectionType = ConnectionManager.ConnectionTypes.HEARTBEAT,
			timeout = 0.1 -- 0.1 second timeout
		})
		
		self:Assert(connectionId ~= nil, "Should create connection")
		
		-- Wait for timeout
		wait(0.2)
		
		-- Force stale cleanup
		local _cleanedCount = ConnectionManager:CleanupStaleConnections()
		
		-- Verify the connection was cleaned up as stale
		local _stats = ConnectionManager:GetStatistics()
		local details = ConnectionManager:GetConnectionDetails()
		self:Assert(details[connectionId] == nil, "Stale connection should be cleaned up")
	end)
	
	self:EndTest(test, success, error and tostring(error) or "Stale connection cleanup works correctly")
end

-- Test 7: Tagged connection cleanup
function ConnectionManagerTests:TestTaggedConnectionCleanup()
	local test = self:StartTest("Tagged Connection Cleanup")
	
	if not ConnectionManager then
		self:EndTest(test, false, "ConnectionManager not available")
		return
	end
	
	local success, error = pcall(function()
		local tag = "TestTag_" .. tick()
		
		-- Create multiple connections with the same tag
		for i = 1, 4 do
			local connection = RunService.Heartbeat:Connect(function() end)
			ConnectionManager:TrackConnection(connection, {
				service = "TagTestService",
				tag = tag,
				description = string.format("Tagged connection %d", i),
				connectionType = ConnectionManager.ConnectionTypes.HEARTBEAT
			})
		end
		
		-- Verify tagged connections exist
		local stats = ConnectionManager:GetStatistics()
		self:Assert(stats.byTag[tag] == 4, "Should have 4 tagged connections")
		
		-- Clean up by tag
		local cleanedCount = ConnectionManager:CleanupTaggedConnections(tag)
		self:Assert(cleanedCount == 4, string.format("Should clean up 4 tagged connections, got %d", cleanedCount))
		
		-- Verify cleanup
		local newStats = ConnectionManager:GetStatistics()
		self:Assert(newStats.byTag[tag] == nil, "Tag should have no connections after cleanup")
	end)
	
	self:EndTest(test, success, error and tostring(error) or "Tagged connection cleanup works correctly")
end

-- Test 8: Connection statistics accuracy
function ConnectionManagerTests:TestConnectionStatistics()
	local test = self:StartTest("Connection Statistics Accuracy")
	
	if not ConnectionManager then
		self:EndTest(test, false, "ConnectionManager not available")
		return
	end
	
	local success, error = pcall(function()
		local initialStats = ConnectionManager:GetStatistics()
		local serviceName = "StatsTestService"
		
		-- Create tracked connections
		local connectionIds = {}
		for i = 1, 7 do
			local connection = RunService.Heartbeat:Connect(function() end)
			local connectionId = ConnectionManager:TrackConnection(connection, {
				service = serviceName,
				description = string.format("Stats test connection %d", i),
				connectionType = ConnectionManager.ConnectionTypes.HEARTBEAT
			})
			table.insert(connectionIds, connectionId)
		end
		
		-- Check statistics
		local stats = ConnectionManager:GetStatistics()
		self:Assert(stats.byService[serviceName] == 7, "Should show 7 connections for service")
		self:Assert(stats.overview.totalConnections >= initialStats.overview.totalConnections + 7, "Total should increase by 7")
		self:Assert(stats.overview.connectionsCreated >= initialStats.overview.connectionsCreated + 7, "Created count should increase by 7")
		
		-- Disconnect some connections
		for i = 1, 3 do
			ConnectionManager:DisconnectConnection(connectionIds[i])
		end
		
		-- Check updated statistics
		local newStats = ConnectionManager:GetStatistics()
		self:Assert(newStats.byService[serviceName] == 4, "Should show 4 connections remaining for service")
		self:Assert(newStats.overview.connectionsDestroyed >= initialStats.overview.connectionsDestroyed + 3, "Destroyed count should increase by 3")
		
		-- Clean up remaining
		ConnectionManager:CleanupServiceConnections(serviceName)
	end)
	
	self:EndTest(test, success, error and tostring(error) or "Connection statistics are accurate")
end

-- Run all tests
function ConnectionManagerTests:RunAllTests()
	print("🚀 Starting ConnectionManager Test Suite")
	print("=" .. string.rep("=", 50))
	
	-- Reset test counters
	self.TestResults = {}
	self.TotalTests = 0
	self.PassedTests = 0
	self.FailedTests = 0
	
	-- Run tests
	self:TestBasicConnectionTracking()
	self:TestPlayerConnectionCleanup()
	self:TestServiceConnectionCleanup()
	self:TestConnectionManagerService()
	self:TestMemoryLeakPrevention()
	self:TestStaleConnectionCleanup()
	self:TestTaggedConnectionCleanup()
	self:TestConnectionStatistics()
	
	-- Print results
	print("=" .. string.rep("=", 50))
	print(string.format("🏁 Test Suite Complete: %d/%d tests passed", self.PassedTests, self.TotalTests))
	
	if self.FailedTests > 0 then
		print("❌ Failed Tests:")
		for _, result in ipairs(self.TestResults) do
			if not result.success then
				print(string.format("  - %s: %s", result.name, result.message))
			end
		end
	else
		print("✅ All tests passed! ConnectionManager is working correctly.")
	end
	
	return self.FailedTests == 0
end

-- Export test results for analytics
function ConnectionManagerTests:GetTestReport()
	return {
		summary = {
			totalTests = self.TotalTests,
			passedTests = self.PassedTests,
			failedTests = self.FailedTests,
			successRate = self.TotalTests > 0 and (self.PassedTests / self.TotalTests) or 0
		},
		results = self.TestResults,
		timestamp = tick()
	}
end

return ConnectionManagerTests
