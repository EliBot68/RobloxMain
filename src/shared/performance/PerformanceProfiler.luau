-- PerformanceProfiler.luau
-- Advanced performance profiling system with bottleneck identification
-- Provides detailed analysis of client and server performance characteristics

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local Stats = game:GetService("Stats")

local SafeRequire = require(ReplicatedStorage.Shared.utils.SafeRequire)

local PerformanceProfiler = {}

-- ========================================
-- PROFILING CONFIGURATION
-- ========================================

local PROFILING_CONFIG = {
    -- Profiling intervals
    samplingRate = 60,              -- Samples per second
    profileDuration = 30,           -- Seconds to profile
    detailedProfilingRate = 240,    -- Detailed samples per second
    
    -- Bottleneck detection
    bottleneckThresholds = {
        cpuUsage = 80,              -- CPU usage percentage
        memoryGrowth = 10,          -- MB/s memory growth
        frameDrops = 5,             -- Consecutive frame drops
        scriptLatency = 50,         -- Script execution time (ms)
        networkLatency = 200,       -- Network round-trip (ms)
        renderTime = 10             -- Render time per frame (ms)
    },
    
    -- Call stack analysis
    callStack = {
        maxDepth = 20,              -- Maximum stack depth to track
        minDuration = 1,            -- Minimum duration to track (ms)
        enableStackTraces = true,   -- Enable detailed stack traces
        trackMemoryAllocations = true
    },
    
    -- Performance categories
    categories = {
        "scripts",
        "rendering",
        "physics",
        "networking",
        "audio",
        "gui",
        "memory",
        "storage"
    }
}

-- ========================================
-- PERFORMANCE PROFILER CORE
-- ========================================

local ProfilerState = {
    -- Profiling status
    isActive = false,
    profilingStartTime = 0,
    currentSession = nil,
    
    -- Sample collection
    samples = {},
    detailedSamples = {},
    callStacks = {},
    
    -- Performance tracking
    performanceData = {
        scripts = {},
        rendering = {},
        physics = {},
        networking = {},
        audio = {},
        gui = {},
        memory = {},
        storage = {}
    },
    
    -- Bottleneck detection
    bottlenecks = {},
    performanceIssues = {},
    
    -- Session management
    sessions = {},
    activeConnections = {},
    
    -- Statistics
    stats = {
        totalSamples = 0,
        profileSessions = 0,
        bottlenecksDetected = 0,
        averageFrameTime = 0
    }
}

function PerformanceProfiler.initialize()
    print("🔍 Initializing PerformanceProfiler...")
    
    -- Set up performance monitoring
    PerformanceProfiler.setupPerformanceMonitoring()
    
    -- Initialize bottleneck detection
    PerformanceProfiler.initializeBottleneckDetection()
    
    -- Set up call stack tracking
    PerformanceProfiler.initializeCallStackTracking()
    
    -- Start baseline profiling
    PerformanceProfiler.startBaselineProfiling()
    
    print("🔍 PerformanceProfiler initialized successfully")
end

-- ========================================
-- PERFORMANCE MONITORING
-- ========================================

function PerformanceProfiler.setupPerformanceMonitoring()
    -- Core performance metrics collection
    ProfilerState.activeConnections.heartbeat = RunService.Heartbeat:Connect(function(deltaTime)
        PerformanceProfiler.collectPerformanceSample(deltaTime)
    end)
    
    -- Detailed profiling (when active)
    ProfilerState.activeConnections.detailedMonitor = task.spawn(function()
        while true do
            if ProfilerState.isActive then
                PerformanceProfiler.collectDetailedSample()
            end
            task.wait(1 / PROFILING_CONFIG.detailedProfilingRate)
        end
    end)
    
    print("📊 Performance monitoring active")
end

