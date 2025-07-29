-- ConfigurationManager.luau
-- Centralized configuration management system with environment awareness
-- Eliminates magic numbers and scattered constants throughout the codebase

local ConfigurationManager = {}
ConfigurationManager.__index = ConfigurationManager

local RunService = game:GetService("RunService")
local HttpService = game:GetService("HttpService")

-- ========================================
-- CORE CONFIGURATION INFRASTRUCTURE
-- ========================================

local instance = nil
local configurationCache = {}
local configurationValidators = {}
local configurationWatchers = {}
local environmentCache = nil

-- Environment detection
local ENVIRONMENTS = {
    DEVELOPMENT = "development",
    STAGING = "staging", 
    PRODUCTION = "production"
}

-- Configuration change events
local configurationChanged = Instance.new("BindableEvent")

-- ========================================
-- SINGLETON PATTERN
-- ========================================

function ConfigurationManager.getInstance()
    if not instance then
        instance = setmetatable({}, ConfigurationManager)
        instance:_initialize()
    end
    return instance
end

function ConfigurationManager:_initialize()
    self.environment = self:_detectEnvironment()
    self.configSources = {}
    self.loadedConfigs = {}
    self.validationErrors = {}
    
    print("🔧 ConfigurationManager initialized for environment: " .. self.environment)
    
    -- Load base configurations
    self:_loadBaseConfigurations()
    self:_validateAllConfigurations()
end

-- ========================================
-- ENVIRONMENT MANAGEMENT
-- ========================================

function ConfigurationManager:_detectEnvironment()
    if environmentCache then
        return environmentCache
    end
    
    -- Check for environment variables or game settings
    local env = ENVIRONMENTS.PRODUCTION -- Default to production
    
    if RunService:IsStudio() then
        env = ENVIRONMENTS.DEVELOPMENT
    elseif game.PlaceId == 0 then
        env = ENVIRONMENTS.DEVELOPMENT
    elseif game:GetService("MarketplaceService"):GetProductInfo(game.PlaceId).Name:find("Test") then
        env = ENVIRONMENTS.STAGING
    end
    
    environmentCache = env
    return env
end

function ConfigurationManager:GetEnvironment()
    return self.environment
end

function ConfigurationManager:IsProduction()
    return self.environment == ENVIRONMENTS.PRODUCTION
end

function ConfigurationManager:IsDevelopment()
    return self.environment == ENVIRONMENTS.DEVELOPMENT
end

function ConfigurationManager:IsStaging()
    return self.environment == ENVIRONMENTS.STAGING
end

-- ========================================
-- CONFIGURATION LOADING
-- ========================================

function ConfigurationManager:_loadBaseConfigurations()
    -- Load all configuration modules
    self:_loadGameplayConfig()
    self:_loadUIConfig()
    self:_loadPerformanceConfig()
    self:_loadNetworkingConfig()
    self:_loadAnalyticsConfig()
    self:_loadSecurityConfig()
    self:_loadAssetsConfig()
    self:_loadMemoryConfig()
    self:_loadDebugConfig()
end

-- ========================================
-- GAMEPLAY CONFIGURATION
-- ========================================

function ConfigurationManager:_loadGameplayConfig()
    local baseConfig = {
        -- Game Session Settings
        SESSION_TIMEOUT = {
            development = 300,    -- 5 minutes
            staging = 600,        -- 10 minutes
            production = 1800     -- 30 minutes
        },
        
        -- Player Limits and Thresholds
        PLAYER_LIMITS = {
            MAX_PLAYERS_PER_SERVER = {
                development = 6,
                staging = 12,
                production = 24
            },
            MAX_RESPAWN_TIME = 5.0,
            MIN_RESPAWN_TIME = 1.0,
            DEFAULT_RESPAWN_TIME = 3.0
        },
        
        -- Difficulty System
        DIFFICULTY = {
            BASE_SPEED = 16,
            SPEED_INCREMENT = 1.5,
            MAX_SPEED = 50,
            DIFFICULTY_RAMP_TIME = 30.0,
            OBSTACLE_SPAWN_RATE = {
                EASY = 0.8,
                MEDIUM = 1.2,
                HARD = 1.8
            }
        },
        
        -- Scoring System
        SCORING = {
            BASE_POINTS_PER_SECOND = 10,
            DISTANCE_MULTIPLIER = 1.5,
            PERFECT_RUN_BONUS = 500,
            STREAK_MULTIPLIER = 1.2,
            MAX_STREAK_MULTIPLIER = 3.0
        },
        
        -- Power-ups and Items
        POWERUPS = {
            SPEED_BOOST = {
                DURATION = 8.0,
                MULTIPLIER = 1.5,
                COOLDOWN = 20.0
            },
            SHIELD = {
                DURATION = 12.0,
                COOLDOWN = 30.0
            },
            DOUBLE_POINTS = {
                DURATION = 15.0,
                MULTIPLIER = 2.0,
                COOLDOWN = 45.0
            }
        }
    }
    
    self:RegisterConfiguration("gameplay", baseConfig)
