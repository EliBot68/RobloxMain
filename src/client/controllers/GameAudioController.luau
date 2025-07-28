-- GameAudioController.luau
-- Client-side audio controller for game music and sound effects

local Players = game:GetService("Players")
local SoundService = game:GetService("SoundService")
local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local RemoteEvents = require(ReplicatedStorage.Shared.modules.RemoteEvents)

local player = Players.LocalPlayer
local GameAudioController = {}

-- Audio state
local backgroundMusic = nil
local isPlaying = false
local fadeInTween = nil
local fadeOutTween = nil

-- Music tracks for different game modes
local MUSIC_TRACKS = {
    normal = {
        soundId = "rbxasset://sounds/electronicpingshort.wav", -- Replace with actual track
        volume = 0.25,
        pitch = 1.0,
        name = "Color Rush Theme"
    },
    intense = {
        soundId = "rbxasset://sounds/impact_generic_large_water_1.mp3", -- Replace with actual track
        volume = 0.3,
        pitch = 1.1,
        name = "High Speed Theme"
    },
    victory = {
        soundId = "rbxasset://sounds/bell.wav", -- Replace with actual track
        volume = 0.4,
        pitch = 1.0,
        name = "Victory Theme"
    }
}

function GameAudioController:Init()
    self:SetupRemoteEvents()
    self:LoadMusicTracks()
    print("🎵 GameAudioController initialized")
end

function GameAudioController:LoadMusicTracks()
    -- Pre-load background music
    backgroundMusic = Instance.new("Sound")
    backgroundMusic.Name = "GameBackgroundMusic"
    backgroundMusic.Looped = true
    backgroundMusic.Volume = 0
    backgroundMusic.Parent = SoundService
    
    print("🎵 Music tracks loaded")
end

function GameAudioController:SetupRemoteEvents()
    -- Start background music
    RemoteEvents.ClientStartGameMusic.OnClientEvent:Connect(function()
        self:StartBackgroundMusic("normal")
    end)
    
    -- Stop background music
    RemoteEvents.ClientStopGameMusic.OnClientEvent:Connect(function()
        self:StopBackgroundMusic()
    end)
    
    -- Switch music themes
    RemoteEvents.ClientSwitchMusicTheme.OnClientEvent:Connect(function(theme)
        self:SwitchMusicTheme(theme)
    end)
    
    -- Play particle effects sound for barrier success
    RemoteEvents.PlayBarrierParticleSound.OnClientEvent:Connect(function()
        self:PlayBarrierSuccessSound()
    end)
    
    print("🎵 Remote events setup complete")
end

function GameAudioController:StartBackgroundMusic(theme)
    if isPlaying then
        self:StopBackgroundMusic()
        wait(0.1) -- Brief pause between tracks
    end
    
    theme = theme or "normal"
    local track = MUSIC_TRACKS[theme]
    
    if track and backgroundMusic then
        backgroundMusic.SoundId = track.soundId
        backgroundMusic.Pitch = track.pitch
        backgroundMusic:Play()
        
        -- Fade in the music
        backgroundMusic.Volume = 0
        isPlaying = true
        
        fadeInTween = TweenService:Create(
            backgroundMusic,
            TweenInfo.new(2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
            {Volume = track.volume}
        )
        fadeInTween:Play()
        
        print("🎵 Started background music: " .. track.name)
    end
end

function GameAudioController:StopBackgroundMusic()
    if backgroundMusic and isPlaying then
        -- Cancel any ongoing fade in
        if fadeInTween then
            fadeInTween:Cancel()
        end
        
        -- Fade out the music
        fadeOutTween = TweenService:Create(
            backgroundMusic,
            TweenInfo.new(1.5, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
            {Volume = 0}
        )
        fadeOutTween:Play()
        
        fadeOutTween.Completed:Connect(function()
            backgroundMusic:Stop()
            isPlaying = false
            print("🎵 Stopped background music")
        end)
    end
end

function GameAudioController:SwitchMusicTheme(newTheme)
    if isPlaying and MUSIC_TRACKS[newTheme] then
        local currentVolume = backgroundMusic.Volume
        
        -- Quick fade out
        local quickFadeOut = TweenService:Create(
            backgroundMusic,
            TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
            {Volume = 0}
        )
        quickFadeOut:Play()
        
        quickFadeOut.Completed:Connect(function()
            -- Switch track
            local track = MUSIC_TRACKS[newTheme]
            backgroundMusic.SoundId = track.soundId
            backgroundMusic.Pitch = track.pitch
            
            -- Fade back in
            local fadeIn = TweenService:Create(
                backgroundMusic,
                TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
                {Volume = track.volume}
            )
            fadeIn:Play()
            
            print("🎵 Switched to music theme: " .. track.name)
        end)
    end
end

function GameAudioController:PlayBarrierSuccessSound()
    -- Play satisfying sound for successful barrier pass
    local successSound = Instance.new("Sound")
    successSound.SoundId = "rbxasset://sounds/pop_mid_up.wav"
    successSound.Volume = 0.5
    successSound.Pitch = 1.0 + math.random() * 0.3 -- Random pitch variation
    successSound.Parent = SoundService
    successSound:Play()
    
    successSound.Ended:Connect(function()
        successSound:Destroy()
    end)
end

function GameAudioController:PlayParticlePassSound()
    -- Play sound specifically for particle effects when passing barriers
    local particleSound = Instance.new("Sound")
    particleSound.SoundId = "rbxasset://sounds/electronicpingshort.wav"
    particleSound.Volume = 0.4
    particleSound.Pitch = 1.2 + math.random() * 0.4 -- Higher pitch for particles
    particleSound.Parent = SoundService
    particleSound:Play()
    
    particleSound.Ended:Connect(function()
        particleSound:Destroy()
    end)
end

function GameAudioController:PlayCountdownSound(number)
    -- Play countdown beep
    local countdownSound = Instance.new("Sound")
    countdownSound.SoundId = "rbxassetid://131961136"
    countdownSound.Volume = 0.8
    countdownSound.Pitch = 0.7 + (number * 0.15) -- Increasing pitch for 1, 2, 3
    countdownSound.Parent = SoundService
    countdownSound:Play()
    
    countdownSound.Ended:Connect(function()
        countdownSound:Destroy()
    end)
end

function GameAudioController:PlayGameStartSound()
    -- Play exciting game start sound
    local startSound = Instance.new("Sound")
    startSound.SoundId = "rbxasset://sounds/action_get_up.mp3"
    startSound.Volume = 0.9
    startSound.Pitch = 1.2
    startSound.Parent = SoundService
    startSound:Play()
    
    startSound.Ended:Connect(function()
        startSound:Destroy()
    end)
end

-- Adjust music volume based on game state
function GameAudioController:SetMusicVolume(volume)
    if backgroundMusic and isPlaying then
        backgroundMusic.Volume = math.clamp(volume, 0, 1)
    end
end

-- Check if music is currently playing
function GameAudioController:IsMusicPlaying()
    return isPlaying
end

-- Get current music theme
function GameAudioController:GetCurrentTheme()
    if not isPlaying then return nil end
    
    for theme, track in pairs(MUSIC_TRACKS) do
        if backgroundMusic.SoundId == track.soundId then
            return theme
        end
    end
    return "unknown"
end

-- Cleanup
function GameAudioController:Cleanup()
    self:StopBackgroundMusic()
    if fadeInTween then fadeInTween:Cancel() end
    if fadeOutTween then fadeOutTween:Cancel() end
    print("🧹 GameAudioController cleaned up")
end

return GameAudioController
