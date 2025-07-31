-- ServiceSpecializationConfig.luau
-- Configuration for specialized service tiers
-- Defines which services to load based on server requirements

local ServiceSpecializationConfig = {
    -- Anti-Cheat Service Tiers
    antiCheat = {
        -- Basic tier (default)
        basic = {
            serviceName = "AntiCheatService",
            description = "Standard anti-cheat protection for general gameplay",
            performance = "Standard",
            features = {"Movement detection", "Speed detection", "Basic stat monitoring"},
            recommendedFor = {"Casual servers", "Development", "Standard gameplay"}
        },
        
        -- Advanced tier (optimized)
        advanced = {
            serviceName = "AntiCheatServiceAdvanced", 
            description = "High-performance anti-cheat with optimizations",
            performance = "Optimized",
            features = {"Batch processing", "Adaptive monitoring", "Event-driven detection", "Performance analytics"},
            recommendedFor = {"Competitive servers", "High-value environments", "Performance-critical situations"}
        }
    },
    
    -- Pet System Tiers
    petSystem = {
        -- Core functionality
        core = {
            serviceName = "PetService",
            description = "Core pet mechanics and data management", 
            scope = "Individual pet operations",
            features = {"Pet spawning", "Basic interactions", "Data persistence", "Simple pet logic"}
        },
        
        -- Orchestration layer
        orchestration = {
            serviceName = "PetOrchestrationService",
            description = "Coordinates multiple pet components and advanced features",
            scope = "System-wide coordination",
            features = {"Multi-pet management", "Complex interactions", "System coordination", "Advanced pet behaviors"}
        }
    },
    
    -- Service Loading Configuration
    loadingStrategy = {
        -- Default services to load
        defaults = {
            "AntiCheatService",      -- Basic anti-cheat
            "PetService"             -- Core pet functionality
        },
        
        -- Advanced services (load based on config)
        conditional = {
            {
                service = "AntiCheatServiceAdvanced",
                condition = "highPerformance",
                description = "Load for performance-critical environments"
            },
            {
                service = "PetOrchestrationService", 
                condition = "advancedPets",
                description = "Load for complex pet interactions"
            }
        }
    },
    
    -- Environment-based configurations
    environments = {
        development = {
            antiCheat = "basic",
            petSystem = {"core"},
            description = "Lightweight setup for development"
        },
        
        production = {
            antiCheat = "basic", 
            petSystem = {"core", "orchestration"},
            description = "Standard production setup"
        },
        
        competitive = {
            antiCheat = "advanced",
            petSystem = {"core", "orchestration"}, 
            description = "High-performance competitive setup"
        },
        
        vip = {
            antiCheat = "advanced",
            petSystem = {"core", "orchestration"},
            description = "Premium server configuration"
        }
    }
}

-- Helper function to get recommended services for an environment
function ServiceSpecializationConfig:GetServicesForEnvironment(environmentName)
    local env = self.environments[environmentName]
    if not env then
        warn("Unknown environment: " .. tostring(environmentName))
        return self.environments.development
    end
    
    local services = {}
    
    -- Add anti-cheat service
    if env.antiCheat == "basic" then
        table.insert(services, self.antiCheat.basic.serviceName)
    elseif env.antiCheat == "advanced" then
        table.insert(services, self.antiCheat.advanced.serviceName)
    end
    
    -- Add pet services
    for _, tier in ipairs(env.petSystem) do
        if tier == "core" then
            table.insert(services, self.petSystem.core.serviceName)
        elseif tier == "orchestration" then
            table.insert(services, self.petSystem.orchestration.serviceName)
        end
    end
    
    return services
end

-- Helper function to print service configuration
function ServiceSpecializationConfig:PrintConfiguration(environmentName)
    local env = self.environments[environmentName] or self.environments.development
    
    print("🎯 Service Configuration for: " .. (environmentName or "development"))
    print("   Description: " .. env.description)
    print("   Services:")
    
    local services = self:GetServicesForEnvironment(environmentName)
    for _, serviceName in ipairs(services) do
        print("     ✓ " .. serviceName)
    end
end

return ServiceSpecializationConfig
