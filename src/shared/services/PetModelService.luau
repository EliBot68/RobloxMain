-- PetModelService.luau
-- Presentation layer for pet visual representation and 3D model management
-- Handles pet model creation, rendering, and visual effects

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local TweenService = game:GetService("TweenService")
local Players = game:GetService("Players")

local ServiceArchitecture = require(ReplicatedStorage.Shared.core.ServiceArchitecture)
local PetDatabase = require(ReplicatedStorage.Shared.data.PetDatabase)

local PetModelService = {}
PetModelService.__index = PetModelService

-- Extend the controller interface
setmetatable(PetModelService, {__index = ServiceArchitecture.IController})

function PetModelService.new()
    local self = setmetatable({}, PetModelService)
    
    self.activeModels = {} -- [playerId] = petModel
    self.modelCache = {} -- [petId] = templateModel
    self.effectsCache = {} -- Visual effects cache
    
    return self
end

-- ========================================
-- CONTROLLER INTERFACE IMPLEMENTATION
-- ========================================

function PetModelService:HandleRequest(request, context)
    local requestType = request.type
    
    if requestType == "create_model" then
        return self:CreatePetModel(request.petData, request.player)
    elseif requestType == "destroy_model" then
        return self:DestroyPetModel(request.player)
    elseif requestType == "update_visual" then
        return self:UpdatePetVisual(request.player, request.visualData)
    else
        return nil, "Unknown request type: " .. requestType
    end
end

function PetModelService:ValidateRequest(request)
    if not request.type then
        return false, "Missing request type"
    end
    
    if request.type == "create_model" then
        if not request.petData or not request.player then
            return false, "Missing petData or player"
        end
    elseif request.type == "destroy_model" then
        if not request.player then
            return false, "Missing player"
        end
    end
    
    return true, "Valid request"
end

function PetModelService:FormatResponse(data)
    if type(data) == "userdata" and data:IsA("Model") then
        return {
            success = true,
            modelName = data.Name,
            primaryPart = data.PrimaryPart and data.PrimaryPart.Name or nil,
            childCount = #data:GetChildren()
        }
    else
        return {
            success = false,
            data = data
        }
    end
end

-- ========================================
-- PET MODEL CREATION
-- ========================================

function PetModelService:CreatePetModel(petData, player)
    -- Clean up existing model
    self:DestroyPetModel(player)
    
    -- Get or create template model
    local templateModel = self:_getOrCreateTemplate(petData)
    if not templateModel then
        return nil, "Failed to create template model"
    end
    
    -- Clone and customize model
    local petModel = templateModel:Clone()
    petModel.Name = petData.name .. "_" .. player.Name
    
    -- Setup model properties
    self:_setupModelProperties(petModel, petData)
    
    -- Position model near player
    self:_positionModel(petModel, player)
    
    -- Setup physics
    self:_setupModelPhysics(petModel, petData)
    
    -- Apply visual effects
    self:_applyVisualEffects(petModel, petData)
    
    -- Add to workspace and track
    petModel.Parent = Workspace
    self.activeModels[player.UserId] = petModel
    
    print("🎨 Created pet model for " .. player.Name .. ": " .. petData.name)
    return petModel, "Pet model created successfully"
end

function PetModelService:DestroyPetModel(player)
    local existingModel = self.activeModels[player.UserId]
    if existingModel then
        existingModel:Destroy()
        self.activeModels[player.UserId] = nil
        print("🗑️ Destroyed pet model for " .. player.Name)
        return true, "Pet model destroyed"
    end
    return false, "No active pet model"
end

-- ========================================
-- MODEL TEMPLATE MANAGEMENT
-- ========================================

function PetModelService:_getOrCreateTemplate(petData)
    -- Check cache first
    if self.modelCache[petData.id] then
        return self.modelCache[petData.id]
    end
    
    -- Create new template
    local template = self:_createTemplateModel(petData)
    if template then
        self.modelCache[petData.id] = template
    end
    
    return template
end

