-- RemoteEvents.luau
-- Shared module for remote event references

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local RemoteEvents = {}

-- Create remote events folder
local remoteEventsFolder = ReplicatedStorage:FindFirstChild("RemoteEvents")
if not remoteEventsFolder then
    remoteEventsFolder = Instance.new("Folder")
    remoteEventsFolder.Name = "RemoteEvents"
    remoteEventsFolder.Parent = ReplicatedStorage
end

-- Function to get or create a remote event
function RemoteEvents:GetRemoteEvent(name)
    local remoteEvent = remoteEventsFolder:FindFirstChild(name)
    if not remoteEvent then
        remoteEvent = Instance.new("RemoteEvent")
        remoteEvent.Name = name
        remoteEvent.Parent = remoteEventsFolder
    end
    return remoteEvent
end

-- Function to get or create a remote function
function RemoteEvents:GetRemoteFunction(name)
    local remoteFunction = remoteEventsFolder:FindFirstChild(name)
    if not remoteFunction then
        remoteFunction = Instance.new("RemoteFunction")
        remoteFunction.Name = name
        remoteFunction.Parent = remoteEventsFolder
    end
    return remoteFunction
end

-- Common remote events for Color Rush game
RemoteEvents.PlayerDataUpdated = RemoteEvents:GetRemoteEvent("PlayerDataUpdated")
RemoteEvents.PurchaseItem = RemoteEvents:GetRemoteEvent("PurchaseItem")

-- Game Events
RemoteEvents.StartGame = RemoteEvents:GetRemoteEvent("StartGame")
RemoteEvents.EndGame = RemoteEvents:GetRemoteEvent("EndGame")
RemoteEvents.GameStarted = RemoteEvents:GetRemoteEvent("GameStarted")
RemoteEvents.GameEnded = RemoteEvents:GetRemoteEvent("GameEnded")
RemoteEvents.ReturnToHub = RemoteEvents:GetRemoteEvent("ReturnToHub")
RemoteEvents.FinishGame = RemoteEvents:GetRemoteEvent("FinishGame")

-- Gameplay Events
RemoteEvents.GameTimer = RemoteEvents:GetRemoteEvent("GameTimer")
RemoteEvents.CoinCollected = RemoteEvents:GetRemoteEvent("CoinCollected")
RemoteEvents.ObstacleHit = RemoteEvents:GetRemoteEvent("ObstacleHit")
RemoteEvents.ColorGateCheck = RemoteEvents:GetRemoteEvent("ColorGateCheck")
RemoteEvents.ColorSuccess = RemoteEvents:GetRemoteEvent("ColorSuccess")
RemoteEvents.ColorFailure = RemoteEvents:GetRemoteEvent("ColorFailure")
RemoteEvents.ChangeColor = RemoteEvents:GetRemoteEvent("ChangeColor")

-- Color & Barrier Events
RemoteEvents.ColorChanged = RemoteEvents:GetRemoteEvent("ColorChanged")
RemoteEvents.PlayerColorChanged = RemoteEvents:GetRemoteEvent("PlayerColorChanged")
RemoteEvents.BarrierHit = RemoteEvents:GetRemoteEvent("BarrierHit")
RemoteEvents.BarrierPassed = RemoteEvents:GetRemoteEvent("BarrierPassed")
RemoteEvents.ShowFailureEffect = RemoteEvents:GetRemoteEvent("ShowFailureEffect")

-- Collection Events
RemoteEvents.CoinHit = RemoteEvents:GetRemoteEvent("CoinHit")
RemoteEvents.CoinCollected = RemoteEvents:GetRemoteEvent("CoinCollected")

-- Achievement Events
RemoteEvents.NewHighScore = RemoteEvents:GetRemoteEvent("NewHighScore")

-- Shop Events
RemoteEvents.OpenShop = RemoteEvents:GetRemoteEvent("OpenShop")
RemoteEvents.PurchaseShopItem = RemoteEvents:GetRemoteEvent("PurchaseShopItem")
RemoteEvents.EquipShopItem = RemoteEvents:GetRemoteEvent("EquipShopItem")
RemoteEvents.ShopPurchaseResult = RemoteEvents:GetRemoteEvent("ShopPurchaseResult")
RemoteEvents.ShopEquipResult = RemoteEvents:GetRemoteEvent("ShopEquipResult")
RemoteEvents.RequestShopData = RemoteEvents:GetRemoteEvent("RequestShopData")

