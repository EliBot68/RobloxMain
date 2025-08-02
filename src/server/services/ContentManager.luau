-- ContentManager.luau
-- Dynamic content management system for easy updates and seasonal content

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local HttpService = game:GetService("HttpService")
local RunService = game:GetService("RunService")

local DataService = require(script.Parent.DataService)
local RemoteEvents = ReplicatedStorage:WaitForChild("RemoteEvents")

local ContentManager = {}

-- Content Version Management
local CONTENT_VERSION = "1.0.0"
local CONTENT_CONFIG = {
    enableAutoUpdates = true,
    updateCheckInterval = 300, -- 5 minutes
    backupOldContent = true,
    allowHotSwap = true
}

-- Active Content Registry
local activeContent = {
    events = {},
    trails = {},
    pets = {},
    cosmetics = {},
    seasonalItems = {},
    leaderboardConfig = {},
    gameSettings = {}
}

-- Content Categories and Templates
local CONTENT_TEMPLATES = {
    event = {
        id = "",
        name = "",
        description = "",
        startDate = 0,
        endDate = 0,
        type = "standard", -- standard, seasonal, special
        rewards = {},
        requirements = {},
        enabled = true,
        icon = "🎉",
        bannerColor = Color3.fromRGB(255, 215, 0)
    },
    
    trail = {
        id = "",
        name = "",
        description = "",
        rarity = "common", -- common, rare, epic, legendary
        unlockMethod = "shop", -- shop, event, goal, gamepass
        price = 0,
        effects = {},
        colors = {},
        animation = "default",
        enabled = true,
        icon = "✨"
    },
    
    pet = {
        id = "",
        name = "",
        description = "",
        rarity = "common",
        unlockMethod = "shop",
        price = 0,
        abilities = {},
        model = "",
        animations = {},
        sounds = {},
        enabled = true,
        icon = "🐾"
    },
    
    cosmetic = {
        id = "",
        name = "",
        description = "",
        type = "hat", -- hat, emote, badge, aura
        rarity = "common",
        unlockMethod = "shop",
        price = 0,
        model = "",
        effects = {},
        enabled = true,
        icon = "👑"
    },
    
    seasonalContent = {
        id = "",
        name = "",
        season = "spring", -- spring, summer, fall, winter, holiday
        startDate = 0,
        endDate = 0,
        items = {},
        events = {},
        decorations = {},
        music = "",
        enabled = true,
        icon = "🌸"
    },
    
    leaderboardReset = {
        id = "",
        name = "",
        resetDate = 0,
        type = "weekly", -- daily, weekly, monthly, seasonal
        preserveData = true,
        rewards = {},
        notification = "",
        enabled = true
    }
}

function ContentManager:Init()
    -- Initialize content management system
    self:LoadActiveContent()
    self:SetupRemoteEvents()
    self:StartUpdateChecker()
    self:SetupPlayerConnections()
    
    print("📦 ContentManager initialized - Dynamic content system active")
end

function ContentManager:SetupRemoteEvents()
    -- Create remote events for content management
    if not RemoteEvents:FindFirstChild("ContentUpdate") then
        local contentUpdateEvent = Instance.new("RemoteEvent")
        contentUpdateEvent.Name = "ContentUpdate"
        contentUpdateEvent.Parent = RemoteEvents
    end
    
    if not RemoteEvents:FindFirstChild("GetActiveContent") then
        local getContentFunction = Instance.new("RemoteFunction")
        getContentFunction.Name = "GetActiveContent"
        getContentFunction.Parent = RemoteEvents
    end
    
    if not RemoteEvents:FindFirstChild("AdminContentUpdate") then
        local adminUpdateEvent = Instance.new("RemoteEvent")
        adminUpdateEvent.Name = "AdminContentUpdate"
        adminUpdateEvent.Parent = RemoteEvents
    end
    
    -- Handle content requests
    RemoteEvents.GetActiveContent.OnServerInvoke = function(player, contentType)
        return self:GetActiveContent(contentType)
    end
    
    -- Handle admin content updates (for authorized users)
    RemoteEvents.AdminContentUpdate.OnServerEvent:Connect(function(player, action, contentType, contentData)
        if self:IsAuthorizedUser(player) then
            self:HandleAdminContentUpdate(action, contentType, contentData)
        end
    end)
