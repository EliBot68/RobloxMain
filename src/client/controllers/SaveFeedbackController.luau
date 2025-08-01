-- SaveFeedbackController.luau
-- Provides visual feedback for save/load operations

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local RemoteEvents = require(ReplicatedStorage.Shared.modules.RemoteEvents)

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local SaveFeedbackController = {}

-- State tracking
local currentSaveUI = nil
local saveQueue = {}
local isShowingSave = false

function SaveFeedbackController:CreateSaveIndicator()
    -- Create save indicator GUI
    local saveGui = Instance.new("ScreenGui")
    saveGui.Name = "SaveIndicatorGui"
    saveGui.ResetOnSpawn = false
    saveGui.IgnoreGuiInset = true
    saveGui.Parent = playerGui
    
    -- Save container
    local saveContainer = Instance.new("Frame")
    saveContainer.Name = "SaveContainer"
    saveContainer.Size = UDim2.new(0, 250, 0, 60)
    saveContainer.Position = UDim2.new(1, -270, 0, 20)
    saveContainer.BackgroundColor3 = Color3.fromRGB(40, 40, 50)
    saveContainer.BorderSizePixel = 0
    saveContainer.BackgroundTransparency = 1 -- Start invisible
    saveContainer.Parent = saveGui
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 12)
    corner.Parent = saveContainer
    
    -- Gradient background
    local gradient = Instance.new("UIGradient")
    gradient.Color = ColorSequence.new{
        ColorSequenceKeypoint.new(0, Color3.fromRGB(60, 60, 80)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(40, 40, 60))
    }
    gradient.Rotation = 90
    gradient.Parent = saveContainer
    
    -- Save icon
    local saveIcon = Instance.new("TextLabel")
    saveIcon.Name = "SaveIcon"
    saveIcon.Size = UDim2.new(0, 40, 1, 0)
    saveIcon.Position = UDim2.new(0, 10, 0, 0)
    saveIcon.BackgroundTransparency = 1
    saveIcon.Text = "💾"
    saveIcon.TextSize = 24
    saveIcon.Font = Enum.Font.GothamBold
    saveIcon.TextColor3 = Color3.new(1, 1, 1)
    saveIcon.Parent = saveContainer
    
    -- Save text
    local saveText = Instance.new("TextLabel")
    saveText.Name = "SaveText"
    saveText.Size = UDim2.new(1, -60, 1, 0)
    saveText.Position = UDim2.new(0, 50, 0, 0)
    saveText.BackgroundTransparency = 1
    saveText.Text = "Saving..."
    saveText.TextColor3 = Color3.new(1, 1, 1)
    saveText.TextSize = 16
    saveText.Font = Enum.Font.Gotham
    saveText.TextXAlignment = Enum.TextXAlignment.Left
    saveText.TextYAlignment = Enum.TextYAlignment.Center
    saveText.Parent = saveContainer
    
    -- Loading dots animation
    local dots = Instance.new("TextLabel")
    dots.Name = "LoadingDots"
    dots.Size = UDim2.new(0, 30, 1, 0)
    dots.Position = UDim2.new(1, -40, 0, 0)
    dots.BackgroundTransparency = 1
    dots.Text = "..."
    dots.TextColor3 = Color3.fromRGB(150, 150, 150)
    dots.TextSize = 16
    dots.Font = Enum.Font.Gotham
    dots.TextXAlignment = Enum.TextXAlignment.Center
    dots.TextYAlignment = Enum.TextYAlignment.Center
    dots.Parent = saveContainer
    
    return saveGui
end

function SaveFeedbackController:ShowSaving(reason)
    -- Show saving indicator
    reason = reason or "Game progress"
    
    if isShowingSave then
        -- Queue this save notification
        table.insert(saveQueue, reason)
        return
    end
    
    isShowingSave = true
    
    -- Create or update save UI
    if not currentSaveUI or not currentSaveUI.Parent then
        currentSaveUI = self:CreateSaveIndicator()
    end
    
    local saveContainer = currentSaveUI:FindFirstChild("SaveContainer")
    local saveText = saveContainer:FindFirstChild("SaveText")
    local saveIcon = saveContainer:FindFirstChild("SaveIcon")
    local dots = saveContainer:FindFirstChild("LoadingDots")
    
    -- Update text and icon for saving state
    saveText.Text = "Saving " .. reason .. "..."
    saveIcon.Text = "💾"
    saveIcon.TextColor3 = Color3.fromRGB(255, 200, 100)
    
    -- Slide in animation
    saveContainer.BackgroundTransparency = 1
    saveContainer.Position = UDim2.new(1, 0, 0, 20)
    
    local slideInTween = TweenService:Create(saveContainer, TweenInfo.new(0.4, Enum.EasingStyle.Back), {
        Position = UDim2.new(1, -270, 0, 20),
        BackgroundTransparency = 0.1
    })
    slideInTween:Play()
    
    -- Event-driven loading dots animation
    spawn(function()
        local dotEvent = Instance.new("BindableEvent")
        local dotCount = 0
        
        local function updateDots()
            if isShowingSave and saveContainer.Parent then
                dotCount = (dotCount % 3) + 1
                dots.Text = string.rep(".", dotCount) .. string.rep(" ", 3 - dotCount)
                task.wait(0.6) -- Slightly longer interval for better UX
                dotEvent:Fire()
            end
        end
        
        dotEvent.Event:Connect(updateDots)
        updateDots() -- Start the animation
    end)
    
    print("💾 Showing save indicator: " .. reason)