-- Fountain Events
RemoteEvents.FountainRewardClaimed = RemoteEvents:GetRemoteEvent("FountainRewardClaimed")
RemoteEvents.ShowFountainCooldown = RemoteEvents:GetRemoteEvent("ShowFountainCooldown")
RemoteEvents.ApplyTempMultiplier = RemoteEvents:GetRemoteEvent("ApplyTempMultiplier")
RemoteEvents.ApplySpecialEffect = RemoteEvents:GetRemoteEvent("ApplySpecialEffect")

-- Quest Events
RemoteEvents.ShowQuestBoard = RemoteEvents:GetRemoteEvent("ShowQuestBoard")
RemoteEvents.QuestCompleted = RemoteEvents:GetRemoteEvent("QuestCompleted")
RemoteEvents.QuestProgressUpdated = RemoteEvents:GetRemoteEvent("QuestProgressUpdated")
RemoteEvents.ClaimQuestReward = RemoteEvents:GetRemoteEvent("ClaimQuestReward")

-- Tutorial Events
RemoteEvents.ShowTutorial = RemoteEvents:GetRemoteEvent("ShowTutorial")
RemoteEvents.StartNewPlayerTutorial = RemoteEvents:GetRemoteEvent("StartNewPlayerTutorial")
RemoteEvents.CompleteTutorial = RemoteEvents:GetRemoteEvent("CompleteTutorial")

-- Mobile UI Events
RemoteEvents.CloseAllMenus = RemoteEvents:GetRemoteEvent("CloseAllMenus")
RemoteEvents.PauseGame = RemoteEvents:GetRemoteEvent("PauseGame")
RemoteEvents.ToggleTrailFX = RemoteEvents:GetRemoteEvent("ToggleTrailFX")
RemoteEvents.OpenMobileSettings = RemoteEvents:GetRemoteEvent("OpenMobileSettings")
RemoteEvents.SwitchToGameMode = RemoteEvents:GetRemoteEvent("SwitchToGameMode")
RemoteEvents.SwitchToHubMode = RemoteEvents:GetRemoteEvent("SwitchToHubMode")

-- Teleport Events
RemoteEvents.TeleportFadeOut = RemoteEvents:GetRemoteEvent("TeleportFadeOut")
RemoteEvents.TeleportFadeIn = RemoteEvents:GetRemoteEvent("TeleportFadeIn")

-- Archway Events
RemoteEvents.ArchwayTriggered = RemoteEvents:GetRemoteEvent("ArchwayTriggered")
RemoteEvents.GameCountdownStart = RemoteEvents:GetRemoteEvent("GameCountdownStart")
RemoteEvents.GameFadeToBlack = RemoteEvents:GetRemoteEvent("GameFadeToBlack")
RemoteEvents.GameFadeFromBlack = RemoteEvents:GetRemoteEvent("GameFadeFromBlack")

-- Audio Events
RemoteEvents.PlayCountdownBeep = RemoteEvents:GetRemoteEvent("PlayCountdownBeep")
RemoteEvents.PlayGameStartSound = RemoteEvents:GetRemoteEvent("PlayGameStartSound")
RemoteEvents.StartGameMusic = RemoteEvents:GetRemoteEvent("StartGameMusic")
RemoteEvents.StopGameMusic = RemoteEvents:GetRemoteEvent("StopGameMusic")
RemoteEvents.ClientStartGameMusic = RemoteEvents:GetRemoteEvent("ClientStartGameMusic")
RemoteEvents.ClientStopGameMusic = RemoteEvents:GetRemoteEvent("ClientStopGameMusic")
RemoteEvents.ClientSwitchMusicTheme = RemoteEvents:GetRemoteEvent("ClientSwitchMusicTheme")
RemoteEvents.PlayBarrierPassSound = RemoteEvents:GetRemoteEvent("PlayBarrierPassSound")
RemoteEvents.PlayBarrierParticleSound = RemoteEvents:GetRemoteEvent("PlayBarrierParticleSound")

-- Multiplayer Queue Events
RemoteEvents.ShowGameModeSelection = RemoteEvents:GetRemoteEvent("ShowGameModeSelection")
RemoteEvents.JoinSoloGame = RemoteEvents:GetRemoteEvent("JoinSoloGame")
RemoteEvents.JoinMultiplayerQueue = RemoteEvents:GetRemoteEvent("JoinMultiplayerQueue")
RemoteEvents.LeaveMultiplayerQueue = RemoteEvents:GetRemoteEvent("LeaveMultiplayerQueue")
RemoteEvents.JoinedQueue = RemoteEvents:GetRemoteEvent("JoinedQueue")
RemoteEvents.LeftQueue = RemoteEvents:GetRemoteEvent("LeftQueue")
RemoteEvents.QueueUpdate = RemoteEvents:GetRemoteEvent("QueueUpdate")
RemoteEvents.QueueFull = RemoteEvents:GetRemoteEvent("QueueFull")
RemoteEvents.SynchronizedCountdown = RemoteEvents:GetRemoteEvent("SynchronizedCountdown")

