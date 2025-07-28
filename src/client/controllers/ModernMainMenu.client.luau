-- ModernMainMenu.client.luau
-- Modern main menu replacing placeholder UI elements
-- Mobile-friendly with proper scaling and modern design

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local SoundService = game:GetService("SoundService")

local ModernUISystem = require(ReplicatedStorage.Shared.modules.ModernUISystem)

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local ModernMainMenu = {}

-- Main Menu Configuration
local MENU_CONFIG = {
    -- Layout configuration
    logoSize = UDim2.new(0, 400, 0, 120),
    buttonSize = UDim2.new(0, 200, 0, 60),
    buttonSpacing = 20,
    
    -- Menu sections
    sections = {
        primary = {"play", "modes", "shop"},
        secondary = {"achievements", "leaderboard", "friends"},
        utility = {"settings", "help", "credits"}
    },
    
    -- Background particle effects
    particleCount = 25,
    particleSpeed = 2
}

-- Menu Button Definitions
local MENU_BUTTONS = {
    play = {
        text = "PLAY",
        icon = "play",
        style = "primary",
        description = "Start your Color Rush adventure!",
        action = "startGame"
    },
    
    modes = {
        text = "GAME MODES",
        icon = "star",
        style = "secondary",
        description = "Choose your difficulty",
        action = "openModes"
    },
    
    shop = {
        text = "SHOP",
        icon = "shop",
        style = "secondary",
        description = "Customize your character",
        action = "openShop"
    },
    
    achievements = {
        text = "ACHIEVEMENTS",
        icon = "trophy",
        style = "secondary",
        description = "View your progress",
        action = "openAchievements"
    },
    
    leaderboard = {
        text = "LEADERBOARD",
        icon = "leaderboard",
        style = "secondary",
        description = "Compete with others",
        action = "openLeaderboard"
    },
    
    friends = {
        text = "FRIENDS",
        icon = "friend",
        style = "secondary",
        description = "Connect with players",
        action = "openFriends"
    },
    
    settings = {
        text = "SETTINGS",
        icon = "settings",
        style = "minimal",
        description = "Game preferences",
        action = "openSettings"
    },
    
    help = {
        text = "HELP",
        icon = "help",
        style = "minimal",
        description = "Learn how to play",
        action = "openHelp"
    },
    
    credits = {
        text = "CREDITS",
        icon = "info",
        style = "minimal",
        description = "About the game",
        action = "openCredits"
    }
}

-- UI Elements
local mainMenuGui = nil
local backgroundFrame = nil
local logoFrame = nil
local buttonContainer = nil
local particleSystem = nil

function ModernMainMenu:CreateMainMenu()
    -- Create main ScreenGui
    mainMenuGui = Instance.new("ScreenGui")
    mainMenuGui.Name = "ModernMainMenu"
    mainMenuGui.ResetOnSpawn = false
    mainMenuGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    mainMenuGui.Parent = playerGui
    
    -- Apply mobile optimization
    ModernUISystem.applyMobileOptimization(mainMenuGui)
    
    -- Create animated background
    self:CreateAnimatedBackground()
    
    -- Create main container
    local mainContainer = ModernUISystem.createModernFrame({
        name = "MainMenuContainer",
        style = "mainMenu",
        size = UDim2.new(1, 0, 1, 0),
        position = UDim2.new(0, 0, 0, 0)
    })
    mainContainer.Parent = mainMenuGui
    
    -- Create logo section
    self:CreateLogoSection(mainContainer)
    
    -- Create button sections
    self:CreateButtonSections(mainContainer)
    
    -- Create footer
    self:CreateFooter(mainContainer)
    
    -- Create particle effects
    self:CreateParticleEffects(mainContainer)
    
    -- Animate menu entrance
    self:PlayEntranceAnimation()
    
    print("🎨 Modern Main Menu created with enhanced design!")
end

