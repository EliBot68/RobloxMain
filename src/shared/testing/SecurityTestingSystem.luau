-- SecurityTestingSystem.luau
-- Automated security testing and vulnerability scanning
-- Provides comprehensive security analysis and vulnerability detection

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local TeleportService = game:GetService("TeleportService")

local SafeRequire = require(ReplicatedStorage.Shared.utils.SafeRequire)

local SecurityTestingSystem = {}

-- ========================================
-- SECURITY TESTING CONFIGURATION
-- ========================================

local SECURITY_CONFIG = {
    -- Scanning settings
    scanning = {
        enableAutomaticScanning = true,
        enableRealTimeMonitoring = true,
        enableVulnerabilityDetection = true,
        enablePenetrationTesting = false, -- Disabled by default for safety
        scanInterval = 300000, -- 5 minutes
        deepScanInterval = 3600000 -- 1 hour
    },
    
    -- Vulnerability detection
    vulnerabilities = {
        checkCodeInjection = true,
        checkDataExposure = true,
        checkAccessControl = true,
        checkInputValidation = true,
        checkCryptography = true,
        checkNetworking = true,
        checkAuthentication = true,
        checkAuthorization = true
    },
    
    -- Code analysis
    codeAnalysis = {
        enableStaticAnalysis = true,
        enableDynamicAnalysis = true,
        enablePatternMatching = true,
        enableDataFlowAnalysis = true,
        checkRemoteEvents = true,
        checkDataStores = true,
        checkHttpRequests = true
    },
    
    -- Security policies
    policies = {
        enforceInputSanitization = true,
        enforceOutputEncoding = true,
        enforceAccessControl = true,
        enforceDataEncryption = true,
        enforceSecureCommunication = true,
        maxDataExposure = "low"
    },
    
    -- Reporting
    reporting = {
        enableDetailedReports = true,
        enableRiskAssessment = true,
        enableComplianceChecking = true,
        generateArtifacts = true,
        alertOnCritical = true
    }
}

-- ========================================
-- SECURITY TESTING STATE
-- ========================================

local SecurityState = {
    -- Vulnerability tracking
    vulnerabilities = {},
    scannedFiles = {},
    securityIssues = {},
    
    -- Security patterns and rules
    securityPatterns = {},
    vulnerabilityRules = {},
    securityPolicies = {},
    
    -- Monitoring and alerts
    monitors = {},
    alerts = {},
    incidents = {},
    
    -- Analysis results
    analysisResults = {},
    riskAssessments = {},
    
    -- Statistics
    stats = {
        filesScanned = 0,
        vulnerabilitiesFound = 0,
        securityIssues = 0,
        policyViolations = 0,
        criticalAlerts = 0
    }
}

function SecurityTestingSystem.initialize()
    print("🔒 Initializing SecurityTestingSystem...")
    
    -- Set up vulnerability detection
    SecurityTestingSystem.setupVulnerabilityDetection()
    
    -- Initialize code analysis
    SecurityTestingSystem.initializeCodeAnalysis()
    
    -- Set up security monitoring
    SecurityTestingSystem.setupSecurityMonitoring()
    
    -- Initialize security policies
    SecurityTestingSystem.initializeSecurityPolicies()
    
    -- Set up automated scanning
    SecurityTestingSystem.setupAutomatedScanning()
    
    print("🔒 SecurityTestingSystem initialized successfully")
end

-- ========================================
-- VULNERABILITY DETECTION
-- ========================================

function SecurityTestingSystem.setupVulnerabilityDetection()
    SecurityState.vulnerabilityDetector = {
        patterns = {},
        rules = {},
        scanners = {},
        checks = {}
    }
    
    -- Initialize vulnerability patterns
    SecurityTestingSystem.initializeVulnerabilityPatterns()
    
    -- Set up security checks
    SecurityTestingSystem.setupSecurityChecks()
    
    print("🔍 Vulnerability detection initialized")
end

