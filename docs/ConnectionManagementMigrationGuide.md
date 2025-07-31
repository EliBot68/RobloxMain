# Connection Management Migration Guide

## 🎯 **MEMORY LEAK ELIMINATION - SERVICE MIGRATION GUIDE**

This guide shows how to migrate existing services to use the new ConnectionManager system to eliminate memory leaks from unmanaged RBXScriptConnections.

---

## **📋 MIGRATION CHECKLIST**

For each service that needs migration:

- [ ] **Import ConnectionManagerService**
- [ ] **Replace direct :Connect() calls**
- [ ] **Add service initialization**
- [ ] **Implement proper cleanup**
- [ ] **Test connection cleanup**
- [ ] **Monitor memory usage**

---

## **🔧 STEP 1: IMPORT CONNECTION MANAGER**

### **Before (Old Pattern):**
```lua
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local MyService = {}
```

### **After (New Pattern):**
```lua
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Safe require
local function safeRequire(module, fallback)
	local success, result = pcall(require, module)
	return success and result or fallback or {}
end

local SafeRequire = safeRequire(ReplicatedStorage.Shared.utils.SafeRequire)
local ConnectionManagerService = SafeRequire and SafeRequire.require(ReplicatedStorage.Shared.services.ConnectionManagerService) or safeRequire(ReplicatedStorage.Shared.services.ConnectionManagerService)

local MyService = {
	Name = "MyService", -- Add service name for tracking
}
```

---

## **🔧 STEP 2: REPLACE DIRECT CONNECTIONS**

### **Pattern 1: Player Events**

#### **Before (Memory Leak Risk):**
```lua
-- ❌ MEMORY LEAK: No cleanup when service shuts down
Players.PlayerAdded:Connect(function(player)
	-- Handle player joining
end)

-- ❌ MEMORY LEAK: Player-specific connections not cleaned up
player.CharacterAdded:Connect(function(character)
	-- Handle character spawning
end)
```

#### **After (Memory Safe):**
```lua
-- ✅ SAFE: Automatically cleaned up when service shuts down
ConnectionManagerService:ConnectPlayerEvent(
	Players,
	Players.PlayerAdded,
	function(player)
		-- Handle player joining
	end,
	self.Name,
	"Player joined game"
)

-- ✅ SAFE: Automatically cleaned up when player leaves
ConnectionManagerService:ConnectPlayerEvent(
	player,
	player.CharacterAdded,
	function(character)
		-- Handle character spawning
	end,
	self.Name,
	string.format("Character spawned for %s", player.Name)
)
```

### **Pattern 2: Remote Event Handlers**

#### **Before (Memory Leak Risk):**
```lua
-- ❌ MEMORY LEAK: RemoteEvent connections never disconnected
local remoteEvent = ReplicatedStorage.RemoteEvents.MyRemote
remoteEvent.OnServerEvent:Connect(function(player, data)
	-- Handle remote event
end)
```

#### **After (Memory Safe):**
```lua
-- ✅ SAFE: Automatically cleaned up with service
ConnectionManagerService:ConnectRemoteHandler(
	remoteEvent,
	"OnServerEvent",
	function(player, data)
		-- Handle remote event
	end,
	self.Name,
	"My remote event handler"
)
```

### **Pattern 3: RunService Events**

#### **Before (Memory Leak Risk):**
```lua
-- ❌ MEMORY LEAK: Heartbeat connection never disconnected
RunService.Heartbeat:Connect(function()
	-- Update game state
end)

-- ❌ MEMORY LEAK: Player-specific stepped connection
RunService.Stepped:Connect(function()
	-- Update player-specific logic
end)
```

