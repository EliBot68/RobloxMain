-- AccessibilityNotificationSystem.luau
-- Mobile accessibility features and push notification management
-- Handles voice control, assistive technologies, and notification services

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local GuiService = game:GetService("GuiService")
local TweenService = game:GetService("TweenService")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TextService = game:GetService("TextService")
local StarterGui = game:GetService("StarterGui")
local LocalizationService = game:GetService("LocalizationService")
local SoundService = game:GetService("SoundService")

local SafeRequire = require(ReplicatedStorage.Shared.utils.SafeRequire)

local AccessibilityNotificationSystem = {}

-- ========================================
-- ACCESSIBILITY CONFIGURATION
-- ========================================

local ACCESSIBILITY_CONFIG = {
    -- Voice control settings
    voiceControl = {
        enabled = false,
        sensitivity = 0.7,
        timeout = 3.0,
        commands = {
            ["tap"] = "tap",
            ["click"] = "tap",
            ["press"] = "tap",
            ["swipe left"] = "swipe_left",
            ["swipe right"] = "swipe_right",
            ["swipe up"] = "swipe_up",
            ["swipe down"] = "swipe_down",
            ["go back"] = "back",
            ["menu"] = "menu",
            ["settings"] = "settings",
            ["help"] = "help",
            ["pause"] = "pause",
            ["play"] = "play",
            ["start"] = "start",
            ["stop"] = "stop"
        }
    },
    
    -- Assistive touch settings
    assistiveTouch = {
        enabled = false,
        size = UDim2.new(0, 60, 0, 60),
        position = UDim2.new(1, -80, 0.5, -30),
        opacity = 0.8,
        actions = {
            "Tap",
            "Long Press",
            "Swipe",
            "Menu",
            "Back",
            "Settings"
        }
    },
    
    -- Visual accessibility
    visualAccessibility = {
        highContrast = false,
        largeText = false,
        reducedMotion = false,
        colorBlindFriendly = false,
        screenReader = false,
        
        contrastRatio = 4.5, -- WCAG AA standard
        textScaling = {
            normal = 1.0,
            large = 1.2,
            extraLarge = 1.5,
            accessibility = 2.0
        },
        
        colorPalette = {
            normal = {
                primary = Color3.fromRGB(33, 150, 243),
                secondary = Color3.fromRGB(76, 175, 80),
                accent = Color3.fromRGB(255, 193, 7),
                background = Color3.fromRGB(245, 245, 245),
                text = Color3.fromRGB(33, 33, 33)
            },
            highContrast = {
                primary = Color3.fromRGB(0, 0, 0),
                secondary = Color3.fromRGB(255, 255, 255),
                accent = Color3.fromRGB(255, 255, 0),
                background = Color3.fromRGB(255, 255, 255),
                text = Color3.fromRGB(0, 0, 0)
            },
            colorBlind = {
                primary = Color3.fromRGB(0, 119, 187),     -- Blue
                secondary = Color3.fromRGB(238, 119, 51),   -- Orange
                accent = Color3.fromRGB(204, 187, 68),      -- Yellow-brown
                background = Color3.fromRGB(245, 245, 245),
                text = Color3.fromRGB(68, 68, 68)
            }
        }
    },
    
    -- Motor accessibility
    motorAccessibility = {
        touchAssist = false,
        dwellClick = false,
        stickyKeys = false,
        slowKeys = false,
        
        dwellTime = 1.5, -- seconds
        touchAreaExpansion = 1.3, -- multiplier
        gestureSimplification = true,
        alternativeInputs = true
    },
    
    -- Cognitive accessibility
    cognitiveAccessibility = {
        simplifiedUI = false,
        focusAssist = false,
        timeoutExtension = false,
        readingAssist = false,
        
        simplificationLevel = 1, -- 1-3
        focusIndicatorSize = 3, -- pixels
        timeoutMultiplier = 2.0,
        readingSpeed = 200 -- words per minute
    },
    
    -- Audio accessibility
    audioAccessibility = {
        subtitles = false,
        audioDescriptions = false,
        visualIndicators = false,
        hapticFeedback = true,
        
        subtitleSize = 16,
        subtitleBackground = true,
        visualAlerts = true,
        hapticPatterns = {
            notification = {0.3, 0.1, 0.3},
            warning = {0.5, 0.1, 0.5, 0.1, 0.5},
            success = {0.2, 0.1, 0.2, 0.1, 0.4}
        }
    }
}

-- ========================================
-- NOTIFICATION CONFIGURATION
-- ========================================

