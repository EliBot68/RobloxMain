-- DataValidator.luau
-- Comprehensive data validation and schema enforcement system
-- Ensures data integrity at all persistence points

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local HttpService = game:GetService("HttpService")

local SafeRequire = require(ReplicatedStorage.Shared.utils.SafeRequire)
local ServiceArchitecture = SafeRequire.require(ReplicatedStorage.Shared.core.ServiceArchitecture)

local DataValidator = {}
DataValidator.__index = DataValidator

-- Implement IValidator interface
setmetatable(DataValidator, {__index = ServiceArchitecture.IValidator})

-- ========================================
-- VALIDATION CONFIGURATION
-- ========================================

local VALIDATION_CONFIG = {
    strictMode = true,
    allowUnknownFields = false,
    maxDepth = 10,
    maxStringLength = 1000,
    maxArrayLength = 1000,
    maxObjectKeys = 100
}

local SCHEMA_VERSION = "1.0.0"

-- ========================================
-- DATA SCHEMAS
-- ========================================

local PLAYER_DATA_SCHEMA = {
    type = "object",
    required = {"coins", "level", "experience", "highScore", "upgrades", "cosmetics", "settings", "achievements", "quests", "pets", "buffs", "lastPlayed"},
    properties = {
        coins = {
            type = "number",
            minimum = 0,
            maximum = 999999999,
            description = "Player's current coin count"
        },
        level = {
            type = "number", 
            minimum = 1,
            maximum = 1000,
            description = "Player's current level"
        },
        experience = {
            type = "number",
            minimum = 0,
            maximum = 999999999,
            description = "Player's total experience points"
        },
        highScore = {
            type = "number",
            minimum = 0,
            maximum = 999999999,
            description = "Player's highest score achieved"
        },
        upgrades = {
            type = "object",
            description = "Player's purchased upgrades",
            properties = {
                speed = {type = "number", minimum = 0, maximum = 100},
                jump = {type = "number", minimum = 0, maximum = 100},
                coins = {type = "number", minimum = 0, maximum = 100},
                luck = {type = "number", minimum = 0, maximum = 100},
                magnet = {type = "number", minimum = 0, maximum = 100}
            }
        },
        cosmetics = {
            type = "object",
            description = "Player's cosmetic items",
            properties = {
                equipped = {
                    type = "object",
                    properties = {
                        hat = {type = "string", pattern = "^[a-zA-Z0-9_-]+$"},
                        shirt = {type = "string", pattern = "^[a-zA-Z0-9_-]+$"},
                        pants = {type = "string", pattern = "^[a-zA-Z0-9_-]+$"},
                        accessory = {type = "string", pattern = "^[a-zA-Z0-9_-]+$"}
                    }
                },
                owned = {
                    type = "array",
                    items = {type = "string", pattern = "^[a-zA-Z0-9_-]+$"},
                    maxItems = 100
                }
            }
        },
        settings = {
            type = "object",
            required = {"music", "sfx", "graphics"},
            properties = {
                music = {type = "boolean"},
                sfx = {type = "boolean"},
                graphics = {type = "string", enum = {"Low", "Medium", "High"}},
                controls = {type = "string", enum = {"Default", "Custom"}},
                autoRun = {type = "boolean"},
                showHints = {type = "boolean"}
            }
        },
        achievements = {
            type = "object",
            description = "Player's unlocked achievements",
            patternProperties = {
                "^[a-zA-Z0-9_-]+$" = {
                    type = "object",
                    required = {"unlocked", "progress"},
                    properties = {
                        unlocked = {type = "boolean"},
                        progress = {type = "number", minimum = 0},
                        unlockedAt = {type = "number", minimum = 0}
                    }
                }
            }
        },
        quests = {
            type = "object",
            properties = {
                active = {
                    type = "array",
                    items = {
                        type = "object",
                        required = {"id", "progress", "target", "startedAt"},
                        properties = {
                            id = {type = "string", pattern = "^[a-zA-Z0-9_-]+$"},
                            progress = {type = "number", minimum = 0},
                            target = {type = "number", minimum = 1},
                            startedAt = {type = "number", minimum = 0},
                            expiresAt = {type = "number", minimum = 0}
                        }
                    },
                    maxItems = 10
                },
                completed = {
                    type = "array",
                    items = {type = "string", pattern = "^[a-zA-Z0-9_-]+$"},
                    maxItems = 1000
                },
                daily = {
                    type = "object",
                    properties = {
                        lastReset = {type = "number", minimum = 0},
                        streak = {type = "number", minimum = 0, maximum = 365},
                        completed = {type = "array", items = {type = "string"}}
                    }
                }
            }
        },
        pets = {
            type = "object",
            properties = {
                active = {
                    anyOf = [
                        {type = "null"},
                        {type = "string", pattern = "^[a-zA-Z0-9_-]+$"}
                    ]
                },
                owned = {
                    type = "object",
                    patternProperties = {
                        "^[a-zA-Z0-9_-]+$" = {
                            type = "object",
                            required = {"level", "experience", "acquiredAt"},
                            properties = {
                                level = {type = "number", minimum = 1, maximum = 100},
                                experience = {type = "number", minimum = 0},
                                acquiredAt = {type = "number", minimum = 0},
                                abilities = {
                                    type = "array",
                                    items = {type = "string"}
                                }
                            }
                        }
                    }
                }
            }
        },
        buffs = {
            type = "object",
            description = "Active player buffs",
            patternProperties = {
                "^[a-zA-Z0-9_-]+$" = {
                    type = "object",
                    required = {"multiplier", "expiresAt"},
                    properties = {
                        multiplier = {type = "number", minimum = 0.1, maximum = 10},
                        expiresAt = {type = "number", minimum = 0},
                        source = {type = "string"}
                    }
                }
            }
        },
        lastPlayed = {
            type = "number",
            minimum = 0,
            description = "Timestamp of last play session"
        },
        joinDate = {
            type = "number", 
            minimum = 0,
            description = "Timestamp when player first joined"
        },
        playTime = {
            type = "number",
            minimum = 0,
            description = "Total play time in seconds"
        },
        statistics = {
            type = "object",
            properties = {
                gamesPlayed = {type = "number", minimum = 0},
                totalScore = {type = "number", minimum = 0},
                coinsEarned = {type = "number", minimum = 0},
                timePlayed = {type = "number", minimum = 0},
                achievements = {type = "number", minimum = 0}
            }
        }
    }
}

