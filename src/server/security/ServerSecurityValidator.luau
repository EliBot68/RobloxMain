-- ServerSecurityValidator.luau
-- Comprehensive server-side validation and input sanitization system
-- Moves all critical game logic validation from client to server-side

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")

local SafeRequire = require(ReplicatedStorage.Shared.utils.SafeRequire)
local ServiceArchitecture = SafeRequire.require(ReplicatedStorage.Shared.core.ServiceArchitecture)

local ServerSecurityValidator = {}
ServerSecurityValidator.__index = ServerSecurityValidator

-- Implement ISecurityValidator interface
setmetatable(ServerSecurityValidator, {__index = ServiceArchitecture.ISecurityValidator})

-- ========================================
-- VALIDATION CONFIGURATION
-- ========================================

local VALIDATION_CONFIG = {
    maxStringLength = 500,
    maxTableDepth = 10,
    maxArraySize = 1000,
    allowedCharacterSet = "[%w%s%p]", -- Alphanumeric, whitespace, punctuation
    blockedPatterns = {
        "script:", "loadstring", "getfenv", "setfenv", "pcall", "xpcall",
        "coroutine", "debug", "io", "os", "require", "spawn", "delay"
    },
    trustedDomains = {
        "roblox.com", "rbxcdn.com", "rbxassets.com"
    }
}

local GAME_LOGIC_CONSTRAINTS = {
    -- Player progress constraints
    maxLevel = 1000,
    maxCoins = 999999999,
    maxExperience = 99999999,
    maxHighScore = 999999999,
    
    -- Gameplay constraints
    maxSpeed = 50, -- studs per second
    maxJumpHeight = 50,
    maxHealth = 100,
    
    -- Economic constraints
    maxPurchaseValue = 100000,
    maxTradeValue = 50000,
    dailyTransactionLimit = 1000000,
    
    -- Time constraints
    minGameDuration = 1, -- seconds
    maxGameDuration = 300, -- 5 minutes
    minActionInterval = 0.1 -- seconds between actions
}

local RATE_LIMITS = {
    -- Per-player rate limits (requests per minute)
    dataUpdate = 60,
    gameAction = 120,
    purchase = 10,
    chat = 30,
    
    -- Global rate limits (requests per minute)
    globalDataUpdates = 1000,
    globalGameActions = 5000
}

-- ========================================
-- CORE SECURITY VALIDATOR
-- ========================================

function ServerSecurityValidator.new()
    local self = setmetatable({}, ServerSecurityValidator)
    
    -- Player tracking
    self.playerSessions = {} -- Session data per player
    self.playerRateLimits = {} -- Rate limiting per player
    self.suspiciousActivity = {} -- Flagged activities per player
    
    -- Global tracking
    self.globalRateLimits = {}
    self.validationCache = {}
    self.blockedPlayers = {}
    
    -- Statistics
    self.stats = {
        validationsPerformed = 0,
        validationsFailed = 0,
        rateLimitViolations = 0,
        suspiciousActivities = 0,
        blockedRequests = 0,
        sanitizedInputs = 0
    }
    
    -- Initialize rate limiting
    self:InitializeRateLimiting()
    
    print("🛡️ ServerSecurityValidator initialized with comprehensive validation")
    return self
end

-- ========================================
-- INPUT VALIDATION AND SANITIZATION
-- ========================================

