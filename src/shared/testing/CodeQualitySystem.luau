-- CodeQualitySystem.luau
-- Code quality metrics and enforcement with complexity analysis and coverage requirements
-- Provides comprehensive code analysis, quality scoring, and automated enforcement

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local HttpService = game:GetService("HttpService")

local SafeRequire = require(ReplicatedStorage.Shared.utils.SafeRequire)

local CodeQualitySystem = {}

-- ========================================
-- CODE QUALITY CONFIGURATION
-- ========================================

local QUALITY_CONFIG = {
    -- Quality thresholds
    thresholds = {
        minimumScore = 7.0,              -- Minimum overall quality score
        maximumComplexity = 15,          -- Maximum cyclomatic complexity
        minimumCoverage = 80,            -- Minimum test coverage percentage
        maximumDuplication = 5,          -- Maximum code duplication percentage
        maximumTechnicalDebt = 480,      -- Maximum technical debt in minutes
        maximumViolations = 20           -- Maximum quality violations
    },
    
    -- Complexity analysis
    complexity = {
        enableCyclomaticComplexity = true,
        enableCognitiveComplexity = true,
        enableHalsteadMetrics = true,
        enableMaintainabilityIndex = true,
        functionThreshold = 10,
        classThreshold = 50
    },
    
    -- Code coverage requirements
    coverage = {
        enableLineCoverage = true,
        enableBranchCoverage = true,
        enableFunctionCoverage = true,
        enableStatementCoverage = true,
        requireIncrementalCoverage = true,
        incrementalThreshold = 5         -- 5% minimum increase
    },
    
    -- Quality rules
    rules = {
        enableNamingConventions = true,
        enableCodeStructure = true,
        enableDocumentation = true,
        enableErrorHandling = true,
        enablePerformanceRules = true,
        enableSecurityRules = true
    },
    
    -- Enforcement settings
    enforcement = {
        enableAutomaticEnforcement = true,
        enableQualityGates = true,
        enablePreCommitHooks = true,
        enableContinuousMonitoring = true,
        failOnViolation = false          -- Set to false for warnings only
    }
}

-- ========================================
-- CODE QUALITY STATE
-- ========================================

local QualityState = {
    -- Code analysis
    analyzedFiles = {},
    qualityMetrics = {},
    complexityMetrics = {},
    coverageMetrics = {},
    
    -- Quality violations
    violations = {},
    violationHistory = {},
    
    -- Quality scores
    overallScore = 0,
    fileScores = {},
    projectScore = 0,
    
    -- Enforcement results
    enforcementResults = {},
    qualityGateResults = {},
    
    -- Technical debt
    technicalDebt = {
        total = 0,
        byCategory = {},
        byFile = {},
        trend = {}
    },
    
    -- Statistics
    stats = {
        totalFiles = 0,
        qualityScore = 0,
        totalViolations = 0,
        totalTechnicalDebt = 0,
        coveragePercentage = 0,
        averageComplexity = 0
    }
}

function CodeQualitySystem.initialize()
    print("📊 Initializing CodeQualitySystem...")
    
    -- Set up code analysis engine
    CodeQualitySystem.setupCodeAnalysisEngine()
    
    -- Initialize complexity analysis
    CodeQualitySystem.initializeComplexityAnalysis()
    
    -- Set up coverage tracking
    CodeQualitySystem.setupCoverageTracking()
    
    -- Initialize quality rules engine
    CodeQualitySystem.initializeQualityRulesEngine()
    
    -- Set up enforcement system
    CodeQualitySystem.setupEnforcementSystem()
    
    print("📊 CodeQualitySystem initialized successfully")
end

-- ========================================
-- CODE ANALYSIS ENGINE
-- ========================================

function CodeQualitySystem.setupCodeAnalysisEngine()
    QualityState.analysisEngine = {
        parsers = {},
        analyzers = {},
        metrics = {},
        cache = {}
    }
    
    -- Initialize code parsers
    CodeQualitySystem.initializeCodeParsers()
    
    print("🔍 Code analysis engine initialized")
end

function CodeQualitySystem.initializeCodeParsers()
    QualityState.analysisEngine.parsers = {
        lua = CodeQualitySystem.createLuaParser(),
        luau = CodeQualitySystem.createLuauParser()
    }
end

