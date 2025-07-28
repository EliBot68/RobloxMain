-- TutorialController.luau
-- Client-side controller for How to Play tutorial UI

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local RemoteEvents = require(ReplicatedStorage.Shared.modules.RemoteEvents)

local TutorialController = {}

-- UI Elements
local tutorialGui = nil
local mainFrame = nil
local currentSectionIndex = 1
local tutorialSections = {}

function TutorialController:CreateTutorialUI()
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
    -- Create a streamlined tutorial for new players covering essential mechanics
    local newPlayerSections = {
        {
            title = "🎉 Welcome to Color Rush!",
            content = [[👋 Welcome to the ultimate color-matching speed run game!

🏃‍♂️ In Color Rush, you'll race through obstacle courses while matching your color to barriers.

✨ This quick tutorial will show you everything you need to know to start having fun!

🔥 Ready to become a Color Rush champion? Let's go!

⚡ **Already know how to play?** You can press ESC anytime to skip this tutorial.]]
        },
        {
            title = "🏃‍♂️ Movement Controls",
            content = [[🎮 Moving around is simple and responsive:

• **WASD** or **Arrow Keys** - Move around the hub
• **Space** - Jump (great for exploring!)
• **Shift** - Sprint for faster movement

📱 **Mobile Players**: Use the on-screen joystick and jump button

🎯 **Pro Tip**: Practice moving around the hub to get comfortable with the controls before your first run!

Try walking around now - you've got this! 🌟]]
        },
        {
            title = "🌈 Color Swapping Magic",
            content = [[🎨 The heart of Color Rush is changing your color to match barriers:

• **Q/E Keys** - Cycle through colors
• **Number Keys (1-6)** - Direct color selection:
  - **1** = 🔴 Red
  - **2** = 🟢 Green  
  - **3** = 🔵 Blue
  - **4** = 🟡 Yellow
  - **5** = 🟣 Purple
  - **6** = 🟠 Orange

📱 **Mobile**: Tap the colored buttons on your screen
🎮 **Xbox Controller**: Use the D-pad directions

⚡ **Success Secret**: Change color BEFORE you reach each barrier for perfect timing!]]
        },
        {
            title = "🚀 Starting Your First Run",
            content = [[🏁 Ready to start racing? Here's how:

1️⃣ **Find the Start Area** - Look for the glowing green teleporter in the hub
2️⃣ **Step Into It** - Walk into the green area to join the queue
3️⃣ **Wait for Others** - Runs start when enough players join (or after a short timer)
4️⃣ **Get Ready!** - You'll be teleported to the starting line

🎯 **Your Goal**: Match your color to each barrier as you race to the finish!

💪 **Remember**: Speed matters, but accuracy is key for the highest scores!]]
        },
        {
            title = "💰 Spending Your Coins",
            content = [[💎 Earn coins by completing runs and spend them wisely:

**🛍️ Shop** (located in the hub):
• **Cosmetics** - Trails, hats, and visual effects
• **Pets** - Adorable companions with special abilities  
• **Upgrades** - Boost your coin earning and abilities

**🎁 What to Buy First**:
1. **Coin Multiplier Upgrades** - Earn more coins faster
2. **A Pet** - They provide helpful bonuses
3. **Cool Cosmetics** - Show off your style!

💡 **Smart Strategy**: Invest in upgrades first, then treat yourself to cosmetics!]]
        },
        {
            title = "🎓 You're Ready to Rush!",
            content = [[🏆 Congratulations! You now know all the basics:

✅ **Movement** - WASD to move, Space to jump
✅ **Color Swapping** - Q/E or number keys to change colors  
✅ **Starting Runs** - Step into the green teleporter
✅ **Spending Coins** - Visit the shop for upgrades and cosmetics

🌟 **Pro Tips for Success**:
• Practice color changes in the hub area
• Watch other players to learn advanced techniques
• Complete daily quests for bonus rewards
• Join parties with friends for extra fun!

🚀 **Ready to become a Color Rush legend?** 
Head to the start area and begin your first run! Good luck! 🍀

🎁 **Welcome Bonus**: You'll receive 100 coins for completing this tutorial!]]
        }
    }
    
    self:ShowTutorial(newPlayerSections)
    print("🎓 Started new player tutorial")
end

function TutorialController:Initialize()
    print("📚 TutorialController initializing...")
    
    -- Create UI
    self:CreateTutorialUI()
    
    -- Connect remote events
    RemoteEvents.ShowTutorial.OnClientEvent:Connect(function(sections)
        self:ShowTutorial(sections)
    end)
    
    RemoteEvents.StartNewPlayerTutorial.OnClientEvent:Connect(function()
        self:StartNewPlayerTutorial()
    end)
    
    -- Handle keyboard shortcuts
    UserInputService.InputBegan:Connect(function(input, gameProcessed)
        if gameProcessed or not mainFrame or not mainFrame.Visible then return end
        
        if input.KeyCode == Enum.KeyCode.Left or input.KeyCode == Enum.KeyCode.A then
            self:PreviousSection()
        elseif input.KeyCode == Enum.KeyCode.Right or input.KeyCode == Enum.KeyCode.D then
            self:NextSection()
        elseif input.KeyCode == Enum.KeyCode.Escape then
            self:HideTutorial()
        end
    end)
    
    print("✅ TutorialController initialized!")
end

-- Auto-initialize
TutorialController:Initialize()

return TutorialController