-- Multiplayer Game Events
RemoteEvents.MultiplayerGameStarted = RemoteEvents:GetRemoteEvent("MultiplayerGameStarted")
RemoteEvents.MultiplayerGameInfo = RemoteEvents:GetRemoteEvent("MultiplayerGameInfo")
RemoteEvents.MultiplayerLeaderboardUpdate = RemoteEvents:GetRemoteEvent("MultiplayerLeaderboardUpdate")
RemoteEvents.MultiplayerGameCompleted = RemoteEvents:GetRemoteEvent("MultiplayerGameCompleted")
RemoteEvents.MultiplayerXpBonus = RemoteEvents:GetRemoteEvent("MultiplayerXpBonus")

-- Analytics Events
RemoteEvents.LogAnalyticsEvent = RemoteEvents:GetRemoteEvent("LogAnalyticsEvent")

-- Monetization Events
RemoteEvents.PromptGamepassPurchase = RemoteEvents:GetRemoteEvent("PromptGamepassPurchase")
RemoteEvents.PromptProductPurchase = RemoteEvents:GetRemoteEvent("PromptProductPurchase")
RemoteEvents.GamepassPurchaseResult = RemoteEvents:GetRemoteEvent("GamepassPurchaseResult")
RemoteEvents.ProductPurchaseResult = RemoteEvents:GetRemoteEvent("ProductPurchaseResult")
RemoteEvents.RequestMonetizationInfo = RemoteEvents:GetRemoteEvent("RequestMonetizationInfo")
RemoteEvents.MonetizationInfoUpdated = RemoteEvents:GetRemoteEvent("MonetizationInfoUpdated")
RemoteEvents.ShowPurchaseConfirmation = RemoteEvents:GetRemoteEvent("ShowPurchaseConfirmation")
RemoteEvents.PurchaseConfirmationResult = RemoteEvents:GetRemoteEvent("PurchaseConfirmationResult")

-- Mystery Crate Events
RemoteEvents.OpenMysteryShop = RemoteEvents:GetRemoteEvent("OpenMysteryShop")
RemoteEvents.PurchaseMysteryBox = RemoteEvents:GetRemoteEvent("PurchaseMysteryBox")
RemoteEvents.MysteryBoxOpened = RemoteEvents:GetRemoteEvent("MysteryBoxOpened")
RemoteEvents.MysteryBoxResult = RemoteEvents:GetRemoteEvent("MysteryBoxResult")
RemoteEvents.ShowCrateMachine = RemoteEvents:GetRemoteEvent("ShowCrateMachine")
RemoteEvents.SpinCrate = RemoteEvents:GetRemoteEvent("SpinCrate")
RemoteEvents.CrateOpenResult = RemoteEvents:GetRemoteEvent("CrateOpenResult")
RemoteEvents.CrateKeyUpdate = RemoteEvents:GetRemoteEvent("CrateKeyUpdate")

-- XP and Leveling Events
RemoteEvents.XpGained = RemoteEvents:GetRemoteEvent("XpGained")
RemoteEvents.LevelUp = RemoteEvents:GetRemoteEvent("LevelUp")
RemoteEvents.LevelMilestoneReward = RemoteEvents:GetRemoteEvent("LevelMilestoneReward")
RemoteEvents.UpdateLevelDisplay = RemoteEvents:GetRemoteEvent("UpdateLevelDisplay")

-- Enhanced Coin Display Events
RemoteEvents.CoinBalanceUpdated = RemoteEvents:GetRemoteEvent("CoinBalanceUpdated")
RemoteEvents.RequestPlayerCoins = RemoteEvents:GetRemoteEvent("RequestPlayerCoins")
RemoteEvents.InstantCoinUpdate = RemoteEvents:GetRemoteEvent("InstantCoinUpdate")

-- Purchase Confirmation Events
RemoteEvents.ShowPurchaseConfirmation = RemoteEvents:GetRemoteEvent("ShowPurchaseConfirmation")
RemoteEvents.ProcessPurchase = RemoteEvents:GetRemoteEvent("ProcessPurchase")
RemoteEvents.PurchaseResult = RemoteEvents:GetRemoteEvent("PurchaseResult")

-- Enhanced XP Display Events
RemoteEvents.RequestPlayerXp = RemoteEvents:GetRemoteEvent("RequestPlayerXp")
RemoteEvents.XpUpdated = RemoteEvents:GetRemoteEvent("XpUpdated")

