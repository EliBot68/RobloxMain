-- PartyController.luau
-- Client-side controller for party system and UI

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SoundService = game:GetService("SoundService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local RemoteEvents = require(ReplicatedStorage.Shared.modules.RemoteEvents)

local PartyController = {}

-- UI elements
local partyGui = nil
local currentParty = nil
local inviteNotifications = {}

function PartyController:CreatePartyUI()
    -- Create main party interface
    partyGui = Instance.new("ScreenGui")
    partyGui.Name = "PartyUI"
    partyGui.ResetOnSpawn = false
    partyGui.Parent = playerGui
    
    -- Main frame
    local mainFrame = Instance.new("Frame")
    mainFrame.Name = "MainFrame"
    mainFrame.Size = UDim2.new(0, 400, 0, 500)
    mainFrame.Position = UDim2.new(0.5, -200, 0.5, -250)
    mainFrame.BackgroundColor3 = Color3.new(0.1, 0.1, 0.15)
    mainFrame.BorderSizePixel = 0
    mainFrame.Visible = false
    mainFrame.Parent = partyGui
    
    -- Add gradient
    local gradient = Instance.new("UIGradient")
    gradient.Color = ColorSequence.new{
        ColorSequenceKeypoint.new(0, Color3.new(0.15, 0.1, 0.2)),
        ColorSequenceKeypoint.new(1, Color3.new(0.1, 0.1, 0.15))
    }
    gradient.Rotation = 45
    gradient.Parent = mainFrame
    
    -- Add corner rounding
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 12)
    corner.Parent = mainFrame
    
    -- Title
    local titleLabel = Instance.new("TextLabel")
    titleLabel.Name = "TitleLabel"
    titleLabel.Size = UDim2.new(1, 0, 0, 50)
    titleLabel.Position = UDim2.new(0, 0, 0, 0)
    titleLabel.BackgroundTransparency = 1
    titleLabel.Text = "👥 PARTY SYSTEM"
    titleLabel.TextColor3 = Color3.new(1, 1, 1)
    titleLabel.TextScaled = true
    titleLabel.Font = Enum.Font.SourceSansBold
    titleLabel.TextStrokeTransparency = 0
    titleLabel.Parent = mainFrame
    
    -- Close button
    local closeButton = Instance.new("TextButton")
    closeButton.Name = "CloseButton"
    closeButton.Size = UDim2.new(0, 30, 0, 30)
    closeButton.Position = UDim2.new(1, -40, 0, 10)
    closeButton.BackgroundColor3 = Color3.new(0.8, 0.2, 0.2)
    closeButton.Text = "×"
    closeButton.TextColor3 = Color3.new(1, 1, 1)
    closeButton.TextScaled = true
    closeButton.Font = Enum.Font.SourceSansBold
    closeButton.Parent = mainFrame
    
    local closeCorner = Instance.new("UICorner")
    closeCorner.CornerRadius = UDim.new(0, 15)
    closeCorner.Parent = closeButton
    
    closeButton.MouseButton1Click:Connect(function()
        self:ClosePartyUI()
    end)
    
    -- Party status section
    local statusFrame = Instance.new("Frame")
    statusFrame.Name = "StatusFrame"
    statusFrame.Size = UDim2.new(1, -20, 0, 80)
    statusFrame.Position = UDim2.new(0, 10, 0, 60)
    statusFrame.BackgroundColor3 = Color3.new(0.2, 0.2, 0.25)
    statusFrame.BorderSizePixel = 0
    statusFrame.Parent = mainFrame
    
    local statusCorner = Instance.new("UICorner")
    statusCorner.CornerRadius = UDim.new(0, 8)
    statusCorner.Parent = statusFrame
    
    -- Status label
    local statusLabel = Instance.new("TextLabel")
    statusLabel.Name = "StatusLabel"
    statusLabel.Size = UDim2.new(1, -20, 1, 0)
    statusLabel.Position = UDim2.new(0, 10, 0, 0)
    statusLabel.BackgroundTransparency = 1
    statusLabel.Text = "Not in a party"
    statusLabel.TextColor3 = Color3.new(0.8, 0.8, 0.8)
    statusLabel.TextScaled = true
    statusLabel.Font = Enum.Font.SourceSans
    statusLabel.TextXAlignment = Enum.TextXAlignment.Left
    statusLabel.Parent = statusFrame
    
    -- Action buttons frame
    local buttonsFrame = Instance.new("Frame")
    buttonsFrame.Name = "ButtonsFrame"
    buttonsFrame.Size = UDim2.new(1, -20, 0, 120)
    buttonsFrame.Position = UDim2.new(0, 10, 0, 150)
    buttonsFrame.BackgroundTransparency = 1
    buttonsFrame.Parent = mainFrame
    
    -- Create party button
    local createButton = Instance.new("TextButton")
    createButton.Name = "CreateButton"
    createButton.Size = UDim2.new(1, 0, 0, 35)
    createButton.Position = UDim2.new(0, 0, 0, 0)
    createButton.BackgroundColor3 = Color3.new(0.2, 0.8, 0.3)
    createButton.Text = "🎉 Create Party"
    createButton.TextColor3 = Color3.new(1, 1, 1)
    createButton.TextScaled = true
    createButton.Font = Enum.Font.SourceSansBold
    createButton.Parent = buttonsFrame
    
    local createCorner = Instance.new("UICorner")
    createCorner.CornerRadius = UDim.new(0, 6)
    createCorner.Parent = createButton
    
    -- Leave party button
    local leaveButton = Instance.new("TextButton")
    leaveButton.Name = "LeaveButton"
    leaveButton.Size = UDim2.new(1, 0, 0, 35)
    leaveButton.Position = UDim2.new(0, 0, 0, 45)
    leaveButton.BackgroundColor3 = Color3.new(0.8, 0.3, 0.2)
    leaveButton.Text = "👋 Leave Party"
    leaveButton.TextColor3 = Color3.new(1, 1, 1)
    leaveButton.TextScaled = true
    leaveButton.Font = Enum.Font.SourceSans
    leaveButton.Visible = false
    leaveButton.Parent = buttonsFrame
    
    local leaveCorner = Instance.new("UICorner")
    leaveCorner.CornerRadius = UDim.new(0, 6)
    leaveCorner.Parent = leaveButton
    
    -- Invite friend button
    local inviteButton = Instance.new("TextButton")
    inviteButton.Name = "InviteButton"
    inviteButton.Size = UDim2.new(1, 0, 0, 35)
    inviteButton.Position = UDim2.new(0, 0, 0, 90)
    inviteButton.BackgroundColor3 = Color3.new(0.3, 0.6, 0.8)
    inviteButton.Text = "📧 Invite Friend"
    inviteButton.TextColor3 = Color3.new(1, 1, 1)
    inviteButton.TextScaled = true
    inviteButton.Font = Enum.Font.SourceSans
    inviteButton.Visible = false
    inviteButton.Parent = buttonsFrame
    
    local inviteCorner = Instance.new("UICorner")
    inviteCorner.CornerRadius = UDim.new(0, 6)
    inviteCorner.Parent = inviteButton
    
    -- Party members list
    local membersFrame = Instance.new("ScrollingFrame")
    membersFrame.Name = "MembersFrame"
    membersFrame.Size = UDim2.new(1, -20, 1, -290)
    membersFrame.Position = UDim2.new(0, 10, 0, 280)
    membersFrame.BackgroundColor3 = Color3.new(0.15, 0.15, 0.2)
    membersFrame.BorderSizePixel = 0
    membersFrame.ScrollBarThickness = 6
    membersFrame.Parent = mainFrame
    
    local membersCorner = Instance.new("UICorner")
    membersCorner.CornerRadius = UDim.new(0, 8)
    membersCorner.Parent = membersFrame
    
    -- Members list layout
    local listLayout = Instance.new("UIListLayout")
    listLayout.Padding = UDim.new(0, 5)
    listLayout.SortOrder = Enum.SortOrder.Name
    listLayout.Parent = membersFrame
    
    -- Button events
    createButton.MouseButton1Click:Connect(function()
        RemoteEvents.CreateParty:FireServer()
    end)
    
    leaveButton.MouseButton1Click:Connect(function()
        RemoteEvents.LeaveParty:FireServer()
    end)
    
    inviteButton.MouseButton1Click:Connect(function()
        self:ShowFriendsList()
    end)
    
    return mainFrame
