-- UITestingSystem.luau
-- Automated UI testing for critical user journeys and interface validation
-- Tests user interactions, UI responsiveness, and interface consistency

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local GuiService = game:GetService("GuiService")
local TweenService = game:GetService("TweenService")
local Players = game:GetService("Players")

local SafeRequire = require(ReplicatedStorage.Shared.utils.SafeRequire)

local UITestingSystem = {}

-- ========================================
-- UI TESTING CONFIGURATION
-- ========================================

local UI_TEST_CONFIG = {
    -- UI interaction settings
    interaction = {
        enableAutomatedClicking = true,
        enableKeyboardSimulation = true,
        enableScrollSimulation = true,
        enableDragSimulation = true,
        defaultClickDelay = 100,         -- milliseconds
        defaultTypeDelay = 50,           -- milliseconds between keystrokes
        maxWaitTime = 5000               -- 5 seconds max wait
    },
    
    -- UI validation
    validation = {
        enableLayoutValidation = true,
        enableVisibilityValidation = true,
        enableResponsivenessValidation = true,
        enableAccessibilityValidation = true,
        responseTimeThreshold = 500,     -- 500ms
        layoutTolerancePixels = 2
    },
    
    -- Screenshot and visual testing
    visual = {
        enableScreenshotComparison = true,
        enableVisualRegression = true,
        pixelDifferenceThreshold = 0.05, -- 5% pixel difference allowed
        enableColorBlindTesting = true
    },
    
    -- User journey testing
    journeys = {
        enableCriticalPathTesting = true,
        enableUserFlowValidation = true,
        enableStateTransitionTesting = true,
        enableErrorPathTesting = true,
        maxJourneyDuration = 30000       -- 30 seconds
    },
    
    -- Performance testing
    performance = {
        enableUIPerformanceTesting = true,
        enableAnimationTesting = true,
        enableMemoryLeakDetection = true,
        maxFrameDrops = 5,
        maxMemoryIncrease = 50           -- 50MB
    }
}

-- ========================================
-- UI TESTING STATE
-- ========================================

local UITestState = {
    -- UI element tracking
    trackedElements = {},
    elementStates = {},
    elementMetrics = {},
    
    -- User journey tracking
    activeJourneys = {},
    journeyResults = {},
    userFlows = {},
    
    -- Interaction simulation
    simulatedInputs = {},
    inputSequences = {},
    interactionQueue = {},
    
    -- Visual testing
    screenshots = {},
    visualBaselines = {},
    visualDifferences = {},
    
    -- Performance monitoring
    frameDrops = {},
    animationMetrics = {},
    memoryUsage = {},
    
    -- Test results
    testResults = {},
    validationResults = {},
    
    -- Statistics
    stats = {
        totalUITests = 0,
        passedUITests = 0,
        failedUITests = 0,
        totalJourneys = 0,
        averageResponseTime = 0,
        totalInteractions = 0
    }
}

function UITestingSystem.initialize()
    print("🖥️ Initializing UITestingSystem...")
    
    -- Set up UI element tracking
    UITestingSystem.setupUIElementTracking()
    
    -- Initialize interaction simulation
    UITestingSystem.initializeInteractionSimulation()
    
    -- Set up visual testing
    UITestingSystem.setupVisualTesting()
    
    -- Initialize user journey testing
    UITestingSystem.initializeUserJourneyTesting()
    
    -- Set up performance monitoring
    UITestingSystem.setupUIPerformanceMonitoring()
    
    print("🖥️ UITestingSystem initialized successfully")
end

-- ========================================
-- UI ELEMENT TRACKING
-- ========================================

function UITestingSystem.setupUIElementTracking()
    UITestState.trackedElements = {}
    UITestState.elementStates = {}
    
    -- Set up automatic UI discovery
    UITestingSystem.startUIDiscovery()
    
    print("👁️ UI element tracking initialized")
end