function SecurityTestingSystem.initializeVulnerabilityPatterns()
    local patterns = SecurityState.vulnerabilityDetector.patterns
    
    -- Code injection patterns
    patterns.codeInjection = {
        "loadstring%s*%(",
        "require%s*%(%s*[\"'][^\"']*[\"']%s*%)",
        "getfenv%s*%(",
        "setfenv%s*%(",
        "debug%.getregistry%s*%(",
        "rawget%s*%(",
        "rawset%s*%("
    }
    
    -- Data exposure patterns
    patterns.dataExposure = {
        "password%s*=%s*[\"'][^\"']*[\"']",
        "token%s*=%s*[\"'][^\"']*[\"']",
        "secret%s*=%s*[\"'][^\"']*[\"']",
        "api[_-]?key%s*=%s*[\"'][^\"']*[\"']",
        "private[_-]?key%s*=%s*[\"'][^\"']*[\"']"
    }
    
    -- Insecure network patterns
    patterns.insecureNetwork = {
        "http://[^%s]*",
        "HttpService:GetAsync%s*%(%s*[\"']http://",
        "HttpService:PostAsync%s*%(%s*[\"']http://",
        "TeleportService:Teleport%s*%(%s*%d+%s*,%s*game%.Players%.LocalPlayer%s*%)"
    }
    
    -- Access control patterns
    patterns.accessControl = {
        "game%.Players%.LocalPlayer%.Character",
        "workspace%.CurrentCamera",
        "game%.StarterPlayer%.StarterPlayerScripts",
        "game%.ServerStorage",
        "game%.ServerScriptService"
    }
    
    -- Input validation patterns
    patterns.inputValidation = {
        "OnServerEvent:Connect%s*%(%s*function%s*%(%s*[^,)]*%s*%)",
        "OnServerInvoke%s*=%s*function%s*%(%s*[^,)]*%s*%)",
        "RemoteFunction%.OnServerInvoke",
        "RemoteEvent%.OnServerEvent"
    }
end

