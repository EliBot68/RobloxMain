-- DifficultyUIController.client.luau
-- Client-side UI controller for displaying difficulty information

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local StarterGui = game:GetService("StarterGui")

local Knit = require(ReplicatedStorage.Packages.Knit)

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- Wait for DifficultyService
local DifficultyService
repeat
    wait(0.1)
    DifficultyService = Knit.Services.DifficultyService
until DifficultyService

-- UI Elements
local difficultyGui
local mainFrame
local levelLabel
local speedBar
local spawnRateBar
local complexityBar
local spikeIndicator
local performanceIndicator

-- UI Configuration
local UI_CONFIG = {
    position = UDim2.new(0, 10, 0, 10),
    size = UDim2.new(0, 300, 0, 200),
    backgroundColor = Color3.fromRGB(0, 0, 0),
    backgroundTransparency = 0.3,
    
    -- Bar configurations
    barHeight = 20,
    barSpacing = 30,
    
    -- Animation settings
    animationDuration = 0.5,
    pulseSpeed = 2
}

-- Create the main UI
local function createDifficultyUI()
    -- Create ScreenGui
    difficultyGui = Instance.new("ScreenGui")
    difficultyGui.Name = "DifficultyUI"
    difficultyGui.ResetOnSpawn = false
    difficultyGui.Parent = playerGui
    
    -- Main frame
    mainFrame = Instance.new("Frame")
    mainFrame.Name = "DifficultyFrame"
    mainFrame.Size = UI_CONFIG.size
    mainFrame.Position = UI_CONFIG.position
    mainFrame.BackgroundColor3 = UI_CONFIG.backgroundColor
    mainFrame.BackgroundTransparency = UI_CONFIG.backgroundTransparency
    mainFrame.BorderSizePixel = 0
    mainFrame.Parent = difficultyGui
    
    -- Add corner rounding
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 8)
    corner.Parent = mainFrame
    
    -- Title
    local title = Instance.new("TextLabel")
    title.Name = "Title"
    title.Size = UDim2.new(1, 0, 0, 30)
    title.Position = UDim2.new(0, 0, 0, 0)
    title.Text = "DIFFICULTY"
    title.TextColor3 = Color3.fromRGB(255, 255, 255)
    title.TextScaled = true
    title.Font = Enum.Font.GothamBold
    title.BackgroundTransparency = 1
    title.Parent = mainFrame
    
    -- Level display
    levelLabel = Instance.new("TextLabel")
    levelLabel.Name = "LevelLabel"
    levelLabel.Size = UDim2.new(1, 0, 0, 40)
    levelLabel.Position = UDim2.new(0, 0, 0, 35)
    levelLabel.Text = "Level 1 - Beginner"
    levelLabel.TextColor3 = Color3.fromRGB(100, 255, 100)
    levelLabel.TextScaled = true
    levelLabel.Font = Enum.Font.Gotham
    levelLabel.BackgroundTransparency = 1
    levelLabel.Parent = mainFrame
    
    -- Speed bar
    speedBar = createProgressBar("Speed", UDim2.new(0, 0, 0, 80), Color3.fromRGB(255, 100, 100))
    
    -- Spawn rate bar
    spawnRateBar = createProgressBar("Spawn Rate", UDim2.new(0, 0, 0, 110), Color3.fromRGB(100, 255, 100))
    
    -- Complexity bar
    complexityBar = createProgressBar("Complexity", UDim2.new(0, 0, 0, 140), Color3.fromRGB(100, 100, 255))
    
    -- Spike indicator
    spikeIndicator = Instance.new("Frame")
    spikeIndicator.Name = "SpikeIndicator"
    spikeIndicator.Size = UDim2.new(1, -20, 0, 20)
    spikeIndicator.Position = UDim2.new(0, 10, 0, 175)
    spikeIndicator.BackgroundColor3 = Color3.fromRGB(255, 255, 0)
    spikeIndicator.BackgroundTransparency = 1
    spikeIndicator.BorderSizePixel = 0
    spikeIndicator.Parent = mainFrame
    
    local spikeCorner = Instance.new("UICorner")
    spikeCorner.CornerRadius = UDim.new(0, 4)
    spikeCorner.Parent = spikeIndicator
    
    local spikeText = Instance.new("TextLabel")
    spikeText.Name = "SpikeText"
    spikeText.Size = UDim2.new(1, 0, 1, 0)
    spikeText.Position = UDim2.new(0, 0, 0, 0)
    spikeText.Text = "⚡ DIFFICULTY SPIKE!"
    spikeText.TextColor3 = Color3.fromRGB(255, 255, 255)
    spikeText.TextScaled = true
    spikeText.Font = Enum.Font.GothamBold
    spikeText.BackgroundTransparency = 1
    spikeText.Parent = spikeIndicator
    
    -- Performance indicator (small, bottom right)
    performanceIndicator = Instance.new("TextLabel")
    performanceIndicator.Name = "PerformanceIndicator"
    performanceIndicator.Size = UDim2.new(0, 60, 0, 15)
    performanceIndicator.Position = UDim2.new(1, -70, 1, -20)
    performanceIndicator.Text = "1.0x"
    performanceIndicator.TextColor3 = Color3.fromRGB(200, 200, 200)
    performanceIndicator.TextScaled = true
    performanceIndicator.Font = Enum.Font.Gotham
    performanceIndicator.BackgroundTransparency = 1
    performanceIndicator.Parent = mainFrame