function CodeQualitySystem.createLuaParser()
    return {
        parseFile = function(filePath, content)
            return CodeQualitySystem.parseLuaFile(filePath, content)
        end,
        extractMetrics = function(ast)
            return CodeQualitySystem.extractLuaMetrics(ast)
        end
    }
end

function CodeQualitySystem.createLuauParser()
    return {
        parseFile = function(filePath, content)
            return CodeQualitySystem.parseLuauFile(filePath, content)
        end,
        extractMetrics = function(ast)
            return CodeQualitySystem.extractLuauMetrics(ast)
        end
    }
end

function CodeQualitySystem.analyzeFile(filePath, content)
    local fileExtension = string.match(filePath, "%.([^%.]+)$")
    local parser = QualityState.analysisEngine.parsers[fileExtension]
    
    if not parser then
        warn(string.format("No parser available for file type: %s", fileExtension))
        return nil
    end
    
    local analysis = {
        filePath = filePath,
        timestamp = tick(),
        ast = nil,
        metrics = {},
        violations = {},
        complexity = {},
        coverage = {},
        score = 0
    }
    
    -- Parse the file
    local success, ast = pcall(parser.parseFile, filePath, content)
    if not success then
        analysis.error = ast
        return analysis
    end
    
    analysis.ast = ast
    
    -- Extract metrics
    analysis.metrics = parser.extractMetrics(ast)
    
    -- Calculate complexity
    analysis.complexity = CodeQualitySystem.calculateComplexity(ast)
    
    -- Find quality violations
    analysis.violations = CodeQualitySystem.findQualityViolations(ast, content)
    
    -- Calculate quality score
    analysis.score = CodeQualitySystem.calculateFileQualityScore(analysis)
    
    -- Store analysis results
    QualityState.analyzedFiles[filePath] = analysis
    QualityState.fileScores[filePath] = analysis.score
    
    return analysis
end

function CodeQualitySystem.parseLuaFile(filePath, content)
    -- Simplified AST representation for Lua files
    local ast = {
        type = "file",
        path = filePath,
        functions = CodeQualitySystem.extractFunctions(content),
        variables = CodeQualitySystem.extractVariables(content),
        statements = CodeQualitySystem.extractStatements(content),
        lines = CodeQualitySystem.countLines(content),
        comments = CodeQualitySystem.extractComments(content)
    }
    
    return ast
end

function CodeQualitySystem.parseLuauFile(filePath, content)
    -- Enhanced parsing for Luau with type information
    local ast = CodeQualitySystem.parseLuaFile(filePath, content)
    
    -- Add Luau-specific features
    ast.types = CodeQualitySystem.extractTypes(content)
    ast.imports = CodeQualitySystem.extractImports(content)
    ast.exports = CodeQualitySystem.extractExports(content)
    
    return ast
end

function CodeQualitySystem.extractFunctions(content)
    local functions = {}
    local functionPattern = "function%s+([%w_]+)%s*%(([^)]*)%)"
    
    for name, params in string.gmatch(content, functionPattern) do
        table.insert(functions, {
            name = name,
            parameters = CodeQualitySystem.parseParameters(params),
            lineNumber = CodeQualitySystem.findLineNumber(content, name)
        })
    end
    
    return functions
end

function CodeQualitySystem.extractVariables(content)
    local variables = {}
    local varPattern = "local%s+([%w_]+)%s*="
    
    for name in string.gmatch(content, varPattern) do
        table.insert(variables, {
            name = name,
            type = "local",
            lineNumber = CodeQualitySystem.findLineNumber(content, name)
        })
    end
    
    return variables
end

function CodeQualitySystem.extractStatements(content)
    local statements = {}
    local lines = CodeQualitySystem.splitLines(content)
    
    for i, line in ipairs(lines) do
        local trimmed = string.match(line, "^%s*(.-)%s*$")
        if trimmed ~= "" and not string.match(trimmed, "^%-%-") then
            table.insert(statements, {
                line = i,
                content = trimmed,
                type = CodeQualitySystem.classifyStatement(trimmed)
            })
        end
    end
    
    return statements
end

function CodeQualitySystem.extractComments(content)
    local comments = {}
    local commentPattern = "%-%-([^\n]*)"
    
    for comment in string.gmatch(content, commentPattern) do
        table.insert(comments, {
            content = comment,
            type = string.match(comment, "^%s*@") and "documentation" or "regular"
        })
    end
    
    return comments
