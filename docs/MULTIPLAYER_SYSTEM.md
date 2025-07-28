# Multiplayer Run Mode System

## Overview
A comprehensive multiplayer queue system that allows 2-6 players to join group runs together, featuring real-time leaderboards, synchronized starts, and bonus XP rewards.

## Features

### ✅ **Queue System**
- **Physical Queue Area**: Green glowing platform next to the main portal with visual waiting spots
- **Queue Capacity**: Supports 2-6 players per multiplayer session
- **Auto-Start Timer**: Games automatically start after 30 seconds if queue isn't full
- **Visual Indicators**: Pulsing neon spots show waiting positions
- **Queue Management**: Players can join/leave the queue with real-time updates

### ✅ **Game Mode Selection**
- **Modal Interface**: Clean UI popup when entering the game area
- **Solo Run Option**: Traditional single-player experience 
- **Group Run Option**: Multiplayer mode with bonus XP highlight
- **Queue Status**: Real-time display of current queue count and player names

### ✅ **Synchronized Gameplay**
- **Simultaneous Start**: All players teleported to different tracks at the same time
- **Shared Countdown**: Synchronized 3-2-1 countdown for all participants
- **Track Assignment**: Players automatically assigned to different tracks (1-6)
- **Unified Game Session**: All players linked to the same multiplayer session

### ✅ **Live Leaderboard**
- **Real-Time Rankings**: Live scoreboard showing all players' current scores
- **Compact Display**: Positioned on the right side during gameplay
- **Dynamic Updates**: Rankings update in real-time as players progress
- **Player Identification**: Shows names and current scores for all participants

### ✅ **Final Scoreboard**
- **Comprehensive Results**: Detailed final results showing all participants
- **Multiple Metrics**: Displays score, barriers passed, and coins collected
- **Placement Rankings**: Gold/Silver/Bronze styling for top 3 players
- **5-Second Display**: Results shown for 5 seconds before auto-closing

### ✅ **Bonus XP System**
- **25% XP Bonus**: All multiplayer participants receive 25% bonus experience
- **Stacking Bonuses**: Multiplayer bonus stacks with existing party bonuses
- **Notification System**: Players notified of bonus XP earned
- **Immediate Application**: Bonus applied instantly upon game completion

## Technical Implementation

### **Server-Side Components**

#### **ArchwayService** (Enhanced)
- **Queue Management**: Handles player join/leave queue operations
- **Session Coordination**: Manages multiplayer session creation and cleanup
- **Synchronized Transport**: Coordinates simultaneous player teleportation
- **Track Assignment**: Distributes players across available tracks

#### **GameService** (Enhanced)
- **Multiplayer Sessions**: Tracks active multiplayer games with shared leaderboards
- **Live Updates**: Broadcasts real-time leaderboard updates to all participants
- **Bonus XP Calculation**: Applies 25% multiplayer bonus to final XP rewards
- **Session Cleanup**: Properly cleans up multiplayer sessions after completion

#### **HubService** (Enhanced)
- **Queue Area Creation**: Physical queue zone with interactive elements
- **Visual Design**: Glowing platform with pulsing waiting spots
- **Detection System**: Touch-based activation for game mode selection

### **Client-Side Components**

#### **MultiplayerController** (New)
- **Game Mode UI**: Modal selection interface for solo vs. multiplayer
- **Queue Interface**: Real-time queue status and player list display
- **Live Leaderboard**: During-game rankings display
- **Final Results**: Comprehensive post-game scoreboard

#### **Remote Events** (Enhanced)
- **Queue Management**: `JoinMultiplayerQueue`, `LeaveMultiplayerQueue`, `QueueUpdate`
- **Game Coordination**: `MultiplayerGameStarted`, `SynchronizedCountdown`
- **Live Updates**: `MultiplayerLeaderboardUpdate`, `MultiplayerGameCompleted`
- **Bonus Notifications**: `MultiplayerXpBonus`

## Usage Instructions

### **For Players**
1. **Approach Portal**: Walk near the main game portal
2. **Choose Mode**: Select "Solo Run" or "Group Run" from the popup
3. **Join Queue**: For Group Run, enter the green queue area
4. **Wait for Players**: Queue shows current participants (2-6 players)
5. **Auto-Start**: Game begins when full or after 30-second timer
6. **Race Together**: All players start simultaneously on different tracks
7. **View Rankings**: Live leaderboard shows real-time progress
8. **See Results**: Final scoreboard displays when all players finish
9. **Earn Bonus**: Receive 25% bonus XP for multiplayer participation

### **For Developers**
1. **Queue Area**: Automatically created in HubService initialization
2. **Track Support**: Supports up to 6 concurrent tracks for multiplayer
3. **Session Management**: Automatic cleanup after game completion
4. **Extensibility**: Easy to add more features like voice chat, team modes, etc.

## Configuration

### **Queue Settings** (ArchwayService)
```lua
local MAX_QUEUE_SIZE = 6 -- Up to 6 players
local QUEUE_TIMEOUT = 30 -- Auto-start after 30 seconds
```

### **XP Bonus** (GameService)
```lua
multiplayerBonus = 1.25 -- 25% bonus XP
```

### **Track Positions** (ArchwayService)
```lua
local trackPositions = {
    Vector3.new(100, 6, -10),   -- Track 1
    Vector3.new(-100, 6, -10),  -- Track 2  
    Vector3.new(0, 6, 140),     -- Track 3
    Vector3.new(200, 6, -10),   -- Track 4
    Vector3.new(-200, 6, -10),  -- Track 5
    Vector3.new(100, 6, 240)    -- Track 6
}
```

## Benefits

### **For Players**
- **Social Gameplay**: Race with friends in real-time
- **Competitive Element**: Live leaderboards add excitement
- **Bonus Rewards**: 25% extra XP incentivizes group play
- **Shared Experience**: Synchronized starts create fair competition

### **For Game Retention**
- **Increased Engagement**: Multiplayer sessions keep players longer
- **Social Features**: Friends can play together easily
- **Competitive Motivation**: Rankings encourage repeat play
- **Community Building**: Shared experiences build player relationships

### **For Game Balance**
- **Fair Competition**: All players start simultaneously
- **Separate Tracks**: No interference between players
- **Balanced Rewards**: Bonus XP doesn't break progression
- **Optional Feature**: Solo mode still available for all players

## Future Enhancements

### **Potential Additions**
- **Team Modes**: 2v2 or 3v3 team competitions
- **Tournament Brackets**: Organized multiplayer tournaments
- **Voice Chat Integration**: In-game communication during races
- **Spectator Mode**: Watch multiplayer races in progress
- **Custom Lobbies**: Private rooms for friends
- **Seasonal Events**: Special multiplayer challenges

## Status: ✅ FULLY IMPLEMENTED

All core multiplayer features are complete and ready for testing:
- ✅ Queue system with visual area
- ✅ Game mode selection UI
- ✅ Synchronized multiplayer gameplay
- ✅ Live leaderboard during games
- ✅ Final scoreboard with detailed results
- ✅ 25% bonus XP for group participation
- ✅ Complete session management and cleanup
- ✅ Client-side UI controllers
- ✅ Server-side session coordination

The multiplayer run mode system provides a complete social gaming experience while maintaining the core Color Rush gameplay mechanics!
