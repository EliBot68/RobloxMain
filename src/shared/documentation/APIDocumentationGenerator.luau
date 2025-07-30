-- APIDocumentationGenerator.luau
-- Comprehensive API documentation with interactive examples
-- Automatically generates documentation for all game systems and APIs

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local StarterGui = game:GetService("StarterGui")

local SafeRequire = require(ReplicatedStorage.Shared.utils.SafeRequire)

local APIDocumentationGenerator = {}

-- ========================================
-- DOCUMENTATION CONFIGURATION
-- ========================================

local DOC_CONFIG = {
    -- Documentation settings
    documentation = {
        outputFormat = "markdown", -- markdown, html, json
        includeExamples = true,
        includeTypeInfo = true,
        includePerformanceNotes = true,
        generateInteractiveDemos = true,
        
        languages = {"lua", "luau"},
        themes = {"light", "dark", "auto"},
        searchEnabled = true,
        navigationEnabled = true
    },
    
    -- API analysis settings
    analysis = {
        includePrivateMethods = false,
        includeDeprecatedAPIs = true,
        validateExamples = true,
        generateTypeDefinitions = true,
        
        extractionPatterns = {
            functions = "function%s+([%w%.]+)%(([^)]*)%)",
            comments = "%-%-([^\n]*)",
            types = ":%s*([%w%.]+)",
            returns = "return%s+([^\n]*)"
        }
    },
    
    -- Interactive examples configuration
    interactiveExamples = {
        enabled = true,
        runInSandbox = true,
        showOutput = true,
        allowModification = true,
        
        defaultExamples = {
            "basic_usage",
            "advanced_usage",
            "error_handling",
            "performance_optimization"
        }
    },
    
    -- Documentation structure
    structure = {
        sections = {
            "overview",
            "quick_start",
            "api_reference",
            "examples",
            "best_practices",
            "troubleshooting",
            "changelog"
        },
        
        apiSections = {
            "description",
            "parameters",
            "returns",
            "examples",
            "notes",
            "see_also"
        }
    }
}

-- ========================================
-- DOCUMENTATION STATE
-- ========================================

local DocState = {
    -- System registry
    registeredSystems = {},
    generatedDocs = {},
    
    -- Analysis results
    analysisResults = {
        functions = {},
        classes = {},
        types = {},
        constants = {}
    },
    
    -- Interactive examples
    examples = {},
    demos = {},
    
    -- Documentation metadata
    metadata = {
        generationTime = 0,
        version = "1.0.0",
        lastUpdate = 0,
        totalAPIs = 0
    }
}

function APIDocumentationGenerator.initialize()
    print("📚 Initializing APIDocumentationGenerator...")
    
    -- Initialize documentation system
    APIDocumentationGenerator.setupDocumentationSystem()
    
    -- Register game systems for documentation
    APIDocumentationGenerator.registerGameSystems()
    
    -- Generate API documentation
    APIDocumentationGenerator.generateComprehensiveDocumentation()
    
    -- Create interactive documentation interface
    APIDocumentationGenerator.createDocumentationInterface()
    
    -- Set up automated documentation updates
    APIDocumentationGenerator.setupAutomatedUpdates()
    
    print("📚 APIDocumentationGenerator initialized successfully")
end

-- ========================================
-- DOCUMENTATION SYSTEM SETUP
-- ========================================

function APIDocumentationGenerator.setupDocumentationSystem()
    DocState.documentationEngine = {
        parsers = APIDocumentationGenerator.createParsers(),
        generators = APIDocumentationGenerator.createGenerators(),
        formatters = APIDocumentationGenerator.createFormatters(),
        
        analyzeSystem = function(self, systemName, systemModule)
            return APIDocumentationGenerator.analyzeSystemAPI(systemName, systemModule)
        end,
        
        generateDocumentation = function(self, analysis)
            return APIDocumentationGenerator.generateSystemDocumentation(analysis)
        end,
        
        createInteractiveExample = function(self, apiInfo, exampleCode)
            return APIDocumentationGenerator.createInteractiveExample(apiInfo, exampleCode)
        end
    }
    
    print("📝 Documentation engine initialized")
end

function APIDocumentationGenerator.createParsers()
    return {
        luauParser = {
            name = "luau_parser",
            
            parseFile = function(self, filePath, content)
                local analysis = {
                    functions = {},
                    classes = {},
                    types = {},
                    comments = {},
                    exports = {}
                }
                
                -- Parse functions
                for funcName, params in content:gmatch(DOC_CONFIG.analysis.extractionPatterns.functions) do
                    table.insert(analysis.functions, {
                        name = funcName,
                        parameters = self:parseParameters(params),
                        file = filePath,
                        line = 0 -- Would calculate actual line number
                    })
                end
                
                -- Parse comments
                for comment in content:gmatch(DOC_CONFIG.analysis.extractionPatterns.comments) do
                    table.insert(analysis.comments, comment:match("^%s*(.-)%s*$"))
                end
                
                return analysis
            end,
            
            parseParameters = function(self, paramString)
                local params = {}
                for param in paramString:gmatch("([^,]+)") do
                    local cleanParam = param:match("^%s*(.-)%s*$")
                    local name, type = cleanParam:match("([%w_]+)%s*:%s*([%w%.]+)")
                    
                    table.insert(params, {
                        name = name or cleanParam,
                        type = type or "any",
                        optional = cleanParam:find("%?") ~= nil
                    })
                end
                return params
            end
        },
        
        commentParser = {
            name = "comment_parser",
            
            parseDocComment = function(self, comment)
                local docInfo = {
                    description = "",
                    parameters = {},
                    returns = "",
                    examples = {},
                    tags = {}
                }
                
                -- Parse JSDoc-style comments
                local lines = comment:split("\n")
                local currentSection = "description"
                
                for _, line in ipairs(lines) do
                    local cleanLine = line:match("^%s*%-%-%s*(.*)") or line
                    
                    if cleanLine:match("^@param") then
                        local param = self:parseParamTag(cleanLine)
                        if param then
                            table.insert(docInfo.parameters, param)
                        end
                    elseif cleanLine:match("^@return") then
                        docInfo.returns = cleanLine:match("^@return%s+(.*)")
                    elseif cleanLine:match("^@example") then
                        currentSection = "example"
                    elseif currentSection == "example" then
                        table.insert(docInfo.examples, cleanLine)
                    elseif currentSection == "description" then
                        docInfo.description = docInfo.description .. cleanLine .. "\n"
                    end
                end
                
                return docInfo
            end,
            
            parseParamTag = function(self, tagLine)
                local type, name, description = tagLine:match("^@param%s+{([^}]+)}%s+([%w_]+)%s*(.*)")
                if not type then
                    name, description = tagLine:match("^@param%s+([%w_]+)%s*(.*)")
                    type = "any"
                end
                
                return {
                    name = name,
                    type = type,
                    description = description,
                    optional = tagLine:find("%[") ~= nil
                }
            end
        }
    }
