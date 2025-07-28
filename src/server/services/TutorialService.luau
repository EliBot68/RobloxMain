-- TutorialService.luau
-- Handles the How to Play kiosk and tutorial information

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local RemoteEvents = require(ReplicatedStorage.Shared.modules.RemoteEvents)

local TutorialService = {}

-- Tutorial content sections
local TUTORIAL_SECTIONS = {
    {
        title = "🎮 Game Controls",
        content = {
            "• Press 1, 2, or 3 to change your color",
            "• Use on-screen buttons on mobile",
            "• WASD or arrow keys to move",
            "• Match your color to pass through barriers!"
        },
        icon = "🎮"
    },
    {
        title = "🌈 Color Matching",
        content = {
            "• Change to RED to pass red barriers",
            "• Change to BLUE to pass blue barriers", 
            "• Change to GREEN to pass green barriers",
            "• Wrong color = game over!",
            "• Your color changes automatically over time"
        },
        icon = "🌈"
    },
    {
        title = "💰 Coins & Rewards",
        content = {
            "• Collect coins during gameplay",
            "• Buy skins and trails in the shop",
            "• Complete daily quests for bonus coins",
            "• Claim fountain rewards once per day",
            "• Higher scores = more coin rewards!"
        },
        icon = "💰"
    },
    {
        title = "🏪 Market Plaza Features",
        content = {
            "• 🛍️ Shop: Buy cosmetic items",
            "• 📋 Quest Board: Daily challenges",
            "• 🌊 Fountain: Daily bonus rewards",
            "• 🏆 Leaderboards: See top players",
            "• All features refresh daily!"
        },
        icon = "🏪"
    },
    {
        title = "🎯 Pro Tips",
        content = {
            "• Plan color changes ahead of time",
            "• Collect all coins for maximum rewards",
            "• Visit daily for quest and fountain bonuses",
            "• Try different strategies for high scores",
            "• Have fun and experiment!"
        },
        icon = "🎯"
    }
}

function TutorialService:SetupKioskDisplay()
    local success, error = pcall(function()
        local marketPlaza = Workspace:FindFirstChild("MarketPlaza")
        if not marketPlaza then
            warn("⚠️ MarketPlaza not found for tutorial kiosk!")
            return
        end
        
        local kiosk = marketPlaza:FindFirstChild("HowToPlayKiosk")
        if not kiosk then
            warn("⚠️ How to Play kiosk not found!")
            return
        end
        
        local infoSign = kiosk:FindFirstChild("InfoSign")
        if not infoSign then 
            warn("⚠️ InfoSign not found in kiosk!")
            return 
        end
    
    -- Add main title billboard
    local titleGui = Instance.new("BillboardGui")
    titleGui.Size = UDim2.new(0, 300, 0, 60)
    titleGui.StudsOffset = Vector3.new(0, 0, 0.2)
    titleGui.Parent = infoSign
    
    local titleLabel = Instance.new("TextLabel")
    titleLabel.Size = UDim2.new(1, 0, 1, 0)
    titleLabel.BackgroundTransparency = 1
    titleLabel.Text = "📚 HOW TO PLAY"
    titleLabel.TextColor3 = Color3.new(1, 1, 1)
    titleLabel.TextScaled = true
    titleLabel.Font = Enum.Font.SourceSansBold
    titleLabel.TextStrokeTransparency = 0
    titleLabel.TextStrokeColor3 = Color3.new(0, 0, 0)
    titleLabel.Parent = titleGui
    
    -- Add subtitle
    local subtitleGui = Instance.new("BillboardGui")
    subtitleGui.Size = UDim2.new(0, 250, 0, 40)
    subtitleGui.StudsOffset = Vector3.new(0, -0.8, 0.2)
    subtitleGui.Parent = infoSign
    
    local subtitleLabel = Instance.new("TextLabel")
    subtitleLabel.Size = UDim2.new(1, 0, 1, 0)
    subtitleLabel.BackgroundTransparency = 1
    subtitleLabel.Text = "Click me to learn!"
    subtitleLabel.TextColor3 = Color3.new(0.8, 0.8, 1)
    subtitleLabel.TextScaled = true
    subtitleLabel.Font = Enum.Font.SourceSansItalic
    subtitleLabel.TextStrokeTransparency = 0
    subtitleLabel.TextStrokeColor3 = Color3.new(0, 0, 0)
    subtitleLabel.Parent = subtitleGui
    
    -- Setup NPC speech bubble
    local speechBubble = kiosk:FindFirstChild("SpeechBubble")
    if speechBubble then
        local speechGui = Instance.new("BillboardGui")
        speechGui.Size = UDim2.new(0, 150, 0, 50)
        speechGui.StudsOffset = Vector3.new(0, 0, 0.1)
        speechGui.Parent = speechBubble
        
        local speechText = Instance.new("TextLabel")
        speechText.Size = UDim2.new(1, 0, 1, 0)
        speechText.BackgroundTransparency = 1
        speechText.Text = "Need help? 🤔"
        speechText.TextColor3 = Color3.new(0.2, 0.2, 0.8)
        speechText.TextScaled = true
        speechText.Font = Enum.Font.SourceSans
        speechText.TextStrokeTransparency = 0
        speechText.TextStrokeColor3 = Color3.new(1, 1, 1)
        speechText.Parent = speechGui
        
        -- Animate speech bubble
        local bobTween = TweenService:Create(
            speechBubble,
            TweenInfo.new(2, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true),
            {Position = speechBubble.Position + Vector3.new(0, 0.5, 0)}
        )
        bobTween:Play()
    end
    
    -- Add pulsing animation to sign
    local pulseTween = TweenService:Create(
        titleLabel,
        TweenInfo.new(1.5, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true),
        {TextTransparency = 0.3}
    )
    pulseTween:Play()
end

function TutorialService:ShowTutorial(player)
    print("📚 " .. player.Name .. " opened the How to Play guide")
    RemoteEvents.ShowTutorial:FireClient(player, TUTORIAL_SECTIONS)
end

function TutorialService:Initialize()
    print("📚 TutorialService initializing...")
    
    -- Wait for workspace to be ready
    wait(1)
    
    -- Setup kiosk display
    self:SetupKioskDisplay()
    
    -- Find and setup click detector with error handling
    local success, error = pcall(function()
        local marketPlaza = Workspace:FindFirstChild("MarketPlaza")
        if not marketPlaza then
            warn("⚠️ MarketPlaza not found for tutorial click detector!")
            return
        end
        
        local kiosk = marketPlaza:FindFirstChild("HowToPlayKiosk")
        if kiosk then
            local clickDetector = kiosk:FindFirstChild("ClickDetector")
            if clickDetector then
                clickDetector.MouseClick:Connect(function(player)
                    self:ShowTutorial(player)
                end)
                print("📚 Tutorial kiosk click detector connected")
            else
            warn("⚠️ ClickDetector not found in tutorial kiosk!")
        end
    else
        warn("⚠️ Tutorial kiosk not found in MarketPlaza!")
    end
    
    print("✅ TutorialService initialized successfully!")
end

-- Auto-initialize when required
TutorialService:Initialize()

return TutorialService
