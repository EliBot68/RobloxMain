-- HubLeaderboardController.luau
-- Physical leaderboard and reward chest in hub area

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local RemoteEvents = require(ReplicatedStorage.Shared.modules.RemoteEvents)

local HubLeaderboardController = {}

-- Physical objects
local leaderboardStand = nil
local rewardChest = nil
local leaderboardScreen = nil
local chestProximityPrompt = nil
local leaderboardProximityPrompt = nil

-- Configuration
local LEADERBOARD_POSITION = Vector3.new(0, 3, -45)
local CHEST_POSITION = Vector3.new(8, 3, -45)
local INTERACTION_DISTANCE = 15

function HubLeaderboardController:CreateLeaderboardStand()
    -- Create leaderboard stand structure
    leaderboardStand = Instance.new("Model")
    leaderboardStand.Name = "WeeklyLeaderboardStand"
    leaderboardStand.Parent = workspace
    
    -- Base platform
    local base = Instance.new("Part")
    base.Name = "Base"
    base.Size = Vector3.new(8, 1, 6)
    base.Position = LEADERBOARD_POSITION
    base.Anchored = true
    base.BrickColor = BrickColor.new("Dark stone grey")
    base.Material = Enum.Material.Marble
    base.Parent = leaderboardStand
    
    -- Decorative trim
    local trim = Instance.new("Part")
    trim.Name = "Trim"
    trim.Size = Vector3.new(8.2, 0.2, 6.2)
    trim.Position = LEADERBOARD_POSITION + Vector3.new(0, 0.6, 0)
    trim.Anchored = true
    trim.BrickColor = BrickColor.new("Bright yellow")
    trim.Material = Enum.Material.Neon
    trim.Parent = leaderboardStand
    
    -- Support pillars
    for i = 1, 2 do
        local pillar = Instance.new("Part")
        pillar.Name = "Pillar" .. i
        pillar.Size = Vector3.new(0.5, 6, 0.5)
        pillar.Position = LEADERBOARD_POSITION + Vector3.new(i == 1 and -3.5 or 3.5, 3.5, 0)
        pillar.Anchored = true
        pillar.BrickColor = BrickColor.new("Really black")
        pillar.Material = Enum.Material.Metal
        pillar.Parent = leaderboardStand
        
        -- Pillar caps
        local cap = Instance.new("Part")
        cap.Name = "Cap" .. i
        cap.Size = Vector3.new(1, 0.5, 1)
        cap.Position = pillar.Position + Vector3.new(0, 3.25, 0)
        cap.Anchored = true
        cap.BrickColor = BrickColor.new("Bright yellow")
        cap.Material = Enum.Material.Neon
        cap.Shape = Enum.PartType.Cylinder
        cap.Parent = leaderboardStand
    end
    
    -- Screen frame
    local screenFrame = Instance.new("Part")
    screenFrame.Name = "ScreenFrame"
    screenFrame.Size = Vector3.new(6, 4, 0.3)
    screenFrame.Position = LEADERBOARD_POSITION + Vector3.new(0, 4, 0)
    screenFrame.Anchored = true
    screenFrame.BrickColor = BrickColor.new("Really black")
    screenFrame.Material = Enum.Material.Metal
    screenFrame.Parent = leaderboardStand
    
    -- Leaderboard screen
    leaderboardScreen = Instance.new("Part")
    leaderboardScreen.Name = "LeaderboardScreen"
    leaderboardScreen.Size = Vector3.new(5.8, 3.8, 0.1)
    leaderboardScreen.Position = LEADERBOARD_POSITION + Vector3.new(0, 4, 0.2)
    leaderboardScreen.Anchored = true
    leaderboardScreen.BrickColor = BrickColor.new("Institutional white")
    leaderboardScreen.Material = Enum.Material.Neon
    leaderboardScreen.Parent = leaderboardStand
    
    -- Screen glow effect
    local screenGlow = Instance.new("PointLight")
    screenGlow.Color = Color3.fromRGB(255, 215, 0)
    screenGlow.Brightness = 2
    screenGlow.Range = 10
    screenGlow.Parent = leaderboardScreen
    
    -- Add title to screen
    self:CreateScreenGUI()
    
    -- Proximity prompt for interaction
    leaderboardProximityPrompt = Instance.new("ProximityPrompt")
    leaderboardProximityPrompt.ActionText = "View Leaderboard"
    leaderboardProximityPrompt.ObjectText = "Weekly Leaderboard"
    leaderboardProximityPrompt.HoldDuration = 0
    leaderboardProximityPrompt.MaxActivationDistance = INTERACTION_DISTANCE
    leaderboardProximityPrompt.Parent = leaderboardScreen
    
    -- Floating particles around screen
    self:CreateScreenParticles()
    
    print("🏆 Leaderboard stand created at", LEADERBOARD_POSITION)
    
    return leaderboardStand