end

function ContentManager:LoadActiveContent()
    -- Load current active content from configuration
    -- This would typically load from DataStore or external configuration
    
    -- Sample Event Content
    self:RegisterEvent({
        id = "spring_festival_2025",
        name = "Spring Festival",
        description = "Celebrate spring with exclusive rewards!",
        startDate = os.time(),
        endDate = os.time() + (7 * 24 * 60 * 60), -- 7 days
        type = "seasonal",
        rewards = {
            {type = "trail", id = "cherry_blossom_trail", name = "Cherry Blossom Trail"},
            {type = "pet", id = "spring_butterfly", name = "Spring Butterfly"},
            {type = "cosmetic", id = "flower_crown", name = "Flower Crown"}
        },
        requirements = {
            {type = "games_played", amount = 10},
            {type = "coins_earned", amount = 1000}
        },
        enabled = true,
        icon = "🌸",
        bannerColor = Color3.fromRGB(255, 182, 193)
    })
    
    -- Sample Trail Content
    self:RegisterTrail({
        id = "rainbow_sparkle",
        name = "Rainbow Sparkle Trail",
        description = "A dazzling rainbow trail with sparkle effects",
        rarity = "epic",
        unlockMethod = "shop",
        price = 2500,
        effects = {"rainbow", "sparkle", "glow"},
        colors = {
            Color3.fromRGB(255, 0, 0),
            Color3.fromRGB(255, 165, 0),
            Color3.fromRGB(255, 255, 0),
            Color3.fromRGB(0, 255, 0),
            Color3.fromRGB(0, 0, 255),
            Color3.fromRGB(75, 0, 130),
            Color3.fromRGB(238, 130, 238)
        },
        animation = "wave",
        enabled = true,
        icon = "🌈"
    })
    
    -- Sample Pet Content
    self:RegisterPet({
        id = "cosmic_dragon",
        name = "Cosmic Dragon",
        description = "A mystical dragon from the cosmic realm",
        rarity = "legendary",
        unlockMethod = "event",
        price = 0,
        abilities = {
            {name = "Coin Magnet", description = "Attracts coins from greater distance"},
            {name = "Star Dust", description = "Leaves a trail of star particles"}
        },
        model = "CosmicDragonModel",
        animations = {"idle", "fly", "celebrate"},
        sounds = {"roar", "purr", "magic"},
        enabled = true,
        icon = "🐉"
    })
    
    -- Sample Seasonal Content
    self:RegisterSeasonalContent({
        id = "summer_beach_theme",
        name = "Summer Beach Paradise",
        season = "summer",
        startDate = os.time(),
        endDate = os.time() + (30 * 24 * 60 * 60), -- 30 days
        items = {
            {type = "cosmetic", id = "beach_hat", name = "Beach Sun Hat"},
            {type = "trail", id = "wave_trail", name = "Ocean Wave Trail"},
            {type = "pet", id = "beach_crab", name = "Surfing Crab"}
        },
        events = {"daily_surf_challenge", "beach_volleyball_tournament"},
        decorations = {"palm_trees", "beach_balls", "surfboards"},
        music = "tropical_beats.mp3",
        enabled = true,
        icon = "🏖️"
    })
    
    print("📦 Active content loaded: " .. self:GetContentStats())
end

function ContentManager:RegisterEvent(eventData)
    -- Register a new event
    local event = self:ValidateContent(eventData, "event")
    if event then
        activeContent.events[event.id] = event
        self:NotifyContentUpdate("event_added", event)
        return true
    end
    return false
end

function ContentManager:RegisterTrail(trailData)
    -- Register a new trail
    local trail = self:ValidateContent(trailData, "trail")
    if trail then
        activeContent.trails[trail.id] = trail
        self:NotifyContentUpdate("trail_added", trail)
        return true
    end
    return false