end

function SaveFeedbackController:ShowSaved(success, reason)
    -- Show save completion feedback
    success = success ~= false -- Default to true if nil
    reason = reason or "Game progress"
    
    if not currentSaveUI or not currentSaveUI.Parent then
        currentSaveUI = self:CreateSaveIndicator()
    end
    
    local saveContainer = currentSaveUI:FindFirstChild("SaveContainer")
    local saveText = saveContainer:FindFirstChild("SaveText")
    local saveIcon = saveContainer:FindFirstChild("SaveIcon")
    local dots = saveContainer:FindFirstChild("LoadingDots")
    
    -- Update for completion state
    if success then
        saveText.Text = "Saved!"
        saveIcon.Text = "✅"
        saveIcon.TextColor3 = Color3.fromRGB(100, 255, 100)
        dots.Text = ""
        
        -- Green success gradient
        local gradient = saveContainer:FindFirstChild("UIGradient")
        if gradient then
            gradient.Color = ColorSequence.new{
                ColorSequenceKeypoint.new(0, Color3.fromRGB(50, 150, 50)),
                ColorSequenceKeypoint.new(1, Color3.fromRGB(30, 100, 30))
            }
        end
    else
        saveText.Text = "Save failed!"
        saveIcon.Text = "❌"
        saveIcon.TextColor3 = Color3.fromRGB(255, 100, 100)
        dots.Text = ""
        
        -- Red error gradient
        local gradient = saveContainer:FindFirstChild("UIGradient")
        if gradient then
            gradient.Color = ColorSequence.new{
                ColorSequenceKeypoint.new(0, Color3.fromRGB(150, 50, 50)),
                ColorSequenceKeypoint.new(1, Color3.fromRGB(100, 30, 30))
            }
        end
    end
    
    -- Show completion state for 2 seconds
    wait(2)
    
    -- Slide out animation
    local slideOutTween = TweenService:Create(saveContainer, TweenInfo.new(0.3), {
        Position = UDim2.new(1, 0, 0, 20),
        BackgroundTransparency = 1
    })
    slideOutTween:Play()
    
    slideOutTween.Completed:Connect(function()
        isShowingSave = false
        
        -- Process queued saves with event-driven delay
        if #saveQueue > 0 then
            local nextReason = table.remove(saveQueue, 1)
            
            local queueEvent = Instance.new("BindableEvent")
            local function processNext()
                self:ShowSaving(nextReason)
            end
            
            queueEvent.Event:Connect(processNext)
            task.wait(0.6) -- Optimized pause between saves
            queueEvent:Fire()
        end
    end)
    
    print(success and "✅ Save completed successfully" or "❌ Save failed")
end