local UPDATE_SCHEMA = {
    type = "object",
    description = "Schema for data updates",
    patternProperties = {
        ".*" = {
            -- Allow any value type for updates
            description = "Update value"
        }
    }
}

-- ========================================
-- CORE VALIDATOR
-- ========================================

function DataValidator.new()
    local self = setmetatable({}, DataValidator)
    
    -- Validation state
    self.schemas = {
        playerData = PLAYER_DATA_SCHEMA,
        updates = UPDATE_SCHEMA
    }
    
    self.customValidators = {}
    self.validationCache = {}
    
    -- Statistics
    self.stats = {
        validations = 0,
        failures = 0,
        cacheHits = 0,
        customValidations = 0
    }
    
    print("✅ DataValidator initialized with schema enforcement")
    return self
end

-- ========================================
-- SCHEMA VALIDATION
-- ========================================

function DataValidator:Validate(data, schemaName)
    schemaName = schemaName or "playerData"
    self.stats.validations = self.stats.validations + 1
    
    local schema = self.schemas[schemaName]
    if not schema then
        return {
            isValid = false,
            errors = {"Unknown schema: " .. schemaName},
            warnings = {}
        }
    end
    
    -- Check cache first
    local cacheKey = self:GenerateCacheKey(data, schemaName)
    if self.validationCache[cacheKey] then
        self.stats.cacheHits = self.stats.cacheHits + 1
        return self.validationCache[cacheKey]
    end
    
    local result = self:ValidateAgainstSchema(data, schema, "")
    
    -- Cache result
    self.validationCache[cacheKey] = result
    
    if not result.isValid then
        self.stats.failures = self.stats.failures + 1
    end
    
    return result
