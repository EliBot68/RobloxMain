-- AdminLifecyclePanel.client.luau
-- Client-side admin panel for game lifecycle management
-- Place this in StarterPlayer/StarterPlayerScripts for admin users

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local AdminLifecyclePanel = {}

-- Configuration
local ADMIN_CONFIG = {
    keyBinding = Enum.KeyCode.F9, -- Key to toggle admin panel
    adminUserIds = {}, -- Add admin user IDs here
    enableDebugMode = true
}

-- UI Elements
local adminGui = nil
local mainFrame = nil
local isVisible = false

function AdminLifecyclePanel:Initialize()
    -- Check if player is admin
    if not self:IsAdmin() then
        return -- Don't initialize for non-admins
    end
    
    print("👑 Initializing Admin Lifecycle Panel for: " .. player.Name)
    
    -- Create GUI
    self:CreateAdminGUI()
    
    -- Setup input handling
    self:SetupInputHandling()
    
    -- Setup remote events
    self:SetupRemoteEvents()
    
    -- Update status periodically
    self:StartStatusUpdates()
    
    print("✅ Admin Lifecycle Panel ready")
end

function AdminLifecyclePanel:IsAdmin()
    -- Check if player is admin
    for _, adminId in ipairs(ADMIN_CONFIG.adminUserIds) do
        if player.UserId == adminId then
            return true
        end
    end
    
    -- Check if player is game creator
    if player.UserId == game.CreatorId then
        return true
    end
    
    return false
end

function AdminLifecyclePanel:CreateAdminGUI()
    -- Create ScreenGui
    adminGui = Instance.new("ScreenGui")
    adminGui.Name = "AdminLifecyclePanel"
    adminGui.Parent = playerGui
    adminGui.DisplayOrder = 100
    
    -- Main Frame
    mainFrame = Instance.new("Frame")
    mainFrame.Name = "MainFrame"
    mainFrame.Parent = adminGui
    mainFrame.Size = UDim2.new(0, 400, 0, 500)
    mainFrame.Position = UDim2.new(0.5, -200, 0.5, -250)
    mainFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
    mainFrame.BorderSizePixel = 0
    mainFrame.Visible = false
    
    -- Add corner radius
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 8)
    corner.Parent = mainFrame
    
    -- Title Bar
    local titleBar = Instance.new("Frame")
    titleBar.Name = "TitleBar"
    titleBar.Parent = mainFrame
    titleBar.Size = UDim2.new(1, 0, 0, 40)
    titleBar.Position = UDim2.new(0, 0, 0, 0)
    titleBar.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
    titleBar.BorderSizePixel = 0
    
    local titleCorner = Instance.new("UICorner")
    titleCorner.CornerRadius = UDim.new(0, 8)
    titleCorner.Parent = titleBar
    
    local title = Instance.new("TextLabel")
    title.Name = "Title"
    title.Parent = titleBar
    title.Size = UDim2.new(1, -50, 1, 0)
    title.Position = UDim2.new(0, 10, 0, 0)
    title.BackgroundTransparency = 1
    title.Text = "🎮 Game Lifecycle Control"
    title.TextColor3 = Color3.fromRGB(255, 255, 255)
    title.TextScaled = true
    title.Font = Enum.Font.GothamBold
    title.TextXAlignment = Enum.TextXAlignment.Left
    
    -- Close Button
    local closeButton = Instance.new("TextButton")
    closeButton.Name = "CloseButton"
    closeButton.Parent = titleBar
    closeButton.Size = UDim2.new(0, 30, 0, 30)
    closeButton.Position = UDim2.new(1, -35, 0, 5)
    closeButton.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
    closeButton.BorderSizePixel = 0
    closeButton.Text = "✕"
    closeButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    closeButton.TextScaled = true
    closeButton.Font = Enum.Font.GothamBold
    
    local closeCorner = Instance.new("UICorner")
    closeCorner.CornerRadius = UDim.new(0, 4)
    closeCorner.Parent = closeButton
    
    closeButton.MouseButton1Click:Connect(function()
        self:TogglePanel()
    end)
    
    -- Content Area
    local contentFrame = Instance.new("Frame")
    contentFrame.Name = "ContentFrame"
    contentFrame.Parent = mainFrame
    contentFrame.Size = UDim2.new(1, -20, 1, -60)
    contentFrame.Position = UDim2.new(0, 10, 0, 50)
    contentFrame.BackgroundTransparency = 1
    
    -- Status Section
    self:CreateStatusSection(contentFrame)
    
    -- Control Buttons Section
    self:CreateControlSection(contentFrame)
    
    -- Player Management Section
    self:CreatePlayerSection(contentFrame)
