-- Services.luau
-- Simplified service accessor for Rojo compatibility
-- This module provides safe access to services without requiring cross-boundary dependencies

local RunService = game:GetService("RunService")
local ServerScriptService = game:GetService("ServerScriptService")

local Services = {}
local _serviceCache = {}

-- Safe require function
local function safeRequire(module)
    local success, result = pcall(require, module)
    if success then
        return result
    else
        warn("Services: Failed to require " .. tostring(module) .. ": " .. tostring(result))
        return nil
    end
end

-- Generic service getter that works at runtime
function Services:GetService(serviceName)
    -- Check cache first
    if _serviceCache[serviceName] then
        return _serviceCache[serviceName]
    end
    
    -- Only load services on the server
    if not RunService:IsServer() then
        warn("Services: Cannot access server services from client")
        return nil
    end
    
    -- Try to find and load the service
    local serverFolder = ServerScriptService:FindFirstChild("Server")
    if not serverFolder then
        warn("Services: Server folder not found in ServerScriptService")
        return nil
    end
    
    -- Check services folder first
    local servicesFolder = serverFolder:FindFirstChild("services")
    if servicesFolder then
        local serviceModule = servicesFolder:FindFirstChild(serviceName)
        if serviceModule then
            local service = safeRequire(serviceModule)
            if service then
                _serviceCache[serviceName] = service
                return service
            end
        end
    end
    
    -- Check controllers folder
    local controllersFolder = serverFolder:FindFirstChild("controllers")
    if controllersFolder then
        local controllerModule = controllersFolder:FindFirstChild(serviceName)
        if controllerModule then
            local controller = safeRequire(controllerModule)
            if controller then
                _serviceCache[serviceName] = controller
                return controller
            end
        end
    end
    
    warn("Services: Service " .. serviceName .. " not found")
    return nil
end

-- Alias for backward compatibility
function Services.Get(serviceName)
    return Services:GetService(serviceName)
end

-- Backward compatibility getters
function Services.MainGameService()
    return Services:GetService("MainGameService")
end

function Services.TrackGeneratorService()
    return Services:GetService("TrackGeneratorService")
end

function Services.MovingObstacleService()
    return Services:GetService("MovingObstacleService")
end

function Services.CollisionController()
    return Services:GetService("CollisionController")
end

function Services.DifficultyService()
    return Services:GetService("DifficultyService")
end

function Services.PlayerService()
    return Services:GetService("PlayerService")
end

function Services.DataService()
    return Services:GetService("DataService")
end

function Services.PerformanceService()
    return Services:GetService("PerformanceService")
end

function Services.AnalyticsService()
    return Services:GetService("AnalyticsService")
end

-- Initialize function for backward compatibility
function Services.Initialize()
    -- Nothing needed for initialization in this simplified version
    return true
end

-- Register function for backward compatibility
function Services.Register(serviceName, serviceInstance)
    if serviceName and serviceInstance then
        _serviceCache[serviceName] = serviceInstance
        return true
    end
    return false
end

return Services
