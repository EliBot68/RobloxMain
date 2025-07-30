-- CodeStyleLintingSystem.luau
-- Comprehensive code style guides and automated formatting/linting
-- Enforces consistent code style and quality standards across the project

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local HttpService = game:GetService("HttpService")
local RunService = game:GetService("RunService")

local SafeRequire = require(ReplicatedStorage.Shared.utils.SafeRequire)

local CodeStyleLintingSystem = {}

-- ========================================
-- CODE STYLE CONFIGURATION
-- ========================================

local STYLE_CONFIG = {
    -- Formatting rules
    formatting = {
        indentType = "spaces", -- "spaces" or "tabs"
        indentSize = 4,
        maxLineLength = 100,
        insertFinalNewline = true,
        trimTrailingWhitespace = true,
        
        -- Lua/Luau specific
        quoteStyle = "double", -- "single", "double", "auto"
        callParentheses = "always", -- "always", "no_single_string", "no_single_table"
        collapseSimpleStatement = false,
        
        -- Spacing rules
        spaceAroundOperators = true,
        spaceAfterCommas = true,
        spaceInParentheses = false,
        spaceInBrackets = false,
        spaceBeforeFunctionParens = false
    },
    
    -- Naming conventions
    naming = {
        functions = {
            style = "camelCase", -- camelCase, PascalCase, snake_case
            prefix = "",
            suffix = "",
            maxLength = 50,
            minLength = 3
        },
        variables = {
            style = "camelCase",
            prefix = "",
            suffix = "",
            maxLength = 30,
            minLength = 1
        },
        constants = {
            style = "UPPER_SNAKE_CASE",
            prefix = "",
            suffix = "",
            maxLength = 50,
            minLength = 2
        },
        classes = {
            style = "PascalCase",
            prefix = "",
            suffix = "",
            maxLength = 40,
            minLength = 3
        },
        files = {
            style = "PascalCase",
            suffix = ".luau",
            maxLength = 50,
            minLength = 3
        },
        directories = {
            style = "camelCase",
            maxLength = 30,
            minLength = 2
        }
    },
    
    -- Code structure rules
    structure = {
        maxFunctionLength = 50,
        maxFunctionParameters = 8,
        maxFileLength = 1000,
        maxComplexity = 10,
        
        requireDocumentation = {
            functions = true,
            classes = true,
            modules = true,
            publicAPIs = true
        },
        
        organizationRules = {
            groupImports = true,
            sortImports = true,
            separateLocalRequires = true,
            groupByType = true
        }
    },
    
    -- Quality rules
    quality = {
        noUnusedVariables = true,
        noUnusedParameters = true,
        noUnusedImports = true,
        noGlobalVariables = true,
        noMagicNumbers = true,
        noEmptyBlocks = true,
        noDeepNesting = 4, -- max nesting level
        
        requireTypeAnnotations = false, -- Luau type annotations
        requireReturnAnnotations = false,
        requireParameterAnnotations = false
    },
    
    -- Luau-specific rules
    luau = {
        strictMode = true,
        typeCheckingMode = "strict", -- "off", "nonstrict", "strict"
        unknownTypeErrors = true,
        
        -- Roblox-specific
        noDeprecatedAPIs = true,
        preferModernAPIs = true,
        noYieldInCallbacks = true,
        properEventHandling = true
    }
}

-- ========================================
-- STYLE SYSTEM STATE
-- ========================================

local StyleState = {
    -- Formatting engine
    formatter = nil,
    linter = nil,
    
    -- Rule sets
    activeRules = {},
    customRules = {},
    
    -- Violation tracking
    violations = {},
    fixableViolations = {},
    
    -- Performance metrics
    metrics = {
        filesProcessed = 0,
        violationsFound = 0,
        violationsFixed = 0,
        processingTime = 0
    },
    
    -- Configuration
    config = STYLE_CONFIG,
    profiles = {}
}

function CodeStyleLintingSystem.initialize()
    print("🎨 Initializing CodeStyleLintingSystem...")
    
    -- Initialize formatting engine
    CodeStyleLintingSystem.initializeFormatter()
    
    -- Initialize linting engine
    CodeStyleLintingSystem.initializeLinter()
    
    -- Set up rule system
    CodeStyleLintingSystem.setupRuleSystem()
    
    -- Create style profiles
    CodeStyleLintingSystem.createStyleProfiles()
    
    -- Initialize auto-fixing
    CodeStyleLintingSystem.initializeAutoFixer()
    
    print("🎨 CodeStyleLintingSystem initialized successfully")
end

-- ========================================
-- FORMATTING ENGINE
-- ========================================

function CodeStyleLintingSystem.initializeFormatter()
    StyleState.formatter = {
        rules = CodeStyleLintingSystem.createFormattingRules(),
        
        formatCode = function(self, code, options)
            return CodeStyleLintingSystem.formatCode(code, options)
        end,
        
        formatFile = function(self, filePath, content)
            return CodeStyleLintingSystem.formatFile(filePath, content)
        end,
        
        validateFormatting = function(self, code)
            return CodeStyleLintingSystem.validateCodeFormatting(code)
        end
    }
    
    print("📝 Code formatter initialized")
