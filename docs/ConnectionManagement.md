# Connection Management System Documentation

## 🔗 Overview

The Connection Management System provides a comprehensive solution for preventing memory leaks from unmanaged RBXScriptConnections in your Roblox game. It automatically tracks all connections, provides cleanup utilities, implements connection pools, and ensures proper disconnection during lifecycle events.

## 🎯 Key Features

- **Automatic Connection Tracking**: All connections are tracked with detailed metadata
- **Player-Specific Cleanup**: Automatically clean up connections when players leave
- **Service-Specific Management**: Organize connections by service for bulk operations
- **Connection Pooling**: Reuse connections for frequently used patterns
- **Memory Leak Detection**: Monitor and detect potential memory leaks
- **Performance Statistics**: Detailed analytics on connection usage
- **Emergency Cleanup**: Nuclear option to clean up everything
- **Lifecycle Integration**: Automatic cleanup on game shutdown

## 📁 File Structure

```
src/
├── shared/
│   ├── core/
│   │   └── ConnectionManager.luau          # Core connection management system
│   └── utils/
│       └── ServiceConnectionHelper.luau    # Helper utilities for services
└── server/
    └── services/
        └── ExampleService.luau             # Example implementation
```

## 🚀 Quick Start

### 1. Basic Connection Tracking

```lua
local ConnectionManager = require(ReplicatedStorage.Shared.core.ConnectionManager)

-- Track a connection with metadata
local connectionId = ConnectionManager:TrackConnection(
    signal:Connect(callback),
    {
        service = "MyService",
        player = player,
        description = "Player data update handler",
        connectionType = ConnectionManager.ConnectionTypes.REMOTE_HANDLER
    }
)

-- Later, disconnect it
ConnectionManager:DisconnectConnection(connectionId)
```

### 2. Using Service Helper (Recommended)

```lua
local ServiceConnectionHelper = require(ReplicatedStorage.Shared.utils.ServiceConnectionHelper)

-- Create a service-specific helper
local helper = ServiceConnectionHelper.CreateServiceHelper("MyService")

-- Connect to player events
helper:ConnectPlayerEvent("PlayerAdded", function(player)
    print("Player joined:", player.Name)
end)

-- Connect to RemoteEvents
helper:ConnectRemoteEvent(RemoteEvents.UpdateQuest, function(player, questId)
    -- Handle quest update
end)

-- Clean up all connections for this service
helper:CleanupAll()
```

## 🛠️ ConnectionManager API

### Core Methods

#### `ConnectionManager:TrackConnection(connection, options)`
Track a new connection with comprehensive metadata.

**Parameters:**
- `connection`: The RBXScriptConnection to track
- `options`: Table with tracking options
  - `service`: Service name (string)
  - `player`: Player instance
  - `tag`: Custom tag for grouping (string)
  - `description`: Human-readable description (string)
  - `connectionType`: Type from ConnectionTypes enum
  - `cleanupCallback`: Function to call during cleanup
  - `timeout`: Custom timeout in seconds

**Returns:** `connectionId` for later reference

#### `ConnectionManager:DisconnectConnection(connectionId)`
Disconnect and clean up a specific connection.

**Parameters:**
- `connectionId`: The ID returned from TrackConnection

**Returns:** `success` (boolean)

### Cleanup Methods

#### `ConnectionManager:CleanupPlayerConnections(player)`
Clean up all connections for a specific player.

**Parameters:**
- `player`: Player instance

**Returns:** Number of connections cleaned up

#### `ConnectionManager:CleanupServiceConnections(serviceName)`
Clean up all connections for a specific service.

**Parameters:**
- `serviceName`: Name of the service

**Returns:** Number of connections cleaned up

#### `ConnectionManager:CleanupTaggedConnections(tag)`
Clean up connections by tag.

**Parameters:**
- `tag`: Tag string

**Returns:** Number of connections cleaned up

