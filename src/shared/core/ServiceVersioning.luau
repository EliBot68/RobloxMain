-- ServiceVersioning.luau
-- Service versioning and backward compatibility management
-- Handles service migrations, API versioning, and compatibility layers

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local HttpService = game:GetService("HttpService")

local ServiceVersioning = {}

-- ========================================
-- VERSION MANAGEMENT
-- ========================================

local VERSION_REGISTRY = {}
local COMPATIBILITY_LAYERS = {}
local MIGRATION_HANDLERS = {}

-- Version comparison utility
local function compareVersions(version1, version2)
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

-- ========================================
-- SERVICE VERSION REGISTRATION
-- ========================================

function ServiceVersioning:RegisterServiceVersion(serviceName, version, implementation, metadata)
    if not VERSION_REGISTRY[serviceName] then
        VERSION_REGISTRY[serviceName] = {}
    end
    
    VERSION_REGISTRY[serviceName][version] = {
        implementation = implementation,
        metadata = metadata or {},
        registeredAt = tick(),
        isActive = false
    }
    
    print("📝 Registered service version: " .. serviceName .. " v" .. version)
end

function ServiceVersioning:SetActiveVersion(serviceName, version)
    local serviceVersions = VERSION_REGISTRY[serviceName]
    if not serviceVersions or not serviceVersions[version] then
        error("❌ Service version not found: " .. serviceName .. " v" .. version)
    end
    
    -- Deactivate other versions
    for v, versionInfo in pairs(serviceVersions) do
        versionInfo.isActive = false
    end
    
    -- Activate target version
    serviceVersions[version].isActive = true
    
    print("✅ Activated service version: " .. serviceName .. " v" .. version)
end

function ServiceVersioning:GetActiveVersion(serviceName)
    local serviceVersions = VERSION_REGISTRY[serviceName]
    if not serviceVersions then
        return nil
    end
    
    for version, versionInfo in pairs(serviceVersions) do
        if versionInfo.isActive then
            return version, versionInfo.implementation
        end
    end
    
    return nil
end

function ServiceVersioning:GetAllVersions(serviceName)
    return VERSION_REGISTRY[serviceName] or {}
end

function ServiceVersioning:GetLatestVersion(serviceName)
    local serviceVersions = VERSION_REGISTRY[serviceName]
    if not serviceVersions then
        return nil
    end
    
    local latestVersion = nil
    for version, _ in pairs(serviceVersions) do
        if not latestVersion or compareVersions(version, latestVersion) > 0 then
            latestVersion = version
        end
    end
    
    return latestVersion
end

-- ========================================
-- BACKWARD COMPATIBILITY
-- ========================================

function ServiceVersioning:AddCompatibilityLayer(serviceName, fromVersion, toVersion, adapter)
    local key = serviceName .. ":" .. fromVersion .. "->" .. toVersion
    COMPATIBILITY_LAYERS[key] = {
        serviceName = serviceName,
        fromVersion = fromVersion,
        toVersion = toVersion,
        adapter = adapter,
        createdAt = tick()
    }
    
    print("🔄 Added compatibility layer: " .. key)
end

function ServiceVersioning:GetCompatibilityAdapter(serviceName, fromVersion, toVersion)
    local key = serviceName .. ":" .. fromVersion .. "->" .. toVersion
    local layer = COMPATIBILITY_LAYERS[key]
    return layer and layer.adapter or nil
end

function ServiceVersioning:CreateVersionProxy(serviceName, targetVersion)
    local activeVersion, activeImplementation = self:GetActiveVersion(serviceName)
    
    if not activeImplementation then
        error("❌ No active version found for service: " .. serviceName)
    end
    
    if activeVersion == targetVersion then
        return activeImplementation
    end
    
    -- Create proxy with compatibility layer
    local adapter = self:GetCompatibilityAdapter(serviceName, targetVersion, activeVersion)
    if not adapter then
        warn("⚠️ No compatibility adapter found for " .. serviceName .. " v" .. targetVersion .. " -> v" .. activeVersion)
        return activeImplementation
    end
    
    local proxy = {}
    setmetatable(proxy, {
        __index = function(_, key)
            local method = activeImplementation[key]
            if type(method) == "function" and adapter[key] then
                -- Apply compatibility transformation
                return function(self, ...)
                    local transformedArgs = adapter[key].transformInput and adapter[key].transformInput(...) or {...}
                    local result = method(activeImplementation, unpack(transformedArgs))
                    return adapter[key].transformOutput and adapter[key].transformOutput(result) or result
                end
            else
                return method
            end
        end
    })
    
    return proxy
end

-- ========================================
-- MIGRATION MANAGEMENT
-- ========================================

function ServiceVersioning:RegisterMigration(serviceName, fromVersion, toVersion, migrationHandler)
    local key = serviceName .. ":" .. fromVersion .. "->" .. toVersion
    MIGRATION_HANDLERS[key] = {
        serviceName = serviceName,
        fromVersion = fromVersion,
        toVersion = toVersion,
        handler = migrationHandler,
        executedAt = nil
    }
    
    print("📦 Registered migration: " .. key)
