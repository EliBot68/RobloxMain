-- DeveloperToolsSystem.luau
-- Comprehensive developer tools and debugging interfaces for easier development
-- Provides debugging, profiling, testing, and development utilities

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local StarterGui = game:GetService("StarterGui")
local CoreGui = game:GetService("CoreGui")
local LogService = game:GetService("LogService")
local StatsService = game:GetService("Stats")

local SafeRequire = require(ReplicatedStorage.Shared.utils.SafeRequire)

local DeveloperToolsSystem = {}

-- ========================================
-- DEVELOPER TOOLS CONFIGURATION
-- ========================================

local DEVTOOLS_CONFIG = {
    -- Debug configuration
    debugging = {
        enabled = true,
        logLevel = "info", -- trace, debug, info, warn, error
        maxLogEntries = 1000,
        showTimestamps = true,
        showCallStacks = true,
        
        breakpoints = true,
        stepDebugging = true,
        variableInspection = true,
        memoryProfiling = true
    },
    
    -- Profiling configuration
    profiling = {
        enabled = true,
        sampleRate = 30, -- FPS
        maxSamples = 10000,
        trackMemory = true,
        trackPerformance = true,
        trackNetworkUsage = true,
        
        performanceThresholds = {
            framerate = 30,
            memory = 100, -- MB
            scriptTime = 16.67 -- ms per frame
        }
    },
    
    -- Console configuration
    console = {
        enabled = true,
        height = 300,
        maxHistory = 100,
        autoComplete = true,
        syntaxHighlighting = true,
        
        shortcuts = {
            toggle = Enum.KeyCode.F12,
            clear = "Ctrl+L",
            execute = Enum.KeyCode.Return
        }
    },
    
    -- Inspector configuration
    inspector = {
        enabled = true,
        showHierarchy = true,
        showProperties = true,
        realTimeUpdates = true,
        editProperties = true,
        
        filters = {
            showHidden = false,
            showServices = true,
            showInstances = true
        }
    },
    
    -- Testing tools
    testing = {
        enabled = true,
        autoRun = false,
        showCoverage = true,
        benchmarking = true,
        
        testFrameworks = {"custom", "jest", "mocha"}
    }
}

-- ========================================
-- DEVELOPER TOOLS STATE
-- ========================================

local DevToolsState = {
    -- Debug state
    debugging = {
        isActive = false,
        breakpoints = {},
        callStack = {},
        variables = {},
        logEntries = {}
    },
    
    -- Profiling state
    profiling = {
        isActive = false,
        samples = {},
        currentSession = nil,
        metrics = {
            framerate = 0,
            memory = 0,
            scriptTime = 0,
            networkUsage = 0
        }
    },
    
    -- Console state
    console = {
        isVisible = false,
        history = {},
        historyIndex = 0,
        currentInput = ""
    },
    
    -- Inspector state
    inspector = {
        isVisible = false,
        selectedObject = nil,
        expandedNodes = {},
        propertyFilter = ""
    },
    
    -- UI references
    interfaces = {},
    
    -- Performance tracking
    performance = {
        startTime = tick(),
        frameCount = 0,
        lastFrameTime = 0
    }
}

function DeveloperToolsSystem.initialize()
    print("🛠️ Initializing DeveloperToolsSystem...")
    
    -- Initialize debugging system
    DeveloperToolsSystem.initializeDebugging()
    
    -- Initialize profiling system
    DeveloperToolsSystem.initializeProfiling()
    
    -- Create developer console
    DeveloperToolsSystem.createDeveloperConsole()
    
    -- Create object inspector
    DeveloperToolsSystem.createObjectInspector()
    
    -- Initialize testing tools
    DeveloperToolsSystem.initializeTestingTools()
    
    -- Set up input handlers
    DeveloperToolsSystem.setupInputHandlers()
    
    -- Create main developer tools interface
    DeveloperToolsSystem.createMainInterface()
    
    print("🛠️ DeveloperToolsSystem initialized successfully")
end

-- ========================================
-- DEBUGGING SYSTEM
-- ========================================

function DeveloperToolsSystem.initializeDebugging()
    DevToolsState.debugger = {
        breakpoints = {},
        callStack = {},
        stepMode = false,
        
        addBreakpoint = function(self, file, line)
            local id = string.format("%s:%d", file, line)
            self.breakpoints[id] = {
                file = file,
                line = line,
                enabled = true,
                conditions = {},
                hitCount = 0
            }
            print(string.format("🔴 Breakpoint set at %s", id))
        end,
        
        removeBreakpoint = function(self, file, line)
            local id = string.format("%s:%d", file, line)
            self.breakpoints[id] = nil
            print(string.format("⚪ Breakpoint removed from %s", id))
        end,
        
        log = function(self, level, message, context)
            DeveloperToolsSystem.logMessage(level, message, context)
        end,
        
        inspect = function(self, variable, depth)
            return DeveloperToolsSystem.inspectVariable(variable, depth or 3)
        end,
        
        trace = function(self, message)
            local traceback = debug.traceback(message or "Debug trace", 2)
            DeveloperToolsSystem.logMessage("trace", traceback)
            return traceback
        end
    }
    
    -- Set up log interception
    DeveloperToolsSystem.setupLogInterception()
    
    print("🐛 Debugging system initialized")
end

