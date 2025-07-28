-- GameTimerUIController.client.luau
-- Displays game timer and win/loss conditions for Color Rush

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local SoundService = game:GetService("SoundService")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local GameTimerUIController = {}

-- UI Configuration
local UI_CONFIG = {
    timerPosition = UDim2.new(0.5, 0, 0, 50), -- Top center
    warningThreshold = 15, -- Seconds when timer turns red
    criticalThreshold = 5, -- Seconds when timer flashes
    
    colors = {
        normal = Color3.fromRGB(220, 220, 220),   -- Softer white
        warning = Color3.fromRGB(255, 140, 0),    -- Orange instead of bright orange
        critical = Color3.fromRGB(220, 80, 80),   -- Softer red
        background = Color3.fromRGB(30, 30, 40)   -- Dark blue-gray instead of black
    },
    
    sounds = {
        warning = "rbxasset://sounds/electronicpingshrill.wav",
        critical = "rbxasset://sounds/button-10.wav",
        victory = "rbxasset://sounds/victory.wav",
        defeat = "rbxasset://sounds/defeat.wav"
    }
}

-- UI Elements
local timerGui = nil
local timerFrame = nil
local timerLabel = nil
local statusLabel = nil
local resultFrame = nil

-- Game State
local gameTimeRemaining = 0
local maxGameTime = 60
local isGameActive = false
local flashingConnection = nil

-- Events
local Events = {}

function GameTimerUIController:Initialize()
    print("⏰ Initializing Game Timer UI Controller...")
    
    -- Setup UI
    self:CreateTimerUI()
    
    -- Setup events
    self:SetupEvents()
    
    print("✅ Game Timer UI Controller initialized!")
end

function GameTimerUIController:CreateTimerUI()
    -- Create main GUI
    timerGui = Instance.new("ScreenGui")
    timerGui.Name = "GameTimerUI"
    timerGui.ResetOnSpawn = false
    timerGui.Parent = playerGui
    
    -- Timer Frame
    timerFrame = Instance.new("Frame")
    timerFrame.Name = "TimerFrame"
    timerFrame.Size = UDim2.new(0, 200, 0, 80)
    timerFrame.Position = UI_CONFIG.timerPosition
    timerFrame.AnchorPoint = Vector2.new(0.5, 0)
    timerFrame.BackgroundColor3 = UI_CONFIG.colors.background
    timerFrame.BackgroundTransparency = 0.3
    timerFrame.BorderSizePixel = 0
    timerFrame.Parent = timerGui
    
    -- Add rounded corners
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 10)
    corner.Parent = timerFrame
    
    -- Add border - SOFTER BORDER
    local stroke = Instance.new("UIStroke")
    stroke.Color = Color3.fromRGB(180, 180, 180) -- Softer gray instead of bright white
    stroke.Thickness = 2
    stroke.Parent = timerFrame
    
    -- Timer Label
    timerLabel = Instance.new("TextLabel")
    timerLabel.Name = "TimerLabel"
    timerLabel.Size = UDim2.new(1, 0, 0.6, 0)
    timerLabel.Position = UDim2.new(0, 0, 0, 0)
    timerLabel.BackgroundTransparency = 1
    timerLabel.Text = "1:00"
    timerLabel.TextColor3 = UI_CONFIG.colors.normal
    timerLabel.TextScaled = true
    timerLabel.Font = Enum.Font.GothamBold
    timerLabel.Parent = timerFrame
    
    -- Status Label
    statusLabel = Instance.new("TextLabel")
    statusLabel.Name = "StatusLabel"
    statusLabel.Size = UDim2.new(1, 0, 0.4, 0)
    statusLabel.Position = UDim2.new(0, 0, 0.6, 0)
    statusLabel.BackgroundTransparency = 1
    statusLabel.Text = "Survive to Win!"
    statusLabel.TextColor3 = UI_CONFIG.colors.normal
    statusLabel.TextScaled = true
    statusLabel.Font = Enum.Font.Gotham
    statusLabel.Parent = timerFrame
    
    -- Result Frame (hidden initially)
    resultFrame = Instance.new("Frame")
    resultFrame.Name = "ResultFrame"
    resultFrame.Size = UDim2.new(0, 400, 0, 200)
    resultFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
    resultFrame.AnchorPoint = Vector2.new(0.5, 0.5)
    resultFrame.BackgroundColor3 = Color3.fromRGB(20, 25, 35)  -- Dark blue-gray
    resultFrame.BackgroundTransparency = 0.1 -- Less transparent for better readability
    resultFrame.BorderSizePixel = 0
    resultFrame.Visible = false
    resultFrame.Parent = timerGui
    
    local resultCorner = Instance.new("UICorner")
    resultCorner.CornerRadius = UDim.new(0, 15)
    resultCorner.Parent = resultFrame
    
    local resultStroke = Instance.new("UIStroke")
    resultStroke.Color = Color3.fromRGB(180, 180, 180) -- Softer border
    resultStroke.Thickness = 2 -- Thinner border
    resultStroke.Parent = resultFrame
    
    -- Result Title
    local resultTitle = Instance.new("TextLabel")
    resultTitle.Name = "ResultTitle"
    resultTitle.Size = UDim2.new(1, 0, 0.4, 0)
    resultTitle.Position = UDim2.new(0, 0, 0, 0)
    resultTitle.BackgroundTransparency = 1
    resultTitle.Text = "VICTORY!"
    resultTitle.TextColor3 = Color3.fromRGB(80, 200, 120) -- Softer green
    resultTitle.TextScaled = true
    resultTitle.Font = Enum.Font.GothamBold
    resultTitle.Parent = resultFrame
    
    -- Result Details
    local resultDetails = Instance.new("TextLabel")
    resultDetails.Name = "ResultDetails"
    resultDetails.Size = UDim2.new(1, -20, 0.6, 0)
    resultDetails.Position = UDim2.new(0, 10, 0.4, 0)
    resultDetails.BackgroundTransparency = 1
    resultDetails.Text = "You survived the timer!"
    resultDetails.TextColor3 = Color3.fromRGB(220, 220, 220) -- Softer white
    resultDetails.TextScaled = true
    resultDetails.Font = Enum.Font.Gotham
    resultDetails.TextWrapped = true
    resultDetails.Parent = resultFrame
    
    -- Hide timer initially
    timerFrame.Visible = false
    
    print("🖼️ Game Timer UI created")