end

function APIDocumentationGenerator.createGenerators()
    return {
        markdownGenerator = {
            name = "markdown_generator",
            
            generateAPI = function(self, apiInfo)
                local markdown = {}
                
                -- Generate header
                table.insert(markdown, string.format("# %s API", apiInfo.name))
                table.insert(markdown, "")
                
                if apiInfo.description then
                    table.insert(markdown, apiInfo.description)
                    table.insert(markdown, "")
                end
                
                -- Generate table of contents
                if #apiInfo.functions > 0 then
                    table.insert(markdown, "## Table of Contents")
                    table.insert(markdown, "")
                    
                    for _, func in ipairs(apiInfo.functions) do
                        table.insert(markdown, string.format("- [%s](#%s)", func.name, func.name:lower():gsub("%.", "")))
                    end
                    table.insert(markdown, "")
                end
                
                -- Generate function documentation
                table.insert(markdown, "## Functions")
                table.insert(markdown, "")
                
                for _, func in ipairs(apiInfo.functions) do
                    local funcDocs = self:generateFunctionDocs(func)
                    for _, line in ipairs(funcDocs) do
                        table.insert(markdown, line)
                    end
                end
                
                return table.concat(markdown, "\n")
            end,
            
            generateFunctionDocs = function(self, funcInfo)
                local docs = {}
                
                -- Function header
                table.insert(docs, string.format("### %s", funcInfo.name))
                table.insert(docs, "")
                
                -- Function signature
                local signature = self:generateSignature(funcInfo)
                table.insert(docs, "```lua")
                table.insert(docs, signature)
                table.insert(docs, "```")
                table.insert(docs, "")
                
                -- Description
                if funcInfo.description then
                    table.insert(docs, funcInfo.description)
                    table.insert(docs, "")
                end
                
                -- Parameters
                if #funcInfo.parameters > 0 then
                    table.insert(docs, "**Parameters:**")
                    table.insert(docs, "")
                    
                    for _, param in ipairs(funcInfo.parameters) do
                        local paramDoc = string.format("- `%s` (%s)%s: %s", 
                            param.name,
                            param.type,
                            param.optional and " *optional*" or "",
                            param.description or "No description"
                        )
                        table.insert(docs, paramDoc)
                    end
                    table.insert(docs, "")
                end
                
                -- Returns
                if funcInfo.returns then
                    table.insert(docs, "**Returns:**")
                    table.insert(docs, "")
                    table.insert(docs, funcInfo.returns)
                    table.insert(docs, "")
                end
                
                -- Examples
                if #funcInfo.examples > 0 then
                    table.insert(docs, "**Examples:**")
                    table.insert(docs, "")
                    
                    for _, example in ipairs(funcInfo.examples) do
                        table.insert(docs, "```lua")
                        table.insert(docs, example.code)
                        table.insert(docs, "```")
                        
                        if example.description then
                            table.insert(docs, example.description)
                        end
                        table.insert(docs, "")
                    end
                end
                
                return docs
            end,
            
            generateSignature = function(self, funcInfo)
                local params = {}
                for _, param in ipairs(funcInfo.parameters) do
                    local paramStr = param.name
                    if param.type then
                        paramStr = paramStr .. ": " .. param.type
                    end
                    if param.optional then
                        paramStr = paramStr .. "?"
                    end
                    table.insert(params, paramStr)
                end
                
                return string.format("%s(%s)", funcInfo.name, table.concat(params, ", "))
            end
        },
        
        htmlGenerator = {
            name = "html_generator",
            
            generateAPI = function(self, apiInfo)
                local html = {}
                
                table.insert(html, "<!DOCTYPE html>")
                table.insert(html, "<html lang=\"en\">")
                table.insert(html, "<head>")
                table.insert(html, "    <meta charset=\"UTF-8\">")
                table.insert(html, "    <meta name=\"viewport\" content=\"width=device-width, initial-scale=1.0\">")
                table.insert(html, string.format("    <title>%s API Documentation</title>", apiInfo.name))
                table.insert(html, "    <link rel=\"stylesheet\" href=\"docs.css\">")
                table.insert(html, "</head>")
                table.insert(html, "<body>")
                table.insert(html, "    <div class=\"documentation\">")
                
                -- Generate content
                table.insert(html, string.format("        <h1>%s API</h1>", apiInfo.name))
                
                if apiInfo.description then
                    table.insert(html, string.format("        <p>%s</p>", apiInfo.description))
                end
                
                -- Generate navigation
                if #apiInfo.functions > 0 then
                    table.insert(html, "        <nav class=\"api-nav\">")
                    table.insert(html, "            <h2>Functions</h2>")
                    table.insert(html, "            <ul>")
                    
                    for _, func in ipairs(apiInfo.functions) do
                        table.insert(html, string.format("                <li><a href=\"#%s\">%s</a></li>", 
                            func.name:lower():gsub("%.", ""), func.name))
                    end
                    
                    table.insert(html, "            </ul>")
                    table.insert(html, "        </nav>")
                end
                
                -- Generate function documentation
                for _, func in ipairs(apiInfo.functions) do
                    local funcHtml = self:generateFunctionHTML(func)
                    for _, line in ipairs(funcHtml) do
                        table.insert(html, "        " .. line)
                    end
                end
                
                table.insert(html, "    </div>")
                table.insert(html, "    <script src=\"docs.js\"></script>")
                table.insert(html, "</body>")
                table.insert(html, "</html>")
                
                return table.concat(html, "\n")
            end,
            
            generateFunctionHTML = function(self, funcInfo)
                local html = {}
                
                table.insert(html, string.format("<section id=\"%s\" class=\"function-docs\">", 
                    funcInfo.name:lower():gsub("%.", "")))
                table.insert(html, string.format("    <h3>%s</h3>", funcInfo.name))
                
                -- Function signature
                local signature = DocState.documentationEngine.generators.markdownGenerator:generateSignature(funcInfo)
                table.insert(html, "    <div class=\"function-signature\">")
                table.insert(html, string.format("        <code>%s</code>", signature))
                table.insert(html, "    </div>")
                
                -- Description
                if funcInfo.description then
                    table.insert(html, string.format("    <p>%s</p>", funcInfo.description))
                end
                
                -- Parameters
                if #funcInfo.parameters > 0 then
                    table.insert(html, "    <h4>Parameters</h4>")
                    table.insert(html, "    <ul class=\"parameters\">")
                    
                    for _, param in ipairs(funcInfo.parameters) do
                        table.insert(html, "        <li>")
                        table.insert(html, string.format("            <code>%s</code> (%s)%s", 
                            param.name,
                            param.type,
                            param.optional and " <em>optional</em>" or ""
                        ))
                        if param.description then
                            table.insert(html, string.format("            <p>%s</p>", param.description))
                        end
                        table.insert(html, "        </li>")
                    end
                    
                    table.insert(html, "    </ul>")
                end
                
                table.insert(html, "</section>")
                
                return html
            end
        }
    }
