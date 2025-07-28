-- PlayerController.luau
-- Handles client-side player data, color state, and visual updates including accessibility features

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")

local RemoteEvents = require(ReplicatedStorage.Shared.modules.RemoteEvents)
local GameConstants = require(ReplicatedStorage.Shared.constants.GameConstants)
local GuiController = require(script.Parent.GuiController)

local player = Players.LocalPlayer
local PlayerController = {}
local playerData = {}
local currentColorState = "RED" -- Default color state
local originalBodyColors = {} -- Store original body colors

function PlayerController:GetCurrentColor()
    return currentColorState
end

function PlayerController:ChangeColor(colorName)
    if colorName == currentColorState then
        return -- Already this color
    end
    
    currentColorState = colorName
    
    -- Update visual appearance
    self:UpdatePlayerVisuals(colorName)
    
    -- Notify server of color change
    RemoteEvents.PlayerColorChanged:FireServer(colorName)
    
    print("🎨 Player color state changed to " .. colorName)
end

function PlayerController:StoreOriginalColors(character)
    -- Store original body colors to restore later
    local bodyColors = character:FindFirstChild("Body Colors")
    if bodyColors then
        originalBodyColors = {
            HeadColor = bodyColors.HeadColor,
            LeftArmColor = bodyColors.LeftArmColor,
            LeftLegColor = bodyColors.LeftLegColor,
            RightArmColor = bodyColors.RightArmColor,
            RightLegColor = bodyColors.RightLegColor,
            TorsoColor = bodyColors.TorsoColor
        }
    end
end

function PlayerController:UpdatePlayerVisuals(colorName)
    local character = player.Character
    if not character then return end
    
    -- Get color values
    local colors = {
        RED = Color3.new(1, 0.2, 0.2),
        GREEN = Color3.new(0.2, 1, 0.2),
        BLUE = Color3.new(0.2, 0.2, 1)
    }
    
    local targetColor = colors[colorName] or colors.RED
    
    -- Method 1: Update body colors
    local bodyColors = character:FindFirstChild("Body Colors")
    if bodyColors then
        local brickColor = BrickColor.new(targetColor)
        bodyColors.HeadColor = brickColor
        bodyColors.LeftArmColor = brickColor
        bodyColors.LeftLegColor = brickColor
        bodyColors.RightArmColor = brickColor
        bodyColors.RightLegColor = brickColor
        bodyColors.TorsoColor = brickColor
    end
    
    -- Method 2: Add glowing outline effect
    self:AddColorOutline(character, targetColor)
    
    -- Method 3: Add particle effect
    self:AddColorParticles(character, targetColor)
    
    -- Method 4: Add colorblind symbol if enabled
    self:AddColorSymbol(character, colorName)
end

function PlayerController:AddColorOutline(character, color)
    local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
    if not humanoidRootPart then return end
    
    -- Remove existing outline
    local existingOutline = humanoidRootPart:FindFirstChild("ColorOutline")
    if existingOutline then
        existingOutline:Destroy()
    end
    
    -- Create new outline effect
    local outline = Instance.new("SelectionBox")
    outline.Name = "ColorOutline"
    outline.Adornee = character
    outline.Color3 = color
    outline.LineThickness = 0.3
    outline.Transparency = 0.3
    outline.Parent = humanoidRootPart
    
    -- Pulsing animation
    local pulseInfo = TweenInfo.new(1, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true)
    local pulseTween = TweenService:Create(outline, pulseInfo, {
        Transparency = 0.7,
        LineThickness = 0.5
    })
    pulseTween:Play()
end

function PlayerController:AddColorParticles(character, color)
    local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
    if not humanoidRootPart then return end
    
    -- Remove existing particles
    local existingParticles = humanoidRootPart:FindFirstChild("ColorParticles")
    if existingParticles then
        existingParticles:Destroy()
    end
    
    -- Create particle attachment
    local attachment = Instance.new("Attachment")
    attachment.Name = "ColorParticles"
    attachment.Parent = humanoidRootPart
    
    -- Create particle emitter
    local particles = Instance.new("ParticleEmitter")
    particles.Color = ColorSequence.new(color)
    particles.Size = NumberSequence.new{
        NumberSequenceKeypoint.new(0, 0.5),
        NumberSequenceKeypoint.new(0.5, 1),
        NumberSequenceKeypoint.new(1, 0)
    }
    particles.Lifetime = NumberRange.new(0.5, 1.5)
    particles.Rate = 10
    particles.SpreadAngle = Vector2.new(45, 45)
    particles.Speed = NumberRange.new(2, 5)
    particles.Transparency = NumberSequence.new{
        NumberSequenceKeypoint.new(0, 1),
        NumberSequenceKeypoint.new(0.5, 0.5),
        NumberSequenceKeypoint.new(1, 1)
    }
    particles.Parent = attachment
