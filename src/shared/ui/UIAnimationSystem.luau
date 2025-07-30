-- UIAnimationSystem.luau
-- Performance-optimized animation library for UI components
-- Provides smooth, accessible animations with proper timing and easing

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local SafeRequire = require(ReplicatedStorage.Shared.utils.SafeRequire)
local UIDesignTokens = SafeRequire.require(ReplicatedStorage.Shared.ui.UIDesignTokens)

local UIAnimationSystem = {}

-- ========================================
-- ANIMATION CONFIGURATION
-- ========================================

local ANIMATION_PRESETS = {
    -- Micro-interactions (0-100ms)
    instant = {
        duration = 0,
        easing = Enum.EasingStyle.Linear,
        direction = Enum.EasingDirection.Out
    },
    
    immediate = {
        duration = 0.05,
        easing = Enum.EasingStyle.Quad,
        direction = Enum.EasingDirection.Out
    },
    
    -- Quick transitions (100-200ms)
    quick = {
        duration = 0.1,
        easing = Enum.EasingStyle.Quad,
        direction = Enum.EasingDirection.Out
    },
    
    snappy = {
        duration = 0.15,
        easing = Enum.EasingStyle.Back,
        direction = Enum.EasingDirection.Out
    },
    
    -- Standard transitions (200-500ms)
    smooth = {
        duration = 0.2,
        easing = Enum.EasingStyle.Quad,
        direction = Enum.EasingDirection.Out
    },
    
    standard = {
        duration = 0.3,
        easing = Enum.EasingStyle.Quart,
        direction = Enum.EasingDirection.Out
    },
    
    bounce = {
        duration = 0.4,
        easing = Enum.EasingStyle.Back,
        direction = Enum.EasingDirection.Out
    },
    
    -- Slow transitions (500ms+)
    gentle = {
        duration = 0.5,
        easing = Enum.EasingStyle.Sine,
        direction = Enum.EasingDirection.Out
    },
    
    dramatic = {
        duration = 0.8,
        easing = Enum.EasingStyle.Expo,
        direction = Enum.EasingDirection.Out
    },
    
    -- Special purpose animations
    elastic = {
        duration = 0.6,
        easing = Enum.EasingStyle.Elastic,
        direction = Enum.EasingDirection.Out
    },
    
    wobble = {
        duration = 0.4,
        easing = Enum.EasingStyle.Elastic,
        direction = Enum.EasingDirection.InOut
    }
}

local REDUCED_MOTION_PRESETS = {
    -- Accessibility: reduced motion alternatives
    instant = ANIMATION_PRESETS.instant,
    immediate = ANIMATION_PRESETS.instant,
    quick = {duration = 0.05, easing = Enum.EasingStyle.Linear},
    snappy = {duration = 0.05, easing = Enum.EasingStyle.Linear},
    smooth = {duration = 0.1, easing = Enum.EasingStyle.Linear},
    standard = {duration = 0.1, easing = Enum.EasingStyle.Linear},
    bounce = {duration = 0.1, easing = Enum.EasingStyle.Linear},
    gentle = {duration = 0.1, easing = Enum.EasingStyle.Linear},
    dramatic = {duration = 0.1, easing = Enum.EasingStyle.Linear},
    elastic = {duration = 0.1, easing = Enum.EasingStyle.Linear},
    wobble = {duration = 0.1, easing = Enum.EasingStyle.Linear}
}