end

function DataValidator:ValidateAgainstSchema(data, schema, path, depth)
    depth = depth or 0
    
    -- Prevent infinite recursion
    if depth > VALIDATION_CONFIG.maxDepth then
        return {
            isValid = false,
            errors = {"Maximum validation depth exceeded at " .. path},
            warnings = {}
        }
    end
    
    local result = {
        isValid = true,
        errors = {},
        warnings = {}
    }
    
    -- Type validation
    if schema.type then
        if not self:ValidateType(data, schema.type, path, result) then
            return result
        end
    end
    
    -- Required fields validation (for objects)
    if schema.type == "object" and schema.required then
        self:ValidateRequired(data, schema.required, path, result)
    end
    
    -- Properties validation (for objects)
    if schema.type == "object" and schema.properties then
        self:ValidateProperties(data, schema.properties, path, result, depth)
    end
    
    -- Pattern properties validation (for objects)
    if schema.type == "object" and schema.patternProperties then
        self:ValidatePatternProperties(data, schema.patternProperties, path, result, depth)
    end
    
    -- Array items validation
    if schema.type == "array" and schema.items then
        self:ValidateArrayItems(data, schema.items, path, result, depth)
    end
    
    -- String validations
    if schema.type == "string" then
        self:ValidateString(data, schema, path, result)
    end
    
    -- Number validations
    if schema.type == "number" then
        self:ValidateNumber(data, schema, path, result)
    end
    
    -- Enum validation
    if schema.enum then
        self:ValidateEnum(data, schema.enum, path, result)
    end
    
    -- Custom validation
    if schema.customValidator then
        self:ValidateCustom(data, schema.customValidator, path, result)
    end
    
    return result
end

-- ========================================
-- TYPE VALIDATION
-- ========================================

function DataValidator:ValidateType(data, expectedType, path, result)
    local actualType = type(data)
    
    -- Handle nil values
    if data == nil then
        table.insert(result.errors, "Value is nil at " .. path)
        result.isValid = false
        return false
    end
    
    -- Handle anyOf (union types)
    if type(expectedType) == "table" and expectedType.anyOf then
        for _, unionType in ipairs(expectedType.anyOf) do
            if self:TypeMatches(data, unionType) then
                return true
            end
        end
        table.insert(result.errors, "Value at " .. path .. " does not match any expected type")
        result.isValid = false
        return false
    end
    
    -- Standard type checking
    if not self:TypeMatches(data, expectedType) then
        table.insert(result.errors, "Expected " .. expectedType .. " at " .. path .. ", got " .. actualType)
        result.isValid = false
        return false
    end
    
    return true
end

function DataValidator:TypeMatches(data, expectedType)
    if type(expectedType) == "string" then
        if expectedType == "null" then
            return data == nil
        else
            return type(data) == expectedType
        end
    elseif type(expectedType) == "table" and expectedType.type then
        return self:TypeMatches(data, expectedType.type)
    end
    
    return false
end

-- ========================================
-- OBJECT VALIDATION
-- ========================================

function DataValidator:ValidateRequired(data, required, path, result)
    if type(data) ~= "table" then
        return
    end
    
    for _, fieldName in ipairs(required) do
        if data[fieldName] == nil then
            table.insert(result.errors, "Missing required field '" .. fieldName .. "' at " .. path)
            result.isValid = false
        end
    end
end

