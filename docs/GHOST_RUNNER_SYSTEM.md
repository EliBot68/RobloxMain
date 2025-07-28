# 👻 Ghost Runner System Documentation

## Overview
The Ghost Runner system allows players to race against recorded "ghost" versions of other players' best runs. When a player completes a run, their path, timing, and performance data is saved and can be replayed as a semi-transparent ghost that other players can compete against.

## Features

### 🎯 Core Functionality
- **Real-time Recording**: Player positions recorded every 0.1 seconds during gameplay
- **Barrier Interaction Tracking**: Records hits/misses with precise timing and location
- **Performance Scoring**: Dynamic scoring system with penalties for hits and bonuses for clean passes
- **Ghost Playback**: Spawns semi-transparent ghost models that replay recorded runs
- **Leaderboard System**: Top 10 ghosts stored per track with automatic ranking

### 🏁 Racing System
- **Ghost Selection**: Players can choose specific ghosts to race against from the leaderboard
- **Real-time Comparison**: Live updates showing current player vs ghost performance
- **Race Notifications**: Visual feedback when winning/losing against ghost times
- **Multiple Ghost Support**: Can race against multiple ghosts simultaneously

### 🎮 User Interface
- **G-Key Toggle**: Press 'G' to open/close the ghost leaderboard
- **Leaderboard Display**: Shows ghost names, scores, completion times, and dates
- **Race Comparison UI**: Real-time stats during ghost races
- **Interactive Selection**: Click ghost entries to start racing against them

### 📊 Data Management
- **DataStore Integration**: Persistent storage of ghost data across server restarts
- **Analytics Tracking**: Integration with analytics system for usage statistics
- **Memory Optimization**: Automatic cleanup of old/low-performing ghosts
- **Cross-Session Support**: Ghosts persist between player sessions

## Technical Implementation

### Server-Side (GhostService.luau)
```lua
-- Key Functions:
- StartRecording(player): Begin recording a player's run
- RecordPosition(player): Capture position data every 0.1s
- PassBarrier(player, wasHit): Log barrier interactions
- EndRecording(player): Stop recording and save ghost data
- SpawnGhost(ghostData, viewer): Create and animate ghost model
- GetLeaderboardGhosts(trackType, count): Retrieve top performers
```

### Client-Side (GhostController.luau)
```lua
-- Key Functions:
- ShowGhostLeaderboard(): Display available ghosts
- RaceAgainstGhost(ghostId): Start racing against selected ghost
- UpdateRaceComparison(): Real-time race progress updates
- HandleKeyboardInput(): G-key toggle functionality
```

### Data Structure
```lua
-- Ghost Run Data:
{
    id = "unique_ghost_id",
    playerId = 12345,
    playerName = "PlayerName",
    score = 1250,
    duration = 45.7,
    timestamp = 1704067200,
    positions = {{x, y, z, time}, ...},
    barrierInteractions = {{time, wasHit, position}, ...},
    trackType = "main"
}
```

## Remote Events

### Client → Server
- `RequestGhostLeaderboard`: Request list of available ghosts
- `RaceAgainstGhost`: Start racing against specific ghost

### Server → Client
- `ShowGhostLeaderboard`: Send ghost list to client
- `UpdateRaceComparison`: Live race progress updates
- `GhostSaved`: Confirmation when player's ghost is saved
- `GhostSpawned`: Notification when ghost starts playing

## Configuration

### GhostService Constants
```lua
GHOST_CONFIG = {
    recordingInterval = 0.1,     -- Position recording frequency
    maxGhostsPerTrack = 10,      -- Leaderboard size
    hitPenalty = 50,             -- Score penalty for barrier hits
    passBonus = 10,              -- Score bonus for clean passes
    ghostTransparency = 0.6,     -- Ghost model transparency
    maxRecordingTime = 300,      -- Maximum run duration (5 minutes)
    cleanupInterval = 86400      -- Daily cleanup of old data
}
```

## Quest Integration
The system includes 5 new ghost-related quests:

1. **👻 Ghost Spectator**: View the leaderboard (100 coins)
2. **👻 Ghost Racer**: Race against 3 ghosts (300 coins) 
3. **👻 Ghost Champion**: Beat a ghost's time (500 coins)
4. **👻 Legendary Ghost**: Reach top 5 leaderboard (special ghost aura)
5. **👻 Ghost Creator**: Complete 5 runs (250 coins)

## Analytics Events
- `ghost_run_recorded`: When a ghost is successfully saved
- `ghost_race_started`: When player begins racing against ghost
- `ghost_race_completed`: When race finishes (win/loss)
- `ghost_leaderboard_viewed`: When player opens leaderboard
- `ghost_selected`: When player chooses ghost to race against

## Performance Considerations

### Memory Management
- Position data compressed using efficient storage
- Automatic cleanup of low-scoring ghosts
- Ghost models destroyed after playback completion
- DataStore operations batched for efficiency

### Network Optimization
- Ghost data streamed progressively during playback
- Position interpolation for smooth movement
- Selective data transmission based on player proximity

### Visual Effects
- Semi-transparent ghost models with glow effect
- Smooth interpolation between recorded positions
- Particle effects for barrier interactions
- Color-coded performance indicators

## Troubleshooting

### Common Issues
1. **Ghost not appearing**: Check if ghost data exists in leaderboard
2. **Recording not working**: Ensure player is in active game session
3. **Leaderboard empty**: Verify DataStore permissions and connectivity
4. **Performance lag**: Check recording interval settings

### Debug Commands
```lua
-- Server console commands for testing:
game.ServerStorage.GhostService:GetLeaderboardGhosts("main", 10)
game.ServerStorage.GhostService:DespawnAllGhosts()
```

## Future Enhancements

### Planned Features
- Multiple track support (different levels/difficulties)
- Ghost replay controls (pause, rewind, fast-forward)
- Team ghost races (multiplayer ghost competitions)
- Ghost customization (colors, effects, names)
- Advanced analytics (heat maps, common failure points)
- Weekly ghost championships with special rewards

### Performance Improvements
- Position prediction for smoother ghost movement
- Adaptive recording quality based on device performance
- Ghost model pooling for memory efficiency
- Progressive loading for large ghost datasets

## Installation Notes

The Ghost Runner system is automatically initialized when the game starts:
1. **Server**: GhostService loads and connects to DataStore
2. **Client**: GhostController sets up UI and input handling
3. **Integration**: System connects to existing GameService for run tracking

All components are fully integrated with the existing Color Rush architecture and require no additional setup beyond the initial file deployment.

---

**📝 Created**: January 2024  
**🔄 Last Updated**: January 2024  
**👨‍💻 Compatibility**: Roblox Studio, Xbox Controller Support, Mobile-Friendly UI