end

-- ========================================
-- UI CONFIGURATION
-- ========================================

function ConfigurationManager:_loadUIConfig()
    local baseConfig = {
        -- Screen Dimensions and Scaling
        SCREEN = {
            REFERENCE_RESOLUTION = {
                WIDTH = 1920,
                HEIGHT = 1080
            },
            MIN_MOBILE_WIDTH = 360,
            UI_SCALE_FACTOR = {
                development = 1.2,
                staging = 1.0,
                production = 1.0
            }
        },
        
        -- Animation Timings
        ANIMATIONS = {
            FADE_IN_TIME = 0.3,
            FADE_OUT_TIME = 0.25,
            SLIDE_ANIMATION_TIME = 0.4,
            BUTTON_PRESS_TIME = 0.1,
            NOTIFICATION_DURATION = 3.0,
            LOADING_SPINNER_SPEED = 1.5
        },
        
        -- UI Element Sizes
        ELEMENTS = {
            BUTTON_HEIGHT = 50,
            BUTTON_WIDTH = 200,
            ICON_SIZE = 32,
            LARGE_ICON_SIZE = 64,
            PADDING = {
                SMALL = 8,
                MEDIUM = 16,
                LARGE = 24,
                EXTRA_LARGE = 32
            }
        },
        
        -- Colors and Themes
        COLORS = {
            PRIMARY = Color3.fromRGB(66, 165, 245),
            SECONDARY = Color3.fromRGB(26, 35, 126),
            SUCCESS = Color3.fromRGB(76, 175, 80),
            WARNING = Color3.fromRGB(255, 193, 7),
            ERROR = Color3.fromRGB(244, 67, 54),
            BACKGROUND = Color3.fromRGB(33, 33, 33),
            TEXT = Color3.fromRGB(255, 255, 255)
        },
        
        -- Mobile-specific settings
        MOBILE = {
            TOUCH_SENSITIVITY = 1.2,
            BUTTON_SIZE_MULTIPLIER = 1.3,
            FONT_SIZE_MULTIPLIER = 1.1
        }
    }
    
    self:RegisterConfiguration("ui", baseConfig)
end

-- ========================================
-- PERFORMANCE CONFIGURATION
-- ========================================

