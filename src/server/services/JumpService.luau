-- JumpService.luau
-- Server-side jump mechanics validation and management

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Knit = require(ReplicatedStorage.Packages.Knit)
local RemoteEvents = require(ReplicatedStorage.Shared.modules.RemoteEvents)

local JumpService = Knit.CreateService {
    Name = "JumpService",
    Client = {}
}

-- Player jump states
local playerJumpStates = {}

-- Jump validation settings
local JUMP_SETTINGS = {
    maxJumpCooldown = 0.5, -- Minimum time between jumps
    maxJumpHeight = 50, -- Maximum allowed jump height
    maxJumpDistance = 100, -- Maximum horizontal distance per jump
    antiCheatEnabled = true
}

function JumpService:KnitStart()
    print("🦘 JumpService starting...")
    
    -- Setup remote event handlers
    self:SetupRemoteEvents()
    
    -- Setup player management
    self:SetupPlayerManagement()
    
    print("✅ JumpService started!")
end

function JumpService:KnitInit()
    -- Initialize service
end

function JumpService:SetupRemoteEvents()
    -- Handle player jump attempts
    RemoteEvents.PlayerJumped.OnServerEvent:Connect(function(player)
        self:ValidatePlayerJump(player)
    end)
    
    -- Handle jump state requests
    RemoteEvents.RequestJumpState.OnServerEvent:Connect(function(player)
        self:SendJumpState(player)
    end)
end

function JumpService:SetupPlayerManagement()
    -- Initialize jump state for new players
    Players.PlayerAdded:Connect(function(player)
        self:InitializePlayerJumpState(player)
    end)
    
    -- Clean up when players leave
    Players.PlayerRemoving:Connect(function(player)
        self:CleanupPlayerJumpState(player)
    end)
    
    -- Handle character spawning
    Players.PlayerAdded:Connect(function(player)
        player.CharacterAdded:Connect(function(character)
            self:SetupCharacterJumpMonitoring(player, character)
        end)
    end)
end

function JumpService:InitializePlayerJumpState(player)
    playerJumpStates[player.UserId] = {
        canJump = true,
        isJumping = false,
        isInAir = false,
        lastJumpTime = 0,
        jumpCount = 0,
        lastPosition = Vector3.new(0, 0, 0),
        
        -- Anti-cheat data
        suspiciousJumps = 0,
        lastValidationTime = tick()
    }
    
    print("🎮 Jump state initialized for " .. player.Name)
end

function JumpService:CleanupPlayerJumpState(player)
    playerJumpStates[player.UserId] = nil
    print("🧹 Jump state cleaned up for " .. player.Name)
end

function JumpService:SetupCharacterJumpMonitoring(player, character)
    local humanoid = character:WaitForChild("Humanoid")
    local humanoidRootPart = character:WaitForChild("HumanoidRootPart")
    
    local jumpState = playerJumpStates[player.UserId]
    if not jumpState then return end
    
    -- Reset jump state for new character
    jumpState.canJump = true
    jumpState.isJumping = false
    jumpState.isInAir = false
    jumpState.lastPosition = humanoidRootPart.Position
    
    -- Monitor humanoid state changes
    humanoid.StateChanged:Connect(function(oldState, newState)
        if newState == Enum.HumanoidStateType.Jumping then
            self:OnPlayerJumpStateChanged(player, "jumping")
        elseif newState == Enum.HumanoidStateType.Landed then
            self:OnPlayerJumpStateChanged(player, "landed")
        elseif newState == Enum.HumanoidStateType.Freefall then
            self:OnPlayerJumpStateChanged(player, "freefall")
        end
    end)
    
    -- Monitor position for anti-cheat
    if JUMP_SETTINGS.antiCheatEnabled then
        spawn(function()
            self:MonitorPlayerPosition(player, character)
        end)
    end
end

function JumpService:ValidatePlayerJump(player)
    local jumpState = playerJumpStates[player.UserId]
    if not jumpState then
        self:InitializePlayerJumpState(player)
        jumpState = playerJumpStates[player.UserId]
    end
    
    local currentTime = tick()
    local timeSinceLastJump = currentTime - jumpState.lastJumpTime
    
    -- Validate jump attempt
    local isValid = true
    local reason = ""
    
    -- Check if player can jump
    if not jumpState.canJump then
        isValid = false
        reason = "Cannot jump at this time"
    end
    
    -- Check cooldown
    if timeSinceLastJump < JUMP_SETTINGS.maxJumpCooldown then
        isValid = false
        reason = "Jump cooldown active"
    end
    
    -- Check if already jumping
    if jumpState.isJumping then
        isValid = false
        reason = "Already jumping"
    end
    
    -- Anti-cheat: Check for suspicious jump frequency
    if JUMP_SETTINGS.antiCheatEnabled then
        if timeSinceLastJump < 0.1 then -- Too frequent
            jumpState.suspiciousJumps = jumpState.suspiciousJumps + 1
            if jumpState.suspiciousJumps > 5 then
                isValid = false
                reason = "Suspicious jump pattern detected"
                print("⚠️ Suspicious jumping detected from " .. player.Name)
            end
        else
            -- Reset suspicious counter if normal jumping
            jumpState.suspiciousJumps = 0
        end
    end
    
    -- Update jump state if valid
    if isValid then
        jumpState.lastJumpTime = currentTime
        jumpState.jumpCount = jumpState.jumpCount + 1
        jumpState.canJump = false
        jumpState.isJumping = true
        
        print("✅ Jump validated for " .. player.Name)
        
        -- Notify analytics
        self:LogJumpEvent(player, "jump_successful")
    else
        print("❌ Jump rejected for " .. player.Name .. ": " .. reason)
        
        -- Notify analytics
        self:LogJumpEvent(player, "jump_rejected", reason)
    end
    
    -- Send validation result to client
    RemoteEvents.JumpValidated:FireClient(player, isValid, reason)
    
    return isValid