local NOTIFICATION_CONFIG = {
    -- Push notification settings
    pushNotifications = {
        enabled = true,
        channels = {
            general = { priority = "normal", sound = true, vibration = true },
            achievements = { priority = "low", sound = true, vibration = false },
            events = { priority = "high", sound = true, vibration = true },
            social = { priority = "normal", sound = false, vibration = true },
            system = { priority = "high", sound = true, vibration = true }
        },
        
        scheduling = {
            quietHours = {
                enabled = false,
                start = 22, -- 10 PM
                end = 8    -- 8 AM
            },
            
            frequency = {
                immediate = 0,
                low = 3600,      -- 1 hour
                normal = 1800,   -- 30 minutes
                high = 300       -- 5 minutes
            }
        },
        
        personalization = {
            adaptiveScheduling = true,
            userPreferences = true,
            contextAware = true,
            locationBased = false
        }
    },
    
    -- In-app notifications
    inAppNotifications = {
        enabled = true,
        position = "top", -- top, bottom, center
        duration = 4.0,   -- seconds
        maxVisible = 3,
        
        types = {
            info = {
                color = Color3.fromRGB(33, 150, 243),
                icon = "ℹ️",
                sound = "notification_info"
            },
            warning = {
                color = Color3.fromRGB(255, 193, 7),
                icon = "⚠️",
                sound = "notification_warning"
            },
            error = {
                color = Color3.fromRGB(244, 67, 54),
                icon = "❌",
                sound = "notification_error"
            },
            success = {
                color = Color3.fromRGB(76, 175, 80),
                icon = "✅",
                sound = "notification_success"
            }
        }
    },
    
    -- Background processing
    backgroundProcessing = {
        enabled = true,
        maxDuration = 30, -- seconds
        priority = "normal",
        
        tasks = {
            dataSync = { interval = 300, priority = "high" },    -- 5 minutes
            analytics = { interval = 600, priority = "low" },    -- 10 minutes
            maintenance = { interval = 1800, priority = "low" }  -- 30 minutes
        }
    }
}

-- ========================================
-- ACCESSIBILITY STATE
-- ========================================

local AccessibilityState = {
    -- Current accessibility settings
    currentSettings = {
        voiceControl = false,
        assistiveTouch = false,
        highContrast = false,
        largeText = false,
        reducedMotion = false,
        screenReader = false,
        touchAssist = false,
        subtitles = false
    },
    
    -- Voice control system
    voiceController = {
        active = false,
        listening = false,
        lastCommand = "",
        commandHistory = {},
        recognitionEngine = nil
    },
    
    -- Assistive touch system
    assistiveTouchController = {
        active = false,
        menu = nil,
        menuOpen = false,
        currentAction = nil
    },
    
    -- Screen reader system
    screenReader = {
        active = false,
        currentElement = nil,
        readingQueue = {},
        speaking = false,
        readingSpeed = 200
    },
    
    -- Visual accessibility
    visualController = {
        contrastMode = "normal",
        textScale = 1.0,
        motionReduced = false,
        currentPalette = "normal"
    },
    
    -- Focus management
    focusManager = {
        currentFocus = nil,
        focusHistory = {},
        focusVisible = true
    }
}

-- ========================================
-- NOTIFICATION STATE
-- ========================================

local NotificationState = {
    -- Push notification system
    pushSystem = {
        initialized = false,
        token = nil,
        channels = {},
        subscriptions = {}
    },
    
    -- In-app notifications
    inAppSystem = {
        queue = {},
        visible = {},
        container = nil
    },
    
    -- Background processing
    backgroundSystem = {
        tasks = {},
        running = {},
        scheduler = nil
    },
    
    -- Notification history
    history = {
        sent = {},
        received = {},
        clicked = {},
        dismissed = {}
    }
}

function AccessibilityNotificationSystem.initialize()
    print("♿ Initializing AccessibilityNotificationSystem...")
    
    -- Initialize accessibility features
    AccessibilityNotificationSystem.initializeAccessibility()
    
    -- Initialize voice control
    AccessibilityNotificationSystem.initializeVoiceControl()
    
    -- Initialize assistive touch
    AccessibilityNotificationSystem.initializeAssistiveTouch()
    
    -- Initialize screen reader
    AccessibilityNotificationSystem.initializeScreenReader()
    
    -- Initialize visual accessibility
    AccessibilityNotificationSystem.initializeVisualAccessibility()
    
    -- Initialize push notifications
    AccessibilityNotificationSystem.initializePushNotifications()
    
    -- Initialize in-app notifications
    AccessibilityNotificationSystem.initializeInAppNotifications()
    
    -- Initialize background processing
    AccessibilityNotificationSystem.initializeBackgroundProcessing()
    
    print("♿ AccessibilityNotificationSystem initialized successfully")
end

-- ========================================
-- ACCESSIBILITY INITIALIZATION
-- ========================================

function AccessibilityNotificationSystem.initializeAccessibility()
    AccessibilityState.accessibilityManager = {
        settings = ACCESSIBILITY_CONFIG,
        
        enableFeature = function(self, featureName)
            AccessibilityState.currentSettings[featureName] = true
            AccessibilityNotificationSystem.applyAccessibilityFeature(featureName, true)
            print(string.format("♿ Enabled accessibility feature: %s", featureName))
        end,
        
        disableFeature = function(self, featureName)
            AccessibilityState.currentSettings[featureName] = false
            AccessibilityNotificationSystem.applyAccessibilityFeature(featureName, false)
            print(string.format("♿ Disabled accessibility feature: %s", featureName))
        end,
        
        toggleFeature = function(self, featureName)
            local current = AccessibilityState.currentSettings[featureName]
            if current then
                self:disableFeature(featureName)
            else
                self:enableFeature(featureName)
            end
        end,
        
        applyProfile = function(self, profileName)
            AccessibilityNotificationSystem.applyAccessibilityProfile(profileName)
        end
    }
    
    print("♿ Accessibility manager initialized")
end