function SaveFeedbackController:ShowDataLoading()
    -- Show data loading indicator on join
    local loadingGui = Instance.new("ScreenGui")
    loadingGui.Name = "DataLoadingGui"
    loadingGui.ResetOnSpawn = false
    loadingGui.IgnoreGuiInset = true
    loadingGui.Parent = playerGui
    
    -- Background overlay
    local overlay = Instance.new("Frame")
    overlay.Name = "Overlay"
    overlay.Size = UDim2.new(1, 0, 1, 0)
    overlay.Position = UDim2.new(0, 0, 0, 0)
    overlay.BackgroundColor3 = Color3.new(0, 0, 0)
    overlay.BackgroundTransparency = 0.5
    overlay.BorderSizePixel = 0
    overlay.Parent = loadingGui
    
    -- Loading container
    local loadingContainer = Instance.new("Frame")
    loadingContainer.Name = "LoadingContainer"
    loadingContainer.Size = UDim2.new(0, 300, 0, 120)
    loadingContainer.Position = UDim2.new(0.5, -150, 0.5, -60)
    loadingContainer.BackgroundColor3 = Color3.fromRGB(40, 40, 50)
    loadingContainer.BorderSizePixel = 0
    loadingContainer.Parent = loadingGui
    
    local loadingCorner = Instance.new("UICorner")
    loadingCorner.CornerRadius = UDim.new(0, 15)
    loadingCorner.Parent = loadingContainer
    
    -- Loading title
    local loadingTitle = Instance.new("TextLabel")
    loadingTitle.Name = "LoadingTitle"
    loadingTitle.Size = UDim2.new(1, 0, 0, 40)
    loadingTitle.Position = UDim2.new(0, 0, 0, 10)
    loadingTitle.BackgroundTransparency = 1
    loadingTitle.Text = "🎮 Loading Your Progress"
    loadingTitle.TextColor3 = Color3.new(1, 1, 1)
    loadingTitle.TextSize = 20
    loadingTitle.Font = Enum.Font.GothamBold
    loadingTitle.Parent = loadingContainer
    
    -- Loading subtitle
    local loadingSubtitle = Instance.new("TextLabel")
    loadingSubtitle.Name = "LoadingSubtitle"
    loadingSubtitle.Size = UDim2.new(1, 0, 0, 30)
    loadingSubtitle.Position = UDim2.new(0, 0, 0, 50)
    loadingSubtitle.BackgroundTransparency = 1
    loadingSubtitle.Text = "Retrieving your coins, XP, and unlocks..."
    loadingSubtitle.TextColor3 = Color3.fromRGB(200, 200, 200)
    loadingSubtitle.TextSize = 14
    loadingSubtitle.Font = Enum.Font.Gotham
    loadingSubtitle.Parent = loadingContainer
    
    -- Loading bar background
    local barBackground = Instance.new("Frame")
    barBackground.Name = "BarBackground"
    barBackground.Size = UDim2.new(0.8, 0, 0, 8)
    barBackground.Position = UDim2.new(0.1, 0, 0, 90)
    barBackground.BackgroundColor3 = Color3.fromRGB(60, 60, 70)
    barBackground.BorderSizePixel = 0
    barBackground.Parent = loadingContainer
    
    local barCorner = Instance.new("UICorner")
    barCorner.CornerRadius = UDim.new(0, 4)
    barCorner.Parent = barBackground
    
    -- Loading bar
    local loadingBar = Instance.new("Frame")
    loadingBar.Name = "LoadingBar"
    loadingBar.Size = UDim2.new(0, 0, 1, 0)
    loadingBar.Position = UDim2.new(0, 0, 0, 0)
    loadingBar.BackgroundColor3 = Color3.fromRGB(100, 200, 255)
    loadingBar.BorderSizePixel = 0
    loadingBar.Parent = barBackground
    
    local loadingBarCorner = Instance.new("UICorner")
    loadingBarCorner.CornerRadius = UDim.new(0, 4)
    loadingBarCorner.Parent = loadingBar
    
    -- Animate loading bar
    local loadingTween = TweenService:Create(loadingBar, TweenInfo.new(2, Enum.EasingStyle.Quad), {
        Size = UDim2.new(1, 0, 1, 0)
    })
    loadingTween:Play()
    
    -- Return GUI for external control
    return loadingGui
end

function SaveFeedbackController:HideDataLoading(loadingGui)
    -- Hide the data loading screen
    if loadingGui and loadingGui.Parent then
        local fadeOut = TweenService:Create(loadingGui, TweenInfo.new(0.5), {
            BackgroundTransparency = 1
        })
        
        -- Fade out all children
        for _, child in pairs(loadingGui:GetDescendants()) do
            if child:IsA("GuiObject") then
                if child:FindFirstChild("BackgroundTransparency") then
                    TweenService:Create(child, TweenInfo.new(0.5), {
                        BackgroundTransparency = 1
                    }):Play()
                end
                if child:FindFirstChild("TextTransparency") then
                    TweenService:Create(child, TweenInfo.new(0.5), {
                        TextTransparency = 1
                    }):Play()
                end
            end
        end
        
        fadeOut:Play()
        fadeOut.Completed:Connect(function()
            loadingGui:Destroy()
        end)
    end
end

