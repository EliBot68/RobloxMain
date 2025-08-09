-- Core shared module  
local MainGameService = {}

function MainGameService.Initialize()
    print("🔧 MainGameService initializing...")
    return true
end

function MainGameService.GetPlayerData(player)
    return {
        name = player.Name,
        userId = player.UserId,
        joinTime = os.time()
    }
end

return MainGameService