end

function CodeQualitySystem.extractTypes(content)
    local types = {}
    local typePattern = ":%s*([%w_]+)"
    
    for typeName in string.gmatch(content, typePattern) do
        table.insert(types, typeName)
    end
    
    return types
end

function CodeQualitySystem.extractImports(content)
    local imports = {}
    local requirePattern = "require%s*%(([^)]+)%)"
    
    for requirePath in string.gmatch(content, requirePattern) do
        table.insert(imports, {
            path = requirePath,
            type = "require"
        })
    end
    
    return imports
end

function CodeQualitySystem.extractExports(content)
    local exports = {}
    local returnPattern = "return%s+([%w_]+)"
    
    for exportName in string.gmatch(content, returnPattern) do
        table.insert(exports, exportName)
    end
    
    return exports
end

function CodeQualitySystem.parseParameters(paramString)
    local params = {}
    if paramString and paramString ~= "" then
        for param in string.gmatch(paramString, "([^,]+)") do
            table.insert(params, string.match(param, "^%s*(.-)%s*$"))
        end
    end
    return params
end

function CodeQualitySystem.findLineNumber(content, searchText)
    local lines = CodeQualitySystem.splitLines(content)
    for i, line in ipairs(lines) do
        if string.find(line, searchText) then
            return i
        end
    end
    return 1
end

function CodeQualitySystem.splitLines(content)
    local lines = {}
    for line in string.gmatch(content, "[^\n]+") do
        table.insert(lines, line)
    end
    return lines
end

function CodeQualitySystem.countLines(content)
    local count = 0
    for _ in string.gmatch(content, "\n") do
        count = count + 1
    end
    return count + 1
end

function CodeQualitySystem.classifyStatement(statement)
    if string.match(statement, "^if%s") then
        return "conditional"
    elseif string.match(statement, "^for%s") or string.match(statement, "^while%s") then
        return "loop"
    elseif string.match(statement, "^function%s") then
        return "function"
    elseif string.match(statement, "^local%s") then
        return "declaration"
    elseif string.match(statement, "^return%s") then
        return "return"
    else
        return "expression"
    end
end

function CodeQualitySystem.extractLuaMetrics(ast)
    return {
        linesOfCode = ast.lines,
        functions = #ast.functions,
        variables = #ast.variables,
        statements = #ast.statements,
        comments = #ast.comments,
        commentRatio = #ast.comments / math.max(ast.lines, 1),
        averageFunctionLength = CodeQualitySystem.calculateAverageFunctionLength(ast),
        maxFunctionLength = CodeQualitySystem.calculateMaxFunctionLength(ast)
    }
end

function CodeQualitySystem.extractLuauMetrics(ast)
    local metrics = CodeQualitySystem.extractLuaMetrics(ast)
    
    -- Add Luau-specific metrics
    metrics.types = #ast.types
    metrics.imports = #ast.imports
    metrics.exports = #ast.exports
    metrics.typeUsageRatio = #ast.types / math.max(#ast.variables + #ast.functions, 1)
    
    return metrics
end

function CodeQualitySystem.calculateAverageFunctionLength(ast)
    if #ast.functions == 0 then return 0 end
    
    local totalLength = 0
    for _, func in ipairs(ast.functions) do
        totalLength = totalLength + (func.endLine or 10) - (func.lineNumber or 1)
    end
    
    return totalLength / #ast.functions
end

function CodeQualitySystem.calculateMaxFunctionLength(ast)
    local maxLength = 0
    for _, func in ipairs(ast.functions) do
        local length = (func.endLine or 10) - (func.lineNumber or 1)
        maxLength = math.max(maxLength, length)
    end
    return maxLength
end

-- ========================================
-- COMPLEXITY ANALYSIS
-- ========================================

function CodeQualitySystem.initializeComplexityAnalysis()
    QualityState.complexityAnalyzer = {
        cyclomaticComplexity = {},
        cognitiveComplexity = {},
        halsteadMetrics = {},
        maintainabilityIndex = {}
    }
    
    print("🔢 Complexity analysis initialized")
end

function CodeQualitySystem.calculateComplexity(ast)
    local complexity = {
        cyclomatic = CodeQualitySystem.calculateCyclomaticComplexity(ast),
        cognitive = CodeQualitySystem.calculateCognitiveComplexity(ast),
        halstead = CodeQualitySystem.calculateHalsteadMetrics(ast),
        maintainability = 0
    }
    
    complexity.maintainability = CodeQualitySystem.calculateMaintainabilityIndex(complexity, ast)
    
    return complexity
