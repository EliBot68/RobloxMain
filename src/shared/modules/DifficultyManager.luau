-- DifficultyManager.luau
-- Comprehensive difficulty progression system for Color Rush
-- Increases speed, spawn rate, and obstacle complexity over time

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local SafeRequire = require(ReplicatedStorage.Shared.utils.SafeRequire)

local DifficultyManager = {}
DifficultyManager.__index = DifficultyManager

-- Default configuration
local DEFAULT_CONFIG = {
    -- Time-based progression
    timeBasedProgression = true,
    distanceBasedProgression = true,
    
    -- Base values (starting difficulty)
    baseSpeed = 16,
    baseSpawnRate = 0.8, -- obstacles per second
    baseObstacleComplexity = 1,
    
    -- Maximum values (difficulty caps)
    maxSpeed = 50,
    maxSpawnRate = 3.0,
    maxObstacleComplexity = 10,
    
    -- Progression rates
    speedIncreaseRate = 0.5, -- speed increase per difficulty level
    spawnRateIncreaseRate = 0.1, -- spawn rate increase per difficulty level
    complexityIncreaseRate = 0.3, -- complexity increase per difficulty level
    
    -- Progression triggers
    timePerDifficultyLevel = 30, -- seconds
    distancePerDifficultyLevel = 500, -- studs
    
    -- Curve types: "linear", "exponential", "logarithmic", "stepped"
    speedCurve = "exponential",
    spawnCurve = "linear",
    complexityCurve = "logarithmic",
    
    -- Exponential curve parameters
    exponentialBase = 1.15,
    exponentialCap = 2.0,
    
    -- Logarithmic curve parameters
    logarithmicBase = 2,
    logarithmicMultiplier = 1.5,
    
    -- Stepped progression
    stepsPerLevel = 5,
    
    -- Dynamic difficulty adjustment
    adaptiveDifficulty = true,
    playerPerformanceWeight = 0.3,
    performanceWindow = 10, -- seconds for performance averaging
    
    -- Difficulty events
    difficultySpikes = true,
    spikeChance = 0.1, -- 10% chance per level
    spikeDuration = 15, -- seconds
    spikeMultiplier = 1.5
}

-- Difficulty level thresholds and names
local DIFFICULTY_LEVELS = {
    {level = 1, name = "Beginner", color = Color3.fromRGB(100, 255, 100)},
    {level = 2, name = "Easy", color = Color3.fromRGB(150, 255, 150)},
    {level = 3, name = "Normal", color = Color3.fromRGB(255, 255, 100)},
    {level = 4, name = "Challenging", color = Color3.fromRGB(255, 200, 100)},
    {level = 5, name = "Hard", color = Color3.fromRGB(255, 150, 100)},
    {level = 6, name = "Expert", color = Color3.fromRGB(255, 100, 100)},
    {level = 7, name = "Master", color = Color3.fromRGB(255, 100, 150)},
    {level = 8, name = "Insane", color = Color3.fromRGB(255, 50, 50)},
    {level = 9, name = "Nightmare", color = Color3.fromRGB(200, 0, 100)},
    {level = 10, name = "Impossible", color = Color3.fromRGB(150, 0, 200)}
}

function DifficultyManager.new(config)
    local self = setmetatable({}, DifficultyManager)
    
    -- Merge config with defaults
    self.config = {}
    for key, value in pairs(DEFAULT_CONFIG) do
        self.config[key] = config and config[key] or value
    end
    
    -- Current state
    self.currentLevel = 1
    self.playTime = 0
    self.distanceTraveled = 0
    self.isActive = false
    
    -- Current difficulty values
    self.currentSpeed = self.config.baseSpeed
    self.currentSpawnRate = self.config.baseSpawnRate
    self.currentComplexity = self.config.baseObstacleComplexity
    
    -- Performance tracking for adaptive difficulty
    self.playerPerformance = {
        deaths = 0,
        successfulRuns = 0,
        averageTime = 0,
        recentPerformance = {},
        performanceScore = 1.0
    }
    
    -- Event tracking
    self.events = {
        onLevelUp = {},
        onDifficultyChange = {},
        onSpike = {},
        onAdaptiveAdjustment = {}
    }
    
    -- Spike system
    self.currentSpike = nil
    self.spikeStartTime = 0
    
    -- Update connection
    self.updateConnection = nil
    
    print("🎚️ DifficultyManager created with config:")
    print("   Time-based: " .. tostring(self.config.timeBasedProgression))
    print("   Distance-based: " .. tostring(self.config.distanceBasedProgression))
    print("   Adaptive: " .. tostring(self.config.adaptiveDifficulty))
    
    return self