function AccessibilityNotificationSystem.applyAccessibilityFeature(featureName, enabled)
    if featureName == "voiceControl" then
        if enabled then
            AccessibilityNotificationSystem.enableVoiceControl()
        else
            AccessibilityNotificationSystem.disableVoiceControl()
        end
    elseif featureName == "assistiveTouch" then
        if enabled then
            AccessibilityNotificationSystem.enableAssistiveTouch()
        else
            AccessibilityNotificationSystem.disableAssistiveTouch()
        end
    elseif featureName == "highContrast" then
        AccessibilityNotificationSystem.setContrastMode(enabled and "highContrast" or "normal")
    elseif featureName == "largeText" then
        AccessibilityNotificationSystem.setTextScale(enabled and 1.5 or 1.0)
    elseif featureName == "reducedMotion" then
        AccessibilityNotificationSystem.setMotionReduction(enabled)
    elseif featureName == "screenReader" then
        if enabled then
            AccessibilityNotificationSystem.enableScreenReader()
        else
            AccessibilityNotificationSystem.disableScreenReader()
        end
    end
end

function AccessibilityNotificationSystem.applyAccessibilityProfile(profileName)
    local profiles = {
        motor_impairment = {
            assistiveTouch = true,
            touchAssist = true,
            largeText = true,
            reducedMotion = true
        },
        
        visual_impairment = {
            screenReader = true,
            highContrast = true,
            largeText = true,
            subtitles = true
        },
        
        hearing_impairment = {
            subtitles = true,
            visualIndicators = true,
            hapticFeedback = true
        },
        
        cognitive_support = {
            simplifiedUI = true,
            focusAssist = true,
            reducedMotion = true,
            largeText = true
        }
    }
    
    local profile = profiles[profileName]
    if not profile then return end
    
    for feature, enabled in pairs(profile) do
        AccessibilityState.accessibilityManager:enableFeature(feature)
    end
    
    print(string.format("♿ Applied accessibility profile: %s", profileName))
end

-- ========================================
-- VOICE CONTROL
-- ========================================

function AccessibilityNotificationSystem.initializeVoiceControl()
    AccessibilityState.voiceController = {
        active = false,
        listening = false,
        commands = ACCESSIBILITY_CONFIG.voiceControl.commands,
        
        startListening = function(self)
            if not self.active then return end
            
            self.listening = true
            print("🎤 Voice control listening...")
            
            -- Simulate voice recognition
            spawn(function()
                task.wait(2) -- Listening duration
                if self.listening then
                    self:processVoiceInput("tap") -- Simulate recognized command
                    self.listening = false
                end
            end)
        end,
        
        stopListening = function(self)
            self.listening = false
            print("🎤 Voice control stopped listening")
        end,
        
        processVoiceInput = function(self, input)
            local command = self.commands[input:lower()]
            if command then
                AccessibilityNotificationSystem.executeVoiceCommand(command)
                table.insert(self.commandHistory, {
                    input = input,
                    command = command,
                    timestamp = tick()
                })
            else
                print(string.format("🎤 Unrecognized voice command: %s", input))
            end
        end
    }
    
    print("🎤 Voice control system initialized")
end

function AccessibilityNotificationSystem.enableVoiceControl()
    AccessibilityState.voiceController.active = true
    AccessibilityState.currentSettings.voiceControl = true
    
    -- Set up voice activation gesture or button
    AccessibilityNotificationSystem.setupVoiceActivation()
    
    print("🎤 Voice control enabled")
end

function AccessibilityNotificationSystem.disableVoiceControl()
    AccessibilityState.voiceController.active = false
    AccessibilityState.voiceController.listening = false
    AccessibilityState.currentSettings.voiceControl = false
    
    print("🎤 Voice control disabled")
end

function AccessibilityNotificationSystem.setupVoiceActivation()
    -- Create voice activation button or gesture
    local player = Players.LocalPlayer
    local playerGui = player:WaitForChild("PlayerGui")
    
    local voiceButton = Instance.new("TextButton")
    voiceButton.Name = "VoiceActivationButton"
    voiceButton.Size = UDim2.new(0, 50, 0, 50)
    voiceButton.Position = UDim2.new(0, 20, 1, -70)
    voiceButton.BackgroundColor3 = Color3.fromRGB(76, 175, 80)
    voiceButton.Text = "🎤"
    voiceButton.TextSize = 24
    voiceButton.TextColor3 = Color3.new(1, 1, 1)
    voiceButton.BorderSizePixel = 0
    voiceButton.Parent = playerGui
    
    -- Round button
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0.5, 0)
    corner.Parent = voiceButton
    
    -- Button functionality
    voiceButton.MouseButton1Click:Connect(function()
        if AccessibilityState.voiceController.listening then
            AccessibilityState.voiceController:stopListening()
        else
            AccessibilityState.voiceController:startListening()
        end
    end)
end

function AccessibilityNotificationSystem.executeVoiceCommand(command)
    print(string.format("🎤 Executing voice command: %s", command))
    
    if command == "tap" then
        -- Simulate tap at screen center
        local screenCenter = workspace.CurrentCamera.ViewportSize / 2
        AccessibilityNotificationSystem.simulateTouch(screenCenter)
    elseif command == "swipe_left" then
        AccessibilityNotificationSystem.simulateSwipe("left")
    elseif command == "swipe_right" then
        AccessibilityNotificationSystem.simulateSwipe("right")
    elseif command == "swipe_up" then
        AccessibilityNotificationSystem.simulateSwipe("up")
    elseif command == "swipe_down" then
        AccessibilityNotificationSystem.simulateSwipe("down")
    elseif command == "back" then
        AccessibilityNotificationSystem.navigateBack()
    elseif command == "menu" then
        AccessibilityNotificationSystem.openMenu()
    elseif command == "settings" then
        AccessibilityNotificationSystem.openSettings()
    elseif command == "help" then
        AccessibilityNotificationSystem.openHelp()
    end
