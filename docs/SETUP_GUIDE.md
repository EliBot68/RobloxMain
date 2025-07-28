# Color Rush Game - Complete System Setup Guide

## 🎮 Overview
This Roblox game features a complete color-matching experience with analytics, monetization, and daily quests.

## 🚀 Quick Start

### 1. Launch Game Server
```bash
# Start Rojo sync (run from project directory)
start_rojo.bat
```

### 2. Required Roblox Services
The game automatically configures these services:
- `HttpService` - For analytics endpoints
- `MarketplaceService` - For monetization
- `DataStoreService` - For player data persistence

### 3. HTTP Analytics Setup
Configure in `AnalyticsService.luau`:
```lua
local ANALYTICS_ENDPOINT = "https://your-analytics-server.com/api/events"
local ANALYTICS_SECRET = "your-secret-key"
```

## 💰 Monetization Products

### Gamepass: VIP Double Coins
- **ID**: Configure in `MonetizationService.luau`
- **Benefit**: 2x coin multiplier for VIP members
- **Price**: Set in Roblox Developer Dashboard

### Developer Product: 100 Coins Pack
- **ID**: Configure in `MonetizationService.luau` 
- **Reward**: 100 coins per purchase
- **Price**: Set in Roblox Developer Dashboard

## 🎯 Daily Quest System

### Automatic Features
- ✅ **UTC Midnight Reset**: All players get new quests daily
- ✅ **15 Quest Types**: Colors, performance, collection, social
- ✅ **Progress Tracking**: Persistent across sessions
- ✅ **Analytics Integration**: Tracks completion patterns

### Quest Categories
- **Color Quests**: Match specific colored barriers
- **Performance Quests**: Speed runs and perfect games  
- **Collection Quests**: Coins and shop purchases
- **Social Quests**: Fountain visits and exploration

## 📊 Analytics Tracking

### Events Logged
- `player_joined` / `player_left`
- `game_started` / `game_completed`
- `quest_completed` / `quest_claimed`
- `purchase_completed` / `coins_earned`
- `barrier_hit` / `shop_visit`
- `daily_quest_reset`

### Data Endpoints
- Real-time HTTP transmission
- Buffered batch sending
- Secure authentication headers
- Error handling and retries

## 🛠 Admin Commands

### Quest Management (Remove in Production)
- `/quest reset` - Manually trigger daily reset
- `/quest status` - View system status and next reset time

### Analytics Commands
- Manual buffer flush and endpoint testing available

## 📁 Key Files

### Server Services
- `AnalyticsService.luau` - HTTP analytics with external endpoints
- `MonetizationService.luau` - Gamepass and developer products
- `QuestService.luau` - Daily quest system with UTC reset
- `DataService.luau` - Player data persistence
- `PlayerService.luau` - Player management and events

### Client Controllers  
- `GameController.luau` - Core gameplay mechanics
- `GuiController.luau` - UI management and updates
- `ShopController.luau` - Three-tab shop with Robux purchases
- `QuestController.luau` - Quest board and progress tracking

### Shared Resources
- `GameConstants.luau` - Game configuration and quest definitions
- `RemoteEvents.luau` - Client-server communication
- `Types.luau` - Type definitions for all systems
- `Analytics.luau` - Shared analytics utilities

## 🔧 Configuration

### Game Constants (`GameConstants.luau`)
```lua
-- Coins and Economy
COINS_PER_CORRECT_BARRIER = 2
COINS_PER_GAME_COMPLETION = 10
VIP_COIN_MULTIPLIER = 2

-- Quest System  
DAILY_QUESTS_COUNT = 3
QUEST_COIN_REWARDS = {25, 50, 100}

-- Game Settings
GAME_DURATION = 120 -- 2 minutes
BARRIER_SPAWN_RATE = 2 -- seconds
```

### Monetization IDs (`MonetizationService.luau`)
```lua
local GAMEPASS_IDS = {
    VIP_DOUBLE_COINS = 123456789 -- Replace with actual ID
}

local DEV_PRODUCT_IDS = {
    COINS_PACK_100 = 987654321 -- Replace with actual ID
}
```

## 🎯 Production Checklist

### Before Launch
- [ ] Set analytics endpoint URL and secret key
- [ ] Configure gamepass and developer product IDs
- [ ] Remove admin commands from server scripts
- [ ] Test daily quest reset timing
- [ ] Verify monetization receipt processing
- [ ] Enable HTTP requests in game settings

### Analytics Setup
- [ ] Configure external analytics server
- [ ] Set up secure endpoint authentication
- [ ] Test HTTP request permissions
- [ ] Verify data format and parsing

### Monetization Setup  
- [ ] Create gamepass in Roblox Developer Dashboard
- [ ] Create developer product for coin pack
- [ ] Set appropriate prices and descriptions
- [ ] Test purchase flows and receipt processing

## 🔍 Monitoring

### Server Console Logs
- Daily quest reset confirmations
- Analytics transmission status
- Purchase processing results
- Error messages and warnings

### Player Data Tracking
- Quest completion rates
- Purchase conversion metrics
- Session duration and engagement
- Coin economy balance

## 🚨 Troubleshooting

### Common Issues
1. **Analytics not sending**: Check HTTP service enabled and endpoint URL
2. **Purchases not working**: Verify MarketplaceService callbacks and product IDs
3. **Quests not resetting**: Check server console for timer errors
4. **Data not saving**: Confirm DataStore service permissions

### Debug Tools
- Admin commands for manual testing
- Server console logging for all systems
- Analytics events for monitoring player behavior
- Error handling with detailed logging

## 📈 Success Metrics

### Player Engagement
- Daily active users and session length
- Quest completion rates by type
- Shop visit frequency and purchase rates
- Player retention and return rates

### Revenue Tracking
- Gamepass conversion rates
- Developer product purchase frequency  
- Revenue per player metrics
- VIP membership adoption

### System Health
- Analytics transmission success rate
- Daily quest reset reliability
- DataStore operation success
- Server performance and error rates

## 🔄 Maintenance

### Regular Tasks
- Monitor analytics endpoint health
- Review quest completion patterns
- Update quest difficulties based on data
- Optimize server performance as needed

### Updates and Features
- Seasonal quest themes
- New monetization products
- Enhanced analytics dimensions
- UI/UX improvements based on player feedback

The Color Rush game is now fully equipped with comprehensive analytics, monetization, and daily quest systems that will drive player engagement and provide valuable insights for ongoing optimization!