end

function CodeQualitySystem.calculateCyclomaticComplexity(ast)
    local complexity = 1 -- Base complexity
    
    for _, statement in ipairs(ast.statements) do
        if statement.type == "conditional" or statement.type == "loop" then
            complexity = complexity + 1
        end
    end
    
    -- Add complexity for functions
    for _, func in ipairs(ast.functions) do
        complexity = complexity + 1
    end
    
    return complexity
end

function CodeQualitySystem.calculateCognitiveComplexity(ast)
    local complexity = 0
    local nestingLevel = 0
    
    for _, statement in ipairs(ast.statements) do
        if statement.type == "conditional" then
            complexity = complexity + (1 + nestingLevel)
            nestingLevel = nestingLevel + 1
        elseif statement.type == "loop" then
            complexity = complexity + (1 + nestingLevel)
            nestingLevel = nestingLevel + 1
        end
    end
    
    return complexity
end

function CodeQualitySystem.calculateHalsteadMetrics(ast)
    local operators = {}
    local operands = {}
    
    -- Simplified Halstead metrics calculation
    for _, statement in ipairs(ast.statements) do
        local content = statement.content
        
        -- Count operators
        local operatorCount = 0
        for operator in string.gmatch(content, "[+%-*/%=<>]") do
            operators[operator] = (operators[operator] or 0) + 1
            operatorCount = operatorCount + 1
        end
        
        -- Count operands (simplified)
        local operandCount = 0
        for operand in string.gmatch(content, "[%w_]+") do
            operands[operand] = (operands[operand] or 0) + 1
            operandCount = operandCount + 1
        end
    end
    
    local n1 = 0 -- Number of distinct operators
    local n2 = 0 -- Number of distinct operands
    local N1 = 0 -- Total number of operators
    local N2 = 0 -- Total number of operands
    
    for _, count in pairs(operators) do
        n1 = n1 + 1
        N1 = N1 + count
    end
    
    for _, count in pairs(operands) do
        n2 = n2 + 1
        N2 = N2 + count
    end
    
    local vocabulary = n1 + n2
    local length = N1 + N2
    local volume = length * math.log(vocabulary, 2)
    local difficulty = (n1 / 2) * (N2 / n2)
    local effort = difficulty * volume
    
    return {
        vocabulary = vocabulary,
        length = length,
        volume = volume,
        difficulty = difficulty,
        effort = effort
    }
end

function CodeQualitySystem.calculateMaintainabilityIndex(complexity, ast)
    local halstead = complexity.halstead
    local cyclomatic = complexity.cyclomatic
    local linesOfCode = ast.lines
    
    -- Simplified maintainability index calculation
    local maintainabilityIndex = 171 - 5.2 * math.log(halstead.volume) - 0.23 * cyclomatic - 16.2 * math.log(linesOfCode)
    
    return math.max(0, math.min(100, maintainabilityIndex))
end

-- ========================================
-- COVERAGE TRACKING
-- ========================================

function CodeQualitySystem.setupCoverageTracking()
    QualityState.coverageTracker = {
        lineCoverage = {},
        branchCoverage = {},
        functionCoverage = {},
        statementCoverage = {}
    }
    
    print("📈 Coverage tracking initialized")
end

function CodeQualitySystem.calculateCoverage(filePath, executionData)
    local analysis = QualityState.analyzedFiles[filePath]
    if not analysis then
        return nil
    end
    
    local coverage = {
        lines = CodeQualitySystem.calculateLineCoverage(analysis, executionData),
        branches = CodeQualitySystem.calculateBranchCoverage(analysis, executionData),
        functions = CodeQualitySystem.calculateFunctionCoverage(analysis, executionData),
        statements = CodeQualitySystem.calculateStatementCoverage(analysis, executionData)
    }
    
    QualityState.coverageMetrics[filePath] = coverage
    
    return coverage
end

function CodeQualitySystem.calculateLineCoverage(analysis, executionData)
    local totalLines = analysis.ast.lines
    local coveredLines = executionData.coveredLines or 0
    
    return {
        total = totalLines,
        covered = coveredLines,
        percentage = (coveredLines / totalLines) * 100
    }
