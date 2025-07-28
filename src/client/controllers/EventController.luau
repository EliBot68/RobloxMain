-- EventController.luau
-- Handles client-side event effects, music, and temporary cosmetics

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local SoundService = game:GetService("SoundService")
local Lighting = game:GetService("Lighting")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local RemoteEvents = require(ReplicatedStorage.Shared.modules.RemoteEvents)

local EventController = {}

-- Event state
local currentEvent = nil
local eventMusic = nil
local originalLighting = {}
local temporaryCosmetics = {}
local eventEffects = {}

function EventController:Init()
    self:SetupRemoteConnections()
    self:SaveOriginalLighting()
    print("✅ EventController initialized")
end

function EventController:SetupRemoteConnections()
    -- Apply event effects
    RemoteEvents.ApplyEventEffects.OnClientEvent:Connect(function(eventData)
        self:ApplyEventTheme(eventData)
    end)
    
    -- Play event music
    RemoteEvents.PlayEventMusic.OnClientEvent:Connect(function(musicId)
        self:PlayEventMusic(musicId)
    end)
    
    -- Show event completion
    RemoteEvents.ShowEventCompletion.OnClientEvent:Connect(function(completionData)
        self:ShowEventCompletion(completionData)
    end)
    
    -- Apply temporary skin
    RemoteEvents.ApplyTemporarySkin.OnClientEvent:Connect(function(skinName, duration)
        self:ApplyTemporarySkin(skinName, duration)
    end)
    
    -- Apply temporary trail
    RemoteEvents.ApplyTemporaryTrail.OnClientEvent:Connect(function(trailName, duration)
        self:ApplyTemporaryTrail(trailName, duration)
    end)
end

function EventController:SaveOriginalLighting()
    originalLighting = {
        Ambient = Lighting.Ambient,
        OutdoorAmbient = Lighting.OutdoorAmbient,
        Brightness = Lighting.Brightness,
        ColorShift_Bottom = Lighting.ColorShift_Bottom,
        ColorShift_Top = Lighting.ColorShift_Top,
        FogColor = Lighting.FogColor,
        FogEnd = Lighting.FogEnd,
        FogStart = Lighting.FogStart
    }
end

function EventController:ApplyEventTheme(eventData)
    currentEvent = eventData
    
    -- Apply theme-specific effects
    if eventData.id == "rainbow_rush" then
        self:ApplyRainbowTheme()
    elseif eventData.id == "neon_nights" then
        self:ApplyNeonTheme()
    elseif eventData.id == "fire_festival" then
        self:ApplyFireTheme()
    elseif eventData.id == "ice_crystal" then
        self:ApplyIceTheme()
    end
    
    -- Show event start notification
    self:ShowEventStartNotification(eventData)
end

function EventController:ApplyRainbowTheme()
    -- Rainbow lighting effects
    Lighting.Ambient = Color3.fromRGB(100, 50, 100)
    Lighting.OutdoorAmbient = Color3.fromRGB(150, 100, 150)
    Lighting.ColorShift_Top = Color3.fromRGB(255, 200, 255)
    
    -- Start rainbow cycle animation
    eventEffects.rainbowCycle = RunService.Heartbeat:Connect(function()
        local time = tick() * 2
        local r = math.sin(time) * 0.5 + 0.5
        local g = math.sin(time + 2) * 0.5 + 0.5
        local b = math.sin(time + 4) * 0.5 + 0.5
        
        Lighting.ColorShift_Bottom = Color3.new(r, g, b)
    end)
    
    print("🌈 Rainbow Rush theme activated!")
end

function EventController:ApplyNeonTheme()
    -- Dark neon lighting
    Lighting.Ambient = Color3.fromRGB(10, 10, 20)
    Lighting.OutdoorAmbient = Color3.fromRGB(20, 20, 40)
    Lighting.Brightness = 0.5
    Lighting.ColorShift_Top = Color3.fromRGB(0, 100, 255)
    Lighting.ColorShift_Bottom = Color3.fromRGB(255, 0, 255)
    
    -- Add fog for cyber atmosphere
    Lighting.FogColor = Color3.fromRGB(50, 0, 100)
    Lighting.FogEnd = 200
    Lighting.FogStart = 50
    
    print("🌃 Neon Nights theme activated!")
end

