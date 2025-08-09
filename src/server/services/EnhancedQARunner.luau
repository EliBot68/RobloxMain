-- EnhancedQARunner.luau
-- Enhanced QA runner that integrates performance monitoring with existing health checks

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local SafeRequire = require(ReplicatedStorage.Shared.utils.SafeRequire)

local EnhancedQARunner = {}

-- Try to load existing QA runner
local existingQARunner = nil
pcall(function()
    existingQARunner = require(game.ServerScriptService.QATestRunner)
end)

-- Try to load performance service
local PerformanceService = nil
pcall(function()
    PerformanceService = _G.PerformanceService or require(game.ServerScriptService.Server.services.PerformanceService)
end)

-- Enhanced health check that combines QA and performance data
function EnhancedQARunner.runComprehensiveHealthCheck()
    local startTime = tick()
    local results = {
        timestamp = startTime,
        qa = nil,
        performance = nil,
        integration = {
            status = "UNKNOWN",
            score = 0,
            issues = {},
            recommendations = {}
        }
    }
    
    print("🔍 Starting Enhanced QA Health Check...")
    print("=" .. string.rep("=", 50))
    
    -- Run existing QA health check
    if existingQARunner and existingQARunner.runHealthCheck then
        print("📋 Running Traditional QA Health Check...")
        local qaSuccess, qaResults = pcall(existingQARunner.runHealthCheck, existingQARunner)
        
        if qaSuccess then
            results.qa = qaResults
            print("✅ Traditional QA Check: " .. (qaResults.overallStatus or "UNKNOWN"))
        else
            results.qa = {
                overallStatus = "ERROR",
                error = tostring(qaResults),
                services = {}
            }
            print("❌ Traditional QA Check Failed: " .. tostring(qaResults))
        end
    else
        print("⚠️  Traditional QA Runner not available")
        results.qa = {
            overallStatus = "UNAVAILABLE",
            services = {}
        }
    end
    
    -- Run performance health check
    if PerformanceService and PerformanceService.getHealthReport then
        print("📊 Running Performance Health Check...")
        local perfSuccess, perfResults = pcall(PerformanceService.getHealthReport, PerformanceService)
        
        if perfSuccess then
            results.performance = perfResults
            print("✅ Performance Check: " .. (perfResults.overall or "UNKNOWN"))
        else
            results.performance = {
                overall = "ERROR",
                error = tostring(perfResults)
            }
            print("❌ Performance Check Failed: " .. tostring(perfResults))
        end
    else
        print("⚠️  Performance Service not available")
        results.performance = {
            overall = "UNAVAILABLE"
        }
    end
    
    -- Calculate integrated health score
    local score = 100
    local issues = {}
    local recommendations = {}
    
    -- QA Component Analysis (40% weight)
    if results.qa then
        if results.qa.overallStatus == "FAIL" then
            score = score - 40
            table.insert(issues, "Critical QA health check failures")
            table.insert(recommendations, "Review and fix failing QA services immediately")
        elseif results.qa.overallStatus == "WARN" then
            score = score - 20
            table.insert(issues, "QA health check warnings detected")
            table.insert(recommendations, "Investigate QA warnings to prevent issues")
        elseif results.qa.overallStatus == "ERROR" or results.qa.overallStatus == "UNAVAILABLE" then
            score = score - 30
            table.insert(issues, "QA health check system unavailable")
            table.insert(recommendations, "Restore QA health check functionality")
        end
    end
    
    -- Performance Component Analysis (40% weight)
    if results.performance then
        if results.performance.overall == "critical" then
            score = score - 40
            table.insert(issues, "Critical performance issues detected")
            table.insert(recommendations, "Optimize performance immediately - check FPS, memory, and services")
        elseif results.performance.overall == "warning" then
            score = score - 20
            table.insert(issues, "Performance warnings detected")
            table.insert(recommendations, "Monitor performance metrics and optimize proactively")
        elseif results.performance.overall == "ERROR" or results.performance.overall == "UNAVAILABLE" then
            score = score - 30
            table.insert(issues, "Performance monitoring system unavailable")
            table.insert(recommendations, "Restore performance monitoring functionality")
        end
        
        -- Specific performance issues
        if results.performance.fps and results.performance.fps.status == "critical" then
            table.insert(issues, string.format("Critical FPS: %d fps", results.performance.fps.current or 0))
            table.insert(recommendations, "Investigate FPS drops - check for expensive operations")
        end
        
        if results.performance.memory and results.performance.memory.status == "critical" then
            table.insert(issues, string.format("Critical memory usage: %s", results.performance.memory.current or "N/A"))
            table.insert(recommendations, "Investigate memory leaks and optimize memory usage")
        end
    end
    
    -- Service Integration Analysis (20% weight)
    local serviceIssues = 0
    if results.qa and results.qa.services then
        for serviceName, serviceStatus in pairs(results.qa.services) do
            if serviceStatus.status == "FAIL" then
                serviceIssues = serviceIssues + 1
                table.insert(issues, string.format("Service %s failed QA check", serviceName))
            end
        end
    end
    
    if results.performance and results.performance.services then
        for serviceName, serviceStatus in pairs(results.performance.services) do
            if not serviceStatus.healthy then
                serviceIssues = serviceIssues + 1
                table.insert(issues, string.format("Service %s unhealthy in performance check", serviceName))
            end
        end
    end
    
    if serviceIssues > 3 then
        score = score - 20
        table.insert(recommendations, "Multiple service failures detected - review service architecture")
    elseif serviceIssues > 0 then
        score = score - (serviceIssues * 3)
        table.insert(recommendations, "Some services have issues - investigate and fix")
    end
    
    -- Determine overall status
    score = math.max(0, score)
    results.integration.score = score
    results.integration.issues = issues
    results.integration.recommendations = recommendations
    
    if score >= 85 then
        results.integration.status = "EXCELLENT"
    elseif score >= 70 then
        results.integration.status = "GOOD"
    elseif score >= 50 then
        results.integration.status = "WARNING"
    elseif score >= 30 then
        results.integration.status = "POOR"
    else
        results.integration.status = "CRITICAL"
    end
    
    local executionTime = tick() - startTime
    results.executionTime = executionTime
    
    -- Print comprehensive report
    EnhancedQARunner.printComprehensiveReport(results)
    
    return results