end

function HubLeaderboardController:CreateScreenGUI()
    -- Create surface GUI for the screen
    local screenGui = Instance.new("SurfaceGui")
    screenGui.Name = "LeaderboardScreenGUI"
    screenGui.Face = Enum.NormalId.Front
    screenGui.CanvasSize = Vector2.new(800, 600)
    screenGui.Parent = leaderboardScreen
    
    -- Background
    local background = Instance.new("Frame")
    background.Size = UDim2.new(1, 0, 1, 0)
    background.BackgroundColor3 = Color3.fromRGB(20, 20, 30)
    background.BorderSizePixel = 0
    background.Parent = screenGui
    
    -- Title
    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(1, -40, 0, 80)
    title.Position = UDim2.new(0, 20, 0, 20)
    title.BackgroundTransparency = 1
    title.Text = "🏆 WEEKLY LEADERBOARD"
    title.TextColor3 = Color3.fromRGB(255, 215, 0)
    title.TextSize = 36
    title.Font = Enum.Font.GothamBold
    title.TextStrokeTransparency = 0
    title.TextStrokeColor3 = Color3.new(0, 0, 0)
    title.Parent = background
    
    -- Subtitle
    local subtitle = Instance.new("TextLabel")
    subtitle.Size = UDim2.new(1, -40, 0, 40)
    subtitle.Position = UDim2.new(0, 20, 0, 100)
    subtitle.BackgroundTransparency = 1
    subtitle.Text = "Most Coins This Week"
    subtitle.TextColor3 = Color3.new(1, 1, 1)
    subtitle.TextSize = 24
    subtitle.Font = Enum.Font.Gotham
    subtitle.Parent = background
    
    -- Preview text
    local previewText = Instance.new("TextLabel")
    previewText.Size = UDim2.new(1, -40, 1, -200)
    previewText.Position = UDim2.new(0, 20, 0, 160)
    previewText.BackgroundTransparency = 1
    previewText.Text = "🎮 Touch to view full leaderboard\n\n🏆 Top 5 players earn weekly rewards!\n\n⏰ Resets every Monday"
    previewText.TextColor3 = Color3.fromRGB(200, 200, 200)
    previewText.TextSize = 20
    previewText.Font = Enum.Font.Gotham
    previewText.TextWrapped = true
    previewText.Parent = background
    
    -- Animated border
    local border = Instance.new("Frame")
    border.Size = UDim2.new(1, -10, 1, -10)
    border.Position = UDim2.new(0, 5, 0, 5)
    border.BackgroundTransparency = 1
    border.BorderSizePixel = 3
    border.BorderColor3 = Color3.fromRGB(255, 215, 0)
    border.Parent = background
    
    -- CONVERTED: Animate border glow → Event-driven animation
    local function createGlowAnimation()
        local glow1 = TweenService:Create(border,
            TweenInfo.new(2, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut),
            {BorderColor3 = Color3.fromRGB(255, 255, 0)}
        )
        
        local glow2 = TweenService:Create(border,
            TweenInfo.new(2, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut),
            {BorderColor3 = Color3.fromRGB(255, 215, 0)}
        )
        
        -- Chain animations using Completed events (no polling)
        glow1.Completed:Connect(function()
            glow2:Play()
        end)
        
        glow2.Completed:Connect(function()
            glow1:Play() -- Restart the cycle
        end)
        
        -- Start the animation cycle
        glow1:Play()
    end
    
    createGlowAnimation()
    print("✅ Border glow animation converted to event-driven system (NO POLLING)")
end