end

function AdminLifecyclePanel:CreateStatusSection(parent)
    local statusFrame = Instance.new("Frame")
    statusFrame.Name = "StatusFrame"
    statusFrame.Parent = parent
    statusFrame.Size = UDim2.new(1, 0, 0, 120)
    statusFrame.Position = UDim2.new(0, 0, 0, 0)
    statusFrame.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
    statusFrame.BorderSizePixel = 0
    
    local statusCorner = Instance.new("UICorner")
    statusCorner.CornerRadius = UDim.new(0, 6)
    statusCorner.Parent = statusFrame
    
    local statusTitle = Instance.new("TextLabel")
    statusTitle.Name = "StatusTitle"
    statusTitle.Parent = statusFrame
    statusTitle.Size = UDim2.new(1, -10, 0, 25)
    statusTitle.Position = UDim2.new(0, 5, 0, 5)
    statusTitle.BackgroundTransparency = 1
    statusTitle.Text = "📊 System Status"
    statusTitle.TextColor3 = Color3.fromRGB(255, 255, 255)
    statusTitle.TextScaled = true
    statusTitle.Font = Enum.Font.GothamBold
    statusTitle.TextXAlignment = Enum.TextXAlignment.Left
    
    local statusText = Instance.new("TextLabel")
    statusText.Name = "StatusText"
    statusText.Parent = statusFrame
    statusText.Size = UDim2.new(1, -10, 1, -35)
    statusText.Position = UDim2.new(0, 5, 0, 30)
    statusText.BackgroundTransparency = 1
    statusText.Text = "Loading..."
    statusText.TextColor3 = Color3.fromRGB(200, 200, 200)
    statusText.TextSize = 12
    statusText.Font = Enum.Font.Gotham
    statusText.TextXAlignment = Enum.TextXAlignment.Left
    statusText.TextYAlignment = Enum.TextYAlignment.Top
    statusText.TextWrapped = true
    
    self.statusText = statusText
end

function AdminLifecyclePanel:CreateControlSection(parent)
    local controlFrame = Instance.new("Frame")
    controlFrame.Name = "ControlFrame"
    controlFrame.Parent = parent
    controlFrame.Size = UDim2.new(1, 0, 0, 200)
    controlFrame.Position = UDim2.new(0, 0, 0, 130)
    controlFrame.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
    controlFrame.BorderSizePixel = 0
    
    local controlCorner = Instance.new("UICorner")
    controlCorner.CornerRadius = UDim.new(0, 6)
    controlCorner.Parent = controlFrame
    
    local controlTitle = Instance.new("TextLabel")
    controlTitle.Name = "ControlTitle"
    controlTitle.Parent = controlFrame
    controlTitle.Size = UDim2.new(1, -10, 0, 25)
    controlTitle.Position = UDim2.new(0, 5, 0, 5)
    controlTitle.BackgroundTransparency = 1
    controlTitle.Text = "🎮 Lifecycle Controls"
    controlTitle.TextColor3 = Color3.fromRGB(255, 255, 255)
    controlTitle.TextScaled = true
    controlTitle.Font = Enum.Font.GothamBold
    controlTitle.TextXAlignment = Enum.TextXAlignment.Left
    
    -- Control buttons
    local buttons = {
        {text = "▶️ Start Game Loop", color = Color3.fromRGB(50, 150, 50), action = "startgame"},
        {text = "⏹️ Stop Game Loop", color = Color3.fromRGB(150, 50, 50), action = "stopgame"},
        {text = "🔄 Restart Game Loop", color = Color3.fromRGB(50, 100, 150), action = "restart"},
        {text = "🔄 Reset All Systems", color = Color3.fromRGB(150, 100, 50), action = "reset"}
    }
    
    for i, buttonData in ipairs(buttons) do
        local button = Instance.new("TextButton")
        button.Name = buttonData.action .. "Button"
        button.Parent = controlFrame
        button.Size = UDim2.new(0.48, 0, 0, 35)
        button.Position = UDim2.new(((i-1) % 2) * 0.52, 0, 0, 35 + math.floor((i-1) / 2) * 45)
        button.BackgroundColor3 = buttonData.color
        button.BorderSizePixel = 0
        button.Text = buttonData.text
        button.TextColor3 = Color3.fromRGB(255, 255, 255)
        button.TextScaled = true
        button.Font = Enum.Font.GothamBold
        
        local buttonCorner = Instance.new("UICorner")
        buttonCorner.CornerRadius = UDim.new(0, 4)
        buttonCorner.Parent = button
        
        button.MouseButton1Click:Connect(function()
            self:SendCommand(buttonData.action)
        end)
        
        -- Hover effects
        button.MouseEnter:Connect(function()
            local tween = TweenService:Create(button, TweenInfo.new(0.2), {BackgroundColor3 = buttonData.color:lerp(Color3.fromRGB(255, 255, 255), 0.2)})
            tween:Play()
        end)
        
        button.MouseLeave:Connect(function()
            local tween = TweenService:Create(button, TweenInfo.new(0.2), {BackgroundColor3 = buttonData.color})
            tween:Play()
        end)
    end
