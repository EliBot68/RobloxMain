# ⚡ Upgrade System Documentation

## Overview
The Upgrade System allows players to spend coins to purchase permanent gameplay improvements. The system includes 8 different upgrade types across multiple categories, each with balanced progression and level caps to maintain fair gameplay.

## Upgrade Categories

### 🏃 Movement Upgrades
- **⚡ Speed Boost** (5 levels max)
  - Effect: +10% movement speed per level (max +50%)
  - Cost: 200 coins base, 1.5x multiplier per level
  - Progression: 200 → 300 → 450 → 675 → 1,012 coins

### 💰 Economy Upgrades
- **💰 Coin Collector** (10 levels max)
  - Effect: +1 bonus coin per correct barrier per level
  - Cost: 150 coins base, 1.3x multiplier per level
  - Progression: 150 → 195 → 254 → 330 → 429 → 558 → 725 → 943 → 1,226 → 1,594 coins

### 🏆 Score Upgrades
- **🏆 Score Master** (7 levels max)
  - Effect: +15% score gain per level (max +105%)
  - Cost: 300 coins base, 1.4x multiplier per level
  - Progression: 300 → 420 → 588 → 823 → 1,152 → 1,613 → 2,258 coins

### 🛡️ Defensive Upgrades
- **🛡️ Barrier Shield** (3 levels max)
  - Effect: -25% score penalty reduction per level (max -75%)
  - Cost: 500 coins base, 2.0x multiplier per level
  - Progression: 500 → 1,000 → 2,000 coins

### 🔥 Streak Upgrades
- **🔥 Streak Keeper** (3 levels max)
  - Effect: +1 mistake forgiveness for maintaining streaks per level
  - Cost: 400 coins base, 1.8x multiplier per level
  - Progression: 400 → 720 → 1,296 coins

### 🍀 Luck Upgrades
- **🍀 Lucky Finder** (5 levels max)
  - Effect: +10% better Mystery Box rewards per level
  - Cost: 350 coins base, 1.6x multiplier per level
  - Progression: 350 → 560 → 896 → 1,434 → 2,294 coins

### ⏱️ Timing Upgrades
- **⏱️ Time Master** (4 levels max)
  - Effect: +10% slower barrier color changes per level
  - Cost: 600 coins base, 1.7x multiplier per level
  - Progression: 600 → 1,020 → 1,734 → 2,948 coins

### 👻 Ghost Racing Upgrades
- **👻 Ghost Hunter** (3 levels max)
  - Effect: +50 bonus coins per ghost victory per level
  - Cost: 450 coins base, 1.9x multiplier per level
  - Progression: 450 → 855 → 1,625 coins

## Technical Implementation

### Server-Side (UpgradeService.luau)
```lua
-- Key Functions:
- LoadPlayerUpgrades(player): Load upgrade data from DataStore
- PurchaseUpgrade(player, upgradeId): Handle upgrade purchases
- GetUpgradeEffects(player): Calculate active upgrade bonuses
- ApplyUpgradeEffects(player, value, effectType): Apply modifiers
```

### Client-Side (UpgradeController.luau)
```lua
-- Key Functions:
- ShowUpgradeShop(): Display upgrade interface
- CreateUpgradeEntry(): Build upgrade UI elements
- PurchaseUpgrade(): Handle purchase requests
- RefreshUpgradeList(): Update display after purchases
```

### Data Storage
```lua
-- Player Upgrade Data Structure:
{
    speed_boost = 2,        -- Level 2 speed boost
    coin_bonus = 5,         -- Level 5 coin collector
    score_multiplier = 1,   -- Level 1 score master
    barrier_forgiveness = 0, -- Not purchased
    -- etc...
}
```

## Upgrade Effects Integration

### In-Game Application
- **Speed Multiplier**: Applied to character movement speed
- **Score Multiplier**: Applied to barrier passing rewards
- **Bonus Coins**: Added automatically on correct barriers
- **Penalty Reduction**: Reduces wrong barrier penalties
- **Mystery Luck**: Improves Mystery Box drop rates
- **Time Slowdown**: Extends barrier color change timing
- **Ghost Bonuses**: Extra rewards for competitive play

### Code Integration Points
```lua
-- GameService.luau - Barrier passing:
local finalReward = UpgradeService:ApplyUpgradeEffects(player, baseReward, "score_multiplier")
local bonusCoins = UpgradeService:ApplyUpgradeEffects(player, 0, "bonus_coins")

-- Penalty reduction:
local finalPenalty = UpgradeService:ApplyUpgradeEffects(player, basePenalty, "penalty_reduction")
```

## User Interface