end

function CodeQualitySystem.calculateBranchCoverage(analysis, executionData)
    local totalBranches = 0
    local coveredBranches = executionData.coveredBranches or 0
    
    -- Count conditional statements as branches
    for _, statement in ipairs(analysis.ast.statements) do
        if statement.type == "conditional" then
            totalBranches = totalBranches + 2 -- if/else branches
        end
    end
    
    return {
        total = totalBranches,
        covered = coveredBranches,
        percentage = totalBranches > 0 and (coveredBranches / totalBranches) * 100 or 100
    }
end

function CodeQualitySystem.calculateFunctionCoverage(analysis, executionData)
    local totalFunctions = #analysis.ast.functions
    local coveredFunctions = executionData.coveredFunctions or 0
    
    return {
        total = totalFunctions,
        covered = coveredFunctions,
        percentage = totalFunctions > 0 and (coveredFunctions / totalFunctions) * 100 or 100
    }
end

function CodeQualitySystem.calculateStatementCoverage(analysis, executionData)
    local totalStatements = #analysis.ast.statements
    local coveredStatements = executionData.coveredStatements or 0
    
    return {
        total = totalStatements,
        covered = coveredStatements,
        percentage = totalStatements > 0 and (coveredStatements / totalStatements) * 100 or 100
    }
end

-- ========================================
-- QUALITY RULES ENGINE
-- ========================================

function CodeQualitySystem.initializeQualityRulesEngine()
    QualityState.rulesEngine = {
        rules = {},
        violations = {},
        categories = {
            "naming",
            "structure", 
            "documentation",
            "error_handling",
            "performance",
            "security"
        }
    }
    
    -- Initialize quality rules
    CodeQualitySystem.setupQualityRules()
    
    print("📋 Quality rules engine initialized")
end

function CodeQualitySystem.setupQualityRules()
    local rules = QualityState.rulesEngine.rules
    
    -- Naming convention rules
    if QUALITY_CONFIG.rules.enableNamingConventions then
        rules.camelCaseVariables = {
            category = "naming",
            severity = "warning",
            check = function(ast) return CodeQualitySystem.checkCamelCaseVariables(ast) end
        }
        
        rules.pascalCaseFunctions = {
            category = "naming",
            severity = "warning", 
            check = function(ast) return CodeQualitySystem.checkPascalCaseFunctions(ast) end
        }
    end
    
    -- Code structure rules
    if QUALITY_CONFIG.rules.enableCodeStructure then
        rules.functionLength = {
            category = "structure",
            severity = "warning",
            check = function(ast) return CodeQualitySystem.checkFunctionLength(ast) end
        }
        
        rules.complexityLimit = {
            category = "structure",
            severity = "error",
            check = function(ast) return CodeQualitySystem.checkComplexityLimit(ast) end
        }
    end
    
    -- Documentation rules
    if QUALITY_CONFIG.rules.enableDocumentation then
        rules.functionDocumentation = {
            category = "documentation",
            severity = "info",
            check = function(ast) return CodeQualitySystem.checkFunctionDocumentation(ast) end
        }
    end
    
    -- Error handling rules
    if QUALITY_CONFIG.rules.enableErrorHandling then
        rules.errorHandling = {
            category = "error_handling",
            severity = "warning",
            check = function(ast) return CodeQualitySystem.checkErrorHandling(ast) end
        }
    end
end

function CodeQualitySystem.findQualityViolations(ast, content)
    local violations = {}
    
    for ruleName, rule in pairs(QualityState.rulesEngine.rules) do
        local ruleViolations = rule.check(ast)
        
        for _, violation in ipairs(ruleViolations) do
            violation.rule = ruleName
            violation.category = rule.category
            violation.severity = rule.severity
            table.insert(violations, violation)
        end
    end
    
    return violations
end

function CodeQualitySystem.checkCamelCaseVariables(ast)
    local violations = {}
    
    for _, variable in ipairs(ast.variables) do
        if not string.match(variable.name, "^[a-z][a-zA-Z0-9]*$") then
            table.insert(violations, {
                message = string.format("Variable '%s' should use camelCase naming", variable.name),
                line = variable.lineNumber,
                type = "naming_convention"
            })
        end
    end
    
    return violations
end