end

function AdminLifecyclePanel:CreatePlayerSection(parent)
    local playerFrame = Instance.new("Frame")
    playerFrame.Name = "PlayerFrame"
    playerFrame.Parent = parent
    playerFrame.Size = UDim2.new(1, 0, 0, 120)
    playerFrame.Position = UDim2.new(0, 0, 0, 340)
    playerFrame.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
    playerFrame.BorderSizePixel = 0
    
    local playerCorner = Instance.new("UICorner")
    playerCorner.CornerRadius = UDim.new(0, 6)
    playerCorner.Parent = playerFrame
    
    local playerTitle = Instance.new("TextLabel")
    playerTitle.Name = "PlayerTitle"
    playerTitle.Parent = playerFrame
    playerTitle.Size = UDim2.new(1, -10, 0, 25)
    playerTitle.Position = UDim2.new(0, 5, 0, 5)
    playerTitle.BackgroundTransparency = 1
    playerTitle.Text = "👥 Player Management"
    playerTitle.TextColor3 = Color3.fromRGB(255, 255, 255)
    playerTitle.TextScaled = true
    playerTitle.Font = Enum.Font.GothamBold
    playerTitle.TextXAlignment = Enum.TextXAlignment.Left
    
    local playerList = Instance.new("ScrollingFrame")
    playerList.Name = "PlayerList"
    playerList.Parent = playerFrame
    playerList.Size = UDim2.new(1, -10, 1, -35)
    playerList.Position = UDim2.new(0, 5, 0, 30)
    playerList.BackgroundTransparency = 1
    playerList.BorderSizePixel = 0
    playerList.ScrollBarThickness = 4
    playerList.CanvasSize = UDim2.new(0, 0, 0, 0)
    
    self.playerList = playerList
    self:UpdatePlayerList()
end

function AdminLifecyclePanel:SetupInputHandling()
    UserInputService.InputBegan:Connect(function(input, gameProcessed)
        if gameProcessed then return end
        
        if input.KeyCode == ADMIN_CONFIG.keyBinding then
            self:TogglePanel()
        end
    end)
end

function AdminLifecyclePanel:SetupRemoteEvents()
    -- Setup remote events for admin commands
    -- This would connect to server-side remote events
end

function AdminLifecyclePanel:StartStatusUpdates()
    spawn(function()
        while true do
            self:UpdateStatus()
            wait(2) -- Update every 2 seconds
        end
    end)
    
    spawn(function()
        while true do
            if isVisible then
                self:UpdatePlayerList()
            end
            wait(5) -- Update player list every 5 seconds
        end
    end)
end

