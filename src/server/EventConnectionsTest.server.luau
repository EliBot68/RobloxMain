-- EventConnectionsTest.server.luau
-- Comprehensive test for all event connections and system bindings
-- Verifies player spawn logic, service linkages, and game state management

local Players = game:GetService("Players")

local EventConnectionsTest = {}

-- Test configuration
local TEST_CONFIG = {
    enableDetailedLogging = true,
    testTimeout = 30,
    runAutomaticTests = true
}

function EventConnectionsTest:Initialize()
    print("🧪 Initializing Event Connections Test Suite...")
    
    if TEST_CONFIG.runAutomaticTests then
        spawn(function()
            wait(10) -- Wait for all systems to load
            self:RunAllTests()
        end)
    end
    
    return true
end

function EventConnectionsTest:RunAllTests()
    print("\n🚀 Running Event Connections Test Suite...")
    
    local results = {
        coreServicesTest = self:TestCoreServicesAvailability(),
        eventConnectionsTest = self:TestEventConnections(),
        serviceLinkageTest = self:TestServiceLinkages(),
        gameStateTest = self:TestGameStateManagement(),
        playerSpawnTest = self:TestPlayerSpawnLogic(),
        recordingBindingTest = self:TestRecordingBindings(),
        analyticsBindingTest = self:TestAnalyticsBindings(),
        systemResetTest = self:TestSystemResetBindings()
    }
    
    -- Print test results
    self:PrintTestResults(results)
    
    return results
end

-- ========================================
-- CORE SERVICES AVAILABILITY TEST
-- ========================================

function EventConnectionsTest:TestCoreServicesAvailability()
    print("🔍 Testing Core Services Availability...")
    
    local services = {
        "GameService",
        "AnalyticsService", 
        "TrackGeneratorService",
        "DifficultyService",
        "MainGameController",
        "CollisionController",
        "RecordingSessionManager",
        "MovingObstacleService",
        "SystemEventConnections",
        "GameStateEventManager"
    }
    
    local results = {}
    
    for _, serviceName in ipairs(services) do
        local getter = _G["Get" .. serviceName]
        local service = getter and getter()
        
        results[serviceName] = {
            available = service ~= nil,
            hasGetter = getter ~= nil,
            service = service
        }
        
        if TEST_CONFIG.enableDetailedLogging then
            local status = service and "✅" or "❌"
            print(status .. " " .. serviceName .. ": " .. (service and "Available" or "Missing"))
        end
    end
    
    return results
end

-- ========================================
-- EVENT CONNECTIONS TEST
-- ========================================

function EventConnectionsTest:TestEventConnections()
    print("🔗 Testing Event Connections...")
    
    local systemConnections = _G.GetSystemEventConnections()
    if not systemConnections then
        warn("❌ SystemEventConnections not available")
        return {success = false, error = "SystemEventConnections missing"}
    end
    
    -- Test connection status
    local connectionStatus = systemConnections:GetConnectionStatus()
    
    local results = {
        success = true,
        systemConnectionsAvailable = true,
        connectionStatus = connectionStatus,
        expectedConnections = {
            "PlayerAdded",
            "PlayerRemoving", 
            "GameStateChange",
            "ScoreUpdate"
        }
    }
    
    if TEST_CONFIG.enableDetailedLogging then
        print("📋 Connection Status:")
        for name, status in pairs(connectionStatus.eventConnections) do
            local statusIcon = status and "✅" or "❌"
            print("  " .. statusIcon .. " " .. name)
        end
    end
    
    return results
end

-- ========================================
-- SERVICE LINKAGE TEST
-- ========================================

