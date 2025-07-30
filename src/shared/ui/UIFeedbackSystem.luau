-- UIFeedbackSystem.luau
-- Comprehensive loading states and user feedback system
-- Provides notifications, progress indicators, toasts, and state management

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local SoundService = game:GetService("SoundService")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

local SafeRequire = require(ReplicatedStorage.Shared.utils.SafeRequire)
local UIDesignTokens = SafeRequire.require(ReplicatedStorage.Shared.ui.UIDesignTokens)
local UIAnimationSystem = SafeRequire.require(ReplicatedStorage.Shared.ui.UIAnimationSystem)

local UIFeedbackSystem = {}

-- ========================================
-- FEEDBACK CONFIGURATION
-- ========================================

local FEEDBACK_CONFIG = {
    -- Toast Notifications
    toasts = {
        maxVisible = 5,
        autoHideDuration = 4000, -- 4 seconds
        animationDuration = 300,
        spacing = 10,
        width = 350,
        minHeight = 60
    },
    
    -- Progress Indicators
    progress = {
        barHeight = 4,
        animationDuration = 200,
        smoothing = 0.1,
        pulseInterval = 1000
    },
    
    -- Loading Overlays
    overlays = {
        fadeDuration = 200,
        spinnerSize = 32,
        backdropOpacity = 0.8
    },
    
    -- Notifications
    notifications = {
        maxQueue = 10,
        persistentDuration = 0, -- 0 = manual dismiss
        temporaryDuration = 6000,
        stackLimit = 3
    },
    
    -- User Feedback
    feedback = {
        hapticIntensity = 0.5,
        soundVolume = 0.3,
        visualFeedbackDuration = 150
    }
}

local FEEDBACK_TYPES = {
    SUCCESS = "success",
    ERROR = "error",
    WARNING = "warning",
    INFO = "info",
    LOADING = "loading"
}

local NOTIFICATION_ACTIONS = {
    DISMISS = "dismiss",
    RETRY = "retry",
    CONFIRM = "confirm",
    CANCEL = "cancel",
    DETAILS = "details"
}

-- ========================================
-- FEEDBACK MANAGER
-- ========================================

local FeedbackManager = {
    -- Toast system
    toastContainer = nil,
    activeToasts = {},
    toastQueue = {},
    
    -- Progress tracking
    progressBars = {},
    loadingOverlays = {},
    
    -- Notification system
    notificationContainer = nil,
    activeNotifications = {},
    notificationQueue = {},
    
    -- State management
    loadingStates = {},
    globalLoadingCount = 0,
    
    -- Sound and haptic feedback
    soundEnabled = true,
    hapticEnabled = true,
    
    -- Animation handles
    animationConnections = {}
}

function UIFeedbackSystem.initialize()
    -- Create UI containers
    UIFeedbackSystem.createFeedbackContainers()
    
    -- Set up global loading indicator
    UIFeedbackSystem.setupGlobalLoadingIndicator()
    
    -- Initialize sound system
    UIFeedbackSystem.initializeSoundSystem()
    
    print("💬 UIFeedbackSystem initialized with comprehensive user feedback")
end

-- ========================================
-- TOAST NOTIFICATIONS
-- ========================================

function UIFeedbackSystem.createFeedbackContainers()
    local playerGui = game.Players.LocalPlayer:WaitForChild("PlayerGui")
    
    -- Create feedback GUI
    local feedbackGui = Instance.new("ScreenGui")
    feedbackGui.Name = "UIFeedbackSystem"
    feedbackGui.DisplayOrder = 100
    feedbackGui.ResetOnSpawn = false
    feedbackGui.Parent = playerGui
    
    -- Toast container
    local toastContainer = Instance.new("Frame")
    toastContainer.Name = "ToastContainer"
    toastContainer.Size = UDim2.new(0, FEEDBACK_CONFIG.toasts.width, 1, 0)
    toastContainer.Position = UDim2.new(1, -FEEDBACK_CONFIG.toasts.width - 20, 0, 20)
    toastContainer.BackgroundTransparency = 1
    toastContainer.Parent = feedbackGui
    
    local toastLayout = Instance.new("UIListLayout")
    toastLayout.SortOrder = Enum.SortOrder.LayoutOrder
    toastLayout.Padding = UDim.new(0, FEEDBACK_CONFIG.toasts.spacing)
    toastLayout.VerticalAlignment = Enum.VerticalAlignment.Top
    toastLayout.Parent = toastContainer
    
    -- Notification container
    local notificationContainer = Instance.new("Frame")
    notificationContainer.Name = "NotificationContainer"
    notificationContainer.Size = UDim2.new(0, 400, 1, -100)
    notificationContainer.Position = UDim2.new(0, 20, 0, 20)
    notificationContainer.BackgroundTransparency = 1
    notificationContainer.Parent = feedbackGui
    
    local notificationLayout = Instance.new("UIListLayout")
    notificationLayout.SortOrder = Enum.SortOrder.LayoutOrder
    notificationLayout.Padding = UDim.new(0, 10)
    notificationLayout.VerticalAlignment = Enum.VerticalAlignment.Top
    notificationLayout.Parent = notificationContainer
    
    FeedbackManager.toastContainer = toastContainer
    FeedbackManager.notificationContainer = notificationContainer
