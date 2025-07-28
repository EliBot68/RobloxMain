# Multiplayer Queue System

## 🎮 Overview
The Color Rush game now features an optional multiplayer queue system that allows players to run the track together with up to 5 other players (6 total). The system provides synchronized countdowns, real-time leaderboards, and coordinated gameplay across multiple participants.

## ⚡ How It Works

### Queue System
- **Entry Point**: Players interact with the portal/archway to see game mode options
- **Mode Selection**: Choose between Solo Play or Join Multiplayer Queue
- **Queue Capacity**: Up to 6 players can race together simultaneously
- **Auto-Start**: Queue automatically starts when full or after 30-second timeout
- **Real-Time Updates**: Players see live queue status and participant list

### Synchronized Gameplay
- **Coordinated Start**: All players begin simultaneously with synchronized countdown
- **Track Assignment**: Players are automatically distributed across available tracks
- **Live Leaderboards**: Real-time score updates every 2 seconds during gameplay
- **Collective Results**: Final leaderboard shows all participants' performance

## 🔧 Technical Implementation

### Queue Management System

#### Queue Data Structure
```lua
multiplayerQueue = {
    [1] = Player1,
    [2] = Player2,
    [3] = Player3,
    -- Up to 6 players total
}
```

#### Session Tracking
```lua
multiplayerSessions[sessionId] = {
    sessionId = "unique_session_id",
    players = {Player1, Player2, Player3},
    startTime = tick(),
    leaderboard = {
        [UserId1] = {player = Player1, score = 15, barriersPassed = 8},
        [UserId2] = {player = Player2, score = 12, barriersPassed = 6}
    },
    isActive = true
}
```

### Core Functions

#### `ArchwayService:AddPlayerToQueue(player)`
- Validates player isn't already queued
- Checks queue capacity (max 6 players)
- Adds player and notifies all participants
- Starts auto-timer for first player
- Auto-launches when queue fills

#### `ArchwayService:StartMultiplayerGame()`
- Creates multiplayer session with unique ID
- Moves all queued players to active session
- Initiates synchronized game sequence
- Assigns players to different tracks

#### `GameService:StartMultiplayerGame(player, sessionId, allPlayers)`
- Creates game session linked to multiplayer session
- Synchronizes starting color across all players
- Begins real-time leaderboard broadcasting
- Tracks multiplayer-specific analytics

### Track Assignment System

#### Available Tracks
```lua
local trackPositions = {
    Vector3.new(100, 6, -10),    -- Track 1 (Original)
    Vector3.new(-100, 6, -10),   -- Track 2 (Original)
    Vector3.new(0, 6, 140),      -- Track 3 (Original)
    Vector3.new(200, 6, -10),    -- Track 4 (New)
    Vector3.new(-200, 6, -10),   -- Track 5 (New)
    Vector3.new(100, 6, 240)     -- Track 6 (New)
}
```

#### Distribution Logic
- Players are assigned using modulo cycling through available tracks
- Ensures even distribution across all 6 possible tracks
- Prevents overcrowding on any single track

## 🎯 Player Experience Flow

### Queue Entry Process
1. **Portal Interaction**: Player touches archway trigger zone
2. **Mode Selection**: GUI appears with Solo/Multiplayer options
3. **Queue Join**: Player selects "Join Multiplayer Queue"
4. **Queue Status**: Real-time updates show queue position and participant list
5. **Auto-Start**: Game begins when full or after timeout

### Game Initialization
1. **Synchronized Fade**: All players fade to black simultaneously
2. **Track Assignment**: Players teleported to assigned tracks
3. **Coordinated Countdown**: Synchronized 3-2-1 countdown for all participants
4. **Simultaneous Start**: All players begin racing at the exact same moment

### Live Competition
1. **Real-Time Leaderboard**: Updates every 2 seconds during gameplay
2. **Score Comparison**: Players see live rankings during the race
3. **Individual Progress**: Personal score tracking maintained alongside group stats
4. **Dynamic Rankings**: Leaderboard position changes based on performance

### Results & Completion
1. **Individual Completion**: Players finish at their own pace
2. **Live Updates**: Leaderboard continues updating as players finish
3. **Final Results**: Complete leaderboard shown when all players finish
4. **Session Cleanup**: Multiplayer session cleaned up after completion

## 📊 Real-Time Leaderboard System

### Update Frequency
- **Live Updates**: Every 2 seconds during active gameplay
- **Instant Updates**: Immediate updates on major score changes
- **Final Results**: Complete summary when session ends

