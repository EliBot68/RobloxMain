-- ExampleServiceConversions.luau
-- Practical examples showing how to convert from legacy patterns to ModernServiceFramework
-- Demonstrates real-world conversion scenarios with before/after comparisons

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ModernServiceFramework = require(ReplicatedStorage.Shared.core.ModernServiceFramework)

local ExampleServiceConversions = {}

-- ========================================
-- EXAMPLE 1: ServiceBase.new() to ModernServiceFramework
-- ========================================

--[[
BEFORE - Legacy ServiceBase Pattern:
```luau
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local SafeRequire = require(ReplicatedStorage.Shared.utils.SafeRequire)
local ServiceBase = SafeRequire.require(ReplicatedStorage.Shared.utils.ServiceBase)

local ExampleService = ServiceBase.new("ExampleService", {
    enableDetailedLogging = true,
    retryFailedRequires = true,
    maxRetryAttempts = 3
})

-- Manual dependency management
local RemoteEvents = SafeRequire.require(ReplicatedStorage.Shared.modules.RemoteEvents)
local DataService = SafeRequire.require(script.Parent.DataService, "DataService", true)
local PlayerService = SafeRequire.require(script.Parent.PlayerService)

function ExampleService:Init()
    print("Initializing ExampleService...")
    self:SetupEventConnections()
end

function ExampleService:Start()
    print("Starting ExampleService...")
    self:BeginOperations()
end
```

AFTER - Modern ServiceFramework Pattern:
]]

-- Modern ExampleService using ModernServiceFramework
local ExampleService = ModernServiceFramework.CreateService("ExampleService", {
    -- Explicit dependency declaration
    Dependencies = {"PlayerService", "RemoteEvents"},
    OptionalDependencies = {"DataService", "AnalyticsService"},
    Priority = 30, -- Medium priority
    Testable = true,
    
    -- Built-in error boundary
    ErrorBoundary = function(errorInfo)
        if errorInfo.type == "PlayerError" then
            warn("🛡️ ExampleService: Player-related error handled gracefully:", errorInfo.message)
            return true -- Error handled, continue operation
        end
        return false -- Let framework handle other errors
    end
})

-- Dependencies are automatically injected - no manual SafeRequire needed!
function ExampleService:Initialize()
    -- Access injected dependencies
    self.playerService = self:GetDependency("PlayerService")
    self.remoteEvents = self:GetDependency("RemoteEvents")
    self.dataService = self:GetDependency("DataService") -- May be nil (optional)
    self.analytics = self:GetDependency("AnalyticsService") -- May be nil (optional)
    
    print("🔧 Initializing ExampleService...")
    
    -- Setup with automatic connection management
    self:CreateConnectionGroup("playerEvents")
    self:SetupEventConnections()
    
    print("✅ ExampleService initialized successfully")
end

function ExampleService:Start()
    print("▶️ Starting ExampleService...")
    self:BeginOperations()
end

function ExampleService:SetupEventConnections()
    -- Managed connections that auto-cleanup
    self:AddConnection("playerAdded",
        self.remoteEvents.PlayerJoined.OnServerEvent:Connect(function(player)
            self:OnPlayerJoined(player)
        end),
        "playerEvents"
    )
end

function ExampleService:OnPlayerJoined(player)
    -- Use TrackOperation for automatic error handling and metrics
    local success, result = self:TrackOperation("ProcessPlayerJoin", function()
        if self.playerService then
            return self.playerService:InitializePlayer(player)
        end
        return true
    end)
    
    if success then
        print("✅ Player joined successfully:", player.Name)
    else
        warn("❌ Failed to process player join:", result)
    end
end

-- ========================================
-- EXAMPLE 2: Services.Register() to ModernServiceFramework
-- ========================================

--[[
BEFORE - Services.Register Pattern:
```luau
local SocialService = {}

function SocialService:Initialize()
    -- Manual setup
end

-- At end of file:
Services.Register("SocialService", SocialService)
```

AFTER - Modern Registration:
]]

-- Create the service with the modern framework
local ModernSocialService = ModernServiceFramework.CreateService("SocialService", {
    Dependencies = {"PlayerService", "DataService"},
    Priority = 40
})

function ModernSocialService:Initialize()
    self.playerService = self:GetDependency("PlayerService")
    self.dataService = self:GetDependency("DataService")
    
    print("🤝 Initializing SocialService...")
    print("✅ SocialService ready")
end

