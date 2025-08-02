-- DebugUtilities.luau
-- Comprehensive debugging utilities and developer tools for troubleshooting
-- Provides advanced debugging capabilities, performance profiling, and system inspection

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local HttpService = game:GetService("HttpService")
local UserInputService = game:GetService("UserInputService")
local ConfigurationManager = require(ReplicatedStorage.Shared.core.ConfigurationManager)

local DebugUtilities = {}

-- Helper function to repeat strings (Luau doesn't have string.rep)
local function repeatString(str, count)
    local result = ""
    for _ = 1, count do
        result = result .. str
    end
    return result
end

-- ========================================
-- DEBUG MODES AND CONFIGURATION
-- ========================================

local _DEBUG_MODES = {
    PERFORMANCE = "performance",
    MEMORY = "memory",
    NETWORK = "network",
    ERRORS = "errors",
    EVENTS = "events",
    SYSTEM = "system"
}

local activeDebugModes = {}
local _debugSessions = {}
local performanceProfiles = {}
local memorySnapshots = {}
local _networkTraces = {}

-- Configuration
local config = ConfigurationManager.getInstance()

-- ========================================
-- PERFORMANCE PROFILING
-- ========================================

-- Performance profiler for measuring execution times
local PerformanceProfiler = {}

function PerformanceProfiler:StartProfile(profileName)
    if not performanceProfiles[profileName] then
        performanceProfiles[profileName] = {
            name = profileName,
            sessions = {},
            stats = {
                totalCalls = 0,
                totalTime = 0,
                averageTime = 0,
                minTime = math.huge,
                maxTime = 0
            }
        }
    end
    
    local session = {
        id = HttpService:GenerateGUID(false),
        startTime = tick(),
        endTime = nil,
        duration = nil,
        memoryStart = collectgarbage("count"),
        memoryEnd = nil,
        memoryUsed = nil
    }
    
    table.insert(performanceProfiles[profileName].sessions, session)
    return session.id
end

function PerformanceProfiler:EndProfile(profileName, sessionId)
    local profile = performanceProfiles[profileName]
    if not profile then
        warn("❌ Profile '" .. profileName .. "' not found")
        return nil
    end
    
    local session = nil
    for _, s in ipairs(profile.sessions) do
        if s.id == sessionId then
            session = s
            break
        end
    end
    
    if not session then
        warn("❌ Profile session '" .. sessionId .. "' not found")
        return nil
    end
    
    -- Complete session measurements
    session.endTime = tick()
    session.duration = session.endTime - session.startTime
    session.memoryEnd = collectgarbage("count")
    session.memoryUsed = session.memoryEnd - session.memoryStart
    
    -- Update statistics
    local stats = profile.stats
    stats.totalCalls = stats.totalCalls + 1
    stats.totalTime = stats.totalTime + session.duration
    stats.averageTime = stats.totalTime / stats.totalCalls
    
    if session.duration < stats.minTime then
        stats.minTime = session.duration
    end
    
    if session.duration > stats.maxTime then
        stats.maxTime = session.duration
    end
    
    return session
end

function PerformanceProfiler:GetProfile(profileName)
    return performanceProfiles[profileName]
end

function PerformanceProfiler:GetAllProfiles()
    return performanceProfiles
end

function PerformanceProfiler:ClearProfile(profileName)
    performanceProfiles[profileName] = nil
end

function PerformanceProfiler:PrintProfileReport(profileName)
    local profile = performanceProfiles[profileName]
    if not profile then
        print("❌ Profile '" .. profileName .. "' not found")
        return
    end
    
    local stats = profile.stats
    print("\n" .. repeatString("=", 50))
    print("📊 PERFORMANCE PROFILE: " .. profileName)
    print(repeatString("=", 50))
    print("Total Calls: " .. stats.totalCalls)
    print("Total Time: " .. string.format("%.4f", stats.totalTime) .. "s")
    print("Average Time: " .. string.format("%.4f", stats.averageTime) .. "s")
    print("Min Time: " .. string.format("%.4f", stats.minTime) .. "s")
    print("Max Time: " .. string.format("%.4f", stats.maxTime) .. "s")
    
    -- Show recent sessions
    print("\nRecent Sessions:")
    local recentCount = math.min(5, #profile.sessions)
    for i = #profile.sessions - recentCount + 1, #profile.sessions do
        local session = profile.sessions[i]
        if session.duration then
            print(string.format("  %s: %.4fs (%.2fKB memory)",
                session.id:sub(1, 8),
                session.duration,
                session.memoryUsed or 0
            ))
        end
    end
    print(repeatString("=", 50) .. "\n")
end

-- ========================================
-- MEMORY DEBUGGING
-- ========================================

-- Memory snapshot and leak detection
local MemoryDebugger = {}

function MemoryDebugger:TakeSnapshot(snapshotName)
    local snapshot = {
        name = snapshotName or "snapshot_" .. tick(),
        timestamp = tick(),
        memory = collectgarbage("count"),
        objects = {},
        services = {},
        players = #Players:GetPlayers()
    }
    
    -- Count instances by type
    for _, obj in ipairs(workspace:GetDescendants()) do
        local className = obj.ClassName
        snapshot.objects[className] = (snapshot.objects[className] or 0) + 1
    end
    
    -- Count ReplicatedStorage objects
    for _, obj in ipairs(ReplicatedStorage:GetDescendants()) do
        local className = obj.ClassName
        snapshot.objects[className] = (snapshot.objects[className] or 0) + 1
    end
    
    memorySnapshots[snapshot.name] = snapshot
    print("📸 Memory snapshot '" .. snapshot.name .. "' taken (" .. 
          string.format("%.2f", snapshot.memory) .. "KB)")
    
    return snapshot
end

function MemoryDebugger:CompareSnapshots(snapshot1Name, snapshot2Name)
    local s1 = memorySnapshots[snapshot1Name]
    local s2 = memorySnapshots[snapshot2Name]
    
    if not s1 or not s2 then
        warn("❌ One or both snapshots not found")
        return nil
    end
    
    local comparison = {
        memoryDiff = s2.memory - s1.memory,
        timeDiff = s2.timestamp - s1.timestamp,
        objectChanges = {},
        significantChanges = {}
    }
    
    -- Compare object counts
    local allClasses = {}
    for className, _ in pairs(s1.objects) do
        allClasses[className] = true
    end
    for className, _ in pairs(s2.objects) do
        allClasses[className] = true
    end
    
    for className, _ in pairs(allClasses) do
        local count1 = s1.objects[className] or 0
        local count2 = s2.objects[className] or 0
        local diff = count2 - count1
        
        comparison.objectChanges[className] = diff
        
        -- Mark significant changes (>10 objects or >50% increase)
        if math.abs(diff) > 10 or (count1 > 0 and math.abs(diff / count1) > 0.5) then
            comparison.significantChanges[className] = diff
        end
    end
    
    return comparison
end

function MemoryDebugger:PrintMemoryReport()
    local currentMemory = collectgarbage("count")
    
    print("\n" .. repeatString("=", 50))
    print("🧠 MEMORY DEBUG REPORT")
    print(repeatString("=", 50))
    print("Current Memory: " .. string.format("%.2f", currentMemory) .. "KB")
    print("Available Snapshots: " .. tostring(#memorySnapshots))
    
    -- Show object counts
    local objectCounts = {}
    for _, obj in ipairs(workspace:GetDescendants()) do
        local className = obj.ClassName
        objectCounts[className] = (objectCounts[className] or 0) + 1
    end
    
    print("\nTop Object Types:")
    local sortedObjects = {}
    for className, count in pairs(objectCounts) do
        table.insert(sortedObjects, {className = className, count = count})
    end
    
    table.sort(sortedObjects, function(a, b) return a.count > b.count end)
    
    for i = 1, math.min(10, #sortedObjects) do
        local obj = sortedObjects[i]
        print("  " .. obj.className .. ": " .. obj.count)
    end
    
    print(repeatString("=", 50) .. "\n")
end

function MemoryDebugger:DetectMemoryLeaks()
    print("🔍 Detecting potential memory leaks...")
    
    local suspiciousPatterns = {}
    
    -- Check for excessive instances of certain types
    local instanceCounts = {}
    for _, obj in ipairs(workspace:GetDescendants()) do
        local className = obj.ClassName
        instanceCounts[className] = (instanceCounts[className] or 0) + 1
    end
    
    for className, count in pairs(instanceCounts) do
        if count > 1000 then -- Threshold for suspicious count
            table.insert(suspiciousPatterns, {
                type = "excessive_instances",
                className = className,
                count = count,
                severity = count > 5000 and "HIGH" or "MEDIUM"
            })
        end
    end
    
    -- Check memory growth rate
    if #memorySnapshots >= 2 then
        local snapshots = {}
        for _, snapshot in pairs(memorySnapshots) do
            table.insert(snapshots, snapshot)
        end
        
        table.sort(snapshots, function(a, b) return a.timestamp < b.timestamp end)
        
        if #snapshots >= 2 then
            local latest = snapshots[#snapshots]
            local previous = snapshots[#snapshots - 1]
            local growthRate = (latest.memory - previous.memory) / (latest.timestamp - previous.timestamp)
            
            if growthRate > 10 then -- 10KB/s growth rate threshold
                table.insert(suspiciousPatterns, {
                    type = "memory_growth",
                    growthRate = growthRate,
                    severity = growthRate > 50 and "HIGH" or "MEDIUM"
                })
            end
        end
    end
    
    -- Report findings
    if #suspiciousPatterns > 0 then
        print("⚠️ Potential memory leaks detected:")
        for _, pattern in ipairs(suspiciousPatterns) do
            if pattern.type == "excessive_instances" then
                print("  " .. pattern.severity .. ": " .. pattern.count .. " " .. pattern.className .. " instances")
            elseif pattern.type == "memory_growth" then
                print("  " .. pattern.severity .. ": Memory growing at " .. 
                      string.format("%.2f", pattern.growthRate) .. "KB/s")
            end
        end
    else
        print("✅ No obvious memory leaks detected")
    end
    
    return suspiciousPatterns
end

-- ========================================
-- SYSTEM INSPECTION
-- ========================================

-- System inspector for examining game state
local SystemInspector = {}

function SystemInspector:InspectServices()
    local services = {
        "Workspace",
        "Players",
        "ReplicatedStorage",
        "ReplicatedFirst",
        "StarterGui",
        "StarterPack",
        "StarterPlayer",
        "Lighting",
        "SoundService",
        "TweenService"
    }
    
    print("\n" .. repeatString("=", 50))
    print("🔧 SERVICES INSPECTION")
    print(repeatString("=", 50))
    
    for _, serviceName in ipairs(services) do
        local success, service = pcall(function() return game:GetService(serviceName) end)
        if success and service then
            local childCount = #service:GetChildren()
            local descendantCount = #service:GetDescendants()
            print(string.format("%-20s: %d children, %d descendants", 
                  serviceName, childCount, descendantCount))
        else
            print(string.format("%-20s: ❌ Error accessing service", serviceName))
        end
    end
    
    print(repeatString("=", 50) .. "\n")
end

function SystemInspector:InspectPerformance()
    print("\n" .. repeatString("=", 50))
    print("⚡ PERFORMANCE INSPECTION")
    print(repeatString("=", 50))
    
    -- FPS and timing
    print("Physics FPS: " .. string.format("%.1f", workspace:GetRealPhysicsFPS()))
    if RunService:IsClient() then
        print("Render FPS: " .. string.format("%.1f", 1 / RunService.RenderStepped:Wait()))
    end
    
    -- Memory
    print("Memory Usage: " .. string.format("%.2f", collectgarbage("count")) .. "KB")
    
    -- Player count
    if RunService:IsServer() then
        print("Players: " .. #Players:GetPlayers() .. "/" .. Players.MaxPlayers)
    end
    
    -- DataModel stats
    local totalObjects = #workspace:GetDescendants()
    print("Total Objects: " .. totalObjects)
    
    if totalObjects > 10000 then
        print("⚠️ High object count - may impact performance")
    end
    
    print(repeatString("=", 50) .. "\n")
end

function SystemInspector:InspectNetworking()
    if not RunService:IsServer() then
        print("ℹ️ Network inspection only available on server")
        return
    end
    
    print("\n" .. repeatString("=", 50))
    print("🌐 NETWORKING INSPECTION")
    print(repeatString("=", 50))
    
    -- Player connections
    local players = Players:GetPlayers()
    print("Connected Players: " .. #players)
    
    for _, player in ipairs(players) do
        if player.Character then
            print("  " .. player.Name .. ": Character loaded")
        else
            print("  " .. player.Name .. ": No character")
        end
    end
    
    -- Remote events and functions
    local remoteEvents = 0
    local remoteFunctions = 0
    
    for _, obj in ipairs(ReplicatedStorage:GetDescendants()) do
        if obj:IsA("RemoteEvent") then
            remoteEvents = remoteEvents + 1
        elseif obj:IsA("RemoteFunction") then
            remoteFunctions = remoteFunctions + 1
        end
    end
    
    print("Remote Events: " .. remoteEvents)
    print("Remote Functions: " .. remoteFunctions)
    
    print(repeatString("=", 50) .. "\n")
end

-- ========================================
-- ERROR DEBUGGING
-- ========================================

-- Error context collector for debugging
local ErrorDebugger = {}

function ErrorDebugger:CaptureErrorContext(error, additionalContext)
    local context = {
        error = error,
        timestamp = tick(),
        stackTrace = debug.traceback(),
        memory = collectgarbage("count"),
        playerCount = #Players:GetPlayers(),
        additionalContext = additionalContext or {}
    }
    
    -- Add system state
    context.systemState = {
        fps = workspace:GetRealPhysicsFPS(),
        gameId = game.PlaceId,
        serverId = game.JobId,
        version = game.PlaceVersion
    }
    
    -- Add recent logs if StructuredLogger is available
    local success, logger = pcall(function()
        return require(ReplicatedStorage.Shared.services.StructuredLogger)
    end)
    
    if success and logger.GetRecentLogs then
        context.recentLogs = logger:GetRecentLogs(5)
    end
    
    return context
end

function ErrorDebugger:AnalyzeError(errorContext)
    local analysis = {
        severity = "MEDIUM",
        category = "UNKNOWN",
        recommendations = {}
    }
    
    local errorMessage = tostring(errorContext.error):lower()
    
    -- Analyze error type
    if errorMessage:find("memory") or errorMessage:find("out of memory") then
        analysis.category = "MEMORY"
        analysis.severity = "HIGH"
        table.insert(analysis.recommendations, "Check for memory leaks")
        table.insert(analysis.recommendations, "Reduce object count")
    elseif errorMessage:find("stack overflow") then
        analysis.category = "LOGIC"
        analysis.severity = "HIGH"
        table.insert(analysis.recommendations, "Check for infinite recursion")
    elseif errorMessage:find("nil") or errorMessage:find("attempt to index") then
        analysis.category = "LOGIC"
        analysis.severity = "MEDIUM"
        table.insert(analysis.recommendations, "Add nil checks")
        table.insert(analysis.recommendations, "Verify object initialization")
    elseif errorMessage:find("network") or errorMessage:find("http") then
        analysis.category = "NETWORK"
        analysis.severity = "MEDIUM"
        table.insert(analysis.recommendations, "Check network connectivity")
        table.insert(analysis.recommendations, "Add retry logic")
    end
    
    -- Analyze system state
    if errorContext.memory > 100000 then -- 100MB
        analysis.severity = "HIGH"
        table.insert(analysis.recommendations, "Memory usage is very high")
    end
    
    if errorContext.systemState.fps < 30 then
        table.insert(analysis.recommendations, "Performance is degraded")
    end
    
    return analysis
end

-- ========================================
-- INTERACTIVE DEBUGGING
-- ========================================

-- Interactive debug console (client-side only)
local DebugConsole = {}

function DebugConsole:CreateDebugConsole()
    if RunService:IsServer() then
        print("ℹ️ Debug console only available on client")
        return
    end
    
    local gui = Instance.new("ScreenGui")
    gui.Name = "DebugConsole"
    gui.ResetOnSpawn = false
    gui.Parent = Players.LocalPlayer:WaitForChild("PlayerGui")
    
    local frame = Instance.new("Frame")
    frame.Name = "ConsoleFrame"
    frame.Size = UDim2.new(0.8, 0, 0.6, 0)
    frame.Position = UDim2.new(0.1, 0, 0.2, 0)
    frame.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
    frame.BorderSizePixel = 0
    frame.Parent = gui
    
    -- Title bar
    local titleBar = Instance.new("Frame")
    titleBar.Name = "TitleBar"
    titleBar.Size = UDim2.new(1, 0, 0, 30)
    titleBar.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
    titleBar.BorderSizePixel = 0
    titleBar.Parent = frame
    
    local titleLabel = Instance.new("TextLabel")
    titleLabel.Text = "🐛 Debug Console"
    titleLabel.Size = UDim2.new(1, -60, 1, 0)
    titleLabel.Position = UDim2.new(0, 10, 0, 0)
    titleLabel.BackgroundTransparency = 1
    titleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    titleLabel.TextXAlignment = Enum.TextXAlignment.Left
    titleLabel.Font = Enum.Font.SourceSansBold
    titleLabel.TextSize = 14
    titleLabel.Parent = titleBar
    
    -- Close button
    local closeButton = Instance.new("TextButton")
    closeButton.Text = "✕"
    closeButton.Size = UDim2.new(0, 30, 1, 0)
    closeButton.Position = UDim2.new(1, -30, 0, 0)
    closeButton.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
    closeButton.BorderSizePixel = 0
    closeButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    closeButton.Font = Enum.Font.SourceSansBold
    closeButton.TextSize = 16
    closeButton.Parent = titleBar
    
    closeButton.MouseButton1Click:Connect(function()
        gui:Destroy()
    end)
    
    -- Output area
    local outputFrame = Instance.new("ScrollingFrame")
    outputFrame.Name = "OutputFrame"
    outputFrame.Size = UDim2.new(1, -20, 1, -80)
    outputFrame.Position = UDim2.new(0, 10, 0, 40)
    outputFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
    outputFrame.BorderSizePixel = 0
    outputFrame.ScrollBarThickness = 8
    outputFrame.Parent = frame
    
    -- Input area
    local inputBox = Instance.new("TextBox")
    inputBox.Name = "InputBox"
    inputBox.Size = UDim2.new(1, -20, 0, 30)
    inputBox.Position = UDim2.new(0, 10, 1, -40)
    inputBox.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
    inputBox.BorderSizePixel = 0
    inputBox.TextColor3 = Color3.fromRGB(255, 255, 255)
    inputBox.PlaceholderText = "Enter debug command..."
    inputBox.Font = Enum.Font.SourceSans
    inputBox.TextSize = 14
    inputBox.TextXAlignment = Enum.TextXAlignment.Left
    inputBox.ClearTextOnFocus = false
    inputBox.Parent = frame
    
    -- Console functionality
    local outputLines = {}
    
    local function addOutput(text, color)
        color = color or Color3.fromRGB(255, 255, 255)
        
        local outputLabel = Instance.new("TextLabel")
        outputLabel.Text = text
        outputLabel.Size = UDim2.new(1, -10, 0, 20)
        outputLabel.Position = UDim2.new(0, 5, 0, #outputLines * 20)
        outputLabel.BackgroundTransparency = 1
        outputLabel.TextColor3 = color
        outputLabel.TextXAlignment = Enum.TextXAlignment.Left
        outputLabel.Font = Enum.Font.SourceSans
        outputLabel.TextSize = 12
        outputLabel.TextWrapped = true
        outputLabel.Parent = outputFrame
        
        table.insert(outputLines, outputLabel)
        
        -- Update canvas size
        outputFrame.CanvasSize = UDim2.new(0, 0, 0, #outputLines * 20)
        outputFrame.CanvasPosition = Vector2.new(0, outputFrame.CanvasSize.Y.Offset)
    end
    
    local function executeCommand(command)
        addOutput("> " .. command, Color3.fromRGB(100, 200, 100))
        
        if command == "help" then
            addOutput("Available commands:")
            addOutput("  help - Show this help")
            addOutput("  memory - Show memory info")
            addOutput("  performance - Show performance info")
            addOutput("  services - Inspect services")
            addOutput("  clear - Clear console")
        elseif command == "memory" then
            addOutput("Memory: " .. string.format("%.2f", collectgarbage("count")) .. "KB")
        elseif command == "performance" then
            addOutput("Physics FPS: " .. string.format("%.1f", workspace:GetRealPhysicsFPS()))
        elseif command == "services" then
            SystemInspector:InspectServices()
        elseif command == "clear" then
            for _, label in ipairs(outputLines) do
                label:Destroy()
            end
            outputLines = {}
            outputFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
        else
            addOutput("Unknown command: " .. command, Color3.fromRGB(255, 100, 100))
        end
    end
    
    inputBox.FocusLost:Connect(function(enterPressed)
        if enterPressed and inputBox.Text ~= "" then
            executeCommand(inputBox.Text)
            inputBox.Text = ""
        end
    end)
    
    addOutput("🐛 Debug Console Ready - Type 'help' for commands")
    
    return gui
end

-- ========================================
-- TRACE UTILITIES
-- ========================================

-- Function call tracer
local FunctionTracer = {}

function FunctionTracer:TraceFunction(func, funcName)
    return function(...)
        local args = {...}
        print("📞 CALL: " .. funcName .. "(" .. table.concat(args, ", ") .. ")")
        
        local startTime = tick()
        local results = {func(...)}
        local duration = tick() - startTime
        
        print("📤 RETURN: " .. funcName .. " -> " .. table.concat(results, ", ") .. 
              " (took " .. string.format("%.4f", duration) .. "s)")
        
        return unpack(results)
    end
end

-- ========================================
-- INITIALIZATION
-- ========================================

function DebugUtilities:Init()
    print("🐛 DebugUtilities initializing...")
    
    -- Enable debug modes based on configuration
    local enabledModes = config:Get("debugging.ENABLED_MODES") or {}
    for _, mode in ipairs(enabledModes) do
        activeDebugModes[mode] = true
    end
    
    -- Setup keyboard shortcuts for debug console (client only)
    if RunService:IsClient() and config:Get("debugging.ENABLE_CONSOLE_HOTKEY") then
        UserInputService.InputBegan:Connect(function(input, gameProcessed)
            if not gameProcessed and input.KeyCode == Enum.KeyCode.F9 then
                DebugConsole:CreateDebugConsole()
            end
        end)
    end
    
    print("✅ DebugUtilities initialized successfully")
    print("   Available tools: Performance Profiler, Memory Debugger, System Inspector")
    if RunService:IsClient() then
        print("   Press F9 to open debug console")
    end
    
    return {
        PerformanceProfiler = PerformanceProfiler,
        MemoryDebugger = MemoryDebugger,
        SystemInspector = SystemInspector,
        ErrorDebugger = ErrorDebugger,
        DebugConsole = DebugConsole,
        FunctionTracer = FunctionTracer
    }
end

return DebugUtilities
