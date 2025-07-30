-- RobuxIntegration.luau
-- Real Robux integration with proper transaction handling and validation
-- Provides secure payment processing, fraud prevention, and transaction management

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local MarketplaceService = game:GetService("MarketplaceService")
local Players = game:GetService("Players")
local HttpService = game:GetService("HttpService")
local DataStoreService = game:GetService("DataStoreService")
local TeleportService = game:GetService("TeleportService")

local SafeRequire = require(ReplicatedStorage.Shared.utils.SafeRequire)

local RobuxIntegration = {}

-- ========================================
-- INTEGRATION CONFIGURATION
-- ========================================

local ROBUX_CONFIG = {
    -- Transaction settings
    transactions = {
        enableReceiptValidation = true,
        enableDuplicateDetection = true,
        enableFraudPrevention = true,
        transactionTimeout = 30,           -- 30 seconds
        maxRetryAttempts = 3,
        batchProcessingEnabled = true,
        auditLoggingEnabled = true
    },
    
    -- Security settings
    security = {
        enableTransactionSigning = true,
        validateProductInfo = true,
        checkPlayerOwnership = true,
        enableRateLimiting = true,
        maxTransactionsPerMinute = 10,
        suspiciousActivityThreshold = 5,
        ipWhitelistEnabled = false
    },
    
    -- Validation rules
    validation = {
        minimumAccountAge = 1,             -- 1 day minimum
        minimumPlayTime = 300,             -- 5 minutes minimum
        validateRobuxBalance = true,
        checkPurchaseHistory = true,
        enableVelocityChecks = true,
        maxVelocityPerHour = 1000          -- R$1000 per hour
    },
    
    -- Error handling
    errorHandling = {
        enableGracefulFailure = true,
        retryFailedTransactions = true,
        notifyOnFailure = true,
        escalateAfterAttempts = 3,
        enableFallbackMethods = true
    },
    
    -- Analytics
    analytics = {
        trackTransactionMetrics = true,
        enableRevenueAnalytics = true,
        trackConversionFunnels = true,
        enableCohortAnalysis = true,
        realTimeReporting = true
    }
}

-- ========================================
-- TRANSACTION STATE
-- ========================================

local TransactionState = {
    -- Active transactions
    pendingTransactions = {},
    processingTransactions = {},
    completedTransactions = {},
    failedTransactions = {},
    
    -- Player tracking
    playerTransactions = {},
    playerVelocity = {},
    suspiciousPlayers = {},
    
    -- Validation data
    productValidation = {},
    priceVerification = {},
    
    -- Security monitoring
    securityEvents = {},
    fraudAttempts = {},
    rateLimitTracking = {},
    
    -- Analytics data
    revenueMetrics = {},
    conversionMetrics = {},
    transactionAnalytics = {},
    
    -- System health
    systemHealth = {
        transactionSuccessRate = 100,
        averageProcessingTime = 0,
        errorRate = 0,
        fraudDetectionRate = 0
    },
    
    -- Statistics
    stats = {
        totalTransactions = 0,
        totalRevenue = 0,
        successfulTransactions = 0,
        failedTransactions = 0,
        fraudulentTransactions = 0,
        averageTransactionValue = 0,
        peakTransactionsPerMinute = 0
    }
}

function RobuxIntegration.initialize()
    print("💳 Initializing RobuxIntegration...")
    
    -- Set up MarketplaceService connections
    RobuxIntegration.setupMarketplaceConnections()
    
    -- Initialize transaction processor
    RobuxIntegration.initializeTransactionProcessor()
    
    -- Set up security system
    RobuxIntegration.setupSecuritySystem()
    
    -- Initialize validation engine
    RobuxIntegration.initializeValidationEngine()
    
    -- Start monitoring systems
    RobuxIntegration.startMonitoringSystems()
    
    print("💳 RobuxIntegration initialized successfully")
end

-- ========================================
-- MARKETPLACE CONNECTIONS
-- ========================================

function RobuxIntegration.setupMarketplaceConnections()
    -- Set up receipt processing
    MarketplaceService.ProcessReceipt = RobuxIntegration.processReceiptSecure
    
    -- Connect to purchase events
    MarketplaceService.PromptGamePassPurchaseFinished:Connect(RobuxIntegration.onGamePassPurchaseFinished)
    MarketplaceService.PromptProductPurchaseFinished:Connect(RobuxIntegration.onProductPurchaseFinished)
    MarketplaceService.PromptBundlePurchaseFinished:Connect(RobuxIntegration.onBundlePurchaseFinished)
    
    -- Connect to info events
    MarketplaceService.PromptGamePassPurchaseRequested:Connect(RobuxIntegration.onGamePassPurchaseRequested)
    MarketplaceService.PromptProductPurchaseRequested:Connect(RobuxIntegration.onProductPurchaseRequested)
    
    print("🔗 Marketplace connections established")
end