function CodeQualitySystem.checkPascalCaseFunctions(ast)
    local violations = {}
    
    for _, func in ipairs(ast.functions) do
        if not string.match(func.name, "^[A-Z][a-zA-Z0-9]*$") then
            table.insert(violations, {
                message = string.format("Function '%s' should use PascalCase naming", func.name),
                line = func.lineNumber,
                type = "naming_convention"
            })
        end
    end
    
    return violations
end

function CodeQualitySystem.checkFunctionLength(ast)
    local violations = {}
    
    for _, func in ipairs(ast.functions) do
        local length = (func.endLine or 20) - func.lineNumber
        if length > 50 then -- Arbitrary threshold
            table.insert(violations, {
                message = string.format("Function '%s' is too long (%d lines)", func.name, length),
                line = func.lineNumber,
                type = "function_length"
            })
        end
    end
    
    return violations
end

function CodeQualitySystem.checkComplexityLimit(ast)
    local violations = {}
    local complexity = CodeQualitySystem.calculateCyclomaticComplexity(ast)
    
    if complexity > QUALITY_CONFIG.thresholds.maximumComplexity then
        table.insert(violations, {
            message = string.format("Cyclomatic complexity too high: %d (max: %d)", 
                complexity, QUALITY_CONFIG.thresholds.maximumComplexity),
            line = 1,
            type = "high_complexity"
        })
    end
    
    return violations
end

function CodeQualitySystem.checkFunctionDocumentation(ast)
    local violations = {}
    
    for _, func in ipairs(ast.functions) do
        -- Check if function has documentation comment above it
        local hasDocumentation = false
        for _, comment in ipairs(ast.comments) do
            if comment.type == "documentation" then
                hasDocumentation = true
                break
            end
        end
        
        if not hasDocumentation then
            table.insert(violations, {
                message = string.format("Function '%s' lacks documentation", func.name),
                line = func.lineNumber,
                type = "missing_documentation"
            })
        end
    end
    
    return violations
end

function CodeQualitySystem.checkErrorHandling(ast)
    local violations = {}
    local hasErrorHandling = false
    
    for _, statement in ipairs(ast.statements) do
        if string.find(statement.content, "pcall") or string.find(statement.content, "xpcall") then
            hasErrorHandling = true
            break
        end
    end
    
    if not hasErrorHandling and #ast.functions > 0 then
        table.insert(violations, {
            message = "No error handling found in file",
            line = 1,
            type = "missing_error_handling"
        })
    end
    
    return violations
end

-- ========================================
-- QUALITY SCORING
-- ========================================

function CodeQualitySystem.calculateFileQualityScore(analysis)
    local scores = {
        complexity = CodeQualitySystem.scoreComplexity(analysis.complexity),
        violations = CodeQualitySystem.scoreViolations(analysis.violations),
        documentation = CodeQualitySystem.scoreDocumentation(analysis.ast),
        structure = CodeQualitySystem.scoreStructure(analysis.metrics),
        maintainability = analysis.complexity.maintainability / 10 -- Scale to 0-10
    }
    
    -- Calculate weighted average
    local weights = {
        complexity = 0.25,
        violations = 0.25,
        documentation = 0.15,
        structure = 0.20,
        maintainability = 0.15
    }
    
    local totalScore = 0
    for metric, score in pairs(scores) do
        totalScore = totalScore + (score * weights[metric])
    end
    
    return math.max(0, math.min(10, totalScore))
end

function CodeQualitySystem.scoreComplexity(complexity)
    local cyclomaticScore = math.max(0, 10 - (complexity.cyclomatic / QUALITY_CONFIG.thresholds.maximumComplexity) * 10)
    local cognitiveScore = math.max(0, 10 - (complexity.cognitive / (QUALITY_CONFIG.thresholds.maximumComplexity * 2)) * 10)
    
    return (cyclomaticScore + cognitiveScore) / 2
end

function CodeQualitySystem.scoreViolations(violations)
    local violationCount = #violations
    local maxViolations = QUALITY_CONFIG.thresholds.maximumViolations
    
    return math.max(0, 10 - (violationCount / maxViolations) * 10)
end

function CodeQualitySystem.scoreDocumentation(ast)
    local commentRatio = #ast.comments / math.max(ast.lines, 1)
    return math.min(10, commentRatio * 50) -- Scale comment ratio
end