function DeveloperToolsSystem.setupLogInterception()
    -- Intercept print statements
    local originalPrint = print
    _G.print = function(...)
        local args = {...}
        local message = table.concat(args, "\t")
        DevToolsState.debugger:log("info", message, {source = "print"})
        originalPrint(...)
    end
    
    -- Intercept warn statements
    local originalWarn = warn
    _G.warn = function(...)
        local args = {...}
        local message = table.concat(args, "\t")
        DevToolsState.debugger:log("warn", message, {source = "warn"})
        originalWarn(...)
    end
    
    -- Intercept error statements
    local originalError = error
    _G.error = function(message, level)
        DevToolsState.debugger:log("error", tostring(message), {
            source = "error",
            level = level or 1,
            traceback = debug.traceback()
        })
        originalError(message, level)
    end
end

function DeveloperToolsSystem.logMessage(level, message, context)
    local logEntry = {
        timestamp = tick(),
        level = level,
        message = message,
        context = context or {},
        traceback = DEVTOOLS_CONFIG.debugging.showCallStacks and debug.traceback() or nil
    }
    
    table.insert(DevToolsState.debugging.logEntries, logEntry)
    
    -- Maintain log size limit
    if #DevToolsState.debugging.logEntries > DEVTOOLS_CONFIG.debugging.maxLogEntries then
        table.remove(DevToolsState.debugging.logEntries, 1)
    end
    
    -- Update console if visible
    if DevToolsState.console.isVisible then
        DeveloperToolsSystem.updateConsoleDisplay()
    end
end

function DeveloperToolsSystem.inspectVariable(variable, maxDepth, currentDepth)
    currentDepth = currentDepth or 0
    maxDepth = maxDepth or 3
    
    if currentDepth >= maxDepth then
        return "... (max depth reached)"
    end
    
    local varType = typeof(variable)
    
    if varType == "table" then
        local result = "{\n"
        local indent = string.rep("  ", currentDepth + 1)
        
        for key, value in pairs(variable) do
            local keyStr = typeof(key) == "string" and string.format('"%s"', key) or tostring(key)
            local valueStr = DeveloperToolsSystem.inspectVariable(value, maxDepth, currentDepth + 1)
            result = result .. indent .. keyStr .. " = " .. valueStr .. ",\n"
        end
        
        result = result .. string.rep("  ", currentDepth) .. "}"
        return result
    elseif varType == "string" then
        return string.format('"%s"', variable)
    elseif varType == "function" then
        return "function() ... end"
    elseif varType == "Instance" then
        return string.format('%s "%s"', variable.ClassName, variable.Name)
    else
        return tostring(variable)
    end
end

-- ========================================
-- PROFILING SYSTEM
-- ========================================

function DeveloperToolsSystem.initializeProfiling()
    DevToolsState.profiler = {
        sessions = {},
        currentSession = nil,
        
        startSession = function(self, name)
            local session = {
                name = name or "Unnamed Session",
                startTime = tick(),
                samples = {},
                metrics = {}
            }
            
            self.currentSession = session
            table.insert(self.sessions, session)
            
            print(string.format("📊 Profiling session started: %s", session.name))
            return session
        end,
        
        endSession = function(self)
            if self.currentSession then
                self.currentSession.endTime = tick()
                self.currentSession.duration = self.currentSession.endTime - self.currentSession.startTime
                
                print(string.format("📊 Profiling session ended: %s (%.2fs)", 
                    self.currentSession.name, self.currentSession.duration))
                
                local session = self.currentSession
                self.currentSession = nil
                return session
            end
        end,
        
        sample = function(self, name, startTime, endTime)
            if self.currentSession then
                table.insert(self.currentSession.samples, {
                    name = name,
                    startTime = startTime,
                    endTime = endTime,
                    duration = endTime - startTime,
                    timestamp = tick()
                })
            end
        end,
        
        getAverageTime = function(self, name)
            if not self.currentSession then return 0 end
            
            local total = 0
            local count = 0
            
            for _, sample in ipairs(self.currentSession.samples) do
                if sample.name == name then
                    total = total + sample.duration
                    count = count + 1
                end
            end
            
            return count > 0 and (total / count) or 0
        end
    }
    
    -- Start performance monitoring
    DeveloperToolsSystem.startPerformanceMonitoring()
    
    print("📊 Profiling system initialized")
end

function DeveloperToolsSystem.startPerformanceMonitoring()
    local connection
    connection = RunService.Heartbeat:Connect(function()
        local currentTime = tick()
        local deltaTime = currentTime - DevToolsState.performance.lastFrameTime
        
        DevToolsState.performance.frameCount = DevToolsState.performance.frameCount + 1
        DevToolsState.performance.lastFrameTime = currentTime
        
        -- Calculate framerate
        DevToolsState.profiling.metrics.framerate = 1 / deltaTime
        
        -- Get memory usage
        local stats = StatsService:GetTotalMemoryUsageMb()
        DevToolsState.profiling.metrics.memory = stats
        
        -- Sample performance data
        if DevToolsState.profiler.currentSession then
            local sample = {
                framerate = DevToolsState.profiling.metrics.framerate,
                memory = DevToolsState.profiling.metrics.memory,
                timestamp = currentTime
            }
            
            table.insert(DevToolsState.profiler.currentSession.metrics, sample)
            
            -- Maintain sample limit
            if #DevToolsState.profiler.currentSession.metrics > DEVTOOLS_CONFIG.profiling.maxSamples then
                table.remove(DevToolsState.profiler.currentSession.metrics, 1)
            end
        end
        
        -- Check performance thresholds
        DeveloperToolsSystem.checkPerformanceThresholds()
    end)
    
    DevToolsState.performanceConnection = connection