function ModernMainMenu:CreateAnimatedBackground()
    backgroundFrame = ModernUISystem.createModernFrame({
        name = "AnimatedBackground",
        style = "mainMenu",
        size = UDim2.new(1, 0, 1, 0),
        position = UDim2.new(0, 0, 0, 0)
    })
    backgroundFrame.Parent = mainMenuGui
    
    -- Add animated gradient
    local gradient = Instance.new("UIGradient")
    gradient.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, ModernUISystem.getDesignTokens().colors.primary),
        ColorSequenceKeypoint.new(0.5, ModernUISystem.getDesignTokens().colors.secondary),
        ColorSequenceKeypoint.new(1, ModernUISystem.getDesignTokens().colors.primaryDark)
    })
    gradient.Rotation = 45
    gradient.Parent = backgroundFrame
    
    -- Animate gradient rotation
    spawn(function()
        while backgroundFrame.Parent do
            for rotation = 0, 360, 2 do
                if not backgroundFrame.Parent then break end
                gradient.Rotation = rotation
                wait(0.1)
            end
        end
    end)
end

function ModernMainMenu:CreateLogoSection(parent)
    logoFrame = Instance.new("Frame")
    logoFrame.Name = "LogoSection"
    logoFrame.Size = UDim2.new(1, 0, 0, 200)
    logoFrame.Position = UDim2.new(0, 0, 0, 50)
    logoFrame.BackgroundTransparency = 1
    logoFrame.Parent = parent
    
    -- Game title
    local titleLabel = Instance.new("TextLabel")
    titleLabel.Name = "GameTitle"
    titleLabel.Size = UDim2.new(0, 500, 0, 80)
    titleLabel.Position = UDim2.new(0.5, -250, 0, 20)
    titleLabel.BackgroundTransparency = 1
    titleLabel.Text = "COLOR RUSH"
    titleLabel.TextColor3 = ModernUISystem.getDesignTokens().colors.white
    titleLabel.TextScaled = true
    titleLabel.Font = ModernUISystem.getDesignTokens().fonts.heading
    titleLabel.TextStrokeTransparency = 0.5
    titleLabel.TextStrokeColor3 = ModernUISystem.getDesignTokens().colors.dark
    titleLabel.Parent = logoFrame
    
    -- Subtitle
    local subtitleLabel = Instance.new("TextLabel")
    subtitleLabel.Name = "GameSubtitle"
    subtitleLabel.Size = UDim2.new(0, 400, 0, 30)
    subtitleLabel.Position = UDim2.new(0.5, -200, 0, 110)
    subtitleLabel.BackgroundTransparency = 1
    subtitleLabel.Text = "Match colors, beat the rush!"
    subtitleLabel.TextColor3 = ModernUISystem.getDesignTokens().colors.light
    subtitleLabel.TextScaled = true
    subtitleLabel.Font = ModernUISystem.getDesignTokens().fonts.body
    subtitleLabel.Parent = logoFrame
    
    -- Add logo glow effect
    ModernUISystem.animateElement(titleLabel, "pulse", {
        duration = 2,
        repeatCount = -1,
        reverses = true
    })
end

function ModernMainMenu:CreateButtonSections(parent)
    buttonContainer = Instance.new("Frame")
    buttonContainer.Name = "ButtonContainer"
    buttonContainer.Size = UDim2.new(0, 800, 0, 400)
    buttonContainer.Position = UDim2.new(0.5, -400, 0.5, -100)
    buttonContainer.BackgroundTransparency = 1
    buttonContainer.Parent = parent
    
    -- Primary buttons (large, prominent)
    local primaryFrame = Instance.new("Frame")
    primaryFrame.Name = "PrimaryButtons"
    primaryFrame.Size = UDim2.new(1, 0, 0, 120)
    primaryFrame.Position = UDim2.new(0, 0, 0, 0)
    primaryFrame.BackgroundTransparency = 1
    primaryFrame.Parent = buttonContainer
    
    self:CreateButtonRow(primaryFrame, MENU_CONFIG.sections.primary, "primary", UDim2.new(0, 240, 0, 70))
    
    -- Secondary buttons (medium size)
    local secondaryFrame = Instance.new("Frame")
    secondaryFrame.Name = "SecondaryButtons"
    secondaryFrame.Size = UDim2.new(1, 0, 0, 100)
    secondaryFrame.Position = UDim2.new(0, 0, 0, 140)
    secondaryFrame.BackgroundTransparency = 1
    secondaryFrame.Parent = buttonContainer
    
    self:CreateButtonRow(secondaryFrame, MENU_CONFIG.sections.secondary, "secondary", UDim2.new(0, 200, 0, 50))
    
    -- Utility buttons (small, bottom)
    local utilityFrame = Instance.new("Frame")
    utilityFrame.Name = "UtilityButtons"
    utilityFrame.Size = UDim2.new(1, 0, 0, 60)
    utilityFrame.Position = UDim2.new(0, 0, 0, 260)
    utilityFrame.BackgroundTransparency = 1
    utilityFrame.Parent = buttonContainer
    
    self:CreateButtonRow(utilityFrame, MENU_CONFIG.sections.utility, "minimal", UDim2.new(0, 150, 0, 40))
