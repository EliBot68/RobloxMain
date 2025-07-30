-- TestingUtilitiesSystem.luau
-- Testing utilities and mocks for complex dependencies
-- Provides comprehensive testing helpers, mocking frameworks, and dependency injection for testing

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")

local SafeRequire = require(ReplicatedStorage.Shared.utils.SafeRequire)

local TestingUtilitiesSystem = {}

-- ========================================
-- TESTING UTILITIES CONFIGURATION
-- ========================================

local UTILITIES_CONFIG = {
    -- Mock system settings
    mocking = {
        enableAutomaticMocking = true,
        enableSpying = true,
        enableStubbing = true,
        enablePartialMocking = true,
        mockCallTracking = true,
        mockValidation = true
    },
    
    -- Test data generation
    testData = {
        enableDataGeneration = true,
        enableRandomization = true,
        enableFixtures = true,
        enableFactories = true,
        seedValue = 12345
    },
    
    -- Dependency injection
    dependencyInjection = {
        enableDependencyInjection = true,
        enableContainerManagement = true,
        enableScopeManagement = true,
        enableLifecycleManagement = true
    },
    
    -- Test environment
    environment = {
        enableIsolation = true,
        enableSandboxing = true,
        enableStateManagement = true,
        enableCleanupHooks = true,
        timeoutMs = 30000
    },
    
    -- Utilities
    utilities = {
        enableAsyncHelpers = true,
        enableMatchers = true,
        enableAssertions = true,
        enableTestDoubles = true
    }
}

-- ========================================
-- TESTING UTILITIES STATE
-- ========================================

local UtilitiesState = {
    -- Mocking system
    mocks = {},
    spies = {},
    stubs = {},
    mockFactories = {},
    
    -- Test data system
    fixtures = {},
    factories = {},
    generators = {},
    testData = {},
    
    -- Dependency injection
    container = {},
    dependencies = {},
    scopes = {},
    lifecycles = {},
    
    -- Test environment
    testEnvironments = {},
    activeEnvironment = nil,
    cleanupHooks = {},
    
    -- Test doubles
    testDoubles = {},
    
    -- Statistics
    stats = {
        mocksCreated = 0,
        spiesCreated = 0,
        stubsCreated = 0,
        testDataGenerated = 0,
        dependenciesInjected = 0
    }
}

function TestingUtilitiesSystem.initialize()
    print("🧰 Initializing TestingUtilitiesSystem...")
    
    -- Set up mocking framework
    TestingUtilitiesSystem.setupMockingFramework()
    
    -- Initialize test data generation
    TestingUtilitiesSystem.initializeTestDataGeneration()
    
    -- Set up dependency injection
    TestingUtilitiesSystem.setupDependencyInjection()
    
    -- Initialize test environment management
    TestingUtilitiesSystem.initializeTestEnvironment()
    
    -- Set up testing utilities
    TestingUtilitiesSystem.setupTestingUtilities()
    
    print("🧰 TestingUtilitiesSystem initialized successfully")
end

-- ========================================
-- MOCKING FRAMEWORK
-- ========================================

function TestingUtilitiesSystem.setupMockingFramework()
    UtilitiesState.mockingFramework = {
        mocks = {},
        spies = {},
        stubs = {},
        callHistory = {},
        verifications = {}
    }
    
    print("🎭 Mocking framework initialized")
end

