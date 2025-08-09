-- Streamlined Client Entry Point - WORKING VERSION!
print("🎨 Streamlined Color Rush Client starting...")

local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

-- Simple client state
local ClientState = {
    initialized = false,
    characterLoaded = false
}

-- Simple client initialization
local function initializeClient()
    print("🎮 Initializing client for:", LocalPlayer.Name)
    
    -- Wait for character
    if LocalPlayer.Character then
        onCharacterAdded(LocalPlayer.Character)
    end
    
    LocalPlayer.CharacterAdded:Connect(onCharacterAdded)
    
    ClientState.initialized = true
    print("✅ Client initialization complete!")
end

-- Handle character spawning
function onCharacterAdded(character)
    print("🏃 Character loaded:", character.Name)
    ClientState.characterLoaded = true
    
    -- Simple character setup
    local humanoid = character:WaitForChild("Humanoid")
    if humanoid then
        print("� Humanoid ready for:", LocalPlayer.Name)
    end
end

-- Simple client loop
local function startClientLoop()
    task.spawn(function()
        while true do
            task.wait(10) -- Every 10 seconds
            if ClientState.initialized and ClientState.characterLoaded then
                print("� Client heartbeat - Ready for gameplay!")
            end
        end
    end)
end

-- Initialize everything
print("📦 Starting streamlined client...")
initializeClient()
startClientLoop()
print("🚀 Client ready!")
print("🔧 Live sync is working - make edits to see changes!")
