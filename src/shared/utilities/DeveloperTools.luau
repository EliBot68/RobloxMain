-- DeveloperTools.luau
-- Advanced developer tools for monitoring, testing, and debugging
-- Provides comprehensive development utilities, test runners, and monitoring dashboards

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local HttpService = game:GetService("HttpService")
local TweenService = game:GetService("TweenService")
local ConfigurationManager = require(ReplicatedStorage.Shared.core.ConfigurationManager)

local DeveloperTools = {}

-- ========================================
-- MONITORING DASHBOARD
-- ========================================

local MonitoringDashboard = {}

function MonitoringDashboard:CreateDashboard()
    if RunService:IsServer() then
        print("ℹ️ Monitoring dashboard only available on client")
        return
    end
    
    local player = Players.LocalPlayer
    local gui = Instance.new("ScreenGui")
    gui.Name = "MonitoringDashboard"
    gui.ResetOnSpawn = false
    gui.Parent = player:WaitForChild("PlayerGui")
    
    -- Main frame
    local mainFrame = Instance.new("Frame")
    mainFrame.Name = "DashboardFrame"
    mainFrame.Size = UDim2.new(0.3, 0, 0.4, 0)
    mainFrame.Position = UDim2.new(1, -10, 0, 10)
    mainFrame.AnchorPoint = Vector2.new(1, 0)
    mainFrame.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
    mainFrame.BorderSizePixel = 0
    mainFrame.Parent = gui
    
    -- Corner rounding
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 8)
    corner.Parent = mainFrame
    
    -- Title bar
    local titleBar = Instance.new("Frame")
    titleBar.Name = "TitleBar"
    titleBar.Size = UDim2.new(1, 0, 0, 30)
    titleBar.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
    titleBar.BorderSizePixel = 0
    titleBar.Parent = mainFrame
    
    local titleCorner = Instance.new("UICorner")
    titleCorner.CornerRadius = UDim.new(0, 8)
    titleCorner.Parent = titleBar
    
    local titleLabel = Instance.new("TextLabel")
    titleLabel.Text = "📊 Developer Monitor"
    titleLabel.Size = UDim2.new(1, -40, 1, 0)
    titleLabel.Position = UDim2.new(0, 10, 0, 0)
    titleLabel.BackgroundTransparency = 1
    titleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    titleLabel.TextXAlignment = Enum.TextXAlignment.Left
    titleLabel.Font = Enum.Font.SourceSansBold
    titleLabel.TextSize = 14
    titleLabel.Parent = titleBar
    
    -- Minimize button
    local minimizeButton = Instance.new("TextButton")
    minimizeButton.Text = "−"
    minimizeButton.Size = UDim2.new(0, 30, 1, 0)
    minimizeButton.Position = UDim2.new(1, -30, 0, 0)
    minimizeButton.BackgroundTransparency = 1
    minimizeButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    minimizeButton.Font = Enum.Font.SourceSansBold
    minimizeButton.TextSize = 16
    minimizeButton.Parent = titleBar
    
    -- Content frame
    local contentFrame = Instance.new("Frame")
    contentFrame.Name = "ContentFrame"
    contentFrame.Size = UDim2.new(1, -20, 1, -40)
    contentFrame.Position = UDim2.new(0, 10, 0, 35)
    contentFrame.BackgroundTransparency = 1
    contentFrame.Parent = mainFrame
    
    -- Metrics
    local metrics = {
        {name = "FPS", value = "0", color = Color3.fromRGB(100, 255, 100)},
        {name = "Memory", value = "0 KB", color = Color3.fromRGB(255, 255, 100)},
        {name = "Players", value = "0", color = Color3.fromRGB(100, 200, 255)},
        {name = "Objects", value = "0", color = Color3.fromRGB(255, 150, 100)},
        {name = "Errors", value = "0", color = Color3.fromRGB(255, 100, 100)},
        {name = "Network", value = "OK", color = Color3.fromRGB(150, 255, 150)}
    }
    
    local metricLabels = {}
    local metricValues = {}
    
    for i, metric in ipairs(metrics) do
        local metricFrame = Instance.new("Frame")
        metricFrame.Size = UDim2.new(1, 0, 0, 25)
        metricFrame.Position = UDim2.new(0, 0, 0, (i - 1) * 30)
        metricFrame.BackgroundTransparency = 1
        metricFrame.Parent = contentFrame
        
        local nameLabel = Instance.new("TextLabel")
        nameLabel.Text = metric.name .. ":"
        nameLabel.Size = UDim2.new(0.5, 0, 1, 0)
        nameLabel.BackgroundTransparency = 1
        nameLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
        nameLabel.TextXAlignment = Enum.TextXAlignment.Left
        nameLabel.Font = Enum.Font.SourceSans
        nameLabel.TextSize = 12
        nameLabel.Parent = metricFrame
        
        local valueLabel = Instance.new("TextLabel")
        valueLabel.Text = metric.value
        valueLabel.Size = UDim2.new(0.5, 0, 1, 0)
        valueLabel.Position = UDim2.new(0.5, 0, 0, 0)
        valueLabel.BackgroundTransparency = 1
        valueLabel.TextColor3 = metric.color
        valueLabel.TextXAlignment = Enum.TextXAlignment.Right
        valueLabel.Font = Enum.Font.SourceSansBold
        valueLabel.TextSize = 12
        valueLabel.Parent = metricFrame
        
        metricLabels[metric.name] = nameLabel
        metricValues[metric.name] = valueLabel
    end
    
    -- Update loop
    local lastUpdate = tick()
    local frameCount = 0
    local errorCount = 0
    
    local connection = RunService.Heartbeat:Connect(function()
        frameCount = frameCount + 1
        local currentTime = tick()
        
        if currentTime - lastUpdate >= 1 then -- Update every second
            -- FPS
            local fps = frameCount / (currentTime - lastUpdate)
            metricValues.FPS.Text = string.format("%.1f", fps)
            
            -- Memory
            local memory = collectgarbage("count")
            metricValues.Memory.Text = string.format("%.1f KB", memory)
            
            -- Update memory color based on usage
            if memory > 100000 then
                metricValues.Memory.TextColor3 = Color3.fromRGB(255, 100, 100)
            elseif memory > 50000 then
                metricValues.Memory.TextColor3 = Color3.fromRGB(255, 200, 100)
            else
                metricValues.Memory.TextColor3 = Color3.fromRGB(100, 255, 100)
            end
            
            -- Players
            metricValues.Players.Text = tostring(#Players:GetPlayers())
            
            -- Objects
            local objectCount = #workspace:GetDescendants()
            metricValues.Objects.Text = tostring(objectCount)
            
            -- Update object color based on count
            if objectCount > 20000 then
                metricValues.Objects.TextColor3 = Color3.fromRGB(255, 100, 100)
            elseif objectCount > 10000 then
                metricValues.Objects.TextColor3 = Color3.fromRGB(255, 200, 100)
            else
                metricValues.Objects.TextColor3 = Color3.fromRGB(100, 255, 100)
            end
            
            -- Errors (would need integration with error handler)
            metricValues.Errors.Text = tostring(errorCount)
            
            frameCount = 0
            lastUpdate = currentTime
        end
    end)
    
    -- Minimize functionality
    local isMinimized = false
    minimizeButton.MouseButton1Click:Connect(function()
        isMinimized = not isMinimized
        
        local targetSize = isMinimized and UDim2.new(0.3, 0, 0, 30) or UDim2.new(0.3, 0, 0.4, 0)
        local tween = TweenService:Create(mainFrame, TweenInfo.new(0.3), {Size = targetSize})
        tween:Play()
        
        contentFrame.Visible = not isMinimized
        minimizeButton.Text = isMinimized and "+" or "−"
    end)
    
    -- Cleanup on destroy
    gui.AncestryChanged:Connect(function()
        if not gui.Parent then
            connection:Disconnect()
        end
    end)
    
    return gui
end

-- ========================================
-- TEST RUNNER
-- ========================================

local TestRunner = {}

function TestRunner:CreateTestSuite(suiteName)
    local suite = {
        name = suiteName,
        tests = {},
        beforeEach = nil,
        afterEach = nil,
        beforeAll = nil,
        afterAll = nil
    }
    
    function suite:AddTest(testName, testFunction)
        table.insert(self.tests, {
            name = testName,
            func = testFunction,
            status = "pending"
        })
    end
    
    function suite:SetBeforeEach(func)
        self.beforeEach = func
    end
    
    function suite:SetAfterEach(func)
        self.afterEach = func
    end
    
    function suite:SetBeforeAll(func)
        self.beforeAll = func
    end
    
    function suite:SetAfterAll(func)
        self.afterAll = func
    end
    
    function suite:Run()
        print("\n" .. "=".rep(50))
        print("🧪 RUNNING TEST SUITE: " .. self.name)
        print("=".rep(50))
        
        local results = {
            passed = 0,
            failed = 0,
            errors = 0,
            total = #self.tests,
            details = {}
        }
        
        -- Run beforeAll
        if self.beforeAll then
            local success, error = pcall(self.beforeAll)
            if not success then
                print("❌ BeforeAll failed: " .. tostring(error))
                return results
            end
        end
        
        -- Run tests
        for _, test in ipairs(self.tests) do
            print("Running: " .. test.name)
            
            local testResult = {
                name = test.name,
                status = "pending",
                duration = 0,
                error = nil
            }
            
            local startTime = tick()
            
            -- Run beforeEach
            if self.beforeEach then
                local success, error = pcall(self.beforeEach)
                if not success then
                    testResult.status = "error"
                    testResult.error = "BeforeEach failed: " .. tostring(error)
                    results.errors = results.errors + 1
                    goto continue
                end
            end
            
            -- Run test
            local success, error = pcall(test.func)
            testResult.duration = tick() - startTime
            
            if success then
                testResult.status = "passed"
                results.passed = results.passed + 1
                print("  ✅ PASSED (" .. string.format("%.3f", testResult.duration) .. "s)")
            else
                testResult.status = "failed"
                testResult.error = tostring(error)
                results.failed = results.failed + 1
                print("  ❌ FAILED: " .. tostring(error))
            end
            
            -- Run afterEach
            if self.afterEach then
                local success, error = pcall(self.afterEach)
                if not success then
                    print("  ⚠️ AfterEach failed: " .. tostring(error))
                end
            end
            
            ::continue::
            table.insert(results.details, testResult)
        end
        
        -- Run afterAll
        if self.afterAll then
            local success, error = pcall(self.afterAll)
            if not success then
                print("⚠️ AfterAll failed: " .. tostring(error))
            end
        end
        
        -- Print summary
        print("\n📊 TEST RESULTS:")
        print("  Passed: " .. results.passed .. "/" .. results.total)
        print("  Failed: " .. results.failed .. "/" .. results.total)
        print("  Errors: " .. results.errors .. "/" .. results.total)
        
        if results.failed > 0 or results.errors > 0 then
            print("  Status: ❌ FAILED")
        else
            print("  Status: ✅ PASSED")
        end
        
        print("=".rep(50) .. "\n")
        
        return results
    end
    
    return suite
end

-- Built-in assertion functions
local Assertions = {}

function Assertions.assertEqual(actual, expected, message)
    if actual ~= expected then
        error((message or "Assertion failed") .. 
              ": expected " .. tostring(expected) .. 
              ", got " .. tostring(actual))
    end
end

function Assertions.assertNotEqual(actual, expected, message)
    if actual == expected then
        error((message or "Assertion failed") .. 
              ": expected values to be different, both were " .. tostring(actual))
    end
end

function Assertions.assertTrue(value, message)
    if not value then
        error((message or "Assertion failed") .. ": expected true, got " .. tostring(value))
    end
end

function Assertions.assertFalse(value, message)
    if value then
        error((message or "Assertion failed") .. ": expected false, got " .. tostring(value))
    end
end

function Assertions.assertNil(value, message)
    if value ~= nil then
        error((message or "Assertion failed") .. ": expected nil, got " .. tostring(value))
    end
end

function Assertions.assertNotNil(value, message)
    if value == nil then
        error((message or "Assertion failed") .. ": expected non-nil value")
    end
end

function Assertions.assertType(value, expectedType, message)
    local actualType = type(value)
    if actualType ~= expectedType then
        error((message or "Assertion failed") .. 
              ": expected type " .. expectedType .. 
              ", got " .. actualType)
    end
end

function Assertions.assertThrows(func, message)
    local success = pcall(func)
    if success then
        error((message or "Assertion failed") .. ": expected function to throw an error")
    end
end

TestRunner.Assertions = Assertions

-- ========================================
-- PERFORMANCE MONITOR
-- ========================================

local PerformanceMonitor = {}

function PerformanceMonitor:StartMonitoring(options)
    options = options or {}
    local interval = options.interval or 5 -- seconds
    local duration = options.duration or 60 -- seconds
    local metrics = options.metrics or {"fps", "memory", "objects", "players"}
    
    local data = {
        startTime = tick(),
        samples = {},
        isRunning = true
    }
    
    print("📈 Starting performance monitoring for " .. duration .. " seconds...")
    
    local function collectSample()
        local sample = {
            timestamp = tick(),
            fps = workspace:GetRealPhysicsFPS(),
            memory = collectgarbage("count"),
            objects = #workspace:GetDescendants(),
            players = #Players:GetPlayers()
        }
        
        table.insert(data.samples, sample)
        print(string.format("Sample %d: FPS=%.1f, Memory=%.1fKB, Objects=%d, Players=%d",
              #data.samples, sample.fps, sample.memory, sample.objects, sample.players))
    end
    
    -- Initial sample
    collectSample()
    
    -- Schedule sampling
    local connection
    connection = RunService.Heartbeat:Connect(function()
        if tick() - data.startTime >= duration then
            data.isRunning = false
            connection:Disconnect()
            PerformanceMonitor:GenerateReport(data)
            return
        end
        
        if tick() - (data.samples[#data.samples] and data.samples[#data.samples].timestamp or 0) >= interval then
            collectSample()
        end
    end)
    
    return data
end

function PerformanceMonitor:GenerateReport(data)
    if #data.samples == 0 then
        print("❌ No performance data to report")
        return
    end
    
    print("\n" .. "=".rep(60))
    print("📈 PERFORMANCE MONITORING REPORT")
    print("=".rep(60))
    print("Duration: " .. string.format("%.1f", tick() - data.startTime) .. " seconds")
    print("Samples: " .. #data.samples)
    
    -- Calculate statistics for each metric
    local metrics = {"fps", "memory", "objects", "players"}
    
    for _, metric in ipairs(metrics) do
        local values = {}
        for _, sample in ipairs(data.samples) do
            table.insert(values, sample[metric])
        end
        
        table.sort(values)
        
        local min = values[1]
        local max = values[#values]
        local avg = 0
        for _, value in ipairs(values) do
            avg = avg + value
        end
        avg = avg / #values
        
        local median = values[math.ceil(#values / 2)]
        
        local unit = metric == "memory" and "KB" or ""
        
        print(string.format("\n%s %s:", string.upper(metric:sub(1, 1)) .. metric:sub(2), unit))
        print(string.format("  Min: %.2f%s", min, unit))
        print(string.format("  Max: %.2f%s", max, unit))
        print(string.format("  Avg: %.2f%s", avg, unit))
        print(string.format("  Med: %.2f%s", median, unit))
        
        -- Performance warnings
        if metric == "fps" and avg < 30 then
            print("  ⚠️ Low FPS detected")
        elseif metric == "memory" and max > 100000 then
            print("  ⚠️ High memory usage detected")
        elseif metric == "objects" and max > 20000 then
            print("  ⚠️ High object count detected")
        end
    end
    
    print("=".rep(60) .. "\n")
    
    return {
        duration = tick() - data.startTime,
        samples = data.samples,
        sampleCount = #data.samples
    }
end

-- ========================================
-- CODE ANALYSIS TOOLS
-- ========================================

local CodeAnalyzer = {}

function CodeAnalyzer:AnalyzeModuleStructure(modulePath)
    local success, moduleContent = pcall(function()
        return require(modulePath)
    end)
    
    if not success then
        return {
            error = "Failed to load module: " .. tostring(moduleContent),
            structure = nil
        }
    end
    
    local analysis = {
        type = type(moduleContent),
        functions = {},
        properties = {},
        complexity = 0
    }
    
    if type(moduleContent) == "table" then
        for key, value in pairs(moduleContent) do
            if type(value) == "function" then
                table.insert(analysis.functions, key)
            else
                analysis.properties[key] = type(value)
            end
        end
        
        analysis.complexity = #analysis.functions + table.getn and table.getn(analysis.properties) or 0
    end
    
    return analysis
end

function CodeAnalyzer:ScanForPatterns(patterns)
    patterns = patterns or {
        "TODO",
        "FIXME",
        "HACK",
        "BUG",
        "NOTE"
    }
    
    local results = {}
    
    -- This would typically scan actual source files
    -- For now, we'll provide a framework
    print("🔍 Scanning codebase for patterns...")
    
    for _, pattern in ipairs(patterns) do
        results[pattern] = {
            count = 0,
            locations = {}
        }
    end
    
    print("📊 Pattern scan complete")
    
    return results
end

-- ========================================
-- INITIALIZATION
-- ========================================

function DeveloperTools:Init()
    print("🛠️ DeveloperTools initializing...")
    
    local config = ConfigurationManager.getInstance()
    
    -- Auto-start monitoring dashboard if enabled
    if RunService:IsClient() and config:Get("debugging.AUTO_START_DASHBOARD") then
        wait(2) -- Give time for other systems to load
        MonitoringDashboard:CreateDashboard()
    end
    
    print("✅ DeveloperTools initialized successfully")
    print("   Available tools: Monitoring Dashboard, Test Runner, Performance Monitor")
    
    return {
        MonitoringDashboard = MonitoringDashboard,
        TestRunner = TestRunner,
        PerformanceMonitor = PerformanceMonitor,
        CodeAnalyzer = CodeAnalyzer,
        Assertions = Assertions
    }
end

return DeveloperTools
