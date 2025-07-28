-- EnhancedClientInit.client.luau
-- Enhanced client initialization using standardized controller architecture

print("🎮 Enhanced Color Rush Client starting...")

-- Core Roblox Services
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

-- Wait for essential shared modules
ReplicatedStorage:WaitForChild("Shared", 10)
if ReplicatedStorage.Shared:FindFirstChild("utils") then
    ReplicatedStorage.Shared.utils:WaitForChild("SafeRequire", 5)
end

-- Import utilities
local SafeRequire = require(ReplicatedStorage.Shared.utils.SafeRequire)
local ControllerRegistry = require(ReplicatedStorage.Shared.utils.ControllerRegistry)

-- Initialize player and wait for character
local player = Players.LocalPlayer
if not player.Character then
    player.CharacterAdded:Wait()
end

-- Wait a moment for essential game setup
wait(2)

-- Initialize ControllerRegistry and load all controllers
print("📦 Initializing ControllerRegistry...")
local initializedCount, failedControllers = ControllerRegistry:InitializeAll()

if #failedControllers > 0 then
    warn(string.format("⚠️ %d controllers failed to initialize: %s", #failedControllers, table.concat(failedControllers, ", ")))
else
    print(string.format("✅ All %d controllers initialized successfully", initializedCount))
end

-- Start auto-start controllers
print("🚀 Starting auto-start controllers...")
local startedCount = ControllerRegistry:StartAll()
print(string.format("✅ %d controllers started successfully", startedCount))

-- Setup global controller access for backward compatibility
print("🔗 Setting up global controller access...")
_G.Controllers = {}
for controllerName, _ in pairs(ControllerRegistry.Controllers) do
    _G.Controllers[controllerName] = ControllerRegistry:GetController(controllerName)
end

-- Initialize enhanced UI system if available
local EnhancedUIController = ControllerRegistry:GetController("EnhancedUIController")
if EnhancedUIController then
    print("🖥️ Setting up Enhanced UI...")
    local success = pcall(function()
        if EnhancedUIController.SetupMainUI then
            EnhancedUIController:SetupMainUI()
        end
    end)
    
    if success then
        print("✅ Enhanced UI initialized")
    else
        warn("⚠️ Enhanced UI setup failed")
    end
end

-- Setup input handling
local InputController = ControllerRegistry:GetController("InputController")
if InputController then
    print("⌨️ Setting up input handling...")
    -- Input controller should handle its own setup
end

-- Setup mobile-specific features if on mobile
if UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled then
    print("📱 Setting up mobile features...")
    local MobileUIController = ControllerRegistry:GetController("MobileUIController")
    if MobileUIController then
        -- Mobile controller should handle its own setup
        print("✅ Mobile UI configured")
    end
end

-- Display controller status
local status = ControllerRegistry:GetStatus()
print(string.format("📊 Controller Status: %d/%d loaded, %d/%d initialized, %d/%d started", 
    status.loaded, status.total,
    status.initialized, status.total,
    status.started, status.total
))

-- Setup periodic health check for critical controllers
spawn(function()
    while true do
        wait(120) -- Check every 2 minutes
        
        local coreControllers = {"GameController", "InputController", "GuiController"}
        for _, controllerName in ipairs(coreControllers) do
            local controller = ControllerRegistry:GetController(controllerName)
            if not controller or not controller.IsInitialized then
                warn(string.format("⚠️ Critical controller %s is not functioning properly", controllerName))
            end
        end
    end
end)

print("🎉 Enhanced Color Rush Client startup complete!")

-- Developer tools for controller management
if game:GetService("RunService"):IsStudio() then
    print("🛠️ Developer mode: Controller management commands available")
    print("   - _G.Controllers to access controllers")
    print("   - ControllerRegistry:GetStatus() for status")
end