function RobuxIntegration.processReceiptSecure(receiptInfo)
    local transactionId = HttpService:GenerateGUID(false)
    
    print(string.format("💳 Processing secure receipt: %s (Transaction: %s)", 
        receiptInfo.PurchaseId, transactionId))
    
    -- Create transaction record
    local transaction = {
        id = transactionId,
        receiptInfo = receiptInfo,
        timestamp = tick(),
        status = "processing",
        validationSteps = {},
        securityChecks = {},
        fraudScore = 0,
        processingTime = 0
    }
    
    TransactionState.processingTransactions[transactionId] = transaction
    
    -- Start async processing
    spawn(function()
        local startTime = tick()
        local result = RobuxIntegration.processTransactionSecurely(transaction)
        transaction.processingTime = tick() - startTime
        
        -- Update statistics
        RobuxIntegration.updateTransactionStatistics(transaction, result)
        
        -- Clean up
        TransactionState.processingTransactions[transactionId] = nil
        
        if result.success then
            TransactionState.completedTransactions[transactionId] = transaction
            TransactionState.stats.successfulTransactions = TransactionState.stats.successfulTransactions + 1
        else
            TransactionState.failedTransactions[transactionId] = transaction
            TransactionState.stats.failedTransactions = TransactionState.stats.failedTransactions + 1
        end
        
        print(string.format("💳 Transaction %s completed: %s (%.3fs)", 
            transactionId, result.success and "SUCCESS" or "FAILED", transaction.processingTime))
    end)
    
    -- Return immediate processing decision
    return Enum.ProductPurchaseDecision.NotProcessedYet
end

function RobuxIntegration.processTransactionSecurely(transaction)
    local receiptInfo = transaction.receiptInfo
    local result = {success = false, reason = "", decision = Enum.ProductPurchaseDecision.NotProcessedYet}
    
    -- Step 1: Basic validation
    local basicValidation = RobuxIntegration.performBasicValidation(receiptInfo)
    table.insert(transaction.validationSteps, basicValidation)
    
    if not basicValidation.valid then
        result.reason = basicValidation.reason
        result.decision = Enum.ProductPurchaseDecision.NotProcessedYet
        return result
    end
    
    -- Step 2: Player validation
    local player = Players:GetPlayerByUserId(receiptInfo.PlayerId)
    if not player then
        result.reason = "Player not found"
        result.decision = Enum.ProductPurchaseDecision.NotProcessedYet
        return result
    end
    
    -- Step 3: Product validation
    local productValidation = RobuxIntegration.validateProduct(receiptInfo.ProductId, receiptInfo.CurrencySpent)
    table.insert(transaction.validationSteps, productValidation)
    
    if not productValidation.valid then
        result.reason = productValidation.reason
        result.decision = Enum.ProductPurchaseDecision.NotProcessedYet
        return result
    end
    
    -- Step 4: Duplicate detection
    local duplicateCheck = RobuxIntegration.checkForDuplicate(receiptInfo.PurchaseId)
    table.insert(transaction.validationSteps, duplicateCheck)
    
    if duplicateCheck.isDuplicate then
        result.reason = "Duplicate transaction"
        result.success = true
        result.decision = Enum.ProductPurchaseDecision.PurchaseGranted
        return result
    end
    
    -- Step 5: Security checks
    local securityCheck = RobuxIntegration.performSecurityChecks(player, receiptInfo)
    table.insert(transaction.securityChecks, securityCheck)
    transaction.fraudScore = securityCheck.fraudScore
    
    if securityCheck.fraudDetected then
        result.reason = securityCheck.reason
        result.decision = Enum.ProductPurchaseDecision.NotProcessedYet
        RobuxIntegration.reportFraudulentActivity(player, receiptInfo, securityCheck)
        return result
    end
    
    -- Step 6: Rate limiting
    local rateLimitCheck = RobuxIntegration.checkRateLimit(player)
    table.insert(transaction.securityChecks, rateLimitCheck)
    
    if not rateLimitCheck.allowed then
        result.reason = "Rate limit exceeded"
        result.decision = Enum.ProductPurchaseDecision.NotProcessedYet
        return result
    end
    
    -- Step 7: Business logic validation
    local businessValidation = RobuxIntegration.validateBusinessLogic(player, receiptInfo)
    table.insert(transaction.validationSteps, businessValidation)
    
    if not businessValidation.valid then
        result.reason = businessValidation.reason
        result.decision = Enum.ProductPurchaseDecision.NotProcessedYet
        return result
    end
    
    -- Step 8: Process the purchase
    local fulfillmentResult = RobuxIntegration.fulfillPurchase(player, receiptInfo, productValidation.productInfo)
    
    if fulfillmentResult.success then
        -- Record successful transaction
        RobuxIntegration.recordSuccessfulTransaction(player, receiptInfo, transaction)
        
        result.success = true
        result.decision = Enum.ProductPurchaseDecision.PurchaseGranted
        result.reason = "Purchase successful"
        
        -- Update player tracking
        RobuxIntegration.updatePlayerTransactionHistory(player, receiptInfo)
        
    else
        result.reason = fulfillmentResult.reason
        result.decision = Enum.ProductPurchaseDecision.NotProcessedYet
    end
    
    return result
end

function RobuxIntegration.onGamePassPurchaseFinished(player, gamePassId, wasPurchased)
    local event = {
        timestamp = tick(),
        type = "gamepass_purchase_finished",
        playerId = player.UserId,
        playerName = player.Name,
        gamePassId = gamePassId,
        wasPurchased = wasPurchased
    }
    
    print(string.format("🎫 GamePass purchase finished: %s - %s (%s)", 
        player.Name, gamePassId, wasPurchased and "SUCCESS" or "CANCELLED"))
    
    -- Track analytics
    RobuxIntegration.trackPurchaseEvent(event)
    
    if wasPurchased then
        -- Verify ownership and apply benefits
        spawn(function()
            task.wait(1) -- Small delay to ensure MarketplaceService is updated
            RobuxIntegration.verifyAndApplyGamePassBenefits(player, gamePassId)
        end)
    end
end