function PetModelService:_createTemplateModel(petData)
    -- Create basic model structure
    local model = Instance.new("Model")
    model.Name = petData.model or petData.id
    
    -- Create main body part
    local bodyPart = Instance.new("Part")
    bodyPart.Name = "Body"
    bodyPart.Size = petData.size or Vector3.new(2, 2, 2)
    bodyPart.Material = Enum.Material.SmoothPlastic
    bodyPart.Shape = Enum.PartType.Block
    bodyPart.TopSurface = Enum.SurfaceType.Smooth
    bodyPart.BottomSurface = Enum.SurfaceType.Smooth
    bodyPart.Parent = model
    
    -- Set as primary part
    model.PrimaryPart = bodyPart
    
    -- Add basic coloring
    bodyPart.Color = petData.color or Color3.new(0.8, 0.8, 0.8)
    
    -- Add mesh or special part based on pet type
    self:_addPetSpecificFeatures(model, bodyPart, petData)
    
    -- Add name tag
    self:_addNameTag(model, petData)
    
    return model
end

function PetModelService:_addPetSpecificFeatures(model, bodyPart, petData)
    local petId = petData.id
    
    if petId:find("bunny") then
        self:_addBunnyFeatures(model, bodyPart, petData)
    elseif petId:find("cat") then
        self:_addCatFeatures(model, bodyPart, petData)
    elseif petId:find("turtle") then
        self:_addTurtleFeatures(model, bodyPart, petData)
    elseif petId:find("fox") then
        self:_addFoxFeatures(model, bodyPart, petData)
    elseif petId:find("owl") then
        self:_addOwlFeatures(model, bodyPart, petData)
    elseif petId:find("wolf") then
        self:_addWolfFeatures(model, bodyPart, petData)
    elseif petId:find("unicorn") then
        self:_addUnicornFeatures(model, bodyPart, petData)
    elseif petId:find("dragon") then
        self:_addDragonFeatures(model, bodyPart, petData)
    elseif petId:find("phoenix") then
        self:_addPhoenixFeatures(model, bodyPart, petData)
    else
        self:_addGenericFeatures(model, bodyPart, petData)
    end
end

function PetModelService:_addBunnyFeatures(model, bodyPart, petData)
    -- Ears
    for i = 1, 2 do
        local ear = Instance.new("Part")
        ear.Name = "Ear" .. i
        ear.Size = Vector3.new(0.3, 1.5, 0.2)
        ear.Material = Enum.Material.SmoothPlastic
        ear.Color = petData.color
        ear.Parent = model
        
        local weld = Instance.new("WeldConstraint")
        weld.Part0 = bodyPart
        weld.Part1 = ear
        weld.Parent = bodyPart
        
        ear.CFrame = bodyPart.CFrame * CFrame.new((i == 1) and -0.4 or 0.4, 0.8, 0.2)
    end
    
    -- Tail
    local tail = Instance.new("Part")
    tail.Name = "Tail"
    tail.Size = Vector3.new(0.5, 0.5, 0.5)
    tail.Shape = Enum.PartType.Ball
    tail.Material = Enum.Material.SmoothPlastic
    tail.Color = Color3.new(1, 1, 1) -- White tail
    tail.Parent = model
    
    local tailWeld = Instance.new("WeldConstraint")
    tailWeld.Part0 = bodyPart
    tailWeld.Part1 = tail
    tailWeld.Parent = bodyPart
    
    tail.CFrame = bodyPart.CFrame * CFrame.new(0, 0, -1.2)
end

function PetModelService:_addCatFeatures(model, bodyPart, petData)
    -- Cat ears (triangular)
    for i = 1, 2 do
        local ear = Instance.new("WedgePart")
        ear.Name = "Ear" .. i
        ear.Size = Vector3.new(0.4, 0.8, 0.4)
        ear.Material = Enum.Material.SmoothPlastic
        ear.Color = petData.color
        ear.Parent = model
        
        local weld = Instance.new("WeldConstraint")
        weld.Part0 = bodyPart
        weld.Part1 = ear
        weld.Parent = bodyPart
        
        ear.CFrame = bodyPart.CFrame * CFrame.new((i == 1) and -0.3 or 0.3, 0.6, 0.2)
    end
    
    -- Whiskers effect
    self:_addWhiskersEffect(model, bodyPart)