end

-- Print detailed comprehensive report
function EnhancedQARunner.printComprehensiveReport(results)
    print("\n" .. string.rep("=", 60))
    print("  COMPREHENSIVE SYSTEM HEALTH REPORT")
    print(string.rep("=", 60))
    
    -- Overall Status
    local statusEmoji = {
        EXCELLENT = "🟢",
        GOOD = "🔵", 
        WARNING = "🟡",
        POOR = "🟠",
        CRITICAL = "🔴",
        UNKNOWN = "⚪"
    }
    
    print(string.format("%s Overall Health: %s (Score: %d/100)", 
        statusEmoji[results.integration.status] or "⚪",
        results.integration.status,
        results.integration.score))
    
    print(string.format("⏱️  Execution Time: %.3f seconds", results.executionTime or 0))
    print("")
    
    -- QA Results
    print("📋 Traditional QA Health Check:")
    if results.qa then
        print(string.format("   Status: %s", results.qa.overallStatus or "UNKNOWN"))
        if results.qa.services then
            local qaServices = 0
            local qaFailed = 0
            for serviceName, serviceStatus in pairs(results.qa.services) do
                qaServices = qaServices + 1
                if serviceStatus.status == "FAIL" then
                    qaFailed = qaFailed + 1
                end
            end
            print(string.format("   Services: %d total, %d failed", qaServices, qaFailed))
        end
    else
        print("   Status: UNAVAILABLE")
    end
    print("")
    
    -- Performance Results
    print("📊 Performance Health Check:")
    if results.performance then
        print(string.format("   Overall: %s", results.performance.overall or "UNKNOWN"))
        if results.performance.fps then
            print(string.format("   FPS: %d (%s)", results.performance.fps.current or 0, results.performance.fps.status or "unknown"))
        end
        if results.performance.memory then
            print(string.format("   Memory: %s (%s)", results.performance.memory.current or "N/A", results.performance.memory.status or "unknown"))
        end
        if results.performance.ping then
            print(string.format("   Ping: %dms (%s)", results.performance.ping.current or 0, results.performance.ping.status or "unknown"))
        end
    else
        print("   Status: UNAVAILABLE")
    end
    print("")
    
    -- Issues and Recommendations
    if #results.integration.issues > 0 then
        print("⚠️  Issues Detected:")
        for i, issue in ipairs(results.integration.issues) do
            print(string.format("   %d. %s", i, issue))
        end
        print("")
    end
    
    if #results.integration.recommendations > 0 then
        print("💡 Recommendations:")
        for i, recommendation in ipairs(results.integration.recommendations) do
            print(string.format("   %d. %s", i, recommendation))
        end
        print("")
    end
    
    -- Final Verdict
    if results.integration.status == "EXCELLENT" then
        print("🎉 SYSTEM STATUS: EXCELLENT")
        print("   All systems operating optimally!")
    elseif results.integration.status == "GOOD" then
        print("✅ SYSTEM STATUS: GOOD")
        print("   Systems operating well with minor issues.")
    elseif results.integration.status == "WARNING" then
        print("⚠️  SYSTEM STATUS: WARNING")
        print("   Some issues detected. Monitor closely.")
    elseif results.integration.status == "POOR" then
        print("🚨 SYSTEM STATUS: POOR")
        print("   Significant issues detected. Take action soon.")
    else
        print("🆘 SYSTEM STATUS: CRITICAL")
        print("   Critical issues detected! Immediate action required!")
    end
    
    print(string.rep("=", 60))