### Leaderboard Data
```lua
leaderboardData = {
    {name = "Player1", score = 25, barriersPassed = 15, coinsCollected = 8},
    {name = "Player2", score = 22, barriersPassed = 13, coinsCollected = 6},
    {name = "Player3", score = 18, barriersPassed = 10, coinsCollected = 4}
}
```

### Ranking Algorithm
- **Primary Sort**: Score (highest to lowest)
- **Secondary Sort**: Barriers passed (for tie-breaking)
- **Tertiary Sort**: Coins collected (final tie-breaker)

## 🎮 Client-Server Communication

### Queue Events
- `ShowGameModeSelection` - Display solo/multiplayer choice
- `JoinMultiplayerQueue` - Add player to queue
- `LeaveMultiplayerQueue` - Remove player from queue
- `QueueUpdate` - Real-time queue status updates
- `QueueFull` - Notify when queue reaches capacity

### Game Events
- `MultiplayerGameStarted` - Initialize multiplayer game mode
- `SynchronizedCountdown` - Coordinated countdown across all players
- `MultiplayerLeaderboardUpdate` - Real-time score updates
- `MultiplayerGameCompleted` - Final results display

### Session Management
- `MultiplayerGameInfo` - Session details and participant list
- Session cleanup after completion or timeout
- Automatic queue management and player notifications

## 🔧 Configuration Options

### Queue Settings
```lua
local MAX_QUEUE_SIZE = 6        -- Maximum players per session
local QUEUE_TIMEOUT = 30        -- Auto-start timer (seconds)
```

### Leaderboard Settings
```lua
local UPDATE_INTERVAL = 2       -- Leaderboard update frequency (seconds)
local SESSION_CLEANUP_DELAY = 60 -- Session data retention (seconds)
```

### Track Configuration
- 6 total tracks available for multiplayer distribution
- Automatic track assignment based on player count
- Expandable track system for future scaling

## 📈 Analytics & Monitoring

### Multiplayer Analytics
```lua
MULTIPLAYER_RUN_START = {
    sessionId = "unique_session_id",
    playerCount = 4,
    startColor = "RED",
    startTime = tick()
}
```

### Performance Metrics
- Queue fill rates and timing
- Session completion rates
- Player retention in multiplayer vs solo
- Average session duration and scores

### System Health Monitoring
- Queue processing efficiency
- Session cleanup success rates
- Leaderboard update performance
- Track assignment distribution

## 🎯 Competitive Features

### Live Competition Elements
- **Real-Time Rankings**: See how you compare during the race
- **Dynamic Leaderboards**: Rankings change as performance varies
- **Immediate Feedback**: Know your position relative to other players
- **Final Standings**: Complete results summary at session end

### Social Aspects
- **Group Formation**: Queue with friends or meet new players
- **Shared Experience**: Synchronized start and live competition
- **Community Building**: Multiplayer sessions encourage social interaction
- **Friendly Competition**: Compare skills with other players in real-time

## 🛠 Technical Benefits

### Scalability
- **Session-Based Architecture**: Independent multiplayer sessions
- **Efficient Resource Usage**: Shared game infrastructure across players
- **Dynamic Track Assignment**: Automatically scales with player count
- **Clean Session Management**: Proper cleanup prevents memory leaks

### Performance Optimization
- **Batch Processing**: Efficient leaderboard updates for all players
- **Smart Cleanup**: Automatic session cleanup after completion
- **Resource Sharing**: Shared game systems across multiplayer participants
- **Network Efficiency**: Optimized communication patterns

### Reliability
- **Fault Tolerance**: Individual player disconnections don't affect others
- **Session Recovery**: Robust session management handles edge cases
- **Queue Management**: Prevents overloading and ensures fair access
- **Error Handling**: Graceful degradation for network or player issues

## 🔮 Future Enhancements

### Advanced Features
- **Private Lobbies**: Allow friends to create exclusive multiplayer sessions
- **Skill-Based Matching**: Queue players with similar skill levels
- **Tournament Mode**: Bracket-style competitions with elimination rounds
- **Team Racing**: Cooperative multiplayer where teams compete together

### Social Integration
- **Friend Invites**: Direct invitation system for multiplayer sessions
- **Guild Racing**: Clan-based multiplayer competitions
- **Leaderboard Persistence**: Historical multiplayer performance tracking
- **Achievement Sharing**: Multiplayer-specific achievements and rewards

### Enhanced Competition
- **Power-Ups**: Special abilities that only activate in multiplayer
- **Dynamic Obstacles**: Barriers that respond to group performance
- **Collaborative Challenges**: Goals that require team coordination
- **Spectator Mode**: Allow non-participating players to watch races

The multiplayer queue system transforms Color Rush from a solo experience into a dynamic social racing game, encouraging competition and community building while maintaining the core color-matching gameplay that makes it engaging.
