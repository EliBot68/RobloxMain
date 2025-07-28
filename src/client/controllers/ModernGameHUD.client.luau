-- ModernGameHUD.client.luau
-- Modern in-game HUD replacing all placeholder UI elements
-- Mobile-optimized with clean design and smooth animations

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local GuiService = game:GetService("GuiService")
local RunService = game:GetService("RunService")

local ModernUISystem = require(ReplicatedStorage.Shared.modules.ModernUISystem)

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local ModernGameHUD = {}

-- HUD Configuration
local HUD_CONFIG = {
    -- Layout settings
    topBarHeight = 80,
    bottomBarHeight = 100,
    sideMargin = 20,
    
    -- Animation settings
    updateInterval = 0.1,
    counterAnimationDuration = 0.3,
    
    -- Mobile optimizations
    mobileScaling = 1.2,
    touchButtonSize = UDim2.new(0, 80, 0, 80),
    
    -- Color coding
    healthColors = {
        high = Color3.fromRGB(46, 204, 113),
        medium = Color3.fromRGB(241, 196, 15),
        low = Color3.fromRGB(231, 76, 60)
    }
}

-- HUD Elements
local gameHUDGui = nil
local topBar = nil
local bottomBar = nil
local centerHUD = nil
local mobileControls = nil

-- Data tracking
local currentStats = {
    score = 0,
    lives = 3,
    time = 0,
    multiplier = 1,
    streak = 0,
    difficulty = 1
}

function ModernGameHUD:CreateGameHUD()
    -- Create main HUD ScreenGui
    gameHUDGui = Instance.new("ScreenGui")
    gameHUDGui.Name = "ModernGameHUD"
    gameHUDGui.ResetOnSpawn = false
    gameHUDGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    gameHUDGui.Parent = playerGui
    
    -- Apply mobile optimization
    ModernUISystem.applyMobileOptimization(gameHUDGui)
    
    -- Create HUD sections
    self:CreateTopBar()
    self:CreateCenterHUD()
    self:CreateBottomBar()
    self:CreateMobileControls()
    
    -- Start update loop
    self:StartUpdateLoop()
    
    -- Play entrance animation
    self:PlayEntranceAnimation()
    
    print("🎮 Modern Game HUD created with enhanced design!")
end

function ModernGameHUD:CreateTopBar()
    topBar = ModernUISystem.createModernFrame({
        name = "TopBar",
        style = "topBar",
        size = UDim2.new(1, 0, 0, HUD_CONFIG.topBarHeight),
        position = UDim2.new(0, 0, 0, 0)
    })
    topBar.Parent = gameHUDGui
    
    -- Score display
    local scoreContainer = self:CreateStatContainer("Score", "0", "star", UDim2.new(0, 200, 1, -10))
    scoreContainer.Position = UDim2.new(0, HUD_CONFIG.sideMargin, 0, 5)
    scoreContainer.Parent = topBar
    
    -- Lives display
    local livesContainer = self:CreateStatContainer("Lives", "3", "heart", UDim2.new(0, 120, 1, -10))
    livesContainer.Position = UDim2.new(0, HUD_CONFIG.sideMargin + 220, 0, 5)
    livesContainer.Parent = topBar
    
    -- Time display
    local timeContainer = self:CreateStatContainer("Time", "0:00", "clock", UDim2.new(0, 120, 1, -10))
    timeContainer.Position = UDim2.new(1, -140, 0, 5)
    timeContainer.Parent = topBar
    
    -- Pause button
    local pauseButton = ModernUISystem.createIconButton({
        name = "PauseButton",
        icon = "pause",
        style = "minimal",
        size = UDim2.new(0, 50, 0, 50),
        position = UDim2.new(1, -70, 0, 15)
    })
    pauseButton.Parent = topBar
    
    pauseButton.MouseButton1Click:Connect(function()
        self:TogglePause()
    end)
end

