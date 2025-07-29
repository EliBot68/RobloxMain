# Performance Monitoring System Documentation

## Overview

The Performance Monitoring System provides comprehensive real-time monitoring of FPS, memory usage, network latency, and service health with remote logging capabilities. It integrates seamlessly with the existing QA health check infrastructure to provide unified system monitoring.

## System Architecture

### Core Components

1. **PerformanceMonitoringService** - Core monitoring logic and metrics collection
2. **PerformanceService** - Server-side service orchestration and client management  
3. **PerformanceMonitorUI** - Client-side user interface and visualization
4. **EnhancedQARunner** - Integrated QA and performance health checking
5. **Remote Events Integration** - Communication layer for real-time updates

## Features

### 📊 Real-Time Metrics
- **FPS Monitoring**: Current, average, min/max frame rates with performance alerts
- **Memory Tracking**: Current usage, peak consumption, trend analysis
- **Network Latency**: Ping monitoring with connection quality assessment
- **Service Health**: Automated health checks for critical game services

### 🚨 Intelligent Alerting
- **Threshold-Based Alerts**: Configurable warning and critical thresholds
- **Client Notifications**: Real-time performance alerts to players and admins
- **Remote Logging**: Mock interfaces for external monitoring systems
- **Auto-Recovery Suggestions**: Intelligent recommendations for performance issues

### 🎛️ Administrative Tools
- **Performance Dashboard**: Real-time UI with minimizable interface
- **Health Reports**: Comprehensive system status reports
- **Metrics Reset**: Clear historical data for fresh monitoring
- **Configuration Management**: Runtime adjustment of monitoring parameters

## Installation and Setup

### 1. File Structure
```
src/
├── shared/
│   └── services/
│       └── PerformanceMonitoringService.luau
├── server/
│   ├── services/
│   │   ├── PerformanceService.luau
│   │   └── EnhancedQARunner.luau
│   └── test/
│       └── PerformanceMonitoringServiceTest.luau
└── client/
    └── ui/
        └── PerformanceMonitorUI.luau
```

### 2. Remote Events Setup
The system automatically creates the following RemoteEvents:
- `RequestPerformanceReport` - Client requests for performance data
- `PerformanceReportUpdated` - Server sends performance updates
- `PerformanceAlert` - Critical performance notifications
- `ShowPerformanceUI` / `HidePerformanceUI` - UI visibility controls
- `RequestHealthCheck` / `HealthCheckResult` - Health check communication

### 3. Auto-Initialization
All services auto-initialize when required. No manual setup required beyond file placement.

## Usage Guide

### 🖥️ Client-Side Interface

#### Accessing the Performance Monitor
```lua
-- Keyboard shortcut: Ctrl+P
-- Or programmatically:
local PerformanceMonitorUI = require(path.to.PerformanceMonitorUI)
PerformanceMonitorUI.show()
```

#### UI Components
- **Minimized View**: Always-visible performance indicator in top-right corner
- **Expanded View**: Detailed metrics display with FPS, memory, ping, and status
- **Alert System**: Prominent notifications for performance issues

### 🔧 Server-Side Administration

#### Running Health Checks
```lua
-- Quick health check
local PerformanceService = _G.PerformanceService
local quickResults = PerformanceService.getHealthReport()

-- Comprehensive health check (includes QA integration)
local EnhancedQARunner = _G.EnhancedQARunner
local comprehensiveResults = EnhancedQARunner.runComprehensiveHealthCheck()
```

#### Admin Commands
```lua
-- Show performance UI to specific player
PerformanceService.handleAdminCommand(player, "perf_show")

-- Generate detailed report
PerformanceService.handleAdminCommand(player, "perf_report")

-- Reset metrics
PerformanceService.handleAdminCommand(player, "perf_reset")

-- Update configuration
PerformanceService.handleAdminCommand(player, "perf_config", {
    FPS_WARNING_THRESHOLD = 25,
    MEMORY_WARNING_MB = 600
})
```

### 🧪 Testing Integration

#### Unit Testing
```lua
-- Run performance monitoring tests
local CriticalSystemsTestRunner = require(path.to.CriticalSystemsTestRunner)
local results = CriticalSystemsTestRunner.runAllTests()

-- Performance tests are included in the critical systems suite
-- 20 comprehensive test cases covering all functionality
```

#### Integration Testing
```lua
-- Test performance + QA integration
local EnhancedQARunner = require(path.to.EnhancedQARunner)
local results = EnhancedQARunner.runComprehensiveHealthCheck()
```