#### `ConnectionManager:CleanupAllConnections()`
Clean up ALL connections (nuclear option).

**Returns:** Number of connections cleaned up

### Statistics and Monitoring

#### `ConnectionManager:GetStatistics()`
Get comprehensive statistics about connection usage.

**Returns:** Table with detailed statistics including:
- Overview statistics
- Breakdown by service, player, tag, and type
- Configuration limits

## 🎮 ServiceConnectionHelper API

### Creating Helpers

#### `ServiceConnectionHelper.CreateServiceHelper(serviceName)`
Create a service-specific connection manager helper.

**Parameters:**
- `serviceName`: Name of the service

**Returns:** ServiceHelper instance

### ServiceHelper Methods

#### `helper:ConnectPlayerEvent(eventName, callback, options)`
Connect to player events with automatic cleanup.

```lua
helper:ConnectPlayerEvent("PlayerAdded", function(player)
    -- Handle player joining
end)
```

#### `helper:ConnectRemoteEvent(remoteEvent, callback, options)`
Connect to RemoteEvent with automatic type setting.

```lua
helper:ConnectRemoteEvent(RemoteEvents.UpdateQuest, function(player, questId)
    -- Handle remote event
end)
```

#### `helper:ConnectGUIEvent(guiObject, eventName, callback, options)`
Connect to GUI events with proper cleanup.

```lua
helper:ConnectGUIEvent(button, "MouseButton1Click", function()
    -- Handle button click
end)
```

#### `helper:ConnectTouchEvent(part, callback, debounceTime, options)`
Connect to Part.Touched events with debouncing.

```lua
helper:ConnectTouchEvent(part, function(hit, player, character)
    -- Handle touch with debouncing
end, 1.0) -- 1 second debounce
```

## 🔧 Connection Types

The system provides predefined connection types for better organization:

```lua
ConnectionManager.ConnectionTypes = {
    PLAYER_EVENT = "player_event",
    REMOTE_HANDLER = "remote_handler", 
    STATE_WATCHER = "state_watcher",
    HEARTBEAT = "heartbeat",
    STEPPED = "stepped",
    RENDERSTEPPED = "renderstepped",
    SIGNAL = "signal",
    TIMER = "timer",
    TWEEN = "tween",
    SOUND = "sound",
    GUI = "gui",
    PHYSICS = "physics",
    OTHER = "other"
}
```

## 📊 Best Practices

### 1. Always Use Service Helpers
```lua
-- ✅ Good: Use service helper
local helper = ServiceConnectionHelper.CreateServiceHelper("MyService")
helper:ConnectPlayerEvent("PlayerAdded", callback)

-- ❌ Bad: Direct connection without tracking
Players.PlayerAdded:Connect(callback) -- Memory leak risk!
```

### 2. Set Descriptive Metadata
```lua
-- ✅ Good: Descriptive metadata
helper:TrackConnection(connection, {
    description = "Player " .. player.Name .. " quest progress watcher",
    connectionType = ConnectionManager.ConnectionTypes.PLAYER_EVENT,
    player = player
})

-- ❌ Bad: No metadata
helper:TrackConnection(connection) -- Hard to debug
```

### 3. Clean Up on Service Shutdown
```lua
function MyService:Shutdown()
    helper:CleanupAll()
end

-- Or use automatic cleanup
helper:AddToShutdownSequence()
```

### 4. Monitor Connection Usage
```lua
-- Regularly check statistics
local stats = ConnectionManager:GetStatistics()
if stats.overview.totalConnections > 1000 then
    warn("High connection count detected!")
end
```

## 🚨 Memory Leak Prevention

### Automatic Cleanup Triggers

1. **Player Disconnect**: All player-specific connections are automatically cleaned up
2. **Service Shutdown**: Service helpers can auto-cleanup on game shutdown
3. **Stale Connection Detection**: Automatically removes invalid or timed-out connections
4. **Connection Limits**: Warns when connection limits are exceeded

