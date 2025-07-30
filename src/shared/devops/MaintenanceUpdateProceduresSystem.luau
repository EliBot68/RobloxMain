-- MaintenanceUpdateProceduresSystem.luau
-- Maintenance and update procedures with minimal downtime for production systems
-- Implements rolling updates, maintenance windows, and zero-downtime deployment strategies

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local HttpService = game:GetService("HttpService")
local RunService = game:GetService("RunService")

local SafeRequire = require(ReplicatedStorage.Shared.utils.SafeRequire)

local MaintenanceUpdateProceduresSystem = {}

-- ========================================
-- MAINTENANCE CONFIGURATION
-- ========================================

local MAINTENANCE_CONFIG = {
    -- Maintenance windows
    maintenanceWindows = {
        emergency = {
            name = "Emergency Maintenance",
            allowedAnytime = true,
            maxDuration = 3600, -- 1 hour
            notificationTime = 300, -- 5 minutes notice
            rollbackPlan = "automatic"
        },
        
        scheduled = {
            name = "Scheduled Maintenance",
            dayOfWeek = 1, -- Monday
            hour = 2, -- 2 AM UTC
            duration = 7200, -- 2 hours
            notificationTime = 86400, -- 24 hours notice
            rollbackPlan = "manual"
        },
        
        hotfix = {
            name = "Hotfix Deployment",
            allowedAnytime = true,
            maxDuration = 1800, -- 30 minutes
            notificationTime = 600, -- 10 minutes notice
            rollbackPlan = "automatic"
        },
        
        rolling = {
            name = "Rolling Update",
            allowedAnytime = true,
            maxDuration = 14400, -- 4 hours
            notificationTime = 1800, -- 30 minutes notice
            rollbackPlan = "automatic"
        }
    },
    
    -- Update strategies
    updateStrategies = {
        blueGreen = {
            name = "Blue-Green Deployment",
            downtime = 0,
            rollbackTime = 60,
            healthCheckDuration = 300,
            trafficSwitchMethod = "instant"
        },
        
        rolling = {
            name = "Rolling Update",
            downtime = 0,
            batchSize = 2,
            batchDelay = 180,
            healthCheckDuration = 120,
            rollbackOnFailure = true
        },
        
        canary = {
            name = "Canary Deployment",
            downtime = 0,
            canaryPercentage = 5,
            promotionStages = [5, 25, 50, 100],
            stageDelay = 600,
            rollbackThreshold = 0.01
        },
        
        maintenance = {
            name = "Maintenance Mode",
            downtime = 300,
            drainTime = 180,
            healthCheckDuration = 60,
            userNotification = true
        }
    },
    
    -- Health checks
    healthChecks = {
        application = {
            endpoint = "/health",
            timeout = 5,
            interval = 30,
            retries = 3,
            successThreshold = 2,
            failureThreshold = 3
        },
        
        database = {
            endpoint = "/db/health",
            timeout = 10,
            interval = 60,
            retries = 2,
            successThreshold = 1,
            failureThreshold = 2
        },
        
        cache = {
            endpoint = "/cache/health",
            timeout = 3,
            interval = 30,
            retries = 3,
            successThreshold = 1,
            failureThreshold = 2
        }
    },
    
    -- Rollback procedures
    rollbackProcedures = {
        automatic = {
            enabled = true,
            triggerConditions = {
                errorRateThreshold = 0.05,
                responseTimeThreshold = 5000,
                healthCheckFailures = 3
            },
            rollbackTimeout = 300
        },
        
        manual = {
            enabled = true,
            requiresApproval = true,
            approvers = ["senior_engineer", "operations_lead"],
            rollbackTimeout = 600
        }
    }
}

-- ========================================
-- SYSTEM STATE
-- ========================================

local MaintenanceState = {
    -- Core engines
    maintenanceEngine = nil,
    updateEngine = nil,
    healthEngine = nil,
    
    -- Active operations
    activeMaintenances = {},
    activeUpdates = {},
    
    -- Maintenance windows
    scheduledWindows = {},
    
    -- System status
    systemStatus = {
        maintenanceMode = false,
        currentMaintenance = nil,
        lastMaintenance = nil,
        nextScheduledMaintenance = nil,
        healthStatus = "healthy"
    },
    
    -- Update tracking
    updateHistory = {},
    rollbackHistory = {},
    
    -- Health monitoring
    healthChecks = {},
    healthHistory = {},
    
    -- Metrics
    metrics = {
        maintenancesCompleted = 0,
        updatesDeployed = 0,
        rollbacksExecuted = 0,
        averageDowntime = 0,
        updateSuccessRate = 100,
        maintenanceSuccessRate = 100
    },
    
    -- Configuration
    config = MAINTENANCE_CONFIG
}