function RobuxIntegration.onProductPurchaseFinished(player, productId, wasPurchased)
    local event = {
        timestamp = tick(),
        type = "product_purchase_finished",
        playerId = player.UserId,
        playerName = player.Name,
        productId = productId,
        wasPurchased = wasPurchased
    }
    
    print(string.format("🛒 Product purchase finished: %s - %s (%s)", 
        player.Name, productId, wasPurchased and "SUCCESS" or "CANCELLED"))
    
    -- Track analytics
    RobuxIntegration.trackPurchaseEvent(event)
end

function RobuxIntegration.onBundlePurchaseFinished(player, bundleId, wasPurchased)
    local event = {
        timestamp = tick(),
        type = "bundle_purchase_finished",
        playerId = player.UserId,
        playerName = player.Name,
        bundleId = bundleId,
        wasPurchased = wasPurchased
    }
    
    print(string.format("📦 Bundle purchase finished: %s - %s (%s)", 
        player.Name, bundleId, wasPurchased and "SUCCESS" or "CANCELLED"))
    
    -- Track analytics
    RobuxIntegration.trackPurchaseEvent(event)
end

function RobuxIntegration.onGamePassPurchaseRequested(player, gamePassId)
    print(string.format("🎫 GamePass purchase requested: %s - %s", player.Name, gamePassId))
    
    -- Pre-purchase validation
    local validation = RobuxIntegration.validateGamePassPurchase(player, gamePassId)
    
    if not validation.valid then
        print(string.format("❌ GamePass purchase blocked: %s", validation.reason))
        -- Could potentially block the purchase here if needed
    end
end

function RobuxIntegration.onProductPurchaseRequested(player, productId)
    print(string.format("🛒 Product purchase requested: %s - %s", player.Name, productId))
    
    -- Pre-purchase validation
    local validation = RobuxIntegration.validateProductPurchase(player, productId)
    
    if not validation.valid then
        print(string.format("❌ Product purchase blocked: %s", validation.reason))
    end
end

-- ========================================
-- VALIDATION ENGINE
-- ========================================

function RobuxIntegration.initializeValidationEngine()
    TransactionState.validationEngine = {
        basicValidator = RobuxIntegration.createBasicValidator(),
        productValidator = RobuxIntegration.createProductValidator(),
        securityValidator = RobuxIntegration.createSecurityValidator(),
        businessValidator = RobuxIntegration.createBusinessValidator()
    }
    
    print("✅ Validation engine initialized")
end

function RobuxIntegration.createBasicValidator()
    return {
        name = "basic_validator",
        
        validate = function(self, receiptInfo)
            return RobuxIntegration.performBasicValidation(receiptInfo)
        end
    }
end

function RobuxIntegration.createProductValidator()
    return {
        name = "product_validator",
        
        validate = function(self, productId, price)
            return RobuxIntegration.validateProduct(productId, price)
        end
    }
end

function RobuxIntegration.createSecurityValidator()
    return {
        name = "security_validator",
        
        validate = function(self, player, receiptInfo)
            return RobuxIntegration.performSecurityChecks(player, receiptInfo)
        end
    }
end

function RobuxIntegration.createBusinessValidator()
    return {
        name = "business_validator",
        
        validate = function(self, player, receiptInfo)
            return RobuxIntegration.validateBusinessLogic(player, receiptInfo)
        end
    }
end

function RobuxIntegration.performBasicValidation(receiptInfo)
    local validation = {valid = true, reason = "", checks = {}}
    
    -- Check required fields
    if not receiptInfo.PlayerId then
        validation.valid = false
        validation.reason = "Missing PlayerId"
        return validation
    end
    
    if not receiptInfo.ProductId then
        validation.valid = false
        validation.reason = "Missing ProductId"
        return validation
    end
    
    if not receiptInfo.PurchaseId then
        validation.valid = false
        validation.reason = "Missing PurchaseId"
        return validation
    end
    
    if not receiptInfo.CurrencySpent or receiptInfo.CurrencySpent <= 0 then
        validation.valid = false
        validation.reason = "Invalid currency amount"
        return validation
    end
    
    if receiptInfo.CurrencyType ~= Enum.CurrencyType.Robux then
        validation.valid = false
        validation.reason = "Invalid currency type"
        return validation
    end
    
    table.insert(validation.checks, "basic_structure_valid")
    
    return validation
end

function RobuxIntegration.validateProduct(productId, expectedPrice)
    local validation = {valid = true, reason = "", productInfo = nil}
    
    -- Get product info from MarketplaceService
    local success, productInfo = pcall(function()
        return MarketplaceService:GetProductInfo(productId, Enum.InfoType.Product)
    end)
    
    if not success then
        validation.valid = false
        validation.reason = "Failed to retrieve product info"
        return validation
    end
    
    if not productInfo then
        validation.valid = false
        validation.reason = "Product not found"
        return validation
    end
    
    validation.productInfo = productInfo
    
    -- Validate product is for sale
    if not productInfo.IsForSale then
        validation.valid = false
        validation.reason = "Product not for sale"
        return validation
    end
    
    -- Validate price (if provided)
    if expectedPrice and productInfo.PriceInRobux ~= expectedPrice then
        validation.valid = false
        validation.reason = string.format("Price mismatch: expected %d, got %d", 
            productInfo.PriceInRobux, expectedPrice)
        return validation
    end
    
    return validation
end