-- Enhanced Upgrade System Events
RemoteEvents.ShowUpgradeShop = RemoteEvents:GetRemoteEvent("ShowUpgradeShop")
RemoteEvents.RequestUpgradeData = RemoteEvents:GetRemoteEvent("RequestUpgradeData")
RemoteEvents.UpgradePurchaseResult = RemoteEvents:GetRemoteEvent("UpgradePurchaseResult")
RemoteEvents.UpgradeDataUpdated = RemoteEvents:GetRemoteEvent("UpgradeDataUpdated")

-- Event Run Events
RemoteEvents.ApplyEventEffects = RemoteEvents:GetRemoteEvent("ApplyEventEffects")
RemoteEvents.PlayEventMusic = RemoteEvents:GetRemoteEvent("PlayEventMusic")
RemoteEvents.ShowEventCompletion = RemoteEvents:GetRemoteEvent("ShowEventCompletion")
RemoteEvents.ApplyTemporarySkin = RemoteEvents:GetRemoteEvent("ApplyTemporarySkin")
RemoteEvents.ApplyTemporaryTrail = RemoteEvents:GetRemoteEvent("ApplyTemporaryTrail")

-- Daily Streak Events
RemoteEvents.ShowStreakUI = RemoteEvents:GetRemoteEvent("ShowStreakUI")
RemoteEvents.ShowStreakReward = RemoteEvents:GetRemoteEvent("ShowStreakReward")
RemoteEvents.ShowStreakAvailable = RemoteEvents:GetRemoteEvent("ShowStreakAvailable")
RemoteEvents.ClaimDailyStreak = RemoteEvents:GetRemoteEvent("ClaimDailyStreak")
RemoteEvents.RequestStreakData = RemoteEvents:GetRemoteEvent("RequestStreakData")
RemoteEvents.PlaySpecialSound = RemoteEvents:GetRemoteEvent("PlaySpecialSound")

-- Accessibility Events
RemoteEvents.UpdatePlayerSettings = RemoteEvents:GetRemoteEvent("UpdatePlayerSettings")
RemoteEvents.ToggleColorblindMode = RemoteEvents:GetRemoteEvent("ToggleColorblindMode")
RemoteEvents.ToggleControllerSupport = RemoteEvents:GetRemoteEvent("ToggleControllerSupport")
RemoteEvents.UpdateQuestProgress = RemoteEvents:GetRemoteEvent("UpdateQuestProgress")

-- Ghost Runner Events
RemoteEvents.StartGhostRecording = RemoteEvents:GetRemoteEvent("StartGhostRecording")
RemoteEvents.StopGhostRecording = RemoteEvents:GetRemoteEvent("StopGhostRecording")
RemoteEvents.RecordBarrierHit = RemoteEvents:GetRemoteEvent("RecordBarrierHit")
RemoteEvents.RequestGhostLeaderboard = RemoteEvents:GetRemoteEvent("RequestGhostLeaderboard")
RemoteEvents.ShowGhostLeaderboard = RemoteEvents:GetRemoteEvent("ShowGhostLeaderboard")
RemoteEvents.RaceAgainstGhost = RemoteEvents:GetRemoteEvent("RaceAgainstGhost")
RemoteEvents.UpdateRaceComparison = RemoteEvents:GetRemoteEvent("UpdateRaceComparison")
RemoteEvents.HideRaceComparison = RemoteEvents:GetRemoteEvent("HideRaceComparison")
RemoteEvents.GhostSaved = RemoteEvents:GetRemoteEvent("GhostSaved")
RemoteEvents.GhostStatsUpdated = RemoteEvents:GetRemoteEvent("GhostStatsUpdated")

-- Upgrade Shop Events
RemoteEvents.ShowUpgradeShop = RemoteEvents:GetRemoteEvent("ShowUpgradeShop")
RemoteEvents.PurchaseUpgrade = RemoteEvents:GetRemoteEvent("PurchaseUpgrade")
RemoteEvents.UpgradePurchaseResult = RemoteEvents:GetRemoteEvent("UpgradePurchaseResult")
RemoteEvents.UpdateUpgradeData = RemoteEvents:GetRemoteEvent("UpdateUpgradeData")
RemoteEvents.BonusCoinsEarned = RemoteEvents:GetRemoteEvent("BonusCoinsEarned")

-- Share Score Events
RemoteEvents.ShowShareScore = RemoteEvents:GetRemoteEvent("ShowShareScore")
RemoteEvents.LogShareEvent = RemoteEvents:GetRemoteEvent("LogShareEvent")