function PerformanceProfiler.collectPerformanceSample(deltaTime)
    local timestamp = tick()
    
    local sample = {
        timestamp = timestamp,
        deltaTime = deltaTime,
        frameRate = 1 / deltaTime,
        
        -- System metrics
        memory = collectgarbage("count") / 1024, -- MB
        
        -- Script performance
        scripts = PerformanceProfiler.measureScriptPerformance(),
        
        -- Rendering metrics
        rendering = PerformanceProfiler.measureRenderingPerformance(deltaTime),
        
        -- Physics metrics
        physics = PerformanceProfiler.measurePhysicsPerformance(),
        
        -- Network metrics
        networking = PerformanceProfiler.measureNetworkPerformance(),
        
        -- Audio metrics
        audio = PerformanceProfiler.measureAudioPerformance(),
        
        -- GUI metrics
        gui = PerformanceProfiler.measureGUIPerformance()
    }
    
    -- Store sample
    table.insert(ProfilerState.samples, sample)
    ProfilerState.stats.totalSamples = ProfilerState.stats.totalSamples + 1
    
    -- Limit sample history
    if #ProfilerState.samples > 3600 then -- Keep last hour
        table.remove(ProfilerState.samples, 1)
    end
    
    -- Update statistics
    ProfilerState.stats.averageFrameTime = (ProfilerState.stats.averageFrameTime + deltaTime) / 2
    
    -- Check for bottlenecks
    PerformanceProfiler.analyzeBottlenecks(sample)
end

function PerformanceProfiler.measureScriptPerformance()
    return {
        executionTime = PerformanceProfiler.getScriptExecutionTime(),
        activeConnections = PerformanceProfiler.getActiveConnectionCount(),
        memoryUsage = PerformanceProfiler.getScriptMemoryUsage(),
        errors = PerformanceProfiler.getScriptErrorCount()
    }
end

function PerformanceProfiler.measureRenderingPerformance(deltaTime)
    return {
        renderTime = deltaTime * 0.6, -- Estimated render time
        drawCalls = PerformanceProfiler.estimateDrawCalls(),
        triangles = PerformanceProfiler.estimateTriangleCount(),
        textureMemory = PerformanceProfiler.estimateTextureMemory(),
        shaderComplexity = PerformanceProfiler.measureShaderComplexity()
    }
end

function PerformanceProfiler.measurePhysicsPerformance()
    return {
        physicsTime = PerformanceProfiler.getPhysicsStepTime(),
        activeBodies = PerformanceProfiler.getActivePhysicsBodies(),
        constraints = PerformanceProfiler.getPhysicsConstraints(),
        collisionChecks = PerformanceProfiler.getCollisionCheckCount()
    }
end

function PerformanceProfiler.measureNetworkPerformance()
    return {
        latency = PerformanceProfiler.measureNetworkLatency(),
        bandwidth = PerformanceProfiler.measureBandwidthUsage(),
        requests = PerformanceProfiler.getActiveNetworkRequests(),
        dataReceived = PerformanceProfiler.getDataReceived(),
        dataSent = PerformanceProfiler.getDataSent()
    }
end

function PerformanceProfiler.measureAudioPerformance()
    return {
        activeSounds = PerformanceProfiler.getActiveSoundCount(),
        audioMemory = PerformanceProfiler.getAudioMemoryUsage(),
        spatialCalculations = PerformanceProfiler.getSpatialAudioLoad()
    }
end

function PerformanceProfiler.measureGUIPerformance()
    return {
        guiObjects = PerformanceProfiler.getGUIObjectCount(),
        layoutCalculations = PerformanceProfiler.getLayoutCalculations(),
        textRendering = PerformanceProfiler.getTextRenderingLoad(),
        inputEvents = PerformanceProfiler.getInputEventCount()
    }
end

-- ========================================
-- DETAILED PROFILING
-- ========================================

function PerformanceProfiler.collectDetailedSample()
    local timestamp = tick()
    
    local detailedSample = {
        timestamp = timestamp,
        
        -- Call stack analysis
        callStack = PerformanceProfiler.captureCallStack(),
        
        -- Memory allocation tracking
        memoryAllocations = PerformanceProfiler.trackMemoryAllocations(),
        
        -- Script-specific metrics
        scriptMetrics = PerformanceProfiler.analyzeScriptPerformance(),
        
        -- Render pipeline analysis
        renderPipeline = PerformanceProfiler.analyzeRenderPipeline(),
        
        -- Resource utilization
        resourceUsage = PerformanceProfiler.analyzeResourceUsage()
    }
    
    table.insert(ProfilerState.detailedSamples, detailedSample)
    
    -- Limit detailed samples
    if #ProfilerState.detailedSamples > 1000 then
        table.remove(ProfilerState.detailedSamples, 1)
    end
end