function ServerSecurityValidator:ValidateAndSanitizeInput(player, inputType, data)
    self.stats.validationsPerformed = self.stats.validationsPerformed + 1
    
    -- Check if player is blocked
    if self:IsPlayerBlocked(player) then
        self.stats.blockedRequests = self.stats.blockedRequests + 1
        return {
            isValid = false,
            error = "Player is blocked from making requests",
            sanitizedData = nil
        }
    end
    
    -- Check rate limits
    if not self:CheckRateLimit(player, inputType) then
        self.stats.rateLimitViolations = self.stats.rateLimitViolations + 1
        return {
            isValid = false,
            error = "Rate limit exceeded for " .. inputType,
            sanitizedData = nil
        }
    end
    
    -- Validate input structure
    local structureValidation = self:ValidateInputStructure(inputType, data)
    if not structureValidation.isValid then
        self.stats.validationsFailed = self.stats.validationsFailed + 1
        return structureValidation
    end
    
    -- Sanitize input data
    local sanitizedData = self:SanitizeData(data)
    if sanitizedData ~= data then
        self.stats.sanitizedInputs = self.stats.sanitizedInputs + 1
    end
    
    -- Validate game logic constraints
    local logicValidation = self:ValidateGameLogic(player, inputType, sanitizedData)
    if not logicValidation.isValid then
        self.stats.validationsFailed = self.stats.validationsFailed + 1
        self:FlagSuspiciousActivity(player, "logic_violation", {
            inputType = inputType,
            violation = logicValidation.error,
            data = sanitizedData
        })
        return logicValidation
    end
    
    -- Update player session tracking
    self:UpdatePlayerSession(player, inputType, sanitizedData)
    
    return {
        isValid = true,
        sanitizedData = sanitizedData,
        validationMetadata = {
            inputType = inputType,
            sanitizationPerformed = sanitizedData ~= data,
            timestamp = os.time()
        }
    }
end

function ServerSecurityValidator:ValidateInputStructure(inputType, data)
    if inputType == "playerDataUpdate" then
        return self:ValidatePlayerDataUpdate(data)
    elseif inputType == "gameAction" then
        return self:ValidateGameAction(data)
    elseif inputType == "purchase" then
        return self:ValidatePurchase(data)
    elseif inputType == "chatMessage" then
        return self:ValidateChatMessage(data)
    else
        return {
            isValid = false,
            error = "Unknown input type: " .. tostring(inputType)
        }
    end
end

function ServerSecurityValidator:ValidatePlayerDataUpdate(data)
    if type(data) ~= "table" then
        return {isValid = false, error = "Player data must be a table"}
    end
    
    -- Validate required fields
    local allowedFields = {
        "coins", "level", "experience", "highScore", "settings",
        "achievements", "pets", "cosmetics", "statistics"
    }
    
    for key, value in pairs(data) do
        if not table.find(allowedFields, key) then
            return {
                isValid = false,
                error = "Invalid field in player data: " .. tostring(key)
            }
        end
        
        -- Validate field types and ranges
        if key == "coins" or key == "level" or key == "experience" or key == "highScore" then
            if type(value) ~= "number" or value < 0 then
                return {
                    isValid = false,
                    error = "Invalid " .. key .. " value: must be non-negative number"
                }
            end
        end
    end
    
    return {isValid = true}
end

function ServerSecurityValidator:ValidateGameAction(data)
    if type(data) ~= "table" then
        return {isValid = false, error = "Game action must be a table"}
    end
    
    local requiredFields = {"actionType", "timestamp"}
    for _, field in ipairs(requiredFields) do
        if data[field] == nil then
            return {
                isValid = false,
                error = "Missing required field: " .. field
            }
        end
    end
    
    -- Validate action type
    local allowedActions = {
        "jump", "move", "collect", "activate", "complete", "start", "pause"
    }
    
    if not table.find(allowedActions, data.actionType) then
        return {
            isValid = false,
            error = "Invalid action type: " .. tostring(data.actionType)
        }
    end
    
    -- Validate timestamp (anti-replay protection)
    local currentTime = os.time()
    if type(data.timestamp) ~= "number" or 
       math.abs(data.timestamp - currentTime) > 30 then -- 30 second tolerance
        return {
            isValid = false,
            error = "Invalid or stale timestamp"
        }
    end
    
    return {isValid = true}
end