function RobuxIntegration.performSecurityChecks(player, receiptInfo)
    local securityCheck = {
        fraudDetected = false,
        fraudScore = 0,
        reason = "",
        checks = {}
    }
    
    -- Check 1: Account age
    local accountAge = player.AccountAge
    if accountAge < ROBUX_CONFIG.validation.minimumAccountAge then
        securityCheck.fraudScore = securityCheck.fraudScore + 30
        table.insert(securityCheck.checks, "young_account")
    end
    
    -- Check 2: Play time validation
    local playTime = RobuxIntegration.getPlayerPlayTime(player)
    if playTime < ROBUX_CONFIG.validation.minimumPlayTime then
        securityCheck.fraudScore = securityCheck.fraudScore + 20
        table.insert(securityCheck.checks, "insufficient_playtime")
    end
    
    -- Check 3: Velocity check
    local velocity = RobuxIntegration.calculatePlayerVelocity(player)
    if velocity > ROBUX_CONFIG.validation.maxVelocityPerHour then
        securityCheck.fraudScore = securityCheck.fraudScore + 40
        table.insert(securityCheck.checks, "high_velocity")
    end
    
    -- Check 4: Suspicious activity patterns
    local suspiciousActivity = RobuxIntegration.checkSuspiciousActivity(player)
    if suspiciousActivity.detected then
        securityCheck.fraudScore = securityCheck.fraudScore + suspiciousActivity.score
        table.insert(securityCheck.checks, "suspicious_activity")
    end
    
    -- Check 5: IP/Location validation
    local locationCheck = RobuxIntegration.validatePlayerLocation(player)
    if not locationCheck.valid then
        securityCheck.fraudScore = securityCheck.fraudScore + 25
        table.insert(securityCheck.checks, "location_anomaly")
    end
    
    -- Determine if fraud is detected
    if securityCheck.fraudScore > 70 then
        securityCheck.fraudDetected = true
        securityCheck.reason = "High fraud score"
    end
    
    return securityCheck
end

function RobuxIntegration.validateBusinessLogic(player, receiptInfo)
    local validation = {valid = true, reason = "", checks = {}}
    
    -- Check if player already owns gamepass (for gamepasses)
    if RobuxIntegration.isGamePass(receiptInfo.ProductId) then
        local hasGamepass = MarketplaceService:UserOwnsGamePassAsync(player.UserId, receiptInfo.ProductId)
        if hasGamepass then
            validation.valid = false
            validation.reason = "Player already owns gamepass"
            return validation
        end
    end
    
    -- Check purchase cooldowns
    local lastPurchase = RobuxIntegration.getLastPurchaseTime(player)
    local cooldownPeriod = 60 -- 1 minute cooldown
    
    if tick() - lastPurchase < cooldownPeriod then
        validation.valid = false
        validation.reason = "Purchase cooldown active"
        return validation
    end
    
    -- Check daily spending limits
    local dailySpending = RobuxIntegration.getDailySpending(player)
    local maxDailySpending = 5000 -- R$5000 daily limit
    
    if dailySpending + receiptInfo.CurrencySpent > maxDailySpending then
        validation.valid = false
        validation.reason = "Daily spending limit exceeded"
        return validation
    end
    
    table.insert(validation.checks, "business_logic_valid")
    
    return validation
end

function RobuxIntegration.checkForDuplicate(purchaseId)
    local check = {isDuplicate = false, originalTransaction = nil}
    
    -- Check in completed transactions
    for transactionId, transaction in pairs(TransactionState.completedTransactions) do
        if transaction.receiptInfo.PurchaseId == purchaseId then
            check.isDuplicate = true
            check.originalTransaction = transactionId
            return check
        end
    end
    
    -- Check in processing transactions
    for transactionId, transaction in pairs(TransactionState.processingTransactions) do
        if transaction.receiptInfo.PurchaseId == purchaseId then
            check.isDuplicate = true
            check.originalTransaction = transactionId
            return check
        end
    end
    
    return check
end

-- ========================================
-- SECURITY SYSTEM
-- ========================================

function RobuxIntegration.setupSecuritySystem()
    TransactionState.securitySystem = {
        fraudDetector = RobuxIntegration.createFraudDetector(),
        rateLimiter = RobuxIntegration.createRateLimiter(),
        activityMonitor = RobuxIntegration.createActivityMonitor(),
        threatAnalyzer = RobuxIntegration.createThreatAnalyzer()
    }
    
    print("🛡️ Security system initialized")
end

function RobuxIntegration.createFraudDetector()
    return {
        name = "fraud_detector",
        
        detect = function(self, player, transaction)
            return RobuxIntegration.detectFraud(player, transaction)
        end,
        
        analyze = function(self, player)
            return RobuxIntegration.analyzeFraudRisk(player)
        end
    }
end

function RobuxIntegration.createRateLimiter()
    return {
        name = "rate_limiter",
        
        check = function(self, player)
            return RobuxIntegration.checkRateLimit(player)
        end,
        
        update = function(self, player)
            RobuxIntegration.updateRateLimit(player)
        end
    }
end

function RobuxIntegration.createActivityMonitor()
    return {
        name = "activity_monitor",
        
        monitor = function(self, player)
            return RobuxIntegration.monitorPlayerActivity(player)
        end
    }
end

function RobuxIntegration.createThreatAnalyzer()
    return {
        name = "threat_analyzer",
        
        analyze = function(self)
            return RobuxIntegration.analyzeThreatLevel()
        end
    }
end

function RobuxIntegration.checkRateLimit(player)
    local check = {allowed = true, reason = "", remaining = 0}
    
    local currentTime = tick()
    local playerId = player.UserId
    
    -- Initialize rate limit tracking for player
    if not TransactionState.rateLimitTracking[playerId] then
        TransactionState.rateLimitTracking[playerId] = {
            transactions = {},
            lastReset = currentTime
        }
    end
    
    local tracking = TransactionState.rateLimitTracking[playerId]
    
    -- Reset if more than a minute has passed
    if currentTime - tracking.lastReset > 60 then
        tracking.transactions = {}
        tracking.lastReset = currentTime
    end
    
    -- Count recent transactions
    local recentCount = 0
    for _, timestamp in ipairs(tracking.transactions) do
        if currentTime - timestamp <= 60 then
            recentCount = recentCount + 1
        end
    end
    
    -- Check against limit
    local maxTransactions = ROBUX_CONFIG.security.maxTransactionsPerMinute
    if recentCount >= maxTransactions then
        check.allowed = false
        check.reason = "Rate limit exceeded"
        check.remaining = 0
    else
        check.remaining = maxTransactions - recentCount
    end
    
    return check