function ConfigurationManager:_loadPerformanceConfig()
    local baseConfig = {
        -- Frame Rate and Rendering
        RENDERING = {
            TARGET_FPS = {
                development = 60,
                staging = 60,
                production = 60
            },
            MAX_RENDER_DISTANCE = 1000,
            LOD_DISTANCES = {
                HIGH = 100,
                MEDIUM = 300,
                LOW = 600
            }
        },
        
        -- Memory Management
        MEMORY = {
            GARBAGE_COLLECTION_INTERVAL = 30.0,
            MAX_CACHED_OBJECTS = 100,
            TEXTURE_MEMORY_LIMIT = 512, -- MB
            AUTO_CLEANUP_THRESHOLD = 0.8, -- 80% memory usage
            
            -- Object Pool Settings
            OBJECT_POOLS = {
                DEFAULT_INITIAL_SIZE = 10,
                MAX_POOL_SIZE = 100,
                TRIM_THRESHOLD = 0.7, -- Trim when 70% full
                TRIM_RATIO = 0.5 -- Remove 50% when trimming
            },
            
            -- Resource Limits
            LIMITS = {
                MAX_CONNECTIONS_PER_PLAYER = 50,
                MAX_TWEENS_PER_PLAYER = 25,
                MAX_TASKS_PER_PLAYER = 20,
                MAX_GAME_OBJECTS_PER_PLAYER = 100
            },
            
            -- Memory Pressure Monitoring
            MONITORING = {
                PRESSURE_CHECK_INTERVAL = 5.0, -- Check every 5 seconds
                DEFAULT_EVENT_INTERVAL = 1.0, -- Event-driven monitoring interval
                ENABLE_ADAPTIVE_CLEANUP = true
            },
            
            -- Memory Pressure Thresholds (in KB)
            PRESSURE_THRESHOLDS = {
                LOW_MEMORY_KB = 50 * 1024, -- 50 MB
                MEDIUM_MEMORY_KB = 100 * 1024, -- 100 MB
                HIGH_MEMORY_KB = 200 * 1024, -- 200 MB
                CRITICAL_MEMORY_KB = 400 * 1024, -- 400 MB
                HIGH_GROWTH_RATE_KB_PER_SEC = 1024 -- 1 MB/sec growth rate threshold
            },
            
            -- Cleanup Thresholds (in seconds)
            CLEANUP_THRESHOLDS = {
                LIGHT_CONNECTION_AGE_SECONDS = 300, -- 5 minutes
                LIGHT_TWEEN_AGE_SECONDS = 120, -- 2 minutes
                LIGHT_TASK_AGE_SECONDS = 180, -- 3 minutes
                
                MODERATE_CONNECTION_AGE_SECONDS = 180, -- 3 minutes
                MODERATE_TWEEN_AGE_SECONDS = 60, -- 1 minute
                MODERATE_TASK_AGE_SECONDS = 90, -- 1.5 minutes
                
                AGGRESSIVE_CONNECTION_AGE_SECONDS = 60, -- 1 minute
                AGGRESSIVE_TWEEN_AGE_SECONDS = 30, -- 30 seconds
                AGGRESSIVE_TASK_AGE_SECONDS = 45 -- 45 seconds
            },
            
            -- Batch Processing
            BATCH_PROCESSING = {
                DEFAULT_BATCH_SIZE = 10,
                MAX_BATCH_SIZE = 50,
                BATCH_TIMEOUT = 1.0 -- Process batch after 1 second
            },
            
            -- Tracking and Logging
            TRACKING = {
                ENABLE_DETAILED_LOGGING = {
                    development = true,
                    staging = true,
                    production = false
                },
                ENABLE_PERFORMANCE_MONITORING = {
                    development = true,
                    staging = true,
                    production = true
                },
                AUTO_CLEANUP_INTERVAL = {
                    development = 60.0, -- 1 minute
                    staging = 300.0, -- 5 minutes
                    production = 600.0 -- 10 minutes
                }
            }
        },
        
        -- Network Optimization
        NETWORK = {
            MAX_CONCURRENT_REQUESTS = 5,
            REQUEST_TIMEOUT = 10.0,
            RETRY_ATTEMPTS = 3,
            BATCH_SIZE = 20
        },
        
        -- Physics Settings
        PHYSICS = {
            SIMULATION_RADIUS = 500,
            MAX_PHYSICS_OBJECTS = 200,
            COLLISION_CHECK_INTERVAL = 0.1
        }
    }
    
    self:RegisterConfiguration("performance", baseConfig)
end

-- ========================================
-- NETWORKING CONFIGURATION
-- ========================================

function ConfigurationManager:_loadNetworkingConfig()
    local baseConfig = {
        -- API Endpoints
        ENDPOINTS = {
            BASE_URL = {
                development = "https://dev-api.example.com",
                staging = "https://staging-api.example.com", 
                production = "https://api.example.com"
            },
            ANALYTICS_URL = {
                development = "https://dev-analytics.example.com",
                staging = "https://staging-analytics.example.com",
                production = "https://analytics.example.com"
            }
        },
        
        -- Request Settings
        REQUESTS = {
            DEFAULT_TIMEOUT = 30.0,
            LONG_TIMEOUT = 60.0,
            SHORT_TIMEOUT = 5.0,
            MAX_RETRIES = 3,
            RETRY_DELAY = 1.0
        },
        
        -- DataStore Settings
        DATASTORE = {
            REQUEST_BUDGET_CHECK_INTERVAL = 1.0,
            MAX_REQUESTS_PER_MINUTE = 60,
            BATCH_SIZE = 20,
            ERROR_RETRY_DELAY = 5.0
        }
    }
    
    self:RegisterConfiguration("networking", baseConfig)
