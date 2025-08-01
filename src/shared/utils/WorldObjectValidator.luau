-- WorldObjectValidator
-- Validates that required world objects exist at runtime
-- Prevents crashes from missing workspace objects

local WorldObjectValidator = {}

-- Required world objects for game functionality
local REQUIRED_WORLD_OBJECTS = {
    -- Spawn and teleport locations
    SpawnLocation = "workspace.SpawnLocation",
    TeleportPads = {
        "workspace.TeleportPads.EasyPad",
        "workspace.TeleportPads.MediumPad", 
        "workspace.TeleportPads.HardPad"
    },
    
    -- Game areas
    GameTrack = "workspace.GameTrack",
    StartLine = "workspace.GameTrack.StartLine",
    FinishLine = "workspace.GameTrack.FinishLine",
    
    -- Hub objects
    Hub = "workspace.Hub",
    ShopStall = "workspace.Hub.ShopStall",
    UpgradeStall = "workspace.Hub.UpgradeStall",
    QuestGiver = "workspace.Hub.QuestGiver",
    Fountain = "workspace.Hub.Fountain",
    RebirthStatue = "workspace.Hub.RebirthStatue",
    
    -- Economy objects
    CoinSpawners = "workspace.CoinSpawners",
    PetHatchers = "workspace.PetHatchers",
    MysteryBoxes = "workspace.MysteryBoxes",
    
    -- Visual anchors
    BillboardAnchors = "workspace.BillboardAnchors",
    ParticleAnchors = "workspace.ParticleAnchors",
    
    -- Audio objects
    AudioRegions = "workspace.AudioRegions",
    
    -- Developer tools
    DeveloperRoom = "workspace.DeveloperRoom"
}

-- Optional objects that improve experience but aren't critical
local OPTIONAL_WORLD_OBJECTS = {
    -- Cosmetic objects
    Decorations = "workspace.Decorations",
    Skybox = "workspace.Skybox",
    Lighting = "workspace.Lighting.Effects",
    
    -- Additional features
    Screenshots = "workspace.Screenshots",
    Events = "workspace.Events",
    Seasonal = "workspace.Seasonal"
}

function WorldObjectValidator.validateObject(objectPath: string): (boolean, Instance?)
    local success, object = pcall(function()
        local parts = string.split(objectPath, ".")
        local current = game
        
        for i = 1, #parts do
            if parts[i] == "game" then
                -- Skip "game" prefix
                continue
            end
            
            current = current:FindFirstChild(parts[i])
            if not current then
                return nil
            end
        end
        
        return current
    end)
    
    if success and object then
        return true, object
    else
        return false, nil
    end
end

function WorldObjectValidator.validateObjectWithWait(objectPath: string, timeout: number?): (boolean, Instance?)
    timeout = timeout or 5 -- Default 5 second timeout
    local startTime = tick()
    
    -- Event-driven object waiting with adaptive intervals
    local checkInterval = 0.1
    local maxInterval = 2.0
    while tick() - startTime < timeout do
        local exists, object = WorldObjectValidator.validateObject(objectPath)
        if exists then
            return true, object
        end
        
        -- Adaptive interval: increase wait time if object isn't found quickly
        task.wait(checkInterval)
        checkInterval = math.min(checkInterval * 1.5, maxInterval)
    end
    
    return false, nil
end

function WorldObjectValidator.validateAllRequired(): {string}
    local missingObjects = {}
    
    for objectName, objectPath in pairs(REQUIRED_WORLD_OBJECTS) do
        if type(objectPath) == "table" then
            -- Multiple objects in array
            for _, path in ipairs(objectPath) do
                local exists, object = WorldObjectValidator.validateObject(path)
                if not exists then
                    table.insert(missingObjects, string.format("%s: %s", objectName, path))
                end
            end
        else
            -- Single object
            local exists, object = WorldObjectValidator.validateObject(objectPath)
            if not exists then
                table.insert(missingObjects, string.format("%s: %s", objectName, objectPath))
            end
        end
    end
    
    return missingObjects
end

function WorldObjectValidator.validateAllOptional(): {string}
    local missingOptional = {}
    
    for objectName, objectPath in pairs(OPTIONAL_WORLD_OBJECTS) do
        if type(objectPath) == "table" then
            for _, path in ipairs(objectPath) do
                local exists, object = WorldObjectValidator.validateObject(path)
                if not exists then
                    table.insert(missingOptional, string.format("%s: %s", objectName, path))
                end
            end
        else
            local exists, object = WorldObjectValidator.validateObject(objectPath)
            if not exists then
                table.insert(missingOptional, string.format("%s: %s", objectName, objectPath))
            end
        end
    end
    
    return missingOptional
