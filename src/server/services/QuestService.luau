-- QuestService.luau
-- Handles daily quest challenges and rewards

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local DataStoreService = game:GetService("DataStoreService")
local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local SafeRequire = require(ReplicatedStorage.Shared.utils.SafeRequire)
local PlayerService = SafeRequire.require(script.Parent.PlayerService)
local RemoteEvents = SafeRequire.require(ReplicatedStorage.Shared.modules.RemoteEvents)

local QuestService = {}

-- DataStore for tracking quest progress
local questProgressStore = DataStoreService:GetDataStore("DailyQuestProgress")

-- Quest templates with creative challenges
local DAILY_QUESTS = {
    -- Color Matching Quests
    {
        id = "red_master",
        name = "🔴 Red Rush Master",
        description = "Successfully match through 25 red barriers",
        targetType = "color_match",
        targetColor = "red",
        targetAmount = 25,
        reward = {type = "coins", amount = 150},
        difficulty = "easy"
    },
    {
        id = "blue_streak",
        name = "🔵 Blue Barrier Breaker",
        description = "Pass through 30 blue barriers without failing",
        targetType = "color_match",
        targetColor = "blue",
        targetAmount = 30,
        reward = {type = "coins", amount = 200},
        difficulty = "medium"
    },
    {
        id = "green_guardian",
        name = "🟢 Green Gate Guardian",
        description = "Master 20 green barriers in a single day",
        targetType = "color_match",
        targetColor = "green",
        targetAmount = 20,
        reward = {type = "coins", amount = 175},
        difficulty = "easy"
    },
    {
        id = "yellow_lightning",
        name = "🟡 Yellow Lightning Strike",
        description = "Blaze through 35 yellow barriers",
        targetType = "color_match",
        targetColor = "yellow",
        targetAmount = 35,
        reward = {type = "coins", amount = 250},
        difficulty = "hard"
    },
    
    -- Coin Collection Quests
    {
        id = "coin_collector",
        name = "💰 Coin Collector Supreme",
        description = "Collect 500 coins from gameplay",
        targetType = "coins_collected",
        targetAmount = 500,
        reward = {type = "multiplier", amount = 2, duration = 600}, -- 10 min 2x multiplier
        difficulty = "medium"
    },
    {
        id = "treasure_hunter",
        name = "💎 Treasure Hunter Elite",
        description = "Gather 1000 coins in a single day",
        targetType = "coins_collected",
        targetAmount = 1000,
        reward = {type = "coins", amount = 300},
        difficulty = "hard"
    },
    
    -- Game Performance Quests
    {
        id = "speed_demon",
        name = "⚡ Speed Demon Challenge",
        description = "Complete 5 games in under 3 minutes each",
        targetType = "fast_games",
        targetAmount = 5,
        targetTime = 180, -- 3 minutes
        reward = {type = "special", effect = "rainbow_trail", duration = 900}, -- 15 min trail
        difficulty = "hard"
    },
    {
        id = "marathon_runner",
        name = "🏃 Marathon Runner",
        description = "Play 10 complete games",
        targetType = "games_played",
        targetAmount = 10,
        reward = {type = "coins", amount = 400},
        difficulty = "medium"
    },
    {
        id = "perfectionist",
        name = "🎯 Perfectionist Pro",
        description = "Complete 3 games without hitting wrong barriers",
        targetType = "perfect_games",
        targetAmount = 3,
        reward = {type = "mega", amount = 500, effect = "golden_aura"},
        difficulty = "expert"
    },
    
    -- Score & Achievement Quests
    {
        id = "high_scorer",
        name = "🏆 High Score Hero",
        description = "Achieve a score of 15 or higher in one game",
        targetType = "high_score",
        targetAmount = 15,
        reward = {type = "coins", amount = 250},
        difficulty = "medium"
    },
    {
        id = "combo_master",
        name = "🔥 Combo Master",
        description = "Get a 10-barrier combo streak",
        targetType = "combo_streak",
        targetAmount = 10,
        reward = {type = "special", effect = "fire_trail", duration = 600},
        difficulty = "hard"
    },
    
    -- Social & Exploration Quests
    {
        id = "fountain_blessed",
        name = "🌊 Fountain's Blessing",
        description = "Claim your daily fountain reward",
        targetType = "fountain_claimed",
        targetAmount = 1,
        reward = {type = "coins", amount = 100},
        difficulty = "easy"
    },
    {
        id = "shop_browser",
        name = "🛍️ Window Shopper",
        description = "Browse the Skins & Trails shop 3 times",
        targetType = "shop_visits",
        targetAmount = 3,
        reward = {type = "coins", amount = 75},
        difficulty = "easy"
    },
    {
        id = "cosmetic_collector",
        name = "✨ Style Enthusiast",
        description = "Purchase any cosmetic item",
        targetType = "cosmetic_purchase",
        targetAmount = 1,
        reward = {type = "coins", amount = 150},
        difficulty = "easy"
    },
    {
        id = "mystery_explorer",
        name = "🎲 Mystery Explorer",
        description = "Open 3 Mystery Boxes",
        targetType = "mystery_box_opened",
        targetAmount = 3,
        reward = {type = "coins", amount = 200},
        difficulty = "medium"
    },
    {
        id = "lucky_finder",
        name = "🍀 Lucky Finder",
        description = "Find a Rare or Epic item from Mystery Boxes",
        targetType = "rare_mystery_find",
        targetAmount = 1,
        reward = {type = "special", effect = "rainbow_trail", duration = 900},
        difficulty = "hard"
    },
    {
        id = "event_enthusiast",
        name = "🎪 Event Enthusiast",
        description = "Complete 2 Event Runs",
        targetType = "event_runs_completed",
        targetAmount = 2,
        reward = {type = "coins", amount = 300},
        difficulty = "medium"
    },
    {
        id = "theme_master",
        name = "🌟 Theme Master",
        description = "Score 20+ points in an Event Run",
        targetType = "event_high_score",
        targetAmount = 20,
        reward = {type = "special", effect = "cosmic_aura", duration = 600},
        difficulty = "hard"
    },
    {
        id = "streak_warrior",
        name = "🔥 Streak Warrior",
        description = "Maintain a 3-day login streak",
        targetType = "daily_streak",
        targetAmount = 3,
        reward = {type = "coins", amount = 200},
        difficulty = "medium"
    },
    {
        id = "dedication_master",
        name = "👑 Dedication Master",
        description = "Achieve a 7-day login streak",
        targetType = "daily_streak",
        targetAmount = 7,
        reward = {type = "special", effect = "dedication_aura", duration = 1200},
        difficulty = "hard"
    },
    {
        id = "accessibility_explorer",
        name = "♿ Accessibility Explorer",
        description = "Enable colorblind mode for better visual clarity",
        targetType = "accessibility_setting",
        targetSetting = "colorblindMode",
        targetAmount = 1,
        reward = {type = "coins", amount = 100},
        difficulty = "easy"
    },
    {
        id = "controller_master",
        name = "🎮 Controller Master",
        description = "Use Xbox controller D-pad for color changes (5 times)",
        targetType = "controller_input",
        targetAmount = 5,
        reward = {type = "coins", amount = 150},
        difficulty = "easy"
    },
    
    -- Ghost Runner Quests
    {
        id = "ghost_viewer",
        name = "👻 Ghost Spectator",
        description = "View the ghost leaderboard for the first time",
        targetType = "ghost_leaderboard_view",
        targetAmount = 1,
        reward = {type = "coins", amount = 100},
        difficulty = "easy"
    },
    {
        id = "ghost_racer",
        name = "👻 Ghost Racer",
        description = "Race against 3 different ghost runners",
        targetType = "ghost_race",
        targetAmount = 3,
        reward = {type = "coins", amount = 300},
        difficulty = "medium"
    },
    {
        id = "ghost_champion",
        name = "👻 Ghost Champion",
        description = "Beat a ghost runner's time in a race",
        targetType = "ghost_victory",
        targetAmount = 1,
        reward = {type = "coins", amount = 500},
        difficulty = "hard"
    },
    {
        id = "top_ghost",
        name = "👻 Legendary Ghost",
        description = "Get your ghost in the top 5 leaderboard",
        targetType = "ghost_leaderboard_rank",
        targetAmount = 5,
        reward = {type = "special", effect = "ghost_aura", duration = 1800},
        difficulty = "hard"
    },
    {
        id = "ghost_creator",
        name = "👻 Ghost Creator",
        description = "Complete 5 runs to create ghost data",
        targetType = "ghost_runs_completed",
        targetAmount = 5,
        reward = {type = "coins", amount = 250},
        difficulty = "medium"
    },
    
    -- Upgrade Quests
    {
        id = "first_upgrade",
        name = "⚡ First Upgrade",
        description = "Purchase your first upgrade",
        targetType = "upgrade_purchase",
        targetAmount = 1,
        reward = {type = "coins", amount = 100},
        difficulty = "easy"
    },
    {
        id = "upgrade_collector",
        name = "⚡ Upgrade Collector",
        description = "Purchase 3 different upgrades",
        targetType = "upgrade_purchase",
        targetAmount = 3,
        reward = {type = "coins", amount = 300},
        difficulty = "medium"
    },
    {
        id = "max_upgrade",
        name = "⚡ Maxed Out",
        description = "Max out any upgrade to its highest level",
        targetType = "max_upgrade_reached",
        targetAmount = 1,
        reward = {type = "special", effect = "upgrade_master_aura", duration = 1800},
        difficulty = "hard"
    },
    
    -- Share & Social Quests
    {
        id = "first_share",
        name = "📤 First Share",
        description = "Share your score for the first time",
        targetType = "score_shared",
        targetAmount = 1,
        reward = {type = "coins", amount = 100},
        difficulty = "easy"
    },
    {
        id = "social_butterfly",
        name = "🦋 Social Butterfly",
        description = "Share your scores 3 times in one day",
        targetType = "score_shared",
        targetAmount = 3,
        reward = {type = "coins", amount = 200},
        difficulty = "medium"
    },
    {
        id = "achievement_sharer",
        name = "🏆 Achievement Sharer",
        description = "Share a perfect run or high score",
        targetType = "epic_share",
        targetAmount = 1,
        reward = {type = "special", effect = "social_aura", duration = 900},
        difficulty = "hard"
    },
    
    -- World Event Quests
    {
        id = "event_participant",
        name = "🌟 Event Participant",
        description = "Participate in your first World Event",
        targetType = "world_event_participation",
        targetAmount = 1,
        reward = {type = "coins", amount = 200},
        difficulty = "easy"
    },
    {
        id = "event_champion",
        name = "🏆 Event Champion",
        description = "Score 20+ points in a World Event",
        targetType = "world_event_high_score",
        targetAmount = 20,
        reward = {type = "coins", amount = 500},
        difficulty = "hard"
    },
    {
        id = "event_veteran",
        name = "⭐ Event Veteran",
        description = "Participate in 5 different World Events",
        targetType = "world_event_participation",
        targetAmount = 5,
        reward = {type = "special", effect = "event_master_aura", duration = 1800},
        difficulty = "hard"
    },
    {
        id = "cosmic_explorer",
        name = "🌌 Cosmic Explorer",
        description = "Complete a run during Cosmic Rush event",
        targetType = "specific_event_completion",
        targetEvent = "cosmic_rush",
        targetAmount = 1,
        reward = {type = "special", effect = "cosmic_trail", duration = 900},
        difficulty = "medium"
    },
    {
        id = "neon_racer",
        name = "🌃 Neon Racer",
        description = "Score 15+ points in Neon Night event",
        targetType = "specific_event_score",
        targetEvent = "neon_night",
        targetAmount = 15,
        reward = {type = "special", effect = "neon_glow", duration = 900},
        difficulty = "medium"
    },
    
    -- Weekly Puzzle Quests
    {
        id = "puzzle_explorer",
        name = "🧩 Puzzle Explorer",
        description = "Find your first weekly puzzle piece",
        targetType = "puzzle_piece_collected",
        targetAmount = 1,
        reward = {type = "coins", amount = 150},
        difficulty = "easy"
    },
    {
        id = "treasure_hunter",
        name = "🗺️ Treasure Hunter",
        description = "Collect 3 puzzle pieces in one week",
        targetType = "puzzle_piece_collected",
        targetAmount = 3,
        reward = {type = "coins", amount = 400},
        difficulty = "medium"
    },
    {
        id = "puzzle_master",
        name = "🏆 Puzzle Master",
        description = "Complete the weekly puzzle challenge",
        targetType = "puzzle_completed",
        targetAmount = 1,
        reward = {type = "special", effect = "puzzle_master_aura", duration = 2400},
        difficulty = "hard"
    },
    {
        id = "rainbow_collector",
        name = "🌈 Rainbow Collector",
        description = "Find all 5 colored puzzle pieces",
        targetType = "puzzle_piece_collected",
        targetAmount = 5,
        reward = {type = "mega", amount = 1000, effect = "rainbow_celebration"},
        difficulty = "expert"
    },
    
    -- Trophy Collection Quests
    {
        id = "trophy_beginner",
        name = "🏆 Trophy Collector",
        description = "Unlock your first trophy",
        targetType = "trophy_unlocked",
        targetAmount = 1,
        reward = {type = "coins", amount = 200},
        difficulty = "easy"
    },
    {
        id = "trophy_enthusiast",
        name = "🏅 Trophy Enthusiast",
        description = "Collect 5 different trophies",
        targetType = "trophy_unlocked",
        targetAmount = 5,
        reward = {type = "coins", amount = 500},
        difficulty = "medium"
    },
    {
        id = "trophy_master",
        name = "👑 Trophy Master",
        description = "Unlock 10 trophies total",
        targetType = "trophy_unlocked",
        targetAmount = 10,
        reward = {type = "special", effect = "trophy_aura", duration = 1800},
        difficulty = "hard"
    },
    {
        id = "legendary_collector",
        name = "💎 Legendary Collector",
        description = "Obtain a Diamond rarity trophy",
        targetType = "diamond_trophy_unlocked",
        targetAmount = 1,
        reward = {type = "mega", amount = 2000, effect = "diamond_celebration"},
        difficulty = "expert"
    },
    
    -- Pet Collection Quests
    {
        id = "pet_owner",
        name = "🐾 Pet Owner",
        description = "Purchase your first pet",
        targetType = "pet_purchased",
        targetAmount = 1,
        reward = {type = "coins", amount = 200},
        difficulty = "easy"
    },
    {
        id = "pet_collector",
        name = "🦄 Pet Collector",
        description = "Own 3 different pets",
        targetType = "pets_owned",
        targetAmount = 3,
        reward = {type = "coins", amount = 500},
        difficulty = "medium"
    },
    {
        id = "pet_enthusiast",
        name = "🌟 Pet Enthusiast",
        description = "Have a pet active for 5 complete games",
        targetType = "games_with_pet",
        targetAmount = 5,
        reward = {type = "special", effect = "pet_bond_aura", duration = 1200},
        difficulty = "medium"
    },
    {
        id = "rare_pet_master",
        name = "💎 Rare Pet Master",
        description = "Purchase a Rare or higher rarity pet",
        targetType = "rare_pet_purchased",
        targetAmount = 1,
        reward = {type = "coins", amount = 1000},
        difficulty = "hard"
    },
    
    -- Exclusive Cosmetic Quests (FOMO-driven)
    {
        id = "exclusive_hunter",
        name = "🌟 Exclusive Hunter",
        description = "Purchase your first exclusive cosmetic before it expires!",
        targetType = "exclusive_purchased",
        targetAmount = 1,
        reward = {type = "special", effect = "exclusive_hunter_aura", duration = 2400},
        difficulty = "hard"
    },
    {
        id = "limited_collector",
        name = "⏰ Limited Time Collector",
        description = "Own 2 different exclusive cosmetics",
        targetType = "exclusives_owned",
        targetAmount = 2,
        reward = {type = "mega", amount = 1500, effect = "collector_prestige"},
        difficulty = "expert"
    },
    {
        id = "exclusive_elite",
        name = "👑 Exclusive Elite",
        description = "Purchase an exclusive worth 150+ Robux",
        targetType = "premium_exclusive_purchased",
        targetAmount = 150,
        reward = {type = "special", effect = "elite_status_aura", duration = 3600},
        difficulty = "expert"
    },
    {
        id = "countdown_watcher",
        name = "⏰ Countdown Watcher",
        description = "Check the exclusive countdown displays 5 times",
        targetType = "countdown_viewed",
        targetAmount = 5,
        reward = {type = "coins", amount = 200},
        difficulty = "easy"
    },
    {
        id = "last_chance",
        name = "🚨 Last Chance Hero",
        description = "Purchase an exclusive with less than 24 hours remaining",
        targetType = "last_minute_purchase",
        targetAmount = 1,
        reward = {type = "special", effect = "procrastinator_badge", duration = 1800},
        difficulty = "hard"
    },
    {
        id = "exclusive_trendsetter",
        name = "✨ Exclusive Trendsetter",
        description = "Be among the first 10 to purchase a new exclusive",
        targetType = "early_exclusive_purchase",
        targetAmount = 1,
        reward = {type = "special", effect = "trendsetter_crown", duration = 4800},
        difficulty = "expert"
    },
    {
        id = "fomo_master",
        name = "😱 FOMO Master",
        description = "Purchase 3 exclusives before they expire",
        targetType = "exclusive_purchased",
        targetAmount = 3,
        reward = {type = "mega", amount = 2500, effect = "fomo_master_achievement"},
        difficulty = "expert"
    },
    
    -- Party System Quests
    {
        id = "party_starter",
        name = "🎉 Party Starter",
        description = "Create your first party",
        targetType = "party_created",
        targetAmount = 1,
        reward = {type = "coins", amount = 200},
        difficulty = "easy"
    },
    {
        id = "social_gamer",
        name = "👥 Social Gamer",
        description = "Play 3 games with friends in a party",
        targetType = "party_games_played",
        targetAmount = 3,
        reward = {type = "special", effect = "friendship_aura", duration = 1800},
        difficulty = "medium"
    },
    {
        id = "party_leader",
        name = "👑 Party Leader",
        description = "Lead a party of 4 players",
        targetType = "max_party_size",
        targetAmount = 4,
        reward = {type = "coins", amount = 500},
        difficulty = "medium"
    },
    {
        id = "teamwork_master",
        name = "🤝 Teamwork Master",
        description = "Earn 1000 bonus XP from party play",
        targetType = "party_bonus_xp",
        targetAmount = 1000,
        reward = {type = "special", effect = "teamwork_crown", duration = 2400},
        difficulty = "hard"
    },
    {
        id = "friendship_goals",
        name = "💖 Friendship Goals",
        description = "Play 10 games with the same party",
        targetType = "consistent_party_games",
        targetAmount = 10,
        reward = {type = "mega", amount = 1000, effect = "friendship_celebration"},
        difficulty = "hard"
    },
    
    -- Creative Party Quests
    {
        id = "voice_commander",
        name = "🎤 Voice Commander",
        description = "Send 15 voice messages to your party",
        targetType = "party_voice_sent",
        targetAmount = 15,
        reward = {type = "special", effect = "voice_master_aura", duration = 1800},
        difficulty = "medium"
    },
    {
        id = "emote_enthusiast",
        name = "😊 Emote Enthusiast",
        description = "Send 25 emotes in party chat",
        targetType = "party_emotes_sent",
        targetAmount = 25,
        reward = {type = "coins", amount = 300},
        difficulty = "medium"
    },
    {
        id = "party_perfectionist",
        name = "🌟 Party Perfectionist",
        description = "Complete 3 perfect synchronized runs",
        targetType = "party_perfect_runs",
        targetAmount = 3,
        reward = {type = "special", effect = "perfectionist_crown", duration = 2400},
        difficulty = "expert"
    },
    {
        id = "celebration_master",
        name = "🎉 Celebration Master",
        description = "Trigger 5 party celebrations",
        targetType = "party_celebrations",
        targetAmount = 5,
        reward = {type = "coins", amount = 400},
        difficulty = "medium"
    },
    {
        id = "party_leveler",
        name = "⭐ Party Leveler",
        description = "Help your party reach level 5",
        targetType = "party_level_reached",
        targetAmount = 5,
        reward = {type = "mega", amount = 1500, effect = "party_legend_aura"},
        difficulty = "expert"
    },
    {
        id = "achievement_hunter",
        name = "🏆 Achievement Hunter",
        description = "Unlock 3 party achievements",
        targetType = "party_achievements_unlocked",
        targetAmount = 3,
        reward = {type = "special", effect = "achievement_collector_badge", duration = 3600},
        difficulty = "hard"
    },
    
    -- Mini-Game Hub Quests
    {
        id = "first_mini_game",
        name = "🎮 First Mini-Game",
        description = "Play your first hub mini-game",
        targetType = "minigame_played",
        targetAmount = 1,
        reward = {type = "coins", amount = 100},
        difficulty = "easy"
    },
    {
        id = "target_practice",
        name = "🎯 Target Practice",
        description = "Hit 10 targets in Jump to Target mini-games",
        targetType = "targets_hit",
        targetAmount = 10,
        reward = {type = "coins", amount = 300},
        difficulty = "medium"
    },
    {
        id = "coin_collector",
        name = "💰 Coin Collector",
        description = "Click 50 coins in Coin Clicker mini-games",
        targetType = "coins_clicked",
        targetAmount = 50,
        reward = {type = "special", effect = "golden_fingers", duration = 1800},
        difficulty = "medium"
    },
    {
        id = "mini_game_champion",
        name = "🏅 Mini-Game Champion",
        description = "Play 5 different mini-game sessions",
        targetType = "minigame_played",
        targetAmount = 5,
        reward = {type = "coins", amount = 500},
        difficulty = "hard"
    },
    {
        id = "perfect_aim",
        name = "🎯 Perfect Aim",
        description = "Hit 5 targets in a single Jump Target session",
        targetType = "perfect_target_game",
        targetAmount = 1,
        reward = {type = "special", effect = "marksman_aura", duration = 2400},
        difficulty = "hard"
    },
    {
        id = "speed_clicker",
        name = "⚡ Speed Clicker",
        description = "Click 20 coins in a single Coin Clicker session",
        targetType = "perfect_clicker_game",
        targetAmount = 1,
        reward = {type = "special", effect = "lightning_hands", duration = 2400},
        difficulty = "hard"
    },
    
    -- Buff System Quests
    {
        id = "first_buff",
        name = "💫 First Power-Up",
        description = "Purchase your first buff from the power-up shop",
        targetType = "buff_purchased",
        targetAmount = 1,
        reward = {type = "coins", amount = 200},
        difficulty = "easy"
    },
    {
        id = "buff_collector",
        name = "🛍️ Power-Up Collector",
        description = "Purchase 3 different types of buffs",
        targetType = "unique_buffs_purchased",
        targetAmount = 3,
        reward = {type = "special", effect = "collector_aura", duration = 3600},
        difficulty = "medium"
    },
    {
        id = "buff_master",
        name = "🎭 Buff Master",
        description = "Use 10 buffs in gameplay",
        targetType = "buffs_used",
        targetAmount = 10,
        reward = {type = "coins", amount = 500},
        difficulty = "medium"
    },
    {
        id = "combo_legend",
        name = "🔥 Combo Legend",
        description = "Achieve a 10+ combo with Combo Streak buff active",
        targetType = "combo_with_buff",
        targetAmount = 10,
        reward = {type = "special", effect = "combo_master_crown", duration = 4800},
        difficulty = "hard"
    },
    {
        id = "shield_survivor",
        name = "🛡️ Shield Survivor",
        description = "Use Shield Protection to survive a collision",
        targetType = "shield_used",
        targetAmount = 1,
        reward = {type = "coins", amount = 300},
        difficulty = "medium"
    },
    {
        id = "time_lord",
        name = "❄️ Time Lord",
        description = "Use Time Freeze buff 5 times",
        targetType = "timefreeze_used",
        targetAmount = 5,
        reward = {type = "special", effect = "temporal_mastery", duration = 3600},
        difficulty = "hard"
    },
    
    -- Tournament Quests
    {
        id = "tournament_participant",
        name = "🏆 Tournament Participant",
        description = "Participate in weekly tournament competition",
        targetType = "tournament_participation",
        targetAmount = 1,
        reward = {type = "coins", amount = 200},
        difficulty = "easy"
    },
    {
        id = "tournament_champion",
        name = "👑 Tournament Champion",
        description = "Earn a tournament prize",
        targetType = "tournament_prizes",
        targetAmount = 1,
        reward = {type = "special", effect = "champion_crown", duration = 7200},
        difficulty = "hard"
    },
    {
        id = "leaderboard_climber",
        name = "📈 Leaderboard Climber",
        description = "Reach top 10 in any tournament category",
        targetType = "leaderboard_top10",
        targetAmount = 1,
        reward = {type = "coins", amount = 500},
        difficulty = "hard"
    }
}