end

function UIFeedbackSystem.showToast(config)
    config = config or {}
    
    local toastConfig = {
        message = config.message or "Toast message",
        type = config.type or FEEDBACK_TYPES.INFO,
        duration = config.duration or FEEDBACK_CONFIG.toasts.autoHideDuration,
        actions = config.actions or {},
        icon = config.icon,
        persistent = config.persistent or false,
        id = config.id or UIFeedbackSystem.generateId()
    }
    
    -- Check if too many toasts are visible
    if #FeedbackManager.activeToasts >= FEEDBACK_CONFIG.toasts.maxVisible then
        table.insert(FeedbackManager.toastQueue, toastConfig)
        return toastConfig.id
    end
    
    local toast = UIFeedbackSystem.createToastElement(toastConfig)
    
    -- Add to active toasts
    table.insert(FeedbackManager.activeToasts, {
        id = toastConfig.id,
        element = toast,
        config = toastConfig,
        startTime = tick()
    })
    
    -- Animate in
    UIFeedbackSystem.animateToastIn(toast)
    
    -- Auto-hide if not persistent
    if not toastConfig.persistent and toastConfig.duration > 0 then
        task.delay(toastConfig.duration / 1000, function()
            UIFeedbackSystem.hideToast(toastConfig.id)
        end)
    end
    
    -- Play sound
    UIFeedbackSystem.playFeedbackSound(toastConfig.type)
    
    return toastConfig.id
end