function HubLeaderboardController:CreateScreenParticles()
    -- Create floating particle effects around the screen
    for i = 1, 8 do
        local particle = Instance.new("Part")
        particle.Name = "Particle" .. i
        particle.Size = Vector3.new(0.5, 0.5, 0.5)
        particle.Shape = Enum.PartType.Ball
        particle.Material = Enum.Material.Neon
        particle.BrickColor = BrickColor.new("Bright yellow")
        particle.Anchored = true
        particle.CanCollide = false
        particle.TopSurface = Enum.SurfaceType.Smooth
        particle.BottomSurface = Enum.SurfaceType.Smooth
        
        -- Random position around screen
        local angle = (i / 8) * math.pi * 2
        local radius = 4
        local basePos = LEADERBOARD_POSITION + Vector3.new(0, 4, 0)
        particle.Position = basePos + Vector3.new(
            math.cos(angle) * radius,
            math.random(-1, 1),
            math.sin(angle) * radius
        )
        
        particle.Parent = leaderboardStand
        
        -- Floating animation
        -- CONVERTED: Movement animation → Event-driven with TweenService.Completed
        local function animateParticleMovement()
            if not particle.Parent then return end
            
            local newAngle = angle + (tick() * 0.5)
            local newPos = basePos + Vector3.new(
                math.cos(newAngle) * radius,
                2 + math.sin(tick() * 2 + i) * 0.5,
                math.sin(newAngle) * radius
            )
            
            local moveTween = TweenService:Create(particle,
                TweenInfo.new(0.1, Enum.EasingStyle.Linear),
                {Position = newPos}
            )
            
            moveTween.Completed:Connect(animateParticleMovement) -- Event-driven continuation
            moveTween:Play()
        end
        
        animateParticleMovement() -- Start the animation chain
        print("✅ Particle movement converted to event-driven animation (NO POLLING)")
        
        -- CONVERTED: Glow animation → Event-driven with TweenService.Completed chains
        local function animateParticleGlow()
            if not particle.Parent then return end
            
            local glow = TweenService:Create(particle,
                TweenInfo.new(1 + math.random() * 2, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut),
                {Transparency = 0.7}
            )
            
            glow.Completed:Connect(function()
                if not particle.Parent then return end
                
                local unglow = TweenService:Create(particle,
                    TweenInfo.new(1 + math.random() * 2, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut),
                    {Transparency = 0.1}
                )
                
                unglow.Completed:Connect(animateParticleGlow) -- Event-driven loop
                unglow:Play()
            end)
            
            glow:Play()
        end
        
        animateParticleGlow() -- Start the glow animation chain
        print("✅ Particle glow converted to event-driven animation (NO POLLING)")
    end
end

