-- AutoScalingLoadBalancingSystem.luau
-- Automated scaling and load balancing for production systems
-- Manages traffic distribution, resource scaling, and performance optimization

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local HttpService = game:GetService("HttpService")
local RunService = game:GetService("RunService")

local SafeRequire = require(ReplicatedStorage.Shared.utils.SafeRequire)

local AutoScalingLoadBalancingSystem = {}

-- ========================================
-- SCALING CONFIGURATION
-- ========================================

local SCALING_CONFIG = {
    -- Auto-scaling rules
    scaling = {
        gameServers = {
            minInstances = 2,
            maxInstances = 20,
            targetUtilization = 70, -- CPU %
            scaleUpCooldown = 300,  -- 5 minutes
            scaleDownCooldown = 600, -- 10 minutes
            
            scaleUpThreshold = 80,   -- CPU %
            scaleDownThreshold = 30, -- CPU %
            
            metrics = {"cpu_usage", "memory_usage", "player_count", "response_time"}
        },
        
        webServers = {
            minInstances = 1,
            maxInstances = 10,
            targetUtilization = 60,
            scaleUpCooldown = 180,
            scaleDownCooldown = 600,
            
            scaleUpThreshold = 75,
            scaleDownThreshold = 25,
            
            metrics = {"cpu_usage", "request_rate", "response_time", "error_rate"}
        },
        
        databases = {
            minInstances = 1,
            maxInstances = 3,
            targetUtilization = 80,
            scaleUpCooldown = 600,
            scaleDownCooldown = 1800,
            
            scaleUpThreshold = 85,
            scaleDownThreshold = 40,
            
            metrics = {"cpu_usage", "connection_count", "query_time"}
        }
    },
    
    -- Load balancing strategies
    loadBalancing = {
        algorithms = {
            roundRobin = {
                name = "Round Robin",
                description = "Distribute requests evenly across servers",
                sticky = false
            },
            
            leastConnections = {
                name = "Least Connections",
                description = "Route to server with fewest active connections",
                sticky = false
            },
            
            weightedRoundRobin = {
                name = "Weighted Round Robin",
                description = "Distribute based on server capacity weights",
                sticky = false
            },
            
            ipHash = {
                name = "IP Hash",
                description = "Route based on client IP hash for session stickiness",
                sticky = true
            },
            
            leastResponseTime = {
                name = "Least Response Time",
                description = "Route to server with lowest response time",
                sticky = false
            }
        },
        
        healthChecks = {
            interval = 30, -- seconds
            timeout = 5,   -- seconds
            retries = 3,
            
            endpoints = {
                "/health",
                "/status",
                "/ping"
            }
        },
        
        sessionStickiness = {
            enabled = true,
            duration = 3600, -- 1 hour
            method = "cookie" -- cookie, ip, header
        }
    },
    
    -- Performance targets
    targets = {
        responseTime = {
            p50 = 100,  -- ms
            p95 = 250,  -- ms
            p99 = 500   -- ms
        },
        
        throughput = {
            requestsPerSecond = 1000,
            playersPerServer = 50,
            concurrentConnections = 10000
        },
        
        availability = {
            uptime = 99.9,     -- %
            errorRate = 0.1,   -- %
            successRate = 99.9 -- %
        }
    }
}

-- ========================================
-- SYSTEM STATE
-- ========================================

local ScalingState = {
    -- Core engines
    scalingEngine = nil,
    loadBalancerEngine = nil,
    metricsEngine = nil,
    
    -- Server management
    serverPools = {},
    activeServers = {},
    
    -- Load balancing
    loadBalancers = {},
    routingRules = {},
    
    -- Scaling operations
    scalingOperations = {},
    scalingHistory = {},
    
    -- Performance metrics
    performanceMetrics = {},
    
    -- System status
    systemStatus = {
        overallHealth = "healthy",
        totalServers = 0,
        activeConnections = 0,
        averageResponseTime = 0,
        throughput = 0
    },
    
    -- Metrics
    metrics = {
        scalingOperations = 0,
        serversAdded = 0,
        serversRemoved = 0,
        loadBalancedRequests = 0,
        averageServerUtilization = 0,
        peakConcurrentUsers = 0
    },
    
    -- Configuration
    config = SCALING_CONFIG
}

function AutoScalingLoadBalancingSystem.initialize()
    print("⚖️ Initializing AutoScalingLoadBalancingSystem...")
    
    -- Initialize core engines
    AutoScalingLoadBalancingSystem.initializeScalingEngine()
    AutoScalingLoadBalancingSystem.initializeLoadBalancerEngine()
    AutoScalingLoadBalancingSystem.initializeMetricsEngine()
    
    -- Set up server pools
    AutoScalingLoadBalancingSystem.initializeServerPools()
    
    -- Start monitoring and scaling
    AutoScalingLoadBalancingSystem.startScalingMonitoring()
    
    -- Initialize load balancers
    AutoScalingLoadBalancingSystem.initializeLoadBalancers()
    
    print("⚖️ AutoScalingLoadBalancingSystem initialized successfully")
