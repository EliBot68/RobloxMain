-- VIPStatusController.luau
-- Displays crown icons next to VIP players

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local RemoteEvents = require(ReplicatedStorage.Shared.modules.RemoteEvents)

local player = Players.LocalPlayer

local VIPStatusController = {}

-- Track VIP players
local vipPlayers = {}
local vipGuis = {}

function VIPStatusController:CreateVIPCrown(targetPlayer)
    if not targetPlayer.Character then return end
    
    local head = targetPlayer.Character:FindFirstChild("Head")
    if not head then return end
    
    -- Remove existing crown if it exists
    local existingCrown = head:FindFirstChild("VIPCrown")
    if existingCrown then
        existingCrown:Destroy()
    end
    
    -- Create billboard GUI for crown
    local billboardGui = Instance.new("BillboardGui")
    billboardGui.Name = "VIPCrown"
    billboardGui.Size = UDim2.new(0, 100, 0, 50)
    billboardGui.StudsOffset = Vector3.new(0, 2.5, 0)
    billboardGui.Parent = head
    
    -- Crown background
    local crownFrame = Instance.new("Frame")
    crownFrame.Name = "CrownFrame"
    crownFrame.Size = UDim2.new(0, 40, 0, 30)
    crownFrame.Position = UDim2.new(0.5, -20, 0, 0)
    crownFrame.BackgroundColor3 = Color3.fromRGB(255, 215, 0)
    crownFrame.BorderSizePixel = 0
    crownFrame.Parent = billboardGui
    
    local crownCorner = Instance.new("UICorner")
    crownCorner.CornerRadius = UDim.new(0, 8)
    crownCorner.Parent = crownFrame
    
    -- Crown gradient
    local crownGradient = Instance.new("UIGradient")
    crownGradient.Color = ColorSequence.new{
        ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 235, 59)),
        ColorSequenceKeypoint.new(0.5, Color3.fromRGB(255, 215, 0)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 193, 7))
    }
    crownGradient.Rotation = 90
    crownGradient.Parent = crownFrame
    
    -- Crown icon
    local crownIcon = Instance.new("TextLabel")
    crownIcon.Name = "CrownIcon"
    crownIcon.Size = UDim2.new(1, 0, 1, 0)
    crownIcon.Position = UDim2.new(0, 0, 0, 0)
    crownIcon.BackgroundTransparency = 1
    crownIcon.Text = "👑"
    crownIcon.TextColor3 = Color3.fromRGB(255, 255, 255)
    crownIcon.TextSize = 20
    crownIcon.Font = Enum.Font.GothamBold
    crownIcon.TextStrokeTransparency = 0.5
    crownIcon.TextStrokeColor3 = Color3.new(0, 0, 0)
    crownIcon.Parent = crownFrame
    
    -- VIP text below crown
    local vipText = Instance.new("TextLabel")
    vipText.Name = "VipText"
    vipText.Size = UDim2.new(0, 60, 0, 15)
    vipText.Position = UDim2.new(0.5, -30, 1, 0)
    vipText.BackgroundTransparency = 1
    vipText.Text = "VIP"
    vipText.TextColor3 = Color3.fromRGB(255, 215, 0)
    vipText.TextSize = 12
    vipText.Font = Enum.Font.GothamBold
    vipText.TextStrokeTransparency = 0.5
    vipText.TextStrokeColor3 = Color3.new(0, 0, 0)
    vipText.Parent = billboardGui
    
    -- Event-driven floating animation
    spawn(function()
        local floatEvent = Instance.new("BindableEvent")
        local frameCount = 0
        
        local function updateFloat()
            if billboardGui.Parent and head.Parent then
                frameCount = frameCount + 1
                billboardGui.StudsOffset = Vector3.new(0, 2.5 + math.sin(tick() * 2) * 0.3, 0)
                
                if frameCount < 20 then
                    task.wait(0.16) -- Reduced frequency for performance
                    floatEvent:Fire()
                else
                    frameCount = 0
                    task.wait(0.2) -- Longer pause between cycles
                    floatEvent:Fire()
                end
            end
        end
        
        floatEvent.Event:Connect(updateFloat)
        updateFloat() -- Start the animation
    end)
    
    -- Event-driven sparkle effect
    spawn(function()
        local sparkleEvent = Instance.new("BindableEvent")
        
        local function createSparkle()
            if billboardGui.Parent and head.Parent then
                -- Create sparkle
                local sparkle = Instance.new("Frame")
                sparkle.Name = "Sparkle"
                sparkle.Size = UDim2.new(0, 4, 0, 4)
                sparkle.Position = UDim2.new(
                    math.random(0, 100) / 100, 
                    math.random(-20, 20), 
                    math.random(0, 100) / 100, 
                    math.random(-10, 10)
                )
                sparkle.BackgroundColor3 = Color3.fromRGB(255, 255, 100)
                sparkle.BorderSizePixel = 0
                sparkle.Parent = billboardGui
                
                local sparkleCorner = Instance.new("UICorner")
                sparkleCorner.CornerRadius = UDim.new(0.5, 0)
                sparkleCorner.Parent = sparkle
                
                -- Event-driven sparkle animation
                spawn(function()
                    local fadeEvent = Instance.new("BindableEvent")
                    local alpha = 1
                    
                    local function fadeStep()
                        if sparkle.Parent and alpha > 0 then
                            sparkle.BackgroundTransparency = 1 - alpha
                            sparkle.Size = UDim2.new(0, 4 * alpha, 0, 4 * alpha)
                            alpha = alpha - 0.05
                            
                            task.wait(0.08) -- Increased interval for better performance
                            fadeEvent:Fire()
                        else
                            if sparkle.Parent then
                                sparkle:Destroy()
                            end
                        end
                    end
                    
                    fadeEvent.Event:Connect(fadeStep)
                    fadeStep()
                end)
                
                -- Schedule next sparkle
                task.wait(math.random(2, 5))
                sparkleEvent:Fire()
            end
        end
        
        sparkleEvent.Event:Connect(createSparkle)
        createSparkle() -- Start the sparkle effect
    end)
    
    vipGuis[targetPlayer.UserId] = billboardGui
    print("👑 Created VIP crown for " .. targetPlayer.Name)