function AdminLifecyclePanel:TogglePanel()
    isVisible = not isVisible
    
    if isVisible then
        mainFrame.Visible = true
        local tween = TweenService:Create(mainFrame, TweenInfo.new(0.3, Enum.EasingStyle.Quart), {
            Size = UDim2.new(0, 400, 0, 500),
            Position = UDim2.new(0.5, -200, 0.5, -250)
        })
        tween:Play()
    else
        local tween = TweenService:Create(mainFrame, TweenInfo.new(0.3, Enum.EasingStyle.Quart), {
            Size = UDim2.new(0, 0, 0, 0),
            Position = UDim2.new(0.5, 0, 0.5, 0)
        })
        tween:Play()
        
        tween.Completed:Connect(function()
            mainFrame.Visible = false
        end)
    end
end

function AdminLifecyclePanel:UpdateStatus()
    if not self.statusText then return end
    
    -- Get current status (this would come from server via remote events)
    local statusInfo = {
        "🎮 State: Loading...",
        "⚡ Game Loop: Unknown",
        "👥 Players: " .. #Players:GetPlayers(),
        "⏰ Uptime: " .. math.floor(workspace.DistributedGameTime) .. "s",
        "💾 Memory: " .. math.floor(game.Stats.PerformanceStats.Memory.PlaceMemoryUsage.Value) .. " MB"
    }
    
    self.statusText.Text = table.concat(statusInfo, "\n")
end

function AdminLifecyclePanel:UpdatePlayerList()
    if not self.playerList then return end
    
    -- Clear existing player entries
    for _, child in pairs(self.playerList:GetChildren()) do
        if child:IsA("Frame") then
            child:Destroy()
        end
    end
    
    -- Add current players
    local yOffset = 0
    for _, plr in pairs(Players:GetPlayers()) do
        local playerFrame = Instance.new("Frame")
        playerFrame.Name = plr.Name
        playerFrame.Parent = self.playerList
        playerFrame.Size = UDim2.new(1, -10, 0, 25)
        playerFrame.Position = UDim2.new(0, 0, 0, yOffset)
        playerFrame.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
        playerFrame.BorderSizePixel = 0
        
        local playerCorner = Instance.new("UICorner")
        playerCorner.CornerRadius = UDim.new(0, 4)
        playerCorner.Parent = playerFrame
        
        local playerLabel = Instance.new("TextLabel")
        playerLabel.Parent = playerFrame
        playerLabel.Size = UDim2.new(0.7, 0, 1, 0)
        playerLabel.Position = UDim2.new(0, 5, 0, 0)
        playerLabel.BackgroundTransparency = 1
        playerLabel.Text = plr.Name
        playerLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
        playerLabel.TextScaled = true
        playerLabel.Font = Enum.Font.Gotham
        playerLabel.TextXAlignment = Enum.TextXAlignment.Left
        
        local resetButton = Instance.new("TextButton")
        resetButton.Parent = playerFrame
        resetButton.Size = UDim2.new(0.25, 0, 0.8, 0)
        resetButton.Position = UDim2.new(0.73, 0, 0.1, 0)
        resetButton.BackgroundColor3 = Color3.fromRGB(150, 100, 50)
        resetButton.BorderSizePixel = 0
        resetButton.Text = "Reset"
        resetButton.TextColor3 = Color3.fromRGB(255, 255, 255)
        resetButton.TextScaled = true
        resetButton.Font = Enum.Font.GothamBold
        
        local resetCorner = Instance.new("UICorner")
        resetCorner.CornerRadius = UDim.new(0, 3)
        resetCorner.Parent = resetButton
        
        resetButton.MouseButton1Click:Connect(function()
            self:SendCommand("reset " .. plr.Name)
        end)
        
        yOffset = yOffset + 30
    end
    
    -- Update canvas size
    self.playerList.CanvasSize = UDim2.new(0, 0, 0, yOffset)
end

function AdminLifecyclePanel:SendCommand(command)
    print("👑 Admin command: " .. command)
    
    -- This would send the command to the server
    -- For now, we'll use the chat system as implemented in GameLifecycleManager
    player:Chat("/" .. command)
end

-- Initialize if admin
if AdminLifecyclePanel:IsAdmin() then
    AdminLifecyclePanel:Initialize()
    
    -- Global access for debugging
    _G.AdminPanel = AdminLifecyclePanel
end

return AdminLifecyclePanel
