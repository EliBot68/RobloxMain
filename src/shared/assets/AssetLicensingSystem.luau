-- AssetLicensingSystem.luau
-- Asset licensing and attribution management with comprehensive compliance tracking
-- Provides license management, attribution tracking, and legal compliance for asset usage

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local MarketplaceService = game:GetService("MarketplaceService")

local SafeRequire = require(ReplicatedStorage.Shared.utils.SafeRequire)

local AssetLicensingSystem = {}

-- ========================================
-- LICENSING CONFIGURATION
-- ========================================

local LICENSING_CONFIG = {
    -- License types and permissions
    licenseTypes = {
        publicDomain = {
            name = "Public Domain",
            commercial = true,
            modification = true,
            distribution = true,
            attribution = false,
            shareAlike = false,
            copyleft = false
        },
        
        mit = {
            name = "MIT License",
            commercial = true,
            modification = true,
            distribution = true,
            attribution = true,
            shareAlike = false,
            copyleft = false
        },
        
        apache2 = {
            name = "Apache License 2.0",
            commercial = true,
            modification = true,
            distribution = true,
            attribution = true,
            shareAlike = false,
            copyleft = false
        },
        
        gpl3 = {
            name = "GNU General Public License v3.0",
            commercial = true,
            modification = true,
            distribution = true,
            attribution = true,
            shareAlike = true,
            copyleft = true
        },
        
        ccBy = {
            name = "Creative Commons Attribution",
            commercial = true,
            modification = true,
            distribution = true,
            attribution = true,
            shareAlike = false,
            copyleft = false
        },
        
        ccBySa = {
            name = "Creative Commons Attribution-ShareAlike",
            commercial = true,
            modification = true,
            distribution = true,
            attribution = true,
            shareAlike = true,
            copyleft = false
        },
        
        ccByNc = {
            name = "Creative Commons Attribution-NonCommercial",
            commercial = false,
            modification = true,
            distribution = true,
            attribution = true,
            shareAlike = false,
            copyleft = false
        },
        
        proprietary = {
            name = "Proprietary License",
            commercial = false,
            modification = false,
            distribution = false,
            attribution = true,
            shareAlike = false,
            copyleft = false
        },
        
        royaltyFree = {
            name = "Royalty-Free License",
            commercial = true,
            modification = true,
            distribution = false,
            attribution = true,
            shareAlike = false,
            copyleft = false
        },
        
        custom = {
            name = "Custom License",
            commercial = nil, -- Determined by custom terms
            modification = nil,
            distribution = nil,
            attribution = true,
            shareAlike = nil,
            copyleft = nil
        }
    },
    
    -- Attribution requirements
    attribution = {
        enableAutoAttribution = true,
        enableCreditGeneration = true,
        enableLicenseValidation = true,
        enableComplianceTracking = true,
        defaultAttributionFormat = "{creator} - {title} ({license})",
        requireSourceUrl = true,
        requireLicenseUrl = true
    },
    
    -- Compliance settings
    compliance = {
        enableAutomaticChecks = true,
        enableLicenseConflictDetection = true,
        enableUsageValidation = true,
        enableExpirationTracking = true,
        strictMode = false,
        warningThreshold = 30, -- Days before expiration
        auditInterval = 86400   -- 24 hours
    },
    
    -- Legal and business
    legal = {
        enableRiskAssessment = true,
        enableCopyrightProtection = true,
        enableTrademarkProtection = true,
        enablePatentChecking = false,
        riskCategories = {"low", "medium", "high", "critical"}
    }
}

-- ========================================
-- LICENSING STATE
-- ========================================

local LicensingState = {
    -- Asset licensing
    assetLicenses = {},
    licenseDatabase = {},
    attributionRecords = {},
    
    -- Compliance tracking
    complianceResults = {},
    violations = {},
    auditResults = {},
    
    -- Legal management
    copyrightDatabase = {},
    trademarkDatabase = {},
    riskAssessments = {},
    
    -- Attribution system
    attributionTemplates = {},
    creditGenerators = {},
    licenseValidators = {},
    
    -- Statistics
    stats = {
        totalAssets = 0,
        licensedAssets = 0,
        compliantAssets = 0,
        violations = 0,
        riskLevel = "low",
        attributionCoverage = 0
    }
}

