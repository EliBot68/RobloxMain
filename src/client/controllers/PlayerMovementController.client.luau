-- PlayerMovementController.client.luau
-- Handles all player input and movement for Color Rush
-- Supports keyboard, mobile, and gamepad inputs

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local ContextActionService = game:GetService("ContextActionService")
local TweenService = game:GetService("TweenService")
local SoundService = game:GetService("SoundService")
local Workspace = game:GetService("Workspace")

local PlayerMovementController = {}

-- Player and Character references
local player = Players.LocalPlayer
local character = nil
local humanoid = nil
local humanoidRootPart = nil

-- Movement Configuration
local MOVEMENT_CONFIG = {
    walkSpeed = 16,
    runSpeed = 24,
    jumpPower = 50,
    jumpHeight = 12,
    airTime = 0.4,
    coyoteTime = 0.15, -- Grace period for jumping after leaving ground
    jumpBufferTime = 0.1, -- Grace period for jump input before landing
    colorSwitchCooldown = 0.2,
    dashDistance = 30,
    dashCooldown = 2,
    wallJumpForce = 35,
    maxAirJumps = 1
}

-- Input State
local inputState = {
    movement = Vector3.new(0, 0, 0),
    isJumping = false,
    isRunning = false,
    isDashing = false,
    currentColor = "Red",
    lastGroundTime = 0,
    lastJumpInputTime = 0,
    airJumpsUsed = 0,
    canMove = true,
    isOnGround = false,
    wallJumpAvailable = false,
    lastWallNormal = Vector3.new(0, 0, 0)
}

-- Color System - MUTED COLORS FOR BETTER VISIBILITY
local COLORS = {
    ["Red"] = {
        color = Color3.fromRGB(180, 60, 60),   -- Darker red
        key = Enum.KeyCode.One,
        material = Enum.Material.Neon,
        sound = "ColorSwitchRed"
    },
    ["Blue"] = {
        color = Color3.fromRGB(60, 120, 200),  -- Softer blue
        key = Enum.KeyCode.Two,
        material = Enum.Material.Glass,
        sound = "ColorSwitchBlue"
    },
    ["Green"] = {
        color = Color3.fromRGB(80, 180, 80),   -- Muted green
        key = Enum.KeyCode.Three,
        material = Enum.Material.ForceField,
        sound = "ColorSwitchGreen"
    },
    ["Yellow"] = {
        color = Color3.fromRGB(200, 180, 60),  -- Darker yellow/gold
        key = Enum.KeyCode.Four,
        material = Enum.Material.Electric,
        sound = "ColorSwitchYellow"
    }
}

-- Mobile Controls
local mobileControls = {
    jumpButton = nil,
    dashButton = nil,
    colorButtons = {},
    movement = Vector2.new(0, 0)
}

-- Events (will be loaded from ReplicatedStorage)
local Events = {}

-- Effects and Feedback
local lastColorSwitchTime = 0
local lastDashTime = 0
local cameraShakeConnection = nil

-- Performance tracking
local inputUpdateTime = 0
local networkUpdateRate = 0.05 -- 20 updates per second to server

function PlayerMovementController:Init()
    print("🎮 Initializing Player Movement Controller...")
    
    -- Wait for events to be available
    self:WaitForEvents()
    
    -- Setup character connections
    self:SetupCharacterConnections()
    
    -- Setup input handling
    self:SetupInputHandling()
    
    -- Setup mobile controls
    self:SetupMobileControls()
    
    -- Setup camera effects
    self:SetupCameraEffects()
    
    -- Start update loops
    self:StartUpdateLoops()
    
    print("✅ Player Movement Controller initialized!")
end

function PlayerMovementController:WaitForEvents()
    print("🔗 Waiting for RemoteEvents...")
    
    local eventsFolder = ReplicatedStorage:WaitForChild("Events", 10)
    if not eventsFolder then
        warn("❌ Events folder not found!")
        return
    end
    
    -- Core movement events
    Events.PlayerMovement = eventsFolder:WaitForChild("PlayerMovement", 5)
    Events.ColorChanged = eventsFolder:WaitForChild("ColorChanged", 5)
    Events.RequestJoinGame = eventsFolder:WaitForChild("RequestJoinGame", 5)
    Events.RequestRespawn = eventsFolder:WaitForChild("RequestRespawn", 5)
    
    -- Game state events (for receiving)
    Events.GameStateChanged = eventsFolder:WaitForChild("GameStateChanged", 5)
    Events.PlayerSpawned = eventsFolder:WaitForChild("PlayerSpawned", 5)
    Events.PlayerDied = eventsFolder:WaitForChild("PlayerDied", 5)
    Events.ObstacleHit = eventsFolder:WaitForChild("ObstacleHit", 5)
    Events.PowerupActivated = eventsFolder:WaitForChild("PowerupActivated", 5)
    Events.GameWarning = eventsFolder:WaitForChild("GameWarning", 5)
    
    -- Setup event listeners
    self:SetupEventListeners()
    
    print("✅ RemoteEvents connected!")