function ServerSecurityValidator:ValidatePurchase(data)
    if type(data) ~= "table" then
        return {isValid = false, error = "Purchase data must be a table"}
    end
    
    local requiredFields = {"itemId", "cost", "currency"}
    for _, field in ipairs(requiredFields) do
        if data[field] == nil then
            return {
                isValid = false,
                error = "Missing required field: " .. field
            }
        end
    end
    
    -- Validate cost
    if type(data.cost) ~= "number" or data.cost <= 0 or data.cost > GAME_LOGIC_CONSTRAINTS.maxPurchaseValue then
        return {
            isValid = false,
            error = "Invalid purchase cost"
        }
    end
    
    -- Validate currency
    local allowedCurrencies = {"coins", "gems", "robux"}
    if not table.find(allowedCurrencies, data.currency) then
        return {
            isValid = false,
            error = "Invalid currency: " .. tostring(data.currency)
        }
    end
    
    return {isValid = true}
end

function ServerSecurityValidator:ValidateChatMessage(data)
    if type(data) ~= "string" then
        return {isValid = false, error = "Chat message must be a string"}
    end
    
    if #data > VALIDATION_CONFIG.maxStringLength then
        return {
            isValid = false,
            error = "Chat message too long"
        }
    end
    
    -- Check for blocked patterns
    for _, pattern in ipairs(VALIDATION_CONFIG.blockedPatterns) do
        if string.find(string.lower(data), string.lower(pattern)) then
            return {
                isValid = false,
                error = "Chat message contains blocked content"
            }
        end
    end
    
    return {isValid = true}
end

function ServerSecurityValidator:SanitizeData(data)
    local dataType = type(data)
    
    if dataType == "string" then
        return self:SanitizeString(data)
    elseif dataType == "table" then
        return self:SanitizeTable(data)
    elseif dataType == "number" then
        return self:SanitizeNumber(data)
    else
        return data -- Basic types pass through
    end
end

function ServerSecurityValidator:SanitizeString(str)
    -- Remove null bytes and control characters
    str = string.gsub(str, "%z", "")
    str = string.gsub(str, "[\1-\31\127-\159]", "")
    
    -- Limit length
    if #str > VALIDATION_CONFIG.maxStringLength then
        str = string.sub(str, 1, VALIDATION_CONFIG.maxStringLength)
    end
    
    -- Remove blocked patterns
    for _, pattern in ipairs(VALIDATION_CONFIG.blockedPatterns) do
        str = string.gsub(str, pattern, "")
    end
    
    return str
end

function ServerSecurityValidator:SanitizeTable(tbl, depth)
    depth = depth or 0
    
    if depth > VALIDATION_CONFIG.maxTableDepth then
        return {}
    end
    
    local sanitized = {}
    local arraySize = 0
    
    for key, value in pairs(tbl) do
        -- Limit array size
        if type(key) == "number" then
            arraySize = arraySize + 1
            if arraySize > VALIDATION_CONFIG.maxArraySize then
                break
            end
        end
        
        -- Sanitize key and value
        local sanitizedKey = self:SanitizeData(key)
        local sanitizedValue = type(value) == "table" and 
                              self:SanitizeTable(value, depth + 1) or 
                              self:SanitizeData(value)
        
        sanitized[sanitizedKey] = sanitizedValue
    end
    
    return sanitized
end

function ServerSecurityValidator:SanitizeNumber(num)
    -- Check for NaN and infinity
    if num ~= num or num == math.huge or num == -math.huge then
        return 0
    end
    
    -- Clamp to reasonable range
    return math.max(-1e15, math.min(1e15, num))
end

-- ========================================
-- GAME LOGIC VALIDATION
-- ========================================

function ServerSecurityValidator:ValidateGameLogic(player, inputType, data)
    if inputType == "playerDataUpdate" then
        return self:ValidatePlayerProgress(player, data)
    elseif inputType == "gameAction" then
        return self:ValidateGameplayAction(player, data)
    elseif inputType == "purchase" then
        return self:ValidateEconomicTransaction(player, data)
    end
    
    return {isValid = true}
end