-- Modern registration (replaces Services.Register)
-- This is typically done in a centralized startup script:
-- ModernServiceFramework.RegisterService("SocialService", ModernSocialService)

-- ========================================
-- EXAMPLE 3: _G.GetService() Elimination
-- ========================================

--[[
BEFORE - Deprecated _G Pattern:
```luau
local CleanupService = {}

function CleanupService:CleanupPlayer(player)
    local playerService = _G.GetService("PlayerService")  -- ❌ Deprecated
    local dataService = _G.GetService("DataService")      -- ❌ Deprecated
    
    if playerService then
        playerService:RemovePlayer(player)
    end
    
    if dataService then
        dataService:SaveAndClearData(player)
    end
end
```

AFTER - Dependency Injection:
]]

local ModernCleanupService = ModernServiceFramework.CreateService("CleanupService", {
    Dependencies = {"PlayerService"}, -- Required
    OptionalDependencies = {"DataService", "AnalyticsService"}, -- Optional
    Priority = 95 -- Low priority (cleanup happens last)
})

function ModernCleanupService:Initialize()
    -- Dependencies automatically injected
    self.playerService = self:GetDependency("PlayerService")
    self.dataService = self:GetDependency("DataService") -- May be nil
    self.analytics = self:GetDependency("AnalyticsService") -- May be nil
    
    print("🧹 Initializing CleanupService...")
    print("✅ CleanupService ready")
end

function ModernCleanupService:CleanupPlayer(player)
    -- Use TrackOperation for error handling and metrics
    local success, result = self:TrackOperation("CleanupPlayer", function()
        -- Required service (guaranteed to exist)
        self.playerService:RemovePlayer(player)
        
        -- Optional services (check before use)
        if self.dataService then
            self.dataService:SaveAndClearData(player)
        end
        
        if self.analytics then
            self.analytics:TrackPlayerExit(player)
        end
        
        return true
    end)
    
    if success then
        print("✅ Player cleanup completed:", player.Name)
    else
        self:HandleError("Failed to cleanup player: " .. result, false)
    end
end

-- ========================================
-- EXAMPLE 4: Complex Service with Multiple Patterns
-- ========================================

--[[
BEFORE - Mixed Patterns (Complex):
```luau
local BuffService = ServiceBase.new("BuffService", {
    enableDetailedLogging = true
})

-- Mixed dependency management
local PlayerService = SafeRequire.require(script.Parent.PlayerService)
local DataService = _G.GetService("DataService")  -- ❌ Deprecated
local ShopService = SafeRequire.require(script.Parent.ShopService, "ShopService", true)

function BuffService:Init()
    self:SetupBuffTypes()
end

Services.Register("BuffService", BuffService)  -- Mixed registration
```

AFTER - Fully Modernized:
]]

local ModernBuffService = ModernServiceFramework.CreateService("BuffService", {
    Dependencies = {"PlayerService", "MainGameService"},
    OptionalDependencies = {"DataService", "ShopService", "AnalyticsService"},
    Priority = 25, -- High priority for gameplay-critical service
    Testable = true,
    
    -- Sophisticated error boundary
    ErrorBoundary = function(errorInfo)
        if errorInfo.type == "BuffError" then
            -- Handle buff-specific errors gracefully
            warn("🛡️ BuffService: Buff error handled:", errorInfo.message)
            return true
        elseif errorInfo.type == "PlayerError" then
            -- Handle player-related errors
            warn("🛡️ BuffService: Player error handled:", errorInfo.message)
            return true
        end
        return false -- Let framework handle other errors
    end
})

-- State management
local activeBuffs = {} -- [userId] = {[buffType] = buffData}

function ModernBuffService:Initialize()
    -- All dependencies automatically injected
    self.playerService = self:GetDependency("PlayerService")
    self.mainGame = self:GetDependency("MainGameService")
    self.dataService = self:GetDependency("DataService")
    self.shopService = self:GetDependency("ShopService")
    self.analytics = self:GetDependency("AnalyticsService")
    
    print("💰 Initializing BuffService...")
    
    -- Organized connection management
    self:CreateConnectionGroup("gameplayEvents")
    self:CreateConnectionGroup("playerEvents")
    
    self:SetupBuffTypes()
    self:SetupEventConnections()
    
    print("✅ BuffService initialized successfully")
end

function ModernBuffService:Start()
    print("▶️ Starting BuffService...")
    self:StartBuffUpdates()
end