function UIFeedbackSystem.createToastElement(config)
    local tokens = UIDesignTokens.getTokens()
    
    -- Main toast frame
    local toast = Instance.new("Frame")
    toast.Name = "Toast_" .. config.id
    toast.Size = UDim2.new(1, 0, 0, FEEDBACK_CONFIG.toasts.minHeight)
    toast.BackgroundColor3 = UIFeedbackSystem.getTypeColor(config.type, "background")
    toast.BorderSizePixel = 0
    toast.LayoutOrder = tick()
    toast.Parent = FeedbackManager.toastContainer
    
    -- Corner radius
    local corner = Instance.new("UICorner")
    corner.CornerRadius = tokens.borderRadius.medium
    corner.Parent = toast
    
    -- Drop shadow
    local shadow = Instance.new("Frame")
    shadow.Name = "Shadow"
    shadow.Size = UDim2.new(1, 4, 1, 4)
    shadow.Position = UDim2.new(0, -2, 0, 2)
    shadow.BackgroundColor3 = Color3.new(0, 0, 0)
    shadow.BackgroundTransparency = 0.8
    shadow.BorderSizePixel = 0
    shadow.ZIndex = toast.ZIndex - 1
    shadow.Parent = toast
    
    local shadowCorner = Instance.new("UICorner")
    shadowCorner.CornerRadius = tokens.borderRadius.medium
    shadowCorner.Parent = shadow
    
    -- Content container
    local content = Instance.new("Frame")
    content.Name = "Content"
    content.Size = UDim2.new(1, -20, 1, -10)
    content.Position = UDim2.new(0, 10, 0, 5)
    content.BackgroundTransparency = 1
    content.Parent = toast
    
    -- Icon (if provided)
    local iconSize = 20
    local textStartX = 0
    
    if config.icon then
        local icon = Instance.new("ImageLabel")
        icon.Name = "Icon"
        icon.Size = UDim2.new(0, iconSize, 0, iconSize)
        icon.Position = UDim2.new(0, 0, 0.5, -iconSize/2)
        icon.BackgroundTransparency = 1
        icon.Image = config.icon
        icon.ImageColor3 = UIFeedbackSystem.getTypeColor(config.type, "text")
        icon.Parent = content
        
        textStartX = iconSize + 10
    end
    
    -- Message text
    local message = Instance.new("TextLabel")
    message.Name = "Message"
    message.Size = UDim2.new(1, -textStartX - (config.actions and #config.actions > 0 and 80 or 20), 1, 0)
    message.Position = UDim2.new(0, textStartX, 0, 0)
    message.BackgroundTransparency = 1
    message.Text = config.message
    message.TextColor3 = UIFeedbackSystem.getTypeColor(config.type, "text")
    message.TextSize = tokens.typography.size.sm
    message.Font = tokens.typography.font.primary
    message.TextWrapped = true
    message.TextXAlignment = Enum.TextXAlignment.Left
    message.TextYAlignment = Enum.TextYAlignment.Center
    message.Parent = content
    
    -- Action buttons
    if config.actions and #config.actions > 0 then
        local actionsContainer = Instance.new("Frame")
        actionsContainer.Name = "Actions"
        actionsContainer.Size = UDim2.new(0, 70, 1, 0)
        actionsContainer.Position = UDim2.new(1, -70, 0, 0)
        actionsContainer.BackgroundTransparency = 1
        actionsContainer.Parent = content
        
        for i, action in ipairs(config.actions) do
            local button = Instance.new("TextButton")
            button.Name = "Action_" .. action.type
            button.Size = UDim2.new(1, 0, 0, 24)
            button.Position = UDim2.new(0, 0, 0, (i-1) * 26)
            button.BackgroundColor3 = UIFeedbackSystem.getTypeColor(config.type, "accent")
            button.BorderSizePixel = 0
            button.Text = action.text or action.type
            button.TextColor3 = tokens.colors.text.onPrimary
            button.TextSize = tokens.typography.size.xs
            button.Font = tokens.typography.font.primary
            button.Parent = actionsContainer
            
            local buttonCorner = Instance.new("UICorner")
            buttonCorner.CornerRadius = tokens.borderRadius.small
            buttonCorner.Parent = button
            
            button.MouseButton1Click:Connect(function()
                if action.callback then
                    pcall(action.callback)
                end
                UIFeedbackSystem.hideToast(config.id)
            end)
        end
    end
    
    -- Close button (if not persistent)
    if not config.persistent then
        local closeButton = Instance.new("TextButton")
        closeButton.Name = "CloseButton"
        closeButton.Size = UDim2.new(0, 20, 0, 20)
        closeButton.Position = UDim2.new(1, -25, 0, 5)
        closeButton.BackgroundTransparency = 1
        closeButton.Text = "×"
        closeButton.TextColor3 = UIFeedbackSystem.getTypeColor(config.type, "text")
        closeButton.TextSize = 18
        closeButton.Font = Enum.Font.SourceSansBold
        closeButton.Parent = toast
        
        closeButton.MouseButton1Click:Connect(function()
            UIFeedbackSystem.hideToast(config.id)
        end)
    end
    
    -- Auto-resize based on content
    UIFeedbackSystem.autoResizeToast(toast, message)
    
    return toast
end

function UIFeedbackSystem.autoResizeToast(toast, messageLabel)
    -- Calculate required height
    local textBounds = game:GetService("TextService"):GetTextSize(
        messageLabel.Text,
        messageLabel.TextSize,
        messageLabel.Font,
        Vector2.new(messageLabel.AbsoluteSize.X, math.huge)
    )
    
    local requiredHeight = math.max(FEEDBACK_CONFIG.toasts.minHeight, textBounds.Y + 20)
    toast.Size = UDim2.new(1, 0, 0, requiredHeight)
end

function UIFeedbackSystem.animateToastIn(toast)
    -- Start from right side
    toast.Position = UDim2.new(1, 50, 0, 0)
    toast.BackgroundTransparency = 1
    
    -- Animate to position
    local positionTween = TweenService:Create(
        toast,
        TweenInfo.new(FEEDBACK_CONFIG.toasts.animationDuration / 1000, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
        {Position = UDim2.new(0, 0, 0, 0)}
    )
    
    local fadeTween = TweenService:Create(
        toast,
        TweenInfo.new(FEEDBACK_CONFIG.toasts.animationDuration / 1000, Enum.EasingStyle.Quad),
        {BackgroundTransparency = 0}
    )
    
    positionTween:Play()
    fadeTween:Play()
end

function UIFeedbackSystem.hideToast(toastId)
    local toastIndex = nil
    local toastData = nil
    
    -- Find toast
    for i, toast in ipairs(FeedbackManager.activeToasts) do
        if toast.id == toastId then
            toastIndex = i
            toastData = toast
            break
        end
    end
    
    if not toastData then return end
    
    -- Animate out
    local toast = toastData.element
    
    local positionTween = TweenService:Create(
        toast,
        TweenInfo.new(FEEDBACK_CONFIG.toasts.animationDuration / 1000, Enum.EasingStyle.Back, Enum.EasingDirection.In),
        {Position = UDim2.new(1, 50, 0, 0)}
    )
    
    local fadeTween = TweenService:Create(
        toast,
        TweenInfo.new(FEEDBACK_CONFIG.toasts.animationDuration / 1000, Enum.EasingStyle.Quad),
        {BackgroundTransparency = 1}
    )
    
    positionTween:Play()
    fadeTween:Play()
    
    positionTween.Completed:Connect(function()
        toast:Destroy()
        table.remove(FeedbackManager.activeToasts, toastIndex)
        
        -- Show queued toast if any
        if #FeedbackManager.toastQueue > 0 then
            local queuedToast = table.remove(FeedbackManager.toastQueue, 1)
            UIFeedbackSystem.showToast(queuedToast)
        end
    end)
end

-- ========================================
-- PROGRESS INDICATORS
-- ========================================

function UIFeedbackSystem.createProgressBar(config)
    config = config or {}
    
    local progressConfig = {
        id = config.id or UIFeedbackSystem.generateId(),
        parent = config.parent,
        size = config.size or UDim2.new(1, 0, 0, FEEDBACK_CONFIG.progress.barHeight),
        position = config.position or UDim2.new(0, 0, 0, 0),
        showPercentage = config.showPercentage or false,
        animated = config.animated ~= false,
        color = config.color or UIDesignTokens.getTokens().colors.primary.main,
        backgroundColor = config.backgroundColor or UIDesignTokens.getTokens().colors.surface.secondary
    }
    
    if not progressConfig.parent then
        warn("Progress bar requires a parent container")
        return nil
    end
    
    -- Main container
    local container = Instance.new("Frame")
    container.Name = "ProgressBar_" .. progressConfig.id
    container.Size = progressConfig.size
    container.Position = progressConfig.position
    container.BackgroundColor3 = progressConfig.backgroundColor
    container.BorderSizePixel = 0
    container.Parent = progressConfig.parent
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, FEEDBACK_CONFIG.progress.barHeight / 2)
    corner.Parent = container
    
    -- Progress fill
    local fill = Instance.new("Frame")
    fill.Name = "Fill"
    fill.Size = UDim2.new(0, 0, 1, 0)
    fill.Position = UDim2.new(0, 0, 0, 0)
    fill.BackgroundColor3 = progressConfig.color
    fill.BorderSizePixel = 0
    fill.Parent = container
    
    local fillCorner = Instance.new("UICorner")
    fillCorner.CornerRadius = UDim.new(0, FEEDBACK_CONFIG.progress.barHeight / 2)
    fillCorner.Parent = fill
    
    -- Percentage label (if enabled)
    local percentageLabel = nil
    if progressConfig.showPercentage then
        percentageLabel = Instance.new("TextLabel")
        percentageLabel.Name = "Percentage"
        percentageLabel.Size = UDim2.new(1, 0, 1, 20)
        percentageLabel.Position = UDim2.new(0, 0, 1, 5)
        percentageLabel.BackgroundTransparency = 1
        percentageLabel.Text = "0%"
        percentageLabel.TextColor3 = UIDesignTokens.getTokens().colors.text.primary
        percentageLabel.TextSize = UIDesignTokens.getTokens().typography.size.sm
        percentageLabel.Font = UIDesignTokens.getTokens().typography.font.primary
        percentageLabel.TextXAlignment = Enum.TextXAlignment.Center
        percentageLabel.Parent = container
    end
    
    -- Progress bar object
    local progressBar = {
        id = progressConfig.id,
        container = container,
        fill = fill,
        percentageLabel = percentageLabel,
        config = progressConfig,
        currentProgress = 0,
        targetProgress = 0,
        animationConnection = nil
    }
    
    FeedbackManager.progressBars[progressConfig.id] = progressBar
    
    return {
        setProgress = function(progress, animated)
            UIFeedbackSystem.setProgressBarProgress(progressConfig.id, progress, animated)
        end,
        getProgress = function()
            return progressBar.currentProgress
        end,
        setColor = function(color)
            fill.BackgroundColor3 = color
        end,
        destroy = function()
            UIFeedbackSystem.destroyProgressBar(progressConfig.id)
        end
    }
end

function UIFeedbackSystem.setProgressBarProgress(progressId, progress, animated)
    local progressBar = FeedbackManager.progressBars[progressId]
    if not progressBar then return end
    
    progress = math.clamp(progress, 0, 1)
    progressBar.targetProgress = progress
    
    if animated == false or not progressBar.config.animated then
        -- Immediate update
        progressBar.currentProgress = progress
        progressBar.fill.Size = UDim2.new(progress, 0, 1, 0)
        
        if progressBar.percentageLabel then
            progressBar.percentageLabel.Text = math.floor(progress * 100) .. "%"
        end
    else
        -- Smooth animation
        if progressBar.animationConnection then
            progressBar.animationConnection:Disconnect()
        end
        
        progressBar.animationConnection = RunService.Heartbeat:Connect(function(deltaTime)
            local difference = progressBar.targetProgress - progressBar.currentProgress
            if math.abs(difference) < 0.001 then
                progressBar.currentProgress = progressBar.targetProgress
                progressBar.animationConnection:Disconnect()
                progressBar.animationConnection = nil
            else
                progressBar.currentProgress = progressBar.currentProgress + difference * FEEDBACK_CONFIG.progress.smoothing
            end
            
            progressBar.fill.Size = UDim2.new(progressBar.currentProgress, 0, 1, 0)
            
            if progressBar.percentageLabel then
                progressBar.percentageLabel.Text = math.floor(progressBar.currentProgress * 100) .. "%"
            end
        end)
    end
end

function UIFeedbackSystem.destroyProgressBar(progressId)
    local progressBar = FeedbackManager.progressBars[progressId]
    if not progressBar then return end
    
    if progressBar.animationConnection then
        progressBar.animationConnection:Disconnect()
    end
    
    progressBar.container:Destroy()
    FeedbackManager.progressBars[progressId] = nil
end

-- ========================================
-- LOADING OVERLAYS
-- ========================================

function UIFeedbackSystem.showLoadingOverlay(config)
    config = config or {}
    
    local overlayConfig = {
        id = config.id or UIFeedbackSystem.generateId(),
        parent = config.parent or game.Players.LocalPlayer.PlayerGui,
        message = config.message or "Loading...",
        blocking = config.blocking ~= false,
        showSpinner = config.showSpinner ~= false,
        showProgress = config.showProgress or false,
        progressValue = config.progressValue or 0
    }
    
    -- Create overlay
    local overlay = Instance.new("Frame")
    overlay.Name = "LoadingOverlay_" .. overlayConfig.id
    overlay.Size = UDim2.new(1, 0, 1, 0)
    overlay.Position = UDim2.new(0, 0, 0, 0)
    overlay.BackgroundColor3 = Color3.new(0, 0, 0)
    overlay.BackgroundTransparency = FEEDBACK_CONFIG.overlays.backdropOpacity
    overlay.BorderSizePixel = 0
    overlay.ZIndex = 1000
    overlay.Parent = overlayConfig.parent
    
    -- Content container
    local content = Instance.new("Frame")
    content.Name = "Content"
    content.Size = UDim2.new(0, 200, 0, 100)
    content.Position = UDim2.new(0.5, -100, 0.5, -50)
    content.BackgroundTransparency = 1
    content.Parent = overlay
    
    -- Spinner
    local spinner = nil
    if overlayConfig.showSpinner then
        spinner = UIFeedbackSystem.createSpinner()
        spinner.Size = UDim2.new(0, FEEDBACK_CONFIG.overlays.spinnerSize, 0, FEEDBACK_CONFIG.overlays.spinnerSize)
        spinner.Position = UDim2.new(0.5, -FEEDBACK_CONFIG.overlays.spinnerSize/2, 0, 0)
        spinner.Parent = content
    end
    
    -- Message
    local message = Instance.new("TextLabel")
    message.Name = "Message"
    message.Size = UDim2.new(1, 0, 0, 30)
    message.Position = UDim2.new(0, 0, 0, overlayConfig.showSpinner and 45 or 20)
    message.BackgroundTransparency = 1
    message.Text = overlayConfig.message
    message.TextColor3 = Color3.new(1, 1, 1)
    message.TextSize = UIDesignTokens.getTokens().typography.size.md
    message.Font = UIDesignTokens.getTokens().typography.font.primary
    message.TextXAlignment = Enum.TextXAlignment.Center
    message.Parent = content
    
    -- Progress bar (if enabled)
    local progressBar = nil
    if overlayConfig.showProgress then
        progressBar = UIFeedbackSystem.createProgressBar({
            parent = content,
            size = UDim2.new(1, 0, 0, 4),
            position = UDim2.new(0, 0, 1, -10),
            showPercentage = true
        })
        
        progressBar.setProgress(overlayConfig.progressValue / 100)
    end
    
    -- Animate in
    overlay.BackgroundTransparency = 1
    local fadeIn = TweenService:Create(
        overlay,
        TweenInfo.new(FEEDBACK_CONFIG.overlays.fadeDuration / 1000),
        {BackgroundTransparency = 1 - FEEDBACK_CONFIG.overlays.backdropOpacity}
    )
    fadeIn:Play()
    
    -- Store overlay
    FeedbackManager.loadingOverlays[overlayConfig.id] = {
        overlay = overlay,
        spinner = spinner,
        progressBar = progressBar,
        message = message,
        config = overlayConfig
    }
    
    return {
        updateMessage = function(newMessage)
            message.Text = newMessage
        end,
        updateProgress = function(progress)
            if progressBar then
                progressBar.setProgress(progress / 100)
            end
        end,
        hide = function()
            UIFeedbackSystem.hideLoadingOverlay(overlayConfig.id)
        end
    }
end

function UIFeedbackSystem.hideLoadingOverlay(overlayId)
    local overlayData = FeedbackManager.loadingOverlays[overlayId]
    if not overlayData then return end
    
    local overlay = overlayData.overlay
    
    -- Animate out
    local fadeOut = TweenService:Create(
        overlay,
        TweenInfo.new(FEEDBACK_CONFIG.overlays.fadeDuration / 1000),
        {BackgroundTransparency = 1}
    )
    fadeOut:Play()
    
    fadeOut.Completed:Connect(function()
        if overlayData.progressBar then
            overlayData.progressBar.destroy()
        end
        
        if overlayData.spinner then
            UIFeedbackSystem.stopSpinner(overlayData.spinner)
        end
        
        overlay:Destroy()
        FeedbackManager.loadingOverlays[overlayId] = nil
    end)
end

-- ========================================
-- LOADING STATES
-- ========================================

function UIFeedbackSystem.setLoadingState(elementOrId, loading, message)
    local element = elementOrId
    local stateId = tostring(elementOrId)
    
    if type(elementOrId) == "string" then
        stateId = elementOrId
        element = UIFeedbackSystem.findElementById(elementOrId)
    end
    
    if loading then
        -- Start loading state
        FeedbackManager.loadingStates[stateId] = {
            element = element,
            originalText = element and element:IsA("TextButton") and element.Text or nil,
            originalEnabled = element and (element:IsA("GuiButton") and element.Active) or true,
            message = message or "Loading...",
            startTime = tick()
        }
        
        -- Update element appearance
        if element then
            if element:IsA("TextButton") then
                element.Text = message or "Loading..."
                element.Active = false
            elseif element:IsA("GuiButton") then
                element.Active = false
            end
            
            -- Add loading spinner to element
            UIFeedbackSystem.addLoadingSpinnerToElement(element)
        end
        
        -- Increment global loading counter
        FeedbackManager.globalLoadingCount = FeedbackManager.globalLoadingCount + 1
        UIFeedbackSystem.updateGlobalLoadingIndicator()
        
    else
        -- End loading state
        local loadingState = FeedbackManager.loadingStates[stateId]
        if not loadingState then return end
        
        -- Restore element appearance
        if element then
            if element:IsA("TextButton") and loadingState.originalText then
                element.Text = loadingState.originalText
                element.Active = loadingState.originalEnabled
            elseif element:IsA("GuiButton") then
                element.Active = loadingState.originalEnabled
            end
            
            -- Remove loading spinner
            UIFeedbackSystem.removeLoadingSpinnerFromElement(element)
        end
        
        FeedbackManager.loadingStates[stateId] = nil
        
        -- Decrement global loading counter
        FeedbackManager.globalLoadingCount = math.max(0, FeedbackManager.globalLoadingCount - 1)
        UIFeedbackSystem.updateGlobalLoadingIndicator()
    end
end

function UIFeedbackSystem.addLoadingSpinnerToElement(element)
    if element:FindFirstChild("LoadingSpinner") then
        return -- Already has spinner
    end
    
    local spinner = UIFeedbackSystem.createSpinner()
    spinner.Name = "LoadingSpinner"
    spinner.Size = UDim2.new(0, 16, 0, 16)
    spinner.Position = UDim2.new(1, -20, 0.5, -8)
    spinner.Parent = element
end

function UIFeedbackSystem.removeLoadingSpinnerFromElement(element)
    local spinner = element:FindFirstChild("LoadingSpinner")
    if spinner then
        UIFeedbackSystem.stopSpinner(spinner)
        spinner:Destroy()
    end
end

-- ========================================
-- SPINNER COMPONENT
-- ========================================

function UIFeedbackSystem.createSpinner()
    local spinner = Instance.new("Frame")
    spinner.Name = "Spinner"
    spinner.BackgroundTransparency = 1
    
    -- Create spinner segments
    local segments = 8
    for i = 1, segments do
        local segment = Instance.new("Frame")
        segment.Name = "Segment" .. i
        segment.Size = UDim2.new(0, 2, 0, 6)
        segment.BackgroundColor3 = Color3.new(1, 1, 1)
        segment.BorderSizePixel = 0
        segment.AnchorPoint = Vector2.new(0.5, 1)
        segment.Parent = spinner
        
        local corner = Instance.new("UICorner")
        corner.CornerRadius = UDim.new(0, 1)
        corner.Parent = segment
        
        -- Position segment around circle
        local angle = (i - 1) * (360 / segments)
        local radians = math.rad(angle)
        local radius = 12
        
        segment.Position = UDim2.new(0.5, math.sin(radians) * radius, 0.5, -math.cos(radians) * radius)
        segment.Rotation = angle
        
        -- Animate opacity
        local opacity = (i - 1) / segments
        segment.BackgroundTransparency = 1 - opacity
    end
    
    -- Start animation
    UIFeedbackSystem.startSpinnerAnimation(spinner)
    
    return spinner
end

function UIFeedbackSystem.startSpinnerAnimation(spinner)
    local startTime = tick()
    
    local connection
    connection = RunService.Heartbeat:Connect(function()
        if not spinner.Parent then
            connection:Disconnect()
            return
        end
        
        local elapsed = tick() - startTime
        local rotation = (elapsed * 360) % 360
        
        for i, segment in pairs(spinner:GetChildren()) do
            if segment:IsA("Frame") and segment.Name:match("Segment") then
                local segmentNumber = tonumber(segment.Name:match("%d+"))
                if segmentNumber then
                    local opacity = ((segmentNumber - 1 + elapsed * 8) % 8) / 8
                    segment.BackgroundTransparency = 1 - opacity
                end
            end
        end
    end)
    
    FeedbackManager.animationConnections[spinner] = connection
end

function UIFeedbackSystem.stopSpinner(spinner)
    local connection = FeedbackManager.animationConnections[spinner]
    if connection then
        connection:Disconnect()
        FeedbackManager.animationConnections[spinner] = nil
    end
end

-- ========================================
-- GLOBAL LOADING INDICATOR
-- ========================================

function UIFeedbackSystem.setupGlobalLoadingIndicator()
    local playerGui = game.Players.LocalPlayer:WaitForChild("PlayerGui")
    
    local loadingGui = Instance.new("ScreenGui")
    loadingGui.Name = "GlobalLoadingIndicator"
    loadingGui.DisplayOrder = 999
    loadingGui.ResetOnSpawn = false
    loadingGui.Parent = playerGui
    
    local loadingBar = Instance.new("Frame")
    loadingBar.Name = "LoadingBar"
    loadingBar.Size = UDim2.new(1, 0, 0, 2)
    loadingBar.Position = UDim2.new(0, 0, 0, 0)
    loadingBar.BackgroundColor3 = UIDesignTokens.getTokens().colors.primary.main
    loadingBar.BorderSizePixel = 0
    loadingBar.Visible = false
    loadingBar.Parent = loadingGui
    
    FeedbackManager.globalLoadingIndicator = loadingBar
end

function UIFeedbackSystem.updateGlobalLoadingIndicator()
    local indicator = FeedbackManager.globalLoadingIndicator
    if not indicator then return end
    
    if FeedbackManager.globalLoadingCount > 0 then
        indicator.Visible = true
        -- Animate loading bar
        UIFeedbackSystem.animateGlobalLoadingBar(indicator)
    else
        indicator.Visible = false
    end
end

function UIFeedbackSystem.animateGlobalLoadingBar(loadingBar)
    local animateWidth = TweenService:Create(
        loadingBar,
        TweenInfo.new(1.5, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut, -1, true),
        {Size = UDim2.new(0.7, 0, 0, 2)}
    )
    
    animateWidth:Play()
    
    -- Stop animation when no longer loading
    local connection
    connection = RunService.Heartbeat:Connect(function()
        if FeedbackManager.globalLoadingCount == 0 then
            animateWidth:Cancel()
            connection:Disconnect()
        end
    end)
end

-- ========================================
-- SOUND AND HAPTIC FEEDBACK
-- ========================================

function UIFeedbackSystem.initializeSoundSystem()
    -- Load user preferences
    pcall(function()
        local player = game.Players.LocalPlayer
        FeedbackManager.soundEnabled = player:GetAttribute("FeedbackSoundsEnabled") ~= false
        FeedbackManager.hapticEnabled = player:GetAttribute("HapticFeedbackEnabled") ~= false
    end)
end

function UIFeedbackSystem.playFeedbackSound(feedbackType)
    if not FeedbackManager.soundEnabled then return end
    
    local soundMap = {
        [FEEDBACK_TYPES.SUCCESS] = "rbxasset://sounds/ui/success.mp3",
        [FEEDBACK_TYPES.ERROR] = "rbxasset://sounds/ui/error.mp3",
        [FEEDBACK_TYPES.WARNING] = "rbxasset://sounds/ui/warn.mp3",
        [FEEDBACK_TYPES.INFO] = "rbxasset://sounds/ui/info.mp3"
    }
    
    local soundId = soundMap[feedbackType]
    if soundId then
        local sound = Instance.new("Sound")
        sound.SoundId = soundId
        sound.Volume = FEEDBACK_CONFIG.feedback.soundVolume
        sound.Parent = SoundService
        sound:Play()
        
        sound.Ended:Connect(function()
            sound:Destroy()
        end)
    end
end

function UIFeedbackSystem.playHapticFeedback(intensity)
    if not FeedbackManager.hapticEnabled or not UserInputService.TouchEnabled then
        return
    end
    
    intensity = intensity or FEEDBACK_CONFIG.feedback.hapticIntensity
    
    pcall(function()
        local hapticService = UserInputService:GetPlatformService()
        if hapticService and hapticService.PerformHapticFeedback then
            hapticService:PerformHapticFeedback(Enum.HapticFeedbackType.ImpactMedium)
        end
    end)
end

-- ========================================
-- UTILITY FUNCTIONS
-- ========================================

function UIFeedbackSystem.getTypeColor(feedbackType, variant)
    local tokens = UIDesignTokens.getTokens()
    
    local colorMap = {
        [FEEDBACK_TYPES.SUCCESS] = {
            background = tokens.colors.semantic.success,
            text = tokens.colors.text.onPrimary,
            accent = tokens.colors.semantic.successDark
        },
        [FEEDBACK_TYPES.ERROR] = {
            background = tokens.colors.semantic.error,
            text = tokens.colors.text.onPrimary,
            accent = tokens.colors.semantic.errorDark
        },
        [FEEDBACK_TYPES.WARNING] = {
            background = tokens.colors.semantic.warning,
            text = tokens.colors.text.primary,
            accent = tokens.colors.semantic.warningDark
        },
        [FEEDBACK_TYPES.INFO] = {
            background = tokens.colors.primary.main,
            text = tokens.colors.text.onPrimary,
            accent = tokens.colors.primary.dark
        },
        [FEEDBACK_TYPES.LOADING] = {
            background = tokens.colors.surface.secondary,
            text = tokens.colors.text.primary,
            accent = tokens.colors.primary.main
        }
    }
    
    return colorMap[feedbackType] and colorMap[feedbackType][variant] or tokens.colors.surface.primary
end

function UIFeedbackSystem.generateId()
    return "feedback_" .. tick() .. "_" .. math.random(1000, 9999)
end

function UIFeedbackSystem.findElementById(elementId)
    -- This would need to be implemented based on your element ID system
    -- For now, return nil as a placeholder
    return nil
end

-- ========================================
-- PUBLIC API
-- ========================================

-- Toast shortcuts
function UIFeedbackSystem.success(message, config)
    config = config or {}
    config.message = message
    config.type = FEEDBACK_TYPES.SUCCESS
    return UIFeedbackSystem.showToast(config)
end

function UIFeedbackSystem.error(message, config)
    config = config or {}
    config.message = message
    config.type = FEEDBACK_TYPES.ERROR
    return UIFeedbackSystem.showToast(config)
end

function UIFeedbackSystem.warning(message, config)
    config = config or {}
    config.message = message
    config.type = FEEDBACK_TYPES.WARNING
    return UIFeedbackSystem.showToast(config)
end

function UIFeedbackSystem.info(message, config)
    config = config or {}
    config.message = message
    config.type = FEEDBACK_TYPES.INFO
    return UIFeedbackSystem.showToast(config)
end

-- Export feedback types and action types for external use
UIFeedbackSystem.FEEDBACK_TYPES = FEEDBACK_TYPES
UIFeedbackSystem.NOTIFICATION_ACTIONS = NOTIFICATION_ACTIONS

-- Initialize the feedback system
UIFeedbackSystem.initialize()

print("💬 UIFeedbackSystem initialized with comprehensive user feedback")

return UIFeedbackSystem