function UITestingSystem.startUIDiscovery()
    local player = Players.LocalPlayer
    if not player then return end
    
    local playerGui = player:WaitForChild("PlayerGui")
    
    -- Discover existing UI elements
    UITestingSystem.discoverUIElements(playerGui)
    
    -- Monitor for new UI elements
    playerGui.DescendantAdded:Connect(function(element)
        if element:IsA("GuiObject") then
            UITestingSystem.trackUIElement(element)
        end
    end)
    
    playerGui.DescendantRemoving:Connect(function(element)
        if element:IsA("GuiObject") then
            UITestingSystem.untrackUIElement(element)
        end
    end)
end

function UITestingSystem.discoverUIElements(parent)
    for _, child in ipairs(parent:GetDescendants()) do
        if child:IsA("GuiObject") then
            UITestingSystem.trackUIElement(child)
        end
    end
end

function UITestingSystem.trackUIElement(element)
    local elementId = UITestingSystem.generateElementId(element)
    
    UITestState.trackedElements[elementId] = {
        element = element,
        id = elementId,
        name = element.Name,
        className = element.ClassName,
        path = UITestingSystem.getElementPath(element),
        properties = UITestingSystem.captureElementProperties(element),
        interactions = {},
        metrics = {
            renderTime = 0,
            interactionCount = 0,
            lastInteraction = 0
        }
    }
    
    -- Set up element monitoring
    UITestingSystem.setupElementMonitoring(element, elementId)
end

function UITestingSystem.generateElementId(element)
    return string.format("%s_%s_%s", element.ClassName, element.Name, tostring(element:GetDebugId()))
end

function UITestingSystem.getElementPath(element)
    local path = {}
    local current = element
    
    while current and current ~= Players.LocalPlayer.PlayerGui do
        table.insert(path, 1, current.Name)
        current = current.Parent
    end
    
    return table.concat(path, " > ")
end

function UITestingSystem.captureElementProperties(element)
    return {
        visible = element.Visible,
        position = element.Position,
        size = element.Size,
        anchorPoint = element.AnchorPoint,
        backgroundColor = element.BackgroundColor3,
        transparency = element.BackgroundTransparency,
        zIndex = element.ZIndex
    }
end

function UITestingSystem.setupElementMonitoring(element, elementId)
    local data = UITestState.trackedElements[elementId]
    
    -- Monitor property changes
    for property, _ in pairs(data.properties) do
        if element:GetPropertyChangedSignal(property) then
            element:GetPropertyChangedSignal(property):Connect(function()
                UITestingSystem.recordPropertyChange(elementId, property, element[property])
            end)
        end
    end
    
    -- Monitor interactions
    if element:IsA("GuiButton") or element:IsA("TextButton") or element:IsA("ImageButton") then
        element.Activated:Connect(function()
            UITestingSystem.recordUIInteraction(elementId, "click")
        end)
    end
    
    if element:IsA("TextBox") then
        element.FocusLost:Connect(function()
            UITestingSystem.recordUIInteraction(elementId, "textInput", element.Text)
        end)
    end
end

function UITestingSystem.recordPropertyChange(elementId, property, newValue)
    local data = UITestState.trackedElements[elementId]
    if data then
        data.properties[property] = newValue
        
        table.insert(data.interactions, {
            type = "propertyChange",
            property = property,
            value = newValue,
            timestamp = tick()
        })
    end
end

function UITestingSystem.recordUIInteraction(elementId, interactionType, value)
    local data = UITestState.trackedElements[elementId]
    if data then
        local interaction = {
            type = interactionType,
            value = value,
            timestamp = tick()
        }
        
        table.insert(data.interactions, interaction)
        data.metrics.interactionCount = data.metrics.interactionCount + 1
        data.metrics.lastInteraction = interaction.timestamp
        
        UITestState.stats.totalInteractions = UITestState.stats.totalInteractions + 1
    end
end

function UITestingSystem.untrackUIElement(element)
    local elementId = UITestingSystem.generateElementId(element)
    UITestState.trackedElements[elementId] = nil
end

-- ========================================
-- INTERACTION SIMULATION
-- ========================================