function MaintenanceUpdateProceduresSystem.initialize()
    print("🔧 Initializing MaintenanceUpdateProceduresSystem...")
    
    -- Initialize core engines
    MaintenanceUpdateProceduresSystem.initializeMaintenanceEngine()
    MaintenanceUpdateProceduresSystem.initializeUpdateEngine()
    MaintenanceUpdateProceduresSystem.initializeHealthEngine()
    
    -- Schedule maintenance windows
    MaintenanceUpdateProceduresSystem.scheduleMaintenanceWindows()
    
    -- Start health monitoring
    MaintenanceUpdateProceduresSystem.startHealthMonitoring()
    
    -- Start maintenance scheduler
    MaintenanceUpdateProceduresSystem.startMaintenanceScheduler()
    
    print("🔧 MaintenanceUpdateProceduresSystem initialized successfully")
end

-- ========================================
-- MAINTENANCE ENGINE
-- ========================================

function MaintenanceUpdateProceduresSystem.initializeMaintenanceEngine()
    MaintenanceState.maintenanceEngine = {
        scheduledMaintenances = {},
        
        scheduleMaintenanceWindow = function(self, config)
            return MaintenanceUpdateProceduresSystem.scheduleMaintenanceWindow(config)
        end,
        
        startMaintenance = function(self, maintenanceId)
            return MaintenanceUpdateProceduresSystem.startMaintenance(maintenanceId)
        end,
        
        completeMaintenance = function(self, maintenanceId)
            return MaintenanceUpdateProceduresSystem.completeMaintenance(maintenanceId)
        end
    }
    
    print("🔧 Maintenance engine initialized")
end

function MaintenanceUpdateProceduresSystem.scheduleMaintenanceWindow(config)
    local maintenance = {
        id = HttpService:GenerateGUID(),
        type = config.type or "scheduled",
        title = config.title,
        description = config.description,
        
        scheduledStart = config.scheduledStart,
        estimatedDuration = config.estimatedDuration,
        
        window = MaintenanceState.config.maintenanceWindows[config.type],
        
        status = "scheduled",
        
        procedures = config.procedures or {},
        rollbackPlan = config.rollbackPlan or {},
        
        notifications = {
            scheduled = false,
            started = false,
            completed = false
        },
        
        approvals = {
            required = config.requiresApproval or false,
            approvers = config.approvers or {},
            approved = false
        },
        
        created = os.time()
    }
    
    MaintenanceState.scheduledWindows[maintenance.id] = maintenance
    
    print(string.format("📅 Scheduled maintenance: %s (%s)", maintenance.title, maintenance.type))
    
    -- Schedule notifications
    MaintenanceUpdateProceduresSystem.scheduleMaintenanceNotifications(maintenance)
    
    return {
        success = true,
        maintenance = maintenance
    }
end

function MaintenanceUpdateProceduresSystem.startMaintenance(maintenanceId)
    local maintenance = MaintenanceState.scheduledWindows[maintenanceId]
    
    if not maintenance then
        return {success = false, error = "Maintenance not found"}
    end
    
    if maintenance.status ~= "scheduled" then
        return {success = false, error = "Maintenance not in scheduled state"}
    end
    
    -- Check approvals if required
    if maintenance.approvals.required and not maintenance.approvals.approved then
        return {success = false, error = "Maintenance not approved"}
    end
    
    maintenance.status = "in_progress"
    maintenance.actualStart = os.time()
    
    MaintenanceState.activeMaintenances[maintenanceId] = maintenance
    MaintenanceState.systemStatus.maintenanceMode = true
    MaintenanceState.systemStatus.currentMaintenance = maintenanceId
    
    print(string.format("🔧 Starting maintenance: %s", maintenance.title))
    
    -- Send start notification
    MaintenanceUpdateProceduresSystem.sendMaintenanceNotification(maintenance, "started")
    
    -- Execute maintenance procedures
    spawn(function()
        local success = MaintenanceUpdateProceduresSystem.executeMaintenance(maintenance)
        
        if success then
            MaintenanceUpdateProceduresSystem.completeMaintenance(maintenanceId)
        else
            MaintenanceUpdateProceduresSystem.failMaintenance(maintenanceId)
        end
    end)
    
    return {success = true}
end