end

function ModernMainMenu:CreateButtonRow(parent, buttonIds, defaultStyle, buttonSize)
    local buttonCount = #buttonIds
    local totalWidth = buttonCount * buttonSize.X.Offset + (buttonCount - 1) * MENU_CONFIG.buttonSpacing
    local startX = (parent.AbsoluteSize.X - totalWidth) / 2
    
    for i, buttonId in ipairs(buttonIds) do
        local buttonConfig = MENU_BUTTONS[buttonId]
        if buttonConfig then
            local button = ModernUISystem.createModernButton({
                name = buttonConfig.text:gsub(" ", "") .. "Button",
                text = buttonConfig.text,
                style = buttonConfig.style or defaultStyle,
                size = buttonSize,
                position = UDim2.new(0, startX + (i - 1) * (buttonSize.X.Offset + MENU_CONFIG.buttonSpacing), 0.5, -buttonSize.Y.Offset / 2)
            })
            button.Parent = parent
            
            -- Add icon if specified
            if buttonConfig.icon then
                local iconButton = ModernUISystem.createIconButton({
                    name = buttonConfig.text:gsub(" ", "") .. "IconButton",
                    icon = buttonConfig.icon,
                    style = buttonConfig.style or defaultStyle,
                    size = UDim2.new(0, 40, 0, 40),
                    position = UDim2.new(0, -50, 0.5, -20)
                })
                iconButton.Parent = button
            end
            
            -- Add tooltip
            self:AddTooltip(button, buttonConfig.description)
            
            -- Connect button action
            button.MouseButton1Click:Connect(function()
                self:HandleButtonClick(buttonConfig.action, buttonId)
            end)
            
            -- Add entrance animation with delay
            spawn(function()
                wait(i * 0.1)
                ModernUISystem.animateElement(button, "slideInFromBottom", {
                    duration = 0.5
                })
            end)
        end
    end
end

function ModernMainMenu:AddTooltip(button, description)
    local tooltip = ModernUISystem.createModernFrame({
        name = "Tooltip",
        style = "modal",
        size = UDim2.new(0, 200, 0, 40),
        position = UDim2.new(0.5, -100, 0, -50)
    })
    tooltip.Visible = false
    tooltip.Parent = button
    
    local tooltipText = Instance.new("TextLabel")
    tooltipText.Size = UDim2.new(1, -16, 1, -8)
    tooltipText.Position = UDim2.new(0, 8, 0, 4)
    tooltipText.BackgroundTransparency = 1
    tooltipText.Text = description
    tooltipText.TextColor3 = ModernUISystem.getDesignTokens().colors.white
    tooltipText.TextScaled = true
    tooltipText.Font = ModernUISystem.getDesignTokens().fonts.caption
    tooltipText.Parent = tooltip
    
    button.MouseEnter:Connect(function()
        tooltip.Visible = true
        ModernUISystem.animateElement(tooltip, "fadeIn", {duration = 0.2})
    end)
    
    button.MouseLeave:Connect(function()
        tooltip.Visible = false
    end)