function AssetLicensingSystem.initialize()
    print("⚖️ Initializing AssetLicensingSystem...")
    
    -- Set up license management
    AssetLicensingSystem.setupLicenseManagement()
    
    -- Initialize attribution system
    AssetLicensingSystem.initializeAttributionSystem()
    
    -- Set up compliance tracking
    AssetLicensingSystem.setupComplianceTracking()
    
    -- Initialize legal management
    AssetLicensingSystem.initializeLegalManagement()
    
    -- Start compliance monitoring
    AssetLicensingSystem.startComplianceMonitoring()
    
    print("⚖️ AssetLicensingSystem initialized successfully")
end

-- ========================================
-- LICENSE MANAGEMENT
-- ========================================

function AssetLicensingSystem.setupLicenseManagement()
    LicensingState.licenseManager = {
        database = {},
        validators = {},
        parsers = {},
        generators = {}
    }
    
    -- Initialize license database
    AssetLicensingSystem.initializeLicenseDatabase()
    
    -- Set up license validators
    AssetLicensingSystem.setupLicenseValidators()
    
    print("📜 License management initialized")
end

function AssetLicensingSystem.initializeLicenseDatabase()
    LicensingState.licenseDatabase = LICENSING_CONFIG.licenseTypes
    
    -- Add license metadata
    for licenseId, license in pairs(LicensingState.licenseDatabase) do
        license.id = licenseId
        license.version = "1.0"
        license.url = string.format("https://licenses.example.com/%s", licenseId)
        license.isValidated = true
        license.lastUpdated = tick()
    end
end

function AssetLicensingSystem.setupLicenseValidators()
    LicensingState.licenseManager.validators = {
        format = AssetLicensingSystem.createFormatValidator(),
        permissions = AssetLicensingSystem.createPermissionsValidator(),
        compatibility = AssetLicensingSystem.createCompatibilityValidator(),
        expiration = AssetLicensingSystem.createExpirationValidator()
    }
end

function AssetLicensingSystem.createFormatValidator()
    return {
        name = "format",
        validate = function(license)
            return AssetLicensingSystem.validateLicenseFormat(license)
        end
    }
end

function AssetLicensingSystem.createPermissionsValidator()
    return {
        name = "permissions",
        validate = function(license, usage)
            return AssetLicensingSystem.validatePermissions(license, usage)
        end
    }
end

function AssetLicensingSystem.createCompatibilityValidator()
    return {
        name = "compatibility",
        validate = function(licenses)
            return AssetLicensingSystem.validateLicenseCompatibility(licenses)
        end
    }
end

function AssetLicensingSystem.createExpirationValidator()
    return {
        name = "expiration",
        validate = function(license)
            return AssetLicensingSystem.validateLicenseExpiration(license)
        end
    }
end

function AssetLicensingSystem.registerAssetLicense(assetId, licenseInfo)
    local license = {
        assetId = assetId,
        licenseType = licenseInfo.type,
        licenseText = licenseInfo.text,
        attribution = licenseInfo.attribution or {},
        permissions = LicensingState.licenseDatabase[licenseInfo.type],
        customTerms = licenseInfo.customTerms or {},
        expiration = licenseInfo.expiration,
        source = licenseInfo.source,
        registrationDate = tick(),
        isValidated = false
    }
    
    -- Validate license
    local validation = AssetLicensingSystem.validateLicense(license)
    license.isValidated = validation.valid
    license.validationResults = validation
    
    -- Store license
    LicensingState.assetLicenses[assetId] = license
    
    -- Update statistics
    LicensingState.stats.totalAssets = LicensingState.stats.totalAssets + 1
    if license.isValidated then
        LicensingState.stats.licensedAssets = LicensingState.stats.licensedAssets + 1
    end
    
    print(string.format("📜 Registered license for asset %s: %s (%s)", 
        assetId, license.licenseType, license.isValidated and "valid" or "invalid"))
    
    return license
end

function AssetLicensingSystem.validateLicense(license)
    local validation = {
        valid = true,
        issues = {},
        warnings = {},
        recommendations = {}
    }
    
    -- Format validation
    local formatResult = LicensingState.licenseManager.validators.format.validate(license)
    if not formatResult.valid then
        validation.valid = false
        table.insert(validation.issues, formatResult.issue)
    end
    
    -- Permissions validation
    local permissionsResult = LicensingState.licenseManager.validators.permissions.validate(
        license, {commercial = true, modification = true, distribution = true})
    if not permissionsResult.valid then
        table.insert(validation.warnings, permissionsResult.warning)
    end
    
    -- Expiration validation
    local expirationResult = LicensingState.licenseManager.validators.expiration.validate(license)
    if not expirationResult.valid then
        table.insert(validation.warnings, expirationResult.warning)
    end
    
    return validation