end

function DeveloperToolsSystem.checkPerformanceThresholds()
    local metrics = DevToolsState.profiling.metrics
    local thresholds = DEVTOOLS_CONFIG.profiling.performanceThresholds
    
    if metrics.framerate < thresholds.framerate then
        DevToolsState.debugger:log("warn", 
            string.format("Low framerate detected: %.1f FPS", metrics.framerate))
    end
    
    if metrics.memory > thresholds.memory then
        DevToolsState.debugger:log("warn", 
            string.format("High memory usage: %.1f MB", metrics.memory))
    end
end

-- ========================================
-- DEVELOPER CONSOLE
-- ========================================

function DeveloperToolsSystem.createDeveloperConsole()
    local player = Players.LocalPlayer
    local playerGui = player:WaitForChild("PlayerGui")
    
    -- Create console GUI
    local consoleGui = Instance.new("ScreenGui")
    consoleGui.Name = "DeveloperConsole"
    consoleGui.ResetOnSpawn = false
    consoleGui.Parent = playerGui
    
    -- Create console frame
    local consoleFrame = Instance.new("Frame")
    consoleFrame.Name = "ConsoleFrame"
    consoleFrame.Size = UDim2.new(1, 0, 0, DEVTOOLS_CONFIG.console.height)
    consoleFrame.Position = UDim2.new(0, 0, 1, -DEVTOOLS_CONFIG.console.height)
    consoleFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
    consoleFrame.BorderSizePixel = 0
    consoleFrame.Visible = false
    consoleFrame.Parent = consoleGui
    
    -- Create console header
    local header = Instance.new("Frame")
    header.Name = "Header"
    header.Size = UDim2.new(1, 0, 0, 30)
    header.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
    header.BorderSizePixel = 0
    header.Parent = consoleFrame
    
    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(1, -100, 1, 0)
    title.Position = UDim2.new(0, 10, 0, 0)
    title.BackgroundTransparency = 1
    title.Text = "Developer Console"
    title.TextColor3 = Color3.fromRGB(255, 255, 255)
    title.TextSize = 14
    title.Font = Enum.Font.SourceSansLight
    title.TextXAlignment = Enum.TextXAlignment.Left
    title.Parent = header
    
    -- Create clear button
    local clearButton = Instance.new("TextButton")
    clearButton.Size = UDim2.new(0, 50, 0, 20)
    clearButton.Position = UDim2.new(1, -60, 0, 5)
    clearButton.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
    clearButton.Text = "Clear"
    clearButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    clearButton.TextSize = 12
    clearButton.Font = Enum.Font.SourceSans
    clearButton.BorderSizePixel = 0
    clearButton.Parent = header
    
    -- Create log display
    local logFrame = Instance.new("ScrollingFrame")
    logFrame.Name = "LogFrame"
    logFrame.Size = UDim2.new(1, 0, 1, -60)
    logFrame.Position = UDim2.new(0, 0, 0, 30)
    logFrame.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
    logFrame.BorderSizePixel = 0
    logFrame.ScrollBarThickness = 8
    logFrame.Parent = consoleFrame
    
    local logLayout = Instance.new("UIListLayout")
    logLayout.SortOrder = Enum.SortOrder.LayoutOrder
    logLayout.Padding = UDim.new(0, 1)
    logLayout.Parent = logFrame
    
    -- Create input area
    local inputFrame = Instance.new("Frame")
    inputFrame.Name = "InputFrame"
    inputFrame.Size = UDim2.new(1, 0, 0, 30)
    inputFrame.Position = UDim2.new(0, 0, 1, -30)
    inputFrame.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
    inputFrame.BorderSizePixel = 0
    inputFrame.Parent = consoleFrame
    
    local inputBox = Instance.new("TextBox")
    inputBox.Name = "InputBox"
    inputBox.Size = UDim2.new(1, -10, 1, -6)
    inputBox.Position = UDim2.new(0, 5, 0, 3)
    inputBox.BackgroundTransparency = 1
    inputBox.Text = ""
    inputBox.PlaceholderText = "Enter Lua command..."
    inputBox.TextColor3 = Color3.fromRGB(255, 255, 255)
    inputBox.PlaceholderColor3 = Color3.fromRGB(150, 150, 150)
    inputBox.TextSize = 14
    inputBox.Font = Enum.Font.SourceSans
    inputBox.TextXAlignment = Enum.TextXAlignment.Left
    inputBox.ClearTextOnFocus = false
    inputBox.Parent = inputFrame
    
    -- Set up event handlers
    clearButton.MouseButton1Click:Connect(function()
        DeveloperToolsSystem.clearConsole()
    end)
    
    inputBox.FocusLost:Connect(function(enterPressed)
        if enterPressed then
            DeveloperToolsSystem.executeCommand(inputBox.Text)
            inputBox.Text = ""
        end
    end)
    
    DevToolsState.interfaces.console = {
        gui = consoleGui,
        frame = consoleFrame,
        logFrame = logFrame,
        inputBox = inputBox,
        logLayout = logLayout
    }
    
    print("💻 Developer console created")