function SecurityTestingSystem.setupSecurityChecks()
    local checks = SecurityState.vulnerabilityDetector.checks
    
    checks.codeInjection = function(content, filePath)
        local issues = {}
        local patterns = SecurityState.vulnerabilityDetector.patterns.codeInjection
        
        for lineNum, line in ipairs(string.split(content, "\n")) do
            for _, pattern in ipairs(patterns) do
                if string.match(line, pattern) then
                    table.insert(issues, {
                        type = "CODE_INJECTION",
                        severity = "HIGH",
                        line = lineNum,
                        content = line,
                        pattern = pattern,
                        description = "Potential code injection vulnerability detected"
                    })
                end
            end
        end
        
        return issues
    end
    
    checks.dataExposure = function(content, filePath)
        local issues = {}
        local patterns = SecurityState.vulnerabilityDetector.patterns.dataExposure
        
        for lineNum, line in ipairs(string.split(content, "\n")) do
            for _, pattern in ipairs(patterns) do
                if string.match(line, pattern) then
                    table.insert(issues, {
                        type = "DATA_EXPOSURE",
                        severity = "CRITICAL",
                        line = lineNum,
                        content = line,
                        pattern = pattern,
                        description = "Sensitive data exposure detected"
                    })
                end
            end
        end
        
        return issues
    end
    
    checks.insecureNetwork = function(content, filePath)
        local issues = {}
        local patterns = SecurityState.vulnerabilityDetector.patterns.insecureNetwork
        
        for lineNum, line in ipairs(string.split(content, "\n")) do
            for _, pattern in ipairs(patterns) do
                if string.match(line, pattern) then
                    table.insert(issues, {
                        type = "INSECURE_NETWORK",
                        severity = "MEDIUM",
                        line = lineNum,
                        content = line,
                        pattern = pattern,
                        description = "Insecure network communication detected"
                    })
                end
            end
        end
        
        return issues
    end
    
    checks.accessControl = function(content, filePath)
        local issues = {}
        
        -- Check for client-side access to server-only resources
        if string.find(filePath, "client") or string.find(filePath, "local") then
            local patterns = SecurityState.vulnerabilityDetector.patterns.accessControl
            
            for lineNum, line in ipairs(string.split(content, "\n")) do
                for _, pattern in ipairs(patterns) do
                    if string.match(line, pattern) then
                        table.insert(issues, {
                            type = "ACCESS_CONTROL",
                            severity = "HIGH",
                            line = lineNum,
                            content = line,
                            pattern = pattern,
                            description = "Potential access control violation"
                        })
                    end
                end
            end
        end
        
        return issues
    end
    
    checks.inputValidation = function(content, filePath)
        local issues = {}
        
        -- Check for missing input validation in remote event handlers
        if string.find(filePath, "server") then
            local lines = string.split(content, "\n")
            
            for lineNum, line in ipairs(lines) do
                if string.match(line, "OnServerEvent:Connect") or string.match(line, "OnServerInvoke") then
                    -- Check next few lines for validation
                    local hasValidation = false
                    for i = lineNum + 1, math.min(lineNum + 10, #lines) do
                        if string.match(lines[i], "typeof") or 
                           string.match(lines[i], "assert") or 
                           string.match(lines[i], "if.*then") then
                            hasValidation = true
                            break
                        end
                    end
                    
                    if not hasValidation then
                        table.insert(issues, {
                            type = "INPUT_VALIDATION",
                            severity = "MEDIUM",
                            line = lineNum,
                            content = line,
                            description = "Remote event handler missing input validation"
                        })
                    end
                end
            end
        end
        
        return issues
    end
end

function SecurityTestingSystem.scanFile(filePath, content)
    local scanResult = {
        filePath = filePath,
        timestamp = tick(),
        vulnerabilities = {},
        securityIssues = {},
        riskLevel = "LOW",
        passed = true
    }
    
    if not content then
        return scanResult
    end
    
    -- Run all security checks
    local checks = SecurityState.vulnerabilityDetector.checks
    
    for checkName, checkFunction in pairs(checks) do
        if SECURITY_CONFIG.vulnerabilities["check" .. checkName:gsub("^%l", string.upper)] then
            local issues = checkFunction(content, filePath)
            
            for _, issue in ipairs(issues) do
                table.insert(scanResult.vulnerabilities, issue)
                
                if issue.severity == "CRITICAL" then
                    scanResult.riskLevel = "CRITICAL"
                    scanResult.passed = false
                elseif issue.severity == "HIGH" and scanResult.riskLevel ~= "CRITICAL" then
                    scanResult.riskLevel = "HIGH"
                    scanResult.passed = false
                elseif issue.severity == "MEDIUM" and scanResult.riskLevel == "LOW" then
                    scanResult.riskLevel = "MEDIUM"
                end
            end
        end
    end
    
    SecurityState.stats.filesScanned = SecurityState.stats.filesScanned + 1
    SecurityState.stats.vulnerabilitiesFound = SecurityState.stats.vulnerabilitiesFound + #scanResult.vulnerabilities
    
    if not scanResult.passed then
        SecurityState.stats.securityIssues = SecurityState.stats.securityIssues + 1
    end
    
    return scanResult
end

function SecurityTestingSystem.scanDirectory(directoryPath)
    local scanResults = {
        directoryPath = directoryPath,
        timestamp = tick(),
        files = {},
        summary = {
            totalFiles = 0,
            vulnerableFiles = 0,
            totalVulnerabilities = 0,
            criticalIssues = 0,
            highIssues = 0,
            mediumIssues = 0,
            lowIssues = 0
        }
    }
    
    -- This would be implemented with actual file system access in a real environment
    print(string.format("🔍 Scanning directory: %s", directoryPath))
    
    return scanResults
end

-- ========================================
-- CODE ANALYSIS
-- ========================================

function SecurityTestingSystem.initializeCodeAnalysis()
    SecurityState.codeAnalyzer = {
        staticAnalysis = {},
        dynamicAnalysis = {},
        patterns = {},
        rules = {}
    }
    
    -- Set up static analysis rules
    SecurityTestingSystem.setupStaticAnalysisRules()
    
    -- Initialize dynamic analysis
    SecurityTestingSystem.setupDynamicAnalysis()
    
    print("🔬 Code analysis initialized")
end

function SecurityTestingSystem.setupStaticAnalysisRules()
    local rules = SecurityState.codeAnalyzer.rules
    
    rules.remoteEventSecurity = {
        pattern = "RemoteEvent",
        check = function(content, context)
            local issues = {}
            
            -- Check for remote events without proper validation
            if string.find(content, "OnServerEvent") then
                if not string.find(content, "player") or not string.find(content, "assert") then
                    table.insert(issues, {
                        type = "REMOTE_EVENT_SECURITY",
                        severity = "MEDIUM",
                        description = "Remote event may lack proper player validation"
                    })
                end
            end
            
            return issues
        end
    }
    
    rules.dataStoreSecurity = {
        pattern = "DataStore",
        check = function(content, context)
            local issues = {}
            
            -- Check for data store operations without error handling
            if string.find(content, "GetAsync") or string.find(content, "SetAsync") then
                if not string.find(content, "pcall") and not string.find(content, "try") then
                    table.insert(issues, {
                        type = "DATASTORE_SECURITY",
                        severity = "LOW",
                        description = "DataStore operation without error handling"
                    })
                end
            end
            
            return issues
        end
    }
    
    rules.httpSecurity = {
        pattern = "HttpService",
        check = function(content, context)
            local issues = {}
            
            -- Check for HTTP requests to insecure endpoints
            if string.find(content, "http://") then
                table.insert(issues, {
                    type = "HTTP_SECURITY",
                    severity = "HIGH",
                    description = "HTTP request to insecure endpoint (use HTTPS)"
                })
            end
            
            -- Check for HTTP requests without validation
            if string.find(content, "GetAsync") or string.find(content, "PostAsync") then
                if not string.find(content, "assert") and not string.find(content, "typeof") then
                    table.insert(issues, {
                        type = "HTTP_VALIDATION",
                        severity = "MEDIUM",
                        description = "HTTP response not validated"
                    })
                end
            end
            
            return issues
        end
    }
end

function SecurityTestingSystem.setupDynamicAnalysis()
    SecurityState.codeAnalyzer.dynamicAnalysis = {
        monitors = {},
        trackers = {},
        interceptors = {}
    }
    
    -- Set up runtime monitoring
    SecurityTestingSystem.setupRuntimeMonitoring()
end

function SecurityTestingSystem.setupRuntimeMonitoring()
    -- Monitor remote event calls
    local originalConnect = Instance.new("RemoteEvent").OnServerEvent.Connect
    
    local function monitorRemoteEvent(self, callback)
        local monitoredCallback = function(player, ...)
            -- Log the call for security analysis
            SecurityTestingSystem.logRemoteEventCall(self.Name, player, {...})
            
            -- Call original callback
            return callback(player, ...)
        end
        
        return originalConnect(self, monitoredCallback)
    end
    
    -- This would require more sophisticated runtime interception in a real implementation
end

function SecurityTestingSystem.logRemoteEventCall(eventName, player, args)
    local logEntry = {
        timestamp = tick(),
        eventName = eventName,
        playerId = player.UserId,
        playerName = player.Name,
        args = args,
        validated = false
    }
    
    -- Analyze the call for suspicious patterns
    SecurityTestingSystem.analyzeRemoteEventCall(logEntry)
end

function SecurityTestingSystem.analyzeRemoteEventCall(logEntry)
    local suspiciousPatterns = {
        -- Rapid successive calls
        function(entry)
            local recentCalls = 0
            local timeWindow = 5 -- seconds
            
            -- This would check recent call history in a real implementation
            return recentCalls > 10 and {
                type = "RATE_LIMITING",
                severity = "MEDIUM",
                description = "Suspicious rate of remote event calls"
            }
        end,
        
        -- Unusual argument patterns
        function(entry)
            for _, arg in ipairs(entry.args) do
                if type(arg) == "string" and #arg > 1000 then
                    return {
                        type = "LARGE_PAYLOAD",
                        severity = "LOW",
                        description = "Unusually large string argument"
                    }
                end
            end
            return nil
        end
    }
    
    for _, pattern in ipairs(suspiciousPatterns) do
        local issue = pattern(logEntry)
        if issue then
            SecurityTestingSystem.reportSecurityIssue(issue, logEntry)
        end
    end
end

-- ========================================
-- SECURITY MONITORING
-- ========================================

function SecurityTestingSystem.setupSecurityMonitoring()
    SecurityState.securityMonitor = {
        realTimeMonitoring = SECURITY_CONFIG.scanning.enableRealTimeMonitoring,
        alerts = {},
        incidents = {},
        patterns = {}
    }
    
    if SecurityState.securityMonitor.realTimeMonitoring then
        SecurityTestingSystem.startRealTimeMonitoring()
    end
    
    print("📡 Security monitoring initialized")
end

function SecurityTestingSystem.startRealTimeMonitoring()
    spawn(function()
        while SecurityState.securityMonitor.realTimeMonitoring do
            -- Monitor for security events
            SecurityTestingSystem.checkSecurityEvents()
            
            -- Monitor system resources
            SecurityTestingSystem.monitorSystemResources()
            
            -- Check for anomalous behavior
            SecurityTestingSystem.detectAnomalies()
            
            task.wait(10) -- Check every 10 seconds
        end
    end)
end

function SecurityTestingSystem.checkSecurityEvents()
    -- Monitor for various security events
    local events = {
        suspiciousPlayerBehavior = SecurityTestingSystem.detectSuspiciousPlayerBehavior(),
        unusualNetworkActivity = SecurityTestingSystem.detectUnusualNetworkActivity(),
        resourceAbuseAttempts = SecurityTestingSystem.detectResourceAbuse()
    }
    
    for eventType, eventData in pairs(events) do
        if eventData then
            SecurityTestingSystem.handleSecurityEvent(eventType, eventData)
        end
    end
end

function SecurityTestingSystem.detectSuspiciousPlayerBehavior()
    -- This would analyze player behavior patterns
    -- Placeholder implementation
    return nil
end

function SecurityTestingSystem.detectUnusualNetworkActivity()
    -- This would monitor network traffic patterns
    -- Placeholder implementation
    return nil
end

function SecurityTestingSystem.detectResourceAbuse()
    -- Monitor for excessive resource usage
    local memoryUsage = collectgarbage("count")
    local threshold = 100000 -- 100MB
    
    if memoryUsage > threshold then
        return {
            type = "MEMORY_ABUSE",
            severity = "MEDIUM",
            memoryUsage = memoryUsage,
            threshold = threshold
        }
    end
    
    return nil
end

function SecurityTestingSystem.monitorSystemResources()
    local resources = {
        memory = collectgarbage("count"),
        timestamp = tick()
    }
    
    -- Store resource usage history for trend analysis
    if not SecurityState.resourceHistory then
        SecurityState.resourceHistory = {}
    end
    
    table.insert(SecurityState.resourceHistory, resources)
    
    -- Keep only recent history
    if #SecurityState.resourceHistory > 100 then
        table.remove(SecurityState.resourceHistory, 1)
    end
end

function SecurityTestingSystem.detectAnomalies()
    -- Detect anomalous patterns in system behavior
    if SecurityState.resourceHistory and #SecurityState.resourceHistory > 10 then
        local recent = SecurityState.resourceHistory[#SecurityState.resourceHistory]
        local baseline = 0
        
        -- Calculate baseline from recent history
        for i = math.max(1, #SecurityState.resourceHistory - 9), #SecurityState.resourceHistory - 1 do
            baseline = baseline + SecurityState.resourceHistory[i].memory
        end
        baseline = baseline / 9
        
        -- Check for memory spike
        if recent.memory > baseline * 2 then
            SecurityTestingSystem.reportSecurityIssue({
                type = "MEMORY_ANOMALY",
                severity = "LOW",
                description = "Unusual memory usage spike detected"
            }, {
                current = recent.memory,
                baseline = baseline
            })
        end
    end
end

-- ========================================
-- SECURITY POLICIES
-- ========================================

function SecurityTestingSystem.initializeSecurityPolicies()
    SecurityState.securityPolicies = {
        inputSanitization = SECURITY_CONFIG.policies.enforceInputSanitization,
        outputEncoding = SECURITY_CONFIG.policies.enforceOutputEncoding,
        accessControl = SECURITY_CONFIG.policies.enforceAccessControl,
        dataEncryption = SECURITY_CONFIG.policies.enforceDataEncryption,
        secureCommunication = SECURITY_CONFIG.policies.enforceSecureCommunication
    }
    
    -- Set up policy enforcement
    SecurityTestingSystem.setupPolicyEnforcement()
    
    print("📋 Security policies initialized")
end

function SecurityTestingSystem.setupPolicyEnforcement()
    local enforcement = {
        violations = {},
        warnings = {},
        enforced = {}
    }
    
    SecurityState.policyEnforcement = enforcement
end

function SecurityTestingSystem.checkPolicyCompliance(scanResult)
    local compliance = {
        passed = true,
        violations = {},
        warnings = {}
    }
    
    -- Check input sanitization policy
    if SecurityState.securityPolicies.inputSanitization then
        for _, vulnerability in ipairs(scanResult.vulnerabilities) do
            if vulnerability.type == "INPUT_VALIDATION" then
                table.insert(compliance.violations, {
                    policy = "INPUT_SANITIZATION",
                    severity = "MEDIUM",
                    description = "Input sanitization policy violation"
                })
                compliance.passed = false
            end
        end
    end
    
    -- Check secure communication policy
    if SecurityState.securityPolicies.secureCommunication then
        for _, vulnerability in ipairs(scanResult.vulnerabilities) do
            if vulnerability.type == "INSECURE_NETWORK" then
                table.insert(compliance.violations, {
                    policy = "SECURE_COMMUNICATION",
                    severity = "HIGH",
                    description = "Secure communication policy violation"
                })
                compliance.passed = false
            end
        end
    end
    
    -- Check data encryption policy
    if SecurityState.securityPolicies.dataEncryption then
        for _, vulnerability in ipairs(scanResult.vulnerabilities) do
            if vulnerability.type == "DATA_EXPOSURE" then
                table.insert(compliance.violations, {
                    policy = "DATA_ENCRYPTION",
                    severity = "CRITICAL",
                    description = "Data encryption policy violation"
                })
                compliance.passed = false
            end
        end
    end
    
    if not compliance.passed then
        SecurityState.stats.policyViolations = SecurityState.stats.policyViolations + 1
    end
    
    return compliance
end

-- ========================================
-- AUTOMATED SCANNING
-- ========================================

function SecurityTestingSystem.setupAutomatedScanning()
    if SECURITY_CONFIG.scanning.enableAutomaticScanning then
        SecurityTestingSystem.startAutomatedScanning()
    end
    
    print("🤖 Automated scanning initialized")
end

function SecurityTestingSystem.startAutomatedScanning()
    spawn(function()
        while SECURITY_CONFIG.scanning.enableAutomaticScanning do
            -- Perform regular security scans
            SecurityTestingSystem.performAutomatedScan()
            
            task.wait(SECURITY_CONFIG.scanning.scanInterval / 1000)
        end
    end)
    
    spawn(function()
        while SECURITY_CONFIG.scanning.enableAutomaticScanning do
            -- Perform deep security scans
            SecurityTestingSystem.performDeepScan()
            
            task.wait(SECURITY_CONFIG.scanning.deepScanInterval / 1000)
        end
    end)
end

function SecurityTestingSystem.performAutomatedScan()
    print("🔍 Performing automated security scan...")
    
    -- This would scan actual project files in a real implementation
    local mockFiles = {
        "src/server/GameService.luau",
        "src/client/PlayerController.luau",
        "src/shared/DataManager.luau"
    }
    
    local scanResults = {}
    
    for _, filePath in ipairs(mockFiles) do
        -- Mock file content for demonstration
        local mockContent = string.format([[
        -- %s
        local RemoteEvent = ReplicatedStorage:WaitForChild("TestEvent")
        
        RemoteEvent.OnServerEvent:Connect(function(player, data)
            -- Process data without validation
            print("Received:", data)
        end)
        
        local HttpService = game:GetService("HttpService")
        local response = HttpService:GetAsync("http://example.com/api")
        ]], filePath)
        
        local result = SecurityTestingSystem.scanFile(filePath, mockContent)
        scanResults[filePath] = result
        
        if not result.passed then
            print(string.format("  ⚠️ Security issues found in %s (%d vulnerabilities)", 
                filePath, #result.vulnerabilities))
        end
    end
    
    return scanResults
end

function SecurityTestingSystem.performDeepScan()
    print("🔬 Performing deep security scan...")
    
    -- Deep scan would include more comprehensive analysis
    local deepScanResult = {
        timestamp = tick(),
        scanType = "deep",
        results = {},
        summary = {
            totalVulnerabilities = 0,
            criticalIssues = 0,
            complianceScore = 0
        }
    }
    
    return deepScanResult
end

-- ========================================
-- INCIDENT HANDLING
-- ========================================

function SecurityTestingSystem.reportSecurityIssue(issue, context)
    local incident = {
        id = HttpService:GenerateGUID(false),
        timestamp = tick(),
        issue = issue,
        context = context,
        status = "open",
        severity = issue.severity
    }
    
    table.insert(SecurityState.incidents, incident)
    
    if issue.severity == "CRITICAL" then
        SecurityState.stats.criticalAlerts = SecurityState.stats.criticalAlerts + 1
        SecurityTestingSystem.handleCriticalAlert(incident)
    end
    
    print(string.format("🚨 Security issue reported: %s (%s)", issue.type, issue.severity))
end

function SecurityTestingSystem.handleCriticalAlert(incident)
    if SECURITY_CONFIG.reporting.alertOnCritical then
        print(string.format("🔴 CRITICAL SECURITY ALERT: %s", incident.issue.description))
        
        -- In a real implementation, this would send notifications
        -- to security teams, log to external systems, etc.
    end
end

function SecurityTestingSystem.handleSecurityEvent(eventType, eventData)
    local event = {
        type = eventType,
        data = eventData,
        timestamp = tick(),
        handled = false
    }
    
    table.insert(SecurityState.securityMonitor.alerts, event)
    
    print(string.format("🔔 Security event detected: %s", eventType))
end

-- ========================================
-- REPORTING AND ANALYSIS
-- ========================================

function SecurityTestingSystem.generateSecurityReport()
    local report = {
        timestamp = tick(),
        summary = {
            filesScanned = SecurityState.stats.filesScanned,
            vulnerabilitiesFound = SecurityState.stats.vulnerabilitiesFound,
            securityIssues = SecurityState.stats.securityIssues,
            policyViolations = SecurityState.stats.policyViolations,
            criticalAlerts = SecurityState.stats.criticalAlerts
        },
        vulnerabilities = {},
        incidents = SecurityState.incidents,
        compliance = {},
        recommendations = {}
    }
    
    -- Analyze vulnerability trends
    report.vulnerabilities = SecurityTestingSystem.analyzeVulnerabilityTrends()
    
    -- Generate compliance assessment
    report.compliance = SecurityTestingSystem.assessCompliance()
    
    -- Provide security recommendations
    report.recommendations = SecurityTestingSystem.generateSecurityRecommendations()
    
    return report
end

function SecurityTestingSystem.analyzeVulnerabilityTrends()
    local analysis = {
        byType = {},
        bySeverity = {},
        trends = {}
    }
    
    -- Analyze vulnerabilities by type and severity
    for _, incident in ipairs(SecurityState.incidents) do
        local issueType = incident.issue.type
        local severity = incident.issue.severity
        
        analysis.byType[issueType] = (analysis.byType[issueType] or 0) + 1
        analysis.bySeverity[severity] = (analysis.bySeverity[severity] or 0) + 1
    end
    
    return analysis
end

function SecurityTestingSystem.assessCompliance()
    local compliance = {
        overallScore = 0,
        policies = {},
        violations = SecurityState.stats.policyViolations,
        recommendations = {}
    }
    
    -- Calculate compliance score based on violations and policies
    local totalPolicies = 0
    local violatedPolicies = 0
    
    for policyName, enabled in pairs(SecurityState.securityPolicies) do
        if enabled then
            totalPolicies = totalPolicies + 1
            
            -- Check if this policy has violations
            local hasViolations = false
            for _, incident in ipairs(SecurityState.incidents) do
                if incident.issue.policy == policyName:upper() then
                    hasViolations = true
                    break
                end
            end
            
            if hasViolations then
                violatedPolicies = violatedPolicies + 1
            end
            
            compliance.policies[policyName] = not hasViolations
        end
    end
    
    compliance.overallScore = totalPolicies > 0 and 
        ((totalPolicies - violatedPolicies) / totalPolicies * 100) or 100
    
    return compliance
end

function SecurityTestingSystem.generateSecurityRecommendations()
    local recommendations = {}
    
    -- Analyze common issues and provide recommendations
    local issueTypes = {}
    for _, incident in ipairs(SecurityState.incidents) do
        local issueType = incident.issue.type
        issueTypes[issueType] = (issueTypes[issueType] or 0) + 1
    end
    
    for issueType, count in pairs(issueTypes) do
        if issueType == "INPUT_VALIDATION" and count > 3 then
            table.insert(recommendations, {
                priority = "HIGH",
                category = "Input Validation",
                description = "Implement comprehensive input validation for all remote events",
                impact = "Prevents injection attacks and improves system reliability"
            })
        elseif issueType == "DATA_EXPOSURE" and count > 0 then
            table.insert(recommendations, {
                priority = "CRITICAL",
                category = "Data Protection",
                description = "Remove or encrypt all exposed sensitive data",
                impact = "Prevents data breaches and protects user privacy"
            })
        elseif issueType == "INSECURE_NETWORK" and count > 1 then
            table.insert(recommendations, {
                priority = "MEDIUM",
                category = "Network Security",
                description = "Use HTTPS for all external communications",
                impact = "Protects data in transit from interception"
            })
        end
    end
    
    return recommendations
end

-- ========================================
-- PUBLIC API
-- ========================================

function SecurityTestingSystem.runSecurityTestingDemo()
    print("🔒 Running security testing demonstration...")
    
    -- Perform automated scan
    print("  🔍 Running automated security scan...")
    local scanResults = SecurityTestingSystem.performAutomatedScan()
    
    local totalIssues = 0
    for filePath, result in pairs(scanResults) do
        totalIssues = totalIssues + #result.vulnerabilities
    end
    print(string.format("    Found %d security issues across %d files", totalIssues, #scanResults))
    
    -- Generate security report
    print("  📊 Generating security report...")
    local report = SecurityTestingSystem.generateSecurityReport()
    print(string.format("    Overall compliance score: %.1f%%", report.compliance.overallScore))
    print(string.format("    Security recommendations: %d", #report.recommendations))
    
    -- Demonstrate vulnerability detection
    print("  🔍 Testing vulnerability detection...")
    local testCode = [[
        local password = "secret123"
        local httpResponse = HttpService:GetAsync("http://insecure-api.com")
        RemoteEvent.OnServerEvent:Connect(function(player, data)
            workspace.Part.Size = data
        end)
    ]]
    
    local testResult = SecurityTestingSystem.scanFile("test.luau", testCode)
    print(string.format("    Test scan found %d vulnerabilities", #testResult.vulnerabilities))
    
    for _, vulnerability in ipairs(testResult.vulnerabilities) do
        print(string.format("      - %s (%s): %s", 
            vulnerability.type, vulnerability.severity, vulnerability.description))
    end
    
    print("🔒 Security testing demonstration completed")
end

function SecurityTestingSystem.getSecurityStats()
    return SecurityState.stats
end

function SecurityTestingSystem.getSecurityIncidents()
    return SecurityState.incidents
end

function SecurityTestingSystem.getComplianceStatus()
    return SecurityTestingSystem.assessCompliance()
end

-- Export API
SecurityTestingSystem.scanFile = SecurityTestingSystem.scanFile
SecurityTestingSystem.scanDirectory = SecurityTestingSystem.scanDirectory
SecurityTestingSystem.generateSecurityReport = SecurityTestingSystem.generateSecurityReport
SecurityTestingSystem.reportSecurityIssue = SecurityTestingSystem.reportSecurityIssue
SecurityTestingSystem.checkPolicyCompliance = SecurityTestingSystem.checkPolicyCompliance

-- Initialize the security testing system
SecurityTestingSystem.initialize()

print("🔒 SecurityTestingSystem loaded with comprehensive security testing capabilities")

return SecurityTestingSystem