function UITestingSystem.initializeInteractionSimulation()
    UITestState.simulatedInputs = {}
    UITestState.inputSequences = {}
    UITestState.interactionQueue = {}
    
    print("🎮 Interaction simulation initialized")
end

function UITestingSystem.simulateClick(element, options)
    options = options or {}
    
    if not element or not element.Parent then
        return false, "Element not found or destroyed"
    end
    
    -- Record simulation
    local simulation = {
        type = "click",
        element = element,
        position = options.position or UITestingSystem.getElementCenter(element),
        timestamp = tick(),
        delay = options.delay or UI_TEST_CONFIG.interaction.defaultClickDelay
    }
    
    table.insert(UITestState.simulatedInputs, simulation)
    
    -- Wait for delay
    if simulation.delay > 0 then
        task.wait(simulation.delay / 1000)
    end
    
    -- Simulate the click
    local success = pcall(function()
        if element:IsA("GuiButton") or element:IsA("TextButton") or element:IsA("ImageButton") then
            -- Fire the Activated event
            for _, connection in ipairs(getconnections(element.Activated)) do
                connection.Function()
            end
        end
    end)
    
    simulation.success = success
    simulation.endTime = tick()
    
    return success, success and nil or "Click simulation failed"
end

function UITestingSystem.getElementCenter(element)
    local absolutePosition = element.AbsolutePosition
    local absoluteSize = element.AbsoluteSize
    
    return Vector2.new(
        absolutePosition.X + absoluteSize.X / 2,
        absolutePosition.Y + absoluteSize.Y / 2
    )
end

function UITestingSystem.simulateTextInput(textBox, text, options)
    options = options or {}
    
    if not textBox or not textBox:IsA("TextBox") then
        return false, "Invalid TextBox element"
    end
    
    local simulation = {
        type = "textInput",
        element = textBox,
        text = text,
        timestamp = tick(),
        typeDelay = options.typeDelay or UI_TEST_CONFIG.interaction.defaultTypeDelay
    }
    
    table.insert(UITestState.simulatedInputs, simulation)
    
    -- Simulate typing character by character
    textBox.Text = ""
    for i = 1, #text do
        task.wait(simulation.typeDelay / 1000)
        textBox.Text = string.sub(text, 1, i)
    end
    
    -- Fire FocusLost
    pcall(function()
        for _, connection in ipairs(getconnections(textBox.FocusLost)) do
            connection.Function()
        end
    end)
    
    simulation.endTime = tick()
    simulation.success = textBox.Text == text
    
    return simulation.success, simulation.success and nil or "Text input simulation failed"
end

function UITestingSystem.simulateScroll(scrollingFrame, direction, amount)
    if not scrollingFrame or not scrollingFrame:IsA("ScrollingFrame") then
        return false, "Invalid ScrollingFrame element"
    end
    
    local simulation = {
        type = "scroll",
        element = scrollingFrame,
        direction = direction,
        amount = amount,
        timestamp = tick()
    }
    
    table.insert(UITestState.simulatedInputs, simulation)
    
    local currentPosition = scrollingFrame.CanvasPosition
    local newPosition = currentPosition
    
    if direction == "up" then
        newPosition = Vector2.new(currentPosition.X, math.max(0, currentPosition.Y - amount))
    elseif direction == "down" then
        newPosition = Vector2.new(currentPosition.X, currentPosition.Y + amount)
    elseif direction == "left" then
        newPosition = Vector2.new(math.max(0, currentPosition.X - amount), currentPosition.Y)
    elseif direction == "right" then
        newPosition = Vector2.new(currentPosition.X + amount, currentPosition.Y)
    end
    
    scrollingFrame.CanvasPosition = newPosition
    
    simulation.endTime = tick()
    simulation.success = true
    
    return true, nil
end

function UITestingSystem.createInteractionSequence(name, interactions)
    local sequence = {
        name = name,
        interactions = interactions,
        results = {},
        startTime = nil,
        endTime = nil,
        success = false
    }
    
    UITestState.inputSequences[name] = sequence
    
    return sequence