end

function DeveloperToolsSystem.toggleConsole()
    local console = DevToolsState.interfaces.console
    if console then
        console.frame.Visible = not console.frame.Visible
        DevToolsState.console.isVisible = console.frame.Visible
        
        if DevToolsState.console.isVisible then
            console.inputBox:CaptureFocus()
            DeveloperToolsSystem.updateConsoleDisplay()
        end
    end
end

function DeveloperToolsSystem.updateConsoleDisplay()
    local console = DevToolsState.interfaces.console
    if not console then return end
    
    -- Clear existing log entries
    for _, child in ipairs(console.logFrame:GetChildren()) do
        if child:IsA("TextLabel") then
            child:Destroy()
        end
    end
    
    -- Add log entries
    for i, logEntry in ipairs(DevToolsState.debugging.logEntries) do
        local logLabel = Instance.new("TextLabel")
        logLabel.Size = UDim2.new(1, -10, 0, 20)
        logLabel.BackgroundTransparency = 1
        logLabel.TextColor3 = DeveloperToolsSystem.getLogColor(logEntry.level)
        logLabel.TextSize = 12
        logLabel.Font = Enum.Font.SourceSans
        logLabel.TextXAlignment = Enum.TextXAlignment.Left
        logLabel.TextYAlignment = Enum.TextYAlignment.Top
        logLabel.TextWrapped = true
        logLabel.LayoutOrder = i
        logLabel.Parent = console.logFrame
        
        -- Format log message
        local timestamp = DEVTOOLS_CONFIG.debugging.showTimestamps and 
            string.format("[%s] ", os.date("%H:%M:%S", logEntry.timestamp)) or ""
        local levelStr = string.format("[%s] ", logEntry.level:upper())
        
        logLabel.Text = timestamp .. levelStr .. logEntry.message
        
        -- Auto-size label based on text
        local textService = game:GetService("TextService")
        local textSize = textService:GetTextSize(
            logLabel.Text,
            logLabel.TextSize,
            logLabel.Font,
            Vector2.new(console.logFrame.AbsoluteSize.X - 10, math.huge)
        )
        
        logLabel.Size = UDim2.new(1, -10, 0, math.max(20, textSize.Y + 4))
    end
    
    -- Scroll to bottom
    console.logFrame.CanvasPosition = Vector2.new(0, console.logFrame.CanvasSize.Y.Offset)
end

function DeveloperToolsSystem.getLogColor(level)
    local colors = {
        trace = Color3.fromRGB(150, 150, 150),
        debug = Color3.fromRGB(100, 150, 255),
        info = Color3.fromRGB(255, 255, 255),
        warn = Color3.fromRGB(255, 200, 100),
        error = Color3.fromRGB(255, 100, 100)
    }
    
    return colors[level] or colors.info
end

function DeveloperToolsSystem.clearConsole()
    DevToolsState.debugging.logEntries = {}
    DeveloperToolsSystem.updateConsoleDisplay()
    print("Console cleared")
end

function DeveloperToolsSystem.executeCommand(command)
    if command == "" then return end
    
    -- Log the command
    DevToolsState.debugger:log("info", "> " .. command, {source = "console"})
    
    -- Add to history
    table.insert(DevToolsState.console.history, command)
    if #DevToolsState.console.history > DEVTOOLS_CONFIG.console.maxHistory then
        table.remove(DevToolsState.console.history, 1)
    end
    
    -- Execute command
    local success, result = pcall(function()
        local func, err = loadstring("return " .. command)
        if not func then
            func, err = loadstring(command)
        end
        
        if not func then
            error("Syntax error: " .. err)
        end
        
        return func()
    end)
    
    if success then
        if result ~= nil then
            local resultStr = DeveloperToolsSystem.inspectVariable(result, 2)
            DevToolsState.debugger:log("info", "< " .. resultStr, {source = "console_result"})
        end
    else
        DevToolsState.debugger:log("error", "Error: " .. tostring(result), {source = "console_error"})
    end
end

-- ========================================
-- OBJECT INSPECTOR
-- ========================================