function SaveFeedbackController:ShowDataLoadSuccess(playerData)
    -- Show successful data load summary
    local summaryGui = Instance.new("ScreenGui")
    summaryGui.Name = "DataSummaryGui"
    summaryGui.ResetOnSpawn = false
    summaryGui.Parent = playerGui
    
    local summaryContainer = Instance.new("Frame")
    summaryContainer.Name = "SummaryContainer"
    summaryContainer.Size = UDim2.new(0, 320, 0, 140)
    summaryContainer.Position = UDim2.new(0.5, -160, 0, -150) -- Start above screen
    summaryContainer.BackgroundColor3 = Color3.fromRGB(40, 40, 50)
    summaryContainer.BorderSizePixel = 0
    summaryContainer.Parent = summaryGui
    
    local summaryCorner = Instance.new("UICorner")
    summaryCorner.CornerRadius = UDim.new(0, 15)
    summaryCorner.Parent = summaryContainer
    
    -- Welcome message
    local welcomeText = Instance.new("TextLabel")
    welcomeText.Name = "WelcomeText"
    welcomeText.Size = UDim2.new(1, 0, 0, 30)
    welcomeText.Position = UDim2.new(0, 0, 0, 10)
    welcomeText.BackgroundTransparency = 1
    welcomeText.Text = "✅ Welcome back, " .. player.Name .. "!"
    welcomeText.TextColor3 = Color3.fromRGB(100, 255, 100)
    welcomeText.TextSize = 18
    welcomeText.Font = Enum.Font.GothamBold
    welcomeText.Parent = summaryContainer
    
    -- Data summary
    local dataText = Instance.new("TextLabel")
    dataText.Name = "DataText"
    dataText.Size = UDim2.new(1, -20, 0, 80)
    dataText.Position = UDim2.new(0, 10, 0, 40)
    dataText.BackgroundTransparency = 1
    dataText.TextColor3 = Color3.new(1, 1, 1)
    dataText.TextSize = 14
    dataText.Font = Enum.Font.Gotham
    dataText.TextXAlignment = Enum.TextXAlignment.Left
    dataText.TextYAlignment = Enum.TextYAlignment.Top
    dataText.TextWrapped = true
    dataText.Parent = summaryContainer
    
    -- Format player data summary
    local coinsText = string.format("💰 Coins: %s", self:FormatNumber(playerData.coins or 0))
    local levelText = string.format("⭐ Level: %d", playerData.level or 1)
    local xpText = string.format("🔥 XP: %s", self:FormatNumber(playerData.experience or 0))
    local cosmeticsText = string.format("🎨 Cosmetics: %d", #(playerData.ownedTrails or {}) + #(playerData.ownedSkins or {}))
    
    dataText.Text = string.format("%s    %s\n%s\n%s", coinsText, levelText, xpText, cosmeticsText)
    
    -- Slide down animation
    local slideDown = TweenService:Create(summaryContainer, TweenInfo.new(0.6, Enum.EasingStyle.Back), {
        Position = UDim2.new(0.5, -160, 0, 20)
    })
    slideDown:Play()
    
    -- Auto-hide after 4 seconds
    spawn(function()
        wait(4)
        local slideUp = TweenService:Create(summaryContainer, TweenInfo.new(0.4), {
            Position = UDim2.new(0.5, -160, 0, -150)
        })
        slideUp:Play()
        slideUp.Completed:Connect(function()
            summaryGui:Destroy()
        end)
    end)
end

function SaveFeedbackController:FormatNumber(number)
    -- Format large numbers for display
    if number >= 1000000000 then
        return string.format("%.1fB", number / 1000000000)
    elseif number >= 1000000 then
        return string.format("%.1fM", number / 1000000)
    elseif number >= 1000 then
        return string.format("%.1fK", number / 1000)
    else
        return tostring(number)
    end
end

function SaveFeedbackController:Initialize()
    -- Set up save feedback system
    print("💾 SaveFeedbackController initializing...")
    
    -- Listen for save events from server
    RemoteEvents.SaveStarted.OnClientEvent:Connect(function(reason)
        self:ShowSaving(reason)
    end)
    
    RemoteEvents.SaveCompleted.OnClientEvent:Connect(function(success, reason)
        self:ShowSaved(success, reason)
    end)
    
    RemoteEvents.DataLoadStarted.OnClientEvent:Connect(function()
        local loadingGui = self:ShowDataLoading()
        
        -- Listen for load completion
        local connection
        connection = RemoteEvents.DataLoadCompleted.OnClientEvent:Connect(function(success, playerData)
            connection:Disconnect()
            self:HideDataLoading(loadingGui)
            
            if success and playerData then
                local successEvent = Instance.new("BindableEvent")
                
                local function showSuccess()
                    self:ShowDataLoadSuccess(playerData)
                end
                
                successEvent.Event:Connect(showSuccess)
                task.wait(0.6) -- Optimized pause timing
                successEvent:Fire()
            end
        end)
    end)
    
    print("✅ SaveFeedbackController initialized!")
end

-- Auto-initialize
SaveFeedbackController:Initialize()

return SaveFeedbackController