-- Common animation patterns
local ANIMATION_PATTERNS = {
    -- Entrance animations
    fadeIn = {
        from = {BackgroundTransparency = 1, TextTransparency = 1},
        to = {BackgroundTransparency = 0, TextTransparency = 0},
        preset = "smooth"
    },
    
    slideInFromLeft = {
        from = {Position = UDim2.new(-1, 0, 0, 0)},
        to = {Position = UDim2.new(0, 0, 0, 0)},
        preset = "standard"
    },
    
    slideInFromRight = {
        from = {Position = UDim2.new(1, 0, 0, 0)},
        to = {Position = UDim2.new(0, 0, 0, 0)},
        preset = "standard"
    },
    
    slideInFromTop = {
        from = {Position = UDim2.new(0, 0, -1, 0)},
        to = {Position = UDim2.new(0, 0, 0, 0)},
        preset = "standard"
    },
    
    slideInFromBottom = {
        from = {Position = UDim2.new(0, 0, 1, 0)},
        to = {Position = UDim2.new(0, 0, 0, 0)},
        preset = "standard"
    },
    
    scaleIn = {
        from = {Size = UDim2.new(0, 0, 0, 0)},
        to = {Size = UDim2.new(1, 0, 1, 0)},
        preset = "bounce"
    },
    
    zoomIn = {
        from = {Size = UDim2.new(0.5, 0, 0.5, 0)},
        to = {Size = UDim2.new(1, 0, 1, 0)},
        preset = "smooth"
    },
    
    -- Exit animations
    fadeOut = {
        from = {BackgroundTransparency = 0, TextTransparency = 0},
        to = {BackgroundTransparency = 1, TextTransparency = 1},
        preset = "quick"
    },
    
    slideOutToLeft = {
        from = {Position = UDim2.new(0, 0, 0, 0)},
        to = {Position = UDim2.new(-1, 0, 0, 0)},
        preset = "quick"
    },
    
    slideOutToRight = {
        from = {Position = UDim2.new(0, 0, 0, 0)},
        to = {Position = UDim2.new(1, 0, 0, 0)},
        preset = "quick"
    },
    
    scaleOut = {
        from = {Size = UDim2.new(1, 0, 1, 0)},
        to = {Size = UDim2.new(0, 0, 0, 0)},
        preset = "quick"
    },
    
    -- Attention animations
    pulse = {
        from = {Size = UDim2.new(1, 0, 1, 0)},
        to = {Size = UDim2.new(1.1, 0, 1.1, 0)},
        preset = "gentle",
        repeat = true,
        reverses = true
    },
    
    shake = {
        keyframes = {
            {time = 0, properties = {Position = UDim2.new(0, 0, 0, 0)}},
            {time = 0.1, properties = {Position = UDim2.new(0, -10, 0, 0)}},
            {time = 0.2, properties = {Position = UDim2.new(0, 10, 0, 0)}},
            {time = 0.3, properties = {Position = UDim2.new(0, -10, 0, 0)}},
            {time = 0.4, properties = {Position = UDim2.new(0, 10, 0, 0)}},
            {time = 0.5, properties = {Position = UDim2.new(0, 0, 0, 0)}}
        },
        preset = "quick"
    },
    
    flash = {
        from = {BackgroundTransparency = 0},
        to = {BackgroundTransparency = 0.5},
        preset = "immediate",
        repeat = 3,
        reverses = true
    },
    
    -- State transitions
    hoverGrow = {
        from = {Size = UDim2.new(1, 0, 1, 0)},
        to = {Size = UDim2.new(1, 4, 1, 4)},
        preset = "quick"
    },
    
    pressScale = {
        from = {Size = UDim2.new(1, 0, 1, 0)},
        to = {Size = UDim2.new(0.95, 0, 0.95, 0)},
        preset = "immediate"
    },
    
    focusGlow = {
        from = {BackgroundColor3 = Color3.new(1, 1, 1)},
        to = {BackgroundColor3 = Color3.fromRGB(0, 122, 255)},
        preset = "smooth"
    }
}

-- ========================================
-- ANIMATION MANAGER
-- ========================================

local AnimationManager = {
    activeAnimations = {},
    animationQueue = {},
    performanceMode = false,
    reducedMotion = false,
    frameRate = 60,
    maxConcurrentAnimations = 20
}

-- Initialize animation system
function UIAnimationSystem.initialize()
    -- Check for reduced motion preference
    local tokens = UIDesignTokens.getTokens()
    local accessibilityMode = UIDesignTokens.getAccessibilityMode()
    
    if accessibilityMode == "reducedMotion" then
        AnimationManager.reducedMotion = true
        print("🎬 Animation system initialized with reduced motion")
    else
        print("🎬 Animation system initialized with full animations")
    end
    
    -- Monitor performance
    UIAnimationSystem.startPerformanceMonitoring()
end

-- ========================================
-- CORE ANIMATION FUNCTIONS
-- ========================================