end

function PartyController:UpdatePartyDisplay(party)
    if not partyGui then return end
    
    currentParty = party
    local mainFrame = partyGui.MainFrame
    local statusLabel = mainFrame.StatusFrame.StatusLabel
    local buttonsFrame = mainFrame.ButtonsFrame
    local membersFrame = mainFrame.MembersFrame
    
    if party then
        -- Update status
        local isLeader = party.leader == tostring(player.UserId)
        statusLabel.Text = string.format("Party: %d/%d members%s", 
            #party.members, 4, isLeader and " (Leader)" or "")
        statusLabel.TextColor3 = Color3.new(0.2, 0.8, 0.3)
        
        -- Show/hide buttons
        buttonsFrame.CreateButton.Visible = false
        buttonsFrame.LeaveButton.Visible = true
        buttonsFrame.InviteButton.Visible = isLeader
        
        -- Update members list
        self:UpdateMembersList(party, membersFrame)
        
        -- Show XP bonus info
        local xpBonusLabel = mainFrame:FindFirstChild("XpBonusLabel")
        if not xpBonusLabel then
            xpBonusLabel = Instance.new("TextLabel")
            xpBonusLabel.Name = "XpBonusLabel"
            xpBonusLabel.Size = UDim2.new(1, -20, 0, 20)
            xpBonusLabel.Position = UDim2.new(0, 10, 0, 250)
            xpBonusLabel.BackgroundTransparency = 1
            xpBonusLabel.TextColor3 = Color3.new(1, 0.8, 0.2)
            xpBonusLabel.TextScaled = true
            xpBonusLabel.Font = Enum.Font.SourceSansItalic
            xpBonusLabel.Parent = mainFrame
        end
        xpBonusLabel.Text = "✨ +25% XP Bonus when playing together!"
        xpBonusLabel.Visible = true
        
    else
        -- No party
        statusLabel.Text = "Not in a party"
        statusLabel.TextColor3 = Color3.new(0.8, 0.8, 0.8)
        
        -- Show/hide buttons
        buttonsFrame.CreateButton.Visible = true
        buttonsFrame.LeaveButton.Visible = false
        buttonsFrame.InviteButton.Visible = false
        
        -- Clear members list
        for _, child in pairs(membersFrame:GetChildren()) do
            if child:IsA("Frame") then
                child:Destroy()
            end
        end
        
        -- Hide XP bonus info
        local xpBonusLabel = mainFrame:FindFirstChild("XpBonusLabel")
        if xpBonusLabel then
            xpBonusLabel.Visible = false
        end
    end
end

function PartyController:UpdateMembersList(party, membersFrame)
    -- Clear existing members
    for _, child in pairs(membersFrame:GetChildren()) do
        if child:IsA("Frame") then
            child:Destroy()
        end
    end
    
    -- Add current members
    for i, memberId in pairs(party.members) do
        local member = Players:GetPlayerByUserId(tonumber(memberId))
        if member then
            local memberFrame = Instance.new("Frame")
            memberFrame.Name = "Member_" .. memberId
            memberFrame.Size = UDim2.new(1, -10, 0, 40)
            memberFrame.BackgroundColor3 = Color3.new(0.2, 0.2, 0.25)
            memberFrame.BorderSizePixel = 0
            memberFrame.Parent = membersFrame
            
            local memberCorner = Instance.new("UICorner")
            memberCorner.CornerRadius = UDim.new(0, 6)
            memberCorner.Parent = memberFrame
            
            -- Member name
            local nameLabel = Instance.new("TextLabel")
            nameLabel.Size = UDim2.new(1, -50, 1, 0)
            nameLabel.Position = UDim2.new(0, 10, 0, 0)
            nameLabel.BackgroundTransparency = 1
            nameLabel.Text = member.Name .. (party.leader == memberId and " 👑" or "")
            nameLabel.TextColor3 = party.leader == memberId and Color3.new(1, 0.8, 0.2) or Color3.new(1, 1, 1)
            nameLabel.TextScaled = true
            nameLabel.Font = Enum.Font.SourceSans
            nameLabel.TextXAlignment = Enum.TextXAlignment.Left
            nameLabel.Parent = memberFrame
            
            -- Status indicator
            local statusDot = Instance.new("Frame")
            statusDot.Size = UDim2.new(0, 12, 0, 12)
            statusDot.Position = UDim2.new(1, -25, 0.5, -6)
            statusDot.BackgroundColor3 = Color3.new(0.2, 0.8, 0.3) -- Online
            statusDot.BorderSizePixel = 0
            statusDot.Parent = memberFrame
            
            local dotCorner = Instance.new("UICorner")
            dotCorner.CornerRadius = UDim.new(0, 6)
            dotCorner.Parent = statusDot
        end
    end
    
    -- Update canvas size
    membersFrame.CanvasSize = UDim2.new(0, 0, 0, #party.members * 45)
end

function PartyController:ShowFriendsList()
    -- Create friends selection UI
    local friendsGui = Instance.new("ScreenGui")
    friendsGui.Name = "FriendsSelection"
    friendsGui.Parent = playerGui
    
    -- Background overlay
    local overlay = Instance.new("Frame")
    overlay.Size = UDim2.new(1, 0, 1, 0)
    overlay.BackgroundColor3 = Color3.new(0, 0, 0)
    overlay.BackgroundTransparency = 0.5
    overlay.BorderSizePixel = 0
    overlay.Parent = friendsGui
    
    -- Friends frame
    local friendsFrame = Instance.new("Frame")
    friendsFrame.Size = UDim2.new(0, 300, 0, 400)
    friendsFrame.Position = UDim2.new(0.5, -150, 0.5, -200)
    friendsFrame.BackgroundColor3 = Color3.new(0.1, 0.1, 0.15)
    friendsFrame.BorderSizePixel = 0
    friendsFrame.Parent = friendsGui
    
    local friendsCorner = Instance.new("UICorner")
    friendsCorner.CornerRadius = UDim.new(0, 12)
    friendsCorner.Parent = friendsFrame
    
    -- Title
    local titleLabel = Instance.new("TextLabel")
    titleLabel.Size = UDim2.new(1, 0, 0, 40)
    titleLabel.BackgroundTransparency = 1
    titleLabel.Text = "👥 Invite Friends"
    titleLabel.TextColor3 = Color3.new(1, 1, 1)
    titleLabel.TextScaled = true
    titleLabel.Font = Enum.Font.SourceSansBold
    titleLabel.Parent = friendsFrame
    
    -- Close button
    local closeButton = Instance.new("TextButton")
    closeButton.Size = UDim2.new(0, 30, 0, 30)
    closeButton.Position = UDim2.new(1, -35, 0, 5)
    closeButton.BackgroundColor3 = Color3.new(0.8, 0.2, 0.2)
    closeButton.Text = "×"
    closeButton.TextColor3 = Color3.new(1, 1, 1)
    closeButton.TextScaled = true
    closeButton.Font = Enum.Font.SourceSansBold
    closeButton.Parent = friendsFrame
    
    local closeCorner2 = Instance.new("UICorner")
    closeCorner2.CornerRadius = UDim.new(0, 15)
    closeCorner2.Parent = closeButton
    
    -- Friends list
    local friendsList = Instance.new("ScrollingFrame")
    friendsList.Size = UDim2.new(1, -20, 1, -60)
    friendsList.Position = UDim2.new(0, 10, 0, 50)
    friendsList.BackgroundColor3 = Color3.new(0.15, 0.15, 0.2)
    friendsList.BorderSizePixel = 0
    friendsList.ScrollBarThickness = 6
    friendsList.Parent = friendsFrame
    
    local friendsListCorner = Instance.new("UICorner")
    friendsListCorner.CornerRadius = UDim.new(0, 8)
    friendsListCorner.Parent = friendsList
    
    local friendsLayout = Instance.new("UIListLayout")
    friendsLayout.Padding = UDim.new(0, 5)
    friendsLayout.Parent = friendsList
    
    -- Add online players as potential invites
    for _, otherPlayer in pairs(Players:GetPlayers()) do
        if otherPlayer ~= player then
            local friendFrame = Instance.new("Frame")
            friendFrame.Size = UDim2.new(1, -10, 0, 35)
            friendFrame.BackgroundColor3 = Color3.new(0.2, 0.2, 0.25)
            friendFrame.BorderSizePixel = 0
            friendFrame.Parent = friendsList
            
            local friendFrameCorner = Instance.new("UICorner")
            friendFrameCorner.CornerRadius = UDim.new(0, 6)
            friendFrameCorner.Parent = friendFrame
            
            local nameLabel = Instance.new("TextLabel")
            nameLabel.Size = UDim2.new(1, -80, 1, 0)
            nameLabel.Position = UDim2.new(0, 10, 0, 0)
            nameLabel.BackgroundTransparency = 1
            nameLabel.Text = otherPlayer.Name
            nameLabel.TextColor3 = Color3.new(1, 1, 1)
            nameLabel.TextScaled = true
            nameLabel.Font = Enum.Font.SourceSans
            nameLabel.TextXAlignment = Enum.TextXAlignment.Left
            nameLabel.Parent = friendFrame
            
            local inviteBtn = Instance.new("TextButton")
            inviteBtn.Size = UDim2.new(0, 60, 0, 25)
            inviteBtn.Position = UDim2.new(1, -70, 0.5, -12.5)
            inviteBtn.BackgroundColor3 = Color3.new(0.3, 0.6, 0.8)
            inviteBtn.Text = "Invite"
            inviteBtn.TextColor3 = Color3.new(1, 1, 1)
            inviteBtn.TextScaled = true
            inviteBtn.Font = Enum.Font.SourceSans
            inviteBtn.Parent = friendFrame
            
            local inviteBtnCorner = Instance.new("UICorner")
            inviteBtnCorner.CornerRadius = UDim.new(0, 4)
            inviteBtnCorner.Parent = inviteBtn
            
            inviteBtn.MouseButton1Click:Connect(function()
                RemoteEvents.SendPartyInvite:FireServer(otherPlayer.UserId)
                friendsGui:Destroy()
            end)
        end
    end
    
    friendsList.CanvasSize = UDim2.new(0, 0, 0, (#Players:GetPlayers() - 1) * 40)
    
    -- Close events
    closeButton.MouseButton1Click:Connect(function()
        friendsGui:Destroy()
    end)
    
    overlay.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            friendsGui:Destroy()
        end
    end)
end

function PartyController:ShowInviteNotification(inviteData)
    -- Create invite notification
    local notificationGui = Instance.new("ScreenGui")
    notificationGui.Name = "PartyInvite"
    notificationGui.Parent = playerGui
    
    local notification = Instance.new("Frame")
    notification.Size = UDim2.new(0, 300, 0, 120)
    notification.Position = UDim2.new(1, 310, 0, 100 + (#inviteNotifications * 130))
    notification.BackgroundColor3 = Color3.new(0.1, 0.1, 0.15)
    notification.BorderSizePixel = 0
    notification.Parent = notificationGui
    
    local notifCorner = Instance.new("UICorner")
    notifCorner.CornerRadius = UDim.new(0, 10)
    notifCorner.Parent = notification
    
    -- Invite text
    local inviteLabel = Instance.new("TextLabel")
    inviteLabel.Size = UDim2.new(1, -20, 0, 60)
    inviteLabel.Position = UDim2.new(0, 10, 0, 10)
    inviteLabel.BackgroundTransparency = 1
    inviteLabel.Text = "👥 " .. inviteData.inviterName .. " invited you to their party!\n(" .. inviteData.partySize .. "/" .. inviteData.maxSize .. " members)"
    inviteLabel.TextColor3 = Color3.new(1, 1, 1)
    inviteLabel.TextScaled = true
    inviteLabel.Font = Enum.Font.SourceSans
    inviteLabel.TextWrapped = true
    inviteLabel.Parent = notification
    
    -- Accept button
    local acceptButton = Instance.new("TextButton")
    acceptButton.Size = UDim2.new(0, 80, 0, 30)
    acceptButton.Position = UDim2.new(0, 20, 1, -40)
    acceptButton.BackgroundColor3 = Color3.new(0.2, 0.8, 0.3)
    acceptButton.Text = "Accept"
    acceptButton.TextColor3 = Color3.new(1, 1, 1)
    acceptButton.TextScaled = true
    acceptButton.Font = Enum.Font.SourceSansBold
    acceptButton.Parent = notification
    
    -- Decline button
    local declineButton = Instance.new("TextButton")
    declineButton.Size = UDim2.new(0, 80, 0, 30)
    declineButton.Position = UDim2.new(1, -100, 1, -40)
    declineButton.BackgroundColor3 = Color3.new(0.8, 0.3, 0.2)
    declineButton.Text = "Decline"
    declineButton.TextColor3 = Color3.new(1, 1, 1)
    declineButton.TextScaled = true
    declineButton.Font = Enum.Font.SourceSans
    declineButton.Parent = notification
    
    -- Button corners
    local acceptCorner = Instance.new("UICorner")
    acceptCorner.CornerRadius = UDim.new(0, 6)
    acceptCorner.Parent = acceptButton
    
    local declineCorner = Instance.new("UICorner")
    declineCorner.CornerRadius = UDim.new(0, 6)
    declineCorner.Parent = declineButton
    
    -- Slide in animation
    local slideIn = TweenService:Create(
        notification,
        TweenInfo.new(0.5, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
        {Position = UDim2.new(1, -310, 0, 100 + (#inviteNotifications * 130))}
    )
    slideIn:Play()
    
    -- Button events
    acceptButton.MouseButton1Click:Connect(function()
        RemoteEvents.AcceptPartyInvite:FireServer(inviteData.inviterId)
        notificationGui:Destroy()
        
        -- Remove from tracking
        for i, notif in pairs(inviteNotifications) do
            if notif == notificationGui then
                table.remove(inviteNotifications, i)
                break
            end
        end
    end)
    
    declineButton.MouseButton1Click:Connect(function()
        RemoteEvents.DeclinePartyInvite:FireServer(inviteData.inviterId)
        notificationGui:Destroy()
        
        -- Remove from tracking
        for i, notif in pairs(inviteNotifications) do
            if notif == notificationGui then
                table.remove(inviteNotifications, i)
                break
            end
        end
    end)
    
    -- Auto-expire after 60 seconds
    spawn(function()
        wait(60)
        if notificationGui.Parent then
            local slideOut = TweenService:Create(
                notification,
                TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
                {Position = UDim2.new(1, 310, 0, notification.Position.Y.Offset)}
            )
            slideOut:Play()
            slideOut.Completed:Connect(function()
                notificationGui:Destroy()
            end)
        end
    end)
    
    table.insert(inviteNotifications, notificationGui)
end

function PartyController:ShowXpBonus(bonusXp, partySize)
    -- Show XP bonus notification
    local bonusGui = Instance.new("ScreenGui")
    bonusGui.Name = "PartyXpBonus"
    bonusGui.Parent = playerGui
    
    local bonusFrame = Instance.new("Frame")
    bonusFrame.Size = UDim2.new(0, 300, 0, 80)
    bonusFrame.Position = UDim2.new(0.5, -150, 0.2, 0)
    bonusFrame.BackgroundColor3 = Color3.new(0.2, 0.8, 0.3)
    bonusFrame.BorderSizePixel = 0
    bonusFrame.Parent = bonusGui
    
    local bonusCorner = Instance.new("UICorner")
    bonusCorner.CornerRadius = UDim.new(0, 12)
    bonusCorner.Parent = bonusFrame
    
    local bonusLabel = Instance.new("TextLabel")
    bonusLabel.Size = UDim2.new(1, -20, 1, -20)
    bonusLabel.Position = UDim2.new(0, 10, 0, 10)
    bonusLabel.BackgroundTransparency = 1
    bonusLabel.Text = "🎉 PARTY BONUS!\n+" .. bonusXp .. " XP (Party of " .. partySize .. ")"
    bonusLabel.TextColor3 = Color3.new(1, 1, 1)
    bonusLabel.TextScaled = true
    bonusLabel.Font = Enum.Font.SourceSansBold
    bonusLabel.TextStrokeTransparency = 0
    bonusLabel.Parent = bonusFrame
    
    -- Slide in and fade out
    bonusFrame.Position = UDim2.new(0.5, -150, -0.2, 0)
    local slideIn = TweenService:Create(
        bonusFrame,
        TweenInfo.new(0.5, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
        {Position = UDim2.new(0.5, -150, 0.2, 0)}
    )
    slideIn:Play()
    
    spawn(function()
        wait(3)
        local slideOut = TweenService:Create(
            bonusFrame,
            TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
            {Position = UDim2.new(0.5, -150, -0.2, 0)}
        )
        slideOut:Play()
        slideOut.Completed:Connect(function()
            bonusGui:Destroy()
        end)
    end)
end

function PartyController:OpenPartyUI()
    if not partyGui then
        self:CreatePartyUI()
    end
    
    local mainFrame = partyGui.MainFrame
    mainFrame.Visible = true
    
    -- Slide in animation
    mainFrame.Position = UDim2.new(0.5, -200, 1, 0)
    local slideIn = TweenService:Create(
        mainFrame,
        TweenInfo.new(0.5, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
        {Position = UDim2.new(0.5, -200, 0.5, -250)}
    )
    slideIn:Play()
    
    -- Request current party data
    RemoteEvents.GetPlayerParty:FireServer()
end

function PartyController:ClosePartyUI()
    if not partyGui then return end
    
    local mainFrame = partyGui.MainFrame
    local slideOut = TweenService:Create(
        mainFrame,
        TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
        {Position = UDim2.new(0.5, -200, 1, 0)}
    )
    slideOut:Play()
    slideOut.Completed:Connect(function()
        mainFrame.Visible = false
    end)
end

function PartyController:Initialize()
    print("👥 PartyController initializing...")
    
    print("✅ PartyController initialized!")
end

-- Remote event connections
RemoteEvents.ShowPartyUI.OnClientEvent:Connect(function()
    PartyController:OpenPartyUI()
end)

RemoteEvents.PartyCreated.OnClientEvent:Connect(function(partyId, party)
    PartyController:UpdatePartyDisplay(party)
end)

RemoteEvents.PartyMemberJoined.OnClientEvent:Connect(function(memberName, party)
    PartyController:UpdatePartyDisplay(party)
end)

RemoteEvents.PartyMemberLeft.OnClientEvent:Connect(function(memberName, party)
    PartyController:UpdatePartyDisplay(party)
end)

RemoteEvents.PartyLeft.OnClientEvent:Connect(function(reason)
    PartyController:UpdatePartyDisplay(nil)
end)

RemoteEvents.PartyDisbanded.OnClientEvent:Connect(function()
    PartyController:UpdatePartyDisplay(nil)
end)

RemoteEvents.PartyInviteReceived.OnClientEvent:Connect(function(inviteData)
    PartyController:ShowInviteNotification(inviteData)
end)

RemoteEvents.PartyXpBonus.OnClientEvent:Connect(function(bonusXp, partySize)
    PartyController:ShowXpBonus(bonusXp, partySize)
end)

RemoteEvents.PlayerPartyData.OnClientEvent:Connect(function(party)
    PartyController:UpdatePartyDisplay(party)
end)

-- Auto-initialize
PartyController:Initialize()

return PartyController
