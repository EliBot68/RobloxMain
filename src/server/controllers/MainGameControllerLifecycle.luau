-- Enhanced MainGameController lifecycle methods
-- Add these methods to the existing MainGameController.luau file

-- ========================================
-- LIFECYCLE MANAGEMENT METHODS
-- ========================================

function MainGameController:InitializeForGameLoop()
    print("🎮 MainGameController: Initializing for game loop...")
    
    -- Reset any existing game data
    self:ClearAllGameData()
    
    -- Initialize game loop specific settings
    self.gameLoopSettings = {
        autoStartGames = true,
        maxConcurrentGames = 50,
        gameTimeout = 300, -- 5 minutes
        minPlayersPerGame = 1,
        maxPlayersPerGame = 1 -- Color Rush is single player
    }
    
    -- Setup game loop monitoring
    self:SetupGameLoopMonitoring()
    
    print("✅ MainGameController ready for game loop")
    return true
end

function MainGameController:UpdateActiveGames()
    if not self.activeSessions then return end
    
    local currentTime = tick()
    
    for sessionId, session in pairs(self.activeSessions) do
        -- Check for game timeouts
        if session.startTime and (currentTime - session.startTime) > (self.gameLoopSettings.gameTimeout or 300) then
            warn("⏰ Game timeout for session: " .. sessionId)
            self:EndGameSession(session.player, {
                reason = "timeout",
                forced = true
            })
        end
        
        -- Update game progress
        if session.player and session.state == "PLAYING" then
            self:UpdateGameProgress(session.player, session)
        end
    end
end

function MainGameController:CleanupFinishedGames()
    if not self.activeSessions then return end
    
    local sessionsToRemove = {}
    
    for sessionId, session in pairs(self.activeSessions) do
        if session.state == "ENDED" or session.state == "FINISHED" then
            -- Clean up session data
            self:CleanupSession(session)
            table.insert(sessionsToRemove, sessionId)
        end
    end
    
    -- Remove finished sessions
    for _, sessionId in ipairs(sessionsToRemove) do
        self.activeSessions[sessionId] = nil
    end
end

function MainGameController:SetupGameLoopMonitoring()
    -- Monitor active game sessions
    spawn(function()
        while true do
            wait(5) -- Check every 5 seconds
            
            if self.activeSessions then
                for sessionId, session in pairs(self.activeSessions) do
                    -- Monitor session health
                    if not self:IsSessionHealthy(session) then
                        warn("⚠️ Unhealthy session detected: " .. sessionId)
                        self:AttemptSessionRecovery(session)
                    end
                end
            end
        end
    end)
end

function MainGameController:IsSessionHealthy(session)
    -- Check if session is healthy
    if not session.player or not session.player.Parent then
        return false
    end
    
    if session.state == "PLAYING" and not session.lastActivity then
        return false
    end
    
    if session.lastActivity and (tick() - session.lastActivity) > 60 then -- 1 minute of inactivity
        return false
    end
    
    return true
end

function MainGameController:AttemptSessionRecovery(session)
    print("🔧 Attempting session recovery for: " .. (session.player and session.player.Name or "Unknown"))
    
    if session.player and session.player.Parent then
        -- Try to reset player to lobby
        local gameStateManager = _G.GetGameStateEventManager()
        if gameStateManager then
            gameStateManager:ChangeGameState(session.player, "RESETTING", {
                reason = "session-recovery",
                automatic = true
            })
        end
    else
        -- Remove dead session
        if session.sessionId and self.activeSessions then
            self.activeSessions[session.sessionId] = nil
        end
    end
end

function MainGameController:ResetService()
    print("🔄 MainGameController: Resetting service...")
    
    -- Stop all active games
    if self.activeSessions then
        for sessionId, session in pairs(self.activeSessions) do
            if session.player then
                self:EndGameSession(session.player, {
                    reason = "service-reset",
                    forced = true
                })
            end
        end
    end
    
    -- Clear all data
    self:ClearAllGameData()
    
    -- Reinitialize
    self:Initialize()
    
    print("✅ MainGameController reset complete")
end

