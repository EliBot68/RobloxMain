# Service Documentation Template

This file contains the documentation standards being applied to all services in the RobloxMain project.

## Documentation Standards

### Luau/JSDoc Style Comments Format:
```lua
--[[
    Brief description of what the function does.
    More detailed explanation if needed.
    
    @param paramName {type} - Description of parameter
    @param paramName2 {type?} - Optional parameter description
    @return {type} - Description of return value
    @return {type, type} - Multiple return values
]]
function ServiceName:FunctionName(paramName, paramName2)
```

### Common Parameter Types:
- `{Player}` - Roblox Player instance
- `{number}` - Numeric value
- `{string}` - Text string
- `{boolean}` - True/false value
- `{table}` - Lua table/dictionary
- `{Instance}` - Roblox Instance
- `{Vector3}` - 3D vector
- `{CFrame}` - Coordinate frame
- `{void}` - No return value

### Common Function Categories:

#### Initialization Functions:
- `Initialize()` - Sets up the service
- `OnInit()` - ServiceBase initialization
- `OnStart()` - ServiceBase start phase

#### Data Management:
- `LoadPlayerData()` - Loads player data from DataStore
- `SavePlayerData()` - Saves player data to DataStore
- `GetPlayerData()` - Retrieves cached player data

#### Player Lifecycle:
- `PlayerJoined()` - Handles new player joining
- `PlayerLeft()` - Handles player leaving
- `HandlePlayerAdded()` - Player addition handling

#### Remote Events:
- `SetupRemoteEvents()` - Sets up client-server communication
- `SetupConnections()` - Sets up event connections

#### Core Functionality:
- Service-specific public methods that clients can call

## Services Documented:

✅ **SocialService** - Friend management and social engagement
✅ **UpgradeService_Consolidated** - Player upgrade system  
✅ **PetService** - Pet ownership and behaviors (partial)

## Services To Document:

### Core Services:
- [ ] DataService - Player data management
- [ ] PlayerService - Player state management
- [ ] GameService - Core game logic
- [ ] MainGameService - Main game controller

### Feature Services:
- [ ] LeaderboardService - Player rankings
- [ ] QuestService - Quest system
- [ ] ShopService - In-game purchases
- [ ] MonetizationService - Revenue features

### Gameplay Services:
- [ ] DifficultyService - Game difficulty scaling
- [ ] MovingObstacleService - Dynamic obstacles
- [ ] GameTrackService - Track generation
- [ ] JumpService - Jump mechanics

### Specialized Services:
- [ ] TeleportService - Server teleportation
- [ ] AnalyticsService - Player analytics
- [ ] TutorialService - New player onboarding
- [ ] EventService - Special events

### UI/UX Services:
- [ ] HubManagerService - Hub world management
- [ ] GameAudioService - Audio management
- [ ] VisualPolishService - Visual effects

### Social/Engagement:
- [ ] PartyService - Group gameplay
- [ ] TournamentService - Competitive events
- [ ] WeeklyLeaderboardService - Time-based rankings

All services should follow this documentation standard for consistency and maintainability.
