-- ConfigurationMigration.luau
-- Migration utilities to help transition services from hardcoded values to ConfigurationManager
-- Provides tools to identify and replace magic numbers throughout the codebase

local ConfigurationMigration = {}

-- Common magic numbers found in Roblox games that should be moved to configuration
local COMMON_MAGIC_NUMBERS = {
    -- Time-related constants
    {pattern = "wait%((%d+%.?%d*)%)", replacement = "config:Get('gameplay.WAIT_TIMES.{NAME}')", description = "Wait times"},
    {pattern = "task%.wait%((%d+%.?%d*)%)", replacement = "config:Get('gameplay.WAIT_TIMES.{NAME}')", description = "Task wait times"},
    
    -- UI dimensions
    {pattern = "Size = UDim2%.new%(0, (%d+), 0, (%d+)%)", replacement = "Size = UDim2.new(0, config:Get('ui.ELEMENTS.{NAME}_WIDTH'), 0, config:Get('ui.ELEMENTS.{NAME}_HEIGHT'))", description = "UI element sizes"},
    {pattern = "Position = UDim2%.new%((%d+%.?%d*), (%d+), (%d+%.?%d*), (%d+)%)", replacement = "Position = UDim2.new(config:Get('ui.POSITIONS.{NAME}_X'), 0, config:Get('ui.POSITIONS.{NAME}_Y'), 0)", description = "UI positions"},
    
    -- Physics values
    {pattern = "Velocity = Vector3%.new%((%d+%.?%d*), (%d+%.?%d*), (%d+%.?%d*)%)", replacement = "Velocity = Vector3.new(config:Get('physics.VELOCITY.{NAME}_X'), config:Get('physics.VELOCITY.{NAME}_Y'), config:Get('physics.VELOCITY.{NAME}_Z'))", description = "Physics velocities"},
    {pattern = "WalkSpeed = (%d+%.?%d*)", replacement = "WalkSpeed = config:Get('gameplay.PLAYER.WALK_SPEED')", description = "Player walk speed"},
    {pattern = "JumpPower = (%d+%.?%d*)", replacement = "JumpPower = config:Get('gameplay.PLAYER.JUMP_POWER')", description = "Player jump power"},
    
    -- Scoring and gameplay
    {pattern = "score = score %+ (%d+)", replacement = "score = score + config:Get('gameplay.SCORING.{NAME}_POINTS')", description = "Score increments"},
    {pattern = "health = (%d+)", replacement = "health = config:Get('gameplay.PLAYER.MAX_HEALTH')", description = "Health values"},
    
    -- Colors
    {pattern = "Color3%.fromRGB%((%d+), (%d+), (%d+)%)", replacement = "config:Get('ui.COLORS.{NAME}')", description = "Color values"},
    
    -- Asset IDs
    {pattern = "SoundId = \"rbxassetid://(%d+)\"", replacement = "SoundId = \"rbxassetid://\" .. config:Get('assets.SOUNDS.{NAME}')", description = "Sound asset IDs"},
    {pattern = "Image = \"rbxassetid://(%d+)\"", replacement = "Image = \"rbxassetid://\" .. config:Get('assets.IMAGES.{NAME}')", description = "Image asset IDs"},
}

-- Configuration templates for different types of values
local CONFIG_TEMPLATES = {
    WAIT_TIMES = {
        SHORT = 0.5,
        MEDIUM = 1.0,
        LONG = 2.0,
        RESPAWN = 3.0,
        COOLDOWN = 5.0
    },
    
    UI_DIMENSIONS = {
        BUTTON_WIDTH = 200,
        BUTTON_HEIGHT = 50,
        ICON_SIZE = 32,
        LARGE_ICON_SIZE = 64,
        SMALL_PADDING = 8,
        MEDIUM_PADDING = 16,
        LARGE_PADDING = 24
    },
    
    PLAYER_STATS = {
        DEFAULT_WALK_SPEED = 16,
        DEFAULT_JUMP_POWER = 50,
        MAX_HEALTH = 100,
        RESPAWN_TIME = 3.0
    },
    
    SCORING_VALUES = {
        KILL_POINTS = 100,
        ASSIST_POINTS = 50,
        OBJECTIVE_POINTS = 200,
        BONUS_MULTIPLIER = 1.5
    }
}

-- ========================================
-- MAGIC NUMBER DETECTION
-- ========================================

function ConfigurationMigration.scanFileForMagicNumbers(filePath)
    local file = io.open(filePath, "r")
    if not file then
        warn("Could not open file: " .. filePath)
        return {}
    end
    
    local content = file:read("*all")
    file:close()
    
    local findings = {}
    local lineNumber = 1
    
    for line in content:gmatch("[^\r\n]+") do
        for _, pattern in ipairs(COMMON_MAGIC_NUMBERS) do
            for match in line:gmatch(pattern.pattern) do
                table.insert(findings, {
                    file = filePath,
                    line = lineNumber,
                    content = line:match("%s*(.-)%s*"), -- Trim whitespace
                    magicNumber = match,
                    suggestedReplacement = pattern.replacement,
                    description = pattern.description
                })
            end
        end
        lineNumber = lineNumber + 1
    end
    
    return findings
