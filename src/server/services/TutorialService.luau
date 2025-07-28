-- TutorialService.luau
-- Handles the How to Play kiosk and complete new player onboarding system

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local DataStoreService = game:GetService("DataStoreService")

local SafeRequire = require(ReplicatedStorage.Shared.utils.SafeRequire)
local WorldObjectValidator = SafeRequire.require(ReplicatedStorage.Shared.utils.WorldObjectValidator)
local RemoteEvents = SafeRequire.require(ReplicatedStorage.Shared.modules.RemoteEvents)

local TutorialService = {}

-- Player tutorial state tracking
local tutorialDataStore = DataStoreService:GetDataStore("PlayerTutorials")
local playerTutorialState = {} -- [userId] = {completedTutorial = bool, completionTime = number}

-- Welcome bonus for new players
local WELCOME_BONUS = {
    coins = 100,
    xp = 50
}

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

function TutorialService:LoadPlayerTutorialData(player)
    local success, data = pcall(function()
        return tutorialDataStore:GetAsync("Player_" .. player.UserId)
    end)
    
    if success and data then
        playerTutorialState[player.UserId] = data
        return data
    else
        -- New player - initialize tutorial state
        local initialState = {
            completedTutorial = false,
            completionTime = 0,
            firstJoin = true,
            joinTime = os.time()
        }
        playerTutorialState[player.UserId] = initialState
        return initialState
    end
end

function TutorialService:SavePlayerTutorialData(player)
    local data = playerTutorialState[player.UserId]
    if not data then return end
    
    spawn(function()
        local success, error = pcall(function()
            tutorialDataStore:SetAsync("Player_" .. player.UserId, data)
        end)
        
        if not success then
            warn("❌ TutorialService: Failed to save tutorial data for " .. player.Name .. ": " .. tostring(error))
        end
    end)
end

function TutorialService:HandlePlayerAdded(player)
    wait(3) -- Give player time to load
    
    local tutorialData = self:LoadPlayerTutorialData(player)
    
    if tutorialData.firstJoin and not tutorialData.completedTutorial then
        -- New player - start tutorial after a brief delay
        wait(2)
        self:StartNewPlayerOnboarding(player)
        print("🎓 Starting new player tutorial for " .. player.Name)
    else
        print("👋 Welcome back, " .. player.Name .. "! Tutorial already completed.")
    end
end

function TutorialService:StartNewPlayerOnboarding(player)
    -- Send welcome message
    local welcomeEvent = RemoteEvents:GetRemoteEvent("ShowWelcomeMessage")
    if welcomeEvent then
        welcomeEvent:FireClient(player, {
            title = "🎉 Welcome to Color Rush!",
            message = "Ready to learn how to play? Your tutorial will start in 3 seconds...",
            duration = 3
        })
    end
    
    wait(3)
    
    -- Start the interactive tutorial
    RemoteEvents.StartNewPlayerTutorial:FireClient(player)
    
    -- Mark as tutorial started
    if playerTutorialState[player.UserId] then
        playerTutorialState[player.UserId].tutorialStarted = true
        self:SavePlayerTutorialData(player)
    end
end

function TutorialService:CompleteTutorial(player)
    local tutorialData = playerTutorialState[player.UserId]
    if not tutorialData then return end
    
    -- Mark tutorial as completed
    tutorialData.completedTutorial = true
    tutorialData.completionTime = os.time()
    tutorialData.firstJoin = false
    
    -- Save completion state
    self:SavePlayerTutorialData(player)
    
    -- Award welcome bonus
    self:AwardWelcomeBonus(player)
    
    print("🎓 " .. player.Name .. " completed the new player tutorial!")
end

function TutorialService:AwardWelcomeBonus(player)
    -- Try to give coins through various services
    local coinsAwarded = false
    local xpAwarded = false
    
    -- Try DataService first
    local success = pcall(function()
        local DataService = require(script.Parent.DataService)
        if DataService then
            local playerData = DataService:GetPlayerData(player)
            if playerData then
                DataService:SetPlayerData(player, "coins", (playerData.coins or 0) + WELCOME_BONUS.coins)
                DataService:SetPlayerData(player, "xp", (playerData.xp or 0) + WELCOME_BONUS.xp)
                coinsAwarded = true
                xpAwarded = true
            end
        end
    end)
    
    -- Fallback to leaderstats if DataService unavailable
    if not coinsAwarded then
        local leaderstats = player:FindFirstChild("leaderstats")
        if leaderstats then
            local coins = leaderstats:FindFirstChild("Coins")
            local xp = leaderstats:FindFirstChild("XP")
            
            if coins then
                coins.Value = coins.Value + WELCOME_BONUS.coins
                coinsAwarded = true
            end
            
            if xp then
                xp.Value = xp.Value + WELCOME_BONUS.xp
                xpAwarded = true
            end
        end
    end
    
    -- Send notification to player
    local notificationEvent = RemoteEvents:GetRemoteEvent("ShowNotification")
    if notificationEvent then
        local bonusText = ""
        if coinsAwarded then bonusText = bonusText .. WELCOME_BONUS.coins .. " coins" end
        if xpAwarded then 
            if bonusText ~= "" then bonusText = bonusText .. " and " end
            bonusText = bonusText .. WELCOME_BONUS.xp .. " XP"
        end
        
        notificationEvent:FireClient(player, {
            title = "🎁 Welcome Bonus!",
            message = "You received " .. bonusText .. " for completing the tutorial!",
            type = "success",
            duration = 5
        })
    end
    
    print("🎁 Awarded welcome bonus to " .. player.Name .. ": " .. WELCOME_BONUS.coins .. " coins, " .. WELCOME_BONUS.xp .. " XP")
end

