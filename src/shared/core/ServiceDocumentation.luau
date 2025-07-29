-- ServiceDocumentation.luau
-- Comprehensive service documentation and API reference system
-- Handles automatic documentation generation, API specs, and interactive docs

local HttpService = game:GetService("HttpService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local ServiceDocumentation = {}

-- ========================================
-- DOCUMENTATION REGISTRY
-- ========================================

local DOCUMENTATION_REGISTRY = {}
local API_SPECIFICATIONS = {}
local EXAMPLE_REGISTRY = {}
local CHANGELOG_REGISTRY = {}

-- ========================================
-- SERVICE DOCUMENTATION REGISTRATION
-- ========================================

function ServiceDocumentation:RegisterServiceDocumentation(serviceName, documentation)
    DOCUMENTATION_REGISTRY[serviceName] = {
        name = serviceName,
        description = documentation.description or "",
        version = documentation.version or "1.0.0",
        author = documentation.author or "Unknown",
        category = documentation.category or "General",
        tags = documentation.tags or {},
        overview = documentation.overview or "",
        architecture = documentation.architecture or {},
        dependencies = documentation.dependencies or {},
        configuration = documentation.configuration or {},
        troubleshooting = documentation.troubleshooting or {},
        performance = documentation.performance or {},
        security = documentation.security or {},
        registeredAt = tick(),
        lastUpdated = tick()
    }
    
    print("📚 Registered documentation for: " .. serviceName)
end

function ServiceDocumentation:UpdateServiceDocumentation(serviceName, updates)
    local doc = DOCUMENTATION_REGISTRY[serviceName]
    if not doc then
        error("❌ Documentation not found for service: " .. serviceName)
    end
    
    for key, value in pairs(updates) do
        doc[key] = value
    end
    doc.lastUpdated = tick()
    
    print("📝 Updated documentation for: " .. serviceName)
end

function ServiceDocumentation:GetServiceDocumentation(serviceName)
    return DOCUMENTATION_REGISTRY[serviceName]
end

function ServiceDocumentation:GetAllDocumentation()
    return DOCUMENTATION_REGISTRY
end

-- ========================================
-- API SPECIFICATION MANAGEMENT
-- ========================================

function ServiceDocumentation:RegisterAPISpecification(serviceName, apiSpec)
    if not API_SPECIFICATIONS[serviceName] then
        API_SPECIFICATIONS[serviceName] = {}
    end
    
    API_SPECIFICATIONS[serviceName][apiSpec.version] = {
        version = apiSpec.version,
        title = apiSpec.title or serviceName .. " API",
        description = apiSpec.description or "",
        baseUrl = apiSpec.baseUrl or "",
        methods = apiSpec.methods or {},
        events = apiSpec.events or {},
        dataTypes = apiSpec.dataTypes or {},
        errorCodes = apiSpec.errorCodes or {},
        authentication = apiSpec.authentication or {},
        rateLimit = apiSpec.rateLimit or {},
        examples = apiSpec.examples or {},
        changelog = apiSpec.changelog or {},
        registeredAt = tick()
    }
    
    print("🔌 Registered API specification: " .. serviceName .. " v" .. apiSpec.version)
end

function ServiceDocumentation:GetAPISpecification(serviceName, version)
    local serviceSpecs = API_SPECIFICATIONS[serviceName]
    if not serviceSpecs then
        return nil
    end
    
    if version then
        return serviceSpecs[version]
    else
        -- Return latest version
        local latestVersion = nil
        local latestSpec = nil
        
        for v, spec in pairs(serviceSpecs) do
            if not latestVersion or self:CompareVersions(v, latestVersion) > 0 then
                latestVersion = v
                latestSpec = spec
            end
        end
        
        return latestSpec
    end
end

-- ========================================
-- METHOD DOCUMENTATION
-- ========================================

function ServiceDocumentation:DocumentMethod(serviceName, methodName, methodDoc)
    local doc = DOCUMENTATION_REGISTRY[serviceName]
    if not doc then
        error("❌ Service documentation not found: " .. serviceName)
    end
    
    if not doc.methods then
        doc.methods = {}
    end
    
    doc.methods[methodName] = {
        name = methodName,
        description = methodDoc.description or "",
        parameters = methodDoc.parameters or {},
        returnValue = methodDoc.returnValue or {},
        throws = methodDoc.throws or {},
        examples = methodDoc.examples or {},
        notes = methodDoc.notes or {},
        deprecated = methodDoc.deprecated or false,
        since = methodDoc.since or doc.version,
        complexity = methodDoc.complexity or "O(1)",
        async = methodDoc.async or false,
        tags = methodDoc.tags or {}
    }
    
    doc.lastUpdated = tick()
    print("📝 Documented method: " .. serviceName .. "." .. methodName)
end

function ServiceDocumentation:DocumentEvent(serviceName, eventName, eventDoc)
    local doc = DOCUMENTATION_REGISTRY[serviceName]
    if not doc then
        error("❌ Service documentation not found: " .. serviceName)
    end
    
    if not doc.events then
        doc.events = {}
    end
    
    doc.events[eventName] = {
        name = eventName,
        description = eventDoc.description or "",
        parameters = eventDoc.parameters or {},
        frequency = eventDoc.frequency or "Variable",
        reliability = eventDoc.reliability or "Guaranteed",
        examples = eventDoc.examples or {},
        notes = eventDoc.notes or {},
        since = eventDoc.since or doc.version,
        tags = eventDoc.tags or {}
    }
    
    doc.lastUpdated = tick()
    print("📡 Documented event: " .. serviceName .. "." .. eventName)
end

function ServiceDocumentation:DocumentProperty(serviceName, propertyName, propertyDoc)
    local doc = DOCUMENTATION_REGISTRY[serviceName]
    if not doc then
        error("❌ Service documentation not found: " .. serviceName)
    end
    
    if not doc.properties then
        doc.properties = {}
    end
    
    doc.properties[propertyName] = {
        name = propertyName,
        description = propertyDoc.description or "",
        type = propertyDoc.type or "any",
        default = propertyDoc.default,
        readonly = propertyDoc.readonly or false,
        nullable = propertyDoc.nullable or false,
        deprecated = propertyDoc.deprecated or false,
        since = propertyDoc.since or doc.version,
        examples = propertyDoc.examples or {},
        validation = propertyDoc.validation or {},
        tags = propertyDoc.tags or {}
    }
    
    doc.lastUpdated = tick()
    print("📄 Documented property: " .. serviceName .. "." .. propertyName)
end

-- ========================================
-- EXAMPLE MANAGEMENT
-- ========================================

function ServiceDocumentation:AddExample(serviceName, exampleName, example)
    if not EXAMPLE_REGISTRY[serviceName] then
        EXAMPLE_REGISTRY[serviceName] = {}
    end
    
    EXAMPLE_REGISTRY[serviceName][exampleName] = {
        name = exampleName,
        title = example.title or exampleName,
        description = example.description or "",
        category = example.category or "General",
        difficulty = example.difficulty or "Beginner",
        code = example.code or "",
        explanation = example.explanation or "",
        expectedOutput = example.expectedOutput or "",
        requirements = example.requirements or {},
        tags = example.tags or {},
        author = example.author or "Unknown",
        createdAt = tick()
    }
    
    print("📋 Added example: " .. serviceName .. " - " .. exampleName)
end

function ServiceDocumentation:GetExamples(serviceName, category)
    local serviceExamples = EXAMPLE_REGISTRY[serviceName] or {}
    
    if not category then
        return serviceExamples
    end
    
    local filteredExamples = {}
    for name, example in pairs(serviceExamples) do
        if example.category == category then
            filteredExamples[name] = example
        end
    end
    
    return filteredExamples
end

-- ========================================
-- CHANGELOG MANAGEMENT
-- ========================================

function ServiceDocumentation:AddChangelogEntry(serviceName, version, entry)
    if not CHANGELOG_REGISTRY[serviceName] then
        CHANGELOG_REGISTRY[serviceName] = {}
    end
    
    if not CHANGELOG_REGISTRY[serviceName][version] then
        CHANGELOG_REGISTRY[serviceName][version] = {
            version = version,
            releaseDate = entry.releaseDate or os.date("%Y-%m-%d"),
            entries = {}
        }
    end
    
    table.insert(CHANGELOG_REGISTRY[serviceName][version].entries, {
        type = entry.type or "feature", -- feature, bugfix, breaking, deprecated
        description = entry.description or "",
        impact = entry.impact or "minor", -- major, minor, patch
        migration = entry.migration or "",
        author = entry.author or "Unknown",
        ticketId = entry.ticketId or ""
    })
    
    print("📝 Added changelog entry: " .. serviceName .. " v" .. version)
end

function ServiceDocumentation:GetChangelog(serviceName, version)
    local serviceChangelog = CHANGELOG_REGISTRY[serviceName]
    if not serviceChangelog then
        return {}
    end
    
    if version then
        return serviceChangelog[version] or {}
    else
        return serviceChangelog
    end
end

-- ========================================
-- AUTOMATIC DOCUMENTATION GENERATION
-- ========================================

function ServiceDocumentation:GenerateServiceOverview(serviceName)
    local doc = DOCUMENTATION_REGISTRY[serviceName]
    if not doc then
        return "No documentation found for service: " .. serviceName
    end
    
    local overview = {}
    
    -- Header
    table.insert(overview, "# " .. doc.name)
    table.insert(overview, "")
    table.insert(overview, doc.description)
    table.insert(overview, "")
    
    -- Metadata
    table.insert(overview, "## Service Information")
    table.insert(overview, "- **Version:** " .. doc.version)
    table.insert(overview, "- **Author:** " .. doc.author)
    table.insert(overview, "- **Category:** " .. doc.category)
    if #doc.tags > 0 then
        table.insert(overview, "- **Tags:** " .. table.concat(doc.tags, ", "))
    end
    table.insert(overview, "")
    
    -- Architecture
    if doc.architecture and next(doc.architecture) then
        table.insert(overview, "## Architecture")
        for section, content in pairs(doc.architecture) do
            table.insert(overview, "### " .. section)
            table.insert(overview, content)
            table.insert(overview, "")
        end
    end
    
    -- Dependencies
    if doc.dependencies and next(doc.dependencies) then
        table.insert(overview, "## Dependencies")
        for depName, depInfo in pairs(doc.dependencies) do
            table.insert(overview, "- **" .. depName .. ":** " .. (depInfo.description or ""))
        end
        table.insert(overview, "")
    end
    
    return table.concat(overview, "\n")
end

function ServiceDocumentation:GenerateAPIReference(serviceName)
    local doc = DOCUMENTATION_REGISTRY[serviceName]
    local apiSpec = self:GetAPISpecification(serviceName)
    
    if not doc then
        return "No documentation found for service: " .. serviceName
    end
    
    local reference = {}
    
    -- Header
    table.insert(reference, "# " .. doc.name .. " API Reference")
    table.insert(reference, "")
    
    if apiSpec then
        table.insert(reference, apiSpec.description)
        table.insert(reference, "")
    end
    
    -- Methods
    if doc.methods and next(doc.methods) then
        table.insert(reference, "## Methods")
        table.insert(reference, "")
        
        for methodName, method in pairs(doc.methods) do
            table.insert(reference, "### " .. methodName)
            table.insert(reference, "")
            table.insert(reference, method.description)
            table.insert(reference, "")
            
            -- Parameters
            if method.parameters and #method.parameters > 0 then
                table.insert(reference, "**Parameters:**")
                for _, param in ipairs(method.parameters) do
                    local paramStr = "- `" .. param.name .. "` (" .. param.type .. ")"
                    if param.optional then
                        paramStr = paramStr .. " *optional*"
                    end
                    paramStr = paramStr .. ": " .. (param.description or "")
                    table.insert(reference, paramStr)
                end
                table.insert(reference, "")
            end
            
            -- Return value
            if method.returnValue and method.returnValue.type then
                table.insert(reference, "**Returns:** `" .. method.returnValue.type .. "` - " .. (method.returnValue.description or ""))
                table.insert(reference, "")
            end
            
            -- Examples
            if method.examples and #method.examples > 0 then
                table.insert(reference, "**Example:**")
                table.insert(reference, "```lua")
                table.insert(reference, method.examples[1])
                table.insert(reference, "```")
                table.insert(reference, "")
            end
        end
    end
    
    -- Events
    if doc.events and next(doc.events) then
        table.insert(reference, "## Events")
        table.insert(reference, "")
        
        for eventName, event in pairs(doc.events) do
            table.insert(reference, "### " .. eventName)
            table.insert(reference, "")
            table.insert(reference, event.description)
            table.insert(reference, "")
            
            if event.parameters and #event.parameters > 0 then
                table.insert(reference, "**Parameters:**")
                for _, param in ipairs(event.parameters) do
                    table.insert(reference, "- `" .. param.name .. "` (" .. param.type .. "): " .. (param.description or ""))
                end
                table.insert(reference, "")
            end
        end
    end
    
    return table.concat(reference, "\n")
end

function ServiceDocumentation:GenerateQuickStart(serviceName)
    local doc = DOCUMENTATION_REGISTRY[serviceName]
    local examples = EXAMPLE_REGISTRY[serviceName] or {}
    
    if not doc then
        return "No documentation found for service: " .. serviceName
    end
    
    local quickStart = {}
    
    table.insert(quickStart, "# " .. doc.name .. " Quick Start")
    table.insert(quickStart, "")
    table.insert(quickStart, doc.overview or doc.description)
    table.insert(quickStart, "")
    
    -- Basic usage example
    local basicExample = nil
    for _, example in pairs(examples) do
        if example.category == "Basic" or example.difficulty == "Beginner" then
            basicExample = example
            break
        end
    end
    
    if basicExample then
        table.insert(quickStart, "## Basic Usage")
        table.insert(quickStart, "")
        table.insert(quickStart, basicExample.description)
        table.insert(quickStart, "")
        table.insert(quickStart, "```lua")
        table.insert(quickStart, basicExample.code)
        table.insert(quickStart, "```")
        table.insert(quickStart, "")
        
        if basicExample.explanation then
            table.insert(quickStart, basicExample.explanation)
            table.insert(quickStart, "")
        end
    end
    
    -- Configuration
    if doc.configuration and next(doc.configuration) then
        table.insert(quickStart, "## Configuration")
        table.insert(quickStart, "")
        for configName, configInfo in pairs(doc.configuration) do
            table.insert(quickStart, "### " .. configName)
            table.insert(quickStart, configInfo.description or "")
            table.insert(quickStart, "")
        end
    end
    
    return table.concat(quickStart, "\n")
end

-- ========================================
-- INTERACTIVE DOCUMENTATION
-- ========================================

function ServiceDocumentation:CreateInteractiveExample(serviceName, exampleName)
    local examples = EXAMPLE_REGISTRY[serviceName]
    if not examples or not examples[exampleName] then
        return nil, "Example not found"
    end
    
    local example = examples[exampleName]
    
    -- Create executable version of the example
    local interactiveExample = {
        title = example.title,
        description = example.description,
        code = example.code,
        execute = function()
            local success, result = pcall(function()
                return loadstring(example.code)()
            end)
            
            return {
                success = success,
                result = result,
                output = success and tostring(result) or result,
                timestamp = tick()
            }
        end,
        getExpectedOutput = function()
            return example.expectedOutput
        end
    }
    
    return interactiveExample
end

function ServiceDocumentation:CreateDocumentationSite(serviceName)
    local doc = DOCUMENTATION_REGISTRY[serviceName]
    if not doc then
        return nil, "Service documentation not found"
    end
    
    local site = {
        serviceName = serviceName,
        overview = self:GenerateServiceOverview(serviceName),
        apiReference = self:GenerateAPIReference(serviceName),
        quickStart = self:GenerateQuickStart(serviceName),
        examples = EXAMPLE_REGISTRY[serviceName] or {},
        changelog = CHANGELOG_REGISTRY[serviceName] or {},
        searchIndex = self:BuildSearchIndex(serviceName),
        navigation = self:BuildNavigation(serviceName),
        generatedAt = tick()
    }
    
    return site
end

-- ========================================
-- SEARCH AND INDEXING
-- ========================================

function ServiceDocumentation:BuildSearchIndex(serviceName)
    local doc = DOCUMENTATION_REGISTRY[serviceName]
    if not doc then
        return {}
    end
    
    local index = {}
    
    -- Index service information
    self:AddToIndex(index, "service", serviceName, doc.description, doc.name)
    
    -- Index methods
    if doc.methods then
        for methodName, method in pairs(doc.methods) do
            self:AddToIndex(index, "method", methodName, method.description, serviceName .. "." .. methodName)
        end
    end
    
    -- Index events
    if doc.events then
        for eventName, event in pairs(doc.events) do
            self:AddToIndex(index, "event", eventName, event.description, serviceName .. "." .. eventName)
        end
    end
    
    -- Index examples
    local examples = EXAMPLE_REGISTRY[serviceName] or {}
    for exampleName, example in pairs(examples) do
        self:AddToIndex(index, "example", exampleName, example.description, example.title)
    end
    
    return index
end

function ServiceDocumentation:AddToIndex(index, type, name, description, fullName)
    local entry = {
        type = type,
        name = name,
        description = description,
        fullName = fullName,
        keywords = self:ExtractKeywords(name .. " " .. description)
    }
    
    table.insert(index, entry)
end

function ServiceDocumentation:ExtractKeywords(text)
    local keywords = {}
    local words = {}
    
    -- Split text into words
    for word in string.gmatch(string.lower(text), "%w+") do
        if #word > 2 then -- Skip very short words
            words[word] = true
        end
    end
    
    for word in pairs(words) do
        table.insert(keywords, word)
    end
    
    return keywords
end

function ServiceDocumentation:SearchDocumentation(serviceName, query)
    local index = self:BuildSearchIndex(serviceName)
    local results = {}
    local queryLower = string.lower(query)
    
    for _, entry in ipairs(index) do
        local score = 0
        
        -- Check name match
        if string.find(string.lower(entry.name), queryLower) then
            score = score + 10
        end
        
        -- Check description match
        if string.find(string.lower(entry.description), queryLower) then
            score = score + 5
        end
        
        -- Check keyword match
        for _, keyword in ipairs(entry.keywords) do
            if string.find(keyword, queryLower) then
                score = score + 3
            end
        end
        
        if score > 0 then
            table.insert(results, {
                entry = entry,
                score = score
            })
        end
    end
    
    -- Sort by score
    table.sort(results, function(a, b)
        return a.score > b.score
    end)
    
    return results
end

-- ========================================
-- UTILITY FUNCTIONS
-- ========================================

function ServiceDocumentation:CompareVersions(version1, version2)
    local function parseVersion(v)
        local parts = {}
        for part in string.gmatch(v, "[^%.]+") do
            table.insert(parts, tonumber(part) or 0)
        end
        return parts
    end
    
    local v1 = parseVersion(version1)
    local v2 = parseVersion(version2)
    
    for i = 1, math.max(#v1, #v2) do
        local n1 = v1[i] or 0
        local n2 = v2[i] or 0
        
        if n1 > n2 then
            return 1
        elseif n1 < n2 then
            return -1
        end
    end
    
    return 0
end

function ServiceDocumentation:BuildNavigation(serviceName)
    local doc = DOCUMENTATION_REGISTRY[serviceName]
    if not doc then
        return {}
    end
    
    local navigation = {
        {section = "Overview", path = "/overview"},
        {section = "Quick Start", path = "/quickstart"},
        {section = "API Reference", path = "/api"}
    }
    
    if doc.methods and next(doc.methods) then
        table.insert(navigation, {section = "Methods", path = "/api/methods"})
    end
    
    if doc.events and next(doc.events) then
        table.insert(navigation, {section = "Events", path = "/api/events"})
    end
    
    local examples = EXAMPLE_REGISTRY[serviceName] or {}
    if next(examples) then
        table.insert(navigation, {section = "Examples", path = "/examples"})
    end
    
    local changelog = CHANGELOG_REGISTRY[serviceName] or {}
    if next(changelog) then
        table.insert(navigation, {section = "Changelog", path = "/changelog"})
    end
    
    return navigation
end

function ServiceDocumentation:ExportDocumentation(serviceName, format)
    format = format or "json"
    
    local exportData = {
        serviceName = serviceName,
        documentation = DOCUMENTATION_REGISTRY[serviceName],
        apiSpecification = API_SPECIFICATIONS[serviceName],
        examples = EXAMPLE_REGISTRY[serviceName],
        changelog = CHANGELOG_REGISTRY[serviceName],
        exportedAt = tick(),
        format = format
    }
    
    if format == "json" then
        return HttpService:JSONEncode(exportData)
    else
        return exportData
    end
end

function ServiceDocumentation:PrintDocumentationStatus()
    print("\n" .. "=".rep(60))
    print("📚 DOCUMENTATION STATUS")
    print("=".rep(60))
    
    local totalServices = 0
    local documentedServices = 0
    local totalMethods = 0
    local totalEvents = 0
    local totalExamples = 0
    
    for serviceName, doc in pairs(DOCUMENTATION_REGISTRY) do
        totalServices = totalServices + 1
        if doc.description and doc.description ~= "" then
            documentedServices = documentedServices + 1
        end
        
        if doc.methods then
            for _ in pairs(doc.methods) do
                totalMethods = totalMethods + 1
            end
        end
        
        if doc.events then
            for _ in pairs(doc.events) do
                totalEvents = totalEvents + 1
            end
        end
    end
    
    for _, examples in pairs(EXAMPLE_REGISTRY) do
        for _ in pairs(examples) do
            totalExamples = totalExamples + 1
        end
    end
    
    print("Documented Services: " .. documentedServices .. "/" .. totalServices)
    print("Total Methods: " .. totalMethods)
    print("Total Events: " .. totalEvents)
    print("Total Examples: " .. totalExamples)
    print("=".rep(60) .. "\n")
end

return ServiceDocumentation