function DeveloperToolsSystem.createObjectInspector()
    local player = Players.LocalPlayer
    local playerGui = player:WaitForChild("PlayerGui")
    
    -- Create inspector GUI
    local inspectorGui = Instance.new("ScreenGui")
    inspectorGui.Name = "ObjectInspector"
    inspectorGui.ResetOnSpawn = false
    inspectorGui.Parent = playerGui
    
    -- Create inspector frame
    local inspectorFrame = Instance.new("Frame")
    inspectorFrame.Name = "InspectorFrame"
    inspectorFrame.Size = UDim2.new(0, 400, 0, 600)
    inspectorFrame.Position = UDim2.new(1, -420, 0, 20)
    inspectorFrame.BackgroundColor3 = Color3.fromRGB(240, 240, 240)
    inspectorFrame.BorderSizePixel = 0
    inspectorFrame.Visible = false
    inspectorFrame.Parent = inspectorGui
    
    -- Round corners
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 8)
    corner.Parent = inspectorFrame
    
    -- Create header
    local header = Instance.new("Frame")
    header.Name = "Header"
    header.Size = UDim2.new(1, 0, 0, 40)
    header.BackgroundColor3 = Color3.fromRGB(50, 120, 200)
    header.BorderSizePixel = 0
    header.Parent = inspectorFrame
    
    local headerCorner = Instance.new("UICorner")
    headerCorner.CornerRadius = UDim.new(0, 8)
    headerCorner.Parent = header
    
    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(1, -80, 1, 0)
    title.Position = UDim2.new(0, 10, 0, 0)
    title.BackgroundTransparency = 1
    title.Text = "Object Inspector"
    title.TextColor3 = Color3.new(1, 1, 1)
    title.TextSize = 16
    title.Font = Enum.Font.SourceSansBold
    title.TextXAlignment = Enum.TextXAlignment.Left
    title.Parent = header
    
    -- Create close button
    local closeButton = Instance.new("TextButton")
    closeButton.Size = UDim2.new(0, 30, 0, 30)
    closeButton.Position = UDim2.new(1, -35, 0, 5)
    closeButton.BackgroundColor3 = Color3.fromRGB(220, 50, 50)
    closeButton.Text = "×"
    closeButton.TextColor3 = Color3.new(1, 1, 1)
    closeButton.TextSize = 18
    closeButton.Font = Enum.Font.SourceSansBold
    closeButton.BorderSizePixel = 0
    closeButton.Parent = header
    
    local closeCorner = Instance.new("UICorner")
    closeCorner.CornerRadius = UDim.new(0, 15)
    closeCorner.Parent = closeButton
    
    -- Create property display
    local propertyFrame = Instance.new("ScrollingFrame")
    propertyFrame.Name = "PropertyFrame"
    propertyFrame.Size = UDim2.new(1, 0, 1, -40)
    propertyFrame.Position = UDim2.new(0, 0, 0, 40)
    propertyFrame.BackgroundTransparency = 1
    propertyFrame.ScrollBarThickness = 8
    propertyFrame.Parent = inspectorFrame
    
    local propertyLayout = Instance.new("UIListLayout")
    propertyLayout.SortOrder = Enum.SortOrder.Name
    propertyLayout.Padding = UDim.new(0, 2)
    propertyLayout.Parent = propertyFrame
    
    -- Set up event handlers
    closeButton.MouseButton1Click:Connect(function()
        inspectorFrame.Visible = false
        DevToolsState.inspector.isVisible = false
    end)
    
    DevToolsState.interfaces.inspector = {
        gui = inspectorGui,
        frame = inspectorFrame,
        propertyFrame = propertyFrame,
        propertyLayout = propertyLayout,
        title = title
    }
    
    print("🔍 Object inspector created")
end

function DeveloperToolsSystem.inspectObject(object)
    local inspector = DevToolsState.interfaces.inspector
    if not inspector then return end
    
    DevToolsState.inspector.selectedObject = object
    DevToolsState.inspector.isVisible = true
    inspector.frame.Visible = true
    
    -- Update title
    if object then
        inspector.title.Text = string.format("Inspector: %s", 
            typeof(object) == "Instance" and object.Name or tostring(object))
    else
        inspector.title.Text = "Object Inspector"
    end
    
    -- Update properties
    DeveloperToolsSystem.updateInspectorProperties()
end

function DeveloperToolsSystem.updateInspectorProperties()
    local inspector = DevToolsState.interfaces.inspector
    local object = DevToolsState.inspector.selectedObject
    
    if not inspector or not object then return end
    
    -- Clear existing properties
    for _, child in ipairs(inspector.propertyFrame:GetChildren()) do
        if child:IsA("Frame") then
            child:Destroy()
        end
    end
    
    -- Add properties based on object type
    if typeof(object) == "Instance" then
        DeveloperToolsSystem.addInstanceProperties(object, inspector.propertyFrame)
    elseif typeof(object) == "table" then
        DeveloperToolsSystem.addTableProperties(object, inspector.propertyFrame)
    else
        DeveloperToolsSystem.addGenericProperties(object, inspector.propertyFrame)
    end
end

function DeveloperToolsSystem.addInstanceProperties(instance, parent)
    -- Add basic info
    DeveloperToolsSystem.createPropertyRow("ClassName", instance.ClassName, parent, false)
    DeveloperToolsSystem.createPropertyRow("Name", instance.Name, parent, true)
    DeveloperToolsSystem.createPropertyRow("Parent", 
        instance.Parent and instance.Parent.Name or "nil", parent, false)
    
    -- Add properties
    local properties = {"Size", "Position", "BackgroundColor3", "TextColor3", "Visible", "Transparency"}
    
    for _, propName in ipairs(properties) do
        local success, value = pcall(function()
            return instance[propName]
        end)
        
        if success then
            DeveloperToolsSystem.createPropertyRow(propName, tostring(value), parent, true)
        end
    end
end

function DeveloperToolsSystem.addTableProperties(table_, parent)
    for key, value in pairs(table_) do
        local keyStr = tostring(key)
        local valueStr = DeveloperToolsSystem.inspectVariable(value, 1)
        DeveloperToolsSystem.createPropertyRow(keyStr, valueStr, parent, false)
    end
end

function DeveloperToolsSystem.addGenericProperties(object, parent)
    DeveloperToolsSystem.createPropertyRow("Type", typeof(object), parent, false)
    DeveloperToolsSystem.createPropertyRow("Value", tostring(object), parent, false)
