# Daily Quest Reset System

## Overview
The Color Rush game features an automatic daily quest reset system that refreshes all players' quest progress at UTC 00:00 every day, ensuring players get new challenges and maintaining engagement.

## How It Works

### Automatic Daily Reset
- **Timing**: Resets occur at exactly UTC 00:00 (midnight) every day
- **Scope**: All player quest progress is reset globally
- **New Quests**: Each player receives 3 new random daily quests
- **Progress**: All quest progress counters reset to 0
- **Scheduling**: System automatically schedules the next reset after each reset

### Individual Player Reset
- **On Login**: Players who join after their last quest day get new quests immediately
- **Cross-Session**: Quest progress persists across game sessions until daily reset
- **Fallback**: Individual reset system ensures players always have current quests

### Quest Day Calculation
- Uses UTC time to ensure global consistency
- Days calculated as `math.floor(os.time() / 86400)` (days since Unix epoch)
- Prevents time zone confusion and ensures fair reset timing

## Technical Implementation

### Core Functions

#### `QuestService:GetSecondsUntilNextUTCMidnight()`
Calculates exact seconds until next UTC midnight for precise scheduling.

#### `QuestService:ResetAllPlayerQuests()`
- Resets quests for all currently connected players
- Logs reset statistics and analytics
- Schedules the next automatic reset

#### `QuestService:ResetPlayerQuests(player, forceDay)`
- Generates 3 new random quests for a specific player
- Saves to DataStore with current day timestamp
- Updates in-memory data and notifies client

#### `QuestService:ScheduleNextDailyReset()`
- Calculates time until next UTC midnight
- Spawns a background timer for the reset
- Automatically triggers `ResetAllPlayerQuests()` at the scheduled time

### Data Structure
```lua
{
    dailyQuests = {
        [1] = { id = "red_master", name = "🔴 Red Rush Master", ... },
        [2] = { id = "coin_collector", name = "💰 Coin Collector", ... },
        [3] = { id = "speed_demon", name = "⚡ Speed Demon", ... }
    },
    questProgress = {
        [1] = { completed = false, progress = 15, claimed = false },
        [2] = { completed = true, progress = 50, claimed = true },
        [3] = { completed = false, progress = 3, claimed = false }
    },
    lastQuestDay = 19742 -- Days since Unix epoch
}
```

## Quest Types Available

### Color Matching Quests
- **Red Rush Master**: Match 25 red barriers
- **Blue Barrier Breaker**: Pass 30 blue barriers
- **Green Gate Guardian**: Master 20 green barriers
- **Rainbow Warrior**: Hit 15 barriers of each color

### Performance Quests
- **Speed Demon**: Complete 10 games in under 2 minutes each
- **Perfect Player**: Complete 5 games without wrong barriers
- **Marathon Runner**: Play 15 games in one day
- **High Score Hero**: Achieve score of 20+ in single game

### Collection Quests
- **Coin Collector**: Collect 100 coins
- **Treasure Hunter**: Collect 250 coins in one day
- **Shopping Spree**: Make 3 shop purchases
- **Upgrade Master**: Purchase any upgrade

### Social Quests
- **Daily Visitor**: Visit the fountain
- **Quest Explorer**: Check quest board 3 times
- **Hub Dweller**: Spend 10 minutes in market plaza

## Admin Commands

For testing and management (remove in production):

- `/quest reset` - Manually trigger daily reset for all players
- `/quest status` - Display current quest system status and next reset time

## Analytics Integration

The system tracks:
- Daily reset events with timestamps
- Number of players reset successfully/failed
- Quest completion patterns over time
- Player engagement with quest system

## Scheduling Details

### Reset Timing Calculation
```lua
-- Get current UTC time components
local currentUTCDate = os.date("!*t", os.time())

-- Calculate seconds since midnight today
local secondsSinceMidnight = currentUTCDate.hour * 3600 + 
                           currentUTCDate.min * 60 + 
                           currentUTCDate.sec

-- Calculate seconds until next midnight
local secondsUntilMidnight = 86400 - secondsSinceMidnight
```

### Automatic Rescheduling
After each reset, the system:
1. Calculates time until next UTC midnight
2. Spawns a new background timer
3. Logs the scheduled reset time
4. Continues the cycle indefinitely

## Error Handling

### DataStore Failures
- Individual player reset failures are logged but don't stop global reset
- Fallback quest generation for failed DataStore reads
- Retry logic for critical save operations

### Player Disconnections
- Quests persist in DataStore even if player disconnects during reset
- Next login will load fresh quests if reset occurred while offline

### Service Dependencies
- Graceful handling when PlayerService or AnalyticsService unavailable
- Core quest functionality works independently

## Performance Considerations

### Memory Management
- In-memory quest data cleared and rebuilt during reset
- Old quest progress discarded to prevent memory leaks
- Efficient batch processing for multiple players

### DataStore Optimization
- Minimal DataStore calls during reset (one per player)
- Cached quest templates to avoid repeated generation
- Background saves to prevent blocking game performance

## Maintenance Notes

### Time Zone Considerations
- Always uses UTC to avoid daylight saving time issues
- Consistent reset timing regardless of server location
- Player time zones don't affect reset scheduling

### Quest Balance
- Random quest selection ensures variety
- Difficulty levels spread across easy/medium/hard
- Reward values balanced for game economy

### Monitoring
- Server console logs provide reset status
- Analytics data tracks system health
- Admin commands allow manual intervention

## Troubleshooting

### Common Issues
1. **Reset not occurring**: Check server console for scheduler errors
2. **Players not getting new quests**: Verify DataStore permissions
3. **Timing issues**: Confirm server time is accurate UTC

### Debug Commands
```lua
-- Check current system status
print("Current Day:", QuestService:GetDaysSinceEpoch())
print("Seconds until reset:", QuestService:GetSecondsUntilNextUTCMidnight())
print("UTC Time:", os.date("!%c", os.time()))
```

## Future Enhancements

### Possible Improvements
- Weekly challenge system with bigger rewards
- Seasonal quest themes and special events
- Player quest difficulty preferences
- Cross-server quest leaderboards
- Quest streak bonuses for consecutive completions

### Scalability
- Batch DataStore operations for large player counts
- Distributed reset system for multiple servers
- Quest template hot-reloading for live updates

The daily quest reset system ensures players always have fresh challenges while maintaining data integrity and providing valuable analytics insights into player engagement patterns.