### Upgrade Shop Features
- **Interactive List**: Scrollable upgrade entries with descriptions
- **Visual Progression**: Current level and max level indicators
- **Cost Display**: Next upgrade cost with coin requirement
- **Effect Preview**: Shows current bonus and next level benefit
- **Purchase Feedback**: Success/failure notifications
- **Category Organization**: Logical grouping of upgrade types

### UI Controls
- **Access**: Click upgrade stall in MarketPlaza
- **Navigation**: ESC key to close, scroll for browsing
- **Purchase**: Click upgrade cost button
- **Visual Feedback**: Hover effects and animations

## Quest Integration
The system includes 3 upgrade-related quests:

### ⚡ First Upgrade (Easy)
- **Objective**: Purchase your first upgrade
- **Reward**: 100 coins
- **Purpose**: Introduce players to the upgrade system

### ⚡ Upgrade Collector (Medium)
- **Objective**: Purchase 3 different upgrades
- **Reward**: 300 coins
- **Purpose**: Encourage diversified upgrading

### ⚡ Maxed Out (Hard)
- **Objective**: Max out any upgrade to its highest level
- **Reward**: Special "Upgrade Master" aura (30 minutes)
- **Purpose**: Long-term progression goal

## Balance Design

### Progression Curve
- **Early Game**: Affordable upgrades (150-300 coins) for immediate impact
- **Mid Game**: Moderate costs (400-600 coins) for specialized builds
- **Late Game**: Expensive upgrades (1,000+ coins) for optimization

### Power Scaling
- **Damage Mitigation**: Penalty reduction capped at 75% maximum
- **Score Scaling**: Multiplicative bonuses balanced against coin economy
- **Speed Limits**: Movement bonuses kept reasonable for gameplay flow
- **Economic Balance**: Coin generation increases match upgrade costs

### Upgrade Synergies
- **Coin Generator Build**: Coin Collector + Score Master for economy focus
- **Defensive Build**: Barrier Shield + Streak Keeper for error forgiveness
- **Speed Runner Build**: Speed Boost + Time Master for quick gameplay
- **Completionist Build**: All upgrades for maximum versatility

## Performance Considerations

### Memory Management
- Upgrade data stored efficiently in player profiles
- Effects calculated on-demand rather than continuously
- UI elements created/destroyed as needed

### Network Optimization
- Upgrade effects applied server-side for security
- Client receives effect confirmations for visual feedback
- Purchase validation prevents exploitation

### Database Efficiency
- Upgrade levels stored as integers for compact storage
- DataStore operations batched where possible
- Automatic cleanup of invalid upgrade data

## Analytics Tracking

### Tracked Events
- `upgrade_purchased`: Player buys an upgrade
- `upgrade_effect_applied`: Upgrade bonus triggers in-game
- `upgrade_shop_viewed`: Player opens upgrade interface
- `max_level_reached`: Player maxes out an upgrade

### Data Points
- Upgrade popularity by category
- Coin spending patterns
- Player progression through upgrade trees
- Economic impact on game balance

## Installation & Setup

### Workspace Structure
```
src/
├── server/services/UpgradeService.luau
├── client/controllers/UpgradeController.luau
└── shared/modules/RemoteEvents.luau (updated)
```

### Required Remote Events
- `ShowUpgradeShop`: Display upgrade interface
- `PurchaseUpgrade`: Handle upgrade purchases
- `UpgradePurchaseResult`: Purchase success/failure feedback
- `UpdateUpgradeData`: Refresh client data after purchase
- `BonusCoinsEarned`: Notify about upgrade-based coin bonuses

### Service Dependencies
- **PlayerService**: Player data management
- **QuestService**: Quest progress tracking
- **AnalyticsService**: Usage analytics
- **GameService**: Effect application during gameplay

### Initialization
1. **Server**: UpgradeService auto-initializes and sets up MarketPlaza stall
2. **Client**: UpgradeController connects to remote events and UI handling
3. **Integration**: GameService applies upgrade effects during barrier interactions

## Future Enhancements

### Planned Features
- **Prestige System**: Reset upgrades for permanent bonuses
- **Upgrade Sets**: Bonus effects for owning related upgrades
- **Temporary Boosts**: Time-limited upgrade effects from events
- **Visual Customization**: Upgrade-based character appearance changes

### Advanced Mechanics
- **Upgrade Combinations**: Synergy bonuses between specific upgrades
- **Seasonal Upgrades**: Limited-time special upgrades
- **Achievement Upgrades**: Unlock powerful upgrades through milestones
- **Guild Upgrades**: Shared upgrades for team-based gameplay

---

**📝 Created**: January 2024  
**🔄 Last Updated**: January 2024  
**💰 Total Upgrade Investment Required**: ~15,000 coins for all max levels  
**⚖️ Balance Status**: Tested and balanced for fair progression