function ServerSecurityValidator:ValidatePlayerProgress(player, data)
    local playerId = tostring(player.UserId)
    local session = self.playerSessions[playerId]
    
    if not session then
        return {isValid = true} -- First update, allow it
    end
    
    -- Check for impossible progress jumps
    if data.level and session.lastLevel then
        local levelIncrease = data.level - session.lastLevel
        if levelIncrease > 10 then -- Max 10 levels per update
            return {
                isValid = false,
                error = "Impossible level increase detected"
            }
        end
    end
    
    if data.coins and session.lastCoins then
        local coinIncrease = data.coins - session.lastCoins
        local timeDiff = os.time() - (session.lastUpdate or os.time())
        local maxPossibleCoins = timeDiff * 100 -- Assume max 100 coins per second
        
        if coinIncrease > maxPossibleCoins and coinIncrease > 0 then
            return {
                isValid = false,
                error = "Impossible coin increase detected"
            }
        end
    end
    
    -- Check against absolute constraints
    if data.level and data.level > GAME_LOGIC_CONSTRAINTS.maxLevel then
        return {
            isValid = false,
            error = "Level exceeds maximum allowed"
        }
    end
    
    if data.coins and data.coins > GAME_LOGIC_CONSTRAINTS.maxCoins then
        return {
            isValid = false,
            error = "Coins exceed maximum allowed"
        }
    end
    
    return {isValid = true}
end

function ServerSecurityValidator:ValidateGameplayAction(player, data)
    local playerId = tostring(player.UserId)
    local session = self.playerSessions[playerId]
    
    if session and session.lastActionTime then
        local timeDiff = os.time() - session.lastActionTime
        if timeDiff < GAME_LOGIC_CONSTRAINTS.minActionInterval then
            return {
                isValid = false,
                error = "Actions too frequent"
            }
        end
    end
    
    -- Validate action-specific logic
    if data.actionType == "jump" and data.height then
        if data.height > GAME_LOGIC_CONSTRAINTS.maxJumpHeight then
            return {
                isValid = false,
                error = "Jump height exceeds maximum"
            }
        end
    end
    
    if data.actionType == "move" and data.speed then
        if data.speed > GAME_LOGIC_CONSTRAINTS.maxSpeed then
            return {
                isValid = false,
                error = "Movement speed exceeds maximum"
            }
        end
    end
    
    return {isValid = true}
end

function ServerSecurityValidator:ValidateEconomicTransaction(player, data)
    local playerId = tostring(player.UserId)
    
    -- Check daily transaction limits
    local today = os.date("%Y-%m-%d", os.time())
    local sessionKey = playerId .. "_" .. today
    local session = self.playerSessions[sessionKey] or {}
    
    local dailySpent = session.dailySpent or 0
    if dailySpent + data.cost > GAME_LOGIC_CONSTRAINTS.dailyTransactionLimit then
        return {
            isValid = false,
            error = "Daily transaction limit exceeded"
        }
    end
    
    return {isValid = true}
end

-- ========================================
-- RATE LIMITING
-- ========================================

function ServerSecurityValidator:InitializeRateLimiting()
    -- Event-driven rate limit reset system
    local rateLimitResetEvent = Instance.new("BindableEvent")
    
    local function scheduleRateLimitReset()
        wait(60) -- Reset every minute
        rateLimitResetEvent:Fire()
    end
    
    rateLimitResetEvent.Event:Connect(function()
        self:ResetRateLimits()
        spawn(scheduleRateLimitReset)
    end)
    
    -- Start the rate limit reset cycle
    spawn(scheduleRateLimitReset)
end

function ServerSecurityValidator:CheckRateLimit(player, requestType)
    local playerId = tostring(player.UserId)
    local minute = math.floor(os.time() / 60)
    local key = playerId .. "_" .. requestType .. "_" .. minute
    
    local currentCount = self.playerRateLimits[key] or 0
    local limit = RATE_LIMITS[requestType] or 60
    
    if currentCount >= limit then
        return false
    end
    
    self.playerRateLimits[key] = currentCount + 1
    
    -- Global rate limiting
    local globalKey = requestType .. "_" .. minute
    local globalCount = self.globalRateLimits[globalKey] or 0
    local globalLimit = RATE_LIMITS["global" .. string.gsub(requestType, "^%l", string.upper)] or 1000
    
    if globalCount >= globalLimit then
        return false
    end
    
    self.globalRateLimits[globalKey] = globalCount + 1
    return true