function EventController:ApplyFireTheme()
    -- Hot fire lighting
    Lighting.Ambient = Color3.fromRGB(100, 50, 20)
    Lighting.OutdoorAmbient = Color3.fromRGB(150, 80, 30)
    Lighting.ColorShift_Top = Color3.fromRGB(255, 150, 50)
    Lighting.ColorShift_Bottom = Color3.fromRGB(255, 100, 0)
    
    -- Fire particle effects in the air
    eventEffects.fireParticles = RunService.Heartbeat:Connect(function()
        local time = tick()
        local intensity = math.sin(time * 3) * 0.3 + 0.7
        Lighting.Brightness = intensity
    end)
    
    print("🔥 Fire Festival theme activated!")
end

function EventController:ApplyIceTheme()
    -- Cold ice lighting
    Lighting.Ambient = Color3.fromRGB(50, 80, 120)
    Lighting.OutdoorAmbient = Color3.fromRGB(80, 120, 180)
    Lighting.ColorShift_Top = Color3.fromRGB(150, 200, 255)
    Lighting.ColorShift_Bottom = Color3.fromRGB(200, 230, 255)
    
    -- Add icy fog
    Lighting.FogColor = Color3.fromRGB(200, 230, 255)
    Lighting.FogEnd = 300
    Lighting.FogStart = 100
    
    print("❄️ Ice Crystal theme activated!")
end

function EventController:PlayEventMusic(musicId)
    -- Stop current music
    if eventMusic then
        eventMusic:Stop()
        eventMusic:Destroy()
    end
    
    -- Play new event music
    eventMusic = Instance.new("Sound")
    eventMusic.SoundId = musicId
    eventMusic.Volume = 0.3
    eventMusic.Looped = true
    eventMusic.Parent = workspace
    eventMusic:Play()
    
    print("🎵 Event music started")
end

function EventController:ShowEventStartNotification(eventData)
    -- Create event start overlay
    local eventGui = Instance.new("ScreenGui")
    eventGui.Name = "EventStartGui"
    eventGui.Parent = playerGui
    
    local eventFrame = Instance.new("Frame")
    eventFrame.Size = UDim2.new(0, 500, 0, 150)
    eventFrame.Position = UDim2.new(0.5, -250, 0.3, 0)
    eventFrame.BackgroundColor3 = Color3.fromRGB(100, 0, 200)
    eventFrame.BorderSizePixel = 0
    eventFrame.Parent = eventGui
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 20)
    corner.Parent = eventFrame
    
    local titleLabel = Instance.new("TextLabel")
    titleLabel.Size = UDim2.new(1, 0, 0.5, 0)
    titleLabel.BackgroundTransparency = 1
    titleLabel.Text = "EVENT ACTIVATED!"
    titleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    titleLabel.TextScaled = true
    titleLabel.Font = Enum.Font.GothamBold
    titleLabel.Parent = eventFrame
    
    local eventNameLabel = Instance.new("TextLabel")
    eventNameLabel.Size = UDim2.new(1, 0, 0.3, 0)
    eventNameLabel.Position = UDim2.new(0, 0, 0.5, 0)
    eventNameLabel.BackgroundTransparency = 1
    eventNameLabel.Text = eventData.name
    eventNameLabel.TextColor3 = Color3.fromRGB(255, 255, 0)
    eventNameLabel.TextScaled = true
    eventNameLabel.Font = Enum.Font.GothamBold
    eventNameLabel.Parent = eventFrame
    
    local descLabel = Instance.new("TextLabel")
    descLabel.Size = UDim2.new(1, 0, 0.2, 0)
    descLabel.Position = UDim2.new(0, 0, 0.8, 0)
    descLabel.BackgroundTransparency = 1
    descLabel.Text = eventData.description
    descLabel.TextColor3 = Color3.fromRGB(200, 200, 255)
    descLabel.TextScaled = true
    descLabel.Font = Enum.Font.Gotham
    descLabel.Parent = eventFrame
    
    -- Animate notification
    eventFrame.Size = UDim2.new(0, 0, 0, 0)
    local appearTween = TweenService:Create(eventFrame, TweenInfo.new(0.5, Enum.EasingStyle.Back), {
        Size = UDim2.new(0, 500, 0, 150)
    })
    
    appearTween:Play()
    
    -- Auto-remove after 4 seconds
    wait(4)
    local fadeOut = TweenService:Create(eventFrame, TweenInfo.new(0.5, Enum.EasingStyle.Quad), {
        BackgroundTransparency = 1
    })
    
    TweenService:Create(titleLabel, TweenInfo.new(0.5, Enum.EasingStyle.Quad), {
        TextTransparency = 1
    }):Play()
    
    TweenService:Create(eventNameLabel, TweenInfo.new(0.5, Enum.EasingStyle.Quad), {
        TextTransparency = 1
    }):Play()
    
    TweenService:Create(descLabel, TweenInfo.new(0.5, Enum.EasingStyle.Quad), {
        TextTransparency = 1
    }):Play()
    
    fadeOut:Play()
    fadeOut.Completed:Connect(function()
        eventGui:Destroy()
    end)