end

function ContentManager:RegisterPet(petData)
    -- Register a new pet
    local pet = self:ValidateContent(petData, "pet")
    if pet then
        activeContent.pets[pet.id] = pet
        self:NotifyContentUpdate("pet_added", pet)
        return true
    end
    return false
end

function ContentManager:RegisterCosmetic(cosmeticData)
    -- Register a new cosmetic
    local cosmetic = self:ValidateContent(cosmeticData, "cosmetic")
    if cosmetic then
        activeContent.cosmetics[cosmetic.id] = cosmetic
        self:NotifyContentUpdate("cosmetic_added", cosmetic)
        return true
    end
    return false
end

function ContentManager:RegisterSeasonalContent(seasonalData)
    -- Register seasonal content
    local seasonal = self:ValidateContent(seasonalData, "seasonalContent")
    if seasonal then
        activeContent.seasonalItems[seasonal.id] = seasonal
        self:NotifyContentUpdate("seasonal_added", seasonal)
        return true
    end
    return false
end

function ContentManager:ValidateContent(data, contentType)
    -- Validate content against template
    local template = CONTENT_TEMPLATES[contentType]
    if not template then
        warn("Invalid content type: " .. contentType)
        return nil
    end
    
    -- Ensure required fields exist
    if not data.id or data.id == "" then
        warn("Content missing required ID")
        return nil
    end
    
    if not data.name or data.name == "" then
        warn("Content missing required name")
        return nil
    end
    
    -- Merge with template defaults
    local validatedContent = {}
    for key, defaultValue in pairs(template) do
        validatedContent[key] = data[key] ~= nil and data[key] or defaultValue
    end
    
    -- Add metadata
    validatedContent.dateAdded = os.time()
    validatedContent.version = CONTENT_VERSION
    
    return validatedContent
end

function ContentManager:GetActiveContent(contentType)
    -- Get active content by type
    if contentType then
        return activeContent[contentType] or {}
    else
        return activeContent
    end
end

function ContentManager:UpdateContent(contentType, contentId, updates)
    -- Update existing content
    if activeContent[contentType] and activeContent[contentType][contentId] then
        for key, value in pairs(updates) do
            activeContent[contentType][contentId][key] = value
        end
        
        activeContent[contentType][contentId].lastUpdated = os.time()
        self:NotifyContentUpdate("content_updated", {
            type = contentType,
            id = contentId,
            updates = updates
        })
        
        return true
    end
    return false
end

function ContentManager:RemoveContent(contentType, contentId)
    -- Remove content (disable rather than delete for safety)
    if activeContent[contentType] and activeContent[contentType][contentId] then
        activeContent[contentType][contentId].enabled = false
        activeContent[contentType][contentId].removedDate = os.time()
        
        self:NotifyContentUpdate("content_removed", {
            type = contentType,
            id = contentId
        })
        
        return true
    end
    return false
end

function ContentManager:SwapContent(oldContentId, newContentData, contentType)
    -- Hot-swap content for seamless updates
    if CONTENT_CONFIG.allowHotSwap then
        -- Backup old content if enabled
        if CONTENT_CONFIG.backupOldContent then
            self:BackupContent(contentType, oldContentId)
        end
        
        -- Remove old content
        self:RemoveContent(contentType, oldContentId)
        
        -- Add new content
        local success = false
        if contentType == "events" then
            success = self:RegisterEvent(newContentData)
        elseif contentType == "trails" then
            success = self:RegisterTrail(newContentData)
        elseif contentType == "pets" then
            success = self:RegisterPet(newContentData)
        elseif contentType == "cosmetics" then
            success = self:RegisterCosmetic(newContentData)
        elseif contentType == "seasonalItems" then
            success = self:RegisterSeasonalContent(newContentData)
        end
        
        if success then
            self:NotifyContentUpdate("content_swapped", {
                oldId = oldContentId,
                newContent = newContentData,
                type = contentType
            })
        end
        
        return success
    end
    return false
end