end

function PetModelService:_addDragonFeatures(model, bodyPart, petData)
    -- Wings
    for i = 1, 2 do
        local wing = Instance.new("Part")
        wing.Name = "Wing" .. i
        wing.Size = Vector3.new(0.1, 2, 3)
        wing.Material = Enum.Material.ForceField
        wing.Color = petData.color
        wing.Transparency = 0.3
        wing.Parent = model
        
        local weld = Instance.new("WeldConstraint")
        weld.Part0 = bodyPart
        weld.Part1 = wing
        weld.Parent = bodyPart
        
        wing.CFrame = bodyPart.CFrame * CFrame.new((i == 1) and -1.5 or 1.5, 0.5, -0.5) * 
                     CFrame.Angles(0, (i == 1) and math.rad(-30) or math.rad(30), 0)
    end
    
    -- Crown/horns
    local crown = Instance.new("Part")
    crown.Name = "Crown"
    crown.Size = Vector3.new(1.5, 0.3, 1.5)
    crown.Material = Enum.Material.Neon
    crown.Color = Color3.new(1, 1, 0) -- Golden
    crown.Shape = Enum.PartType.Cylinder
    crown.Parent = model
    
    local crownWeld = Instance.new("WeldConstraint")
    crownWeld.Part0 = bodyPart
    crownWeld.Part1 = crown
    crownWeld.Parent = bodyPart
    
    crown.CFrame = bodyPart.CFrame * CFrame.new(0, 1.2, 0)
end

function PetModelService:_addGenericFeatures(model, bodyPart, petData)
    -- Simple eyes
    for i = 1, 2 do
        local eye = Instance.new("Part")
        eye.Name = "Eye" .. i
        eye.Size = Vector3.new(0.2, 0.2, 0.1)
        eye.Shape = Enum.PartType.Ball
        eye.Material = Enum.Material.Neon
        eye.Color = Color3.new(1, 1, 1)
        eye.Parent = model
        
        local weld = Instance.new("WeldConstraint")
        weld.Part0 = bodyPart
        weld.Part1 = eye
        weld.Parent = bodyPart
        
        eye.CFrame = bodyPart.CFrame * CFrame.new((i == 1) and -0.3 or 0.3, 0.2, 0.9)
    end
end

-- ========================================
-- MODEL SETUP AND PHYSICS
-- ========================================

function PetModelService:_setupModelProperties(model, petData)
    -- Set up all parts
    for _, part in ipairs(model:GetDescendants()) do
        if part:IsA("BasePart") then
            part.CanCollide = false
            part.Anchored = false
            
            -- Add collision group for pets
            part.CollisionGroup = "Pets"
        end
    end
end

function PetModelService:_positionModel(model, player)
    if not player.Character or not player.Character:FindFirstChild("HumanoidRootPart") then
        return
    end
    
    local playerPosition = player.Character.HumanoidRootPart.Position
    local spawnPosition = playerPosition + Vector3.new(
        math.random(-3, 3),
        2,
        math.random(-3, 3)
    )
    
    model:SetPrimaryPartCFrame(CFrame.new(spawnPosition))
end

function PetModelService:_setupModelPhysics(model, petData)
    local bodyPart = model.PrimaryPart
    if not bodyPart then return end
    
    -- BodyPosition for smooth following
    local bodyPosition = Instance.new("BodyPosition")
    bodyPosition.MaxForce = Vector3.new(4000, 4000, 4000)
    bodyPosition.Position = bodyPart.Position
    bodyPosition.D = 2000 -- Damping
    bodyPosition.P = 10000 -- Power
    bodyPosition.Parent = bodyPart
    
    -- BodyVelocity for movement control
    local bodyVelocity = Instance.new("BodyVelocity")
    bodyVelocity.MaxForce = Vector3.new(4000, 0, 4000)
    bodyVelocity.Velocity = Vector3.new(0, 0, 0)
    bodyVelocity.Parent = bodyPart
    
    -- BodyAngularVelocity for rotation control
    local bodyAngularVelocity = Instance.new("BodyAngularVelocity")
    bodyAngularVelocity.MaxTorque = Vector3.new(0, 5000, 0)
    bodyAngularVelocity.AngularVelocity = Vector3.new(0, 0, 0)
    bodyAngularVelocity.Parent = bodyPart
