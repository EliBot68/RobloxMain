-- RuntimeValidator Service
-- Validates game state and world objects at runtime
-- Provides immediate feedback on missing dependencies

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local SafeRequire = require(ReplicatedStorage.Shared.utils.SafeRequire)
local WorldObjectValidator = SafeRequire.require(
    ReplicatedStorage.Shared.utils.WorldObjectValidator,
    {} -- Empty fallback to prevent crashes
)

local RuntimeValidator = {}

-- Validation state
RuntimeValidator.IsValidated = false
RuntimeValidator.ValidationErrors = {}
RuntimeValidator.LastValidation = 0
RuntimeValidator.ValidationInterval = 300 -- 5 minutes

function RuntimeValidator:Init()
    print("🔍 RuntimeValidator initializing...")
    
    -- Immediate validation
    self:ValidateAll()
    
    -- Set up periodic validation
    self:StartPeriodicValidation()
    
    print("✅ RuntimeValidator initialized")
end

function RuntimeValidator:ValidateAll()
    self.ValidationErrors = {}
    self.LastValidation = tick()
    
    -- Validate world objects
    self:ValidateWorldObjects()
    
    -- Validate services (if on server)
    if RunService:IsServer() then
        self:ValidateServices()
    end
    
    -- Generate validation report
    self:GenerateReport()
    
    self.IsValidated = true
end

function RuntimeValidator:ValidateWorldObjects()
    if not WorldObjectValidator or not WorldObjectValidator.validateAllRequired then
        table.insert(self.ValidationErrors, "WorldObjectValidator not available")
        return
    end
    
    local missingRequired = WorldObjectValidator.validateAllRequired()
    local missingOptional = WorldObjectValidator.validateAllOptional()
    
    for _, missing in ipairs(missingRequired) do
        table.insert(self.ValidationErrors, string.format("CRITICAL: Missing required object - %s", missing))
    end
    
    for _, missing in ipairs(missingOptional) do
        table.insert(self.ValidationErrors, string.format("WARNING: Missing optional object - %s", missing))
    end
end

function RuntimeValidator:ValidateServices()
    -- Check if critical services are loaded
    local criticalServices = {
        "PlayerService",
        "DataService", 
        "GameService",
        "UnifiedDataService"
    }
    
    for _, serviceName in ipairs(criticalServices) do
        local success, service = pcall(function()
            return require(game.ServerScriptService.Server.services[serviceName])
        end)
        
        if not success then
            table.insert(self.ValidationErrors, string.format("CRITICAL: Service %s not available - %s", serviceName, tostring(service)))
        elseif service and service.IsInitialized == false then
            table.insert(self.ValidationErrors, string.format("WARNING: Service %s not initialized", serviceName))
        end
    end
end

function RuntimeValidator:ValidateService(service, serviceName)
    -- Validates a single service object
    if not service then
        warn(string.format("🔍 Service validation failed: %s is nil", serviceName))
        return false
    end
    
    if type(service) ~= "table" then
        warn(string.format("🔍 Service validation warning: %s is not a table (type: %s)", serviceName, type(service)))
        return false
    end
    
    -- Check for common service patterns
    local hasValidStructure = false
    
    -- Check for Knit service pattern
    if service.Name and service.Client then
        hasValidStructure = true
    end
    
    -- Check for initialization methods
    if service.Init or service.Initialize or service.Start then
        hasValidStructure = true
    end
    
    -- Check for basic module pattern (at least one function)
    for key, value in pairs(service) do
        if type(value) == "function" then
            hasValidStructure = true
            break
        end
    end
    
    if hasValidStructure then
        return true
    else
        warn(string.format("🔍 Service validation warning: %s has no recognizable service pattern", serviceName))
        return false
    end
end

function RuntimeValidator:GenerateReport()
    local criticalErrors = {}
    local warnings = {}
    
    for _, error in ipairs(self.ValidationErrors) do
        if string.find(error, "CRITICAL") then
            table.insert(criticalErrors, error)
        else
            table.insert(warnings, error)
        end
    end
    
    print("🔍 Runtime Validation Report:")
    print("==================================")
    
    if #criticalErrors == 0 and #warnings == 0 then
        print("✅ All systems validated successfully!")
    else
        if #criticalErrors > 0 then
            print("💥 CRITICAL ERRORS:")
            for _, error in ipairs(criticalErrors) do
                warn("  • " .. error)
            end
        end
        
        if #warnings > 0 then
            print("⚠️ WARNINGS:")
            for _, warning in ipairs(warnings) do
                print("  • " .. warning)
            end
        end
    end
    
    print("==================================")
    
    -- Alert developers if critical errors exist
    if #criticalErrors > 0 then
        self:AlertDevelopers(criticalErrors)
    end