end

function APIDocumentationGenerator.createFormatters()
    return {
        codeFormatter = {
            name = "code_formatter",
            
            formatLua = function(self, code)
                -- Basic Lua code formatting
                local lines = code:split("\n")
                local formatted = {}
                local indentLevel = 0
                
                for _, line in ipairs(lines) do
                    local trimmed = line:match("^%s*(.-)%s*$")
                    
                    -- Decrease indent for end keywords
                    if trimmed:match("^end") or trimmed:match("^else") or trimmed:match("^elseif") then
                        indentLevel = math.max(0, indentLevel - 1)
                    end
                    
                    -- Apply indentation
                    local indent = string.rep("    ", indentLevel)
                    table.insert(formatted, indent .. trimmed)
                    
                    -- Increase indent for block keywords
                    if trimmed:match("^function") or trimmed:match("^if") or 
                       trimmed:match("^for") or trimmed:match("^while") or
                       trimmed:match("^else$") or trimmed:match("^elseif") then
                        indentLevel = indentLevel + 1
                    end
                end
                
                return table.concat(formatted, "\n")
            end,
            
            highlightSyntax = function(self, code, language)
                -- Basic syntax highlighting (would use real syntax highlighter)
                local highlighted = code
                
                -- Highlight keywords
                local keywords = {"function", "end", "if", "then", "else", "elseif", "for", "while", "do", "local", "return"}
                for _, keyword in ipairs(keywords) do
                    highlighted = highlighted:gsub("(%f[%w]" .. keyword .. "%f[%W])", "<span class=\"keyword\">%1</span>")
                end
                
                -- Highlight strings
                highlighted = highlighted:gsub("(\"[^\"]*\")", "<span class=\"string\">%1</span>")
                highlighted = highlighted:gsub("('[^']*')", "<span class=\"string\">%1</span>")
                
                -- Highlight comments
                highlighted = highlighted:gsub("(%-%-[^\n]*)", "<span class=\"comment\">%1</span>")
                
                return highlighted
            end
        }
    }
end

-- ========================================
-- SYSTEM REGISTRATION
-- ========================================

