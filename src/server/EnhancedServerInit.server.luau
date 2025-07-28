-- EnhancedServerInit.server.luau
-- Enhanced server initialization using standardized service architecture

print("🚀 Enhanced Color Rush Server starting...")

-- Core Roblox Services
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

-- Import utilities
local SafeRequire = require(ReplicatedStorage.Shared.utils.SafeRequire)
local ServiceRegistry = require(ReplicatedStorage.Shared.utils.ServiceRegistry)

-- Initialize RuntimeValidator for system health checking
print("🔍 Initializing RuntimeValidator...")
local RuntimeValidator = SafeRequire.requireWithRetry(
    ReplicatedStorage.Shared.services.RuntimeValidator,
    3
)

if RuntimeValidator then
    RuntimeValidator:Init()
    print("✅ RuntimeValidator initialized successfully")
else
    warn("⚠️ RuntimeValidator failed to load - continuing with fallback")
end

-- Initialize ServiceRegistry and load all services
print("📦 Initializing ServiceRegistry...")
local initializedCount, failedServices = ServiceRegistry:InitializeAll()

if #failedServices > 0 then
    warn(string.format("⚠️ %d services failed to initialize: %s", #failedServices, table.concat(failedServices, ", ")))
else
    print(string.format("✅ All %d services initialized successfully", initializedCount))
end

-- Start auto-start services
print("🚀 Starting auto-start services...")
local startedCount = ServiceRegistry:StartAll()
print(string.format("✅ %d services started successfully", startedCount))

-- Setup global service access for backward compatibility
print("🔗 Setting up global service access...")
_G.Services = {}
for serviceName, _ in pairs(ServiceRegistry.Services) do
    _G.Services[serviceName] = ServiceRegistry:GetService(serviceName)
end

-- Initialize MainGameService if available
local MainGameService = ServiceRegistry:GetService("MainGameService")
if MainGameService then
    print("🎮 Initializing MainGameService...")
    local success = pcall(function()
        MainGameService:Init()
        if MainGameService.Config and MainGameService.Config.autoStartAfterInit then
            MainGameService:Start()
        end
    end)
    
    if success then
        print("✅ MainGameService initialized and started")
    else
        warn("⚠️ MainGameService initialization failed")
    end
end

-- Display service status
local status = ServiceRegistry:GetStatus()
print(string.format("📊 Service Status: %d/%d loaded, %d/%d initialized, %d/%d started", 
    status.loaded, status.total,
    status.initialized, status.total,
    status.started, status.total
))

-- Setup periodic health check
spawn(function()
    while true do
        wait(60) -- Check every minute
        
        if RuntimeValidator and RuntimeValidator.ValidateAll then
            local success = pcall(function()
                RuntimeValidator:ValidateAll()
            end)
            
            if not success then
                warn("⚠️ RuntimeValidator health check failed")
            end
        end
    end
end)

print("🎉 Enhanced Color Rush Server startup complete!")

-- Developer tools for service management
if game:GetService("RunService"):IsStudio() then
    print("🛠️ Developer mode: Service management commands available")
    print("   - _G.Services to access services")
    print("   - ServiceRegistry:GetStatus() for status")
    print("   - RuntimeValidator:ValidateAll() for validation")
end