function MainGameController:ClearAllGameData()
    -- Clear all game-related data
    self.activeSessions = {}
    self.playerData = {}
    self.gameQueue = {}
    
    -- Reset statistics
    if self.statistics then
        self.statistics = {
            gamesStarted = 0,
            gamesCompleted = 0,
            totalPlayTime = 0,
            averageScore = 0
        }
    end
end

function MainGameController:UpdateGameProgress(player, session)
    -- Update session activity
    session.lastActivity = tick()
    
    -- Update game metrics
    if session.gameData then
        session.gameData.currentTime = tick() - session.startTime
        
        -- Track progress analytics
        local analyticsService = _G.GetAnalyticsService()
        if analyticsService then
            analyticsService:TrackEvent(player, "game_progress_update", {
                sessionId = session.sessionId,
                currentTime = session.gameData.currentTime,
                currentScore = session.gameData.currentScore or 0
            })
        end
    end
end

function MainGameController:CleanupSession(session)
    -- Clean up any session-specific resources
    if session.trackData then
        local trackGenerator = _G.GetTrackGeneratorService()
        if trackGenerator and trackGenerator.CleanupTrack then
            trackGenerator:CleanupTrack(session.trackData)
        end
    end
    
    if session.collisionData then
        local collisionController = _G.GetCollisionController()
        if collisionController and collisionController.CleanupPlayerCollisions then
            collisionController:CleanupPlayerCollisions(session.player)
        end
    end
    
    if session.recordingData then
        local recordingManager = _G.GetRecordingSessionManager()
        if recordingManager and recordingManager.CleanupRecording then
            recordingManager:CleanupRecording(session.player)
        end
    end
end

-- ========================================
-- ENHANCED PLAYER MANAGEMENT
-- ========================================

function MainGameController:PreparePlayerForGame(player, gameData)
    if not player or not player.Parent then
        warn("❌ Invalid player for game preparation")
        return false
    end
    
    print("🎯 Preparing player for game: " .. player.Name)
    
    -- Create or update session
    local sessionId = self:CreateGameSession(player, gameData)
    if not sessionId then
        warn("❌ Failed to create game session for: " .. player.Name)
        return false
    end
    
    -- Setup player UI
    self:SetupPlayerUI(player, gameData)
    
    -- Prepare track
    self:PrepareTrackForPlayer(player, gameData)
    
    -- Setup collision detection
    self:SetupCollisionForPlayer(player)
    
    -- Initialize difficulty
    self:InitializeDifficultyForPlayer(player, gameData)
    
    print("✅ Player prepared for game: " .. player.Name)
    return true
end

function MainGameController:CreateGameSession(player, gameData)
    local sessionId = player.UserId .. "_" .. tick()
    
    if not self.activeSessions then
        self.activeSessions = {}
    end
    
    self.activeSessions[sessionId] = {
        sessionId = sessionId,
        player = player,
        state = "PREPARING",
        startTime = tick(),
        lastActivity = tick(),
        gameData = gameData or {},
        trackData = nil,
        collisionData = nil,
        recordingData = nil
    }
    
    return sessionId
end

function MainGameController:SetupPlayerUI(player, gameData)
    -- Setup UI for player
    local uiEvent = _G.GetRemoteEvent and _G.GetRemoteEvent("SetupPlayerUI")
    if uiEvent then
        uiEvent:FireClient(player, {
            gameMode = gameData.gameMode or "standard",
            difficulty = gameData.difficulty or 1,
            theme = gameData.theme or "default"
        })
    end
end

function MainGameController:PrepareTrackForPlayer(player, gameData)
    local trackGenerator = _G.GetTrackGeneratorService()
    if trackGenerator then
        local trackConfig = {
            difficulty = gameData.difficulty or 1,
            length = gameData.trackLength or 100,
            theme = gameData.theme or "default",
            player = player
        }
        
        if trackGenerator.PreparePlayerTrack then
            trackGenerator:PreparePlayerTrack(player, trackConfig)
        end
    end
end