function APIDocumentationGenerator.registerGameSystems()
    print("📋 Registering game systems for documentation...")
    
    -- Register all mobile optimization systems
    local mobileSystem = {
        name = "MobileOptimization",
        path = "ReplicatedStorage.Shared.mobile.MobileOptimization",
        module = SafeRequire(ReplicatedStorage.Shared.mobile.MobileOptimization),
        description = "Comprehensive mobile performance optimization system"
    }
    APIDocumentationGenerator.registerSystem(mobileSystem)
    
    local adaptiveUISystem = {
        name = "AdaptiveUISystem",
        path = "ReplicatedStorage.Shared.mobile.AdaptiveUISystem",
        module = SafeRequire(ReplicatedStorage.Shared.mobile.AdaptiveUISystem),
        description = "Adaptive UI scaling and layout system for all screen sizes"
    }
    APIDocumentationGenerator.registerSystem(adaptiveUISystem)
    
    local touchControlsSystem = {
        name = "TouchControlsSystem",
        path = "ReplicatedStorage.Shared.mobile.TouchControlsSystem", 
        module = SafeRequire(ReplicatedStorage.Shared.mobile.TouchControlsSystem),
        description = "Advanced touch controls with haptic feedback and gesture recognition"
    }
    APIDocumentationGenerator.registerSystem(touchControlsSystem)
    
    local deviceOptimizationSystem = {
        name = "DeviceOptimizationSystem",
        path = "ReplicatedStorage.Shared.mobile.DeviceOptimizationSystem",
        module = SafeRequire(ReplicatedStorage.Shared.mobile.DeviceOptimizationSystem),
        description = "Device-specific optimizations and offline mode functionality"
    }
    APIDocumentationGenerator.registerSystem(deviceOptimizationSystem)
    
    local accessibilitySystem = {
        name = "AccessibilityNotificationSystem",
        path = "ReplicatedStorage.Shared.mobile.AccessibilityNotificationSystem",
        module = SafeRequire(ReplicatedStorage.Shared.mobile.AccessibilityNotificationSystem),
        description = "Mobile accessibility features and push notification management"
    }
    APIDocumentationGenerator.registerSystem(accessibilitySystem)
    
    local analyticsSystem = {
        name = "MobileAnalyticsCloudSystem",
        path = "ReplicatedStorage.Shared.mobile.MobileAnalyticsCloudSystem",
        module = SafeRequire(ReplicatedStorage.Shared.mobile.MobileAnalyticsCloudSystem),
        description = "Mobile analytics and cross-platform cloud synchronization"
    }
    APIDocumentationGenerator.registerSystem(analyticsSystem)
    
    print(string.format("📋 Registered %d systems for documentation", #DocState.registeredSystems))
end

function APIDocumentationGenerator.registerSystem(systemInfo)
    table.insert(DocState.registeredSystems, systemInfo)
    
    -- Analyze system API
    local analysis = DocState.documentationEngine:analyzeSystem(systemInfo.name, systemInfo.module)
    DocState.analysisResults[systemInfo.name] = analysis
    
    print(string.format("📝 Registered system: %s (%d functions)", systemInfo.name, #analysis.functions))
end

-- ========================================
-- API ANALYSIS
-- ========================================

function APIDocumentationGenerator.analyzeSystemAPI(systemName, systemModule)
    local analysis = {
        name = systemName,
        functions = {},
        properties = {},
        events = {},
        description = "",
        examples = {}
    }
    
    if not systemModule then
        print(string.format("⚠️ Could not analyze %s - module not found", systemName))
        return analysis
    end
    
    -- Analyze module structure
    for key, value in pairs(systemModule) do
        if typeof(value) == "function" then
            local funcInfo = APIDocumentationGenerator.analyzeFunctionAPI(key, value, systemModule)
            table.insert(analysis.functions, funcInfo)
        elseif typeof(value) ~= "function" and key ~= "_G" then
            table.insert(analysis.properties, {
                name = key,
                type = typeof(value),
                value = value
            })
        end
    end
    
    -- Generate examples for key functions
    analysis.examples = APIDocumentationGenerator.generateSystemExamples(systemName, analysis.functions)
    
    return analysis
end

function APIDocumentationGenerator.analyzeFunctionAPI(funcName, func, parentModule)
    local funcInfo = {
        name = funcName,
        description = APIDocumentationGenerator.extractFunctionDescription(funcName, parentModule),
        parameters = APIDocumentationGenerator.inferFunctionParameters(funcName, func),
        returns = APIDocumentationGenerator.inferFunctionReturns(funcName, func),
        examples = APIDocumentationGenerator.generateFunctionExamples(funcName, parentModule),
        category = APIDocumentationGenerator.categorizeFunctionAPI(funcName),
        visibility = funcName:sub(1, 1) == "_" and "private" or "public"
    }
    
    return funcInfo
end

function APIDocumentationGenerator.extractFunctionDescription(funcName, parentModule)
    -- Extract description from comments or generate based on function name
    local descriptions = {
        initialize = "Initializes the system and sets up all necessary components",
        enable = "Enables the specified feature or functionality",
        disable = "Disables the specified feature or functionality",
        get = "Retrieves the specified data or configuration",
        set = "Sets the specified data or configuration", 
        update = "Updates the system state or processes pending operations",
        reset = "Resets the system to its default state",
        destroy = "Destroys the system and cleans up resources",
        run = "Runs a demonstration or test of the system functionality"
    }
    
    -- Check for exact matches
    if descriptions[funcName] then
        return descriptions[funcName]
    end
    
    -- Check for pattern matches
    for pattern, description in pairs(descriptions) do
        if funcName:lower():find(pattern) then
            return description:gsub("the specified", funcName:match(pattern .. "(.*)") or "the specified")
        end
    end
    
    -- Generate description based on function name
    return string.format("Performs %s operation", funcName:gsub("([A-Z])", " %1"):lower())
end

function APIDocumentationGenerator.inferFunctionParameters(funcName, func)
    -- Infer parameters based on function name and common patterns
    local commonParameters = {
        enable = {{name = "feature", type = "string", description = "The feature to enable"}},
        disable = {{name = "feature", type = "string", description = "The feature to disable"}},
        set = {
            {name = "property", type = "string", description = "The property to set"},
            {name = "value", type = "any", description = "The value to set"}
        },
        get = {{name = "property", type = "string", description = "The property to retrieve"}},
        track = {
            {name = "event", type = "string", description = "The event to track"},
            {name = "data", type = "table", optional = true, description = "Additional event data"}
        },
        show = {{name = "element", type = "GuiObject", description = "The UI element to show"}},
        hide = {{name = "element", type = "GuiObject", description = "The UI element to hide"}},
        apply = {{name = "settings", type = "table", description = "The settings to apply"}},
        register = {
            {name = "element", type = "GuiObject", description = "The element to register"},
            {name = "config", type = "table", optional = true, description = "Optional configuration"}
        }
    }
    
    -- Check for pattern matches
    for pattern, params in pairs(commonParameters) do
        if funcName:lower():find(pattern) then
            return params
        end
    end
    
    -- Default parameters for unknown functions
    return {{name = "...", type = "any", description = "Function parameters"}}
end

function APIDocumentationGenerator.inferFunctionReturns(funcName, func)
    local returnPatterns = {
        get = "The requested value or nil if not found",
        is = "Boolean indicating the state",
        can = "Boolean indicating capability",
        has = "Boolean indicating presence",
        create = "The created object or instance",
        find = "The found object or nil",
        calculate = "The calculated result",
        generate = "The generated content"
    }
    
    for pattern, returnDesc in pairs(returnPatterns) do
        if funcName:lower():find(pattern) then
            return returnDesc
        end
    end
    
    return "No return value"
end

function APIDocumentationGenerator.generateFunctionExamples(funcName, parentModule)
    local examples = {}
    
    -- Generate basic usage example
    local basicExample = APIDocumentationGenerator.generateBasicExample(funcName, parentModule)
    if basicExample then
        table.insert(examples, {
            title = "Basic Usage",
            code = basicExample,
            description = string.format("Basic usage of %s function", funcName)
        })
    end
    
    -- Generate advanced example for complex functions
    if funcName:find("register") or funcName:find("configure") or funcName:find("setup") then
        local advancedExample = APIDocumentationGenerator.generateAdvancedExample(funcName, parentModule)
        if advancedExample then
            table.insert(examples, {
                title = "Advanced Usage",
                code = advancedExample,
                description = string.format("Advanced usage with configuration options")
            })
        end
    end
    
    return examples
end

function APIDocumentationGenerator.generateBasicExample(funcName, parentModule)
    local moduleName = "System" -- Would extract actual module name
    
    local exampleTemplates = {
        initialize = string.format("%s.initialize()", moduleName),
        enable = string.format("%s.enable%s()", moduleName, funcName:gsub("enable", "")),
        disable = string.format("%s.disable%s()", moduleName, funcName:gsub("disable", "")),
        get = string.format("local value = %s.%s()", moduleName, funcName),
        set = string.format("%s.%s(\"property\", value)", moduleName, funcName),
        track = string.format("%s.%s(\"eventName\", {data = \"value\"})", moduleName, funcName),
        register = string.format("%s.%s(element, {config = true})", moduleName, funcName),
        show = string.format("%s.%s()", moduleName, funcName),
        hide = string.format("%s.%s()", moduleName, funcName)
    }
    
    for pattern, template in pairs(exampleTemplates) do
        if funcName:lower():find(pattern) then
            return template
        end
    end
    
    return string.format("%s.%s()", moduleName, funcName)
end

function APIDocumentationGenerator.generateAdvancedExample(funcName, parentModule)
    local moduleName = "System"
    
    if funcName:find("register") then
        return string.format([[-- Register element with full configuration
local element = script.Parent.MyButton
%s.%s(element, {
    responsive = true,
    accessibility = {
        largeText = true,
        highContrast = false
    },
    animations = {
        enabled = true,
        duration = 0.3
    }
})]], moduleName, funcName)
    elseif funcName:find("configure") or funcName:find("setup") then
        return string.format([[-- Configure system with advanced options
%s.%s({
    performance = {
        optimization = "balanced",
        monitoring = true
    },
    features = {
        accessibility = true,
        analytics = true
    },
    debugging = {
        verbose = false,
        logging = true
    }
})]], moduleName, funcName)
    end
    
    return nil
end

function APIDocumentationGenerator.categorizeFunctionAPI(funcName)
    local categories = {
        ["Initialization"] = {"initialize", "setup", "start", "begin"},
        ["Configuration"] = {"configure", "set", "apply", "update"},
        ["Data Access"] = {"get", "retrieve", "fetch", "load"},
        ["Event Handling"] = {"on", "track", "trigger", "emit"},
        ["UI Management"] = {"show", "hide", "display", "render"},
        ["System Control"] = {"enable", "disable", "toggle", "switch"},
        ["Registration"] = {"register", "add", "create", "new"},
        ["Cleanup"] = {"destroy", "cleanup", "remove", "delete"},
        ["Utility"] = {"calculate", "generate", "format", "validate"},
        ["Demo"] = {"run", "demo", "test", "example"}
    }
    
    for category, patterns in pairs(categories) do
        for _, pattern in ipairs(patterns) do
            if funcName:lower():find(pattern) then
                return category
            end
        end
    end
    
    return "General"
end

function APIDocumentationGenerator.generateSystemExamples(systemName, functions)
    local examples = {
        {
            title = "Quick Start",
            description = string.format("Getting started with %s", systemName),
            code = APIDocumentationGenerator.generateQuickStartExample(systemName, functions)
        },
        {
            title = "Common Usage Patterns",
            description = "Common ways to use this system",
            code = APIDocumentationGenerator.generateCommonUsageExample(systemName, functions)
        }
    }
    
    return examples
end

function APIDocumentationGenerator.generateQuickStartExample(systemName, functions)
    local hasInit = false
    local hasDemo = false
    
    for _, func in ipairs(functions) do
        if func.name:lower():find("initialize") then
            hasInit = true
        elseif func.name:lower():find("demo") or func.name:lower():find("run") then
            hasDemo = true
        end
    end
    
    local example = string.format("-- Quick start with %s\nlocal %s = require(path.to.%s)\n\n", 
        systemName, systemName, systemName)
    
    if hasInit then
        example = example .. string.format("-- Initialize the system\n%s.initialize()\n\n", systemName)
    end
    
    if hasDemo then
        example = example .. string.format("-- Run demonstration\n%s.runDemo()\n", systemName)
    else
        example = example .. string.format("-- Use basic functionality\n-- Add your code here")
    end
    
    return example
end

function APIDocumentationGenerator.generateCommonUsageExample(systemName, functions)
    local example = string.format("-- Common usage patterns for %s\n", systemName)
    
    -- Find common function patterns
    local patterns = {
        enable = "Enable features",
        get = "Retrieve information", 
        set = "Configure settings",
        track = "Track events",
        register = "Register components"
    }
    
    for pattern, description in pairs(patterns) do
        for _, func in ipairs(functions) do
            if func.name:lower():find(pattern) and func.visibility == "public" then
                example = example .. string.format("\n-- %s\n%s.%s()\n", description, systemName, func.name)
                break
            end
        end
    end
    
    return example
end

-- ========================================
-- DOCUMENTATION GENERATION
-- ========================================

function APIDocumentationGenerator.generateComprehensiveDocumentation()
    print("📚 Generating comprehensive API documentation...")
    
    local startTime = tick()
    
    -- Generate documentation for each registered system
    for _, systemInfo in ipairs(DocState.registeredSystems) do
        local analysis = DocState.analysisResults[systemInfo.name]
        if analysis then
            local documentation = DocState.documentationEngine:generateDocumentation(analysis)
            DocState.generatedDocs[systemInfo.name] = documentation
            print(string.format("📄 Generated documentation for %s", systemInfo.name))
        end
    end
    
    -- Generate combined documentation
    APIDocumentationGenerator.generateMasterDocumentation()
    
    -- Generate interactive examples
    APIDocumentationGenerator.generateInteractiveExamples()
    
    -- Update metadata
    DocState.metadata.generationTime = tick() - startTime
    DocState.metadata.lastUpdate = tick()
    DocState.metadata.totalAPIs = APIDocumentationGenerator.countTotalAPIs()
    
    print(string.format("📚 Documentation generation completed (%.2fs)", DocState.metadata.generationTime))
end

function APIDocumentationGenerator.generateSystemDocumentation(analysis)
    local documentation = {
        markdown = "",
        html = "",
        json = ""
    }
    
    -- Generate markdown documentation
    documentation.markdown = DocState.documentationEngine.generators.markdownGenerator:generateAPI(analysis)
    
    -- Generate HTML documentation
    documentation.html = DocState.documentationEngine.generators.htmlGenerator:generateAPI(analysis)
    
    -- Generate JSON documentation
    documentation.json = HttpService:JSONEncode(analysis)
    
    return documentation
end

function APIDocumentationGenerator.generateMasterDocumentation()
    local masterDoc = {}
    
    -- Generate table of contents
    table.insert(masterDoc, "# Game Systems API Documentation")
    table.insert(masterDoc, "")
    table.insert(masterDoc, "Comprehensive API documentation for all game systems.")
    table.insert(masterDoc, "")
    table.insert(masterDoc, "## Systems")
    table.insert(masterDoc, "")
    
    for _, systemInfo in ipairs(DocState.registeredSystems) do
        table.insert(masterDoc, string.format("- [%s](#%s) - %s", 
            systemInfo.name, 
            systemInfo.name:lower(), 
            systemInfo.description))
    end
    table.insert(masterDoc, "")
    
    -- Include individual system documentation
    for _, systemInfo in ipairs(DocState.registeredSystems) do
        local systemDocs = DocState.generatedDocs[systemInfo.name]
        if systemDocs and systemDocs.markdown then
            table.insert(masterDoc, "---")
            table.insert(masterDoc, "")
            table.insert(masterDoc, systemDocs.markdown)
            table.insert(masterDoc, "")
        end
    end
    
    DocState.masterDocumentation = table.concat(masterDoc, "\n")
    
    print("📚 Master documentation generated")
end

function APIDocumentationGenerator.generateInteractiveExamples()
    if not DOC_CONFIG.interactiveExamples.enabled then return end
    
    print("🎮 Generating interactive examples...")
    
    for _, systemInfo in ipairs(DocState.registeredSystems) do
        local analysis = DocState.analysisResults[systemInfo.name]
        if analysis then
            for _, func in ipairs(analysis.functions) do
                if func.visibility == "public" and #func.examples > 0 then
                    local interactiveExample = APIDocumentationGenerator.createInteractiveExample(func, func.examples[1])
                    DocState.examples[systemInfo.name .. "." .. func.name] = interactiveExample
                end
            end
        end
    end
    
    print(string.format("🎮 Generated %d interactive examples", APIDocumentationGenerator.countExamples()))
end

function APIDocumentationGenerator.createInteractiveExample(apiInfo, example)
    return {
        title = string.format("%s - %s", apiInfo.name, example.title),
        description = example.description,
        code = example.code,
        editable = DOC_CONFIG.interactiveExamples.allowModification,
        runnable = DOC_CONFIG.interactiveExamples.runInSandbox,
        
        run = function(self, customCode)
            local codeToRun = customCode or self.code
            return APIDocumentationGenerator.executeExampleCode(codeToRun)
        end
    }
end

function APIDocumentationGenerator.executeExampleCode(code)
    if not DOC_CONFIG.interactiveExamples.runInSandbox then
        return {success = false, error = "Code execution disabled"}
    end
    
    local success, result = pcall(function()
        local func, err = loadstring(code)
        if not func then
            return {success = false, error = err}
        end
        
        local output = func()
        return {success = true, output = output}
    end)
    
    if success then
        return result
    else
        return {success = false, error = tostring(result)}
    end
end

-- ========================================
-- DOCUMENTATION INTERFACE
-- ========================================

function APIDocumentationGenerator.createDocumentationInterface()
    print("🖥️ Creating documentation interface...")
    
    local player = Players.LocalPlayer
    local playerGui = player:WaitForChild("PlayerGui")
    
    -- Create documentation GUI
    local docGui = Instance.new("ScreenGui")
    docGui.Name = "APIDocumentation"
    docGui.ResetOnSpawn = false
    docGui.Parent = playerGui
    
    -- Create main documentation frame
    local mainFrame = Instance.new("Frame")
    mainFrame.Name = "DocumentationFrame"
    mainFrame.Size = UDim2.new(0.8, 0, 0.8, 0)
    mainFrame.Position = UDim2.new(0.1, 0, 0.1, 0)
    mainFrame.BackgroundColor3 = Color3.fromRGB(245, 245, 245)
    mainFrame.BorderSizePixel = 0
    mainFrame.Visible = false
    mainFrame.Parent = docGui
    
    -- Round corners
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 12)
    corner.Parent = mainFrame
    
    -- Create header
    local header = Instance.new("Frame")
    header.Name = "Header"
    header.Size = UDim2.new(1, 0, 0, 60)
    header.Position = UDim2.new(0, 0, 0, 0)
    header.BackgroundColor3 = Color3.fromRGB(33, 150, 243)
    header.BorderSizePixel = 0
    header.Parent = mainFrame
    
    local headerCorner = Instance.new("UICorner")
    headerCorner.CornerRadius = UDim.new(0, 12)
    headerCorner.Parent = header
    
    -- Header title
    local title = Instance.new("TextLabel")
    title.Name = "Title"
    title.Size = UDim2.new(1, -120, 1, 0)
    title.Position = UDim2.new(0, 20, 0, 0)
    title.BackgroundTransparency = 1
    title.Text = "API Documentation"
    title.TextColor3 = Color3.new(1, 1, 1)
    title.TextSize = 24
    title.Font = Enum.Font.SourceSansBold
    title.TextXAlignment = Enum.TextXAlignment.Left
    title.Parent = header
    
    -- Close button
    local closeButton = Instance.new("TextButton")
    closeButton.Name = "CloseButton"
    closeButton.Size = UDim2.new(0, 40, 0, 40)
    closeButton.Position = UDim2.new(1, -50, 0, 10)
    closeButton.BackgroundColor3 = Color3.fromRGB(244, 67, 54)
    closeButton.Text = "✕"
    closeButton.TextColor3 = Color3.new(1, 1, 1)
    closeButton.TextSize = 18
    closeButton.Font = Enum.Font.SourceSansBold
    closeButton.BorderSizePixel = 0
    closeButton.Parent = header
    
    local closeCorner = Instance.new("UICorner")
    closeCorner.CornerRadius = UDim.new(0, 20)
    closeCorner.Parent = closeButton
    
    -- Create navigation sidebar
    local sidebar = Instance.new("Frame")
    sidebar.Name = "Sidebar"
    sidebar.Size = UDim2.new(0, 250, 1, -60)
    sidebar.Position = UDim2.new(0, 0, 0, 60)
    sidebar.BackgroundColor3 = Color3.fromRGB(240, 240, 240)
    sidebar.BorderSizePixel = 0
    sidebar.Parent = mainFrame
    
    -- Create content area
    local contentArea = Instance.new("ScrollingFrame")
    contentArea.Name = "ContentArea"
    contentArea.Size = UDim2.new(1, -250, 1, -60)
    contentArea.Position = UDim2.new(0, 250, 0, 60)
    contentArea.BackgroundColor3 = Color3.new(1, 1, 1)
    contentArea.BorderSizePixel = 0
    contentArea.ScrollBarThickness = 10
    contentArea.Parent = mainFrame
    
    -- Populate navigation
    APIDocumentationGenerator.populateNavigation(sidebar)
    
    -- Set up event handlers
    closeButton.MouseButton1Click:Connect(function()
        mainFrame.Visible = false
    end)
    
    -- Create toggle button
    APIDocumentationGenerator.createDocumentationToggle(docGui, mainFrame)
    
    DocState.documentationInterface = {
        gui = docGui,
        mainFrame = mainFrame,
        sidebar = sidebar,
        contentArea = contentArea
    }
    
    print("🖥️ Documentation interface created")
end

function APIDocumentationGenerator.createDocumentationToggle(docGui, mainFrame)
    -- Create floating documentation button
    local toggleButton = Instance.new("TextButton")
    toggleButton.Name = "DocumentationToggle"
    toggleButton.Size = UDim2.new(0, 60, 0, 60)
    toggleButton.Position = UDim2.new(1, -80, 0, 20)
    toggleButton.BackgroundColor3 = Color3.fromRGB(33, 150, 243)
    toggleButton.Text = "📚"
    toggleButton.TextSize = 24
    toggleButton.TextColor3 = Color3.new(1, 1, 1)
    toggleButton.BorderSizePixel = 0
    toggleButton.Parent = docGui
    
    local toggleCorner = Instance.new("UICorner")
    toggleCorner.CornerRadius = UDim.new(0.5, 0)
    toggleCorner.Parent = toggleButton
    
    toggleButton.MouseButton1Click:Connect(function()
        mainFrame.Visible = not mainFrame.Visible
    end)
end

function APIDocumentationGenerator.populateNavigation(sidebar)
    local scrollingFrame = Instance.new("ScrollingFrame")
    scrollingFrame.Size = UDim2.new(1, 0, 1, 0)
    scrollingFrame.BackgroundTransparency = 1
    scrollingFrame.ScrollBarThickness = 6
    scrollingFrame.Parent = sidebar
    
    local layout = Instance.new("UIListLayout")
    layout.SortOrder = Enum.SortOrder.LayoutOrder
    layout.Padding = UDim.new(0, 2)
    layout.Parent = scrollingFrame
    
    -- Add navigation items for each system
    for i, systemInfo in ipairs(DocState.registeredSystems) do
        local navItem = Instance.new("TextButton")
        navItem.Name = systemInfo.name
        navItem.Size = UDim2.new(1, -10, 0, 40)
        navItem.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
        navItem.Text = systemInfo.name
        navItem.TextColor3 = Color3.fromRGB(50, 50, 50)
        navItem.TextSize = 14
        navItem.Font = Enum.Font.SourceSans
        navItem.TextXAlignment = Enum.TextXAlignment.Left
        navItem.BorderSizePixel = 0
        navItem.LayoutOrder = i
        navItem.Parent = scrollingFrame
        
        -- Add padding
        local padding = Instance.new("UIPadding")
        padding.PaddingLeft = UDim.new(0, 10)
        padding.Parent = navItem
        
        navItem.MouseButton1Click:Connect(function()
            APIDocumentationGenerator.showSystemDocumentation(systemInfo.name)
        end)
    end
    
    -- Update scrolling frame canvas size
    scrollingFrame.CanvasSize = UDim2.new(0, 0, 0, #DocState.registeredSystems * 42)
end

function APIDocumentationGenerator.showSystemDocumentation(systemName)
    local contentArea = DocState.documentationInterface.contentArea
    
    -- Clear existing content
    for _, child in ipairs(contentArea:GetChildren()) do
        if child:IsA("GuiObject") then
            child:Destroy()
        end
    end
    
    -- Get system documentation
    local systemDocs = DocState.generatedDocs[systemName]
    if not systemDocs then
        print(string.format("⚠️ No documentation found for %s", systemName))
        return
    end
    
    -- Create documentation display
    local docDisplay = Instance.new("TextLabel")
    docDisplay.Size = UDim2.new(1, -20, 0, 0)
    docDisplay.Position = UDim2.new(0, 10, 0, 10)
    docDisplay.BackgroundTransparency = 1
    docDisplay.Text = systemDocs.markdown
    docDisplay.TextColor3 = Color3.fromRGB(50, 50, 50)
    docDisplay.TextSize = 14
    docDisplay.Font = Enum.Font.SourceSans
    docDisplay.TextXAlignment = Enum.TextXAlignment.Left
    docDisplay.TextYAlignment = Enum.TextYAlignment.Top
    docDisplay.TextWrapped = true
    docDisplay.Parent = contentArea
    
    -- Calculate text size
    local textService = game:GetService("TextService")
    local textSize = textService:GetTextSize(
        docDisplay.Text,
        docDisplay.TextSize,
        docDisplay.Font,
        Vector2.new(contentArea.AbsoluteSize.X - 20, math.huge)
    )
    
    docDisplay.Size = UDim2.new(1, -20, 0, textSize.Y + 20)
    contentArea.CanvasSize = UDim2.new(0, 0, 0, textSize.Y + 40)
    
    print(string.format("📄 Showing documentation for %s", systemName))
end

-- ========================================
-- AUTOMATED UPDATES
-- ========================================

function APIDocumentationGenerator.setupAutomatedUpdates()
    DocState.updateScheduler = {
        enabled = true,
        interval = 300, -- 5 minutes
        
        start = function(self)
            spawn(function()
                while self.enabled do
                    task.wait(self.interval)
                    APIDocumentationGenerator.checkForUpdates()
                end
            end)
        end
    }
    
    DocState.updateScheduler:start()
    print("🔄 Automated documentation updates enabled")
end

function APIDocumentationGenerator.checkForUpdates()
    -- Check if any systems have been modified
    local needsUpdate = false
    
    for _, systemInfo in ipairs(DocState.registeredSystems) do
        if APIDocumentationGenerator.hasSystemChanged(systemInfo) then
            needsUpdate = true
            break
        end
    end
    
    if needsUpdate then
        print("🔄 Detected system changes, updating documentation...")
        APIDocumentationGenerator.generateComprehensiveDocumentation()
    end
end

function APIDocumentationGenerator.hasSystemChanged(systemInfo)
    -- Simplified change detection (in real implementation, would check file timestamps, etc.)
    return false
end

-- ========================================
-- UTILITY FUNCTIONS
-- ========================================

function APIDocumentationGenerator.countTotalAPIs()
    local total = 0
    for _, analysis in pairs(DocState.analysisResults) do
        total = total + #analysis.functions
    end
    return total
end

function APIDocumentationGenerator.countExamples()
    local total = 0
    for _, example in pairs(DocState.examples) do
        total = total + 1
    end
    return total
end

-- ========================================
-- PUBLIC API
-- ========================================

function APIDocumentationGenerator.getDocumentation(systemName)
    return DocState.generatedDocs[systemName]
end

function APIDocumentationGenerator.getMasterDocumentation()
    return DocState.masterDocumentation
end

function APIDocumentationGenerator.getSystemAnalysis(systemName)
    return DocState.analysisResults[systemName]
end

function APIDocumentationGenerator.regenerateDocumentation()
    APIDocumentationGenerator.generateComprehensiveDocumentation()
    print("🔄 Documentation regenerated")
end

function APIDocumentationGenerator.exportDocumentation(format)
    format = format or "markdown"
    
    local exports = {}
    for systemName, docs in pairs(DocState.generatedDocs) do
        exports[systemName] = docs[format]
    end
    
    return exports
end

function APIDocumentationGenerator.runDocumentationDemo()
    print("📚 Running API documentation demonstration...")
    
    -- Show documentation statistics
    print("  📊 Documentation Statistics:")
    print(string.format("    Systems Documented: %d", #DocState.registeredSystems))
    print(string.format("    Total APIs: %d", DocState.metadata.totalAPIs))
    print(string.format("    Interactive Examples: %d", APIDocumentationGenerator.countExamples()))
    print(string.format("    Generation Time: %.2fs", DocState.metadata.generationTime))
    
    -- Show registered systems
    print("  📋 Documented Systems:")
    for _, systemInfo in ipairs(DocState.registeredSystems) do
        local analysis = DocState.analysisResults[systemInfo.name]
        print(string.format("    %s: %d functions", systemInfo.name, #analysis.functions))
    end
    
    -- Show sample documentation
    print("  📄 Sample Documentation (MobileOptimization):")
    local sampleDocs = DocState.generatedDocs["MobileOptimization"]
    if sampleDocs then
        local lines = sampleDocs.markdown:split("\n")
        for i = 1, math.min(10, #lines) do
            print(string.format("    %s", lines[i]))
        end
        if #lines > 10 then
            print("    ...")
        end
    end
    
    -- Show interactive documentation interface
    if DocState.documentationInterface then
        print("  🖥️ Interactive Documentation Interface:")
        print("    Click the 📚 button in the top-right corner to open")
        print("    Navigate through systems using the sidebar")
        print("    View detailed API documentation and examples")
        
        -- Briefly show the documentation interface
        DocState.documentationInterface.mainFrame.Visible = true
        task.wait(2)
        DocState.documentationInterface.mainFrame.Visible = false
    end
    
    print("📚 API documentation demonstration completed")
    print("     Comprehensive documentation system operational!")
end

-- Initialize the API documentation generator
APIDocumentationGenerator.initialize()

print("📚 APIDocumentationGenerator loaded with comprehensive documentation system")

return APIDocumentationGenerator