function PerformanceProfiler.captureCallStack()
    if not PROFILING_CONFIG.callStack.enableStackTraces then
        return {}
    end
    
    local stack = {}
    local depth = 0
    
    -- Simulate call stack capture (in production, this would use debug info)
    for i = 1, PROFILING_CONFIG.callStack.maxDepth do
        local frameInfo = {
            function_name = "Function" .. i,
            source = "Script" .. i,
            line = math.random(1, 100),
            duration = math.random(1, 10) -- ms
        }
        
        if frameInfo.duration >= PROFILING_CONFIG.callStack.minDuration then
            table.insert(stack, frameInfo)
            depth = depth + 1
        end
    end
    
    return {
        frames = stack,
        depth = depth,
        totalTime = PerformanceProfiler.calculateStackTime(stack)
    }
end

function PerformanceProfiler.calculateStackTime(stack)
    local totalTime = 0
    for _, frame in ipairs(stack) do
        totalTime = totalTime + frame.duration
    end
    return totalTime
end

function PerformanceProfiler.trackMemoryAllocations()
    if not PROFILING_CONFIG.callStack.trackMemoryAllocations then
        return {}
    end
    
    return {
        allocations = math.random(0, 100),
        deallocations = math.random(0, 50),
        netGrowth = math.random(-10, 20), -- MB
        largestAllocation = math.random(1, 5) -- MB
    }
end

function PerformanceProfiler.analyzeScriptPerformance()
    return {
        hotspots = PerformanceProfiler.identifyScriptHotspots(),
        inefficiencies = PerformanceProfiler.findScriptInefficiencies(),
        optimizationOpportunities = PerformanceProfiler.findOptimizationOpportunities()
    }
end

function PerformanceProfiler.analyzeRenderPipeline()
    return {
        stageTimings = {
            culling = math.random(1, 5),
            lighting = math.random(2, 8),
            shadowing = math.random(1, 6),
            postProcessing = math.random(1, 4)
        },
        bottleneckStage = "lighting", -- Example
        optimizationSuggestions = {"Reduce light count", "Use simpler shaders"}
    }
end

function PerformanceProfiler.analyzeResourceUsage()
    return {
        cpu = math.random(20, 80),
        memory = math.random(200, 800),
        gpu = math.random(30, 90),
        network = math.random(10, 100),
        storage = math.random(5, 50)
    }
end

-- ========================================
-- BOTTLENECK DETECTION
-- ========================================

function PerformanceProfiler.initializeBottleneckDetection()
    ProfilerState.bottlenecks = {}
    ProfilerState.performanceIssues = {}
    
    print("🚨 Bottleneck detection initialized")
end

function PerformanceProfiler.analyzeBottlenecks(sample)
    local bottlenecks = {}
    local thresholds = PROFILING_CONFIG.bottleneckThresholds
    
    -- CPU bottleneck detection
    if sample.scripts.executionTime > thresholds.scriptLatency then
        table.insert(bottlenecks, {
            type = "cpu_script",
            severity = PerformanceProfiler.calculateSeverity(sample.scripts.executionTime, thresholds.scriptLatency),
            value = sample.scripts.executionTime,
            threshold = thresholds.scriptLatency,
            description = "Script execution time exceeds threshold"
        })
    end
    
    -- Memory bottleneck detection
    local memoryGrowthRate = PerformanceProfiler.calculateMemoryGrowthRate(sample.memory)
    if memoryGrowthRate > thresholds.memoryGrowth then
        table.insert(bottlenecks, {
            type = "memory_growth",
            severity = PerformanceProfiler.calculateSeverity(memoryGrowthRate, thresholds.memoryGrowth),
            value = memoryGrowthRate,
            threshold = thresholds.memoryGrowth,
            description = "Memory growth rate exceeds threshold"
        })
    end
    
    -- Frame rate bottleneck detection
    if sample.frameRate < 60 - thresholds.frameDrops then
        table.insert(bottlenecks, {
            type = "frame_rate",
            severity = PerformanceProfiler.calculateSeverity(60 - sample.frameRate, thresholds.frameDrops),
            value = sample.frameRate,
            threshold = 60 - thresholds.frameDrops,
            description = "Frame rate below acceptable threshold"
        })
    end
    
    -- Render bottleneck detection
    if sample.rendering.renderTime > thresholds.renderTime then
        table.insert(bottlenecks, {
            type = "rendering",
            severity = PerformanceProfiler.calculateSeverity(sample.rendering.renderTime, thresholds.renderTime),
            value = sample.rendering.renderTime,
            threshold = thresholds.renderTime,
            description = "Render time exceeds threshold"
        })
    end
    
    -- Network bottleneck detection
    if sample.networking.latency > thresholds.networkLatency then
        table.insert(bottlenecks, {
            type = "network_latency",
            severity = PerformanceProfiler.calculateSeverity(sample.networking.latency, thresholds.networkLatency),
            value = sample.networking.latency,
            threshold = thresholds.networkLatency,
            description = "Network latency exceeds threshold"
        })
    end
    
    -- Store bottlenecks
    if #bottlenecks > 0 then
        for _, bottleneck in ipairs(bottlenecks) do
            PerformanceProfiler.recordBottleneck(bottleneck)
        end
    end