function DataValidator:ValidateProperties(data, properties, path, result, depth)
    if type(data) ~= "table" then
        return
    end
    
    -- Validate known properties
    for propName, propSchema in pairs(properties) do
        if data[propName] ~= nil then
            local propPath = path == "" and propName or path .. "." .. propName
            local propResult = self:ValidateAgainstSchema(data[propName], propSchema, propPath, depth + 1)
            
            if not propResult.isValid then
                for _, error in ipairs(propResult.errors) do
                    table.insert(result.errors, error)
                end
                result.isValid = false
            end
            
            for _, warning in ipairs(propResult.warnings) do
                table.insert(result.warnings, warning)
            end
        end
    end
    
    -- Check for unknown properties
    if not VALIDATION_CONFIG.allowUnknownFields then
        for propName, _ in pairs(data) do
            if not properties[propName] then
                table.insert(result.warnings, "Unknown property '" .. propName .. "' at " .. path)
            end
        end
    end
end

function DataValidator:ValidatePatternProperties(data, patternProperties, path, result, depth)
    if type(data) ~= "table" then
        return
    end
    
    for propName, propValue in pairs(data) do
        local matchedPattern = false
        
        for pattern, propSchema in pairs(patternProperties) do
            if string.match(propName, pattern) then
                matchedPattern = true
                local propPath = path == "" and propName or path .. "." .. propName
                local propResult = self:ValidateAgainstSchema(propValue, propSchema, propPath, depth + 1)
                
                if not propResult.isValid then
                    for _, error in ipairs(propResult.errors) do
                        table.insert(result.errors, error)
                    end
                    result.isValid = false
                end
                
                for _, warning in ipairs(propResult.warnings) do
                    table.insert(result.warnings, warning)
                end
                
                break
            end
        end
        
        if not matchedPattern and not VALIDATION_CONFIG.allowUnknownFields then
            table.insert(result.warnings, "Property '" .. propName .. "' at " .. path .. " does not match any pattern")
        end
    end
end

-- ========================================
-- ARRAY VALIDATION
-- ========================================

function DataValidator:ValidateArrayItems(data, itemSchema, path, result, depth)
    if type(data) ~= "table" then
        return
    end
    
    -- Check array length
    local arrayLength = #data
    if arrayLength > VALIDATION_CONFIG.maxArrayLength then
        table.insert(result.errors, "Array at " .. path .. " exceeds maximum length of " .. VALIDATION_CONFIG.maxArrayLength)
        result.isValid = false
        return
    end
    
    -- Validate each item
    for i, item in ipairs(data) do
        local itemPath = path .. "[" .. i .. "]"
        local itemResult = self:ValidateAgainstSchema(item, itemSchema, itemPath, depth + 1)
        
        if not itemResult.isValid then
            for _, error in ipairs(itemResult.errors) do
                table.insert(result.errors, error)
            end
            result.isValid = false
        end
        
        for _, warning in ipairs(itemResult.warnings) do
            table.insert(result.warnings, warning)
        end
    end
end

-- ========================================
-- STRING VALIDATION
-- ========================================

function DataValidator:ValidateString(data, schema, path, result)
    if type(data) ~= "string" then
        return
    end
    
    local stringLength = string.len(data)
    
    -- Length validation
    if stringLength > VALIDATION_CONFIG.maxStringLength then
        table.insert(result.errors, "String at " .. path .. " exceeds maximum length of " .. VALIDATION_CONFIG.maxStringLength)
        result.isValid = false
    end
    
    if schema.minLength and stringLength < schema.minLength then
        table.insert(result.errors, "String at " .. path .. " is shorter than minimum length of " .. schema.minLength)
        result.isValid = false
    end
    
    if schema.maxLength and stringLength > schema.maxLength then
        table.insert(result.errors, "String at " .. path .. " exceeds maximum length of " .. schema.maxLength)
        result.isValid = false
    end
    
    -- Pattern validation
    if schema.pattern then
        if not string.match(data, schema.pattern) then
            table.insert(result.errors, "String at " .. path .. " does not match required pattern")
            result.isValid = false
        end
    end
    
    -- Format validation
    if schema.format then
        if not self:ValidateStringFormat(data, schema.format, path, result) then
            result.isValid = false
        end
    end
