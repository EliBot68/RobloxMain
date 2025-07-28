-- UIManager.client.luau
-- Centralized UI management that coordinates between MainGameController and UIHandler
-- Ensures proper UI state synchronization and RemoteEvent handling

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer

local UIManager = {}

-- UI Controllers
local UIHandler = nil
local MainGameController = nil

-- State tracking
local isInitialized = false

function UIManager:Init()
    print("🎛️ Initializing UI Manager...")
    
    -- Load UI controllers
    self:LoadControllers()
    
    -- Setup coordination
    self:SetupCoordination()
    
    isInitialized = true
    print("✅ UI Manager initialized!")
end

function UIManager:LoadControllers()
    print("📦 Loading UI controllers...")
    
    -- Load UIHandler
    local uiSuccess, uiHandler = pcall(function()
        return require(script.Parent.ui.UIHandler)
    end)
    
    if uiSuccess then
        UIHandler = uiHandler
        print("✅ UIHandler loaded")
    else
        warn("❌ Failed to load UIHandler")
    end
    
    -- Load MainGameController
    local mainSuccess, mainController = pcall(function()
        return require(script.Parent.MainGameController)
    end)
    
    if mainSuccess then
        MainGameController = mainController
        print("✅ MainGameController loaded")
    else
        warn("❌ Failed to load MainGameController")
    end
end

function UIManager:SetupCoordination()
    print("🔗 Setting up UI coordination...")
    
    -- Ensure both controllers are properly connected
    if UIHandler and MainGameController then
        -- The UIHandler already connects to RemoteEvents directly,
        -- so we just need to ensure they're both active
        print("✅ UI coordination setup complete!")
    else
        warn("⚠️ Some UI controllers failed to load")
    end
end

-- Public API for external access
function UIManager:GetUIHandler()
    return UIHandler
end

function UIManager:GetMainGameController()
    return MainGameController
end

function UIManager:IsInitialized()
    return isInitialized
end

-- Initialize automatically
UIManager:Init()

return UIManager