function ContentManager:ScheduleLeaderboardReset(resetConfig)
    -- Schedule a leaderboard reset
    local resetData = self:ValidateContent(resetConfig, "leaderboardReset")
    if resetData then
        -- Schedule the reset
        spawn(function()
            local timeUntilReset = resetData.resetDate - os.time()
            if timeUntilReset > 0 then
                wait(timeUntilReset)
                self:ExecuteLeaderboardReset(resetData)
            end
        end)
        
        return true
    end
    return false
end

function ContentManager:ExecuteLeaderboardReset(resetData)
    -- Execute leaderboard reset
    local LeaderboardService = require(script.Parent.LeaderboardService)
    
    if resetData.preserveData then
        -- Archive current leaderboard data
        LeaderboardService:ArchiveCurrentLeaderboard(resetData.name)
    end
    
    -- Reset leaderboard
    LeaderboardService:ResetLeaderboard()
    
    -- Distribute rewards if any
    if resetData.rewards and #resetData.rewards > 0 then
        LeaderboardService:DistributeResetRewards(resetData.rewards)
    end
    
    -- Notify players
    if resetData.notification and resetData.notification ~= "" then
        self:BroadcastNotification(resetData.notification, "leaderboard_reset")
    end
    
    print("📊 Leaderboard reset executed: " .. resetData.name)
end

function ContentManager:NotifyContentUpdate(updateType, data)
    -- Notify all clients of content updates
    RemoteEvents.ContentUpdate:FireAllClients(updateType, data)
    
    print("📦 Content update broadcasted: " .. updateType)
end

function ContentManager:BroadcastNotification(message, notificationType)
    -- Send notification to all players
    for _, player in pairs(Players:GetPlayers()) do
        RemoteEvents.ContentUpdate:FireClient(player, "notification", {
            message = message,
            type = notificationType or "info",
            duration = 5
        })
    end
end

function ContentManager:StartUpdateChecker()
    -- Event-driven content update checker
    if CONTENT_CONFIG.enableAutoUpdates then
        local updateCheckerEvent = Instance.new("BindableEvent")
        
        local function scheduleUpdateCheck()
            wait(CONTENT_CONFIG.updateCheckInterval)
            updateCheckerEvent:Fire()
        end
        
        updateCheckerEvent.Event:Connect(function()
            self:CheckForContentUpdates()
            spawn(scheduleUpdateCheck)
        end)
        
        -- Start the update checking cycle
        spawn(scheduleUpdateCheck)
    end
end

function ContentManager:CheckForContentUpdates()
    -- Check for expired content and auto-updates
    local currentTime = os.time()
    
    -- Check events for expiration
    for eventId, event in pairs(activeContent.events) do
        if event.enabled and event.endDate > 0 and currentTime > event.endDate then
            event.enabled = false
            self:NotifyContentUpdate("event_expired", event)
            print("⏰ Event expired: " .. event.name)
        end
    end
    
    -- Check seasonal content
    for seasonalId, seasonal in pairs(activeContent.seasonalItems) do
        if seasonal.enabled and seasonal.endDate > 0 and currentTime > seasonal.endDate then
            seasonal.enabled = false
            self:NotifyContentUpdate("seasonal_expired", seasonal)
            print("🍂 Seasonal content expired: " .. seasonal.name)
        end
    end
end

function ContentManager:SetupPlayerConnections()
    -- Handle player joining for content sync (NO POLLING)
    Players.PlayerAdded:Connect(function(player)
        task.delay(2, function() -- Non-blocking player load wait
            -- Send all active content to new player
            RemoteEvents.ContentUpdate:FireClient(player, "full_sync", activeContent)
        end)
    end)
end

function ContentManager:BackupContent(contentType, contentId)
    -- Backup content before modification
    if activeContent[contentType] and activeContent[contentType][contentId] then
        local backupData = activeContent[contentType][contentId]
        -- In production, this would save to DataStore or external storage
        print("💾 Content backed up: " .. contentType .. "/" .. contentId)
    end
end