-- Pet System Events
RemoteEvents.ShowPetShop = RemoteEvents:GetRemoteEvent("ShowPetShop")
RemoteEvents.PurchasePet = RemoteEvents:GetRemoteEvent("PurchasePet")
RemoteEvents.PetPurchaseResult = RemoteEvents:GetRemoteEvent("PetPurchaseResult")
RemoteEvents.EquipPet = RemoteEvents:GetRemoteEvent("EquipPet")
RemoteEvents.PetEquipResult = RemoteEvents:GetRemoteEvent("PetEquipResult")
RemoteEvents.TriggerPetReaction = RemoteEvents:GetRemoteEvent("TriggerPetReaction")
RemoteEvents.ApplyPetPassive = RemoteEvents:GetRemoteEvent("ApplyPetPassive")

-- Exclusive Cosmetics Events (FOMO System)
RemoteEvents.ShowExclusivePurchase = RemoteEvents:GetRemoteEvent("ShowExclusivePurchase")
RemoteEvents.PurchaseExclusive = RemoteEvents:GetRemoteEvent("PurchaseExclusive")
RemoteEvents.ExclusivePurchased = RemoteEvents:GetRemoteEvent("ExclusivePurchased")
RemoteEvents.ExclusiveExpired = RemoteEvents:GetRemoteEvent("ExclusiveExpired")
RemoteEvents.ExclusivePurchaseResult = RemoteEvents:GetRemoteEvent("ExclusivePurchaseResult")
RemoteEvents.GetExclusiveData = RemoteEvents:GetRemoteEvent("GetExclusiveData")
RemoteEvents.GetExclusiveLeaderboard = RemoteEvents:GetRemoteEvent("GetExclusiveLeaderboard")
RemoteEvents.ExclusiveLeaderboardData = RemoteEvents:GetRemoteEvent("ExclusiveLeaderboardData")
RemoteEvents.ShowNotification = RemoteEvents:GetRemoteEvent("ShowNotification")

-- Party System Events
RemoteEvents.OpenPartySystem = RemoteEvents:GetRemoteEvent("OpenPartySystem")
RemoteEvents.ShowPartyUI = RemoteEvents:GetRemoteEvent("ShowPartyUI")
RemoteEvents.CreateParty = RemoteEvents:GetRemoteEvent("CreateParty")
RemoteEvents.LeaveParty = RemoteEvents:GetRemoteEvent("LeaveParty")
RemoteEvents.SendPartyInvite = RemoteEvents:GetRemoteEvent("SendPartyInvite")
RemoteEvents.AcceptPartyInvite = RemoteEvents:GetRemoteEvent("AcceptPartyInvite")
RemoteEvents.DeclinePartyInvite = RemoteEvents:GetRemoteEvent("DeclinePartyInvite")
RemoteEvents.GetPlayerParty = RemoteEvents:GetRemoteEvent("GetPlayerParty")
RemoteEvents.PartyActionResult = RemoteEvents:GetRemoteEvent("PartyActionResult")
RemoteEvents.PartyCreated = RemoteEvents:GetRemoteEvent("PartyCreated")
RemoteEvents.PartyMemberJoined = RemoteEvents:GetRemoteEvent("PartyMemberJoined")
RemoteEvents.PartyMemberLeft = RemoteEvents:GetRemoteEvent("PartyMemberLeft")
RemoteEvents.PartyLeft = RemoteEvents:GetRemoteEvent("PartyLeft")
RemoteEvents.PartyDisbanded = RemoteEvents:GetRemoteEvent("PartyDisbanded")
RemoteEvents.PartyLeaderChanged = RemoteEvents:GetRemoteEvent("PartyLeaderChanged")
RemoteEvents.PartyInviteReceived = RemoteEvents:GetRemoteEvent("PartyInviteReceived")
RemoteEvents.PartyInviteSent = RemoteEvents:GetRemoteEvent("PartyInviteSent")
RemoteEvents.PartyInviteAccepted = RemoteEvents:GetRemoteEvent("PartyInviteAccepted")
RemoteEvents.PartyInviteDeclined = RemoteEvents:GetRemoteEvent("PartyInviteDeclined")
RemoteEvents.PartyInviteExpired = RemoteEvents:GetRemoteEvent("PartyInviteExpired")
RemoteEvents.PartyXpBonus = RemoteEvents:GetRemoteEvent("PartyXpBonus")
RemoteEvents.PlayerPartyData = RemoteEvents:GetRemoteEvent("PlayerPartyData")

