--[[
	DeveloperToolsController
	Client-side developer tools GUI controller
	Only accessible by authorized developers
--]]

local Players = game:GetService("Players")
local StarterGui = game:GetService("StarterGui")
local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

local Knit = require(ReplicatedStorage.Packages.Knit)
local DeveloperConfig = require(ReplicatedStorage.Shared.modules.DeveloperConfig)

local DeveloperToolsController = Knit.CreateController {
	Name = "DeveloperToolsController",
}

-- UI References
local gui = nil
local mainFrame = nil
local isVisible = false

-- Check if player is a developer
local function isDeveloper()
	local player = Players.LocalPlayer
	return DeveloperConfig:IsDeveloper(player)
end

-- Create the developer GUI
local function createDeveloperGUI()
	-- Create ScreenGui
	gui = Instance.new("ScreenGui")
	gui.Name = "DeveloperTools"
	gui.ResetOnSpawn = false
	gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	
	-- Main Frame
	mainFrame = Instance.new("Frame")
	mainFrame.Name = "MainFrame"
	mainFrame.Size = UDim2.new(0, 400, 0, 500)
	mainFrame.Position = UDim2.new(0, 20, 0, 20)
	mainFrame.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
	mainFrame.BorderSizePixel = 0
	mainFrame.Parent = gui
	
	-- Corner rounding
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 8)
	corner.Parent = mainFrame
	
	-- Title
	local title = Instance.new("TextLabel")
	title.Name = "Title"
	title.Size = UDim2.new(1, 0, 0, 40)
	title.Position = UDim2.new(0, 0, 0, 0)
	title.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
	title.BorderSizePixel = 0
	title.Text = "🛠️ Developer Tools"
	title.TextColor3 = Color3.fromRGB(255, 255, 255)
	title.TextScaled = true
	title.Font = Enum.Font.GothamBold
	title.Parent = mainFrame
	
	local titleCorner = Instance.new("UICorner")
	titleCorner.CornerRadius = UDim.new(0, 8)
	titleCorner.Parent = title
	
	-- Content Frame
	local contentFrame = Instance.new("ScrollingFrame")
	contentFrame.Name = "Content"
	contentFrame.Size = UDim2.new(1, -20, 1, -60)
	contentFrame.Position = UDim2.new(0, 10, 0, 50)
	contentFrame.BackgroundTransparency = 1
	contentFrame.BorderSizePixel = 0
	contentFrame.ScrollBarThickness = 8
	contentFrame.ScrollBarImageColor3 = Color3.fromRGB(100, 100, 100)
	contentFrame.Parent = mainFrame
	
	-- UI Layout
	local layout = Instance.new("UIListLayout")
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.Padding = UDim.new(0, 10)
	layout.Parent = contentFrame
	
	-- Close Button
	local closeButton = createButton("❌ Close", function()
		toggleGUI()
	end)
	closeButton.LayoutOrder = 1
	closeButton.Parent = contentFrame
	
	-- Teleportation Section
	createSection("🚀 Teleportation", contentFrame, 2)
	
	-- Track teleport buttons
	local tracks = {"Track1", "Track2", "Track3", "Hub"}
	for i, trackName in pairs(tracks) do
		local button = createButton("Teleport to " .. trackName, function()
			DeveloperToolsController.TeleportService:TeleportToTrack(trackName)
		end)
		button.LayoutOrder = 2 + i
		button.Parent = contentFrame
	end
	
	-- Economy Section
	createSection("💰 Economy", contentFrame, 10)
	
	-- Coin grant buttons
	local coinAmounts = {100, 1000, 10000}
	for i, amount in pairs(coinAmounts) do
		local button = createButton("Grant " .. amount .. " Coins", function()
			DeveloperToolsController.DeveloperService:GrantCoins(amount)
		end)
		button.LayoutOrder = 10 + i
		button.Parent = contentFrame
	end
	
	-- XP grant buttons
	local xpAmounts = {50, 500, 5000}
	for i, amount in pairs(xpAmounts) do
		local button = createButton("Grant " .. amount .. " XP", function()
			DeveloperToolsController.DeveloperService:GrantXP(amount)
		end)
		button.LayoutOrder = 15 + i
		button.Parent = contentFrame
	end
	
	-- Player Data Section
	createSection("👤 Player Data", contentFrame, 20)
	
	local resetSaveButton = createButton("⚠️ Reset Player Save", function()
		-- Confirmation dialog
		local confirmGui = createConfirmationDialog(
			"Reset Save Data",
			"Are you sure you want to reset your save data? This cannot be undone!",
			function()
				DeveloperToolsController.DeveloperService:ResetPlayerSave()
			end
		)
		confirmGui.Parent = gui
	end)
	resetSaveButton.LayoutOrder = 21
	resetSaveButton.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
	resetSaveButton.Parent = contentFrame
	
	local skipTutorialButton = createButton("Skip Tutorial", function()
		DeveloperToolsController.DeveloperService:SkipTutorial()
	end)
	skipTutorialButton.LayoutOrder = 22
	skipTutorialButton.Parent = contentFrame
	
	-- Debug Section
	createSection("🐛 Debug", contentFrame, 30)
	
	local logAssetsButton = createButton("Log Missing Assets", function()
		DeveloperToolsController.DeveloperService:LogMissingAssets()
	end)
	logAssetsButton.LayoutOrder = 31
	logAssetsButton.Parent = contentFrame
	
	local checkScriptsButton = createButton("Check Script Errors", function()
		DeveloperToolsController.DeveloperService:CheckScriptErrors()
	end)
	checkScriptsButton.LayoutOrder = 32
	checkScriptsButton.Parent = contentFrame
	
	-- Testing Section
	createSection("🧪 Testing", contentFrame, 40)
	
	local unlockAllButton = createButton("Unlock All Content", function()
		DeveloperToolsController.DeveloperService:UnlockAllContent()
	end)
	unlockAllButton.LayoutOrder = 41
	unlockAllButton.Parent = contentFrame
	
	local maxStatsButton = createButton("Max Player Stats", function()
		DeveloperToolsController.DeveloperService:MaxPlayerStats()
	end)
	maxStatsButton.LayoutOrder = 42
	maxStatsButton.Parent = contentFrame
	
	-- Update content size
	contentFrame.CanvasSize = UDim2.new(0, 0, 0, layout.AbsoluteContentSize.Y + 20)
	layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
		contentFrame.CanvasSize = UDim2.new(0, 0, 0, layout.AbsoluteContentSize.Y + 20)
	end)
	
	-- Initially hidden
	mainFrame.Position = UDim2.new(0, -420, 0, 20)
	gui.Parent = Players.LocalPlayer:WaitForChild("PlayerGui")
