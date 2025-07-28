-- InputController.luau
-- Handles player input and controls including Xbox controller support

local UserInputService = game:GetService("UserInputService")
local ContextActionService = game:GetService("ContextActionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local RemoteEvents = require(ReplicatedStorage.Shared.modules.RemoteEvents)
local GameConstants = require(ReplicatedStorage.Shared.constants.GameConstants)

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
    UserInputService.InputBegan:Connect(function(input, gameProcessed)
        if gameProcessed then return end
        
        if input.KeyCode == key then
            callback()
        end
    end)
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
    -- Track controller usage for quests and analytics
    RemoteEvents.UpdateQuestProgress:FireServer("controller_input", 1, {
        inputMethod = inputMethod,
        timestamp = os.time()
    })
    
    print("🎮 Controller input tracked: " .. inputMethod)
end

function InputController:SetupControllerSupport()
    if not GameConstants.CONTROLLER_ENABLED or not playerSettings or not playerSettings.controllerEnabled then
        return
    end
    
    print("🎮 Setting up Xbox controller support...")
    
    -- Xbox controller D-pad mappings
    -- D-pad Up = Red
    UserInputService.InputBegan:Connect(function(input, gameProcessed)
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
    
    -- Gamepad thumbstick support for additional accessibility
    UserInputService.InputChanged:Connect(function(input, gameProcessed)
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
    
    -- Fun jump animation trigger (Space key)
    self:OnKeyPressed(Enum.KeyCode.Space, function()
        local PolishController = require(script.Parent.PolishController)
        if PolishController and PolishController.TriggerJumpAnimation then
            PolishController:TriggerJumpAnimation()
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
        local buttonConfigs = {
            {
                name = "ColorRed",
                color = Color3.new(1, 0.2, 0.2),
                borderColor = Color3.new(0.8, 0, 0),
                position = UDim2.new(0, 15, 1, -180),
                symbol = GameConstants.COLORBLIND_SYMBOLS.RED
            },
            {
                name = "ColorGreen", 
                color = Color3.new(0.2, 1, 0.2),
                borderColor = Color3.new(0, 0.8, 0),
                position = UDim2.new(0, 105, 1, -180),
                symbol = GameConstants.COLORBLIND_SYMBOLS.GREEN
            },
            {
                name = "ColorBlue",
                color = Color3.new(0.2, 0.2, 1),
                borderColor = Color3.new(0, 0, 0.8),
                position = UDim2.new(0, 195, 1, -180),
                symbol = GameConstants.COLORBLIND_SYMBOLS.BLUE
            },
            {
                name = "ColorYellow",
                color = Color3.new(1, 1, 0.2),
                borderColor = Color3.new(0.8, 0.8, 0),
                position = UDim2.new(0, 285, 1, -180),
                symbol = GameConstants.COLORBLIND_SYMBOLS.YELLOW
            },
            {
                name = "ColorPurple",
                color = Color3.new(0.8, 0.2, 1),
                borderColor = Color3.new(0.6, 0, 0.8),
                position = UDim2.new(0, 15, 1, -90),
                symbol = GameConstants.COLORBLIND_SYMBOLS.PURPLE
            },
            {
                name = "ColorOrange",
                color = Color3.new(1, 0.6, 0.2),
                borderColor = Color3.new(0.8, 0.4, 0),
                position = UDim2.new(0, 105, 1, -90),
                symbol = GameConstants.COLORBLIND_SYMBOLS.ORANGE
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
                
                -- Add haptic feedback for mobile
                button.MouseButton1Click:Connect(function()
                    -- Visual feedback for button press
                    local originalSize = imageLabel.Size
                    imageLabel.Size = UDim2.new(originalSize.X.Scale * 0.9, originalSize.X.Offset * 0.9,
                                              originalSize.Y.Scale * 0.9, originalSize.Y.Offset * 0.9)
                    
                    game:GetService("TweenService"):Create(imageLabel, 
                        TweenInfo.new(0.1, Enum.EasingStyle.Quad), 
                        {Size = originalSize}
                    ):Play()
                end)
            end
        end
        
        print("📱 Enhanced mobile color buttons styling applied")
    end
end
        local blueButton = contextActionGui:FindFirstChild("ColorBlue")
        if blueButton and blueButton:FindFirstChild("ImageLabel") then
            blueButton.ImageLabel.BackgroundColor3 = Color3.new(0.2, 0.2, 1)
            blueButton.ImageLabel.BackgroundTransparency = 0.2
            blueButton.ImageLabel.BorderSizePixel = 2
            blueButton.ImageLabel.BorderColor3 = Color3.new(0, 0, 0.8)
            blueButton.Position = UDim2.new(0, 160, 1, -160) -- Bottom center
            
            -- Add symbol for colorblind mode
            if playerSettings and playerSettings.colorblindMode then
                self:AddSymbolToButton(blueButton, GameConstants.COLORBLIND_SYMBOLS.BLUE)
            end
        end
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
    
    -- Wait for PlayerController to be available
    spawn(function()
        wait(1) -- Give time for other controllers to initialize
        PlayerController = require(script.Parent.PlayerController)
        self:SetupColorControls()
        
        -- Listen for player settings updates
        RemoteEvents.PlayerDataUpdated.OnClientEvent:Connect(function(data)
            if data and data.settings then
                self:UpdatePlayerSettings(data.settings)
                -- Re-style buttons when settings change
                self:StyleMobileButtons()
            end
        end)
        
        -- Setup controller support
        self:SetupControllerSupport()
    end)
    
    print("✅ InputController initialized")
end

return InputController