end

function EventController:ShowEventCompletion(completionData)
    -- Create completion notification
    local completionGui = Instance.new("ScreenGui")
    completionGui.Name = "EventCompletionGui"
    completionGui.Parent = playerGui
    
    local completionFrame = Instance.new("Frame")
    completionFrame.Size = UDim2.new(0, 400, 0, 200)
    completionFrame.Position = UDim2.new(0.5, -200, 0.4, 0)
    completionFrame.BackgroundColor3 = Color3.fromRGB(0, 150, 100)
    completionFrame.BorderSizePixel = 0
    completionFrame.Parent = completionGui
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 15)
    corner.Parent = completionFrame
    
    local titleLabel = Instance.new("TextLabel")
    titleLabel.Size = UDim2.new(1, 0, 0.3, 0)
    titleLabel.BackgroundTransparency = 1
    titleLabel.Text = "EVENT COMPLETE!"
    titleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    titleLabel.TextScaled = true
    titleLabel.Font = Enum.Font.GothamBold
    titleLabel.Parent = completionFrame
    
    local eventLabel = Instance.new("TextLabel")
    eventLabel.Size = UDim2.new(1, 0, 0.2, 0)
    eventLabel.Position = UDim2.new(0, 0, 0.3, 0)
    eventLabel.BackgroundTransparency = 1
    eventLabel.Text = completionData.eventName
    eventLabel.TextColor3 = Color3.fromRGB(255, 255, 0)
    eventLabel.TextScaled = true
    eventLabel.Font = Enum.Font.Gotham
    eventLabel.Parent = completionFrame
    
    local bonusLabel = Instance.new("TextLabel")
    bonusLabel.Size = UDim2.new(1, 0, 0.5, 0)
    bonusLabel.Position = UDim2.new(0, 0, 0.5, 0)
    bonusLabel.BackgroundTransparency = 1
    bonusLabel.Text = "Bonus Rewards:\n+" .. completionData.bonusCoins .. " Coins\n+" .. completionData.bonusXp .. " XP"
    bonusLabel.TextColor3 = Color3.fromRGB(200, 255, 200)
    bonusLabel.TextScaled = true
    bonusLabel.Font = Enum.Font.Gotham
    bonusLabel.Parent = completionFrame
    
    -- Animate and auto-remove
    completionFrame.Size = UDim2.new(0, 0, 0, 0)
    local appearTween = TweenService:Create(completionFrame, TweenInfo.new(0.4, Enum.EasingStyle.Back), {
        Size = UDim2.new(0, 400, 0, 200)
    })
    
    appearTween:Play()
    
    -- Auto-remove after 5 seconds
    wait(5)
    local fadeOut = TweenService:Create(completionFrame, TweenInfo.new(0.3, Enum.EasingStyle.Quad), {
        BackgroundTransparency = 1
    })
    
    fadeOut:Play()
    fadeOut.Completed:Connect(function()
        completionGui:Destroy()
    end)
end