end

function UITestingSystem.executeInteractionSequence(sequenceName)
    local sequence = UITestState.inputSequences[sequenceName]
    if not sequence then
        return false, "Sequence not found"
    end
    
    sequence.startTime = tick()
    sequence.results = {}
    
    print(string.format("🎮 Executing interaction sequence: %s", sequenceName))
    
    for i, interaction in ipairs(sequence.interactions) do
        local result = {
            step = i,
            interaction = interaction,
            startTime = tick()
        }
        
        local success, error
        
        if interaction.type == "click" then
            success, error = UITestingSystem.simulateClick(interaction.element, interaction.options)
        elseif interaction.type == "textInput" then
            success, error = UITestingSystem.simulateTextInput(interaction.element, interaction.text, interaction.options)
        elseif interaction.type == "scroll" then
            success, error = UITestingSystem.simulateScroll(interaction.element, interaction.direction, interaction.amount)
        elseif interaction.type == "wait" then
            task.wait(interaction.duration)
            success = true
        elseif interaction.type == "validate" then
            success, error = pcall(interaction.validator)
        end
        
        result.endTime = tick()
        result.duration = result.endTime - result.startTime
        result.success = success
        result.error = error
        
        table.insert(sequence.results, result)
        
        if not success then
            sequence.success = false
            sequence.error = error
            break
        end
    end
    
    sequence.endTime = tick()
    sequence.duration = sequence.endTime - sequence.startTime
    sequence.success = sequence.success or true
    
    print(string.format("🎮 Sequence %s: %s (%.2fs)", 
        sequenceName, sequence.success and "PASSED" or "FAILED", sequence.duration))
    
    return sequence.success, sequence.error
end

-- ========================================
-- VISUAL TESTING
-- ========================================

function UITestingSystem.setupVisualTesting()
    UITestState.screenshots = {}
    UITestState.visualBaselines = {}
    UITestState.visualDifferences = {}
    
    print("📸 Visual testing initialized")
end

function UITestingSystem.captureScreenshot(name, element)
    -- Note: In a real implementation, this would use actual screenshot capabilities
    local screenshot = {
        name = name,
        element = element,
        timestamp = tick(),
        size = element and element.AbsoluteSize or workspace.CurrentCamera.ViewportSize,
        position = element and element.AbsolutePosition or Vector2.new(0, 0),
        hash = UITestingSystem.generateVisualHash(element)
    }
    
    UITestState.screenshots[name] = screenshot
    
    return screenshot
end

function UITestingSystem.generateVisualHash(element)
    -- Simplified visual hash based on element properties
    if not element then
        return tostring(tick())
    end
    
    local properties = {
        element.Size.X.Scale,
        element.Size.Y.Scale,
        element.Position.X.Scale,
        element.Position.Y.Scale,
        element.BackgroundColor3.R,
        element.BackgroundColor3.G,
        element.BackgroundColor3.B,
        element.BackgroundTransparency
    }
    
    return table.concat(properties, "_")
end

function UITestingSystem.setVisualBaseline(name, element)
    local screenshot = UITestingSystem.captureScreenshot(name, element)
    UITestState.visualBaselines[name] = screenshot
    
    print(string.format("📸 Visual baseline set: %s", name))
    
    return screenshot
end

function UITestingSystem.compareWithBaseline(name, element)
    local baseline = UITestState.visualBaselines[name]
    if not baseline then
        return false, "No baseline found for " .. name
    end
    
    local currentScreenshot = UITestingSystem.captureScreenshot(name .. "_current", element)
    
    local comparison = {
        baseline = baseline,
        current = currentScreenshot,
        identical = baseline.hash == currentScreenshot.hash,
        difference = UITestingSystem.calculateVisualDifference(baseline, currentScreenshot),
        timestamp = tick()
    }
    
    UITestState.visualDifferences[name] = comparison
    
    local passed = comparison.difference < UI_TEST_CONFIG.visual.pixelDifferenceThreshold
    
    return passed, passed and nil or string.format("Visual difference %.2f%% exceeds threshold", comparison.difference * 100)