end

-- ========================================
-- VISUAL EFFECTS
-- ========================================

function PetModelService:_applyVisualEffects(model, petData)
    -- Apply glow effect
    if petData.glowIntensity and petData.glowIntensity > 0 then
        self:_addGlowEffect(model, petData)
    end
    
    -- Apply rarity-specific effects
    local rarityConfig = PetDatabase:GetRarityConfig(petData.rarity)
    if rarityConfig then
        self:_addRarityEffect(model, rarityConfig)
    end
    
    -- Apply pet-specific particle effects
    self:_addParticleEffects(model, petData)
end

function PetModelService:_addGlowEffect(model, petData)
    for _, part in ipairs(model:GetDescendants()) do
        if part:IsA("BasePart") then
            local pointLight = Instance.new("PointLight")
            pointLight.Brightness = petData.glowIntensity * 0.5
            pointLight.Color = petData.color
            pointLight.Range = 5
            pointLight.Parent = part
        end
    end
end

function PetModelService:_addRarityEffect(model, rarityConfig)
    local bodyPart = model.PrimaryPart
    if not bodyPart then return end
    
    -- Create rarity aura
    local aura = Instance.new("SelectionBox")
    aura.Name = "RarityAura"
    aura.Adornee = bodyPart
    aura.Color3 = rarityConfig.glowColor
    aura.LineThickness = 0.2
    aura.Transparency = 0.7
    aura.Parent = model
    
    -- Animate aura
    local auraTween = TweenService:Create(
        aura,
        TweenInfo.new(2, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true),
        {Transparency = 0.3}
    )
    auraTween:Play()
end

function PetModelService:_addParticleEffects(model, petData)
    local bodyPart = model.PrimaryPart
    if not bodyPart then return end
    
    -- Create attachment for particles
    local attachment = Instance.new("Attachment")
    attachment.Name = "ParticleAttachment"
    attachment.Parent = bodyPart
    
    -- Add particles based on pet type
    if petData.id:find("fire") then
        self:_addFireParticles(attachment)
    elseif petData.id:find("crystal") then
        self:_addCrystalParticles(attachment)
    elseif petData.id:find("cosmic") then
        self:_addCosmicParticles(attachment)
    end
end

function PetModelService:_addFireParticles(attachment)
    local particles = Instance.new("ParticleEmitter")
    particles.Name = "FireParticles"
    particles.Texture = "rbxasset://textures/particles/fire_main.dds"
    particles.Lifetime = NumberRange.new(0.5, 1.5)
    particles.Rate = 50
    particles.SpreadAngle = Vector2.new(45, 45)
    particles.Speed = NumberRange.new(2, 5)
    particles.Parent = attachment
end

function PetModelService:_addCrystalParticles(attachment)
    local particles = Instance.new("ParticleEmitter")
    particles.Name = "CrystalParticles"
    particles.Texture = "rbxasset://textures/particles/sparkles_main.dds"
    particles.Lifetime = NumberRange.new(1.0, 2.0)
    particles.Rate = 20
    particles.SpreadAngle = Vector2.new(360, 360)
    particles.Speed = NumberRange.new(1, 3)
    particles.Color = ColorSequence.new(Color3.new(0.8, 0.9, 1))
    particles.Parent = attachment
end

function PetModelService:_addCosmicParticles(attachment)
    local particles = Instance.new("ParticleEmitter")
    particles.Name = "CosmicParticles"
    particles.Texture = "rbxasset://textures/particles/stars.png"
    particles.Lifetime = NumberRange.new(2.0, 4.0)
    particles.Rate = 30
    particles.SpreadAngle = Vector2.new(180, 180)
    particles.Speed = NumberRange.new(0.5, 2)
    particles.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Color3.new(1, 1, 1)),
        ColorSequenceKeypoint.new(0.5, Color3.new(0.5, 0.8, 1)),
        ColorSequenceKeypoint.new(1, Color3.new(0.2, 0.2, 0.8))
    })
    particles.Parent = attachment