end

function ConfigurationMigration.scanDirectoryForMagicNumbers(directoryPath)
    local allFindings = {}
    
    -- This would need to be implemented with actual file system access
    -- For now, return example findings
    local exampleFindings = {
        {
            file = "GameService.luau",
            line = 45,
            content = "wait(3)",
            magicNumber = "3",
            suggestedReplacement = "config:Get('gameplay.WAIT_TIMES.RESPAWN')",
            description = "Wait times"
        },
        {
            file = "UIManager.luau", 
            line = 12,
            content = "Size = UDim2.new(0, 200, 0, 50)",
            magicNumber = "200, 50",
            suggestedReplacement = "Size = UDim2.new(0, config:Get('ui.ELEMENTS.BUTTON_WIDTH'), 0, config:Get('ui.ELEMENTS.BUTTON_HEIGHT'))",
            description = "UI element sizes"
        }
    }
    
    return exampleFindings
end

-- ========================================
-- CONFIGURATION GENERATION
-- ========================================

function ConfigurationMigration.generateConfigurationFromFindings(findings)
    local generatedConfig = {
        gameplay = {
            WAIT_TIMES = {},
            PLAYER = {},
            SCORING = {}
        },
        ui = {
            ELEMENTS = {},
            POSITIONS = {},
            COLORS = {}
        },
        assets = {
            SOUNDS = {},
            IMAGES = {}
        }
    }
    
    for _, finding in ipairs(findings) do
        if finding.description == "Wait times" then
            local configName = "GENERIC_WAIT_" .. finding.magicNumber:gsub("%.", "_")
            generatedConfig.gameplay.WAIT_TIMES[configName] = tonumber(finding.magicNumber)
        elseif finding.description == "UI element sizes" then
            -- Parse width/height from magic number
            local width, height = finding.magicNumber:match("(%d+), (%d+)")
            if width and height then
                generatedConfig.ui.ELEMENTS["ELEMENT_WIDTH"] = tonumber(width)
                generatedConfig.ui.ELEMENTS["ELEMENT_HEIGHT"] = tonumber(height)
            end
        elseif finding.description == "Player walk speed" then
            generatedConfig.gameplay.PLAYER.WALK_SPEED = tonumber(finding.magicNumber)
        elseif finding.description == "Sound asset IDs" then
            local soundName = "SOUND_" .. finding.magicNumber
            generatedConfig.assets.SOUNDS[soundName] = tonumber(finding.magicNumber)
        end
    end
    
    return generatedConfig
end

-- ========================================
-- AUTOMATIC REPLACEMENT
-- ========================================

function ConfigurationMigration.createReplacementScript(findings)
    local script = {
        "-- Auto-generated configuration migration script",
        "-- Replace magic numbers with configuration calls",
        "",
        "local ConfigurationManager = require(ReplicatedStorage.Shared.core.ConfigurationManager)",
        "local config = ConfigurationManager.getInstance()",
        ""
    }
    
    local replacements = {}
    
    for _, finding in ipairs(findings) do
        table.insert(replacements, {
            file = finding.file,
            line = finding.line,
            from = finding.content,
            to = finding.suggestedReplacement:gsub("{NAME}", "GENERIC")
        })
    end
    
    -- Group replacements by file
    local fileReplacements = {}
    for _, replacement in ipairs(replacements) do
        if not fileReplacements[replacement.file] then
            fileReplacements[replacement.file] = {}
        end
        table.insert(fileReplacements[replacement.file], replacement)
    end
    
    -- Generate replacement code
    for file, replacements in pairs(fileReplacements) do
        table.insert(script, "-- Replacements for " .. file)
        for _, replacement in ipairs(replacements) do
            table.insert(script, "-- Line " .. replacement.line .. ": " .. replacement.from)
            table.insert(script, "-- Replace with: " .. replacement.to)
        end
        table.insert(script, "")
    end
    
    return table.concat(script, "\n")
end

-- ========================================
-- VALIDATION AND TESTING
-- ========================================