## Configuration

### Performance Thresholds
```lua
local CONFIG = {
    FPS_WARNING_THRESHOLD = 30,     -- Below this triggers warnings
    FPS_CRITICAL_THRESHOLD = 15,    -- Below this triggers critical alerts
    MEMORY_WARNING_MB = 500,        -- Above this triggers warnings  
    MEMORY_CRITICAL_MB = 800,       -- Above this triggers critical alerts
    PING_WARNING_MS = 200,          -- Above this triggers warnings
    PING_CRITICAL_MS = 500,         -- Above this triggers critical alerts
    LOG_INTERVAL = 60,              -- Seconds between periodic reports
    REMOTE_LOG_ENABLED = true,      -- Enable remote logging
    DETAILED_LOGGING = false        -- Enable verbose console logging
}
```

### UI Configuration
```lua
local UI_CONFIG = {
    UPDATE_INTERVAL = 1,            -- Seconds between UI updates
    AUTO_HIDE_ALERTS = true,        -- Auto-hide performance alerts
    ALERT_DURATION = 5              -- Seconds to show alerts
}
```

## Monitoring Metrics

### 📈 FPS Metrics
- **Current FPS**: Real-time frame rate
- **Average FPS**: Running average over sample window
- **Min/Max FPS**: Performance extremes
- **Frame Drops**: Count of critical FPS events

### 💾 Memory Metrics  
- **Current Usage**: Real-time memory consumption
- **Peak Usage**: Maximum memory used this session
- **Trend Analysis**: Memory usage pattern over time
- **High Memory Events**: Count of memory threshold violations

### 🌐 Network Metrics
- **Current Ping**: Real-time network latency
- **Average Ping**: Running average of connection quality
- **Connection Status**: Good/Warning/Critical classification

### 🔧 Service Health
- **TutorialService**: Tutorial system health
- **MainGameService**: Core game mechanics health  
- **AnalyticsService**: Analytics and tracking health
- **UpgradeService**: Upgrade system health
- **DataService**: Data persistence health

## Health Check Integration

### Traditional QA Integration
The system integrates with existing `QATestRunner` to provide unified health monitoring:

```lua
-- Enhanced QA runner automatically includes:
-- - Traditional QA service checks (40% weight)
-- - Performance monitoring (40% weight)  
-- - Service integration analysis (20% weight)

local results = EnhancedQARunner.runComprehensiveHealthCheck()
-- Returns comprehensive health score (0-100) with detailed breakdown
```

### Health Status Levels
- **EXCELLENT** (85-100): All systems optimal
- **GOOD** (70-84): Minor issues, systems functional
- **WARNING** (50-69): Some issues detected, monitor closely
- **POOR** (30-49): Significant issues, take action soon
- **CRITICAL** (0-29): Critical issues, immediate action required

## Remote Logging

### Mock Implementation
The system includes mock interfaces for external logging services:

```lua
-- Automatically logs to mock endpoints:
-- - Performance events
-- - Health check results  
-- - Alert notifications
-- - Metric violations

-- In production, replace mock implementations with actual HTTP requests
-- to your monitoring infrastructure (DataDog, New Relic, etc.)
```

### Logged Events
- `PERIODIC_REPORT`: Regular performance snapshots
- `CRITICAL_FPS`: Frame rate below critical threshold
- `CRITICAL_MEMORY`: Memory usage above critical threshold
- `SERVICE_UNHEALTHY`: Service health check failures
- `PERFORMANCE_ALERT`: General performance alerts

## Troubleshooting

### Common Issues

#### Performance Monitor Not Showing
```lua
-- Check if services are loaded
local PerformanceService = _G.PerformanceService
local PerformanceMonitoringService = require(ReplicatedStorage.Shared.services.PerformanceMonitoringService)

-- Manually show UI
RemoteEvents.ShowPerformanceUI:FireClient(player)
```

#### High Memory Warnings
```lua
-- Check memory trends
local report = PerformanceMonitoringService.getReport()
print("Current Memory:", report.memory.current)
print("Peak Memory:", report.memory.peak)

-- Reset metrics if needed
PerformanceMonitoringService.resetMetrics()
```

#### Service Health Failures
```lua
-- Run detailed health check
local healthReport = PerformanceMonitoringService.checkServiceHealth()
for serviceName, status in pairs(healthReport) do
    if not status.healthy then
        print("Unhealthy service:", serviceName, status.error)
    end
end
```

### Performance Optimization