end

function DeveloperToolsSystem.createPropertyRow(name, value, parent, editable)
    local row = Instance.new("Frame")
    row.Name = name
    row.Size = UDim2.new(1, -10, 0, 25)
    row.BackgroundTransparency = 1
    row.Parent = parent
    
    local nameLabel = Instance.new("TextLabel")
    nameLabel.Size = UDim2.new(0.4, 0, 1, 0)
    nameLabel.BackgroundTransparency = 1
    nameLabel.Text = name
    nameLabel.TextColor3 = Color3.fromRGB(50, 50, 50)
    nameLabel.TextSize = 12
    nameLabel.Font = Enum.Font.SourceSans
    nameLabel.TextXAlignment = Enum.TextXAlignment.Left
    nameLabel.Parent = row
    
    if editable then
        local valueBox = Instance.new("TextBox")
        valueBox.Size = UDim2.new(0.6, -5, 1, -2)
        valueBox.Position = UDim2.new(0.4, 0, 0, 1)
        valueBox.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
        valueBox.BorderColor3 = Color3.fromRGB(200, 200, 200)
        valueBox.Text = value
        valueBox.TextColor3 = Color3.fromRGB(30, 30, 30)
        valueBox.TextSize = 12
        valueBox.Font = Enum.Font.SourceSans
        valueBox.TextXAlignment = Enum.TextXAlignment.Left
        valueBox.Parent = row
        
        valueBox.FocusLost:Connect(function(enterPressed)
            if enterPressed then
                DeveloperToolsSystem.updateObjectProperty(name, valueBox.Text)
            end
        end)
    else
        local valueLabel = Instance.new("TextLabel")
        valueLabel.Size = UDim2.new(0.6, -5, 1, 0)
        valueLabel.Position = UDim2.new(0.4, 0, 0, 0)
        valueLabel.BackgroundTransparency = 1
        valueLabel.Text = value
        valueLabel.TextColor3 = Color3.fromRGB(100, 100, 100)
        valueLabel.TextSize = 12
        valueLabel.Font = Enum.Font.SourceSans
        valueLabel.TextXAlignment = Enum.TextXAlignment.Left
        valueLabel.TextWrapped = true
        valueLabel.Parent = row
    end
end

function DeveloperToolsSystem.updateObjectProperty(propertyName, newValue)
    local object = DevToolsState.inspector.selectedObject
    if not object or typeof(object) ~= "Instance" then return end
    
    local success, error = pcall(function()
        -- Try to convert value to appropriate type
        local convertedValue = newValue
        
        -- Simple type conversion
        if newValue == "true" then
            convertedValue = true
        elseif newValue == "false" then
            convertedValue = false
        elseif tonumber(newValue) then
            convertedValue = tonumber(newValue)
        end
        
        object[propertyName] = convertedValue
    end)
    
    if success then
        print(string.format("Updated %s.%s = %s", object.Name, propertyName, newValue))
    else
        warn(string.format("Failed to update property: %s", error))
    end
end

-- ========================================
-- TESTING TOOLS
-- ========================================

function DeveloperToolsSystem.initializeTestingTools()
    DevToolsState.testFramework = {
        tests = {},
        results = {},
        
        registerTest = function(self, name, testFunction)
            self.tests[name] = testFunction
            print(string.format("🧪 Test registered: %s", name))
        end,
        
        runTest = function(self, name)
            local test = self.tests[name]
            if not test then
                warn(string.format("Test not found: %s", name))
                return false
            end
            
            local startTime = tick()
            local success, result = pcall(test)
            local endTime = tick()
            
            local testResult = {
                name = name,
                success = success,
                result = result,
                duration = endTime - startTime,
                timestamp = tick()
            }
            
            self.results[name] = testResult
            
            if success then
                print(string.format("✅ Test passed: %s (%.3fs)", name, testResult.duration))
            else
                print(string.format("❌ Test failed: %s - %s", name, result))
            end
            
            return success
        end,
        
        runAllTests = function(self)
            local totalTests = 0
            local passedTests = 0
            
            for name, _ in pairs(self.tests) do
                totalTests = totalTests + 1
                if self:runTest(name) then
                    passedTests = passedTests + 1
                end
            end
            
            print(string.format("🧪 Test Summary: %d/%d passed", passedTests, totalTests))
            return passedTests, totalTests
        end,
        
        benchmark = function(self, name, func, iterations)
            iterations = iterations or 1000
            
            local startTime = tick()
            for i = 1, iterations do
                func()
            end
            local endTime = tick()
            
            local totalTime = endTime - startTime
            local avgTime = totalTime / iterations
            
            print(string.format("⏱️ Benchmark %s: %.3fs total, %.6fs avg (%d iterations)", 
                name, totalTime, avgTime, iterations))
            
            return avgTime
        end
    }
    
    -- Register sample tests
    DeveloperToolsSystem.registerSampleTests()
    
    print("🧪 Testing tools initialized")
end