function HubLeaderboardController:CreateRewardChest()
    -- Create reward chest structure
    rewardChest = Instance.new("Model")
    rewardChest.Name = "WeeklyRewardChest"
    rewardChest.Parent = workspace
    
    -- Chest platform
    local platform = Instance.new("Part")
    platform.Name = "Platform"
    platform.Size = Vector3.new(4, 1, 4)
    platform.Position = CHEST_POSITION
    platform.Anchored = true
    platform.BrickColor = BrickColor.new("Dark stone grey")
    platform.Material = Enum.Material.Marble
    platform.Parent = rewardChest
    
    -- Chest base
    local chestBase = Instance.new("Part")
    chestBase.Name = "ChestBase"
    chestBase.Size = Vector3.new(3, 1.5, 2)
    chestBase.Position = CHEST_POSITION + Vector3.new(0, 1.25, 0)
    chestBase.Anchored = true
    chestBase.BrickColor = BrickColor.new("Reddish brown")
    chestBase.Material = Enum.Material.Wood
    chestBase.Parent = rewardChest
    
    -- Chest lid
    local chestLid = Instance.new("Part")
    chestLid.Name = "ChestLid"
    chestLid.Size = Vector3.new(3.2, 0.5, 2.2)
    chestLid.Position = CHEST_POSITION + Vector3.new(0, 2.25, 0)
    chestLid.Anchored = true
    chestLid.BrickColor = BrickColor.new("Reddish brown")
    chestLid.Material = Enum.Material.Wood
    chestLid.Parent = rewardChest
    
    -- Gold trim
    local trim1 = Instance.new("Part")
    trim1.Name = "Trim1"
    trim1.Size = Vector3.new(3.4, 0.1, 0.1)
    trim1.Position = CHEST_POSITION + Vector3.new(0, 1.8, 1)
    trim1.Anchored = true
    trim1.BrickColor = BrickColor.new("Bright yellow")
    trim1.Material = Enum.Material.Neon
    trim1.Parent = rewardChest
    
    local trim2 = Instance.new("Part")
    trim2.Name = "Trim2"
    trim2.Size = Vector3.new(3.4, 0.1, 0.1)
    trim2.Position = CHEST_POSITION + Vector3.new(0, 1.8, -1)
    trim2.Anchored = true
    trim2.BrickColor = BrickColor.new("Bright yellow")
    trim2.Material = Enum.Material.Neon
    trim2.Parent = rewardChest
    
    -- Lock mechanism
    local lock = Instance.new("Part")
    lock.Name = "Lock"
    lock.Size = Vector3.new(0.5, 0.8, 0.3)
    lock.Position = CHEST_POSITION + Vector3.new(0, 1.5, 1.2)
    lock.Anchored = true
    lock.BrickColor = BrickColor.new("Bright yellow")
    lock.Material = Enum.Material.Metal
    lock.Parent = rewardChest
    
    -- Chest glow
    local chestGlow = Instance.new("PointLight")
    chestGlow.Color = Color3.fromRGB(255, 215, 0)
    chestGlow.Brightness = 1.5
    chestGlow.Range = 8
    chestGlow.Parent = chestBase
    
    -- Proximity prompt
    chestProximityPrompt = Instance.new("ProximityPrompt")
    chestProximityPrompt.ActionText = "Open Chest"
    chestProximityPrompt.ObjectText = "Weekly Rewards"
    chestProximityPrompt.HoldDuration = 1
    chestProximityPrompt.MaxActivationDistance = INTERACTION_DISTANCE
    chestProximityPrompt.Parent = chestBase
    
    -- Floating coins effect
    self:CreateChestParticles()
    
    print("💰 Reward chest created at", CHEST_POSITION)
    
    return rewardChest
end

function HubLeaderboardController:CreateChestParticles()
    -- Create floating coin effects around chest
    for i = 1, 6 do
        local coin = Instance.new("Part")
        coin.Name = "FloatingCoin" .. i
        coin.Size = Vector3.new(0.8, 0.1, 0.8)
        coin.Shape = Enum.PartType.Cylinder
        coin.Material = Enum.Material.Neon
        coin.BrickColor = BrickColor.new("Bright yellow")
        coin.Anchored = true
        coin.CanCollide = false
        
        -- Random position around chest
        local angle = (i / 6) * math.pi * 2
        local radius = 3
        local basePos = CHEST_POSITION + Vector3.new(0, 2, 0)
        coin.Position = basePos + Vector3.new(
            math.cos(angle) * radius,
            math.random(-1, 1),
            math.sin(angle) * radius
        )
        
        coin.Parent = rewardChest
        
        -- CONVERTED: Floating and spinning animation → Event-driven with TweenService.Completed
        local function animateCoin()
            if not coin.Parent then return end
            
            local newAngle = angle + (tick() * 0.3)
            local newPos = basePos + Vector3.new(
                math.cos(newAngle) * radius,
                1 + math.sin(tick() * 1.5 + i) * 0.8,
                math.sin(newAngle) * radius
            )
            
            local moveTween = TweenService:Create(coin,
                TweenInfo.new(0.1, Enum.EasingStyle.Linear),
                {
                    Position = newPos,
                    Orientation = Vector3.new(0, tick() * 100 + i * 60, 0)
                }
            )
            
            moveTween.Completed:Connect(animateCoin) -- Event-driven continuation
            moveTween:Play()
        end
        
        animateCoin() -- Start the coin animation chain
        print("✅ Coin animation converted to event-driven animation (NO POLLING)")
    end
end