end

function AccessibilityNotificationSystem.simulateTouch(position)
    -- Simulate touch input at position
    print(string.format("👆 Simulating touch at (%.0f, %.0f)", position.X, position.Y))
end

function AccessibilityNotificationSystem.simulateSwipe(direction)
    print(string.format("👆 Simulating swipe: %s", direction))
end

function AccessibilityNotificationSystem.navigateBack()
    print("⬅️ Navigating back")
end

function AccessibilityNotificationSystem.openMenu()
    print("📋 Opening menu")
end

function AccessibilityNotificationSystem.openSettings()
    print("⚙️ Opening settings")
end

function AccessibilityNotificationSystem.openHelp()
    print("❓ Opening help")
end

-- ========================================
-- ASSISTIVE TOUCH
-- ========================================

function AccessibilityNotificationSystem.initializeAssistiveTouch()
    AccessibilityState.assistiveTouchController = {
        active = false,
        menu = nil,
        menuOpen = false,
        
        createMenu = function(self)
            local player = Players.LocalPlayer
            local playerGui = player:WaitForChild("PlayerGui")
            
            -- Create assistive touch button
            local assistiveButton = Instance.new("TextButton")
            assistiveButton.Name = "AssistiveTouchButton"
            assistiveButton.Size = ACCESSIBILITY_CONFIG.assistiveTouch.size
            assistiveButton.Position = ACCESSIBILITY_CONFIG.assistiveTouch.position
            assistiveButton.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
            assistiveButton.BackgroundTransparency = 1 - ACCESSIBILITY_CONFIG.assistiveTouch.opacity
            assistiveButton.Text = "⚫"
            assistiveButton.TextSize = 20
            assistiveButton.TextColor3 = Color3.fromRGB(128, 128, 128)
            assistiveButton.BorderSizePixel = 2
            assistiveButton.BorderColor3 = Color3.fromRGB(200, 200, 200)
            assistiveButton.Parent = playerGui
            
            -- Round button
            local corner = Instance.new("UICorner")
            corner.CornerRadius = UDim.new(0.5, 0)
            corner.Parent = assistiveButton
            
            -- Create action menu
            local actionMenu = Instance.new("Frame")
            actionMenu.Name = "AssistiveTouchMenu"
            actionMenu.Size = UDim2.new(0, 200, 0, 150)
            actionMenu.Position = UDim2.new(0.5, -100, 0.5, -75)
            actionMenu.BackgroundColor3 = Color3.fromRGB(240, 240, 240)
            actionMenu.BackgroundTransparency = 0.1
            actionMenu.BorderSizePixel = 0
            actionMenu.Visible = false
            actionMenu.Parent = playerGui
            
            -- Round menu
            local menuCorner = Instance.new("UICorner")
            menuCorner.CornerRadius = UDim.new(0, 12)
            menuCorner.Parent = actionMenu
            
            -- Create action buttons
            local actions = ACCESSIBILITY_CONFIG.assistiveTouch.actions
            for i, action in ipairs(actions) do
                local actionButton = Instance.new("TextButton")
                actionButton.Name = action .. "Button"
                actionButton.Size = UDim2.new(0, 80, 0, 40)
                actionButton.Position = UDim2.new(0, 10 + ((i-1) % 2) * 90, 0, 10 + math.floor((i-1) / 2) * 50)
                actionButton.BackgroundColor3 = Color3.fromRGB(33, 150, 243)
                actionButton.Text = action
                actionButton.TextSize = 12
                actionButton.TextColor3 = Color3.new(1, 1, 1)
                actionButton.BorderSizePixel = 0
                actionButton.Parent = actionMenu
                
                -- Round action button
                local actionCorner = Instance.new("UICorner")
                actionCorner.CornerRadius = UDim.new(0, 6)
                actionCorner.Parent = actionButton
                
                -- Action button functionality
                actionButton.MouseButton1Click:Connect(function()
                    AccessibilityNotificationSystem.executeAssistiveAction(action)
                    self:hideMenu()
                end)
            end
            
            -- Main button functionality
            assistiveButton.MouseButton1Click:Connect(function()
                if self.menuOpen then
                    self:hideMenu()
                else
                    self:showMenu()
                end
            end)
            
            self.menu = {
                button = assistiveButton,
                menu = actionMenu
            }
        end,
        
        showMenu = function(self)
            if self.menu then
                self.menu.menu.Visible = true
                self.menuOpen = true
                
                -- Animate menu appearance
                local tween = TweenService:Create(self.menu.menu,
                    TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
                    {Size = UDim2.new(0, 200, 0, 150)}
                )
                tween:Play()
            end
        end,
        
        hideMenu = function(self)
            if self.menu then
                -- Animate menu disappearance
                local tween = TweenService:Create(self.menu.menu,
                    TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
                    {Size = UDim2.new(0, 0, 0, 0)}
                )
                tween:Play()
                
                tween.Completed:Connect(function()
                    self.menu.menu.Visible = false
                    self.menuOpen = false
                end)
            end
        end
    }
    
    print("👆 Assistive touch system initialized")
end

function AccessibilityNotificationSystem.enableAssistiveTouch()
    AccessibilityState.assistiveTouchController.active = true
    AccessibilityState.assistiveTouchController:createMenu()
    AccessibilityState.currentSettings.assistiveTouch = true
    
    print("👆 Assistive touch enabled")
end