end

function AssetLicensingSystem.validateLicenseFormat(license)
    local result = {valid = true, issue = nil}
    
    -- Check required fields
    if not license.licenseType then
        result.valid = false
        result.issue = "License type is required"
        return result
    end
    
    if not LicensingState.licenseDatabase[license.licenseType] then
        result.valid = false
        result.issue = "Unknown license type: " .. license.licenseType
        return result
    end
    
    -- Check attribution requirements
    local licenseInfo = LicensingState.licenseDatabase[license.licenseType]
    if licenseInfo.attribution and not license.attribution then
        result.valid = false
        result.issue = "Attribution is required for this license type"
        return result
    end
    
    return result
end

function AssetLicensingSystem.validatePermissions(license, usage)
    local result = {valid = true, warning = nil}
    local licenseInfo = LicensingState.licenseDatabase[license.licenseType]
    
    -- Check commercial use
    if usage.commercial and not licenseInfo.commercial then
        result.valid = false
        result.warning = "Commercial use not permitted under this license"
        return result
    end
    
    -- Check modification
    if usage.modification and not licenseInfo.modification then
        result.valid = false
        result.warning = "Modification not permitted under this license"
        return result
    end
    
    -- Check distribution
    if usage.distribution and not licenseInfo.distribution then
        result.valid = false
        result.warning = "Distribution not permitted under this license"
        return result
    end
    
    return result
end

function AssetLicensingSystem.validateLicenseCompatibility(licenses)
    local result = {valid = true, conflicts = {}}
    
    -- Check for copyleft conflicts
    local copyleftLicenses = {}
    local nonCopyleftLicenses = {}
    
    for _, license in ipairs(licenses) do
        local licenseInfo = LicensingState.licenseDatabase[license.licenseType]
        if licenseInfo.copyleft then
            table.insert(copyleftLicenses, license)
        else
            table.insert(nonCopyleftLicenses, license)
        end
    end
    
    -- Check for conflicts
    if #copyleftLicenses > 0 and #nonCopyleftLicenses > 0 then
        result.valid = false
        table.insert(result.conflicts, {
            type = "copyleft_conflict",
            description = "Copyleft and non-copyleft licenses cannot be mixed"
        })
    end
    
    return result
end

function AssetLicensingSystem.validateLicenseExpiration(license)
    local result = {valid = true, warning = nil}
    
    if license.expiration then
        local currentTime = tick()
        local timeToExpiration = license.expiration - currentTime
        
        if timeToExpiration <= 0 then
            result.valid = false
            result.warning = "License has expired"
        elseif timeToExpiration <= LICENSING_CONFIG.compliance.warningThreshold * 86400 then
            result.warning = string.format("License expires in %d days", 
                math.ceil(timeToExpiration / 86400))
        end
    end
    
    return result
end

-- ========================================
-- ATTRIBUTION SYSTEM
-- ========================================

function AssetLicensingSystem.initializeAttributionSystem()
    LicensingState.attributionSystem = {
        templates = {},
        generators = {},
        validators = {},
        records = {}
    }
    
    -- Set up attribution templates
    AssetLicensingSystem.setupAttributionTemplates()
    
    -- Initialize credit generators
    AssetLicensingSystem.initializeCreditGenerators()
    
    print("🏷️ Attribution system initialized")
end

function AssetLicensingSystem.setupAttributionTemplates()
    LicensingState.attributionSystem.templates = {
        basic = "{creator} - {title}",
        detailed = "{creator} - {title} ({license})",
        full = "{creator} - {title} ({license}) - {sourceUrl}",
        creative_commons = "'{title}' by {creator} is licensed under {license}. {licenseUrl}",
        academic = "{creator}. {title}. {year}. {license}. {sourceUrl}"
    }
end

function AssetLicensingSystem.initializeCreditGenerators()
    LicensingState.attributionSystem.generators = {
        text = AssetLicensingSystem.createTextCreditGenerator(),
        html = AssetLicensingSystem.createHtmlCreditGenerator(),
        json = AssetLicensingSystem.createJsonCreditGenerator(),
        markdown = AssetLicensingSystem.createMarkdownCreditGenerator()
    }