function ContentManager:GetContentStats()
    -- Get content statistics
    local stats = {}
    for contentType, content in pairs(activeContent) do
        local enabledCount = 0
        local totalCount = 0
        
        for _, item in pairs(content) do
            totalCount = totalCount + 1
            if item.enabled then
                enabledCount = enabledCount + 1
            end
        end
        
        stats[contentType] = {
            total = totalCount,
            enabled = enabledCount
        }
    end
    
    return HttpService:JSONEncode(stats)
end

function ContentManager:IsAuthorizedUser(player)
    -- Check if player has content management permissions
    -- This would integrate with your admin system
    return player.Name == "YourUsername" or player:GetRankInGroup(0) >= 100 -- Example check
end

function ContentManager:HandleAdminContentUpdate(action, contentType, contentData)
    -- Handle admin content updates
    if action == "add" then
        if contentType == "events" then
            self:RegisterEvent(contentData)
        elseif contentType == "trails" then
            self:RegisterTrail(contentData)
        elseif contentType == "pets" then
            self:RegisterPet(contentData)
        elseif contentType == "cosmetics" then
            self:RegisterCosmetic(contentData)
        elseif contentType == "seasonal" then
            self:RegisterSeasonalContent(contentData)
        end
    elseif action == "update" then
        self:UpdateContent(contentType, contentData.id, contentData.updates)
    elseif action == "remove" then
        self:RemoveContent(contentType, contentData.id)
    elseif action == "swap" then
        self:SwapContent(contentData.oldId, contentData.newContent, contentType)
    end
end

-- Quick Content Management Functions for Easy Updates

function ContentManager:QuickAddEvent(name, description, durationDays, rewards)
    -- Quick event creation
    return self:RegisterEvent({
        id = string.lower(name):gsub("%s+", "_") .. "_" .. os.time(),
        name = name,
        description = description,
        startDate = os.time(),
        endDate = os.time() + (durationDays * 24 * 60 * 60),
        type = "special",
        rewards = rewards or {},
        requirements = {{type = "games_played", amount = 5}},
        enabled = true,
        icon = "🎉"
    })
end

function ContentManager:QuickAddTrail(name, description, price, rarity, colors)
    -- Quick trail creation
    return self:RegisterTrail({
        id = string.lower(name):gsub("%s+", "_"),
        name = name,
        description = description,
        rarity = rarity or "common",
        unlockMethod = "shop",
        price = price or 1000,
        effects = {"glow"},
        colors = colors or {Color3.fromRGB(255, 255, 255)},
        animation = "default",
        enabled = true,
        icon = "✨"
    })
end

function ContentManager:QuickAddPet(name, description, rarity, unlockMethod, price)
    -- Quick pet creation
    return self:RegisterPet({
        id = string.lower(name):gsub("%s+", "_"),
        name = name,
        description = description,
        rarity = rarity or "common",
        unlockMethod = unlockMethod or "shop",
        price = price or 2000,
        abilities = {{name = "Companion", description = "Follows you around"}},
        model = "DefaultPetModel",
        animations = {"idle", "walk"},
        sounds = {"happy"},
        enabled = true,
        icon = "🐾"
    })
end

function ContentManager:QuickLeaderboardReset(type, preserveData, rewards)
    -- Quick leaderboard reset scheduling
    local resetDate = os.time()
    
    if type == "weekly" then
        resetDate = resetDate + (7 * 24 * 60 * 60)
    elseif type == "monthly" then
        resetDate = resetDate + (30 * 24 * 60 * 60)
    elseif type == "daily" then
        resetDate = resetDate + (24 * 60 * 60)
    end
    
    return self:ScheduleLeaderboardReset({
        id = type .. "_reset_" .. os.time(),
        name = string.upper(type:sub(1,1)) .. type:sub(2) .. " Leaderboard Reset",
        resetDate = resetDate,
        type = type,
        preserveData = preserveData ~= false,
        rewards = rewards or {},
        notification = "Leaderboard has been reset! New season begins!",
        enabled = true
    })
end

return ContentManager