#### **After (Memory Safe):**
```lua
-- ✅ SAFE: Automatically cleaned up with service
ConnectionManagerService:ConnectRunServiceEvent(
	"Heartbeat",
	function()
		-- Update game state
	end,
	self.Name,
	nil, -- No specific player
	"Game state update loop"
)

-- ✅ SAFE: Player-specific connection cleaned up when player leaves
ConnectionManagerService:ConnectRunServiceEvent(
	"Stepped",
	function()
		-- Update player-specific logic
	end,
	self.Name,
	player, -- Specific player
	string.format("Player logic for %s", player.Name)
)
```

### **Pattern 4: Physics Events**

#### **Before (Memory Leak Risk):**
```lua
-- ❌ MEMORY LEAK: Touch events never disconnected
part.Touched:Connect(function(hit)
	-- Handle touch
end)
```

#### **After (Memory Safe):**
```lua
-- ✅ SAFE: Automatically cleaned up
ConnectionManagerService:ConnectPhysicsEvent(
	part,
	"Touched",
	function(hit)
		-- Handle touch
	end,
	self.Name,
	player, -- If player-specific
	"Touch detection"
)
```

### **Pattern 5: GUI Events**

#### **Before (Memory Leak Risk):**
```lua
-- ❌ MEMORY LEAK: GUI connections not cleaned up when player leaves
button.Activated:Connect(function()
	-- Handle button click
end)
```

#### **After (Memory Safe):**
```lua
-- ✅ SAFE: Cleaned up when player leaves
ConnectionManagerService:ConnectGUIEvent(
	button,
	"Activated",
	function()
		-- Handle button click
	end,
	self.Name,
	player,
	"Button click handler"
)
```

### **Pattern 6: Timers**

#### **Before (Memory Leak Risk):**
```lua
-- ❌ MEMORY LEAK: Timer runs forever
spawn(function()
	while true do
		wait(5)
		-- Do something every 5 seconds
	end
end)

-- ❌ MEMORY LEAK: Heartbeat-based timer
local lastTime = tick()
RunService.Heartbeat:Connect(function()
	if tick() - lastTime >= 5 then
		lastTime = tick()
		-- Do something every 5 seconds
	end
end)
```

#### **After (Memory Safe):**
```lua
-- ✅ SAFE: Timer automatically cleaned up
ConnectionManagerService:CreateTimer(
	5.0, -- 5 second interval
	function(callCount, totalTime)
		-- Do something every 5 seconds
	end,
	self.Name,
	player, -- If player-specific
	"5-second status timer"
)
```

---

## **🔧 STEP 3: ADD SERVICE INITIALIZATION**

### **Add to your service:**
```lua
function MyService:Initialize()
	if self._initialized then return end
	
	-- Ensure ConnectionManagerService is initialized
	if ConnectionManagerService and ConnectionManagerService.Initialize then
		ConnectionManagerService:Initialize()
	end
	
	-- Set up all your connections here
	self:_setupConnections()
	
	self._initialized = true
	print("✅ MyService initialized with connection management")
end

function MyService:_setupConnections()
	-- Move all your connection setup code here
	-- Use ConnectionManagerService methods instead of direct :Connect()
end
```

---

## **🔧 STEP 4: IMPLEMENT PROPER CLEANUP**

### **Add cleanup method:**
```lua
function MyService:Cleanup()
	print("🧹 Cleaning up MyService...")
	
	if ConnectionManagerService then
		local cleanedCount = ConnectionManagerService:CleanupServiceConnections(self.Name)
		print(string.format("✅ Cleaned up %d connections for %s", cleanedCount, self.Name))
	end
	
	-- Clear any local data
	self._initialized = false
	
	print("✅ MyService cleanup completed")
end
```

---

## **🔧 STEP 5: UPDATE SERVICE SHUTDOWN**

### **In your main server script or service manager:**
```lua
-- When shutting down services
game:BindToClose(function()
	MyService:Cleanup()
	-- Cleanup other services...
	
	-- Optional: Clean up everything (nuclear option)
	if ConnectionManagerService then
		ConnectionManagerService:CleanupAllConnections()
	end
end)
```

---

## **📊 MONITORING AND DEBUGGING**

