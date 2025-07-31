-- InputController.luau
-- Handles player input and controls including Xbox controller support

local UserInputService = game:GetService("UserInputService")
local ContextActionService = game:GetService("ContextActionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local RemoteEvents = require(ReplicatedStorage.Shared.modules.RemoteEvents)
local GameConstants = require(ReplicatedStorage.Shared.constants.GameConstants)
local ConnectionManager = require(ReplicatedStorage.Shared.core.ConnectionManager)

local player = Players.LocalPlayer
local InputController = {}

-- Reference to PlayerController for color changes
local PlayerController = nil
local playerSettings = nil -- Will store player's accessibility settings

function InputController:BindAction(actionName, callback, createTouchButton, ...)
    ContextActionService:BindAction(actionName, callback, createTouchButton, ...)
end

function InputController:UnbindAction(actionName)
    ContextActionService:UnbindAction(actionName)
end

function InputController:OnKeyPressed(key, callback)
    -- Use ConnectionManager directly for UserInputService events
    local connection = UserInputService.InputBegan:Connect(function(input, gameProcessed)
        if gameProcessed then return end
        
        if input.KeyCode == key then
            callback()
        end
    end)
    
    -- Track the connection using ConnectionManager
    local connectionId = ConnectionManager:TrackConnection(
        connection,
        {
            service = "InputController",
            player = player,
            description = "Key binding for " .. tostring(key),
            connectionType = ConnectionManager.ConnectionTypes.OTHER
        }
    )
    
    return connectionId
end

function InputController:SetPlayerController(controller)
    PlayerController = controller
end

function InputController:UpdatePlayerSettings(settings)
    playerSettings = settings
    
    -- Update controller bindings if needed
    if playerSettings and playerSettings.controllerEnabled then
        self:SetupControllerSupport()
    end
end

function InputController:HandleColorChange(colorName)
    if PlayerController then
        PlayerController:ChangeColor(colorName)
    end
    print("🎨 Color changed to " .. colorName)
end

function InputController:TrackControllerInput(inputMethod)
    -- Track controller usage for quests and analytics (with error handling)
    local success, error = pcall(function()
        RemoteEvents.UpdateQuestProgress:FireServer("controller_input", 1, {
            inputMethod = inputMethod,
            timestamp = os.time()
        })
    end)
    
    if not success then
        warn("Failed to track controller input:", error)
    end
    
    print("🎮 Controller input tracked: " .. inputMethod)
end

function InputController:SetupControllerSupport()
    -- Validate GameConstants exist
    if not GameConstants or not GameConstants.CONTROLLER_ENABLED then
        warn("⚠️ GameConstants.CONTROLLER_ENABLED not found, controller support disabled")
        return
    end
    
    if not GameConstants.CONTROLLER_ENABLED or not playerSettings or not playerSettings.controllerEnabled then
        return
    end
    
    print("🎮 Setting up Xbox controller support...")
    
    -- Xbox controller D-pad mappings with managed connections
    local dpadConnection = UserInputService.InputBegan:Connect(function(input, gameProcessed)
        if gameProcessed then return end
        
        if input.KeyCode == Enum.KeyCode.DPadUp then
            self:HandleColorChange("RED")
            self:TrackControllerInput("dpad_up")
        elseif input.KeyCode == Enum.KeyCode.DPadLeft then
            self:HandleColorChange("GREEN")
            self:TrackControllerInput("dpad_left")
        elseif input.KeyCode == Enum.KeyCode.DPadRight then
            self:HandleColorChange("BLUE")
            self:TrackControllerInput("dpad_right")
        end
    end)
    
    ConnectionManager:TrackConnection(
        dpadConnection,
        {
            service = "InputController",
            player = player,
            description = "Xbox controller D-pad input handling",
            connectionType = ConnectionManager.ConnectionTypes.OTHER
        }
    )
    
    -- Gamepad thumbstick support for additional accessibility
    local thumbstickConnection = UserInputService.InputChanged:Connect(function(input, gameProcessed)
        if gameProcessed then return end
        
        if input.KeyCode == Enum.KeyCode.Thumbstick1 then
            local position = input.Position
            
            -- Convert thumbstick position to color selection
            if math.abs(position.Y) > math.abs(position.X) then
                -- Vertical movement (up/down)
                if position.Y > 0.5 then
                    self:HandleColorChange("RED") -- Up
                elseif position.Y < -0.5 then
                    self:HandleColorChange("BLUE") -- Down
                end
            else
                -- Horizontal movement (left/right)
                if position.X < -0.5 then
                    self:HandleColorChange("GREEN") -- Left
                elseif position.X > 0.5 then
                    self:HandleColorChange("BLUE") -- Right
                end
            end
        end
    end)
    
    ConnectionManager:TrackConnection(
        thumbstickConnection,
        {
            service = "InputController",
            player = player,
            description = "Xbox controller thumbstick input handling",
            connectionType = ConnectionManager.ConnectionTypes.OTHER
        }
    )
    
    print("✅ Xbox controller D-pad support enabled (Up=Red, Left=Green, Right=Blue)")
end

function InputController:SetupColorControls()
    -- Bind color change actions for mobile/touch
    ContextActionService:BindAction(
        "ColorRed",
        function(actionName, inputState, inputObject)
            if inputState == Enum.UserInputState.Begin then
                self:HandleColorChange("RED")
            end
        end,
        true, -- Create touch button
        Enum.KeyCode.One
    )
    
    ContextActionService:BindAction(
        "ColorGreen", 
        function(actionName, inputState, inputObject)
            if inputState == Enum.UserInputState.Begin then
                self:HandleColorChange("GREEN")
            end
        end,
        true, -- Create touch button
        Enum.KeyCode.Two
    )
    
    ContextActionService:BindAction(
        "ColorBlue",
        function(actionName, inputState, inputObject)
            if inputState == Enum.UserInputState.Begin then
                self:HandleColorChange("BLUE")
            end
        end,
        true, -- Create touch button
        Enum.KeyCode.Three
    )
    
    -- Also bind to keyboard for desktop
    self:OnKeyPressed(Enum.KeyCode.One, function()
        self:HandleColorChange("RED")
    end)
    
    self:OnKeyPressed(Enum.KeyCode.Two, function()
        self:HandleColorChange("GREEN")
    end)
    
    self:OnKeyPressed(Enum.KeyCode.Three, function()
        self:HandleColorChange("BLUE")
    end)
    
    -- Fun jump animation trigger (Space key) with safe require
    self:OnKeyPressed(Enum.KeyCode.Space, function()
        local success, PolishController = pcall(require, script.Parent.PolishController)
        if success and PolishController and PolishController.TriggerJumpAnimation then
            PolishController:TriggerJumpAnimation()
        else
            print("⚠️ PolishController not available for jump animation")
        end
    end)
    
    -- Style the mobile buttons
    self:StyleMobileButtons()
    
    print("🎮 Color controls setup complete")
end

function InputController:StyleMobileButtons()
    -- Wait a frame for buttons to be created
    game:GetService("RunService").Heartbeat:Wait()
    
    local playerGui = player:WaitForChild("PlayerGui")
    local contextActionGui = playerGui:FindFirstChild("ContextActionGui")
    
    if contextActionGui then
        -- Enhanced button styling for better mobile experience
        local buttonSize = UDim2.new(0, 80, 0, 80) -- Larger tap-friendly size
        
        -- Fallback symbols in case GameConstants.COLORBLIND_SYMBOLS is missing
        local fallbackSymbols = {
            RED = "🔺",
            GREEN = "⬟", 
            BLUE = "⬢",
            YELLOW = "⭐",
            PURPLE = "⬥",
            ORANGE = "⬣"
        }
        
        local symbols = (GameConstants and GameConstants.COLORBLIND_SYMBOLS) or fallbackSymbols
        
        local buttonConfigs = {
            {
                name = "ColorRed",
                color = Color3.new(1, 0.2, 0.2),
                borderColor = Color3.new(0.8, 0, 0),
                position = UDim2.new(0, 15, 1, -180),
                symbol = symbols.RED
            },
            {
                name = "ColorGreen", 
                color = Color3.new(0.2, 1, 0.2),
                borderColor = Color3.new(0, 0.8, 0),
                position = UDim2.new(0, 105, 1, -180),
                symbol = symbols.GREEN
            },
            {
                name = "ColorBlue",
                color = Color3.new(0.2, 0.2, 1),
                borderColor = Color3.new(0, 0, 0.8),
                position = UDim2.new(0, 195, 1, -180),
                symbol = symbols.BLUE
            },
            {
                name = "ColorYellow",
                color = Color3.new(1, 1, 0.2),
                borderColor = Color3.new(0.8, 0.8, 0),
                position = UDim2.new(0, 285, 1, -180),
                symbol = symbols.YELLOW
            },
            {
                name = "ColorPurple",
                color = Color3.new(0.8, 0.2, 1),
                borderColor = Color3.new(0.6, 0, 0.8),
                position = UDim2.new(0, 15, 1, -90),
                symbol = symbols.PURPLE
            },
            {
                name = "ColorOrange",
                color = Color3.new(1, 0.6, 0.2),
                borderColor = Color3.new(0.8, 0.4, 0),
                position = UDim2.new(0, 105, 1, -90),
                symbol = symbols.ORANGE
            }
        }
        
        -- Apply enhanced styling to each button
        for _, config in pairs(buttonConfigs) do
            local button = contextActionGui:FindFirstChild(config.name)
            if button and button:FindFirstChild("ImageLabel") then
                local imageLabel = button.ImageLabel
                
                -- Enhanced styling for better mobile experience
                imageLabel.BackgroundColor3 = config.color
                imageLabel.BackgroundTransparency = 0.1 -- More visible
                imageLabel.BorderSizePixel = 3 -- Thicker border
                imageLabel.BorderColor3 = config.borderColor
                imageLabel.Size = buttonSize
                button.Position = config.position
                button.Size = buttonSize
                
                -- Add corner radius for modern look
                local corner = imageLabel:FindFirstChild("UICorner")
                if not corner then
                    corner = Instance.new("UICorner")
                    corner.CornerRadius = UDim.new(0, 12)
                    corner.Parent = imageLabel
                end
                
                -- Add drop shadow for depth
                local shadow = imageLabel:FindFirstChild("Shadow")
                if not shadow then
                    shadow = Instance.new("Frame")
                    shadow.Name = "Shadow"
                    shadow.Size = UDim2.new(1, 4, 1, 4)
                    shadow.Position = UDim2.new(0, 2, 0, 2)
                    shadow.BackgroundColor3 = Color3.new(0, 0, 0)
                    shadow.BackgroundTransparency = 0.8
                    shadow.BorderSizePixel = 0
                    shadow.ZIndex = imageLabel.ZIndex - 1
                    shadow.Parent = imageLabel
                    
                    local shadowCorner = Instance.new("UICorner")
                    shadowCorner.CornerRadius = UDim.new(0, 12)
                    shadowCorner.Parent = shadow
                end
                
                -- Add symbol for colorblind mode with better visibility
                if playerSettings and playerSettings.colorblindMode then
                    self:AddSymbolToButton(button, config.symbol)
                end
                
                -- Add haptic feedback for mobile with managed connections
                local buttonClickConnection = button.MouseButton1Click:Connect(function()
                    -- Visual feedback for button press
                    local originalSize = imageLabel.Size
                    imageLabel.Size = UDim2.new(originalSize.X.Scale * 0.9, originalSize.X.Offset * 0.9,
                                              originalSize.Y.Scale * 0.9, originalSize.Y.Offset * 0.9)
                    
                    game:GetService("TweenService"):Create(imageLabel, 
                        TweenInfo.new(0.1, Enum.EasingStyle.Quad), 
                        {Size = originalSize}
                    ):Play()
                end)
                
                ConnectionManager:TrackConnection(
                    buttonClickConnection,
                    {
                        service = "InputController",
                        player = player,
                        description = "Mobile button visual feedback for " .. config.name,
                        connectionType = ConnectionManager.ConnectionTypes.GUI
                    }
                )
            end
        end
        
        print("📱 Enhanced mobile color buttons styling applied")
    end
end

function InputController:AddSymbolToButton(button, symbol)
    local imageLabel = button:FindFirstChild("ImageLabel")
    if not imageLabel then return end
    
    -- Remove existing symbol if any
    local existingSymbol = imageLabel:FindFirstChild("ColorSymbol")
    if existingSymbol then
        existingSymbol:Destroy()
    end
    
    -- Create symbol label
    local symbolLabel = Instance.new("TextLabel")
    symbolLabel.Name = "ColorSymbol"
    symbolLabel.Size = UDim2.new(0.6, 0, 0.6, 0)
    symbolLabel.Position = UDim2.new(0.2, 0, 0.2, 0)
    symbolLabel.BackgroundTransparency = 1
    symbolLabel.Text = symbol
    symbolLabel.TextColor3 = Color3.new(1, 1, 1)
    symbolLabel.TextScaled = true
    symbolLabel.Font = Enum.Font.SourceSansBold
    symbolLabel.TextStrokeTransparency = 0
    symbolLabel.TextStrokeColor3 = Color3.new(0, 0, 0)
    symbolLabel.Parent = imageLabel
    
    print("🔤 Added symbol " .. symbol .. " to color button")
end
function InputController:Init()
    print("🎮 InputController initializing...")
    
    -- Initialize ConnectionManager
    ConnectionManager:Initialize()
    
    -- Wait for PlayerController to be available
    spawn(function()
        wait(1) -- Give time for other controllers to initialize
        
        local success, controller = pcall(require, script.Parent.PlayerController)
        if success and controller then
            PlayerController = controller
            self:SetupColorControls()
        else
            warn("⚠️ PlayerController not available, color controls disabled")
            return
        end
        
        -- Listen for player settings updates with managed connection
        local settingsConnection = RemoteEvents.PlayerDataUpdated.OnClientEvent:Connect(function(data)
            if data and data.settings then
                self:UpdatePlayerSettings(data.settings)
                -- Re-style buttons when settings change
                self:StyleMobileButtons()
            end
        end)
        
        ConnectionManager:TrackConnection(
            settingsConnection,
            {
                service = "InputController",
                player = player,
                description = "Player settings update handler",
                connectionType = ConnectionManager.ConnectionTypes.REMOTE_HANDLER
            }
        )
        
        -- Setup controller support
        self:SetupControllerSupport()
    end)
    
    print("✅ InputController initialized")
end

-- Cleanup method for proper resource management
function InputController:Cleanup()
    ConnectionManager:CleanupServiceConnections("InputController")
    print("🧹 InputController cleanup completed")
end

return InputController