function ModernBuffService:SetupBuffTypes()
    -- Define buff configurations
    self.buffTypes = {
        coinMagnet = {
            name = "💰 Coin Magnet",
            duration = 30,
            price = 150
        },
        doubleJump = {
            name = "🦘 Double Jump", 
            duration = 45,
            price = 200
        }
    }
end

function ModernBuffService:SetupEventConnections()
    -- Track all connections for proper cleanup
    if self.mainGame then
        self:AddConnection("gameStateChanged",
            self.mainGame.Events.GameStateChanged:Connect(function(newState)
                self:OnGameStateChanged(newState)
            end),
            "gameplayEvents"
        )
    end
    
    if self.playerService then
        self:AddConnection("playerLeft",
            self.playerService.Events.PlayerLeft:Connect(function(player)
                self:CleanupPlayerBuffs(player)
            end),
            "playerEvents"
        )
    end
end

function ModernBuffService:ApplyBuff(player, buffType)
    return self:TrackOperation("ApplyBuff", function()
        local userId = player.UserId
        
        if not activeBuffs[userId] then
            activeBuffs[userId] = {}
        end
        
        local buffConfig = self.buffTypes[buffType]
        if not buffConfig then
            error("Unknown buff type: " .. buffType)
        end
        
        -- Apply the buff
        activeBuffs[userId][buffType] = {
            startTime = os.time(),
            duration = buffConfig.duration,
            config = buffConfig
        }
        
        -- Analytics tracking (optional)
        if self.analytics then
            self.analytics:TrackEvent("BuffApplied", {
                userId = userId,
                buffType = buffType,
                duration = buffConfig.duration
            })
        end
        
        print(string.format("✨ Applied %s to %s", buffConfig.name, player.Name))
        return true
    end)
end

function ModernBuffService:CleanupPlayerBuffs(player)
    local userId = player.UserId
    if activeBuffs[userId] then
        activeBuffs[userId] = nil
        print("🧹 Cleaned up buffs for", player.Name)
    end
end

function ModernBuffService:Stop()
    print("⏹️ Stopping BuffService...")
    
    -- Graceful shutdown
    self:DisconnectGroup("gameplayEvents")
    self:DisconnectGroup("playerEvents")
    
    -- Save any important data
    if self.dataService then
        for userId, buffs in pairs(activeBuffs) do
            -- Save active buffs to restore later
            self.dataService:SavePlayerBuffs(userId, buffs)
        end
    end
end

-- ========================================
-- CONVERSION CHECKLIST AND BENEFITS
-- ========================================

function ExampleServiceConversions:GetConversionChecklist()
    return {
        before = {
            "❌ ServiceBase.new() pattern",
            "❌ Manual SafeRequire dependency management", 
            "❌ _G.GetService() calls",
            "❌ Services.Register() for registration",
            "❌ Manual error handling",
            "❌ No connection management",
            "❌ Difficult to test"
        },
        
        after = {
            "✅ ModernServiceFramework.CreateService() pattern",
            "✅ Automatic dependency injection",
            "✅ Dependency declarations in config",
            "✅ Built-in error boundaries",
            "✅ Automatic connection cleanup",
            "✅ Performance tracking and metrics",
            "✅ Built-in testing support",
            "✅ Lifecycle management (Initialize/Start/Stop)",
            "✅ Service health monitoring",
            "✅ Priority-based initialization"
        },
        
        benefits = {
            "🔧 Reduced boilerplate code by ~60%",
            "🛡️ Built-in error isolation and recovery",
            "⚡ Faster development with dependency injection",
            "🧪 Easier testing with mocking support", 
            "📊 Automatic performance monitoring",
            "🔄 Consistent lifecycle management",
            "🧹 Automatic memory cleanup",
            "📈 Better code maintainability"
        }
    }
end

function ExampleServiceConversions:PrintConversionSummary()
    local checklist = self:GetConversionChecklist()
    
    print("🔄 SERVICE ARCHITECTURE CONVERSION SUMMARY")
    print("=" .. string.rep("=", 50))
    
    print("\n❌ ELIMINATED PATTERNS:")
    for _, item in ipairs(checklist.before) do
        print("   " .. item)
    end
    
    print("\n✅ NEW MODERN ARCHITECTURE:")
    for _, item in ipairs(checklist.after) do
        print("   " .. item)
    end
    
    print("\n🎯 KEY BENEFITS ACHIEVED:")
    for _, benefit in ipairs(checklist.benefits) do
        print("   " .. benefit)
    end
    
    print("\n🚀 READY FOR PRODUCTION!")
end

return ExampleServiceConversions