end

function ServiceVersioning:ExecuteMigration(serviceName, fromVersion, toVersion, data)
    local key = serviceName .. ":" .. fromVersion .. "->" .. toVersion
    local migration = MIGRATION_HANDLERS[key]
    
    if not migration then
        warn("⚠️ No migration handler found for: " .. key)
        return false, "Migration handler not found"
    end
    
    print("🔄 Executing migration: " .. key)
    
    local success, result = pcall(migration.handler, data)
    
    if success then
        migration.executedAt = tick()
        print("✅ Migration completed: " .. key)
        return true, result
    else
        warn("❌ Migration failed: " .. key .. " - " .. tostring(result))
        return false, result
    end
end

function ServiceVersioning:GetMigrationPath(serviceName, fromVersion, toVersion)
    -- Find sequence of migrations to get from fromVersion to toVersion
    local path = {}
    local visited = {}
    local queue = {{version = fromVersion, path = {}}}
    
    while #queue > 0 do
        local current = table.remove(queue, 1)
        local currentVersion = current.version
        local currentPath = current.path
        
        if currentVersion == toVersion then
            return currentPath
        end
        
        if visited[currentVersion] then
            continue
        end
        visited[currentVersion] = true
        
        -- Find all possible next versions
        for migrationKey, migration in pairs(MIGRATION_HANDLERS) do
            if migration.serviceName == serviceName and migration.fromVersion == currentVersion then
                local nextVersion = migration.toVersion
                local newPath = {}
                for _, step in ipairs(currentPath) do
                    table.insert(newPath, step)
                end
                table.insert(newPath, migration)
                
                table.insert(queue, {version = nextVersion, path = newPath})
            end
        end
    end
    
    return nil -- No migration path found
end

function ServiceVersioning:AutoMigrate(serviceName, fromVersion, toVersion, data)
    local migrationPath = self:GetMigrationPath(serviceName, fromVersion, toVersion)
    
    if not migrationPath then
        return false, "No migration path found from v" .. fromVersion .. " to v" .. toVersion
    end
    
    local currentData = data
    for _, migration in ipairs(migrationPath) do
        local success, result = self:ExecuteMigration(
            migration.serviceName,
            migration.fromVersion,
            migration.toVersion,
            currentData
        )
        
        if not success then
            return false, "Migration failed at step " .. migration.fromVersion .. " -> " .. migration.toVersion .. ": " .. tostring(result)
        end
        
        currentData = result
    end
    
    return true, currentData
end

-- ========================================
-- API VERSIONING
-- ========================================

local API_VERSIONS = {}

function ServiceVersioning:RegisterAPIVersion(serviceName, apiVersion, endpoints)
    if not API_VERSIONS[serviceName] then
        API_VERSIONS[serviceName] = {}
    end
    
    API_VERSIONS[serviceName][apiVersion] = {
        endpoints = endpoints,
        registeredAt = tick(),
        deprecated = false,
        deprecationDate = nil
    }
    
    print("🔌 Registered API version: " .. serviceName .. " API v" .. apiVersion)
end

function ServiceVersioning:DeprecateAPIVersion(serviceName, apiVersion, deprecationDate)
    local apiVersions = API_VERSIONS[serviceName]
    if apiVersions and apiVersions[apiVersion] then
        apiVersions[apiVersion].deprecated = true
        apiVersions[apiVersion].deprecationDate = deprecationDate or tick()
        
        warn("⚠️ API version deprecated: " .. serviceName .. " API v" .. apiVersion)
    end
end

function ServiceVersioning:GetAPIEndpoint(serviceName, apiVersion, endpointName)
    local apiVersions = API_VERSIONS[serviceName]
    if not apiVersions or not apiVersions[apiVersion] then
        return nil, "API version not found"
    end
    
    local versionInfo = apiVersions[apiVersion]
    if versionInfo.deprecated then
        warn("⚠️ Using deprecated API: " .. serviceName .. " API v" .. apiVersion)
    end
    
    local endpoint = versionInfo.endpoints[endpointName]
    if not endpoint then
        return nil, "Endpoint not found"
    end
    
    return endpoint, nil
end

function ServiceVersioning:GetSupportedAPIVersions(serviceName)
    local versions = {}
    local apiVersions = API_VERSIONS[serviceName]
    
    if apiVersions then
        for version, info in pairs(apiVersions) do
            table.insert(versions, {
                version = version,
                deprecated = info.deprecated,
                deprecationDate = info.deprecationDate,
                registeredAt = info.registeredAt
            })
        end
    end
    
    return versions
end

-- ========================================
-- VERSION COMPATIBILITY MATRIX
-- ========================================