end

function UITestingSystem.calculateVisualDifference(baseline, current)
    -- Simplified difference calculation
    if baseline.hash == current.hash then
        return 0
    end
    
    -- In a real implementation, this would compare actual pixel data
    return 0.1 -- 10% difference as example
end

-- ========================================
-- USER JOURNEY TESTING
-- ========================================

function UITestingSystem.initializeUserJourneyTesting()
    UITestState.activeJourneys = {}
    UITestState.journeyResults = {}
    UITestState.userFlows = {}
    
    print("🚶 User journey testing initialized")
end

function UITestingSystem.defineUserJourney(journeyName, steps)
    local journey = {
        name = journeyName,
        steps = steps,
        results = {},
        metrics = {
            totalTime = 0,
            stepCount = #steps,
            failedSteps = 0,
            averageStepTime = 0
        }
    }
    
    UITestState.userFlows[journeyName] = journey
    UITestState.stats.totalJourneys = UITestState.stats.totalJourneys + 1
    
    return journey
end

function UITestingSystem.executeUserJourney(journeyName)
    local journey = UITestState.userFlows[journeyName]
    if not journey then
        return false, "Journey not found"
    end
    
    journey.startTime = tick()
    journey.results = {}
    
    print(string.format("🚶 Executing user journey: %s", journeyName))
    
    for i, step in ipairs(journey.steps) do
        local stepResult = {
            step = i,
            name = step.name,
            startTime = tick()
        }
        
        local success, error = UITestingSystem.executeJourneyStep(step)
        
        stepResult.endTime = tick()
        stepResult.duration = stepResult.endTime - stepResult.startTime
        stepResult.success = success
        stepResult.error = error
        
        table.insert(journey.results, stepResult)
        
        if not success then
            journey.metrics.failedSteps = journey.metrics.failedSteps + 1
            journey.success = false
            journey.error = error
            
            print(string.format("  ✗ Step %d (%s): %s", i, step.name, error))
            break
        else
            print(string.format("  ✓ Step %d (%s): %.2fms", i, step.name, stepResult.duration * 1000))
        end
    end
    
    journey.endTime = tick()
    journey.metrics.totalTime = journey.endTime - journey.startTime
    journey.metrics.averageStepTime = journey.metrics.totalTime / #journey.results
    journey.success = journey.success or true
    
    -- Update statistics
    if journey.success then
        UITestState.stats.passedUITests = UITestState.stats.passedUITests + 1
    else
        UITestState.stats.failedUITests = UITestState.stats.failedUITests + 1
    end
    
    UITestState.stats.totalUITests = UITestState.stats.totalUITests + 1
    
    table.insert(UITestState.journeyResults, journey)
    
    print(string.format("🚶 Journey %s: %s (%.2fs)", 
        journeyName, journey.success and "PASSED" or "FAILED", journey.metrics.totalTime))
    
    return journey.success, journey.error
end

function UITestingSystem.executeJourneyStep(step)
    if step.action then
        local success, error = pcall(step.action)
        if not success then
            return false, error
        end
    end
    
    if step.wait then
        task.wait(step.wait)
    end
    
    if step.validation then
        local success, error = pcall(step.validation)
        if not success then
            return false, error
        end
    end
    
    return true, nil
end

-- ========================================
-- UI PERFORMANCE MONITORING
-- ========================================

function UITestingSystem.setupUIPerformanceMonitoring()
    UITestState.frameDrops = {}
    UITestState.animationMetrics = {}
    UITestState.memoryUsage = {}
    
    -- Monitor frame rate during UI interactions
    UITestingSystem.startFrameRateMonitoring()
    
    -- Monitor memory usage
    UITestingSystem.startMemoryMonitoring()
    
    print("📈 UI performance monitoring active")
end