-- Enhanced Party Features
RemoteEvents.PartyInviteResult = RemoteEvents:GetRemoteEvent("PartyInviteResult")
RemoteEvents.PartyJoinResult = RemoteEvents:GetRemoteEvent("PartyJoinResult")
RemoteEvents.StartPartyGame = RemoteEvents:GetRemoteEvent("StartPartyGame")
RemoteEvents.PartyGameStartResult = RemoteEvents:GetRemoteEvent("PartyGameStartResult")
RemoteEvents.PartyLeaveResult = RemoteEvents:GetRemoteEvent("PartyLeaveResult")
RemoteEvents.GetPartyData = RemoteEvents:GetRemoteEvent("GetPartyData")
RemoteEvents.PartyDataResponse = RemoteEvents:GetRemoteEvent("PartyDataResponse")
RemoteEvents.PartyNotification = RemoteEvents:GetRemoteEvent("PartyNotification")
RemoteEvents.PartyXPBonus = RemoteEvents:GetRemoteEvent("PartyXPBonus")
RemoteEvents.PartySyncCountdown = RemoteEvents:GetRemoteEvent("PartySyncCountdown")

-- Creative Party Communication
RemoteEvents.SendPartyVoice = RemoteEvents:GetRemoteEvent("SendPartyVoice")
RemoteEvents.PartyVoiceMessage = RemoteEvents:GetRemoteEvent("PartyVoiceMessage")
RemoteEvents.PartyVoiceResult = RemoteEvents:GetRemoteEvent("PartyVoiceResult")
RemoteEvents.SendPartyEmote = RemoteEvents:GetRemoteEvent("SendPartyEmote")
RemoteEvents.PartyEmote = RemoteEvents:GetRemoteEvent("PartyEmote")
RemoteEvents.PartyEmoteResult = RemoteEvents:GetRemoteEvent("PartyEmoteResult")
RemoteEvents.PartyCelebration = RemoteEvents:GetRemoteEvent("PartyCelebration")
RemoteEvents.PartyAchievement = RemoteEvents:GetRemoteEvent("PartyAchievement")

-- Mini-Game Events
RemoteEvents.PlayMiniGame = RemoteEvents:GetRemoteEvent("PlayMiniGame")
RemoteEvents.StartMiniGameCountdown = RemoteEvents:GetRemoteEvent("StartMiniGameCountdown")
RemoteEvents.ShowMiniGameMessage = RemoteEvents:GetRemoteEvent("ShowMiniGameMessage")
RemoteEvents.ShowMiniGameResults = RemoteEvents:GetRemoteEvent("ShowMiniGameResults")
RemoteEvents.MiniGameScoreUpdate = RemoteEvents:GetRemoteEvent("MiniGameScoreUpdate")

-- Buff System Events
RemoteEvents.PurchaseBuff = RemoteEvents:GetRemoteEvent("PurchaseBuff")
RemoteEvents.ActivateBuff = RemoteEvents:GetRemoteEvent("ActivateBuff")
RemoteEvents.BuffActivated = RemoteEvents:GetRemoteEvent("BuffActivated")
RemoteEvents.BuffExpired = RemoteEvents:GetRemoteEvent("BuffExpired")
RemoteEvents.BuffTimeUpdate = RemoteEvents:GetRemoteEvent("BuffTimeUpdate")
RemoteEvents.BuffUpdated = RemoteEvents:GetRemoteEvent("BuffUpdated")
RemoteEvents.BuffPurchased = RemoteEvents:GetRemoteEvent("BuffPurchased")
RemoteEvents.CollectBuffPickup = RemoteEvents:GetRemoteEvent("CollectBuffPickup")
RemoteEvents.CreateEffect = RemoteEvents:GetRemoteEvent("CreateEffect")
RemoteEvents.ShieldActivated = RemoteEvents:GetRemoteEvent("ShieldActivated")
RemoteEvents.ShowStreakEffect = RemoteEvents:GetRemoteEvent("ShowStreakEffect")
RemoteEvents.BarrierPassed = RemoteEvents:GetRemoteEvent("BarrierPassed")
RemoteEvents.BarrierCollision = RemoteEvents:GetRemoteEvent("BarrierCollision")