function ServiceVersioning:GenerateCompatibilityMatrix(serviceName)
    local versions = {}
    local serviceVersions = VERSION_REGISTRY[serviceName] or {}
    
    for version, _ in pairs(serviceVersions) do
        table.insert(versions, version)
    end
    
    table.sort(versions, function(a, b)
        return compareVersions(a, b) < 0
    end)
    
    local matrix = {}
    for i, fromVersion in ipairs(versions) do
        matrix[fromVersion] = {}
        for j, toVersion in ipairs(versions) do
            if i == j then
                matrix[fromVersion][toVersion] = "SAME"
            else
                local adapter = self:GetCompatibilityAdapter(serviceName, fromVersion, toVersion)
                local migrationPath = self:GetMigrationPath(serviceName, fromVersion, toVersion)
                
                if adapter then
                    matrix[fromVersion][toVersion] = "COMPATIBLE"
                elseif migrationPath then
                    matrix[fromVersion][toVersion] = "MIGRATION_AVAILABLE"
                else
                    matrix[fromVersion][toVersion] = "INCOMPATIBLE"
                end
            end
        end
    end
    
    return {
        serviceName = serviceName,
        versions = versions,
        matrix = matrix,
        generatedAt = tick()
    }
end

-- ========================================
-- VERSION HEALTH MONITORING
-- ========================================

function ServiceVersioning:GetVersionHealth(serviceName)
    local health = {
        serviceName = serviceName,
        activeVersion = nil,
        availableVersions = 0,
        deprecatedVersions = 0,
        migrationPaths = 0,
        compatibilityLayers = 0,
        issues = {}
    }
    
    local activeVersion = self:GetActiveVersion(serviceName)
    health.activeVersion = activeVersion
    
    local serviceVersions = VERSION_REGISTRY[serviceName] or {}
    health.availableVersions = 0
    for _ in pairs(serviceVersions) do
        health.availableVersions = health.availableVersions + 1
    end
    
    -- Count migrations and compatibility layers
    for key, migration in pairs(MIGRATION_HANDLERS) do
        if migration.serviceName == serviceName then
            health.migrationPaths = health.migrationPaths + 1
        end
    end
    
    for key, layer in pairs(COMPATIBILITY_LAYERS) do
        if layer.serviceName == serviceName then
            health.compatibilityLayers = health.compatibilityLayers + 1
        end
    end
    
    -- Check for issues
    if not activeVersion then
        table.insert(health.issues, "No active version set")
    end
    
    if health.availableVersions > 5 then
        table.insert(health.issues, "Too many versions available - consider cleanup")
    end
    
    if health.migrationPaths == 0 and health.availableVersions > 1 then
        table.insert(health.issues, "Multiple versions but no migration paths")
    end
    
    return health
end

function ServiceVersioning:GetAllServicesHealth()
    local allHealth = {}
    
    for serviceName, _ in pairs(VERSION_REGISTRY) do
        allHealth[serviceName] = self:GetVersionHealth(serviceName)
    end
    
    return allHealth
end

-- ========================================
-- REPORTING AND UTILITIES
-- ========================================

function ServiceVersioning:PrintVersionReport(serviceName)
    local health = self:GetVersionHealth(serviceName)
    local matrix = self:GenerateCompatibilityMatrix(serviceName)
    
    print("\n" .. "=".rep(60))
    print("📊 VERSION REPORT: " .. serviceName)
    print("=".rep(60))
    print("Active Version: " .. (health.activeVersion or "NONE"))
    print("Available Versions: " .. health.availableVersions)
    print("Migration Paths: " .. health.migrationPaths)
    print("Compatibility Layers: " .. health.compatibilityLayers)
    
    if #health.issues > 0 then
        print("\n⚠️ Issues:")
        for _, issue in ipairs(health.issues) do
            print("  - " .. issue)
        end
    end
    
    print("\n📋 Available Versions:")
    for _, version in ipairs(matrix.versions) do
        local status = (version == health.activeVersion) and " (ACTIVE)" or ""
        print("  - v" .. version .. status)
    end
    
    print("\n🔄 Compatibility Matrix:")
    print("From\\To\t" .. table.concat(matrix.versions, "\t"))
    for _, fromVersion in ipairs(matrix.versions) do
        local row = "v" .. fromVersion
        for _, toVersion in ipairs(matrix.versions) do
            local compatibility = matrix.matrix[fromVersion][toVersion]
            local symbol = compatibility == "SAME" and "=" or 
                          compatibility == "COMPATIBLE" and "✓" or
                          compatibility == "MIGRATION_AVAILABLE" and "M" or "✗"
            row = row .. "\t" .. symbol
        end
        print(row)
    end
    
    print("=".rep(60) .. "\n")
end

function ServiceVersioning:ExportVersionData(serviceName)
    local data = {
        serviceName = serviceName,
        versions = VERSION_REGISTRY[serviceName] or {},
        migrations = {},
        compatibilityLayers = {},
        apiVersions = API_VERSIONS[serviceName] or {},
        exportedAt = tick()
    }
    
    -- Export migrations
    for key, migration in pairs(MIGRATION_HANDLERS) do
        if migration.serviceName == serviceName then
            table.insert(data.migrations, migration)
        end
    end
    
    -- Export compatibility layers
    for key, layer in pairs(COMPATIBILITY_LAYERS) do
        if layer.serviceName == serviceName then
            table.insert(data.compatibilityLayers, layer)
        end
    end
    
    return HttpService:JSONEncode(data)
end

return ServiceVersioning