end

function CodeStyleLintingSystem.createFormattingRules()
    return {
        indentation = {
            name = "indentation",
            description = "Enforce consistent indentation",
            fix = function(code)
                return CodeStyleLintingSystem.fixIndentation(code)
            end,
            check = function(code)
                return CodeStyleLintingSystem.checkIndentation(code)
            end
        },
        
        lineLength = {
            name = "line_length",
            description = "Enforce maximum line length",
            fix = function(code)
                return CodeStyleLintingSystem.fixLineLength(code)
            end,
            check = function(code)
                return CodeStyleLintingSystem.checkLineLength(code)
            end
        },
        
        whitespace = {
            name = "whitespace",
            description = "Manage whitespace and spacing",
            fix = function(code)
                return CodeStyleLintingSystem.fixWhitespace(code)
            end,
            check = function(code)
                return CodeStyleLintingSystem.checkWhitespace(code)
            end
        },
        
        quoteStyle = {
            name = "quote_style",
            description = "Enforce consistent quote style",
            fix = function(code)
                return CodeStyleLintingSystem.fixQuoteStyle(code)
            end,
            check = function(code)
                return CodeStyleLintingSystem.checkQuoteStyle(code)
            end
        },
        
        semicolons = {
            name = "semicolons",
            description = "Manage semicolon usage",
            fix = function(code)
                return CodeStyleLintingSystem.fixSemicolons(code)
            end,
            check = function(code)
                return CodeStyleLintingSystem.checkSemicolons(code)
            end
        }
    }
end

function CodeStyleLintingSystem.formatCode(code, options)
    options = options or {}
    local config = options.config or StyleState.config.formatting
    
    local formatted = code
    local issues = {}
    
    -- Apply formatting rules in order
    local rules = {"indentation", "whitespace", "quoteStyle", "lineLength", "semicolons"}
    
    for _, ruleName in ipairs(rules) do
        local rule = StyleState.formatter.rules[ruleName]
        if rule then
            local ruleIssues = rule.check(formatted)
            if #ruleIssues > 0 then
                for _, issue in ipairs(ruleIssues) do
                    table.insert(issues, issue)
                end
                
                if options.autoFix ~= false then
                    formatted = rule.fix(formatted)
                end
            end
        end
    end
    
    return {
        code = formatted,
        issues = issues,
        changed = formatted ~= code
    }
end

function CodeStyleLintingSystem.formatFile(filePath, content)
    local startTime = tick()
    
    local result = StyleState.formatter:formatCode(content, {
        autoFix = true,
        filePath = filePath
    })
    
    local endTime = tick()
    
    StyleState.metrics.filesProcessed = StyleState.metrics.filesProcessed + 1
    StyleState.metrics.processingTime = StyleState.metrics.processingTime + (endTime - startTime)
    
    if #result.issues > 0 then
        StyleState.metrics.violationsFound = StyleState.metrics.violationsFound + #result.issues
        if result.changed then
            StyleState.metrics.violationsFixed = StyleState.metrics.violationsFixed + #result.issues
        end
    end
    
    return result
end

-- ========================================
-- FORMATTING RULE IMPLEMENTATIONS
-- ========================================

function CodeStyleLintingSystem.fixIndentation(code)
    local config = StyleState.config.formatting
    local lines = code:split("\n")
    local formatted = {}
    local indentLevel = 0
    
    local indentString = config.indentType == "tabs" and "\t" or string.rep(" ", config.indentSize)
    
    for _, line in ipairs(lines) do
        local trimmed = line:match("^%s*(.-)%s*$")
        
        -- Decrease indent for end keywords
        if trimmed:match("^end%s*$") or trimmed:match("^else%s*$") or 
           trimmed:match("^elseif%s+") or trimmed:match("^until%s+") then
            indentLevel = math.max(0, indentLevel - 1)
        end
        
        -- Apply indentation
        local formatted_line = string.rep(indentString, indentLevel) .. trimmed
        table.insert(formatted, formatted_line)
        
        -- Increase indent for block keywords
        if trimmed:match("^function%s*") or trimmed:match("^if%s+") or 
           trimmed:match("^for%s+") or trimmed:match("^while%s+") or
           trimmed:match("^repeat%s*$") or trimmed:match("^else%s*$") or
           trimmed:match("^elseif%s+") then
            indentLevel = indentLevel + 1
        end
        
        -- Handle table and function definitions
        if trimmed:match("{%s*$") or trimmed:match("function%s*%(") then
            indentLevel = indentLevel + 1
        end
        if trimmed:match("^%s*}") then
            indentLevel = math.max(0, indentLevel - 1)
        end
    end
    
    return table.concat(formatted, "\n")
end