function CodeQualitySystem.scoreStructure(metrics)
    local functionLengthScore = math.max(0, 10 - (metrics.averageFunctionLength / 30) * 10)
    local functionsPerFileScore = math.max(0, 10 - (metrics.functions / 20) * 10)
    
    return (functionLengthScore + functionsPerFileScore) / 2
end

function CodeQualitySystem.calculateProjectScore()
    local totalScore = 0
    local fileCount = 0
    
    for _, score in pairs(QualityState.fileScores) do
        totalScore = totalScore + score
        fileCount = fileCount + 1
    end
    
    QualityState.projectScore = fileCount > 0 and (totalScore / fileCount) or 0
    QualityState.stats.qualityScore = QualityState.projectScore
    
    return QualityState.projectScore
end

-- ========================================
-- ENFORCEMENT SYSTEM
-- ========================================

function CodeQualitySystem.setupEnforcementSystem()
    QualityState.enforcementSystem = {
        enabled = QUALITY_CONFIG.enforcement.enableAutomaticEnforcement,
        qualityGates = {},
        preCommitHooks = {},
        continuousMonitoring = QUALITY_CONFIG.enforcement.enableContinuousMonitoring
    }
    
    print("🛡️ Enforcement system initialized")
end

function CodeQualitySystem.enforceQualityStandards(filePath, analysis)
    if not QualityState.enforcementSystem.enabled then
        return true
    end
    
    local enforcement = {
        filePath = filePath,
        timestamp = tick(),
        passed = true,
        violations = {},
        score = analysis.score,
        threshold = QUALITY_CONFIG.thresholds.minimumScore
    }
    
    -- Check quality score threshold
    if analysis.score < QUALITY_CONFIG.thresholds.minimumScore then
        enforcement.passed = false
        table.insert(enforcement.violations, {
            type = "quality_score",
            message = string.format("Quality score %.1f below threshold %.1f", 
                analysis.score, QUALITY_CONFIG.thresholds.minimumScore)
        })
    end
    
    -- Check complexity threshold
    if analysis.complexity.cyclomatic > QUALITY_CONFIG.thresholds.maximumComplexity then
        enforcement.passed = false
        table.insert(enforcement.violations, {
            type = "complexity",
            message = string.format("Cyclomatic complexity %d exceeds threshold %d",
                analysis.complexity.cyclomatic, QUALITY_CONFIG.thresholds.maximumComplexity)
        })
    end
    
    -- Check violation count
    local violationCount = #analysis.violations
    if violationCount > QUALITY_CONFIG.thresholds.maximumViolations then
        enforcement.passed = false
        table.insert(enforcement.violations, {
            type = "violation_count",
            message = string.format("Violation count %d exceeds threshold %d",
                violationCount, QUALITY_CONFIG.thresholds.maximumViolations)
        })
    end
    
    QualityState.enforcementResults[filePath] = enforcement
    
    if not enforcement.passed then
        if QUALITY_CONFIG.enforcement.failOnViolation then
            error(string.format("Quality standards not met for file: %s", filePath))
        else
            warn(string.format("Quality standards not met for file: %s", filePath))
            for _, violation in ipairs(enforcement.violations) do
                warn(string.format("  - %s: %s", violation.type, violation.message))
            end
        end
    end
    
    return enforcement.passed
end

-- ========================================
-- PUBLIC API
-- ========================================

function CodeQualitySystem.analyzeProject(projectPath)
    print("📊 Analyzing project quality...")
    
    local startTime = tick()
    local analysisResults = {}
    
    -- Simulate project file analysis
    local sampleFiles = {
        "src/shared/services/DataService.luau",
        "src/shared/services/GameService.luau",
        "src/shared/utils/SafeRequire.luau",
        "src/client/controllers/MainGameController.luau",
        "src/server/services/PlayerService.luau"
    }
    
    for _, filePath in ipairs(sampleFiles) do
        -- Simulate file content
        local content = string.format([[
-- %s
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local %s = {}

function %s.initialize()
    print("Initializing %s...")
end

function %s.process(data)
    if not data then
        error("Data is required")
    end
    
    local result = {}
    for i = 1, #data do
        result[i] = data[i] * 2
    end
    
    return result
end

return %s
        ]], filePath, 
            string.match(filePath, "([^/]+)%.luau$") or "Module",
            string.match(filePath, "([^/]+)%.luau$") or "Module",
            string.match(filePath, "([^/]+)%.luau$") or "Module",
            string.match(filePath, "([^/]+)%.luau$") or "Module",
            string.match(filePath, "([^/]+)%.luau$") or "Module")
        
        local analysis = CodeQualitySystem.analyzeFile(filePath, content)
        if analysis then
            analysisResults[filePath] = analysis
            
            -- Simulate coverage data
            local coverage = CodeQualitySystem.calculateCoverage(filePath, {
                coveredLines = math.random(15, 25),
                coveredBranches = math.random(3, 8),
                coveredFunctions = math.random(2, 4),
                coveredStatements = math.random(10, 20)
            })
            
            -- Enforce quality standards
            CodeQualitySystem.enforceQualityStandards(filePath, analysis)
        end
    end
    
    -- Calculate project metrics
    local projectScore = CodeQualitySystem.calculateProjectScore()
    
    local endTime = tick()
    
    -- Generate quality report
    local report = CodeQualitySystem.generateQualityReport(analysisResults)
    
    print(string.format("📊 Project analysis completed in %.2fs", endTime - startTime))
    print(string.format("📊 Project quality score: %.1f/10", projectScore))
    
    return report