function ModernGameHUD:CreateCenterHUD()
    centerHUD = Instance.new("Frame")
    centerHUD.Name = "CenterHUD"
    centerHUD.Size = UDim2.new(1, 0, 1, -(HUD_CONFIG.topBarHeight + HUD_CONFIG.bottomBarHeight))
    centerHUD.Position = UDim2.new(0, 0, 0, HUD_CONFIG.topBarHeight)
    centerHUD.BackgroundTransparency = 1
    centerHUD.Parent = gameHUDGui
    
    -- Streak counter (center display)
    local streakDisplay = ModernUISystem.createInfoCard({
        name = "StreakDisplay",
        title = "STREAK",
        value = "0",
        style = "streak",
        size = UDim2.new(0, 150, 0, 80),
        position = UDim2.new(0.5, -75, 0, 50)
    })
    streakDisplay.Parent = centerHUD
    
    -- Multiplier display
    local multiplierDisplay = ModernUISystem.createInfoCard({
        name = "MultiplierDisplay",
        title = "MULTIPLIER",
        value = "x1",
        style = "multiplier",
        size = UDim2.new(0, 150, 0, 80),
        position = UDim2.new(0.5, -75, 0, 150)
    })
    multiplierDisplay.Parent = centerHUD
    
    -- Combo feedback
    local comboFeedback = Instance.new("TextLabel")
    comboFeedback.Name = "ComboFeedback"
    comboFeedback.Size = UDim2.new(0, 300, 0, 60)
    comboFeedback.Position = UDim2.new(0.5, -150, 0.5, -30)
    comboFeedback.BackgroundTransparency = 1
    comboFeedback.Text = ""
    comboFeedback.TextColor3 = ModernUISystem.getDesignTokens().colors.white
    comboFeedback.TextScaled = true
    comboFeedback.Font = ModernUISystem.getDesignTokens().fonts.heading
    comboFeedback.TextStrokeTransparency = 0.5
    comboFeedback.TextStrokeColor3 = ModernUISystem.getDesignTokens().colors.dark
    comboFeedback.Visible = false
    comboFeedback.Parent = centerHUD
    
    -- Progress indicators
    self:CreateProgressIndicators(centerHUD)
end

function ModernGameHUD:CreateBottomBar()
    bottomBar = ModernUISystem.createModernFrame({
        name = "BottomBar",
        style = "bottomBar",
        size = UDim2.new(1, 0, 0, HUD_CONFIG.bottomBarHeight),
        position = UDim2.new(0, 0, 1, -HUD_CONFIG.bottomBarHeight)
    })
    bottomBar.Parent = gameHUDGui
    
    -- Difficulty indicator
    local difficultyContainer = self:CreateStatContainer("Difficulty", "1", "target", UDim2.new(0, 150, 0, 60))
    difficultyContainer.Position = UDim2.new(0, HUD_CONFIG.sideMargin, 0, 20)
    difficultyContainer.Parent = bottomBar
    
    -- Progress bar
    local progressFrame = ModernUISystem.createModernFrame({
        name = "ProgressFrame",
        style = "progressContainer",
        size = UDim2.new(0, 400, 0, 30),
        position = UDim2.new(0.5, -200, 0, 35)
    })
    progressFrame.Parent = bottomBar
    
    local progressBar = ModernUISystem.createModernFrame({
        name = "ProgressBar",
        style = "progressBar",
        size = UDim2.new(0, 0, 1, 0),
        position = UDim2.new(0, 0, 0, 0)
    })
    progressBar.Parent = progressFrame
    
    local progressLabel = Instance.new("TextLabel")
    progressLabel.Name = "ProgressLabel"
    progressLabel.Size = UDim2.new(1, 0, 1, 0)
    progressLabel.BackgroundTransparency = 1
    progressLabel.Text = "LEVEL PROGRESS"
    progressLabel.TextColor3 = ModernUISystem.getDesignTokens().colors.white
    progressLabel.TextScaled = true
    progressLabel.Font = ModernUISystem.getDesignTokens().fonts.caption
    progressLabel.Parent = progressFrame
    
    -- Special ability button
    local abilityButton = ModernUISystem.createModernButton({
        name = "SpecialAbilityButton",
        text = "POWER",
        style = "special",
        size = UDim2.new(0, 120, 0, 60),
        position = UDim2.new(1, -140, 0, 20)
    })
    abilityButton.Parent = bottomBar
    
    abilityButton.MouseButton1Click:Connect(function()
        self:UseSpecialAbility()
    end)