end

-- Quick health check (simplified version)
function EnhancedQARunner.quickHealthCheck()
    print("⚡ Quick Health Check...")
    
    local issues = {}
    local status = "GOOD"
    
    -- Check QA
    if existingQARunner and existingQARunner.runHealthCheck then
        local qaSuccess, qaResults = pcall(existingQARunner.runHealthCheck, existingQARunner)
        if not qaSuccess or (qaResults and qaResults.overallStatus == "FAIL") then
            table.insert(issues, "QA Check Failed")
            status = "WARNING"
        end
    end
    
    -- Check Performance
    if PerformanceService and PerformanceService.getHealthReport then
        local perfSuccess, perfResults = pcall(PerformanceService.getHealthReport, PerformanceService)
        if perfSuccess and perfResults then
            if perfResults.overall == "critical" then
                table.insert(issues, "Critical Performance Issues")
                status = "CRITICAL"
            elseif perfResults.overall == "warning" and status ~= "CRITICAL" then
                table.insert(issues, "Performance Warnings")
                status = "WARNING"
            end
        end
    end
    
    print(string.format("Status: %s", status))
    if #issues > 0 then
        print("Issues: " .. table.concat(issues, ", "))
    else
        print("No issues detected")
    end
    
    return {
        status = status,
        issues = issues,
        timestamp = tick()
    }
end

-- Continuous monitoring function
function EnhancedQARunner.startContinuousMonitoring(interval)
    interval = interval or 300 -- Default 5 minutes
    
    print(string.format("🔄 Starting continuous monitoring (every %d seconds)...", interval))
    
    -- Event-driven monitoring with adaptive intervals
    local monitoringEvent = Instance.new("BindableEvent")
    
    local function scheduleNextCheck()
        local adaptiveInterval = interval
        
        -- Get current system status to adapt interval
        local quickCheck = EnhancedQARunner.quickHealthCheck()
        if quickCheck.status == "CRITICAL" then
            adaptiveInterval = interval * 0.5 -- Check more frequently for critical issues
        elseif quickCheck.status == "HEALTHY" then
            adaptiveInterval = interval * 2 -- Check less frequently when healthy
        end
        
        task.spawn(function()
            task.wait(adaptiveInterval)
            monitoringEvent:Fire()
        end)
    end
    
    monitoringEvent.Event:Connect(function()
        print("\n⏰ Scheduled Health Check")
        local results = EnhancedQARunner.quickHealthCheck()
        
        -- Alert on critical issues
        if results.status == "CRITICAL" then
            print("🚨 CRITICAL ALERT: " .. table.concat(results.issues, ", "))
            -- Could integrate with alerting system here
        end
        
        -- Schedule next check
        scheduleNextCheck()
    end)
    
    -- Start monitoring
    scheduleNextCheck()
    
    return monitoringEvent -- Return event for control
end

-- Export functions for backward compatibility with existing QA runner
if existingQARunner then
    -- Preserve existing QA runner functions
    for funcName, func in pairs(existingQARunner) do
        if not EnhancedQARunner[funcName] then
            EnhancedQARunner[funcName] = func
        end
    end
end

-- Override the health check function with enhanced version
EnhancedQARunner.runHealthCheck = EnhancedQARunner.runComprehensiveHealthCheck

-- Global access
_G.EnhancedQARunner = EnhancedQARunner

return EnhancedQARunner