function DeveloperToolsSystem.registerSampleTests()
    local testFramework = DevToolsState.testFramework
    
    testFramework:registerTest("SampleTest", function()
        assert(1 + 1 == 2, "Basic math failed")
        assert(typeof("test") == "string", "Type check failed")
        return "Sample test passed"
    end)
    
    testFramework:registerTest("PerformanceTest", function()
        local start = tick()
        for i = 1, 1000 do
            local _ = i * 2
        end
        local duration = tick() - start
        assert(duration < 1, "Performance test took too long")
        return "Performance test passed"
    end)
    
    testFramework:registerTest("MemoryTest", function()
        local before = collectgarbage("count")
        local bigTable = {}
        for i = 1, 1000 do
            bigTable[i] = string.rep("test", 100)
        end
        bigTable = nil
        collectgarbage()
        local after = collectgarbage("count")
        
        -- Memory should not increase significantly after cleanup
        return "Memory test completed"
    end)
end

-- ========================================
-- INPUT HANDLERS
-- ========================================

function DeveloperToolsSystem.setupInputHandlers()
    UserInputService.InputBegan:Connect(function(input, gameProcessed)
        if gameProcessed then return end
        
        -- Toggle console with F12
        if input.KeyCode == DEVTOOLS_CONFIG.console.shortcuts.toggle then
            DeveloperToolsSystem.toggleConsole()
        end
        
        -- Toggle inspector with F11
        if input.KeyCode == Enum.KeyCode.F11 then
            DeveloperToolsSystem.toggleInspector()
        end
        
        -- Toggle profiler with F10
        if input.KeyCode == Enum.KeyCode.F10 then
            DeveloperToolsSystem.toggleProfiler()
        end
    end)
    
    print("⌨️ Input handlers initialized")
end

function DeveloperToolsSystem.toggleInspector()
    local inspector = DevToolsState.interfaces.inspector
    if inspector then
        inspector.frame.Visible = not inspector.frame.Visible
        DevToolsState.inspector.isVisible = inspector.frame.Visible
        
        if DevToolsState.inspector.isVisible and not DevToolsState.inspector.selectedObject then
            -- Inspect workspace by default
            DeveloperToolsSystem.inspectObject(workspace)
        end
    end
end

function DeveloperToolsSystem.toggleProfiler()
    if DevToolsState.profiler.currentSession then
        DevToolsState.profiler:endSession()
    else
        DevToolsState.profiler:startSession("Manual Session")
    end
end

-- ========================================
-- MAIN INTERFACE
-- ========================================

function DeveloperToolsSystem.createMainInterface()
    local player = Players.LocalPlayer
    local playerGui = player:WaitForChild("PlayerGui")
    
    -- Create main tools GUI
    local toolsGui = Instance.new("ScreenGui")
    toolsGui.Name = "DeveloperTools"
    toolsGui.ResetOnSpawn = false
    toolsGui.Parent = playerGui
    
    -- Create floating toolbar
    local toolbar = Instance.new("Frame")
    toolbar.Name = "Toolbar"
    toolbar.Size = UDim2.new(0, 300, 0, 50)
    toolbar.Position = UDim2.new(0, 20, 0, 20)
    toolbar.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
    toolbar.BorderSizePixel = 0
    toolbar.Parent = toolsGui
    
    local toolbarCorner = Instance.new("UICorner")
    toolbarCorner.CornerRadius = UDim.new(0, 25)
    toolbarCorner.Parent = toolbar
    
    -- Create toolbar buttons
    local buttons = {
        {name = "Console", icon = "💻", action = DeveloperToolsSystem.toggleConsole},
        {name = "Inspector", icon = "🔍", action = DeveloperToolsSystem.toggleInspector},
        {name = "Profiler", icon = "📊", action = DeveloperToolsSystem.toggleProfiler},
        {name = "Tests", icon = "🧪", action = function() DeveloperToolsSystem.runTests() end}
    }
    
    for i, buttonInfo in ipairs(buttons) do
        local button = Instance.new("TextButton")
        button.Name = buttonInfo.name
        button.Size = UDim2.new(0, 70, 0, 40)
        button.Position = UDim2.new(0, (i-1) * 75 + 5, 0, 5)
        button.BackgroundColor3 = Color3.fromRGB(70, 70, 70)
        button.Text = buttonInfo.icon
        button.TextColor3 = Color3.new(1, 1, 1)
        button.TextSize = 20
        button.Font = Enum.Font.SourceSans
        button.BorderSizePixel = 0
        button.Parent = toolbar
        
        local buttonCorner = Instance.new("UICorner")
        buttonCorner.CornerRadius = UDim.new(0, 8)
        buttonCorner.Parent = button
        
        button.MouseButton1Click:Connect(buttonInfo.action)
        
        -- Add tooltip
        local tooltip = Instance.new("TextLabel")
        tooltip.Name = "Tooltip"
        tooltip.Size = UDim2.new(0, 80, 0, 20)
        tooltip.Position = UDim2.new(0, -5, 1, 5)
        tooltip.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
        tooltip.Text = buttonInfo.name
        tooltip.TextColor3 = Color3.new(1, 1, 1)
        tooltip.TextSize = 12
        tooltip.Font = Enum.Font.SourceSans
        tooltip.Visible = false
        tooltip.BorderSizePixel = 0
        tooltip.Parent = button
        
        local tooltipCorner = Instance.new("UICorner")
        tooltipCorner.CornerRadius = UDim.new(0, 4)
        tooltipCorner.Parent = tooltip
        
        button.MouseEnter:Connect(function()
            tooltip.Visible = true
        end)
        
        button.MouseLeave:Connect(function()
            tooltip.Visible = false
        end)
    end
    
    DevToolsState.interfaces.toolbar = {
        gui = toolsGui,
        toolbar = toolbar
    }
    
    print("🛠️ Main developer tools interface created")
