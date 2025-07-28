-- TutorialController.luau
-- Client-side controller for How to Play tutorial UI and interactive onboarding

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local SafeRequire = require(ReplicatedStorage.Shared.utils.SafeRequire)
local RemoteEvents = SafeRequire.require(ReplicatedStorage.Shared.modules.RemoteEvents)

local TutorialController = {}

-- UI Elements
local tutorialGui = nil
local mainFrame = nil
local currentSectionIndex = 1
local tutorialSections = {}

-- Interactive tutorial elements
local movementGuide = nil
local highlightFrame = nil
local actionPrompt = nil
local tutorialArrow = nil

-- Tutorial state
local isInInteractiveTutorial = false
local currentTutorialStep = 1
local tutorialSteps = {}

function TutorialController:CreateInteractiveElements()
    -- Create movement guide overlay
    movementGuide = Instance.new("ScreenGui")
    movementGuide.Name = "MovementGuide"
    movementGuide.ResetOnSpawn = false
    movementGuide.Enabled = false
    movementGuide.Parent = playerGui
    
    -- Movement instruction frame
    local moveFrame = Instance.new("Frame")
    moveFrame.Size = UDim2.new(0, 300, 0, 150)
    moveFrame.Position = UDim2.new(0, 20, 1, -170)
    moveFrame.BackgroundColor3 = Color3.new(0, 0, 0)
    moveFrame.BackgroundTransparency = 0.3
    moveFrame.BorderSizePixel = 0
    moveFrame.Parent = movementGuide
    
    local moveCorner = Instance.new("UICorner")
    moveCorner.CornerRadius = UDim.new(0, 10)
    moveCorner.Parent = moveFrame
    
    local moveText = Instance.new("TextLabel")
    moveText.Name = "MoveText"
    moveText.Size = UDim2.new(1, -20, 1, -20)
    moveText.Position = UDim2.new(0, 10, 0, 10)
    moveText.BackgroundTransparency = 1
    moveText.Text = "🎮 Use WASD to move around"
    moveText.TextColor3 = Color3.new(1, 1, 1)
    moveText.TextScaled = true
    moveText.Font = Enum.Font.SourceSansBold
    moveText.TextWrapped = true
    moveText.Parent = moveFrame
    
    -- Highlight frame for UI elements
    highlightFrame = Instance.new("Frame")
    highlightFrame.Name = "HighlightFrame"
    highlightFrame.Size = UDim2.new(0, 100, 0, 100)
    highlightFrame.BackgroundColor3 = Color3.new(1, 1, 0)
    highlightFrame.BackgroundTransparency = 0.7
    highlightFrame.BorderSizePixel = 0
    highlightFrame.Visible = false
    highlightFrame.ZIndex = 1000
    highlightFrame.Parent = movementGuide
    
    local highlightCorner = Instance.new("UICorner")
    highlightCorner.CornerRadius = UDim.new(0, 8)
    highlightCorner.Parent = highlightFrame
    
    -- Action prompt
    actionPrompt = Instance.new("Frame")
    actionPrompt.Size = UDim2.new(0, 350, 0, 100)
    actionPrompt.Position = UDim2.new(0.5, -175, 0.8, 0)
    actionPrompt.BackgroundColor3 = Color3.new(0.1, 0.7, 0.1)
    actionPrompt.BorderSizePixel = 0
    actionPrompt.Visible = false
    actionPrompt.ZIndex = 1001
    actionPrompt.Parent = movementGuide
    
    local promptCorner = Instance.new("UICorner")
    promptCorner.CornerRadius = UDim.new(0, 12)
    promptCorner.Parent = actionPrompt
    
    local promptText = Instance.new("TextLabel")
    promptText.Name = "PromptText"
    promptText.Size = UDim2.new(1, -20, 1, -20)
    promptText.Position = UDim2.new(0, 10, 0, 10)
    promptText.BackgroundTransparency = 1
    promptText.Text = "Press SPACE to continue"
    promptText.TextColor3 = Color3.new(1, 1, 1)
    promptText.TextScaled = true
    promptText.Font = Enum.Font.SourceSansBold
    promptText.Parent = actionPrompt
    
    -- Tutorial arrow
    tutorialArrow = Instance.new("ImageLabel")
    tutorialArrow.Name = "TutorialArrow"
    tutorialArrow.Size = UDim2.new(0, 50, 0, 50)
    tutorialArrow.BackgroundTransparency = 1
    tutorialArrow.Image = "rbxasset://textures/ui/GuiImagePlaceholder.png" -- Use arrow image
    tutorialArrow.ImageColor3 = Color3.new(1, 1, 0)
    tutorialArrow.Visible = false
    tutorialArrow.ZIndex = 1002
    tutorialArrow.Parent = movementGuide
