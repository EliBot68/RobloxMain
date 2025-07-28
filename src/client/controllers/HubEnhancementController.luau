-- HubEnhancementController.luau
-- Manages animated NPCs, ambient sounds, tip signs, and party stand in the hub

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local SoundService = game:GetService("SoundService")
local RunService = game:GetService("RunService")
local TextService = game:GetService("TextService")
local Workspace = game:GetService("Workspace")

local RemoteEvents = require(ReplicatedStorage.Shared.modules.RemoteEvents)

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local HubEnhancementController = {}

-- Configuration
local HUB_CONFIG = {
    npcs = {
        {
            name = "Coach Ruby",
            position = Vector3.new(10, 4, 15),
            skinColor = Color3.fromRGB(194, 154, 108),
            shirtColor = Color3.fromRGB(255, 100, 100),
            pantsColor = Color3.fromRGB(50, 50, 100),
            dialogues = {
                "Welcome to Color Rush! Ready to test your reflexes?",
                "Remember: match your color to pass through barriers!",
                "The faster you go, the more coins you earn!",
                "Don't forget to visit the shop for upgrades!",
                "Practice makes perfect, runner!"
            },
            walkPoints = {
                Vector3.new(8, 4, 15),
                Vector3.new(12, 4, 15),
                Vector3.new(10, 4, 18),
                Vector3.new(10, 4, 12)
            },
            walkSpeed = 3
        },
        {
            name = "Merchant Max",
            position = Vector3.new(-8, 4, 10),
            skinColor = Color3.fromRGB(245, 205, 148),
            shirtColor = Color3.fromRGB(100, 255, 100),
            pantsColor = Color3.fromRGB(100, 50, 200),
            dialogues = {
                "Check out my shop for amazing upgrades!",
                "Need more speed? I've got the gear for you!",
                "Coins burning a hole in your pocket? Spend them here!",
                "New items arrive daily in my shop!",
                "Quality gear for quality runners!"
            },
            walkPoints = {
                Vector3.new(-10, 4, 8),
                Vector3.new(-6, 4, 8),
                Vector3.new(-6, 4, 12),
                Vector3.new(-10, 4, 12)
            },
            walkSpeed = 2
        },
        {
            name = "Party Pete",
            position = Vector3.new(20, 4, 5),
            skinColor = Color3.fromRGB(255, 220, 177),
            shirtColor = Color3.fromRGB(255, 200, 50),
            pantsColor = Color3.fromRGB(200, 100, 255),
            dialogues = {
                "Want to race with friends? Join a party!",
                "Multiplayer runs are twice the fun!",
                "Challenge your friends to beat your score!",
                "The more the merrier in Color Rush!",
                "Team up and dominate the leaderboards!"
            },
            walkPoints = {
                Vector3.new(18, 4, 3),
                Vector3.new(22, 4, 3),
                Vector3.new(22, 4, 7),
                Vector3.new(18, 4, 7)
            },
            walkSpeed = 4
        }
    },
    tipSigns = {
        {
            position = Vector3.new(0, 4, 20),
            rotation = Vector3.new(0, 0, 0),
            tips = {
                "💡 TIP: Don't forget to upgrade your gear!",
                "💡 TIP: Collect coins during runs for maximum profit!",
                "💡 TIP: Match your color to pass through barriers!"
            }
        },
        {
            position = Vector3.new(-15, 4, 0),
            rotation = Vector3.new(0, 45, 0),
            tips = {
                "🎯 PRO TIP: Higher speeds = more coin multipliers!",
                "🎯 PRO TIP: Visit the fountain for temporary boosts!",
                "🎯 PRO TIP: Check achievements for bonus rewards!"
            }
        },
        {
            position = Vector3.new(15, 4, -10),
            rotation = Vector3.new(0, -30, 0),
            tips = {
                "⭐ EXPERT TIP: Chain perfect runs for streak bonuses!",
                "⭐ EXPERT TIP: Use trails to intimidate other players!",
                "⭐ EXPERT TIP: Join events for exclusive rewards!"
            }
        }
    },
    partyStand = {
        position = Vector3.new(20, 4, 0),
        rotation = Vector3.new(0, 180, 0),
        size = Vector3.new(8, 6, 4)
    }
}