function CodeStyleLintingSystem.checkIndentation(code)
    local config = StyleState.config.formatting
    local issues = {}
    local lines = code:split("\n")
    
    for lineNum, line in ipairs(lines) do
        if line:match("^%s+") then
            local leadingWhitespace = line:match("^(%s+)")
            
            if config.indentType == "spaces" then
                if leadingWhitespace:find("\t") then
                    table.insert(issues, {
                        line = lineNum,
                        message = "Use spaces for indentation, not tabs",
                        type = "indentation",
                        fixable = true
                    })
                elseif #leadingWhitespace % config.indentSize ~= 0 then
                    table.insert(issues, {
                        line = lineNum,
                        message = string.format("Indentation should be multiples of %d spaces", config.indentSize),
                        type = "indentation",
                        fixable = true
                    })
                end
            elseif config.indentType == "tabs" then
                if leadingWhitespace:find(" ") then
                    table.insert(issues, {
                        line = lineNum,
                        message = "Use tabs for indentation, not spaces",
                        type = "indentation",
                        fixable = true
                    })
                end
            end
        end
    end
    
    return issues
end

function CodeStyleLintingSystem.fixLineLength(code)
    local config = StyleState.config.formatting
    local lines = code:split("\n")
    local formatted = {}
    
    for _, line in ipairs(lines) do
        if #line > config.maxLineLength then
            -- Try to break line at logical points
            local broken = CodeStyleLintingSystem.breakLongLine(line, config.maxLineLength)
            for _, brokenLine in ipairs(broken) do
                table.insert(formatted, brokenLine)
            end
        else
            table.insert(formatted, line)
        end
    end
    
    return table.concat(formatted, "\n")
end

function CodeStyleLintingSystem.breakLongLine(line, maxLength)
    -- Simple line breaking at commas and operators
    local broken = {}
    local current = line
    
    while #current > maxLength do
        local breakPoint = CodeStyleLintingSystem.findBreakPoint(current, maxLength)
        if breakPoint > 0 then
            table.insert(broken, current:sub(1, breakPoint))
            current = string.rep(" ", 4) .. current:sub(breakPoint + 1):match("^%s*(.*)$")
        else
            -- Can't break, keep as is
            table.insert(broken, current)
            break
        end
    end
    
    if #current > 0 then
        table.insert(broken, current)
    end
    
    return broken
end

function CodeStyleLintingSystem.findBreakPoint(line, maxLength)
    -- Look for good break points within maxLength
    local bestBreak = 0
    local breakChars = {",", "and", "or", "+", "-", "*", "/", "==", "~=", "<=", ">="}
    
    for _, breakChar in ipairs(breakChars) do
        local pos = line:find(breakChar, 1, true)
        while pos and pos <= maxLength do
            bestBreak = pos
            pos = line:find(breakChar, pos + 1, true)
        end
    end
    
    return bestBreak
end

