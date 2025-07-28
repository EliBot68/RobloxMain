# 🔥 Daily Streak System Documentation

## Overview
The Daily Streak system rewards players for consecutive daily logins with escalating coin rewards and special effects. Missing a day resets the streak, encouraging consistent engagement.

## 🎯 **Core Features**

### **Daily Streak Stall**
- Animated floating cylinder in MarketPlaza with particle effects
- Interactive through both clicking and walking into it
- Visual title "🔥 DAILY STREAK" with rotating and floating animations
- Bright orange neon material with golden particle sparkles

### **Streak Tracking**
- Tracks consecutive daily logins (UTC-based day calculation)
- Automatically resets to 1 if player misses a day
- Maintains longest streak record for achievement tracking
- Prevents double-claiming on the same day

## 💰 **Reward Structure**

### **Week 1 Rewards (Days 1-7)**
- **Day 1**: 10 coins - "Welcome back! Starting your streak!"
- **Day 2**: 15 coins - "Day 2! Keep it up!"
- **Day 3**: 20 coins - "Day 3! You're on a roll!"
- **Day 4**: 30 coins - "Day 4! Impressive dedication!"
- **Day 5**: 40 coins - "Day 5! Almost a week!"
- **Day 6**: 50 coins - "Day 6! One more for the weekly bonus!"
- **Day 7**: 75 coins + Golden Aura (5 min) - "WEEK COMPLETE! Amazing streak!"

### **Week 2 Rewards (Days 8-14)**
- **Day 8-13**: 25-50 coins with encouraging messages
- **Day 14**: 100 coins + Rainbow Explosion (10 min) - "TWO WEEKS! LEGENDARY STREAK!"

### **Extended Rewards**
- **Day 21**: 150 coins + Cosmic Aura (15 min) - "THREE WEEKS! COSMIC DEDICATION!"
- **Day 30**: 250 coins + Streak Master (20 min) - "ONE MONTH! STREAK MASTER ACHIEVED!"
- **Day 31+**: 60 coins default reward with long streak message

### **Special Effects**
- **Golden Aura**: Week completion celebration effect
- **Rainbow Explosion**: Two-week milestone with particle burst
- **Cosmic Aura**: Three-week achievement with cosmic particles
- **Streak Master**: Monthly milestone with ultimate visual effects

## 🎮 **User Experience**

### **Streak Interface**
- **Current Streak Display**: Shows current consecutive days
- **Longest Streak Record**: Displays personal best achievement
- **Today's Reward Preview**: Shows claimable reward amount and type
- **Tomorrow's Preview**: Incentivizes return with next day's reward
- **Claim Button**: Large, prominent button to collect reward
- **Status Indication**: Clear "Already Claimed" state when appropriate

### **Notification System**
- **Login Notification**: Appears 3 seconds after joining if reward available
- **Reward Celebration**: Full-screen notification with coin amount and message
- **Availability Alert**: Side notification encouraging stall visit
- **Sound Effects**: Escalating audio feedback for different milestone types

### **Visual Feedback**
- **Stall Animation**: Continuous rotation and floating motion
- **Particle Effects**: Golden sparkles emanating from stall
- **UI Animations**: Smooth transitions, scaling, and fading effects
- **Color Coding**: Green for claimable, gray for already claimed

## 🏆 **Quest Integration**

### **Streak-Based Quests**
- **🔥 Streak Warrior**: Maintain 3-day streak → 200 coins
- **👑 Dedication Master**: Achieve 7-day streak → Dedication Aura effect

### **Quest Synergy**
- Streak achievements automatically progress quest objectives
- Multiple reward layers encourage consistent engagement
- Long-term goals complement daily immediate rewards

## 📊 **Analytics & Data**

### **Tracked Metrics**
- `DAILY_STREAK_CLAIMED`: Records each reward claim with streak day and reward details
- `DAILY_STREAK_BROKEN`: Logs when streaks are broken and how many days missed
- **Longest Streak**: Personal achievement tracking
- **Total Rewards Claimed**: Lifetime engagement metric

### **Data Persistence**
- Secure DataStore implementation for streak progress
- UTC-based day calculation for global consistency
- Fail-safe data loading with graceful degradation
- Integration with main player data system

## 🔧 **Technical Implementation**

### **Server Architecture**
- **DailyStreakService**: Core streak logic, reward calculation, and data management
- **UTC Day Calculation**: Consistent global day boundaries
- **DataStore Integration**: Persistent streak tracking across sessions
- **Service Dependencies**: PlayerService, AnalyticsService, QuestService integration

### **Client Architecture**
- **StreakController**: UI management, notifications, and visual effects
- **Dynamic UI Generation**: Responsive interface based on streak data
- **Animation System**: Smooth transitions and celebratory effects
- **Sound Integration**: Audio feedback for different reward types

### **Data Flow**
1. Player joins game → Load streak data from DataStore
2. Check if new day → Update streak counter (continue/reset)
3. Determine if reward available → Show availability notification
4. Player interacts with stall → Display streak interface
5. Player claims reward → Update data, apply rewards, show celebration
6. Analytics and quest progress updated
7. Data saved to DataStore and synced with PlayerService

## 🚀 **Engagement Psychology**

### **Retention Mechanics**
- **Escalating Rewards**: Increasing value incentivizes longer streaks
- **Loss Aversion**: Fear of losing streak encourages daily returns
- **Achievement Recognition**: Longest streak tracking appeals to completionists
- **Immediate Gratification**: Instant coin rewards provide satisfaction

### **Milestone Celebrations**
- **Weekly Milestones**: Special effects at 7, 14, 21, 30 days
- **Visual Recognition**: Unique particle effects for major achievements
- **Social Proof**: Longest streak display creates aspiration
- **Progressive Messaging**: Encouraging messages build momentum

## 🔮 **Future Expansion Opportunities**

### **Enhanced Rewards**
- Exclusive cosmetics for long streaks (30+ days)
- Streak-based shop discounts
- VIP benefits for consistent players
- Seasonal streak bonuses

### **Social Features**
- Guild/friend streak competitions
- Global leaderboards for longest streaks
- Streak sharing and bragging rights
- Team streak challenges

### **Advanced Mechanics**
- Streak insurance (one missed day forgiveness)
- Double XP days for long streaks
- Streak multipliers for other game rewards
- Premium streak accelerators

---

The Daily Streak system creates a powerful retention loop that rewards consistency while providing immediate gratification, encouraging players to return daily and building long-term engagement with escalating rewards and achievement recognition.