function MaintenanceUpdateProceduresSystem.executeMaintenance(maintenance)
    local procedures = maintenance.procedures
    
    print(string.format("    📋 Executing %d maintenance procedures...", #procedures))
    
    for i, procedure in ipairs(procedures) do
        print(string.format("    %d. %s", i, procedure.name))
        
        local success = MaintenanceUpdateProceduresSystem.executeProcedure(procedure, maintenance)
        
        if not success then
            print(string.format("    ❌ Procedure failed: %s", procedure.name))
            
            -- Execute rollback if automatic
            if maintenance.window.rollbackPlan == "automatic" then
                print("    🔄 Executing automatic rollback...")
                MaintenanceUpdateProceduresSystem.executeRollback(maintenance)
            end
            
            return false
        end
        
        print(string.format("    ✅ Procedure completed: %s", procedure.name))
    end
    
    return true
end

function MaintenanceUpdateProceduresSystem.executeProcedure(procedure, maintenance)
    -- Simulate procedure execution based on type
    if procedure.type == "database_migration" then
        return MaintenanceUpdateProceduresSystem.executeDatabaseMigration(procedure)
    elseif procedure.type == "server_update" then
        return MaintenanceUpdateProceduresSystem.executeServerUpdate(procedure)
    elseif procedure.type == "configuration_update" then
        return MaintenanceUpdateProceduresSystem.executeConfigurationUpdate(procedure)
    elseif procedure.type == "security_patch" then
        return MaintenanceUpdateProceduresSystem.executeSecurityPatch(procedure)
    elseif procedure.type == "cleanup" then
        return MaintenanceUpdateProceduresSystem.executeCleanup(procedure)
    else
        return MaintenanceUpdateProceduresSystem.executeGenericProcedure(procedure)
    end
end

function MaintenanceUpdateProceduresSystem.executeDatabaseMigration(procedure)
    print("        🗄️ Starting database migration...")
    
    -- Simulate backup
    print("        💾 Creating database backup...")
    wait(0.2)
    
    -- Simulate migration
    print("        🔄 Applying database changes...")
    wait(0.3)
    
    -- Simulate validation
    print("        ✅ Validating migration...")
    wait(0.1)
    
    return math.random() > 0.05 -- 95% success rate
end

function MaintenanceUpdateProceduresSystem.executeServerUpdate(procedure)
    print("        🖥️ Starting server update...")
    
    -- Simulate update download
    print("        📥 Downloading update package...")
    wait(0.1)
    
    -- Simulate installation
    print("        📦 Installing update...")
    wait(0.2)
    
    -- Simulate restart
    print("        🔄 Restarting services...")
    wait(0.1)
    
    return math.random() > 0.02 -- 98% success rate
end

function MaintenanceUpdateProceduresSystem.executeConfigurationUpdate(procedure)
    print("        ⚙️ Updating configuration...")
    
    -- Simulate configuration backup
    print("        💾 Backing up current configuration...")
    wait(0.1)
    
    -- Simulate update
    print("        📝 Applying configuration changes...")
    wait(0.1)
    
    -- Simulate validation
    print("        ✅ Validating configuration...")
    wait(0.1)
    
    return math.random() > 0.01 -- 99% success rate
end

function MaintenanceUpdateProceduresSystem.executeSecurityPatch(procedure)
    print("        🔒 Applying security patch...")
    
    -- Simulate patch application
    print("        🛡️ Installing security updates...")
    wait(0.2)
    
    -- Simulate security scan
    print("        🔍 Running security validation...")
    wait(0.1)
    
    return math.random() > 0.005 -- 99.5% success rate
end

function MaintenanceUpdateProceduresSystem.executeCleanup(procedure)
    print("        🧹 Performing system cleanup...")
    
    -- Simulate cleanup operations
    print("        🗑️ Removing temporary files...")
    wait(0.1)
    
    print("        📊 Optimizing database...")
    wait(0.1)
    
    print("        💾 Clearing caches...")
    wait(0.1)
    
    return true -- Cleanup always succeeds
end

function MaintenanceUpdateProceduresSystem.executeGenericProcedure(procedure)
    print(string.format("        🔧 Executing %s...", procedure.name))
    wait(0.1)
    
    return math.random() > 0.03 -- 97% success rate
end

function MaintenanceUpdateProceduresSystem.completeMaintenance(maintenanceId)
    local maintenance = MaintenanceState.activeMaintenances[maintenanceId]
    
    if maintenance then
        maintenance.status = "completed"
        maintenance.actualEnd = os.time()
        maintenance.actualDuration = maintenance.actualEnd - maintenance.actualStart
        
        MaintenanceState.activeMaintenances[maintenanceId] = nil
        MaintenanceState.systemStatus.maintenanceMode = false
        MaintenanceState.systemStatus.currentMaintenance = nil
        MaintenanceState.systemStatus.lastMaintenance = maintenanceId
        
        -- Update metrics
        MaintenanceState.metrics.maintenancesCompleted = MaintenanceState.metrics.maintenancesCompleted + 1
        MaintenanceState.metrics.averageDowntime = MaintenanceUpdateProceduresSystem.updateAverageDowntime(
            maintenance.actualDuration
        )
        
        print(string.format("✅ Maintenance completed: %s (%.1fs)", 
            maintenance.title, 
            maintenance.actualDuration))
        
        -- Send completion notification
        MaintenanceUpdateProceduresSystem.sendMaintenanceNotification(maintenance, "completed")
        
        return {success = true}
    else
        return {success = false, error = "Maintenance not found"}
    end
end

function MaintenanceUpdateProceduresSystem.failMaintenance(maintenanceId)
    local maintenance = MaintenanceState.activeMaintenances[maintenanceId]
    
    if maintenance then
        maintenance.status = "failed"
        maintenance.actualEnd = os.time()
        maintenance.actualDuration = maintenance.actualEnd - maintenance.actualStart
        
        MaintenanceState.activeMaintenances[maintenanceId] = nil
        MaintenanceState.systemStatus.maintenanceMode = false
        MaintenanceState.systemStatus.currentMaintenance = nil
        
        print(string.format("❌ Maintenance failed: %s", maintenance.title))
        
        -- Send failure notification
        MaintenanceUpdateProceduresSystem.sendMaintenanceNotification(maintenance, "failed")
        
        -- Trigger alerts
        local MonitoringSystem = SafeRequire("ReplicatedStorage.Shared.devops.MonitoringAlertingSystem")
        if MonitoringSystem then
            MonitoringSystem.createManualAlert({
                title = "Maintenance Failed",
                message = string.format("Maintenance '%s' failed during execution", maintenance.title),
                level = "critical",
                source = "maintenance_system"
            })
        end
        
        return {success = true}
    else
        return {success = false, error = "Maintenance not found"}
    end
end

-- ========================================
-- UPDATE ENGINE
-- ========================================

function MaintenanceUpdateProceduresSystem.initializeUpdateEngine()
    MaintenanceState.updateEngine = {
        activeUpdates = {},
        
        deployUpdate = function(self, updateConfig)
            return MaintenanceUpdateProceduresSystem.deployUpdate(updateConfig)
        end,
        
        rollbackUpdate = function(self, updateId)
            return MaintenanceUpdateProceduresSystem.rollbackUpdate(updateId)
        end,
        
        getUpdateStatus = function(self, updateId)
            return MaintenanceUpdateProceduresSystem.getUpdateStatus(updateId)
        end
    }
    
    print("🚀 Update engine initialized")
end

function MaintenanceUpdateProceduresSystem.deployUpdate(updateConfig)
    local update = {
        id = HttpService:GenerateGUID(),
        type = updateConfig.type or "application",
        version = updateConfig.version,
        strategy = updateConfig.strategy or "rolling",
        
        title = updateConfig.title,
        description = updateConfig.description,
        
        started = os.time(),
        status = "deploying",
        
        configuration = MaintenanceState.config.updateStrategies[updateConfig.strategy],
        
        progress = {
            phase = "preparing",
            percentage = 0,
            currentBatch = 0,
            totalBatches = 0
        },
        
        rollback = {
            available = true,
            previousVersion = updateConfig.previousVersion,
            rollbackData = updateConfig.rollbackData
        },
        
        healthChecks = {
            passed = 0,
            failed = 0,
            lastCheck = nil
        }
    }
    
    MaintenanceState.activeUpdates[update.id] = update
    
    print(string.format("🚀 Starting update deployment: %s (%s strategy)", 
        update.title, 
        update.strategy))
    
    -- Execute update based on strategy
    spawn(function()
        local success = MaintenanceUpdateProceduresSystem.executeUpdateStrategy(update)
        
        if success then
            update.status = "completed"
            update.completed = os.time()
            update.duration = update.completed - update.started
            
            MaintenanceState.metrics.updatesDeployed = MaintenanceState.metrics.updatesDeployed + 1
            
            print(string.format("✅ Update completed: %s (%.1fs)", update.title, update.duration))
        else
            update.status = "failed"
            update.completed = os.time()
            
            print(string.format("❌ Update failed: %s", update.title))
            
            -- Auto-rollback if configured
            if update.configuration.rollbackOnFailure then
                print("    🔄 Initiating automatic rollback...")
                MaintenanceUpdateProceduresSystem.rollbackUpdate(update.id)
            end
        end
        
        -- Move to history
        table.insert(MaintenanceState.updateHistory, update)
        MaintenanceState.activeUpdates[update.id] = nil
    end)
    
    return {
        success = true,
        update = update
    }
end

function MaintenanceUpdateProceduresSystem.executeUpdateStrategy(update)
    local strategy = update.strategy
    
    if strategy == "blueGreen" then
        return MaintenanceUpdateProceduresSystem.executeBlueGreenUpdate(update)
    elseif strategy == "rolling" then
        return MaintenanceUpdateProceduresSystem.executeRollingUpdate(update)
    elseif strategy == "canary" then
        return MaintenanceUpdateProceduresSystem.executeCanaryUpdate(update)
    elseif strategy == "maintenance" then
        return MaintenanceUpdateProceduresSystem.executeMaintenanceUpdate(update)
    else
        return false
    end
end

function MaintenanceUpdateProceduresSystem.executeBlueGreenUpdate(update)
    print("    🔵 Executing Blue-Green deployment...")
    
    -- Phase 1: Deploy to green environment
    update.progress.phase = "deploying_green"
    update.progress.percentage = 20
    print("        🟢 Deploying to green environment...")
    wait(0.3)
    
    -- Phase 2: Health check green environment
    update.progress.phase = "health_check_green"
    update.progress.percentage = 40
    print("        🏥 Health checking green environment...")
    
    local healthPassed = MaintenanceUpdateProceduresSystem.performHealthCheck(update, "green")
    if not healthPassed then
        print("        ❌ Green environment health check failed")
        return false
    end
    
    -- Phase 3: Switch traffic to green
    update.progress.phase = "switching_traffic"
    update.progress.percentage = 80
    print("        🔀 Switching traffic to green environment...")
    wait(0.2)
    
    -- Phase 4: Final health check
    update.progress.phase = "final_health_check"
    update.progress.percentage = 90
    print("        🏥 Final health check...")
    
    local finalHealthPassed = MaintenanceUpdateProceduresSystem.performHealthCheck(update, "final")
    if not finalHealthPassed then
        print("        ❌ Final health check failed - rolling back...")
        return false
    end
    
    update.progress.percentage = 100
    return true
end

function MaintenanceUpdateProceduresSystem.executeRollingUpdate(update)
    print("    🔄 Executing Rolling update...")
    
    local config = update.configuration
    local batchSize = config.batchSize or 2
    local totalServers = 8 -- Simulated server count
    local totalBatches = math.ceil(totalServers / batchSize)
    
    update.progress.totalBatches = totalBatches
    
    for batch = 1, totalBatches do
        update.progress.currentBatch = batch
        update.progress.phase = string.format("batch_%d", batch)
        update.progress.percentage = (batch / totalBatches) * 100
        
        print(string.format("        📦 Updating batch %d/%d...", batch, totalBatches))
        
        -- Simulate batch update
        wait(0.2)
        
        -- Health check after batch
        local healthPassed = MaintenanceUpdateProceduresSystem.performHealthCheck(update, "batch")
        if not healthPassed then
            print(string.format("        ❌ Batch %d health check failed", batch))
            return false
        end
        
        -- Wait between batches
        if batch < totalBatches then
            print(string.format("        ⏱️ Waiting %ds before next batch...", config.batchDelay))
            wait(config.batchDelay / 60) -- Simulate wait
        end
    end
    
    return true
end

function MaintenanceUpdateProceduresSystem.executeCanaryUpdate(update)
    print("    🐤 Executing Canary deployment...")
    
    local config = update.configuration
    local stages = config.promotionStages or {5, 25, 50, 100}
    
    for i, percentage in ipairs(stages) do
        update.progress.phase = string.format("canary_%d_percent", percentage)
        update.progress.percentage = (i / #stages) * 100
        
        print(string.format("        🎯 Deploying to %d%% of traffic...", percentage))
        
        -- Simulate deployment
        wait(0.2)
        
        -- Monitor for stage delay
        print(string.format("        ⏱️ Monitoring for %ds...", config.stageDelay))
        wait(config.stageDelay / 60) -- Simulate monitoring
        
        -- Health check
        local healthPassed = MaintenanceUpdateProceduresSystem.performHealthCheck(update, "canary")
        if not healthPassed then
            print(string.format("        ❌ Canary health check failed at %d%%", percentage))
            return false
        end
        
        -- Check metrics for rollback threshold
        local errorRate = math.random() * 0.02 -- 0-2% error rate
        if errorRate > config.rollbackThreshold then
            print(string.format("        ❌ Error rate %.3f%% exceeds threshold %.3f%%", 
                errorRate * 100, 
                config.rollbackThreshold * 100))
            return false
        end
        
        print(string.format("        ✅ Canary stage %d%% successful", percentage))
    end
    
    return true
end

function MaintenanceUpdateProceduresSystem.executeMaintenanceUpdate(update)
    print("    🔧 Executing Maintenance mode update...")
    
    local config = update.configuration
    
    -- Phase 1: Enable maintenance mode
    update.progress.phase = "enabling_maintenance"
    update.progress.percentage = 10
    print("        🚧 Enabling maintenance mode...")
    
    MaintenanceState.systemStatus.maintenanceMode = true
    
    -- Phase 2: Drain connections
    update.progress.phase = "draining_connections"
    update.progress.percentage = 30
    print(string.format("        💧 Draining connections (%ds)...", config.drainTime))
    wait(config.drainTime / 60) -- Simulate drain
    
    -- Phase 3: Deploy update
    update.progress.phase = "deploying_update"
    update.progress.percentage = 70
    print("        🚀 Deploying update...")
    wait(0.3)
    
    -- Phase 4: Health check
    update.progress.phase = "health_check"
    update.progress.percentage = 90
    print("        🏥 Health checking...")
    
    local healthPassed = MaintenanceUpdateProceduresSystem.performHealthCheck(update, "maintenance")
    if not healthPassed then
        print("        ❌ Health check failed")
        MaintenanceState.systemStatus.maintenanceMode = false
        return false
    end
    
    -- Phase 5: Disable maintenance mode
    update.progress.phase = "disabling_maintenance"
    update.progress.percentage = 100
    print("        ✅ Disabling maintenance mode...")
    
    MaintenanceState.systemStatus.maintenanceMode = false
    
    return true
end

function MaintenanceUpdateProceduresSystem.performHealthCheck(update, context)
    local checks = MaintenanceState.config.healthChecks
    local passed = 0
    local total = 0
    
    for checkName, config in pairs(checks) do
        total = total + 1
        
        -- Simulate health check
        local success = math.random() > 0.05 -- 95% success rate
        
        if success then
            passed = passed + 1
            print(string.format("            ✅ %s health check passed", checkName))
        else
            print(string.format("            ❌ %s health check failed", checkName))
        end
    end
    
    update.healthChecks.passed = update.healthChecks.passed + passed
    update.healthChecks.failed = update.healthChecks.failed + (total - passed)
    update.healthChecks.lastCheck = os.time()
    
    local successRate = passed / total
    return successRate >= 0.8 -- Require 80% success rate
end

function MaintenanceUpdateProceduresSystem.rollbackUpdate(updateId)
    local update = MaintenanceState.activeUpdates[updateId] or 
                   MaintenanceUpdateProceduresSystem.findUpdateInHistory(updateId)
    
    if not update then
        return {success = false, error = "Update not found"}
    end
    
    if not update.rollback.available then
        return {success = false, error = "Rollback not available"}
    end
    
    local rollback = {
        id = HttpService:GenerateGUID(),
        updateId = updateId,
        previousVersion = update.rollback.previousVersion,
        started = os.time(),
        status = "rolling_back"
    }
    
    print(string.format("🔄 Rolling back update: %s", update.title))
    
    spawn(function()
        local success = MaintenanceUpdateProceduresSystem.executeRollback(rollback, update)
        
        if success then
            rollback.status = "completed"
            rollback.completed = os.time()
            rollback.duration = rollback.completed - rollback.started
            
            MaintenanceState.metrics.rollbacksExecuted = MaintenanceState.metrics.rollbacksExecuted + 1
            
            print(string.format("✅ Rollback completed: %s (%.1fs)", update.title, rollback.duration))
        else
            rollback.status = "failed"
            rollback.completed = os.time()
            
            print(string.format("❌ Rollback failed: %s", update.title))
            
            -- Critical alert for rollback failure
            local MonitoringSystem = SafeRequire("ReplicatedStorage.Shared.devops.MonitoringAlertingSystem")
            if MonitoringSystem then
                MonitoringSystem.createManualAlert({
                    title = "Rollback Failed",
                    message = string.format("Rollback failed for update '%s' - manual intervention required", update.title),
                    level = "critical",
                    source = "update_system"
                })
            end
        end
        
        table.insert(MaintenanceState.rollbackHistory, rollback)
    end)
    
    return {
        success = true,
        rollback = rollback
    }
end

function MaintenanceUpdateProceduresSystem.executeRollback(rollback, update)
    print(string.format("    🔄 Executing rollback to version: %s", rollback.previousVersion))
    
    -- Simulate rollback based on original strategy
    if update.strategy == "blueGreen" then
        print("        🔵 Switching traffic back to blue environment...")
        wait(0.1)
    elseif update.strategy == "rolling" then
        print("        🔄 Rolling back all servers...")
        wait(0.3)
    elseif update.strategy == "canary" then
        print("        🐤 Reverting canary deployment...")
        wait(0.2)
    elseif update.strategy == "maintenance" then
        print("        🔧 Rolling back in maintenance mode...")
        MaintenanceState.systemStatus.maintenanceMode = true
        wait(0.2)
        MaintenanceState.systemStatus.maintenanceMode = false
    end
    
    -- Health check after rollback
    print("        🏥 Health checking rollback...")
    wait(0.1)
    
    return math.random() > 0.02 -- 98% rollback success rate
end

-- ========================================
-- HEALTH ENGINE
-- ========================================

function MaintenanceUpdateProceduresSystem.initializeHealthEngine()
    MaintenanceState.healthEngine = {
        activeChecks = {},
        
        performHealthCheck = function(self, checkType)
            return MaintenanceUpdateProceduresSystem.performSystemHealthCheck(checkType)
        end,
        
        getHealthStatus = function(self)
            return MaintenanceUpdateProceduresSystem.getSystemHealthStatus()
        end,
        
        addHealthCheck = function(self, checkConfig)
            return MaintenanceUpdateProceduresSystem.addHealthCheck(checkConfig)
        end
    }
    
    print("🏥 Health monitoring engine initialized")
end

function MaintenanceUpdateProceduresSystem.startHealthMonitoring()
    spawn(function()
        while true do
            MaintenanceUpdateProceduresSystem.performSystemHealthCheck("scheduled")
            wait(60) -- Check every minute
        end
    end)
    
    print("🏥 Health monitoring started")
end

function MaintenanceUpdateProceduresSystem.performSystemHealthCheck(checkType)
    local healthCheck = {
        id = HttpService:GenerateGUID(),
        type = checkType,
        timestamp = os.time(),
        results = {}
    }
    
    local overallHealth = "healthy"
    local totalChecks = 0
    local passedChecks = 0
    
    for checkName, config in pairs(MaintenanceState.config.healthChecks) do
        totalChecks = totalChecks + 1
        
        -- Simulate health check
        local success = math.random() > 0.05 -- 95% success rate
        local responseTime = math.random(100, 1000) -- 100-1000ms
        
        healthCheck.results[checkName] = {
            status = success and "healthy" or "unhealthy",
            responseTime = responseTime,
            timestamp = os.time()
        }
        
        if success then
            passedChecks = passedChecks + 1
        else
            if checkName == "application" then
                overallHealth = "degraded"
            elseif checkName == "database" then
                overallHealth = "critical"
            end
        end
    end
    
    healthCheck.overallHealth = overallHealth
    healthCheck.successRate = (passedChecks / totalChecks) * 100
    
    -- Store health check
    table.insert(MaintenanceState.healthHistory, healthCheck)
    
    -- Keep only last 100 health checks
    if #MaintenanceState.healthHistory > 100 then
        table.remove(MaintenanceState.healthHistory, 1)
    end
    
    -- Update system status
    MaintenanceState.systemStatus.healthStatus = overallHealth
    
    -- Alert on health issues
    if overallHealth ~= "healthy" then
        local MonitoringSystem = SafeRequire("ReplicatedStorage.Shared.devops.MonitoringAlertingSystem")
        if MonitoringSystem then
            MonitoringSystem.createManualAlert({
                title = "System Health Degraded",
                message = string.format("System health is %s - %d/%d checks passing", 
                    overallHealth, 
                    passedChecks, 
                    totalChecks),
                level = overallHealth == "critical" and "critical" or "warning",
                source = "health_monitoring"
            })
        end
    end
    
    return healthCheck
end

-- ========================================
-- SCHEDULING AND NOTIFICATIONS
-- ========================================

function MaintenanceUpdateProceduresSystem.scheduleMaintenanceWindows()
    -- Schedule regular maintenance windows
    spawn(function()
        while true do
            MaintenanceUpdateProceduresSystem.checkScheduledMaintenance()
            wait(3600) -- Check every hour
        end
    end)
    
    print("📅 Maintenance window scheduler started")
end

function MaintenanceUpdateProceduresSystem.checkScheduledMaintenance()
    local currentTime = os.time()
    local currentDate = os.date("*t", currentTime)
    
    -- Check for scheduled maintenance (e.g., Monday 2 AM UTC)
    local scheduledConfig = MaintenanceState.config.maintenanceWindows.scheduled
    
    if currentDate.wday == scheduledConfig.dayOfWeek and 
       currentDate.hour == scheduledConfig.hour and
       currentDate.min < 5 then -- Within first 5 minutes of the hour
        
        -- Check if maintenance already scheduled for this time
        local alreadyScheduled = false
        for _, maintenance in pairs(MaintenanceState.scheduledWindows) do
            local maintenanceDate = os.date("*t", maintenance.scheduledStart)
            if maintenanceDate.yday == currentDate.yday and 
               maintenanceDate.hour == currentDate.hour then
                alreadyScheduled = true
                break
            end
        end
        
        if not alreadyScheduled then
            MaintenanceUpdateProceduresSystem.scheduleAutoMaintenance()
        end
    end
end

function MaintenanceUpdateProceduresSystem.scheduleAutoMaintenance()
    local config = {
        type = "scheduled",
        title = "Weekly Scheduled Maintenance",
        description = "Routine system maintenance and updates",
        scheduledStart = os.time(),
        estimatedDuration = 7200, -- 2 hours
        procedures = {
            {name = "System Updates", type = "server_update"},
            {name = "Database Optimization", type = "cleanup"},
            {name = "Security Patches", type = "security_patch"},
            {name = "Configuration Updates", type = "configuration_update"}
        }
    }
    
    MaintenanceUpdateProceduresSystem.scheduleMaintenanceWindow(config)
end

function MaintenanceUpdateProceduresSystem.scheduleMaintenanceNotifications(maintenance)
    local notificationTime = maintenance.window.notificationTime
    
    spawn(function()
        -- Wait until notification time
        local waitTime = maintenance.scheduledStart - os.time() - notificationTime
        if waitTime > 0 then
            wait(waitTime)
        end
        
        -- Send notification
        MaintenanceUpdateProceduresSystem.sendMaintenanceNotification(maintenance, "scheduled")
    end)
end

function MaintenanceUpdateProceduresSystem.sendMaintenanceNotification(maintenance, eventType)
    local messages = {
        scheduled = string.format("Maintenance scheduled: %s at %s", 
            maintenance.title, 
            os.date("%Y-%m-%d %H:%M UTC", maintenance.scheduledStart)),
        
        started = string.format("Maintenance started: %s", maintenance.title),
        
        completed = string.format("Maintenance completed: %s (duration: %.1fs)", 
            maintenance.title, 
            maintenance.actualDuration or 0),
        
        failed = string.format("Maintenance failed: %s", maintenance.title)
    }
    
    local message = messages[eventType] or string.format("Maintenance %s: %s", eventType, maintenance.title)
    
    print(string.format("📢 Notification: %s", message))
    
    -- Mark notification as sent
    maintenance.notifications[eventType] = true
    
    -- In a real implementation, this would send notifications via various channels
end

function MaintenanceUpdateProceduresSystem.startMaintenanceScheduler()
    spawn(function()
        while true do
            -- Check for maintenance windows that should start
            local currentTime = os.time()
            
            for maintenanceId, maintenance in pairs(MaintenanceState.scheduledWindows) do
                if maintenance.status == "scheduled" and 
                   maintenance.scheduledStart <= currentTime then
                    
                    -- Auto-start if no approval required or already approved
                    if not maintenance.approvals.required or maintenance.approvals.approved then
                        MaintenanceUpdateProceduresSystem.startMaintenance(maintenanceId)
                    else
                        print(string.format("⏰ Maintenance ready to start but pending approval: %s", 
                            maintenance.title))
                    end
                end
            end
            
            wait(60) -- Check every minute
        end
    end)
    
    print("⏰ Maintenance scheduler started")
end

-- ========================================
-- UTILITY FUNCTIONS
-- ========================================

function MaintenanceUpdateProceduresSystem.updateAverageDowntime(newDowntime)
    local totalMaintenances = MaintenanceState.metrics.maintenancesCompleted
    local currentAverage = MaintenanceState.metrics.averageDowntime
    
    if totalMaintenances <= 1 then
        return newDowntime
    else
        return ((currentAverage * (totalMaintenances - 1)) + newDowntime) / totalMaintenances
    end
end

function MaintenanceUpdateProceduresSystem.findUpdateInHistory(updateId)
    for _, update in ipairs(MaintenanceState.updateHistory) do
        if update.id == updateId then
            return update
        end
    end
    return nil
end

function MaintenanceUpdateProceduresSystem.executeRollback(maintenance)
    print("🔄 Executing rollback procedures...")
    
    local rollbackProcedures = maintenance.rollbackPlan or {}
    
    for i, procedure in ipairs(rollbackProcedures) do
        print(string.format("    %d. Rolling back: %s", i, procedure.name))
        
        -- Simulate rollback procedure
        wait(0.1)
        
        local success = math.random() > 0.05 -- 95% success rate
        if not success then
            print(string.format("    ❌ Rollback procedure failed: %s", procedure.name))
            return false
        end
        
        print(string.format("    ✅ Rollback completed: %s", procedure.name))
    end
    
    return true
end

-- ========================================
-- PUBLIC API
-- ========================================

function MaintenanceUpdateProceduresSystem.requestMaintenance(config)
    return MaintenanceState.maintenanceEngine:scheduleMaintenanceWindow(config)
end

function MaintenanceUpdateProceduresSystem.requestUpdate(updateConfig)
    return MaintenanceState.updateEngine:deployUpdate(updateConfig)
end

function MaintenanceUpdateProceduresSystem.approveMaintenanceWindow(maintenanceId, approverId)
    local maintenance = MaintenanceState.scheduledWindows[maintenanceId]
    
    if maintenance and maintenance.approvals.required then
        maintenance.approvals.approved = true
        maintenance.approvals.approvedBy = approverId
        maintenance.approvals.approvedAt = os.time()
        
        print(string.format("✅ Maintenance approved: %s (by: %s)", maintenance.title, approverId))
        
        return {success = true}
    else
        return {success = false, error = "Maintenance not found or approval not required"}
    end
end

function MaintenanceUpdateProceduresSystem.getMaintenanceStatus(maintenanceId)
    return MaintenanceState.scheduledWindows[maintenanceId] or 
           MaintenanceState.activeMaintenances[maintenanceId]
end

function MaintenanceUpdateProceduresSystem.getUpdateStatus(updateId)
    return MaintenanceState.activeUpdates[updateId]
end

function MaintenanceUpdateProceduresSystem.getSystemStatus()
    return MaintenanceState.systemStatus
end

function MaintenanceUpdateProceduresSystem.getSystemHealthStatus()
    return MaintenanceState.healthEngine:getHealthStatus()
end

function MaintenanceUpdateProceduresSystem.emergencyRollback(updateId)
    return MaintenanceState.updateEngine:rollbackUpdate(updateId)
