# Pet System Documentation

## Overview
The Pet System adds adorable companion pets to Color Rush that follow players, react to their gameplay, and provide passive bonuses. Players can purchase pets with coins or Robux, each with unique abilities and behaviors.

## Core Components

### 1. PetService.luau (Server)
**Location**: `src/server/services/PetService.luau`

**Main Functions**:
- Pet ownership and data management
- Pet spawning and behavior systems
- Physical pet models with following AI
- Passive ability application
- Pet vendor management
- Purchase and equipment handling

**Key Features**:
- 8 unique pets across 5 rarity tiers
- Physics-based following system
- Real-time reaction animations
- DataStore persistence
- Marketplace vendor NPC

### 2. PetController.luau (Client)
**Location**: `src/client/controllers/PetController.luau`

**Main Functions**:
- Pet shop UI with tabs (Shop, Collection, Active)
- Purchase confirmation and validation
- Pet equipping/unequipping interface
- Visual notifications and feedback
- Client-side pet interactions

**UI Features**:
- Tabbed interface for different views
- Rarity-based color coding
- Active pet indicators
- Purchase/equip buttons
- Responsive scrolling grid layout

## Pet Database

### Starter Pets (Coins)
1. **⚡ Spark Bunny** - 500 coins
   - Rarity: Common
   - Passive: +5% running speed
   - Reactions: Hop on matches, lightning dance on perfect streaks

2. **💰 Coin Cat** - 750 coins
   - Rarity: Common
   - Passive: +1 coin on perfect streaks (every 3 barriers)
   - Reactions: Purr on matches, golden shimmer on perfect

3. **🌈 Rainbow Bird** - 1,200 coins
   - Rarity: Uncommon
   - Passive: +10% chance for bonus effects
   - Reactions: Wing flutter, rainbow trail effects

### Mid-Tier Pets (Coins)
4. **💎 Crystal Fox** - 2,500 coins
   - Rarity: Rare
   - Passive: Saves from 1 mistake per game
   - Reactions: Crystal glow, protective barrier effects

5. **🔥 Fire Dragon** - 3,000 coins
   - Rarity: Rare
   - Passive: +15% score on 5+ combo streaks
   - Reactions: Flame puff, fire roar celebrations

6. **🌙 Shadow Wolf** - 5,000 coins
   - Rarity: Epic
   - Passive: +20% ghost race performance
   - Reactions: Shadow step, victory howl

### Premium Pets (Robux)
7. **🦄 Cosmic Unicorn** - 150 Robux
   - Rarity: Legendary
   - Passive: +25% XP from all activities
   - Reactions: Star sparkle, cosmic blessing

8. **🔱 Golden Phoenix** - 300 Robux
   - Rarity: Mythic
   - Passive: +50% coins and XP from perfect games
   - Reactions: Golden feathers, phoenix rebirth

## Passive Abilities System

### Types of Passives
1. **Speed Bonus**: Increases player movement speed
2. **Coin Bonus**: Awards extra coins on perfect streaks
3. **Color Bonus**: Increases chance for special effects
4. **Combo Protection**: Saves from mistakes
5. **Streak Multiplier**: Bonus score on combo streaks
6. **Ghost Power**: Enhanced ghost race performance
7. **Experience Boost**: Increased XP gain
8. **Double Rewards**: Multiplied rewards for perfect games

### Implementation
- Passives are applied in GameService during gameplay
- Real-time calculations for bonuses
- Server-side validation for security
- Client feedback for bonus notifications

## Pet Behaviors

### Following System
- Physics-based movement with BodyPosition and BodyVelocity
- Dynamic distance calculations (3-6 studs from player)
- Smooth interpolation and floating animations
- Collision avoidance and terrain adaptation

### Reaction System
- **onMatch**: Triggered when player passes correct barrier
- **onPerfect**: Triggered on perfect streaks (every 5th barrier)
- **onMiss**: Triggered when player hits wrong barrier

### Animation Types
- **Hop Excited**: Vertical bouncing animation
- **Lightning Dance**: Color flashing with sparkle effects
- **Golden Shimmer**: Metallic glow effects
- **Crystal Burst**: Explosion-like particle effects
- **Shadow Step**: Transparency and position shifts
- **Fire Roar**: Flame particle systems

## Pet Vendor