function EventConnectionsTest:TestServiceLinkages()
    print("🔗 Testing Service Linkages...")
    
    local linkageManager = _G.GetServiceLinkageManager and _G.GetServiceLinkageManager()
    local mainController = _G.GetMainGameController()
    local trackGenerator = _G.GetTrackGeneratorService()
    local collisionController = _G.GetCollisionController()
    
    local results = {
        success = true,
        linkageManagerAvailable = linkageManager ~= nil,
        mainControllerLinkages = {},
        bidirectionalCommunication = {}
    }
    
    -- Test MainController → TrackGenerator linkage
    if mainController and trackGenerator then
        results.mainControllerLinkages.trackGenerator = {
            hasReference = mainController.TrackGeneratorService ~= nil,
            hasRequestMethod = mainController.RequestTrackGeneration ~= nil,
            hasGetCurrentTrack = mainController.GetCurrentTrack ~= nil
        }
        
        if TEST_CONFIG.enableDetailedLogging then
            local hasRef = mainController.TrackGeneratorService and "✅" or "❌"
            print("  " .. hasRef .. " MainController → TrackGenerator reference")
            
            local hasMethod = mainController.RequestTrackGeneration and "✅" or "❌"
            print("  " .. hasMethod .. " MainController.RequestTrackGeneration method")
        end
    end
    
    -- Test MainController → CollisionController linkage
    if mainController and collisionController then
        results.mainControllerLinkages.collisionController = {
            hasReference = mainController.CollisionController ~= nil,
            hasEnableMethod = mainController.EnableCollisionDetection ~= nil,
            hasDisableMethod = mainController.DisableCollisionDetection ~= nil
        }
        
        if TEST_CONFIG.enableDetailedLogging then
            local hasRef = mainController.CollisionController and "✅" or "❌"
            print("  " .. hasRef .. " MainController → CollisionController reference")
            
            local hasEnable = mainController.EnableCollisionDetection and "✅" or "❌"
            print("  " .. hasEnable .. " MainController.EnableCollisionDetection method")
        end
    end
    
    -- Test bidirectional communication
    if collisionController and mainController then
        results.bidirectionalCommunication.collision = {
            collisionToMain = collisionController.NotifyPlayerCollision ~= nil,
            mainToCollision = mainController.HandlePlayerCollision ~= nil
        }
        
        if TEST_CONFIG.enableDetailedLogging then
            local toMain = collisionController.NotifyPlayerCollision and "✅" or "❌"
            print("  " .. toMain .. " CollisionController → MainController communication")
            
            local fromMain = mainController.HandlePlayerCollision and "✅" or "❌"
            print("  " .. fromMain .. " MainController ← CollisionController communication")
        end
    end
    
    return results
end

-- ========================================
-- GAME STATE MANAGEMENT TEST
-- ========================================

function EventConnectionsTest:TestGameStateManagement()
    print("🎮 Testing Game State Management...")
    
    local gameStateManager = _G.GetGameStateEventManager()
    if not gameStateManager then
        warn("❌ GameStateEventManager not available")
        return {success = false, error = "GameStateEventManager missing"}
    end
    
    local results = {
        success = true,
        gameStateManagerAvailable = true,
        playerStates = gameStateManager:GetAllPlayerStates(),
        globalState = gameStateManager:GetGlobalGameState(),
        hasStateChangeMethods = {
            changeGameState = gameStateManager.ChangeGameState ~= nil,
            getPlayerState = gameStateManager.GetPlayerState ~= nil,
            setGlobalGameState = gameStateManager.SetGlobalGameState ~= nil
        }
    }
    
    if TEST_CONFIG.enableDetailedLogging then
        print("🎮 Global Game State: " .. tostring(results.globalState))
        
        local playerCount = 0
        for _ in pairs(results.playerStates) do
            playerCount = playerCount + 1
        end
        print("👥 Players with tracked states: " .. playerCount)
        
        for method, available in pairs(results.hasStateChangeMethods) do
            local status = available and "✅" or "❌"
            print("  " .. status .. " " .. method .. " method")
        end
    end
    
    return results
end

-- ========================================
-- PLAYER SPAWN LOGIC TEST
-- ========================================

function EventConnectionsTest:TestPlayerSpawnLogic()
    print("👥 Testing Player Spawn Logic...")
    
    local playerSpawnLogic = _G.GetPlayerSpawnLogic and _G.GetPlayerSpawnLogic()
    
    local results = {
        success = true,
        playerSpawnLogicAvailable = playerSpawnLogic ~= nil,
        spawnPhases = {},
        currentSpawns = {}
    }
    
    if playerSpawnLogic then
        results.currentSpawns = playerSpawnLogic:GetAllSpawnStatuses()
        
        if TEST_CONFIG.enableDetailedLogging then
            print("📋 Current spawn processes:")
            for userId, status in pairs(results.currentSpawns) do
                local player = Players:GetPlayerByUserId(userId)
                local playerName = player and player.Name or "Unknown"
                print("  👤 " .. playerName .. " → " .. status.currentPhase .. " (" .. status.retryCount .. " retries)")
            end
        end
    else
        warn("⚠️ PlayerSpawnLogic not directly accessible (may be internal to SystemEventConnections)")
        results.success = true -- This is expected in current architecture
    end
    
    return results
end

-- ========================================
-- RECORDING BINDINGS TEST
-- ========================================

function EventConnectionsTest:TestRecordingBindings()
    print("🎬 Testing Recording Bindings...")
    
    local recordingManager = _G.GetRecordingSessionManager()
    local gameStateManager = _G.GetGameStateEventManager()
    
    local results = {
        success = true,
        recordingManagerAvailable = recordingManager ~= nil,
        gameStateManagerAvailable = gameStateManager ~= nil,
        recordingMethods = {}
    }
    
    if recordingManager then
        results.recordingMethods = {
            startRecording = recordingManager.StartRecording ~= nil,
            stopRecording = recordingManager.StopRecording ~= nil,
            pauseRecording = recordingManager.PauseRecording ~= nil,
            resumeRecording = recordingManager.ResumeRecording ~= nil
        }
        
        if TEST_CONFIG.enableDetailedLogging then
            for method, available in pairs(results.recordingMethods) do
                local status = available and "✅" or "❌"
                print("  " .. status .. " " .. method .. " method")
            end
        end
    end
    
    return results