end

function PlayerMovementController:SetupEventListeners()
    -- Listen for game state changes
    if Events.GameStateChanged then
        Events.GameStateChanged.OnClientEvent:Connect(function(newState, oldState)
            self:OnGameStateChanged(newState, oldState)
        end)
    end
    
    -- Listen for player events
    if Events.PlayerSpawned then
        Events.PlayerSpawned.OnClientEvent:Connect(function(spawnedPlayer)
            if spawnedPlayer == player then
                self:OnPlayerSpawned()
            end
        end)
    end
    
    if Events.PlayerDied then
        Events.PlayerDied.OnClientEvent:Connect(function(diedPlayer, deathData)
            if diedPlayer == player then
                self:OnPlayerDied(deathData)
            end
        end)
    end
    
    if Events.ObstacleHit then
        Events.ObstacleHit.OnClientEvent:Connect(function(hitPlayer, reason)
            if hitPlayer == player then
                self:OnObstacleHit(reason)
            end
        end)
    end
    
    if Events.PowerupActivated then
        Events.PowerupActivated.OnClientEvent:Connect(function(targetPlayer, powerup)
            if targetPlayer == player then
                self:OnPowerupActivated(powerup)
            end
        end)
    end
    
    if Events.GameWarning then
        Events.GameWarning.OnClientEvent:Connect(function(timeLeft, warningType)
            self:OnGameWarning(timeLeft, warningType)
        end)
    end
end

function PlayerMovementController:SetupCharacterConnections()
    print("👤 Setting up character connections...")
    
    -- Handle character spawning
    local function onCharacterAdded(newCharacter)
        character = newCharacter
        humanoid = character:WaitForChild("Humanoid", 5)
        humanoidRootPart = character:WaitForChild("HumanoidRootPart", 5)
        
        if humanoid and humanoidRootPart then
            self:OnCharacterAdded()
        end
    end
    
    -- Connect to character events
    if player.Character then
        onCharacterAdded(player.Character)
    end
    
    player.CharacterAdded:Connect(onCharacterAdded)
    player.CharacterRemoving:Connect(function()
        self:OnCharacterRemoving()
    end)
end

function PlayerMovementController:OnCharacterAdded()
    print("👨‍🎮 Character added, setting up movement...")
    
    -- Reset input state
    inputState.isOnGround = false
    inputState.airJumpsUsed = 0
    inputState.canMove = true
    inputState.lastGroundTime = tick()
    
    -- Configure humanoid
    if humanoid then
        humanoid.WalkSpeed = MOVEMENT_CONFIG.walkSpeed
        humanoid.JumpHeight = MOVEMENT_CONFIG.jumpHeight
        humanoid.AutoRotate = true
        humanoid.PlatformStand = false
        
        -- Ground detection
        humanoid.StateChanged:Connect(function(oldState, newState)
            self:OnHumanoidStateChanged(oldState, newState)
        end)
        
        -- Jumping events
        humanoid.Jumping:Connect(function()
            self:OnJumping()
        end)
        
        humanoid.FreeFalling:Connect(function()
            self:OnFreeFalling()
        end)
        
        humanoid.Landed:Connect(function()
            self:OnLanded()
        end)
    end
    
    -- Setup character appearance
    self:UpdateCharacterAppearance()
    
    -- Setup collision detection
    self:SetupCollisionDetection()
end

function PlayerMovementController:OnCharacterRemoving()
    print("👋 Character removing, cleaning up...")
    
    character = nil
    humanoid = nil
    humanoidRootPart = nil
    inputState.canMove = false
    
    -- Cleanup mobile controls
    self:CleanupMobileControls()
end