end

function DataValidator:ValidateStringFormat(data, format, path, result)
    if format == "email" then
        if not string.match(data, "^[%w%.%-_]+@[%w%.%-_]+%.%w+$") then
            table.insert(result.errors, "Invalid email format at " .. path)
            return false
        end
    elseif format == "url" then
        if not string.match(data, "^https?://") then
            table.insert(result.errors, "Invalid URL format at " .. path)
            return false
        end
    elseif format == "uuid" then
        if not string.match(data, "^%x%x%x%x%x%x%x%x%-%x%x%x%x%-%x%x%x%x%-%x%x%x%x%-%x%x%x%x%x%x%x%x%x%x%x%x$") then
            table.insert(result.errors, "Invalid UUID format at " .. path)
            return false
        end
    end
    
    return true
end

-- ========================================
-- NUMBER VALIDATION
-- ========================================

function DataValidator:ValidateNumber(data, schema, path, result)
    if type(data) ~= "number" then
        return
    end
    
    -- Check for NaN and infinity
    if data ~= data then -- NaN check
        table.insert(result.errors, "Number at " .. path .. " is NaN")
        result.isValid = false
        return
    end
    
    if data == math.huge or data == -math.huge then
        table.insert(result.errors, "Number at " .. path .. " is infinite")
        result.isValid = false
        return
    end
    
    -- Range validation
    if schema.minimum and data < schema.minimum then
        table.insert(result.errors, "Number at " .. path .. " is below minimum of " .. schema.minimum)
        result.isValid = false
    end
    
    if schema.maximum and data > schema.maximum then
        table.insert(result.errors, "Number at " .. path .. " exceeds maximum of " .. schema.maximum)
        result.isValid = false
    end
    
    if schema.exclusiveMinimum and data <= schema.exclusiveMinimum then
        table.insert(result.errors, "Number at " .. path .. " must be greater than " .. schema.exclusiveMinimum)
        result.isValid = false
    end
    
    if schema.exclusiveMaximum and data >= schema.exclusiveMaximum then
        table.insert(result.errors, "Number at " .. path .. " must be less than " .. schema.exclusiveMaximum)
        result.isValid = false
    end
    
    -- Multiple validation
    if schema.multipleOf and data % schema.multipleOf ~= 0 then
        table.insert(result.errors, "Number at " .. path .. " is not a multiple of " .. schema.multipleOf)
        result.isValid = false
    end
end

-- ========================================
-- ENUM VALIDATION
-- ========================================

function DataValidator:ValidateEnum(data, enumValues, path, result)
    local isValid = false
    
    for _, enumValue in ipairs(enumValues) do
        if data == enumValue then
            isValid = true
            break
        end
    end
    
    if not isValid then
        local enumString = table.concat(enumValues, ", ")
        table.insert(result.errors, "Value at " .. path .. " must be one of: " .. enumString)
        result.isValid = false
    end
end

-- ========================================
-- CUSTOM VALIDATION
-- ========================================

function DataValidator:ValidateCustom(data, validatorName, path, result)
    self.stats.customValidations = self.stats.customValidations + 1
    
    local validator = self.customValidators[validatorName]
    if not validator then
        table.insert(result.warnings, "Unknown custom validator: " .. validatorName)
        return
    end
    
    local success, customResult = pcall(validator, data, path)
    
    if not success then
        table.insert(result.errors, "Custom validation error at " .. path .. ": " .. tostring(customResult))
        result.isValid = false
        return
    end
    
    if not customResult.isValid then
        for _, error in ipairs(customResult.errors or {}) do
            table.insert(result.errors, error)
        end
        result.isValid = false
    end
    
    for _, warning in ipairs(customResult.warnings or {}) do
        table.insert(result.warnings, warning)
    end
end

function DataValidator:RegisterCustomValidator(name, validatorFunction)
    self.customValidators[name] = validatorFunction
    print("🔧 Registered custom validator: " .. name)