end

function PlayerController:AddColorSymbol(character, colorName)
    local head = character:FindFirstChild("Head")
    if not head then return end
    
    -- Remove existing symbol
    local existingSymbol = head:FindFirstChild("ColorSymbolGui")
    if existingSymbol then
        existingSymbol:Destroy()
    end
    
    -- Only add symbol if colorblind mode is enabled
    if not playerData.settings or not playerData.settings.colorblindMode then
        return
    end
    
    -- Create billboard GUI for symbol
    local symbolGui = Instance.new("BillboardGui")
    symbolGui.Name = "ColorSymbolGui"
    symbolGui.Size = UDim2.new(0, 100, 0, 100)
    symbolGui.StudsOffset = Vector3.new(0, 2, 0)
    symbolGui.Parent = head
    
    -- Create symbol label
    local symbolLabel = Instance.new("TextLabel")
    symbolLabel.Size = UDim2.new(1, 0, 1, 0)
    symbolLabel.BackgroundTransparency = 1
    symbolLabel.Text = GameConstants.COLORBLIND_SYMBOLS[colorName] or "?"
    symbolLabel.TextColor3 = Color3.new(1, 1, 1)
    symbolLabel.TextScaled = true
    symbolLabel.Font = Enum.Font.SourceSansBold
    symbolLabel.TextStrokeTransparency = 0
    symbolLabel.TextStrokeColor3 = Color3.new(0, 0, 0)
    symbolLabel.Parent = symbolGui
    
    -- Add pulsing animation
    local pulseInfo = TweenInfo.new(1, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true)
    local pulseTween = TweenService:Create(symbolLabel, pulseInfo, {
        TextTransparency = 0.3
    })
    pulseTween:Play()
    
    print("🔤 Added colorblind symbol " .. GameConstants.COLORBLIND_SYMBOLS[colorName] .. " for " .. colorName)
end

function PlayerController:RestoreOriginalAppearance(character)
    -- Restore original body colors
    local bodyColors = character:FindFirstChild("Body Colors")
    if bodyColors and originalBodyColors.HeadColor then
        bodyColors.HeadColor = originalBodyColors.HeadColor
        bodyColors.LeftArmColor = originalBodyColors.LeftArmColor
        bodyColors.LeftLegColor = originalBodyColors.LeftLegColor
        bodyColors.RightArmColor = originalBodyColors.RightArmColor
        bodyColors.RightLegColor = originalBodyColors.RightLegColor
        bodyColors.TorsoColor = originalBodyColors.TorsoColor
    end
    
    -- Remove effects
    local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
    if humanoidRootPart then
        local outline = humanoidRootPart:FindFirstChild("ColorOutline")
        if outline then outline:Destroy() end
        
        local particles = humanoidRootPart:FindFirstChild("ColorParticles")
        if particles then particles:Destroy() end
    end
    
    -- Remove symbol
    local head = character:FindFirstChild("Head")
    if head then
        local symbolGui = head:FindFirstChild("ColorSymbolGui")
        if symbolGui then symbolGui:Destroy() end
    end
end

function PlayerController:OnCharacterAdded(character)
    -- Store original appearance
    self:StoreOriginalColors(character)
    
    -- Apply current color state
    wait(1) -- Wait for character to fully load
    self:UpdatePlayerVisuals(currentColorState)
end

function PlayerController:UpdatePlayerData(data)
    playerData = data
    print("💰 Player data updated:", data.coins, "coins, Level", data.level)
    
    -- Update any UI elements here
    -- GuiController:UpdateStatsDisplay(data)
end

function PlayerController:GetPlayerData()
    return playerData
end

function PlayerController:PurchaseItem(itemName, cost)
    if playerData.coins >= cost then
        RemoteEvents.PurchaseItem:FireServer(itemName, cost)
        return true
    else
        print("❌ Not enough coins!")
        return false
    end
end

function PlayerController:Init()
    -- Listen for data updates from server
    RemoteEvents.PlayerDataUpdated.OnClientEvent:Connect(function(data)
        self:UpdatePlayerData(data)
    end)
    
    -- Handle character spawning
    if player.Character then
        self:OnCharacterAdded(player.Character)
    end
    
    player.CharacterAdded:Connect(function(character)
        self:OnCharacterAdded(character)
    end)
    
    -- Listen for game state changes
    RemoteEvents.GameStarted.OnClientEvent:Connect(function(initialColor)
        -- During game, use server-controlled color
        print("🎮 Game started, server controls color: " .. initialColor)
    end)
    
    RemoteEvents.GameEnded.OnClientEvent:Connect(function(results)
        -- After game, restore manual color control
        self:UpdatePlayerVisuals(currentColorState)
        print("🏁 Game ended, restored manual color control")
    end)
    
    print("✅ PlayerController initialized")
end

return PlayerController