end

function GameTimerUIController:SetupEvents()
    -- Wait for Events folder
    local eventsFolder = ReplicatedStorage:WaitForChild("Events", 10)
    if not eventsFolder then
        warn("❌ Events folder not found in ReplicatedStorage")
        return
    end
    
    -- Game Timer Update
    Events.GameTimerUpdate = eventsFolder:WaitForChild("GameTimerUpdate", 5)
    if Events.GameTimerUpdate then
        Events.GameTimerUpdate.OnClientEvent:Connect(function(timeRemaining, maxTime)
            self:UpdateTimer(timeRemaining, maxTime)
        end)
    end
    
    -- Game State Changes
    Events.GameStateChanged = eventsFolder:WaitForChild("GameStateChanged", 5)
    if Events.GameStateChanged then
        Events.GameStateChanged.OnClientEvent:Connect(function(newState, data)
            self:OnGameStateChanged(newState, data)
        end)
    end
    
    -- Win/Loss Events
    Events.PlayerWon = eventsFolder:WaitForChild("PlayerWon", 5)
    if Events.PlayerWon then
        Events.PlayerWon.OnClientEvent:Connect(function(reason, data)
            self:ShowVictory(reason, data)
        end)
    end
    
    Events.PlayerLost = eventsFolder:WaitForChild("PlayerLost", 5)
    if Events.PlayerLost then
        Events.PlayerLost.OnClientEvent:Connect(function(reason, data)
            self:ShowDefeat(reason, data)
        end)
    end
    
    Events.GameVictory = eventsFolder:WaitForChild("GameVictory", 5)
    if Events.GameVictory then
        Events.GameVictory.OnClientEvent:Connect(function(victoryType, data, results)
            self:ShowGameVictory(victoryType, data, results)
        end)
    end
    
    Events.GameDefeat = eventsFolder:WaitForChild("GameDefeat", 5)
    if Events.GameDefeat then
        Events.GameDefeat.OnClientEvent:Connect(function(defeatType, data, results)
            self:ShowGameDefeat(defeatType, data, results)
        end)
    end
    
    print("🔗 Game Timer UI events connected")
end

function GameTimerUIController:UpdateTimer(timeRemaining, maxTime)
    gameTimeRemaining = timeRemaining
    maxGameTime = maxTime
    
    -- Format time as MM:SS
    local minutes = math.floor(timeRemaining / 60)
    local seconds = math.floor(timeRemaining % 60)
    local timeText = string.format("%d:%02d", minutes, seconds)
    
    timerLabel.Text = timeText
    
    -- Update color based on time remaining
    if timeRemaining <= UI_CONFIG.criticalThreshold then
        timerLabel.TextColor3 = UI_CONFIG.colors.critical
        self:StartCriticalFlashing()
        self:PlayWarningSound("critical")
    elseif timeRemaining <= UI_CONFIG.warningThreshold then
        timerLabel.TextColor3 = UI_CONFIG.colors.warning
        self:StopCriticalFlashing()
        if math.floor(timeRemaining) == UI_CONFIG.warningThreshold then
            self:PlayWarningSound("warning")
        end
    else
        timerLabel.TextColor3 = UI_CONFIG.colors.normal
        self:StopCriticalFlashing()
    end
    
    -- Update status based on time
    if timeRemaining <= 10 then
        statusLabel.Text = "Almost there!"
    else
        statusLabel.Text = "Survive to Win!"
    end
end

