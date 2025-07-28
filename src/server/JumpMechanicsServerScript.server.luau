-- JumpMechanicsServerScript.server.luau
-- Server-side jump validation and anti-cheat for Color Rush

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

-- Safe require for modules
local SafeRequire = require(ReplicatedStorage.Shared.utils.SafeRequire)
local RemoteEvents = SafeRequire.requireWithRetry(ReplicatedStorage.Shared.modules.RemoteEvents, 3)

if not RemoteEvents then
    warn("❌ Failed to load RemoteEvents - Jump mechanics server disabled")
    return
end

-- Jump validation service
local JumpMechanicsServer = {
    playerStates = {},
    settings = {
        maxJumpCooldown = 0.5,
        maxJumpHeight = 50,
        maxJumpDistance = 100,
        antiCheatEnabled = true,
        suspicionThreshold = 5
    }
}

function JumpMechanicsServer:Init()
    print("🦘 Jump Mechanics Server initializing...")
    
    self:SetupPlayerManagement()
    self:SetupRemoteEvents()
    
    print("✅ Jump Mechanics Server initialized!")
end

function JumpMechanicsServer:SetupPlayerManagement()
    -- Handle player joining
    Players.PlayerAdded:Connect(function(player)
        self:InitializePlayerState(player)
    end)
    
    -- Handle player leaving
    Players.PlayerRemoving:Connect(function(player)
        self:CleanupPlayerState(player)
    end)
    
    -- Handle character spawning
    Players.PlayerAdded:Connect(function(player)
        player.CharacterAdded:Connect(function(character)
            self:SetupCharacterMonitoring(player, character)
        end)
    end)
    
    -- Initialize existing players
    for _, player in pairs(Players:GetPlayers()) do
        self:InitializePlayerState(player)
        if player.Character then
            self:SetupCharacterMonitoring(player, player.Character)
        end
    end
end

function JumpMechanicsServer:InitializePlayerState(player)
    self.playerStates[player.UserId] = {
        canJump = true,
        isJumping = false,
        isInAir = false,
        lastJumpTime = 0,
        jumpCount = 0,
        lastPosition = Vector3.new(0, 0, 0),
        suspiciousJumps = 0,
        lastValidationTime = tick(),
        connections = {}
    }
    
    print("🎮 Jump state initialized for " .. player.Name)
end

function JumpMechanicsServer:CleanupPlayerState(player)
    local state = self.playerStates[player.UserId]
    if state then
        -- Disconnect any connections
        for _, connection in pairs(state.connections) do
            if connection then
                connection:Disconnect()
            end
        end
        
        self.playerStates[player.UserId] = nil
        print("🧹 Jump state cleaned up for " .. player.Name)
    end
end

function JumpMechanicsServer:SetupCharacterMonitoring(player, character)
    local humanoid = character:WaitForChild("Humanoid")
    local humanoidRootPart = character:WaitForChild("HumanoidRootPart")
    
    local state = self.playerStates[player.UserId]
    if not state then
        self:InitializePlayerState(player)
        state = self.playerStates[player.UserId]
    end
    
    -- Reset state for new character
    state.canJump = true
    state.isJumping = false
    state.isInAir = false
    state.lastPosition = humanoidRootPart.Position
    
    -- Disconnect old connections
    for _, connection in pairs(state.connections) do
        if connection then
            connection:Disconnect()
        end
    end
    state.connections = {}
    
    -- Monitor humanoid state changes
    state.connections.stateChanged = humanoid.StateChanged:Connect(function(oldState, newState)
        self:OnStateChanged(player, newState)
    end)
    
    -- Anti-cheat position monitoring
    if self.settings.antiCheatEnabled then
        state.connections.positionMonitor = RunService.Heartbeat:Connect(function()
            self:MonitorPosition(player, character)
        end)
    end
end

function JumpMechanicsServer:OnStateChanged(player, newState)
    local state = self.playerStates[player.UserId]
    if not state then return end
    
    if newState == Enum.HumanoidStateType.Jumping then
        state.isJumping = true
        state.isInAir = true
        state.canJump = false
        
    elseif newState == Enum.HumanoidStateType.Landed then
        state.isJumping = false
        state.isInAir = false
        
        -- Start cooldown
        spawn(function()
            wait(self.settings.maxJumpCooldown)
            if state then
                state.canJump = true
                self:SendStateUpdate(player)
            end
        end)
        
    elseif newState == Enum.HumanoidStateType.Freefall then
        state.isInAir = true
        state.canJump = false
    end
    
    self:SendStateUpdate(player)
end