end

-- ========================================
-- VISUAL UPDATES
-- ========================================

function PetModelService:UpdatePetVisual(player, visualData)
    local model = self.activeModels[player.UserId]
    if not model then
        return false, "No active pet model"
    end
    
    if visualData.color then
        self:_updateModelColor(model, visualData.color)
    end
    
    if visualData.scale then
        self:_updateModelScale(model, visualData.scale)
    end
    
    if visualData.transparency then
        self:_updateModelTransparency(model, visualData.transparency)
    end
    
    return true, "Visual updated"
end

function PetModelService:_updateModelColor(model, color)
    for _, part in ipairs(model:GetDescendants()) do
        if part:IsA("BasePart") and part.Name:find("Body") then
            part.Color = color
        end
    end
end

function PetModelService:_updateModelScale(model, scale)
    for _, part in ipairs(model:GetDescendants()) do
        if part:IsA("BasePart") then
            part.Size = part.Size * scale
        end
    end
end

function PetModelService:_updateModelTransparency(model, transparency)
    for _, part in ipairs(model:GetDescendants()) do
        if part:IsA("BasePart") then
            part.Transparency = transparency
        end
    end
end

-- ========================================
-- CLEANUP AND MANAGEMENT
-- ========================================

function PetModelService:GetActiveModels()
    return self.activeModels
end

function PetModelService:GetModelForPlayer(player)
    return self.activeModels[player.UserId]
end

function PetModelService:CleanupInactiveModels()
    local activePlayers = {}
    for _, player in ipairs(Players:GetPlayers()) do
        activePlayers[player.UserId] = true
    end
    
    local cleaned = 0
    for playerId, model in pairs(self.activeModels) do
        if not activePlayers[playerId] then
            model:Destroy()
            self.activeModels[playerId] = nil
            cleaned = cleaned + 1
        end
    end
    
    if cleaned > 0 then
        print("🧹 Cleaned up " .. cleaned .. " inactive pet models")
    end
    
    return cleaned
end

function PetModelService:ClearAllModels()
    for playerId, model in pairs(self.activeModels) do
        model:Destroy()
    end
    self.activeModels = {}
    print("🧹 Cleared all pet models")
end

-- Helper methods
function PetModelService:_addNameTag(model, petData)
    local nameTag = Instance.new("BillboardGui")
    nameTag.Name = "NameTag"
    nameTag.Size = UDim2.new(4, 0, 1, 0)
    nameTag.StudsOffset = Vector3.new(0, 3, 0)
    nameTag.Parent = model.PrimaryPart
    
    local nameLabel = Instance.new("TextLabel")
    nameLabel.Size = UDim2.new(1, 0, 1, 0)
    nameLabel.BackgroundTransparency = 1
    nameLabel.Text = petData.name
    nameLabel.TextColor3 = Color3.new(1, 1, 1)
    nameLabel.TextStrokeTransparency = 0
    nameLabel.TextStrokeColor3 = Color3.new(0, 0, 0)
    nameLabel.Font = Enum.Font.SourceSansBold
    nameLabel.TextScaled = true
    nameLabel.Parent = nameTag
end

function PetModelService:_addWhiskersEffect(model, bodyPart)
    -- Simple whiskers using beams or parts
    for i = 1, 4 do
        local whisker = Instance.new("Part")
        whisker.Name = "Whisker" .. i
        whisker.Size = Vector3.new(0.8, 0.02, 0.02)
        whisker.Material = Enum.Material.Neon
        whisker.Color = Color3.new(1, 1, 1)
        whisker.Anchored = false
        whisker.CanCollide = false
        whisker.Parent = model
        
        local weld = Instance.new("WeldConstraint")
        weld.Part0 = bodyPart
        weld.Part1 = whisker
        weld.Parent = bodyPart
        
        local side = (i <= 2) and -1 or 1
        local height = (i % 2 == 1) and 0.1 or -0.1
        whisker.CFrame = bodyPart.CFrame * CFrame.new(side * 0.8, height, 0.8) * 
                         CFrame.Angles(0, side * math.rad(15), 0)
    end
end

return PetModelService