function EventController:ApplyTemporarySkin(skinName, duration)
    temporaryCosmetics.skin = {
        name = skinName,
        endTime = tick() + duration
    }
    
    -- Apply visual skin effect to player
    local character = player.Character
    if character then
        local humanoid = character:FindFirstChild("Humanoid")
        if humanoid then
            -- Change player appearance temporarily
            for _, part in pairs(character:GetChildren()) do
                if part:IsA("BasePart") and part.Name ~= "HumanoidRootPart" then
                    -- Apply special skin colors/effects based on skin name
                    if skinName == "Rainbow Runner" then
                        part.Color = Color3.fromHSV(tick() % 1, 1, 1)
                    elseif skinName == "Cyber Runner" then
                        part.Color = Color3.fromRGB(0, 255, 255)
                        part.Material = Enum.Material.Neon
                    elseif skinName == "Fire Dancer" then
                        part.Color = Color3.fromRGB(255, 100, 0)
                        part.Material = Enum.Material.Neon
                    elseif skinName == "Ice Walker" then
                        part.Color = Color3.fromRGB(200, 230, 255)
                        part.Material = Enum.Material.Ice
                    end
                end
            end
        end
    end
    
    print("👤 Applied temporary skin: " .. skinName)
    
    -- Schedule removal
    spawn(function()
        wait(duration)
        self:RemoveTemporarySkin()
    end)
end

function EventController:ApplyTemporaryTrail(trailName, duration)
    temporaryCosmetics.trail = {
        name = trailName,
        endTime = tick() + duration
    }
    
    -- Create trail effect
    local character = player.Character
    if character and character:FindFirstChild("HumanoidRootPart") then
        local rootPart = character.HumanoidRootPart
        
        local attachment0 = Instance.new("Attachment")
        attachment0.Position = Vector3.new(-1, 0, 0)
        attachment0.Parent = rootPart
        
        local attachment1 = Instance.new("Attachment")
        attachment1.Position = Vector3.new(1, 0, 0)
        attachment1.Parent = rootPart
        
        local trail = Instance.new("Trail")
        trail.Attachment0 = attachment0
        trail.Attachment1 = attachment1
        trail.Lifetime = 2
        trail.MinLength = 0
        trail.Parent = rootPart
        
        -- Set trail colors based on trail name
        if trailName == "Rainbow Burst" then
            trail.Color = ColorSequence.new{
                ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 0, 0)),
                ColorSequenceKeypoint.new(0.5, Color3.fromRGB(0, 255, 0)),
                ColorSequenceKeypoint.new(1, Color3.fromRGB(0, 0, 255))
            }
        elseif trailName == "Neon Stream" then
            trail.Color = ColorSequence.new(Color3.fromRGB(0, 255, 255))
        elseif trailName == "Flame Trail" then
            trail.Color = ColorSequence.new(Color3.fromRGB(255, 100, 0))
        elseif trailName == "Frost Trail" then
            trail.Color = ColorSequence.new(Color3.fromRGB(200, 230, 255))
        end
        
        trail.Transparency = NumberSequence.new{
            NumberSequenceKeypoint.new(0, 0.5),
            NumberSequenceKeypoint.new(1, 1)
        }
        
        temporaryCosmetics.trailObject = trail
    end
    
    print("✨ Applied temporary trail: " .. trailName)
    
    -- Schedule removal
    spawn(function()
        wait(duration)
        self:RemoveTemporaryTrail()
    end)
end

function EventController:RemoveTemporarySkin()
    temporaryCosmetics.skin = nil
    
    -- Reset player appearance
    local character = player.Character
    if character then
        for _, part in pairs(character:GetChildren()) do
            if part:IsA("BasePart") and part.Name ~= "HumanoidRootPart" then
                -- Reset to default colors
                part.Color = Color3.fromRGB(163, 162, 165) -- Default gray
                part.Material = Enum.Material.Plastic
            end
        end
    end
    
    print("👤 Removed temporary skin")
end

function EventController:RemoveTemporaryTrail()
    temporaryCosmetics.trail = nil
    
    if temporaryCosmetics.trailObject then
        temporaryCosmetics.trailObject:Destroy()
        temporaryCosmetics.trailObject = nil
    end
    
    print("✨ Removed temporary trail")
end

function EventController:RestoreLighting()
    -- Stop any event effects
    for effectName, connection in pairs(eventEffects) do
        if connection then
            connection:Disconnect()
        end
    end
    eventEffects = {}
    
    -- Restore original lighting
    for property, value in pairs(originalLighting) do
        Lighting[property] = value
    end
    
    -- Stop event music
    if eventMusic then
        eventMusic:Stop()
        eventMusic:Destroy()
        eventMusic = nil
    end
    
    print("🌅 Restored original lighting and effects")
end

-- Clean up when player leaves or game ends
game.Players.PlayerRemoving:Connect(function(leavingPlayer)
    if leavingPlayer == player then
        EventController:RestoreLighting()
    end
end)

return EventController