end

-- Create a progress bar
local function createProgressBar(labelText, position, color)
    local container = Instance.new("Frame")
    container.Name = labelText .. "Container"
    container.Size = UDim2.new(1, -20, 0, UI_CONFIG.barHeight)
    container.Position = position
    container.BackgroundTransparency = 1
    container.Parent = mainFrame
    
    -- Label
    local label = Instance.new("TextLabel")
    label.Name = "Label"
    label.Size = UDim2.new(0.3, 0, 1, 0)
    label.Position = UDim2.new(0, 10, 0, 0)
    label.Text = labelText .. ":"
    label.TextColor3 = Color3.fromRGB(255, 255, 255)
    label.TextScaled = true
    label.Font = Enum.Font.Gotham
    label.BackgroundTransparency = 1
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Parent = container
    
    -- Background bar
    local background = Instance.new("Frame")
    background.Name = "Background"
    background.Size = UDim2.new(0.65, 0, 0.8, 0)
    background.Position = UDim2.new(0.33, 0, 0.1, 0)
    background.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
    background.BorderSizePixel = 0
    background.Parent = container
    
    local bgCorner = Instance.new("UICorner")
    bgCorner.CornerRadius = UDim.new(0, 4)
    bgCorner.Parent = background
    
    -- Progress bar
    local progressBar = Instance.new("Frame")
    progressBar.Name = "ProgressBar"
    progressBar.Size = UDim2.new(0, 0, 1, 0)
    progressBar.Position = UDim2.new(0, 0, 0, 0)
    progressBar.BackgroundColor3 = color
    progressBar.BorderSizePixel = 0
    progressBar.Parent = background
    
    local progressCorner = Instance.new("UICorner")
    progressCorner.CornerRadius = UDim.new(0, 4)
    progressCorner.Parent = progressBar
    
    -- Value label
    local valueLabel = Instance.new("TextLabel")
    valueLabel.Name = "ValueLabel"
    valueLabel.Size = UDim2.new(1, 0, 1, 0)
    valueLabel.Position = UDim2.new(0, 0, 0, 0)
    valueLabel.Text = "0"
    valueLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    valueLabel.TextScaled = true
    valueLabel.Font = Enum.Font.Gotham
    valueLabel.BackgroundTransparency = 1
    valueLabel.Parent = background
    
    return {
        container = container,
        progressBar = progressBar,
        valueLabel = valueLabel,
        color = color
    }
end

-- Update progress bar
local function updateProgressBar(bar, value, maxValue, displayValue)
    local percentage = math.min(value / maxValue, 1)
    
    -- Animate bar
    local tween = TweenService:Create(
        bar.progressBar,
        TweenInfo.new(UI_CONFIG.animationDuration, Enum.EasingStyle.Quart, Enum.EasingDirection.Out),
        {Size = UDim2.new(percentage, 0, 1, 0)}
    )
    tween:Play()
    
    -- Update value label
    bar.valueLabel.Text = displayValue or string.format("%.1f", value)
end

-- Update difficulty display
local function updateDifficultyDisplay(difficulty)
    if not difficulty then
        return
    end
    
    -- Update level display
    levelLabel.Text = "Level " .. difficulty.level .. " - " .. difficulty.levelName
    levelLabel.TextColor3 = difficulty.levelColor
    
    -- Update progress bars
    updateProgressBar(speedBar, difficulty.speed, 50, string.format("%.0f", difficulty.speed))
    updateProgressBar(spawnRateBar, difficulty.spawnRate, 3, string.format("%.1f", difficulty.spawnRate))
    updateProgressBar(complexityBar, difficulty.complexity, 10, string.format("%.1f", difficulty.complexity))
    
    -- Update performance indicator
    local performanceText = string.format("%.1fx", difficulty.performanceScore)
    performanceIndicator.Text = performanceText
    
    if difficulty.performanceScore < 0.8 then
        performanceIndicator.TextColor3 = Color3.fromRGB(100, 255, 100) -- Easier
    elseif difficulty.performanceScore > 1.2 then
        performanceIndicator.TextColor3 = Color3.fromRGB(255, 100, 100) -- Harder
    else
        performanceIndicator.TextColor3 = Color3.fromRGB(200, 200, 200) -- Normal
    end
    
    -- Update spike indicator
    if difficulty.isSpike then
        spikeIndicator.BackgroundTransparency = 0.2
        
        -- Pulse animation
        local pulseTween = TweenService:Create(
            spikeIndicator,
            TweenInfo.new(0.5, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true),
            {BackgroundTransparency = 0.8}
        )
        pulseTween:Play()
    else
        spikeIndicator.BackgroundTransparency = 1
    end
end