function UIAnimationSystem.animate(element, animationConfig)
    if not element or not animationConfig then
        warn("Invalid animation parameters")
        return nil
    end
    
    -- Get animation preset
    local presets = AnimationManager.reducedMotion and REDUCED_MOTION_PRESETS or ANIMATION_PRESETS
    local preset = presets[animationConfig.preset] or presets.smooth
    
    -- Override duration if specified
    local duration = animationConfig.duration or preset.duration
    local easing = animationConfig.easing or preset.easing
    local direction = animationConfig.direction or preset.direction
    
    -- Performance check
    if AnimationManager.performanceMode and duration > 0.3 then
        duration = 0.1 -- Reduce duration in performance mode
    end
    
    -- Create tween info
    local tweenInfo = TweenInfo.new(
        duration,
        easing,
        direction,
        animationConfig.repeatCount or 0,
        animationConfig.reverses or false,
        animationConfig.delayTime or 0
    )
    
    -- Create and play tween
    local tween = TweenService:Create(element, tweenInfo, animationConfig.properties)
    
    -- Register animation
    local animationId = UIAnimationSystem.generateAnimationId()
    AnimationManager.activeAnimations[animationId] = {
        tween = tween,
        element = element,
        startTime = tick(),
        config = animationConfig
    }
    
    -- Clean up on completion
    tween.Completed:Connect(function()
        AnimationManager.activeAnimations[animationId] = nil
        
        if animationConfig.onComplete then
            pcall(animationConfig.onComplete)
        end
    end)
    
    tween:Play()
    
    return {
        id = animationId,
        tween = tween,
        cancel = function()
            tween:Cancel()
            AnimationManager.activeAnimations[animationId] = nil
        end,
        pause = function()
            tween:Pause()
        end,
        resume = function()
            tween:Play()
        end
    }
end

function UIAnimationSystem.animatePattern(element, patternName, config)
    config = config or {}
    
    local pattern = ANIMATION_PATTERNS[patternName]
    if not pattern then
        warn("Unknown animation pattern: " .. tostring(patternName))
        return nil
    end
    
    -- Handle keyframe animations
    if pattern.keyframes then
        return UIAnimationSystem.animateKeyframes(element, pattern.keyframes, config)
    end
    
    -- Prepare animation configuration
    local animationConfig = {
        properties = pattern.to,
        preset = config.preset or pattern.preset,
        duration = config.duration,
        easing = config.easing,
        direction = config.direction,
        repeatCount = config.repeatCount or (pattern.repeat and -1 or 0),
        reverses = config.reverses or pattern.reverses,
        delayTime = config.delayTime,
        onComplete = config.onComplete
    }
    
    -- Set initial state if specified
    if pattern.from then
        for property, value in pairs(pattern.from) do
            element[property] = value
        end
    end
    
    -- Store original values for restoration
    local originalValues = {}
    for property, _ in pairs(pattern.to) do
        originalValues[property] = element[property]
    end
    
    -- Create animation with restoration callback
    local originalOnComplete = animationConfig.onComplete
    animationConfig.onComplete = function()
        -- Restore original values if requested
        if config.restore then
            for property, value in pairs(originalValues) do
                element[property] = value
            end
        end
        
        if originalOnComplete then
            pcall(originalOnComplete)
        end
    end
    
    return UIAnimationSystem.animate(element, animationConfig)
end

