# 🎪 Event Run System Documentation

## Overview
The Event Run system provides players with special themed versions of the main Color Rush track, featuring unique visual effects, music, temporary cosmetics, and bonus rewards.

## 🌟 **Core Features**

### **Event Portal**
- Located next to the main game archway in MarketPlaza
- Animated floating portal with color-shifting effects
- Interactive through both clicking and walking through
- Displays current active event name and theme

### **Event Themes**
The system cycles through 4 unique themed events, each lasting 1 hour:

#### 🌈 **Rainbow Rush**
- **Description**: All colors cycle rapidly with rainbow effects!
- **Visual Effects**: Rainbow lighting cycle, colorful ambient effects
- **Rewards**: 1.5x XP, 1.3x Coins
- **Temporary Cosmetics**: Rainbow Runner skin, Rainbow Burst trail

#### 🌃 **Neon Nights**
- **Description**: Glowing neon barriers in a dark cyber world!
- **Visual Effects**: Dark atmosphere with neon lighting, cyber fog
- **Rewards**: 1.4x XP, 1.2x Coins  
- **Temporary Cosmetics**: Cyber Runner skin, Neon Stream trail

#### 🔥 **Fire Festival**
- **Description**: Hot barriers with flame effects and fire trails!
- **Visual Effects**: Hot fire lighting, flame particle effects, brightness pulse
- **Rewards**: 1.6x XP, 1.4x Coins
- **Temporary Cosmetics**: Fire Dancer skin, Flame Trail

#### ❄️ **Ice Crystal**
- **Description**: Crystalline barriers with frosty particle effects!
- **Visual Effects**: Cold ice lighting, icy fog atmosphere
- **Rewards**: 1.3x XP, 1.5x Coins
- **Temporary Cosmetics**: Ice Walker skin, Frost Trail

## 🎮 **Gameplay Features**

### **Event Mechanics**
- Special themed lighting and atmosphere changes
- Temporary cosmetic effects applied for 5 minutes
- Event-specific background music during gameplay
- Enhanced visual effects throughout the run
- All standard game mechanics remain intact

### **Bonus Rewards**
- **XP Multipliers**: 1.3x to 1.6x based on event theme
- **Coin Multipliers**: 1.2x to 1.5x based on event theme
- **Bonus Calculations**: Applied to base rewards after game completion
- **Temporary Cosmetics**: Exclusive themed skins and trails

### **Event Rotation**
- Events automatically cycle every hour
- Random selection from 4 available themes
- Portal display updates to show current event
- Seamless transitions between events

## 🏆 **Quest Integration**

### **Event-Specific Quests**
- **🎪 Event Enthusiast**: Complete 2 Event Runs → 300 coins
- **🌟 Theme Master**: Score 20+ points in Event Run → Cosmic Aura effect

### **Quest Tracking**
- Event runs count as separate quest category
- High scores in events tracked independently
- Special rewards for event completion achievements

## 📊 **Analytics & Progression**

### **Event Analytics**
- `EVENT_RUN_START`: Tracks event participation by theme
- `EVENT_RUN_END`: Records completion data, bonuses, and performance
- Event-specific metrics for balancing and engagement analysis

### **XP System Integration**
- Event XP multipliers stack with base XP calculation
- Perfect game and high score bonuses still apply
- Level progression accelerated during events

## 🎨 **Visual Effects System**

### **Lighting Themes**
Each event applies unique lighting configurations:
- **Ambient/Outdoor lighting** adjustments
- **Color shifting** effects for atmosphere
- **Fog effects** for immersion
- **Dynamic lighting** animations

### **Temporary Cosmetics**
- **Duration**: 5 minutes from event start
- **Auto-removal**: System automatically restores defaults
- **Visual Effects**: Theme-matching particle effects and materials
- **Player Customization**: Temporary overrides of normal appearance

## 🔧 **Technical Implementation**

### **Server Architecture**
- **EventService**: Manages event logic, rotations, and rewards
- **GameService Integration**: Special event game mode support
- **Quest System**: Event-specific quest types and tracking
- **Analytics**: Comprehensive event metrics collection

### **Client Architecture**  
- **EventController**: Handles visual effects, music, and notifications
- **Lighting Management**: Theme-specific atmosphere changes
- **UI Notifications**: Event start/completion celebrations
- **Cosmetic Application**: Temporary appearance modifications

### **Data Flow**
1. Player interacts with Event Portal
2. Server validates and starts event game
3. Client receives event theme data and applies effects
4. Game proceeds with enhanced visuals and music
5. Completion triggers bonus calculations and notifications
6. Analytics and quest progress updated
7. Temporary effects automatically expire

## 🚀 **Future Expansion Opportunities**

### **Additional Themes**
- Space/Galaxy theme with cosmic effects
- Underwater theme with bubble effects  
- Desert/Sand theme with particle storms
- Forest/Nature theme with organic effects

### **Event Mechanics**
- Limited-time exclusive events (holidays, seasons)
- Community events with shared goals
- Event leaderboards and competitions
- Special event-only cosmetics and rewards

### **Advanced Features**
- Player voting on next event theme
- Custom event creation tools
- Cross-event achievement chains
- Event-specific barrier types and mechanics

---

The Event Run system provides a dynamic, engaging layer to the base Color Rush experience, offering players fresh content, visual variety, and enhanced progression opportunities while maintaining the core gameplay loop that players love.