-- Player quest tracking
local playerQuests = {}
local playerQuestProgress = {}

function QuestService:GetDaysSinceEpoch()
    return math.floor(os.time() / 86400)
end

function QuestService:GetSecondsUntilNextUTCMidnight()
    -- Calculate seconds until next UTC 00:00
    local currentTime = os.time()
    local currentUTCDate = os.date("!*t", currentTime)
    
    -- Calculate seconds since midnight today
    local secondsSinceMidnight = currentUTCDate.hour * 3600 + currentUTCDate.min * 60 + currentUTCDate.sec
    
    -- Calculate seconds until next midnight (86400 seconds in a day)
    local secondsUntilMidnight = 86400 - secondsSinceMidnight
    
    return secondsUntilMidnight
end

function QuestService:ResetAllPlayerQuests()
    -- Get all player data from DataStore and reset their quests
    print("🔄 Starting daily quest reset for all players...")
    
    local currentDay = self:GetDaysSinceEpoch()
    local resetCount = 0
    local failureCount = 0
    
    -- Get all stored user data keys (this is simplified - in practice you'd maintain a list)
    -- For now, we'll reset quests for currently active players and trust individual resets for others
    
    -- Reset for currently connected players
    for _, player in pairs(Players:GetPlayers()) do
        local success = self:ResetPlayerQuests(player, currentDay)
        if success then
            resetCount = resetCount + 1
            print("✅ Reset quests for " .. player.Name)
        else
            failureCount = failureCount + 1
            warn("❌ Failed to reset quests for " .. player.Name)
        end
    end
    
    -- Log the daily reset event to analytics if available
    if PlayerService and PlayerService.AnalyticsService then
        local AnalyticsService = PlayerService.AnalyticsService
        for _, player in pairs(Players:GetPlayers()) do
            AnalyticsService:LogEvent(player, "daily_quest_reset", {
                resetDay = currentDay,
                playersReset = resetCount,
                failures = failureCount,
                resetTime = os.time()
            })
        end
    end
    
    -- Log the daily reset event
    print("📋 Daily quest reset completed:")
    print("   • Players reset: " .. resetCount)
    print("   • Failures: " .. failureCount)
    print("   • Current day: " .. currentDay)
    
    -- Schedule the next reset
    self:ScheduleNextDailyReset()
end

function QuestService:ResetPlayerQuests(player, forceDay)
    local userId = tostring(player.UserId)
    local currentDay = forceDay or self:GetDaysSinceEpoch()
    
    -- Generate new daily quests
    local newQuestData = {
        dailyQuests = self:GetRandomQuests(3),
        questProgress = {},
        lastQuestDay = currentDay
    }
    
    -- Initialize progress for each quest
    for i, quest in pairs(newQuestData.dailyQuests) do
        newQuestData.questProgress[i] = {
            completed = false,
            progress = 0,
            claimed = false
        }
    end
    
    -- Save to DataStore
    local success = pcall(function()
        questProgressStore:SetAsync(userId, newQuestData)
    end)
    
    if success then
        -- Update in-memory data
        playerQuests[userId] = newQuestData.dailyQuests
        playerQuestProgress[userId] = newQuestData.questProgress
        
        -- Sync with main player data
        if PlayerService then
            local playerData = PlayerService:GetPlayerData(player)
            if playerData then
                playerData.questProgress = newQuestData.questProgress
                playerData.dailyQuests = newQuestData.dailyQuests
                playerData.lastQuestReset = currentDay
                PlayerService:UpdatePlayerData(player, playerData)
            end
        end
        
        -- Notify client if player is online
        if player and player.Parent then
            RemoteEvents.QuestProgressUpdated:FireClient(player, newQuestData.dailyQuests, newQuestData.questProgress)
            print("🔄 " .. player.Name .. " received new daily quests")
        end
        
        return true
    else
        warn("❌ Failed to reset quests for " .. player.Name)
        return false
    end
end

function QuestService:ScheduleNextDailyReset()
    -- Calculate time until next UTC midnight
    local secondsUntilReset = self:GetSecondsUntilNextUTCMidnight()
    
    print("⏰ Next daily quest reset scheduled in " .. math.floor(secondsUntilReset / 3600) .. " hours and " .. math.floor((secondsUntilReset % 3600) / 60) .. " minutes")
    
    -- Schedule the reset
    task.spawn(function() -- UPDATED for modern API
        task.wait(secondsUntilReset) -- UPDATED for modern API
        self:ResetAllPlayerQuests()
    end)
end

function QuestService:CheckAndResetIfNeeded(player)
    -- Check if a specific player needs a quest reset (called on login)
    local userId = tostring(player.UserId)
    local currentDay = self:GetDaysSinceEpoch()
    
    -- Try to load current quest data
    local success, data = pcall(function()
        return questProgressStore:GetAsync(userId) or {}
    end)
    
    if success and data.lastQuestDay and data.lastQuestDay < currentDay then
        -- Player needs a reset
        print("🔄 " .. player.Name .. " needs quest reset (last reset: day " .. (data.lastQuestDay or 0) .. ", current: day " .. currentDay .. ")")
        return self:ResetPlayerQuests(player, currentDay)
    end
    
    return false
end

function QuestService:GetRandomQuests(count)
    local availableQuests = {}
    for _, quest in pairs(DAILY_QUESTS) do
        table.insert(availableQuests, quest)
    end
    
    -- Shuffle and pick random quests
    local selectedQuests = {}
    for i = 1, math.min(count, #availableQuests) do
        local randomIndex = math.random(1, #availableQuests)
        table.insert(selectedQuests, availableQuests[randomIndex])
        table.remove(availableQuests, randomIndex)
    end
    
    return selectedQuests
end

function QuestService:LoadPlayerQuests(player)
    local userId = tostring(player.UserId)
    local currentDay = self:GetDaysSinceEpoch()
    
    -- Try to load from DataStore
    local success, data = pcall(function()
        return questProgressStore:GetAsync(userId) or {}
    end)
    
    if not success then
        warn("Failed to load quest data for " .. player.Name)
        data = {}
    end
    
    -- Check if we need new daily quests (quest reset)
    if not data.lastQuestDay or data.lastQuestDay < currentDay then
        print("🔄 Generating new daily quests for " .. player.Name .. " (last reset: day " .. (data.lastQuestDay or 0) .. ", current: day " .. currentDay .. ")")
        
        -- Use the centralized reset function
        local resetSuccess = self:ResetPlayerQuests(player, currentDay)
        
        if resetSuccess then
            -- Reload the data after reset
            local reloadSuccess, newData = pcall(function()
                return questProgressStore:GetAsync(userId) or {}
            end)
            
            if reloadSuccess then
                data = newData
            else
                warn("Failed to reload quest data after reset for " .. player.Name)
            end
        else
            -- Fallback to old method if reset fails
            data.dailyQuests = self:GetRandomQuests(3)
            data.questProgress = {}
            data.lastQuestDay = currentDay
            
            -- Initialize progress for each quest
            for i, quest in pairs(data.dailyQuests) do
                data.questProgress[i] = {
                    completed = false,
                    progress = 0,
                    claimed = false
                }
            end
            
            -- Save immediately
            self:SavePlayerQuests(player, data)
        end
    end
    
    playerQuests[userId] = data.dailyQuests or {}
    playerQuestProgress[userId] = data.questProgress or {}
    
    print("📋 Loaded " .. #(data.dailyQuests or {}) .. " daily quests for " .. player.Name)
    return data.dailyQuests, data.questProgress
end

function QuestService:SavePlayerQuests(player, data)
    local userId = tostring(player.UserId)
    
    local success = pcall(function()
        questProgressStore:SetAsync(userId, data)
    end)
    
    if not success then
        warn("Failed to save quest data for " .. player.Name)
    end
    
    -- Also sync quest data with main player data if PlayerService is available
    if PlayerService then
        local playerData = PlayerService:GetPlayerData(player)
        if playerData then
            playerData.questProgress = data.questProgress or {}
            playerData.dailyQuests = data.dailyQuests or {}
            playerData.lastQuestReset = data.lastQuestDay or 0
            -- Don't call UpdatePlayerData here to avoid infinite loops
            print("🔄 Synced quest data to main player data for " .. player.Name)
        end
    end
end

function QuestService:UpdateQuestProgress(player, questType, amount, extraData)
    local userId = tostring(player.UserId)
    local quests = playerQuests[userId]
    local progress = playerQuestProgress[userId]
    
    if not quests or not progress then return end
    
    for i, quest in pairs(quests) do
        if quest.targetType == questType and progress[i] and not progress[i].completed then
            local oldProgress = progress[i].progress
            
            -- Update progress based on quest type
            if questType == "color_match" and extraData and extraData.color == quest.targetColor then
                progress[i].progress = progress[i].progress + (amount or 1)
            elseif questType == "coins_collected" or questType == "games_played" or questType == "fountain_claimed" or questType == "shop_visits" or questType == "cosmetic_purchase" or questType == "mystery_box_opened" then
                progress[i].progress = progress[i].progress + (amount or 1)
            elseif questType == "high_score" and amount >= quest.targetAmount then
                progress[i].progress = quest.targetAmount
            elseif questType == "combo_streak" and amount >= quest.targetAmount then
                progress[i].progress = quest.targetAmount
            elseif questType == "fast_games" and extraData and extraData.time <= quest.targetTime then
                progress[i].progress = progress[i].progress + 1
            elseif questType == "perfect_games" and extraData and extraData.perfect then
                progress[i].progress = progress[i].progress + 1
            elseif questType == "rare_mystery_find" and extraData and (extraData.rarity == "Rare" or extraData.rarity == "Epic") then
                progress[i].progress = progress[i].progress + 1
            elseif questType == "event_runs_completed" then
                progress[i].progress = progress[i].progress + 1
            elseif questType == "event_high_score" and amount >= quest.targetAmount then
                progress[i].progress = quest.targetAmount
            elseif questType == "daily_streak" and amount >= quest.targetAmount then
                progress[i].progress = quest.targetAmount
            elseif questType == "accessibility_setting" and extraData and extraData.setting == quest.targetSetting and extraData.enabled then
                progress[i].progress = quest.targetAmount
            elseif questType == "controller_input" then
                progress[i].progress = progress[i].progress + (amount or 1)
            elseif questType == "upgrade_purchase" then
                progress[i].progress = progress[i].progress + (amount or 1)
            elseif questType == "max_upgrade_reached" and extraData and extraData.maxLevelReached then
                progress[i].progress = quest.targetAmount
            elseif questType == "score_shared" then
                progress[i].progress = progress[i].progress + (amount or 1)
            elseif questType == "epic_share" and extraData and (extraData.isPerfect or extraData.isNewHighScore) then
                progress[i].progress = quest.targetAmount
            elseif questType == "world_event_participation" then
                progress[i].progress = progress[i].progress + (amount or 1)
            elseif questType == "world_event_high_score" and amount >= quest.targetAmount then
                progress[i].progress = quest.targetAmount
            elseif questType == "specific_event_completion" and extraData and extraData.eventId == quest.targetEvent then
                progress[i].progress = quest.targetAmount
            elseif questType == "specific_event_score" and extraData and extraData.eventId == quest.targetEvent and amount >= quest.targetAmount then
                progress[i].progress = quest.targetAmount
            elseif questType == "puzzle_piece_collected" then
                progress[i].progress = progress[i].progress + (amount or 1)
            elseif questType == "puzzle_completed" and extraData and extraData.completed then
                progress[i].progress = quest.targetAmount
            elseif questType == "trophy_unlocked" then
                progress[i].progress = progress[i].progress + (amount or 1)
            elseif questType == "diamond_trophy_unlocked" and extraData and extraData.trophyId then
                -- Check if it's a diamond trophy
                progress[i].progress = quest.targetAmount
            elseif questType == "pet_purchased" then
                progress[i].progress = progress[i].progress + (amount or 1)
            elseif questType == "pets_owned" and amount >= quest.targetAmount then
                progress[i].progress = quest.targetAmount
            elseif questType == "games_with_pet" and extraData and extraData.hasPet then
                progress[i].progress = progress[i].progress + 1
            elseif questType == "rare_pet_purchased" and extraData and (extraData.rarity == "Rare" or extraData.rarity == "Epic" or extraData.rarity == "Legendary" or extraData.rarity == "Mythic") then
                progress[i].progress = quest.targetAmount
            elseif questType == "exclusive_purchased" then
                progress[i].progress = progress[i].progress + (amount or 1)
            elseif questType == "exclusives_owned" and amount >= quest.targetAmount then
                progress[i].progress = quest.targetAmount
            elseif questType == "premium_exclusive_purchased" and extraData and extraData.price >= quest.targetAmount then
                progress[i].progress = quest.targetAmount
            elseif questType == "countdown_viewed" then
                progress[i].progress = progress[i].progress + (amount or 1)
            elseif questType == "last_minute_purchase" and extraData and extraData.timeRemaining < 86400 then -- Less than 24 hours
                progress[i].progress = quest.targetAmount
            elseif questType == "early_exclusive_purchase" and extraData and extraData.purchaseRank <= 10 then
                progress[i].progress = quest.targetAmount
            elseif questType == "party_created" then
                progress[i].progress = progress[i].progress + (amount or 1)
            elseif questType == "party_games_played" and extraData and extraData.isPartyGame then
                progress[i].progress = progress[i].progress + 1
            elseif questType == "max_party_size" and amount >= quest.targetAmount then
                progress[i].progress = quest.targetAmount
            elseif questType == "party_bonus_xp" then
                progress[i].progress = progress[i].progress + (amount or 0)
            elseif questType == "consistent_party_games" and extraData and extraData.sameParty then
                progress[i].progress = progress[i].progress + 1
            elseif questType == "party_voice_sent" then
                progress[i].progress = progress[i].progress + (amount or 1)
            elseif questType == "party_emotes_sent" then
                progress[i].progress = progress[i].progress + (amount or 1)
            elseif questType == "party_perfect_runs" and extraData and extraData.isPerfectPartyRun then
                progress[i].progress = progress[i].progress + 1
            elseif questType == "party_celebrations" then
                progress[i].progress = progress[i].progress + (amount or 1)
            elseif questType == "party_level_reached" and amount >= quest.targetAmount then
                progress[i].progress = quest.targetAmount
            elseif questType == "party_achievements_unlocked" then
                progress[i].progress = progress[i].progress + (amount or 1)
            -- Mini-Game Quest Types
            elseif questType == "minigame_played" then
                progress[i].progress = progress[i].progress + (amount or 1)
            elseif questType == "targets_hit" then
                progress[i].progress = progress[i].progress + (amount or 1)
            elseif questType == "coins_clicked" then
                progress[i].progress = progress[i].progress + (amount or 1)
            elseif questType == "perfect_target_game" and extraData and extraData.gameType == "jumpTarget" and extraData.score >= 5 then
                progress[i].progress = quest.targetAmount
            elseif questType == "perfect_clicker_game" and extraData and extraData.gameType == "coinClicker" and extraData.coinsClicked >= 20 then
                progress[i].progress = quest.targetAmount
            -- Buff System Quest Types
            elseif questType == "buff_purchased" then
                progress[i].progress = progress[i].progress + (amount or 1)
            elseif questType == "unique_buffs_purchased" and extraData and extraData.uniqueBuffTypes then
                progress[i].progress = math.max(progress[i].progress, extraData.uniqueBuffTypes)
            elseif questType == "buffs_used" then
                progress[i].progress = progress[i].progress + (amount or 1)
            elseif questType == "combo_with_buff" and extraData and extraData.comboCount >= quest.targetAmount and extraData.hasComboStreakBuff then
                progress[i].progress = quest.targetAmount
            elseif questType == "shield_used" and extraData and extraData.shieldActivated then
                progress[i].progress = quest.targetAmount
            elseif questType == "timefreeze_used" then
                progress[i].progress = progress[i].progress + (amount or 1)
            end
            
            -- Check if quest is completed
            if progress[i].progress >= quest.targetAmount then
                progress[i].completed = true
                self:NotifyQuestCompleted(player, i, quest)
            elseif progress[i].progress > oldProgress then
                self:NotifyQuestProgress(player, i, quest, progress[i].progress)
            end
        end
    end
    
    -- Save progress
    local data = {
        dailyQuests = quests,
        questProgress = progress,
        lastQuestDay = self:GetDaysSinceEpoch()
    }
    self:SavePlayerQuests(player, data)
end

function QuestService:NotifyQuestCompleted(player, questIndex, quest)
    print("🎉 " .. player.Name .. " completed quest: " .. quest.name)
    RemoteEvents.QuestCompleted:FireClient(player, questIndex, quest)
end

function QuestService:NotifyQuestProgress(player, questIndex, quest, currentProgress)
    RemoteEvents.QuestProgressUpdated:FireClient(player, questIndex, quest, currentProgress)
end

function QuestService:ClaimQuestReward(player, questIndex)
    local userId = tostring(player.UserId)
    local quests = playerQuests[userId]
    local progress = playerQuestProgress[userId]
    
    if not quests or not progress or not quests[questIndex] or not progress[questIndex] then
        return false
    end
    
    local quest = quests[questIndex]
    local questProgress = progress[questIndex]
    
    if not questProgress.completed or questProgress.claimed then
        return false
    end
    
    -- Apply reward
    local reward = quest.reward
    local playerData = PlayerService:GetPlayerData(player)
    
    if reward.type == "coins" then
        playerData.coins = playerData.coins + reward.amount
        playerData.totalCoinsEarned = (playerData.totalCoinsEarned or 0) + reward.amount
        PlayerService:UpdatePlayerData(player, playerData)
        
    elseif reward.type == "multiplier" then
        RemoteEvents.ApplyTempMultiplier:FireClient(player, reward.amount, reward.duration)
        
    elseif reward.type == "special" then
        RemoteEvents.ApplySpecialEffect:FireClient(player, reward.effect, reward.duration)
        
    elseif reward.type == "mega" then
        playerData.coins = playerData.coins + reward.amount
        playerData.totalCoinsEarned = (playerData.totalCoinsEarned or 0) + reward.amount
        PlayerService:UpdatePlayerData(player, playerData)
        RemoteEvents.ApplySpecialEffect:FireClient(player, reward.effect, 30)
    end
    
    -- Mark as claimed
    questProgress.claimed = true
    
    -- Save progress
    local data = {
        dailyQuests = quests,
        questProgress = progress,
        lastQuestDay = self:GetDaysSinceEpoch()
    }
    self:SavePlayerQuests(player, data)
    
    print("🎁 " .. player.Name .. " claimed reward for quest: " .. quest.name)
    return true
end

function QuestService:GetPlayerQuestData(player)
    local userId = tostring(player.UserId)
    return playerQuests[userId], playerQuestProgress[userId]
end

function QuestService:SetupQuestBoard()
    local success, error = pcall(function()
        local marketPlaza = Workspace:FindFirstChild("MarketPlaza")
        if not marketPlaza then
            warn("⚠️ MarketPlaza not found for quest board!")
            return
        end
        
        local questBoard = marketPlaza:FindFirstChild("QuestBoard")
        if not questBoard then
            warn("⚠️ Quest board not found!")
            return
        end
        
        local boardPanel = questBoard:FindFirstChild("BoardPanel")
        if not boardPanel then 
            warn("⚠️ BoardPanel not found in quest board!")
            return 
        end
    
    -- Add floating title
    local billboardGui = Instance.new("BillboardGui")
    billboardGui.Size = UDim2.new(0, 400, 0, 80)
    billboardGui.StudsOffset = Vector3.new(0, 4, 0)
    billboardGui.Parent = boardPanel
    
    local titleLabel = Instance.new("TextLabel")
    titleLabel.Size = UDim2.new(1, 0, 1, 0)
    titleLabel.BackgroundTransparency = 1
    titleLabel.Text = "📋 DAILY QUESTS"
    titleLabel.TextColor3 = Color3.new(0.8, 0.6, 0.2)
    titleLabel.TextScaled = true
    titleLabel.Font = Enum.Font.SourceSansBold
    titleLabel.TextStrokeTransparency = 0
    titleLabel.TextStrokeColor3 = Color3.new(0, 0, 0)
    titleLabel.Parent = billboardGui
    
    -- Add floating animation
    local floatTween = TweenService:Create(
        billboardGui,
        TweenInfo.new(4, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true),
        {StudsOffset = Vector3.new(0, 5, 0)}
    )
    floatTween:Play()
end

function QuestService:Initialize()
    print("📋 QuestService initializing...")
    
    -- Wait for workspace to be ready
    task.wait(1) -- UPDATED for modern API
    
    -- Setup quest board display
    self:SetupQuestBoard()
    
    -- Find and setup click detector with error handling
    local success, error = pcall(function()
        local marketPlaza = Workspace:FindFirstChild("MarketPlaza")
        if not marketPlaza then
            warn("⚠️ MarketPlaza not found for quest board click detector!")
            return
        end
        
        local questBoard = marketPlaza:FindFirstChild("QuestBoard")
        if questBoard then
            local clickDetector = questBoard:FindFirstChild("ClickDetector")
            if clickDetector then
                clickDetector.MouseClick:Connect(function(player)
                    local quests, progress = self:GetPlayerQuestData(player)
                    RemoteEvents.ShowQuestBoard:FireClient(player, quests, progress)
                end)
                print("📋 Quest board click detector connected")
        else
            warn("⚠️ ClickDetector not found in quest board!")
        end
    else
        warn("⚠️ Quest board not found in MarketPlaza!")
    end
    
    -- Initialize the daily reset system
    self:ScheduleNextDailyReset()
    print("⏰ Daily quest reset system activated")
    
    print("✅ QuestService initialized successfully!")
end

-- Handle player joining
local function onPlayerAdded(player)
    -- Load player quests
    task.spawn(function() -- UPDATED for modern API
        task.wait(2) -- UPDATED for modern API - Wait for player to fully load
        QuestService:LoadPlayerQuests(player)
    end)
end

-- Connect events
Players.PlayerAdded:Connect(onPlayerAdded)

-- Remote event handlers
RemoteEvents.ClaimQuestReward.OnServerEvent:Connect(function(player, questIndex)
    QuestService:ClaimQuestReward(player, questIndex)
end)

-- Auto-initialize when required
QuestService:Initialize()

return QuestService
