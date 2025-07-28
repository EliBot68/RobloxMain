# Developer Testing Tools

This document describes the comprehensive developer testing tools available in the game.

## 🛠️ Overview

The developer tools provide a complete testing suite that includes:
- **GUI Teleportation**: Quick travel to any track or location
- **Economy Testing**: Grant coins and XP for balance testing  
- **Save Management**: Reset player data or skip tutorial
- **Error Monitoring**: Real-time console error tracking and asset validation
- **Content Unlocking**: Instantly unlock all content for testing

## 🔑 Access Control

Developer tools are **only accessible** to authorized developers:
- Players with UserIDs in the `DEVELOPER_IDS` list
- Game owner (when testing in Studio)
- **All other players cannot see or use these tools**

## 🎮 Developer GUI

### Opening the GUI
- **Keyboard Shortcut**: Press `F9` to toggle the developer tools GUI
- **Welcome Message**: Developers see a chat notification when they join

### GUI Features

#### 🚀 Teleportation Section
- **Teleport to Hub**: Return to main hub area
- **Teleport to Track1**: Go to beginner track
- **Teleport to Track2**: Go to intermediate track  
- **Teleport to Track3**: Go to advanced track
- **Visual Effects**: Teleportation includes blue particle effects and sounds

#### 💰 Economy Section
- **Grant 100 Coins**: Small coin amount for testing
- **Grant 1000 Coins**: Medium coin amount for testing
- **Grant 10000 Coins**: Large coin amount for testing
- **Grant 50 XP**: Small XP amount for testing
- **Grant 500 XP**: Medium XP amount for testing
- **Grant 5000 XP**: Large XP amount for testing
- **Level Calculation**: XP grants automatically update player level

#### 👤 Player Data Section
- **Reset Player Save**: ⚠️ **Permanent action** - Completely resets all player data
  - Shows confirmation dialog before executing
  - Kicks player to reload with fresh data
- **Skip Tutorial**: Marks tutorial as completed for current player

#### 🐛 Debug Section
- **Log Missing Assets**: Check for missing textures, sounds, meshes
- **Check Script Errors**: Scan for runtime script errors and syntax issues
- **Real-time Monitoring**: Continuous monitoring of console errors

#### 🧪 Testing Section
- **Unlock All Content**: Instantly unlock all tracks, cosmetics, and upgrades
- **Max Player Stats**: Set player to level 100 with maximum coins and stats

## 🖥️ Console Error Monitoring

### Automatic Error Detection
The system automatically monitors and logs:
- **Script Errors**: Runtime errors, syntax errors, missing modules
- **Asset Loading Failures**: Missing textures, sounds, meshes
- **Missing Objects**: Required workspace objects and folder structure
- **High Asset Queue**: Warns when asset loading queue gets too large

### Error Categories
- **SCRIPT**: Lua script errors with stack traces
- **ASSET**: Failed asset loading (textures, sounds, meshes)
- **MISSING_OBJECT**: Required workspace objects not found
- **MISSING_TRACK**: Game tracks not found in workspace
- **MISSING_FOLDER**: Required folder structure missing

### Error Reporting
- **Real-time Notifications**: Developers get instant notifications of new errors
- **Detailed Reports**: Comprehensive error reports with timestamps and context
- **Error History**: Maintains log of all errors for analysis
- **Recent Error Filtering**: Shows only errors from last 5 minutes for quick debugging

## 🔧 Technical Implementation

### Architecture
```
DeveloperToolsController (Client)
├── GUI Creation and Management
├── User Input Handling (F9 toggle)
└── Service Communication

DeveloperService (Server) 
├── Economy Manipulation (coins, XP)
├── Save Data Management
├── Content Unlocking
└── Developer Authentication

TeleportService (Enhanced)
├── Safe Teleportation with Effects
├── Track Position Management
└── Developer Teleport Functions

ConsoleMonitorService (Server)
├── Real-time Error Monitoring  
├── Asset Validation
├── Script Error Detection
└── Error Reporting & Analytics
```

### Security Features
- **UserID Validation**: Only authorized developers can access tools
- **Server-side Verification**: All commands validated on server
- **Action Logging**: All developer actions are logged for audit
- **Confirmation Dialogs**: Destructive actions require confirmation

## 🎯 Usage Examples

### Testing New Economy Balance
1. Open developer tools with `F9`
2. Use "Grant Coins" buttons to test different amounts
3. Check upgrade prices with various coin amounts
4. Use "Grant XP" to test level scaling
5. Use "Reset Player Save" to test fresh player experience

### Debugging Missing Assets
1. Use "Log Missing Assets" to see current errors
2. Check console for detailed error messages
3. Use "Check Script Errors" to find code issues
4. Monitor real-time as you test different game features

### Content Testing
1. Use "Unlock All Content" to access everything instantly
2. Teleport between tracks to test each one
3. Use "Max Player Stats" to test high-level gameplay
4. Use "Skip Tutorial" to test experienced player flow

## ⚠️ Important Notes

### Safety Warnings
- **"Reset Player Save" is permanent** - Always confirm before using
- **Only use in development** - Never use these tools in production
- **Regular players cannot access** - Tools are invisible to non-developers

### Performance Considerations
- Error monitoring runs continuously but with minimal performance impact
- Large teleportation distances may cause brief loading delays
- Granting very large amounts of currency should be done in smaller increments

### Best Practices
1. **Test incrementally** - Make small changes and test frequently
2. **Use real scenarios** - Test with realistic player progression
3. **Monitor errors actively** - Check error logs regularly during development
4. **Document issues** - Note any bugs found for fixing
5. **Clean up after testing** - Reset save data when switching test scenarios

## 🔄 Integration with Game Systems

The developer tools integrate seamlessly with:
- **UnifiedDataService**: Save/load player data changes
- **EconomyBalanceService**: Respects balance calculations when granting currency
- **ReplicatedDataService**: Updates client UI in real-time
- **TutorialService**: Properly skips tutorial progression
- **LoggingService**: Records all developer actions for audit

This comprehensive testing suite ensures thorough testing of all game systems while maintaining security and preventing access by regular players.