end

-- ========================================
-- ANALYTICS CONFIGURATION
-- ========================================

function ConfigurationManager:_loadAnalyticsConfig()
    local baseConfig = {
        -- Event Tracking
        EVENTS = {
            BATCH_SIZE = 50,
            FLUSH_INTERVAL = 30.0,
            MAX_QUEUE_SIZE = 500,
            RETRY_FAILED_EVENTS = true
        },
        
        -- Metrics Collection
        METRICS = {
            COLLECTION_INTERVAL = 10.0,
            PERFORMANCE_SAMPLING_RATE = {
                development = 1.0,    -- 100% sampling
                staging = 0.5,        -- 50% sampling  
                production = 0.1      -- 10% sampling
            }
        },
        
        -- Privacy Settings
        PRIVACY = {
            COLLECT_USER_AGENT = false,
            ANONYMIZE_IP = true,
            DATA_RETENTION_DAYS = 365
        }
    }
    
    self:RegisterConfiguration("analytics", baseConfig)
end

-- ========================================
-- SECURITY CONFIGURATION
-- ========================================

function ConfigurationManager:_loadSecurityConfig()
    local baseConfig = {
        -- Input Validation
        VALIDATION = {
            MAX_USERNAME_LENGTH = 20,
            MAX_MESSAGE_LENGTH = 200,
            ALLOWED_CHARACTERS = "[%w%s%p]",
            RATE_LIMIT_REQUESTS = 10,
            RATE_LIMIT_WINDOW = 60.0
        },
        
        -- Anti-Cheat Settings
        ANTICHEAT = {
            SPEED_CHECK_THRESHOLD = 1.5,
            POSITION_VALIDATION_INTERVAL = 0.5,
            MAX_TELEPORT_DISTANCE = 50,
            ENABLE_SERVER_VALIDATION = true
        },
        
        -- Data Protection
        DATA = {
            ENCRYPT_SENSITIVE_DATA = true,
            USE_SECURE_RANDOM = true,
            HASH_PLAYER_IDS = false
        }
    }
    
    self:RegisterConfiguration("security", baseConfig)
end

-- ========================================
-- ASSETS CONFIGURATION
-- ========================================

function ConfigurationManager:_loadAssetsConfig()
    local baseConfig = {
        -- Asset IDs (replace with actual IDs)
        SOUNDS = {
            BACKGROUND_MUSIC = 142376088,
            JUMP_SOUND = 131961136,
            COLLECT_SOUND = 142356113,
            DEATH_SOUND = 131961136,
            UI_CLICK = 421058925
        },
        
        -- Image Assets
        IMAGES = {
            LOGO = "rbxasset://textures/ui/TopBar/iconSort.png",
            LOADING_SPINNER = "rbxasset://textures/loading/robloxTilt.png",
            BUTTON_BACKGROUND = "rbxasset://textures/ui/common/roundrect_16_4.png"
        },
        
        -- 3D Models and Meshes
        MODELS = {
            PLAYER_CHARACTER = 0, -- Replace with actual model ID
            OBSTACLES = {
                BASIC_WALL = 0,
                MOVING_PLATFORM = 0,
                ROTATING_BLADE = 0
            }
        },
        
        -- Fonts
        FONTS = {
            PRIMARY = Enum.Font.GothamBold,
            SECONDARY = Enum.Font.Gotham,
            MONOSPACE = Enum.Font.Code
        },
        
        -- Obstacle Configuration
        OBSTACLES = {
            COLORS = {
                HORIZONTAL_SLIDER = Color3.fromRGB(255, 100, 100),
                VERTICAL_PENDULUM = Color3.fromRGB(255, 200, 100),
                CIRCULAR_SPINNER = Color3.fromRGB(100, 255, 100),
                ZIGZAG_MOVER = Color3.fromRGB(200, 100, 255),
                RANDOM_TELEPORTER = Color3.fromRGB(255, 150, 200)
            },
            SIZES = {
                SMALL = Vector3.new(2, 2, 2),
                MEDIUM = Vector3.new(4, 4, 4),
                LARGE = Vector3.new(6, 6, 6),
                WALL = Vector3.new(2, 8, 2),
                PLATFORM = Vector3.new(8, 2, 2),
                SPINNER = Vector3.new(3, 6, 3)
            },
            SPEEDS = {
                SLOW = 2,
                MEDIUM = 4,
                FAST = 8,
                VERY_FAST = 12
            },
            MOVEMENT_BOUNDS = {
                SMALL_RANGE = 10,
                MEDIUM_RANGE = 15,
                LARGE_RANGE = 20
            },
            CLEANUP_INTERVAL = {
                development = 20.0,
                staging = 30.0,
                production = 60.0
            }
        }
    }
    
    self:RegisterConfiguration("assets", baseConfig)