end

-- Create a button
function createButton(text, callback)
	local button = Instance.new("TextButton")
	button.Size = UDim2.new(1, 0, 0, 35)
	button.BackgroundColor3 = Color3.fromRGB(70, 130, 180)
	button.BorderSizePixel = 0
	button.Text = text
	button.TextColor3 = Color3.fromRGB(255, 255, 255)
	button.TextScaled = true
	button.Font = Enum.Font.Gotham
	
	local buttonCorner = Instance.new("UICorner")
	buttonCorner.CornerRadius = UDim.new(0, 4)
	buttonCorner.Parent = button
	
	-- Hover effect
	button.MouseEnter:Connect(function()
		TweenService:Create(button, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(90, 150, 200)}):Play()
	end)
	
	button.MouseLeave:Connect(function()
		TweenService:Create(button, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(70, 130, 180)}):Play()
	end)
	
	button.Activated:Connect(callback)
	
	return button
end

-- Create a section header
function createSection(title, parent, layoutOrder)
	local section = Instance.new("TextLabel")
	section.Size = UDim2.new(1, 0, 0, 30)
	section.BackgroundTransparency = 1
	section.Text = title
	section.TextColor3 = Color3.fromRGB(200, 200, 200)
	section.TextScaled = true
	section.Font = Enum.Font.GothamBold
	section.TextXAlignment = Enum.TextXAlignment.Left
	section.LayoutOrder = layoutOrder
	section.Parent = parent
	
	return section
end