function CodeStyleLintingSystem.checkLineLength(code)
    local config = StyleState.config.formatting
    local issues = {}
    local lines = code:split("\n")
    
    for lineNum, line in ipairs(lines) do
        if #line > config.maxLineLength then
            table.insert(issues, {
                line = lineNum,
                message = string.format("Line too long (%d > %d characters)", #line, config.maxLineLength),
                type = "line_length",
                fixable = true
            })
        end
    end
    
    return issues
end

function CodeStyleLintingSystem.fixWhitespace(code)
    local config = StyleState.config.formatting
    local formatted = code
    
    -- Remove trailing whitespace
    if config.trimTrailingWhitespace then
        formatted = formatted:gsub("%s+\n", "\n")
    end
    
    -- Add final newline
    if config.insertFinalNewline and not formatted:match("\n$") then
        formatted = formatted .. "\n"
    end
    
    -- Fix spacing around operators
    if config.spaceAroundOperators then
        formatted = formatted:gsub("([%w_])([+%-*/%^=<>])([%w_])", "%1 %2 %3")
        formatted = formatted:gsub("([%w_])([=<>!]=?)([%w_])", "%1 %2 %3")
    end
    
    -- Fix spacing after commas
    if config.spaceAfterCommas then
        formatted = formatted:gsub(",([%w_])", ", %1")
    end
    
    return formatted
end

function CodeStyleLintingSystem.checkWhitespace(code)
    local config = StyleState.config.formatting
    local issues = {}
    local lines = code:split("\n")
    
    for lineNum, line in ipairs(lines) do
        -- Check trailing whitespace
        if config.trimTrailingWhitespace and line:match("%s+$") then
            table.insert(issues, {
                line = lineNum,
                message = "Trailing whitespace found",
                type = "whitespace",
                fixable = true
            })
        end
        
        -- Check spacing around operators
        if config.spaceAroundOperators then
            if line:match("[%w_][+%-*/%^=<>][%w_]") then
                table.insert(issues, {
                    line = lineNum,
                    message = "Missing spaces around operators",
                    type = "whitespace",
                    fixable = true
                })
            end
        end
        
        -- Check spacing after commas
        if config.spaceAfterCommas then
            if line:match(",[%w_]") then
                table.insert(issues, {
                    line = lineNum,
                    message = "Missing space after comma",
                    type = "whitespace",
                    fixable = true
                })
            end
        end
    end
    
    return issues
end

function CodeStyleLintingSystem.fixQuoteStyle(code)
    local config = StyleState.config.formatting
    local formatted = code
    
    if config.quoteStyle == "double" then
        -- Convert single quotes to double quotes (simple implementation)
        formatted = formatted:gsub("'([^']*)'", '"%1"')
    elseif config.quoteStyle == "single" then
        -- Convert double quotes to single quotes
        formatted = formatted:gsub('"([^"]*)"', "'%1'")
    end
    
    return formatted
end

function CodeStyleLintingSystem.checkQuoteStyle(code)
    local config = StyleState.config.formatting
    local issues = {}
    local lines = code:split("\n")
    
    for lineNum, line in ipairs(lines) do
        if config.quoteStyle == "double" then
            if line:match("'[^']*'") then
                table.insert(issues, {
                    line = lineNum,
                    message = "Use double quotes for strings",
                    type = "quote_style",
                    fixable = true
                })
            end
        elseif config.quoteStyle == "single" then
            if line:match('"[^"]*"') then
                table.insert(issues, {
                    line = lineNum,
                    message = "Use single quotes for strings",
                    type = "quote_style",
                    fixable = true
                })
            end
        end
    end
    
    return issues
end

function CodeStyleLintingSystem.fixSemicolons(code)
    -- Remove unnecessary semicolons (Lua doesn't require them)
    return code:gsub(";%s*\n", "\n")
end

function CodeStyleLintingSystem.checkSemicolons(code)
    local issues = {}
    local lines = code:split("\n")
    
    for lineNum, line in ipairs(lines) do
        if line:match(";%s*$") then
            table.insert(issues, {
                line = lineNum,
                message = "Unnecessary semicolon (Lua doesn't require semicolons)",
                type = "semicolons",
                fixable = true
            })
        end
    end
    
    return issues
end

-- ========================================
-- LINTING ENGINE
-- ========================================

function CodeStyleLintingSystem.initializeLinter()
    StyleState.linter = {
        rules = CodeStyleLintingSystem.createLintingRules(),
        
        lintCode = function(self, code, options)
            return CodeStyleLintingSystem.lintCode(code, options)
        end,
        
        lintFile = function(self, filePath, content)
            return CodeStyleLintingSystem.lintFile(filePath, content)
        end,
        
        validateCode = function(self, code)
            return CodeStyleLintingSystem.validateCodeQuality(code)
        end
    }
    
    print("🔍 Code linter initialized")
end

function CodeStyleLintingSystem.createLintingRules()
    return {
        namingConventions = {
            name = "naming_conventions",
            description = "Enforce naming conventions",
            severity = "warning",
            check = function(code)
                return CodeStyleLintingSystem.checkNamingConventions(code)
            end
        },
        
        unusedVariables = {
            name = "unused_variables",
            description = "Detect unused variables",
            severity = "warning",
            check = function(code)
                return CodeStyleLintingSystem.checkUnusedVariables(code)
            end
        },
        
        complexityCheck = {
            name = "complexity_check",
            description = "Check code complexity",
            severity = "warning",
            check = function(code)
                return CodeStyleLintingSystem.checkComplexity(code)
            end
        },
        
        magicNumbers = {
            name = "magic_numbers",
            description = "Detect magic numbers",
            severity = "info",
            check = function(code)
                return CodeStyleLintingSystem.checkMagicNumbers(code)
            end
        },
        
        documentation = {
            name = "documentation",
            description = "Check documentation completeness",
            severity = "warning",
            check = function(code)
                return CodeStyleLintingSystem.checkDocumentation(code)
            end
        },
        
        luauSpecific = {
            name = "luau_specific",
            description = "Luau-specific checks",
            severity = "error",
            check = function(code)
                return CodeStyleLintingSystem.checkLuauSpecific(code)
            end
        }
    }
end

function CodeStyleLintingSystem.lintCode(code, options)
    options = options or {}
    local issues = {}
    
    -- Run all enabled linting rules
    for ruleName, rule in pairs(StyleState.linter.rules) do
        if not options.disabledRules or not options.disabledRules[ruleName] then
            local ruleIssues = rule.check(code)
            for _, issue in ipairs(ruleIssues) do
                issue.rule = ruleName
                issue.severity = rule.severity
                table.insert(issues, issue)
            end
        end
    end
    
    return issues
end

function CodeStyleLintingSystem.lintFile(filePath, content)
    local startTime = tick()
    
    local issues = StyleState.linter:lintCode(content, {
        filePath = filePath
    })
    
    local endTime = tick()
    
    -- Update metrics
    StyleState.metrics.filesProcessed = StyleState.metrics.filesProcessed + 1
    StyleState.metrics.violationsFound = StyleState.metrics.violationsFound + #issues
    StyleState.metrics.processingTime = StyleState.metrics.processingTime + (endTime - startTime)
    
    return issues
end

-- ========================================
-- LINTING RULE IMPLEMENTATIONS
-- ========================================

function CodeStyleLintingSystem.checkNamingConventions(code)
    local config = StyleState.config.naming
    local issues = {}
    local lines = code:split("\n")
    
    for lineNum, line in ipairs(lines) do
        -- Check function names
        local funcName = line:match("function%s+([%w_]+)")
        if funcName then
            local valid = CodeStyleLintingSystem.validateNaming(funcName, config.functions)
            if not valid.isValid then
                table.insert(issues, {
                    line = lineNum,
                    message = string.format("Function name '%s' %s", funcName, valid.reason),
                    type = "naming_conventions"
                })
            end
        end
        
        -- Check variable names (local declarations)
        local varName = line:match("local%s+([%w_]+)")
        if varName then
            local valid = CodeStyleLintingSystem.validateNaming(varName, config.variables)
            if not valid.isValid then
                table.insert(issues, {
                    line = lineNum,
                    message = string.format("Variable name '%s' %s", varName, valid.reason),
                    type = "naming_conventions"
                })
            end
        end
        
        -- Check constant names (uppercase variables)
        local constName = line:match("local%s+([A-Z_][A-Z0-9_]*)")
        if constName then
            local valid = CodeStyleLintingSystem.validateNaming(constName, config.constants)
            if not valid.isValid then
                table.insert(issues, {
                    line = lineNum,
                    message = string.format("Constant name '%s' %s", constName, valid.reason),
                    type = "naming_conventions"
                })
            end
        end
    end
    
    return issues
end

function CodeStyleLintingSystem.validateNaming(name, rules)
    if #name < rules.minLength then
        return {isValid = false, reason = string.format("is too short (minimum %d characters)", rules.minLength)}
    end
    
    if #name > rules.maxLength then
        return {isValid = false, reason = string.format("is too long (maximum %d characters)", rules.maxLength)}
    end
    
    if rules.style == "camelCase" then
        if not name:match("^[a-z][a-zA-Z0-9]*$") then
            return {isValid = false, reason = "should use camelCase"}
        end
    elseif rules.style == "PascalCase" then
        if not name:match("^[A-Z][a-zA-Z0-9]*$") then
            return {isValid = false, reason = "should use PascalCase"}
        end
    elseif rules.style == "snake_case" then
        if not name:match("^[a-z][a-z0-9_]*$") then
            return {isValid = false, reason = "should use snake_case"}
        end
    elseif rules.style == "UPPER_SNAKE_CASE" then
        if not name:match("^[A-Z][A-Z0-9_]*$") then
            return {isValid = false, reason = "should use UPPER_SNAKE_CASE"}
        end
    end
    
    return {isValid = true}
end

function CodeStyleLintingSystem.checkUnusedVariables(code)
    local issues = {}
    local lines = code:split("\n")
    local declaredVars = {}
    local usedVars = {}
    
    -- Find declared variables
    for lineNum, line in ipairs(lines) do
        local varName = line:match("local%s+([%w_]+)")
        if varName then
            declaredVars[varName] = lineNum
        end
    end
    
    -- Find variable usage
    for _, line in ipairs(lines) do
        for varName, _ in pairs(declaredVars) do
            if line:find(varName) and not line:match("local%s+" .. varName) then
                usedVars[varName] = true
            end
        end
    end
    
    -- Report unused variables
    for varName, lineNum in pairs(declaredVars) do
        if not usedVars[varName] then
            table.insert(issues, {
                line = lineNum,
                message = string.format("Variable '%s' is declared but never used", varName),
                type = "unused_variables"
            })
        end
    end
    
    return issues
end

function CodeStyleLintingSystem.checkComplexity(code)
    local config = StyleState.config.structure
    local issues = {}
    local lines = code:split("\n")
    
    local currentFunction = nil
    local functionStart = 0
    local complexity = 0
    local nestingLevel = 0
    
    for lineNum, line in ipairs(lines) do
        local trimmed = line:match("^%s*(.-)%s*$")
        
        -- Track function boundaries
        if trimmed:match("^function") then
            currentFunction = trimmed:match("function%s+([%w_.]+)") or "anonymous"
            functionStart = lineNum
            complexity = 1 -- Base complexity
            nestingLevel = 0
        elseif trimmed:match("^end") and currentFunction then
            -- Check function length
            local functionLength = lineNum - functionStart
            if functionLength > config.maxFunctionLength then
                table.insert(issues, {
                    line = functionStart,
                    message = string.format("Function '%s' is too long (%d > %d lines)", 
                        currentFunction, functionLength, config.maxFunctionLength),
                    type = "complexity_check"
                })
            end
            
            -- Check complexity
            if complexity > config.maxComplexity then
                table.insert(issues, {
                    line = functionStart,
                    message = string.format("Function '%s' is too complex (complexity %d > %d)", 
                        currentFunction, complexity, config.maxComplexity),
                    type = "complexity_check"
                })
            end
            
            currentFunction = nil
        end
        
        if currentFunction then
            -- Count complexity-increasing constructs
            if trimmed:match("^if") or trimmed:match("^while") or trimmed:match("^for") then
                complexity = complexity + 1
                nestingLevel = nestingLevel + 1
            elseif trimmed:match("^elseif") then
                complexity = complexity + 1
            elseif trimmed:match("^end") then
                nestingLevel = math.max(0, nestingLevel - 1)
            end
            
            -- Check nesting level
            if nestingLevel > STYLE_CONFIG.quality.noDeepNesting then
                table.insert(issues, {
                    line = lineNum,
                    message = string.format("Code is nested too deeply (level %d > %d)", 
                        nestingLevel, STYLE_CONFIG.quality.noDeepNesting),
                    type = "complexity_check"
                })
            end
        end
    end
    
    return issues
end

function CodeStyleLintingSystem.checkMagicNumbers(code)
    local issues = {}
    local lines = code:split("\n")
    
    -- Common non-magic numbers to ignore
    local allowedNumbers = {0, 1, 2, 10, 100, 1000}
    local allowedSet = {}
    for _, num in ipairs(allowedNumbers) do
        allowedSet[num] = true
    end
    
    for lineNum, line in ipairs(lines) do
        -- Find numeric literals
        for number in line:gmatch("([%d%.]+)") do
            local num = tonumber(number)
            if num and not allowedSet[num] then
                table.insert(issues, {
                    line = lineNum,
                    message = string.format("Magic number '%s' should be replaced with a named constant", number),
                    type = "magic_numbers"
                })
            end
        end
    end
    
    return issues
end

function CodeStyleLintingSystem.checkDocumentation(code)
    local config = StyleState.config.structure.requireDocumentation
    local issues = {}
    local lines = code:split("\n")
    
    for lineNum, line in ipairs(lines) do
        local trimmed = line:match("^%s*(.-)%s*$")
        
        -- Check function documentation
        if config.functions and trimmed:match("^function%s+([%w_.]+)") then
            local funcName = trimmed:match("function%s+([%w_.]+)")
            
            -- Look for documentation comment above function
            local hasDoc = false
            if lineNum > 1 then
                local prevLine = lines[lineNum - 1]:match("^%s*(.-)%s*$")
                if prevLine:match("^%-%-") then
                    hasDoc = true
                end
            end
            
            if not hasDoc then
                table.insert(issues, {
                    line = lineNum,
                    message = string.format("Function '%s' is missing documentation", funcName),
                    type = "documentation"
                })
            end
        end
    end
    
    return issues
end

function CodeStyleLintingSystem.checkLuauSpecific(code)
    local config = StyleState.config.luau
    local issues = {}
    local lines = code:split("\n")
    
    for lineNum, line in ipairs(lines) do
        -- Check for deprecated Roblox APIs (simplified)
        if config.noDeprecatedAPIs then
            local deprecatedAPIs = {"FindFirstChild", "WaitForChild"}
            for _, api in ipairs(deprecatedAPIs) do
                if line:find(api) and line:find("%(") then
                    -- This is a very basic check - real implementation would be more sophisticated
                    if api == "FindFirstChild" and not line:find("true") then
                        table.insert(issues, {
                            line = lineNum,
                            message = "Consider using FindFirstChild with recursive parameter for better performance",
                            type = "luau_specific"
                        })
                    end
                end
            end
        end
        
        -- Check for yield in callbacks
        if config.noYieldInCallbacks then
            if line:match("Connect%(function") and line:match("wait%(") then
                table.insert(issues, {
                    line = lineNum,
                    message = "Avoid yielding in event callbacks - use spawn() or task.spawn()",
                    type = "luau_specific"
                })
            end
        end
    end
    
    return issues
end

-- ========================================
-- RULE SYSTEM
-- ========================================

function CodeStyleLintingSystem.setupRuleSystem()
    StyleState.ruleManager = {
        enabledRules = {},
        disabledRules = {},
        customRules = {},
        
        enableRule = function(self, ruleName)
            self.enabledRules[ruleName] = true
            self.disabledRules[ruleName] = nil
        end,
        
        disableRule = function(self, ruleName)
            self.disabledRules[ruleName] = true
            self.enabledRules[ruleName] = nil
        end,
        
        addCustomRule = function(self, rule)
            self.customRules[rule.name] = rule
        end
    }
    
    -- Enable all rules by default
    for ruleName, _ in pairs(StyleState.formatter.rules) do
        StyleState.ruleManager:enableRule(ruleName)
    end
    
    for ruleName, _ in pairs(StyleState.linter.rules) do
        StyleState.ruleManager:enableRule(ruleName)
    end
    
    print("📋 Rule system initialized")
end

-- ========================================
-- STYLE PROFILES
-- ========================================

function CodeStyleLintingSystem.createStyleProfiles()
    StyleState.profiles = {
        strict = {
            name = "Strict",
            description = "Strict formatting and linting rules",
            config = CodeStyleLintingSystem.createStrictProfile()
        },
        
        relaxed = {
            name = "Relaxed", 
            description = "Relaxed rules for faster development",
            config = CodeStyleLintingSystem.createRelaxedProfile()
        },
        
        roblox = {
            name = "Roblox",
            description = "Roblox-specific best practices",
            config = CodeStyleLintingSystem.createRobloxProfile()
        },
        
        mobile = {
            name = "Mobile",
            description = "Mobile game development optimized",
            config = CodeStyleLintingSystem.createMobileProfile()
        }
    }
    
    print("📋 Style profiles created")
end

function CodeStyleLintingSystem.createStrictProfile()
    local strictConfig = {}
    
    -- Copy base config and make it stricter
    for section, rules in pairs(STYLE_CONFIG) do
        strictConfig[section] = {}
        for key, value in pairs(rules) do
            strictConfig[section][key] = value
        end
    end
    
    -- Override with stricter rules
    strictConfig.formatting.maxLineLength = 80
    strictConfig.structure.maxFunctionLength = 30
    strictConfig.structure.maxComplexity = 5
    strictConfig.quality.requireTypeAnnotations = true
    strictConfig.quality.requireReturnAnnotations = true
    
    return strictConfig
end

function CodeStyleLintingSystem.createRelaxedProfile()
    local relaxedConfig = {}
    
    -- Copy base config and make it more relaxed
    for section, rules in pairs(STYLE_CONFIG) do
        relaxedConfig[section] = {}
        for key, value in pairs(rules) do
            relaxedConfig[section][key] = value
        end
    end
    
    -- Override with relaxed rules
    relaxedConfig.formatting.maxLineLength = 120
    relaxedConfig.structure.maxFunctionLength = 80
    relaxedConfig.structure.maxComplexity = 15
    relaxedConfig.quality.noMagicNumbers = false
    
    return relaxedConfig
end

function CodeStyleLintingSystem.createRobloxProfile()
    local robloxConfig = {}
    
    -- Copy base config
    for section, rules in pairs(STYLE_CONFIG) do
        robloxConfig[section] = {}
        for key, value in pairs(rules) do
            robloxConfig[section][key] = value
        end
    end
    
    -- Roblox-specific overrides
    robloxConfig.luau.strictMode = true
    robloxConfig.luau.noDeprecatedAPIs = true
    robloxConfig.luau.preferModernAPIs = true
    robloxConfig.luau.noYieldInCallbacks = true
    
    return robloxConfig
end

function CodeStyleLintingSystem.createMobileProfile()
    local mobileConfig = {}
    
    -- Copy base config
    for section, rules in pairs(STYLE_CONFIG) do
        mobileConfig[section] = {}
        for key, value in pairs(rules) do
            mobileConfig[section][key] = value
        end
    end
    
    -- Mobile-specific overrides
    mobileConfig.structure.maxComplexity = 8
    mobileConfig.quality.requireTypeAnnotations = true
    mobileConfig.formatting.maxLineLength = 90
    
    return mobileConfig
end

-- ========================================
-- AUTO-FIXER
-- ========================================

function CodeStyleLintingSystem.initializeAutoFixer()
    StyleState.autoFixer = {
        fixableRules = {},
        
        fixCode = function(self, code, issues)
            return CodeStyleLintingSystem.autoFixCode(code, issues)
        end,
        
        canFix = function(self, issue)
            return issue.fixable == true
        end
    }
    
    -- Register fixable rules
    for ruleName, rule in pairs(StyleState.formatter.rules) do
        StyleState.autoFixer.fixableRules[ruleName] = rule.fix
    end
    
    print("🔧 Auto-fixer initialized")
end

function CodeStyleLintingSystem.autoFixCode(code, issues)
    local fixed = code
    local fixedIssues = {}
    
    -- Sort issues by line number (descending) to avoid position shifts
    table.sort(issues, function(a, b) return (a.line or 0) > (b.line or 0) end)
    
    for _, issue in ipairs(issues) do
        if StyleState.autoFixer:canFix(issue) then
            local fixerRule = StyleState.autoFixer.fixableRules[issue.type]
            if fixerRule then
                fixed = fixerRule(fixed)
                table.insert(fixedIssues, issue)
                StyleState.metrics.violationsFixed = StyleState.metrics.violationsFixed + 1
            end
        end
    end
    
    return {
        code = fixed,
        fixedIssues = fixedIssues,
        unfixedIssues = CodeStyleLintingSystem.filterUnfixed(issues, fixedIssues)
    }
end

function CodeStyleLintingSystem.filterUnfixed(allIssues, fixedIssues)
    local unfixed = {}
    local fixedSet = {}
    
    for _, fixed in ipairs(fixedIssues) do
        fixedSet[fixed] = true
    end
    
    for _, issue in ipairs(allIssues) do
        if not fixedSet[issue] then
            table.insert(unfixed, issue)
        end
    end
    
    return unfixed
end

-- ========================================
-- PUBLIC API
-- ========================================

function CodeStyleLintingSystem.formatCode(code, options)
    return StyleState.formatter:formatCode(code, options)
end

function CodeStyleLintingSystem.lintCode(code, options)
    return StyleState.linter:lintCode(code, options)
end

function CodeStyleLintingSystem.formatAndLintCode(code, options)
    options = options or {}
    
    -- Format first
    local formatResult = StyleState.formatter:formatCode(code, options)
    
    -- Then lint
    local lintIssues = StyleState.linter:lintCode(formatResult.code, options)
    
    -- Auto-fix if requested
    local finalCode = formatResult.code
    local fixedIssues = {}
    
    if options.autoFix then
        local fixResult = StyleState.autoFixer:fixCode(formatResult.code, lintIssues)
        finalCode = fixResult.code
        fixedIssues = fixResult.fixedIssues
        lintIssues = fixResult.unfixedIssues
    end
    
    return {
        code = finalCode,
        formatIssues = formatResult.issues,
        lintIssues = lintIssues,
        fixedIssues = fixedIssues,
        changed = finalCode ~= code
    }
end

function CodeStyleLintingSystem.setProfile(profileName)
    local profile = StyleState.profiles[profileName]
    if profile then
        StyleState.config = profile.config
        print(string.format("🎨 Style profile set to: %s", profile.name))
        return true
    else
        warn(string.format("Style profile not found: %s", profileName))
        return false
    end
end

function CodeStyleLintingSystem.getProfiles()
    local profileList = {}
    for name, profile in pairs(StyleState.profiles) do
        table.insert(profileList, {
            name = name,
            displayName = profile.name,
            description = profile.description
        })
    end
    return profileList
end

function CodeStyleLintingSystem.getMetrics()
    return StyleState.metrics
end

function CodeStyleLintingSystem.resetMetrics()
    StyleState.metrics = {
        filesProcessed = 0,
        violationsFound = 0,
        violationsFixed = 0,
        processingTime = 0
    }
end

function CodeStyleLintingSystem.runCodeStyleDemo()
    print("🎨 Running code style and linting demonstration...")
    
    -- Show style configuration
    print("  📋 Style Configuration:")
    local config = StyleState.config.formatting
    print(string.format("    Indent Type: %s (%d spaces)", config.indentType, config.indentSize))
    print(string.format("    Max Line Length: %d", config.maxLineLength))
    print(string.format("    Quote Style: %s quotes", config.quoteStyle))
    print(string.format("    Trim Trailing Whitespace: %s", config.trimTrailingWhitespace and "Yes" or "No"))
    
    -- Show naming conventions
    print("  📝 Naming Conventions:")
    local naming = StyleState.config.naming
    print(string.format("    Functions: %s", naming.functions.style))
    print(string.format("    Variables: %s", naming.variables.style))
    print(string.format("    Constants: %s", naming.constants.style))
    print(string.format("    Classes: %s", naming.classes.style))
    
    -- Demonstrate formatting
    print("  🔧 Code Formatting Example:")
    local sampleCode = [[function   badlyFormatted( param1,param2 )
local  x=param1+param2
if x>10 then
return x
end
end;]]
    
    print("    Before formatting:")
    local beforeLines = sampleCode:split("\n")
    for i, line in ipairs(beforeLines) do
        print(string.format("      %d: %s", i, line))
    end
    
    local formatResult = CodeStyleLintingSystem.formatCode(sampleCode, {autoFix = true})
    print("    After formatting:")
    local afterLines = formatResult.code:split("\n")
    for i, line in ipairs(afterLines) do
        print(string.format("      %d: %s", i, line))
    end
    
    print(string.format("    Issues found and fixed: %d", #formatResult.issues))
    
    -- Demonstrate linting
    print("  🔍 Code Linting Example:")
    local lintSample = [[function veryLongFunctionNameThatViolatesConventions()
    local unusedVariable = 42
    local MAGIC_NUMBER = 12345
    
    if true then
        if true then
            if true then
                if true then
                    if true then
                        print("Too deep nesting")
                    end
                end
            end
        end
    end
end]]
    
    local lintIssues = CodeStyleLintingSystem.lintCode(lintSample)
    print(string.format("    Linting issues found: %d", #lintIssues))
    
    for i, issue in ipairs(lintIssues) do
        if i <= 3 then -- Show first 3 issues
            print(string.format("      Line %d: %s (%s)", issue.line, issue.message, issue.type))
        end
    end
    if #lintIssues > 3 then
        print(string.format("      ... and %d more issues", #lintIssues - 3))
    end
    
    -- Show available profiles
    print("  📋 Available Style Profiles:")
    for _, profile in ipairs(CodeStyleLintingSystem.getProfiles()) do
        print(string.format("    %s: %s", profile.displayName, profile.description))
    end
    
    -- Demonstrate profile switching
    print("  🔄 Profile Switching Demo:")
    local originalProfile = "default"
    print(string.format("    Current profile: %s", originalProfile))
    
    CodeStyleLintingSystem.setProfile("strict")
    print("    Switched to strict profile")
    
    CodeStyleLintingSystem.setProfile("relaxed")
    print("    Switched to relaxed profile")
    
    -- Show metrics
    print("  📊 Processing Metrics:")
    local metrics = CodeStyleLintingSystem.getMetrics()
    print(string.format("    Files Processed: %d", metrics.filesProcessed))
    print(string.format("    Violations Found: %d", metrics.violationsFound))
    print(string.format("    Violations Fixed: %d", metrics.violationsFixed))
    print(string.format("    Processing Time: %.3fs", metrics.processingTime))
    
    -- Show auto-fix capabilities
    print("  🔧 Auto-Fix Capabilities:")
    print("    ✅ Indentation and whitespace")
    print("    ✅ Line length (with smart breaking)")
    print("    ✅ Quote style consistency")
    print("    ✅ Semicolon removal")
    print("    ✅ Operator spacing")
    print("    ⚠️ Naming conventions (detection only)")
    print("    ⚠️ Complexity issues (detection only)")
    
    print("🎨 Code style and linting demonstration completed")
    print("     Comprehensive code quality enforcement operational!")
end

-- Initialize the code style and linting system
CodeStyleLintingSystem.initialize()

print("🎨 CodeStyleLintingSystem loaded with comprehensive style enforcement and linting")

return CodeStyleLintingSystem
