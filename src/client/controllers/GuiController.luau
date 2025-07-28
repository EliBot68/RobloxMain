-- GuiController.luau
-- Manages client-side UI interactions

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local GuiController = {}

function GuiController:CreateTween(object, info, properties)
    local tweenInfo = TweenInfo.new(
        info.duration or 0.5,
        info.easingStyle or Enum.EasingStyle.Quad,
        info.easingDirection or Enum.EasingDirection.Out
    )
    
    local tween = TweenService:Create(object, tweenInfo, properties)
    return tween
end

function GuiController:FadeIn(gui)
    gui.Visible = true
    local tween = self:CreateTween(gui, {duration = 0.3}, {BackgroundTransparency = 0})
    tween:Play()
end

function GuiController:FadeOut(gui)
    local tween = self:CreateTween(gui, {duration = 0.3}, {BackgroundTransparency = 1})
    tween:Play()
    tween.Completed:Connect(function()
        gui.Visible = false
    end)
end

function GuiController:Init()
    print("GuiController initialized")
end

return GuiController