### Manual Cleanup

```lua
-- Clean up specific player
ConnectionManager:CleanupPlayerConnections(player)

-- Clean up specific service
ConnectionManager:CleanupServiceConnections("MyService")

-- Emergency cleanup everything
ConnectionManager:CleanupAllConnections()
```

## 📈 Performance Monitoring

### Statistics Dashboard
```lua
local stats = ConnectionManager:GetStatistics()
print("Total Connections:", stats.overview.totalConnections)
print("Memory Leaks Prevented:", stats.overview.memoryLeaksPreventend)
print("Cleanup Errors:", stats.overview.cleanupErrors)
```

### Automatic Monitoring
The system includes automatic monitoring that:
- Checks for high connection counts every minute
- Detects stale connections every 30 seconds
- Logs warnings for potential memory leaks
- Provides cleanup suggestions

## 🔍 Debugging and Diagnostics

### Connection Debugging
```lua
-- Enable debug logging
ConnectionManager.Config.ENABLE_DEBUG_LOGGING = true

-- Print comprehensive diagnostics
local stats = ConnectionManager:GetStatistics()
print("Connection Statistics:", HttpService:JSONEncode(stats))
```

### Service-Specific Diagnostics
```lua
-- Check service statistics
local serviceStats = helper:GetStatistics()
print("Service Connections:", serviceStats.totalConnections)
```

## ⚙️ Configuration

### ConnectionManager Configuration
```lua
ConnectionManager.Config = {
    MAX_CONNECTIONS_PER_PLAYER = 500,
    MAX_CONNECTIONS_PER_SERVICE = 1000,
    CLEANUP_INTERVAL = 30, -- seconds
    ENABLE_DEBUG_LOGGING = true,
    ENABLE_MEMORY_MONITORING = true,
    AUTO_CLEANUP_THRESHOLD = 0.8,
    CONNECTION_TIMEOUT = 300, -- 5 minutes
}
```

## 🚀 Migration Guide

### Migrating Existing Services

1. **Replace Direct Connections**
```lua
-- Before
local connection = Players.PlayerAdded:Connect(callback)

-- After
local helper = ServiceConnectionHelper.CreateServiceHelper("MyService")
helper:ConnectPlayerEvent("PlayerAdded", callback)
```

2. **Add Cleanup Logic**
```lua
-- Add to existing services
function MyService:Shutdown()
    helper:CleanupAll()
end
```

3. **Update Connection Patterns**
```lua
-- Before
local connections = {}
connections[#connections + 1] = signal:Connect(callback)

-- After
helper:TrackConnection(signal:Connect(callback), {
    description = "Signal handler",
    connectionType = ConnectionManager.ConnectionTypes.SIGNAL
})
```

## 🎯 Example Implementation

See `ExampleService.luau` for a complete implementation showing:
- Player lifecycle management
- RemoteEvent handlers
- GUI connections
- Character event handling
- Game loop connections
- Proper cleanup patterns

## 🔒 Thread Safety

The ConnectionManager is designed to be thread-safe and can be used from:
- Server scripts
- Client scripts
- ModuleScripts
- Parallel Lua contexts

## 🆘 Troubleshooting

### Common Issues

1. **High Connection Counts**
   - Check statistics regularly
   - Review connection patterns
   - Implement proper cleanup

2. **Memory Leaks**
   - Use automatic cleanup triggers
   - Monitor stale connections
   - Review service shutdown procedures

3. **Performance Issues**
   - Enable performance monitoring
   - Use connection pooling
   - Implement debouncing for high-frequency events

### Getting Help

- Check connection statistics: `ConnectionManager:GetStatistics()`
- Enable debug logging: `ConnectionManager.Config.ENABLE_DEBUG_LOGGING = true`
- Review service diagnostics: `helper:GetStatistics()`

This connection management system ensures your Roblox game maintains optimal performance and prevents memory leaks across all services.