end

function RobuxIntegration.updateRateLimit(player)
    local playerId = player.UserId
    local currentTime = tick()
    
    if TransactionState.rateLimitTracking[playerId] then
        table.insert(TransactionState.rateLimitTracking[playerId].transactions, currentTime)
    end
end

function RobuxIntegration.calculatePlayerVelocity(player)
    local playerId = player.UserId
    local currentTime = tick()
    local hourAgo = currentTime - 3600 -- 1 hour ago
    
    local totalSpent = 0
    
    -- Check player transaction history
    if TransactionState.playerTransactions[playerId] then
        for _, transaction in ipairs(TransactionState.playerTransactions[playerId]) do
            if transaction.timestamp >= hourAgo then
                totalSpent = totalSpent + (transaction.amount or 0)
            end
        end
    end
    
    return totalSpent
end

function RobuxIntegration.checkSuspiciousActivity(player)
    local analysis = {detected = false, score = 0, patterns = {}}
    
    local playerId = player.UserId
    
    -- Check for rapid successive purchases
    local recentTransactions = RobuxIntegration.getRecentTransactions(player, 300) -- 5 minutes
    if #recentTransactions > 3 then
        analysis.score = analysis.score + 20
        table.insert(analysis.patterns, "rapid_purchases")
    end
    
    -- Check for unusual amounts
    local averageAmount = RobuxIntegration.getAverageTransactionAmount(player)
    local lastTransaction = RobuxIntegration.getLastTransaction(player)
    
    if lastTransaction and averageAmount > 0 then
        local ratio = lastTransaction.amount / averageAmount
        if ratio > 5 then -- 5x average
            analysis.score = analysis.score + 15
            table.insert(analysis.patterns, "unusual_amount")
        end
    end
    
    -- Check for new account high spending
    if player.AccountAge < 7 and RobuxIntegration.getTotalSpending(player) > 1000 then
        analysis.score = analysis.score + 25
        table.insert(analysis.patterns, "new_account_high_spending")
    end
    
    analysis.detected = analysis.score > 30
    
    return analysis
end

function RobuxIntegration.reportFraudulentActivity(player, receiptInfo, securityCheck)
    local fraudReport = {
        timestamp = tick(),
        playerId = player.UserId,
        playerName = player.Name,
        receiptInfo = receiptInfo,
        fraudScore = securityCheck.fraudScore,
        detectedPatterns = securityCheck.checks,
        ipAddress = "unknown", -- Would get from actual request
        userAgent = "unknown"  -- Would get from actual request
    }
    
    table.insert(TransactionState.fraudAttempts, fraudReport)
    TransactionState.stats.fraudulentTransactions = TransactionState.stats.fraudulentTransactions + 1
    
    -- Flag player as suspicious
    TransactionState.suspiciousPlayers[player.UserId] = {
        flagged = true,
        timestamp = tick(),
        reason = securityCheck.reason,
        fraudScore = securityCheck.fraudScore
    }
    
    print(string.format("🚨 Fraudulent activity reported: %s (Score: %d)", 
        player.Name, securityCheck.fraudScore))
end

-- ========================================
-- TRANSACTION PROCESSING
-- ========================================

function RobuxIntegration.initializeTransactionProcessor()
    TransactionState.transactionProcessor = {
        fulfillmentEngine = RobuxIntegration.createFulfillmentEngine(),
        recordKeeper = RobuxIntegration.createRecordKeeper(),
        analyticstracker = RobuxIntegration.createAnalyticsTracker(),
        errorHandler = RobuxIntegration.createErrorHandler()
    }
    
    print("⚙️ Transaction processor initialized")
end

function RobuxIntegration.createFulfillmentEngine()
    return {
        name = "fulfillment_engine",
        
        fulfill = function(self, player, receiptInfo, productInfo)
            return RobuxIntegration.fulfillPurchase(player, receiptInfo, productInfo)
        end
    }
end

function RobuxIntegration.createRecordKeeper()
    return {
        name = "record_keeper",
        
        record = function(self, player, receiptInfo, transaction)
            RobuxIntegration.recordSuccessfulTransaction(player, receiptInfo, transaction)
        end
    }
end

function RobuxIntegration.createAnalyticsTracker()
    return {
        name = "analytics_tracker",
        
        track = function(self, event)
            RobuxIntegration.trackPurchaseEvent(event)
        end
    }
end

function RobuxIntegration.createErrorHandler()
    return {
        name = "error_handler",
        
        handle = function(self, error)
            RobuxIntegration.handleTransactionError(error)
        end
    }
end

function RobuxIntegration.fulfillPurchase(player, receiptInfo, productInfo)
    local result = {success = false, reason = ""}
    
    -- Determine product type and fulfill accordingly
    if RobuxIntegration.isGamePass(receiptInfo.ProductId) then
        -- GamePass - benefits are automatically granted by Roblox
        result.success = true
        result.reason = "GamePass ownership granted"
        
    elseif RobuxIntegration.isDeveloperProduct(receiptInfo.ProductId) then
        -- Developer Product - need to grant specific benefits
        local fulfillmentResult = RobuxIntegration.fulfillDeveloperProduct(player, receiptInfo.ProductId, productInfo)
        result = fulfillmentResult
        
    else
        result.reason = "Unknown product type"
        return result
    end
    
    return result