function PlayerMovementController:SetupInputHandling()
    print("⌨️ Setting up input handling...")
    
    -- Keyboard input
    UserInputService.InputBegan:Connect(function(input, gameProcessed)
        if gameProcessed then return end
        self:OnInputBegan(input)
    end)
    
    UserInputService.InputEnded:Connect(function(input, gameProcessed)
        if gameProcessed then return end
        self:OnInputEnded(input)
    end)
    
    -- Continuous input (for movement)
    RunService.Heartbeat:Connect(function()
        self:UpdateMovementInput()
    end)
    
    -- Context actions for mobile
    self:SetupContextActions()
end

function PlayerMovementController:SetupContextActions()
    -- Jump action
    ContextActionService:BindAction("Jump", function(actionName, inputState, inputObject)
        if inputState == Enum.UserInputState.Begin then
            self:HandleJumpInput()
        end
    end, true, Enum.KeyCode.Space, Enum.KeyCode.ButtonA)
    
    -- Dash action
    ContextActionService:BindAction("Dash", function(actionName, inputState, inputObject)
        if inputState == Enum.UserInputState.Begin then
            self:HandleDashInput()
        end
    end, true, Enum.KeyCode.LeftShift, Enum.KeyCode.ButtonB)
    
    -- Run action
    ContextActionService:BindAction("Run", function(actionName, inputState, inputObject)
        if inputState == Enum.UserInputState.Begin then
            self:HandleRunInput(true)
        elseif inputState == Enum.UserInputState.End then
            self:HandleRunInput(false)
        end
    end, true, Enum.KeyCode.LeftControl, Enum.KeyCode.ButtonX)
    
    -- Color switching
    for colorName, colorData in pairs(COLORS) do
        ContextActionService:BindAction("SwitchTo" .. colorName, function(actionName, inputState, inputObject)
            if inputState == Enum.UserInputState.Begin then
                self:HandleColorSwitch(colorName)
            end
        end, false, colorData.key)
    end
end

function PlayerMovementController:OnInputBegan(input)
    local keyCode = input.KeyCode
    local inputType = input.UserInputType
    
    -- Handle specific key inputs
    if keyCode == Enum.KeyCode.Space then
        self:HandleJumpInput()
    elseif keyCode == Enum.KeyCode.LeftShift then
        self:HandleDashInput()
    elseif keyCode == Enum.KeyCode.LeftControl then
        self:HandleRunInput(true)
    elseif keyCode == Enum.KeyCode.R then
        self:HandleRespawnRequest()
    elseif keyCode == Enum.KeyCode.J then
        self:HandleJoinGameRequest()
    end
    
    -- Handle color switching
    for colorName, colorData in pairs(COLORS) do
        if keyCode == colorData.key then
            self:HandleColorSwitch(colorName)
            break
        end
    end
end

function PlayerMovementController:OnInputEnded(input)
    local keyCode = input.KeyCode
    
    if keyCode == Enum.KeyCode.LeftControl then
        self:HandleRunInput(false)
    end
end

function PlayerMovementController:UpdateMovementInput()
    if not inputState.canMove or not humanoid or not humanoidRootPart then
        return
    end
    
    -- Get movement input
    local moveVector = Vector3.new(0, 0, 0)
    
    -- Keyboard movement
    if UserInputService:IsKeyDown(Enum.KeyCode.W) or UserInputService:IsKeyDown(Enum.KeyCode.Up) then
        moveVector = moveVector + Vector3.new(0, 0, -1)
    end
    if UserInputService:IsKeyDown(Enum.KeyCode.S) or UserInputService:IsKeyDown(Enum.KeyCode.Down) then
        moveVector = moveVector + Vector3.new(0, 0, 1)
    end
    if UserInputService:IsKeyDown(Enum.KeyCode.A) or UserInputService:IsKeyDown(Enum.KeyCode.Left) then
        moveVector = moveVector + Vector3.new(-1, 0, 0)
    end
    if UserInputService:IsKeyDown(Enum.KeyCode.D) or UserInputService:IsKeyDown(Enum.KeyCode.Right) then
        moveVector = moveVector + Vector3.new(1, 0, 0)
    end
    
    -- Mobile movement (from thumbstick)
    if mobileControls.movement.Magnitude > 0.1 then
        moveVector = Vector3.new(mobileControls.movement.X, 0, -mobileControls.movement.Y)
    end
    
    -- Normalize and apply movement
    if moveVector.Magnitude > 0 then
        moveVector = moveVector.Unit
        self:ApplyMovement(moveVector)
    end
    
    inputState.movement = moveVector