local AMBIENT_SOUNDS = {
    hubMusic = {
        soundId = "rbxassetid://1845756489", -- Peaceful/chill music
        volume = 0.25,
        looped = true,
        pitch = 1.0
    },
    ambientNature = {
        soundId = "rbxassetid://131961136", -- Birds chirping (free asset)
        volume = 0.15,
        looped = true,
        pitch = 0.9
    },
    fountainWater = {
        soundId = "rbxassetid://132477420", -- Water flowing (free asset)
        volume = 0.12,
        looped = true,
        pitch = 1.1
    },
    marketChatter = {
        soundId = "rbxassetid://186311262", -- Crowd/market ambience
        volume = 0.08,
        looped = true,
        pitch = 0.8
    },
    footsteps = {
        soundId = "rbxassetid://131961136", -- Footstep sounds for NPCs
        volume = 0.1,
        looped = false,
        pitch = 1.2
    }
}

-- State tracking
local npcs = {}
local tipSigns = {}
local partyStand = nil
local ambientSounds = {}
local hubEnhanced = false

function HubEnhancementController:CreateNPC(npcData)
    -- Create an animated NPC character
    local npc = Instance.new("Model")
    npc.Name = npcData.name
    npc.Parent = Workspace
    
    -- Create humanoid and parts
    local humanoid = Instance.new("Humanoid")
    humanoid.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
    humanoid.Parent = npc
    
    -- Head
    local head = Instance.new("Part")
    head.Name = "Head"
    head.Size = Vector3.new(2, 1, 1)
    head.TopSurface = Enum.SurfaceType.Smooth
    head.BottomSurface = Enum.SurfaceType.Smooth
    head.BrickColor = BrickColor.new("Bright yellow")
    head.Material = Enum.Material.SmoothPlastic
    head.Shape = Enum.PartType.Block
    head.CanCollide = false
    head.Parent = npc
    
    -- Face
    local face = Instance.new("Decal")
    face.Name = "face"
    face.Face = Enum.NormalId.Front
    face.Texture = "rbxasset://textures/face.png"
    face.Parent = head
    
    -- Torso
    local torso = Instance.new("Part")
    torso.Name = "Torso"
    torso.Size = Vector3.new(2, 2, 1)
    torso.TopSurface = Enum.SurfaceType.Smooth
    torso.BottomSurface = Enum.SurfaceType.Smooth
    torso.BrickColor = BrickColor.new(npcData.shirtColor)
    torso.Material = Enum.Material.SmoothPlastic
    torso.CanCollide = false
    torso.Parent = npc
    
    -- Arms
    local leftArm = Instance.new("Part")
    leftArm.Name = "Left Arm"
    leftArm.Size = Vector3.new(1, 2, 1)
    leftArm.TopSurface = Enum.SurfaceType.Smooth
    leftArm.BottomSurface = Enum.SurfaceType.Smooth
    leftArm.BrickColor = BrickColor.new(npcData.skinColor)
    leftArm.Material = Enum.Material.SmoothPlastic
    leftArm.CanCollide = false
    leftArm.Parent = npc
    
    local rightArm = leftArm:Clone()
    rightArm.Name = "Right Arm"
    rightArm.Parent = npc
    
    -- Legs
    local leftLeg = Instance.new("Part")
    leftLeg.Name = "Left Leg"
    leftLeg.Size = Vector3.new(1, 2, 1)
    leftLeg.TopSurface = Enum.SurfaceType.Smooth
    leftLeg.BottomSurface = Enum.SurfaceType.Smooth
    leftLeg.BrickColor = BrickColor.new(npcData.pantsColor)
    leftLeg.Material = Enum.Material.SmoothPlastic
    leftLeg.CanCollide = false
    leftLeg.Parent = npc
    
    local rightLeg = leftLeg:Clone()
    rightLeg.Name = "Right Leg"
    rightLeg.Parent = npc
    
    -- Humanoid Root Part
    local hrp = Instance.new("Part")
    hrp.Name = "HumanoidRootPart"
    hrp.Size = Vector3.new(2, 2, 1)
    hrp.Transparency = 1
    hrp.CanCollide = false
    hrp.Parent = npc
    
    -- Create joints
    local function createJoint(part0, part1, c0, c1)
        local joint = Instance.new("Motor6D")
        joint.Part0 = part0
        joint.Part1 = part1
        joint.C0 = c0
        joint.C1 = c1
        joint.Parent = part0
        return joint
    end
    
    -- Connect parts
    createJoint(hrp, torso, CFrame.new(0, 0, 0), CFrame.new(0, 0, 0))
    createJoint(torso, head, CFrame.new(0, 1, 0), CFrame.new(0, -0.5, 0))
    createJoint(torso, leftArm, CFrame.new(-1.5, 0.5, 0), CFrame.new(0, 0.5, 0))
    createJoint(torso, rightArm, CFrame.new(1.5, 0.5, 0), CFrame.new(0, 0.5, 0))
    createJoint(torso, leftLeg, CFrame.new(-0.5, -1, 0), CFrame.new(0, 1, 0))
    createJoint(torso, rightLeg, CFrame.new(0.5, -1, 0), CFrame.new(0, 1, 0))
    
    -- Set PrimaryPart
    npc.PrimaryPart = hrp
    
    -- Position the NPC
    npc:SetPrimaryPartCFrame(CFrame.new(npcData.position))
    
    -- Add name display
    local nameGui = Instance.new("BillboardGui")
    nameGui.Name = "NameDisplay"
    nameGui.Size = UDim2.new(0, 200, 0, 50)
    nameGui.StudsOffset = Vector3.new(0, 3, 0)
    nameGui.Parent = head
    
    local nameLabel = Instance.new("TextLabel")
    nameLabel.Size = UDim2.new(1, 0, 1, 0)
    nameLabel.BackgroundTransparency = 1
    nameLabel.Text = npcData.name
    nameLabel.TextColor3 = Color3.new(1, 1, 1)
    nameLabel.TextSize = 18
    nameLabel.Font = Enum.Font.GothamBold
    nameLabel.TextStrokeTransparency = 0
    nameLabel.TextStrokeColor3 = Color3.new(0, 0, 0)
    nameLabel.Parent = nameGui
    
    -- Add click detector for dialogue
    local clickDetector = Instance.new("ClickDetector")
    clickDetector.MaxActivationDistance = 20
    clickDetector.Parent = torso
    
    -- Dialogue system
    local lastDialogueTime = 0
    clickDetector.MouseClick:Connect(function(clickingPlayer)
        if clickingPlayer == player and tick() - lastDialogueTime > 3 then
            lastDialogueTime = tick()
            local randomDialogue = npcData.dialogues[math.random(1, #npcData.dialogues)]
            self:ShowDialogue(npc, randomDialogue)
        end
    end)
    
    -- Store NPC data
    npcs[npcData.name] = {
        model = npc,
        data = npcData,
        currentWalkTarget = 1,
        isWalking = false,
        walkConnection = nil,
        footstepSound = nil
    }
    
    -- Add footstep sound to NPC
    local footstepSound = Instance.new("Sound")
    footstepSound.Name = "FootstepSound"
    footstepSound.SoundId = AMBIENT_SOUNDS.footsteps.soundId
    footstepSound.Volume = AMBIENT_SOUNDS.footsteps.volume
    footstepSound.Pitch = AMBIENT_SOUNDS.footsteps.pitch + (math.random(-20, 20) / 100) -- Slight pitch variation
    footstepSound.Parent = hrp
    npcs[npcData.name].footstepSound = footstepSound
    
    -- Start walking behavior
    self:StartNPCWalking(npcData.name)
    
    print("🤖 Created NPC: " .. npcData.name)
    return npc
end

function HubEnhancementController:StartNPCWalking(npcName)
    -- Make NPC walk between waypoints
    local npcInfo = npcs[npcName]
    if not npcInfo then return end
    
    local npc = npcInfo.model
    local npcData = npcInfo.data
    
    if not npc or not npc.PrimaryPart then return end
    
    local function walkToNextPoint()
        if not npc.Parent then return end
        
        local targetPoint = npcData.walkPoints[npcInfo.currentWalkTarget]
        local currentPos = npc.PrimaryPart.Position
        local targetPos = Vector3.new(targetPoint.X, currentPos.Y, targetPoint.Z)
        
        -- Calculate direction and distance
        local direction = (targetPos - currentPos)
        local distance = direction.Magnitude
        direction = direction.Unit
        
        if distance < 2 then
            -- Reached target, move to next point
            npcInfo.currentWalkTarget = (npcInfo.currentWalkTarget % #npcData.walkPoints) + 1
            wait(math.random(2, 5)) -- Pause between walks
            walkToNextPoint()
            return
        end
        
        -- Face the direction
        local lookDirection = CFrame.lookAt(currentPos, targetPos)
        npc:SetPrimaryPartCFrame(CFrame.new(currentPos, targetPos))
        
        -- Walk to target
        local walkTime = distance / npcData.walkSpeed
        local walkTween = TweenService:Create(npc.PrimaryPart, 
            TweenInfo.new(walkTime, Enum.EasingStyle.Linear), 
            {Position = targetPos}
        )
        
        -- Play footstep sounds during walking
        local footstepTimer = 0
        local footstepInterval = 0.5 -- Play footstep every 0.5 seconds
        
        npcInfo.walkConnection = RunService.Heartbeat:Connect(function(deltaTime)
            footstepTimer = footstepTimer + deltaTime
            if footstepTimer >= footstepInterval then
                footstepTimer = 0
                if npcInfo.footstepSound and npc.Parent then
                    npcInfo.footstepSound:Play()
                end
            end
        end)
        
        walkTween:Play()
        walkTween.Completed:Connect(function()
            -- Stop footstep sounds
            if npcInfo.walkConnection then
                npcInfo.walkConnection:Disconnect()
                npcInfo.walkConnection = nil
            end
            
            wait(1)
            walkToNextPoint()
        end)
    end
    
    -- Start walking after a random delay
    spawn(function()
        wait(math.random(1, 3))
        walkToNextPoint()
    end)
end

function HubEnhancementController:ShowDialogue(npc, text)
    -- Show dialogue bubble above NPC
    local head = npc:FindFirstChild("Head")
    if not head then return end
    
    -- Remove existing dialogue
    local existingDialogue = head:FindFirstChild("DialogueGui")
    if existingDialogue then
        existingDialogue:Destroy()
    end
    
    -- Create dialogue bubble
    local dialogueGui = Instance.new("BillboardGui")
    dialogueGui.Name = "DialogueGui"
    dialogueGui.Size = UDim2.new(0, 300, 0, 100)
    dialogueGui.StudsOffset = Vector3.new(0, 4, 0)
    dialogueGui.Parent = head
    
    -- Background bubble
    local bubble = Instance.new("Frame")
    bubble.Size = UDim2.new(1, 0, 1, 0)
    bubble.BackgroundColor3 = Color3.new(1, 1, 1)
    bubble.BorderSizePixel = 0
    bubble.Parent = dialogueGui
    
    local bubbleCorner = Instance.new("UICorner")
    bubbleCorner.CornerRadius = UDim.new(0, 15)
    bubbleCorner.Parent = bubble
    
    -- Add shadow
    local shadow = Instance.new("Frame")
    shadow.Size = UDim2.new(1, 6, 1, 6)
    shadow.Position = UDim2.new(0, 3, 0, 3)
    shadow.BackgroundColor3 = Color3.new(0, 0, 0)
    shadow.BackgroundTransparency = 0.7
    shadow.BorderSizePixel = 0
    shadow.ZIndex = bubble.ZIndex - 1
    shadow.Parent = dialogueGui
    
    local shadowCorner = Instance.new("UICorner")
    shadowCorner.CornerRadius = UDim.new(0, 15)
    shadowCorner.Parent = shadow
    
    -- Dialogue text
    local textLabel = Instance.new("TextLabel")
    textLabel.Size = UDim2.new(1, -20, 1, -20)
    textLabel.Position = UDim2.new(0, 10, 0, 10)
    textLabel.BackgroundTransparency = 1
    textLabel.Text = text
    textLabel.TextColor3 = Color3.new(0, 0, 0)
    textLabel.TextSize = 14
    textLabel.Font = Enum.Font.Gotham
    textLabel.TextWrapped = true
    textLabel.TextXAlignment = Enum.TextXAlignment.Center
    textLabel.TextYAlignment = Enum.TextYAlignment.Center
    textLabel.Parent = bubble
    
    -- Animate appearance
    bubble.Size = UDim2.new(0, 0, 0, 0)
    local appearTween = TweenService:Create(bubble, TweenInfo.new(0.3, Enum.EasingStyle.Back), {
        Size = UDim2.new(1, 0, 1, 0)
    })
    appearTween:Play()
    
    -- Auto-remove after 4 seconds
    spawn(function()
        wait(4)
        if dialogueGui and dialogueGui.Parent then
            local disappearTween = TweenService:Create(bubble, TweenInfo.new(0.2), {
                Size = UDim2.new(0, 0, 0, 0)
            })
            disappearTween:Play()
            disappearTween.Completed:Connect(function()
                dialogueGui:Destroy()
            end)
        end
    end)
end

function HubEnhancementController:CreateTipSign(signData)
    -- Create an animated tip sign
    local sign = Instance.new("Model")
    sign.Name = "TipSign"
    sign.Parent = Workspace
    
    -- Sign post
    local post = Instance.new("Part")
    post.Name = "Post"
    post.Size = Vector3.new(0.5, 4, 0.5)
    post.Position = signData.position
    post.BrickColor = BrickColor.new("Dark stone grey")
    post.Material = Enum.Material.Wood
    post.Anchored = true
    post.Parent = sign
    
    -- Sign board
    local board = Instance.new("Part")
    board.Name = "Board"
    board.Size = Vector3.new(6, 3, 0.2)
    board.Position = signData.position + Vector3.new(0, 2, 0)
    board.BrickColor = BrickColor.new("Bright yellow")
    board.Material = Enum.Material.SmoothPlastic
    board.Anchored = true
    board.Parent = sign
    
    -- Add border
    local border = Instance.new("SelectionBox")
    border.Adornee = board
    border.Color3 = Color3.new(0, 0, 0)
    border.LineThickness = 0.2
    border.Transparency = 0
    border.Parent = board
    
    -- Tip display
    local tipGui = Instance.new("SurfaceGui")
    tipGui.Face = Enum.NormalId.Front
    tipGui.Parent = board
    
    local tipFrame = Instance.new("Frame")
    tipFrame.Size = UDim2.new(1, 0, 1, 0)
    tipFrame.BackgroundTransparency = 1
    tipFrame.Parent = tipGui
    
    local tipLabel = Instance.new("TextLabel")
    tipLabel.Size = UDim2.new(1, -20, 1, -20)
    tipLabel.Position = UDim2.new(0, 10, 0, 10)
    tipLabel.BackgroundTransparency = 1
    tipLabel.Text = signData.tips[1]
    tipLabel.TextColor3 = Color3.new(0, 0, 0)
    tipLabel.TextSize = 24
    tipLabel.Font = Enum.Font.GothamBold
    tipLabel.TextWrapped = true
    tipLabel.TextXAlignment = Enum.TextXAlignment.Center
    tipLabel.TextYAlignment = Enum.TextYAlignment.Center
    tipLabel.Parent = tipFrame
    
    -- Rotate sign
    sign:SetPrimaryPartCFrame(CFrame.new(signData.position) * CFrame.Angles(0, math.rad(signData.rotation.Y), 0))
    
    -- Animate tip cycling
    spawn(function()
        local tipIndex = 1
        while sign.Parent do
            wait(8) -- Change tip every 8 seconds
            tipIndex = (tipIndex % #signData.tips) + 1
            
            -- Fade out
            local fadeOut = TweenService:Create(tipLabel, TweenInfo.new(0.5), {
                TextTransparency = 1
            })
            fadeOut:Play()
            
            fadeOut.Completed:Connect(function()
                -- Change text
                tipLabel.Text = signData.tips[tipIndex]
                
                -- Fade in
                local fadeIn = TweenService:Create(tipLabel, TweenInfo.new(0.5), {
                    TextTransparency = 0
                })
                fadeIn:Play()
            end)
        end
    end)
    
    -- Add gentle swaying animation
    spawn(function()
        while sign.Parent do
            local swayTween = TweenService:Create(board, TweenInfo.new(3, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true), {
                Orientation = Vector3.new(0, signData.rotation.Y + 2, 0)
            })
            swayTween:Play()
            wait(6)
        end
    end)
    
    -- Add glowing effect around the sign
    local glowPart = Instance.new("Part")
    glowPart.Name = "Glow"
    glowPart.Size = Vector3.new(8, 4, 0.1)
    glowPart.Position = signData.position + Vector3.new(0, 2, -0.2)
    glowPart.BrickColor = BrickColor.new("Bright yellow")
    glowPart.Material = Enum.Material.Neon
    glowPart.Transparency = 0.8
    glowPart.Anchored = true
    glowPart.CanCollide = false
    glowPart.Parent = sign
    
    -- Animate glow pulsing
    spawn(function()
        while sign.Parent do
            local pulseTween = TweenService:Create(glowPart, TweenInfo.new(2, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true), {
                Transparency = 0.6
            })
            pulseTween:Play()
            wait(4)
        end
    end)
    
    -- Add sparkle effects
    spawn(function()
        while sign.Parent do
            wait(math.random(2, 5))
            
            -- Create sparkle
            local sparkle = Instance.new("Part")
            sparkle.Name = "Sparkle"
            sparkle.Size = Vector3.new(0.2, 0.2, 0.2)
            sparkle.Shape = Enum.PartType.Ball
            sparkle.Material = Enum.Material.Neon
            sparkle.BrickColor = BrickColor.new("Bright yellow")
            sparkle.CanCollide = false
            sparkle.Anchored = true
            sparkle.Parent = sign
            
            -- Random position around the sign
            local randomX = signData.position.X + math.random(-3, 3)
            local randomY = signData.position.Y + math.random(1, 4)
            local randomZ = signData.position.Z + math.random(-1, 1)
            sparkle.Position = Vector3.new(randomX, randomY, randomZ)
            
            -- Animate sparkle
            local sparkleTween = TweenService:Create(sparkle, TweenInfo.new(1.5), {
                Size = Vector3.new(0.5, 0.5, 0.5),
                Transparency = 1,
                Position = sparkle.Position + Vector3.new(0, 2, 0)
            })
            sparkleTween:Play()
            
            sparkleTween.Completed:Connect(function()
                sparkle:Destroy()
            end)
        end
    end)
    
    table.insert(tipSigns, sign)
    print("📋 Created tip sign at: " .. tostring(signData.position))
    
    return sign
end

function HubEnhancementController:CreatePartyStand()
    -- Create a "Play with Friends" party stand
    local standData = HUB_CONFIG.partyStand
    
    local stand = Instance.new("Model")
    stand.Name = "PartyStand"
    stand.Parent = Workspace
    
    -- Base platform
    local base = Instance.new("Part")
    base.Name = "Base"
    base.Size = standData.size
    base.Position = standData.position
    base.BrickColor = BrickColor.new("Bright red")
    base.Material = Enum.Material.Neon
    base.Anchored = true
    base.Parent = stand
    
    local baseCorner = Instance.new("SpecialMesh")
    baseCorner.MeshType = Enum.MeshType.Cylinder
    baseCorner.Parent = base
    
    -- Decorative pillars
    for i = 1, 4 do
        local pillar = Instance.new("Part")
        pillar.Name = "Pillar" .. i
        pillar.Size = Vector3.new(0.5, 8, 0.5)
        pillar.BrickColor = BrickColor.new("Really red")
        pillar.Material = Enum.Material.SmoothPlastic
        pillar.Anchored = true
        pillar.Parent = stand
        
        local angle = (i - 1) * 90
        local radius = 3
        local x = standData.position.X + math.cos(math.rad(angle)) * radius
        local z = standData.position.Z + math.sin(math.rad(angle)) * radius
        pillar.Position = Vector3.new(x, standData.position.Y + 4, z)
    end
    
    -- Party sign
    local sign = Instance.new("Part")
    sign.Name = "PartySign"
    sign.Size = Vector3.new(6, 4, 0.2)
    sign.Position = standData.position + Vector3.new(0, 6, 0)
    sign.BrickColor = BrickColor.new("Bright yellow")
    sign.Material = Enum.Material.SmoothPlastic
    sign.Anchored = true
    sign.Parent = stand
    
    -- Sign text
    local signGui = Instance.new("SurfaceGui")
    signGui.Face = Enum.NormalId.Front
    signGui.Parent = sign
    
    local signFrame = Instance.new("Frame")
    signFrame.Size = UDim2.new(1, 0, 1, 0)
    signFrame.BackgroundColor3 = Color3.fromRGB(255, 100, 100)
    signFrame.BorderSizePixel = 0
    signFrame.Parent = signGui
    
    local signCorner = Instance.new("UICorner")
    signCorner.CornerRadius = UDim.new(0, 15)
    signCorner.Parent = signFrame
    
    local titleLabel = Instance.new("TextLabel")
    titleLabel.Size = UDim2.new(1, 0, 0.5, 0)
    titleLabel.Position = UDim2.new(0, 0, 0, 0)
    titleLabel.BackgroundTransparency = 1
    titleLabel.Text = "🎉 PLAY WITH FRIENDS! 🎉"
    titleLabel.TextColor3 = Color3.new(1, 1, 1)
    titleLabel.TextSize = 32
    titleLabel.Font = Enum.Font.GothamBold
    titleLabel.TextXAlignment = Enum.TextXAlignment.Center
    titleLabel.TextYAlignment = Enum.TextYAlignment.Center
    titleLabel.Parent = signFrame
    
    local subtitleLabel = Instance.new("TextLabel")
    subtitleLabel.Size = UDim2.new(1, 0, 0.5, 0)
    subtitleLabel.Position = UDim2.new(0, 0, 0.5, 0)
    subtitleLabel.BackgroundTransparency = 1
    subtitleLabel.Text = "Click to start a party!"
    subtitleLabel.TextColor3 = Color3.new(1, 1, 1)
    subtitleLabel.TextSize = 24
    subtitleLabel.Font = Enum.Font.Gotham
    subtitleLabel.TextXAlignment = Enum.TextXAlignment.Center
    subtitleLabel.TextYAlignment = Enum.TextYAlignment.Center
    subtitleLabel.Parent = signFrame
    
    -- Click detector
    local clickDetector = Instance.new("ClickDetector")
    clickDetector.MaxActivationDistance = 20
    clickDetector.Parent = base
    
    clickDetector.MouseClick:Connect(function(clickingPlayer)
        if clickingPlayer == player then
            -- Open party system
            RemoteEvents.OpenPartySystem:FireServer()
            print("🎉 Party system activated!")
        end
    end)
    
    -- Add rotating animation
    spawn(function()
        while stand.Parent do
            local rotateTween = TweenService:Create(base, TweenInfo.new(8, Enum.EasingStyle.Linear, Enum.EasingDirection.InOut, -1), {
                Orientation = Vector3.new(0, 360, 0)
            })
            rotateTween:Play()
            wait(8)
        end
    end)
    
    -- Add confetti effects
    spawn(function()
        while stand.Parent do
            wait(math.random(3, 6))
            
            -- Create confetti
            for i = 1, 5 do
                local confetti = Instance.new("Part")
                confetti.Name = "Confetti"
                confetti.Size = Vector3.new(0.1, 0.1, 0.1)
                confetti.Shape = Enum.PartType.Block
                confetti.Material = Enum.Material.Neon
                confetti.CanCollide = false
                confetti.Anchored = true
                confetti.Parent = stand
                
                -- Random colors
                local colors = {
                    BrickColor.new("Bright red"),
                    BrickColor.new("Bright blue"),
                    BrickColor.new("Bright green"),
                    BrickColor.new("Bright yellow"),
                    BrickColor.new("Hot pink")
                }
                confetti.BrickColor = colors[math.random(1, #colors)]
                
                -- Start above the stand
                local startX = standData.position.X + math.random(-3, 3)
                local startY = standData.position.Y + 8
                local startZ = standData.position.Z + math.random(-2, 2)
                confetti.Position = Vector3.new(startX, startY, startZ)
                
                -- Animate falling
                local fallTween = TweenService:Create(confetti, TweenInfo.new(3, Enum.EasingStyle.Quad), {
                    Position = Vector3.new(startX + math.random(-2, 2), standData.position.Y - 1, startZ + math.random(-2, 2)),
                    Orientation = Vector3.new(math.random(0, 360), math.random(0, 360), math.random(0, 360)),
                    Transparency = 1
                })
                fallTween:Play()
                
                fallTween.Completed:Connect(function()
                    confetti:Destroy()
                end)
            end
        end
    end)
    
    partyStand = stand
    print("🎉 Created party stand at: " .. tostring(standData.position))
    
    return stand
end

function HubEnhancementController:SetupAmbientSounds()
    -- Create ambient background sounds and music
    for soundName, soundData in pairs(AMBIENT_SOUNDS) do
        if soundName ~= "footsteps" then -- Don't create footsteps as global sound
            local sound = Instance.new("Sound")
            sound.Name = soundName
            sound.SoundId = soundData.soundId
            sound.Volume = soundData.volume
            sound.Looped = soundData.looped
            sound.Pitch = soundData.pitch
            sound.Parent = SoundService
            
            -- Play the sound
            sound:Play()
            
            ambientSounds[soundName] = sound
            print("🎵 Started ambient sound: " .. soundName)
        end
    end
    
    -- Add dynamic volume based on distance (for fountain)
    if ambientSounds.fountainWater then
        spawn(function()
            while ambientSounds.fountainWater.Parent do
                local character = player.Character
                if character and character:FindFirstChild("HumanoidRootPart") then
                    local playerPos = character.HumanoidRootPart.Position
                    local fountainPos = Vector3.new(0, 4, 0) -- Assume fountain is at origin
                    local distance = (playerPos - fountainPos).Magnitude
                    
                    -- Adjust volume based on distance (closer = louder)
                    local maxDistance = 30
                    local volume = math.max(0, 0.12 * (1 - math.min(distance / maxDistance, 1)))
                    ambientSounds.fountainWater.Volume = volume
                end
                wait(0.5)
            end
        end)
    end
    
    -- Add dynamic volume for market chatter based on NPC proximity
    if ambientSounds.marketChatter then
        spawn(function()
            while ambientSounds.marketChatter.Parent do
                local character = player.Character
                if character and character:FindFirstChild("HumanoidRootPart") then
                    local playerPos = character.HumanoidRootPart.Position
                    local nearestNPCDistance = math.huge
                    
                    -- Find nearest NPC
                    for _, npcInfo in pairs(npcs) do
                        if npcInfo.model and npcInfo.model.PrimaryPart then
                            local npcPos = npcInfo.model.PrimaryPart.Position
                            local distance = (playerPos - npcPos).Magnitude
                            nearestNPCDistance = math.min(nearestNPCDistance, distance)
                        end
                    end
                    
                    -- Adjust volume based on nearest NPC distance
                    local maxDistance = 25
                    local volume = math.max(0, 0.08 * (1 - math.min(nearestNPCDistance / maxDistance, 1)))
                    ambientSounds.marketChatter.Volume = volume
                end
                wait(1)
            end
        end)
    end
end

function HubEnhancementController:EnhanceHub()
    -- Main function to enhance the entire hub area
    if hubEnhanced then
        print("🏠 Hub already enhanced!")
        return
    end
    
    print("🏠 Enhancing hub area...")
    
    -- Create NPCs
    for _, npcData in pairs(HUB_CONFIG.npcs) do
        self:CreateNPC(npcData)
    end
    
    -- Create tip signs
    for _, signData in pairs(HUB_CONFIG.tipSigns) do
        self:CreateTipSign(signData)
    end
    
    -- Create party stand
    self:CreatePartyStand()
    
    -- Setup ambient sounds
    self:SetupAmbientSounds()
    
    hubEnhanced = true
    print("✅ Hub enhancement complete!")
end

function HubEnhancementController:StopAmbientSounds()
    -- Stop all ambient sounds (useful when leaving hub)
    for soundName, sound in pairs(ambientSounds) do
        if sound and sound.Parent then
            sound:Stop()
        end
    end
    print("🔇 Stopped ambient sounds")
end

function HubEnhancementController:Initialize()
    -- Initialize the hub enhancement controller
    print("🏠 HubEnhancementController initializing...")
    
    -- Wait a moment for the hub to load
    wait(2)
    
    -- Enhance the hub
    self:EnhanceHub()
    
    -- Listen for hub events
    RemoteEvents.ReturnToHub.OnClientEvent:Connect(function()
        -- Re-enable ambient sounds when returning to hub
        if hubEnhanced then
            self:SetupAmbientSounds()
        end
    end)
    
    RemoteEvents.GameStarted.OnClientEvent:Connect(function()
        -- Stop ambient sounds during game
        self:StopAmbientSounds()
    end)
    
    print("✅ HubEnhancementController initialized!")
end

-- Auto-initialize
spawn(function()
    HubEnhancementController:Initialize()
end)

return HubEnhancementController