function UIAnimationSystem.animateKeyframes(element, keyframes, config)
    config = config or {}
    
    local animations = {}
    local totalDuration = 0
    
    -- Calculate total duration
    for _, keyframe in ipairs(keyframes) do
        totalDuration = math.max(totalDuration, keyframe.time)
    end
    
    -- Create sequential animations
    for i, keyframe in ipairs(keyframes) do
        local delay = keyframe.time
        
        task.spawn(function()
            task.wait(delay)
            
            local animConfig = {
                properties = keyframe.properties,
                preset = config.preset or "quick",
                duration = config.stepDuration or 0.1,
                onComplete = (i == #keyframes) and config.onComplete or nil
            }
            
            local anim = UIAnimationSystem.animate(element, animConfig)
            table.insert(animations, anim)
        end)
    end
    
    return {
        animations = animations,
        cancel = function()
            for _, anim in ipairs(animations) do
                if anim.cancel then
                    anim.cancel()
                end
            end
        end
    }
end

-- ========================================
-- SPECIALIZED ANIMATION FUNCTIONS
-- ========================================

function UIAnimationSystem.fadeIn(element, config)
    config = config or {}
    return UIAnimationSystem.animatePattern(element, "fadeIn", config)
end

function UIAnimationSystem.fadeOut(element, config)
    config = config or {}
    return UIAnimationSystem.animatePattern(element, "fadeOut", config)
end

function UIAnimationSystem.slideIn(element, direction, config)
    config = config or {}
    local patternName = "slideInFrom" .. string.upper(string.sub(direction, 1, 1)) .. string.sub(direction, 2)
    return UIAnimationSystem.animatePattern(element, patternName, config)
end

function UIAnimationSystem.slideOut(element, direction, config)
    config = config or {}
    local patternName = "slideOutTo" .. string.upper(string.sub(direction, 1, 1)) .. string.sub(direction, 2)
    return UIAnimationSystem.animatePattern(element, patternName, config)
end

function UIAnimationSystem.scale(element, fromScale, toScale, config)
    config = config or {}
    
    local originalSize = element.Size
    local fromSize = UDim2.new(fromScale, 0, fromScale, 0)
    local toSize = UDim2.new(toScale, 0, toScale, 0)
    
    element.Size = fromSize
    
    return UIAnimationSystem.animate(element, {
        properties = {Size = toSize},
        preset = config.preset or "smooth",
        duration = config.duration,
        onComplete = function()
            if config.restore then
                element.Size = originalSize
            end
            if config.onComplete then
                pcall(config.onComplete)
            end
        end
    })
end

function UIAnimationSystem.pulse(element, config)
    config = config or {}
    return UIAnimationSystem.animatePattern(element, "pulse", config)
end

function UIAnimationSystem.shake(element, config)
    config = config or {}
    return UIAnimationSystem.animatePattern(element, "shake", config)
end

function UIAnimationSystem.flash(element, config)
    config = config or {}
    return UIAnimationSystem.animatePattern(element, "flash", config)
end

-- ========================================
-- SEQUENCE AND PARALLEL ANIMATIONS
-- ========================================

function UIAnimationSystem.sequence(animations)
    local sequenceControl = {
        currentIndex = 1,
        animations = animations,
        currentAnimation = nil,
        cancelled = false
    }
    
    local function playNext()
        if sequenceControl.cancelled or sequenceControl.currentIndex > #animations then
            return
        end
        
        local animConfig = animations[sequenceControl.currentIndex]
        sequenceControl.currentIndex = sequenceControl.currentIndex + 1
        
        -- Add completion handler to continue sequence
        local originalOnComplete = animConfig.onComplete
        animConfig.onComplete = function()
            if originalOnComplete then
                pcall(originalOnComplete)
            end
            playNext()
        end
        
        -- Execute animation based on type
        if animConfig.pattern then
            sequenceControl.currentAnimation = UIAnimationSystem.animatePattern(
                animConfig.element,
                animConfig.pattern,
                animConfig
            )
        else
            sequenceControl.currentAnimation = UIAnimationSystem.animate(
                animConfig.element,
                animConfig
            )
        end
    end
    
    -- Start sequence
    playNext()
    
    return {
        cancel = function()
            sequenceControl.cancelled = true
            if sequenceControl.currentAnimation and sequenceControl.currentAnimation.cancel then
                sequenceControl.currentAnimation.cancel()
            end
        end
    }
end

function UIAnimationSystem.parallel(animations)
    local parallelAnimations = {}
    local completedCount = 0
    local totalCount = #animations
    local onAllComplete = nil
    
    for _, animConfig in ipairs(animations) do
        -- Add completion tracking
        local originalOnComplete = animConfig.onComplete
        animConfig.onComplete = function()
            if originalOnComplete then
                pcall(originalOnComplete)
            end
            
            completedCount = completedCount + 1
            if completedCount >= totalCount and onAllComplete then
                pcall(onAllComplete)
            end
        end
        
        -- Execute animation
        local animation
        if animConfig.pattern then
            animation = UIAnimationSystem.animatePattern(
                animConfig.element,
                animConfig.pattern,
                animConfig
            )
        else
            animation = UIAnimationSystem.animate(
                animConfig.element,
                animConfig
            )
        end
        
        table.insert(parallelAnimations, animation)
    end
    
    return {
        animations = parallelAnimations,
        cancel = function()
            for _, anim in ipairs(parallelAnimations) do
                if anim.cancel then
                    anim.cancel()
                end
            end
        end,
        onComplete = function(callback)
            onAllComplete = callback
            if completedCount >= totalCount then
                pcall(callback)
            end
        end
    }
end

-- ========================================
-- SPRING ANIMATIONS
-- ========================================

function UIAnimationSystem.spring(element, targetProperties, config)
    config = config or {}
    
    local spring = {
        tension = config.tension or 170,
        friction = config.friction or 26,
        mass = config.mass or 1,
        velocity = config.velocity or 0,
        precision = config.precision or 0.01
    }
    
    local originalProperties = {}
    local currentProperties = {}
    
    -- Store original and current values
    for property, targetValue in pairs(targetProperties) do
        originalProperties[property] = element[property]
        currentProperties[property] = element[property]
    end
    
    local startTime = tick()
    local connection
    
    connection = RunService.Heartbeat:Connect(function()
        local dt = RunService.Heartbeat:Wait()
        local allSettled = true
        
        for property, targetValue in pairs(targetProperties) do
            local currentValue = currentProperties[property]
            local displacement = targetValue - currentValue
            
            if math.abs(displacement) > spring.precision then
                allSettled = false
                
                -- Simple spring physics
                local springForce = displacement * spring.tension
                local dampingForce = spring.velocity * spring.friction
                local acceleration = (springForce - dampingForce) / spring.mass
                
                spring.velocity = spring.velocity + acceleration * dt
                local newValue = currentValue + spring.velocity * dt
                
                currentProperties[property] = newValue
                element[property] = newValue
            end
        end
        
        if allSettled then
            connection:Disconnect()
            if config.onComplete then
                pcall(config.onComplete)
            end
        end
    end)
    
    return {
        cancel = function()
            connection:Disconnect()
        end
    }
end

-- ========================================
-- PERFORMANCE MONITORING
-- ========================================

function UIAnimationSystem.startPerformanceMonitoring()
    local frameTime = 0
    local frameCount = 0
    
    RunService.Heartbeat:Connect(function(deltaTime)
        frameTime = frameTime + deltaTime
        frameCount = frameCount + 1
        
        -- Check every second
        if frameTime >= 1 then
            local fps = frameCount / frameTime
            AnimationManager.frameRate = fps
            
            -- Enable performance mode if FPS drops below 30
            if fps < 30 and #AnimationManager.activeAnimations > 5 then
                AnimationManager.performanceMode = true
                UIAnimationSystem.optimizeAnimations()
            elseif fps > 45 then
                AnimationManager.performanceMode = false
            end
            
            frameTime = 0
            frameCount = 0
        end
    end)
end

function UIAnimationSystem.optimizeAnimations()
    if not AnimationManager.performanceMode then
        return
    end
    
    -- Cancel non-essential animations if too many are running
    if #AnimationManager.activeAnimations > AnimationManager.maxConcurrentAnimations then
        local animationsToCancel = {}
        
        for id, animData in pairs(AnimationManager.activeAnimations) do
            -- Cancel older, less important animations
            if tick() - animData.startTime > 0.5 then
                table.insert(animationsToCancel, id)
            end
        end
        
        for _, id in ipairs(animationsToCancel) do
            local animData = AnimationManager.activeAnimations[id]
            if animData and animData.tween then
                animData.tween:Cancel()
                AnimationManager.activeAnimations[id] = nil
            end
        end
        
        print("🎬 Optimized animations: cancelled " .. #animationsToCancel .. " animations")
    end
end

-- ========================================
-- UTILITY FUNCTIONS
-- ========================================

function UIAnimationSystem.generateAnimationId()
    return "anim_" .. tick() .. "_" .. math.random(1000, 9999)
end

function UIAnimationSystem.getActiveAnimationCount()
    local count = 0
    for _ in pairs(AnimationManager.activeAnimations) do
        count = count + 1
    end
    return count
end

function UIAnimationSystem.cancelAllAnimations()
    for id, animData in pairs(AnimationManager.activeAnimations) do
        if animData.tween then
            animData.tween:Cancel()
        end
    end
    AnimationManager.activeAnimations = {}
    print("🎬 Cancelled all active animations")
end

function UIAnimationSystem.setPerformanceMode(enabled)
    AnimationManager.performanceMode = enabled
    print("🎬 Performance mode: " .. (enabled and "enabled" or "disabled"))
end

function UIAnimationSystem.setReducedMotion(enabled)
    AnimationManager.reducedMotion = enabled
    print("🎬 Reduced motion: " .. (enabled and "enabled" or "disabled"))
end

function UIAnimationSystem.getAnimationPresets()
    return AnimationManager.reducedMotion and REDUCED_MOTION_PRESETS or ANIMATION_PRESETS
end

function UIAnimationSystem.getAnimationPatterns()
    return ANIMATION_PATTERNS
end

function UIAnimationSystem.getPerformanceMetrics()
    return {
        activeAnimations = UIAnimationSystem.getActiveAnimationCount(),
        frameRate = AnimationManager.frameRate,
        performanceMode = AnimationManager.performanceMode,
        reducedMotion = AnimationManager.reducedMotion
    }
end

-- Initialize the animation system
UIAnimationSystem.initialize()

print("🎬 UIAnimationSystem initialized with performance optimization")

return UIAnimationSystem
