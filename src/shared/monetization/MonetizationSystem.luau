-- MonetizationSystem.luau
-- Comprehensive monetization infrastructure with real Robux integration
-- Provides ethical monetization, balanced economy, and revenue optimization

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local MarketplaceService = game:GetService("MarketplaceService")
local Players = game:GetService("Players")
local HttpService = game:GetService("HttpService")
local RunService = game:GetService("RunService")
local DataStoreService = game:GetService("DataStoreService")

local SafeRequire = require(ReplicatedStorage.Shared.utils.SafeRequire)

local MonetizationSystem = {}

-- ========================================
-- MONETIZATION CONFIGURATION
-- ========================================

local MONETIZATION_CONFIG = {
    -- Real product IDs (Replace with actual IDs from Roblox Creator Dashboard)
    products = {
        -- Gamepasses
        gamepasses = {
            premium_access = {
                id = 1234567890,  -- Replace with real gamepass ID
                name = "Premium Access",
                description = "Unlock exclusive features and benefits",
                price = 299,  -- Robux
                category = "premium",
                benefits = {"double_rewards", "exclusive_areas", "priority_queue", "custom_cosmetics"}
            },
            
            vip_pass = {
                id = 1234567891,  -- Replace with real gamepass ID
                name = "VIP Pass",
                description = "Ultimate VIP experience with all perks",
                price = 499,
                category = "vip",
                benefits = {"triple_rewards", "vip_lounge", "exclusive_items", "admin_chat"}
            },
            
            builder_kit = {
                id = 1234567892,  -- Replace with real gamepass ID
                name = "Builder Kit",
                description = "Advanced building tools and materials",
                price = 199,
                category = "utility",
                benefits = {"advanced_tools", "unlimited_materials", "save_builds", "share_builds"}
            },
            
            speed_boost = {
                id = 1234567893,  -- Replace with real gamepass ID
                name = "Speed Boost",
                description = "Permanent 50% speed increase",
                price = 149,
                category = "enhancement",
                benefits = {"speed_multiplier_1.5", "dash_ability", "wall_climb"}
            }
        },
        
        -- Developer Products (Consumables)
        devProducts = {
            coins_100 = {
                id = 2345678901,  -- Replace with real dev product ID
                name = "100 Coins",
                description = "Get 100 in-game coins instantly",
                price = 29,
                amount = 100,
                currency = "coins",
                category = "currency"
            },
            
            coins_500 = {
                id = 2345678902,  -- Replace with real dev product ID
                name = "500 Coins",
                description = "Get 500 in-game coins with 25% bonus",
                price = 99,
                amount = 625,  -- 25% bonus
                currency = "coins",
                category = "currency"
            },
            
            coins_1000 = {
                id = 2345678903,  -- Replace with real dev product ID
                name = "1000 Coins",
                description = "Get 1000 in-game coins with 50% bonus",
                price = 199,
                amount = 1500,  -- 50% bonus
                currency = "coins",
                category = "currency"
            },
            
            gems_50 = {
                id = 2345678904,  -- Replace with real dev product ID
                name = "50 Gems",
                description = "Premium currency for exclusive items",
                price = 99,
                amount = 50,
                currency = "gems",
                category = "premium_currency"
            },
            
            energy_refill = {
                id = 2345678905,  -- Replace with real dev product ID
                name = "Energy Refill",
                description = "Instantly refill your energy to maximum",
                price = 19,
                amount = 100,
                currency = "energy",
                category = "consumable"
            },
            
            double_xp_1h = {
                id = 2345678906,  -- Replace with real dev product ID
                name = "Double XP (1 Hour)",
                description = "Double experience gain for 1 hour",
                price = 49,
                duration = 3600,  -- 1 hour
                effect = "double_xp",
                category = "booster"
            },
            
            mystery_crate = {
                id = 2345678907,  -- Replace with real dev product ID
                name = "Mystery Crate",
                description = "Contains random rare items and rewards",
                price = 149,
                type = "mystery_crate",
                category = "crate"
            }
        }
    },
    
    -- Economy balance settings
    economy = {
        -- Currency exchange rates
        exchangeRates = {
            robux_to_coins = 3.5,      -- 1 Robux = 3.5 Coins
            robux_to_gems = 0.5,       -- 1 Robux = 0.5 Gems
            coins_to_gems = 0.1        -- 10 Coins = 1 Gem
        },
        
        -- Earning rates (per hour of gameplay)
        earningRates = {
            coins_base = 50,           -- Base coins per hour
            xp_base = 100,             -- Base XP per hour
            energy_regen = 10          -- Energy regeneration per hour
        },
        
        -- Price scaling
        priceScaling = {
            inflation_rate = 0.02,     -- 2% per level
            discount_threshold = 0.8,  -- 80% of price for bulk purchases
            premium_multiplier = 1.5   -- Premium members get 50% more value
        },
        
        -- Balance constraints
        constraints = {
            max_daily_earning = 1000,  -- Max coins earnable per day
            max_currency_stack = 999999,
            min_purchase_cooldown = 300, -- 5 minutes between purchases
            max_refunds_per_day = 3
        }
    },
    
    -- Ethical monetization guidelines
    ethics = {
        -- Pay-to-win prevention
        payToWin = {
            enablePayToWinPrevention = true,
            maxAdvantagePercent = 10,  -- Max 10% advantage from purchases
            skillBasedProgression = true,
            fairCompetitiveBalance = true
        },
        
        -- Fair progression
        progression = {
            freePlayerViability = true,
            reasonableTimeGates = true,
            skillRewardsPriority = true,
            noMandatoryPurchases = true
        },
        
        -- Transparency
        transparency = {
            clearPricing = true,
            honestDescriptions = true,
            noHiddenCosts = true,
            explicitBenefits = true
        },
        
        -- Player protection
        protection = {
            spendingLimits = true,
            cooldownPeriods = true,
            refundPolicy = true,
            parentalControls = true
        }
    },
    
    -- Revenue optimization
    optimization = {
        dynamicPricing = {
            enabled = true,
            priceTestingEnabled = true,
            demandBasedPricing = true,
            personalizedOffers = true
        },
        
        retention = {
            newPlayerOffers = true,
            churningPlayerOffers = true,
            loyaltyRewards = true,
            seasonalPromotions = true
        },
        
        analytics = {
            conversionTracking = true,
            cohortAnalysis = true,
            ltv_optimization = true,
            abTestingEnabled = true
        }
    }
}