function AccessibilityNotificationSystem.disableAssistiveTouch()
    AccessibilityState.assistiveTouchController.active = false
    AccessibilityState.currentSettings.assistiveTouch = false
    
    if AccessibilityState.assistiveTouchController.menu then
        AccessibilityState.assistiveTouchController.menu.button:Destroy()
        AccessibilityState.assistiveTouchController.menu.menu:Destroy()
        AccessibilityState.assistiveTouchController.menu = nil
    end
    
    print("👆 Assistive touch disabled")
end

function AccessibilityNotificationSystem.executeAssistiveAction(action)
    print(string.format("👆 Executing assistive action: %s", action))
    
    if action == "Tap" then
        AccessibilityNotificationSystem.simulateTouch(workspace.CurrentCamera.ViewportSize / 2)
    elseif action == "Long Press" then
        AccessibilityNotificationSystem.simulateLongPress()
    elseif action == "Swipe" then
        AccessibilityNotificationSystem.simulateSwipe("up")
    elseif action == "Menu" then
        AccessibilityNotificationSystem.openMenu()
    elseif action == "Back" then
        AccessibilityNotificationSystem.navigateBack()
    elseif action == "Settings" then
        AccessibilityNotificationSystem.openSettings()
    end
end

function AccessibilityNotificationSystem.simulateLongPress()
    print("👆 Simulating long press")
end

-- ========================================
-- SCREEN READER
-- ========================================

function AccessibilityNotificationSystem.initializeScreenReader()
    AccessibilityState.screenReader = {
        active = false,
        speaking = false,
        readingQueue = {},
        currentElement = nil,
        
        speak = function(self, text, priority)
            table.insert(self.readingQueue, {
                text = text,
                priority = priority or "normal",
                timestamp = tick()
            })
            
            if not self.speaking then
                self:processQueue()
            end
        end,
        
        processQueue = function(self)
            if #self.readingQueue == 0 then
                self.speaking = false
                return
            end
            
            self.speaking = true
            local item = table.remove(self.readingQueue, 1)
            
            print(string.format("🗣️ Speaking: %s", item.text))
            
            -- Simulate speech duration
            local words = #string.split(item.text, " ")
            local duration = words / (AccessibilityState.screenReader.readingSpeed / 60)
            
            spawn(function()
                task.wait(duration)
                self:processQueue()
            end)
        end,
        
        stopSpeaking = function(self)
            self.readingQueue = {}
            self.speaking = false
            print("🗣️ Screen reader stopped speaking")
        end,
        
        readElement = function(self, element)
            if not self.active then return end
            
            local text = AccessibilityNotificationSystem.getElementText(element)
            if text then
                self:speak(text, "high")
            end
        end
    }
    
    print("🗣️ Screen reader system initialized")
end

function AccessibilityNotificationSystem.enableScreenReader()
    AccessibilityState.screenReader.active = true
    AccessibilityState.currentSettings.screenReader = true
    
    -- Set up focus tracking for screen reader
    AccessibilityNotificationSystem.setupScreenReaderFocus()
    
    AccessibilityState.screenReader:speak("Screen reader enabled", "high")
    print("🗣️ Screen reader enabled")
end

function AccessibilityNotificationSystem.disableScreenReader()
    AccessibilityState.screenReader.active = false
    AccessibilityState.screenReader:stopSpeaking()
    AccessibilityState.currentSettings.screenReader = false
    
    print("🗣️ Screen reader disabled")
end

function AccessibilityNotificationSystem.setupScreenReaderFocus()
    -- Monitor GUI focus changes and read focused elements
    spawn(function()
        while AccessibilityState.screenReader.active do
            local focusedElement = AccessibilityNotificationSystem.getFocusedElement()
            if focusedElement ~= AccessibilityState.screenReader.currentElement then
                AccessibilityState.screenReader.currentElement = focusedElement
                AccessibilityState.screenReader:readElement(focusedElement)
            end
            task.wait(0.1)
        end
    end)
end

function AccessibilityNotificationSystem.getFocusedElement()
    -- Simplified focus detection
    return nil -- Would implement actual focus detection
end

function AccessibilityNotificationSystem.getElementText(element)
    if not element then return nil end
    
    if element:IsA("TextLabel") or element:IsA("TextButton") then
        return element.Text
    elseif element:IsA("ImageLabel") or element:IsA("ImageButton") then
        return element.Name or "Image"
    else
        return element.Name or "Interactive element"
    end
end

-- ========================================
-- VISUAL ACCESSIBILITY
-- ========================================

function AccessibilityNotificationSystem.initializeVisualAccessibility()
    AccessibilityState.visualController = {
        contrastMode = "normal",
        textScale = 1.0,
        motionReduced = false,
        currentPalette = "normal",
        
        updateVisuals = function(self)
            AccessibilityNotificationSystem.applyVisualSettings(self)
        end
    }
    
    print("👁️ Visual accessibility initialized")
end

function AccessibilityNotificationSystem.setContrastMode(mode)
    AccessibilityState.visualController.contrastMode = mode
    AccessibilityState.visualController.currentPalette = mode
    AccessibilityState.visualController:updateVisuals()
    
    print(string.format("👁️ Contrast mode set to: %s", mode))
end

function AccessibilityNotificationSystem.setTextScale(scale)
    AccessibilityState.visualController.textScale = scale
    AccessibilityState.visualController:updateVisuals()
    
    print(string.format("👁️ Text scale set to: %.1fx", scale))
end