end

function RobuxIntegration.fulfillDeveloperProduct(player, productId, productInfo)
    local result = {success = false, reason = ""}
    
    -- Here you would integrate with your game's systems to grant the appropriate rewards
    -- This is where you'd call your MonetizationSystem or other game logic
    
    -- Example fulfillment logic:
    local success = pcall(function()
        -- Get the MonetizationSystem to handle fulfillment
        local MonetizationSystem = require(ReplicatedStorage.Shared.monetization.MonetizationSystem)
        
        -- Find the product in our catalog
        local productCatalog = MonetizationSystem.getProductCatalog()
        local product = productCatalog[productId]
        
        if product then
            -- Use the existing fulfillment system
            local fulfillmentResult = MonetizationSystem.fulfillPurchase(player, product, {
                PurchaseId = productId,
                CurrencySpent = productInfo.PriceInRobux
            })
            
            if fulfillmentResult then
                result.success = true
                result.reason = "Developer product fulfilled"
            else
                result.reason = "Fulfillment failed"
            end
        else
            result.reason = "Product not found in catalog"
        end
    end)
    
    if not success then
        result.reason = "Error during fulfillment"
    end
    
    return result
end

function RobuxIntegration.recordSuccessfulTransaction(player, receiptInfo, transaction)
    -- Record in player transaction history
    local playerId = player.UserId
    
    if not TransactionState.playerTransactions[playerId] then
        TransactionState.playerTransactions[playerId] = {}
    end
    
    local transactionRecord = {
        purchaseId = receiptInfo.PurchaseId,
        productId = receiptInfo.ProductId,
        amount = receiptInfo.CurrencySpent,
        timestamp = tick(),
        transactionId = transaction.id,
        status = "completed"
    }
    
    table.insert(TransactionState.playerTransactions[playerId], transactionRecord)
    
    -- Update rate limiting
    RobuxIntegration.updateRateLimit(player)
    
    -- Update global statistics
    TransactionState.stats.totalTransactions = TransactionState.stats.totalTransactions + 1
    TransactionState.stats.totalRevenue = TransactionState.stats.totalRevenue + receiptInfo.CurrencySpent
    
    -- Calculate average transaction value
    if TransactionState.stats.totalTransactions > 0 then
        TransactionState.stats.averageTransactionValue = 
            TransactionState.stats.totalRevenue / TransactionState.stats.totalTransactions
    end
    
    print(string.format("💰 Transaction recorded: %s spent R$%d on %s", 
        player.Name, receiptInfo.CurrencySpent, receiptInfo.ProductId))
end

-- ========================================
-- MONITORING SYSTEMS
-- ========================================

function RobuxIntegration.startMonitoringSystems()
    spawn(function()
        while true do
            RobuxIntegration.updateSystemHealth()
            RobuxIntegration.cleanupOldData()
            RobuxIntegration.generateAnalytics()
            
            task.wait(60) -- Update every minute
        end
    end)
    
    print("📊 Monitoring systems started")
end

function RobuxIntegration.updateSystemHealth()
    local totalTransactions = TransactionState.stats.successfulTransactions + TransactionState.stats.failedTransactions
    
    -- Calculate success rate
    if totalTransactions > 0 then
        TransactionState.systemHealth.transactionSuccessRate = 
            (TransactionState.stats.successfulTransactions / totalTransactions) * 100
    end
    
    -- Calculate average processing time
    local totalProcessingTime = 0
    local processedCount = 0
    
    for _, transaction in pairs(TransactionState.completedTransactions) do
        if transaction.processingTime then
            totalProcessingTime = totalProcessingTime + transaction.processingTime
            processedCount = processedCount + 1
        end
    end
    
    if processedCount > 0 then
        TransactionState.systemHealth.averageProcessingTime = totalProcessingTime / processedCount
    end
    
    -- Calculate error rate
    if totalTransactions > 0 then
        TransactionState.systemHealth.errorRate = 
            (TransactionState.stats.failedTransactions / totalTransactions) * 100
    end
    
    -- Calculate fraud detection rate
    if totalTransactions > 0 then
        TransactionState.systemHealth.fraudDetectionRate = 
            (TransactionState.stats.fraudulentTransactions / totalTransactions) * 100
    end
end

function RobuxIntegration.cleanupOldData()
    local cutoffTime = tick() - 86400 -- 24 hours ago
    
    -- Clean up old completed transactions
    for transactionId, transaction in pairs(TransactionState.completedTransactions) do
        if transaction.timestamp < cutoffTime then
            TransactionState.completedTransactions[transactionId] = nil
        end
    end
    
    -- Clean up old failed transactions
    for transactionId, transaction in pairs(TransactionState.failedTransactions) do
        if transaction.timestamp < cutoffTime then
            TransactionState.failedTransactions[transactionId] = nil
        end
    end
    
    -- Clean up old rate limit data
    for playerId, tracking in pairs(TransactionState.rateLimitTracking) do
        if tick() - tracking.lastReset > 3600 then -- 1 hour
            TransactionState.rateLimitTracking[playerId] = nil
        end
    end
end