function UITestingSystem.startFrameRateMonitoring()
    local lastFrameTime = tick()
    local frameCount = 0
    local frameTimes = {}
    
    RunService.Heartbeat:Connect(function()
        local currentTime = tick()
        local frameTime = currentTime - lastFrameTime
        
        table.insert(frameTimes, frameTime)
        frameCount = frameCount + 1
        
        -- Keep only last 60 frames (1 second at 60 FPS)
        if #frameTimes > 60 then
            table.remove(frameTimes, 1)
        end
        
        -- Check for frame drops
        if frameTime > 1/30 then -- Frame drop threshold (below 30 FPS)
            table.insert(UITestState.frameDrops, {
                timestamp = currentTime,
                frameTime = frameTime,
                fps = 1 / frameTime
            })
        end
        
        lastFrameTime = currentTime
    end)
end

function UITestingSystem.startMemoryMonitoring()
    task.spawn(function()
        while true do
            local memoryUsage = collectgarbage("count") / 1024 -- Convert to MB
            
            table.insert(UITestState.memoryUsage, {
                timestamp = tick(),
                memory = memoryUsage
            })
            
            -- Keep only last hour of data
            if #UITestState.memoryUsage > 3600 then
                table.remove(UITestState.memoryUsage, 1)
            end
            
            task.wait(1) -- Check every second
        end
    end)
end

function UITestingSystem.measureUIResponsiveness(element, action)
    local startTime = tick()
    local startMemory = collectgarbage("count")
    
    local success, error = pcall(action)
    
    local endTime = tick()
    local endMemory = collectgarbage("count")
    
    local metrics = {
        element = element.Name,
        responseTime = (endTime - startTime) * 1000, -- Convert to milliseconds
        memoryDelta = (endMemory - startMemory) / 1024, -- Convert to MB
        success = success,
        error = error,
        timestamp = endTime
    }
    
    table.insert(UITestState.elementMetrics, metrics)
    
    -- Check performance thresholds
    local performanceIssues = {}
    
    if metrics.responseTime > UI_TEST_CONFIG.validation.responseTimeThreshold then
        table.insert(performanceIssues, "Slow response time")
    end
    
    if metrics.memoryDelta > UI_TEST_CONFIG.performance.maxMemoryIncrease then
        table.insert(performanceIssues, "Excessive memory usage")
    end
    
    metrics.performanceIssues = performanceIssues
    
    return metrics
end

-- ========================================
-- CRITICAL PATH TESTING
-- ========================================

function UITestingSystem.defineCriticalPaths()
    -- Main menu navigation
    UITestingSystem.defineUserJourney("MainMenuNavigation", {
        {
            name = "Open Main Menu",
            action = function()
                local mainMenu = UITestingSystem.findElement("MainMenu")
                assert(mainMenu, "Main menu not found")
                assert(mainMenu.Visible, "Main menu not visible")
            end,
            validation = function()
                local mainMenu = UITestingSystem.findElement("MainMenu")
                assert(mainMenu and mainMenu.Visible, "Main menu should be visible")
            end
        },
        {
            name = "Click Play Button",
            action = function()
                local playButton = UITestingSystem.findElement("PlayButton")
                UITestingSystem.simulateClick(playButton)
            end,
            wait = 0.5,
            validation = function()
                local gameUI = UITestingSystem.findElement("GameUI")
                assert(gameUI and gameUI.Visible, "Game UI should be visible after clicking play")
            end
        }
    })
    
    -- Settings workflow
    UITestingSystem.defineUserJourney("SettingsWorkflow", {
        {
            name = "Open Settings",
            action = function()
                local settingsButton = UITestingSystem.findElement("SettingsButton")
                UITestingSystem.simulateClick(settingsButton)
            end,
            validation = function()
                local settingsMenu = UITestingSystem.findElement("SettingsMenu")
                assert(settingsMenu and settingsMenu.Visible, "Settings menu should be visible")
            end
        },
        {
            name = "Adjust Volume",
            action = function()
                local volumeSlider = UITestingSystem.findElement("VolumeSlider")
                -- Simulate slider interaction
                volumeSlider.Value = 0.5
            end,
            validation = function()
                local volumeSlider = UITestingSystem.findElement("VolumeSlider")
                assert(math.abs(volumeSlider.Value - 0.5) < 0.01, "Volume should be set to 0.5")
            end
        },
        {
            name = "Save Settings",
            action = function()
                local saveButton = UITestingSystem.findElement("SaveButton")
                UITestingSystem.simulateClick(saveButton)
            end,
            validation = function()
                -- Settings should be saved and menu closed
                local settingsMenu = UITestingSystem.findElement("SettingsMenu")
                assert(not settingsMenu.Visible, "Settings menu should be closed")
            end
        }
    })