end

-- ========================================
-- MEMORY CONFIGURATION (Update existing MemoryManager config)
-- ========================================

function ConfigurationManager:_loadMemoryConfig()
    local baseConfig = {
        -- Memory Tracking
        TRACKING = {
            ENABLE_DETAILED_LOGGING = {
                development = true,
                staging = true,
                production = false
            },
            ENABLE_PERFORMANCE_MONITORING = true,
            AUTO_CLEANUP_INTERVAL = 60.0
        },
        
        -- Limits per Player
        LIMITS = {
            MAX_CONNECTIONS_PER_PLAYER = 100,
            MAX_TWEENS_PER_PLAYER = 50,
            MAX_TASKS_PER_PLAYER = 20,
            MAX_OBJECTS_PER_PLAYER = 200
        },
        
        -- Cleanup Settings
        CLEANUP = {
            FORCE_GC_INTERVAL = 300.0, -- 5 minutes
            MEMORY_WARNING_THRESHOLD = 0.8,
            EMERGENCY_CLEANUP_THRESHOLD = 0.9
        }
    }
    
    self:RegisterConfiguration("memory", baseConfig)
end

-- ========================================
-- DEBUG CONFIGURATION
-- ========================================

function ConfigurationManager:_loadDebugConfig()
    local baseConfig = {
        -- Logging Levels
        LOGGING = {
            LEVEL = {
                development = "DEBUG",
                staging = "INFO",
                production = "WARN"
            },
            ENABLE_CONSOLE_OUTPUT = {
                development = true,
                staging = true,
                production = false
            }
        },
        
        -- Debug Features
        FEATURES = {
            SHOW_FPS_COUNTER = {
                development = true,
                staging = false,
                production = false
            },
            ENABLE_DEBUG_GUI = {
                development = true,
                staging = false,
                production = false
            },
            ENABLE_PROFILING = {
                development = true,
                staging = true,
                production = false
            }
        }
    }
    
    self:RegisterConfiguration("debug", baseConfig)
end

-- ========================================
-- CONFIGURATION REGISTRATION AND VALIDATION
-- ========================================

function ConfigurationManager:RegisterConfiguration(configName, config)
    self.configSources[configName] = config
    
    -- Process environment-specific values
    local processedConfig = self:_processEnvironmentValues(config)
    self.loadedConfigs[configName] = processedConfig
    
    print("📝 Registered configuration: " .. configName)
end

function ConfigurationManager:_processEnvironmentValues(config)
    local processed = {}
    
    for key, value in pairs(config) do
        if type(value) == "table" then
            if value[self.environment] ~= nil then
                -- Environment-specific value
                processed[key] = value[self.environment]
            elseif value.development or value.staging or value.production then
                -- Skip environment objects, use default
                processed[key] = value[self.environment] or value.production or value.development
            else
                -- Nested table, process recursively
                processed[key] = self:_processEnvironmentValues(value)
            end
        else
            processed[key] = value
        end
    end
    
    return processed
end

-- ========================================
-- CONFIGURATION ACCESS
-- ========================================

function ConfigurationManager:Get(configPath)
    local parts = string.split(configPath, ".")
    local current = self.loadedConfigs
    
    for _, part in ipairs(parts) do
        if current[part] == nil then
            warn("Configuration path not found: " .. configPath)
            return nil
        end
        current = current[part]
    end
    
    return current
end

function ConfigurationManager:GetWithDefault(configPath, defaultValue)
    local value = self:Get(configPath)
    return value ~= nil and value or defaultValue
end