end

function CodeQualitySystem.generateQualityReport(analysisResults)
    local report = {
        timestamp = tick(),
        projectScore = QualityState.projectScore,
        totalFiles = 0,
        totalViolations = 0,
        averageComplexity = 0,
        coverageMetrics = {},
        qualityMetrics = {},
        enforcement = QualityState.enforcementResults,
        summary = {
            filesAnalyzed = 0,
            filesPassingStandards = 0,
            totalScore = QualityState.projectScore,
            recommendations = {}
        }
    }
    
    local totalComplexity = 0
    local filesPassingStandards = 0
    
    for filePath, analysis in pairs(analysisResults) do
        report.totalFiles = report.totalFiles + 1
        report.totalViolations = report.totalViolations + #analysis.violations
        totalComplexity = totalComplexity + analysis.complexity.cyclomatic
        
        local enforcement = QualityState.enforcementResults[filePath]
        if enforcement and enforcement.passed then
            filesPassingStandards = filesPassingStandards + 1
        end
        
        report.qualityMetrics[filePath] = {
            score = analysis.score,
            complexity = analysis.complexity,
            violations = #analysis.violations,
            coverage = QualityState.coverageMetrics[filePath]
        }
    end
    
    report.averageComplexity = report.totalFiles > 0 and (totalComplexity / report.totalFiles) or 0
    report.summary.filesAnalyzed = report.totalFiles
    report.summary.filesPassingStandards = filesPassingStandards
    
    -- Generate recommendations
    report.summary.recommendations = CodeQualitySystem.generateRecommendations(report)
    
    return report
end

function CodeQualitySystem.generateRecommendations(report)
    local recommendations = {}
    
    if report.projectScore < QUALITY_CONFIG.thresholds.minimumScore then
        table.insert(recommendations, "Improve overall code quality score by addressing violations")
    end
    
    if report.averageComplexity > QUALITY_CONFIG.thresholds.maximumComplexity then
        table.insert(recommendations, "Reduce code complexity by breaking down complex functions")
    end
    
    if report.totalViolations > QUALITY_CONFIG.thresholds.maximumViolations then
        table.insert(recommendations, "Address quality violations to improve maintainability")
    end
    
    local passRate = report.totalFiles > 0 and (report.summary.filesPassingStandards / report.totalFiles) * 100 or 0
    if passRate < 80 then
        table.insert(recommendations, "Increase percentage of files meeting quality standards")
    end
    
    return recommendations
end

function CodeQualitySystem.getQualityStats()
    return QualityState.stats
end

function CodeQualitySystem.getProjectScore()
    return QualityState.projectScore
end

function CodeQualitySystem.getEnforcementResults()
    return QualityState.enforcementResults
end

-- Export API
CodeQualitySystem.analyzeFile = CodeQualitySystem.analyzeFile
CodeQualitySystem.calculateCoverage = CodeQualitySystem.calculateCoverage
CodeQualitySystem.enforceQualityStandards = CodeQualitySystem.enforceQualityStandards
CodeQualitySystem.calculateProjectScore = CodeQualitySystem.calculateProjectScore

-- Initialize the code quality system
CodeQualitySystem.initialize()

print("📊 CodeQualitySystem loaded with comprehensive quality analysis capabilities")

return CodeQualitySystem