end

function DifficultyManager:Start()
    if self.isActive then
        return
    end
    
    self.isActive = true
    self.playTime = 0
    self.distanceTraveled = 0
    self.currentLevel = 1
    
    -- Reset to base values
    self.currentSpeed = self.config.baseSpeed
    self.currentSpawnRate = self.config.baseSpawnRate
    self.currentComplexity = self.config.baseObstacleComplexity
    
    -- Start update loop
    self.updateConnection = RunService.Heartbeat:Connect(function(deltaTime)
        self:Update(deltaTime)
    end)
    
    self:TriggerEvent("onDifficultyChange", {
        level = self.currentLevel,
        speed = self.currentSpeed,
        spawnRate = self.currentSpawnRate,
        complexity = self.currentComplexity
    })
    
    print("▶️ DifficultyManager started")
end

function DifficultyManager:Stop()
    if not self.isActive then
        return
    end
    
    self.isActive = false
    
    if self.updateConnection then
        self.updateConnection:Disconnect()
        self.updateConnection = nil
    end
    
    print("⏹️ DifficultyManager stopped")
end

function DifficultyManager:Update(deltaTime)
    if not self.isActive then
        return
    end
    
    -- Update time and distance (distance should be fed from game logic)
    self.playTime = self.playTime + deltaTime
    
    -- Calculate new difficulty level
    local newLevel = self:CalculateDifficultyLevel()
    
    -- Check for level up
    if newLevel > self.currentLevel then
        self:LevelUp(newLevel)
    end
    
    -- Update difficulty values
    self:UpdateDifficultyValues()
    
    -- Handle difficulty spikes
    self:HandleDifficultySpikes(deltaTime)
    
    -- Update adaptive difficulty
    if self.config.adaptiveDifficulty then
        self:UpdateAdaptiveDifficulty()
    end
end