end

function AssetLicensingSystem.createTextCreditGenerator()
    return {
        format = "text",
        generate = function(assets)
            return AssetLicensingSystem.generateTextCredits(assets)
        end
    }
end

function AssetLicensingSystem.createHtmlCreditGenerator()
    return {
        format = "html",
        generate = function(assets)
            return AssetLicensingSystem.generateHtmlCredits(assets)
        end
    }
end

function AssetLicensingSystem.createJsonCreditGenerator()
    return {
        format = "json",
        generate = function(assets)
            return AssetLicensingSystem.generateJsonCredits(assets)
        end
    }
end

function AssetLicensingSystem.createMarkdownCreditGenerator()
    return {
        format = "markdown",
        generate = function(assets)
            return AssetLicensingSystem.generateMarkdownCredits(assets)
        end
    }
end

function AssetLicensingSystem.generateAttribution(assetId, format)
    format = format or "basic"
    
    local license = LicensingState.assetLicenses[assetId]
    if not license then
        return nil
    end
    
    local template = LicensingState.attributionSystem.templates[format]
    if not template then
        template = LicensingState.attributionSystem.templates.basic
    end
    
    local attribution = AssetLicensingSystem.applyAttributionTemplate(template, license)
    
    -- Record attribution generation
    AssetLicensingSystem.recordAttribution(assetId, attribution, format)
    
    return attribution
end

function AssetLicensingSystem.applyAttributionTemplate(template, license)
    local attribution = template
    local replacements = {
        ["{creator}"] = license.attribution.creator or "Unknown Creator",
        ["{title}"] = license.attribution.title or "Untitled Asset",
        ["{license}"] = LicensingState.licenseDatabase[license.licenseType].name,
        ["{licenseUrl}"] = LicensingState.licenseDatabase[license.licenseType].url,
        ["{sourceUrl}"] = license.source or "",
        ["{year}"] = license.attribution.year or os.date("%Y"),
        ["{description}"] = license.attribution.description or ""
    }
    
    for placeholder, value in pairs(replacements) do
        attribution = string.gsub(attribution, placeholder, value)
    end
    
    return attribution
end

function AssetLicensingSystem.recordAttribution(assetId, attribution, format)
    local record = {
        assetId = assetId,
        attribution = attribution,
        format = format,
        timestamp = tick(),
        generated = true
    }
    
    if not LicensingState.attributionRecords[assetId] then
        LicensingState.attributionRecords[assetId] = {}
    end
    
    table.insert(LicensingState.attributionRecords[assetId], record)
end

function AssetLicensingSystem.generateCreditsFile(assetIds, format)
    format = format or "text"
    
    local assets = {}
    for _, assetId in ipairs(assetIds) do
        local license = LicensingState.assetLicenses[assetId]
        if license then
            table.insert(assets, {
                id = assetId,
                license = license
            })
        end
    end
    
    local generator = LicensingState.attributionSystem.generators[format]
    if not generator then
        return nil
    end
    
    return generator.generate(assets)
end

function AssetLicensingSystem.generateTextCredits(assets)
    local credits = {"Asset Credits:", ""}
    
    for _, asset in ipairs(assets) do
        local attribution = AssetLicensingSystem.generateAttribution(asset.id, "detailed")
        if attribution then
            table.insert(credits, "• " .. attribution)
        end
    end
    
    return table.concat(credits, "\n")
end

function AssetLicensingSystem.generateHtmlCredits(assets)
    local credits = {"<h2>Asset Credits</h2>", "<ul>"}
    
    for _, asset in ipairs(assets) do
        local attribution = AssetLicensingSystem.generateAttribution(asset.id, "detailed")
        if attribution then
            table.insert(credits, string.format("<li>%s</li>", attribution))
        end
    end
    
    table.insert(credits, "</ul>")
    
    return table.concat(credits, "\n")
end

function AssetLicensingSystem.generateJsonCredits(assets)
    local credits = {
        title = "Asset Credits",
        generated = os.date("%Y-%m-%d %H:%M:%S"),
        assets = {}
    }
    
    for _, asset in ipairs(assets) do
        local license = asset.license
        table.insert(credits.assets, {
            id = asset.id,
            title = license.attribution.title or "Untitled",
            creator = license.attribution.creator or "Unknown",
            license = LicensingState.licenseDatabase[license.licenseType].name,
            source = license.source
        })
    end
    
    return HttpService:JSONEncode(credits)
