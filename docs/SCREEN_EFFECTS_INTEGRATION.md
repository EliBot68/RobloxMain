# Screen Effects System Integration Guide

## 🎬 Overview
The Screen Effects System provides immersive visual feedback for game actions including speed boosts, jumps, and death effects. All effects use TweenService and camera manipulation for smooth, performance-optimized animations.

## 📁 File Structure
```
src/
├── client/controllers/
│   └── ScreenEffectsController.client.luau    # Main client controller
├── server/services/
│   └── ScreenEffectsService.server.luau       # Server-side event management
├── server/testing/
│   └── ScreenEffectsTest.server.luau          # Testing and demo script
└── shared/modules/
    └── ScreenEffectsConfig.luau               # Configuration settings
```

## 🚀 Quick Start

### 1. Server-Side Usage
```lua
local ScreenEffectsService = require(path.to.ScreenEffectsService)

-- Trigger speed boost for a player
ScreenEffectsService:TriggerSpeedBoost(player, 3.0) -- 3 second duration

-- Trigger jump effect with custom power
ScreenEffectsService:TriggerJump(player, 1.5) -- 1.5x normal jump

-- Trigger screen shake (impact, explosion, etc.)
ScreenEffectsService:TriggerShake(player, 2.0, 1.0) -- intensity, duration

-- Flash effect (damage, pickup, etc.)
ScreenEffectsService:TriggerFlash(player, Color3.fromRGB(255, 0, 0), 0.5, 0.3)

-- Death effect
ScreenEffectsService:TriggerDeath(player)

-- Respawn effect
ScreenEffectsService:TriggerRespawn(player)
```

### 2. Client-Side Usage
```lua
local ScreenEffectsController = require(path.to.ScreenEffectsController)

-- Direct client calls (for immediate feedback)
ScreenEffectsController:SpeedBoost(2.0)
ScreenEffectsController:Jump(1.0)
ScreenEffectsController:Flash(Color3.new(1, 1, 1), 0.5, 0.2)
ScreenEffectsController:Shake(1.5, 0.5)
```

## 🎮 Integration Examples

### Speed Boost Integration
```lua
-- In your speed boost pickup script
local function onSpeedBoostCollected(player)
    -- Apply speed boost to character
    local character = player.Character
    local humanoid = character:FindFirstChild("Humanoid")
    if humanoid then
        humanoid.WalkSpeed = 32 -- Normal: 16
        
        -- Trigger visual effect
        ScreenEffectsService:TriggerSpeedBoost(player, 5.0)
        
        -- Reset after duration
        spawn(function()
            wait(5)
            humanoid.WalkSpeed = 16
        end)
    end
end
```

### Jump Enhancement Integration
```lua
-- In your jump pad or super jump script
local function onJumpPadTouched(hit, jumpPower)
    local character = hit.Parent
    local humanoid = character:FindFirstChildOfClass("Humanoid")
    local player = Players:GetPlayerFromCharacter(character)
    
    if humanoid and player then
        -- Apply jump
        humanoid.JumpHeight = jumpPower or 50
        humanoid.Jump = true
        
        -- Trigger visual effect based on jump power
        local effectPower = (jumpPower or 50) / 50 -- Normalize to 1.0
        ScreenEffectsService:TriggerJump(player, effectPower)
    end
end
```

### Combat Integration
```lua
-- In your combat/damage script
local function onPlayerDamaged(player, damage, damageType)
    local character = player.Character
    local humanoid = character:FindFirstChild("Humanoid")
    
    if humanoid then
        humanoid.Health = humanoid.Health - damage
        
        -- Screen shake based on damage
        local shakeIntensity = math.min(damage / 20, 3.0) -- Max shake at 60+ damage
        ScreenEffectsService:TriggerShake(player, shakeIntensity, 0.5)
        
        -- Flash effect based on damage type
        local flashColor = Color3.fromRGB(255, 100, 100) -- Red for damage
        if damageType == "fire" then
            flashColor = Color3.fromRGB(255, 140, 0) -- Orange for fire
        elseif damageType == "ice" then
            flashColor = Color3.fromRGB(150, 220, 255) -- Blue for ice
        end
        
        ScreenEffectsService:TriggerFlash(player, flashColor, 0.4, 0.2)
        
        -- Death effect if health depleted
        if humanoid.Health <= 0 then
            ScreenEffectsService:TriggerDeath(player)
        end
    end
end
```