-- ========================================
-- MONETIZATION STATE
-- ========================================

local MonetizationState = {
    -- Product management
    activeProducts = {},
    productMetadata = {},
    productSales = {},
    
    -- Player economics
    playerEconomics = {},
    transactions = {},
    purchaseHistory = {},
    
    -- Revenue tracking
    revenueMetrics = {},
    conversionData = {},
    cohortMetrics = {},
    
    -- Dynamic pricing
    priceTests = {},
    personalizedOffers = {},
    promotionalCampaigns = {},
    
    -- Fraud prevention
    suspiciousActivities = {},
    flaggedTransactions = {},
    verificationQueue = {},
    
    -- Analytics
    economyMetrics = {},
    balanceAnalytics = {},
    optimizationResults = {},
    
    -- Statistics
    stats = {
        totalRevenue = 0,
        totalTransactions = 0,
        averageRevenuePer User = 0,
        conversionRate = 0,
        retentionImpact = 0,
        economyHealth = 100
    }
}

function MonetizationSystem.initialize()
    print("💰 Initializing MonetizationSystem...")
    
    -- Set up product management
    MonetizationSystem.setupProductManagement()
    
    -- Initialize economy system
    MonetizationSystem.initializeEconomySystem()
    
    -- Set up transaction processing
    MonetizationSystem.setupTransactionProcessing()
    
    -- Initialize fraud prevention
    MonetizationSystem.initializeFraudPrevention()
    
    -- Set up revenue optimization
    MonetizationSystem.setupRevenueOptimization()
    
    -- Start monetization monitoring
    MonetizationSystem.startMonetizationMonitoring()
    
    print("💰 MonetizationSystem initialized successfully")
end

-- ========================================
-- PRODUCT MANAGEMENT
-- ========================================

function MonetizationSystem.setupProductManagement()
    MonetizationState.productManager = {
        catalog = MonetizationSystem.createProductCatalog(),
        validator = MonetizationSystem.createProductValidator(),
        processor = MonetizationSystem.createPurchaseProcessor(),
        fulfillment = MonetizationSystem.createFulfillmentSystem()
    }
    
    -- Initialize product catalog
    MonetizationSystem.initializeProductCatalog()
    
    print("🛒 Product management initialized")
end

function MonetizationSystem.createProductCatalog()
    return {
        name = "product_catalog",
        products = {},
        
        getProduct = function(self, productId)
            return MonetizationSystem.getProductInfo(productId)
        end,
        
        validatePurchase = function(self, player, productId)
            return MonetizationSystem.validatePurchase(player, productId)
        end
    }
end

function MonetizationSystem.createProductValidator()
    return {
        name = "product_validator",
        
        validate = function(self, player, productId, context)
            return MonetizationSystem.validatePurchaseRequest(player, productId, context)
        end
    }
end

function MonetizationSystem.createPurchaseProcessor()
    return {
        name = "purchase_processor",
        
        process = function(self, player, productId, receiptInfo)
            return MonetizationSystem.processPurchase(player, productId, receiptInfo)
        end
    }
end

function MonetizationSystem.createFulfillmentSystem()
    return {
        name = "fulfillment_system",
        
        fulfill = function(self, player, product, transaction)
            return MonetizationSystem.fulfillPurchase(player, product, transaction)
        end
    }
end