-- Create confirmation dialog
function createConfirmationDialog(title, message, onConfirm)
	local confirmGui = Instance.new("Frame")
	confirmGui.Name = "ConfirmationDialog"
	confirmGui.Size = UDim2.new(0, 300, 0, 150)
	confirmGui.Position = UDim2.new(0.5, -150, 0.5, -75)
	confirmGui.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
	confirmGui.BorderSizePixel = 0
	
	local confirmCorner = Instance.new("UICorner")
	confirmCorner.CornerRadius = UDim.new(0, 8)
	confirmCorner.Parent = confirmGui
	
	local confirmTitle = Instance.new("TextLabel")
	confirmTitle.Size = UDim2.new(1, 0, 0, 30)
	confirmTitle.BackgroundTransparency = 1
	confirmTitle.Text = title
	confirmTitle.TextColor3 = Color3.fromRGB(255, 255, 255)
	confirmTitle.TextScaled = true
	confirmTitle.Font = Enum.Font.GothamBold
	confirmTitle.Parent = confirmGui
	
	local confirmMessage = Instance.new("TextLabel")
	confirmMessage.Size = UDim2.new(1, -20, 0, 60)
	confirmMessage.Position = UDim2.new(0, 10, 0, 35)
	confirmMessage.BackgroundTransparency = 1
	confirmMessage.Text = message
	confirmMessage.TextColor3 = Color3.fromRGB(220, 220, 220)
	confirmMessage.TextWrapped = true
	confirmMessage.Font = Enum.Font.Gotham
	confirmMessage.TextSize = 14
	confirmMessage.Parent = confirmGui
	
	local buttonFrame = Instance.new("Frame")
	buttonFrame.Size = UDim2.new(1, -20, 0, 35)
	buttonFrame.Position = UDim2.new(0, 10, 1, -45)
	buttonFrame.BackgroundTransparency = 1
	buttonFrame.Parent = confirmGui
	
	local buttonLayout = Instance.new("UIListLayout")
	buttonLayout.FillDirection = Enum.FillDirection.Horizontal
	buttonLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	buttonLayout.Padding = UDim.new(0, 10)
	buttonLayout.Parent = buttonFrame
	
	local cancelButton = createButton("Cancel", function()
		confirmGui:Destroy()
	end)
	cancelButton.Size = UDim2.new(0, 100, 1, 0)
	cancelButton.BackgroundColor3 = Color3.fromRGB(120, 120, 120)
	cancelButton.Parent = buttonFrame
	
	local confirmButton = createButton("Confirm", function()
		onConfirm()
		confirmGui:Destroy()
	end)
	confirmButton.Size = UDim2.new(0, 100, 1, 0)
	confirmButton.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
	confirmButton.Parent = buttonFrame
	
	return confirmGui
end

-- Toggle GUI visibility
function toggleGUI()
	if not gui then return end
	
	isVisible = not isVisible
	local targetPosition = isVisible and UDim2.new(0, 20, 0, 20) or UDim2.new(0, -420, 0, 20)
	
	TweenService:Create(mainFrame, TweenInfo.new(0.3, Enum.EasingStyle.Quart), {
		Position = targetPosition
	}):Play()
end

function DeveloperToolsController:KnitStart()
	-- Only create GUI for developers
	if not isDeveloper() then
		return
	end
	
	-- Get services
	self.DeveloperService = Knit.GetService("DeveloperService")
	self.TeleportService = Knit.GetService("TeleportService")
	
	-- Create the GUI
	createDeveloperGUI()
	
	-- Keyboard shortcut to toggle (configurable)
	UserInputService.InputBegan:Connect(function(input, gameProcessed)
		if gameProcessed then return end
		
		if input.KeyCode == DeveloperConfig.SETTINGS.TOGGLE_KEY then
			toggleGUI()
		end
	end)
	
	-- Show welcome message if enabled
	if DeveloperConfig.SETTINGS.SHOW_WELCOME_MESSAGE then
		StarterGui:SetCore("ChatMakeSystemMessage", {
			Text = string.format("[Developer Tools] Press %s to open developer tools.", DeveloperConfig.SETTINGS.TOGGLE_KEY.Name);
			Color = Color3.fromRGB(100, 255, 100);
			Font = Enum.Font.GothamBold;
			FontSize = Enum.FontSize.Size18;
		})
	end
end

return DeveloperToolsController