end

function VIPStatusController:RemoveVIPCrown(targetPlayer)
    local gui = vipGuis[targetPlayer.UserId]
    if gui and gui.Parent then
        gui:Destroy()
    end
    vipGuis[targetPlayer.UserId] = nil
    print("👑 Removed VIP crown from " .. targetPlayer.Name)
end

function VIPStatusController:UpdateVIPStatus(targetPlayer, isVIP)
    if isVIP and not vipPlayers[targetPlayer.UserId] then
        -- Player became VIP
        vipPlayers[targetPlayer.UserId] = true
        if targetPlayer.Character then
            self:CreateVIPCrown(targetPlayer)
        end
    elseif not isVIP and vipPlayers[targetPlayer.UserId] then
        -- Player lost VIP status
        vipPlayers[targetPlayer.UserId] = false
        self:RemoveVIPCrown(targetPlayer)
    end
end

function VIPStatusController:CheckPlayerVIPStatus(targetPlayer)
    -- Request VIP status from server
    RemoteEvents.RequestVIPStatus:FireServer(targetPlayer)
end

function VIPStatusController:Initialize()
    print("👑 VIPStatusController initializing...")
    
    -- Listen for VIP status updates
    RemoteEvents.VIPStatusUpdated.OnClientEvent:Connect(function(targetPlayer, isVIP)
        if targetPlayer and targetPlayer.Parent then
            self:UpdateVIPStatus(targetPlayer, isVIP)
        end
    end)
    
    -- Handle player character spawning
    local function onCharacterAdded(character, targetPlayer)
        wait(1) -- Wait for character to fully load
        if vipPlayers[targetPlayer.UserId] then
            self:CreateVIPCrown(targetPlayer)
        end
    end
    
    -- Set up for existing players
    for _, targetPlayer in pairs(Players:GetPlayers()) do
        if targetPlayer.Character then
            onCharacterAdded(targetPlayer.Character, targetPlayer)
        end
        
        targetPlayer.CharacterAdded:Connect(function(character)
            onCharacterAdded(character, targetPlayer)
        end)
        
        -- Request initial VIP status
        self:CheckPlayerVIPStatus(targetPlayer)
    end
    
    -- Set up for new players
    Players.PlayerAdded:Connect(function(targetPlayer)
        if targetPlayer.Character then
            onCharacterAdded(targetPlayer.Character, targetPlayer)
        end
        
        targetPlayer.CharacterAdded:Connect(function(character)
            onCharacterAdded(character, targetPlayer)
        end)
        
        -- Request VIP status for new player
        wait(1) -- Give server time to process
        self:CheckPlayerVIPStatus(targetPlayer)
    end)
    
    -- Clean up when players leave
    Players.PlayerRemoving:Connect(function(targetPlayer)
        vipPlayers[targetPlayer.UserId] = nil
        if vipGuis[targetPlayer.UserId] then
            vipGuis[targetPlayer.UserId]:Destroy()
            vipGuis[targetPlayer.UserId] = nil
        end
    end)
    
    print("✅ VIPStatusController initialized!")
end

-- Auto-initialize
VIPStatusController:Initialize()

return VIPStatusController