end

function PlayerMovementController:ApplyMovement(moveVector)
    if not humanoidRootPart or not humanoid then return end
    
    -- Calculate camera-relative movement
    local camera = Workspace.CurrentCamera
    local cameraCFrame = camera.CFrame
    local cameraDirection = cameraCFrame.LookVector
    local cameraRight = cameraCFrame.RightVector
    
    -- Remove Y component for horizontal movement
    cameraDirection = Vector3.new(cameraDirection.X, 0, cameraDirection.Z).Unit
    cameraRight = Vector3.new(cameraRight.X, 0, cameraRight.Z).Unit
    
    -- Calculate world movement direction
    local worldMoveVector = (cameraDirection * -moveVector.Z) + (cameraRight * moveVector.X)
    
    -- Set humanoid movement
    humanoid:Move(worldMoveVector, true)
    
    -- Update speed based on running state
    local targetSpeed = inputState.isRunning and MOVEMENT_CONFIG.runSpeed or MOVEMENT_CONFIG.walkSpeed
    if humanoid.WalkSpeed ~= targetSpeed then
        humanoid.WalkSpeed = targetSpeed
    end
end

function PlayerMovementController:HandleJumpInput()
    if not inputState.canMove or not humanoid or not humanoidRootPart then
        return
    end
    
    inputState.lastJumpInputTime = tick()
    
    local currentTime = tick()
    local timeSinceGrounded = currentTime - inputState.lastGroundTime
    
    -- Ground jump or coyote time jump
    if inputState.isOnGround or timeSinceGrounded <= MOVEMENT_CONFIG.coyoteTime then
        self:PerformJump("ground")
    -- Air jump
    elseif inputState.airJumpsUsed < MOVEMENT_CONFIG.maxAirJumps then
        self:PerformJump("air")
        inputState.airJumpsUsed = inputState.airJumpsUsed + 1
    -- Wall jump
    elseif inputState.wallJumpAvailable then
        self:PerformWallJump()
    end
end

function PlayerMovementController:PerformJump(jumpType)
    if not humanoid then return end
    
    inputState.isJumping = true
    
    -- Apply jump
    if jumpType == "air" then
        -- Air jump - custom velocity
        local bodyVelocity = humanoidRootPart:FindFirstChild("AirJumpVelocity")
        if not bodyVelocity then
            bodyVelocity = Instance.new("BodyVelocity")
            bodyVelocity.Name = "AirJumpVelocity"
            bodyVelocity.MaxForce = Vector3.new(0, 4000, 0)
            bodyVelocity.Parent = humanoidRootPart
        end
        
        bodyVelocity.Velocity = Vector3.new(0, MOVEMENT_CONFIG.jumpPower, 0)
        
        -- Remove after air time
        game:GetService("Debris"):AddItem(bodyVelocity, MOVEMENT_CONFIG.airTime)
    else
        -- Ground jump - use humanoid
        humanoid.Jump = true
    end
    
    -- Visual and audio effects
    self:PlayJumpEffects(jumpType)
    
    -- Send to server
    if Events.PlayerMovement then
        Events.PlayerMovement:FireServer({
            action = "jump",
            jumpType = jumpType,
            position = humanoidRootPart.Position,
            velocity = humanoidRootPart.AssemblyLinearVelocity
        })
    end
end

function PlayerMovementController:PerformWallJump()
    if not humanoidRootPart or not inputState.wallJumpAvailable then return end
    
    -- Calculate wall jump direction
    local wallNormal = inputState.lastWallNormal
    local jumpDirection = (wallNormal + Vector3.new(0, 1, 0)).Unit
    
    -- Apply wall jump force
    local bodyVelocity = Instance.new("BodyVelocity")
    bodyVelocity.MaxForce = Vector3.new(4000, 4000, 4000)
    bodyVelocity.Velocity = jumpDirection * MOVEMENT_CONFIG.wallJumpForce
    bodyVelocity.Parent = humanoidRootPart
    
    game:GetService("Debris"):AddItem(bodyVelocity, 0.3)
    
    -- Reset wall jump
    inputState.wallJumpAvailable = false
    inputState.airJumpsUsed = 0 -- Reset air jumps on wall jump
    
    -- Effects
    self:PlayJumpEffects("wall")
    
    -- Send to server
    if Events.PlayerMovement then
        Events.PlayerMovement:FireServer({
            action = "wallJump",
            wallNormal = wallNormal,
            position = humanoidRootPart.Position,
            velocity = bodyVelocity.Velocity
        })
    end
