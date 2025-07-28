-- GameConstants.luau
-- Shared constants used throughout the game

local GameConstants = {}

-- Game Settings
GameConstants.GAME_NAME = "Color Rush"
GameConstants.VERSION = "1.0.0"

-- Player Settings
GameConstants.DEFAULT_WALKSPEED = 20 -- Increased from 16 for better speed
GameConstants.DEFAULT_JUMPPOWER = 50
GameConstants.RUNNING_SPEED = 28 -- Increased proportionally
GameConstants.BOOST_SPEED = 36 -- Increased proportionally

-- Color Game Settings
GameConstants.GAME_COLORS = {
    RED = Color3.new(1, 0.2, 0.2),
    BLUE = Color3.new(0.2, 0.2, 1),
    GREEN = Color3.new(0.2, 1, 0.2),
    YELLOW = Color3.new(1, 1, 0.2),
    PURPLE = Color3.new(1, 0.2, 1),
    ORANGE = Color3.new(1, 0.6, 0.2)
}

GameConstants.COLOR_NAMES = {"RED", "BLUE", "GREEN", "YELLOW", "PURPLE", "ORANGE"}

-- Economy
GameConstants.STARTING_COINS = 0
GameConstants.COIN_VALUE = 10
GameConstants.BARRIER_REWARD = 50
GameConstants.WRONG_COLOR_PENALTY = -20

-- Game Mechanics
GameConstants.BARRIER_SPAWN_DISTANCE = 25 -- Reduced distance for 2x track length
GameConstants.COIN_SPAWN_CHANCE = 0.4 -- Increased for longer tracks
GameConstants.COLOR_CHANGE_TIME = 6 -- Reduced for more variation

-- Upgrades
GameConstants.UPGRADES = {
    SPEED = {
        name = "Speed Boost",
        baseCost = 100,
        multiplier = 1.5,
        maxLevel = 10
    },
    COIN_MAGNET = {
        name = "Coin Magnet",
        baseCost = 200,
        multiplier = 1.8,
        maxLevel = 5
    },
    DOUBLE_COINS = {
        name = "Double Coins",
        baseCost = 500,
        multiplier = 2.0,
        maxLevel = 3
    }
}

-- UI Settings
GameConstants.TWEEN_TIME = 0.2
GameConstants.NOTIFICATION_DURATION = 2
GameConstants.COLOR_CHANGE_WARNING = 2 -- seconds before color change

-- Effects
GameConstants.PARTICLE_DURATION = 1
GameConstants.SCREEN_SHAKE_INTENSITY = 0.5

-- Accessibility Settings
GameConstants.COLORBLIND_SYMBOLS = {
    RED = "🔺", -- Triangle for red
    GREEN = "⬟", -- Pentagon for green  
    BLUE = "⬢", -- Hexagon for blue
    YELLOW = "⭐", -- Star for yellow
    PURPLE = "⬥", -- Diamond for purple
    ORANGE = "⬣" -- Rounded hexagon for orange
}

-- Controller Settings
GameConstants.CONTROLLER_ENABLED = true
GameConstants.DPAD_COLORS = {"RED", "GREEN", "BLUE"} -- D-pad Up, Left, Right

-- Party System Constants
GameConstants.MAX_PARTY_SIZE = 4
GameConstants.PARTY_XP_BONUS = 0.25 -- 25% bonus XP when in party
GameConstants.PARTY_INVITE_TIMEOUT = 60 -- seconds
GameConstants.PARTY_SYNC_TOLERANCE = 3 -- seconds to wait for all party members
GameConstants.PARTY_PERFECT_BONUS = 0.5 -- Additional bonus for perfect party runs
GameConstants.PARTY_STREAK_BONUS = 0.1 -- Bonus per consecutive party game
GameConstants.MAX_PARTY_STREAK = 10
GameConstants.PARTY_VOICE_COOLDOWN = 5 -- seconds between voice messages
GameConstants.PARTY_EMOTE_COOLDOWN = 3 -- seconds between emotes
GameConstants.PARTY_CELEBRATION_DURATION = 5 -- seconds for group celebrations
GameConstants.PARTY_SYNC_COUNTDOWN = 5 -- countdown before party game starts

return GameConstants