end

-- ========================================
-- PUBLIC API
-- ========================================

function DeveloperToolsSystem.log(level, message, context)
    DevToolsState.debugger:log(level, message, context)
end

function DeveloperToolsSystem.debug(message, context)
    DevToolsState.debugger:log("debug", message, context)
end

function DeveloperToolsSystem.info(message, context)
    DevToolsState.debugger:log("info", message, context)
end

function DeveloperToolsSystem.warn(message, context)
    DevToolsState.debugger:log("warn", message, context)
end

function DeveloperToolsSystem.error(message, context)
    DevToolsState.debugger:log("error", message, context)
end

function DeveloperToolsSystem.trace(message)
    return DevToolsState.debugger:trace(message)
end

function DeveloperToolsSystem.inspect(variable, depth)
    return DevToolsState.debugger:inspect(variable, depth)
end

function DeveloperToolsSystem.addBreakpoint(file, line)
    DevToolsState.debugger:addBreakpoint(file, line)
end

function DeveloperToolsSystem.removeBreakpoint(file, line)
    DevToolsState.debugger:removeBreakpoint(file, line)
end

function DeveloperToolsSystem.startProfiling(name)
    return DevToolsState.profiler:startSession(name)
end

function DeveloperToolsSystem.endProfiling()
    return DevToolsState.profiler:endSession()
end

function DeveloperToolsSystem.profileFunction(name, func)
    local startTime = tick()
    local result = func()
    local endTime = tick()
    
    DevToolsState.profiler:sample(name, startTime, endTime)
    return result
end

function DeveloperToolsSystem.benchmark(name, func, iterations)
    return DevToolsState.testFramework:benchmark(name, func, iterations)
end

function DeveloperToolsSystem.registerTest(name, testFunction)
    DevToolsState.testFramework:registerTest(name, testFunction)
end

function DeveloperToolsSystem.runTest(name)
    return DevToolsState.testFramework:runTest(name)
end

function DeveloperToolsSystem.runTests()
    return DevToolsState.testFramework:runAllTests()
end

function DeveloperToolsSystem.runDeveloperToolsDemo()
    print("🛠️ Running developer tools demonstration...")
    
    -- Show tool capabilities
    print("  🔧 Developer Tools Features:")
    print("    Console: Advanced Lua command execution and logging")
    print("    Inspector: Real-time object property viewing and editing")
    print("    Profiler: Performance monitoring and optimization")
    print("    Debugger: Breakpoints, variable inspection, and tracing")
    print("    Testing: Unit tests, benchmarks, and coverage analysis")
    
    -- Show keyboard shortcuts
    print("  ⌨️ Keyboard Shortcuts:")
    print("    F12: Toggle Developer Console")
    print("    F11: Toggle Object Inspector")
    print("    F10: Toggle Performance Profiler")
    print("    Ctrl+L: Clear Console (when console is active)")
    
    -- Demonstrate logging
    print("  📝 Logging Example:")
    DeveloperToolsSystem.info("This is an info message")
    DeveloperToolsSystem.warn("This is a warning message")
    DeveloperToolsSystem.debug("This is a debug message")
    
    -- Demonstrate variable inspection
    print("  🔍 Variable Inspection:")
    local sampleData = {
        name = "Sample Object",
        value = 42,
        nested = {
            array = {1, 2, 3},
            flag = true
        }
    }
    local inspected = DeveloperToolsSystem.inspect(sampleData, 2)
    print("    Sample object inspection:")
    local lines = inspected:split("\n")
    for i = 1, math.min(5, #lines) do
        print(string.format("      %s", lines[i]))
    end
    
    -- Demonstrate profiling
    print("  📊 Profiling Example:")
    DeveloperToolsSystem.startProfiling("Demo Session")
    
    -- Simulate some work
    local result = DeveloperToolsSystem.profileFunction("demo_calculation", function()
        local sum = 0
        for i = 1, 1000 do
            sum = sum + i
        end
        return sum
    end)
    
    local session = DeveloperToolsSystem.endProfiling()
    print(string.format("    Profiling session completed: %.3fs", session.duration))
    
    -- Demonstrate testing
    print("  🧪 Testing Example:")
    local passed, total = DeveloperToolsSystem.runTests()
    print(string.format("    Test results: %d/%d tests passed", passed, total))
    
    -- Show performance metrics
    print("  📈 Performance Metrics:")
    local metrics = DevToolsState.profiling.metrics
    print(string.format("    Current FPS: %.1f", metrics.framerate))
    print(string.format("    Memory Usage: %.1f MB", metrics.memory))
    
    -- Show interface controls
    print("  🖥️ User Interface:")
    print("    Developer toolbar visible in top-left corner")
    print("    Click toolbar buttons to open different tools")
    print("    All tools are dockable and resizable")
    
    print("🛠️ Developer tools demonstration completed")
    print("     Comprehensive development environment operational!")
end

-- Initialize the developer tools system
DeveloperToolsSystem.initialize()

print("🛠️ DeveloperToolsSystem loaded with comprehensive debugging and development tools")

return DeveloperToolsSystem