end

function PlayerMovementController:HandleDashInput()
    if not inputState.canMove or inputState.isDashing then return end
    
    local currentTime = tick()
    if currentTime - lastDashTime < MOVEMENT_CONFIG.dashCooldown then
        return
    end
    
    lastDashTime = currentTime
    self:PerformDash()
end

function PlayerMovementController:PerformDash()
    if not humanoidRootPart then return end
    
    inputState.isDashing = true
    
    -- Calculate dash direction
    local dashDirection = inputState.movement
    if dashDirection.Magnitude < 0.1 then
        -- Dash forward if no movement input
        dashDirection = humanoidRootPart.CFrame.LookVector
    end
    dashDirection = Vector3.new(dashDirection.X, 0, dashDirection.Z).Unit
    
    -- Apply dash force
    local bodyVelocity = Instance.new("BodyVelocity")
    bodyVelocity.MaxForce = Vector3.new(4000, 0, 4000)
    bodyVelocity.Velocity = dashDirection * MOVEMENT_CONFIG.dashDistance
    bodyVelocity.Parent = humanoidRootPart
    
    -- Dash duration
    spawn(function()
        wait(0.2)
        if bodyVelocity and bodyVelocity.Parent then
            bodyVelocity:Destroy()
        end
        inputState.isDashing = false
    end)
    
    -- Visual effects
    self:PlayDashEffects()
    
    -- Send to server
    if Events.PlayerMovement then
        Events.PlayerMovement:FireServer({
            action = "dash",
            direction = dashDirection,
            position = humanoidRootPart.Position
        })
    end
end

function PlayerMovementController:HandleRunInput(isRunning)
    inputState.isRunning = isRunning
    
    if humanoid then
        local targetSpeed = isRunning and MOVEMENT_CONFIG.runSpeed or MOVEMENT_CONFIG.walkSpeed
        humanoid.WalkSpeed = targetSpeed
    end
end

function PlayerMovementController:HandleColorSwitch(colorName)
    local currentTime = tick()
    if currentTime - lastColorSwitchTime < MOVEMENT_CONFIG.colorSwitchCooldown then
        return
    end
    
    if inputState.currentColor == colorName then
        return
    end
    
    lastColorSwitchTime = currentTime
    inputState.currentColor = colorName
    
    -- Update character appearance
    self:UpdateCharacterAppearance()
    
    -- Visual and audio effects
    self:PlayColorSwitchEffects(colorName)
    
    -- Send to server
    if Events.ColorChanged then
        Events.ColorChanged:FireServer(colorName)
    end
end

function PlayerMovementController:HandleRespawnRequest()
    if Events.RequestRespawn then
        Events.RequestRespawn:FireServer()
    end
end

function PlayerMovementController:HandleJoinGameRequest()
    if Events.RequestJoinGame then
        Events.RequestJoinGame:FireServer()
    end
end

function PlayerMovementController:UpdateCharacterAppearance()
    if not character then return end
    
    local colorData = COLORS[inputState.currentColor]
    if not colorData then return end
    
    -- Update character color and material
    for _, part in pairs(character:GetChildren()) do
        if part:IsA("BasePart") and part.Name ~= "HumanoidRootPart" then
            part.Color = colorData.color
            part.Material = colorData.material
            
            -- Add glow effect
            local pointLight = part:FindFirstChild("ColorGlow")
            if not pointLight then
                pointLight = Instance.new("PointLight")
                pointLight.Name = "ColorGlow"
                pointLight.Parent = part
            end
            
            pointLight.Color = colorData.color
            pointLight.Brightness = 0.3  -- Reduced for professional look
            pointLight.Range = 4  -- Slightly reduced range
        end
    end
end

function PlayerMovementController:OnHumanoidStateChanged(oldState, newState)
    if newState == Enum.HumanoidStateType.Freefall then
        inputState.isOnGround = false
    elseif newState == Enum.HumanoidStateType.Landed then
        inputState.isOnGround = true
        inputState.lastGroundTime = tick()
        inputState.airJumpsUsed = 0 -- Reset air jumps on landing
        
        -- Check for jump buffering
        if tick() - inputState.lastJumpInputTime <= MOVEMENT_CONFIG.jumpBufferTime then
            self:PerformJump("ground")
        end
    elseif newState == Enum.HumanoidStateType.Running or newState == Enum.HumanoidStateType.RunningNoPhysics then
        inputState.isOnGround = true
        inputState.lastGroundTime = tick()
    end
