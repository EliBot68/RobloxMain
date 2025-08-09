-- SharedUtils.luau
-- Utility functions safe for both client and server

local SharedUtils = {}

function SharedUtils.WaitForChildTimeout(parent, childName, timeout)
    local child = parent:FindFirstChild(childName)
    if child then
        return child
    end
    
    local startTime = tick()
    repeat
        child = parent:FindFirstChild(childName)
        if child then
            return child
        end
        wait(0.1)
    until tick() - startTime > (timeout or 10)
    
    warn("WaitForChildTimeout: Failed to find", childName, "in", parent.Name)
    return nil
end

function SharedUtils.SafeDestroy(instance)
    if instance and instance.Parent then
        instance:Destroy()
    end
end

return SharedUtils
