-- ConfigurationValidators.luau
-- Validation schemas and functions for all game configurations
-- Ensures configuration integrity and catches invalid settings at startup

local ConfigurationValidators = {}

-- ========================================
-- VALIDATION HELPER FUNCTIONS
-- ========================================

local function validateNumber(value, min, max, name)
    if type(value) ~= "number" then
        error(name .. " must be a number, got " .. type(value))
    end
    
    if min and value < min then
        error(name .. " must be >= " .. min .. ", got " .. value)
    end
    
    if max and value > max then
        error(name .. " must be <= " .. max .. ", got " .. value)
    end
    
    return true
end

local function validateString(value, minLength, maxLength, pattern, name)
    if type(value) ~= "string" then
        error(name .. " must be a string, got " .. type(value))
    end
    
    if minLength and #value < minLength then
        error(name .. " must be at least " .. minLength .. " characters, got " .. #value)
    end
    
    if maxLength and #value > maxLength then
        error(name .. " must be at most " .. maxLength .. " characters, got " .. #value)
    end
    
    if pattern and not string.match(value, pattern) then
        error(name .. " does not match required pattern: " .. pattern)
    end
    
    return true
end

local function validateColor3(value, name)
    if typeof(value) ~= "Color3" then
        error(name .. " must be a Color3, got " .. typeof(value))
    end
    return true
end

local function validateEnum(value, validValues, name)
    for _, validValue in ipairs(validValues) do
        if value == validValue then
            return true
        end
    end
    
    error(name .. " must be one of: " .. table.concat(validValues, ", ") .. ", got " .. tostring(value))
end

-- ========================================
-- GAMEPLAY CONFIGURATION VALIDATORS
-- ========================================

function ConfigurationValidators.validateGameplayConfig(config)
    -- Session timeout validation
    validateNumber(config.SESSION_TIMEOUT, 60, 7200, "SESSION_TIMEOUT") -- 1 minute to 2 hours
    
    -- Player limits validation
    local playerLimits = config.PLAYER_LIMITS
    validateNumber(playerLimits.MAX_PLAYERS_PER_SERVER, 1, 50, "MAX_PLAYERS_PER_SERVER")
    validateNumber(playerLimits.MAX_RESPAWN_TIME, 0.1, 30, "MAX_RESPAWN_TIME")
    validateNumber(playerLimits.MIN_RESPAWN_TIME, 0.1, 10, "MIN_RESPAWN_TIME")
    validateNumber(playerLimits.DEFAULT_RESPAWN_TIME, 0.1, 10, "DEFAULT_RESPAWN_TIME")
    
    if playerLimits.MIN_RESPAWN_TIME > playerLimits.MAX_RESPAWN_TIME then
        error("MIN_RESPAWN_TIME cannot be greater than MAX_RESPAWN_TIME")
    end
    
    -- Difficulty system validation
    local difficulty = config.DIFFICULTY
    validateNumber(difficulty.BASE_SPEED, 1, 100, "BASE_SPEED")
    validateNumber(difficulty.SPEED_INCREMENT, 0.1, 10, "SPEED_INCREMENT")
    validateNumber(difficulty.MAX_SPEED, 10, 200, "MAX_SPEED")
    validateNumber(difficulty.DIFFICULTY_RAMP_TIME, 1, 300, "DIFFICULTY_RAMP_TIME")
    
    if difficulty.BASE_SPEED >= difficulty.MAX_SPEED then
        error("BASE_SPEED must be less than MAX_SPEED")
    end
    
    -- Obstacle spawn rates
    local spawnRates = difficulty.OBSTACLE_SPAWN_RATE
    validateNumber(spawnRates.EASY, 0.1, 5, "OBSTACLE_SPAWN_RATE.EASY")
    validateNumber(spawnRates.MEDIUM, 0.1, 5, "OBSTACLE_SPAWN_RATE.MEDIUM")
    validateNumber(spawnRates.HARD, 0.1, 5, "OBSTACLE_SPAWN_RATE.HARD")
    
    -- Scoring validation
    local scoring = config.SCORING
    validateNumber(scoring.BASE_POINTS_PER_SECOND, 1, 1000, "BASE_POINTS_PER_SECOND")
    validateNumber(scoring.DISTANCE_MULTIPLIER, 0.1, 10, "DISTANCE_MULTIPLIER")
    validateNumber(scoring.PERFECT_RUN_BONUS, 0, 10000, "PERFECT_RUN_BONUS")
    validateNumber(scoring.STREAK_MULTIPLIER, 1, 5, "STREAK_MULTIPLIER")
    validateNumber(scoring.MAX_STREAK_MULTIPLIER, 1, 10, "MAX_STREAK_MULTIPLIER")
    
    -- Power-ups validation
    local powerups = config.POWERUPS
    for powerupName, powerup in pairs(powerups) do
        if powerup.DURATION then
            validateNumber(powerup.DURATION, 0.5, 60, powerupName .. ".DURATION")
        end
        if powerup.COOLDOWN then
            validateNumber(powerup.COOLDOWN, 1, 300, powerupName .. ".COOLDOWN")
        end
        if powerup.MULTIPLIER then
            validateNumber(powerup.MULTIPLIER, 0.1, 10, powerupName .. ".MULTIPLIER")
        end
    end
    
    return true
end

-- ========================================
-- UI CONFIGURATION VALIDATORS
-- ========================================

function ConfigurationValidators.validateUIConfig(config)
    -- Screen resolution validation
    local screen = config.SCREEN
    local refRes = screen.REFERENCE_RESOLUTION
    validateNumber(refRes.WIDTH, 800, 7680, "REFERENCE_RESOLUTION.WIDTH")
    validateNumber(refRes.HEIGHT, 600, 4320, "REFERENCE_RESOLUTION.HEIGHT")
    validateNumber(screen.MIN_MOBILE_WIDTH, 320, 1920, "MIN_MOBILE_WIDTH")
    validateNumber(screen.UI_SCALE_FACTOR, 0.5, 3.0, "UI_SCALE_FACTOR")
    
    -- Animation timings validation
    local animations = config.ANIMATIONS
    validateNumber(animations.FADE_IN_TIME, 0.01, 5, "FADE_IN_TIME")
    validateNumber(animations.FADE_OUT_TIME, 0.01, 5, "FADE_OUT_TIME")
    validateNumber(animations.SLIDE_ANIMATION_TIME, 0.01, 5, "SLIDE_ANIMATION_TIME")
    validateNumber(animations.BUTTON_PRESS_TIME, 0.01, 1, "BUTTON_PRESS_TIME")
    validateNumber(animations.NOTIFICATION_DURATION, 0.5, 10, "NOTIFICATION_DURATION")
    validateNumber(animations.LOADING_SPINNER_SPEED, 0.1, 10, "LOADING_SPINNER_SPEED")
    
    -- UI element sizes validation
    local elements = config.ELEMENTS
    validateNumber(elements.BUTTON_HEIGHT, 20, 200, "BUTTON_HEIGHT")
    validateNumber(elements.BUTTON_WIDTH, 50, 800, "BUTTON_WIDTH")
    validateNumber(elements.ICON_SIZE, 8, 128, "ICON_SIZE")
    validateNumber(elements.LARGE_ICON_SIZE, 16, 256, "LARGE_ICON_SIZE")
    
    local padding = elements.PADDING
    validateNumber(padding.SMALL, 1, 50, "PADDING.SMALL")
    validateNumber(padding.MEDIUM, 2, 100, "PADDING.MEDIUM")
    validateNumber(padding.LARGE, 4, 150, "PADDING.LARGE")
    validateNumber(padding.EXTRA_LARGE, 8, 200, "PADDING.EXTRA_LARGE")
    
    -- Colors validation
    local colors = config.COLORS
    validateColor3(colors.PRIMARY, "PRIMARY")
    validateColor3(colors.SECONDARY, "SECONDARY")
    validateColor3(colors.SUCCESS, "SUCCESS")
    validateColor3(colors.WARNING, "WARNING")
    validateColor3(colors.ERROR, "ERROR")
    validateColor3(colors.BACKGROUND, "BACKGROUND")
    validateColor3(colors.TEXT, "TEXT")
    
    -- Mobile settings validation
    local mobile = config.MOBILE
    validateNumber(mobile.TOUCH_SENSITIVITY, 0.1, 5, "TOUCH_SENSITIVITY")
    validateNumber(mobile.BUTTON_SIZE_MULTIPLIER, 0.5, 3, "BUTTON_SIZE_MULTIPLIER")
    validateNumber(mobile.FONT_SIZE_MULTIPLIER, 0.5, 3, "FONT_SIZE_MULTIPLIER")
    
    return true
end

-- ========================================
-- PERFORMANCE CONFIGURATION VALIDATORS
-- ========================================

function ConfigurationValidators.validatePerformanceConfig(config)
    -- Rendering validation
    local rendering = config.RENDERING
    validateNumber(rendering.TARGET_FPS, 30, 120, "TARGET_FPS")
    validateNumber(rendering.MAX_RENDER_DISTANCE, 100, 10000, "MAX_RENDER_DISTANCE")
    
    local lodDistances = rendering.LOD_DISTANCES
    validateNumber(lodDistances.HIGH, 10, 500, "LOD_DISTANCES.HIGH")
    validateNumber(lodDistances.MEDIUM, 50, 1000, "LOD_DISTANCES.MEDIUM")
    validateNumber(lodDistances.LOW, 100, 2000, "LOD_DISTANCES.LOW")
    
    if lodDistances.HIGH >= lodDistances.MEDIUM or lodDistances.MEDIUM >= lodDistances.LOW then
        error("LOD distances must be in ascending order: HIGH < MEDIUM < LOW")
    end
    
    -- Memory validation
    local memory = config.MEMORY
    validateNumber(memory.GARBAGE_COLLECTION_INTERVAL, 1, 300, "GARBAGE_COLLECTION_INTERVAL")
    validateNumber(memory.MAX_CACHED_OBJECTS, 10, 10000, "MAX_CACHED_OBJECTS")
    validateNumber(memory.TEXTURE_MEMORY_LIMIT, 64, 4096, "TEXTURE_MEMORY_LIMIT")
    validateNumber(memory.AUTO_CLEANUP_THRESHOLD, 0.1, 1.0, "AUTO_CLEANUP_THRESHOLD")
    
    -- Network validation
    local network = config.NETWORK
    validateNumber(network.MAX_CONCURRENT_REQUESTS, 1, 50, "MAX_CONCURRENT_REQUESTS")
    validateNumber(network.REQUEST_TIMEOUT, 1, 120, "REQUEST_TIMEOUT")
    validateNumber(network.RETRY_ATTEMPTS, 0, 10, "RETRY_ATTEMPTS")
    validateNumber(network.BATCH_SIZE, 1, 1000, "BATCH_SIZE")
    
    -- Physics validation
    local physics = config.PHYSICS
    validateNumber(physics.SIMULATION_RADIUS, 50, 2000, "SIMULATION_RADIUS")
    validateNumber(physics.MAX_PHYSICS_OBJECTS, 10, 5000, "MAX_PHYSICS_OBJECTS")
    validateNumber(physics.COLLISION_CHECK_INTERVAL, 0.01, 1.0, "COLLISION_CHECK_INTERVAL")
    
    return true
end

-- ========================================
-- NETWORKING CONFIGURATION VALIDATORS
-- ========================================

function ConfigurationValidators.validateNetworkingConfig(config)
    -- Endpoints validation
    local endpoints = config.ENDPOINTS
    validateString(endpoints.BASE_URL, 8, 200, "^https?://", "BASE_URL")
    validateString(endpoints.ANALYTICS_URL, 8, 200, "^https?://", "ANALYTICS_URL")
    
    -- Request settings validation
    local requests = config.REQUESTS
    validateNumber(requests.DEFAULT_TIMEOUT, 1, 300, "DEFAULT_TIMEOUT")
    validateNumber(requests.LONG_TIMEOUT, 5, 600, "LONG_TIMEOUT")
    validateNumber(requests.SHORT_TIMEOUT, 0.5, 30, "SHORT_TIMEOUT")
    validateNumber(requests.MAX_RETRIES, 0, 20, "MAX_RETRIES")
    validateNumber(requests.RETRY_DELAY, 0.1, 60, "RETRY_DELAY")
    
    if requests.SHORT_TIMEOUT >= requests.DEFAULT_TIMEOUT or 
       requests.DEFAULT_TIMEOUT >= requests.LONG_TIMEOUT then
        error("Timeout values must be in ascending order: SHORT < DEFAULT < LONG")
    end
    
    -- DataStore validation
    local datastore = config.DATASTORE
    validateNumber(datastore.REQUEST_BUDGET_CHECK_INTERVAL, 0.1, 10, "REQUEST_BUDGET_CHECK_INTERVAL")
    validateNumber(datastore.MAX_REQUESTS_PER_MINUTE, 1, 1000, "MAX_REQUESTS_PER_MINUTE")
    validateNumber(datastore.BATCH_SIZE, 1, 100, "BATCH_SIZE")
    validateNumber(datastore.ERROR_RETRY_DELAY, 0.5, 300, "ERROR_RETRY_DELAY")
    
    return true
end

-- ========================================
-- ANALYTICS CONFIGURATION VALIDATORS
-- ========================================

function ConfigurationValidators.validateAnalyticsConfig(config)
    -- Events validation
    local events = config.EVENTS
    validateNumber(events.BATCH_SIZE, 1, 1000, "BATCH_SIZE")
    validateNumber(events.FLUSH_INTERVAL, 1, 300, "FLUSH_INTERVAL")
    validateNumber(events.MAX_QUEUE_SIZE, 10, 10000, "MAX_QUEUE_SIZE")
    
    if type(events.RETRY_FAILED_EVENTS) ~= "boolean" then
        error("RETRY_FAILED_EVENTS must be a boolean")
    end
    
    -- Metrics validation
    local metrics = config.METRICS
    validateNumber(metrics.COLLECTION_INTERVAL, 0.5, 300, "COLLECTION_INTERVAL")
    validateNumber(metrics.PERFORMANCE_SAMPLING_RATE, 0.001, 1.0, "PERFORMANCE_SAMPLING_RATE")
    
    -- Privacy validation
    local privacy = config.PRIVACY
    if type(privacy.COLLECT_USER_AGENT) ~= "boolean" then
        error("COLLECT_USER_AGENT must be a boolean")
    end
    if type(privacy.ANONYMIZE_IP) ~= "boolean" then
        error("ANONYMIZE_IP must be a boolean")
    end
    validateNumber(privacy.DATA_RETENTION_DAYS, 1, 3650, "DATA_RETENTION_DAYS") -- 1 day to 10 years
    
    return true
end

-- ========================================
-- SECURITY CONFIGURATION VALIDATORS
-- ========================================

function ConfigurationValidators.validateSecurityConfig(config)
    -- Validation settings
    local validation = config.VALIDATION
    validateNumber(validation.MAX_USERNAME_LENGTH, 3, 100, "MAX_USERNAME_LENGTH")
    validateNumber(validation.MAX_MESSAGE_LENGTH, 10, 2000, "MAX_MESSAGE_LENGTH")
    validateString(validation.ALLOWED_CHARACTERS, 1, 50, nil, "ALLOWED_CHARACTERS")
    validateNumber(validation.RATE_LIMIT_REQUESTS, 1, 1000, "RATE_LIMIT_REQUESTS")
    validateNumber(validation.RATE_LIMIT_WINDOW, 1, 3600, "RATE_LIMIT_WINDOW")
    
    -- Anti-cheat validation
    local anticheat = config.ANTICHEAT
    validateNumber(anticheat.SPEED_CHECK_THRESHOLD, 1.0, 10.0, "SPEED_CHECK_THRESHOLD")
    validateNumber(anticheat.POSITION_VALIDATION_INTERVAL, 0.1, 5.0, "POSITION_VALIDATION_INTERVAL")
    validateNumber(anticheat.MAX_TELEPORT_DISTANCE, 1, 1000, "MAX_TELEPORT_DISTANCE")
    
    if type(anticheat.ENABLE_SERVER_VALIDATION) ~= "boolean" then
        error("ENABLE_SERVER_VALIDATION must be a boolean")
    end
    
    -- Data protection validation
    local data = config.DATA
    if type(data.ENCRYPT_SENSITIVE_DATA) ~= "boolean" then
        error("ENCRYPT_SENSITIVE_DATA must be a boolean")
    end
    if type(data.USE_SECURE_RANDOM) ~= "boolean" then
        error("USE_SECURE_RANDOM must be a boolean")
    end
    if type(data.HASH_PLAYER_IDS) ~= "boolean" then
        error("HASH_PLAYER_IDS must be a boolean")
    end
    
    return true
end

-- ========================================
-- ASSETS CONFIGURATION VALIDATORS
-- ========================================

function ConfigurationValidators.validateAssetsConfig(config)
    -- Sound assets validation
    local sounds = config.SOUNDS
    for soundName, soundId in pairs(sounds) do
        validateNumber(soundId, 0, 999999999999, soundName .. " sound ID")
    end
    
    -- Image assets validation (basic string validation)
    local images = config.IMAGES
    for imageName, imageAsset in pairs(images) do
        validateString(imageAsset, 5, 200, nil, imageName .. " image asset")
    end
    
    -- Models validation
    local models = config.MODELS
    validateNumber(models.PLAYER_CHARACTER, 0, 999999999999, "PLAYER_CHARACTER")
    
    for modelType, modelId in pairs(models.OBSTACLES) do
        validateNumber(modelId, 0, 999999999999, "OBSTACLES." .. modelType)
    end
    
    -- Fonts validation
    local fonts = config.FONTS
    local validFonts = {
        Enum.Font.Legacy, Enum.Font.Arial, Enum.Font.ArialBold,
        Enum.Font.SourceSans, Enum.Font.SourceSansBold, Enum.Font.SourceSansLight,
        Enum.Font.SourceSansItalic, Enum.Font.Bodoni, Enum.Font.Garamond,
        Enum.Font.Cartoon, Enum.Font.Code, Enum.Font.Fantasy,
        Enum.Font.Gotham, Enum.Font.GothamBold, Enum.Font.GothamBlack
    }
    
    for fontName, font in pairs(fonts) do
        local isValidFont = false
        for _, validFont in ipairs(validFonts) do
            if font == validFont then
                isValidFont = true
                break
            end
        end
        if not isValidFont then
            error(fontName .. " must be a valid Enum.Font")
        end
    end
    
    return true
end

-- ========================================
-- MEMORY CONFIGURATION VALIDATORS
-- ========================================

function ConfigurationValidators.validateMemoryConfig(config)
    -- Tracking validation
    local tracking = config.TRACKING
    if type(tracking.ENABLE_DETAILED_LOGGING) ~= "boolean" then
        error("ENABLE_DETAILED_LOGGING must be a boolean")
    end
    if type(tracking.ENABLE_PERFORMANCE_MONITORING) ~= "boolean" then
        error("ENABLE_PERFORMANCE_MONITORING must be a boolean")
    end
    validateNumber(tracking.AUTO_CLEANUP_INTERVAL, 5, 3600, "AUTO_CLEANUP_INTERVAL")
    
    -- Limits validation
    local limits = config.LIMITS
    validateNumber(limits.MAX_CONNECTIONS_PER_PLAYER, 10, 1000, "MAX_CONNECTIONS_PER_PLAYER")
    validateNumber(limits.MAX_TWEENS_PER_PLAYER, 5, 500, "MAX_TWEENS_PER_PLAYER")
    validateNumber(limits.MAX_TASKS_PER_PLAYER, 5, 200, "MAX_TASKS_PER_PLAYER")
    validateNumber(limits.MAX_OBJECTS_PER_PLAYER, 10, 5000, "MAX_OBJECTS_PER_PLAYER")
    
    -- Cleanup validation
    local cleanup = config.CLEANUP
    validateNumber(cleanup.FORCE_GC_INTERVAL, 30, 3600, "FORCE_GC_INTERVAL")
    validateNumber(cleanup.MEMORY_WARNING_THRESHOLD, 0.1, 1.0, "MEMORY_WARNING_THRESHOLD")
    validateNumber(cleanup.EMERGENCY_CLEANUP_THRESHOLD, 0.1, 1.0, "EMERGENCY_CLEANUP_THRESHOLD")
    
    if cleanup.MEMORY_WARNING_THRESHOLD >= cleanup.EMERGENCY_CLEANUP_THRESHOLD then
        error("MEMORY_WARNING_THRESHOLD must be less than EMERGENCY_CLEANUP_THRESHOLD")
    end
    
    return true
end

-- ========================================
-- DEBUG CONFIGURATION VALIDATORS
-- ========================================

function ConfigurationValidators.validateDebugConfig(config)
    -- Logging validation
    local logging = config.LOGGING
    local validLogLevels = {"DEBUG", "INFO", "WARN", "ERROR"}
    validateEnum(logging.LEVEL, validLogLevels, "LEVEL")
    
    if type(logging.ENABLE_CONSOLE_OUTPUT) ~= "boolean" then
        error("ENABLE_CONSOLE_OUTPUT must be a boolean")
    end
    
    -- Features validation
    local features = config.FEATURES
    if type(features.SHOW_FPS_COUNTER) ~= "boolean" then
        error("SHOW_FPS_COUNTER must be a boolean")
    end
    if type(features.ENABLE_DEBUG_GUI) ~= "boolean" then
        error("ENABLE_DEBUG_GUI must be a boolean")
    end
    if type(features.ENABLE_PROFILING) ~= "boolean" then
        error("ENABLE_PROFILING must be a boolean")
    end
    
    return true
end

-- ========================================
-- REGISTRATION HELPER
-- ========================================

function ConfigurationValidators.registerAllValidators(configManager)
    configManager:RegisterValidator("gameplay", ConfigurationValidators.validateGameplayConfig)
    configManager:RegisterValidator("ui", ConfigurationValidators.validateUIConfig)
    configManager:RegisterValidator("performance", ConfigurationValidators.validatePerformanceConfig)
    configManager:RegisterValidator("networking", ConfigurationValidators.validateNetworkingConfig)
    configManager:RegisterValidator("analytics", ConfigurationValidators.validateAnalyticsConfig)
    configManager:RegisterValidator("security", ConfigurationValidators.validateSecurityConfig)
    configManager:RegisterValidator("assets", ConfigurationValidators.validateAssetsConfig)
    configManager:RegisterValidator("memory", ConfigurationValidators.validateMemoryConfig)
    configManager:RegisterValidator("debug", ConfigurationValidators.validateDebugConfig)
    
    print("✅ All configuration validators registered")
end

return ConfigurationValidators
