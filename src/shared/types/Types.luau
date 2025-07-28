-- Types.luau
-- Type definitions for the game

export type PlayerData = {
    coins: number,
    level: number,
    experience: number,
    settings: {
        music: boolean,
        sfx: boolean,
        colorblindMode: boolean,
        controllerEnabled: boolean
    }
}

export type TweenInfo = {
    duration: number?,
    easingStyle: Enum.EasingStyle?,
    easingDirection: Enum.EasingDirection?
}

return {}