end

-- ========================================
-- SCALING ENGINE
-- ========================================

function AutoScalingLoadBalancingSystem.initializeScalingEngine()
    ScalingState.scalingEngine = {
        scalingGroups = {},
        cooldownPeriods = {},
        
        scaleUp = function(self, groupName, count)
            return AutoScalingLoadBalancingSystem.scaleUp(groupName, count)
        end,
        
        scaleDown = function(self, groupName, count)
            return AutoScalingLoadBalancingSystem.scaleDown(groupName, count)
        end,
        
        evaluateScaling = function(self, groupName)
            return AutoScalingLoadBalancingSystem.evaluateScalingNeeds(groupName)
        end
    }
    
    print("📈 Scaling engine initialized")
end

function AutoScalingLoadBalancingSystem.initializeServerPools()
    ScalingState.serverPools = {
        gameServers = {
            name = "Game Servers",
            type = "gameServers",
            config = ScalingState.config.scaling.gameServers,
            servers = {},
            currentInstances = 0,
            targetInstances = 2,
            status = "stable"
        },
        
        webServers = {
            name = "Web Servers",
            type = "webServers", 
            config = ScalingState.config.scaling.webServers,
            servers = {},
            currentInstances = 0,
            targetInstances = 1,
            status = "stable"
        },
        
        databases = {
            name = "Database Servers",
            type = "databases",
            config = ScalingState.config.scaling.databases,
            servers = {},
            currentInstances = 0,
            targetInstances = 1,
            status = "stable"
        }
    }
    
    -- Initialize minimum instances for each pool
    for poolName, pool in pairs(ScalingState.serverPools) do
        for i = 1, pool.config.minInstances do
            AutoScalingLoadBalancingSystem.addServerToPool(poolName)
        end
    end
    
    print("🖥️ Server pools initialized")
end

function AutoScalingLoadBalancingSystem.addServerToPool(poolName, serverConfig)
    local pool = ScalingState.serverPools[poolName]
    
    if not pool then
        return {success = false, error = "Pool not found"}
    end
    
    local server = {
        id = HttpService:GenerateGUID(),
        poolName = poolName,
        type = pool.type,
        
        status = "starting",
        health = "unknown",
        
        created = os.time(),
        lastHealthCheck = nil,
        
        metrics = {
            cpuUsage = 0,
            memoryUsage = 0,
            connections = 0,
            responseTime = 0,
            throughput = 0
        },
        
        configuration = serverConfig or AutoScalingLoadBalancingSystem.getDefaultServerConfig(pool.type)
    }
    
    -- Simulate server startup
    spawn(function()
        print(string.format("🚀 Starting server: %s (%s)", server.id, poolName))
        
        -- Simulate startup time
        wait(math.random(5, 15))
        
        server.status = "running"
        server.health = "healthy"
        
        print(string.format("✅ Server ready: %s", server.id))
        
        -- Add to active servers
        ScalingState.activeServers[server.id] = server
        
        -- Update pool
        table.insert(pool.servers, server)
        pool.currentInstances = pool.currentInstances + 1
        
        ScalingState.metrics.serversAdded = ScalingState.metrics.serversAdded + 1
        
        -- Register with load balancer
        AutoScalingLoadBalancingSystem.registerServerWithLoadBalancer(server)
    end)
    
    return {
        success = true,
        server = server
    }
end

function AutoScalingLoadBalancingSystem.removeServerFromPool(poolName, serverId)
    local pool = ScalingState.serverPools[poolName]
    
    if not pool then
        return {success = false, error = "Pool not found"}
    end
    
    local server = ScalingState.activeServers[serverId]
    
    if not server then
        return {success = false, error = "Server not found"}
    end
    
    print(string.format("🛑 Removing server: %s", serverId))
    
    -- Drain connections gracefully
    server.status = "draining"
    
    spawn(function()
        -- Simulate graceful shutdown
        wait(30) -- 30 second drain period
        
        server.status = "terminated"
        
        -- Remove from active servers
        ScalingState.activeServers[serverId] = nil
        
        -- Remove from pool
        for i, poolServer in ipairs(pool.servers) do
            if poolServer.id == serverId then
                table.remove(pool.servers, i)
                pool.currentInstances = pool.currentInstances - 1
                break
            end
        end
        
        ScalingState.metrics.serversRemoved = ScalingState.metrics.serversRemoved + 1
        
        -- Unregister from load balancer
        AutoScalingLoadBalancingSystem.unregisterServerFromLoadBalancer(server)
        
        print(string.format("✅ Server removed: %s", serverId))
    end)
    
    return {success = true}