-- Spectator System Events
RemoteEvents.EnterSpectatorMode = RemoteEvents:GetRemoteEvent("EnterSpectatorMode")
RemoteEvents.ExitSpectatorMode = RemoteEvents:GetRemoteEvent("ExitSpectatorMode")
RemoteEvents.SwitchSpectatorTarget = RemoteEvents:GetRemoteEvent("SwitchSpectatorTarget")
RemoteEvents.SpectatorTargetChanged = RemoteEvents:GetRemoteEvent("SpectatorTargetChanged")
RemoteEvents.SpectatorCheer = RemoteEvents:GetRemoteEvent("SpectatorCheer")
RemoteEvents.SpectatorCameraControl = RemoteEvents:GetRemoteEvent("SpectatorCameraControl")
RemoteEvents.UpdateSpectatorCamera = RemoteEvents:GetRemoteEvent("UpdateSpectatorCamera")
RemoteEvents.ShowCheerMessage = RemoteEvents:GetRemoteEvent("ShowCheerMessage")
RemoteEvents.CheerConfirmed = RemoteEvents:GetRemoteEvent("CheerConfirmed")
RemoteEvents.StopSpectating = RemoteEvents:GetRemoteEvent("StopSpectating")

-- Tournament System Events
RemoteEvents.RequestTournamentData = RemoteEvents:GetRemoteEvent("RequestTournamentData")
RemoteEvents.TournamentDataUpdated = RemoteEvents:GetRemoteEvent("TournamentDataUpdated")
RemoteEvents.TournamentLeaderboardUpdated = RemoteEvents:GetRemoteEvent("TournamentLeaderboardUpdated")
RemoteEvents.TournamentPrizeAwarded = RemoteEvents:GetRemoteEvent("TournamentPrizeAwarded")
RemoteEvents.TournamentWeekReset = RemoteEvents:GetRemoteEvent("TournamentWeekReset")
RemoteEvents.GetTournamentPrizes = RemoteEvents:GetRemoteEvent("GetTournamentPrizes")
RemoteEvents.TournamentPrizesUpdated = RemoteEvents:GetRemoteEvent("TournamentPrizesUpdated")

-- Trail System Events
RemoteEvents.EquipTrail = RemoteEvents:GetRemoteEvent("EquipTrail")
RemoteEvents.UnequipTrail = RemoteEvents:GetRemoteEvent("UnequipTrail")
RemoteEvents.GetPlayerTrails = RemoteEvents:GetRemoteEvent("GetPlayerTrails")
RemoteEvents.PlayerTrailsUpdate = RemoteEvents:GetRemoteEvent("PlayerTrailsUpdate")
RemoteEvents.TrailEquipResult = RemoteEvents:GetRemoteEvent("TrailEquipResult")
RemoteEvents.ShowTrailManager = RemoteEvents:GetRemoteEvent("ShowTrailManager")

-- Crate Machine Events
RemoteEvents.ShowCrateMachine = RemoteEvents:GetRemoteEvent("ShowCrateMachine")
RemoteEvents.SpinCrate = RemoteEvents:GetRemoteEvent("SpinCrate")
RemoteEvents.CrateOpenResult = RemoteEvents:GetRemoteEvent("CrateOpenResult")

-- Achievement System Events
RemoteEvents.RequestAchievementData = RemoteEvents:GetRemoteEvent("RequestAchievementData")
RemoteEvents.AchievementDataUpdated = RemoteEvents:GetRemoteEvent("AchievementDataUpdated")
RemoteEvents.AchievementUnlocked = RemoteEvents:GetRemoteEvent("AchievementUnlocked")
RemoteEvents.ClaimAchievementReward = RemoteEvents:GetRemoteEvent("ClaimAchievementReward")
RemoteEvents.AchievementClaimResult = RemoteEvents:GetRemoteEvent("AchievementClaimResult")

-- Daily Bonus Events
RemoteEvents.RequestDailyBonus = RemoteEvents:GetRemoteEvent("RequestDailyBonus")
RemoteEvents.ShowDailyBonusPopup = RemoteEvents:GetRemoteEvent("ShowDailyBonusPopup")
RemoteEvents.ClaimDailyBonus = RemoteEvents:GetRemoteEvent("ClaimDailyBonus")
RemoteEvents.DailyBonusResult = RemoteEvents:GetRemoteEvent("DailyBonusResult")

-- Save/Load Feedback Events
RemoteEvents.SaveStarted = RemoteEvents:GetRemoteEvent("SaveStarted")
RemoteEvents.SaveCompleted = RemoteEvents:GetRemoteEvent("SaveCompleted")
RemoteEvents.DataLoadStarted = RemoteEvents:GetRemoteEvent("DataLoadStarted")
RemoteEvents.DataLoadCompleted = RemoteEvents:GetRemoteEvent("DataLoadCompleted")
RemoteEvents.RequestManualSave = RemoteEvents:GetRemoteEvent("RequestManualSave")

