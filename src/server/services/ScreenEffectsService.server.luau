-- ScreenEffectsService.server.luau
-- Server-side service to trigger screen effects for players
-- Communicates with ScreenEffectsController on client

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local ScreenEffectsService = {}

-- Create RemoteEvents for client communication
local eventsFolder = ReplicatedStorage:FindFirstChild("Events") or Instance.new("Folder")
eventsFolder.Name = "Events"
eventsFolder.Parent = ReplicatedStorage

-- Screen Effects RemoteEvents
local speedBoostEvent = Instance.new("RemoteEvent")
speedBoostEvent.Name = "SpeedBoostActivated"
speedBoostEvent.Parent = eventsFolder

local jumpEvent = Instance.new("RemoteEvent")
jumpEvent.Name = "PlayerJumped"
jumpEvent.Parent = eventsFolder

local deathEvent = Instance.new("RemoteEvent")
deathEvent.Name = "PlayerDied"
deathEvent.Parent = eventsFolder

local respawnEvent = Instance.new("RemoteEvent")
respawnEvent.Name = "PlayerRespawned"
respawnEvent.Parent = eventsFolder

local flashEvent = Instance.new("RemoteEvent")
flashEvent.Name = "FlashEffect"
flashEvent.Parent = eventsFolder

local shakeEvent = Instance.new("RemoteEvent")
shakeEvent.Name = "ScreenShake"
shakeEvent.Parent = eventsFolder

function ScreenEffectsService:Init()
    print("📹 Screen Effects Service initialized on server!")
    
    -- Set up player connections
    Players.PlayerAdded:Connect(function(player)
        self:SetupPlayerEffects(player)
    end)
    
    -- Set up existing players
    for _, player in pairs(Players:GetPlayers()) do
        self:SetupPlayerEffects(player)
    end
end

function ScreenEffectsService:SetupPlayerEffects(player)
    player.CharacterAdded:Connect(function(character)
        local humanoid = character:WaitForChild("Humanoid")
        
        -- Listen for death
        humanoid.Died:Connect(function()
            deathEvent:FireClient(player)
        end)
        
        -- Listen for jumping
        humanoid.Jumping:Connect(function()
            jumpEvent:FireClient(player, 1.0)
        end)
    end)
    
    print("🎮 Screen effects setup for player: " .. player.Name)
end

-- Public API Methods
function ScreenEffectsService:TriggerSpeedBoost(player, duration)
    if player and player.Parent then
        speedBoostEvent:FireClient(player, duration or 1.0)
        print("⚡ Speed boost effect triggered for " .. player.Name .. " (" .. (duration or 1.0) .. "s)")
    end
end

function ScreenEffectsService:TriggerSpeedBoostAll(duration)
    speedBoostEvent:FireAllClients(duration or 1.0)
    print("⚡ Speed boost effect triggered for all players (" .. (duration or 1.0) .. "s)")
end

function ScreenEffectsService:TriggerJump(player, jumpPower)
    if player and player.Parent then
        jumpEvent:FireClient(player, jumpPower or 1.0)
        print("🦘 Jump effect triggered for " .. player.Name .. " (power: " .. (jumpPower or 1.0) .. ")")
    end
end

function ScreenEffectsService:TriggerJumpAll(jumpPower)
    jumpEvent:FireAllClients(jumpPower or 1.0)
    print("🦘 Jump effect triggered for all players (power: " .. (jumpPower or 1.0) .. ")")
end

function ScreenEffectsService:TriggerDeath(player)
    if player and player.Parent then
        deathEvent:FireClient(player)
        print("💀 Death effect triggered for " .. player.Name)
    end
end

function ScreenEffectsService:TriggerRespawn(player)
    if player and player.Parent then
        respawnEvent:FireClient(player)
        print("❤️ Respawn effect triggered for " .. player.Name)
    end
end

function ScreenEffectsService:TriggerFlash(player, color, intensity, duration)
    if player and player.Parent then
        flashEvent:FireClient(player, color or Color3.new(1, 1, 1), intensity or 0.5, duration or 0.2)
        print("✨ Flash effect triggered for " .. player.Name)
    end
end

function ScreenEffectsService:TriggerFlashAll(color, intensity, duration)
    flashEvent:FireAllClients(color or Color3.new(1, 1, 1), intensity or 0.5, duration or 0.2)
    print("✨ Flash effect triggered for all players")
end

function ScreenEffectsService:TriggerShake(player, intensity, duration)
    if player and player.Parent then
        shakeEvent:FireClient(player, intensity or 1.0, duration or 0.5)
        print("📳 Screen shake triggered for " .. player.Name .. " (intensity: " .. (intensity or 1.0) .. ")")
    end
end

function ScreenEffectsService:TriggerShakeAll(intensity, duration)
    shakeEvent:FireAllClients(intensity or 1.0, duration or 0.5)
    print("📳 Screen shake triggered for all players (intensity: " .. (intensity or 1.0) .. ")")
end

-- Initialize
ScreenEffectsService:Init()

return ScreenEffectsService