end

function ModernGameHUD:CreateMobileControls()
    -- Only show on mobile devices
    if not UserInputService.TouchEnabled then
        return
    end
    
    mobileControls = Instance.new("Frame")
    mobileControls.Name = "MobileControls"
    mobileControls.Size = UDim2.new(1, 0, 1, 0)
    mobileControls.BackgroundTransparency = 1
    mobileControls.Parent = gameHUDGui
    
    -- Left action button
    local leftActionButton = ModernUISystem.createIconButton({
        name = "LeftActionButton",
        icon = "left",
        style = "mobile",
        size = HUD_CONFIG.touchButtonSize,
        position = UDim2.new(0, 40, 1, -140)
    })
    leftActionButton.Parent = mobileControls
    
    -- Right action button
    local rightActionButton = ModernUISystem.createIconButton({
        name = "RightActionButton",
        icon = "right",
        style = "mobile",
        size = HUD_CONFIG.touchButtonSize,
        position = UDim2.new(1, -120, 1, -140)
    })
    rightActionButton.Parent = mobileControls
    
    -- Jump button
    local jumpButton = ModernUISystem.createIconButton({
        name = "JumpButton",
        icon = "jump",
        style = "mobile",
        size = HUD_CONFIG.touchButtonSize,
        position = UDim2.new(1, -120, 1, -240)
    })
    jumpButton.Parent = mobileControls
    
    -- Connect mobile controls
    leftActionButton.TouchTap:Connect(function()
        self:HandleMobileInput("left")
    end)
    
    rightActionButton.TouchTap:Connect(function()
        self:HandleMobileInput("right")
    end)
    
    jumpButton.TouchTap:Connect(function()
        self:HandleMobileInput("jump")
    end)
end

function ModernGameHUD:CreateStatContainer(title, value, icon, size)
    local container = ModernUISystem.createModernFrame({
        name = title .. "Container",
        style = "statContainer",
        size = size,
        position = UDim2.new(0, 0, 0, 0)
    })
    
    -- Icon
    if icon then
        local iconButton = ModernUISystem.createIconButton({
            name = title .. "Icon",
            icon = icon,
            style = "statIcon",
            size = UDim2.new(0, 30, 0, 30),
            position = UDim2.new(0, 10, 0.5, -15)
        })
        iconButton.Parent = container
    end
    
    -- Title
    local titleLabel = Instance.new("TextLabel")
    titleLabel.Name = title .. "Title"
    titleLabel.Size = UDim2.new(1, -50, 0, 20)
    titleLabel.Position = UDim2.new(0, 45, 0, 5)
    titleLabel.BackgroundTransparency = 1
    titleLabel.Text = title:upper()
    titleLabel.TextColor3 = ModernUISystem.getDesignTokens().colors.medium
    titleLabel.TextScaled = true
    titleLabel.Font = ModernUISystem.getDesignTokens().fonts.caption
    titleLabel.TextXAlignment = Enum.TextXAlignment.Left
    titleLabel.Parent = container
    
    -- Value
    local valueLabel = Instance.new("TextLabel")
    valueLabel.Name = title .. "Value"
    valueLabel.Size = UDim2.new(1, -50, 0, 35)
    valueLabel.Position = UDim2.new(0, 45, 0, 25)
    valueLabel.BackgroundTransparency = 1
    valueLabel.Text = value
    valueLabel.TextColor3 = ModernUISystem.getDesignTokens().colors.white
    valueLabel.TextScaled = true
    valueLabel.Font = ModernUISystem.getDesignTokens().fonts.body
    valueLabel.TextXAlignment = Enum.TextXAlignment.Left
    valueLabel.Parent = container
    
    return container
end

