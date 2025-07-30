-- ConsistencyChecker.luau
-- Data integrity and consistency validation system
-- Performs automated checks and repairs for data corruption

local DataStoreService = game:GetService("DataStoreService")
local HttpService = game:GetService("HttpService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local SafeRequire = require(ReplicatedStorage.Shared.utils.SafeRequire)
local ServiceArchitecture = SafeRequire.require(ReplicatedStorage.Shared.core.ServiceArchitecture)

local ConsistencyChecker = {}
ConsistencyChecker.__index = ConsistencyChecker

-- Implement IConsistencyChecker interface
setmetatable(ConsistencyChecker, {__index = ServiceArchitecture.IConsistencyChecker})

-- ========================================
-- CONSISTENCY CHECK CONFIGURATION
-- ========================================

local CHECK_CONFIG = {
    enableAutoChecks = true,
    checkInterval = 600, -- 10 minutes
    deepCheckInterval = 3600, -- 1 hour
    maxRepairAttempts = 3,
    autoRepair = true,
    quarantineCorrupted = true,
    alertThreshold = 0.05, -- 5% corruption rate
    batchSize = 25
}

local CHECK_TYPES = {
    STRUCTURAL = "structural",     -- Data structure validation
    REFERENTIAL = "referential",   -- Cross-reference validation
    BUSINESS = "business",         -- Business logic validation
    TEMPORAL = "temporal",         -- Time-based validation
    STATISTICAL = "statistical",  -- Statistical anomaly detection
    CHECKSUM = "checksum"         -- Data integrity validation
}

local SEVERITY_LEVELS = {
    LOW = 1,      -- Minor inconsistencies
    MEDIUM = 2,   -- Moderate issues
    HIGH = 3,     -- Serious problems
    CRITICAL = 4  -- Data corruption
}

-- ========================================
-- CORE CONSISTENCY CHECKER
-- ========================================

function ConsistencyChecker.new()
    local self = setmetatable({}, ConsistencyChecker)
    
    -- Check state
    self.activeChecks = {}
    self.checkHistory = {}
    self.quarantinedData = {}
    self.repairLog = {}
    
    -- Check definitions
    self.checks = {}
    self.customValidators = {}
    
    -- Statistics
    self.stats = {
        totalChecks = 0,
        checksExecuted = 0,
        issuesFound = 0,
        issuesRepaired = 0,
        dataQuarantined = 0,
        falsePositives = 0,
        avgCheckTime = 0,
        lastFullCheck = 0
    }
    
    -- Initialize check definitions
    self:RegisterBuiltInChecks()
    
    -- Start automated checking
    if CHECK_CONFIG.enableAutoChecks then
        self:StartAutomatedChecks()
    end
    
    print("🔍 ConsistencyChecker initialized with data integrity validation")
    return self
end

-- ========================================
-- CHECK REGISTRATION
-- ========================================

function ConsistencyChecker:RegisterBuiltInChecks()
    -- Structural consistency checks
    self:RegisterCheck(CHECK_TYPES.STRUCTURAL, "required_fields", function(data, context)
        return self:CheckRequiredFields(data, context)
    end, SEVERITY_LEVELS.HIGH)
    
    self:RegisterCheck(CHECK_TYPES.STRUCTURAL, "data_types", function(data, context)
        return self:CheckDataTypes(data, context)
    end, SEVERITY_LEVELS.MEDIUM)
    
    self:RegisterCheck(CHECK_TYPES.STRUCTURAL, "value_ranges", function(data, context)
        return self:CheckValueRanges(data, context)
    end, SEVERITY_LEVELS.MEDIUM)
    
    -- Referential consistency checks
    self:RegisterCheck(CHECK_TYPES.REFERENTIAL, "foreign_keys", function(data, context)
        return self:CheckForeignKeys(data, context)
    end, SEVERITY_LEVELS.HIGH)
    
    self:RegisterCheck(CHECK_TYPES.REFERENTIAL, "circular_references", function(data, context)
        return self:CheckCircularReferences(data, context)
    end, SEVERITY_LEVELS.MEDIUM)
    
    -- Business logic checks
    self:RegisterCheck(CHECK_TYPES.BUSINESS, "business_rules", function(data, context)
        return self:CheckBusinessRules(data, context)
    end, SEVERITY_LEVELS.HIGH)
    
    self:RegisterCheck(CHECK_TYPES.BUSINESS, "state_transitions", function(data, context)
        return self:CheckStateTransitions(data, context)
    end, SEVERITY_LEVELS.MEDIUM)
    
    -- Temporal checks
    self:RegisterCheck(CHECK_TYPES.TEMPORAL, "timestamp_validity", function(data, context)
        return self:CheckTimestamps(data, context)
    end, SEVERITY_LEVELS.MEDIUM)
    
    self:RegisterCheck(CHECK_TYPES.TEMPORAL, "temporal_ordering", function(data, context)
        return self:CheckTemporalOrdering(data, context)
    end, SEVERITY_LEVELS.LOW)
    
    -- Statistical checks
    self:RegisterCheck(CHECK_TYPES.STATISTICAL, "statistical_outliers", function(data, context)
        return self:CheckStatisticalOutliers(data, context)
    end, SEVERITY_LEVELS.LOW)
    
    -- Checksum validation
    self:RegisterCheck(CHECK_TYPES.CHECKSUM, "data_integrity", function(data, context)
        return self:CheckDataIntegrity(data, context)
    end, SEVERITY_LEVELS.CRITICAL)
    
    print("📋 Registered " .. self:CountChecks() .. " built-in consistency checks")
end

function ConsistencyChecker:RegisterCheck(checkType, checkName, checkFunction, severity)
    local checkId = checkType .. "_" .. checkName
    
    self.checks[checkId] = {
        id = checkId,
        type = checkType,
        name = checkName,
        function_ = checkFunction,
        severity = severity,
        enabled = true,
        registeredAt = os.time(),
        executionCount = 0,
        lastExecuted = 0,
        avgExecutionTime = 0
    }
    
    self.stats.totalChecks = self.stats.totalChecks + 1
end

-- ========================================
-- CHECK EXECUTION
-- ========================================

function ConsistencyChecker:CheckPlayerData(playerId, data, checkTypes)
    local checkId = self:GenerateCheckId(playerId)
    
    local checkSession = {
        checkId = checkId,
        playerId = playerId,
        startTime = os.time(),
        checkTypes = checkTypes or self:GetAllCheckTypes(),
        results = {},
        issues = {},
        repairs = {},
        status = "running"
    }
    
    self.activeChecks[checkId] = checkSession
    
    print("🔍 Starting consistency check for player " .. playerId .. " (" .. checkId .. ")")
    
    local context = {
        playerId = playerId,
        checkId = checkId,
        data = data,
        timestamp = os.time()
    }
    
    -- Execute checks by type
    for _, checkType in ipairs(checkSession.checkTypes) do
        local typeResults = self:ExecuteChecksOfType(checkType, data, context)
        checkSession.results[checkType] = typeResults
        
        -- Collect issues
        for _, result in ipairs(typeResults) do
            if not result.passed then
                table.insert(checkSession.issues, result)
            end
        end
    end
    
    -- Analyze and repair if enabled
    if CHECK_CONFIG.autoRepair and #checkSession.issues > 0 then
        checkSession.repairs = self:AttemptRepairs(playerId, data, checkSession.issues, context)
    end
    
    -- Finalize check session
    checkSession.endTime = os.time()
    checkSession.duration = checkSession.endTime - checkSession.startTime
    checkSession.status = "completed"
    
    self.activeChecks[checkId] = nil
    self.checkHistory[checkId] = checkSession
    
    -- Update statistics
    self.stats.checksExecuted = self.stats.checksExecuted + 1
    self.stats.issuesFound = self.stats.issuesFound + #checkSession.issues
    self.stats.issuesRepaired = self.stats.issuesRepaired + #checkSession.repairs
    self.stats.avgCheckTime = (self.stats.avgCheckTime * (self.stats.checksExecuted - 1) + checkSession.duration) / self.stats.checksExecuted
    
    print("✅ Consistency check completed for player " .. playerId .. 
          " (" .. #checkSession.issues .. " issues, " .. #checkSession.repairs .. " repairs)")
    
    return checkSession
end

function ConsistencyChecker:ExecuteChecksOfType(checkType, data, context)
    local results = {}
    
    for checkId, check in pairs(self.checks) do
        if check.type == checkType and check.enabled then
            local startTime = tick()
            
            local success, result = pcall(function()
                return check.function_(data, context)
            end)
            
            local endTime = tick()
            local executionTime = (endTime - startTime) * 1000 -- Convert to ms
            
            -- Update check statistics
            check.executionCount = check.executionCount + 1
            check.lastExecuted = os.time()
            check.avgExecutionTime = (check.avgExecutionTime * (check.executionCount - 1) + executionTime) / check.executionCount
            
            if success and result then
                result.checkId = checkId
                result.checkType = checkType
                result.executionTime = executionTime
                table.insert(results, result)
            else
                -- Check execution failed
                table.insert(results, {
                    checkId = checkId,
                    checkType = checkType,
                    passed = false,
                    severity = SEVERITY_LEVELS.CRITICAL,
                    issue = "Check execution failed",
                    details = {
                        error = tostring(result),
                        executionTime = executionTime
                    }
                })
            end
        end
    end
    
    return results
end

-- ========================================
-- BUILT-IN CHECK IMPLEMENTATIONS
-- ========================================

function ConsistencyChecker:CheckRequiredFields(data, context)
    local requiredFields = {"coins", "level", "experience", "highScore", "lastPlayed"}
    local missingFields = {}
    
    for _, field in ipairs(requiredFields) do
        if data[field] == nil then
            table.insert(missingFields, field)
        end
    end
    
    if #missingFields > 0 then
        return {
            passed = false,
            severity = SEVERITY_LEVELS.HIGH,
            issue = "Missing required fields",
            details = {
                missingFields = missingFields,
                fieldCount = #missingFields
            },
            autoRepair = true,
            repairAction = "add_default_values"
        }
    end
    
    return {
        passed = true,
        severity = SEVERITY_LEVELS.LOW,
        issue = nil
    }
end

function ConsistencyChecker:CheckDataTypes(data, context)
    local typeChecks = {
        coins = "number",
        level = "number",
        experience = "number",
        highScore = "number",
        lastPlayed = "number",
        settings = "table",
        upgrades = "table"
    }
    
    local typeErrors = {}
    
    for field, expectedType in pairs(typeChecks) do
        if data[field] ~= nil and type(data[field]) ~= expectedType then
            table.insert(typeErrors, {
                field = field,
                expectedType = expectedType,
                actualType = type(data[field]),
                value = data[field]
            })
        end
    end
    
    if #typeErrors > 0 then
        return {
            passed = false,
            severity = SEVERITY_LEVELS.MEDIUM,
            issue = "Data type mismatches",
            details = {
                typeErrors = typeErrors,
                errorCount = #typeErrors
            },
            autoRepair = true,
            repairAction = "fix_data_types"
        }
    end
    
    return {
        passed = true,
        severity = SEVERITY_LEVELS.LOW,
        issue = nil
    }
end

function ConsistencyChecker:CheckValueRanges(data, context)
    local rangeChecks = {
        coins = {min = 0, max = 999999999},
        level = {min = 1, max = 1000},
        experience = {min = 0, max = 999999999},
        highScore = {min = 0, max = 999999999}
    }
    
    local rangeErrors = {}
    
    for field, range in pairs(rangeChecks) do
        if type(data[field]) == "number" then
            if data[field] < range.min or data[field] > range.max then
                table.insert(rangeErrors, {
                    field = field,
                    value = data[field],
                    min = range.min,
                    max = range.max
                })
            end
        end
    end
    
    if #rangeErrors > 0 then
        return {
            passed = false,
            severity = SEVERITY_LEVELS.MEDIUM,
            issue = "Values out of valid range",
            details = {
                rangeErrors = rangeErrors,
                errorCount = #rangeErrors
            },
            autoRepair = true,
            repairAction = "clamp_values"
        }
    end
    
    return {
        passed = true,
        severity = SEVERITY_LEVELS.LOW,
        issue = nil
    }
end

function ConsistencyChecker:CheckBusinessRules(data, context)
    local violations = {}
    
    -- Experience should be consistent with level
    if type(data.level) == "number" and type(data.experience) == "number" then
        local expectedMinXP = (data.level - 1) * 100
        if data.experience < expectedMinXP then
            table.insert(violations, {
                rule = "experience_level_consistency",
                description = "Experience is too low for current level",
                level = data.level,
                experience = data.experience,
                expectedMinimum = expectedMinXP
            })
        end
    end
    
    -- High score should not exceed reasonable limits based on level
    if type(data.level) == "number" and type(data.highScore) == "number" then
        local maxReasonableScore = data.level * 10000
        if data.highScore > maxReasonableScore then
            table.insert(violations, {
                rule = "high_score_reasonableness",
                description = "High score seems unreasonably high for level",
                level = data.level,
                highScore = data.highScore,
                maxReasonable = maxReasonableScore
            })
        end
    end
    
    -- Coins should be reasonable
    if type(data.coins) == "number" and type(data.level) == "number" then
        local maxReasonableCoins = data.level * 50000
        if data.coins > maxReasonableCoins then
            table.insert(violations, {
                rule = "coin_reasonableness",
                description = "Coin amount seems unreasonably high for level",
                level = data.level,
                coins = data.coins,
                maxReasonable = maxReasonableCoins
            })
        end
    end
    
    if #violations > 0 then
        return {
            passed = false,
            severity = SEVERITY_LEVELS.HIGH,
            issue = "Business rule violations",
            details = {
                violations = violations,
                violationCount = #violations
            },
            autoRepair = false, -- Business rules often need manual review
            repairAction = "manual_review"
        }
    end
    
    return {
        passed = true,
        severity = SEVERITY_LEVELS.LOW,
        issue = nil
    }
end

function ConsistencyChecker:CheckTimestamps(data, context)
    local timestampErrors = {}
    local currentTime = os.time()
    
    -- Check lastPlayed timestamp
    if type(data.lastPlayed) == "number" then
        if data.lastPlayed > currentTime then
            table.insert(timestampErrors, {
                field = "lastPlayed",
                value = data.lastPlayed,
                currentTime = currentTime,
                issue = "Future timestamp"
            })
        elseif data.lastPlayed < 1000000000 then -- Before 2001
            table.insert(timestampErrors, {
                field = "lastPlayed",
                value = data.lastPlayed,
                issue = "Unreasonably old timestamp"
            })
        end
    end
    
    -- Check other timestamps
    if data.joinDate and type(data.joinDate) == "number" then
        if data.joinDate > currentTime then
            table.insert(timestampErrors, {
                field = "joinDate",
                value = data.joinDate,
                currentTime = currentTime,
                issue = "Future timestamp"
            })
        end
    end
    
    if #timestampErrors > 0 then
        return {
            passed = false,
            severity = SEVERITY_LEVELS.MEDIUM,
            issue = "Invalid timestamps",
            details = {
                timestampErrors = timestampErrors,
                errorCount = #timestampErrors
            },
            autoRepair = true,
            repairAction = "fix_timestamps"
        }
    end
    
    return {
        passed = true,
        severity = SEVERITY_LEVELS.LOW,
        issue = nil
    }
end

function ConsistencyChecker:CheckDataIntegrity(data, context)
    -- Check for data corruption indicators
    local corruptionSigns = {}
    
    -- Check for string corruption
    for key, value in pairs(data) do
        if type(value) == "string" then
            -- Check for null bytes or control characters
            if string.find(value, "\0") then
                table.insert(corruptionSigns, {
                    field = key,
                    issue = "Contains null bytes",
                    value = value
                })
            end
        end
    end
    
    -- Check for circular references
    local visited = {}
    local function checkCircular(obj, path)
        if type(obj) == "table" then
            if visited[obj] then
                table.insert(corruptionSigns, {
                    issue = "Circular reference detected",
                    path = path
                })
                return
            end
            
            visited[obj] = true
            for k, v in pairs(obj) do
                checkCircular(v, path .. "." .. tostring(k))
            end
            visited[obj] = nil
        end
    end
    
    checkCircular(data, "root")
    
    if #corruptionSigns > 0 then
        return {
            passed = false,
            severity = SEVERITY_LEVELS.CRITICAL,
            issue = "Data corruption detected",
            details = {
                corruptionSigns = corruptionSigns,
                signCount = #corruptionSigns
            },
            autoRepair = false,
            repairAction = "quarantine"
        }
    end
    
    return {
        passed = true,
        severity = SEVERITY_LEVELS.LOW,
        issue = nil
    }
end

function ConsistencyChecker:CheckForeignKeys(data, context)
    -- Placeholder for foreign key validation
    return {
        passed = true,
        severity = SEVERITY_LEVELS.LOW,
        issue = nil
    }
end

function ConsistencyChecker:CheckCircularReferences(data, context)
    -- Already implemented in CheckDataIntegrity
    return {
        passed = true,
        severity = SEVERITY_LEVELS.LOW,
        issue = nil
    }
end

function ConsistencyChecker:CheckStateTransitions(data, context)
    -- Placeholder for state transition validation
    return {
        passed = true,
        severity = SEVERITY_LEVELS.LOW,
        issue = nil
    }
end

function ConsistencyChecker:CheckTemporalOrdering(data, context)
    -- Placeholder for temporal ordering validation
    return {
        passed = true,
        severity = SEVERITY_LEVELS.LOW,
        issue = nil
    }
end

function ConsistencyChecker:CheckStatisticalOutliers(data, context)
    -- Placeholder for statistical outlier detection
    return {
        passed = true,
        severity = SEVERITY_LEVELS.LOW,
        issue = nil
    }
end

-- ========================================
-- REPAIR MECHANISMS
-- ========================================

function ConsistencyChecker:AttemptRepairs(playerId, data, issues, context)
    local repairs = {}
    
    for _, issue in ipairs(issues) do
        if issue.autoRepair then
            local repair = self:ExecuteRepair(playerId, data, issue, context)
            if repair then
                table.insert(repairs, repair)
            end
        else
            -- Log non-repairable issues for manual review
            self:LogIssueForManualReview(playerId, issue, context)
        end
    end
    
    return repairs
end

function ConsistencyChecker:ExecuteRepair(playerId, data, issue, context)
    local repairAction = issue.repairAction
    local repairResult = {
        repairId = self:GenerateRepairId(),
        playerId = playerId,
        issue = issue,
        repairAction = repairAction,
        timestamp = os.time(),
        success = false,
        changes = {}
    }
    
    local success = false
    
    if repairAction == "add_default_values" then
        success = self:RepairMissingFields(data, issue, repairResult)
    elseif repairAction == "fix_data_types" then
        success = self:RepairDataTypes(data, issue, repairResult)
    elseif repairAction == "clamp_values" then
        success = self:RepairValueRanges(data, issue, repairResult)
    elseif repairAction == "fix_timestamps" then
        success = self:RepairTimestamps(data, issue, repairResult)
    elseif repairAction == "quarantine" then
        success = self:QuarantineData(playerId, data, issue, repairResult)
    end
    
    repairResult.success = success
    
    if success then
        print("🔧 Repaired issue: " .. issue.issue .. " for player " .. playerId)
    else
        warn("❌ Failed to repair issue: " .. issue.issue .. " for player " .. playerId)
    end
    
    return repairResult
end

function ConsistencyChecker:RepairMissingFields(data, issue, repairResult)
    local defaultValues = {
        coins = 0,
        level = 1,
        experience = 0,
        highScore = 0,
        lastPlayed = os.time(),
        settings = {},
        upgrades = {},
        achievements = {},
        cosmetics = {equipped = {}, owned = {}}
    }
    
    for _, field in ipairs(issue.details.missingFields) do
        if defaultValues[field] ~= nil then
            data[field] = defaultValues[field]
            table.insert(repairResult.changes, {
                field = field,
                action = "added",
                value = defaultValues[field]
            })
        end
    end
    
    return #repairResult.changes > 0
end

function ConsistencyChecker:RepairDataTypes(data, issue, repairResult)
    for _, typeError in ipairs(issue.details.typeErrors) do
        local field = typeError.field
        local expectedType = typeError.expectedType
        local currentValue = data[field]
        
        local newValue = nil
        
        if expectedType == "number" and type(currentValue) == "string" then
            newValue = tonumber(currentValue)
        elseif expectedType == "string" and type(currentValue) == "number" then
            newValue = tostring(currentValue)
        elseif expectedType == "table" and type(currentValue) ~= "table" then
            newValue = {}
        end
        
        if newValue ~= nil then
            data[field] = newValue
            table.insert(repairResult.changes, {
                field = field,
                action = "type_conversion",
                oldValue = currentValue,
                newValue = newValue,
                oldType = type(currentValue),
                newType = type(newValue)
            })
        end
    end
    
    return #repairResult.changes > 0
end

function ConsistencyChecker:RepairValueRanges(data, issue, repairResult)
    for _, rangeError in ipairs(issue.details.rangeErrors) do
        local field = rangeError.field
        local value = rangeError.value
        local min = rangeError.min
        local max = rangeError.max
        
        local clampedValue = math.max(min, math.min(max, value))
        
        if clampedValue ~= value then
            data[field] = clampedValue
            table.insert(repairResult.changes, {
                field = field,
                action = "value_clamped",
                oldValue = value,
                newValue = clampedValue,
                range = {min = min, max = max}
            })
        end
    end
    
    return #repairResult.changes > 0
end

function ConsistencyChecker:RepairTimestamps(data, issue, repairResult)
    local currentTime = os.time()
    
    for _, timestampError in ipairs(issue.details.timestampErrors) do
        local field = timestampError.field
        local value = timestampError.value
        
        local newValue = nil
        
        if timestampError.issue == "Future timestamp" then
            newValue = currentTime
        elseif timestampError.issue == "Unreasonably old timestamp" then
            newValue = currentTime
        end
        
        if newValue then
            data[field] = newValue
            table.insert(repairResult.changes, {
                field = field,
                action = "timestamp_corrected",
                oldValue = value,
                newValue = newValue,
                issue = timestampError.issue
            })
        end
    end
    
    return #repairResult.changes > 0
end

function ConsistencyChecker:QuarantineData(playerId, data, issue, repairResult)
    local quarantineId = self:GenerateQuarantineId()
    
    self.quarantinedData[quarantineId] = {
        quarantineId = quarantineId,
        playerId = playerId,
        data = self:DeepCopy(data),
        issue = issue,
        timestamp = os.time(),
        reason = "Data corruption detected"
    }
    
    self.stats.dataQuarantined = self.stats.dataQuarantined + 1
    
    warn("⚠️ Quarantined corrupted data for player " .. playerId .. " (ID: " .. quarantineId .. ")")
    
    return true
end

-- ========================================
-- AUTOMATED CHECKING
-- ========================================

function ConsistencyChecker:StartAutomatedChecks()
    -- Regular consistency checks
    task.spawn(function()
        while true do
            task.wait(CHECK_CONFIG.checkInterval)
            self:RunScheduledChecks()
        end
    end)
    
    -- Deep consistency checks
    task.spawn(function()
        while true do
            task.wait(CHECK_CONFIG.deepCheckInterval)
            self:RunDeepChecks()
        end
    end)
    
    print("⏰ Automated consistency checks started")
end

function ConsistencyChecker:RunScheduledChecks()
    print("🔍 Running scheduled consistency checks...")
    
    -- In a real implementation, this would check active player data
    -- For now, it's a placeholder
    
    local checksRun = 0
    local issuesFound = 0
    
    print("✅ Scheduled checks completed: " .. checksRun .. " checks, " .. issuesFound .. " issues")
end

function ConsistencyChecker:RunDeepChecks()
    print("🔍 Running deep consistency checks...")
    
    self.stats.lastFullCheck = os.time()
    
    -- Deep checks would include statistical analysis, cross-referencing, etc.
    print("✅ Deep checks completed")
end

-- ========================================
-- UTILITY FUNCTIONS
-- ========================================

function ConsistencyChecker:GenerateCheckId(playerId)
    return "check_" .. playerId .. "_" .. os.time() .. "_" .. math.random(1000, 9999)
end

function ConsistencyChecker:GenerateRepairId()
    return "repair_" .. os.time() .. "_" .. math.random(1000, 9999)
end

function ConsistencyChecker:GenerateQuarantineId()
    return "quarantine_" .. os.time() .. "_" .. math.random(1000, 9999)
end

function ConsistencyChecker:GetAllCheckTypes()
    local types = {}
    for checkType, _ in pairs(CHECK_TYPES) do
        table.insert(types, CHECK_TYPES[checkType])
    end
    return types
end

function ConsistencyChecker:CountChecks()
    local count = 0
    for _ in pairs(self.checks) do
        count = count + 1
    end
    return count
end

function ConsistencyChecker:DeepCopy(original)
    if type(original) ~= "table" then
        return original
    end
    
    local copy = {}
    for key, value in pairs(original) do
        copy[key] = self:DeepCopy(value)
    end
    
    return copy
end

function ConsistencyChecker:LogIssueForManualReview(playerId, issue, context)
    -- Log issues that require manual review
    warn("⚠️ Manual review required for player " .. playerId .. ": " .. issue.issue)
end

-- ========================================
-- STATISTICS AND REPORTING
-- ========================================

function ConsistencyChecker:GetStatistics()
    return {
        stats = self.stats,
        config = CHECK_CONFIG,
        activeChecks = self:CountActiveChecks(),
        quarantinedItems = self:CountQuarantinedItems(),
        checkDefinitions = self:CountChecks(),
        
        healthMetrics = {
            corruptionRate = self.stats.checksExecuted > 0 and 
                           (self.stats.dataQuarantined / self.stats.checksExecuted) or 0,
            repairSuccessRate = self.stats.issuesFound > 0 and 
                              (self.stats.issuesRepaired / self.stats.issuesFound) or 0,
            avgIssuesPerCheck = self.stats.checksExecuted > 0 and 
                              (self.stats.issuesFound / self.stats.checksExecuted) or 0
        }
    }
end

function ConsistencyChecker:CountActiveChecks()
    local count = 0
    for _ in pairs(self.activeChecks) do
        count = count + 1
    end
    return count
end

function ConsistencyChecker:CountQuarantinedItems()
    local count = 0
    for _ in pairs(self.quarantinedData) do
        count = count + 1
    end
    return count
end

function ConsistencyChecker:GenerateHealthReport()
    local stats = self:GetStatistics()
    
    local report = {
        reportId = "health_" .. os.time(),
        timestamp = os.time(),
        overallHealth = "good",
        issues = {},
        recommendations = {},
        statistics = stats
    }
    
    -- Analyze health metrics
    if stats.healthMetrics.corruptionRate > CHECK_CONFIG.alertThreshold then
        report.overallHealth = "degraded"
        table.insert(report.issues, "High corruption rate detected")
        table.insert(report.recommendations, "Investigate data sources for corruption")
    end
    
    if stats.healthMetrics.repairSuccessRate < 0.8 then
        table.insert(report.issues, "Low repair success rate")
        table.insert(report.recommendations, "Review repair mechanisms")
    end
    
    if stats.stats.avgCheckTime > 5000 then -- 5 seconds
        table.insert(report.issues, "Slow consistency checks")
        table.insert(report.recommendations, "Optimize check performance")
    end
    
    return report
end

return ConsistencyChecker