end

function ModernMainMenu:CreateFooter(parent)
    local footer = Instance.new("Frame")
    footer.Name = "Footer"
    footer.Size = UDim2.new(1, 0, 0, 60)
    footer.Position = UDim2.new(0, 0, 1, -80)
    footer.BackgroundTransparency = 1
    footer.Parent = parent
    
    -- Version info
    local versionLabel = Instance.new("TextLabel")
    versionLabel.Name = "VersionLabel"
    versionLabel.Size = UDim2.new(0, 200, 0, 30)
    versionLabel.Position = UDim2.new(0, 20, 0, 15)
    versionLabel.BackgroundTransparency = 1
    versionLabel.Text = "Version 2.0 - Enhanced Edition"
    versionLabel.TextColor3 = ModernUISystem.getDesignTokens().colors.medium
    versionLabel.TextScaled = true
    versionLabel.Font = ModernUISystem.getDesignTokens().fonts.caption
    versionLabel.TextXAlignment = Enum.TextXAlignment.Left
    versionLabel.Parent = footer
    
    -- Social links
    local socialFrame = Instance.new("Frame")
    socialFrame.Name = "SocialLinks"
    socialFrame.Size = UDim2.new(0, 300, 0, 50)
    socialFrame.Position = UDim2.new(1, -320, 0, 5)
    socialFrame.BackgroundTransparency = 1
    socialFrame.Parent = footer
    
    local socialButtons = {
        {icon = "share", text = "SHARE", action = "shareGame"},
        {icon = "chat", text = "DISCORD", action = "joinDiscord"},
        {icon = "star", text = "RATE", action = "rateGame"}
    }
    
    for i, social in ipairs(socialButtons) do
        local socialButton = ModernUISystem.createIconButton({
            name = social.text .. "Button",
            icon = social.icon,
            style = "minimal",
            size = UDim2.new(0, 80, 0, 40),
            position = UDim2.new(0, (i - 1) * 90, 0, 5)
        })
        socialButton.Parent = socialFrame
        
        socialButton.MouseButton1Click:Connect(function()
            self:HandleButtonClick(social.action, social.text:lower())
        end)
    end
end

function ModernMainMenu:CreateParticleEffects(parent)
    particleSystem = Instance.new("Frame")
    particleSystem.Name = "ParticleSystem"
    particleSystem.Size = UDim2.new(1, 0, 1, 0)
    particleSystem.BackgroundTransparency = 1
    particleSystem.Parent = parent
    
    -- Create floating particles
    for i = 1, MENU_CONFIG.particleCount do
        local particle = Instance.new("Frame")
        particle.Name = "Particle" .. i
        particle.Size = UDim2.new(0, math.random(4, 12), 0, math.random(4, 12))
        particle.Position = UDim2.new(math.random(), 0, math.random(), 0)
        particle.BackgroundColor3 = ModernUISystem.getDesignTokens().colors.white
        particle.BackgroundTransparency = math.random(50, 90) / 100
        particle.BorderSizePixel = 0
        particle.Parent = particleSystem
        
        local corner = Instance.new("UICorner")
        corner.CornerRadius = UDim.new(1, 0)
        corner.Parent = particle
        
        -- Animate particle floating
        spawn(function()
            while particle.Parent do
                local moveTime = math.random(10, 20)
                local newPosition = UDim2.new(math.random(), 0, math.random(), 0)
                
                local tween = TweenService:Create(
                    particle,
                    TweenInfo.new(moveTime, Enum.EasingStyle.Linear),
                    {Position = newPosition}
                )
                tween:Play()
                tween.Completed:Wait()
            end
        end)
    end
end

function ModernMainMenu:PlayEntranceAnimation()
    -- Animate logo entrance
    ModernUISystem.animateElement(logoFrame, "slideInFromBottom", {
        duration = 0.8
    })
    
    -- Animate background fade in
    ModernUISystem.animateElement(backgroundFrame, "fadeIn", {
        duration = 1.0
    })
    
    -- Play sound effect
    local enterSound = Instance.new("Sound")
    enterSound.SoundId = "rbxasset://sounds/electronicpingshort.wav" -- Replace with custom sound
    enterSound.Volume = 0.3
    enterSound.Parent = SoundService
    enterSound:Play()
    
    enterSound.Ended:Connect(function()
        enterSound:Destroy()
    end)