function ModernGameHUD:CreateProgressIndicators(parent)
    -- Health bar
    local healthFrame = ModernUISystem.createModernFrame({
        name = "HealthFrame",
        style = "healthContainer",
        size = UDim2.new(0, 200, 0, 20),
        position = UDim2.new(0, HUD_CONFIG.sideMargin, 1, -40)
    })
    healthFrame.Parent = parent
    
    local healthBar = ModernUISystem.createModernFrame({
        name = "HealthBar",
        style = "healthBar",
        size = UDim2.new(1, 0, 1, 0),
        position = UDim2.new(0, 0, 0, 0)
    })
    healthBar.BackgroundColor3 = HUD_CONFIG.healthColors.high
    healthBar.Parent = healthFrame
    
    -- Energy bar
    local energyFrame = ModernUISystem.createModernFrame({
        name = "EnergyFrame",
        style = "energyContainer",
        size = UDim2.new(0, 200, 0, 15),
        position = UDim2.new(1, -220, 1, -35)
    })
    energyFrame.Parent = parent
    
    local energyBar = ModernUISystem.createModernFrame({
        name = "EnergyBar",
        style = "energyBar",
        size = UDim2.new(1, 0, 1, 0),
        position = UDim2.new(0, 0, 0, 0)
    })
    energyBar.BackgroundColor3 = ModernUISystem.getDesignTokens().colors.info
    energyBar.Parent = energyFrame
end

function ModernGameHUD:StartUpdateLoop()
    spawn(function()
        while gameHUDGui and gameHUDGui.Parent do
            self:UpdateStats()
            wait(HUD_CONFIG.updateInterval)
        end
    end)
end

function ModernGameHUD:UpdateStats()
    -- Update score
    self:UpdateStatValue("Score", self:FormatNumber(currentStats.score))
    
    -- Update lives with color coding
    local livesContainer = topBar:FindFirstChild("LivesContainer")
    if livesContainer then
        local livesValue = livesContainer:FindFirstChild("LivesValue")
        if livesValue then
            livesValue.Text = tostring(currentStats.lives)
            
            -- Color code based on lives remaining
            if currentStats.lives <= 1 then
                livesValue.TextColor3 = HUD_CONFIG.healthColors.low
            elseif currentStats.lives <= 2 then
                livesValue.TextColor3 = HUD_CONFIG.healthColors.medium
            else
                livesValue.TextColor3 = ModernUISystem.getDesignTokens().colors.white
            end
        end
    end
    
    -- Update time
    self:UpdateStatValue("Time", self:FormatTime(currentStats.time))
    
    -- Update streak
    local streakDisplay = centerHUD:FindFirstChild("StreakDisplay")
    if streakDisplay then
        local valueLabel = streakDisplay:FindFirstChild("ValueLabel")
        if valueLabel then
            valueLabel.Text = tostring(currentStats.streak)
        end
    end
    
    -- Update multiplier
    local multiplierDisplay = centerHUD:FindFirstChild("MultiplierDisplay")
    if multiplierDisplay then
        local valueLabel = multiplierDisplay:FindFirstChild("ValueLabel")
        if valueLabel then
            valueLabel.Text = "x" .. tostring(currentStats.multiplier)
        end
    end
    
    -- Update difficulty
    self:UpdateStatValue("Difficulty", tostring(currentStats.difficulty))
end

function ModernGameHUD:UpdateStatValue(statName, newValue)
    local container = topBar:FindFirstChild(statName .. "Container") or bottomBar:FindFirstChild(statName .. "Container")
    if container then
        local valueLabel = container:FindFirstChild(statName .. "Value")
        if valueLabel and valueLabel.Text ~= newValue then
            valueLabel.Text = newValue
            
            -- Animate value change
            ModernUISystem.animateElement(valueLabel, "pulse", {
                duration = HUD_CONFIG.counterAnimationDuration
            })
        end
    end
end

function ModernGameHUD:FormatNumber(number)
    if number >= 1000000 then
        return string.format("%.1fM", number / 1000000)
    elseif number >= 1000 then
        return string.format("%.1fK", number / 1000)
    else
        return tostring(number)
    end
end

function ModernGameHUD:FormatTime(seconds)
    local minutes = math.floor(seconds / 60)
    local remainingSeconds = seconds % 60
    return string.format("%d:%02d", minutes, remainingSeconds)
end