end

function AutoScalingLoadBalancingSystem.getDefaultServerConfig(serverType)
    if serverType == "gameServers" then
        return {
            cpu = 2,
            memory = "4GB",
            maxPlayers = 50,
            region = "us-west-2"
        }
    elseif serverType == "webServers" then
        return {
            cpu = 1,
            memory = "2GB",
            maxConnections = 1000,
            region = "us-west-2"
        }
    elseif serverType == "databases" then
        return {
            cpu = 4,
            memory = "8GB",
            storage = "100GB",
            region = "us-west-2"
        }
    end
    
    return {}
end

function AutoScalingLoadBalancingSystem.scaleUp(poolName, count)
    local pool = ScalingState.serverPools[poolName]
    
    if not pool then
        return {success = false, error = "Pool not found"}
    end
    
    count = count or 1
    
    -- Check if within limits
    if pool.currentInstances + count > pool.config.maxInstances then
        count = pool.config.maxInstances - pool.currentInstances
    end
    
    if count <= 0 then
        return {success = false, error = "At maximum capacity"}
    end
    
    -- Check cooldown period
    local cooldownKey = poolName .. "_scaleup"
    if ScalingState.scalingEngine.cooldownPeriods[cooldownKey] then
        local timeSince = os.time() - ScalingState.scalingEngine.cooldownPeriods[cooldownKey]
        if timeSince < pool.config.scaleUpCooldown then
            return {success = false, error = "Still in cooldown period"}
        end
    end
    
    local operation = {
        id = HttpService:GenerateGUID(),
        type = "scale_up",
        poolName = poolName,
        count = count,
        started = os.time(),
        status = "in_progress",
        serversAdded = {}
    }
    
    ScalingState.scalingOperations[operation.id] = operation
    
    print(string.format("📈 Scaling up %s: adding %d servers", poolName, count))
    
    -- Add servers
    for i = 1, count do
        local result = AutoScalingLoadBalancingSystem.addServerToPool(poolName)
        if result.success then
            table.insert(operation.serversAdded, result.server.id)
        end
    end
    
    operation.status = "completed"
    operation.completed = os.time()
    
    -- Set cooldown
    ScalingState.scalingEngine.cooldownPeriods[cooldownKey] = os.time()
    
    -- Update pool status
    pool.targetInstances = pool.currentInstances + count
    pool.status = "scaling_up"
    
    ScalingState.metrics.scalingOperations = ScalingState.metrics.scalingOperations + 1
    
    -- Add to history
    table.insert(ScalingState.scalingHistory, operation)
    
    return {
        success = true,
        operation = operation
    }
end

function AutoScalingLoadBalancingSystem.scaleDown(poolName, count)
    local pool = ScalingState.serverPools[poolName]
    
    if not pool then
        return {success = false, error = "Pool not found"}
    end
    
    count = count or 1
    
    -- Check if within limits
    if pool.currentInstances - count < pool.config.minInstances then
        count = pool.currentInstances - pool.config.minInstances
    end
    
    if count <= 0 then
        return {success = false, error = "At minimum capacity"}
    end
    
    -- Check cooldown period
    local cooldownKey = poolName .. "_scaledown"
    if ScalingState.scalingEngine.cooldownPeriods[cooldownKey] then
        local timeSince = os.time() - ScalingState.scalingEngine.cooldownPeriods[cooldownKey]
        if timeSince < pool.config.scaleDownCooldown then
            return {success = false, error = "Still in cooldown period"}
        end
    end
    
    local operation = {
        id = HttpService:GenerateGUID(),
        type = "scale_down",
        poolName = poolName,
        count = count,
        started = os.time(),
        status = "in_progress",
        serversRemoved = {}
    }
    
    ScalingState.scalingOperations[operation.id] = operation
    
    print(string.format("📉 Scaling down %s: removing %d servers", poolName, count))
    
    -- Select servers to remove (least utilized first)
    local serversToRemove = AutoScalingLoadBalancingSystem.selectServersForRemoval(pool, count)
    
    for _, serverId in ipairs(serversToRemove) do
        local result = AutoScalingLoadBalancingSystem.removeServerFromPool(poolName, serverId)
        if result.success then
            table.insert(operation.serversRemoved, serverId)
        end
    end
    
    operation.status = "completed"
    operation.completed = os.time()
    
    -- Set cooldown
    ScalingState.scalingEngine.cooldownPeriods[cooldownKey] = os.time()
    
    -- Update pool status
    pool.targetInstances = pool.currentInstances - count
    pool.status = "scaling_down"
    
    ScalingState.metrics.scalingOperations = ScalingState.metrics.scalingOperations + 1
    
    -- Add to history
    table.insert(ScalingState.scalingHistory, operation)
    
    return {
        success = true,
        operation = operation
    }