function ConfigurationManager:Set(configPath, value)
    local parts = string.split(configPath, ".")
    local current = self.loadedConfigs
    
    -- Navigate to parent
    for i = 1, #parts - 1 do
        local part = parts[i]
        if current[part] == nil then
            current[part] = {}
        end
        current = current[part]
    end
    
    -- Set the value
    local finalKey = parts[#parts]
    local oldValue = current[finalKey]
    current[finalKey] = value
    
    -- Trigger change event
    self:_triggerConfigChange(configPath, oldValue, value)
    
    print("🔄 Configuration updated: " .. configPath .. " = " .. tostring(value))
end

-- ========================================
-- CONFIGURATION WATCHING AND EVENTS
-- ========================================

function ConfigurationManager:Watch(configPath, callback)
    if not configurationWatchers[configPath] then
        configurationWatchers[configPath] = {}
    end
    
    table.insert(configurationWatchers[configPath], callback)
    
    print("👁️ Added watcher for configuration: " .. configPath)
end

function ConfigurationManager:_triggerConfigChange(configPath, oldValue, newValue)
    if configurationWatchers[configPath] then
        for _, callback in ipairs(configurationWatchers[configPath]) do
            pcall(callback, configPath, oldValue, newValue)
        end
    end
    
    -- Fire global change event
    configurationChanged:Fire(configPath, oldValue, newValue)
end

-- ========================================
-- CONFIGURATION VALIDATION
-- ========================================

function ConfigurationManager:RegisterValidator(configPath, validatorFunction)
    configurationValidators[configPath] = validatorFunction
    print("✅ Registered validator for: " .. configPath)
end

function ConfigurationManager:_validateAllConfigurations()
    self.validationErrors = {}
    
    for configPath, validator in pairs(configurationValidators) do
        local value = self:Get(configPath)
        local isValid, error = pcall(validator, value)
        
        if not isValid then
            table.insert(self.validationErrors, {
                path = configPath,
                error = error,
                value = value
            })
            warn("❌ Configuration validation failed for " .. configPath .. ": " .. tostring(error))
        end
    end
    
    return #self.validationErrors == 0
end

function ConfigurationManager:GetValidationErrors()
    return self.validationErrors
end

-- ========================================
-- CONFIGURATION EXPORT AND IMPORT
-- ========================================

function ConfigurationManager:ExportConfiguration(configName)
    if not self.loadedConfigs[configName] then
        return nil
    end
    
    return HttpService:JSONEncode(self.loadedConfigs[configName])
end

function ConfigurationManager:GetAllConfigurations()
    return self.loadedConfigs
end

function ConfigurationManager:PrintConfigurationSummary()
    print("📋 Configuration Manager Summary:")
    print("   Environment: " .. self.environment)
    print("   Loaded configurations: " .. tostring(#self.loadedConfigs))
    print("   Validation errors: " .. tostring(#self.validationErrors))
    
    for configName, _ in pairs(self.loadedConfigs) do
        print("     - " .. configName)
    end
end

-- ========================================
-- CONVENIENCE METHODS FOR COMMON CONFIGS
-- ========================================

-- Gameplay shortcuts
function ConfigurationManager:GetGameplayConfig()
    return self.loadedConfigs.gameplay
end

function ConfigurationManager:GetDifficultyConfig()
    return self.loadedConfigs.gameplay.DIFFICULTY
end

function ConfigurationManager:GetScoringConfig()
    return self.loadedConfigs.gameplay.SCORING
end

-- UI shortcuts
function ConfigurationManager:GetUIConfig()
    return self.loadedConfigs.ui
end

function ConfigurationManager:GetAnimationTimings()
    return self.loadedConfigs.ui.ANIMATIONS
end

function ConfigurationManager:GetUIColors()
    return self.loadedConfigs.ui.COLORS
end

-- Performance shortcuts
function ConfigurationManager:GetPerformanceConfig()
    return self.loadedConfigs.performance
end

function ConfigurationManager:GetMemoryConfig()
    return self.loadedConfigs.memory
end

-- Asset shortcuts
function ConfigurationManager:GetAssetConfig()
    return self.loadedConfigs.assets
end

function ConfigurationManager:GetSoundAssets()
    return self.loadedConfigs.assets.SOUNDS
end

-- ========================================
-- MODULE RETURN
-- ========================================

return ConfigurationManager