function DifficultyManager:CalculateDifficultyLevel()
    local timeLevel = 1
    local distanceLevel = 1
    
    -- Time-based level calculation
    if self.config.timeBasedProgression then
        timeLevel = math.floor(self.playTime / self.config.timePerDifficultyLevel) + 1
    end
    
    -- Distance-based level calculation
    if self.config.distanceBasedProgression then
        distanceLevel = math.floor(self.distanceTraveled / self.config.distancePerDifficultyLevel) + 1
    end
    
    -- Use the higher of the two (or just one if the other is disabled)
    local calculatedLevel = math.max(timeLevel, distanceLevel)
    
    -- Cap at maximum level
    return math.min(calculatedLevel, #DIFFICULTY_LEVELS)
end

function DifficultyManager:UpdateDifficultyValues()
    local baseLevel = self.currentLevel - 1 -- Zero-indexed for calculations
    
    -- Apply performance modifier if adaptive difficulty is enabled
    local performanceModifier = 1.0
    if self.config.adaptiveDifficulty then
        performanceModifier = self.playerPerformance.performanceScore
    end
    
    -- Calculate speed
    self.currentSpeed = self:ApplyCurve(
        self.config.baseSpeed,
        self.config.maxSpeed,
        baseLevel,
        self.config.speedIncreaseRate,
        self.config.speedCurve
    ) * performanceModifier
    
    -- Calculate spawn rate
    self.currentSpawnRate = self:ApplyCurve(
        self.config.baseSpawnRate,
        self.config.maxSpawnRate,
        baseLevel,
        self.config.spawnRateIncreaseRate,
        self.config.spawnCurve
    ) * performanceModifier
    
    -- Calculate complexity
    self.currentComplexity = self:ApplyCurve(
        self.config.baseObstacleComplexity,
        self.config.maxObstacleComplexity,
        baseLevel,
        self.config.complexityIncreaseRate,
        self.config.complexityCurve
    ) * performanceModifier
    
    -- Apply spike multiplier if active
    if self.currentSpike then
        self.currentSpeed = self.currentSpeed * self.config.spikeMultiplier
        self.currentSpawnRate = self.currentSpawnRate * self.config.spikeMultiplier
        self.currentComplexity = self.currentComplexity * self.config.spikeMultiplier
    end
    
    -- Ensure values don't exceed maximums
    self.currentSpeed = math.min(self.currentSpeed, self.config.maxSpeed)
    self.currentSpawnRate = math.min(self.currentSpawnRate, self.config.maxSpawnRate)
    self.currentComplexity = math.min(self.currentComplexity, self.config.maxObstacleComplexity)
end

function DifficultyManager:ApplyCurve(baseValue, maxValue, level, increaseRate, curveType)
    local value = baseValue
    
    if curveType == "linear" then
        value = baseValue + (level * increaseRate)
        
    elseif curveType == "exponential" then
        local multiplier = math.min(
            math.pow(self.config.exponentialBase, level * increaseRate),
            self.config.exponentialCap
        )
        value = baseValue * multiplier
        
    elseif curveType == "logarithmic" then
        if level > 0 then
            local multiplier = 1 + (math.log(level + 1) / math.log(self.config.logarithmicBase)) * self.config.logarithmicMultiplier * increaseRate
            value = baseValue * multiplier
        end
        
    elseif curveType == "stepped" then
        local step = math.floor(level / self.config.stepsPerLevel)
        value = baseValue + (step * increaseRate)
    end
    
    return math.min(value, maxValue)
end

function DifficultyManager:LevelUp(newLevel)
    local oldLevel = self.currentLevel
    self.currentLevel = newLevel
    
    local levelData = DIFFICULTY_LEVELS[newLevel] or DIFFICULTY_LEVELS[#DIFFICULTY_LEVELS]
    
    print("🎚️ Difficulty Level Up! " .. oldLevel .. " → " .. newLevel .. " (" .. levelData.name .. ")")
    
    -- Check for difficulty spike
    if self.config.difficultySpikes and math.random() < self.config.spikeChance then
        self:TriggerDifficultySpike()
    end
    
    self:TriggerEvent("onLevelUp", {
        oldLevel = oldLevel,
        newLevel = newLevel,
        levelName = levelData.name,
        levelColor = levelData.color
    })
end

function DifficultyManager:TriggerDifficultySpike()
    if self.currentSpike then
        return -- Already in a spike
    end
    
    self.currentSpike = {
        startTime = self.playTime,
        duration = self.config.spikeDuration,
        multiplier = self.config.spikeMultiplier
    }
    
    print("⚡ Difficulty Spike activated! Duration: " .. self.config.spikeDuration .. "s")
    
    self:TriggerEvent("onSpike", {
        duration = self.config.spikeDuration,
        multiplier = self.config.spikeMultiplier
    })
end

function DifficultyManager:HandleDifficultySpikes(deltaTime)
    if not self.currentSpike then
        return
    end
    
    local spikeAge = self.playTime - self.currentSpike.startTime
    
    if spikeAge >= self.currentSpike.duration then
        print("⚡ Difficulty Spike ended")
        self.currentSpike = nil
    end
end

function DifficultyManager:UpdateAdaptiveDifficulty()
    -- Calculate performance score based on recent performance
    local totalScore = 0
    local sampleCount = #self.playerPerformance.recentPerformance
    
    if sampleCount > 0 then
        for _, performance in ipairs(self.playerPerformance.recentPerformance) do
            totalScore = totalScore + performance
        end
        
        local averagePerformance = totalScore / sampleCount
        
        -- Update performance score (1.0 = normal, <1.0 = easier, >1.0 = harder)
        local targetScore = 0.7 + (averagePerformance * 0.6) -- Range: 0.7 to 1.3
        
        -- Smooth adjustment
        self.playerPerformance.performanceScore = self.playerPerformance.performanceScore + 
            (targetScore - self.playerPerformance.performanceScore) * self.config.playerPerformanceWeight
        
        -- Cap the performance score
        self.playerPerformance.performanceScore = math.max(0.5, math.min(2.0, self.playerPerformance.performanceScore))
    end
end

function DifficultyManager:AddDistance(distance)
    self.distanceTraveled = self.distanceTraveled + distance
end

function DifficultyManager:RecordPlayerDeath()
    self.playerPerformance.deaths = self.playerPerformance.deaths + 1
    
    -- Add poor performance sample
    table.insert(self.playerPerformance.recentPerformance, 0.2)
    self:TrimPerformanceHistory()
    
    print("💀 Player death recorded - adjusting adaptive difficulty")
end

function DifficultyManager:RecordPlayerSuccess(completionTime)
    self.playerPerformance.successfulRuns = self.playerPerformance.successfulRuns + 1
    
    -- Calculate performance score based on completion time vs expected time
    local expectedTime = 60 -- Base expected time
    local performanceRatio = expectedTime / math.max(completionTime, 1)
    local performanceScore = math.min(1.0, performanceRatio)
    
    table.insert(self.playerPerformance.recentPerformance, performanceScore)
    self:TrimPerformanceHistory()
    
    print("🏆 Player success recorded - completion time: " .. string.format("%.1f", completionTime) .. "s")
end

function DifficultyManager:TrimPerformanceHistory()
    local maxSamples = math.ceil(self.config.performanceWindow)
    
    while #self.playerPerformance.recentPerformance > maxSamples do
        table.remove(self.playerPerformance.recentPerformance, 1)
    end
end

function DifficultyManager:GetCurrentDifficulty()
    return {
        level = self.currentLevel,
        levelName = (DIFFICULTY_LEVELS[self.currentLevel] or DIFFICULTY_LEVELS[#DIFFICULTY_LEVELS]).name,
        levelColor = (DIFFICULTY_LEVELS[self.currentLevel] or DIFFICULTY_LEVELS[#DIFFICULTY_LEVELS]).color,
        speed = self.currentSpeed,
        spawnRate = self.currentSpawnRate,
        complexity = self.currentComplexity,
        playTime = self.playTime,
        distanceTraveled = self.distanceTraveled,
        performanceScore = self.playerPerformance.performanceScore,
        isSpike = self.currentSpike ~= nil
    }
end

function DifficultyManager:SetDifficultyLevel(level)
    level = math.max(1, math.min(level, #DIFFICULTY_LEVELS))
    
    if level ~= self.currentLevel then
        local oldLevel = self.currentLevel
        self.currentLevel = level
        
        print("🎚️ Difficulty manually set to level " .. level)
        
        self:TriggerEvent("onLevelUp", {
            oldLevel = oldLevel,
            newLevel = level,
            manual = true
        })
    end
end

function DifficultyManager:ResetDifficulty()
    self.currentLevel = 1
    self.playTime = 0
    self.distanceTraveled = 0
    self.currentSpeed = self.config.baseSpeed
    self.currentSpawnRate = self.config.baseSpawnRate
    self.currentComplexity = self.config.baseObstacleComplexity
    self.currentSpike = nil
    self.playerPerformance.performanceScore = 1.0
    
    print("🔄 Difficulty reset to level 1")
end

-- Event system
function DifficultyManager:OnEvent(eventName, callback)
    if not self.events[eventName] then
        self.events[eventName] = {}
    end
    
    table.insert(self.events[eventName], callback)
end

function DifficultyManager:TriggerEvent(eventName, data)
    if self.events[eventName] then
        for _, callback in ipairs(self.events[eventName]) do
            pcall(callback, data)
        end
    end
    
    self:TriggerEvent("onDifficultyChange", self:GetCurrentDifficulty())
end

-- Static utility functions
function DifficultyManager.GetPresetConfigs()
    return {
        casual = {
            baseSpeed = 12,
            maxSpeed = 30,
            timePerDifficultyLevel = 45,
            speedIncreaseRate = 0.3,
            adaptiveDifficulty = true,
            difficultySpikes = false
        },
        
        normal = DEFAULT_CONFIG,
        
        hardcore = {
            baseSpeed = 20,
            maxSpeed = 80,
            timePerDifficultyLevel = 20,
            speedIncreaseRate = 0.8,
            spawnRateIncreaseRate = 0.15,
            adaptiveDifficulty = false,
            difficultySpikes = true,
            spikeChance = 0.2
        },
        
        timeAttack = {
            timeBasedProgression = true,
            distanceBasedProgression = false,
            timePerDifficultyLevel = 15,
            speedCurve = "exponential",
            maxSpeed = 100,
            difficultySpikes = true,
            spikeChance = 0.3
        },
        
        endurance = {
            timeBasedProgression = true,
            distanceBasedProgression = true,
            timePerDifficultyLevel = 60,
            speedCurve = "linear",
            adaptiveDifficulty = true,
            difficultySpikes = false
        }
    }
end

function DifficultyManager:Destroy()
    self:Stop()
    
    -- Clear all events
    for eventName in pairs(self.events) do
        self.events[eventName] = {}
    end
    
    print("🗑️ DifficultyManager destroyed")
end

return DifficultyManager