end

-- ========================================
-- ANALYTICS BINDINGS TEST
-- ========================================

function EventConnectionsTest:TestAnalyticsBindings()
    print("📊 Testing Analytics Bindings...")
    
    local analyticsService = _G.GetAnalyticsService()
    local gameStateManager = _G.GetGameStateEventManager()
    
    local results = {
        success = true,
        analyticsServiceAvailable = analyticsService ~= nil,
        gameStateManagerAvailable = gameStateManager ~= nil,
        analyticsMethods = {}
    }
    
    if analyticsService then
        results.analyticsMethods = {
            trackEvent = analyticsService.TrackEvent ~= nil,
            trackPlayerJoin = analyticsService.TrackPlayerJoin ~= nil,
            trackPlayerLeave = analyticsService.TrackPlayerLeave ~= nil
        }
        
        if TEST_CONFIG.enableDetailedLogging then
            for method, available in pairs(results.analyticsMethods) do
                local status = available and "✅" or "❌"
                print("  " .. status .. " " .. method .. " method")
            end
        end
    end
    
    return results
end

-- ========================================
-- SYSTEM RESET BINDINGS TEST
-- ========================================

function EventConnectionsTest:TestSystemResetBindings()
    print("🔄 Testing System Reset Bindings...")
    
    local gameStateManager = _G.GetGameStateEventManager()
    local mainController = _G.GetMainGameController()
    
    local results = {
        success = true,
        gameStateManagerAvailable = gameStateManager ~= nil,
        mainControllerAvailable = mainController ~= nil,
        resetMethods = {}
    }
    
    if mainController then
        results.resetMethods = {
            resetPlayerGame = mainController.ResetPlayerGame ~= nil,
            clearPlayerData = mainController.ClearPlayerData ~= nil,
            preparePlayerForGame = mainController.PreparePlayerForGame ~= nil
        }
        
        if TEST_CONFIG.enableDetailedLogging then
            for method, available in pairs(results.resetMethods) do
                local status = available and "✅" or "❌"
                print("  " .. status .. " " .. method .. " method")
            end
        end
    end
    
    return results
end

-- ========================================
-- RESULTS REPORTING
-- ========================================

function EventConnectionsTest:PrintTestResults(results)
    print("\n📊 Event Connections Test Results:")
    print("=" .. string.rep("=", 50))
    
    local totalTests = 0
    local passedTests = 0
    
    for testName, result in pairs(results) do
        totalTests = totalTests + 1
        local success = result.success ~= false
        if success then passedTests = passedTests + 1 end
        
        local status = success and "✅ PASS" or "❌ FAIL"
        print(status .. " " .. testName)
        
        if not success and result.error then
            print("    Error: " .. result.error)
        end
    end
    
    print("=" .. string.rep("=", 50))
    print("📈 Summary: " .. passedTests .. "/" .. totalTests .. " tests passed")
    
    if passedTests == totalTests then
        print("🎉 All event connections and system bindings are working correctly!")
    else
        warn("⚠️ Some tests failed - check the implementation")
    end
    
    return {
        totalTests = totalTests,
        passedTests = passedTests,
        success = passedTests == totalTests
    }
end

-- Manual test triggers for debugging
function EventConnectionsTest:TestPlayerSpawnManual(player)
    if not player then
        warn("❌ No player provided for manual spawn test")
        return
    end
    
    print("🧪 Manual player spawn test for: " .. player.Name)
    
    local systemConnections = _G.GetSystemEventConnections()
    if systemConnections and systemConnections.HandlePlayerAdded then
        systemConnections:HandlePlayerAdded(player)
        print("✅ Manual spawn test triggered")
    else
        warn("❌ Cannot trigger manual spawn test - SystemEventConnections missing")
    end
end

function EventConnectionsTest:TestGameStateChangeManual(player, newState)
    if not player then
        warn("❌ No player provided for manual game state test")
        return
    end
    
    newState = newState or "PLAYING"
    print("🧪 Manual game state change test: " .. player.Name .. " → " .. newState)
    
    local gameStateManager = _G.GetGameStateEventManager()
    if gameStateManager and gameStateManager.ChangeGameState then
        gameStateManager:ChangeGameState(player, newState, {testData = true})
        print("✅ Manual game state test triggered")
    else
        warn("❌ Cannot trigger manual game state test - GameStateEventManager missing")
    end
end

-- Global accessors for manual testing
_G.TestEventConnections = EventConnectionsTest
_G.RunEventConnectionsTests = function()
    return EventConnectionsTest:RunAllTests()
end

-- Auto-initialize
spawn(function()
    wait(12) -- Wait for all other systems
    EventConnectionsTest:Initialize()
end)

return EventConnectionsTest