end

function AssetLicensingSystem.generateMarkdownCredits(assets)
    local credits = {"# Asset Credits", ""}
    
    for _, asset in ipairs(assets) do
        local license = asset.license
        local licenseInfo = LicensingState.licenseDatabase[license.licenseType]
        
        local entry = string.format("- **%s** by %s ([%s](%s))", 
            license.attribution.title or "Untitled",
            license.attribution.creator or "Unknown",
            licenseInfo.name,
            licenseInfo.url)
        
        if license.source then
            entry = entry .. string.format(" - [Source](%s)", license.source)
        end
        
        table.insert(credits, entry)
    end
    
    return table.concat(credits, "\n")
end

-- ========================================
-- COMPLIANCE TRACKING
-- ========================================

function AssetLicensingSystem.setupComplianceTracking()
    LicensingState.complianceTracker = {
        enabled = LICENSING_CONFIG.compliance.enableAutomaticChecks,
        auditor = {},
        monitor = {},
        reporter = {}
    }
    
    -- Initialize compliance auditor
    AssetLicensingSystem.initializeComplianceAuditor()
    
    print("✅ Compliance tracking initialized")
end

function AssetLicensingSystem.initializeComplianceAuditor()
    LicensingState.complianceTracker.auditor = {
        checks = {
            license_validity = AssetLicensingSystem.createLicenseValidityCheck(),
            attribution_presence = AssetLicensingSystem.createAttributionPresenceCheck(),
            permission_compliance = AssetLicensingSystem.createPermissionComplianceCheck(),
            expiration_monitoring = AssetLicensingSystem.createExpirationMonitoringCheck()
        }
    }
end

function AssetLicensingSystem.createLicenseValidityCheck()
    return {
        name = "license_validity",
        description = "Check if all assets have valid licenses",
        execute = function()
            return AssetLicensingSystem.checkLicenseValidity()
        end
    }
end

function AssetLicensingSystem.createAttributionPresenceCheck()
    return {
        name = "attribution_presence",
        description = "Check if required attributions are present",
        execute = function()
            return AssetLicensingSystem.checkAttributionPresence()
        end
    }
end

function AssetLicensingSystem.createPermissionComplianceCheck()
    return {
        name = "permission_compliance",
        description = "Check if asset usage complies with license permissions",
        execute = function()
            return AssetLicensingSystem.checkPermissionCompliance()
        end
    }
end

function AssetLicensingSystem.createExpirationMonitoringCheck()
    return {
        name = "expiration_monitoring",
        description = "Monitor license expirations",
        execute = function()
            return AssetLicensingSystem.checkLicenseExpirations()
        end
    }
end