function JumpMechanicsServer:MonitorPosition(player, character)
    local state = self.playerStates[player.UserId]
    if not state then return end
    
    local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
    if not humanoidRootPart then return end
    
    local currentPosition = humanoidRootPart.Position
    local deltaPosition = currentPosition - state.lastPosition
    
    -- Check for suspicious vertical movement
    if deltaPosition.Y > self.settings.maxJumpHeight then
        self:FlagSuspiciousActivity(player, "excessive_jump_height", deltaPosition.Y)
    end
    
    -- Check for suspicious horizontal movement during jump
    if state.isJumping then
        local horizontalDistance = Vector3.new(deltaPosition.X, 0, deltaPosition.Z).Magnitude
        if horizontalDistance > self.settings.maxJumpDistance then
            self:FlagSuspiciousActivity(player, "excessive_jump_distance", horizontalDistance)
        end
    end
    
    state.lastPosition = currentPosition
end

function JumpMechanicsServer:FlagSuspiciousActivity(player, activityType, value)
    local state = self.playerStates[player.UserId]
    if not state then return end
    
    state.suspiciousJumps = state.suspiciousJumps + 1
    
    print(string.format("⚠️ Suspicious jump activity from %s: %s (value: %.2f)", 
        player.Name, activityType, value))
    
    -- Take action if threshold exceeded
    if state.suspiciousJumps >= self.settings.suspicionThreshold then
        self:HandleSuspiciousPlayer(player)
    end
end

function JumpMechanicsServer:HandleSuspiciousPlayer(player)
    local state = self.playerStates[player.UserId]
    if not state then return end
    
    print("🚨 Taking action against suspicious player: " .. player.Name)
    
    -- Disable jumping temporarily
    state.canJump = false
    self:SendStateUpdate(player)
    
    -- Re-enable after a timeout
    spawn(function()
        wait(5) -- 5 second timeout
        if state then
            state.canJump = true
            state.suspiciousJumps = 0
            self:SendStateUpdate(player)
            print("🔓 Jump restrictions lifted for " .. player.Name)
        end
    end)
end

function JumpMechanicsServer:SetupRemoteEvents()
    -- Handle jump attempts
    RemoteEvents.PlayerJumped.OnServerEvent:Connect(function(player)
        self:ValidateJump(player)
    end)
    
    -- Handle state requests
    RemoteEvents.RequestJumpState.OnServerEvent:Connect(function(player)
        self:SendStateUpdate(player)
    end)
end

function JumpMechanicsServer:ValidateJump(player)
    local state = self.playerStates[player.UserId]
    if not state then
        self:InitializePlayerState(player)
        state = self.playerStates[player.UserId]
    end
    
    local currentTime = tick()
    local timeSinceLastJump = currentTime - state.lastJumpTime
    
    local isValid = true
    local reason = ""
    
    -- Validation checks
    if not state.canJump then
        isValid = false
        reason = "Cannot jump at this time"
    end
    
    if timeSinceLastJump < self.settings.maxJumpCooldown then
        isValid = false
        reason = "Jump cooldown active"
    end
    
    if state.isJumping then
        isValid = false
        reason = "Already jumping"
    end
    
    -- Anti-cheat: Check for spam jumping
    if self.settings.antiCheatEnabled then
        if timeSinceLastJump < 0.1 then
            state.suspiciousJumps = state.suspiciousJumps + 1
            if state.suspiciousJumps > 3 then
                isValid = false
                reason = "Suspicious jump pattern"
            end
        else
            state.suspiciousJumps = math.max(0, state.suspiciousJumps - 1)
        end
    end
    
    -- Update state if valid
    if isValid then
        state.lastJumpTime = currentTime
        state.jumpCount = state.jumpCount + 1
        state.canJump = false
        state.isJumping = true
        
        print(string.format("✅ Jump validated for %s (count: %d)", player.Name, state.jumpCount))
    else
        print(string.format("❌ Jump rejected for %s: %s", player.Name, reason))
    end
    
    -- Send result to client
    RemoteEvents.JumpValidated:FireClient(player, isValid, reason)
    
    return isValid
end

function JumpMechanicsServer:SendStateUpdate(player)
    local state = self.playerStates[player.UserId]
    if not state then return end
    
    RemoteEvents.UpdateJumpState:FireClient(player, {
        canJump = state.canJump,
        isJumping = state.isJumping,
        isInAir = state.isInAir,
        jumpCount = state.jumpCount
    })
end

function JumpMechanicsServer:GetPlayerState(player)
    return self.playerStates[player.UserId]
end

function JumpMechanicsServer:SetPlayerJumpEnabled(player, enabled)
    local state = self.playerStates[player.UserId]
    if state then
        state.canJump = enabled
        self:SendStateUpdate(player)
    end
end

function JumpMechanicsServer:ResetPlayerJumpCooldown(player)
    local state = self.playerStates[player.UserId]
    if state then
        state.lastJumpTime = 0
        state.canJump = true
        self:SendStateUpdate(player)
    end
end

-- API for other scripts
_G.JumpMechanicsServer = JumpMechanicsServer

-- Initialize the service
JumpMechanicsServer:Init()