end

function PlayerMovementController:OnJumping()
    inputState.isJumping = true
    inputState.isOnGround = false
end

function PlayerMovementController:OnFreeFalling()
    inputState.isOnGround = false
end

function PlayerMovementController:OnLanded()
    inputState.isOnGround = true
    inputState.isJumping = false
    inputState.lastGroundTime = tick()
    inputState.airJumpsUsed = 0
    
    -- Landing effects
    self:PlayLandingEffects()
end

function PlayerMovementController:SetupCollisionDetection()
    if not humanoidRootPart then return end
    
    -- Raycast for wall detection
    RunService.Heartbeat:Connect(function()
        if not humanoidRootPart or inputState.isOnGround then return end
        
        self:CheckForWalls()
    end)
end

function PlayerMovementController:CheckForWalls()
    if not humanoidRootPart then return end
    
    local raycastParams = RaycastParams.new()
    raycastParams.FilterType = Enum.RaycastFilterType.Blacklist
    raycastParams.FilterDescendantsInstances = {character}
    
    -- Cast rays in multiple directions
    local directions = {
        humanoidRootPart.CFrame.RightVector,
        -humanoidRootPart.CFrame.RightVector,
        humanoidRootPart.CFrame.LookVector,
        -humanoidRootPart.CFrame.LookVector
    }
    
    for _, direction in ipairs(directions) do
        local rayResult = Workspace:Raycast(humanoidRootPart.Position, direction * 3, raycastParams)
        if rayResult then
            local normal = rayResult.Normal
            local angle = math.acos(normal:Dot(Vector3.new(0, 1, 0)))
            
            -- Check if wall is vertical enough for wall jumping
            if angle > math.rad(75) then
                inputState.wallJumpAvailable = true
                inputState.lastWallNormal = normal
                return
            end
        end
    end
    
    inputState.wallJumpAvailable = false
end

function PlayerMovementController:SetupMobileControls()
    if not UserInputService.TouchEnabled then return end
    
    print("📱 Setting up mobile controls...")
    
    -- Create mobile UI
    local playerGui = player:WaitForChild("PlayerGui")
    local mobileGui = playerGui:FindFirstChild("MobileControls")
    
    if not mobileGui then
        mobileGui = Instance.new("ScreenGui")
        mobileGui.Name = "MobileControls"
        mobileGui.Parent = playerGui
    end
    
    -- Jump button
    mobileControls.jumpButton = self:CreateMobileButton(mobileGui, "Jump", UDim2.new(1, -80, 1, -80), UDim2.new(0, 60, 0, 60))
    mobileControls.jumpButton.MouseButton1Down:Connect(function()
        self:HandleJumpInput()
    end)
    
    -- Dash button
    mobileControls.dashButton = self:CreateMobileButton(mobileGui, "Dash", UDim2.new(1, -160, 1, -80), UDim2.new(0, 60, 0, 60))
    mobileControls.dashButton.MouseButton1Down:Connect(function()
        self:HandleDashInput()
    end)
    
    -- Color buttons
    local colorIndex = 0
    for colorName, colorData in pairs(COLORS) do
        local button = self:CreateMobileButton(mobileGui, colorName, UDim2.new(0, 20, 1, -80 - (colorIndex * 70)), UDim2.new(0, 60, 0, 60))
        button.BackgroundColor3 = colorData.color
        button.MouseButton1Down:Connect(function()
            self:HandleColorSwitch(colorName)
        end)
        
        mobileControls.colorButtons[colorName] = button
        colorIndex = colorIndex + 1
    end
    
    -- Movement handled by default mobile controls
end

function PlayerMovementController:CreateMobileButton(parent, text, position, size)
    local button = Instance.new("TextButton")
    button.Text = text
    button.Position = position
    button.Size = size
    button.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
    button.BorderSizePixel = 2
    button.BorderColor3 = Color3.fromRGB(255, 255, 255)
    button.TextColor3 = Color3.fromRGB(255, 255, 255)
    button.TextScaled = true
    button.Font = Enum.Font.GothamBold
    button.Parent = parent
    
    return button
end

