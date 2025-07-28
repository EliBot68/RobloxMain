-- GameAudioService.luau
-- Handles all audio during gameplay including countdown, background music, and effects

local Players = game:GetService("Players")
local SoundService = game:GetService("SoundService")
local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local RemoteEvents = require(ReplicatedStorage.Shared.modules.RemoteEvents)

local GameAudioService = {}

-- Audio instances
local backgroundMusic = nil
local countdownSounds = {}
local barrierPassSounds = {}
local gameStartSound = nil

-- Audio configuration
local AUDIO_CONFIG = {
    backgroundMusic = {
        soundId = "rbxasset://sounds/electronicpingshort.wav", -- Placeholder - replace with actual music
        volume = 0.3,
        looped = true,
        pitch = 1.0
    },
    countdownBeep = {
        soundId = "rbxassetid://131961136",
        volume = 0.8,
        pitches = {0.7, 0.85, 1.0} -- 3, 2, 1 countdown
    },
    gameStart = {
        soundId = "rbxasset://sounds/action_get_up.mp3",
        volume = 0.9,
        pitch = 1.2
    },
    barrierPass = {
        soundIds = {
            "rbxasset://sounds/pop_mid_up.wav",
            "rbxasset://sounds/bell.wav",
            "rbxasset://sounds/electronicpingshort.wav"
        },
        volume = 0.6,
        pitchRange = {0.9, 1.3}
    },
    coinCollect = {
        soundIds = {
            "rbxasset://sounds/electronicpingshort.wav",
            "rbxasset://sounds/pop_mid_up.wav",
            "rbxasset://sounds/bell.wav"
        },
        volume = 0.7,
        pitchRange = {1.0, 1.4}
    }
}

function GameAudioService:Initialize()
    self:LoadAudioAssets()
    self:SetupRemoteEvents()
    print("🎵 GameAudioService initialized")
end

function GameAudioService:LoadAudioAssets()
    -- Load background music
    backgroundMusic = Instance.new("Sound")
    backgroundMusic.Name = "GameBackgroundMusic"
    backgroundMusic.SoundId = AUDIO_CONFIG.backgroundMusic.soundId
    backgroundMusic.Volume = AUDIO_CONFIG.backgroundMusic.volume
    backgroundMusic.Looped = AUDIO_CONFIG.backgroundMusic.looped
    backgroundMusic.Pitch = AUDIO_CONFIG.backgroundMusic.pitch
    backgroundMusic.Parent = SoundService
    
    -- Load countdown sounds
    for i = 1, 3 do
        local countdownSound = Instance.new("Sound")
        countdownSound.Name = "CountdownBeep" .. i
        countdownSound.SoundId = AUDIO_CONFIG.countdownBeep.soundId
        countdownSound.Volume = AUDIO_CONFIG.countdownBeep.volume
        countdownSound.Pitch = AUDIO_CONFIG.countdownBeep.pitches[i]
        countdownSound.Parent = SoundService
        table.insert(countdownSounds, countdownSound)
    end
    
    -- Load game start sound
    gameStartSound = Instance.new("Sound")
    gameStartSound.Name = "GameStartSound"
    gameStartSound.SoundId = AUDIO_CONFIG.gameStart.soundId
    gameStartSound.Volume = AUDIO_CONFIG.gameStart.volume
    gameStartSound.Pitch = AUDIO_CONFIG.gameStart.pitch
    gameStartSound.Parent = SoundService
    
    -- Load barrier pass sounds
    for i, soundId in ipairs(AUDIO_CONFIG.barrierPass.soundIds) do
        local barrierSound = Instance.new("Sound")
        barrierSound.Name = "BarrierPass" .. i
        barrierSound.SoundId = soundId
        barrierSound.Volume = AUDIO_CONFIG.barrierPass.volume
        barrierSound.Parent = SoundService
        table.insert(barrierPassSounds, barrierSound)
    end
    
    print("🎵 Audio assets loaded successfully")
end

function GameAudioService:SetupRemoteEvents()
    -- Handle countdown audio
    RemoteEvents.PlayCountdownBeep.OnServerEvent:Connect(function(player, countdownNumber)
        self:PlayCountdownBeep(player, countdownNumber)
    end)
    
    -- Handle game start audio
    RemoteEvents.PlayGameStartSound.OnServerEvent:Connect(function(player)
        self:PlayGameStart(player)
    end)
    
    -- Handle background music
    RemoteEvents.StartGameMusic.OnServerEvent:Connect(function(player)
        self:StartBackgroundMusic(player)
    end)
    
    RemoteEvents.StopGameMusic.OnServerEvent:Connect(function(player)
        self:StopBackgroundMusic(player)
    end)
    
    -- Handle barrier pass sounds
    RemoteEvents.PlayBarrierPassSound.OnServerEvent:Connect(function(player)
        self:PlayBarrierPassSound(player)
    end)
end

function GameAudioService:PlayCountdownBeep(player, countdownNumber)
    if countdownNumber >= 1 and countdownNumber <= 3 then
        local soundIndex = 4 - countdownNumber -- Convert 3,2,1 to 1,2,3 for pitch progression
        local sound = countdownSounds[soundIndex]
        if sound then
            -- Create a copy for this player to avoid conflicts
            local playerSound = sound:Clone()
            playerSound.Parent = workspace
            playerSound:Play()
            
            playerSound.Ended:Connect(function()
                playerSound:Destroy()
            end)
            
            print("🔢 Played countdown beep " .. countdownNumber .. " for " .. player.Name)
        end
    end
end

function GameAudioService:PlayGameStart(player)
    if gameStartSound then
        local playerSound = gameStartSound:Clone()
        playerSound.Parent = workspace
        playerSound:Play()
        
        playerSound.Ended:Connect(function()
            playerSound:Destroy()
        end)
        
        print("🚀 Played game start sound for " .. player.Name)
    end
end

function GameAudioService:StartBackgroundMusic(player)
    -- Fire to client to start background music
    RemoteEvents.ClientStartGameMusic:FireClient(player)
    print("🎵 Started background music for " .. player.Name)
end

function GameAudioService:StopBackgroundMusic(player)
    -- Fire to client to stop background music
    RemoteEvents.ClientStopGameMusic:FireClient(player)
    print("🎵 Stopped background music for " .. player.Name)
end

function GameAudioService:PlayBarrierPassSound(player)
    local randomSound = barrierPassSounds[math.random(1, #barrierPassSounds)]
    if randomSound then
        local playerSound = randomSound:Clone()
        -- Add random pitch variation
        local pitchRange = AUDIO_CONFIG.barrierPass.pitchRange
        playerSound.Pitch = math.random() * (pitchRange[2] - pitchRange[1]) + pitchRange[1]
        playerSound.Parent = workspace
        playerSound:Play()
        
        playerSound.Ended:Connect(function()
            playerSound:Destroy()
        end)
    end
end

-- Cleanup function
function GameAudioService:CleanupPlayerAudio(player)
    -- Stop any player-specific audio
    self:StopBackgroundMusic(player)
    print("🧹 Cleaned up audio for " .. player.Name)
end

-- Get current background music volume for balancing
function GameAudioService:GetMusicVolume()
    return AUDIO_CONFIG.backgroundMusic.volume
end

-- Set music volume (for dynamic adjustment)
function GameAudioService:SetMusicVolume(volume)
    AUDIO_CONFIG.backgroundMusic.volume = math.clamp(volume, 0, 1)
    if backgroundMusic then
        backgroundMusic.Volume = AUDIO_CONFIG.backgroundMusic.volume
    end
end

return GameAudioService