function TestingUtilitiesSystem.createMock(originalObject, options)
    options = options or {}
    
    local mock = {
        _isMock = true,
        _original = originalObject,
        _options = options,
        _calls = {},
        _returnValues = {},
        _implementations = {},
        _properties = {},
        _metadata = {
            createdAt = tick(),
            name = options.name or "Mock",
            strict = options.strict or false
        }
    }
    
    -- Create mock methods based on original object
    if originalObject and type(originalObject) == "table" then
        for key, value in pairs(originalObject) do
            if type(value) == "function" then
                mock[key] = TestingUtilitiesSystem.createMockMethod(mock, key, value)
            else
                mock[key] = value
            end
        end
    end
    
    -- Add mock control methods
    TestingUtilitiesSystem.addMockControlMethods(mock)
    
    UtilitiesState.mocks[#UtilitiesState.mocks + 1] = mock
    UtilitiesState.stats.mocksCreated = UtilitiesState.stats.mocksCreated + 1
    
    return mock
end

function TestingUtilitiesSystem.createMockMethod(mock, methodName, originalMethod)
    return function(...)
        local args = {...}
        local callInfo = {
            method = methodName,
            args = args,
            timestamp = tick(),
            returnValue = nil,
            threwError = false,
            error = nil
        }
        
        -- Record the call
        if not mock._calls[methodName] then
            mock._calls[methodName] = {}
        end
        table.insert(mock._calls[methodName], callInfo)
        
        -- Check for custom implementation
        if mock._implementations[methodName] then
            local success, result = pcall(mock._implementations[methodName], unpack(args))
            callInfo.returnValue = result
            callInfo.threwError = not success
            callInfo.error = not success and result or nil
            
            if not success then
                error(result)
            end
            return result
        end
        
        -- Check for preset return value
        if mock._returnValues[methodName] then
            callInfo.returnValue = mock._returnValues[methodName]
            return mock._returnValues[methodName]
        end
        
        -- Call original method if available and not strict mock
        if not mock._metadata.strict and originalMethod then
            local success, result = pcall(originalMethod, unpack(args))
            callInfo.returnValue = result
            callInfo.threwError = not success
            callInfo.error = not success and result or nil
            
            if not success then
                error(result)
            end
            return result
        end
        
        return nil
    end
end

function TestingUtilitiesSystem.addMockControlMethods(mock)
    mock.mockReturnValue = function(methodName, value)
        mock._returnValues[methodName] = value
        return mock
    end
    
    mock.mockImplementation = function(methodName, implementation)
        mock._implementations[methodName] = implementation
        return mock
    end
    
    mock.mockClear = function(methodName)
        if methodName then
            mock._calls[methodName] = {}
        else
            mock._calls = {}
        end
        return mock
    end
    
    mock.mockReset = function()
        mock._calls = {}
        mock._returnValues = {}
        mock._implementations = {}
        return mock
    end
    
    mock.mockRestore = function()
        return mock._original
    end
    
    mock.getCallCount = function(methodName)
        return mock._calls[methodName] and #mock._calls[methodName] or 0
    end
    
    mock.getCalls = function(methodName)
        return mock._calls[methodName] or {}
    end
    
    mock.getLastCall = function(methodName)
        local calls = mock._calls[methodName]
        return calls and calls[#calls] or nil
    end
    
    mock.wasCalledWith = function(methodName, ...)
        local expectedArgs = {...}
        local calls = mock._calls[methodName] or {}
        
        for _, call in ipairs(calls) do
            if TestingUtilitiesSystem.deepEqual(call.args, expectedArgs) then
                return true
            end
        end
        return false
    end
end

function TestingUtilitiesSystem.createSpy(originalFunction, name)
    local spy = {
        _isSpy = true,
        _original = originalFunction,
        _name = name or "Spy",
        _calls = {},
        _metadata = {
            createdAt = tick()
        }
    }
    
    local spyFunction = function(...)
        local args = {...}
        local callInfo = {
            args = args,
            timestamp = tick(),
            returnValue = nil,
            threwError = false,
            error = nil
        }
        
        table.insert(spy._calls, callInfo)
        
        if originalFunction then
            local success, result = pcall(originalFunction, unpack(args))
            callInfo.returnValue = result
            callInfo.threwError = not success
            callInfo.error = not success and result or nil
            
            if not success then
                error(result)
            end
            return result
        end
        
        return nil
    end
    
    -- Add spy methods
    spy.getCallCount = function()
        return #spy._calls
    end
    
    spy.getCalls = function()
        return spy._calls
    end
    
    spy.getLastCall = function()
        return spy._calls[#spy._calls]
    end
    
    spy.wasCalledWith = function(...)
        local expectedArgs = {...}
        for _, call in ipairs(spy._calls) do
            if TestingUtilitiesSystem.deepEqual(call.args, expectedArgs) then
                return true
            end
        end
        return false
    end
    
    spy.clear = function()
        spy._calls = {}
        return spy
    end
    
    setmetatable(spy, {
        __call = spyFunction
    })
    
    UtilitiesState.spies[#UtilitiesState.spies + 1] = spy
    UtilitiesState.stats.spiesCreated = UtilitiesState.stats.spiesCreated + 1
    
    return spy
end

function TestingUtilitiesSystem.createStub(name, implementation)
    local stub = {
        _isStub = true,
        _name = name or "Stub",
        _implementation = implementation,
        _calls = {},
        _returnValue = nil,
        _metadata = {
            createdAt = tick()
        }
    }
    
    local stubFunction = function(...)
        local args = {...}
        local callInfo = {
            args = args,
            timestamp = tick(),
            returnValue = nil,
            threwError = false,
            error = nil
        }
        
        table.insert(stub._calls, callInfo)
        
        if stub._implementation then
            local success, result = pcall(stub._implementation, unpack(args))
            callInfo.returnValue = result
            callInfo.threwError = not success
            callInfo.error = not success and result or nil
            
            if not success then
                error(result)
            end
            return result
        elseif stub._returnValue ~= nil then
            callInfo.returnValue = stub._returnValue
            return stub._returnValue
        end
        
        return nil
    end
    
    -- Add stub methods
    stub.returns = function(value)
        stub._returnValue = value
        return stub
    end
    
    stub.throws = function(error)
        stub._implementation = function()
            error(error)
        end
        return stub
    end
    
    stub.callsThrough = function(originalFunction)
        stub._implementation = originalFunction
        return stub
    end
    
    stub.getCallCount = function()
        return #stub._calls
    end
    
    stub.getCalls = function()
        return stub._calls
    end
    
    setmetatable(stub, {
        __call = stubFunction
    })
    
    UtilitiesState.stubs[#UtilitiesState.stubs + 1] = stub
    UtilitiesState.stats.stubsCreated = UtilitiesState.stats.stubsCreated + 1
    
    return stub
end

function TestingUtilitiesSystem.verifyMockCall(mock, methodName, expectedArgs, times)
    if not mock._isMock then
        error("Object is not a mock")
    end
    
    local calls = mock._calls[methodName] or {}
    local matchingCalls = 0
    
    if expectedArgs then
        for _, call in ipairs(calls) do
            if TestingUtilitiesSystem.deepEqual(call.args, expectedArgs) then
                matchingCalls = matchingCalls + 1
            end
        end
    else
        matchingCalls = #calls
    end
    
    if times then
        return matchingCalls == times
    else
        return matchingCalls > 0
    end
end

-- ========================================
-- TEST DATA GENERATION
-- ========================================

function TestingUtilitiesSystem.initializeTestDataGeneration()
    UtilitiesState.testDataGenerator = {
        seed = UTILITIES_CONFIG.testData.seedValue,
        generators = {},
        fixtures = {},
        factories = {}
    }
    
    -- Set up random seed for reproducible tests
    math.randomseed(UTILITIES_CONFIG.testData.seedValue)
    
    -- Initialize built-in generators
    TestingUtilitiesSystem.setupBuiltInGenerators()
    
    print("🎲 Test data generation initialized")
end

function TestingUtilitiesSystem.setupBuiltInGenerators()
    local generators = UtilitiesState.testDataGenerator.generators
    
    generators.string = function(length, charset)
        length = length or 10
        charset = charset or "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
        
        local result = ""
        for i = 1, length do
            local randomIndex = math.random(1, #charset)
            result = result .. string.sub(charset, randomIndex, randomIndex)
        end
        return result
    end
    
    generators.number = function(min, max)
        min = min or 1
        max = max or 100
        return math.random(min, max)
    end
    
    generators.boolean = function()
        return math.random() > 0.5
    end
    
    generators.array = function(length, elementGenerator)
        length = length or 5
        elementGenerator = elementGenerator or generators.number
        
        local array = {}
        for i = 1, length do
            array[i] = elementGenerator()
        end
        return array
    end
    
    generators.object = function(schema)
        local object = {}
        for key, generator in pairs(schema or {}) do
            object[key] = generator()
        end
        return object
    end
    
    generators.userId = function()
        return math.random(1000000, 9999999)
    end
    
    generators.username = function()
        local prefixes = {"Player", "User", "Gamer", "Pro", "Elite"}
        local suffixes = {"123", "456", "789", "999", "2023"}
        return prefixes[math.random(#prefixes)] .. suffixes[math.random(#suffixes)]
    end
    
    generators.vector3 = function(range)
        range = range or 100
        return Vector3.new(
            math.random(-range, range),
            math.random(-range, range),
            math.random(-range, range)
        )
    end
    
    generators.color3 = function()
        return Color3.new(
            math.random(),
            math.random(),
            math.random()
        )
    end
end

function TestingUtilitiesSystem.generate(generatorName, ...)
    local generator = UtilitiesState.testDataGenerator.generators[generatorName]
    if not generator then
        error(string.format("Generator '%s' not found", generatorName))
    end
    
    UtilitiesState.stats.testDataGenerated = UtilitiesState.stats.testDataGenerated + 1
    return generator(...)
end

function TestingUtilitiesSystem.registerGenerator(name, generatorFunction)
    UtilitiesState.testDataGenerator.generators[name] = generatorFunction
end

function TestingUtilitiesSystem.createFixture(name, data)
    UtilitiesState.testDataGenerator.fixtures[name] = data
    return data
end

function TestingUtilitiesSystem.getFixture(name)
    return UtilitiesState.testDataGenerator.fixtures[name]
end

function TestingUtilitiesSystem.createFactory(name, template)
    UtilitiesState.testDataGenerator.factories[name] = template
    return template
end

function TestingUtilitiesSystem.build(factoryName, overrides)
    local template = UtilitiesState.testDataGenerator.factories[factoryName]
    if not template then
        error(string.format("Factory '%s' not found", factoryName))
    end
    
    local result = {}
    
    -- Apply template
    for key, value in pairs(template) do
        if type(value) == "function" then
            result[key] = value()
        else
            result[key] = value
        end
    end
    
    -- Apply overrides
    if overrides then
        for key, value in pairs(overrides) do
            result[key] = value
        end
    end
    
    return result
end

-- ========================================
-- DEPENDENCY INJECTION
-- ========================================

function TestingUtilitiesSystem.setupDependencyInjection()
    UtilitiesState.diContainer = {
        dependencies = {},
        singletons = {},
        factories = {},
        scopes = {},
        resolvers = {}
    }
    
    print("💉 Dependency injection initialized")
end

function TestingUtilitiesSystem.registerDependency(name, implementation, options)
    options = options or {}
    
    local dependency = {
        name = name,
        implementation = implementation,
        type = options.type or "transient", -- "transient", "singleton", "scoped"
        scope = options.scope,
        factory = options.factory,
        instance = nil
    }
    
    UtilitiesState.diContainer.dependencies[name] = dependency
    UtilitiesState.stats.dependenciesInjected = UtilitiesState.stats.dependenciesInjected + 1
    
    return dependency
end

function TestingUtilitiesSystem.resolveDependency(name)
    local dependency = UtilitiesState.diContainer.dependencies[name]
    if not dependency then
        error(string.format("Dependency '%s' not registered", name))
    end
    
    if dependency.type == "singleton" then
        if not dependency.instance then
            dependency.instance = TestingUtilitiesSystem.createDependencyInstance(dependency)
        end
        return dependency.instance
    elseif dependency.type == "scoped" then
        local scope = TestingUtilitiesSystem.getCurrentScope()
        if not scope.instances[name] then
            scope.instances[name] = TestingUtilitiesSystem.createDependencyInstance(dependency)
        end
        return scope.instances[name]
    else -- transient
        return TestingUtilitiesSystem.createDependencyInstance(dependency)
    end
end

function TestingUtilitiesSystem.createDependencyInstance(dependency)
    if dependency.factory then
        return dependency.factory()
    elseif type(dependency.implementation) == "function" then
        return dependency.implementation()
    else
        return dependency.implementation
    end
end

function TestingUtilitiesSystem.createScope(name)
    local scope = {
        name = name,
        instances = {},
        createdAt = tick(),
        active = true
    }
    
    UtilitiesState.diContainer.scopes[name] = scope
    return scope
end

function TestingUtilitiesSystem.getCurrentScope()
    return UtilitiesState.diContainer.currentScope or TestingUtilitiesSystem.createScope("default")
end

function TestingUtilitiesSystem.withScope(scopeName, func)
    local originalScope = UtilitiesState.diContainer.currentScope
    UtilitiesState.diContainer.currentScope = UtilitiesState.diContainer.scopes[scopeName] or TestingUtilitiesSystem.createScope(scopeName)
    
    local success, result = pcall(func)
    
    UtilitiesState.diContainer.currentScope = originalScope
    
    if not success then
        error(result)
    end
    
    return result
end

function TestingUtilitiesSystem.clearDependencies()
    UtilitiesState.diContainer.dependencies = {}
    UtilitiesState.diContainer.singletons = {}
    UtilitiesState.diContainer.scopes = {}
end

-- ========================================
-- TEST ENVIRONMENT MANAGEMENT
-- ========================================

function TestingUtilitiesSystem.initializeTestEnvironment()
    UtilitiesState.testEnvironmentManager = {
        environments = {},
        activeEnvironment = nil,
        isolationLevel = "full" -- "none", "partial", "full"
    }
    
    print("🏗️ Test environment management initialized")
end

function TestingUtilitiesSystem.createTestEnvironment(name, config)
    config = config or {}
    
    local environment = {
        name = name,
        isolated = config.isolated ~= false,
        sandboxed = config.sandboxed or false,
        state = {},
        mocks = {},
        spies = {},
        stubs = {},
        cleanupHooks = {},
        createdAt = tick(),
        active = false
    }
    
    UtilitiesState.testEnvironmentManager.environments[name] = environment
    return environment
end

function TestingUtilitiesSystem.activateEnvironment(name)
    local environment = UtilitiesState.testEnvironmentManager.environments[name]
    if not environment then
        error(string.format("Test environment '%s' not found", name))
    end
    
    -- Deactivate current environment
    if UtilitiesState.testEnvironmentManager.activeEnvironment then
        UtilitiesState.testEnvironmentManager.activeEnvironment.active = false
    end
    
    -- Activate new environment
    environment.active = true
    UtilitiesState.testEnvironmentManager.activeEnvironment = environment
    
    return environment
end

function TestingUtilitiesSystem.withEnvironment(environmentName, testFunction)
    local originalEnvironment = UtilitiesState.testEnvironmentManager.activeEnvironment
    
    local environment = TestingUtilitiesSystem.activateEnvironment(environmentName)
    
    local success, result = pcall(testFunction, environment)
    
    -- Restore original environment
    if originalEnvironment then
        TestingUtilitiesSystem.activateEnvironment(originalEnvironment.name)
    else
        UtilitiesState.testEnvironmentManager.activeEnvironment = nil
    end
    
    if not success then
        error(result)
    end
    
    return result
end

function TestingUtilitiesSystem.addCleanupHook(hook)
    local environment = UtilitiesState.testEnvironmentManager.activeEnvironment
    if environment then
        table.insert(environment.cleanupHooks, hook)
    end
end

function TestingUtilitiesSystem.runCleanupHooks(environment)
    environment = environment or UtilitiesState.testEnvironmentManager.activeEnvironment
    if not environment then
        return
    end
    
    for _, hook in ipairs(environment.cleanupHooks) do
        pcall(hook)
    end
    
    environment.cleanupHooks = {}
end

function TestingUtilitiesSystem.cleanupEnvironment(name)
    local environment = UtilitiesState.testEnvironmentManager.environments[name]
    if not environment then
        return
    end
    
    -- Run cleanup hooks
    TestingUtilitiesSystem.runCleanupHooks(environment)
    
    -- Clear mocks, spies, stubs
    environment.mocks = {}
    environment.spies = {}
    environment.stubs = {}
    environment.state = {}
    
    -- Clear dependencies if isolated
    if environment.isolated then
        TestingUtilitiesSystem.clearDependencies()
    end
end

-- ========================================
-- TESTING UTILITIES
-- ========================================

function TestingUtilitiesSystem.setupTestingUtilities()
    -- Async helpers
    TestingUtilitiesSystem.setupAsyncHelpers()
    
    -- Custom matchers
    TestingUtilitiesSystem.setupCustomMatchers()
    
    -- Test doubles
    TestingUtilitiesSystem.setupTestDoubles()
    
    print("🔧 Testing utilities initialized")
end

function TestingUtilitiesSystem.setupAsyncHelpers()
    UtilitiesState.asyncHelpers = {}
end

function TestingUtilitiesSystem.waitFor(condition, timeout, interval)
    timeout = timeout or 5000 -- 5 seconds
    interval = interval or 100 -- 100ms
    
    local startTime = tick()
    
    while true do
        if condition() then
            return true
        end
        
        if (tick() - startTime) * 1000 >= timeout then
            return false, "Timeout waiting for condition"
        end
        
        task.wait(interval / 1000)
    end
end

function TestingUtilitiesSystem.eventually(assertion, timeout, interval)
    local success, error = TestingUtilitiesSystem.waitFor(function()
        local ok, err = pcall(assertion)
        return ok
    end, timeout, interval)
    
    if not success then
        error(error or "Assertion never became true")
    end
end

function TestingUtilitiesSystem.setupCustomMatchers()
    UtilitiesState.customMatchers = {}
end

function TestingUtilitiesSystem.addMatcher(name, matcherFunction)
    UtilitiesState.customMatchers[name] = matcherFunction
end

function TestingUtilitiesSystem.setupTestDoubles()
    UtilitiesState.testDoubles = {
        dummies = {},
        fakes = {},
        doubles = {}
    }
end

function TestingUtilitiesSystem.createDummy(interface)
    local dummy = {}
    
    for key, value in pairs(interface) do
        if type(value) == "function" then
            dummy[key] = function() end
        else
            dummy[key] = nil
        end
    end
    
    return dummy
end

function TestingUtilitiesSystem.createFake(interface, behavior)
    local fake = {}
    
    for key, value in pairs(interface) do
        if type(value) == "function" then
            fake[key] = behavior[key] or function() return nil end
        else
            fake[key] = behavior[key] or nil
        end
    end
    
    return fake
end

-- ========================================
-- UTILITY FUNCTIONS
-- ========================================

function TestingUtilitiesSystem.deepEqual(a, b)
    if type(a) ~= type(b) then
        return false
    end
    
    if type(a) == "table" then
        for key, value in pairs(a) do
            if not TestingUtilitiesSystem.deepEqual(value, b[key]) then
                return false
            end
        end
        
        for key, value in pairs(b) do
            if a[key] == nil then
                return false
            end
        end
        
        return true
    else
        return a == b
    end
end

function TestingUtilitiesSystem.deepCopy(original)
    if type(original) ~= "table" then
        return original
    end
    
    local copy = {}
    for key, value in pairs(original) do
        copy[key] = TestingUtilitiesSystem.deepCopy(value)
    end
    
    return copy
end

function TestingUtilitiesSystem.clearAllMocks()
    for _, mock in ipairs(UtilitiesState.mocks) do
        mock.mockReset()
    end
    
    for _, spy in ipairs(UtilitiesState.spies) do
        spy.clear()
    end
    
    UtilitiesState.mocks = {}
    UtilitiesState.spies = {}
    UtilitiesState.stubs = {}
end

-- ========================================
-- PREDEFINED TEST UTILITIES
-- ========================================

function TestingUtilitiesSystem.setupPredefinedUtilities()
    -- Create common test fixtures
    TestingUtilitiesSystem.createFixture("samplePlayer", {
        userId = 12345,
        username = "TestPlayer",
        displayName = "Test Player",
        level = 5,
        experience = 1250,
        currency = 500
    })
    
    TestingUtilitiesSystem.createFixture("sampleGameData", {
        sessionId = "test-session-123",
        startTime = tick(),
        players = {},
        settings = {
            difficulty = "normal",
            music = true,
            effects = true
        }
    })
    
    -- Create common factories
    TestingUtilitiesSystem.createFactory("player", {
        userId = function() return TestingUtilitiesSystem.generate("userId") end,
        username = function() return TestingUtilitiesSystem.generate("username") end,
        level = function() return TestingUtilitiesSystem.generate("number", 1, 50) end,
        experience = function() return TestingUtilitiesSystem.generate("number", 0, 10000) end,
        currency = function() return TestingUtilitiesSystem.generate("number", 0, 1000) end
    })
    
    TestingUtilitiesSystem.createFactory("gameSession", {
        sessionId = function() return TestingUtilitiesSystem.generate("string", 16) end,
        startTime = function() return tick() end,
        duration = function() return TestingUtilitiesSystem.generate("number", 60, 1800) end,
        playerCount = function() return TestingUtilitiesSystem.generate("number", 1, 10) end
    })
    
    -- Register common dependencies
    TestingUtilitiesSystem.registerDependency("HttpService", game:GetService("HttpService"))
    TestingUtilitiesSystem.registerDependency("Players", game:GetService("Players"))
    TestingUtilitiesSystem.registerDependency("RunService", game:GetService("RunService"))
    
    print("🏭 Predefined test utilities set up")
end

-- ========================================
-- PUBLIC API
-- ========================================

function TestingUtilitiesSystem.runTestUtilitiesDemo()
    print("🧰 Running test utilities demonstration...")
    
    -- Set up predefined utilities
    TestingUtilitiesSystem.setupPredefinedUtilities()
    
    -- Demonstrate mocking
    print("  🎭 Testing mocking capabilities...")
    local mockService = TestingUtilitiesSystem.createMock({
        getData = function() return "real data" end,
        processData = function(data) return data .. " processed" end
    }, {name = "MockDataService"})
    
    mockService.mockReturnValue("getData", "mock data")
    local result = mockService.getData()
    print(string.format("    Mock result: %s", result))
    
    -- Demonstrate spying
    print("  👁️ Testing spy capabilities...")
    local originalFunction = function(x) return x * 2 end
    local spy = TestingUtilitiesSystem.createSpy(originalFunction, "MultiplierSpy")
    
    local spyResult = spy(5)
    print(string.format("    Spy result: %d (called %d times)", spyResult, spy.getCallCount()))
    
    -- Demonstrate test data generation
    print("  🎲 Testing data generation...")
    local testPlayer = TestingUtilitiesSystem.build("player")
    print(string.format("    Generated player: %s (Level %d)", testPlayer.username, testPlayer.level))
    
    -- Demonstrate dependency injection
    print("  💉 Testing dependency injection...")
    TestingUtilitiesSystem.withScope("test", function()
        local httpService = TestingUtilitiesSystem.resolveDependency("HttpService")
        print(string.format("    Resolved HttpService: %s", tostring(httpService)))
    end)
    
    print("🧰 Test utilities demonstration completed")
end

function TestingUtilitiesSystem.getUtilitiesStats()
    return UtilitiesState.stats
end

function TestingUtilitiesSystem.getAllMocks()
    return UtilitiesState.mocks
end

function TestingUtilitiesSystem.getAllSpies()
    return UtilitiesState.spies
end

function TestingUtilitiesSystem.getAllStubs()
    return UtilitiesState.stubs
end

-- Export API
TestingUtilitiesSystem.createMock = TestingUtilitiesSystem.createMock
TestingUtilitiesSystem.createSpy = TestingUtilitiesSystem.createSpy
TestingUtilitiesSystem.createStub = TestingUtilitiesSystem.createStub
TestingUtilitiesSystem.generate = TestingUtilitiesSystem.generate
TestingUtilitiesSystem.build = TestingUtilitiesSystem.build
TestingUtilitiesSystem.getFixture = TestingUtilitiesSystem.getFixture
TestingUtilitiesSystem.registerDependency = TestingUtilitiesSystem.registerDependency
TestingUtilitiesSystem.resolveDependency = TestingUtilitiesSystem.resolveDependency
TestingUtilitiesSystem.createTestEnvironment = TestingUtilitiesSystem.createTestEnvironment
TestingUtilitiesSystem.withEnvironment = TestingUtilitiesSystem.withEnvironment
TestingUtilitiesSystem.waitFor = TestingUtilitiesSystem.waitFor
TestingUtilitiesSystem.eventually = TestingUtilitiesSystem.eventually
TestingUtilitiesSystem.clearAllMocks = TestingUtilitiesSystem.clearAllMocks

-- Initialize the testing utilities system
TestingUtilitiesSystem.initialize()

print("🧰 TestingUtilitiesSystem loaded with comprehensive testing utilities")

return TestingUtilitiesSystem