end

function TutorialController:ShowMovementGuide(message)
    if not movementGuide then return end
    
    movementGuide.Enabled = true
    local moveText = movementGuide:FindFirstChild("MoveText", true)
    if moveText then
        moveText.Text = message or "🎮 Use WASD to move around"
    end
    
    -- Animate in
    local moveFrame = movementGuide:FindFirstChild("Frame")
    if moveFrame then
        moveFrame.Position = UDim2.new(0, -320, 1, -170)
        local slideTween = TweenService:Create(
            moveFrame,
            TweenInfo.new(0.5, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
            {Position = UDim2.new(0, 20, 1, -170)}
        )
        slideTween:Play()
    end
end

function TutorialController:HideMovementGuide()
    if not movementGuide then return end
    
    local moveFrame = movementGuide:FindFirstChild("Frame")
    if moveFrame then
        local slideTween = TweenService:Create(
            moveFrame,
            TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
            {Position = UDim2.new(0, -320, 1, -170)}
        )
        slideTween:Play()
        slideTween.Completed:Connect(function()
            movementGuide.Enabled = false
        end)
    end
end

function TutorialController:HighlightUIElement(element, message)
    if not highlightFrame or not element then return end
    
    highlightFrame.Size = UDim2.new(0, element.AbsoluteSize.X + 20, 0, element.AbsoluteSize.Y + 20)
    highlightFrame.Position = UDim2.new(0, element.AbsolutePosition.X - 10, 0, element.AbsolutePosition.Y - 10)
    highlightFrame.Visible = true
    
    -- Pulsing animation
    local pulseTween = TweenService:Create(
        highlightFrame,
        TweenInfo.new(1, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true),
        {BackgroundTransparency = 0.3}
    )
    pulseTween:Play()
    
    if message then
        self:ShowActionPrompt(message)
    end
end

function TutorialController:ClearHighlight()
    if highlightFrame then
        highlightFrame.Visible = false
    end
    self:HideActionPrompt()
end

function TutorialController:ShowActionPrompt(message)
    if not actionPrompt then return end
    
    local promptText = actionPrompt:FindFirstChild("PromptText", true)
    if promptText then
        promptText.Text = message
    end
    
    actionPrompt.Visible = true
    actionPrompt.Position = UDim2.new(0.5, -175, 1, 0)
    
    local slideTween = TweenService:Create(
        actionPrompt,
        TweenInfo.new(0.5, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
        {Position = UDim2.new(0.5, -175, 0.8, 0)}
    )
    slideTween:Play()
end

function TutorialController:HideActionPrompt()
    if not actionPrompt then return end
    
    local slideTween = TweenService:Create(
        actionPrompt,
        TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
        {Position = UDim2.new(0.5, -175, 1, 0)}
    )
    slideTween:Play()
    slideTween.Completed:Connect(function()
        actionPrompt.Visible = false
    end)
end

function TutorialController:ShowArrowToObject(targetObject, message)
    if not tutorialArrow or not targetObject then return end
    
    tutorialArrow.Visible = true
    
    -- Point arrow towards target
    local connection
    connection = RunService.Heartbeat:Connect(function()
        if not targetObject or not targetObject.Parent then
            connection:Disconnect()
            tutorialArrow.Visible = false
            return
        end
        
        local targetPos = targetObject.AbsolutePosition
        local targetSize = targetObject.AbsoluteSize
        
        tutorialArrow.Position = UDim2.new(0, targetPos.X + targetSize.X/2 - 25, 0, targetPos.Y - 60)
    end)
    
    -- Bouncing animation
    local bounceTween = TweenService:Create(
        tutorialArrow,
        TweenInfo.new(0.5, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true),
        {Size = UDim2.new(0, 60, 0, 60)}
    )
    bounceTween:Play()
    
    if message then
        self:ShowActionPrompt(message)
    end
end

function TutorialController:HideArrow()
    if tutorialArrow then
        tutorialArrow.Visible = false
    end
end
    -- Create main GUI
    tutorialGui = Instance.new("ScreenGui")
    tutorialGui.Name = "TutorialGui"
    tutorialGui.ResetOnSpawn = false
    tutorialGui.Parent = playerGui
    
    -- Background overlay
    local overlay = Instance.new("Frame")
    overlay.Size = UDim2.new(1, 0, 1, 0)
    overlay.Position = UDim2.new(0, 0, 0, 0)
    overlay.BackgroundColor3 = Color3.new(0, 0, 0)
    overlay.BackgroundTransparency = 0.5
    overlay.BorderSizePixel = 0
    overlay.Visible = false
    overlay.Parent = tutorialGui
    
    -- Main tutorial frame
    mainFrame = Instance.new("Frame")
    mainFrame.Size = UDim2.new(0, 700, 0, 500)
    mainFrame.Position = UDim2.new(0.5, -350, 0.5, -250)
    mainFrame.BackgroundColor3 = Color3.new(0.95, 0.95, 0.9)
    mainFrame.BorderSizePixel = 0
    mainFrame.Visible = false
    mainFrame.Parent = tutorialGui
    
    -- Add book-like appearance
    local bookCorner = Instance.new("UICorner")
    bookCorner.CornerRadius = UDim.new(0, 15)
    bookCorner.Parent = mainFrame
    
    local bookGradient = Instance.new("UIGradient")
    bookGradient.Color = ColorSequence.new{
        ColorSequenceKeypoint.new(0, Color3.new(1, 0.98, 0.9)),
        ColorSequenceKeypoint.new(0.5, Color3.new(0.95, 0.95, 0.9)),
        ColorSequenceKeypoint.new(1, Color3.new(0.9, 0.9, 0.85))
    }
    bookGradient.Rotation = 45
    bookGradient.Parent = mainFrame
    
    -- Book binding effect
    local binding = Instance.new("Frame")
    binding.Size = UDim2.new(0, 20, 1, 0)
    binding.Position = UDim2.new(0, 0, 0, 0)
    binding.BackgroundColor3 = Color3.new(0.6, 0.3, 0.1)
    binding.BorderSizePixel = 0
    binding.Parent = mainFrame
    
    local bindingCorner = Instance.new("UICorner")
    bindingCorner.CornerRadius = UDim.new(0, 15)
    bindingCorner.Parent = binding
    
    -- Title header
    local titleFrame = Instance.new("Frame")
    titleFrame.Size = UDim2.new(1, -40, 0, 80)
    titleFrame.Position = UDim2.new(0, 30, 0, 10)
    titleFrame.BackgroundColor3 = Color3.new(0.1, 0.3, 0.6)
    titleFrame.BorderSizePixel = 0
    titleFrame.Parent = mainFrame
    
    local titleCorner = Instance.new("UICorner")
    titleCorner.CornerRadius = UDim.new(0, 10)
    titleCorner.Parent = titleFrame
    
    local titleLabel = Instance.new("TextLabel")
    titleLabel.Size = UDim2.new(1, 0, 1, 0)
    titleLabel.BackgroundTransparency = 1
    titleLabel.Text = "📚 HOW TO PLAY COLOR RUSH"
    titleLabel.TextColor3 = Color3.new(1, 1, 1)
    titleLabel.TextScaled = true
    titleLabel.Font = Enum.Font.SourceSansBold
    titleLabel.TextStrokeTransparency = 0
    titleLabel.TextStrokeColor3 = Color3.new(0, 0, 0)
    titleLabel.Parent = titleFrame
    
    -- Content area
    local contentFrame = Instance.new("Frame")
    contentFrame.Size = UDim2.new(1, -60, 1, -200)
    contentFrame.Position = UDim2.new(0, 30, 0, 100)
    contentFrame.BackgroundTransparency = 1
    contentFrame.Parent = mainFrame
    
    -- Section title
    local sectionTitle = Instance.new("TextLabel")
    sectionTitle.Name = "SectionTitle"
    sectionTitle.Size = UDim2.new(1, 0, 0, 50)
    sectionTitle.Position = UDim2.new(0, 0, 0, 0)
    sectionTitle.BackgroundTransparency = 1
    sectionTitle.Text = ""
    sectionTitle.TextColor3 = Color3.new(0.1, 0.1, 0.4)
    sectionTitle.TextScaled = true
    sectionTitle.Font = Enum.Font.SourceSansBold
    sectionTitle.TextXAlignment = Enum.TextXAlignment.Left
    sectionTitle.Parent = contentFrame
    
    -- Content scroll frame
    local scrollFrame = Instance.new("ScrollingFrame")
    scrollFrame.Name = "ContentScroll"
    scrollFrame.Size = UDim2.new(1, 0, 1, -60)
    scrollFrame.Position = UDim2.new(0, 0, 0, 60)
    scrollFrame.BackgroundTransparency = 1
    scrollFrame.BorderSizePixel = 0
    scrollFrame.ScrollBarThickness = 8
    scrollFrame.ScrollBarImageColor3 = Color3.new(0.6, 0.6, 0.6)
    scrollFrame.Parent = contentFrame
    
    -- Content text
    local contentText = Instance.new("TextLabel")
    contentText.Name = "ContentText"
    contentText.Size = UDim2.new(1, -20, 1, 0)
    contentText.Position = UDim2.new(0, 10, 0, 0)
    contentText.BackgroundTransparency = 1
    contentText.Text = ""
    contentText.TextColor3 = Color3.new(0.2, 0.2, 0.2)
    contentText.TextSize = 18
    contentText.Font = Enum.Font.SourceSans
    contentText.TextWrapped = true
    contentText.TextXAlignment = Enum.TextXAlignment.Left
    contentText.TextYAlignment = Enum.TextYAlignment.Top
    contentText.Parent = scrollFrame
    
    -- Navigation buttons
    local navFrame = Instance.new("Frame")
    navFrame.Size = UDim2.new(1, -60, 0, 60)
    navFrame.Position = UDim2.new(0, 30, 1, -70)
    navFrame.BackgroundTransparency = 1
    navFrame.Parent = mainFrame
    
    -- Previous button
    local prevButton = Instance.new("TextButton")
    prevButton.Name = "PrevButton"
    prevButton.Size = UDim2.new(0, 100, 0, 40)
    prevButton.Position = UDim2.new(0, 0, 0, 10)
    prevButton.BackgroundColor3 = Color3.new(0.3, 0.6, 0.3)
    prevButton.Text = "◀ Previous"
    prevButton.TextColor3 = Color3.new(1, 1, 1)
    prevButton.TextScaled = true
    prevButton.Font = Enum.Font.SourceSansBold
    prevButton.Parent = navFrame
    
    local prevCorner = Instance.new("UICorner")
    prevCorner.CornerRadius = UDim.new(0, 8)
    prevCorner.Parent = prevButton
    
    -- Next button
    local nextButton = Instance.new("TextButton")
    nextButton.Name = "NextButton"
    nextButton.Size = UDim2.new(0, 100, 0, 40)
    nextButton.Position = UDim2.new(1, -100, 0, 10)
    nextButton.BackgroundColor3 = Color3.new(0.3, 0.6, 0.3)
    nextButton.Text = "Next ▶"
    nextButton.TextColor3 = Color3.new(1, 1, 1)
    nextButton.TextScaled = true
    nextButton.Font = Enum.Font.SourceSansBold
    nextButton.Parent = navFrame
    
    local nextCorner = Instance.new("UICorner")
    nextCorner.CornerRadius = UDim.new(0, 8)
    nextCorner.Parent = nextButton
    
    -- Page indicator
    local pageIndicator = Instance.new("TextLabel")
    pageIndicator.Name = "PageIndicator"
    pageIndicator.Size = UDim2.new(0, 200, 0, 40)
    pageIndicator.Position = UDim2.new(0.5, -100, 0, 10)
    pageIndicator.BackgroundTransparency = 1
    pageIndicator.Text = "1 / 5"
    pageIndicator.TextColor3 = Color3.new(0.4, 0.4, 0.4)
    pageIndicator.TextScaled = true
    pageIndicator.Font = Enum.Font.SourceSansItalic
    pageIndicator.Parent = navFrame
    
    -- Close button
    local closeButton = Instance.new("TextButton")
    closeButton.Size = UDim2.new(0, 40, 0, 40)
    closeButton.Position = UDim2.new(1, -50, 0, 10)
    closeButton.BackgroundColor3 = Color3.new(0.8, 0.3, 0.3)
    closeButton.Text = "✕"
    closeButton.TextColor3 = Color3.new(1, 1, 1)
    closeButton.TextScaled = true
    closeButton.Font = Enum.Font.SourceSansBold
    closeButton.Parent = mainFrame
    
    local closeCorner = Instance.new("UICorner")
    closeCorner.CornerRadius = UDim.new(0, 8)
    closeCorner.Parent = closeButton
    
    -- Connect button events
    prevButton.MouseButton1Click:Connect(function()
        self:PreviousSection()
    end)
    
    nextButton.MouseButton1Click:Connect(function()
        self:NextSection()
    end)
    
    closeButton.MouseButton1Click:Connect(function()
        self:HideTutorial()
    end)
    
    -- Store UI references
    tutorialGui.Overlay = overlay
    tutorialGui.MainFrame = mainFrame
end

function TutorialController:UpdateSection()
    if not mainFrame or not tutorialSections[currentSectionIndex] then return end
    
    local section = tutorialSections[currentSectionIndex]
    local sectionTitle = mainFrame:FindFirstChild("SectionTitle", true)
    local contentText = mainFrame:FindFirstChild("ContentText", true)
    local pageIndicator = mainFrame:FindFirstChild("PageIndicator", true)
    local prevButton = mainFrame:FindFirstChild("PrevButton", true)
    local nextButton = mainFrame:FindFirstChild("NextButton", true)
    
    if sectionTitle then
        sectionTitle.Text = section.title
    end
    
    if contentText then
        local contentString = ""
        for i, line in pairs(section.content) do
            contentString = contentString .. line
            if i < #section.content then
                contentString = contentString .. "\n\n"
            end
        end
        contentText.Text = contentString
        
        -- Update scroll frame canvas size
        local scrollFrame = contentText.Parent
        scrollFrame.CanvasSize = UDim2.new(0, 0, 0, contentText.TextBounds.Y + 20)
    end
    
    if pageIndicator then
        pageIndicator.Text = currentSectionIndex .. " / " .. #tutorialSections
    end
    
    -- Update button states
    if prevButton then
        prevButton.BackgroundColor3 = currentSectionIndex > 1 and Color3.new(0.3, 0.6, 0.3) or Color3.new(0.5, 0.5, 0.5)
        prevButton.Active = currentSectionIndex > 1
    end
    
    if nextButton then
        if currentSectionIndex < #tutorialSections then
            nextButton.Text = "Next ▶"
            nextButton.BackgroundColor3 = Color3.new(0.3, 0.6, 0.3)
        else
            nextButton.Text = "Done! ✓"
            nextButton.BackgroundColor3 = Color3.new(0.6, 0.3, 0.8)
        end
    end
end

function TutorialController:PreviousSection()
    if currentSectionIndex > 1 then
        currentSectionIndex = currentSectionIndex - 1
        self:UpdateSection()
        self:PlayPageTurnSound()
    end
end

function TutorialController:NextSection()
    if currentSectionIndex < #tutorialSections then
        currentSectionIndex = currentSectionIndex + 1
        self:UpdateSection()
        self:PlayPageTurnSound()
    else
        -- Done with tutorial
        self:HideTutorial()
        
        -- If this was the new player tutorial, notify server of completion
        if tutorialSections and #tutorialSections > 0 and tutorialSections[1].title and string.find(tutorialSections[1].title, "Welcome to Color Rush") then
            RemoteEvents.CompleteTutorial:FireServer()
            print("🎓 New player tutorial completed!")
        end
    end
end

function TutorialController:ShowTutorial(sections)
    tutorialSections = sections or {}
    currentSectionIndex = 1
    
    if not mainFrame or #tutorialSections == 0 then return end
    
    -- Show overlay and main frame
    local overlay = tutorialGui.Overlay
    overlay.Visible = true
    mainFrame.Visible = true
    
    -- Reset frame for animation
    mainFrame.Size = UDim2.new(0, 0, 0, 0)
    mainFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
    
    -- Animate in
    local showTween = TweenService:Create(
        mainFrame,
        TweenInfo.new(0.5, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
        {
            Size = UDim2.new(0, 700, 0, 500),
            Position = UDim2.new(0.5, -350, 0.5, -250)
        }
    )
    showTween:Play()
    
    -- Update content
    self:UpdateSection()
    
    -- Play open sound
    self:PlaySound("rbxasset://sounds/electronicpingshort.wav")
    
    print("📚 Tutorial opened")
end

function TutorialController:HideTutorial()
    if not mainFrame or not mainFrame.Visible then return end
    
    -- Check if this was the new player tutorial being skipped/closed
    local wasNewPlayerTutorial = tutorialSections and #tutorialSections > 0 and tutorialSections[1].title and string.find(tutorialSections[1].title, "Welcome to Color Rush")
    
    local overlay = tutorialGui.Overlay
    
    -- Animate out
    local hideTween = TweenService:Create(
        mainFrame,
        TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.In),
        {
            Size = UDim2.new(0, 0, 0, 0),
            Position = UDim2.new(0.5, 0, 0.5, 0)
        }
    )
    
    hideTween:Play()
    hideTween.Completed:Connect(function()
        mainFrame.Visible = false
        overlay.Visible = false
        
        -- If new player tutorial was skipped or completed, notify server
        if wasNewPlayerTutorial then
            RemoteEvents.CompleteTutorial:FireServer()
            print("🎓 New player tutorial completed/skipped!")
        end
    end)
    
    -- Play close sound
    self:PlaySound("rbxasset://sounds/pop_mid_down.wav")
    
    print("📚 Tutorial closed")
end

function TutorialController:PlayPageTurnSound()
    self:PlaySound("rbxasset://sounds/pop_low.wav")
end

function TutorialController:PlaySound(soundId)
    local sound = Instance.new("Sound")
    sound.SoundId = soundId
    sound.Volume = 0.3
    sound.Parent = workspace
    sound:Play()
    
    sound.Ended:Connect(function()
        sound:Destroy()
    end)
end

function TutorialController:StartNewPlayerTutorial()
    -- Define interactive tutorial steps
    tutorialSteps = {
        {
            type = "welcome",
            title = "🎉 Welcome to Color Rush!",
            message = "Let's learn the basics! This interactive tutorial will guide you step by step.",
            action = "continue"
        },
        {
            type = "movement",
            title = "🏃‍♂️ Movement Practice",
            message = "First, let's practice moving around. Use WASD or arrow keys to move!",
            action = "move",
            requirement = "player_moved"
        },
        {
            type = "jump",
            title = "🦘 Jumping",
            message = "Great! Now try jumping with the SPACE key.",
            action = "jump",
            requirement = "player_jumped"
        },
        {
            type = "color_introduction",
            title = "🌈 Color System",
            message = "The heart of Color Rush is changing colors! Let's find your color controls.",
            action = "highlight_colors"
        },
        {
            type = "color_practice",
            title = "� Change Your Color",
            message = "Try pressing 1, 2, or 3 to change your color! Watch your character change!",
            action = "color_change",
            requirement = "color_changed"
        },
        {
            type = "shop_introduction", 
            title = "🛍️ The Shop",
            message = "See that glowing shop area? That's where you'll spend coins on upgrades and cosmetics!",
            action = "point_to_shop"
        },
        {
            type = "start_area",
            title = "🚀 Ready to Race",
            message = "The green teleporter area is where runs begin. Ready to try your first race?",
            action = "point_to_start"
        },
        {
            type = "completion",
            title = "� Tutorial Complete!",
            message = "You're ready to play! Remember: match your color to barriers and collect coins. Have fun!",
            action = "complete"
        }
    }
    
    isInInteractiveTutorial = true
    currentTutorialStep = 1
    
    self:StartTutorialStep()
end

function TutorialController:StartTutorialStep()
    local step = tutorialSteps[currentTutorialStep]
    if not step then
        self:CompleteTutorial()
        return
    end
    
    print("🎓 Tutorial Step " .. currentTutorialStep .. ": " .. step.title)
    
    -- Clear previous elements
    self:ClearHighlight()
    self:HideArrow()
    self:HideActionPrompt()
    
    -- Execute step action
    if step.action == "continue" then
        self:ShowActionPrompt("Press SPACE or click to continue")
        
    elseif step.action == "move" then
        self:ShowMovementGuide("🎮 Use WASD or arrow keys to move around. Try it now!")
        self:SetupMovementDetection()
        
    elseif step.action == "jump" then
        self:ShowMovementGuide("🦘 Press SPACE to jump!")
        self:SetupJumpDetection()
        
    elseif step.action == "highlight_colors" then
        self:ShowMovementGuide("🌈 Look for your color controls - usually in the bottom of your screen!")
        self:FindAndHighlightColorControls()
        
    elseif step.action == "color_change" then
        self:ShowMovementGuide("🎨 Press 1, 2, or 3 to change colors! Try it now!")
        self:SetupColorChangeDetection()
        
    elseif step.action == "point_to_shop" then
        self:FindAndPointToShop()
        
    elseif step.action == "point_to_start" then
        self:FindAndPointToStartArea()
        
    elseif step.action == "complete" then
        self:ShowActionPrompt("🎉 Congratulations! Click to claim your welcome bonus!")
    end
end

function TutorialController:NextTutorialStep()
    if not isInInteractiveTutorial then return end
    
    currentTutorialStep = currentTutorialStep + 1
    if currentTutorialStep <= #tutorialSteps then
        wait(1) -- Brief pause between steps
        self:StartTutorialStep()
    else
        self:CompleteTutorial()
    end
end

function TutorialController:SetupMovementDetection()
    local initialPosition = player.Character and player.Character.PrimaryPart and player.Character.PrimaryPart.Position
    
    local connection
    connection = RunService.Heartbeat:Connect(function()
        if not isInInteractiveTutorial or currentTutorialStep ~= 2 then
            connection:Disconnect()
            return
        end
        
        local character = player.Character
        if character and character.PrimaryPart then
            local currentPosition = character.PrimaryPart.Position
            if initialPosition and (currentPosition - initialPosition).Magnitude > 5 then
                connection:Disconnect()
                self:HideMovementGuide()
                self:ShowActionPrompt("✅ Great movement! Press SPACE to continue")
                
                -- Auto-advance after demonstrating movement
                wait(2)
                self:NextTutorialStep()
            end
        end
    end)
end

function TutorialController:SetupJumpDetection()
    local connection
    connection = UserInputService.InputBegan:Connect(function(input, gameProcessed)
        if not isInInteractiveTutorial or currentTutorialStep ~= 3 or gameProcessed then return end
        
        if input.KeyCode == Enum.KeyCode.Space then
            connection:Disconnect()
            self:HideMovementGuide()
            self:ShowActionPrompt("🦘 Perfect jump! Press SPACE to continue")
            
            wait(2)
            self:NextTutorialStep()
        end
    end)
end

function TutorialController:SetupColorChangeDetection()
    local connection
    connection = UserInputService.InputBegan:Connect(function(input, gameProcessed)
        if not isInInteractiveTutorial or currentTutorialStep ~= 5 or gameProcessed then return end
        
        local colorKeys = {Enum.KeyCode.One, Enum.KeyCode.Two, Enum.KeyCode.Three, Enum.KeyCode.Q, Enum.KeyCode.E}
        for _, key in pairs(colorKeys) do
            if input.KeyCode == key then
                connection:Disconnect()
                self:HideMovementGuide()
                self:ShowActionPrompt("🌈 Excellent! You changed colors! Press SPACE to continue")
                
                wait(2)
                self:NextTutorialStep()
                break
            end
        end
    end)
end

function TutorialController:FindAndHighlightColorControls()
    -- Look for common color control UI elements
    spawn(function()
        wait(1)
        
        -- Check for color GUI elements
        local colorGui = playerGui:FindFirstChild("ColorGui") or playerGui:FindFirstChild("GameUI")
        if colorGui then
            local colorFrame = colorGui:FindFirstChild("ColorFrame") or colorGui:FindFirstChild("Colors")
            if colorFrame then
                self:HighlightUIElement(colorFrame, "These are your color controls!")
                return
            end
        end
        
        -- Fallback: show generic message
        self:ShowActionPrompt("🌈 Look around your screen for color controls (usually numbered buttons or colored circles)")
        wait(3)
        self:NextTutorialStep()
    end)
end

function TutorialController:FindAndPointToShop()
    spawn(function()
        -- Try to find shop in workspace
        local shopArea = Workspace:FindFirstChild("MarketPlaza") or Workspace:FindFirstChild("Shop")
        if shopArea then
            self:ShowMovementGuide("🛍️ There's the shop area! You'll unlock it after your first run.")
            self:ShowActionPrompt("Press SPACE to continue")
        else
            self:ShowActionPrompt("🛍️ Look around for the shop area - it's usually marked with bright colors! Press SPACE to continue")
        end
        
        wait(3)
        self:NextTutorialStep()
    end)
end

function TutorialController:FindAndPointToStartArea()
    spawn(function()
        -- Try to find start area in workspace
        local startArea = Workspace:FindFirstChild("StartArea") or Workspace:FindFirstChild("TeleportPads")
        if startArea then
            self:ShowMovementGuide("🚀 That's the start area! Step into the green teleporter to begin a race!")
            self:ShowActionPrompt("Press SPACE to finish the tutorial")
        else
            self:ShowActionPrompt("🚀 Look for a green glowing area - that's where races begin! Press SPACE to finish tutorial")
        end
        
        wait(3)
        self:NextTutorialStep()
    end)
end

function TutorialController:CompleteTutorial()
    isInInteractiveTutorial = false
    
    -- Clear all tutorial UI
    self:ClearHighlight()
    self:HideArrow()
    self:HideMovementGuide()
    self:HideActionPrompt()
    
    -- Notify server of completion
    RemoteEvents.CompleteTutorial:FireServer()
    print("🎓 Interactive tutorial completed!")
end

function TutorialController:Initialize()
    print("📚 TutorialController initializing...")
    
    -- Create UI elements
    self:CreateTutorialUI()
    self:CreateInteractiveElements()
    
    -- Connect remote events
    RemoteEvents.ShowTutorial.OnClientEvent:Connect(function(sections)
        self:ShowTutorial(sections)
    end)
    
    RemoteEvents.StartNewPlayerTutorial.OnClientEvent:Connect(function()
        self:StartNewPlayerTutorial()
    end)
    
    -- Handle keyboard shortcuts for traditional tutorial
    UserInputService.InputBegan:Connect(function(input, gameProcessed)
        if gameProcessed then return end
        
        -- Traditional tutorial navigation
        if mainFrame and mainFrame.Visible and not isInInteractiveTutorial then
            if input.KeyCode == Enum.KeyCode.Left or input.KeyCode == Enum.KeyCode.A then
                self:PreviousSection()
            elseif input.KeyCode == Enum.KeyCode.Right or input.KeyCode == Enum.KeyCode.D then
                self:NextSection()
            elseif input.KeyCode == Enum.KeyCode.Escape then
                self:HideTutorial()
            end
        end
        
        -- Interactive tutorial navigation
        if isInInteractiveTutorial then
            if input.KeyCode == Enum.KeyCode.Space then
                local step = tutorialSteps[currentTutorialStep]
                if step and (step.action == "continue" or step.action == "complete") then
                    if step.action == "complete" then
                        self:CompleteTutorial()
                    else
                        self:NextTutorialStep()
                    end
                end
            elseif input.KeyCode == Enum.KeyCode.Escape then
                -- Allow skipping interactive tutorial
                self:CompleteTutorial()
            end
        end
    end)
    
    print("✅ TutorialController initialized!")
end

-- Auto-initialize
TutorialController:Initialize()

return TutorialController