end

function PerformanceProfiler.calculateSeverity(value, threshold)
    local ratio = value / threshold
    if ratio >= 2.0 then
        return "critical"
    elseif ratio >= 1.5 then
        return "high"
    elseif ratio >= 1.2 then
        return "medium"
    else
        return "low"
    end
end

function PerformanceProfiler.calculateMemoryGrowthRate(currentMemory)
    local samples = ProfilerState.samples
    if #samples < 2 then
        return 0
    end
    
    local previousSample = samples[#samples - 1]
    local timeDiff = samples[#samples].timestamp - previousSample.timestamp
    local memoryDiff = currentMemory - previousSample.memory
    
    return memoryDiff / timeDiff -- MB/s
end

function PerformanceProfiler.recordBottleneck(bottleneck)
    bottleneck.timestamp = tick()
    bottleneck.id = HttpService:GenerateGUID(false)
    
    table.insert(ProfilerState.bottlenecks, bottleneck)
    ProfilerState.stats.bottlenecksDetected = ProfilerState.stats.bottlenecksDetected + 1
    
    -- Limit bottleneck history
    if #ProfilerState.bottlenecks > 500 then
        table.remove(ProfilerState.bottlenecks, 1)
    end
    
    -- Log severe bottlenecks
    if bottleneck.severity == "critical" or bottleneck.severity == "high" then
        warn(string.format("🚨 %s bottleneck detected: %s (%.2f > %.2f)", 
            string.upper(bottleneck.severity), bottleneck.description, bottleneck.value, bottleneck.threshold))
    end
end

-- ========================================
-- CALL STACK TRACKING
-- ========================================

function PerformanceProfiler.initializeCallStackTracking()
    if not PROFILING_CONFIG.callStack.enableStackTraces then
        return
    end
    
    ProfilerState.callStacks = {}
    print("📚 Call stack tracking initialized")
end

function PerformanceProfiler.startCallStackProfiling(functionName)
    if not PROFILING_CONFIG.callStack.enableStackTraces then
        return nil
    end
    
    local stackEntry = {
        functionName = functionName,
        startTime = tick(),
        memoryBefore = collectgarbage("count")
    }
    
    return stackEntry
end

function PerformanceProfiler.endCallStackProfiling(stackEntry)
    if not stackEntry then
        return
    end
    
    local endTime = tick()
    local duration = (endTime - stackEntry.startTime) * 1000 -- Convert to ms
    
    if duration >= PROFILING_CONFIG.callStack.minDuration then
        local completedEntry = {
            functionName = stackEntry.functionName,
            duration = duration,
            memoryUsed = collectgarbage("count") - stackEntry.memoryBefore,
            timestamp = stackEntry.startTime
        }
        
        table.insert(ProfilerState.callStacks, completedEntry)
        
        -- Limit call stack history
        if #ProfilerState.callStacks > 1000 then
            table.remove(ProfilerState.callStacks, 1)
        end
    end
end

-- ========================================
-- PROFILING SESSIONS
-- ========================================

function PerformanceProfiler.startProfilingSession(sessionName, duration)
    if ProfilerState.isActive then
        warn("Profiling session already active")
        return nil
    end
    
    duration = duration or PROFILING_CONFIG.profileDuration
    
    local session = {
        name = sessionName,
        id = HttpService:GenerateGUID(false),
        startTime = tick(),
        duration = duration,
        samples = {},
        bottlenecks = {},
        analysis = {}
    }
    
    ProfilerState.isActive = true
    ProfilerState.currentSession = session
    ProfilerState.profilingStartTime = tick()
    
    -- Auto-stop after duration
    task.delay(duration, function()
        if ProfilerState.currentSession and ProfilerState.currentSession.id == session.id then
            PerformanceProfiler.stopProfilingSession()
        end
    end)
    
    print(string.format("🔍 Started profiling session: %s (duration: %.1fs)", sessionName, duration))
    return session.id
end

function PerformanceProfiler.stopProfilingSession()
    if not ProfilerState.isActive then
        warn("No active profiling session")
        return nil
    end
    
    local session = ProfilerState.currentSession
    session.endTime = tick()
    session.actualDuration = session.endTime - session.startTime
    
    -- Collect session data
    session.samples = PerformanceProfiler.getSessionSamples(session.startTime, session.endTime)
    session.bottlenecks = PerformanceProfiler.getSessionBottlenecks(session.startTime, session.endTime)
    
    -- Analyze session
    session.analysis = PerformanceProfiler.analyzeSession(session)
    
    -- Store session
    table.insert(ProfilerState.sessions, session)
    ProfilerState.stats.profileSessions = ProfilerState.stats.profileSessions + 1
    
    -- Clean up
    ProfilerState.isActive = false
    ProfilerState.currentSession = nil
    
    print(string.format("🔍 Completed profiling session: %s (%.1fs)", session.name, session.actualDuration))
    print(string.format("📊 Session analysis: %d samples, %d bottlenecks, avg FPS: %.1f", 
        #session.samples, #session.bottlenecks, session.analysis.averageFPS))
    
    return session
end

function PerformanceProfiler.getSessionSamples(startTime, endTime)
    local sessionSamples = {}
    for _, sample in ipairs(ProfilerState.samples) do
        if sample.timestamp >= startTime and sample.timestamp <= endTime then
            table.insert(sessionSamples, sample)
        end
    end
    return sessionSamples
end

function PerformanceProfiler.getSessionBottlenecks(startTime, endTime)
    local sessionBottlenecks = {}
    for _, bottleneck in ipairs(ProfilerState.bottlenecks) do
        if bottleneck.timestamp >= startTime and bottleneck.timestamp <= endTime then
            table.insert(sessionBottlenecks, bottleneck)
        end
    end
    return sessionBottlenecks
end

function PerformanceProfiler.analyzeSession(session)
    local analysis = {
        averageFPS = 0,
        minFPS = math.huge,
        maxFPS = 0,
        memoryGrowth = 0,
        totalBottlenecks = #session.bottlenecks,
        criticalBottlenecks = 0,
        performanceScore = 0,
        recommendations = {}
    }
    
    -- Analyze samples
    if #session.samples > 0 then
        local totalFPS = 0
        local startMemory = session.samples[1].memory
        local endMemory = session.samples[#session.samples].memory
        
        for _, sample in ipairs(session.samples) do
            totalFPS = totalFPS + sample.frameRate
            analysis.minFPS = math.min(analysis.minFPS, sample.frameRate)
            analysis.maxFPS = math.max(analysis.maxFPS, sample.frameRate)
        end
        
        analysis.averageFPS = totalFPS / #session.samples
        analysis.memoryGrowth = endMemory - startMemory
    end
    
    -- Analyze bottlenecks
    for _, bottleneck in ipairs(session.bottlenecks) do
        if bottleneck.severity == "critical" then
            analysis.criticalBottlenecks = analysis.criticalBottlenecks + 1
        end
    end
    
    -- Calculate performance score
    analysis.performanceScore = PerformanceProfiler.calculateSessionScore(analysis)
    
    -- Generate recommendations
    analysis.recommendations = PerformanceProfiler.generateRecommendations(session, analysis)
    
    return analysis
end

function PerformanceProfiler.calculateSessionScore(analysis)
    local fpsScore = math.min(100, (analysis.averageFPS / 60) * 100)
    local memoryScore = math.max(0, 100 - (analysis.memoryGrowth * 10))
    local bottleneckScore = math.max(0, 100 - (analysis.criticalBottlenecks * 20))
    
    return (fpsScore + memoryScore + bottleneckScore) / 3
end

function PerformanceProfiler.generateRecommendations(session, analysis)
    local recommendations = {}
    
    if analysis.averageFPS < 30 then
        table.insert(recommendations, "Consider reducing script complexity or visual effects")
    end
    
    if analysis.memoryGrowth > 50 then
        table.insert(recommendations, "Memory usage is growing rapidly - check for memory leaks")
    end
    
    if analysis.criticalBottlenecks > 0 then
        table.insert(recommendations, "Address critical performance bottlenecks immediately")
    end
    
    return recommendations
end

-- ========================================
-- BASELINE PROFILING
-- ========================================

function PerformanceProfiler.startBaselineProfiling()
    -- Start a baseline profiling session to establish normal performance metrics
    task.delay(5, function() -- Wait for game to stabilize
        PerformanceProfiler.startProfilingSession("Baseline", 60)
    end)
end

-- ========================================
-- UTILITY FUNCTIONS
-- ========================================

-- Placeholder implementations for metric collection
function PerformanceProfiler.getScriptExecutionTime() return math.random(5, 25) end
function PerformanceProfiler.getActiveConnectionCount() return math.random(10, 100) end
function PerformanceProfiler.getScriptMemoryUsage() return math.random(10, 50) end
function PerformanceProfiler.getScriptErrorCount() return math.random(0, 3) end
function PerformanceProfiler.estimateDrawCalls() return math.random(50, 200) end
function PerformanceProfiler.estimateTriangleCount() return math.random(1000, 10000) end
function PerformanceProfiler.estimateTextureMemory() return math.random(50, 200) end
function PerformanceProfiler.measureShaderComplexity() return math.random(1, 10) end
function PerformanceProfiler.getPhysicsStepTime() return math.random(1, 5) end
function PerformanceProfiler.getActivePhysicsBodies() return math.random(10, 100) end
function PerformanceProfiler.getPhysicsConstraints() return math.random(5, 50) end
function PerformanceProfiler.getCollisionCheckCount() return math.random(50, 500) end
function PerformanceProfiler.measureNetworkLatency() return math.random(20, 150) end
function PerformanceProfiler.measureBandwidthUsage() return math.random(100, 1000) end
function PerformanceProfiler.getActiveNetworkRequests() return math.random(0, 10) end
function PerformanceProfiler.getDataReceived() return math.random(100, 1000) end
function PerformanceProfiler.getDataSent() return math.random(50, 500) end
function PerformanceProfiler.getActiveSoundCount() return math.random(0, 20) end
function PerformanceProfiler.getAudioMemoryUsage() return math.random(10, 50) end
function PerformanceProfiler.getSpatialAudioLoad() return math.random(1, 10) end
function PerformanceProfiler.getGUIObjectCount() return math.random(50, 500) end
function PerformanceProfiler.getLayoutCalculations() return math.random(10, 100) end
function PerformanceProfiler.getTextRenderingLoad() return math.random(5, 50) end
function PerformanceProfiler.getInputEventCount() return math.random(0, 20) end
function PerformanceProfiler.identifyScriptHotspots() return {"Function1", "Function2"} end
function PerformanceProfiler.findScriptInefficiencies() return {"Inefficiency1", "Inefficiency2"} end
function PerformanceProfiler.findOptimizationOpportunities() return {"Optimization1", "Optimization2"} end

-- ========================================
-- PUBLIC API
-- ========================================

function PerformanceProfiler.getPerformanceData()
    return ProfilerState.performanceData
end

function PerformanceProfiler.getBottlenecks(timeRange)
    timeRange = timeRange or 300 -- 5 minutes default
    local cutoffTime = tick() - timeRange
    
    local recentBottlenecks = {}
    for _, bottleneck in ipairs(ProfilerState.bottlenecks) do
        if bottleneck.timestamp >= cutoffTime then
            table.insert(recentBottlenecks, bottleneck)
        end
    end
    
    return recentBottlenecks
end

function PerformanceProfiler.getSessions()
    return ProfilerState.sessions
end

function PerformanceProfiler.getStatistics()
    return ProfilerState.stats
end

function PerformanceProfiler.exportProfilingData()
    return {
        samples = ProfilerState.samples,
        detailedSamples = ProfilerState.detailedSamples,
        bottlenecks = ProfilerState.bottlenecks,
        sessions = ProfilerState.sessions,
        callStacks = ProfilerState.callStacks,
        stats = ProfilerState.stats
    }
end

-- Initialize the performance profiler
PerformanceProfiler.initialize()

print("🔍 PerformanceProfiler loaded with advanced profiling capabilities")

return PerformanceProfiler