function AccessibilityNotificationSystem.setMotionReduction(enabled)
    AccessibilityState.visualController.motionReduced = enabled
    AccessibilityState.visualController:updateVisuals()
    
    print(string.format("👁️ Motion reduction: %s", enabled and "enabled" or "disabled"))
end

function AccessibilityNotificationSystem.applyVisualSettings(controller)
    local palette = ACCESSIBILITY_CONFIG.visualAccessibility.colorPalette[controller.currentPalette]
    
    -- Apply color palette to UI elements
    -- This would iterate through all UI elements and update their colors
    
    -- Apply text scaling
    -- This would update text sizes based on the scale factor
    
    -- Apply motion settings
    -- This would disable/enable animations based on motion reduction setting
end

-- ========================================
-- PUSH NOTIFICATIONS
-- ========================================

function AccessibilityNotificationSystem.initializePushNotifications()
    NotificationState.pushSystem = {
        initialized = false,
        token = nil,
        channels = {},
        
        initialize = function(self)
            -- Initialize push notification service
            self.initialized = true
            self.token = "demo_token_" .. tostring(math.random(10000, 99999))
            
            -- Set up notification channels
            for channelName, settings in pairs(NOTIFICATION_CONFIG.pushNotifications.channels) do
                self.channels[channelName] = {
                    name = channelName,
                    settings = settings,
                    subscribed = true
                }
            end
            
            print("📱 Push notification system initialized")
        end,
        
        sendNotification = function(self, channel, title, message, data)
            if not self.initialized then return end
            
            local notification = {
                id = HttpService:GenerateGUID(false),
                channel = channel,
                title = title,
                message = message,
                data = data or {},
                timestamp = tick(),
                delivered = false
            }
            
            -- Check quiet hours
            if AccessibilityNotificationSystem.isQuietHours() then
                print(string.format("🔕 Notification queued (quiet hours): %s", title))
                return
            end
            
            -- Deliver notification
            AccessibilityNotificationSystem.deliverPushNotification(notification)
            
            -- Store in history
            table.insert(NotificationState.history.sent, notification)
        end,
        
        subscribeToChannel = function(self, channelName)
            if self.channels[channelName] then
                self.channels[channelName].subscribed = true
                print(string.format("📱 Subscribed to channel: %s", channelName))
            end
        end,
        
        unsubscribeFromChannel = function(self, channelName)
            if self.channels[channelName] then
                self.channels[channelName].subscribed = false
                print(string.format("📱 Unsubscribed from channel: %s", channelName))
            end
        end
    }
    
    NotificationState.pushSystem:initialize()
    print("📱 Push notifications initialized")
end

function AccessibilityNotificationSystem.deliverPushNotification(notification)
    -- Simulate push notification delivery
    print(string.format("📱 Push Notification: %s - %s", notification.title, notification.message))
    
    notification.delivered = true
    table.insert(NotificationState.history.received, notification)
end

function AccessibilityNotificationSystem.isQuietHours()
    local quietHours = NOTIFICATION_CONFIG.pushNotifications.scheduling.quietHours
    if not quietHours.enabled then return false end
    
    local currentHour = tonumber(os.date("%H"))
    
    if quietHours.start < quietHours.end then
        return currentHour >= quietHours.start and currentHour < quietHours.end
    else
        return currentHour >= quietHours.start or currentHour < quietHours.end
    end
end

-- ========================================
-- IN-APP NOTIFICATIONS
-- ========================================