function ModernGameHUD:ShowComboFeedback(text, color)
    local comboFeedback = centerHUD:FindFirstChild("ComboFeedback")
    if comboFeedback then
        comboFeedback.Text = text
        comboFeedback.TextColor3 = color or ModernUISystem.getDesignTokens().colors.white
        comboFeedback.Visible = true
        
        -- Animate feedback
        ModernUISystem.animateElement(comboFeedback, "bounceIn", {
            duration = 0.5
        })
        
        -- Hide after delay
        spawn(function()
            wait(2)
            ModernUISystem.animateElement(comboFeedback, "fadeOut", {
                duration = 0.3
            })
            wait(0.3)
            comboFeedback.Visible = false
        end)
    end
end

function ModernGameHUD:PlayEntranceAnimation()
    -- Animate top bar
    ModernUISystem.animateElement(topBar, "slideInFromTop", {
        duration = 0.6
    })
    
    -- Animate bottom bar
    ModernUISystem.animateElement(bottomBar, "slideInFromBottom", {
        duration = 0.6
    })
    
    -- Animate center elements with delay
    spawn(function()
        wait(0.3)
        ModernUISystem.animateElement(centerHUD, "fadeIn", {
            duration = 0.8
        })
    end)
end

-- Action handlers
function ModernGameHUD:TogglePause()
    print("⏸️ Toggle pause")
    -- Implement pause functionality
end

function ModernGameHUD:UseSpecialAbility()
    print("⚡ Special ability used")
    -- Implement special ability
end

function ModernGameHUD:HandleMobileInput(action)
    print("📱 Mobile input: " .. action)
    -- Implement mobile input handling
end

-- Public methods for updating stats
function ModernGameHUD:SetScore(score)
    currentStats.score = score
end

function ModernGameHUD:SetLives(lives)
    currentStats.lives = lives
end

function ModernGameHUD:SetTime(time)
    currentStats.time = time
end

function ModernGameHUD:SetStreak(streak)
    currentStats.streak = streak
    
    -- Show combo feedback for significant streaks
    if streak > 0 and streak % 5 == 0 then
        self:ShowComboFeedback("STREAK x" .. streak .. "!", ModernUISystem.getDesignTokens().colors.success)
    end
end

function ModernGameHUD:SetMultiplier(multiplier)
    currentStats.multiplier = multiplier
end

function ModernGameHUD:SetDifficulty(difficulty)
    currentStats.difficulty = difficulty
end

function ModernGameHUD:UpdateHealthBar(percentage)
    local healthBar = centerHUD:FindFirstChild("HealthFrame"):FindFirstChild("HealthBar")
    if healthBar then
        local newSize = UDim2.new(percentage / 100, 0, 1, 0)
        
        TweenService:Create(
            healthBar,
            TweenInfo.new(0.3, Enum.EasingStyle.Quad),
            {Size = newSize}
        ):Play()
        
        -- Update color based on health
        if percentage <= 25 then
            healthBar.BackgroundColor3 = HUD_CONFIG.healthColors.low
        elseif percentage <= 50 then
            healthBar.BackgroundColor3 = HUD_CONFIG.healthColors.medium
        else
            healthBar.BackgroundColor3 = HUD_CONFIG.healthColors.high
        end
    end
end

function ModernGameHUD:UpdateEnergyBar(percentage)
    local energyBar = centerHUD:FindFirstChild("EnergyFrame"):FindFirstChild("EnergyBar")
    if energyBar then
        local newSize = UDim2.new(percentage / 100, 0, 1, 0)
        
        TweenService:Create(
            energyBar,
            TweenInfo.new(0.2, Enum.EasingStyle.Quad),
            {Size = newSize}
        ):Play()
    end
end

function ModernGameHUD:Hide()
    if gameHUDGui then
        gameHUDGui.Enabled = false
    end
end

function ModernGameHUD:Show()
    if gameHUDGui then
        gameHUDGui.Enabled = true
    end
end

function ModernGameHUD:Destroy()
    if gameHUDGui then
        gameHUDGui:Destroy()
        gameHUDGui = nil
    end
end

-- Initialize when game starts
spawn(function()
    wait(1) -- Wait for game to initialize
    ModernGameHUD:CreateGameHUD()
end)

return ModernGameHUD