end

function ServerSecurityValidator:ResetRateLimits()
    local currentMinute = math.floor(os.time() / 60)
    
    -- Clean up old rate limit entries (keep only current minute)
    for key in pairs(self.playerRateLimits) do
        local minute = tonumber(string.match(key, "_(%d+)$"))
        if minute and minute < currentMinute then
            self.playerRateLimits[key] = nil
        end
    end
    
    for key in pairs(self.globalRateLimits) do
        local minute = tonumber(string.match(key, "_(%d+)$"))
        if minute and minute < currentMinute then
            self.globalRateLimits[key] = nil
        end
    end
end

-- ========================================
-- SESSION MANAGEMENT
-- ========================================

function ServerSecurityValidator:UpdatePlayerSession(player, actionType, data)
    local playerId = tostring(player.UserId)
    local session = self.playerSessions[playerId] or {}
    
    session.lastUpdate = os.time()
    session.lastActionTime = os.time()
    session.actionCount = (session.actionCount or 0) + 1
    
    if actionType == "playerDataUpdate" and data then
        if data.level then session.lastLevel = data.level end
        if data.coins then session.lastCoins = data.coins end
        if data.experience then session.lastExperience = data.experience end
    end
    
    self.playerSessions[playerId] = session
end

-- ========================================
-- SUSPICIOUS ACTIVITY TRACKING
-- ========================================

function ServerSecurityValidator:FlagSuspiciousActivity(player, activityType, details)
    local playerId = tostring(player.UserId)
    local flagged = self.suspiciousActivity[playerId] or {}
    
    table.insert(flagged, {
        activityType = activityType,
        details = details,
        timestamp = os.time(),
        serverId = game.JobId
    })
    
    self.suspiciousActivity[playerId] = flagged
    self.stats.suspiciousActivities = self.stats.suspiciousActivities + 1
    
    -- Auto-block if too many violations
    if #flagged >= 5 then
        self:BlockPlayer(player, "Multiple security violations")
    end
    
    print("🚨 Suspicious activity flagged for " .. player.Name .. ": " .. activityType)
end

function ServerSecurityValidator:BlockPlayer(player, reason)
    local playerId = tostring(player.UserId)
    self.blockedPlayers[playerId] = {
        reason = reason,
        timestamp = os.time(),
        blockedBy = "SecurityValidator"
    }
    
    print("🚫 Player blocked: " .. player.Name .. " - " .. reason)
end

function ServerSecurityValidator:IsPlayerBlocked(player)
    local playerId = tostring(player.UserId)
    return self.blockedPlayers[playerId] ~= nil
end

-- ========================================
-- UTILITY FUNCTIONS
-- ========================================

function ServerSecurityValidator:GetSecurityReport(player)
    local playerId = tostring(player.UserId)
    
    return {
        session = self.playerSessions[playerId],
        suspiciousActivities = self.suspiciousActivity[playerId] or {},
        isBlocked = self:IsPlayerBlocked(player),
        stats = self.stats
    }
end

function ServerSecurityValidator:GetSystemStatistics()
    return {
        stats = self.stats,
        activeSessions = 0,
        blockedPlayers = 0,
        flaggedActivities = 0
    }
    
    -- Count active sessions and blocked players
    for _ in pairs(self.playerSessions) do
        _.activeSessions = _.activeSessions + 1
    end
    
    for _ in pairs(self.blockedPlayers) do
        _.blockedPlayers = _.blockedPlayers + 1
    end
    
    for playerId, activities in pairs(self.suspiciousActivity) do
        _.flaggedActivities = _.flaggedActivities + #activities
    end
end

return ServerSecurityValidator