function AccessibilityNotificationSystem.initializeInAppNotifications()
    NotificationState.inAppSystem = {
        queue = {},
        visible = {},
        container = nil,
        
        initialize = function(self)
            self:createContainer()
            
            -- Start notification processing
            spawn(function()
                while true do
                    self:processQueue()
                    task.wait(0.1)
                end
            end)
            
            print("📲 In-app notifications initialized")
        end,
        
        createContainer = function(self)
            local player = Players.LocalPlayer
            local playerGui = player:WaitForChild("PlayerGui")
            
            local container = Instance.new("Frame")
            container.Name = "NotificationContainer"
            container.Size = UDim2.new(1, 0, 1, 0)
            container.Position = UDim2.new(0, 0, 0, 0)
            container.BackgroundTransparency = 1
            container.Parent = playerGui
            
            self.container = container
        end,
        
        showNotification = function(self, type, title, message, duration)
            local notification = {
                id = HttpService:GenerateGUID(false),
                type = type,
                title = title,
                message = message,
                duration = duration or NOTIFICATION_CONFIG.inAppNotifications.duration,
                timestamp = tick()
            }
            
            table.insert(self.queue, notification)
        end,
        
        processQueue = function(self)
            if #self.queue == 0 then return end
            if #self.visible >= NOTIFICATION_CONFIG.inAppNotifications.maxVisible then return end
            
            local notification = table.remove(self.queue, 1)
            self:displayNotification(notification)
        end,
        
        displayNotification = function(self, notification)
            local notificationFrame = self:createNotificationFrame(notification)
            table.insert(self.visible, {frame = notificationFrame, notification = notification})
            
            -- Auto-dismiss after duration
            spawn(function()
                task.wait(notification.duration)
                self:dismissNotification(notification.id)
            end)
        end,
        
        createNotificationFrame = function(self, notification)
            local typeConfig = NOTIFICATION_CONFIG.inAppNotifications.types[notification.type]
            
            local frame = Instance.new("Frame")
            frame.Name = "Notification_" .. notification.id
            frame.Size = UDim2.new(0, 300, 0, 80)
            frame.Position = UDim2.new(1, 320, 0, 20 + (#self.visible * 90))
            frame.BackgroundColor3 = typeConfig.color
            frame.BorderSizePixel = 0
            frame.Parent = self.container
            
            -- Round corners
            local corner = Instance.new("UICorner")
            corner.CornerRadius = UDim.new(0, 8)
            corner.Parent = frame
            
            -- Icon
            local icon = Instance.new("TextLabel")
            icon.Size = UDim2.new(0, 30, 0, 30)
            icon.Position = UDim2.new(0, 10, 0, 10)
            icon.BackgroundTransparency = 1
            icon.Text = typeConfig.icon
            icon.TextSize = 20
            icon.TextColor3 = Color3.new(1, 1, 1)
            icon.Parent = frame
            
            -- Title
            local titleLabel = Instance.new("TextLabel")
            titleLabel.Size = UDim2.new(1, -50, 0, 25)
            titleLabel.Position = UDim2.new(0, 45, 0, 5)
            titleLabel.BackgroundTransparency = 1
            titleLabel.Text = notification.title
            titleLabel.TextSize = 14
            titleLabel.TextColor3 = Color3.new(1, 1, 1)
            titleLabel.Font = Enum.Font.SourceSansBold
            titleLabel.TextXAlignment = Enum.TextXAlignment.Left
            titleLabel.Parent = frame
            
            -- Message
            local messageLabel = Instance.new("TextLabel")
            messageLabel.Size = UDim2.new(1, -50, 0, 45)
            messageLabel.Position = UDim2.new(0, 45, 0, 30)
            messageLabel.BackgroundTransparency = 1
            messageLabel.Text = notification.message
            messageLabel.TextSize = 12
            messageLabel.TextColor3 = Color3.new(0.9, 0.9, 0.9)
            messageLabel.Font = Enum.Font.SourceSans
            messageLabel.TextXAlignment = Enum.TextXAlignment.Left
            messageLabel.TextYAlignment = Enum.TextYAlignment.Top
            messageLabel.TextWrapped = true
            messageLabel.Parent = frame
            
            -- Animate in
            local tweenIn = TweenService:Create(frame,
                TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
                {Position = UDim2.new(1, -320, 0, 20 + (#self.visible * 90))}
            )
            tweenIn:Play()
            
            return frame
        end,
        
        dismissNotification = function(self, notificationId)
            for i, visibleNotification in ipairs(self.visible) do
                if visibleNotification.notification.id == notificationId then
                    -- Animate out
                    local tweenOut = TweenService:Create(visibleNotification.frame,
                        TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
                        {Position = UDim2.new(1, 20, 0, visibleNotification.frame.Position.Y.Offset)}
                    )
                    tweenOut:Play()
                    
                    tweenOut.Completed:Connect(function()
                        visibleNotification.frame:Destroy()
                        table.remove(self.visible, i)
                        
                        -- Reposition remaining notifications
                        self:repositionNotifications()
                    end)
                    
                    break
                end
            end
        end,
        
        repositionNotifications = function(self)
            for i, visibleNotification in ipairs(self.visible) do
                local newPosition = UDim2.new(1, -320, 0, 20 + ((i-1) * 90))
                local tween = TweenService:Create(visibleNotification.frame,
                    TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
                    {Position = newPosition}
                )
                tween:Play()
            end
        end
    }
    
    NotificationState.inAppSystem:initialize()
end

-- ========================================
-- BACKGROUND PROCESSING
-- ========================================

function AccessibilityNotificationSystem.initializeBackgroundProcessing()
    NotificationState.backgroundSystem = {
        tasks = {},
        running = {},
        scheduler = nil,
        
        initialize = function(self)
            -- Set up background tasks
            for taskName, config in pairs(NOTIFICATION_CONFIG.backgroundProcessing.tasks) do
                self.tasks[taskName] = {
                    name = taskName,
                    config = config,
                    lastRun = 0,
                    running = false
                }
            end
            
            -- Start background scheduler
            self:startScheduler()
            
            print("⚙️ Background processing initialized")
        end,
        
        startScheduler = function(self)
            self.scheduler = spawn(function()
                while true do
                    self:checkTasks()
                    
                    -- Adaptive scheduling: longer waits when no active tasks
                    local activeTasks = 0
                    for _, task in pairs(self.tasks) do
                        if task.running then
                            activeTasks = activeTasks + 1
                        end
                    end
                    
                    local waitTime = activeTasks > 0 and 10 or 60 -- More frequent when tasks are active
                    task.wait(waitTime)
                end
            end)
        end,
        
        checkTasks = function(self)
            local currentTime = tick()
            
            for taskName, task in pairs(self.tasks) do
                if not task.running and (currentTime - task.lastRun) >= task.config.interval then
                    self:runTask(taskName)
                end
            end
        end,
        
        runTask = function(self, taskName)
            local task = self.tasks[taskName]
            if not task then return end
            
            task.running = true
            task.lastRun = tick()
            
            print(string.format("⚙️ Running background task: %s", taskName))
            
            spawn(function()
                -- Simulate task execution
                if taskName == "dataSync" then
                    AccessibilityNotificationSystem.performDataSync()
                elseif taskName == "analytics" then
                    AccessibilityNotificationSystem.performAnalytics()
                elseif taskName == "maintenance" then
                    AccessibilityNotificationSystem.performMaintenance()
                end
                
                task.running = false
                print(string.format("⚙️ Completed background task: %s", taskName))
            end)
        end
    }
    
    NotificationState.backgroundSystem:initialize()
end

function AccessibilityNotificationSystem.performDataSync()
    -- Sync accessibility settings and notification preferences
    task.wait(2) -- Simulate sync time
    print("📊 Data sync completed")
end

function AccessibilityNotificationSystem.performAnalytics()
    -- Send accessibility usage analytics
    task.wait(1) -- Simulate analytics time
    print("📈 Analytics sent")
end

function AccessibilityNotificationSystem.performMaintenance()
    -- Clean up old notifications and data
    task.wait(3) -- Simulate maintenance time
    print("🧹 Maintenance completed")
end

-- ========================================
-- PUBLIC API
-- ========================================

function AccessibilityNotificationSystem.enableAccessibilityFeature(featureName)
    AccessibilityState.accessibilityManager:enableFeature(featureName)
end

function AccessibilityNotificationSystem.disableAccessibilityFeature(featureName)
    AccessibilityState.accessibilityManager:disableFeature(featureName)
end

function AccessibilityNotificationSystem.toggleAccessibilityFeature(featureName)
    AccessibilityState.accessibilityManager:toggleFeature(featureName)
end

function AccessibilityNotificationSystem.applyAccessibilityProfile(profileName)
    AccessibilityState.accessibilityManager:applyProfile(profileName)
end

function AccessibilityNotificationSystem.sendPushNotification(channel, title, message, data)
    NotificationState.pushSystem:sendNotification(channel, title, message, data)
end

function AccessibilityNotificationSystem.showInAppNotification(type, title, message, duration)
    NotificationState.inAppSystem:showNotification(type, title, message, duration)
end

function AccessibilityNotificationSystem.subscribeToChannel(channelName)
    NotificationState.pushSystem:subscribeToChannel(channelName)
end

function AccessibilityNotificationSystem.unsubscribeFromChannel(channelName)
    NotificationState.pushSystem:unsubscribeFromChannel(channelName)
end

function AccessibilityNotificationSystem.getAccessibilitySettings()
    return AccessibilityState.currentSettings
end

function AccessibilityNotificationSystem.getNotificationHistory()
    return NotificationState.history
end

function AccessibilityNotificationSystem.runAccessibilityDemo()
    print("♿ Running accessibility and notification demonstration...")
    
    -- Show current accessibility settings
    print("  ♿ Current Accessibility Settings:")
    for feature, enabled in pairs(AccessibilityState.currentSettings) do
        print(string.format("    %s: %s", feature, enabled and "✅" or "❌"))
    end
    
    -- Demonstrate voice control
    print("  🎤 Testing voice control...")
    AccessibilityNotificationSystem.enableAccessibilityFeature("voiceControl")
    task.wait(1)
    
    -- Demonstrate assistive touch
    print("  👆 Testing assistive touch...")
    AccessibilityNotificationSystem.enableAccessibilityFeature("assistiveTouch")
    task.wait(1)
    
    -- Demonstrate screen reader
    print("  🗣️ Testing screen reader...")
    AccessibilityNotificationSystem.enableAccessibilityFeature("screenReader")
    task.wait(1)
    
    -- Demonstrate visual accessibility
    print("  👁️ Testing visual accessibility...")
    AccessibilityNotificationSystem.enableAccessibilityFeature("highContrast")
    AccessibilityNotificationSystem.enableAccessibilityFeature("largeText")
    task.wait(1)
    
    -- Demonstrate notifications
    print("  📱 Testing notifications...")
    
    -- In-app notifications
    AccessibilityNotificationSystem.showInAppNotification("info", "Welcome!", "Accessibility features are now active.")
    task.wait(2)
    
    AccessibilityNotificationSystem.showInAppNotification("success", "Voice Control", "Voice commands are ready to use.")
    task.wait(2)
    
    AccessibilityNotificationSystem.showInAppNotification("warning", "Battery Low", "Enable power saving mode for longer usage.")
    task.wait(2)
    
    -- Push notifications
    AccessibilityNotificationSystem.sendPushNotification("general", "Daily Reminder", "Don't forget to complete your daily activities!")
    AccessibilityNotificationSystem.sendPushNotification("achievements", "New Achievement!", "You've unlocked the accessibility advocate badge.")
    
    -- Show notification channels
    print("  📲 Notification Channels:")
    for channelName, channel in pairs(NotificationState.pushSystem.channels) do
        print(string.format("    %s: %s (Priority: %s)", 
            channelName, 
            channel.subscribed and "✅" or "❌", 
            channel.settings.priority))
    end
    
    -- Show background tasks
    print("  ⚙️ Background Tasks:")
    for taskName, task in pairs(NotificationState.backgroundSystem.tasks) do
        print(string.format("    %s: %s (Interval: %ds)", 
            taskName, 
            task.running and "🏃" or "⏸️", 
            task.config.interval))
    end
    
    -- Apply accessibility profile
    print("  👥 Applying accessibility profile...")
    AccessibilityNotificationSystem.applyAccessibilityProfile("visual_impairment")
    
    print("♿ Accessibility and notification demonstration completed")
    print("     All accessibility features and notifications are fully functional!")
end

-- Initialize the accessibility and notification system
AccessibilityNotificationSystem.initialize()

print("♿ AccessibilityNotificationSystem loaded with comprehensive mobile accessibility")

return AccessibilityNotificationSystem
