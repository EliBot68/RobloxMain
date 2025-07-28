# Rebirth System Implementation

## Overview
The Rebirth System allows players to reset their progression at specific level milestones (20, 50, 75, 100, 150) in exchange for permanent upgrades that enhance coin gain, crate odds, and grant unique cosmetic auras.

## 🌟 **System Features**

### **Progressive Requirements**
- **Rebirth 1**: Level 20 → Bronze Aura + 25% coin bonus + 10% crate odds
- **Rebirth 2**: Level 50 → Silver Aura + 50% coin bonus + 20% crate odds  
- **Rebirth 3**: Level 75 → Gold Aura + 75% coin bonus + 30% crate odds
- **Rebirth 4**: Level 100 → Diamond Aura + 100% coin bonus + 40% crate odds
- **Rebirth 5**: Level 150 → Rainbow Aura + 150% coin bonus + 50% crate odds

### **What Players Keep**
- ✅ All cosmetics (skins, trails, pets)
- ✅ Achievement progress and goals
- ✅ Owned gamepasses and purchases
- ✅ Social features (shared scores)
- ✅ Settings and tutorial completion

### **What Gets Reset**
- ❌ Level (back to 1)
- ❌ Current coins (starts with rebirth bonus coins)
- ❌ High score (fresh challenge)
- ❌ Current game statistics

### **Permanent Bonuses**
- 🪙 **Coin Multiplier**: Stacks with VIP gamepass for maximum earning
- 🎁 **Crate Odds**: Better chances for rare items in mystery crates
- ✨ **Cosmetic Aura**: Visual particle effects that show your rebirth level
- 🏆 **Starting Bonus**: Begin with coins based on rebirth level

## 📁 **File Structure**

### **Server-Side Components**
```
src/server/services/
├── RebirthService.luau          # Core rebirth logic and progression
├── AuraService.luau             # Visual aura effects management
└── DataService.luau             # Enhanced with rebirth data fields
```

### **Client-Side Components**
```
src/client/controllers/
└── RebirthController.luau       # Rebirth UI and confirmation dialogs
```

### **Integration Points**
- **GameService**: Coin collection with rebirth multipliers
- **MysteryService**: Crate opening with improved odds
- **GoalService**: Added "First Rebirth" achievement goal
- **DataService**: Persistent rebirth bonuses and aura data

## 🔧 **Technical Implementation**

### **RebirthService.luau**
- **Core Functions**: `CanRebirth()`, `PerformRebirth()`, `GetRebirthInfo()`
- **Bonus Calculation**: `GetCoinMultiplier()`, `GetCrateOddsBonus()`
- **Data Management**: Preserves important progress while resetting core stats
- **Analytics Integration**: Tracks rebirth events and progression

### **AuraService.luau**
- **Visual Effects**: Particle emitters with type-specific configurations
- **Aura Types**: Bronze, Silver, Gold, Diamond, Rainbow with unique colors
- **Animation**: Floating ring effects and particle cycling
- **Auto-Application**: Applies auras on character spawn and rebirth

### **RebirthController.luau**
- **User Interface**: Corner-positioned rebirth panel with progress display
- **Confirmation System**: Warning dialog for rebirth consequences
- **Real-Time Updates**: Live progress tracking and requirements
- **Notifications**: Success/failure feedback with visual effects

## 💾 **Data Persistence**

### **Enhanced Data Structure**
```lua
DEFAULT_DATA = {
    -- Rebirth System Fields
    rebirths = 0,                    -- Number of completed rebirths
    rebirthBonuses = {
        coinMultiplier = 1,          -- Permanent coin earning multiplier
        crateOddsBonus = 0,          -- Improved mystery crate odds
        auraEffect = nil,            -- Current cosmetic aura type
        unlocks = {}                 -- Special rebirth unlocks
    }
}
```

### **Auto-Save Triggers**
- Immediate save upon rebirth completion
- Aura effect updates
- Bonus multiplier changes

## 🎮 **Player Experience**

### **Rebirth UI Features**
- **Progress Display**: Current rebirth status and active bonuses
- **Next Goal**: Clear requirements and upcoming rewards
- **Confirmation Dialog**: Warning about progress reset with detailed explanation
- **Visual Feedback**: Animated notifications and success messages

### **Progression Flow**
1. **Reach Level Requirement**: Player achieves rebirth threshold
2. **UI Notification**: Rebirth button becomes available
3. **Confirmation**: Player reviews consequences and confirms
4. **Reset Process**: Progress resets, bonuses applied, aura unlocked
5. **Enhanced Gameplay**: Permanent benefits improve future runs

### **Strategic Benefits**
- **Faster Progression**: Higher coin multipliers accelerate leveling
- **Better Rewards**: Improved crate odds yield more valuable cosmetics
- **Visual Prestige**: Unique auras show dedication and achievement
- **Compound Growth**: Multiple rebirths create exponential benefits

## 🔗 **System Integration**

### **Coin System Integration**
```lua
-- GameService coin awarding with rebirth multiplier
local rebirthMultiplier = RebirthService:GetCoinMultiplier(player)
coinsToAward = math.floor(coinsToAward * rebirthMultiplier)
```

### **Mystery Crate Integration**
```lua
-- MysteryService with rebirth odds bonus
local rebirthBonus = RebirthService:GetCrateOddsBonus(player) * 100
-- Reduces common odds, increases rare odds proportionally
```

### **Goal System Integration**
- Added "First Rebirth" achievement with exclusive cosmetic reward
- Integrated with existing goal tracking and notification system

## 📊 **Analytics & Balancing**

### **Tracked Events**
- `rebirth_completed`: Full rebirth data including pre/post stats
- Coin earning rates with multiplier effects
- Crate opening results with bonus odds
- Player retention and progression metrics

### **Balancing Considerations**
- **Level Requirements**: Spaced to provide meaningful milestones
- **Bonus Scaling**: Substantial but not game-breaking increases
- **Visual Progression**: Clear distinction between rebirth tiers
- **Endgame Content**: Rainbow aura as prestigious final goal

## 🎯 **Success Metrics**

The rebirth system successfully addresses the user's request to:
- ✅ Allow progression reset at Level 20 or 50 (expanded to 5 tiers)
- ✅ Provide permanent upgrades for faster coin gain
- ✅ Improve mystery crate odds for better rewards
- ✅ Grant unique cosmetic auras for visual prestige
- ✅ Maintain player investment while adding replayability

## 🚀 **Future Enhancements**

### **Potential Expansions**
- **Rebirth Challenges**: Special objectives during rebirth runs
- **Seasonal Auras**: Limited-time aura variants
- **Rebirth Leaderboards**: Fastest rebirth completion times
- **Advanced Bonuses**: XP multipliers, special unlock requirements

The rebirth system provides a complete progression reset mechanism with meaningful permanent benefits, encouraging long-term engagement while respecting player investment in cosmetics and achievements.