-- Level up animation
local function playLevelUpAnimation(data)
    -- Flash the level label
    local originalColor = levelLabel.TextColor3
    levelLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    
    local flashTween = TweenService:Create(
        levelLabel,
        TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut, 3, true),
        {TextColor3 = data.levelColor}
    )
    flashTween:Play()
    
    -- Scale animation
    local scaleTween = TweenService:Create(
        levelLabel,
        TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
        {TextSize = levelLabel.TextSize * 1.2}
    )
    scaleTween:Play()
    
    scaleTween.Completed:Connect(function()
        local resetTween = TweenService:Create(
            levelLabel,
            TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
            {TextSize = levelLabel.TextSize / 1.2}
        )
        resetTween:Play()
    end)
    
    print("🎚️ Level Up! " .. data.oldLevel .. " → " .. data.newLevel .. " (" .. data.levelName .. ")")
end

-- Spike animation
local function playSpikeAnimation(data)
    -- Shake the main frame
    local originalPosition = mainFrame.Position
    
    local shakeSequence = {}
    for i = 1, 10 do
        local offset = UDim2.new(0, math.random(-5, 5), 0, math.random(-5, 5))
        table.insert(shakeSequence, {
            Time = i * 0.05,
            Value = originalPosition + offset
        })
    end
    table.insert(shakeSequence, {Time = 0.6, Value = originalPosition})
    
    local shakeKeyframe = TweenService:Create(
        mainFrame,
        TweenInfo.new(0.6, Enum.EasingStyle.Bounce, Enum.EasingDirection.Out),
        {Position = originalPosition}
    )
    
    -- Simple shake effect
    for i = 1, 5 do
        spawn(function()
            wait(i * 0.1)
            mainFrame.Position = originalPosition + UDim2.new(0, math.random(-3, 3), 0, math.random(-3, 3))
        end)
    end
    
    spawn(function()
        wait(0.6)
        mainFrame.Position = originalPosition
    end)
    
    print("⚡ Difficulty Spike activated!")
end

-- Initialize UI
createDifficultyUI()

-- Connect to difficulty service events
DifficultyService.DifficultyChanged:Connect(function(data)
    updateDifficultyDisplay(data)
end)

DifficultyService.LevelUp:Connect(function(data)
    playLevelUpAnimation(data)
end)

DifficultyService.SpikeActivated:Connect(function(data)
    playSpikeAnimation(data)
end)

-- Initial difficulty request
spawn(function()
    wait(2) -- Wait for services to fully initialize
    
    local initialDifficulty = DifficultyService:GetCurrentDifficulty()
    if initialDifficulty then
        updateDifficultyDisplay(initialDifficulty)
    end
end)

-- Debug controls (only in Studio)
if game:GetService("RunService"):IsStudio() then
    -- Create debug controls
    local debugFrame = Instance.new("Frame")
    debugFrame.Size = UDim2.new(0, 200, 0, 100)
    debugFrame.Position = UDim2.new(1, -210, 0, 10)
    debugFrame.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
    debugFrame.BackgroundTransparency = 0.3
    debugFrame.BorderSizePixel = 0
    debugFrame.Parent = difficultyGui
    
    local debugCorner = Instance.new("UICorner")
    debugCorner.CornerRadius = UDim.new(0, 8)
    debugCorner.Parent = debugFrame
    
    local debugTitle = Instance.new("TextLabel")
    debugTitle.Size = UDim2.new(1, 0, 0, 25)
    debugTitle.Position = UDim2.new(0, 0, 0, 0)
    debugTitle.Text = "Debug Controls"
    debugTitle.TextColor3 = Color3.fromRGB(255, 255, 255)
    debugTitle.TextScaled = true
    debugTitle.Font = Enum.Font.Gotham
    debugTitle.BackgroundTransparency = 1
    debugTitle.Parent = debugFrame
    
    -- Level up button
    local levelUpButton = Instance.new("TextButton")
    levelUpButton.Size = UDim2.new(0.9, 0, 0, 25)
    levelUpButton.Position = UDim2.new(0.05, 0, 0, 30)
    levelUpButton.Text = "Force Level Up"
    levelUpButton.BackgroundColor3 = Color3.fromRGB(100, 255, 100)
    levelUpButton.Parent = debugFrame
    
    levelUpButton.Activated:Connect(function()
        local currentDifficulty = DifficultyService:GetCurrentDifficulty()
        if currentDifficulty then
            DifficultyService:SetDifficultyLevel(currentDifficulty.level + 1)
        end
    end)
    
    -- Reset button
    local resetButton = Instance.new("TextButton")
    resetButton.Size = UDim2.new(0.9, 0, 0, 25)
    resetButton.Position = UDim2.new(0.05, 0, 0, 60)
    resetButton.Text = "Reset Difficulty"
    resetButton.BackgroundColor3 = Color3.fromRGB(255, 100, 100)
    resetButton.Parent = debugFrame
    
    resetButton.Activated:Connect(function()
        DifficultyService:SetDifficultyLevel(1)
    end)
end

print("🎚️ Difficulty UI Controller initialized!")
print("📊 UI shows: Level, Speed, Spawn Rate, Complexity, Performance Score, Spikes")
print("🎮 Animated transitions and visual feedback enabled!")