function MainGameController:SetupCollisionForPlayer(player)
    local collisionController = _G.GetCollisionController()
    if collisionController then
        if collisionController.EnablePlayerCollision then
            collisionController:EnablePlayerCollision(player)
        end
        
        if collisionController.SetupPlayerForCollision then
            collisionController:SetupPlayerForCollision(player, player.Character)
        end
    end
end

function MainGameController:InitializeDifficultyForPlayer(player, gameData)
    local difficultyService = _G.GetDifficultyService()
    if difficultyService then
        local initialDifficulty = gameData.difficulty or 1
        
        if difficultyService.InitializePlayerDifficulty then
            difficultyService:InitializePlayerDifficulty(player, initialDifficulty)
        end
    end
end

function MainGameController:ResetPlayerGame(player)
    if not player then return end
    
    print("🔄 Resetting game for player: " .. player.Name)
    
    -- Find and clean up player session
    if self.activeSessions then
        for sessionId, session in pairs(self.activeSessions) do
            if session.player == player then
                self:CleanupSession(session)
                self.activeSessions[sessionId] = nil
                break
            end
        end
    end
    
    -- Reset player data
    if self.playerData and self.playerData[player.UserId] then
        self.playerData[player.UserId] = nil
    end
    
    -- Disable collision
    local collisionController = _G.GetCollisionController()
    if collisionController and collisionController.DisablePlayerCollision then
        collisionController:DisablePlayerCollision(player)
    end
    
    -- Clear track
    local trackGenerator = _G.GetTrackGeneratorService()
    if trackGenerator and trackGenerator.ClearPlayerTrack then
        trackGenerator:ClearPlayerTrack(player)
    end
    
    -- Reset difficulty
    local difficultyService = _G.GetDifficultyService()
    if difficultyService and difficultyService.ResetPlayerDifficulty then
        difficultyService:ResetPlayerDifficulty(player)
    end
    
    print("✅ Player game reset complete: " .. player.Name)
end

function MainGameController:ClearPlayerData(player)
    if not player then return end
    
    -- Clear any stored player data
    if self.playerData and self.playerData[player.UserId] then
        self.playerData[player.UserId] = nil
    end
    
    -- Clear UI
    local uiEvent = _G.GetRemoteEvent and _G.GetRemoteEvent("ClearPlayerUI")
    if uiEvent then
        uiEvent:FireClient(player)
    end
end

-- ========================================
-- GAME SESSION MANAGEMENT
-- ========================================

function MainGameController:EndGameSession(player, results)
    if not player then return end
    
    print("🏁 Ending game session for: " .. player.Name)
    
    -- Find session
    local session = nil
    if self.activeSessions then
        for sessionId, sess in pairs(self.activeSessions) do
            if sess.player == player then
                session = sess
                break
            end
        end
    end
    
    if session then
        -- Update session state
        session.state = "ENDED"
        session.endTime = tick()
        session.results = results or {}
        
        -- Calculate final metrics
        local duration = session.endTime - session.startTime
        session.results.duration = duration
        
        -- Track completion analytics
        local analyticsService = _G.GetAnalyticsService()
        if analyticsService then
            analyticsService:TrackEvent(player, "game_session_ended", {
                sessionId = session.sessionId,
                duration = duration,
                finalScore = session.results.finalScore or 0,
                reason = session.results.reason or "completed"
            })
        end
        
        -- Clean up session
        spawn(function()
            wait(2) -- Brief delay
            self:CleanupSession(session)
            if self.activeSessions then
                self.activeSessions[session.sessionId] = nil
            end
        end)
    end
end

-- Export these methods to be added to MainGameController
return {
    InitializeForGameLoop = InitializeForGameLoop,
    UpdateActiveGames = UpdateActiveGames,
    CleanupFinishedGames = CleanupFinishedGames,
    SetupGameLoopMonitoring = SetupGameLoopMonitoring,
    ResetService = ResetService,
    ClearAllGameData = ClearAllGameData,
    PreparePlayerForGame = PreparePlayerForGame,
    ResetPlayerGame = ResetPlayerGame,
    ClearPlayerData = ClearPlayerData,
    EndGameSession = EndGameSession
}