end

function JumpService:OnPlayerJumpStateChanged(player, state)
    local jumpState = playerJumpStates[player.UserId]
    if not jumpState then return end
    
    if state == "jumping" then
        jumpState.isJumping = true
        jumpState.isInAir = true
        jumpState.canJump = false
        
    elseif state == "landed" then
        jumpState.isJumping = false
        jumpState.isInAir = false
        
        -- Start cooldown before allowing next jump
        spawn(function()
            wait(JUMP_SETTINGS.maxJumpCooldown)
            if jumpState then
                jumpState.canJump = true
                
                -- Send updated state to client
                self:SendJumpState(player)
            end
        end)
        
    elseif state == "freefall" then
        jumpState.isInAir = true
        jumpState.canJump = false
    end
    
    -- Send updated state to client
    self:SendJumpState(player)
end

function JumpService:MonitorPlayerPosition(player, character)
    local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
    if not humanoidRootPart then return end
    
    local jumpState = playerJumpStates[player.UserId]
    if not jumpState then return end
    
    local lastPosition = humanoidRootPart.Position
    local checkInterval = 0.1
    
    while character.Parent and jumpState do
        wait(checkInterval)
        
        if not humanoidRootPart.Parent then break end
        
        local currentPosition = humanoidRootPart.Position
        local deltaPosition = currentPosition - lastPosition
        
        -- Check for suspicious vertical movement
        if deltaPosition.Y > JUMP_SETTINGS.maxJumpHeight then
            print("⚠️ Suspicious jump height detected from " .. player.Name)
            jumpState.suspiciousJumps = jumpState.suspiciousJumps + 1
        end
        
        -- Check for suspicious horizontal movement during jump
        if jumpState.isJumping then
            local horizontalDistance = Vector3.new(deltaPosition.X, 0, deltaPosition.Z).Magnitude
            if horizontalDistance > JUMP_SETTINGS.maxJumpDistance then
                print("⚠️ Suspicious jump distance detected from " .. player.Name)
                jumpState.suspiciousJumps = jumpState.suspiciousJumps + 1
            end
        end
        
        lastPosition = currentPosition
        jumpState.lastPosition = currentPosition
    end
end

function JumpService:SendJumpState(player)
    local jumpState = playerJumpStates[player.UserId]
    if not jumpState then return end
    
    RemoteEvents.UpdateJumpState:FireClient(player, {
        canJump = jumpState.canJump,
        isJumping = jumpState.isJumping,
        isInAir = jumpState.isInAir,
        jumpCount = jumpState.jumpCount
    })
end

function JumpService:GetPlayerJumpState(player)
    return playerJumpStates[player.UserId]
end

function JumpService:SetPlayerJumpState(player, state)
    local jumpState = playerJumpStates[player.UserId]
    if not jumpState then
        self:InitializePlayerJumpState(player)
        jumpState = playerJumpStates[player.UserId]
    end
    
    for key, value in pairs(state) do
        jumpState[key] = value
    end
    
    -- Send updated state to client
    self:SendJumpState(player)
end

function JumpService:EnableJump(player)
    local jumpState = playerJumpStates[player.UserId]
    if jumpState then
        jumpState.canJump = true
        self:SendJumpState(player)
    end
end

function JumpService:DisableJump(player)
    local jumpState = playerJumpStates[player.UserId]
    if jumpState then
        jumpState.canJump = false
        self:SendJumpState(player)
    end
end

function JumpService:ResetJumpCooldown(player)
    local jumpState = playerJumpStates[player.UserId]
    if jumpState then
        jumpState.lastJumpTime = 0
        jumpState.canJump = true
        self:SendJumpState(player)
    end
end

function JumpService:LogJumpEvent(player, eventType, details)
    -- Log jump events for analytics
    if RemoteEvents.LogAnalyticsEvent then
        RemoteEvents.LogAnalyticsEvent:Fire(player.UserId, "jump_mechanics", {
            event_type = eventType,
            player_name = player.Name,
            details = details or "",
            timestamp = os.time()
        })
    end
end

-- Client-facing methods
function JumpService.Client:GetJumpState(player)
    return self.Server:GetPlayerJumpState(player)
end

function JumpService.Client:RequestJumpState(player)
    self.Server:SendJumpState(player)
end

return JumpService