function AssetLicensingSystem.runComplianceAudit()
    print("✅ Running compliance audit...")
    
    local audit = {
        id = HttpService:GenerateGUID(false),
        timestamp = tick(),
        results = {},
        violations = {},
        warnings = {},
        summary = {}
    }
    
    -- Run all compliance checks
    for checkName, check in pairs(LicensingState.complianceTracker.auditor.checks) do
        local result = check.execute()
        audit.results[checkName] = result
        
        -- Collect violations and warnings
        if result.violations then
            for _, violation in ipairs(result.violations) do
                table.insert(audit.violations, violation)
            end
        end
        
        if result.warnings then
            for _, warning in ipairs(result.warnings) do
                table.insert(audit.warnings, warning)
            end
        end
    end
    
    -- Generate summary
    audit.summary = {
        totalAssets = LicensingState.stats.totalAssets,
        compliantAssets = LicensingState.stats.compliantAssets,
        violations = #audit.violations,
        warnings = #audit.warnings,
        complianceRate = LicensingState.stats.totalAssets > 0 and 
            (LicensingState.stats.compliantAssets / LicensingState.stats.totalAssets) * 100 or 100
    }
    
    LicensingState.auditResults[audit.id] = audit
    
    print(string.format("✅ Compliance audit completed: %d violations, %d warnings", 
        #audit.violations, #audit.warnings))
    
    return audit
end

function AssetLicensingSystem.checkLicenseValidity()
    local result = {
        passed = true,
        violations = {},
        warnings = {}
    }
    
    for assetId, license in pairs(LicensingState.assetLicenses) do
        if not license.isValidated then
            result.passed = false
            table.insert(result.violations, {
                assetId = assetId,
                type = "invalid_license",
                description = "Asset has invalid or missing license",
                severity = "high"
            })
        end
    end
    
    return result
end

function AssetLicensingSystem.checkAttributionPresence()
    local result = {
        passed = true,
        violations = {},
        warnings = {}
    }
    
    for assetId, license in pairs(LicensingState.assetLicenses) do
        local licenseInfo = LicensingState.licenseDatabase[license.licenseType]
        
        if licenseInfo.attribution and not license.attribution then
            result.passed = false
            table.insert(result.violations, {
                assetId = assetId,
                type = "missing_attribution",
                description = "Attribution required but not provided",
                severity = "medium"
            })
        end
    end
    
    return result
end

function AssetLicensingSystem.checkPermissionCompliance()
    local result = {
        passed = true,
        violations = {},
        warnings = {}
    }
    
    -- This would check against actual usage patterns
    -- For demo purposes, assume commercial usage
    for assetId, license in pairs(LicensingState.assetLicenses) do
        local licenseInfo = LicensingState.licenseDatabase[license.licenseType]
        
        if not licenseInfo.commercial then
            table.insert(result.warnings, {
                assetId = assetId,
                type = "commercial_restriction",
                description = "Asset license restricts commercial use",
                severity = "medium"
            })
        end
    end
    
    return result
end

function AssetLicensingSystem.checkLicenseExpirations()
    local result = {
        passed = true,
        violations = {},
        warnings = {}
    }
    
    local currentTime = tick()
    local warningThreshold = LICENSING_CONFIG.compliance.warningThreshold * 86400
    
    for assetId, license in pairs(LicensingState.assetLicenses) do
        if license.expiration then
            local timeToExpiration = license.expiration - currentTime
            
            if timeToExpiration <= 0 then
                result.passed = false
                table.insert(result.violations, {
                    assetId = assetId,
                    type = "expired_license",
                    description = "License has expired",
                    severity = "high"
                })
            elseif timeToExpiration <= warningThreshold then
                table.insert(result.warnings, {
                    assetId = assetId,
                    type = "expiring_license",
                    description = string.format("License expires in %d days", 
                        math.ceil(timeToExpiration / 86400)),
                    severity = "low"
                })
            end
        end
    end
    
    return result
end

-- ========================================
-- LEGAL MANAGEMENT
-- ========================================

function AssetLicensingSystem.initializeLegalManagement()
    LicensingState.legalManager = {
        copyrightTracker = {},
        trademarkTracker = {},
        riskAssessor = {},
        documentGenerator = {}
    }
    
    -- Initialize copyright tracking
    AssetLicensingSystem.initializeCopyrightTracking()
    
    -- Initialize risk assessment
    AssetLicensingSystem.initializeRiskAssessment()
    
    print("⚖️ Legal management initialized")
end

function AssetLicensingSystem.initializeCopyrightTracking()
    LicensingState.legalManager.copyrightTracker = {
        database = {},
        verification = {},
        protection = {}
    }
end

function AssetLicensingSystem.initializeRiskAssessment()
    LicensingState.legalManager.riskAssessor = {
        assessments = {},
        categories = LICENSING_CONFIG.legal.riskCategories,
        factors = {
            "license_clarity",
            "attribution_completeness", 
            "permission_alignment",
            "jurisdiction_compatibility",
            "usage_scope"
        }
    }
end

function AssetLicensingSystem.assessLegalRisk(assetId)
    local license = LicensingState.assetLicenses[assetId]
    if not license then
        return {risk = "critical", factors = {"no_license"}}
    end
    
    local assessment = {
        assetId = assetId,
        timestamp = tick(),
        risk = "low",
        score = 0,
        factors = {},
        recommendations = {}
    }
    
    -- Assess license clarity
    if not license.isValidated then
        assessment.score = assessment.score + 3
        table.insert(assessment.factors, "unclear_license")
    end
    
    -- Assess attribution completeness
    local licenseInfo = LicensingState.licenseDatabase[license.licenseType]
    if licenseInfo.attribution and not license.attribution then
        assessment.score = assessment.score + 2
        table.insert(assessment.factors, "missing_attribution")
    end
    
    -- Determine risk level
    if assessment.score >= 5 then
        assessment.risk = "critical"
    elseif assessment.score >= 3 then
        assessment.risk = "high"
    elseif assessment.score >= 1 then
        assessment.risk = "medium"
    else
        assessment.risk = "low"
    end
    
    -- Generate recommendations
    if assessment.score > 0 then
        table.insert(assessment.recommendations, "Review and validate asset licensing")
        if not license.attribution and licenseInfo.attribution then
            table.insert(assessment.recommendations, "Add required attribution information")
        end
    end
    
    LicensingState.riskAssessments[assetId] = assessment
    
    return assessment
end

-- ========================================
-- COMPLIANCE MONITORING
-- ========================================

function AssetLicensingSystem.startComplianceMonitoring()
    -- Event-driven compliance monitoring with adaptive intervals
    local complianceEvent = Instance.new("BindableEvent")
    
    local function scheduleComplianceCheck()
        if not LICENSING_CONFIG.compliance.enableAutomaticChecks then
            -- Much longer wait when disabled
            task.spawn(function()
                task.wait(LICENSING_CONFIG.compliance.auditInterval * 10)
                complianceEvent:Fire()
            end)
            return
        end
        
        -- Adaptive interval based on compliance violations
        local violationCount = #(LicensingState.violations or {})
        local interval = LICENSING_CONFIG.compliance.auditInterval
        
        if violationCount > 5 then
            interval = interval * 0.5 -- More frequent checks if violations found
        elseif violationCount == 0 then
            interval = interval * 2 -- Less frequent if no violations
        end
        
        task.spawn(function()
            task.wait(interval)
            complianceEvent:Fire()
        end)
    end
    
    complianceEvent.Event:Connect(function()
        if LICENSING_CONFIG.compliance.enableAutomaticChecks then
            AssetLicensingSystem.performComplianceChecks()
            AssetLicensingSystem.updateComplianceStatistics()
        end
        
        -- Schedule next check
        scheduleComplianceCheck()
    end)
    
    -- Start monitoring
    scheduleComplianceCheck()
    
    print("👁️ Compliance monitoring started")
end

function AssetLicensingSystem.performComplianceChecks()
    -- Run quick compliance checks
    local quickAudit = AssetLicensingSystem.runComplianceAudit()
    
    -- Update compliance status
    LicensingState.stats.violations = #quickAudit.violations
    LicensingState.stats.compliantAssets = quickAudit.summary.compliantAssets
    
    -- Check for critical violations
    for _, violation in ipairs(quickAudit.violations) do
        if violation.severity == "high" or violation.severity == "critical" then
            AssetLicensingSystem.handleCriticalViolation(violation)
        end
    end
end

function AssetLicensingSystem.handleCriticalViolation(violation)
    print(string.format("🚨 Critical license violation: %s (%s)", 
        violation.description, violation.assetId))
    
    -- Store violation
    table.insert(LicensingState.violations, violation)
    
    -- Take action based on strict mode
    if LICENSING_CONFIG.compliance.strictMode then
        -- In strict mode, disable the asset
        print(string.format("⛔ Disabling asset due to critical violation: %s", violation.assetId))
    end
end

function AssetLicensingSystem.updateComplianceStatistics()
    local stats = LicensingState.stats
    
    -- Update attribution coverage
    local attributedAssets = 0
    for assetId, license in pairs(LicensingState.assetLicenses) do
        if license.attribution or not LicensingState.licenseDatabase[license.licenseType].attribution then
            attributedAssets = attributedAssets + 1
        end
    end
    
    stats.attributionCoverage = stats.totalAssets > 0 and (attributedAssets / stats.totalAssets) * 100 or 100
    
    -- Update overall risk level
    local riskCounts = {low = 0, medium = 0, high = 0, critical = 0}
    for _, assessment in pairs(LicensingState.riskAssessments) do
        riskCounts[assessment.risk] = riskCounts[assessment.risk] + 1
    end
    
    if riskCounts.critical > 0 then
        stats.riskLevel = "critical"
    elseif riskCounts.high > 0 then
        stats.riskLevel = "high"
    elseif riskCounts.medium > 0 then
        stats.riskLevel = "medium"
    else
        stats.riskLevel = "low"
    end
end

-- ========================================
-- PUBLIC API
-- ========================================

function AssetLicensingSystem.runLicensingDemo()
    print("⚖️ Running asset licensing demonstration...")
    
    -- Register sample asset licenses
    local sampleAssets = {
        {id = "ui_background", type = "ccBy", creator = "Artist1", title = "Blue Background"},
        {id = "character_model", type = "mit", creator = "Modeler2", title = "Hero Character"},
        {id = "ambient_music", type = "ccByNc", creator = "Composer3", title = "Forest Ambience"},
        {id = "particle_effect", type = "proprietary", creator = "EffectStudio", title = "Magic Sparkles"},
        {id = "sound_effect", type = "publicDomain", creator = "Various", title = "Explosion Sound"}
    }
    
    print("  📜 Registering asset licenses...")
    
    for _, asset in ipairs(sampleAssets) do
        AssetLicensingSystem.registerAssetLicense(asset.id, {
            type = asset.type,
            attribution = {
                creator = asset.creator,
                title = asset.title,
                year = "2025"
            },
            source = string.format("https://assets.example.com/%s", asset.id)
        })
    end
    
    -- Generate attributions
    print("  🏷️ Generating attributions...")
    
    for _, asset in ipairs(sampleAssets) do
        local attribution = AssetLicensingSystem.generateAttribution(asset.id, "detailed")
        print(string.format("    %s: %s", asset.id, attribution))
    end
    
    -- Generate credits file
    local assetIds = {}
    for _, asset in ipairs(sampleAssets) do
        table.insert(assetIds, asset.id)
    end
    
    local creditsFile = AssetLicensingSystem.generateCreditsFile(assetIds, "text")
    print("  📄 Generated credits file:")
    print("    " .. string.gsub(creditsFile, "\n", "\n    "))
    
    -- Run compliance audit
    print("  ✅ Running compliance audit...")
    local audit = AssetLicensingSystem.runComplianceAudit()
    
    print(string.format("    Compliance rate: %.1f%%", audit.summary.complianceRate))
    print(string.format("    Violations: %d", audit.summary.violations))
    print(string.format("    Warnings: %d", audit.summary.warnings))
    
    -- Assess legal risks
    print("  ⚖️ Assessing legal risks...")
    
    for _, asset in ipairs(sampleAssets) do
        local risk = AssetLicensingSystem.assessLegalRisk(asset.id)
        print(string.format("    %s: %s risk", asset.id, risk.risk))
    end
    
    -- Show licensing statistics
    local stats = AssetLicensingSystem.getLicensingStats()
    print("  📊 Licensing Statistics:")
    print(string.format("    Total assets: %d", stats.totalAssets))
    print(string.format("    Licensed assets: %d", stats.licensedAssets))
    print(string.format("    Compliant assets: %d", stats.compliantAssets))
    print(string.format("    Attribution coverage: %.1f%%", stats.attributionCoverage))
    print(string.format("    Overall risk level: %s", stats.riskLevel))
    
    print("⚖️ Asset licensing demonstration completed")
end

function AssetLicensingSystem.getLicensingStats()
    return LicensingState.stats
end

function AssetLicensingSystem.getAssetLicense(assetId)
    return LicensingState.assetLicenses[assetId]
end

function AssetLicensingSystem.getComplianceResults()
    return LicensingState.complianceResults
end

function AssetLicensingSystem.getAuditResults()
    return LicensingState.auditResults
end

function AssetLicensingSystem.getRiskAssessments()
    return LicensingState.riskAssessments
end

function AssetLicensingSystem.getAttributionRecords(assetId)
    return LicensingState.attributionRecords[assetId]
end

-- Export API
AssetLicensingSystem.registerAssetLicense = AssetLicensingSystem.registerAssetLicense
AssetLicensingSystem.generateAttribution = AssetLicensingSystem.generateAttribution
AssetLicensingSystem.generateCreditsFile = AssetLicensingSystem.generateCreditsFile
AssetLicensingSystem.runComplianceAudit = AssetLicensingSystem.runComplianceAudit
AssetLicensingSystem.assessLegalRisk = AssetLicensingSystem.assessLegalRisk

-- Initialize the asset licensing system
AssetLicensingSystem.initialize()

print("⚖️ AssetLicensingSystem loaded with comprehensive licensing and attribution management")

return AssetLicensingSystem