function ConfigurationMigration.validateMigration(configManager)
    local validationResults = {
        success = true,
        errors = {},
        warnings = {},
        stats = {
            totalConfigs = 0,
            validConfigs = 0,
            invalidConfigs = 0
        }
    }
    
    -- Get all configurations
    local allConfigs = configManager:GetAllConfigurations()
    
    for configName, config in pairs(allConfigs) do
        validationResults.stats.totalConfigs = validationResults.stats.totalConfigs + 1
        
        local isValid, error = pcall(function()
            -- Basic validation - check for nil values and proper types
            ConfigurationMigration._validateConfigStructure(config, configName)
        end)
        
        if isValid then
            validationResults.stats.validConfigs = validationResults.stats.validConfigs + 1
        else
            validationResults.stats.invalidConfigs = validationResults.stats.invalidConfigs + 1
            validationResults.success = false
            table.insert(validationResults.errors, {
                config = configName,
                error = tostring(error)
            })
        end
    end
    
    return validationResults
end

function ConfigurationMigration._validateConfigStructure(config, configName)
    if type(config) ~= "table" then
        error("Configuration '" .. configName .. "' is not a table")
    end
    
    -- Check for empty configurations
    local hasValues = false
    for _ in pairs(config) do
        hasValues = true
        break
    end
    
    if not hasValues then
        error("Configuration '" .. configName .. "' is empty")
    end
    
    -- Recursively check nested tables
    for key, value in pairs(config) do
        if type(value) == "table" then
            ConfigurationMigration._validateConfigStructure(value, configName .. "." .. key)
        elseif value == nil then
            error("Configuration '" .. configName .. "." .. key .. "' is nil")
        end
    end
end

-- ========================================
-- MIGRATION REPORTS
-- ========================================

function ConfigurationMigration.generateMigrationReport(findings, configManager)
    local report = {
        "# Configuration Migration Report",
        "Generated on: " .. os.date("%Y-%m-%d %H:%M:%S"),
        "",
        "## Summary",
        "- Total files scanned: " .. tostring(#findings),
        "- Magic numbers found: " .. tostring(#findings),
        "- Configuration environment: " .. configManager:GetEnvironment(),
        "",
        "## Findings by Category"
    }
    
    -- Group findings by description
    local categories = {}
    for _, finding in ipairs(findings) do
        if not categories[finding.description] then
            categories[finding.description] = {}
        end
        table.insert(categories[finding.description], finding)
    end
    
    for category, categoryFindings in pairs(categories) do
        table.insert(report, "")
        table.insert(report, "### " .. category)
        table.insert(report, "Found " .. #categoryFindings .. " instances:")
        
        for _, finding in ipairs(categoryFindings) do
            table.insert(report, "- **" .. finding.file .. ":" .. finding.line .. "** - `" .. finding.content .. "`")
            table.insert(report, "  - Suggested: `" .. finding.suggestedReplacement .. "`")
        end
    end
    
    table.insert(report, "")
    table.insert(report, "## Configuration Validation")
    
    local validation = ConfigurationMigration.validateMigration(configManager)
    table.insert(report, "- ✅ Valid configurations: " .. validation.stats.validConfigs)
    table.insert(report, "- ❌ Invalid configurations: " .. validation.stats.invalidConfigs)
    table.insert(report, "- 📊 Total configurations: " .. validation.stats.totalConfigs)
    
    if #validation.errors > 0 then
        table.insert(report, "")
        table.insert(report, "### Validation Errors")
        for _, error in ipairs(validation.errors) do
            table.insert(report, "- **" .. error.config .. "**: " .. error.error)
        end
    end
    
    table.insert(report, "")
    table.insert(report, "## Next Steps")
    table.insert(report, "1. Review suggested replacements")
    table.insert(report, "2. Update configuration values as needed")
    table.insert(report, "3. Test changes in development environment")
    table.insert(report, "4. Deploy to staging for validation")
    table.insert(report, "5. Monitor production for any issues")
    
    return table.concat(report, "\n")
end

-- ========================================
-- UTILITY FUNCTIONS
-- ========================================

function ConfigurationMigration.createBackupConfiguration(configManager)
    local backup = {
        timestamp = os.time(),
        environment = configManager:GetEnvironment(),
        configurations = configManager:GetAllConfigurations()
    }
    
    -- In a real implementation, this would save to a file
    print("📁 Configuration backup created for environment: " .. configManager:GetEnvironment())
    
    return backup
end

function ConfigurationMigration.restoreConfiguration(backup, configManager)
    if backup.environment ~= configManager:GetEnvironment() then
        warn("⚠️ Backup environment (" .. backup.environment .. ") does not match current environment (" .. configManager:GetEnvironment() .. ")")
    end
    
    -- Restore configurations
    for configName, config in pairs(backup.configurations) do
        configManager:RegisterConfiguration(configName, config)
    end
    
    print("✅ Configuration restored from backup (timestamp: " .. backup.timestamp .. ")")
end

function ConfigurationMigration.compareConfigurations(config1, config2)
    local differences = {}
    
    -- This would implement a deep comparison algorithm
    -- For now, return a simple comparison result
    
    return {
        identical = false,
        differences = differences,
        summary = "Configuration comparison not yet implemented"
    }
end

return ConfigurationMigration