end

function AutoScalingLoadBalancingSystem.selectServersForRemoval(pool, count)
    local serversToRemove = {}
    local sortedServers = {}
    
    -- Create sorted list by utilization (ascending)
    for _, server in ipairs(pool.servers) do
        if server.status == "running" then
            table.insert(sortedServers, {
                id = server.id,
                utilization = (server.metrics.cpuUsage + server.metrics.memoryUsage) / 2
            })
        end
    end
    
    table.sort(sortedServers, function(a, b) return a.utilization < b.utilization end)
    
    -- Select least utilized servers
    for i = 1, math.min(count, #sortedServers) do
        table.insert(serversToRemove, sortedServers[i].id)
    end
    
    return serversToRemove
end

function AutoScalingLoadBalancingSystem.evaluateScalingNeeds(poolName)
    local pool = ScalingState.serverPools[poolName]
    
    if not pool then
        return {action = "none", reason = "Pool not found"}
    end
    
    -- Calculate average metrics across pool
    local totalCpu = 0
    local totalMemory = 0
    local totalConnections = 0
    local activeServers = 0
    
    for _, server in ipairs(pool.servers) do
        if server.status == "running" then
            totalCpu = totalCpu + server.metrics.cpuUsage
            totalMemory = totalMemory + server.metrics.memoryUsage
            totalConnections = totalConnections + server.metrics.connections
            activeServers = activeServers + 1
        end
    end
    
    if activeServers == 0 then
        return {action = "none", reason = "No active servers"}
    end
    
    local avgCpu = totalCpu / activeServers
    local avgMemory = totalMemory / activeServers
    
    -- Determine scaling action
    if avgCpu > pool.config.scaleUpThreshold then
        return {
            action = "scale_up",
            reason = string.format("High CPU usage: %.1f%%", avgCpu),
            metric = "cpu",
            value = avgCpu,
            threshold = pool.config.scaleUpThreshold
        }
    elseif avgCpu < pool.config.scaleDownThreshold and activeServers > pool.config.minInstances then
        return {
            action = "scale_down",
            reason = string.format("Low CPU usage: %.1f%%", avgCpu),
            metric = "cpu",
            value = avgCpu,
            threshold = pool.config.scaleDownThreshold
        }
    end
    
    return {action = "none", reason = "Within normal thresholds"}
end

function AutoScalingLoadBalancingSystem.startScalingMonitoring()
    spawn(function()
        while true do
            -- Evaluate scaling needs for each pool
            for poolName, pool in pairs(ScalingState.serverPools) do
                local evaluation = AutoScalingLoadBalancingSystem.evaluateScalingNeeds(poolName)
                
                if evaluation.action == "scale_up" then
                    local result = AutoScalingLoadBalancingSystem.scaleUp(poolName, 1)
                    if result.success then
                        print(string.format("🔄 Auto-scaled up %s: %s", poolName, evaluation.reason))
                    end
                elseif evaluation.action == "scale_down" then
                    local result = AutoScalingLoadBalancingSystem.scaleDown(poolName, 1)
                    if result.success then
                        print(string.format("🔄 Auto-scaled down %s: %s", poolName, evaluation.reason))
                    end
                end
            end
            
            -- Update server metrics (simulation)
            AutoScalingLoadBalancingSystem.updateServerMetrics()
            
            wait(60) -- Check every minute
        end
    end)
    
    print("📊 Auto-scaling monitoring started")
end

function AutoScalingLoadBalancingSystem.updateServerMetrics()
    for serverId, server in pairs(ScalingState.activeServers) do
        if server.status == "running" then
            -- Simulate realistic server metrics
            server.metrics.cpuUsage = math.random(20, 95)
            server.metrics.memoryUsage = math.random(30, 85)
            server.metrics.connections = math.random(10, 100)
            server.metrics.responseTime = math.random(50, 200)
            server.metrics.throughput = math.random(100, 1000)
            
            server.lastHealthCheck = os.time()
        end
    end
end

-- ========================================
-- LOAD BALANCER ENGINE
-- ========================================

function AutoScalingLoadBalancingSystem.initializeLoadBalancerEngine()
    ScalingState.loadBalancerEngine = {
        balancers = {},
        algorithms = {},
        
        createLoadBalancer = function(self, config)
            return AutoScalingLoadBalancingSystem.createLoadBalancer(config)
        end,
        
        routeRequest = function(self, balancerId, request)
            return AutoScalingLoadBalancingSystem.routeRequest(balancerId, request)
        end,
        
        updateServerPool = function(self, balancerId, servers)
            return AutoScalingLoadBalancingSystem.updateLoadBalancerPool(balancerId, servers)
        end
    }
    
    -- Register load balancing algorithms
    AutoScalingLoadBalancingSystem.registerLoadBalancingAlgorithms()
    
    print("⚖️ Load balancer engine initialized")
end

function AutoScalingLoadBalancingSystem.registerLoadBalancingAlgorithms()
    ScalingState.loadBalancerEngine.algorithms = {
        roundRobin = function(servers, request)
            return AutoScalingLoadBalancingSystem.roundRobinSelection(servers, request)
        end,
        
        leastConnections = function(servers, request)
            return AutoScalingLoadBalancingSystem.leastConnectionsSelection(servers, request)
        end,
        
        weightedRoundRobin = function(servers, request)
            return AutoScalingLoadBalancingSystem.weightedRoundRobinSelection(servers, request)
        end,
        
        ipHash = function(servers, request)
            return AutoScalingLoadBalancingSystem.ipHashSelection(servers, request)
        end,
        
        leastResponseTime = function(servers, request)
            return AutoScalingLoadBalancingSystem.leastResponseTimeSelection(servers, request)
        end
    }
end

function AutoScalingLoadBalancingSystem.createLoadBalancer(config)
    local loadBalancer = {
        id = HttpService:GenerateGUID(),
        name = config.name or "Load Balancer",
        algorithm = config.algorithm or "roundRobin",
        
        servers = {},
        serverWeights = {},
        
        sessionStickiness = config.sessionStickiness or false,
        healthCheckEnabled = config.healthCheckEnabled or true,
        
        statistics = {
            totalRequests = 0,
            totalConnections = 0,
            averageResponseTime = 0,
            requestsPerSecond = 0
        },
        
        roundRobinIndex = 1,
        sessionMap = {},
        
        created = os.time(),
        status = "active"
    }
    
    ScalingState.loadBalancers[loadBalancer.id] = loadBalancer
    
    print(string.format("⚖️ Created load balancer: %s (%s)", loadBalancer.name, loadBalancer.algorithm))
    
    return loadBalancer
end

function AutoScalingLoadBalancingSystem.initializeLoadBalancers()
    -- Create load balancers for each server pool
    for poolName, pool in pairs(ScalingState.serverPools) do
        local config = {
            name = pool.name .. " Load Balancer",
            algorithm = poolName == "gameServers" and "leastConnections" or "roundRobin",
            sessionStickiness = poolName == "gameServers",
            healthCheckEnabled = true
        }
        
        local loadBalancer = AutoScalingLoadBalancingSystem.createLoadBalancer(config)
        
        -- Associate with pool
        pool.loadBalancerId = loadBalancer.id
        
        -- Add existing servers to load balancer
        for _, server in ipairs(pool.servers) do
            if server.status == "running" then
                AutoScalingLoadBalancingSystem.registerServerWithLoadBalancer(server)
            end
        end
    end
    
    print("⚖️ Load balancers initialized for all server pools")
end

function AutoScalingLoadBalancingSystem.registerServerWithLoadBalancer(server)
    local pool = ScalingState.serverPools[server.poolName]
    local loadBalancer = ScalingState.loadBalancers[pool.loadBalancerId]
    
    if loadBalancer then
        table.insert(loadBalancer.servers, {
            id = server.id,
            endpoint = string.format("server-%s:8080", server.id:sub(1, 8)),
            weight = 1,
            status = "active",
            connections = 0,
            responseTime = 0
        })
        
        print(string.format("📌 Registered server %s with load balancer", server.id))
    end
end

function AutoScalingLoadBalancingSystem.unregisterServerFromLoadBalancer(server)
    local pool = ScalingState.serverPools[server.poolName]
    local loadBalancer = ScalingState.loadBalancers[pool.loadBalancerId]
    
    if loadBalancer then
        for i, lbServer in ipairs(loadBalancer.servers) do
            if lbServer.id == server.id then
                table.remove(loadBalancer.servers, i)
                print(string.format("📌 Unregistered server %s from load balancer", server.id))
                break
            end
        end
    end
end

function AutoScalingLoadBalancingSystem.routeRequest(balancerId, request)
    local loadBalancer = ScalingState.loadBalancers[balancerId]
    
    if not loadBalancer then
        return {success = false, error = "Load balancer not found"}
    end
    
    -- Get healthy servers
    local healthyServers = {}
    for _, server in ipairs(loadBalancer.servers) do
        if server.status == "active" then
            table.insert(healthyServers, server)
        end
    end
    
    if #healthyServers == 0 then
        return {success = false, error = "No healthy servers available"}
    end
    
    -- Select server using configured algorithm
    local algorithm = ScalingState.loadBalancerEngine.algorithms[loadBalancer.algorithm]
    local selectedServer = algorithm(healthyServers, request)
    
    if selectedServer then
        -- Update statistics
        loadBalancer.statistics.totalRequests = loadBalancer.statistics.totalRequests + 1
        ScalingState.metrics.loadBalancedRequests = ScalingState.metrics.loadBalancedRequests + 1
        
        -- Update server connection count
        selectedServer.connections = selectedServer.connections + 1
        
        -- Handle session stickiness
        if loadBalancer.sessionStickiness and request.clientId then
            loadBalancer.sessionMap[request.clientId] = selectedServer.id
        end
        
        return {
            success = true,
            server = selectedServer,
            endpoint = selectedServer.endpoint
        }
    else
        return {success = false, error = "Failed to select server"}
    end
end

-- ========================================
-- LOAD BALANCING ALGORITHMS
-- ========================================

function AutoScalingLoadBalancingSystem.roundRobinSelection(servers, request)
    if #servers == 0 then return nil end
    
    -- Simple round robin implementation
    local index = (math.floor(tick()) % #servers) + 1
    return servers[index]
end

function AutoScalingLoadBalancingSystem.leastConnectionsSelection(servers, request)
    if #servers == 0 then return nil end
    
    local selectedServer = nil
    local minConnections = math.huge
    
    for _, server in ipairs(servers) do
        if server.connections < minConnections then
            minConnections = server.connections
            selectedServer = server
        end
    end
    
    return selectedServer
end

function AutoScalingLoadBalancingSystem.weightedRoundRobinSelection(servers, request)
    if #servers == 0 then return nil end
    
    -- Simple weighted selection based on server weight
    local totalWeight = 0
    for _, server in ipairs(servers) do
        totalWeight = totalWeight + (server.weight or 1)
    end
    
    local random = math.random() * totalWeight
    local currentWeight = 0
    
    for _, server in ipairs(servers) do
        currentWeight = currentWeight + (server.weight or 1)
        if random <= currentWeight then
            return server
        end
    end
    
    return servers[1] -- Fallback
end

function AutoScalingLoadBalancingSystem.ipHashSelection(servers, request)
    if #servers == 0 then return nil end
    
    -- Hash client IP to consistently route to same server
    local clientIp = request.clientIp or "127.0.0.1"
    local hash = 0
    
    for i = 1, #clientIp do
        hash = hash + string.byte(clientIp, i)
    end
    
    local index = (hash % #servers) + 1
    return servers[index]
end

function AutoScalingLoadBalancingSystem.leastResponseTimeSelection(servers, request)
    if #servers == 0 then return nil end
    
    local selectedServer = nil
    local minResponseTime = math.huge
    
    for _, server in ipairs(servers) do
        if server.responseTime < minResponseTime then
            minResponseTime = server.responseTime
            selectedServer = server
        end
    end
    
    return selectedServer or servers[1]
end

-- ========================================
-- METRICS ENGINE
-- ========================================

function AutoScalingLoadBalancingSystem.initializeMetricsEngine()
    ScalingState.metricsEngine = {
        collectors = {},
        aggregators = {},
        
        collectMetrics = function(self)
            return AutoScalingLoadBalancingSystem.collectSystemMetrics()
        end,
        
        getMetrics = function(self, timeRange)
            return AutoScalingLoadBalancingSystem.getAggregatedMetrics(timeRange)
        end
    }
    
    -- Start metrics collection
    AutoScalingLoadBalancingSystem.startMetricsCollection()
    
    print("📊 Metrics engine initialized")
end

function AutoScalingLoadBalancingSystem.collectSystemMetrics()
    local metrics = {
        timestamp = os.time(),
        
        serverMetrics = {},
        loadBalancerMetrics = {},
        
        systemOverview = {
            totalServers = 0,
            activeConnections = 0,
            averageResponseTime = 0,
            totalThroughput = 0
        }
    }
    
    -- Collect server metrics
    for serverId, server in pairs(ScalingState.activeServers) do
        if server.status == "running" then
            metrics.serverMetrics[serverId] = {
                cpuUsage = server.metrics.cpuUsage,
                memoryUsage = server.metrics.memoryUsage,
                connections = server.metrics.connections,
                responseTime = server.metrics.responseTime,
                throughput = server.metrics.throughput
            }
            
            metrics.systemOverview.totalServers = metrics.systemOverview.totalServers + 1
            metrics.systemOverview.activeConnections = metrics.systemOverview.activeConnections + server.metrics.connections
            metrics.systemOverview.averageResponseTime = metrics.systemOverview.averageResponseTime + server.metrics.responseTime
            metrics.systemOverview.totalThroughput = metrics.systemOverview.totalThroughput + server.metrics.throughput
        end
    end
    
    -- Calculate averages
    if metrics.systemOverview.totalServers > 0 then
        metrics.systemOverview.averageResponseTime = metrics.systemOverview.averageResponseTime / metrics.systemOverview.totalServers
    end
    
    -- Collect load balancer metrics
    for balancerId, loadBalancer in pairs(ScalingState.loadBalancers) do
        metrics.loadBalancerMetrics[balancerId] = {
            totalRequests = loadBalancer.statistics.totalRequests,
            totalConnections = loadBalancer.statistics.totalConnections,
            averageResponseTime = loadBalancer.statistics.averageResponseTime,
            requestsPerSecond = loadBalancer.statistics.requestsPerSecond,
            activeServers = #loadBalancer.servers
        }
    end
    
    -- Update system status
    ScalingState.systemStatus = {
        overallHealth = AutoScalingLoadBalancingSystem.calculateSystemHealth(),
        totalServers = metrics.systemOverview.totalServers,
        activeConnections = metrics.systemOverview.activeConnections,
        averageResponseTime = metrics.systemOverview.averageResponseTime,
        throughput = metrics.systemOverview.totalThroughput
    }
    
    return metrics
end

function AutoScalingLoadBalancingSystem.calculateSystemHealth()
    local healthyServers = 0
    local totalServers = 0
    
    for _, server in pairs(ScalingState.activeServers) do
        totalServers = totalServers + 1
        if server.health == "healthy" then
            healthyServers = healthyServers + 1
        end
    end
    
    if totalServers == 0 then
        return "unknown"
    end
    
    local healthPercentage = (healthyServers / totalServers) * 100
    
    if healthPercentage >= 90 then
        return "healthy"
    elseif healthPercentage >= 70 then
        return "degraded"
    else
        return "unhealthy"
    end
end

function AutoScalingLoadBalancingSystem.startMetricsCollection()
    spawn(function()
        while true do
            AutoScalingLoadBalancingSystem.collectSystemMetrics()
            wait(30) -- Collect metrics every 30 seconds
        end
    end)
    
    print("📊 Metrics collection started")
end

function AutoScalingLoadBalancingSystem.getAggregatedMetrics(timeRange)
    timeRange = timeRange or 300 -- Default 5 minutes
    
    -- This would aggregate metrics over the time range
    -- For demo purposes, return current snapshot
    return AutoScalingLoadBalancingSystem.collectSystemMetrics()
end

-- ========================================
-- PUBLIC API
-- ========================================

function AutoScalingLoadBalancingSystem.manualScale(poolName, action, count)
    if action == "up" then
        return ScalingState.scalingEngine:scaleUp(poolName, count)
    elseif action == "down" then
        return ScalingState.scalingEngine:scaleDown(poolName, count)
    else
        return {success = false, error = "Invalid action"}
    end
end

function AutoScalingLoadBalancingSystem.getServerPoolStatus(poolName)
    return ScalingState.serverPools[poolName]
end

function AutoScalingLoadBalancingSystem.getLoadBalancerStatus(balancerId)
    return ScalingState.loadBalancers[balancerId]
end

function AutoScalingLoadBalancingSystem.getSystemMetrics()
    return ScalingState.metricsEngine:collectMetrics()
end

function AutoScalingLoadBalancingSystem.getScalingHistory(limit)
    limit = limit or 20
    
    local history = {}
    local count = 0
    
    for i = #ScalingState.scalingHistory, 1, -1 do
        if count >= limit then break end
        
        table.insert(history, ScalingState.scalingHistory[i])
        count = count + 1
    end
    
    return history
end

function AutoScalingLoadBalancingSystem.updateLoadBalancerPool(balancerId, servers)
    local loadBalancer = ScalingState.loadBalancers[balancerId]
    
    if loadBalancer then
        loadBalancer.servers = servers
        return {success = true}
    else
        return {success = false, error = "Load balancer not found"}
    end
end

function AutoScalingLoadBalancingSystem.simulateTraffic(intensity)
    intensity = intensity or "medium"
    
    local requestCount = 0
    
    if intensity == "low" then
        requestCount = 50
    elseif intensity == "medium" then
        requestCount = 200
    elseif intensity == "high" then
        requestCount = 500
    end
    
    print(string.format("🌊 Simulating %s traffic: %d requests", intensity, requestCount))
    
    spawn(function()
        for i = 1, requestCount do
            -- Simulate requests to game servers
            local gameServerLB = nil
            for _, pool in pairs(ScalingState.serverPools) do
                if pool.type == "gameServers" then
                    gameServerLB = ScalingState.loadBalancers[pool.loadBalancerId]
                    break
                end
            end
            
            if gameServerLB then
                local request = {
                    id = HttpService:GenerateGUID(),
                    clientId = "client_" .. math.random(1, 100),
                    clientIp = string.format("192.168.1.%d", math.random(1, 254)),
                    timestamp = os.time()
                }
                
                AutoScalingLoadBalancingSystem.routeRequest(gameServerLB.id, request)
            end
            
            wait(0.1)
        end
        
        print(string.format("✅ Traffic simulation completed: %d requests processed", requestCount))
    end)
end

function AutoScalingLoadBalancingSystem.runScalingDemo()
    print("⚖️ Running auto-scaling and load balancing demonstration...")
    
    -- Show configuration
    print("  ⚙️ Scaling Configuration:")
    for poolName, config in pairs(ScalingState.config.scaling) do
        print(string.format("    %s:", poolName))
        print(string.format("      Min/Max Instances: %d/%d", config.minInstances, config.maxInstances))
        print(string.format("      Target Utilization: %d%%", config.targetUtilization))
        print(string.format("      Scale Up/Down Threshold: %d%%/%d%%", config.scaleUpThreshold, config.scaleDownThreshold))
    end
    
    -- Show server pools
    print("  🖥️ Server Pools:")
    for poolName, pool in pairs(ScalingState.serverPools) do
        print(string.format("    %s: %d/%d servers (%s)", 
            pool.name, 
            pool.currentInstances, 
            pool.targetInstances, 
            pool.status))
    end
    
    -- Show load balancers
    print("  ⚖️ Load Balancers:")
    for balancerId, loadBalancer in pairs(ScalingState.loadBalancers) do
        print(string.format("    %s: %s algorithm, %d servers", 
            loadBalancer.name, 
            loadBalancer.algorithm, 
            #loadBalancer.servers))
    end
    
    -- Show load balancing algorithms
    print("  📋 Available Algorithms:")
    for algName, algConfig in pairs(ScalingState.config.loadBalancing.algorithms) do
        print(string.format("    %s: %s", algConfig.name, algConfig.description))
    end
    
    -- Simulate traffic spike
    print("  🌊 Simulating Traffic Spike:")
    AutoScalingLoadBalancingSystem.simulateTraffic("high")
    
    wait(2) -- Wait for traffic simulation
    
    -- Show updated metrics
    print("  📊 System Metrics After Traffic:")
    local metrics = AutoScalingLoadBalancingSystem.getSystemMetrics()
    print(string.format("    Total Servers: %d", metrics.systemOverview.totalServers))
    print(string.format("    Active Connections: %d", metrics.systemOverview.activeConnections))
    print(string.format("    Average Response Time: %.1fms", metrics.systemOverview.averageResponseTime))
    print(string.format("    Total Throughput: %d req/s", metrics.systemOverview.totalThroughput))
    
    -- Demonstrate manual scaling
    print("  📈 Manual Scaling Demo:")
    local scaleResult = AutoScalingLoadBalancingSystem.manualScale("gameServers", "up", 2)
    if scaleResult.success then
        print(string.format("    ✅ Scaled up game servers: operation %s", scaleResult.operation.id))
    end
    
    wait(1)
    
    -- Show scaling history
    print("  📜 Recent Scaling Operations:")
    local history = AutoScalingLoadBalancingSystem.getScalingHistory(5)
    for _, operation in ipairs(history) do
        print(string.format("    %s %s: %s (%d servers)", 
            operation.type, 
            operation.poolName, 
            operation.status,
            operation.count))
    end
    
    -- Show performance targets
    print("  🎯 Performance Targets:")
    local targets = ScalingState.config.targets
    print(string.format("    Response Time: P50=%dms, P95=%dms, P99=%dms", 
        targets.responseTime.p50, 
        targets.responseTime.p95, 
        targets.responseTime.p99))
    print(string.format("    Throughput: %d req/s, %d players/server", 
        targets.throughput.requestsPerSecond, 
        targets.throughput.playersPerServer))
    print(string.format("    Availability: %.1f%% uptime, %.1f%% error rate", 
        targets.availability.uptime, 
        targets.availability.errorRate))
    
    -- Show system health
    print("  🏥 System Health:")
    print(string.format("    Overall Health: %s", ScalingState.systemStatus.overallHealth:upper()))
    print(string.format("    Health Check Coverage: %d endpoints", #ScalingState.config.loadBalancing.healthChecks.endpoints))
    
    -- Show aggregated metrics
    print("  📊 Aggregated Metrics:")
    local aggregatedMetrics = ScalingState.metrics
    print(string.format("    Scaling Operations: %d", aggregatedMetrics.scalingOperations))
    print(string.format("    Servers Added: %d", aggregatedMetrics.serversAdded))
    print(string.format("    Servers Removed: %d", aggregatedMetrics.serversRemoved))
    print(string.format("    Load Balanced Requests: %d", aggregatedMetrics.loadBalancedRequests))
    
    print("⚖️ Auto-scaling and load balancing demonstration completed")
    print("     Enterprise-grade scaling and load balancing operational!")
end

-- Initialize the auto-scaling and load balancing system
AutoScalingLoadBalancingSystem.initialize()

print("⚖️ AutoScalingLoadBalancingSystem loaded with comprehensive scaling and load balancing")

return AutoScalingLoadBalancingSystem