### Location
- Positioned in MarketPlaza at coordinates (-15, 1, 25)
- Marble stand with floating neon NPC
- Interactive click detector with 15-stud activation range

### Shop Interface
- Three-tab design (Shop, Collection, Active)
- Grid layout with rarity color coding
- Real-time purchase validation
- Owned/equipped status indicators

## Quest Integration

### New Pet-Related Quests
1. **🐾 Pet Owner**: Purchase first pet (200 coins)
2. **🦄 Pet Collector**: Own 3 different pets (500 coins)
3. **🌟 Pet Enthusiast**: Play 5 games with active pet (special aura)
4. **💎 Rare Pet Master**: Purchase rare+ pet (1,000 coins)

### Quest Progress Tracking
- Automatic progress updates on purchases
- Game completion tracking with pets
- Rarity-based achievement unlocks

## Data Structure

### Player Data Extensions
```lua
-- Added to DEFAULT_DATA in DataService
ownedPets = {}, -- Array of owned pet IDs
activePet = nil, -- Currently equipped pet ID
petStats = {}, -- Pet-specific statistics
```

### Pet Data Format
```lua
{
    id = "unique_pet_id",
    name = "Display Name",
    description = "Pet description",
    rarity = "Common|Uncommon|Rare|Epic|Legendary|Mythic",
    price = 500,
    currency = "coins|robux",
    passive = {
        type = "passive_type",
        value = 0.05,
        description = "Human readable description"
    },
    reactions = {
        onMatch = "animation_name",
        onPerfect = "special_animation",
        onMiss = "sad_animation"
    },
    model = "ModelName",
    size = Vector3.new(2, 2, 2),
    followDistance = 4,
    color = Color3.new(1, 1, 0.6)
}
```

## Integration Points

### GameService Integration
- Pet reactions on barrier hits
- Passive bonus applications
- Coin and XP multiplier calculations
- Perfect game detection

### QuestService Integration
- Pet purchase tracking
- Games played with pets
- Collection milestone achievements

### DataService Integration
- Pet ownership persistence
- Active pet tracking
- Statistics storage

## Remote Events

### New Events Added
- `ShowPetShop`: Opens pet shop interface
- `PurchasePet`: Handles pet purchases
- `PetPurchaseResult`: Purchase confirmation
- `EquipPet`: Pet equipping/unequipping
- `PetEquipResult`: Equip confirmation
- `TriggerPetReaction`: Animation triggers
- `ApplyPetPassive`: Passive effect application

## Technical Features

### Performance Optimizations
- Efficient pet model creation with minimal parts
- Rate-limited reaction system (0.5s cooldown)
- Connection cleanup on player leave
- Optimized following calculations

### Error Handling
- Graceful pet spawning failures
- DataStore error recovery
- Purchase validation and rollback
- Connection cleanup prevention

### Security Features
- Server-side purchase validation
- Currency verification
- Ownership checking
- Data integrity protection

## Future Enhancements

### Planned Features
1. **Pet Levels**: Experience system for pets
2. **Pet Battles**: PvP pet combat mini-game
3. **Breeding System**: Combine pets for new variants
4. **Seasonal Pets**: Limited-time special pets
5. **Pet Accessories**: Cosmetic pet customization
6. **Pack Animals**: Multiple pets following player

### Balancing Considerations
- Passive ability power scaling
- Economic balance for pricing
- Rarity distribution fairness
- Progression curve optimization

## Testing Checklist

### Core Functionality
- [ ] Pet vendor interaction works
- [ ] Shop UI opens and functions correctly
- [ ] Pet purchases process properly
- [ ] Pets spawn and follow player
- [ ] Passive abilities apply correctly
- [ ] Reactions trigger on gameplay events
- [ ] Data persistence works
- [ ] Quest progress updates

### Edge Cases
- [ ] Multiple pet switches
- [ ] Connection loss during purchase
- [ ] Invalid pet data handling
- [ ] Player leaving mid-transaction
- [ ] DataStore failures
- [ ] Pet model creation errors

### Performance Tests
- [ ] Multiple pets in server
- [ ] Long gameplay sessions
- [ ] Rapid pet switching
- [ ] High player count scenarios
- [ ] Memory usage monitoring
- [ ] Animation performance

The Pet System adds significant depth and engagement to Color Rush while maintaining the game's core simplicity and fun factor. Players now have loyal companions that enhance their experience and provide meaningful progression goals.