### Collectible Integration
```lua
-- In your collectible/pickup script
local function onCollectiblePickup(player, collectibleType, value)
    local flashColor = Color3.new(1, 1, 1) -- Default white
    local flashIntensity = 0.3
    
    if collectibleType == "coin" then
        flashColor = Color3.fromRGB(255, 215, 0) -- Gold
        flashIntensity = 0.4
    elseif collectibleType == "gem" then
        flashColor = Color3.fromRGB(100, 255, 100) -- Green
        flashIntensity = 0.5
    elseif collectibleType == "powerup" then
        flashColor = Color3.fromRGB(255, 100, 255) -- Magenta
        flashIntensity = 0.6
        -- Also add screen shake for powerups
        ScreenEffectsService:TriggerShake(player, 0.8, 0.3)
    end
    
    ScreenEffectsService:TriggerFlash(player, flashColor, flashIntensity, 0.25)
end
```

## ⚙️ Configuration

### Using Presets
```lua
local ScreenEffectsConfig = require(path.to.ScreenEffectsConfig)

-- Apply different effect intensities
ScreenEffectsConfig:ApplyPreset("Subtle")    -- For sensitive players
ScreenEffectsConfig:ApplyPreset("Standard")  -- Default experience
ScreenEffectsConfig:ApplyPreset("Intense")   -- Dramatic effects
ScreenEffectsConfig:ApplyPreset("Mobile")    -- Mobile-optimized
```

### Custom Configuration
```lua
-- Modify specific effect parameters
ScreenEffectsConfig.SpeedBoost.fovIncrease = 20  -- More dramatic FOV change
ScreenEffectsConfig.Jump.shakeIntensity = 2.0    -- Stronger jump shake
ScreenEffectsConfig.Death.fadeDuration = 3.0     -- Longer death fade
```

### Theme System
```lua
-- Apply seasonal or themed effects
ScreenEffectsConfig:SetTheme("Halloween")  -- Orange tints
ScreenEffectsConfig:SetTheme("Christmas")  -- Red/green colors
ScreenEffectsConfig:SetTheme("Neon")       -- Bright, electric colors
```

## 🧪 Testing Commands

Enable chat commands for testing (automatically enabled in test script):

- `!speedboost [duration]` - Trigger speed boost effect
- `!jump [power]` - Trigger jump effect  
- `!shake [intensity] [duration]` - Trigger screen shake
- `!flash [r] [g] [b] [intensity]` - Trigger colored flash
- `!death` - Trigger death effect
- `!respawn` - Trigger respawn effect
- `!testall` - Run complete test sequence
- `!combo` - Test combination effects

## 📱 Mobile Optimization

The system automatically detects mobile devices and applies optimizations:

- Reduced motion blur intensity
- Simplified camera shake patterns
- Faster transition animations
- Touch-friendly scaling
- Performance-optimized effects

## 🎯 Performance Considerations

### Automatic Optimizations
- Effects are automatically reduced if FPS drops below 30
- Maximum of 3 concurrent effects per player
- Mobile devices get simplified effects
- Blur effects are reduced on lower-end devices

### Manual Optimization
```lua
-- Disable effects for very low-end devices
if somePerformanceCheck() then
    ScreenEffectsConfig.General.effectQuality = "Low"
    ScreenEffectsConfig.General.maxConcurrentEffects = 1
end
```

## 🔧 Troubleshooting

### Effects Not Appearing
1. Check that `ScreenEffectsController` is running on client
2. Verify `ScreenEffectsService` is running on server
3. Ensure `Events` folder exists in ReplicatedStorage
4. Check for script errors in output

### Performance Issues
1. Lower effect quality in config
2. Reduce concurrent effect limit
3. Enable mobile optimizations
4. Check for excessive rapid-fire effects

### Effects Too Subtle/Intense
1. Adjust config values in `ScreenEffectsConfig`
2. Use appropriate presets
3. Consider player accessibility needs
4. Test on different devices

## 🔄 Future Enhancements

Planned features for future updates:
- Sound integration with effects
- Particle effect integration
- VR-specific optimizations
- Advanced accessibility options
- Custom effect scripting API
- Analytics and usage tracking

## 📞 Support

For issues or questions:
1. Check configuration settings
2. Test with included test script
3. Review integration examples
4. Verify all scripts are properly placed
5. Check for console errors

The Screen Effects System is designed to be plug-and-play while remaining highly customizable for your specific game needs!