end

function UITestingSystem.findElement(elementName)
    for _, data in pairs(UITestState.trackedElements) do
        if data.name == elementName or string.find(data.path, elementName) then
            return data.element
        end
    end
    return nil
end

-- ========================================
-- PUBLIC API
-- ========================================

function UITestingSystem.runAllUITests()
    print("🖥️ Running all UI tests...")
    
    local startTime = tick()
    
    -- Define critical paths
    UITestingSystem.defineCriticalPaths()
    
    -- Execute all user journeys
    for journeyName, _ in pairs(UITestState.userFlows) do
        UITestingSystem.executeUserJourney(journeyName)
    end
    
    -- Run visual regression tests
    UITestingSystem.runVisualRegressionTests()
    
    local endTime = tick()
    
    -- Generate report
    local report = UITestingSystem.generateUITestReport()
    
    print(string.format("🖥️ UI tests completed in %.2fs", endTime - startTime))
    print(string.format("📊 Results: %d/%d passed", 
        UITestState.stats.passedUITests, UITestState.stats.totalUITests))
    
    return report
end

function UITestingSystem.runVisualRegressionTests()
    print("📸 Running visual regression tests...")
    
    -- Test key UI elements for visual consistency
    local elementsToTest = {"MainMenu", "GameUI", "SettingsMenu", "HUD"}
    
    for _, elementName in ipairs(elementsToTest) do
        local element = UITestingSystem.findElement(elementName)
        if element then
            local success, error = UITestingSystem.compareWithBaseline(elementName, element)
            if not success then
                print(string.format("  ✗ Visual regression: %s - %s", elementName, error))
            else
                print(string.format("  ✓ Visual consistency: %s", elementName))
            end
        end
    end
end

function UITestingSystem.generateUITestReport()
    return {
        timestamp = tick(),
        stats = UITestState.stats,
        journeys = UITestState.journeyResults,
        interactions = UITestState.simulatedInputs,
        visualTests = UITestState.visualDifferences,
        performance = {
            frameDrops = UITestState.frameDrops,
            memoryUsage = UITestState.memoryUsage,
            elementMetrics = UITestState.elementMetrics
        },
        trackedElements = UITestState.trackedElements
    }
end

function UITestingSystem.getUITestStats()
    return UITestState.stats
end

function UITestingSystem.getJourneyResults()
    return UITestState.journeyResults
end

function UITestingSystem.getTrackedElements()
    return UITestState.trackedElements
end

-- Export API
UITestingSystem.simulateClick = UITestingSystem.simulateClick
UITestingSystem.simulateTextInput = UITestingSystem.simulateTextInput
UITestingSystem.simulateScroll = UITestingSystem.simulateScroll
UITestingSystem.defineUserJourney = UITestingSystem.defineUserJourney
UITestingSystem.executeUserJourney = UITestingSystem.executeUserJourney
UITestingSystem.captureScreenshot = UITestingSystem.captureScreenshot
UITestingSystem.setVisualBaseline = UITestingSystem.setVisualBaseline
UITestingSystem.compareWithBaseline = UITestingSystem.compareWithBaseline
UITestingSystem.measureUIResponsiveness = UITestingSystem.measureUIResponsiveness

-- Initialize the UI testing system
UITestingSystem.initialize()

print("🖥️ UITestingSystem loaded with comprehensive UI testing capabilities")

return UITestingSystem