end

function WorldObjectValidator.createValidationReport(): string
    local missingRequired = WorldObjectValidator.validateAllRequired()
    local missingOptional = WorldObjectValidator.validateAllOptional()
    
    local report = ""
    
    if #missingRequired == 0 then
        report = report .. "✅ All required world objects found\n"
    else
        report = report .. "❌ Missing required world objects:\n"
        for _, missing in ipairs(missingRequired) do
            report = report .. "  • " .. missing .. "\n"
        end
    end
    
    if #missingOptional > 0 then
        report = report .. "⚠️ Missing optional world objects:\n"
        for _, missing in ipairs(missingOptional) do
            report = report .. "  • " .. missing .. "\n"
        end
    end
    
    if #missingRequired == 0 and #missingOptional == 0 then
        report = report .. "🎉 All world objects present!"
    end
    
    return report
end

function WorldObjectValidator.createPlaceFileTemplate(): string
    local template = "-- Place File Object Structure Template\n"
    template = template .. "-- Create these objects in workspace for full functionality\n\n"
    
    template = template .. "-- REQUIRED OBJECTS:\n"
    for objectName, objectPath in pairs(REQUIRED_WORLD_OBJECTS) do
        if type(objectPath) == "table" then
            template = template .. string.format("-- %s:\n", objectName)
            for _, path in ipairs(objectPath) do
                template = template .. string.format("--   %s\n", path)
            end
        else
            template = template .. string.format("-- %s: %s\n", objectName, objectPath)
        end
    end
    
    template = template .. "\n-- OPTIONAL OBJECTS:\n"
    for objectName, objectPath in pairs(OPTIONAL_WORLD_OBJECTS) do
        if type(objectPath) == "table" then
            template = template .. string.format("-- %s:\n", objectName)
            for _, path in ipairs(objectPath) do
                template = template .. string.format("--   %s\n", path)
            end
        else
            template = template .. string.format("-- %s: %s\n", objectName, objectPath)
        end
    end
    
    return template
end

function WorldObjectValidator.waitForObject(objectPath: string, timeout: number?): Instance?
    timeout = timeout or 30 -- Default 30 second timeout
    local startTime = tick()
    
    print(string.format("🔍 Waiting for object: %s (timeout: %ds)", objectPath, timeout or 10))
    
    -- Event-driven object waiting with adaptive intervals
    local checkInterval = 0.5
    local maxInterval = 5.0
    while tick() - startTime < timeout do
        local exists, object = WorldObjectValidator.validateObject(objectPath)
        if exists then
            print(string.format("✅ Found object: %s", objectPath))
            return object
        end
        
        -- Adaptive interval: increase wait time if object takes longer to find
        task.wait(checkInterval)
        checkInterval = math.min(checkInterval * 1.2, maxInterval)
    end
    
    warn(string.format("⏰ Timeout waiting for object: %s", objectPath))
    return nil
end

function WorldObjectValidator.createObjectIfMissing(objectPath: string, objectType: string?, parentPath: string?): Instance?
    local exists, object = WorldObjectValidator.validateObject(objectPath)
    if exists then
        return object
    end
    
    -- Attempt to create missing object
    local parts = string.split(objectPath, ".")
    local objectName = parts[#parts]
    
    local parent = game
    if parentPath then
        local parentExists, parentObject = WorldObjectValidator.validateObject(parentPath)
        if parentExists then
            parent = parentObject
        else
            warn(string.format("Cannot create %s: parent %s not found", objectPath, parentPath))
            return nil
        end
    else
        -- Find parent from path
        for i = 1, #parts - 1 do
            if parts[i] == "game" then
                continue
            end
            parent = parent:FindFirstChild(parts[i])
            if not parent then
                warn(string.format("Cannot create %s: parent path broken at %s", objectPath, parts[i]))
                return nil
            end
        end
    end
    
    -- Create the object
    local newObject
    if objectType then
        newObject = Instance.new(objectType)
    else
        -- Default to Folder for containers
        newObject = Instance.new("Folder")
    end
    
    newObject.Name = objectName
    newObject.Parent = parent
    
    print(string.format("🔧 Created missing object: %s", objectPath))
    return newObject
end

return WorldObjectValidator