end

function ModernMainMenu:HandleButtonClick(action, buttonId)
    -- Play click sound
    local clickSound = Instance.new("Sound")
    clickSound.SoundId = "rbxasset://sounds/button-09.mp3" -- Replace with custom sound
    clickSound.Volume = 0.5
    clickSound.Parent = SoundService
    clickSound:Play()
    
    clickSound.Ended:Connect(function()
        clickSound:Destroy()
    end)
    
    -- Handle different actions
    if action == "startGame" then
        self:StartGame()
    elseif action == "openModes" then
        self:OpenGameModes()
    elseif action == "openShop" then
        self:OpenShop()
    elseif action == "openAchievements" then
        self:OpenAchievements()
    elseif action == "openLeaderboard" then
        self:OpenLeaderboard()
    elseif action == "openFriends" then
        self:OpenFriends()
    elseif action == "openSettings" then
        self:OpenSettings()
    elseif action == "openHelp" then
        self:OpenHelp()
    elseif action == "openCredits" then
        self:OpenCredits()
    elseif action == "shareGame" then
        self:ShareGame()
    elseif action == "joinDiscord" then
        self:JoinDiscord()
    elseif action == "rateGame" then
        self:RateGame()
    end
    
    print("🎮 Menu action triggered: " .. action .. " (" .. buttonId .. ")")
end

-- Action handlers (placeholders - implement actual functionality)
function ModernMainMenu:StartGame()
    print("🎮 Starting game...")
    -- Implement game start logic
end

function ModernMainMenu:OpenGameModes()
    print("🎯 Opening game modes...")
    -- Implement game modes UI
end

function ModernMainMenu:OpenShop()
    print("🛒 Opening shop...")
    -- Implement shop UI
end

function ModernMainMenu:OpenAchievements()
    print("🏆 Opening achievements...")
    -- Implement achievements UI
end

function ModernMainMenu:OpenLeaderboard()
    print("📊 Opening leaderboard...")
    -- Implement leaderboard UI
end

function ModernMainMenu:OpenFriends()
    print("👥 Opening friends...")
    -- Implement friends UI
end

function ModernMainMenu:OpenSettings()
    print("⚙️ Opening settings...")
    -- Implement settings UI
end

function ModernMainMenu:OpenHelp()
    print("❓ Opening help...")
    -- Implement help UI
end

function ModernMainMenu:OpenCredits()
    print("ℹ️ Opening credits...")
    -- Implement credits UI
end

function ModernMainMenu:ShareGame()
    print("📤 Sharing game...")
    -- Implement share functionality
end

function ModernMainMenu:JoinDiscord()
    print("💬 Joining Discord...")
    -- Implement Discord integration
end

function ModernMainMenu:RateGame()
    print("⭐ Rating game...")
    -- Implement rating functionality
end

function ModernMainMenu:Hide()
    if mainMenuGui then
        local fadeTween = ModernUISystem.animateElement(mainMenuGui, "fadeIn", {
            duration = 0.5,
            startTransparency = 0,
            endTransparency = 1
        })
        
        fadeTween.Completed:Connect(function()
            mainMenuGui.Enabled = false
        end)
    end
end

function ModernMainMenu:Show()
    if mainMenuGui then
        mainMenuGui.Enabled = true
        ModernUISystem.animateElement(mainMenuGui, "fadeIn", {
            duration = 0.5
        })
    end
end

function ModernMainMenu:Destroy()
    if mainMenuGui then
        mainMenuGui:Destroy()
        mainMenuGui = nil
    end
end

-- Initialize the modern main menu
spawn(function()
    wait(2) -- Wait for everything to load
    ModernMainMenu:CreateMainMenu()
end)

return ModernMainMenu