function GameTimerUIController:OnGameStateChanged(newState, data)
    if newState == "Running" then
        isGameActive = true
        timerFrame.Visible = true
        resultFrame.Visible = false
        statusLabel.Text = "Survive to Win!"
        timerLabel.TextColor3 = UI_CONFIG.colors.normal
        self:StopCriticalFlashing()
    elseif newState == "Lobby" or newState == "GameOver" then
        isGameActive = false
        timerFrame.Visible = false
        self:StopCriticalFlashing()
    elseif newState == "Countdown" then
        timerFrame.Visible = true
        timerLabel.Text = "READY"
        statusLabel.Text = "Get Ready!"
        timerLabel.TextColor3 = UI_CONFIG.colors.warning
    end
end

function GameTimerUIController:StartCriticalFlashing()
    if flashingConnection then return end -- Already flashing
    
    flashingConnection = RunService.Heartbeat:Connect(function()
        local time = tick()
        local alpha = (math.sin(time * 10) + 1) / 2 -- Oscillate between 0 and 1
        timerLabel.TextTransparency = alpha * 0.5 -- Flash between 0 and 0.5 transparency
    end)
end

function GameTimerUIController:StopCriticalFlashing()
    if flashingConnection then
        flashingConnection:Disconnect()
        flashingConnection = nil
        timerLabel.TextTransparency = 0
    end
end

function GameTimerUIController:PlayWarningSound(soundType)
    local soundId = UI_CONFIG.sounds[soundType]
    if soundId then
        local sound = Instance.new("Sound")
        sound.SoundId = soundId
        sound.Volume = 0.5
        sound.Parent = SoundService
        sound:Play()
        
        sound.Ended:Connect(function()
            sound:Destroy()
        end)
    end
end

function GameTimerUIController:ShowVictory(reason, data)
    resultFrame.Visible = true
    
    local title = resultFrame:FindFirstChild("ResultTitle")
    local details = resultFrame:FindFirstChild("ResultDetails")
    
    title.Text = "VICTORY!"
    title.TextColor3 = Color3.fromRGB(80, 200, 120) -- Softer green
    
    local detailText = "You won!"
    if reason == "finish_line" then
        detailText = string.format("You reached the finish line!\\nTime: %.1fs\\nScore: %d", 
            data.finishTime or 0, data.score or 0)
    elseif reason == "survival" then
        detailText = string.format("You survived the time limit!\\nSurvival Time: %.1fs\\nScore: %d", 
            data.survivalTime or 0, data.score or 0)
    end
    
    details.Text = detailText
    
    -- Play victory sound
    self:PlayWarningSound("victory")
    
    -- Animate result frame
    self:AnimateResultFrame(true)
end

function GameTimerUIController:ShowDefeat(reason, data)
    resultFrame.Visible = true
    
    local title = resultFrame:FindFirstChild("ResultTitle")
    local details = resultFrame:FindFirstChild("ResultDetails")
    
    title.Text = "DEFEAT"
    title.TextColor3 = Color3.fromRGB(220, 80, 80) -- Softer red
    
    local detailText = "You lost!"
    if reason == "no_lives" then
        detailText = "You ran out of lives!"
    elseif reason == "no_health" then
        detailText = "Your health reached zero!"
    end
    
    details.Text = detailText
    
    -- Play defeat sound
    self:PlayWarningSound("defeat")
    
    -- Animate result frame
    self:AnimateResultFrame(false)
end

function GameTimerUIController:ShowGameVictory(victoryType, data, results)
    -- This could show overall game results
    print("🏆 Game Victory: " .. tostring(victoryType))
end

function GameTimerUIController:ShowGameDefeat(defeatType, data, results)
    -- This could show overall game results
    print("💀 Game Defeat: " .. tostring(defeatType))
end

function GameTimerUIController:AnimateResultFrame(isVictory)
    -- Scale animation
    resultFrame.Size = UDim2.new(0, 0, 0, 0)
    
    local targetSize = UDim2.new(0, 400, 0, 200)
    local scaleInfo = TweenInfo.new(0.5, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
    local scaleTween = TweenService:Create(resultFrame, scaleInfo, {Size = targetSize})
    
    scaleTween:Play()
    
    -- Auto-hide after 5 seconds
    spawn(function()
        wait(5)
        local hideInfo = TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
        local hideTween = TweenService:Create(resultFrame, hideInfo, {Size = UDim2.new(0, 0, 0, 0)})
        hideTween:Play()
        
        hideTween.Completed:Connect(function()
            resultFrame.Visible = false
        end)
    end)
end

function GameTimerUIController:Cleanup()
    self:StopCriticalFlashing()
    
    if timerGui then
        timerGui:Destroy()
    end
    
    -- Disconnect events
    for _, event in pairs(Events) do
        if event and event.OnClientEvent then
            -- Note: We can't directly disconnect OnClientEvent connections
            -- They will be cleaned up when the GUI is destroyed
        end
    end
end

-- Initialize automatically
GameTimerUIController:Initialize()

return GameTimerUIController