end

function RuntimeValidator:AlertDevelopers(criticalErrors: {string})
    -- Send alerts to developers in game
    local Players = game:GetService("Players")
    
    for _, player in ipairs(Players:GetPlayers()) do
        if self:IsDeveloper(player) then
            self:SendDeveloperAlert(player, criticalErrors)
        end
    end
end

function RuntimeValidator:IsDeveloper(player: Player): boolean
    -- Check if player is a developer (customize this logic)
    local DeveloperConfig = SafeRequire.require(
        ReplicatedStorage.Shared.modules.DeveloperConfig,
        {IsDeveloper = function() return false end}
    )
    
    if DeveloperConfig and DeveloperConfig.IsDeveloper then
        return DeveloperConfig.IsDeveloper(player.UserId)
    end
    
    return false
end

function RuntimeValidator:SendDeveloperAlert(player: Player, errors: {string})
    -- Create alert GUI for developer
    local gui = Instance.new("ScreenGui")
    gui.Name = "ValidationAlert"
    gui.ResetOnSpawn = false
    gui.Parent = player.PlayerGui
    
    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(0.8, 0, 0.6, 0)
    frame.Position = UDim2.new(0.1, 0, 0.2, 0)
    frame.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
    frame.BorderColor3 = Color3.fromRGB(255, 100, 100)
    frame.BorderSizePixel = 3
    frame.Parent = gui
    
    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(1, 0, 0.15, 0)
    title.Position = UDim2.new(0, 0, 0, 0)
    title.BackgroundColor3 = Color3.fromRGB(255, 100, 100)
    title.Text = "🚨 CRITICAL VALIDATION ERRORS"
    title.TextColor3 = Color3.fromRGB(255, 255, 255)
    title.TextScaled = true
    title.Font = Enum.Font.GothamBold
    title.Parent = frame
    
    local scrollFrame = Instance.new("ScrollingFrame")
    scrollFrame.Size = UDim2.new(0.95, 0, 0.7, 0)
    scrollFrame.Position = UDim2.new(0.025, 0, 0.2, 0)
    scrollFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
    scrollFrame.CanvasSize = UDim2.new(0, 0, 0, #errors * 50)
    scrollFrame.Parent = frame
    
    for i, error in ipairs(errors) do
        local errorLabel = Instance.new("TextLabel")
        errorLabel.Size = UDim2.new(0.95, 0, 0, 40)
        errorLabel.Position = UDim2.new(0.025, 0, 0, (i-1) * 50)
        errorLabel.BackgroundTransparency = 1
        errorLabel.Text = error
        errorLabel.TextColor3 = Color3.fromRGB(255, 200, 200)
        errorLabel.TextScaled = true
        errorLabel.Font = Enum.Font.Gotham
        errorLabel.TextXAlignment = Enum.TextXAlignment.Left
        errorLabel.Parent = scrollFrame
    end
    
    local closeButton = Instance.new("TextButton")
    closeButton.Size = UDim2.new(0.2, 0, 0.1, 0)
    closeButton.Position = UDim2.new(0.4, 0, 0.9, 0)
    closeButton.BackgroundColor3 = Color3.fromRGB(100, 100, 100)
    closeButton.Text = "Close"
    closeButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    closeButton.TextScaled = true
    closeButton.Font = Enum.Font.Gotham
    closeButton.Parent = frame
    
    closeButton.MouseButton1Click:Connect(function()
        gui:Destroy()
    end)
    
    -- Auto-close after 30 seconds
    game:GetService("Debris"):AddItem(gui, 30)
end

function RuntimeValidator:StartPeriodicValidation()
    if not RunService:IsServer() then
        return -- Only run periodic validation on server
    end
    
    -- Event-driven periodic validation system
    local periodicValidationEvent = Instance.new("BindableEvent")
    
    local function schedulePeriodicValidation()
        task.wait(self.ValidationInterval)
        periodicValidationEvent:Fire()
    end
    
    periodicValidationEvent.Event:Connect(function()
        if tick() - self.LastValidation >= self.ValidationInterval then
            print("🔄 Running periodic validation...")
            self:ValidateAll()
        end
        spawn(schedulePeriodicValidation)
    end)
    
    -- Start the periodic validation cycle
    spawn(schedulePeriodicValidation)
end

function RuntimeValidator:GetValidationStatus(): {boolean}
    return {
        IsValidated = self.IsValidated,
        ErrorCount = #self.ValidationErrors,
        LastValidation = self.LastValidation,
        Errors = self.ValidationErrors
    }
end

function RuntimeValidator:ForceValidation()
    print("🔄 Forcing immediate validation...")
    self:ValidateAll()
end

return RuntimeValidator