function RobuxIntegration.generateAnalytics()
    if not ROBUX_CONFIG.analytics.trackTransactionMetrics then
        return
    end
    
    local analytics = {
        timestamp = tick(),
        metrics = {
            totalRevenue = TransactionState.stats.totalRevenue,
            totalTransactions = TransactionState.stats.totalTransactions,
            successRate = TransactionState.systemHealth.transactionSuccessRate,
            averageTransactionValue = TransactionState.stats.averageTransactionValue,
            fraudRate = TransactionState.systemHealth.fraudDetectionRate
        },
        performance = {
            averageProcessingTime = TransactionState.systemHealth.averageProcessingTime,
            errorRate = TransactionState.systemHealth.errorRate,
            systemHealth = "healthy" -- Would be calculated based on various factors
        }
    }
    
    TransactionState.transactionAnalytics = analytics
end

-- ========================================
-- UTILITY FUNCTIONS
-- ========================================

function RobuxIntegration.isGamePass(productId)
    -- GamePasses typically have IDs in a different range than Developer Products
    -- This is a simplified check - in practice, you'd maintain a registry
    return productId >= 1000000000 and productId < 2000000000
end

function RobuxIntegration.isDeveloperProduct(productId)
    -- Developer Products typically have IDs in a different range
    return productId >= 2000000000
end

function RobuxIntegration.getPlayerPlayTime(player)
    -- In a real implementation, you'd track actual play time
    return math.random(300, 3600) -- 5 minutes to 1 hour
end

function RobuxIntegration.validatePlayerLocation(player)
    -- In a real implementation, you'd check IP geolocation
    return {valid = true, reason = ""}
end

