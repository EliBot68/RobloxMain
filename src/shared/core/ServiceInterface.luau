-- ServiceInterface.luau
-- Service interface definitions and contracts for dependency injection
-- Defines standard interfaces that all services should implement

local ServiceInterface = {}

-- ========================================
-- BASE SERVICE INTERFACE
-- ========================================

ServiceInterface.IService = {
    Initialize = "function", -- Initialize service with dependencies
    Start = "function",      -- Start service operations
    Stop = "function",       -- Stop service and cleanup resources
    GetName = "function",    -- Get service name
    GetStatus = "function"   -- Get service status/health
}

-- ========================================
-- CORE GAME SERVICE INTERFACES
-- ========================================

ServiceInterface.IGameService = {
    Initialize = "function",
    Start = "function",
    Stop = "function",
    GetName = "function",
    GetStatus = "function",
    
    -- Game-specific methods
    StartGame = "function",
    EndGame = "function",
    GetGameState = "function",
    UpdateGameState = "function"
}

ServiceInterface.IAnalyticsService = {
    Initialize = "function",
    Start = "function", 
    Stop = "function",
    GetName = "function",
    GetStatus = "function",
    
    -- Analytics-specific methods
    LogEvent = "function",
    LogPlayerAction = "function",
    GetPlayerStats = "function",
    FlushEvents = "function"
}

ServiceInterface.IDataService = {
    Initialize = "function",
    Start = "function",
    Stop = "function", 
    GetName = "function",
    GetStatus = "function",
    
    -- Data-specific methods
    SavePlayerData = "function",
    LoadPlayerData = "function",
    GetPlayerData = "function",
    UpdatePlayerData = "function"
}

ServiceInterface.IMemoryManager = {
    Initialize = "function",
    Start = "function",
    Stop = "function",
    GetName = "function", 
    GetStatus = "function",
    
    -- Memory management methods
    RegisterConnection = "function",
    DisconnectConnection = "function",
    RegisterTween = "function",
    CleanupTween = "function",
    CleanupPlayer = "function",
    GetMemoryStats = "function"
}

-- ========================================
-- CLIENT CONTROLLER INTERFACES
-- ========================================

ServiceInterface.IController = {
    Initialize = "function",
    Start = "function",
    Stop = "function",
    GetName = "function",
    GetStatus = "function",
    
    -- Controller-specific methods
    HandleInput = "function",
    UpdateUI = "function"
}

ServiceInterface.IGameController = {
    Initialize = "function",
    Start = "function", 
    Stop = "function",
    GetName = "function",
    GetStatus = "function",
    
    -- Game controller methods
    HandleInput = "function",
    UpdateUI = "function",
    OnGameStart = "function",
    OnGameEnd = "function"
}

-- ========================================
-- SPECIALIZED SERVICE INTERFACES
-- ========================================

ServiceInterface.ITrackGeneratorService = {
    Initialize = "function",
    Start = "function",
    Stop = "function",
    GetName = "function",
    GetStatus = "function",
    
    -- Track generation methods
    GenerateTrack = "function",
    GetTrackConfiguration = "function",
    ValidateTrack = "function"
}

ServiceInterface.IDifficultyService = {
    Initialize = "function",
    Start = "function",
    Stop = "function",
    GetName = "function", 
    GetStatus = "function",
    
    -- Difficulty management methods
    GetCurrentDifficulty = "function",
    UpdateDifficulty = "function",
    CalculateDifficultyLevel = "function"
}

ServiceInterface.IMonetizationService = {
    Initialize = "function",
    Start = "function",
    Stop = "function",
    GetName = "function",
    GetStatus = "function",
    
    -- Monetization methods
    ProcessPurchase = "function",
    ValidateGamepass = "function",
    GetPlayerPurchases = "function"
}

-- ========================================
-- UTILITY SERVICE INTERFACES  
-- ========================================

ServiceInterface.INotificationService = {
    Initialize = "function",
    Start = "function",
    Stop = "function",
    GetName = "function",
    GetStatus = "function",
    
    -- Notification methods
    ShowNotification = "function",
    HideNotification = "function",
    ClearAllNotifications = "function"
}

ServiceInterface.IUIService = {
    Initialize = "function", 
    Start = "function",
    Stop = "function",
    GetName = "function",
    GetStatus = "function",
    
    -- UI management methods
    CreateUI = "function",
    DestroyUI = "function", 
    UpdateUI = "function",
    GetUIElement = "function"
}

-- ========================================
-- INTERFACE VALIDATION UTILITIES
-- ========================================

function ServiceInterface.ValidateImplementation(implementation, interface)
    local errors = {}
    
    for methodName, expectedType in pairs(interface) do
        if not implementation[methodName] then
            table.insert(errors, "Missing required method: " .. methodName)
        elseif type(implementation[methodName]) ~= expectedType then
            table.insert(errors, "Method '" .. methodName .. "' should be " .. expectedType .. " but is " .. type(implementation[methodName]))
        end
    end
    
    return #errors == 0, errors
end

function ServiceInterface.GetRequiredMethods(interface)
    local methods = {}
    for methodName, _ in pairs(interface) do
        table.insert(methods, methodName)
    end
    return methods
end

function ServiceInterface.CreateProxy(target, interface)
    local proxy = {}
    
    -- Only expose methods defined in the interface
    for methodName, _ in pairs(interface) do
        if target[methodName] then
            proxy[methodName] = function(...)
                return target[methodName](...)
            end
        end
    end
    
    return proxy
end

-- ========================================
-- SERVICE CONTRACT DEFINITIONS
-- ========================================

ServiceInterface.ServiceContracts = {
    -- Core services that must always be available
    REQUIRED_SERVICES = {
        "GameService",
        "AnalyticsService", 
        "DataService",
        "MemoryManager"
    },
    
    -- Services that can be optional depending on context
    OPTIONAL_SERVICES = {
        "TrackGeneratorService",
        "DifficultyService",
        "MonetizationService",
        "NotificationService"
    },
    
    -- Client-only services
    CLIENT_SERVICES = {
        "GameController",
        "UIController", 
        "InputController",
        "NotificationController"
    },
    
    -- Server-only services
    SERVER_SERVICES = {
        "AntiCheatService",
        "TeleportService",
        "PartyService",
        "LeaderboardService"
    }
}

-- ========================================
-- INTERFACE BUILDER UTILITIES
-- ========================================

function ServiceInterface.CreateInterface(name, methods)
    local interface = {}
    
    for _, methodName in ipairs(methods) do
        interface[methodName] = "function"
    end
    
    ServiceInterface[name] = interface
    return interface
end

function ServiceInterface.ExtendInterface(baseInterface, additionalMethods)
    local extendedInterface = {}
    
    -- Copy base interface methods
    for methodName, methodType in pairs(baseInterface) do
        extendedInterface[methodName] = methodType
    end
    
    -- Add additional methods
    for methodName, methodType in pairs(additionalMethods) do
        extendedInterface[methodName] = methodType
    end
    
    return extendedInterface
end

function ServiceInterface.GetAllInterfaces()
    local interfaces = {}
    
    for key, value in pairs(ServiceInterface) do
        if type(value) == "table" and key:sub(1, 1) == "I" then
            interfaces[key] = value
        end
    end
    
    return interfaces
end

return ServiceInterface