function TutorialService:HasCompletedTutorial(player)
    local tutorialData = playerTutorialState[player.UserId]
    return tutorialData and tutorialData.completedTutorial or false
end

function TutorialService:SetupKioskDisplay()
    local success, error = pcall(function()
        -- Validate tutorial kiosk objects
        local marketPlazaExists = WorldObjectValidator.validateObjectWithWait("workspace.MarketPlaza", 5)
        if not marketPlazaExists then
            warn("⚠️ TutorialService: MarketPlaza not found for tutorial kiosk!")
            return
        end
        
        local kioskExists = WorldObjectValidator.validateObjectWithWait("workspace.MarketPlaza.HowToPlayKiosk", 3)
        if not kioskExists then
            warn("⚠️ TutorialService: Creating tutorial kiosk...")
            self:CreateTutorialKiosk()
            return
        end
        
        local marketPlaza = Workspace.MarketPlaza
        local kiosk = marketPlaza.HowToPlayKiosk
        
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

function TutorialService:CreateTutorialKiosk()
    local marketPlaza = Workspace:FindFirstChild("MarketPlaza")
    if not marketPlaza then
        warn("⚠️ TutorialService: MarketPlaza not found, cannot create tutorial kiosk")
        return
    end
    
    -- Create tutorial kiosk model
    local kiosk = Instance.new("Model")
    kiosk.Name = "HowToPlayKiosk"
    kiosk.Parent = marketPlaza
    
    -- Create base platform
    local base = Instance.new("Part")
    base.Name = "Base"
    base.Size = Vector3.new(6, 1, 6)
    base.Position = Vector3.new(15, 2.5, -20) -- Near market plaza center
    base.Anchored = true
    base.Material = Enum.Material.Marble
    base.BrickColor = BrickColor.new("Light blue")
    base.Parent = kiosk
    
    -- Create info sign
    local infoSign = Instance.new("Part")
    infoSign.Name = "InfoSign"
    infoSign.Size = Vector3.new(4, 6, 0.5)
    infoSign.Position = base.Position + Vector3.new(0, 4, 0)
    infoSign.Anchored = true
    infoSign.Material = Enum.Material.SmoothPlastic
    infoSign.BrickColor = BrickColor.new("Dark blue")
    infoSign.Parent = kiosk
    
    -- Create click detector
    local clickDetector = Instance.new("ClickDetector")
    clickDetector.MaxActivationDistance = 15
    clickDetector.Parent = infoSign
    
    -- Create speech bubble
    local speechBubble = Instance.new("Part")
    speechBubble.Name = "SpeechBubble"
    speechBubble.Size = Vector3.new(2, 2, 0.1)
    speechBubble.Position = infoSign.Position + Vector3.new(3, 2, 0)
    speechBubble.Anchored = true
    speechBubble.Material = Enum.Material.ForceField
    speechBubble.BrickColor = BrickColor.new("Bright yellow")
    speechBubble.Shape = Enum.PartType.Ball
    speechBubble.Parent = kiosk
    
    print("🔧 TutorialService: Created tutorial kiosk in MarketPlaza")
    
    -- Setup display after creating
    wait(1)
    self:SetupKioskDisplay()
end

function TutorialService:ShowTutorial(player)
    print("📚 " .. player.Name .. " opened the How to Play guide")
    RemoteEvents.ShowTutorial:FireClient(player, TUTORIAL_SECTIONS)
end

function TutorialService:StartTutorial(player)
    print("🎯 Starting interactive tutorial for " .. player.Name)
    -- Send tutorial start signal to client
    RemoteEvents.StartNewPlayerTutorial:FireClient(player)
end

function TutorialService:Initialize()
    print("📚 TutorialService initializing...")
    
    -- Validate tutorial-related world objects
    print("🔍 Validating tutorial world objects...")
    local missingObjects = WorldObjectValidator.validateAllRequired()
    if #missingObjects > 0 then
        warn("⚠️ TutorialService: Missing required world objects:")
        for _, missing in ipairs(missingObjects) do
            warn("  • " .. missing)
        end
    end
    
    -- Wait for workspace to be ready
    wait(1)
    
    -- Setup kiosk display
    self:SetupKioskDisplay()
    
    -- Setup player connections
    Players.PlayerAdded:Connect(function(player)
        spawn(function()
            self:HandlePlayerAdded(player)
        end)
    end)
    
    Players.PlayerRemoving:Connect(function(player)
        if playerTutorialState[player.UserId] then
            self:SavePlayerTutorialData(player)
            playerTutorialState[player.UserId] = nil
        end
    end)
    
    -- Handle existing players
    for _, player in pairs(Players:GetPlayers()) do
        spawn(function()
            self:HandlePlayerAdded(player)
        end)
    end
    
    -- Setup remote event handlers
    RemoteEvents.CompleteTutorial.OnServerEvent:Connect(function(player)
        self:CompleteTutorial(player)
    end)
    
    RemoteEvents.StartTutorial.OnServerEvent:Connect(function(player)
        self:StartTutorial(player)
    end)
    
    -- Find and setup click detector with error handling
    spawn(function()
        wait(2) -- Give kiosk time to load
        local success, error = pcall(function()
            local marketPlaza = Workspace:FindFirstChild("MarketPlaza")
            if not marketPlaza then
                warn("⚠️ MarketPlaza not found for tutorial click detector!")
                return
            end
            
            local kiosk = marketPlaza:FindFirstChild("HowToPlayKiosk")
            if kiosk then
                local clickDetector = kiosk:FindFirstChild("ClickDetector", true)
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
        end)
        
        if not success then
            warn("⚠️ Error setting up tutorial kiosk: " .. tostring(error))
        end
    end)
    
    print("✅ TutorialService initialized successfully!")
end

-- Auto-initialize when required
TutorialService:Initialize()

return TutorialService