### **Check connection statistics:**
```lua
-- Get detailed statistics
local stats = ConnectionManagerService:GetStatistics()
print("Connection Statistics:", game:GetService("HttpService"):JSONEncode(stats))

-- Get connection details for debugging
local details = ConnectionManagerService:GetConnectionDetails()
for connectionId, info in pairs(details) do
	print(string.format("Connection %s: %s (Age: %.1fs)", 
		connectionId, info.description, info.age))
end
```

### **Monitor memory usage:**
```lua
-- Add to a monitoring service
spawn(function()
	while true do
		wait(60) -- Check every minute
		
		local stats = ConnectionManagerService:GetStatistics()
		if stats.overview.totalConnections > 1000 then
			warn("High connection count detected:", stats.overview.totalConnections)
		end
		
		-- Log to analytics
		if AnalyticsService then
			AnalyticsService:TrackEvent("ConnectionCount", {
				total = stats.overview.totalConnections,
				created = stats.overview.connectionsCreated,
				destroyed = stats.overview.connectionsDestroyed
			})
		end
	end
end)
```

---

## **🚨 COMMON MIGRATION ISSUES**

### **Issue 1: Service Dependencies**
```lua
-- ❌ PROBLEM: Accessing ConnectionManagerService before it's initialized
local ConnectionManagerService = require(...)
ConnectionManagerService:ConnectPlayerEvent(...) -- May fail

-- ✅ SOLUTION: Always check if service is available
if ConnectionManagerService and ConnectionManagerService.ConnectPlayerEvent then
	ConnectionManagerService:ConnectPlayerEvent(...)
end
```

### **Issue 2: Player-Specific Cleanup**
```lua
-- ❌ PROBLEM: Not specifying player for player-specific connections
ConnectionManagerService:ConnectPhysicsEvent(playerPart, "Touched", callback, serviceName)

-- ✅ SOLUTION: Always specify the player for player-specific connections
ConnectionManagerService:ConnectPhysicsEvent(playerPart, "Touched", callback, serviceName, player)
```

### **Issue 3: Connection ID Management**
```lua
-- ❌ PROBLEM: Storing connection IDs but never using them
local connectionId = ConnectionManagerService:ConnectPlayerEvent(...)
-- connectionId is lost

-- ✅ SOLUTION: Store IDs only if you need manual cleanup
local MyService = {
	_connections = {} -- Store important connection IDs
}

local connectionId = ConnectionManagerService:ConnectPlayerEvent(...)
table.insert(self._connections, connectionId) -- Only if needed for manual cleanup
```

---

## **✅ MIGRATION VERIFICATION**

After migrating a service, verify:

1. **No direct :Connect() calls remain** - Search for `:Connect(` in the service file
2. **Service name is specified** - All connections should include the service name
3. **Player connections specify player** - Player-specific connections should include the player parameter
4. **Cleanup method exists** - Service should have a Cleanup() method
5. **Initialization is proper** - Service should initialize ConnectionManagerService
6. **No memory leaks** - Test player joining/leaving multiple times

### **Quick verification script:**
```lua
-- Run this in the command line to check for remaining direct connections
local function checkService(service)
	local source = game:GetService("ServerScriptService"):GetSource(service)
	local directConnections = {}
	
	for line in source:gmatch("[^\r\n]+") do
		if line:match(":Connect%(") and not line:match("ConnectionManagerService") then
			table.insert(directConnections, line:match("^%s*(.-)%s*$"))
		end
	end
	
	return directConnections
end
```

---

## **🎯 EXPECTED RESULTS**

After proper migration:

- **Zero memory leaks** from unmanaged connections
- **Automatic cleanup** when players leave
- **Automatic cleanup** when services shutdown
- **Detailed monitoring** of connection usage
- **Improved game stability** and performance
- **Professional connection management** across all services

The ConnectionManager system will prevent the memory leaks that were causing issues with your 50+ services creating unmanaged connections.