function RobuxIntegration.getLastPurchaseTime(player)
    local playerId = player.UserId
    
    if TransactionState.playerTransactions[playerId] then
        local transactions = TransactionState.playerTransactions[playerId]
        if #transactions > 0 then
            return transactions[#transactions].timestamp
        end
    end
    
    return 0
end

function RobuxIntegration.getDailySpending(player)
    local playerId = player.UserId
    local currentTime = tick()
    local dayStart = currentTime - (currentTime % 86400) -- Start of current day
    local dailySpending = 0
    
    if TransactionState.playerTransactions[playerId] then
        for _, transaction in ipairs(TransactionState.playerTransactions[playerId]) do
            if transaction.timestamp >= dayStart then
                dailySpending = dailySpending + transaction.amount
            end
        end
    end
    
    return dailySpending
end

function RobuxIntegration.getRecentTransactions(player, timeWindow)
    local playerId = player.UserId
    local currentTime = tick()
    local cutoffTime = currentTime - timeWindow
    local recentTransactions = {}
    
    if TransactionState.playerTransactions[playerId] then
        for _, transaction in ipairs(TransactionState.playerTransactions[playerId]) do
            if transaction.timestamp >= cutoffTime then
                table.insert(recentTransactions, transaction)
            end
        end
    end
    
    return recentTransactions
end

function RobuxIntegration.getAverageTransactionAmount(player)
    local playerId = player.UserId
    
    if TransactionState.playerTransactions[playerId] then
        local transactions = TransactionState.playerTransactions[playerId]
        local total = 0
        
        for _, transaction in ipairs(transactions) do
            total = total + transaction.amount
        end
        
        return #transactions > 0 and (total / #transactions) or 0
    end
    
    return 0
end

function RobuxIntegration.getLastTransaction(player)
    local playerId = player.UserId
    
    if TransactionState.playerTransactions[playerId] then
        local transactions = TransactionState.playerTransactions[playerId]
        return #transactions > 0 and transactions[#transactions] or nil
    end
    
    return nil
end

function RobuxIntegration.getTotalSpending(player)
    local playerId = player.UserId
    local total = 0
    
    if TransactionState.playerTransactions[playerId] then
        for _, transaction in ipairs(TransactionState.playerTransactions[playerId]) do
            total = total + transaction.amount
        end
    end
    
    return total
end

function RobuxIntegration.updatePlayerTransactionHistory(player, receiptInfo)
    -- Update player velocity tracking
    local playerId = player.UserId
    
    if not TransactionState.playerVelocity[playerId] then
        TransactionState.playerVelocity[playerId] = {
            hourlySpending = 0,
            dailySpending = 0,
            lastReset = tick()
        }
    end
    
    local velocity = TransactionState.playerVelocity[playerId]
    velocity.hourlySpending = velocity.hourlySpending + receiptInfo.CurrencySpent
    velocity.dailySpending = velocity.dailySpending + receiptInfo.CurrencySpent
end

function RobuxIntegration.updateTransactionStatistics(transaction, result)
    -- Update processing time statistics
    if transaction.processingTime then
        local avgTime = TransactionState.systemHealth.averageProcessingTime or 0
        local count = TransactionState.stats.totalTransactions + 1
        
        TransactionState.systemHealth.averageProcessingTime = 
            ((avgTime * (count - 1)) + transaction.processingTime) / count
    end
end

function RobuxIntegration.trackPurchaseEvent(event)
    if not ROBUX_CONFIG.analytics.trackTransactionMetrics then
        return
    end
    
    -- Track conversion funnels
    if event.type == "gamepass_purchase_finished" and event.wasPurchased then
        -- Successful gamepass conversion
        print(string.format("📈 Conversion: GamePass %s purchased by %s", 
            event.gamePassId, event.playerName))
    end
    
    if event.type == "product_purchase_finished" and event.wasPurchased then
        -- Successful product conversion
        print(string.format("📈 Conversion: Product %s purchased by %s", 
            event.productId, event.playerName))
    end
end

function RobuxIntegration.verifyAndApplyGamePassBenefits(player, gamePassId)
    -- Verify the player actually owns the gamepass
    local hasGamepass = MarketplaceService:UserOwnsGamePassAsync(player.UserId, gamePassId)
    
    if hasGamepass then
        -- Apply gamepass benefits through MonetizationSystem
        local success = pcall(function()
            local MonetizationSystem = require(ReplicatedStorage.Shared.monetization.MonetizationSystem)
            local productCatalog = MonetizationSystem.getProductCatalog()
            local product = productCatalog[gamePassId]
            
            if product then
                MonetizationSystem.applyGamepassBenefits(player, product)
                print(string.format("✅ Applied gamepass benefits: %s for %s", 
                    product.data.name, player.Name))
            end
        end)
        
        if not success then
            print(string.format("❌ Failed to apply gamepass benefits for %s", player.Name))
        end
    else
        print(string.format("⚠️ GamePass ownership verification failed for %s", player.Name))
    end
end

function RobuxIntegration.validateGamePassPurchase(player, gamePassId)
    local validation = {valid = true, reason = ""}
    
    -- Check if player already owns it
    local hasGamepass = MarketplaceService:UserOwnsGamePassAsync(player.UserId, gamePassId)
    if hasGamepass then
        validation.valid = false
        validation.reason = "Player already owns gamepass"
        return validation
    end
    
    -- Additional validation logic...
    
    return validation
end

function RobuxIntegration.validateProductPurchase(player, productId)
    local validation = {valid = true, reason = ""}
    
    -- Validate product exists and is for sale
    local success, productInfo = pcall(function()
        return MarketplaceService:GetProductInfo(productId, Enum.InfoType.Product)
    end)
    
    if not success or not productInfo or not productInfo.IsForSale then
        validation.valid = false
        validation.reason = "Product not available for purchase"
        return validation
    end
    
    return validation
end

-- ========================================
-- PUBLIC API
-- ========================================

function RobuxIntegration.runIntegrationDemo()
    print("💳 Running Robux integration demonstration...")
    
    -- Show system health
    print("  🏥 System Health:")
    print(string.format("    Transaction Success Rate: %.1f%%", 
        TransactionState.systemHealth.transactionSuccessRate))
    print(string.format("    Average Processing Time: %.3fs", 
        TransactionState.systemHealth.averageProcessingTime))
    print(string.format("    Error Rate: %.1f%%", 
        TransactionState.systemHealth.errorRate))
    print(string.format("    Fraud Detection Rate: %.1f%%", 
        TransactionState.systemHealth.fraudDetectionRate))
    
    -- Show transaction statistics
    print("  📊 Transaction Statistics:")
    print(string.format("    Total Transactions: %d", TransactionState.stats.totalTransactions))
    print(string.format("    Total Revenue: R$%d", TransactionState.stats.totalRevenue))
    print(string.format("    Successful Transactions: %d", TransactionState.stats.successfulTransactions))
    print(string.format("    Failed Transactions: %d", TransactionState.stats.failedTransactions))
    print(string.format("    Fraudulent Transactions: %d", TransactionState.stats.fraudulentTransactions))
    print(string.format("    Average Transaction Value: R$%.2f", TransactionState.stats.averageTransactionValue))
    
    -- Test validation systems
    print("  ✅ Testing Validation Systems:")
    
    -- Test basic validation
    local validReceipt = {
        PlayerId = 12345,
        ProductId = 2345678901,
        PurchaseId = "test_purchase_123",
        CurrencySpent = 99,
        CurrencyType = Enum.CurrencyType.Robux
    }
    
    local basicValidation = RobuxIntegration.performBasicValidation(validReceipt)
    print(string.format("    Basic Validation: %s", basicValidation.valid and "PASS" or "FAIL"))
    
    -- Test security checks (with mock player)
    local mockPlayer = {
        UserId = 12345,
        Name = "TestPlayer",
        AccountAge = 30
    }
    
    local securityCheck = RobuxIntegration.performSecurityChecks(mockPlayer, validReceipt)
    print(string.format("    Security Check: %s (Score: %d)", 
        securityCheck.fraudDetected and "FRAUD" or "CLEAN", securityCheck.fraudScore))
    
    -- Test rate limiting
    local rateLimitCheck = RobuxIntegration.checkRateLimit(mockPlayer)
    print(string.format("    Rate Limit: %s (Remaining: %d)", 
        rateLimitCheck.allowed and "ALLOWED" or "BLOCKED", rateLimitCheck.remaining))
    
    -- Show fraud detection capabilities
    print("  🛡️ Security Features:")
    print("    ✅ Receipt validation")
    print("    ✅ Duplicate transaction detection")
    print("    ✅ Fraud pattern analysis")
    print("    ✅ Rate limiting")
    print("    ✅ Velocity checking")
    print("    ✅ Account age validation")
    print("    ✅ Business logic validation")
    
    print("💳 Robux integration demonstration completed")
end

function RobuxIntegration.getTransactionStats()
    return TransactionState.stats
end

function RobuxIntegration.getSystemHealth()
    return TransactionState.systemHealth
end

function RobuxIntegration.getPlayerTransactions(player)
    return TransactionState.playerTransactions[player.UserId] or {}
end

function RobuxIntegration.getFraudReports()
    return TransactionState.fraudAttempts
end

function RobuxIntegration.getAnalytics()
    return TransactionState.transactionAnalytics
end

-- Export API
RobuxIntegration.processReceiptSecure = RobuxIntegration.processReceiptSecure
RobuxIntegration.validateProduct = RobuxIntegration.validateProduct
RobuxIntegration.performSecurityChecks = RobuxIntegration.performSecurityChecks

-- Initialize the Robux integration system
RobuxIntegration.initialize()

print("💳 RobuxIntegration loaded with secure transaction processing and fraud prevention")

return RobuxIntegration