function PlayerMovementController:CleanupMobileControls()
    local playerGui = player:WaitForChild("PlayerGui")
    local mobileGui = playerGui:FindFirstChild("MobileControls")
    if mobileGui then
        mobileGui:Destroy()
    end
    
    mobileControls = {
        jumpButton = nil,
        dashButton = nil,
        colorButtons = {},
        movement = Vector2.new(0, 0)
    }
end

function PlayerMovementController:SetupCameraEffects()
    -- Camera shake and effects will be handled here
    -- This connects to the ScreenEffectsController
end

function PlayerMovementController:StartUpdateLoops()
    -- Network update loop (send position to server periodically)
    spawn(function()
        while true do
            wait(networkUpdateRate)
            self:SendNetworkUpdate()
        end
    end)
    
    -- Performance monitoring
    spawn(function()
        while true do
            wait(1)
            self:UpdatePerformanceMetrics()
        end
    end)
end

function PlayerMovementController:SendNetworkUpdate()
    if not humanoidRootPart or not Events.PlayerMovement then return end
    
    -- Only send if player is moving or state changed
    if inputState.movement.Magnitude > 0.1 or inputState.isJumping or inputState.isDashing then
        Events.PlayerMovement:FireServer({
            action = "update",
            position = humanoidRootPart.Position,
            velocity = humanoidRootPart.AssemblyLinearVelocity,
            rotation = humanoidRootPart.CFrame.Rotation,
            movement = inputState.movement,
            isOnGround = inputState.isOnGround,
            currentColor = inputState.currentColor
        })
    end
end

function PlayerMovementController:UpdatePerformanceMetrics()
    inputUpdateTime = tick()
    -- Track input lag, frame rate, etc.
end

-- Event Handlers for Game Events

function PlayerMovementController:OnGameStateChanged(newState, oldState)
    print("🎮 Game state changed: " .. tostring(oldState) .. " → " .. tostring(newState))
    
    if newState == "Running" then
        inputState.canMove = true
    elseif newState == "GameOver" or newState == "Lobby" then
        inputState.canMove = true
    elseif newState == "Countdown" then
        inputState.canMove = false -- Disable movement during countdown
    end
end

function PlayerMovementController:OnPlayerSpawned()
    print("👤 Player spawned, enabling movement")
    inputState.canMove = true
    inputState.currentColor = "Red"
    self:UpdateCharacterAppearance()
end

function PlayerMovementController:OnPlayerDied(deathData)
    print("💀 Player died: " .. tostring(deathData.reason))
    inputState.canMove = false
    
    -- Play death effects
    self:PlayDeathEffects(deathData.reason)
end

function PlayerMovementController:OnObstacleHit(reason)
    print("💥 Obstacle hit: " .. tostring(reason))
    
    -- Screen shake and effects
    self:PlayHitEffects(reason)
end

function PlayerMovementController:OnPowerupActivated(powerup)
    print("⚡ Powerup activated: " .. tostring(powerup.type))
    
    -- Apply powerup effects
    if powerup.type == "speed_boost" then
        MOVEMENT_CONFIG.walkSpeed = MOVEMENT_CONFIG.walkSpeed * 1.5
        MOVEMENT_CONFIG.runSpeed = MOVEMENT_CONFIG.runSpeed * 1.5
        if humanoid then
            humanoid.WalkSpeed = inputState.isRunning and MOVEMENT_CONFIG.runSpeed or MOVEMENT_CONFIG.walkSpeed
        end
    elseif powerup.type == "invincibility" then
        -- Visual invincibility effects
        self:PlayInvincibilityEffects(powerup.duration or 5)
    end
end

function PlayerMovementController:OnGameWarning(timeLeft, warningType)
    print("⚠️ Game warning: " .. tostring(warningType) .. " (" .. tostring(timeLeft) .. "s)")
    
    if warningType == "return_to_track" then
        self:PlayWarningEffects("Get back on track!")
    elseif warningType == "time_warning" then
        self:PlayWarningEffects("Time running out!")
    end
end

-- Effects and Feedback