end

-- ========================================
-- SCHEMA MANAGEMENT
-- ========================================

function DataValidator:RegisterSchema(name, schema)
    self.schemas[name] = schema
    print("📋 Registered validation schema: " .. name)
end

function DataValidator:GetSchema(name)
    return self.schemas[name]
end

function DataValidator:UpdateSchema(name, schema)
    if self.schemas[name] then
        self.schemas[name] = schema
        -- Clear cache entries for this schema
        self:ClearCacheForSchema(name)
        print("📋 Updated validation schema: " .. name)
        return true
    end
    return false
end

-- ========================================
-- CACHE MANAGEMENT
-- ========================================

function DataValidator:GenerateCacheKey(data, schemaName)
    -- Create a simple hash of the data structure
    local dataString = HttpService:JSONEncode(data)
    return schemaName .. "_" .. string.len(dataString) .. "_" .. (string.byte(dataString, 1) or 0)
end

function DataValidator:ClearCacheForSchema(schemaName)
    for cacheKey, _ in pairs(self.validationCache) do
        if string.sub(cacheKey, 1, string.len(schemaName)) == schemaName then
            self.validationCache[cacheKey] = nil
        end
    end
end

function DataValidator:ClearCache()
    self.validationCache = {}
    print("🗑️ Validation cache cleared")
end

-- ========================================
-- UTILITY FUNCTIONS
-- ========================================

function DataValidator:ValidateUpdate(currentData, updateData)
    -- Validate the update format
    local updateResult = self:Validate(updateData, "updates")
    if not updateResult.isValid then
        return updateResult
    end
    
    -- Apply update to current data for full validation
    local updatedData = self:ApplyUpdate(currentData, updateData)
    
    -- Validate the resulting data
    return self:Validate(updatedData, "playerData")
end

function DataValidator:ApplyUpdate(currentData, updateData)
    local result = {}
    
    -- Copy current data
    for key, value in pairs(currentData) do
        result[key] = value
    end
    
    -- Apply updates
    for key, value in pairs(updateData) do
        result[key] = value
    end
    
    return result
end

function DataValidator:SanitizeData(data, schemaName)
    schemaName = schemaName or "playerData"
    local schema = self.schemas[schemaName]
    
    if not schema then
        warn("⚠️ Cannot sanitize data - unknown schema: " .. schemaName)
        return data
    end
    
    return self:SanitizeAgainstSchema(data, schema)
end

function DataValidator:SanitizeAgainstSchema(data, schema)
    if schema.type == "object" and type(data) == "table" then
        local sanitized = {}
        
        -- Only include known properties
        if schema.properties then
            for propName, propSchema in pairs(schema.properties) do
                if data[propName] ~= nil then
                    sanitized[propName] = self:SanitizeAgainstSchema(data[propName], propSchema)
                end
            end
        end
        
        return sanitized
        
    elseif schema.type == "array" and type(data) == "table" then
        local sanitized = {}
        
        for i, item in ipairs(data) do
            sanitized[i] = self:SanitizeAgainstSchema(item, schema.items)
        end
        
        return sanitized
        
    else
        -- For primitive types, return as-is (validation will catch issues)
        return data
    end
end

function DataValidator:GetStatistics()
    return {
        stats = self.stats,
        cacheSize = self:CountCacheEntries(),
        schemasCount = self:CountSchemas(),
        customValidatorsCount = self:CountCustomValidators()
    }
end

function DataValidator:CountCacheEntries()
    local count = 0
    for _ in pairs(self.validationCache) do
        count = count + 1
    end
    return count
end

function DataValidator:CountSchemas()
    local count = 0
    for _ in pairs(self.schemas) do
        count = count + 1
    end
    return count
end

function DataValidator:CountCustomValidators()
    local count = 0
    for _ in pairs(self.customValidators) do
        count = count + 1
    end
    return count
end

return DataValidator