-- Monetization Events
RemoteEvents.PromptGamepassPurchase = RemoteEvents:GetRemoteEvent("PromptGamepassPurchase")
RemoteEvents.PromptProductPurchase = RemoteEvents:GetRemoteEvent("PromptProductPurchase")
RemoteEvents.RequestMonetizationInfo = RemoteEvents:GetRemoteEvent("RequestMonetizationInfo")
RemoteEvents.MonetizationInfoUpdated = RemoteEvents:GetRemoteEvent("MonetizationInfoUpdated")
RemoteEvents.GamepassPurchaseResult = RemoteEvents:GetRemoteEvent("GamepassPurchaseResult")
RemoteEvents.ProductPurchaseResult = RemoteEvents:GetRemoteEvent("ProductPurchaseResult")
RemoteEvents.OpenMonetizationShop = RemoteEvents:GetRemoteEvent("OpenMonetizationShop")

-- VIP Status Events
RemoteEvents.RequestVIPStatus = RemoteEvents:GetRemoteEvent("RequestVIPStatus")
RemoteEvents.VIPStatusUpdated = RemoteEvents:GetRemoteEvent("VIPStatusUpdated")

-- Weekly Leaderboard Events
RemoteEvents.RequestWeeklyLeaderboard = RemoteEvents:GetRemoteEvent("RequestWeeklyLeaderboard")
RemoteEvents.UpdateWeeklyLeaderboard = RemoteEvents:GetRemoteEvent("UpdateWeeklyLeaderboard")
RemoteEvents.ShowWeeklyLeaderboard = RemoteEvents:GetRemoteEvent("ShowWeeklyLeaderboard")
RemoteEvents.HideWeeklyLeaderboard = RemoteEvents:GetRemoteEvent("HideWeeklyLeaderboard")
RemoteEvents.ShowWeeklyRewardChest = RemoteEvents:GetRemoteEvent("ShowWeeklyRewardChest")
RemoteEvents.ClaimWeeklyReward = RemoteEvents:GetRemoteEvent("ClaimWeeklyReward")
RemoteEvents.WeeklyRewardClaimed = RemoteEvents:GetRemoteEvent("WeeklyRewardClaimed")
RemoteEvents.WeeklyLeaderboardReset = RemoteEvents:GetRemoteEvent("WeeklyLeaderboardReset")
RemoteEvents.PlayerEarnedCoins = RemoteEvents:GetRemoteEvent("PlayerEarnedCoins")
RemoteEvents.UpdatePlayerRank = RemoteEvents:GetRemoteEvent("UpdatePlayerRank")

-- Daily Reward Events
RemoteEvents.RequestDailyRewardData = RemoteEvents:GetRemoteEvent("RequestDailyRewardData")
RemoteEvents.UpdateDailyRewardData = RemoteEvents:GetRemoteEvent("UpdateDailyRewardData")
RemoteEvents.ShowDailyRewardPopup = RemoteEvents:GetRemoteEvent("ShowDailyRewardPopup")
RemoteEvents.HideDailyRewardPopup = RemoteEvents:GetRemoteEvent("HideDailyRewardPopup")
RemoteEvents.ClaimDailyReward = RemoteEvents:GetRemoteEvent("ClaimDailyReward")
RemoteEvents.DailyRewardClaimResult = RemoteEvents:GetRemoteEvent("DailyRewardClaimResult")

-- Hub Puzzle Events
RemoteEvents.RequestHubPuzzleState = RemoteEvents:GetRemoteEvent("RequestHubPuzzleState")
RemoteEvents.StartHubPuzzle = RemoteEvents:GetRemoteEvent("StartHubPuzzle")
RemoteEvents.EndHubPuzzle = RemoteEvents:GetRemoteEvent("EndHubPuzzle")
RemoteEvents.HubPuzzleOrbCollected = RemoteEvents:GetRemoteEvent("HubPuzzleOrbCollected")
RemoteEvents.HubPuzzleCompleted = RemoteEvents:GetRemoteEvent("HubPuzzleCompleted")
RemoteEvents.HubPuzzleReward = RemoteEvents:GetRemoteEvent("HubPuzzleReward")
RemoteEvents.UnlockTrail = RemoteEvents:GetRemoteEvent("UnlockTrail")

-- Jump Mechanics Events
RemoteEvents.PlayerJumped = RemoteEvents:GetRemoteEvent("PlayerJumped")
RemoteEvents.JumpValidated = RemoteEvents:GetRemoteEvent("JumpValidated")
RemoteEvents.UpdateJumpState = RemoteEvents:GetRemoteEvent("UpdateJumpState")
RemoteEvents.RequestJumpState = RemoteEvents:GetRemoteEvent("RequestJumpState")

return RemoteEvents