function PlayerMovementController:PlayJumpEffects(jumpType)
    -- Trigger ScreenEffectsController for jump effects
    local intensity = 0.3
    local duration = 0.4
    
    if jumpType == "air" then
        print("🌟 Air jump effects")
        intensity = 0.4 -- More intense for air jumps
        
        -- Trigger jump effect via Events
        if Events.TriggerJumpEffect then
            Events.TriggerJumpEffect:FireServer("air", MOVEMENT_CONFIG.jumpPower)
        end
        
    elseif jumpType == "wall" then
        print("🧱 Wall jump effects")
        intensity = 0.5 -- Most intense for wall jumps
        
        if Events.TriggerJumpEffect then
            Events.TriggerJumpEffect:FireServer("wall", MOVEMENT_CONFIG.wallJumpForce)
        end
        
    else
        print("⬆️ Ground jump effects")
        intensity = 0.2 -- Light shake for ground jumps
        
        if Events.TriggerJumpEffect then
            Events.TriggerJumpEffect:FireServer("ground", MOVEMENT_CONFIG.jumpPower)
        end
    end
    
    -- Local screen shake as immediate feedback
    self:ScreenShake(intensity, duration)
    
    -- Get ScreenEffectsController if available
    local screenEffects = game.Players.LocalPlayer.PlayerGui:FindFirstChild("ScreenEffects")
    if screenEffects then
        -- Direct call to screen effects for immediate response
        game.ReplicatedStorage.Events.TriggerScreenShake:FireServer(intensity, 0.5)
    end
end

function PlayerMovementController:PlayDashEffects()
    print("💨 Dash effects")
    
    -- Trigger speed boost screen effects
    if Events.TriggerSpeedBoostEffect then
        Events.TriggerSpeedBoostEffect:FireServer(0.5) -- 0.5 second speed boost effect
    end
    
    -- Local immediate feedback
    self:ScreenShake(0.1, 10)
    
    -- Fire FOV zoom effect for speed feeling
    if game.ReplicatedStorage.Events:FindFirstChild("TriggerFOVZoom") then
        game.ReplicatedStorage.Events.TriggerFOVZoom:FireServer(0.3, 0.5) -- Slight zoom for 0.5 seconds
    end
end

function PlayerMovementController:PlayColorSwitchEffects(colorName)
    print("🎨 Color switch effects: " .. colorName)
    
    -- Flash effect
    local colorData = COLORS[colorName]
    if colorData then
        -- Play color switch sound
        -- Add particle effects
    end
end

function PlayerMovementController:PlayLandingEffects()
    print("⬇️ Landing effects")
    self:ScreenShake(0.1, 3)
end

function PlayerMovementController:PlayDeathEffects(reason)
    print("☠️ Death effects: " .. reason)
    self:ScreenShake(0.5, 20)
end

function PlayerMovementController:PlayHitEffects(reason)
    print("💢 Hit effects: " .. reason)
    self:ScreenShake(0.3, 15)
end

function PlayerMovementController:PlayInvincibilityEffects(duration)
    print("✨ Invincibility effects for " .. duration .. " seconds")
    
    if not character then return end
    
    -- Create sparkle effect
    spawn(function()
        local endTime = tick() + duration
        while tick() < endTime and character do
            for _, part in pairs(character:GetChildren()) do
                if part:IsA("BasePart") then
                    part.Material = Enum.Material.ForceField
                end
            end
            wait(0.2)
            
            for _, part in pairs(character:GetChildren()) do
                if part:IsA("BasePart") then
                    part.Material = COLORS[inputState.currentColor].material
                end
            end
            wait(0.2)
        end
    end)
end

function PlayerMovementController:PlayWarningEffects(message)
    print("⚠️ Warning: " .. message)
    -- Flash screen red or show warning UI
end

function PlayerMovementController:ScreenShake(duration, intensity)
    -- This would integrate with ScreenEffectsController
    print("📳 Screen shake: " .. duration .. "s, intensity: " .. intensity)
    
    -- Basic camera shake implementation
    local camera = Workspace.CurrentCamera
    if not camera then return end
    
    local originalCFrame = camera.CFrame
    local shakeEnd = tick() + duration
    
    if cameraShakeConnection then
        cameraShakeConnection:Disconnect()
    end
    
    cameraShakeConnection = RunService.Heartbeat:Connect(function()
        if tick() >= shakeEnd then
            cameraShakeConnection:Disconnect()
            cameraShakeConnection = nil
            return
        end
        
        local progress = (tick() - (shakeEnd - duration)) / duration
        local currentIntensity = intensity * (1 - progress)
        
        local offset = Vector3.new(
            math.random(-currentIntensity, currentIntensity) / 100,
            math.random(-currentIntensity, currentIntensity) / 100,
            math.random(-currentIntensity, currentIntensity) / 100
        )
        
        camera.CFrame = camera.CFrame + offset
    end)
end

-- Initialize the controller
PlayerMovementController:Init()

return PlayerMovementController