function HubLeaderboardController:AnimateChestOpen()
    if not rewardChest then return end
    
    local chestLid = rewardChest:FindFirstChild("ChestLid")
    if not chestLid then return end
    
    -- Open chest animation
    local openTween = TweenService:Create(chestLid,
        TweenInfo.new(1, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
        {
            CFrame = chestLid.CFrame * CFrame.Angles(math.rad(-60), 0, 0) * CFrame.new(0, 0, -0.5)
        }
    )
    openTween:Play()
    
    -- Particle burst effect
    spawn(function()
        for i = 1, 12 do
            local particle = Instance.new("Part")
            particle.Size = Vector3.new(0.3, 0.3, 0.3)
            particle.Shape = Enum.PartType.Ball
            particle.Material = Enum.Material.Neon
            particle.BrickColor = BrickColor.new("Bright yellow")
            particle.Position = CHEST_POSITION + Vector3.new(0, 2, 0)
            particle.Anchored = false
            particle.CanCollide = false
            particle.Parent = workspace
            
            -- Random velocity
            local bodyVelocity = Instance.new("BodyVelocity")
            bodyVelocity.Velocity = Vector3.new(
                math.random(-10, 10),
                math.random(5, 15),
                math.random(-10, 10)
            )
            bodyVelocity.Parent = particle
            
            -- Remove after animation
            game:GetService("Debris"):AddItem(particle, 3)
        end
    end)
    
    -- Close chest after 3 seconds
    spawn(function()
        wait(3)
        local closeTween = TweenService:Create(chestLid,
            TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut),
            {
                CFrame = chestLid.CFrame * CFrame.Angles(math.rad(60), 0, 0) * CFrame.new(0, 0, 0.5)
            }
        )
        closeTween:Play()
    end)
end

function HubLeaderboardController:UpdateChestAvailability(playerRank)
    if not chestProximityPrompt then return end
    
    if playerRank and playerRank <= 5 then
        chestProximityPrompt.Enabled = true
        chestProximityPrompt.ObjectText = "Weekly Rewards (Available)"
        
        -- Add special glow for eligible players
        local chestBase = rewardChest:FindFirstChild("ChestBase")
        if chestBase and not chestBase:FindFirstChild("EligibleGlow") then
            local eligibleGlow = Instance.new("SelectionBox")
            eligibleGlow.Name = "EligibleGlow"
            eligibleGlow.Color3 = Color3.fromRGB(0, 255, 0)
            eligibleGlow.Transparency = 0.5
            eligibleGlow.Adornee = chestBase
            eligibleGlow.Parent = chestBase
            
            -- Pulse animation
            spawn(function()
                while eligibleGlow.Parent do
                    local pulse = TweenService:Create(eligibleGlow,
                        TweenInfo.new(1, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true),
                        {Transparency = 0.2}
                    )
                    pulse:Play()
                    wait(1)
                end
            end)
        end
    else
        chestProximityPrompt.Enabled = false
        chestProximityPrompt.ObjectText = "Weekly Rewards (Top 5 Only)"
        
        -- Remove eligible glow
        local chestBase = rewardChest:FindFirstChild("ChestBase")
        if chestBase then
            local eligibleGlow = chestBase:FindFirstChild("EligibleGlow")
            if eligibleGlow then
                eligibleGlow:Destroy()
            end
        end
    end
end

function HubLeaderboardController:Initialize()
    print("🏆 HubLeaderboardController initializing...")
    
    -- Create physical objects
    self:CreateLeaderboardStand()
    self:CreateRewardChest()
    
    -- Connect proximity prompt events
    if leaderboardProximityPrompt then
        leaderboardProximityPrompt.Triggered:Connect(function(playerWhoTriggered)
            if playerWhoTriggered == player then
                RemoteEvents.ShowWeeklyLeaderboard:FireServer()
            end
        end)
    end
    
    if chestProximityPrompt then
        chestProximityPrompt.Triggered:Connect(function(playerWhoTriggered)
            if playerWhoTriggered == player then
                RemoteEvents.ShowWeeklyRewardChest:FireServer()
            end
        end)
    end
    
    -- Listen for chest animation events
    RemoteEvents.WeeklyRewardClaimed.OnClientEvent:Connect(function()
        self:AnimateChestOpen()
    end)
    
    -- Listen for rank updates
    RemoteEvents.UpdatePlayerRank.OnClientEvent:Connect(function(rank)
        self:UpdateChestAvailability(rank)
    end)
    
    print("✅ HubLeaderboardController initialized!")
end

-- Auto-initialize
HubLeaderboardController:Initialize()

return HubLeaderboardController