#### Reducing Monitoring Overhead
```lua
-- Adjust update intervals
PerformanceMonitoringService.updateConfig({
    LOG_INTERVAL = 120,  -- Reduce logging frequency
    DETAILED_LOGGING = false  -- Disable verbose logging
})
```

#### Memory Management
```lua
-- Regular metrics reset for long-running servers
PerformanceMonitoringService.resetMetrics()

-- Monitor trend arrays
local metrics = PerformanceMonitoringService.getMetrics()
print("FPS samples:", #metrics.fps.samples)
print("Memory trend:", #metrics.memory.trend)
```

## API Reference

### PerformanceMonitoringService

#### Core Functions
- `generatePerformanceReport()` - Get comprehensive performance data
- `checkServiceHealth()` - Run service health checks
- `updateFPSMetrics()` - Update frame rate metrics
- `updateMemoryMetrics()` - Update memory usage metrics
- `logPerformanceEvent(type, data)` - Log performance events
- `resetMetrics()` - Clear all historical data

#### Status Functions
- `getFPSStatus()` - Get FPS health status (good/warning/critical)
- `getMemoryStatus()` - Get memory health status
- `getPingStatus()` - Get network health status  
- `getOverallHealthStatus()` - Get combined health status

#### Configuration
- `updateConfig(newConfig)` - Update monitoring parameters
- `getConfig()` - Get current configuration

### PerformanceService

#### Client Management
- `handlePerformanceRequest(player)` - Handle client data requests
- `broadcastPerformanceUpdates()` - Send updates to active clients
- `sendPerformanceAlert(type, message, target)` - Send alerts

#### Health Checking
- `comprehensiveHealthCheck()` - Get integrated QA + performance health
- `handleHealthCheckRequest(player)` - Handle client health requests

### PerformanceMonitorUI

#### Display Control
- `show()` - Show expanded performance monitor
- `hide()` - Hide to minimized view
- `toggle()` - Toggle visibility
- `updateDisplay(data)` - Update UI with new data

#### Alert Management
- `showAlert(type, message)` - Display performance alert
- `hideAlert()` - Hide current alert

### EnhancedQARunner

#### Health Checking
- `runComprehensiveHealthCheck()` - Full system health analysis
- `quickHealthCheck()` - Simplified health check
- `startContinuousMonitoring(interval)` - Automated monitoring

## Best Practices

### 🎯 Monitoring Strategy
1. **Start with defaults** - Built-in thresholds work for most games
2. **Monitor trends** - Look for patterns over time, not just snapshots
3. **Regular health checks** - Run comprehensive checks before deployments
4. **Alert fatigue prevention** - Tune thresholds to avoid excessive alerts

### ⚡ Performance Optimization
1. **Monitor the monitor** - Performance monitoring shouldn't impact game performance
2. **Batch updates** - UI updates every 1-5 seconds are sufficient
3. **Clean up data** - Reset metrics periodically for long-running servers
4. **Smart alerting** - Use rate limiting to prevent alert spam

### 🔧 Maintenance
1. **Review thresholds monthly** - Adjust based on actual game performance
2. **Test integrations** - Ensure QA + performance integration stays working
3. **Update configurations** - Tune parameters based on player feedback
4. **Monitor false positives** - Investigate and fix incorrect alerts

## Integration Examples

### Custom Service Integration
```lua
-- Add custom service to health monitoring
local customChecker = function()
    local success, service = pcall(function()
        return require(path.to.CustomService)
    end)
    return success and service ~= nil and service.isHealthy
end

-- Add to PerformanceMonitoringService
serviceHealthCheckers.CustomService = customChecker
```

### External Monitoring Integration
```lua
-- Replace mock logging with real service
function PerformanceMonitoringService.sendRemoteLog(logEntry)
    local HttpService = game:GetService("HttpService")
    local jsonData = HttpService:JSONEncode(logEntry)
    
    -- Replace with your actual monitoring service
    HttpService:PostAsync("https://your-monitoring-service.com/logs", jsonData, {
        ["Content-Type"] = "application/json"
    })
end
```

### Analytics Integration
```lua
-- Automatically log performance events to analytics
local function logToAnalytics(eventType, data)
    if RemoteEvents.LogAnalyticsEvent then
        RemoteEvents.LogAnalyticsEvent:FireServer("performance_event", {
            type = eventType,
            data = data,
            timestamp = tick()
        })
    end
end
```

---

*This performance monitoring system provides production-ready monitoring capabilities for Roblox games with comprehensive metrics, intelligent alerting, and seamless integration with existing QA infrastructure.*