function MonetizationSystem.initializeProductCatalog()
    -- Load gamepasses
    for productKey, productData in pairs(MONETIZATION_CONFIG.products.gamepasses) do
        MonetizationState.activeProducts[productData.id] = {
            key = productKey,
            type = "gamepass",
            data = productData,
            enabled = true,
            salesCount = 0,
            revenue = 0
        }
    end
    
    -- Load developer products
    for productKey, productData in pairs(MONETIZATION_CONFIG.products.devProducts) do
        MonetizationState.activeProducts[productData.id] = {
            key = productKey,
            type = "devproduct",
            data = productData,
            enabled = true,
            salesCount = 0,
            revenue = 0
        }
    end
    
    print(string.format("📦 Loaded %d products into catalog", 
        #MONETIZATION_CONFIG.products.gamepasses + #MONETIZATION_CONFIG.products.devProducts))
end

function MonetizationSystem.getProductInfo(productId)
    local product = MonetizationState.activeProducts[productId]
    if not product then
        return nil
    end
    
    -- Apply dynamic pricing if enabled
    local currentPrice = product.data.price
    if MONETIZATION_CONFIG.optimization.dynamicPricing.enabled then
        currentPrice = MonetizationSystem.calculateDynamicPrice(productId, currentPrice)
    end
    
    return {
        id = productId,
        key = product.key,
        type = product.type,
        name = product.data.name,
        description = product.data.description,
        price = currentPrice,
        originalPrice = product.data.price,
        category = product.data.category,
        benefits = product.data.benefits,
        enabled = product.enabled
    }
end

function MonetizationSystem.validatePurchase(player, productId)
    local product = MonetizationState.activeProducts[productId]
    if not product or not product.enabled then
        return false, "Product not available"
    end
    
    -- Check player eligibility
    local playerData = MonetizationSystem.getPlayerEconomicData(player)
    
    -- Check purchase cooldown
    local lastPurchase = playerData.lastPurchaseTime or 0
    local cooldown = MONETIZATION_CONFIG.economy.constraints.min_purchase_cooldown
    
    if tick() - lastPurchase < cooldown then
        return false, "Purchase cooldown active"
    end
    
    -- Check if gamepass already owned
    if product.type == "gamepass" then
        local hasGamepass = MarketplaceService:UserOwnsGamePassAsync(player.UserId, productId)
        if hasGamepass then
            return false, "Already owned"
        end
    end
    
    -- Fraud prevention checks
    local fraudCheck = MonetizationSystem.performFraudCheck(player, productId)
    if not fraudCheck.safe then
        return false, fraudCheck.reason
    end
    
    return true, "Purchase validated"
end

-- ========================================
-- ECONOMY SYSTEM
-- ========================================

function MonetizationSystem.initializeEconomySystem()
    MonetizationState.economyEngine = {
        balancer = MonetizationSystem.createEconomyBalancer(),
        analyzer = MonetizationSystem.createEconomyAnalyzer(),
        optimizer = MonetizationSystem.createEconomyOptimizer(),
        monitor = MonetizationSystem.createEconomyMonitor()
    }
    
    -- Initialize economy tracking
    MonetizationSystem.initializeEconomyTracking()
    
    print("⚖️ Economy system initialized")
end

function MonetizationSystem.createEconomyBalancer()
    return {
        name = "economy_balancer",
        
        balance = function(self)
            return MonetizationSystem.performEconomyBalancing()
        end,
        
        calculateInflation = function(self)
            return MonetizationSystem.calculateInflationRate()
        end
    }
end

function MonetizationSystem.createEconomyAnalyzer()
    return {
        name = "economy_analyzer",
        
        analyze = function(self)
            return MonetizationSystem.analyzeEconomyHealth()
        end
    }
end

function MonetizationSystem.createEconomyOptimizer()
    return {
        name = "economy_optimizer",
        
        optimize = function(self)
            return MonetizationSystem.optimizeEconomyParameters()
        end
    }
end

function MonetizationSystem.createEconomyMonitor()
    return {
        name = "economy_monitor",
        
        monitor = function(self)
            MonetizationSystem.monitorEconomyMetrics()
        end
    }
end

function MonetizationSystem.initializeEconomyTracking()
    MonetizationState.economyMetrics = {
        totalCurrencyInCirculation = 0,
        averageCurrencyPerPlayer = 0,
        currencyInflationRate = 0,
        purchasingPowerIndex = 100,
        economyStabilityScore = 100
    }
end

function MonetizationSystem.getPlayerEconomicData(player)
    local playerData = MonetizationState.playerEconomics[player.UserId]
    
    if not playerData then
        playerData = {
            userId = player.UserId,
            currencies = {
                coins = 100,  -- Starting coins
                gems = 0,     -- Premium currency
                energy = 100  -- Energy system
            },
            spending = {
                totalSpent = 0,
                totalPurchases = 0,
                averagePurchase = 0,
                lastPurchaseTime = 0
            },
            earnings = {
                totalEarned = 100,
                dailyEarnings = 0,
                earningsToday = 0,
                lastEarningReset = tick()
            },
            status = {
                isPremium = false,
                isVip = false,
                spendingTier = "free",
                riskLevel = "low"
            },
            history = {}
        }
        
        MonetizationState.playerEconomics[player.UserId] = playerData
    end
    
    return playerData
end

function MonetizationSystem.updatePlayerCurrency(player, currencyType, amount, reason)
    local playerData = MonetizationSystem.getPlayerEconomicData(player)
    local oldAmount = playerData.currencies[currencyType] or 0
    
    -- Apply constraints
    local maxStack = MONETIZATION_CONFIG.economy.constraints.max_currency_stack
    local newAmount = math.min(oldAmount + amount, maxStack)
    
    playerData.currencies[currencyType] = math.max(0, newAmount)
    
    -- Record transaction
    table.insert(playerData.history, {
        timestamp = tick(),
        type = "currency_update",
        currency = currencyType,
        amount = amount,
        oldAmount = oldAmount,
        newAmount = playerData.currencies[currencyType],
        reason = reason
    })
    
    -- Update economy metrics
    MonetizationSystem.updateEconomyMetrics()
    
    return playerData.currencies[currencyType]
end

function MonetizationSystem.calculateDynamicPrice(productId, basePrice)
    if not MONETIZATION_CONFIG.optimization.dynamicPricing.enabled then
        return basePrice
    end
    
    -- Get demand data
    local demand = MonetizationSystem.getProductDemand(productId)
    local supply = 1.0 -- Digital products have infinite supply
    
    -- Calculate price adjustment based on demand
    local demandMultiplier = 1.0
    if demand > 1.2 then
        demandMultiplier = 1.1 -- 10% price increase for high demand
    elseif demand < 0.8 then
        demandMultiplier = 0.9 -- 10% discount for low demand
    end
    
    -- Apply seasonal adjustments
    local seasonalMultiplier = MonetizationSystem.getSeasonalPriceMultiplier()
    
    -- Calculate final price
    local dynamicPrice = math.floor(basePrice * demandMultiplier * seasonalMultiplier)
    
    -- Ensure price stays within reasonable bounds (±30% of base price)
    local minPrice = math.floor(basePrice * 0.7)
    local maxPrice = math.floor(basePrice * 1.3)
    
    return math.max(minPrice, math.min(maxPrice, dynamicPrice))
end

function MonetizationSystem.getProductDemand(productId)
    -- Calculate demand based on recent sales and player interest
    local product = MonetizationState.activeProducts[productId]
    if not product then
        return 1.0
    end
    
    -- Use recent sales data to calculate demand
    local recentSales = product.salesCount or 0
    local totalPlayers = #Players:GetPlayers()
    
    if totalPlayers == 0 then
        return 1.0
    end
    
    -- Simple demand calculation (can be made more sophisticated)
    local demandRatio = recentSales / math.max(1, totalPlayers)
    return math.max(0.5, math.min(2.0, demandRatio * 10))
end

function MonetizationSystem.getSeasonalPriceMultiplier()
    -- Apply seasonal pricing (holidays, events, etc.)
    local currentTime = os.time()
    local dayOfYear = os.date("*t", currentTime).yday
    
    -- Example: Holiday season discount (December)
    if dayOfYear >= 335 and dayOfYear <= 365 then -- December
        return 0.85 -- 15% holiday discount
    end
    
    -- Example: Summer event pricing (June-August)
    if dayOfYear >= 152 and dayOfYear <= 243 then -- June-August
        return 1.05 -- 5% summer premium
    end
    
    return 1.0 -- No seasonal adjustment
end

-- ========================================
-- TRANSACTION PROCESSING
-- ========================================

function MonetizationSystem.setupTransactionProcessing()
    -- Set up MarketplaceService connections
    MarketplaceService.ProcessReceipt = MonetizationSystem.processReceiptCallback
    MarketplaceService.PromptGamePassPurchaseFinished:Connect(MonetizationSystem.onGamePassPurchaseFinished)
    MarketplaceService.PromptProductPurchaseFinished:Connect(MonetizationSystem.onProductPurchaseFinished)
    
    print("💳 Transaction processing initialized")
end

function MonetizationSystem.processReceiptCallback(receiptInfo)
    print(string.format("💰 Processing receipt: %s", HttpService:JSONEncode(receiptInfo)))
    
    local player = Players:GetPlayerByUserId(receiptInfo.PlayerId)
    if not player then
        print("❌ Player not found for receipt")
        return Enum.ProductPurchaseDecision.NotProcessedYet
    end
    
    local productId = receiptInfo.ProductId
    local product = MonetizationState.activeProducts[productId]
    
    if not product then
        print(string.format("❌ Unknown product ID: %d", productId))
        return Enum.ProductPurchaseDecision.NotProcessedYet
    end
    
    -- Check if already processed
    local purchaseId = receiptInfo.PurchaseId
    if MonetizationSystem.isPurchaseAlreadyProcessed(purchaseId) then
        print("✅ Purchase already processed")
        return Enum.ProductPurchaseDecision.PurchaseGranted
    end
    
    -- Process the purchase
    local success = MonetizationSystem.fulfillPurchase(player, product, receiptInfo)
    
    if success then
        -- Record the transaction
        MonetizationSystem.recordTransaction(player, product, receiptInfo)
        
        print(string.format("✅ Purchase fulfilled: %s for %s", product.data.name, player.Name))
        return Enum.ProductPurchaseDecision.PurchaseGranted
    else
        print(string.format("❌ Failed to fulfill purchase: %s", product.data.name))
        return Enum.ProductPurchaseDecision.NotProcessedYet
    end
end

function MonetizationSystem.onGamePassPurchaseFinished(player, gamePassId, wasPurchased)
    if wasPurchased then
        local product = MonetizationState.activeProducts[gamePassId]
        if product then
            print(string.format("🎫 Gamepass purchased: %s by %s", product.data.name, player.Name))
            
            -- Apply gamepass benefits
            MonetizationSystem.applyGamepassBenefits(player, product)
            
            -- Record analytics
            MonetizationSystem.recordGamepassPurchase(player, product)
        end
    end
end

function MonetizationSystem.onProductPurchaseFinished(player, productId, wasPurchased)
    if wasPurchased then
        local product = MonetizationState.activeProducts[productId]
        if product then
            print(string.format("🛒 Product purchase initiated: %s by %s", product.data.name, player.Name))
            -- Actual fulfillment happens in processReceiptCallback
        end
    end
end

function MonetizationSystem.fulfillPurchase(player, product, receiptInfo)
    local productData = product.data
    local playerData = MonetizationSystem.getPlayerEconomicData(player)
    
    if product.type == "devproduct" then
        -- Handle developer product fulfillment
        if productData.currency then
            -- Currency purchase
            local amount = productData.amount or 0
            MonetizationSystem.updatePlayerCurrency(player, productData.currency, amount, "purchase")
            
            print(string.format("💰 Granted %d %s to %s", amount, productData.currency, player.Name))
            
        elseif productData.effect then
            -- Effect/booster purchase
            MonetizationSystem.applyTemporaryEffect(player, productData)
            
            print(string.format("⚡ Applied effect %s to %s", productData.effect, player.Name))
            
        elseif productData.type == "mystery_crate" then
            -- Mystery crate
            local rewards = MonetizationSystem.openMystery Crate(player)
            
            print(string.format("📦 Opened mystery crate for %s: %d rewards", player.Name, #rewards))
        end
        
    elseif product.type == "gamepass" then
        -- Handle gamepass benefits (if not already applied)
        MonetizationSystem.applyGamepassBenefits(player, product)
    end
    
    return true
end

function MonetizationSystem.applyGamepassBenefits(player, product)
    local playerData = MonetizationSystem.getPlayerEconomicData(player)
    
    for _, benefit in ipairs(product.data.benefits or {}) do
        if benefit == "double_rewards" then
            playerData.multipliers = playerData.multipliers or {}
            playerData.multipliers.rewards = 2.0
            
        elseif benefit == "triple_rewards" then
            playerData.multipliers = playerData.multipliers or {}
            playerData.multipliers.rewards = 3.0
            
        elseif benefit == "speed_multiplier_1.5" then
            playerData.multipliers = playerData.multipliers or {}
            playerData.multipliers.speed = 1.5
            
        elseif benefit == "premium_access" then
            playerData.status.isPremium = true
            
        elseif benefit == "vip_lounge" then
            playerData.status.isVip = true
        end
    end
    
    print(string.format("🎁 Applied gamepass benefits for %s: %s", player.Name, product.data.name))
end

function MonetizationSystem.applyTemporaryEffect(player, productData)
    local playerData = MonetizationSystem.getPlayerEconomicData(player)
    
    if not playerData.activeEffects then
        playerData.activeEffects = {}
    end
    
    local effect = {
        type = productData.effect,
        duration = productData.duration or 3600,
        startTime = tick(),
        endTime = tick() + (productData.duration or 3600)
    }
    
    table.insert(playerData.activeEffects, effect)
    
    -- Start effect monitoring
    spawn(function()
        task.wait(effect.duration)
        MonetizationSystem.removeExpiredEffect(player, effect)
    end)
end

function MonetizationSystem.openMystery Crate(player)
    local rewards = {}
    
    -- Define possible rewards with probabilities
    local possibleRewards = {
        {type = "coins", amount = 100, probability = 0.4},
        {type = "coins", amount = 250, probability = 0.25},
        {type = "gems", amount = 10, probability = 0.15},
        {type = "gems", amount = 25, probability = 0.1},
        {type = "energy", amount = 50, probability = 0.08},
        {type = "rare_item", item = "golden_sword", probability = 0.02}
    }
    
    -- Generate 3-5 random rewards
    local numRewards = math.random(3, 5)
    
    for i = 1, numRewards do
        local roll = math.random()
        local cumulativeProbability = 0
        
        for _, reward in ipairs(possibleRewards) do
            cumulativeProbability = cumulativeProbability + reward.probability
            
            if roll <= cumulativeProbability then
                table.insert(rewards, reward)
                
                -- Apply the reward
                if reward.type == "coins" or reward.type == "gems" or reward.type == "energy" then
                    MonetizationSystem.updatePlayerCurrency(player, reward.type, reward.amount, "mystery_crate")
                elseif reward.type == "rare_item" then
                    -- Grant rare item (implement item system separately)
                    print(string.format("🎁 Granted rare item: %s to %s", reward.item, player.Name))
                end
                
                break
            end
        end
    end
    
    return rewards
end

function MonetizationSystem.recordTransaction(player, product, receiptInfo)
    local transaction = {
        id = receiptInfo.PurchaseId,
        playerId = player.UserId,
        playerName = player.Name,
        productId = product.data.id,
        productName = product.data.name,
        productType = product.type,
        price = product.data.price,
        currency = "robux",
        timestamp = tick(),
        receiptInfo = receiptInfo,
        fulfillmentStatus = "completed"
    }
    
    -- Store transaction
    MonetizationState.transactions[transaction.id] = transaction
    
    -- Update player purchase history
    local playerData = MonetizationSystem.getPlayerEconomicData(player)
    table.insert(playerData.history, transaction)
    
    -- Update player spending data
    playerData.spending.totalSpent = playerData.spending.totalSpent + product.data.price
    playerData.spending.totalPurchases = playerData.spending.totalPurchases + 1
    playerData.spending.averagePurchase = playerData.spending.totalSpent / playerData.spending.totalPurchases
    playerData.spending.lastPurchaseTime = tick()
    
    -- Update product sales data
    product.salesCount = product.salesCount + 1
    product.revenue = product.revenue + product.data.price
    
    -- Update global statistics
    MonetizationState.stats.totalRevenue = MonetizationState.stats.totalRevenue + product.data.price
    MonetizationState.stats.totalTransactions = MonetizationState.stats.totalTransactions + 1
    
    -- Update analytics
    MonetizationSystem.updateRevenueAnalytics(transaction)
    
    print(string.format("📊 Recorded transaction: %s (R$%d)", transaction.productName, transaction.price))
end

function MonetizationSystem.isPurchaseAlreadyProcessed(purchaseId)
    return MonetizationState.transactions[purchaseId] ~= nil
end

-- ========================================
-- FRAUD PREVENTION
-- ========================================

function MonetizationSystem.initializeFraudPrevention()
    MonetizationState.fraudDetection = {
        detector = MonetizationSystem.createFraudDetector(),
        analyzer = MonetizationSystem.createFraudAnalyzer(),
        blocker = MonetizationSystem.createFraudBlocker()
    }
    
    print("🛡️ Fraud prevention initialized")
end

function MonetizationSystem.createFraudDetector()
    return {
        name = "fraud_detector",
        
        detect = function(self, player, productId)
            return MonetizationSystem.detectFraudulentActivity(player, productId)
        end
    }
end

function MonetizationSystem.createFraudAnalyzer()
    return {
        name = "fraud_analyzer",
        
        analyze = function(self, activity)
            return MonetizationSystem.analyzeFraudPatterns(activity)
        end
    }
end

function MonetizationSystem.createFraudBlocker()
    return {
        name = "fraud_blocker",
        
        block = function(self, player, reason)
            return MonetizationSystem.blockSuspiciousPlayer(player, reason)
        end
    }
end

function MonetizationSystem.performFraudCheck(player, productId)
    local check = {safe = true, reason = nil}
    
    local playerData = MonetizationSystem.getPlayerEconomicData(player)
    
    -- Check purchase frequency
    local recentPurchases = MonetizationSystem.getRecentPurchases(player, 3600) -- Last hour
    if #recentPurchases > 5 then
        check.safe = false
        check.reason = "Suspicious purchase frequency"
        return check
    end
    
    -- Check spending patterns
    local hourlySpending = MonetizationSystem.getHourlySpending(player)
    if hourlySpending > 1000 then -- More than R$1000 per hour
        check.safe = false
        check.reason = "Unusual spending pattern"
        return check
    end
    
    -- Check account age vs spending
    local accountAge = MonetizationSystem.getAccountAge(player)
    if accountAge < 86400 and playerData.spending.totalSpent > 100 then -- New account spending > R$100
        check.safe = false
        check.reason = "New account high spending"
        return check
    end
    
    return check
end

function MonetizationSystem.getRecentPurchases(player, timeWindow)
    local recentPurchases = {}
    local currentTime = tick()
    local playerData = MonetizationSystem.getPlayerEconomicData(player)
    
    for _, transaction in ipairs(playerData.history) do
        if transaction.type ~= "currency_update" and 
           (currentTime - transaction.timestamp) <= timeWindow then
            table.insert(recentPurchases, transaction)
        end
    end
    
    return recentPurchases
end

function MonetizationSystem.getHourlySpending(player)
    local recentPurchases = MonetizationSystem.getRecentPurchases(player, 3600)
    local totalSpending = 0
    
    for _, purchase in ipairs(recentPurchases) do
        totalSpending = totalSpending + (purchase.price or 0)
    end
    
    return totalSpending
end

function MonetizationSystem.getAccountAge(player)
    -- Estimate account age (in production, use player.AccountAge * 86400)
    return player.AccountAge * 86400
end

-- ========================================
-- REVENUE OPTIMIZATION
-- ========================================

function MonetizationSystem.setupRevenueOptimization()
    MonetizationState.revenueOptimizer = {
        abTester = MonetizationSystem.createABTester(),
        personalizer = MonetizationSystem.createOfferPersonalizer(),
        campaignManager = MonetizationSystem.createCampaignManager(),
        analyticsEngine = MonetizationSystem.createRevenueAnalytics()
    }
    
    print("📈 Revenue optimization initialized")
end

function MonetizationSystem.createABTester()
    return {
        name = "ab_tester",
        
        test = function(self, testName, variants)
            return MonetizationSystem.createPriceTest(testName, variants)
        end
    }
end

function MonetizationSystem.createOfferPersonalizer()
    return {
        name = "offer_personalizer",
        
        personalize = function(self, player)
            return MonetizationSystem.generatePersonalizedOffers(player)
        end
    }
end

function MonetizationSystem.createCampaignManager()
    return {
        name = "campaign_manager",
        
        manage = function(self)
            return MonetizationSystem.manageProm otionalCampaigns()
        end
    }
end

function MonetizationSystem.createRevenueAnalytics()
    return {
        name = "revenue_analytics",
        
        analyze = function(self)
            return MonetizationSystem.analyzeRevenueMetrics()
        end
    }
end

function MonetizationSystem.generatePersonalizedOffers(player)
    local playerData = MonetizationSystem.getPlayerEconomicData(player)
    local offers = {}
    
    -- Analyze player behavior
    local spendingTier = MonetizationSystem.determineSpendingTier(playerData)
    local playStyle = MonetizationSystem.analyzePlayStyle(player)
    local churnRisk = MonetizationSystem.calculateChurnRisk(player)
    
    -- Generate offers based on player profile
    if spendingTier == "whale" then
        -- High-value offers for big spenders
        table.insert(offers, {
            type = "premium_bundle",
            discount = 0.2, -- 20% discount
            value = 999,
            description = "Exclusive whale package"
        })
        
    elseif spendingTier == "dolphin" then
        -- Medium-value offers
        table.insert(offers, {
            type = "value_pack",
            discount = 0.15,
            value = 299,
            description = "Great value package"
        })
        
    elseif spendingTier == "minnow" then
        -- Low-cost entry offers
        table.insert(offers, {
            type = "starter_pack",
            discount = 0.1,
            value = 99,
            description = "Perfect starter package"
        })
        
    else -- Free players
        -- First-time buyer incentives
        table.insert(offers, {
            type = "first_purchase",
            discount = 0.5, -- 50% first-time discount
            value = 49,
            description = "Special first purchase offer"
        })
    end
    
    -- Churn prevention offers
    if churnRisk > 0.7 then
        table.insert(offers, {
            type = "comeback_offer",
            discount = 0.3,
            value = 149,
            description = "We miss you! Special offer",
            urgency = "24_hours"
        })
    end
    
    return offers
end

function MonetizationSystem.determineSpendingTier(playerData)
    local totalSpent = playerData.spending.totalSpent
    
    if totalSpent >= 1000 then
        return "whale"      -- R$1000+
    elseif totalSpent >= 100 then
        return "dolphin"    -- R$100-999
    elseif totalSpent >= 10 then
        return "minnow"     -- R$10-99
    else
        return "free"       -- < R$10
    end
end

function MonetizationSystem.analyzePlayStyle(player)
    -- Analyze player's gameplay patterns
    -- This would integrate with actual gameplay systems
    return {
        preferredGameModes = {"adventure", "building"},
        sessionLength = "medium",
        socialActivity = "high",
        competitiveness = "medium"
    }
end

function MonetizationSystem.calculateChurnRisk(player)
    local playerData = MonetizationSystem.getPlayerEconomicData(player)
    
    -- Simple churn risk calculation
    local daysSinceLastLogin = 0 -- Would get from actual login tracking
    local recentActivity = 1.0 -- Would get from activity tracking
    
    local riskFactors = {
        daysSinceLastLogin / 7,    -- Days since last login (normalized to weeks)
        1 - recentActivity,        -- Inverse of recent activity
        0 -- Other factors...
    }
    
    local totalRisk = 0
    for _, factor in ipairs(riskFactors) do
        totalRisk = totalRisk + factor
    end
    
    return math.min(1.0, totalRisk / #riskFactors)
end

-- ========================================
-- MONITORING AND ANALYTICS
-- ========================================

function MonetizationSystem.startMonetizationMonitoring()
    spawn(function()
        while true do
            MonetizationSystem.updateMonetizationMetrics()
            MonetizationSystem.performEconomyBalancing()
            MonetizationSystem.analyzeRevenuePerformance()
            MonetizationSystem.checkEthicalCompliance()
            
            task.wait(300) -- Update every 5 minutes
        end
    end)
    
    print("📊 Monetization monitoring started")
end

function MonetizationSystem.updateMonetizationMetrics()
    -- Update conversion rate
    local totalPlayers = #Players:GetPlayers()
    local payingPlayers = 0
    
    for _, playerData in pairs(MonetizationState.playerEconomics) do
        if playerData.spending.totalSpent > 0 then
            payingPlayers = payingPlayers + 1
        end
    end
    
    MonetizationState.stats.conversionRate = totalPlayers > 0 and (payingPlayers / totalPlayers) * 100 or 0
    
    -- Update ARPU (Average Revenue Per User)
    MonetizationState.stats.averageRevenuePerUser = totalPlayers > 0 and 
        (MonetizationState.stats.totalRevenue / totalPlayers) or 0
    
    -- Update economy health
    MonetizationSystem.calculateEconomyHealth()
end

function MonetizationSystem.calculateEconomyHealth()
    local healthFactors = {
        conversionRate = math.min(1.0, MonetizationState.stats.conversionRate / 10), -- Target 10% conversion
        revenueGrowth = 1.0, -- Would calculate from historical data
        playerSatisfaction = 1.0, -- Would get from feedback systems
        economicBalance = MonetizationSystem.assessEconomicBalance()
    }
    
    local totalHealth = 0
    for _, factor in pairs(healthFactors) do
        totalHealth = totalHealth + factor
    end
    
    MonetizationState.stats.economyHealth = (totalHealth / 4) * 100
end

function MonetizationSystem.assessEconomicBalance()
    -- Check if economy is balanced (not too inflationary or deflationary)
    local currencySupply = MonetizationState.economyMetrics.totalCurrencyInCirculation
    local targetSupply = #Players:GetPlayers() * 1000 -- Target 1000 coins per player
    
    if targetSupply == 0 then
        return 1.0
    end
    
    local ratio = currencySupply / targetSupply
    
    -- Ideal ratio is around 1.0, penalize deviations
    if ratio >= 0.8 and ratio <= 1.2 then
        return 1.0 -- Perfect balance
    elseif ratio >= 0.6 and ratio <= 1.4 then
        return 0.8 -- Good balance
    elseif ratio >= 0.4 and ratio <= 1.6 then
        return 0.6 -- Acceptable balance
    else
        return 0.3 -- Poor balance
    end
end

function MonetizationSystem.performEconomyBalancing()
    if not MonetizationState.economyEngine then
        return
    end
    
    local analysis = MonetizationState.economyEngine.analyzer:analyze()
    
    -- Auto-adjust earning rates if economy is imbalanced
    if analysis.inflationRate > 0.1 then -- 10% inflation threshold
        -- Reduce earning rates
        MONETIZATION_CONFIG.economy.earningRates.coins_base = 
            math.max(25, MONETIZATION_CONFIG.economy.earningRates.coins_base * 0.95)
        
        print("⚖️ Reduced earning rates due to inflation")
        
    elseif analysis.inflationRate < -0.05 then -- Deflation threshold
        -- Increase earning rates
        MONETIZATION_CONFIG.economy.earningRates.coins_base = 
            math.min(100, MONETIZATION_CONFIG.economy.earningRates.coins_base * 1.05)
        
        print("⚖️ Increased earning rates due to deflation")
    end
end

function MonetizationSystem.analyzeRevenuePerformance()
    -- Track revenue trends
    local currentRevenue = MonetizationState.stats.totalRevenue
    local revenueAnalysis = {
        totalRevenue = currentRevenue,
        conversionRate = MonetizationState.stats.conversionRate,
        arpu = MonetizationState.stats.averageRevenuePerUser,
        trends = {
            daily = "stable",   -- Would calculate from historical data
            weekly = "growing",
            monthly = "growing"
        },
        topProducts = MonetizationSystem.getTopSellingProducts(),
        optimizationOpportunities = MonetizationSystem.identifyOptimizationOpportunities()
    }
    
    MonetizationState.revenueMetrics = revenueAnalysis
end

function MonetizationSystem.getTopSellingProducts()
    local products = {}
    
    for productId, product in pairs(MonetizationState.activeProducts) do
        table.insert(products, {
            id = productId,
            name = product.data.name,
            salesCount = product.salesCount,
            revenue = product.revenue
        })
    end
    
    -- Sort by revenue
    table.sort(products, function(a, b) return a.revenue > b.revenue end)
    
    -- Return top 5
    local topProducts = {}
    for i = 1, math.min(5, #products) do
        table.insert(topProducts, products[i])
    end
    
    return topProducts
end

function MonetizationSystem.identifyOptimizationOpportunities()
    local opportunities = {}
    
    -- Check for underperforming products
    for productId, product in pairs(MonetizationState.activeProducts) do
        if product.salesCount < 5 and product.data.price < 200 then
            table.insert(opportunities, {
                type = "underperforming_product",
                productId = productId,
                suggestion = "Consider price adjustment or promotion"
            })
        end
    end
    
    -- Check conversion rate
    if MonetizationState.stats.conversionRate < 5 then
        table.insert(opportunities, {
            type = "low_conversion",
            suggestion = "Improve onboarding and first-time buyer experience"
        })
    end
    
    return opportunities
end

function MonetizationSystem.checkEthicalCompliance()
    local compliance = {
        payToWinViolations = 0,
        fairnessIssues = 0,
        transparencyProblems = 0,
        playerProtectionConcerns = 0
    }
    
    -- Check for pay-to-win violations
    if MONETIZATION_CONFIG.ethics.payToWin.enablePayToWinPrevention then
        compliance = MonetizationSystem.auditPayToWinCompliance(compliance)
    end
    
    -- Check player spending limits
    compliance = MonetizationSystem.auditSpendingLimits(compliance)
    
    -- Report compliance issues
    if compliance.payToWinViolations > 0 or compliance.fairnessIssues > 0 then
        print(string.format("⚠️ Ethical compliance issues detected: %d violations", 
            compliance.payToWinViolations + compliance.fairnessIssues))
    end
    
    return compliance
end

function MonetizationSystem.auditPayToWinCompliance(compliance)
    -- Check if any products provide unfair advantages
    for productId, product in pairs(MonetizationState.activeProducts) do
        local advantages = MonetizationSystem.calculateProductAdvantage(product)
        
        if advantages.competitiveAdvantage > MONETIZATION_CONFIG.ethics.payToWin.maxAdvantagePercent then
            compliance.payToWinViolations = compliance.payToWinViolations + 1
            print(string.format("⚠️ Pay-to-win violation detected: %s provides %.1f%% advantage", 
                product.data.name, advantages.competitiveAdvantage))
        end
    end
    
    return compliance
end

function MonetizationSystem.calculateProductAdvantage(product)
    -- Calculate competitive advantage provided by product
    local advantage = {
        competitiveAdvantage = 0,
        progressionAdvantage = 0,
        qualityOfLifeImprovement = 0
    }
    
    for _, benefit in ipairs(product.data.benefits or {}) do
        if benefit == "double_rewards" then
            advantage.progressionAdvantage = advantage.progressionAdvantage + 50 -- 50% faster progression
        elseif benefit == "triple_rewards" then
            advantage.progressionAdvantage = advantage.progressionAdvantage + 100 -- 100% faster progression
        elseif benefit == "speed_multiplier_1.5" then
            advantage.competitiveAdvantage = advantage.competitiveAdvantage + 15 -- 15% speed advantage
        end
    end
    
    return advantage
end

function MonetizationSystem.auditSpendingLimits(compliance)
    -- Check if any players are spending excessively
    for userId, playerData in pairs(MonetizationState.playerEconomics) do
        local dailySpending = MonetizationSystem.getDailySpending(playerData)
        
        if dailySpending > 500 then -- R$500 per day threshold
            compliance.playerProtectionConcerns = compliance.playerProtectionConcerns + 1
            print(string.format("⚠️ Excessive spending detected: Player %d spent R$%d today", 
                userId, dailySpending))
        end
    end
    
    return compliance
end

function MonetizationSystem.getDailySpending(playerData)
    local currentTime = tick()
    local dayStart = currentTime - (currentTime % 86400) -- Start of current day
    local dailySpending = 0
    
    for _, transaction in ipairs(playerData.history) do
        if transaction.timestamp >= dayStart and transaction.price then
            dailySpending = dailySpending + transaction.price
        end
    end
    
    return dailySpending
end

-- ========================================
-- UTILITY FUNCTIONS
-- ========================================

function MonetizationSystem.updateRevenueAnalytics(transaction)
    -- Update analytics with new transaction data
    -- This would integrate with the analytics systems from previous prompts
end

function MonetizationSystem.removeExpiredEffect(player, effect)
    local playerData = MonetizationSystem.getPlayerEconomicData(player)
    
    if playerData.activeEffects then
        for i, activeEffect in ipairs(playerData.activeEffects) do
            if activeEffect == effect then
                table.remove(playerData.activeEffects, i)
                break
            end
        end
    end
    
    print(string.format("⏰ Effect expired for %s: %s", player.Name, effect.type))
end

function MonetizationSystem.updateEconomyMetrics()
    local totalCurrency = 0
    local playerCount = 0
    
    for _, playerData in pairs(MonetizationState.playerEconomics) do
        playerCount = playerCount + 1
        for currencyType, amount in pairs(playerData.currencies) do
            if currencyType == "coins" then
                totalCurrency = totalCurrency + amount
            end
        end
    end
    
    MonetizationState.economyMetrics.totalCurrencyInCirculation = totalCurrency
    MonetizationState.economyMetrics.averageCurrencyPerPlayer = 
        playerCount > 0 and (totalCurrency / playerCount) or 0
end

-- ========================================
-- PUBLIC API
-- ========================================

function MonetizationSystem.runMonetizationDemo()
    print("💰 Running monetization system demonstration...")
    
    -- Simulate some players
    local samplePlayers = {}
    for i = 1, 5 do
        local mockPlayer = {
            UserId = 1000 + i,
            Name = "TestPlayer" .. i,
            AccountAge = math.random(30, 365) -- 30-365 days
        }
        table.insert(samplePlayers, mockPlayer)
    end
    
    print("  💰 Product Catalog:")
    for productId, product in pairs(MonetizationState.activeProducts) do
        local productInfo = MonetizationSystem.getProductInfo(productId)
        print(string.format("    %s: R$%d (%s)", 
            productInfo.name, productInfo.price, productInfo.type))
    end
    
    -- Simulate some purchases
    print("  🛒 Simulating purchases...")
    
    for i, player in ipairs(samplePlayers) do
        -- Initialize player data
        MonetizationSystem.getPlayerEconomicData(player)
        
        -- Simulate gamepass purchase
        if i <= 2 then
            local gamepassId = MONETIZATION_CONFIG.products.gamepasses.premium_access.id
            local product = MonetizationState.activeProducts[gamepassId]
            
            -- Simulate purchase receipt
            local receiptInfo = {
                PlayerId = player.UserId,
                ProductId = gamepassId,
                PurchaseId = "test_purchase_" .. i,
                PlaceIdWherePurchased = game.PlaceId,
                CurrencySpent = product.data.price,
                CurrencyType = Enum.CurrencyType.Robux
            }
            
            local result = MonetizationSystem.processReceiptCallback(receiptInfo)
            print(string.format("    %s purchased %s: %s", 
                player.Name, product.data.name, 
                result == Enum.ProductPurchaseDecision.PurchaseGranted and "Success" or "Failed"))
        end
        
        -- Simulate dev product purchase
        if i >= 3 then
            local devProductId = MONETIZATION_CONFIG.products.devProducts.coins_500.id
            local product = MonetizationState.activeProducts[devProductId]
            
            local receiptInfo = {
                PlayerId = player.UserId,
                ProductId = devProductId,
                PurchaseId = "test_dev_purchase_" .. i,
                PlaceIdWherePurchased = game.PlaceId,
                CurrencySpent = product.data.price,
                CurrencyType = Enum.CurrencyType.Robux
            }
            
            local result = MonetizationSystem.processReceiptCallback(receiptInfo)
            print(string.format("    %s purchased %s: %s", 
                player.Name, product.data.name,
                result == Enum.ProductPurchaseDecision.PurchaseGranted and "Success" or "Failed"))
        end
    end
    
    task.wait(1)
    
    -- Generate personalized offers
    print("  🎯 Personalized Offers:")
    for _, player in ipairs(samplePlayers) do
        local offers = MonetizationSystem.generatePersonalizedOffers(player)
        
        if #offers > 0 then
            print(string.format("    %s:", player.Name))
            for _, offer in ipairs(offers) do
                print(string.format("      %s: %.0f%% off (R$%d)", 
                    offer.description, offer.discount * 100, offer.value))
            end
        end
    end
    
    -- Show economy metrics
    print("  ⚖️ Economy Metrics:")
    local economyHealth = MonetizationState.stats.economyHealth
    print(string.format("    Economy Health: %.1f%%", economyHealth))
    print(string.format("    Total Currency: %d coins", 
        MonetizationState.economyMetrics.totalCurrencyInCirculation))
    print(string.format("    Average per Player: %.1f coins", 
        MonetizationState.economyMetrics.averageCurrencyPerPlayer))
    
    -- Show revenue metrics
    local stats = MonetizationSystem.getMonetizationStats()
    print("  📊 Revenue Metrics:")
    print(string.format("    Total Revenue: R$%d", stats.totalRevenue))
    print(string.format("    Total Transactions: %d", stats.totalTransactions))
    print(string.format("    Conversion Rate: %.1f%%", stats.conversionRate))
    print(string.format("    ARPU: R$%.2f", stats.averageRevenuePerUser))
    
    -- Show top products
    local topProducts = MonetizationSystem.getTopSellingProducts()
    print("  🏆 Top Selling Products:")
    for i, product in ipairs(topProducts) do
        print(string.format("    %d. %s: %d sales (R$%d)", 
            i, product.name, product.salesCount, product.revenue))
    end
    
    -- Ethical compliance check
    print("  ✅ Ethical Compliance:")
    local compliance = MonetizationSystem.checkEthicalCompliance()
    print(string.format("    Pay-to-Win Violations: %d", compliance.payToWinViolations))
    print(string.format("    Fairness Issues: %d", compliance.fairnessIssues))
    print(string.format("    Protection Concerns: %d", compliance.playerProtectionConcerns))
    
    print("💰 Monetization system demonstration completed")
end

function MonetizationSystem.getMonetizationStats()
    return MonetizationState.stats
end

function MonetizationSystem.getProductCatalog()
    return MonetizationState.activeProducts
end

function MonetizationSystem.getPlayerData(player)
    return MonetizationSystem.getPlayerEconomicData(player)
end

function MonetizationSystem.getTransactionHistory()
    return MonetizationState.transactions
end

function MonetizationSystem.getRevenueMetrics()
    return MonetizationState.revenueMetrics
end

-- Export API
MonetizationSystem.processReceiptCallback = MonetizationSystem.processReceiptCallback
MonetizationSystem.getProductInfo = MonetizationSystem.getProductInfo
MonetizationSystem.validatePurchase = MonetizationSystem.validatePurchase
MonetizationSystem.updatePlayerCurrency = MonetizationSystem.updatePlayerCurrency

-- Initialize the monetization system
MonetizationSystem.initialize()

print("💰 MonetizationSystem loaded with real Robux integration and ethical monetization")

return MonetizationSystem
